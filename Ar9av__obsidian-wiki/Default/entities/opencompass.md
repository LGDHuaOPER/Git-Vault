---
title: OpenCompass
category: entities
tags:
  - ai-agent
  - evaluation
  - benchmark
  - open-source
  - shanghai-ai-lab
sources:
  - "数据拾光者: AI那些趣事系列123：目前主流的智能体可观测性和智能体评测相关的产品调研 (2026-05-07)"
summary: 上海人工智能实验室开源的大模型及智能体全维度评测平台（司南评测体系），提供工具调用、任务规划、代码解释器等专项评测集，偏基准测试而非生产可观测。
provenance:
  extracted: 0.80
  inferred: 0.15
  ambiguous: 0.05
base_confidence: 0.53
lifecycle: draft
lifecycle_changed: 2026-07-22
tier: supporting
created: 2026-07-22T00:00:00+08:00
updated: 2026-07-22T00:00:00+08:00
relationships:
  - target: "[[concepts/agent-evaluation-framework]]"
    type: implements
  - target: "[[concepts/ai-agent-observability]]"
    type: related_to
  - target: "[[entities/mlflow]]"
    type: related_to
---

# OpenCompass

**OpenCompass**（司南评测体系）是由**上海人工智能实验室**开源的大模型及智能体全维度评测平台，GitHub 地址 https://github.com/open-compass/opencompass，约 7K Star，采用 Apache License 2.0 协议。^[extracted] 它不仅是业界公认的权威评测基准，也是目前国内大模型榜单的重要数据来源。^[extracted]

## 核心定位

OpenCompass 的本质是**评测框架**而非运维平台。^[extracted] 它的强项在于大模型/智能体基准测试，适合做"入学考试"而非线上监控。^[extracted] 如果团队需要生产环境的实时可观测性（Trace 链路、延迟监控），OpenCompass 不是合适选择。^[extracted]

## 智能体评测能力

OpenCompass 将智能体能力作为一级评测维度，重点考察模型在复杂任务中的表现：^[extracted]

### 工具调用能力

评测模型是否能正确调用外部工具（如计算器、API、数据库），并处理工具返回结果。^[extracted] 支持与 Lagent、LangChain 等智能体框架配合，进行端到端测试。^[extracted]

### 任务规划与推理

通过多步推理任务（如数学题、代码生成、决策任务），评估智能体的规划能力、步骤正确性以及抗幻觉能力。^[extracted]

### 代码解释器评测

专门针对"代码即工具"的场景，评估模型生成代码、执行并修正错误的能力，例如使用 CIBench 数据集。^[extracted]

## 可观测性维度

OpenCompass 中的"可观测"主要通过**评测数据反推模型内部状态**：^[extracted]

- **过程追踪**：不仅看最终答案对错，还记录智能体每一步的思考（Chain of Thought）、工具选择及中间结果，提供"黑盒"内部的执行轨迹。^[extracted]
- **多维度切片**：支持对同一模型在不同任务类型（如知识问答 vs 工具调用）上的表现进行对比，快速定位能力短板。^[extracted]
- **鲁棒性测试**：通过注入噪声或对抗性提示词，测试智能体在复杂环境下的稳定性。^[extracted]

## 架构与生态

OpenCompass 2.0 构建了"铁三角"生态：^[extracted]

| 模块 | 名称 | 功能描述 |
|------|------|---------|
| CompassKit | 评测工具链 | 核心代码库，支持分布式评测、多模态评测、主观评测等 |
| CompassHub | 基准社区 | 开源社区共建的评测数据集与基准 |
| CompassRank | 评测榜单 | 官方发布的模型能力排行榜 |

## 快速开始

```bash
# 安装（支持 pip 一键安装）
pip install opencompass

# 运行智能体相关评测示例
opencompass --config path/to/agent_eval_config.py
```

^[extracted]

## 适用场景

- 研发阶段模型能力诊断与调优。^[extracted]
- 大模型/智能体基准测试与榜单发布。^[extracted]
- 离线评估不同模型在工具调用、推理、代码等专项能力上的差距。^[extracted]

## 局限性

- 不具备生产环境的实时可观测性能力。^[extracted]
- 需要配置模型路径和数据集，上手门槛高于即开即用的可视化平台。^[inferred]
- 评测结果反映的是模型能力上限，不一定代表真实业务场景下的表现。^[inferred]

## 相关页面

- [[concepts/agent-evaluation-framework]] — 智能体评估方法论
- [[concepts/ai-agent-observability]] — 生产级可观测性体系
- [[entities/mlflow]] — 另一个支持实验管理的开源平台
