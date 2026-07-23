---
title: Agent Observability Landing Guide
category: skills
tags:
  - ai-agent
  - observability
  - how-to
  - opentelemetry
  - trace
sources:
  - "唧唧复急急: AI 智能体应用时代，可观测性怎么做？ (2026-03-27)"
  - "小加号编程笔记: AI Agent 可观测性：如何记录推理、工具调用、失败与成本 (2026-07-13)"
summary: 从 0 到 1 搭建 AI Agent 可观测性的实操路径：定义最小任务单元、埋齐关键字段与事件、叠加轻量评估、沉淀失败数据集、用实验驱动迭代，再逐步扩展成本、失败分类、隐私脱敏与告警面板。
provenance:
  extracted: 0.75
  inferred: 0.20
  ambiguous: 0.05
base_confidence: 0.58
lifecycle: draft
lifecycle_changed: 2026-07-22
tier: supporting
created: 2026-07-22T00:00:00+08:00
updated: 2026-07-22T00:00:00+08:00
relationships:
  - target: "[[concepts/ai-agent-observability]]"
    type: implements
  - target: "[[concepts/agent-trace-span-taxonomy]]"
    type: uses
  - target: "[[concepts/agent-failure-taxonomy]]"
    type: uses
  - target: "[[concepts/agent-cost-breakdown]]"
    type: uses
  - target: "[[concepts/observability-3-0]]"
    type: related_to
  - target: "[[references/7-llm-observability-tools]]"
    type: related_to
  - target: "[[skills/openclaw-observability-setup-tencent-cloud]]"
    type: related_to
---

# Agent Observability Landing Guide

AI 可观测性平台建设容易"做大做重"，迟迟不落地。^[extracted] 更务实的做法是先跑通一条最关键的线上任务，把排障和迭代拉回工程节奏。^[extracted]

## 第一阶段：定义一个最小任务单元

不要一上来追求"全量可观测"，先选一个**最核心、投诉最多、价值最清晰**的任务。^[extracted] 例如：

- "问制度库并回答"
- "根据工单信息生成处理建议"
- "根据客户对话判断是否需要转人工"

先把任务单元定义清楚：什么叫成功，什么叫失败，什么叫高成本但勉强成功，什么场景必须转人工。^[extracted] 没有任务单元，后面的 trace 和 evaluation 都会失焦。^[extracted]

**第一阶段只做一件事**：给这类任务统一一个 `trace_id` 或 `session_id`，把用户输入、检索、模型调用、工具调用、最终结果挂到同一条链路下。^[extracted]

## 第二阶段：埋齐关键字段、事件、指标

第一版不要贪多，先把最影响排障效率的字段埋齐。^[extracted]

### 必须埋的字段

| 类别 | 字段示例 |
|------|---------|
| 请求标识 | `trace_id`、`session_id`、`user_id`、`task_type`、`app_version` |
| 输入信息 | 用户原始问题、输入渠道、语言、是否命中敏感场景 |
| 模型调用 | `model_name`、`temperature`、`max_tokens`、prompt 版本、输入/输出 token、模型延迟、模型费用 |
| 检索信息 | retrieval query、召回文档 ID、文档版本、知识库来源、top_k、重排分数、最终注入片段 |
| 工具调用 | `tool_name`、调用原因、输入参数、输出摘要、耗时、是否成功、错误码、重试次数 |
| Agent 过程 | loop 次数、每步 action、停止原因、是否回退、是否触发人工接管 |
| 结果信息 | 最终回答、是否完成任务、失败原因分类、人工反馈、用户反馈 |
| 评估信息 | 准确性分、完整性分、是否违规、是否命中业务规则、评估器版本 |

^[extracted]

### 必须埋的事件

- `session_started`
- `retrieval_started` / `retrieval_completed`
- `llm_call_started` / `llm_call_completed`
- `tool_call_started` / `tool_call_completed`
- `agent_step_completed`
- `human_handoff_triggered`
- `session_completed`
- `evaluation_completed`

^[extracted]

### 必须盯的指标

- 任务成功率
- 人工接管率
- 平均 loop 次数与 P95 loop 次数
- 工具调用成功率、误调用率
- 检索命中率或"答案引用有效知识"比例
- 平均输入 / 输出 token
- 单任务平均成本与 P95 成本
- 平均延迟与 P95 延迟
- 评估通过率

^[extracted]

## 第三阶段：给线上结果加一层轻量 Evaluation

第一版不需要复杂评分体系，可以三层并行，能上什么先上什么：^[extracted]

1. **规则评估**：回答是否引用知识库版本号、是否调用不该调用的工具、是否在应当拒答的场景给出确定性结论。^[extracted]
2. **人工反馈**：给运营/客服/业务专家一个最简标注入口，先能标"答对 / 答错 / 不完整 / 成本过高 / 应转人工未转"。^[extracted]
3. **模型评审**：让另一个模型辅助判断答案是否命中问题、是否遗漏关键信息、是否存在明显幻觉，作为筛查器挑出需要人工复核的样本。^[extracted]

关键不是评分有多准，而是把"线上结果是否可接受"落成结构化数据，并且能和 trace 一一对应。^[extracted]

## 第四阶段：把坏样本沉淀成 Dataset

以下样本应自动或半自动进数据集：^[extracted]

- 用户明确投诉的样本
- evaluation 不通过的样本
- 成本异常高的样本
- loop 异常长的样本
- 工具误调用样本
- 检索命中但答案错误的样本

数据集里不要只留问题和答案，至少还要带上对应 trace 链接、知识片段、工具调用记录、评估结果、故障标签。^[extracted] 第一版 50 到 100 条高质量失败样本，通常就够支持第一轮回归和改版验证。^[extracted]

## 第五阶段：把改动放进实验

改 prompt、改工具描述、改知识召回、改停止条件时，不要直接发版。^[extracted] 先在失败数据集上做对照实验，盯住四个维度：^[extracted]

- 质量有没有提升
- 成本有没有失控
- 延迟有没有恶化
- 人工接管率有没有下降

只要实验结果能回写到同一批样本上，团队就能避免"局部修好了，但整体反而变差"的错觉。^[extracted]

## 第六阶段：逐步扩展完整能力

当最小闭环跑通后，再按顺序补齐：^[extracted]

| 阶段 | 目标 | 做法 |
|------|------|------|
| 1. Trace 打通 | 能复盘一次 Agent Run | 记录 root trace、LLM span、tool span |
| 2. 成本可见 | 知道钱花在哪里 | 记录 token、模型、工具、重试成本 |
| 3. 失败分类 | 知道主要失败来自哪里 | 统一 `failure_type` 和 `recovery_action` |
| 4. 隐私脱敏 | 避免观测数据变成风险 | 对输入、参数、结果做脱敏和保留周期 |
| 5. 质量评估 | 不只看接口成功 | 接入规则校验、LLM-as-Judge、人工抽检 |
| 6. 告警面板 | 让问题主动浮出来 | 按任务类型看延迟、失败、成本、质量 |

^[extracted]

## 每周复盘三问

团队应每周固定做一次样本复盘，不是看 dashboard 漂不漂亮，而是一起回答：^[extracted]

1. 这周最常见的失败类型是什么？
2. 哪些问题是检索、工具、提示词还是停止条件导致的？
3. 下一个版本优先修哪两类问题？

这五件事做完，团队就能从"AI 功能上线了但靠感觉维护"，进入"AI 功能按工程方式迭代"。^[extracted]

## 相关页面

- [[concepts/ai-agent-observability]] — Agent 可观测性整体概念
- [[concepts/observability-3-0]] — 可观测性范式演进到 Observability 3.0
- [[references/7-llm-observability-tools]] — 7 款 LLM 可观测与评测工具选型指南
- [[skills/openclaw-observability-setup-tencent-cloud]] — OpenClaw 在腾讯云的可观测接入实操
- [[concepts/agent-trace-span-taxonomy]] — Trace/Span 结构设计
- [[concepts/agent-failure-taxonomy]] — 失败分类体系
- [[concepts/agent-cost-breakdown]] — 成本构成与观测
- [[concepts/evaluation-driven-development]] — 评估驱动开发方法论
