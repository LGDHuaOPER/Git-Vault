---
title: "Agent Trace and Span Taxonomy"
category: concepts
tags:
  - ai-agent
  - observability
  - tracing
  - opentelemetry
  - span-structure
sources:
  - "AI Engineer编程: OpenTelemetry + Agent 可观测平台基础 (2026-07-11)"
  - "小加号编程笔记: AI Agent 可观测性：如何记录推理、工具调用、失败与成本 (2026-07-13)"
  - "阿里云可观测: AI 原生应用全栈可观测实践：以 DeepSeek 对话机器人为例"
summary: "Agent Run 的 Trace/Span 结构设计：树状层次模型、SpanKind 映射规则、推理过程与工具调用的记录策略、以及 Attribute vs Event 的正确使用边界。"
base_confidence: 0.67
lifecycle: draft
lifecycle_changed: "2026-07-16"
tier: supporting
provenance:
  extracted: 0.6
  inferred: 0.3
  ambiguous: 0.1
created: 2026-07-16
updated: 2026-07-16
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

## 相关页面

- [[agent-observability-fundamentals]] — Agent 可观测性基础概念
- [[agent-failure-taxonomy]] — Agent 失败分类
- [[agent-cost-breakdown]] — 成本观测
- [[opentelemetry-genai-agent-setup]] — OTel SDK 实际配置
