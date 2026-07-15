---
source_url: "https://mp.weixin.qq.com/s?search_click_id=10944039153882374254-1784128297816-2448874674&__biz=Mzk2NDk1ODU4NQ==&mid=2247485071&idx=1&sn=06bcd06029bfd26e464e427b4252bca1&chksm=c50bec51b17bc757f5267ed73e182492bae322e1eebde755ea4931c0c1ab9d43bb9e5bcc1e67&subscene=0&scene=7&clicktime=1784128297&enterid=1784128297&ascene=65&devicetype=iOS26.5.2&version=18004b3c&nettype=WIFI&abtest_cookie=AAACAA==&lang=zh_CN&countrycode=CN&fontScale=100&exportkey=n_ChQIAhIQ0pE2C1uuBVcjipgzOAKIBBLhAQIE97dBBAEAAAAAABI9BzS3eWAAAAAOpnltbLcz9gKNyK89dVj0OW6QENdjgOfMOfjZ98nyMpMWn6KdAouuA4HQ9o98eq71UlAV2iobQHu0bh6jn+uCZBKndEGmbL+3TIxDhNwPFa/rtAX+94gwBCnABWG3LiFoxbZ8qFwwak4NbEpLDJm06soKWPqi/vogy8zJPnHW5XK4ZgUqiGw+ObgVVjE9syF2/XRVj7LLgskatAi5xw89qSau0rSt3oFenbjSuQwanSg+CdgDo5xCQKTO4IkSYsv/UQAEMZV9seovTA==&pass_ticket=Shjq6f8gf06m0vxBR9kl67XB7TGfFPEGvyCO09p+lnJZBzNxEAAkaXQPXORzi2I4&wx_header=3"
title: "Langfuse部署实战：搭建 Agent 可观测平台"
account: "南哥聊技术"
published_at: "2026-06-08T11:47:17.000Z"
saved_at: "2026-07-15T15:11:44.796Z"
sync_id: "art_6165d22a2e5b48eaad53df05245c4ea5"
parse_status: "ok"
---

# Langfuse部署实战：搭建 Agent 可观测平台

**上一篇讲到了Langfuse怎么用[可观测性实战：用 Langfuse 看清一次工具调用](https://mp.weixin.qq.com/s?__biz=Mzk2NDk1ODU4NQ==&mid=2247485066&idx=1&sn=1d75083a511928d1a6df02f123bbaf5a&scene=21#wechat_redirect)**

**这一篇讲解下怎么部署**

但真正落地时，还有一个更基础的问题：

```
Langfuse 本身部署在哪里？
```

如果只是本地 Demo，直接用云服务或者临时容器跑一下都可以。

可一旦进入真实 Agent 项目，情况就不一样了。

Agent trace 里可能出现用户输入、工具参数、业务返回、token 用量、模型响应、会话 ID、用户 ID，甚至某些业务侧错误信息。它不是普通的系统监控数据，更接近 AI 应用的行为记录。

所以很多团队最后都会走到自部署这一步。

这篇就结合我这次安装 Langfuse 的笔记，聊一下如何用 Docker Compose 部署一套可用的 Langfuse v3 环境，以及部署时容易踩到的几个坑。

文章不会只贴一份  `docker-compose.yml` ，因为 Langfuse v3 已经不是一个单容器应用。真正影响部署稳定性的，往往是组件关系、端口边界、存储权限和环境变量。

![](附件资源/Langfuse部署实战：搭建%20Agent%20可观测平台/img_1.png)

## 先看清 Langfuse v3 的部署结构

部署 Langfuse 之前，最好先把它当成一个小型观测平台，而不是一个普通 Web 应用。

一套完整的自部署环境通常包含这些组件：

| 组件 | 作用 |
| --- | --- |
| Langfuse Web | 提供 Web UI、项目管理、API 入口 |
| Langfuse Worker | 处理后台任务、数据摄取、导出等异步任务 |
| PostgreSQL | 存储用户、组织、项目、配置等元数据 |
| ClickHouse | 存储 trace、observation、score 等高频观测数据 |
| Redis | 缓存和队列 |
| MinIO / S3 | 存储事件上传、媒体、批量导出等对象数据 |

也就是说， `langfuse/langfuse:3`  只是 Web 侧， `langfuse/langfuse-worker:3`  只是后台任务侧。它们背后还依赖 PostgreSQL、ClickHouse、Redis 和对象存储。

这个结构决定了 Langfuse 的部署重点不是“容器能不能启动”，而是下面几件事：

- Web 和 Worker 是否连接到了同一套数据库、ClickHouse、Redis、S3；
- ClickHouse 是否能稳定写入大量 trace 数据；
- Redis 队列是否可用；
- S3 bucket 是否提前准备好；
- 宿主机端口是否只暴露必要服务；
- 密钥、盐值、加密 key 是否替换成自己的值；
- 数据目录是否持久化，并且权限正确。

如果这些边界没处理好，表面上 Web 页面可能能打开，但数据摄取、后台任务、导出、媒体上传都会陆续出问题。

## Docker Compose 适合什么场景

官方提供了 Docker Compose 示例，这个方案非常适合三类场景：

- 本地开发；
- 内网测试环境；
- 单台服务器或单台 VM 的轻量自部署。

如果是生产环境，并且有高可用、弹性扩容、备份恢复和统一运维要求，Kubernetes 会更合适。

我这次部署的目标是先把 Langfuse 跑在内网服务器上，服务 Spring AI Alibaba Agent 的可观测性验证，所以选择 Docker Compose 更直接。

整体链路可以简化成这样：

```
Spring AI Alibaba 应用
-> OpenTelemetry / SDK
-> Langfuse Web API
-> Redis 队列
-> Langfuse Worker
-> ClickHouse / PostgreSQL / MinIO
```

这里有一个很容易混淆的点：宿主机访问地址和容器内访问地址不是一回事。

比如宿主机上访问 MinIO API 可以写成：

```
http://:9090
```

但 Langfuse Web 和 Worker 容器内部访问 MinIO 时，更推荐使用 Compose 服务名：

```
http://minio:9000
```

ClickHouse、Redis 也是一样。

容器内互访用服务名，外部访问用宿主机 IP 和映射端口。把这两类地址混在一起，是 Docker Compose 部署里很常见的坑。

## 准备部署目录

我习惯把这类中间件数据统一放到  `/data/docker`  下，方便备份和迁移。

这次目录可以设计成这样：

```
/data/docker/langfuse/
clickhouse/
data/
logs/
minio/
data/
redis/
data/
```

创建目录：

```
mkdir -p /data/docker/langfuse/clickhouse/{data,logs}
mkdir -p /data/docker/langfuse/minio/data
mkdir -p /data/docker/langfuse/redis/data
```

ClickHouse 的目录权限要特别处理。

官方 Compose 示例里 ClickHouse 使用的是  `user: "101:101"` ，所以如果把 ClickHouse 数据目录挂载到宿主机，宿主机目录也要给到对应 UID。

```
chown -R 101:101 /data/docker/langfuse/clickhouse/data
chown -R 101:101 /data/docker/langfuse/clickhouse/logs

chmod -R 755 /data/docker/langfuse/minio
chmod -R 755 /data/docker/langfuse/redis
```

如果这个权限没处理，ClickHouse 很容易启动失败。看日志时通常会看到数据目录、日志目录无法写入一类的问题。

这不是 Langfuse 的问题，而是挂载目录和容器用户没对齐。

## 准备 PostgreSQL

Langfuse 的 PostgreSQL 用来存储元数据，比如用户、组织、项目、API Key、配置等。

如果已经有内网 PostgreSQL，可以直接创建一个独立数据库：

```
psql -h  -U
```

进入  `psql`  后执行：

```
CREATE DATABASE langfuse;
```

连接串类似这样：

```
DATABASE_URL="postgresql://langfuse_user:replace-with-password@:5432/langfuse"
DIRECT_URL="postgresql://langfuse_user:replace-with-password@:5432/langfuse"
```

这里有两个实践建议。

第一，生产或准生产环境不要直接使用示例密码。

第二，数据库时区尽量按 UTC 处理。官方 Compose 示例里 PostgreSQL 设置了  `TZ: UTC`  和  `PGTZ: UTC` ，这是为了减少跨服务时间字段不一致的问题。

如果只是内网测试，也建议从一开始就按这个习惯来。

## 配置关键环境变量

Langfuse 自部署最容易被忽略的是环境变量。

官方 Compose 示例里有很多  `CHANGEME` ，这些不是可有可无的注释，而是必须替换的部署参数。

最关键的是下面几类。

第一类是访问地址和认证密钥：

```
NEXTAUTH_URL="http://:13000"
NEXTAUTH_SECRET="replace-with-a-random-secret"
SALT="replace-with-a-random-salt"
ENCRYPTION_KEY="replace-with-64-hex-chars"
```

其中  `ENCRYPTION_KEY`  可以用下面命令生成：

```
openssl rand -hex 32
```

第二类是 PostgreSQL：

```
DATABASE_URL="postgresql://langfuse_user:replace-with-password@:5432/langfuse"
DIRECT_URL="postgresql://langfuse_user:replace-with-password@:5432/langfuse"
```

第三类是 ClickHouse。

如果 ClickHouse 跟 Langfuse 在同一个 Compose 网络里，容器内地址建议这样写：

```
CLICKHOUSE_MIGRATION_URL="clickhouse://clickhouse:9000"
CLICKHOUSE_URL="http://clickhouse:8123"
CLICKHOUSE_USER="clickhouse"
CLICKHOUSE_PASSWORD="replace-with-clickhouse-password"
```

第四类是 Redis：

```
REDIS_HOST="redis"
REDIS_PORT=6379
REDIS_AUTH="replace-with-redis-password"
```

第五类是 S3 / MinIO。

Langfuse v3 的对象存储不只用于一个地方，常见配置会包含 event upload、media upload、batch export 等几组变量。

内网 MinIO 示例可以这样理解：

```
LANGFUSE_S3_EVENT_UPLOAD_BUCKET=langfuse
LANGFUSE_S3_EVENT_UPLOAD_ENDPOINT=http://minio:9000
LANGFUSE_S3_EVENT_UPLOAD_ACCESS_KEY_ID=minio
LANGFUSE_S3_EVENT_UPLOAD_SECRET_ACCESS_KEY=replace-with-minio-password
LANGFUSE_S3_EVENT_UPLOAD_FORCE_PATH_STYLE=true

LANGFUSE_S3_MEDIA_UPLOAD_BUCKET=langfuse
LANGFUSE_S3_MEDIA_UPLOAD_ENDPOINT=http://minio:9000
LANGFUSE_S3_MEDIA_UPLOAD_ACCESS_KEY_ID=minio
LANGFUSE_S3_MEDIA_UPLOAD_SECRET_ACCESS_KEY=replace-with-minio-password
LANGFUSE_S3_MEDIA_UPLOAD_FORCE_PATH_STYLE=true

LANGFUSE_S3_BATCH_EXPORT_ENABLED=true
LANGFUSE_S3_BATCH_EXPORT_BUCKET=langfuse
LANGFUSE_S3_BATCH_EXPORT_ENDPOINT=http://minio:9000
LANGFUSE_S3_BATCH_EXPORT_EXTERNAL_ENDPOINT=http://:9090
LANGFUSE_S3_BATCH_EXPORT_ACCESS_KEY_ID=minio
LANGFUSE_S3_BATCH_EXPORT_SECRET_ACCESS_KEY=replace-with-minio-password
LANGFUSE_S3_BATCH_EXPORT_FORCE_PATH_STYLE=true
```

注意这里的两个 endpoint。

`LANGFUSE_S3_BATCH_EXPORT_ENDPOINT`  是容器内部访问 MinIO 的地址，所以用  `http://minio:9000` 。

`LANGFUSE_S3_BATCH_EXPORT_EXTERNAL_ENDPOINT`  是外部下载或访问时看到的地址，所以可以用宿主机 IP 和映射端口。

这一点如果配错，常见表现是后台能写对象，但外部访问导出文件时地址不对。

## Compose 服务怎么拆

完整 Compose 文件可以基于官方示例改。

如果你跟我一样使用外部 PostgreSQL，那么 Compose 里可以不启动 PostgreSQL 容器，只保留 Langfuse Web、Langfuse Worker、ClickHouse、Redis、MinIO。

核心关系大概是这样：

```
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

ClickHouse 可以这样挂载：

```
clickhouse:
image: clickhouse/clickhouse-server
user: "101:101"
environment:
CLICKHOUSE_USER: clickhouse
CLICKHOUSE_PASSWORD: ${CLICKHOUSE_PASSWORD}
volumes:
- /data/docker/langfuse/clickhouse/data:/var/lib/clickhouse
- /data/docker/langfuse/clickhouse/logs:/var/log/clickhouse-server
ports:
- "127.0.0.1:8123:8123"
- "127.0.0.1:9000:9000"
healthcheck:
test: wget --no-verbose --tries=1 --spider http://localhost:8123/ping || exit 1
interval: 5s
timeout: 5s
retries: 10
start_period: 1s
```

这里我更建议把 ClickHouse、Redis 这类内部组件绑定到  `127.0.0.1` ，甚至不暴露给宿主机外部网络。

官方 Compose 示例也强调了类似思路：对外主要暴露 Langfuse Web 和必要的 MinIO 访问端口，其他组件尽量限制在本机或内网。

如果为了调试临时把 ClickHouse、Redis、MinIO Console 暴露到  `0.0.0.0` ，部署完成后也要收回来，或者至少用防火墙限制访问来源。

## 启动和验证

配置完成后启动：

```
docker compose -f docker-compose.custom.yml up -d --wait
```

查看状态：

```
docker compose -f docker-compose.custom.yml ps
```

看日志：

```
docker compose -f docker-compose.custom.yml logs -f
```

几个关键验证命令：

```
# 验证 Langfuse Web
curl -I http://localhost:13000

# 验证 ClickHouse
curl http://localhost:8123/ping

# 验证 Redis
docker exec langfuse-redis redis-cli -a "$REDIS_AUTH" PING

# 验证 MinIO
curl http://localhost:9090/minio/health/live
```

首次访问 Langfuse Web：

```
http://:13000
```

然后按顺序完成：

- 注册管理员账户；
- 创建 Organization；
- 创建 Project；
- 获取 Public Key 和 Secret Key；
- 在 Spring AI Alibaba 应用里配置 Langfuse / OTLP 接入。

如果你启用了 MinIO Console，可以访问：

```
http://:9091
```

创建 bucket：

```
langfuse
```

官方示例里 MinIO 启动命令会自动创建  `/data/langfuse` ，但自己改 Compose 或使用其他 MinIO 镜像时，最好还是确认 bucket 是否存在。

## 这次部署里最容易踩的坑

第一个坑是端口冲突。

Langfuse Web 默认容器端口是  `3000` 。如果宿主机上已经有其他应用占用 3000，可以映射成  `13000` ：

```
ports:
- "0.0.0.0:13000:3000"
```

MinIO API 默认是容器内  `9000` ，ClickHouse Native 也是  `9000` 。所以宿主机端口要错开，比如：

```
MinIO API      9090 -> 9000
MinIO Console  9091 -> 9001
ClickHouse     8123 -> 8123
ClickHouse     9000 -> 9000
```

第二个坑是 ClickHouse 权限。

只要使用宿主机目录挂载，先检查：

```
ls -ld /data/docker/langfuse/clickhouse/data
ls -ld /data/docker/langfuse/clickhouse/logs
```

如果不是  `101:101` ，就按前面的命令修正。

第三个坑是 Redis 版本。

安装笔记里最初用了 Redis 5.0.10。它能跑，但版本偏旧。新的部署建议直接用 Redis 7，并设置密码和  `noeviction`  策略：

```
redis:
image: redis:7
command: >
--requirepass ${REDIS_AUTH}
--maxmemory-policy noeviction
```

第四个坑是 MinIO bucket。

Web 能打开不代表对象存储可用。只要涉及事件上传、媒体、导出，bucket 不存在就会出问题。

可以用 MinIO Console 创建，也可以用命令创建：

```
docker run --rm --network langfuse-network \
minio/mc:latest \
sh -c "
mc alias set langfuse-minio http://minio:9000 minio $MINIO_ROOT_PASSWORD && \
mc mb langfuse-minio/langfuse --ignore-existing
"
```

第五个坑是把内部端口直接暴露到公网。

Langfuse Web 可以放到网关后面，通过域名和 HTTPS 访问。

但 ClickHouse、Redis、MinIO API 这类组件，不应该裸露在公网。哪怕是内网环境，也建议只开放必要来源。

对于 AI trace 平台，这一点尤其重要。

因为 trace 里不只是技术指标，还可能包含真实业务上下文。

## 接入应用前再做一次边界检查

Langfuse 部署完成后，不要急着把所有 Agent 请求全量打进去。

我建议先做一次边界检查。

第一，确认采集范围。

```
开发环境：可以较完整记录 prompt、completion、tool 参数、tool result
测试环境：记录关键字段和必要摘要
生产环境：默认记录元数据，问题会话按需打开更详细记录
```

第二，确认敏感字段。

下面这些内容默认不应该进入观测系统：

```
Token
密钥
身份证号
手机号
精确地址
用户上传文件全文
敏感业务字段
```

第三，确认 trace 维度。

至少要保证这些字段能串起来：

```
traceId
sessionId
userId
agentName
modelName
toolName
resultCode
duration
tokenUsage
```

没有这些维度，Langfuse 只是多了一个漂亮后台，排查问题时仍然很难把链路串起来。

第四，确认数据保留策略。

AI trace 数据增长会比较快，尤其在打开 prompt、completion、tool result 之后。部署时就要考虑磁盘空间、ClickHouse 数据保留、备份和清理。

简单备份可以先这样做：

```
tar -czf langfuse-backup-$(date +%Y%m%d).tar.gz /data/docker/langfuse/
```

但如果进入生产使用，还是要针对 PostgreSQL、ClickHouse、MinIO 分别设计备份策略。

## 小结

Langfuse 自部署本身不复杂，但它不是一个“起一个容器就完事”的应用。

更准确地说，它是一套 AI 可观测性数据平台：

```
Web 负责展示和 API
Worker 负责异步处理
PostgreSQL 管元数据
ClickHouse 扛高频 trace
Redis 管队列和缓存
MinIO / S3 存对象和导出
```

用 Docker Compose 部署时，真正要盯住的是四类问题：

- 组件之间的连接地址是否区分了容器内和宿主机外；
- ClickHouse、MinIO、Redis 的持久化和权限是否正确；
- NEXTAUTH_SECRET 、 SALT 、 ENCRYPTION_KEY 、数据库密码等密钥是否替换；
- 内部组件端口是否避免不必要暴露。

这套环境跑起来以后，再回到 Spring AI Alibaba Agent 侧接入 OpenTelemetry 或 Langfuse SDK，整个可观测链路就完整了：

```
Agent 请求
-> 模型调用
-> 工具调用
-> 业务结果
-> trace 写入 Langfuse
-> 在 Langfuse 里复盘一次 AI 行为
```

对 Agent 工程化来说，这一步很关键。

因为只有先把观测平台部署稳定，后面谈 trace、token 统计、工具调用分析、问题会话复盘才有意义。

这也是 Agent 可观测性真正落地时绕不开的两件事：一边要看清链路，另一边要守住数据边界。

我最近在做时光笺的小宇助手时，也会持续把这些 Agent 工程化问题记录下来。对用户来说，它可能只是一次自然语言创建待办、整理日程或生成提醒；对开发者来说，背后其实是一整套模型调用、工具选择、业务落库和链路追踪。

如果你也对这类 AI 时间管理助手感兴趣，可以去应用商店搜索“时光笺”体验一下。

## 参考资料

- Langfuse Self Hosting 文档：https://langfuse.com/self-hosting
- Langfuse Configuration 文档：https://langfuse.com/self-hosting/configuration
- Langfuse 官方 Docker Compose 示例：https://github.com/langfuse/langfuse/blob/main/docker-compose.yml
- Langfuse 官方文档：https://langfuse.com/docs

---
原文链接：https://mp.weixin.qq.com/s?__biz=Mzk2NDk1ODU4NQ%3D%3D&mid=2247485071&idx=1&sn=06bcd06029bfd26e464e427b4252bca1&chksm=c50bec51b17bc757f5267ed73e182492bae322e1eebde755ea4931c0c1ab9d43bb9e5bcc1e67
