---
source_url: "https://mp.weixin.qq.com/s?__biz=Mzg3Njc2NDAwOA==&mid=2247539999&idx=1&sn=b9a6c2d46d3ae60d73cc812d54a7fcba&chksm=ce79226808f57b5bac2eb50bdf1d31d006c15200278f5bb9c2fda9e0acac1fe5473e1db53685&mpshare=1&scene=1&srcid=0309dJI6KeSD1rrBuSxWspe3&sharer_shareinfo=f6031765c5f3b34652cc022d081b67bc&sharer_shareinfo_first=f6031765c5f3b34652cc022d081b67bc"
title: "我们用 AI Observe Stack 观测了 OpenClaw，发现 AI Agent 背后的这些隐患"
account: "SelectDB"
published_at: "2026-03-04T10:14:00.000Z"
saved_at: "2026-07-15T17:08:25.907Z"
sync_id: "art_0348f75f7a6b4af28e96daa7e32f82c2"
parse_status: "ok"
---

# 我们用 AI Observe Stack 观测了 OpenClaw，发现 AI Agent 背后的这些隐患

![](附件资源/我们用%20AI%20Observe%20Stack%20观测了%20OpenClaw，发现%20AI%20Agent%20背后的这些隐患/img_1.jpg)

![](附件资源/我们用%20AI%20Observe%20Stack%20观测了%20OpenClaw，发现%20AI%20Agent%20背后的这些隐患/img_2.gif)

![](附件资源/我们用%20AI%20Observe%20Stack%20观测了%20OpenClaw，发现%20AI%20Agent%20背后的这些隐患/img_3.png)

**导读：**OpenClaw 成为风靡全球的 AI Agent 同时，它的安全性和 AI Agent 通用的不确定性等问题也引发人们的广泛关注。基于 SelectDB 或 Apache Doris 的 AI Observe Stack 可以为 OpenClaw 提供可观测性，让 AI Agent 的每一个行为清晰可见、安全问题可被洞察，让你看清它的每一个 “脑回路”。

本文基于 AI Observe Stack 构建的 OpenClaw可观测系统是使用 AI 在一天内完成的。用户也可以用阿里云 SelectDB 云服务或者开源 Apache Doris 在几分钟内快速搭建起来亲身体验。

![](附件资源/我们用%20AI%20Observe%20Stack%20观测了%20OpenClaw，发现%20AI%20Agent%20背后的这些隐患/img_4.png)

## 1. OpenClaw：爆火背后的安全危机

## OpenClaw 大概是 2026 年最火的开源 AI Agent 平台。它支持通过 WhatsApp、Telegram、Web 等渠道与用户交互，背后的 Agent 可以调用 shell 命令、浏览网页、搜索信息、操作文件、发送消息——几乎无所不能。

![](附件资源/我们用%20AI%20Observe%20Stack%20观测了%20OpenClaw，发现%20AI%20Agent%20背后的这些隐患/img_5.png)

但"无所不能"恰恰是问题所在。

OpenClaw 上线短短几周内，安全事件已经井喷。来自 Kaspersky、Cisco、CrowdStrike、Trend Micro 等安全厂商的报告描绘了一幅触目惊心的画面：

- 近 1000 个暴露的 OpenClaw 实例 被安全研究员通过 Shodan 发现，这些实例无需认证即可访问，泄露了 API 密钥、Telegram bot token 和完整聊天记录： https://www.kaspersky.com/blog/openclaw-vulnerabilities-exposed/55263/
- 安全审计发现 512 个漏洞 ，其中 8 个为高危 ，包含一个 CVSS 8.8 的远程代码执行漏洞 CVE-2026-25253 。 Kaspersky ：www.bitsight.com/blog/openclaw-ai-security-risks-exposed-instances
- 研究人员证明：仅凭 一封精心构造的邮件 ，就能通过 prompt injection 诱导 OpenClaw 窃取私有 SSH 密钥和 API token。 BitSight： www.trendmicro.com/en_us/research/26/b/what-openclaw-reveals-about-agentic-assistants.html

- ClawHub 技能市场中 36% 的技能存在安全缺陷 ，1467 个含恶意载荷 。 Trend Micro： https://snyk.io/blog/toxicskills-malicious-ai-agent-skills-clawhub/

- 工信部专门发布了《关于防范 OpenClaw 开源 AI 智能体安全风险的预警提示》

Cisco 的分析一针见血：OpenClaw 的安全问题不是配置问题，而是**架构问题**——它的官方文档自己都写着："there is no 'perfectly secure' setup"。

这些是行业公开的安全报告。那么，如果我们对一个实际运行中的 OpenClaw 实例做深度审计，会看到什么？

### 我们的审计结果

我们用 **AI Observe Stack**（https://github.com/velodb/ai-observe-stack）对一个真实的 OpenClaw 实例进行了 7 天的全量可观测审计，记录了每一次 LLM 调用、每一次工具执行、每一条日志。结果如下：

- Agent 自主执行了 31 次 shell 命令 ，包括文件操作和网络请求
- Agent 访问了 40 个外部网站 ，其中部分内容包含 prompt injection 标记
- 一个用户的 单次提问 触发了 19 轮 LLM 调用 ，累计消耗 784 万 tokens
- 在外部网页返回的内容中，检测到 "ignore previous instructions" 等注入模式

行业报告告诉你"有风险"，而可观测数据让你**亲眼看到风险在哪里、有多大**。

**你以为你在用 ****AI****，其实 AI 在用你的权限。**

而且，正如 Trend Micro 所指出的，这些问题**不是 OpenClaw 独有的**，而是 Agent AI 范式的固有问题。几乎所有具备工具调用能力的 AI Agent 都会面临同样的困境。

## 2. 三个黑盒问题：从 OpenClaw 看所有 AI Agent

OpenClaw 的审计结果揭示了 AI Agent 的三个本质性黑盒问题。传统软件有日志、有监控、有审计，但 AI Agent 不一样——它的行为是非确定性的、上下文驱动的、自主决策的。

### 2.1 黑盒一：安全黑盒

在 OpenClaw 的审计中，我们看到 Agent 执行了  `curl`  访问外部 URL、用  `exec`  操作文件系统、通过  `gateway`  向用户发送消息。这些操作都是 Agent 自主决定的，用户并不知情。

这不是 OpenClaw 的特例。任何具备工具调用能力的 AI Agent 都可能执行 shell 命令（ `rm -rf` 、 `sudo` ）、读取敏感文件（ `.ssh/id_rsa` 、 `.env` ）、发送网络请求（ `curl` 、 `scp` ）。更危险的是，当 Agent 浏览网页时，恶意网站可以在页面中嵌入 prompt injection 内容——Agent 读到 "ignore previous instructions" 时，它可能真的会执行。

**你完全不知道它干了什么。**

### 2.2 黑盒二：成本黑盒

OpenClaw 中最极端的案例：一个用户问题触发了 19 轮 LLM 调用。Agent 的"思考链"是这样的——先搜索网页、再浏览页面、再执行命令、再总结结果。每一步都是一次 LLM 调用，而每次调用都携带了**完整的对话历史**。

这就是 context window 的滚雪球效应：第一轮调用 3000 tokens，第二轮 8000，第三轮 25000……到第 19 轮已经膨胀到几十万 tokens。一个问题的成本可能是你预期的 100 倍。

这个问题在所有 AI Agent 中普遍存在。**月底账单才知道花了多少。**

### 2.3 黑盒三：行为黑盒

OpenClaw 的 工具调用错误率， `exec`  的调用次数，部分请求的 P95 延迟远是否高于平均值。但如果没有可观测体系，这些数据你根本看不到。

当用户投诉"AI 回答慢"或"AI 回答不准"时，你无法复盘——不知道是 LLM 慢、工具调用失败、还是 Agent 进入了死循环。

**出了问题无法复盘。**

**3. 解决方案：用可观测性打开黑盒**

### 3.1 AI Observe Stack 简介

AI Observe Stack（https://github.com/velodb/ai-observe-stack）是一个开源的 AI 可观测平台，专为 AI Agent 场景设计。它基于三个成熟的开源项目：

组件

Progress

OpenTelemetry Collector

遥测数据网关，接收 OpenTelemetry 协议数据

Apache Doris

存储层，VARIANT 类型 + 倒排索引，天然适配半结构化数据

Grafana + Doris App 插件

可视化层，支持 SQL 查询和预置 Dashboard

### 3.2 架构介绍

![](附件资源/我们用%20AI%20Observe%20Stack%20观测了%20OpenClaw，发现%20AI%20Agent%20背后的这些隐患/img_6.png)

**核心优势：**

- Traces + Metrics + Logs 三合一 ：不是三套系统，而是统一采集、统一存储、统一查询
- SQL 查询 ：不需要学新的查询语言，标准 SQL 即可分析所有数据
- 实时分析 ：数据写入即可查询，不需要等待 ETL 或预聚合
- 5 分钟部署 ：一条 docker compose up -d 搞定

> 💡 本文使用开源 Apache Doris 进行演示。如果你的 AI Agent 已经在生产环境运行，需要更高的可用性、弹性扩缩容和免运维体验，可以使用阿里云 SelectDB 云数据库 ——基于 Apache Doris 的全托管云服务，即可获得开箱即用的生产级可观测存储。 产品介绍： https://www.aliyun.com/product/selectdb?utm_content=g_1000410296

## 4. 用 AI Observe Stack 观测 OpenClaw

说了这么多问题，怎么解决？我们用 AI Observe Stack 对 OpenClaw 做了完整的可观测接入。以下所有数据来自真实的 OpenClaw 运行环境，通过三个预置 Dashboard 呈现。

### 4.1 安全审计：你的 Agent 在执行什么命令？

这是你最应该关心的问题。

打开 **Security & Audit Dashboard**，顶部四个指标卡片一目了然：

![](附件资源/我们用%20AI%20Observe%20Stack%20观测了%20OpenClaw，发现%20AI%20Agent%20背后的这些隐患/img_7.png)

- Dangerous Commands ：检测到的危险 shell 命令数量（ rm -rf 、 sudo 、 chmod 777 、 curl | sh 等）
- Prompt Injection ：外部内容中检测到的注入模式数量（ ignore previous instructions 、 you are now 、 DAN mode 等）
- Outbound Actions ：Agent 主动发出的对外操作（发邮件、发消息、调用外部 API）
- Sensitive File Access ： Agent 访问敏感文件的次数（ .ssh/id_rsa 、 .env 、 credentials.json 等）

数字变红意味着需要立即关注。

#### 4.1.1 Security Event Timeline

往下看时间线图，可以看到安全事件的时间分布：

![](附件资源/我们用%20AI%20Observe%20Stack%20观测了%20OpenClaw，发现%20AI%20Agent%20背后的这些隐患/img_8.png)

每种颜色代表一类操作：橙色是 shell 命令执行，蓝色是浏览器操作，紫色是网页抓取，红色是 gateway 调用。如果某个时段出现异常的操作尖峰——比如凌晨 3 点突然执行了大量 shell 命令——你需要警觉。

#### 4.1.2 Top Risk Sessions

哪些会话最危险？**Top Risk Sessions** 表格按风险评分排序：

![](附件资源/我们用%20AI%20Observe%20Stack%20观测了%20OpenClaw，发现%20AI%20Agent%20背后的这些隐患/img_9.png)

风险评分算法： `exec×3 + web×2 + outbound×5 + error×1 + sensitive_file×10` 。得分越高，越需要优先审查。

展开折叠面板，可以深入查看每个风险类型的详细记录：

- Dangerous Command Detection ：每条危险命令的执行时间、会话 ID、风险类别（DESTRUCTIVE / PRIVILEGE_ESCALATION / DATA_EXFIL / CREDENTIAL_ACCESS）和完整命令内容

![](附件资源/我们用%20AI%20Observe%20Stack%20观测了%20OpenClaw，发现%20AI%20Agent%20背后的这些隐患/img_10.png)

- Prompt Injection Detection ：检测到的注入内容、风险类型（INJECTION_PATTERN / ROLE_HIJACK / HIDDEN_INSTRUCTION / JAILBREAK）和来源工具

![](附件资源/我们用%20AI%20Observe%20Stack%20观测了%20OpenClaw，发现%20AI%20Agent%20背后的这些隐患/img_11.png)

- Outbound Data Flow Audit ：所有对外操作的记录，包括发送的邮件、消息和网络请求

![](附件资源/我们用%20AI%20Observe%20Stack%20观测了%20OpenClaw，发现%20AI%20Agent%20背后的这些隐患/img_12.png)

- Sensitive File Access Log ：敏感文件访问明细，按文件类型分类（SSH_KEY / ENV_FILE / CREDENTIALS 等）

![](附件资源/我们用%20AI%20Observe%20Stack%20观测了%20OpenClaw，发现%20AI%20Agent%20背后的这些隐患/img_13.png)

- User Message Audit Trail ：完整的用户消息审计轨迹，按渠道分类（WhatsApp / Web），可搜索过滤

![](附件资源/我们用%20AI%20Observe%20Stack%20观测了%20OpenClaw，发现%20AI%20Agent%20背后的这些隐患/img_14.png)

- Tool Execution Log ：所有工具执行的完整日志，包含工具名、执行状态（OK / ERROR）和返回内容，用于取证分析

![](附件资源/我们用%20AI%20Observe%20Stack%20观测了%20OpenClaw，发现%20AI%20Agent%20背后的这些隐患/img_15.png)

- Tool Calls vs Errors Over Time ：工具调用总量与错误数的趋势对比，错误率突增可能意味着 Agent 正在尝试越权操作

![](附件资源/我们用%20AI%20Observe%20Stack%20观测了%20OpenClaw，发现%20AI%20Agent%20背后的这些隐患/img_16.png)

**关键发现**：通过这个 Dashboard，我们可以去发现 Agent 在处理某些用户请求时，是否会主动执行  `curl`  命令访问外部 URL，是否执行了危险的命令，如 rm， 返回的内容中是否包含了 prompt injection 标记。预防**间接提示注入攻击链**。

### 4.2 成本分析：一个问题花了多少钱？

打开 **Cost & Efficiency Dashboard**，先看概览：

![](附件资源/我们用%20AI%20Observe%20Stack%20观测了%20OpenClaw，发现%20AI%20Agent%20背后的这些隐患/img_17.png)

#### 4.2.1 Token Usage Over Time

时序图显示 token 消耗趋势，按模型分别统计 input 和 output：

![](附件资源/我们用%20AI%20Observe%20Stack%20观测了%20OpenClaw，发现%20AI%20Agent%20背后的这些隐患/img_18.png)

右侧的饼图展示各模型的 token 占比，帮你看清成本主要花在了哪个模型上。

#### 4.2.2 Context Window 滚雪球效应

这是最值得关注的图表——**Input Tokens per Turn（Context Window Growth）**：

![](附件资源/我们用%20AI%20Observe%20Stack%20观测了%20OpenClaw，发现%20AI%20Agent%20背后的这些隐患/img_19.png)

每条线代表一个会话。你可以清晰地看到**滚雪球效应**：随着对话进行，每次 LLM 调用携带的 input tokens 持续增长——因为每次调用都带上了完整的对话历史。

一个会话的 input tokens 可能从几千膨胀到几十万。这意味着一个用户问了 19 个问题，最后一个问题的 input 成本可能是第一个问题的 **100 倍**。

#### 4.2.3 Per-Question Cost（每个问题花了多少？）

这个表格把成本拆解到每个用户问题：

![](附件资源/我们用%20AI%20Observe%20Stack%20观测了%20OpenClaw，发现%20AI%20Agent%20背后的这些隐患/img_20.png)

- ai_steps ：这个问题触发了多少轮 LLM 调用（蓝色越深，轮数越多）
- total_input ：累计 input tokens（红色越深，成本越高）
- user_question ：用户问了什么

你会发现，一些看似简单的问题——比如"帮我查一下这个网站的信息"——实际触发了 Agent 的长链路操作：先搜索、再浏览、再总结、再确认，每步都是一次 LLM 调用。**一个问题可能消耗几十万 tokens**。

### 4.3 行为分析：Agent 在做什么？

打开 **Agent Behavior Dashboard**，从全局视角看 Agent 行为。

#### 4.3.1 性能概览

![](附件资源/我们用%20AI%20Observe%20Stack%20观测了%20OpenClaw，发现%20AI%20Agent%20背后的这些隐患/img_21.png)

- Avg Request Latency ：用户发出请求到得到回复的平均时长
- Avg Turn Duration ：Agent 每个思考回合的平均耗时
- Total Spans ：总 Span 数（衡量 Agent 活跃度）
- Trace Chains ：Trace 链路数（衡量请求复杂度）

#### 4.3.2 Tool 调用分布

![](附件资源/我们用%20AI%20Observe%20Stack%20观测了%20OpenClaw，发现%20AI%20Agent%20背后的这些隐患/img_22.png)

**Tool Call Summary** 表格展示了每个工具的全貌：

![](附件资源/我们用%20AI%20Observe%20Stack%20观测了%20OpenClaw，发现%20AI%20Agent%20背后的这些隐患/img_23.png)

**关键发现**：

- browser 工具的被调用 40 次，是使用此时最多的 tool
- exec 被调用了 31 次——每次调用都应该被审查
- web_fetch 占总调用量的大头，这意味着 Agent 花了大量时间在抓取外部内容

#### 4.3.3 Span Performance Summary

深入到 Span 级别的性能分析：

![](附件资源/我们用%20AI%20Observe%20Stack%20观测了%20OpenClaw，发现%20AI%20Agent%20背后的这些隐患/img_24.png)

可以看到  `openclaw.request` （端到端延迟）的 P95 远高于平均值——说明存在长尾请求。通过 Trace 链路，你可以定位到是哪个工具调用或 LLM 调用拖慢了整个请求。

#### 4.3.4 Conversation Flow

![](附件资源/我们用%20AI%20Observe%20Stack%20观测了%20OpenClaw，发现%20AI%20Agent%20背后的这些隐患/img_25.png)

这是一张完整的对话流水表，按时间倒序展示 Agent 与用户的每一次交互。你可以清晰地看到一个请求的完整生命周期：用户发问 → Agent 思考 → 调用工具 → 获取结果 → 生成回复。每行的  `msg_role`  用颜色区分：蓝色是用户消息，绿色是 Agent 回复，橙色是工具返回。当你在其他面板中发现异常时，可以在这里定位到具体的对话上下文，进行逐条复盘。

### 4.4 日志探索：Doris App Discover

### Dashboard 提供的是预定义的分析视角，但实际排查问题时，你往 往需要 自由探索原始数据 。Doris App 插件内置的 Discover 功能正是为此设计。

在 Grafana 左侧导航栏进入 **Doris App > Discover**，你会看到一个类似 Kibana 的日志探索界面：

![](附件资源/我们用%20AI%20Observe%20Stack%20观测了%20OpenClaw，发现%20AI%20Agent%20背后的这些隐患/img_26.png)

顶部的查询栏支持两种模式：**SQL** 和 **Lucene**。SQL 模式下你可以写任意 WHERE 条件，比如  `log_attributes['type'] = 'message'`  精确筛选 Agent 的对话消息；Lucene 模式则提供全文搜索能力，适合模糊查找关键词。

点击展开任意一条日志，可以看到完整的结构化详情：

![](附件资源/我们用%20AI%20Observe%20Stack%20观测了%20OpenClaw，发现%20AI%20Agent%20背后的这些隐患/img_27.png)

展开后的 Table 视图将每个字段清晰列出，JSON 视图则展示原始数据结构。你可以直接看到 Agent 的完整消息内容——包括它的思考过程（ `thinking` ）、执行的命令、调用的模型和 token 消耗。点击 "Surrounding items" 还能查看上下文日志，还原完整的事件时间线。

Discover 在以下场景特别有用：

- 即席查询 ： Dashboard 没有覆盖的分析需求，直接写 SQL 探索
- 关键词搜索 ： 搜索特定的错误信息、文件路径或命令内容
- 数据验证 ： 确认数据采集是否正常，检查字段格式是否符合预期

### 4.5 深入追踪：Doris App Trace 分析

三个 Dashboard 提供了全局视角，但当你需要**深入到单个请求的完整调用链**时，Doris App 插件内置的 Trace 功能是更强大的工具。

在 Grafana 左侧导航栏进入 **Doris App > Traces**，你会看到一个专业的 Trace 搜索界面：

![](附件资源/我们用%20AI%20Observe%20Stack%20观测了%20OpenClaw，发现%20AI%20Agent%20背后的这些隐患/img_28.png)

你可以按 Service、Operation 筛选，也可以通过 Tags 精确搜索（例如  `http.status_code=200 error=true` ），或按 Duration 范围过滤出慢请求。散点图直观展示了每个 Trace 的耗时分布——那些远高于平均线的点就是需要关注的异常请求。

点击任意一条 Trace，进入 **Waterfall 视图**：

![](附件资源/我们用%20AI%20Observe%20Stack%20观测了%20OpenClaw，发现%20AI%20Agent%20背后的这些隐患/img_29.png)

这个视图把一个 Agent 请求的完整生命周期展开成调用链： `openclaw.agent.turn`  是父 Span，耗时 38.33 秒；其下的  `tool.browser` 、 `tool.web_fetch`  等子 Span 展示了 Agent 在这次回合中依次调用了哪些工具、每个工具花了多长时间。

Trace 分析在以下场景特别有价值：

- 慢请求定位 ： 用户反馈"AI 回复太慢"，通过 Trace 精确定位是 LLM 推理慢还是某个工具调用卡住了
- 异常行为取证 ： 安全审计中发现可疑操作，通过 Trace ID 追溯完整的调用上下文
- Agent 行为理解 ： 直观看到 Agent 的"思考过程"——它先调了什么工具、再调了什么、为什么耗时这么长

Dashboard 告诉你"有问题"，Trace 告诉你"问题在哪里"。

## 5. 5 分钟部署

## 第一步：启动 AI Observe Stack

```

```

```
git clone https://github.com/ai-observe/ai-observe-stack.git
cd ai-observe-stack/docker
docker compose up -d
```

等待 Doris 就绪（首次约 3 分钟）：

```
docker compose ps
# 确认所有服务 STATUS 显示 "running"，doris 显示 "(healthy)"
```

``

> 💡 生产环境 可以使用 阿里云 SelectDB 云数据库 替代本地 Doris，详见下方生产环境：对接 阿里云 SelectDB 产品介绍： https://www.aliyun.com/product/selectdb?utm_content=g_1000410296

### 第二步：对接你的 AI Agent

以 OpenClaw 为例，安装社区 OTel 插件并配置 OpenTelemetry endpoint：

```
# 安装插件
mkdir -p ~/.openclaw/plugins
cd ~/.openclaw/plugins
git clone https://github.com/henrikrexed/openclaw-observability-plugin otel-observability
cd otel-observability && npm install
```

在  `~/.openclaw/openclaw.json`  中配置：

```
{
"plugins": {
"load": {
"paths": ["~/.openclaw/plugins/otel-observability"]
},
"entries": {
"otel-observability": {
"enabled": true,
"config": {
"endpoint": "http://127.0.0.1:4318",
"protocol": "http",
"serviceName": "openclaw",
"traces": true,
"metrics": true
}
}
}
}
}
```

启动日志采集（因为社区插件不导出日志，需要通过 filelog 方式采集）。注意：以下命令中的  `$(pwd)`  指向第一步 clone 的  `ai-observe-stack/docker`  目录，请确保在该目录下执行：

```
docker run -d \
--name openclaw-log-collector \
--network docker_aiobs-net \
-v ~/.openclaw/logs:/openclaw-logs:ro \
-v ~/.openclaw/agents:/openclaw-agents:ro \
-v $(pwd)/../examples/openclaw/otel-collector-log-config.yaml:/etc/otelcol-contrib/config.yaml:ro \
otel/opentelemetry-collector-contrib:0.144.0 \
--config=/etc/otelcol-contrib/config.yaml
```

重启 OpenClaw：

```
openclaw gateway restart
```

### 第三步：打开 Dashboard

打开 Grafana（http://localhost:3000，默认账号 `admin` / `admin`），三个 OpenClaw Dashboard 已经预置好了，无需手动导入：

- Security & Audit Dashboard — 安全审计
- Cost & Efficiency Dashboard — 成本分析
- Agent Behavior Dashboard — 行为分析

对接 OpenClaw 并产生数据后，Dashboard 会自动展示分析结果。你的 AI Agent 的一切行为，现在都在你的掌控之中。

### 生产环境：对接阿里云 SelectDB

上面的一键部署包含了内置的 Doris 实例，适合本地体验和开发测试。如果你的 AI Agent 已经在生产环境运行，**推荐使用 阿里云 SelectDB 云数据库**：https://www.aliyun.com/product/selectdb?utm_content=g_1000410296作为 AI Observe Stack 的后端存储，免去运维负担。

只需将第一步替换为以下操作，其余步骤完全一致：

```
# 1. 配置连接信息
cp .env.example .env
# 编辑 .env，填入 SelectDB Cloud 连接信息：
DORIS_FE_HTTP_ENDPOINT=http://.selectdb.com:http_port
DORIS_FE_MYSQL_ENDPOINT=.selectdb.com:mysql_port
DORIS_USERNAME=admin
DORIS_PASSWORD=

# 2. 使用 without-doris 模式启动（不启动本地 Doris，数据直接写入云端）
docker compose -f docker-compose-without-doris.yaml up -d
```

## 6. 不只是 OpenClaw

## 虽然本文以 OpenClaw 为例，但 AI Observe Stack 的设计是通用的。任何支持 OpenTelemetry 的 AI Agent 框架都可以接入：

- 数据采集 ： 通过 OpenTelemetry 协议（gRPC :4317 / HTTP :4318）发送 Traces 和 Metrics；通过 filelog receiver 采集日志
- 数据存储 ： Apache Doris 的高效列式存储，VARIANT 类型天然适配半结构化 JSON 的可观测数据，倒排索引自动加速文本检索等查询
- 数据分析 ： 标准 SQL 查询，你可以自由编写任何分析逻辑

无论你用的是 LangChain、AutoGen、CrewAI 还是自研的 Agent 框架，只要输出 OpenTelemetry 格式的遥测数据，就能接入这套体系。

## 7. 结语

## 如果你正在运行 AI Agent，你需要回答一个问题：

**你知道它在做什么吗？**

它执行了哪些命令？访问了哪些文件？调用了哪些外部服务？花了多少 token？有没有被注入攻击？

如果你回答不了这些问题，那你的 AI Agent 就是一个黑盒——一个拥有你全部权限的黑盒。

**AI Observe Stack 的目标，就是为每一个 AI Agent 装上一扇“透明玻璃窗”。**让黑盒变白盒，让不确定性变得确定。我们相信，可观测性是 AI 大规模落地的基石。

**开源不应孤独，** 如果你也认同这个理念，欢迎给我们的项目点个 Star，支持我们继续为 AI 的安全保驾护航。

👉 GitHub 地址：https://github.com/ai-observe/ai-observe-stack

**想立刻体验？**

无论你是 OpenClaw 的玩家，还是正在开发自己的 AI Agent，都可以在几分钟内快速部署这套观测栈：

**省心的云上部署：**使用 阿里云 SelectDB 云数据库，无需自己维护数据库：https://www.aliyun.com/product/selectdb?utm_content=g_1000410296

**免费的开源部署：**喜欢 DIY 的朋友可以选择 Apache Doris。

如果你想进一步沟通，可**扫码进入 AI 可观测**交流群。在这里，您不仅可以与其他有相同需求的用户交流，还能获得专业的技术咨询和支持。

![](附件资源/我们用%20AI%20Observe%20Stack%20观测了%20OpenClaw，发现%20AI%20Agent%20背后的这些隐患/img_30.jpg)

**- END - **

更多标杆企业信赖

**智慧金融与政企**：[财通证券](https://mp.weixin.qq.com/s?__biz=Mzg3Njc2NDAwOA==&mid=2247539061&idx=1&sn=1bdfea7a7623b32b2bab8424c7ffd79f&scene=21#wechat_redirect)｜[东北证券](https://mp.weixin.qq.com/s?__biz=Mzg3Njc2NDAwOA==&mid=2247534484&idx=1&sn=be3c0e26da40a1da03dd3bc487961880&scene=21#wechat_redirect)｜[度小满](https://mp.weixin.qq.com/s?__biz=Mzg3Njc2NDAwOA==&mid=2247539096&idx=1&sn=6b5bfd2e41448cc428fce7aa749a5099&scene=21#wechat_redirect)｜[国金证券](https://mp.weixin.qq.com/s?__biz=Mzg3Njc2NDAwOA==&mid=2247535362&idx=1&sn=745fd6aa178aae78e807f59932c7e5eb&scene=21#wechat_redirect)｜[国信证券](https://mp.weixin.qq.com/s?__biz=Mzg3Njc2NDAwOA==&mid=2247537026&idx=1&sn=19a88be7610378cb0283f43e0563cb61&scene=21#wechat_redirect)｜[杭银消金](https://mp.weixin.qq.com/s?__biz=Mzg3Njc2NDAwOA==&mid=2247517678&idx=1&sn=2fa963e0cf8194ad8a027f2c108d5459&chksm=cf2f8be9f85802ffb84237297a0c2ec6efdf1266f9213ee028f46e7e6aad43e7f10042015095&scene=21&cur_album_id=2524165801138995201#wechat_redirect)｜[杭州银行](https://mp.weixin.qq.com/s?__biz=Mzg3Njc2NDAwOA==&mid=2247538893&idx=1&sn=5e1f2f644651111732316334170c1d93&scene=21#wechat_redirect)｜[河北幸福消费金融](https://mp.weixin.qq.com/s?__biz=Mzg3Njc2NDAwOA==&mid=2247522589&idx=1&sn=2c8e14756aa6727ef51da608dfb074f7&chksm=cf2f971af8581e0c2fdd887636a9844eef3b16c3c9832d9e62e1457cff641935db69832f885e&scene=21&cur_album_id=2524165801138995201#wechat_redirect)｜[河南农商银行](https://mp.weixin.qq.com/s?__biz=Mzg3Njc2NDAwOA==&mid=2247538801&idx=1&sn=147fb07c23c6b39720e82fb4a5d6a613&scene=21#wechat_redirect)｜[汇添富基金](http://mp.weixin.qq.com/s?__biz=Mzg3Njc2NDAwOA==&mid=2247532266&idx=1&sn=12b08c27cc55dd9e6074f565ddeb9378&chksm=cf2f70edf858f9fb7d19675a068a77b92bba293fba079e267cefcb46ae5ec452b646d7b69d93&scene=21#wechat_redirect)｜[金融壹账通](https://mp.weixin.qq.com/s?__biz=Mzg3Njc2NDAwOA==&mid=2247522120&idx=1&sn=32bfd0bec1a56c7ecea05c088e566cd1&chksm=cf2f994ff858105979a27bd768133ff2c663e3f7ed5f894e373d834a1e35e67b15ca15c2de6d&scene=21&cur_album_id=2524165801138995201#wechat_redirect)｜[陆金所控股](https://mp.weixin.qq.com/s?__biz=Mzg3Njc2NDAwOA==&mid=2247534403&idx=1&sn=a07c42af38ce146f75fbf3fc1a96f4ba&scene=21#wechat_redirect)｜[霖梓控股](https://mp.weixin.qq.com/s?__biz=Mzg3Njc2NDAwOA==&mid=2247535962&idx=1&sn=1d348942d631ebc15a1a4cb5b73b2177&scene=21#wechat_redirect)｜[拉卡拉](https://mp.weixin.qq.com/s?__biz=Mzg3Njc2NDAwOA==&mid=2247536412&idx=1&sn=099a0e58cfb6a49a444a6afa4268438b&scene=21#wechat_redirect)｜[某公安厅](https://mp.weixin.qq.com/s?__biz=Mzg3Njc2NDAwOA==&mid=2247539749&idx=1&sn=c90808e0bdd55841ed030eace7a6aed4&scene=21#wechat_redirect)｜[平安人寿](https://mp.weixin.qq.com/s?__biz=Mzg3Njc2NDAwOA==&mid=2247526035&idx=1&sn=ce723ff107a98a6d8887d45455c9e4c0&chksm=cf2f6894f858e182ab243f4e96ce9d675831802272f5e40915bf9c7edd8d36b0b022d9ec3ca1&scene=21&cur_album_id=2524165801138995201#wechat_redirect) | [Planet](https://mp.weixin.qq.com/s?__biz=Mzg3Njc2NDAwOA==&mid=2247537994&idx=1&sn=f9512a0127a6390067ffe2fdb3ab15df&scene=21#wechat_redirect)｜[奇富科技](http://mp.weixin.qq.com/s?__biz=Mzg3Njc2NDAwOA==&mid=2247526469&idx=1&sn=4b2d7748da1a3b601499d7d2d80748b2&chksm=cf2f6642f858ef54b7dc5b307ec4eaba7d867ee5ab5862b9e60274cc56940787686da30873fa&scene=21#wechat_redirect)｜[上海证券](https://mp.weixin.qq.com/s?__biz=Mzg3Njc2NDAwOA==&mid=2247537933&idx=1&sn=18d6800c56fdda9df28bcb17c82ff50b&scene=21#wechat_redirect) | [同程数科](https://mp.weixin.qq.com/s?__biz=Mzg3Njc2NDAwOA==&mid=2247521341&idx=1&sn=3e2b5ee81ebe6ba8b2a238e91ea7f7b7&chksm=cf2f9a3af858132c380332c123813f1df24169e30040363428db78cc0fef541f6ee802f2262d&scene=21&cur_album_id=2524165801138995201#wechat_redirect)｜[通联支付](http://mp.weixin.qq.com/s?__biz=Mzg3Njc2NDAwOA==&mid=2247532843&idx=1&sn=ec7c674e29a66dcb4a78ad24e9507bc2&chksm=cf2f4f2cf858c63a7953dbbe8893c2335bee15b0abe3d97d45725cfe80d9b35aa465f43d6264&scene=21#wechat_redirect)｜[泰康养老](https://mp.weixin.qq.com/s?__biz=Mzg3Njc2NDAwOA==&mid=2247535945&idx=1&sn=dc09452873e75a12341d46bbead62f28&scene=21#wechat_redirect)｜[无锡锡商银行](http://mp.weixin.qq.com/s?__biz=Mzg3Njc2NDAwOA==&mid=2247529958&idx=1&sn=e720bfefc8cc63148c3aa6ceeee69be6&chksm=cf2f7be1f858f2f75dfab49839eafeffeddb93c49851fc8ebdcbcfd788230f6d06b1be6ad9fb&scene=21#wechat_redirect)｜[星云零售信贷](https://mp.weixin.qq.com/s?__biz=Mzg3Njc2NDAwOA==&mid=2247522161&idx=1&sn=40862998ddead3c398c7765e1e8b57d8&chksm=cf2f9976f8581060f9cbf6e402f3a39d35e86a559f7d59c80b680d41977c6165e0f42cce8422&scene=21&cur_album_id=2524165801138995201#wechat_redirect)｜[星火保](http://mp.weixin.qq.com/s?__biz=Mzg3Njc2NDAwOA==&mid=2247532661&idx=1&sn=adba43453acddfdcf2f294f2e46727fc&chksm=cf2f4e72f858c76437d3dc998b712deb7841fb2d65c45e017aeb4f9e61e74e4ad710a5cd0df1&scene=21#wechat_redirect) | [宇信科技](https://mp.weixin.qq.com/s?__biz=Mzg3Njc2NDAwOA==&mid=2247537885&idx=1&sn=692aa93fd32b98a0c226b794eaaee4de&scene=21#wechat_redirect)｜[银联商务](http://mp.weixin.qq.com/s?__biz=Mzg3Njc2NDAwOA==&mid=2247526954&idx=1&sn=4dae0891ccbaae99146b5a6ba783f392&chksm=cf2f642df858ed3b939be0b04d264ddb0529556fe15ad70c3501af44d0026972cd1bef49a7b7&scene=21#wechat_redirect)｜[易生支付](http://mp.weixin.qq.com/s?__biz=Mzg3Njc2NDAwOA==&mid=2247532494&idx=1&sn=aec3c408890ce0b6fd802a7f7d7e2bd1&chksm=cf2f71c9f858f8dfff7ae63f7bd3b4b91bc2717f83824d3245afb8ebbc44b1be96cbe9403354&scene=21#wechat_redirect)｜[浙江头部银行](https://mp.weixin.qq.com/s?__biz=Mzg3Njc2NDAwOA==&mid=2247538744&idx=1&sn=dd12ef273efed43dcf987efb253ab470&scene=21#wechat_redirect)｜[招商信诺人寿](https://mp.weixin.qq.com/s?__biz=Mzg3Njc2NDAwOA==&mid=2247524176&idx=1&sn=19138ac93dd44f395d68745cf94d9a6b&chksm=cf2f9157f858184176169417464dce040cd89fab6b35099d8b76086342f9682c49fd8cc87582&scene=21&cur_album_id=2524165801138995201#wechat_redirect)｜[招联金融](http://mp.weixin.qq.com/s?__biz=Mzg3Njc2NDAwOA==&mid=2247533296&idx=1&sn=b94ffa477e3398afe94e38b66479bf57&chksm=cf2f4cf7f858c5e10f996f0634f967de6478eaa573a45f102502602e16e142397935d58205d5&scene=21#wechat_redirect)｜[中信银行信用卡中心](https://mp.weixin.qq.com/s?__biz=Mzg3Njc2NDAwOA==&mid=2247535858&idx=1&sn=8edeb10d97936a88b52543c2ac108288&scene=21#wechat_redirect)｜[中泰证券](https://mp.weixin.qq.com/s?__biz=Mzg3Njc2NDAwOA==&mid=2247536592&idx=1&sn=8b72e72c1df501d1b6b2a337b3ad090d&scene=21#wechat_redirect)｜[360 数科](https://mp.weixin.qq.com/s?__biz=Mzg3Njc2NDAwOA==&mid=2247509531&idx=1&sn=60f3b5160acf1f2e6df2f30242dc4306&chksm=cf2fa81cf858210abd2b7158c19b39dc1431cc9114b1f463d25586dafe8c60673992deda574a&token=2001517976&lang=zh_CN&scene=21#wechat_redirect)｜[360 企业安全浏览器](http://mp.weixin.qq.com/s?__biz=Mzg3Njc2NDAwOA==&mid=2247527814&idx=1&sn=f4b56af0fac8b465b40819cd080f7563&chksm=cf2f6381f858ea97d8121642b03ae99fe48cd8c5a514c18e571be235405a90397d25f243b624&scene=21#wechat_redirect)

**互联网与文娱****：**[菜鸟](https://mp.weixin.qq.com/s?__biz=Mzg3Njc2NDAwOA==&mid=2247537342&idx=1&sn=118685b9bfe9c0442e0bb1558718431f&scene=21#wechat_redirect)｜[抖音集团](http://mp.weixin.qq.com/s?__biz=Mzg3Njc2NDAwOA==&mid=2247530668&idx=1&sn=3ecfbb295fc4e3fd7617044ac3575543&chksm=cf2f76abf858ffbd0718c2102777dfbb914f07deb05bf6e07a663107f1d0f1897257ba02a131&scene=21#wechat_redirect)｜[斗鱼](https://mp.weixin.qq.com/s?__biz=Mzg3Njc2NDAwOA==&mid=2247517967&idx=1&sn=0896767aa1b7d1f0b314c22023e4de3c&chksm=cf2f8908f858001e935f7f0c1c8082847c31851dc27377652b57a8c6b3c4883890e0448eff27&scene=21&cur_album_id=2524165801138995201#wechat_redirect)｜[叮咚买菜](https://mp.weixin.qq.com/s?__biz=Mzg3Njc2NDAwOA==&mid=2247518311&idx=1&sn=d18e9d2be16c26833d4d3e03f5c2836b&chksm=cf2f8660f8580f7632c6211ede6d56a4a79531c95981c72dccc76948dd9f7afdb2c419db10db&scene=21&cur_album_id=2524165801138995201#wechat_redirect)|[浩瀚深度](https://mp.weixin.qq.com/s?__biz=Mzg3Njc2NDAwOA==&mid=2247537072&idx=1&sn=6b5f4fae6224b2535badfd29ba3c8ecb&scene=21#wechat_redirect)｜[京东](https://mp.weixin.qq.com/s?__biz=Mzg3Njc2NDAwOA==&mid=2247536067&idx=1&sn=6325bd6379241c56925cdfd0b748212e&scene=21#wechat_redirect)｜[工商信息查询平台](http://mp.weixin.qq.com/s?__biz=Mzg3Njc2NDAwOA==&mid=2247526281&idx=1&sn=a586ef0e7b8d1cc631cc08da63331dbc&chksm=cf2f698ef858e098407b107df2511260590c09f2629071fcc40f24632c92582304230cb7bf7f&scene=21#wechat_redirect)｜[货拉拉](https://mp.weixin.qq.com/s?__biz=Mzg3Njc2NDAwOA==&mid=2247538110&idx=1&sn=75a963d6982769aa43e5279dbf7af44a&scene=21#wechat_redirect)｜[快手](http://mp.weixin.qq.com/s?__biz=Mzg3Njc2NDAwOA==&mid=2247533822&idx=1&sn=36a3db48f30db59f05ff4313d205d146&chksm=cf2f4af9f858c3ef54b109d4fc465d6883a541b8b18adc23b0dcb15ca5e876201af2498cc811&scene=21#wechat_redirect)｜[荔枝微课](https://mp.weixin.qq.com/s?__biz=Mzg3Njc2NDAwOA==&mid=2247519304&idx=1&sn=6c59fae3838e1f02a29eebca1b5799e9&chksm=cf2f824ff8580b593720ebed5234490c9b4a00fa616218b2ee3f8e89beb95eab11c720022e91&scene=21&cur_album_id=2524165801138995201#wechat_redirect)｜[票务平台](https://mp.weixin.qq.com/s?__biz=Mzg3Njc2NDAwOA==&mid=2247521422&idx=1&sn=e42a6e93170f14bd17a48812f1e8ece4&chksm=cf2f9a89f858139f1ffa47678d3c4d068f44788ac18f288b1e31243bad0bfff1745b5763794c&scene=21&cur_album_id=2524165801138995201#wechat_redirect)｜[墨迹天气](http://mp.weixin.qq.com/s?__biz=Mzg3Njc2NDAwOA==&mid=2247530525&idx=1&sn=33ac4ce5192c12a8b19b6b18a344f718&chksm=cf2f761af858ff0c0c69f833e501ca52e0a5818a17e0fcc8c1d7f86d6b8d364b83b5ad6d2244&scene=21#wechat_redirect)｜[MiniMax](https://mp.weixin.qq.com/s?__biz=Mzg3Njc2NDAwOA==&mid=2247536310&idx=1&sn=8c2d8980a4c7b3f88421f1ed5f1d0eba&scene=21#wechat_redirect)｜[奇安信](https://mp.weixin.qq.com/s?__biz=Mzg3Njc2NDAwOA==&mid=2247524942&idx=1&sn=331f494035518da1875fca0fc9c5437a&chksm=cf2f6c49f858e55fd2ad0aa4a2f958b9b1b0f790441a519471debe217c38b6a5bde06ae46e87&scene=21&cur_album_id=2524165801138995201#wechat_redirect)｜[趣丸科技](http://mp.weixin.qq.com/s?__biz=Mzg3Njc2NDAwOA==&mid=2247530649&idx=1&sn=da6e4444e1e50b54ba640cc40385b33c&chksm=cf2f769ef858ff88bc36e0ef5e894b3898348123db2cc3d9d4d55b7b56e17e65402f09bc32a0&scene=21#wechat_redirect)｜[顺丰科技](https://mp.weixin.qq.com/s?__biz=Mzg3Njc2NDAwOA==&mid=2247536639&idx=1&sn=2f0cb56207b97a63aa5857dffac9ea83&scene=21#wechat_redirect)｜[腾讯音乐](http://mp.weixin.qq.com/s?__biz=Mzg3Njc2NDAwOA==&mid=2247533968&idx=1&sn=bd1f32f608c3ce648c12f5cf3365db8c&chksm=cf2f4b97f858c2811330a4247d40bfd404ea031cc0c4f2c7d5ae79309b204c13afe8d81ff1a4&scene=21#wechat_redirect)｜[天眼查](https://mp.weixin.qq.com/s?__biz=Mzg3Njc2NDAwOA==&mid=2247519778&idx=1&sn=e32c89396fc87a09965cc89b5e9e1b4b&chksm=cf2f8025f858093392bffd5619ba53be539a865128bcedd6e6094cf6e49082282cd7c3bc5298&scene=21&cur_album_id=2524165801138995201#wechat_redirect)｜[网易](http://mp.weixin.qq.com/s?__biz=Mzg3Njc2NDAwOA==&mid=2247529891&idx=1&sn=fbdc2154807b766bd4534522dc48295d&chksm=cf2f7ba4f858f2b26996ef3fc3564da96a632a81d4ae01500a77e58ef925cbdb14d6e22efdad&scene=21#wechat_redirect)｜[网易游戏](http://mp.weixin.qq.com/s?__biz=Mzg3Njc2NDAwOA==&mid=2247531491&idx=1&sn=bbff8938a6d08b6ead0a08e203709f01&chksm=cf2f75e4f858fcf2a6e4023e93aec4fd165af096388a6fa61906fa640b82ff4e60cd3d8a2641&scene=21#wechat_redirect)｜[网易严选](https://mp.weixin.qq.com/s?__biz=Mzg3Njc2NDAwOA==&mid=2247503369&idx=1&sn=29fab18c22f5778b0bb19409cb68f567&chksm=cf2fc00ef8584918fc809d661066f139d002f0202f2f6477a02286527409296d6212a373e58a&token=2001517976&lang=zh_CN&scene=21#wechat_redirect)｜[网易云信](https://mp.weixin.qq.com/s?__biz=Mzg3Njc2NDAwOA==&mid=2247536880&idx=1&sn=710229bd13e19f06216eb7211220a0ce&scene=21#wechat_redirect)｜[网易云音乐](https://mp.weixin.qq.com/s?__biz=Mzg3Njc2NDAwOA==&mid=2247535994&idx=1&sn=88d69524871d7b34191d2f2d778e78e6&scene=21#wechat_redirect)｜[小米](https://mp.weixin.qq.com/s?__biz=Mzg3Njc2NDAwOA==&mid=2247537383&idx=1&sn=47a4bc984bf6097a74b343e77ec4a86b&scene=21#wechat_redirect)｜[小鹅通](https://mp.weixin.qq.com/s?__biz=Mzg3Njc2NDAwOA==&mid=2247524553&idx=1&sn=63af19e32467049aa3b2fff79898c5ce&chksm=cf2f6ecef858e7d8dc3939f71ebef3bf17962e50889707b8393080a7e2ffca7520c814232bd7&scene=21&cur_album_id=2524165801138995201&poc_token=HCXDWmWjWHZ5_WrVJMWvScoFjGBJjOj_ZV5DcLPW#wechat_redirect)｜[迅雷](http://mp.weixin.qq.com/s?__biz=Mzg3Njc2NDAwOA==&mid=2247531772&idx=1&sn=3db2e0c4f8dec01085bd6e24d2c857b3&chksm=cf2f72fbf858fbed95f9aa74e103b76c828dd5433a0338e97354db4781974e9444a957e9adde&scene=21#wechat_redirect)｜[约苗](https://mp.weixin.qq.com/s?__biz=Mzg3Njc2NDAwOA==&mid=2247521201&idx=1&sn=dc8f3d55343cd054974e8c5f4bfe50a2&chksm=cf2f9db6f85814a055a245c88c5c5c138fb7b9a9bbacedfa39dae563726ae43ad237993a5872&scene=21&cur_album_id=2524165801138995201#wechat_redirect)｜[字节跳动](https://mp.weixin.qq.com/s?__biz=Mzg3Njc2NDAwOA==&mid=2247538610&idx=1&sn=138366ab0a8fc81e044232d9752baa34&scene=21#wechat_redirect)｜[知乎](https://mp.weixin.qq.com/s?__biz=Mzg3Njc2NDAwOA==&mid=2247520797&idx=1&sn=1fd8394aafaddbd0ab0fbfc322e5fb25&chksm=cf2f9c1af858150c4ef3e2d9b5762477584d3e0908d71ab8871b81061253343e689c6aa18ac0&scene=21&cur_album_id=2524165801138995201#wechat_redirect)｜[360 商业化](https://mp.weixin.qq.com/s?__biz=Mzg3Njc2NDAwOA==&mid=2247518769&idx=1&sn=60b5ac3a78930baddc845f1e6c66a29c&chksm=cf2f8436f8580d201bacec5b3434ee62b2fea52718c4b82355c8e8c698fc2d4228a2b0cc0bef&token=2001517976&lang=zh_CN&scene=21#wechat_redirect)

**企业服务与新经济****：**[宝尊科技](https://mp.weixin.qq.com/s?__biz=Mzg3Njc2NDAwOA==&mid=2247536183&idx=1&sn=d4ddeaf5a8ebbb284b5207c62ea50c40&scene=21#wechat_redirect)| [波司登](https://mp.weixin.qq.com/s?__biz=Mzg3Njc2NDAwOA==&mid=2247537544&idx=1&sn=049172879eeb986d6c67a0a2472bbdd2&scene=21#wechat_redirect)｜[Cisco](https://mp.weixin.qq.com/s?__biz=Mzg3Njc2NDAwOA==&mid=2247535303&idx=1&sn=3a57e0de6153d6715e5d19f1f3ff0717&scene=21#wechat_redirect)｜[橙联](https://mp.weixin.qq.com/s?__biz=Mzg3Njc2NDAwOA==&mid=2247507345&idx=1&sn=4dc83cae32333c2aa2355c9447ecfb81&chksm=cf2fd396f8585a8018f753f50d89f6bbbb607c86350bf49957bbc07894477b88a61f3eba9342&scene=21&cur_album_id=2524165801138995201#wechat_redirect)｜[度言](https://mp.weixin.qq.com/s?__biz=Mzg3Njc2NDAwOA==&mid=2247512880&idx=1&sn=9b3adbddb44b7287835adf560a56e65b&chksm=cf2fbd37f8583421316ef89513c84654956b8d9e2231868613ce4c9ad439127bb5a8a4077b73&token=2001517976&lang=zh_CN&scene=21#wechat_redirect)｜[观测云](http://mp.weixin.qq.com/s?__biz=Mzg3Njc2NDAwOA==&mid=2247526244&idx=1&sn=af3b3bc7a5d5419d003ada6b9ea9c376&chksm=cf2f6963f858e0758e623e16612bceae95457c6d7aeed918be6d0d5bd53e8962d14549b64de0&scene=21#wechat_redirect)｜[慧策](https://mp.weixin.qq.com/s?__biz=Mzg3Njc2NDAwOA==&mid=2247515310&idx=1&sn=abfa22039b546171dd6cb1ead692de0f&chksm=cf2fb2a9f8583bbff034fc5824f89bf6a1d960a1f7997f3c3fc42af27b271c76d28aecf4b522&scene=21&cur_album_id=2524165801138995201#wechat_redirect)｜[快成物流](http://mp.weixin.qq.com/s?__biz=Mzg3Njc2NDAwOA==&mid=2247531733&idx=1&sn=53e4df3ca765685dcc2b429db833a64d&chksm=cf2f72d2f858fbc4e5ccc99ea75262b6903467c9c3ea3e66919a587545fe1ea01cd7b2fd3b62&scene=21#wechat_redirect)｜[领健](https://mp.weixin.qq.com/s?__biz=Mzg3Njc2NDAwOA==&mid=2247512380&idx=1&sn=e7bb6b39a71b2a350acd7ac8d2f3b202&chksm=cf2fbf3bf858362d4e4326712e9d360493c2660e5d619e0c7ec23383b560bea2f0644b10c84f&scene=21&cur_album_id=2524165801138995201#wechat_redirect)｜[领创](https://mp.weixin.qq.com/s?__biz=Mzg3Njc2NDAwOA==&mid=2247538208&idx=1&sn=0ba989f9a6000ad44416c6941db42dbb&scene=21#wechat_redirect)｜[灵犀科技](https://mp.weixin.qq.com/s?__biz=Mzg3Njc2NDAwOA==&mid=2247535808&idx=1&sn=142386b7a74856d424676f79b281d07a&scene=21#wechat_redirect)｜[名创优品](http://mp.weixin.qq.com/s?__biz=Mzg3Njc2NDAwOA==&mid=2247529981&idx=1&sn=85ba7efaa7c947573d59d87ae4897cc4&chksm=cf2f7bfaf858f2ec757fe383ec0bd4053bdfb09c09197fa1587c36d8c3947394d6621116341a&scene=21#wechat_redirect)｜[Moka BI](https://mp.weixin.qq.com/s?__biz=Mzg3Njc2NDAwOA==&mid=2247518538&idx=1&sn=d9a39d040c9f430a841a2045a2bafb90&chksm=cf2f874df8580e5b0d77c6235aadd8610c80b4afd1c2781172ba6e1fb734dbb6e463d6f8794e&scene=21&cur_album_id=2524165801138995201#wechat_redirect)｜[美联物业](https://mp.weixin.qq.com/s?__biz=Mzg3Njc2NDAwOA==&mid=2247517792&idx=1&sn=455c085a102c7af1fcac44e62bc06ca1&chksm=cf2f8867f8580171c05af38785d7c7a32766308df46f482f7731cdc0d3dc76d9ed0a69b864f2&token=2001517976&lang=zh_CN&scene=21#wechat_redirect)｜[麦当劳](https://mp.weixin.qq.com/s?__biz=Mzg3Njc2NDAwOA==&mid=2247536949&idx=1&sn=011fc3bb018594daa972da2f6d0c42e9&scene=21#wechat_redirect)｜[钱大妈](http://mp.weixin.qq.com/s?__biz=Mzg3Njc2NDAwOA==&mid=2247529314&idx=1&sn=e1564a7bc1184ba73c353c465eae503d&chksm=cf2f7d65f858f473f71cad992eb80cdf095cb873fe2394c6a2deab07ecbd12aae6eb5de72a60&scene=21#wechat_redirect)｜[拈花云科](https://mp.weixin.qq.com/s?__biz=Mzg3Njc2NDAwOA==&mid=2247522076&idx=1&sn=c2b2b0f72e9bc25b9020238048a3c6ae&chksm=cf2f991bf858100dfdacf18748ef75a4e76e6cbf34e8b1e52ffc55232e6f6db0ae6c4d9b1b69&scene=21&cur_album_id=2524165801138995201#wechat_redirect)｜[森马](https://mp.weixin.qq.com/s?__biz=Mzg3Njc2NDAwOA==&mid=2247536942&idx=1&sn=aeb684eaa379dbb4d910d9fefc678ccd&scene=21#wechat_redirect) |[思必驰](https://mp.weixin.qq.com/s?__biz=Mzg3Njc2NDAwOA==&mid=2247539634&idx=1&sn=845bcf9b685b232387d8b52f5064e544&scene=21#wechat_redirect)｜[顺丰科技](https://mp.weixin.qq.com/s?__biz=Mzg3Njc2NDAwOA==&mid=2247536639&idx=1&sn=2f0cb56207b97a63aa5857dffac9ea83&scene=21#wechat_redirect)｜[上海家化](http://mp.weixin.qq.com/s?__biz=Mzg3Njc2NDAwOA==&mid=2247529885&idx=1&sn=b7c4ae401c29dfa64d10097a2ae3c678&chksm=cf2f7b9af858f28c309136b6a68ede29631849dceba2b84d180b07cd04d02937c940c74975ae&scene=21#wechat_redirect) | [物易云通](https://mp.weixin.qq.com/s?__biz=Mzg3Njc2NDAwOA==&mid=2247490382&idx=1&sn=531f8d388526ee57aff6e86c8befe66c&scene=21#wechat_redirect)｜[云积互动](https://mp.weixin.qq.com/s?__biz=Mzg3Njc2NDAwOA==&mid=2247508739&idx=1&sn=52d028e91f9fa9cf4e93036970711eed&chksm=cf2fad04f8582412ec4cfd3c7a4a672326652c0062a481eda98a704ec245a878f5246ad236bc&scene=21&cur_album_id=2524165801138995201#wechat_redirect)｜[有赞](https://mp.weixin.qq.com/s?__biz=Mzg3Njc2NDAwOA==&mid=2247524089&idx=1&sn=95b479a8648809456100e121677fb29d&chksm=cf2f90fef85819e8e73021e841d396ad1cc44e002bff0002c1b431741b3790a775415b829bf8&scene=21&cur_album_id=2524165801138995201#wechat_redirect)｜[雨润集团](http://mp.weixin.qq.com/s?__biz=Mzg3Njc2NDAwOA==&mid=2247532231&idx=1&sn=ff3913472ee157907f40e174ddf370bd&chksm=cf2f70c0f858f9d69c4f195e01df934a28149797aacaffb8382d0883c7fb07dcf5a861aa239c&scene=21#wechat_redirect)｜[纵腾集团](https://mp.weixin.qq.com/s?__biz=Mzg3Njc2NDAwOA==&mid=2247513813&idx=1&sn=348def05d3f82fc3e7b119a78b3c2b84&chksm=cf2fb8d2f85831c45349ea5a3e4b6c27503aa41f783903a856b915a6556b3d4c81691fb24a7c&scene=21&cur_album_id=2524165801138995201#wechat_redirect)｜[中通快递](https://mp.weixin.qq.com/s?__biz=Mzg3Njc2NDAwOA==&mid=2247538817&idx=1&sn=3615bc2a9142bd722d1c208f0e779cb3&scene=21#wechat_redirect)

**先进智造与电信****：**[爱玛](http://mp.weixin.qq.com/s?__biz=Mzg3Njc2NDAwOA==&mid=2247529522&idx=1&sn=95d61e4fea493b667612a946ed126b2d&chksm=cf2f7a35f858f323918bfa574f60d3c8af817c60c6e1680f0b639533528fce3183e60ac90e95&scene=21#wechat_redirect)｜[长安汽车](https://mp.weixin.qq.com/s?__biz=Mzg3Njc2NDAwOA==&mid=2247526078&idx=1&sn=55ac5982a5a81eb98d380cdca2fe4a1f&chksm=cf2f68b9f858e1af4f53a4eeb489516d2508f513435f9c82b50896acce8cbe522f165034ce9f&scene=21&cur_album_id=2524165801138995201#wechat_redirect)[｜](https://mp.weixin.qq.com/s?__biz=Mzg3Njc2NDAwOA==&mid=2247526078&idx=1&sn=55ac5982a5a81eb98d380cdca2fe4a1f&chksm=cf2f68b9f858e1af4f53a4eeb489516d2508f513435f9c82b50896acce8cbe522f165034ce9f&scene=21&cur_album_id=2524165801138995201#wechat_redirect)[海信集团](https://mp.weixin.qq.com/s?__biz=Mzg3Njc2NDAwOA==&mid=2247538992&idx=1&sn=9a9794465ba2598845371d0788dfccd7&scene=21#wechat_redirect)｜[恒瑞医药](https://mp.weixin.qq.com/s?__biz=Mzg3Njc2NDAwOA==&mid=2247539656&idx=1&sn=b752a0eca85fb808281acee92479b4d7&scene=21#wechat_redirect)｜[极越汽车](http://mp.weixin.qq.com/s?__biz=Mzg3Njc2NDAwOA==&mid=2247530634&idx=1&sn=b02e765afeefbe7eb709260ec5127031&chksm=cf2f768df858ff9b78f0e61907bf86ef319c7d03e6eddc116c0da70713bb853e3301da160148&scene=21#wechat_redirect)｜[金风科技](https://mp.weixin.qq.com/s?__biz=Mzg3Njc2NDAwOA==&mid=2247533704&idx=1&sn=f1c619e15f318e58ad70befd0e70fc91&scene=21#wechat_redirect)｜[科大讯飞](http://mp.weixin.qq.com/s?__biz=Mzg3Njc2NDAwOA==&mid=2247534327&idx=1&sn=60c35720f3f412db6a78079815acc592&chksm=cf2f48f0f858c1e6f7ca4b881ed20e60c0aba8554972514674e291e26face6586fc96413e2e9&scene=21#wechat_redirect)｜[岚图汽车](https://mp.weixin.qq.com/s?__biz=Mzg3Njc2NDAwOA==&mid=2247537812&idx=1&sn=dba5ebde479749f8ba74409e6a93c2e4&scene=21#wechat_redirect)｜[Lifewit](https://mp.weixin.qq.com/s?__biz=Mzg3Njc2NDAwOA==&mid=2247487975&idx=1&sn=0cfd5f9d748cb982e1ff5abc35fddb9a&chksm=cf2c1fe0f85b96f652975a5f88a9ca85d6ef75e55427dda02126d34f06d2e2a3ac15bda56413&token=2145458351&lang=zh_CN&scene=21#wechat_redirect)｜[哪吒科技](http://mp.weixin.qq.com/s?__biz=Mzg3Njc2NDAwOA==&mid=2247531497&idx=1&sn=473ea00ef53c0bd902968446e8b0e6e4&chksm=cf2f75eef858fcf850ab57e1c28d5fbfc81aa369c865c1153105b9d8e4a61d910a739634686d&scene=21#wechat_redirect)｜[四川航空](https://mp.weixin.qq.com/s?__biz=Mzg3Njc2NDAwOA==&mid=2247536110&idx=1&sn=86a18fe553ddc620be30173c663101e4&scene=21#wechat_redirect)｜[上汽通用五菱](https://mp.weixin.qq.com/s?__biz=Mzg3Njc2NDAwOA==&mid=2247530723&idx=1&sn=47c5c9d104566b638cb09e9d0ab3f448&scene=21#wechat_redirect)｜[三星电子](http://mp.weixin.qq.com/s?__biz=Mzg3Njc2NDAwOA==&mid=2247533303&idx=1&sn=5b8a674e5ab8fbc2a9d2d462e1527a32&chksm=cf2f4cf0f858c5e689ecebf5c2f2a60681926946038f3be3ffddc11bfb29b256c158870b1ee5&scene=21#wechat_redirect)｜[蜀海供应链](https://mp.weixin.qq.com/s?__biz=Mzg3Njc2NDAwOA==&mid=2247496660&idx=1&sn=1c0738a95564fc4cebb8a56cb539f703&scene=21#wechat_redirect)｜[赢家服饰](https://mp.weixin.qq.com/s?__biz=Mzg3Njc2NDAwOA==&mid=2247539117&idx=1&sn=2701e867a53a7ff1925c7e72fc3d3b1f&scene=21#wechat_redirect)｜[特步](https://mp.weixin.qq.com/s?__biz=Mzg3Njc2NDAwOA==&mid=2247535841&idx=1&sn=7a0a2851555bdd5f340bb3aa640fc61c&scene=21#wechat_redirect)｜[天翼云](https://mp.weixin.qq.com/s?__biz=Mzg3Njc2NDAwOA==&mid=2247538931&idx=1&sn=4287ccc0bbbf7a0a4a05df810ed91e98&scene=21#wechat_redirect)｜[雅迪](http://mp.weixin.qq.com/s?__biz=Mzg3Njc2NDAwOA==&mid=2247532027&idx=1&sn=d4de3a3326c1450b063d017aaaa78506&chksm=cf2f73fcf858faea620ba48c0b78b3746485a74fd5f1d29482b0dbed3cbd6d374ecc17cd2453&scene=21#wechat_redirect)｜[中国联通](https://mp.weixin.qq.com/s?__biz=Mzg3Njc2NDAwOA==&mid=2247523168&idx=1&sn=f6a8195d485b56438a4413ca05c9a5e7&chksm=cf2f9567f8581c71f476c52f89de7e4e6769d17e232c8930e257d2db71a45b9ab83a50382655&scene=21&cur_album_id=2524165801138995201#wechat_redirect)

作为基于 Apache Doris 的商业化公司，飞轮科技秉承着 “开源技术创新”和“实时数仓服务”双轮驱动的战略，在投入资源大力参与 Apache Doris 社区研发和推广的同时，基于 Apache Doris 内核打造了聚焦于企业大数据实时分析需求的企业级产品 SelectDB ，面向新一代需求打造世界领先的实时分析能力。自 2022 年成立以来，获得 IDG 资本、红杉中国、襄禾资本等顶级 VC 的近 10 亿元融资，创下了近年来开源基础软件领域的新纪录。

---
原文链接：https://mp.weixin.qq.com/s?__biz=Mzg3Njc2NDAwOA%3D%3D&mid=2247539999&idx=1&sn=b9a6c2d46d3ae60d73cc812d54a7fcba&chksm=ce79226808f57b5bac2eb50bdf1d31d006c15200278f5bb9c2fda9e0acac1fe5473e1db53685
