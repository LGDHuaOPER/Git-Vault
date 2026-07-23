---
title: AI Agent 可观测性：看不见的链路，才是最贵的技术债
category: references
tags:
  - ai-agent
  - observability
  - slo
  - metrics
  - rag
sources:
  - "祥聊AI: AI Agent 可观测性：看不见的链路，才是最贵的技术债 (2026-04-12)"
summary: 祥聊AI 从工程实践角度提出 Agent 可观测应沿请求链路在任务/会话、Agent 编排、工具/MCP、RAG 检索、LLM 调用五个节点埋观测点，并以 SLO 驱动四组核心指标。
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
  - target: "[[concepts/agent-observability-metrics]]"
    type: related_to
  - target: "[[concepts/rag-observability]]"
    type: related_to
  - target: "[[entities/arize-phoenix]]"
    type: related_to
  - target: "[[entities/langfuse-llm-observability]]"
    type: related_to
---

# AI [[concepts/ai-agent-observability|Agent 可观测性]]：看不见的链路，才是最贵的技术债

> 原文：AI Agent 可观测性：看不见的链路，才是最贵的技术债（祥聊AI，2026-04-12）

## 核心观点

很多团队反复换模型、堆提示词、调参数但效果不稳定，核心问题往往不是模型本身，而是**看不见 Agent 怎么完成任务**。看不见就没法诊断，只能凭猜测优化。

## 症状与误判

典型症状：任务完成率忽高忽低、同一类任务昨天能今天又不行、复杂任务中间卡住或跑偏、成本越来越高但效果没提升。

常见误判对照：

| 表面现象 | 常见第一反应 | 更可能的根因 |
|---------|-------------|-------------|
| 回答质量一般 | 模型不够强 | 上游数据错了，或 RAG 检索没命中 |
| 任务很慢 | 模型推理慢 | 某步重复执行、工具调用卡住、循环过多 |
| 任务失败 | 提示词不够细 | 工具超时、权限拒绝、外部 API 异常 |
| 成本飙升 | 模型太贵 | 上下文膨胀、失败后反复重试、无效循环 |
| 表现不稳定 | 模型随机性 | 特定步骤系统性失稳，或依赖服务波动 |

## 链路视角的五个观测节点

沿 Agent 处理一次任务的链路埋观测点：

```
用户请求 → Gateway → Engine → Tool/MCP → RAG 检索 → LLM 调用 → 结果聚合 → 响应用户
```

| 观测节点 | 核心问题 | 关键信号 |
|---------|---------|---------|
| 任务/会话 | 有没有完成？用户是否接受？ | 成功率、人工接管率、业务达成率 |
| Agent 编排 | 执行了几步？在哪一步偏了？ | 步骤数、重试次数、循环次数、步骤失败分布 |
| 工具/MCP | 工具调到了吗？结果对吗？ | 调用耗时、错误率、超时率、退出码 |
| RAG 检索 | 找到了吗？找对了吗？ | 召回率、命中率、检索延迟、重排质量 |
| LLM 调用 | 快不快？贵不贵？有没有拒答？ | 延迟 P50/P95/P99、token 量、成本、拒答率、截断率 |

## 为什么 RAG 层必须单独看

大量 Agent 输出质量差的根因在输入给模型的上下文就是错的：检索没命中、召回排序不对、知识库过期。这些问题换再贵的模型也解决不了。需要观测：检索输入、召回结果、重排结果、引用片段。

## SLO 驱动的四组核心指标

没有 SLO，监控只是"看数字"。建议先盯住四组指标：

**结果指标**：任务成功率、人工接管率、业务结果达成率
**过程指标**：步骤失败分布、重试/循环次数、MCP 调用错误率（按系统拆分）
**成本指标**：单任务平均 token 消耗、失败任务的 token 浪费、模型调用成本（按租户/Agent 拆分）
**质量指标**：RAG 检索命中率、LLM 拒答率/截断率、延迟 P50/P95/P99

## 分阶段建设路径

- **阶段一（1-2 周）结果可见性**：采集 task_started/finished/failed，看清成功率、失败率、人工接管率、基础成本。
- **阶段二（2-4 周）过程可见性**：接入 OpenTelemetry，补齐 step/tool/llm 事件，接入 [[entities/langfuse-llm-observability|Langfuse]] 和 Phoenix。
- **阶段三（持续）治理自动化**：定义 SLO、自动降级、模型路由、自动转人工、离线评估回归。

## 工具组合建议

| 观测域 | 组件 |
|--------|------|
| LLM Trace 与成本 | Langfuse |
| RAG 调试与评估 | [[entities/arize-phoenix|Arize Phoenix]] |
| 分布式追踪 | OpenTelemetry |
| 指标与告警 | Prometheus + Alertmanager |
| 看板 | Grafana |
