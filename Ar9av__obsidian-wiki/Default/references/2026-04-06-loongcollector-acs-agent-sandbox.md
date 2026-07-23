---
title: "LoongCollector + ACS Agent Sandbox：构建 AI Agent 生产级运行平台"
category: references
tags: [observability, security, alibaba, loongcollector, sandbox]
sources:
  - "阿里云可观测: LoongCollector + ACS Agent Sandbox：构建 AI Agent 生产级运行平台 (2026-04-06)"
summary: 阿里云介绍 ACS Agent Sandbox 与 LoongCollector 深度集成，为 OpenClaw 等 AI Agent 提供运行时安全隔离与全栈可观测能力。
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
  - target: "[[entities/acs-agent-sandbox]]"
    type: describes
---

# LoongCollector + ACS Agent Sandbox：构建 AI Agent 生产级运行平台

阿里云可观测团队阐述 AI Agent 生产化面临的运行时安全与全链路可观测挑战，以及 ACS Agent Sandbox + LoongCollector 的完整解决方案。

## AI Agent 的两大新特点

- **行为不可预测**：同样输入可能产生不同输出，调用不同工具链路
- **具备执行能力**：Agent 能访问数据、调用 API、执行操作

## 核心挑战

### 运行时安全

1. **执行环境缺少强隔离**：Prompt 注入或误触发可能导致越权访问、数据泄露
2. **外部能力缺少管控**：工具被滥用可能导致 SSRF、内网探测、敏感数据外传

### 全链路可观测

1. **行为难以复现和定位**：同一问题不同时间可能调用不同工具
2. **成本难以控制和归因**：LLM Token 与外部 API 调用波动巨大
3. **质量难以度量和优化**：输出受模型、Prompt、检索数据等多因素影响

## ACS Agent Sandbox

阿里云容器服务推出的 AI Agent 运行沙箱环境，基于 Kubernetes 提供**安全、隔离、可扩展**的运行平台。

## LoongCollector 能力

阿里云开源的统一可观测数据采集器，在 AI Agent 场景的优势：

- **极致性能与低开销**：零拷贝架构、事件池化复用、单核 500MB/s 日志采集吞吐
- **一体化采集**：日志 / 指标 / 链路全覆盖，支持 stdout、Prometheus Exporter、OpenTelemetry
- **端侧计算**：C++ 插件 / SPL 引擎支持过滤、转换、聚合
- **企业级可靠性**：At-Least-Once 投递、本地磁盘缓存、自动重试、反压限流
- **大规模弹性场景统一管控**：ConfigServer 集中管理、远程配置下发

## OpenClaw 部署方案

- 在 ACK/ACS 集群安装 LoongCollector、Virtual Node、ack-agent-sandbox-controller 等组件
- 开启 OpenClaw 的 `diagnostics-otel` 插件
- 通过 Sandbox CR 创建 OpenClaw 沙箱
- 配置 Session 日志、应用日志、OpenTelemetry 三类采集 Pipeline

## Related

- [[entities/acs-agent-sandbox]] — ACS Agent Sandbox 详解
- [[entities/loongsuite-platform]] — LoongSuite / LoongCollector 产品体系
- [[entities/openclaw]] — OpenClaw 平台与安全危机
- [[skills/openclaw-observability-setup-tencent-cloud]] — OpenClaw 可观测接入实践