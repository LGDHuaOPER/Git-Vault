---
tags: [DeepWiki, Agent Wiki, Cognition, AI编程工具]
created: 2026-07-24
updated: 2026-07-24
sources: [2026-07-22-Agent-Wiki现状与解析]
---

# DeepWiki

> Cognition 实现的 [[Agent Wiki]]，面向 GitHub 上每个公共仓库自动生成可导航的知识库，已索引超过 50,000 个顶级公共仓库。

## 正文

DeepWiki 是 Cognition（Devin 的开发团队）基于 [[LLM Wiki]] 模式构建的公共设施。它的核心创新在于**规模**和**定位**。

### 核心特性

- **面向公共仓库**：在任何公共 GitHub 仓库 URL 中将 `github.com` 替换为 `deepwiki.com`，即可获得该代码库的 AI 生成且可导航的 Wiki。
- **生成内容**：架构概览、文件索引、依赖关系图、搜索功能，以及返回源码的链接。
- **真实规模**：从 MCP 到 LangChain，超过 50,000 个顶级公共仓库已被索引。

### 定位：Agent 的检索基础设施

DeepWiki 并非产品的终点，而是 **Agent 的检索基础设施**。Devin 使用 Wiki 在代码库中定位相关上下文，因此 DeepWiki 是编译层，使 Devin 的代码搜索更有依据。

### 技术特点

- 模式文件：推断的（自动识别仓库结构）
- 刷新方式：按需
- 输出格式：面向 Agent 优化的 HTML/MD

## 相关页面

- [[Agent Wiki]]
- [[LLM Wiki]]
- [[AutoWiki]]
- [[OpenWiki]]
- [[GBrain]]
- [[知识编译]]
