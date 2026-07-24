---
tags: [Agent Wiki, LLM Wiki, AI编程工具, 知识管理]
created: 2026-07-24
updated: 2026-07-24
sources: [2026-07-22-Agent-Wiki现状与解析]
---

# Agent Wiki

> LLM Wiki 模式在社区中演化出的统称，指利用 AI Agent 自动维护持久化知识库的一类系统。

## 正文

Agent Wiki 是 [[LLM Wiki]] 模式在 2026 年社区实践中逐步形成的统称。在 Karpathy 发布 LLM Wiki 的 Gist 之后，多个团队独立实现了相同架构的系统，这一品类被简称为 Agent Wiki。

### 与 LLM Wiki 的关系

LLM Wiki 是 Karpathy 提出的原始概念和模式定义，Agent Wiki 是该模式在实际工程中的实现品类。两者的核心思想一致：AI Agent 在摄入时编译知识为持久化页面，而非每次查询时从原始资料重新推导。

### 主要实现

截至 2026 年中，已有四个独立实现：

| 实现 | 团队 | 特点 |
|------|------|------|
| [[DeepWiki]] | Cognition | 面向公共 GitHub 仓库，已索引 50,000+ 仓库 |
| [[AutoWiki]] | Factory | 文档作为 CI 构建产物，自动刷新 |
| [[OpenWiki]] | LangChain | 开源 CLI，支持 Code Brain 和 Personal Brain |
| [[GBrain]] | Garry Tan | 个人规模开源实现，最简洁 |

### 趋同信号

四个团队、四种语料库、同一架构（Git 中的 Markdown + 模式文件 + 摄入时合成 + 变更时刷新 + 为 Agent 阅读而编写），这种跨团队的结构性趋同被视为该模式正确性的最有力证据。

### 关键区分

Agent Wiki 解决的是**语料库知识**问题（"这份材料包含什么"），而非**用户经验记忆**问题（"我上周二改变了什么决定"）。后者需要像 Mem0 这样的专用记忆层。两者互补，不可混为一谈。

## 相关页面

- [[LLM Wiki]]
- [[知识编译]]
- [[DeepWiki]]
- [[AutoWiki]]
- [[OpenWiki]]
- [[GBrain]]
- [[AI编程工具]]
