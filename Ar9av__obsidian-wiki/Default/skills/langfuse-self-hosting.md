---
title: Langfuse Self-Hosting
category: skills
tags:
  - ai-agent
  - observability
  - langfuse
  - deployment
  - docker
sources:
  - "南哥聊技术: Langfuse部署实战：搭建 Agent 可观测平台 (2026-06-08)"
summary: 使用 Docker Compose 自托管 Langfuse v3 的实操要点，包括组件关系、端口边界、存储权限和环境变量配置。
provenance:
  extracted: 0.70
  inferred: 0.25
  ambiguous: 0.05
base_confidence: 0.55
lifecycle: draft
lifecycle_changed: 2026-07-22
tier: supporting
created: 2026-07-22T00:00:00+08:00
updated: 2026-07-22T00:00:00+08:00
relationships:
  - target: "[[entities/langfuse-llm-observability]]"
    type: implements
---

# Langfuse Self-Hosting

使用 Docker Compose 自托管一套可用的 [[entities/langfuse-llm-observability|Langfuse]] v3 环境。适合本地开发、内网测试、单台服务器轻量自部署；生产高可用场景推荐 Kubernetes。

## 组件清单

| 组件 | 作用 |
|------|------|
| Langfuse Web | Web UI、项目管理、API 入口 |
| Langfuse Worker | 后台任务、数据摄取、导出 |
| PostgreSQL | 元数据存储（用户、组织、项目、API Key） |
| ClickHouse | trace、observation、score 等高频数据 |
| Redis | 缓存和队列 |
| MinIO / S3 | 事件上传、媒体、批量导出 |

## 目录与权限

推荐目录结构：

```
/data/docker/langfuse/
├── clickhouse/{data,logs}
├── minio/data
└── redis/data
```

ClickHouse 容器使用 `user: "101:101"`，宿主机挂载目录必须同步权限：

```bash
chown -R 101:101 /data/docker/langfuse/clickhouse/data
chown -R 101:101 /data/docker/langfuse/clickhouse/logs
chmod -R 755 /data/docker/langfuse/minio
chmod -R 755 /data/docker/langfuse/redis
```

## 关键环境变量

### 访问地址与认证

```env
NEXTAUTH_URL="http://<host>:13000"
NEXTAUTH_SECRET="<random-secret>"
SALT="<random-salt>"
ENCRYPTION_KEY="<64-hex-chars>"
```

生成 `ENCRYPTION_KEY`：

```bash
openssl rand -hex 32
```

### PostgreSQL

```env
DATABASE_URL="postgresql://<user>:<password>@<host>:5432/langfuse"
DIRECT_URL="postgresql://<user>:<password>@<host>:5432/langfuse"
```

建议 PostgreSQL 时区按 UTC 处理，减少跨服务时间字段不一致。

### ClickHouse

容器内访问使用服务名：

```env
CLICKHOUSE_MIGRATION_URL="clickhouse://clickhouse:9000"
CLICKHOUSE_URL="http://clickhouse:8123"
CLICKHOUSE_USER="clickhouse"
CLICKHOUSE_PASSWORD="<password>"
```

### Redis

```env
REDIS_HOST="redis"
REDIS_PORT=6379
REDIS_AUTH="<password>"
```

建议使用 Redis 7，并设置 `maxmemory-policy noeviction`。

### S3 / MinIO

需要配置 event upload、media upload、batch export 三组变量。注意区分：

- `*_ENDPOINT`：容器内部访问 MinIO 的地址，用 `http://minio:9000`
- `*_EXTERNAL_ENDPOINT`：外部下载时看到的地址，用宿主机 IP 和映射端口

```env
LANGFUSE_S3_EVENT_UPLOAD_BUCKET=langfuse
LANGFUSE_S3_EVENT_UPLOAD_ENDPOINT=http://minio:9000
LANGFUSE_S3_EVENT_UPLOAD_ACCESS_KEY_ID=minio
LANGFUSE_S3_EVENT_UPLOAD_SECRET_ACCESS_KEY=<minio-password>
LANGFUSE_S3_EVENT_UPLOAD_FORCE_PATH_STYLE=true
```

media upload 和 batch export 同理。

## Compose 服务拆分建议

若使用外部 PostgreSQL，Compose 中可只保留 Web、Worker、ClickHouse、Redis、MinIO：

```yaml
services:
  langfuse-web:
    image: langfuse/langfuse:3
    depends_on:
      clickhouse:
        condition: service_healthy
      minio:
        condition: service_healthy
      redis:
        condition: service_healthy
    ports:
      - "0.0.0.0:13000:3000"
    env_file:
      - .env

  langfuse-worker:
    image: langfuse/langfuse-worker:3
    depends_on:
      clickhouse:
        condition: service_healthy
      minio:
        condition: service_healthy
      redis:
        condition: service_healthy
    env_file:
      - .env
```

内部组件（ClickHouse、Redis）建议绑定 `127.0.0.1` 或不暴露给外部网络。

## 启动与验证

```bash
docker compose -f docker-compose.custom.yml up -d --wait
docker compose -f docker-compose.custom.yml ps
docker compose -f docker-compose.custom.yml logs -f
```

关键验证：

```bash
curl -I http://localhost:13000
curl http://localhost:8123/ping
docker exec langfuse-redis redis-cli -a "$REDIS_AUTH" PING
curl http://localhost:9090/minio/health/live
```

## 首次访问流程

1. 访问 `http://<host>:13000`
2. 注册管理员账户
3. 创建 Organization
4. 创建 Project
5. 获取 Public Key 和 Secret Key
6. 在应用中配置 Langfuse / OTLP 接入

## 常见坑点

1. **端口冲突**：Langfuse Web 容器端口 3000，可映射为 13000；MinIO API 与 ClickHouse Native 都默认 9000，宿主机端口要错开。
2. **ClickHouse 权限**：宿主机目录 UID/GID 需为 101:101。
3. **Redis 版本**：建议 Redis 7 + `noeviction`。
4. **MinIO bucket**：必须创建名为 `langfuse` 的 bucket，否则事件上传/导出失败。
5. **内部端口暴露**：ClickHouse、Redis、MinIO API 不应裸露在公网，尤其 trace 中可能含业务上下文。

## 接入前的边界检查

- **采集范围**：生产环境默认只记录元数据，问题会话按需打开详细记录。
- **敏感字段**：Token、密钥、身份证、手机号、地址、用户上传文件全文等不应进入观测系统。
- **Trace 维度**：至少保证 traceId、sessionId、userId、agentName、modelName、toolName、resultCode、duration、tokenUsage 可串起来。
- **数据保留**：提前规划磁盘空间、ClickHouse 保留策略、备份和清理。
