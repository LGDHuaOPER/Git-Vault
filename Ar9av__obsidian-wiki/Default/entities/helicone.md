---
title: Helicone
category: entities
tags:
  - ai-agent
  - observability
  - gateway
  - cost-management
  - llm
sources:
  - "唧唧复急急: AI 智能体应用时代，可观测性怎么做？ (2026-03-27)"
summary: 偏网关与成本层的 LLM 可观测性方案，通过请求代理、多模型路由、Token 计费与配额控制，解决生产入口治理问题。
provenance:
  extracted: 0.75
  inferred: 0.20
  ambiguous: 0.05
base_confidence: 0.53
lifecycle: draft
lifecycle_changed: 2026-07-22
tier: supporting
created: 2026-07-22T00:00:00+08:00
updated: 2026-07-22T00:00:00+08:00
relationships:
  - target: "[[concepts/ai-agent-observability]]"
    type: implements
  - target: "[[concepts/agent-cost-breakdown]]"
    type: implements
  - target: "[[entities/langfuse-llm-observability]]"
    type: related_to
---

# Helicone

**Helicone** 是 LLM 可观测性生态中偏**网关 / 成本层**的代表性方案。^[extracted] 与 Phoenix、Langfuse 等工作台层方案不同，Helicone 的关注点不是"模型为什么答错"，而是"所有请求从哪里进、花了多少钱、能不能统一控流和审计"。^[extracted]

## 核心定位

Helicone 解决的是**生产入口治理问题**：多模型路由、API 代理、请求日志、Token 计费、成本分摊、缓存、限流、Key 管理，外加一部分基础 tracing。^[extracted]

## 核心能力

### 统一接入

支持统一接入 OpenAI、Anthropic、Azure OpenAI、各类开源推理服务。^[extracted] 对于同时接多个模型供应商、多个团队共享同一套模型预算的团队非常实用。^[extracted]

### 成本可见性

- 按业务线、按模型、按时间维度统计 Token 消耗与费用。^[extracted]
- 提供预算告警和配额控制，防止"钱包拒绝服务攻击"。^[inferred]
- 通过代理层降低 SDK 接入复杂度。^[extracted]

### 请求治理

- 多模型路由：根据成本、延迟、可用性动态选择模型。^[inferred]
- 缓存：对重复请求进行缓存，降低冗余调用成本。^[inferred]
- 限流与 Key 管理：统一管控 API Key 与调用速率。^[extracted]

## 与 Phoenix / Langfuse 的对比

| 维度 | Helicone | Phoenix | Langfuse |
|------|----------|---------|----------|
| 分层定位 | 网关 / 成本层 | 观测 / 评估工作台层 | 观测 / 评估工作台层 |
| 核心问题 | 入口治理、记账、配额 | Trace + Eval + Dataset | Trace + Prompt 管理 + Eval |
| 接入方式 | 改 base_url 即可 | SDK instrumentation | SDK instrumentation |
| 强项 | 成本、路由、Key 管理 | RAG 深度分析、OTel 原生 | 开源 LLM 工程闭环 |
| 边界 | 不擅长业务质量归因 | 不是统一流量入口 | 需要搭配治理层 |

^[extracted]

## 适用场景

- 需要统一模型入口、控预算、做路由治理的**平台型团队**。^[extracted]
- 多团队共享模型预算，需要成本分摊与配额控制。^[extracted]
- 希望通过代理层快速接入多家模型供应商，降低 SDK 改造工作量。^[extracted]

## 局限性

Helicone 更强在**入口治理和成本可见性**，不是完整的智能体评估工作台。^[extracted] 它通常不擅长回答"这次回答为什么业务上不合格"，需要与 Phoenix、Langfuse 等工具配合使用。^[extracted]

## 相关页面

- [[concepts/ai-agent-observability]] — 可观测性分层架构
- [[concepts/agent-cost-breakdown]] — Agent 成本构成与治理
- [[entities/langfuse-llm-observability]] — 工作台层开源方案
- [[entities/arize-phoenix]] — 另一个工作台层开源方案
