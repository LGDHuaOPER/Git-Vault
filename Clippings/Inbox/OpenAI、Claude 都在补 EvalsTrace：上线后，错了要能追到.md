---
title: "OpenAI、Claude 都在补 Evals/Trace：上线后，错了要能追到"
source: "https://mp.weixin.qq.com/s/zsFO0PuFmXp1AhlWraPc7Q"
author:
  - "[[KK]]"
published: 2026年6月16日 17:56
created: 2026-08-10
description: "Agent 最难查的是那种没有报错的错：工单看似处理完，工具调用也成功，业务却已经走偏。OpenAI、Claude、Palantir、AWS、Microsoft、Google 都在补的，是这条生产质量回路。"
tags:
  - "Clippings"
  - "微信/公众号文章"
"word-count": "9375"
---
KK AI应用落地社 *2026年6月16日 17:56*

售后工单里，Agent 直接失败反而好处理。失败会暴露，会进告警，会有人回滚，也会有人追日志。麻烦的是另一类单子： **它看起来把事情办完了** 。

工单总结得很漂亮，工具调用显示成功，客户通知草稿也写好了。几个小时后，服务经理回头看这单，才发现它用错了维修证据，查错了备件区域，还把本该人工确认的动作推进到了下一步。

这类问题在传统监控里很难看出来。接口没挂，延迟不高，日志也不一定报错，系统像是正常执行了一次任务，业务却已经被带偏。所以这一篇要讲 Evals 和 Trace。

这里说的 Evals，不是模型排行榜里的分数，也不是让模型自己评价“我做得好不好”。放在企业 Agent 里，它更接近一条生产质检线。

**本文只讲一件事：** 企业 Agent 上线后，质量控制不能只看最后回答，要看完整行为链路。

*Trace 是证据，Evals 是判断，Regression 是防复发。*

可以粗一点分工：Trace 留下“它到底做了什么”，Evals 判断“这样做对不对”，Regression 负责看“下次改模型、prompt、工具、权限时，同样的问题会不会回来”。过去一年，几个大公司和开源框架都在补这条线。

| 公开材料 | 具体动作 | 露出的生产问题 |
| --- | --- | --- |
| **OpenAI Agent Evals** | trace grading、datasets、eval runs | Agent 不能只评最终回答，要看 model calls、tool calls、guardrails、handoffs |
| **Claude Code Observability** | OpenTelemetry traces、metrics、events | 模型请求、工具执行、token、cost、prompt、tool result 要进生产遥测 |
| **Anthropic Agent Evals** | code / model / human graders | Agent eval 经常要组合规则、模型判断和人工复核 |
| **Palantir AIP** | AIP Evals + AIP Observability | eval suite、variance、workflow execution、metrics、tracing、logs 被放进平台层 |
| **AWS Bedrock AgentCore** | online / on-demand / batch evaluation | 生产 trace 可以抽样评分，事故 trace 可以单独拉出来排查 |
| **Microsoft Foundry** | system / process / quality evaluators | tool selection、tool input accuracy、tool output utilization 被拆成独立评测项 |
| **Google ADK Eval** | golden dataset、trajectory failure、Pytest gate | Agent 漏掉关键工具步骤，也可以被 CI/CD 拦下来 |

这些名字放在一起，不是为了堆品牌。它们露出来的是同一个变化：Agent 已经开始进入业务流程，质量控制不能再停在 **“回答看起来不错”** 。

产品按钮放在哪里不是重点， **链路有没有闭合** 才是重点：生产里发生过的错误，能不能变成下一次上线前必须通过的检查。

![图片](https://mmbiz.qpic.cn/sz_mmbiz_png/qAlfPw92OQusBiakKnOt0mM8SthmH2TWmtbLjLSicibcfT55R0cdkiaCfeIWS0bOibxoDR14iaSXjib5LqviafSwSLiajMAumPCia1F9NHmPc42KtR5fg/640?wx_fmt=png&from=appmsg&watermark=1&tp=webp&wxfrom=5&wx_lazy=1#imgIndex=0)

## 一、先看一张售后工单

机械制造行业更容易看清楚这个问题。Siemens 和 Microsoft 关于 Industrial Copilot 的公开材料里，工业 AI 已经进入自动化工程、PLC、TIA Portal、WinCC、传感器配置、机器可视化、检测报告和维护排障这些生产场景。

下面这个售后 Agent 不是某家公司已经公开上线的完整案例，而是基于这些公开趋势抽出来的架构样例。为了方便看清楚，先把场景压成三步。

01公开信号：工业 AI 已经进到生产现场

不是单纯问答，而是自动化工程、PLC、TIA Portal、WinCC、传感器配置、机器可视化、检测报告和维护排障这些流程。

02架构样例：一家海外设备厂商的售后工单

系统接入售后工单、设备序列号、保修状态、维修记录、传感器、备件库存、服务商排班和合同 SLA。客户提交的问题是：设备频繁报警，产线偶发停机，现场工程师怀疑是驱动模块问题。

03生产转折：Agent 开始影响成本和责任边界

Demo 阶段，它能总结故障、找相似案例、给检查建议、生成客户通知草稿。到了生产阶段，它还会查库存、推荐派工、预留备件、修改工单状态、把故障结论写回知识库。

问题就在这里：一旦 Agent 从“写一段话”变成“推动一个流程”，错误就不一定会炸出异常，但会让业务慢慢偏掉。下面三种错法最常见。

### 第一种：结果像对，路径是错的

Agent 最后建议：“派现场工程师检查驱动模块。”这句话本身可能没错，问题是它怎么得出这句话。

它有没有查设备序列号？有没有确认这台设备的保修状态？有没有看最近 48 小时的报警和温度、电流、振动趋势？有没有对比同型号设备的历史维修案例？有没有确认推荐工程师具备这个型号的认证？

如果这些都没做，只是根据用户描述和维修手册生成了一段建议，那它不是“按流程推出来的”，更像“猜出来的”。

最终文本看起来对，路径已经错了。这类问题最容易被忽略，因为业务人员看到的是一个合理建议，系统人员看到的是一次正常返回。只有 trace 能说明它到底有没有走该走的步骤。

### 第二种：工具成功，业务是错的

Agent 调用了库存工具，工具返回成功，请求也没有报错。但它传错了 `warehouse_region` ：应该查北美仓，它查了欧洲仓。于是系统告诉它“有货”，它就建议预留驱动模块。从技术指标看，这次工具调用是成功的；从业务结果看，这次建议是错的。

Agent 比传统软件麻烦的一点在这里： **工具成功不等于任务成功** 。工具有没有选对，参数有没有传对，返回有没有被正确理解，都要单独评。

Microsoft Foundry 把 tool selection、tool input accuracy、tool output utilization 拆出来，原因就在这里。

### 第三种：回答正常，控制边界错了

Agent 生成了一段客户通知：“我们判断该问题可能涉及驱动模块异常，将安排工程师尽快到场。”这段话很稳，也很像专业客服，但它不能直接发。因为这句话涉及责任判断、停机风险、SLA、保修、赔付、经销商责任和客户等级，它应该先停在服务经理确认，而不是直接进入客户可见流程。

Morgan Stanley 的 Debrief 公开资料里有一个很关键的设计：AI 可以生成会议纪要、action items 和邮件草稿，但顾问要 review and adjust，然后再写入 Salesforce。

这个设计不是“保守”，它是在划责任边界。企业 Agent 进入售后、金融、供应链、生产运维以后，很多动作都属于这一类：模型可以生成，但 **不能直接执行** 。

把这三类问题放在一起看，就会发现，企业 Agent 的风险不是“它会不会说错话”这么简单。

| 错误类型 | 表面现象 | 要查的东西 |
| --- | --- | --- |
| 路径错 | 回答看起来合理 | trace 里有没有查该查的证据 |
| 工具错 | 工具调用成功 | tool selection / input / output 是否正确 |
| 边界错 | 文案专业稳定 | approval / guardrail 有没有拦住高风险动作 |

这三种错误都不一定会在错误率里出现，它们更像生产里的“静默偏差”。

## 二、传统监控看不见这种错

传统 APM 很重要，但它主要回答服务健康问题。Agent 进入业务流程以后，还要回答行为质量问题。系统健康只能告诉你“机器还在跑”，但不能告诉你“它是不是按正确的业务路径在跑”。

| 传统监控更关心 | Agent 质量还要追问 |
| --- | --- |
| 请求是否成功 | 任务是不是真的完成 |
| 延迟是否正常 | Agent 有没有绕远路或重复调用工具 |
| 错误率是否升高 | 工具成功但参数是否传错 |
| 日志有没有异常 | 上下文、证据、权限是否正确 |
| 队列是否堆积 | 高风险动作有没有停在人审前 |

AWS AgentCore Evaluations 的公开材料里提到一种很典型的情况：运营指标可能是绿的，但用户体验和 Agent 质量已经下降。问题不一定是系统挂了，也可能是 Agent 选错了工具，或者回答没有帮助。

放到企业里，这种情况并不少见：很多 Agent 事故不是“服务不可用”，而是“看起来可用，但越用越偏”。传统软件坏了，通常会给出明显信号：接口失败、超时、队列堆积、异常日志；Agent 坏了，不一定。它可能还在正常返回，还能给出一段语气稳定的解释，只是看的证据错了，调的工具错了，或者把本该人工确认的动作直接执行了。

所以 Agent 的生产质量不能只靠日志和监控面板。需要把几件事接起来：trace 留证据，eval 做判断，失败样本进回归，线上继续抽样。

![图片](https://mmbiz.qpic.cn/sz_mmbiz_png/qAlfPw92OQvm2I81iaz7FpRuR0bEMoEZ7Nqb7yKflicOYrkcp0zpwDTKprtE2jLSBLghEbialVicqE8phCsv6mia6H2ZMWhHw8t47XY5oiabIptF8/640?wx_fmt=png&from=appmsg&watermark=1&tp=webp&wxfrom=5&wx_lazy=1#imgIndex=1)

传统监控证明系统还活着，Agent 质量回路证明它正在按 **正确路径** 做事。

这两件事不能互相替代。APM 仍然要做，错误率、延迟、队列、成本也仍然要看。但如果 Agent 已经能查数据、调工具、写系统、触发审批，只看系统健康就不够了，还要看行为健康。

行为健康至少要看四层：

01上下文：数据、文档、权限有没有对上

它有没有拿到当前设备型号的手册、合同口径、客户等级和最新遥测。上下文错了，后面的推理再漂亮也会偏。

02工具：选没选对，参数有没有传对

工具成功只说明接口返回了，不说明任务成功。查错仓库、查错客户、漏查工单，都会让最终建议看起来正常但业务已经错了。

03控制：高风险动作有没有停在人审前

客户通知、备件预留、SLA 变更、状态写回，不应该只看模型有没有生成，而要看 approval 和 guardrail 有没有真的生效。

04回归：同类错误下次会不会再出现

失败 trace 不能只留在事故复盘里。它要进入 eval dataset，变成下一次 prompt、模型、工具变更前必须通过的检查。

OpenAI 讲 trace grading，AWS 讲 online evaluation，Palantir 把 AIP Evals 和 Observability 放进平台里，背后都和这件事有关。它们不是在给监控大屏加一个 AI 插件，而是在补 Agent 的生产质量控制面。

## 三、Trace 不是日志，是这次行为的证据链

很多团队会说自己有日志，但日志不等于 trace。普通日志记录的是系统事件：请求到了、接口返回了、工具报错了、队列消费了。Agent trace 要记录的是一次行为链路，它要能回答这些问题：

| 要追的问题 | trace 里要留下什么 |
| --- | --- |
| 谁发起了任务 | 用户、角色、组织、权限 |
| Agent 理解成什么任务 | 任务类型、风险等级、业务对象 |
| 它看了哪些上下文 | 工单、设备、合同、手册、遥测、历史案例 |
| 它调用了哪些工具 | 工具名、参数、返回、耗时、错误 |
| 它有没有触发控制 | guardrail、approval、handoff、人工确认 |
| 它写回了什么 | 工单状态、客户通知、备件预留、知识库更新 |

这块最容易被忽略：同样一句“建议派工程师检查驱动模块”，最后文本看起来都很稳，背后的 **执行路径** 可能完全不同。

| 看起来一样的建议 | Agent 实际走过的路径 | 风险判断 |
| --- | --- | --- |
| **路径 A** | 查了设备序列号、保修状态、近期遥测、相似案例、备件库存、工程师资质 | **建议有证据，后面能复盘** |
| **路径 B** | 只读了用户描述和一段维修手册，就生成派工建议 | **文本可能像对的，但风险不可控** |

OpenAI Agent Evals 讲 trace grading，就是在处理这类问题：不只评最后一句话，还要评这条路径有没有走对。没有 trace，团队只能围着最终回答争论；有了 trace，才知道它是按流程推出来的，还是靠语言能力猜出来的。

可观测性这块也在变得更标准。OpenTelemetry 已经在给 GenAI 场景定义统一的观测字段；Claude Code 文档也把模型请求、工具执行、token / cost、prompt、工具返回接到 OpenTelemetry。放到企业里，Agent 的每一步不能只丢进字符串日志，要能被现有 APM 和可观测系统接住。

**架构师要看的不是“有没有日志”。** 要看一次 Agent run 能不能还原成： *谁发起、看了什么、调了什么、谁确认、写回了哪里。*

所以 trace schema 不要一开始做成大而全的平台表，先把能复盘一次执行的字段留下来。

---

| Trace 字段 | 具体含义 | 用来排查什么 |
| --- | --- | --- |
| `run_id` | 一次 Agent 执行的唯一 ID | 串起模型、工具、人工、写回 |
| `actor` | 发起人、角色、组织、权限 | 是否越权、是否角色错配 |
| `task_type` | 咨询、诊断、派工、通知、写回 | 是否把任务识别错 |
| `business_objects` | 客户、设备、工单、合同、备件 | 是否串错对象 |
| `context_sources` | 文档、工单、遥测、知识库、版本 | 是否用了过期或缺失上下文 |
| `retrieval_results` | 检索结果、相似度、是否被使用 | 是否证据不相关 |
| `model_calls` | 模型版本、输入、输出、token、耗时 | 是否模型变更导致退化 |
| `tool_calls` | 工具名、参数、返回、错误、耗时 | 是否工具选择或参数错误 |
| `guardrail_events` | 哪些规则触发、拦截或放行 | 风险控制是否生效 |
| `human_events` | 谁确认、谁拒绝、等待多久 | 人工确认链路是否清晰 |
| `writebacks` | 写回对象、状态、幂等 key | 是否重复写回或写错对象 |
| `eval_hooks` | 哪些节点进入评测 | 失败样本是否能沉淀 |

这张表不一定第一天就全部做完，但有一个底线：不要把 Agent 的运行记录压成一个 `agent_log_text` 大字段。那样后面做 eval、排查和回归都会很痛苦。好的 trace 不只是事后排查材料，它是下一步 eval 的原料；如果 trace 不能变成样本，质量回路就断了。

## 四、Eval 不是评分，是回归测试

Eval 这个词很容易被误解成“打分”：这条回答 8 分，那条回答 9 分，这个模型比另一个模型高 3 分。这样的分数有用，但不够。企业 Agent 更需要的是回归测试：今天修了工具选择问题，明天不能把权限边界弄坏；今天换了更便宜的模型，不能让高风险工单漏掉人工确认；今天改了检索策略，不能引入过期手册，让 Agent 用旧证据解释新型号设备。

Google ADK Eval 的 codelab 里有一个很小的例子：期望路径是先 `lookup_order` ，再 `issue_refund` ；实际 Agent 跳过验证，直接调用了 `issue_refund` 。这不是最终回答错了，而是行动顺序错了。

放到售后场景里，就是本该先查设备和保修，再建议派工，实际却先建议派工，再补查保修；本该先检查备件适配性，再创建预留，实际却先创建预留，再发现型号不匹配；本该先生成客户通知草稿，再等服务经理确认，实际却直接发出正式通知。这类问题靠看最终文本很难发现，必须进入过程评测。

| Eval 层级 | 评什么 | 售后场景例子 |
| --- | --- | --- |
| **结果** | 最终回答是否正确、完整、相关 | 是否解释故障原因和下一步 |
| **证据** | 回答是否被上下文支撑 | 是否引用当前型号手册和近期遥测 |
| **过程** | 工具路径、参数、顺序是否正确 | 是否先查保修，再建议派工 |
| **控制** | 权限、人审、写回是否符合规则 | 客户通知是否停在人工确认前 |

Microsoft Foundry 的 Agent Evaluators 也是这个思路。它把 system、process、quality evaluation 拆开，process evaluation 继续拆到 tool selection、tool input accuracy、tool output utilization、tool call success。

项目里要把“Agent 不靠谱”拆开看。工具选错、参数传错、证据不可靠、没有触发人审、写回对象错，这些才是可修复的问题。

## 五、LLM-as-judge 不能包打天下

LLM-as-judge 有用，但 **不能全交给模型判断** 。企业 Agent 里，很多质量项更适合用规则、代码、schema、trace 检查和人工抽检。

| 问题 | 更合适的 evaluator |
| --- | --- |
| 有没有调用 `get_warranty_status` | 代码断言 / trace 检查 |
| 是否先查保修再派工 | trajectory evaluator |
| 工具参数是否传对 | schema + value assertion |
| 是否使用过期手册 | metadata / version rule |
| 客户通知是否停在人审前 | policy rule |
| 回答是否被证据支撑 | groundedness evaluator + 抽检 |
| 客户措辞是否合规 | LLM evaluator + 合规 checklist |

AWS 的 AgentCore onboarding sample 里有一个很实用的工程模式：一个 output evaluator 看最终输出，一个 custom tool-call evaluator 检查 OTel spans，确认 Agent 真的调用了 pricing tool，而不是凭空编价格。这个例子说明，eval 不只是看“说得像不像”，还要检查“有没有做该做的事”。

## 六、生产 trace 要变成 eval 样本

很多团队第一次做 eval，会做一组很干净的样本：几十条标准问题，每条一个理想答案。跑出来分数很好看，上线后还是翻车。问题出在样本太干净， **真实业务不是干净问题。**

真实业务里有权限、例外、历史、脏数据、重复工单、过期文档、冲突规则、人工判断。售后场景里还有经销商、备件区域、客户等级、合同条款、SLA 口径。所以 eval dataset 不能只靠标准问答，至少要有四类样本。

01高频正常样本：保住主流程

常见报警、常见备件、常见派工要稳定通过。它们不一定最难，但最能反映日常体验有没有退化。

02边界样本：覆盖容易错的例外

过保但有特殊合同、同型号不同批次、客户等级不同导致 SLA 口径不同，这些才是企业流程里真正容易翻车的地方。

03高风险样本：防止副作用事故

客户通知、备件预留、SLA 状态变更、知识库写回，都要单独测。这里错一次，影响的不只是回答质量。

04生产失败样本：防止同类问题复发

用户投诉、人工纠错、低分 trace、被服务经理打回的建议，都是最值钱的样本。它们能把现场问题变成回归资产。

最值钱的是第四类。每一次真实失败都应该留下来，问几个问题：这次 Agent 错在哪里？是上下文缺失、工具选错、参数传错、证据不可靠，还是人工确认没触发？能不能写成 evaluator？不能自动评的部分，谁来人工复核？

一个项目开始变强，通常不是因为第一版样本有多大，而是因为它能把 **生产失败** 持续变成回归样本。项目里最有用的材料，常常不是一开始设计出来的“标准问答”，而是上线后被业务人员打回来的那些 trace：这一步为什么没查合同？这个客户为什么不能自动发通知？这类设备为什么不能用通用维修建议？这些问题一旦沉淀下来，Agent 才会越来越贴近真实业务。

一条有用的售后 Agent 样本，不应该只存“用户问了什么、标准答案是什么”。它至少要描述任务、对象、上下文、期望路径、禁止动作和人工确认点，可以像这样理解：

| 样本字段 | 例子 | 作用 |
| --- | --- | --- |
| `task_type` | field\_service\_recommendation | 让 Agent 知道这是派工建议，不是普通问答 |
| `business_objects` | 工单、设备、客户、合同 | 防止串错对象 |
| `required_context` | 设备档案、保修、遥测、相似案例、库存、工程师资质 | 检查上下文是否完整 |
| `expected_tool_sequence` | 先查设备，再查保修，再查遥测，再查库存 | 检查行动顺序 |
| `must_not_do` | 未经确认不得发送客户通知，不得自动预留备件 | 检查控制边界 |
| `expected_output` | 建议派工、证据齐全、需要人审 | 检查最终输出和流程状态 |

这比单纯的“标准答案”更接近真实 Agent eval。如果 Agent 最后说得很好，但没有调用保修查询，失败；如果 Agent 调用了库存工具，但没有检查工程师资质，失败；如果 Agent 生成客户通知并直接发送，失败；如果 Agent 用了旧型号维修案例，却没有说明证据限制，也失败。这样的样本能把业务流程变成可测试的工程约束。

![图片](https://mmbiz.qpic.cn/mmbiz_png/qAlfPw92OQvRStusH11pT4vmtVkJaclr2ZWsmurjb5IdXydVicOQEwa9WBBHTsjwwTy1bicPBwsQxSj2cLx0hxiahIlm16EO1la0bQ45CSCcibs/640?wx_fmt=png&from=appmsg&watermark=1&tp=webp&wxfrom=5&wx_lazy=1#imgIndex=2)

## 七、发布门禁：Prompt、模型、工具都不能裸奔

很多 Agent 项目的发布流程很薄：改了 prompt，看几条样例；换了模型，看几条样例；加了工具，也看几条样例。Demo 阶段可以这样，生产阶段不行。

危险的发布，往往不是“大改版”，而是一次看起来很小的调整。为了让回答更短，改了 prompt，结果工具选择变差；为了降低成本，换了模型，结果高风险场景更容易漏掉人工确认；为了提高召回，改了检索，结果引入更多旧文档，证据质量下降；为了补能力，加了新工具，结果 Agent 过度调用新工具，旧流程变慢。

发布门禁要看差异，不是只看这次分数，而是看这次和上一次比，哪些能力退化。它防的就是 *悄悄退化* 进入生产。

![图片](https://mmbiz.qpic.cn/mmbiz_png/qAlfPw92OQvU9bIicenTbedLtReyZ5IehJluyichzSHA5r4lUgfEE9aQt5u1P8UiaFHw4VX62ibSjv5ImUKIOqibpa4pWmlxWWVCLbkYEMv1JDL4/640?wx_fmt=png&from=appmsg&watermark=1&tp=webp&wxfrom=5&wx_lazy=1#imgIndex=3)

一个最小门禁可以这样定：

| 变更 | 必跑 eval |
| --- | --- |
| 改 prompt | 高频样本、边界样本、任务完成、输出质量 |
| 换模型 | 全量 regression、成本、延迟、多次运行方差 |
| 改检索 | groundedness、context coverage、旧文档误用 |
| 新增工具 | tool selection、tool input accuracy、tool output utilization |
| 改权限 | 越权访问、隐藏字段、禁止动作、人工确认 |
| 改写回逻辑 | 幂等、状态机、补偿、回滚、审计 |

Palantir AIP Evals 里提到对 LLM-backed functions 做多次运行、看 variance。Agent 不是确定性函数，一次看起来对，不代表下一次还对。版本发布前只跑一条样例，很容易给团队一种假的确定性。

发布门禁要保护的不是一张漂亮报告，而是避免新版本把旧能力打坏。可以把门禁拆成三层。

01基础回归：高频任务不能退化

主流程通过率下降、工具选择明显变差、回答质量变差，这类问题应该在发布前被挡住。

02高风险回归：权限、人审、写回不能失控

禁止动作被执行、人工确认被跳过、客户通知直接发出，这些不是体验问题，是生产风险。

03生产采样回归：线上真实失败不能复发

历史事故样本再次失败，就说明修复没有真正进入质量回路。生产里踩过的坑，下一次上线前必须被测到。

这个流程不一定一开始就全自动，但至少要形成一个习惯：所有会影响上下文、工具、权限、写回的变更，都要经过 eval。否则每次上线都在赌。只不过传统系统赌的是接口会不会挂，Agent 赌的是业务路径会不会被带偏。

## 八、线上 eval：上线不是终点

上线前 eval 只能覆盖已知问题，真实使用会不断制造新问题。这也是 AWS AgentCore 把 evaluation 分成 online、on-demand、batch 的原因。

| Eval 类型 | 适合处理什么 |
| --- | --- |
| **Batch eval** | 发布前回归，看新版本有没有退化 |
| **On-demand eval** | 针对某个 span / trace 排查投诉或事故 |
| **Online eval** | 从生产流量抽样，持续看质量趋势 |

售后 Agent 可以重点抽这些 trace：高价值客户工单、高风险停机工单、涉及客户通知或备件预留的工单、人工拒绝 Agent 建议的工单、用户二次追问较多的工单。

这些 trace 不能只是进仪表盘。它们要进入失败归类、eval 样本、修复 backlog，再回到下一次 regression，否则 observability 只是展示，不会推动修复。有用的线上 eval，不是告诉团队“今天平均分 8.6”，而是告诉团队：哪类工单最容易错，哪个工具参数最常传错，哪类人审最容易被跳过，哪个版本开始引入退化。

线上 eval 还会改变产品边界。有些任务经过一段时间抽样，会发现 Agent 表现稳定，可以逐步提高自动化程度；有些任务则相反，数据不稳定、责任边界复杂、人工拒绝率高、客户影响大。这样的任务不应该硬推自动执行，而应该退回建议、草稿或辅助决策。

## 九、FDE / 现场角色为什么绕不开

质量回路不是 AI 团队坐在办公室里造出来的，尤其是 eval 数据集。样本往往来自现场：客户怎么描述问题，工程师怎么判断异常，服务经理什么时候愿意批准，经销商为什么不接单，备件为什么看似有库存但不能用。还有哪些客户通知不能直接发，哪些例外写在合同里但不在知识库里，哪些状态修改会触发后续责任。

这些东西如果没人带回来，eval 数据集就会只剩干净样本。模型会在干净样本上表现不错， **一进真实场景就开始偏** 。

所以企业前期可以依赖外部团队搭第一版 Agent、Harness 和质量回路，但后期一定要培养自己的 **现场工程能力** 。

这里的 FDE / 现场工程角色，不是售前讲方案的人。他要做的是把现场问题工程化：把客户语言翻译成任务类型，把异常流程翻译成 eval 样本，把人工判断点翻译成 approval policy，把真实失败翻译成 regression case，把业务对象翻译成 trace schema。

这件事外部顾问可以带着做，但 **不能永远外包** 。Agent 最后跑的是这家企业自己的设备、合同、客户、组织和责任边界。外部团队可以把第一条质量回路搭起来，但长期让它变准的人，一定要贴着业务现场。

## 十、落地顺序：先留证据，再做门禁

落地时，不需要第一天就做成很重的平台。更稳的做法，是按 30 / 60 / 90 天推进。重点不是买一堆工具，而是把 **出过的问题** 变成下次上线前必须过的检查。

### 前 30 天：先让问题可见

前 30 天的目标不是自动优化，而是先能复盘。

| 交付物 | 要解决什么 |
| --- | --- |
| Trace schema v1 | 每次 run 至少能串起上下文、工具、人工、写回 |
| 任务类型表 | 明确 Agent 到底支持哪些任务 |
| 动作风险分级 | 区分只读、建议、草稿、写回、通知、审批 |
| 失败分类 v1 | 把“不准”拆成可修的问题 |
| 生产抽样机制 | 每天或每周抽取真实 trace |

这 30 天先不追求完美 eval，先让问题有证据。

### 60 天：让失败变成样本

60 天的目标，是把生产问题变成回归资产。

| 交付物 | 要解决什么 |
| --- | --- |
| Golden dataset v1 | 高频、边界、高风险、生产失败样本 |
| Evaluator 组合 | 规则、代码、LLM、人工复核 |
| Tool call evaluator | 检查工具选择、参数、返回使用 |
| Approval evaluator | 检查高风险动作是否停在人审前 |
| Regression report | 每次变更前后对比退化 |

到这一步，质量才开始有工程抓手，因为 **问题开始可以复现** 。

### 90 天：接入发布和运营

90 天的目标，是让质量回路进入生产节奏。

| 交付物 | 要解决什么 |
| --- | --- |
| CI/CD eval gate | 高风险退化阻断上线 |
| Online sampling | 生产 trace 持续抽样评分 |
| Quality dashboard | 系统健康、行为质量、业务影响、改进效率 |
| Issue queue | 低分 trace 自动进入修复队列 |
| Version comparison | prompt、模型、工具、检索变更可对比 |

到这一步，Agent 才不是“上线后靠感觉维护”，它开始像一个 **真实生产系统** 。

## 十一、这些材料到底补了什么

只把 OpenAI、Claude、Palantir、AWS、Microsoft、Google、LangSmith、Langfuse、Phoenix、promptfoo、DeepEval 这些名字列出来，意义不大。读者真正需要看的，是它们分别把哪一块生产短板说清楚。

前面讲 Siemens / Microsoft，是为了说明工业 AI 已经进到 PLC、TIA Portal、WinCC、传感器配置、检测报告和维护排障这类生产场景；讲 Morgan Stanley，是为了说明金融工作流里，AI 生成内容以后仍然要保留顾问 review and adjust，再写回 Salesforce。这两个案例都在提醒同一件事：Agent 一旦进入业务流程，就不能只看“回答像不像”。

再看这些工具和平台材料，重点会更清楚。它们不是同一种产品，但公开材料里反复出现的信号，可以拆成下面几条。

01OpenAI / Anthropic：先把 eval 方法讲清楚

OpenAI 把 trace grading、datasets、eval runs 放到 Agent Evals 里；Anthropic 强调 code-based、model-based、human graders 的组合。核心不是“让模型给自己打分”，而是把 **最后回答、过程轨迹、人工判断** 分开评。

02Claude / OpenTelemetry：把运行过程接进遥测

Claude Code Observability 把 model request、tool execution、token、cost、prompt、tool result 接到 OpenTelemetry。它提醒的是：Agent 不能只留下字符串日志，关键步骤要进入 **标准化 trace / metric / event** 。

03Palantir / AWS / Microsoft / Google：把质量回路放进平台

Palantir 讲 eval suite、variance、AIP Observability；AWS 把 evaluation 分成 batch、on-demand、online；Microsoft 把 tool selection、tool input accuracy、tool output utilization 拆成评测项；Google ADK Eval 把 trajectory failure 接进 CI/CD。这些材料共同指向：Agent 质量不是一次人工 review，而是一条 **发布门禁和生产采样** 。

04LangSmith / Langfuse / Phoenix / promptfoo / DeepEval：把它变成日常工程流

开源和框架生态做的是另一件事：把 trace、dataset、eval、experiment、CI、red team、agentic metrics 放进开发流程。也就是说，团队改 prompt、换模型、加工具时，不能只靠感觉，要能看见 **这次改动让哪些能力退化** 。

所以这不是“谁家的产品更强”的问题。更准确地说，OpenAI 和 Anthropic 在把 eval 方法讲清楚，Claude / OpenTelemetry 在把 trace 标准化，Palantir、AWS、Microsoft、Google 在把它放进平台和发布流程，LangSmith、Langfuse、Phoenix、promptfoo、DeepEval 在把它带进开源工程工具链。

这些材料合在一起，指向的不是一个新名词，而是一层生产质量能力。

这层能力至少包括五件事：

1.**Trace** ：记录一次 Agent 到底看了什么、调了什么、写了什么。

2.**Eval dataset** ：把真实问题沉淀成可重复样本。

3.**Evaluator** ：用规则、代码、LLM、人审判断行为是否正确。

4.**Release gate** ：防止新版本破坏旧能力。

5.**Online evaluation** ：在生产里持续发现退化。

企业 Agent 到了生产阶段，不能只证明“它能回答”。更重要的是：它错了以后，团队能不能追到它看错了什么、调错了什么、漏掉了什么控制点；修完以后，能不能防止同一个问题下次再回来。

Evals / Trace 不是为了让文章里多几个新名词，而是让企业 Agent 从“看起来能跑”，变成“出了问题能追、能改、能防复发”。

做架构评审时，可以留这五个问题。

| 架构评审问题 | 如果答不上来，风险在哪里 |
| --- | --- |
| 一次 Agent run 能不能还原完整路径 | 出事后只能看最终回答，查不到问题在哪 |
| 生产失败有没有进入 eval dataset | 同类错误会在下个版本继续回来 |
| 工具选择和参数有没有单独评测 | 工具成功但业务错误会被漏掉 |
| 高风险动作有没有 approval trace | 人审被跳过时很难追责和回滚 |
| prompt / 模型 / 工具变更有没有 diff report | 新版本可能悄悄破坏旧能力 |

下一篇继续往平台层拆：当 SDD、Ontology、Harness、Evals / Trace 放在一起，哪些能力应该沉到平台层，哪些必须留在业务层，哪些只能靠企业自己的现场能力长期积累。

## 资料来源

| 来源 | 本文使用的关键点 |
| --- | --- |
| Anthropic Agent Evals 工程文章 | Agent eval 通常组合 code-based、model-based、human graders，既看 transcript，也看 outcome |
| Claude Code Observability 文档 | Claude Code CLI 通过 OpenTelemetry 记录 model request、tool execution、token/cost metrics、prompt 和 tool result events |
| Siemens × Microsoft Industrial Copilot 公开资料 | 工业 AI 已进入自动化工程、PLC / TIA Portal、机器可视化、维护排障、传感器配置和检测报告等生产场景 |
| OpenAI Agent Evals 官方文档 | trace grading、model calls、tool calls、guardrails、handoffs、dataset 和 eval runs |
| OpenAI Agents SDK 官方文档 | orchestration、tool execution、state、approvals、observability、evaluation |
| OpenAI × Morgan Stanley 公开案例 | eval framework、专家反馈、retrieval method 迭代、zero data retention |
| Morgan Stanley Debrief 发布资料 | 顾问 review and adjust、action items、写入 Salesforce |
| Palantir AIP Evals 官方文档 | eval suite、test cases、evaluation functions、多次运行和 variance |
| Palantir AIP Observability 官方文档 | metrics、tracing、logs、execution history、workflow lineage、P95 duration |
| AWS Bedrock AgentCore Observability / Evaluations | production trace、online / on-demand / batch evaluation、质量分数和运营指标并看 |
| AWS AgentCore onboarding GitHub sample | output evaluator、tool-call evaluator、OTel spans、local/on-demand/online 三种评测模式 |
| Microsoft Foundry Observability / Agent Evaluators | system/process/quality evaluation、tool call accuracy、tool input accuracy、task completion |
| Google ADK Eval codelab | golden dataset、trajectory failure、Pytest 接入 CI/CD 阻断退化 |
| OpenTelemetry GenAI semantic conventions | GenAI span、event、attribute、metric 的标准化方向 |
| LangSmith / Langfuse / Phoenix / promptfoo / DeepEval | trace、dataset、eval、experiment、CI/CD、red team 和 agentic metrics |

## 写作说明

本文基于公开技术文档、GitHub 资料、工程博客和企业案例整理。AI 工具仅用于资料归纳、结构梳理和初稿辅助，核心判断、事实核对和最终表达均已人工审校。

企业 Agent 架构第一性原理 · 目录

作者提示: 个人观点，仅供参考

拖拽到此处完成下载

图片将完成下载

AIX智能下载器