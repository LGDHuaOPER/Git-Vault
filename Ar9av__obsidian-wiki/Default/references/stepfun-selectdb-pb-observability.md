---
title: 阶跃星辰基于 SelectDB 构建 PB 级 Agent 可观测平台
category: references
tags:
  - ai-agent
  - observability
  - apache-doris
  - selectdb
  - large-scale
  - steptrace
sources:
  - "SelectDB: 阶跃星辰基于 SelectDB 构建 PB 级 Agent 可观测平台 (2026-06-26)"
summary: 阶跃星辰（StepFun）基于 SelectDB（Apache Doris）构建 PB 级 Agent 可观测平台 StepTrace 的架构实践，包括 Agent Trace 数据模型、检索分析、成本治理、评测闭环和基础设施关联六大能力要求。
provenance:
  extracted: 0.70
  inferred: 0.25
  ambiguous: 0.05
base_confidence: 0.60
lifecycle: draft
lifecycle_changed: "2026-07-22"
tier: supporting
created: 2026-07-16
updated: "2026-07-22"
relationships:
  - target: "[[concepts/ai-agent-observability]]"
    type: related_to
  - target: "[[entities/litefuse]]"
    type: related_to
  - target: "[[entities/ai-observe-stack]]"
    type: related_to
  - target: "[[entities/apache-doris-agent-observability]]"
    type: uses
  - target: "[[entities/langfuse-llm-observability]]"
    type: related_to
  - target: "[[entities/vllm]]"
    type: related_to
---

# 阶跃星辰基于 SelectDB 构建 PB 级 Agent 可观测平台

阶跃星辰（StepFun）作为国内领先的大模型公司，面对海量 Agent 调用产生的 trace 数据，选择基于 **SelectDB**（Apache Doris 内核）构建 **PB 级 Agent 可观测平台 StepTrace**。

## Agent 可观测的本质挑战

Agent 时代，观测对象从**确定性的程序**变成了**概率行为的系统**，不确定性大大增加。在传统微服务场景下，排障决策树体现在代码和系统架构中；但在 Agent 场景下，每一步决策过程和结果都无法收敛成确定流程 ^[extracted]。

StepTrace 需要具备六个部分的能力 ^[extracted]：

| 能力 | 说明 |
|------|------|
| **数据模型** | Agent Trace 特有属性：prompt、reasoning、toolcall 等应在设计之初考虑 |
| **Session 级别分析** | 多轮对话才能达成目标，需要会话级别的还原和复盘分析 |
| **成本分析** | Agent 每步 token 消耗需体现在 trace 中，支撑成本统计与治理 |
| **Trace 检索** | 支持用户、标签、环境等元数据检索，以及输入输出中的文本检索 |
| **评测闭环** | Agent trace 必须可分析、可回放，为持续迭代提供测试数据或样本集 |
| **基础设施关联** | trace 能关联底层基础设施（沙箱、KV Cache、调度），定位非预期效果根因 |

## 数据底座的四个要求

支撑 Agent Trace 的数据底座需要 ^[extracted]：

1. **宽表建模**：Trace 属性能够在宽表中建模和分析
2. **灵活检索**：除 trace id 点查外，支持关键字全文检索和 metadata 嵌套 JSON 检索
3. **多维指标聚合**：从 trace 底表支持各种灵活的 rollup，聚合成功率、质量、token 成本等派生数据
4. **混合负载治理**：离在线一体查询需要负载隔离和管理

## 为什么选择 SelectDB

SelectDB（基于 Apache Doris 内核）提供的优秀特性 ^[extracted]：

| 特性 | 作用 |
|------|------|
| **VARIANT 类型** | 支撑 JSON 半结构化数据；写入时自动识别字段名和类型，拆分子列，列式存储提升压缩率和查询性能 |
| **倒排索引** | 支持高效点查和关键词过滤，2023 年开始支持，经过多年 PB 级生产环境验证 |
| **异步物化视图** | 灵活轻量的 rollup 能力，支持多维度聚合和透明改写 |
| **Stream Load 实时导入** | 承接大批量写入吞吐，p99 延迟在 1s 以内，单次请求可达 500MB 大批次 |
| **Workload Group** | 隔离在线和离线负载 |
| **FE/BE 分离架构** | 扩展灵活，运维成本低，扩容升级无需像 ClickHouse 手动搬迁数据 |

## StepTrace 落地实践

### 架构

StepTrace 在传输协议上兼容 **[[entities/langfuse-llm-observability|Langfuse]]、Litefuse 和 OpenTelemetry** 协议，trace 上下文中使用 W3C 协议，复用 OpenTelemetry 的 gRPC、Collector 等技术栈 ^[extracted]。

```
Agent 服务 → OpenTelemetry SDK → Kafka（缓冲） → SelectDB（存储+分析）
                                                          ↓
                                                    Grafana / 自定义仪表盘
```

数据采集后通过 Stream Load 写入 SelectDB，在 GB/s 高吞吐写入负载下达到**秒级实时可见**效果。通过物化视图实现预聚合和预计算，例如 token 整条成本计算。

### 场景一：SWE-Agent

SWE-Agent 是 StepTrace 的重要应用。通过对 SWE Agent 做 SDK 埋点，观测镜像拉取、沙盒创建、沙盒执行、多轮模型调用、工具调用等环节，保障 SWE Agent 稳定性。

StepTrace 能清楚看到 rollup 链路和 evaluation 评测链路上的各个环节，支持传统日志/轨迹文件难以实现的高级分析：Agent 多版本横向比较、时序性能变化、成功率等 ^[extracted]。

### 场景二：智能座舱 Agent

座舱 Agent 面临安全和成本挑战。通过 trace 方法观测链路每次推理过程，分析为何未得到用户预期结果，再针对性提升效果。同时构建评测集，在替换新模型或更新架构时进行量化效果评估。

## 未来展望

阶跃星辰希望围绕 SelectDB 构建一体化的 Agent 数据分析平台 ^[extracted]：

1. **基础设施层面打通**：生产级 Agent 运行链路复杂，需要统一观测模型决策、沙箱执行、推理调度、引擎优化，例如 [[entities/vllm|vLLM]] 层的 prefill/decode、沙箱中 eBPF 无侵入观测和安全拦截
2. **数据闭环**：将 trace 数据直接对接 **ATIF**（Agent 运行轨迹格式），打通 OpenHands、SWE-Bench、Gemini CLI 等评测框架，成为 SFT、RL、Evaluation 的数据底座
3. **数据开放**：接入企业级数据平台，对接公司内部大数据组件，构建基于 Trace 的完整数仓体系

## 产品化：Litefuse

SelectDB 将这些能力产品化为 **Litefuse**——一个开箱即用的 Agent 可观测与评估产品。需要 Agent 可观测能力的团队可以基于 SelectDB 自建，也可以直接使用 Litefuse 快速迭代，并基于开源代码持续迭代个性化需求 ^[extracted]。

## 相关页面

- [[entities/litefuse]] — SelectDB 产品化的 Agent 可观测平台
- [[entities/ai-observe-stack]] — 基于 Doris 的 AI 可观测存储后端
- [[entities/apache-doris-agent-observability]] — Apache Doris 在 Agent 可观测性中的应用
- [[concepts/ai-agent-observability]] — AI Agent 可观测性整体概念
