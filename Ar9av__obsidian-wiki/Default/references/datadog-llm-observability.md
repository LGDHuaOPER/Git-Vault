---
title: Datadog - What Is LLM Observability & Monitoring
category: references
tags:
  - ai-agent
  - observability
  - datadog
  - llm
  - monitoring
sources:
  - "Datadog: What Is LLM Observability & Monitoring (2024-04-23)"
summary: Datadog 知识中心对 LLM 可观测性的定义：覆盖输入输出监控、请求链路追踪、延迟与 Token 追踪，以及幻觉、成本超支、安全漏洞等问题的提前发现。
provenance:
  extracted: 0.78
  inferred: 0.17
  ambiguous: 0.05
base_confidence: 0.73
lifecycle: draft
lifecycle_changed: 2026-07-22
tier: supporting
created: 2026-07-22T00:00:00+08:00
updated: 2026-07-22T00:00:00+08:00
relationships:
  - target: "[[concepts/ai-agent-observability]]"
    type: related_to
---

# Datadog - What Is LLM Observability & Monitoring

> 原文：What Is LLM Observability & Monitoring?（Datadog Knowledge Center，2024-04-23）

## 定义

LLM observability 是一套工具、技术和实践，为工程和数据科学团队持续提供 LLM 应用行为和性能的可见性。它覆盖：

- 监控输入和输出
- 追踪请求在模型链中的流转
- 追踪延迟和 Token 使用
- 检测幻觉、成本超支、安全漏洞等问题

生产环境中的 LLM 应用与传统软件有本质不同：输出非确定性、模型链不透明、失败不总是以错误形式出现，而表现为错误或低质量响应。

## LLM 应用常见问题

1. **Hallucinations（幻觉）**：对无答案的查询生成看似自信但实际错误的回答。
2. **Performance and cost（性能与成本）**：依赖第三方模型导致性能下降、算法变化不一致、高成本。
3. **Prompt hacking（提示词攻击）**：用户通过 Prompt injection 影响 LLM 生成不当或有害内容。
4. **Security and data privacy（安全与数据隐私）**：数据泄露、输出偏见、未授权访问、生成包含敏感或个人数据的响应。
5. **Model prompt and response variance（Prompt 和响应差异）**：同一查询收到不同响应，导致用户体验不一致。

## LLM 可观测性的收益

1. **Improved LLM application performance**：实时监控延迟、吞吐量和响应质量，及时干预。
2. **Better explainability**：可视化请求-响应对、词嵌入、Prompt 链序列，增强可解释性和信任。
3. **Faster issue diagnosis**：端到端可见性帮助 pinpoint 无响应或错误响应的根因。
4. **Increased security**：监控模型行为、访问模式、输入输出，检测数据泄露或对抗攻击。
5. **Efficient cost management**：监控资源消耗和利用，识别瓶颈或低利用率，优化成本。

## 选择 LLM 可观测方案的要点

1. **LLM chain debugging**：完整可见 LLM 链操作，快速排查 Agent 循环或链变慢问题。
2. **Visibility into complete application stack**：覆盖 GPU、数据库、服务、模型等完整应用栈。
3. **Explainability and anomaly detection**：提供决策过程洞察，并内置异常、偏见检测能力。
4. **Scalability, integration, and security**：高可扩展、多平台集成、PII 脱敏、敏感数据扫描、Prompt hacking 防护。
5. **Full lifecycle support**：不仅服务生产，也支持开发阶段的实验和微调。
