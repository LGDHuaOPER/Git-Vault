---
title: AI Observe Stack
category: entities
tags: [ai, observability, database, olap]
sources:
  - "SelectDB: 我们用 AI Observe Stack 观测了 OpenClaw (2026-03-04)"
  - "SelectDB: Apache Doris 在 AgentLogsBench 中领先 (2026-07-07)"
summary: AI Observe Stack 是基于 Apache Doris / SelectDB 构建的开源 AI Agent 可观测平台，通过 OpenTelemetry Collector + Doris + Grafana 提供 Traces/Metrics/Logs 三合一能力，5 分钟可完成部署。
provenance:
  extracted: 0.60
  inferred: 0.35
  ambiguous: 0.05
base_confidence: 0.61
lifecycle: draft
lifecycle_changed: 2026-07-16
tier: supporting
created: 2026-07-16T00:00:00+08:00
updated: "2026-07-22"
relationships:
  - target: "[[concepts/ai-agent-observability]]"
    type: implements
  - target: "[[references/agentlogsbench]]"
    type: related_to
  - target: "[[entities/openclaw]]"
    type: uses
  - target: "[[concepts/agent-harness]]"
    type: related_to
  - target: "[[concepts/agent-trace-and-timeline]]"
    type: related_to
  - target: "[[entities/langfuse-llm-observability]]"
    type: related_to
---

# AI Observe Stack

AI Observe Stack 是基于 **Apache Doris**（及其云服务 SelectDB）构建的 AI Agent 可观测存储解决方案。它定位于 Agent 可观测体系的**数据层**——解决 Agent Trace 数据的存储、检索和聚合问题。

## 为什么需要专用存储

Agent 可观测数据有四个传统 APM 存储难以满足的特征：

1. **大文本短语搜索** — Agent 的输出 payload 从 5KB 到 1MB，故障特征常隐藏在长文本中。传统日志系统（ELK、Loki）的倒排索引在大文本场景下膨胀严重。
2. **动态 JSON 过滤** — 关键分析字段（模型版本、Prompt 模板、租户 ID）位于动态 JSON 中，不同供应商写入不同属性。预展开 JSON 路径维护辅助表会导致 ETL 工程膨胀。
3. **有序 Trace 回放** — Agent Trace 需要按时间顺序取回完整链路（含嵌套层级），不能仅按 Trace ID 聚合扁平 Span。
4. **实时聚合与持续写入并存** — 排障过程中成本看板、失败率看板仍需实时刷新，查询延迟需在毫秒到几十毫秒级。

这本质上是一个**混合负载数据系统问题**——同时要求搜索引擎、OLAP 数据库和时序数据库的能力 ^[inferred]。

## 架构

AI Observe Stack 基于三个成熟开源项目构建 ^[extracted]：

| 组件 | 作用 |
|------|------|
| **OpenTelemetry Collector** | 遥测数据网关，接收 OpenTelemetry 协议数据 |
| **Apache Doris / SelectDB** | 存储层，VARIANT 类型 + 倒排索引，天然适配半结构化数据 |
| **Grafana + Doris App 插件** | 可视化层，支持 SQL 查询和预置 Dashboard |

核心优势 ^[extracted]：
- **Traces + Metrics + Logs 三合一**：统一采集、统一存储、统一查询
- **SQL 查询**：标准 SQL 即可分析所有数据
- **实时分析**：数据写入即可查询，无需等待 ETL 或预聚合
- **5 分钟部署**：一条 `docker compose up -d` 搞定

### 数据流

```
Agent 运行时 → OTel Collector / 自定义 Exporter
                    → Doris (Observation 表)
                         ├── 短语搜索（倒排索引）
                         ├── JSON 动态过滤（VARIANT 类型）
                         ├── Trace 回放（按 trace_id + 时间排序）
                         └── 实时聚合（MPP 查询引擎）
```

Doris 的列式存储 + MPP 架构天然适合此类场景：高吞吐写入、列式压缩大文本、向量化执行聚合查询。

## 实践案例

### OpenClaw 安全观测

SelectDB 团队使用 AI Observe Stack 在**一天内**（由 AI 辅助开发）搭建了 [[entities/openclaw|OpenClaw]] 的可观测系统，实现了：

- 实时监控 Agent 执行的每条 shell 命令
- 检测敏感操作模式（如访问 `/etc/passwd`、外传 SSH 密钥）
- 追踪 Token 消耗和 API 成本
- 回放完整 Task Trace 排查异常行为

发现了 OpenClaw 的三大黑盒问题：**安全黑盒**（执行了什么命令不可见）、**成本黑盒**（Token 消耗无法归因）、**行为黑盒**（Agent 的决策链路不可追踪）。

### 阶跃星辰 PB 级平台

阶跃星辰（StepFun）基于 SelectDB 构建了 PB 级的 Agent 可观测平台，支撑其大规模 Agent 服务的生产运维。^[inferred]

## 预置 Dashboard

针对 OpenClaw 观测场景，AI Observe Stack 预置三个 Dashboard ^[extracted]：

### Security & Audit Dashboard

顶部四个核心指标卡片：
- **Dangerous Commands**：检测到的危险 shell 命令数量（`rm -rf`、`sudo`、`chmod 777`、`curl | sh` 等）
- **Prompt Injection**：外部内容中检测到的注入模式数量（`ignore previous instructions`、`you are now`、`DAN mode` 等）
- **Outbound Actions**：Agent 主动发出的对外操作（发邮件、发消息、调用外部 API）
- **Sensitive File Access**：Agent 访问敏感文件的次数（`.ssh/id_rsa`、`.env`、`credentials.json` 等）

下钻面板包括：Security Event Timeline、Top Risk Sessions、Dangerous Command Detection、Prompt Injection Detection、Outbound Data Flow Audit、Sensitive File Access Log、User Message Audit Trail、Tool Execution Log、Tool Calls vs Errors Over Time。

### Cost & Efficiency Dashboard

- Token Usage Over Time：按模型分别统计 input/output tokens
- Input Tokens per Turn（Context Window Growth）：展示上下文滚雪球效应
- Per-Question Cost：把成本拆解到每个用户问题，包括 `ai_steps`、`total_input`、`user_question`

### Agent Behavior Dashboard

- 性能概览：Avg Request Latency、Avg Turn Duration、Total Spans、Trace Chains
- Tool 调用分布：browser、exec、web_fetch 等工具的调用统计
- Span Performance Summary：`openclaw.request` P95 远高于平均值提示长尾请求
- Conversation Flow：完整对话流水表，按时间倒序展示交互生命周期

## Doris App 插件增强

### Discover（日志探索）

类似 Kibana 的日志探索界面，支持 SQL 和 Lucene 两种查询模式。可展开单条日志查看完整结构化详情，包括 Table 视图、JSON 视图、原始数据结构，以及 "Surrounding items" 上下文还原。适用于即席查询、关键词搜索、数据验证。^[extracted]

### Traces（Trace 分析）

可按 Service、Operation、Tags、Duration 筛选，散点图展示 Trace 耗时分布。Waterfall 视图将 Agent 请求完整生命周期展开为调用链。适用于慢请求定位、异常行为取证、Agent 行为理解。^[extracted]

## 性能基准

在 **AgentLogsBench** 基准测试中，Apache Doris 在综合排名中领先，尤其在 Hot Query Runtime（高并发查询延迟）场景表现突出。参见 [[references/agentlogsbench]]。

## 生态定位

AI Observe Stack 是**存储层解决方案**，不绑定特定的采集或可视化层：

- **采集层兼容**：OTel Collector、LoongCollector、[[entities/langfuse-llm-observability|Langfuse]] SDK 均可对接
- **可视化层开放**：通过标准 SQL 接口对接 Grafana、Superset、或自定义面板
## Related

- [[concepts/agent-harness]] — Agent Harness 框架层产生运行时数据，AI Observe Stack 提供存储和分析
- [[concepts/agent-trace-and-timeline]] — Agent Trace 的存储和回放依赖于 OLAP 存储后端的能力
