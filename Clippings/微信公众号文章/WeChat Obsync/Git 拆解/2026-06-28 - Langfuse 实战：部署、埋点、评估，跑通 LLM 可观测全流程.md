---
source_url: "https://mp.weixin.qq.com/s?search_click_id=10944039153882374254-1784128278145-2078877300&__biz=MzcwMTI5NTA2NA==&mid=2247485581&idx=1&sn=dbfb084f9ab61de7350647089636890d&chksm=f50550613727239e48a26f83b5343edf687e4ce403574e86476957f65c0e1cf63ae5023c911a&subscene=0&scene=7&clicktime=1784128278&enterid=1784128278&ascene=65&devicetype=iOS26.5.2&version=18004b3c&nettype=WIFI&abtest_cookie=AAACAA==&lang=zh_CN&countrycode=CN&fontScale=100&exportkey=n_ChQIAhIQJF2bQr4coNbUlruW/2F21hLhAQIE97dBBAEAAAAAABg7FXGQ4WUAAAAOpnltbLcz9gKNyK89dVj0fvv/eyJUh38kOp18NP8tbrn3UCkvdHvomfry6K/gG4sz8RQnjW71CrgoJ6sKkP273gjgDF716Mgt1nGGdm5JZHFd7AYirWGl+nBgRg2zWdb8IegvV0a/EyG3RvjJw5MOHVwpZ3l4tLLuuK4xYxF1S9f4U7hrln9/VN1ygM4RAado6M+DnWLDTAh995CPKBTMT6hslxXz9BweGiorVhqM5q7QR7XyOgWUpQ2/prD3VHaaU1U354u1r63Sdw==&pass_ticket=z+Jii4nnOl5R1hUCcPQIRQ9InItcLl/TABYmHPimKmrGINJ+EmLI/EfyGoeFBFiR&wx_header=3"
title: "Langfuse 实战：部署、埋点、评估，跑通 LLM 可观测全流程"
account: "Git 拆解"
published_at: "2026-06-28T04:09:00.000Z"
saved_at: "2026-07-15T15:11:25.641Z"
sync_id: "art_b45cc5048fcb43889d02a0a47e4b73c5"
parse_status: "ok"
---

# Langfuse 实战：部署、埋点、评估，跑通 LLM 可观测全流程

> 项目卡片 - 项目 ：Langfuse [1] - 状态 ：v3.178.0 / 28.5K Star / 月均 200+ commits - 一句话判断 ：目前最成熟的开源 LLM 可观测平台，从埋点到评估到 Prompt 管理形成闭环，自托管体验接近 SaaS。

LLM 应用上线后你会很快发现一件事：常规日志根本不够用。

agent 调了哪些工具、每步花了多少 token、用户的哪些输入触发了幻觉、改了 prompt 之后效果有没有变差——这些答案散落在各处 log 里，没有一个地方能看到全貌。

Langfuse 是目前开源方案里做得最完整的一个。我翻了它的仓库，从 tracing 到评估到 Prompt 版本管理，整套工作流都闭合了。本文不拆架构，只讲怎么用它——从部署到跑通第一个评估。

5 分钟部署一个自己的 Langfuse

Langfuse 支持云端和自托管两种方式。自托管用 Docker Compose，一条命令启动全部依赖：

```
git clone --depth=1 https://github.com/langfuse/langfuse.git
cd langfuse
docker compose up
```

![](附件资源/Langfuse%20实战：部署、埋点、评估，跑通%20LLM%20可观测全流程/img_1.png)

它会拉起 6 个服务：web（Next.js 应用）、worker（队列消费者）、PostgreSQL（元数据）、ClickHouse（trace 数据分析）、Redis（队列）、MinIO（S3 兼容存储）。首次启动后访问  `http://localhost:3000`  注册账号即可。

生产环境建议用官方 Helm Chart[2] 部署到 Kubernetes，或者用 Terraform 模板[3]一键拉起 AWS/Azure/GCP 基础设施。

关键的配置项就几个：

- DATABASE_URL ：PostgreSQL 连接串
- CLICKHOUSE_URL ：ClickHouse HTTP 地址
- SALT + ENCRYPTION_KEY ：用于加密 API Key，用 openssl rand -hex 32 生成
- REDIS_HOST / REDIS_AUTH ：Redis 连接信息

给你的 LLM 应用加埋点

Langfuse 的埋点方式分两种：**手动 SDK** 和 **框架自动集成**。如果你用的是 OpenAI SDK，最快的方式是 drop-in 替换——改一行 import 就行。

### OpenAI drop-in 替换

这是我试下来最快的方式——改一行 import，什么业务代码都不用动。

```
# 原来
from openai import OpenAI
client = OpenAI()

# 替换为
from langfuse.openai import OpenAI
client = OpenAI()
```

![](附件资源/Langfuse%20实战：部署、埋点、评估，跑通%20LLM%20可观测全流程/img_2.png)

替换后，所有  `client.chat.completions.create()`  调用自动上报到 Langfuse：输入、输出、token 用量、延迟、错误信息全部捕获。

初始化 SDK 只需要设置环境变量：

```
LANGFUSE_PUBLIC_KEY=pk-lf-...
LANGFUSE_SECRET_KEY=sk-lf-...
LANGFUSE_HOST=https://your-langfuse.example.com
```

这两个 Key 在 Langfuse 的 Project Settings → API Keys 页面创建。SDK 会在后台自动初始化，不需要在你的代码里显式调用任何 setup 函数。

### 用装饰器追踪自定义逻辑

对于 RAG pipeline、agent 链等复杂流程，用  `@observe()`  装饰器把自定义函数也纳入 trace：

```
from langfuse import observe

@observe()
def retrieve_documents(query: str) -> list:
docs = vector_store.similarity_search(query)
return docs

@observe()
def generate_answer(query: str, docs: list) -> str:
context = "\n".join([d.page_content for d in docs])
return client.chat.completions.create(
model="gpt-4o",
messages=[
{"role": "system", "content": f"Context:\n{context}"},
{"role": "user", "content": query}
]
).choices[0].message.content

@observe()
def rag_pipeline(query: str) -> str:
docs = retrieve_documents(query)
return generate_answer(query, docs)
```

![](附件资源/Langfuse%20实战：部署、埋点、评估，跑通%20LLM%20可观测全流程/img_3.png)

`@observe()`  会自动把函数调用链串联成一条完整的 trace。每个被装饰的函数成为 trace 中的一个 span，嵌套调用自动形成父子关系。在 Langfuse UI 里你可以看到整条链路的输入输出、执行顺序和耗时分布。

### LangChain / LlamaIndex 自动集成

如果你用 LangChain，传入 callback handler 即可：

```
from langfuse.callback import CallbackHandler

handler = CallbackHandler()
chain.invoke({"query": "hello"}, config={"callbacks": [handler]})
```

LlamaIndex 同理，通过 callback manager 接入。框架集成的完整列表在仓库 README 的 Integrations 表里，覆盖了 Vercel AI SDK、Haystack、DSPy、Mirascope 等主流选择。

用 Trace 数据做评估

埋点之后，Langfuse 的 trace 面板会记录每次调用的完整信息。但这些数据如果不做评估，就只是日志。

Langfuse 的评估系统支持三种方式：

![](附件资源/Langfuse%20实战：部署、埋点、评估，跑通%20LLM%20可观测全流程/img_4.png)

### LLM-as-a-Judge

让另一个 LLM 来评判你的输出质量。在 Langfuse 的 Evaluations 页面配置一个 evaluator，选择"LLM-as-a-Judge"类型，写一个评分 prompt 模板：

```
你是一个评审。请根据以下标准评判 AI 的回答：
- 是否回答了用户的问题
- 是否包含事实错误
- 回答是否简洁

用户问题：{{observation.input}}
AI 回答：{{observation.output}}

请打分（1-5）并说明理由。
```

Langfuse 会在 trace 数据上自动执行这个评分，结果汇总到 Score Analytics 面板。

### Code Evaluator

用自定义 Python 函数做精确评估，比如判断回答中是否包含关键词、是否满足格式要求：

```
def contains_citation(output, reference):
return 1 if reference in output else 0
```

### 人工标注

对于关键场景，支持手动打分 + 标注队列，适合需要人工复核的评估任务。

Prompt 版本管理

在生产环境改 prompt 是一件高风险的事。改了之后效果变差，你未必能第一时间发现。

![](附件资源/Langfuse%20实战：部署、埋点、评估，跑通%20LLM%20可观测全流程/img_5.png)

Langfuse 的 Prompt Management 把 prompt 当作代码来管理：

- 版本控制 ：每次修改自动生成新版本，可以回滚
- 标签系统 ：给版本打 production 、 staging 、 draft 标签
- 服务端缓存 ：prompt 改了之后客户端不用重新部署，SDK 自动拉取最新版本
- Playground 联动 ：在 trace 面板看到不好的输出，一键跳到 Playground 迭代

使用方式是在 Langfuse UI 的 Prompts 页面创建 prompt，然后用 SDK 按名称拉取：

```
from langfuse import Langfuse

langfuse = Langfuse()
prompt = langfuse.get_prompt("my-rag-system-prompt", label="production")
system_message = prompt.prompt
```

这比把 prompt 硬编码在代码里、改一次要发一次版要靠谱得多。

Datasets + Experiments：把评估流程化

![](附件资源/Langfuse%20实战：部署、埋点、评估，跑通%20LLM%20可观测全流程/img_6.png)

当你的评估不再是一锤子买卖，而是需要反复跑、对比不同 prompt 版本的效果，就需要 Datasets 和 Experiments。

**Dataset** 是一组测试用例——输入和期望输出的集合。你可以手动创建、从 trace 数据里挑选用例、或通过 API 批量导入。

**Experiment** 是在 Dataset 上跑评估的实验。你可以：

- 用不同 prompt 版本跑同一组测试用例
- 对比不同模型在相同数据集上的表现
- 自动计算平均分、通过率等指标

这个流程本质上就是给 LLM 应用做 CI/CD——改了 prompt，跑一轮 experiment，分数下降就回滚，上升就推到 production。如果是我自己用，prompt 上线前一定会过这一步。

MCP：让 AI Agent 查询你的 Trace 数据

Langfuse v3 新增了一个值得关注的功能——内置 MCP（Model Context Protocol）Server。这意味着 Claude、Cursor 这类 AI agent 可以直接查询你的 Langfuse 数据。

![](附件资源/Langfuse%20实战：部署、埋点、评估，跑通%20LLM%20可观测全流程/img_7.png)

配置方式：

```
# 生成 Basic Auth token
echo -n "pk-lf-xxx:sk-lf-xxx" | base64

# 添加 MCP server
claude mcp add --transport http langfuse \
http://localhost:3000/api/public/mcp \
--header "Authorization: Basic {base64-token}"
```

配置好后，你可以在 Claude 里直接问"帮我查今天 error 率最高的 5 条 trace"。Agent 通过 MCP 调用 Langfuse API 返回数据，不需要打开 UI 逐条翻。

部署前要知道的事

**双数据库架构**。元数据走 PostgreSQL，trace 数据走 ClickHouse。自托管最低建议 4C8G 内存，需要维护两个数据库。

**SDK 异步上报**。trace 数据先写本地内存队列，批量异步发送，不阻塞应用。网络中断时自动缓存、恢复后重传。

**MIT 协议**，核心功能完全开源。SSO、RBAC、审计日志等企业功能在  `ee/`  目录下，采用额外许可。如果你是个人或小团队，核心功能够用。

**数据在你自己手里**。这是自托管相比 SaaS 方案的根本优势——你的 prompt、trace、评估数据不经过第三方。

这里会继续拆真实可用的开发者工具：少讲概念，多看入口、成本和坑点。你只需要判断一件事——它值不值得放进自己的工作流。

### 引用链接

[1]Langfuse: _https://github.com/langfuse/langfuse_

[2]Helm Chart: _https://langfuse.com/self-hosting/kubernetes-helm_

[3]Terraform 模板: _https://langfuse.com/self-hosting_

---
原文链接：https://mp.weixin.qq.com/s?__biz=MzcwMTI5NTA2NA%3D%3D&mid=2247485581&idx=1&sn=dbfb084f9ab61de7350647089636890d&chksm=f50550613727239e48a26f83b5343edf687e4ce403574e86476957f65c0e1cf63ae5023c911a
