---
title: Arize Phoenix
category: entities
tags:
  - ai-agent
  - observability
  - evaluation
  - open-source
  - opentelemetry
sources:
  - "数据拾光者: AI那些趣事系列123：目前主流的智能体可观测性和智能体评测相关的产品调研 (2026-05-07)"
  - "熹元网络: Dify 平台集成 Phoenix 实战：提升智能体全链路可观测性 (2026-07-06)"
  - "机器之魂: LLM 可观测性：大多数生产级 AI 系统中缺失的那一层（完整指南） (2026-04-17)"
summary: Arize Phoenix 是基于 OpenTelemetry 的开源 AI 可观测性平台，专为 LLM 应用设计，提供 Tracing、Evaluation、Prompt 管理等核心能力，支持自托管部署和多种 Agent 框架集成。
base_confidence: 0.75
lifecycle: draft
lifecycle_changed: "2026-07-22"
tier: supporting
provenance:
  extracted: 0.8
  inferred: 0.2
  ambiguous: 0.0
created: "2026-07-22"
updated: "2026-07-22"
relationships:
  - target: "[[concepts/ai-agent-observability]]"
    type: implements
  - target: "[[concepts/genai-observability-semconv]]"
    type: uses
  - target: "[[entities/langfuse-llm-observability]]"
    type: related_to
  - target: "[[references/dify-phoenix-integration]]"
    type: related_to
  - target: "[[entities/dify]]"
    type: related_to
  - target: "[[entities/langsmith]]"
    type: related_to
---

# Arize Phoenix

**Arize Phoenix** 是基于 **OpenTelemetry** 和自研 **OpenInference** 标准的开源 AI 可观测性平台，专为 LLM 应用设计。它能够自动追踪智能体执行的完整链路，解决"Agent 内部到底发生了什么"的问题，同时提供 LLM-as-a-Judge 评估能力。

## 核心定位

Phoenix 的核心价值在于：

- **开源可自托管**：数据完全掌握在自己手中，适合对数据隐私要求高的企业
- **框架无感集成**：原生支持 LangGraph、CrewAI、OpenAI Agents SDK、Claude Agent SDK、AutoGen 等主流 Agent 框架
- **RAG 深度分析**：特别针对 RAG 应用，能可视化检索到的文档片段（Chunks）、计算检索相关性，帮助定位是"没搜到"还是"答错了"
- **OTel 原生**：基于 OpenTelemetry 标准，可与现有可观测性体系无缝集成

## 核心功能

### 1. 智能体可观测性（Agent Observability）

- **全链路追踪（Tracing）**：自动记录智能体的每一步推理、工具调用（Function Call）、API 请求。在 UI 上以树状结构展示，精确到每个工具的执行耗时、输入输出
- **框架无感集成**：无论你用什么框架，只需几行代码注入 instrumentation 即可接入
- **检索增强生成（RAG）深度分析**：可视化检索到的文档片段、计算检索相关性

### 2. 智能体评测（Agent Evaluation）

- **自动化评估（Evals）**：提供预置的评估器，衡量回答相关性（Answer Relevance）、检索相关性（Retrieval Relevance）、毒性（Toxicity）等指标
- **实验对比（Experiments）**：支持 A/B Testing。对比不同模型（如 GPT-4 vs Claude）、不同提示词（Prompt）或不同参数在同一组测试数据集上的表现
- **数据集管理**：支持创建版本化的测试数据集（Dataset），用于回归测试，确保代码更新不会导致智能体性能回退

### 3. Prompt 管理

- **版本控制**：追踪 Prompt 的迭代历史
- **Playground**：直接在 UI 里调试 Prompt，支持基于生产环境的 Trace 数据进行提示词迭代

## 架构与部署

- **自托管优先**：设计为可本地运行（Localhost）、Docker 或 K8s 部署
- **多语言支持**：以 Python 生态为主，通过 OpenTelemetry 的 OTLP 协议，也支持 Node.js（TypeScript）等语言的应用监控
- **UI 界面**：提供 Web UI（默认端口 6006）用于可视化 traces、查看评估报告和进行 Prompt 调优

### 快速开始

```bash
# 1. 安装
pip install arize-phoenix

# 2. 启动服务（会启动本地服务器和 UI）
phoenix serve
# 访问 http://localhost:6006

# 3. 在你的 Agent 代码中注入监控（以 OpenAI 为例）
from openinference.instrumentation.openai import OpenAIInstrumentor
from phoenix.otel import register

tracer_provider = register(endpoint="http://localhost:4317")  # OTLP 端点
OpenAIInstrumentor().instrument(tracer_provider=tracer_provider)
```

## 与同类工具对比

| 维度 | Phoenix | Langfuse | [[entities/langsmith|LangSmith]] |
|------|---------|----------|-----------|
| **开源** | ✅ 开源（Mulan PSL 2.0 / Apache 2.0） | ✅ MIT（核心功能） | ❌ 闭源 |
| **自托管** | ✅ 支持 | ✅ 支持 | 仅企业版 |
| **OTel 原生** | ✅ 是 | ✅ 是 | ❌ 否 |
| **RAG 分析** | ⭐ 强（可视化文档片段、相关性计算） | 一般 | 一般 |
| **评估能力** | ⭐ 强（LLM-as-Judge、实验对比） | 基础（LLM-as-Judge、人工标注） | ⭐ 强（内置丰富评估器） |
| **框架绑定** | 框架无关 | 框架无关 | 深度绑定 LangChain |
| **适用场景** | RAG 深度分析、OTel 体系、自托管 | 开源 LLM 工程闭环、数据合规 | LangChain 生态、快速验证 |

## 典型工作流

1. **开发阶段**：集成 SDK，在本地或测试环境查看 Trace，调试 Prompt
2. **测试阶段**：使用评估功能在数据集上测试 Prompt 和模型，选择最优解
3. **生产阶段**：监控线上流量，收集用户反馈，通过 A/B 测试持续迭代优化

## 相关页面

- [[concepts/ai-agent-observability]] — AI Agent 可观测性整体概念
- [[concepts/genai-observability-semconv]] — OpenTelemetry GenAI 语义规范
- [[entities/langfuse-llm-observability]] — Langfuse LLM 可观测平台
- [[references/[[entities/dify|Dify]]-phoenix-integration]] — Dify 平台集成 Phoenix 实战