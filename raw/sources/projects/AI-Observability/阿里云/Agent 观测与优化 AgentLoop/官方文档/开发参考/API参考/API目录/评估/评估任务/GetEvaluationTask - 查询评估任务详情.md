---
title: "GetEvaluationTask - 查询评估任务详情"
source: "https://help.aliyun.com/zh/document_detail/3045680.html?spm=a2c4g.11186623.help-menu-3033820.d_6_1_3_5_0_1.bbf850fdeXABZU"
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
"word-count": "650"
更新时间: "2026-07-08 12:00:53"
---
获取评估任务详情

## 调试

[您可以在OpenAPI Explorer中直接运行该接口，免去您计算签名的困扰。运行成功后，OpenAPI Explorer可以自动生成SDK代码示例。](https://api.aliyun.com/api/AgentLoop/2026-05-20/GetEvaluationTask)[您可以在OpenAPI Explorer中直接运行该接口，免去您计算签名的困扰。运行成功后，OpenAPI Explorer可以自动生成SDK代码示例。](https://api.alibabacloud.com/api/AgentLoop/2026-05-20/GetEvaluationTask)

 [![](https://img.alicdn.com/tfs/TB16JcyXHr1gK0jSZR0XXbP8XXa-24-26.png) 调试](https://api.aliyun.com/api/AgentLoop/2026-05-20/GetEvaluationTask)

## **授权信息**

当前API暂无授权信息透出。

## 请求语法

```
GET /api/v1/evaluation-task/{agentSpace}/{taskId} HTTP/1.1
```

## 路径参数

| **名称** | **类型** | **必填** | **描述** | **示例值** |
| --- | --- | --- | --- | --- |
| agentSpace | string | 否   | AgentSpace 名称。 | prod-agentspace |
| taskId | string | 否   | 评估任务 ID。 | eval-task-8b36f2e2b1f94f9c91ce7a4b0f6d9c25 |

## 请求参数

| **名称** | **类型** | **必填** | **描述** | **示例值** |
| --- | --- | --- | --- | --- |

当前API无需请求参数

## **返回参数**

| **名称** | **类型** | **描述** | **示例值** |
| --- | --- | --- | --- |
|     | object | Schema of Response |     |
| requestId | string | 请求 ID。 | 3FE4CD1E-FF41-56BE-B590-7A021D9C1524 |
| taskId | string | 评估任务 ID。 | eval-task-8b36f2e2b1f94f9c91ce7a4b0f6d9c25 |
| taskName | string | 任务名称。 | trace\\_task\\_completion\\_eval |
| agentSpace | string | AgentSpace 名称。 | prod-agentspace |
| taskMode | string | 评估任务模式。 **枚举值：** - batch : batch | batch |
| dataType | string | 评估对象的数据来源类型。 **枚举值：** - trace : trace - log : log - atif : atif - dataset : dataset | trace |
| evaluators | array | 评估器配置列表。 | \\[{"evaluatorRef":"Builtin.agent\\_task\\_completion","resultName":"agent\\_task\\_completion","resultType":"score","variableMapping":{"input":"trace.input","output":"trace.output","agent\\_trajectory":"trace.agent\\_trajectory"}}\\] |
|     | [Evaluator](https://help.aliyun.com/zh/document_detail/3045378.html) | 单个评估器配置对象。 | {"evaluatorRef":"Builtin.agent\\_task\\_completion"} |
| status | string | 评估任务状态。 **枚举值：** - Failed : Failed - Running : Running - Completed : Completed - Scheduling : Scheduling - Deleted : Deleted - Terminated : Terminated - Pending : Pending | Running |
| createdAt | integer | 创建时间，秒级 Unix 时间戳。 | 1782816000 |
| updatedAt | integer | 最近更新时间，秒级 Unix 时间戳。 | 1782816600 |
| dataFilter | string | 评估数据筛选条件，后端以 JSON 字符串形式返回。 | {"query":"serviceName='checkout-service'","maxRecords":10,"samplingRate":100} |
| channel | string | 任务来源。 **枚举值：** - default : default | default |
| config | object | 数据源和执行配置。`dataType=trace` 任务通常包含后端补齐的 `project`、`storeName` 和 `dataScope`。 | {"project":"agentspace-project","storeName":"logstore-tracing","dataScope":"trace"} |
|     | string | 单个配置项的值，键名由具体字段约定决定。 | trace |
| tags | object | 任务标签键值对。未设置时为空。 | {"serviceId":"checkout-service","env":"prod"} |
|     | string | 单个任务标签值，键名按业务维度自定义。 | prod |
| regionId | string | 任务所属地域。 | cn-hangzhou |
| runStrategyConfig | RunStrategies | 运行策略结构化配置，解析后的回填策略和持续评估策略。 | {"backfill":{"enabled":true,"startTime":1782816000000,"endTime":1782902400000},"continuous":{"enabled":true,"intervalUnit":"HOUR","intervalValue":1,"dataDelayMinutes":5}} |
| description | string | 评估任务描述。 | 评估线上 Agent 链路任务完成度 |

镇元最新契约中，查询响应不再返回 runStrategies 原始 JSON 字符串字段，调用方应读取 runStrategyConfig 获取结构化运行策略。

## 示例

正常返回示例

`JSON`格式

```
{
  "requestId": "3FE4CD1E-FF41-56BE-B590-7A021D9C1524",
  "taskId": "eval-task-8b36f2e2b1f94f9c91ce7a4b0f6d9c25",
  "taskName": "trace_task_completion_eval",
  "agentSpace": "prod-agentspace",
  "taskMode": "batch",
  "dataType": "trace",
  "evaluators": [
    {
      "evaluatorRef": "Builtin.agent_task_completion",
      "name": "agent_task_completion",
      "type": "AGENT",
      "resultName": "agent_task_completion",
      "resultType": "score",
      "config": {
        "version": "1.0.0"
      },
      "filters": {
        "query": "serviceName='checkout-service'"
      },
      "variableMapping": {
        "key": "trace.input"
      }
    }
  ],
  "status": "Running",
  "createdAt": 1782816000,
  "updatedAt": 1782816600,
  "dataFilter": "{\"query\":\"serviceName='checkout-service'\",\"maxRecords\":10,\"samplingRate\":100}",
  "channel": "default",
  "config": {
    "key": "trace"
  },
  "tags": {
    "key": "prod"
  },
  "regionId": "cn-hangzhou",
  "runStrategyConfig": {
    "backfill": {
      "enabled": true,
      "startTime": 1782816000000,
      "endTime": 1782902400000
    },
    "continuous": {
      "enabled": true,
      "intervalUnit": "HOUR",
      "intervalValue": 1,
      "dataDelayMinutes": 5
    }
  },
  "description": "评估线上 Agent 链路任务完成度"
}
```

## 错误码

访问[错误中心](https://api.aliyun.com/document/AgentLoop/2026-05-20/errorCode)[错误中心](https://api.alibabacloud.com/document/AgentLoop/2026-05-20/errorCode)查看更多错误码。

## **变更历史**

更多信息，参考[变更详情](https://api.aliyun.com/document/AgentLoop/2026-05-20/GetEvaluationTask#workbench-doc-change-demo)[变更详情](https://api.alibabacloud.com/document/AgentLoop/2026-05-20/GetEvaluationTask#workbench-doc-change-demo)。