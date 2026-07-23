---
title: AI 客服评测：从硬规则到 LLM Judge
category: references
tags:
  - ai-agent
  - evaluation
  - llm-as-judge
  - customer-service
  - quality-assurance
sources:
  - "自由的灵魂在路上: [Alan の测试] 从硬规则到 LLM Judge：如何搭建一套可落地的 AI 客服评测系统 (2026-07-22)"
summary: 一套面向 AI 客服的四层评测工程实践：L1 确定性业务规则、L2 行为意图识别、L3 七维 LLM Judge、L4 多轮流程回归，配套数据集设计、专业指标体系和可下钻报告。
base_confidence: 0.75
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
  - target: "[[concepts/agent-evaluation-framework]]"
    type: related_to
  - target: "[[concepts/llm-as-judge-evaluation]]"
    type: related_to
  - target: "[[concepts/evaluation-driven-development]]"
    type: related_to
---

# AI 客服评测：从硬规则到 LLM Judge

## 核心观点

AI 客服评测的核心问题不是"回答像不像人"，而是"是否完成了正确的业务动作"。这要求把确定性约束、分类能力、生成质量和多轮流程分层评测，不能只看整体通过率或单一 LLM 总分 ^[extracted]。

## 四层 Evaluator 体系

### L1：确定性业务规则

适合用普通代码判断的要求：句数、禁用词、明确格式、主动推荐微信、承诺实时价格/库存/车况、提供手机号后再次索要、结束后继续营销、负面回复动作顺序等 ^[extracted]。

规则设计应采用"触发条件 + 语义对象 + 动作"组合，避免单个关键词误报。例如识别"具体事项 + 店家确认"，而非维护狭窄话术白名单 ^[extracted]。

### L2：行为和意图识别

统计 Accuracy、Precision、Recall、F1、Macro/Micro F1 和混淆矩阵。关键类别（手机号、结束意图、负面反馈）应优先看 Recall ^[extracted]。

本项目定义十类行为标签：`VEHICLE_INFO`、`STORE_INFO`、`APPOINTMENT`、`PRICE_NEGOTIATION`、`WECHAT_REQUEST`、`NEGATIVE_FEEDBACK`、`OTHER_VEHICLE`、`OFF_TOPIC`、`PHONE_PROVIDED`、`END_CONVERSATION` ^[extracted]。

### L3：生成回复质量（七维 LLM Judge）

在 L1 之后执行，Judge 返回结构化分数、理由、事实风险和适用性 ^[extracted]：

| 维度 | 判断内容 |
|------|----------|
| 回答相关性 | 是否回应当前问题 |
| 事实准确性 | 是否忠实于 knowledge |
| 必要信息覆盖 | 是否使用题目要求的知识点 |
| 任务完成度 | 是否完成该类业务动作 |
| 留资价值 | 是否说明联系后能得到什么 |
| 清晰与语气 | 是否简洁、口语、自然 |
| 上下文一致性 | 是否承接历史且不自相矛盾 |

判定口径：回答相关性/事实准确性/任务完成度任一低于 3 分为 failed；任一适用维度低于 4 分为 review；全维度不低于 4 且无事实风险为 passed ^[extracted]。

### L4：多轮流程回归

覆盖咨询 → 引导 → 提供手机号 → intent.code=9、微信转手机号、负面反馈处理、用户拒绝后停止追问、用户结束立即结束、已留手机号后继续咨询、 knowledge 从有值变空、车辆切换等场景 ^[extracted]。

## 数据集设计要点

每条用例必须具备：稳定唯一 ID、标题描述、业务行为标签、input/chatHistory/knowledge、期望结果类型、适用断言、优先级、测试族、来源版本、审核状态 ^[extracted]。

来源优先级：已确认的产品原型和业务规则 > 脱敏真实会话 bad case > 边界表达 > 基于真实模式构造的合成变体 > LLM 辅助扩写候选样本。合成样本必须明确标记，LLM 生成样本不能自动进入正式基线 ^[extracted]。

## 实施建议

推荐建设顺序：冻结产品规则 → 建立行为标签和数据 Schema → 实现 Adapter 和 L1 → 建设核心单轮集并接入 L2 → 接入结构化 LLM Judge 并完成人工校准 → 增加多轮剧本和专项指标 → 生成可下钻报告 → 建立 bad case 归因与回归流程 → 最后接入 CI 或平台 ^[extracted]。

## 相关页面

- [[concepts/agent-evaluation-framework]] — Agent 评测方法论框架
- [[concepts/llm-as-judge-evaluation]] — LLM-as-Judge 评估方法论
- [[concepts/evaluation-driven-development]] — 评估驱动开发
