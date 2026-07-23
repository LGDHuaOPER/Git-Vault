---
title: LLM 可观测性工具选型
category: concepts
tags:
  - ai-agent
  - observability
  - evaluation
  - tool-selection
  - llm
sources:
  - "尼可同学: AI 应用上线后怎么监控？7 款评测与可观测性工具，帮你告别“盲人调参” (2026-07-22)"
summary: 基于 LangSmith、Langfuse、Arize Phoenix、Datadog、Lunary、TruLens、Helicone 七款主流 LLM 可观测性平台的能力差异与适用场景，建立按现有技术栈、数据要求和当前痛点三维度选型的决策框架。
base_confidence: 0.70
lifecycle: draft
lifecycle_changed: "2026-07-22"
tier: supporting
provenance:
  extracted: 0.75
  inferred: 0.20
  ambiguous: 0.05
created: "2026-07-22"
updated: "2026-07-22"
relationships:
  - target: "[[concepts/ai-agent-observability]]"
    type: related_to
  - target: "[[entities/langfuse-llm-observability]]"
    type: related_to
  - target: "[[entities/arize-phoenix]]"
    type: related_to
  - target: "[[entities/greptimedb]]"
    type: related_to
  - target: "[[concepts/rag-observability]]"
    type: related_to
  - target: "[[entities/helicone]]"
    type: related_to
  - target: "[[entities/langsmith]]"
    type: related_to
  - target: "[[entities/lunary]]"
    type: related_to
  - target: "[[references/datadog-llm-observability]]"
    type: related_to
---

# LLM 可观测性工具选型

大模型应用的可观测性平台不是“功能越多越好”，而是要看团队当前最急着解决哪一个问题。^[inferred] 选型时应先回答三个问题：我们需要看见什么？数据必须留在哪里？哪个问题最值得先解决？^[extracted]

## 可观测性到底在“观察”什么

传统监控关注系统是否正常运行，而大模型可观测性还要回答：**模型为什么给出这个结果？**^[extracted]

一次 Agent 请求背后通常包含提示词组装、模型推理、知识库检索、工具调用、结果验证和多轮重试。有用的平台会把这些步骤串成一条完整的执行轨迹，让工程师看到每一步的输入、输出、耗时、成本和评分。^[extracted]

一套基本完整的 LLM 可观测性能力包括五部分：^[extracted]

| 能力 | 解决的问题 |
|------|-----------|
| **执行轨迹** | 记录模型调用、检索步骤、工具调用和 Agent 决策过程 |
| **质量评测** | 用代码规则、人工标注或大模型裁判判断回答是否准确、相关、可靠 |
| **成本分析** | 按模型、用户、会话或功能统计令牌消耗和调用费用 |
| **提示词管理** | 保存提示词版本，比较修改前后的质量和成本变化 |
| **线上监控** | 发现延迟异常、质量回退、安全风险和成本飙升，并触发告警 |

可观测性解决“发生了什么”，评测解决“做得好不好”。^[extracted]

## 七款平台速查

### [[entities/langsmith|LangSmith]]：LangChain / LangGraph 团队最省心

- **优势**：LangChain 团队开发，把开发、调试、评测和生产监控连成一套完整工作流；自动追踪和调试体验在 LangChain 生态中最顺滑
- **适合**：已大量使用 LangChain 或 LangGraph，希望在同一平台完成追踪、数据集管理和评测的团队
- **注意**：完整自托管主要面向企业方案，数据部署方式和预算需提前确认 ^[extracted]

### Langfuse：开源、自托管和提示词管理的均衡选手

- **优势**：开源 LLM 工程平台，覆盖轨迹、评测、数据集、实验和提示词管理；基于 OpenTelemetry，可接入现有分布式追踪体系；提示词作为工程资产管理成熟
- **适合**：希望开源自托管、重视数据控制，同时需要追踪、评测和提示词管理的团队
- **注意**：自托管不等于零成本，数据库、升级、备份、权限和监控都需要维护 ^[extracted]

### Arize Phoenix：RAG 和评测工作流的强项选手

- **优势**：围绕 OpenTelemetry 和 OpenInference 构建，RAG 分析尤其友好，可分别检查检索相关性、回答相关性和事实依据；支持代码检查、大模型裁判和人工标注
- **适合**：RAG 比重较高、重视评测实验和数据可移植性的 AI 工程团队 ^[extracted]

### Datadog Agent Observability：把模型问题和基础设施问题放在一起看

- **优势**：与公司已有的 APM、日志、基础设施指标关联；能继续向下追查 Agent 延迟升高的根因（数据库阻塞、检索服务异常、资源不足）
- **适合**：已经全面使用 [[references/datadog-llm-observability|Datadog]] 管理基础设施、APM 和日志，希望统一监控 Agent 与底层系统的企业
- **注意**：平台相对偏重，对尚未建立 Datadog 体系的小团队不是最轻量起点 ^[extracted]

### [[entities/lunary|Lunary]]：小团队快速看到用户、会话和成本

- **优势**：开源、轻量接入，重视用户和会话维度；可追踪某位用户经历了哪些对话、某类功能消耗了多少成本，并把用户反馈接入评测
- **适合**：希望用较少工程投入获得会话追踪、成本分析和用户反馈的初创团队
- **注意**：生态规模和企业级集成能力与头部平台仍有差距 ^[extracted]

### TruLens：先把 RAG 评明白

- **优势**：以评测为中心，提出 RAG Triad：上下文相关性、回答相关性、事实依据性，对应 RAG 最常见的三类故障
- **适合**：以 RAG 质量评测为核心任务，希望深入比较检索和生成效果的研发团队
- **注意**：更像专用评测框架，完整告警、用户分析和基础设施关联通常需与其他工具搭配 ^[extracted]

### [[entities/helicone|Helicone]]：改一个接口地址，先把请求和成本看起来

- **优势**：可作为模型 API 前面的网关，很多场景只需修改 API 基础地址即可开始查看请求、令牌、成本、用户和会话数据；代理层还可承担缓存、限流和用量控制
- **适合**：需要快速接入请求日志和成本监控，或需要网关、缓存与用户用量控制的产品团队
- **注意**：代理模式位于请求链路中，需认真评估数据流向、可用性、延迟和故障处理 ^[extracted]

## 选型决策表

| 团队情况 | 优先考虑 | 核心理由 |
|----------|----------|---------|
| 已使用 LangChain / LangGraph | LangSmith | 原生追踪体验最好，开发与评测闭环完整 |
| 需要开源、自托管和数据主权 | Langfuse | 功能均衡，提示词管理成熟，部署自主 |
| RAG 很重，希望深入分析检索质量 | Arize Phoenix | RAG 轨迹和评测工作流完整，基于开放标准 |
| 企业已全面使用 Datadog | Datadog Agent Observability | 能把 Agent、应用和基础设施问题统一关联 |
| 小团队想快速看用户、会话和成本 | Lunary | 轻量，用户分析和成本维度直观 |
| 当前最重要的是严谨评测 RAG | TruLens | 评测优先，RAG Triad 清晰、聚焦 |
| 想用最少代码先记录请求和费用 | Helicone | 代理接入快，还能提供缓存、限流和用量控制 |

## 选型三步骤

1. **先看现有技术栈**。已深度绑定 LangGraph 就试 LangSmith；已全面使用 Datadog 就优先复用现有平台。^[extracted]
2. **再看数据要求**。需要数据留在自己的环境里，就重点比较 Langfuse、Phoenix、Lunary、TruLens 和 Helicone 的自托管方案。^[extracted]
3. **最后看当前痛点**。想调试 Agent 看执行轨迹，想改善 RAG 看检索评测，想控制账单看用户和成本，目标不同答案也不同。^[extracted]

## 落地建议：不要一上来就追求“大而全”

可观测性平台不是装上 SDK 就自动产生价值。如果没有定义关键任务、成功标准和需要监控的指标，再漂亮的仪表盘也只是堆积日志。^[extracted]

最小闭环：^[extracted]

1. 选择 10–20 个最重要或最容易出错的真实任务
2. 为这些任务记录完整执行轨迹，包括模型、检索和工具调用
3. 先检查任务结果、错误率、延迟和成本，再增加少量质量评分
4. 把线上失败案例加入评测数据集，修复后运行回归测试
5. 只有当现有流程真的不够用时，再引入更复杂的告警、实验和自动评测

## 相关页面

- [[entities/langfuse-llm-observability]] — 开源 LLM 可观测平台
- [[entities/arize-phoenix]] — 基于 OpenTelemetry 的 AI 可观测平台
- [[entities/greptimedb]] — 统一可观测性数据库
- [[concepts/ai-agent-observability]] — AI Agent 可观测性整体概念
- [[concepts/rag-observability]] — RAG 可观测性
- [[concepts/evaluation-driven-development]] — 评估驱动开发方法论
