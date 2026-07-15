---
title: "Alibaba Cloud LoongCollector and ACS Agent Sandbox"
category: references
tags:
  - ai-agent
  - observability
  - alibaba-cloud
  - production-platform
  - agent-sandbox
sources:
  - "阿里云可观测: LoongCollector + ACS Agent Sandbox：构建 AI Agent 生产级运行平台 (2026-04-06)"
  - "阿里云可观测: 重磅发布丨云监控 AI Agent 可观测，企业生产级 Agent 首选全域观测平台 (2026-06-01)"
  - "阿里云可观测: AI 原生应用全栈可观测实践：以 DeepSeek 对话机器人为例"
summary: "阿里云 ARMS AI 可观测方案：LoongCollector 实现全栈数据采集（业务/应用/模型层）、ACS Agent Sandbox 提供安全隔离的 Agent 执行环境，构成生产级 Agent 运行与观测一体化平台。"
base_confidence: 0.53
lifecycle: draft
lifecycle_changed: "2026-07-16"
tier: supporting
provenance:
  extracted: 0.4
  inferred: 0.5
  ambiguous: 0.1
created: 2026-07-16
updated: 2026-07-16
---

# Alibaba Cloud LoongCollector and ACS Agent Sandbox

阿里云的 AI Agent 可观测方案由两个核心组件构成 ^[extracted]：

## LoongCollector（数据采集引擎）

LoongCollector 是阿里云 ARMS 旗下的全栈数据采集器，专为 AI 应用场景优化：

- **全栈覆盖**：从基础设施（容器、网络）到应用层（API 调用）再到 AI 模型层（Prompt、Token、Tool Call），实现贯穿式采集
- **零代码改造**：通过自动插桩和 Agent 注入，无需修改业务代码即可采集 AI 应用的观测数据
- **GenAI 语义规范**：基于 OpenTelemetry 扩展了 AI 场景的语义约定，统一了 Prompt、模型调用、工具调用等数据模型 ^[inferred]
- **多后端导出**：支持导出到 ARMS、Prometheus、Jaeger 等多种后端

## ACS Agent Sandbox（安全执行环境）

ACS（Alibaba Cloud Sandbox）Agent Sandbox 提供了 AI Agent 的生产级运行环境：

- **安全隔离**：每个 Agent 实例运行在独立沙箱中，防止工具调用对宿主机的影响
- **资源管控**：CPU、内存、网络的配额和限流
- **可观测内建**：Sandbox 内置了 Agent 行为记录，与 LoongCollector 集成，自动采集 Agent 运行时的完整轨迹
- **企业级特性**：与阿里云 IAM、审计日志、合规体系集成

## 阿里云 ARMS AI 可观测

2026 年 6 月，阿里云发布了云监控 AI Agent 可观测能力，定位为企业生产级 Agent 的首选全域观测平台。核心特性 ^[extracted]：

- **全链路追踪**：从用户请求 → Agent 推理 → 工具调用 → 模型响应 → 用户反馈，端到端可见
- **质量评估**：内置 LLM-as-Judge 评估引擎，支持自动化质量评分
- **成本分析**：Token 消耗、工具调用费用的精细化统计
- **安全监控**：Prompt 注入检测、越狱尝试告警
- **企业级集成**：与阿里云生态（RAM、SLS、ARMS）原生集成

## DeepSeek 对话机器人案例

阿里云以 DeepSeek 对话机器人为例，展示了全栈可观测实践的完整链路：前端请求 → 后端 Agent 服务 → DeepSeek API → ARMS 全链路追踪。详见来源文档。

## 相关页面

- [[agent-observability-fundamentals]] — Agent 可观测性概念
- [[opentelemetry-genai-agent-setup]] — OpenTelemetry 标准方案
- [[ai-production-engineering-five-pillars]] — 运行工程化框架
- [[stepfun-selectdb-pb-observability]] — SelectDB 在生产可观测中的实践
