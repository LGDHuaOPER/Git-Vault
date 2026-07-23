---
title: "GetEvaluatorSkill - 获取评估器技能详情"
source: "https://help.aliyun.com/zh/document_detail/3045678.html?spm=a2c4g.11186623.help-menu-3033820.d_6_1_3_5_1_6.62786fc2j3lePM"
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
"word-count": "490"
更新时间: "2026-07-08 11:43:42"
---
获取评估器技能详情。

## 调试

[您可以在OpenAPI Explorer中直接运行该接口，免去您计算签名的困扰。运行成功后，OpenAPI Explorer可以自动生成SDK代码示例。](https://api.aliyun.com/api/AgentLoop/2026-05-20/GetEvaluatorSkill)[您可以在OpenAPI Explorer中直接运行该接口，免去您计算签名的困扰。运行成功后，OpenAPI Explorer可以自动生成SDK代码示例。](https://api.alibabacloud.com/api/AgentLoop/2026-05-20/GetEvaluatorSkill)

 [![](https://img.alicdn.com/tfs/TB16JcyXHr1gK0jSZR0XXbP8XXa-24-26.png) 调试](https://api.aliyun.com/api/AgentLoop/2026-05-20/GetEvaluatorSkill)

## **授权信息**

当前API暂无授权信息透出。

## 请求语法

```
GET /api/v1/evaluator/{name}/skill/{skillName} HTTP/1.1
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
| version | string | 否   | 技能版本。 | 1782816000000 |

## **返回参数**

| **名称** | **类型** | **描述** | **示例值** |
| --- | --- | --- | --- |
|     | object | Schema of Response |     |
| requestId | string | 请求 ID。 | 3FE4CD1E-FF41-56BE-B590-7A021D9C1524 |
| skill | object | 技能详情。 | {"skillName":"trace\\_context\\_loader","enable":true,"currentVersion":"1782816000000"} |
| skillName | string | 技能名称。 | trace\\_context\\_loader |
| displayName | string | 显示名称。 | Trace 上下文读取 |
| description | string | 技能描述。 | 读取链路上下文辅助评估 |
| enable | boolean | 是否启用技能。 **枚举值：** - true : true - false : false | true |
| currentVersion | string | 当前版本。 | 1782816000000 |
| latestVersion | string | 最新版本。 | 1782816000000 |
| files | array<object> | 技能文件列表。 | \\[{"name":"SKILL.md","content":"# Trace Context Loader","remark":"主技能说明"}\\] |
|     | object | 单个技能文件对象。 | {"name":"SKILL.md"} |
| name | string | 文件名。 | SKILL.md |
| content | string | 文件内容。 | \\# Trace Context Loader |
| remark | string | 文件备注。 | 主技能说明 |
| versions | array<object> | 技能版本列表。 | \\[{"version":"1782816000000","versionDescription":"首次发布版本"}\\] |
|     | object | 单个版本对象。 | {"version":"1.0.0"} |
| version | string | 版本号。 | 1782816000000 |
| versionDescription | string | 版本描述。 | 首次发布版本 |
| createdAt | integer | 版本创建时间，秒级 Unix 时间戳。 | 1782816000 |
| createdAt | integer | 创建时间，秒级 Unix 时间戳。 | 1782816000 |
| updatedAt | integer | 更新时间，秒级 Unix 时间戳。 | 1782816600 |

## 示例

正常返回示例

`JSON`格式

```
{
  "requestId": "3FE4CD1E-FF41-56BE-B590-7A021D9C1524",
  "skill": {
    "skillName": "trace_context_loader",
    "displayName": "Trace 上下文读取",
    "description": "读取链路上下文辅助评估",
    "enable": true,
    "currentVersion": "1782816000000",
    "latestVersion": "1782816000000",
    "files": [
      {
        "name": "SKILL.md",
        "content": "# Trace Context Loader",
        "remark": "主技能说明"
      }
    ],
    "versions": [
      {
        "version": "1782816000000",
        "versionDescription": "首次发布版本",
        "createdAt": 1782816000
      }
    ],
    "createdAt": 1782816000,
    "updatedAt": 1782816600
  }
}
```

## 错误码

访问[错误中心](https://api.aliyun.com/document/AgentLoop/2026-05-20/errorCode)[错误中心](https://api.alibabacloud.com/document/AgentLoop/2026-05-20/errorCode)查看更多错误码。

## **变更历史**

更多信息，参考[变更详情](https://api.aliyun.com/document/AgentLoop/2026-05-20/GetEvaluatorSkill#workbench-doc-change-demo)[变更详情](https://api.alibabacloud.com/document/AgentLoop/2026-05-20/GetEvaluatorSkill#workbench-doc-change-demo)。