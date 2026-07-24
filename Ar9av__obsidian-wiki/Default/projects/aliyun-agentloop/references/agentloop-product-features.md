---
title: "AgentLoop 产品功能"
category: references
tags:
  - product-features
  - ai-agent-observability
  - agent-audit
  - agent-evaluation
  - alicloud
relationships:
  - target: "[[entities/agentloop]]"
    type: related_to
created: 2026-07-24
updated: 2026-07-24
sources:
  - type: "official-docs"
    url: "https://help.aliyun.com/zh/product/3033820.html"
    count: 52
summary: >
  AgentLoop 产品功能全景：AI Agent 可观测（会话分析/全景拓扑/链路追踪/场景化分析/总览）、AI Agent 审计（风险审计/实体调查/审计事实/审计规则）、评估与实验（评估器/评估任务/离线实验/在线实验）、Agent 资产（Prompts/Skills）、经验库、数据中心（数据标注/数据集）、系统管理与服务支持。
provenance: "Consolidated from 52 Alibaba Cloud AgentLoop product feature documentation pages: observability (12 pages), audit (8 pages), experiments (2 pages), data center (3 pages), Agent assets (3 pages), experience library (2 pages), evaluation (3 pages), system admin (1 page), agent space (1 page), support (4 pages), plus product overview and compliance docs."
---

# AgentLoop 产品功能

## 1. AI Agent 可观测

[[entities/agentloop|AgentLoop]] 的可观测模块提供从全局总览到单次会话细粒度分析的完整观测能力。

### 总览 Dashboard

全局视图，展示核心指标卡片和多维度统计表格：

| 核心指标 | 说明 |
|----------|------|
| 活跃会话数 | 统计时间范围内产生交互的会话总数（支持日同比） |
| 对话数 | 统计时间范围内的对话总轮次 |
| 活跃 Agent 数 | 有调用记录的 AI Agent 数量 |
| 活跃 AI 应用数 | 有调用记录的 AI 应用数量 |
| Token 消耗 | 所有请求消耗的 Token 总量（含输入和输出） |
| 平均 TTFT | Time To First Token，从发起到首 Token 的平均耗时 |

**模型调用统计**：展示各大模型的调用量、Token 消耗、错误数、平均 TTFT、P95 TTFT 等指标。

### AI Agent 列表 & AI 应用列表

提供 Agent 维度和应用维度的列表视图：

- **AI Agent 列表** — 展示所有已接入 Agent 的名称、类型、状态、接入时间
- **AI 应用列表** — 展示所有已接入 AI 应用的名称、框架、状态、最近活跃时间
- 支持按名称/状态筛选和排序

### AI Agent 详情页 & AI 应用详情页

- **Agent 详情页** — Agent 级指标（调用量/TTFT/Token/错误率）、链路列表、关联会话
- **应用详情页** — 应用级健康评分、性能趋势、最近 Trace 列表、依赖拓扑

### 会话分析

以 Session 为维度，深入分析单次会话的完整执行过程：

- Session 列表（按时间/Agent/状态筛选）
- Session 详情：对话内容、工具调用序列、Token 消耗分布、耗时分析
- 支持 Session 回放和导出

### 链路追踪（Trace）

基于 [[concepts/agent-trace-and-timeline|Agent Trace]] 的分布式追踪能力：

- **Trace 列表** — 按时间/Agent/状态/耗时筛选，展示 Trace 摘要
- **Trace 详情** — 树状 Span 结构可视化，展示完整调用链
- **Timeline 视图** — 按时间轴展示各 Span 的执行时序
- **8 种 LLM Span Kind** — CHAIN / EMBEDDING / RETRIEVER / RERANKER / TASK / LLM / TOOL / AGENT
- **Span 详情** — 每个 Span 的输入/输出、Token 消耗、耗时、状态码

### 全景拓扑

可视化 Agent 应用的服务依赖关系：

- 展示 Agent 与 LLM 模型、工具服务、检索服务、数据库等的外部调用关系
- 节点颜色反映健康状态（正常/降级/错误）
- 支持拓扑下钻至 Trace 和 Session

### 场景化分析

针对特定场景的预置分析视图：

- **Token 成本分析** — Token 消耗趋势、按模型/Agent/应用的成本归因
- **错误分析** — 错误类型分布、错误率趋势、高频错误 Top N
- **性能分析** — TTFT/TPOT 分布、慢请求识别、性能劣化检测

### 接入指引

提供从零开始接入可观测的指引：创建云监控 2.0 工作空间 → 安装探针 → 配置数据上报 → 验证接入成功。

---

## 2. AI Agent 审计

面向安全团队和应用 Owner，提供从接入到风险治理的全链路审计能力。解决 Agent 运行时产生的数据泄漏、行为异常、权限越界和安全合规风险。

### 核心流程

```
接入配置 → 审计管理 → 风险发现 → 实体调查 → 审计事实回放
```

### 审计接入

支持两种接入方式：
- **会话日志接入** — 针对 Qoder、Cursor、Claude Code、Codex 等 AI Coding Agent 的会话数据接入
- **Runtime/eBPF 接入** — 针对 AI 节点运行时采集，基于 eBPF 内核级监控

### 审计管理

- **应用风险审计开关** — 控制 Agent 应用的风险检测任务启停
- **运行时风险审计开关** — 控制主机运行时的风险检测任务启停
- **状态监控** — 查看已接入应用列表、运行时主机列表、最近数据时间和 24 小时流量趋势

### 风险审计

- **风险概览** — Dashboard 视图，展示风险事件总数、风险等级分布、风险趋势
- **数据泄漏检测** — 检测 Secret（密钥/AccessKey/Token）、PII（身份证/手机号/邮箱）等敏感信息泄漏
- **敏感文件检测** — 检测 Agent 对敏感文件路径的读写操作
- **外联行为检测** — 检测 Agent 对可疑域名和 IP 的网络外联

### 审计规则

预置审计规则覆盖以下维度（详见 [审计规则说明](https://help.aliyun.com/zh/document_detail/3045691.html)）：
- 敏感数据泄漏（Secret/PII）
- 敏感文件操作
- 权限越界行为
- 异常命令执行
- 异常网络连接
- 高危 API 调用
- Token 滥用

### 实体调查

以实体为中心的反查分析，支持的实体类型：

| 实体类型 | 说明 |
|----------|------|
| Secret | 密钥/AccessKey/Token |
| PII | 个人敏感信息 |
| 文件路径 | 敏感文件操作路径 |
| 外联域名/IP | 网络连接目标 |
| 应用/主机/用户 | 审计主体 |
| 来源 IP | 请求来源 |
| Tool/命令 | 工具调用和命令执行 |

每个实体可查看：关联风险事件、出现 Session、共现关系图谱。

### 审计事实

提供 Session 级别的原始审计事实浏览：

- **Session 浏览** — 按时间查看所有 Session 的审计事件
- **Token 分析** — 分析 Session 中的 Token 使用模式和异常
- **行为分析** — 直接描述原始审计事实和标准化后的审计活动数据

### 风险事件字段

风险事件包含完整字段信息（详见 [风险事件字段说明](https://help.aliyun.com/zh/document_detail/3045691.html)）：
- 事件时间、事件类型、风险等级
- 关联 Session ID、Agent ID、应用 ID
- 触发规则、事件描述、涉及的实体
- 原始审计事实引用

---

## 3. 实验

AgentLoop 支持离线实验和在线 A/B 实验，用于验证 Prompt/Skill/模型变更的效果。

### 实验操作指南

- **创建实验计划** — 定义实验目标、数据源、评估器、实验分组
- **执行实验** — 运行实验计划，对比对照组与实验组效果
- **实验结果分析** — 查看各分组的评估指标差异，判断变更是否有效
- **实验记录管理** — 浏览、筛选、删除历史实验记录

### 离线实验上报

支持使用离线实验方式上报实验结果（参见 [离线实验上报指南](https://help.aliyun.com/zh/document_detail/3047496.html)）：
- 适用于不便于接入 AgentLoop 实时采集的场景
- 通过 API 批量上报实验数据
- 支持自定义评估指标

---

## 4. 数据中心

### 数据集概述

数据集（Dataset）是 Trajectory 加工后的结构化数据资产，是评估和实验的基础。

### 数据集控制台接入

通过控制台管理数据集：
- 从 Pipeline 输出的 Trajectory 自动导入
- 手动上传 JSONL/CSV 格式数据
- 支持数据筛选、标注、版本管理

### 数据标注

- 支持人工标注和 AI 辅助标注
- 标注维度可自定义（如正确性、相关性、安全性等）
- 标注结果回流至数据集，用于评估和训练

---

## 5. 评估

### 评估概述

AgentLoop 的评估模块将 [[concepts/agent-evaluation-framework|Agent 评估框架]]工程化落地：

- **评估器（Evaluator）** — 定义评分逻辑，支持 LLM-as-Judge 和 Agent-as-Judge
- **评估器技能（Evaluator Skill）** — 可复用的评估技能单元，组合形成评估器
- **评估任务（Evaluation Task）** — 将数据集 + 评估器组合执行，产出评分报告
- **评估运行（Evaluation Run）** — 单次评估执行的详细记录

### 评估器

- 创建和管理评估器，配置评估模型、评分维度和标准
- 支持评估器技能的组合与复用
- 评估器类型：LLM Judge（用 LLM 评分）、规则 Judge（确定性规则评分）、混合 Judge

### 评估任务

- 创建评估任务：选择数据集 + 评估器 + 执行配置
- 查看评估结果：逐条数据的评分详情、整体统计、维度得分分布
- 评估历史：浏览和管理历史评估运行记录

---

## 6. Agent 资产

### Agent 资产概述

Agent 资产是驱动 Agent 行为的核心可复用资源，包括 Prompts 和 Skills。

### Prompts 管理

- **版本控制** — 每个 Prompt 支持多版本管理，记录变更历史
- **关联追踪** — 追踪每个 Prompt 版本被哪些 Agent 应用使用
- **效果对比** — 结合实验模块对比不同 Prompt 版本的效果
- **模板管理** — 支持参数化 Prompt 模板

### Skills 管理

- **Skill 注册** — 注册 Agent 可用的 Skills（工具函数/MCP 工具/API 调用）
- **能力绑定** — 将 Skills 绑定到具体的 Agent 或 Agent 应用
- **调用追踪** — 追踪每个 Skill 的调用量、成功率、平均耗时
- **变更管理** — Skill 的版本控制和变更审批

---

## 7. 经验库

### 经验库产品介绍

经验库（Experience Library）从历史 Trajectory 中提炼可复用的经验和模式：
- 自动从评估通过的 Trajectory 中提取成功经验
- 在 Agent 运行时动态检索相关经验作为上下文
- 形成"执行 → 评估 → 沉淀经验 → 增强执行"的闭环

### 经验库使用指南

- 配置经验提取策略（按时间范围、评估分数阈值、Agent 类型筛选）
- 经验检索：在 Agent 运行时通过上下文库 API 检索相关经验
- 经验管理：浏览、标注、启用/停用经验条目

---

## 8. 智能体空间 & 系统管理

### 智能体空间（AgentSpace）

参见 [[projects/aliyun-agentloop/agentloop|AgentLoop 项目页]]中 AgentSpace 的概念说明。

### 空间管理

- 创建/删除/编辑 AgentSpace
- 查看空间概览：Agent 应用数、数据集数、评估任务数、Pipeline 数
- 空间级权限控制

---

## 9. 服务支持

- **服务等级协议（SLA）** — AgentLoop 服务等级协议，定义服务可用性承诺和赔偿标准
- **常见问题（FAQ）** — 覆盖接入、计费、功能使用的常见问题
- **联系我们** — 技术支持钉钉群：147535001692

---

## LLM Trace 字段

AgentLoop 的 LLM Trace 字段在 [[concepts/genai-observability-semconv|OTel GenAI SemConv]] 基础上扩展，主要字段类别：

| 字段类别 | 说明 | 示例字段 |
|----------|------|----------|
| LLM 请求属性 | 模型调用的输入参数 | `llm.request.model`, `llm.request.max_tokens`, `llm.request.temperature` |
| LLM 响应属性 | 模型调用的输出 | `llm.response.model`, `llm.response.finish_reason` |
| LLM 用量属性 | Token 消耗 | `llm.usage.input_tokens`, `llm.usage.output_tokens` |
| GenAI 属性 | 通用 GenAI 语义 | `gen_ai.system`, `gen_ai.request.model`, `gen_ai.usage.input_tokens` |
| Agent 属性 | Agent 特有语义 | 会话 ID、工具名称、工具调用参数 |
| 事件（Event） | 流式输出事件 | `gen_ai.content.prompt`, `gen_ai.content.completion` |

Python 应用可使用 [loongsuite-util-genai](https://pypi.org/project/loongsuite-util-genai/) 组件辅助采集，详见 [[entities/loongsuite-platform|LoongSuite Platform]]。

## 计费

参见 [[projects/aliyun-agentloop/agentloop#技术规格|项目概述中的计费说明]]。

- **AI 积分** — 0.01 元/积分（一次评估约 10 积分，一次实验约 1 积分）
- **数据集存储** — 0.00004 元/条/天
- **执行次数** — 0.001 元/次
- **上下文工程** — 公测阶段暂不计费
