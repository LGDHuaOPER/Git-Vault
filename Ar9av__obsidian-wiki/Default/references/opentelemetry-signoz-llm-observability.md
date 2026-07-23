---
title: 使用 OpenTelemetry 和 SigNoz 实现 LLM 可观测性
category: references
tags:
  - ai-agent
  - observability
  - opentelemetry
  - signoz
  - langchain
sources:
  - "云云众生s: 使用 OpenTelemetry 和 SigNoz 实现 LLM 可观测性 (2024-02-18)"
summary: 使用 OpenTelemetry 与 SigNoz 为 LangChain 应用构建开源 LLM 可观测性栈，支持手动插桩和 OpenLLMetry 自动插桩，并提供成本与性能监控仪表板。
base_confidence: 0.70
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
  - target: "[[entities/signoz]]"
    type: related_to
  - target: "[[entities/openllmetry]]"
    type: related_to
  - target: "[[concepts/genai-observability-semconv]]"
    type: related_to
  - target: "[[concepts/ai-agent-observability]]"
    type: related_to
---

# 使用 OpenTelemetry 和 SigNoz 实现 LLM 可观测性

## 为什么需要 LLM 可观测性

LLM 是错综复杂的系统，缺乏可观测性时理解内部动态会变成猜测游戏。主要用例包括：模型性能和准确性洞察、实时性能跟踪、资源利用和效率、问题检测和故障排除 ^[extracted]。

## OpenTelemetry 的优势

- **统一插桩**：单一方案收集全范围遥测数据
- **厂商中立性**：可与各种监控和分析平台配合
- **社区驱动和开源**
- **定制和可扩展性**
- **未来保障** ^[extracted]

## SigNoz 作为后端

SigNoz 是天生支持 OpenTelemetry 的 APM，专为 OpenTelemetry 构建，支持 OpenTelemetry 语义约定，为 traces、metrics、logs 三种信号提供可视化。整个可观测性堆栈可完全开源 ^[extracted]。

## 两种插桩方式

### 手动插桩（OpenTelemetry SDK）

使用 `opentelemetry-sdk`，通过 `start_span` 在 API 请求周围创建 span 并设置属性，允许细粒度控制但实施耗时 ^[extracted]。

### 自动插桩（OpenLLMetry）

`traceloop-sdk` 可自动插桩 LangChain 应用中的 OpenAI 调用、Vector DB 检索等。初始化后通过 `Traceloop.set_association_properties` 设置 user_id、chat_id 等关联属性 ^[extracted]。

## SigNoz 仪表板

支持使用查询构建器创建图表，可监控总 LLM 调用、延迟、令牌吞吐量、运行成本等指标。支持动态仪表板变量（按服务或用户筛选）、阈值告警、Slack/Teams/PagerDuty 通知，并提供预构建的 LangChain 性能和成本仪表板 JSON ^[extracted]。

## 相关页面

- [[entities/signoz]] — SigNoz 开源 APM
- [[entities/openllmetry]] — OpenLLMetry 自动插桩 SDK
- [[concepts/genai-observability-semconv]] — OpenTelemetry GenAI 语义规范
