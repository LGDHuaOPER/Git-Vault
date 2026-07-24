---
title: Agent Trace and Timeline
category: concepts
tags: [ai, observability, agent, trace]
sources:
  - "一览清风: Agent Timeline：看懂 AI Agent 调试从看日志到看轨迹的变化 (2026-06-30)"
  - "ThinkingAgent: AI可观测性：Prompt、Tool Call、Trace、Token全链路追踪 (2026-06-22)"
  - "叶小钗: Agent Harness 可观测性 (2026-05-25)"
  - "SelectDB: Apache Doris 在 AgentLogsBench 中领先 (2026-07-07)"
  - "阿里云开发者: 详解大模型应用可观测全链路 (2025-03-13)"
  - "小加号编程笔记: AI Agent 可观测性：如何记录推理、工具调用、失败与成本 (2026-07-13)"
summary: Agent Trace 是有序的、多层级嵌套的执行链路记录，区别于传统 APM 的扁平 request-response trace。Agent Timeline 将 Trace 可视化为时间轴，支持按执行顺序回放完整推理过程。
provenance:
  extracted: 0.55
  inferred: 0.40
  ambiguous: 0.05
base_confidence: 0.78
lifecycle: draft
lifecycle_changed: 2026-07-16
tier: supporting
created: 2026-07-16T00:00:00+08:00
updated: "2026-07-24"
relationships:
  - target: "[[concepts/ai-agent-observability]]"
    type: derived_from
  - target: "[[concepts/agent-harness]]"
    type: related_to
  - target: "[[entities/ai-observe-stack]]"
    type: related_to
  - target: "[[entities/openclaw]]"
    type: related_to
  - target: "[[concepts/genai-observability-semconv]]"
    type: related_to
---

# Agent Trace and Timeline

Agent Trace 是 AI [[concepts/ai-agent-observability|Agent 可观测性]]的核心数据结构——它不是传统 APM 中的扁平 request-response span，而是**有序的、多层级嵌套的执行链路**，记录 Agent 从接收任务到完成输出的每一个推理步骤。

## 从日志到 Trace 的范式转变

传统调试方式依赖日志（Logs）：查看模型输入输出、工具调用结果、错误信息。但 Agent 执行涉及 10+ 轮 ReAct 推理循环，每轮包含模型调用、工具选择、结果反思，日志的线性结构无法还原这种分层、有序的决策流程。

**Agent Timeline** 的概念由 Honeycomb 在 2026 年 6 月的 OpenTelemetry 实操指南中系统化提出：当 AI Agent 不再只是回答问题，而是调用工具、访问数据库、修改文件时，运维者不能只看"最终回答"，必须能复盘它完成任务的**整条轨迹**。

## Trace 的数据结构

### Observation（观测单元）
Agent Trace 由一系列 Observation 构成，形成一个有序序列：

```
Trace
├── Span: Agent Task "修复失败的测试"
│   ├── Observation: LLM Call（模型分析错误）
│   ├── Observation: Tool Call（读取文件）
│   ├── Observation: LLM Call（生成修复方案）
│   ├── Observation: Tool Call（编辑文件）
│   ├── Observation: LLM Call（验证修复）
│   └── Observation: Tool Call（运行测试）
```

每个 Observation 携带：时间戳、类型（LLM / Tool / Retry / Embedding）、输入输出、Token 用量、耗时、状态码。^[inferred]

### 与传统 Trace 的关键差异

| 特征 | 传统 APM Trace | Agent Trace |
|------|---------------|-------------|
| Span 嵌套 | 2-3 层（HTTP → DB） | 10+ 层（Task → Reasoning → Tool → Retry） |
| Payload | 结构化键值对 | 大文本（5KB-1MB），含自然语言、代码、JSON |
| 排序需求 | 时间戳即可 | 严格有序，因推理步骤有因果依赖 |
| 查询模式 | 按状态码过滤 | 短语搜索、嵌套路径检索、Timeline 回放 |
| 关键字段 | HTTP method、status | 模型版本、Prompt 模板、工具名称、Token 数 |

## Agent Timeline 的六个失败层

Honeycomb 将 Agent 的失败位置分解为六个逐层递进的层次：

1. **输入失败** — Prompt 不完整、上下文窗口溢出、权限缺失
2. **模型失败** — 幻觉、逻辑矛盾、输出格式违反 schema
3. **工具失败** — API 超时、参数错误、返回空结果、schema 不匹配
4. **数据失败** — 检索到不相关文档（RAG）、向量相似度误导、知识库过期
5. **控制失败** — 无限推理循环、过早终止、工具选择策略错误
6. **结果失败** — 最终输出虽语法正确但不符合业务语义

Timeline 的核心价值在于**从"它错了"定位到"错在哪一步"**。^[inferred]

## 实现路径

### 全链路追踪的四要素
ThinkingAgent 文章总结的四个必须追踪的维度：

- **Prompt** — 每次模型调用的完整输入（含系统提示、历史消息、模板填充结果）
- **Tool Call** — 工具名称、参数、返回结果、耗时
- **Trace** — 完整调用链路的层级结构
- **Token** — 每次调用的 Token 消耗和成本

### 工具与平台

- **Langfuse** — 开源 LLM 可观测平台，提供 Trace 可视化、Prompt 版本管理、评估功能
- **LoongSuite** — 阿里云可观测体系，通过 [[concepts/genai-observability-semconv|OpenTelemetry GenAI SemConv]] 实现标准化 Trace 采集
- **Honeycomb** — 2026 年率先提出 Agent Timeline 概念，基于 OTel 实现

参见 [[entities/langfuse-llm-observability]]、[[entities/loongsuite-platform]]。

## 开放性议题

- Agent Trace 的存储成本远高于传统 Trace：每条 Trace 可能包含 MB 级文本 payload。OLAP 数据库（Doris/ClickHouse）vs 专用平台（Langfuse）的取舍尚未有定论 ^[ambiguous]
- Timeline 可视化的交互设计仍在早期：如何在一个界面上同时展示推理逻辑、工具调用参数和 Token 成本分布 ^[inferred]

## Trace Span 分类体系

一次 Agent Run 应被记录为一棵多层级的 Trace 树 ^[extracted]，根节点记录任务整体信息，下面挂载各类 Span：

| 层级 | 记录对象 | 关键字段 |
|------|---------|---------|
| Root Trace | 一次 Agent Run | `request_id`, `user_id_hash`, `session_id`, `goal`, `status`, `total_cost` |
| Planner Span | 计划生成 | `plan_id`, `steps_count`, `selected_strategy` |
| LLM Span | 一次模型调用 | `model`, `input_tokens`, `output_tokens`, `latency_ms`, `finish_reason` |
| Tool Span | 一次工具调用 | `tool_name`, `args_schema`, `duration_ms`, `status`, `result_size` |
| Memory Span | 记忆检索或写入 | `query`, `top_k`, `hit_ids`, `scores` |
| RAG Span | 检索增强 | `retriever`, `document_ids`, `scores`, `rerank_model` |
| Eval Span | 质量评估 | `score`, `label`, `judge_model`, `failure_reason` |

两个核心原则 ^[extracted]：(1) **不要只记录最终答案**——最终答案是结果，不是过程，真正能帮你 debug 的是每一步看到了什么、选择了什么；(2) **不要把所有内容都明文记录**——用户隐私、完整 Prompt、完整工具返回可能包含敏感信息，可记录 hash、摘要、字段 schema、脱敏片段、引用 ID。

### 推理记录策略

不推荐记录完整思维链（CoT），而应记录**可审计的决策摘要** ^[extracted]：

- ✅ 记录：`{step: "select_tool", decision: "call_order_status_tool", reason_summary: "...", confidence: 0.78}`
- ❌ 不记录：`{chain_of_thought: "非常长的逐字推理过程..."}`

原因：安全（链式推理可能泄露系统提示）、噪声（长文本难以稳定分析）、成本（存储查询成本高）、可用性（工程排查更需要"决策点+依据摘要+输入输出 ID"）。

## Related

- [[entities/ai-observe-stack]] — Agent Trace 数据的存储和检索基础设施
- [[entities/openclaw]] — OpenClaw 的 Timeline 回放需求是 Agent Trace 的典型应用场景
- [[concepts/llm-gpu-observability]] — LLM 推理层的 GPU 级观测
