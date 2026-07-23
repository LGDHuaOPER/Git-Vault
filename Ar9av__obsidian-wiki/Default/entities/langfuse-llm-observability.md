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
  - "FutureCraft AI: 第12篇：Agent 可观测性——看见你的 Agent 在想什么 (2026-06-02)"
  - "ThinkingAgent: AI安全和治理 (2026-06-28)"
  - "叶小钗: Agent 可观测性：为什么有了 LangChain，还会出现 Langfuse？ (2026-06-10)"
  - "AI应用笔记本: 测 AI 智能体总靠瞎猜？LangFuse 搞定 99% 大模型应用观测与评估难题 (2026-06-24)"
  - "ThinkingAgent: AI可观测性：Prompt、Tool Call、Trace、Token全链路追踪 (2026-06-22)"
summary: Langfuse 是目前最成熟的开源 LLM 可观测平台（约 29K Star，月 SDK 安装超 5000 万次），提供 Trace 可视化、Prompt 版本管理、数据集评估、Playground 调试环境等核心能力，支持自托管与 SaaS，被 63 家财富 500 强企业采用。
provenance:
  extracted: 0.70
  inferred: 0.23
  ambiguous: 0.07
base_confidence: 0.75
lifecycle: draft
lifecycle_changed: 2026-07-16
tier: core
created: 2026-07-16T00:00:00+08:00
updated: "2026-07-22"
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
  - target: "[[entities/dify]]"
    type: related_to
  - target: "[[entities/langsmith]]"
    type: related_to
  - target: "[[entities/vllm]]"
    type: related_to
  - target: "[[references/2026-04-27-langfuse-lifecycle-observability]]"
    type: related_to
  - target: "[[references/langfuse-deployment-practice]]"
    type: related_to
  - target: "[[skills/langfuse-self-hosting]]"
    type: related_to
---

# Langfuse LLM Observability

**Langfuse** 是目前最成熟的开源 LLM 可观测平台（v3.178.0，约 29K Star，月均 200+ commits，月 SDK 安装超 5000 万次），已被 63 家财富 500 强企业采用。^[extracted] 它整合了可观测性、提示词管理、评估与实验四大能力，从 tracing 到评估到 Prompt 版本管理形成完整工程闭环。^[extracted]

- **GitHub**：https://github.com/langfuse/langfuse
- **协议**：MIT（核心），EE 目录下为企业功能（SSO、RBAC、审计日志）
- **部署**：自托管（Docker Compose / Helm Chart / Terraform）或 SaaS Cloud

## 与 LangChain 的关系

Langfuse 和 LangChain 没有组织关系——Langfuse 不是 LangChain 公司的产品。两者的分工是：

- **LangChain** 是 Agent 开发框架（解决"如何构建 Agent"）
- **Langfuse** 是 LLM 可观测平台（解决"如何查看 Agent 行为"）

LangChain 公司自身的可观测产品是 **[[entities/langsmith|LangSmith]]**（商业产品）。

## 架构与部署

### 自托管架构

Docker Compose 一键启动 6 个服务。关键坑点：容器内互访用 Compose 服务名（如 `http://minio:9000`），外部访问用宿主机 IP 和映射端口——混用是部署中最常见的错误。内部组件（ClickHouse、Redis）建议绑定 `127.0.0.1` 或不对外暴露：

- **Web**：Next.js 应用，提供 UI
- **Worker**：队列消费者，处理异步任务
- **PostgreSQL**：元数据存储（用户、项目、配置）
- **ClickHouse**：Trace 数据分析引擎（OLAP）
- **Redis**：消息队列
- **MinIO**：S3 兼容对象存储

关键配置项：
- `DATABASE_URL` / `DIRECT_URL`（PG 连接串，建议 UTC 时区）
- `CLICKHOUSE_MIGRATION_URL` / `CLICKHOUSE_URL`（CK 地址，容器内用服务名）
- `NEXTAUTH_URL`、`NEXTAUTH_SECRET`、`SALT`
- `ENCRYPTION_KEY`（64 位十六进制，用 `openssl rand -hex 32` 生成）
- `REDIS_HOST` / `REDIS_AUTH`（建议 Redis 7 + `noeviction`）
- S3/MinIO 三组变量：event upload、media upload、batch export，注意区分容器内 endpoint 和外部 endpoint

ClickHouse 使用 `user: "101:101"`，宿主机挂载目录需 `chown -R 101:101`。必须手动创建名为 `langfuse` 的 MinIO bucket，否则事件上传和导出会失败。

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

### Trace 中的 Observation 类型

Langfuse 把 Trace 下的每个步骤称为 **Observation**，常见类型包括 ^[extracted]：

| 类型 | 含义 |
|------|------|
| **SPAN** | 普通业务步骤 |
| **GENERATION** | 一次 LLM 生成（模型调用） |
| **TOOL** | 一次工具调用 |
| **RETRIEVER** | 一次检索 |
| **CHAIN** | 链式调用 |
| **AGENT** | Agent 节点 |
| **EVENT** | 一个事件点 |
| **EVALUATOR** | 评估节点 |
| **EMBEDDING** | Embedding 调用 |
| **GUARDRAIL** | 安全或规则检查 |

一次完整的 Agent Trace 可能包含用户提问、模型推理、RAG 检索与重排、工具执行输入输出等多个 Observation。^[extracted]

### 2. 评估系统

Langfuse 的评估系统围绕 **Score** 展开。Score 是所有质量信号的统一载体，可以来自用户反馈、业务系统、自动评估器或人工标注。^[extracted]

**Score 可以挂载的对象** ^[extracted]：

- Trace：评价一次完整交互
- Observation：评价某个模型调用、工具调用或检索步骤
- Session：评价一段多轮会话
- Dataset Run：评价一次实验运行

**Score 类型** ^[extracted]：

| 类型 | 示例 |
|------|------|
| Numeric | 0.87、4、0.0-1.0 |
| Categorical | good、bad、partially_correct |
| Boolean | true / false |
| Text | 人工评论、纠错答案、失败原因 |

**评估方式**：

- **LLM-as-a-Judge**：让另一个 LLM 按评分 prompt 模板对输出打分（faithfulness、简洁性、helpfulness 等）^[extracted]
- **Code Evaluator**：自定义 Python/TypeScript 函数做精确评估（关键词检测、格式验证、JSON Schema 校验）^[extracted]
- **UI 手动评分**：在界面上直接给 Trace 打分，适合小批量快速抽查^[extracted]
- **人工标注队列（Annotation Queue）**：结构化人工审核工作流，分配审核任务，适合高风险输出需人工二次把关的场景^[extracted]

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

Langfuse v3 新增内置 MCP Server，Claude Code、Cursor 等 AI Agent 可以直接查询 Langfuse 数据（如"帮我查今天 error 率最高的 5 条 trace"）。^[extracted]

配置方式：^[extracted]

```bash
# 生成 Basic Auth token
echo -n "pk-lf-xxx:sk-lf-xxx" | base64

# 添加 MCP server
claude mcp add --transport http langfuse \
  http://localhost:3000/api/public/mcp \
  --header "Authorization: Basic {base64-token}"
```

配置好后，AI Agent 通过 MCP 调用 Langfuse API 返回数据，不需要打开 UI 逐条翻。^[extracted]

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

### 8. AI Coding Tool 集成（Langfuse Skills）

Langfuse 提供官方 **Skills** 仓库（https://github.com/langfuse/skills），让 AI Coding Agent（如 Codex、Claude Code）可以自动把项目接入 Langfuse。^[extracted] 典型用法是直接把下面提示词丢给 Agent：^[extracted]

```
Read https://litefuse.ai/SKILL.md and follow the instructions to install and configure Litefuse.
```

实际接入时，Agent 通常会在原有执行链路的关键节点上增加 trace、generation、tool span，而不会破坏原有执行流程。^[extracted] 一个常见的改造模式是：

1. 新增统一的 Langfuse Service，集中管理 client、tracing、prompt、score、flush 等逻辑
2. 每次真实请求大模型时生成 generation 记录（模型、输入、输出、tool calls、token usage）
3. 每次工具调用记录 tool span（工具名、参数、返回结果、耗时）
4. 用 traceId 把一次完整聊天请求中的模型调用和工具执行串起来
5. 把系统提示词抽象成 Langfuse prompt，运行时优先读取 production 版本，失败则回退到本地模板

> ⚠️ 接入后如果 cost 一直显示为 0，常见原因是 SDK 同步时没有把模型接口返回的 usage 一起上报。修复方式是在 SDK 调用处把 token 消耗同步给 Langfuse。^[extracted]

## 框架与部署支持

Langfuse 对主流 LLM 框架和部署方式都有原生支持 ^[extracted]：

| 类型 | 支持范围 |
|------|---------|
| **Agent 框架** | LangChain、LangGraph、OpenAI Agents SDK、CrewAI、Pydantic AI、[[entities/dify|Dify]] |
| **模型 SDK** | OpenAI SDK、Anthropic SDK、LlamaIndex、Vercel AI SDK、Haystack、DSPy、Mirascope |
| **部署方式** | Cloud（免费 Hobby）、自托管（Docker Compose 一行命令）、企业版 |
| **数据标准** | 基于 OpenTelemetry，避免厂商锁定 |

追踪数据的采集是异步的，批量上报，不会给应用增加响应时延。^[extracted]

## 对 AI 智能体测试的三个价值

Langfuse 覆盖智能体测试的完整周期 ^[extracted]：

| 阶段 | 核心能力 | 解决的问题 |
|------|---------|-----------|
| **上线前** | 离线评估 + 数据集实验 | 改了提示词 / 换了模型，量化对比质量变化，防止退化 |
| **上线后** | 在线评估 + 实时监控 | 成本、延迟、输出质量三指标持续监控，问题实时发现 |
| **问题定位** | 全链路追踪 + 时间线视图 | Agent 出问题精确到节点，不用猜是哪个环节出错 |

## 选型指南

在企业级 AI 可观测栈中，Langfuse 的定位是：
- **主栈**：做 trace + dataset + 在线 eval
- **搭配**：Prometheus 抓 [[entities/vllm|vLLM]] TTFT/TPOT/GPU；LiteLLM spend_logs 对账云账单；Phoenix 周度 RAG 漂移分析

与 DeepFlux OTel 的分工：OTel 负责 SLO 监控和告警（基础设施视角），Langfuse 负责 Prompt 质量分析和 session 回放（业务视角）。两者不冲突，可同时运行。

## 与 LangSmith 的对比

从 Eino 框架接入视角，Langfuse 与 LangSmith 的关键差异 ^[extracted]：

| 维度 | Langfuse | LangSmith |
|------|----------|-----------|
| 协议 | MIT 开源，数据自有 | SDK 开源，平台闭源 |
| 集成 | OTel 一等公民，生态最广 | LangChain 一等公民，深度集成 |
| 功能 | trace + eval + prompt hub | trace + eval + prompt hub |
| 成本 | 自托管需 ClickHouse 集群 | 量大后单价贵 |
| UI | 略糙 | 更强 |

LangSmith 的优势在于 LangChain 原生集成和回放/分支能力；Langfuse 的优势在于真正开源、数据自有、OTel 原生。

## 生态定位

| 对比对象 | 关系 |
|---------|------|
| **vs. LangSmith** | LangSmith 是 LangChain 的商业产品，Langfuse 是独立开源方案 |
| **vs. LoongSuite** | [[entities/loongsuite-platform|LoongSuite]] 偏采集层，Langfuse 偏可视化与评估层；两者可通过 OTel 对接 |
| **vs. AI Observe Stack** | [[entities/ai-observe-stack|AI Observe Stack]] 是存储后端，Langfuse 可以作为其上层消费端之一 |
| **vs. GreptimeDB** | [[entities/greptimedb|GreptimeDB]] 是统一可观测性数据库（存储层），Langfuse 是 LLM 工程平台（应用层）；两者可互补 |
| **vs. Arize Phoenix** | [[entities/arize-phoenix|Phoenix]] 是 OTel 原生开源平台，RAG 分析更强；Langfuse 是更完整的 LLM 工程闭环 |

## 相关页面

- [[entities/litefuse]] — 基于 Doris 的 Langfuse 替代/优化方案
- [[concepts/agent-trace-cost-quality-architecture]] — Langfuse 在其中扮演的角色
- [[skills/langfuse-integration-patterns]] — 实际埋点代码模式
- [[concepts/evaluation-driven-development]] — Langfuse 支持的评估驱动方法论
- [[concepts/ai-agent-observability]] — AI Agent 可观测性整体概念
- [[concepts/agent-trace-and-timeline]] — Agent Trace 数据结构
- [[entities/greptimedb]] — 统一可观测性数据库（互补存储层）
- [[entities/arize-phoenix]] — OTel 原生开源可观测平台
- [[references/spring-ai-otel-langfuse]] — Spring AI + OTel + Langfuse 生产级方案
- [[synthesis/genai-observability-semconv-x-langfuse-llm-observability]] — synthesis: standard vs product — the gap between SemConv telemetry and Langfuse workflow
- [[synthesis/ai-agent-observability-x-langfuse-llm-observability]] — synthesis: theory vs implementation — the framework's six failure categories vs Langfuse's three trace statuses
- [[synthesis/llm-as-judge-evaluation-x-langfuse-llm-observability]] — synthesis: evaluation-observability loop — trace data feeds the Judge, but the wiring is manual
- [[references/2026-04-27-langfuse-lifecycle-observability]] — Langfuse 全生命周期可观测性平台
- [[references/langfuse-deployment-practice]] — Langfuse 部署实战：搭建 Agent 可观测平台
- [[skills/langfuse-self-hosting]] — Langfuse 自托管部署指南
