---
title: "GetDataset - 获取数据集"
source: "https://help.aliyun.com/zh/document_detail/3045459.html?spm=a2c4g.11186623.help-menu-3033820.d_6_1_3_3_6.fe6b2c91zmgf9F"
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
"word-count": "537"
更新时间: "2026-07-16 19:04:17"
---
查询数据集

## 调试

[您可以在OpenAPI Explorer中直接运行该接口，免去您计算签名的困扰。运行成功后，OpenAPI Explorer可以自动生成SDK代码示例。](https://api.aliyun.com/api/AgentLoop/2026-05-20/GetDataset)

 [![](https://img.alicdn.com/tfs/TB16JcyXHr1gK0jSZR0XXbP8XXa-24-26.png) 调试](https://api.aliyun.com/api/AgentLoop/2026-05-20/GetDataset)

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
| agentloop:GetDataset | get | \\*Dataset `acs:agentloop:{#regionId}:{#accountId}:agentspace/{#AgentSpaceName}/dataset/{#DatasetName}` | 无   | 无   |

## 请求语法

```
GET /agentspace/{agentSpace}/dataset/{datasetName} HTTP/1.1
```

## 路径参数

| **名称** | **类型** | **必填** | **描述** | **示例值** |
| --- | --- | --- | --- | --- |
| agentSpace | string | 是   | 智能体空间名称 | sop-agent |
| datasetName | string | 是   | 数据集名称 | product\\_faq\\_dataset |

## 请求参数

| **名称** | **类型** | **必填** | **描述** | **示例值** |
| --- | --- | --- | --- | --- |

当前API无需请求参数

## **返回参数**

| **名称** | **类型** | **描述** | **示例值** |
| --- | --- | --- | --- |
|     | object | Schema of Response |     |
| description | string | 数据集描述 | Product FAQ dataset for semantic search |
| createTime | string | 创建时间 | 2026-06-15T10:30:00Z |
| requestId | string | 请求 ID | D17DE39E-6C62-50E3-9EB7-FDE41BB0D43D |
| updateTime | string | 更新时间 | 2026-06-15T11:20:00Z |
| agentSpace | string | 智能体空间名称 | sop-agent |
| datasetName | string | 数据集名称 | product\\_faq\\_dataset |
| regionId | string | 地域 ID | cn-beijing |
| schema | object | 数据集表结构 |     |
|     | IndexKey | 数据集表结构 |     |
| isFavorite | boolean |     |     |

## 示例

正常返回示例

`JSON`格式

```
{
  "description": "Product FAQ dataset for semantic search",
  "createTime": "2026-06-15T10:30:00Z",
  "requestId": "D17DE39E-6C62-50E3-9EB7-FDE41BB0D43D",
  "updateTime": "2026-06-15T11:20:00Z",
  "agentSpace": "sop-agent",
  "datasetName": "product_faq_dataset",
  "regionId": "cn-beijing",
  "schema": {
    "key": {
      "chn": true,
      "type": "",
      "embedding": "",
      "jsonKeys": {
        "key": {
          "type": "",
          "chn": true
        }
      }
    }
  },
  "isFavorite": true
}
```

## 错误码

访问[错误中心](https://api.aliyun.com/document/AgentLoop/2026-05-20/errorCode)查看更多错误码。

## **变更历史**

更多信息，参考[变更详情](https://api.aliyun.com/document/AgentLoop/2026-05-20/GetDataset#workbench-doc-change-demo)。