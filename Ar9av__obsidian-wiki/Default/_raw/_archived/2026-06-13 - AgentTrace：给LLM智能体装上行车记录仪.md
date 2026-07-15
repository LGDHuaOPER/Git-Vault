---
source_url: "https://mp.weixin.qq.com/s?search_click_id=10944039153882374254-1784128517935-5938319167&__biz=MzAxMTExMzg0Ng==&mid=2651337631&idx=1&sn=91b9b470f9b364e364085adf28e5f566&chksm=81ef05f7f9c094b939b04d3f21d11ba9ad2d96a638acb3bb67537d16f79cec0c1b6d100ed9ad&subscene=0&scene=7&clicktime=1784128517&enterid=1784128517&ascene=65&devicetype=iOS26.5.2&version=18004b3c&nettype=WIFI&abtest_cookie=AAACAA==&lang=zh_CN&countrycode=CN&fontScale=100&exportkey=n_ChQIAhIQu9ME8e9CRF+CQoUjw1GsORLhAQIE97dBBAEAAAAAANjCGVwd2gQAAAAOpnltbLcz9gKNyK89dVj0nvDZmTHWbET/bA+w1rFzN57BkNf1NIMUxgzQo+BMi2wD0ihRXXo6lZXHpIo3PaUadB4SuRUeljx1aWw2Jb78EbpJ301x9aVv1lmQKBcQqypCY1dA9sNFCWmEjNwe52cOvYLkseZteT0lJENnqP0yIiOQF3LK0gKamszrfvgRU/r9e0AqwIzjpwWo8aAb4xUuOF8WOUMCW9Y5xFH+ULiiB/39LEQW6k/KjZoF5mTmRQACCRVgfmU05ldsZw==&pass_ticket=qpQHHl/kn1GEu4uM+XVwY+23qsHMjaPwZMhP/LwgKrNki+02YxI5I31R1mbppCjB&wx_header=3"
title: "AgentTrace：给LLM智能体装上行车记录仪"
account: "Agentic AI研习社"
published_at: "2026-06-13T05:00:00.000Z"
saved_at: "2026-07-15T15:15:26.922Z"
sync_id: "art_db78138c779b4b21bde67f2a895791d2"
parse_status: "ok"
---

# AgentTrace：给LLM智能体装上行车记录仪

> 生产环境中，AI Agent做了一个决定，没人知道它为什么那样做。翻开日志，全是 print() ，一声叹息。

[Agent评测合集](https://mp.weixin.qq.com/mp/appmsgalbum?__biz=MzAxMTExMzg0Ng==&action=getalbum&album_id=4541775438192525322#wechat_redirect)

![](附件资源/AgentTrace：给LLM智能体装上行车记录仪/img_1.jpg)

# 黑箱在跑，人在猜

LLM智能体已经能调用工具、查数据库、自己修订目标了。它们正在从Demo走进生产环境。

但有个问题没怎么被认真讨论：**这些东西在跑的时候，外部几乎看不到里面在发生什么**。

传统的安全审计手段，像输入过滤、Prompt加固、API边界控制，都是围绕"确定性系统"设计的。它们假设程序按固定路径执行，行为可预测。LLM智能体不吃这一套。它们的推理是非确定性的，操作序列是动态拼出来的，更麻烦的是，**出问题的往往不是恶意输入，而是智能体自己推理路径上的偏差**：配置没问题，工具没问题，但它就是想偏了。

UC Berkeley的研究者们在**AgentTrace**这篇论文里直面了这个问题。他们的判断是：**不是安全手段不够多，是底层缺了一层可观测性基础设施**。

# 日志不是用来"事后翻"的

目前大多数团队调试LLM智能体的方式还相当原始。加几个 `print()` ，看看Prompt和Response，运气好再查一下API调用链。智能体一旦跑复杂了，多个工具链式调用、读写记忆、甚至多智能体协作，这点信息量根本还原不出"发生了什么，为什么发生"。

AgentTrace的想法很直接：**把日志从一个调试工具升级成一等公民的基础设施层**。像数据库有WAL、微服务有分布式追踪一样，智能体也应该有自己结构化的Trace。

具体做法是把智能体的运行时拆成三个"面"（Surface），每个面管一类信息。

![](附件资源/AgentTrace：给LLM智能体装上行车记录仪/img_2.png)

图1 AgentTrace概览

# 三层：操作、认知、上下文

## 操作面：谁调了谁，花了多久

这层最"常规"，但实现得挺干净。

AgentTrace用Python的装饰器注入，在运行时自动拦截智能体类上的所有公共方法。**每次方法调用产生一对事件： `start` 和 `complete` **，带着方法名、参数摘要、返回类型、耗时。事件同时写进本地JSONL和OpenTelemetry Span，Trace/Span的父子关系全部保留。

熟悉微服务分布式追踪（Dapper、Jaeger）的人对这套逻辑不会陌生。AgentTrace做的事情本质上就是**把分布式追踪的理念压到单个智能体的粒度**。

## 认知面：它当时到底在想什么

这层是整个论文最有意思的地方。

操作面告诉外界智能体"做了什么"，认知面告诉外界它"为什么这么做"。具体来说，AgentTrace会捕获：

- • 原始Prompt和LLM返回的Completion
- • 推理链（Chain-of-Thought的每一步）
- • 置信度估计
- •  标签里的内容和结构化的JSON字段（ plan 、 reflection 等）

提取方式是一套通用策略：**标记检测 + XML标签解析 + JSON字段提取**，不绑定特定模型或Prompt格式。

真正关键的设计是：**认知Span嵌套在操作Span里**。也就是说，从"智能体调了一个API"这个操作，一层层展开，能看到它当时想了什么才决定调这个API。这个追溯能力在生产环境排查问题时能节省大量时间。

举个例子：凌晨三点，监控告警，智能体做了一次不该做的数据写入。点开Trace，操作Span展开，认知Span展开，看到当时的CoT："用户说'帮我整理一下'，我认为应该归档到主库> ……" 立刻就能定位是Prompt里的"整理"触发了歧义。没有这层Trace，对着监控只能干瞪眼。

## 下文面：跟外面世界的一切交互

这层追踪智能体所有向外的I/O：**HTTP请求、SQL/NoSQL查询、Redis缓存操作、向量数据库访问、文件系统读写**。

实现上借了OpenTelemetry的自动检测能力，通过monkey-patch  `requests` 、 `sqlalchemy` 、 `redis` 这些标准库，不用手动埋点。每个外部交互都会带上自己的元数据：URL、查询语句、返回行数、延迟。

**这层桥接了"想"和"做"**。一个内部推理决定，什么时候变成了外部的数据库查询，中间花了多久，一目了然。

# 共享信封

三层的日志事件套在同一个结构里：

uuid

surface: cognitive | operational | contextual

trace_id, span_id

timestamp (UTC)

event_body (per-surface)

存两份：JSONL给离线分析、回放和流式处理，OTel Span给实时追踪和Jaeger/Tempo的可视化。**写入时做Schema校验，追加写入，导出失败不影响执行**。

# 装饰器注入：一个很干净的实现

论文里的Algorithm 1值得单独提一下。整个包装逻辑只有五步：

- 1. 给每个目标方法创建一个保留签名的wrapper
- 2. 调用前生成Trace/Span ID，记录start事件
- 3. 执行原函数，过程中尝试提取认知内容
- 4. 成功返回后记录complete 事件（耗时、结果摘要）
- 5. 异常时记录error事件，原样re-raise

几个工程决策相当务实：装饰器注入不碰业务代码；正常路径每次调用只产生两个事件，导出异步批处理；序列化失败不会阻塞执行。整体上是一个**非侵入、低开销、可组合**的方案。

# 读完之后的延伸思考

论文标题里有个词：**"foundational layer"**（基础层）。乍一听有点大，但读完整篇之后会发现这个定位是准确的。

现在LLM智能体的生态有点像微服务早期的混沌状态：框架一堆（LangChain、AutoGPT、CrewAI……），但可观测性基本停在 `print()` 调试阶段。AgentOps、LADYBUG这些早期的观测工具开了一个好头，但它们偏单面追踪，没有一个Schema把认知、操作、上下文统一起来。

AgentTrace提了一个开放标准。有了结构化的Trace之后，很多事才能往下做：动态威胁检测、事后安全取证、推理稳定性评估、跨智能体的行为基准测试。

但也有几个明显还没解决的问题：

**认知面的深度不够。**目前的提取靠标记解析（ `` 标签、JSON字段），复杂推理很多时候是非结构化的，散在多轮对话里。怎么捕获更细粒度的"推理微步"，论文自己也承认这是个开放问题。

**Schema能不能统一也是个问号。** AgentTrace的三面分类和共享信封是一个好起点，但如果每个框架各玩各的Schema，互操作性还是零。行业是否会需要一个像OpenTelemetry之于微服务那样的标准化协议？这需要社区共识，不是一篇论文能解决的。

**隐私这件事绕不过去。** 论文把Privacy / Redaction 标成了future work。认知面捕获的Prompt和推理链可能夹着用户敏感数据，生产环境里这是卡脖子的点。可观测性和隐私保护怎么平衡，还需要更多工作。

# 最后

AgentTrace有意思的地方不是它多复杂，而是它把一个问题摆到了台面上：**智能体在里面跑了半天，外界真的知道它在干什么吗？**

对有LLM智能体跑在生产环境的团队来说，这值得认真琢磨一下：下次出问题的时候，手上是散落一地的 `print()` ，还是一个能告诉是谁、做了什么、为什么这样做的完整Trace？

两种选择，两种完全不同的心理状态。

**PS：**

最后，做个小小的推荐，目前正在进行的两个项目：

- [Agent Insight](https://mp.weixin.qq.com/s?__biz=MzAxMTExMzg0Ng==&mid=2651337583&idx=1&sn=f0405a0fdf534d96afc369fc76a51e7c&scene=21#wechat_redirect) ： 由openEuler孵化，旨在让每一个Agent 都可被观测、可被评估、可自我进化。
- [Skill Radar](https://mp.weixin.qq.com/s?__biz=MzAxMTExMzg0Ng==&mid=2651337298&idx=1&sn=76352a0711478ee06879ededa5f563ae&scene=21#wechat_redirect) ：给Agent Skills技术画一张”活地图”，追踪Skills技术，让Agent能力进化有迹可循。

如果你对这方面感兴趣，别忘了**点赞、关注**噢~

**更多Agentic AI技术前沿分享，欢迎扫描下方二维码进入技术交流群**（或者添加群助手ID：qstarsky 邀请您进群交流）

Agentic AI

![图片](附件资源/AgentTrace：给LLM智能体装上行车记录仪/img_3.jpg)

**立即扫码**

# 往期回顾

# [从Skill Insight到Agent Insight：一次以Harness为中心的演进](https://mp.weixin.qq.com/s?__biz=MzAxMTExMzg0Ng==&mid=2651337583&idx=1&sn=f0405a0fdf534d96afc369fc76a51e7c&scene=21#wechat_redirect)

# [评测挂了？先别判死刑，可能是评测Agent走错了路](https://mp.weixin.qq.com/s?__biz=MzAxMTExMzg0Ng==&mid=2651337605&idx=1&sn=6bb469cefe5873f8b2b8855ebfad4599&scene=21#wechat_redirect)

# [Agent评测](https://mp.weixin.qq.com/mp/appmsgalbum?__biz=MzAxMTExMzg0Ng==&action=getalbum&album_id=4541775438192525322#wechat_redirect)

# 相关链接

- • 论文：https://arxiv.org/pdf/2602.10133

---
原文链接：https://mp.weixin.qq.com/s?__biz=MzAxMTExMzg0Ng%3D%3D&mid=2651337631&idx=1&sn=91b9b470f9b364e364085adf28e5f566&chksm=81ef05f7f9c094b939b04d3f21d11ba9ad2d96a638acb3bb67537d16f79cec0c1b6d100ed9ad
