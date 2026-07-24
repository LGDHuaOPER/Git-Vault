---
title: "Agent Trace and Span Taxonomy"
category: concepts
tags:
  - ai-agent
  - observability
  - tracing
  - opentelemetry
  - span-structure

relationships:
  - target: "[[concepts/ai-agent-observability]]"
    type: related_to
sources:
  - "AI Engineer编程: OpenTelemetry + Agent 可观测平台基础 (2026-07-11)"
  - "小加号编程笔记: AI Agent 可观测性：如何记录推理、工具调用、失败与成本 (2026-07-13)"
  - "阿里云可观测: AI 原生应用全栈可观测实践：以 DeepSeek 对话机器人为例"
  - "阿里云开发者: 阿里巴巴 & 蚂蚁 LoongSuite GenAI 可观测语义规范 (2026-05-12)"
  - "阿里云云原生: LLM 应用可观测性：从 Trace 视角展开的探索与实践之旅 (2024-07-24)"
summary: "Agent Run 的 Trace/Span 结构设计：树状层次模型、SpanKind 映射规则、阿里云 8 种 LLM Span Kind 分类体系、推理过程与工具调用的记录策略、以及 Attribute vs Event 的正确使用边界。"
base_confidence: 0.70
lifecycle: draft
lifecycle_changed: "2026-07-16"
tier: supporting
provenance:
  extracted: 0.6
  inferred: 0.3
  ambiguous: 0.1
created: 2026-07-16
updated: "2026-07-24"
---

# Agent Trace and Span Taxonomy

## 一次 Agent Run 的 Trace 结构

一次 Agent Run 应该被记录为一棵 **Trace Tree**，而非线性调用链。根 Span 代表整个用户请求，子 Span 代表内部的每一步操作：

```
Root Span: agent.run (SERVER)
├── Span: agent.plan (INTERNAL) — 推理/规划
├── Span: llm.call (CLIENT) — LLM 生成
├── Span: tool.search (CLIENT) — 工具调用
│   └── Span: tool.search.api_call (CLIENT)
├── Span: agent.reason (INTERNAL) — 基于工具结果的推理
├── Span: llm.call (CLIENT) — 二次 LLM 调用
└── Span: agent.output (INTERNAL) — 最终输出
```

## SpanKind 在 Agent 场景中的映射

| SpanKind | 含义 | Agent 场景示例 |
|----------|------|---------------|
| `SERVER` | 接收外部请求 | FastAPI 入口、`agent.run()` 入口 |
| `CLIENT` | 向外部发起请求 | 调用 OpenAI API、调用搜索工具 |
| `INTERNAL` | 内部操作 | Agent 规划、推理步骤、结果解析 |
| `PRODUCER` | 生产消息到队列 | Agent 发送任务到 Kafka |
| `CONSUMER` | 从队列消费消息 | Worker 消费任务 |

核心原则：SpanKind 回答"我在这次调用中扮演什么角色"，与物理位置（内网/外网）无关 ^[extracted]。

## Entry/Step Span：Agent 长链路的分层抽象

来自 LoongSuite GenAI 语义扩展，用于解决 Agent 长程任务中单个 Trace 包含成百上千 Span、调用链冗长难读的问题 ^[extracted]：

- **Entry Span**：Agent 调用入口处的 Span，还原模型和用户的原始输入输出，形成对话历史。这样可以获取最原始的客户请求，不受 System Prompt 或框架 Prompt 干扰。
- **Step Span**：每次 ReAct 过程的层次化表达。排查时先观察整体，定位到哪一轮 ReAct 出问题，再深入该轮具体步骤。

这种分层让 Agent 的多轮行动、反思以及对应执行结果一目了然。

## Attribute vs Event

| 维度 | Attribute | Event |
|------|-----------|-------|
| 本质 | Span 的静态元数据 | Span 生命周期中的关键时刻 |
| 时间戳 | 无（属于整个 Span） | 有独立时间戳 |
| 数量 | 通常 10-30 个 | 通常 0-5 个 |
| 用途 | 描述"这个操作是什么" | 记录"过程中发生了什么" |
| 查询 | "找出 model=deepseek 的 Span" | "找出包含 prompt.sent 的 Span" |

**高基数陷阱**：`user.id` 作为 Attribute 会导致索引爆炸。高基数数据（用户 ID、请求 ID）应放入 Span Event 或外部日志系统 ^[extracted]。低基数数据（service, method, status）适合作为 Attribute。

## 推理过程记录策略

Agent 的推理链（Chain-of-Thought）是否应该作为 Span 记录？

**应该**，但需要注意 ^[inferred]：
- 推理本身是最有价值的调试信息——"Agent 为什么选了这个工具"比"Agent 调了什么工具"更重要
- 推理过程应作为 INTERNAL Span 或 Span Event 记录，而非单独的外部调用
- 对于安全敏感场景，推理内容可能需要脱敏或选择性记录（见 [[agent-observability-fundamentals]] 隐私与安全部分）

## 工具调用记录

每次工具调用应该是一个独立的 CLIENT Span，记录：
- `tool.name` — 工具名称
- `tool.input` — 输入参数（可能需脱敏）
- `tool.output` — 返回结果（可能需截断）
- `tool.duration_ms` — 执行耗时
- `tool.status` — 成功/失败/超时

工具调用失败的 Span 不应简单标记为 ERROR，而应按 [[agent-failure-taxonomy]] 中的分类体系记录具体失败类型。

## 阿里云 LLM Span Kind 分类体系

阿里云 ARMS 在 2024 年提出了面向 LLM 应用的领域化 Trace 语义，定义了 8 种核心操作类型（LLM Span Kind），以会话串联用户交互、以 Trace 承载全链路节点 ^[extracted]：

| Span Kind | 含义 | 典型场景 |
|-----------|------|----------|
| **CHAIN** | 静态流程编排 | LangChain SequentialChain、Dify Workflow 中的编排节点，可嵌套包含 Retrieval、Embedding、LLM 调用等子 Span |
| **EMBEDDING** | 文本嵌入处理 | 对文本嵌入模型的操作，用于向量化查询文本或文档分片，支持后续相似度检索 |
| **RETRIEVER** | RAG 检索 | 从向量数据库获取补充上下文，提升 LLM 响应准确性。记录 document chunk 内容及相关度评分 |
| **RERANKER** | 文档重排序 | 对多个候选文档结合提问内容判断相关性并排序，返回 TopK 文档作为 LLM 上下文 |
| **TASK** | 自定义内部方法 | 本地 function 调用等应用自定义逻辑，如数据预处理、格式转换等非 LLM/工具操作 |
| **LLM** | 大模型调用 | 基于 SDK 或 OpenAPI 请求不同大模型进行推理或文本生成。记录 Prompt、模型请求参数、响应、Token 消耗 |
| **TOOL** | 外部工具调用 | 调用计算器、搜索 API、天气 API 等外部工具以获取实时信息。记录工具名称、入参、返回结果、耗时 |
| **AGENT** | 智能体动态编排 | 基于模型推理结果决策下一步执行的动态编排场景，可能涉及多轮 LLM + Tool 的循环调用 |

### 与 OTel GenAI 语义的对应关系

| 阿里云 Span Kind | OTel GenAI Span Kind（v1.41） | 说明 |
|------------------|------------------------------|------|
| CHAIN | —（框架层抽象） | OTel 不使用 CHAIN，而是依赖嵌套 Span 结构表达编排 |
| EMBEDDING | `gen_ai.embeddings` | OTel 通过 `gen_ai.operation.name = "embeddings"` 标识 |
| RETRIEVER | `retrieve` / `gen_ai.retrieval` | OTel v1.41 覆盖 RAG pipeline 中的检索步骤 |
| RERANKER | —（未有独立约定） | 阿里云将其独立为一种操作类型 |
| TASK | —（应用层自定义） | 应用层自定义 Span，无 GenAI 特定语义 |
| LLM | `gen_ai.chat` / `gen_ai.text_completion` | 对应 OTel Client Span（Layer 1） |
| TOOL | `execute_tool` (INTERNAL) | OTel v1.41 起工具名必须出现在 span 名中 |
| AGENT | `invoke_agent` (CLIENT/INTERNAL) | OTel 的 Agent 与 Workflow Span（Layer 2） |

阿里云的分类比 OTel GenAI 更早地引入了 RERANKER 和 TASK 等操作类型，反映了一种"从实际工程场景出发定义语义"而非"从协议规范出发"的思路 ^[inferred]。这一分类已被阿里云 ARMS Python Agent 完整实现，开发者可通过 `aliyun-instrumentation-llama-index` 等 SDK 自动接入。

## 相关页面

- [[concepts/ai-agent-observability]] — Agent 可观测性基础概念
- [[concepts/genai-observability-semconv]] — OTel GenAI 语义规范（标准层）
- [[concepts/agent-failure-taxonomy]] — Agent 失败分类
- [[concepts/agent-cost-breakdown]] — 成本观测
- [[references/opentelemetry-genai-agent-setup]] — OTel SDK 实际配置
- [[references/aliyun-end-to-end-ai-observability]] — 阿里云端到端 AI 可观测实践
