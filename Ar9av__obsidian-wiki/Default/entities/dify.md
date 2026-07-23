---
title: Dify
category: entities
tags:
  - ai-agent
  - llmops
  - low-code
  - observability
  - open-source
sources:
  - "阿里云开发者社区: 从 AI Agent 到模型推理：端到端 AI 可观测实践 (2026-07-16)"
  - "千问AI平台: 详解大模型应用可观测全链路 (2025-03-13)"
summary: 开源 LLMOps 平台，通过声明式 YAML 定义 AI 应用，提供可视化 Prompt 编排、运营和数据集管理，广泛用于快速构建 LLM 应用和 Agent。
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

# Dify

**Dify.AI** 是一款简单易用且开源的 LLMOps 平台，帮助开发者更简单、更快速地创建 AI 应用。其核心理念是通过可声明式的 YAML 文件定义 AI 应用的各个方面，包括 Prompt、上下文和插件等，并提供可视化的 Prompt 编排、运营、数据集管理等功能 ^[extracted]。

## 系统架构

请求从前端进入，通过 Nginx 反向代理到达 Flask 部署的 API 后端。复杂任务放入 Redis，由 worker 组件执行后台任务，数据存储在对象存储和 PostgreSQL 中 ^[extracted]。

## 生产实践建议

1. **Nginx 上传限制**：文档上传可能超过默认限制，建议调大 `NGINX_CLIENT_MAX_BODY_SIZE`
2. **PGSQL 连接池**：Dify workflow 运行时会保持数据库连接，默认连接池较小，建议调大到 300 以上
3. **Redis 高可用**：Redis 同时承担缓存和消息队列职责，建议用哨兵模式或替换为消息队列（如 RocketMQ）
4. **向量数据库与对象存储**：建议将本地存储替换为第三方向量数据库和云存储，提升高可用性
5. **可观测性**：Dify 内置可观测能力但需每个应用单独配置，维度相对单一，数据存 PGSQL 在规模大时查询效率低 ^[extracted]

## 可观测性集成

使用阿里云 Python Agent 等基于 OpenTelemetry 的探针可以解决 Dify 内置可观测的局限：一次接入所有应用生效，将 Dify 内部流程与外部微服务调用、模型推理完整串起来，支持 workflow 每步的 input/output 和 Token 消耗分析，并解决 gevent 协程下开源探针卡死的问题 ^[extracted]。

## 相关页面

- [[entities/loongsuite-platform]] — 阿里云可观测对 Dify 的集成支持
- [[references/aliyun-end-to-end-ai-observability]] — Dify 生产实践与可观测
- [[references/aliyun-llm-observability-full-chain]] — Dify 自动化埋点实战
