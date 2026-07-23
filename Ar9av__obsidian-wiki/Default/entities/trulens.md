---
title: TruLens
category: entities
tags:
  - ai-agent
  - observability
  - evaluation
  - rag
  - open-source
sources:
  - "尼可同学: AI 应用上线后怎么监控？7 款评测与可观测性工具，帮你告别“盲人调参” (2026-07-22)"
summary: 以评测为中心的开源框架，提出 RAG Triad 从上下文相关性、回答相关性和事实依据三个维度系统评估 RAG 质量。
provenance:
  extracted: 0.82
  inferred: 0.13
  ambiguous: 0.05
base_confidence: 0.49
lifecycle: draft
lifecycle_changed: 2026-07-22
tier: supporting
created: 2026-07-22T12:00:00+08:00
updated: 2026-07-22T12:00:00+08:00
relationships:
  - target: "[[concepts/rag-observability]]"
    type: implements
  - target: "[[concepts/llm-as-judge-evaluation]]"
    type: uses
  - target: "[[entities/langfuse-llm-observability]]"
    type: related_to
  - target: "[[entities/arize-phoenix]]"
    type: related_to
---

# TruLens

**TruLens** 是一套以评测为中心的开源框架。它最有代表性的概念是 **RAG Triad**，也就是从三个维度检查 RAG：检索到的上下文是否与问题相关，回答是否与问题相关，回答是否真正建立在上下文证据之上。^[extracted]

## 核心定位

TruLens 更像一套专用评测框架，而不是覆盖所有生产监控需求的一站式平台。^[extracted] 如果团队还需要完整告警、用户分析和基础设施关联，通常要与其他可观测性工具搭配使用。^[extracted]

## RAG Triad

三个指标看似简单，却对应了 RAG 最常见的三类故障 ^[extracted]：

| 维度 | 检查什么 | 对应故障 |
|------|---------|---------|
| **上下文相关性（Context Relevance）** | 检索到的上下文是否与问题相关 | 找错资料 |
| **回答相关性（Answer Relevance）** | 回答是否与问题相关 | 答非所问 |
| **事实依据（Groundedness / Faithfulness）** | 回答是否真正建立在上下文证据之上 | 拿着正确资料继续胡编 |

## 核心能力

- **RAG Triad 评测**：系统评估检索和生成质量
- **大模型裁判（LLM-as-a-Judge）**：用 LLM 自动打分
- **自定义反馈函数**：根据业务规则定义评测逻辑
- **运行结果比较**：对比不同检索配置的效果
- **本地记录**：评测数据保存在本地，便于研发和调试

## 适用场景

**适合谁**：以 RAG 质量评测为核心任务，希望深入比较检索和生成效果的研发团队。^[extracted]

## 与通用可观测平台的边界

TruLens 不擅长完整告警、用户分析和基础设施关联。典型组合是：TruLens 负责研发阶段 RAG 评测，Langfuse 或 Phoenix 负责生产阶段 trace + 在线监控。^[inferred]

## 相关页面

- [[concepts/rag-observability]] — RAG 可观测性整体概念
- [[concepts/llm-as-judge-evaluation]] — LLM-as-Judge 评测方法
- [[references/7-llm-observability-tools]] — 七款工具选型指南
- [[entities/langfuse-llm-observability]] — 生产级开源可观测平台
- [[entities/arize-phoenix]] — RAG 深度分析平台
