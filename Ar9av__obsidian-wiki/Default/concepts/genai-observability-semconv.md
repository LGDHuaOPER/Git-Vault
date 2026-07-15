---
title: GenAI Observability Semantic Conventions
aliases:
  - OpenTelemetry GenAI SemConv
  - OpenTelemetry GenAI 语义约定
  - OTel GenAI Semantic Conventions
category: concepts
tags:
  - ai-agent
  - observability
  - opentelemetry
  - standards
sources:
  - "阿里云开发者: 阿里巴巴 & 蚂蚁 LoongSuite GenAI 可观测语义规范 (2026-05-12)"
  - "阿里云可观测: 零代码改造！LoongSuite AI 采集套件观测实战 (2025-09-01)"
  - "阿里云开发者: 详解大模型应用可观测全链路 (2025-03-13)"
  - "蒸馏大弟: OpenTelemetry CNCF毕业：Agent时代的可观测性标准已定 (2026-07-08)"
  - "程序猿架构之路: AI可观测性-Trace-Cost-质量三合一 (2026-07-01)"
summary: OpenTelemetry GenAI Semantic Conventions 是 OTel 社区为生成式 AI 场景制定的可观测数据采集标准，2026 年 5 月随 OTel CNCF 毕业进入稳定期。定义了 Model、Prompt、Token、Tool Calling、Agent、Session 等概念的统一字段命名和数据模型。中国社区（阿里/蚂蚁）在此基础上提出了 Entry/Step Span、Skill 语义、Token 级推理观测三项扩展。
provenance:
  extracted: 0.65
  inferred: 0.28
  ambiguous: 0.07
base_confidence: 0.78
lifecycle: draft
lifecycle_changed: 2026-07-16
tier: supporting
created: 2026-07-16T00:00:00+08:00
updated: 2026-07-16T12:00:00+08:00
relationships:
  - target: "[[concepts/ai-agent-observability]]"
    type: uses
  - target: "[[entities/loongsuite-platform]]"
    type: implements
  - target: "[[concepts/agent-trace-cost-quality-architecture]]"
    type: supports
  - target: "[[entities/agenttrace]]"
    type: related_to
  - target: "[[entities/apache-doris-agent-observability]]"
    type: related_to
  - target: "[[entities/litefuse]]"
    type: uses
  - target: "[[references/agentlogsbench]]"
    type: related_to
---

# GenAI Observability Semantic Conventions

OpenTelemetry GenAI Semantic Conventions（GenAI SemConv）是 OTel 社区自 2024 年初开始推动的**生成式 AI 可观测数据采集标准**。它的目标是像 HTTP SemConv 标准化 HTTP 请求的观测字段一样，为 Model、Prompt、Token、Tool Calling、Agent、Memory、Session 等 GenAI 原生概念建立统一的字段命名和数据模型。

## CNCF 毕业

2026 年 5 月 21 日，OpenTelemetry 正式从 CNCF 毕业，成为最高成熟度项目——与 Kubernetes、Prometheus 并列。

CNCF TOC 评价："OpenTelemetry 已经展现出成熟项目所需的治理、社区采用和技术成熟度。"

关键数据：
- 95% 的云原生新项目采用 OpenTelemetry
- 一次埋点，任意支持 OTLP 的后端（Datadog、Grafana、Honeycomb、New Relic、Azure Monitor、AWS X-Ray），换后端只需改 Collector 配置

## 为什么需要语义规范

AI Agent 系统的可观测面临天然的数据碎片化问题：

- **跨模型**：不同模型提供商的返回格式、元数据字段各不相同
- **跨框架**：LangChain、LlamaIndex、Spring AI Alibaba 等框架的记录方式不统一
- **跨平台**：不同可观测后端（Prometheus、Grafana、Datadog、自建平台）的消费口径不一致

没有统一语义规范时，不同团队各自记录"模型名""输入长度""Token 数""响应内容"等字段，字段命名和统计口径无法对齐。

## Agent 时代的遥测挑战

Agent 系统的遥测数据量比传统应用**多几个数量级**：

| 指标 | 传统 API | Agent 系统 |
|------|---------|-----------|
| Span 数 | 5-10 | 50-200+ |
| 数据倍增 | 基准 | 10-50x |
| 单次 Trace | KB 级 | KB-MB 级 |
| 日均总量 | GB 级 | TB 级 |

传统监控工具的假设（短生命周期、无状态、独立 request-response）与 Agent 系统的现实（长运行会话、有状态、多步工作流、非确定性调用图）根本不匹配。标准化已从"建议"变成"刚需"。

## 标准 Span 类型与属性

### Span 类型

| Span 类型 | 含义 |
|-----------|------|
| `gen_ai.chat` | LLM 模型调用 |
| `invoke_agent` | Agent 运行 |
| `execute_tool` | 工具调用 |

### 标准属性

| 属性 | 示例 | 用途 |
|------|------|------|
| `gen_ai.system` | `openai` / `anthropic` | LLM 提供商 |
| `gen_ai.request.model` | `gpt-4o-mini` | 模型路由对账 |
| `gen_ai.usage.input_tokens` | `2400` | 成本计算 |
| `gen_ai.usage.output_tokens` | `180` | 成本计算 |
| `gen_ai.response.finish_reasons` | `stop` | 截断诊断 |
| `gen_ai.request.temperature` | `0.7` | 采样温度参数 |
| `gen_ai.tool_call.name` | `search_docs` | 工具调用名称 |
| `gen_ai.tool_call.id` | `call_abc123` | 工具调用唯一标识 |

### 扩展属性（应用层）

| 属性 | 示例 | 用途 |
|------|------|------|
| `app.tenant_id` | `shop_882` | 租户 chargeback |
| `app.feature` | `checkout_assist` | 功能预算归因 |
| `app.trace.quality.faithfulness` | `0.87` | 质量得分接入 Trace |

## 四层价值

1. **统一数据语言** — 不同业务、不同基础设施、不同观测后端共享同一套字段语义
2. **支撑性能、成本、质量、安全的统一治理** — 标准化字段使 Token 用量、延迟、质量、安全事件可在统一仪表板上聚合
3. **跨团队可观测资产复用** — 算法团队的指标可被 SRE 团队的告警规则直接引用
4. **降低可观测工具的迁移成本** — 遵循 SemConv 的应用可无缝切换后端，无需修改插桩代码

## 中国社区的贡献：LoongSuite GenAI 扩展

阿里巴巴和蚂蚁集团在 OTel GenAI SemConv 的基础上提出了三个核心扩展提案：

1. **Entry/Step Span** — 引入两级 Span 层次：Entry Span 表示一次用户交互（Session 级别），Step Span 表示 Agent 的一个推理步骤，补全了从"单次调用"到"完整对话"的层级缺失。

2. **Skill 语义** — 为 Agent 中可复用的技能（Skill）定义标准化属性，包括 skill 名称、版本、输入输出 schema，使跨 Agent 的技能调用可追踪。

3. **Token 级推理观测** — 将观测粒度从"每次模型调用"细化到"每个 Token 的生成"，支持 TTFT（Time to First Token）和 TPOT（Time per Output Token）的精确测量。

这些扩展通过 OTel 社区的 GenAI SIG 向上游贡献，并已在阿里云内部 170+ 业务线规模化落地。

## 生态采用

所有主流 tracer 已采用 GenAI 语义约定：Langfuse、Arize Phoenix、OpenLLMetry、Laminar。

[[entities/litefuse|Litefuse]] 通过社区提供的 Doris Exporter 将 OTel Collector 采集的数据写入 Doris 的 VARIANT 列，实现与 OTel 生态的无缝对接。

## Go SDK 集成

Go SDK 状态：
- Traces 和 Metrics：**Stable**
- Logs：**Beta**（可能有 breaking changes）

最小化集成 3 步（10% 基准采样，错误/慢请求 100% 采集）：

```go
go get go.opentelemetry.io/otel@latest
go get go.opentelemetry.io/otel/sdk@latest
go get go.opentelemetry.io/otel/exporters/otlp/otlptrace/otlptracegrpc@latest

tp := sdktrace.NewTracerProvider(
    sdktrace.WithBatcher(exporter),
    sdktrace.WithSampler(sdktrace.ParentBased(
        sdktrace.TraceIDRatioBased(0.1),
    )),
)
handler := otelhttp.NewHandler(mux, "my-service")
```

Agent 系统额外步骤：
1. 手动埋点 GenAI 语义约定（`gen_ai.*` namespace）
2. 配置 Collector Gateway Mode（集中处理）
3. 实施智能采样：基准采样 5%，错误/慢请求 100%

真实案例：SaaS 应用 400 万请求/天，基准采样 5%，遥测成本降低 70%，SRE 团队仍有完整事故可视性。

## Vendor Neutrality

一次埋点，换后端只需改 Collector 配置，不用重写代码。OTel 的 vendor-neutral 设计避免了厂商锁定。

## 落地实践：LoongSuite AI 采集套件

LoongSuite 基于 GenAI SemConv 实现了**零代码改造**的 AI 应用可观测采集：

- **LoongCollector** — 主机级探针，通过 eBPF 和插件机制实现无侵入采集
- **语言 Agent** — Python、Java、Go 等语言的自动插桩 SDK
- **LoongSuite Pilot** — 专门面向 AI Coding Agent 的端侧可观测采集器

参见 [[entities/loongsuite-platform]]。

## 开放性议题

- GenAI SemConv 仍处于 Experimental 阶段，字段稳定性不足。生产环境建议通过映射层隔离变更影响
- 端侧 Agent（IDE 内运行的 Coding Agent）的可观测语义尚未进入 SemConv 范围，LoongSuite Pilot 是首个尝试
- SemConv 定义了"采集什么"，但"如何存储""如何查询"没有标准——[[references/agentlogsbench|AgentLogsBench]] 试图在后一个问题上建立基准

## 相关页面

- [[concepts/ai-agent-observability]] — AI Agent 可观测性整体概念
- [[concepts/agent-trace-cost-quality-architecture]] — 基于 OTel GenAI 约定的三合一架构
- [[entities/agenttrace]] — AgentTrace 的认知面如何补充 OTel 的操作面
- [[entities/apache-doris-agent-observability]] — Doris 作为 OTel 后端的存储引擎
- [[references/opentelemetry-genai-agent-setup]] — OTel 在 Agent 场景中的实战配置
