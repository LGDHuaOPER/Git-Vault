---
title: UModel
category: concepts
tags: [observability, modeling, alibaba, agent, topology]
sources:
  - "阿里云可观测: 重磅发布丨云监控 AI Agent 可观测，企业生产级 Agent 首选全域观测平台 (2026-06-01)"
summary: 阿里云云监控 AI Agent 可观测产品的统一建模体系，将基础设施、AI 服务、AI 资产等实体默认关联，实现全域数据无缝关联。
provenance:
  extracted: 0.68
  inferred: 0.27
  ambiguous: 0.05
base_confidence: 0.44
lifecycle: draft
lifecycle_changed: 2026-07-22
tier: supporting
created: 2026-07-22T00:00:00+08:00
updated: 2026-07-22T00:00:00+08:00
relationships:
  - target: "[[concepts/ai-agent-observability]]"
    type: implements
  - target: "[[entities/alicloud-cloudmonitor-ai-agent-observability]]"
    type: related_to
---

# UModel

**UModel** 是阿里云云监控 AI Agent 可观测产品中的**统一建模体系**，用于将基础设施、AI 服务、AI 资产等全域实体进行统一建模，并默认关联，实现从 GPU 到 Agent 的全栈观测对象和数据的一次查询即可获取关联上下文。

## 建模范围

UModel 将以下实体纳入统一建模：

- **基础设施**：GPU、ACK/ECS/FC 等计算资源
- **AI 服务**：推理服务、训练任务、SandBox 等运行环境
- **AI 资产**：模型、AI Agent、AI 应用、工具、数据集等

## 核心作用

- **全域数据默认关联**：无需用户手动拼接数据，一次查询即可获取从基础设施到 Agent 决策的完整上下文
- **实体拓扑构建**：支撑全景拓扑视图，实时展示 AI 应用、AI Agent、模型、工具等实体的全局关系
- **智能根因分析**：为 AI 辅助的根因定位提供跨层关联数据基础

## 在 AI Agent 可观测中的位置

UModel 位于阿里云云监控 AI Agent 可观测产品的**数据层**，上承接入层采集的 Trace/Metric/Log，下启分析层的全景拓扑、链路追踪、会话分析、指标大盘、智能告警五大模块。

## Related

- [[entities/alicloud-cloudmonitor-ai-agent-observability]] — 云监控 AI Agent 可观测产品
- [[concepts/ai-agent-observability]] — Agent 可观测性范式
- [[references/2026-06-01-cloudmonitor-ai-agent-observability]] — 产品发布来源