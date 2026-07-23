---
title: "CreateEvaluator - 创建评估器"
source: "https://help.aliyun.com/zh/document_detail/3045655.html?spm=a2c4g.11186623.help-menu-3033820.d_6_1_3_5_1_2.110e3a5dpQ4cjw"
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
"word-count": "428"
更新时间: "2026-07-08 11:15:00"
---
创建评估器。

## 调试

[您可以在OpenAPI Explorer中直接运行该接口，免去您计算签名的困扰。运行成功后，OpenAPI Explorer可以自动生成SDK代码示例。](https://api.aliyun.com/api/AgentLoop/2026-05-20/CreateEvaluator)[您可以在OpenAPI Explorer中直接运行该接口，免去您计算签名的困扰。运行成功后，OpenAPI Explorer可以自动生成SDK代码示例。](https://api.alibabacloud.com/api/AgentLoop/2026-05-20/CreateEvaluator)

 [![](https://img.alicdn.com/tfs/TB16JcyXHr1gK0jSZR0XXbP8XXa-24-26.png) 调试](https://api.aliyun.com/api/AgentLoop/2026-05-20/CreateEvaluator)

## **授权信息**

当前API暂无授权信息透出。

## 请求语法

```
POST /api/v1/evaluators/{agentSpace} HTTP/1.1
```

## 路径参数

| **名称** | **类型** | **必填** | **描述** | **示例值** |
| --- | --- | --- | --- | --- |
| agentSpace | string | 是   | AgentSpace 名称。 | prod-agentspace |

## 请求参数

| **名称** | **类型** | **必填** | **描述** | **示例值** |
| --- | --- | --- | --- | --- |
| body | object | 否   | 请求体。 | {"name":"trace\\_task\\_completion","displayName":"链路任务完成度","type":"AGENT","metricName":"agent\\_task\\_completion","version":"1.0.0"} |
| name | string | 是   | 评估器名称，不能以系统保留前缀开头，最长 128 字符。 | trace\\_task\\_completion |
| displayName | string | 否   | 显示名称，最长 128 字符。 | 链路任务完成度 |
| type | string | 是   | 评估器类型。`LLM` 表示内联大模型评估器，`AGENT` 表示 StarOps 数字员工评估器，`CODE` 表示代码评估器。 **枚举值：** - AGENT : AGENT - CODE : CODE - LLM : LLM | AGENT |
| description | string | 否   | 评估器描述，最长 256 字符。 | 判断 Agent 是否完成用户任务 |
| metricName | string | 是   | 评估指标名称。 | agent\\_task\\_completion |
| version | string | 是   | 初始版本号。 | 1.0.0 |
| versionDescription | string | 否   | 版本描述。 | 初始版本 |
| config | object | 否   | 评估器配置。LLM/AGENT 常包含 prompt、variables、outputSchema；CODE 常包含 codeType、faasConfig、variables、parameters。 | {"prompt":"请评估任务完成度","variables":\\[{"name":"input"}\\]} |
| annotations | array | 否   | 注解标记列表。 | \\["\\_\\_en"\\] |
|     | string | 否   | 单个注解标记。 | \\_\\_en |
| properties | object | 否   | 评估器属性。 | {"agentEvaluatorMode":"raw\\_prompt"} |
| clientToken | string | 否   | 幂等 Token。CloudSpec 声明了该查询参数，当前后端未做幂等比对。 | a1b2c3d4-1234-5678-90ab-cdef12345678 |

## **返回参数**

| **名称** | **类型** | **描述** | **示例值** |
| --- | --- | --- | --- |
|     | object | Schema of Response |     |
| requestId | string | 请求 ID。 | 3FE4CD1E-FF41-56BE-B590-7A021D9C1524 |
| name | string | 评估器名称。 | trace\\_task\\_completion |
| version | string | 创建的版本号。 | 1.0.0 |

## 示例

正常返回示例

`JSON`格式

```
{
  "requestId": "3FE4CD1E-FF41-56BE-B590-7A021D9C1524",
  "name": "trace_task_completion",
  "version": "1.0.0"
}
```

## 错误码

访问[错误中心](https://api.aliyun.com/document/AgentLoop/2026-05-20/errorCode)[错误中心](https://api.alibabacloud.com/document/AgentLoop/2026-05-20/errorCode)查看更多错误码。

## **变更历史**

更多信息，参考[变更详情](https://api.aliyun.com/document/AgentLoop/2026-05-20/CreateEvaluator#workbench-doc-change-demo)[变更详情](https://api.alibabacloud.com/document/AgentLoop/2026-05-20/CreateEvaluator#workbench-doc-change-demo)。