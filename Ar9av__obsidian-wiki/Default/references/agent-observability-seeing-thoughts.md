---
title: Agent 可观测性——看见你的 Agent 在想什么
category: references
tags:
  - ai-agent
  - observability
  - tracing
  - metrics
  - evaluation
sources:
  - "FutureCraft AI: 第12篇：Agent 可观测性——看见你的 Agent 在想什么 (2026-06-02)"
summary: FutureCraft AI 第 12 篇从 Traces、Metrics、Logs 三支柱重新定义 Agent 可观测性，对比 LangSmith、Arize、Langfuse、Galileo 等平台，并给出最小可观测性配置。
provenance:
  extracted: 0.70
  inferred: 0.25
  ambiguous: 0.05
base_confidence: 0.55
lifecycle: draft
lifecycle_changed: 2026-07-22
tier: supporting
created: 2026-07-22T00:00:00+08:00
updated: "2026-07-22"
relationships:
  - target: "[[concepts/ai-agent-observability]]"
    type: related_to
  - target: "[[concepts/agent-harness]]"
    type: related_to
  - target: "[[entities/langfuse-llm-observability]]"
    type: related_to
  - target: "[[entities/helicone]]"
    type: related_to
---

# [[concepts/ai-agent-observability|Agent 可观测性]]——看见你的 Agent 在想什么

> 原文：第12篇：Agent 可观测性——看见你的 Agent 在想什么（FutureCraft AI，2026-06-02）

## 为什么 Agent 可观测性更难

传统服务有确定输入输出、stack trace、latency 分布、HTTP status code。Agent 的执行路径是非确定性的：

- **推理不透明**：模型内部推理是 token 序列，看到的是最终文本而非推理步骤。
- **工具调用链**：工具 A 的结果作为输入调用工具 B，可能 10-20 步，错误级联传播。
- **概率性失败**：同一任务重跑可能成功，传统"复现 → 修复 → 验证"工作流失效。
- **多 Agent 时序**：并行执行、共享状态、时序依赖让追踪更复杂。

## 重新定义三支柱

### Traces：推理-工具调用链路追踪

Agent Trace 追踪的是**推理-行动序列**，例如：

```
Agent 收到任务
├── LLM 推理："需要先了解代码库结构，用 glob 搜索"
├── Tool Call: Glob("**/*.py")
├── LLM 推理："文件太多，聚焦 src/ 目录"
├── Tool Call: Read("src/auth/jwt.py")
├── LLM 推理："发现问题：JWT 密钥硬编码"
└── 最终答案生成
```

### Metrics：超越延迟和错误率

Agent Metrics 还需关注：token 使用、工具调用次数、任务完成率、重试次数、上下文使用率、成本/任务。

### Logs：模型输入输出完整记录

需记录完整模型输入（系统提示 + 对话历史）、完整模型输出（含思考过程）、工具调用参数和返回值、token 计数和成本、错误详情。

## 主流平台对比

| 平台 | 核心优势 | 适合场景 |
|------|---------|---------|
| LangSmith | 近零接入成本，原生 LangChain 集成 | LangChain/LangGraph 技术栈 |
| Arize AI | Span 级追踪、Phoenix 开源、漂移检测 | 企业合规、长期监控模型漂移 |
| [[entities/langfuse-llm-observability|Langfuse]] | 自托管、成本透明、灵活评估 | 数据隐私要求高、控制平台成本 |
| Galileo | 评估 + 护栏 + 可观测一体化 | 输出质量持续监控、护栏统一 |

## OpenTelemetry for LLMs

OpenLLMetry 是目前最成熟的 OTel for LLMs 实现，定义标准 LLM span 属性（`llm.vendor`、`llm.request.model`、`llm.usage.prompt_tokens` 等）。标准化意义：写一次 instrumentation，数据可同时发给 LangSmith、Langfuse、Arize。

## 生产典型组合

- **网关层（成本追踪）**：[[entities/helicone|Helicone]] / Portkey 作为 LLM 网关，记录 Token 用量和成本，支持请求缓存。
- **分析层（质量监控）**：Langfuse / LangSmith 做完整 Trace 记录、质量评估、失败分析。

## 最小可观测性配置

1. **接入 Langfuse（5 分钟）**：`pip install langfuse`，配置公钥/私钥/Host，用 `@observe()` 装饰器。
2. **添加关键 Metrics（10 分钟）**：用 `langfuse_context.score_current_trace()` 记录任务级别 success。
3. **设置成本告警**：用 Helicone 或 Langfuse 预算功能设置每日/每周 Token 上限。
4. **建立失败分析工作流**：每周 review 失败 Trace，找最常见失败步骤、Token 异常位置、错误集中工具。
