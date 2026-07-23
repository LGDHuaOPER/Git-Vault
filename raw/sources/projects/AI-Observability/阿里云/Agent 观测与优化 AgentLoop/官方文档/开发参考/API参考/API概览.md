---
title: "API概览"
source: "https://help.aliyun.com/zh/document_detail/3041792.html?spm=a2c4g.11186623.help-menu-3033820.d_6_1_0.3bf326576xH7zz"
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
"word-count": "1216"
更新时间: "2026-07-23 17:39:37"
---
## **API标准及多语言预置SDK**

本产品（`AgentLoop/2026-05-20`）的OpenAPI采用[ROA](https://help.aliyun.com/zh/sdk/product-overview/roa-mechanism)签名风格。我们已经为开发者封装了常见编程语言的SDK，开发者可通过[下载SDK](https://api.aliyun.com/api-tools/sdk/AgentLoop?version=2026-05-20)直接调用本产品OpenAPI而无需关心技术细节。如果现有SDK不能满足使用需求，可通过签名机制进行自签名对接。由于自签名细节非常复杂，需花费 5个工作日左右。因此建议加入我们的服务钉钉群（147535001692），在专家指导下进行签名对接。

在使用API前，您需要准备好身份账号及访问密钥（AccessKey），才能有效通过客户端工具（SDK、CLI等）访问API。细节请参见[获取AccessKey](https://help.aliyun.com/zh/ram/user-guide/create-an-accesskey-pair)。

## **自定义签名场景**

若您的业务场景有特殊需求，需通过自签名方式对接 API，建议优先咨询我们的技术支持团队（服务钉钉群：147535001692），获取专业指导以确保高效接入。

## **账号与安全准备**

阿里云账号具备对所有资源的完全管理权限。一旦 AccessKey 泄露，所有相关资源都将面临未经授权访问的风险。为确保安全，建议创建一个仅具备 API 访问权限的[RAM用户](https://help.aliyun.com/zh/ram/user-guide/create-a-ram-user)并配置其 AccessKey，同时基于最小权限原则 (PoLP) 配置 RAM 策略。仅在明确需要阿里云账号权限的特定场景下，才使用阿里云账号。

## 数据处理

| API | 标题  | API概述 |
| --- | --- | --- |
| [PreviewPipeline](https://help.aliyun.com/zh/document_detail/3046329.html) | 流水线预览 | 预览流水线。在不创建流水线资源的前提下，基于给定的数据源、节点编排和时间范围试运行查询，返回少量样本数据，用于验证参数配置和预览处理效果。 |
| [CreatePipeline](https://help.aliyun.com/zh/document_detail/3046328.html) | 创建流水线 | 创建流水线 |
| [DeletePipeline](https://help.aliyun.com/zh/document_detail/3045455.html) | 删除Pipeline | 删除流水线 |
| [UpdatePipeline](https://help.aliyun.com/zh/document_detail/3045468.html) | 更新Pipeline | 更新流水线 |
| [GetPipeline](https://help.aliyun.com/zh/document_detail/3045462.html) | 查询Pipeline | 查询流水线 |
| [ListPipelines](https://help.aliyun.com/zh/document_detail/3045460.html) | 查询Pipeline 列表 | 查询流水线列表 |

## 地域

| API | 标题  | API概述 |
| --- | --- | --- |
| [DescribeRegions](https://help.aliyun.com/zh/document_detail/3045449.html) | 查询地域信息 | 查询Regions |

## 数据集

| API | 标题  | API概述 |
| --- | --- | --- |
| [AddDatasetData](https://help.aliyun.com/zh/document_detail/3045451.html) | 添加数据集数据 | 向指定 Dataset 追加结构化数据行，避免客户端拼接 SQL。 |
| [ExecuteQuery](https://help.aliyun.com/zh/document_detail/3045448.html) | 执行语句 | 执行查询语句。 |
| [UpdateDataset](https://help.aliyun.com/zh/document_detail/3045484.html) | 更新数据集 | 更新数据集 |
| [CreateDataset](https://help.aliyun.com/zh/document_detail/3045476.html) | 创建数据集 | 创建数据集 |
| [DeleteDataset](https://help.aliyun.com/zh/document_detail/3045454.html) | 删除数据集 | 删除数据集 |
| [ListDatasets](https://help.aliyun.com/zh/document_detail/3045464.html) | 列出数据集 | 查询数据集列表 |
| [GetDataset](https://help.aliyun.com/zh/document_detail/3045459.html) | 获取数据集 | 查询数据集 |

## 智能体空间

| API | 标题  | API概述 |
| --- | --- | --- |
| [CreateAgentSpace](https://help.aliyun.com/zh/document_detail/3045475.html) | 创建AgentSpace | 创建AgentSpace |
| [UpdateAgentSpace](https://help.aliyun.com/zh/document_detail/3045481.html) | 更新AgentSpace | 更新AgentSpace |
| [ListAgentSpaces](https://help.aliyun.com/zh/document_detail/3045463.html) | 查询AgentSpaces列表 | 查询AgentSpace列表 |
| [GetAgentSpace](https://help.aliyun.com/zh/document_detail/3045456.html) | 查询AgentSpace信息 | 查询AgentSpace |
| [DeleteAgentSpace](https://help.aliyun.com/zh/document_detail/3045453.html) | 删除AgentSpace | 删除AgentSpace |

## 评估

| API | 标题  | API概述 |
| --- | --- | --- |
| 评估任务 | 评估任务 |     |
| [ListEvaluationTasks](https://help.aliyun.com/zh/document_detail/3045683.html) | 查询评估任务列表 | 查询评估任务列表 |
| [GetEvaluationTask](https://help.aliyun.com/zh/document_detail/3045680.html) | 查询评估任务详情 | 获取评估任务详情 |
| [CreateEvaluationTask](https://help.aliyun.com/zh/document_detail/3045654.html) | 创建评估任务 | 创建评估任务。 |
| [UpdateEvaluationTask](https://help.aliyun.com/zh/document_detail/3045662.html) | 更新评估任务 | 更新评估任务。 |
| [DeleteEvaluationTask](https://help.aliyun.com/zh/document_detail/3045658.html) | 删除评估任务 | 删除评估任务。 |
| [ListEvaluationRuns](https://help.aliyun.com/zh/document_detail/3045679.html) | 查询评估运行列表 | 查询评估运行列表。 |
| [GetEvaluationRun](https://help.aliyun.com/zh/document_detail/3045677.html) | 获取评估运行详情 | 获取评估运行详情 |
| [UpdateEvaluationRun](https://help.aliyun.com/zh/document_detail/3045657.html) | 更新评估运行 | 更新评估运行。 |
| [DeleteEvaluationRun](https://help.aliyun.com/zh/document_detail/3045663.html) | 删除评估运行 | 删除评估运行。 |
| 评估器 | 评估器 |     |
| [ListEvaluators](https://help.aliyun.com/zh/document_detail/3045659.html) | 查询评估器列表 | 查询评估器列表。 |
| [GetEvaluator](https://help.aliyun.com/zh/document_detail/3045681.html) | 获取评估器详情 | 获取评估器详情。 |
| [CreateEvaluator](https://help.aliyun.com/zh/document_detail/3045655.html) | 创建评估器 | 创建评估器。 |
| [UpdateEvaluator](https://help.aliyun.com/zh/document_detail/3045664.html) | 更新评估器 | 更新评估器。 |
| [DeleteEvaluator](https://help.aliyun.com/zh/document_detail/3045671.html) | 删除评估器 | 删除评估器。 |
| [ListEvaluatorSkills](https://help.aliyun.com/zh/document_detail/3045656.html) | 查询评估器技能列表 | 查询评估器技能列表。 |
| [GetEvaluatorSkill](https://help.aliyun.com/zh/document_detail/3045678.html) | 获取评估器技能详情 | 获取评估器技能详情。 |
| [CreateEvaluatorSkill](https://help.aliyun.com/zh/document_detail/3045661.html) | 创建评估器技能 | 创建评估器技能。 |
| [UpdateEvaluatorSkill](https://help.aliyun.com/zh/document_detail/3045676.html) | 更新评估器技能 | 更新评估器技能。 |
| [DeleteEvaluatorSkill](https://help.aliyun.com/zh/document_detail/3045675.html) | 删除评估器技能 | 删除评估器技能。 |

## 其他

| API                                                                             | 标题       | API概述     |
| ------------------------------------------------------------------------------- | -------- | --------- |
| [CreateExperimentPlan](https://help.aliyun.com/zh/document_detail/3047496.html) | 创建实验计划   | 创建实验计划。   |
| [CreateExperimentRun](https://help.aliyun.com/zh/document_detail/3047500.html)  | 执行实验     | 执行实验。     |
| [DeleteExperimentPlan](https://help.aliyun.com/zh/document_detail/3047501.html) | 删除实验计划   | 删除实验计划。   |
| [DeleteExperimentRun](https://help.aliyun.com/zh/document_detail/3047502.html)  | 删除实验记录   | 删除实验记录。   |
| [GetExperimentPlan](https://help.aliyun.com/zh/document_detail/3047503.html)    | 查询实验计划   | 查询实验计划    |
| [GetExperimentRun](https://help.aliyun.com/zh/document_detail/3047505.html)     | 查询实验记录详情 | 查询实验记录详情。 |
| [ListExperimentPlans](https://help.aliyun.com/zh/document_detail/3047506.html)  | 查询实验计划列表 | 查询实验计划列表。 |
| [ListExperimentRuns](https://help.aliyun.com/zh/document_detail/3047507.html)   | 查询实验记录列表 | 查询实验记录列表。 |
| [UpdateExperimentPlan](https://help.aliyun.com/zh/document_detail/3047509.html) | 更新实验计划   | 更新实验计划。   |
| [UpdateExperimentRun](https://help.aliyun.com/zh/document_detail/3047511.html)  | 更新实验运行   | 更新实验运行。   |