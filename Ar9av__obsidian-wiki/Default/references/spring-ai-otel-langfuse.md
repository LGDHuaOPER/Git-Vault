---
title: Spring AI + OpenTelemetry + Langfuse 生产级可观测方案
category: references
tags:
  - ai-agent
  - observability
  - spring-ai
  - opentelemetry
  - langfuse
sources:
  - "可执行AI方案库: Spring AI 应用上生产，最先缺的不是模型，而是可观测性 (2026-04-18)"
summary: 基于 Spring AI + OpenTelemetry + 自托管 Langfuse 的生产级 LLM 应用可观测方案，通过 OTLP 将 LLM 调用封装为 Trace/Span 导出到 Langfuse，实现 Prompt、Token、延迟、成本和错误的统一观测。
base_confidence: 0.75
lifecycle: draft
lifecycle_changed: "2026-07-22"
tier: supporting
provenance:
  extracted: 0.85
  inferred: 0.15
  ambiguous: 0.0
created: "2026-07-22"
updated: "2026-07-22"
relationships:
  - target: "[[concepts/ai-agent-observability]]"
    type: implements
  - target: "[[entities/langfuse-llm-observability]]"
    type: uses
  - target: "[[concepts/genai-observability-semconv]]"
    type: uses
  - target: "[[skills/langfuse-self-hosting]]"
    type: related_to
---

# Spring AI + OpenTelemetry + Langfuse 生产级可观测方案

## 为什么 Spring AI 应用需要专门的 LLM 可观测性？

传统应用的可观测性通常关注 CPU、内存、数据库查询、接口耗时和错误率。但 LLM 应用多了一批新的关键指标：

- **Prompt 可追踪**：知道最终发给模型的输入是什么，而不是只看业务参数
- **Token 可统计**：区分 prompt tokens、completion tokens 和 total tokens
- **成本可估算**：将模型、Token 和调用次数关联起来，避免费用失控
- **链路可回放**：从用户请求一路追到模型调用、工具调用和异常节点

LLM 调用不是一次普通的 HTTP 请求，它往往包含 Prompt 组装、RAG 检索、工具调用、模型请求、流式响应、Token 统计、异常重试等多个环节。缺少可观测性，就等于在黑盒里调生产问题。

## 整体架构

推荐的架构可以分为五层：业务入口、Spring AI 调用层、OpenTelemetry 采集层、OTLP 导出层和 Langfuse 观测平台。

```
业务入口（Spring Boot）
    ↓
Spring AI 调用层（统一模型调用抽象）
    ↓
OpenTelemetry 采集层（生成和导出 Trace）
    ↓
OTLP 导出层
    ↓
Langfuse 观测平台（接收、存储和展示）
```

**关键设计原则**：不要把 LLM 调用当成孤立日志处理，而是把它纳入完整分布式链路追踪体系。这样排查问题时，就可以从一次用户请求直接看到模型调用、Token 消耗、耗时分布和异常原因。

## 一次请求的完整链路

当用户发起一次请求后，系统会先生成或继承 Trace Context。随后，业务逻辑、RAG 检索、Prompt 组装、Spring AI 调用和模型响应都会被串联起来。

最终，在 Langfuse 中可以看到每一次调用的完整上下文，包括：

- 请求对应的 `trace_id` 和 `span_id`
- 使用的模型名称（如 gpt-4o、gpt-4.1 或企业私有模型）
- Prompt tokens、Completion tokens、Total tokens
- LLM 调用延迟、总请求耗时和异常类型
- 工具调用、RAG 检索、下游服务调用等上下文

## 接入 OpenTelemetry 的核心思路

在 Spring Boot 应用里，OpenTelemetry 通常有两种接入方式：

### 1. 基础链路自动采集

HTTP 请求、数据库访问、Redis、消息队列等常规链路可以交给 OpenTelemetry Java Agent 自动采集。这样可以快速获得完整的后端请求链路。

### 2. LLM 调用手动增强

Spring AI 的模型调用处需要补充 LLM 语义字段，例如模型名称、Token 使用量、Prompt 长度、响应耗时、错误类型等。这部分信息通常需要在业务代码或统一拦截器中显式写入 Span Attribute：

```java
// 示例：为一次 LLM 调用补充观测字段
span.setAttribute("llm.system", "spring-ai");
span.setAttribute("llm.model", modelName);
span.setAttribute("llm.prompt_tokens", promptTokens);
span.setAttribute("llm.completion_tokens", completionTokens);
span.setAttribute("llm.total_tokens", totalTokens);
span.setAttribute("llm.latency_ms", latencyMs);
```

这些字段进入 Langfuse 后，就不只是"有日志"，而是能够按模型、耗时、错误、Token 和成本进行分析。

## 为什么选择自托管 Langfuse？

Langfuse 更贴近 LLM 应用场景。相比只看通用 APM，它能更自然地展示 Prompt、Response、Token、Session、Trace 和模型调用细节：

- **数据可控**：自托管部署，适合对 Prompt、用户数据和模型输出有合规要求的团队
- **LLM 友好**：围绕 Prompt、Trace、Token、评估和模型调用设计
- **工程兼容**：通过 OpenTelemetry/OTLP 接入，不强绑定某个模型供应商
- **排障直接**：从异常请求直接定位到具体 Prompt、工具调用或模型返回

## 生产环境必须考虑的 5 个细节

### 1. 采样策略

生产环境不一定需要 100% 采集。可以对普通请求按比例采样，对错误请求、慢请求和高成本请求全量采集。

### 2. 脱敏与合规

Prompt 和 Response 可能包含用户隐私、合同内容、内部知识库信息。进入 Langfuse 前，应支持字段级脱敏、正则脱敏或按场景关闭内容记录。

### 3. 异步导出

Trace 导出不能阻塞主业务链路。推荐使用批处理和异步导出，避免观测平台波动影响用户请求。

### 4. 故障降级

Langfuse 或网络不可用时，应允许丢弃 Span，而不是拖垮业务系统。可观测性系统应该服务于稳定性，而不是成为新的单点风险。

### 5. 统一字段规范

建议在团队内统一字段命名，例如 `llm.model`、`llm.total_tokens`、`llm.latency_ms`、`error.type`。字段标准化后，后续统计、告警和报表才有基础。

## 落地建议：三阶段推进

### 第一阶段：先看见

接入 OpenTelemetry 基础链路和 Langfuse，确保每一次 LLM 请求都能被追踪。

### 第二阶段：看清楚

补齐模型名称、Token、延迟、错误类型、用户会话、业务场景等关键字段。

### 第三阶段：可治理

基于 Trace 数据建立成本报表、慢请求分析、Prompt 质量评估、异常告警和模型对比机制。

**最终目标不是多一个监控面板**，而是让 LLM 应用从"能跑"进入"可解释、可排障、可优化、可治理"的生产状态。

## 适用场景

这套方案尤其适合以下场景：

- 已经使用 Spring Boot / Spring Cloud 构建企业应用的团队
- 正在用 Spring AI 接入 OpenAI、Azure OpenAI 或私有大模型的团队
- 希望把 LLM 调用纳入现有 OpenTelemetry 体系的团队
- 对 Prompt、模型输出和用户数据有合规要求，需要自托管观测平台的团队
- 希望分析 Token 成本、慢请求、错误率和模型表现的团队

## 相关页面

- [[concepts/ai-agent-observability]] — AI Agent 可观测性整体概念
- [[entities/langfuse-llm-observability]] — Langfuse LLM 可观测平台
- [[concepts/genai-observability-semconv]] — OpenTelemetry GenAI 语义规范
- [[references/opentelemetry-genai-agent-setup]] — OTel 在 Agent 场景中的实战配置
- [[skills/langfuse-self-hosting]] — Langfuse 自托管部署指南