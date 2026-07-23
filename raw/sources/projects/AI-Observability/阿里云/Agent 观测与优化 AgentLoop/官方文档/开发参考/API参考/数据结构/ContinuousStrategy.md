---
title: "ContinuousStrategy"
source: "https://help.aliyun.com/zh/document_detail/3045376.html?spm=a2c4g.11186623.help-menu-3033820.d_6_1_4_1.42ed73deUfXkNG"
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
"word-count": "185"
更新时间: "2026-07-07 12:01:50"
---
| 名称               | 类型      | 描述                                                                    | 示例值  |
| ---------------- | ------- | --------------------------------------------------------------------- | ---- |
|                  | object  | 持续评估策略，用于按固定时间窗口持续评估新增数据。                                             |      |
| enabled          | boolean | 是否启用持续评估。不传或 true 表示启用；false 表示关闭但保留配置。                               | true |
| intervalUnit     | string  | 持续评估窗口间隔单位。当前轮询实现需要该字段。 枚举值： - HOUR：HOUR。 - MINUTE：MINUTE。 - DAY：DAY。 | HOUR |
| intervalValue    | integer | 持续评估窗口间隔大小，需要与 intervalUnit 配合使用，取值应大于 0。                             | 1    |
| dataDelayMinutes | integer | 数据到达延迟时间，单位为分钟。窗口结束后延迟该时间再创建运行，用于等待数据完整到达；不传默认为 0。                    | 5    |