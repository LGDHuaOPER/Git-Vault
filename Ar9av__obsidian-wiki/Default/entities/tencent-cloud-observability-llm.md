---
title: Tencent Cloud Observability LLM Observability
category: entities
tags: [observability, tencent, llm, openclaw, opentelemetry]
sources:
  - "腾讯云开发者: 告别“黑箱”养虾！腾讯云可观测平台给您的 OpenClaw 装上“透视眼” (2026-03-26)"
summary: 腾讯云可观测平台面向 LLM 应用的可观测解决方案，通过 OpenTelemetry + 双插件协同为 OpenClaw 等 Agent 提供 Trace 与 Metrics 一体化监控。
provenance:
  extracted: 0.70
  inferred: 0.25
  ambiguous: 0.05
base_confidence: 0.44
lifecycle: draft
lifecycle_changed: 2026-07-22
tier: supporting
created: 2026-07-22T00:00:00+08:00
updated: 2026-07-22T00:00:00+08:00
relationships:
  - target: "[[entities/openclaw]]"
    type: related_to
  - target: "[[concepts/genai-observability-semconv]]"
    type: uses
  - target: "[[concepts/ai-agent-observability]]"
    type: implements
---

# Tencent Cloud Observability LLM Observability

腾讯云可观测平台推出的 **LLM 可观测**解决方案，针对 OpenClaw 等 AI Agent 的运行特性，基于 OpenTelemetry 通用框架，通过"双插件协同"实现 Trace 链路追踪与 Metrics 指标监控的一体化。

## 双插件协同架构

### 底层基础：OpenTelemetry 通用框架

提供标准化数据采集、传输和格式定义，遵循 GenAI 语义规范。

### 核心插件 1：openclaw-tencent-plugin

腾讯云专属 Trace 链路追踪插件，深度适配 OpenClaw 运行链路和 Hook 机制，负责全流程 Trace 数据的采集、串联和标准化上报。

### 核心插件 2：diagnostics-otel

OpenClaw 原生 Metrics 指标采集插件，无需额外开发，自动识别启用，采集系统性能、队列状态、会话情况等核心指标。

## 接入流程

1. 在腾讯云控制台 LLM 可观测 → 应用列表接入 OpenClaw，获取接入点与 Token
2. 在 OpenClaw extensions 目录安装 `openclaw-tencent-plugin`
3. 编辑 `openclaw.json` 启用插件并配置 OTel 导出
4. 重启 OpenClaw
5. 验证插件状态与数据上报

## 可观测价值

### 全链路结构化追踪

基于 OpenTelemetry GenAI 语义规范，生成带父子关系的完整调用链：

`enter_openclaw_system → invoke_agent → chat → execute tool`

每个环节记录入口信息、模型推理详情、工具调用参数与结果、链路耗时。

### Token 消耗精细拆解

区分输入 Token、输出 Token、缓存读写 Token，按模型、调用场景、业务场景多维度聚合，支持趋势监控与费用预估。

### 系统运行指标实时监控

- 服务性能：QPS、平均/最大响应耗时、错误率
- 队列状态：队列深度、等待时间、堆积告警
- 会话管理：会话总数、卡死会话、异常会话检测
- 资源趋势：上下文大小变化、各节点资源占用

## Related

- [[entities/openclaw]] — OpenClaw 平台
- [[concepts/genai-observability-semconv]] — OpenTelemetry GenAI 语义规范
- [[references/2026-03-26-tencent-cloud-openclaw-observability]] — 接入实践来源