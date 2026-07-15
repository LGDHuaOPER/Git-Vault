---
title: "AgentTrace"
category: entities
tags:
  - ai-agent
  - observability
  - trace
  - research
sources:
  - "Agentic AI研习社: AgentTrace：给LLM智能体装上行车记录仪 (2026-06-13)"
summary: "UC Berkeley 提出的 LLM Agent 三层结构化追踪框架——操作面（做了什么）、认知面（为什么这样做）、上下文面（与外部世界的交互）——统一为一个共享信封 Schema。"
base_confidence: 0.55
lifecycle: draft
lifecycle_changed: "2026-07-16"
tier: supporting
provenance:
  extracted: 0.55
  inferred: 0.35
  ambiguous: 0.10
created: "2026-07-16"
updated: "2026-07-16"
relationships:
  - target: "[[agent-observability-paradigm]]"
    type: extends
  - target: "[[agent-trace-cost-quality-architecture]]"
    type: extends
---

# AgentTrace

**AgentTrace** 是 UC Berkeley 研究者提出的 LLM Agent 可观测性框架，核心理念：**把日志从调试工具升级为一等公民的基础设施层**——像数据库有 WAL、微服务有分布式追踪一样，Agent 也应该有自己结构化的 Trace。^[extracted]

- **论文**：https://arxiv.org/pdf/2602.10133
- **定位**：Agent 可观测性的基础层（foundational layer）
- **核心贡献**：将 Agent 运行时拆成三个"面"（Surface），每个面管一类信息

## 三面架构

### 1. 操作面（Operational Surface）

回答 **"谁调了谁，花了多久"**。^[extracted]

- 通过 Python 装饰器注入，运行时自动拦截 Agent 类上的所有公共方法
- 每次方法调用产生一对事件：`start` 和 `complete`
- 记录方法名、参数摘要、返回类型、耗时
- 同时写入本地 JSONL 和 OpenTelemetry Span
- **本质上是把分布式追踪（Dapper/Jaeger）的理念压到单个 Agent 粒度**

### 2. 认知面（Cognitive Surface）

回答 **"它当时到底在想什么"**——这是整个框架最有意思的地方。^[extracted]

捕获内容：
- 原始 Prompt 和 LLM 返回的 Completion
- 推理链（Chain-of-Thought 的每一步）
- 置信度估计
- `<thinking>` 标签内的内容和结构化 JSON 字段（`plan`、`reflection` 等）

提取策略：**标记检测 + XML 标签解析 + JSON 字段提取**，不绑定特定模型或 Prompt 格式。^[extracted]

关键设计：**认知 Span 嵌套在操作 Span 里**。从"Agent 调了一个 API"一层层展开，能看到它当时想了什么才决定调这个 API。^[extracted]

### 3. 上下文面（Contextual Surface）

回答 **"它与外部世界的一切交互"**。^[extracted]

追踪所有向外 I/O：HTTP 请求、SQL/NoSQL 查询、Redis 缓存操作、向量数据库访问、文件系统读写。

实现借力 OpenTelemetry 的自动检测能力，通过 monkey-patch `requests`、`sqlalchemy`、`redis` 等标准库。

**这层桥接了"想"和"做"**——一个内部推理决定，什么时候变成了外部查询，中间花了多久。^[extracted]

## 共享信封

三层日志事件套在统一结构里 ^[extracted]：

```
uuid
surface: cognitive | operational | contextual
trace_id, span_id
timestamp (UTC)
event_body (per-surface)
```

存储两份：JSONL 给离线分析和回放，OTel Span 给实时追踪和 Jaeger/Tempo 可视化。写入时做 Schema 校验，追加写入，导出失败不影响执行。

## 装饰器注入实现

五个步骤，工程上相当务实 ^[extracted]：

1. 给每个目标方法创建保留签名的 wrapper
2. 调用前生成 Trace/Span ID，记录 start 事件
3. 执行原函数，过程中尝试提取认知内容
4. 成功返回后记录 complete 事件（耗时、结果摘要）
5. 异常时记录 error 事件，原样 re-raise

特点：非侵入（不碰业务代码）、低开销（每次调用只产生两个事件）、可组合。

## 开放问题

论文自身承认的局限 ^[inferred]：

1. **认知面深度不够**：当前靠标记解析（XML 标签、JSON 字段），复杂推理散在多轮对话里时难以捕获更细粒度的"推理微步"
2. **Schema 统一**：三面分类和共享信封是好起点，但需要社区共识才能成为像 OTel 的行业标准
3. **隐私**：认知面捕获的 Prompt 和推理链可能夹着用户敏感数据，论文将 Privacy/Redaction 标为 future work

## 相关页面

- [[agent-observability-paradigm]] — AgentTrace 试图解决的"黑盒"问题
- [[agent-trace-cost-quality-architecture]] — 与之互补的生产级三合一架构
- [[opentelemetry-genai-semconv]] — OTel GenAI 语义约定——AgentTrace 的 OTel Span 部分依赖的标准
