---
title: Agent Causal Attribution
aliases:
  - Agent 因果归因
  - Trace 因果归因
category: concepts
tags:
  - ai-agent
  - observability
  - causal-attribution
  - trace-analysis
  - debugging
sources:
  - "Vibe编码: 如何基于Trace归因Agent效果问题 (2026-07-15)"
summary: Agent 因果归因超越"失败定位"，回答"只改这个模块，结果分布会不会改变"。涵盖 AgentRx 约束诊断、TraceElephant 步骤级归因、Causal Agent Replay 反事实干预、模块边界声明、基线重建与负对照实验。
base_confidence: 0.55
lifecycle: draft
lifecycle_changed: "2026-07-22"
tier: supporting
provenance:
  extracted: 0.60
  inferred: 0.30
  ambiguous: 0.10
created: "2026-07-22"
updated: "2026-07-22"
relationships:
  - target: "[[concepts/agent-failure-taxonomy]]"
    type: extends
  - target: "[[concepts/agent-trace-and-timeline]]"
    type: extends
  - target: "[[concepts/ai-agent-observability]]"
    type: related_to
  - target: "[[concepts/agent-harness]]"
    type: related_to
  - target: "[[entities/langfuse-llm-observability]]"
    type: related_to
  - target: "[[concepts/genai-observability-semconv]]"
    type: related_to
---

# Agent Causal Attribution

Agent 因果归因（Causal Attribution）回答的问题不是"哪一步出错了"，而是"**只改这个模块，结果分布会不会改变**"。这是从"失败定位"到"因果推断"的跨越——Trace 记录只能证明事情发生过，不能直接证明替换某个 Prompt、Context、Tool Adapter 或权限模块后结果会稳定恢复。

## 从失败定位到因果归因的鸿沟

Anthropic 在 Claude Code 质量复盘中披露了一个典型案例：用户感知到的一段广泛质量下降，实际叠加了**三项独立变更**——默认 reasoning effort 从 high 调到 medium、旧会话触发 context pruning bug 导致持续清理 thinking、system prompt 新增限制工具调用间文本长度的指令。聚合曲线里的"模型变差"，可能来自模型配置、上下文处理和 Prompt 三条不同链路。^[extracted]

这个案例给出的警告：如果 Trace 没有记录公开 build、实验分桶、模型与 effort、Prompt hash、history pruning 事件和旧会话状态，事后看到再多 LLM span，也难以还原真实因果链。

## 四层归因能力模型

从观测到因果，归因能力分为四个递进的层次 ^[extracted]：

| 层次 | 回答的问题 | 代表技术 |
|------|-----------|---------|
| **观测层** | 发生了什么？ | [[concepts/genai-observability-semconv|OpenTelemetry GenAI SemConv]], OpenInference |
| **诊断层** | 哪里开始失控？ | AgentRx 约束诊断, Phoenix/[[entities/langfuse-llm-observability|Langfuse]] Playground |
| **回放层** | 能否从同一状态重新执行？ | LangGraph Time Travel, Google Agent Executor |
| **因果层** | 只改这个模块，结果分布会不会改变？ | Causal Agent Replay (CAR) |

## AgentRx：约束驱动的结构化诊断

AgentRx 将异构日志转为 Trajectory IR，再根据工具 schema、领域策略和已观察前缀生成约束。guard 决定约束在哪一步生效，predicate 检查是否违反，LLM judge 再从 violation log 中找 critical failure step。^[extracted]

在 115 条人工标注失败轨迹上，AgentRx 报告失败定位和分类相对 prompting baseline 分别提高 **23.6 和 22.9 个百分点**。但逐域绝对结果揭示现状：τ-bench 的 step accuracy 是 54.0%，Flash 是 83.3%，完整 Magentic-One 只有 31.8%。在 Magentic-One 上，68% 的失败轨迹含两个以上 failure event，第一条错误和第一个未恢复错误经常不是同一步。^[extracted]

AgentRx 的价值在于把自由文本猜测变成"约束、证据、步骤"的可审计诊断，但它没有恢复业务 checkpoint，也没有对候选步骤执行反事实干预。critical failure 仍由 judge 基于 Trace 判断——能给出高质量候选，不能单独证明某个模块造成了结果变化。^[extracted]

## TraceElephant：步骤级归因的现状

TraceElephant 收集了 380 次执行中的 220 条失败 Trace（来自 Captain-Agent、Magentic-One 和 SWE-Agent），每一步包含输入、输出、工具日志、Agent 配置和架构元数据。^[extracted]

论文报告：完整 Trace 相比只看输出，Agent 级归因有约 **22%** 的相对提升，步骤级有约 **76%** 的相对提升。但完整设置下，步骤级准确率仍在 **30%** 左右；动态单步回放也只把平均值从 30.3% 提到 33.3%。^[extracted]

这个结果的含义：完整 Trace 解决了"证据不够"的一部分，却没有消除恢复语义。planner 在 t2 给出坏计划，verifier 在 t4 本应纠正却放行，tool 在 t6 执行错误动作。t2 可以是首个差异，t4 可以是第一个不可恢复点，t6 只是机械执行点。三者如果混在一个"根因步骤"指标里，产品输出会很有把握，工程行动却可能对错模块。^[extracted]

## Causal Agent Replay (CAR)：反事实干预

Causal Agent Replay 把轨迹写成**结构因果模型**（Structural Causal Model），允许重采样某一步、替换 action、observation、context 或 policy，再按相同随机策略执行后缀，比较失败概率。论文定义了 **point of commitment**——最晚仍能通过干预显著提高成功概率的步骤。^[extracted]

CAR 在合成环境中恢复了植入的关键步骤，也用 Monte Carlo Shapley 找到双步骤交互。但论文验证使用合成 SCM 和 mock tools，真实副作用系统没有覆盖。在 Who&When 的 121 个可运行样本里，带置信区间门禁的方法只对 22 个样本输出，82% 选择弃权；把弃权计错时，step exact 只有 4.1%。^[extracted]

这个负面结果很有价值：因果归因产品真正困难的地方，是**判断什么时候证据不足**，并清楚说明还缺哪块状态、哪种干预或多少统计功效。给每条 Trace 填一个"根因"反倒容易。^[inferred]

## 生产实现指南

### 模块边界声明

归因的前提是声明模块边界。Intent、Planner、Prompt/Model、Context/Retrieval/Memory、Tool Schema/Adapter、Tool Executor、Permission/Guardrail、Outcome Evaluator 都要有稳定的 module id、version、owner 和输入输出版本。线性 Trace 还要转成带 control、data、state-read、state-write、handoff、retry 关系的**状态图**，只从 outcome 的祖先节点中产生候选。^[extracted]

### 基线重建

从候选前的 checkpoint 恢复，在模型、工具和外部副作用边界返回原始记录值，检查原故障能否稳定复现。基线重建不通过，后续实验应停止——继续扫模块只会把环境漂移包装成归因结果。^[extracted]

### 最小干预设计

基线通过后，设计最小干预。例如 Tool Adapter 把 `qty: "two"` 序列化错了，就只把它替换为 `qty: 2`，冻结 plan、context、model output 和 backend snapshot。baseline 与 treatment 使用相同 checkpoint 和一组配对 seed，多次执行，再看成功率、质量、成本、延迟和安全的差值及置信区间。^[extracted]

### 负对照与弃权机制

加入 **negative control**：修改一个与 outcome 没有依赖关系的字段，结果不应显著变化。单模块无效、但依赖图显示两个模块存在紧邻交互时，才测试少量联合干预。对所有模块组合穷举 Shapley，成本高，也很容易得到缺乏决策价值的漂亮数字。^[extracted]

归因报告应包含：causal set、首个因果有效分歧、最晚可救援点、效应大小与区间、replay fidelity、反证、剩余失败和弃权原因。只写"根因是 Tool"无法支持回滚、修复优先级或 owner 责任判断。^[extracted]

## 未解难题

- **完整状态与隐私冲突** — 动态 system prompt、压缩前 context、cache、账号权限可能决定结果，但生产 Trace 常因 PII、密钥和成本被脱敏或采样。可行做法是把敏感 payload 放入受控 artifact store，span 只保留加密引用、hash 和完整性等级。^[extracted]
- **托管模型 bit-exact 复现** — seed 不能冻结 provider serving stack，网页、搜索、数据库 DOM 持续变化。因果结论应限定在明确的 snapshot 和干预语义里，报告概率效应。^[extracted]
- **副作用隔离** — 发邮件、支付、删除、部署和权限变更无法在真实环境中随意重放。需要事务 sandbox、fake backend、幂等键、side-effect ledger 和 simulator validity test。^[extracted]

## 相关页面

- [[concepts/agent-failure-taxonomy]] — 失败分类体系（因果归因的前置）
- [[concepts/agent-trace-and-timeline]] — Trace 数据结构（归因的输入）
- [[concepts/ai-agent-observability]] — 可观测体系总览
- [[concepts/agent-harness]] — Harness 工程框架（归因的工程基础）
- [[concepts/evaluation-driven-development]] — 评估驱动开发（归因结果驱动优化）
