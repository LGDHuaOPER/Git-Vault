---
title: "Litefuse"
category: entities
tags:
  - ai-agent
  - observability
  - apache-doris
  - evaluation
  - open-source
sources:
  - "SelectDB: Litefuse 开源并推出单进程轻量模式 (2026-06-22)"
  - "一臻数据: Litefuse 正式发布！Doris 原生 Agent 可观测平台来了 (2026-05-21)"
  - "一臻数据: 正式开源！Doris 驱动的Agent观测平台 (2026-07-05)"
  - "SelectDB: Agent 时代为什么需要新的可观测范式？ (2026-05-21)"
  - "SelectDB: Litefuse 正式发布：Agent 可观测与效果评估，比 Langfuse 成本低 88% (2026-05-15)"
summary: "基于 Apache Doris 构建的开源 Agent 可观测与评估平台，兼容 Langfuse SDK，存储成本降低 65%-88%，支持单进程 25 秒极简部署。"
base_confidence: 0.63
lifecycle: draft
lifecycle_changed: "2026-07-16"
tier: supporting
provenance:
  extracted: 0.65
  inferred: 0.25
  ambiguous: 0.10
created: "2026-07-16"
updated: "2026-07-16"
relationships:
  - target: "[[apache-doris-agent-observability]]"
    type: uses
  - target: "[[langfuse]]"
    type: replaces
  - target: "[[evaluation-driven-development]]"
    type: implements
  - target: "[[entities/openclaw]]"
    type: related_to
---

# Litefuse

**Litefuse** 是由飞轮科技（SelectDB）推出的开源 Agent 可观测与效果评估平台，基于 Apache Doris 构建，兼容 Langfuse SDK 和 100+ AI 生态集成。^[extracted]

- **GitHub**：https://github.com/litefuse/litefuse
- **官网**：https://litefuse.ai
- **SaaS**：https://litefuse.cloud (免费额度)
- **协议**：MIT
- **核心作者**：肖康（飞轮科技副总裁，Apache Doris PMC Member）

## 核心定位

Litefuse 将 [[evaluation-driven-development]]（EDD）方法论产品化，提供 Trace 采集、可视化分析、数据集管理、实验运行与评估的完整闭环。^[extracted]

核心价值主张 ^[inferred]：
1. 不止于记录 Agent 行为，更注重效果评估和持续优化
2. 面向 AI 语义（LLM 请求、Tool 调用、Retrieval、Token）的原生支持
3. 极低的总拥有成本（存储成本降低 65%-88%）

## 架构亮点

### 存储引擎：Apache Doris 替代 ClickHouse

Litefuse 基于 Langfuse 构建，但在存储层将 ClickHouse 替换为 Apache Doris，原因三方面 ^[extracted]：

1. **存储成本**：Doris VARIANT 类型自动将 JSON 字段按列拆分存储，压缩率 5:1-10:1；存算分离架构只需存一份数据到对象存储。实测短对话节省 65%、长对话节省 88%。

2. **全文检索**：Doris 倒排索引支持关键词、短语、前缀、正则和多字段混合检索，中英文分词全覆盖，秒级响应，比 LIKE 快 5-10 倍。已在 MiniMax、字节、快手、腾讯等公司的 PB 级生产环境验证。

3. **部署简化**：Doris 去掉了 MinIO 写入缓冲层（利用实时写入和 group commit），Redis 队列功能用 PostgreSQL 插件替代，组件从 6 个压缩到 3 个。

### 单进程轻量模式

业界第一个极致轻量的单机单进程部署模式 ^[extracted]：

- 一个约 358MB 的二进制包，内含 Node.js 运行时、JVM 运行时、嵌入式 PGlite（Postgres）、DorisLite（嵌入式 Doris）
- 无外部运行时依赖，无需 Docker
- 运行只有一个进程
- 一行命令 `curl -fsSL https://litefuse.ai/install.sh | sh`，约 25 秒完成部署
- 对比 Langfuse Docker 部署（6 个容器，2 分 18 秒），快了 5.5 倍

单机版可处理 TB 级数据，需要扩容时可切换到分布式部署。

### Claude Code / Hermes / OpenClaw 增强支持

Litefuse 对通用 Agent 做了专门增强 ^[extracted]：不只记录模型调用请求和响应，而是捕获完整的执行步骤——user message、thinking 过程、text response、工具调用细节和元数据。

接入方式：直接把 `Read https://litefuse.ai/SKILL.md and follow the instructions to install and configure Litefuse.` 扔给 Agent 即可。

## 与 Langfuse 的对比

| 维度 | Langfuse | Litefuse |
|------|----------|----------|
| 存储引擎 | ClickHouse + PostgreSQL | Apache Doris + PGlite |
| 部署组件 | 6 个（Web/Worker/Redis/MinIO/PG/CK） | 3 个（或单进程） |
| 存储成本 | 基准 | 节省 65%-88% |
| 全文检索 | LIKE（全表扫描） | 倒排索引（秒级） |
| 存算分离 | 仅企业版 | 开源版支持 |
| Agent 支持 | 通用 LLM Trace | 增强 Agent 语义 |

## 相关页面

- [[apache-doris-agent-observability]] — Doris 在可观测性中的技术原理
- [[langfuse]] — 被 Litefuse 兼容和优化的上游平台
- [[evaluation-driven-development]] — Litefuse 实现的方法论
- [[agent-observability-paradigm]] — 需要 Agent 可观测平台的根本原因
- [[entities/openclaw]] — OpenClaw 的安全事件是 Agent 可观测平台需求的核心驱动力
