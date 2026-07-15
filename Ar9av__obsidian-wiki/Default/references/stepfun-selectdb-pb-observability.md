---
title: "StepFun SelectDB PB-Scale Agent Observability"
category: references
tags:
  - ai-agent
  - observability
  - apache-doris
  - selectdb
  - large-scale
sources:
  - "SelectDB: 阶跃星辰基于 SelectDB 构建 PB 级 Agent 可观测平台 (2026-06-26)"
summary: "阶跃星辰（StepFun）基于 SelectDB（Apache Doris）构建 PB 级 Agent 可观测平台的架构实践——如何用列式分析型数据库承载海量 Agent trace 数据的实时写入与多维分析。"
base_confidence: 0.47
lifecycle: draft
lifecycle_changed: "2026-07-16"
tier: supporting
provenance:
  extracted: 0.3
  inferred: 0.5
  ambiguous: 0.2
created: 2026-07-16
updated: 2026-07-16
---

# StepFun SelectDB PB-Scale Agent Observability

阶跃星辰（StepFun）作为国内领先的大模型公司，面对海量 Agent 调用产生的 trace 数据，选择了基于 SelectDB（Apache Doris）构建 PB 级 Agent 可观测平台 ^[extracted]。

## 为什么选择 SelectDB

在大规模 Agent 可观测场景中，传统方案面临的核心挑战：

- **写入压力**：每秒数十万条 Agent trace 数据（每个 Span 一条记录）
- **查询需求**：需要按时间范围、模型、用户、任务类型等多维度实时聚合分析
- **成本约束**：PB 级数据量下，ClickHouse 集群的资源成本显著

SelectDB（Apache Doris 的企业发行版）的优势 ^[extracted]：
- **列式存储 + MPP 架构**：高吞吐写入（百万行/秒）+ 亚秒级聚合查询
- **统一存储**：替代 Langfuse 架构中的 ClickHouse + PostgreSQL 双存储，减少运维复杂度
- **高压缩比**：列式存储对时序型 trace 数据的压缩率远高于行式存储

## 架构要点

阶跃星辰的方案将 Agent trace 数据直接写入 SelectDB，通过 Doris 的聚合能力实现实时分析 ^[inferred]：

```
Agent 服务 → OpenTelemetry SDK → Kafka（缓冲） → SelectDB（存储+分析）
                                                          ↓
                                                    Grafana / 自定义仪表盘
```

关键设计决策：
- Kafka 作为写入缓冲，平滑峰值流量
- SelectDB 同时承担实时写入和离线分析，不需要 Lambda 架构
- 利用 Doris 的物化视图预聚合常用指标（P50/P95 延迟、Token 消耗、成功率）

## 对 Litefuse 的启示

阶跃星辰的实践验证了 Doris 在 Agent 可观测场景中的可行性，这也是 [[litefuse-doris-native-observability|Litefuse]] 选择 Doris 作为底层存储的基础——Litefuse 将这种架构封装成了开箱即用的可观测平台 ^[inferred]。

## 相关页面

- [[litefuse-doris-native-observability]] — Doris 原生的轻量级可观测平台
- [[langfuse-platform]] — 基于 ClickHouse 的开源方案
- [[agent-observability-fundamentals]] — 可观测性基础概念
