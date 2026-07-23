---
title: "DeleteExperimentPlan - 删除实验计划"
source: "https://help.aliyun.com/zh/document_detail/3047501.html?spm=a2c4g.11186623.help-menu-3033820.d_6_1_3_6_2.22596495uo5m87"
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
"word-count": "269"
更新时间: "2026-07-23 10:59:38"
---
删除实验计划。

## 接口说明

调用 DeleteExperimentPlan 删除指定实验计划。删除后无法再基于该计划发起新的执行；已产生的实验记录仍可查询。

## 调试

[您可以在OpenAPI Explorer中直接运行该接口，免去您计算签名的困扰。运行成功后，OpenAPI Explorer可以自动生成SDK代码示例。](https://api.aliyun.com/api/AgentLoop/2026-05-20/DeleteExperimentPlan)

 [![](https://img.alicdn.com/tfs/TB16JcyXHr1gK0jSZR0XXbP8XXa-24-26.png) 调试](https://api.aliyun.com/api/AgentLoop/2026-05-20/DeleteExperimentPlan)

## **授权信息**

当前API暂无授权信息透出。

## 请求语法

```
DELETE /api/v1/experiments/{agentSpace}/plans/{planId} HTTP/1.1
```

## 路径参数

| **名称** | **类型** | **必填** | **描述** | **示例值** |
| --- | --- | --- | --- | --- |
| agentSpace | string | 否   | AgentSpace 名称。 | al-playground-cn-hongkong |
| planId | string | 否   | 实验计划 ID。 | exp-plan-aa1a66b074bc42aa8696c73c7dc9b718 |

## 请求参数

| **名称** | **类型** | **必填** | **描述** | **示例值** |
| --- | --- | --- | --- | --- |

当前API无需请求参数

请传入目标 `agentSpace` 和 `planId`。

## **返回参数**

| **名称** | **类型** | **描述** | **示例值** |
| --- | --- | --- | --- |
|     | object | 删除实验计划响应。 |     |
| requestId | string | 请求 ID。 | 3FE4CD1E-FF41-56BE-B590-7A021D9C1524 |
| planId | string | 实验计划 ID。 | exp-plan-aa1a66b074bc42aa8696c73c7dc9b718 |
| status | string | 删除结果。成功为 deleted。 | deleted |

不会级联删除已有 ExperimentRun。\\n\\n`json\n{ "planId": "exp-plan-aa1a66b074bc42aa8696c73c7dc9b718", "status": "deleted" }\n`

## 示例

正常返回示例

`JSON`格式

```
{
  "requestId": "3FE4CD1E-FF41-56BE-B590-7A021D9C1524",
  "planId": "exp-plan-aa1a66b074bc42aa8696c73c7dc9b718",
  "status": "deleted"
}
```

## 错误码

访问[错误中心](https://api.aliyun.com/document/AgentLoop/2026-05-20/errorCode)查看更多错误码。

## **变更历史**

更多信息，参考[变更详情](https://api.aliyun.com/document/AgentLoop/2026-05-20/DeleteExperimentPlan#workbench-doc-change-demo)。