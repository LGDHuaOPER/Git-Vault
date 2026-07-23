---
title: 阿里云：从 AI Agent 到模型推理的端到端 AI 可观测实践
category: references
tags:
  - ai-agent
  - observability
  - opentelemetry
  - alibaba
  - model-inference
sources:
  - "阿里云开发者社区: 从 AI Agent 到模型推理：端到端 AI 可观测实践 (2026-07-16)"
summary: 阿里云基于 OpenTelemetry 的端到端 AI 可观测实践，覆盖 AI 应用层、AI 网关、模型推理层，重点解决用得起来、用得省、用得好的三类痛点。
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
  - target: "[[concepts/genai-observability-semconv]]"
    type: related_to
  - target: "[[entities/dify]]"
    type: related_to
  - target: "[[entities/vllm]]"
    type: related_to
  - target: "[[references/aliyun-python-probe-llm]]"
    type: related_to
---

# 阿里云：从 AI Agent 到模型推理的端到端 AI 可观测实践

## AI 应用开发的三类痛点

1. **用起来**：同样问题多次询问回答不同、换模型效果打折、响应卡住回不来
2. **用得省**：不知道每次调用消耗多少 Token、哪些应用消耗高
3. **用得好**：回答质量是否达标、是否存在不合理不合规内容 ^[extracted]

## 典型架构分层

从用户业务层 → AI 应用层（AI Agent）→ 模型服务层，中间通过 API 网关（如 Higress）和 AI 网关做流量防护、Token 限流、敏感信息过滤、模型内容缓存、多模型切换 ^[extracted]。

## 基于 Trace 的全链路诊断

基于 OpenTelemetry 规范，从用户端侧、API 网关、AI 应用层、AI 网关到模型层进行埋点。网关层手动埋点，应用层和模型内部层采用无侵入自动埋点，最终上报阿里云可观测平台 ^[extracted]。

AI 应用内部对 RAG、工具使用、模型调用等关键节点埋点；模型推理阶段（如 [[entities/vllm|vLLM]]/SGLang）本身也是 Python 程序，可部署探针采集内部推理信息 ^[extracted]。

## AI 应用黄金三指标

与传统微服务黄金三指标（请求数、错误、耗时）类比，AI 应用的黄金三指标可能是 **Token、Error、Duration** ^[extracted]。

关键性能指标：
- **TTFT**（Time to First Token）：首包延迟，反映响应速度
- **TPOT**（Time Per Output Token）：每输出 Token 平均耗时，反映生成效率和流畅度
- **吞吐率**：模型同时支撑的推理请求数
- **GPU 利用率、KV Cache 命中率**：基础设施层指标 ^[extracted]

## Python 探针无侵入埋点

基于 OpenTelemetry Python Agent 底座扩展，支持 [[entities/dify|Dify]]、LangChain、LlamaIndex 等框架。利用 Python monkey patch 机制，在原始方法执行前后插入采集逻辑，实现用户代码不修改即可采集 ^[extracted]。

相比开源探针，阿里云方案增强了对多进程（unicorn/gunicorn）、gevent 协程、流式上报等生产场景的支持，解决了开源探针在 gevent 模式下卡死进程的问题 ^[extracted]。

## MCP Token 黑洞问题

使用 MCP 工具的 Agent 可能最终输出 1000 Token，但背后调用几十次模型、大量 MCP Tools，实际消耗上万个 Token。中间每次调用都把历史对话和工具结果作为 input 再发给大模型，Token 消耗不断叠加。因此需要采集每个 MCP Tool 的调用耗时和 Token 消耗 ^[extracted]。

## 相关页面

- [[entities/loongsuite-platform]] — 阿里云 LoongSuite 可观测产品体系
- [[concepts/ai-agent-observability]] — Agent 可观测性整体概念
- [[concepts/genai-observability-semconv]] — OpenTelemetry GenAI 语义规范
- [[references/aliyun-python-probe-llm]] — 阿里云 Python 应用可观测：解决 LLM 落地最后一公里
