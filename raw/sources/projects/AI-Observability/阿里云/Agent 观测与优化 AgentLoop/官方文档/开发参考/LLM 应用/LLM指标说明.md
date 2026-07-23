---
title: "LLM指标说明"
source: "https://help.aliyun.com/zh/document_detail/3046156.html?spm=a2c4g.11186623.help-menu-3033820.d_6_0_0.2f1c357aH6X7Tj"
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
"word-count": "540"
更新时间: "2026-07-13 11:19:00"
---
本文介绍了LLM中的常见指标，您可以使用这些指标自定义Grafana大盘。

## **公共Label**

| **维度名称** | **维度Key** | **示例** |
| --- | --- | --- |
| 服务名称 | service | llm-rag-demo |
| 服务PID | pid | ggxw4lnjuz@0cb8619bb54\\*\\*\\*\\* |
| 机器IP | serverIp | 127.0.0.1 |
| 接口  | rpc | query |
| 应用来源 | source | - xtrace：表示可观测链路 OpenTelemetry 版。 - apm：表示应用实时监控服务 ARMS。 |

## **请求指标**

**说明**

原则上，请求指标涵盖埋点所支持的不同协议和调用类型，包括提供服务、依赖服务等。更多信息，请参见Java应用的[应用监控指标说明](https://help.aliyun.com/zh/arms/application-monitoring/developer-reference/application-monitoring-metrics#section-3d3-i77-4ib)。

| **指标名称** | **指标** | **指标类型** | **采集间隔** | **单位** | **维度** |
| --- | --- | --- | --- | --- | --- |
| 总请求数 | arms\\_$callType\\_requests\\_count | Gauge | 15s | 无   | 不同服务访问类型维度不同。详细信息，请参见[应用监控指标说明](https://help.aliyun.com/zh/arms/application-monitoring/developer-reference/application-monitoring-metrics#section-3d3-i77-4ib)。 |
| 错误请求数 | arms\\_$callType\\_requests\\_error\\_count | Gauge | 15s | 无   |
| 总请求耗时 | arms\\_$callType\\_requests\\_seconds | Gauge | 15s | 秒   |
| 慢请求数 | arms\\_$callType\\_requests\\_slow\\_count | Gauge | 15s | 无   |

## **LLM指标**

在公共基础Label上可能还存在如下Label：modelName、spanKind、usageType。

| **维度名称** | **维度Key** | **示例** | **说明** |
| 模型名称 | modelName | - gpt-4 - text-davinci-003 | 无   |
| 操作类型 | spanKind | LLM、CHAIN、EMBEDDING等，请参见[LLM Trace字段定义说明](https://help.aliyun.com/zh/arms/application-monitoring/developer-reference/llm-trace-field-definition-description)。 | 无   |
| 使用类型 | usageType | - input - output | Token相关指标专用。 |

### **操作类型**

| **指标名称** | **指标** | **指标类型** | **采集间隔** | **单位** | **维度** |
| 调用LLM的请求次数 | genai\\_calls\\_count | Gauge | 1m  | 无   | - modelName - spanKind |
| 调用LLM的响应耗时 | genai\\_calls\\_duration\\_seconds | Gauge | 1m  | 秒   | - modelName - spanKind |
| 调用LLM的错误次数 | genai\\_calls\\_error\\_count | Gauge | 1m  | 无   | - modelName - spanKind |
| 调用LLM的慢调用次数 | genai\\_calls\\_slow\\_count | Gauge | 1m  | 无   | - modelName - spanKind |

### **大模型性能**

| **指标名称** | **指标** | **指标类型** | **采集间隔** | **单位** | **维度** |
| 调用LLM的Time To First Token(TTFT) | genai\\_llm\\_first\\_token\\_seconds | Gauge | 1m  | 秒   | - modelName - spanKind |

### **大模型用量**

| **指标名称** | **指标** | **指标类型** | **采集间隔** | **单位** | **维度** |
| Tokens消耗统计 | genai\\_llm\\_usage\\_tokens | Gauge | 1m  | 无   | - modelName - spanKind - usageType - input - output |