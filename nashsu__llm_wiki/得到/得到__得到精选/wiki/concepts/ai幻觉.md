---
type: concept
title: AI幻觉
tags: [AI可信度, 大语言模型, DeepSeek, 信息风险]
related: [three-categories-of-information, ai-generalization, yishi-yu-renji-chayi, ren-bi-ai-xiong]
created: 2026-08-07
updated: 2026-08-07
sources: ["得到精选/MD/797.DeepSeek高级心法 为什么你的AI总是不听话.md"]
---

# AI幻觉

AI幻觉（Hallucination）指大语言模型在缺乏正确信息的情况下，生成貌似合理却与事实不符的输出，即“自以为知道但不知道，于是瞎说”的现象。万维钢在新书推广中指出：当前最先进的AI也未彻底解决幻觉问题，且可能永远无法根除。

幻觉是用户感到“AI不听话”的核心原因之一——许多问题的答案表面上看似专业，实则是AI的虚构。不应因此全盘否定AI，而应基于对AI知识边界的理解来管理风险。

## 应对策略

关键方法是对问题进行信息分类，见 [[three-categories-of-information|信息三类分类法]]：
- 属于“旧/标准/专家皆知”的信息，AI通常可靠。
- 属于“近一两年新公开”的信息，AI很可能不知，需联网搜索并核查原始资料。
- 属于“本地/隐性/不可事先知道”的信息，必须由人提供。

进一步降低风险的措施包括设置“人类签字页”（参见 [[human-sign-off-page]]），明确高风险决策必须由人类复核。

## 与相关概念的关系

- AI幻觉暴露了模型的“意识与人格”缺失（见 [[yishi-yu-renji-chayi|意识与人机差异]]），它并非有意欺骗，而是缺乏自我认知。
- 它也提醒我们，AI的泛化能力（见 [[ai-generalization]]）需建立在可靠信息基础上，否则幻觉会污染创造性输出。