---
source_url: "https://mp.weixin.qq.com/s?chksm=eae172e1dd96fbf7c9da14af0807b02b73bf414404e0234fb35d698bd4b0f302835a9218eedf&exptype=unsubscribed_card_recommend_item_heat_tlfeeds&ranksessionid=1784740382_1&req_id=1784740381972938&scene=169&mid=2247484251&sn=071a92dfef05fc7776de510b0d179c4e&idx=3&__biz=MzI2OTQ0NTMzMw==&sessionid=1784741001&subscene=200&clicktime=1784741073&enterid=1784741073&flutter_pos=15&biz_enter_id=5&jumppath=1001_1784740998023,1104_1784741002331,20020_1784741047163,1104_1784741072318&jumppathdepth=4&ascene=56&devicetype=iOS26.5.2&version=18004b43&nettype=WIFI&abtest_cookie=AAACAA==&lang=zh_CN&countrycode=CN&fontScale=100&exportkey=n_ChQIAhIQCRQSgSyz4YwXKuUc/9r9BhLhAQIE97dBBAEAAAAAABihEoKpTKkAAAAOpnltbLcz9gKNyK89dVj0CsMoeq9vmAZGTsDsE8UvK9U4yJJeoV0c9ZGBgprVGGx7d+7quWKae78mw1assGXGA+a8VK+vAVfuuuMItu2NHlNNscYRcF+qArmmNVzqdN+at/iwKRH1S7XmphB5f+YT6IFggg9zjkClGfdqUsU4fBvbG7Ra8qUWjkeyUVVqbpc/Cd9uMSAXQq3J0dqCXYY/hHD7M8jKwSTv58NOO+zOBE1VUZ9kubR44rzD2K2lI/zI1KomKolSdQzjXg==&pass_ticket=kTFqX/cbMU+F3U2K/Xysr4Q1px6KTc8f862SEuTot34G/3A2keVk34wp4QEenlq8&wx_header=3"
title: "Agent Wiki的现状与解析"
account: "登链造物"
published_at: "2026-07-22T14:22:27.000Z"
saved_at: "2026-07-22T17:25:32.468Z"
sync_id: "art_acd252e250af467d8a2dc958f6be36c4"
parse_status: "ok"
---

# Agent Wiki的现状与解析

![登链社区](附件资源/Agent%20Wiki的现状与解析/img_1.gif)

> 内容摘要与导读： 介绍由Andrej Karpathy提出的LLM Wiki模式，即利用大语言模型在数据摄入时编译知识为持久化的Markdown页面，并在源变化时维护更新，避免在每次查询时重复推导。这种模式被Cognition（DeepWiki）、Factory（AutoWiki）、LangChain（OpenWiki）和Garry Tan（GBrain）四个团队独立实现，形成了一致的架构：原始源不可变、LLM生成的wiki、以及描述组织方式的配置文件。

![image-20240930222847819.png](附件资源/Agent%20Wiki的现状与解析/img_2.jpg)

2026年4月，Andrej Karpathy发布了一个GitHub Gist，描述了一种他称之为LLM Wiki的模式。

在接下来的几个月里，四个不同的团队不约而同地实现了同样的想法：@cognition 构建了DeepWiki，@FactoryAI 构建了AutoWiki，@Langchain 开源了OpenWiki，而Garry Tan开源了GBrain。不同的公司，不同的用户，同一种架构。

一个LLM读取一组资料，将它们编译成一组持续维护的Markdown页面，并随着资料的变化保持这些页面的最新状态。然后，Agent读取这些页面，而不是针对每个问题都从原始素材中重新推导一切。

这种模式已经成为一个类别，建立在它之上的系统越来越多地被简称为Agent维基。这就是它的本质、各团队的实现、它的局限，以及它常被误解的一点。

## ![](附件资源/Agent%20Wiki的现状与解析/img_3.png) 核心理念：在摄入时编译，而不是在查询时编译

从问题开始说起，因为这种模式直接回应了它。

![image-20240930222847819.png](附件资源/Agent%20Wiki的现状与解析/img_4.jpg)

给模型提供知识体的默认方式是检索。你上传文档，分块并嵌入，在查询时提取相关块并回答。它有用，但有一个结构性的缺陷：没有任何积累。每个问题都从原始块开始，模型一遍又一遍地重新推导相同的理解，关于代码库的第十个问题并不比第一个更便宜或信息更充分。

LLM Wiki将合成时机反转了。它不是从原始片段在查询时组装知识，而是让LLM在摄入时一次性将知识组装成持久化的页面，然后维护它们。当新资料到达时，模型读取它，更新它触及的实体页面，修改摘要，并就与已有内容的矛盾做出标记。

RAG在每个问题上重新推导知识。维基一次性推导并保持最新。两者都是合理的；区别在于你何时支付合成成本以及结果是否持久。

该架构始终是三层。原始资料是不可变的：文章、论文、仓库、数据。模型读取它们但从不编辑。维基是LLM生成的Markdown，完全由模型拥有：摘要、实体页面、概念页面、交叉引用。模式是一个配置文件（CLAUDE.md、AGENTS.md或类似文件），告诉模型维基是如何组织的以及要运行什么工作流，这正是使其成为一个有纪律的维护者，而不是一个拥有文件访问权限的聊天机器人。

![image-20240930222847819.png](附件资源/Agent%20Wiki的现状与解析/img_5.jpg)

在其上运行三种操作：摄入一个资料并将其归档到受影响的页面；查询维基（可选地将好的答案作为新页面归档，这样探索也会累积）；以及lint——定期检查矛盾、过时声明和孤立页面的过程。

## ![](附件资源/Agent%20Wiki的现状与解析/img_6.png) 为什么它有效：瓶颈从来都不是写作本身

人类维基会腐烂，原因很具体。困难的部分从来都不是阅读资料或拥有洞察力，而是簿记工作：更新交叉引用、保持摘要最新、将一个新文档与四十个现有页面进行协调。这项工作是无边界的、不吸引人的，并且是一个忙碌团队首先放弃的东西。所以维基会衰败，人们不再信任它，它就会消亡。

而这正是语言模型不介意的工作。它不会厌倦，不会忘记更新交叉引用，并且可以在一次处理中修改十五个文件。LLM Wiki之所以有效，是因为它消除了之前杀死每个维基的维护成本。

这个想法比工具更古老。Vannevar Bush在1945年描述了Memex：一个经过策划的个人文档存储库，并在它们之间建立关联路径。Bush未解决的问题是谁来维护这些路径。八十年后，答案是模型。

## ![](附件资源/Agent%20Wiki的现状与解析/img_7.png) 这个模式是如何得名的

Karpathy的Gist值得直接阅读，因为它比大多数总结更精确。他对普通文档工作流的抱怨是："LLM在每个问题上从零开始重新发现知识。没有积累。"他的替代方案是编译而不是检索，这样"知识被编译一次并保持最新，而不是在每个查询上重新推导"，产生了他所谓的"一个持久的、不断累积的产物"。

关键是，你不需要编写它。"你从不（或很少）自己写维基，LLM编写并维护全部。"他自己的设置是Agent在一侧，Obsidian在另一侧，实时观看页面更新："Obsidian是IDE；LLM是程序员；维基是代码库。"

这个Gist还特别提到了规模，这是最值得记住的细节。先索引且不使用嵌入的方法"在中等规模（约100个来源，约几百个页面）下效果出奇地好，并且避免了基于嵌入的RAG基础设施的需要。"超过这个规模，它建议添加搜索，特别是qmd，描述为"一个用于Markdown文件的本地搜索引擎，具有混合BM25/向量搜索和LLM重排序"。

这更像是一个范围界定规则，而不是对检索的替代。在语料库规模较小时跳过检索基础设施，随着其增长再添加回来。编译时和查询时合成处于一个光谱上，你在光谱上的位置主要取决于你有多少材料。

工程问题在于该模式在个人规模之外是什么样的，而过去几个月已经给出了答案。

## ![](附件资源/Agent%20Wiki的现状与解析/img_8.png) 各实验室实际构建了什么

这就是模式从想法变成工程的地方，而各实现之间的差异正是有用的部分。

Cognition：DeepWiki，作为公共设施的维基

@cognition_labs 采用了这个模式，并将其指向GitHub上的每个公共仓库。在任何公共仓库URL中将 github.com 替换为 deepwiki.com，你就会得到一个该代码库的生成且可导航的维基：架构概览、文件索引、依赖关系图、搜索，以及返回源码的链接（来源：Cognition）。

有两件事很突出。规模是真实的：从MCP到LangChain，超过50,000个顶级公共仓库已经被索引。而且维基并不是产品的终点，它是Agent的检索基础设施。Devin使用维基在代码库中定位相关上下文，因此DeepWiki是编译层，使Devin的代码搜索更有依据（来源：Devin Docs）。

Factory：AutoWiki，作为构建产物的文档

@FactoryAI 以CI术语描述了相同的模式，他们的框架是该类别中最锐利的线条：文档应该是构建产物，而不是副项目。它从源码构建，围绕代码库的实际工作方式组织，并在仓库更改时刷新（来源：Factory）。

![image-20240930222847819.png](附件资源/Agent%20Wiki的现状与解析/img_9.jpg)

生成方法是四个中最明确进行工程化的。AutoWiki运行两遍分析：对README、包清单、CI配置和入口点进行结构扫描，然后对路由、API端点、服务类、数据库模式和特性开关进行更深入的语义扫描。工作被分配给专门的Agent，每个Agent只负责仓库的一个方面，并且有足够的上下文来生成一个好的页面，这正是对单Agent文档生成在大规模下平庸的上下文问题的直接回答。

时效性被作为基础设施而非纪律来处理： `/wiki`  按需重新生成， `/install-wiki`  编写一个CI工作流，在每次推送到默认分支时刷新维基。对于GitHub仓库，它同步到仓库自己的维基标签页（来源：Factory Docs）。

LangChain：OpenWiki，从代码到一切的飞跃

@LangChainAI 开源了OpenWiki作为一个CLI，用于为代码库编写和维护Agent文档，然后将其扩展为OpenWiki Brains，具有两种模式：Code Brain（原始的仓库用例）和Personal Brain（从你自己的连接来源构建维基）（来源：LangChain）。

第二种模式是重要的举动。Personal Brain从Gmail、Notion、git仓库、X、Hacker News和网络搜索中摄入，并将它们合成为一个供Agent查阅的本地Markdown维基。该类别从"记录我的仓库"跳跃到"编译我的工作生活"。

有一个设计细节值得注意，因为每个团队都达成了共识：输出不是供人类阅读的散文，而是针对LLM上下文优化的结构化Markdown，包含标题、交叉引用和摘要，设计目的是使Agent能够快速找到相关上下文。维基是为实际阅读它的读者编写的，而这个读者是模型。

GBrain：个人规模的开源版本

Garry Tan的GBrain将相同的形式应用于个人知识库而非代码库：git仓库中的Markdown、一个模式文件，以及一个自动维护的实体交叉链接图。它最清楚地证明该模式本质上非常简单。没有向量数据库，没有服务，只有文件——由模型维护，且人类可以阅读。

### ![](附件资源/Agent%20Wiki的现状与解析/img_10.png) 技术矩阵

![image-20240930222847819.png](附件资源/Agent%20Wiki的现状与解析/img_11.jpg)

| 实现 | 语料库 | 模式 | 刷新 | 格式 |
| --- | --- | --- | --- | --- |
| DeepWiki | 公共GitHub仓库 | 推断的 | 按需 | 用于Agent的HTML/MD |
| AutoWiki | 你的代码库 | AGENTS.md | CI推送 | 仓库维基的MD |
| OpenWiki | 代码 + 个人 | config.yaml | 按需 | 本地目录的MD |
| GBrain | 个人知识库 | brain.yaml | 按需 | 仓库的MD |

向下阅读各列，趋同就是信号。四个团队，四个语料库，同一种架构：git中的Markdown，模型遵循的模式文件，摄入时合成，变更时刷新，以及为Agent阅读而编写的页面。当解决不同问题的独立团队落在相同的形状上时，这个形状通常是正确的。

差异在于时效性，这是成熟度的标志。Factory将过时视为构建问题并在CI中解决。其他团队按需刷新，这意味着他们的维基只精确到最后一次有人记得运行命令的时刻。

## ![](附件资源/Agent%20Wiki的现状与解析/img_12.png) 它的局限性

这个模式确实很好，因此需要诚实地说明它的边界。

规模。Karpathy自己指出了：先索引且不使用嵌入是一种中等规模技术，大约一百个来源。超过几百个页面，你就回到了搜索引擎，这就是为什么他自己的Gist推荐混合BM25和向量搜索。

保真度。在摄入时编译意味着早期的摘要可能会悄悄丢失来源中的某个细节，并且每个后续的答案都会继承那个损失。对原始块的检索没有这种失败模式。你是在用重新推导成本换取压缩风险。

过时性。一个编译后的页面只在最后一次刷新时是真实的。这就是为什么Factory的CI框架比它看起来更重要的全部原因：一个过时的维基比没有维基更糟糕，因为它以一种看起来权威的格式自信地出错。

编译成本。你预先支付了真正的代币来构建你可能永远不会查询的页面，并重新检查那些什么都没有改变的页面。

## ![](附件资源/Agent%20Wiki的现状与解析/img_13.png) 维基不是记忆

这里有一个值得仔细区分的区别，因为这个领域的词汇仍然松散。

这些系统越来越多地被描述为记忆。LangChain称OpenWiki为AI Agent的维基记忆层，而围绕该模式的一般框架是这就是你给Agent记忆的方式。这个词在那里承载了很大的重量，并且它覆盖了两个相当不同的事物。

两个轴被放在一个术语下。

![image-20240930222847819.png](附件资源/Agent%20Wiki的现状与解析/img_14.jpg)

语料库知识是维基所做的：编译一组文档、或一个仓库、或你的Gmail存档所说的内容。它回答"这个材料体包含什么"。

用户和经验记忆是另一个轴：一个特定的人偏好什么，他们上周决定了什么，他们的团队已经拒绝了哪种方法，一个Agent昨天在另一个应用中尝试了什么以及结果如何。它限定于一个身份而非语料库，从交互而非摄入中积累，并且必须处理每个用户的矛盾、过时、来源和删除。

维基擅长第一个，并且不尝试第二个。将你的Gmail编译成页面告诉Agent你的Gmail里有什么，但它没有告诉Agent你在上周二的一次对话中改变了关于供应商决定的想法，或者一个建议的方法已经在你身上失败过一次。

第二个轴正是像Mem0这样的专用记忆层的作用：标记到用户ID的记忆，因此它跟随一个人跨会话、应用和Agent，当事实变化时在原位更新，而不是无限追加。两者是互补的，错误不在于选择维基，而在于相信因为你编译了一个语料库，你就已经解决了记忆问题。

## ![](附件资源/Agent%20Wiki的现状与解析/img_15.png) 要点

LLM Wiki是一个真实的模式，背后有真正的洞察力：知识应该被编译一次并维护，而不是在每个问题上重新推导，而杀死人类维基的维护工作正是模型免费执行的劳动。四个团队在几个月内交付相同的架构，是它正确的最有力证据。

从中汲取三件事。当语料库稳定且经常被重读时，将你的文档编译成维护良好的页面。当它超过个人规模时，添加真正的检索，原始公式也推荐这样做。并且保持编译语料库和记住用户之间的区别，因为维基给你第一个，而不是第二个。这价值很大，但并不是同一回事。

## ![](附件资源/Agent%20Wiki的现状与解析/img_16.png) 参考文献

Andrej Karpathy, LLM Wiki (GitHub Gist, April 2026)

qmd: local hybrid BM25/vector search for markdown

Cognition, DeepWiki: AI docs for any repo

Devin Docs, DeepWiki

Factory, Introducing AutoWiki

Factory Documentation, AutoWiki overview

langchain-ai/openwiki (GitHub)

LangChain, Wiki Memory

garrytan/gbrain (GitHub)

Vannevar Bush, As We May Think (The Atlantic, 1945)

> - 原文链接： x.com/mem0ai/status/2079... - 登链社区 AI 助手，为大家转译优秀英文文章，如有翻译不通的地方，还请包涵～

登链社区始于 2017 年，通过构建高质量的技术内容平台，助力开发者在 AI 时代成为更好的 Builder。

![登链社区](附件资源/Agent%20Wiki的现状与解析/img_17.gif)

- 登链社区网站: learnblockchain.cn
- Twitter: @UpchainDAO
- B站: space.bilibili.com/581611011
- YouTube: www.youtube.com/@upchain

![登链社区](附件资源/Agent%20Wiki的现状与解析/img_18.gif)

---
原文链接：https://mp.weixin.qq.com/s?__biz=MzI2OTQ0NTMzMw%3D%3D&mid=2247484251&idx=3&sn=071a92dfef05fc7776de510b0d179c4e&chksm=eae172e1dd96fbf7c9da14af0807b02b73bf414404e0234fb35d698bd4b0f302835a9218eedf
