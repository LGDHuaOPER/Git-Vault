---
title: "AddDatasetData - 添加数据集数据"
source: "https://help.aliyun.com/zh/document_detail/3045451.html?spm=a2c4g.11186623.help-menu-3033820.d_6_1_3_3_0.27be54c3x8W6Iu"
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
"word-count": "639"
更新时间: "2026-07-07 13:42:55"
---
向指定 Dataset 追加结构化数据行，避免客户端拼接 SQL。

## 调试

[您可以在OpenAPI Explorer中直接运行该接口，免去您计算签名的困扰。运行成功后，OpenAPI Explorer可以自动生成SDK代码示例。](https://api.aliyun.com/api/AgentLoop/2026-05-20/AddDatasetData)[您可以在OpenAPI Explorer中直接运行该接口，免去您计算签名的困扰。运行成功后，OpenAPI Explorer可以自动生成SDK代码示例。](https://api.alibabacloud.com/api/AgentLoop/2026-05-20/AddDatasetData)

 [![](https://img.alicdn.com/tfs/TB16JcyXHr1gK0jSZR0XXbP8XXa-24-26.png) 调试](https://api.aliyun.com/api/AgentLoop/2026-05-20/AddDatasetData)

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
| agentloop:AddDatasetData | none | \\*Dataset `acs:agentloop:{#regionId}:{#accountId}:agentspace/{#AgentSpace}/dataset/{#DatasetName}` | 无   | 无   |

## 请求语法

```
POST /agentspace/{agentSpace}/dataset/{datasetName}/rows HTTP/1.1
```

## 路径参数

| **名称** | **类型** | **必填** | **描述** | **示例值** |
| --- | --- | --- | --- | --- |
| agentSpace | string | 否   | 智能体空间名称 | sop-agent |
| datasetName | string | 否   | 数据集名称 | product\\_faq\\_dataset |

## 请求参数

| **名称** | **类型** | **必填** | **描述** | **示例值** |
| --- | --- | --- | --- | --- |
| body | object | 否   | 请求体，必须包含 dataArray。 | {"dataArray":\\[{"content":"hello"}\\]} |
| dataArray | array<object> | 否   | 待追加写入的数据行数组。数组不能为空；服务端流式读取；请求体默认最大 100MB；单请求事务内 all-or-nothing。 |     |
|     | object | 否   | 单行数据对象。key 为 id 或 Dataset schema 中定义的字段名；字段名大小写不敏感；未知字段会报错。 |     |
|     | any | 否   | schema 字段值。未传或传 null 写入空值；text 传 string，long 传整数或整数字符串，double 传有限数字或数字字符串，json 传任意合法 JSON 值。 | "hello" / 123 / 0.98 / {"a":1} |
| clientToken | string | 否   | 幂等 Token，客户端生成的唯一字符串，保证创建操作幂等 | a1b2c3d4-1234-5678-90ab-cdef12345678 |

## **返回参数**

| **名称** | **类型** | **描述** | **示例值** |
| --- | --- | --- | --- |
|     | object | Schema of Response |     |
| requestId | string | Id of the request | D0173835-9E0F-508F-8BFA-9F556E59C302 |
| affectedRows | integer | 扫描/处理的日志行数 | 100 |

## 示例

正常返回示例

`JSON`格式

```
{
  "requestId": "D0173835-9E0F-508F-8BFA-9F556E59C302",
  "affectedRows": 100
}
```

## 错误码

访问[错误中心](https://api.aliyun.com/document/AgentLoop/2026-05-20/errorCode)[错误中心](https://api.alibabacloud.com/document/AgentLoop/2026-05-20/errorCode)查看更多错误码。

## **变更历史**

更多信息，参考[变更详情](https://api.aliyun.com/document/AgentLoop/2026-05-20/AddDatasetData#workbench-doc-change-demo)[变更详情](https://api.alibabacloud.com/document/AgentLoop/2026-05-20/AddDatasetData#workbench-doc-change-demo)。