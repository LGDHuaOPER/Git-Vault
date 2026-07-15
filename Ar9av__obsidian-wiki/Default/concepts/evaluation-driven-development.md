---
title: "评估驱动开发 (EDD)"
category: concepts
tags:
  - ai-agent
  - evaluation
  - methodology
sources:
  - "SelectDB: Agent 时代为什么需要新的可观测范式？ (2026-05-21)"
  - "一臻数据: Litefuse 正式发布！Doris 原生 Agent 可观测平台来了 (2026-05-21)"
  - "一臻数据: 正式开源！Doris 驱动的Agent观测平台 (2026-07-05)"
summary: "EDD (Evaluation Driven Development)：先观测 Agent 真实行为，用量化评估打分，用评估数据驱动 Prompt 调优和模型选型——让'Agent 变好了'从主观感受变成可验证的事实。"
base_confidence: 0.58
lifecycle: draft
lifecycle_changed: "2026-07-16"
tier: supporting
provenance:
  extracted: 0.50
  inferred: 0.40
  ambiguous: 0.10
created: "2026-07-16"
updated: "2026-07-16"
---

# 评估驱动开发 (EDD)

## TDD vs EDD

TDD（测试驱动开发）在传统软件中的逻辑：写测试 → 跑用例 → 代码通过 → 重构。这套方法论保证的是**代码逻辑正确**——接口返回正确状态码，边界条件处理正确。

EDD 的逻辑不同。Agent 的核心质量问题不是接口返回 `200`，而是：**回答准不准？工具调没调对？任务路径合不合理？上下文有没有腐化？** ^[extracted]

这些问题，传统单元测试覆盖不到。^[inferred]

## EDD 闭环

```
观测 → 评估 → 归因 → 优化 → 再评估
```

1. **观测**：完整记录 Agent 每一步的真实行为（LLM 调用、工具执行、推理路径）
2. **评估**：用评估器（规则/LLM-as-Judge/人工）对输出打分，识别 Bad Case
3. **归因**：定位问题根因——是 Prompt 歧义？模型幻觉？上下文过长？工具调用语义漂移？
4. **优化**：调整 Prompt、换模型、修改工具描述、压缩上下文
5. **再评估**：用同一批数据集重跑，分数上升 → 上线；分数不变 → 继续迭代

## EDD 所需的基础设施

^[inferred]

EDD 闭环不是纯流程概念，它需要一整套基础设施支撑：

| 能力 | 组件 | 说明 |
|------|------|------|
| Trace 采集 | OTel SDK / Langfuse SDK | 自动捕获每次调用的输入输出、Token、耗时 |
| 可视化分析 | Trace 面板 + 指标看板 | 下钻单次 Trace，聚合全局指标 |
| 数据集管理 | Golden Dataset | 从线上 Trace 中沉淀 Bad Case 和 Good Case |
| 评估器 | LLM-as-Judge / Code Eval / 人工标注 | 多种评估方式组合 |
| 实验对比 | Experiments | 不同 Prompt/模型版本在相同数据集上跑分对比 |

当前将 EDD 闭环产品化的平台包括 [[litefuse]]（基于 Apache Doris）和 [[langfuse]]（基于 ClickHouse + PostgreSQL）。^[extracted]

## 与传统可观测的关系

传统可观测（Prometheus/Grafana/ELK）负责回答"系统正常吗"，EDD 负责回答"Agent 做对了吗"。两者不替代，是互补的维度。^[inferred]

生产环境通常两套体系并行：OTel 做 SLO 监控和告警，Langfuse/Litefuse 做 Prompt 质量分析和 session 回放。^[extracted]

## 相关页面

- [[agent-observability-paradigm]] — 为什么需要新范式
- [[agent-trace-cost-quality-architecture]] — 具体的技术架构
- [[litefuse]] — EDD 方法论的产品化实现
- [[langfuse]] — EDD 工具链中的评估和实验功能
