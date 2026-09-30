---
source_url: "https://mp.weixin.qq.com/s?__biz=Mzk0MzY4NzUzMQ%3D%3D&mid=2247484245&idx=1&sn=b3bc610e34d1458ab4e3afe9d814f789&chksm=c3315151f446d84744d3ae4d3b0a1acce6ee3a41ed36b98c32a218c6f219c85c9d76dc689ff2"
title: "图解谷歌OKF（Open Knowledge Format）仓库，理解开放知识格式的落地路径"
account: "小码AI笔记"
published_at: "2026-06-23T04:39:03.000Z"
saved_at: "2026-08-16T00:41:03.418Z"
sync_id: "art_628cac2af51a42b6997abad6608b088f"
parse_status: "ok"
---

# 图解谷歌OKF（Open Knowledge Format）仓库，理解开放知识格式的落地路径

![](附件资源/图解谷歌OKF（Open%20Knowledge%20Format）仓库，理解开放知识格式的落地路径/img_1.png)

前些日子 Google Cloud 发布了 Open Knowledge Format（开放知识格式：[谷歌发布OKF（Open Knowledge Format）规范，它与Karpathy的LLM-wiki是什么关系？](https://mp.weixin.qq.com/s?__biz=Mzk0MzY4NzUzMQ==&mid=2247484230&idx=1&sn=9169887ece86b85f82dd2c86c2c8172c&scene=21#wechat_redirect)），并在 `GoogleCloudPlatform/knowledge-catalog` 仓库里一起给出了规范文件、参考写入端（智能体）、样例运行配方、已生成知识包（bundle）、查看器（ `viz.html` ），以及接入 Knowledge Catalog 的演示。当前版本还是 `OKF v0.1 — Draft` ，说明规范还在完善中。[1][2][3][5][6]

本篇拆解谷歌的示例仓库，看OKF的具体落地内容： `SPEC.md` 是规格起点，后面还有参考写入端、样例产物、消费端查看器，以及接入谷歌 Knowledge Catalog 产品适配示例。[1][2][5][6]

> 按照OKF的路径，未来的知识就像一包包可携带的知识包，可直接放进项目、智能体或目录系统直接消费。它可以是一棵目录，也可以被打成压缩包分发；它是不同消费端都认同同一份契约。

把  `GoogleCloudPlatform/knowledge-catalog/okf/` 根目录摊平看，大致是这样：

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

```bash
okf/├─ SPEC.md                  # OKF 最小交换约定├─ README.md                # 仓库导航、样例索引和运行说明├─ samples/                 # 复跑说明：数据集、种子网址、精确 enrich 命令├─ bundles/                 # 已生成的 OKF 知识包和 viz.html├─ src/reference_agent/     # 写入端与查看器实现│  ├─ sources/              # 数据源适配器，当前仓库只内置 BigQuery│  ├─ bundle/               # 文档写入、路径和索引生成│  ├─ web/                  # 网页抓取│  ├─ viewer/               # 知识包可视化│  └─ cli.py / runner.py    # 执行入口和流程编排├─ tests/                   # 数据源、知识包、查看器、web pass 的行为测试└─ pyproject.toml           # Python 包入口和依赖
```

仓库不只写了规格文件 `SPEC.md` ，还把交换约定、运行配方、写入端实现、已生成产物和消费端样板一起给出来了。[2]

> 提示：文中的 BigQuery 是 Google Cloud（很多人也叫 GCP）提供的全托管、无服务器企业级云数据仓库，面向大规模数据分析；用户不用自己管理底层基础设施，就能用标准 SQL 或 Python 查询和分析 PB 级数据。后面出现的  `BQ pass`  里的 `BQ` ，就是 BigQuery 的缩写。按 Google Cloud 价格页当前说明，BigQuery 免费层包含每月 10 GiB 存储和 1 TiB 查询处理量。[7][8]

不过在仔细读  `SPEC.md` 之前，最好先把仓库里的三样东西分清。

 `samples/` 不是原始知识数据，也不是智能体自动读取的一整套配置，而是仓库附带的复跑说明：本次要跑哪个外部资料（数据集）、用什么  `enrich` 命令， `seeds.txt`  则给  `web pass` 提供种子网址。程序实际读取的是命令行参数和  `seeds.txt` ，再由 `reference_agent`  去读外部数据源，把结果写进 `bundles/` 。

把仓库拆开看，实际链条是 `样例说明数据源和运行参数 -> reference_agent 执行 -> bundles 落产物` 。[2]

## OKF 定的是知识包结构、概念文档和最小字段约束

![](附件资源/图解谷歌OKF（Open%20Knowledge%20Format）仓库，理解开放知识格式的落地路径/img_2.png)

_这张图对应的是 OKF 的最小交换约定。_

看  `SPEC.md`  中的规范，OKF 定义的是 `知识包` 这个分发单元：一包知识就是一棵目录树，里面放 Markdown 概念文档；每个非保留概念文档都要带 YAML 头部元数据， `type`  必填，文件路径就是概念 ID， `index.md`  和  `log.md` 是保留文件名。对消费端的要求也写死了：遇到未知 `type` 、额外字段、失效链接，或者缺失 `index.md` ，都要尽量读取，不能轻易拒收。[3]

这些约束只负责交换层：知识怎么打包、怎么交换、怎么再被别的系统读进去。知识平台怎么建、语义层怎么统一，都不在这份规范里。整个仓库也是按这个边界走的：先把交换层钉住，再补写入端、消费端和产品接入样板。[2][3]

![](附件资源/图解谷歌OKF（Open%20Knowledge%20Format）仓库，理解开放知识格式的落地路径/img_3.png)

_这张图把角色拆开看：输入源提供上下文，写入动作通常由智能体执行；消费端不只 `viewer`  查看器，也可以是智能体或别的 AI 应用。_

这里的“写入端”和“消费端”不要按传统前后端去理解。写入端指的是把源系统知识整理并写成 OKF 知识包的一侧，真正执行写入动作的往往是知识补全智能体；BigQuery、网页资料这些更多是输入源。消费端则是任何会读取、遍历和利用这包文件的系统，不只 `viewer` ，也可以是智能体、RAG、搜索索引，或者 Knowledge Catalog 这样的目录系统。AI 在两边都参与，只是写入和消费的角色不同。[2][3]

## 谷歌在示例仓库里铺了四层落地样板

### 第一层是规范：先把交换约定写死

仓库的  `SPEC.md` 规范写的很克制。它不是发明一套大而全的类型体系，也没有绑定服务、数据库或界面，只把写入端和消费端之间最小的知识包交换约定定下来。[3]

约定其实很短。写入端要写对：非保留  `.md` 文档必须有可解析的头部元数据， `type` 不能为空；消费端要宽读：未知字段、未知  `type` 、断链、缺少 `index.md` ，都不能直接判死。OKF 从一开始就没有往重平台规范那边走，它先解决的是互操作。[2][3]

![](附件资源/图解谷歌OKF（Open%20Knowledge%20Format）仓库，理解开放知识格式的落地路径/img_4.png)

_一句话说， `SPEC.md` 要求的是：写入端从严，读取端尽量宽读。_

### 第二层是  `reference_agent`  ：谷歌给出了一套 agent 应用示例

 `reference_agent`  是样板 Agent，在真实落地或者开发中我们可以直接参考示例代码的实现逻辑。

它的定位是 `概念验证版` 应用：

-  `enrich`  演示怎么把源数据和网页资料写成 OKF 知识包。
-  `visualize`  演示怎么把这包文件消费成可交互的单文件查看器。

也就是说，谷歌这一层给出的不是 OKF 本体，而是一套覆盖写入和消费的 agent 应用示例。[2]

![](附件资源/图解谷歌OKF（Open%20Knowledge%20Format）仓库，理解开放知识格式的落地路径/img_5.png)

_这张图把  `reference_agent` 拆成两条线： `enrich`  负责写入， `visualize` 负责消费；两边都围绕同一个 OKF 知识包。_

看模块分工也不复杂：[2]

-  `sources/bigquery.py`  负责读 BigQuery 元数据
-  `agent.py`  拆成 BigQuery 智能体和网页摄取智能体
-  `runner.py`  串写入流程并重建  `index.md`
-  `viewer/generator.py`  负责把知识包转成  `viz.html`  ，
-  `cli.py`  则提供  `enrich`  和  `visualize`  两个入口。

> 注意这里别把  `BigQuery`  理解成 OKF 的通用名词。它不是 OKF 规范的要求，但在当前这份  `reference_agent` 实现里， `bq`  也是唯一内置的数据源。[2][3]

写入侧可以拆成两段：

- BigQuery 轮（  `BQ pass`  ）先只用 BigQuery 元数据，为每个概念生成一份 OKF 文档。
- 网页轮（  `web pass`  ）再拿显式给定的种子网址去抓权威页面，在页面预算、域名白名单和深度限制内，决定是补现有文档、单独生成  `references/<slug>`  ，还是直接跳过。 [2]

![](附件资源/图解谷歌OKF（Open%20Knowledge%20Format）仓库，理解开放知识格式的落地路径/img_6.png)

_这张图只压缩了  `reference_agent` 的写入侧： `enrich`  负责把源数据和网页资料整理成 OKF 知识包。_

这里要分开看两层。OKF 本身是厂商中立格式，不绑定特定智能体、框架、模型提供方或服务系统；而在 `reference_agent`  这套应用示例里，写入侧是 `reference_agent enrich --source bq + web pass` ，消费侧是 `reference_agent visualize` 生成单文件查看器。[2]

在自己项目中落地，你可以继续用这套应用，也可以换成基于 Codex、Claude Code，或者别的智能体框架的写入端和消费端；前提只有一个，就是最后写出来、读进去的知识包还守住同一份 OKF 约定。 `reference_agent`  不是 OKF 本体，而是谷歌先交出来的最短可跑应用示例。[2][3]

### 第三层是  `bundles`  和复现配方  `samples`

这一层是仓库里已经生成出来的样例产物 `bundles/` ， `samples/` 只是复跑这些样板时附带的一层配方。[2]

仓库直接挂了三组公开样例： `GA4 Google Merchandise Store` 、 `Stack Overflow` 、 `Bitcoin public datasets` 。每组都对应一份样例说明和一份已经生成好的知识包。[2]

拿一组看结构就够了：

-
-
-
-
-
-
-
-
-

```bash
samples/<name>/├─ README.md     # 跑哪个外部数据集、用什么 enrich 命令└─ seeds.txt     # web pass 的种子网址bundles/<name>/├─ datasets/├─ tables/├─ references/├─ index.md└─ viz.html
```

重点不在配方本身，而在谷歌把“输入长什么样”和“产物长什么样”一起摆出来了。前者是可复现说明，后者才是 OKF 真正要交换和消费的东西。 `samples/`  里选用的 GA4、Stack Overflow、Bitcoin 也只是示例源。

从 OKF 的设计边界看，如果你自己实现写入端，完全可以换成 API 文档、数据库模式、产品帮助中心，或者内部知识页面。[2][3]

查看器（ `viewer` ）本身也没被做成重产品。 `src/reference_agent/viewer/generator.py` 生成的是一个单文件、自包含的 HTML 页面，包括图结构、头部元数据、渲染后的 Markdown、反向链接、搜索、类型筛选。它就是  `reference_agent` 这套应用里的概念验证版消费端，用来证明知识包一旦生成，已经能被浏览、跳转和消费。[2]

![](附件资源/图解谷歌OKF（Open%20Knowledge%20Format）仓库，理解开放知识格式的落地路径/img_7.png)

_这就是  `viz.html` 的实际样子：左侧把知识包渲染成概念图谱，右侧直接展开当前文档的头部元数据、正文、模式和示例查询。_

### [可选] 第四层：通过  `mdcode`  把知识包接进 Knowledge Catalog

这一层讲的是怎么消费 OKF 的知识包。你知不知道 Knowledge Catalog 本身并不重要，先把它理解成 Google Cloud / Dataplex 里的一种目录型消费端就够了；关键在于它不直接读知识包，而是要先过一层 `mdcode`  桥接。前面三层已经够你理解 OKF，也够你把知识包写出来并直接消费；这一层只是“接特定产品”的可选分支。[4][5][6]

到这里，其实可以把消费端分成两类：

- 直接消费知识包：像  `viz.html`  、智能体、RAG、搜索索引这种，本身就认 OKF 的目录、Markdown、头部元数据和链接，不需要桥接层。
- 映射后再消费：像 Knowledge Catalog 这种有自己对象模型的产品，不直接吃“裸知识包文件夹”，中间要先过一层桥接或映射。 [2][4][5][6]

![](附件资源/图解谷歌OKF（Open%20Knowledge%20Format）仓库，理解开放知识格式的落地路径/img_8.png)

_第四层是这条桥：先把知识包映射成目录模型，再通过 `kcmd push`  发布到 Knowledge Catalog。_

 `mdcode demo` 展示的就是第二种（映射后再消费）。 `catalog/`  里预放了一套 GA4 知识包， `setup.ts`  创建 Dataplex  `EntryGroup` 并写出  `catalog.yaml` ，再把知识包里的 Markdown 文档映射成 Dataplex 的  `entry / aspect`  模型：每个  `.md` 对应一个  `entry` ， `entry`  名镜像文件路径，正文进入 `dataplex-types.global.overview` ，头部元数据里的自定义 `type:`  如果不是合法的 Dataplex 类型引用，就回退到 `dataplex-types.global.generic` 。[5][6]

所以这条链真正闭合时，走的是：

 `OKF 知识包 -> mdcode 目录快照 -> kcmd push -> Dataplex EntryGroup / aspects`

如果你的消费端能直接读知识包，第四层就可以跳过；只有消费端不直接认知识包，或者你真要接目录产品、治理系统和现有目录系统时，才需要继续走这层适配。[2][4][5][6]

## 总结：怎么落地？

在我们自己的项目中落地或者搭配其他Agent使用，不要着急搭平台，也别先搞什么大一统知识体系。最短路径就两段：先把知识包做出来，再判断消费端是直接读，还是要桥接后再读。

> 如果放到 Codex、Claude Code 这类智能体环境里，我更倾向于把 OKF 做成一组 skill：写入 skill 负责按约定生成概念文档、补头部元数据、维护 `index.md`  和链接；读取 skill 负责遍历知识包、按类型筛选、追踪反向链接，再把相关概念装进上下文。这样 OKF 就不只是“文件夹格式”，而会变成智能体可以反复调用的一套知识读写动作。

![](附件资源/图解谷歌OKF（Open%20Knowledge%20Format）仓库，理解开放知识格式的落地路径/img_9.png)

_先写出最小知识包，再决定是不是要接桥接层；平台接入应该放在最后，不该放在最前。_

- 先挑一个边界清楚的知识子域和数据源，数据库、API 文档、帮助中心、内部知识页都可以。
- 先决定写入端怎么来。想复用现成样板，就从  `reference_agent enrich --source bq`  这条链起；如果你的源不是 BigQuery，就保留同样的知识包约定，自己补数据源适配器，或者在 Codex / Claude Code 里封装成 OKF 写入 skill。 [2][3]
- 先把一包最小可用的知识包写出来，重点不是写满，而是先把头部元数据、链接、  `index.md`  和类型约定跑通。
- 先用  `viz.html`  、智能体、RAG 或搜索去直接消费它，检查这包文件能不能读、能不能跳、能不能查。
- 如果消费端能直接读知识包，这里就够了；只有消费端不直接认知识包，或者你必须接目录产品、治理系统和现有目录系统时，再加桥接层，比如  `mdcode`  或自己的适配器。 [2][4][5][6]

## 引用链接

_[1] Google Cloud Blog, How the Open Knowledge Format can improve data sharing: https://cloud.google.com/blog/products/data-analytics/how-the-open-knowledge-format-can-improve-data-sharing_

_[2] GoogleCloudPlatform/knowledge-catalog OKF README: https://github.com/GoogleCloudPlatform/knowledge-catalog/tree/main/okf_

_[3] Open Knowledge Format v0.1 SPEC: https://raw.githubusercontent.com/GoogleCloudPlatform/knowledge-catalog/main/okf/SPEC.md_

_[4] Metadata as Code README: https://github.com/GoogleCloudPlatform/knowledge-catalog/tree/main/toolbox/mdcode_

_[5] Metadata as Code Demo README: https://github.com/GoogleCloudPlatform/knowledge-catalog/tree/main/toolbox/mdcode/demo_

_[6] OKF demo setup.ts: https://github.com/GoogleCloudPlatform/knowledge-catalog/blob/main/toolbox/mdcode/demo/okf/setup.ts_

_[7] BigQuery 文档: https://docs.cloud.google.com/bigquery/docs?hl=zh-cn_

_[8] BigQuery 价格: https://cloud.google.com/bigquery/pricing?hl=zh-cn_

推荐阅读：

[谷歌发布OKF（Open Knowledge Format）规范，它与Karpathy的LLM-wiki是什么关系？](https://mp.weixin.qq.com/s?__biz=Mzk0MzY4NzUzMQ==&mid=2247484230&idx=1&sn=9169887ece86b85f82dd2c86c2c8172c&scene=21#wechat_redirect)

[1000页PDF解析不到1秒！1W+星的开源PDF解析项目LiteParse适合接入RAG系统吗？](https://mp.weixin.qq.com/s?__biz=Mzk0MzY4NzUzMQ==&mid=2247484225&idx=1&sn=0dfe2bb43285201f4e391fccb47126f8&scene=21#wechat_redirect)

[图解 “Loop Engineering” | 智能体的四层循环](https://mp.weixin.qq.com/s?__biz=Mzk0MzY4NzUzMQ==&mid=2247484210&idx=1&sn=dfe605ed1064e79701a6c48c109b7410&scene=21#wechat_redirect)

[拆解开源项目DOCX-Editor，WEB端预览/编辑WORD文件更好的方案](https://mp.weixin.qq.com/s?__biz=Mzk0MzY4NzUzMQ==&mid=2247484163&idx=1&sn=a4e82709308cf126332523a2be97efec&scene=21#wechat_redirect)

[Prompt落伍了？最近都在说"Loop Engineering"是什么，一文带你读懂它！](https://mp.weixin.qq.com/s?__biz=Mzk0MzY4NzUzMQ==&mid=2247484138&idx=1&sn=488dbb06dc30a10b6fc7b4af9a8b3346&scene=21#wechat_redirect)

预览时标签不可点

---
原文链接：https://mp.weixin.qq.com/s?__biz=Mzk0MzY4NzUzMQ%3D%3D&mid=2247484245&idx=1&sn=b3bc610e34d1458ab4e3afe9d814f789&chksm=c3315151f446d84744d3ae4d3b0a1acce6ee3a41ed36b98c32a218c6f219c85c9d76dc689ff2
