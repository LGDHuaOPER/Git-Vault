---
source_url: "https://mp.weixin.qq.com/s?__biz=MzIzOTU0NTQ0MA==&mid=2247560862&idx=1&sn=997c0e80d7bdc1f6ddc39fa4c79a4380&chksm=e868c9c18443ace49a48a4df89ece01f23aa5a1ec16192420d545b3bbaf6d218023da5e4f72b&mpshare=1&scene=1&srcid=0612kbEoRLhTjQX8rKdI0usQ&sharer_shareinfo=e32d937ae4764b0d48d1b6a9166e26d3&sharer_shareinfo_first=e32d937ae4764b0d48d1b6a9166e26d3"
title: "当 AI Coding Agent 成为基础设施：我们为什么要开源 LoongSuite Pilot"
account: "阿里云开发者"
published_at: "2026-06-12T10:00:00.000Z"
saved_at: "2026-07-15T17:07:54.978Z"
sync_id: "art_4f8128114ddf46f5916b5bc368733d18"
parse_status: "ok"
---

# 当 AI Coding Agent 成为基础设施：我们为什么要开源 LoongSuite Pilot

![](附件资源/当%20AI%20Coding%20Agent%20成为基础设施：我们为什么要开源%20LoongSuite%20Pilot/img_1.jpg)

阿里妹导读

文章内容基于作者个人技术实践与独立思考，旨在分享经验，仅代表个人观点。

1. 当 AI Coding Agent 成为基础设施
可观测性准备好了吗？

2025 年以来，AI Coding Agent 进入了爆发期。Cursor、Claude Code、Codex、Qoder ——这些工具已经不再是"尝鲜玩具"，而是越来越多开发者和团队每天依赖的生产力工具。它们能理解代码上下文、自主调用工具、跨文件重构，甚至独立完成完整的功能开发。

但当我们尝试回答一些基本问题时，会发现自己几乎无从下手：

- 团队里每个人的 AI Coding Agent 每天消耗了多少 Token？
- 哪些类型的任务适合交给 AI Agent，哪些不适合？
- 当 Agent 输出不符合预期时，它中间经历了什么？
- 一个 Agent 在某次会话中修改了 30 个文件，这些修改的完整链路是什么？

![](附件资源/当%20AI%20Coding%20Agent%20成为基础设施：我们为什么要开源%20LoongSuite%20Pilot/img_2.svg)

这些问题指向一个共同的事实：**我们对 AI Coding Agent 的运行行为几乎没有可观测性。** 这不是一个小问题——当企业每月在 AI Coding 工具上投入数万甚至数十万预算，却无法量化回答"这笔钱值不值"的时候，它就变成了一个经营问题。

我们仔细分析了这个问题，发现困难来自三个层面：

**Agent 行为天然难以观测。** 与传统的 API 调用不同，一次 AI Agent 的任务执行可能包含 10 轮以上的 ReAct 推理循环，每轮涉及模型调用、工具选择、结果反思。传统的 Metrics + Log + Trace 三板斧只能看到一堆独立的 HTTP 请求，无法还原这种分层、有序的决策流程。

**多 Agent 数据天然割裂。** 每个 Agent 的数据格式不同、存储位置不同、记录粒度不同。Cursor 的数据在一个地方，Claude Code 的在另一个地方，想做横向对比几乎不可能。

**端侧是可观测的盲区。** 现有的可观测方案——无论是 LoongCollector 这样的主机探针，还是 Python/Go/Java 语言 Agent 这样的进程探针——都面向服务端。但 AI Coding Agent 运行在开发者本地机器上，数据散落在 IDE 历史文件、本地 SQLite 数据库、Session 日志等各个角落，传统方案完全触及不到。

2. 应对难题，LoongSuite Pilot 的解决思路

面对上述挑战，我们做了一些关键的设计选择。这些选择背后的取舍，或许对同样在探索这个领域的开发者有参考价值。

![](附件资源/当%20AI%20Coding%20Agent%20成为基础设施：我们为什么要开源%20LoongSuite%20Pilot/img_3.png)

**选择一：做 ALL IN ONE 架构而非单点适配**

最容易想到的做法是为每个 Agent 写一个专属的数据提取脚本。但 Coding Agent 生态迭代极快，几个月就会有新的 Agent 出现，单点方案无法持续。我们的选择是做一个**统一的采集平台**——一次部署，自动覆盖设备上所有已安装的 AI Coding Agent。

这要求架构必须足够可扩展。我们将每个 Agent 的检测规则、部署模式和采集配置全部声明化，放在  `agents.d/*.json`  文件中：

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
-
-
-
-
-

```
{  "id": "claude-code",  "displayName": "Claude Code",  "deployMode": "hook",  "detection": {    "paths": ["~/.claude"],    "commands": ["claude"]  },  "hook": {    "settingsPath": "~/.claude/settings.json",    "events": ["UserPromptSubmit", "PreToolUse", "PostToolUse", "Stop", ...],    "hookCommand": "$PILOT_DATA/hooks/claude-code-loongsuite-pilot-hook.sh"  },  "input": {    "type": "hook-jsonl",    "logDir": "$PILOT_DATA/logs/claude-code"  }}
```

```
新增一个 Agent 的适配，核心工作量在于理解其数据格式并编写转换逻辑，不需要改动框架代码。
```

**选择二：适配 Agent 而非改造 Agent**

服务端可观测有成熟范式——通过 Java Agent、Python Agent 等进程内注入实现自动埋点。但端侧 AI Coding Agent 是第三方闭源产品，我们无法修改它们的运行时，也不可能要求每个 Agent 厂商暴露标准化的遥测接口。而且每个 Agent 留下数据的方式截然不同：Claude Code 支持 Hook 回调，Qoder 的历史在 SQLite 数据库里，有些 Agent 只留下 Session 日志文件。

因此核心原则是：**让采集能力适配 AI Agent 的原生运行模式，而非要求 Agent 改造自己来适配采集工具。** 我们将这些差异抽象为 5 种采集基类，每种封装一套增量提取策略，新 Agent 只需选择合适的基类并实现 2-3 个方法：

![](附件资源/当%20AI%20Coding%20Agent%20成为基础设施：我们为什么要开源%20LoongSuite%20Pilot/img_4.svg)

| 采集基类 | 策略 | 适用场景 |
| --- | --- | --- |
| BaseHookInput | Hook JSONL 日志增量读取 | 支持 Hook 机制的 Agent（Cursor、Claude Code、Codex） |
| BaseIdeInput | IDE 历史文件快照轮询 | IDE 插件类 Agent |
| BaseSqliteInput | SQLite rowid 游标增量查询 | 使用本地数据库的 Agent |
| BaseSessionInput | Session 文件轮询 | 会话日志型 Agent |
| BaseCliForwarder | CLI 遥测日志转发 | CLI 类 Agent |

底层通过 Checkpoint 机制保障数据可靠性——StateStore 记录读取偏移，SnapshotStore 存储去重快照。本地设备上网络波动、设备重启、终端关闭都是常态，断点续采保证了进程异常中断后不会出现数据丢失或重复。

目前已适配的 Agent 及其覆盖能力：

| Agent | 覆盖事件 |
| --- | --- |
| Claude Code | 用户提问、工具调用（前/后）、任务完成、上下文压缩、子 Agent 生命周期、通知等完整事件链 |
| Codex | 会话启动、用户提问、工具调用（前/后）、任务完成 |
| Cursor | 12 种事件覆盖，包括会话生命周期、工具调用、提问、子 Agent 等 |
| Qoder / Qoder Work | Hook 日志 + IDE 历史记录 + 数据库 + 会话文件多路并行采集 |

**选择三：用语义规范统一异构数据**

采集到数据只是第一步。如果 Cursor 的数据是一种格式，Claude Code 是另一种，下游每加一个分析能力都要对接多种数据源，这条路不可持续。

我们的做法是将所有原始数据归一化为统一的 **AgentActivityEntry** 事件格式，遵循 **LoongSuite GenAI 可观测语义规范**。该规范基于 OpenTelemetry GenAI Semantic Conventions 扩展，在社区标准尚未覆盖的 AI Coding Agent 场景上做了补充。

![](附件资源/当%20AI%20Coding%20Agent%20成为基础设施：我们为什么要开源%20LoongSuite%20Pilot/img_5.png)

统一语义的价值在于：

- 口径对齐 ：所有 Agent 的数据使用相同的字段名和语义定义（ gen_ai.usage.input_tokens 、 gen_ai.session.id 、 gen_ai.tool.call.id 等），下游分析无需感知数据来源差异。
- 层级化链路 ：保留 session → turn → step → response/tool_call 的完整层级，能够还原 Agent 从接收输入到最终输出的完整执行链路，包括每一轮 ReAct 循环中的思考、工具调用和推理过程。
- 基础设施复用 ：接入一个新 Agent 时，看板、告警、分析查询等下游能力自动生效，无需重新开发。

**选择四：灵活粒度，平衡观测与安全**

不是所有团队都需要采集全量数据。有些场景只需要成本分析（Token 用量、模型调用次数），有些场景需要完整审计（消息内容、工具参数、执行结果）。

我们在两个层面提供安全控制：

**采集粒度控制。** 支持按 Agent 类型配置是否采集消息内容、工具参数、模型输入输出等大字段，关闭后仅上报模型名、Token 消耗、耗时、工具名称等结构化元数据。

**敏感信息自动脱敏。** AI Coding Agent 的对话内容中经常夹带 API Key、云厂商 AK/SK、数据库连接串、私钥等敏感凭据——开发者在提问时粘贴了一段配置文件，或者 Agent 在读取  `.env`  文件后将内容写入工具调用参数，这些都会导致敏感信息进入采集链路。Pilot 内置了基于规则的自动脱敏引擎，在数据分发给任何输出通道之前，统一扫描并替换敏感内容：

| 脱敏类型 | 覆盖范围 | 替换标记 |
| --- | --- | --- |
| 云 AccessKey | 阿里云 LTAI、AWS AKIA/ASIA、腾讯云 AKID | `[ACCESSKEY_MASKED]` |
| API Key | OpenAI 兼容 sk- _ 、GitHub PAT ghp_/gho_/ghs_ _ | `[APIKEY_MASKED]` |
| 数据库连接串 | MySQL/PostgreSQL/MongoDB/Redis URI、JDBC 带密码 | `[DATABASEURL_MASKED]` |
| 私钥 | PEM / OpenSSH 私钥块 | `[PRIVATEKEY_MASKED]` |

脱敏通过配置开关控制（ `mask.mode: none | all | custom` ），默认关闭，开启后对所有输出通道（SLS / JSONL / HTTP / OTLP）统一生效。

**选择五：多目标输出，不绑定后端**

不同团队对数据的消费方式不同：安全合规需要结构化日志做审计查询，SRE 需要 Trace 视图做链路分析，本地开发者可能只想看一眼原始 JSONL。为了避免绑定单一后端，采集到的数据通过并行扇出同时写入多个目标，单个目标失败不阻塞其他通道：

- 本地 JSONL ：零依赖落盘，适合本地调试
- SLS Logstore ：生产级实时查询
- HTTP Endpoint ：对接自建后端
- OTLP Trace ：标准协议，接入 Jaeger / Grafana Tempo 等任意兼容后端

数据的存储和消费完全在用户自有基础设施中完成，不依赖任何 Agent 厂商。

3. 从安装到看板：1 分钟跑通全流程

讲了这么多设计思路，不如实际跑一遍。以下是从零开始到在看板上看到数据的完整过程。

**第一步：一行命令安装**

-
-
-
-
-
-

```
curl -fsSL https://loongcollector-community-edition.oss-cn-shanghai.aliyuncs.com/loongsuite-pilot/installer.sh | bash -s -- install \  --sls-endpoint "https://cn-xx.log.aliyuncs.com" \  --sls-project "my-project" \  --sls-logstore "my-logstore" \  --sls-ak-id "your-ak-id" \  --sls-ak-secret "your-ak-secret" \
```

安装脚本会自动完成：下载最新版本、部署到  `~/.loongsuite-pilot/` 、安装 Hook 脚本、启动后台进程。安装完成后 Pilot 即刻开始扫描 AI Coding Agent，自动注入采集能力。Pilot 同时支持日志和 Trace 两类数据输出，可以在安装时一起配置，两条通道并行工作，互不阻塞。

- 日志数据 ：输出到本地 JSONL 文件或 SLS Logstore，用于结构化查询和成本分析
- Trace 数据 ：通过 --collect-trace true 开启，将每次会话还原为完整的 Trace 调用树——从用户提问到模型推理、工具调用、最终回复，可以输出到 OTLP 的后端

**第二步：正常使用 Agent，数据自动采集**

安装完成后，像往常一样使用 Claude Code、Cursor 或其他 Agent 即可。Pilot 在后台静默运行，不会弹窗、不会改变你的操作习惯。

**第三步：通过本地 Dashboard 快速查看状态**

Pilot 内置了一个本地 Dashboard，无需任何外部依赖即可查看采集状态和 Agent 活跃情况：

-
-

```
loongsuite-pilot monitor start# 浏览器访问 http://127.0.0.1:8765
```

```
![](附件资源/当%20AI%20Coding%20Agent%20成为基础设施：我们为什么要开源%20LoongSuite%20Pilot/img_6.png)
```

Dashboard 提供 Agent 维度的采集概览——每个 Agent 的事件数、最近活跃时间、上报成功率，以及 Pilot 进程自身的 CPU / 内存资源占用趋势。这对于安装后的首次验证特别有用：一眼就能确认哪些 Agent 被成功发现、数据是否在正常流动。

**第四步：查看原始采集数据**

每条采集事件都会落盘到本地 JSONL 文件（ `~/.loongsuite-pilot/logs/output/` ）。我们来看一组真实的 Claude Code 事件——Agent 调用 Bash 工具执行  `ls`  命令，以及对应的执行结果：

**事件 1：** `tool.call` ** — Agent 发起工具调用**

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

```
{  "event.name": "tool.call",  "gen_ai.agent.type": "claude-code",  "gen_ai.session.id": "8e06a611-d9ae-4c43-b03d-a285e8bda3ab",  "gen_ai.turn.id": "8e06a611-d9ae-4c43-b03d-a285e8bda3ab:t1",  "gen_ai.step.id": "8e06a611-d9ae-4c43-b03d-a285e8bda3ab:t1:s3",  "gen_ai.tool.name": "Bash",  "gen_ai.tool.call.id": "toolu_vrtx_0115QdGCWqoQ4Mnj6aKwcEuy",  "gen_ai.tool.call.arguments": "{\"command\":\"ls /workspace/agent-data-collection/docs/\",\"description\":\"List docs directory\"}",  "trace_id": "09f11db9fca4348e70ad34aa620e810c",  "span_id": "dc688dbb763a7f4c",  "parent_span_id": "d5afbe7a280d0d52"}
```

**事件 2：** `tool.result` ** — 工具执行结果**

-
-
-
-
-
-
-
-
-

```
{  "event.name": "tool.result",  "gen_ai.tool.name": "Bash",  "gen_ai.tool.call.id": "toolu_vrtx_0115QdGCWqoQ4Mnj6aKwcEuy",  "gen_ai.tool.call.result": "E2E-REMOTE-TEST-GUIDE.md\n...",  "gen_ai.step.id": "8e06a611-d9ae-4c43-b03d-a285e8bda3ab:t1:s3",  "trace_id": "09f11db9fca4348e70ad34aa620e810c",  "span_id": "dc688dbb763a7f4c"}
```

```
从这组数据中可以读出很多信息：
```

- session.id → turn.id → step.id （ t1:s3 ）：三级标识层层递进——会话 → 第 1 轮对话 → 第 3 个 ReAct 步骤，精确定位这次工具调用在整个会话链路中的位置
- tool.name + tool.call.arguments ：Agent 调用了什么工具、传入了什么参数，完整记录——这对安全审计至关重要
- tool.call.id ：同一个 ID 串联了 tool.call 和 tool.result ，形成配对
- trace_id + span_id + parent_span_id ：OTel 链路 ID，将同一次任务的所有事件串联成完整调用树

**第五步：在 SLS 上查询和分析**

数据上报到 SLS 后，可以直接用 SQL 做分析。以下是几条实用的查询示例：

**查询某用户过去 7 天的 Token 总消耗：**

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

```
SELECT  "user.id",  "gen_ai.agent.type",  SUM(CAST("gen_ai.usage.input_tokens" AS BIGINT))  AS total_input,  SUM(CAST("gen_ai.usage.output_tokens" AS BIGINT)) AS total_output,  SUM(CAST("gen_ai.usage.total_tokens" AS BIGINT))  AS total_tokensFROM logWHERE "event.name" = 'llm.response'  AND "user.id" = '${userID}'GROUP BY "user.id", "gen_ai.agent.type"ORDER BY total_tokens DESC
```

```
按 Agent 类型统计工具调用 Top 10：
```

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

```
SELECT  "gen_ai.agent.type",  "gen_ai.tool.name",  COUNT(*) AS call_count,  AVG(CAST("gen_ai.tool.call.duration" AS DOUBLE)) AS avg_duration_msFROM logWHERE "event.name" = 'tool.result'GROUP BY "gen_ai.agent.type", "gen_ai.tool.name"ORDER BY call_count DESCLIMIT 10
```

```
找出 Token 消耗异常的会话（单次请求超过 50K Token）：
```

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

```
SELECT  "gen_ai.session.id",  "gen_ai.agent.type",  "user.id",  "gen_ai.request.model",  CAST("gen_ai.usage.total_tokens" AS BIGINT) AS total_tokensFROM logWHERE "event.name" = 'llm.response'  AND CAST("gen_ai.usage.total_tokens" AS BIGINT) > 50000ORDER BY total_tokens DESCLIMIT 20
```

```
这些查询直接使用归一化后的标准字段名，无论数据来自 Claude Code、Cursor 还是 Codex，同一条 SQL 通吃——这就是统一语义规范在下游分析中的实际价值。
```

在此基础上，可以进一步构建可视化看板，将这些查询固化为实时刷新的仪表盘。这也正是我们接下来要讨论的——有了这些数据，能回答哪些关键问题。

4. 用数据回答四个关键问题

![](附件资源/当%20AI%20Coding%20Agent%20成为基础设施：我们为什么要开源%20LoongSuite%20Pilot/img_7.png)

前面两章解决的是"怎么拿到数据"的问题——从安装部署到数据采集再到 SLS 查询，这条链路已经跑通了。但采集数据本身不是目的，真正的价值在于：这些数据能帮我们回答哪些以前回答不了的问题？

在实际使用中，我们发现团队对 AI Coding Agent 的核心关切可以归结为四个问题。这四个问题也是驱动我们持续优化采集能力的核心动力——每一次"现有数据还不够回答这个问题"的发现，都会反过来推动我们补充新的采集字段或扩展新的 Agent 适配。

**AI Coding 的 ROI 如何度量？**

企业在 AI Coding 工具上的投入正在快速攀升——按人均每月 $20-200 的订阅费、加上百万级 Token 的 API 调用费，一个 50 人的研发团队年投入轻松突破百万。但问到"这笔钱值不值"，大多数团队答不出来。

传统研发效能度量在 AI 时代彻底失效。代码行数？AI 写 500 行可能只是在循环试错。PR 数量？一个 Agent 会话可能产生 5 个 PR，也可能 5 个会话才产出 1 个有效 PR。Commit 频率？AI 生成的 commit 和人工精修的 commit 不能等量齐观。**我们缺的不是指标，而是一个能把"AI 做了什么"和"结果怎么样"关联起来的数据基础。**

Pilot 采集的全链路数据让这个关联成为可能。每次 Agent 执行任务的完整过程以 Trace 树形式呈现——从用户请求入口（ENTRY）到 Agent 决策（AGENT）、推理步骤（STEP）、LLM 调用（LLM）、工具执行（TOOL），层级关系一目了然：

![](附件资源/当%20AI%20Coding%20Agent%20成为基础设施：我们为什么要开源%20LoongSuite%20Pilot/img_8.png)

举一个具体的例子。某次 Claude Code 会话中，用户要求"重构认证模块"。Trace 树显示 Agent 经历了 12 轮 ReAct 推理，其中前 4 轮在读取和理解现有代码（工具调用以 Read、Grep 为主），第 5-10 轮在实施修改（Write、Edit 为主），第 11-12 轮在运行测试验证。通过 Step Span 可以看到：第 7 轮 Agent 写了一段代码但随即在第 8 轮自行回退重写——这种"自我修正"消耗了约 15% 的 Token，但最终产出了正确的实现。

这些信息聚合起来，就能构建出一套新的 ROI 度量体系：

- 任务完成率 ：发起了多少次会话，多少次真正完成了目标？（通过会话的最终事件类型判断）
- Token 效率比 ：每完成一个有效任务平均消耗多少 Token？不同复杂度的任务效率差异如何？
- 人机协作比 ：一次会话中 Agent 自主完成的步骤 vs 需要人工介入修正的步骤，比例是多少？
- 自我修正率 ：Agent 在执行中回退重做的比例——适度的自我修正说明模型有反思能力，过高则说明任务超出能力边界

**多 Agent 并存时代如何选型？**

一个团队里，有人习惯用 Cursor，有人偏爱 Claude Code，有人刚开始尝试 Codex。技术负责人经常被问到："我们应该统一用哪个？"但这个问题本身就是错的——正确的问题是**"什么场景用什么 Agent"**。

没有统一的数据视角时，团队只能凭个人体感"站队"。而体感往往有偏差——一个人对 Cursor 的好印象可能来自某次特别顺畅的补全体验，而忽略了它在跨文件重构时的低效。

Pilot 的统一 Schema 让跨 Agent 横向对比第一次成为可能。通过  `gen_ai.session.id → turn.id → step.id`  构建的三级标识体系，我们可以在相同的度量框架下，将同一个任务交给不同的 Agent 或不同的模型，观察它们行为上的真实差异。

我们做了一个实验：将同一个任务——"为一个模块补充单元测试"——分别交给 Claude Code、Cursor 和 Qoder，用 Pilot 采集三次执行的全链路数据。三个 Agent 都成功完成了任务，但打开 Pilot 的分析面板，**行为模式的差异一目了然**：

![](附件资源/当%20AI%20Coding%20Agent%20成为基础设施：我们为什么要开源%20LoongSuite%20Pilot/img_9.png)

**Claude Code：** 总耗时最短，LLM 单轮推理速度最快。工具调用以 Bash 为主，风格像一个在终端里工作的高级工程师——通过  `find`  和  `Read`  快速定位目标文件，确认上下文后一次写出测试。LLM 推理和工具执行的耗时各占一半，说明它在"思考"和"行动"之间保持了较好的节奏。

**Cursor：** LLM 调用次数最少但单轮推理时间最长——它启用了 high-thinking 模式，每一轮都在做更深度的推理。工具调用最为多样化（Shell + Read + Grep + Write），呈现出典型的"搜索-阅读-理解-编写"四步工作流，更像一个在 IDE 里精细操作的开发者。虽然总耗时最长，但输出 Token 也最多，生成的测试代码更详尽。适合需要深度理解、代码质量要求高的场景。

**Qoder：** Token 消耗远低于另外两者，上下文管理最为紧凑。最显著的特征是工具耗时几乎为零——所有工具调用都是轻量级 API（Glob、Read），时间几乎全花在 LLM 推理上。LLM 调用轮次最多但单轮推理最慢，呈现出"小步快跑"的风格——每轮处理的上下文更小，通过更多轮次逐步推进。适合对 Token 成本敏感、或需要频繁迭代的场景。

这些差异在没有统一数据采集之前，完全淹没在"感觉都差不多"的主观印象里。真正有价值的不是得出一个放之四海而皆准的结论，而是让每个团队基于自己的实际数据找到自己的"甜蜜区"——因为最优解不仅因 Agent 而异，也因团队的技术栈、代码库特点和工作方式而异。最终的答案往往不是 A vs B vs C，而是一套数据驱动的 Agent 组合策略。

**Token 花得多就是效果好吗？**

这是我们在实践中发现的最反直觉的现象：**Token 消耗和输出质量之间存在明显的非线性关系。** 很多时候，消耗最多 Token 的会话，产出质量反而最差。

我们追踪了一组真实案例，发现了三种典型的"Token 黑洞"模式：

**模式一：循环试错。** Agent 尝试某种方案 → 运行测试失败 → 换一种方案 → 再次失败 → 反复循环。在 Trace 树上表现为大量连续的 STEP，每个 STEP 内都有 Write + Bash(test) 的工具调用对，但 Bash 的结果始终包含错误输出。

**模式二：上下文膨胀。** 随着会话变长，每轮对话携带的上下文越来越大，导致  `input_tokens`  呈阶梯式上升。这种增长有时是必要的（复杂任务需要大量上下文），但更多时候是因为缺少有效的上下文管理——Agent 把前面轮次的完整输出全部带入下一轮，而其中大部分信息已经不再相关。

**模式三：过度谨慎。** Agent 在执行前花大量 Token 反复确认和推理，"思考"占比远超"行动"。在 Trace 树上表现为 LLM Span 的 Token 消耗占 80% 以上，而 TOOL Span 寥寥无几。

基于  `gen_ai.usage.input_tokens` 、 `gen_ai.usage.output_tokens` 、 `gen_ai.usage.total_tokens` 、 `gen_ai.usage.cache_read.input_tokens`  等字段，可以构建多层次的成本可视化：

![](附件资源/当%20AI%20Coding%20Agent%20成为基础设施：我们为什么要开源%20LoongSuite%20Pilot/img_10.png)

识别这些模式的价值不仅在于成本优化——它们本质上是 Agent 能力边界的信号灯。哪些任务类型容易触发循环试错？哪些代码库的上下文管理需要优化？哪些场景下应该果断切换到人工介入？这些决策以前只能靠直觉，现在有了数据支撑。

**AI Agent 的操作谁来审计？**

前面三个问题关乎效率和成本，这个问题关乎安全底线。

我们正在见证一个前所未有的现象：**AI Agent 是人类历史上第一种大规模拥有代码写入权限的非人类实体。** 一个 Agent 可以在几分钟内修改几十个文件、执行数十条 shell 命令、访问数百个代码路径。更关键的是，这些操作的发起者不是人——是模型基于概率推理做出的决策，而模型是可以被操纵的。

提示词注入（Prompt Injection）是当前 AI Agent 面临的最严峻安全威胁之一。攻击者可以在代码注释、Issue 描述、甚至文件内容中植入恶意指令，诱导 Agent 执行非预期操作——删除关键文件、泄露环境变量、向外部地址发送敏感数据。这些操作在日志中看起来和正常的工具调用毫无差别，传统的安全审计手段几乎无法识别。

这正是全链路行为数据的价值所在。基于 Pilot 采集的完整 Agent 行为数据，可以构建一套从管理到调查的多层安全审计体系：

**第一层：审计管理与运行时监控。** 将所有接入的 Agent 应用（Claude Code、Cursor、Codex、Qoder 等）纳入统一的审计管理视图，每个应用的活跃趋势一目了然。同时开启 AI 系统运行时审计，实时监控各主机上运行的 Agent 类型和行为状态。

![](附件资源/当%20AI%20Coding%20Agent%20成为基础设施：我们为什么要开源%20LoongSuite%20Pilot/img_11.png)

**第二层：风险态势大盘。** 全局视角展示风险事件统计——高风险事件数、今日操作数、敏感写入次数、安全事件总量等核心指标。通过信号分层摘要（高/中/低），快速判断当前安全态势。今日优先风险队列按应用和严重程度自动排序，将最需要关注的风险事项置顶。

![](附件资源/当%20AI%20Coding%20Agent%20成为基础设施：我们为什么要开源%20LoongSuite%20Pilot/img_12.png)

**第三层：风险主体定位。** 从应用、用户、主机、工具类型、外联域名/IP、命令等六个维度，分别列出 Top 3 风险主体。每个主体标注其主要风险标签（如  `dangerous_command` 、 `sensitive_access` 、 `model_context_secret_leak` ），帮助安全团队快速锁定需要重点关注的对象。

![](附件资源/当%20AI%20Coding%20Agent%20成为基础设施：我们为什么要开源%20LoongSuite%20Pilot/img_13.png)

**第四层：数据泄露链路分析。** 这是最关键的深度分析视角。将数据外传风险拆解为三条链路：攻击驱动外传链路（恶意指令触发的数据窃取）、模型上下文泄露链路（敏感信息通过模型上下文流出）、敏感数据类型分布（识别涉及的数据类型如密钥、凭证等）。泄露发现队列将所有可疑的 DLP 事件集中呈现，关联外传链路、上下文溢出和敏感数据匹配结果，支持快速定性。

![](附件资源/当%20AI%20Coding%20Agent%20成为基础设施：我们为什么要开源%20LoongSuite%20Pilot/img_14.png)

**第五层：实体关联调查。** 当锁定可疑目标后，进入实体调查视图。该视图将所有 Agent 行为涉及的实体——应用、主机、用户、会话、工具、外联域名、目标 IP、AK/Secret、文件路径、命令、敏感路径模式等——以全景方式呈现，每种实体类型标注出异常数量占比。下钻到具体实体后，可以看到该实体的完整行为画像和关联的安全事件。

![](附件资源/当%20AI%20Coding%20Agent%20成为基础设施：我们为什么要开源%20LoongSuite%20Pilot/img_15.png)

**第六层：会话级追溯。** 最终，所有调查都汇聚到具体的会话。以 Session 为单位展示完整的事件时间线——每条事件的类型、参数、涉及工具和完整上下文一览无余。安全团队可以逐事件回放 Agent 的行为轨迹，精确判断是正常操作还是被恶意指令驱动的异常行为，为最终定性提供原始证据。

![](附件资源/当%20AI%20Coding%20Agent%20成为基础设施：我们为什么要开源%20LoongSuite%20Pilot/img_16.png)

5. 开源与社区

今天，我们正式将 **LoongSuite Pilot** 开源。作为 LoongSuite 可观测套件在端侧的延伸，Pilot 补齐了 AI Coding Agent 这一可观测盲区——让运行在开发者本地的 Agent 行为，和服务端的模型调用、基础设施指标一样，变得可采集、可查询、可分析。

- LoongSuite Pilot ：https://github.com/alibaba/loongsuite-pilot

同时也欢迎关注 LoongSuite 生态的其他开源项目：

- LoongCollector：https://github.com/alibaba/loongcollector
- LoongSuite Python Agent：https://github.com/alibaba/loongsuite-python-agent
- LoongSuite Go Agent：https://github.com/alibaba/loongsuite-go-agent
- LoongSuite Java Agent：https://github.com/alibaba/loongsuite-java-agent
- LoongSuite Semantic Conventions：https://github.com/alibaba/loongsuite-semantic-conventions

**接下来我们计划做的事：**

- 更多 Agent 适配：OpenClaw、Hermes、Gemini CLI、Cline 等
- 开箱即用的分析看板：效率度量和成本分析 Dashboard
- 社区 Agent 贡献模板：标准化的第三方 Agent 适配流程

**如何参与：**

- 提交 Issue：报告 Bug 或提出新的 Agent 适配需求
- 贡献 Agent 适配：参考 agents.d/ 下的声明文件和已有实现
- 分享实践：把你的使用经验和分析洞察分享到社区

AI Coding Agent 正在重新定义软件开发的方式。我们相信，可观测性是让这些 Agent 从"能用"走向"好用"的关键基础设施——而这个基础设施应该是开放的、标准化的、属于社区的。

---
原文链接：https://mp.weixin.qq.com/s?__biz=MzIzOTU0NTQ0MA%3D%3D&mid=2247560862&idx=1&sn=997c0e80d7bdc1f6ddc39fa4c79a4380&chksm=e868c9c18443ace49a48a4df89ece01f23aa5a1ec16192420d545b3bbaf6d218023da5e4f72b
