---
title: "CreateExperimentPlan - 创建实验计划"
source: "https://help.aliyun.com/zh/document_detail/3047496.html?spm=a2c4g.11186623.help-menu-3033820.d_6_1_3_6_0.2d06462eEcUrEs"
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
"word-count": "1139"
更新时间: "2026-07-23 10:19:34"
---
创建实验计划。

## 接口说明

调用 CreateExperimentPlan 在指定 AgentSpace 下创建实验计划。用于定义一次离线或在线实验的配置，包括数据源、可选的评估器，以及在线实验所需的实验分组。创建成功后，再调用 CreateExperimentRun 发起执行。

## 调试

[您可以在OpenAPI Explorer中直接运行该接口，免去您计算签名的困扰。运行成功后，OpenAPI Explorer可以自动生成SDK代码示例。](https://api.aliyun.com/api/AgentLoop/2026-05-20/CreateExperimentPlan)

 [![](https://img.alicdn.com/tfs/TB16JcyXHr1gK0jSZR0XXbP8XXa-24-26.png) 调试](https://api.aliyun.com/api/AgentLoop/2026-05-20/CreateExperimentPlan)

## **授权信息**

当前API暂无授权信息透出。

## 请求语法

```
POST /api/v1/experiments/{agentSpace}/plans HTTP/1.1
```

## 路径参数

| **名称** | **类型** | **必填** | **描述** | **示例值** |
| --- | --- | --- | --- | --- |
| agentSpace | string | 否   | AgentSpace 名称。 | al-playground-cn-hongkong |

## 请求参数

| **名称** | **类型** | **必填** | **描述** | **示例值** |
| --- | --- | --- | --- | --- |
| body | object | 否   | 请求体。离线实验可不传 experiments；在线实验至少传 1 个 experiments。 | {"planName": "rca\\_benchmark\\_eval\\_experiment", "experimentType": "OFFLINE", "description": "", "datasetId": "rca\\_benckmark\\_eval", "evaluators": \\[{"evaluatorRef": "Builtin.agent\\_correctness", "name": "Builtin.agent\\_correctness", "type": "AGENT", "resultName": "Builtin.agent\\_correctness", "resultType": "score", "variableMapping": {"input": "experiment\\_input", "output": "experiment\\_output", "expected\\_output": "dataset.ground\\_truth\\_json"}, "filters": {"query": "", "sample": "100"}, "config": {"variables": \\[\\], "prompt": ""}}, {"evaluatorRef": "rca-toxicity-safety-accuracy", "name": "rca-toxicity-safety-accuracy", "type": "AGENT", "resultName": "rca-toxicity-safety-accuracy", "resultType": "score", "variableMapping": {"input": "experiment\\_input", "output": "experiment\\_output", "question": "dataset.question", "expected\\_output": "dataset.ground\\_truth\\_json", "payload\\_json": "dataset.payload\\_json"}, "filters": {"query": "", "sample": "100"}, "config": {"variables": \\[\\], "prompt": ""}}\\]} |
| planName | string | 是   | 实验计划名称。同一 AgentSpace 下同一账号不可重名。 | rca\\_benchmark\\_eval\\_experiment |
| experimentType | string | 是   | 实验类型。请求传 `OFFLINE` 或 `ONLINE`。 **枚举值：** - OFFLINE : OFFLINE - ONLINE : ONLINE | OFFLINE |
| description | string | 否   | 实验计划描述。 | rca\\_benchmark\\_eval\\_experiment 离线实验 |
| datasetId | string | 否   | 关联的数据集 ID。不传时执行阶段按 simple 模式处理。 | rca\\_benckmark\\_eval |
| experiments | array | 是   | 实验配置列表，最多 5 个。离线实验可不传或传空数组；在线实验至少传 1 个。 | \\[{"label": "A", "name": "experimentA", "modelName": "qwen3.7-plus", "modelProvider": "dashscope", "modelParameters": {"temperature": 0.7, "topP": 0.8, "presencePenalty": 0.0, "frequencyPenalty": 0.0}, "promptTemplate": \\[{"role": "system", "content": "你是阿里云 ARMS 产品答疑机器人"}, {"role": "user", "content": "{{input}}"}\\]}, {"label": "B", "name": "experimentB", "modelName": "qwen3.7-max", "modelProvider": "dashscope", "modelParameters": {"temperature": 0.7, "topP": 0.8, "presencePenalty": 0.0, "frequencyPenalty": 0.0}, "promptTemplate": \\[{"role": "system", "content": "你是阿里云 ARMS 产品答疑机器人"}, {"role": "user", "content": "{{input}}"}\\]}\\] |
|     | ExperimentConfig | 否   | 单个实验分组配置。在线实验必填 label、name、modelName；非 agent 模式需提供 promptTemplate。 |     |
| evaluators | array | 否   | 评估器列表。配置后实验完成时可自动触发评估。 | \\[{"evaluatorRef": "Builtin.agent\\_correctness", "name": "Builtin.agent\\_correctness", "type": "AGENT", "resultName": "Builtin.agent\\_correctness", "resultType": "score", "variableMapping": {"input": "experiment\\_input", "output": "experiment\\_output", "expected\\_output": "dataset.ground\\_truth\\_json"}, "filters": {"query": "", "sample": "100"}, "config": {"variables": \\[\\], "prompt": ""}}, {"evaluatorRef": "rca-toxicity-safety-accuracy", "name": "rca-toxicity-safety-accuracy", "type": "AGENT", "resultName": "rca-toxicity-safety-accuracy", "resultType": "score", "variableMapping": {"input": "experiment\\_input", "output": "experiment\\_output", "question": "dataset.question", "expected\\_output": "dataset.ground\\_truth\\_json", "payload\\_json": "dataset.payload\\_json"}, "filters": {"query": "", "sample": "100"}, "config": {"variables": \\[\\], "prompt": ""}}\\] |
|     | [Evaluator](https://help.aliyun.com/zh/document_detail/3045378.html) | 否   | 单个评估器配置对象。 |     |
| selectedItemIds | array | 否   | 部分数据集模式下选定的数据项 ID 列表，需与 `datasetId` 配合使用。 | \\["019ef4d5-a0f0-7114-832d-5542d771cd8c", "019f1729-be9b-7769-a006-8e98023ad7ad"\\] |
|     | string | 否   | 数据集中的单条数据项 ID。 | 019ef4d5-a0f0-7114-832d-5542d771cd8c |
| querySql | string | 否   | 部分数据集模式下的自定义查询 SQL 子句。`selectedItemIds` 为空时可使用。 | status='OK' |
| input | object | 否   | 可选。 | {"question": "如何退款？"} |

`experimentType` 请求传 `OFFLINE` / `ONLINE`，查询时返回 `offline` / `online`。

关于 `experiments`：

-   `OFFLINE`：可不传或传空数组。离线分组在 CreateExperimentRun 时通过 `offlineExperiments` 指定。
    
-   `ONLINE`：至少传 1 个实验分组（最多 5 个）。
    

### 离线实验请求示例

```
{
  "planName": "rca_benchmark_eval_experiment",
  "experimentType": "OFFLINE",
  "description": "",
  "datasetId": "rca_benckmark_eval",
  "evaluators": [
    {
      "evaluatorRef": "Builtin.agent_correctness",
      "name": "Builtin.agent_correctness",
      "type": "AGENT",
      "resultName": "Builtin.agent_correctness",
      "resultType": "score",
      "variableMapping": {
        "input": "experiment_input",
        "output": "experiment_output",
        "expected_output": "dataset.ground_truth_json"
      },
      "filters": {
        "query": "",
        "sample": "100"
      },
      "config": {
        "variables": [],
        "prompt": ""
      }
    },
    {
      "evaluatorRef": "rca-toxicity-safety-accuracy",
      "name": "rca-toxicity-safety-accuracy",
      "type": "AGENT",
      "resultName": "rca-toxicity-safety-accuracy",
      "resultType": "score",
      "variableMapping": {
        "input": "experiment_input",
        "output": "experiment_output",
        "question": "dataset.question",
        "expected_output": "dataset.ground_truth_json",
        "payload_json": "dataset.payload_json"
      },
      "filters": {
        "query": "",
        "sample": "100"
      },
      "config": {
        "variables": [],
        "prompt": ""
      }
    }
  ]
}
```

### 在线实验请求示例

```
{
  "planName": "arms_agent_experiment",
  "experimentType": "ONLINE",
  "description": "",
  "datasetId": "arms_customer_agent_level1",
  "experiments": [
    {
      "label": "A",
      "name": "experimentA",
      "modelName": "qwen3.7-plus",
      "modelProvider": "dashscope",
      "modelParameters": {
        "temperature": 0.7,
        "topP": 0.8,
        "presencePenalty": 0.0,
        "frequencyPenalty": 0.0
      },
      "promptTemplate": [
        {
          "role": "system",
          "content": "你是阿里云 ARMS 产品答疑机器人"
        },
        {
          "role": "user",
          "content": "{{input}}"
        }
      ]
    },
    {
      "label": "B",
      "name": "experimentB",
      "modelName": "qwen3.7-max",
      "modelProvider": "dashscope",
      "modelParameters": {
        "temperature": 0.7,
        "topP": 0.8,
        "presencePenalty": 0.0,
        "frequencyPenalty": 0.0
      },
      "promptTemplate": [
        {
          "role": "system",
          "content": "你是阿里云 ARMS 产品答疑机器人"
        },
        {
          "role": "user",
          "content": "{{input}}"
        }
      ]
    }
  ],
  "evaluators": [
    {
      "evaluatorRef": "Builtin.agent_correctness",
      "name": "Builtin.agent_correctness",
      "type": "AGENT",
      "resultName": "Builtin.agent_correctness",
      "resultType": "score",
      "variableMapping": {
        "input": "experiment_input",
        "output": "experiment_output",
        "expected_output": "dataset.expected_output"
      },
      "filters": {
        "query": "",
        "sample": "100"
      },
      "config": {
        "variables": [],
        "prompt": ""
      }
    }
  ]
}
```

## **返回参数**

| **名称** | **类型** | **描述** | **示例值** |
| --- | --- | --- | --- |
|     | object | 创建实验计划响应。 |     |
| requestId | string | 请求 ID。 | 3FE4CD1E-FF41-56BE-B590-7A021D9C1524 |
| planId | string | 实验计划 ID。 | exp-plan-e95bff54685a4ae29ff3a834c1008a71 |
| status | string | 创建结果。成功为 `created`。 **枚举值：** - created : created - error : error | created |
| message | string | 提示信息。 | 实验计划创建成功 |

成功时返回 `planId`，HTTP 201。创建后不会自动执行，需再调用 CreateExperimentRun。

## 示例

正常返回示例

`JSON`格式

```
{
  "requestId": "3FE4CD1E-FF41-56BE-B590-7A021D9C1524",
  "planId": "exp-plan-e95bff54685a4ae29ff3a834c1008a71",
  "status": "created",
  "message": "实验计划创建成功"
}
```

## 错误码

访问[错误中心](https://api.aliyun.com/document/AgentLoop/2026-05-20/errorCode)查看更多错误码。

## **变更历史**

更多信息，参考[变更详情](https://api.aliyun.com/document/AgentLoop/2026-05-20/CreateExperimentPlan#workbench-doc-change-demo)。