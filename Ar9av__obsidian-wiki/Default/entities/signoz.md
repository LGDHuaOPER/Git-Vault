---
title: SigNoz
category: entities
tags:
  - ai-agent
  - observability
  - opentelemetry
  - apm
  - open-source
sources:
  - "云云众生s: 使用 OpenTelemetry 和 SigNoz 实现 LLM 可观测性 (2024-02-18)"
summary: 天生支持 OpenTelemetry 的开源 APM，为 traces、metrics、logs 提供统一可视化后端，常与 OpenLLMetry 配合构建开源 LLM 可观测栈。
base_confidence: 0.68
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
  - target: "[[entities/openllmetry]]"
    type: uses
  - target: "[[concepts/genai-observability-semconv]]"
    type: implements
  - target: "[[concepts/ai-agent-observability]]"
    type: related_to
---

# SigNoz

**SigNoz** 是一款天生支持 OpenTelemetry 的开源 APM，从一开始就专为 OpenTelemetry 构建，为 traces、metrics、logs 三种信号提供统一可视化界面 ^[extracted]。

## 核心特点

- **原生 OpenTelemetry 支持**：支持 OpenTelemetry 语义约定，避免供应商锁定
- **全栈开源**：配合 OpenTelemetry 和 OpenLLMetry 可构建完全开源的可观测性堆栈
- **统一界面**：将日志、指标和跟踪集中在一个界面上
- **成本可控**：相比 Datadog 等商业工具，高基数自定义指标成本更可控 ^[extracted]

## LLM 可观测性用法

常与 [[entities/openllmetry]] 配合使用：
1. 在 LangChain 等 LLM 应用中通过 OpenLLMetry 自动插桩
2. 将遥测数据通过 OTLP 发送到 SigNoz 后端
3. 在 SigNoz 仪表板中查看 LLM 调用延迟、Token 吞吐量、成本等指标

## 仪表板能力

- 查询构建器创建图表
- 动态仪表板变量（按服务、用户筛选）
- 阈值告警
- Slack/Teams/PagerDuty 通知
- 预构建 LangChain 性能和成本仪表板 ^[extracted]

## 相关页面

- [[entities/openllmetry]] — 自动插桩 SDK
- [[concepts/genai-observability-semconv]] — OpenTelemetry GenAI 语义规范
- [[references/opentelemetry-signoz-llm-observability]] — 详细集成教程
