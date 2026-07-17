---
title: Agent 在线评估体系
category: concepts
tags:
  - agent
  - evaluation
  - online-evaluation
  - badcase-mining
  - production-engineering
sources:
  - "AI Engineer编程微信公众号: Agent 可观测与质量评测体系：从数据采集到数据飞轮的完整实践 (2026-07-12)"
created: 2026-07-17
updated: 2026-07-17
summary: Agent 在线评估体系的设计——实时告警、Badcase 挖掘、在线加工引擎，以及离线与在线互补的差分评估策略。
base_confidence: 0.7
lifecycle: draft
lifecycle_changed: "2026-07-17"
tier: supporting
relationships:
  - target: "[[concepts/evaluation-driven-development]]"
    type: extends
  - target: "[[concepts/ai-agent-observability]]"
    type: related_to
  - target: "[[concepts/agent-data-flywheel]]"
    type: related_to
provenance:
  extracted: 0.5
  inferred: 0.4
  ambiguous: 0.1
---

# Agent 在线评估体系

## 静态 Benchmark 的四大局限性

离线评测（Benchmark）虽能提供确定性环境，但在生产环境中面临根本性局限：

| 局限性 | 具体表现 | 根本原因 |
|---|---|---|
| **依赖漂移** | 第三方 API 升级/限流 → 线上失败 | Mock 的是快照，线上 API 持续演进 |
| **长尾输入** | 任务模糊多意图 → Agent 运行走偏 | 评测集是"精心构造"，线上是开放域 |
| **会话状态累积** | Token 超限/记忆冲突 → 能力骤降 | 离线是短会话，线上是长会话累积效应 |
| **测试用例难以全面覆盖** | 边界/异常/组合场景 → 盲区频发 | 组合爆炸，评测集覆盖率 |

这些局限决定了在线评估不是可选的增强，而是必须的补充。^[extracted]

## 在线评估的双轨架构

在线评估体系由两条互补的轨道组成：

1. **Reactive（实时告警与监测）** — 发现问题，快速止损
2. **Proactive（Badcase 挖掘）** — 发现盲区，补全评测集

两者通过 Badcase 回流形成闭环，将生产环境的真实反馈补充回离线评测集。^[inferred]

## 实时告警策略

基于多维指标的动态阈值和趋势检测：

- **TTFT**（Time To First Token）— 首 Token 延迟突增
- **TPOT**（Time Per Output Token）— 每输出 Token 耗时异常
- **Token 消耗** — 单会话 Token 突增（可能意味着无限循环）
- **工具调用成功率** — Function Calling 失败率上升
- **用户反馈差评率** — 显式或隐式负反馈信号

## Badcase 挖掘流程

```
线上流量 → 异常检测 → 聚类分析 → 根因分类 → 脱敏回流 → 评测集更新 → 离线验证 → 发布新版本
```

核心步骤：
1. **异常检测** — 基于指标偏移、响应质量降级、用户负反馈触发
2. **聚类分析** — 将类似异常的 Trace 聚合为同类型问题
3. **根因分类** — 归因至 Prompt、上下文、模型或工具问题
4. **脱敏回流** — 将脱敏后的真实案例添加入离线评测集
5. **离线验证** — 新版在更新后的评测集上重新验证

## 在线加工引擎

在线加工引擎是一个**高性能流式数据处理 Pipeline**，核心设计包含：

### CPU + GPU 混合计算
- **CPU** — Trace 聚合、规则匹配、元数据处理
- **GPU** — LLM 评估器推理、意图分类、语义嵌入

### 场景化评估
基于意图的自动分类 + 动态标签体系，不同场景路由到不同的评估器集合。不同类型任务（数值/时序类、工具链/结构类、语义/回答质量类）由不同的评估策略处理。^[extracted]

### 语义去重
基于 Embedding 的聚类，将大量 Trace 高效去重为少量候选样本，使人工审核在工程上可行。^[extracted]

## 差分评估策略

离线与在线互补而非替代：

- **离线评测**：确定性、可控、可复现，解决"已知风险"
- **在线评估**：实时、动态、自适应，应对"未知风险"

两者通过 Badcase 回流形成闭环，每种任务类型（数值/时序类、工具链/结构类、语义/回答质量类）需要差异化的评估方法。^[extracted]

## 相关页面

- [[concepts/evaluation-driven-development]] — 离线评测方法论基础
- [[concepts/agent-data-flywheel]] — 数据飞轮完整闭环
- [[concepts/ai-agent-observability]] — 可观测体系总览
- [[concepts/agent-trace-cost-quality-architecture]] — Trace-Cost-Quality 三合一架构
- [[concepts/agent-harness]] — Agent 执行环境的工程框架层
- [[concepts/llm-as-judge-evaluation]] — LLM-as-Judge 评估方法论
