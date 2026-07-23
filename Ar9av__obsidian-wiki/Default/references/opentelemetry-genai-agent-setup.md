---
title: "OpenTelemetry for GenAI Agent Observability"
category: references
tags:
  - ai-agent
  - observability
  - opentelemetry
  - tracing
  - genai

relationships:
  - target: "[[concepts/ai-agent-observability]]"
    type: related_to
  - target: "[[entities/langfuse-llm-observability]]"
    type: related_to
sources:
  - "AI Engineer编程: OpenTelemetry + Agent 可观测平台基础 (2026-07-11)"
  - "阿里云可观测: AI 原生应用全栈可观测实践：以 DeepSeek 对话机器人为例"
summary: "OpenTelemetry 在 GenAI Agent 可观测场景中的实战配置：TracerProvider/SpanProcessor/SpanExporter 三层架构、手动插桩模式、Collector 部署与采样策略、分布式追踪的 Context 传播。"
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

# OpenTelemetry for Gen[[concepts/ai-agent-observability|AI Agent Observability]]

## 三层架构

OpenTelemetry SDK 的三层架构是理解 Agent 观测管道的关键 ^[extracted]：

### 1. TracerProvider（管理中心）
```python
from opentelemetry.sdk.trace import TracerProvider
provider = TracerProvider(resource=resource)
trace.set_tracer_provider(provider)
```
职责：创建 Tracer、管理 SpanProcessor 链、生成 trace_id/span_id。

### 2. SpanProcessor（处理链）
```python
from opentelemetry.sdk.trace.export import BatchSpanProcessor
processor = BatchSpanProcessor(otlp_exporter)
provider.add_span_processor(processor)
```
Span 结束后进入队列，积累到一定数量或时间后批量发送，减少网络请求次数。

### 3. SpanExporter（导出器）
```python
from opentelemetry.exporter.otlp.proto.grpc.trace_exporter import OTLPSpanExporter
exporter = OTLPSpanExporter(endpoint="http://localhost:4317", insecure=True)
```
将数据发送到后端（Jaeger、[[entities/langfuse-llm-observability|Langfuse]]、Prometheus 等）。

## 手动插桩模式

对于 Agent 应用，推荐手动创建 Span 以获得精确的语义控制 ^[extracted]：

```python
from opentelemetry import trace
tracer = trace.get_tracer(__name__)

with tracer.start_as_current_span(
    "agent.run",
    kind=trace.SpanKind.SERVER,
) as root:
    root.set_attribute("agent.input", user_query)
    root.set_attribute("gen_ai.system", "deepseek")

    # LLM 调用
    with tracer.start_as_current_span(
        "llm.call",
        kind=trace.SpanKind.CLIENT,
    ) as llm_span:
        llm_span.set_attribute("gen_ai.request.model", "deepseek-v3")
        llm_span.set_attribute("gen_ai.usage.input_tokens", 150)
        llm_span.set_attribute("gen_ai.usage.output_tokens", 80)

    # 工具调用
    with tracer.start_as_current_span(
        "tool.search",
        kind=trace.SpanKind.CLIENT,
    ) as tool_span:
        tool_span.set_attribute("tool.name", "web_search")
        tool_span.set_attribute("tool.duration_ms", 320)
```

## Collector 部署

Collector 解耦了应用和后端，实现数据脱敏、采样控制、多后端分发 ^[extracted]：

```yaml
receivers:
  otlp:
    protocols:
      grpc:
        endpoint: 0.0.0.0:4317

processors:
  batch:
    timeout: 1s
    send_batch_size: 1024
  memory_limiter:
    limit_mib: 512

exporters:
  jaeger:
    endpoint: jaeger:14250
    tls:
      insecure: true

service:
  pipelines:
    traces:
      receivers: [otlp]
      processors: [memory_limiter, batch]
      exporters: [jaeger]
```

## 采样策略

| 策略 | 原理 | 适用 |
|------|------|------|
| **头部采样** | 请求入口处决策，下游跟随 | 简单场景 |
| **尾部采样** | Trace 完成后按内容（错误、延迟）决策 | 生产中推荐 |
| **混合采样** | 头部降采样 + 尾部精细决策 | 大规模生产 |

尾部采样配置示例：
```yaml
processors:
  tail_sampling:
    decision_wait: 10s
    policies:
      - name: errors
        type: status_code
        status_code: {status_codes: [ERROR]}
      - name: slow
        type: latency
        latency: {threshold_ms: 1000}
      - name: probabilistic
        type: probabilistic
        probabilistic: {sampling_percentage: 10}
```

## 分布式追踪：Context 传播

跨服务调用时，Context 传播确保前后端 Span 属于同一个 Trace ^[extracted]：

1. **inject()** 必须在 `start_span` 之后调用（读取当前 active span）
2. **extract()** 返回的是 Context，不是 Span
3. 每次调用下游都需要新建 headers 并重新 `inject()`（不能复用）

## 高流量降级保护

生产环境中，应用端需要做队列和超时保护 ^[inferred]：
- Span 发送队列有容量上限，满了以后丢弃新 Span（不影响业务）
- 动态调整采样率来降低发送量
- Agent 端监控 Span 丢弃率，评估是否需要扩容 Collector

## 相关页面

- [[agent-trace-span-taxonomy]] — Trace/Span 设计
- [[agent-observability-fundamentals]] — 可观测性概念框架
- [[langfuse-platform]] — 可对接的观测平台
- [[alicloud-loongcollector-agent-sandbox]] — 阿里云的 Collector 实现
