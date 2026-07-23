---
title: "UpdateContextStore - 修改上下文库配置"
source: "https://help.aliyun.com/zh/document_detail/3045483.html?spm=a2c4g.11186623.help-menu-3033820.d_6_1_3_0_9.7dce7d15cIZLy9"
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
"word-count": "657"
更新时间: "2026-07-15 15:17:19"
---
修改上下文库配置

## 调试

[您可以在OpenAPI Explorer中直接运行该接口，免去您计算签名的困扰。运行成功后，OpenAPI Explorer可以自动生成SDK代码示例。](https://api.aliyun.com/api/AgentLoop/2026-05-20/UpdateContextStore)

 [![](https://img.alicdn.com/tfs/TB16JcyXHr1gK0jSZR0XXbP8XXa-24-26.png) 调试](https://api.aliyun.com/api/AgentLoop/2026-05-20/UpdateContextStore)

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
| agentloop:UpdateContextStore | update | \\*ContextStore `acs:agentloop:{#regionId}:{#accountId}:agentspace/{#AgentSpaceName}/contextstore/{#ContextStoreName}` | 无   | 无   |

## 请求语法

```
PUT /agentspace/{agentSpace}/contextstore/{contextStoreName} HTTP/1.1
```

## 路径参数

| **名称** | **类型** | **必填** | **描述** | **示例值** |
| --- | --- | --- | --- | --- |
| agentSpace | string | 是   | AgentSpace 名称，长度 2-64 字符 | my-agent-space |
| contextStoreName | string | 是   | 待更新的上下文库名称，长度 2-64 字符 | my-context-store |

## 请求参数

| **名称** | **类型** | **必填** | **描述** | **示例值** |
| --- | --- | --- | --- | --- |
| body | object | 否   | 请求体 |     |
| description | string | 否   | 上下文库描述，便于业务方理解用途 | 我的上下文库 |
| config | object | 否   | 上下文库配置，传入即整体覆盖；不传则保持原配置 |     |
| metadataField | object | 否   | 元数据字段映射，key 为业务字段，value 为存储字段 | {"userId":"user\\_id","sessionId":"session\\_id"} |
|     | string | 否   |     |     |
| source | object | 否   | 数据源配置，仅作为数据源根标识 |     |
| startTime | string | 否   | 数据回灌起始时间，ISO 8601 UTC 格式 | 2026-01-01T00:00:00Z |
| agentSpace | string | 否   | trace 数据源所在的 AgentSpace；本期不支持跨 AgentSpace，若传入必须等于 path AgentSpace，否则返回 400 参数错误。AgentSpace 创建后不可变更 | my-agent-space |
| contextType | string | 否   | 上下文库类型；创建后通常不可变更，提供该字段仅用于异常修正 | experience |
| status | string | 否   |     | Paused |
| clientToken | string | 否   | 幂等 Token，客户端生成的唯一字符串，保证更新操作幂等 | a1b2c3d4-1234-5678-90ab-cdef12345678 |

## **返回参数**

| **名称** | **类型** | **描述** | **示例值** |
| --- | --- | --- | --- |
|     | object | 响应数据 |     |
| requestId | string | 请求 Id，用于排查问题时定位本次请求 | 9ACFB10A-1B2C-3D4E-5F6G-7H8I9J0K1L2M |

## 示例

正常返回示例

`JSON`格式

```
{
  "requestId": "9ACFB10A-1B2C-3D4E-5F6G-7H8I9J0K1L2M"
}
```

## 错误码

访问[错误中心](https://api.aliyun.com/document/AgentLoop/2026-05-20/errorCode)查看更多错误码。

## **变更历史**

更多信息，参考[变更详情](https://api.aliyun.com/document/AgentLoop/2026-05-20/UpdateContextStore#workbench-doc-change-demo)。