---
source_url: "https://mp.weixin.qq.com/s?__biz=MzA3OTQwNDAxMw%3D%3D&mid=2247483654&idx=1&sn=0d98edd56f1e60b38eea397c59781876&chksm=9fb54f84a8c2c6929650b728a1943228966f9ca8ccb23b715715f5f90383f16c27bc1b9ed27b"
title: "Harness实践：OpenSpec + Superpowers + CodeGraph + Ponytail + Caveman + RTK（上）"
account: "若水AI行者"
published_at: "2026-08-31 20:40:05"
saved_at: "2026-09-18 18:28:12"
sync_id: "art_6d96d36acdb94fd58f309477cb4f5841"
parse_status: "ok"
---

# Harness实践：OpenSpec + Superpowers + CodeGraph + Ponytail + Caveman + RTK（上）

# 7 个开源项目，整合出一套实操落地的 AI 编码 Harness，方便使用。

> 流程有人管、检索有人管、生成有人管、输出有人管、执行有人管——五个环节各守一道闸。
> 文章分三步走：**第一节**说清楚 AI 编码为什么会失控，以及治住它需要解决哪五个问题；**第二节**逐个介绍 7 个开源项目，看它们各自守的是哪道闸；**第三节**把其中五个组合成一套能直接落地的 Harness，附 Claude Code 和 Codex 的完整配置。
> 关于数据来源，先交代一句：文中每个数字都标了出处。**A 级是本轮在自己机器上复现的**，**B 级是项目官方 README / 文档 / 博客的声明，但我没有独立复测**，**C 级来自二手信息**。凡属时效性强、可能随版本变化的信息，文末附一张**时效性信息清单**；如需引用，请以各项目 GitHub 的最新信息为准，或自行验证。

## 一、AI 编码为什么会失控：五个要害

用 AI 写代码久了会有个体感：失控的从来不是模型不够聪明，而是没人给它划跑道。换个更强的模型，往往只是让失控来得更快、账单更大。

所谓 Harness，就是套在模型外面那层工程外壳。它要解决的是下面五个主要问题——这也是贯穿全文的主线。

### 1.1 上下文工程：三个口子在漏 token

模型的上下文窗口是稀缺资源，而 agent 每转一圈，就有三个口子往里灌东西：

- 读 为了搞懂一个函数，先 grep 一轮，再 Read 十几个文件——探索成本原样进了窗口，也进了账单；
- 拿 跑一次测试吐回 200 行日志，  `ls -la`  又是 50+ 行——命令输出整段倒进上下文；
- 说 寒暄、铺垫、免责声明、最后再来一段总结复述——对话里的废话同样按 token 收费。

三个口子各配一个节流阀，互不重叠：**CodeGraph 管「读」、RTK 管「拿」、Caveman 管「说」**，Comet 的 Context Compression 再在阶段交接时把牢门禁。

上下文工程也有反面，而且不止一个：CodeGraph 官方承认检索用久了会有约 80% 的上下文残留在窗口里（详见 2.2 节）；RTK 官方声明输出削减会被逐层稀释，不等于账单打一折（详见 2.3 节）；Caveman 更是自曝在简洁任务上净收益可能为负（详见 2.5 节）。**省了一头，往往胀了另一头。**

### 1.2 工具的设计：给什么工具，决定它怎么干活

给模型什么工具、工具长什么样，直接塑造 agent 的行为。这一层有四个反直觉的经验：

- 工具不是越多越好 。CodeGraph 只往外暴露一个 MCP 工具  `codegraph_explore`  ，另外 7 个能力藏着不往外列。官方的说法是：一个强工具，比一堆窄工具更能引导 agent 做对选择。
- 改写胜过说教 。RTK 从不劝 agent「别读长日志」——它在 PreToolUse 钩子里直接把  `git status`  改成  `rtk git status`  。agent 全程没感觉，行为已经被改掉了。
- 入口要收敛 。Comet 在每个平台只装一个 Rule 加一个 Hook Router，再按配置分发。否则五六个工具各装一套 hooks，迟早打架。
- 能力要有能覆盖到子代理的入口形态 。CodeGraph 除了 MCP server，还提供一套完整 CLI（  `codegraph explore "<你的问题>"`  ，输出与 MCP 工具相同）——因为 MCP 的使用指引只送达主 agent，子代理（比如 Claude Code 的 Explore subagent）根本看不到，拿到任务还是只能 grep 乱翻；命令行则谁都能调。至于这套 CLI 到底省多少，我在自己的一个项目上做了一组对照：同一查询走 CodeGraph 比走「grep + Read」少吞进 96.7%–99.2% 的字节（完整数据见 2.2 节）。

### 1.3 状态和记忆：遵循 SDD

「会话污染」是 agent 最大的健壮性漏洞：会话过程中，焦点不断偏移，LLM能够抓住很多细节但好像总是抓不住核心重点；需求改了三轮，没人说得清哪一版才是最终版。

把状态存进文件只是治标。这件事背后有个更硬的方法论：**SDD（Spec-Driven Development，规范驱动开发）**。它的核心主张比「持久化」激进得多——

> **规范是唯一真相，代码只是规范的实现产物。**

OpenSpec 官方的原话是 _"One source of truth your whole team and every coding agent can read"_。落到做法上，SDD 有四条原则：

- 规范先行 动手写代码之前，先写清楚「要做什么、做到什么算完」。AI 从不缺写码能力，它缺的是没有歧义的需求——需求含糊时，再强的模型也只是把猜测写得更快；
- 变更先改规范 需求变了，先更新 spec，再由 spec 推导出实现要改什么。OpenSpec 用 delta spec 表达这件事（格式是  `## ADDED Requirements`  →  `### Requirement:`  →  `#### Scenario:`  ，明确标注这次是新增、修改还是移除），而不是改完代码回头补文档；
- 规范即验收标尺 spec 里写的是可验证的场景，不是形容词。有了它，验证阶段才有可对照的标尺，而不是靠「感觉做完了」；
- 规范是人机协作的评审界面 人审的是一份几百字能读完的 spec，不是几千行读不完的 diff——这是人工介入成本最低、收益最高的位置。

为什么它对 AI 编码尤其关键？对话式需求（想到哪说到哪）有三个致命伤：上下文一断就没了、中间过程没人能审、做完了没有对照物。SDD 把「散落在对话里的意图」固化成「项目里的文件」，由此换来四件事：

- 可回溯 三轮需求变更留下三份 proposal，谁都能看清是怎么一步步演变到今天的；
- 可跨会话 规范是文件，换 session、换人、换 AI 工具都能接着干；
- 可沉淀 实现完成后 delta spec 合并回主 spec，需求库随时间长成一份「活文档」；
- 可在写码前拦错 设计阶段有明确的人工确认点，需求理解错了在动工之前就被发现。

在这套 Harness 里，SDD 落在两处：**Comet** 在 active workflow、Router Hook 生效且目标路径受 Guard 管辖时，用阶段门禁阻止越阶段写入（见 1.5 节），并把每次变更的阶段与状态写进项目内的 Runtime / change 状态文件；**OpenSpec** 负责四件套产物（proposal / design / tasks / specs）与归档时的 delta 合并。

一点诚实的补充：第 4 条在 Native 工作流里要打个折——Native 把验证交给独立的只读 Verifier，不再强制人工审 spec，这是它给强模型的自由度（详见 2.1 节）。

### 1.4 验证回路 + 评测集：遵循 TDD

「agent 说做完了」和「真的做完了」之间，隔着一条必须有人守的线。守这条线的方式，正是 **TDD（Test-Driven Development，测试驱动开发）**。它的循环很短：**红**——先写一个失败的测试，把「做完」的定义固化成可执行的东西；**绿**——写刚好能让测试通过的实现；**重构**——在测试的保护下收拾代码。

注意它和上一节的衔接：SDD 的 spec 里那些  `#### Scenario:`  描述的行为，落到 TDD 里就是一条条具体的测试用例。**规范负责定义「做到什么算完」，测试负责把它变成机器能判定的东西。**「绿」这一步要求的「刚好通过」，又和 1.5 节 Ponytail 的最小实现是同一个取向。

这个题目下其实有两套机制，一个管运行时，一个管演进：

- 验证回路（运行时） Comet 的验证证据门——没有真实存在的 verification report 就别想过关，由脚本校验而不是听 agent 汇报；Native 工作流还会派一个独立的只读 Verifier，写代码的人不能给自己判卷；Superpowers 按变更配置启用 TDD 和两阶段审查；RTK 的 tee 留了底牌，命令失败时完整原始输出自动落盘，随时回看。
- 评测集（演进时） 严格说这一层已经不属于 TDD 了——TDD 验的是「这次代码对不对」，评测集验的是「这套流程本身靠不靠谱」，属于对方法的元评测。Comet 自带  `comet eval`  ，可以给任何 Skill 跑标准化评测、用独立的 LLM-as-Judge 打分、把结果同步到 LangSmith / LangFuse。

官方的评测方法学也值得抄作业：Comet 用 **pass^3**（连续三次全过才算稳定）而不是单次通过率；CodeGraph 做对照实验时，连控制组都不许偷用被测工具，28 次运行做到 0 污染。

**这两节的关系可以用一句话记住：SDD 定义「要做什么、做到什么算完」，TDD 证明「已经做完」——前者是契约，后者是证据。**

### 1.5 熵减：三种熵在同时增长

熵增是长任务、长会话的必然。但把它理解成「代码越写越乱」就窄了——agent 系统里其实有三种熵在同时涨：

- 流程熵 范围蔓延（一个 bugfix 改着改着动了半个模块）、阶段跳跃（设计还没确认，代码已经写了三千行），以及最隐蔽的 目标漂移 ——做着做着偏离了最初的目标，而且 agent 自认为还在正轨上；
- 代码熵 过度工程（装个日期选择器要引第三方库 + 包装组件 + 样式表）、同一个功能被写出三套实现；
- 上下文熵 多轮之后窗口里堆满过时信息、失败尝试和无关输出，模型的注意力被稀释。这一条常被忽略，但它正是 1.1 节 CodeGraph 那 80% 残留、以及 Comet Context Compression 存在的动因。

Comet 把自己的守卫命名为 **Anti-drift Phase Guards**（面向长上下文会话的防漂移守卫），主打流程熵：当 active change 存在、Router Hook 已受信任并命中受管辖路径时，Hook Router 会把文件写入路由到当前工作流的 Guard——Native 只允许在 Build 阶段写实现代码，Classic 允许 Build 和 Verify。当前机器已确认 Router 安装与信任状态，但尚未做完整的阶段拒绝对照实验，有继续提升的空间。

另外两道闸：

- Ponytail 的懒人阶梯 写代码前强制走一遍七层决策——「这东西需要存在吗 → 代码库里已有吗 → 标准库能做吗 → ……」，熵在生成端就被压掉；
- 路由门禁与归档闭环 团队规则决定什么任务值得进流程；阶段守卫和归档共同形成生命周期闭环。

两点诚实的补充：一是**闭环不等于「只减不增」**——验证失败时允许退回 Build 重来，这是必要的返工通道；二是**上下文熵目前只能缓解、不能根除**——压缩本身就会丢信息，Comet 的 Context Compression 同样是拿 5% 的 spec 覆盖率去换 token（见 2.1 节）。

先看全景图，再进第二节逐个拆：

| 问题 | 环节 | 工具 | 一句话定位 | 在 Harness 中的角色 |
| --- | --- | --- | --- | --- |
| 状态和记忆 + 验证回路 + 熵减 | 流程编排 | ** Comet ** | 把 SDD 阶段串成可执行的状态机 | 非平凡开发任务的流程主入口 |
| （Classic 配套）需求规格 | WHAT | OpenSpec | proposal / specs / tasks | Classic 中由 Comet 管理，按 adapter 调用 |
| （Classic 配套）工程方法 | HOW | Superpowers | brainstorming / TDD / 子代理 | Classic 中由 Comet 按阶段调用 |
| 上下文工程 + 工具设计 | 检索 | ** CodeGraph ** | 预索引代码知识图谱，替代乱 grep | 中大型代码仓库推荐；小仓库/文档库按需 |
| 上下文工程 | 执行 | ** RTK ** | 命令输出过滤器，减少日志噪音 | 执行端（推荐） |
| 熵减 | 生成 | ** Ponytail ** | 懒人决策阶梯，从源头少写代码 | 生成端（ ** 可选 ** ） |
| 上下文工程 | 输出 | ** Caveman ** | 电报体回复，砍掉客套话 | 输出端（ ** 可选 ** ） |

## 二、七个开源实现：七件工具，各管一道闸

> 这一节每个项目只讲四件事：它是什么、它怎么起作用、官方给的数据是多少、它管不了什么。想直接上手，跳到第三节看完整配置。

### 2.1 Comet：流程编排层，管「什么时候做、下一步做什么」

**GitHub：https://github.com/rpamis/comet**（rpamis 出品，MIT 许可；Classic 工作流里内嵌 OpenSpec 管需求、Superpowers 管工程方法）

**主要解决：状态和记忆 · 验证回路 + 评测集 · 熵减**

Comet 是整个 Harness 的主入口，管的是编排。它提供两条互不干扰的工作流：

- Native（给强模型用） 四阶段 Shape → Build → Verify → Archive 。只依赖自己的运行时，不依赖 OpenSpec、Superpowers，连 Bash/Git Bash/WSL 都不需要——纯 Node 就能跑。Shape 澄清需求、写 brief 和目标规格并等你确认；Build 让模型自己挑实现路径；Verify 派一个 独立的只读 Verifier 去验收；Archive 用可恢复事务收尾。官方原话：「Native 是给能自主规划、自主验证的强模型用的」。入口  `/comet-native`  。什么是强模型？Fable 5或接近的模型。
- Classic（给需要完整方法论约束的场景） 五阶段 Open → Design → Build → Verify → Archive ，也就是 OpenSpec + Superpowers 那套完整阶段治理。官方原话：「Classic 是给从完整分阶段方法论和更强约束中受益的场景用的」。入口  `/comet-classic`  。

两条工作流**互不升级**，不是「轻量版 / 重量级」的关系。共享入口  `/comet`  会读项目配置决定转发给谁，不靠猜任务大小。

**官方评测（0.4.0-beta.7，B 级官方自述）**：Native 与 0.4.0 Classic 的对齐实验——16 个工作流任务 × 48 次运行，挑出 41 对「两边都通过」的样本做对比：**总 Token −76.8%、轮次 −57.4%、耗时 −47.4%、pass^3 87.5%（+12.5pp）、pass@3 100%**。只比两边都通过的样本对，是种保守的公平对比；pass^3（连续三次全过）也比单次通过率严格得多。这组数字是 Comet 自己跑出来的，我没有复测。

**状态和记忆怎么落地**。两套工作流的 Runtime 分别落盘，路径与状态格式不同，需要分开说（以下为 0.4.0-beta 官方口径，README 原文印证 "Native stores user-readable artifacts under  `docs/comet/`  by default, while machine Runtime is fixed under the project-local  `.comet/runtime/native/` "）：

- Native 用户可读产物默认在  `docs/comet/`  （想换位置就设  `native.artifact_root`  ，比如  `artifacts/comet/`  ）；机器 Runtime 固定在项目内的  `.comet/runtime/native/`  ，下面分  `changes/<id>/`  （  `state.json`  与日志）、  `locks/`  、  `transactions/`  ；「当前 change 归谁」记在  `.comet/current-change.json`  ；
- Classic 产物布局由  `classic.artifact_layout`  控制——新项目是  `docs`  （即  `docs/openspec/`  +  `docs/superpowers/`  ），老项目若保留 legacy，OpenSpec 根在仓库级  `openspec/`  、Superpowers 仍在  `docs/superpowers/`  ；变更级状态在  `<classic-change-dir>/.comet.yaml`  ，引擎机器态在  `<classic-change-dir>/.comet/run-state.json`  （camelCase 字段：  `currentStep`  /  `status`  /  `iteration`  ），审计日志是  `<classic-change-dir>/.comet/state-events.jsonl`  ；
- 共享  `.comet/config.yaml`  是唯一的 Comet 项目级配置 （含 schema、default_workflow、workflows、ambient_resume、hook.allow_paths、classic. 、native. ）。

Hook 路由也是共享的：每个平台装一个  `comet-workflow-guard`  Rule，有 Hook 能力的平台只装  `comet-hook-router.mjs`  一个入口，由  `current-change.json`  决定这次写请求落到 Native 还是 Classic 的 Guard—— **不会两边同写**。另外 0.4.0-beta 起整套 Runtime 是纯 Node（TypeScript 编译后由 node 执行），不依赖 Bash/WSL。

**验证回路怎么落地**：Verify 阶段必须有真实存在的 verification report，由脚本校验；注意这时候  `branch_status`  还是  `pending` ，要等归档提交前才被置为  `handled` 。另外  `comet eval`  可以给任何 Skill 跑标准化评测，关键设计是**裁判和运动员分开**——主 Agent 与 LLM-as-Judge 各有独立的 agent / model / API 地址 / 凭证：

```bash
# comet/eval.yaml —— 评测配置：执行者与裁判分离（官方 README 示例）
execution:
  agent: codex
  model: subject-model
  baseUrl: https://subject.example/v1
judge:
  agent: claude-code
  model: judge-model
  baseUrl: https://judge.example/v1
```

常用入口有三类： `--collect`  做静态检查（不起 Agent/Docker）、 `--html`  出本地评测报告、 `--suite langsmith`  把结果同步到 LangSmith。它们仍依赖对应的评测配置与可写目录；本机 sandbox 中尚未完成端到端执行。

**熵减怎么落地——Anti-drift Phase Guards**，官方的说法是「面向长上下文会话的防漂移守卫」。阶段强制力不靠 prompt 说教，靠的是一条三层链路：

```swift
agent 发起文件写入
   │
   ▼
comet-hook-router.mjs        ← 平台唯一的 Hook 入口
   │  读 .comet/current-change.json 路由到恰好一个 Guard
   │  官方原话：一次写至多到达一个 Guard；
   │          归属歧义或过期 → fail closed（失败关闭，绝不猜）
   ▼
comet-guard.mjs / comet-native-hook-guard.mjs（Classic / Native 各自独立的 Guard）
   ▼
校验阶段退出条件 + 允许写入路径
```

- Rule 层 每个平台只装一个  `comet-workflow-guard`  规则，只套一套阶段模型；
- Hook 层 支持 Hook 的平台只装  `comet-hook-router.mjs`  一个 Hook（官方脚本表原话："The platform's only Hook entry"）；
- Guard 层 官方原话 "Native permits ordinary implementation writes only in Build; Classic permits them in Build and Verify"——Native 只在 Build 允许写实现，Classic 允许 Build + Verify。只有 active change、Router 已受信任且写入命中受管辖路径时，才会由 Guard 执行这项限制；「设计没确认，物理上写不了实现」是满足这些前提后的行为描述。

Guard 的核心约束包括入口校验、状态迁移守卫、isolation 与分支绑定、验证证据门。如果 agent 确实需要在非编码阶段写项目内的共享规则或团队笔记，就要在  `.comet/config.yaml`  里显式放行：

```bash
hook:
allow_paths:
- .agents/rules
- docs/team-notes
```

 `hook.allow_paths`  是 0.4.0 文档定义的**共享写策略字段**（shared entry field）。本项目当前配置未启用该字段，具体可用性可以自行验证。文档规则是：项目相对路径白名单、默认空列表；**前缀匹配、子目录继承**（放行  `docs/team-notes`  就等于放行它下面所有层级）；但  `.comet/`  Runtime 目录与 Classic 的 OpenSpec / Superpowers 产物根是禁区，靠它绕不过去，项目外路径则维持原有 scope 行为。README 原文印证："…this setting cannot bypass  `.comet`  or workflow artifact directories."

另外还有 Hotfix（跳过完整 brainstorming）和 Tweak（轻量档）两个快捷档位——注意它们在 Codex 里的菜单名是「Comet Classic 预设:Hotfix / Tweak」，详见 3.4。

#### Comet 怎么和 Claude Code / Codex 联动

先把安装的次数说清楚，这是最容易被误解的地方：

-  `npm install -g @rpamis/comet`  装的是 CLI，一台机器装一次就够了
-  `comet init`  是给项目接上 Comet，一个项目目录跑一次 ——跑的时候由你选择要接哪些 coding agent（Claude Code、Codex、WorkBuddy、Antigravity……可以多选），也可以事后改配置；（注意，comet init可以配置全局，所有项目都遵循，但严重不推荐）
- 换项目就再  `comet init`  一次，CLI 不用重装；升级用  `comet update`  。

接上之后，「联动」由三个入口和两个共享点构成：

- 命令入口 Claude Code 用斜杠命令  `/comet`  ，Codex 用 skill 语法  `$comet`  。两边都有共享入口（按配置转发 Native/Classic）、逐阶段命令（  `/comet-open`  、  `/comet-design`  ……）和预设档。2026-08-29 历史实录显示  `$comet-native`  在 Codex 里可以直接敲（3.4 节有入口清单）；但 Hotfix / Tweak 在 Codex 里的名字是「Comet Classic 预设:Hotfix / Tweak」，不能照 Claude Code 的  `/comet-hotfix`  硬套。
- 写拦截入口 支持 Hook 的平台只装  `comet-hook-router.mjs`  一个 Hook。Claude Code 挂在原生 hook 系统的 PreToolUse 事件上；Codex 和 WorkBuddy 由  `comet init`  自动装好，不需要手工接线（项目级  `.codex/hooks.json`  ，matcher  `Write|Edit`  ，3.4 节有实测落盘）；
- 恢复入口  `comet init/update`  会把  `<comet-ambient-resume>`  托管块合并进  `CLAUDE.md`  /  `AGENTS.md`  ；项目规则要求在开始可能涉及 active workflow 的改动或调查前运行一次  `comet resume-probe`  。它只做只读探测，返回  `auto_resume`  /  `ask_user`  /  `out_of_scope`  /  `none`  四选一，再路由到对应入口。

两个共享点，是「状态和记忆」能跨平台生效的关键：

- 状态文件在项目里，不归任何平台私有  `.comet/config.yaml`  （工作流配置）、  `.comet/current-change.json`  （当前变更归属），加上 Native 的  `.comet/runtime/native/changes/<id>/`  或 Classic 的  `<classic-change-dir>/.comet.yaml`  与  `<classic-change-dir>/.comet/run-state.json`  （布局详见上文）。Claude Code 和 Codex 读的是同一份，换宿主不丢进度；
- Classic 会把 OpenSpec + Superpowers 的 skills 一起装进平台 skills 目录 （  `.claude/skills/`  下会出现  `openspec-*`  、  `brainstorming`  等）；Native 只装 Comet 自己的。

#### 本机  `comet init`  实录（v0.4.0-beta.20）

官方口径之外，放一份真实安装记录节选，让「联动」这件事落地可感：

```shell
Comet v0.4.0-beta.20 — You are on the latest version.
✔ 安装范围: 项目（当前目录）
✔ Comet 模式: 两者 — Native + Classic 双入口（/comet 默认 Native）
✔ 安装模式: Symlink（共享中央存储，节省空间）
✔ 平台: Claude Code, Codex, WorkBuddy, Antigravity 2.0
# OpenSpec：11 skills + 11 commands → .claude / .agents / .codebuddy/
#   "Codex, Antigravity share .agents/skills; writing one tree for codex"
# Superpowers：14 skills → .agents/skills/（universal；symlink → Claude Code）
#   安全审查（Gen / Socket / Snyk 三引擎）: 14 个全 Safe / 0 alerts / Low Risk
#   （using-git-worktrees Med Risk、using-superpowers 1 alert，如实标出）
# Comet：78 files/平台 + 1 规则 + Phase guard hook（Claude Code/Codex/WorkBuddy 实测装）
# CodeGraph：skipped（已有索引）/ CLI 已装 / MCP registered (global)
# 工作目录：Native → docs/comet/；Classic → docs/openspec/
```

这份实录暴露了两处「README 表格 vs 安装器实际行为」的差异：一是**Codex 的 skills 不在  `.codex/`  而在  `.agents/skills/` **（与 Antigravity 共用 universal 目录，Claude Code 侧用 symlink 指过去）；二是**Codex 与 WorkBuddy 的 Hook 由安装器自动装**，README 只笼统说「支持 Hook 的平台安装 Router」却没列名单，实测推翻了「需要手工接线」的猜测。另一个亮点是 Superpowers 安装时跑了 **Gen / Socket / Snyk 三引擎安全审查**，14 个 skill 全绿才落地，审查结果原样留在输出里（包括 using-git-worktrees 的 Med Risk 和 using-superpowers 的 1 个 alert）——供应链风险处理得比多数工具链透明。

另外还有  `comet dashboard` （本地只读仪表盘）、初始化时用  `--codegraph init|skip`  决定是否同时建 CodeGraph 索引，以及 **35 个 AI 编码平台**的覆盖（README 原文：「 `comet init`  supports 35 AI coding platforms」）。

还有一项 Classic 专属的 **Context Compression**：在 Design → Build 交接点开启后， `comet-handoff.mjs`  会生成紧凑上下文包，把 Build 阶段的输入 token 砍掉 25–30%，测试通过率不变，任务越大省得越多（大任务约 15,000 tokens）。代价是 **Spec 覆盖率从 100% 掉到 95%**——想省 token 就得接受这点边缘细节的损失。开关在  `.comet/config.yaml`  的  `classic:`  块下（ `context_compression: beta` ），默认  `off` ，本机也保持关闭。完整数据与出处见 4.1、4.2 节。

#### Classic / both 初始化时由 Comet 安装：OpenSpec 与 Superpowers

**OpenSpec**（https://github.com/Fission-AI/OpenSpec，MIT）—— **主要解决：状态和记忆**。它把「改代码」变成一条文档流水线：主入口  `/opsx:propose`  一次产出 proposal.md / design.md / tasks.md / specs/ 四件套（Cursor/Copilot 写成  `/opsx-propose` ，Codex 写成  `$openspec-propose` ），实现完成后把增量 spec 合并回主 spec 再归档。支持 **30+ 种 AI 助手**，要求 Node.js 20.19.0+。（安装Comet就不需要单独安装OpenSpec）。

**Superpowers**（https://github.com/obra/superpowers，MIT）—— **主要解决：验证回路**。一套可组合的编码方法论 Skills：brainstorming、writing/executing-plans（计划拆到 2–5 分钟粒度、带精确文件路径和验证步骤）、subagent-driven-development（两阶段审查）、test-driven-development、systematic-debugging。支持 **14 个平台**。（安装Comet就不需要单独安装Superpowers）。

它 6.0 那轮自优化过程（官方博客，B 级）本身就是「评测集驱动改进」的标本：三轮优化下来，审查包 shell 化省约 10%、双审查合并再省约 15%、25 轮实验花了约 165 美元换来简洁审查合同 −41%，官方口径是 "up to 50% faster / up to 60% cheaper"（注意 up to 是上限）。还有一个反直觉的发现：**限制 thinking token 反而更贵**——回合数从 92 涨到 138，输出翻倍。（版本 **6.3.0**，发布于 2026-08-12，本机已装版本一致。注意  `comet doctor`  对 Superpowers 只报 detected、明确说 version not recorded by skills installer，所以版本号得从官方发布页查。）

一句话收尾：**Comet 把「规范纪律」变成了自动执行的状态机，让团队从「能写好」变成「每次都写得好」。**

### 2.2 CodeGraph：检索端，管「读」（精准读代码）

**GitHub：https://github.com/colbymchenry/codegraph**（colbymchenry 出品，MIT 许可）

**主要解决：上下文工程 · 工具的设计**

CodeGraph 是一张**预先建好的代码知识图谱**：Rust 内核把符号、调用和依赖关系解析出来， `codegraph init`  一条命令建索引，之后文件监听会在你保存时增量同步。我这台机器上索引了 49 个文件、17,740 个节点、65,626 条边，状态 current。索引也会有延迟、有解析不了的语法，实在没命中就直接读文件，别跟它较劲。

**它真正的价值在「出事的时候」。** 平时写代码，快一点慢一点体感不强；真正要命的是程序报错、行为不对、要定位「问题代码到底在哪」。这时候 agent 的传统做法是 grep 一个关键词，命中几十个文件，再挨个 Read 进去看——窗口瞬间塞满，还经常找错地方。CodeGraph 的活法不一样：查询命中已索引的代码符号时，你可以用自然语言描述现象（比如「guard 在非 Build 阶段拦截了写入」），由它返回**相关符号的逐字源码 + 调用路径 + 影响半径**，每条都带着精确到行号的  `文件:行号` 。文档、配置、未支持语法或表述太宽的查询仍可能不命中，此时应直接读文件。本节末尾那组历史对照记录说的就是这种理想命中场景。

**官方基准（2026-08-05 复测，B 级官方自述）**：Claude Opus 4.8 × 7 个真实仓库（VS Code、Excalidraw、Django、Tokio、OkHttp、Gin、Alamofire），每个 arm 跑 4 次取中位数：

> **"The universal win — every repo, every size: 88% fewer tool calls · 53% faster · 62% fewer tokens · 44% cheaper · file reads cut to zero on all seven repos."**
> （工具调用 −88%、速度 +53%、token −62%、成本 −44%，**文件读取在全部 7 个仓库归零**。）

那是官方在人家自己挑的 7 个仓库上测出来的，不是我复测的，也不能直接外推成你项目的收益。

**2026-08-29 的一次本机对照（C 级历史记录）**：官方那组数字来自别人挑的仓库，当时在这个仓库上另做了一组对照——同一个定位任务，分别走「CodeGraph 一次调用」和「grep 定位 + Read 命中文件」两条路径。由于没有把完整命令、文件选择规则和字节统计脚本保存为可运行产物，下面的具体数字暂列：

| 查询 | CodeGraph（1 次调用） | grep + Read | 减少 |
| --- | --- | --- | --- |
| comet guard state transition | 14,261 字节 | 1,595,917 字节（grep 444 KB + 读 5 个文件） | −99.2% |
| hook router platform codex | 10,701 字节 | 318,714 字节（grep 30 KB + 读 1 个文件） | −96.7% |
| resume probe current change | 13,408 字节 | 1,416,630 字节（grep 450 KB + 读 5 个文件） | −99.1% |

口径必须说清楚：我这个仓库里堆着大量压缩过的  `.mjs` （单文件 289 KB–500 KB），grep 命中一行就是几十 KB，属于对 CodeGraph 特别有利的场景，别拿 −99% 当预期收益——官方跨 7 个仓库的 −62% 保守得多。这组实测真正说明的只有一件事：**在大文件和打包产物面前，grep 的代价被严重低估了。**

**代价也得说**，这是官方自己写在 README 里的：多轮会话里，检索上下文的残留会比文件读取基线多出约 80%。检索端省了探索，代价是窗口更满——长会话可以考虑配合压缩策略。

**工具设计上有两条值得抄的决策**：

- MCP 默认只暴露一个工具  `codegraph_explore`  一次调用返回符号源码 + 调用路径 + 影响半径。一个强工具，比一堆窄工具更能引导 agent 做对选择；
- 把用法写进 MCP initialize 响应和指令文件的 marker 段 直接告诉 agent「别用 grep 复查、把返回的源码当作已读」。因为子代理和非 MCP agent 看不到 MCP guidance，安装器还会往  `CLAUDE.md`  /  `AGENTS.md`  /  `GEMINI.md`  写一段围栏指引，专门教它们用 CLI。

**CLI 模式**： `codegraph explore "<你的问题>"`  提供和 MCP 探索相同的能力， `codegraph affected`  能顺着 import 依赖找出被改动波及的测试文件（CI 精准跑测试很好用）。CLI 与 MCP 在输出细节、计数口径上的差异取决于宿主和查询内容，我在本地测试中两者输出一致或相差无几。

其他要点：**100% 本地**（SQLite + FTS5，不需要 API key）；性能参考——Swift 编译器仓库（27k 文件）全新索引约 **100 秒**、单文件重同步约 4 秒，Linux 内核（70k 文件、200 万符号）在 2 核 VPS 上 **12 分钟**建完，再索引比最快的竞品 **快 2–7 倍**（31 仓库、30 语言基准）；**9 类 Agent**（Claude Code、Cursor、Codex CLI、opencode、Gemini CLI、Antigravity、Kiro、Copilot 等）由安装器自动写 MCP 配置。

边界也要讲清楚：CodeGraph 只能「劝」agent 别乱 grep，最终调不调还是模型说了算。所以实践中要把使用规则写进全局配置（3.3 / 3.4 有完整代码）。

### 2.3 RTK：执行端，管「拿」（砍日志）

**GitHub：https://github.com/rtk-ai/rtk**（rtk-ai 出品，Apache 2.0）

**主要解决：上下文工程（执行端）**

RTK 是守在 shell 出口的**命令输出过滤器**。官方定位原话：_"High-performance CLI proxy that cuts up to 90% of the bash output your agent reads"_——砍的是 agent 读到的 bash 输出，最多九成。单个 Rust 二进制，覆盖 100+ 命令，开销不到 10ms。截止2026-08-31，RTK 仓库约 78K star / 4,9 fork。

**它的机制是「钩子改写」，不是网络代理**——这是最值得学的一点。装好之后会注册一个 PreToolUse 钩子：agent 每次要跑  `git status` ，钩子在执行前把它改写成  `rtk git status` ；RTK 包住真命令拿到完整输出，压缩后只把摘要交回去。**agent 全程无感，行为却已经被改变。** 压缩就四招：**过滤**（去注释、空白、样板）、**分组**（按目录或错误类型聚合）、**截断**（长行砍尾）、**去重**（重复日志折叠成计数）。

官方削减幅度（bash 输出口径，不是账单口径）：

| 命令类型 | 代表命令 | 输出削减 |
| --- | --- | --- |
| 测试运行器 | pytest · cargo test · go test · jest | −90% |
| 编译 | cargo build · cargo clippy | −80% |
| Lint | ruff · golangci-lint · eslint | −80% ~ −85% |

典型对比：一次  `cargo test` （15 个挂 2 个）原样 200+ 行，RTK 版约 20 行； `git push`  15 行变成一行  `ok main` ； `ls -la`  45 行变成 12 行目录树。

**两个给验证回路兜底的设计**：

- tee 保险 命令失败时完整原始输出自动落盘（macOS 默认在  `~/Library/Application Support/rtk/tee/`  ，Linux 常见在  `~/.local/share/rtk/tee/`  ），摘要末尾带上路径。agent 想深挖就去翻日志，不用重跑命令：

```bash
full output: ~/.local/share/rtk/tee/1707753600_cargo_test.log
```

-

- 诚实稀释声明（官方原文） "…it is not the same as cutting your bill by 90%. Bash output is one contributor to input tokens…The reduction dilutes at every step." ——bash 输出只是输入 token 的一部分，输入又只是账单的一部分， 削减在每一层都被稀释 。RTK 按  `bytes / 4`  估算节省，百分比可靠，绝对 token 数只能算近似值。

**本机接线状态**（这是两侧差异最大的一个组件）：

- Claude Code PreToolUse hook 已启用，但只匹配 Bash——Read / Grep / Glob 不会被改写。想让这些也走 RTK，就改走 shell 命令，或者显式调  `rtk read`  /  `rtk grep`  /  `rtk find`  ；
- Codex 走规则文件档。我实际跑  `rtk init --codex`  ，它会写入项目  `RTK.md`  并在项目  `AGENTS.md`  里加一行  `@RTK.md`  引用：

```swift
$ rtk init --codex
RTK configured for Codex CLI.
  RTK.md:    RTK.md
  AGENTS.md: @RTK.md reference already present
  Codex project instructions path: AGENTS.md
```

### 2.4 Ponytail：生成端，管熵减（可选组件）

**GitHub：https://github.com/DietrichGebert/ponytail**（Dietrich Gebert 出品，MIT 许可）

**主要解决：熵减（生成端）**

Ponytail 是一层**前置决策规则**：写代码之前先强制走一遍「资深懒人的思维阶梯」，从源头杜绝冗余，而不是事后回来重构。

官方的决策阶梯有 7 层，停在第一个成立的台阶上：

```markdown
1. 这东西需要存在吗？   → 不需要，跳过（YAGNI）
2. 代码库里已经有了吗？ → 复用，不重写
3. 标准库能做吗？       → 用标准库
4. 平台原生特性能做吗？ → 用原生特性
5. 已安装的依赖能做吗？ → 用它
6. 一行能搞定吗？       → 就写一行
7. 最后才写：能工作的最小实现
```

官方特别强调：阶梯是在**理解问题之后**才运行的——先把改动涉及的代码读完、把真实流程追一遍，再去选台阶。原话是「对方案懒惰，对阅读绝不懒惰」。经典例子是日期选择器：普通 AI 会装上 flatpickr + 包装组件 + 样式表，再花两轮讨论时区；Ponytail 只写一行：

```xml
<inputtype = "date" >
```

**官方基准（B 级官方自述，agentic 无头 Claude Code 会话，Haiku 4.5）**：

| 指标 | vs 无 skill 基线 |
| --- | --- |
| 代码量 LOC | ** −54% ** （过度构建场景最高 −94%） |
| Token / 成本 / 耗时 | ** −22% / −20% / −27% ** |
| 安全性 | ** 100% ** （无 skill 基线同为 100%；朴素「YAGNI+一行流」提示词方案 95%） |

注意口径：−94% 是过度构建场景的峰值（日期选择器 404 行 → 23 行），平均是 −54%；早先 single-shot 基准里 80–94% 那个数，官方已澄清是「会话基线伪影」（issue #126）。

它的核心原则（README 原文）：**"The rule was never 'fewest tokens.'"**——规则从来不是「用最少 token」，而是「只写任务真正需要的」，**永远不裁剪验证、错误处理、安全、无障碍**（lazy, not negligent）。官方也诚实指出了边界：terse 模型可能为了爬阶梯烧掉大量 thinking token，反而更贵。

插件里装的东西（我直接读了安装目录，不是照抄 README）：**6 个 skills**（ `ponytail` 、 `ponytail-audit` 、 `ponytail-debt` 、 `ponytail-gain` 、 `ponytail-help` 、 `ponytail-review` ）+ 一一对应的 6 个 command，外加 lite/full/ultra/off 四档强度，兼容 **20 个 Agent 宿主**。

还有个容易被忽略的点：**插件自带 lifecycle hooks**。manifest 里写着  `"hooks": "./hooks/claude-codex-hooks.json"` ，实际挂了三组（下面这份是我为了省版面压成紧凑排版的，字段名和参数与原始文件一致）：

```powershell
{
  "hooks": {
    "SessionStart":     [{ "matcher": "startup|resume|clear|compact",
                           "hooks": [{ "type": "command", "command": "node \"${CLAUDE_PLUGIN_ROOT}/hooks/ponytail-activate.js\"", "timeout": 5 }] }],
    "SubagentStart":    [{ "hooks": [{ "type": "command", "command": "node \"${CLAUDE_PLUGIN_ROOT}/hooks/ponytail-subagent.js\"", "timeout": 5 }] }],
    "UserPromptSubmit": [{ "hooks": [{ "type": "command", "command": "node \"${CLAUDE_PLUGIN_ROOT}/hooks/ponytail-mode-tracker.js\"", "timeout": 5 }] }]
  }
}
```

这就是「always-on 激活」的实现方式——前提是插件已启用、对应 hook 已受信任且宿主确实加载了它；满足这些条件后，会话开始、子代理启动和提交 prompt 时会重新加载 Ponytail 模式，不用手动触发。

但这里有个很容易踩的坑：**装完插件不等于激活了**。按官方文档，装插件不会自动信任它捆绑的 hook。我在 Codex 的  `/hooks`  里实测，刚装完时这三组的状态是  `Installed 1 / Active 0 / Review 1` —— **没审之前它们会被直接跳过，always-on 等于没发生**。

审完之后，Codex 会把信任结果按 hook 内容的 hash 落到  `~/.codex/config.toml` ，三组各一条：

```ini
[hooks.state."ponytail@ponytail:hooks/claude-codex-hooks.json:session_start:0:0"]
trusted_hash = "sha256:5f81d38f…"

[hooks.state."ponytail@ponytail:hooks/claude-codex-hooks.json:user_prompt_submit:0:0"]
trusted_hash = "sha256:6a6f42bc…"

[hooks.state."ponytail@ponytail:hooks/claude-codex-hooks.json:subagent_start:0:0"]
trusted_hash = "sha256:1423b56c…"
```

 `trusted_hash`  只在审过之后才会写入，所以它能直接证明 hook **已经受信任**；要判断是否正在生效，还应同时确认插件 enabled，并观察当前会话是否实际加载。它记的是内容 hash：插件一升级、脚本内容一变，hash 可能对不上，宿主会重新要求审查。

作为**可选组件**，它的收益集中在「AI 过度工程」高发的场景（原型、内部工具、常见 CRUD）；算法密集或领域建模重的代码，强行最小化收益有限，甚至有害。

### 2.5 Caveman：输出端，管「说」（砍废话）——可选组件

**GitHub：https://github.com/JuliusBrussee/caveman**（JuliusBrussee 出品）

**主要解决：上下文工程（输出端）**

Caveman 是这几个项目里最欢乐的一个：让 AI 用「原始人电报体」说话——删掉寒暄、铺垫、免责声明、总结复述，只留结论、动作和代码（当前版本 v2.3.1，由官方安装命令的 URL tag 确认）。

**Caveman 2 是双产品架构**（官方 README）：

| 产品 | 管什么 | 节省 | 许可 |
| --- | --- | --- | --- |
| ** Skill ** | 管 ** 输出 ** ：电报体回答，代码/报错保持原样 | 10 任务平均 1214→294 token；任务级平均 ** 65% ** （区间 22%–87%） | ** MIT ** |
| ** Proxy/Engine ** | 管 ** 输入 ** ：本地代理在每次 provider 调用前压缩，字节级精确恢复 | 54-run 基准： ** 输入 token −33.2% ** ，18 项精确检查全过 | ** BSL-1.1 ** （非 OSI，有 Change Date） |

效果对比（官方示例）：普通回答 69 tokens → Caveman 19 tokens（"New object ref each render… Wrap in  `useMemo` "）。

但它是**可选组件**，而且官方的诚实声明比收益声明更值得看（**"Honest number warning"** 原文）：_"The skill only shrinks output tokens. Input and reasoning tokens are untouched, and the skill itself adds ~1–1.5k input tokens per turn. Whole-session savings run smaller… on already-terse workloads they can go net-negative. The real win is readability and speed; cost savings are the bonus."_——只压输出 token，输入和推理 token 不动，skill 本身每轮还要吃掉约 1–1.5k 输入 token；整会话的节省要小得多，本来就简洁的任务甚至可能是负收益；**真正的收益是可读性和速度，省钱只是赠品。**

结论：**Caveman 是约束工具，不是省钱工具。** 上游建议按需使用。我这个项目里装上的 skill 正文写的是  `ACTIVE EVERY RESPONSE` 、默认  `full` ，所以「按需触发」是推荐策略，不是装完就有的默认状态。

---
原文链接：https://mp.weixin.qq.com/s?__biz=MzA3OTQwNDAxMw%3D%3D&mid=2247483654&idx=1&sn=0d98edd56f1e60b38eea397c59781876&chksm=9fb54f84a8c2c6929650b728a1943228966f9ca8ccb23b715715f5f90383f16c27bc1b9ed27b
