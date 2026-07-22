---
source_url: "https://mp.weixin.qq.com/s?search_click_id=2577446274891197028-1784693494802-8961431991&__biz=MzI5ODk5ODI4Nw==&mid=2247559208&idx=2&sn=61defdb2657ad74ec443021f17e75eec&chksm=ed0bd95335764bbfff1b86f2fd84b7ce234f211caebc390233157af87136049eef9ddb3139c1&subscene=90&scene=7&clicktime=1784693494&enterid=1784693494&ascene=65&devicetype=iOS26.5.2&version=18004b42&nettype=3G+&abtest_cookie=AAACAA==&lang=zh_CN&countrycode=CN&fontScale=100&exportkey=n_ChQIAhIQ97bf2spKmqehdH+y+HxwlhLhAQIE97dBBAEAAAAAACAaBmgPtEUAAAAOpnltbLcz9gKNyK89dVj00cj5fLq5cZvf2GUz54AYaxqYhv+hdP2UCdPpBiZo9P8040LasnNVy0jpGbWPDjDMeyL443YZx+aGTxLYI9lHhzf5rxTxFM0Ud+7fQqX5p4RQHIgnARx7c0niysMnfTH0HhBYDyXZCpvwRsQLqSxAJsYHSryPwTEOzteQ8ThMVzN/l9q9hsqfU7F4RaorjS3aHnhT+Kl43SapsJRAcgC66OUH1cgsoD8cyPJ1G7PPlKIi7y+2uQfU7pLM4w==&pass_ticket=V5cmh3G6l91Oq26cr3bgx87nBqkSYn0RElF65nJEA6VtyqacERaM3hBii0zog1OV&wx_header=3"
title: "一文看懂 OpenTelemetry GenAI：LLM、Agent、MCP 怎么做可观测性"
account: "CNCF"
published_at: "2026-05-25T02:03:41.000Z"
saved_at: "2026-07-22T04:11:42.200Z"
sync_id: "art_bcaff7a9646d45748082086ee44e1b2e"
parse_status: "ok"
---

# 一文看懂 OpenTelemetry GenAI：LLM、Agent、MCP 怎么做可观测性

LLM 应用的可观测性跟传统微服务不是一个路子。一次 LLM 调用产生的遥测数据比 HTTP 请求多得多，但难的不是量，而是形态：prompt 和 completion 是大段文本，tool calling 的参数结构每次都不一样，agent 的多步推理路径没法用固定 schema 描述。你不光要知道"调了什么模型、花了多长时间"，还得知道"用了多少 token、花了多少钱、回答质量怎么样"。

传统的 OTel 语义约定 (Semantic Conventions) 管不了这些。 `http.request.method` 、 `db.system.name`  对 LLM 调用没有意义。社区需要一套专门的规范。

2024 年 4 月，OpenTelemetry 在 Semantic Conventions SIG 下成立了 **GenAI 特别兴趣组 (GenAI SIG)**[1]。从那时到现在，这套规范从最初的 LLM 客户端调用追踪，扩展到覆盖 Agent 编排、MCP 工具调用、内容捕获、质量评估六个层面。截至本文发稿，OTel 官方 **docs 站版本为 v1.41.0**[2]，最新 GitHub release 为 **v1.41.1**[3]（仅含 k8s codegen 修复，不涉及 GenAI）。

本文逐层拆解这套规范的结构：每个部分定义了什么、为什么这样设计、现在能用到什么程度。读过我们之前 **[Agent 可观测性](https://mp.weixin.qq.com/s?__biz=Mzg3MTgxMzczNg==&mid=2247494091&idx=1&sn=f272af58c1056be06f4e8d5ac5266b5c&scene=21#wechat_redirect)**[4]文章的话，本文是它的"规范篇"，讲的是社区对 Agent 可观测性挑战给出的标准化回答。

![](附件资源/一文看懂%20OpenTelemetry%20GenAI：LLM、Agent、MCP%20怎么做可观测性/img_1.png)

_OTel GenAI 语义规范六层结构_

# 规范的演进：从早期到 v1.41

GenAI SIG 在 2024 年 4 月启动时，目标很明确：给 LLM 客户端调用定一组标准属性——model 名、token 用量、延迟——让不同 instrumentation 库产出格式一致的遥测数据。早期版本定义了  `gen_ai.system` 、 `gen_ai.request.model`  等基础属性和两个 histogram metric。

v1.37 是分界线。这一版对 chat history 的记录方式做了**大幅重构**[5]：原来是 per-message events（每条消息一个 event），改成了三个聚合属性—— `gen_ai.system_instructions` 、 `gen_ai.input.messages` 、 `gen_ai.output.messages` ——放在 span 上或新引入的  `gen_ai.client.inference.operation.details`  event 上。改的原因很直接：per-message events 在多轮对话场景下产生大量细碎事件，查询关联都困难。

此后每一版都有 GenAI 相关的重要变更：

| 版本 | GenAI 相关变更 |
| --- | --- |
| v1.37 [6] | 重构 chat history 记录方式； `gen_ai.system` 改为 `gen_ai.provider.name` |
| v1.38 [7] | Evaluation event；tool definitions 和 call details； `invoke_agent` kind 指南；embeddings dimension；multimodal JSON schema |
| v1.39 [8] | MCP 语义约定 |
| v1.40 [9] | Retrieval span；cache token 属性；Anthropic input token 计算指南 |
| v1.41 [10] | `execute_tool` span 命名要求工具名；reasoning tokens； `invoke_workflow` ；streaming metrics；拆分 `invoke_agent` CLIENT/INTERNAL |

![](附件资源/一文看懂%20OpenTelemetry%20GenAI：LLM、Agent、MCP%20怎么做可观测性/img_2.png)

_OTel GenAI 语义规范演进时间线_截至 2026 年 5 月，GenAI 和 MCP 语义规范仍处于 **Development 状态**[11]。规范文档写得很明确："稳定版发布前会更新过渡计划。"目前没有公开的稳定化时间表，但 **2026 Semantic Conventions Roadmap**[12] 已在向各子 SIG 征集计划。

属性名和结构仍可能变，但核心概念已经稳定。规范提供了  `OTEL_SEMCONV_STABILITY_OPT_IN`  环境变量管理版本过渡，新项目现在基于规范构建是合理的。

# Layer 1: Client Spans——模型调用的标准化

规范最基础的一层，定义应用代码调用 GenAI 模型时产生的 **span**[13]。

## Inference

每次 LLM 调用产生一个 span， `gen_ai.operation.name`  设为  `chat`  或  `text_completion` ，多模态生成场景还会用  `generate_content。` span kind 是  `CLIENT` ，因为模型通常跑在远程服务上。

核心属性：

| 属性 | 含义 | 示例 |
| --- | --- | --- |
| `gen_ai.provider.name` | 提供商标识 | `openai` 、 `anthropic` 、 `aws.bedrock` |
| `gen_ai.request.model` | 请求时指定的模型 | `gpt-4o-mini` |
| `gen_ai.response.model` | 实际响应的模型 | `gpt-4o-mini-2024-07-18` |
| `gen_ai.usage.input_tokens` | 输入 token 数 | `142` |
| `gen_ai.usage.output_tokens` | 输出 token 数 | `87` |
| `gen_ai.response.finish_reasons` | 停止原因 | `["stop"]` 、 `["tool_calls"]` |

光看表格不够直观，下面是一个 OpenAI chat completion 调用产生的 span 在 trace viewer（如 Jaeger、Grafana Tempo）中展示的样子：

```
{
"operationName": "chat gpt-4o-mini",
"spanKind": "CLIENT",
"duration": "1.23s",
"attributes": {
"gen_ai.operation.name":          "chat",
"gen_ai.provider.name":           "openai",
"gen_ai.request.model":           "gpt-4o-mini",
"gen_ai.response.model":          "gpt-4o-mini-2024-07-18",
"gen_ai.usage.input_tokens":      142,
"gen_ai.usage.output_tokens":     87,
"gen_ai.response.finish_reasons": ["stop"],
"server.address":                 "api.openai.com",
"server.port":                    443
}
}
```

**❝**注：这是逻辑视图，方便阅读。实际的 OTLP wire format（protobuf 或 JSON encoding）用的是  `KeyValue`  数组结构，属性值按类型区分（ `stringValue` 、 `intValue`  等），时间戳是纳秒级 Unix timestamp 字符串。

`server.address`  和  `server.port`  是通用网络属性，不属于 GenAI 规范本身，但 instrumentation 通常会一起带上。 `provider.name`  和  `request.model`  是两个独立属性。同一个模型可能通过不同提供商访问（Azure OpenAI 和 OpenAI 直连都能调 GPT-4o）， `provider.name`  决定该用哪套提供商专属属性。

`request.model`  和  `response.model`  的区分也有实际意义：你请求  `gpt-4o` ，实际响应的可能是  `gpt-4o-2024-08-06` 。Fine-tuned 模型的  `response.model`  应该比基座模型名更具体。

## Embeddings 和 Retrievals

Embeddings（ `gen_ai.operation.name=embeddings` ）用于向量嵌入，规范新增了  `gen_ai.embeddings.dimension.count`  记录向量维度数。Retrievals 覆盖 RAG pipeline 中的检索步骤。

## 一行代码接入

Python + OpenAI SDK 的**接入成本极低**[14]：

```
from opentelemetry.instrumentation.openai_v2 import OpenAIInstrumentor

OpenAIInstrumentor().instrument()

# 之后所有 OpenAI SDK 调用自动产生符合规范的 span + metrics + events
client.chat.completions.create(model="gpt-4o-mini", messages=[...])
```

`opentelemetry-instrumentation-openai-v2`  是目前最成熟的 GenAI instrumentation。Anthropic、AWS Bedrock 等通过社区库支持。

# Layer 2: Agent & Workflow Spans——超越微服务的新概念

传统分布式追踪有 HTTP span、RPC span、DB span，但没有"agent 调用"。GenAI 规范为此定义了一组**全新的操作类型**[15]。

## create_agent

描述 agent 的创建，用于远程 agent 服务（如 OpenAI Assistants API、AWS Bedrock Agents），span kind 为  `CLIENT` 。

```
Span: create_agent support-router
Kind: CLIENT
Attributes:
gen_ai.operation.name = create_agent
gen_ai.agent.name = support-router
gen_ai.provider.name = openai
```

## invoke_agent

调用 agent 执行任务。v1.41 明确**拆分了两种场景**[16]： `CLIENT` （远程调用）和  `INTERNAL` （本地框架执行，比如 LangGraph 在同一进程跑 agent 逻辑）。

## invoke_workflow

描述预定义流程的执行（**v1.41 新增**[17]）。跟 agent 的区别：agent 有自主推理能力，workflow 是固定流程。

## execute_tool

工具执行 span，kind 为  `INTERNAL` 。**v1.41 起工具名必须出现在 span 名中**[18]（ `execute_tool {gen_ai.tool.name}` ）。 `gen_ai.tool.call.arguments`  和  `gen_ai.tool.call.result`  只在隐私策略允许时记录。

## 这些 span 类型解决什么问题？

我们在 **Agent 可观测性**[19]文章里讨论过 agent 场景的核心挑战：agent 的推理过程在 trace 中是黑盒。有了 agent span 约定，执行流程可以被标准化拆解：

```
invoke_agent research-assistant (INTERNAL)
├── chat gpt-4o (CLIENT)                ← 模型决定需要搜索
├── execute_tool web_search (INTERNAL)  ← 执行搜索
├── chat gpt-4o (CLIENT)               ← 基于搜索结果继续推理
├── execute_tool summarize (INTERNAL)   ← 摘要处理
└── chat gpt-4o (CLIENT)               ← 生成最终回答
```

每一步都有标准化属性，任何兼容的后端都能解析和展示。

# Layer 3: MCP 语义约定——解决 Trace 断裂

Model Context Protocol (MCP) 在 2025 年快速普及，但带来了一个可观测性问题：agent 端和 MCP server 端的 trace 是断的。

**Glama 在分析中指出**[20]：agent 端产生 Trace A，MCP server 端产生 Trace B，两者之间没有 context 传播。OTel 在 **v1.39**[21] 引入的 **MCP 语义约定**[22]就是为了解决这个问题。

## 核心设计

MCP 基于 JSON-RPC，但规范推荐用 MCP 约定而非通用 RPC 语义约定，因为 MCP span 携带了 RPC 约定不覆盖的上下文（session、tool call 详情等）。

以 stdio 传输为例的 client span：

```
Span: tools/call get-weather
Kind: CLIENT
Attributes:
gen_ai.operation.name = execute_tool
mcp.method.name = tools/call
mcp.session.id = session-xyz
mcp.protocol.version = 2025-03-26
gen_ai.tool.name = get-weather
jsonrpc.request.id = 42
network.transport = pipe            # stdio 对应 pipe
```

HTTP 传输则是  `network.transport = tcp` （或  `quic` ），加上  `network.protocol.name = http` （参见 **MCP 规范**[23]）。

如果 client 和 server 两端的 instrumentation 都按规范传播 W3C Trace Context，server span 就能挂到 client span 下面，trace 不再断裂。

## 与 execute_tool 的兼容

规范设计了去重逻辑：如果 MCP instrumentation 检测到外层 GenAI instrumentation 已经在追踪 tool 执行，就不创建重复 span，而是在现有 span 上添加 MCP 属性（ `mcp.method.name` 、 `mcp.session.id`  等）。

一个完整的 **agent + MCP 调用链路**[24]：

```
invoke_agent weather-forecast-agent (INTERNAL)
├── chat {model} (CLIENT)                          ← GenAI model
├── tools/call get-weather (CLIENT)                ← MCP client
│   └── tools/call get-weather (SERVER)            ← MCP server
└── chat {model} (CLIENT)                          ← GenAI model
```

## MCP 专属 Metrics

规范定义了四个 MCP metric： `mcp.client.operation.duration`  /  `mcp.server.operation.duration` （操作延迟）和  `mcp.client.session.duration`  /  `mcp.server.session.duration` （会话持续时间）。

# Layer 4: Events 与内容捕获——隐私与可观测性的平衡

传统 OTel 的 HTTP span 不太需要纠结"要不要记录请求体"。但 LLM 应用不一样：prompt 和 completion 内容既是排查问题的关键数据，也是最敏感的数据。

## 两个核心 Event

**gen_ai.client.inference.operation.details**[25]（v1.37 新增）：记录一次 GenAI 调用的完整输入输出。这是个 opt-in 的 event，可由后端按事件/日志方式处理，与 trace 数据的生命周期和存储策略解耦。

`gen_ai.evaluation.result` ：记录 GenAI 输出的**质量评估结果**[26]，包含  `gen_ai.evaluation.score.value`  和  `gen_ai.evaluation.score.label` 。比如一个 relevancy 评估器返回 score.value=0.85、score.label="relevant"。

`operation.details`  event 长什么样？下面是启用内容捕获后的逻辑视图：

```
{
"eventName": "gen_ai.client.inference.operation.details",
"attributes": {
"gen_ai.system_instructions": [
{"type": "text", "content": "You are a helpful customer support agent."}
],
"gen_ai.input.messages": [
{
"role": "user",
"parts": [{"type": "text", "content": "我的订单 #12345 到哪了？"}]
}
],
"gen_ai.output.messages": [
{
"role": "assistant",
"parts": [{"type": "text", "content": "您的订单 #12345 已于今天上午发出，预计明天送达。"}],
"finish_reason": "stop"
}
]
}
}
```

注意：记录在  `gen_ai.client.inference.operation.details`  event 上时，messages 必须按规范定义的 **JSON schema**[27] 以**结构化形式**记录（数组 + 嵌套对象）。如果选择记录在 span attributes 上，OTel 属性系统对嵌套结构支持有限，后端不支持结构化属性时才可以退化成 JSON string。

这些内容在默认模式下不会出现。很多 instrumentation 用  `OTEL_INSTRUMENTATION_GENAI_CAPTURE_MESSAGE_CONTENT=true`  作为 opt-in 开关；无论具体开关叫什么，内容捕获默认不应开启。生产环境里通常走第三种模式（外部存储），span 上只留引用地址。

## 三种内容记录模式

规范定义了**三种处理 prompt/response 内容的方式**[28]：

**不记录（默认）。** 环境变量  `OTEL_INSTRUMENTATION_GENAI_CAPTURE_MESSAGE_CONTENT`  默认 false，最安全。

**记录在 span 属性上。** `gen_ai.input.messages`  和  `gen_ai.output.messages`  作为 span attributes。方便查看，但有大小限制，所有能看 trace 的人都能看到内容。

**外部存储 + span 记引用。** 完整内容存到 S3 、GreptimeDB 等外部存储，span 上只保存引用地址，可以单独设 IAM 和 retention。规范推荐在遥测量较大或需要安全处理敏感数据的生产环境中使用**这种模式**[29]。

![](附件资源/一文看懂%20OpenTelemetry%20GenAI：LLM、Agent、MCP%20怎么做可观测性/img_3.png)

_GenAI 内容捕获的三种模式对比_

# Layer 5: Metrics——两个最基础的 Client Histogram

GenAI 语义规范定义了多个 metric（包括 client 和 server 两侧），其中最基础、最常用的是**两个 client histogram**[30]：

## gen_ai.client.operation.duration

每次 GenAI 操作的端到端延迟，单位秒。维度包括  `gen_ai.operation.name` 、 `gen_ai.request.model` 、 `gen_ai.provider.name` 。

## gen_ai.client.token.usage

每次操作的 token 消耗，单位为  `{token}` 。推荐的 bucket 边界是指数增长的： `[1, 4, 16, 64, 256, 1024, 4096, 16384, 65536, 262144, 1048576, 4194304, 16777216, 67108864]` ，从 1 token 到 67M token。

token 计量有两条规则值得注意：提供商同时报告 used tokens 和 billable tokens 时，instrumentation 必须报告 billable tokens；如果 instrumentation 无法高效获取 token 数（比如需要离线计算），不应该猜测，直接不报告。

这两个 metric 能回答大部分运营问题：哪个模型最贵、哪个场景延迟最高、token 消耗趋势如何。在我们的 **GenAI demo**[31] 中，通过 OTLP 写入 GreptimeDB 后直接用 PromQL 查询：

```
# token 消耗的 p95
histogram_quantile(0.95,
sum(rate(gen_ai_client_token_usage_bucket[5m])) by (le, gen_ai_token_type)
)
```

# Layer 6: 提供商专属约定——从通用到特化

通用 GenAI 属性覆盖共性，但每个提供商有自己的特殊能力。规范通过提供商专属约定处理差异。

## OpenAI

目前定义最详细的**提供商约定**[32]。 `gen_ai.provider.name`  设为  `openai` ，在通用属性之外新增了：

- gen_ai.usage.cache_read.input_tokens ：从提供商缓存读取的 token 数
- gen_ai.usage.cache_creation.input_tokens ：写入提供商缓存的 token 数
- gen_ai.usage.reasoning.output_tokens ：推理过程消耗的 token 数（o1/o3 系列， v1.41 新增 [33] ）

区分这些对成本分析很实用：cached input 通常比正常 input 便宜，具体折扣取决于 provider 和模型；reasoning token 则是 reasoning 模型的额外成本项。

## Anthropic、AWS Bedrock、Azure AI Inference

Anthropic（ `gen_ai.provider.name=anthropic` ）提供了  `gen_ai.usage.input_tokens`  的**计算指南**[34]，因为 Anthropic 的计费逻辑跟 OpenAI 不同。AWS Bedrock（ `aws.bedrock` ）和 Azure AI Inference（ `azure.ai.inference` ）扩展了各自平台的属性。

设计原则是： `gen_ai.provider.name`  作为鉴别器，决定该出现哪组专属属性。OpenAI 的 span 不该有  `aws.bedrock.*`  属性，反过来也一样。

# 一个完整的 Trace

把前面六层拼起来，看看一个 agent 通过 MCP 调外部工具的完整 trace 长什么样：

![](附件资源/一文看懂%20OpenTelemetry%20GenAI：LLM、Agent、MCP%20怎么做可观测性/img_4.png)

_Agent + MCP 完整 trace 瀑布图_

```
invoke_agent support-router (INTERNAL, trace=t1)
│
├── chat gpt-4o (CLIENT)
│     gen_ai.provider.name = openai
│     gen_ai.request.model = gpt-4o
│     gen_ai.usage.input_tokens = 1523
│     gen_ai.usage.output_tokens = 42
│     gen_ai.response.finish_reasons = ["tool_calls"]
│
├── tools/call query-orders (CLIENT)                  ← MCP client
│     mcp.method.name = tools/call
│     mcp.session.id = sess-abc
│     gen_ai.tool.name = query-orders
│   │
│   └── tools/call query-orders (SERVER)              ← MCP server
│
└── chat gpt-4o (CLIENT)
gen_ai.usage.input_tokens = 2841
gen_ai.usage.output_tokens = 256
gen_ai.usage.cache_read.input_tokens = 1523     ← OpenAI 专属
gen_ai.response.finish_reasons = ["stop"]

Metrics (同一时间窗口):
gen_ai.client.operation.duration{model=gpt-4o}
gen_ai.client.token.usage{model=gpt-4o, token_type=input}
mcp.client.operation.duration{method=tools/call}

Events (opt-in):
gen_ai.client.inference.operation.details → 完整 prompt/completion
gen_ai.evaluation.result → score.value=0.92, score.label="relevant"
```

注：上面 metrics 的  `{model=...}` 、 `{token_type=...}`  是 Prometheus 风格简写展示；原始 attribute 名是  `gen_ai.request.model` 、 `gen_ai.token.type`  等，导出到 Prometheus 时会下划线化为  `gen_ai_request_model` 、 `gen_ai_token_type` 。不过 Prometheus 3.0 （参见 [Prometheus 3.0 完整解读](https://mp.weixin.qq.com/s?__biz=Mzg3MTgxMzczNg==&mid=2247494757&idx=1&sn=d5c320e9643e05ebc24301167a5d032d&scene=21#wechat_redirect)一文）已经支持了 OpenTelemetry 的命名习惯。

整个 trace 通过  `trace_id`  串联，从 agent 决策到 MCP server 执行到最终回答，一条链路。

# 当前状态与采用

规范处于 Development 状态，离 Stable 还有距离。v1.36 是过渡分界线：已有 instrumentation 默认发旧版属性， `OTEL_SEMCONV_STABILITY_OPT_IN=gen_ai_latest_experimental` **切换到最新版本**[35]。

SDK 方面，**OpenAI Python SDK 的 instrumentation**[36] 最成熟。Anthropic、Cohere、AWS Bedrock 通过社区库（如 **OpenLLMetry**[37]）支持。LangGraph、CrewAI 等框架的 instrumentation 在开发中。

厂商方面，**Datadog 支持 v1.37+ GenAI 语义规范**[38]，是最早原生集成的商业平台之一。**Elastic 的 2026 报告**[39]显示 85% 的组织已在用某种形式的 GenAI for observability，89% 的 OTel 生产用户将厂商合规性 (vendor compliance) 评为"关键"或"非常重要"。

我们在[https://mp.weixin.qq.com/s?__biz=Mzg3MTgxMzczNg==&mid=2247494460&idx=1&sn=6ceefdc0c695c71c33fdc07710ae305a&scene=21#wechat_redirect](https://mp.weixin.qq.com/s?__biz=Mzg3MTgxMzczNg==&mid=2247494460&idx=1&sn=6ceefdc0c695c71c33fdc07710ae305a&scene=21#wechat_redirect)**[GenAI demo](https://mp.weixin.qq.com/s?__biz=Mzg3MTgxMzczNg==&mid=2247494460&idx=1&sn=6ceefdc0c695c71c33fdc07710ae305a&scene=21#wechat_redirect)**[40] 中完整实现了基于这套规范的 LLM 可观测性方案，OTLP 直送 GreptimeDB，三类信号合一存储。想看效果可以直接跑：

```
docker compose --profile load up -d
# Grafana: http://localhost:3000
```

# 总结

OTel GenAI 语义规范给 LLM 和 Agent 可观测性建了统一的数据模型，六个层面覆盖了从模型调用到 agent 编排到工具执行的完整链路。

其中 Agent Spans 和 MCP 约定是传统 OTel 里不存在的新东西，专门为 agent 编排和 tool calling 设计，在构建 agent 应用时最值得关注。内容捕获的三种模式在隐私和可观测性之间做了务实的分层。规范还在快速迭代，v1.37 到 v1.41 之间每一版都有 GenAI 相关变更，现在用是合理的，但要留好适配新版本的余地。

起步建议：从 OpenAI Python SDK 的 instrumentation 入手，接入成本最低。然后看看**规范文档**[41]和我们的[https://mp.weixin.qq.com/s?__biz=Mzg3MTgxMzczNg==&mid=2247494460&idx=1&sn=6ceefdc0c695c71c33fdc07710ae305a&scene=21#wechat_redirect](https://mp.weixin.qq.com/s?__biz=Mzg3MTgxMzczNg==&mid=2247494460&idx=1&sn=6ceefdc0c695c71c33fdc07710ae305a&scene=21#wechat_redirect)**[demo](https://mp.weixin.qq.com/s?__biz=Mzg3MTgxMzczNg==&mid=2247494460&idx=1&sn=6ceefdc0c695c71c33fdc07710ae305a&scene=21#wechat_redirect)**[\[](https://mp.weixin.qq.com/s?__biz=Mzg3MTgxMzczNg==&mid=2247494460&idx=1&sn=6ceefdc0c695c71c33fdc07710ae305a&scene=21#wechat_redirect)42]，对照着理解六层结构在实际场景里的表现。

**相关热点文章：**

- [Agent 可观测性：旧瓶还能用，但必须装新酒](https://mp.weixin.qq.com/s?__biz=Mzg3MTgxMzczNg==&mid=2247494091&idx=1&sn=f272af58c1056be06f4e8d5ac5266b5c&scene=21#wechat_redirect)
- [Agent 质量评估：监控全绿，AI 回答却不靠谱？](https://mp.weixin.qq.com/s?__biz=Mzg3MTgxMzczNg==&mid=2247494327&idx=1&sn=55af7869ed2936a71010730908c54699&scene=21#wechat_redirect)
- [当 LLM 应用遇上可观测性：用 GreptimeDB 统一 Traces、Metrics 和对话记录](https://mp.weixin.qq.com/s?__biz=Mzg3MTgxMzczNg==&mid=2247494460&idx=1&sn=6ceefdc0c695c71c33fdc07710ae305a&scene=21#wechat_redirect)
- [从 eBPF 到 LLM：可观测性管道的每一层都在变｜上海 Meetup 回顾](https://mp.weixin.qq.com/s?__biz=Mzg3MTgxMzczNg==&mid=2247494716&idx=1&sn=aa91107a21cc0482acce7c116c1a3549&scene=21#wechat_redirect)
- [时隔 7 年，Prometheus 3.0 到底改了什么？](https://mp.weixin.qq.com/s?__biz=Mzg3MTgxMzczNg==&mid=2247494757&idx=1&sn=d5c320e9643e05ebc24301167a5d032d&scene=21#wechat_redirect)

**Reference**

[1] GenAI 特别兴趣组 (GenAI SIG): _https://github.com/open-telemetry/community/blob/main/projects/gen-ai.md_

[2] docs 站版本为 v1.41.0: _https://opentelemetry.io/docs/specs/semconv/gen-ai/_

[3] v1.41.1: _https://github.com/open-telemetry/semantic-conventions/releases/tag/v1.41.1_

[4] Agent 可观测性: _https://greptime.com/blogs/2025-12-11-agent-observability_

[5] 大幅重构: _https://github.com/open-telemetry/semantic-conventions/releases/tag/v1.37.0_

[6] v1.37: _https://github.com/open-telemetry/semantic-conventions/releases/tag/v1.37.0_

[7] v1.38: _https://github.com/open-telemetry/semantic-conventions/releases/tag/v1.38.0_

[8] v1.39: _https://github.com/open-telemetry/semantic-conventions/releases/tag/v1.39.0_

[9] v1.40: _https://github.com/open-telemetry/semantic-conventions/releases/tag/v1.40.0_

[10] v1.41: _https://github.com/open-telemetry/semantic-conventions/releases/tag/v1.41.0_

[11] Development 状态: _https://opentelemetry.io/docs/specs/semconv/gen-ai/_

[12] 2026 Semantic Conventions Roadmap: _https://github.com/open-telemetry/semantic-conventions/issues/3330_

[13] span: _https://opentelemetry.io/docs/specs/semconv/gen-ai/gen-ai-spans/_

[14] 接入成本极低: _https://pypi.org/project/opentelemetry-instrumentation-openai-v2/_

[15] 全新的操作类型: _https://opentelemetry.io/docs/specs/semconv/gen-ai/gen-ai-agent-spans/_

[16] 拆分了两种场景: _https://github.com/open-telemetry/semantic-conventions/releases/tag/v1.41.0_

[17] v1.41 新增: _https://github.com/open-telemetry/semantic-conventions/releases/tag/v1.41.0_

[18] v1.41 起工具名必须出现在 span 名中: _https://github.com/open-telemetry/semantic-conventions/releases/tag/v1.41.0_

[19] Agent 可观测性: _https://greptime.com/blogs/2025-12-11-agent-observability_

[20] Glama 在分析中指出: _https://glama.ai/blog/2025-11-29-open-telemetry-for-model-context-protocol-mcp-analytics-and-agent-observability_

[21] v1.39: _https://github.com/open-telemetry/semantic-conventions/releases/tag/v1.39.0_

[22] MCP 语义约定: _https://opentelemetry.io/docs/specs/semconv/gen-ai/mcp/_

[23] MCP 规范: _https://opentelemetry.io/docs/specs/semconv/gen-ai/mcp/_

[24] agent + MCP 调用链路: _https://opentelemetry.io/docs/specs/semconv/gen-ai/mcp/_

[25]  `gen_ai.client.inference.operation.details` : _https://opentelemetry.io/docs/specs/semconv/gen-ai/gen-ai-events/_

[26] 质量评估结果: _https://opentelemetry.io/docs/specs/semconv/gen-ai/gen-ai-events/_

[27] JSON schema: _https://opentelemetry.io/docs/specs/semconv/gen-ai/gen-ai-events/_

[28] 三种处理 prompt/response 内容的方式: _https://opentelemetry.io/docs/specs/semconv/gen-ai/gen-ai-spans/_

[29] 这种模式: _https://opentelemetry.io/docs/specs/semconv/gen-ai/gen-ai-spans/_

[30] 两个 client histogram: _https://opentelemetry.io/docs/specs/semconv/gen-ai/gen-ai-metrics/_

[31] GenAI demo: _https://greptime.com/blogs/2026-03-10-llm-observability-otel-genai-greptimedb_

[32] 提供商约定: _https://opentelemetry.io/docs/specs/semconv/gen-ai/openai/_

[33] v1.41 新增: _https://github.com/open-telemetry/semantic-conventions/releases/tag/v1.41.0_

[34] 计算指南: _https://github.com/open-telemetry/semantic-conventions/releases/tag/v1.40.0_

[35] 切换到最新版本: _https://opentelemetry.io/docs/specs/semconv/gen-ai/_

[36] OpenAI Python SDK 的 instrumentation: _https://pypi.org/project/opentelemetry-instrumentation-openai-v2/_

[37] OpenLLMetry: _https://horovits.medium.com/opentelemetry-for-genai-and-the-openllmetry-project-81b9cea6a771_

[38] Datadog 支持 v1.37+ GenAI 语义规范: _https://www.datadoghq.com/blog/llm-otel-semantic-convention/_

[39] Elastic 的 2026 报告: _https://www.elastic.co/blog/2026-observability-trends-generative-ai-opentelemetry_

[40] GenAI demo: _https://greptime.com/blogs/2026-03-10-llm-observability-otel-genai-greptimedb_

[41] 规范文档: _https://opentelemetry.io/docs/specs/semconv/gen-ai/_

[42] demo: _https://github.com/GreptimeTeam/demo-scene/tree/main/genai-observability_

---
原文链接：https://mp.weixin.qq.com/s?__biz=MzI5ODk5ODI4Nw%3D%3D&mid=2247559208&idx=2&sn=61defdb2657ad74ec443021f17e75eec&chksm=ed0bd95335764bbfff1b86f2fd84b7ce234f211caebc390233157af87136049eef9ddb3139c1
