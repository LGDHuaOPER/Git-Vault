---
title: "UpdateEvaluationTask - 更新评估任务"
source: "https://help.aliyun.com/zh/document_detail/3045662.html?spm=a2c4g.11186623.help-menu-3033820.d_6_1_3_5_0_3.36a066f7UU0tkW"
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
"word-count": "514"
更新时间: "2026-07-08 11:19:14"
---
更新评估任务。

## 调试

[您可以在OpenAPI Explorer中直接运行该接口，免去您计算签名的困扰。运行成功后，OpenAPI Explorer可以自动生成SDK代码示例。](https://api.aliyun.com/api/AgentLoop/2026-05-20/UpdateEvaluationTask)[您可以在OpenAPI Explorer中直接运行该接口，免去您计算签名的困扰。运行成功后，OpenAPI Explorer可以自动生成SDK代码示例。](https://api.alibabacloud.com/api/AgentLoop/2026-05-20/UpdateEvaluationTask)

 [![](https://img.alicdn.com/tfs/TB16JcyXHr1gK0jSZR0XXbP8XXa-24-26.png) 调试](https://api.aliyun.com/api/AgentLoop/2026-05-20/UpdateEvaluationTask)

## **授权信息**

当前API暂无授权信息透出。

## 请求语法

```
PUT /api/v1/evaluation-task/{agentSpace}/{taskId} HTTP/1.1
```

## 路径参数

| **名称** | **类型** | **必填** | **描述** | **示例值** |
| --- | --- | --- | --- | --- |
| agentSpace | string | 否   | AgentSpace 名称。 | prod-agentspace |
| taskId | string | 否   | 评估任务 ID。 | eval-task-8b36f2e2b1f94f9c91ce7a4b0f6d9c25 |

## 请求参数

| **名称** | **类型** | **必填** | **描述** | **示例值** |
| --- | --- | --- | --- | --- |
| body | object | 否   | 请求体。 | {"dataFilter":{"query":"serviceName='checkout-service' AND status='OK'","maxRecords":10},"runStrategies":{"continuous":{"enabled":true,"intervalUnit":"HOUR","intervalValue":1,"dataDelayMinutes":5}}} |
| dataFilter | string | 否   | 评估数据筛选条件，支持 JSON 对象或 JSON 字符串。 | {"query":"serviceName='checkout-service' AND status='OK'","maxRecords":10,"samplingRate":50} |
| evaluators | array | 否   | 新的评估器配置列表。传入时会整体替换任务评估器列表，并重新校验评估器唯一性和变量映射。 | \\[{"evaluatorRef":"Builtin.agent\\_task\\_completion","resultName":"agent\\_task\\_completion","resultType":"score","variableMapping":{"input":"trace.input","output":"trace.output","agent\\_trajectory":"trace.agent\\_trajectory"}}\\] |
|     | [Evaluator](https://help.aliyun.com/zh/document_detail/3045378.html) | 否   | 单个评估器配置对象。 |     |
| status | string | 否   | 任务状态。当前后端只允许用户主动设置为 `Terminated`；其他状态由系统推进。 **枚举值：** - Terminated : Terminated | Terminated |
| tags | object | 否   | 任务标签键值对。默认无需传递；仅在需要按业务标签关联或过滤任务时传入。 | {"env":"prod","serviceId":"checkout-service","planId":"plan-20260703"} |
|     | string | 否   | 单个任务标签值，键名按业务维度自定义。 | prod |
| config | object | 否   | 新的任务配置。部分创建期字段不可修改。 | {"dataScope":"trace"} |
|     | string | 否   | 单个配置项的值，键名由具体字段约定决定。 | trace |
| runStrategies | RunStrategies | 否   | 新的任务执行策略，支持 JSON 对象或 JSON 字符串。若任务处于 `Completed`、`Terminated` 或 `Failed`，并且新策略启用了 backfill 或 continuous，后端会把任务恢复为 `Pending` 并触发编排。 |     |
| description | string | 否   | 评估任务描述。 | 更新后的链路 Trace 任务完成度评估 |
| clientToken | string | 否   | 幂等 Token。CloudSpec 声明了该查询参数，当前后端未做幂等比对。 | a1b2c3d4-1234-5678-90ab-cdef12345678 |

## **返回参数**

| **名称** | **类型** | **描述** | **示例值** |
| --- | --- | --- | --- |
|     | object | Schema of Response |     |
| requestId | string | 请求 ID。 | 3FE4CD1E-FF41-56BE-B590-7A021D9C1524 |

## 示例

正常返回示例

`JSON`格式

```
{
  "requestId": "3FE4CD1E-FF41-56BE-B590-7A021D9C1524"
}
```

## 错误码

访问[错误中心](https://api.aliyun.com/document/AgentLoop/2026-05-20/errorCode)[错误中心](https://api.alibabacloud.com/document/AgentLoop/2026-05-20/errorCode)查看更多错误码。

## **变更历史**

更多信息，参考[变更详情](https://api.aliyun.com/document/AgentLoop/2026-05-20/UpdateEvaluationTask#workbench-doc-change-demo)[变更详情](https://api.alibabacloud.com/document/AgentLoop/2026-05-20/UpdateEvaluationTask#workbench-doc-change-demo)。