---
title: "UpdateEvaluatorSkill - 更新评估器技能"
source: "https://help.aliyun.com/zh/document_detail/3045676.html?spm=a2c4g.11186623.help-menu-3033820.d_6_1_3_5_1_8.70b3a070TiqGxS"
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
"word-count": "349"
更新时间: "2026-07-08 11:31:19"
---
更新评估器技能。

## 调试

[您可以在OpenAPI Explorer中直接运行该接口，免去您计算签名的困扰。运行成功后，OpenAPI Explorer可以自动生成SDK代码示例。](https://api.aliyun.com/api/AgentLoop/2026-05-20/UpdateEvaluatorSkill)[您可以在OpenAPI Explorer中直接运行该接口，免去您计算签名的困扰。运行成功后，OpenAPI Explorer可以自动生成SDK代码示例。](https://api.alibabacloud.com/api/AgentLoop/2026-05-20/UpdateEvaluatorSkill)

 [![](https://img.alicdn.com/tfs/TB16JcyXHr1gK0jSZR0XXbP8XXa-24-26.png) 调试](https://api.aliyun.com/api/AgentLoop/2026-05-20/UpdateEvaluatorSkill)

## **授权信息**

当前API暂无授权信息透出。

## 请求语法

```
PUT /api/v1/evaluator/{name}/skill/{skillName} HTTP/1.1
```

## 路径参数

| **名称** | **类型** | **必填** | **描述** | **示例值** |
| --- | --- | --- | --- | --- |
| name | string | 是   | 评估器名称。 | trace\\_task\\_completion |
| skillName | string | 是   | 技能名称。 | trace\\_context\\_loader |

## 请求参数

| **名称** | **类型** | **必填** | **描述** | **示例值** |
| --- | --- | --- | --- | --- |
| agentSpace | string | 是   | AgentSpace 名称。 | prod-agentspace |
| body | object | 否   | 请求体。 | {"displayName":"Trace 上下文读取","enable":true,"files":\\[{"name":"SKILL.md","content":"# Trace Context Loader"}\\]} |
| displayName | string | 否   | 技能显示名称。 | Trace 上下文读取 |
| description | string | 否   | 技能描述。 | 读取链路上下文辅助评估 |
| enable | boolean | 否   | 是否启用技能。 **枚举值：** - true : true - false : false | true |
| files | array<object> | 否   | 技能文件列表。传入时更新技能文件内容。 | \\[{"name":"SKILL.md","content":"# Trace Context Loader","remark":"主技能说明"}\\] |
|     | object | 否   | 单个技能文件对象。 | {"name":"SKILL.md"} |
| name | string | 是   | 技能文件名。 | SKILL.md |
| content | string | 是   | 技能文件内容。 | \\# Trace Context Loader |
| remark | string | 否   | 文件备注。 | 主技能说明 |
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

更多信息，参考[变更详情](https://api.aliyun.com/document/AgentLoop/2026-05-20/UpdateEvaluatorSkill#workbench-doc-change-demo)[变更详情](https://api.alibabacloud.com/document/AgentLoop/2026-05-20/UpdateEvaluatorSkill#workbench-doc-change-demo)。