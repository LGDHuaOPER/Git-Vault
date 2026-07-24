---
title: GreptimeDB
category: entities
tags:
  - observability
  - database
  - opentelemetry
  - open-source
sources:
  - "GreptimeDB: 当 LLM 应用遇上可观测性：用 GreptimeDB 统一 Traces、Metrics 和对话记录 (2026-03-10)"
  - "CNCF: 一文看懂 OpenTelemetry GenAI：LLM、Agent、MCP 怎么做可观测性 (2026-05-25)"
  - "DeepFlow: 从 eBPF 到 LLM：可观测性管道的每一层都在变｜上海 Meetup 回顾 (2026-04-28)"
summary: GreptimeDB 是新一代可观测性数据库，基于 OpenTelemetry GenAI 语义规范，将 Traces、Metrics 和对话记录统一存储在同一数据库中，支持跨信号关联查询、流处理聚合、全文检索和自然语言分析。
base_confidence: 0.75
lifecycle: draft
lifecycle_changed: "2026-07-22"
tier: supporting
provenance:
  extracted: 0.8
  inferred: 0.2
  ambiguous: 0.0
created: "2026-07-22"
updated: "2026-07-22"
relationships:
  - target: "[[concepts/genai-observability-semconv]]"
    type: implements
  - target: "[[concepts/ai-agent-observability]]"
    type: related_to
  - target: "[[entities/langfuse-llm-observability]]"
    type: related_to
  - target: "[[entities/automq]]"
    type: related_to
  - target: "[[entities/deepflow]]"
    type: related_to
---

# GreptimeDB

**GreptimeDB** 是格睿科技（Greptime）开发的新一代可观测性数据库，专注于统一处理指标（Metrics）、日志（Logs）和追踪（Traces）数据。在 LLM 可观测性领域，GreptimeDB 基于 **OpenTelemetry GenAI 语义规范**，将三类信号统一存储在同一数据库中，解决了传统方案中 traces、metrics、logs 分散在三个系统导致的数据关联难题。

## 核心定位

传统 LLM 可观测性方案中，工程师通常面临"三个系统，定位一个问题"的困境：

- `trace_id` 在 Jaeger 里
- Token 用量在 Prometheus 里
- 对话内容在 Elasticsearch 里

GreptimeDB 的核心价值在于**统一存储、统一查询**：三类信号都存在同一个数据库，通过 `trace_id` 和 `span_id` 实现跨信号关联。

## 架构与接入

### OTLP 直送架构

```
GenAI 应用（Python）
│  OpenAI SDK + OTel GenAI Instrumentor
│  自动产生 traces + metrics + logs
│
│ OTLP/HTTP
▼
GreptimeDB
├── opentelemetry_traces  ← traces，gen_ai.* 属性展开为可查询列
├── genai_conversations   ← logs，完整 prompt/completion 内容
├── OTel metrics          ← histograms，支持 PromQL 查询
└── Flow 聚合表            ← 实时预聚合的 token/延迟/状态统计
│
Grafana
├── SQL 面板（traces、logs、Flow 表）
├── PromQL 面板（OTel histogram metrics）
└── Trace 瀑布图（GreptimeDB Grafana 插件）
```

### 三类信号接入方式

| 信号类型 | 接入方式 | 存储表 |
|----------|----------|--------|
| **Traces** | OTLP/HTTP，通过内置 pipeline 将 span attributes 展平为可查询列 | `opentelemetry_traces` |
| **Metrics** | 标准 OTLP，histogram 自动支持 PromQL | OTel metrics 表 |
| **Logs** | OTLP/HTTP，通过自定义 header 路由到指定表 | `genai_conversations` |

## 三大核心优势

### 1. 三类信号同库，跨信号关联查询

GreptimeDB 将三类信号存在同一个数据库。`opentelemetry_traces` 表和 `genai_conversations` 表都有 `trace_id` 和 `span_id` 列，一条 SQL 就能把 token 用量和完整对话内容关联起来：

```sql
SELECT
  t.trace_id,
  t."span_attributes.gen_ai.request.model" AS model,
  t."span_attributes.gen_ai.usage.input_tokens" AS input_tokens,
  t."span_attributes.gen_ai.usage.output_tokens" AS output_tokens,
  json_get_string(parse_json(c.body), 'content') AS user_message
FROM opentelemetry_traces t
JOIN genai_conversations c ON t.trace_id = c.trace_id AND t.span_id = c.span_id
WHERE t."span_attributes.gen_ai.system" IS NOT NULL
ORDER BY input_tokens DESC
LIMIT 10;
```

### 2. 从原始 Span 衍生 Metrics，不用双写

GreptimeDB 的流处理引擎（Flow）提供持续聚合能力，类似 SQL 里的物化视图，但实时驱动。每个 LLM 调用的 Span 本身就是一个宽事件（Wide Event），携带了所有需要聚合的字段。有了 Flow，不需要应用层再额外上报一套 metrics，直接从 traces 里聚合出来就够了：

```sql
-- token 用量：每分钟每模型的消耗
CREATE FLOW genai_token_usage_flow
SINK TO genai_token_usage_1m
EXPIRE AFTER '24h'
AS
SELECT
  "span_attributes.gen_ai.request.model" AS model,
  COUNT("span_attributes.gen_ai.request.model") AS request_count,
  SUM(CAST("span_attributes.gen_ai.usage.input_tokens" AS DOUBLE)) AS total_input_tokens,
  SUM(CAST("span_attributes.gen_ai.usage.output_tokens" AS DOUBLE)) AS total_output_tokens,
  date_bin('1 minute'::INTERVAL, "timestamp") AS time_window
FROM opentelemetry_traces
WHERE "span_attributes.gen_ai.system" IS NOT NULL
GROUP BY "span_attributes.gen_ai.request.model", time_window;
```

**uddsketch 分位数聚合**：GreptimeDB 1.0 RC1 支持 `uddsketch_state(buckets, error_rate, value)` 保存分位数草图，通过 `uddsketch_calc(percentile, sketch)` 查询 p50/p95/p99 延迟，无需扫全量原始 traces ^[extracted]：

```sql
-- 延迟分布聚合
CREATE FLOW genai_latency_flow
SINK TO genai_latency_1m
EXPIRE AFTER '24h'
AS
SELECT
  "span_attributes.gen_ai.request.model" AS model,
  uddsketch_state(128, 0.01, duration_nano) AS duration_sketch,
  date_bin('1 minute'::INTERVAL, "timestamp") AS time_window
FROM opentelemetry_traces
WHERE "span_attributes.gen_ai.system" IS NOT NULL
GROUP BY "span_attributes.gen_ai.request.model", time_window;

-- 查询分位数
SELECT model,
  ROUND(uddsketch_calc(0.50, duration_sketch) / 1000000, 1) AS p50_ms,
  ROUND(uddsketch_calc(0.95, duration_sketch) / 1000000, 1) AS p95_ms
FROM genai_latency_1m;
```

### 2b. PromQL 查询共存

GreptimeDB 同时支持 SQL 和 PromQL，Grafana dashboard 里两种查询方式并列，共用同一套数据 ^[extracted]。OTel SDK 生成的 histogram metrics 可直接用 PromQL：

```promql
# token 消耗的 p95 分布
histogram_quantile(0.95,
  sum(rate(gen_ai_client_token_usage_bucket[5m])) by (le, gen_ai_token_type)
)

# 各模型请求速率
sum(rate(gen_ai_client_operation_duration_seconds_count[5m])) by (gen_ai_request_model)
```

### 3. 原始对话可搜索，点击直达 Trace

开启 `OTEL_INSTRUMENTATION_GENAI_CAPTURE_MESSAGE_CONTENT=true` 后，每条用户输入和模型输出都作为一条 log 记录写入 `genai_conversations` 表。GreptimeDB 接收 OTLP 日志时会自动创建该表，并对 `body` 列启用**全文索引**：

```sql
SELECT
  timestamp,
  trace_id,
  CASE WHEN json_get_string(parse_json(body), 'message.role') IS NOT NULL
    THEN json_get_string(parse_json(body), 'message.role')
    ELSE 'user' END AS role,
  COALESCE(
    json_get_string(parse_json(body), 'message.content'),
    json_get_string(parse_json(body), 'content')
  ) AS content
FROM genai_conversations
WHERE matches_term(body, 'GreptimeDB')
ORDER BY timestamp DESC
LIMIT 20;
```

## 与 Langfuse 的对比

| 维度 | GreptimeDB | Langfuse |
|------|-----------|----------|
| **定位** | 可观测性数据库（存储层） | LLM 工程平台（应用层） |
| **核心能力** | 统一存储 traces/metrics/logs，跨信号关联查询 | Trace 可视化、Prompt 管理、评估、实验 |
| **部署** | 开源版/企业版，支持云原生部署 | Docker Compose / Helm / Terraform |
| **适用场景** | 需要统一存储和灵活查询的底层基础设施 | 需要完整 LLM 工程闭环的应用层平台 |

两者可以互补：GreptimeDB 作为统一存储后端，Langfuse 作为上层应用平台。

## OB Cloud 多云日志存储实践

OceanBase 公有云（OB Cloud）覆盖七大主流公有云厂商，日志存储遇到了开发运维成本和运行成本两个核心问题：^[extracted]

- **开发运维成本**：各云厂商日志服务查询语法割裂，API 抽象难度大，每增加一个云就要重新适配。^[extracted]
- **运行成本**：阿里云 SLS 索引流量费用高昂，CloudWatch 按扫描量收费且查询性能到分钟级，Azure 存储费用也不便宜。^[extracted]

OB Cloud 团队先后评估了 ES（运维复杂且成本比 SLS 还高）、ClickHouse（当时不支持全文索引）、Loki（只对标签建索引，查询体验差），最终选择 GreptimeDB。^[extracted]

### 效果

- 大数据量查询从 Loki 的频繁超时提升到**亚秒到秒级响应**。^[extracted]
- 多云部署体验一致，对象存储加高效压缩带来更低存储成本。^[extracted]
- Pipeline 功能让 Fluent Bit 直采原始日志，在 GreptimeDB 内部完成解析和字段提取。^[extracted]
- 目前 OB Cloud 日志存储已全部切换到 GreptimeDB 企业版：**80+ 套集群，300 TB 数据（7 天保留），最大单集群超 50 TB，平均写入流量超 1 GB/s**。^[extracted]
- 日志存储成本降低 **60%**，同步下调对客 SQL 审计服务定价，帮助用户节省 60% 以上 SQL 审计成本。^[extracted]

### 智能诊断 Agent

OB Cloud 搭建了 Multi-Agent 智能诊断系统，其中可观测 Agent 通过 GreptimeDB 的 MCP Server 查日志和 SQL 审计数据，通过 OB Server MCP Server 查内部表，配合 PromQL 查指标。^[extracted] 开发同学甚至在自己的 Code Agent 上配了 MCP Server，AI 直接拉错误日志，结合代码上下文定位 bug。^[extracted]

## MCP + LLM 自然语言分析

GreptimeDB 用统一的表模型存储所有可观测性数据：Prometheus Metrics、OpenTelemetry Traces、日志都以表的形式存在，通过 SQL 和 PromQL 查询。^[extracted] 大模型只要了解表结构和字段含义，就能自己编排查询。^[extracted]

在 [[entities/deepflow|DeepFlow]] + [[entities/automq|AutoMQ]] + GreptimeDB 的端到端 Demo 中，通过 GreptimeDB 的 MCP Server 接入大模型，可用自然语言提问："过去 5 分钟对 GreptimeDB 发起了多少请求？分别用什么协议？延迟多少？"模型自动将问题转化为 SQL 查询统一存储的 Metrics/Logs/Traces 数据，几秒钟返回结果。^[extracted]

## 快速上手

项目开源在 GreptimeTeam/demo-scene，三步跑起来：

```bash
# 1. 设置 OpenAI API Key
export OPENAI_API_KEY="sk-..."

# 2. 启动全部服务（GreptimeDB + Grafana + load generator + Flow 聚合）
docker compose --profile load up -d

# 3. 打开 Grafana：http://localhost:3000（admin / admin）
#    打开 "GenAI Observability" dashboard
```

## 相关页面

- [[concepts/genai-observability-semconv]] — OpenTelemetry GenAI 语义规范
- [[concepts/ai-agent-observability]] — AI Agent 可观测性整体概念
- [[entities/langfuse-llm-observability]] — Langfuse LLM 可观测平台