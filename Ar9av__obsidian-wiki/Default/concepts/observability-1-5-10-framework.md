---
title: Observability 1-5-10 Framework
category: concepts
tags:
  - observability
  - sre
  - slo
  - alibaba
  - agent
relationships:
  - target: "[[entities/dify]]"
    type: related_to
sources:
  - "Pub: 阿里技术, 大模型可观测1-5-10：发现、定位、恢复的三层能力建设 (2025-09-21)"
summary: 阿里云提出的企业级 SLO 驱动可观测框架：1 分钟发现问题、5 分钟定位根因、10 分钟恢复服务，通过日志标准化、监控告警、分析诊断三层能力逐级建设将可观测从"能看"提升到"能救"。
provenance:
  extracted: 0.70
  inferred: 0.25
  ambiguous: 0.05
base_confidence: 0.55
lifecycle: draft
lifecycle_changed: "2026-07-24"
tier: supporting
created: 2026-07-24T00:00:00+08:00
updated: 2026-07-24T00:00:00+08:00
---

# Observability 1-5-10 Framework

**1-5-10** 是阿里云针对大模型应用提出的可观测性 SLO（Service Level Objective）框架：**1 分钟发现问题、5 分钟定位根因、10 分钟恢复服务**。它不仅仅是时间指标，更是一套从底层日志采集到顶层智能诊断的分层能力建设方法论。

## 核心定义

| 阶段 | 时间 | 目标 | 依赖能力 |
|------|------|------|---------|
| **发现** | ≤1 min | 感知异常发生，触发告警 | 指标采集 → 实时大盘 → 阈值/基线告警 |
| **定位** | ≤5 min | 从告警下钻到具体根因（模型/链路/参数）^[extracted] | 链路追踪 → 领域化视图 → 多维分析（应用/模型/地域/错误码）|
| **恢复** | ≤10 min | 止损并修复，恢复业务可用 ^[extracted] | 根因诊断 → 降级/切换策略 → 复盘闭环 |

该框架的核心洞见：**建设节奏不必追求一步到位，而应按能力层逐级递进**——先从"有日志可查"做到"有告警可看"，再逐步建设到"能快速诊断恢复"。

## 三层能力建设

### L1：日志采集与标准化

所有可观测能力的基础。需要约定统一的日志格式，将关键字段结构化。

**百炼（阿里云大模型服务平台）日志规范**：^[extracted]

```
bailian-log,<app>,<module>,<model>,<workspace>,<requestId>,<statusCode>,<totalTokens>,<inputTokens>,<outputTokens>,<cost>,<errorMsg>
```

字段含义：应用名称、模块、模型名、工作空间、请求 ID、HTTP 状态码、Token 总量、输入/输出 Token 数、费用、错误信息。

**核心原则**：^[inferred]
- **结构化优先**：日志字段以逗号分隔，便于正则解析到 SLS/ARMS
- **关键字段必采**：app、model、requestId、statusCode、tokens 是最小可诊断集合
- **关联 ID 不透传丢失**：traceId 和 requestId 必须在每行日志中携带

### L2：监控大盘与告警

在日志标准化基础上，构建领域化监控指标体系。

**核心指标** ^[extracted]：
- **模型调用量**：QPS / 分钟调用次数
- **Token 消耗**：输入/输出 Token 数、费用
- **延迟分布**：P50/P95/P99、TTFT（首 Token 延迟）
- **错误码分布**：4xx / 5xx 细分，限流错误、鉴权失败、超时
- **成功率**：以业务语义定义（非 HTTP 200 = 成功）^[inferred]

**核心模型水位监控** ^[extracted]：

不同模型有不同的限流阈值，需建立**秒粒度**水位监控（而非 1 分钟聚合粒度），原因是：
- 模型限流通常按秒计算——秒级毛刺（如秒杀流量、用户突发密集访问）可能在 1 分钟级别被平滑掉
- 实际定位场景：11:45:41 秒出现限流峰值，1 分钟粒度看到的是正常曲线

> 告警阈值应设置在模型限流值的 70%-80%，给弹性扩容留出缓冲时间。

### L3：分析诊断与恢复

在发现问题的基础上，下钻定位根因。

**多维下钻维度** ^[extracted]：
- 按**应用**：哪个应用触发（[[entities/dify|Dify]] 应用 / 自建 Agent / API 直调）
- 按**模型**：哪个模型实例（qwen-plus / deepseek-chat / 自定义模型）
- 按**地域**：哪个 Region / AZ
- 按**错误码**：限流 / 超时 / 鉴权 / 模型内部错误
- 按**用户**：是否集中在特定用户/租户

**诊断工具链** ^[inferred]：
1. 告警触发 → 告警详情页（模型、错误码、时间窗口）
2. 下钻至链路追踪 → 定位具体失败 Span
3. 结合日志上下文 → 还原完整请求链路
4. 关联模型服务端指标 → 排除/确认推理层问题

## 与传统 SRE SLO 的差异

| 维度 | 传统 SRE（Google SRE） | 1-5-10 框架 |
|------|----------------------|-------------|
| 监控对象 | 微服务延迟、错误率 | 模型推理、Token 消耗、语义正确性 |
| 故障模型 | 服务宕机、依赖超时 | 模型幻觉、限流、输出格式错误、Token 黑洞 |
| 数据粒度 | 请求级 | Token 级 → 请求级 → 会话级（三级）^[inferred] |
| 恢复手段 | 回滚、切流、扩容 | 模型切换、降级提示、参数调整、Prompt 修复 ^[inferred] |

## 工程落地路径

基于 1-5-10 框架的渐进式建设路线 ^[inferred]：

1. **Week 1-2**：日志标准化——统一日志格式，接入 SLS/ARMS，确保关键字段齐全
2. **Week 3-4**：指标大盘——构建模型维度的 QPS/Token/延迟/错误率大盘，设置阈值告警
3. **Month 2**：链路追踪——接入 OpenTelemetry，实现 LLM Span 自动采集，打通端到端调用链
4. **Month 3**：多维分析——建立应用×模型×地域×错误码的下钻能力
5. **Month 4+**：智能诊断——通过 AI 辅助根因分析（结合日志+链路+模型服务端信号）

## 与其他可观测框架的关系

- [[concepts/ai-agent-observability]]：1-5-10 是 AI Agent 可观测性在生产运维层面（SRE 视角）的量化落地
- [[concepts/agent-trace-cost-quality-architecture]]：定位阶段的"5 分钟"依赖 Trace-Cost-Quality 三合一架构的实时关联查询能力
- [[concepts/genai-observability-semconv]]：1-5-10 框架中的标准化日志字段，与 OTel GenAI SemConv 的 `gen_ai.*` 属性命名规范互补 ^[inferred]
- [[entities/alicloud-cloudmonitor-ai-agent-observability]]：云监控 AI Agent 可观测产品的故障定位时间线（T+0s → T+10s → T+30s → T+60s → T+90s）是 1-5-10 在具体产品中的落地实现

## Related

- [[concepts/agent-observability-metrics]] — Agent 可观测性指标体系的 SLO 驱动设计
- [[concepts/ai-agent-observability]] — 核心范式
- [[entities/alicloud-cloudmonitor-ai-agent-observability]] — 阿里云云监控 AI Agent 可观测产品
- [[references/caict-llm-observability-standard]] — 中国信通院 LLM 可观测性能力分级标准
