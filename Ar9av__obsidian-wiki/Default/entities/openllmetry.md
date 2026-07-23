---
title: OpenLLMetry
category: entities
tags:
  - ai-agent
  - observability
  - opentelemetry
  - instrumentation
  - open-source
sources:
  - "云云众生s: 使用 OpenTelemetry 和 SigNoz 实现 LLM 可观测性 (2024-02-18)"
summary: Traceloop 推出的 OpenTelemetry 库，用于快速为 LangChain 等 LLM 应用自动插桩，自动捕获 OpenAI 调用、Vector DB 检索等遥测数据。
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
  - target: "[[entities/signoz]]"
    type: related_to
  - target: "[[concepts/genai-observability-semconv]]"
    type: implements
  - target: "[[concepts/ai-agent-observability]]"
    type: related_to
  - target: "[[entities/langfuse-llm-observability]]"
    type: related_to
---

# OpenLLMetry

**OpenLLMetry** 是由 Traceloop 构建的 OpenTelemetry 库，用于快速为 LangChain 等 LLM 应用自动插桩。可以将其理解为具有内置能力来插桩 LLM 生态系统组件的 OpenTelemetry ^[extracted]。

## 核心能力

- **自动插桩**：除 API 和数据库调用外，自动插桩 LangChain 应用中的 OpenAI 调用、Vector DB 检索等
- **低接入成本**：安装 SDK 并在应用入口初始化即可
- **关联属性**：支持设置 user_id、chat_id 等关联属性，便于按用户或会话排查问题 ^[extracted]

## 使用方式

```python
from traceloop.sdk import Traceloop
Traceloop.init(app_name="Your App")
```

可通过环境变量配置后端：
```
TRACELOOP_BASE_URL=ingest.{region}.signoz.cloud
TRACELOOP_HEADERS="signoz-access-token=..."
```

## 与 OpenTelemetry 的关系

OpenLLMetry 构建在 OpenTelemetry 之上，将 LLM 生态特定的插桩能力封装为易用的 SDK。采集的数据遵循 OpenTelemetry 语义约定，可导出到任何兼容后端（如 SigNoz、[[entities/langfuse-llm-observability|Langfuse]] 等）^[extracted]。

## 相关页面

- [[entities/signoz]] — 常用后端 APM
- [[concepts/genai-observability-semconv]] — OpenTelemetry GenAI 语义规范
- [[references/opentelemetry-signoz-llm-observability]] — 集成教程
