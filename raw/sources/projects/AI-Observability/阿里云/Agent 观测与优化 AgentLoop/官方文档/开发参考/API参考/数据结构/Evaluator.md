---
title: "Evaluator"
source: "https://help.aliyun.com/zh/document_detail/3045378.html?spm=a2c4g.11186623.help-menu-3033820.d_6_1_4_3.4db54185ilGYZ8"
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
"word-count": "439"
更新时间: "2026-07-07 12:02:13"
---
| 名称              | 类型     | 描述                                                                                                             | 示例值                                        |
| --------------- | ------ | -------------------------------------------------------------------------------------------------------------- | ------------------------------------------ |
|                 | object | 评估任务中的评估器配置，用于引用已创建的评估器，或以内联方式描述本次任务使用的评估器。                                                                    |                                            |
| evaluatorRef    | string | 已注册评估器的引用名称。传入后优先按该引用加载评估器定义，支持内置评估器和自定义评估器。                                                                   | Builtin.agent\\_task\\_completion          |
| name            | string | 评估器名称。未传 evaluatorRef 的内联评估器场景必填；同一任务内 evaluatorRef 或 name 不能重复。                                               | agent\\_task\\_completion                  |
| type            | string | 评估器类型。未传时默认 LLM；内联 CODE 评估器当前不支持，CODE 类型请通过 evaluatorRef 引用已创建评估器。 枚举值： - AGENT：AGENT。 - CODE：CODE。 - LLM：LLM。 | AGENT                                      |
| resultName      | string | 评估结果字段名。内联评估器场景必填；引用已有评估器时未传则使用评估器定义中的 metricName。                                                             | agent\\_task\\_completion                  |
| resultType      | string | 评估结果类型。内联评估器场景必填；引用已有评估器时未传默认为 score。 枚举值： - score：score。 - binary：binary。 - text：text。                        | score                                      |
| config          | object | 评估器运行配置。内联 LLM 评估器需要包含 prompt 等配置；引用已有评估器时通常不传，仅在需要指定版本等运行时参数时传入。                                              | {"version":"1.0.0"}                        |
| filters         | object | 评估器级数据筛选条件，会与任务级 dataFilter.query 共同生效。                                                                        | {"query":"serviceName='checkout-service'"} |
| variableMapping | object | 变量映射关系，将评估器变量映射到评估数据字段。LLM/AGENT 内联评估器必填，引用已有评估器时变量名必须存在于评估器定义中。                                               |                                            |
|                 | string | 单个变量映射值，表示该评估器变量读取的评估数据字段路径。                                                                                   | trace.input                                |