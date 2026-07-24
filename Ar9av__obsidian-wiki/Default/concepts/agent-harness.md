---
title: Agent Harness
category: concepts
tags: [ai, agent, engineering, observability]
sources:
  - "叶小钗: Agent Harness 可观测性：生产级 AI 项目必须补上的一课 (2026-05-25)"
  - "叶小钗: Agent 可观测性：为什么有了 LangChain，还会出现 Langfuse？ (2026-06-10)"
  - "随野录: Agent Harness 可观测性：让 LLM 智能体的执行全过程可记录、可回放、可评估 (2026-06-03)"
  - "企业大模型应用和开发: 【Agent Harness Engineering】8. 可观测性与运维：Agent系统的透明化监控体系 (2026-06-07)"
  - "小加号编程笔记: AI Agent 可观测性：如何记录推理、工具调用、失败与成本 (2026-07-13)"
summary: Agent Harness 是围绕 AI Agent 执行环境的工程框架层，涵盖执行日志、Trace 链路、指标采集、决策归因、任务状态、异常检测、评估回放等能力，是生产级 Agent 项目的基础设施。
provenance:
  extracted: 0.50
  inferred: 0.45
  ambiguous: 0.05
base_confidence: 0.44
lifecycle: draft
lifecycle_changed: 2026-07-16
tier: supporting
created: 2026-07-16T00:00:00+08:00
updated: "2026-07-25"
relationships:
  - target: "[[concepts/ai-agent-observability]]"
    type: implements
  - target: "[[concepts/agent-trace-and-timeline]]"
    type: uses
  - target: "[[entities/ai-observe-stack]]"
    type: related_to
  - target: "[[entities/openclaw]]"
    type: related_to
  - target: "[[entities/helicone]]"
    type: related_to
  - target: "[[entities/langfuse-llm-observability]]"
    type: related_to
  - target: "[[entities/langsmith]]"
    type: related_to
  - target: "[[references/agent-harness-observability]]"
    type: related_to
---

# Agent Harness

Agent Harness 是围绕 AI Agent 执行环境构建的**工程框架层**。2025 年以来，Agent 的基础执行能力已足够成熟，大量产品走向生产环境，如何让 Agent 长期稳定运行、正确执行长链路复杂任务成为核心挑战——Harness 正是为回答这一问题而出现的工程实践。

## 概念边界

Harness 不是 Agent 框架本身（如 LangChain、LlamaIndex），也不是可观测平台（如 [[entities/langfuse-llm-observability|Langfuse]]、[[entities/langsmith|LangSmith]]），而是**位于两者之间的工程胶水层** ^[inferred]：

- **向下**：规范化 Agent 的执行过程，产生结构化、可追踪的运行时数据
- **向上**：为可观测平台提供标准化的数据输入，支撑排障、评估、优化

> "现阶段所有围绕 Agent 工程架构的技术被称为 Harness。" — 叶小钗 (2026-05-25)

### 一个真实案例：为什么 Harness 不是可选的

开发者让 Agent 调用 `write_file` 工具写一篇文章，Agent 反复报错 `缺少 'path' 参数`。检查代码没发现问题——按传统软件开发经验，需要打日志看模型返回了什么。^[extracted]

加上执行日志和模型日志面板后，立刻看到根因：**模型连续几次把工具参数包成了错误的 `_raw` 结构**——工具期待结构化参数（`path`、`content`），模型却把它们塞进了 `_raw` 字符串里，工具拿不到字段自然失败。^[extracted]

这个问题很简单——程序做一下参数兼容就好。但关键在于：**如果没有 Harness 层的日志面板，排查这个问题可能需要数小时的人工猜测和代码翻查。** 而有了 Harness 的模型日志 + 工具调用日志，三分钟定位根因。^[extracted]

这正是 Harness 的核心价值：将 Agent 的黑盒行为变成可检查、可追溯的白盒信号。

## Harness 的核心能力

### 1. 执行日志与模型日志
记录每次 Agent 执行的完整过程，包括：模型输入（Prompt + 上下文）、模型输出（原始响应）、工具调用参数与结果、错误与重试信息。这是最基本的 Harness 能力，也是所有上层能力的基石。

### 2. Trace 调用树
将 Agent 的多轮推理构建为层级化 Trace，展示从 Task → LLM Call → Tool Call → Retry 的完整调用树。参见 [[concepts/agent-trace-and-timeline]]。

### 3. 指标设计
定义 Agent 特有关键指标：
- **性能**：端到端延迟、TTFT（首个 Token 时间）、TPOT（每输出 Token 时间）
- **成本**：Token 消耗（按模型/租户/任务类型）、API 调用费用
- **质量**：工具调用成功率、任务完成率、重试次数、平均推理轮次
- **安全**：敏感命令执行频率、Prompt 注入检测命中率

### 4. 决策归因
回答"Agent 为什么这么做"——将 Agent 的每一步决策（工具选择、信息检索、推理路径）与其上下文关联，形成可解释的决策链。

### 5. 任务状态显式化
将 Agent 的内部状态（pending → reasoning → tool_calling → reflecting → done）显式暴露为可观测状态机，而非隐藏在日志行中。

### 6. 异常检测
基于历史基线检测异常模式：异常高的 Token 消耗、异常的推理轮次、异常的工具调用组合（如反复编辑同一文件——"循环修复"模式）。

### 7. 评估与回放
- **评估**：对比不同模型版本、Prompt 模板在同一任务上的表现
- **回放**：使用历史 Trace 数据复现问题，验证修复效果

## Harness 可观测性的工程实现细节

来自 Mini-OpenClaw 等项目的实践经验，Harness 可观测性需要把以下八个方面显式化：^[extracted]

### 1. 原始数据记录

每个会话保存一份原始日志（如 `jsonl`），包含用户请求消息、模型请求和响应、工具输入和输出、异常、会话压缩、评估结果等。^[extracted] 优先保留的事件类型：^[extracted]

- `model_call` / `model_result`：记录模型输入输出、token、耗时、模型名。
- `tool_call` / `tool_result`：记录工具名、参数、结果、错误。
- 上下文和状态变化：如压缩、任务状态迁移。
- 观测系统自己生成的事件：如 `anomaly`、`evaluation`。

这类原始数据可分为两部分：模型输入输出（方便查看提示词是否按设计格式提供）和 Agent 执行日志（按时间线查看执行流程）。^[extracted]

### 2. 指标设计

基于原始数据可计算的关键指标：^[extracted]

- 工具错误率
- 模型调用耗时
- token 消耗
- 上下文压缩是否过于频繁
- 成本评估

指标能提示哪里可能不正常，但不能解释根本原因。^[extracted] 例如工具错误率 30% 只能说明工具调用经常失败，无法区分是工具实现坏了、模型传错参数，还是工具描述让模型误解了 schema。^[extracted]

### 3. Trace 调用树结构

Agent 执行不是一条线，更像一棵树：一次模型调用产生一个或多个工具调用，工具结果进入下一轮模型调用，某个工具如果触发委派，下面还会展开子 Agent 的完整执行过程。^[extracted]

设计原始日志时应记录三个关键字段：^[extracted]

- `model_call_id`：把一次模型请求、响应、决策记录和后续动作关联起来。
- `tool_call_id`：把工具调用和工具结果配对。
- `delegation_id`：把子 Agent 的事件挂回父 Agent 的委派节点。

有了这些字段，Trace 调用树就不需要靠时间顺序来猜。^[extracted]

### 4. 决策归因

Trace 能展示 Agent 执行树，但还需要回答"模型为什么选择这个工具""它考虑过别的吗""如果跑偏了如何排查"。^[extracted] 一种做法是在 system prompt 里加入决策记录规范，让模型在需要选择动作时输出固定格式的决策块，包含当前目标、候选动作、最终选择、选择原因和预期结果。^[extracted]

后端解析这个决策块，生成 `decision` 事件挂到对应模型调用节点上。^[extracted] 这样看 Trace 时，不仅看到它调用了某个工具，还能看到它当时认为自己的目标是什么、为什么选择这个工具而不是继续搜索或询问用户。^[extracted]

### 5. 任务状态显式化

复杂任务光有 Trace 还不够，用户真正关心的是任务状态：任务有没有完成？哪个卡住了？当前进行到哪一步？^[extracted]

每个会话开始创建 root task，调用 `delegate_task` 时创建子 task。任务有自己的状态机：`pending` → `planning` → `running` → `waiting_child` → `succeeded` / `failed` / `cancelled`。^[extracted] 同时用 `tasks.jsonl` 记录任务变化历史，`tasks.json` 保存当前任务状态。^[extracted]

### 6. 异常检测

Agent 一次工具调用失败很正常，真正危险的是连续失败、不能收敛、还在不停执行。^[extracted] 常见异常模式：^[extracted]

- 同一个工具连续失败
- 连续两轮模型没有响应
- token 突然暴涨
- 一直说在调整但实际上只是换一种说法重复失败

可先实现一组规则：重复失败、接近迭代上限、空响应循环、压缩频繁、未知工具。^[extracted] 规则在执行过程中或会话结束后触发，写入 `anomaly` 事件，前端在可观察性页面展示。^[extracted]

### 7. 评估

当过程看清楚后，还要回答"这次到底做对没有"。^[extracted] 可设置三种评估方式：^[extracted]

- **用户反馈**：对模型回复点赞或点踩。
- **启发式评估**：会话结束后检查明显失败信号，如没有最终回复、有高严重度异常、模型调用失败、迭代次数接近上限、工具错误率太高。
- **LLM-as-Judge**：让另一个模型评估 Agent 输出。

### 8. 回放与对比

真实调试 Agent 最常见的动作是：抓到失败 case，改 prompt / 工具描述 / Agent 配置，再跑一次。^[extracted] 判断是否有效，可用同一个 case，在相似条件下再跑一次，对比两棵 Trace 调用树。^[extracted]

例如原来写文件失败 4 次，新会话只失败 1 次或没有失败；原来触发高风险异常告警，新会话没有触发；原来评估失败，新会话成功。^[extracted] 两个会话的迭代、模型调用、工具调用、委派节点会被结构化对齐，展示哪些节点相同、新增、消失或状态/耗时变化。^[extracted]

这形成闭环：发现问题 → 定位轨迹 → 修改配置 → 回放对比。^[extracted]

## ETCLOVG 框架中的可观测层

Agent Harness Engineering 的 ETCLOVG 框架将可观测性与运维（Observability and Operations，O层）定位为第五层——负责提供监控、追踪和分析能力，使智能体行为透明可理解。这一层是智能体系统运维的基础，支持问题诊断、性能优化、成本控制和可靠性保障。^[extracted]

ETCLOVG 的可观测层包含三大核心组件 ^[extracted]：

- **追踪（Tracing）**：记录模型调用、工具调用、状态转移、跨智能体协作的完整路径
- **监控（Monitoring）**：实时观察执行状态、资源消耗、成本消耗、系统健康
- **分析（Analysis）**：从追踪和监控数据提取错误分析、性能分析、成本分析、行为分析

## Harness 可观测性的八维数据捕获模型

从一次 Agent 运行的视角，Harness 可观测性需要捕获八个维度的字段 ^[extracted]：

| 维度 | 要捕获的字段 | 主要用途 |
|------|-------------|---------|
| **目标/意图** | 用户请求、系统 prompt、显式目标 | 离线评估、对齐业务需求 |
| **计划/推理** | CoT、ReAct 步骤、子任务分解 | debug 决策失败原因 |
| **上下文** | prompt 历史、检索文档、记忆读写 | token 优化、prompt 调优 |
| **工具调用** | 工具名、参数、返回、延迟、错误 | 工具失败率、慢调用分析 |
| **状态变化** | 变量更新、scratchpad 演化、子 agent 交接 | 多 agent 协作可追溯 |
| **成本** | 每步 token、缓存命中、模型单价 | 按用户/会话/工具的 ROI 看板 |
| **风险** | 护栏触发、PII 检测、注入尝试、超时 | 安全审计、异常告警 |
| **结果质量** | 最终输出、LLM-as-judge 分数、人工反馈 | 回归测试、模型/版本发布门禁 |

这八列数据汇到一起，支撑四种核心能力：**记录（Record）、度量（Measure）、回放（Replay）、评估（Evaluate）**。^[extracted]

## 跨智能体追踪

多智能体系统的追踪比单 Agent 更复杂 ^[extracted]：

- **追踪关联**：关联不同智能体的追踪
- **通信追踪**：追踪智能体间通信
- **状态同步**：追踪智能体状态同步
- **结果聚合**：追踪结果聚合过程

## 可观测性框架六大流派

市面上的 Agent 可观测性项目大致分六个流派 ^[extracted]：

| 流派 | 代表项目 | 卖点 |
|------|---------|------|
| 平台一体化 | LangSmith、Maxim | 开箱即用，trace + eval + prompt hub 一体 |
| 开源自托管 | Langfuse、Phoenix、LangWatch | 数据自有，可控可审计 |
| 网关代理 | [[entities/helicone|Helicone]]、Portkey | 一行改 base_url 接入，路由+缓存+成本 |
| OTel 标准派 | OpenLLMetry / Traceloop、Honeycomb | 厂商中立，未来切换成本低 |
| 评估为先 | Braintrust、W&B Weave | dataset/scorer/CI 流水线最完善 |
| 企业 APM | Datadog LLM Obs、New Relic AI | 已有 APM 用户的统一面板 |

另外还有 **Agent 原生**项目：**AgentOps**（`AgentOps-AI/agentops`，MIT 协议）是唯一从一开始就为 Agent 而生的项目，对 LangChain / CrewAI / AutoGen / OpenAI Agents SDK 有专门埋点，提供 session replay + 多 Agent 交接追踪 ^[extracted]；Maxim 也提供类似能力。

## 与 LangChain/Langfuse 的关系

LangChain 是 Agent 开发框架（关注"如何构建 Agent"），Langfuse 是 LLM 可观测平台（关注"如何查看 Agent 行为"）。Harness 是两者之间的工程实践——它不替代任何一方，而是**补充从开发到生产的工程化缺失** ^[inferred]。

一个典型的 Harness 实现可能使用 LangChain 作为 Agent 框架，通过 Harness 层规范化和丰富运行时数据，再将数据导出到 Langfuse 进行可视化和评估。

## Harness 的工程价值

来自一线实践的总结：

- **量化上限**——有了 Trace 和指标，Agent 的能力上限不再是主观感受，而是可测量、可对比的
- **锁定回归**——模型升级或 Prompt 修改后，通过回放历史任务验证是否存在退化
- **成本透明**——每次任务执行的成本（Token + API）可精确归因到具体步骤
- **加速排障**——从"模型回答不对"到"第三轮工具调用返回了空结果，导致后续推理走偏"的分钟级定位

## OTel 自建最小可观测层

不想用 SaaS 又不想被 LangChain 绑死？用 OpenTelemetry 自己手搓一个最小可观测层，约 80 行代码即可拿到全链路 trace ^[extracted]：

```python
from opentelemetry import trace
from opentelemetry.sdk.trace import TracerProvider
from opentelemetry.sdk.trace.export import BatchSpanProcessor
from opentelemetry.sdk.resources import Resource

provider = TracerProvider(resource=Resource.create({
    "service.name": "my-agent",
    "service.version": "1.0.0",
}))
trace.set_tracer_provider(provider)
tracer = trace.get_tracer(__name__)

def llm_step(name, model, messages):
    with tracer.start_as_current_span(f"llm.{name}") as span:
        span.set_attribute("gen_ai.system", "openai")
        span.set_attribute("gen_ai.request.model", model)
        resp = client.chat.completions.create(model=model, messages=messages)
        u = resp.usage
        span.set_attribute("gen_ai.usage.input_tokens", u.prompt_tokens)
        span.set_attribute("gen_ai.usage.output_tokens", u.completion_tokens)
        return resp.choices[0].message.content

def tool_call(name, args, fn):
    with tracer.start_as_current_span(f"tool.{name}") as span:
        span.set_attribute("gen_ai.tool.name", name)
        try:
            result = fn(**args)
        except Exception as e:
            span.record_exception(e)
            raise
        return result
```

生产时将 `ConsoleSpanExporter` 换成 `OTLPSpanExporter`，即可打到任何 OTel 后端（Jaeger + Grafana Tempo + Loki、Honeycomb、Datadog）。关键在于一开始按 **OpenTelemetry GenAI 语义约定**写属性名，将来换 Langfuse、Honeycomb 或 Datadog 都不用改业务代码 ^[extracted]。

## 落地五步法

从 0 到生产级 Harness 可观测性 ^[extracted]：

1. **埋点优先**：30 分钟接入 `@observe` / `@traceable` / `tracer.start_as_current_span`
2. **成本看板**：第一周建立按用户/会话/工具切分的成本看板，识别烧钱 Top 10% 流量
3. **错误回放**：把用户报错的 trace 拉出来，修掉工具失败率 Top 3
4. **离线 eval**：从 trace 挑 50-100 条典型 case 建 dataset，写 LLM-as-judge 评分函数，绑定 GitHub Action
5. **在线 eval + 告警**：线上 1% 抽样跑 judge，胜率跌破阈值告警；配合网关 + Guardrails 强制实施业务约束

## 2026 年三个趋势

1. **OTel GenAI 语义约定进入稳定期**：OpenLLMetry、Traceloop、Langfuse、Datadog 都在跟进，新项目直接按 `gen_ai.*` 属性名埋点最稳 ^[extracted]
2. **Eval 从离线走向在线**：微软 Adaptive Spec-driven Scoring 让"用文本描述生成测试用例"成为可能，叠加线上抽样 LLM-as-judge，质量门禁越来越像传统 CI ^[extracted]
3. **多 Agent 可观测性**：CrewAI / AutoGen 等多 agent 编排框架成熟，子 agent 委派、上下文交接、工具路由成为第一公民，AgentOps 和 Maxim 等 agent 原生平台越来越被需要 ^[extracted]

## 开放性议题

- Harness 是否应该标准化为一个独立框架，还是每个团队各自实现？目前生态中缺乏标准 Harness 实践指南 ^[ambiguous]
- Harness 层引入的额外延迟（日志记录、状态追踪）在处理高吞吐 Agent 时的开销权衡 ^[inferred]

## Related

- [[entities/ai-observe-stack]] — Agent 可观测数据的存储后端，Harness 产生的运行时数据最终存储于此
- [[entities/openclaw]] — OpenClaw 的安全危机是 Agent Harness 必要性的典型案例
- [[references/agent-harness-observability]] — Agent Harness Engineering 可观测性与运维
