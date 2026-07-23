---
title: "LLM Trace字段定义说明"
source: "https://help.aliyun.com/zh/document_detail/3046157.html?spm=a2c4g.11186623.help-menu-3033820.d_6_0_1.d3b57a73kwrE6k"
author:
  - "阿里云计算"
published:
created: 2026-07-23
description: "AgentLoop 是阿里云推出的面向企业级智能体的一站式自进化平台，提供 Agent全栈观测与审计、Agent评估与实验、Agent资产管理与持续优化等核心能力，助力企业构建智能体进化数据飞轮，持续提升企业 Agent的质量、效率、成本与安全性。面向企业真实生产环境 Agent应用提供 Agent-as-a-Judge、Agent Playground、Trace2Dataset等 Agent应用范式的场景化闭环能力，让 Agent在生产环境中形成可观测、可评估、可优化的持续进化飞轮。"
tags:
  - "Clippings"
  - "AI可观测"
  - "阿里云"
  - "阿里云/AgentLoop"
  - "官方文档"
"word-count": "5402"
更新时间: "2026-07-13 11:19:03"
---
LLM Trace字段是阿里云参考OpenTelemetry标准以及大语言模型应用领域概念制定的，通过对Attributes、Resource、Event扩展用于描述LLM应用调用链数据的语义，能够反映LLM的输入输出请求、令牌消耗等关键操作。它们为Completion、Chat、RAG、Agent、Tool等场景提供了丰富的、语境相关的语义数据，以便于数据跟踪和上报。

此语义字段将随着社区的发展而不断更新和优化。若应用为 Python 应用，需自行手动采集可观测数据，您可以使用 [loongsuite-util-genai 组件](https://pypi.org/project/loongsuite-util-genai/)来帮助您完成数据的采集接入。详情参见 [README](https://github.com/alibaba/loongsuite-python-agent/blob/main/util/opentelemetry-util-genai/README-loongsuite.rst)。

Span一级字段定义参考OpenTelemetry开源标准，阿里云可观测链路 OpenTelemetry 版底层存储的Trace一级字段详细说明，请参见[调用链分析参数说明](https://help.aliyun.com/zh/arms/application-monitoring/developer-reference/trace-explorer-parameters#concept-2144432)。

**说明**

LLM相关的SpanKind是一个Attribute，不同于OpenTelemetry中Trace定义的[Span kind](https://opentelemetry.io/docs/concepts/signals/traces/#span-kind)。本语义规范在 [OpenTelemetry GenAI 语义规范](https://opentelemetry.io/docs/specs/semconv/gen-ai/)的基础上进行扩展，该规范在修改和完善当中，可能会在后续的维护中发生修改。

## **公共部分**

### **Attributes**

| **AttributeKey** | **Description** | **类型** | **示例值** | **需求等级** |
| --- | --- | --- | --- | --- |
| `gen_ai.session.id` | 会话ID | string | `ddde34343-f93a-4477-33333-sdfsdaf` | 有条件时必须 |
| `gen_ai.user.id` | 应用的C端用户标识 | string | `u-lK8JddD` | 有条件时必须 |
| `gen_ai.span.kind` | 操作类型 \\[1\\] | string | `参考LLM Span Kind` | 必须  |
| `gen_ai.operation.name` | 操作二级类型 \\[2\\] | string | `参考LLM Operation Name` | 必须  |
| `gen_ai.framework` | 使用的框架类型 | string | `langchain`;`llama_index` | 有条件时必须 |

**\[1\]**`**gen_ai.span.kind**`: 与`gen_ai.operation.name`的映射关系如下：

| `**gen_ai.span.kind**` | `**gen_ai.operation.name**` | **Description** |
| --- | --- | --- |
| RETRIEVER | `retrieval` | 文档召回 |
| LLM | `chat`;`generate_content`;`text_completion` | 模型调用 |
| EMBEDDING | `embeddings` | 嵌入  |
| TOOL | `execute_tool` | 工具调用 |
| AGENT | `create_agent`;`invoke_agent` | 智能体调用 |
| RERANKER | \\- | 重排序调用 |
| CHAIN | \\- | 链（调用单元） |
| TASK | \\- | 任务调用 |
| ENTRY | \\- | 入口调用标识 |
| STEP | \\- | ReAct轮次标识 |

**\[2\]**`**gen_ai.operation.name**`: 操作二级类型，应当来自于以下某个枚举，或者自定义一个其他的值：

| **Value** | **Description** |
| --- | --- |
| `chat` | 对话补全操作 |
| `create_agent` | 创建 GenAI 智能体操作 |
| `embeddings` | 词嵌入操作 |
| `execute_tool` | 调用工具操作 |
| `generate_content` | 多模态内容生成操作 |
| `invoke_agent` | 调用 GenAI 智能体操作 |
| `retrieval` | 文档召回操作 |
| `text_completion` | 文本补全操作 |

### **Resources**

| **ResourceKey** | **Description** | **类型** | **示例值** | **需求等级** |
| --- | --- | --- | --- | --- |
| `service.name` | 应用名称 | string | `test-easy-rag` | 必须  |
| `acs.cms.workspace` | 云监控Workspace | string | `arms-test` | 有条件时必须 |
| `acs.arms.service.id` | 云监控服务ID | string | `ggxw4lnjuz@b63ba5a1d60b517ae374f` | 有条件时必须 |
| `ali.trace.source` | 应用来源 | string | `mse-gateway`;`alb` | 有条件时必须 |
| `acs.arms.service.feature` | 应用特征 | string | `genai_app` | 必须 **说明** `**acs.arms.service.feature**` **= genai\\_app ，用于自动识别并标识为AI应用，在LLM或者Agent应用场景下必传。** |

## **Chain**

Chain是一种将LLM和其他多个组件连接在一起的工具，以实现复杂的任务，可能包含Retrieval、Embedding、LLM调用、还可以嵌套Chain等。

Span 命名应该为 `chain {chain_name}`，如果无法获取到 chain\_name，则命名为 chain。

**说明**

OpenTelemetry 社区尚未具备该类型 Span 的语义规范。当前 Chain Span 仅用于 LangChain 框架。

### **Attributes**

| **AttributeKey** | **Description** | **类型** | **Example** | **需求等级** |
| --- | --- | --- | --- | --- |
| `gen_ai.span.kind` | 操作类型 \\[1\\] | string | `CHAIN` | 必须  |
| `gen_ai.operation.name` | 操作二级类型 | string | `workflow`; `task` | 有条件时必须 |
| `input.value` | 输入内容 | string | `Who Are You!` | 推荐  |
| `output.value` | 返回内容 | string | `I am ChatBot` | 推荐  |
| `gen_ai.user.time_to_first_token` | 首包延迟 \\[2\\] | integer | 1000000 | 推荐  |

**\[1\]**`**gen_ai.span.kind**`: 大模型spanKind专用枚举，Chain中取值**必须**为 `CHAIN`。

**\[2\]**`**gen_ai.user.time_to_first_token**`: 代表一次提问的整体响应首包耗时，从服务端获取的用户请求到首包返回的时间，单位纳秒。

## **Retriever**

Retriever一般表示访问向量存储或者数据库获取数据,一般用于补充上下文内容提升LLM的响应的准确性以及效率。

`gen_ai.operation.name` 应该为 `retrieval`。当 `gen_ai.operation.name` 为`retrieval`时，可以将 `gen_ai.span.kind` 推断为 RETRIEVER。

Span 命名应该为 `{gen_ai.operation.name} {gen_ai.data_source.id}`，视特殊情况也可以有其他类型的命名格式。

### **Attributes**

| **AttributeKey** | **Description** | **类型** | **Example** | **需求等级** |
| --- | --- | --- | --- | --- |
| `gen_ai.span.kind` | 操作类型 \\[1\\] | string | `RETRIEVER` | 必须  |
| `gen_ai.operation.name` | 操作二级类型 \\[2\\] | string | `retrieval` | 必须  |
| `gen_ai.data_source.id` | 数据源唯一标识 \\[3\\] | string | `H7STPQYOND` | 有条件时必须 |
| `gen_ai.provider.name` | 大模型的提供商 | string | `openai` | 有条件时必须 |
| `gen_ai.request.model` | 请求中指定的模型名 | string | `gpt-4` | 有条件时必须 |
| `gen_ai.request.top_k` | 请求中指定的topK | float | `1.0` | 推荐  |
| `gen_ai.retrieval.documents` | 召回的文档列表 \\[4\\] | string | `[{"id": "doc_123","score": 0.95},{"id": "doc_456","score": 0.87},{"id": "doc_789","score": 0.82}]` | 可选  |
| `gen_ai.retrieval.query.text` | 检索内容短句 | string | `what is the topic in xxx?` | 可选  |

**\[1\]**`**gen_ai.span.kind**`: 大模型spanKind专用枚举，Retriever中取值**必须**为 `RETRIEVER`。

**\[2\]**`**gen_ai.operation.name**`: 操作二级类型。

**\[3\]**`**gen_ai.data_source.id**`: 数据源唯一ID，AI Agent 或 RAG 应用依赖的数据来源，可以是外部数据库、对象存储、文档集、网站或其他存储系统。

**\[4\]**`**gen_ai.retrieval.documents**`: 用于记录召回的文档列表。每个文档对象至少应包含以下属性：id（字符串）：文档的唯一标识符；score（双精度浮点数）：文档的相关性得分。

## **Reranker**

Reranker针对输入的多个文档结合提问内容判断相关性进行排序处理，可能返回TopK的文档作为LLM。

Span 命名应该为 `rerank {reranker.model_name}`，如果无法获取到 `reranker.model_name`，则命名为 rerank。

**说明**

OpenTelemetry 社区尚未具备该类型 Span 的语义规范。

### **Attributes**

| **AttributeKey** | **Description** | **类型** | **Example** | **需求等级** |
| --- | --- | --- | --- | --- |
| `gen_ai.span.kind` | 操作类型 \\[1\\] | string | `RERANKER` | 必须  |
| `reranker.query` | Reranker请求的入参 | string | `How to format timestamp?` | 可选  |
| `reranker.model_name` | Reranker所用的模型名 | string | `cross-encoder/ms-marco-MiniLM-L-12-v2` | 可选  |
| `reranker.top_k` | Reranker后的排名 | integer | `3` | 可选  |
| `reranker.input_document` | 输出文档相关的元数据\\[2\\] | string | `参考示例` | 必须  |
| `reranker.output_document` | 输出文档相关的元数据\\[3\\] | string | `参考示例` | 必须  |

**\[1\]**`**gen_ai.span.kind**`: 大模型spanKind专用枚举，Reranker中取值**必须**为 `RERANKER`。

**\[2\]**`**reranker.output_document**`: 重排序输入文档，JSON数组结构，metadata为文档的基本信息，包含路径，文件名以及来源等。

**\[3\]**`**reranker.output_document**`: 重排序输出文档，JSON数组结构，metadata为文档的基本信息，包含路径，文件名以及来源等。

## **LLM**

LLM标识大模型的调用/推理过程，例如基于SDK或OpenAPI请求不同的大模型进行推理或者文本生成等场景。

`gen_ai.operation.name` 应该为 `chat`,`generate_content`,`text_completion`之一。当 `gen_ai.operation.name` 为`chat`,`generate_content`,`text_completion`时，可以将 `gen_ai.span.kind` 推断为 LLM。

Span 命名应该为 `{gen_ai.operation.name} {gen_ai.request.model}`，视特殊情况也可以有其他类型的命名格式。

### **Attributes**

| **AttributeKey** | **Description** | **类型** | **Example** | **需求等级** |
| --- | --- | --- | --- | --- |
| `gen_ai.span.kind` | 操作类型 \\[1\\] | string | `LLM` | 必须  |
| `gen_ai.operation.name` | 操作二级类型 \\[2\\] | string | `chat`; `generate_content`; `text_completion` | 必须  |
| `gen_ai.provider.name` | 大模型的提供商 | string | `openai` | 必须  |
| `gen_ai.conversation.id` | 对话的唯一ID \\[3\\] | string | `conv_5j66UpCpwteGg4YSxUnt7lPY` | 有条件时必须 |
| `gen_ai.output.type` | LLM请求中指定的输出类型 \\[4\\] | string | `text`;`json`;`image`;`audio` | 有条件时必须 |
| `gen_ai.request.choice.count` | LLM请求中希望获得的候选生成数量 | int | `3` | 有条件且不为1时必须 |
| `gen_ai.request.model` | LLM请求中指定的模型名 | string | `gpt-4` | 必须  |
| `gen_ai.request.seed` | LLM请求中指定的seed | string | `gpt-4` | 有条件时必须 |
| `gen_ai.request.frequency_penalty` | LLM请求中设定的频率惩罚 | float | `0.1` | 推荐  |
| `gen_ai.request.max_tokens` | LLM请求中指定的最大token数 | integer | `100` | 推荐  |
| `gen_ai.request.presence_penalty` | LLM请求中设定的存在性惩罚 | float | `0.1` | 推荐  |
| `gen_ai.request.temperature` | LLM请求中指定的温度 | float | `0.1` | 推荐  |
| `gen_ai.request.top_p` | LLM请求中指定的topP | float | `1.0` | 推荐  |
| `gen_ai.request.top_k` | LLM请求中指定的topK | float | `1.0` | 推荐  |
| `gen_ai.request.stop_sequences` | LLM的终止序列 | string\\[\\] | `["stop"]` | 推荐  |
| `gen_ai.response.id` | LLM生成的唯一id | string | `chatcmpl-9J3uIL87gldCFtiIbyaOvTeYBRA3l` | 推荐  |
| `gen_ai.response.model` | LLM生成所使用的模型名 | string | `gpt-4-0613` | 推荐  |
| `gen_ai.response.finish_reasons` | LLM终止生成的原因 | string\\[\\] | `["stop"]` | 推荐  |
| `gen_ai.response.time_to_first_token` | 流式响应场景下的大模型自身的首包响应耗时 \\[5\\] | integer | `1000000` | 推荐  |
| `gen_ai.response.reasoning_time` | 推理模型的推理时间 \\[6\\] | integer | `1248` | 推荐  |
| `gen_ai.usage.input_tokens` | 输入使用的token数 | integer | `100` | 推荐  |
| `gen_ai.usage.output_tokens` | 输出使用的token数 | integer | `200` | 推荐  |
| `gen_ai.usage.total_tokens` | 使用的总token数 | integer | `300` | 推荐  |
| `gen_ai.usage.cache_creation.input_tokens` | 写入模型提供商缓存中的token数 \\[7\\] | integer | `25` | 推荐  |
| `gen_ai.usage.cache_read.input_tokens` | 从模型提供商缓存中读取出的token数 \\[8\\] | integer | `50` | 推荐  |
| `gen_ai.input.messages` | 模型输入内容 \\[9\\] | string | `[{"role": "user", "parts": [{"type": "text", "content": "Weather in Paris?"}]}, {"role": "assistant", "parts": [{"type": "tool_call", "id": "call_VSPygqKTWdrhaFErNvMV18Yl", "name":"get_weather", "arguments":{"location":"Paris"}}]}, {"role": "tool", "parts": [{"type": "tool_call_response", "id":" call_VSPygqKTWdrhaFErNvMV18Yl", "result":"rainy, 57°F"}]}]` | 可选  |
| `gen_ai.output.messages` | 模型输出内容 \\[10\\] | string | `[ { "role": "assistant", "parts": [ { "content": "Split into A(3), B(3), C(2). Weigh A vs B, then narrow down to the heavy group and weigh again.", "type": "reasoning" }, { "content": "Split into A(3), B(3), C(2).\\n- **Weigh 1:** A vs B → heavier side contains it; if balanced, it's in C\\n- **Weigh 2:** From the 3-ball group, weigh 1 vs 1 → heavier wins; if balanced, it's the 3rd. From C, weigh 1 vs 1 directly.", "type": "text" } ], "finish_reason": "end_turn" }]` | 可选  |
| `gen_ai.system_instructions` | system提示词的内容 \\[11\\] | string | `[{"type": "text", "content": "You are a helpful assistant"}]` | 可选  |
| `gen_ai.tool.definitions` | 工具定义列表 \\[12\\] | string | `[{"type":"function","name":"get_current_weather","description": "Get the current weather in a given location","parameters":{"type":"object","properties":{"location":{"type":"string","description":"The city and state, e.g. San Francisco, CA"},"unit": {"type":"string","enum":["celsius","fahrenheit"]}},"required":["location","unit"]}}]` | 可选  |
| `gen_ai.latency.time_in_model_prefill` | LLM推理的Prefill时间，单位纳秒 | integer | `1000` | 推荐  |
| `gen_ai.latency.time_in_model_decode` | LLM推理的Decode时间，单位纳秒 | integer | `1000` | 推荐  |
| `gen_ai.latency.time_in_model_inference` | LLM推理的推理时间，等于Prefill和Decode时间的和，单位纳秒 | integer | `1000` | 推荐  |
| `gen_ai.input.multimodal_metadata` | LLM输入内容中涉及的多模态数据 \\[13\\] | string\\[\\] | `[{"type":"uri","mime_type":"image/jpeg","uri":"sls://project/logstore/date/object","modality":"image"}]` | 推荐  |
| `gen_ai.output.multimodal_metadata` | LLM输出内容中涉及的多模态数据 \\[14\\] | string\\[\\] | `[{"type":"uri","mime_type":"image/jpeg","uri":"sls://project/logstore/date/object","modality":"image"}]` | 推荐  |

**\[1\]**`**gen_ai.span.kind**`: 大模型spanKind专用枚举，在LLM中取值**必须**为 `LLM`。

**\[2\]**`**gen_ai.operation.name**`: 操作二级类型。

**\[3\]**`**gen_ai.conversation.id**`: 会话的唯一ID，当埋点可以比较方便地获取会话的ID时**应该**采集。

**\[4\]**`**gen_ai.output.type**`: 当可以获取并且请求指定了类型（如指定了output format）时**应该**采集。取值应属于以下枚举，或自定义一个其他的值：

| **Value** | **Description** |
| --- | --- |
| `image` | 图片  |
| `json` | 具备一定格式的 JSON 对象 |
| `speech` | 语音  |
| `text` | 纯文本 |

**\[5\]**`**gen_ai.user.time_to_first_token**`: 代表一次提问的整体响应首包耗时，从服务端获取的用户请求到首包返回的时间，单位纳秒。

**\[6\]**`**gen_ai.response.reasoning_time**`: 代表响应reasoning过程的持续时长，单位毫秒。

**\[7\]**`**gen_ai.usage.cache_creation.input_tokens**`：该属性的值应该已经被包含在`gen_ai.usage.input_tokens`中。

**\[8\]**`**gen_ai.usage.cache_read.input_tokens**`：该属性的值应该已经被包含在`gen_ai.usage.input_tokens`中。

**\[9\]**`**gen_ai.input.messages**`: 用于记录LLM调用的输入内容，消息**必须**按照发送给模型或智能体的顺序提供。需遵循[gen\_ai.input.messages.json](https://github.com/open-telemetry/semantic-conventions/tree/main/docs/gen-ai)。

仅在 `OTEL_INSTRUMENTATION_GENAI_CAPTURE_MESSAGE_CONTENT` 开关开启的情况下采集。该开关默认开启。

**\[10\]**`**gen_ai.output.messages**`: 用于记录模型的输出内容，消息**必须**按照发送给模型或智能体的顺序提供。需遵循[gen\_ai.output.messages.json](https://github.com/open-telemetry/semantic-conventions/tree/main/docs/gen-ai)。

仅在 `OTEL_INSTRUMENTATION_GENAI_CAPTURE_MESSAGE_CONTENT` 开关开启的情况下采集。该开关默认开启。

**\[11\]**`**gen_ai.system_instructions**`: 用于单独记录system提示词内容/system指令内容。如果system提示词/system指令内容可以单独获取，则**应该**用该字段记录；如果system提示词/system指令内容是模型调用的一部分，应该记录在`gen_ai.input.messages`属性中。需遵循[gen\_ai.system\_instructions.json](https://github.com/open-telemetry/semantic-conventions/tree/main/docs/gen-ai)。

仅在 `OTEL_INSTRUMENTATION_GENAI_CAPTURE_MESSAGE_CONTENT` 开关开启的情况下采集。该开关默认开启。

**\[12\]**`**gen_ai.tool.definitions**`: 用于记录请求大模型时携带的工具定义。该属性可能会非常大，采集时默认可以仅采集"type"和"name"两个字段。其余字段仅在 `OTEL_INSTRUMENTATION_GENAI_CAPTURE_MESSAGE_CONTENT` 开关开启的情况下采集。该开关默认开启。

**\[13\]**`**gen_ai.input.multimodal_metadata**`: 用于汇总记录模型在输入内容中涉及的多模态数据，**仅**包含UriPart消息。需遵循[gen\_ai.input.messages.json](https://github.com/open-telemetry/semantic-conventions/tree/main/docs/gen-ai)。

仅在 `OTEL_INSTRUMENTATION_GENAI_CAPTURE_MESSAGE_CONTENT` 开关开启的情况下采集。该开关默认开启。

**\[14\]**`**gen_ai.output.multimodal_metadata**`: 用于汇总记录模型在输出内容中涉及的多模态数据，**仅**包含UriPart消息。需遵循[gen\_ai.output.messages.json](https://github.com/open-telemetry/semantic-conventions/tree/main/docs/gen-ai)。

仅在 `OTEL_INSTRUMENTATION_GENAI_CAPTURE_MESSAGE_CONTENT` 开关开启的情况下采集。该开关默认开启。

### **记录指令、输入和输出**

用户输入和模型响应可以不记录、记录在 span 的 attributes 中或者作为 events（即 logs）记录下来。详情请参考[控制 LLM 应用对话历史采集行为](https://help.aliyun.com/zh/arms/application-monitoring/developer-reference/control-historical-dialog-collection-of-llm-applications)。

## **Embedding**

Embedding标识一次嵌入处理，例如针对文本嵌入大模型的操作，后续可以根据相似度查询优化问题。

`gen_ai.operation.name` 应该为 `embeddings`。当 `gen_ai.operation.name` 为`embeddings`时，可以将 `gen_ai.span.kind` 推断为 EMBEDDING。

Span 命名应该为 `{gen_ai.operation.name} {gen_ai.request.model}`，视特殊情况也可以有其他类型的命名格式。

### **Attributes**

| **AttributeKey** | **Description** | **类型** | **Example** | **需求等级** |
| --- | --- | --- | --- | --- |
| `gen_ai.span.kind` | 操作类型 \\[1\\] | string | `EMBEDDING` | 必须  |
| `gen_ai.operation.name` | 操作二级类型 \\[2\\] | string | `embeddings` | 必须  |
| `gen_ai.provider.name` | 大模型的提供商 | string | `openai` | 必须  |
| `gen_ai.request.model` | 请求中指定的模型名 | string | `gpt-4` | 有条件时必须 |
| `gen_ai.embeddings.dimension.count` | Embedding操作所应具备的维度数 | integer | `1024` | 推荐  |
| `gen_ai.request.encoding_formats` | 嵌入操作中请求的编码格式 | string\\[\\] | `["base64"]`; `["float", "binary"]` | 推荐  |
| `gen_ai.usage.input_tokens` | 输入文本的token消耗 | integer | `10` | 可选  |
| `gen_ai.usage.total_tokens` | Embedding的token总消耗 | integer | `10` | 可选  |

**\[1\]**`**gen_ai.span.kind**`: 大模型spanKind专用枚举，Embedding中取值**必须**为 `EMBEDDING`。

**\[2\]**`**gen_ai.operation.name**`: 操作二级类型。

## **Tool**

Tool标识对外部工具的调用，例如可能调用计算器或者请求天气API获取最新的天气情况。

`gen_ai.operation.name` 应该为 `execute_tool`。当 `gen_ai.operation.name` 为`execute_tool`时，可以将 `gen_ai.span.kind` 推断为 TOOL。

Span 命名应该为 `{gen_ai.operation.name} {gen_ai.tool.name}`，视特殊情况也可以有其他类型的命名格式。

当工具执行表示将 Skill 加载到上下文中时，应设置 `gen_ai.skill.*` 相关字段。常见场景包括 `load_skill`、`read_skill` 或类似含义的工具调用。

### **Attributes**

| **AttributeKey** | **Description** | **类型** | **Example** | **需求等级** |
| --- | --- | --- | --- | --- |
| `gen_ai.span.kind` | 操作类型 \\[1\\] | string | `TOOL` | 必须  |
| `gen_ai.operation.name` | 操作二级类型 \\[2\\] | string | `execute_tool` | 必须  |
| `gen_ai.tool.call.id` | 工具 id | string | `call_mszuSIzqtI65i1wAUOE8w5H4` | 推荐  |
| `gen_ai.tool.description` | 工具描述 | string | `Multiply two numbers` | 推荐  |
| `gen_ai.tool.name` | 工具名称 | string | 推荐  |     |
| `gen_ai.tool.type` | 工具类型 | string | `function`;`extension`;`datastore` | 推荐  |
| `gen_ai.skill.id` | GenAI Skill 的唯一标识 | string | `skill_29bbe8a7` | 加载 Skill 时有条件必须 |
| `gen_ai.skill.name` | GenAI Skill 名称 | string | `code_review`;`change_workitem` | 加载 Skill 时有条件必须 |
| `gen_ai.skill.description` | 应用提供的 GenAI Skill 自由文本描述 | string | `Execute code review on GitHub repositories` | 推荐  |
| `gen_ai.skill.version` | GenAI Skill 版本 | string | `0.2.0`;`v2.1.0` | 推荐  |
| `gen_ai.tool.call.arguments` | 工具调用入参 \\[2\\] | string | `{"location": "San Francisco?","date": "2025-10-01"}` | 可选  |
| `gen_ai.tool.call.result` | 工具调用返回值 \\[3\\] | string | `{"temperature_range": {"high": 75,"low": 60},"conditions": "sunny"}` | 可选  |

**\[1\]**`**gen_ai.span.kind**`: 大模型spanKind专用枚举，Tool中取值**必须**为 `TOOL`。

**\[2\]**`**gen_ai.tool.call.arguments**`: 工具调用入参，为一个 json 字符串。 仅在 `OTEL_INSTRUMENTATION_GENAI_CAPTURE_MESSAGE_CONTENT` 开关开启的情况下采集。该开关默认开启。

**\[3\]**`**gen_ai.tool.call.result**`: 工具调用返回值，为一个 json 字符串。 仅在 `OTEL_INSTRUMENTATION_GENAI_CAPTURE_MESSAGE_CONTENT` 开关开启的情况下采集。该开关默认开启。

## **Agent**

Agent表示智能体场景，一种更复杂的CHAIN，需要基于大模型的推理结果决策执行下一步，例如可能涉及到LLM以及Tool的多次调用，一步步决策得出最终答案。

`gen_ai.operation.name` 应该为 `invoke_agent`,`create_agent`之一。当 `gen_ai.operation.name` 为`invoke_agent`,`create_agent`时，可以将 `gen_ai.span.kind` 推断为 AGENT。

Span 命名应该为 `{gen_ai.operation.name} {gen_ai.agent.name}`，视特殊情况也可以有其他类型的命名格式。

### **Attributes**

| **AttributeKey** | **Description** | **类型** | **Example** | **需求等级** |
| --- | --- | --- | --- | --- |
| `gen_ai.span.kind` | 操作类型 \\[1\\] | string | `AGENT` | 必须  |
| `gen_ai.operation.name` | 操作二级类型 \\[2\\] | string | `invoke_agent`; `create_agent` | 必须  |
| `gen_ai.conversation.id` | 对话的唯一ID \\[3\\] | string | `conv_5j66UpCpwteGg4YSxUnt7lPY` | 有条件时必须 |
| `gen_ai.agent.description` | Agent描述 | string | `Helps with math problems`; `Generates fiction stories` | 有条件时必须 |
| `gen_ai.agent.id` | Agent唯一标识 | string | `asst_5j66UpCpwteGg4YSxUnt7lPY` | 有条件时必须 |
| `gen_ai.agent.name` | Agent名称 | string | `Math Tutor`; `Fiction Writer` | 有条件时必须 |
| `gen_ai.data_source.id` | 数据源唯一标识 \\[4\\] | string | `H7STPQYOND` | 有条件时必须 |
| `gen_ai.usage.input_tokens` | 输入使用的token数 | integer | `100` | 推荐  |
| `gen_ai.usage.output_tokens` | 输出使用的token数 | integer | `200` | 推荐  |
| `gen_ai.usage.total_tokens` | 使用的总token数 | integer | `300` | 推荐  |
| `gen_ai.usage.cache_creation.input_tokens` | 写入模型提供商缓存中的token数 \\[5\\] | integer | `25` | 推荐  |
| `gen_ai.usage.cache_read.input_tokens` | 从模型提供商缓存中读取出的token数 \\[6\\] | integer | `50` | 推荐  |
| `gen_ai.input.messages` | 模型输入内容 \\[7\\] | string | `[{"role": "user", "parts": [{"type": "text", "content": "Weather in Paris?"}]}, {"role": "assistant", "parts": [{"type": "tool_call", "id": "call_VSPygqKTWdrhaFErNvMV18Yl", "name":"get_weather", "arguments":{"location":"Paris"}}]}, {"role": "tool", "parts": [{"type": "tool_call_response", "id":" call_VSPygqKTWdrhaFErNvMV18Yl", "result":"rainy, 57°F"}]}]` | 可选  |
| `gen_ai.output.messages` | 模型输出内容 \\[8\\] | string | `[{"role":"assistant","parts":[{"type":"text","content":"The weather in Paris is currently rainy with a temperature of 57°F."}],"finish_reason":"stop"}]` | 可选  |
| `gen_ai.system_instructions` | system提示词的内容 \\[9\\] | string | `[{"type": "text", "content": "You are a helpful assistant"}]` | 可选  |
| `gen_ai.tool.definitions` | 工具定义列表 \\[10\\] | string | `[{"type":"function","name":"get_current_weather","description": "Get the current weather in a given location","parameters":{"type":"object","properties":{"location":{"type":"string","description":"The city and state, e.g. San Francisco, CA"},"unit": {"type":"string","enum":["celsius","fahrenheit"]}},"required":["location","unit"]}}]` | 可选  |
| `gen_ai.response.time_to_first_token` | Agent的首包响应耗时 | integer | `1000000` | 推荐  |

**\[1\]**`**gen_ai.span.kind**`: 大模型spanKind专用枚举，Agent中取值**必须**为 `AGENT`。

**\[2\]**`**gen_ai.operation.name**`: 操作二级类型。

**\[3\]**`**gen_ai.conversation.id**`: 会话的唯一ID，当埋点可以比较方便地获取会话的ID时**应该**采集。

**\[4\]**`**gen_ai.data_source.id**`: 数据源唯一ID，AI Agent 或 RAG 应用依赖的数据来源，可以是外部数据库、对象存储、文档集、网站或其他存储系统。

**\[5\]**`**gen_ai.usage.cache_creation.input_tokens**`：该属性的值应该已经被包含在`gen_ai.usage.input_tokens`中。

**\[6\]**`**gen_ai.usage.cache_read.input_tokens**`：该属性的值应该已经被包含在`gen_ai.usage.input_tokens`中。

**\[7\]**`**gen_ai.input.messages**`: 用于记录LLM调用的输入内容，消息**必须**按照发送给模型或智能体的顺序提供。需遵循[gen\_ai.input.messages.json](https://github.com/open-telemetry/semantic-conventions/tree/main/docs/gen-ai)。

仅在 `OTEL_INSTRUMENTATION_GENAI_CAPTURE_MESSAGE_CONTENT` 开关开启的情况下采集。该开关默认开启。

**\[8\]**`**gen_ai.output.messages**`: 用于记录模型的输出内容，消息**必须**按照发送给模型或智能体的顺序提供。需遵循[gen\_ai.output.messages.json](https://github.com/open-telemetry/semantic-conventions/tree/main/docs/gen-ai)。

仅在 `OTEL_INSTRUMENTATION_GENAI_CAPTURE_MESSAGE_CONTENT` 开关开启的情况下采集。该开关默认开启。

**\[9\]**`**gen_ai.system_instructions**`: 用于单独记录system提示词内容/system指令内容。如果system提示词/system指令内容可以单独获取，则**应该**用该字段记录；如果system提示词/system指令内容是模型调用的一部分，应该记录在`gen_ai.input.messages`属性中。需遵循[gen\_ai.system\_instructions.json](https://github.com/open-telemetry/semantic-conventions/tree/main/docs/gen-ai)。

仅在 `OTEL_INSTRUMENTATION_GENAI_CAPTURE_MESSAGE_CONTENT` 开关开启的情况下采集。该开关默认开启。

**\[10\]**`**gen_ai.tool.definitions**`: 用于记录请求大模型时携带的工具定义。该属性可能会非常大，采集时默认可以仅采集"type"和"name"两个字段。其余字段仅在 `OTEL_INSTRUMENTATION_GENAI_CAPTURE_MESSAGE_CONTENT` 开关开启的情况下采集。该开关默认开启。

## **Task**

Task标识一次内部自定义方法，例如可能调用本地的某个function等应用自定义的逻辑。

Span 命名应该为 `run_task {gen_ai.task.name}`，视特殊情况也可以有其他类型的命名格式。

**说明**

OpenTelemetry 社区尚未具备该类型 Span 的语义规范，因此 `gen_ai.operation.name` 可能还会有变化。

### **Attributes**

| **AttributeKey** | **Description** | **类型** | **Example** | **需求等级** |
| --- | --- | --- | --- | --- |
| `gen_ai.span.kind` | 操作类型 \\[1\\] | string | `TASK` | 必须  |
| `gen_ai.operation.name` | 操作二级类型 | string | `run_task` | 必须  |
| `input.value` | 输入参数 | string | `输入参数,自定义json格式` | 可选  |
| `input.mime_type` | 输入MimeType | string | `text/plain`; `application/json` | 可选  |
| `output.mime_type` | 输出MimeType | string | `text/plain`; `application/json` | 可选  |

**\[1\]**`**gen_ai.span.kind**`: 大模型spanKind专用枚举，Task中取值**必须**为 `TASK`。

## **Entry**

Entry标识一次对AI应用系统的调用入口。

Span 命名应该为 `enter_ai_application_system`，视特殊情况也可以有其他类型的命名格式。

**说明**

OpenTelemetry 社区尚未具备该类型 Span 的语义规范，因此 `gen_ai.operation.name` 可能还会有变化。

### **Attributes**

| **AttributeKey** | **Description** | **类型** | **Example** | **需求等级** |
| --- | --- | --- | --- | --- |
| `gen_ai.span.kind` | 操作类型 \\[1\\] | string | `ENTRY` | 必须  |
| `gen_ai.operation.name` | 操作二级类型 | string | `enter` | 推荐  |
| `gen_ai.session.id` | 会话ID | string | `ddde34343-f93a-4477-33333-sdfsdaf` | 有条件时必须 |
| `gen_ai.user.id` | 应用的C端用户标识 | string | `u-lK8JddD` | 有条件时必须 |
| `gen_ai.input.messages` | 模型输入内容 \\[2\\] | string | `[{"role": "user", "parts": [{"type": "text", "content": "Weather in Paris?"}]}, {"role": "assistant", "parts": [{"type": "tool_call", "id": "call_VSPygqKTWdrhaFErNvMV18Yl", "name":"get_weather", "arguments":{"location":"Paris"}}]}, {"role": "tool", "parts": [{"type": "tool_call_response", "id":" call_VSPygqKTWdrhaFErNvMV18Yl", "result":"rainy, 57°F"}]}]` | 可选  |
| `gen_ai.output.messages` | 模型输出内容 \\[3\\] | string | `[{"role":"assistant","parts":[{"type":"text","content":"The weather in Paris is currently rainy with a temperature of 57°F."}],"finish_reason":"stop"}]` | 可选  |
| `gen_ai.response.time_to_first_token` | 流式响应场景下的首包响应耗时 \\[4\\] | integer | `1000000` | 推荐  |

**\[1\]**`**gen_ai.span.kind**`: 大模型spanKind专用枚举，Entry中取值**必须**为 `ENTRY`。

**\[2\]**`**gen_ai.input.messages**`: 用于记录LLM调用的输入内容，消息**必须**按照发送给模型或智能体的顺序提供。需遵循[gen\_ai.input.messages.json](https://github.com/open-telemetry/semantic-conventions/tree/main/docs/gen-ai)。

仅在 `OTEL_INSTRUMENTATION_GENAI_CAPTURE_MESSAGE_CONTENT` 开关开启的情况下采集。该开关默认开启。

**\[3\]**`**gen_ai.output.messages**`: 用于记录模型的输出内容，消息**必须**按照发送给模型或智能体的顺序提供。需遵循[gen\_ai.output.messages.json](https://github.com/open-telemetry/semantic-conventions/tree/main/docs/gen-ai)。

仅在 `OTEL_INSTRUMENTATION_GENAI_CAPTURE_MESSAGE_CONTENT` 开关开启的情况下采集。该开关默认开启。

**\[4\]**`**gen_ai.response.time_to_first_token**`: 代表一次提问的整体响应首包耗时，从服务端获取的用户请求到首包返回的时间，单位纳秒。

## **ReAct Step**

Step调用标识Agent的一次Reasoning-Acting迭代的过程。

Span 命名应该为 `react step`，视特殊情况也可以有其他类型的命名格式。

**说明**

OpenTelemetry 社区尚未具备该类型 Span 的语义规范，因此 `gen_ai.operation.name` 可能还会有变化。

### **Attributes**

| **AttributeKey** | **Description** | **类型** | **Example** | **需求等级** |
| --- | --- | --- | --- | --- |
| `gen_ai.span.kind` | 操作类型 \\[1\\] | string | `STEP` | 必须  |
| `gen_ai.operation.name` | 操作二级类型 | string | `react` | 推荐  |
| `gen_ai.react.finish_reason` | 本轮ReAct结束的原因 | string | `error` | 推荐  |
| `gen_ai.react.round` | 本轮ReAct的轮次号 \\[2\\] | integer | `1` | 推荐  |

**\[1\]**`**gen_ai.span.kind**`: 大模型spanKind专用枚举，ReAct Step中取值**必须**为 `STEP`。

**\[2\]**`**gen_ai.react.round**`: ReAct的轮次号建议从1开始计数，每次迭代自增1。