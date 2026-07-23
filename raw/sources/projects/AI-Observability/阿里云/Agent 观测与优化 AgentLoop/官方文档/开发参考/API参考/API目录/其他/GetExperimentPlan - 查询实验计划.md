---
title: "GetExperimentPlan - 查询实验计划"
source: "https://help.aliyun.com/zh/document_detail/3047503.html?spm=a2c4g.11186623.help-menu-3033820.d_6_1_3_6_4.403a123c3drzHe"
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
"word-count": "621"
更新时间: "2026-07-23 11:02:40"
---
查询实验计划

## 接口说明

调用 GetExperimentPlan 查询指定实验计划的完整配置，包括实验分组、数据源、评估器和时间戳。

## 调试

[您可以在OpenAPI Explorer中直接运行该接口，免去您计算签名的困扰。运行成功后，OpenAPI Explorer可以自动生成SDK代码示例。](https://api.aliyun.com/api/AgentLoop/2026-05-20/GetExperimentPlan)

 [![](https://img.alicdn.com/tfs/TB16JcyXHr1gK0jSZR0XXbP8XXa-24-26.png) 调试](https://api.aliyun.com/api/AgentLoop/2026-05-20/GetExperimentPlan)

## **授权信息**

当前API暂无授权信息透出。

## 请求语法

```
GET /api/v1/experiments/{agentSpace}/plans/{planId} HTTP/1.1
```

## 路径参数

| **名称** | **类型** | **必填** | **描述** | **示例值** |
| --- | --- | --- | --- | --- |
| agentSpace | string | 否   | AgentSpace 名称。 | al-playground-cn-hongkong |
| planId | string | 否   | 实验计划 ID。 | exp-plan-0242d983f5d340fd8479cf2c19eb279e |

## 请求参数

| **名称** | **类型** | **必填** | **描述** | **示例值** |
| --- | --- | --- | --- | --- |

当前API无需请求参数

请传入目标 `agentSpace` 和 `planId`。仅可查询当前账号创建的计划。

## **返回参数**

| **名称** | **类型** | **描述** | **示例值** |
| --- | --- | --- | --- |
|     | object | 实验计划详情响应。 |     |
| requestId | string | 请求 ID。 | 3FE4CD1E-FF41-56BE-B590-7A021D9C1524 |
| planId | string | 实验计划 ID。 | exp-plan-0242d983f5d340fd8479cf2c19eb279e |
| planName | string | 实验计划名称。 | arms\\_agent\\_experiment |
| experimentType | string | 实验类型。 **枚举值：** - offline : offline - online : online | online |
| description | string | 描述信息。 | 对比 checkout Agent 基线与优化版本 |
| status | string | 计划状态。 **枚举值：** - running : running - stopped : stopped - pending : pending | stopped |
| datasetId | string | 关联的数据集 ID。 | arms\\_customer\\_agent\\_level1 |
| experiments | array | 实验配置列表。 | \\[{"label": "A", "name": "baseline", "modelName": "qwen-max"}\\] |
|     | ExperimentConfig | 单个实验分组配置。 |     |
| selectedItemIds | array | 部分数据集模式下选定的数据项 ID 列表。 | \\["019ef4d5-a0f0-7114-832d-5542d771cd8c"\\] |
|     | string | 数据集中的单条数据项 ID。 | 019ef4d5-a0f0-7114-832d-5542d771cd8c |
| querySql | string | 部分数据集模式下的自定义查询 SQL 子句。 | status='OK' |
| createdAt | integer | 创建时间，毫秒级 Unix 时间戳。 | 1782816000000 |
| updatedAt | integer | 更新时间，毫秒级 Unix 时间戳。 | 1782816600000 |
| evaluators | array | 评估器列表。 | \\[{"evaluatorRef": "Builtin.agent\\_task\\_completion"}\\] |
|     | [Evaluator](https://help.aliyun.com/zh/document_detail/3045378.html) | 单个评估器配置对象。 | {"evaluatorRef":"Builtin.agent\\_task\\_completion"} |
| input | object | 可选。 | {"question": "如何退款？"} |

计划不存在或不属于当前账号时，可能返回空对象。请根据响应中是否包含 `planId` 判断。时间戳为毫秒。

## 示例

正常返回示例

`JSON`格式

```
{
  "requestId": "3FE4CD1E-FF41-56BE-B590-7A021D9C1524",
  "planId": "exp-plan-0242d983f5d340fd8479cf2c19eb279e",
  "planName": "arms_agent_experiment",
  "experimentType": "online",
  "description": "对比 checkout Agent 基线与优化版本",
  "status": "stopped",
  "datasetId": "arms_customer_agent_level1",
  "experiments": [
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
  "selectedItemIds": [
    "019ef4d5-a0f0-7114-832d-5542d771cd8c"
  ],
  "querySql": "status='OK'",
  "createdAt": 1782816000000,
  "updatedAt": 1782816600000,
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
    "question": "如何退款？"
  }
}
```

## 错误码

访问[错误中心](https://api.aliyun.com/document/AgentLoop/2026-05-20/errorCode)查看更多错误码。

## **变更历史**

更多信息，参考[变更详情](https://api.aliyun.com/document/AgentLoop/2026-05-20/GetExperimentPlan#workbench-doc-change-demo)。