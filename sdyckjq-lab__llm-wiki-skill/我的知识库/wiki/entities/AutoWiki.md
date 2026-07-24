---
tags: [AutoWiki, Agent Wiki, Factory, CI/CD]
created: 2026-07-24
updated: 2026-07-24
sources: [2026-07-22-Agent-Wiki现状与解析]
---

# AutoWiki

> Factory 实现的 [[Agent Wiki]]，将文档定位为构建产物，通过 CI 自动刷新，拥有最明确的工程化方法。

## 正文

AutoWiki 是 Factory 对 [[LLM Wiki]] 模式的实现，其核心主张是：**文档应该是构建产物，而不是副项目**。

### 工程化方法

AutoWiki 在四个实现中拥有最明确的工程化方法：

- **两遍分析**：第一遍对 README、包清单、CI 配置和入口点进行结构扫描；第二遍对路由、API 端点、服务类、数据库模式和特性开关进行更深入的语义扫描。
- **专门 Agent 分工**：工作被分配给专门的 Agent，每个 Agent 只负责仓库的一个方面，并有足够的上下文来生成高质量页面。这直接回应了单 Agent 文档生成在大规模下的上下文问题。
- **时效性作为基础设施**：`/wiki` 按需重新生成；`/install-wiki` 编写 CI 工作流，在每次推送到默认分支时刷新 Wiki。对于 GitHub 仓库，同步到仓库自己的 Wiki 标签页。

### 核心洞察

Factory 将过时视为构建问题而非纪律问题，并在 CI 中解决。这意味着 Wiki 始终保持最新——这正是其他按需刷新实现的最大弱点。**一个过时的维基比没有维基更糟糕，因为它以一种看起来权威的格式自信地出错。**

### 技术特点

- 模式文件：AGENTS.md
- 刷新方式：CI 推送（每次 push 自动刷新）
- 输出格式：仓库 Wiki 的 MD

## 相关页面

- [[Agent Wiki]]
- [[LLM Wiki]]
- [[DeepWiki]]
- [[OpenWiki]]
- [[GBrain]]
- [[知识编译]]
