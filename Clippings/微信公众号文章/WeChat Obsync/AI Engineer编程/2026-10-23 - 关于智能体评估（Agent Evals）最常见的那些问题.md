---
source_url: "https://mp.weixin.qq.com/s?__biz=MzIzNTExNzMwNg%3D%3D&mid=2647835237&idx=1&sn=d55e5f29968740a54bf701e73a56c13a&chksm=f0ca6df0c7bde4e65dfac3af23db44b07c8f0f1cf3ae94dd3bb86fd567b250a23c2d97a1afa1"
title: "关于智能体评估（Agent Evals）最常见的那些问题"
account: "AI Engineer编程"
published_at: "2026-10-23 10:17:33"
saved_at: "2026-10-23 12:41:14"
sync_id: "art_0bf27ea0aee54f2eba004ef98aaef0d8"
parse_status: "ok"
---

# 关于智能体评估（Agent Evals）最常见的那些问题

### 智能体评估 关于智能体评估（Agent Evals）最常见的那些问题

![智能体评估常见问题](附件资源/关于智能体评估（Agent%20Evals）最常见的那些问题/img_1.png)

关于本文

原文：The Most Common Questions About Agent Evals, Answered[1]

译文中的配图取自原文，图内文字为英文原文，图注已译为中文。

核心要点

**· ****评估通过对智能体的每次运行打分，帮你确认它的行为是否符合预期。** 上手时，先选定一个行为，用真实追踪记录构建一个小规模数据集，跑出一个基线。上线前用离线评估，上线后用在线评估，并把新出现的失败案例补充进数据集。

**· ****能用代码评估的地方就用代码评估，不能的地方交给 LLM 裁判（LLM-as-a-judge），再用人工评审来校验这两者。** 对于需要多步执行的智能体，要评估完整的会话线程、执行轨迹和最终状态。

**· ****Terminal-Bench 这类基准测试本质上也是离线评估，只是任务更长、且各自带有独立环境。** 它们由 Harbor 运行，结果记录到 LangSmith 实验中。

在构建和发布智能体的过程中，你需要一种手段来确认它的行为符合预期——无论是在开发阶段，还是在真实用户开始依赖它之后。

传统软件中，相同的输入产生相同的输出，因此单元测试（unit test）可以直接断言精确结果。智能体则难测试得多，原因有以下几点：

**· ****同一请求在不同次运行之间输出就可能不同**

**· ****正确答案可能不止一个**，精确匹配（exact match）的检查方式因此失效

**· ****执行步骤由智能体自行决定**，所以输出正确，也可能来自一条“错误”的路径。例如，智能体可能调用了并不需要的工具，或在未获用户授权的情况下执行了操作。

智能体评估正是为此而生：它用能够容纳这些差异的检查项，为智能体的每次运行打分。与被评估的智能体一样，评估方案也没有放之四海而皆准的模板；最合适的评估套件（eval suite）取决于团队、产品，以及他们希望优化的目标。

过去几年在打磨 LangSmith[2]（LangChain 的智能体工程平台）的过程中，我们团队被问到过大量关于评估的问题。本文梳理了其中最常见的一些问题，涵盖如何入门智能体评估，以及工作流（workflow）中可以选用的各类评估方式。

01

应该从哪里入手？

一切评估都始自弄清智能体实际在做什么。一次追踪（trace）记录了智能体的一次完整运行，包括输入、输出，以及其间每一次模型调用和工具调用（tool call）。抽样阅读若干追踪记录，观察它如何处理请求、又在哪些环节出错。这些发现会告诉你应该优先测试什么。起步阶段，宜小不宜大。

**1****选定一个你关心的行为。** 以旅行助手为例，一个行为可以是：它是否按照用户指定的日期和价格区间完成预订。

**2****用追踪记录构建一个小数据集。** 数据集（dataset）是样本的集合，每个样本是一个测试用例（test case），包含输入，通常还包含期望输出。针对一个行为，10 到 20 个样本就足以起步；在 LangSmith 中，可以直接从追踪视图把记录加入数据集。如果智能体尚未上线，可以让团队成员或一小批可信的设计合作伙伴（design partner）先试用（即 dogfooding，内部先用自己的产品），并基于这些追踪记录开展工作。

**3****跑出一个基线（baseline）。** 让当前版本的智能体在该数据集上运行，并把结果保存为一次实验。一次实验（experiment）包含某个版本智能体在数据集上的运行结果，以及各评估器给出的分数。后续版本的表现都将与这次实验对比。

**4****发现失败案例就随手补充。** 生产环境或测试中遇到的每一次失败，都应成为一个新的样本。

![价格是对的，但智能体查错了日期。这条追踪记录会成为数据集中的一个新样本。](附件资源/关于智能体评估（Agent%20Evals）最常见的那些问题/img_2.png)

价格是对的，但智能体查错了日期。这条追踪记录会成为数据集中的一个新样本。

持续把失败案例补进数据集，你就拥有了一个改进闭环：发现问题、加入数据集、改进智能体、重新运行。随着需要评估的行为越来越多，你可以沿用上面的做法逐步扩充评估套件。

02

离线评估与在线评估有什么区别？

评估既可以在变更发布前运行，也应该在智能体上线后运行。上线前，评估能判断某次改动是让智能体变好还是变差；上线后，评估能反映它在真实用户场景下的表现。

**离线评估**在发布变更之前，让智能体在数据集上跑一遍。示例输入由你选定，也可以附带期望输出（expected output），也就是参考输出。借助数据集，你可以跨智能体版本对比实验结果。它最适合用来验证新的提示词（prompt）、模型或工具，并在问题触达用户之前拦住回归（regression）。

Terminal-Bench[3] 这类基准测试同样是离线评估，它基于一组固定任务构建，便于横向对比不同的智能体、模型或版本。这类基准测试由 Harbor 运行，结果记录到 LangSmith 实验中，后文会详细展开。

**在线评估**对流入的生产追踪记录实时打分。这类评估通常没有可供比对的参考输出（reference output），因此依赖代码检查和能够独立评判单次运行的 LLM 裁判。它最适合用来监控质量，并发现数据集尚未覆盖的问题。

两者缺一不可，而且互为输入：在线评估标记出的失败案例，会成为离线数据集中的新样本。

![旅行助手的离线评估与在线评估示例](附件资源/关于智能体评估（Agent%20Evals）最常见的那些问题/img_3.png)

旅行助手的离线评估与在线评估示例

旅行助手的离线评估与在线评估示例。

在 LangSmith 中，为离线评估构建数据集[4]有多种方式：从零手写样本；从已有追踪记录中添加运行；导入团队在标注队列（annotation queue）[5]中审核过的运行；上传 CSV 或 JSONL 文件；或者以少量已有样本为基础生成合成样本（synthetic example）。

随着评估套件不断扩大，你需要决定是把样本加进已有数据集，还是新建一个。大致的原则是：

**· **如果样本针对**同一行为、使用同一组评估器**，就放在**同一个数据集**里，这样历次实验之间才能保持可比性。

**· **如果输入形态不同（例如单轮请求与完整会话）、需要不同的评估器，或数据集的用途不同，就**新建数据集**——比如“每次提交 PR（pull request）都跑的小规模集”与“发布前跑的大规模集”。

在单个数据集内部，还可以用划分（split）只运行其中一部分样本。

03

智能体评估器有哪些类型？

评估器（evaluator）是给一次运行打分的逻辑。常见的有四类，多数团队会先从一两类做起，再逐步增加。

**· ****代码评估器（code evaluator）**以确定性的方式做检查，例如预订价格是否在用户预算之内。它速度快、成本低、结果稳定，但它要求输入和输出都是确定性的，这也限制了它的适用范围。

**· ****LLM 裁判（LLM-as-a-judge）**用模型来评判代码难以判断的内容，例如助手的回复是否清晰地确认了航班信息。

**· ****人工评审（human review）**由团队成员或领域专家直接给运行打分。它更慢，但在判断主观质量、校验其他评估器方面，是最好的信号。它通常只用在一小部分样本上，其结论再用来指导 LLM 评估器的判断。

**· ****成对比较评估器（pairwise evaluator）**把两个输出并排比较，选出更好的那个，适合在两个提示词或两个模型之间做取舍。

![按评估器类型划分，你可能提出的问题](附件资源/关于智能体评估（Agent%20Evals）最常见的那些问题/img_4.png)

按评估器类型划分，你可能提出的问题

按评估器类型划分，你可能提出的问题。

上述任何一类评估器，都可以作用于智能体运行过程中的不同部分。评估对象可能是：

**· ****单个步骤。** 例如 search_flights 是否以正确的日期被调用。

**· ****最终回复。** 例如回复是否确认了智能体实际预订的航班。

**· ****完整对话。** 例如最终预订是否反映了用户在多轮对话中提出的每一处变更。

**· ****环境终态（end state）。** 例如智能体在独立容器（container）中运行后，模拟（mock）预订系统里的预订记录。基准测试常用这种设置，有时也被称为容器化评估。

04

LLM 裁判可信吗？

LLM 裁判用模型来评判那些难以用代码验证的输出，例如答案是否有检索到的文档支撑。裁判很灵活，但也可能不稳定，甚至与团队的判断出现偏差。养成以下几个习惯可以让它更可靠：

**· ****让裁判与人工评分对齐。** 请团队成员给一批运行打分，检查裁判在哪些地方与人不一致，然后调整裁判的提示词或示例，直到两者吻合。LangSmith 的标注队列[5]让这件事变得简单，我们的 LLM-as-a-judge 文档[6]也给出了完整流程。

**· ****问具体、聚焦的问题。** 在旅行助手的例子里，“回复是否提到了每一段中转？”比“这个回复好吗？”更容易判断。

**· ****定义精确的评分尺度（scoring scale）。** 二元的通过/不通过（pass/fail），或一小组带标签的类别，远比 1–10 分制（1–10 scale）更可复现。裁判往往很难区分 6 分和 7 分。

![采用 1–10 分制的评估器（描述性差、容易大幅波动）与一组二元评估器的对比](附件资源/关于智能体评估（Agent%20Evals）最常见的那些问题/img_5.png)

采用 1–10 分制的评估器（描述性差、容易大幅波动）与一组二元评估器的对比

采用 1–10 分制的评估器（描述性差、容易大幅波动）与一组二元评估器的对比。

05

评估和基准测试是一回事吗？

基准测试（benchmark）是离线评估的一种，由一组任务（task）组成。任务即基准测试中的一个测试用例，包含指令、容器中的运行环境，以及为结果打分的测试脚本（test script）。随着智能体能力增强，单纯的 LLM 裁判或基于代码的评估往往不够用了：智能体现在可以执行代码、编辑文件、对接外部服务。为了模拟这类多步行为，基准测试会在容器中搭建隔离的基础设施，让开发者能在离线环境里，以与生产中相同的方式测试智能体的行为。

与更简单的 LLM 裁判和基于代码的评估相比，基准测试的差异在于：

**· ****任务步骤更多。** 为完成单个任务，智能体可能需要安装依赖包（package）、编辑文件、执行命令，涉及数十次工具调用。

**· ****每个任务自带环境。** 智能体如今可以在带有代码仓库（repo）、文件和工具的沙箱（sandbox）等环境中执行操作。每个任务都配有独立的隔离环境，供智能体在其中工作。

**· ****评分检查的是智能体的行为。** 测试脚本在运行结束后检查环境状态，例如测试是否通过、目标文件是否存在。你仍然可以查看追踪记录，但分数来自智能体执行的动作以及它留下的状态。

对旅行助手来说，一个基准任务可能会给它一套模拟预订系统和一条请求：“暴风雪取消了旅客飞往丹佛的航班，请重新预订，并同步调整酒店。”智能体完成后，测试脚本会检查数据库（database）中的预订记录。

![每个基准任务都有独立环境。测试脚本检查智能体留下的状态，Harbor 则把各任务的结果统一记录到一次 LangSmith 实验中。](附件资源/关于智能体评估（Agent%20Evals）最常见的那些问题/img_6.png)

每个基准任务都有独立环境。测试脚本检查智能体留下的状态，Harbor 则把各任务的结果统一记录到一次 LangSmith 实验中。

Harbor[7] 是一个开源的评估执行框架（eval harness），为这类长程任务提供测试所需的脚手架。它也是驱动 Terminal-Bench 的框架，你可以用同样的任务格式为自己的智能体构建基准测试。借助 LangSmith 集成，每次 Harbor 运行都会记录为一次 LangSmith 实验。Harbor 会为每个任务构建容器，你也可以利用 LangSmith 追踪记录，让每个环境更贴近智能体在生产中面对的真实情况。基准测试结果会与其余评估并列展示，打开任意一次运行，即可同时看到完整追踪和对应分数。

我们正是用这套方案在 Terminal-Bench 2.0 上改进 Deep Agents[8]：通过审阅追踪记录定位失效模式（failure mode），再调整执行框架。我们也用它构建了 IssueBench[9]——面向 LangSmith Engine 的基准测试。每个 IssueBench 任务会给 Engine 一批追踪记录，并评估它是否把正确的记录归入了正确的问题簇。

为自己的智能体构建基准测试，流程与前面的评估相同，只是有几处调整：

**· ****从追踪记录中收集任务。** 在 LangSmith 追踪里找出失败案例，再把每一个转成带独立环境的 Harbor 任务，例如一套填有该用户预订信息的模拟预订系统。

**· ****明确“好”的定义。** 编写 LLM 裁判或基于代码的评估，按你的评分标准（rubric）打分。

**· ****以分数为目标做爬山式迭代（hill climbing）。** 运行智能体，用分数对各项改动做 A/B 测试。你也可以搭一个智能体循环来自动跑完这个流程：修改智能体、重跑基准测试、保留或回滚每一次改动——类似 Andrej Karpathy 几个月前提出的 autoresearch[10] 循环。

06

如何以可控成本评估生产流量？

离线评估跑在固定数据集上，成本可预测。在线评估跑在实时流量上，如果每条追踪记录都交给 LLM 裁判打分，评估成本就会随着每个新用户一起增长。要让成本可控，可以：

**· ****采样与过滤（sampling / filtering）。** LangSmith 的在线评估器[11]可以只对一定比例的流量打分，或只对满足过滤条件的追踪记录打分，例如收到负面用户反馈的那些。

**· ****尽可能使用代码检查。** 检查预订日期是否与请求一致、智能体是否先搜索再下单，这类检查几乎不产生成本。

**· ****换用更便宜的裁判。** 在 Jev-as-a-Judge[12] 实验中，来自 TypeSafe AI 的 Jev 在每一次通过/不通过判定上都与人工标注一致，总成本仅 0.34 美元；作为对比，Claude Sonnet 4.6 为 28.17 美元。

LangSmith 会持续记录在线评估的成本，团队可以随时查看开销。

![按评估器统计的在线评估成本随时间变化](附件资源/关于智能体评估（Agent%20Evals）最常见的那些问题/img_7.png)

按评估器统计的在线评估成本随时间变化

按评估器统计的在线评估成本随时间变化。

07

必须自己构建智能体评估吗？

不必，尤其是当你评估的是智能体的常见问题时。一个不错的起点是 LangSmith 中预置的 LLM 评估器模板[13]，覆盖幻觉（hallucination）、PII 泄露等典型检查。把它加到数据集或追踪项目中，修改提示词以适配你的智能体即可——比如告诉裁判：我们的旅行助手绝不能预订超出用户预算的方案。

我们的开源包 agentevals[14] 同样内置了针对智能体消息与工具调用的评估器：既可以把智能体调用的工具与参考列表做比对，也可以让 LLM 裁判判断这些步骤是否合理。

你也可以把一个离线评估器复用到多个数据集上，并让它作为在线评估器运行在生产追踪记录上（前提是该评估器不需要参考输出）。

如果评估需要贴合你自己的智能体，Eval Engineering Skill[15] 可以在 Claude Code、Codex 这类编码智能体中运行，读取你的代码仓库和追踪记录，与你一起写出可直接执行的评估。

LangSmith Engine[16] 也能从生产追踪记录中自动生成评估：当它识别出一个问题簇（issue cluster）时，会把失败的追踪记录转成数据集样本，并把参考输出写成断言（assertion）[17]，例如“按用户请求的日期预订航班”。

08

如何评估多轮对话？

许多智能体需要跨多轮工作。例如用户先让旅行助手查航班，随后改日期，再加订酒店。单看每一轮都没问题，但整段对话的结果却可能是错的。

要在 LangSmith 中评估对话，需要在追踪元数据（metadata）里传入 thread ID，这样每一轮都会被归入同一个线程（thread）[18]。线程是同一段对话中一系列追踪记录的集合。有了线程，你就可以挂载在线评估器，在对话结束后对整个线程打分，例如问：“最终预订是否反映了用户提出的每一处变更？”或者“用户是否不得不重复自己的要求？”LangSmith 还会把每个线程以轨迹（trajectory）[19]的形式呈现，按顺序列出每条消息和每次工具调用，且各出现一次。

在离线评估中，你可以把完整对话作为样本存入数据集，也可以用 LLM 模拟用户，从而测试智能体从头到尾处理一段对话的能力。

![每一轮单独看都合理，问题只在整条线程上才暴露出来](附件资源/关于智能体评估（Agent%20Evals）最常见的那些问题/img_8.png)

每一轮单独看都合理，问题只在整条线程上才暴露出来

每一轮单独看都合理，问题只在整条线程上才暴露出来。

09

如何评估最终输出之外的环节？

智能体要执行很多步，最终答案只能反映其中一部分。除了最终回复，你可能还需要检查：

**· ****路径**，即智能体产生的消息与工具调用的序列。

**· ****最终状态（final state）**，例如旅行助手创建的预订记录、它写入的文件，或它对代码仓库所做的改动。

当生产环境中的智能体越来越复杂时，你可能需要一个专门的评估执行框架，尤其是当智能体的“成果”就是它对环境所做的改动时。假设让一个编码智能体修复 bug：LLM 裁判可以读懂它的回复，但最可靠的检查方式，是在智能体结束后运行仓库的测试。要做到这一点，每次测试都需要一份干净的仓库副本，避免运行之间相互干扰——Harbor 会替你做好这些准备。你可以在 LangSmith Sandboxes[20] 中运行用 Deep Agents[21] 构建的智能体，并把每次运行连同其追踪记录一起写入 LangSmith 实验。更多内容见 Harbor x LangChain[22]。

10

如果智能体不是用 LangChain、LangGraph 或 Deep Agents 构建的，还能在 LangSmith 中追踪和评估吗？

可以。LangSmith 不绑定特定框架（framework agnostic），无论智能体用哪种框架构建、甚至完全不用框架，都能追踪和评估。发送追踪记录有几种方式：

**· ****框架集成（framework integration）。** LangSmith 为主流智能体框架[23]提供了集成，例如 OpenAI Agents SDK[24]、Claude Agent SDK[25] 等。

**· ****模型供应商封装（wrapper）。** 如果你直接调用模型供应商，只需给 OpenAI[26] 或 Anthropic[27] 的客户端（client）套一层封装，每次模型调用就会被追踪。

**· ****@traceable 装饰器（decorator）。** 把它加到自己的函数上，例如旅行助手的航班搜索工具，即可追踪智能体的任意步骤[28]。

追踪记录一旦进入 LangSmith，评估对任何框架都是一样的用法：把追踪记录加入数据集、用 SDK[29] 的 evaluate() 函数传入智能体来运行离线实验、为生产流量挂载在线评估器。

11

如何从现有的评估技术栈迁移过来？

不必推倒重来：你已经搭好的大部分东西，都能接着用在 LangSmith 上。

**· ****数据集。** 把现有测试用例以 CSV 或 JSONL 文件上传，或用 SDK 创建。

**· ****代码评估器。** 现有评分函数（scoring function）通常只需少量改动，就能作为 LangSmith 评估器运行。如果你的评估已经以测试形式存在，pytest[30] 和 Vitest[31] 集成可以让你保留原有配置。

**· ****LLM 裁判。** 把现有裁判提示词粘贴到界面中的 LLM-as-a-judge 评估器里，或继续保留在代码中。

**· ****追踪。** LangSmith 兼容任何框架，因此你可以直接从现有智能体发送追踪记录，而无需重写。

12

如何呈现评估结果？

离线实验回答“每一次发布是否带来了提升”，在线评估看板（dashboard）则回答“在生产环境中，性能随时间推移能否稳得住”。在 LangSmith 中，你可以直接对比实验结果，并针对 token 成本、延迟（latency）、评估器分数随时间变化等指标创建自定义看板。基准测试则提供一个稳定的分数，用于跨版本比较模型或智能体。

参考链接

**[1] The Most Common Questions About Agent Evals, Answered**
https://www.langchain.com/blog/common-questions-about-agent-evals

**[2] LangSmith**
https://smith.langchain.com

**[3] Terminal-Bench**
https://www.tbench.ai/

**[4] 构建数据集**
https://docs.langchain.com/langsmith/manage-datasets

**[5] 标注队列**
https://docs.langchain.com/langsmith/annotation-queues

**[6] LLM-as-a-judge 文档**
https://docs.langchain.com/langsmith/llm-as-judge

**[7] Harbor**
https://github.com/harbor-framework/harbor

**[8] Terminal-Bench 2.0 上改进 Deep Agents**
https://www.langchain.com/blog/improving-deep-agents-with-harness-engineering

**[9] IssueBench**
https://www.langchain.com/blog/issuebench-how-we-evaluate-engine

**[10] autoresearch**
https://github.com/karpathy/autoresearch

**[11] 在线评估器**
https://docs.langchain.com/langsmith/online-evaluations-llm-as-judge

**[12] Jev-as-a-Judge**
https://www.langchain.com/blog/jev-agent-evals-langsmith

**[13] 预置的 LLM 评估器模板**
https://www.langchain.com/blog/reusable-langsmith-evaluator-templates

**[14] agentevals**
https://github.com/langchain-ai/agentevals

**[15] Eval Engineering Skill**
https://www.langchain.com/blog/towards-automating-eval-engineering

**[16] LangSmith Engine**
https://docs.langchain.com/langsmith/engine

**[17] 断言**
https://docs.langchain.com/langsmith/assertions

**[18] 线程**
https://docs.langchain.com/langsmith/threads

**[19] 轨迹**
https://www.langchain.com/blog/langsmith-trajectories-tracing

**[20] LangSmith Sandboxes**
https://www.langchain.com/langsmith/sandboxes

**[21] LangChain Deep Agents**
https://www.langchain.com/deep-agents

**[22] Harbor x LangChain**
https://www.langchain.com/blog/unified-stack-for-evaluating-agents

**[23] 主流智能体框架**
https://docs.langchain.com/langsmith/integrations

**[24] OpenAI Agents SDK**
https://docs.langchain.com/langsmith/trace-with-openai-agents-sdk

**[25] Claude Agent SDK**
https://docs.langchain.com/langsmith/trace-claude-agent-sdk

**[26] OpenAI**
https://docs.langchain.com/langsmith/trace-openai

**[27] Anthropic**
https://docs.langchain.com/langsmith/trace-anthropic

**[28] 追踪智能体的任意步骤**
https://docs.langchain.com/langsmith/annotate-code

**[29] LangSmith SDK：evaluate() 用法**
https://docs.langchain.com/langsmith/evaluate-llm-application

**[30] LangSmith pytest 集成**
https://docs.langchain.com/langsmith/pytest

**[31] LangSmith Vitest / Jest 集成**
https://docs.langchain.com/langsmith/vitest-jest

**[32] 《How We Build Evals for Deep Agents》**
https://www.langchain.com/blog/how-we-build-evals-for-deep-agents

**[33] LangSmith 评估快速入门**
https://docs.langchain.com/langsmith/evaluation-quickstart

**[34] LangSmith Essentials**
https://academy.langchain.com/courses/quickstart-langsmith-essentials

**[35] Agent Evals 线上工作坊报名（2026 年 10 月 28 日）**
https://events.langchain.com/register/762756f4-4344-4760-b4b9-a07dd63e76af/

本文译自 LangChain 官方博客，原文链接见上方参考链接。

---
原文链接：https://mp.weixin.qq.com/s?__biz=MzIzNTExNzMwNg%3D%3D&mid=2647835237&idx=1&sn=d55e5f29968740a54bf701e73a56c13a&chksm=f0ca6df0c7bde4e65dfac3af23db44b07c8f0f1cf3ae94dd3bb86fd567b250a23c2d97a1afa1
