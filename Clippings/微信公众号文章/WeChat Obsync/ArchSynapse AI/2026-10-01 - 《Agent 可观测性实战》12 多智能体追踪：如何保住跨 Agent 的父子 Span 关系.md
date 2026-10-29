---
source_url: "https://mp.weixin.qq.com/s?__biz=MzAwMTYwNzE2Mg%3D%3D&mid=2651040448&idx=1&sn=ddcfce19c0a462aa60217dd549fbc8ec&chksm=81201e55b65797434df9b438d47edb1e3ff249637884fff5055206e333b0baefb6bd97bc5a61"
title: "《Agent 可观测性实战》12 | 多智能体追踪：如何保住跨 Agent 的父子 Span 关系"
account: "ArchSynapse AI"
published_at: "2026-10-01 20:00:00"
saved_at: "2026-10-21 22:18:14"
sync_id: "art_574d664a2e5d4b72af44ac84390cfc1f"
parse_status: "ok"
---

# 《Agent 可观测性实战》12 | 多智能体追踪：如何保住跨 Agent 的父子 Span 关系

![](附件资源/《Agent%20可观测性实战》12%20多智能体追踪：如何保住跨%20Agent%20的父子%20Span%20关系/img_1.png)

**ArchSynapse AI**

《Agent 可观测性实战》12

# 多智能体追踪：如何保住跨 Agent 的父子 Span 关系

**// **你好，这里是公众号：【ArchSynapse AI】。

第 11 讲结尾，我埋了一颗雷：**只要一并发，子 Span 就会变成"孤儿"，你的 Trace 树就断了一截。**

而多智能体系统，恰恰是"天生并发"的——主 Agent 为了快，常常同时把活派给订单、物流好几个子 Agent。所以这颗雷，在 multi-agent 场景下几乎必炸。这一讲，我们就正面把它拆了，把跨 Agent 的因果链**焊死**。

- ●   ●

| ** 01 ** | ** 为什么多智能体是观测的"重灾区" ** |
| --- | --- |

单 Agent 断一条链，顶多是某一步看不清。但多 Agent 断链，代价要严重得多，因为它有三个叠加的麻烦：

| ** 1 ** | ** 边界特别多 ** ：主 Agent → 子 Agent → 工具，每往下跨一层，都是一次可能断链的"交接"。层级越深，孤儿 Span 的机会越多。 |
| --- | --- |
| ** 2 ** | ** 天生并发 ** ：主 Agent 常并行调度多个子 Agent（同时查订单、查物流）。而并发，正是上一讲说的孤儿 Span 的温床。 |
| ** 3 ** | ** 静默失败会叠加甩锅 ** ：这是最致命的。退款批错了，到底是主 Agent 编排错了、还是订单子 Agent 返回了脏数据、还是退款子 Agent 判断失误？ ** 没有一条完整的因果链，你连"谁的锅"都分不清 ** ——这正是第 2 讲那个失败家族第七条 "多 Agent 甩锅"。 |

一句话：**单 Agent 断链，你损失的是细节；多 Agent 断链，你损失的是"甩锅裁判权"。** 这是必须焊死链路的根本原因。

- ●   ●

| ** 02 ** | ** 病根：上下文为什么一并发就断 ** |
| --- | --- |

先复习第 11 讲那个机制：OpenTelemetry 用一个叫"当前 Span"的上下文变量（基于 Python 的  `contextvars` ）在背后记账，里层 Span 就是靠读这个变量才知道谁是自己的爹。

关键在于—— **这个变量是"跟着执行流走"的，而不同的执行边界，它的表现并不一样**。上一讲我们已经区分过一次，这里再重复一次：

|  | ** 跨线程：会断。 ** 你用线程池并发跑子 Agent，worker 线程里的  `contextvars`  读不到主线程那个"当前 Span"（  `loop.run_in_executor`  本质相同）； |
| --- | --- |
|  | ** 跨进程 / 跨服务：必断。 ** 子 Agent 是独立的微服务，两个进程之间内存都不通，更别提上下文变量； |
|  | ** asyncio：一般不断。 **  `asyncio.Task`  创建时会 ** 拷贝一份当前 context ** ，所以  `gather`  里的子 Span 会正确挂上去，不用手动接力。它要提防的是 ** 生命周期 ** ——在某个 Span 的  `with`  块里  `create_task`  却不 await，等任务真跑起来时父 Span 可能已经关闭。 |

所以真正需要你动手"焊"的，正是前两种边界。药方也就是那一句：**在跨边界时，手动把上下文"接力"过去**——这在分布式追踪里叫 **上下文传播（Context Propagation）**。下面就分别给这两种边界落地代码。

- ●   ●

| ** 03 ** | ** 焊法一：同进程并发，手动接力上下文 ** |
| --- | --- |

先看最常见的：主 Agent 在**同一个进程**里，用线程池并行调两个子 Agent。

诀窍就一句话：**在派活前抓住当前上下文，在子任务里先把它"接"过来，再开 Span。**

- ●  ●  python

```
from concurrent.futures import ThreadPoolExecutor
from opentelemetry import trace, context as otel_context

tracer = trace.get_tracer("ecom-customer-agent")

def _run_with_ctx(ctx, fn, *args):
"""在子线程里先接过父上下文，再执行——这是防孤儿的关键。"""
    token = otel_context.attach(ctx)          # ← 把父上下文"接力"进本线程
try:
return fn(*args)
finally:
        otel_context.detach(token)            # 用完还原，别污染线程

def run_turn(session_id: str, user_msg: str) -> str:
with tracer.start_as_current_span("invoke_agent customer_supervisor") as root:
        root.set_attribute("session.id", session_id)
        ctx = otel_context.get_current()      # ← 此刻"当前 Span"就是 root，抓住它

# 并行派活给订单、物流两个子 Agent；关键是把 ctx 一起带过去
with ThreadPoolExecutor() as pool:
            f_order = pool.submit(_run_with_ctx, ctx, order_agent, user_msg)
            f_logi  = pool.submit(_run_with_ctx, ctx, logistics_agent, user_msg)
            order, logistics = f_order.result(), f_logi.result()

# 串行：退款依赖前两者的结果，所以放在它们之后
        refund = refund_agent(order, logistics)
return summarize(order, logistics, refund)

def order_agent(user_msg):
# 因为上面 attach 了 ctx，这里开的 Span 的父，正确指向了 root
with tracer.start_as_current_span("invoke_agent order_agent") as span:
        span.set_attribute("gen_ai.agent.name", "order_agent")
return call_tool("query_order", {...})     # call_tool 见第 11 讲
```

 `order_agent` 、 `logistics_agent`  里开的 Span，因为线程一进来就  `attach`  了  `root`  的上下文，它们的父就**牢牢指向 root**——两个子 Agent 虽然在不同线程并行跑，Trace 树却完整不断。

### 顺带一提：如果你嫌每次手动  `attach`  麻烦，OTel 生态里也有对  `ThreadPoolExecutor`  、  `asyncio`  的辅助封装，但 原理都是这一套"抓 ctx → attach → 执行 → detach" 。理解了原理，用哪种语法糖都不慌。

- ●   ●

| ** 04 ** | ** 焊法二：跨进程/跨服务，靠 traceparent 传递 ** |
| --- | --- |

如果你的子 Agent 是**独立部署的微服务**（这在大团队里很常见），内存上下文根本传不过去。这时要靠一个更"物理"的办法：**把追踪上下文塞进请求头，跟着 HTTP 请求一起过去。**

用的是 W3C 的 **Trace Context** 标准（那个  `traceparent`  请求头），OTel 提供了  `inject`  /  `extract`  两个函数，一注一取即可：

- ●  ●  python

```
from opentelemetry.propagate import inject, extract
import requests

# —— 主服务（编排端）：发请求前，把追踪上下文注入 HTTP 头 ——
def call_refund_service(payload):
    headers = {}
    inject(headers)                       # ← 自动写入 traceparent（当前 Span 的身份证）
return requests.post("http://refund-agent/run", headers=headers, json=payload)

# —— 子服务（退款 Agent 端）：收到请求后，从头里提取上下文当"父" ——
def handle_run(request):
    ctx = extract(request.headers)        # ← 从 traceparent 还原出父上下文
with tracer.start_as_current_span("invoke_agent refund_agent", context=ctx) as span:
        span.set_attribute("gen_ai.agent.name", "refund_agent")
# …退款逻辑…（此 Span 的父，正是主服务那个 Span，跨进程也不断链）
```

这套  `inject` / `extract`  其实就是**传统分布式追踪的老本行**——微服务之间传 Trace 上下文，十年前就在这么干了。Agent 时代只是把它复用过来。这也再次印证第 3 讲那句话：可观测性不是 Agent 发明的，我们是站在成熟地基上。

### 用框架的读者请注意 ：LangGraph、CrewAI、AutoGen 这类框架配上 OpenInference 自动埋点， 多半已经帮你处理好了跨节点的上下文传播 。但请务必 去 Phoenix 里亲眼验证一下那棵树断没断 ——尤其是你自己加了并发、或跨了服务之后。别盲信"框架应该搞定了"，断链往往就藏在这种想当然里。

- ●   ●

| ** 05 ** | ** 层级怎么摆：该串联还是并联 ** |
| --- | --- |

链路焊住了，再看**结构**。多智能体的 Span 该怎么组织——两个 Agent 并行协作时，Trace 该并联还是串联？

答案是：**看它们有没有依赖，如实反映即可——但不管串还是并，父子关系都不能丢。**

|  | ** 无依赖 → 并联 ** ：查订单和查物流互不依赖，就让它俩并发，两个子 Span 在时间轴上 ** 重叠 ** ，但都挂在主 Agent 这个父下面； |
| --- | --- |
|  | ** 有依赖 → 串联 ** ：退款必须等订单、物流结果出来才能判断，所以退款子 Agent 的 Span 在时间上 ** 排在它们之后 ** 。 |

画成拓扑图，一目了然：

invoke_agent customer_supervisor主 Agent编排

### invoke_agent order_agent 订单 并联 与物流并发，时间轴上重叠

execute_tool query_orderOK

95ms

### invoke_agent logistics_agent 物流 并联 与订单并发，时间轴上重叠

execute_tool query_logisticsOK

110ms

### invoke_agent refund_agent 退款 串联 依赖前两者的结果，排在它们之后

retrieve 退款政策命中[政策v2 0.82]

|  | chat 判断可退 依据=政策v2第3条 |
| --- | --- |

|  | execute_tool issue_refund ⚠️写 success 220ms |
| --- | --- |

**并联不等于断链**——这是最容易被误解的一点。并行的两个 Span 时间上重叠，但它们的父指针必须都指向主 Agent。你在第三节做的那套"接力上下文"，保证的正是这件事：**让并发反映为"同父的兄弟"，而不是"失散的孤儿"。**

- ●   ●

| ** 06 ** | ** 收益：从"互相甩锅"到"一眼定责" ** |
| --- | --- |

焊好这条链，你到底赚到了什么？回到那个最痛的场景：**退款批错了。**

打开这条完整的 Trace 拓扑，责任链清清楚楚地摊在你面前：

customer_supervisor状态 OK ✅

### order_agent → query_order 状态 OK ✅ order_id=X ← 用户问的其实是 order_id=Y

### logistics_agent 状态 OK ✅

### refund_agent → issue_refund 状态 OK ✅ 依据 order_id=X → 误退

**请特别注意：这四个 Span 的状态全是**  `OK` **，没有任何一个报错、没有一处红色。** 这正是第 2 讲讲的静默失败——工具调用参数合法、接口 200、返回正常，只不过**查的是别人的订单**。指望平台自动给你标个红叉，是不会发生的。

那 Trace 给了你什么？**证据。** 正因为  `order_id`  被如实记在了 Span 属性里，你才能把它和用户真正的订单号一对，立刻看出：根因是**订单子 Agent 返回了脏数据**，而退款子 Agent 只是"忠实地基于一个错误前提"往下走——它没做错任何事，却造成了误退。

这就是第 2 讲那句话的现金价值：**面对静默失败，你唯一能抓住的确定性，就是每一步的过程证据。** 有了这条链，"多 Agent 甩锅"到此终结—— **不是谁嘴硬谁赢，是证据说了算。**

这个"跨 Agent 全链路因果"的能力，也正是国内头部厂商在重点建设的方向，可作为你将来选型的参照（平台篇第 22 讲细讲）：**火山引擎**的 OneAgent 统一探针，主打从 App 到 AI 网关、Agent、工具、模型的**全链路统一采集**；**阿里云**则上线了支持 **Multi-Agent 全链路透视**的方案。它们要解决的，本质上就是这一讲的核心命题—— **别让任何一个子 Agent 变成断线的孤儿。**

- ●   ●

| ** ✓ ** | ** 小结 ** |
| --- | --- |

这一讲，我们把多智能体这块最硬的骨头啃了：

| ** 1 ** | ** 为什么是重灾区 ** ：边界多、天生并发、静默失败叠加甩锅——多 Agent 断链，损失的是"甩锅裁判权"。 |
| --- | --- |
| ** 2 ** | ** 病根 ** ：OTel 的"当前 Span"上下文跟着执行流走，不跨线程/协程/进程边界，一并发就跟丢。 |
| ** 3 ** | ** 两种焊法 ** ：同进程并发，手动"抓 ctx → attach → 执行 → detach"接力；跨进程/服务，用  `inject`  /  `extract`  把 traceparent 塞进请求头。 |
| ** 4 ** | ** 层级设计 ** ：无依赖并联、有依赖串联，如实反映——但 ** 并联不等于断链，父子关系必须都指向主 Agent ** 。 |
| ** 5 ** | ** 框架党要验证 ** ：别盲信框架"应该搞定了"，去 Phoenix 亲眼看树断没断。 |

下一讲，我们钻进那个"幻觉高发区"—— **RAG 链路观测**。当 Agent 又双叒胡说时，到底是"检索没找到对的文档"，还是"检索对了但生成乱编"？我会教你用 Retriever Span 里的证据，把这两种病一刀切开、精准归因。第 9 讲埋的"忠实性幻觉"那个伏笔，也在下一讲兑现。

| ** ? ** | ** 思考题 ** |
| --- | --- |

| ** 1 ** | 顺着第五节的并联结构往深追一层：假设主 Agent ** 并行 ** 调了订单和物流两个子 Agent，其中 ** 物流子 Agent 超时失败 ** 了。在你的 Trace 拓扑里，这个失败 ** 应该长什么样 ** ？它会不会影响到另一个并行的订单 Span 的父子关系？主 Agent 那个根 Span 的状态又该是什么？（提示：想想"兄弟"之间是否互相牵连。） |
| --- | --- |
| ** 2 ** | 动手挑战：把第三节的并发接力代码跑起来，然后 ** 故意去掉 **  `_run_with_ctx`  ** 里的 **  `attach`  ，再去 Phoenix 看那棵树——你会亲眼看到"孤儿 Span"长什么样。见过一次，你就再也不会忘了这个坑。 |

| ** ≡ ** | ** 本讲延伸阅读 ** |
| --- | --- |

|  | OpenTelemetry： _ Context Propagation _ 与 W3C _ Trace Context _ （  `traceparent`  ）规范 |
| --- | --- |
|  | 阿里云云原生： _ 告别 Agent"黑箱"！阿里云上线 AI Agent 可观测方案，支持 Multi-Agent 全链路透视 _ |
|  | 火山引擎开发者社区： _ Agent 可观测性——从 Trace 到回放 _ （OneAgent 全链路统一采集） |

**ArchSynapse AI**

看得见的 Agent，才是可信的 Agent

---
原文链接：https://mp.weixin.qq.com/s?__biz=MzAwMTYwNzE2Mg%3D%3D&mid=2651040448&idx=1&sn=ddcfce19c0a462aa60217dd549fbc8ec&chksm=81201e55b65797434df9b438d47edb1e3ff249637884fff5055206e333b0baefb6bd97bc5a61
