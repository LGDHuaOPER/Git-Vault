---
source_url: "https://mp.weixin.qq.com/s?__biz=MzIyMDY2MTE3Mw%3D%3D&mid=2247497066&idx=1&sn=2fc9b94887414d58d9a782da415c3559&chksm=97ca21b0a0bda8a63d25b83126479c6b08b00acc647889674f136272284504ab97a9701d76c6"
title: "OpenTelemetry 实战：统一可观测性数据采集"
account: "运维开发故事"
published_at: "2026-10-13 14:38:08"
saved_at: "2026-10-21 21:59:43"
sync_id: "art_684f4a864fcd44c58359c82264bd3035"
parse_status: "ok"
---

# OpenTelemetry 实战：统一可观测性数据采集

## 一、为什么需要统一采集

先说一个很多团队正在经历的现状：可观测性是三套东西拼起来的——

- Traces ：用了 Jaeger 的客户端，或者各语言自己接的 SDK
- Metrics ：用了 Prometheus 的 client library，或者 Micrometer
- Logs ：用了各自的日志框架，靠 Fluent Bit / Promtail 去扫文件

问题在哪？

- SDK 林立 ：一个 Java 服务要同时引 Jaeger client、Micrometer、SLF4J + 日志采集 agent。版本一冲突，排查问题的时间比写业务还多。
- 厂商锁定 ：数据格式是各家的。想从 Jaeger 换成 Tempo，得改一遍代码里的导出配置。
- 三套管线，三套运维 ：Collector、Prometheus、日志 agent 各自部署、各自监控、各自告警。复杂度乘法式增长。
- 关联缺失 ：Trace 和 Log 之间的 trace_id 各写各的，联不起来（第 7 篇讲的三支柱关联，底层就卡在这）。

OpenTelemetry（OTel）要解决的，就是把**采集这一层标准化**：一套 API/SDK，一种传输协议（OTLP），一个 Collector 处理管线，把三支柱的数据汇到任意后端。

**本文的立场**：OTel 不是要取代 Prometheus、Loki、Tempo，而是统一它们的**采集前端**。后端你该用啥用啥，但前面的 SDK 和管线，只维护一套。

## 二、OTel 是什么：三件套 + 一个协议

OpenTelemetry 由 CNCF 托管，已经毕业（Graduated），是云原生可观测性的事实标准。它的组成：

| 组件 | 作用 |
| --- | --- |
| ** Specification（规范） ** | 定义 API、数据模型、语义约定（哪些字段叫什么名字） |
| ** API / SDK ** | 各语言的代码库，负责生成遥测数据 |
| ** Collector ** | 可插拔的采集/处理/导出管线，OTel 的心脏 |
| ** OTLP ** | OpenTelemetry Protocol，统一的传输协议（gRPC + HTTP） |

记住一句话：**OTel 的标准化发生在&quot;生成&quot;和&quot;传输&quot;这两段，不在&quot;存储&quot;和&quot;展示&quot;那两段。** 所以它的定位是"与后端无关的前置层"。

```
应用（埋点） ──OTLP──▶ Collector（接收/处理/导出）──▶ Tempo / Prometheus / Loki
   SDK/自动注入                  receivers→processors→exporters        任意后端
```

## 三、架构：Instrumentation → OTLP → Collector → 后端

### 3.1 数据采集端（Instrumentation）

两种方式，都不用改业务代码：

**方式一：自动注入（推荐起步）**

OTel Operator 通过 Kubernetes 的 Mutating Webhook，在 Pod 创建时自动注入 instrumentation agent。开发者只加一个注解。

**方式二：手动 SDK（精细控制）**

在代码里引入 OTel SDK，手动埋关键路径（自定义 span、业务属性）。

绝大多数团队，90% 的覆盖度用方式一就能拿下，剩下 10% 的关键业务埋点用方式二补充。

### 3.2 传输协议（OTLP）

所有数据走 OTLP，默认两个端口：

- 4317 ：gRPC（默认、性能好）
- 4318 ：HTTP/Protobuf（防火墙不友好 gRPC 时的备选）

OTLP 同时承载 traces、metrics、logs 三种信号，这是"统一"的物理基础。

### 3.3 Collector 部署：Agent + Gateway 两件套

```
┌─────────────┐   ┌─────────────┐   ┌──────────────┐
│ Pod (Node)  │   │  Agent      │   │  Gateway     │   ┌────────┐
│ app + SDK   │──▶│ Collector   │──▶│ Collector    │──▶│ Tempo  │
│             │   │ (DaemonSet)│   │ (Deployment) │──▶│ Prom   │
└─────────────┘   └─────────────┘   └──────────────┘──▶│ Loki   │
                                                     └────────┘
```

| 模式 | 部署位置 | 职责 |
| --- | --- | --- |
| ** Agent ** | 每个节点 DaemonSet | 就近接收、做资源属性补充、批处理，转发给 Gateway |
| ** Gateway ** | 中心 Deployment | 汇聚、采样决策、导出到后端、统一鉴权 |

**为什么分两层？** Agent 兜底本地采集（即使 Gateway 挂了，Agent 还能缓存一批），Gateway 做集中的采样和路由。单体小规模也可以只部署 Gateway，Agent 不是必须。

## 四、零代码接入：OTel Operator 自动注入

这是落地成本最低的路径——开发者不改一行代码。

**第一步：部署 OTel Operator**

```bash
bashkubectl apply -f https://github.com/open-telemetry/opentelemetry-operator/releases/latest/download/opentelemetry-operator.yaml
```

**第二步：定义 Instrumentation（全局采集配置，写一次）**

```yaml
yamlapiVersion: opentelemetry.io/v1alpha1
kind: Instrumentation
metadata:
  name: otel-java-instrumentation
  namespace: observability
spec:
  exporter:
    endpoint: http://otel-gateway.observability:4317
  propagators:
    - tracecontext
    - baggage
  sampler:
    type: parentbased_traceidratio
    argument: "0.5"      # 50% 头采样（先保守，后面用 tail sampling 兜底）
  java:
    env:
      - name: OTEL_TRACES_SAMPLER
        value: "parentbased_traceidratio"
```

**第三步：业务 Deployment 加一个注解，自动注入**

```yaml
yamlapiVersion: apps/v1
kind: Deployment
metadata:
  name: payment-api
spec:
  template:
    metadata:
      annotations:
        # 引用上面定义的 Instrumentation，自动注入 Java agent
        instrumentation.opentelemetry.io/injected-java: "otel-java-instrumentation"
    spec:
      containers:
        - name: payment-api
          image: registry/payment-api:1.4.2
```

Pod 创建时，Operator 的 Webhook 自动：

- 注入 OTel Java agent 的 init container 和 JVM 参数
- 设置  `OTEL_*`  环境变量
- 应用无任何代码改动，启动即产出 traces + metrics

**各语言自动注入注解**：

| 语言 | 注解键 |
| --- | --- |
| Java |  `instrumentation.opentelemetry.io/injected-java`  |
| Python |  `instrumentation.opentelemetry.io/injected-python`  |
| Node.js |  `instrumentation.opentelemetry.io/injected-nodejs`  |
| .NET |  `instrumentation.opentelemetry.io/injected-dotnet`  |
| Go | 暂不支持自动注入（需手动 SDK） |

**没有 Operator 时的纯环境变量注入**（裸机 / 非 K8s）：

```bash
bash# Java：挂一个 javaagent
java -javaagent:/opt/opentelemetry-javaagent.jar \
  -Dotel.service.name=payment-api \
  -Dotel.exporter.otlp.endpoint=http://otel-gateway:4317 \
  -jar app.jar

# Python：用 opentelemetry-instrument 包装
opentelemetry-instrument \
  --traces_exporter otlp \
  --metrics_exporter otlp \
  --service_name payment-api \
  python app.py

# Node.js：用 auto-instrumentations 注册
NODE_OPTIONS="--require @opentelemetry/auto-instrumentations-node/register" \
  OTEL_EXPORTER_OTLP_ENDPOINT=http://otel-gateway:4317 \
  OTEL_SERVICE_NAME=payment-api \
  node app.js
```

## 五、Collector 配置实战

Collector 的配置是 OTel 的核心。一个生产可用的 Gateway 配置骨架：

```yaml
yaml# otel-collector-config.yaml
receivers:
  otlp:
    protocols:
      grpc:
        endpoint: 0.0.0.0:4317
      http:
        endpoint: 0.0.0.0:4318
  # 兼容存量 Jaeger（迁移期用）
  jaeger:
    protocols:
      grpc: {}
      thrift_http: {}
  # 兼容存量 Prometheus 抓取（迁移期用）
  prometheus:
    config:
      scrape_configs:
        - job_name: otel-collector
          static_configs:
            - targets: [0.0.0.0:8888]

processors:
  # 必须第一个：内存限流，防止 Collector 自己 OOM（核心稳定性）
  memory_limiter:
    check_interval: 1s
    limit_mib: 1500
    spike_limit_mib: 500

  # 批处理：攒一批再发，大幅降低后端压力（核心性能）
  batch:
    timeout: 5s
    send_batch_size: 1024

  # K8s 属性补充：自动加 namespace / pod / node / deployment 信息
  k8sattributes:
    auth_type: serviceAccount
    extract:
      metadata:
        - namespace
        - pod_name
        - deployment

  # 资源属性：统一加 cluster、环境等全局标签
  resource:
    attributes:
      - key: deployment.environment
        value: prod
        action: insert
      - key: k8s.cluster.name
        value: prod-cluster-01
        action: insert

  # 尾部采样（仅 traces）：错误和慢请求全留，其余抽样（成本控制核心）
  tail_sampling:
    decision_wait: 10s
    num_traces: 50000
    policies:
      - name: errors
        type: status_code
        status_code:
          status_codes: [ERROR]
      - name: slow
        type: latency
        latency:
          threshold_ms: 500
      - name: probabilistic
        type: probabilistic
        probabilistic:
          sampling_percentage: 10

exporters:
  # Traces → Tempo（走 OTLP/HTTP）
  otlphttp/tempo:
    endpoint: http://tempo:4318
  # Metrics → Prometheus（暴露抓取端点，复用现有 Prometheus）
  prometheus:
    endpoint: 0.0.0.0:8889
    resource_to_telemetry_conversion:
      enabled: true
  # Logs → Loki
  loki:
    endpoint: http://loki:3100/loki/api/v1/push
  # 调试用：打到 stdout
  debug:
    verbosity: normal

service:
  pipelines:
    traces:
      receivers: [otlp, jaeger]
      processors: [memory_limiter, k8sattributes, tail_sampling, batch]
      exporters: [otlphttp/tempo, debug]
    metrics:
      receivers: [otlp, prometheus]
      processors: [memory_limiter, k8sattributes, resource, batch]
      exporters: [prometheus, debug]
    logs:
      receivers: [otlp]
      processors: [memory_limiter, k8sattributes, resource, batch]
      exporters: [loki, debug]
```

**配置顺序的关键纪律**：

-  `memory_limiter`  必须 在 processors 列表最前面——它要尽早拦截内存压力
-  `batch`  放最后（导出前最后一道），把处理后的数据攒批发出
-  `tail_sampling`  只在 traces pipeline 用，且要在 batch 之前（先采样再批处理）
- metrics 不用 tail_sampling（采样会破坏指标聚合，metrics 用 recorder 端采样或 head sampling）

## 六、采样策略：成本控制的核心

全量采集 100% 的 trace，在百万 QPS 量级，存储和后端成本会瞬间爆掉。**采样不是可选优化，是必做项。**

**两级采样配合**：

| 级别 | 位置 | 策略 | 作用 |
| --- | --- | --- | --- |
| ** 头采样（head） ** | SDK 端 |  `parentbased_traceidratio`  50% | 入口处就丢掉一半，降低采集和传输压力 |
| ** 尾采样（tail） ** | Gateway | 错误 100% + 慢请求 100% + 其余 10% | 保证有价值的 trace 不丢 |

**为什么两级都要？** 头采样在源头省带宽，但它是"盲采"——不知道这条 trace 会不会出错。尾采样能看到完整结果（失败/慢），但已经付出了采集成本。两者配合：**头采样砍量，尾采样保质**。

**尾采样配置（上面 config 已含）的关键点**：

-  `decision_wait: 10s`  ：等 10 秒让整条 trace 的 span 到齐再决定，避免"这条没采样但子 span 采样了"的断裂
- 错误和慢请求全留——你最该看的就是这两者
- 概率采样兜底 10%：保留足够样本看整体形态

**指标和日志一般不采样**（或极轻量采样）：指标是聚合值，丢采样点会失真；日志靠日志级别过滤（INFO 以下不采）比采样更合理。

## 七、接入已有的系统：从 Jaeger / Prometheus 迁移

OTel 的 receiver 设计就是为了"无痛接管存量"。迁移期可以并行运行，逐步切换：

| 存量系统 | OTel Receiver | 迁移动作 |
| --- | --- | --- |
| Jaeger client |  `jaeger`  receiver | 应用端的 Jaeger exporter 指向 Collector 的 jaeger 端口 |
| Zipkin |  `zipkin`  receiver | 指向 Collector 的 zipkin 端口 |
| Prometheus 抓取 |  `prometheus`  receiver | 把 scrape 配置搬进 Collector，或保留 Prometheus 直采 |
| 自定义 OTLP |  `otlp`  receiver | 直接对接 |

**迁移节奏**：

- 阶段一 ：Collector 上线，开启 otlp + jaeger + zipkin receivers，同时导出到 Tempo（新）和旧的 Jaeger（旧）。两边都有数据，校验一致。
- 阶段二 ：应用的 trace exporter 从直连 Jaeger 改为直连 Collector。旧 Jaeger 逐步无人写入。
- 阶段三 ：关闭旧 Jaeger，Collector 作为唯一 trace 入口。

**存量 Prometheus 的处理**：不必急着动。Prometheus 继续抓你的 RED/USE 指标，OTel 只接管"应用主动埋点"和"trace/log"两件事。等时机成熟，再用  `prometheus`  receiver 把抓取任务收编进 Collector。不要为了统一而统一—— **稳定优先**。

## 八、日志采集：filelog + 与 Trace 关联

OTel 也能统一采日志（第 11 篇讲的 Loki 日志，前面的采集端可以换成 OTel）。

**用 filelog receiver 扫容器日志**：

```yaml
yamlreceivers:
  filelog:
    include: [/var/log/pods/*/*/*.log]
    start_at: beginning
    operators:
      - type: docker
        stream: stdout
      - type: regex
        regex: '^(?P<ts>\S+) (?P<level>\w+) (?P<msg>.*)$'
      - type: traceparser      # 从日志里提取 trace_id，打通关联
        trace_id:
          regex: 'trace_id["\s:=]+([0-9a-f]{32})'

exporters:
  loki:
    endpoint: http://loki:3100/loki/api/v1/push

service:
  pipelines:
    logs:
      receivers: [filelog]
      processors: [memory_limiter, k8sattributes, batch]
      exporters: [loki]
```

**关键价值**： `traceparser`  operator 从日志里提取  `trace_id` ，写入 Loki 的 label。这样在 Tempo 看到一条慢 trace，点开就能直接跳到这条请求对应的所有日志—— **第 7 篇讲的三支柱关联，底层就靠这个**。

## 九、避坑指南

### 坑一：漏了 memory_limiter，Collector 自己 OOM

**现象**：流量高峰时 Collector 内存暴涨被 K8s 杀掉，整个采集管线断流，比没监控还糟。

**解法**： `memory<em>limiter`  必须第一个处理器，且 limitmib 要根据 Pod 内存 limit 留 20% 余量。这是 OTel 部署的头号稳定性开关。

### 坑二：不用 batch，后端被小包淹没

**现象**：每个 span 单独导出，Tempo/Prometheus 连接数被打满，处理延迟飙升。

**解法**：batch processor 必配， `send<em>batch</em>size`  1024、 `timeout`  5s。攒批后导出，后端压力降一个数量级。

### 坑三：100% 采样，成本爆炸

**现象**：trace 量随流量线性增长，月度账单第一个月还能扛，流量翻倍就崩。

**解法**：头采样（SDK）+ 尾采样（Gateway）两级都要。错误/慢请求全留，正常流量抽样 10-50%。日志靠 level 过滤而非采样。

### 坑四：OTLP 版本不一致，数据静默丢失

**现象**：新旧 Collector / SDK 的 OTLP 协议版本混用，部分字段丢失或整条丢弃，且没有明显报错。

**解法**：统一 OTel 组件版本到同一发版线；升级时先升 Collector 再升 SDK；用  `debug`  exporter 抽样验证字段完整。

### 坑五：自动注入注解写错，Pod 没埋上

**现象**：注解加了但没生效，trace 一片空白。

**解法**：确认注解在  `spec.template.metadata.annotations` （pod template 上，不是 deployment metadata）；确认 Operator 的 Webhook 已就绪；看 Pod 是否多了一个 init container（注入成功的标志）。

### 坑六：日志被双重采集

**现象**：同一份容器日志，OTel 的 filelog 扫了一遍，Fluent Bit / Promtail 又扫了一遍，Loki 里重复。

**解法**：迁移到 OTel 采日志时，关掉原有的日志 agent；用统一的采集入口，避免两条管线抢同一份文件。

## 十、写在最后

OpenTelemetry 的价值不只是"少写几个 SDK"——它把可观测性的**采集前端标准化**了。带来的连锁反应：

- 后端自由 ：今天用 Tempo + Prometheus + Loki，明天想换，采集端一行不用动
- 三支柱贯通 ：统一协议让 trace、metric、log 共享同一套语义约定和属性，关联是天然的（第 7 篇的"三支柱关联"终于有了地基）
- 成本可控 ：Collector 的采样和批处理集中管理，告别各后端各自为战的账单

它和前面几篇是同一张网：**Prometheus vs VM**（第 5 篇）解决 metrics 存储选型，**ELK→Loki 迁移**（第 11 篇）解决日志存储选型，**本文**解决前面那一公里的"怎么统一采"。三者叠加，就是一套完整、开放、不被锁定的可观测性体系。

从今天起做一件事：在测试环境部署一个 Collector，给一个 Java 服务加那行注解，看 traces 能不能进 Tempo。十分钟，你就摸到了 OTel 的门槛。

---
原文链接：https://mp.weixin.qq.com/s?__biz=MzIyMDY2MTE3Mw%3D%3D&mid=2247497066&idx=1&sn=2fc9b94887414d58d9a782da415c3559&chksm=97ca21b0a0bda8a63d25b83126479c6b08b00acc647889674f136272284504ab97a9701d76c6
