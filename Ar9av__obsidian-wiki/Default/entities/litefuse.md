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
  - "SelectDB: Litefuse 开源并推出单进程轻量模式，25 秒就能跑起来的 Agent 可观测与评估平台 (2026-06-22)"
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
updated: "2026-07-22"
relationships:
  - target: "[[apache-doris-agent-observability]]"
    type: uses
  - target: "[[langfuse]]"
    type: replaces
  - target: "[[evaluation-driven-development]]"
    type: implements
  - target: "[[entities/openclaw]]"
    type: related_to
  - target: "[[entities/langfuse-llm-observability]]"
    type: related_to
---

# Litefuse

**Litefuse** 是由飞轮科技（SelectDB）推出的开源 Agent 可观测与效果评估平台，基于 Apache Doris 构建，兼容 [[entities/langfuse-llm-observability|Langfuse]] SDK 和 100+ AI 生态集成。^[extracted]

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

Litefuse 基于 Langfuse 构建，但在存储层将 ClickHouse 替换为 Apache Doris。Agent 可观测与传统可观测的本质区别是量变引起质变：MB 长文本、跨度几天/GB 大小的超长 Trace、大量半结构化 JSON、数据量级提升，这些特点对传统存储分析引擎提出新挑战 ^[extracted]。Doris 匹配这些挑战的能力包括：

1. **成熟的倒排索引加速全文检索 10x**：支持关键词 MATCH、多关键词 MATCH_ALL、短语 MATCH_PHRASE、前缀 MATCH_PHRASE_PREFIX、词距 SLOP、正则 MATCH_REGEXP、多字段 MULTI_MATCH 等；支持英文、中文、中英文混合 IK、UNICODE ICU 分词；支持 BM25 相关性打分；PB 级存储、百 GB/s 实时写入、秒级检索。已在 MiniMax、阶跃星辰、字节、快手、腾讯、阿里、百度、网易等数百家公司生产环境验证。

2. **延迟物化降低长文本查询内存占用**：TOPN 查询排序阶段只读取时间字段，获取最终 N 条时才读取完整数据，避免大量 IO/CPU/内存消耗。

3. **分桶排序索引聚簇存储优化超长 Trace**：按 trace id hash 分桶、数据文件内按 trace id 排序、建立前缀索引，获取超长 Trace 所有 Span 时无需从分散服务器和文件中读取。

4. **VARIANT 数据类型 Native 支持半结构化 JSON**：写入时自动识别 JSON 字段名和类型，拆分成子列并采用列式存储，提升压缩率，查询时只需读取相关子列，避免 JSON 解析，通常查询速度提升 10 倍。

5. **存算分离架构降低存储成本 75%-88%**：列式存储 + ZSTD 压缩降低空间；存算分离只需在对象存储存 1 份而非本地磁盘 2-3 副本；对象存储成本仅为本地磁盘的 25%-50%。ClickHouse 开源版本不支持存算分离，Doris 开源版即支持。

### 单进程轻量模式

业界第一个极致轻量的单机单进程部署模式 ^[extracted]：

- 一个约 358MB 的二进制包，内含 Node.js 运行时、JVM 运行时、嵌入式 PGlite（Postgres）、DorisLite（嵌入式 Doris）
- 无外部运行时依赖，无需 Docker，只依赖内置 Node.js 和 JVM 运行时
- 运行只有一个进程，数据库以库的方式加载而不需要额外进程
- 一行命令 `curl -fsSL https://litefuse.ai/install.sh | sh`，约 25 秒完成部署（12 秒下载、11 秒解压安装）
- 对比 Langfuse Docker 部署（6 个容器，2 分 18 秒，且需提前准备 Docker 环境和镜像），快了 5.5 倍

单机版可处理 TB 级数据，需要扩容时可切换到分布式部署。支持 macOS (Apple silicon) 和 Linux (x64)。

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
