---
source_url: "https://mp.weixin.qq.com/s?__biz=MzAxNjk4MzQxNw%3D%3D&mid=2247489331&idx=1&sn=fa7ba8d9cc3ac76050fe8d7c9d5d8821&chksm=9bed2325ac9aaa33064cfaa4fba861f5dc98d70f2793740064bd38324c9ca47dca2527de299c"
title: "对标Claude Agent Team：OpenCode也打造了自己的智能体团队（长文详解）"
account: "架构师之道"
published_at: "2026-02-11 00:01:00"
saved_at: "2026-10-22 09:14:43"
sync_id: "art_49b0fdc75f1a4317bd2501abdc276ce0"
parse_status: "ok"
---

# 对标Claude Agent Team：OpenCode也打造了自己的智能体团队（长文详解）

## 0. 引言

本文的内容源自于OpenCode官方，由博主翻译、整理而成，特此说明。

2026 年 2 月初，Anthropic 在其 Claude Code 中推出了 **智能体团队（Agent Teams）** 功能 —— 允许一个主导型 AI 智能体生成多个协作者，每个协作者运行在独立的会话中，通过消息传递进行协同。受此启发，OpenCode 也实现了自己的智能体团队方案。本文将从系统层面深入对比这两种架构：Claude Code 的实现方式、OpenCode 的不同做法，以及背后的原因。

这不是一篇入门教程，而是面向工程师与架构师的系统性解析，旨在揭示多智能体协调在**实现层面的真实运作机制**——包括状态机、锁顺序、消息语义，以及决定系统形态的关键设计决策。

## 1. 背景：什么是智能体团队？

智能体团队将单智能体的编程助手模式扩展为多智能体协同模式。不同于单一 LLM 按顺序处理所有任务，**主导型智能体（Lead Agent）会生成多个**协作者智能体（Teammate Agents），每个协作者拥有独立的提示循环与上下文窗口。主导智能体负责：分配工作、接收发现结果、整合最终产出。

这一能力之所以重要，是因为现代 AI 辅助工作流越来越需要**并行化与专业化**——例如一个智能体探索代码库，另一个编写测试；或三个来自不同厂商的模型从不同角度分析同一系统。智能体团队提供了让这种协作成为可能的**协调原语**。

Claude Code 与 OpenCode 在高层概念上一致，差异体现在**实现细节**：如何生成协作者、如何传递消息、如何处理故障、以及如何隔离通信图。

## 2. Claude Code 的架构

Claude Code 的智能体团队功能以研究预览形式发布，需启用  `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS`  标志。

### 2.1 高层设计

![](附件资源/对标Claude%20Agent%20Team：OpenCode也打造了自己的智能体团队（长文详解）/img_1.jpg)

Claude Code 的智能体团队系统包含五大核心组件：

#### 2.1.1 后端注册器（Backend Registry）

一层检测逻辑，根据终端环境选择最优的生成策略：

| 后端类型 | 选择条件 | 执行模型 |
| --- | --- | --- |
| 进程内（In-process） | 默认 | 同进程运行器 |
| Tmux | 在 tmux 内部或外部可用 tmux |  `tmux split-pane`  + 独立  `claude`  进程 |
| iTerm2 | 在 iTerm2 内部且  `it2`  CLI 可用 | iTerm2 原生分屏 |

#### 2.1.2 进程内执行循环（In-Process Execution Loop）

用于进程内协作者的核心执行循环。它将来自  `"team-lead"`  的初始消息格式化，在循环中调用 LLM，并在轮次间阻塞于**消息等待原语**——处理  `new_message` 、 `shutdown_request`  或  `aborted`  事件。

#### 2.1.3 面板式执行（Pane-Based Execution）

针对 tmux 与 iTerm2 后端，Claude Code 会生成一个独立的  `claude`  进程，并传入标志（ `--agent-id` 、 `--agent-name` 、 `--team-name` 、 `--parent-session-id` ），通过团队消息系统传递初始提示。

#### 2.1.4 基于文件的消息传递（File-Based Messaging）

关键机制：智能体通过  `~/.claude/<teamName>/inboxes/<agentName>.json`  路径下的 JSON 收件箱文件通信。消息的写入与读取均通过收件箱系统完成——进程内智能体使用消息等待循环，主导端则使用轮询组件。文件锁防止并发写入导致损坏。

#### 2.1.5 收件箱轮询（Inbox Polling）

主导端上的轮询组件按固定间隔读取收件箱文件，处理权限请求、关闭请求、沙箱权限更新以及常规协作者消息。后者会被格式化为 XML（ `<teammate-message teammate_id="..." color="...">` ）并提交给模型。

### 2.2 关键架构特性

#### 2.2.1 基于轮询的消息投递

主导端通过定期读取收件箱文件发现新消息，延迟与轮询间隔成正比。进程内协作者虽阻塞于消息等待循环，但该循环本质上也是轮询直至消息到达。

#### 2.2.2 异构生成后端

同一团队可混合进程内与面板式协作者。无论后端如何，消息层保持一致——始终是基于文件锁的 JSON 收件箱。

#### 2.2.3 专用团队工具

Claude Code 暴露了多个团队专属工具： `TeamCreate` （创建团队）、 `TeamDelete` （删除团队）、 `SendMessage` （发送消息）、 `TaskCreate` （创建任务）、 `TaskList` （列出任务）、 `TaskGet` （获取任务）、 `TaskUpdate` （更新任务）以及  `Skill` （技能）——此外还有通用的  `Task`  工具用于子智能体生成。协作者生成通过  `Task`  工具并指定  `team_name`  与  `name`  参数完成，但团队创建与消息传递有独立工具。

#### 2.2.4 以主导为中心的通信

消息主要在主导与协作者之间流动。主导端的轮询组件是主要入口。协作者之间的点对点通信通过  `SendMessage`  工具实现，同样经由文件收件箱路由，但核心协调模式仍是**主导中心式**。

## 3. OpenCode 的架构

OpenCode 的实现分为两个阶段：在 Claude Code 发布后 24 小时内完成首个可运行移植（2026 年 2 月 6 日），随后在 2 月 6 日至 10 日间经过四天的加固、测试与架构优化——总计约 50 次提交。其架构在多个基础维度上与 Claude Code 不同。

### 3.1 高层设计

![](附件资源/对标Claude%20Agent%20Team：OpenCode也打造了自己的智能体团队（长文详解）/img_2.jpg)

系统由五个源码模块组成：

| 模块 | 行数 | 职责 |
| --- | --- | --- |
|  `team/events.ts`  | ~154 | Zod 模式定义、BusEvent（11 种类型事件） |
|  `team/index.ts`  | ~942 | Team 与 TeamTasks 命名空间——生命周期、状态机、恢复机制 |
|  `team/messaging.ts`  | ~142 | 合成消息注入 + 自动唤醒 |
|  `tool/team.ts`  | ~656 | 面向 LLM 的 9 个工具 |
|  `tool/task.ts`  | ~218 | 子智能体隔离（禁用团队工具及其他特定工具） |

### 3.2 关键架构特性

#### 3.2.1 事件驱动的消息投递

OpenCode 不采用轮询，而是直接将消息作为**合成用户消息**注入接收方的会话，并通过重启其提示循环来自动唤醒空闲会话。无轮询间隔，无收件箱文件。消息将在下一轮 LLM 循环中立即被处理。

#### 3.2.2 单一生成后端

所有协作者均在进程内运行，不支持 tmux 或 iTerm2 后端。这简化了实现，但限制了可视化展示选项。

#### 3.2.3 显式工具分离

提供 9 个专用工具（ `team_create` 、 `team_spawn` 、 `team_message` 、 `team_broadcast` 、 `team_tasks` 、 `team_claim` 、 `team_approve_plan` 、 `team_shutdown` 、 `team_cleanup` ），取代 Claude Code 中重载的  `Task`  工具。执行模型直接体现在工具名称中，语义清晰。

#### 3.2.4 多模型团队

每个协作者可使用不同的 LLM 提供商与模型。单个团队可同时包含  `anthropic/claude-sonnet-4-20250514` 、 `google/gemini-2.5-pro`  与  `openai/gpt-5.3-codex`  协同工作。

#### 3.2.5 带依赖的共享任务列表

内置任务管理系统，支持状态（ `pending` 、 `in_progress` 、 `completed` 、 `cancelled` 、 `blocked` ）、优先级、原子化认领及自动依赖解析。

#### 3.2.6 特性开关控制

整个系统受  `OPENCODE_EXPERIMENTAL_AGENT_TEAMS`  控制，这是一个在访问时动态求值的开关。

## 4. 深度解析：五个产生分歧的设计决策

### 4.1 消息投递：存储与通知解耦

消息投递包含两个独立维度：**消息存储位置**（持久化层）与**接收方如何发现新消息**（通知机制）。将二者混为一谈会导致架构对比失准。实际设计空间如下：

|  | 轮询（通知） | 事件驱动 / 自动唤醒（通知） |
| --- | --- | --- |
| ** 收件箱文件 ** （存储） | Claude Code | 可能的混合方案 |
| ** 会话注入 ** （存储） | （无人采用） | OpenCode |

Claude Code 选择 **收件箱文件 + 轮询**；OpenCode 选择 **会话注入 + 自动唤醒**。但轮询并非文件收件箱的固有属性——它是 Claude Code UI 架构的结果。

![](附件资源/对标Claude%20Agent%20Team：OpenCode也打造了自己的智能体团队（长文详解）/img_3.jpg)

**Claude Code** 消息以 JSON 数组形式存储在  `~/.claude/<teamName>/inboxes/<agentName>.json` ，并通过文件锁保护。主导端按固定间隔轮询收件箱文件以发现新消息——这与 React TUI 架构一致：轮询钩子让 UI 在不阻塞渲染周期的情况下发现新消息。进程内协作者使用消息等待循环，本质也是轮询直至消息出现。对于面板式协作者（tmux、iTerm2），收件箱文件充当跨进程 IPC 通道——这是独立操作系统进程间唯一的共享面。

```
主导端                        协作者
  |                              |
  |--- 写入消息 -------------->  | （追加到收件箱 JSON）
  |                              |
  |    [轮询间隔]                |
  |                              |
  |<-- 读取收件箱 -------------  | （从收件箱 JSON 读取）
  |    （轮询组件）              |
```

**OpenCode** 将消息直接注入接收方会话的对话历史，作为合成用户消息。 `injectMessage()`  函数创建  `role: "user"`  且  `synthetic: true`  的新消息，格式为  `[Team message from <sender>]: <text>` 。这些消息通过现有的  `Session.updateMessage()`  /  `Session.updatePart()`  API 持久化到磁盘——写入用户数据目录下 Storage 命名空间的键路径  `message/{sessionID}/{messageID}` （JSON 文件），因此可在重启后保留。注入后， `autoWake()`  检查  `SessionStatus` ：若接收方处于空闲，则启动新的  `SessionPrompt.loop()` 。

```
// messaging.ts —— 简化自实际实现
asyncfunctioninjectMessage(sessionID: string, fromName: string, text: string) {
// 实际实现还会从最近的用户消息解析智能体/模型元数据
const msgId = Identifier.ascending("message");
awaitSession.updateMessage({
id: msgId,
    sessionID,
role: "user",
/* 智能体、模型、时间等元数据 */
  });
awaitSession.updatePart({
id: Identifier.ascending("part"),
messageID: msgId,
    sessionID,
type: "text",
text: `[Team message from ${fromName}]: ${text}`,
synthetic: true,
  });
}

functionautoWake(sessionID: string, from: string) {
const status = SessionStatus.get(sessionID);
if (status.type !== "idle") return;
SessionPrompt.loop({ sessionID }).catch(/* 记录日志 */);
}
```

#### 4.1.1 OpenCode 为何不使用收件箱文件

并非因为收件箱文件需要轮询——它们并不需要。OpenCode 的所有协作者都在进程内运行，不存在跨进程 IPC 问题。现有会话持久化层已能将消息写为 JSON 文件，天然具备持久性。另建收件箱层只会重复功能。

Claude Code **必须**使用收件箱文件，因为它支持三种生成后端（进程内、tmux 面板、iTerm2 面板）。当协作者是 tmux 分割中的独立 OS 进程时，无法向其内存会话注入消息——需要一个磁盘上的共享文件。它轮询这些文件是因为主导端运行在 React TUI 渲染循环内，而非文件消息本身需要轮询。

理论上最优的架构是将收件箱文件与事件驱动通知结合：既保留可审查的持久化消息历史，又实现零延迟投递。OpenCode 选择会话注入，是在单进程执行与既有基础设施下阻力最小的路径，并不代表它在所有场景下都更优。

#### 4.1.2 真正的权衡

OpenCode 的消息与会话对话历史交织，使得团队通信难以单独审查。Claude Code 的收件箱文件提供了干净、独立的智能体间通信审计日志。对于长期运行的团队——如过夜任务、跨多次重启仍存活的团队——这种分离具有价值。

### 4.2 生成语义：阻塞—异步的反复迭代

OpenCode 中的生成模型在 Git 历史中经历了明确的三阶段演进：

- 初始移植 （  `c9702638d`  ）：非阻塞生成，符合我们对 Claude Code 的理解。
- 阻塞尝试 （  `9c57a4485`  ）：让  `team_spawn`  等待协作者完整提示循环结束。这是错误的——它会阻止主导智能体并行协调多个协作者。
- 最终设计 （  `177272136`  ）：回归“触发即忘”（fire-and-forget），并引入自动唤醒作为缺失环节。

关键启发来自观察一次 Claude Code 团队会话：

> “生成并非对每个协作者都阻塞。主导智能体会并行生成两个研究员，展示状态表，并持续与用户交互。主导的智能体循环保持存活。”

真正的问题不是生成为非阻塞，而是生成后主导智能体的提示循环因 LLM 无事可做而退出。自动唤醒解决了这一点：当协作者向空闲的主导端发送消息时，会重启主导端的提示循环。

```
// 触发前：在启动独立循环前转为 busy/starting 状态
awaittransitionMemberStatus(teamName, name, "busy");
awaittransitionExecutionStatus(teamName, name, "starting");

// 最终生成模式：触发即忘 + Promise.resolve().then()
// 防止同步异常抛出
Promise.resolve()
  .then(async () => {
awaittransitionExecutionStatus(teamName, name, "running");
returnSessionPrompt.loop({ sessionID: session.id });
  })
  .then(async (result) => {
// 处理完成：转换状态，通知主导端
awaitnotifyLead(teamName, name, session.id, result.reason);
  })
  .catch(async (err) => {
// 处理错误：标记为失败，通知主导端
awaittransitionMemberStatus(teamName, name, "error");
  });

// 立即返回，不等待循环结束
return { sessionID: session.id, label };
```

### 4.3 通信拓扑：主导中心 vs. 全互联

**Claude Code** 所有通信经由主导端的轮询组件路由。协作者可向彼此的收件箱投递消息，但主要模式是协作者→主导端。

**OpenCode** 支持完全的点对点通信。任何协作者均可通过名称使用  `team_message`  向其他协作者发消息。团队系统提示明确鼓励这种做法：

> “你可以按名称向任意协作者发消息——不仅限于主导端。”

这是在观察到主导中心路由会造成瓶颈后的刻意改动。当协作者可直接共享发现（例如，投注分析师将数据广播给伤病侦察员），主导端便可专注于编排，而非消息转发。

### 4.4 持久化与锁机制

**Claude Code** 对收件箱文件使用基于文件的写锁进行保护。团队配置保存在  `~/.claude/<teamName>/config.json` 。

**OpenCode** 使用进程内的**读写锁**，且写锁优先：

```
// lock.ts —— 写优先避免饥饿
exportnamespaceLock {
exportasyncfunctionread(key: string): Promise<Disposable>;
exportasyncfunctionwrite(key: string): Promise<Disposable>;
}
```

团队状态通过  `Storage`  命名空间持久化为 JSON 文件。核心原语是  `Storage.update()`  —— 在文件路径对应的排他写锁下执行**读-改-写**操作（以下为简化版，实际实现含错误处理与惰性目录解析）：

```
exportasyncfunction update<T>(key: string[], fn: (draft: T) =>void) {
const target = path.join(dir, ...key) + ".json";
  using _ = awaitLock.write(target); // 获取排他锁
const content = awaitBun.file(target).json();
fn(content);                       // 原地修改
awaitBun.write(target, JSON.stringify(content, null, 2));
return content as T;
}
```

 `using`  关键字配合  `Symbol.dispose`  提供 RAII 式清理——即使修改过程中抛出异常，锁也会释放。任务认领利用该机制保证原子性：在  `Storage.update()`  内，认领回调会先检查状态、负责人与依赖，再设置  `status: "in_progress"` ，确保只有一个智能体能成功认领。

### 4.5 工具覆盖范围

| 能力 | Claude Code | OpenCode |
| --- | --- | --- |
| 创建团队 |  `TeamCreate`  （专用工具） |  `team_create`  （显式，支持可选委托模式） |
| 删除团队 |  `TeamDelete`  （专用工具） |  `team_cleanup`  （显式，需全部关闭） |
| 生成协作者 |  `Task`  工具加团队参数 |  `team_spawn`  （专用工具） |
| 发送消息 |  `SendMessage`  （专用工具） |  `team_message`  （点对点） |
| 广播 | 无 |  `team_broadcast`  （所有活跃成员） |
| 任务管理 |  `TaskCreate`  /  `TaskList`  /  `TaskGet`  /  `TaskUpdate`  |  `team_tasks`  +  `team_claim`  （内置，原子化） |
| 计划审批 | 存在（plan_approval 消息类型及批准/拒绝流程） |  `team_approve_plan`  （分阶段写工具解锁） |
| 关闭 | Shutdown 消息类型 |  `team_shutdown`  （含循环取消） |
| 委托模式 | 存在（CLI 标志与文档提及） |  `team_create(delegate: true)`  限制主导端为只读 |

两套系统均暴露丰富的专用工具。Claude Code 至少有 8 个团队相关工具（ `TeamCreate` 、 `TeamDelete` 、 `SendMessage` 、 `TaskCreate` 、 `TaskList` 、 `TaskGet` 、 `TaskUpdate` 、 `Skill` ）外加通用  `Task`  工具。OpenCode 有 9 个（ `team_create` 、 `team_spawn` 、 `team_message` 、 `team_broadcast` 、 `team_tasks` 、 `team_claim` 、 `team_approve_plan` 、 `team_shutdown` 、 `team_cleanup` ）。两者规模相当，仅组织方式不同。

## 5. 状态机与生命周期

OpenCode 通过两个独立的状态机追踪协作者生命周期。

### 5.1 成员状态（粗粒度生命周期）

![](附件资源/对标Claude%20Agent%20Team：OpenCode也打造了自己的智能体团队（长文详解）/img_4.jpg)

五种状态，转换受约束：

```
constMEMBER_TRANSITIONS: Record<MemberStatus, MemberStatus[]> = {
ready:              ["busy", "shutdown_requested", "shutdown", "error"],
busy:               ["ready", "shutdown_requested", "error"],
shutdown_requested: ["shutdown", "ready", "error"],
shutdown:           [],          // 终态
error:              ["ready", "shutdown_requested", "shutdown"],
};
```

### 5.2 执行状态（细粒度提示循环跟踪）

十个状态，以子步骤粒度跟踪提示循环。正常路径与取消路径（简化版—— `failed`  与  `timed_out`  可从多数活跃状态到达）：

```
idle -> starting -> running -> completing -> completed -> idle
                       |
                       v
                cancel_requested -> cancelling -> cancelled -> idle

（failed 与 timed_out 可从 starting、running、
 cancel_requested、cancelling 或 completing 进入 -> idle）
```

双层设计让 UI 能完整查看每个协作者的实时行为，同时保持生命周期状态机简洁，便于推理恢复与清理逻辑。

### 5.3 转换守卫

转换需通过允许转换映射校验。存在两种覆盖机制：

-  `guard: true`  若成员已处于  `"shutdown"`  状态则跳过转换，防止自动清理期间的竞态条件。
-  `force: true`  完全绕过转换校验。用于崩溃后状态机可能不一致时的恢复与取消，作为安全网。

## 6. 子智能体隔离

![](附件资源/对标Claude%20Agent%20Team：OpenCode也打造了自己的智能体团队（长文详解）/img_5.jpg)

当团队成员通过 `task` 工具创建子智能体（用于代码库探索、研究等任务）时，该子智能体**不得访问团队通信通道**。设计 rationale：子智能体是临时性工作单元，产生高频率、低价值的输出（如grep结果、文件读取、中间推理）。若允许其直接向团队广播，将导致协调通道被淹没。

OpenCode通过两个层面强制实施隔离（隔离机制同样适用于 `todowrite` 、 `todoread` 及条件性 `task` 工具，但团队工具的权限控制是架构级关键设计）：

**权限拒绝规则**（应用于子智能体会话创建）：

```
constTEAM_TOOLS = [
"team_create", "team_spawn", "team_message", "team_broadcast",
"team_tasks", "team_claim", "team_approve_plan",
"team_shutdown", "team_cleanup"
] asconst;

// 应用于子智能体会话创建时的权限拒绝规则
...TEAM_TOOLS.map(t => ({
permission: t,
pattern: "*",
action: "deny"
}))
```

**工具可见性隐藏**——团队工具从子智能体的工具列表中完全移除：

```
tools: {
  ...Object.fromEntries(TEAM_TOOLS.map(t => [t, false])),
}
```

团队成员系统提示明确规范中继模式：

> _"子智能体中继：若通过task工具创建子智能体，它们无法与团队通信。您需负责通过team_message或team_broadcast中继相关发现。"_

该设计源于安全审计（提交 `2ad270dc4` ）发现子智能体可能因继承父级权限意外访问 `team_message` 。Claude Code同样实施相同隔离机制——常规子智能体无法访问团队工具——证实该边界是必要设计而非过度谨慎。

## 7. 恢复语义

![](附件资源/对标Claude%20Agent%20Team：OpenCode也打造了自己的智能体团队（长文详解）/img_6.jpg)

当服务器重启时，系统需处理残留状态以避免智能体失控。OpenCode在实例引导时执行严格顺序的恢复流程：

**步骤1：注册权限恢复**。 `onCleanedRestorePermissions()` 同步订阅 `TeamEvent.Cleaned` 事件。此步骤必须在恢复前完成，因为恢复可能触发清理操作，而清理需恢复主代理会话的委派模式权限。

**步骤2：恢复过期成员**。 `Team.recover()` 扫描所有团队中状态为 `"busy"` 的成员，强制将其状态转换为 `cancelled → idle → ready` 。随后向主代理会话注入合成通知：

```
[System]: 服务器已重启。团队"X"中的以下成员中断，需恢复：worker-1, worker-2。
请使用team_message或team_broadcast通知它们继续工作。
```

**步骤3：订阅自动清理**。 `autoCleanup()` 在恢复完成后（通过 `.finally()` ）订阅 `MemberStatusChanged` 事件。此顺序防止恢复自身触发的状态转换导致误清理。

**关键特性：无自动重启**。中断的成员被标记为就绪状态，但其提示循环不会自动重启。必须由用户手动重新激活。这是出于安全考虑的决策——避免崩溃后智能体失控，而非功能限制。

### 7.1 取消机制

活动成员取消采用带退避重试的循环：

```
for (const _ of [0, 1, 2]) {
SessionPrompt.cancel(member.sessionID);
awaittransitionExecutionStatus(teamName, memberName, "cancelling");
awaitBun.sleep(120);
// 检查是否达到终端状态
if (TERMINAL_EXECUTION_STATES.has(current?.execution_status)) break;
}
// 回退：直接检查运行时状态，若卡住则强制转换
```

三次尝试（间隔120毫秒）。若提示循环未停止，系统直接检查运行时状态并强制转换。 `SessionPrompt.cancel()` 会通过 `"cancelled"` 解析所有等待的Promise，并触发 `AbortController` ，向活跃的LLM流式调用传播取消信号。

## 8. 局限性与权衡

### 8.1 单进程限制

OpenCode的所有锁均为内存锁。系统无法在多个服务器实例上安全共享同一存储目录。这对CLI工具可接受，但从根本上限制了水平扩展能力。Claude Code采用基于文件的锁，同样仅限单机运行，但至少支持跨进程。

### 8.2 无消息确认机制

两个系统均不提供消息送达确认。在OpenCode中， `injectMessage()` 通过 `Session.updateMessage()` 写入磁盘后立即返回——消息持久化且能存活于重启，但发送方无法确认接收方是否已处理。若磁盘写入失败，消息将丢失且无重试机制。无死信队列，无至少一次处理保证。

### 8.3 无背压机制

OpenCode对单条消息设10KB大小限制，但无有界队列或流量控制。快速发送方可能用合成消息淹没慢速接收方的会话。Claude Code同样存在此限制——收件箱文件无界增长。

### 8.4 无跨团队通信

团队间完全隔离。无原生跨团队消息原语。若需不同团队智能体通信，需在更高层构建。

### 8.5 线性团队发现

 `findBySession()` 遍历所有团队以定位会话所属团队。每次查找时间复杂度为O(团队数×成员数)。在预期规模（1-3个团队）下可行，但无法扩展至数百个团队。

### 8.6 恢复需手动操作

服务器重启后，中断的成员处于就绪但空闲状态。必须由人工重新激活。这是出于安全考虑的决策——但这也意味着无人值守的长期运行团队无法在崩溃后自我恢复。

## 9. 验证：多模型实时协作

为在真实场景下压力测试系统，我们运行了渐进式复杂团队场景：

**NFL研究（2月7日）**。两个Gemini 2.5 Pro智能体研究海鹰队和爱国者队历史。该测试暴露了主代理提示循环退出问题，推动了自动唤醒机制的诞生。同时发现Gemini特有的行为问题：模型循环生成约50条几乎相同的"任务完成"消息且无法停止——这是基础设施层面的观察结果，单元测试无法捕获。

**超级碗预测（2月8日）**。四个Claude Opus智能体（统计分析师、投注分析师、对战分析师、伤病侦察员）并行工作，实现点对点协调。投注分析师主动向所有队友广播发现；伤病侦察员在分析中交叉引用投注数据。这验证了全网格通信拓扑，并证明原子化认领的共享任务列表在并发访问下有效。

**架构戏剧性测试（2月10日）**。来自三个不同提供商的三个模型——GPT-5.3 Codex、Gemini 2.5 Pro和Claude Sonnet 4——作为队友通过同一消息总线实时协调：

![](附件资源/对标Claude%20Agent%20Team：OpenCode也打造了自己的智能体团队（长文详解）/img_7.jpg)

所有消息经主代理路由。子智能体隔离机制有效。自动唤醒在每次消息投递时正确触发。该系统从24小时移植项目发展为支持多模型、多提供商实时协作的稳定架构。

## 10. 结论

将Claude Code的智能体团队移植到OpenCode仅用24小时，这反而是简单部分。真正有趣的是差异点：用合成注入和自动唤醒替代轮询，构建全网格点对点消息系统，实现带受保护转换的两级状态机，添加支持依赖解析的共享任务列表，以及设计以安全优先的恢复语义。

核心洞见：**单机上的多智能体协调是系统工程问题，而非分布式系统问题**。当智能体共享文件系统时，无需Raft；当合成消息注入有效时，无需gRPC。Claude Code和OpenCode都实现了同一基础架构的不同变体——进程隔离加消息总线——并在真实多智能体负载下验证了其可行性。

差异在于架构如何向智能体和用户呈现：事件驱动唤醒 vs 轮询；全网格通信 vs 领导中心路由；两级状态机 vs 隐式生命周期；会话注入 vs 收件箱文件。这些都是工程选择，而非能力差异——这些选择决定了系统在出错时是否可调试、可恢复且可预测。

### 10.1 设计对比

| 维度 | Claude Code | OpenCode |
| --- | --- | --- |
| 消息存储 | 基于文件的收件箱（独立审计日志） | 会话注入（复用会话持久化） |
| 消息通知 | 轮询（React钩子/消息等待循环） | 事件驱动自动唤醒（SessionPrompt.loop重启） |
| 创建模型 | 立即发送（3种后端） | 立即发送（仅进程内） |
| 通信方式 | 领导中心化（基于轮询） | 全网格（点对点） |
| 工具模型 | 8+专用工具 | 9专用工具 |
| 状态跟踪 | 隐式（内存应用状态） | 两级状态机（成员+执行） |
| 任务管理 | 内置（TaskCreate/TaskList/TaskUpdate） | 内置支持依赖+原子认领 |
| 子智能体隔离 | 显式（Task工具双路径代码） | 显式（拒绝列表+可见性隐藏） |
| 恢复机制 | 未知（闭源） | 有序启动+手动重启 |
| 多模型支持 | 单提供商 | 每团队多提供商 |
| 锁机制 | 文件锁 | 内存读写锁（写优先） |
| 计划审批 | 存在（收件箱消息审批/拒绝流程） | 原生支持标签化权限模式 |
| 委派模式 | 存在（CLI标志和文档提及） | 主代理仅限协调工具 |

---
原文链接：https://mp.weixin.qq.com/s?__biz=MzAxNjk4MzQxNw%3D%3D&mid=2247489331&idx=1&sn=fa7ba8d9cc3ac76050fe8d7c9d5d8821&chksm=9bed2325ac9aaa33064cfaa4fba861f5dc98d70f2793740064bd38324c9ca47dca2527de299c
