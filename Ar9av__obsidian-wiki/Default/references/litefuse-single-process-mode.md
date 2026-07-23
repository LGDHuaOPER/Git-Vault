---
title: Litefuse 单进程轻量模式
category: references
tags:
  - ai-agent
  - observability
  - apache-doris
  - litefuse
  - evaluation
sources:
  - "SelectDB: Litefuse 开源并推出单进程轻量模式，25 秒就能跑起来的 Agent 可观测与评估平台 (2026-06-22)"
summary: SelectDB 2026 年 6 月宣布 Litefuse 开源并推出业界首个单进程轻量模式，约 25 秒完成单机部署，基于 Apache Doris 解决 Agent 可观测的长文本、超长 Trace、半结构化数据、成本挑战。
provenance:
  extracted: 0.72
  inferred: 0.23
  ambiguous: 0.05
base_confidence: 0.55
lifecycle: draft
lifecycle_changed: 2026-07-22
tier: supporting
created: 2026-07-22T00:00:00+08:00
updated: "2026-07-22"
relationships:
  - target: "[[entities/litefuse]]"
    type: related_to
  - target: "[[entities/apache-doris-agent-observability]]"
    type: related_to
---

# [[entities/litefuse|Litefuse]] 单进程轻量模式

> 原文：Litefuse 开源并推出单进程轻量模式，25 秒就能跑起来的 Agent 可观测与评估平台（SelectDB，2026-06-22）

## 为什么要做单机版

私有化环境中多数可观测产品依赖 Docker 启动：拉取镜像几个 GB、起一堆容器、后续维护复杂。Litefuse 推出单进程模式，让用户用最简单方式在单机跑起 Agent 可观测与评估。

## 单进程版特点

- **一个二进制包，体积不到 400MB**：内含 Node.js 运行时、JVM 运行时、PGlite 嵌入式 Postgres、DorisLite 嵌入式 Doris。
- **无其他运行时依赖**：无需外部依赖，无需 Docker。
- **只有一个进程**：数据库以库的方式加载，无需额外进程。
- **一行命令部署**：`curl -fsSL https://litefuse.ai/install.sh | sh`，约 25 秒完成（12 秒下载 358MB 安装包、11 秒解压安装）。

支持 macOS (Apple silicon) 和 Linux (x64)。

## 为什么选择 Apache Doris

Agent 可观测与传统可观测的本质区别是量变引起质变：

- **MB 长文本**：单次请求输入输出可能 MB 级别，传统 LIKE 检索慢且内存消耗大。
- **超长 Trace**：复杂 Agent 任务可能运行数小时甚至数天，Span 数可达几万，Trace 大小可达 GB。
- **大量半结构化数据**：Agent 输入输出大量 JSON，需要 Native 支持。
- **数据量提升一个量级**：存储成本大幅增加。

Apache Doris 的五项能力匹配这些挑战：

1. **成熟的倒排索引**：支持关键词、短语、前缀、正则、多字段检索，中英文分词，BM25 打分，秒级响应。
2. **延迟物化**：排序阶段只读取时间字段，获取最终 N 条时才读完整数据，降低长文本查询内存占用。
3. **分桶排序索引聚簇存储**：按 trace id hash 分桶、排序、前缀索引，快速获取超长 Trace 所有 Span。
4. **VARIANT 数据类型**：JSON 自动拆分子列、列式存储，提升压缩率并避免 JSON 解析开销。
5. **存算分离架构**：开源版支持，数据存对象存储 1 份，存储成本降低 75%-88%。

## 生态与部署

- GitHub：https://github.com/litefuse/litefuse
- 官网：https://litefuse.ai
- SaaS：https://litefuse.cloud（免费额度）
- 阿里云 SelectDB 可开启独享 Litefuse 实例
