---
title: Langfuse 部署实战：搭建 Agent 可观测平台
category: references
tags:
  - ai-agent
  - observability
  - langfuse
  - deployment
  - docker
sources:
  - "南哥聊技术: Langfuse部署实战：搭建 Agent 可观测平台 (2026-06-08)"
summary: 南哥聊技术分享的 Langfuse v3 Docker Compose 自部署笔记，重点讲组件关系、端口边界、存储权限和环境变量配置。
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
  - target: "[[entities/langfuse-llm-observability]]"
    type: related_to
  - target: "[[skills/langfuse-self-hosting]]"
    type: related_to
---

# [[entities/langfuse-llm-observability|Langfuse]] 部署实战：搭建 Agent 可观测平台

> 原文：Langfuse部署实战：搭建 Agent 可观测平台（南哥聊技术，2026-06-08）

## Langfuse v3 部署结构

一套完整自部署环境包含 6 个组件：

| 组件 | 作用 |
|------|------|
| Langfuse Web | Web UI、项目管理、API 入口 |
| Langfuse Worker | 后台任务、数据摄取、导出等异步任务 |
| PostgreSQL | 用户、组织、项目、配置等元数据 |
| ClickHouse | trace、observation、score 等高频观测数据 |
| Redis | 缓存和队列 |
| MinIO / S3 | 事件上传、媒体、批量导出等对象数据 |

## Docker Compose 适用场景

适合本地开发、内网测试、单台服务器轻量自部署。生产环境有高可用、弹性扩容、备份恢复要求时推荐 Kubernetes。

## 关键配置

### 目录与权限

建议目录结构：
```
/data/docker/langfuse/
├── clickhouse/{data,logs}
├── minio/data
└── redis/data
```

ClickHouse 使用 `user: "101:101"`，宿主机挂载目录需 `chown -R 101:101`。

### 核心环境变量

**访问地址与认证密钥**：
- `NEXTAUTH_URL`
- `NEXTAUTH_SECRET`
- `SALT`
- `ENCRYPTION_KEY`（64 位十六进制，可用 `openssl rand -hex 32` 生成）

**PostgreSQL**：
- `DATABASE_URL`
- `DIRECT_URL`

**ClickHouse**：
- `CLICKHOUSE_MIGRATION_URL="clickhouse://clickhouse:9000"`
- `CLICKHOUSE_URL="http://clickhouse:8123"`

**Redis**：
- `REDIS_HOST`
- `REDIS_PORT`
- `REDIS_AUTH`

**S3 / MinIO**：
- 需配置 event upload、media upload、batch export 三组变量
- `*_ENDPOINT` 用容器内服务名（如 `http://minio:9000`）
- `*_EXTERNAL_ENDPOINT` 用宿主机 IP 和映射端口

## 常见坑点

1. **端口冲突**：Langfuse Web 容器端口 3000，可映射为 13000；MinIO API 与 ClickHouse Native 都默认 9000，宿主机端口要错开。
2. **ClickHouse 权限**：宿主机目录 UID/GID 需为 101:101。
3. **Redis 版本**：建议 Redis 7，设置密码和 `maxmemory-policy noeviction`。
4. **MinIO bucket**：Web 能打开不代表对象存储可用，必须手动创建 `langfuse` bucket。
5. **内部端口暴露**：ClickHouse、Redis、MinIO API 不应裸露在公网。

## 接入应用前的边界检查

- **采集范围**：开发环境可较完整记录；生产环境默认记录元数据，问题会话按需打开详细记录。
- **敏感字段**：Token、密钥、身份证号、手机号、精确地址、用户上传文件全文、敏感业务字段默认不应进入观测系统。
- **Trace 维度**：至少保证 traceId、sessionId、userId、agentName、modelName、toolName、resultCode、duration、tokenUsage 可串起来。
- **数据保留策略**：提前考虑磁盘空间、ClickHouse 数据保留、备份和清理。
