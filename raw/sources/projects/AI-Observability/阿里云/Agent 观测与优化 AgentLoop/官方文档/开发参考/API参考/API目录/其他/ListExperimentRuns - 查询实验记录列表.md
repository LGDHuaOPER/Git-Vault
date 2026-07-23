---
title: "ListExperimentRuns - 查询实验记录列表"
source: "https://help.aliyun.com/zh/document_detail/3047507.html?spm=a2c4g.11186623.help-menu-3033820.d_6_1_3_6_7.3c973621416rn2"
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
"word-count": "766"
更新时间: "2026-07-23 11:14:43"
---
查询实验记录列表。

## 接口说明

调用 ListExperimentRuns 查询当前账号在指定 AgentSpace 下的实验执行记录。支持按状态、数据集、计划名称、实验名称过滤，并使用 `page`/`pageSize` 分页。

## 调试

[您可以在OpenAPI Explorer中直接运行该接口，免去您计算签名的困扰。运行成功后，OpenAPI Explorer可以自动生成SDK代码示例。](https://api.aliyun.com/api/AgentLoop/2026-05-20/ListExperimentRuns)

 [![](https://img.alicdn.com/tfs/TB16JcyXHr1gK0jSZR0XXbP8XXa-24-26.png) 调试](https://api.aliyun.com/api/AgentLoop/2026-05-20/ListExperimentRuns)

## **授权信息**

当前API暂无授权信息透出。

## 请求语法

```
GET /api/v1/experimentruns/{agentSpace}/records HTTP/1.1
```

## 路径参数

| **名称** | **类型** | **必填** | **描述** | **示例值** |
| --- | --- | --- | --- | --- |
| agentSpace | string | 否   | AgentSpace 名称。 | al-playground-cn-hongkong |

## 请求参数

| **名称** | **类型** | **必填** | **描述** | **示例值** |
| --- | --- | --- | --- | --- |
| page | integer | 否   | 页码，从 0 开始，默认 0。 | 0   |
| pageSize | integer | 否   | 每页大小，默认 20。 | 10  |
| status | string | 否   | 按状态过滤。 **枚举值：** - running : running - pending : pending - cancelled : cancelled - evaluating : evaluating - completed : completed - failed : failed - timeout : timeout | evaluating |
| datasetId | string | 否   | 按数据集 ID 精确过滤。 | arms\\_customer\\_agent\\_level1 |
| planName | string | 否   | 按实验计划名称模糊过滤。 | arms\\_agent\\_experiment |
| experimentName | string | 否   | 按实验配置中的名称模糊过滤。 | experimentA |
| maxResults | integer | 否   | 可选。分页请优先使用 `page` 与 `pageSize`。 | 20  |
| nextToken | string | 否   | 可选。分页请优先使用 `page` 与 `pageSize`。 | eyJwYWdlIjoxfQ== |

分页请使用 `page`（从 0 开始）与 `pageSize`。

## **返回参数**

| **名称** | **类型** | **描述** | **示例值** |
| --- | --- | --- | --- |
|     | object | 实验记录列表响应。 |     |
| requestId | string | 请求 ID。 | 3FE4CD1E-FF41-56BE-B590-7A021D9C1524 |
| total | integer | 总记录数。 | 100 |
| page | integer | 当前页码。 | 0   |
| pageSize | integer | 每页大小。 | 10  |
| records | array | 实验记录列表。 | \\[{"recordId": "exp-run-f6d419b0ed3d43a7b585948a55efc07b", "experimentPlanId": "exp-plan-0242d983f5d340fd8479cf2c19eb279e", "recordName": "arms\\_agent\\_experiment 2026/07/22 20:02:55", "planName": "arms\\_agent\\_experiment", "status": "evaluating", "progress": 100.0, "totalTasks": 40, "completedTasks": 40, "failedTasks": 0, "dataSourceType": "dataset-full", "datasetId": "arms\\_customer\\_agent\\_level1", "modelNames": \\["qwen3.7-plus", "qwen3.7-max"\\], "evaluationTaskId": "eval-task-6bec93bfa03740dd86ce2bf1496e65fb", "executedAt": 1784721775379, "completedAt": 1784721811392}, {"recordId": "a5397261-6e6d-4e45-bf52-feb8686f7524", "experimentPlanId": "exp-plan-e95bff54685a4ae29ff3a834c1008a71", "recordName": "rca\\_benchmark\\_eval\\_experiment 2026/07/22 19:23:59", "planName": "rca\\_benchmark\\_eval\\_experiment", "status": "completed", "progress": 100.0, "totalTasks": 20, "completedTasks": 20, "failedTasks": 0, "dataSourceType": "dataset-full", "datasetId": "rca\\_benckmark\\_eval", "modelNames": \\[\\], "evaluationTaskId": "eval-task-b1395b3bdf3e4dc994d7dcde7a66da45", "executedAt": 1784719439255, "completedAt": 1784719989371}\\] |
|     | ExperimentRecord | 单个实验记录对象。 |     |
| maxResults | integer | 最大返回条数。 | 20  |
| nextToken | string | 可选。 | eyJwYWdlIjoxfQ== |

### 响应示例

```
{
  "total": 100,
  "page": 0,
  "pageSize": 10,
  "records": [
    {
      "recordId": "exp-run-f6d419b0ed3d43a7b585948a55efc07b",
      "experimentPlanId": "exp-plan-0242d983f5d340fd8479cf2c19eb279e",
      "recordName": "arms_agent_experiment 2026/07/22 20:02:55",
      "planName": "arms_agent_experiment",
      "status": "evaluating",
      "progress": 100.0,
      "totalTasks": 40,
      "completedTasks": 40,
      "failedTasks": 0,
      "dataSourceType": "dataset-full",
      "datasetId": "arms_customer_agent_level1",
      "modelNames": [
        "qwen3.7-plus",
        "qwen3.7-max"
      ],
      "evaluationTaskId": "eval-task-6bec93bfa03740dd86ce2bf1496e65fb",
      "executedAt": 1784721775379,
      "completedAt": 1784721811392
    },
    {
      "recordId": "a5397261-6e6d-4e45-bf52-feb8686f7524",
      "experimentPlanId": "exp-plan-e95bff54685a4ae29ff3a834c1008a71",
      "recordName": "rca_benchmark_eval_experiment 2026/07/22 19:23:59",
      "planName": "rca_benchmark_eval_experiment",
      "status": "completed",
      "progress": 100.0,
      "totalTasks": 20,
      "completedTasks": 20,
      "failedTasks": 0,
      "dataSourceType": "dataset-full",
      "datasetId": "rca_benckmark_eval",
      "modelNames": [],
      "evaluationTaskId": "eval-task-b1395b3bdf3e4dc994d7dcde7a66da45",
      "executedAt": 1784719439255,
      "completedAt": 1784719989371
    },
    {
      "recordId": "exp-run-5224ae07549b490e9eb45508bb5d86be",
      "experimentPlanId": "b7f0ad3d-3765-446a-a744-ab64ab8bf386",
      "recordName": "arms_customer_agent_plan 2026/07/22 09:00:01",
      "planName": "arms_customer_agent_plan",
      "status": "completed",
      "progress": 0.0,
      "totalTasks": 1,
      "completedTasks": 0,
      "failedTasks": 1,
      "dataSourceType": "dataset-partial",
      "datasetId": "arms_customer_agent_level1",
      "querySql": "where \"input\" LIKE '%探针%'",
      "selectedItemIds": [
        "019ef4d5-a0f0-7114-832d-5542d771cd8c"
      ],
      "modelNames": [],
      "evaluationTaskId": "eval-task-a12e74ec6a6d49bc820541e7f1a9a3b6",
      "executedAt": 1784682001995,
      "completedAt": 1784682275325
    }
  ]
}
```

## 示例

正常返回示例

`JSON`格式

```
{
  "requestId": "3FE4CD1E-FF41-56BE-B590-7A021D9C1524",
  "total": 100,
  "page": 0,
  "pageSize": 10,
  "records": [
    {
      "recordId": "",
      "recordName": "",
      "experimentPlanId": "",
      "planName": "",
      "status": "",
      "totalTasks": 0,
      "failedTasks": 0,
      "completedTasks": 0,
      "progress": 0,
      "executedAt": 0,
      "completedAt": 0,
      "datasetId": "",
      "experimentConfig": [
        {
          "label": "",
          "name": "",
          "modelName": "",
          "modelProvider": "",
          "modelParameters": {
            "temperature": 0,
            "maxTokens": 0,
            "topP": 0,
            "topK": 0,
            "frequencyPenalty": 0,
            "presencePenalty": 0,
            "stopSequences": [
              ""
            ]
          },
          "endpointConnectorId": "",
          "promptTemplate": [
            {
              "role": "",
              "content": ""
            }
          ],
          "requestBodyTemplate": "",
          "requestMethod": ""
        }
      ],
      "dataSourceType": "",
      "modelNames": [
        ""
      ],
      "errorMessage": "",
      "datasetProject": "",
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
      "input": {
        "test": "test",
        "test2": 1
      },
      "selectedItemIds": [
        ""
      ],
      "querySql": "",
      "evaluationTaskId": ""
    }
  ],
  "maxResults": 20,
  "nextToken": "eyJwYWdlIjoxfQ=="
}
```

## 错误码

访问[错误中心](https://api.aliyun.com/document/AgentLoop/2026-05-20/errorCode)查看更多错误码。

## **变更历史**

更多信息，参考[变更详情](https://api.aliyun.com/document/AgentLoop/2026-05-20/ListExperimentRuns#workbench-doc-change-demo)。