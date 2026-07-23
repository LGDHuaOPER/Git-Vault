---
title: 7 款 LLM 可观测性与评测工具选型指南
category: references
tags:
  - ai-agent
  - observability
  - evaluation
  - tools
  - clippings
sources:
  - "尼可同学: AI 应用上线后怎么监控？7 款评测与可观测性工具，帮你告别“盲人调参” (2026-07-22)"
  - "数据菌在发呆: LLM应用上生产，不再“盲人摸象”！7款可观测性神器，让你的AI洞察一切！ (2026-06-16)"
summary: 尼可同学 2026 年 7 月对 7 款主流 LLM 可观测与评测工具的选型指南：LangSmith、Langfuse、Arize Phoenix、Datadog、Lunary、TruLens、Helicone 的定位、适用场景与选择逻辑。
provenance:
  extracted: 0.85
  inferred: 0.12
  ambiguous: 0.03
base_confidence: 0.68
lifecycle: draft
lifecycle_changed: 2026-07-22
tier: supporting
created: 2026-07-22T00:00:00+08:00
updated: 2026-07-22T12:00:00+08:00
relationships:
  - target: "[[entities/langfuse-llm-observability]]"
    type: related_to
  - target: "[[entities/langsmith]]"
    type: related_to
  - target: "[[entities/arize-phoenix]]"
    type: related_to
  - target: "[[entities/helicone]]"
    type: related_to
  - target: "[[entities/lunary]]"
    type: related_to
  - target: "[[entities/trulens]]"
    type: related_to
  - target: "[[concepts/observability-3-0]]"
    type: related_to
  - target: "[[skills/agent-observability-landing-guide]]"
    type: related_to
  - target: "[[concepts/llm-observability-tool-selection]]"
    type: related_to
  - target: "[[references/datadog-llm-observability]]"
    type: related_to
---

# 7 款 LLM 可观测性与评测工具选型指南

> 原文：AI 应用上线后怎么监控？7 款评测与可观测性工具，帮你告别“盲人调参”（尼可同学，2026-07-22）

LLM 应用上线后，传统监控只关注接口是否返回 200、服务器是否宕机已经远远不够。接口调用成功不代表回答正确，延迟没有异常不代表模型没有胡说，Agent 顺利跑完流程也不代表它调用了正确的工具。真正有用的可观测性平台需要把提示词组装、模型推理、知识库检索、工具调用、结果验证和多轮重试串成一条完整执行轨迹，让工程师看到每一步的输入、输出、耗时、成本和评分。

一套基本完整的大模型可观测性能力通常包括五部分 ^[extracted]：

- **执行轨迹**：记录模型调用、检索步骤、工具调用和 Agent 决策过程
- **质量评测**：用代码规则、人工标注或大模型裁判判断回答是否准确、相关、可靠
- **成本分析**：按模型、用户、会话或功能统计令牌消耗和调用费用
- **提示词管理**：保存提示词版本，比较修改前后的质量和成本变化
- **线上监控**：发现延迟异常、质量回退、安全风险和成本飙升，并触发告警

可观测性解决“发生了什么”，评测解决“做得好不好”。主流平台正在把这两者放到一起：先用执行轨迹还原过程，再用评测器为结果打分，最后把线上失败案例沉淀成新的测试集。

## 1. LangSmith：LangChain / LangGraph 团队最省心的选择

如果你的应用已经大量使用 [[entities/langsmith|LangChain]] 或 LangGraph，LangSmith 通常是阻力最小的起点。^[extracted] 它把开发、调试、评测和生产监控连成一套完整工作流。开启追踪后可以看到 Agent 调用了哪些工具、每一步生成了什么内容、哪一步耗时最长，以及最终为什么走到这个结果。^[extracted]

LangSmith 同时支持两类评测：上线前用固定数据集比较不同模型、提示词和工作流；上线后对真实流量抽样评分，监控安全、格式、回答质量和异常变化。线上失败轨迹可以直接加入数据集，修复后再跑回归测试。^[extracted]

**适合谁**：使用 LangChain 或 LangGraph，希望在同一平台完成追踪、数据集管理和评测的团队。^[extracted]

## 2. Langfuse：开源、自托管和提示词管理的均衡选手

[[entities/langfuse-llm-observability|Langfuse]] 是开源 LLM 工程平台，覆盖执行轨迹、评测、数据集、实验和提示词管理。基于 OpenTelemetry 构建，能接入现有分布式追踪体系，也支持 LangChain、LlamaIndex、CrewAI 和主流模型提供商。^[extracted]

Langfuse 的一个明显特点是把提示词当作正式工程资产。团队可以集中保存和发布提示词版本，把每个版本与执行轨迹、质量分数和成本关联起来，让提示词修改不再“凭感觉改几句话”。^[extracted] 自托管能力对重视数据主权的团队很有吸引力，但要区分“没有软件许可费”和“没有运维成本”。^[extracted]

**适合谁**：希望开源自托管、重视数据控制，同时需要追踪、评测和提示词管理的团队。^[extracted]

## 3. Arize Phoenix：RAG 和评测工作流的强项选手

如果你的应用高度依赖知识库检索，[[entities/arize-phoenix|Arize Phoenix]] 值得优先试。^[extracted] 它围绕 OpenTelemetry 和 OpenInference 构建，可以记录模型调用、检索、工具使用和自定义逻辑，并组织成完整轨迹。

Phoenix 对 RAG 应用尤其友好。RAG 出问题时不只看最终答案，因为故障可能发生在检索阶段（没找到正确资料）或生成阶段（拿到资料却没正确使用）。Phoenix 可以分别检查检索相关性、回答相关性和事实依据，并查看具体返回了哪些文档块。^[extracted] 对希望保留开放标准、避免埋点层被单一平台锁定的团队很有价值。^[extracted]

**适合谁**：RAG 比重较高、重视评测实验和数据可移植性的 AI 工程团队。^[extracted]

## 4. Datadog Agent Observability：把模型问题和基础设施问题放在一起看

如果公司已经全面使用 Datadog，没有必要为了大模型再搭一座新的监控孤岛。^[extracted] Datadog 已将相关能力扩展为 **Agent Observability**，能记录模型调用、工作流和动态 Agent 的完整轨迹，监控延迟、令牌、成本、错误和质量指标，并把这些数据与应用性能、日志、数据库和基础设施指标关联起来。^[extracted]

这对大型企业尤其重要：一次 Agent 延迟升高，原因未必是模型变慢，也可能是数据库阻塞、检索服务异常或资源不足。Datadog 的价值在于团队可以在同一监控体系里继续向下追查，而不必在多个平台之间来回切换。^[extracted]

**适合谁**：已经使用 Datadog 管理基础设施、APM 和日志，希望统一监控 Agent 与底层系统的企业。^[extracted]

## 5. Lunary：小团队快速看到用户、会话和成本

[[entities/lunary|Lunary]] 是一款开源 LLM 可观测性平台，提供执行轨迹、用户会话、成本统计、提示词管理和评测。它强调轻量接入，适合还没有专门平台团队、但已经需要看清线上使用情况的早期产品。^[extracted]

和单纯记录模型请求相比，Lunary 更重视用户和会话维度。你可以追踪某位用户经历了哪些对话、某类功能消耗了多少成本，并把最终用户的点赞、点踩或其他反馈接入评测流程。^[extracted]

**适合谁**：希望用较少工程投入获得会话追踪、成本分析和用户反馈的初创团队。^[extracted]

## 6. TruLens：不是先做监控，而是先把 RAG 评明白

如果你的核心问题是“如何严谨评价 RAG”，[[entities/trulens|TruLens]] 比通用监控平台更聚焦。^[extracted] 它最有代表性的概念是 **RAG Triad**，从三个维度检查 RAG：检索到的上下文是否与问题相关，回答是否与问题相关，回答是否真正建立在上下文证据之上。^[extracted]

这三个指标对应 RAG 最常见的三类故障：找错资料、答非所问、拿着正确资料继续胡编。^[extracted]

**适合谁**：以 RAG 质量评测为核心任务，希望深入比较检索和生成效果的研发团队。^[extracted]

## 7. Helicone：改一个接口地址，先把请求和成本看起来

[[entities/helicone|Helicone]] 与多数平台的接入方式不同。它可以作为模型 API 前面的网关：应用不再直接请求模型提供商，而是把请求发给 Helicone，再由它转发并记录。^[extracted] 很多场景只需要修改 API 基础地址，就能开始查看请求、令牌、成本、用户和会话数据。

代理层还可以承担缓存、限流和用量控制。对于重复请求较多或采用多租户计费的产品，这些能力能够直接影响成本。^[extracted] 但代理模式也意味着它位于请求链路中，团队必须认真评估数据流向、可用性、延迟和故障处理方案。^[extracted]

**适合谁**：需要快速接入请求日志和成本监控，或需要网关、缓存与用户用量控制的产品团队。^[extracted]

## 七款工具选型速查表

| 你的团队情况 | 优先考虑 | 核心理由 |
|-------------|---------|---------|
| 已经使用 LangChain 或 LangGraph | LangSmith | 原生追踪体验最好，开发与评测闭环完整 |
| 需要开源、自托管和数据主权 | Langfuse | 功能均衡，提示词管理成熟，部署自主 |
| RAG 很重，希望深入分析检索质量 | Arize Phoenix | RAG 轨迹和评测工作流完整，基于开放标准 |
| 企业已经全面使用 Datadog | Datadog Agent Observability | 能把 Agent、应用和基础设施问题统一关联 |
| 小团队想快速看用户、会话和成本 | Lunary | 轻量，用户分析和成本维度直观 |
| 当前最重要的是严谨评测 RAG | TruLens | 评测优先，RAG Triad 清晰、聚焦 |
| 想用最少代码先记录请求和费用 | Helicone | 代理接入快，还能提供缓存、限流和用量控制 |

## 选型建议：不要一上来就追求“大而全”

可观测性平台不是装上 SDK 就自动产生价值。如果没有定义关键任务、成功标准和需要监控的指标，再漂亮的仪表盘也只是堆积日志。更适合从一个最小闭环开始 ^[extracted]：

1. 选择 10 到 20 个最重要或最容易出错的真实任务
2. 为这些任务记录完整执行轨迹，包括模型、检索和工具调用
3. 先检查任务结果、错误率、延迟和成本，再增加少量质量评分
4. 把线上失败案例加入评测数据集，修复后运行回归测试
5. 只有当现有流程真的不够用时，再引入更复杂的告警、实验和自动评测

## 相关页面

- [[entities/langfuse-llm-observability]] — 开源 LLM 可观测平台
- [[entities/langsmith]] — LangChain 官方可观测平台
- [[entities/arize-phoenix]] — RAG 与评测导向的开源平台
- [[entities/lunary]] — 轻量开源 LLM 可观测平台
- [[entities/trulens]] — RAG 评测框架
- [[entities/helicone]] — LLM 网关与成本监控
- [[concepts/ai-agent-observability]] — AI Agent 可观测性整体概念
- [[concepts/observability-3-0]] — 可观测性范式演进到 Observability 3.0
- [[skills/agent-observability-landing-guide]] — Agent 可观测性从 0 到 1 落地路径
- [[concepts/llm-as-judge-evaluation]] — LLM-as-Judge 评测方法
- [[concepts/llm-observability-tool-selection]] — LLM 可观测性工具选型方法论
- [[references/datadog-llm-observability]] — Datadog LLM 可观测性介绍
