---
title: "GetExperimentRun - 查询实验记录详情"
source: "https://help.aliyun.com/zh/document_detail/3047505.html?spm=a2c4g.11186623.help-menu-3033820.d_6_1_3_6_5.6c70352cOFH2qO"
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
更新时间: "2026-07-23 11:05:40"
---
查询实验记录详情。

## 接口说明

调用 GetExperimentRun 查询某次实验执行记录的详情，包括状态、进度、配置快照和关联评估任务 ID。

## 调试

[您可以在OpenAPI Explorer中直接运行该接口，免去您计算签名的困扰。运行成功后，OpenAPI Explorer可以自动生成SDK代码示例。](https://api.aliyun.com/api/AgentLoop/2026-05-20/GetExperimentRun)

 [![](https://img.alicdn.com/tfs/TB16JcyXHr1gK0jSZR0XXbP8XXa-24-26.png) 调试](https://api.aliyun.com/api/AgentLoop/2026-05-20/GetExperimentRun)

## **授权信息**

当前API暂无授权信息透出。

## 请求语法

```
GET /api/v1/experimentruns/{agentSpace}/records/{recordId} HTTP/1.1
```

## 路径参数

| **名称** | **类型** | **必填** | **描述** | **示例值** |
| --- | --- | --- | --- | --- |
| agentSpace | string | 否   | AgentSpace 名称。 | al-playground-cn-hongkong |
| recordId | string | 否   | 实验记录 ID。 | exp-run-f6d419b0ed3d43a7b585948a55efc07b |

## 请求参数

| **名称** | **类型** | **必填** | **描述** | **示例值** |
| --- | --- | --- | --- | --- |

当前API无需请求参数

请传入目标 `agentSpace` 和 `recordId`。

## **返回参数**

| **名称** | **类型** | **描述** | **示例值** |
| --- | --- | --- | --- |
|     | object | 实验记录详情响应。 |     |
| requestId | string | 请求 ID。 | 3FE4CD1E-FF41-56BE-B590-7A021D9C1524 |
| regionId | string | 地域 ID。 | cn-hangzhou |
| record | ExperimentRecord | 实验记录详情。值为 null 的字段不返回。 | {"recordId": "exp-run-f6d419b0ed3d43a7b585948a55efc07b", "experimentPlanId": "exp-plan-0242d983f5d340fd8479cf2c19eb279e", "recordName": "arms\\_agent\\_experiment 2026/07/22 20:02:55", "planName": "arms\\_agent\\_experiment", "status": "evaluating", "totalTasks": 40, "completedTasks": 40, "failedTasks": 0, "progress": 100.0, "executedAt": 1784721775379, "completedAt": 1784721811392, "dataSourceType": "dataset-full", "datasetId": "arms\\_customer\\_agent\\_level1", "modelNames": \\["qwen3.7-plus", "qwen3.7-max"\\], "evaluationTaskId": "eval-task-6bec93bfa03740dd86ce2bf1496e65fb"} |

`progress` 取值 0-100。实验完成后评估仍在进行时，`status` 可能为 `evaluating`。

### 在线实验响应示例

```
{
  "record": {
    "recordId": "exp-run-f6d419b0ed3d43a7b585948a55efc07b",
    "experimentPlanId": "exp-plan-0242d983f5d340fd8479cf2c19eb279e",
    "recordName": "arms_agent_experiment 2026/07/22 20:02:55",
    "planName": "arms_agent_experiment",
    "status": "evaluating",
    "totalTasks": 40,
    "completedTasks": 40,
    "failedTasks": 0,
    "progress": 100.0,
    "executedAt": 1784721775379,
    "completedAt": 1784721811392,
    "dataSourceType": "dataset-full",
    "datasetId": "arms_customer_agent_level1",
    "modelNames": [
      "qwen3.7-plus",
      "qwen3.7-max"
    ],
    "evaluationTaskId": "eval-task-6bec93bfa03740dd86ce2bf1496e65fb"
  }
}
```

### 离线实验响应示例

```
{
  "record": {
    "recordId": "a5397261-6e6d-4e45-bf52-feb8686f7524",
    "experimentPlanId": "exp-plan-e95bff54685a4ae29ff3a834c1008a71",
    "recordName": "rca_benchmark_eval_experiment 2026/07/22 19:23:59",
    "planName": "rca_benchmark_eval_experiment",
    "status": "completed",
    "totalTasks": 20,
    "completedTasks": 20,
    "failedTasks": 0,
    "progress": 100.0,
    "executedAt": 1784719439255,
    "completedAt": 1784719989371,
    "dataSourceType": "dataset-full",
    "datasetId": "rca_benckmark_eval",
    "modelNames": [],
    "evaluationTaskId": "eval-task-b1395b3bdf3e4dc994d7dcde7a66da45",
    "experimentConfig": [
      {
        "name": "experimentA",
        "promptTemplate": []
      }
    ]
  }
}
```

## 示例

正常返回示例

`JSON`格式

```
{
  "requestId": "3FE4CD1E-FF41-56BE-B590-7A021D9C1524",
  "regionId": "cn-hangzhou",
  "record": {
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
}
```

## 错误码

访问[错误中心](https://api.aliyun.com/document/AgentLoop/2026-05-20/errorCode)查看更多错误码。

## **变更历史**

更多信息，参考[变更详情](https://api.aliyun.com/document/AgentLoop/2026-05-20/GetExperimentRun#workbench-doc-change-demo)。