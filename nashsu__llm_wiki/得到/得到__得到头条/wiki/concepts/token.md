---
type: concept
title: Token
created: 2026-08-01
updated: 2026-08-01
tags: [ai, 计量单位, token]
related: [token-economics, token-factory, token-tiered-pricing, token-efficiency, openai, alibaba]
sources: ["得到头条/MD/1271.868｜黄仁勋一直说的“Token经济学”，到底是什么意思？.md"]
---

# Token

Token（词元）是AI能理解、处理、输出的最小信息单元。它是理解Token经济学的基石概念。

## 定义

Token是一个语言的计量单位，常被翻译成“词元”。例如，“今天天气怎么样？”这句话会被切成几个Token：“今天”是一个Token，“天气”是一个Token，“怎么样”可能被切成两个Token，问号是一个Token。

## 与字符的区别

Token与“字符”最主要的区别之一在于：字符的大小是统一且确定的（1个汉字就是1个字符），但Token不一样——有的模型可能把“今天”当成1个Token，而有的模型会把它拆成“今”和“天”两个Token。所以，同样一句话，在不同的AI里，对应的Token数量可能不一样。

## 三重属性

根据黄仁勋在2026年GTC演讲中的论述，Token具有三重属性：

1. **成本单位**：AI的API按Token计费，Token是AI服务的计价基础。
2. **效率单位**：数据中心的核心指标正从存储容量转变为每秒能生产多少Token。
3. **新货币**：Token配额可能成为科技公司薪酬的一部分。

## 相关页面

- 核心概念：[[token-economics]]、[[token-factory]]、[[token-tiered-pricing]]、[[token-efficiency]]
- 相关组织：[[openai]]、[[alibaba]]
- 来源：[[li-nannan-2026-token-economics]]