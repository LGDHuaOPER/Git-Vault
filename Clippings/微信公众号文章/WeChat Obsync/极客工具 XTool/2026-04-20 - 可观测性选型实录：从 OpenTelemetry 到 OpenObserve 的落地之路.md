---
source_url: "https://mp.weixin.qq.com/s?search_click_id=4566775704178140990-1784705773035-9875353061&__biz=MzA4Nzg2NTY2Mw==&mid=2247486582&idx=1&sn=79d1491a8d13059122df241b39f077c2&chksm=91ec5ffaec81780ee67cb4b4d990c47b086063eeb7bc5505c5d53339f8aad156bd0766b3f892&subscene=90&scene=7&clicktime=1784705773&enterid=1784705773&ascene=65&devicetype=iOS26.5.2&version=18004b43&nettype=3G+&abtest_cookie=AAACAA==&lang=zh_CN&countrycode=CN&fontScale=100&exportkey=n_ChQIAhIQLUqmeBnQh2nHkJ6Nh8VdGRLhAQIE97dBBAEAAAAAAGpDOseTrccAAAAOpnltbLcz9gKNyK89dVj0+3huVujxUccGFcvnB46zUTEdDl35/H2WTPNAV4I6HWYVf3YPziZowr7MACeWu6/usNqRgbVCCCu23/N65UXfjoXguI4UazpvsTDFh85P1WE6gO2a1UJRME6yS7DTXWkhMtvi8qS6uEizzMGDSHk5Rkf+vYw2pADclqbO6y69YYNzQC7fmssfufDRvpzXb9SFXXDFOoWupHJESl5ESlGvE0gwNEdq8EAEk+Z9SUoLMeT8Ue/UDA1irUO8ug==&pass_ticket=2ZPYKITBKS3gSnPQdJ5hCTckQnr63xLER/rv3TuS+fCouNwhWi6mtriNm04LGKMG&wx_header=3"
title: "可观测性选型实录：从 OpenTelemetry 到 OpenObserve 的落地之路"
account: "极客工具 XTool"
published_at: "2026-04-20T10:27:19.000Z"
saved_at: "2026-07-22T07:36:22.874Z"
sync_id: "art_3c3430a49fbd41658de6fe2bcca5be19"
parse_status: "ok"
---

# 可观测性选型实录：从 OpenTelemetry 到 OpenObserve 的落地之路

![Gemini_Generated_Image_x4b0s4x4b0s4x4b0.png](附件资源/可观测性选型实录：从%20OpenTelemetry%20到%20OpenObserve%20的落地之路/img_1.png)

最近在做智能体的可观测性建设。每次对话的执行过程、调用链路、耗时分布都需要被观测到。当用户反馈"Skill 执行慢了"或者"结果不对"，我需要能快速定位是哪个环节出了问题。

这就是可观测性的核心价值：**从外部输出推断系统内部状态**。

这篇文章记录了我在可观测性技术选型上的完整调研过程——从理解 **OpenTelemetry** 协议，到对比多种存储方案，最终选择 **OpenObserve** 作为落地平台。

## 一、为什么选 OpenTelemetry？

### 1.1 可观测性的三大信号

可观测性（Observability）源于控制理论，核心思路是：通过系统的外部输出，推断内部状态。

在软件系统中，这转化为三大信号：

| 信号 | 回答的问题 | 典型场景 |
| --- | --- | --- |
| ** Traces（链路追踪） ** | 请求走了哪些路径？每步耗时多少？ | 定位"Skill 执行慢"瓶颈在哪 |
| ** Metrics（指标） ** | 系统级数据如何？ | CPU 使用率、QPS、错误率趋势 |
| ** Logs（日志） ** | 发生了什么离散事件？ | 排查具体错误信息 |

![统一采集架构：OTel Collector 统一管道](附件资源/可观测性选型实录：从%20OpenTelemetry%20到%20OpenObserve%20的落地之路/img_2.png)

三者关联起来才是完整的可观测性：从 Metrics 发现异常 → 通过 Traces 定位链路 → 在 Logs 中找到根因。

### 1.2 OpenTelemetry 是什么

**OpenTelemetry（OTel）** 是 CNCF 旗下的可观测性框架，由 OpenTracing 和 OpenCensus 合并而来。它不是某个具体产品，而是一套**采集和传输标准**：

- API + SDK ：各语言的埋点库（Java/Python/Go/Node.js...）
- OTLP 协议 ：统一的遥测数据传输格式
- Collector ：数据采集、处理、转发的核心组件

关键定位：OTel **只管采集和传输，不管存储和展示**。这避免了厂商锁定——换了存储后端，采集层代码不用改。

### 1.3 核心架构

```
应用（OTel SDK / Java Agent）
↓  OTLP
OTel Collector（可选，生产推荐）
↓  OTLP
存储后端（Jaeger / Prometheus / OpenObserve / ...）
```

**Collector** 是架构中的关键组件，类似 Logstash 的角色：

- Receivers ：接收数据（支持 OTLP/Jaeger/Zipkin/Kafka 等多种协议）
- Processors ：处理数据（过滤、采样、批量发送）
- Exporters ：导出数据到后端

![OTel Collector 内部架构](附件资源/可观测性选型实录：从%20OpenTelemetry%20到%20OpenObserve%20的落地之路/img_3.png)

> 💡 Collector vs Exporter 的区别 （我踩过坑）： - Exporter ：SDK 内置的导出器，直接把数据发送到后端 - Collector ：独立进程，可接收多种协议，集中处理后转发 - 生产环境建议用 Collector Gateway 做统一入口

## 二、存储选型：四大流派

OTel 解决了"怎么采"的问题，但"存哪里"才是成本的关键。在可观测性场景中，数据量巨大，存储成本往往占系统总成本的大头。

### 2.1 四大存储流派

| 流派 | 代表方案 | 索引方式 | 适用场景 |
| --- | --- | --- | --- |
| ** 全文索引 ** | Elasticsearch / OpenSearch | 全量倒排索引 | 安全分析、复杂搜索 |
| ** 标签存储 ** | Loki + MinIO/S3 | 仅标签+时间索引 | 日志聚合、Prometheus 生态 |
| ** 列式分析 ** | SigNoz (ClickHouse) | 列存 OLAP | SQL 聚合分析 |
| ** 存算分离 ** | OpenObserve + MinIO/S3 | Parquet + 轻量索引 | 全栈可观测 |

大致的趋势是：**全文索引查询能力最强但存储成本最高**，**标签/列式/存算分离方案通过减少索引来降低存储成本**。

### 2.2 选型决策树

```
需要任意关键词全文搜索？
├── 是 → Elasticsearch（安全分析、合规审计）
└── 否 → 日志量多大？
├── 中小规模 → OpenObserve 单节点 / SigNoz
└── 大规模 → Grafana LGTM 或 OpenObserve HA
```

## 三、落地平台对比：我的四个候选

基于存储选型分析，我重点对比了四个开源方案，并且**每个都实际部署体验过**。

### 3.1 方案速览

| 方案 | 核心组件 | 部署体验 | 我的感受 |
| --- | --- | --- | --- |
| ** OpenObserve ** | 单二进制（Rust） | 极简 | 一条 docker run 就跑起来了 |
| ** Grafana LGTM ** | Loki+Tempo+Mimir+Grafana | 复杂 | 光配置就折腾了一下午 |
| ** SigNoz ** | ClickHouse + OTel Collector | 中等 | docker-compose 一键起来，还算方便 |
| ** Uptrace ** | ClickHouse + PostgreSQL | 中等 | 功能丰富但还在 beta |

### 3.2 实际体验对比

#### OpenObserve

- 部署 ： docker run 一条命令，几分钟就启动了
- 能力 ：Logs + Metrics + Traces + Dashboards + Alerts 全内置
- 查询 ：SQL + PromQL，上手门槛低
- 踩坑 ：开源版只有 Admin 角色，没有 RBAC。如果需要多租户，可以用 Organization 级别做数据隔离（每个 org 用不同的 auth key），但细粒度权限控制需要企业版

#### Grafana LGTM

- 组件 ：Loki（日志）+ Tempo（追踪）+ Mimir（指标）+ Grafana（可视化），4-5 个独立组件
- 优势 ：可视化能力确实强，Drilldown（无查询体验）很自然，Trace 的 Span 展示分类比 OpenObserve 清晰
- 代价 ：4-5 个组件各自安装、配置、运维，学习成本高

#### SigNoz

- 存储 ：ClickHouse 列式 OLAP
- 部署 ：Docker Compose 一键启动
- 优势 ：一个控制台看所有，APM 功能完整，OTel 原生
- 感受 ：整体不错，但对我当前场景来说引入 ClickHouse 有点重

### 3.3 运维视角对比（选型的关键）

对我来说，运维成本才是选型的核心考量——我没有专职 SRE，可观测系统得自己维护：

| 运维场景 | Grafana LGTM | OpenObserve |
| --- | --- | --- |
| ** 安装 ** | 4-5 个组件各自配置 | 单二进制 |
| ** 升级 ** | 4-5 个组件分别升级 | 升级一个二进制 |
| ** 故障排查 ** | 需定位是哪个组件的问题 | 单一进程，日志集中 |
| ** 监控自己 ** | 每个组件都要监控 | 只需监控自身 |

## 四、我为什么选了 OpenObserve

### 4.1 决策理由

**一句话**：我需要的是 `快速落地` ，不是 `完美架构` 。

具体来说：

- 运维成本最低 ：All-in-One 设计，我一个人就能搞定部署和维护
- 存储成本低 ：Parquet + 对象存储，比 ES 的全量索引方案省很多
- OTel 原生 ：直接接收 OTLP 协议，和我用的 OTel SDK 无缝对接
- 快速验证 ：从零到看到第一条 Trace，不到 30 分钟

### 4.2 我的实际部署架构

```
智能体平台（Java Agent）
↓  OTLP gRPC
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

### 4.3 踩过的坑

**坑 1：OTel Collector 不同版本的配置路径不同**

OTel Collector 有两个发行版： `otelcol` （核心版）和  `otelcol-contrib` （社区增强版）。它们的配置文件挂载路径不一样：

- otelcol ： /etc/otelcol/config.yaml
- otelcol-contrib ： /etc/otelcol-contrib/config.yaml

关键问题在于：**如果你挂载的 config 路径不对，Collector 不会报错，还能正常 receive 数据**。但 process 和 export 不会生效——表现为数据进来了但没发到后端。

更坑的是， `otelcol-contrib`  的镜像自带默认配置，即使你挂载错了，它也会用默认配置跑起来，看起来一切正常。我折腾了好几个小时才定位到这个问题。

![应用通过 OTel SDK 接入 Collector](附件资源/可观测性选型实录：从%20OpenTelemetry%20到%20OpenObserve%20的落地之路/img_4.png)

**经验**：部署 Collector 时，务必确认镜像版本和配置路径的对应关系。

**坑 2：OpenObserve 开源版的 IAM 是个"坑"**

OpenObserve 开源版的权限控制比较受限，类似 Dify 的策略——多租户角色控制、SSO、细粒度访问控制等安全模块都锁在 Enterprise 版后面（ `RBAC, SSO, fine-grained access — all locked behind "Enterprise"` ）。

开源版只支持 Organization 级别的隔离：

- 每个 Organization 关联独立的用户
- 每个 Organization 用不同的 auth key 推送数据
- 但角色只有一个：Admin

如果你的场景需要多角色（比如只读用户、编辑者、管理员），开源版是做不到的。我目前的做法是用 Organization 做数据隔离，权限方面只能自己在外层控制。

### 4.4 单机版其实就很能打

OpenObserve 单机版用的是 SQLite + 本地磁盘，没有外部依赖。官方测试数据显示，单台 Mac M2 默认配置下摄入速度约 31 MB/秒，折合 **~2.6 TB/天**。

这意味着大部分中小团队的可观测数据量远远到不了这个级别。单机模式就能覆盖绝大多数场景。

**更务实的做法**：OpenObserve 本身跑单节点就行，但**存储层直接用高可用的组件**——元数据用 MySQL（主备），遥测数据用对象存储（天然分布式）。这样 OpenObserve 进程挂了，重启就恢复，数据不丢。不用搞 OpenObserve 集群、不用 etcd，运维简单但数据安全。

```
推荐部署方式（单节点 + 高可用存储）
├── OpenObserve × 1（单进程，挂了重启即可）
├── MySQL（主备） ← 元数据
└── MinIO / S3（对象存储，天然分布式） ← 遥测数据
```

> 不过官方数据是 Mac M2 的测试结果，实际生产环境性能需要根据自己的机器配置做验证。

### 4.5 高可用架构：需要时再加

![Grafana LGTM 仪表盘](附件资源/可观测性选型实录：从%20OpenTelemetry%20到%20OpenObserve%20的落地之路/img_5.png)

OpenObserve 单节点部署确实极简，但如果你要上高可用，依赖就多了：

```
OpenObserve HA 架构
├── OpenObserve（多节点集群）
├── etcd（集群元数据 + 选主）
├── MySQL / PostgreSQL（元数据存储）
├── OSS / S3（遥测数据存储，Parquet 格式）
└── 调度器（Job Scheduler，管理数据生命周期）
```

核心设计是**元数据和数据分开存储**：

- 元数据 （stream 定义、schema、用户信息等）→ MySQL/PG + etcd
- 遥测数据 （traces/logs/metrics）→ 对象存储（Parquet 列式文件）
- 调度 （compaction、retention、flush 等）→ 内置 Job Scheduler

所以不要被"单二进制"迷惑——单节点确实简单，但 HA 模式下你要维护 etcd 集群、MySQL、对象存储和调度器，复杂度也不低。好在我当前阶段单节点就够了，等真正需要 HA 时再评估。

### 4.5 不选 Grafana LGTM 的原因

说清楚，Grafana LGTM 在**功能完整性和可视化能力**上确实更强——Trace 的 Span 展示更清晰，Drilldown 体验很棒。但它需要维护 4-5 个独立组件，对我来说运维成本太高。

> 我的原则 ：先跑起来，再优化。可观测性本身是为了降低排障成本，如果可观测系统的运维成本比排障成本还高，就本末倒置了。

## 五、上手指南

### 5.1 启动 OpenObserve

```
docker run -d\
--name openobserve \
-v$PWD/data:/data \
-p5080:5080 \
-eZO_ROOT_USER_EMAIL="root@example.com"\
-eZO_ROOT_USER_PASSWORD="Complexpass#123"\
public.ecr.aws/zinclabs/openobserve:latest
```

访问  `http://localhost:5080` ，用上面的邮箱密码登录。

### 5.2 部署 OTel Collector

```
# otel-collector-config.yaml
receivers:
otlp:
protocols:
grpc:
endpoint: 0.0.0.0:4317
http:
endpoint: 0.0.0.0:4318

processors:
filter/traces:
error_mode: ignore
traces:
span:
# 过滤健康检查等噪音数据
-'attributes["url.full"] != nil and IsMatch(attributes["url.full"], ".*/actuator_exporter")'
batch:
send_batch_size:10
timeout: 10s

exporters:
otlphttp/openobserve:
endpoint:"http://localhost:5080/api/default"
headers:
Authorization:"Basic "
stream-name:"default"
tls:
insecure:true

service:
pipelines:
traces:
receivers:[otlp]
processors:[filter/traces, batch]
exporters:[otlphttp/openobserve]
metrics:
receivers:[otlp]
processors:[batch]
exporters:[otlphttp/openobserve]
logs:
receivers:[otlp]
processors:[batch]
exporters:[otlphttp/openobserve]
```

### 5.3 应用接入（Java Agent 零代码）

```
java -javaagent:opentelemetry-javaagent.jar \
-Dotel.service.name=my-agent-service \
-Dotel.exporter.otlp.endpoint=http://localhost:4317 \
-Dotel.exporter.otlp.protocol=grpc \
-jar my-app.jar
```

启动应用，发几个请求，然后在 OpenObserve 的 Traces 页面就能看到完整的链路追踪了。

## 六、总结

| 维度 | 选择 | 理由 |
| --- | --- | --- |
| ** 采集标准 ** | OpenTelemetry | 业界标准，无厂商锁定 |
| ** 存储平台 ** | OpenObserve | 运维成本最低，部署极简 |
| ** 数据管道 ** | OTel Collector | 统一过滤、批量、转发 |

**我的选型建议**（仅供参考）：

- 🔹 个人开发者 / 小项目 → OpenObserve（快速落地）
- 🔹 已有 ClickHouse 经验 → SigNoz（生态成熟）
- 🔹 有专职 SRE / 大规模部署 → Grafana LGTM（功能最强）
- 🔹 阿里云生态 → 阿里云 ARMS（托管免运维）

> 技术选型没有银弹，适合自己当前阶段的就是最好的。

**参考资源**：

- OpenTelemetry 官方文档
- OpenObserve 官方文档
- OTel Collector 部署指南
- SigNoz GitHub
- Grafana docker-otel-lgtm

---
原文链接：https://mp.weixin.qq.com/s?__biz=MzA4Nzg2NTY2Mw%3D%3D&mid=2247486582&idx=1&sn=79d1491a8d13059122df241b39f077c2&chksm=91ec5ffaec81780ee67cb4b4d990c47b086063eeb7bc5505c5d53339f8aad156bd0766b3f892
