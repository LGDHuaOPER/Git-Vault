---
title: Apache Doris 在 AgentLogsBench 中领先
category: references
tags:
  - ai-agent
  - observability
  - apache-doris
  - benchmark
  - storage-engine
sources:
  - "SelectDB: Apache Doris 在 AgentLogsBench 中领先，支撑 Agent 可观测性生产负载 (2026-07-07)"
summary: 2026 年 5 月 AgentLogsBench 结果显示 Apache Doris 在面向 Agent 可观测的混合负载 benchmark 中以 1.28 倍 slowdown 领先，支撑短语搜索、动态 JSON 过滤、trace 回放和实时看板刷新。
base_confidence: 0.78
lifecycle: draft
lifecycle_changed: "2026-07-22"
tier: supporting
provenance:
  extracted: 0.80
  inferred: 0.15
  ambiguous: 0.05
created: "2026-07-22"
updated: "2026-07-22"
relationships:
  - target: "[[entities/apache-doris-agent-observability]]"
    type: related_to
  - target: "[[references/agentlogsbench]]"
    type: related_to
  - target: "[[entities/litefuse]]"
    type: related_to
  - target: "[[concepts/ai-agent-observability]]"
    type: related_to
---

# Apache Doris 在 AgentLogsBench 中领先

## Agent 可观测的新型负载特征

[[concepts/ai-agent-observability|Agent 可观测性]]与传统可观测性的差异：
- 文本主体庞大且无结构（5KB 到 1MB）
- 关键分析字段高度动态（模型版本、prompt 模板、发布环、客户等级等位于动态 JSON payload）
- Trace 是有序链路，不是扁平日志
- 实时看板必须与持续写入并存 ^[extracted]

这要求系统同时具备**短语搜索、动态 JSON 过滤、有序 trace 回放和实时聚合能力**——本质上是一个混合负载数据系统问题 ^[extracted]。

## AgentLogsBench 设计

Benchmark 位于 `velodb/agentlogsbench` 仓库，使用同一套工作负载对比 Apache Doris、ClickHouse、DuckDB、Elasticsearch、OpenSearch 和 PostgreSQL。核心指标是相对每个查询最快结果的 slowdown 几何平均值，数值越低越好 ^[extracted]。

评分对象是 `agent_observations` 单表：稳定字段提升为列，其他内容放在动态 `payload` 中。数据规模 M 级约 1 亿行，input 正文从 5KB 到 1MB 不等 ^[extracted]。

20 个查询按四类访问模式分组：trace 回放、多短语事故搜索、动态 payload 过滤、结构化文本检索 / 看板刷新。

## 测试结果

- **综合排行榜**：Apache Doris 以 1.28 倍领先
- **Hot 场景**：Doris 以 1.14 领先，比 Elasticsearch/OpenSearch 快约 3 倍，比 ClickHouse 快约 17 倍
- **Cold 场景**：Doris 以 1.60 领先，略优于 Elasticsearch 的 1.65
- **存储占用**：Doris 57.94 GiB，Elasticsearch/OpenSearch 需要 3-4 倍更多存储
- **加载性能**：ClickHouse 第一（2755 秒），Doris 第二（4396 秒）^[extracted]

## Doris 领先的四项架构能力

1. **倒排索引**：`input` 和 `output` 列上的倒排索引让短语搜索由索引驱动；Doris 4.1 的 `search()` 函数支持类 Lucene 表达式
2. **VARIANT 子列存储**：动态 JSON 路径可提升为 typed subcolumn，热路径按列式速度执行，无需 schema migration
3. **HASH(trace_id) 分布 + DUPLICATE KEY**：同一 trace 的 observation 落在同一 tablet 并按 seq_no 排序，trace replay 退化为顺序读取
4. **分区裁剪、Bloom filter、zone map、Condition Cache、Query Cache**：看板刷新可扛住并发写入 ^[extracted]

## 相关页面

- [[entities/apache-doris-agent-observability]] — Apache Doris 在 Agent 可观测性中的技术原理
- [[references/agentlogsbench]] — Agent 可观测存储基准测试
- [[entities/litefuse]] — 基于 Doris 的 Agent 可观测与评估平台
