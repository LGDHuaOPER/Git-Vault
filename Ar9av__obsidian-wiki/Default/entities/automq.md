---
title: AutoMQ
category: entities
tags:
  - observability
  - kafka
  - cloud-native
  - s3
  - open-source
sources:
  - "DeepFlow: 从 eBPF 到 LLM：可观测性管道的每一层都在变｜上海 Meetup 回顾 (2026-04-28)"
summary: 基于共享存储架构的云原生 Diskless Kafka，100% 兼容 Kafka 协议，通过 S3 Stream 引擎实现秒级扩缩容、跨 AZ 零流量费和低成本可观测数据管道。
provenance:
  extracted: 0.75
  inferred: 0.20
  ambiguous: 0.05
base_confidence: 0.53
lifecycle: draft
lifecycle_changed: 2026-07-22
tier: supporting
created: 2026-07-22T00:00:00+08:00
updated: 2026-07-22T00:00:00+08:00
relationships:
  - target: "[[entities/deepflow]]"
    type: related_to
  - target: "[[entities/greptimedb]]"
    type: related_to
---

# AutoMQ

**AutoMQ** 是基于共享存储架构的新一代 **Diskless Kafka**，fork Kafka 代码后将存储层替换为自研流存储引擎 **S3 Stream**，100% 兼容 Kafka 协议。^[extracted] 它主要解决传统 Kafka 在云原生环境下的架构错配问题：云盘贵、计算存储耦合导致扩缩容困难、分区数据迁移动辄数小时、跨可用区流量费高昂。^[extracted]

## 核心设计

### 存算分离

所有数据存在对象存储上，Broker 完全无状态：^[extracted]

- 不需要多副本复制
- 跨 AZ 流量费消除
- 分区迁移只移动 metadata 而不搬数据，秒级完成
- 集群内置 controller 实时监控负载，自动做 partition 流量均衡

### WAL Storage 抽象层

对象存储写入延迟高（典型 P99 百毫秒级），AutoMQ 引入 WAL Storage 抽象层解决：^[extracted]

- 数据先同步写入低延迟 WAL 存储（EBS、S3 Express 或 NFS）
- 持久化后返回 ACK
- 再异步上传到对象存储
- 整体 P99 延迟控制在 10ms 以内

## 落地案例

| 客户 | 场景 | 效果 |
|------|------|------|
| 米哈游 | 游戏发版流量洪峰 | 单集群峰值 350K+ QPS，资源利用率提升一个数量级 |
| 爱奇艺 | 大规模 Kafka 集群弹性升级 | 弹性效率提升 10 倍，成本降低 70% 以上 |
| 吉利汽车 | 车联网场景 | 稳定运行近三年，零故障，400+ TB 数据存储无容量上限担忧 |
| 得物 | 可观测性数据管道 | 多集群合计 40+ GiB/s 峰值吞吐，成本降低 50% 以上 |

^[extracted]

## 零停机迁移

AutoMQ 提供零停机迁移工具，支持从 Kafka 到 AutoMQ 的在线迁移：^[extracted]

- 所有数据和 offset byte-to-byte 保留
- 生产和消费端滚动重启即可
- 不需要停机
- 不需要梳理 topic 和业务关系

## 冷热数据读取

- **热数据**：从内存 Hot Cache 直接读。^[extracted]
- **冷数据**：从对象存储加载到 Cold Cache。^[extracted]
- 冷热分离，不会污染 Page Cache，避免传统 Kafka 冷读拖垮集群的问题。^[extracted]

## 自平衡策略

AutoMQ 提供 QPS 均衡、Traffic 均衡、Partition 均衡等多种策略及组合策略，controller 实时监控集群水位线，自动移动 partition 达到均衡目标。^[extracted] 因为 partition 不含数据，迁移是秒级的。^[extracted]

## 在可观测性管道中的角色

在 DeepFlow + AutoMQ + GreptimeDB 的端到端可观测管道中，AutoMQ 承担**数据传输层**：^[extracted]

```
DeepFlow 零侵扰采集 → AutoMQ 传输 → GreptimeDB 统一存储 → MCP + LLM 智能分析
```

## 相关页面

- [[entities/deepflow]] — 可观测数据采集层
- [[entities/greptimedb]] — 可观测数据统一存储层
- [[references/deepflow-automq-greptimedb-meetup]] — Meetup 完整回顾
