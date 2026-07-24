---
tags: [OpenWiki, Agent Wiki, LangChain, 开源]
created: 2026-07-24
updated: 2026-07-24
sources: [2026-07-22-Agent-Wiki现状与解析]
---

# OpenWiki

> LangChain 开源的 [[Agent Wiki]] 实现，从代码库文档跨越到个人知识库编译，支持 Code Brain 和 Personal Brain 两种模式。

## 正文

OpenWiki 是 LangChain 对 [[LLM Wiki]] 模式的开源实现，其最重要的贡献是将 Agent Wiki 的范畴从"记录我的仓库"扩展到"编译我的工作生活"。

### 两种模式

- **Code Brain**：原始的代码仓库用例——为代码库编写和维护 Agent 文档。
- **Personal Brain**：从用户自己的连接来源（Gmail、Notion、Git 仓库、X/Twitter、Hacker News 和网络搜索）摄入信息，合成为一个供 Agent 查阅的本地 Markdown Wiki。

### 设计共识

OpenWiki 的输出设计反映了一个所有团队达成的共识：**输出不是供人类阅读的散文，而是针对 LLM 上下文优化的结构化 Markdown**——包含标题、交叉引用和摘要，设计目的是使 Agent 能快速找到相关上下文。Wiki 是为实际阅读它的读者编写的，而这个读者是模型本身。

### 定位为记忆层

LangChain 将 OpenWiki 描述为"AI Agent 的 Wiki 记忆层"。这一表述有启发性但也有误导风险：它覆盖了语料库知识编译和用户经验记忆两个不同维度。详见 [[RAG vs Wiki]]。

### 技术特点

- 模式文件：config.yaml
- 刷新方式：按需
- 输出格式：本地目录的 MD

## 相关页面

- [[Agent Wiki]]
- [[LLM Wiki]]
- [[DeepWiki]]
- [[AutoWiki]]
- [[GBrain]]
- [[知识编译]]
