---
source_url: "https://mp.weixin.qq.com/s?__biz=MzAwMTYwNzE2Mg%3D%3D&mid=2651040405&idx=1&sn=9a3f79197df8ec57d074b077f05d9725&chksm=81201e00b65797169aaba88eaea0f2140a7fadeac87bb5c713b49200a9267d4d5a0d2b85bbff"
title: "《Agent 可观测性实战》07 | 三套标准怎么选：OpenInference vs OpenLLMetry vs OTel GenAI"
account: "ArchSynapse AI"
published_at: "2026-09-12 21:00:00"
saved_at: "2026-10-21 22:15:39"
sync_id: "art_e463e5e0345a47f08d3c7201d28d532d"
parse_status: "ok"
---

# 《Agent 可观测性实战》07 | 三套标准怎么选：OpenInference vs OpenLLMetry vs OTel GenAI

![](附件资源/《Agent%20可观测性实战》07%20三套标准怎么选：OpenInference%20vs%20OpenLLMetry%20vs%20OTel%20GenAI/img_1.png)

**ArchSynapse AI**

《Agent 可观测性实战》07

# 三套标准怎么选：OpenInference vs OpenLLMetry vs OTel GenAI

**// **你好，这里是公众号：【ArchSynapse AI】。

第 6 讲结尾，我故意留了个破绽：那棵标准 Span 树里，"检索政策"那一步没给标准属性名——因为 OTel GenAI 约定在 RAG/检索这块还比较薄弱。

于是你上网一搜，很可能更懵了：除了 OTel GenAI，还冒出来 **OpenInference**、**OpenLLMetry** 两套东西，都说自己是"LLM/Agent 可观测性标准"。它们打架吗？我到底该信哪个、埋哪套？

这一讲就把这个"标准的江湖"讲清楚。先给你吃颗定心丸：**它们基本不打架——因为三者都站在 OpenTelemetry 的肩膀上。**

- ●   ●

| ** 01 ** | ** 先建立正确的心智：它们不是"三选一的对手" ** |
| --- | --- |

很多人一上来就把这三个摆成擂台，问"谁赢"。这是错的。正确的图景是**分层**的：

### 2

语义约定 + 自动埋点分歧只在这一层

OpenInference　｜　OpenLLMetry　｜　OTel GenAI(gen_ai.*)

### 1

统一的底座三者共用

OpenTelemetry（Trace / Span / OTLP）

**底座只有一个：OpenTelemetry。** Trace、Span 这套结构（第 4 讲）和 OTLP 传输协议，三者共用。真正有分歧的，只是上面那一层—— **"AI 特有的东西该怎么命名、怎么自动采集"**。

所以正确的问题不是"选哪个标准"，而是"**在 OTel 这个共同底座上，我用哪一套约定和埋点库，来把 AI 语义采下来**"。想清楚这个，下面就好办了。我们一个一个看。

- ●   ●

| ** 02 ** | ** 三套分别是什么、强在哪 ** |
| --- | --- |

**OTel GenAI（** `gen_ai.*` **）——官方"正统"，最中立，但偏"标准"而非"工具"。**

这就是第 6 讲的主角，它是 OpenTelemetry 社区（GenAI SIG）的**官方语义约定**本身。它的价值是**中立和面向未来**：不绑任何厂商，谁都得向它看齐。但也正因为它是"标准"而非"现成工具"，它更多是**规定字段该叫什么**，具体怎么把数据采出来，往往还得靠某个 instrumentation 库去实现。短板你也知道了：LLM/Agent/工具最成熟，RAG/检索相对薄弱，且大量属性仍是 experimental。

**OpenInference——Arize 主导，自动埋点开箱即用，对 RAG 刻画最细。**

OpenInference 是一套**语义约定 + 一整套自动埋点库**。它的核心标志是那个**必填**的  `openinference.span.kind` （第 5 讲那套"工种"就出自这里），靠它把每个 Span 归类，让平台能渲染出 AI 感知的视图。它有两个突出优点：

| ** 1 ** | ** 开箱即用的自动埋点 ** ：对 LangChain、LlamaIndex、OpenAI、CrewAI 等主流框架，装上对应的 instrumentation 就能自动出 Span，不用你手写； |
| --- | --- |
| ** 2 ** | ** 对 RAG / 检索刻画最细 ** ：Retriever、Reranker、Embedding 这些 Span 的建模是它的强项——正好补上 OTel GenAI 的短板。 |

要记住的一点：**OpenInference 产出的每一条 Trace，本身就是合法的 OTLP**——它是在 OTel 之上加了一层 AI 语义，不是另起炉灶。它是 Arize/Phoenix 生态的埋点层，但数据并不被锁死在里面。另外一个要留意的默认行为：**它倾向于默认捕获完整的 prompt/completion**——方便，但敏感，合规场景你得主动关掉或脱敏（这条我们下一节细说）。

**OpenLLMetry——Traceloop 主导，一行接入，后端中立。**

OpenLLMetry 是 Traceloop 维护的**开源 SDK + 自动埋点集**，主打"一行初始化，自动给你的 LLM 调用、向量库、框架埋点"，然后输出**标准 OTLP**，可以接到任何观测后端。

这里要**纠正一个网上流传很广的说法**：有人说"OpenLLMetry 已经并入 OpenTelemetry 了"—— **不准确**。准确的表述是：它是一个**独立的开源项目**，构建在 OTel 之上，语义持续向 OTel GenAI 对齐、并把成果往上游贡献，但它本身仍独立存在、独立演进。你别把它和"官方标准"划等号。

- ●   ●

| ** 03 ** | ** 一张表看清取舍 ** |
| --- | --- |

把上面拆成可对比的维度，一表收尽：

| 维度 | OTel GenAI（  `gen_ai.*`  ） | OpenInference | OpenLLMetry |
| --- | --- | --- | --- |
| 主导方 | OpenTelemetry 社区（GenAI SIG） | Arize | Traceloop |
| 本质 | 官方 ** 语义约定 ** （标准本身） | 语义约定 + 自动埋点库 | SDK + 自动埋点库 |
| 与 OTel 关系 | 它 ** 就是 ** OTel 的一部分 | 建立在 OTel 之上，产出合法 OTLP | 建立在 OTel 之上，向 OTel GenAI 对齐（ ** 仍是独立项目 ** ） |
| 核心标志 |  `gen_ai.*`  |  `openinference.span.kind`  （必填） | 一行 init，自动埋点 |
| 自动埋点 | 依赖各家 instrumentation | 开箱覆盖 LangChain/LlamaIndex/OpenAI/CrewAI 等 | 广覆盖 LLM 供应商 + 向量库 + 框架 |
| RAG/检索刻画 | 相对薄弱 | ** 最细 ** （Retriever/Reranker/Embedding） | 中等 |
| prompt/completion 默认 | 默认关闭，须 opt-in（走 events） | ** 默认捕获全量 ** （需自行关/脱敏） | 可配置 |
| 中立 / 不绑生态 | ** 最中立 ** | 偏 Arize/Phoenix 生态，但输出仍是 OTLP | 后端中立（输出标准 OTLP） |
| 成熟度 | 多为 experimental、演进快 | 相对稳定、实用 | 相对稳定、实用 |

看这张表，你应该能品出三者的"性格"：OTel GenAI 是**中立的裁判**（定规矩），OpenInference 和 OpenLLMetry 是**能干活的选手**（既守规矩、又帮你把数据自动采出来），后两者只是各自的侧重和生态不同。

- ●   ●

| ** 04 ** | ** 给你明确的选型建议 ** |
| --- | --- |

我知道你要的不是"看情况"，而是能拍板的建议。那我直说：

|  | ** 默认立场：以 OTel GenAI（ ** `gen_ai.*` ** ）为"北极星"。 ** 无论你实际用哪套埋点库，都让最终落库的字段向  `gen_ai.*`  看齐。这是你面向未来、不被任何厂商绑架的保险。 |
| --- | --- |
|  | ** 想要开箱即用、且是重度 RAG 场景 → OpenInference。 ** 尤其如果你已经在用、或打算用 Arize Phoenix（一个很强的开源评估/调试平台，第 21 讲会讲），OpenInference 是天然搭配，它对检索链路的刻画能力，做 RAG 归因时（第 13 讲）会让你受益良多。 |
|  | ** 想要一行接入、多框架自动埋点、又要后端自由 → OpenLLMetry。 ** 它输出标准 OTLP，今天接观测云、明天接 Datadog，后端随你换。 |
|  | ** 最该避免的，不是"选错这三个中的哪一个"，而是"自己发明一套私有字段"。 ** 只要你落在这三套里的任意一套，底层都是 OTLP、都能被主流平台消化，将来平滑迁移；一旦自造私有格式，就回到了第 6 讲说的"给自己上锁"。 |

一句话总结这套决策：**底座认准 OpenTelemetry，字段向**  `gen_ai.*`  **看齐，埋点库按"框架契合度 + 是否重 RAG + 生态"来挑。**

- ●   ●

| ** 05 ** | ** 选 OpenInference 前，留意那个"默认全量"开关 ** |
| --- | --- |

上面表格里有一行值得单独点出来：**OpenInference 默认捕获完整 prompt/completion**。这是它"开箱即用"的一体两面——出了幻觉、出了 badcase，原文都在，排查和做评估样本一步到位（第 13、16 讲的宝贵素材）；但我们那个电商客服系统的对话里塞满了手机号、订单地址、支付信息，**原样灌进观测后端、尤其是境外 SaaS，在国内就是实打实的合规红线**。

所以选型时多问一句：**这套埋点默认记不记全量、能不能关、能不能脱敏？** 这不是劝你别用 OpenInference，而是提醒你——"默认全量"是个需要主动审视、而非闭眼接受的开关。至于"既要留证据、又要守合规"具体怎么落地，是第 15 讲的正题，这里不展开。

- ●   ●

| ** ✓ ** | ** 小结 ** |
| --- | --- |

这一讲我们理清了"标准的江湖"：

| ** 1 ** | ** 它们不是三选一的对手，而是分层的 ** ：底座都是 OpenTelemetry，分歧只在上面"AI 语义约定 + 自动埋点"这一层。 |
| --- | --- |
| ** 2 ** | ** 三者性格 ** ：OTel GenAI 是中立的裁判（最正统、RAG 弱、多 experimental）；OpenInference 是自动埋点选手（RAG 刻画最细、默认抓全量、偏 Arize/Phoenix 生态）；OpenLLMetry 是后端中立选手（一行接入、独立项目、非"已并入 OTel"）。 |
| ** 3 ** | ** 选型口诀 ** ：底座认准 OTel，字段向  `gen_ai.*`  看齐，埋点库按框架契合度/是否重 RAG/生态来挑； ** 最该避免的是自造私有字段 ** 。 |
| ** 4 ** | ** 一个必审的默认项 ** ：OpenInference 默认记全量 prompt——方便但踩合规红线，选型时先看清它能不能关、能不能脱敏（完整解法见第 15 讲）。 |

到这里，原理篇只剩"指标"和"评估指标"两块拼图了。下一讲，我们从"链路"切换到"数字"：**延迟、Token、成本、成功率……这么多指标，到底该盯哪些、怎么定阈值？** 我会帮你把一堆散乱的指标，收敛成一套"能指导行动"的指标框架。

| ** ? ** | ** 思考题 ** |
| --- | --- |

| ** 1 ** | 回到你自己的项目：你现在的观测数据，是遵循了  `gen_ai.*`  / OpenInference / OpenLLMetry 里的某一套，还是一套 ** 自己发明 ** 的私有字段？如果是后者，试着估一估：要迁到一个标准平台，你大概要改多少地方？ |
| --- | --- |
| ** 2 ** | 你的业务场景， ** 需要默认记录完整的 prompt/completion 吗 ** ？如果需要，你打算怎么在"留证据"和"合规脱敏"之间取得平衡？（先想想，第 15 讲我们对答案。） |

| ** ≡ ** | ** 本讲延伸阅读 ** |
| --- | --- |

|  | OpenInference 规范与  `span.kind`  （arize-ai.github.io/openinference） |
| --- | --- |
|  | OpenLLMetry（Traceloop，github.com/traceloop/openllmetry） |
|  | Arthur： _ OpenInference vs OpenTelemetry GenAI Conventions for Agent Tracing _ |

**ArchSynapse AI**

看得见的 Agent，才是可信的 Agent

---
原文链接：https://mp.weixin.qq.com/s?__biz=MzAwMTYwNzE2Mg%3D%3D&mid=2651040405&idx=1&sn=9a3f79197df8ec57d074b077f05d9725&chksm=81201e00b65797169aaba88eaea0f2140a7fadeac87bb5c713b49200a9267d4d5a0d2b85bbff
