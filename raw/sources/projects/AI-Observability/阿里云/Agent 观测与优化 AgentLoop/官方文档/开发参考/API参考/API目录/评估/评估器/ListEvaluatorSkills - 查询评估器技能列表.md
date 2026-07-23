---
title: "ListEvaluatorSkills - 查询评估器技能列表"
source: "https://help.aliyun.com/zh/document_detail/3045656.html?spm=a2c4g.11186623.help-menu-3033820.d_6_1_3_5_1_5.2c5624e0FcAPYB"
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
"word-count": "417"
更新时间: "2026-07-08 11:15:33"
---
查询评估器技能列表。

## 调试

[您可以在OpenAPI Explorer中直接运行该接口，免去您计算签名的困扰。运行成功后，OpenAPI Explorer可以自动生成SDK代码示例。](https://api.aliyun.com/api/AgentLoop/2026-05-20/ListEvaluatorSkills)[您可以在OpenAPI Explorer中直接运行该接口，免去您计算签名的困扰。运行成功后，OpenAPI Explorer可以自动生成SDK代码示例。](https://api.alibabacloud.com/api/AgentLoop/2026-05-20/ListEvaluatorSkills)

 [![](https://img.alicdn.com/tfs/TB16JcyXHr1gK0jSZR0XXbP8XXa-24-26.png) 调试](https://api.aliyun.com/api/AgentLoop/2026-05-20/ListEvaluatorSkills)

## **授权信息**

当前API暂无授权信息透出。

## 请求语法

```
GET /api/v1/evaluator/{name}/skills HTTP/1.1
```

## 路径参数

| **名称** | **类型** | **必填** | **描述** | **示例值** |
| --- | --- | --- | --- | --- |
| name | string | 是   | 评估器名称。 | trace\\_task\\_completion |

## 请求参数

| **名称** | **类型** | **必填** | **描述** | **示例值** |
| --- | --- | --- | --- | --- |
| agentSpace | string | 是   | AgentSpace 名称。 | prod-agentspace |
| maxResults | integer | 否   | 每页条数。 | 20  |
| nextToken | string | 否   | 下一页分页 Token。 | eyJuZXh0IjoiMjAifQ== |

## **返回参数**

| **名称** | **类型** | **描述** | **示例值** |
| --- | --- | --- | --- |
|     | object | Schema of Response |     |
| requestId | string | 请求 ID。 | 3FE4CD1E-FF41-56BE-B590-7A021D9C1524 |
| total | integer | 技能总数。 | 3   |
| nextToken | string | 下一页分页 Token。 | eyJuZXh0IjoiNDAifQ== |
| maxResults | integer | 本次请求使用的每页条数。 | 20  |
| skills | array<object> | 技能摘要列表。 | \\[{"skillName":"trace\\_context\\_loader","displayName":"Trace 上下文读取","enable":true}\\] |
|     | object | 单个技能摘要对象。 | {"skillName":"trace\\_context\\_loader"} |
| skillName | string | 技能名称。 | trace\\_context\\_loader |
| displayName | string | 显示名称。 | Trace 上下文读取 |
| description | string | 技能描述。 | 读取链路上下文辅助评估 |
| enable | boolean | 是否启用技能。 **枚举值：** - true : true - false : false | true |
| latestVersion | string | 最新版本。CloudSpec 声明该字段，当前后端响应未填充。 | 1782816000000 |
| createdAt | integer | 创建时间。CloudSpec 声明为 int64，当前后端返回 StarOps `createTime` 字符串字段。 | 1782816000 |
| updatedAt | integer | 更新时间。CloudSpec 声明为 int64，当前后端返回 StarOps `updateTime` 字符串字段。 | 1782816600 |

## 示例

正常返回示例

`JSON`格式

```
{
  "requestId": "3FE4CD1E-FF41-56BE-B590-7A021D9C1524",
  "total": 3,
  "nextToken": "eyJuZXh0IjoiNDAifQ==",
  "maxResults": 20,
  "skills": [
    {
      "skillName": "trace_context_loader",
      "displayName": "Trace 上下文读取",
      "description": "读取链路上下文辅助评估",
      "enable": true,
      "latestVersion": "1782816000000",
      "createdAt": 1782816000,
      "updatedAt": 1782816600
    }
  ]
}
```

## 错误码

访问[错误中心](https://api.aliyun.com/document/AgentLoop/2026-05-20/errorCode)[错误中心](https://api.alibabacloud.com/document/AgentLoop/2026-05-20/errorCode)查看更多错误码。

## **变更历史**

更多信息，参考[变更详情](https://api.aliyun.com/document/AgentLoop/2026-05-20/ListEvaluatorSkills#workbench-doc-change-demo)[变更详情](https://api.alibabacloud.com/document/AgentLoop/2026-05-20/ListEvaluatorSkills#workbench-doc-change-demo)。