---
tags: [GBrain, Agent Wiki, Garry Tan, 个人知识库]
created: 2026-07-24
updated: 2026-07-24
sources: [2026-07-22-Agent-Wiki现状与解析]
---

# GBrain

> Garry Tan 开源的 [[Agent Wiki]] 实现，将 LLM Wiki 模式应用于个人知识库，最简洁地证明了该模式的本质简单性。

## 正文

GBrain 是 Garry Tan 对 [[LLM Wiki]] 模式的个人规模开源实现。它将相同的形式应用于个人知识库而非代码库。

### 极简设计

GBrain 最清楚地证明了该模式的本质简单性：

- Git 仓库中的 Markdown 文件
- 一个模式文件（brain.yaml）定义组织方式
- 一个自动维护的实体交叉链接图
- 没有向量数据库，没有服务，只有文件——由模型维护，人类可读

### 技术特点

- 语料库：个人知识库
- 模式文件：brain.yaml
- 刷新方式：按需
- 输出格式：仓库的 MD

### 意义

GBrain 证明了 Agent Wiki 模式不需要复杂的基础设施。在最简形式下，它只是"Git 仓库中的 Markdown + 模型遵循的模式文件 + 自动维护的交叉链接"。

## 相关页面

- [[Agent Wiki]]
- [[LLM Wiki]]
- [[DeepWiki]]
- [[AutoWiki]]
- [[OpenWiki]]
- [[知识编译]]
