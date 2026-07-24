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
  - "阿里云可观测: Python 应用可观测重磅上线：解决 LLM 应用落地的"最后一公里"问题 (2024-11-08)"
  - "阿里云可观测: 零代码改造！LoongSuite AI 采集套件观测实战 (2025-09-01)"
  - "阿里云开发者: 详解大模型应用可观测全链路 (2025-03-13)"
  - "蒸馏大弟: OpenTelemetry CNCF毕业：Agent时代的可观测性标准已定 (2026-07-08)"
  - "程序猿架构之路: AI可观测性-Trace-Cost-质量三合一 (2026-07-01)"
  - "CNCF: 一文看懂 OpenTelemetry GenAI：LLM、Agent、MCP 怎么做可观测性 (2026-05-25)"
  - "GreptimeDB: 当 LLM 应用遇上可观测性：用 GreptimeDB 统一 Traces、Metrics 和对话记录 (2026-03-10)"
  - "AI Engineer编程: OpenTelemetry + Agent 可观测平台基础 (2026-07-11)"
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
updated: "2026-07-22"
relationships:
  - target: "[[concepts/ai-agent-observability]]"
    type: uses
  - target: "[[entities/loongsuite-platform]]"
    type: implements
  - target: "[[concepts/agent-trace-cost-quality-architecture]]"
    type: related_to
  - target: "[[entities/agenttrace]]"
    type: related_to
  - target: "[[entities/apache-doris-agent-observability]]"
    type: related_to
  - target: "[[entities/litefuse]]"
    type: uses
  - target: "[[references/agentlogsbench]]"
    type: related_to
  - target: "[[entities/arize-phoenix]]"
    type: related_to
  - target: "[[entities/dify]]"
    type: related_to
  - target: "[[entities/greptimedb]]"
    type: related_to
  - target: "[[references/loongsuite-pilot-open-source]]"
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

## OTel GenAI 语义规范六层结构

OTel GenAI 语义规范从 v1.37 到 v1.41 快速迭代，形成了覆盖 LLM 应用全链路的六层结构 ^[extracted]：

### Layer 1: Client Spans — 模型调用标准化

每次 LLM 调用产生一个 span，`gen_ai.operation.name` 设为 `chat` 或 `text_completion`。核心属性：

| 属性 | 含义 | 示例 |
|------|------|------|
| `gen_ai.provider.name` | 提供商标识 | `openai`、`anthropic`、`aws.bedrock` |
| `gen_ai.request.model` | 请求时指定的模型 | `gpt-4o-mini` |
| `gen_ai.response.model` | 实际响应的模型 | `gpt-4o-mini-2024-07-18` |
| `gen_ai.usage.input_tokens` | 输入 token 数 | `142` |
| `gen_ai.usage.output_tokens` | 输出 token 数 | `87` |
| `gen_ai.response.finish_reasons` | 停止原因 | `["stop"]`、`["tool_calls"]` |

Embeddings 新增 `gen_ai.embeddings.dimension.count` 记录向量维度数。Retrievals 覆盖 RAG pipeline 中的检索步骤。

### Layer 2: Agent & Workflow Spans — 超越微服务的新概念

传统分布式追踪没有"agent 调用"概念。GenAI 规范定义了全新操作类型 ^[extracted]：

| Span 类型 | 含义 | Span Kind |
|-----------|------|-----------|
| `create_agent` | Agent 创建（远程服务） | `CLIENT` |
| `invoke_agent` | Agent 调用（v1.41 拆分 CLIENT/INTERNAL） | `CLIENT`/`INTERNAL` |
| `invoke_workflow` | 预定义流程执行（v1.41 新增） | `CLIENT` |
| `execute_tool` | 工具执行（v1.41 起工具名必须出现在 span 名中） | `INTERNAL` |

Agent span 让执行流程可以被标准化拆解：

```
invoke_agent research-assistant (INTERNAL)
├── chat gpt-4o (CLIENT)                ← 模型决定需要搜索
├── execute_tool web_search (INTERNAL)  ← 执行搜索
├── chat gpt-4o (CLIENT)               ← 基于搜索结果继续推理
├── execute_tool summarize (INTERNAL)   ← 摘要处理
└── chat gpt-4o (CLIENT)               ← 生成最终回答
```

### Layer 3: MCP 语义约定 — 解决 Trace 断裂

MCP（Model Context Protocol）在 2025 年快速普及，但 agent 端和 MCP server 端的 trace 是断的。OTel v1.39 引入 MCP 语义约定解决此问题 ^[extracted]：

- 基于 JSON-RPC，但推荐用 MCP 约定而非通用 RPC 语义约定
- 核心属性：`mcp.method.name`、`mcp.session.id`、`mcp.protocol.version`、`gen_ai.tool.name`
- 去重逻辑：若外层 GenAI instrumentation 已追踪 tool 执行，MCP instrumentation 不创建重复 span，而是添加 MCP 属性
- 定义四个 MCP metric：`mcp.client.operation.duration`、`mcp.server.operation.duration`、`mcp.client.session.duration`、`mcp.server.session.duration`

### Layer 4: Events 与内容捕获 — 隐私与可观测性的平衡

两个核心 Event ^[extracted]：

1. **`gen_ai.client.inference.operation.details`**（v1.37 新增）：记录一次 GenAI 调用的完整输入输出（opt-in）
2. **`gen_ai.evaluation.result`**：记录 GenAI 输出的质量评估结果，包含 `gen_ai.evaluation.score.value` 和 `gen_ai.evaluation.score.label`

三种内容记录模式：

| 模式 | 说明 | 适用场景 |
|------|------|----------|
| 不记录（默认） | `OTEL_INSTRUMENTATION_GENAI_CAPTURE_MESSAGE_CONTENT` 默认 false | 最安全 |
| Span 属性记录 | `gen_ai.input.messages` 和 `gen_ai.output.messages` 作为 span attributes | 方便查看，但有大小限制 |
| 外部存储 + Span 引用 | 完整内容存到 S3/[[entities/greptimedb|GreptimeDB]] 等外部存储，span 上只保存引用地址 | 生产环境推荐，可单独设 IAM 和 retention |

### Layer 5: Metrics — 两个最基础的 Client Histogram

| Metric | 含义 | 单位 |
|--------|------|------|
| `gen_ai.client.operation.duration` | 每次 GenAI 操作的端到端延迟 | 秒 |
| `gen_ai.client.token.usage` | 每次操作的 token 消耗 | `{token}` |

Token 计量规则：提供商同时报告 used tokens 和 billable tokens 时，必须报告 billable tokens；无法高效获取时不应猜测。

### Layer 6: 提供商专属约定 — 从通用到特化

以 OpenAI 为例，在通用属性之外新增 ^[extracted]：

- `gen_ai.usage.cache_read.input_tokens`：从提供商缓存读取的 token 数
- `gen_ai.usage.cache_creation.input_tokens`：写入提供商缓存的 token 数
- `gen_ai.usage.reasoning.output_tokens`：推理过程消耗的 token 数（o1/o3 系列，v1.41 新增）

`gen_ai.provider.name` 作为鉴别器，决定该出现哪组专属属性。

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

### 1. Entry/Step Span

引入两级 Span 层次，补全从"单次调用"到"完整对话"的层级缺失：

- **Entry Span**：Agent 调用入口处的 Span，还原模型和用户的原始输入输出，形成对话历史，避免被 System Prompt 或框架 Prompt 干扰。
- **Step Span**：每次 ReAct 过程的层次化表达，支持 Top-down 排查——先定位哪一轮 ReAct 出问题，再深入该轮具体步骤。

### 2. Skill 语义

为 Agent 中可复用的技能（Skill）定义标准化属性，使跨 Agent 的技能调用可追踪：

| 属性 | 说明 |
|------|------|
| `gen_ai.skill.name` | Skill 名称 |
| `gen_ai.skill.id` | Skill 实例标识，区分灰度/A/B 实验 |
| `gen_ai.skill.description` | Skill 功能描述 |
| `gen_ai.skill.version` | Skill 版本号 |

同时向 OTel 社区提交了独立 `invoke_skill` Span 的提案（[open-telemetry/semantic-conventions-genai#86](https://github.com/open-telemetry/semantic-conventions-genai/issues/86)）。

### 3. Token 级推理观测

将观测粒度从"每次模型调用"细化到"每个 Token 的生成"，支持 TTFT 和 TPOT 的精确测量：

**Token 性能属性**：

| 属性 | 描述 |
|------|------|
| `gen_ai.response.per_token_time_to_schedule` | 每个 Token 进入迭代的时间戳 |
| `gen_ai.response.per_token_time_to_generate` | 每个 Token 出迭代的时间戳 |
| `gen_ai.iteration.per_token_batch_size` | 每个 Token 所在迭代批的总请求数 |
| `gen_ai.iteration.per_token_cumulative_count` | 每个 Token 所在迭代批的总 Token 数 |

**Token 精度属性**：

| 属性 | 描述 |
|------|------|
| `gen_ai.response.candidate.per_position_decoded_tokens` | 每个位置 top-k 候选 Token 字符串 |
| `gen_ai.response.candidate.per_position_token_ids` | 每个位置 top-k 候选 Token ID |
| `gen_ai.response.candidate.per_position_logprobs` | 每个位置 top-k 候选 Token logits |

这些扩展通过 OTel 社区的 GenAI SIG 向上游贡献，并已在阿里云内部 170+ 业务线规模化落地。

### GenAI Utils 工程化能力层

为降低各框架插桩库重复实现遥测逻辑的成本，LoongSuite 在探针中实现了 **GenAI Utils**：

- 插桩层只做数据提取，不直接操作 OTel API
- ExtendedTelemetryHandler 统一收口 Span 创建、属性挂载、Metrics 记录、Event 发送、Context 管理
- 语义规范升级时只改 Utils 一处，所有下游插桩库自动生效

已支持 Python 和 JS 版本，以及 DashScope、[[entities/dify|Dify]]、AgentScope、Mem0、MCP、Agno、Google ADK、LangChain 等框架插桩。

## 生态采用

所有主流 tracer 已采用 GenAI 语义约定：Langfuse、[[entities/arize-phoenix|Arize Phoenix]]、OpenLLMetry、Laminar。

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
- [[references/loongsuite-pilot-open-source|LoongSuite Pilot]] — 专门面向 AI Coding Agent 的端侧可观测采集器

参见 [[entities/loongsuite-platform]]。

## OTel Collector 部署与采样策略

在生产环境中，建议使用 **OTel Collector Gateway Mode** 集中处理遥测数据，而非应用直连后端 ^[extracted]：

### 为什么需要 Collector

| 场景 | 直接发送到后端 | 经过 Collector |
|------|---------------|---------------|
| 换后端 | 改代码，重启应用 | 改 Collector 配置，应用无感知 |
| 数据脱敏 | 每个应用自己实现 | Collector 统一处理 |
| 采样控制 | 各自配置 | 统一配置 |
| 多后端同时发送 | 应用发多份 | Collector 一份变多份 |

### 采样策略

| 策略 | 原理 | 适用场景 |
|------|------|---------|
| **头部采样** | 请求入口处决策，下游跟随 | 简单，减少发送量 |
| **尾部采样** | 等 Trace 完成后按内容决策 | 保留错误、慢请求 |
| **混合采样** | 头部降采样 + 尾部精细决策 | 生产推荐 |

Agent 系统推荐：基准采样 5%，错误/慢请求 100% 采集。真实案例：SaaS 应用 400 万请求/天，基准采样 5%，遥测成本降低 70%，SRE 团队仍有完整事故可视性。^[extracted]

### 动态采样降级

高流量下使用自适应采样器 ^[extracted]：
```python
class AdaptiveSampler(Sampler):
    def should_sample(self, ...):
        cpu = psutil.cpu_percent()
        if cpu > 90: return TraceIdRatioBased(0.001)  # 0.1%
        elif cpu > 70: return TraceIdRatioBased(0.01)  # 1%
        return TraceIdRatioBased(0.1)                   # 10%
```

### 分布式环境常见问题

- **时钟漂移**：子 Span 显示在父 Span 之前。解决：NTP/Chrony 同步 + OTel SDK 用单调时钟计算 duration。关键原则：只比较 Duration，不比较绝对时间戳。^[extracted]
- **高基数问题**：`user.id` 作为 Attribute 导致索引爆炸。解决：低基数字段（service、method）存 Span Attribute，高基数字段（user.id、request.id）存 Span Event 或 Log。查询流程：先查日志系统获得 trace_id 列表，再在 Trace 系统中查询完整链路。^[extracted]

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
- [[synthesis/genai-observability-semconv-x-langfuse-llm-observability]] — synthesis: standard vs product — the gap between evolving SemConv and production-ready Langfuse
