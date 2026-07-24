---
title: Alibaba Cloud CloudMonitor AI Agent Observability
category: entities
tags: [observability, alibaba, cloudmonitor, agent, production]
sources:
  - "阿里云云原生: 重磅发布丨云监控 AI Agent 可观测，企业生产级 Agent 首选全域观测平台 (2026-05-31)"
  - "阿里云可观测: 重磅发布丨云监控 AI Agent 可观测，企业生产级 Agent 首选全域观测平台 (2026-06-01)"
  - "阿里云可观测: 零代码改造！LoongSuite AI 采集套件观测实战 (2025-09-01)"
summary: 阿里云云监控 2026 年发布的 AI Agent 可观测产品，定位为企业生产级 Agent 首选全域观测平台，采用四层架构覆盖接入/数据/分析/应用。
provenance:
  extracted: 0.71
  inferred: 0.24
  ambiguous: 0.05
base_confidence: 0.65
lifecycle: draft
lifecycle_changed: 2026-07-22
tier: supporting
created: 2026-07-22T00:00:00+08:00
updated: 2026-07-24T00:00:00+08:00
relationships:
  - target: "[[entities/loongsuite-platform]]"
    type: uses
  - target: "[[concepts/umodel]]"
    type: uses
  - target: "[[concepts/ai-agent-observability]]"
    type: implements
---

# Alibaba Cloud CloudMonitor AI Agent Observability

阿里云云监控于 2026 年 6 月正式发布 **AI Agent 可观测**产品，定位为企业生产级 Agent 首选全域观测平台。该产品基于 [[entities/loongsuite-platform|LoongSuite]] 技术栈，采用接入层、数据层、分析层、应用层四层架构。

## 四层架构

| 层级 | 能力 |
|---|---|
| 接入层 | 多语言自研探针（Python/Node.js/Golang/Java），支持 LangChain/LangGraph/AgentScope/Dify/OpenClaw/Hermes/QoderWork/Claude Code/Codex 等 20+ 框架；兼容 OpenTelemetry GenAI 语义规范；提供 GenAI Utils 自定义 SDK |
| 数据层 | 基于 [[concepts/umodel|UModel]] 统一建模体系，将基础设施、AI 服务、AI 资产默认关联；完整存储推理过程数据，支持多模态原生预览 |
| 分析层 | 全景拓扑、链路追踪、会话分析、指标大盘、智能告警五大模块 |
| 应用层 | Agentic 化，提供与控制台对等的 CLI/Skills 接口，支持 AI Agent 直接调用可观测能力 |

## 核心能力

- **全场景接入**：自研探针、自定义 SDK、OTel 兼容三种模式
- **全局总览大盘**：会话、Token、模型性能、Agent 调用、框架分布
- **拓扑与健康度**：实时展示 AI 应用/Agent/模型/工具关系；主动式健康巡检
- **全链路追踪**：轨迹回溯、工作流路径图、推理过程还原、多模态预览、评估关联、链路转数据集
- **会话分析**：USER→SESSION→TRACE 三层聚合，还原多轮对话
- **场景化分析**：Token 用量、模型性能（RED/TTFT/TPOT）、工具调用、RAG 调用
- **智能告警与根因定位**：AI 智能分析，支持多轮追问
- **Agentic Ops**：能力全开放、全域数据关联、全链路 AI 辅助

## 典型落地场景

1. **Token 成本治理**：多维度追踪消耗，AI 辅助定位高消耗链路
2. **故障根因快速定位**：告警 → 健康度下钻 → 链路聚焦 → AI 根因报告 → 转数据集优化
3. **数据驱动的 Agent 持续优化**：观测 → 评估 → 筛选 → 回灌闭环

## 故障定位时间线

云监控 AI Agent 可观测产品提供了精确到秒的故障定位流水线 ^[extracted]：

| 时间 | 动作 | 说明 |
|------|------|------|
| T+0s | 异常告警触发 | 基于指标阈值（Token 消耗异常、错误率飙升）或健康度巡检自动触发 |
| T+10s | 健康度大盘下钻 | 定位异常 Agent 节点，展示上下游影响面，红绿灯状态一目了然 |
| T+30s | 链路追踪聚焦 | 聚焦失败路径，通过工作流图展示完整决策环节（Plan → Act → Observe → Reflect）|
| T+60s | AI 智能根因分析 | 综合推理过程数据和调用上下文，自动生成根因分析报告 |
| T+90s | 一键转数据集 | 将故障链路数据一键转为评估数据集，用于后续 Prompt/模型优化 |

> 故障定位流水线是 [[concepts/observability-1-5-10-framework|1-5-10 框架]] 在产品层面的具体落地实现——目标是在 90 秒内完成从发现到可复盘的完整闭环。^[inferred]

## 主动式健康巡检

区别于传统被动等待告警的模式，云监控提供主动式健康检查机制 ^[extracted]：

- **内置巡检规则 + 自定义告警规则**：按需开启，以"红绿灯"方式直观呈现实时健康状态
- **异常详情**：健康度详情页展示具体异常事件和上下游影响面
- **AI 智能分析**：自动生成健康巡检报告，支持异常归因
- **多渠道通知**：通过 IM、电话等多种渠道订阅健康事件，第一时间收到风险通知

## 接入模式

支持三种接入模式 ^[extracted]：
- **零代码探针**：pip install + Dockerfile 注入，针对 Python/Node.js/Golang/Java 主流语言
- **自定义 SDK**：通过 GenAI Utils SDK 自定义采集
- **OTel 兼容**：直接对接 OpenTelemetry 标准协议，兼容已有的 OTel Collector 基础设施

## Related

- [[entities/loongsuite-platform]] — LoongSuite 技术栈
- [[concepts/umodel]] — UModel 统一建模体系
- [[concepts/ai-agent-observability]] — Agent 可观测性范式
- [[concepts/observability-1-5-10-framework]] — 1-5-10 可观测框架
- [[references/2026-06-01-cloudmonitor-ai-agent-observability]] — 产品发布来源