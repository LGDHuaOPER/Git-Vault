---
title: "UpdateExperimentRun - 更新实验运行"
source: "https://help.aliyun.com/zh/document_detail/3047511.html?spm=a2c4g.11186623.help-menu-3033820.d_6_1_3_6_9.51da6bcfoQozAM"
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
"word-count": "558"
更新时间: "2026-07-23 11:27:43"
---
更新实验运行。

## 接口说明

调用 UpdateExperimentRun 更新实验记录的名称、状态和任务计数。未传字段保持不变。离线实验典型顺序：running → 进度回写 → completed。

## 调试

[您可以在OpenAPI Explorer中直接运行该接口，免去您计算签名的困扰。运行成功后，OpenAPI Explorer可以自动生成SDK代码示例。](https://api.aliyun.com/api/AgentLoop/2026-05-20/UpdateExperimentRun)

 [![](https://img.alicdn.com/tfs/TB16JcyXHr1gK0jSZR0XXbP8XXa-24-26.png) 调试](https://api.aliyun.com/api/AgentLoop/2026-05-20/UpdateExperimentRun)

## **授权信息**

当前API暂无授权信息透出。

## 请求语法

```
PUT /api/v1/experimentruns/{agentSpace}/records/{recordId} HTTP/1.1
```

## 路径参数

| **名称** | **类型** | **必填** | **描述** | **示例值** |
| --- | --- | --- | --- | --- |
| agentSpace | string | 否   | AgentSpace 名称。 | al-playground-cn-hongkong |
| recordId | string | 否   | 实验记录 ID。 | a5397261-6e6d-4e45-bf52-feb8686f7524 |

## 请求参数

| **名称** | **类型** | **必填** | **描述** | **示例值** |
| --- | --- | --- | --- | --- |
| clientToken | string | 否   | 可选。 | a1b2c3d4-1234-5678-90ab-cdef12345678 |
| body | object | 否   | 请求体。未传字段保持不变。 | {"status": "running", "totalTasks": 20, "executedAt": 1784719439255, "recordName": "rca\\_benchmark\\_eval\\_experiment 2026/07/22 19:23:59"} |
| recordName | string | 否   | 实验记录名称。 | rca\\_benchmark\\_eval\\_experiment 2026/07/22 19:23:59 |
| status | string | 否   | 实验记录状态。设置为 cancelled 时取消执行。 **枚举值：** - running : running - pending : pending - cancelled : cancelled - completed : completed - failed : failed | running |
| totalTasks | integer | 否   | 总任务数。 | 20  |
| completedTasks | integer | 否   | 已完成任务数。 | 10  |
| failedTasks | integer | 否   | 失败任务数。 | 0   |
| executedAt | integer | 否   | 实验执行时间，毫秒级 Unix 时间戳。 | 1784719439255 |
| completedAt | integer | 否   | 实验完成时间，毫秒级 Unix 时间戳。 | 1784719989371 |

### 离线实验：开始执行\\n\\n\`\`\`json\\n{

"status": "running", "totalTasks": 20, "executedAt": 1784719439255, "recordName": "rca\_benchmark\_eval\_experiment 2026/07/22 19:23:59" }\\n`\n\n### 离线实验：进度回写\n\n`json\\n{ "completedTasks": 10, "failedTasks": 0, "totalTasks": 20 }\\n`\n\n### 离线实验：标记完成\n\n`json\\n{ "status": "completed", "completedTasks": 20, "failedTasks": 0, "totalTasks": 20, "completedAt": 1784719989371 }\\n`\n\n### 取消执行\n\n`json\\n{ "status": "cancelled" }\\n\`\`\`

## **返回参数**

| **名称** | **类型** | **描述** | **示例值** |
| --- | --- | --- | --- |
|     | object | 更新实验运行响应。 |     |
| requestId | string | 请求 ID。 | 019F89B5-1B07-3BB3-A32E-F5B007029E9C |
| recordId | string | 实验记录 ID。 | a5397261-6e6d-4e45-bf52-feb8686f7524 |
| status | string | 更新后的状态（落库值）。 **枚举值：** - running : running - pending : pending - eval\\_cancelled : eval\\_cancelled - cancelled : cancelled - completed : completed - failed : failed | running |
| message | string | 提示信息。 | 实验记录更新成功 |

本接口返回的 `status` 为落库值。查询详情时 GetExperimentRun 可能将其展示为 `evaluating` / `eval_cancelling` 等计算状态。\\n\\n`json\n{ "requestId": "019F89B5-1B07-3BB3-A32E-F5B007029E9C", "recordId": "a5397261-6e6d-4e45-bf52-feb8686f7524", "status": "running", "message": "实验记录更新成功" }\n`

## 示例

正常返回示例

`JSON`格式

```
{
  "requestId": "019F89B5-1B07-3BB3-A32E-F5B007029E9C",
  "recordId": "a5397261-6e6d-4e45-bf52-feb8686f7524",
  "status": "running",
  "message": "实验记录更新成功"
}
```

## 错误码

访问[错误中心](https://api.aliyun.com/document/AgentLoop/2026-05-20/errorCode)查看更多错误码。

## **变更历史**

更多信息，参考[变更详情](https://api.aliyun.com/document/AgentLoop/2026-05-20/UpdateExperimentRun#workbench-doc-change-demo)。