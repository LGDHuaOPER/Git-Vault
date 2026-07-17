---
title: AI Agent Observability
aliases:
  - Agent Observability
  - Agent 可观测性
  - Agent Observability Fundamentals
  - Agent 可观测性范式转变
category: concepts
tags:
  - ai-agent
  - observability
  - tracing
  - metrics
  - llm
sources:
  - "阿里云开发者: 当 AI Coding Agent 成为基础设施：我们为什么要开源 LoongSuite Pilot (2026-06-12)"
  - "阿里云开发者: 阿里巴巴 & 蚂蚁 LoongSuite GenAI 可观测语义规范 (2026-05-12)"
  - "阿里云开发者: 详解大模型应用可观测全链路 (2025-03-13)"
  - "阿里云开发者社区: 从 AI Agent 到模型推理：端到端 AI 可观测实践"
  - "SelectDB: 我们用 AI Observe Stack 观测了 OpenClaw (2026-03-04)"
  - "SelectDB: Apache Doris 在 AgentLogsBench 中领先 (2026-07-07)"
  - "ThinkingAgent: AI可观测性：Prompt、Tool Call、Trace、Token全链路追踪 (2026-06-22)"
  - "叶小钗: Agent 可观测性：为什么有了 LangChain，还会出现 Langfuse？ (2026-06-10)"
  - "叶小钗: Agent Harness 可观测性 (2026-05-25)"
  - "阿里云可观测: 零代码改造！LoongSuite AI 采集套件观测实战 (2025-09-01)"
  - "一览清风: Agent Timeline：看懂 AI Agent 调试从看日志到看轨迹的变化 (2026-06-30)"
  - "小加号编程笔记: AI Agent 可观测性：如何记录推理、工具调用、失败与成本 (2026-07-13)"
  - "ThinkingAgent: AI安全和治理：AI Observability、Evaluation、治理、安全与成本 (2026-06-28)"
  - "FutureCraft AI: 第12篇：Agent 可观测性——看见你的 Agent 在想什么 (2026-06-02)"
  - "SelectDB: Agent 时代为什么需要新的可观测范式？ (2026-05-21)"
  - "数栖云间: Apache Doris 在 AI Agent 可观测性中的架构实践 (2026-03-12)"
  - "一臻数据: Litefuse 正式发布！Doris 原生 Agent 可观测平台来了 (2026-05-21)"
  - "AI Engineer编程微信公众号: Agent 可观测与质量评测体系：从数据采集到数据飞轮的完整实践 (2026-07-12)"
summary: AI Agent 可观测性是理解、调试和治理 AI Agent 系统内部状态与行为的完整能力体系。核心问题是"任务有没有做对"而非"系统有没有崩"——从 HTTP 200 到语义正确性的范式跨越。涵盖四大观测维度（Trace/Prompt/Tool Call/Token）、三层架构设计（接入/计算存储/应用）、四大支柱（Tracing/Metrics/Logging/Alerting）、六层失败模型，以及观测→评估→归因→优化的闭环流程。
provenance:
  extracted: 0.65
  inferred: 0.28
  ambiguous: 0.07
base_confidence: 0.82
lifecycle: draft
lifecycle_changed: 2026-07-16
tier: core
created: 2026-07-16T00:00:00+08:00
updated: 2026-07-17
relationships:
  - target: "[[concepts/agent-trace-and-timeline]]"
    type: extends
  - target: "[[concepts/agent-trace-span-taxonomy]]"
    type: extends
  - target: "[[concepts/agent-harness]]"
    type: related_to
  - target: "[[concepts/genai-observability-semconv]]"
    type: uses
  - target: "[[concepts/agent-cost-breakdown]]"
    type: related_to
  - target: "[[concepts/agent-failure-taxonomy]]"
    type: extends
  - target: "[[concepts/ai-production-engineering-five-pillars]]"
    type: part_of
  - target: "[[concepts/evaluation-driven-development]]"
    type: supports
  - target: "[[concepts/agent-online-evaluation]]"
    type: related_to
  - target: "[[concepts/agent-data-flywheel]]"
    type: related_to
  - target: "[[entities/deepseek-observability-agent]]"
    type: related_to
  - target: "[[references/alicloud-loongcollector-agent-sandbox]]"
    type: related_to
  - target: "[[references/stepfun-selectdb-pb-observability]]"
    type: related_to
---

# AI Agent Observability

AI Agent 可观测性是理解 AI Agent 系统内部状态和行为的完整能力。它不是简单的日志记录，而是从用户输入 → Prompt → LLM 调用 → Tool Call → 多轮推理 → 最终输出的全链路可视化与诊断体系。

## 范式转变：从 HTTP 200 到语义正确性

传统可观测性（APM）的核心问题是：**系统有没有正常运行？** Prometheus 看 CPU/内存，Grafana 看延迟/QPS，ELK 看错误日志。P99 延迟 0.2 秒、错误率 0.001%——运维同学可以安心下班。

Agent 时代，这套逻辑彻底失效。

某团队上线了一款客服 Agent：监控大盘全绿，HTTP 状态码 200，工具调用链路正常，模型响应时间达标。但系统把一个符合退款政策的订单直接回复为"根据政策无法退款"。从任何传统可观测指标看，没有异常。**但 Agent 在业务层给出了错误答案。**

核心问题转移了：**在系统正常运行的同时，任务真的做对了吗？**

## 为什么 Agent 比普通服务更需要可观测性

传统 APM 围绕结构化、稳定且可预测的遥测数据展开：HTTP 状态码、延迟分位数、错误计数等，schema 固定、payload 较小。AI Agent 有三个根本差异：

1. **非确定性输出**：相同输入可能产生不同输出，传统"请求-响应成功率"模型失效。Agent 的行为取决于模型推理、工具选择和环境状态，而不是固定的代码路径。

2. **多步推理链路**：一次用户请求可能触发 4-10 次 LLM 调用、多次工具调用、内部规划的生成与修正。链路长且分支多，传统 trace 粒度不足。

3. **成本不可见**：Agent 的成本不只是 API 调用费用，还包含 Token 消耗、工具调用费、重试浪费。没有观测就无法优化。

从数据层面看，量变引起质变：

| 维度 | 传统可观测 | Agent 可观测 |
|------|-----------|-------------|
| 文本长度 | KB 级别 | MB 级别（百万 token 上下文） |
| Trace 规模 | 几个 Span / 请求 | 数百到数万 Span / 任务 |
| 数据格式 | 结构化的元数据 | input/output 大量嵌套 JSON |
| 数据总量 | 日均 GB 级 | 日均 TB 级 |
| Trace 跨度 | 毫秒到秒 | 数小时到数天 |

## 四大观测维度

AI Agent 可观测性围绕四个核心维度展开：

### 1. Trace 链路追踪
完整的调用链路，从用户输入到最终输出。一条 Agent Trace 通常包含多层嵌套：Span → Observation → LLM Call / Tool Call / Retry。参见 [[concepts/agent-trace-and-timeline]] 和 [[concepts/agent-trace-span-taxonomy]]。

### 2. Prompt 追踪
记录所有 Prompt（包括动态生成的系统提示、模板变量填充结果），追踪每次模型调用的输入输出和性能指标（延迟、Token 数、首次 Token 时间）。

### 3. Tool Call 追踪
监控 Agent 调用的所有外部工具（API、数据库、文件系统、搜索引擎），记录调用参数、返回结果、耗时、失败重试。

### 4. Token 与成本追踪
Token 消耗、API 调用费用的实时监控，支持按应用、租户、模型版本等维度聚合。详见 [[concepts/agent-cost-breakdown]]。

## 四大支柱框架

部分实践者将可观测能力组织为四大支柱：

### 1. Tracing（追踪）
记录每次 AI 调用的完整链路：Prompt → 模型推理 → Tool Call → 输出 → 用户反馈。Agent trace 需要建模成树状结构，而不仅仅是线性的 span 序列。

### 2. Metrics（指标）
实时监控关键指标：延迟（P50/P95/P99）、成功率、Token 消耗、质量评分。Agent metrics 需要多维度——按模型、按任务类型、按用户/租户拆分。

### 3. Logging（日志）
结构化日志，支持搜索和分析。Agent 日志的特殊性在于推理链（Chain-of-Thought）本身也是重要的观测对象——"它在想什么"往往比"它做了什么"更能解释问题。

### 4. Alerting（告警）
异常检测和自动告警：质量下降（如 hallucination 率上升）、成本飙升（Token 消耗异常）、安全事件（越狱尝试）。告警阈值需要基于历史基线动态调整。

## 与传统 APM 的关键差异

| 维度 | 传统 APM | AI Agent 可观测性 |
|------|----------|-------------------|
| 观测对象 | 代码路径（确定性） | 推理路径（非确定性） |
| 数据形态 | 结构化、固定 schema | 半结构化、大文本、动态 JSON |
| Trace 结构 | 线性调用链 | 树状决策图 / 多层嵌套 ReAct 循环 |
| 核心指标 | QPS、延迟、错误率 | 质量/Token/工具成功率/推理步数/TTFT/TPOT |
| 告警逻辑 | 阈值告警 | 基线漂移告警 + 语义告警 |
| 成本模型 | 基础设施成本 | Token 计费 + 工具调用费 |
| 故障模型 | 超时、5xx、OOM | Prompt 注入、幻觉、工具误调用、推理循环 |
| 排障方式 | 查日志、看监控面板 | 回放 Timeline、检索嵌套路径、对比多轮推理 |

## Agent 的六层失败模型

来自 Honeycomb 的 Agent Timeline 实践框架，将 Agent 的失败位置分为六层：

1. **输入失败** — Prompt 不完整、上下文不足、权限缺失
2. **模型失败** — 幻觉、逻辑错误、输出格式不符
3. **工具失败** — API 超时、返回空结果、schema 不匹配
4. **数据失败** — 检索到错误文档、向量相似度误导
5. **控制失败** — 循环推理、过早终止、工具选择错误
6. **结果失败** — 最终输出不符合业务预期

Timeline 的核心价值在于**从"它错了"定位到"错在哪一步"**。详见 [[concepts/agent-failure-taxonomy]]。

## 观测→评估闭环

面向 Agent 的可观测与效果评估深度融合，形成闭环：

1. **上线前**：通过测试集与评估器量化对比不同版本的回答效果
2. **上线后**：持续采集真实用户的交互轨迹与 Agent 内部执行路径
3. **异常排查**：发现 Bad Case 后自动或半自动归因至 Prompt、上下文、模型或工具问题
4. **持续迭代**：将 Bad Case 转化为评测样本，在下一轮验证优化效果

这个闭环就是 **观测 → 评估 → 归因 → 优化 → 再评估**。方法论层面参见 [[concepts/evaluation-driven-development]] 和 [[concepts/llm-as-judge-evaluation]]。

## 全链路可观测架构：三层设计

面向 Agent 原生的全链路可观测体系，分为三层 ^[extracted]：

### 接入层：多形态、无侵入、标准化

| 接入形态 | 代表框架 | 策略 |
|---|---|---|
| 高代码 | LangChain、LlamaIndex、AutoGen、Spring AI | SDK 深度埋点 |
| 低代码 | Dify、Langflow | 平台扩展机制注入 |
| 通用 Agent | OpenClaw | 运行时统一采集 |
| 多语言 | Python/Node.js/Java/Go | 字节码增强/eBPF 无侵入埋点 |

关键设计：基于 OTEL 标准保证生态兼容性，同时通过 LoongSuite 进行 GenAI 语义扩展，实现框架无关的埋点抽象。^[extracted]

### 计算 & 存储层：Agent 原生数据处理

- **GENAI 语义对齐**：将技术 Span 转化为语义角色（llm_call、retriever_search、tool_execution），实现从"函数调用"到"Agent 决策"的语义跃迁 ^[extracted]
- **Trace 尾采样**：基于错误、慢请求、异常模式等聚合结果做尾部采样，平衡高成本场景下的存储效率
- **UModel 实体拓扑**：构建 LLM 模型、Tool、Knowledge Base、Agent 实例的关联图谱，实现从"链路追踪"到"系统理解"的升级 ^[extracted]

### 应用层：三维分析

| 维度 | 分析内容 | 业务价值 |
|---|---|---|
| 性能分析 | Token 消耗、LLM/工具调用耗时、平均推理轮次 | 优化用户体验 |
| 安全审计 | 敏感信息泄露、越权工具调用、Prompt 注入 | 合规与风控 |
| 成本分析 | 模型调用费用趋势、会话成本核算 | FinOps 决策 |

## Agent 性能指标维度扩展

除了传统延迟和吞吐量，Agent 场景引入了全新的性能指标 ^[extracted]：

- **TTFT**（Time To First Token）— 首 Token 延迟，直接影响用户等待感知
- **TPOT**（Time Per Output Token）— 每输出 Token 耗时，决定流式响应流畅度
- **SSE 流式输出质量** — 流式传输的稳定性和完整性
- **对话轮次** — 完成一个任务所需的推理步数，反映 Agent 效率

这些指标直接关联用户实时体验，成为 Agent 可观测的核心度量对象。

## 数据采集目标多元化

Token 消耗、文本、图片、音频、视频等多模态内容的采集，涉及大体积数据的采样压缩、敏感内容脱敏等新挑战。Agent Trace 的数据量比传统 APM 高 1-2 个数量级，存储和传输成本不可忽视。^[extracted]

## 观测→评估闭环

面向 Agent 的可观测与效果评估深度融合，形成闭环：

1. **上线前**：通过测试集与评估器量化对比不同版本的回答效果
2. **上线后**：持续采集真实用户的交互轨迹与 Agent 内部执行路径
3. **异常排查**：发现 Bad Case 后自动或半自动归因至 Prompt、上下文、模型或工具问题
4. **持续迭代**：将 Bad Case 转化为评测样本，在下一轮验证优化效果

这个闭环就是 **观测 → 评估 → 归因 → 优化 → 再评估**。完整的数据飞轮闭环参见 [[concepts/agent-data-flywheel]]，在线评估体系参见 [[concepts/agent-online-evaluation]]。

## 最小落地闭环

从 Day 1 开始的最小可观测方案：

1. 记录每次 Agent Run 的完整输入输出（结构化日志）
2. 记录每次 LLM 调用的 Token 消耗（成本追踪）
3. 对最终输出做简单的质量评估（LLM-as-Judge）
4. 设置成本异常的告警阈值

## 生态与工具

### 开源平台
- [[entities/langfuse-llm-observability]] — 最成熟的开源 LLM 可观测平台（28.5K Star）
- [[entities/ai-observe-stack]] — 基于 Apache Doris 的 AI 可观测存储后端
- [[entities/loongsuite-platform]] — 阿里云 LoongSuite 可观测体系
- [[entities/litefuse]] — 基于 Doris 的开源 Agent 可观测与评估平台
- [[entities/agenttrace]] — UC Berkeley 三层结构化追踪框架
- [[entities/mcpspy-ebpf-mcp-monitoring]] — 基于 eBPF 的 MCP 无侵入可观测
- [[entities/deepseek-observability-agent]] — DeepSeek 在可观测性智能体中的实践

### 标准化
- [[concepts/genai-observability-semconv]] — OpenTelemetry GenAI 语义规范
- [[references/agentlogsbench]] — Agent 可观测存储基准测试

### 工程模式
- [[concepts/agent-harness]] — Agent 执行环境的工程框架
- [[concepts/ai-production-engineering-five-pillars]] — 运行工程化的完整框架

### 案例与部署
- [[references/alicloud-loongcollector-agent-sandbox]] — 阿里云 ARMS AI 可观测方案
- [[references/stepfun-selectdb-pb-observability]] — 阶跃星辰 PB 级 Agent 可观测平台

## 开放性议题

- Agent 可观测数据的存储方案选择：专用 OLAP（Doris/ClickHouse）vs 通用可观测后端（Elasticsearch/Loki）vs 专用平台（Langfuse/LangSmith）
- 端侧 Agent（如 AI Coding Agent）的可观测盲区如何填补 — LoongSuite Pilot 是首个系统性尝试
- Agent 评估（Evaluation）与可观测性（Observability）的边界模糊化趋势
- Timeline 可视化的交互设计仍在早期：如何在一个界面上同时展示推理逻辑、工具调用参数和 Token 成本分布
