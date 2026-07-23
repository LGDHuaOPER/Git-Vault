---
title: "DescribeRegions - 查询地域信息"
source: "https://help.aliyun.com/zh/document_detail/3045449.html?spm=a2c4g.11186623.help-menu-3033820.d_6_1_3_2_0.505d46aaUBq8E1"
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
"word-count": "237"
更新时间: "2026-07-07 13:36:44"
---
查询Regions

## 调试

[您可以在OpenAPI Explorer中直接运行该接口，免去您计算签名的困扰。运行成功后，OpenAPI Explorer可以自动生成SDK代码示例。](https://api.aliyun.com/api/AgentLoop/2026-05-20/DescribeRegions)[您可以在OpenAPI Explorer中直接运行该接口，免去您计算签名的困扰。运行成功后，OpenAPI Explorer可以自动生成SDK代码示例。](https://api.alibabacloud.com/api/AgentLoop/2026-05-20/DescribeRegions)

 [![](https://img.alicdn.com/tfs/TB16JcyXHr1gK0jSZR0XXbP8XXa-24-26.png) 调试](https://api.aliyun.com/api/AgentLoop/2026-05-20/DescribeRegions)

## **授权信息**

当前API暂无授权信息透出。

## 请求语法

```
GET /regions HTTP/1.1
```

## 请求参数

| **名称** | **类型** | **必填** | **描述** | **示例值** |
| --- | --- | --- | --- | --- |
| language | string | 是   | 语言，可传参数 - zh：中文 - en：英语 | zh  |
| maxResults | integer | 否   | 最大请求数量 | 50  |
| nextToken | string | 否   | 分页 Token | dXkC1NeQkVKHWkVfOvIVEp4dD+2BRJj42DLT6GrZysw= |

## **返回参数**

| **名称** | **类型** | **描述** | **示例值** |
| --- | --- | --- | --- |
|     | object | 响应数据 |     |
| requestId | string | 请求 Id | 4FDD8668-516C-5183-9BCF-4CAD8E3CF327 |
| regions | array<object> | 地域信息 |     |
|     | object | 地域信息 |     |
| regionId | string | 地域 ID | cn-hangzhou |
| internetEndpoint | string | 公网地址 | agentloop.cn-hangzhou.aliyuncs.com |
| vpcEndpoint | string | 内网地址 | agentloop.cn-hangzhou.aliyuncs.com |
| localName | string | 地域名称 | 华东1（杭州） |
| nextToken | string | 分页 Token，没有下一页则为空 | ydx438PDAW1lYRJZbBn9 |
| maxResults | integer | 一次获取的最大记录数 | 100 |

## 示例

正常返回示例

`JSON`格式

```
{
  "requestId": "4FDD8668-516C-5183-9BCF-4CAD8E3CF327",
  "regions": [
    {
      "regionId": "cn-hangzhou",
      "internetEndpoint": "agentloop.cn-hangzhou.aliyuncs.com",
      "vpcEndpoint": "agentloop.cn-hangzhou.aliyuncs.com",
      "localName": "华东1（杭州）"
    }
  ],
  "nextToken": "ydx438PDAW1lYRJZbBn9",
  "maxResults": 100
}
```

## 错误码

访问[错误中心](https://api.aliyun.com/document/AgentLoop/2026-05-20/errorCode)[错误中心](https://api.alibabacloud.com/document/AgentLoop/2026-05-20/errorCode)查看更多错误码。

## **变更历史**

更多信息，参考[变更详情](https://api.aliyun.com/document/AgentLoop/2026-05-20/DescribeRegions#workbench-doc-change-demo)[变更详情](https://api.alibabacloud.com/document/AgentLoop/2026-05-20/DescribeRegions#workbench-doc-change-demo)。