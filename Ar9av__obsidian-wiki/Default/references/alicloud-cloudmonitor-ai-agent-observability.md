---
title: 阿里云云监控 AI Agent 可观测
category: references
tags:
  - ai-agent
  - observability
  - alibaba-cloud
  - cloudmonitor
  - multi-agent
  - production
sources:
  - "阿里云云原生: 重磅发布丨云监控 AI Agent 可观测，企业生产级 Agent 首选全域观测平台 (2026-05-31)"
summary: 阿里云云监控发布的 AI Agent 可观测产品，提供接入层、数据层、分析层、应用层四层架构，支持 Multi-Agent 全链路追踪、会话分析、Token 成本治理、智能告警与根因定位、Agentic Ops 能力。
provenance:
  extracted: 0.75
  inferred: 0.20
  ambiguous: 0.05
base_confidence: 0.63
lifecycle: draft
lifecycle_changed: "2026-07-22"
tier: supporting
created: "2026-07-22"
updated: "2026-07-22"
relationships:
  - target: "[[entities/loongsuite-platform]]"
    type: related_to
  - target: "[[concepts/ai-agent-observability]]"
    type: implements
  - target: "[[concepts/genai-observability-semconv]]"
    type: uses
  - target: "[[references/alicloud-loongcollector-agent-sandbox]]"
    type: related_to
  - target: "[[entities/dify]]"
    type: related_to
  - target: "[[concepts/umodel]]"
    type: related_to
  - target: "[[entities/openclaw]]"
    type: related_to
---

# 阿里云云监控 AI Agent 可观测

2026 年 5 月 31 日，阿里云云监控正式发布 **AI Agent 可观测**产品，定位为企业生产级 Agent 的全域观测平台。

## 产品背景

AI Agent 正从实验走向规模化生产：
- 2025 年全球 AI Agent 市场规模已达 792 亿美元（Multimodal.dev 统计）
- 超过 66% 的落地项目已采用 Multi-Agent 协作架构（Arcade.dev 调研）
- Gartner 预测到 2026 年将有 40% 的企业应用内嵌 AI Agent 能力 ^[extracted]

生产级 Agent 面临四大核心挑战 ^[extracted]：

| 挑战 | 说明 |
|------|------|
| **成本失控** | Token 作为核心成本单元，缺乏实时监测，异常重试/重复调用往往月底才发现 |
| **故障定位低效** | Multi-Agent 网状调用链复杂，MTTR 居高不下 |
| **安全边界模糊** | 工具调用增多扩大攻击面，Prompt 注入、越权调用等风险缺乏过程化监测 |
| **质量难以量化** | 幻觉、决策偏离缺乏过程数据支撑，难以复现和优化 |

## 四层产品架构

### 接入层：灵活适配，分钟级接入

- 多语言自研探针（Python/Node.js/Golang/Java），支持 LangChain/LangGraph、AgentScope、[[entities/dify|Dify]]、[[entities/openclaw|OpenClaw]]、Hermes、QoderWork、Claude Code、Codex 等 20+ 主流 AI 框架或智能体应用
- 对业务代码零侵入，分钟级完成接入
- 提供 GenAI Utils 自定义埋点 SDK
- 兼容 OpenTelemetry GenAI 数据规范，支持 OTLP gRPC/HTTP 传输协议 ^[extracted]

### 数据层：统一建模，全域关联

基于 **[[concepts/umodel|UModel]] 统一建模体系**，将基础设施（GPU、ACK/ECS/FC）、AI 服务（推理服务、训练任务、SandBox）、AI 资产（模型、AI Agent、AI 应用、工具、数据集）等实体统一建模，完整存储推理过程数据并支持多模态数据原生预览。

### 分析层：多维分析

全景拓扑、链路追踪、会话分析、指标大盘、智能告警五大核心模块协同，提供从全局视图到单链路下钻的完整分析路径。

### 应用层：Agentic 化

将可观测能力全面 Agentic 化，提供与控制台对等的 CLI/Skills 接口，支持 AI Agent 直接调用可观测能力进行快速接入、智能查询、分析和告警处理，并在全路径内嵌 AI 辅助分析能力。

## 核心能力

### 全场景接入

三种接入模式：
1. 自动探针接入（主流框架）
2. 自定义埋点 SDK
3. OpenTelemetry 兼容接入

### 全局总览大盘

覆盖会话统计、Token 用量统计、模型性能、Agent 调用和智能体框架分布等维度。

### 拓扑与健康度

- **全景拓扑**：实时展示 AI 应用、AI Agent、模型、工具等实体的全局拓扑关系，支持 Multi-Agent 调用关系逐层下钻
- **主动式健康巡检**：内置巡检规则 + 自定义告警规则，红绿灯方式呈现实时健康状态；健康度详情展示异常事件和上下游影响面，支持 AI 智能分析生成巡检报告

### 全链路追踪

- 轨迹追踪与回溯：调用树、链路图、时序线、链路分析大盘
- 工作流执行路径图：以图谱形式展现决策路径和工具调用关系
- 推理过程数据还原：以推理轨迹为时间线还原内部推理过程
- 多模态数据原生预览：文本、图像、音视频、PDF
- 评估能力关联：在链路追踪视图中发起评估任务、按评估结果筛选链路
- 链路转数据集：批量将高价值链路转换为数据集，支持自定义 Pipeline 加工

### 会话分析

通过 **USER → SESSION → TRACE** 三层数据聚合结构，还原用户与 Agent 的多轮对话交互全过程，适配多轮对话、长周期会话、多模态场景。

### 场景化分析

- **Token 用量分析**：模型/AI 应用/AI Agent 多维筛选，输入/输出/缓存命中率统计
- **模型性能分析**：RED 指标（Rate/Error/Duration）、TTFT、TPOT 等多维统计与趋势
- **工具调用分析**：全局工具调用分布与性能明细、技能（Skills）加载统计
- **RAG 调用分析**：Retrieval、Rerank、Embedding 调用的 RED 指标与趋势

### 智能告警与根因定位

覆盖模型调用、工具调用、Token 消耗、Agent 自身调用等维度的告警指标集。告警触发后支持 AI 智能分析和根因定位，并可通过多轮对话追问细节。

### Agentic Ops 能力

- 能力全开放：接入到查数、统计、分析、告警全链路提供 CLI/Skills 接口
- 全域数据关联：UModel 体系覆盖 GPU 到 Agent 的全栈对象，一次查询获取关联上下文
- 全链路 AI 辅助：Trace 分析、健康度分析、指标异动分析、告警根因定位均内嵌 AI 辅助

## 典型落地场景

### 场景一：Token 成本治理

支持按模型/Agent/应用多维度追踪 Token 消耗分布，提供输入输出 Token 数、缓存命中率与 Agent 使用分布的秒级趋势大盘，AI 辅助定位高消耗链路。

### 场景二：故障根因快速定位

异常告警触发后：
- T+0s：告警触发
- T+10s：健康度大盘下钻定位异常 Agent 节点
- T+30s：链路追踪聚焦失败路径，工作流图展示决策环节
- T+60s：AI 智能根因分析自动生成分析报告
- T+90s：价值链路数据一键转为数据集用于后续优化

### 场景三：数据驱动的 Agent 持续优化

通过链路追踪关联评估能力，筛选高质量链路并批量转换为数据集，完整保留推理过程与多模态上下文，形成**观测 → 评估 → 筛选 → 回灌**闭环。

## 相关页面

- [[entities/loongsuite-platform]] — 阿里云 AI 可观测产品体系
- [[concepts/ai-agent-observability]] — AI Agent 可观测性整体概念
- [[concepts/genai-observability-semconv]] — OpenTelemetry GenAI 语义规范
- [[references/alicloud-loongcollector-agent-sandbox]] — 阿里云 ARMS AI 可观测方案
