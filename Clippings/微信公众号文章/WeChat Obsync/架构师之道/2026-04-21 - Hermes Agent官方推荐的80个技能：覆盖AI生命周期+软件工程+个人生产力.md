---
source_url: "https://mp.weixin.qq.com/s?__biz=MzAxNjk4MzQxNw%3D%3D&mid=2247489934&idx=1&sn=a2a8311d34f04578339dfaf00c585014&chksm=9bed2d98ac9aa48eba55b22640bc48ee30aaec7f1cb4ad59ccf236886c4138e0496bbd368c82"
title: "Hermes Agent官方推荐的80个技能：覆盖AI生命周期+软件工程+个人生产力"
account: "架构师之道"
published_at: "2026-04-21 00:01:00"
saved_at: "2026-10-20 01:07:35"
sync_id: "art_59ea2f5df4de4621b06e3f5a3ee7d9bc"
parse_status: "ok"
---

# Hermes Agent官方推荐的80个技能：覆盖AI生命周期+软件工程+个人生产力

Hermes Agent 在0.10.0版中，官方列出了值得预装的 **80 个技能**，它们不仅仅是“功能列表”，更是一张**现代 AI 驱动型开发者的能力地图**。

![](附件资源/Hermes%20Agent官方推荐的80个技能：覆盖AI生命周期+软件工程+个人生产力/img_1.png)

现在我来帮你从几个关键视角拆解、归类并提炼其设计哲学，让你快速理解“为什么是这些技能”以及“如何用好它们”。

## 一、整体格局：80 个技能，覆盖 AI 生命周期 + 软件工程 + 个人生产力

从分类来看，Hermes 团队显然在构建一个 **全栈 AI 工程师** 的助手工具包。技能不是随意堆砌，而是围绕 **四大核心任务流** 设计：

- AI/ML 模型开发与部署 →  `mlops`  (22个) +  `creative`  (部分)
- 软件工程协作与自动化 →  `github`  (6) +  `software-development`  (6) +  `autonomous-ai-agents`  (4)
- 信息获取与研究 →  `research`  (5) +  `media`  (4) +  `data-science`  (3)
- 个人与团队生产力 →  `productivity`  (6) +  `note-taking`  +  `email`  +  `smart-home`

这种分布暗示：Hermes 的定位是 **“可编程的副驾驶”**——既能帮你写代码、调模型，也能替你看论文、回邮件、控制灯光，甚至绕过 LLM 安全限制（ `godmode` ）。

## 二、最值得关注的 3 个“元技能” (Meta-Skills)

这类技能不直接产出代码或数据，而是**改变你使用 Hermes 的方式**。它们是杠杆：

| 技能 | 作用 | 为什么重要 |
| --- | --- | --- |
|  `plan`  | 先检查上下文，再生成 markdown 计划 | 避免盲目执行，强制结构化思考 |
|  `subagent-driven-development`  | 用独立子智能体执行子任务 | 并行处理、隔离上下文、提升可靠度 |
|  `systematic-debugging`  | 4 阶段根因调试法 | 将调试从“碰运气”变成可复现流程 |

**建议**：任何复杂任务前，先用  `plan`  拆解，再用  `subagent-driven-development`  分配子任务——这是 Hermes 推荐的高阶工作流。

## 三、AI 工程能力最集中的  `mlops`  类别（22 个）

这几乎是 **LLM 全栈工程的标准教材目录**。按功能可再分 5 层：

### 1. 模型微调与优化

-  `unsloth`  、  `peft-fine-tuning`  、  `axolotl`  、  `fine-tuning-with-trl`  、  `grpo-rl-training`  → 覆盖 LoRA、QLoRA、RLHF、GRPO，从快速微调到强化学习全链路。

### 2. 推理与服务

-  `llama-cpp`  (CPU/Apple Silicon)
-  `vllm`  (高性能服务)
-  `modal-serverless-gpu`  (云弹性)
-  `gguf-quantization`  (模型压缩)

### 3. 结构化输出与控制

-  `outlines`  、  `guidance`  → 用正则/语法约束生成格式
-  `obliteratus`  → 移除安全对齐（红队用途）

### 4. 多模态与专项模型

-  `whisper`  (语音→文字)
-  `clip`  (图文匹配)
-  `segment-anything-model`  (图像分割)
-  `audiocraft`  、  `stable-diffusion`  (生成音频/图像)

### 5. 实验管理

-  `weights-and-biases`  、  `huggingface-hub`

> 💡 **实战解读**：如果你要做 LLM 应用，这个技能树直接告诉你：微调用  `unsloth` / `axolotl` ，量化用  `gguf` ，本地推理用  `llama-cpp` ，云端服务用  `vllm`  或  `modal` ，控制输出用  `outlines` ——Hermes 已经帮你选型了。

## 四、自动化与智能体：从“工具”到“AI智能体”

 `autonomous-ai-agents`  包含  `claude-code` 、 `codex` 、 `opencode` ，以及  `hermes-agent`  自身。这意味着：

- Hermes 可以 调用其他 CLI 智能体 来完成任务（比如让 Claude Code 写代码，Hermes 只做协调）
- 这是一种 多智能体编排 模式——每个智能体有自己擅长的工作负载，Hermes 作为控制层。

再加上  `mcp`  (Model Context Protocol) 相关技能（ `native-mcp` 、 `mcporter` ），Hermes 实际遵循 **MCP 标准** 来连接外部工具和数据源。这是 Anthropic 推动的生态，说明 Hermes 意图融入更大的智能体互操作网络。

## 五、软件工程实践：超越“写代码”

 `software-development`  类别除了常规的 TDD、代码审查，还有 ** `requesting-code-review` **（提交前验证）和 ** `writing-plans` **（实施计划）。结合  `github`  下的 PR 工作流、issue 管理，Hermes 试图覆盖 **从 idea → plan → code → review → merge** 的完整闭环。

值得注意的是 ** `dogfood` **（Web 应用系统性 QA 测试）和 ** `codebase-inspection` **（用 pygount 检查代码库）——这表明 Hermes 也能做质量度量与自动化测试。

## 六、研究与知识管理：AI 时代的“第二大脑”

-  `arxiv`  +  `blogwatcher`  +  `llm-wiki`  → 自动拉取论文、追踪博客，并构建 markdown 知识库
-  `jupyter-live-kernel`  → 在对话中执行 Python 并保留状态（数据分析利器）
-  `research-paper-writing`  → 专门为 ML/AI 论文写作设计的流程

这组技能让 Hermes 成为一个 **研究助理**：你可以说“帮我追踪本周 arxiv 上关于 RLHF 的论文，总结并存入 my-llm-wiki”。

## 七、值得注意的“非主流”技能（但很实用）

| 技能 | 场景 |
| --- | --- |
|  `godmode`  | 红队测试、安全研究（需谨慎使用） |
|  `pokemon-player`  | 自动化游戏测试/教学演示 |
|  `wechat-mp-crawler`  | 获取公众号文章（合规前提下） |
|  `openhue`  | 用自然语言控制灯光——AI 走向物理世界 |
|  `polymarket`  | 查询预测市场数据（用于决策参考） |

这些技能暴露了 Hermes 的设计原则：**不设边界**——只要能通过 API/CLI 控制，就做成技能。

## 八、如何高效学习与使用这 80 个技能？

### 第一步：按角色筛选

- AI 研究员 → 优先  `mlops`  +  `research`  +  `jupyter-live-kernel`
- 全栈工程师 → 优先  `software-development`  +  `github`  +  `autonomous-ai-agents`
- 产品经理/分析师 → 优先  `productivity`  +  `notion`  +  `google-workspace`  +  `ocr-and-documents`
- 安全/红队 →  `godmode`  +  `obliteratus`  +  `systematic-debugging`

### 第二步：组合使用

典型高阶用法：

```
plan → (拆解出 3 个子任务) → subagent-driven-development
→ 子任务 A: 用 codex 写 API
→ 子任务 B: 用 unsloth 微调模型
→ 子任务 C: 用 github-pr-workflow 提交代码
→ 最后用 research-paper-writing 生成文档
```

### 第三步：扩展与自定义

Hermes 技能本质上是对 CLI 工具、API 或脚本的封装。你可以参考  `native-mcp`  和  `mcporter`  的机制，**将自己的常用工具也封装成新技能**。

## 总结：Hermes 技能树的核心隐喻

> **Hermes 不是一个“什么都会一点”的聊天机器人，而是一套可编程、可组合、可扩展的 AI 操作系统接口。**

- 80 个技能 = 80 个经过验证的“原子能力”
- 类别分布 = 现代 AI 工程师需要涉足的所有领域
- 元技能（plan, subagent-driven-development） = 控制流，让你能编排原子能力

你不需要一次性记住所有技能。只要理解 **“遇到什么问题 → 应该查阅哪个分类 → 调用哪个技能”**，你就能把 Hermes 用到飞起。

---
原文链接：https://mp.weixin.qq.com/s?__biz=MzAxNjk4MzQxNw%3D%3D&mid=2247489934&idx=1&sn=a2a8311d34f04578339dfaf00c585014&chksm=9bed2d98ac9aa48eba55b22640bc48ee30aaec7f1cb4ad59ccf236886c4138e0496bbd368c82
