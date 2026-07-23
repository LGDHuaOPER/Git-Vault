---
title: "ListEvaluationRuns - 查询评估运行列表"
source: "https://help.aliyun.com/zh/document_detail/3045679.html?spm=a2c4g.11186623.help-menu-3033820.d_6_1_3_5_0_5.39b37ec2dTPLzn"
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
"word-count": "508"
更新时间: "2026-07-08 11:51:43"
---
查询评估运行列表。

## 调试

[您可以在OpenAPI Explorer中直接运行该接口，免去您计算签名的困扰。运行成功后，OpenAPI Explorer可以自动生成SDK代码示例。](https://api.aliyun.com/api/AgentLoop/2026-05-20/ListEvaluationRuns)[您可以在OpenAPI Explorer中直接运行该接口，免去您计算签名的困扰。运行成功后，OpenAPI Explorer可以自动生成SDK代码示例。](https://api.alibabacloud.com/api/AgentLoop/2026-05-20/ListEvaluationRuns)

 [![](https://img.alicdn.com/tfs/TB16JcyXHr1gK0jSZR0XXbP8XXa-24-26.png) 调试](https://api.aliyun.com/api/AgentLoop/2026-05-20/ListEvaluationRuns)

## **授权信息**

当前API暂无授权信息透出。

## 请求语法

```
GET /api/v1/evaluation-task/{agentSpace}/{taskId}/runs HTTP/1.1
```

## 路径参数

| **名称** | **类型** | **必填** | **描述** | **示例值** |
| --- | --- | --- | --- | --- |
| agentSpace | string | 否   | AgentSpace 名称。 | prod-agentspace |
| taskId | string | 否   | 评估任务 ID。 | eval-task-8b36f2e2b1f94f9c91ce7a4b0f6d9c25 |

## 请求参数

| **名称** | **类型** | **必填** | **描述** | **示例值** |
| --- | --- | --- | --- | --- |
| status | string | 否   | 运行状态过滤条件。 **枚举值：** - Failed : Failed - Running : Running - Completed : Completed - Terminated : Terminated - Pending : Pending | Running |
| runType | string | 否   | 运行类型过滤条件。 **枚举值：** - continuous : continuous - backfill : backfill - continuous\\_parent : continuous\\_parent | backfill |
| nextToken | string | 否   | 下一页分页 Token。 | eyJsYXN0SWQiOjEwMX0= |
| maxResults | integer | 否   | 每页返回条数。后端默认 20，最大 100。 | 20  |

## **返回参数**

| **名称** | **类型** | **描述** | **示例值** |
| --- | --- | --- | --- |
|     | object | Schema of Response |     |
| requestId | string | 请求 ID。 | 3FE4CD1E-FF41-56BE-B590-7A021D9C1524 |
| totalCount | integer | 符合条件的运行总数。 | 3   |
| maxResults | integer | 本次请求使用的每页条数。 | 20  |
| nextToken | string | 下一页分页 Token。为空表示没有下一页。 | eyJsYXN0SWQiOjEyMH0= |
| evaluationRuns | array<object> | 运行摘要列表。 | \\[{"runId":"eval-run-4fd47f3d7e684e15b1d3d178c6a5b81a","runType":"backfill","status":"Running","totalCount":100}\\] |
|     | object | 单个评估运行摘要对象。 | {"runId":"eval-run-4fd47f3d7e684e15b1d3d178c6a5b81a"} |
| runId | string | 运行 ID。 | eval-run-4fd47f3d7e684e15b1d3d178c6a5b81a |
| runName | string | 运行名称。 | trace\\_task\\_completion\\_eval-backfill |
| taskId | string | 评估任务 ID。 | eval-task-8b36f2e2b1f94f9c91ce7a4b0f6d9c25 |
| runType | string | 运行类型。 **枚举值：** - continuous : continuous - backfill : backfill - continuous\\_parent : continuous\\_parent | backfill |
| status | string | 运行状态。 **枚举值：** - Failed : Failed - Running : Running - Completed : Completed - Terminated : Terminated - Pending : Pending | Running |
| totalCount | integer | 总评估条数。 | 100 |
| successCount | integer | 成功条数。 | 96  |
| failedCount | integer | 失败条数。 | 4   |
| createdAt | integer | 创建时间，秒级 Unix 时间戳。 | 1782816000 |
| updatedAt | integer | 更新时间，秒级 Unix 时间戳。 | 1782816600 |
| dataStartTime | integer | 本次运行数据窗口起始时间，秒级 Unix 时间戳。 | 1782816000 |
| dataEndTime | integer | 本次运行数据窗口结束时间，秒级 Unix 时间戳。 | 1782902400 |

## 示例

正常返回示例

`JSON`格式

```
{
  "requestId": "3FE4CD1E-FF41-56BE-B590-7A021D9C1524",
  "totalCount": 3,
  "maxResults": 20,
  "nextToken": "eyJsYXN0SWQiOjEyMH0=",
  "evaluationRuns": [
    {
      "runId": "eval-run-4fd47f3d7e684e15b1d3d178c6a5b81a",
      "runName": "trace_task_completion_eval-backfill",
      "taskId": "eval-task-8b36f2e2b1f94f9c91ce7a4b0f6d9c25",
      "runType": "backfill",
      "status": "Running",
      "totalCount": 100,
      "successCount": 96,
      "failedCount": 4,
      "createdAt": 1782816000,
      "updatedAt": 1782816600,
      "dataStartTime": 1782816000,
      "dataEndTime": 1782902400
    }
  ]
}
```

## 错误码

访问[错误中心](https://api.aliyun.com/document/AgentLoop/2026-05-20/errorCode)[错误中心](https://api.alibabacloud.com/document/AgentLoop/2026-05-20/errorCode)查看更多错误码。

## **变更历史**

更多信息，参考[变更详情](https://api.aliyun.com/document/AgentLoop/2026-05-20/ListEvaluationRuns#workbench-doc-change-demo)[变更详情](https://api.alibabacloud.com/document/AgentLoop/2026-05-20/ListEvaluationRuns#workbench-doc-change-demo)。