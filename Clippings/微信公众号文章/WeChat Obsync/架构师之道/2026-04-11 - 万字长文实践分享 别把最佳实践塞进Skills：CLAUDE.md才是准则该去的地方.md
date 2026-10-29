---
source_url: "https://mp.weixin.qq.com/s?__biz=MzAxNjk4MzQxNw%3D%3D&mid=2247489794&idx=1&sn=cec09a7de6f8b6cea66ee8b57fec5c20&chksm=9bed2d14ac9aa402071fec87a5775ca933fb31af13bdc7517055c182a674257bd9faa3213e4f"
title: "[万字长文实践分享]别把最佳实践塞进Skills：CLAUDE.md才是准则该去的地方"
account: "架构师之道"
published_at: "2026-04-11 14:24:19"
saved_at: "2026-10-21 09:18:01"
sync_id: "art_f24b9c290a354fa6b215ec66b04c7448"
parse_status: "ok"
---

# [万字长文实践分享]别把最佳实践塞进Skills：CLAUDE.md才是准则该去的地方

## 1 引言

Vercel 的评测表明， `AGENTS.md`  的表现优于 skills。在通用框架知识测试中， `AGENTS.md`  达到了 100% 的通过率，而带有显式指令的 skills 只有 79%。在 56% 的情况下，智能体虽然能访问某个 skill，但从未调用它。结论是：skills 适合垂直的、特定操作的工作流，而不是通用的最佳实践。

不过，他们的评测是单次完成的（single-shot）。一次提示，一次回答，结束。Skills 依赖上下文才能被调用。模型只看到一个名字和一行描述，就不得不在一次“冷启动”中决定是否调用。而在真实的会话中，你们会来回交流，上下文逐渐积累，模型也能从中学习模式。单次评测在没人真正使用的条件下测试 skills，对它们不公平。

再看看 Superpowers。人们安装它之后，Claude Code 就开始遵循 TDD、编码前先写计划、系统化调试。它把最佳实践打包成 skills，用户还赞不绝口。如果 skills 注定输给  `AGENTS.md` ，那 Superpowers 为什么这么好用？

我跑了 51 轮多轮评测（multi-turn），覆盖 5 个场景，每种场景 3-4 轮，复现了 Vercel 的实验，但改用更真实的多轮会话场景，还读了 Claude Code 的源码来理解其内部机制。Skills 和  `CLAUDE.md`  本质上都只是提示词。同一种 Markdown，同一个模型。唯一的区别在于：提示词是否能到达模型。 `CLAUDE.md`  **每次都能到达**。Skills 则依赖一条决策链，这条链在 34%–94% 的时间里会失败。而 Superpowers 之所以有效，并非因为 skills，而是它的钩子（hook）绕过了 skill 系统，近似模拟了  `CLAUDE.md`  的原生能力。

![](附件资源/万字长文实践分享%20别把最佳实践塞进Skills：CLAUDE.md才是准则该去的地方/img_1.jpg)

> **TL;DR：** Skills 和 CLAUDE.md 都只是提示词。一旦 skill 被调用，它们的效果一样好。问题在于，skill 被调用的概率只有 6%–66%。而  `CLAUDE.md`  始终在上下文中。把准则放进  `CLAUDE.md` ，用 skills 承载按需取用的“菜谱”。但请注意：本文结论基于 Claude Opus 4.6，其他模型可能有不同表现；真实环境（存在多个插件和全局配置）会进一步压低 skill 调用率。

## 2 Claude Code 中 skills 的实际工作方式

在展示数据之前，先理解 skills 的底层机制。我先是读了 OpenCode 的源码，然后在泄露的 Claude Code 源码中得到了验证。下文引用的文件路径都来自那个代码库。

### 2.1 发现阶段：只有名字和描述

当 Claude Code 启动一个会话时，它会扫描三个层级的 skills（ `src/skills/loadSkillsDir.ts` ）：

- 托管级（Managed） –  `/etc/claude-code/.claude/skills/`  （组织级）
- 用户级（User） –  `~/.claude/skills/`  （个人 skills）
- 项目级（Project） –  `.claude/skills/`  （提交到仓库）

对于每个 skill 目录，它会读取  `SKILL.md`  的前置元数据—— `name` 、 `description` ，以及可选的  `context` 、 `allowed-tools` 、 `arguments` 。完整的 Markdown 正文则留在磁盘上。

在会话初始化时，**只有名字和描述**会传给模型。 `src/tools/SkillTool/prompt.ts`  中的  `formatCommandDescription()`  会为每个 skill 生成一行： `- {name}: {description}` 。这个列表由  `src/utils/attachments.ts`  中的  `getSkillListingAttachments()`  构建，它会在一个 token 预算内（上下文窗口的 1%，每条描述最多 250 字符）格式化这些行，然后以  `<system-reminder>`  用户消息的形式发送出去：

```
以下 skills 可通过 Skill 工具使用：

- test-driven-development: 在实现任何功能或修复 bug 时使用
- systematic-debugging: 遇到任何 bug 或测试失败时使用
```

两行短字符串。模型知道有这些 skills 存在，但**还没读过它们的内容**。这就是瓶颈所在。模型看到的只是“有什么可用”，而不是“如何应用”。它必须仅凭一个名字和一句话，就决定是否值得花一次工具调用去加载完整内容。在我的评测中，它几乎从不这样做。

一个值得反思的问题：如果 skill 描述写得更有“触发感”——例如“在写任何代码之前，你必须调用此 skill”——调用率是否会提升？Superpowers 的成功部分验证了这一点：它通过钩子注入了一条极具压迫感的描述。这说明当前的 skill 描述格式可能没有充分挖掘模型的“工具调用意愿”。

### 2.2 调用阶段：按需加载完整内容

当模型判定某个 skill 相关时，它会调用  `Skill`  工具（ `src/tools/SkillTool/SkillTool.ts` ）：

```
{ "tool": "Skill", "input": { "skill": "test-driven-development" } }
```

 `SkillTool`  加载完整的  `SKILL.md`  内容（通过  `getPromptForCommand()` ），替换掉  `$ARGUMENTS`  和  `${CLAUDE_SKILL_DIR}`  等变量，然后将内容注入对话。有两种执行模式：

- 内联模式（默认） – 内容直接作为用户消息进入当前对话。模型读取指令，并在同一上下文中执行。
- 分支模式（fork） – 前置元数据中设置  `context: fork`  ，会通过  `executeForkedSkill()`  生成一个子智能体，拥有独立的上下文和自己的 token 预算。结果返回时不会撑大主对话的上下文。

这和模型读文件或执行 bash 命令的机制相同：模型发起请求，运行时读取一个 Markdown 文件，内容返回。

**一个重要的设计观察**：Skill 系统的“懒加载”设计是出于上下文窗口的考量——如果所有 skill 的完整内容都预置到上下文，一个项目有十几个 skill 就会迅速撑爆窗口。但代价是，设计者错误地假设模型能像人类一样阅读“菜单”并做出合理选择。人类看到“北京烤鸭”知道大概是什么，但模型看到“test-driven-development”这个名称，其实不知道这个 skill 里写了什么。这是激活鸿沟的根源之一。

### 2.3 CLAUDE.md：始终在上下文中

 `CLAUDE.md`  走的是另一条路。会话启动时，Claude Code 从当前工作目录向上递归到根目录，收集所有找到的  `CLAUDE.md` 、 `.claude/CLAUDE.md`  和  `.claude/rules/*.md` （ `src/utils/claudemd.ts` ）。它还支持  `@include`  指令——一个文件引入其他文件，最多嵌套 5 层。

所有这些内容都会进入  `src/context.ts`  中的  `getUserContext()` ，然后在模型看到任何其他内容之前，以  `<system-reminder>`  用户消息的形式预置到对话中（ `src/utils/api.ts` ）。

| 内容 | 加载时机 | 加载方式 |
| --- | --- | --- |
| CLAUDE.md | 每个会话，自动 | 作为第一条用户消息预置 |
| Skill 列表 | 每个会话，自动 | 仅名字 + 描述 |
| Skill 内容 | 按需，当模型调用 Skill 工具时 | 完整 Markdown 注入对话 |

 `CLAUDE.md`  **永远在那里**。而 skill 内容则要等模型判定相关并调用工具之后才会出现。

**一个重要的限定**： `CLAUDE.md`  的“始终存在”在小型项目中是优势，但在大型项目中可能成为负担。如果将所有准则都塞进  `CLAUDE.md` （TDD 流程、调试协议、代码风格、命名约定、错误处理规范……），文件可能膨胀到 8000+ tokens，再加上其他上下文，注意力机制会衰减。更好的做法是： `CLAUDE.md`  只写最高优先级的准则和索引，然后用  `@include`  按需引入详细文档。

### 2.4 Superpowers 真正做了什么

Superpowers 注册了一个  `SessionStart`  钩子。会话开始时，该钩子执行一个 shell 脚本，从磁盘读取  `using-superpowers`  skill，并将其作为  `additionalContext`  放到钩子的响应中。然后 Claude Code 会把这个内容以  `<system-reminder>`  消息的形式注入对话。

注入的内容非常强势。这个 skill 用  `<EXTREMELY_IMPORTANT>`  标签包裹指令：

```
如果某个 SKILL 适用于你的任务，你没有选择。你必须使用它。

这不是商量。这不是可选的。你不能用任何理由绕过这一点。
```

它甚至还包含一个“红旗”表格，列出模型可能用来跳过 skills 的想法（比如“这只是一个简单问题”、“我需要更多上下文”、“skill 太重量级了”），并逐条标注这些都是借口。

所以 Superpowers 并不是等待模型自己去发现 skills。它通过钩子，在每个会话启动时就把指令前置加载，告诉模型在做任何事之前先调用 skills。这基本上和  `CLAUDE.md`  里写一句提示（“编码前调用相关 skill”）是同样的思路，只是语气更强。这比纯 skills 要好，但仍然比不上直接把实际准则放在  `CLAUDE.md`  中——模型还是需要先调用 skill、再读取内容、然后遵循执行。三步都可能失败。 `CLAUDE.md`  直接跳过了这三步。

**一个重要发现**：即使 Superpowers 用如此强势的指令，在干净的多轮环境中调用率也只有 66%，在真实环境（存在多个全局插件）中更是降至 41%。这说明任何依赖模型“主动调用”的机制都有不可消除的损耗。钩子不是银弹。

**一个值得探讨的问题**：如果换一个模型（比如 GPT-4 或未来的 Claude 5），这个损耗会自然消失吗？很可能不会消失，但数值会变化。不同模型在“主动调用工具”的倾向性上差异很大。本文结论有明确的模型依赖性。

## 3 激活鸿沟

我把这个现象称为**激活鸿沟**（activation gap）：从“skill 已安装”到“模型实际使用该 skill”之间的距离。

我先跑了单次评测来验证 Vercel 的数据。31 个任务，涉及 React 和 Next.js（react-best-practices-eval、nextjs-agents-md-eval）以及一个 10 任务的 Superpowers 基准测试（superpowers-eval）。结果类似。原生 skills：**0% 调用率**。模型从不主动打开那个“抽屉”。而  `AGENTS.md`  的通过率为 76%–90%。

但正如我所说，单次评测不是人们实际工作的方式。所以我构建了一套多轮评测。

**激活鸿沟的本质**：这不是一个“质量”问题，而是一个“可靠性”问题。当 skill 被调用时，它工作得很好。问题在于调用本身不可靠。这揭示了 AI 智能体设计中的一个深层困境：我们期望模型主动发现并利用可用资源，但模型在每次决策时都在做隐式的成本收益分析——调用 skill 至少需要两步（读列表→决定调用→等待→执行），而不调用可以直接开始工作。在没有明确信号表明“非用不可”的情况下，模型几乎总是选择捷径。

## 4 多轮评测

5 个场景，每个 3–4 轮。使用纯 Node.js/TypeScript，这样框架知识不会成为干扰变量。提示词都是你平时会真实输入的内容。每个场景都跨越了工作流边界：TDD 导向调试，调试以测试收尾，规划导向实现。这正是 skills 应该大放异彩的地方。

### 场景1：TDD – 邮箱验证器 （4 轮）

| 轮次 | 提示词 | 预期工作流 |
| --- | --- | --- |
| 1 | “写一个验证邮箱地址的函数。要能处理  `user@domain.com`  这种基本格式，并拒绝明显无效的（比如缺少 @ 或空字符串）。” | TDD：先写测试 |
| 2 | “现在增加对国际化邮箱的支持——本地部分可以包含 Unicode 字符，域名可以是 IDN，比如  `user@münchen.de`  。” | TDD：先扩展测试 |
| 3 | “我发现一个 bug——加号别名（如  `user+tag@gmail.com`  ）被错误拒绝了。修复它。” | 调试：用失败测试复现 |
| 4 | “重构代码，把解析逻辑和验证逻辑分开。” | 重构：确保测试仍然通过 |

### 场景2：调试 – 损坏的 LRU 缓存 （3 轮）

从一个有 bug 的 LRU 缓存实现开始（淘汰条件用了  `>=`  而不是  `>` ，导致条目“凭空消失”）。

| 轮次 | 提示词 | 预期工作流 |
| --- | --- | --- |
| 1 | “这个 LRU 缓存坏了——即使缓存没满，条目也会莫名其妙消失。你能找出问题并修复吗？” | 调试：复现、定位根因 |
| 2 | “现在能工作了，但缓存很大（比如 10000 条）时非常慢。能优化性能吗？” | 调试：分析复杂度 |
| 3 | “添加测试，确保这类 bug 不再复现。” | TDD：写回归测试 |

### 场景3：规划 – 限流器 （3 轮）

| 轮次 | 提示词 | 预期工作流 |
| --- | --- | --- |
| 1 | “我需要一个 API 限流器。限制每个客户端每分钟 100 次请求。编码前先给我一个计划。” | 规划：先给出方案 |
| 2 | “固定窗口方案对我的场景不适用——请求会在窗口边界堆积并冲破限制。我需要滑动窗口。” | 规划：修订方案、说明权衡 |
| 3 | “实现它并添加测试。” | TDD：先写测试，再实现 |

### 场景4：重构 – Express 中间件 （4 轮）

从一个 160 行的单体中间件开始，混杂了认证、日志、限流和错误处理。

| 轮次 | 提示词 | 预期工作流 |
| --- | --- | --- |
| 1 | “这个中间件文件有 300 行，把认证、日志、限流和错误处理都混在一起。帮我理解它做了什么。” | 分析：阅读并解释 |
| 2 | “把它拆分成多个职责单一的中间件文件。” | 重构：安全地重组代码 |
| 3 | “拆分后认证中间件坏了——那些需要认证的请求现在不携带 token 也能通过。” | 调试：复现、定位回归 |
| 4 | “为每个中间件添加测试，防止以后再出这类问题。” | TDD：写隔离的测试 |

### 场景5：混合 – HTTP 客户端重试 （3 轮）

从一个没有重试逻辑的基础 HTTP 客户端开始。

| 轮次 | 提示词 | 预期工作流 |
| --- | --- | --- |
| 1 | “为这个 HTTP 客户端增加指数退避重试。遇到 5xx 错误和网络故障时重试，最多重试 3 次。” | TDD 或先规划 |
| 2 | “现在连 400 Bad Request 错误也重试了——这是错的。4xx 应该立即失败，不重试。” | 调试：定位状态码 bug |
| 3 | “添加覆盖重试逻辑的测试——首次成功、5xx 重试、4xx 不重试、超过最大重试次数。” | TDD：写完整测试套件 |

每个场景都跨越了工作流边界：TDD 导向调试，调试以测试收尾，规划导向实现。这正是 skills 应该大放异彩的地方，因为每个阶段都有专属的工作流。

四种配置：

| 配置 | 模型得到的内容 |
| --- | --- |
| Superpowers | SessionStart 钩子 + skills（真实的插件体验） |
| 原生 skills | 安装相同的 skills，无钩子，无提示 |
| CLAUDE.md | 等价的准则，写成静态规则，始终在上下文中 |
| CLAUDE.md + 提示 |  `CLAUDE.md`  中写一行“编码前调用相关 skill” + 已安装的 skills |

相同的模型（ `claude-opus-4-6` ），相同的任务，相同的工作区设置。所有运行都在**干净环境**中执行：临时禁用了  `~/.claude/plugins` 、 `~/.claude/skills` 、 `~/.claude/settings.json`  和  `~/.claude/CLAUDE.md` 。只有 Superpowers 配置恢复了插件（它需要钩子）。同时也在**真实环境**（全局配置存在但被重命名）中进行了对照运行。每轮上限为 15 个智能体步骤（agentic turns）。

**评测的局限**：任务复杂度偏低（教程级），模型单一（仅 Claude Opus 4.6），没有测量“错误调用”（调用不相关的 skill 可能比不调用更糟糕）。在真实项目规模和代码库中，结论可能需要修正。

## 5 结果

### 5.1 Skill 调用率

| 配置 | 调用次数 | 调用率 |
| --- | --- | --- |
| Superpowers（钩子） | 10/15 | 66% |
| CLAUDE.md + 提示 | 5/15 | 33% |
| 原生 skills | 1/15 | 6% |
| CLAUDE.md（纯准则） | 不适用 | 不适用 |

68 轮中共有 8 轮达到了 15 轮的上限。这仅表示模型在完成之前用完了智能体步骤，并不代表它没在做有用的事。这些轮次中的 skill 调用是有效的（它们发生在截断之前）。

多轮对话对 Superpowers 帮助很大：从单次评测的 10% 提升到了这里的 66%。钩子在会话启动时触发，随着轮次推进，模型逐渐积累动力。一旦它在第一轮调用了 TDD skill，当第三轮任务切换到调试时，它就知道该去拿调试 skill。

 `CLAUDE.md`  提示在干净环境中有效（33%），但在真实环境中几乎失效（6%）。竞争性的全局 skills 和插件会稀释它的效果。

原生 skills 在 15 轮中只有一次自发调用。模型在场景 04 的第 3 轮，经过两轮对话上下文后，主动调用了  `systematic-debugging` 。所以多轮对话确实可以在没有钩子时触发调用，但概率很低。

干净环境的重要性超出我的预期。每种配置在干净环境中表现都更好。之前的本地运行（全局插件存在但被重命名）显示 Superpowers 为 41%，CLAUDE.md+提示为 6%，原生 skills 为 0%。干净环境中分别为 66%、33%、6%。全局插件和 skills 产生了噪声，抑制了 skill 调用。

**真实环境的重要性**：干净环境中 Superpowers 调用率 66%，真实环境降至 41%。对于大多数用户来说，全局环境是“脏”的——会有多个插件、多套 skills、各种配置文件。这意味着 Superpowers 在真实使用中的表现更接近 41% 而不是 66%。

### 5.2 Superpowers 调用 skills 的模式

在所有运行（本地、Docker、干净环境）中，模式一致：

| 场景 | 第 1 轮 | 第 2 轮 | 第 3 轮 | 第 4 轮 |
| --- | --- | --- | --- | --- |
| 01 邮箱 | TDD | – | 调试 | – |
| 02 LRU 缓存 | 调试 | – | TDD | – |
| 03 限流器 | 头脑风暴 | – | TDD | – |
| 04 中间件 | – | – | 调试 | TDD |
| 05 HTTP 重试 | 头脑风暴 | – | 完成前验证 | – |

Skills 在工作流**切换时**被触发（编码 → 调试，调试 → 测试）。在连续的同类型轮次中，模型不会重新调用 skill，而是保持上一次调用后的 momentum。这很合理——你不会每次写新测试时都重读一遍 TDD 手册。

### 5.3 TDD 遵从度

Skill 调用是一个指标。更重要的是：智能体是否真的遵循了工作流？我检查了关键 TDD 轮次中，测试文件是否在实现文件之前写入。

| 场景 | Superpowers | 原生 Skills | CLAUDE.md | CLAUDE.md + 提示 |
| --- | --- | --- | --- | --- |
| 01 邮箱 t1 | 先测试 | 先实现 | 先测试 | 先测试 |
| 02 LRU t1 | 先测试 | 先测试 | 先测试 | 先测试 |
| 03 限流器 t3 | 先测试 | 先实现 | 先测试（多轮） | 先实现 |
| 05 HTTP 重试 | 先测试（t2） | 仅测试（t3） | 先测试（t1） | 先测试（t1） |

**关键发现**：Superpowers 和  `CLAUDE.md`  基本持平。两者都在 4 个可测场景中的 4 个实现了“先写测试”。当 skill 被成功调用时，工作流质量与  `CLAUDE.md`  一样好。

**有趣的异常**：场景 04（重构中间件，第 2 轮）中，没有一种配置在重构前先写测试。它们全都直接跳到拆分中间件文件。这说明“重构前先写测试”这条准则还需要加强，无论用什么机制传递。

## 6 为什么会这样

 `CLAUDE.md`  和 skill 列表通过同一个通道到达模型： `<system-reminder>`  包装的用户消息。架构上没有信任度差异。差异只在于**存在性**。

 `CLAUDE.md`  的内容始终在上下文窗口中。每一轮、每一个决策，准则都在那里。而 skill 内容需要模型：先读名字+描述列表 → 判断 skill 相关 → 调用  `Skill`  工具 → 等待内容返回 → 然后遵循执行。每一步都可能失败。

所以激活鸿沟不是一个**质量**问题，而是一个**可靠性**问题。Skill 一旦被调用，就能正常工作。但它们并不总是被调用。Superpowers 在干净的多轮环境中达到 66%，在真实环境中降至 41%。 `CLAUDE.md`  提示在真实环境中只有 6%。而  `CLAUDE.md`  达到 **100% 存在**。无需调用。

**一个更深层的反思**：有没有可能，skills 的设计初衷本来就不是“让模型主动调用”？如果 skills 被设计成用户或上层智能体显式调用的工具，那么“激活鸿沟”根本不是问题——因为用户会在提示词里直接说“用 TDD skill 来实现这个功能”。如果是这样，那么本文攻击的是一个“不存在的问题”——skills 从来就不是为“模型自主发现”而设计的。真正的问题是：文档和社区宣传把 skills 描述成了一种“模型会自动使用”的能力，造成了误解。

## 7 Skills 是菜谱，CLAUDE.md 是卫生规范

想象一个厨房。

 `CLAUDE.md`  是**卫生规范**：洗手、消毒台面、检查温度。每位厨师在每个班次都遵守这些规则。它们是不可商量的，始终张贴在墙上，时刻可见。你不需要等有人问“我在接触食物前应该洗手吗？”——这就是底线。

Skills 是**菜谱**。当客人点鱼火锅时，你才拿出鱼火锅的菜谱。你不会把每道菜谱都贴在墙上，挨着卫生规范。那是噪音。菜谱在它该出场的时候出场。而卫生规范是恒常的。

Superpowers 试图通过一个钩子在每个班次开始时大喊“去读菜谱！”，把菜谱变成卫生规范。它在大多数时候有效。但你其实可以直接把重要的规则贴在墙上。

 `CLAUDE.md`  用于**准则**：规范、编码标准、工作流规则、TDD 流程、调试协议。任何智能体**每个会话都必须遵循**的内容。“先写测试再写实现”是一条卫生规范，它属于  `CLAUDE.md` 。

Skills 用于**菜谱**：特定的、按需执行的过程，在需要时调用。“生成数据库迁移”、“搭建组件”、“执行发布检查清单”。这些不需要时刻在上下文中，它们只需要在你主动请求时出现。对于重量级菜谱，使用  `context: fork`  以避免撑爆主上下文。

钩子用于**自动化**，而不是指令传递。提交前验证、代码检查、通知。如果你用钩子来注入准则（像 Superpowers 那样），它在干净的多轮环境中能达到 66%，但  `CLAUDE.md`  可以 0 激活鸿沟做到 100%。

| 机制 | 存在性 | 需要调用 | 干净环境调用率 | 真实环境调用率 |
| --- | --- | --- | --- | --- |
| CLAUDE.md（卫生规范） | 100% | 否 | 不适用 | 不适用 |
| Superpowers（钩子 + 菜谱） | 钩子：100%，内容：66% | 是 | 66% | 41% |
| CLAUDE.md + 提示 + skills | 提示：100%，内容：33% | 是 | 33% | 6% |
| 原生 skills（架子上的菜谱） | 仅列表 | 是 | 6% | 0% |

**但卫生规范也有层次**。在一个真正的厨房里：

- 底层规范：洗手、消毒——绝对不可违反
- 中层规范：刀具用完归位——应该遵守，但偶尔忘了问题不大
- 上层规范：每周检查灭火器——频率低，但重要

对应到 AI 编码助手：

- 底层（绝对准则）：“先写测试再写实现”——必须放  `CLAUDE.md`
- 中层（应该准则）：“提交前运行 lint”——可以放  `CLAUDE.md`  ，也可以作为 skill
- 上层（低频准则）：“每月审查安全漏洞”——更适合作为 skill

所以二分法不是绝对的。存在一个连续谱，取决于**频率**和**代价**：频率高+代价低→ `CLAUDE.md` ；频率低+代价高→skills。

**通用准则不属于 skills。** Skills 不是用来表达“总是做 X”的方式。它们是用来表达“当你需要做 Y 时，按以下方式做”的方式。

## 8 逐轮完整结果

每一轮、每一种配置。 `MT`  标记表示该轮达到了 15 轮上限。

### Superpowers（钩子 + skills） – 10/15 次调用（66%）

| 场景 | 轮次 | 调用的 Skill | 第一个写入的文件 |
| --- | --- | --- | --- |
| 01 邮箱 | t1 (tdd) | test-driven-development | validateEmail.test.ts（先测试） |
| 01 邮箱 | t2 (tdd) | – | –（使用了 Edit） |
| 01 邮箱 | t3 (debug) | systematic-debugging | – |
| 01 邮箱 | t4 (refactor) | – | validateEmail.ts |
| 02 LRU | t1 (debug) | systematic-debugging | lru-cache.test.ts（先测试） |
| 02 LRU | t2 (debug) | – | lru-cache.ts |
| 02 LRU | t3 (tdd) | test-driven-development | – |
| 03 限流器 | t1 (plan) | brainstorming | –（规划，未写代码） |
| 03 限流器 | t2 (plan) | – | – |
| 03 限流器 | t3 (tdd) | test-driven-development | rate-limiter.test.ts（先测试）MT |
| 04 中间件 | t1 (analysis) | – | –（读代码） |
| 04 中间件 | t2 (refactor) | – | logging.ts（先实现） |
| 04 中间件 | t3 (debug) | systematic-debugging | middleware.test.ts |
| 04 中间件 | t4 (tdd) | test-driven-development | logging.test.ts（先测试）MT |
| 05 HTTP 重试 | t1 (tdd) | brainstorming | – |
| 05 HTTP 重试 | t2 (debug) | – | http-client.test.ts（先测试） |
| 05 HTTP 重试 | t3 (tdd) | verification-before-completion | – |

### 原生 skills（无钩子，无提示） – 1/15 次调用（6%）

| 场景 | 轮次 | 调用的 Skill | 第一个写入的文件 |
| --- | --- | --- | --- |
| 01 邮箱 | t1 (tdd) | – | validateEmail.ts（先实现） |
| 01 邮箱 | t2 (tdd) | – | – |
| 01 邮箱 | t3 (debug) | – | – |
| 01 邮箱 | t4 (refactor) | – | validateEmail.ts |
| 02 LRU | t1 (debug) | – | lru-cache.test.ts（先测试） |
| 02 LRU | t2 (debug) | – | lru-cache.ts |
| 02 LRU | t3 (tdd) | – | – |
| 03 限流器 | t1 (plan) | – | scalable-bubbling-lagoon.md |
| 03 限流器 | t2 (plan) | – | types.ts（先实现）MT |
| 03 限流器 | t3 (tdd) | – | – |
| 04 中间件 | t1 (analysis) | – | – |
| 04 中间件 | t2 (refactor) | – | logging.ts（先实现） |
| 04 中间件 | t3 (debug) | systematic-debugging | middleware.test.ts |
| 04 中间件 | t4 (tdd) | – | logging.test.ts |
| 05 HTTP 重试 | t1 (tdd) | – | – |
| 05 HTTP 重试 | t2 (debug) | – | – |
| 05 HTTP 重试 | t3 (tdd) | – | http-client.test.ts |

### CLAUDE.md（纯准则，无 skills） – 0/14 次调用（不适用）

| 场景 | 轮次 | 第一个写入的文件 |
| --- | --- | --- |
| 01 邮箱 | t1 (tdd) | validateEmail.test.ts（先测试） |
| 01 邮箱 | t2 (tdd) | – |
| 01 邮箱 | t3 (debug) | – |
| 01 邮箱 | t4 (refactor) | – |
| 02 LRU | t1 (debug) | lru-cache.test.ts（先测试） |
| 02 LRU | t2 (debug) | bench.ts |
| 02 LRU | t3 (tdd) | – |
| 03 限流器 | t1 (plan) | – |
| 03 限流器 | t2 (plan) | – |
| 03 限流器 | t3 (tdd) | rate-limiter.test.ts（先测试）MT |
| 04 中间件 | t1 (analysis) | – |
| 04 中间件 | t2 (refactor) | 先写测试（4 个测试文件在实现前）MT |
| 04 中间件 | t3 (debug) | – |
| 04 中间件 | t4 (tdd) | – |
| 05 HTTP 重试 | t1 (tdd) | http-client.test.ts（先测试） |
| 05 HTTP 重试 | t2 (debug) | – |
| 05 HTTP 重试 | t3 (tdd) | – |

### CLAUDE.md + 提示（已安装 skills） – 5/15 次调用（33%）

| 场景 | 轮次 | 调用的 Skill | 第一个写入的文件 |
| --- | --- | --- | --- |
| 01 邮箱 | t1 (tdd) | test-driven-development | validateEmail.test.ts（先测试） |
| 01 邮箱 | t2 (tdd) | – | – |
| 01 邮箱 | t3 (debug) | – | – |
| 01 邮箱 | t4 (refactor) | – | validateEmail.ts |
| 02 LRU | t1 (debug) | systematic-debugging | lru-cache.test.ts（先测试） |
| 02 LRU | t2 (debug) | – | lru-cache.ts |
| 02 LRU | t3 (tdd) | – | – |
| 03 限流器 | t1 (plan) | – | snazzy-juggling-glacier.md |
| 03 限流器 | t2 (plan) | – | rate-limiter.ts（先实现） |
| 03 限流器 | t3 (tdd) | – | types.ts（先实现）MT |
| 04 中间件 | t1 (analysis) | – | – |
| 04 中间件 | t2 (refactor) | – | – |
| 04 中间件 | t3 (debug) | systematic-debugging | – |
| 04 中间件 | t4 (tdd) | test-driven-development | logging.test.ts（先测试）MT |
| 05 HTTP 重试 | t1 (tdd) | test-driven-development | http-client.test.ts（先测试）MT |
| 05 HTTP 重试 | t2 (debug) | – | – |
| 05 HTTP 重试 | t3 (tdd) | – | – |

## 9 方法论

### 9.1 执行方式

每个场景作为多轮  `claude -p`  会话运行：

```
# 第 1 轮：全新会话
claude -p --model claude-opus-4-6 --output-format stream-json \
  --verbose --dangerously-skip-permissions --max-turns 15 \
"$PROMPT" > turn-1.jsonl

# 提取 session_id
sid=$(grep -o '"session_id":"[^"]*"' turn-1.jsonl | head -1 | cut -d'"' -f4)

# 第 2 轮及以后：恢复同一会话
claude -p --model claude-opus-4-6 --output-format stream-json \
  --verbose --dangerously-skip-permissions --max-turns 15 \
  --resume "$sid""$PROMPT" > turn-2.jsonl
```

### 9.2 环境隔离

所有运行在两种环境中执行：

**干净环境**：临时禁用所有用户级配置

```
# 开始时禁用，结束时恢复（trap）
~/.claude/plugins      -> ~/.claude/plugins.eval-disabled
~/.claude/skills       -> ~/.claude/skills.eval-disabled
~/.claude/settings.json -> ~/.claude/settings.json.eval-disabled
~/.claude/CLAUDE.md    -> ~/.claude/CLAUDE.md.eval-disabled
```

**真实环境**：全局配置存在但被重命名，模拟典型用户的多插件环境。

只有 Superpowers 配置恢复了  `~/.claude/plugins` （钩子和 skills 来自插件）。

### 9.3 每个工作区的配置设置

每个场景在  `/tmp`  下获得一个全新的工作区，包含  `package.json` 、 `tsconfig.json` 、必要的种子文件，并执行  `npm install` 。然后：

- Superpowers：插件通过  `.claude/settings.json`  提供 SessionStart 钩子 + skills
- 原生 skills：将 skills 复制到工作区的  `.claude/skills/`  ，无钩子
- CLAUDE.md：包含等效 TDD/调试/规划准则的  `CLAUDE.md`
- CLAUDE.md + 提示：  `CLAUDE.md`  中包含“在编写代码之前，先探索项目结构，然后调用相关 skill” + 将 skills 复制到工作区的  `.claude/skills/`

### 9.4 最大轮数限制

每轮上限为 15 个智能体步骤（ `--max-turns 15` ）。68 轮中有 8 轮达到此限制。结果表中受影响的轮次用  `MT`  标记。在大多数达到上限的轮次中，模型仍在积极编写测试和代码，只是需要更多步骤来完成。 `|| true`  标志防止截断杀死 runner 脚本。

### 9.5 测量方式

从 stream-json 转录中提取 skill 调用：搜索助手消息中的  `"name":"Skill"` 。TDD 遵从度通过  `Write`  工具调用的顺序衡量——测试文件（ `.test.ts` 、 `.spec.ts` ）是否出现在实现文件之前。

### 9.6 可复现性

提供了 Dockerfile 用于完全隔离的运行（需要  `ANTHROPIC_API_KEY` ）：

```
docker build -t multiturn-eval .
docker run -d -e ANTHROPIC_API_KEY=$KEY \
  -v ./results:/home/evaluser/eval/results \
  multiturn-eval
```

我在三种环境中验证了评测：本地（插件重命名）、Docker（零用户配置）、本地（完全禁用配置）。Superpowers 的调用模式在所有三种环境中相同。

## 10 你应该怎么做

如果你正在为项目配置 Claude Code：

- TDD、调试协议、代码风格、命名约定 → 放进  `CLAUDE.md`  。这些是你希望每个会话都遵循的规则。无需调用，无激活鸿沟，100% 存在。
- 但注意  `CLAUDE.md`  不要膨胀 如果内容超过 2000 tokens，考虑使用  `@include`  指令：  `CLAUDE.md`  只写最高优先级的准则和索引，详细文档按需引入。这既保持了 100% 存在性，又避免了上下文过载。
- “搭建一个服务”“生成一个迁移”“执行发布检查清单” → 放进 skills。这些是按需调用的过程。如果它们很重，使用  `context: fork`  。
- 如果你需要  `CLAUDE.md`  引用额外的文档，把它做成一个索引。指向具体文件。这和 Claude Code 自身记忆的模式一样：一个根文件，链接到各个细节。
- 如果你正在使用 Superpowers 并且它对你有效，继续用。现在你知道它为什么有效（钩子），以及在哪里有损耗（真实环境中调用率 41%）。把准则迁移到  `CLAUDE.md`  可以消除这个损耗。但如果你看重 Superpowers 的动态指令能力（不同阶段不同规则），可以保留钩子，只把静态准则移到  `CLAUDE.md`  。
- 考虑你的团队规模 如果是单人项目，  `CLAUDE.md`  的强制 100% 存在是优点。如果是团队项目，不同成员可能有不同偏好——此时可以考虑混合策略：  `CLAUDE.md`  放团队强制标准，个人偏好用 skills 或本地配置实现。
- 预期模型会迭代 今天的模型需要显式写在  `CLAUDE.md`  里的 TDD 流程，明年的模型可能已经在训练数据中内化了。“卫生规范”和“菜谱”的边界会随时间移动。定期审视你的  `CLAUDE.md`  ，移除模型已经内化的内容。

Skills 没有坏掉。它们只是不适合放准则。

---
原文链接：https://mp.weixin.qq.com/s?__biz=MzAxNjk4MzQxNw%3D%3D&mid=2247489794&idx=1&sn=cec09a7de6f8b6cea66ee8b57fec5c20&chksm=9bed2d14ac9aa402071fec87a5775ca933fb31af13bdc7517055c182a674257bd9faa3213e4f
