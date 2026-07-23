---
title: LangSmith
category: entities
tags:
  - ai-agent
  - observability
  - evaluation
  - langchain
  - saas
sources:
  - "数据拾光者: AI那些趣事系列123：目前主流的智能体可观测性和智能体评测相关的产品调研 (2026-05-07)"
summary: LangChain 公司推出的商业闭源 LLM 应用可观测与评测平台，深度绑定 LangChain/LangGraph 生态，提供思维链可视化、生产监控、LLM-as-Judge 和人工标注集成。
provenance:
  extracted: 0.80
  inferred: 0.15
  ambiguous: 0.05
base_confidence: 0.53
lifecycle: draft
lifecycle_changed: 2026-07-22
tier: supporting
created: 2026-07-22T00:00:00+08:00
updated: "2026-07-22"
relationships:
  - target: "[[concepts/ai-agent-observability]]"
    type: implements
  - target: "[[entities/langfuse-llm-observability]]"
    type: related_to
  - target: "[[entities/arize-phoenix]]"
    type: related_to
  - target: "[[entities/mlflow]]"
    type: related_to
---

# LangSmith

**LangSmith** 是 LangChain 公司推出的商业闭源平台，专注于解决 LLM 应用（尤其是智能体）在生产环境中的**可观测性（Observability）**和**评测（Evaluation）**难题。^[extracted] 它与 LangChain 框架同属一家公司，但 LangSmith 是 SaaS 服务（也提供企业自托管选项），属于专有软件。^[extracted]

## 开源状态与协议

LangSmith 并非完全开源。GitHub 上能找到的 `langsmith` 库只是**客户端 SDK**（MIT 协议），用于在代码中发送追踪数据；真正的服务端平台代码是闭源的，无法自行部署完整社区版。^[extracted]

| 组件 | 开源状态 | 协议 | 说明 |
|------|---------|------|------|
| LangSmith 平台 | ❌ 闭源 | 商业专有 | UI 后台、存储、核心服务，按量或按席位付费 |
| LangSmith Client SDK | ✅ 开源 | MIT | 连接 LangSmith 服务的客户端库（Python/JS） |
| LangChain 框架 | ✅ 开源 | MIT | 构建应用的底层框架，与 LangSmith 分离 |

## 核心功能：智能体可观测性

### 思维链可视化

将 Agent 的思考过程（Reasoning）完全展开，不仅能看到最终答案，还能看到它调用了哪些工具（Tools）、传入参数、中间步骤的 LLM 调用、Token 消耗及耗时。^[extracted] 当 Agent 出错或陷入死循环时，能快速定位是哪个工具调用失败，或哪一步 Prompt 逻辑有问题。^[extracted]

### 生产环境监控

记录生产环境中的每一次会话（Trace），监控延迟、成本和错误率。^[extracted] 提供 Insights 面板，自动聚类相似的错误或低质量回答，帮助团队发现高频问题。^[extracted]

## 核心功能：智能体评测

### LLM-as-a-Judge

利用更强的 LLM（如 GPT-4）自动对历史运行记录（Traces）或测试集进行打分，支持自定义评分标准（如相关性、准确性、安全性）。^[extracted] 无需人工介入即可批量评估数千次 Agent 运行的质量，量化版本迭代效果。^[extracted]

### 数据集与回归测试

将生产中的真实对话保存为数据集（Dataset），用于后续离线评测（Offline Eval），支持 A/B 测试不同模型或 Prompt 版本。^[extracted] 防止优化过程中引入"回退"（Regression），确保新版本不会在已知场景下表现更差。^[extracted]

### 人工标注集成

提供标注队列（Annotation Queues），让领域专家对复杂 Agent 输出进行人工打分或修正，这些标注数据可反哺训练集或评测标准。^[extracted]

## 选型建议

### 适合 LangSmith 的场景

- 深度使用 LangChain/LangGraph 生态，需要零配置的深度集成。^[extracted]
- 看重强大的可视化调试和成熟的评测工作流。^[extracted]
- 能接受 SaaS 服务或购买企业版（自托管）。^[extracted]
- 初创团队快速验证 MVP，免费额度够用，上手快。^[extracted]

### 寻找开源替代的场景

- 需要完全自托管、数据不出域或预算有限。^[extracted]
- 技术栈混合（非纯 LangChain），需要框架无关的观测层。^[extracted]
- 金融或数据敏感行业，需要满足数据出境/存储合规要求。^[extracted]

主要开源替代方案包括 [[entities/langfuse-llm-observability|Langfuse]]（MIT 协议）和 [[entities/mlflow|MLflow]]（Apache 2.0）。^[extracted]

## 与 Langfuse 的核心差异

| 维度 | Langfuse | LangSmith |
|------|----------|-----------|
| 出身 | 独立开源 LLM 工程平台 | LangChain 官方闭源 SaaS |
| 核心优势 | 数据主权、框架无关、成本透明 | 与 LangChain 生态无缝集成、评估功能强大 |
| 部署模式 | 云托管或自托管（Docker/K8s） | 主要为云 SaaS（企业版支持私有化） |
| 集成难度 | 需手动接入 SDK，支持 OpenAI SDK、LlamaIndex 等 | LangChain 用户零配置，非 LangChain 需适配 |
| 定价模型 | 自托管免费；云版按量付费 | 按 Trace 量 + 席位费（$39/用户/月起） |
| 追踪模型 | Span/Generation，原生支持 OpenTelemetry | Run Tree，深度解析 LangChain LCEL/LangGraph |
| 评估能力 | LLM-as-Judge + 人工标注，灵活性高 | 内置丰富评估器，A/B 测试与数据集管理完善 |

## 相关页面

- [[entities/langfuse-llm-observability]] — LangSmith 的主要开源竞品
- [[concepts/ai-agent-observability]] — LLM 应用可观测性整体概念
- [[entities/arize-phoenix]] — 另一个开源可观测平台
