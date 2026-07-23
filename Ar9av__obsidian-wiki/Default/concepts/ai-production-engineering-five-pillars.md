---
title: "AI Production Engineering: Five Pillars"
category: concepts
tags:
  - ai-agent
  - production-operations
  - governance
  - safety
  - cost-management

relationships:
  - target: "[[entities/arize-phoenix]]"
    type: related_to
  - target: "[[entities/langfuse-llm-observability]]"
    type: related_to
sources:
  - "ThinkingAgent: AI安全和治理：AI Observability、Evaluation、治理、安全与成本 (2026-06-28)"
  - "阿里云可观测: LoongCollector + ACS Agent Sandbox：构建 AI Agent 生产级运行平台 (2026-04-06)"
summary: "AI 运行工程化的五维框架：可观测性、评估、治理、安全、成本。从实验品到生产基础设施所需的全套工程实践，以及分阶段落地路线图。"
base_confidence: 0.67
lifecycle: draft
lifecycle_changed: "2026-07-16"
tier: supporting
provenance:
  extracted: 0.6
  inferred: 0.3
  ambiguous: 0.1
created: 2026-07-16
updated: "2026-07-22"
---

# AI Production Engineering: Five Pillars

AI 系统从「实验品」变成「生产基础设施」后，运行工程化不再是可选项，而是必需品。它涵盖五个维度 ^[extracted]：

1. **Observability（可观测性）** — 从黑盒到透明
2. **Evaluation（评估）** — 质量的持续度量
3. **Governance（治理）** — 合规与可审计性
4. **Safety（安全）** — 防护与对抗
5. **Cost（成本）** — 精细化管控

## 五大维度详解

### Observability
四大支柱：Tracing + Metrics + Logging + Alerting。详见 [[agent-observability-fundamentals]]。核心原则：从 Day 1 就建立，不要等出了问题才加监控。

### Evaluation
三个层次：自动化评估 → 半自动评估 → 人工评估。LLM-as-Judge 是核心方法（见 [[llm-as-judge-evaluation]]）。评估是持续的过程，每次模型/工具变更都需重新评估。

### Governance（治理）
五大维度：透明性、公平性、问责制、隐私保护、安全保障。关键实践：
- 完整的审计日志（谁、何时、做了什么决策、基于什么输入）
- 关注全球监管动态（EU AI Act 2026 生效、NIST AI RMF 2025）
- 治理要前置——合规成本远高于预防成本 ^[extracted]

### Safety（安全）
五大威胁：Prompt 注入、数据泄露、模型滥用、对抗攻击、供应链风险。五层防护：输入过滤 → 模型安全 → 输出审查 → 运行时监控 → 审计回溯。定期红队测试是生产环境的必要实践。

### Cost（成本）
七个优化策略 ^[extracted]：

| 策略 | 效果 |
|------|------|
| **智能模型路由** | 简单任务走小模型，复杂任务走大模型；成本降低 40-60% |
| **语义缓存** | 相似查询复用结果；成本降低 30-50% |
| **Prompt 优化** | 结构化 Prompt、动态上下文、压缩历史；Token 减少 20-40% |
| **批量处理** | 非实时任务批量调用；成本降低 50%（OpenAI Batch API） |
| **模型降级** | 在可接受质量损失下使用更便宜模型；如 GPT-4o → GPT-4o-mini 成本 -90% |
| **Token 预算控制** | 为用户/项目/任务设置预算，超阈值告警或降级 |
| **自托管模型** | 高频调用场景自托管开源模型；成本降低 10 倍 |

详见 [[agent-cost-breakdown]]。

## 分阶段落地路线图

### 阶段 1：启动（0-1 月）
- Observability：[[entities/langfuse-llm-observability|Langfuse]] Cloud / 开源自部署
- Evaluation：基础 LLM-as-Judge
- 治理：基础日志
- 安全：Prompt 注入防护
- 成本：设置预算告警

### 阶段 2：成长（1-3 月）
- Observability：自建平台 + OpenTelemetry
- Evaluation：评估数据集 + CI/CD 集成
- 安全：内容过滤 + 输出审查
- 成本：模型路由优化

### 阶段 3：企业（3-6 月）
- Observability：自建 + [[entities/arize-phoenix|Arize Phoenix]]
- Evaluation：多层次评估 + 人工评估
- 治理：合规认证 + AI 影响评估
- 安全：专业红队 + SOC
- 成本：精细化管控 + 自托管模型

## 十条最佳实践

1. 从 Day 1 就建立 Observability
2. 评估是持续的过程，不是一次性的
3. 安全是底线，不是优化项
4. 成本优化要量化 ROI
5. 治理要前置，不要事后补救
6. 自动化一切可自动化的（评估、监控、告警、报告）
7. 建立跨职能团队（工程、产品、法务、安全）
8. 保持透明度（对用户、监管、内部）
9. 持续学习——每次事件都是改进机会
10. 文档化一切（决策、配置、变更、事件）

AI 系统的价值由模型能力决定，但可靠性由运行工程化决定。在生产环境中，可靠性永远比能力更重要 ^[extracted]。

## 相关页面

- [[agent-observability-fundamentals]] — 可观测性子系统
- [[llm-as-judge-evaluation]] — 评估子系统
- [[agent-cost-breakdown]] — 成本子系统
- [[opentelemetry-genai-agent-setup]] — 标准化观测基础设施
