---
title: Agent 时代为什么需要新的可观测范式？
category: references
tags:
  - ai-agent
  - observability
  - litefuse
  - paradigm
  - evaluation
sources:
  - "SelectDB: Agent 时代为什么需要新的可观测范式？ (2026-05-21)"
summary: 传统可观测性无法回答 Agent"任务是否做对"，面向 Agent 的可观测需要与效果评估深度融合，形成观测→评估→归因→优化→再评估的闭环。
base_confidence: 0.72
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
  - target: "[[entities/litefuse]]"
    type: related_to
  - target: "[[concepts/evaluation-driven-development]]"
    type: related_to
---

# Agent 时代为什么需要新的可观测范式？

## 传统可观测失效的真实场景

某客服 Agent 监控大盘全绿：P99 延迟 0.2 秒、错误率 0.001%、Token 消耗平稳。但系统将符合退款政策的订单回复为"无法退款"——所有传统指标正常，业务层却给出错误答案 ^[extracted]。

过去可观测回答"系统有没有正常运行"；Agent 时代更紧迫的问题是"在系统正常运行的同时，任务真的做对了吗？"^[extracted]

## 传统可观测为什么无法满足

1. **影响 Agent 可靠性的因素更多**：Agent 具有长链路和概率性特征，执行过程包含意图理解、上下文检索、Prompt 动态拼装、LLM 推理、工具调用、结果整合、多轮决策
2. **侧重系统性能与稳定性，而非业务效果**：传统指标能回答服务是否宕机、接口是否超时，但无法判断产出内容是否符合预期
3. **缺乏对 AI 生态与语义的原生支持**：没有为大模型 SDK、AI 框架、AI 网关、LLM 请求、Tool 调用、Retrieval、Token 等 AI 语义做深入集成 ^[extracted]

## 面向 Agent 可观测与效果评估的深度融合

新范式下的核心动作：
- **上线前**：通过测试集与评估器量化对比不同版本的回答效果
- **上线后**：持续采集真实用户交互轨迹与 Agent 内部执行路径
- **异常排查**：发现 Bad Case 后自动或半自动归因至 Prompt、上下文、模型或工具问题
- **持续迭代**：将高价值 Bad Case 转化为评测样本，在下一轮迭代中验证优化效果 ^[extracted]

核心闭环：**观测 → 评估 → 归因 → 优化 → 再评估**。

与传统工具的区别：
- 不止于可观测，更注重效果评估和优化
- 主要用户从工程团队变成算法业务团队
- 将可观测融入 AI 生态
- 系统设计面向 AI 语义 ^[extracted]

## Litefuse 的定位

Litefuse 定位为面向 Agent 时代的可观测与效果评估平台，完整记录 Agent 执行过程（模型调用、上下文构造、工具执行、任务路径），并通过自动化评估与语义级质量分析，帮助团队明确 Agent 做得好不好、有没有越做越好 ^[extracted]。

## 相关页面

- [[concepts/ai-agent-observability]] — Agent 可观测性整体概念
- [[entities/litefuse]] — Litefuse 平台详细介绍
- [[concepts/evaluation-driven-development]] — 评估驱动开发
