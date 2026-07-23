---
title: "CreateEvaluationTask - 创建评估任务"
source: "https://help.aliyun.com/zh/document_detail/3045654.html?spm=a2c4g.11186623.help-menu-3033820.d_6_1_3_5_0_2.42fb15a0FJVgD8"
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
"word-count": "752"
更新时间: "2026-07-08 11:14:27"
---
创建评估任务。

## 接口说明

调用 CreateEvaluationTask 在指定 AgentSpace 下创建评估任务。服务端会校验 AgentSpace 权限、初始化评估结果存储、检查任务名称唯一性，并根据 `taskMode` 与 `runStrategies` 异步创建和执行 EvaluationRun。

该接口适用于对 Trace、Dataset 或 SLS Log 数据运行内置或自定义评估器，支持历史回填和持续评估两类执行策略。

## 调试

[您可以在OpenAPI Explorer中直接运行该接口，免去您计算签名的困扰。运行成功后，OpenAPI Explorer可以自动生成SDK代码示例。](https://api.aliyun.com/api/AgentLoop/2026-05-20/CreateEvaluationTask)[您可以在OpenAPI Explorer中直接运行该接口，免去您计算签名的困扰。运行成功后，OpenAPI Explorer可以自动生成SDK代码示例。](https://api.alibabacloud.com/api/AgentLoop/2026-05-20/CreateEvaluationTask)

 [![](https://img.alicdn.com/tfs/TB16JcyXHr1gK0jSZR0XXbP8XXa-24-26.png) 调试](https://api.aliyun.com/api/AgentLoop/2026-05-20/CreateEvaluationTask)

## **授权信息**

当前API暂无授权信息透出。

## 请求语法

```
POST /api/v1/evaluation-task/{agentSpace} HTTP/1.1
```

## 路径参数

| **名称** | **类型** | **必填** | **描述** | **示例值** |
| --- | --- | --- | --- | --- |
| agentSpace | string | 否   | AgentSpace 名称。 | prod-agentspace |

## 请求参数

| **名称** | **类型** | **必填** | **描述** | **示例值** |
| --- | --- | --- | --- | --- |
| body | object | 否   | 请求体。 | {"taskName":"trace\\_task\\_completion\\_eval","taskMode":"batch","dataType":"trace","evaluators":\\[{"evaluatorRef":"Builtin.agent\\_task\\_completion","resultName":"agent\\_task\\_completion","resultType":"score","variableMapping":{"input":"trace.input","output":"trace.output","agent\\_trajectory":"trace.agent\\_trajectory"}}\\],"config":{"dataScope":"trace"}} |
| taskName | string | 否   | 任务名称，同一用户同一 AgentSpace 下不能与未删除任务重名，长度不超过 256 字符。 | trace\\_task\\_completion\\_eval |
| taskMode | string | 否   | 评估任务模式。`batch` 创建持久评估任务。 **枚举值：** - batch : batch | batch |
| dataType | string | 否   | 评估对象的数据来源类型。链路 Trace 评估使用 `trace`。 **枚举值：** - trace : trace - log : log - atif : atif - dataset : dataset | trace |
| dataFilter | string | 否   | 评估数据筛选条件，支持 JSON 对象或 JSON 字符串。常用字段包括 `query`、`provided`、`maxRecords`、`samplingRate`。 | {"query":"serviceName='checkout-service'","maxRecords":10,"samplingRate":100} |
| evaluators | array | 否   | 评估器配置列表，不能为空。同一任务内以 `evaluatorRef` 优先，否则以 `name` 作为唯一标识。 | \\[{"evaluatorRef":"Builtin.agent\\_task\\_completion","resultName":"agent\\_task\\_completion","resultType":"score","variableMapping":{"input":"trace.input","output":"trace.output","agent\\_trajectory":"trace.agent\\_trajectory"}}\\] |
|     | [Evaluator](https://help.aliyun.com/zh/document_detail/3045378.html) | 否   | 单个评估器配置对象。 |     |
| channel | string | 否   | 任务来源。未传时后端默认为 `default`。 **枚举值：** - default : default | default |
| config | object | 否   | 数据源和执行配置。`dataType=trace` 时后端自动补齐 SLS Project 和 `storeName=logstore-tracing`；链路级 Trace 评估建议传 `dataScope=trace`。 | {"dataScope":"trace"} |
|     | string | 否   | 单个配置项的值，键名由具体字段约定决定。 | trace |
| tags | object | 否   | 任务标签键值对。默认无需传递；仅在需要按业务标签关联或过滤任务时传入。 | {"env":"prod","serviceId":"checkout-service","planId":"plan-20260703"} |
|     | string | 否   | 单个任务标签值，键名按业务维度自定义。 | prod |
| runStrategies | RunStrategies | 否   | 任务执行策略，支持 JSON 对象或 JSON 字符串。`backfill` 用于历史数据回填，`continuous` 用于持续评估新增数据。 |     |
| description | string | 否   | 评估任务描述。 | 评估线上 Agent 链路任务完成度 |
| clientToken | string | 否   | 幂等 Token。CloudSpec 声明了该查询参数，当前后端未做幂等比对。 | a1b2c3d4-1234-5678-90ab-cdef12345678 |

## **返回参数**

| **名称** | **类型** | **描述** | **示例值** |
| --- | --- | --- | --- |
|     | object | Schema of Response |     |
| requestId | string | 请求 ID。 | 3FE4CD1E-FF41-56BE-B590-7A021D9C1524 |
| taskId | string | 评估任务 ID。 | eval-task-8b36f2e2b1f94f9c91ce7a4b0f6d9c25 |
| status | string | 评估任务状态。创建后通常为 `Pending`，异步编排后可能进入 `Running` 或 `Scheduling`。 **枚举值：** - Failed : Failed - Running : Running - Completed : Completed - Scheduling : Scheduling - Deleted : Deleted - Terminated : Terminated - Pending : Pending | Pending |

## 示例

正常返回示例

`JSON`格式

```
{
  "requestId": "3FE4CD1E-FF41-56BE-B590-7A021D9C1524",
  "taskId": "eval-task-8b36f2e2b1f94f9c91ce7a4b0f6d9c25",
  "status": "Pending"
}
```

## 错误码

访问[错误中心](https://api.aliyun.com/document/AgentLoop/2026-05-20/errorCode)[错误中心](https://api.alibabacloud.com/document/AgentLoop/2026-05-20/errorCode)查看更多错误码。

## **变更历史**

更多信息，参考[变更详情](https://api.aliyun.com/document/AgentLoop/2026-05-20/CreateEvaluationTask#workbench-doc-change-demo)[变更详情](https://api.alibabacloud.com/document/AgentLoop/2026-05-20/CreateEvaluationTask#workbench-doc-change-demo)。