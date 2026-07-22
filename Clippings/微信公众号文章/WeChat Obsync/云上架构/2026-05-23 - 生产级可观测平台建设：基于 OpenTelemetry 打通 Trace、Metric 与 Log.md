---
source_url: "https://mp.weixin.qq.com/s?__biz=MzYzMjIxOTMxNg==&mid=2247484945&idx=2&sn=d62255e00b245a684aa39853e99c8159&chksm=f13b2e4843719a60468cb080862a373624080523811e6db55faf8edec587ee26c29612126037&mpshare=1&scene=1&srcid=0601qTPIbqZRkJMJ0CHN1RbY&sharer_shareinfo=fa8c0bba38631403df6146ab0f0ecbf8&sharer_shareinfo_first=fa8c0bba38631403df6146ab0f0ecbf8"
title: "生产级可观测平台建设：基于 OpenTelemetry 打通 Trace、Metric 与 Log"
account: "云上架构"
published_at: "2026-05-23T08:57:06.000Z"
saved_at: "2026-07-20T07:55:31.716Z"
sync_id: "art_1ecd18e4f93248c9b9af5b7e8f118f1c"
parse_status: "ok"
---

# 生产级可观测平台建设：基于 OpenTelemetry 打通 Trace、Metric 与 Log

# 生产级可观测平台建设：基于 OpenTelemetry 打通 Trace、Metric 与 Log

> 面向 Java 微服务与 Kubernetes 场景，构建一套可落地、可扩展、可治理的统一可观测平台。核心目标不是“多接几个监控组件”，而是用统一数据模型、统一采集链路和统一关联能力，把故障定位从“翻日志、猜链路、看大盘”升级为“从告警直达根因”。

## 1. 背景：为什么需要统一可观测平台

### 1.1 典型故障现场

某天凌晨 2 点，支付接口告警： `/pay/confirm`  的 P99 延迟从 80 ms 上升到 3.2 s，错误率没有明显升高。

排查过程通常是这样的：

| 系统 | 看到的信息 | 问题 |
| --- | --- | --- |
| Prometheus + Grafana | CPU、内存、QPS 正常，P99 明显升高 | 只能说明“慢了”，不能直接说明“哪里慢” |
| ELK / Loki | 应用无明显 ERROR 日志 | 只能说明“没报错”，不能说明“没异常” |
| Jaeger / Zipkin / Tempo | 个别调用链显示 Redis、线程池、DB 都有波动 | Trace 与指标、日志割裂，定位仍靠人工拼图 |

最后发现根因不是 Redis，也不是数据库，而是支付服务内部线程池队列堆积。线程池拒绝策略没有触发 ERROR，只是请求在队列中长时间等待，导致 P99 延迟升高。

这类问题的本质不是“监控系统不够多”，而是三类信号没有关联：

- • Metric 告诉你系统变慢了；
- • Trace 告诉你一次请求经过了哪些节点；
- • Log 告诉你某段业务逻辑发生了什么；
- • 但如果三者不能通过 trace_id 、 span_id 、 service.name 、 deployment.environment 等维度统一起来，排障仍然是人工拼图。

### 1.2 传统监控烟囱的问题

传统方案通常是三条独立链路：

```
Metric  -> Prometheus / VictoriaMetrics / Mimir -> Grafana
Trace   -> Jaeger / Zipkin / Tempo              -> Trace UI
Log     -> Filebeat / Logstash / Fluent Bit     -> Elasticsearch / Loki
```

这会带来几个工程问题：

- 1. 采集链路重复 ：每类信号都有自己的 Agent、协议、缓冲和重试机制。
- 2. 字段语义不一致 ：同一个服务可能在日志中叫 pay-service ，在指标中叫 payment ，在 Trace 中叫 payment-service 。
- 3. 上下文断裂 ：日志没有 trace_id ，Metric 没有 Exemplar，Trace 里看不到关键业务维度。
- 4. 治理困难 ：高基数字段、敏感字段、采样策略、租户隔离分散在不同系统里。
- 5. 扩展成本高 ：当服务规模、请求量和集群数量上升后，采集端、存储端和查询端都会各自膨胀。

### 1.3 OpenTelemetry 的定位

OpenTelemetry 的价值不是替代 Prometheus、Loki、Tempo、Jaeger 或 Grafana，而是提供一套统一的可观测标准：

```
Application
│
├─ OpenTelemetry API / SDK / Java Agent
│
├─ Trace  -> Span
├─ Metric -> Counter / Histogram / Gauge
└─ Log    -> LogRecord
│
▼
OTLP Protocol
│
▼
OpenTelemetry Collector
│
├─ enrich / filter / sample / batch / route
│
├─ traces  -> Tempo / Jaeger / Kafka
├─ metrics -> Prometheus / Mimir / VictoriaMetrics
└─ logs    -> Loki / Elasticsearch / Kafka
```

它解决的核心问题是：

- • 用统一协议 OTLP 传输 Trace、Metric、Log；
- • 用统一资源模型描述服务、实例、环境、版本、集群；
- • 用统一 Collector 做采集、处理、路由、采样和脱敏；
- • 用统一语义规范约束字段命名；
- • 用统一上下文传播机制把一次请求跨服务串起来。

## 2. 核心原理：OpenTelemetry 如何统一三类信号

### 2.1 数据模型：Resource、Scope 与 Signal

OpenTelemetry 的数据模型可以理解为三层：

```
Resource
└─ InstrumentationScope
├─ Span
├─ Metric DataPoint
└─ LogRecord
```

#### 2.1.1 Resource：描述“谁产生了数据”

`Resource`  是所有信号的公共身份信息，典型字段包括：

| 字段 | 示例 | 说明 |
| --- | --- | --- |
| `service.name` | `payment-service` | 服务名，必须统一 |
| `service.namespace` | `mall` | 服务所属业务域 |
| `service.version` | `1.8.3` | 版本号，用于灰度和回滚分析 |
| `deployment.environment.name` | `prod` | 环境，如 dev、test、pre、prod |
| `k8s.namespace.name` | `payment` | Kubernetes 命名空间 |
| `k8s.pod.name` | `payment-xxx` | Pod 名称 |
| `cloud.region` | `ap-northeast-1` | 云区域 |

生产中一定要优先治理  `Resource` ，因为后续所有查询、告警、成本归因和租户隔离都依赖它。

#### 2.1.2 InstrumentationScope：描述“谁采集了数据”

`InstrumentationScope`  用于标识数据来自哪个库或哪个埋点模块，例如：

```
io.opentelemetry.spring-webmvc
io.opentelemetry.jdbc
com.company.payment.business
```

这对排查自动埋点与手动埋点的边界很有用。比如一个数据库 Span 由 JDBC 自动生成，而一个支付风控 Span 由业务代码手动生成，两者应该在 Scope 上有所区分。

#### 2.1.3 Signal：Trace、Metric 与 Log

| 信号 | 主要对象 | 适合回答的问题 |
| --- | --- | --- |
| Trace | Span、Trace、Span Event、Link | 一次请求经过了哪里，哪里耗时，哪里报错 |
| Metric | Counter、Histogram、Gauge、UpDownCounter | 系统整体趋势、吞吐、延迟、错误率、资源水位 |
| Log | LogRecord、结构化日志 | 某个业务动作的详细上下文和异常信息 |

真正的统一可观测，不是把三类数据放进同一个 UI，而是让它们共享统一维度，并能相互跳转。

### 2.2 Trace：Span、Context 与跨进程传播

Trace 表示一次完整请求链路；Span 表示链路中的一个操作。

```
Trace: 创建订单请求
├─ Span A: HTTP POST /orders
│    ├─ Span B: check inventory
│    ├─ Span C: call payment-service
│    │    └─ Span D: payment confirm
│    └─ Span E: insert order table
```

每个 Span 都包含：

- • trace_id ：整条链路的全局 ID；
- • span_id ：当前 Span ID；
- • parent_span_id ：父 Span ID；
- • span.kind ：SERVER、CLIENT、PRODUCER、CONSUMER、INTERNAL；
- • Attributes：HTTP、DB、MQ、业务字段；
- • Events：Span 内部事件，如重试、降级、限流；
- • Status：OK、ERROR 或 UNSET。

跨服务传播依赖 W3C Trace Context，典型请求头如下：

```
traceparent: 00-4bf92f3577b34da6a3ce929d0e0e4736-00f067aa0ba902b7-01
tracestate: vendor=value
```

只要网关、HTTP 客户端、RPC 框架、MQ 生产者和消费者都正确传播上下文，一次请求即使跨多个服务、多个线程、多个消息队列，也能被串成完整 Trace。

### 2.3 Metric：从“系统指标”到“业务指标”

Metric 不是只有 CPU、内存、QPS。生产系统里至少要分三层：

| 层级 | 示例 | 用途 |
| --- | --- | --- |
| 基础设施指标 | CPU、内存、磁盘、网络、Pod 重启次数 | 判断基础资源状态 |
| 运行时指标 | JVM GC、线程池、连接池、HTTP 延迟 | 判断服务运行状态 |
| 业务指标 | 下单数、支付成功率、库存扣减失败数、订单金额分布 | 判断业务健康度 |

常用指标类型：

| 类型 | 适用场景 | 示例 |
| --- | --- | --- |
| Counter | 单调递增计数 | 请求数、错误数、订单数 |
| Histogram | 分布统计 | HTTP 延迟、订单金额、DB 查询耗时 |
| Gauge | 当前值 | 队列长度、CPU 使用率、库存余量 |
| UpDownCounter | 可增可减 | 当前在线人数、活跃任务数 |

生产中最推荐优先建设 Histogram，因为延迟、金额、耗时这类数据不仅要看平均值，更要看 P95、P99、最大值和分布。

### 2.4 Log：从文本日志到结构化日志

传统日志常见问题：

```
2026-05-23 10:01:00 INFO create order success user=1001 amount=299
```

看起来能读，但不适合机器检索。生产建议使用结构化 JSON 日志：

```
{
"timestamp": "2026-05-23T10:01:00.123+09:00",
"level": "INFO",
"service.name": "order-service",
"trace_id": "4bf92f3577b34da6a3ce929d0e0e4736",
"span_id": "00f067aa0ba902b7",
"event": "order_created",
"order.id": "O202605230001",
"order.amount": 299.00,
"order.channel": "app"
}
```

这样可以做到：

- • 从 Trace 一键跳到同 TraceID 的日志；
- • 从日志反查对应请求链路；
- • 在 Loki / Elasticsearch 中按字段过滤；
- • 对业务事件做审计与分析。

### 2.5 Sampling：采样策略决定成本与可用性

Trace 数据量通常远高于日志和指标。没有采样，系统很容易被 Trace 存储拖垮。

采样分两类：

| 类型 | 发生位置 | 优点 | 缺点 | 适合场景 |
| --- | --- | --- | --- | --- |
| Head Sampling | SDK / Agent 端 | 成本低、简单、性能好 | 请求刚开始就决定，无法知道后面是否报错或变慢 | 大规模普通流量 |
| Tail Sampling | Collector 端 | 可以根据完整 Trace 决定是否保留 | Collector 内存压力大，需要缓存 Trace | 保留错误、慢请求、关键交易 |

生产建议：

```
SDK / Agent：ParentBased + TraceIdRatioBased，降低入口数据量
Collector：Tail Sampling，保留 ERROR、慢请求、核心业务请求
```

推荐策略：

- • 错误 Trace：100% 保留；
- • 慢请求 Trace：100% 保留；
- • 支付、下单、退款等核心链路：提高采样率或强制保留；
- • 普通健康请求：按比例采样；
- • 健康检查、静态资源、无价值端点：直接过滤。

### 2.6 Exemplar：Metric 与 Trace 的桥梁

当 Grafana 里看到某个接口 P99 突然升高时，通常还要去 Trace 系统里搜索慢请求。Exemplar 解决的就是这个跳转问题：Metric 的某个数据点可以附带一个具体的  `trace_id` 。

```
HTTP latency histogram bucket
└─ exemplar
├─ value: 3.2s
├─ trace_id: 4bf92f3577b34da6a3ce929d0e0e4736
└─ span_id: 00f067aa0ba902b7
```

有了 Exemplar，排障路径会变成：

```
告警 -> Grafana 指标图 -> 点击 Exemplar -> 进入具体 Trace -> 查看相关日志
```

这才是统一可观测平台真正提升效率的地方。

## 3. 总体架构设计

### 3.1 推荐生产架构

面向中大型 Java 微服务，推荐使用“Agent + Gateway Collector + Kafka + 后端存储”的架构：

```
┌─────────────────────────────────────────────────────────────┐
│ Application Layer                                           │
│                                                             │
│  Spring Boot / Dubbo / Gateway / Worker / Scheduler         │
│       │                                                     │
│       ├─ OpenTelemetry Java Agent                           │
│       ├─ Manual Instrumentation for business spans/metrics   │
│       └─ JSON Logs with trace_id/span_id                     │
└───────┬─────────────────────────────────────────────────────┘
│ OTLP gRPC / HTTP
▼
┌─────────────────────────────────────────────────────────────┐
│ OpenTelemetry Collector Gateway                             │
│                                                             │
│  receivers: otlp                                            │
│  processors: memory_limiter / k8sattributes / filter        │
│              transform / batch / tail_sampling              │
│  exporters: kafka / prometheusremotewrite / otlphttp / loki │
└───────┬─────────────────────────────────────────────────────┘
│
├─────────────── traces ───────────────┐
│                                      ▼
│                              Kafka / Tempo
│
├─────────────── metrics ──────────────► Mimir / Prometheus / VictoriaMetrics
│
└─────────────── logs ─────────────────► Loki / Elasticsearch

▼
Grafana
Dashboard / Explore / Alert / TraceQL / LogQL / PromQL
```

### 3.2 为什么不建议应用直接写存储

应用直接写 Tempo、Loki 或 Prometheus Remote Write 看似简单，但生产中容易出现几个问题：

- 1. 后端存储抖动会直接反压业务应用；
- 2. 采样、脱敏、字段治理分散在各个应用里；
- 3. 多语言 SDK 配置不一致，后续维护困难；
- 4. 存储切换时需要修改所有应用配置；
- 5. 缺少统一缓冲层，流量尖峰时容易丢数据。

Collector 的价值在于把可观测数据从业务应用中解耦出来。

### 3.3 Collector 部署模式

| 模式 | 架构 | 优点 | 缺点 | 推荐场景 |
| --- | --- | --- | --- | --- |
| Sidecar | 每个 Pod 一个 Collector | 隔离性好，应用本地上报 | 资源消耗大，配置分散 | 高安全隔离、特殊租户 |
| DaemonSet Agent | 每个节点一个 Collector | 适合采集节点和 Pod 元数据 | Trace 路由能力有限 | 基础设施指标、日志采集 |
| Gateway | 集群部署一组 Collector | 策略集中、易扩展、易治理 | 需要做好高可用和限流 | 微服务 Trace / Metric / Log 主链路 |
| 混合模式 | Agent + Gateway | 能力最完整 | 架构稍复杂 | 中大型生产环境 |

推荐落地方式：

```
应用 OTLP -> Gateway Collector
节点指标 / 容器日志 -> DaemonSet Collector / Fluent Bit
Gateway Collector -> Kafka / Mimir / Tempo / Loki
```

## 4. 技术选型

### 4.1 后端组件选型

| 能力 | 推荐组件 | 说明 |
| --- | --- | --- |
| Trace 存储 | Grafana Tempo | 成本低，适合大规模 Trace，对象存储友好，支持 TraceQL |
| Metric 存储 | Mimir / VictoriaMetrics / Prometheus | 小规模用 Prometheus，中大规模用 Mimir 或 VictoriaMetrics |
| Log 存储 | Loki / Elasticsearch | Loki 成本低、与 Grafana 结合好；ES 适合复杂全文检索 |
| 缓冲层 | Kafka | 削峰、解耦、回放、后端故障缓冲 |
| UI | Grafana | 统一 Dashboard、Explore、Alert、Trace/Log/Metric 跳转 |
| 采集标准 | OpenTelemetry Collector | 统一接入、治理、采样、脱敏、路由 |

### 4.2 Jaeger、Tempo 与 Zipkin 如何选择

| 组件 | 优点 | 局限 | 建议 |
| --- | --- | --- | --- |
| Zipkin | 简单，历史悠久 | 查询能力和生态相对有限 | 适合遗留系统兼容 |
| Jaeger | 成熟，生态广 | 大规模存储成本和运维复杂度较高 | 适合已有 Jaeger 体系 |
| Tempo | 成本低，Grafana 生态强，TraceQL 能力好 | 对 Grafana 体系依赖更强 | 新建平台优先考虑 |

### 4.3 Prometheus、Mimir 与 VictoriaMetrics 如何选择

| 规模 | 推荐方案 |
| --- | --- |
| 单集群、小规模 | Prometheus + Grafana |
| 多服务、中等规模 | Prometheus Agent / Collector + Mimir / VictoriaMetrics |
| 多集群、大规模 | Mimir 分布式或 VictoriaMetrics Cluster |

## 5. 标准化字段设计

### 5.1 服务身份字段

所有应用必须统一以下字段：

```
service.name
service.namespace
service.version
deployment.environment.name
service.instance.id
k8s.cluster.name
k8s.namespace.name
k8s.pod.name
```

推荐命名规范：

```
service.name = order-service
service.namespace = mall
deployment.environment.name = prod
service.version = 1.8.3
```

不要出现以下情况：

```
payment
pay-service
payment-service
payment_svc
```

同一个服务在不同信号中必须使用同一个名字。

### 5.2 业务字段治理

业务字段不能随意加。建议分三类：

| 类型 | 示例 | 是否适合放入 Trace Attribute | 是否适合放入 Metric Label |
| --- | --- | --- | --- |
| 低基数 | `order.channel=app` 、 `payment.method=wechat` | 是 | 是 |
| 中基数 | `merchant.id` 、 `region.code` | 谨慎 | 谨慎 |
| 高基数 | `user.id` 、 `order.id` 、 `request.id` | Trace 可用，Metric 不建议 | 否 |

高基数字段放到 Metric Label 会导致时间序列爆炸，轻则查询变慢，重则存储雪崩。

### 5.3 敏感字段治理

以下字段禁止直接进入可观测系统：

```
Authorization
Cookie
Set-Cookie
password
token
id_card
phone
email
bank_card
完整 SQL 参数
```

治理方式：

- • 在 SDK 端不要采集；
- • 在 Collector 端二次删除或 hash；
- • 对日志框架增加脱敏拦截器；
- • 对 db.statement 做限制，避免明文参数进入 Trace。

## 6. Java 服务接入方案

### 6.1 推荐接入策略

Java 微服务推荐采用“两层接入”：

```
Java Agent 自动埋点：HTTP、JDBC、Redis、MQ、RPC、JVM、线程池
手动埋点：核心业务 Span、业务指标、关键事件
```

不要一开始就全靠手写埋点。自动埋点解决 70% 的通用链路，手动埋点只放在业务关键路径。

### 6.2 Maven 依赖

建议业务代码只引入 API 和注解，SDK 与 Exporter 尽量交给 Java Agent 或自动配置管理。

```

io.opentelemetry
opentelemetry-bom
1.41.0
pom
import

io.opentelemetry
opentelemetry-api

io.opentelemetry.instrumentation
opentelemetry-instrumentation-annotations
2.15.0

net.logstash.logback
logstash-logback-encoder
8.0

```

版本建议以企业内部 BOM 统一锁定，不要每个服务单独升级。

### 6.3 Java Agent 启动方式

```
java \
-javaagent:/opt/otel/opentelemetry-javaagent.jar \
-Dotel.service.name=order-service \
-Dotel.resource.attributes=service.namespace=mall,service.version=1.8.3,deployment.environment.name=prod,k8s.cluster.name=prod-a \
-Dotel.exporter.otlp.endpoint=http://otel-collector-gateway:4317 \
-Dotel.exporter.otlp.protocol=grpc \
-Dotel.traces.exporter=otlp \
-Dotel.metrics.exporter=otlp \
-Dotel.logs.exporter=none \
-Dotel.traces.sampler=parentbased_traceidratio \
-Dotel.traces.sampler.arg=0.1 \
-Dotel.instrumentation.runtime-telemetry.enabled=true \
-jar app.jar
```

说明：

- • Trace 和 Metric 由 OTel 上报；
- • Log 建议先走应用标准输出，由日志采集链路进入 Loki/ES；
- • Java Agent 会自动把 trace_id 、 span_id 注入日志 MDC；
- • 业务日志是否直接走 OTLP Logs，需要结合团队日志平台成熟度决定。

### 6.4 Kubernetes 注入方式

生产环境不建议每个 Deployment 手写一大段 JVM 参数，可以用环境变量统一注入：

```
apiVersion: apps/v1
kind: Deployment
metadata:
name: order-service
spec:
template:
metadata:
labels:
app: order-service
spec:
containers:
- name: order-service
image: registry.example.com/mall/order-service:1.8.3
env:
- name: JAVA_TOOL_OPTIONS
value: >-
-javaagent:/otel/opentelemetry-javaagent.jar
- name: OTEL_SERVICE_NAME
value: order-service
- name: OTEL_RESOURCE_ATTRIBUTES
value: service.namespace=mall,service.version=1.8.3,deployment.environment.name=prod,k8s.cluster.name=prod-a
- name: OTEL_EXPORTER_OTLP_ENDPOINT
value: http://otel-collector-gateway.observability:4317
- name: OTEL_EXPORTER_OTLP_PROTOCOL
value: grpc
- name: OTEL_TRACES_SAMPLER
value: parentbased_traceidratio
- name: OTEL_TRACES_SAMPLER_ARG
value: "0.1"
- name: OTEL_INSTRUMENTATION_RUNTIME_TELEMETRY_ENABLED
value: "true"
volumeMounts:
- name: otel-agent
mountPath: /otel
volumes:
- name: otel-agent
emptyDir: {}
```

更成熟的方式是使用 OpenTelemetry Operator 做自动注入，减少应用侧配置复杂度。

## 7. 生产级业务代码示例

### 7.1 订单创建场景

场景：订单服务接收创建订单请求，依次完成库存校验、支付确认、订单落库和消息发送。

目标：

- • 关键业务步骤有 Span；
- • 失败时记录异常和错误状态；
- • 业务指标可用于告警；
- • 日志自动携带 TraceID；
- • 异步线程不丢上下文。

### 7.2 Controller 示例

```
@RestController
@RequestMapping("/api/orders")
@RequiredArgsConstructor
public class OrderController {

private final OrderApplicationService orderApplicationService;

@PostMapping
public ResponseEntity createOrder(@RequestBody CreateOrderRequest request) {
OrderCreateResponse response = orderApplicationService.createOrder(request);
return ResponseEntity.ok(response);
}
}
```

HTTP SERVER Span 由 Java Agent 自动创建，Controller 通常不需要手动创建 Span。

### 7.3 业务服务手动埋点

```
@Service
@Slf4j
@RequiredArgsConstructor
public class OrderApplicationService {

private final InventoryClient inventoryClient;
private final PaymentClient paymentClient;
private final OrderRepository orderRepository;
private final ApplicationEventPublisher eventPublisher;
private final OpenTelemetry openTelemetry;

private Tracer tracer;
private LongCounter orderCreatedCounter;
private LongCounter orderFailedCounter;
private DoubleHistogram orderAmountHistogram;
private DoubleHistogram orderCreateLatencyHistogram;

@PostConstruct
public void init() {
this.tracer = openTelemetry.getTracer("com.example.mall.order", "1.0.0");

Meter meter = openTelemetry.getMeter("com.example.mall.order");

this.orderCreatedCounter = meter.counterBuilder("business.order.created")
.setDescription("Total number of created orders")
.setUnit("{order}")
.build();

this.orderFailedCounter = meter.counterBuilder("business.order.failed")
.setDescription("Total number of failed order creations")
.setUnit("{order}")
.build();

this.orderAmountHistogram = meter.histogramBuilder("business.order.amount")
.setDescription("Order amount distribution")
.setUnit("CNY")
.build();

this.orderCreateLatencyHistogram = meter.histogramBuilder("business.order.create.duration")
.setDescription("Order creation duration")
.setUnit("ms")
.build();
}

public OrderCreateResponse createOrder(CreateOrderRequest request) {
long startNanos = System.nanoTime();

Span span = tracer.spanBuilder("order.create")
.setSpanKind(SpanKind.INTERNAL)
.setAttribute("order.channel", request.channel())
.setAttribute("payment.method", request.paymentMethod())
.setAttribute("product.id", request.productId())
.startSpan();

try (Scope scope = span.makeCurrent()) {
log.info("Start creating order, productId={}, channel={}", request.productId(), request.channel());

checkInventory(request);
PaymentResult paymentResult = confirmPayment(request);
Order order = saveOrder(request, paymentResult);
publishOrderCreatedEvent(order);

Attributes metricAttrs = Attributes.builder()
.put("order.channel", request.channel())
.put("payment.method", request.paymentMethod())
.build();

orderCreatedCounter.add(1, metricAttrs);
orderAmountHistogram.record(request.amount().doubleValue(), metricAttrs);

span.setAttribute("order.id", order.getId());
span.setAttribute("order.result", "success");
span.setStatus(StatusCode.OK);

log.info("Order created successfully, orderId={}", order.getId());
return new OrderCreateResponse(order.getId(), "SUCCESS");

} catch (BusinessException ex) {
recordFailure(span, request, ex, ex.getCode());
throw ex;
} catch (Exception ex) {
recordFailure(span, request, ex, "SYSTEM_ERROR");
throw ex;
} finally {
long costMs = TimeUnit.NANOSECONDS.toMillis(System.nanoTime() - startNanos);
orderCreateLatencyHistogram.record(costMs, Attributes.of(
AttributeKey.stringKey("order.channel"), request.channel()
));
span.end();
}
}

@WithSpan("order.inventory.check")
protected void checkInventory(CreateOrderRequest request) {
Span current = Span.current();
current.setAttribute("product.id", request.productId());
current.setAttribute("order.quantity", request.quantity());

InventoryResult result = inventoryClient.check(request.productId(), request.quantity());
if (!result.success()) {
current.setStatus(StatusCode.ERROR, "Inventory insufficient");
throw new BusinessException("INVENTORY_NOT_ENOUGH", "Inventory insufficient");
}
}

private PaymentResult confirmPayment(CreateOrderRequest request) {
Span span = tracer.spanBuilder("order.payment.confirm")
.setSpanKind(SpanKind.CLIENT)
.setAttribute("payment.method", request.paymentMethod())
.setAttribute("payment.amount", request.amount().doubleValue())
.startSpan();

try (Scope scope = span.makeCurrent()) {
PaymentResult result = paymentClient.confirm(request.userId(), request.amount(), request.paymentMethod());
if (!result.success()) {
span.setStatus(StatusCode.ERROR, result.errorCode());
throw new BusinessException(result.errorCode(), result.errorMessage());
}
span.setAttribute("payment.transaction_id", result.transactionId());
return result;
} catch (Exception ex) {
span.recordException(ex);
span.setStatus(StatusCode.ERROR, ex.getMessage());
throw ex;
} finally {
span.end();
}
}

@WithSpan("order.persist")
protected Order saveOrder(CreateOrderRequest request, PaymentResult paymentResult) {
Order order = Order.create(request, paymentResult.transactionId());
return orderRepository.save(order);
}

@WithSpan("order.event.publish")
protected void publishOrderCreatedEvent(Order order) {
eventPublisher.publishEvent(new OrderCreatedEvent(order.getId(), order.getUserId()));
}

private void recordFailure(Span span, CreateOrderRequest request, Exception ex, String errorCode) {
span.recordException(ex);
span.setStatus(StatusCode.ERROR, errorCode);
span.setAttribute("order.result", "failed");
span.setAttribute("error.code", errorCode);

orderFailedCounter.add(1, Attributes.of(
AttributeKey.stringKey("order.channel"), request.channel(),
AttributeKey.stringKey("error.code"), errorCode
));

log.warn("Create order failed, errorCode={}, productId={}, channel={}",
errorCode, request.productId(), request.channel(), ex);
}
}
```

### 7.4 异步线程上下文传递

异步任务是 Trace 断链的高发点。错误写法：

```
executorService.submit(() -> {
// Span.current() 可能为空
sendCoupon(orderId);
});
```

正确写法：

```
Context context = Context.current();
executorService.submit(context.wrap(() -> sendCoupon(orderId)));
```

如果是统一线程池，可以封装：

```
public class TraceContextAwareExecutor implements Executor {

private final Executor delegate;

public TraceContextAwareExecutor(Executor delegate) {
this.delegate = delegate;
}

@Override
public void execute(Runnable command) {
Context context = Context.current();
delegate.execute(context.wrap(command));
}
}
```

### 7.5 Kafka 消息上下文传播

生产者发送消息时，Java Agent 通常会自动把 TraceContext 写入消息头。如果需要手动处理，可使用 TextMapPropagator。

```
@Component
@RequiredArgsConstructor
public class OrderEventProducer {

private final KafkaTemplate kafkaTemplate;
private final OpenTelemetry openTelemetry;

public void send(OrderCreatedEvent event) {
ProducerRecord record = new ProducerRecord<>(
"order-created-topic",
event.orderId(),
JsonUtils.toJson(event)
);

openTelemetry.getPropagators()
.getTextMapPropagator()
.inject(Context.current(), record, (carrier, key, value) -> {
if (carrier != null) {
carrier.headers().add(key, value.getBytes(StandardCharsets.UTF_8));
}
});

kafkaTemplate.send(record);
}
}
```

消费者读取：

```
@Component
@RequiredArgsConstructor
@Slf4j
public class OrderEventConsumer {

private final OpenTelemetry openTelemetry;
private final CouponService couponService;

@KafkaListener(topics = "order-created-topic", groupId = "coupon-service")
public void onMessage(ConsumerRecord record) {
Context extractedContext = openTelemetry.getPropagators()
.getTextMapPropagator()
.extract(Context.current(), record, (carrier, key) -> {
if (carrier == null) {
return null;
}
Header header = carrier.headers().lastHeader(key);
return header == null ? null : new String(header.value(), StandardCharsets.UTF_8);
});

try (Scope scope = extractedContext.makeCurrent()) {
OrderCreatedEvent event = JsonUtils.fromJson(record.value(), OrderCreatedEvent.class);
couponService.issueCoupon(event.userId(), event.orderId());
log.info("Coupon issued for orderId={}", event.orderId());
}
}
}
```

如果 Java Agent 已经覆盖 Kafka 客户端，通常不需要手动传播；手动示例主要用于自定义 MQ 或特殊序列化框架。

## 8. 日志接入与 TraceID 关联

### 8.1 Logback JSON 配置

```

timestamp
level
logger
thread
message

true
{"log.format":"json"}

```

Java Agent 会把 Trace 上下文注入 MDC，常见字段包括：

```
trace_id
span_id
trace_flags
```

输出示例：

```
{
"timestamp": "2026-05-23T10:10:11.123+09:00",
"level": "INFO",
"logger": "com.example.mall.order.OrderApplicationService",
"thread": "http-nio-8080-exec-10",
"message": "Order created successfully, orderId=O202605230001",
"trace_id": "4bf92f3577b34da6a3ce929d0e0e4736",
"span_id": "00f067aa0ba902b7",
"trace_flags": "01",
"log.format": "json"
}
```

### 8.2 日志采集建议

推荐链路：

```
应用 stdout JSON 日志 -> Fluent Bit / Vector / Alloy -> Loki / Elasticsearch
```

不建议一开始就让业务应用直接通过 OTLP Logs 写 Collector，除非团队已经明确统一日志标准。原因是日志数据量通常很大，直接从应用推送可能增加业务进程负担。

## 9. OpenTelemetry Collector 生产配置

### 9.1 Gateway Collector 配置

```
receivers:
otlp:
protocols:
grpc:
endpoint: 0.0.0.0:4317
max_recv_msg_size_mib: 16
http:
endpoint: 0.0.0.0:4318

processors:
memory_limiter:
check_interval: 1s
limit_mib: 2048
spike_limit_mib: 512

k8sattributes:
auth_type: serviceAccount
passthrough: false
extract:
metadata:
- k8s.namespace.name
- k8s.pod.name
- k8s.deployment.name
- k8s.node.name
pod_association:
- sources:
- from: resource_attribute
name: k8s.pod.ip
- sources:
- from: connection

resource:
attributes:
- key: telemetry.sdk.provider
value: opentelemetry
action: upsert
- key: observability.platform
value: unified-otel
action: upsert

attributes/sanitize:
actions:
- key: http.request.header.authorization
action: delete
- key: http.request.header.cookie
action: delete
- key: http.response.header.set_cookie
action: delete
- key: db.statement
action: hash

filter/drop_noise:
error_mode: ignore
traces:
span:
- 'attributes["url.path"] == "/actuator/health"'
- 'attributes["http.route"] == "/actuator/health"'
metrics:
metric:
- 'name == "process.runtime.jvm.buffer.limit"'

tail_sampling:
decision_wait: 10s
num_traces: 50000
expected_new_traces_per_sec: 5000
policies:
- name: errors
type: status_code
status_code:
status_codes: [ERROR]
- name: slow-requests
type: latency
latency:
threshold_ms: 800
- name: important-services
type: string_attribute
string_attribute:
key: service.name
values:
- payment-service
- order-service
enabled_regex_matching: false
- name: baseline
type: probabilistic
probabilistic:
sampling_percentage: 10

batch:
timeout: 2s
send_batch_size: 8192
send_batch_max_size: 16384

exporters:
debug:
verbosity: basic

kafka/traces:
brokers:
- kafka-0.kafka:9092
- kafka-1.kafka:9092
- kafka-2.kafka:9092
topic: otel-traces
encoding: otlp_proto
protocol_version: 3.6.0
compression: gzip

prometheusremotewrite:
endpoint: http://mimir-nginx.observability.svc:9009/api/v1/push
resource_to_telemetry_conversion:
enabled: true

otlphttp/loki:
endpoint: http://loki-gateway.observability.svc:3100/otlp

extensions:
health_check:
endpoint: 0.0.0.0:13133
pprof:
endpoint: 0.0.0.0:1777
zpages:
endpoint: 0.0.0.0:55679

service:
extensions: [health_check, pprof, zpages]
telemetry:
logs:
level: info
metrics:
address: 0.0.0.0:8888
pipelines:
traces:
receivers: [otlp]
processors: [memory_limiter, k8sattributes, resource, attributes/sanitize, filter/drop_noise, tail_sampling, batch]
exporters: [kafka/traces]
metrics:
receivers: [otlp]
processors: [memory_limiter, k8sattributes, resource, filter/drop_noise, batch]
exporters: [prometheusremotewrite]
logs:
receivers: [otlp]
processors: [memory_limiter, k8sattributes, resource, attributes/sanitize, batch]
exporters: [otlphttp/loki]
```

### 9.2 Kafka 消费 Collector

Trace 经过 Kafka 后，再由独立 Collector 消费写入 Tempo：

```
receivers:
kafka/traces:
brokers:
- kafka-0.kafka:9092
- kafka-1.kafka:9092
- kafka-2.kafka:9092
topic: otel-traces
group_id: otel-traces-tempo-writer
encoding: otlp_proto
protocol_version: 3.6.0

processors:
memory_limiter:
check_interval: 1s
limit_mib: 2048
spike_limit_mib: 512
batch:
timeout: 2s
send_batch_size: 8192

exporters:
otlp/tempo:
endpoint: tempo-distributor.observability.svc:4317
tls:
insecure: true
sending_queue:
enabled: true
num_consumers: 8
queue_size: 10000
retry_on_failure:
enabled: true
initial_interval: 1s
max_interval: 30s
max_elapsed_time: 300s

service:
pipelines:
traces:
receivers: [kafka/traces]
processors: [memory_limiter, batch]
exporters: [otlp/tempo]
```

### 9.3 为什么 Trace 走 Kafka，Metric 不一定走 Kafka

Trace 和 Log 往往数据量大、突发性强，适合 Kafka 缓冲。Metric 通常是周期性数据，且 Prometheus 生态更习惯 Pull 或 Remote Write。

建议：

```
Trace：Collector -> Kafka -> Collector -> Tempo
Metric：Collector -> Remote Write -> Mimir / VictoriaMetrics
Log：stdout -> 日志 Agent -> Loki / ES，或 Collector -> Loki
```

## 10. 高并发与可扩展设计

### 10.1 高并发下的数据链路问题

高并发下，可观测系统最容易出问题的地方不是 UI，而是采集链路：

- 1. SDK 队列满，Span 被丢弃；
- 2. Collector CPU 飙高，batch 发送延迟增加；
- 3. Tail Sampling 缓存过多 Trace，Collector OOM；
- 4. Kafka topic 分区不足，消费堆积；
- 5. Loki/Tempo/Mimir 写入端抖动，反压采集层；
- 6. 高基数字段导致存储和查询爆炸。

### 10.2 SDK 端参数建议

| 参数 | 小规模 | 中等规模 | 高并发 |
| --- | --- | --- | --- |
| Trace 采样率 | 100% | 10% - 30% | 1% - 10% |
| Batch queue | 默认 | 2048 - 8192 | 8192 - 32768 |
| Export batch | 默认 | 512 - 2048 | 2048 - 8192 |
| Export interval | 默认 | 500 ms - 2 s | 1 s - 5 s |
| OTLP 协议 | gRPC | gRPC | gRPC + gzip |

注意：采样率不是越低越好。错误、慢请求和关键交易必须通过 Tail Sampling 或业务标记保留。

### 10.3 Collector 扩容策略

Collector Gateway 建议无状态部署：

```
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
name: otel-collector-gateway
spec:
scaleTargetRef:
apiVersion: apps/v1
kind: Deployment
name: otel-collector-gateway
minReplicas: 3
maxReplicas: 20
metrics:
- type: Resource
resource:
name: cpu
target:
type: Utilization
averageUtilization: 70
- type: Resource
resource:
name: memory
target:
type: Utilization
averageUtilization: 75
```

扩容建议：

- • Gateway Collector 至少 3 副本；
- • 使用 Service 做负载均衡；
- • 对 Collector 自身指标建 Dashboard；
- • 重点观察 otelcol_receiver_accepted_spans 、 otelcol_exporter_send_failed_spans 、 otelcol_processor_dropped_spans ；
- • Tail Sampling 场景下，扩容会影响同一 Trace 的聚合，需要使用负载均衡策略保证同一 Trace 尽量进入同一 Collector。

### 10.4 Kafka Topic 设计

推荐按信号和环境拆分 Topic：

```
otel-prod-traces
otel-prod-logs
otel-pre-traces
otel-test-traces
```

Kafka 分区建议：

| 日 Trace 量 | 初始分区数 | 说明 |
| --- | --- | --- |
|  10 亿 Span | 64+ | 需要压测和独立容量规划 |

生产建议：

- • retention.ms 设置 1 - 7 天，用于后端故障恢复；
- • 开启压缩，Trace 数据通常压缩率较高；
- • Producer 使用 acks=1 或 acks=all ，按可靠性要求选择；
- • 消费端按 Tempo 写入能力水平扩容。

## 11. 查询、看板与告警

### 11.1 PromQL：RED 指标

服务级别建议先建设 RED 指标：

- • Rate：请求速率；
- • Errors：错误率；
- • Duration：请求延迟。

示例：

```
sum(rate(http_server_request_duration_seconds_count{service_name="order-service"}[5m]))
```

错误率：

```
sum(rate(http_server_request_duration_seconds_count{service_name="order-service", http_response_status_code=~"5.."}[5m]))
/
sum(rate(http_server_request_duration_seconds_count{service_name="order-service"}[5m]))
```

P99 延迟：

```
histogram_quantile(
0.99,
sum by (le, http_route) (
rate(http_server_request_duration_seconds_bucket{service_name="order-service"}[5m])
)
)
```

### 11.2 TraceQL：查找慢请求和错误链路

```
{ resource.service.name = "order-service" && duration > 800ms }
```

```
{ resource.service.name = "payment-service" && status = error }
```

```
{ span.http.route = "/api/orders" && span.http.response.status_code >= 500 }
```

### 11.3 LogQL：通过 trace_id 查日志

```
{service_name="order-service"} |= "4bf92f3577b34da6a3ce929d0e0e4736"
```

如果日志已经结构化为 JSON：

```
{service_name="order-service"}
| json
| trace_id="4bf92f3577b34da6a3ce929d0e0e4736"
```

### 11.4 告警规则示例

```
groups:
- name: order-service-slo
rules:
- alert: OrderServiceHighErrorRate
expr: |
sum(rate(http_server_request_duration_seconds_count{service_name="order-service", http_response_status_code=~"5.."}[5m]))
/
sum(rate(http_server_request_duration_seconds_count{service_name="order-service"}[5m]))
> 0.01
for: 5m
labels:
severity: critical
service: order-service
annotations:
summary: "order-service 5xx error rate is higher than 1%"
description: "Order service has high 5xx error rate for more than 5 minutes. Check traces and logs from Grafana Explore."

- alert: OrderServiceHighP99Latency
expr: |
histogram_quantile(
0.99,
sum by (le) (
rate(http_server_request_duration_seconds_bucket{service_name="order-service"}[5m])
)
) > 1
for: 10m
labels:
severity: warning
service: order-service
annotations:
summary: "order-service P99 latency is higher than 1s"
```

## 12. 工程治理：从“能用”到“好用”

### 12.1 接入规范

每个服务接入前必须确认：

- • service.name 是否唯一且稳定；
- • service.version 是否能跟发版系统对应；
- • 日志是否为 JSON；
- • 日志是否含 trace_id 、 span_id ；
- • 是否接入 JVM、HTTP、DB、Redis、MQ 指标；
- • 是否有业务核心指标；
- • 是否配置采样策略；
- • 是否清理敏感字段；
- • 是否避免高基数 Metric Label。

### 12.2 埋点规范

Span 命名建议：

```
领域.动作
order.create
order.payment.confirm
inventory.lock
coupon.issue
```

不要这样命名：

```
methodA
process
handle
step1
```

Metric 命名建议：

```
business.order.created
business.order.failed
business.payment.confirm.duration
threadpool.queue.size
```

日志事件建议：

```
order_created
payment_confirm_failed
inventory_not_enough
coupon_issued
```

### 12.3 Dashboard 分层

建议建设四类 Dashboard：

| 看板 | 使用对象 | 内容 |
| --- | --- | --- |
| 服务总览 | 研发、运维 | RED、JVM、依赖调用、实例状态 |
| 业务看板 | 产品、业务、研发 | 下单数、支付成功率、转化率、退款率 |
| 平台看板 | SRE、平台团队 | Collector、Kafka、Tempo、Loki、Mimir 状态 |
| 成本看板 | 架构、管理者 | 数据量、采样率、存储增长、租户占比 |

## 13. 常见生产问题与解决方案

### 13.1 Trace 断链

原因：

- • 网关没有透传 traceparent ；
- • Feign、RestTemplate、WebClient 或 Dubbo 未被自动 instrumentation；
- • MQ 消息头丢失；
- • 异步线程没有传递 Context；
- • 服务之间混用了 B3、W3C TraceContext 等传播协议。

解决：

```
-Dotel.propagators=tracecontext,baggage,b3
```

同时检查网关是否清理了未知请求头。

### 13.2 Collector OOM

原因：

- • Tail Sampling decision_wait 过长；
- • num_traces 设置过大；
- • 后端写入变慢导致队列堆积；
- • 单个 Span Attribute 过大；
- • 日志通过 OTLP 大量涌入。

解决：

- • 配置 memory_limiter ；
- • 降低 decision_wait ；
- • 拆分 Trace、Metric、Log Collector；
- • 引入 Kafka；
- • 对大字段做删除或 hash；
- • Collector HPA 扩容。

### 13.3 Metric 存储爆炸

原因：

```
user_id、order_id、request_id、trace_id 被放进 Metric Label
```

解决：

- • 高基数字段只放 Trace；
- • Metric Label 只放低基数字段；
- • 对业务指标建立白名单；
- • 在 Collector 层丢弃异常标签。

### 13.4 日志没有 TraceID

排查顺序：

- 1. Java Agent 是否启用；
- 2. 日志框架是否支持 MDC；
- 3. Logback 是否输出 MDC；
- 4. 异步日志是否丢失 MDC；
- 5. 当前日志是否处于 Span 上下文内。

### 13.5 自动埋点和旧链路追踪冲突

如果项目仍然使用 Spring Cloud Sleuth、Brave 或 SkyWalking Agent，需要避免多套 Agent 同时修改字节码。

建议：

- • 新系统统一用 OpenTelemetry；
- • 老系统逐步迁移；
- • 过渡期兼容 B3 和 W3C TraceContext；
- • 不要让多个 Java Agent 同时接管同一类框架。

## 14. 落地路线图

### 14.1 第一阶段：统一 TraceID 和服务命名

目标：先把链路串起来。

工作：

- • 接入 Java Agent；
- • 统一 service.name 、 service.version 、 environment ；
- • 日志输出 trace_id 、 span_id ；
- • Collector 接收 OTLP；
- • Trace 写入 Tempo 或 Jaeger；
- • Grafana 能从 Trace 跳转到日志。

### 14.2 第二阶段：补齐指标和告警

目标：从“能查问题”升级到“能发现问题”。

工作：

- • 接入 HTTP、JVM、DB、Redis、MQ 指标；
- • 建设 RED Dashboard；
- • 建设业务指标；
- • 配置错误率、P99、依赖失败率告警；
- • 对核心服务配置 SLO。

### 14.3 第三阶段：采样、脱敏和成本治理

目标：让平台可长期运行。

工作：

- • 引入 Tail Sampling；
- • 错误、慢请求、关键交易保留；
- • 删除敏感字段；
- • 治理高基数标签；
- • 建立采集量和存储量看板；
- • 引入 Kafka 缓冲。

### 14.4 第四阶段：多集群和智能化

目标：平台化、规模化。

工作：

- • 多集群统一接入；
- • 按租户或业务线隔离；
- • 建设全局 Grafana；
- • 引入异常检测；
- • 基于 Trace 和 Metric 做自动根因分析；
- • 打通发布系统，实现版本维度故障归因。

## 15. 最佳实践清单

### 15.1 必做项

- • 所有服务统一 service.name ；
- • 所有日志必须带 trace_id ；
- • 所有核心接口必须有 RED 指标；
- • 所有核心业务动作必须有业务指标；
- • Collector 必须配置 memory_limiter 和 batch ；
- • 生产必须有采样策略；
- • 敏感字段必须脱敏；
- • Metric Label 必须治理高基数；
- • Collector 自身必须被监控。

### 15.2 不建议做的事

- • 不要把 user_id 、 order_id 放入 Metric Label；
- • 不要让应用直接依赖某个 Trace 存储后端；
- • 不要在业务代码里到处手写 Span；
- • 不要同时运行多套 Java Agent；
- • 不要把完整 SQL 参数、Token、Cookie 打到日志或 Trace；
- • 不要一开始就追求全量 Trace；
- • 不要忽略 Collector 自身的可观测性。

## 16. 总结

OpenTelemetry 不是一个单独的监控产品，而是一套可观测数据标准和采集治理体系。

真正的生产级可观测平台，关键不在于“装了多少组件”，而在于是否做到以下几点：

- 1. 统一身份 ：Trace、Metric、Log 使用一致的服务、环境、版本和实例维度。
- 2. 统一链路 ：上下文能跨 HTTP、RPC、MQ、线程池完整传播。
- 3. 统一治理 ：采样、脱敏、过滤、高基数控制在 Collector 层集中处理。
- 4. 统一关联 ：告警能跳 Trace，Trace 能跳日志，指标能通过 Exemplar 关联请求样本。
- 5. 统一扩展 ：通过 Gateway Collector、Kafka 和分布式存储支撑高并发、多集群和长期演进。

对于研发团队来说，第一步不需要做得很复杂。先完成 Java Agent 接入、TraceID 日志关联、Collector 网关和基础 Dashboard，就能把故障定位效率提升一个层级。后续再逐步补齐采样、Kafka 缓冲、SLO、成本治理和多集群能力。

一句话概括：

> OpenTelemetry 的核心价值，是把可观测数据从“分散采集”变成“统一建模”，再从“人工排障”升级为“信号关联驱动的根因定位”。

## 附录 A：推荐目录结构

```
observability/
collector/
gateway-config.yaml
traces-consumer-config.yaml
grafana/
dashboards/
service-overview.json
jvm-overview.json
otel-collector.json
business-order.json
datasources/
tempo.yaml
mimir.yaml
loki.yaml
k8s/
otel-collector-deployment.yaml
otel-collector-hpa.yaml
otel-collector-rbac.yaml
examples/
order-service/
pom.xml
src/main/java/...
src/main/resources/logback-spring.xml
```

## 附录 B：关键参考资料

- • OpenTelemetry Java 文档： https://opentelemetry.io/docs/languages/java/
- • OpenTelemetry Java 配置： https://opentelemetry.io/docs/languages/java/configuration/
- • OTLP Exporter 配置： https://opentelemetry.io/docs/languages/sdk-configuration/otlp-exporter/
- • OpenTelemetry Semantic Conventions： https://opentelemetry.io/docs/specs/semconv/
- • OpenTelemetry Kubernetes 自动注入： https://opentelemetry.io/docs/platforms/kubernetes/operator/automatic/
- • Grafana Tempo TraceQL： https://grafana.com/docs/tempo/latest/traceql/
- • Grafana Tempo 文档： https://grafana.com/docs/tempo/latest/

---
原文链接：https://mp.weixin.qq.com/s?__biz=MzYzMjIxOTMxNg%3D%3D&mid=2247484945&idx=2&sn=d62255e00b245a684aa39853e99c8159&chksm=f13b2e4843719a60468cb080862a373624080523811e6db55faf8edec587ee26c29612126037
