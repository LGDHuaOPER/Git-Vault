---
title: "CreatePipeline - 创建流水线"
source: "https://help.aliyun.com/zh/document_detail/3046328.html?spm=a2c4g.11186623.help-menu-3033820.d_6_1_3_1_8.47db11f9aLY8SK"
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
"word-count": "599"
更新时间: "2026-07-14 11:28:19"
---
创建流水线

## 调试

[您可以在OpenAPI Explorer中直接运行该接口，免去您计算签名的困扰。运行成功后，OpenAPI Explorer可以自动生成SDK代码示例。](https://api.aliyun.com/api/AgentLoop/2026-05-20/CreatePipeline)

 [![](https://img.alicdn.com/tfs/TB16JcyXHr1gK0jSZR0XXbP8XXa-24-26.png) 调试](https://api.aliyun.com/api/AgentLoop/2026-05-20/CreatePipeline)

## **授权信息**

当前API暂无授权信息透出。

## 请求语法

```
POST /agentspace/{agentSpace}/pipeline HTTP/1.1
```

## 路径参数

| **名称** | **类型** | **必填** | **描述** | **示例值** |
| --- | --- | --- | --- | --- |
| agentSpace | string | 否   | AgentSpace 名称，流水线将创建在该 AgentSpace 下 | my-agent-space |

## 请求参数

| **名称** | **类型** | **必填** | **描述** | **示例值** |
| --- | --- | --- | --- | --- |
| body | object | 否   | 请求体 |     |
| pipelineName | string | 否   | 流水线名称，3~63 个字符，仅允许小写字母、数字和连字符 | my-pipeline |
| description | string | 否   | 流水线描述，最长 256 个字符 | 从 SLS 采集 Trace 数据清洗入 Dataset |
| pipeline | object | 否   | Pipeline 配置（节点编排） |     |
| nodes | array<object> | 否   | 节点列表 |     |
|     | array<object> | 否   | 单个节点配置 |     |
| id  | string | 否   | 节点 Id | node-1 |
| type | string | 否   | 节点类型 | transform |
| parameters | object | 否   | 节点参数，键值结构，随节点类型而定 |     |
|     | any | 否   | 节点参数值 | value |
| source | object | 否   | Pipeline 数据源 |     |
| type | string | 否   | 数据源类型，当前支持 SLS | SLS |
| logstore | object | 否   | SLS Logstore 数据源配置 |     |
| project | string | 否   | SLS Project 名称 | my-sls-project |
| logstore | string | 否   | SLS Logstore 名称 | my-sls-logstore |
| query | string | 否   | 数据筛选查询语句（SLS 查询/分析语法） | \\* \\| SELECT \\* |
| sink | object | 否   | Pipeline 目标（数据写入目标） |     |
| type | string | 否   | 目标类型，当前支持 Dataset | Dataset |
| dataset | object | 否   | 目标数据集配置 |     |
| agentSpace | string | 否   | 目标数据集所属 AgentSpace 名称 | my-agent-space |
| dataset | string | 否   | 目标数据集名称 | my-dataset |
| executePolicy | object | 否   | 调度方式 |     |
| mode | string | 否   | 调度模式：RunOnce（单次执行）或 Scheduled（周期调度） | RunOnce |
| runOnce | object | 否   | 单次执行配置，仅 mode 为 RunOnce 时必填 |     |
| fromTime | integer | 否   | 数据处理窗口起始时间，Unix 秒，必须小于 toTime | 1735660800 |
| toTime | integer | 否   | 数据处理窗口结束时间，Unix 秒，必须大于 fromTime | 1735747200 |
| scheduled | object | 否   | 周期调度配置，仅 mode 为 Scheduled 时必填 |     |
| interval | string | 否   | 调度间隔，支持 1h / 6h / 12h / 1d | 1h  |
| fromTime | integer | 否   | 调度起始时间，Unix 毫秒时间戳 | 1735660800000 |
| clientToken | string | 否   | 幂等 Token，客户端生成的唯一字符串，保证创建操作幂等 | a1b2c3d4-1234-5678-90ab-cdef12345678 |

## **返回参数**

| **名称** | **类型** | **描述** | **示例值** |
| --- | --- | --- | --- |
|     | object | 响应数据 |     |
| requestId | string | 请求 Id，用于排查问题时定位本次请求 | 9ACFB10A-1B2C-3D4E-5F6G-7H8I9J0K1L2M |

## 示例

正常返回示例

`JSON`格式

```
{
  "requestId": "9ACFB10A-1B2C-3D4E-5F6G-7H8I9J0K1L2M"
}
```

## 错误码

访问[错误中心](https://api.aliyun.com/document/AgentLoop/2026-05-20/errorCode)查看更多错误码。

## **变更历史**

更多信息，参考[变更详情](https://api.aliyun.com/document/AgentLoop/2026-05-20/CreatePipeline#workbench-doc-change-demo)。