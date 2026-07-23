---
title: AgentLogsBench
category: references
tags: [ai, observability, benchmark, database]
sources:
  - "SelectDB: Apache Doris 在 AgentLogsBench 中领先 (2026-07-07)"
  - "SelectDB: 我们用 AI Observe Stack 观测了 OpenClaw (2026-03-04)"
summary: AgentLogsBench 是面向 AI Agent 可观测存储场景的基准测试，对比不同数据库在 Agent Trace 数据的存储、短语搜索、JSON 过滤、有序回放和实时聚合场景下的性能。Apache Doris 在综合排名中领先。
provenance:
  extracted: 0.70
  inferred: 0.25
  ambiguous: 0.05
base_confidence: 0.61
lifecycle: draft
lifecycle_changed: 2026-07-16
tier: supporting
created: 2026-07-16T00:00:00+08:00
updated: "2026-07-22"
relationships:
  - target: "[[entities/ai-observe-stack]]"
    type: related_to
  - target: "[[concepts/ai-agent-observability]]"
    type: related_to
  - target: "[[concepts/agent-harness]]"
    type: related_to
  - target: "[[concepts/agent-trace-and-timeline]]"
    type: related_to
  - target: "[[entities/loongsuite-platform]]"
    type: related_to
---

# AgentLogsBench

AgentLogsBench 是面向 **AI Agent 可观测数据存储场景**的公开基准测试，由 VeloDB 社区维护，结果在 https://velodb.github.io/agentlogsbench 实时更新。本文引用的数据来自 2026 年 5 月的测试结果。

## 测试目标

Agent 可观测对存储系统提出了不同于传统 APM 的组合需求：**短语搜索**（大文本 payload）、**动态 JSON 过滤**（半结构化字段）、**有序 Trace 回放**（按时间 + 嵌套层级）、**实时聚合**（看板查询与持续写入并行）。

AgentLogsBench 将这些需求量化为可测量的基准场景，回答"哪种数据库适合作为 Agent 可观测的存储后端"。

## 测试负载

### 数据特征
模拟真实 Agent Trace 数据：
- 大文本 Observation payload（5KB-1MB，混合自然语言、代码、JSON）
- 高度动态的 JSON 属性（模型版本、Prompt 模板、租户信息、工具参数等随每次调用变化）
- 深层次嵌套的 Trace 结构（Task → Step → LLM Call / Tool Call → Retry）

### 查询负载

| 场景 | 查询类型 | 目标延迟 |
|------|---------|---------|
| Hot Query | 高并发的简单过滤 + 聚合（如按模型统计 Token 消耗） | < 50ms |
| Cold Query | 全表扫描 + 短语搜索 + 多条件 JSON 过滤 | < 5s |
| Trace 回放 | 按 trace_id 取回完整链路，按时间排序 | < 200ms |
| 实时看板 | 聚合查询（P50/P95/P99 延迟、错误率、Token 消耗趋势） | < 100ms |

### 引擎配置
参测引擎以典型生产配置运行，未做针对性性能调优（目的是反映开箱即用的表现而非极限压测结果）。

## 2026 年 5 月结果

Apache Doris 在综合排行榜中领先，尤其体现在：

- **Hot Query Runtime** — 高并发短查询延迟最低，适合实时看板场景
- **Cold Query Runtime** — 全表短语搜索 + JSON 过滤的延迟显著低于对比引擎
- **存储效率** — 列式压缩对大文本 payload 的压缩比突出

对比引擎包括 ClickHouse、Elasticsearch 等常见可观测存储方案（完整排行榜见实时网站）。

## 对 Agent 可观测平台选型的意义

AgentLogsBench 表明：Agent 可观测的存储层选择**不是无差别的**——传统基于倒排索引的日志系统（Elasticsearch/Loki）在大文本短语搜索场景下膨胀严重，而通用 OLAP 数据库（Doris/ClickHouse）需要补充倒排索引和 VARIANT 类型才能高效处理动态 JSON 过滤和全文搜索。

这也解释了为什么 SelectDB 的 [[entities/ai-observe-stack|AI Observe Stack]] 选择 Apache Doris 作为存储引擎：它通过倒排索引 + VARIANT + MPP 查询的组合，同时覆盖了搜索引擎、OLAP 和时序数据库的能力 ^[inferred]。

## 局限性

- 基准测试使用模拟数据而非真实生产 Trace，生产环境的数据分布可能更极端
- 当前版本未覆盖多租户隔离、数据生命周期管理、备份恢复等运维维度
- 查询负载的设计基于 2026 年中期的 Agent 规模，随着 Agent 复杂度增长，基准需持续演进 ^[inferred]

## Related

- [[concepts/agent-harness]] — Harness 层的运行时数据是 AgentLogsBench 测试负载的核心数据源
- [[concepts/agent-trace-and-timeline]] — Agent Trace 的有序回放是基准测试的关键查询场景
- [[entities/loongsuite-platform]] — LoongSuite 作为采集层，其数据最终存储到 AgentLogsBench 测试的数据库中
