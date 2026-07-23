---
title: 阿里云：详解大模型应用可观测全链路
category: references
tags:
  - ai-agent
  - observability
  - alibaba
  - opentelemetry
  - dify
sources:
  - "千问AI平台: 详解大模型应用可观测全链路 (2025-03-13)"
summary: 阿里云面向 QwQ/DeepSeek 等 LLM 应用的可观测解决方案，覆盖采集治理、领域视图、根因定位，并给出 Dify 自动化埋点与端到端链路追踪实战。
base_confidence: 0.72
lifecycle: draft
lifecycle_changed: "2026-07-22"
tier: supporting
provenance:
  extracted: 0.75
  inferred: 0.20
  ambiguous: 0.05
created: "2026-07-22"
updated: "2026-07-22"
relationships:
  - target: "[[entities/loongsuite-platform]]"
    type: related_to
  - target: "[[concepts/ai-agent-observability]]"
    type: related_to
  - target: "[[references/caict-llm-observability-standard]]"
    type: related_to
  - target: "[[entities/dify]]"
    type: related_to
  - target: "[[entities/langfuse-llm-observability]]"
    type: related_to
  - target: "[[entities/langsmith]]"
    type: related_to
---

# 阿里云：详解大模型应用可观测全链路

## 大模型可观测的挑战

从模型层到应用层面临四类挑战：性能与成本（GPU 利用率不理想）、使用与开发体验（链路长、定位慢）、效果评估（输出不可预测和幻觉）、安全合规（内容风险）^[extracted]。

## 典型 LLM 应用组件

- **AI 网关**：对接不同 LLM 服务，满足大小模型混合使用，故障时自动切换
- **内容安全**：引入 Moderation 和 Guardrails 进行内容审查和提示词防御
- **工具调用**：调用外部工具或服务完成具体操作
- **RAG 技术**：基于向量数据库优化上下文和长期记忆
- **缓存技术**：命中缓存提升效率、降低成本 ^[extracted]

## 必备可观测能力

成熟平台需要支持：端侧不同形态数据接入、领域化分析视图、场景化分析能力、端到端全链路分析、大盘和告警 ^[extracted]。

## LLM 领域指标

模型推理性能指标：
- **TTFT**（Time to First Token）：生成第一个 token 所需时间
- **TBT**（Time Between Tokens）：相邻 token 之间的时间间隔
- **TPOT**（Time Per Output Token）：每个输出 token 的平均时间 ^[extracted]

评估场景从准确性、有毒性、幻觉等角度评估性能、安全性和可靠性。

## 无侵入采集

阿里云 Python Agent 基于 OpenTelemetry Python Agent 底座，支持 LlamaIndex、LangChain、通义千问、OpenAI、[[entities/dify|Dify]]、PromptFlow 等国内外框架和模型。利用框架 Callback 机制和 wrapper 原理实现无侵入埋点 ^[extracted]。

## 用户体验监控差异

LLM 应用与传统 Web/移动应用在用户体验监控方面的差异：
- 内容质量：首次回答准确率、幻觉率
- 交互效率：用户中断率、多轮对话平均轮次、意图修正频率
- 会话关联：LLM 应用会话与传统应用会话没有本质区别，可进行关联分析 ^[extracted]

## Dify 自动化埋点实战

Dify 默认集成的 [[entities/langfuse-llm-observability|Langfuse]] 和 [[entities/langsmith|LangSmith]] 偏向 LLM 领域，缺乏端到端完整分析能力。阿里云 Python Agent 针对 Dify 内部执行链路精细埋点，基于 OTel 标准与上下游串联，可定位流程执行、工具调用、异常分析 ^[extracted]。

部署方式：安装 ack-onepilot、使用 aliyun-bootstrap 安装探针、通过 `aliyun-instrument python app.py` 启动应用，在 ARMS 工作台查看调用链详情 ^[extracted]。

## 相关页面

- [[entities/loongsuite-platform]] — 阿里云 LoongSuite 可观测产品体系
- [[references/caict-llm-observability-standard]] — 中国信通院 LLM 应用可观测性标准
- [[concepts/ai-agent-observability]] — Agent 可观测性整体概念
