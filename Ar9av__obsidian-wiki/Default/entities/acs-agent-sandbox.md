---
title: ACS Agent Sandbox
category: entities
tags: [security, sandbox, alibaba, kubernetes, agent]
sources:
  - "阿里云可观测: LoongCollector + ACS Agent Sandbox：构建 AI Agent 生产级运行平台 (2026-04-06)"
  - "阿里云可观测: 重磅发布丨云监控 AI Agent 可观测，企业生产级 Agent 首选全域观测平台 (2026-06-01)"
summary: 阿里云容器服务推出的 AI Agent 运行沙箱环境，基于 Kubernetes 提供安全、隔离、可扩展的 Agent 运行平台。
provenance:
  extracted: 0.71
  inferred: 0.24
  ambiguous: 0.05
base_confidence: 0.61
lifecycle: draft
lifecycle_changed: 2026-07-22
tier: supporting
created: 2026-07-22T00:00:00+08:00
updated: 2026-07-22T00:00:00+08:00
relationships:
  - target: "[[entities/loongsuite-platform]]"
    type: uses
  - target: "[[entities/openclaw]]"
    type: related_to
  - target: "[[concepts/ai-agent-observability]]"
    type: related_to
---

# ACS Agent Sandbox

**ACS Agent Sandbox** 是阿里云容器服务（Alibaba Cloud Container Service）推出的 AI Agent 运行沙箱环境，基于 Kubernetes 提供**安全、隔离、可扩展**的 Agent 运行平台，常与 [[entities/loongsuite-platform|LoongCollector]] 配合实现运行时可观测。

## 解决的问题

AI Agent 与传统应用有两个根本差异：

1. **行为不可预测**：相同输入可能产生不同输出，调用不同工具链路
2. **具备执行能力**：Agent 能访问数据、调用 API、执行操作

这两个特点带来运行时安全和全链路可观测两大挑战。

## 运行时安全保障

- **执行环境强隔离**：单 Sandbox 运行在独立内核沙箱环境，避免恶意代码攻击主机；独立隔离临时文件系统，避免读取/篡改/删除主机文件
- **外部能力管控**：限制 Agent 可调用的外部能力范围，防止异常外呼、SSRF、内网探测、敏感数据落盘或外传

## 与 LoongCollector 的集成

ACS Agent Sandbox 与 LoongCollector 深度集成：

- ACS 管控自动为 Sandbox 注入 LoongCollector 容器
- 通过挂载共享文件路径采集日志
- 通过 Pod 网络对 Agent 进行 Prometheus 抓取或接收 OpenTelemetry 数据

由此构建完整的 AI Agent 生产级运行平台。

## OpenClaw 部署示例

典型落地步骤：

1. 在 ACK/ACS 集群安装 LoongCollector、ACK Virtual Node、ack-agent-sandbox-controller 等组件
2. 开启 OpenClaw 的 `diagnostics-otel` 插件
3. 通过 Sandbox CR 创建 OpenClaw 沙箱
4. 配置 Session 日志、应用日志、OpenTelemetry 三类采集 Pipeline

## Related

- [[entities/loongsuite-platform]] — LoongSuite / LoongCollector 产品体系
- [[entities/openclaw]] — OpenClaw 平台
- [[references/2026-04-06-loongcollector-acs-agent-sandbox]] — 部署实践来源
- [[concepts/ai-agent-observability]] — Agent 可观测性范式