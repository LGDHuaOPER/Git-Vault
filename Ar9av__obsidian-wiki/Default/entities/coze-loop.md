---
title: Coze Loop
category: entities
tags:
  - ai-agent
  - observability
  - evaluation
  - agentops
  - bytedance
  - open-source
sources:
  - "数据拾光者: AI那些趣事系列123：目前主流的智能体可观测性和智能体评测相关的产品调研 (2026-05-07)"
  - "唧唧复急急: AI 智能体应用时代，可观测性怎么做？ (2026-03-27)"
summary: 字节跳动开源的 AgentOps 平台（扣子罗盘），通过全链路 Trace、性能监控、评测集与评估器闭环，以及 BadCase 自动回流，实现智能体从开发到运维的工程化迭代。
provenance:
  extracted: 0.75
  inferred: 0.20
  ambiguous: 0.05
base_confidence: 0.58
lifecycle: draft
lifecycle_changed: 2026-07-22
tier: supporting
created: 2026-07-22T00:00:00+08:00
updated: 2026-07-22T00:00:00+08:00
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

# Coze Loop

**Coze Loop**（扣子罗盘）是字节跳动推出的开源 AgentOps 平台，GitHub 地址为 https://github.com/coze-dev/coze-loop，采用 Apache 2.0 协议，约 5.4K Star。^[extracted] 它通过**评测（Evaluation）**和**观测（Observability）**两大模块，将智能体开发从"玄学炼丹"转变为"数据驱动的工程化迭代"。^[extracted]

## 核心定位

Coze Loop 主要解决智能体"开发黑盒、评测靠猜、运维抓瞎"的痛点，定位是**国内首选的智能体可观测与评测一体化平台**。^[inferred] 与 Langfuse、LangSmith 等海外平台相比，它更强调 Agent 专项能力（工具调用成功率、多步规划合理性）和 BadCase 自动回流机制。^[inferred]

## 可观测性能力

### 全链路 Trace 追踪

可观测模块像"飞行记录仪"一样还原完整决策链路：^[extracted]

- **节点级拆解**：自动记录从用户输入到最终输出的每个环节，包括 Prompt 解析、模型调用（LLM）、工具调用（Tools）、代码执行等，可清晰看到哪个节点耗时过长或报错。^[extracted]
- **中间态捕获**：不仅看结果，还能查看每一步的中间结果和变量状态，例如模型调用工具前生成的参数是否正确。^[extracted]
- **多框架集成**：提供 Go、Python、Node.js SDK，支持 Eino、LangChain 等主流框架，也支持 Coze 平台原生应用自动上报。^[extracted]

### 性能与成本监控

- **关键指标看板**：实时监控 Token 消耗、响应延迟（Latency）、错误率（Error Rate），支持按模型、应用维度拆分统计。^[extracted]
- **异常告警**：基于 Trace 数据设置预警规则，当出现高频错误或性能骤降时快速定位根因。^[extracted]

### BadCase 自动回流

这是 Coze Loop 的一大特色。系统从线上 Trace 中自动采样，对真实用户对话进行在线评测，筛选出低分（BadCase）对话，并自动回流到评测数据集中，使测试集不断吸收真实场景的边界情况，实现越用越聪明的**数据飞轮**。^[extracted]

## 评测能力

### 评测体系架构

评测流程遵循"**评测集（Dataset）→ 评估器（Evaluator）→ 实验（Experiment）**"的闭环：^[extracted]

| 组件 | 功能 | 核心能力 |
|------|------|---------|
| 评测集 | 定义"考题" | 支持 CSV 导入或手动创建，可基于 Trace 回流数据自动扩充 |
| 评估器 | 定义"评分标准" | 预置准确性、简洁性、合规性模板；支持自定义 LLM 作为裁判多维度打分 |
| 评测实验 | 执行"考试" | 将 Prompt、模型、数据集组合运行，生成可视化报告 |

### 核心评测维度

- **准确性（Accuracy）**：事实一致性、逻辑正确性。^[extracted]
- **简洁性（Conciseness）**：避免冗余废话。^[extracted]
- **合规性（Safety）**：敏感词、偏见、有害内容检测。^[extracted]
- **Agent 专项**：工具调用成功率、多步规划合理性。^[extracted]

### 多模型对比与 A/B 测试

支持在同一套评测集上对比不同模型（如 GPT-4 vs DeepSeek）或不同 Prompt 版本的表现，通过数据直观选出性价比最高的方案。^[extracted]

## 生命周期角色

| 阶段 | 核心功能 | 解决的问题 |
|------|---------|-----------|
| 开发 | Prompt 调试、多模型对比、版本管理 | 提升 Prompt 编写效率，管理迭代历史 |
| 评测 | 自动化评测实验、BadCase 分析 | 量化智能体质量，为迭代提供数据依据 |
| 观测 | 全链路 Trace、性能监控、日志审计 | 线上问题快速定位，保障稳定性与合规性 |
| 调优 | 基于评测/观测结果的 Prompt 优化 | 形成"观测-分析-优化"的闭环 |

## 与 Langfuse / LangSmith 的对比

| 维度 | Coze Loop | Langfuse | LangSmith |
|------|-----------|----------|-----------|
| 出身 | 字节跳动 | 独立开源 | LangChain 官方 |
| 协议 | Apache 2.0（完全开源） | MIT（核心开源） | 闭源 SaaS |
| 部署难度 | 中等偏上 | 极简 | 云 SaaS 为主 |
| Agent 专项 | 强（工具调用、多步规划评测） | 中 | 强 |
| 特色能力 | BadCase 自动回流 | 开源自托管、Prompt 管理 | LangChain 生态深度集成 |

## 相关页面

- [[concepts/ai-agent-observability]] — Coze Loop 实现的 Agent 可观测体系
- [[concepts/evaluation-driven-development]] — 评测驱动的智能体开发方法论
- [[entities/langfuse-llm-observability]] — 海外主流开源 LLM 可观测平台
- [[entities/langsmith]] — LangChain 官方商业可观测平台
