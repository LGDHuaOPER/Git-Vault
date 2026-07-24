---
title: AI Agent Observability
aliases:
  - Agent Observability
  - Agent 可观测性
  - Agent Observability Fundamentals
  - Agent 可观测性范式转变
category: concepts
tags:
  - ai-agent
  - observability
  - tracing
  - metrics
  - llm
sources:
  - "阿里云开发者: 当 AI Coding Agent 成为基础设施：我们为什么要开源 LoongSuite Pilot (2026-06-12)"
  - "阿里云开发者: 阿里巴巴 & 蚂蚁 LoongSuite GenAI 可观测语义规范 (2026-05-12)"
  - "阿里云开发者: 详解大模型应用可观测全链路 (2025-03-13)"
  - "阿里云开发者社区: 从 AI Agent 到模型推理：端到端 AI 可观测实践 (2026-07-16)"
  - "InfoQ: AI 原生应用全栈可观测实践：以 DeepSeek 对话机器人为例 (2026-07-16)"
  - "SelectDB: 我们用 AI Observe Stack 观测了 OpenClaw (2026-03-04)"
  - "SelectDB: Apache Doris 在 AgentLogsBench 中领先 (2026-07-07)"
  - "ThinkingAgent: AI可观测性：Prompt、Tool Call、Trace、Token全链路追踪 (2026-06-22)"
  - "叶小钗: Agent 可观测性：为什么有了 LangChain，还会出现 Langfuse？ (2026-06-10)"
  - "叶小钗: Agent Harness 可观测性 (2026-05-25)"
  - "阿里云可观测: 零代码改造！LoongSuite AI 采集套件观测实战 (2025-09-01)"
  - "一览清风: Agent Timeline：看懂 AI Agent 调试从看日志到看轨迹的变化 (2026-06-30)"
  - "小加号编程笔记: AI Agent 可观测性：如何记录推理、工具调用、失败与成本 (2026-07-13)"
  - "ThinkingAgent: AI安全和治理：AI Observability、Evaluation、治理、安全与成本 (2026-06-28)"
  - "FutureCraft AI: 第12篇：Agent 可观测性——看见你的 Agent 在想什么 (2026-06-02)"
  - "SelectDB: Agent 时代为什么需要新的可观测范式？ (2026-05-21)"
  - "数栖云间: Apache Doris 在 AI Agent 可观测性中的架构实践 (2026-03-12)"
  - "一臻数据: Litefuse 正式发布！Doris 原生 Agent 可观测平台来了 (2026-05-21)"
  - "AI Engineer编程微信公众号: Agent 可观测与质量评测体系：从数据采集到数据飞轮的完整实践 (2026-07-12)"
  - "祥聊AI: AI Agent 可观测性：看不见的链路，才是最贵的技术债 (2026-04-12)"
  - "机器之魂: LLM 可观测性：大多数生产级 AI 系统中缺失的那一层 (2026-04-17)"
  - "智枢圈: 理论篇-14 大模型评估与可观测性 (2026-05-11)"
  - "安全进化论: 让智能体可观察可评估可进化 (2026-06-15)"
  - "企业大模型应用和开发: Agent Harness Engineering 可观测性与运维 (2026-06-07)"
  - "随野录: Agent Harness 可观测性 (2026-06-03)"
  - "云计算开源产业联盟: 中国信通院联合发布《面向LLM应用的可观测性能力要求》 (2025-07-31)"
  - "阿里技术: 大模型可观测1-5-10：发现、定位、恢复的三层能力建设 (2025-09-21)"
  - "自由的灵魂在路上: [Alan の测试] 从硬规则到 LLM Judge：如何搭建一套可落地的 AI 客服评测系统 (2026-07-22)"
  - "架构驿站: 一文读懂 LLM 可观测性 (2024-01-13)"
  - "Datadog: What Is LLM Observability & Monitoring (2024-04-23)"
  - "可执行AI方案库: Spring AI 应用上生产，最先缺的不是模型，而是可观测性 (2026-04-18)"
  - "腾讯云架构师技术同盟: 生成式 AI 可观测性 2.0：成本、安全、质量三大支柱 (2026-06-24)"
  - "唧唧复急急: AI 智能体应用时代，可观测性怎么做？ (2026-03-27)"
  - "小加号编程笔记: AI Agent 可观测性：如何记录推理、工具调用、失败与成本 (2026-07-13)"
  - "AI随记: 【大模型应用开发从零做起】第28篇：你的AI应用正在裸奔——2026年，可观测性从可选项变成必选项 (2026-07-22)"
  - "Python技术Gang: 【AI白皮书】AI可观测 (2025-12-31)"
  - "前端早读课: AI可观测性：大语言模型与智能体的全链路透视 (2026-05-14)"
  - "云云众生s: LLM在可观测性中制造新盲区 (2026-02-12)"
summary: AI Agent 可观测性是理解、调试和治理 AI Agent 系统内部状态与行为的完整能力体系。涵盖了三大架构视角：(1)四层工具生态（标准/语义/工作台/网关），(2)三层数据架构（接入/计算存储/应用），以及 (3)全栈覆盖架构（应用层/AI网关/推理引擎/MCP服务），形成从黑盒到透明的完整观测方案。 AI Agent 可观测性是理解、调试和治理 AI Agent 系统内部状态与行为的完整能力体系。核心问题是"任务有没有做对"而非"系统有没有崩"——从 HTTP 200 到语义正确性的范式跨越。涵盖四大观测维度（Trace/Prompt/Tool Call/Token）、三层架构设计（接入/计算存储/应用）、四层开源生态（标准/语义/工作台/网关）、四大支柱（Tracing/Metrics/Logging/Alerting）、六层失败模型，以及观测→评估→归因→优化的闭环流程。
provenance:
  extracted: 0.67
  inferred: 0.26
  ambiguous: 0.07
base_confidence: 0.82
lifecycle: draft
lifecycle_changed: 2026-07-16
tier: core
created: 2026-07-16T00:00:00+08:00
updated: "2026-07-25"
relationships:
  - target: "[[concepts/agent-trace-and-timeline]]"
    type: extends
  - target: "[[concepts/agent-trace-span-taxonomy]]"
    type: extends
  - target: "[[concepts/agent-harness]]"
    type: related_to
  - target: "[[concepts/genai-observability-semconv]]"
    type: uses
  - target: "[[concepts/agent-cost-breakdown]]"
    type: related_to
  - target: "[[concepts/agent-failure-taxonomy]]"
    type: extends
  - target: "[[concepts/ai-production-engineering-five-pillars]]"
    type: related_to
  - target: "[[concepts/evaluation-driven-development]]"
    type: related_to
  - target: "[[concepts/agent-online-evaluation]]"
    type: related_to
  - target: "[[concepts/agent-data-flywheel]]"
    type: related_to
  - target: "[[entities/deepseek-observability-agent]]"
    type: related_to
  - target: "[[references/alicloud-loongcollector-agent-sandbox]]"
    type: related_to
  - target: "[[references/stepfun-selectdb-pb-observability]]"
    type: related_to
  - target: "[[entities/signoz]]"
    type: related_to
  - target: "[[entities/openllmetry]]"
    type: related_to
  - target: "[[entities/dify]]"
    type: related_to
  - target: "[[entities/vllm]]"
    type: related_to
  - target: "[[entities/helicone]]"
    type: related_to
  - target: "[[entities/langsmith]]"
    type: related_to
  - target: "[[entities/loongsuite-pilot]]"
    type: related_to
  - target: "[[concepts/observability-3-0]]"
    type: related_to
  - target: "[[references/7-llm-observability-tools]]"
    type: related_to
  - target: "[[skills/openclaw-observability-setup-tencent-cloud]]"
    type: related_to
  - target: "[[concepts/agent-observability-metrics]]"
    type: related_to
  - target: "[[references/agent-observability-seeing-thoughts]]"
    type: related_to
  - target: "[[concepts/ai-coding-agent-observability]]"
    type: related_to
  - target: "[[concepts/genai-observability-2.0]]"
    type: related_to
  - target: "[[concepts/llm-observability-tool-selection]]"
    type: related_to
  - target: "[[references/agent-harness-observability]]"
    type: related_to
  - target: "[[references/ai-agent-observability-invisible-chain]]"
    type: related_to
  - target: "[[references/llm-observability-agent-interview]]"
    type: related_to
---

# AI Agent Observability

AI Agent 可观测性是理解 AI Agent 系统内部状态和行为的完整能力。它不是简单的日志记录，而是从用户输入 → Prompt → LLM 调用 → Tool Call → 多轮推理 → 最终输出的全链路可视化与诊断体系。

## 范式转变：从 HTTP 200 到语义正确性

传统可观测性（APM）的核心问题是：**系统有没有正常运行？** Prometheus 看 CPU/内存，Grafana 看延迟/QPS，ELK 看错误日志。P99 延迟 0.2 秒、错误率 0.001%——运维同学可以安心下班。

Agent 时代，这套逻辑彻底失效。

某团队上线了一款客服 Agent：监控大盘全绿，HTTP 状态码 200，工具调用链路正常，模型响应时间达标。但系统把一个符合退款政策的订单直接回复为"根据政策无法退款"。从任何传统[[concepts/agent-observability-metrics|可观测指标]]看，没有异常。**但 Agent 在业务层给出了错误答案。**

核心问题转移了：**在系统正常运行的同时，任务真的做对了吗？**

## 为什么 Agent 比普通服务更需要可观测性

传统 APM 围绕结构化、稳定且可预测的遥测数据展开：HTTP 状态码、延迟分位数、错误计数等，schema 固定、payload 较小。AI Agent 有三个根本差异：

1. **非确定性输出**：相同输入可能产生不同输出，传统"请求-响应成功率"模型失效。Agent 的行为取决于模型推理、工具选择和环境状态，而不是固定的代码路径。

2. **多步推理链路**：一次用户请求可能触发 4-10 次 LLM 调用、多次工具调用、内部规划的生成与修正。链路长且分支多，传统 trace 粒度不足。

3. **成本不可见**：Agent 的成本不只是 API 调用费用，还包含 Token 消耗、工具调用费、重试浪费。没有观测就无法优化。

从数据层面看，量变引起质变：

| 维度 | 传统可观测 | Agent 可观测 |
|------|-----------|-------------|
| 文本长度 | KB 级别 | MB 级别（百万 token 上下文） |
| Trace 规模 | 几个 Span / 请求 | 数百到数万 Span / 任务 |
| 数据格式 | 结构化的元数据 | input/output 大量嵌套 JSON |
| 数据总量 | 日均 GB 级 | 日均 TB 级 |
| Trace 跨度 | 毫秒到秒 | 数小时到数天 |

## 四大观测维度

AI Agent 可观测性围绕四个核心维度展开：

### 1. Trace 链路追踪
完整的调用链路，从用户输入到最终输出。一条 Agent Trace 通常包含多层嵌套：Span → Observation → LLM Call / Tool Call / Retry。参见 [[concepts/agent-trace-and-timeline]] 和 [[concepts/agent-trace-span-taxonomy]]。

### 2. Prompt 追踪
记录所有 Prompt（包括动态生成的系统提示、模板变量填充结果），追踪每次模型调用的输入输出和性能指标（延迟、Token 数、首次 Token 时间）。

### 3. Tool Call 追踪
监控 Agent 调用的所有外部工具（API、数据库、文件系统、搜索引擎），记录调用参数、返回结果、耗时、失败重试。

### 4. Token 与成本追踪
Token 消耗、API 调用费用的实时监控，支持按应用、租户、模型版本等维度聚合。详见 [[concepts/agent-cost-breakdown]]。

## 四大支柱框架

部分实践者将可观测能力组织为四大支柱：

### 1. Tracing（追踪）
记录每次 AI 调用的完整链路：Prompt → 模型推理 → Tool Call → 输出 → 用户反馈。Agent trace 需要建模成树状结构，而不仅仅是线性的 span 序列。

### 2. Metrics（指标）
实时监控关键指标：延迟（P50/P95/P99）、成功率、Token 消耗、质量评分。Agent metrics 需要多维度——按模型、按任务类型、按用户/租户拆分。

### 3. Logging（日志）
结构化日志，支持搜索和分析。Agent 日志的特殊性在于推理链（Chain-of-Thought）本身也是重要的观测对象——[[references/agent-observability-seeing-thoughts|"它在想什么"]]往往比"它做了什么"更能解释问题。

### 4. Alerting（告警）
异常检测和自动告警：质量下降（如 hallucination 率上升）、成本飙升（Token 消耗异常）、安全事件（越狱尝试）。告警阈值需要基于历史基线动态调整。

## 与传统 APM 的关键差异

| 维度 | 传统 APM | AI Agent 可观测性 |
|------|----------|-------------------|
| 观测对象 | 代码路径（确定性） | 推理路径（非确定性） |
| 数据形态 | 结构化、固定 schema | 半结构化、大文本、动态 JSON |
| Trace 结构 | 线性调用链 | 树状决策图 / 多层嵌套 ReAct 循环 |
| 核心指标 | QPS、延迟、错误率 | 质量/Token/工具成功率/推理步数/TTFT/TPOT |
| 告警逻辑 | 阈值告警 | 基线漂移告警 + 语义告警 |
| 成本模型 | 基础设施成本 | Token 计费 + 工具调用费 |
| 故障模型 | 超时、5xx、OOM | Prompt 注入、幻觉、工具误调用、推理循环 |
| 排障方式 | 查日志、看监控面板 | 回放 Timeline、检索嵌套路径、对比多轮推理 |

## 传统可观测性的三个结构性错位

来自支付宝 AIDD 2026 演讲中对 Agent 可观测性挑战的系统性总结 ^[extracted]：

1. **链路错位**：Agent 可能循环调用工具、回退重试，传统 Trace 图画出来"全是一团乱麻"——线性链路无法表达循环与回退，Agent 的执行图更像决策树而非调用链。

2. **指标失灵**：系统不报错、延迟低，但 Agent 可能在"一本正经地胡说八道"。"答对"才是 Agent 的唯一健康指标，但传统指标无法感知语义正确性。

3. **黑盒困境**：LLM 是个黑盒，只知道给出了离谱答案，却无法定位中间哪一步推理"跑偏"了——传统日志只能看到最终输出，看不到推理轨迹、工具调用决策和记忆状态变化。

这三个错位倒逼可观测性目标从"系统是否正常运行"升维为"系统是否正确思考与行动"。

## Agent 的六层失败模型

来自 Honeycomb 的 Agent Timeline 实践框架，将 Agent 的失败位置分为六层：

1. **输入失败** — Prompt 不完整、上下文不足、权限缺失
2. **模型失败** — 幻觉、逻辑错误、输出格式不符
3. **工具失败** — API 超时、返回空结果、schema 不匹配
4. **数据失败** — 检索到错误文档、向量相似度误导
5. **控制失败** — 循环推理、过早终止、工具选择错误
6. **结果失败** — 最终输出不符合业务预期

Timeline 的核心价值在于**从"它错了"定位到"错在哪一步"**。详见 [[concepts/agent-failure-taxonomy]]。

## 全栈可观测架构：四层覆盖

除了上述三层数据架构，业界（阿里云等）还提出了按 **观测对象** 划分的全栈覆盖视角，将 AI 系统的可观测性分为四个层次 ^[extracted]：

### 1. AI 原生应用可观测

面向 LLM 应用开发者，解决四大痛点：工具选择盲区（Agent 选择了错误工具）、错误排除困难（非确定性的多步推理中定位失败点）、Token 消耗黑洞（隐形成本失控）、循环调用陷阱（Agent 陷入推理死循环）。^[extracted]

所需能力：零代码接入、可视化工具选择过程、精准故障定位、Token 成本分析、端到端链路追踪。^[extracted]

### 2. AI 网关可观测

AI 网关位于应用和模型之间，需覆盖五个维度的观测 ^[extracted]：

| 维度 | 观测内容 |
|------|---------|
| **性能与稳定性** | QPS、成功率、响应时间、流式/非流式请求分布 |
| **资源消耗与成本** | Token 消耗数/s、按模型/消费者维度的 Token 统计 |
| **安全与合规审计** | 内容安全拦截日志、风险类型统计、异常消费者检测 |
| **治理策略执行** | 限流统计、缓存命中率、Fallback 执行路径 |
| **多租户与权限** | 消费者身份识别、消费者级指标、异常消费者检测 |

^[extracted]

### 3. 推理引擎可观测

推理引擎（如 [[entities/vllm|vLLM]]、SGLang）是 AI 算法与硬件之间的桥梁。四个核心观测维度 ^[extracted]：

| 维度 | 观测项 |
|------|--------|
| **API Server** | 请求速率、并发数、错误率 |
| **模型输入输出** | Token 数、prompt/completion 长度、TTFT |
| **推理过程** | Scheduler 队列深度、prefill/decode 耗时、KV Cache 命中率 |
| **引擎状态** | GPU 利用率、显存使用、批处理大小 |

^[extracted]

TTFT（首 Token 时间）直接影响用户体验，高 TTFT 可从提示词长度、并发排队、KV Cache 使用率等维度优化。^[extracted]

### 4. MCP 服务可观测

MCP（Model Context Protocol）服务器作为 Agent 调用外部工具和数据源的桥梁，其可观测数据（调用参数、返回结果、耗时、失败重试）会自动采集到可观测平台中，与 Agent 的核心 Trace 整合为统一视图。^[extracted]

> 一个典型演示场景：LangChain Agent + Qwen Turbo 通过 SLS MCP 服务器访问日志接口，Agent 与 MCP 服务器的所有观测数据自动采集到统一可观测平台。^[extracted]

## 多语言插桩技术

面向 AI 应用的多语言链路插桩，不同语言采用不同的无侵入/低侵入策略 ^[extracted]：

| 语言 | 技术 | 策略 |
|------|------|------|
| **Python** | Monkey Patch | 运行时动态替换函数实现，无需修改源码 |
| **Java** | 字节码增强 | 通过 Java Agent 在类加载时注入埋点 |
| **Go** | 编译时插桩 | 在编译阶段注入追踪代码 |
| **其他** | OpenTelemetry SDK | 通过 OTel 开源框架手动/自动接入 |

^[extracted]

## 观测→评估闭环

面向 Agent 的可观测与效果评估深度融合，形成闭环：

面向 Agent 原生的全链路可观测体系，分为三层 ^[extracted]：

### 接入层：多形态、无侵入、标准化

| 接入形态 | 代表框架 | 策略 |
|---|---|---|
| 高代码 | LangChain、LlamaIndex、AutoGen、Spring AI | SDK 深度埋点 |
| 低代码 | Dify、Langflow | 平台扩展机制注入 |
| 通用 Agent | OpenClaw | 运行时统一采集 |
| 多语言 | Python/Node.js/Java/Go | 字节码增强/eBPF 无侵入埋点 |

关键设计：基于 OTEL 标准保证生态兼容性，同时通过 LoongSuite 进行 GenAI 语义扩展，实现框架无关的埋点抽象。^[extracted]

### 计算 & 存储层：Agent 原生数据处理

- **GENAI 语义对齐**：将技术 Span 转化为语义角色（llm_call、retriever_search、tool_execution），实现从"函数调用"到"Agent 决策"的语义跃迁 ^[extracted]
- **Trace 尾采样**：基于错误、慢请求、异常模式等聚合结果做尾部采样，平衡高成本场景下的存储效率
- **UModel 实体拓扑**：构建 LLM 模型、Tool、Knowledge Base、Agent 实例的关联图谱，实现从"链路追踪"到"系统理解"的升级 ^[extracted]

### 应用层：三维分析

| 维度 | 分析内容 | 业务价值 |
|---|---|---|
| 性能分析 | Token 消耗、LLM/工具调用耗时、平均推理轮次 | 优化用户体验 |
| 安全审计 | 敏感信息泄露、越权工具调用、Prompt 注入 | 合规与风控 |
| 成本分析 | 模型调用费用趋势、会话成本核算 | FinOps 决策 |

## Agent 性能指标维度扩展

除了传统延迟和吞吐量，Agent 场景引入了全新的性能指标 ^[extracted]：

- **TTFT**（Time To First Token）— 首 Token 延迟，直接影响用户等待感知
- **TPOT**（Time Per Output Token）— 每输出 Token 耗时，决定流式响应流畅度
- **SSE 流式输出质量** — 流式传输的稳定性和完整性
- **对话轮次** — 完成一个任务所需的推理步数，反映 Agent 效率

这些指标直接关联用户实时体验，成为 Agent 可观测的核心度量对象。

## 数据采集目标多元化

Token 消耗、文本、图片、音频、视频等多模态内容的采集，涉及大体积数据的采样压缩、敏感内容脱敏等新挑战。Agent Trace 的数据量比传统 APM 高 1-2 个数量级，存储和传输成本不可忽视。^[extracted]

## 观测→评估闭环

面向 Agent 的可观测与效果评估深度融合，形成闭环：

1. **上线前**：通过测试集与评估器量化对比不同版本的回答效果
2. **上线后**：持续采集真实用户的交互轨迹与 Agent 内部执行路径
3. **异常排查**：发现 Bad Case 后自动或半自动归因至 Prompt、上下文、模型或工具问题
4. **持续迭代**：将 Bad Case 转化为评测样本，在下一轮验证优化效果

这个闭环就是 **观测 → 评估 → 归因 → 优化 → 再评估**。完整的数据飞轮闭环参见 [[concepts/agent-data-flywheel]]，在线评估体系参见 [[concepts/agent-online-evaluation]]。

## 最小落地闭环

从 Day 1 开始的最小可观测方案：

1. 记录每次 Agent Run 的完整输入输出（结构化日志）
2. 记录每次 LLM 调用的 Token 消耗（成本追踪）
3. 对最终输出做简单的质量评估（LLM-as-Judge）
4. 设置成本异常的告警阈值

## 生态与工具

### 开源平台
- [[entities/langfuse-llm-observability]] — 最成熟的开源 LLM 可观测平台（28.5K Star）
- [[entities/ai-observe-stack]] — 基于 Apache Doris 的 AI 可观测存储后端
- [[entities/loongsuite-platform]] — 阿里云 LoongSuite 可观测体系
- [[entities/litefuse]] — 基于 Doris 的开源 Agent 可观测与评估平台
- [[entities/signoz]] — 天生支持 OpenTelemetry 的开源 APM
- [[entities/openllmetry]] — 面向 LLM 生态的自动插桩 SDK
- [[entities/agenttrace]] — UC Berkeley 三层结构化追踪框架
- [[entities/mcpspy-ebpf-mcp-monitoring]] — 基于 eBPF 的 MCP 无侵入可观测
- [[entities/deepseek-observability-agent]] — DeepSeek 在可观测性智能体中的实践
- [[entities/dify]] — 开源 LLMOps 平台（常与可观测探针集成）
- [[entities/vllm]] — 开源大模型推理加速框架（可被探针观测）
- [[entities/agentloop]] — 阿里云 AgentLoop 自进化平台（Agent 级全栈观测与评估）

### 标准化
- [[concepts/genai-observability-semconv]] — OpenTelemetry GenAI 语义规范
- [[references/agentlogsbench]] — Agent 可观测存储基准测试
- [[references/caict-llm-observability-standard]] — 中国信通院《面向LLM应用的可观测性能力要求》

### 工程模式
- [[concepts/agent-harness]] — Agent 执行环境的工程框架
- [[concepts/ai-production-engineering-five-pillars]] — 运行工程化的完整框架

### 案例与部署
- [[references/alicloud-loongcollector-agent-sandbox]] — 阿里云 ARMS AI 可观测方案
- [[references/stepfun-selectdb-pb-observability]] — 阶跃星辰 PB 级 Agent 可观测平台
- [[references/spring-ai-otel-langfuse]] — Spring AI + OpenTelemetry + Langfuse 生产级方案
- [[references/dify-phoenix-integration]] — Dify 平台集成 Phoenix 实战
- [[references/aliyun-end-to-end-ai-observability]] — 阿里云端到端 AI 可观测实践（含 Dify 生产优化）
- [[references/agent-new-observability-paradigm-litefuse]] — Agent 新可观测范式
- [[references/llm-observability-five-pillars]] — LLM 可观测性五大支柱
- [[references/ai-customer-service-evaluation-alan]] — AI 客服评测工程实践
- [[references/2026-07-16-infoq-deepseek-chatbot-observability]] — QCon 演讲：DeepSeek 对话机器人全栈可观测实践

## 行业标准与规范

### 中国信通院《面向LLM应用的可观测性能力要求》

2025 年 7 月，中国信息通信研究院联合阿里云、华为云、腾讯云、百度等 29 家单位发布**国内首个面向 LLM 应用的可观测性能力分级标准** ^[extracted]。标准以数据的采集、建模、存储、应用为主线，分为四大部分：

| 层级 | 规范内容 |
|------|----------|
| **基础设施层** | 网络、存储、主机、操作系统、系统进程的指标 |
| **中间件层** | RAG、语义缓存、MCP、向量数据库的指标 |
| **模型层** | 模型指标、成本指标、评估指标、多模态评估指标 |
| **模型服务层** | 性能指标（QPS、响应时间、Token 消耗、首 Token 延时、并发连接数、吞吐量）、失败指标（失效率、推理超时率、错误类型频率）、计量指标（按时间/消费者/模型维度的请求数和 Token 数） |
| **应用层** | 性能指标、内容质量、用户体验指标、失败指标 |

数据应用层要求支持会话分析能力：会话数据与用户终端信息整合、会话响应时间分析、会话准确性分析、会话一致性检查、用户行为模式识别。

### 阿里巴巴可观测 1-5-10 框架

阿里巴巴提出的**发现（1）、定位（5）、恢复（10）**三层能力建设框架 ^[extracted]：

**发现（1）**：监控告警体系
- 业务监控：自定义日志 + 日志服务/QuickBI/DataV/云监控构建业务大盘
- 云产品监控：百炼模型观测 + 云监控 + ARMS 应用实时监控

核心指标分三类：
- **可用性**：资源水位（QPM/Token 使用率）、分析维度（应用、功能模块、模型、工作空间）
- **性能**：调用量、延迟、成功率
- **业务反馈**：用户差评率

**定位（5）**：问题排查 SOP
1. 应急发起：收集问题现象
2. 确认应急类型：水位高/系统报错/延迟等
3. 确认异常场景：429 错误/其他错误码/延迟
4. 排查原因：结合业务监控和云产品监控定位
5. 启动应急预案：限流/扩容/降级

**恢复（10）**：预案执行
- 业务系统侧限流
- 工作空间配额调整
- 联系云厂商扩容

### 生成式 AI 可观测性 2.0：三大支柱

腾讯云提出的**成本、安全、质量**三大支柱框架 ^[extracted]：

**成本支柱**：
- 风险：钱包拒绝服务攻击（Denial of Wallet）、模型漂移导致的账单暴涨
- 应对：Token 配额与断路器（基于用户/租户维度的窗口期 Token 计数）、工具调用预算（Agent 思考链最大深度）

**安全支柱**：
- 输入端：语义扫描/越狱检测（Llama-Guard 或向量匹配）
- 输出端：正则 + NER 混合扫描，敏感信息脱敏或拦截

**质量支柱**：
- LLM-as-a-Judge 机制，重点观测两个指标（参考 RAGAS 框架）：
  - 上下文相关性（Context Relevance）：检索知识是否真能回答用户问题
  - 忠实度（Faithfulness）：回答是否有严谨依据来源于检索上下文
- 异步流评估：用户请求、检索上下文、模型回答推送到 Kafka，后置评估服务打分
- 幻觉率趋势图和回答质量水位线，平均得分低于 0.8 触发工程告警

## LLM 可观测性五大支柱

来自 Arize 和业界早期实践总结的框架 ^[extracted]：

| 支柱 | 关注点 |
|------|--------|
| **Evaluation** | 验证 LLM 性能，捕捉幻觉和问答问题 |
| **LLM Traces and Spans** | 捕获 LangChain、LlamaIndex 等框架的执行路径 |
| **Prompt Analysis and Troubleshooting** | 使用 Evals 和实时生产数据重现问题 |
| **Search and Retrieval** | RAG 故障排除和评估 |
| **Fine-tuning** | 收集真实/人工数据支持微调工作流 |

## 硬规则与软质量分离

在客服等高风险场景中，评测必须区分硬约束和软质量 ^[extracted]：
- **硬规则**：能用字符串、结构化字段、顺序或知识字段确定的要求，由代码判断；事实编造、越界承诺、结束后营销等红线独立否决
- **软质量**：需要理解语义、自然度、承接关系的要求，使用 LLM Judge
- **不可冒充**：没有检索轨迹就不要报告检索 Recall，非流式接口就不要报告 TTFT

## 开源生态的四层架构

面向 Agent 的可观测开源工具可按职责分为四层，避免"一家全包"的选型误区。详见 [[concepts/ai-observability-layered-architecture]]：^[extracted]

| 层级 | 代表 | 职责 | 边界 |
|------|------|------|------|
| **标准层** | OpenTelemetry | 统一 trace/span/metric/log 表达，接入现有 observability 栈 | 能记链路，但不天然理解 prompt、tool、retrieval、eval 等 AI 语义 |
| **语义层** | OpenInference | 给 LLM、Agent、Tool、Retriever、Evaluator 补充统一语义 | 不是工作台；负责把现场描述清楚 |
| **工作台层** | Phoenix、Langfuse | 把 trace、eval、dataset、experiment 放到日常使用的工作台 | 不是底层标准，也不是统一流量入口 |
| **网关/成本层** | [[entities/helicone|Helicone]] | 统一入口、记账、配额、路由、审计 | 不擅长业务质量归因 |

^[extracted]

## 从 0 到 1 的最小落地路径

Agent 可观测平台建设不要一开始就追求平台化。更务实的做法分五步：^[extracted]

1. **定义最小任务单元**：选核心、高投诉、价值清晰的任务，统一 `trace_id`/`session_id`。^[extracted]
2. **埋齐关键字段与事件**：请求标识、模型调用、检索信息、工具调用、Agent 过程、结果信息、评估信息，以及 8 类关键事件。^[extracted]
3. **叠加轻量 evaluation**：规则评估 + 人工反馈 + 模型评审并行，能上什么先上什么。^[extracted]
4. **沉淀失败数据集**：把投诉样本、eval 不通过样本、高成本样本、工具误调用样本等沉淀为带 trace 链接和故障标签的数据集。^[extracted]
5. **用实验驱动迭代**：改 prompt/工具/检索前，先在失败数据集上做对照实验，盯住质量、成本、延迟、人工接管率四个维度。^[extracted]

完整实操指南参见 [[skills/agent-observability-landing-guide]]。

## 生产落地常见陷阱

- **只采模型调用，不采业务语义**：不知道任务是什么、结果有没有业务价值，数据很难支持业务排障。解决办法是从第一天起带上 `task_type`、成功定义、失败分类。^[extracted]
- **trace 很细，但没有版本信息**：没有 prompt 版本、工具 schema 版本、知识版本、评估器版本，团队难以判断波动是模型漂了还是配置改了。^[extracted]
- **把 evaluation 当成一次性项目**：业务变了、知识变了、流程变了，评估标准还是旧的。evaluation 本身也是生产系统的一部分，需要持续维护。^[extracted]
- **坏样本积累了，但没有统一标签**：今天"答偏了"，明天"工具乱调"，后天"知识有问题"，无法形成可统计、可回归的故障分类。建议第一版就用粗标签如 `retrieval_miss`、`stale_knowledge`、`tool_misfire`、`loop_runaway`、`unsafe_answer`、`should_handoff_but_not`。^[extracted]
- **只盯质量，不盯成本**：准确率升了一点，但 loop 次数、token 和工具调用数一起飙升，最后无法规模化上线。任何改动都要同时过质量和成本两道门。^[extracted]
- **敏感数据直接全量落库**：把用户原文、身份证号、合同内容、内部文档全量扔进 tracing 系统，后面一定会出合规问题。更稳妥的做法是分级存储、字段脱敏、敏感内容打标、原文按权限回看、设置保留周期。^[extracted]

## 2026 年行业转向：可观测性从"可选项"变成"必选项"

2026 年是大模型应用从"能不能用"进入"稳不稳定"阶段的分水岭 ^[extracted]：

- **阿里云**：2026 年 7 月 30 日，正式将"LLM 应用监控"更名为"AI Agent 可观测"，入口迁至云监控 2.0 ^[extracted]
- **LangChain 行业报告**：《2026 年 AI Agent 行业报告》显示，近 89% 的受访者已为 Agent 部署了可观测性能力 ^[extracted]
- **IBM**：在 Think 2026 大会上正式发布 Instana GenAI Observability 升级版，助力团队从被动故障排查转型为主动合规式 AI 运行 ^[extracted]

传统 APM 的两个根本失效 ^[extracted]：
1. **监控对象变了**：传统监控关注代码路径（确定性），Agent 监控关注推理路径（非确定性）——同样的 Prompt，每次结果都可能不同
2. **评判维度变了**：HTTP 200 ≠ 业务正确。监控面板全绿，但 Agent 可能在业务层给出了错误答案

因此，可观测性在 2026 年已从技术栈的可选项变为生产部署的必选项。如果团队不能回答"上次 Prompt 改动后质量变了多少""最近一周在哪类请求上表现最差""成本上涨是哪个环节的 Token 增加了"这三个问题，说明 LLM 应用仍在裸奔。

## 开放性议题

- Agent 可观测数据的存储方案选择：专用 OLAP（Doris/ClickHouse）vs 通用可观测后端（Elasticsearch/Loki）vs 专用平台（Langfuse/[[entities/langsmith|LangSmith]]）
- 端侧 Agent（如 AI Coding Agent）的可观测盲区如何填补 — [[entities/loongsuite-pilot|LoongSuite Pilot]] 是首个系统性尝试
- Agent 评估（Evaluation）与可观测性（Observability）的边界模糊化趋势
- Timeline 可视化的交互设计仍在早期：如何在一个界面上同时展示推理逻辑、工具调用参数和 Token 成本分布

## LLM 可观测性要解决的典型问题

从生产实践看，LLM 应用常见的五类问题 ^[extracted]：

| 问题 | 说明 |
|------|------|
| **幻觉** | LLM 偶尔产生虚假信息，尤其在面对无答案的查询时给出看似自信但实际有缺陷的回答 |
| **性能和成本** | 依赖第三方模型导致 API 性能下降、算法变化不一致、大数据量下高成本 |
| **提示词破解** | 用户通过 Prompt 注入影响 LLM 产生特定/有害内容 |
| **安全和数据隐私** | 数据泄露、训练数据偏差导致的偏见、未经授权访问、生成包含敏感或个人数据的响应 |
| **提示和响应差异** | 相同查询收到不同响应，导致混淆和不一致体验 |

## eBPF：高质量可观测信号源

eBPF 通过零侵扰、全栈采集能力，为可观测性智能体提供高质量数据基础设施。相比传统 APM，eBPF 能覆盖 APM 插桩无法覆盖的网关、中间件、数据库、DNS、K8s 网络等全链路组件。详见 [[concepts/ebpf-observability-agent]]。

## Related

- [[concepts/observability-3-0]] — 可观测性范式演进到 Observability 3.0（概率系统时代）
- [[references/7-llm-observability-tools]] — 7 款 LLM 可观测与评测工具选型指南
- [[skills/openclaw-observability-setup-tencent-cloud]] — OpenClaw 在腾讯云的可观测接入实操
- [[concepts/ai-coding-agent-observability]] — AI Coding Agent 可观测性（端侧场景）
- [[concepts/genai-observability-2.0]] — 生成式 AI 可观测性 2.0：成本、安全、质量三大支柱
- [[concepts/llm-observability-tool-selection]] — LLM 可观测性工具选型方法论
- [[references/agent-harness-observability]] — Agent Harness Engineering 可观测性与运维
- [[references/ai-agent-observability-invisible-chain]] — AI Agent 可观测性：看不见的链路，才是最贵的技术债
- [[references/llm-observability-agent-interview]] — LLM 可观测性在 Agent 系统中的应用（面试题视角）
- [[synthesis/ai-agent-observability-x-langfuse-llm-observability]] — synthesis: theory vs implementation — the framework's ambition outpaces Langfuse's trace model
- [[synthesis/ai-agent-observability-x-dify]] — synthesis: observability vs abstraction — low-code platforms create observability blind spots
- [[synthesis/ai-agent-observability-x-arize-phoenix]] — synthesis: general framework vs RAG-specialized — the framework under-specifies RAG's four sub-layers
