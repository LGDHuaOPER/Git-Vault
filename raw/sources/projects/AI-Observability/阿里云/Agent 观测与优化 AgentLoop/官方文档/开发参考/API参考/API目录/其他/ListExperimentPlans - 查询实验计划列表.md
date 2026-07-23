---
title: "ListExperimentPlans - 查询实验计划列表"
source: "https://help.aliyun.com/zh/document_detail/3047506.html?spm=a2c4g.11186623.help-menu-3033820.d_6_1_3_6_6.29aa13b5hE1ZFR"
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
"word-count": "596"
更新时间: "2026-07-23 11:09:40"
---
查询实验计划列表。

## 接口说明

调用 ListExperimentPlans 查询当前账号在指定 AgentSpace 下的实验计划列表。支持按计划名称模糊搜索、按状态过滤，并使用 `offset`/`limit` 分页。

## 调试

[您可以在OpenAPI Explorer中直接运行该接口，免去您计算签名的困扰。运行成功后，OpenAPI Explorer可以自动生成SDK代码示例。](https://api.aliyun.com/api/AgentLoop/2026-05-20/ListExperimentPlans)

 [![](https://img.alicdn.com/tfs/TB16JcyXHr1gK0jSZR0XXbP8XXa-24-26.png) 调试](https://api.aliyun.com/api/AgentLoop/2026-05-20/ListExperimentPlans)

## **授权信息**

当前API暂无授权信息透出。

## 请求语法

```
GET /api/v1/experiments/{agentSpace}/plans HTTP/1.1
```

## 路径参数

| **名称** | **类型** | **必填** | **描述** | **示例值** |
| --- | --- | --- | --- | --- |
| agentSpace | string | 否   | AgentSpace 名称。 | al-playground-cn-hongkong |

## 请求参数

| **名称** | **类型** | **必填** | **描述** | **示例值** |
| --- | --- | --- | --- | --- |
| planName | string | 否   | 按计划名称模糊搜索。 | arms\\_agent |
| status | string | 否   | 按状态精确过滤。 **枚举值：** - running : running - stopped : stopped - pending : pending | pending |
| offset | integer | 否   | 偏移量，默认 0。 | 0   |
| limit | integer | 否   | 返回条数，默认 20。 | 20  |
| maxResults | integer | 否   | 可选。分页请优先使用 `offset` 与 `limit`。 | 20  |
| nextToken | string | 否   | 可选。分页请优先使用 `offset` 与 `limit`。 | eyJsYXN0SWQiOjEyM30= |

分页请使用 `offset` 与 `limit`。结果按创建时间倒序。

## **返回参数**

| **名称** | **类型** | **描述** | **示例值** |
| --- | --- | --- | --- |
|     | object | 实验计划列表响应。 |     |
| requestId | string | 请求 ID。 | 3FE4CD1E-FF41-56BE-B590-7A021D9C1524 |
| total | integer | 符合条件的总记录数。 | 6   |
| page | integer | 页码信息。 | 0   |
| pageSize | integer | 每页条数。 | 20  |
| plans | array | 实验计划摘要列表。 | \\[{"planId": "exp-plan-e95bff54685a4ae29ff3a834c1008a71", "planName": "rca\\_benchmark\\_eval\\_experiment", "experimentType": "offline", "description": "", "status": "pending", "datasetId": "rca\\_benckmark\\_eval", "querySql": "", "experimentCount": 5, "createdAt": 1784612365000, "updatedAt": 1784619562000}, {"planId": "exp-plan-0242d983f5d340fd8479cf2c19eb279e", "planName": "arms\\_agent\\_experiment", "experimentType": "online", "description": "", "status": "stopped", "datasetId": "arms\\_customer\\_agent\\_level1", "querySql": "", "experimentCount": 4, "createdAt": 1784257858000, "updatedAt": 1784721811000}, {"planId": "b7f0ad3d-3765-446a-a744-ab64ab8bf386", "planName": "arms\\_customer\\_agent\\_plan", "experimentType": "offline", "description": "", "status": "stopped", "datasetId": "arms\\_customer\\_agent\\_level1", "querySql": "where \\\\"input\\\\" LIKE '%探针%'", "experimentCount": 65, "createdAt": 1782310430000, "updatedAt": 1784692254000}\\] |
|     | ExperimentPlanData | 单个实验计划摘要对象。 |     |
| maxResults | integer | 最大返回条数。 | 20  |
| nextToken | string | 下一页 Token。 | eyJsYXN0SWQiOjEwMX0= |

列表不返回完整 `experiments` 与 `datasetProject`。需要完整配置时请调用 GetExperimentPlan。\\n\\n`json\n{ "total": 6, "plans": [ { "planId": "exp-plan-e95bff54685a4ae29ff3a834c1008a71", "planName": "rca_benchmark_eval_experiment", "experimentType": "offline", "description": "", "status": "pending", "datasetId": "rca_benckmark_eval", "querySql": "", "experimentCount": 5, "createdAt": 1784612365000, "updatedAt": 1784619562000 }, { "planId": "exp-plan-0242d983f5d340fd8479cf2c19eb279e", "planName": "arms_agent_experiment", "experimentType": "online", "description": "", "status": "stopped", "datasetId": "arms_customer_agent_level1", "querySql": "", "experimentCount": 4, "createdAt": 1784257858000, "updatedAt": 1784721811000 }, { "planId": "b7f0ad3d-3765-446a-a744-ab64ab8bf386", "planName": "arms_customer_agent_plan", "experimentType": "offline", "description": "", "status": "stopped", "datasetId": "arms_customer_agent_level1", "querySql": "where \"input\" LIKE '%探针%'", "experimentCount": 65, "createdAt": 1782310430000, "updatedAt": 1784692254000 } ] }\n`

## 示例

正常返回示例

`JSON`格式

```
{
  "requestId": "3FE4CD1E-FF41-56BE-B590-7A021D9C1524",
  "total": 6,
  "page": 0,
  "pageSize": 20,
  "plans": [
    {
      "planId": "",
      "planName": "",
      "experimentType": "",
      "description": "",
      "status": "",
      "datasetId": "",
      "querySql": "",
      "experimentCount": 0,
      "createdAt": 0,
      "updatedAt": 0
    }
  ],
  "maxResults": 20,
  "nextToken": "eyJsYXN0SWQiOjEwMX0="
}
```

## 错误码

访问[错误中心](https://api.aliyun.com/document/AgentLoop/2026-05-20/errorCode)查看更多错误码。

## **变更历史**

更多信息，参考[变更详情](https://api.aliyun.com/document/AgentLoop/2026-05-20/ListExperimentPlans#workbench-doc-change-demo)。