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
summary: "Agent 失败的分类体系：不只是 binary error，而是细分为 LLM 错误、工具错误、检索错误、格式错误、权限错误、上下文错误、循环错误、安全错误、人工介入等具体类别，每类有不同的根因和恢复策略。"
base_confidence: 0.6
lifecycle: draft
lifecycle_changed: "2026-07-16"
tier: supporting
provenance:
  extracted: 0.5
  inferred: 0.4
  ambiguous: 0.1
created: 2026-07-16
updated: 2026-07-22
---

# Agent Failure Taxonomy

## 为什么不能只写 Error

Agent 系统的失败不是二元的。简单标记 `status: ERROR` 丢失了关键的调试和恢复信息 ^[extracted]。不同类型的失败需要不同的处理策略——工具超时可能需要重试，而幻觉输出可能需要切换模型或调整 Prompt。

## 失败分类

### 1. LLM 错误（`llm_error`）
- **例子**：模型 API 失败、限流、超时
- **优先排查**：模型服务、重试策略

### 2. 工具错误（`tool_error`）
- **例子**：工具 500、超时、参数错误
- **优先排查**：工具稳定性、参数 schema
- **恢复策略**：自动重试（指数退避）、降级到备用工具、跳过该工具继续

### 3. 检索错误（`retrieval_error`）
- **例子**：没召回关键资料
- **优先排查**：RAG、索引、query rewrite

### 4. 格式错误（`format_error`）
- **例子**：输出不是合法 JSON、工具参数格式不符合 schema
- **优先排查**：输出约束、解析重试
- **恢复策略**：格式修复 Prompt 重试（常见消耗 1-2 次额外 LLM 调用）

### 5. 权限错误（`permission_error`）
- **例子**：工具权限不足或越权拦截
- **优先排查**：权限系统、工具策略

### 6. 上下文错误（`context_error`）
- **例子**：上下文缺失、污染、过载
- **优先排查**：Context Engineering

### 7. 循环错误（`loop_error`）
- **例子**：Agent 重复调用、无法停止
- **优先排查**：Planner、停止条件

### 8. 安全错误（`safety_error`）
- **例子**：触发安全规则
- **优先排查**：安全策略、用户输入

### 9. 人工介入（`human_intervention`）
- **例子**：需要人工确认
- **优先排查**：产品流程、风险动作

^[extracted]

## 失败记录结构

除了基本的 `status: ERROR`，失败记录还应包含"恢复动作"字段，以区分：^[extracted]

- 失败后成功降级
- 失败后重试成功
- 失败后直接终止
- 失败后模型胡乱补全（最危险）

示例：

```json
{
  "failure_type": "tool_error",
  "failure_stage": "query_order_status",
  "error_code": "timeout",
  "retry_count": 2,
  "recovery_action": "fallback_to_cached_order_snapshot",
  "final_status": "degraded_success"
}
```

^[extracted]

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

- [[concepts/ai-agent-observability]] — 失败观测是可观测性的核心场景
- [[concepts/agent-trace-span-taxonomy]] — 失败信息在 Trace/Span 中的记录方式
- [[concepts/agent-cost-breakdown]] — 重试失败直接导致成本膨胀
