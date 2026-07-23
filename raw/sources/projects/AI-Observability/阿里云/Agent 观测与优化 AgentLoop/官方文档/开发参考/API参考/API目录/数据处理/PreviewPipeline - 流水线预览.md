---
title: "PreviewPipeline - 流水线预览"
source: "https://help.aliyun.com/zh/document_detail/3046329.html?spm=a2c4g.11186623.help-menu-3033820.d_6_1_3_1_3.76563acaYuzVJl"
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
"word-count": "1230"
更新时间: "2026-07-14 11:36:37"
---
预览流水线。在不创建流水线资源的前提下，基于给定的数据源、节点编排和时间范围试运行查询，返回少量样本数据，用于验证参数配置和预览处理效果。

## 接口说明

## 请求说明

-   **agentSpace** 必须是当前账户下已创建的 AgentSpace 实例。
    
-   **source.type** 当前仅支持 `logstore` 类型，且 `logstore.project` 和 `logstore.logstore` 需要在该 AgentSpace 内完成授权并处于同一区域。
    
-   **pipeline.nodes** 至少包含一个 `Source` 类型的节点，不允许为空。
    
-   **fromTime** 和 **toTime** 是 Unix 秒级时间戳，其中 **fromTime** 必须小于 **toTime**。
    
-   返回的数据最多为 5 条记录，并自动过滤掉数据源系统内部字段。
    

## 调试

[您可以在OpenAPI Explorer中直接运行该接口，免去您计算签名的困扰。运行成功后，OpenAPI Explorer可以自动生成SDK代码示例。](https://api.aliyun.com/api/AgentLoop/2026-05-20/PreviewPipeline)

 [![](https://img.alicdn.com/tfs/TB16JcyXHr1gK0jSZR0XXbP8XXa-24-26.png) 调试](https://api.aliyun.com/api/AgentLoop/2026-05-20/PreviewPipeline)

## **授权信息**

当前API暂无授权信息透出。

## 请求语法

```
POST /agentspace/{agentSpace}/pipeline/preview HTTP/1.1
```

## 路径参数

| **名称** | **类型** | **必填** | **描述** | **示例值** |
| --- | --- | --- | --- | --- |
| agentSpace | string | 否   | AgentSpace 名称，定位流水线所在的 AgentSpace | my-agent-space |

## 请求参数

| **名称** | **类型** | **必填** | **描述** | **示例值** |
| --- | --- | --- | --- | --- |
| body | object | 否   | 请求体 |     |
| source | object | 否   | Pipeline 数据源 |     |
| type | string | 否   | 数据源类型，当前支持 SLS | SLS |
| logstore | object | 否   | SLS Logstore 数据源配置 |     |
| project | string | 否   | SLS Project 名称 | my-sls-project |
| logstore | string | 否   | SLS Logstore 名称 | my-sls-logstore |
| query | string | 否   | 数据筛选查询语句（SLS 查询/分析语法） | \\* \\| SELECT \\* |
| pipeline | object | 否   | Pipeline 配置（节点编排） |     |
| nodes | array<object> | 否   | 节点列表 |     |
|     | array<object> | 否   | 单个节点配置 |     |
| id  | string | 否   | 节点 Id | node-1 |
| type | string | 否   | 节点类型 | transform |
| parameters | object | 否   | 节点参数，键值结构，随节点类型而定 |     |
|     | any | 否   | 节点参数值 | value |
| fromTime | integer | 否   | 预览数据窗口起始时间，Unix 秒 | 1735660800 |
| toTime | integer | 否   | 预览数据窗口结束时间，Unix 秒 | 1735747200 |

-   The path parameter agentSpace must match an existing AgentSpace instance owned by the current account; otherwise an AgentSpaceNotFound error is returned.
    
-   source.type currently only supports `SLS`. The logstore.project and logstore.logstore must have completed STS authorization within the AgentSpace, and must be in the same region.
    
-   source.logstore.query follows standard SLS query syntax (including SPL stage `| SELECT ...`). Verify your query in the SLS console first.
    
-   pipeline.nodes must contain at least one Source node (type=Source); an empty array triggers InvalidParameter.Pipeline.
    
-   Other supported node types include Filter, Extract, Transform, SampleData, etc. (see the Pipeline developer documentation for the complete list).
    
-   pipeline.nodes\[\].parameters is map, interpreted according to node.type; unexpected keys will be rejected.
    
-   fromTime / toTime are unix seconds; fromTime must be strictly less than toTime. Keep the window under 15 minutes to control SLS scan volume within the 3-second timeout.
    

## **返回参数**

| **名称** | **类型** | **描述** | **示例值** |
| --- | --- | --- | --- |
|     | object | 响应数据 |     |
| requestId | string | 请求 Id，用于排查问题时定位本次请求 | 9ACFB10A-1B2C-3D4E-5F6G-7H8I9J0K1L2M |
| meta | object | 查询元信息 |     |
| progress | string | SLS 查询进度，Complete 表示已完成 | Complete |
| aggQuery | string | 聚合分析 SPL 语句 | \\* \\| SELECT status, count(\\*) AS cnt GROUP BY status |
| whereQuery | string | 过滤条件 SPL 语句 | status: 200 |
| hasSQL | boolean | 是否 sql 查询 |     |
| processedRows | integer | 处理的日志行数 | 10000 |
| elapsedMillisecond | integer | 查询耗时，毫秒 | 1200 |
| cpuSec | number | 消耗的 CPU 时间，秒 | 0.5 |
| cpuCores | integer | 消耗的 CPU 核数 | 2   |
| keys | array | 结果列名列表 |     |
|     | string | 结果列名列表 | \\[\\] |
| terms | array<object> | 列的类型与聚合信息 |     |
|     | object | 列的类型与聚合信息 |     |
| limited | integer | 返回结果行数上限 | 5   |
| mode | integer | 查询模式标识 | 1   |
| scanBytes | integer | 扫描的原始数据字节数 | 1048576 |
| count | integer | 匹配的日志条数 | 100 |
| processedBytes | integer | 处理的数据字节数 | 524288 |
| isAccurate | boolean | 是否开启纳秒级有序 |     |
| columnTypes | array | `meta.columnTypes` 提供列名到数据类型的映射（string / long / double / json）。 |     |
|     | string | `meta.columnTypes` 提供列名到数据类型的映射（string / long / double / json）。 | string |
| data | array<object> | `data` 为样本行集合（数组内 map），仅包含前 N 行（默认最多 5 行），不反映完整写入计划。 |     |
|     | object | 字段值 | 200 |
|     | string | 返回数据 | \\[{'type': 'saturation', 'value': 0}, {'type': 'load', 'value': 0}, {'type': 'latency', 'value': 1}, {'type': 'error', 'value': 0}\\] |

-   data 为样本行集合（数组内 map），仅包含前 N 行（默认最多 5 行），不反映完整写入计划。
    
-   meta.limited 表示是否命中行数限制，为 true 时当前数据为截断子集。
    
-   meta.mode 描述执行模式（spl / sql / hybrid），可用于理解查询降级行为。
    
-   meta.columnTypes 提供列名到数据类型的映射（string / long / double / json）。
    
-   meta.processedRows / processedBytes / scanBytes / cpuSec / cpuCores 反映资源消耗，可用于创建流水线前的容量估算。
    
-   若预览未命中数据，data 为空数组，meta.count=0，requestId 仍返回以便日志定位。
    

## 示例

正常返回示例

`JSON`格式

```
{
  "requestId": "9ACFB10A-1B2C-3D4E-5F6G-7H8I9J0K1L2M",
  "meta": {
    "progress": "Complete",
    "aggQuery": "* | SELECT status, count(*) AS cnt GROUP BY status",
    "whereQuery": "status: 200",
    "hasSQL": true,
    "processedRows": 10000,
    "elapsedMillisecond": 1200,
    "cpuSec": 0.5,
    "cpuCores": 2,
    "keys": [
      "[]"
    ],
    "terms": [
      {
        "test": "test",
        "test2": 1
      }
    ],
    "limited": 5,
    "mode": 1,
    "scanBytes": 1048576,
    "count": 100,
    "processedBytes": 524288,
    "isAccurate": true,
    "columnTypes": [
      "string"
    ]
  },
  "data": [
    {
      "key": "[{'type': 'saturation', 'value': 0}, {'type': 'load', 'value': 0}, {'type': 'latency', 'value': 1}, {'type': 'error', 'value': 0}]"
    }
  ]
}
```

## 错误码

访问[错误中心](https://api.aliyun.com/document/AgentLoop/2026-05-20/errorCode)查看更多错误码。

## **变更历史**

更多信息，参考[变更详情](https://api.aliyun.com/document/AgentLoop/2026-05-20/PreviewPipeline#workbench-doc-change-demo)。