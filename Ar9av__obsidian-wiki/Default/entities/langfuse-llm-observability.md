---
title: Langfuse LLM Observability
aliases:
  - Langfuse
  - Langfuse LLM Observability Platform
category: entities
tags:
  - ai-agent
  - observability
  - evaluation
  - open-source
  - llm
sources:
  - "Git 拆解: Langfuse 实战：部署、埋点、评估，跑通 LLM 可观测全流程 (2026-06-28)"
  - "IMBoy技术笔记: 可观测性：Langfuse、Langsmith 集成 (2026-07-03)"
  - "程序猿架构之路: AI可观测性-Trace-Cost-质量三合一 (2026-07-01)"
  - "南哥聊技术: Langfuse部署实战：搭建 Agent 可观测平台 (2026-06-08)"
  - "ThinkingAgent: AI安全和治理 (2026-06-28)"
  - "叶小钗: Agent 可观测性：为什么有了 LangChain，还会出现 Langfuse？ (2026-06-10)"
  - "ThinkingAgent: AI可观测性：Prompt、Tool Call、Trace、Token全链路追踪 (2026-06-22)"
summary: Langfuse 是目前最成熟的开源 LLM 可观测平台（28.5K Star），提供 Trace 可视化、Prompt 版本管理、数据集评估、Playground 调试环境等核心能力，支持自托管（Docker Compose / Helm / Terraform）和 SaaS Cloud 部署。基于 ClickHouse+PostgreSQL 双数据库架构。
provenance:
  extracted: 0.65
  inferred: 0.25
  ambiguous: 0.10
base_confidence: 0.73
lifecycle: draft
lifecycle_changed: 2026-07-16
tier: core
created: 2026-07-16T00:00:00+08:00
updated: 2026-07-16T12:00:00+08:00
relationships:
  - target: "[[concepts/ai-agent-observability]]"
    type: implements
  - target: "[[concepts/agent-trace-and-timeline]]"
    type: implements
  - target: "[[entities/litefuse]]"
    type: related_to
  - target: "[[concepts/agent-trace-cost-quality-architecture]]"
    type: implements
  - target: "[[skills/langfuse-integration-patterns]]"
    type: related_to
  - target: "[[entities/ai-observe-stack]]"
    type: related_to
  - target: "[[entities/loongsuite-platform]]"
    type: related_to
---

# Langfuse LLM Observability

**Langfuse** 是目前最成熟的开源 LLM 可观测平台（v3.178.0，28.5K Star，月均 200+ commits），从 tracing 到评估到 Prompt 版本管理，整套工作流都闭合。

- **GitHub**：https://github.com/langfuse/langfuse
- **协议**：MIT（核心），EE 目录下为企业功能（SSO、RBAC、审计日志）
- **部署**：自托管（Docker Compose / Helm Chart / Terraform）或 SaaS Cloud

## 与 LangChain 的关系

Langfuse 和 LangChain 没有组织关系——Langfuse 不是 LangChain 公司的产品。两者的分工是：

- **LangChain** 是 Agent 开发框架（解决"如何构建 Agent"）
- **Langfuse** 是 LLM 可观测平台（解决"如何查看 Agent 行为"）

LangChain 公司自身的可观测产品是 **LangSmith**（商业产品）。

## 架构与部署

### 自托管架构

Docker Compose 一键启动 6 个服务。关键坑点：容器内互访用 Compose 服务名（如 `http://minio:9000`），外部访问用宿主机 IP 和映射端口——混用是部署中最常见的错误。内部组件（ClickHouse、Redis）建议绑定 `127.0.0.1` 或不对外暴露：

- **Web**：Next.js 应用，提供 UI
- **Worker**：队列消费者，处理异步任务
- **PostgreSQL**：元数据存储（用户、项目、配置）
- **ClickHouse**：Trace 数据分析引擎（OLAP）
- **Redis**：消息队列
- **MinIO**：S3 兼容对象存储

关键配置项：`DATABASE_URL`（PG 连接串）、`CLICKHOUSE_URL`（CK HTTP 地址）、`SALT` + `ENCRYPTION_KEY`（API Key 加密，用 `openssl rand -hex 32` 生成）、`REDIS_HOST`/`REDIS_AUTH`。

生产环境推荐 Helm Chart 部署到 Kubernetes，或用 Terraform 模板一键拉起 AWS/Azure/GCP 基础设施。

### 最低资源

自托管最低建议 4C8G 内存，需要维护两个数据库。SDK 异步上报：trace 数据先写本地内存队列，批量异步发送，网络中断时自动缓存、恢复后重传。

### 部署方式对比

| 方式 | 适用场景 |
|------|---------|
| Cloud（官方托管） | 快速试用，有免费额度，数据上传到云端 |
| Self-Hosted（Docker） | 生产环境，数据保留在自有基础设施内 |
| Helm Chart（Kubernetes） | 大规模生产部署，自动扩缩容 |
| Terraform | 一键拉起 AWS/Azure/GCP 基础设施 |

## 核心功能

### 1. 埋点 Tracing

四种埋点方式：

**OpenAI Drop-in 替换**（最快）：改一行 import，所有 `client.chat.completions.create()` 调用自动上报。

```python
# from openai import OpenAI  → 替换为
from langfuse.openai import OpenAI
client = OpenAI()
```

**装饰器 `@observe()`**：用于 RAG pipeline、Agent 链等自定义逻辑，每个被装饰的函数成为 trace 中的一个 span，嵌套调用自动形成父子关系。

**框架自动集成**：LangChain 通过 CallbackHandler、LlamaIndex 通过 callback manager、Vercel AI SDK、Haystack、DSPy、Mirascope 等均可集成。

**Context Manager**：精确控制 Span 边界。

```python
from langfuse import Langfuse
langfuse = Langfuse()

with langfuse.start_span(name="tool_call", metadata={"tool": "search"}) as span:
    result = search_api.query(query)
    span.update(output=result)
```

### 2. 评估系统

支持三种评估方式：

- **LLM-as-a-Judge**：让另一个 LLM 按评分 prompt 模板对输出打分（faithfulness、简洁性等）
- **Code Evaluator**：自定义 Python 函数做精确评估（关键词检测、格式验证）
- **人工标注**：手动打分 + 标注队列

### 3. Prompt 版本管理

把 Prompt 当作代码管理：
- 版本控制：每次修改自动生成新版本，可回滚
- 标签系统：`production` / `staging` / `draft`
- 服务端缓存：SDK 自动拉取最新版本，客户端无需重新部署
- Playground 联动：Trace 面板看到不好的输出，一键跳到 Playground 迭代

### 4. Datasets + Experiments

Dataset 是一组测试用例（输入 + 期望输出），Experiment 是在 Dataset 上跑评估的实验——对 LLM 应用做 CI/CD。

流程：改 Prompt → 跑一轮 experiment → 分数下降则回滚，上升则推到 production。

### 5. MCP Server

Langfuse v3 新增内置 MCP Server，Claude Code、Cursor 等 AI Agent 可以直接查询 Langfuse 数据（如"帮我查今天 error 率最高的 5 条 trace"）。

### 6. 成本追踪

按模型、用户、Session 维度聚合 Token 消耗和 API 费用，支持成本预算告警。

### 7. Eino Callback Handler 集成

云计算框架 CloudWeGo 的 Eino 通过 `callbacks.Handler` 接口实现了与 Langfuse 的深度集成：

- `NewLangfuseHandler(cfg)` + `defer flusher()` 即可接入
- ChatModel 节点自动上报为 Generation（带 token 用量），其他节点上报为 Span
- 流式响应在 goroutine 中收集完所有 chunks 后再上报完整 completion
- `SetTrace(ctx, ...)` 在请求级别覆盖 userID、sessionID、tags、release
- 支持批量异步上报（可配置线程数、缓冲区大小、刷新间隔）

**节点映射规则**：

| Eino 节点类型 | Langfuse 对象 | 额外信息 |
|--------------|--------------|---------|
| `ComponentOfChatModel` | **Generation** | model name、params、prompt messages、completion、token 用量 |
| 其他节点（Lambda、Tool） | **Span** | 输入输出 JSON、耗时 |

## 选型指南

在企业级 AI 可观测栈中，Langfuse 的定位是：
- **主栈**：做 trace + dataset + 在线 eval
- **搭配**：Prometheus 抓 vLLM TTFT/TPOT/GPU；LiteLLM spend_logs 对账云账单；Phoenix 周度 RAG 漂移分析

与 DeepFlux OTel 的分工：OTel 负责 SLO 监控和告警（基础设施视角），Langfuse 负责 Prompt 质量分析和 session 回放（业务视角）。两者不冲突，可同时运行。

## 生态定位

| 对比对象 | 关系 |
|---------|------|
| **vs. LangSmith** | LangSmith 是 LangChain 的商业产品，Langfuse 是独立开源方案 |
| **vs. LoongSuite** | [[entities/loongsuite-platform|LoongSuite]] 偏采集层，Langfuse 偏可视化与评估层；两者可通过 OTel 对接 |
| **vs. AI Observe Stack** | [[entities/ai-observe-stack|AI Observe Stack]] 是存储后端，Langfuse 可以作为其上层消费端之一 |

## 相关页面

- [[entities/litefuse]] — 基于 Doris 的 Langfuse 替代/优化方案
- [[concepts/agent-trace-cost-quality-architecture]] — Langfuse 在其中扮演的角色
- [[skills/langfuse-integration-patterns]] — 实际埋点代码模式
- [[concepts/evaluation-driven-development]] — Langfuse 支持的评估驱动方法论
- [[concepts/ai-agent-observability]] — AI Agent 可观测性整体概念
- [[concepts/agent-trace-and-timeline]] — Agent Trace 数据结构
