---
title: "ListDatasets - 列出数据集"
source: "https://help.aliyun.com/zh/document_detail/3045464.html?spm=a2c4g.11186623.help-menu-3033820.d_6_1_3_3_5.5bf6711b4qhoQN"
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
"word-count": "635"
更新时间: "2026-07-16 19:04:31"
---
查询数据集列表

## 调试

[您可以在OpenAPI Explorer中直接运行该接口，免去您计算签名的困扰。运行成功后，OpenAPI Explorer可以自动生成SDK代码示例。](https://api.aliyun.com/api/AgentLoop/2026-05-20/ListDatasets)

 [![](https://img.alicdn.com/tfs/TB16JcyXHr1gK0jSZR0XXbP8XXa-24-26.png) 调试](https://api.aliyun.com/api/AgentLoop/2026-05-20/ListDatasets)

## **授权信息**

下表是API对应的授权信息，可以在RAM权限策略语句的`Action`元素中使用，用来给RAM用户或RAM角色授予调用此API的权限。具体说明如下：

-   操作：是指具体的权限点。
    
-   访问级别：是指每个操作的访问级别，取值为写入（Write）、读取（Read）或列出（List）。
    
-   资源类型：是指操作中支持授权的资源类型。具体说明如下：
    
    -   对于必选的资源类型，用前面加 \* 表示。
        
    -   对于不支持资源级授权的操作，用`全部资源`表示。
        
-   条件关键字：是指云产品自身定义的条件关键字。
    
-   关联操作：是指成功执行操作所需要的其他权限。操作者必须同时具备关联操作的权限，操作才能成功。
    

| **操作** | **访问级别** | **资源类型** | **条件关键字** | **关联操作** |
| --- | --- | --- | --- | --- |
| agentloop:ListDatasets | list | \\*Dataset `acs:agentloop:{#regionId}:{#accountId}:agentspace/{#AgentSpaceName}/dataset/*` | 无   | 无   |

## 请求语法

```
GET /agentspace/{agentSpace}/dataset HTTP/1.1
```

## 路径参数

| **名称** | **类型** | **必填** | **描述** | **示例值** |
| --- | --- | --- | --- | --- |
| agentSpace | string | 是   | 智能体空间名称 | sop-agent |

## 请求参数

| **名称** | **类型** | **必填** | **描述** | **示例值** |
| --- | --- | --- | --- | --- |
| datasetName | string | 否   | 数据集名称 | product\\_faq\\_dataset |
| maxResults | integer | 否   | 最大结果数 | 100 |
| nextToken | string | 否   | nextToken，首次请求时无需设置；后续请求传入上一次响应返回的 nextToken | RsfoUqpOJd5nd0F1e4OquY/7dKNGp1JMgsKtvCagmtY= |

## **返回参数**

| **名称** | **类型** | **描述** | **示例值** |
| --- | --- | --- | --- |
|     | object | Schema of Response |     |
| nextToken | string | 查询返回结果下一页的令牌。 当返回结果数据总条数超过 maxResults 限制，则数据会被截断，您可以使用 nextToken 查询下一页数据。 | umaQfI7x758Ns4TgWrj8yA3fYlnk7dJgsfhMrSViRY8= |
| maxResults | integer | 本次请求设置的最大返回条数。 | 100 |
| requestId | string | 请求 ID | 90F52F93-8800-5A71-8737-18F34BA90166 |
| total | integer | 总记录数 | 33  |
| datasets | array<object> | 结果集 |     |
|     | object | 结果集 |     |
| description | string | 数据集描述 | Product FAQ dataset for semantic search |
| createTime | string | 创建时间 | 2026-01-19T02:11:02Z |
| updateTime | string | 更新时间 | 2026-05-18T02:21:32Z |
| datasetName | string | 数据集名称 | product\\_faq\\_dataset |
| agentSpace | string | 智能体空间名称 | sop-agent |
| regionId | string | 地域 ID | cn-shanghai |
| isFavorite | boolean |     |     |

## 示例

正常返回示例

`JSON`格式

```
{
  "nextToken": "umaQfI7x758Ns4TgWrj8yA3fYlnk7dJgsfhMrSViRY8=",
  "maxResults": 100,
  "requestId": "90F52F93-8800-5A71-8737-18F34BA90166",
  "total": 33,
  "datasets": [
    {
      "description": "Product FAQ dataset for semantic search",
      "createTime": "2026-01-19T02:11:02Z",
      "updateTime": "2026-05-18T02:21:32Z",
      "datasetName": "product_faq_dataset",
      "agentSpace": "sop-agent",
      "regionId": "cn-shanghai",
      "isFavorite": true
    }
  ]
}
```

## 错误码

访问[错误中心](https://api.aliyun.com/document/AgentLoop/2026-05-20/errorCode)查看更多错误码。

## **变更历史**

更多信息，参考[变更详情](https://api.aliyun.com/document/AgentLoop/2026-05-20/ListDatasets#workbench-doc-change-demo)。