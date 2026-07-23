---
title: "ListEvaluators - 查询评估器列表"
source: "https://help.aliyun.com/zh/document_detail/3045659.html?spm=a2c4g.11186623.help-menu-3033820.d_6_1_3_5_1_0.7bf1c4f5H1SSqx"
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
"word-count": "463"
更新时间: "2026-07-08 11:17:24"
---
查询评估器列表。

## 调试

[您可以在OpenAPI Explorer中直接运行该接口，免去您计算签名的困扰。运行成功后，OpenAPI Explorer可以自动生成SDK代码示例。](https://api.aliyun.com/api/AgentLoop/2026-05-20/ListEvaluators)[您可以在OpenAPI Explorer中直接运行该接口，免去您计算签名的困扰。运行成功后，OpenAPI Explorer可以自动生成SDK代码示例。](https://api.alibabacloud.com/api/AgentLoop/2026-05-20/ListEvaluators)

 [![](https://img.alicdn.com/tfs/TB16JcyXHr1gK0jSZR0XXbP8XXa-24-26.png) 调试](https://api.aliyun.com/api/AgentLoop/2026-05-20/ListEvaluators)

## **授权信息**

当前API暂无授权信息透出。

## 请求语法

```
GET /api/v1/evaluators HTTP/1.1
```

## 请求参数

| **名称** | **类型** | **必填** | **描述** | **示例值** |
| --- | --- | --- | --- | --- |
| agentSpace | string | 是   | AgentSpace 名称。 | prod-agentspace |
| type | string | 否   | 评估器类型过滤。 **枚举值：** - AGENT : AGENT - CODE : CODE - LLM : LLM | AGENT |
| name | string | 否   | 评估器名称模糊搜索条件。 | trace\\_task\\_completion |
| source | string | 否   | 评估器来源过滤。 **枚举值：** - custom : custom - builtin : builtin | custom |
| maxResults | integer | 否   | 每页返回条数，默认 20，最大 100。 | 20  |
| nextToken | string | 否   | 下一页分页 Token。 | eyJsYXN0SWQiOjEyM30= |

## **返回参数**

| **名称** | **类型** | **描述** | **示例值** |
| --- | --- | --- | --- |
|     | object | Schema of Response |     |
| requestId | string | 请求 ID。 | 3FE4CD1E-FF41-56BE-B590-7A021D9C1524 |
| total | integer | 符合条件的评估器总数。 | 12  |
| nextToken | string | 下一页分页 Token。 | eyJsYXN0SWQiOjEzM30= |
| maxResults | integer | 本次请求使用的每页条数。 | 20  |
| evaluators | array<object> | 评估器摘要列表。 | \\[{"name":"trace\\_task\\_completion","type":"AGENT","latestVersion":"1.0.0"}\\] |
|     | array<object> | 单个评估器配置对象。 | {"evaluatorRef":"Builtin.agent\\_task\\_completion"} |
| name | string | 评估器名称。 | trace\\_task\\_completion |
| displayName | string | 显示名称。 | 链路任务完成度 |
| metricName | string | 指标名称。 | agent\\_task\\_completion |
| type | string | 评估器类型。 **枚举值：** - AGENT : AGENT - CODE : CODE - LLM : LLM | AGENT |
| description | string | 评估器描述。 | 判断 Agent 是否完成用户任务 |
| latestVersion | string | 最新版本号。 | 1.0.0 |
| properties | object | 评估器属性。 | {"agentEvaluatorMode":"raw\\_prompt"} |
| annotations | array | 注解标记列表。 | \\["\\_\\_en"\\] |
|     | string | 单个注解标记。 | \\_\\_en |
| createdAt | integer | 创建时间，秒级 Unix 时间戳。 | 1782816000 |
| updatedAt | integer | 更新时间，秒级 Unix 时间戳。 | 1782816600 |

## 示例

正常返回示例

`JSON`格式

```
{
  "requestId": "3FE4CD1E-FF41-56BE-B590-7A021D9C1524",
  "total": 12,
  "nextToken": "eyJsYXN0SWQiOjEzM30=",
  "maxResults": 20,
  "evaluators": [
    {
      "name": "trace_task_completion",
      "displayName": "链路任务完成度",
      "metricName": "agent_task_completion",
      "type": "AGENT",
      "description": "判断 Agent 是否完成用户任务",
      "latestVersion": "1.0.0",
      "properties": {
        "agentEvaluatorMode": "raw_prompt"
      },
      "annotations": [
        "__en"
      ],
      "createdAt": 1782816000,
      "updatedAt": 1782816600
    }
  ]
}
```

## 错误码

访问[错误中心](https://api.aliyun.com/document/AgentLoop/2026-05-20/errorCode)[错误中心](https://api.alibabacloud.com/document/AgentLoop/2026-05-20/errorCode)查看更多错误码。

## **变更历史**

更多信息，参考[变更详情](https://api.aliyun.com/document/AgentLoop/2026-05-20/ListEvaluators#workbench-doc-change-demo)[变更详情](https://api.alibabacloud.com/document/AgentLoop/2026-05-20/ListEvaluators#workbench-doc-change-demo)。