---
title: MLflow
category: entities
tags:
  - ai-agent
  - observability
  - evaluation
  - mlops
  - open-source
  - apache
sources:
  - "数据拾光者: AI那些趣事系列123：目前主流的智能体可观测性和智能体评测相关的产品调研 (2026-05-07)"
summary: Linux 基金会旗下的开源 MLOps 平台，通过 Trace 与 GenAI Evaluation 模块为智能体提供可观测性与评测能力，适合作为底层实验管理底座。
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
  - target: "[[concepts/evaluation-driven-development]]"
    type: implements
  - target: "[[entities/langfuse-llm-observability]]"
    type: related_to
  - target: "[[entities/langsmith]]"
    type: related_to
---

# MLflow

**MLflow** 是 Linux 基金会旗下的开源项目（GitHub https://github.com/mlflow/mlflow，25.8K Star，5.7K fork），核心代码库遵循 Apache License 2.0 协议。^[extracted] 它已从传统的机器学习生命周期管理平台，全面进化为**生成式 AI 与智能体（Agent）的可观测性平台**。^[extracted] 针对智能体场景，MLflow 2.x/3.x 通过 **Trace（追踪）** 和 **GenAI Evaluation（评估）** 两大模块，解决智能体"黑盒"调试与量化评估难题。^[extracted]

## 核心定位

MLflow 在智能体可观测性领域更像**底层实验管理底座**，而非开箱即用的可视化工作台。^[inferred] 它的优势在于与 MLflow Model Registry、实验管理、CI/CD 流水线的深度整合，适合已经有 MLflow 基础的团队扩展智能体能力。^[inferred]

## 智能体可观测性

### Trace 与 Span 模型

MLflow 的 Trace 系统记录"**为什么发生**"，通过自动化分布式链路追踪将复杂智能体工作流可视化：^[extracted]

- **Trace（追踪）**：代表一次完整用户请求生命周期。例如用户问"帮我订一张机票"，从接收请求到最终回复的整个过程。^[extracted]
- **Span（跨度）**：Trace 中的每一个独立步骤，例如：意图识别 → 工具调用（查询航班） → LLM 合成回复。^[extracted] 每个 Span 记录输入、输出、耗时和元数据（如 Token 用量、成本）。^[extracted]

### 实战价值

- **调试工具调用**：在 UI 中展开 Trace，看到底是哪个工具超时，或哪一步 LLM 调用返回了意外格式。^[extracted]
- **成本与性能分析**：自动记录每次 LLM 调用的 Token 消耗和延迟，识别检索步骤还是生成步骤拖慢整体速度。^[extracted]
- **多框架支持**：原生支持 LangChain、LlamaIndex、LangGraph 等主流 Agent 框架，通常只需一行 `autolog()` 即可开启追踪。^[extracted]

## 智能体评测

### 评测模式

| 模式 | 应用场景 | 核心功能 |
|------|---------|---------|
| 离线评估（Offline） | 开发/回归测试 | 在标注数据集上批量运行，对比不同 Prompt 或模型版本效果 |
| 在线监控（Online） | 生产环境 | 对实时用户请求采样评估，监控质量漂移 |

^[extracted]

### 内置 LLM-as-a-Judge

MLflow 提供内置评估器，利用 LLM 作为裁判评估智能体输出：^[extracted]

- **正确性（Correctness）**：答案是否准确。^[extracted]
- **有据性（Groundedness）**：答案是否严格基于上下文（防幻觉）。^[extracted]
- **安全性（Safety）**：是否包含不当内容。^[extracted]
- **工具使用合理性**：是否调用了该调用的工具，调用参数是否正确。^[extracted]

### 自定义评测逻辑

通过 `@scorer` 装饰器定义业务专属规则，例如金融客服智能体需要检查合规性提示语、验证工具调用链顺序等。^[extracted]

## 版本注意

- **MLflow 2.x**：评估功能主要在 `mlflow.evaluate` 或 Databricks 特定的 `databricks-agents` SDK 中。^[extracted]
- **MLflow 3.x**：评估 API 统一迁移至 `mlflow.genai` 命名空间（如 `mlflow.genai.evaluate`），API 更简洁，且深度集成 Trace 数据。^[extracted]

## 典型工作流

1. **开发阶段**：使用 `mlflow.genai.evaluate` 在测试集上跑分，用 LLM 法官快速筛选最佳 Agent 版本。^[extracted]
2. **部署阶段**：将选中版本注册到 MLflow Model Registry 并部署到生产环境。^[extracted]
3. **生产阶段**：开启在线监控，持续收集 Trace 和反馈；发现质量下降时触发回滚或重新评估。^[extracted]

## 与 Langfuse / [[entities/langsmith|LangSmith]] 的对比

| 维度 | MLflow | Langfuse | LangSmith |
|------|--------|----------|-----------|
| 定位 | MLOps / 实验管理底座 | LLM 工程平台 | LangChain 官方 SaaS |
| 协议 | Apache 2.0 | MIT | 闭源 |
| Agent 可视化 | 基础，Agent 专用可视化较弱 | 强 | 强 |
| 评估 | 实验管理 + GenAI Evaluation | Trace + Dataset + Eval | 成熟评测工作流 |
| 适用场景 | 已有 MLflow 生态、重实验管理 | 需要完整 LLM 工程闭环 | 深度 LangChain 用户 |

## 相关页面

- [[concepts/ai-agent-observability]] — 智能体可观测性整体概念
- [[concepts/evaluation-driven-development]] — 评估驱动开发方法论
- [[entities/langfuse-llm-observability]] — 开源 LLM 工程平台
