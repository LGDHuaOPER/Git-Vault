---
source_url: "https://mp.weixin.qq.com/s?__biz=MzI5OTU5MjI2OQ==&mid=2247484079&idx=1&sn=110c4721206550df06b2ed543966a146&chksm=ed34e5c7d33cc4abb4ebd73c5b3cff7eb9f44e6c8c62809aa6903d10eb8eabecaa07d809f532&mpshare=1&scene=1&srcid=0601Eadmpa04zjgdZJPtlEzm&sharer_shareinfo=599f43c31b98d9449b3970b6ec0b298b&sharer_shareinfo_first=599f43c31b98d9449b3970b6ec0b298b"
title: "使用 OpenTelemetry 观测 vLLM"
account: "云原生观测"
published_at: "2026-05-25T01:15:00.000Z"
saved_at: "2026-07-20T07:44:44.088Z"
sync_id: "art_bf1f3d620b7f44fa8aae7ca9e61fcc2f"
parse_status: "ok"
---

# 使用 OpenTelemetry 观测 vLLM

![](附件资源/使用%20OpenTelemetry%20观测%20vLLM/img_1.jpg)

> 《Observing vLLM with OpenTelemetry and Dash0》

![Observing vLLM with OpenTelemetry and Dash0](附件资源/使用%20OpenTelemetry%20观测%20vLLM/img_2.png)

Observing vLLM with OpenTelemetry and Dash0vLLM 内置了 OpenTelemetry 埋点，但要在生产环境接好，远不止传一个开关那么简单。常规 APM 能告诉你请求变慢了，却说不清延迟来自 KV 缓存抢占、调度器队列压力、漫长的 prefill 阶段，还是 decode 瓶颈。要区分这些原因，需要推理专用的信号：缓存利用率、首 token 时间（TTFT）、抢占率、队列深度。

本文介绍如何用 OTel Collector 采集这些信号、以 Dash0 作为可观测性后端，说明各信号在实践中的含义，以及如何用于容量规划与延迟排查。完整可运行示例（含 FastAPI RAG 应用、vLLM 服务与 OTel Collector 的 Docker Compose 栈）见 dash0-examples 仓库。

## 为什么 LLM 推理可观测性是独立问题

从外部看，慢的 HTTP 服务与慢的 LLM 推理服务很像：都是 p99 升高、超时、体验变差。但根因与修复手段完全不同。

对普通服务而言，高延迟通常指向上游依赖、慢查询或资源饱和。你看链路、找到慢的组件、修它。

对 vLLM，延迟会分成多个阶段：调度、prefill、decode 在负载下的表现不同，调优策略也不同。KV 缓存压力会引发抢占，吞吐下降却不一定表现为错误。TTFT 与每个输出 token 的耗时是独立指标，在批处理负载下可能明显背离。队列深度能在用户感知到变慢之前，告诉你是否接近容量上限。

没有 LLM 专用埋点，这些都看不见，也无法干净地映射到标准 HTTP 或 RPC 语义。vLLM 的 OpenTelemetry 集成通过分布式链路提供逐请求可见性，通过兼容 Prometheus 的指标端点提供推理专用信号，供仪表板与告警使用。

## vLLM 会发出什么

### 链路（Traces）

设置  `--otlp-traces-endpoint`  后，vLLM 会为每次推理请求导出 OTel span。OTel 支持是可选依赖，需执行  `pip install vllm[otel]` ，会安装  `opentelemetry-sdk` 、 `opentelemetry-api` 、 `opentelemetry-exporter-otlp`  和  `opentelemetry-semantic-conventions-ai` （均为  `>=1.26.0` ）。未安装时，该标志会被静默忽略。

Span 属性定义在 vLLM 的  `SpanAttributes`  类（ `vllm/tracing/utils.py` ）中。代码注释写得很直白：这些属性是*「从 OTel 语义约定复制而来，以避免版本冲突。」* vLLM 刻意固定自己的属性名，而不是紧跟不断演进的 OTel GenAI 语义约定。这是为了稳定性，也意味着 vLLM 完全不发出 OTel span 事件；追踪完全基于属性，不记录 prompt 或 completion 内容。

**Span 属性**

| 属性 | 含义 |
| --- | --- |
| gen_ai.request.model / gen_ai.response.model | 处理请求的模型 |
| gen_ai.usage.prompt_tokens | 输入 token 数，用于成本与容量跟踪 |
| gen_ai.usage.completion_tokens | 输出 token 数 |
| gen_ai.latency.e2e | 整次请求耗时 |
| gen_ai.latency.time_to_first_token | TTFT，对流式应用而言是最直观的延迟信号 |
| gen_ai.latency.time_in_queue | 开始执行前的等待时间；持续上升表示容量压力，往往在延迟明显恶化之前就会出现 |

vLLM 还会输出一整套内部分解延迟（ `gen_ai.latency.time_in_model_prefill` 、 `gen_ai.latency.time_in_model_decode` 、 `gen_ai.latency.time_in_model_forward`  等）。排查单条慢链路时有用，仪表板一般不必展示。

需注意命名差异：vLLM 使用  `gen_ai.usage.prompt_tokens`  和  `gen_ai.usage.completion_tokens` ，而非当前 OTel GenAI 语义约定中的  `input_tokens`  /  `output_tokens` 。 `gen_ai.latency.*`  命名空间也是 vLLM 特有的。在 Dash0 中查询时，请使用这些确切名称。

**资源属性**

资源属性随进程中的每条 span 一起上报。值得显式设置的，以及 vLLM 自动添加的如下：

| 属性 | 来源 |
| --- | --- |
| service.name | 通过 OTEL_SERVICE_NAME 设置，Dash0 中过滤的主属性 |
| service.version | 通过 OTEL_SERVICE_VERSION 设置 |
| deployment.environment.name | 通过 Collector 的 resource processor 设置 |
| vllm.instrumenting_module_name | vLLM 自动添加 |
| vllm.process_id | vLLM 自动添加 |
| vllm.process_kind / vllm.process_name | GPU worker 子进程上自动添加 |

请显式设置  `OTEL_SERVICE_NAME` 、 `OTEL_SERVICE_VERSION`  和  `deployment.environment.name` ，这些是你在 Dash0 中的主要过滤维度。注意：自 OTel 语义约定 1.27 起，环境属性名为  `deployment.environment.name` ；旧的  `deployment.environment`  在多数工具中仍可用，但已弃用。

**链路传播**

vLLM 从 HTTP 请求头和环境变量中读取 W3C  `traceparent`  上下文。环境变量路径用于向 GPU worker 子进程传播：请求到达后，主进程在拉起 worker 前将  `traceparent`  注入环境，使所有 worker span 挂到同一条 trace 上。若应用代码创建 span 并注入出站请求头，vLLM 的 span 会成为你的子 span，GPU worker span 再成为其子 span，从而形成覆盖完整请求路径的单条 trace。

###

### 指标（Metrics）

vLLM 在  `/metrics`  暴露 Prometheus 格式指标，由 Collector 的 Prometheus receiver 抓取。

| 指标 | 类型 | 含义 |
| --- | --- | --- |
| vllm:e2e_request_latency_seconds | Histogram | 整次请求延迟，关注 p95/p99；均值会掩盖长尾 |
| vllm:time_to_first_token_seconds | Histogram | 首个 token 流出前的耗时，交互式应用最重要的延迟信号 |
| vllm:time_per_output_token_seconds | Histogram | 每个输出 token 的 decode 延迟，用于发现 decode 阶段瓶颈 |
| vllm:inter_token_latency_seconds | Histogram | 相邻 token 间隔，流式 UI 中用户直接可感知 |
| vllm:prompt_tokens_total | Counter | 累计输入 token，用 rate() 看 tokens/秒 |
| vllm:generation_tokens_total | Counter | 累计输出 token，GPU 容量规划的核心指标 |
| vllm:gpu_cache_usage_perc | Gauge | KV 缓存占用百分比，接近 1.0 意味着即将发生抢占 |
| vllm:num_requests_waiting | Gauge | 队列深度，在延迟恶化前上升是最早的容量预警 |
| vllm:num_preemptions_total | Counter | 从内存中驱逐的请求数；速率上升且与缓存高占用相关，说明配置需要调整 |
| vllm:prefix_cache_hit_rate | Gauge | 前缀缓存命中率；若重复 system prompt 或共享上下文的 RAG，低命中率是调优机会 |

Collector 抓取  `/metrics`  时，Prometheus 会自动加上  `job`  和  `instance`  标签。环境、集群、命名空间等额外上下文，需在 Collector 的  `resource`  processor 或 Kubernetes attributes processor 中显式配置。

## 数据管道

采集架构端到端保持 OTel 原生：vLLM 经 OTLP/gRPC 把 trace 推到 OTel Collector；Collector 用 Prometheus receiver 抓取 vLLM 的  `/metrics` 。两类信号走同一条管道，经 OTLP 导出到 Dash0。

![管道架构图](附件资源/使用%20OpenTelemetry%20观测%20vLLM/img_3.png)

管道架构图(1) 用户请求经 HTTP 打到 RAG 应用。(2) RAG 应用调用 vLLM 的 HTTP POST  `/v1/completions` ，并注入 W3C  `traceparent`  头，使两服务共享一条 trace。(3) RAG 应用经 OTLP gRPC 把 span 推到 Collector。(4) vLLM 同样推送，其推理 span 作为 RAG span 的子 span。(5)(6) Collector 每 15 秒从两个服务的  `/metrics`  抓取。(7) 两服务的 trace 与两次 scrape 的指标，经单条 OTLP gRPC 导出到 Dash0。

**为什么经 Collector 而不是直接导出到 Dash0？**

直接导出可行，但会失去用资源属性丰富遥测、发送前过滤或采样、把信号路由到多个后端、以及与应用解耦的重试能力。Collector 把埋点与导出策略解耦。开发环境影响较小，但任何生产部署都应把 Collector 放在管道里。

**为什么 Collector 同时用 OTLP 推送和 Prometheus 拉取？**

vLLM 用 OTLP 推送 trace：每个请求产生 span 并立即发送。指标来自 Prometheus scrape 端点，需要周期性拉取。OTel Collector 原生支持两者： `prometheus`  receiver 把抓到的指标转成 OTel 数据点，经与 trace 相同的  `otlp/dash0`  exporter 转发，Dash0 只需一条 OTLP 连接即可收到全部数据。

## 搭建步骤

完整示例见 dash0-examples/vllm。下面是关键配置说明。

### vLLM

vLLM Docker 镜像（ `vllm/vllm-openai` ）需要 NVIDIA GPU。没有生产级硬件时，用  `g4dn.xlarge`  EC2（单块 T4）跑  `facebook/opt-125m`  就足以验证整条遥测管道。没有 GPU 时，可从  `docker-compose.yml`  去掉  `deploy.resources`  块，在 CPU 上测管道；推理会很慢，但 trace 与指标仍会正常流动。

通过 OTLP 端点启用追踪：

-
-

```
vllm serve facebook/opt-125m \  --otlp-traces-endpoint=http://otel-collector:4317
```

同时设置这些环境变量：

-
-
-

```
OTEL_SERVICE_NAME=vllm-serverOTEL_EXPORTER_OTLP_TRACES_ENDPOINT=http://otel-collector:4317OTEL_EXPORTER_OTLP_TRACES_INSECURE=true
```

### OTel Collector 配置

-
-
-
-
-
-
-
-
-
-
-
-
-
-
-
-
-
-
-
-
-
-
-
-
-
-
-
-
-
-
-
-
-
-
-
-
-
-
-
-
-
-
-
-
-
-
-
-
-
-
-
-

```
extensions:  health_check:    endpoint: 0.0.0.0:13133
receivers:  otlp:    protocols:      grpc:        endpoint: 0.0.0.0:4317      http:        endpoint: 0.0.0.0:4318
prometheus:    config:      global:        scrape_interval: 15s      scrape_configs:        - job_name: vllm          static_configs:            - targets: ["vllm:8000"]        - job_name: rag-app          static_configs:            - targets: ["rag-app:8001"]
processors:  batch:    timeout: 1s    send_batch_size: 1024
exporters:  debug:    verbosity: detailed    sampling_initial: 5    sampling_thereafter: 200
otlp/dash0:    endpoint: ${env:DASH0_ENDPOINT_OTLP_GRPC_HOSTNAME}:${env:DASH0_ENDPOINT_OTLP_GRPC_PORT}    headers:      Authorization: Bearer ${env:DASH0_AUTH_TOKEN}      Dash0-Dataset: ${env:DASH0_DATASET}
service:  extensions: [health_check]  pipelines:    traces:      receivers: [otlp]      processors: [batch]      exporters: [debug, otlp/dash0]    metrics:      receivers: [otlp, prometheus]      processors: [batch]      exporters: [debug, otlp/dash0]
```

几点说明：

`batch`  processor 能降低开销，开发环境够用。生产环境 OpenTelemetry 社区建议逐步弃用它：batch processor 在数据持久化之前就确认接收，Collector 重启可能静默丢 span。替代方案是带持久化存储的 exporter 级批处理。细节见 为何 OpenTelemetry 批处理器将逐步淘汰。

`debug`  exporter 把遥测打到 stdout。上面的采样配置会先打 5 条再每 200 条打 1 条，足以在搭建时确认有数据，又不过度刷屏。生产环境应去掉。

Prometheus 抓取间隔 15 秒是合理默认。vLLM 指标端点按调度周期更新，短于 5 秒的抓取只会增加 Collector CPU，数据并不会明显更新。

###

### 应用层埋点

若从应用代码调用 vLLM（RAG 流水线、Agent 等），需要传播 trace 上下文，才能把 vLLM span 接到应用 span 上。

在应用里直接用 OTel API。通过环境变量配置 SDK，用  `opentelemetry.trace.get_tracer()`  自动拾取 provider。这样应用代码与 SDK 初始化解耦，与 vLLM 在  `vllm/tracing/__init__.py`  中的做法一致：对外暴露干净的  `instrument`  装饰器，而不是把  `TracerProvider` 、 `BatchSpanProcessor`  泄露给调用方。

-
-
-
-
-
-
-
-
-
-
-
-
-
-
-
-
-
-
-
-
-
-
-
-
-
-
-
-
-
-
-

```
from opentelemetry import tracefrom opentelemetry.trace.propagation.tracecontext import TraceContextTextMapPropagatorimport requests
# SDK 通过环境变量自动配置：# OTEL_SERVICE_NAME=rag-app# OTEL_EXPORTER_OTLP_ENDPOINT=http://otel-collector:4317# OTEL_EXPORTER_OTLP_INSECURE=truetracer = trace.get_tracer("rag-app")
def call_vllm(prompt: str) -> str:    with tracer.start_as_current_span("rag.generate") as span:        span.set_attribute("gen_ai.request.model", "facebook/opt-125m")        span.set_attribute("gen_ai.request.max_tokens", 100)
# 把 trace 上下文注入出站请求头        headers = {}        TraceContextTextMapPropagator().inject(headers)
response = requests.post(            "http://vllm:8000/v1/completions",            headers=headers,            json={"model": "facebook/opt-125m", "prompt": prompt, "max_tokens": 100}        )        result = response.json()
usage = result.get("usage", {})        span.set_attribute("gen_ai.usage.prompt_tokens", usage.get("prompt_tokens", 0))        span.set_attribute("gen_ai.usage.completion_tokens", usage.get("completion_tokens", 0))
return result["choices"][0]["text"]
```

`TraceContextTextMapPropagator().inject(headers)`  把当前 span 上下文序列化进  `traceparent`  头。vLLM 处理请求时读取该头，并以你的 span 为父 span 创建自己的 span。不做这一步，会得到两条断开的 trace，而不是一条连续的瀑布图。

示例中的属性名（ `gen_ai.usage.prompt_tokens` 、 `gen_ai.usage.completion_tokens` ）与 vLLM 发出的一致。命名统一后，应用 span 与 vLLM span 会在 Dash0 的 GenAI 视图中正确对齐。

## 在 Dash0 中看到什么

### 链路

从 RAG 应用到 vLLM、上下文传播完整时，瀑布图大致如下：

![Dash0 瀑布图：完整 trace](附件资源/使用%20OpenTelemetry%20观测%20vLLM/img_4.png)

Dash0 瀑布图：完整 trace_Dash0 瀑布图：完整 trace_

单条 trace 就能回答原本需要分别给各服务埋点才能搞清楚的问题：延迟在文档检索还是模型生成？ `rag.generate`  开始与  `llm_request`  开始之间差距变大，说明请求尚未执行就已出现队列压力。

点开  `llm_request`  span，能看到 vLLM 填写的全套  `gen_ai.latency.*`  属性： `gen_ai.latency.time_in_queue` 、 `gen_ai.latency.time_in_model_prefill` 、 `gen_ai.latency.time_in_model_decode`  等。它们是 span 属性而非子 span，不会出现在瀑布图的行里，而是单次推理各阶段的耗时分解。 `time_in_queue`  长说明是调度器压力，不是模型慢； `time_in_model_prefill`  长说明 prompt 相对硬件偏大。

### Dash0 中的指标

Prometheus receiver 开始抓取且管道运行后，vLLM 指标会以标准 OTel 指标出现在 Dash0，可与同一服务的 trace 一起查询。

![Dash0 指标浏览器：vllm: 指标列表](附件资源/使用%20OpenTelemetry%20观测%20vLLM/img_5.png)

Dash0 指标浏览器：vllm: 指标列表_Dash0 指标浏览器：完整  `vllm:`  指标列表，示例中选中了  `vllm:time_to_first_token_seconds` _

Collector 一开始抓取，完整的  `vllm:*`  指标列表就会出现。选中任一指标可看到描述、可用属性，以及常见聚合的预置查询。

**容量规划：** 同时看  `vllm:gpu_cache_usage_perc`  与  `vllm:num_requests_waiting` 。缓存利用率超过 90% 且等待队列非零，是可靠的信号：需要更多 GPU 内存或增加副本。

**延迟 SLO：** 流式应用用  `vllm:time_to_first_token_seconds`  的 p95；非流式用  `vllm:e2e_request_latency_seconds`  的 p99。在用户感知之前对两者设告警。Dash0 原生支持 Prometheus 格式告警规则，见 配置告警检查。

**排查延迟尖峰：** 看  `vllm:num_preemptions_total`  的 rate。抢占不会表现为错误，而是请求突然变慢——调度器不得不驱逐进行中的 KV 缓存状态。若出现无法解释的 p99 尖峰且  `gpu_cache_usage_perc`  很高，先看抢占率。

**吞吐监控：** `rate(vllm:generation_tokens_total[5m])`  给出每秒 token 数，是衡量服务配置是否充分利用算力的最直接指标。

### Agent0

Agent0 可以直接帮你基于 vLLM 遥测做调查与行动。例如，trace 视图里能看到 vLLM span，却与 HTTP span 分组方式不同。问 Agent0：**「为什么我的 vLLM span 在 dash0.operation.name 里显示 Unknown operation？」** 会立刻解释：GenAI span 用的属性词汇与 HTTP span 不同（ `gen_ai.*`  而非  `http.*` ），你可以在 Dash0 设置里加自定义 operation 命名规则来对齐。Agent0 会指出受影响的 span、说明原因，并给出具体配置步骤。

![Agent0 解释 vLLM span 的 Unknown operation 标签](附件资源/使用%20OpenTelemetry%20观测%20vLLM/img_6.png)

Agent0 解释 vLLM span 的 Unknown operation 标签_Agent0 解释 vLLM span 的 Unknown operation 标签_

也可以让 Agent0 根据你关心的  `vllm:*`  指标名直接生成监控仪表板，几秒钟就能得到可用面板。

![Agent0 生成的 vLLM 监控仪表板（延迟）](附件资源/使用%20OpenTelemetry%20观测%20vLLM/img_7.png)

Agent0 生成的 vLLM 监控仪表板（延迟）

![Agent0 生成的 vLLM 监控仪表板（延迟、缓存、吞吐）](附件资源/使用%20OpenTelemetry%20观测%20vLLM/img_8.png)

Agent0 生成的 vLLM 监控仪表板（延迟、缓存、吞吐）_Agent0 生成的 vLLM 监控仪表板：延迟、缓存与吞吐面板_

## 扩展到 Agent 流水线

vLLM 位于多 Agent 系统内部时，同一套管道仍然适用。Agent 对话的每一轮可能包含多次工具调用与 LLM 调用。若每次调用都传播 trace 上下文，它们都会成为同一条 trace 中的 span，于是单条用户消息对应一条 trace，展示 Agent 为回复所做的一切，vLLM 推理 span 作为树上的叶子节点。

GenAI 语义约定定义了 Agent span 上应有的属性： `gen_ai.operation.name`  表示操作类型， `gen_ai.agent.name`  表示 Agent 身份， `gen_ai.tool.name`  表示工具调用。当 Agent 框架使用这些属性、vLLM 发出自己的  `gen_ai.*`  span 属性时，两套 span 处在同一命名空间，可在 Dash0 中一起查询。

本文的推理可观测性是基础；Agent 可观测性在同一模式上再叠一层。Dash0 的 Agent 可观测性实用指南 介绍如何扩展到完整 Agent 流水线。若希望用更高层 SDK 而非裸 OTel 做 AI 可观测性，可参考 OpenLIT 与 OpenLLMetry 集成作为补充方案。

## 运行示例

克隆仓库并进入 vllm 目录：

-
-

```
git clone https://github.com/dash0hq/dash0-examples.gitcd dash0-examples/vllm
```

在根目录  `.env`  中配置 Dash0 凭据：

-
-
-
-

```
DASH0_AUTH_TOKEN=your_auth_tokenDASH0_DATASET=defaultDASH0_ENDPOINT_OTLP_GRPC_HOSTNAME=ingress.eu-west-1.aws.dash0.comDASH0_ENDPOINT_OTLP_GRPC_PORT=4317
```

启动栈（需要 NVIDIA GPU；无 GPU 时见上文 vLLM 搭建一节如何在 CPU 上运行）：

-

```
docker compose up --build
```

等待 vLLM 加载模型（T4 上约 2–5 分钟），然后发送测试请求：

-

```
python scripts/send-request.py
```

示例目录中的 README 说明前置条件、完整预期输出，以及数据流入 Dash0 后应关注的内容。

vLLM 内置 OTel 支持意味着埋点成本低，接到生产级管道所需的配置也很少。回报是：链路级可见推理各阶段，指标级可见 GPU 利用率、缓存压力与队列深度——这些才是让你有信心运维 LLM 服务层的信号。

![](附件资源/使用%20OpenTelemetry%20观测%20vLLM/img_9.png)

---
原文链接：https://mp.weixin.qq.com/s?__biz=MzI5OTU5MjI2OQ%3D%3D&mid=2247484079&idx=1&sn=110c4721206550df06b2ed543966a146&chksm=ed34e5c7d33cc4abb4ebd73c5b3cff7eb9f44e6c8c62809aa6903d10eb8eabecaa07d809f532
