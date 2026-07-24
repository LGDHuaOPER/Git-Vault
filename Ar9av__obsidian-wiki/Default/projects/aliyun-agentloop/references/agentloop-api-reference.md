---
title: "AgentLoop API 参考"
category: references
tags:
  - api-reference
  - alicloud
  - agentloop
  - rest-api
  - openapi
relationships:
  - target: "[[projects/aliyun-agentloop/agentloop]]"
    type: related_to
created: 2026-07-24
updated: 2026-07-24
sources:
  - type: "official-docs"
    url: "https://help.aliyun.com/zh/document_detail/3041792.html"
    count: 86
summary: >
  AgentLoop REST API (v2026-05-20) 的完整参考，覆盖 75+ 端点，按 7 大领域组织：上下文库、实验计划、数据处理 Pipeline、数据集、智能体空间、评估任务、评估器。采用 ROA 签名风格，支持多语言 SDK。
provenance: "Consolidated from 86 Alibaba Cloud AgentLoop API reference pages: API overview + 75 endpoint docs across 7 API categories + 4 data structure docs + version history + authorization + service endpoints."
---

# AgentLoop API 参考

[[projects/aliyun-agentloop/agentloop|AgentLoop]] 提供 RESTful OpenAPI（版本 `2026-05-20`），采用 **ROA 签名风格**。阿里云已为常见编程语言封装 SDK，可通过 [SDK 下载](https://api.aliyun.com/api-tools/sdk/AgentLoop?version=2026-05-20) 直接使用。

## 基础信息

| 项目 | 值 |
|------|-----|
| API 版本 | `AgentLoop/2026-05-20` |
| 签名风格 | ROA |
| 可用地域 | cn-hangzhou, cn-shanghai, cn-hongkong |
| 服务接入点 | `agentloop.{region}.aliyuncs.com` |
| RAM 权限 | `AliyunAgentLoopFullAccess` |
| API Explorer | `https://api.aliyun.com/api/AgentLoop/2026-05-20/{Action}` |

## 鉴权

所有 API 请求需使用 AccessKey 鉴权。推荐创建 RAM 用户并授予 `AliyunAgentLoopFullAccess` 策略，遵循最小权限原则。部分 API（如上下文库 API）支持资源级授权，可通过 RAM 策略控制具体资源访问。

## API 总览

### 1. 上下文库 API（Context Store）— 10 个端点

管理 Agent 上下文库，用于存储和检索 Agent 运行时上下文。

| 端点 | 方法 | 说明 | 访问级别 |
|------|------|------|----------|
| `CreateContextStore` | POST | 创建上下文库 | Write |
| `DeleteContextStore` | DELETE | 删除上下文库 | Write |
| `GetContextStore` | GET | 查询上下文库信息 | Read |
| `ListContextStores` | GET | 查询上下文库列表 | List |
| `UpdateContextStore` | PUT | 修改上下文库配置 | Write |
| `SearchContext` | POST | 搜索上下文内容 | Read |
| `CreateContextStoreAPIKey` | POST | 创建 API Key | Write |
| `DeleteContextStoreAPIKey` | DELETE | 删除 API Key | Write |
| `GetContextStoreAPIKey` | GET | 查询 API Key | Read |
| `ListContextStoreAPIKeys` | GET | 查询 API Key 列表 | List |

### 2. 实验计划 API（Experiment）— 10 个端点

管理实验计划与执行记录，支持离线实验和在线 A/B 实验。

| 端点 | 方法 | 说明 | 访问级别 |
|------|------|------|----------|
| `CreateExperimentPlan` | POST `/api/v1/experiments/{agentSpace}/plans` | 创建实验计划 | Write |
| `DeleteExperimentPlan` | DELETE `/api/v1/experiments/{agentSpace}/plans/{planId}` | 删除实验计划 | Write |
| `GetExperimentPlan` | GET `/api/v1/experiments/{agentSpace}/plans/{planId}` | 查询实验计划 | Read |
| `ListExperimentPlans` | GET `/api/v1/experiments/{agentSpace}/plans` | 查询实验计划列表 | List |
| `UpdateExperimentPlan` | PUT `/api/v1/experiments/{agentSpace}/plans/{planId}` | 更新实验计划 | Write |
| `CreateExperimentRun` | POST `/api/v1/experiments/{agentSpace}/plans/{planId}/runs` | 执行实验 | Write |
| `DeleteExperimentRun` | DELETE | 删除实验记录 | Write |
| `GetExperimentRun` | GET | 查询实验记录详情 | Read |
| `ListExperimentRuns` | GET | 查询实验记录列表 | List |
| `UpdateExperimentRun` | PUT | 更新实验运行 | Write |

**实验类型**：`CreateExperimentPlan` 支持离线实验（不传 `experiments` 参数）和在线实验（至少传 1 个实验分组）。在线实验需要指定分组配置（对照组/实验组）和分流比例。

### 3. 数据处理 Pipeline API — 14 个端点

管理数据清洗流水线，将原始 Trace 转化为结构化 Trajectory。

| 端点 | 方法 | 说明 | 访问级别 |
|------|------|------|----------|
| `CreatePipeline` | POST `/agentspace/{agentSpace}/pipeline` | 创建 Pipeline | Write |
| `DeletePipeline` | DELETE | 删除 Pipeline | Write |
| `GetPipeline` | GET | 查询 Pipeline 详情 | Read |
| `ListPipelines` | GET | 查询 Pipeline 列表 | List |
| `UpdatePipeline` | PUT | 更新 Pipeline 配置 | Write |
| `PreviewPipeline` | POST | 流水线预览（调试） | Write |
| `RunPipeline` | POST | 执行 Pipeline | Write |
| `CancelPipelineRun` | POST | 取消 Pipeline 执行 | Write |
| `PausePipeline` | POST | 暂停 Pipeline | Write |
| `ResumePipeline` | POST | 恢复 Pipeline | Write |
| `TerminatePipeline` | POST | 终止 Pipeline | Write |
| `GetPipelineRun` | GET | 查询 Pipeline 执行详情 | Read |
| `ListPipelineRuns` | GET | 查询 Pipeline 执行列表 | List |
| `GetPipelineStats` | GET | 查询 Pipeline 统计信息 | Read |

**Pipeline 工作流**：创建 → 预览（调试） → 运行 → 监控（暂停/恢复/终止）→ 查看执行结果。

### 4. 数据集 API（Dataset）— 7 个端点

管理 Agent 评估与实验所用的数据集。

| 端点 | 方法 | 说明 | 访问级别 |
|------|------|------|----------|
| `CreateDataset` | POST | 创建数据集 | Write |
| `DeleteDataset` | DELETE | 删除数据集 | Write |
| `GetDataset` | GET | 获取数据集详情 | Read |
| `ListDatasets` | GET | 列出数据集 | List |
| `UpdateDataset` | PUT | 更新数据集 | Write |
| `AddDatasetData` | POST | 添加数据集数据 | Write |
| `ExecuteQuery` | POST | 执行查询语句 | Read |

### 5. 智能体空间 API（AgentSpace）— 5 个端点

管理 AgentLoop 资源隔离的基本单元。

| 端点 | 方法 | 说明 | 访问级别 |
|------|------|------|----------|
| `CreateAgentSpace` | POST | 创建 AgentSpace | Write |
| `DeleteAgentSpace` | DELETE | 删除 AgentSpace | Write |
| `GetAgentSpace` | GET | 查询 AgentSpace 信息 | Read |
| `ListAgentSpaces` | GET | 查询 AgentSpaces 列表 | List |
| `UpdateAgentSpace` | PUT | 更新 AgentSpace | Write |

**注意**：AgentSpace 名称在创建后不可更换，且需全局唯一。每个 AgentSpace 与云监控 2.0 工作空间、MSE AI 治理中心命名空间、SLS Project 形成绑定关系。

### 6. 评估任务 API（Evaluation Task）— 9 个端点

管理 Agent 评估任务和执行。

| 端点 | 方法 | 说明 | 访问级别 |
|------|------|------|----------|
| `CreateEvaluationTask` | POST | 创建评估任务 | Write |
| `DeleteEvaluationTask` | DELETE | 删除评估任务 | Write |
| `GetEvaluationTask` | GET | 查询评估任务详情 | Read |
| `ListEvaluationTasks` | GET | 查询评估任务列表 | List |
| `UpdateEvaluationTask` | PUT | 更新评估任务 | Write |
| `GetEvaluationRun` | GET | 获取评估运行详情 | Read |
| `ListEvaluationRuns` | GET | 查询评估运行列表 | List |
| `DeleteEvaluationRun` | DELETE | 删除评估运行 | Write |
| `UpdateEvaluationRun` | PUT | 更新评估运行 | Write |

### 7. 评估器 API（Evaluator）— 10 个端点

管理评估器和评估器技能（Skill）。

| 端点 | 方法 | 说明 | 访问级别 |
|------|------|------|----------|
| `CreateEvaluator` | POST | 创建评估器 | Write |
| `DeleteEvaluator` | DELETE | 删除评估器 | Write |
| `GetEvaluator` | GET | 获取评估器详情 | Read |
| `ListEvaluators` | GET | 查询评估器列表 | List |
| `UpdateEvaluator` | PUT | 更新评估器 | Write |
| `CreateEvaluatorSkill` | POST | 创建评估器技能 | Write |
| `DeleteEvaluatorSkill` | DELETE | 删除评估器技能 | Write |
| `GetEvaluatorSkill` | GET | 获取评估器技能详情 | Read |
| `ListEvaluatorSkills` | GET | 查询评估器技能列表 | List |
| `UpdateEvaluatorSkill` | PUT | 更新评估器技能 | Write |

### 8. 地域 API — 1 个端点

| 端点 | 方法 | 说明 |
|------|------|------|
| `DescribeRegions` | GET | 查询可用地域信息 |

## 数据结构

API 请求和响应中使用的核心数据结构：

- **BackfillStrategy** — 回填策略配置，定义 Pipeline 如何处理历史数据的回填
- **ContinuousStrategy** — 持续处理策略配置，定义实时流数据的持续处理方式
- **DataFilter** — 数据过滤器，支持按条件筛选 Trace 数据（如按模型名称、时间范围、错误状态）
- **Evaluator** — 评估器配置结构体，包含评估器类型、模型配置、评分标准等字段

## LLM Trace 字段

AgentLoop 的 LLM Trace 字段基于 [[concepts/genai-observability-semconv|OpenTelemetry GenAI 语义规范]]扩展，覆盖以下 Span Kind：

| Span Kind | 说明 |
|-----------|------|
| CHAIN | 通用处理链 |
| EMBEDDING | 向量嵌入 |
| RETRIEVER | 检索操作 |
| RERANKER | 重排序 |
| TASK | 任务 |
| LLM | 大模型调用 |
| TOOL | 工具调用 |
| AGENT | Agent 执行 |

详细字段定义参见 [[projects/aliyun-agentloop/references/agentloop-product-features#llm-trace-字段|产品功能中的 LLM Trace 说明]]。

## SDK 与工具

- **多语言 SDK**: Python, Java, Go, TypeScript, .NET, PHP, C++（通过 [SDK 下载](https://api.aliyun.com/api-tools/sdk/AgentLoop?version=2026-05-20)获取）
- **API Explorer**: 在线调试，自动生成 SDK 代码示例
- **loongsuite-util-genai**: Python 组件，辅助完成 LLM Trace 数据的采集接入（详见 [[entities/loongsuite-platform|LoongSuite Platform]]）
- **AgentLoop CLI**: 命令行工具，被 AI Agent 接入工作流使用

## 版本历史

| 版本 | 发布时间 | 变更 |
|------|----------|------|
| 2026-05-20 | 2026-05-20 | 初始版本，包含上下文库、Pipeline、数据集、智能体空间、评估、实验等全部 API |
