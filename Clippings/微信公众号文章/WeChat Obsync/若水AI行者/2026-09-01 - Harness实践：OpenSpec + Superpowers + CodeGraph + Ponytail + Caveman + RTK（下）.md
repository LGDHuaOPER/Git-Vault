---
source_url: "https://mp.weixin.qq.com/s?__biz=MzA3OTQwNDAxMw%3D%3D&mid=2247483669&idx=1&sn=d88fcaeefd96e68ff923295c72f36d83&chksm=9fb54f97a8c2c68192cb12cbc4ec8e82159b87539f9b95588a7c86750c6742eb25442807febb"
title: "Harness实践：OpenSpec + Superpowers + CodeGraph + Ponytail + Caveman + RTK（下）"
account: "若水AI行者"
published_at: "2026-09-01 11:52:04"
saved_at: "2026-09-18 18:28:28"
sync_id: "art_8ecb5d11429d4b1a869078948b80b3a2"
parse_status: "ok"
---

# Harness实践：OpenSpec + Superpowers + CodeGraph + Ponytail + Caveman + RTK（下）

## 三、整合成一套 Harness：Comet + CodeGraph + Ponytail + Caveman + RTK

### 3.1 分层原则

七个项目，为什么最后是五件套？因为 OpenSpec 和 Superpowers 在 Classic 里属于 Comet 的配套能力，Native 压根不依赖它们。我这个项目里两者都已经由 Comet 装好了——「由 Comet 管理」不等于「项目里不存在」，要不要单独装，看 comet init 的结果就行。

核心原则一句话：

> Comet 管流程，OpenSpec 管需求，Superpowers 管工程方法，CodeGraph 管检索，RTK 管执行，Ponytail 管代码形态，Caveman 管聊天话术。

它们不是平级竞争，而是分层组合。一张图看全景（每个组件旁标注了它对应哪个主题）：

![](附件资源/Harness实践：OpenSpec%20+%20Superpowers%20+%20CodeGraph%20+%20Ponytail%20+%20Caveman%20+%20RTK（下）/img_1.png)

### 3.2 五个问题如何被逐一解决

| 问题 | 谁来管 | 怎么管 |
| --- | --- | --- |
| 上下文工程 | CodeGraph + RTK + Caveman + Comet | 读：官方 benchmark 说一次探索能替代几十次工具调用，2026-08-29 的一次本机对照记录为 96.7%–99.2%；拿：RTK 压命令输出；说：Caveman 压对话；交接：Context Compression 生成紧凑交接包。各组数据口径不同，不宜直接相加 |
| 工具的设计 | CodeGraph + RTK + Comet | CodeGraph 单工具哲学（一个强工具引导正确选择）；RTK 钩子改写（行为无感被改变，不靠说教）；Comet 一个 Rule + 一个 Hook Router（入口收敛，hooks 不打架） |
| 状态和记忆 | Comet + OpenSpec | SDD：规范先行、变更先改 spec；change 状态文件跨会话恢复，  `state-events.jsonl`  留审计，delta spec 归档沉淀成活文档 |
| 验证回路 + 评测集 | Comet + Superpowers + RTK +  `comet eval`  | verify-pass 证据门（脚本校验）；独立只读 Verifier（写代码的人不能给自己判卷）；TDD + 两阶段审查；tee 底牌可回溯；  `comet eval`  用独立 LLM-as-Judge 评 Skill，接 LangSmith 追踪 |
| 熵减 | Comet 守卫 + Ponytail + 路由门禁 | 流程熵：阶段守卫拦住不符合当前 phase 的写入，也防目标漂移；代码熵：七层懒人阶梯约束过度工程；上下文熵：靠压缩缓解，无法根除；路由表决定什么任务进 workflow；Verify 失败仍可退回 Build，闭环不是「只减不增」 |

### 3.3 Claude Code 实战案例

下面是在 Claude Code 上搭这套 Harness 的完整配置。配置格式都来自各项目官方 README，由安装器写入或可手工核对。

第一步：安装四件套

```bash
# Comet：流程主入口（当前发行版要求 Node.js 22+）
npm install -g @rpamis/comet

# CLI，一台机器装一次
cd your-project
comet init --codegraph init

# 每个项目目录跑一次；初始化时选平台和 workflow
# 不想建索引用 --codegraph skip
# RTK：执行端输出过滤（注意别用 cargo install rtk，crates.io 上有同名包）
brew install rtk
rtk init -g
# Claude Code 接线：注册 PreToolUse hook
# Ponytail（可选）：生成端懒人阶梯
# 在 Claude Code 里分两次发送（官方 README 明确要求分开发送才生效）：
#   /plugin marketplace add DietrichGebert/ponytail
#   /plugin install ponytail@ponytail
# Caveman（可选）：输出端电报体；先下载并审阅固定版本，再执行（远程脚本示例）
curl -fsSL https://raw.githubusercontent.com/JuliusBrussee/caveman/v2.3.1/install.sh -o /tmp/caveman-install.sh
less /tmp/caveman-install.sh
bash /tmp/caveman-install.sh

```

Ponytail 在 Claude Code 里的实际安装过程（本机实录，两条命令要分开跑）：

```sql
❯ /plugin marketplace add DietrichGebert/ponytail
  ⎿  Successfully added marketplace: ponytail

❯ /plugin install ponytail@ponytail
   Plugins  Discover   Installed   Marketplaces   Errors
   Plugin Details
   ponytail
   Forces the laziest solution that works. YAGNI, stdlib first, one line over fifty.
   Will install:
   · Components will be discovered at installation
   ⚠ Make sure you trust a plugin before installing, updating, or using it...
     Install for you (user scope)
     Install for all collaborators on this repository (project scope)
   > Install for you, in this repo only (local scope)
     Back to plugin list
❯ /plugin install ponytail@ponytail
  ⎿  ✓ Installed ponytail. Plugin is now active.

```

两个细节值得注意：一是安装前会弹出作用域选择——用户级（你自己的所有项目）、项目级（仓库所有协作者）、本地级（只有当前仓库的你自己）。团队想统一工程规范就选项目级，自己试水选本地级。二是那条警告不是套话：Anthropic 明确声明它无法验证第三方插件里的 MCP server 和文件会不会按预期工作，所以装之前先看一眼插件主页。选完作用域再敲一次 /plugin install ponytail@ponytail 才真正装上。

第二步：核对安装器写入的配置

CodeGraph 的 MCP server 配置（写入 ~/.claude.json）：

```css
{
  ”mcpServers”: {
    ”codegraph”: {
      ”type”: ”stdio”,
      ”command”: ”codegraph”,
      ”args”: [”serve”, ”--mcp”]
    }
  }
}

```

CodeGraph 工具自动放行（写入 ~/.claude/settings.json，一个通配符放行全部 CodeGraph 工具）：

```css
{
  ”permissions”: {
    ”allow”: [
      ”mcp__codegraph__*”
    ]
  }
}

```

RTK 的行为配置（macOS 路径为 ~/Library/Application Support/rtk/config.toml）：

```ini
[hooks]
exclude_commands = [”curl”, ”playwright”]
# 这些命令不做改写

[tee]
enabled = true # 命令失败时保存完整原始输出（默认开启）
mode = ”failures” # ”failures” / ”always” / ”never”

```

第三步：全局路由规则（写入 ~/.claude/CLAUDE.md，节选核心）

```markdown

# Harness 路由规则（团队策略示例，不是 Comet 内置默认）

## 团队约定哪些任务走 /comet
- 新功能、较大 bugfix、重构、跨文件/跨模块改动
- 需要设计、验收、验证、归档的任务
- 恢复 `/changes/*` 已有工作（本项目为 `docs/openspec/changes/*`）

## 团队约定哪些任务可跳过 /comet
- 纯问答、单文件琐碎改动、一行修复、无行为契约的文案调整

## 边界
- Comet 项目里新变更必经 /comet 或 /comet-open，禁止直接 /opsx:new
- 只在当前 workflow/continuation 明确要求的决策点等待用户；不要额外制造确认点
- OpenSpec / Superpowers 在 Classic 中由 Comet 管理；Native 不依赖它们
- 理解工程结构优先用 codegraph_explore，不要逐文件 grep
- 子代理与非 MCP 工具链改用 CLI：codegraph explore ”query”（输出与 MCP 工具相同）
- CodeGraph 未命中、文档/配置未索引或索引延迟时，直接读取文件；shell 输出可按需用 RTK
- Caveman 只压缩聊天输出；proposal / design doc / verification report /
  commit message / PR description 必须保持完整语言

```

第四步：跑一次 Classic 任务（下面是机制示意，不是我这次的端到端执行日志；跑之前项目默认入口要设成 Classic，或显式调用 Classic 入口）

```cs

> /comet 给订单模块加一个导出 CSV 的功能

[Comet] 当前阶段: Open（Classic 五阶段）
[Comet] 已生成 docs/openspec/changes/add-csv-export/
        ├─ proposal.md   变更提案
        ├─ design.md     设计决策
        ├─ tasks.md      任务清单
        └─ specs/        规格文档
[Comet] ⏸ 决策点：等待用户确认 proposal

> （AI 试图提前写实现文件时——Hook 链拦截）
[Hook Router] Write src/orders/export.csv.ts
        → 读 .comet/current-change.json → 路由至 Classic Guard
[Guard] [HARD STOP] Blocked
        原因: 当前阶段 Open，实现写入仅允许 Build / Verify 阶段

> 确认 proposal，进入 Design 阶段

[CodeGraph] codegraph_explore ”orders module export interfaces”
        → 返回: OrderService 相关符号逐字源码 + 调用路径 + 影响半径
        → 文件读取: 0 次（替代 grep/Read 探索）

> 设计确认，进入 Build 阶段（TDD：先写失败测试）

[RTK] agent 调用 pytest → 钩子改写为 rtk pytest
        200+ 行输出压缩为:
        FAILED: 2/15 tests
        [full output: ~/.local/share/rtk/tee/1707753600_pytest.log]

[Ponytail] CSV 转义逻辑 → 标准库 csv 模块可做 → 不引第三方依赖

> （会话中断后重开）
> comet status
[Comet] 只读显示当前 change 与阶段；实际恢复走 resume-probe 返回的 nextCommand 或对应永久入口
> 测试全绿，verify-pass → Archive
[Comet] delta spec 已合并回主 spec，归档至 docs/openspec/changes/archive/

```

日常维护三件套：comet status（只读看状态）、comet doctor（体检）、comet update（升级）。其中 comet doctor 输出最全，可检查安装接线、索引与部分状态；它不能替代真实任务中的阶段拒绝和端到端执行验证。本机实测输出（节选）：

```sql
  > comet doctor

Comet Doctor (scope: auto)
  ✓ Scope: auto checks project scope first, then global scope when it is different
  ✓ Environment: node v26.7.0; platform darwin/arm64; project <项目根>; global <用户主目录>
  ✓ Comet CLI: installed (0.4.0-beta.20)
  ✓ openspec CLI: installed (1.11.0)
  ✓ Superpowers: detected (Claude Code project, Codex project, WorkBuddy project,
    Antigravity project, Antigravity 2.0 project, Codex global;
    version not recorded by skills installer)
  ✓ Classic artifact layout: docs: configured docs/openspec/ present
  ✓ Classic OpenSpec root: docs/openspec/config.yaml is valid (spec-driven)
  ✓ working directories: present (docs)
  ✓ skills: Claude Code (project): complete (78 files)
  ✓ rules: Claude Code (project): complete (1 files)
  ✓ hook runtime: Claude Code (project): current
  ✓ hooks: Claude Code (project): exactly one managed Router Hook present
  ✓ skills: Codex (project): complete (78 files)
  ✓ rules: Codex (project): complete (1 files)
  ✓ hook runtime: Codex (project): current
  ✓ hooks: Codex (project): exactly one managed Router Hook present
  ✓ skills: WorkBuddy (project): complete (78 files)
  ✓ hook runtime: WorkBuddy (project): current
  ✓ hooks: WorkBuddy (project): exactly one managed Router Hook present
  ✓ scripts present: OK (12 scripts)
  ✓ CodeGraph CLI: CodeGraph CLI is installed
  ✓ CodeGraph project index: CodeGraph index is initialized and current
  ✓ CodeGraph MCP registration: Claude Code: registered; Codex CLI: registered
  ✓ CodeGraph effective for Claude Code: CLI, current project index, and MCP registration are ready
  ✓ CodeGraph effective for Codex CLI: CLI, current project index, and MCP registration are ready
  ✓ current selection: no active Comet change

```

几个值得盯的判据：「exactly one managed Router Hook present」——每个平台有且仅有一个 Router Hook，多了少了都说明接线有问题（这正是 2.1 节「入口收敛」的落地检查）；「CodeGraph effective for …」——它要求 CLI、项目索引、MCP 注册三者同时就位才算生效，缺一个都不行；另外注意 Superpowers 那行，doctor 只报「detected」并注明version not recorded by skills installer——它不记录版本号，所以想知道版本还得另找来源。Antigravity 这边只出现在 Superpowers 的 detected 列表里，没有 skills/hooks 检查项，与 2.1 节实录中「Antigravity 2.0 未显示 hook」一致。

```nginx
comet status # 只读查看当前阶段与状态，不替代恢复入口

comet doctor # 检查安装健康、skills、脚本、CodeGraph 索引

comet update # 更新

```

### 3.4 Codex 实战案例

先把最容易搞混的两件事说清楚，能省掉不少重复劳动：

-  `npm install -g @rpamis/comet`  装的是 CLI，一台机器装一次 ，之后所有项目共用，换项目不用重装；
-  `comet init`  是给项目接上 Comet，一个项目目录跑一次 。跑的时候由你勾选要接哪些 coding agent——Claude Code、Codex、WorkBuddy、Antigravity 可以多选，也可以只选一个。这就是「装到哪些 agent 由人决定」的落点。

和 Claude Code 相比，Codex 这边最大的差异在 RTK：Codex 只能用 AGENTS.md + RTK.md 规则文件（靠模型自觉遵守），不像 Claude Code 有 PreToolUse hook 能强制改写。我本机现在的状态是：Claude Code 的 RTK hook 已启用；Codex 侧项目级 RTK.md 和 AGENTS.md 引用都已就位（2.3 节有实测输出）。Comet 这边两边都有项目级 .codex/hooks.json 与 trust hash，它们提供了 Write|Edit 的拦截入口；是否在具体 active change 中拒绝越阶段写入仍待验证。Codex 里的入口为 2026-08-29 历史实录：$comet-native 可直接敲，$comet- 能补全出入口（详见本节第四步）。

第一步：安装与接线

```cs
# Comet：CLI 全局装一次；初始化时选 Codex 平台
npm install -g @rpamis/comet
cd your-project
comet init --platform codex
    # 也可以不加参数交互多选平台
    # --workflow native|classic|both 选工作流
    # --codegraph init|skip 决定是否建索引

# RTK：规则文件档接线（项目级）
rtk init --codex # 写入项目 RTK.md，并在项目 AGENTS.md 加 @RTK.md 引用
# 坑：全局 ~/.codex/AGENTS.md 里的 @RTK.md 引用可能指向错误路径，需手工修正

# Ponytail（可选）：Codex 插件
codex plugin marketplace add DietrichGebert/ponytail
codex plugin add ponytail@ponytail
# 装完运行 codex，打开 /hooks，审核并信任插件自带的 lifecycle hooks

```

Codex 侧的实际安装过程（本机历史实录，和 Claude Code 的交互方式不同；插件安装后仍需在 /hooks 审核捆绑 hook）：

```typescript

> codex plugin marketplace add DietrichGebert/ponytail
 Marketplace `ponytail` is already added from https://github.com/DietrichGebert/ponytail.git.
 Installed marketplace root: ~/.codex/.tmp/marketplaces/ponytail

> codex plugin add ponytail@ponytail
  Added plugin `ponytail` from marketplace `ponytail`.
  Installed plugin root: ~/.codex/plugins/cache/ponytail/ponytail/4.9.0

```

装完用 codex plugin list 复查，当前 Codex 状态是 ponytail@ponytail  installed, enabled  4.9.0。还有一步：插件自带的三组 lifecycle hooks 需要在/hooks里逐个审核信任，否则会被直接跳过（官方文档原话：装插件不会自动信任它捆绑的 hook）。

第二步：CodeGraph 的 MCP 配置

Codex 的 MCP server 写在 ~/.codex/config.toml（安装器自动写入，与官方 README 给 Claude 的配置等价）：

```ini
[mcp_servers.codegraph]
command = ”codegraph”
args = [”serve”, ”--mcp”]

```

第三步：规则作用域。团队约束优先写项目 AGENTS.md，个人全局默认才写 ~/.codex/AGENTS.md。我这个项目的  托管块和 Ponytail 规则都在项目 AGENTS.md 里；CodeGraph 的 marker 段有没有，取决于你有没有跑过它的安装器——别把两者当成同一个文件里必然同时存在的东西。

```diff
# Harness 路由规则（项目 AGENTS.md 或用户级 AGENTS.md，按作用域选择）
- 新功能 / 重构 / 跨文件改动 → 团队策略可要求走 $comet；Comet 入口仍按项目配置选 Native/Classic
- 理解工程结构优先 codegraph_explore，不要逐文件 grep
- 执行命令后若需完整输出，读 RTK tee 日志，不要重跑命令
- 本文件中的  块与 CodeGraph marker 段为工具托管，勿手改

```

第三步半：Codex 的 Hook 写拦截——官方机制 + 本机落盘 + 信任

先说机制。Codex 官方文档（https://learn.chatgpt.com/docs/hooks）把 Hooks 定义为"an extensibility framework for Codex"——允许你在 agent 主循环的固定切面上挂自己的脚本或 MCP 工具。几个要点：

- 11 个事件切面 ：一轮对话内的  `PreToolUse`  /  `PermissionRequest`  /  `PostToolUse`  /  `PreCompact`  /  `PostCompact`  /  `UserPromptSubmit`  /  `SubagentStop`  /  `Stop`  ；会话或子代理启动时的  `SessionStart`  /  `SubagentStart`  ；主线程结束时的  `SessionEnd`  ；
- matcher 按正则过滤 ：  `PreToolUse`  过滤的是工具名。官方文档里有一句关键注解—— 对  `apply_patch`  ，matcher 值也可以写成  `Edit`  或  `Write`  。这正是 Comet 落盘里  `Write|Edit`  的来历：它不是 Comet 自造的写法，而是 Codex 写文件工具的标准匹配名。另外  `UserPromptSubmit`  和  `Stop`  不支持 matcher，配了也会被忽略；
- stdin / stdout 双向协议 ：每个 command hook 从 stdin 收到一个 JSON（含  `session_id`  、  `cwd`  、  `hook_event_name`  、  `model`  ，以及  `tool_name`  /  `tool_input`  等事件专属字段），往 stdout 写决策。  `PreToolUse`  用  `permissionDecision: "deny"`  拒绝（legacy 的  `decision: "block"`  也接受，退出码 2 同理）；  `PostToolUse`  用  `decision: "block"`  加  `additionalContext`  把反馈塞回模型；
- 信任门禁 ：非受管 hook 首次运行前必须审查并信任，信任按 hook 内容的 hash 记录——脚本一改 hash 就变，重新进审查队列。CLI 里用  `/hooks`  查看和信任，一次性自动化可以加  `--dangerously-bypass-hook-trust`  ；企业能通过  `requirements.toml`  下发受管 hook，默认按策略信任；
- 多来源全部加载，不互相覆盖 ：  `~/.codex/hooks.json`  、  `~/.codex/config.toml`  、  `<项目>/.codex/hooks.json`  、  `<项目>/.codex/config.toml`  是最常用的四个位置，命中的 hook 全部执行，同一事件的多个 command hook 并发启动。注意项目级 hook 只在  `.codex/`  层被信任时才加载；
- timeout 默认 600 秒 （  `SessionEnd`  是例外：默认 1 秒、上限 3 秒）；handler 分  `command`  和  `mcp_tool`  两种，加  `async: true`  可以丢到后台跑。想整体关掉就设  `[features] hooks = false`  （  `codex_hooks`  是它的 deprecated alias）。

最小配置长这样（官方形状）：

```bash

{
  ”hooks”: {
    ”PreToolUse”: [
      {
       ”matcher”: ”^Bash$”,
       ”hooks”: [
          { ”type”: ”command”, ”command”: ”python3 ~/.codex/hooks/pre_tool_use_policy.py”, ”timeout”: 30, ”statusMessage”: ”Checking Bash command” }
        ]
      }
    ],

    ”PostToolUse”: [
      { ”matcher”: ”^Bash$”, ”hooks”: [ { ”type”: ”command”, ”command”: ”python3 ~/.codex/hooks/post_tool_use_review.py”, ”timeout”: 30 } ] }
    ]
  }
}

```

本机落盘（Codex CLI v0.150.1）：comet init 在 Codex 上会自动写项目级 .codex/hooks.json，不需要手工接线。当前文件里没有显式 timeout，超时走宿主默认值：

```bash
{
  ”hooks”: {
    ”PreToolUse”: [
      {
        ”matcher”: ”Write|Edit”,
        ”hooks”: [
          {
            ”type”: ”command”,
            ”command”: ”node \”<项目根>/.agents/skills/comet/scripts/comet-hook-router.mjs\” --platform \”codex\” --project-root \”<项目根>\””
          }
        ]
      }
    ]
  }
}

```

（路径用 <项目根> 占位；落盘原文是安装时项目的真实路径。）对照上面的官方机制看，两个关键字段一目了然：

- Matcher  `Write|Edit`  ——就是官方说的 apply_patch 匹配名写法，两个写文件工具一并匹配；
- router 带平台参数 ：  `--platform "codex" --project-root "<项目根>"`  ——同一个 router 脚本服务所有平台，靠参数区分平台和项目边界。

信任界面（首次运行时出现过，之后 trust hash 持久化）：

```sql
PreToolUse hooks
  1 hook needs review before it can run. 选择信任即可。

  [!] Hook 1 · new
  Event     PreToolUse
  Matcher   Write|Edit
  Source    Project config - <项目根>/.codex/hooks.json
  Command   node ”…/.agents/skills/comet/scripts/comet-hook-router.mjs” --platform ”codex”
            --project-root ”…”
  Mode      Sync
  Timeout   600s
  Trust     New hook - review required
  Press t to trust; esc to go back

```

现在本机 config.toml 里已经存了对应的 trusted_hash，说明这个 hook 过了审查。脚本内容一变（比如升级 Comet 导致 router 更新），下次启动会重新要你确认。

/hooks全景长什么样（2026-08-29 实测）。在 Codex 里输入 /hooks，看到的是一张总表，把「装了什么、哪些在跑、哪些等你审」一次列全：

```css
Hooks
  Lifecycle hooks from config and enabled plugins.

  ⚠ 3 hooks need review before they can run.
  Event                 Installed   Active      Review      Description
  PreToolUse            1           1           0           Before a tool executes
  PermissionRequest     0           0           0           When permission is requested
  PostToolUse           0           0           0           After a tool executes
  PreCompact            0           0           0           Before context compaction
  PostCompact           0           0           0           After context compaction
  SessionStart          1           0           1           When a new session starts
  SessionEnd            0           0           0           Right before a session ends
  UserPromptSubmit      1           0           1           When the user submits a prompt
  SubagentStart         1           0           1           When a subagent is created
  SubagentStop          0           0           0           Right before a subagent ends its turn
  Stop                  0           0           0           Right before Codex ends its turn
  Interrupt             0           0           0           Right before an interrupted turn is aborted

```

这张表一次说清了三件事：

- Comet 的写拦截在跑 ：  `PreToolUse`  那行是 Installed 1 / Active 1 / Review 0——装了、激活了、不用再管；
- Ponytail 的三组 hook 全在等你审 ：  `SessionStart`  、  `UserPromptSubmit`  、  `SubagentStart`  三行都是 Installed 1 / Active 0 / Review 1 （这张截图是刚装完、还没审的状态，顶部那行  `⚠ 3 hooks need review`  也在提示这一点）。它们正好对应 2.4 节那个 hooks 文件里的三组事件，一个不差。 没审之前会被直接跳过——插件装完了，但「always-on 激活」其实还没发生。 三列数字的关系就是  `Installed = Active + Review`  ：装了不等于在跑。 怎么确认自己到底审没审过？ 看  `~/.codex/config.toml`  里有没有对应的  `trusted_hash`  ，比看 UI 更可靠。我这边审完之后，三组 hook 各落了一条记录（格式见 2.4 节），至此 Ponytail 的 always-on 才真正生效；
- 界面比文档多一个事件 ：官方文档列了 11 个，实际界面是 12 行 ，多出一个  `Interrupt`  （一轮对话被中断前触发）。文档没提它，但界面里确实存在。

顺带一提，Codex CLI 本身是开源的，仓库在https://github.com/openai/codex； 上面这些机制的 wire schema 官方指向仓库里的 codex-rs/hooks/schema/generated （注意 main 分支的 schema 可能包含当前 release 还没支持的字段）。

第四步：实际运行

```shell
# 新任务
codex
> $comet 给订单模块加一个导出 CSV 的功能
# （Comet 状态机接管：Open → Design → Build → Verify → Archive，
#   RTK 靠 AGENTS.md 里的规则指引，Ponytail 阶梯约束生成；
#   Codex 的 skill 触发语法是 $comet，不是 Claude Code 的 /comet）

# 会话中断后恢复
codex resume
# Codex 侧恢复会话
# Comet 侧的恢复探测：
#   comet resume-probe 返回 auto_resume / ask_user / out_of_scope / none，
#   并按项目配置路由到对应工作流入口（Claude Code：/comet-native 或
#   /comet-classic；Codex：$comet 展开的对应入口）

```

Codex 里的 Comet 入口清单（2026-08-29 实测）。先直接回答那个悬着的问题——$comet-native可以直接调用：

```bash
› $comet-native
  Comet Native  [Skill] Comet Native workflow

```

再输入 $comet- 看自动补全，会把全部入口一次列全：

```ruby
› $comet-

  Comet Any / Skill Creator     [Skill] 创建或升级 Comet Classic workflow Skill
  Comet Classic                 [Skill] Comet Classic workflow:OpenSpec + Superpowers
  Comet Classic 阶段 1:Open     [Skill] 开启 OpenSpec change 并建立其产物
  Comet Classic 阶段 2:Design   [Skill] 为 change 产出深度技术 Design Doc
  Comet Classic 阶段 3:Build    [Skill] 恢复或创建实施计划并执行其任务
  Comet Classic 阶段 4:Verify   [Skill] 验证 change、记录证据并驱动修复循环
  Comet Classic 阶段 5:Archive  [Skill] 确认归档、合并 delta spec 并完成分支收尾
  Comet Classic 预设:Hotfix     [Skill] 通过 open-build-verify-archive 短流程修复已有行为 bug
  Comet Classic 预设:Tweak      [Skill] 处理可收敛为单一 OpenSpec change 的轻量或中等变更
  Comet Native                  [Skill] Comet Native workflow
  Comet 手动代码审查            [Skill] 只读审查当前 change，不推进工作流

```

三个要点：

-  `$comet-native`  和  `$comet`  都能直接敲 ，不用先展开菜单再选；
- Hotfix 和 Tweak 的真实名字是「Comet Classic 预设:Hotfix / Tweak」 ——它们是 Classic 的预设档，不是  `comet-hotfix`  这样的独立前缀。想在 Codex 里用，输入  `$comet-`  从菜单里选，别照着 Claude Code 的  `/comet-hotfix`  硬套；
- 菜单里还多出一个 Claude Code 侧没提过的 「Comet 手动代码审查」 （只读审查当前 change，不推进工作流），以及别的插件混进来的 skill（我这儿出现了  `control-chrome`  ）——  `$`  补全列的是 所有已安装 skill ，不只有 Comet 的。

$和@不是一回事（实测对比，这是 Codex 里最容易搞混的一组前缀）。同样拿 Ponytail 试：

```sql
› $ponytail

  ponytail                   [Skill] Forces the laziest solution that actually works…
  ponytail (ponytail)        [Skill] Forces the laziest solution that actually works…
  ponytail-audit             [Skill] Whole-repo audit for over-engineering…
  ponytail-audit (ponytail)  [Skill] Whole-repo audit for over-engineering…
  ponytail-debt              [Skill] Harvest every `ponytail:` comment into a debt ledger…
  ponytail-debt (ponytail)   [Skill] Harvest every `ponytail:` comment into a debt ledger…
  …
```

```swift
  › @ponytail

  Ponytail         Lazy senior developer mode                         Plugin
  ponytail         Forces the laziest solution that actually works…   Skill
  ponytail-audit   Whole-repo audit for over-engineering…             Skill
  ponytail-debt    Harvest every `ponytail:` comment into a ledger…   Skill
  ponytail-gain    Show ponytail's measured impact as a scoreboard…   Skill
  ponytail-help    Quick-reference card for all ponytail modes…       Skill
  ponytail-review  Code review focused exclusively on over-engineering…  Skill
  ponytail         .agents/skills/                                    Dir

› @ponytail-review
  ponytail-review  Code review focused exclusively on over-engineering…  Skill
  ponytail-review  .agents/skills/                                       Dir
  SKILL.md         .agents/skills/ponytail-review/

```

两个结论：

-  `$是执行，@是引用。`  输入  `@ponytail`  时，菜单里除了 skill，还会列出插件本体（标  `Plugin`  ）、  `.agents/skills/`  目录（标  `Dir`  ），再往下钻还会出现  `SKILL.md`  文件——它是 Codex 的 资源引用 入口，作用是把文件或目录挂进上下文。想让 agent 进入 Ponytail 模式干活，用  `$ponytail`  ；想让它把 skill 的源码读一遍，用  `@`  。所以官方 README 那句「Codex 里用  `@`  前缀调用」，按实测更准确地说是 引用 而非执行；
- 每个 skill 都出现了两次 。一次是项目里已有的  `.agents/skills/`  版本，一次是刚装进来的插件版本（括号里带  `ponytail`  命名空间）。项目里本来就有 Ponytail skills 时，装插件不会覆盖它，而是两套并存，调用时可按命名空间区分。

双平台当前差异：Claude Code 的 RTK Bash hook 已启用（强制改写）；Codex 的项目级 RTK 规则已接上，但靠模型自觉。Comet Router 两边的配置里都在。Codex 侧必须去 /hooks 逐个审，当前 config.toml 里三组各有 trusted_hash 落盘；这证明已受信任，不单独证明每个当前会话都在执行。Claude Code 侧的 hook 加载与版本选择仍应以宿主实际状态为准。

### 3.5 一次任务的生命周期走读（含中途断电恢复）

拿「给订单模块加一个导出 CSV 的功能」串一遍。

第 0 步·路由判断。团队规则可以规定新功能、跨文件改动必须进 Comet，琐碎任务直接做。这是 Harness 层的策略——Comet Runtime 不会按任务大小自动换 workflow。进了 Comet 之后走 Native 还是 Classic，仍然由项目配置决定。

第 1 步·Open（Classic）或 Shape（Native）。Classic 下 OpenSpec 生成 proposal / design / tasks / specs 四件套；Native 下 Shape 澄清需求、写 brief 和目标规格。要不要停下来等你确认、还是自动往下走，取决于当前 workflow、Runtime continuation 和项目配置——不是每个阶段都必然有人工确认点。

第 2 步·Design / 进入 Build 前。Classic 完整流程里由 Superpowers 的 brainstorming 接管；Hotfix/Tweak 各有自己的缩短路径。这时候 CodeGraph 可以一次探索拿到订单模块的接口和调用链，但查询也可能为空、有歧义，或者带进一堆无关符号，必要时就回退直接读文件。−88% 和文件读取归零是官方 benchmark 的说法，不是每次查询的保证。

第 3 步·Build。按 change 选择 direct、executing-plans 还是 subagent-driven-development；TDD 也可能选 tdd 或 direct，不是所有路径都强制。Claude Code 的 Bash 命令会被 RTK hook 改写，Codex 这边则要看规则有没有接上。写代码时套用 Ponytail 阶梯；开了 Context Compression 就用 Comet 生成的交接包。

第 4 步·Verify。验证门强制校验：测试全绿 + tasks 勾完 + 设计目标达成，而且 verification report 必须真实存在——这些由脚本校验，缺一样都进不了下一阶段（Native 下由独立只读 Verifier 把关）。测试挂了？RTK 的 tee 日志里有完整输出，让子代理自己去翻，别重跑命令。

第 5 步·Archive。Classic 按增量 spec 语义合并回主 spec；Native 用自己的 archive transaction。两边的状态文件也不是同一套。

中途断电怎么办？重开会话先跑一次只读的 comet resume-probe . --stdin --json：返回 auto_resume 就顺着它给的 nextCommand 继续，返回 ask_user 就选一个 change。comet status 只负责查看，不是恢复入口。我这个项目目前没有 Ponytail 的 nudge/PostToolUse hook，只有项目级 skills 和 AGENTS.md 规则。

### 3.6 路由门禁与协同边界

整合的关键不在装了什么，而在规则。四条核心边界：

路由门禁——团队推荐什么时候走 Comet（不是 Runtime 按规模自动切换）：

| 推荐走 /comet | 通常可跳过 /comet |
| --- | --- |
| 新功能 | 纯问答 |
| 较大 bugfix | 单文件琐碎改动 |
| 重构 | 一行修复 |
| 跨文件/跨模块改动 | 无行为契约的小文案/格式调整 |
| 需要设计、验收、验证、归档 |  |

Ponytail 边界——不可省略清单：安全检查、信任边界的数据校验、错误处理、数据丢失保护、无障碍要求、必要的可观测性、保护真实行为的测试。Ponytail 能让代码更小，但不能替你跳过 Comet 的阶段门或省掉验证；是否强制 TDD 由当前 change 的 tdd_mode 决定。

Caveman 边界——绝不压缩落盘产物：proposal、design doc、spec、tasks、implementation plan、verification report、archive notes、commit message、PR description 必须保持完整语言。遇到安全警告、不可逆操作确认、用户决策点、验证失败时自动暂停。

CodeGraph 边界：MCP guidance 和项目指令能覆盖到哪些 agent，取决于宿主；子代理可以用 codegraph explore CLI，也可以在未命中、索引延迟或文档/配置场景回退直接读取。那个 +80% 是上游特定 benchmark 的残留上下文口径，不是固定值。

### 3.7 收益与限制（诚实版）

收益（都是各项目官方口径，叠起来之后的综合效果没有独立基准）：

| 维度 | 工具 | 官方声明 |
| --- | --- | --- |
| 流程可靠性 | Comet | 双工作流状态机 + 阶段守卫 + 可恢复状态；上游 Native vs Classic benchmark 报告 Token −76.8%、轮次 −57.4%、耗时 −47.4%、pass^3 87.5%，非本机复测 |
| 探索成本 | CodeGraph | 上游 7 仓库 benchmark 报告工具调用 −88%、token −62%、成本 −44%、文件读取归零；2026-08-29 历史对照记录为 96.7%–99.2%（口径不同，不可直接比较） |
| 执行输出 | RTK | 上游宣称测试日志最多约 −90%；本机验证  `154/154`  自测通过，未做原始输出对照 |
| 代码量 | Ponytail | 上游报告平均 −54% 等数据；本机只验证 root suite  `84/84`  ，没测过自己项目的代码量收益 |
| 聊天输出 | Caveman | 上游报告 Skill/Proxy 节省数据；本机只有项目 skill 文件，没有独立 benchmark |

限制与风险（认真读）：

- 组合没有联合基准 。五个工具各有官方数据，叠起来会怎样没人测过。它们理论上正交，但 Ponytail 砍代码量和 Superpowers 的 TDD 全面性之间存在张力——一个求少、一个求全，靠边界规则调和，不会自动平衡。
- 规则档工具的采纳率要打折 。我这台机器上 Claude Code 有 RTK Bash hook（强制改写），Codex 只有规则（靠模型自觉）。CodeGraph 有 MCP 和规则指引，但用不用仍取决于查询命中和 agent 当时的判断。
- Caveman 的净收益可能为负 。简洁任务 + 长会话里，规则自身每轮约 1–1.5k 输入 token 的成本可能吃掉节省。所以设为可选、按需触发。
- CodeGraph 的上下文残留 。官方明示多轮会话约 +80% 检索上下文残留——检索省了，窗口更满，长会话可以考虑配合压缩策略。
- 维护成本是真实的 。我这台机器上跑的是 Comet  `0.4.0-beta.20`  、OpenSpec  `1.11.0`  、CodeGraph  `1.6.0`  、RTK  `0.45.0`  、Codex  `0.150.1`  、Superpowers plugin manifest  `6.3.0`  、Ponytail  `4.9.0`  （插件 manifest）；上游 benchmark 可能是别的版本跑出来的。另外全局规则本身就是一份需要维护的配置资产。
- BSL-1.1 许可警示 。Caveman 的 Proxy/Engine 用的是 BSL-1.1（非 OSI 开源），商用集成前需经法务确认。

## 四、数据核验与说明

原始资料以各项目 README / 官方博客为一手数据源，本轮复核则优先用本机 CLI、配置和实测。可信度分三级：A = 我在本机复现；B = 项目官方自述、我没独立复测；C = 其他来源。

### 4.1 本机验证（macOS 26.4；基线采集 2026-08-29，本轮复查 2026-08-31）

| 验证项 | 当前结果 |
| --- | --- |
| 环境 | macOS 26.4（Build 25E246） |
| Comet |  `0.4.0-beta.20`  ；默认入口 Native；Native/Classic 均无 active change |
| Comet roots | Native  `docs/comet`  ；Classic  `docs/openspec`  ；Superpowers  `docs/superpowers`  |
| Comet 配置 |  `default_workflow: native`  ；Classic  `artifact_layout: docs`  ；  `context_compression: off`  （默认关闭，未启用压缩） |
| Comet health |  `comet doctor . --json`  PASS；Codex/Claude/WorkBuddy 各一个 managed Router Hook |
| OpenSpec |  `1.11.0`  ；Classic adapter 可调用 |
| Codex CLI |  `0.150.1`  ；项目  `.codex/hooks.json`  已注册  `Write|Edit`  Router，trust hash 存在 |
| Codex Hook 官方文档 | 2026-08-29 历史记录曾核对[https://learn.chatgpt.com/docs/hooks] |
| Codex  `/hooks`  界面 | 2026-08-29 安装后历史截图：Comet 的  `PreToolUse`  为  `Installed 1 / Active 1 / Review 0`  ；Ponytail 三组为  `Installed 1 / Active 0 / Review 1`  。本轮通过  `config.toml`  确认三组 Ponytail  `trusted_hash`  均存在。 |
| CodeGraph |  `1.6.0`  ；49 files、17,740 nodes、65,626 edges，索引 current；Codex/Claude MCP 已注册 |
| CodeGraph CLI 实测 | 2026-08-29 历史对照记录为 96.7% / 99.1% / 99.2%（本仓库含压缩  `.mjs`  ，属有利场景）；未保存可运行的统计脚本 |
| RTK |  `0.45.0`  ；  `rtk verify`  为 154/154；Claude Bash hook 已启用；  `rtk init --codex`  已执行，项目  `RTK.md`  +  `AGENTS.md`  引用就位 |
| Ponytail | Codex 插件 4.9.0 ，installed & enabled；6 skills + 6 commands + 3 组 lifecycle hooks；root suite 84/84。Codex 三组 hook 的  `trusted_hash`  均已写入，表示已受信任；当前会话是否全部执行仍需宿主界面确认 |
| Caveman | 项目 skill 存在；无独立测试套件 |
| Comet Eval | 命令存在，但 sandbox 下因无法创建  `~/.comet/eval`  未完成执行验证 |

上面这些 A 级结论，证明的是「这台机器、这个项目、这个版本」的状态——它不代表上游 benchmark 成立，也不保证下一个版本行为一致。

### 4.2 上游声明与来源

这一节汇总正文引用过的上游资料，按项目分组。三档含义与 4.1 保持一致：A = 本轮本机可复现；B = 项目官方 README / 文档或博客明确声明，但我没有独立复测；C = 历史记录或二手转载。同一事实若既有本机证据又有上游声明，以本机证据单独列在 4.1，不因“官方写过”自动升为 A。

Comet

| 声明 | 级别 | 依据 |
| --- | --- | --- |
| 双工作流：Native 四阶段 / Classic 五阶段；Native 不依赖 OpenSpec/Superpowers/Bash/WSL | B | 官方 README |
|  `comet init`  支持 35 个 AI 编码平台（原始材料写的 29 是错的） | B | README 原文「  `comet init`  supports 35 AI coding platforms」 |
| 评测：Token −76.8%、轮次 −57.4%、耗时 −47.4%、pass^3 87.5%、pass@3 100% | B | README 自述的 Native vs Classic 对齐实验（16 任务 × 48 次，取 41 对双方通过样本） |
| Context Compression：Build 输入 −25~30%、测试通过率 100%、大任务约 15,000 tokens；代价是 Spec 覆盖率 100%→95% | B | README 的 Context Compression 章节 |
| Runtime 布局：Native 产物  `docs/comet/`  （可改  `native.artifact_root`  ）+ 机器态  `.comet/runtime/native/`  ；Classic  `<classic-change-dir>/.comet.yaml`  +  `run-state.json`  +  `state-events.jsonl`  ；共享  `.comet/config.yaml`  与  `current-change.json`  | B | README 原文印证 + 官方文档补充；本项目根路径见 4.1 |
| Hook 机制：每平台一个 Rule + 一个 Router；一次写至多到一个 Guard、fail closed；Native 仅 Build 可写实现、Classic 为 Build+Verify | B | README 的 Guard & Automation Scripts 脚本表 + Classic Reliability 第 7 条；本机尚未完成阶段拒绝对照 |
|  `hook.allow_paths`  为当前共享写策略字段（项目相对白名单，不能绕过  `.comet`  与产物根） | B | README 原文；前缀匹配、子目录继承、越界由  `comet doctor`  报告三条尚未在本机复验 |
| 双平台联动：各平台独立 skills 目录、每平台一个 Rule、  `<comet-ambient-resume>`  托管块 | B（部分 A） | README Supported Platforms 表 + resume-probe + 项目结构章节；Codex / WorkBuddy 自动装 Router hook 已在本机配置中确认 |

CodeGraph

| 声明 | 级别 | 依据 |
| --- | --- | --- |
| Rust 内核 20 语言、总支持 34 语言、9 类 Agent、MCP 单工具哲学 | B | 官方 README |
| 上游基准：工具调用 −88%、速度 +53%、token −62%、成本 −44%、文件读取归零 | B | README 自述（7 个指定仓库 × 4 次运行取中位数） |
| 上下文残留 +80% | B | README 的诚实声明（多轮会话实测） |
| 性能：Swift 仓库 27k 文件 ~100s、Linux 内核 Codex CLI 与 Hook

| 声明 | 级别 | 依据 |
| --- | --- | --- |
| 11 个事件、stdin/stdout 协议、matcher 语义、timeout 默认 600s、managed hook、  `codex_hooks`  deprecated alias | B | 官方文档https://learn.chatgpt.com/docs/hooks；本轮网络不可达，未能复验页面或跳转 |
|  `/hooks`  界面实际显示 12 行，比文档多一个  `Interrupt`  | A | 2026-08-29 历史实录； |
|  `$`  是执行、  `@`  是引用；  `$comet-native`  可直接调用；Hotfix/Tweak 菜单名为「Comet Classic 预设:Hotfix / Tweak」 | A | 2026-08-29 历史实录； |

RTK

| 声明 | 级别 | 依据 |
| --- | --- | --- |
| 机制四板斧、tee 保险、削减表、稀释声明、bytes/4 估算、config.toml 格式 | B | 官方 README |
| crates.io 同名包（Rust Type Kit）安装坑 | B | 官方 README 确认 |
| 全称「Rust Token Killer」 | B（弱） | README 徽标 alt 文本；正文自称 "CLI proxy"，未在正文正式声明 |
| ~77,200 star / 4,850 fork / 创建于 2026-01-22 / v0.45.0 | C | 公众号转载，数值动态变化（见 4.3 第 1 项） |

Ponytail

| 声明 | 级别 | 依据 |
| --- | --- | --- |
| 7 层阶梯、6 个 skill、4 档强度、20 个 agent 宿主、「never fewest tokens」、「lazy, not negligent」 | B | 官方 README |
| 插件自带 3 组 lifecycle hooks（  `SessionStart`  /  `SubagentStart`  /  `UserPromptSubmit`  ） | A | 直读插件安装目录的  `hooks/claude-codex-hooks.json`  与 manifest |
| 双侧安装命令与实际安装过程 | 混合 | README 原文 + 本机当前插件状态；完整安装过程为历史实录 |
| agentic 基准：LOC −54% / token −22% / cost −20% / time −27% / safe 100% | B | README（Haiku 4.5 无头会话）；−94% 为过度构建峰值，issue #126 已澄清为「会话基线伪影」 |

Caveman

| 声明 | 级别 | 依据 |
| --- | --- | --- |
| 双产品架构与许可拆分（MIT Skill + BSL-1.1 Proxy） | B | 官方 README |
| Skill 输出节省：10 任务平均 1214→294 token、任务级平均 65%（22%–87%）；Proxy 输入 −33.2% | B | README 自述基准（Proxy 为 54-run、18 项精确检查全过） |
| 诚实警告：每轮 +1–1.5k 输入 token、净收益可能为负、真收益是速度与可读性 | B | README 原文 |
| 第三方实测「创意网页代码量 +18.9%」 | C | 第三方对比数据，非官方，引用前请自行复核 |

OpenSpec / Superpowers

| 声明 | 级别 | 依据 |
| --- | --- | --- |
| OpenSpec：  `/opsx:propose`  主入口、Stores beta、30+ 工具、Node 20.19+ | B | 官方 README |
| Superpowers：14 个平台与核心 skills 库 | B | 官方 README |
| Superpowers 6.0 自优化过程（−10% / +15% / $165 / −41%）、thinking token 反直觉发现 | B | 官方博客 blog.fsck.com |
| Superpowers "up to 50% faster / up to 60% cheaper" | B | 官方博客口径（注意 up to 是上限） |

### 4.3 时效性信息清单

文中「我这台机器上跑出来的」结论，只对当时的版本、当时的项目成立。下面几类信息时效性较强——版本号、仓库统计、宿主相关的口径等都会随时间变化，如需引用，请以最新来源为准：

| # | 项目 | 核对来源 | 变动原因 |
| --- | --- | --- | --- |
| 1 | RTK 的 star / fork / 创建日期 / 最新版本号 | GitHub 项目页与 Releases | 统计数值每日变动；官方 README 内部版本号本身就不一致（0.28.2 vs v0.37.2+），只能以 Releases 为准 |
| 2 | CodeGraph CLI 与 MCP 的输出差异 | 官方未发布对照数据；如需具体数值，可在目标仓库上同一查询两边各跑一次对比 | 输出细节与计数口径随宿主、查询、仓库而异，不存在可照搬的通用比例 |
| 3 | Caveman 的默认触发策略 | 官方 README 的 Honest number warning 章节 | 是否默认开启取决于任务类型；官方承认简洁任务上净收益可能为负——规则每轮约消耗 1–1.5k 输入 token |
| 4 | Ponytail 三组 hook 的启用状态 |  `~/.codex/config.toml`  的  `hooks.state`  是否写入  `trusted_hash`  | 装插件不等于激活；该字段是信任动作的直接产物，比 UI 显示更稳定（UI 状态与截图时点相关） |

除上述四项外，正文还混有三类证据，不能统称“本次实测”：

- 本轮可复现 ：Comet  `doctor/status/root`  、当前配置与项目 hooks、CodeGraph 索引状态、RTK  `verify`  、Ponytail Codex 插件 manifest / trust hash、Caveman 项目 skill 存在；
- 历史实录 ：Codex 侧  `$comet-native`  与  `$`  自动补全入口、Hotfix/Tweak 菜单名、  `/hooks`  界面数字、CodeGraph 三组字节对照、2026-08-29 的仓库 HTTP 200 结果；
- 上游声明 ：Comet 支持 35 个平台、Context Compression 的 25–30% 与 95% 覆盖率代价、  `hook.allow_paths`  细节、Runtime 双套布局、各项目 benchmark。

### 4.4 关于 Codex CLI 和 ChatGPT Desktop

本机验证采用 Codex CLI，实际对比 ChatGPT Desktop（采用 Codex 模式）等效，如有非预期表现可以让 Desktop 自行解决或给出解决方案+手动执行。

## 结语

回到开头的五个问题，这套 Harness 的本质是一次分工明确的权力制衡：

- 上下文工程 ：CodeGraph 把探索成本前置成索引（AI 想乱翻文件，不如查图；代价是残留变多，需一起管理）；RTK 把执行噪音挡在上下文外（想读 200 行日志，只给 20 行）；Caveman 把废话挡在终端里（想客套，电报体伺候）；
- 工具的设计 ：一个强工具胜过一堆窄工具（CodeGraph）、改写胜过说教（RTK）、一个入口胜过一堆 hooks（Comet）；
- 状态和记忆 ：SDD 把规范立为唯一真相、代码降为实现产物——变更先改 spec 再动代码，四件套与 delta 归档让需求可回溯、可跨会话、可沉淀；
- 验证回路 + 评测集 ：verify-pass 证据门 + 独立 Verifier 让「说完成了」变成「证明完成了」，  `comet eval`  让 Skill 本身也被评测；
- 熵减 ：三种熵分头治理——Comet 的 Anti-drift 守卫治流程熵（阶段跳跃、目标漂移），Ponytail 阶梯治代码熵（过度工程），上下文熵则只能靠压缩缓解；闭环留了退回 Build 的返工通道。

每一个工具单独看都只是「省了一点 token」或「多了一道检查」，组合起来改变的是博弈结构：AI 的每一个失误倾向，都有一道闸在对应位置等着。

至于要不要全上？推荐按项目规模和痛点分层，而不是默认全装：非平凡开发先上 Comet + RTK；中大型代码仓库再加 CodeGraph；Ponytail 与 Caveman 按需启用。

- Comet 是这套组合里承担流程强制的组件。满足 active change、Router 受信任和路径受管辖等前提后，Guard 才能拦截越阶段写入；本机  `comet doctor`  显示三个受管平台各 78 个 skill 文件、1 条规则、一个 Router Hook，接线可自检；
- RTK 的投入产出比最高：一个二进制、一个 hook，把命令输出的噪音砍掉大半，失败时还有 tee 兜底；
- CodeGraph 解决的是中大型仓库里定位代码的痛点。它生效的条件很硬——doctor 会检查 CLI、项目索引、MCP 注册是否同时就位，缺一个就不算 effective；小仓库或文档库可跳过；

Ponytail 和 Caveman 则是按项目可选的：Ponytail 在「AI 过度工程」高发的场景（原型、内部工具、常见 CRUD）收益明显，但算法密集或领域建模重的代码，强行最小化可能帮倒忙；Caveman 官方自己就承认，在原本就简洁的任务上净收益可能为负——它真正卖的是可读性，省钱只是赠品。

以上是本机装完、接完、跑通多个项目之后的选择。官方数据只能说明单个组件的上限，组合起来效果如何，取决于具体项目——benchmark 适合当参考，不适合当收益承诺。

项目地址：

- Comet：https://github.com/rpamis/comet （内嵌 OpenSpec https://github.com/Fission-AI/OpenSpec 与 Superpowers https://github.com/obra/superpowers）
- CodeGraph：https://github.com/colbymchenry/codegraph
- Ponytail：https://github.com/DietrichGebert/ponytail
- Caveman：https://github.com/JuliusBrussee/caveman
- RTK：https://github.com/rtk-ai/rtk

文中提到的平台与文档：

- Codex CLI（开源）：https://github.com/openai/codex
- Codex Hooks 官方文档：https://learn.chatgpt.com/docs/hooks

_本文资料核验时间：2026-08-26 至 2026-08-27 为初始采集，2026-08-29 在 macOS 26.4 上建立本机基线，2026-08-31 复查了 CLI、配置、索引、测试与可用文件。A 级表示本轮本机可复现，B 级表示上游项目声明但未独立复测，C 级表示历史记录或二手来源；4.3 列出时效性较强的信息，不要把历史记录当作当前事实。_

---
原文链接：https://mp.weixin.qq.com/s?__biz=MzA3OTQwNDAxMw%3D%3D&mid=2247483669&idx=1&sn=d88fcaeefd96e68ff923295c72f36d83&chksm=9fb54f97a8c2c68192cb12cbc4ec8e82159b87539f9b95588a7c86750c6742eb25442807febb
