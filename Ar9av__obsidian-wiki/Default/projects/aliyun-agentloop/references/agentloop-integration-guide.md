---
title: "AgentLoop 集成指南"
category: references
tags:
  - integration-guide
  - agent-framework
  - alicloud
  - agentloop
  - quickstart
relationships:
  - target: "[[projects/aliyun-agentloop/agentloop]]"
    type: related_to
created: 2026-07-24
updated: 2026-07-24
sources:
  - type: "official-docs"
    url: "https://help.aliyun.com/zh/document_detail/3033823.html"
    count: 12
summary: >
  AgentLoop 支持 8+ 种 Agent 框架和应用类型的接入，包括 AgentScope、Dify、Hermes Agent、LangChain/LangGraph、OpenClaw、AI Coding Agent（Cursor/Claude Code/Codex/Qoder）及通用 AI Agent 接入。提供 QuickStart 全流程实践指南。
provenance: "Consolidated from 12 Alibaba Cloud AgentLoop integration documentation pages: QuickStart guide + 6 framework-specific integration guides + AI Coding Agent integration (including LoongSuite Pilot) + general AI Agent integration via skill-based workflow."
---

# AgentLoop 集成指南

[[projects/aliyun-agentloop/agentloop|AgentLoop]] 支持多种 Agent 框架和应用类型的接入，覆盖服务端 Agent 应用和端侧 AI Coding Agent。

## 快速入门（QuickStart）

首次使用 AgentLoop 的完整实操路径，按以下 7 步完成从零到一的闭环：

### 前置条件
1. 注册并实名认证阿里云账号
2. 开通 **云监控 2.0**、**SLS 日志服务**、**MSE 微服务引擎（AI 治理中心）**、**AgentLoop**
3. RAM 用户被授予 `AliyunAgentLoopFullAccess` 系统策略
4. 为 RAM 用户创建 AccessKey

### 操作流程

| 步骤 | 操作 | 说明 |
|------|------|------|
| 1 | **创建智能体空间** | 在 [AgentLoop 控制台](https://agentloop.console.aliyun.com/) 创建 AgentSpace，选择地域（cn-hangzhou/cn-shanghai/cn-hongkong），名称全局唯一且不可更换 |
| 2 | **接入观测数据** | 选择对应框架的接入方式（见下方框架接入章节），完成 Agent 应用接入 |
| 3 | **构建评估器** | 创建评估器（支持 LLM-as-Judge / Agent-as-Judge），定义评分维度和标准 |
| 4 | **创建评估任务** | 基于 Pipeline 产出的 Dataset 创建评估任务，选择评估器，配置执行参数 |
| 5 | **导入与标注数据集** | 从 Trajectory 导入数据，进行人工标注或使用 Trace2Dataset 自动构建 |
| 6 | **管理 Agent 资产** | 管理 Prompts 和 Skills，建立版本控制和变更追踪 |
| 7 | **使用记忆库** | 配置上下文库（Context Store）和经验库，让 Agent 从历史经验中学习 |

完成全部步骤后，AgentLoop 的自进化闭环即开始运转：观测数据 → Trajectory → Dataset → 评估 → 优化 → 更高质量的观测数据。

---

## 框架接入指南

### 1. 接入 AgentScope（Python）

AgentScope 是阿里通义实验室开源的 Multi-Agent 开发框架。接入方式：

- 使用 AgentScope 内置的回调机制记录 Agent 执行事件
- 通过 LoongCollector 的 Python Agent 探针自动采集 LLM 调用数据
- 配置 OpenTelemetry Exporter 将 Trace 数据发送至 AgentLoop

### 2. 接入 Dify

[[entities/dify|Dify]] 是开源 LLMOps 平台。接入方式：

- 利用 Dify 的 OpsTrace 事件机制
- 配置 OpenTelemetry Collector 转发 Trace 至 AgentLoop
- 自动捕获 Workflow/Agent 执行过程中的 LLM 调用、工具调用、知识库检索等关键节点
- 支持 Dify 的可视化编排 Workflow 和 Chatflow 两种模式

### 3. 接入 Hermes Agent

接入方式：

- 在 Hermes Agent 配置中添加 AgentLoop SDK 或 OTel Exporter
- 自动采集 Agent 的推理链、工具调用、记忆操作等执行轨迹
- 支持 Session 级别的上下文追踪

### 4. 接入 LangChain & LangGraph

[[entities/langfuse-llm-observability|LangChain/LangGraph]] 是主流 LLM 应用框架。接入方式：

- 通过 LangChain Callback 机制自动插桩
- 使用 loongsuite-util-genai Python 组件辅助采集
- 自动捕获 Chain/Agent/Tool 各级 Span，支持嵌套 Trace 结构
- LangGraph 的 StateGraph 状态流转也可被完整记录

### 5. 接入 OpenClaw

[[entities/openclaw|OpenClaw]] 是多 Channel AI Agent 平台。接入方式：

- 通过 OpenClaw 内置的 diagnostics-otel 插件上报 OTel 数据
- 结合 LoongCollector 探针实现全栈采集
- 覆盖 Multi-Agent 间调用、工具链执行、Channel 交互等完整链路

### 6. AI Coding Agent 接入（LoongSuite Pilot）

专为运行在开发者本地机器上的 AI Coding Agent（Cursor、Claude Code、Codex、Qoder 等）设计，通过 [[entities/loongsuite-pilot|LoongSuite Pilot]] 采集器上报数据：

- **LoongSuite Pilot** 是阿里云 2026 年 6 月开源的端侧采集器，统一采集本地 Agent 的行为数据
- 安装方式：一键安装脚本，无需修改 Agent 代码
- 采集内容：Agent 对话记录、工具调用（文件读写、Shell 执行、API 调用）、Token 消耗、模型推理过程
- 数据传输：加密上报至 AgentLoop，支持离线缓存重传
- 版本要求：参见 [LoongSuite Pilot 版本说明](https://help.aliyun.com/zh/document_detail/3033878.html)

### 7. 通过 AI Agent 自动化接入

AgentLoop 提供 `alibabacloud-agentloop-management` Skill，将接入流程封装为结构化工作流：

- **适用 Agent**: QoderWork、Cursor、Claude Code
- **工作方式**: 安装 Skill → 自然语言描述接入需求 → Agent 自动编排并执行全流程
- **底层实现**: 调用 AgentLoop CLI 与标准探针方案（ack-onepilot、AliyunJavaAgent、aliyun-bootstrap、instgo、OpenTelemetry 等）
- **接入后效果**: 自动完成 Workspace 配置、APM 初始化、服务注册和探针注入

---

## 控制台内嵌分享

AgentLoop 支持将控制台页面内嵌到第三方应用中（见 [实践教程](https://help.aliyun.com/zh/document_detail/3046111.html)）：

- 通过 URL 参数控制内嵌页面的显示范围
- 支持隐藏导航栏、侧边栏等 UI 元素
- 可用于构建自定义运维 Dashboard

---

## 安全合规

- **RAM 权限**: 所有 API 调用需通过 RAM 鉴权，支持资源级权限控制（`AliyunAgentLoopFullAccess` 或自定义策略）
- **数据加密**: API 通信使用 HTTPS，存储数据使用阿里云 KMS 加密
- **审计日志**: 所有 API 操作记录在阿里云操作审计（ActionTrail）中
- **服务等级协议**: AgentLoop 提供服务等级协议（SLA），详见 [服务支持文档](https://help.aliyun.com/zh/document_detail/3044490.html)
