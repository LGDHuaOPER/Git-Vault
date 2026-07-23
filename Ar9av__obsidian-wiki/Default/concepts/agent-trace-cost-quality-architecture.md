---
title: "AI 可观测性 Trace-Cost-Quality 三合一架构"
category: concepts
tags:
  - ai-agent
  - observability
  - trace
  - cost-management
  - quality

relationships:
  - target: "[[entities/helicone]]"
    type: related_to
  - target: "[[entities/vllm]]"
    type: related_to
sources:
  - "程序猿架构之路: AI可观测性-Trace-Cost-质量三合一 (2026-07-01)"
  - "AI Engineer编程微信公众号: Agent 可观测与质量评测体系：从数据采集到数据飞轮的完整实践 (2026-07-12)"
summary: "将分布式追踪、成本账本、质量评分统一在 OpenTelemetry GenAI 语义约定之上——让 on-call 在 5 分钟内回答'慢在哪、贵在哪、错在哪'的三合一可观测架构。"
base_confidence: 0.55
lifecycle: draft
lifecycle_changed: "2026-07-16"
tier: supporting
provenance:
  extracted: 0.55
  inferred: 0.35
  ambiguous: 0.10
created: "2026-07-16"
updated: "2026-07-22"
---

# AI 可观测性 Trace-Cost-Quality 三合一架构

## 三支柱

AI 可观测性是对 LLM 应用建立**分布式追踪 + 成本账本 + 质量评分**的统一遥测契约——让 on-call 能在 5 分钟内回答"慢在哪、贵在哪、错在哪"。^[extracted]

| 支柱 | 回答的问题 | 核心指标 |
|------|-----------|---------|
| **Trace** | 哪一步慢/失败？ | span 树、TTFT、tool latency |
| **Cost** | 谁花了多少钱？ | $/token、$/task、$/\$revenue |
| **Quality** | 输出好不好？ | faithfulness、hallucination rate、采纳率 |

## OpenTelemetry GenAI Semantic Conventions

关键 span 属性（2025 OTel gen-ai 草案口径）^[extracted]：

| 属性 | 示例 | 用途 |
|------|------|------|
| `gen_ai.system` | `openai` / `anthropic` | 供应商识别 |
| `gen_ai.request.model` | `gpt-4o-mini` | 路由对账 |
| `gen_ai.usage.input_tokens` | `2400` | 成本计算 |
| `gen_ai.usage.output_tokens` | `180` | 成本计算 |
| `gen_ai.response.finish_reasons` | `stop` | 截断诊断 |
| `app.tenant_id` | `shop_882` | 租户 chargeback |
| `app.feature` | `checkout_assist` | 功能预算归因 |
| `app.trace.quality.faithfulness` | `0.87` | 质量分 |

## Trace 设计：一棵会话树

典型 RAG Agent 的完整 Trace 结构 ^[extracted]：

```
session_trace (root)
├── guardrail_span (12ms)
├── retrieve_span (85ms, top_k=8)
│   ├── embed_span (22ms)
│   └── vector_search_span (41ms)
├── rerank_span (120ms)
├── chat_span (TTFT 620ms, TPOT 38ms, tokens in/out)
│   ├── tool_call get_order (45ms)
│   └── tool_call get_logistics (38ms)
└── async_judge_span (faithfulness 0.89)
```

### SLO 映射

| Span | SLO | 告警 |
|------|-----|------|
| retrieve P99 | 200ms | 5min 窗口 |
| chat TTFT P99 | 1s | - |
| tool error rate | 1% | - |
| e2e P99 | 15s | - |

## 工具链选型

| 产品 | 强项 | 弱项 | 推荐场景 |
|------|------|------|---------|
| **Langfuse** | trace + eval + prompt 管理一体 | 自托管运维 | 默认主栈（开源可私有化） |
| **Phoenix (Arize)** | 向量漂移、RAG eval | 商业功能分层 | RAG 质量深析 |
| **[[entities/helicone|Helicone]]** | 代理式成本日志极快 | 依赖代理链路 | API 流量侧快速接入 |
| **Datadog LLM** | 与现有 APM 统一 | 单价高 | 已有 DD 的企业 |
| **Litefuse** | Doris 原生、存储成本低 88% | 较新 | 成本敏感 + 私有化部署 |

推荐组合 ^[extracted]：Langfuse 做 trace + dataset + 在线 eval；Prometheus 抓 [[entities/vllm|vLLM]] TTFT/TPOT/GPU；LiteLLM spend_logs 对账云账单；Phoenix 周度 RAG 漂移分析。

## 质量评估矩阵

| 方式 | 延迟 | 成本 | 用途 |
|------|------|------|------|
| 规则 | 实时 | 低 | 价格格式、引用存在 |
| LLM-as-Judge | 秒级 | 高 | faithfulness 评分 |
| 人工抽检 | 天级 | 中 | 校准 judge |
| 用户反馈 | 实时 | 低 | 👎/转人工信号 |

在线采样策略：5% 会话异步 judge；faithfulness < 0.8 自动打标 `quality_incident`。^[extracted]

## 可观测性成熟度模型

^[inferred]

| 等级 | 能力 |
|------|------|
| L1 | 仅日志 + 账单 |
| L2 | OTel trace + token 归因 |
| L3 | + 在线 judge 采样 + 看板 |
| L4 | + 自动回流 Harness + 成本预算自治 |

## 轨迹评估：从 Trace 到可评估数据

原始 Trace 信息多、密度低，直接输入 LLM 会超出上下文限制。设计了**三阶段加工流水线**将 Trace 转化为可评估的轨迹数据 ^[extracted]：

### 轨迹提取策略

保留 LLM 决策逻辑和工具调用关系，丢弃以下技术噪音：
- 耗时数据（供 Code 评估使用，但不传给 LLM 评估器）
- Token 数（记录在成本维度，不干扰语义评估）
- 框架内部细节（SDK 实现细节无关质量判断）

工具返回内容压缩为 `${response}` 占位，保留调用结构而非完整响应体。

### 分层信息处理

从原始 Trace → 结构化轨迹 → 评估结果，每层都有明确的信息过滤策略：

1. **原始 Trace** — 保留所有原始数据作为审计底稿
2. **结构化轨迹** — 提取决策逻辑、工具调用关系，压缩技术元数据
3. **评估输入** — 仅向 LLM 评估器传递语义相关的内容

**分层信息处理原则**：保留决策逻辑，丢弃执行细节；Code 评估效率指标，LLM 评估语义质量。^[extracted]

## 常见陷阱

1. **只采 trace 不算 token**：span 无 `usage.*` → FinOps 黑洞。Fix：Gateway 统一注入；vLLM 用 prometheus `vllm:prompt_tokens_total`。^[extracted]
2. **PII 进 trace**：用户手机号明文 → 合规失败。Fix：hash/掩码；`gen_ai.prompt` 默认不记录全文，只记 hash + 长度。^[extracted]
3. **质量分与业务 KPI 脱节**：faithfulness 高但转化率降 → 评错维度。Fix：scorecard 必含采纳率/转人工率。^[extracted]
4. **多工具链 trace 断裂**：Langfuse + 自研日志 trace_id 不一致。Fix：W3C traceparent 全链路透传。^[extracted]

## 相关页面

- [[concepts/agent-observability-paradigm]] — 范式转变的背景
- [[concepts/evaluation-driven-development]] — 评估驱动的迭代方法论
- [[concepts/agent-online-evaluation]] — 在线评估体系
- [[concepts/agent-data-flywheel]] — 数据飞轮闭环
- [[concepts/genai-observability-semconv]] — OTel GenAI 语义约定详解
- [[entities/litefuse]] — Litefuse 的三合一实现
- [[entities/langfuse-llm-observability]] — Langfuse 的 trace + eval 功能
