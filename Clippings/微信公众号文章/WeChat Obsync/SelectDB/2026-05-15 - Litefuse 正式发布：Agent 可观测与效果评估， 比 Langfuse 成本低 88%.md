---
source_url: "https://mp.weixin.qq.com/s?__biz=Mzg3Njc2NDAwOA==&mid=2247540527&idx=1&sn=8cab803eef180f79971d49ffef1221b8&chksm=ceda836798765db888d634a93ff4e216462a43058c43105491951522c49f7ca9680263bc6519&mpshare=1&scene=1&srcid=05152ovkxrjU6sZR9d6tkjHj&sharer_shareinfo=b68fdcd1445076a6cc6f7e389aef527f&sharer_shareinfo_first=b68fdcd1445076a6cc6f7e389aef527f"
title: "Litefuse 正式发布：Agent 可观测与效果评估， 比 Langfuse 成本低 88%"
account: "SelectDB"
published_at: "2026-05-15T07:42:00.000Z"
saved_at: "2026-07-15T15:27:08.922Z"
sync_id: "art_27794e0cc64742c3939a1ea493639c1c"
parse_status: "ok"
---

# Litefuse 正式发布：Agent 可观测与效果评估， 比 Langfuse 成本低 88%

![](附件资源/Litefuse%20正式发布：Agent%20可观测与效果评估，%20比%20Langfuse%20成本低%2088%/img_1.png)

**导读：****Litefuse 是一个 Agent 可观测与评估平台，通过 Evaluation Driven Development (EDD) “观测-评估-优化”闭环，让 Agent 的执行过程可追踪、问题可定位、效果可量化、优化可验证。**

**Litefuse 兼容 Langfuse SDK 和 100 多个 AI 生态，并支持 Hermes、OpenClaw、Claude Code** 等通用 Agent。

**Litefuse 基于 Apache Doris，存储成本比 Langfuse 降低 88%、简化部署架构、Trace 文本检索效率提升 10 倍，帮助团队以更低成本构建可靠、可持续优化的 Agent 工程体系。**

![](附件资源/Litefuse%20正式发布：Agent%20可观测与效果评估，%20比%20Langfuse%20成本低%2088%/img_2.png)

Agent 时代，开发一个 Agent 正变得越来越容易，真正困难的是：**如何保证它在真实业务中持续可靠地工作**。

传统日志和 APM 可以告诉你接口是否返回成功、延迟是否正常、系统是否稳定，却很难回答：

- Agent 为什么选择了错误的工具？
- 为什么某次任务规划走偏了？
- 为什么同样的问题，这次回答正确，下次却出现幻觉？
- 模型、Prompt、工具或上下文升级后，Agent 的真实效果到底变好了还是变差了？

这正是 Litefuse 要解决的问题。

**Litefuse 是面向 Agent 的可观测与评估平台**，帮助开发者通过 Evaluation Driven Development，也就是 EDD 的“观测 - 评估 - 优化”循环，将 Agent 的运行过程从黑盒变成可追踪、可分析、可量化、可持续改进的工程体系。

_Litefuse 已经正式上线并提供免费使用额度，现在你可以通过下面这一句提示词用 AI Native 的方式让 Agent 自动对接好 Litefuse，开启 Agent 可观测之旅。_

```
Read https://litefuse.ai/SKILL.md and follow the instructions to install and configure Litefuse.
```

![](附件资源/Litefuse%20正式发布：Agent%20可观测与效果评估，%20比%20Langfuse%20成本低%2088%/img_3.png)

01

![](附件资源/Litefuse%20正式发布：Agent%20可观测与效果评估，%20比%20Langfuse%20成本低%2088%/img_4.png)

Agent 的可靠性面临新挑战

在 AI Agent 时代，随着 Coding Agent 能力大幅增强，开发一个 Agent 不难，难的是如何保证 Agent 在实际业务中的运行效果。

Agent 的可靠性面临着比传统软件更大的挑战。一方面，传统软件面临的逻辑正确性、运行健壮性、高峰压力、基础设施稳定性等问题，Agent 作为一个软件也同样存在。另一方面，大模型幻觉、路径规划错误、工具调用失败、上下文记忆腐化等 GenAI 特有的问题，让 Agent 的效果变得不可靠，比如最近 Opus 从 4.6 升级到 4.7 在某些方面反而降智，某次工具升级可能参数和语义发生变化。

![](附件资源/Litefuse%20正式发布：Agent%20可观测与效果评估，%20比%20Langfuse%20成本低%2088%/img_5.png)

要回答这个问题，仅有日志是不够的。开发团队需要看到 Agent 每一步做了什么、为什么这么做、输入输出是什么、最终效果如何，以及这些效果能否被持续量化。

![](附件资源/Litefuse%20正式发布：Agent%20可观测与效果评估，%20比%20Langfuse%20成本低%2088%/img_6.png)

02

![](附件资源/Litefuse%20正式发布：Agent%20可观测与效果评估，%20比%20Langfuse%20成本低%2088%/img_7.png)

从 TDD 到 EDD：Agent 时代需要新的工程方法论

在传统软件时代，Test Driven Development，简称 TDD，是提升软件质量的重要方法。

TDD 通过“增加测试用例 - 写代码通过测试 - 重构优化”的循环，帮助开发者持续保证代码逻辑正确。异常测试、压力测试和传统可观测体系，则进一步保证系统在复杂环境下稳定运行。

对于 AI Agent，通过上面的手段保证系统稳定、逻辑正确的运行还远远不够。因为 Agent 的核心问题不只是 HTTP 接口返回 200、延迟很低，而是：**Agent 的输出是否符合预期？执行路径是否合理？工具调用是否正确？整体效果是否持续稳定？**

因此，Agent 时代需要一种新的工程闭环：Evaluation Driven Development，简称 EDD。

![](附件资源/Litefuse%20正式发布：Agent%20可观测与效果评估，%20比%20Langfuse%20成本低%2088%/img_8.png)

EDD 的核心是**观测 - 评估 - 改进**循环，在这个循环里面：

**1. 观测：Agent 行为不再是黑盒**

Agent 可观测关注的重点，不只是服务是否稳定、接口是否报错、延迟是否变高，而是 Agent 的行为和效果。一次完整的 Agent Trace 应该记录模型请求、用户输入、系统提示词、思考过程、工具调用、检索结果、上下文、输出结果、Token 使用量等关键步骤。有了这些 Trace，开发者可以回放一个具体 bad case 的完整执行过程，也可以将真实线上数据沉淀为后续评估的数据基础。

**2. 评估：Agent 效果可以被量化**

评估基于观测数据和测试数据集进行。评估方法可以是程序规则、人工标注，也可以是 LLM 自动评测。评估数据既可以来自离线构造的数据集，也可以来自线上 Trace 和用户反馈。通过评估，团队可以知道 Agent 在准确性、完整性、安全性、工具调用正确性、任务完成率等维度上的表现。

**3. 改进：对 Agent 效果进行提升**

当评估发现 bad case 后，开发者可以针对 Prompt、工具、知识库、工作流、记忆策略或模型配置进行优化。优化完成后，再通过同一批数据集进行评估，量化判断效果是否真正提升。只有当评估结果达到预期后，再进入线上发布。

**EDD 让 Agent 的效果分析变得更透明、可量化。**Agent 的效果分析不再依赖猜测，而是基于真实运行数据；Agent 的效果好坏不再依赖主观感觉，而是通过真实数据集和评估来量化。

![](附件资源/Litefuse%20正式发布：Agent%20可观测与效果评估，%20比%20Langfuse%20成本低%2088%/img_9.png)

03

![](附件资源/Litefuse%20正式发布：Agent%20可观测与效果评估，%20比%20Langfuse%20成本低%2088%/img_10.png)

Litefuse：将 EDD 产品化的 Agent 可观测与评估平台

EDD 的完整闭环中，改进通常由 Agent 开发团队完成，而观测和评估则需要平台和工具支撑。Litefuse 正是为这个场景设计的。**Litefuse 将 Agent 的 Trace 采集、存储、可视化分析、数据集管理、实验运行和评估流程产品化，帮助开发者以更低成本、更低运维复杂度构建 Agent ****可观测与评估****工作流。**

基于 Litefuse 的 一个典型 Agent Evaluation Driven Development 流程如下：

- 准备一批初始测试数据集 （Dataset），一般也叫做离线测试数据集，可能来源于人类专家构建和标注，包括输入和预期的输出，包括正常 case、corner case、估计对抗的 case 等。
- 开发 Agent。
- 在离线测试数据集运行一次实验 （Experiment），得到 Agent 在每条测试数据上的输出，然后运行评估 （Evaluation），根据测试数据集的输出和 Agent 的输出打分，打分可能是分类、0-1 或者数值分数。这个评估打分过程可以是人工标注，也可以是配置 LLM 和提示词自动完成。
- 评估的结果达到预期可以上线，达不到预期则根据评估产生的 badcase 进行优化，然后再进行评估，直到效果达到预期。
- 上线后通过 Litefuse SDK 对 Agent 进行持续观测，将全量或者采样的观测数据放入在线测试数据集，对这个数据集进行持续评估，一旦发现效果退化，需要分析改进 Agent，再评估达标后进行线上升级。
- 在线测试数据集中有价值的部分，特别是产生 bad case 的数据，再放回离线测试数据集，在主动更新 Agent 比如发布新版本时，用离线测试数据集进行评估效果，判断能否上线。

![](附件资源/Litefuse%20正式发布：Agent%20可观测与效果评估，%20比%20Langfuse%20成本低%2088%/img_11.png)

![](附件资源/Litefuse%20正式发布：Agent%20可观测与效果评估，%20比%20Langfuse%20成本低%2088%/img_12.png)

04

![](附件资源/Litefuse%20正式发布：Agent%20可观测与效果评估，%20比%20Langfuse%20成本低%2088%/img_13.png)

为什么 Litefuse 更适合大规模 Agent 可观测

Langfuse 是一个优秀的 LLM Engineering Platform。它提供丰富的 AI 生态集成，包括大模型厂商如 OpenAI, Anthropic 的 SDK，AI 开发工具如 LangChain, Dify 等 100 多个生态对接，开发者可以很容易和自己的 Agent 集成；在可观测数据建模和用户界面上体现了 AI Native 的元素如 LLM 请求、Tool 调用、Retrieval、Token usage 等，对 AI 开发者、产品等业务角色很友好；还提供了 Prompt 管理和 Evaluation 功能，帮助开发者进行 Agent 评估优化。

**我们在用户访谈的过程中，也发现使用 Langfuse 的一些痛点：**

- 存储成本高。 有的用户反馈几万月活的 Agent 产生了 TB 级的 Langfuse 存储，AI 可观测的成本已经成为整个 Agent 成本中很大一部分，而且现在还是较小 规模，将来扩大 100 倍、1000 倍成本将难以承受。
- 架构复杂。 Langfuse 的架构有 6 个组件，自身服务的 Web 和 Worker，Redis 做队列和缓存，Minio 做写入 buffer，Postgres 做 OLTP 存储元数据，Clickhouse 做 OLAP 存储可观测数据。很多用户反馈部署和维护复杂，特别是在一些交付到客户的场景带来很大的负担，有的用户甚至尝试回退到早期只用 Postgres 的版本，但是损失很多功能体验明显下降。
- 文本检索慢。 Langfuse trace 搜索底层使用数据库 LIKE，LIKE 需要全量扫描数据进行字符串匹配，数据量大的时候 IO 和 CPU 资源消耗很高，查询响应慢。

**因此，我们在 Langfuse 的基础上进行改进推出 Litefuse，存储系统采用 Apache Doris**，为用户带来下面一些收益。

成本降低 88%

在 OpenClaw 短对话、长对话、超长对话等典型 Agent 对话数据测试中，相同数据下，**Litefuse 相比 Langfuse 的存储空间分别降低 65%、88%、88%**。

这意味着，同样的预算下，团队可以保存更多 Agent Trace、更长历史周期，或者支撑更多 Agent 的持续观测与评估。

![](附件资源/Litefuse%20正式发布：Agent%20可观测与效果评估，%20比%20Langfuse%20成本低%2088%/img_14.png)

在高达 88% 的存储空间节省背后，是 Litefuse 和 Doris 针对 Agent 可观测数据的优化。

- Litefuse 使用 Doris VARIANT 数据类型存储 Trace 中的 input output 文本字段，input output 绝大多数情况是 JSON 格式，VARIANT 将 JSON 拆分成字段子列存储，利用列式存储的高压缩比降低存储空间，非 JSON 格式也能自适应存储成字符串。
- Doris 支持存算分离模式，只需要写入一次、存储一份数据，不需要多个副本的存储空间和写入计算资源开销，存储空间和写入计算资源都降低 50%。
- Doris 存算分离模式将数据存储在对象存储或者 HDFS 等廉价的存储上，进一步降低实际付出的存储成本。

架构简洁轻量，单机可以极简到 1 个进程

Litefuse 利用 Doris 的实时写入和服务端 group commit 能力，去掉了原本用于写入缓冲的 MinIO，减少中间写入链路，提升可观测数据实时性。同时，Litefuse 利用 Postgres 插件实现异步队列能力，不再依赖 Redis。**整体架构从 6 个组件减少到 3 个组件。在单机版本中，Litefuse 进一步将组件合并为单进程形态，单机也能轻松处理 TB 基本的数据，团队可以用极简方式完成部署和维护。**

![](附件资源/Litefuse%20正式发布：Agent%20可观测与效果评估，%20比%20Langfuse%20成本低%2088%/img_15.png)

文本检索加速 10x

Agent 可观测场景中，经常有这样的情况，内部测试或者用户反馈了一个 bad case，怎么快速找到对应的 trace 进行分析？通常会根据对话的内容去 input output 里面搜索，对应到产品中如下图的功能。

![](附件资源/Litefuse%20正式发布：Agent%20可观测与效果评估，%20比%20Langfuse%20成本低%2088%/img_16.png)

Litefuse 基于 Doris 倒排索引搜索 trace input output 文本时，能够做到秒级返回，**速度比 Langfuse LIKE 方式提升 5-10 倍**。Doris 早在 2023 年开始支持了倒排索引，被 MiniMax、阶跃星辰、字节、快手、腾讯、阿里、百度、网易等数百家公司大规模应用于 PB 级生产环境。

支持通用 Agent 开箱即用

Litefuse 兼容 Langfuse SDK，保留了对 100 多个 AI 生态的支持，包括 OpenAI SDK、Anthropic SDK、LangChain、Dify 等。**Litefuse 特别增强了对 Hermes、OpenClaw、Claude Code 等通用 Agent 的支持**。通过 Hook 插件，Litefuse 可以采集更丰富的 Agent Trace 信息，并在 Dashboard 中分析 Agent 的执行过程、成本、性能和安全相关指标。

Langfuse 目前还不支持 Hermes Agent，对 OpenClaw 的支持是通过 OpenRouter 采集大模型调用信息，缺失了 Agent 本身的行为数据，对 Claude Code 的支持很简单，比如基础的时间戳不正确不是实际发生时间。

![](附件资源/Litefuse%20正式发布：Agent%20可观测与效果评估，%20比%20Langfuse%20成本低%2088%/img_17.png)

以 Claude Code 为例，当用户输入：

```
research and write a report about agent observability and evaluation
```

Litefuse 可以观测到更完整的执行步骤，包括 user message、thinking、text response 等详细过程；每一步元数据也会被忠实记录，并统一放在  `claude_code`  层级字段下，方便后续查询、分析和评估。

![](附件资源/Litefuse%20正式发布：Agent%20可观测与效果评估，%20比%20Langfuse%20成本低%2088%/img_18.png)

Langfuse

![](附件资源/Litefuse%20正式发布：Agent%20可观测与效果评估，%20比%20Langfuse%20成本低%2088%/img_19.png)

Litefuse

相比只看到模型请求，完整的 Agent Trace 能帮助开发者真正理解 Agent 的行为，并将线上 bad case 转化为可持续改进的数据资产。

![](附件资源/Litefuse%20正式发布：Agent%20可观测与效果评估，%20比%20Langfuse%20成本低%2088%/img_20.png)

05

![](附件资源/Litefuse%20正式发布：Agent%20可观测与效果评估，%20比%20Langfuse%20成本低%2088%/img_21.png)

马上使用 Litefuse 开启 Agent 可观测之旅

**Litefuse 官网和 SaaS 产品已经上线，并提供 10 万条数据存储 1 个月的免费使用额度，现在就可以注册账号立即使用。**

- 官网： https://litefuse.ai
- SaaS 产品： https://litefuse.cloud

如果你正在使用 Hermes、OpenClaw、Claude Code，也可以直接通过一句 Prompt，让 Agent 自动完成 Litefuse 接入：

```
Read https://litefuse.ai/SKILL.md and follow the instructions to install and configure Litefuse.
```

**Litefuse 也已经在阿里云 SelectDB 提供服务**。如果你正在使用阿里云，可以在阿里云 SelectDB 产品中开启独享 Litefuse 实例：

- SelectDB 产品： https://www.aliyun.com/product/selectdb
- Litefuse 实例说明： https://help.aliyun.com/zh/selectdb/enable-datalens-ai

**此外，Litefuse 计划在 6 月 11 日 ****SelectDB 产品发布会上****发布开源版本**。开源版本将支持更轻量的单机部署，单机形态可极简到 1 个进程，可以轻松处理 1TB 以内的数据。

欢迎大家加入 Litefuse 社群，与 Litefuse 的开发者和用户交流 Agent 可观测与评估，打造可靠有效的 AI Agent。

![](附件资源/Litefuse%20正式发布：Agent%20可观测与效果评估，%20比%20Langfuse%20成本低%2088%/img_22.png)

![](附件资源/Litefuse%20正式发布：Agent%20可观测与效果评估，%20比%20Langfuse%20成本低%2088%/img_23.gif)

在 6 月 11 日举行的 **SelectDB 产品发布会**上，我们将进一步分享 Agent Observablity 场景下，SelectDB 的技术思考与进展，同时将介绍 Litefuse 的设计思路及使用演示。

**欢迎关注 SelectDB 产品发布会——面向 Agent 的实时数据引擎，期待和大家一起讨论。**

---
原文链接：https://mp.weixin.qq.com/s?__biz=Mzg3Njc2NDAwOA%3D%3D&mid=2247540527&idx=1&sn=8cab803eef180f79971d49ffef1221b8&chksm=ceda836798765db888d634a93ff4e216462a43058c43105491951522c49f7ca9680263bc6519
