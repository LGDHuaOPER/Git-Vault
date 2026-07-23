---
title: Lunary
category: entities
tags:
  - ai-agent
  - observability
  - evaluation
  - open-source
  - llm
sources:
  - "尼可同学: AI 应用上线后怎么监控？7 款评测与可观测性工具，帮你告别“盲人调参” (2026-07-22)"
summary: 开源 LLM 可观测性平台，强调轻量接入，侧重用户会话、成本统计和用户反馈，适合早期产品团队快速看清线上使用情况。
provenance:
  extracted: 0.80
  inferred: 0.15
  ambiguous: 0.05
base_confidence: 0.48
lifecycle: draft
lifecycle_changed: 2026-07-22
tier: supporting
created: 2026-07-22T12:00:00+08:00
updated: 2026-07-22T12:00:00+08:00
relationships:
  - target: "[[concepts/ai-agent-observability]]"
    type: implements
  - target: "[[entities/langfuse-llm-observability]]"
    type: related_to
  - target: "[[entities/arize-phoenix]]"
    type: related_to
  - target: "[[entities/helicone]]"
    type: related_to
---

# Lunary

**Lunary** 是一款开源 LLM 可观测性平台，提供执行轨迹、用户会话、成本统计、提示词管理和评测。^[extracted] 它强调轻量接入，适合还没有专门平台团队、但已经需要看清线上使用情况的早期产品。^[extracted]

## 核心定位

与单纯记录模型请求相比，Lunary 更重视**用户和会话维度**。你可以追踪某位用户经历了哪些对话、某类功能消耗了多少成本，并把最终用户的点赞、点踩或其他反馈接入评测流程。^[extracted]

## 核心能力

- **执行轨迹（Tracing）**：记录模型调用、工具调用和 Agent 执行步骤
- **用户与会话分析**：按用户或会话聚合对话历史、成本和使用情况
- **成本统计**：按模型、用户、功能等维度统计 Token 消耗与费用
- **提示词管理**：集中管理提示词版本
- **评测（Evaluation）**：支持自动或人工对输出质量打分

## 适用场景

**适合谁**：希望用较少工程投入获得会话追踪、成本分析和用户反馈的初创团队。^[extracted]

**生态规模和企业级集成能力与头部平台仍有差距**，但对于小团队，功能简单、部署轻反而意味着能更快开始使用。^[extracted]

## 与同类工具对比

| 维度 | Lunary | Langfuse | Arize Phoenix |
|------|--------|----------|---------------|
| 核心视角 | 用户 / 会话 / 成本 | Trace / Prompt / Eval | RAG 深度分析 / Eval |
| 接入复杂度 | 低 | 中 | 中 |
| 开源协议 | 开源 | MIT | Mulan PSL 2.0 / Apache 2.0 |
| 企业级集成 | 较弱 | 较强 | 较强 |

## 相关页面

- [[references/7-llm-observability-tools]] — 七款工具选型指南
- [[entities/langfuse-llm-observability]] — 开源 LLM 可观测平台
- [[entities/arize-phoenix]] — RAG 与评测导向平台
- [[entities/helicone]] — LLM 网关与成本监控
- [[concepts/ai-agent-observability]] — AI Agent 可观测性整体概念
