---
title: "Agent Failure Taxonomy"
category: concepts
tags:
  - ai-agent
  - observability
  - error-handling
  - debugging
sources:
  - "小加号编程笔记: AI Agent 可观测性：如何记录推理、工具调用、失败与成本 (2026-07-13)"
summary: "Agent 失败的分类体系：不只是 binary error，而是细分为工具失败、格式错误、超时、重试耗尽、幻觉输出等具体类别，每类有不同的根因和恢复策略。"
base_confidence: 0.6
lifecycle: draft
lifecycle_changed: "2026-07-16"
tier: supporting
provenance:
  extracted: 0.5
  inferred: 0.4
  ambiguous: 0.1
created: 2026-07-16
updated: 2026-07-16
---

# Agent Failure Taxonomy

## 为什么不能只写 Error

Agent 系统的失败不是二元的。简单标记 `status: ERROR` 丢失了关键的调试和恢复信息 ^[extracted]。不同类型的失败需要不同的处理策略——工具超时可能需要重试，而幻觉输出可能需要切换模型或调整 Prompt。

## 失败分类

### 1. 工具失败（Tool Failure）
- **类型**：工具不可用、工具超时、工具返回格式错误、工具返回空结果
- **根因**：外部服务故障、网络问题、API 限流
- **恢复策略**：自动重试（指数退避）、降级到备用工具、跳过该工具继续

### 2. 格式错误（Format Error）
- **类型**：模型返回的 JSON 解析失败、工具参数格式不符合 schema、输出不满足约束
- **根因**：模型指令不清晰、温度过高、模型本身的结构化输出能力不足
- **恢复策略**：格式修复 Prompt 重试（常见消耗 1-2 次额外 LLM 调用）

### 3. 超时（Timeout）
- **类型**：模型推理超时、工具执行超时、整体 Agent Run 超时
- **根因**：模型响应慢、工具服务延迟高、任务过于复杂导致推理循环过长
- **恢复策略**：设置合理的超时阈值，分解复杂任务

### 4. 重试耗尽（Retry Exhausted）
- **类型**：多次工具重试或格式修复后仍未成功，达到最大重试次数
- **根因**：根本性问题（如工具确实不可用），重试无法解决
- **恢复策略**：优雅降级返回部分结果，标记需要人工介入

### 5. 幻觉输出（Hallucination）
- **类型**：模型编造了不存在的工具名、虚构的 API 参数、超出上下文的"知识"
- **根因**：RAG 召回不足、Prompt 约束不明确、模型本身的幻觉倾向
- **恢复策略**：增加事实校验步骤（Grounding check），交叉验证 ^[inferred]

## 失败观测的 Span 记录建议

除了基本的 `status: ERROR`，建议在 Span 上附加：
```
failure.type: "tool_timeout" | "format_error" | "hallucination" | "retry_exhausted"
failure.tool: "search_api"
failure.retry_count: 3
failure.recovery: "fallback_to_cache"
```

这样可以在后端的可观测平台上按失败类型聚合分析，发现系统性问题。

## 相关页面

- [[agent-observability-fundamentals]] — 失败观测是可观测性的核心场景
- [[agent-trace-span-taxonomy]] — 失败信息在 Trace/Span 中的记录方式
- [[agent-cost-breakdown]] — 重试失败直接导致成本膨胀
