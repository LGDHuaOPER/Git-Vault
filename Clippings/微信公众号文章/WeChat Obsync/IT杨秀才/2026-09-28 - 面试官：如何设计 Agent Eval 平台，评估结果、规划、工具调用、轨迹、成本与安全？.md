---
source_url: "https://mp.weixin.qq.com/s?__biz=Mzk0MTYxNDgyNA%3D%3D&mid=2247495666&idx=1&sn=e09eb7a751a146535925d7d8da1115ef&chksm=c2cd1c75f5ba95633622a26151c457d862a9e52be3193817ab3794f90821816ee4681cacdcad"
title: "面试官：如何设计 Agent Eval 平台，评估结果、规划、工具调用、轨迹、成本与安全？"
account: "IT杨秀才"
published_at: "2026-09-28 14:25:51"
saved_at: "2026-10-21 08:35:49"
sync_id: "art_b0a3230b38c94dd29541c21acd75b27d"
parse_status: "ok"
---

# 面试官：如何设计 Agent Eval 平台，评估结果、规划、工具调用、轨迹、成本与安全？

![alt](附件资源/面试官：如何设计%20Agent%20Eval%20平台，评估结果、规划、工具调用、轨迹、成本与安全？/img_1.png)

[秀才的学习网站： https://golangstar.cn/](https://mp.weixin.qq.com/s?__biz=Mzk0MTYxNDgyNA==&mid=2247494997&idx=1&sn=291a6d209a8fa9e107ba7ff1840ed2b5&scene=21#wechat_redirect)

## 1. 题目分析

两个采购 Agent 都回复“申请已提交”。第一个核实预算、完成审批后，只创建了一条正确记录；第二个跳过审批，超时后又重复提交了一次。如果评测只把最终回复交给另一个模型打分，两者可能都拿到高分。

再看第三个 Agent：它严格遵守流程，也提交成功，但为了完成同样的任务，调用模型二十次、重复检索十几轮。它不一定有正确性问题，却可能根本不适合生产环境。

**Agent Eval 平台需要回答三个问题：任务到底有没有完成，执行过程是否可靠，以及这份结果付出的代价与风险是否可接受。** 最终结果、Planning、Tool Calling、Trajectory、成本和安全性是六个相互关联、不能互相替代的评测维度。平台的职责不是给 Agent 排一个总分，而是提供可复核的证据，支撑问题定位和版本发布。

### 1.1 评测契约

评测起点不是挑一个裁判模型，而是定义任务的成功条件。一条用例至少包含用户请求、初始状态、执行身份、可用工具、业务约束、成功断言和资源预算。例如采购任务既要验证申请已提交，也要验证租户、金额、审批记录和提交次数；信息不全时，正确行为可能是澄清，而不是强行完成。

因此，测试集不能只是“问题—参考答案”。应当覆盖正常流程、缺失参数、工具异常、长链路任务和对抗输入，并按业务类型、难度、权限范围切片。生产失败样本脱敏后进入回归集，开发集用于调试，独立保留集用于验收；同一事件的改写问题不能一部分用于调参、一部分又充当独立测试。

每次实验固定数据集、Agent 代码、Prompt、模型配置、工具协议和评估器版本，并保存环境快照。参考答案、隐藏断言与评分规则不应暴露给被测 Agent。否则模型可能学会迎合测试，而不是完成业务。

### 1.2 平台架构

平台可以拆成用例管理、运行调度、隔离执行、证据存储、评估服务和发布决策六部分。用例是测试定义，实验是一组版本配置，一次试验则是某个用例的一次独立执行，三者分别用  `case_id` 、 `experiment_id` 、 `trial_id`  关联。

调度器通过有界队列分发任务，限制并发、Token 和总费用。执行器调用被测 Agent，工具指向有状态模拟服务或隔离测试环境；每次试验恢复相同初态，并隔离会话、缓存与长期记忆。录制回放适合稳定回归，但旧响应不一定适配新动作，还需在测试环境补充真实工具集成评测，不能把所有工具都写成“固定返回成功”。

![用例、隔离运行、证据存储与评估服务组成完整评测平台](附件资源/面试官：如何设计%20Agent%20Eval%20平台，评估结果、规划、工具调用、轨迹、成本与安全？/img_2.png)

用例、隔离运行、证据存储与评估服务组成完整评测平台采集层记录模型调用、工具参数与返回、状态变化、耗时和用量。调用使用  `span_id`  与父子关系关联，并行交接还要记录显式依赖；大文件存对象存储，结构化索引与评分存数据库。记录公开计划和动作依据即可，平台不依赖获取模型的隐藏思维链，也不能将生成的解释当作真实推理过程的证明。

评估服务异步消费证据，输出维度、分数、通过状态、证据位置和评估器版本。评分超时属于“未评定”，执行环境故障单独标记，不能悄悄从报表删除。评估器重试不必重跑 Agent；需要重跑时生成新的试验编号，保留原记录，避免只留下最好的一次。

### 1.3 结果核验

**最终结果必须同时检查交付内容和环境终态。** Agent 宣称完成，不等于业务完成；Anthropic 的 Agent 评测说明也明确区分执行记录与环境中的实际结果。

对于采购任务，评估器从受信任的测试数据库核验记录归属、字段和审批凭证，并检查是否出现额外申请。对于代码任务，执行测试验证功能与回归；对于研究报告，检查关键结论是否覆盖需求、引用是否真实支持结论。文本相似度只能作为辅助，同一个正确结果可能有多种表达。

![核对业务记录、审批凭证与额外副作用，而不是相信完成声明](附件资源/面试官：如何设计%20Agent%20Eval%20平台，评估结果、规划、工具调用、轨迹、成本与安全？/img_3.png)

核对业务记录、审批凭证与额外副作用，而不是相信完成声明可计算的字段、状态和不变量交给规则或程序断言；相关性、解释质量等开放问题才使用 LLM-as-Judge。裁判按明确量表返回分项结论和证据引用，不能只给一个没有依据的“八十分”。用人工标注集校准裁判，监测误判；版本盲测和交换答案顺序可以帮助识别偏好偏差，争议与高风险样本进入人工复核。

最终输出至少区分任务成功、部分完成、正确拒绝和任务失败。应当拒绝的任务被正确拒绝，可以满足该用例契约；可正常完成的任务被拒绝则不是成功。无法判定的样本保留原因，不能自动归入通过。

### 1.4 规划质量

Planning 评估的是**目标拆解、依赖关系和执行条件**，不是计划写得长不长。对显式规划器，可以要求输出结构化步骤、前置条件和完成判据，检查必要子目标覆盖率、依赖合法率、工具可用性与预算可行性。

采购任务中，“查预算”和“查制度”可能互不依赖，先后交换或并行执行都合理；“审批通过”必须先于“提交申请”，则是不可交换的约束。参考计划应表达必要子目标与偏序关系，而不是规定唯一的工具序列。

![计划检查必要依赖，实际轨迹允许合理的等价顺序](附件资源/面试官：如何设计%20Agent%20Eval%20平台，评估结果、规划、工具调用、轨迹、成本与安全？/img_4.png)

计划检查必要依赖，实际轨迹允许合理的等价顺序动态规划还需要故障用例：预算服务暂不可用、检索返回冲突证据、审批未通过时，Agent 是否重新选择合理路径或停止执行。重规划次数多不代表能力强，关键是是否依据新证据有效调整。

如果 Agent 没有显式计划，计划文本评分应标记为“不适用”，通过后续动作评估行为上的规划能力。评估不能要求它额外生成一段漂亮解释，再把这段解释当成正确决策的证据。

### 1.5 工具调用

Tool Calling 需要分层核验：是否应该调用、是否选对工具、参数是否正确，以及执行结果是否被正确使用。对应统计工具选择正确率、漏调率、误调率、参数语义正确率和结果使用正确率，分母分别绑定决策机会或调用次数，不能混成一个“工具成功率”。

Schema 合法只是最低要求。 `amount`  是数字，不代表金额单位正确； `order_id`  是字符串，也不代表它属于当前租户。租户身份应来自服务端鉴权上下文，不能相信用户或模型填写的租户 ID。工具等价性、日期容差和可选字段应由业务契约定义，不必要求 JSON 文本逐字相同。BFCL 的多轮评测结合状态与执行路径检查，也说明只看终态会遗漏某些只读工具行为。

![从工具选择和参数语义，一直核验到实际业务状态](附件资源/面试官：如何设计%20Agent%20Eval%20平台，评估结果、规划、工具调用、轨迹、成本与安全？/img_5.png)

从工具选择和参数语义，一直核验到实际业务状态模型调用决策与下游可用性需要分开统计。正确请求遇到服务超时，不等于工具选错；接口返回 HTTP 200，也不代表申请已经提交。平台还应验证异常处理：缺参时是否澄清，限流时是否遵守预算，写操作结果未知时是否查状态或走幂等恢复。

尤其要保留“模型提出的调用”和“执行层最终执行的调用”。参数被中间件修复后成功，代表系统修复有效，不能因此把模型原始参数也判为正确。

### 1.6 轨迹诊断

Trajectory 是实际发生的行动与观测序列，关注的不是“打算怎样做”，而是**每一步是否基于已有证据推动任务**。检查项包括必要步骤完成情况、顺序约束、结果到参数的数据传递、无效循环、重复副作用和终止时机。

严格逐步匹配只适合强约束流程。开放任务需要允许等价路径、并行执行和必要的探索。LangChain 的轨迹评估器提供严格、无序及子集等匹配模式；平台应按业务选择规则，必要时用依赖图验证，而不是把参考轨迹当唯一答案。

重复调用也不能直接判错：状态变化后重新查询可能必要，相同状态下无限重复才是问题。轨迹长度和重复率适合发现异常，不能脱离任务语义直接决定质量。

定位失败时，报告应链接到最早违反约束的步骤。例如证据检索正确，工具也执行成功，但返回的“待审批”被误读成“已批准”，那么问题落在结果解释与状态推进。可以固定此前状态，只替换该步输出再回放，验证故障假设；这种对照实验有助于归因，但不能仅凭时间先后就宣称找到了根因。

### 1.7 成本效率

成本核算覆盖一次任务的全部执行，包括失败尝试、重试、模型切换、检索、工具与必要的人工介入。模型用量按供应商的计费字段与价格版本结算，缓存、输入、输出及推理 Token 先统一口径，避免重复收费。OpenTelemetry 的 GenAI 用量约定明确指出，缓存输入与推理输出分别属于相应的输入、输出总量；细分项不能简单再次相加。

更有业务意义的指标是：

**每个合格任务成本 = 全部被测运行成本 ÷ 合格任务数。**

合格表示同时满足任务契约与安全要求。分子不能只统计成功任务，零成功时应报告“无合格产出”，不能显示零成本。模型裁判、评测基础设施与人工标注属于评测平台自身费用，需要另建账目。

![示意账本：请求更便宜，不一定代表每个合格结果更便宜](附件资源/面试官：如何设计%20Agent%20Eval%20平台，评估结果、规划、工具调用、轨迹、成本与安全？/img_6.png)

示意账本：请求更便宜，不一定代表每个合格结果更便宜以同一批一百项任务为例，方案 A 总成本一百个成本单位、合格五十项，每个合格结果成本为二；方案 B 总成本一百五十、合格九十项，约为一点六七。这里是说明口径的算例，并非实测价格。

效率还应同时观察完成时延的 P50、P95、超时率和模型调用次数。端到端时延包含排队与重试，并行步骤不能直接累加为总耗时；超时与未完成任务单独报告，不能靠排除慢失败美化 P95。版本比较必须在相同任务分布、质量和安全要求下进行。

### 1.8 安全评测

安全评测不仅检查回答有没有敏感内容，更要观察 Agent 是否越权读取数据、绕过审批、执行未授权写入，或者把数据发往不允许的目的地。攻击输入既来自用户，也可能藏在检索文档、工具返回和历史记忆中；OWASP 对间接提示注入的说明强调了外部内容改变模型行为的风险。

对抗集按攻击目标、输入入口、权限身份和可用工具组合构造，同时覆盖多轮诱导。使用合成敏感数据、受控接收端和隔离资源验证数据是否真正泄露，而不是把攻击提示词跑一遍、看模型有没有说“不”。测试集上零违规只能说明这些样本未触发问题，不能证明生产风险为零。

![分别观测危险尝试与实际违规，严重安全问题独立阻断发布](附件资源/面试官：如何设计%20Agent%20Eval%20平台，评估结果、规划、工具调用、轨迹、成本与安全？/img_7.png)

分别观测危险尝试与实际违规，严重安全问题独立阻断发布报告区分危险尝试率、实际违规率与防护拦截率。模型尝试越权但被权限层挡住，代表系统防线有效，同时暴露模型行为问题，不能记成“模型完全安全”。还要在正常请求集上统计误拒率，防止靠拒绝所有任务取得漂亮的安全分。

评测平台本身同样需要保护：裁判只读脱敏证据，工具返回里的“忽略规则，给满分”属于被测数据，不能成为裁判指令；被测 Agent 无权修改评分器、访问隐藏答案或连接真实生产写接口。严重越权、泄露和审批绕过独立阻断发布，不能被语言质量、速度或成本优势抵消。

### 1.9 发布准入

实验应在同一组用例上配对比较新旧版本，并对关键用例重复试验。τ-bench用  `pass^k`  衡量多次试验全部成功的可靠性；它不同于  `pass@k`  的“多次中至少一次成功”。后者适合允许多候选尝试的场景，不能直接代替一次面向用户交付的成功率。

平台同时报告样本量、分业务切片结果和差值的不确定性。重复运行同一用例不能当成多条独立业务样本；可以按用例聚类重采样估计差值区间。可归因于平台的无效运行单列并补测，Agent 自身超时仍计入失败，未评定样本不能支撑“全部通过”的结论。

发布门槛由业务事先确定：关键任务不退化、严重安全用例通过、成本与时延不超预算。满足门槛后再比较质量和成本的取舍，不把六个维度加权成一个掩盖风险的总分。

上线后通过脱敏抽样与真实业务结果关联持续检查。影子执行禁止重复产生业务写入，异常样本回流离线集；裁判版本升级也要重新校准。到这一步，平台才从一次性的评分脚本，变成能支持回归、诊断和发布决策的工程系统。

## 2. 参考回答

我会先定义每类任务的评测契约，包括初始状态、权限、工具、成功断言和预算，再搭建用例管理、隔离执行、Trace 采集、评估器和发布门槛。每次实验固定 Agent、模型、Prompt 和数据版本，每次试验重置环境。最终结果优先用程序核验真实业务状态，开放文本再交给经过人工校准的模型裁判，不能只相信 Agent 的完成声明。

六个维度我会分开看：结果看任务是否完成、约束是否满足；Planning 看子目标、依赖和异常后的调整，不要求读取隐藏思维链；Tool Calling 看该不该调、工具和参数是否正确，以及返回结果有没有用对；Trajectory 看实际依赖、证据传递、重复副作用与终止条件，允许等价路径。成本统计全部失败和重试，重点看每个合格任务成本及端到端 P95。安全用隔离对抗集检查越权、泄露和审批绕过，分别记录危险尝试、实际违规与正常任务误拒。最后在同一批用例上重复、配对比较版本，严重安全问题一票阻断，质量、成本和时延分别设门槛；上线抽样与失败样本回流，形成持续回归体系。

## 学习交流

> 如果您觉得文章有帮助，点个关注哦。秀才后面会在公众号分享**大模型应用开发面试真题**。同时，秀才也会将这些大模型面试题整理到了我的学习网站：**https://golangstar.cn**，欢迎大家上我的网站学习，网站学习更高效哦！

**AI Agent项目**

> [AI模拟面试官](https://mp.weixin.qq.com/s?__biz=Mzk0MTYxNDgyNA==&mid=2247494548&idx=1&sn=86554b8c20d457c28811ca153f76e049&scene=21#wechat_redirect)
> [API开放平台智能客服系统](https://mp.weixin.qq.com/s?__biz=Mzk0MTYxNDgyNA==&mid=2247494604&idx=1&sn=1a3bad9b2ad2c05e43ac26cd0975bfa8&scene=21#wechat_redirect)

**大模型面试题系列**

> [字节大模型一面：在构建一个复杂的 Agent 时，你认为最主要的挑战是什么？](https://mp.weixin.qq.com/s?__biz=Mzk0MTYxNDgyNA==&mid=2247493275&idx=1&sn=8ba0658b0ac96225056cb1f14377a2b7&scene=21#wechat_redirect)
> [京东大模型二面：你知道哪些方法可以提高RAG的检索正确率？](https://mp.weixin.qq.com/s?__biz=Mzk0MTYxNDgyNA==&mid=2247493851&idx=1&sn=fa71312412d7619fbcd68c8a8859e473&scene=21#wechat_redirect)
> [美团大模型二面：Memory是Agent的一个关键模块，请问如何为Agent设计短期记忆和长期记忆系统？可以借助哪些外部工具或技术？](https://mp.weixin.qq.com/s?__biz=Mzk0MTYxNDgyNA==&mid=2247493257&idx=1&sn=6d254b0bc6da95a686a503702d6da2be&scene=21#wechat_redirect)
> [快手大模型二面：假如说要设计一个多轮对话Agent，你会怎么设计？](https://mp.weixin.qq.com/s?__biz=Mzk0MTYxNDgyNA==&mid=2247493760&idx=1&sn=092842db70c6f77d41eaeef245b0ff68&scene=21#wechat_redirect)
> [京东大模型二面：请详细解释 ReAct 框架，它是如何将思维链和行动结合起来，以完成复杂任务的？](https://mp.weixin.qq.com/s?__biz=Mzk0MTYxNDgyNA==&mid=2247493201&idx=1&sn=03aa63f0ceb0555283c420118e41a966&scene=21#wechat_redirect)
> [小米大模型二面：RAG 检索不到问题时如何定位问题？排查思路是什么？](https://mp.weixin.qq.com/s?__biz=Mzk0MTYxNDgyNA==&mid=2247493718&idx=1&sn=627c2bb41b9c84214da8572ad02f26a6&scene=21#wechat_redirect)
> [京东大模型二面：RAG系统中如何进行query改写，以及如何基于检索结果构建有效prompt？](https://mp.weixin.qq.com/s?__biz=Mzk0MTYxNDgyNA==&mid=2247494049&idx=1&sn=b6c831cfa6e911aafd63b6febc1fd062&scene=21#wechat_redirect)

**后端面试题系列**

> [【2025最新版】Go面试真题大合集（含答案）](https://mp.weixin.qq.com/s?__biz=Mzk0MTYxNDgyNA==&mid=2247490689&idx=2&sn=e6e2545ce41e16f7ca846b6e3c75cce8&scene=21#wechat_redirect)
> [【2025最新】Mysql面试真题（图文并茂版）](https://mp.weixin.qq.com/s?__biz=Mzk0MTYxNDgyNA==&mid=2247491596&idx=1&sn=f82ebacc41729e1455594fe9149cf35a&scene=21#wechat_redirect)
> [【2026最新】Redis面试真题（图文并茂版）](https://mp.weixin.qq.com/s?__biz=Mzk0MTYxNDgyNA==&mid=2247494347&idx=1&sn=301e8f89a62f879f2d81b4ee70ebdd1a&scene=21#wechat_redirect)
> [【2026最新】消息队列面试真题（图文并茂版）](https://mp.weixin.qq.com/s?__biz=Mzk0MTYxNDgyNA==&mid=2247494444&idx=1&sn=4e5325bf515e96c66639baeb0f324afb&scene=21#wechat_redirect)

**Vibe Coding系列**

> [越来越火的 Vibe Coding 究竟是什么？](https://mp.weixin.qq.com/s?__biz=Mzk0MTYxNDgyNA==&mid=2247494569&idx=1&sn=c35660b68c11998ded09c46f33d43893&scene=21#wechat_redirect)
> [Claude Code 快速上手核心指南！看这篇就够了](https://mp.weixin.qq.com/s?__biz=Mzk0MTYxNDgyNA==&mid=2247494658&idx=1&sn=dfa9d92540e24fab438e577ec912f68c&scene=21#wechat_redirect)
> [Claude Code的CLAUDE.md 配置应该怎么写？](https://mp.weixin.qq.com/s?__biz=Mzk0MTYxNDgyNA==&mid=2247494696&idx=1&sn=fb77b4564927628f7b98e7f099d360fd&scene=21#wechat_redirect)
> [Claude Code的斜杠命令有哪些实用技巧](https://mp.weixin.qq.com/s?__biz=Mzk0MTYxNDgyNA==&mid=2247494792&idx=1&sn=85388ae8a558c415c800a5d5a556e6a7&scene=21#wechat_redirect)
> [Claude Code怎样接MCP Server](https://mp.weixin.qq.com/s?__biz=Mzk0MTYxNDgyNA==&mid=2247494819&idx=1&sn=badb6d366cc3ad7240c08bf88eb0b796&scene=21#wechat_redirect)
> [Claude Code的子代理你用过吗？](https://mp.weixin.qq.com/s?__biz=Mzk0MTYxNDgyNA==&mid=2247494916&idx=1&sn=1d5836e9e237534999bba4343613c36d&scene=21#wechat_redirect)
> [如何用Claude Code的Hooks自动跑格式化、测试和安全检查？](https://mp.weixin.qq.com/s?__biz=Mzk0MTYxNDgyNA==&mid=2247494964&idx=1&sn=7420734f7a47d56e066c34c592fd361d&scene=21#wechat_redirect)
> [Claude Code的Skills该如何写？](https://mp.weixin.qq.com/s?__biz=Mzk0MTYxNDgyNA==&mid=2247494971&idx=1&sn=476ee31ddc7d6b747c07a626fa4a37c9&scene=21#wechat_redirect)
> [你用过哪些Claude Code插件？](https://mp.weixin.qq.com/s?__biz=Mzk0MTYxNDgyNA==&mid=2247494978&idx=1&sn=1a4c024628c5cb0263b29e610f5823f5&scene=21#wechat_redirect)
> [一套工作流让Claude Code又快又稳！](https://mp.weixin.qq.com/s?__biz=Mzk0MTYxNDgyNA==&mid=2247494978&idx=1&sn=1a4c024628c5cb0263b29e610f5823f5&scene=21#wechat_redirect)

**LangChain实战系列**

> [大模型初体验：DeepSeek本地部署](https://mp.weixin.qq.com/s?__biz=Mzk0MTYxNDgyNA==&mid=2247486015&idx=1&sn=720977dc0d18bebffcb546c3490c86ef&scene=21#wechat_redirect)
> [LangChain+DeepSeek小白入门大模型应用开发(1)](https://mp.weixin.qq.com/s?__biz=Mzk0MTYxNDgyNA==&mid=2247486089&idx=1&sn=263d84302757e9c0ca145eea88238903&scene=21#wechat_redirect)
> [大模型应用开发入门系列(1)：Hello LangChain](https://mp.weixin.qq.com/s?__biz=Mzk0MTYxNDgyNA==&mid=2247486155&idx=1&sn=5dae9ccc0dabb35b879c222250bd7508&scene=21#wechat_redirect)
> [LangChain框架入门系列(2)：Model I/O](https://mp.weixin.qq.com/s?__biz=Mzk0MTYxNDgyNA==&mid=2247486314&idx=1&sn=bac68d35e860569f13acf19a7495fa1d&scene=21#wechat_redirect)
> [LangChain框架入门系列(3):数据连接](https://mp.weixin.qq.com/s?__biz=Mzk0MTYxNDgyNA==&mid=2247486466&idx=1&sn=e8dc616d01d7032a66a0559446bc0c3e&scene=21#wechat_redirect)
> [LangChain框架入门系列(4)：链](https://mp.weixin.qq.com/s?__biz=Mzk0MTYxNDgyNA==&mid=2247486551&idx=1&sn=699c687a51bf8c03c4b17c86d733724f&scene=21#wechat_redirect)
> [LangChain框架入门系列(5)：Memory](https://mp.weixin.qq.com/s?__biz=Mzk0MTYxNDgyNA==&mid=2247486782&idx=1&sn=759a75c5eecf266ee566946aca43c3df&scene=21#wechat_redirect)
> [LangChain框架入门系列(6)：RAG](https://mp.weixin.qq.com/s?__biz=Mzk0MTYxNDgyNA==&mid=2247487264&idx=1&sn=b79f1f69057757aa17d04796cbf743f2&scene=21#wechat_redirect)
> [LangChain框架入门系列(7)：Agent](https://mp.weixin.qq.com/s?__biz=Mzk0MTYxNDgyNA==&mid=2247487336&idx=1&sn=515606200186ed720171378eeb10e99e&scene=21#wechat_redirect)
> [LangChain框架入门系列(8)：Callbacks](https://mp.weixin.qq.com/s?__biz=Mzk0MTYxNDgyNA==&mid=2247487383&idx=1&sn=7352b429c8c7447355bf1516faa56378&scene=21#wechat_redirect)

---
原文链接：https://mp.weixin.qq.com/s?__biz=Mzk0MTYxNDgyNA%3D%3D&mid=2247495666&idx=1&sn=e09eb7a751a146535925d7d8da1115ef&chksm=c2cd1c75f5ba95633622a26151c457d862a9e52be3193817ab3794f90821816ee4681cacdcad
