---
title: vLLM
category: entities
tags:
  - ai-agent
  - model-inference
  - observability
  - open-source
  - python
sources:
  - "阿里云开发者社区: 从 AI Agent 到模型推理：端到端 AI 可观测实践 (2026-07-16)"
summary: 开源大模型推理加速框架，通过 PagedAttention、KV Cache 复用等技术提升推理效率，其 Python 程序特性使其可被 OpenTelemetry 探针无侵入观测。
base_confidence: 0.68
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
---

# vLLM

**vLLM** 是市面上著名的开源大模型推理加速框架之一（另一个是 SGLang），通过内存分块、KV Cache 复用等方式大幅加速模型推理效率 ^[extracted]。

## 核心能力

- **PagedAttention**：将注意力机制中的 KV Cache 分块管理，提高内存利用率和吞吐
- **KV Cache 复用**：减少重复计算，降低推理延迟
- **高吞吐推理**：适合高并发在线推理场景

## 可观测性

由于 vLLM 本身也是一个 Python 程序，可以使用 OpenTelemetry Python Agent 无侵入地采集其内部流转细节，包括调用链和核心指标：
- **TTFT**（Time To First Token）
- **TPOT**（Time Per Output Token）
- 请求排队情况
- GPU 利用率、KV Cache 命中率 ^[extracted]

## 真实案例

通过 AI 网关发现调用自建 DeepSeek 模型耗时特别高，全链路追踪定位到问题在模型推理层。TTFT 和 TPOT 均正常，进一步检查发现请求在推理引擎中排队，最终通过调大推理引擎请求队列大小配置解决 ^[extracted]。

## 相关页面

- [[entities/loongsuite-platform]] — 阿里云可观测对 vLLM 的采集支持
- [[references/aliyun-end-to-end-ai-observability]] — 端到端可观测实践案例
- [[concepts/ai-agent-observability]] — Agent 可观测性整体概念
