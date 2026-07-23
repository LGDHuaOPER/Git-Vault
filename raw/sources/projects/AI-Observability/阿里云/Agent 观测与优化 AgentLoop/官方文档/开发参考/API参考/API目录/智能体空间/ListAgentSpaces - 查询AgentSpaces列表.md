---
title: "ListAgentSpaces - 查询AgentSpaces列表"
source: "https://help.aliyun.com/zh/document_detail/3045463.html?spm=a2c4g.11186623.help-menu-3033820.d_6_1_3_4_2.716bba25qBJRze"
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
"word-count": "547"
更新时间: "2026-07-07 13:46:13"
---
查询AgentSpace列表

## 调试

[您可以在OpenAPI Explorer中直接运行该接口，免去您计算签名的困扰。运行成功后，OpenAPI Explorer可以自动生成SDK代码示例。](https://api.aliyun.com/api/AgentLoop/2026-05-20/ListAgentSpaces)[您可以在OpenAPI Explorer中直接运行该接口，免去您计算签名的困扰。运行成功后，OpenAPI Explorer可以自动生成SDK代码示例。](https://api.alibabacloud.com/api/AgentLoop/2026-05-20/ListAgentSpaces)

 [![](https://img.alicdn.com/tfs/TB16JcyXHr1gK0jSZR0XXbP8XXa-24-26.png) 调试](https://api.aliyun.com/api/AgentLoop/2026-05-20/ListAgentSpaces)

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
| agentloop:ListAgentSpaces | list | \\*AgentSpace `acs:agentloop:{#regionId}:{#accountId}:agentspace/*` | 无   | 无   |

## 请求语法

```
GET /agentspace HTTP/1.1
```

## 请求参数

| **名称** | **类型** | **必填** | **描述** | **示例值** |
| --- | --- | --- | --- | --- |
| agentSpace | string | 否   | AgentSpace 名称 | test-agent-space |
| regionId | string | 否   |     |     |
| maxResults | integer | 否   | 最大结果数 | 50  |
| nextToken | string | 否   | 翻页 token。 | pEL20OGYeZQez8NdW7ve |

## **返回参数**

| **名称** | **类型** | **描述** | **示例值** |
| --- | --- | --- | --- |
|     | object | 响应数据 |     |
| nextToken | string | 分页 Token，没有下一页则为空 | b5754ef15c784abc8696d82790d2985c |
| maxResults | integer | 最大返回数量 | 100 |
| requestId | string | 请求 Id | 4E4AC775-2358-5B52-B6FB-171459D7B14B |
| total | integer | 总数  | 13  |
| agentSpaces | array<object> | agentSpaces 信息 |     |
|     | array<object> | agentSpaces 信息 |     |
| agentSpace | string | AgentSpace 名称 | test-agent-space |
| description | string | 描述  | test |
| cmsWorkspace | string | CMS 工作空间 | test-cms-workspace |
| mseNamespace | object | MSE 命名空间 |     |
| namespaceName | string | MSE 命名空间名称 | terraform-alicloud-modules |
| namespaceId | string | MSE 命名空间 ID | phoenixcloud-raw-logs |
| slsProject | string | 日志服务项目名称 | default-cms-1152309027070167-cn-beijing |
| regionId | string | 地域 ID | cn-hangzhou |
| createTime | string | 创建时间 | 2023-08-23T04:06:06Z |
| updateTime | string | 更新时间 | 2026-02-11T08:40:23Z |

## 示例

正常返回示例

`JSON`格式

```
{
  "nextToken": "b5754ef15c784abc8696d82790d2985c",
  "maxResults": 100,
  "requestId": "4E4AC775-2358-5B52-B6FB-171459D7B14B",
  "total": 13,
  "agentSpaces": [
    {
      "agentSpace": "test-agent-space",
      "description": "test",
      "cmsWorkspace": "test-cms-workspace",
      "mseNamespace": {
        "namespaceName": "terraform-alicloud-modules",
        "namespaceId": "phoenixcloud-raw-logs"
      },
      "slsProject": "default-cms-1152309027070167-cn-beijing",
      "regionId": "cn-hangzhou",
      "createTime": "2023-08-23T04:06:06Z",
      "updateTime": "2026-02-11T08:40:23Z"
    }
  ]
}
```

## 错误码

访问[错误中心](https://api.aliyun.com/document/AgentLoop/2026-05-20/errorCode)[错误中心](https://api.alibabacloud.com/document/AgentLoop/2026-05-20/errorCode)查看更多错误码。

## **变更历史**

更多信息，参考[变更详情](https://api.aliyun.com/document/AgentLoop/2026-05-20/ListAgentSpaces#workbench-doc-change-demo)[变更详情](https://api.alibabacloud.com/document/AgentLoop/2026-05-20/ListAgentSpaces#workbench-doc-change-demo)。