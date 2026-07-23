---
title: Observability 3.0
category: concepts
tags: [observability, llm, agent, evolution, paradigm]
sources:
  - "OpenObserve: LLM 可观测 vs 传统可观测：到底有什么不同？ (2026-05-18)"
summary: 可观测性的第三代演进，从“还活着吗”到“为什么答错了、怎么改、改完会不会更好”，将 Trace/Metric/Log/Prompt/Score/Dataset/Experiment 纳入统一底座。
provenance:
  extracted: 0.72
  inferred: 0.23
  ambiguous: 0.05
base_confidence: 0.44
lifecycle: draft
lifecycle_changed: 2026-07-22
tier: supporting
created: 2026-07-22T00:00:00+08:00
updated: "2026-07-22"
relationships:
  - target: "[[concepts/ai-agent-observability]]"
    type: extends
  - target: "[[concepts/llm-as-judge-evaluation]]"
    type: uses
  - target: "[[entities/langfuse-llm-observability]]"
    type: related_to
  - target: "[[entities/openobserve]]"
    type: related_to
  - target: "[[references/7-llm-observability-tools]]"
    type: related_to
  - target: "[[skills/agent-observability-landing-guide]]"
    type: related_to
  - target: "[[skills/openclaw-observability-setup-tencent-cloud]]"
    type: related_to
  - target: "[[references/openobserve-otel-landing]]"
    type: related_to
  - target: "[[references/2026-05-18-openobserve-llm-vs-traditional-observability]]"
    type: related_to
---

# Observability 3.0

**Observability 3.0** 是面向 AI 原生 / 概率系统的可观测性范式演进，核心问题是"为什么这次答错了、怎么改、改完会不会更好"，而不仅仅是"系统还活着吗"或"哪里慢了"。

## 三代演进对比

| 维度 | Observability 1.0 | Observability 2.0 | Observability 3.0 |
|---|---|---|---|
| 时代 | APM 时代 | 云原生 / 分布式 | AI 原生 / 概率系统 |
| 核心问题 | "还活着吗？" | "哪里慢了 / 错了？" | "为什么答错了？怎么改？" |
| 监控对象 | 单机进程 | 微服务、容器 | LLM 应用、Agent、RAG |
| 核心信号 | CPU / 错误率 | Metric + Log + Trace | 三件套 + Prompt + Score + Dataset |
| 失败定义 | 进程挂了 | 请求超时 | 答得不对、答得太贵、Agent 死循环 |
| 闭环动作 | 重启 / 扩容 | 修 bug | 改 Prompt / 换模型 / 跑 Experiment |
| 主要用户 | SRE | SRE + 开发 | + AI 工程师 + 产品 |

## 新增核心对象

Observability 3.0 在传统 Metric / Log / Trace 之上，引入 LLM 应用特有对象：

- **Prompt 管理**：Prompt 是 LLM 应用的"源代码"，需要版本化、热更新、关联 trace
- **Evaluation（评估）**：把"答得对不对"变成可执行分数，典型实现为 LLM-as-Judge
- **Score**：LLM 可观测里的第四种信号，与 Metric/Log/Trace 并列
- **Dataset**：把 bad case 沉淀为回归测试集
- **Experiment**：新 Prompt / 模型在 Dataset 上跑分对比，是 LLM 时代的统计学灰度发布
- **Playground**：工程师快速试错多个 Prompt 变体的对比台

## 统一底座的必要性

真实 LLM 故障从来都是全栈的：可能是模型问题、GPU 推理队列阻塞、向量库延迟、上游 API 超时、Prompt 改坏。只看 LLM 调用层的"AI 可观测平台"只能看见冰山一角。

Observability 3.0 的主张是将 Trace、Metric、Log、Prompt、Score、Dataset、Experiment 放在**同一个数据底座**，让 AI 工程师、SRE、产品经理在同一张图上回答"为什么这次答错了"。

## 与现有范式的关系

Observability 3.0 不是抛弃 1.0 和 2.0，而是在它们的能力底座上回答新问题：

- 1.0 让你知道"还活着吗"
- 2.0 让你知道"哪里慢了"
- 3.0 让你知道"为什么这次答错了，下次怎么改，改完会不会更好"

## Related

- [[references/2026-05-18-openobserve-llm-vs-traditional-observability]] — 来源文章
- [[concepts/ai-agent-observability]] — Agent 可观测性范式
- [[concepts/llm-as-judge-evaluation]] — LLM-as-Judge 评估
- [[entities/langfuse-llm-observability]] — 典型 Observability 3.0 工作台
- [[references/7-llm-observability-tools]] — 7 款 LLM 可观测与评测工具选型指南
- [[skills/agent-observability-landing-guide]] — Agent 可观测性从 0 到 1 落地路径
- [[skills/openclaw-observability-setup-tencent-cloud]] — OpenClaw 在腾讯云的可观测接入实操
- [[references/openobserve-otel-landing]] — 可观测性选型实录：从 OpenTelemetry 到 OpenObserve 的落地之路