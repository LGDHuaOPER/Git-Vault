---
title: "Agent 观测与优化 AgentLoop"
category: projects
tags:
  - ai-agent-observability
  - alicloud
  - agent-evaluation
  - agent-audit
  - agentops
created: 2026-07-24
updated: 2026-07-24
sources:
  - type: "official-docs"
    url: "https://help.aliyun.com/zh/product/3033820.html"
    count: 129
summary: >
  AgentLoop 是阿里云面向企业级智能体的一站式自进化平台，提供 Agent 全栈观测与审计、评估与实验、资产管理与持续优化三大核心能力，构建可观测→可评估→可优化的持续进化飞轮。产品覆盖 7 大 API 域（75+ 端点）、8 种 Agent 框架接入、LLM Trace 语义规范和 RAM 权限体系。
provenance: "Consolidated from 129 Alibaba Cloud official documentation pages covering product overview, API reference (75+ endpoints across 7 domains), integration guides (8+ frameworks), product feature guides, and support documentation."
---

# Agent 观测与优化 AgentLoop

AgentLoop 是阿里云推出的面向企业级智能体的一站式自进化平台。它围绕**数据飞轮**（Data Flywheel）构建产品能力——Agent 在线上运行时持续产生 Trace、对话和日志数据，经过 Pipeline 清洗为结构化调用轨迹（Trajectory），沉淀为数据集和经验资产，反向驱动评估、实验和优化，形成正向增强循环。

## 产品定位

区别于传统 LLMOps 工具仅提供 LLM-as-a-Judge、Playground 等单点功能，AgentLoop 面向**企业真实生产环境 Agent 应用**，提供 Agent-as-a-Judge、Agent Playground、Trace2Dataset 等 Agent 应用范式的场景化闭环能力。

解决四大核心挑战：
- **质量退化难感知** — Agent 多步推理输出质量下降，故障定位平均超 2 小时
- **成本暴涨难归因** — Token 异常消耗可达平峰期 10 倍以上
- **变更风险难拦截** — Prompt/Skill/模型变更缺乏自动化质量门禁
- **行为审计无留痕** — Agent 多步执行轨迹缺乏审计与回放能力

## 核心架构

AgentLoop 由以下核心模块构成：

| 模块 | 说明 | 参考页 |
|------|------|--------|
| **Agent 可观测** | 全链路 Trace、会话分析、全景拓扑、链路追踪、Token 成本治理 | [[projects/aliyun-agentloop/references/agentloop-product-features|产品功能]] |
| **Agent 审计** | 风险检测、实体调查、审计事实回放、敏感数据泄漏检测 | [[projects/aliyun-agentloop/references/agentloop-product-features|产品功能]] |
| **评估 & 实验** | Agent-as-a-Judge 评估器、评估任务 Pipeline、离线/在线实验 | [[projects/aliyun-agentloop/references/agentloop-product-features|产品功能]] |
| **数据处理 Pipeline** | Trace 清洗、轨迹生成、数据标注与回流 | [[projects/aliyun-agentloop/references/agentloop-api-reference|API 参考]] |
| **Agent 资产** | Prompts 管理、Skills 管理、上下文库（Context Store）、经验库 | [[projects/aliyun-agentloop/references/agentloop-product-features|产品功能]] |
| **接入中心** | 8 种框架接入 + AI Agent 自动化接入 | [[projects/aliyun-agentloop/references/agentloop-integration-guide|集成指南]] |

## 关键实体

- **AgentSpace** — 顶层工作空间，对应团队/业务线的资源隔离边界，与云监控 2.0 工作空间、MSE AI 治理中心命名空间、SLS Project 一一绑定
- **Agent 应用** — 已接入 AgentLoop 进行观测、评估和优化的具体实例，背后可能包含多个协作 Agent
- **Pipeline** — 数据清洗流水线，将原始 Trace 转化为结构化 Trajectory 并写入数据集
- **Trajectory** — 一次 Agent 请求从接收到完成的完整执行轨迹，含输入/输出、模型推理、工具调用、检索增强等全部步骤
- **Dataset** — 从 Trajectory 加工而成的结构化数据资产，用于评估和实验
- **Evaluator** — 评估器，支持 LLM-as-Judge 和 Agent-as-Judge 两种模式
- **ExperimentPlan** — 实验计划，定义离线/在线实验的配置（数据源、评估器、实验分组）

## 技术规格

- **API 版本**: `AgentLoop/2026-05-20`
- **签名风格**: ROA
- **可用地域**: cn-hangzhou, cn-shanghai, cn-hongkong
- **服务接入点**: `agentloop.cn-hangzhou.aliyuncs.com`（及其他地域对应域名）
- **计费方式**: 按量付费（AI 积分 0.01 元/积分 + 数据集存储 0.00004 元/条/天 + 执行次数 0.001 元/次）
- **RAM 权限**: `AliyunAgentLoopFullAccess` 系统策略，支持资源级授权

## 与现有 Wiki 知识的关联

AgentLoop 是阿里云 AI Agent 可观测生态的核心产品，与以下现有知识紧密关联：

- [[entities/alicloud-cloudmonitor-ai-agent-observability]] — AgentLoop 是云监控 2.0 的 AI Agent 可观测子产品
- [[entities/loongsuite-platform]] — LoongCollector/LoongSuite Pilot 是 AgentLoop 的数据采集层
- [[entities/loongsuite-pilot]] — 端侧 AI Coding Agent 采集器，通过 AgentLoop 的 AI Coding Agent 接入路径上报数据
- [[concepts/ai-agent-observability]] — AgentLoop 实现了 AI Agent 可观测性的完整能力体系
- [[concepts/agent-data-flywheel]] — AgentLoop 的核心运作机制就是数据飞轮
- [[concepts/agent-evaluation-framework]] — AgentLoop 的评估模块实现了评估流水线的工程化落地
- [[concepts/agent-trace-and-timeline]] — AgentLoop 的 Trajectory 概念是 Trace 的高层抽象
- [[concepts/genai-observability-semconv]] — AgentLoop 的 LLM Trace 字段基于 OTel GenAI SemConv 扩展
- [[entities/dify]] — AgentLoop 支持 Dify 应用接入
- [[entities/openclaw]] — AgentLoop 支持 OpenClaw 应用接入

## 详细参考

- [[projects/aliyun-agentloop/references/agentloop-api-reference|API 参考]] — 75+ REST API 端点完整参考（7 大领域）
- [[projects/aliyun-agentloop/references/agentloop-integration-guide|集成指南]] — 8 种框架接入 + QuickStart 全流程
- [[projects/aliyun-agentloop/references/agentloop-product-features|产品功能]] — 可观测、审计、评估、实验、资产管理等功能详解
