---
title: "DeleteExperimentRun - 删除实验记录"
source: "https://help.aliyun.com/zh/document_detail/3047502.html?spm=a2c4g.11186623.help-menu-3033820.d_6_1_3_6_3.1841524eLhC9cP"
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
"word-count": "226"
更新时间: "2026-07-23 11:00:38"
---
删除实验记录。

## 接口说明

调用 DeleteExperimentRun 删除指定实验执行记录。删除记录不会删除其所属的实验计划。

## 调试

[您可以在OpenAPI Explorer中直接运行该接口，免去您计算签名的困扰。运行成功后，OpenAPI Explorer可以自动生成SDK代码示例。](https://api.aliyun.com/api/AgentLoop/2026-05-20/DeleteExperimentRun)

 [![](https://img.alicdn.com/tfs/TB16JcyXHr1gK0jSZR0XXbP8XXa-24-26.png) 调试](https://api.aliyun.com/api/AgentLoop/2026-05-20/DeleteExperimentRun)

## **授权信息**

当前API暂无授权信息透出。

## 请求语法

```
DELETE /api/v1/experimentruns/{agentSpace}/records/{recordId} HTTP/1.1
```

## 路径参数

| **名称** | **类型** | **必填** | **描述** | **示例值** |
| --- | --- | --- | --- | --- |
| agentSpace | string | 否   | AgentSpace 名称。 | al-playground-cn-hongkong |
| recordId | string | 否   | 实验记录 ID。 | exp-run-f6d419b0ed3d43a7b585948a55efc07b |

## 请求参数

| **名称** | **类型** | **必填** | **描述** | **示例值** |
| --- | --- | --- | --- | --- |

当前API无需请求参数

请传入目标 `agentSpace` 和 `recordId`。

## **返回参数**

| **名称** | **类型** | **描述** | **示例值** |
| --- | --- | --- | --- |
|     | object | 删除实验记录响应。 |     |
| requestId | string | 请求 ID。 | 019F89BE-9190-3AAA-B5A4-DBAE3BABBBEA |

### 响应示例\\n\\n\`\`\`json\\n{

"requestId": "019F89BE-9190-3AAA-B5A4-DBAE3BABBBEA" }\\n\`\`\`

## 示例

正常返回示例

`JSON`格式

```
{
  "requestId": "019F89BE-9190-3AAA-B5A4-DBAE3BABBBEA"
}
```

## 错误码

访问[错误中心](https://api.aliyun.com/document/AgentLoop/2026-05-20/errorCode)查看更多错误码。

## **变更历史**

更多信息，参考[变更详情](https://api.aliyun.com/document/AgentLoop/2026-05-20/DeleteExperimentRun#workbench-doc-change-demo)。