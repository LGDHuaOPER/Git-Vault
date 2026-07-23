---
title: OpenObserve
category: entities
tags:
  - observability
  - opentelemetry
  - open-source
  - logs
  - metrics
  - traces
sources:
  - "极客工具 XTool: 可观测性选型实录：从 OpenTelemetry 到 OpenObserve 的落地之路 (2026-04-20)"
summary: 基于 Rust 的开源全栈可观测性平台，单二进制部署，内置 Logs/Metrics/Traces/Dashboards/Alerts，通过 Parquet + 对象存储降低存储成本。
provenance:
  extracted: 0.80
  inferred: 0.15
  ambiguous: 0.05
base_confidence: 0.53
lifecycle: draft
lifecycle_changed: 2026-07-22
tier: supporting
created: 2026-07-22T00:00:00+08:00
updated: "2026-07-22"
relationships:
  - target: "[[concepts/ai-agent-observability]]"
    type: implements
  - target: "[[concepts/genai-observability-semconv]]"
    type: uses
  - target: "[[entities/greptimedb]]"
    type: related_to
  - target: "[[entities/signoz]]"
    type: related_to
---

# OpenObserve

**OpenObserve** 是一个基于 Rust 编写的开源全栈可观测性平台，提供 Logs、Metrics、Traces、Dashboards、Alerts 的一体化能力。^[extracted] 它的核心卖点是**单二进制、极简部署、低运维成本**，适合希望快速落地 OpenTelemetry 可观测体系的中小团队。^[extracted]

## 核心定位

OpenObserve 属于可观测性**存储与展示层**，本身不是专门的 LLM/Agent 工作台。^[inferred] 它通过原生 OTLP 协议接收 OpenTelemetry 数据，适合作为已有 OTel 采集体系的后端存储与查询平台。^[extracted]

## 关键特性

### 单二进制部署

- 一个 Rust 二进制文件即可运行。^[extracted]
- `docker run` 一条命令几分钟启动。^[extracted]
- 单机版使用 SQLite + 本地磁盘，无外部依赖。^[extracted]

### 全栈能力

- **Traces**：链路追踪 + Flamegraph。^[extracted]
- **Metrics**：SQL / PromQL 查询。^[extracted]
- **Logs**：结构化日志搜索。^[extracted]
- **Dashboards / Alerts**：内置可视化与告警。^[extracted]

### 低成本存储

采用 **Parquet + 对象存储 + 轻量索引** 的存算分离架构，比 Elasticsearch 的全量倒排索引成本更低。^[extracted]

### 查询接口

同时支持 **SQL** 和 **PromQL**，上手门槛较低。^[extracted]

## 部署架构示例

```
智能体平台（Java Agent）
↓ OTLP gRPC
OTel Collector Gateway
├── 过滤：排除 /actuator_exporter 等健康检查
├── 批量：batch size=10, timeout=10s
└── 导出：OTLP HTTP → OpenObserve
↓
OpenObserve（单节点）
├── Traces：链路追踪 + Flamegraph
├── Metrics：SQL / PromQL 查询
└── Logs：结构化日志搜索
```

^[extracted]

## 推荐部署方式

对于生产环境，OpenObserve 官方推荐"单节点 + 高可用存储"的务实方案：^[extracted]

```
├── OpenObserve × 1（单进程，挂了重启即可）
├── MySQL（主备） ← 元数据
└── MinIO / S3（对象存储，天然分布式） ← 遥测数据
```

这种方案不需要维护 OpenObserve 集群或 etcd，运维简单但数据不丢。^[extracted]

### 高可用架构

如果需要完整 HA，需要额外维护：^[extracted]

```
├── OpenObserve（多节点集群）
├── etcd（集群元数据 + 选主）
├── MySQL / PostgreSQL（元数据存储）
├── OSS / S3（遥测数据存储，Parquet 格式）
└── 调度器（Job Scheduler，管理数据生命周期）
```

## 实际踩坑

### OTel Collector 配置路径差异

`otelcol`（核心版）和 `otelcol-contrib`（社区增强版）的配置文件挂载路径不同：^[extracted]

- `otelcol`：`/etc/otelcol/config.yaml`
- `otelcol-contrib`：`/etc/otelcol-contrib/config.yaml`

如果挂载路径错误，Collector 仍能接收数据，但 process 和 export 不会生效，表现为数据进来了但没发到后端。^[extracted]

### 开源版 IAM 受限

OpenObserve 开源版只支持 Organization 级别的隔离（每个 org 用不同 auth key），角色只有一个 Admin。^[extracted] 如果需要多角色（只读用户、编辑者、管理员）或 SSO，需要企业版。^[extracted]

## 与 Grafana LGTM / [[entities/signoz|SigNoz]] 的对比

| 维度 | OpenObserve | Grafana LGTM | SigNoz |
|------|-------------|--------------|--------|
| 核心组件 | 单二进制（Rust） | Loki+Tempo+Mimir+Grafana | ClickHouse + OTel Collector |
| 部署体验 | 极简 | 复杂 | 中等 |
| 运维成本 | 低 | 高（4-5 个组件） | 中（需维护 ClickHouse） |
| 可视化 | 基础 | 强 | 完整 |
| 权限控制 | 开源版仅 Admin | 完整 | 完整 |

^[extracted]

## 选型建议

- **个人开发者 / 小项目**：OpenObserve（快速落地）。^[extracted]
- **已有 ClickHouse 经验**：SigNoz（生态成熟）。^[extracted]
- **有专职 SRE / 大规模部署**：Grafana LGTM（功能最强）。^[extracted]
- **阿里云生态**：阿里云 ARMS（托管免运维）。^[extracted]

## 相关页面

- [[concepts/genai-observability-semconv]] — OpenTelemetry 采集标准
- [[concepts/ai-agent-observability]] — Agent 可观测性整体概念
- [[entities/greptimedb]] — 另一个统一可观测性数据库
