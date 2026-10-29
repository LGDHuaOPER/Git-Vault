---
source_url: "https://mp.weixin.qq.com/s?__biz=MzU3ODAxNTIzMQ%3D%3D&mid=2247490936&idx=1&sn=a49fd4b752e6638456bf59d14fcab12f&chksm=fd7a87e8ca0d0efe587064d789936c6fc5c88f59dc80caf19915df858e0eef36f129c736f874"
title: "将最先进的采样技术引入 OpenTelemetry Collector"
account: "SRETALK"
published_at: "2026-09-23 17:40:56"
saved_at: "2026-10-21 19:17:02"
sync_id: "art_3a0a7595c6d244f6addeef37f1f190f2"
parse_status: "ok"
---

# 将最先进的采样技术引入 OpenTelemetry Collector

![](附件资源/将最先进的采样技术引入%20OpenTelemetry%20Collector/img_1.png)

> **❝**Honeycomb 正将其基于多年 Refinery 实践经验构建的“自适应尾部采样器（adaptive tail sampling processor）”捐赠给 OpenTelemetry Collector 社区。OpenTelemetry 也从 CNCF 毕业了，Tracing 领域未来就是 OpenTelemetry 一家独大了。

By: Mike Goldsmith | 2026年9月1日

对于所有大规模运行可观测性流水线的人来说，采样都是一项必须掌握的核心技能。从降低带宽、CPU 和内存消耗，到控制成本以及提升后端对用户的响应性能，各种决策之间充满权衡。

在过去，主流的采样机制只有三种，且各有利弊：

- 头部采样（Head sampling） ： 在应用程序内部进行配置
- 概率（随机）采样（Probabilistic sampling） ： 在数据流水线中进行配置
- 尾部采样（Tail sampling） ： 在具备追踪感知路由能力（trace-aware routed）的 Collector 中进行配置

然而，其实还存在隐藏的第四种选择**：自适应尾部采样（Adaptive tail sampling）**——它重新定义了这些权衡关系。

在 OpenTelemetry 成为遥感数据标准之前，我们就已开发了开源尾部采样代理 Refinery。作为目前最先进的采样代理，Refinery 能够帮助客户在不超预算的前提下保留关键的上下文信息，即使面对流量突增也能游刃有余。它通过应用可动态变化的采样规则来实现这一目标，远比现有 Collector 尾部采样器中那些僵硬的静态规则更为灵活。此外，它还承担了集群化、扩缩容以及路由等诸多工作。

但令我们遗憾的是，这些理念此前一直未能成为主流。用户受限于 Collector 尾部采样器或概率采样器中僵化固定的规则，导致业界普遍认为尾部采样难以驾驭、不够灵活且风险较高。

这一切促使我们思考：如何才能帮助整个行业充分释放自适应尾部采样的潜力？于是，我们决定将这一全新的自适应尾部采样组件捐赠给 OpenTelemetry Collector。

> **❝****长话短说（TL;DR）**： 我们正在将自适应尾部采样器作为 Processor 捐赠给 OpenTelemetry！如果您想在官方 Collector 发行版集成之前先行体验，可以使用我们的 Honeycomb Collector Distribution。

## 传统尾部采样 vs 自适应尾部采样

现有的尾部采样组件与自适应采样方法之间存在许多相似之处。

### 缓存（Buffering）

两种采样器都会将 Span 缓存一段时间，以确保获取尽可能完整的 Trace 上下文，从而基于整条 Trace 的全貌而非单个 Span 作出决策。自适应尾部采样器引入了一套额外的机制：它会在接收到 Root Span 后不久即触发决策（默认  `decision_delay`  为 2 秒），并以  `trace_timeout` （默认 30 秒）作为兜底逻辑，用于处理始终未能获取 Root Span 的 Trace。这能有效缓解 CPU 和内存压力，对于短生命周期的请求尤为明显。

### 静态规则（Static rules）

两者都支持静态规则评估，例如：“保留所有包含 Error 的 Trace”、“保留 Root Span 耗时超过 1 秒的 Trace”或“丢弃所有健康检查接口（healthcheck）的请求”。

这也延伸到了基于静态规则运行的概率采样，例如：“对于首页请求，按 1/10 的概率随机保留”。

### 追踪指纹识别（Trace fingerprinting）

该功能使采样器能够识别出不同 Trace 之间的相似性，从而确保能够覆盖系统内部各种不同的调用链路。此外，追踪指纹识别还能确保那些通常很少被采样的请求（如低流量的租户）在输出数据中获得合理呈现。这是自适应采样的核心特性。

举例来说，你可以通过以下组合来唯一标识一条 Trace：

- 整个 Trace 中出现的服务名称集合与响应状态码集合
- 来自 Root Span 的租户 ID（Tenant id）
- Root Span 的 HTTP 路由（http route）

如果某位用户在结账（Checkout）时因使用了优惠码而走了一条不同的系统路径，该请求就会被赋予不同的指纹并区别对待。同时，系统里每一个租户的请求也都能够在采样数据中得到体现。

### 自适应采样率（Adaptive sample rates）

自适应采样真正的魅力在于其动态调整能力，而这正是与追踪指纹识别紧密绑定的。

每个指纹的实际采样率是动态变化的，因为你需要设定一个跨所有指纹共同作用的“目标”——可以是一个流量百分比，也可以是一个吞吐量预算。采样器会对各指纹的流量规模进行对数分析（logarithmic analysis），从而得出相对采样率。

![](附件资源/将最先进的采样技术引入%20OpenTelemetry%20Collector/img_2.png)

上图显示，少数几个指纹占据了绝大部分流量。这可能是因为它们对应的是首页，或者是由于两个大客户产生了远高于其他人的流量。如果我们不结合指纹识别直接应用 1/10 的固定采样率，很可能会遗漏大量低流量调用的数据；反之，如果对每个指纹都各自应用 1/10 的采样率，又可能会丢失大客户流量中的细节特征。

![](附件资源/将最先进的采样技术引入%20OpenTelemetry%20Collector/img_3.png)

 `log()`  函数通过规范化各个指纹的流量规模，提供了一个相对基准值。我们可以利用它将 1/10 的整体采样率合理平摊到整个分布中，确保每个指纹都能留存一部分数据。

此外，自适应目标的表达方式有两种：

- 按百分比（  `adaptive_percentage`  ） ： 例如保留总体流量的 10%。采样器会将该预算分配给各个指纹：对高频指纹进行更强力的下采样（downsample），同时对低频指纹保留更多数据。
- 按吞吐量（  `adaptive_throughput`  ） ： 例如将总量控制在约每秒 1000 个 Span。无论流量如何突发，采样器都会自动计算并动态调整每个指纹的采样率，以确保整体不超预算。

无论采取哪种方式，采样率都会定期重新计算（默认为 15 秒，可配置），从而随着流量的起伏实时自适应。

这里真正的价值在于**成本控制**。设定吞吐量目标后，即便是面对流量洪峰，输出的数据量也不会随之线性成倍暴涨；而无论采用哪种目标，即使首页遭受了 DDoS 攻击，结账端点的遥感数据也不会受到波及。

### 采样率归因（Sample rate attribution）

采样现已成为 OpenTelemetry 中的一等公民。通过在  `tracestate`  中使用  `ot=th`  来传递采样阈值，Processor 输出的这一信息对于告诉后端“该 Trace 代表了多少真实流量”极具价值。

当这一机制与自适应采样率结合时，后端系统便能够据此对 Trace 进行准确的数据推算与外推分析（extrapolated data）。

## 立即通过 Honeycomb Collector Distribution 体验

我们正在将自适应尾部采样 Processor 捐赠给 OpenTelemetry Collector，目前正在上游逐步推进至 Alpha 阶段。在此期间，您可以直接使用 Honeycomb Collector Distribution 来体验——它是 Collector  `contrib`  镜像的无缝替代品，内部已预置了该组件。

以下是一个完整的 Trace 流水线配置示例。它接收 OTLP 数据，应用两条采样规则，并将数据导出至 Honeycomb。规则逻辑如下：

- 第一条规则：保留任何包含 Error 状态码的 Trace（优先评估）。
- 第二条规则：针对“服务名称 + HTTP 路由”的所有组合，目标保留 10% 的流量。这样既能保证低流量路由清晰可见，又能对热门路由进行合理的下采样。

```
receivers:
  otlp:
    protocols:
      grpc:
      http:

processors:
adaptive_tail_sampling:
    rules:
      # Error 始终保留，最先评估
      -name:keep-errors
        conditions:
          -span.status.code==STATUS_CODE_ERROR
        sampler:
          type:always_sample
      # 其余数据按（service, route）维度收敛于 ~10% 的保留率
      -name:default
        sampler:
          type:adaptive_percentage
          goal_percentage:10
          fingerprint_attributes:
            -resource.attributes["service.name"]
            -span.attributes["http.route"]
      # 缓存、超时和 Cache 均使用合理的默认值，精简配置仅需指定 rules 即可

exporters:
otlp_http:
    endpoint:https://api.honeycomb.io
    headers:
      x-honeycomb-team:${env:HONEYCOMB_API_KEY}

service:
pipelines:
    traces:
      receivers:[otlp]
      processors:[adaptive_tail_sampling]
      exporters:[otlp_http]
```

若要在 Kubernetes 上运行，可以使用 OpenTelemetry Collector 的 Helm Chart，并将镜像指向 Honeycomb 的发行版：

```
# values.yaml
image:
  repository: honeycombio/honeycomb-opentelemetry-collector
  tag: latest # 建议固定到具体的 release 版本: https://github.com/honeycombio/honeycomb-collector-distro/releases
mode: deployment
config:
  # 此处填入上述 Collector 配置
```

将上述内容保存为  `values.yaml` （并在  `config`  下贴入上面的 Collector 配置），随后添加 Chart 仓库并安装：

```
helm repo add open-telemetry https://open-telemetry.github.io/opentelemetry-helm-charts
helm repo update

helm install adaptive-sampler \
  open-telemetry/opentelemetry-collector \
  -f values.yaml \
  --set-string extraEnvs[0].name=HONEYCOMB_API_KEY \
  --set-string extraEnvs[0].value=$HONEYCOMB_API_KEY
```

更倾向于先在本地试用？可以直接拉取发行版的 Docker 镜像并挂载配置运行：

```
docker run -p 4317 -4318:4317-4318 \
  -e HONEYCOMB_API_KEY=$HONEYCOMB_API_KEY \
  -v $(pwd)/config.yaml:/config.yaml \
  honeycombio/honeycomb-opentelemetry-collector:latest
```

## 结语

Flashcat 创业之初，就思考过可观测性三大支柱（Metrics/Traces/Logs）的数据应该如何采集，是否有必要重复造轮子，当时的思考决策是：

- 指标：Prometheus 生态是事实上的标准，拥抱即可，不过 Exporter 比较零散不方便维护，应该整合到一个组件，于是有了 Categraf
- 链路：OpenTelemetry 未来会一统天下，没必要重复造轮子，这是一个厂商中立的方案，大家更喜欢厂商中立的方案
- 日志：半结构化的，没有标准一说，如果能复用 OpenTelemetry 那更好，如果不能，遵从 Canonical Log Line 理念打印 JSON 日志即可，采集器没有那么关键，关键的是应用程序如何打印日志，规范如何

![](附件资源/将最先进的采样技术引入%20OpenTelemetry%20Collector/img_4.png)

AI Agent 持续发展，底层的数据底座是根基，如果您对大一统的可观测性方案感兴趣，欢迎联系我们交流思路/产品：**https://flashcat.cloud/contact**

---
原文链接：https://mp.weixin.qq.com/s?__biz=MzU3ODAxNTIzMQ%3D%3D&mid=2247490936&idx=1&sn=a49fd4b752e6638456bf59d14fcab12f&chksm=fd7a87e8ca0d0efe587064d789936c6fc5c88f59dc80caf19915df858e0eef36f129c736f874
