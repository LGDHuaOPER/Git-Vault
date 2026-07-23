---
title: Agent Observability Metrics
category: concepts
tags:
  - ai-agent
  - observability
  - metrics
  - slo
  - reliability
aliases:
  - Agent 可观测性指标
sources:
  - "祥聊AI: AI Agent 可观测性：看不见的链路，才是最贵的技术债 (2026-04-12)"
summary: Agent 可观测性指标应以 SLO 为驱动，围绕结果、过程、成本、质量四组核心指标构建，避免"指标越多越好"的陷阱。
provenance:
  extracted: 0.72
  inferred: 0.23
  ambiguous: 0.05
base_confidence: 0.55
lifecycle: draft
lifecycle_changed: 2026-07-22
tier: supporting
created: 2026-07-22T00:00:00+08:00
updated: "2026-07-22"
relationships:
  - target: "[[concepts/ai-agent-observability]]"
    type: part_of
  - target: "[[concepts/agent-cost-breakdown]]"
    type: related_to
  - target: "[[entities/langfuse-llm-observability]]"
    type: related_to
---

# [[concepts/ai-agent-observability|Agent Observability]] Metrics

**Agent 可观测性指标**不是越多越好，关键是能驱动决策。核心前提是先定义 SLO（Service Level Objective）——"什么数值算正常，什么数值该告警"。没有 SLO，监控只是"看数字"。

## SLO 驱动原则

以 SLO 违约为告警标准，而不是以"指标变化"为告警标准。例如成功率下降 0.5% 但仍在 SLO 范围内，不需要半夜叫人。

Agent 场景的 SLO 要回答：
- 任务成功率应该 ≥ 多少？
- 端到端延迟 P99 应该 ≤ 多少？
- 单次工具调用超时率应该 ≤ 多少？

## 四组核心指标

### 第一组：结果指标 — Agent 是否在创造价值

| 指标 | 驱动的决策 |
|------|-----------|
| 任务成功率 | Agent 是否可以继续投入 |
| 人工接管率 | 自动化成熟度是否在提升 |
| 业务结果达成率 | 是否真正创造了业务价值 |

### 第二组：过程指标 — 问题集中发生在哪

| 指标 | 驱动的决策 |
|------|-----------|
| 步骤失败分布 | 哪个步骤需要重点优化 |
| 重试/循环次数 | 是否存在无效的资源消耗 |
| MCP 调用错误率（按系统拆分） | 哪个外部依赖最不稳定 |

### 第三组：成本指标 — 钱花在哪里

| 指标 | 驱动的决策 |
|------|-----------|
| 单任务平均 token 消耗 | 上下文是否膨胀 |
| 失败任务的 token 浪费 | 是否需要 fail-fast 策略 |
| 模型调用成本（按租户/Agent 拆分） | 是否需要分级模型路由 |

### 第四组：质量指标 — RAG 和模型表现如何

| 指标 | 驱动的决策 |
|------|-----------|
| RAG 检索命中率 | 知识库质量是否达标 |
| LLM 拒答率 / 截断率 | 模型选型或 prompt 是否需要调整 |
| 延迟 P50 / P95 / P99 | 是否有体验瓶颈需要优化 |

## 告警原则

1. **以 SLO 违约为主**：成功率跌破阈值、P99 恶化超过上限、成本突破预算。
2. **以依赖隔离为辅**：单一 MCP 系统异常单独告警，不要因为一个工具挂了就把整个 Agent 标红。

## 快速定位表

| 现象 | 优先怀疑 |
|------|---------|
| 成本突然升高，成功率没变 | 循环/重试/上下文膨胀 |
| 某类任务总失败，普通问答正常 | 工具链路或 RAG 质量 |
| 同一步频繁超时 | 工具或外部依赖 |
| 输出经常偏题 | RAG 检索质量或知识库过期 |
| 不同时段表现差别大 | 外部依赖或上游服务波动 |

## 分阶段建设

- **阶段一（1-2 周）结果可见性**：采集 task 级事件，看清成功率、失败率、人工接管率、基础成本。
- **阶段二（2-4 周）过程可见性**：补齐 step/tool/llm 事件，接入 [[entities/langfuse-llm-observability|Langfuse]] 和 Phoenix。
- **阶段三（持续）治理自动化**：定义 SLO、自动降级、模型路由、自动转人工、离线评估回归。
