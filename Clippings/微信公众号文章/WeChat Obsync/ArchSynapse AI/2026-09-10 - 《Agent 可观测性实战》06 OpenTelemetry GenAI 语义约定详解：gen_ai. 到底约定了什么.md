---
source_url: "https://mp.weixin.qq.com/s?__biz=MzAwMTYwNzE2Mg%3D%3D&mid=2651040403&idx=1&sn=a874f518798e1b5e5b6de29603f4c0c3&chksm=81201e06b657971017ec3340cb4a5567bc9e53500f4a84bd2ac41b24e292cf47a6c485ec6326"
title: "《Agent 可观测性实战》06 | OpenTelemetry GenAI 语义约定详解：gen_ai.* 到底约定了什么"
account: "ArchSynapse AI"
published_at: "2026-09-10 22:00:00"
saved_at: "2026-10-21 22:15:05"
sync_id: "art_05f6152a4b0a4a5b8dcfb7896b0586f9"
parse_status: "ok"
---

# 《Agent 可观测性实战》06 | OpenTelemetry GenAI 语义约定详解：gen_ai.* 到底约定了什么

![](附件资源/《Agent%20可观测性实战》06%20OpenTelemetry%20GenAI%20语义约定详解：gen_ai.%20到底约定了什么/img_1.png)

**ArchSynapse AI**

《Agent 可观测性实战》06

# OpenTelemetry GenAI 语义约定详解：gen_ai.* 到底约定了什么

**// **你好，这里是公众号：【ArchSynapse AI】。

第 5 讲结尾我留了个看似琐碎的问题：那些该记的字段，到底该叫什么名字？是  `model` 、 `llm_model` ，还是  `gen_ai.request.model` ？

别小看这个"起名"问题。它决定的不是美观，而是一件很硬的事：**你埋下的数据，除了你自己的代码，还有谁认得？** 如果字段名是你自己拍脑袋定的，那换一个观测平台、接一个下游分析、想用现成的自动埋点——统统要重写一层映射。而如果大家都遵守同一套命名，你的数据就成了"普通话"，任何遵守约定的平台都能直接听懂。

这套"普通话"，就是这一讲的主角：**OpenTelemetry GenAI 语义约定（Semantic Conventions）**，也就是那一堆  `gen_ai.*` 。这一讲偏硬核，但值得——它是你从"能埋点"走向"埋对、埋得能通用"的分水岭。

- ●   ●

| ** 01 ** | ** 语义约定，到底在约定什么 ** |
| --- | --- |

先把概念说白。**语义约定，就是社区约好"某个概念，统一叫某个名字、放在某个位置"。**

OpenTelemetry 本身只规定了 Trace/Span 这种**结构**，但它不管你往 Span 里塞的属性该叫什么。于是 GenAI 语义约定补上了这一层：它规定，一次大模型调用，"用的哪个模型"这个属性就叫  `gen_ai.request.model` ，"烧了多少输入 token"就叫  `gen_ai.usage.input_tokens` —— **所有人、所有工具，都用同一套 key。**

这带来的直接好处是两个字：**互通**。

|  | 你用 OpenInference 或某个框架的自动埋点产出的数据，Langfuse、Datadog、观测云都能直接解析——因为大家都认  `gen_ai.*`  。 |
| --- | --- |
|  | 你今天用 A 平台，明天想换 B 平台，只要两边都遵循约定， ** 埋点代码一行不用改 ** 。 |

反过来，如果你自定义命名，就等于给自己上了锁：数据出不了你的小圈子，换平台就是一次"数据迁移工程"。这，就是第 5 讲那个"起名问题"的真正分量。

- ●   ●

| ** 02 ** | ** 先说清它的"身位"与状态：这是一个还在长身体的标准 ** |
| --- | --- |

在背任何字段之前，你**必须**先建立一个正确的预期，否则会踩坑：

**GenAI 语义约定，是一个仍在快速演进、大部分内容尚处**  `experimental` **（实验/开发）状态的标准。**

几个关键事实：

|  | 它归属于 OpenTelemetry，如今 GenAI 部分已经拆出了 ** 独立的 SIG 和仓库 ** （  `semantic-conventions-genai`  ）在专门推进，更新很勤。 |
| --- | --- |
|  | 截至撰稿时，语义约定已经过多轮迭代、仍在活跃更新（具体版本以仓库最新 release 为准），但  `gen_ai.*`  里绝大多数属性 ** 仍标注为 experimental ** ——意味着 ** 字段名还可能变 ** 。 |
|  | 这不是空话。给你两个真实发生过的"改名"：token 用量早期叫  `gen_ai.usage.prompt_tokens`  /  `completion_tokens`  ，后来统一改成了  `input_tokens`  /  `output_tokens`  ；标识模型提供方的属性，也从早期的  `gen_ai.system`  演进到了  `gen_ai.provider.name`  。 |

所以，**本讲给你的速查表，请当成"当前快照"来用，一手信息永远以仓库里的 issue/PR 为准。** 但请注意——"标准还在变"是你**更该遵循它**的理由，而不是自己另起炉灶的借口：跟着标准走，将来它演进，社区和工具会帮你平滑迁移；自己发明一套，以后每一次对接、每一次升级，都得你自己扛。

想清楚这个心态，我们来看它到底约定了些什么。

- ●   ●

| ** 03 ** | ** gen_ai.* 的五大块 ** |
| --- | --- |

我把  `gen_ai.*`  拆成五块来理解，正好对应你在第 5 讲里建模的那些 Span。

**第一块：描述"一次 LLM 调用"。** 这是最核心的一组，回答"这是一次什么样的模型调用"：

|  |  `gen_ai.operation.name`  ：操作类型，取预定义值，如  `chat`  （对话）、  `embeddings`  （向量化）、  `execute_tool`  、  `invoke_agent`  等； |
| --- | --- |
|  |  `gen_ai.provider.name`  ：模型提供方，如  `openai`  、  `anthropic`  、  `aws.bedrock`  ； |
|  |  `gen_ai.request.model`  /  `gen_ai.response.model`  ：请求的模型名 / 实际响应的模型名（两者可能不同）； |
|  |  `gen_ai.request.temperature`  、  `gen_ai.request.max_tokens`  、  `gen_ai.request.top_p`  ：请求参数； |
|  |  `gen_ai.response.finish_reasons`  ：结束原因（正常停止？截断？触发了内容过滤？）； |
|  |  `gen_ai.response.id`  ：模型返回的响应 ID，用于对账。 |

**第二块：描述"用了多少"（成本命脉）。**

|  |  `gen_ai.usage.input_tokens`  /  `gen_ai.usage.output_tokens`  ：输入 / 输出 token 数。这两个字段是你第 8、25 讲做成本核算的原料。 |
| --- | --- |

**第三块：描述"Agent 与工具"（Agent 时代的新增，也是重点）。** 这块直接对应我们的多智能体系统：

|  | 操作  `create_agent`  /  `invoke_agent`  ：Agent 的创建与调用；Span 名常写成  `invoke_agent {gen_ai.agent.name}`  这种低基数形式； |
| --- | --- |
|  | 操作  `execute_tool`  ：由 Agent 驱动的工具/函数执行； |
|  |  `gen_ai.agent.name`  /  `gen_ai.agent.id`  /  `gen_ai.agent.description`  ：Agent 的标识与描述； |
|  |  `gen_ai.tool.name`  /  `gen_ai.tool.call.id`  ：工具的稳定标识与本次调用 ID。这里有个易错点——  `gen_ai.tool.name`  要填 ** 稳定的工具名 ** （如  `query_order`  ），别把整段用户请求或 prompt 灌进去。 |

**第四块：内容（prompt / completion）怎么记。** 这块单独拎出来，因为它最敏感：

模型到底看到了什么、说了什么，这些**消息内容**在约定里是通过 **events / logs**（而非直接塞进 Span 属性）来承载的，而且**默认是关闭的、需显式开启（opt-in）**。原因你已经知道——里面全是 PII。（提醒一句：连"内容到底放 events 还是放 Span 属性"这个机制本身，社区都还在拉扯、仍会变，落地前记得核一眼仓库最新方向。）这正好和第 3、5 讲埋的那根脱敏弦对上，第 15 讲会专门讲怎么在"记原文"和"守合规"之间安全落地。

**第五块：指标（Metrics）。** 约定也规范了两个关键指标：

|  |  `gen_ai.client.operation.duration`  ：调用耗时（必备）； |
| --- | --- |
|  |  `gen_ai.client.token.usage`  ：token 用量（推荐）。 |

这两个是你在第 8 讲搭指标看板时的标准原料。

- ●   ●

| ** 04 ** | ** gen_ai.* 属性速查表 ** |
| --- | --- |

把上面五块收进一张速查表，方便你埋点时对照。**再强调一次：下列全部为**  `experimental`  **状态，命名以**  `semantic-conventions-genai`  **仓库为准。**

| 分组 | 属性 / 操作名 | 含义 | 归属 |
| --- | --- | --- | --- |
| 调用 |  `gen_ai.operation.name`  | 操作类型（chat / embeddings / execute_tool / invoke_agent…） | Span 属性 |
| 调用 |  `gen_ai.provider.name`  | 模型提供方（曾用  `gen_ai.system`  ） | Span 属性 |
| 调用 |  `gen_ai.request.model`  /  `gen_ai.response.model`  | 请求 / 实际响应的模型 | Span 属性 |
| 调用 |  `gen_ai.request.temperature`  /  `.max_tokens`  /  `.top_p`  | 请求参数 | Span 属性 |
| 调用 |  `gen_ai.response.finish_reasons`  /  `.id`  | 结束原因 / 响应 ID | Span 属性 |
| 用量 |  `gen_ai.usage.input_tokens`  /  `.output_tokens`  | 输入 / 输出 token（曾用  `prompt/completion_tokens`  ） | Span 属性 |
| Agent |  `create_agent`  /  `invoke_agent`  | Agent 生命周期操作 | 操作（Span 名） |
| Agent |  `execute_tool`  | 工具执行操作 | 操作（Span 名） |
| Agent |  `gen_ai.agent.name`  /  `.id`  /  `.description`  | Agent 标识与描述 | Span 属性 |
| 工具 |  `gen_ai.tool.name`  /  `.call.id`  | 工具稳定标识 / 本次调用 ID | Span 属性 |
| 内容 | prompt / completion 消息内容 | 模型的输入输出原文（ ** 默认关闭，须 opt-in、脱敏 ** ） | 事件 / 日志 |
| 指标 |  `gen_ai.client.operation.duration`  | 调用耗时（必备） | Metric |
| 指标 |  `gen_ai.client.token.usage`  | token 用量（推荐） | Metric |

- ●   ●

| ** 05 ** | ** 把标准贴回那棵 Span 树 ** |
| --- | --- |

理论讲完，见证一下"第 5 讲的建模 + 第 6 讲的命名"合体的时刻。还是退款那一轮，这次我用**标准属性名**把它重画一遍——你会发现，OTel 约定的  `invoke_agent → chat → execute_tool`  结构，和我们第 5 讲切出来的 Span 树严丝合缝：

invoke_agentcustomer_supervisor

gen_ai.agent.name=customer_supervisor

### chat 意图识别 gen_ai.provider.name=... · gen_ai.request.model=... · usage.input_tokens=48 · output_tokens=12

### execute_tool 查订单 OK gen_ai.tool.name=query_order · 95ms

### invoke_agent refund_agent gen_ai.agent.name=refund_agent

(检索政策)

← 见下方说明

|  | chat 判断可退 gen_ai.operation.name=chat · 依据政策v2 |
| --- | --- |

|  | execute_tool 发起退款 ⚠️写 gen_ai.tool.name=issue_refund · success · 220ms |
| --- | --- |

### chat 汇总生成回复 usage.output_tokens=180

对着这棵树，两点值得你记住：

**第一，标准让你的 Trace 变成"通用件"。** 现在这条 Trace，扔给任何遵循  `gen_ai.*`  的平台，它都能自动认出"这是一次 Agent 调用、里面有两次工具执行、退款那次是写操作"，并渲染出 AI 感知的视图。你没有被任何一家平台绑定。

**第二，也要知道标准的"边界"。** 你注意到那个"检索政策"我用了括号、没给标准属性名吗？这是故意的—— **OTel GenAI 约定目前最成熟的是 LLM 调用、Agent、工具这三块，而 RAG / 检索（Retriever）这类的约定还相对薄弱。** 检索的细粒度建模（命中文档、相似度分），反而是 OpenInference 覆盖得更细。

一套标准强在哪、弱在哪，另一套怎么补位——这正好是下一讲的引子。

- ●   ●

| ** ✓ ** | ** 小结 ** |
| --- | --- |

这一讲我们啃下了 GenAI 语义约定这块硬骨头：

| ** 1 ** | ** 语义约定 = 数据的"普通话" ** ：统一命名带来跨平台互通，自定义命名等于给自己上锁。 |
| --- | --- |
| ** 2 ** | ** 它是个还在长身体的标准 ** ：GenAI 部分已独立成 SIG/仓库，多数  `gen_ai.*`  仍是 experimental、字段名会变（token、provider 都改过名）——速查表当快照用，一手以仓库为准；但"会变"是更该遵循它的理由。 |
| ** 3 ** | gen_ai.* 五大块：调用、用量、Agent/工具、内容（敏感、须 opt-in）、指标——每一块都对得上你第 5 讲建的 Span。 |
| ** 4 ** | ** 标准有边界 ** ：LLM/Agent/工具最成熟，RAG/检索相对薄弱——这是下一讲要解决的问题。 |

下一讲（第 7 讲），我们把镜头拉到"标准的江湖"：除了 OTel GenAI，还有 **OpenInference** 和 **OpenLLMetry** 两套。它们和 OTel 是什么关系、各自强在哪、你到底该押哪一套——尤其是当你既要 OTel 的通用性、又要 OpenInference 那种对 RAG 的细腻刻画时，怎么选。这一讲会给你一张对比表和明确的选型建议。

| ** ? ** | ** 思考题 ** |
| --- | --- |

| ** 1 ** | 假设你当初图省事，给字段起了自己的名字（  `my_model`  、  `token_cost`  ……）。现在老板要求把观测数据从自建平台迁到某商业平台—— ** 你要付出哪些额外的代价？ ** 反过来，如果你一开始就遵循了  `gen_ai.*`  ，这次迁移会轻松多少？ |
| --- | --- |
| ** 2 ** | 翻翻你现在的埋点（或你在用的框架的自动埋点）：它记录 token 用量的字段，叫的是  `prompt_tokens`  还是  `input_tokens`  ？由此你能推断出它大致是"哪个年代"对齐的约定吗？ |

| ** ≡ ** | ** 本讲延伸阅读 ** |
| --- | --- |

|  | OpenTelemetry 官方： _ Gen AI 语义约定 _ （opentelemetry.io/docs/specs/semconv 下的 gen-ai 部分）与  `semantic-conventions-genai`  仓库（一手来源） |
| --- | --- |
|  | OpenTelemetry 博客： _ Inside the LLM Call: GenAI Observability with OpenTelemetry _ （2026） |
|  | Greptime： _ How OpenTelemetry Traces LLM Calls, Agent Reasoning, and MCP Tools _ |

**ArchSynapse AI**

看得见的 Agent，才是可信的 Agent

---
原文链接：https://mp.weixin.qq.com/s?__biz=MzAwMTYwNzE2Mg%3D%3D&mid=2651040403&idx=1&sn=a874f518798e1b5e5b6de29603f4c0c3&chksm=81201e06b657971017ec3340cb4a5567bc9e53500f4a84bd2ac41b24e292cf47a6c485ec6326
