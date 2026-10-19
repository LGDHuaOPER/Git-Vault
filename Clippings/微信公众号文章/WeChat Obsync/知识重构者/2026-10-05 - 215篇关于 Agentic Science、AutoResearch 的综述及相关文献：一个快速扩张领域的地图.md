---
source_url: "https://mp.weixin.qq.com/s?__biz=MzkzMzk0NTU2Mw%3D%3D&mid=2247486680&idx=1&sn=46642e91d0d5b2166cfecbe73031eb30&chksm=c245856cf5320c7a4bc78cd5ea9d797b1fec50ed2b8be64d4a38d5d5b0995bf5ece672742f2d"
title: "215篇关于 Agentic Science、AutoResearch 的综述及相关文献：一个快速扩张领域的地图"
account: "知识重构者"
published_at: "2026-10-05 20:00:50"
saved_at: "2026-10-11 13:02:18"
sync_id: "art_ce2da91ef8214937a9deefdacc186495"
parse_status: "ok"
---

# 215篇关于 Agentic Science、AutoResearch 的综述及相关文献：一个快速扩张领域的地图

文献是永远读不完的，哪怕只是综述文献。

最近我在追踪agentic science，autoresearch等相关领域的前沿。我知道看完这个领域的文献是一件不可能的事情。于是我让若干大模型一起来帮我检索了一下这个领域的综述论文（以及部分position，perspective论文）。一搜吓一跳。检索结果合并去重之后，居然有215篇相关文献（检索方法见：[比较不同 Agent 找文献的能力：懂得闭嘴的模型才是好模型](https://mp.weixin.qq.com/s?__biz=MzkzMzk0NTU2Mw==&mid=2247486657&idx=1&sn=635d16b81a9b425a3370c0241b2220c4&scene=21#wechat_redirect)）。

我自己把这215篇文献的标题全部浏览了一遍。但是看完这全部的文献既不可能，也无必要。我决定把这215篇文献分享出来，它也许可以成为关注这个领域的一个很好的起点。

具体文献附在文末。下面是我对这批文献所呈现的领域地图的个人解读，仅供参考。

这个领域正在以一种远超普通研究者阅读能力的速度扩张，而且它并不是沿着一条清晰的学术脉络向前发展，而是在多个不同 community、不同学科和不同研究环节中同时展开。

计算机科学研究者在讨论 AI Scientist、Deep Research Agent、long-horizon agent、memory、self-evolution 和 verification；化学、材料和生物医学研究者在讨论 self-driving laboratory、autonomous experimentation 和 AI co-scientist；信息科学和科研支持相关的研究，则开始进入文献检索、知识综合、系统综述、假设生成、论文评审和学术出版。与此同时，Nature、PNAS 等期刊上的 comment、perspective 和 editorial 已经开始讨论：当 Agent 真正进入科研过程以后，科学共同体、研究机构、学术会议和研究者本身会发生什么变化。

因此，关于 Agentic Science 的现状，可能已经很难由任何一篇综述完整呈现。不同综述看见的是这个巨大领域的不同切面。把这些文献放在一起，我们才能开始看到一张相对完整的地图。

## 第一条主线：从 AI for Science 到 AI Scientist

最直接的一组文献，是对 Agentic Science、Autonomous Scientific Discovery、AI Scientist 和 AutoResearch 的总体综述。

这组文献试图回答的是：AI 在科研中的角色究竟发生了什么变化？

早期的 AI for Science，更多强调模型对某个科研任务的支持，例如预测分子性质、分析生物数据或者求解数学问题。现在的 Agentic Science，则开始把研究过程本身作为自动化对象：系统可以检索文献、生成假设、设计实验、调用工具、运行代码、分析结果、修改计划，甚至生成最终论文。

从“完成一个科研任务”，到“组织一段完整的研究过程”，这是 Agentic Science 最核心的变化。围绕这个变化，已经出现了多篇关于 AI Scientist、Autonomous Research、Scientific Agents 和 research lifecycle 的综述。不同文章提出了不同的科研阶段划分、自治等级和系统 taxonomy，也对“什么才算真正的自主科研”给出了不同答案。

如果一个人刚刚进入这个领域，这一组总体综述是最合适的入口。

## 第二条主线：Deep Research 与信息密集型 Research Agent

另一组快速增长的文献集中在 Deep Research、Deep Search、Research Agent 和 AI Research Assistant。

与自主实验室相比，这一类 Agent 处理的主要对象不是物理实验，而是信息：搜索网页和数据库、阅读论文、追踪证据、比较观点、生成报告、维护研究状态，并在长时间任务中不断调整检索和推理策略。

这一部分其实与普通研究者和知识工作者的距离最近。今天我们已经能够直接使用 ChatGPT Deep Research、Kimi、Gemini、Qwen 等产品完成类似任务。围绕这些系统，也已经出现了关于 Deep Research Agent、LLM-based Search Agent、research automation 和 research assistant 的多篇综述。

如果你关心的是“Agent 如何帮助人类做研究”，而不是实验室自动化，这一组文献可能是最值得优先阅读的部分。

## 第三条主线：研究过程正在被逐段拆开

215 篇文献中，有相当一部分并不讨论完整的 AI Scientist，而是专门研究科研过程中的某一个环节。

其中数量非常明显的一支，是 scientific ideation 和 hypothesis generation：怎样利用大模型产生科学问题、生成假设、评估新颖性，并把假设推进到可验证状态。另一些综述则关注文献检索、系统综述、research synthesis、数据分析、科研写作和自动同行评审。

把这些文献放在一起，会发现过去经常被视为一个整体的“做研究”，正在被重新拆解成许多可以描述、建模、评估和自动化的环节。

这也说明，Agentic Science 并不只是要造出一个包办一切的 AI Scientist。更现实的发展路径可能是：科研过程中的不同环节先分别形成成熟的 Agent 和工具，然后再通过更长程的 workflow、共享的研究状态和验证机制连接起来。

## 第四条主线：长程 Agent、记忆、Harness 与持续研究状态

当 Agent 从完成一次检索、回答一个问题，走向持续数小时甚至数天的研究任务，问题就开始发生变化。

这时决定系统能力的已经不只是模型本身，还包括它如何保存状态、调用工具、管理上下文、恢复错误、检查中间结果，以及怎样在多轮行动之后仍然记得自己究竟要解决什么问题。

因此，在 Agentic Science 周围，已经形成了一批关于 long-horizon agent、persistent memory、self-evolving agent、recursive self-improvement、agent evaluation 和 harness design 的综述。它们未必直接以“科研”为题，但实际上构成了 AutoResearch 能否真正运行起来的技术基础。

对于关注 Research Harness、长期研究状态和自主研究基础设施的人，这组文献可能比一些泛泛讨论 AI Scientist 愿景的文章更加重要。

## 第五条主线：从软件 Agent 到 Self-Driving Laboratory

Agentic Science 的另一条重要路线，是把 AI Agent 与机器人、实验设备、自动化工作站和实验反馈闭环结合起来。

Self-driving laboratory 已经形成了相当完整的文献分支。相关综述不仅讨论实验自动化，还讨论系统如何选择下一轮实验、如何根据结果更新假设，以及如何处理安全、标准化、设备互操作和实验可复现性。

这一方向在化学、材料科学和药物发现中尤其活跃。原因并不难理解：这些领域的研究过程往往包含大量可重复的实验、明确的测量指标和相对快速的反馈循环，因此更适合建立“设计—执行—测量—学习”的闭环。

它也提醒我们，所谓科研自动化并不是一个统一问题。代码实验、文献研究、数学证明、药物发现和物理实验所需要的 Agent，其环境、工具、证据标准和可达到的自治程度都非常不同。

## 第六条主线：不同学科正在形成各自的 Agentic Science

在总体综述之外，领域化综述已经大量出现。

目前文献最密集的方向之一是化学和材料科学，包括化学 Agent、材料设计、能源材料、自主实验室和 autonomous chemical discovery。生物医学同样形成了清晰的分支，覆盖生物信息学、单细胞研究、药物发现、癌症研究、组学分析和 medical AI scientist。

此外，数学、物理、天体物理、空气动力学和纳米光子学等领域也已经开始出现自己的综述和 position paper。

这些文献特别值得放在一起比较。不同学科如何描述“研究过程”，哪些环节可以被自动化，什么算有效证据，什么时候可以认为研究已经完成，这些问题的答案并不相同。

**Agentic Science 在某种意义上像一面镜子：当不同学科试图把科研过程交给 Agent 时，它们也被迫更加明确地说明，自己究竟是如何产生知识的。**

## 第七条主线：Verification 正在成为中心问题

如果说第一阶段的问题是“AI 能不能做研究”，那么最近越来越多的文献开始追问：“我们怎么知道它真的完成了研究？”

在这份 corpus 中，verification、evaluation、reproducibility、provenance、reliability 和 trustworthy autonomous science 已经成为反复出现的关键词。

一个 Agent 能够生成一篇形式完整的论文，并不意味着它提出了有效的新知识；一个自动化 workflow 成功运行到最后，也不意味着它完成了科学意义上的闭环；一个结果能够被另一个模型打出高分，也不能证明它在现实世界中成立。

因此，科研 Agent 的真正瓶颈正在从生成能力转向验证能力。怎样保存完整研究轨迹，怎样追溯证据与数据来源，怎样区分工作流完成和科学发现，怎样让人类研究者在关键节点介入，这些问题很可能决定 Agentic Science 最终能够走多远。

## 第八条主线：科研组织、学术出版与人的位置

还有一组文献开始把 Agent 放到更大的科学系统中研究。

它们讨论人类与 Agent 如何组成科研团队，AI Scientist 是否会改变学术会议和同行评审，研究论文是否会从静态文本变成可执行、可交互的 Agent，科研机构和资助体系应当如何应对自动化研究，以及人类研究者的判断、责任和学术权威将放在哪里。

这部分目前还没有形成像技术综述那样稳定的研究框架，但它可能是最值得长期关注的方向之一。因为一旦 Agent 真正参与科研，变化的不只是研究效率，也包括科研劳动的分工、知识的生产方式和科学共同体的组织结构。

## 这215篇文献可以怎样使用？

这份清单目前最准确的定位，是一个可以继续核查、扩展和编码的领域地图。

如果你关注普通研究者可以直接使用的工具，可以从 Deep Research、Research Assistant、文献综述自动化和 scientific ideation 开始；如果你关注 Agent 技术，可以进入 long-horizon、memory、self-evolution、evaluation 和 harness；如果你来自化学、材料或生物医学领域，可以直接寻找相应的领域综述和 self-driving laboratory 文献；如果你关心图书情报、科研管理或者 Science of Science，那么 provenance、scientific curation、peer review、research artifacts 和 human–agent systems 可能是最相关的入口。

没有人需要把这 215 篇文献全部读完。它们真正的价值，是让我们看到这个领域已经延伸到了哪里，以及自己的问题处于整张地图的什么位置。

## 附录：215篇文献信息

![](附件资源/215篇关于%20Agentic%20Science、AutoResearch%20的综述及相关文献：一个快速扩张领域的地图/img_1.png)

![](附件资源/215篇关于%20Agentic%20Science、AutoResearch%20的综述及相关文献：一个快速扩张领域的地图/img_2.png)

![](附件资源/215篇关于%20Agentic%20Science、AutoResearch%20的综述及相关文献：一个快速扩张领域的地图/img_3.png)

![](附件资源/215篇关于%20Agentic%20Science、AutoResearch%20的综述及相关文献：一个快速扩张领域的地图/img_4.png)

![](附件资源/215篇关于%20Agentic%20Science、AutoResearch%20的综述及相关文献：一个快速扩张领域的地图/img_5.png)

![](附件资源/215篇关于%20Agentic%20Science、AutoResearch%20的综述及相关文献：一个快速扩张领域的地图/img_6.png)

![](附件资源/215篇关于%20Agentic%20Science、AutoResearch%20的综述及相关文献：一个快速扩张领域的地图/img_7.png)

![](附件资源/215篇关于%20Agentic%20Science、AutoResearch%20的综述及相关文献：一个快速扩张领域的地图/img_8.png)

![](附件资源/215篇关于%20Agentic%20Science、AutoResearch%20的综述及相关文献：一个快速扩张领域的地图/img_9.png)

感谢您的阅读。我是@知识重构者，全网同名，主要在知乎与公众号写作。长期关注AI时代的认知重构、知识工作方式变迁、个人创作系统，以及新的就业与创业机会。欢迎关注，一起理解变化，寻找属于自己的路径。

---
原文链接：https://mp.weixin.qq.com/s?__biz=MzkzMzk0NTU2Mw%3D%3D&mid=2247486680&idx=1&sn=46642e91d0d5b2166cfecbe73031eb30&chksm=c245856cf5320c7a4bc78cd5ea9d797b1fec50ed2b8be64d4a38d5d5b0995bf5ece672742f2d
