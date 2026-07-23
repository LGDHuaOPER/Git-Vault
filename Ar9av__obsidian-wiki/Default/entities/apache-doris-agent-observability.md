---
title: "Apache Doris 在 Agent 可观测性中的应用"
category: entities
tags:
  - apache-doris
  - ai-agent
  - observability
  - storage-engine
sources:
  - "数栖云间: Apache Doris 在 AI Agent 可观测性中的架构实践 (2026-03-12)"
  - "SelectDB: Litefuse 开源并推出单进程轻量模式 (2026-06-22)"
  - "一臻数据: 正式开源！Doris 驱动的Agent观测平台 (2026-07-05)"
  - "SelectDB: Apache Doris 在 AgentLogsBench 中领先，支撑 Agent 可观测性生产负载 (2026-07-07)"
summary: "Apache Doris 如何通过 VARIANT 类型、倒排索引、PipelineX 执行引擎和存算分离架构，成为 AI Agent 可观测性场景的理想存储分析引擎。"
base_confidence: 0.63
lifecycle: draft
lifecycle_changed: "2026-07-16"
tier: supporting
provenance:
  extracted: 0.70
  inferred: 0.23
  ambiguous: 0.07
created: "2026-07-16"
updated: "2026-07-22"
relationships:
  - target: "[[litefuse]]"
    type: related_to
  - target: "[[agent-observability-paradigm]]"
    type: related_to
  - target: "[[concepts/ai-agent-observability]]"
    type: related_to
  - target: "[[references/agentlogsbench]]"
    type: related_to
  - target: "[[entities/langfuse-llm-observability]]"
    type: related_to
---

# Apache Doris 在 [[concepts/ai-agent-observability|Agent 可观测性]]中的应用

Apache Doris 是一个基于 MPP 架构的高性能实时分析型数据库。在 AI Agent 可观测性场景中，Doris 凭借四个核心能力成为理想的数据引擎。^[extracted]

## Agent Trace 数据的特殊挑战

Agent 可观测数据与传统的微服务 Trace 有量变到质变的差异 ^[extracted]：

| 挑战 | 特征 | 传统方案的局限 |
|------|------|---------------|
| **MB 级长文本** | 单次 I/O 可达 MB 级，百万 token 上下文 | LIKE 硬匹配极慢；全量加载到内存需 10GB+ |
| **超长 Trace** | 数小时到数天，几万 Span，总数据达 GB | 读取分散在多文件中的 Span 很慢 |
| **大量半结构化 JSON** | input/output 和 metadata 都是 JSON | 行存读取 + 解析开销巨大 |
| **数据量提升一个量级** | 日均 TB 级 | 存储成本激增 |

## 核心能力

### 1. VARIANT 类型：动态列式化

Doris 的 VARIANT 类型专为半结构化 JSON 设计 ^[extracted]：

- **自动字段提取**：写入时将高频字段（`trace_id`、`span_id`、`timestamp`）提取为独立列，享受列式压缩和查询加速
- **动态扩展**：新增字段无需 DDL，通过 Light Schema Change 秒级完成
- **嵌套结构保留**：复杂嵌套 JSON（如 LLM 的 `tool_calls` 数组）保持原始结构，支持 JSON Path 查询
- **压缩率**：相比 Elasticsearch，压缩率达 5:1 到 10:1，存储成本降低 50%-80%

在查询时，只需读取相关字段的子列，不需要先扫整行再解析 JSON——查询速度通常提升 10 倍。^[extracted]

### 2. 倒排索引：全文检索加速 10x

Doris 3.0 版本针对可观测场景的专项优化 ^[extracted]：

- 支持关键词（MATCH）、多关键词（MATCH_ALL）、短语（MATCH_PHRASE）、前缀、正则、多字段混合检索
- 支持 BM25 相关性打分和排序
- 支持中英文分词（IK、UNICODE ICU）
- **批量索引构建**：写入性能提升 5 倍
- **分区裁剪结合**：先按时间范围裁剪分区，再在分区内索引检索
- 实测：在 7 天数百万条日志中检索包含特定关键词（如 "ignore previous instructions"）的记录，毫秒级响应 vs ClickHouse 全表扫描 3-10 秒

### 3. PipelineX 执行引擎

传统火山模型的两个瓶颈 ^[extracted]：上游算子阻塞等待、逐行处理导致 CPU 缓存命中率低。

PipelineX 改进：
- **算子融合**：多个算子融合为 Pipeline，数据在内存中流式传递
- **Local Shuffle**：单机内数据重分布，避免数据倾斜
- **向量化执行**：每次处理一批数据（Batch），利用 SIMD 指令加速

典型查询场景（"统计过去 1 小时各工具的调用次数和平均延迟"）：扫描、过滤、聚合三算子融合，延迟从 5-10 秒降至 1-2 秒。^[extracted]

### 4. 延迟物化

处理 "取最新 Top N 条 Trace" 这类高频查询时 ^[extracted]：排序阶段只读时间戳字段，Top N 确定后才读完整记录，避免将大量 MB 级长文本加载进内存。

### 5. 分桶排序与 Trace 聚簇存储

按 `trace_id` hash 分桶 + 数据文件内部按 `trace_id` 排序 + prefix index ^[extracted]：分析完整 Trace 时可以范围 scan 快速拿到所有 Span，不用在分散的服务器和文件中散点查找。

### 6. 存算分离降低成本

数据写一份存对象存储（OSS/HDFS），不需要多副本；对象存储单价仅为本地磁盘的 25%-50%。开源版本即支持存算分离（对比 ClickHouse 开源版不支持）。^[extracted]

综合效果：相比 ClickHouse 方案，存储成本降低 **75% 到 88%**。^[extracted]

## 生态集成

Doris 通过标准协议融入云原生可观测生态 ^[extracted]：

- **OpenTelemetry Exporter**：社区提供 Doris Exporter，OTel Collector 采集数据直接 HTTP API 写入
- **MySQL 协议兼容**：Grafana 通过 MySQL Datasource 连接，标准 SQL 查询
- **Elasticsearch 协议兼容（规划中）**：未来支持 Kibana 直接连接，ELK 用户零成本迁移

## 生产验证

在 MiniMax、阶跃星辰、字节跳动、快手、腾讯、阿里、百度、网易等数百家公司的 PB 级生产环境中大规模应用。^[extracted]

## [[references/agentlogsbench|AgentLogsBench]] 性能验证

AgentLogsBench 是专门面向 Agent 可观测混合负载设计的 benchmark，使用单表 `agent_observations` 同时测试短语搜索、动态 JSON 过滤、有序 trace 回放和实时看板刷新 ^[extracted]。

2026 年 5 月 M 级（约 1 亿行）测试结果：
- **综合排行榜**：Doris 以 1.28 倍 slowdown 领先
- **Hot 场景**：Doris 1.14 倍，比 Elasticsearch/OpenSearch 快约 3 倍，比 ClickHouse 快约 17 倍
- **Cold 场景**：Doris 1.60 倍，略优于 Elasticsearch 的 1.65
- **存储占用**：Doris 57.94 GiB，Elasticsearch/OpenSearch 需要 3-4 倍存储
- **Trace 回放（Q03/Q04 hot）**：Doris 0.020s/0.036s vs ClickHouse 2.289s/2.411s
- **多短语搜索（Q13/Q15 hot）**：Doris 0.088s/0.081s vs Elasticsearch 1.094s/1.392s vs ClickHouse 9.3s/9.5s
- **动态 payload 过滤（Q16/Q17 hot）**：Doris 0.078s/0.030s ^[extracted]

Doris 领先的四项架构能力：倒排索引、VARIANT 分层子列存储、HASH(trace_id) 分布 + DUPLICATE KEY 排序、分区裁剪与缓存机制。^[extracted]

## 相关页面

- [[litefuse]] — 基于 Doris 构建的 Agent 可观测平台
- [[agent-observability-paradigm]] — 为什么 Agent 需要新的数据引擎
- [[langfuse]] — 基于 ClickHouse 的对比方案
- [[references/apache-doris-agentlogsbench-leadership]] — AgentLogsBench 领先详情
