---
title: "LLM 可观测 vs 传统可观测：到底有什么不同？"
category: references
tags: [observability, llm, openobserve, observability-3-0, comparison]
sources:
  - "OpenObserve: LLM 可观测 vs 传统可观测：到底有什么不同？ (2026-05-18)"
summary: OpenObserve 科普 LLM 可观测与传统可观测的根本差异，提出 Observability 3.0 应将 Trace/Metric/Log/Prompt/Score/Dataset/Experiment 放在同一数据底座。
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
  - target: "[[concepts/observability-3-0]]"
    type: describes
  - target: "[[entities/openobserve]]"
    type: related_to
---

# LLM 可观测 vs 传统可观测：到底有什么不同？

[[entities/openobserve|OpenObserve]] 的一篇科普文章，用一句话概括 LLM 可观测与传统可观测的根本差异：传统系统问"还活着吗"，LLM 系统问"回答得好吗"。

## 一句话讲清区别

| 维度 | 传统系统 | LLM 系统 |
|---|---|---|
| 对错 | 确定的 | 概率的 |
| 监控要回答 | "还活着吗？" | "回答得好吗？" |

传统软件 1+1 永远等于 2，登录成功就是 200；LLM 同样 Prompt 今天答得漂亮，明天可能跑偏。

## 传统可观测平台为何看不懂 LLM？

四个"看不见"：

1. **看不见幻觉**：HTTP 200 不代表答案对
2. **看不见质量退化**：Prompt 改一行，延迟没变但 15% 回答开始忽略关键事实
3. **看不见成本**：Token 成本散落在几十个子调用上，CPU 时间反映不了
4. **看不见路径**：Agent 请求是树状结构（Plan → 检索 → 工具 → 子 Agent → 重试），不是线性 API 调用

## LLM 可观测平台的新对象

Langfuse、Braintrust、Phoenix 等平台出现的新名词，本质是对应上述四个"看不见"：

- **Prompt 管理**：Prompt 是 LLM 应用的"源代码"，需要版本化、热更新、关联 trace
- **Evaluation**：把"答得对不对"变成可执行分数，即 LLM-as-Judge
- **Dataset**：把 bad case 沉淀为回归测试集
- **Experiment**：新 Prompt 与旧 Prompt 在同一 Dataset 上跑分对比，是 LLM 时代的"灰度发布"
- **Score**：LLM 可观测里第四种信号，与 Metric/Log/Trace 并列
- **Playground**：工程师快速试错对比多个变体

## 可观测的三代演进

| 维度 | Observability 1.0 | Observability 2.0 | Observability 3.0 |
|---|---|---|---|
| 时代 | APM 时代 | 云原生 / 分布式 | AI 原生 / 概率系统 |
| 回答的问题 | "还活着吗？" | "哪里慢了 / 错了？" | "为什么答错了？怎么改？" |
| 监控对象 | 单机进程 | 微服务、容器 | LLM 应用、Agent、RAG |
| 核心信号 | CPU / 错误率 | Metric + Log + Trace | 三件套 + Prompt + Score + Dataset |
| 失败定义 | 进程挂了 | 请求超时 | 答得不对、答得太贵、死循环 |
| 闭环动作 | 重启 / 扩容 | 修 bug | 改 Prompt / 换模型 / 跑 Experiment |

## OpenObserve 的主张

把 Trace、Metric、Log、Prompt、Score、Dataset、Experiment 放在**同一个数据底座**，让 AI 工程师、SRE、产品经理在同一张图上回答"为什么这次答错了"。不是复制 Langfuse，也不是在 Datadog 上贴 LLM 模块，而是让 3.0 装进同一底座、1.0 和 2.0 能力天然延续。

## Related

- [[concepts/observability-3-0]] — Observability 3.0 详解
- [[concepts/llm-as-judge-evaluation]] — LLM-as-Judge 评估方法论
- [[entities/langfuse-llm-observability]] — Langfuse 开源 LLM 可观测平台
- [[entities/arize-phoenix]] — Phoenix AI 可观测平台