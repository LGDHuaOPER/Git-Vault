---
source_url: "https://mp.weixin.qq.com/s?__biz=MzI5MTcwMzQ5Ng%3D%3D&mid=2247484014&idx=1&sn=1ebd7fd29dd45b1441c29333433afdfb&chksm=ec0dddc9db7a54dff76b71c63992cb4bb82d1d70763957f395457b2dfe202c4657b2d0543d2a"
title: "从 OpenTelemetry 到 Langfuse：企业级 Agent 可观测性实践"
account: "AI渐渐"
published_at: "2026-09-29 23:15:32"
saved_at: "2026-09-30 01:13:30"
sync_id: "art_6c2aa9da17644b5db344c0667fa39c82"
parse_status: "ok"
---

# 从 OpenTelemetry 到 Langfuse：企业级 Agent 可观测性实践

## 一、从 OTel 到 Langfuse

前阵子分享了 OpenTelemetry 的技术文章（[链接](https://mp.weixin.qq.com/s?__biz=MzI5MTcwMzQ5Ng==&mid=2247483996&idx=1&sn=7ade288a853a3e512ea856310de610fb&scene=21#wechat_redirect)），讲的是怎么把 Agent 的 trajectory 记录成一棵 Trace 树。 OTel 基本是 Agent 轨迹监控的基石：它定义了一套标准的数据模型，后面很多可观测性工具和 Agent 框架，都是在它之上做迭代。

这一篇接着往下讲，把 Langfuse 这个企业级的 Agent 监控应用，从技术实现到落地实践完整展开一遍，年初也写过一篇关于 Langfuse 的文章（[链接](https://mp.weixin.qq.com/s?__biz=MzI5MTcwMzQ5Ng==&mid=2247483663&idx=1&sn=9250cb9120a51776bb348c51debb8e4b&scene=21#wechat_redirect)），感兴趣的可以前往阅读。

### 1.1 OTel 和 Langfuse 的关系

一句话概括：OTel 负责「怎么标准化记录」，Langfuse 负责「怎么把记录理解成 Agent 能分析的样子」。

```
OpenTelemetry    → Agent 执行记录成通用 Trace / Span

Langfuse         → 在它的基础上补 Agent 语义，并做分析
```

而且 Langfuse 本身就是基于 OTel 实现的。

### 1.2 Langfuse 的定位

Langfuse 是一个面向 LLM / Agent 应用的可观测性与分析平台。它把 OTel 的通用 span 转换成带 Agent 语义的 observation（LLM 调用、工具调用、Agent 决策），并在 trace 上挂上 session、user、score 这些分析维度。

回到一次具体的 Agent 执行。OTel 能告诉你哪一步慢、哪一步报错、调用层级是什么。但对一个 LLM / Agent 应用，真正想知道的往往是另一批信息：

```
第一次 LLM 的输入是什么、输出是什么

为什么决定调用这个 Tool

Tool 的参数和返回分别是什么

每一步用了多少 Token、花了多少钱

这次会话整体效果怎么样、属于哪个用户
```

OTel 的 span 知道「这是一次调用、耗时 50ms」，但不知道「这是一次 LLM 调用，用了 n 个 token，成本 m 」。这些字段属于 Agent 语义，要么自己定义，要么交给上层平台。

Langfuse 的核心作用就是把这层补齐：

- OTel 原生 ：能直接接收 OTel 的 OTLP 数据，已有的埋点可以复用；
- Agent 视角开箱即用 ：generation / tool / agent 分类型展示，token、成本、会话面板自动渲染；
- 开源可自建 ：支持私有化部署，数据不出内网；
- 不止 tracing ：还涵盖评估（Evaluation）、Prompt 管理、数据集与实验。

## 二、核心原理

### 2.1 Langfuse

Langfuse 不是另一套 Trace 系统，底层核心还是基于 OpenTelemetry 实现的。

具体表现为三点：

- 一次请求在 Langfuse 里的 Trace ID，和 OTel 的  `trace_id`  是同一个值；
- Langfuse 里的一个 Observation ，就是 OTel 的一个 span 在 Langfuse 侧的表示；
- Langfuse 还能直接作为 OTel 后端使用——把 exporter 指向它的 OTLP 端点，原生 OTel 的 span 也能进 Langfuse。

### 2.2 Observation Type

OTel 的 span 只有通用类型；Langfuse 给它补上了类型标签，也就是  `as_type` ：

```
span         通用步骤（非 LLM 操作）
generation   LLM 调用，额外带 model / token / cost
tool         工具调用，带输入输出
agent        能自主决策、调用工具的执行单元
chain        多个步骤之间的衔接
embedding    生成向量
guardrail    内容防护、越狱检测
```

 `generation`  是其中最关键的一类。它不是「多了一种 span」，而是在 span 上固定了一组 LLM 专属字段：

```
model              用的哪个模型
input / output     发给模型的和模型返回的
usage_details      输入 / 输出 token 数
cost_details       本次调用的成本
```

有了这组字段，token 统计、成本计算、模型对比这些，Langfuse 的 Dashboard 能自动渲染。

### 2.3 Trace 级维度

Agent 的效果往往要跨多次请求看，所以 Langfuse 在 trace 上挂了几个聚合维度：

```
session_id   把同一个会话的多轮请求归到一起
user_id      关联到具体用户
tags         自定义分类标签
score        人工或自动评估的结果
```

前面的 Observation Type 解决「单次执行看到了什么」，这几个维度解决「多次执行放在一起怎么比较」。

### 2.4 数据结构

把同一个 Agent 的数据分别送进 Jaeger 和 Langfuse，形状是一样的都是树状，能回答的问题不同。

Jaeger 面向系统：

```
哪里慢、哪里报错、调用链是什么、服务之间怎么调用
```

Langfuse 面向 Agent：

```
模型到底说了什么、为什么调用这个 Tool、Tool 返回了什么

用了多少 Token、这次请求花了多少钱

不同 Model / Prompt 的效果对比、某个 Session 的整体体验
```

两者的关注点可以概括成：

```
OpenTelemetry → 系统发生了什么

Langfuse      → Agent 做了什么、效果怎么样
```

## 三、编码实现

下面用一个真实的  `LLM → Tool → LLM`  链路对比，不用单次函数调用，因为多步结构才能体现差异。

### 3.1 Agent 本身

原生没有可观测性的 Agent：

```
class ProductAgent:

    name = "product-agent"

    def __init__(self, llm, search_tool):
        self.llm = llm
        self.search_tool = search_tool

    def run(self, query):

        # 第一次 LLM：理解需求，决定是否调用 Tool
        response = self.llm.chat(
            messages=[
                {"role": "system", "content": "你是电商商品助手，需要时调用商品搜索工具。"},
                {"role": "user", "content": query},
            ],
            tools=[self.search_tool],
        )

        if response.tool_calls:
            tool_call = response.tool_calls[0]

            # 执行 Tool
            products = self.search_tool(**tool_call.arguments)

            # 第二次 LLM：根据 Tool 结果生成最终回答
            return self.llm.chat(
                messages=[
                    {"role": "user", "content": query},
                    {"role": "assistant", "tool_calls": [tool_call]},
                    {"role": "tool", "content": products},
                ]
            )

        return response
```

执行链路：

```
User → LLM → Tool → LLM → Answer
```

### 3.2 原生 OpenTelemetry

OTel 只提供通用 span，所以 LLM、Tool 的语义和字段都要自己定义：

```
with tracer.start_as_current_span("product-agent"):

    with tracer.start_as_current_span("llm") as span:
        response = llm.chat(...)
        span.set_attribute("gen_ai.request.model", "claude-haiku-4-5")
        span.set_attribute("gen_ai.usage.input_tokens", response.usage.input_tokens)
        span.set_attribute("output.value", response.content)

    with tracer.start_as_current_span("search-product") as span:
        products = search_tool(**tool_call.arguments)
        span.set_attribute("tool.name", "search_product")
        span.set_attribute("tool.arguments", str(tool_call.arguments))
        span.set_attribute("output.value", str(products))

    with tracer.start_as_current_span("llm") as span:
        final_response = llm.chat(...)
        span.set_attribute("output.value", final_response.content)
```

得到的树：

```
product-agent
├── llm
├── search-product
└── llm
```

结构没问题，耗时和父子关系都能看。但有一批东西需要应用自己建设：

```
这是 Agent 还是普通 span？
这是 LLM 调用还是普通 span？
Token 怎么统一统计？
Cost 怎么算？
Session、User 怎么关联？
Evaluation 挂在哪？
最终这些字段怎么渲染成面板？
```

OTel 提供的是最标准和最基础能力，这些 Agent 专项能力需要自己编码实现。

### 3.3 Langfuse

同一个 Agent，用 Langfuse SDK 写：

```
from langfuse import get_client

langfuse = get_client()

with langfuse.start_as_current_observation(
    as_type="agent", name="product-agent"
):
    with langfuse.start_as_current_observation(
        as_type="generation", name="understand-query", model="claude-haiku-4-5"
    ) as generation:
        response = llm.chat(...)
        generation.update(
            input=query,
            output=response.content,
            usage_details={
                "input": response.usage.input_tokens,
                "output": response.usage.output_tokens,
            },
        )

    with langfuse.start_as_current_observation(
        as_type="tool", name="search-product"
    ) as tool:
        products = search_tool(**tool_call.arguments)
        tool.update(input=tool_call.arguments, output=products)

    with langfuse.start_as_current_observation(
        as_type="generation", name="generate-answer", model="claude-haiku-4-5"
    ) as generation:
        final_response = llm.chat(...)
        generation.update(
            input=products,
            output=final_response.content,
            usage_details={
                "input": final_response.usage.input_tokens,
                "output": final_response.usage.output_tokens,
            },
        )
```

代码结构和 OTel 几乎一样，仍然是「开 observation → 做事 → 更新字段」。差别在于：

-  `as_type`  直接声明这是  `agent`  /  `generation`  /  `tool`  ，平台能识别并按类型渲染；
-  `generation`  自带  `model`  、  `usage_details`  ，token 和成本自动算；
-  `input`  /  `output`  是固定字段，模型到底说了什么一眼可见。

![](附件资源/从%20OpenTelemetry%20到%20Langfuse：企业级%20Agent%20可观测性实践/img_1.png)

如果还想把多轮会话和用户关联起来，加一层 trace 级属性即可：

```
from langfuse import propagate_attributes

with propagate_attributes(user_id="u_123", session_id="s_abc"):
    agent.run(query)
```

同一个会话的多轮请求会自动归到  `s_abc`  下，面板上就能按 session 看整体效果。

## 四、实践落地

### 4.1 痛点问题

单个 Agent 直接写  `with langfuse...`  没问题。但企业里业务场景一般都需要 Multi-Agent 架构：

```
MasterAgent
├── ProductAgent
├── OrderAgent
├── RecommendAgent
├── QAAgent
└── AfterSaleAgent
```

如果每个 Agent 都手写 Langfuse，业务代码会变得繁琐冗余：

```
业务逻辑 + Langfuse + 异常处理 + Trace 管理 + Metrics + Logging
```

一旦要改字段规范、换后端、加采样，就要修改每个 Agent 代码。

### 4.2 定义 BaseAgent 基类

第三章的埋点直接写在执行流程里，业务和可观测性混在一起。第一反应是抽一个基类，把 agent 级的 observation 提到父类：

```
class BaseAgent:

    name = "base-agent"

    def run(self, query):
        with langfuse.start_as_current_observation(
            as_type="agent", name=self.name
        ):
            return self.execute(query)

class ProductAgent(BaseAgent):

    name = "product-agent"

    def __init__(self, llm, search_tool):
        self.llm = llm
        self.search_tool = search_tool

    def execute(self, query):
        # 第一次 LLM：理解需求，决定是否调用 Tool
        response = self.llm.chat(
            messages=[
                {"role": "system", "content": "你是电商商品助手，需要时调用商品搜索工具。"},
                {"role": "user", "content": query},
            ],
            tools=[self.search_tool],
        )

        if response.tool_calls:
            tool_call = response.tool_calls[0]

            # 执行 Tool
            products = self.search_tool(**tool_call.arguments)

            # 第二次 LLM：根据 Tool 结果生成最终回答
            return self.llm.chat(
                messages=[
                    {"role": "user", "content": query},
                    {"role": "assistant", "tool_calls": [tool_call]},
                    {"role": "tool", "content": products},
                ]
            )

        return response
```

业务 Agent 里已经看不到 langfuse，剩下的全是业务。agent 级的 observation 由基类统一开；内部的 generation / tool observation 由 LLM client 和工具包装统一产生——包装一次，所有 Agent 共用。

但基类的问题也很直接。它只管住了 agent 这一层，其他横切能力如果也往基类里塞：

```
BaseAgent
├── Langfuse
├── Logging
├── Retry
├── Timeout
├── Metrics
├── Guardrail
└── Cache
```

一个 Agent 想加只属于自己的能力，就得改基类，影响所有子类。

### 4.3 Middleware & Hook

更合适的做法是不靠继承，用一个 Runner 在运行时给 Agent 包一层 Middleware：

> Agent 只负责业务，Middleware 负责横切能力。

ProductAgent 不再继承 BaseAgent：

```
class ProductAgent:

    name = "product-agent"

    def __init__(self, llm, search_tool):
        self.llm = llm
        self.search_tool = search_tool

    def run(self, query):
        response = self.llm.chat(
            messages=[
                {"role": "system", "content": "你是电商商品助手，需要时调用商品搜索工具。"},
                {"role": "user", "content": query},
            ],
            tools=[self.search_tool],
        )

        if response.tool_calls:
            tool_call = response.tool_calls[0]
            products = self.search_tool(**tool_call.arguments)
            return self.llm.chat(
                messages=[
                    {"role": "user", "content": query},
                    {"role": "assistant", "tool_calls": [tool_call]},
                    {"role": "tool", "content": products},
                ]
            )

        return response
```

Middleware 只做一件事，包一层 observation：

```
class LangfuseMiddleware:

    def __init__(self, langfuse):
        self.langfuse = langfuse

    def __call__(self, agent, query, next):
        with self.langfuse.start_as_current_observation(
            as_type="agent", name=agent.name
        ):
            return next()
```

Runner 在运行时把中间件串起来：

```
runner = AgentRunner(middlewares=[LangfuseMiddleware(langfuse)])

runner.run(ProductAgent(llm, search_tool), query)
```

执行过程：

![](附件资源/从%20OpenTelemetry%20到%20Langfuse：企业级%20Agent%20可观测性实践/img_2.png)

以后新增一个 OrderAgent，只要写好  `run` 、接进 Runner 就自动带上可观测性，不用继承任何基类，也不用写一行可观测性代码。

Hook 是同一个思路的另一种写法，在 Agent 生命周期的关键节点回调：

```
class LangfuseHook:

    def before_run(self, agent, query): ...
    def after_run(self, agent, query, result): ...
    def on_error(self, agent, query, error): ...
```

```
Hook       → 偏生命周期事件监听
Middleware → 偏执行链包装与控制
```

只做 Trace、Logging、Metrics，两者都够用。如果要把 Tracing、Retry、Timeout、Guardrail、Fallback、Cache 统一承载，Middleware 更适合作为 Agent Runtime 的统一扩展机制。

### 4.4 最终形态

整个方案从「给一个 Agent 加埋点」演进成「Runtime 自带可观测性」：

![](附件资源/从%20OpenTelemetry%20到%20Langfuse：企业级%20Agent%20可观测性实践/img_3.png)

到这一步，Langfuse 不再只是某个 Agent 的监控工具，而是整个 Agent Runtime 的一项基础能力。

## 五、总结

把 OTel 和 Langfuse 放在一起，是一条连续的路：

```
OpenTelemetry：给 Agent 建可观测性底座

Langfuse：让这套底座真正服务于 LLM / Agent
```

![](附件资源/从%20OpenTelemetry%20到%20Langfuse：企业级%20Agent%20可观测性实践/img_4.png)

落到 Multi-Agent 生产环境，接入方式的演进是：

```
手动埋点  →  BaseAgent  →  Middleware / Hook  →  Agent Runtime
```

核心结论只有一句：从单个 Agent 到几十个 Agent，业务代码里不应该到处出现  `with langfuse...` ，可观测性应该是 Agent Runtime 的基础能力，而不是每个 Agent 自己负责的一段业务代码。

最后，国庆将至，在这里祝大家节日快乐！假期吃好、玩好！

---
原文链接：https://mp.weixin.qq.com/s?__biz=MzI5MTcwMzQ5Ng%3D%3D&mid=2247484014&idx=1&sn=1ebd7fd29dd45b1441c29333433afdfb&chksm=ec0dddc9db7a54dff76b71c63992cb4bb82d1d70763957f395457b2dfe202c4657b2d0543d2a
