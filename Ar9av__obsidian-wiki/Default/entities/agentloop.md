---
title: "AgentLoop — 阿里云 Agent 自进化平台"
category: entities
tags:
  - ai-agent
  - observability
  - evaluation
  - alibaba
  - agent-platform
sources:
  - "阿里云: Agent 观测与优化 AgentLoop - 智能体自进化平台产品页 (2026-07-23)"
  - "阿里云: AgentLoop 官方文档 - 什么是 AgentLoop (2026-06-22)"
  - "阿里云: AgentLoop 官方文档 - 核心概念 (2026-06-18)"
  - "阿里云: AgentLoop 官方文档 - 计费说明 (2026-07-03)"
  - "阿里云: AgentLoop 官方文档 - 开服地域"
  - "阿里云: AgentLoop 官方文档 - RAM权限策略参考 (2026-07-10)"
  - "阿里云: AgentLoop 官方文档 - 控制台内嵌分享接入指南 (2026-06-18)"
  - "阿里云: AgentLoop 官方文档 - API概览 (2026-07-23)"
  - "阿里云: AgentLoop 官方文档 - 服务接入点 (2026-07-09)"
summary: AgentLoop 是阿里云推出的面向企业级智能体的一站式自进化平台，提供 Agent 全栈观测与审计、Agent-as-a-Judge 评估、Trace2Dataset 数据飞轮、资产管理与持续优化等核心能力，兼容主流 Agent 框架和运行时。
base_confidence: 0.90
lifecycle: draft
lifecycle_changed: "2026-07-25"
tier: core
provenance:
  extracted: 0.92
  inferred: 0.06
  ambiguous: 0.02
created: "2026-07-25"
updated: "2026-07-25"
relationships:
  - target: "[[entities/alicloud-cloudmonitor-ai-agent-observability]]"
    type: related_to
  - target: "[[concepts/ai-agent-observability]]"
    type: extends
  - target: "[[concepts/agent-data-flywheel]]"
    type: implements
  - target: "[[concepts/agent-evaluation-framework]]"
    type: implements
  - target: "[[concepts/agent-trace-and-timeline]]"
    type: uses
  - target: "[[entities/langfuse-llm-observability]]"
    type: related_to
  - target: "[[entities/loongsuite-platform]]"
    type: related_to
  - target: "[[concepts/agent-cost-breakdown]]"
    type: related_to
  - target: "[[concepts/umodel]]"
    type: uses
  - target: "[[entities/dify]]"
    type: related_to
  - target: "[[entities/openclaw]]"
    type: related_to
---

# AgentLoop — 阿里云 Agent 自进化平台

AgentLoop（Agent 观测与优化 AgentLoop）是阿里云推出的面向企业级智能体的一站式自进化平台，提供 Agent 全栈观测与审计、Agent 评估与实验、Agent 资产管理与持续优化等核心能力。不同于传统 LLMOps 工具仅面向单次 LLM 调用，AgentLoop 以 Agent 完整执行轨迹（Trajectory）为核心对象，覆盖从规划到执行再到反馈的全过程。^[extracted]

## 为什么需要 AgentLoop

当企业从 LLM 应用迈入 Agent 应用阶段，传统 APM 和 LLMOps 工具集体失灵。Agent 的多步推理、工具调用、多模型协作带来四大核心挑战 ^[extracted]：

| 挑战 | 具体表现 |
|------|---------|
| **质量退化难感知** | Agent 多步推理输出质量下降，故障定位平均超 2 小时，只能被动等工单和客诉 |
| **成本暴涨难归因** | Token 异常消耗可达平峰期 10 倍以上，缺乏精细归因手段 |
| **变更风险难拦截** | Prompt/Skill/模型变更缺乏自动化质量门禁，大部分故障本可拦截却被放过至线上 |
| **行为审计无留痕** | Agent 多步执行轨迹缺乏审计与回放能力，难以满足强合规行业需求 |

^[extracted]

## 核心设计理念

1. **面向 Agent 而非 LLM 设计** — 以 Agent 完整执行轨迹为核心对象，覆盖多步推理、动态规划和工具编排 ^[extracted]
2. **企业级生产场景闭环** — 从数据采集、质量评估到持续优化，每个环节为企业生产环境量身设计 ^[extracted]
3. **核心能力 Agentic 化** — 评估器等核心组件自身即 Agent，支持通过 Prompt/Skill/Tool 灵活扩展（如 Agent-as-a-Judge）^[extracted]
4. **全面兼容主流框架与运行时** — 不绑定特定框架，兼容 [[entities/dify|Dify]]、LangChain/LangGraph、AgentScope、[[entities/openclaw]]、Hermes 等，以及 Qoder/Claude Code/Codex/Cursor 等 CLI ^[extracted]

## 核心概念

### 数据飞轮

AgentLoop 的核心运作机制。Agent 线上运行时持续产生 Trace，经 Pipeline 清洗为 Trajectory，沉淀为数据集（Dataset）和经验（Experience），反过来驱动评估、实验、检测与优化，形成正向增强循环。关键：**数据一次采集，在观测、审计、评估、优化四场景中复用，价值随时间持续增长**。^[extracted]

### AgentSpace

组织和管理资源的顶层工作空间，对应一个团队、业务线或独立项目的完整资源边界。一个 AgentSpace 包含 Agent 应用、数据集、评估任务、实验计划、记忆库和经验库等全部资源，是企业级多租户治理的基本单元。单账号最多 50 个 AgentSpace。^[extracted]

### Trajectory（调用轨迹）

记录一次 Agent 请求从接收到完成的完整执行轨迹，包含用户输入、模型推理、工具调用、检索增强、记忆读取、决策分支与最终回复等全部步骤，以及每步的耗时、Token 消耗和状态信息。Trajectory 是数据飞轮的基础数据单元。^[extracted]

### Dataset（数据集）

管理 Agent 运行时数据的核心载体，支持自定义 Schema（text/long/double/json）、版本管理、全文检索、语义搜索和 SQL 分析。承担评估输入数据来源、实验对比测试集、CI/CD 门禁回归基准集等多重角色。^[extracted]

### Pipeline（数据处理引擎）

自动化数据加工引擎，将原始运行数据转化为 Trajectory 或高质量数据集。典型链路：数据源接入 → 数据降维（过滤/去重/采样）→ 特征提取 → AI 数据加工 → 写入目标存储。可节省 90% 以上人工数据处理成本。^[extracted]

### Memory（记忆库）

为 Agent 提供的长期上下文管理能力，支持四种策略类型 ^[extracted]：
- **事实记忆（Facts）** — 记录确定性信息
- **情节记忆（Episodic）** — 保存交互片段
- **摘要记忆（Summary）** — 压缩长期历史
- **自定义策略（Custom）** — 适配特殊场景

兼容 Mem0 API 协议，已有 Mem0 用户可无缝迁移。^[extracted]

### Experience（经验库）

从 Agent 执行轨迹中自动提取的可复用操作知识，记录某类任务中有效的处理方法、决策路径、成功模式或失败教训。与 Memory 关注"记住用户和环境信息"不同，Experience 关注"Agent 自身如何更好地完成任务"。支持组织级共享——多个 Agent 应用可共享同一经验库。^[extracted]

## 功能特性

### Agent 全栈观测

通过阿里云自研探针、开源探针及云产品深度集成，实现 Agent 端到端**无侵入采集**链路、指标和日志。基于 [[concepts/umodel|UModel]] 自动发现 Agent → Tool → Model 等上下游实体拓扑关系，结合 STAROps 智能诊断引擎快速定位性能瓶颈与 Token 消耗热点。Trace 记录一次请求的完整执行过程（用户输入、模型调用、工具调用、检索增强、记忆读取、最终回复）。^[extracted]

> AgentLoop 的观测粒度是 **Agent 级而非 LLM 级**——传统 LLMOps 工具止于单次模型调用，无法理解多步推理链路间的因果关系。^[extracted]

### Agent 行为审计

为 Agent 每一步工具调用和决策分支构建**不可篡改的执行轨迹证据链**。内置异常行为检测引擎，可实时识别越权操作、数据外发等风险模式，分钟级完成异常风险预警。^[extracted]

### Agent 评估（Agent-as-a-Judge）

引入 **Agent-as-a-Judge** 评估范式——评估器本身就是具备复杂任务规划、工具使用和多步推理能力的 Agent，基于完整 Trajectory 轨迹进行深度评估，相比 LLM-as-a-Judge 更接近人类专家真实评估效果 ^[extracted]。

- **评估对象**：模型输出、RAG 检索结果、工具调用、Agent 执行轨迹
- **评估器类型**：预置评估器（幻觉、正确性、任务完成度等）和自定义评估器
- **运行策略**：基于新数据的持续评估（实时监控）+ 基于历史数据的批次评估（离线回归）
- **评估结果用途**：发现 Bad Case、监控线上质量趋势、验证版本变更是否引入退化、与 CI/CD 集成自动化质量门禁 ^[extracted]

### Agent 实验

在受控条件下对比不同配置的效果差异。用户创建实验计划，选择目标数据集和评估器组合，定义多组实验变量（Agent 实例、模型版本、Prompt 版本、参数配置、工具配置等），批量运行后对比准确性、质量评分、延迟、Token 消耗和成本等维度。结果提供统计显著性分析。^[extracted]

配套 Playground 交互式实验环境，支持即时调整实验对象、实时查看输出并挂载评估器对比结果，适用于快速调试和验证。^[extracted]

### Agent 资产（Prompts & Skills）

为 Prompt 和 Skill 提供集中托管、版本控制和变更审计能力。每次变更可回溯，效果可通过关联评估量化对比，变更后可自动触发评估验证，确保不引入质量退化。支持灰度发布与多人协同编辑。^[extracted]

### Trace2Dataset 数据飞轮

Pipeline 引擎将线上 Trace 数据自动转化为结构化数据集。通过过滤、去重、采样、聚类等步骤，原始运行数据被持续加工为 Golden 数据集、Bad Case 数据集或后训练数据集，实现"数据越跑越多、质量越用越高"的飞轮效应 ^[extracted]。

## 应用场景

| 场景 | AgentLoop 解决方案 |
|------|-------------------|
| **智能客服质量提升** | 每轮对话质量评估，自动识别 Bad Case，高频问题沉淀为数据集定向优化，记忆库保持用户偏好连续性 |
| **Coding Agent 质量守护** | 完整执行轨迹观测与评估，覆盖任务规划合理性、工具调用准确性、代码产出正确性等维度 |
| **版本迭代质量门禁** | 基于历史数据集的 A/B 对比实验，量化新版本在准确性/延迟/成本等维度差异，建立自动化质量门禁 |
| **Agent 成本治理（FinOps）** | 精确追踪每个 Agent/工具/推理的 Token 消耗和耗时，识别成本热点，对比不同模型和配置的成本效率比 |
| **企业合规审计** | 完整证据链留痕，支持按时间/用户/Agent 应用维度审计回放，实时预警越权操作和敏感数据访问 |

^[extracted]

## 渐进式接入路径

AgentLoop 推荐四步渐进式接入 ^[extracted]：

1. **观测先行** — 通过自研探针完成 Agent 全链路数据接入，5 分钟内在控制台看到 Trace 数据
2. **数据资产化** — 利用 Pipeline 将线上 Trace 自动转化为结构化数据集，从被动积累日志转变为主动构建数据资产
3. **建立评估体系** — 从预置评估器起步，构建业务专属自定义评估器（Agent-as-a-Judge），结合人工反馈校准
4. **持续优化闭环** — 通过 Agent 资产调优、记忆库和经验库提升 Agent 长期表现，实现数据飞轮正循环

## 接入生态

AgentLoop 全面兼容以下 Agent 开发框架和运行时 ^[extracted]：

| 类别 | 支持列表 |
|------|---------|
| Agent 框架 | LangChain/LangGraph、AgentScope、Dify、OpenClaw、Hermes、LlamaIndex、Claude Agent SDK |
| Coding Agent/CLI | Qoder、Claude Code、Codex、Cursor |
| 阿里云运行时 | AgentRun、AgentTeams、ACS |
| 接入协议 | OpenTelemetry 标准协议、ARMS 自动探针、Python/Java SDK 手动埋点、MCP Server |

## 开服地域

截至 2026 年 6 月，AgentLoop 支持以下地域（AgentSpace 创建后不可更换）^[extracted]：

| 地域 | Region ID |
|------|-----------|
| 华东1（杭州） | cn-hangzhou |
| 华东2（上海） | cn-shanghai |
| 华北2（北京） | cn-beijing |
| 华北3（张家口） | cn-zhangjiakou |
| 华南1（深圳） | cn-shenzhen |
| 中国香港 | cn-hongkong |
| 新加坡 | ap-southeast-1 |

API 服务接入点：`agentloop.<region>.aliyuncs.com`（公网）/ `agentloop-vpc.<region>.aliyuncs.com`（VPC），支持 9 个地域（含华南3广州、西南1成都）。^[extracted]

## 计费

采用按量付费（后付费），按天结算。新用户首月享免费试用权益包 ^[extracted]：

| 计费项 | 单价 | 说明 |
|--------|------|------|
| **AI 积分** | 0.01 元/积分 | 一次评估约消耗 10 积分，一次实验约消耗 1 积分 |
| **数据集存储** | 0.00004 元/条/天 | 按存储条目数和天数计量 |
| **执行次数** | 0.001 元/次 | 评估、实验等数据样本执行次数 |

新用户免费额度（31 天有效）：10,000 AI 积分 + 31,000 条/天数据集存储 + 2,000 次执行。上下文工程模块（记忆库/经验库）当前公测阶段暂不计费。^[extracted]

关联产品独立收费：ARMS（Agent 可观测）、SLS（审计及评估/实验数据）、MSE（Agent 资产管理，公测暂不计费）。^[extracted]

## 控制台内嵌分享

AgentLoop 控制台支持以内嵌方式集成到第三方系统，使用 `agentloop4service.console.aliyun.com` 域名，通过 STS AssumeRole + GetSigninToken 生成免登录链接。支持 URL 参数控制：隐藏侧边栏（`embed={"sidebar":"hidden"}`）、禁止切换空间（`hiddenSwitch=true`）、禁止返回首页（`hiddenBackHome=true`）、预填评估参数（`embed.eval.*`），以及通过 `traceId` 直接打开 Trace 详情页。^[extracted]

## API

OpenAPI 采用 ROA 签名风格（版本 `AgentLoop/2026-05-20`），已封装多语言 SDK。API 分为以下模块 ^[extracted]：

| API 模块 | 核心能力 |
|----------|---------|
| **AgentSpace** | CRUD 管理智能体空间 |
| **Pipeline** | 流水线的创建、更新、预览、删除 |
| **Dataset** | 数据集的 CRUD 与 SQL 查询 |
| **Evaluation** | 评估任务、评估运行、评估器的 CRUD（含评估器 Skill） |
| **Experiment** | 实验计划与实验运行的 CRUD |
| **Region** | 查询可用地域 |

RAM 权限支持系统策略（AliyunAgentLoopFullAccess / AliyunAgentLoopReadOnlyAccess）和自定义细粒度权限策略，按读/写权限分类，支持 AgentLoop、SLS 日志、AI 治理中心 Prompt/Skill、云监控 2.0 等粒度控制。^[extracted]

## 使用限制

| 限制项 | 说明 |
|--------|------|
| AgentSpace 数量 | 单账号默认最多 50 个 |
| Trace 保留时长 | 默认 30 天，可按需调整 |
| 评估并发 | 单账号默认 100 |

^[extracted]

## 相关页面

- [[entities/alicloud-cloudmonitor-ai-agent-observability]] — 阿里云云监控 AI Agent 可观测产品（AgentLoop 的底层观测能力来源之一）
- [[concepts/ai-agent-observability]] — AI Agent 可观测性整体概念
- [[concepts/agent-data-flywheel]] — Agent 质量提升的数据飞轮模式
- [[concepts/agent-evaluation-framework]] — Agent 评测的完整方法论框架
- [[entities/langfuse-llm-observability]] — 开源 LLM 可观测平台（同赛道对比）
- [[entities/loongsuite-platform]] — 阿里云 LoongSuite 可观测采集体系（AgentLoop 的数据采集底座）
- [[concepts/agent-cost-breakdown]] — Agent 系统成本构成与治理
