---
title: LoongSuite Platform
category: entities
tags: [ai, observability, alibaba, opentelemetry]
sources:
  - "阿里云开发者: 当 AI Coding Agent 成为基础设施：我们为什么要开源 LoongSuite Pilot (2026-06-12)"
  - "阿里云开发者: 阿里巴巴 & 蚂蚁 LoongSuite GenAI 可观测语义规范 (2026-05-12)"
  - "阿里云可观测: 零代码改造！LoongSuite AI 采集套件观测实战 (2025-09-01)"
  - "阿里云开发者: 详解大模型应用可观测全链路 (2025-03-13)"
summary: LoongSuite 是阿里云推出的 AI 可观测产品体系，包含 LoongCollector（主机探针）、语言 Agent SDK（自动插桩）、和 LoongSuite Pilot（端侧 AI Coding Agent 采集器），基于 OpenTelemetry GenAI SemConv 实现标准化采集。
provenance:
  extracted: 0.70
  inferred: 0.25
  ambiguous: 0.05
base_confidence: 0.78
lifecycle: draft
lifecycle_changed: 2026-07-16
tier: supporting
created: 2026-07-16T00:00:00+08:00
updated: 2026-07-16T00:00:00+08:00
relationships:
  - target: "[[concepts/genai-observability-semconv]]"
    type: implements
  - target: "[[concepts/ai-agent-observability]]"
    type: implements
  - target: "[[references/agentlogsbench]]"
    type: related_to
---

# LoongSuite Platform

LoongSuite 是阿里云可观测团队推出的 **AI 原生可观测产品体系**，覆盖从传统服务端到 AI Coding Agent 端侧的完整可观测链路。它是 OpenTelemetry GenAI Semantic Conventions 在阿里巴巴内部大规模落地（170+ 业务线）的工程载体。

## 产品矩阵

### LoongCollector（主机探针）
面向服务端的无侵入可观测采集器，通过 eBPF 和插件机制实现**零代码改造**接入：

- 自动识别 AI 框架调用（LangChain、LlamaIndex、Spring AI Alibaba、Dify 等）
- 按 OTel GenAI SemConv 标准化输出 Trace、Metrics、Logs
- 支持 Python、Java、Go 等多语言运行时
- 覆盖 AI 网关（Higress）、模型服务（Qwen、DeepSeek）、向量数据库、缓存等全链路组件

采集的典型数据类型包括：模型调用延迟与 Token 消耗、工具调用成功率与耗时、RAG 检索的向量相似度与召回率、内容安全审查的拦截统计。

### 语言 Agent SDK（自动插桩）
面向应用开发者的**进程内探针**，支持在 Python、Java、Go 应用中通过几行代码接入：

```python
# Python SDK 示例
from loongsuite import LoongSuite
ls = LoongSuite.get_handler()
with ls.trace_llm_call(model="qwen-max", prompt=prompt) as span:
    response = model.generate(prompt)
    span.set_token_usage(response.usage)
```

通过 Context Manager 模式自动完成遥测数据的采集和输出，无需手动埋点。

### LoongSuite Pilot（端侧采集器）
2026 年 6 月开源的**端侧 AI Coding Agent 可观测采集器**，专门解决 AI Coding Agent（Cursor、Claude Code、Codex、Qoder 等）运行在开发者本地机器上导致的"可观测盲区"问题。

**设计选择：**

- **ALL IN ONE 架构**：不针对单个 Agent 做单点适配，而是定义统一的 Agent 行为数据模型，通过标准化适配层对接不同 Agent 的数据源
- **端侧数据归集**：从 IDE 历史文件、本地 SQLite 数据库、Session 日志等分散位置统一采集
- **多 Agent 横向对比**：统一数据格式使不同 Agent 的 Token 消耗、任务完成率、工具调用模式可直接对比

Pilot 回答的核心问题：团队里每个人的 AI Coding Agent 每天消耗了多少 Token？哪些任务适合交给 Agent？Agent 输出不符合预期时中间经历了什么？

## 技术栈

- **采集标准**：OpenTelemetry GenAI SemConv + 阿里巴巴/蚂蚁扩展提案（Entry/Step Span、Skill 语义、Token 级观测）
- **数据传输**：OTLP 协议
- **存储后端**：阿里云可观测平台（SLS 日志服务、ARMS 应用监控）
- **可视化**：阿里云可观测控制台 + Grafana

## 开源策略

LoongSuite Pilot 于 2026 年 6 月开源，LoongCollector 的 AI 采集插件同步开源。开源的动机：AI Coding Agent 的可观测性是行业共性问题，单一厂商无法覆盖所有 Agent 的数据格式变化，需要社区共建适配层 ^[inferred]。

## 与同类工具的定位差异

| 维度 | LoongSuite | Langfuse | Honeycomb |
|------|-----------|----------|-----------|
| 定位 | 全链路采集 + 平台 | LLM 可观测与应用评估 | 通用可观测 + Agent Timeline |
| 采集方式 | 无侵入探针 + SDK | SDK 埋点 | OTel Collector |
| 端侧覆盖 | Pilot 支持 Coding Agent | 不覆盖 | 不覆盖 |
| 标准遵循 | OTel GenAI SemConv | 自有数据模型 | OTel |

## Related

- [[references/agentlogsbench]] — Agent 可观测存储基准测试，LoongSuite 的存储选型参考
