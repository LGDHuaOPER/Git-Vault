---
source_url: "https://mp.weixin.qq.com/s?__biz=Mzg2MzcyODQ5MQ==&mid=2247502254&idx=1&sn=e1cf499e11435f1ce490fdd5c73daeda&chksm=cf9f933dcf2c741890b3b2dd0d6fad5e7821b99a477fc3ec0eebeab9eea6ccd19c95e32fd303&mpshare=1&scene=1&srcid=0612ZxpyTtzjiF0snib352TE&sharer_shareinfo=09fdcd1d0e5d2f4fddb8d8fe0994584b&sharer_shareinfo_first=09fdcd1d0e5d2f4fddb8d8fe0994584b"
title: "Agent 可观测性：为什么有了 LangChain，还会出现 Langfuse？"
account: "叶小钗"
published_at: "2026-06-10T01:00:00.000Z"
saved_at: "2026-07-15T15:23:28.717Z"
sync_id: "art_349ec875e71d40cfb45e082891a3cea5"
parse_status: "ok"
---

# Agent 可观测性：为什么有了 LangChain，还会出现 Langfuse？

> 对AI感兴趣的同学 ，欢迎咨询

上次我们发布了一篇文章，关于Agent的可观测性： [Agent Harness 可观测性](https://mp.weixin.qq.com/s?__biz=Mzg2MzcyODQ5MQ==&mid=2247501724&idx=1&sn=b6d7d1037390e4257725b5781c0cf875&scene=21#wechat_redirect)

评论区有同学说这个和 langsmith、langfuse 是一样的，非常像。

说实话，那篇文章的内容，是我做完公司 Agent 后的一些思考，结合以往的开发经验和 Agent 的一些特性，自己在这里鼓捣出来的，可能都是殊途同归，思路都是一样的。

很久以前我就听说过 langsmith，它是 langchain 的商业化的可观察平台，我们虽然之前也对 LangChain 进行过研究，也有客户团队要求必须使用 LangChain，但我们自己还是习惯于手搓框架，所以对它并不关注，也没有想去了解它。

关于 langfuse，最开始我还以为是 LangChain 公司的开源项目，最后了解了一下，才发现它是由 Langfuse 团队开源的一个 LLM 应用可观察与评估平台。

当我打开 github 的时候，我居然还关注了这个项目！！居然就毫无印象了，看来平时看的东西确实太多了：

![](附件资源/Agent%20可观测性：为什么有了%20LangChain，还会出现%20Langfuse？/img_1.png)

正好，最近我也在开发 **AI 应用开发基座框架**，用来管理模型、提示词这些的的基础应用，今天就让我们去研究下 langfuse 看看它能做些什么。

学习方式都很固定了：先把它部署起来，接入到我们开发的 Agent 里面看看：

## 安装部署langfuse

github官网地址 https://github.com/langfuse/langfuse

langfuse支持云端托管和自托管的方式，云端比较简单，注册账号申请key就可以，有免费额度，如果长期使用就要收费了，数据也需要发送到云端，数据安全也存在一定的风险。

我们这里选择自托管，一个最简单的 docker启动

![](附件资源/Agent%20可观测性：为什么有了%20LangChain，还会出现%20Langfuse？/img_2.png)

从github下载源码后，直接使用docker compose up 启动项目

我在启动的时候遇到了两个端口占用问题，因为我本地有运行redis和php，所以6379和9000 这两个端口被占用，我是临时关停了这两个服务，重新使用docker启动就好了。

启动好了之后，输入 http://localhost:3000/

![](附件资源/Agent%20可观测性：为什么有了%20LangChain，还会出现%20Langfuse？/img_3.png)

一进来，就显示需要注册，登录，我们这里点击`Sign up` 直接注册一个账号进去

![](附件资源/Agent%20可观测性：为什么有了%20LangChain，还会出现%20Langfuse？/img_4.png)

注册完成后，进入管理页面

![](附件资源/Agent%20可观测性：为什么有了%20LangChain，还会出现%20Langfuse？/img_5.png)

进入页面后，我们需要先创建一个机构和项目，这里我们创建了一个 my-org的机构和一个 my-org-agent的项目

然后我们在创建一个API keys，就可以接入项目了。

![](附件资源/Agent%20可观测性：为什么有了%20LangChain，还会出现%20Langfuse？/img_6.png)

这里点击 `Create new APl key`  可以得到一组API的密钥，我们项目接入的时候需要使用。

## 接入项目

我们都知道现在程序员已经离不开 AI Coding 了，所以 langfuse 还是挺人性化的，提供一个接入skills，官方地址：

```
https://github.com/langfuse/skills
```

我们只需要安装这个skills，到我们的AI Coding工具，他就可以帮我们把这个langfuse接入到我们的Agent项目中，让我们试试看效果如何

![](附件资源/Agent%20可观测性：为什么有了%20LangChain，还会出现%20Langfuse？/img_7.png)

我这里使用npx安装，其他同学就随便了，能安装上这个技能就行，安装好了之后，看看CodeX有没有这个技能，有的话就准备让它把langfuse接入到我们开发的Agent中。

![](附件资源/Agent%20可观测性：为什么有了%20LangChain，还会出现%20Langfuse？/img_8.png)

从上图可以看到，Codex已经显示有langfuse这个技能，我们就直接让他开始接入项目了。

```
你需要使用这个技能，把这个项目接入到langfuse，让我可以看到模型调用日志，工具执行日志，常见的指标，提示词由langfuse来进行管理，你需要先梳理好这个项目目前的实现逻辑，给我一个开发计划，需要做哪些改动，等我确认后在执行
```

等CodeX将 langfuse 接入项目后，我们开始使用我们的Agent聊天，写文章之类的任务。等Agent把任务执行完成后，我们可以打开langfuse的面板看看有没有详细的日志显示

![](附件资源/Agent%20可观测性：为什么有了%20LangChain，还会出现%20Langfuse？/img_9.png)

从上图可以看出，langfuse显示了Agent的执行日志，说明我们已经接入成功了。

有一个问题就是 就是cost一直无法显示，我们在Model Definitions配置了模型的价格也无法显示，后面排查是在Agent通过Sdk同步给langfuse的时候，没有把接口返回的usage进行同步，langfuse就没有token的使用记录，所以cost一直显示0，让Codex改一下，把token的消耗同步到langfuse,就可以正常显示cost

![](附件资源/Agent%20可观测性：为什么有了%20LangChain，还会出现%20Langfuse？/img_10.png)

![](附件资源/Agent%20可观测性：为什么有了%20LangChain，还会出现%20Langfuse？/img_11.png)

到这里我们的Agent就接入成功了，相关的Traceing，Sessions，Users面板的数据都可以看到了。

#### 项目改造

CodeX帮我们接入了langfuse，我们来简单看一下，它在我们原有的Agent项目中做了哪些改动。

它并没有大改我们的执行逻辑，我们原来的执行流程是：

用户发送消息 → 组装 system prompt 和历史消息 → 调用模型 → 如果模型返回 tool calls，就执行工具 → 把工具结果塞回上下文 → 再次调用模型 → 返回最终结果。

Langfuse 接入后，这条链路没有被破坏，只是在关键节点上增加了 trace、generation、tool span 。

#### 1. 新增统一的 Langfuse Service

项目里新增了一个统一的 Langfuse service 文件，负责集中管理 Langfuse client，处理 tracing、prompt、score、flush 等相关逻辑。

这样业务代码不需要到处直接引用 Langfuse SDK，只需要和这个 service 交互即可。后面如果要调整 Langfuse 的配置、关闭观测、修改上报逻辑，也都可以集中在这里处理。

#### 2. 对模型调用做埋点

每次真实请求大模型时，都会在 Langfuse 中生成一条 generation 记录，里面会记录：使用的模型，输入信息，模型输出，tool calls，token usage等，这样我们就能在 Langfuse 里看到每一次模型调用的完整上下文，而不是只能看到最终回复。

![](附件资源/Agent%20可观测性：为什么有了%20LangChain，还会出现%20Langfuse？/img_12.png)

#### 3. 记录工具调用过程

Agent 最核心的能力之一就是调用工具，比如读取文件、搜索网页、执行命令等。这次改造中，每一次工具调用就会记一个tool span ，Langfuse 里都会出现一个对应的工具执行记录，会记录工具名称，参数，工具返回结果等

这样我后面就可以在 Langfuse 里看到 Agent 执行任务时中间到底调用了哪些工具、每个工具是否成功、耗时多久等

![](附件资源/Agent%20可观测性：为什么有了%20LangChain，还会出现%20Langfuse？/img_13.png)

#### 4. 用 Trace 串起完整执行链路

记录traceId，在一次完整聊天请求外层增加了 trace，后面所有的模型请求和工具执行都和这个traceId相关，就可以把整个流程串起来。

#### 5. 接入提示词管理

之前系统的提示词是通过agent.md 和上下文拼接起来的，改造之后把这个拼接模版 抽象成了一个  Langfuse prompt：agent/system和agent/memory-flush，后面我们就可以在langfuse的管理台看见这个提示词，运行时优先从 Langfuse 读取 production 版本。如果 Langfuse 没配置，或者 prompt 拉取失败，就回退到本地模板，不影响 Agent 正常运行。

![](附件资源/Agent%20可观测性：为什么有了%20LangChain，还会出现%20Langfuse？/img_14.png)

整体来看，这次改动是给原来的 Agent 执行链路加上一层可观测性。接入之后，每一次模型调用、工具调用、提示词版本和 token 消耗，都可以在 Langfuse 中被追踪和分析。

## langfuse功能详解

上面我们介绍了怎么给Agent或者大模型应用如何接入langfuse，下面我们来详细了解下langfuse有哪些功能模块。

我们 把 Langfuse 运行起来以后，它质上是一个 **LLM 应用观测、调试、Prompt 管理和评估服务**。它并不影响我们的LLM应用程序的执行逻辑，我们只需把Agent执行过程中发生了什么事情，发送给它就行，比如：用户的问题，agent执行了哪些步骤，工具的参数和结果，调用什么模型等等。

Langfuse 收到这些数据后，会把它们组织成 trace、observation、score、session、dataset run 等对象，然后在 UI 里展示成可搜索、可过滤、可聚合的调试和评估界面。

![](附件资源/Agent%20可观测性：为什么有了%20LangChain，还会出现%20Langfuse？/img_15.jpg)

#### 如何接入

上面我们已经通过我们的案例 讲解了如何接入Langfuse，这里我们就不多讲了

想要深入了解的 可以去看官方的文档  https://langfuse.com/docs

#### 数据流转

以一次 LLM 调用为例，看看应用侧把 trace/generation/score 发送到 Langfuse。

![](附件资源/Agent%20可观测性：为什么有了%20LangChain，还会出现%20Langfuse？/img_16.png)

## 能力详解

Langfuse将以下能力整合在一个统一平台中：

- 可观测性（Observability）：追踪 LLM 的调用链、用户交互、检索和工具使用。
- Prompt 管理（Prompt Management）：集中管理、版本控制和协同迭代。
- 评估系统（Evaluations）：自动或人工对模型输出质量进行评估。
- 数据集管理（Datasets）：构建标准化测试集与回归基准。
- Playground 调试环境：交互式优化 Prompt 与模型参数。

这几个能力组合到一起，就构建了一个LLM应用的闭环，可以清楚看到线上发生了什么，再将一些可变的Prompt管理起来，用评估系统判断质量，用数据集稳定复现问题，最后通过Playgroup中的快速验证和修复。

![](附件资源/Agent%20可观测性：为什么有了%20LangChain，还会出现%20Langfuse？/img_17.jpg)

#### 可观测性

可观测性 是langfuse的基础，有了可观察性，团队就可以看到 Agent 的任务结果是怎么一步一步产生的。

在Agent中，问题往往不是出现在最终的回答上，可能是意图分类分错了 ，检索到的结果和问题不匹配，工具调用参数出错了，也可能是提示词升级导致。

Langfuse 用 trace 和 observation 把这些中间过程保存下来。

#### Trace 记录一次完整的交互

Trace表示一次完整的业务交互流程发生的所有事件，比如：

- 用户提问
- Agent一步一步执行任务
- RAG系统完成检索，重排
- 工具执行的输入和输出

一个trace通常表示一次用户请求，用户可能只看到一个答案，但是它的内部可能发生了很多事情

#### Observation：交互里的每个步骤

Observation 是 trace 下的具体步骤。常见类型包括：

- SPAN ：普通业务步骤。
- GENERATION ：一次 LLM 生成。
- TOOL ：一次工具调用。
- RETRIEVER ：一次检索。
- CHAIN ：链式调用。
- AGENT ：Agent 节点。
- EVENT ：一个事件点。
- EVALUATOR ：评估节点。
- EMBEDDING ：embedding 调用。
- GUARDRAIL ：安全或规则检查。

一个 Agent trace 可能是这样的：

![](附件资源/Agent%20可观测性：为什么有了%20LangChain，还会出现%20Langfuse？/img_18.jpg)

#### 用户交互、会话和用户维度

可观测性不只看单次 trace。实际排查问题时，团队经常需要更高层次的视角。

Session 用来把多轮对话串起来。应用只要给多条 trace 带上同一个  `sessionId` ，Langfuse 就可以展示一段完整会话，帮助你判断上下文是否连贯、用户是否反复追问、Agent 是否在中途偏离任务。

User 维度依赖 trace 上的  `userId` 。它适合排查某个客户、某个租户或某类用户的体验、成本和失败率。

Dashboards 则把 traces、observations 和 scores 做聚合，用来观察请求量、延迟、成本、模型分布、score 趋势和 prompt 版本表现。

#### Prompt管理

Prompt管理解决的是另外一个核心问题，LLM应用的行为，稳定性通常由Prompt决定，如果Prompt写死在代码或者配置文件里面，每次修改想要查看效果，还需要重启服务，而且团队也不好协作，回滚提示词和比较不同提示词的效果也不好办。

Langfuse 把 Prompt 集中管理起来。它可以被版本化、打标签、在线读取，并和线上 traces、成本、延迟、scores 关联起来。

#### Prompt 为什么需要平台化管理

在简单 demo 里，把 Prompt 写死在代码中没有问题。但在真实系统里，团队通常会遇到这些情况：

- 产品、运营、工程和算法同学都想参与 Prompt 修改。
- Prompt 需要区分生产、测试和实验版本。
- 线上回答变差后，需要知道当前使用的是哪个版本。
- 修改 Prompt 前后，需要比较质量、成本和延迟。
- 出问题时，需要快速回滚到旧版本。

管理Prompt就是将人工记忆和手动同步的操作，转变为平台内的版本控制与发布流程。

#### Langfuse 中的 Prompt 生命周期

Prompt 数据存在 Postgres 数据库中，读取时会经过缓存以降低运行时拉取成本。LLM应用可以通过SDK 按名称和 label 获取 Prompt，例如生产环境读取  `production`  label，测试环境读取  `staging`  label。

![](附件资源/Agent%20可观测性：为什么有了%20LangChain，还会出现%20Langfuse？/img_19.png)

当 LLM 调用记录进入 Langfuse 后，trace 和 generation 可以关联到具体 promptName 和 promptVersion。这样就可以观察到那个版本的提示词表现更好。

![](附件资源/Agent%20可观测性：为什么有了%20LangChain，还会出现%20Langfuse？/img_20.jpg)

## 评估

LLM 应用最难工程化的部分之一，是输出质量很难被稳定度量。传统服务可以看错误率和延迟，但 LLM 应用还要回答：答案是否正确、是否有帮助、是否安全、是否遵守格式、是否引用了可靠来源。

Langfuse 的评估系统围绕 Score 展开。Score 是所有质量信号的统一载体，它可以来自用户反馈、业务系统、自动评估器或人工标注。

#### Score：评估结果的统一数据模型

Score 可以在不同对象上：

- Trace：评价一次完整交互。
- Observation：评价某个模型调用、工具调用或检索步骤。
- Session：评价一段多轮会话。
- Dataset Run：评价一次实验运行。

Score 也可以有不同类型：

- Numeric：例如 0.87 、 4 、 0.0 到 1.0 。
- Categorical：例如 good 、 bad 、 partially_correct 。
- Boolean：例如 true 或 false 。
- Text：例如人工评论、纠错答案、失败原因。

这样一来，质量就不再只是 感觉好不好 的主观判断，而是变成系统里可以被记录、筛选、统计和对比的数据。后面我们想看哪些回答差、哪个工具经常失败、哪个版本效果更好，都可以直接基于这些 Score 来分析

![](附件资源/Agent%20可观测性：为什么有了%20LangChain，还会出现%20Langfuse？/img_21.jpg)

#### 自动评估：Evaluator

Evaluator 会读取 trace、observation 或 dataset run 的数据，自动产出 score。

![](附件资源/Agent%20可观测性：为什么有了%20LangChain，还会出现%20Langfuse？/img_22.png)

LLM-as-a-Judge 使用另一个模型作为裁判。它读取输入、输出、参考答案、上下文等，然后返回分数和理由。它适合评估 helpfulness、correctness、relevance、faithfulness、toxicity、policy violation 等较难用规则表达的维度。

Code Evaluator 则适合确定性检查，例如输出是否是合法 JSON、是否包含必需字段、是否命中 expected output、是否满足业务规则。它更加便宜、稳定、可重复，但只能覆盖能写成代码的判断。

自动评估的流程如下：

![](附件资源/Agent%20可观测性：为什么有了%20LangChain，还会出现%20Langfuse？/img_23.jpg)

#### 人工评估：Human Annotation

不是所有质量判断都适合自动化。客服、医疗、法律、金融、教育等场景，经常需要领域专家人工看上下文、打分、写评论或提供纠正答案。

![](附件资源/Agent%20可观测性：为什么有了%20LangChain，还会出现%20Langfuse？/img_24.png)

Langfuse 中的 Human Annotation 以 Annotation Queue 的形式工作。队列里每个任务指向一个 trace、observation 或 session，并配置一组需要填写的 score config。

标注员完成任务后，提交的结果会成为 source 为 annotation 的 score。人工评估常见用途：

- 抽样校准自动评估器。
- 为高价值客户的问题做质量复盘。
- 收集纠错答案，后续进入数据集。
- 建立团队对“好回答”的共同标准。

## 数据集DateSets管理

数据集管理解决的是  如何稳定比较改动效果 的问题。

如果团队只看线上零散 trace，很容易陷入个案讨论：这个回答好了，另一个回答坏了，很难判断新新的 Prompt、新模型或新检索策略整体是否更好。Dataset 把样本固定下来，让团队可以重复运行同一批输入，并比较不同版本的输出、成本、延迟和评分。

### Dataset 是什么

Dataset 是一组测试样本。每个 item 通常包含：

- input：给应用的问题或结构化输入。
- expected output：期望答案，可选。
- metadata：场景、难度、用户类型、业务标签等。

示例：

```
Dataset: customer-support-regression

Item 1:
input: "怎么申请退款？"
expected_output: "说明退款条件、入口和处理时效"
metadata: {"category": "refund", "difficulty": "easy"}

Item 2:
input: "我的订单为什么还没发货？"
expected_output: "查询订单状态并解释可能原因"
metadata: {"category": "shipping", "difficulty": "medium"}
```

### Dataset Run 和 Experiment

Dataset 是固定样本集合，Dataset Run 是某一次运行结果。比如：

- prompt-v1 + gpt-4.1 跑一遍。
- prompt-v2 + gpt-4.1 跑一遍。
- prompt-v2 + 新检索策略 再跑一遍。

每次 run 都可以记录输出、关联 trace、写入 scores，并统计成本和延迟。

这样我们就能从 我感觉 v2 更好 变成 v2 在退款类问题上正确率更高，但成本上升了 18%。

![](附件资源/Agent%20可观测性：为什么有了%20LangChain，还会出现%20Langfuse？/img_25.jpg)

#### 数据集从哪里来

数据集我们可以人工自己来创建，也可以从线上Trace中添加，Trace里面有一个 `Add to datasets` 按钮，可以一键添加到数据集里面。

我们通常会把这些样本放进 dataset：

- 线上失败或低分 trace。
- 人工标注给出纠正答案的样本。
- 关键业务流程的黄金样本。
- 边界条件和安全风险样本。
- 每次事故或回归后新增的复现样本。

这样 Dataset 会逐渐成为 LLM 应用的回归测试的资产。

## Playground 调试环境

Playground 是 Langfuse 里的交互式调试环境。

它解决的问题是：线上发现不好 的 case 之后，团队不应该每次都改代码、部署、再观察；更高效的方式是在一个实验台里快速调整 Prompt、模型和参数，确认方向后再保存为可管理的 Prompt 版本。

#### Playground 能做什么

在 Playground 里，用户通常可以：

- 选择模型连接。
- 编辑 system/user/assistant messages。
- 填写 Prompt 变量。
- 调整 temperature、max tokens 等模型参数。
- 配置 tool calling。
- 测试 structured output schema。
- 从 trace 复现一次失败调用。
- 把调试好的内容保存为 Prompt。

它既适合工程师调试，也适合产品、运营和领域专家参与 Prompt 迭代。

![](附件资源/Agent%20可观测性：为什么有了%20LangChain，还会出现%20Langfuse？/img_26.jpg)

## 结语

今天的内容主要在围绕这 Agent 项目的可观测性展开，其实除了 Agent，RAG 也有可观测性，这里我们就不衍生讨论了。

最后，关于 Agent 的知识会有很多，想要系统性学习的同学可以看看这篇文章：

[《生产级 Agent 实践指南》](https://mp.weixin.qq.com/mp/appmsgalbum?__biz=Mzg2MzcyODQ5MQ==&action=getalbum&album_id=4531523924685389828&from_itemidx=1&from_msgid=2247501885&sessionid=#wechat_redirect)

感兴趣的朋友，可以看看这个神秘礼品：

---
原文链接：https://mp.weixin.qq.com/s?__biz=Mzg2MzcyODQ5MQ%3D%3D&mid=2247502254&idx=1&sn=e1cf499e11435f1ce490fdd5c73daeda&chksm=cf9f933dcf2c741890b3b2dd0d6fad5e7821b99a477fc3ec0eebeab9eea6ccd19c95e32fd303
