---
title: LoongSuite Platform
category: entities
tags: [ai, observability, alibaba, opentelemetry]
sources:
  - "阿里云开发者: 当 AI Coding Agent 成为基础设施：我们为什么要开源 LoongSuite Pilot (2026-06-12)"
  - "阿里云开发者: 阿里巴巴 & 蚂蚁 LoongSuite GenAI 可观测语义规范 (2026-05-12)"
  - "阿里云可观测: Python 应用可观测重磅上线：解决 LLM 应用落地的“最后一公里”问题 (2024-11-08)"
  - "阿里云可观测: 零代码改造！LoongSuite AI 采集套件观测实战 (2025-09-01)"
  - "阿里云开发者: 详解大模型应用可观测全链路 (2025-03-13)"
  - "阿里云云原生: 重磅发布丨云监控 AI Agent 可观测，企业生产级 Agent 首选全域观测平台 (2026-05-31)"
  - "阿里云开发者社区: 从 AI Agent 到模型推理：端到端 AI 可观测实践 (2026-07-16)"
summary: LoongSuite 是阿里云推出的 AI 可观测产品体系，包含 LoongCollector（主机探针）、语言 Agent SDK（自动插桩）、和 LoongSuite Pilot（端侧 AI Coding Agent 采集器），基于 OpenTelemetry GenAI SemConv 实现标准化采集。
provenance:
  extracted: 0.72
  inferred: 0.23
  ambiguous: 0.05
base_confidence: 0.78
lifecycle: draft
lifecycle_changed: 2026-07-16
tier: supporting
created: 2026-07-16T00:00:00+08:00
updated: "2026-07-22"
relationships:
  - target: "[[concepts/genai-observability-semconv]]"
    type: implements
  - target: "[[concepts/ai-agent-observability]]"
    type: implements
  - target: "[[references/agentlogsbench]]"
    type: related_to
  - target: "[[concepts/umodel]]"
    type: related_to
  - target: "[[entities/langfuse-llm-observability]]"
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
2026 年 6 月开源的**端侧 AI Coding Agent 可观测采集器**，专门解决 AI Coding Agent（Cursor、Claude Code、Codex、Qoder 等）运行在开发者本地机器上导致的"可观测盲区"问题。参见 [[entities/loongsuite-pilot]]。

**设计选择：**

- **ALL IN ONE 架构**：不针对单个 Agent 做单点适配，而是定义统一的 Agent 行为数据模型，通过 `agents.d/*.json` 声明化文件对接不同 Agent 的数据源
- **端侧数据归集**：从 IDE 历史文件、本地 SQLite 数据库、Session 日志、Hook JSONL 等分散位置统一采集
- **多 Agent 横向对比**：统一数据格式使不同 Agent 的 Token 消耗、任务完成率、工具调用模式可直接对比
- **采集基类抽象**：将差异封装为 Hook、IDE、SQLite、Session、CLI Forwarder 五种采集基类，新 Agent 只需选择基类并实现 2-3 个方法
- **多目标输出**：本地 JSONL、SLS、HTTP Endpoint、OTLP Trace 并行扇出，不绑定后端

Pilot 回答的核心问题：团队里每个人的 AI Coding Agent 每天消耗了多少 Token？哪些任务适合交给 Agent？Agent 输出不符合预期时中间经历了什么？一个 Agent 在某次会话中修改了 30 个文件，这些修改的完整链路是什么？

## Python Agent 与 AI 应用深度集成

LoongSuite Python Agent 基于 OpenTelemetry Python Agent 底座扩展，面向 AI 应用框架量身定制：

- **框架覆盖**：支持 LangChain、LlamaIndex、通义千问、OpenAI、Dify、PromptFlow 等国内外框架和模型
- **无侵入埋点**：利用框架 Callback 机制和 Python monkey patch，用户代码无需修改即可接入
- **生产增强**：支持 unicorn/gunicorn 多进程、gevent 协程、流式上报拆分，解决开源探针在 gevent 下卡死的问题 ^[extracted]
- **模型推理观测**：可部署到 vLLM/SGLang 等推理加速框架内部，采集 TTFT、TPOT、请求排队、GPU 利用率、KV Cache 命中率等指标 ^[extracted]

## MCP Token 黑洞观测

针对 MCP 工具链的"Token 黑洞"问题——Agent 最终输出少量 Token，但背后调用几十次模型和大量 MCP Tools，实际消耗上万 Token——LoongSuite 支持采集每个 MCP Tool 的调用耗时和 Token 消耗，帮助团队发现隐藏成本 ^[extracted]。

## Dify 端到端链路追踪

LoongSuite Python Agent 针对 Dify 内部执行链路精细埋点：
- 一次接入所有 Dify 应用全体生效
- 将 Dify 内部 workflow 与外部微服务调用、模型推理完整串起来
- 展示 workflow 每步的 input/output 和 Token 消耗
- 支持多层级全局维度分析 ^[extracted]

## 云监控 2.0

阿里云云监控 2.0 是融合日志服务 SLS、云监控 CMS、应用实时监控服务 ARMS 的一站式可观测平台，提供基于指标、链路、日志、事件的统一观测图谱。结合 LoongSuite 探针，可实现从 UI 端侧 → 网关 → 后端 → 组件依赖 → 模型的完整业务链路透视 ^[extracted]。

## 技术栈

- **采集标准**：[[concepts/genai-observability-semconv|OpenTelemetry GenAI SemConv]] + 阿里巴巴/蚂蚁扩展提案（Entry/Step Span、Skill 语义、Token 级观测）
- **数据传输**：OTLP 协议
- **存储后端**：阿里云可观测平台（SLS 日志服务、ARMS 应用监控）
- **可视化**：阿里云可观测控制台 + Grafana

## 开源策略

LoongSuite Pilot 于 2026 年 6 月开源，LoongCollector 的 AI 采集插件同步开源。开源的动机：AI Coding Agent 的可观测性是行业共性问题，单一厂商无法覆盖所有 Agent 的数据格式变化，需要社区共建适配层 ^[inferred]。

## 云监控 AI Agent 可观测产品

2026 年 5 月，阿里云云监控基于 LoongSuite 技术栈正式发布 **AI Agent 可观测**产品，定位为企业生产级 Agent 首选全域观测平台。该产品采用接入层、数据层、分析层、应用层四层架构 ^[extracted]：

- **接入层**：多语言自研探针，支持 20+ 主流 AI 框架，兼容 OpenTelemetry GenAI 语义规范
- **数据层**：基于 [[concepts/umodel|UModel]] 统一建模体系，将基础设施、AI 服务、AI 资产统一建模
- **分析层**：全景拓扑、链路追踪、会话分析、指标大盘、智能告警五大模块
- **应用层**：Agentic 化，提供 CLI/Skills 接口，支持 AI Agent 直接调用可观测能力

核心场景包括 Token 成本治理、Multi-Agent 故障根因定位、数据驱动的 Agent 持续优化。详见 [[references/alicloud-cloudmonitor-ai-agent-observability]]。

## 与同类工具的定位差异

| 维度 | LoongSuite | [[entities/langfuse-llm-observability|Langfuse]] | Honeycomb |
|------|-----------|----------|-----------|
| 定位 | 全链路采集 + 平台 | LLM 可观测与应用评估 | 通用可观测 + Agent Timeline |
| 采集方式 | 无侵入探针 + SDK | SDK 埋点 | OTel Collector |
| 端侧覆盖 | Pilot 支持 Coding Agent | 不覆盖 | 不覆盖 |
| 标准遵循 | OTel GenAI SemConv | 自有数据模型 | OTel |

## Related

- [[references/agentlogsbench]] — Agent 可观测存储基准测试，LoongSuite 的存储选型参考
- [[entities/dify]] — LoongSuite Python Agent 集成的 LLMOps 平台
- [[entities/vllm]] — LoongSuite 支持观测的推理加速框架
- [[references/aliyun-end-to-end-ai-observability]] — 端到端 AI 可观测实践详情
