---
source_url: "https://mp.weixin.qq.com/s?__biz=MzUyOTk0MDI1Nw%3D%3D&mid=2247484160&idx=1&sn=39ff703bc4c179e3a32d25e145a5af1e&chksm=fa58294ecd2fa0585e596b45ba9f4ea83cc47e201a447368d24efca8bb092b52cb9c9a25e177"
title: "给 AI 助手装上本地知识库大脑：QMD 语义搜索全工具接入教程（Hermes、Claude、Codex、Cursor 都能用）"
account: "你那个会AI的朋友"
published_at: "2026-08-24 09:11:00"
saved_at: "2026-08-24 12:50:40"
sync_id: "art_1bfa61d3bca5408188bd3e29cacbb8ad"
parse_status: "ok"
---

# 给 AI 助手装上本地知识库大脑：QMD 语义搜索全工具接入教程（Hermes、Claude、Codex、Cursor 都能用）

> 大家好， 我是大鹏。是「你那个会AI的朋友」，关注我，我会把最实用的AI技巧讲给你听~ 🌹

> 适合谁：笔记/文档越攒越多、靠文件名和关键词翻找越来越痛苦，想让 AI 助手能直接"读懂"你的知识库的个人用户。全程本地运行，不花一分钱。
> 先说清楚：本文命令与配置均核验自 **QMD 官方 GitHub README（tobi/qmd）** 与 **Hermes 官方文档 Qmd 技能页**，核验时间 **2026-08-07**。模型体积约 2GB、首次冷启动较慢，介意的话先看「七、避坑提醒」。

你有没有这种感觉：笔记软件里存了几百篇文档，真到要用的时候，**搜出来的永远不是想要的那篇**？

关键词对不上、标题没起好、内容里有但文件名没有——传统搜索就抓瞎了。今天介绍一个开源工具 **QMD**，配合 AI 助手（以 Hermes 为例）搭一套**完全本地**的知识库语义搜索：你问"我之前写过竞品定价的分析吗"，它直接给你翻出那篇笔记，哪怕标题里根本没有"竞品"两个字。

## 一、先说结论：QMD 是什么？为什么值得装？

**QMD（Query Markup Documents）** 是一个运行在你电脑上的本地搜索引擎，专为个人知识库设计。它把 Markdown 笔记、会议记录、文档、甚至任意文本文件**索引**起来，然后用三种方式组合搜索：关键词、语义、AI 重排。

| 对比项 | QMD 本地搜索 | 软件自带搜索 | 云端 RAG 服务 |
| --- | --- | --- | --- |
| 费用 | ‎ ** 0 元，开源免费 ** | 免费但弱 | 按 token 收费 |
| 隐私 | ‎ ** 完全本地，数据不出电脑 ** | 本地 | 笔记上传云端 |
| 中文语义理解 | ✅ 支持（可换多语言 Embedding 模型） | ❌ 只能关键词匹配 | ✅ |
| 搜索质量 | 关键词+语义+重排，三合一 | 只能按文件名/正文匹配 | 高 |
| 依赖 | 本地 GGUF 模型（~2GB） | 无 | 需联网 |

**三个关键词解释清楚 QMD 的核心：**

- ‎ Embedding（向量嵌入） ——把一段文字转成一串数字坐标，"苹果"和"水果"的距离比"苹果"和"汽车"近。这就是语义搜索的基础。
- ‎ BM25 ——传统关键词打分算法，搜代码变量名、专有名词这类精确内容又快又准。
- ‎ 重排（Reranking） ——先用前两者粗筛出候选，再用一个小型 AI 模型给结果重新打分排序，保证最相关的排最前面。

**为什么各家 AI 工具都能用？** QMD 本身是一个**本地搜索引擎 + 标准 MCP 服务器**（MCP 是 Anthropic 推出的开放协议，现在主流 AI 工具几乎全部原生支持），所以它不绑定任何一家—— **配一次，全家桶共享同一个索引**：

| AI 工具（Harness） | 接入方式 | 官方支持度 |
| --- | --- | --- |
| ‎ ** Hermes Agent ** | ‎  `hermes skills install official/research/qmd`  或 MCP 接入 | ✅ ** Hermes 官方技能页钦定 ** （Nous 官方维护） |
| ‎ ** Claude Desktop ** | ‎  `claude_desktop_config.json`  加 ‎  `mcpServers.qmd`  | ✅ README 官方示例 |
| ‎ ** Claude Code ** | ‎  `claude plugin marketplace add tobi/qmd`  + ‎  `claude plugin install qmd@qmd`  | ✅ README 官方插件（最顺滑） |
| ‎ ** Codex CLI ** | ‎  `~/.codex/config.toml`  的 ‎  `[mcp_servers]`  段 | ✅ Codex 原生 MCP |
| ‎ ** Cursor / Cline ** | 各自的 MCP 设置面板，JSON 形状与 Claude 相同 | ✅ |
| ‎ ** Cherry Studio ** | 设置 → MCP 服务器 → 添加 stdio 服务，命令填 ‎  `qmd`  、参数填 ‎  `mcp`  | ✅ 通用 MCP 客户端 |
| ‎ ** Zed / VS Code ** | MCP 客户端 + ‎  `QMD_EDITOR_URI`  跳转 | ✅ 官方支持 |
| ... |  |  |

一个索引，多家共用，结构示意：

```
         ┌─── Claude Desktop ──┐
         │                     │
 你的笔记库 ── QMD 索引 ──┼─── Codex CLI ─────┤
 (本地目录)   (只建一份)  ├─── Cursor ────────┤
         │                     │
         └─── Hermes / Cherry Studio ──┘
```

> 也就是说：**建一次索引，Claude、Codex、Cursor、Hermes 都能搜你的知识库**，不用每家各建一遍。下面教程以 Hermes 为主展开（它给 QMD 做了官方技能，接入最规范），其他工具的配置方法在「六」里一并给出。

## 二、它怎么工作？（30 秒看懂管道）

```
你的提问 "我之前分析过竞品定价吗？"
        │
        ▼
① 查询扩展：小模型把问题改写成 2 个变体（原问题权重×2）
        │
        ▼
② 并行检索：BM25 关键词搜索 + Embedding 语义搜索 同时跑
        │
        ▼
③ 融合排序：RRF 算法合并两路结果，前几名加分
        │
        ▼
④ LLM 重排：qwen3-reranker 给 Top 30 候选逐条打分 0~1
        │
        ▼
⑤ 位置感知混合：前 3 名信检索 75%、之后逐步加重重排权重
        │
        ▼
输出：最相关的那篇笔记 + 原文
```

（这是官方文档对检索管线的描述，通俗翻译：**先关键词和语义各捞一遍，再让 AI 精排**。）

## 三、环境要求与安装（3 分钟）

### 1. 检查 Node.js

QMD 要求 **Node.js ≥ 22**（或 Bun ≥ 1.0）。检查：

```
node --version
```

- 低于 22 → 去 nodejs.org 下载 LTS 版重装
- 本机实测：Node v24，✅ 满足

### 2. 安装 QMD

```
npm install -g @tobilu/qmd
```

> 国内网络慢的话，先设置 npm 镜像再装：
>

```
npm config set registry https://registry.npmmirror.com
```

### 3. 验证安装

```
qmd --version
qmd status
```

**首次运行会自动下载 3 个本地模型（约 2GB，一次性）**：

| 模型 | 用途 | 大小 |
| --- | --- | --- |
| ‎  `embeddinggemma-300M-Q8_0`  | 向量嵌入（默认） | ~300MB |
| ‎  `qwen3-reranker-0.6b-q8_0`  | 结果重排 | ~640MB |
| ‎  `qmd-query-expansion-1.7B`  | 查询扩展（微调模型） | ~1.1GB |

> ⚠️ 下载源是 HuggingFace，国内可能需要代理。下载到本地缓存后离线可用。

## 四、建立你的知识库索引（核心步骤）

### 第 1 步：添加文档目录（Collection）

把你的笔记目录"登记"给 QMD，每个目录一个名字：

```
# 添加 Obsidian 仓库为例
qmd collection add "D:\Users\invitop\Documents\DevinStoreHouse" --name vault

# 其他例子
qmd collection add ~/notes --name notes
qmd collection add ~/Documents/meetings --name meetings

# 查看已添加的目录
qmd collection list
```

### 第 2 步：给每个目录加上下文说明（强烈建议！）

这是 QMD 的**关键特性**：给目录写一句"这是放什么的"，搜索时 AI 能据此做更好的上下文判断，检索质量提升明显：

```
qmd context add qmd://vault "个人知识库：电商工作笔记、公众号文章、项目复盘"
qmd context add qmd://meetings "会议记录与行动项"
```

### 第 3 步：生成 Embedding 向量

```
qmd embed
```

这会把所有文档切成块（官方策略：约 900 tokens 一块、15% 重叠、代码块不切断），逐块生成向量。**之后每新增/修改文档，都要重新跑一遍**（或加  `-f`  强制全量重建）。

### 第 4 步：检查索引健康

```
qmd status
```

会显示索引健康度、各目录文档数、模型信息。

## 五、三种搜索方式，怎么选？（含实测性能）

| 命令 | 原理 | 速度（官方基准） | 适合场景 |
| --- | --- | --- | --- |
| ‎  `qmd search "关键词"`  | BM25 纯关键词 | ‎ ** ~0.2s ** | 搜代码变量名、专有名词、精确短语 |
| ‎  `qmd vsearch "自然语言"`  | 语义向量 | ‎ ** ~3s ** | 概念型问题："关于定价策略的笔记" |
| ‎  `qmd query "自然语言"`  | 混合+重排（质量最高） | 2-3s 热 / ** ~19s 冷 ** | 重要问题，要最好结果 |

**实战示例：**

```
# 精确关键词（快，不需要加载模型）
qmd search "Miro 净化器"

# 语义搜索（它不认识"打品"也能找到相关笔记）
qmd vsearch "竞品定价分析"

# 混合+重排（最推荐）
qmd query "我之前总结过哪些免费 AI API 的用法？"

# 指定只在某个目录里搜
qmd query "退换货政策" --collection vault

# 取出结果原文
qmd get "报告/竞品分析-202607.md" --full
qmd multi-get "报告/2026-07*.md" --json
```

**高级玩法——组合检索**（同一句话里混用关键词和语义）：

```
qmd query $'lex: 补单表 \n vec: 订单统计里哪些要剔除'
```

第一行是精确关键词、第二行是语义理解，两路结果合并排序。**注意：第一路权重×2，把最有把握的放前面。**

## 六、接入 Hermes（重点！两种方式）

### 方式 A：安装官方技能（最简单）

```
hermes skills install official/research/qmd
```

装完 Hermes 就知道怎么用 QMD 了——你直接对它说"搜一下我的笔记里关于 X 的内容"，它就会调  `qmd query`  帮你搜。（触发词：搜笔记、知识库、语义搜索。）

### 方式 B：MCP 接入（推荐，功能更强）

MCP（模型上下文协议）让 Hermes 把 QMD 的搜索能力变成**原生工具**，不用每次加载技能。

**B1. 简单模式（stdio，即用即起）：**

编辑  `~/.hermes/config.yaml` ，加入：

```
mcp_servers:
  qmd:
    command: "qmd"
    args: ["mcp"]
    timeout: 30
    connect_timeout: 45
```

注册后 Hermes 自动获得 5 个工具： `mcp_qmd_search` 、 `mcp_qmd_vsearch` 、 `mcp_qmd_deep_search` 、 `mcp_qmd_get` 、 `mcp_qmd_status` 。

> 代价：首次搜索要加载模型（约 19s 冷启动），之后本次会话内保持热状态。

**B2. 常驻模式（HTTP Daemon，重度用户推荐）：**

先把 QMD 作为后台服务启动，模型常驻内存，每次搜索 2-3 秒：

```
qmd mcp --http --daemon
# 默认监听 http://localhost:8181
```

然后 config.yaml 改成连 HTTP：

```
mcp_servers:
  qmd:
    url: "http://localhost:8181/mcp"
    timeout: 30
```

> 代价：常驻占用约 **2GB 内存**，适合经常搜索知识库的用户；偶尔用的话 B1 就够了。
> Windows 开机自启：把  `qmd mcp --http --daemon`  做成一个 .bat 放进「启动」文件夹，或用任务计划程序即可。

**接好之后的效果：** 你问 Hermes"帮我查下 7 月竞品调价相关的笔记"，它会自动调  `mcp_qmd_deep_search` ，从你的知识库里找到相关文档并引用原文回答—— **你的 AI 助手从此"记得"你写过的所有东西**。

### 其他 AI 工具怎么接？（同一套索引，无需重建）

**① Claude Desktop** — 编辑配置文件  `claude_desktop_config.json` ：

```
{
  "mcpServers": {
    "qmd": { "command": "qmd", "args": ["mcp"] }
  }
}
```

**② Claude Code** — 官方插件一键装（最顺滑）：

```
claude plugin marketplace add tobi/qmd
claude plugin install qmd@qmd
```

**③ Codex CLI** — 编辑  `~/.codex/config.toml` ：

```
[mcp_servers.qmd]
command = "qmd"
args = ["mcp"]
```

**④ Cursor / Cline** — 设置面板 → MCP 服务器 → 添加，JSON 形状和 Claude Desktop 一样（stdio，命令  `qmd` 、参数  `mcp` ）。

**⑤ Cherry Studio** — 设置 → MCP 服务器 → 添加服务器：类型选 stdio，命令填  `qmd` ，参数填  `mcp` 。

**⑥ Zed / VS Code** — 走各自 MCP 客户端配置，同样一段 JSON；另外可设  `QMD_EDITOR_URI`  环境变量，让搜索结果支持点击跳转到编辑器原文位置。

> 重要：**索引是共享的**。只要 QMD 装过一次、索引建过一次（第四章流程），上面所有工具接入后搜的都是同一份索引，不用每家重新 embed。

## 七、避坑提醒（重要！）

- ‎ 首次下载约 2GB 模型 ：来自 HuggingFace，国内网络可能需要代理；下载一次，之后完全离线可用。
- ‎ 冷启动慢（~19s）是正常的 ：模型没加载时的首查延迟。常用就上 HTTP Daemon 模式，或先用 ‎  `qmd search`  （BM25 不需要模型）。
- ‎ 中文语义搜索 ：默认 Embedding 模型对中文效果一般，官方文档明确支持通过环境变量换成多语言模型：

```
# Windows PowerShell
setx QMD_EMBED_MODEL "你的多语言embedding模型名"
# 换模型后必须重新生成向量：qmd embed -f
```

- ‎ 新增文档记得重新 ‎  `qmd embed`  ：索引不会自动更新，这是最常见的"搜不到新内容"原因。
- ‎ Windows GPU 注意 ：官方文档提示 Windows CUDA 并行上下文可能崩溃（‎  `ggml-cuda.cu:98`  ），默认单并行；驱动不稳定就设 ‎  `QMD_FORCE_CPU=1`  纯 CPU 跑（慢但稳）。
- ‎ macOS 用户 ：需先 ‎  `brew install sqlite`  （系统自带 SQLite 不支持扩展加载），Windows/Linux 无需此步。
- ‎ 隐私边界 ：QMD 完全本地，数据不出电脑——但也意味着它只能搜你 明确添加过的目录 ，云端协作文档不在范围内。

## 八、实际应用场景

- ‎ Obsidian 仓库秒变可问答知识库 ：几百篇笔记，用自然语言"我之前分析过 XX 吗？"直接命中
- ‎ 电商工作流 ：订单统计口径、补单表规则、竞品分析报告——问一句"有效订单的定义是什么"，立刻翻出当时的笔记原文
- ‎ 会议记录检索 ：散落在各月的会议纪要，按"上次讨论到哪了"这类问题语义检索
- ‎ 公众号选题查重 ：写文章前先搜"这个主题我写过没"，避免重复
- ‎ 多 AI 助手共享一套索引 ：QMD 的索引（‎  `~/.cache/qmd/index.sqlite`  ）是共享的，配一次，Claude、Codex、Cursor、Hermes 都能搜同一个知识库，不用每家各建一遍

## 九、结语

QMD 把"本地知识库语义搜索"这件事做到了开箱即用：**一个 npm 命令装好，三个命令建立索引，AI 助手立刻多了一个"读过你所有笔记"的能力**。配合 Hermes 官方技能/MCP 接入，就是一套完全本地、零成本、隐私无忧的个人 RAG 方案。

动心的话，现在就可以： `npm install -g @tobilu/qmd`  → 添加你的 Obsidian 目录 →  `qmd embed`  → 问 Hermes 一个问题试试。

---
原文链接：https://mp.weixin.qq.com/s?__biz=MzUyOTk0MDI1Nw%3D%3D&mid=2247484160&idx=1&sn=39ff703bc4c179e3a32d25e145a5af1e&chksm=fa58294ecd2fa0585e596b45ba9f4ea83cc47e201a447368d24efca8bb092b52cb9c9a25e177
