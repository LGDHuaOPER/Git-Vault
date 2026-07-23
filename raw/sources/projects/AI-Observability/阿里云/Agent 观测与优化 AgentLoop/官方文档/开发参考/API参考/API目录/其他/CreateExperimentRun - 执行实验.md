---
title: "CreateExperimentRun - 执行实验"
source: "https://help.aliyun.com/zh/document_detail/3047500.html?spm=a2c4g.11186623.help-menu-3033820.d_6_1_3_6_1.10a61b7fQAJKil"
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
"word-count": "662"
更新时间: "2026-07-23 10:58:57"
---
执行实验。

## 接口说明

调用 CreateExperimentRun，基于已有实验计划发起一次实验执行。在线实验通常只需传 `experimentPlanId`；离线实验需传 `offlineExperiments`（1-5 个）。

## 调试

[您可以在OpenAPI Explorer中直接运行该接口，免去您计算签名的困扰。运行成功后，OpenAPI Explorer可以自动生成SDK代码示例。](https://api.aliyun.com/api/AgentLoop/2026-05-20/CreateExperimentRun)

 [![](https://img.alicdn.com/tfs/TB16JcyXHr1gK0jSZR0XXbP8XXa-24-26.png) 调试](https://api.aliyun.com/api/AgentLoop/2026-05-20/CreateExperimentRun)

## **授权信息**

当前API暂无授权信息透出。

## 请求语法

```
POST /api/v1/experimentruns/{agentSpace}/execute HTTP/1.1
```

## 路径参数

| **名称** | **类型** | **必填** | **描述** | **示例值** |
| --- | --- | --- | --- | --- |
| agentSpace | string | 否   | AgentSpace 名称。 | al-playground-cn-hongkong |

## 请求参数

| **名称** | **类型** | **必填** | **描述** | **示例值** |
| --- | --- | --- | --- | --- |
| clientToken | string | 否   | 可选。 | a1b2c3d4-1234-5678-90ab-cdef12345678 |
| body | object | 否   | 请求体。 | {"experimentPlanId": "exp-plan-0242d983f5d340fd8479cf2c19eb279e"} |
| experimentPlanId | string | 是   | 实验计划 ID。 | exp-plan-0242d983f5d340fd8479cf2c19eb279e |
| recordName | string | 否   | 实验记录名称。不传时默认使用「计划名 + 时间戳」。 | arms\\_agent\\_experiment 2026/07/22 20:02:55 |
| status | string | 否   | 初始状态。不传时默认为 `pending`。 **枚举值：** - running : running - pending : pending - completed : completed - failed : failed | pending |
| totalTasks | integer | 否   | 总任务数。在线实验不传时按生成任务数计。 | 40  |
| completedTasks | integer | 否   | 已完成任务数。不传时默认 0。 | 0   |
| failedTasks | integer | 否   | 失败任务数。不传时默认 0。 | 0   |
| executedAt | integer | 否   | 执行时间，毫秒级 Unix 时间戳。 | 1784721775379 |
| completedAt | integer | 否   | 完成时间，毫秒级 Unix 时间戳。 | 1784721811392 |
| offlineExperiments | array | 否   | 离线实验配置列表。计划类型为 offline 时必填，数量 1-5。 | \\[{"label": "experimentA", "name": "experimentA"}\\] |
|     | OfflineExperimentConfig | 否   | 单个离线实验分组，含 label、name、可选 desc。 |     |

### 在线实验请求示例\\n\\n\`\`\`json\\n{

"experimentPlanId": "exp-plan-0242d983f5d340fd8479cf2c19eb279e" }\\n`\n\n### 离线实验请求示例\n\n`json\\n{ "experimentPlanId": "exp-plan-e95bff54685a4ae29ff3a834c1008a71", "offlineExperiments": \[ { "label": "experimentA", "name": "experimentA" } \] }\\n\`\`\`

## **返回参数**

| **名称** | **类型** | **描述** | **示例值** |
| --- | --- | --- | --- |
|     | object | 执行实验响应。 |     |
| requestId | string | 请求 ID。 | 019F89B5-1B07-3BB3-A32E-F5B007029E9C |
| recordId | string | 实验记录 ID。在线实验多为 exp-run-{uuid32}；离线实验也可能为标准 UUID。 | exp-run-f6d419b0ed3d43a7b585948a55efc07b |
| status | string | 实验记录状态。创建后通常为 pending。 **枚举值：** - running : running - pending : pending - completed : completed - failed : failed | pending |
| message | string | 提示信息。 | 实验已创建，开始执行 |

在线实验成功时 `message` 为「实验已创建，开始执行」；离线实验成功时 `message` 为「离线实验记录已创建，请通过 UpdateExperimentRun 接口更新执行进度」。\\n\\n### 在线实验响应示例\\n\\n`json\n{ "recordId": "exp-run-f6d419b0ed3d43a7b585948a55efc07b", "requestId": "019F89B5-1B07-3BB3-A32E-F5B007029E9C", "message": "实验已创建，开始执行", "status": "pending" }\n`\\n\\n### 离线实验响应示例\\n\\n`json\n{ "recordId": "a5397261-6e6d-4e45-bf52-feb8686f7524", "requestId": "019F89B5-1B07-3BB3-A32E-F5B007029E9C", "message": "离线实验记录已创建，请通过 UpdateExperimentRun 接口更新执行进度", "status": "pending" }\n`

## 示例

正常返回示例

`JSON`格式

```
{
  "requestId": "019F89B5-1B07-3BB3-A32E-F5B007029E9C",
  "recordId": "exp-run-f6d419b0ed3d43a7b585948a55efc07b",
  "status": "pending",
  "message": "实验已创建，开始执行"
}
```

## 错误码

访问[错误中心](https://api.aliyun.com/document/AgentLoop/2026-05-20/errorCode)查看更多错误码。

## **变更历史**

更多信息，参考[变更详情](https://api.aliyun.com/document/AgentLoop/2026-05-20/CreateExperimentRun#workbench-doc-change-demo)。