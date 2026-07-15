---
title: "LLM-as-Judge Evaluation"
category: concepts
tags:
  - ai-agent
  - evaluation
  - llm-as-judge
  - quality-assurance
sources:
  - "ThinkingAgent: AI安全和治理：AI Observability、Evaluation、治理、安全与成本 (2026-06-28)"
  - "阿里云可观测: AI 原生应用全栈可观测实践：以 DeepSeek 对话机器人为例"
summary: "LLM-as-Judge 评估方法论：用 LLM 作为评判器对 Agent 输出进行自动化质量评估，涵盖忠实度、相关性、安全性等维度，以及三级评估体系（自动化/半自动/人工）。"
base_confidence: 0.67
lifecycle: draft
lifecycle_changed: "2026-07-16"
tier: supporting
provenance:
  extracted: 0.6
  inferred: 0.3
  ambiguous: 0.1
created: 2026-07-16
updated: 2026-07-16
---

# LLM-as-Judge Evaluation

## 为什么需要 LLM 评估 Agent 输出

传统自动化测试无法评估 Agent 输出的质量——"答案对不对"往往没有标准答案。LLM-as-Judge 用另一个 LLM 作为评判器，对 Agent 的输出进行多维度打分。这是当前最主流的 AI 输出评估方法 ^[extracted]。

核心评估维度：
- **Faithfulness（忠实度）**：回答是否忠于给定的上下文/RAG 文档，有无编造
- **Relevance（相关性）**：回答是否切题
- **Safety（安全性）**：回答是否包含有害内容
- **Completeness（完整性）**：回答是否覆盖了问题的所有方面

## 三级评估体系

### Level 1: 自动化评估（每次 Agent Run）
- LLM-as-Judge 自动打分
- 基于规则的检查（格式、长度、关键词）
- 适用于每次请求的实时质量门禁 ^[inferred]

### Level 2: 半自动评估（每日/每周批次）
- 抽样 + LLM-as-Judge 深度评估
- 结合业务指标（用户反馈、任务完成率）
- 发现系统性质量退化趋势

### Level 3: 人工评估（周期性）
- 领域专家抽查
- A/B 测试对比
- 评估标准本身的校准

## 评估 Prompt 设计

LLM-as-Judge 的核心是评估 Prompt 的设计。一个好的评估 Prompt 应该 ^[inferred]：
1. 明确评估维度（faithfulness/relevance/safety）
2. 提供评分标准（1-5 分的具体含义）
3. 要求给出评分理由（可解释性）
4. 避免引导性措辞（减少 Judge 偏见）

## 质量门禁

建立质量门禁，在 Agent 输出被返回给用户前做最后检查：
```
Agent 输出 → 质量评估 → 通过 → 返回用户
                      → 不通过 → 重试/降级/拒绝
```

## 工具集成

主流可观测平台都内置了评估能力：
- [[langfuse-platform]] 支持将 trace 导出为评估数据集，在线运行 LLM-as-Judge 评估
- [[litefuse-doris-native-observability]] 内置了基于 Doris 的批量评估引擎
- Arize Phoenix 提供漂移检测——监控同输入下输出质量是否在下降

## 相关页面

- [[agent-observability-fundamentals]] — 评估是可观测性的自然延伸
- [[ai-production-engineering-five-pillars]] — 评估在运行工程化中的位置
- [[agent-failure-taxonomy]] — 失败分类支撑评估维度
