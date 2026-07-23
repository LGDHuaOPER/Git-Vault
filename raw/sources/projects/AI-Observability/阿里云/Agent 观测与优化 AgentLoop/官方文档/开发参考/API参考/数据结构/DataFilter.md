---
title: "DataFilter"
source: "https://help.aliyun.com/zh/document_detail/3045377.html?spm=a2c4g.11186623.help-menu-3033820.d_6_1_4_2.23d31ff6ZC0DdO"
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
"word-count": "257"
更新时间: "2026-07-14 19:54:27"
---
| **名称**       | **类型**  | **描述**                                                                 | **示例值**                                                                       |
| ------------ | ------- | ---------------------------------------------------------------------- | ----------------------------------------------------------------------------- |
|              | object  | 评估任务的数据筛选条件，用于控制数据查询条件、单次输入内容、采样比例和最大评估数量。                             | {"query":"serviceName='checkout-service'","maxRecords":10,"samplingRate":100} |
| query        | string  | 数据查询过滤条件，会与评估器级 filters.query 共同生效。Trace 场景可填写服务名、环境、标签等过滤表达式。         | serviceName='checkout-service'                                                |
| maxRecords   | integer | 最大评估记录数，对 backfill 和 continuous 运行都生效。未传时后端不额外写入默认值。                   | 10                                                                            |
| samplingRate | integer | 采样率百分比，取值 0 到 100。0 或不传表示不采样；100 表示全量；小于 100 时先随机采样，再应用 maxRecords 限制。 | 100                                                                           |
| serviceNames | array   |                                                                        |                                                                               |
|              | string  |                                                                        |                                                                               |
| provided     | object  | 单次临时评估输入内容，主要用于 oneshot 任务。值会按字符串保存；对象或数组值会被序列化为 JSON 字符串。             | {"input":"用户查询订单状态","output":"已查询到订单状态"}                                      |