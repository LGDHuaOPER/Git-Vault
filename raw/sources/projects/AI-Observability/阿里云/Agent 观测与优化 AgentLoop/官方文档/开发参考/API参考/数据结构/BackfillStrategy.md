---
title: "BackfillStrategy"
source: "https://help.aliyun.com/zh/document_detail/3045375.html?spm=a2c4g.11186623.help-menu-3033820.d_6_1_4_0.6d20162b9pA03t"
author:
  - "阿里云计算"
published:
created: 2026-07-23
description: "AgentLoop 是阿里云推出的面向企业级智能体的一站式自进化平台，提供 Agent全栈观测与审计、Agent评估与实验、Agent资产管理与持续优化等核心能力，助力企业构建智能体进化数据飞轮，持续提升企业 Agent的质量、效率、成本与安全性。面向企业真实生产环境 Agent应用提供 Agent-as-a-Judge、Agent Playground、Trace2Dataset等 Agent应用范式的场景化闭环能力，让 Agent在生产环境中形成可观测、可评估、可优化的持续进化飞轮。"
tags:
  - "Clippings"
  - "AI可观测"
  - "阿里云"
  - "阿里云/AgentLoop"
  - "官方文档"
"word-count": "157"
更新时间: "2026-07-07 19:27:56"
---
| **名称**    | **类型**  | **描述**                                  | **示例值**                                                                              |
| --------- | ------- | --------------------------------------- | ------------------------------------------------------------------------------------ |
|           | object  | 历史数据回填评估策略，用于指定一次回填运行的时间范围和触发方式。        | {"enabled":true,"startTime":1782816000000,"endTime":1782902400000,"immediate":false} |
| enabled   | boolean | 是否启用回填策略。不传或 true 表示启用；false 表示关闭但保留配置。 | true                                                                                 |
| startTime | integer | 回填时间范围起点，Unix 毫秒时间戳。需要手动启动回填时应提供完整时间范围。 | 1782816000000                                                                        |
| endTime   | integer | 回填时间范围终点，Unix 毫秒时间戳。需要手动启动回填时应提供完整时间范围。 | 1782902400000                                                                        |