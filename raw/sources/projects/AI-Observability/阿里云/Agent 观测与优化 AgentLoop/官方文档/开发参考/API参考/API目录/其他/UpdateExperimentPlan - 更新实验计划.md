---
title: "UpdateExperimentPlan - 更新实验计划"
source: "https://help.aliyun.com/zh/document_detail/3047509.html?spm=a2c4g.11186623.help-menu-3033820.d_6_1_3_6_8.6b342671ratkuO"
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
"word-count": "691"
更新时间: "2026-07-23 11:20:43"
---
更新实验计划。

## 接口说明

调用 UpdateExperimentPlan 更新指定实验计划。未传字段保持不变。仅可更新当前账号创建的计划。

## 调试

[您可以在OpenAPI Explorer中直接运行该接口，免去您计算签名的困扰。运行成功后，OpenAPI Explorer可以自动生成SDK代码示例。](https://api.aliyun.com/api/AgentLoop/2026-05-20/UpdateExperimentPlan)

 [![](https://img.alicdn.com/tfs/TB16JcyXHr1gK0jSZR0XXbP8XXa-24-26.png) 调试](https://api.aliyun.com/api/AgentLoop/2026-05-20/UpdateExperimentPlan)

## **授权信息**

当前API暂无授权信息透出。

## 请求语法

```
PUT /api/v1/experiments/{agentSpace}/plans/{planId} HTTP/1.1
```

## 路径参数

| **名称** | **类型** | **必填** | **描述** | **示例值** |
| --- | --- | --- | --- | --- |
| agentSpace | string | 否   | AgentSpace 名称。 | al-playground-cn-hongkong |
| planId | string | 否   | 实验计划 ID。 | exp-plan-e95bff54685a4ae29ff3a834c1008a71 |

## 请求参数

| **名称** | **类型** | **必填** | **描述** | **示例值** |
| --- | --- | --- | --- | --- |
| body | object | 否   | 请求体。未传字段保持不变。 | {"planName": "rca\\_benchmark\\_eval\\_experiment", "description": "", "datasetId": "rca\\_benckmark\\_eval", "selectedItemIds": \\[\\], "querySql": "", "evaluators": \\[{"variableMapping": {"output": "experiment\\_output", "input": "experiment\\_input", "expected\\_output": "dataset.ground\\_truth\\_json"}, "evaluatorRef": "Builtin.agent\\_correctness", "name": "Builtin.agent\\_correctness", "filters": {"query": "", "sample": "100"}, "type": "AGENT", "config": {"variables": \\[\\], "prompt": ""}, "resultType": "score", "resultName": "Builtin.agent\\_correctness"}, {"variableMapping": {"output": "experiment\\_output", "input": "experiment\\_input", "question": "dataset.question", "expected\\_output": "dataset.ground\\_truth\\_json", "payload\\_json": "dataset.payload\\_json"}, "evaluatorRef": "rca-toxicity-safety-accuracy", "name": "rca-toxicity-safety-accuracy", "filters": {"query": "", "sample": "100"}, "type": "AGENT", "config": {"variables": \\[\\], "prompt": ""}, "resultType": "score", "resultName": "rca-toxicity-safety-accuracy"}\\]} |
| planName | string | 否   | 实验计划名称。 | rca\\_benchmark\\_eval\\_experiment |
| experimentType | string | 否   | 实验类型。 **枚举值：** - OFFLINE : OFFLINE - ONLINE : ONLINE | OFFLINE |
| description | string | 否   | 描述信息。 | rca\\_benchmark\\_eval\\_experiment 离线实验 |
| datasetId | string | 否   | 关联的数据集 ID。 | rca\\_benckmark\\_eval |
| datasetProject | string | 否   | 可选。 | agentspace-project |
| experiments | array | 否   | 实验配置列表。传入时整体替换，数量须为 1-5。 | \\[{"label": "A", "name": "baseline", "modelName": "qwen-max"}\\] |
|     | ExperimentConfig | 否   | 单个实验分组配置。 |     |
| evaluators | array | 否   | 评估器列表。省略表示不修改；传空数组表示清空。 | \\[{"evaluatorRef": "Builtin.agent\\_task\\_completion"}\\] |
|     | [Evaluator](https://help.aliyun.com/zh/document_detail/3045378.html) | 否   | 单个评估器配置对象。 |     |
| selectedItemIds | array | 否   | 部分数据集模式下选定的数据项 ID 列表。传空数组表示清空。 | \\[\\] |
|     | string | 否   | 数据集中的单条数据项 ID。 | a1b2c3d4-e5f6-7890-abcd-ef1234567890 |
| querySql | string | 否   | 部分数据集模式下的自定义查询 SQL 子句。 | level > 2 |
| input | object | 否   | 可选。 | {"question": "如何退款？"} |

### 请求示例（更新离线计划的数据集与评估器）\\n\\n\`\`\`json\\n{

"planName": "rca\_benchmark\_eval\_experiment", "description": "", "datasetId": "rca\_benckmark\_eval", "selectedItemIds": \[\], "querySql": "", "evaluators": \[ { "variableMapping": { "output": "experiment\_output", "input": "experiment\_input", "expected\_output": "dataset.ground\_truth\_json" }, "evaluatorRef": "Builtin.agent\_correctness", "name": "Builtin.agent\_correctness", "filters": { "query": "", "sample": "100" }, "type": "AGENT", "config": { "variables": \[\], "prompt": "" }, "resultType": "score", "resultName": "Builtin.agent\_correctness" }, { "variableMapping": { "output": "experiment\_output", "input": "experiment\_input", "question": "dataset.question", "expected\_output": "dataset.ground\_truth\_json", "payload\_json": "dataset.payload\_json" }, "evaluatorRef": "rca-toxicity-safety-accuracy", "name": "rca-toxicity-safety-accuracy", "filters": { "query": "", "sample": "100" }, "type": "AGENT", "config": { "variables": \[\], "prompt": "" }, "resultType": "score", "resultName": "rca-toxicity-safety-accuracy" } \] }\\n\`\`\`

## **返回参数**

| **名称** | **类型** | **描述** | **示例值** |
| --- | --- | --- | --- |
|     | object | 更新实验计划响应。 |     |
| requestId | string | 请求 ID。 | 3FE4CD1E-FF41-56BE-B590-7A021D9C1524 |
| planId | string | 实验计划 ID。 | exp-plan-e95bff54685a4ae29ff3a834c1008a71 |
| status | string | 更新结果。成功为 updated。 | updated |
| message | string | 提示信息。 | 实验计划更新成功 |

如需查看更新后的完整配置，请调用 GetExperimentPlan。\\n\\n`json\n{ "planId": "exp-plan-e95bff54685a4ae29ff3a834c1008a71", "status": "updated" }\n`

## 示例

正常返回示例

`JSON`格式

```
{
  "requestId": "3FE4CD1E-FF41-56BE-B590-7A021D9C1524",
  "planId": "exp-plan-e95bff54685a4ae29ff3a834c1008a71",
  "status": "updated",
  "message": "实验计划更新成功"
}
```

## 错误码

访问[错误中心](https://api.aliyun.com/document/AgentLoop/2026-05-20/errorCode)查看更多错误码。

## **变更历史**

更多信息，参考[变更详情](https://api.aliyun.com/document/AgentLoop/2026-05-20/UpdateExperimentPlan#workbench-doc-change-demo)。