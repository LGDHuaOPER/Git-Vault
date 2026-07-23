---
title: AI Observability Layered Architecture
category: concepts
tags:
  - ai-agent
  - observability
  - opentelemetry
  - openinference
  - architecture
sources:
  - "唧唧复急急: AI 智能体应用时代，可观测性怎么做？ (2026-03-27)"
summary: 将 AI 可观测性工具按职责分为标准层、语义层、工作台层和网关/成本层，避免"一家全包"的选型误区，按需组合 OpenTelemetry、OpenInference、Phoenix/Langfuse、Helicone 等方案。
provenance:
  extracted: 0.75
  inferred: 0.20
  ambiguous: 0.05
base_confidence: 0.53
lifecycle: draft
lifecycle_changed: 2026-07-22
tier: supporting
created: 2026-07-22T00:00:00+08:00
updated: "2026-07-22"
relationships:
  - target: "[[concepts/ai-agent-observability]]"
    type: extends
  - target: "[[concepts/genai-observability-semconv]]"
    type: related_to
  - target: "[[entities/langfuse-llm-observability]]"
    type: related_to
  - target: "[[entities/arize-phoenix]]"
    type: related_to
  - target: "[[entities/helicone]]"
    type: related_to
  - target: "[[entities/langsmith]]"
    type: related_to
---

# AI Observability Layered Architecture

AI 智能体可观测性的开源生态不是"一家替代所有家"，而是**分层组合**。^[extracted] 把各层职责想清楚，选型反而更简单。^[extracted]

> "OpenTelemetry 管底座，OpenInference 管 AI 语义，Phoenix / Langfuse 管工作台，Helicone 管入口和成本；选型时先看自己缺哪一层，不要一上来找'一家全包'。"^[extracted]

## 四层架构

### 第一层：标准层

**代表**：[[concepts/genai-observability-semconv|OpenTelemetry]]

**解决的问题**：把一次 AI 请求放回团队熟悉的 trace、span、metric、log 体系里。^[extracted]

**适合团队**：
- 已有成熟 observability 栈，希望 AI 应用沿用现有采集、传输、存储和告警路径。^[extracted]
- 平台工程能力较强，希望埋点模型、工具、检索链路时不被某个上层产品绑死。^[extracted]

**边界**：OpenTelemetry 擅长定义链路和上下文传递，但默认不理解"这一步是检索""这一段文本是 prompt 模板""这次失败属于工具误调用"。^[extracted] 只停在这一层，会得到结构完整但业务解释力有限的 trace。^[extracted]

### 第二层：采集 / 语义层

**代表**：OpenInference

**解决的问题**：不是"有没有 trace"，而是"AI trace 里该有什么字段和语义"。^[extracted]

例如一次 LLM 调用，除了耗时和状态码，还应带上模型名、token 使用量、prompt、completion、tool call、retrieval metadata、评估结果、会话或任务标识。^[extracted] 没有这一层，团队容易把 AI 观测做成一堆普通 RPC span，再靠人工猜测哪一段是模型、哪一段是工具、哪一段是知识注入。^[extracted]

**与 OpenTelemetry 的关系**：不是对立，更像在后者之上补了一层 AI 语义——底下还是 trace，往上才有 prompt、document、tool、eval 这些对象。^[extracted]

**适合团队**：
- 有自研编排框架、Agent runtime 或中间层，希望把语义埋点掌握在自己手里。^[extracted]
- 准备同时接多种上层工具，不想一开始就锁死在某一家专有 SDK 里。^[extracted]

**边界**：语义约定不是工作台。它能把现场拍清楚，但不自动提供样本筛选、人工标注、实验对比和回归看板。^[extracted]

### 第三层：观测 / 评估工作台层

**代表**：[[entities/arize-phoenix|Arize Phoenix]]、[[entities/langfuse-llm-observability|Langfuse]]

**解决的问题**：把前面采到的 trace、prompt、检索片段、工具调用、评分结果、数据集、实验对比放到一个能日常使用的工作台里。^[extracted]

**分工差异**：
- **Phoenix** 更偏"面向评估与调试"的研究台气质，尤其适合把 trace、eval、dataset 放在一起看，做问题归因和实验比较。^[extracted]
- **Langfuse** 更偏"面向生产协作"的产品化工作台，在 tracing、prompt 管理、会话查看、标注与反馈闭环上更容易直接落地。^[extracted]

**适合团队**：已有线上流量，开始频繁做问题归因和评测迭代的小中型团队，或要给多个 AI 场景提供统一工作台的平台团队。^[extracted]

**边界**：工作台不是底层标准，也不是万能治理层。仍需回答数据从哪里来、要不要接入现有 tracing 栈、敏感数据怎么脱敏、线上入口流量由谁控制。^[extracted]

### 第四层：网关 / 成本层

**代表**：[[entities/helicone|Helicone]]

**解决的问题**：所有请求从哪里进、花了多少钱、能不能统一控流和审计。^[extracted]

**核心能力**：多模型路由、API 代理、请求日志、token 计费、成本分摊、缓存、限流、Key 管理。^[extracted]

**适合团队**：同时接多个模型供应商、多个团队共享模型预算、或需要先把调用入口收拢起来的平台化团队。^[extracted]

**边界**：能回答"钱花到哪了、流量怎么走、哪些请求异常"，但通常不擅长回答"这次回答为什么业务上不合格"。^[extracted]

## 分层选型决策树

```
初始阶段，没有能回看 trace、筛失败样本、顺手做点评估的地方？
→ 优先补工作台层（Phoenix / Langfuse）

已有一定基础，多个 AI 场景同时上线？
→ 底层用 OpenTelemetry + OpenInference 统一埋点和语义
→ 上层选 Phoenix 或 Langfuse 作为工作台

已有成熟 observability 栈？
→ 继续用 OpenTelemetry 承接基础链路
→ 引入 OpenInference 补 AI 语义
→ 加一层面向 AI 排障与评测的工作台
```

^[extracted]

## 开源方案对照

| 方案 | 分层定位 | 适合解决的问题 | 更适合的团队 | 主要边界 |
|------|---------|---------------|-------------|---------|
| OpenTelemetry | 标准层 / 基础遥测层 | 统一 trace、span、metric、log 表达 | 已有监控体系、希望保持开放标准的团队 | 能记链路，但不天然理解 prompt、tool、retrieval、eval 等 AI 语义 |
| OpenInference | 采集 / 语义层 | 给 LLM、Agent、Tool、Retriever、Evaluator 等对象补充统一语义 | 有自研 Agent runtime、希望跨工具复用语义埋点的团队 | 不是工作台；负责把现场描述清楚 |
| Phoenix | 观测 / 评估工作台层 | 结合 trace、eval、dataset、experiment 做调试、归因、回放与比较 | 已有线上流量，频繁做问题归因和评测迭代的团队 | 更偏评估与调试，不是底层标准或统一流量入口 |
| Langfuse | 观测 / 评估工作台层 | tracing、prompt 管理、会话查看、反馈闭环、数据集与实验协作 | 需要较快落地生产协作工作台的小中型团队 | 仍需搭配底层埋点和现有 observability / 治理体系 |
| Helicone | 网关 / 成本层 | 请求代理、成本核算、多模型路由、配额与入口治理 | 需要统一模型入口、控预算、做路由治理的平台型团队 | 更强在治理和记账，不是完整的评估 / 数据集工作台 |
| [[entities/langsmith|LangSmith]] | 开发调试 / 评测工作流层 | tracing、评测、调试、实验对比，适合 LangChain / LangGraph 生态 | 已深度使用 LangChain 生态、接受其路线的团队 | 不是纯开源路线，更多是平台化工作流 |

^[extracted]

## 选型原则

- **不要问谁最强，先问自己现在缺哪一层**。^[extracted]
- 初始阶段优先把排障和复盘跑起来，而不是追求完美分层。^[extracted]
- 成熟团队用开放标准层避免厂商锁定，再按需选上层工作台。^[extracted]

## 相关页面

- [[concepts/ai-agent-observability]] — AI Agent 可观测性总览
- [[concepts/genai-observability-semconv]] — OpenTelemetry GenAI 语义规范
- [[entities/langfuse-llm-observability]] — 工作台层开源方案
- [[entities/arize-phoenix]] — 工作台层开源方案
- [[entities/helicone]] — 网关 / 成本层方案
