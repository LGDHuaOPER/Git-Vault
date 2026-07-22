---
source_url: "https://mp.weixin.qq.com/s?__biz=Mzg3MTgxMzczNg==&mid=2247494460&idx=1&sn=6ceefdc0c695c71c33fdc07710ae305a&chksm=cf4229c4ef83ea476f31aeb9809927dc7d14cc3701c336fddb4feab14fe73359cbd04a563353&scene=7&ascene=65&devicetype=iOS26.5.2&version=18004b43&nettype=3G+&abtest_cookie=AAACAA==&lang=zh_CN&countrycode=CN&fontScale=100&exportkey=n_ChQIAhIQESL5m3hXyQSIIXs78o2vlBLNAQIE97dBBAEAAAAAAIFbFDsRcuMAAAAOpnltbLcz9gKNyK89dVj0T+GSAfsDmfDmTjxOrPQoGBylhncVCH/KEEiXCAST6TSVTdUdbHveW+MXn5RzYkBjVmzs0aDKX/B579UhjYrirbWsWwFhcfWruGgjautabqoyKMcEH6utg+xSP4spYlmVn/Bu/w+f4/2LZCJUnm1W9B3QgujGWzotf/jj4BtSEl3dEGaYybHV5CfM/dlxiRItrL0Odv5hDPYb3vgiwfpEnoWtAoJNgrQ=&pass_ticket=Pko/zMowAey+cGvhxAFB5uiVZGu67pdKOSU5LVAGPp1La079eehYzrILegXT4E30&wx_header=3"
title: "当 LLM 应用遇上可观测性：用 GreptimeDB 统一 Traces、Metrics 和对话记录"
account: "GreptimeDB"
published_at: "2026-03-10T10:00:34.000Z"
saved_at: "2026-07-22T05:04:40.782Z"
sync_id: "art_c2afab05817c42dcb8bd1006d7c83e29"
parse_status: "ok"
---

# 当 LLM 应用遇上可观测性：用 GreptimeDB 统一 Traces、Metrics 和对话记录

# 三个系统，定位一个问题

LLM 应用上线之后，工程师通常会遇到这几个问题：

- 这个请求为什么这么慢？是模型响应慢，还是业务逻辑的问题？
- 上周 token 用量突然涨了 3 倍，是哪个用户？哪个 prompt？
- 用户反馈"AI 回答得一塌糊涂"，能找到那条对话记录吗？
- 同一个场景，换个模型，p95 延迟和成本差多少？

这些问题本身不复杂，但如果你用的是传统可观测性方案——Prometheus 存 metrics、Elasticsearch 存日志、Jaeger 存 traces——三个系统之间的数据根本关联不起来。一次 LLM 调用的  `trace_id`  在 Jaeger 里，token 用量在 Prometheus 里，对话内容在 Elasticsearch 里，定位一个问题要跨三个界面来回跳。

LLM 应用的可观测性不缺数据，缺的是把这三类信号统一存储、统一查询的能力。

本文以一个基于 **OpenTelemetry GenAI 语义规范**[1] 的 demo 为例，展示如何用 GreptimeDB 作为统一后端，解决上面这些问题。

# OTel GenAI 语义规范：LLM 可观测性的统一语言

**OpenTelemetry**[2]（OTel）在微服务可观测性领域已经是事实标准。2024 年起，OTel 社区开始为 GenAI 工作负载制定专用的**语义规范（Semantic Conventions）**[3]，定义了一套  `gen_ai.*`  命名空间下的标准属性体系，把 LLM 调用的遥测数据格式统一了下来。

## 三类信号

OTel GenAI 规范覆盖三类可观测性信号：

**Traces（链路追踪）**——每次 LLM 调用产生一个 Span，携带结构化属性：

| 属性 | 含义 | 示例值 |
| --- | --- | --- |
| `gen_ai.system` | 提供商 | `openai` |
| `gen_ai.request.model` | 请求模型 | `gpt-4o-mini` |
| `gen_ai.response.model` | 实际使用模型 | `gpt-4o-mini-2024-07-18` |
| `gen_ai.usage.input_tokens` | 输入 token 数 | `142` |
| `gen_ai.usage.output_tokens` | 输出 token 数 | `87` |
| `gen_ai.response.finish_reasons` | 停止原因（JSON 数组） | `["stop"]` 、 `["tool_calls"]` |

**Metrics（指标）**——SDK 自动生成两个直方图 metric（OTel 规范中的 instrument 名）：

- gen_ai.client.operation.duration ：每次调用的端到端延迟（单位 s ）
- gen_ai.client.token.usage ：每次调用的 token 消耗（无单位）

两个 metric 写入 GreptimeDB 后，表名规则有所不同： `gen_ai.client.operation.duration`  有单位，Prometheus 惯例会追加  `_seconds`  后缀，实际表名为  `gen_ai_client_operation_duration_seconds_bucket/count/sum` ； `gen_ai.client.token.usage`  无单位，不追加后缀，实际表名为  `gen_ai_client_token_usage_bucket/count/sum` 。

**Logs/Events（日志/事件）**——可选开启的会话内容捕获，记录完整的 prompt 和 completion。

## 一行代码接入

对于 Python + OpenAI SDK，接入成本极低：

```
from opentelemetry.instrumentation.openai_v2 import OpenAIInstrumentor

OpenAIInstrumentor().instrument()

# 之后所有 OpenAI SDK 调用自动产生 gen_ai.* 遥测数据
client.chat.completions.create(model="gpt-4o-mini", messages=[...])
```

**opentelemetry-instrumentation-openai-v2**[4] 自动 patch 了 OpenAI SDK，每次调用都会生成符合规范的 Span、Metric 和 Log，无需修改业务代码。除了 OpenAI，规范还覆盖 Anthropic、Azure AI Inference、AWS Bedrock 等主流提供商。

# Demo 架构：OTLP 直送 GreptimeDB

这个 demo 的架构刻意保持简单：

```
GenAI 应用（Python）
│  OpenAI SDK + OTel GenAI Instrumentor
│  自动产生 traces + metrics + logs
│
│ OTLP/HTTP
▼
GreptimeDB
├── opentelemetry_traces  ← traces，gen_ai.* 属性展开为可查询列
├── genai_conversations   ← logs，完整 prompt/completion 内容
├── OTel metrics          ← histograms，支持 PromQL 查询
└── Flow 聚合表            ← 实时预聚合的 token/延迟/状态统计
│
Grafana
├── SQL 面板（traces、logs、Flow 表）
├── PromQL 面板（OTel histogram metrics）
└── Trace 瀑布图（GreptimeDB Grafana 插件）
```

三类 OTel 信号通过不同的端点写入 GreptimeDB（详见 **GreptimeDB OpenTelemetry 接入文档**[5]）：

```
# Traces：通过内置 pipeline 将 span attributes 展平为可查询列
OTLPSpanExporter(
endpoint="http://greptimedb:4000/v1/otlp/v1/traces",
headers={"x-greptime-pipeline-name": "greptime_trace_v1"},
)

# Metrics：标准 OTLP，histogram 自动支持 PromQL
OTLPMetricExporter(endpoint="http://greptimedb:4000/v1/otlp/v1/metrics")

# Logs：通过自定义 header 路由到指定表
OTLPLogExporter(
endpoint="http://greptimedb:4000/v1/otlp/v1/logs",
headers={"X-Greptime-Log-Table-Name": "genai_conversations"},
)
```

整个链路没有 OTel Collector——数据从应用直接写入 GreptimeDB，适合 demo 和小规模部署。生产环境通常会在中间加 Collector 处理 buffer/retry、采样和 PII 脱敏，但架构核心不变。

跑起来之后，Grafana dashboard 长这样——请求数、token 用量、成本、错误率一屏呈现，往下是 token 趋势、延迟分位数、model comparison：

![](附件资源/当%20LLM%20应用遇上可观测性：用%20GreptimeDB%20统一%20Traces、Metrics%20和对话记录/img_1.png)

Dashboard 总览：请求数、token 用量、累计成本、错误率一屏呈现

# GreptimeDB 的三个核心优势

## 1. 三类信号同库，跨信号关联查询

传统方案里，traces、metrics、logs 分散在三个系统，"从 trace 找到对应日志"往往要在界面之间手动传递  `trace_id` ，无法用一条查询完成。

GreptimeDB 将三类信号存在同一个数据库。 `opentelemetry_traces`  表和  `genai_conversations`  表都有  `trace_id`  和  `span_id`  列，一条 SQL 就能把 token 用量和完整对话内容关联起来。

注意： `opentelemetry_traces`  的列名包含点号（如  `span_attributes.gen_ai.request.model` ），在 SQL 中需用双引号包裹，下文所有示例统一使用双引号：

```
-- 找到 token 用量最高的用户 prompt，直接关联查看内容
SELECT
t.trace_id,
t."span_attributes.gen_ai.request.model" AS model,
t."span_attributes.gen_ai.usage.input_tokens" AS input_tokens,
t."span_attributes.gen_ai.usage.output_tokens" AS output_tokens,
json_get_string(parse_json(c.body), 'content') AS user_message
FROM opentelemetry_traces t
JOIN genai_conversations c ON t.trace_id = c.trace_id AND t.span_id = c.span_id
WHERE t."span_attributes.gen_ai.system" IS NOT NULL
AND json_get_string(parse_json(c.body), 'message.role') IS NULL
ORDER BY input_tokens DESC
LIMIT 10;
```

Prometheus + Elasticsearch 的组合里这类查询几乎无法实现——两个系统没有共享的存储引擎， `trace_id`  关联只能在应用层手动拼接。

## 2. 从原始 Span 衍生 Metrics，不用双写

GreptimeDB 的流处理引擎（Flow）提供持续聚合能力，类似 SQL 里的物化视图，但实时驱动。

每个 LLM 调用的 Span 本身就是一个[宽事件（Wide Event）](https://mp.weixin.qq.com/s?__biz=Mzg3MTgxMzczNg==&mid=2247492737&idx=1&sn=3ffdb9752a2477ff435a8a4d40cab7ac&scene=21#wechat_redirect)，携带了所有需要聚合的字段：model、token counts、duration、status code。有了 Flow，不需要应用层再额外上报一套 metrics，直接从 traces 里聚合出来就够了。

这个 demo 定义了三个 Flow，将  `opentelemetry_traces`  表的原始 Span 实时聚合到三张汇总表：

```
-- token 用量：每分钟每模型的消耗
CREATE FLOW genai_token_usage_flow
SINK TO genai_token_usage_1m
EXPIRE AFTER'24h'
AS
SELECT
"span_attributes.gen_ai.request.model"AS model,
COUNT("span_attributes.gen_ai.request.model") AS request_count,
SUM(CAST("span_attributes.gen_ai.usage.input_tokens" AS DOUBLE)) AS total_input_tokens,
SUM(CAST("span_attributes.gen_ai.usage.output_tokens" AS DOUBLE)) AS total_output_tokens,
date_bin('1 minute'::INTERVAL, "timestamp") AS time_window
FROM opentelemetry_traces
WHERE "span_attributes.gen_ai.system" IS NOT NULL
GROUP BY "span_attributes.gen_ai.request.model", time_window;

-- 延迟分布：用 uddsketch 保存分位数草图，支持 p50/p95/p99 查询
CREATE FLOW genai_latency_flow
SINK TO genai_latency_1m
EXPIRE AFTER '24h'
AS
SELECT
"span_attributes.gen_ai.request.model" AS model,
COUNT("span_attributes.gen_ai.request.model") AS request_count,
uddsketch_state(128, 0.01, duration_nano) AS duration_sketch,
date_bin('1 minute'::INTERVAL, "timestamp") AS time_window
FROM opentelemetry_traces
WHERE "span_attributes.gen_ai.system" IS NOT NULL
GROUP BY "span_attributes.gen_ai.request.model", time_window;
```

**uddsketch_state(buckets, error_rate, value)**[6] 是 GreptimeDB 1.0 RC1 中的分位数聚合函数，三个参数依次是：分桶数（128）、误差率（0.01，即 1%）、待聚合的值列。查询时直接从 Flow 结果表读取，不用扫全量原始 traces：

```
SELECT
model,
ROUND(uddsketch_calc(0.50, duration_sketch) / 1000000, 1) AS p50_ms,
ROUND(uddsketch_calc(0.95, duration_sketch) / 1000000, 1) AS p95_ms,
ROUND(uddsketch_calc(0.99, duration_sketch) / 1000000, 1) AS p99_ms,
time_window
FROM genai_latency_1m
ORDER BY time_window DESC
LIMIT 20;
```

## 3. 原始对话可搜索，点击直达 Trace

OTel GenAI 规范支持将完整的 prompt 和 completion 内容作为 Log Events 发送。开启  `OTEL_INSTRUMENTATION_GENAI_CAPTURE_MESSAGE_CONTENT=true`  后，每条用户输入和模型输出都作为一条 log 记录写入  `genai_conversations`  表。GreptimeDB 接收 OTLP 日志时会自动创建该表，并对  `body`  列启用**全文索引**[7]，无需手动建表。

**matches_term()**[8] 函数利用全文索引做关键词检索：

```
-- 搜索所有提到 "GreptimeDB" 的对话
SELECT
timestamp,
trace_id,
CASE WHEN json_get_string(parse_json(body), 'message.role') IS NOT NULL
THEN json_get_string(parse_json(body), 'message.role')
ELSE 'user' END AS role,
COALESCE(
json_get_string(parse_json(body), 'message.content'),
json_get_string(parse_json(body), 'content')
) AS content
FROM genai_conversations
WHERE matches_term(body, 'GreptimeDB')
ORDER BY timestamp DESC
LIMIT 20;
```

`genai_conversations`  表里每条 log 的  `body`  结构因角色不同而有所差异：用户消息是  `{"content": "..."}`  顶层结构，助手回复是  `{"message": {"role": "assistant", "content": "..."}}`  嵌套结构，用  `COALESCE`  同时兼容两种格式。

Grafana dashboard 里的 "Search Conversations" 输入框就是这条查询的前端——输入关键词，下方立刻显示匹配的对话，每条记录都带  `trace_id`  链接，点击后直接跳转到对应的 trace 瀑布图。

![](附件资源/当%20LLM%20应用遇上可观测性：用%20GreptimeDB%20统一%20Traces、Metrics%20和对话记录/img_2.png)

对话检索：输入关键词即可全文搜索历史 prompt/completion，每条记录携带 trace_id

下图展示了从 Recent Conversations 到 Recent Traces，再到 Trace Detail 瀑布图的完整视图——**三类信号在同一界面里通过 ** `trace_id` ** 串联**：

![](附件资源/当%20LLM%20应用遇上可观测性：用%20GreptimeDB%20统一%20Traces、Metrics%20和对话记录/img_3.png)

对话记录、trace 列表与 trace 瀑布图在同一界面通过 trace_id 关联

对于 tool calling、RAG pipeline、multi-agent 这类复杂场景，trace 结构会形成嵌套的 span 树。demo 里 tool calling 场景的完整 trace：

```
tool_call_pipeline (4.01s)
├── plan_tool_use (2.62s)
│   └── chat llama3.2 (2.62s)     ← 模型判断需要调用工具
├── execute_tools (59.31ms)
│   └── tool.calculate (59.23ms)  ← 模拟工具执行
└── synthesize_answer (1.33s)
└── chat llama3.2 (1.33s)     ← 携带工具结果再次调用模型
```

![](附件资源/当%20LLM%20应用遇上可观测性：用%20GreptimeDB%20统一%20Traces、Metrics%20和对话记录/img_4.png)

tool_call_pipeline 的 trace 瀑布图：嵌套 span 树清晰展示每个阶段耗时

这些嵌套结构完整保存在 GreptimeDB 中，通过 GreptimeDB Grafana 插件渲染成标准瀑布图，也可以直接用 SQL 查询特定  `trace_id`  的所有 span。

# 你能从数据里看到什么

**成本估算**：按模型实际用量，估算任意时间段的费用（以下以 gpt-4o-mini 定价为例，实际费率以 OpenAI 官网为准）——

```
SELECT
"span_attributes.gen_ai.request.model" AS model,
SUM("span_attributes.gen_ai.usage.input_tokens")  AS input_tokens,
SUM("span_attributes.gen_ai.usage.output_tokens") AS output_tokens,
ROUND(
SUM("span_attributes.gen_ai.usage.input_tokens")  * 0.15 / 1000000
+ SUM("span_attributes.gen_ai.usage.output_tokens") * 0.60 / 1000000,
4
) AS estimated_cost_usd
FROM opentelemetry_traces
WHERE "span_attributes.gen_ai.system" IS NOT NULL
AND timestamp > NOW() - '1 hour'::INTERVAL
GROUP BY model
ORDER BY estimated_cost_usd DESC;
```

**各模型错误率**：哪个模型最不稳定——

```
SELECT
"span_attributes.gen_ai.request.model" AS model,
COUNT(*) AS total,
COUNT(CASE WHEN span_status_code = 'STATUS_CODE_ERROR' THEN 1 END) AS errors,
ROUND(
COUNT(CASE WHEN span_status_code = 'STATUS_CODE_ERROR' THEN 1 END) * 100.0
/ COUNT(*),
1
) AS error_rate_pct
FROM opentelemetry_traces
WHERE "span_attributes.gen_ai.system" IS NOT NULL
AND timestamp > NOW() - '1 hour'::INTERVAL
GROUP BY model
ORDER BY error_rate_pct DESC;
```

**PromQL 查询**：OTel SDK 生成的 histogram metrics 同样支持 PromQL。两个 metric 的实际表名已在前文说明，PromQL 中直接使用：

```
# token 消耗的 p95 分布
histogram_quantile(0.95,
sum(rate(gen_ai_client_token_usage_bucket[5m])) by (le, gen_ai_token_type)
)

# 各模型请求速率
sum(rate(gen_ai_client_operation_duration_seconds_count[5m])) by (gen_ai_request_model)
```

GreptimeDB 同时支持 SQL 和 PromQL，Grafana dashboard 里两种查询方式并列，共用同一套数据。下图展示了 Token Efficiency、Model Comparison 和 Metrics（PromQL）三个区块：

![](附件资源/当%20LLM%20应用遇上可观测性：用%20GreptimeDB%20统一%20Traces、Metrics%20和对话记录/img_5.png)

Token Efficiency、Model Comparison、PromQL Metrics：SQL 与 PromQL 面板共存于同一 dashboard

# 快速上手

项目开源在 **GreptimeTeam/demo-scene**[9]（阅读原文即可跳转 demo），三步跑起来：

```
# 1. 设置 OpenAI API Key
export OPENAI_API_KEY="sk-..."

# 2. 启动全部服务（GreptimeDB + Grafana + load generator + Flow 聚合）
docker compose --profile load up -d

# 3. 打开 Grafana：http://localhost:3000（admin / admin）
#    打开 "GenAI Observability" dashboard
```

也支持本地 Ollama，不需要 OpenAI API Key：

```
docker compose --profile local up -d
docker compose --profile local exec ollama ollama pull llama3.2
OPENAI_BASE_URL=http://ollama:11434/v1 MODEL_NAME=llama3.2 \
docker compose --profile load up -d
```

# 小结

OTel GenAI 规范统一了 LLM 遥测数据的格式，但它只管数据怎么产出，不管数据存在哪、怎么查。这篇文章展示的是后半段：用 GreptimeDB 把 traces、metrics、logs 放在同一个库里，通过 Flow 从原始 span 直接聚合出指标，用  `matches_term()`  搜索历史对话，点  `trace_id`  跳到完整链路。SQL 和 PromQL 都支持，现有的 Grafana 工作流不用改。

如果你在做 LLM 应用的可观测性，可以先把 demo 跑起来看看效果。

# 关于 Greptime

Greptime 格睿科技专注于打造新一代可观测性数据库，服务开发者与企业用户，覆盖从边缘设备到云端企业级部署的多样化需求。

- GreptimeDB 开源版 ：开源、云原生，统一处理指标、日志和追踪数据，适合中小规模 IoT 与可观测性场景；
- GreptimeDB 企业版 ：面向关键业务，提供更高性能、高安全性、高可用性和智能化运维服务；

欢迎加入开源社区参与贡献与交流！推荐从带有  `good first issue`  标签的任务入手，一起共建可观测未来。添加微信小助手: greptime 参与技术交流！

![](附件资源/当%20LLM%20应用遇上可观测性：用%20GreptimeDB%20统一%20Traces、Metrics%20和对话记录/img_6.png)

- ⭐ Star us on GitHub：https://github.com/GreptimeTeam/greptimedb
- 📚 官网：https://greptime.cn/
- 📖 文档：https://docs.greptime.cn/
- 🌍 Twitter：https://twitter.com/Greptime
- 💬 Slack：https://greptime.com/slack
- 💼 LinkedIn：https://www.linkedin.com/company/greptime/

往期精彩文章：

- [从黑匣子到全量可观测：理想汽车车载数据架构演进之路](https://mp.weixin.qq.com/s?__biz=Mzg3MTgxMzczNg==&mid=2247494434&idx=1&sn=fb6673f990733a81e55933198c143092&scene=21#wechat_redirect)
- [Agent 可观测性：旧瓶还能用，但必须装新酒](https://mp.weixin.qq.com/s?__biz=Mzg3MTgxMzczNg==&mid=2247494091&idx=1&sn=f272af58c1056be06f4e8d5ac5266b5c&scene=21#wechat_redirect)
- [Agent 质量评估：监控全绿，AI 回答却不靠谱？](https://mp.weixin.qq.com/s?__biz=Mzg3MTgxMzczNg==&mid=2247494327&idx=1&sn=55af7869ed2936a71010730908c54699&scene=21#wechat_redirect)

**Reference**

[1] OpenTelemetry GenAI 语义规范: _https://opentelemetry.io/docs/specs/semconv/gen-ai/_

[2] OpenTelemetry: _https://opentelemetry.io/_

[3] 语义规范（Semantic Conventions）: _https://opentelemetry.io/docs/specs/semconv/gen-ai/_

[4]  `opentelemetry-instrumentation-openai-v2` : _https://pypi.org/project/opentelemetry-instrumentation-openai-v2/_

[5] GreptimeDB OpenTelemetry 接入文档: _https://docs.greptime.cn/user-guide/ingest-data/for-observability/opentelemetry/_

[6]  `uddsketch_state(buckets, error_rate, value)` : _https://docs.greptime.cn/reference/sql/functions/approximate/#uddsketch_calc_

[7] 全文索引: _https://docs.greptime.cn/user-guide/logs/fulltext-search/_

[8]  `matches_term()` : _https://docs.greptime.cn/user-guide/logs/fulltext-search/_

[9] GreptimeTeam/demo-scene: _https://github.com/GreptimeTeam/demo-scene/tree/main/genai-observability_

---
原文链接：https://mp.weixin.qq.com/s?__biz=Mzg3MTgxMzczNg%3D%3D&mid=2247494460&idx=1&sn=6ceefdc0c695c71c33fdc07710ae305a&chksm=cf4229c4ef83ea476f31aeb9809927dc7d14cc3701c336fddb4feab14fe73359cbd04a563353
