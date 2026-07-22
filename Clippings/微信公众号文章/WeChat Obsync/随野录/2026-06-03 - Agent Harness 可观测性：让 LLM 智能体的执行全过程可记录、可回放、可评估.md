---
source_url: "https://mp.weixin.qq.com/s?search_click_id=4566775704178140990-1784705505979-4599395651&__biz=MzYzNDkwMjY1Mg==&mid=2247485444&idx=1&sn=0892a4c2e2b19b9660ff995e07314774&chksm=f10721fc4efaedc2833e8ad44981cd2bfb36b4770918e4380c41b9bdf52436c198d487401558&subscene=90&scene=7&clicktime=1784705505&enterid=1784705505&ascene=65&devicetype=iOS26.5.2&version=18004b43&nettype=3G+&abtest_cookie=AAACAA==&lang=zh_CN&countrycode=CN&fontScale=100&exportkey=n_ChQIAhIQHjvoIGOv1l0ZBZplg3UgsRLhAQIE97dBBAEAAAAAAP5uJI6fCl0AAAAOpnltbLcz9gKNyK89dVj0uRuzcEVYN1Mc2IeZAMbottknWEIW6OSnkZhuVwhX8oN5H2yOowSBHsFGx+TOnL9qzfx1rSRnVPkbHX4fwmIdeQ613w0OzwfRByOC3ATEymBLXp8pDsqI7rowydH/KwgePuKldCJhnRXwv1hfKmLq97uSBry7HRge/5YYpmXK4kdQKZNRyDcHD2Necx854uHdD0TuhVJ//Xh4hQAwMdTAQq14RyVWlleg03+dOpwZ8NQmJ7Gck64KDUaazw==&pass_ticket=jy71kAl4aQZDlNasFj5AsC/WCxeruLmiAv8ssU5jT8paNTg/gGxmfpNUsQy41zpx&wx_header=3"
title: "Agent Harness 可观测性：让 LLM 智能体的执行全过程可记录、可回放、可评估"
account: "随野录"
published_at: "2026-06-03T14:16:44.000Z"
saved_at: "2026-07-22T07:31:58.324Z"
sync_id: "art_043d1bb7e3b14699b62e1f5c2fb5b244"
parse_status: "ok"
---

# Agent Harness 可观测性：让 LLM 智能体的执行全过程可记录、可回放、可评估

导读

把 LLM 智能体从 Demo 推到生产，最难的不是写提示词，而是**看得见它到底在做什么**。这一篇系统讲清楚 **Agent Harness 可观测性**：要捕获哪些数据、用什么模型组织数据、怎么回放与评估，以及 **Langfuse**、**LangSmith**、**Arize Phoenix**、**OpenLLMetry**、**Braintrust**、**AgentOps** 等主流框架各自的能力边界、SDK 用法和选型对比，最后给出一套不依赖任何商业平台的 OTel 自建方案。

Agent

可观测性

Trace

Eval

OpenTelemetry

01

为什么 Agent 跑起来就是黑盒

写一个能跑的 Agent 很简单——十几行 Python，调  `openai.chat.completions.create` ，外面套一层 while 循环就能跑。但线上跑三天就出怪事：

• 用户报了一个错误，**你不知道是哪一次 LLM 调用、哪一条工具响应、哪一行 prompt 改了**导致的；

• 同事在 Slack 说"agent 比上周慢了一倍"，**你查不到 token 烧在哪、工具超时在哪**；

• 业务想算 ROI，**你拿不到每个用户每次会话的真实成本**；

• 升级到 Claude 4.8 之后行为变了，**没有任何数据可以回放对比**。

这不是某个框架的问题，是 LLM 应用的本质：传统的 APM（应用性能监控）只能看见"调用了一次 HTTP"，看不见里面 token 怎么用、工具怎么选、上下文怎么长。Agent 的 **执行链**比传统服务长得多、有状态得多、有非确定性得多——必须有一套专门的可观测性基础设施来兜底。

关键洞察

Agent 可观测性不是"加个日志"就完事。它的对象是一个 **非确定的、嵌套的、多回合的 LLM+工具调用图**——每个节点都是一次 LLM 决策、一次工具往返、一次状态更新。你要的是一棵可查询、可回放、可打分的执行树，不是几行 print。

02

Agent Harness 可观测性到底在观测什么

**Agent Harness** 是包裹 LLM 的运行时——它拥有循环、管理上下文、调用工具、持久化状态、产出结果。**Harness 可观测性**就是把这一整条执行链做到：看得见、能量化、能重放、能打分。具体到一次 Agent 运行，要捕获的字段可以拆成 **八个维度**：

| 维度 | 要捕获的字段 | 主要用途 |
| --- | --- | --- |
| ** 目标 / 意图 ** | 用户请求、系统 prompt、显式目标 | 离线评估、对齐业务需求 |
| ** 计划 / 推理 ** | CoT、ReAct 步骤、子任务分解 | debug 决策失败原因 |
| ** 上下文 ** | prompt 历史、检索文档、记忆读写 | token 优化、prompt 调优 |
| ** 工具调用 ** | 工具名、参数、返回、延迟、错误 | 工具失败率、慢调用分析 |
| ** 状态变化 ** | 变量更新、scratchpad 演化、子 agent 交接 | 多 agent 协作可追溯 |
| ** 成本 ** | 每步 token、缓存命中、模型单价 | 按用户/会话/工具的 ROI 看板 |
| ** 风险 ** | 护栏触发、PII 检测、注入尝试、超时 | 安全审计、异常告警 |
| ** 结果质量 ** | 最终输出、LLM-as-judge 分数、人工反馈 | 回归测试、模型/版本发布门禁 |

这八列数据汇到一起，就能支撑起下面四种能力：**记录 / 度量 / 回放 / 评估**。这四件事正是 2026 年 Agent 平台层的标准动作——最近一周的 **微软 Adaptive Spec-driven Scoring** 开源、**微软研究院**发布智能体评估与价值对齐研究、**OpenAI**公布第三方评估操作手册，方向都是一致的：把"看 LLM 在干什么"做成生产级工程能力。

![](附件资源/Agent%20Harness%20可观测性：让%20LLM%20智能体的执行全过程可记录、可回放、可评估/img_1.jpg)

03

统一的心智模型：Trace / Span / Event

几乎所有主流框架都收敛到同一套数据模型——**OpenTelemetry 的 Trace 模型**。理解这三个词就够了：

Trace（一次完整运行）

一条 Trace = 一次 Agent 完整运行 = 一个用户请求到最终答复的全过程。Trace 有一个全局 ID、开始时间、结束时间、状态（成功/失败）、一个根 Span。

Span（一个工作单元）

Span 是 Trace 内部的一个工作节点——一次 LLM 调用、一次工具往返、一次检索、一次子 agent 委派。Span 都有一个  `parent_id` ，所以它们会形成一棵树，正好对应 Agent 的"思维图"。一个典型的 ReAct Agent 的 trace 长这样：

trace-tree.txt

root: chain.run_agent (2.4s, $0.018)
llm: plan_step (380ms, 640 tokens, gpt-4o)
tool: search_docs(q="RAG vs fine-tune") (820ms)
llm: reflect_step (290ms, 410 tokens)
tool: get_doc(id=42) (120ms)
llm: final_answer (510ms, 820 tokens, gpt-4o)
event: guardrail.pii_detected → redacted

Event（事件标注）

Event 是 Span 上的时间戳标注——"护栏触发"、"重试一次"、"用户点了赞"。它不带时长，只有瞬间语义，用于在 Span 内追加上下文。

Span 上挂载的属性（attributes）才是真正的"业务字段"： `model=gpt-4o-2024-08-06` 、 `prompt_version=v3.2` 、 `tool_name=search_docs` 、 `user_id=u_42` 、 `session_id=s_abc` 。这些键值对是后续查询、聚合、过滤的全部基础。

![](附件资源/Agent%20Harness%20可观测性：让%20LLM%20智能体的执行全过程可记录、可回放、可评估/img_2.png)

04

四大能力：记录、度量、回放、评估

把 trace 数据沉淀下来之后，能解锁的工程能力分四档：

REC

记录

MET

度量

RPL

回放

EVAL

评估

记录：把执行链持久化

最底层——把每一次运行的 span tree 原样落到对象存储或数据库。存储格式通常是 JSON / protobuf / Parquet，便于后续查询。**注意：**原始 prompt/response 涉及隐私，落地时要做 PII 脱敏和保留策略，否则法务会找你。

度量：成本/延迟/成功率的看板

从 trace 数据中按维度聚合：每个用户的 token 成本、每种工具的 p95 延迟、每个 prompt 版本的胜率、每个会话的轮次分布。成熟平台直接给你 SQL/DSL 查询界面，新手可以从"过去 7 天总成本"和"异常失败的 trace"两个查询开始。

回放：时间旅行调试

有三种回放，能力依次增强：

• **Session 回放**：在 UI 上点开一次 trace 看到完整的 span 树和事件。

• **带补丁回放**：把某次 trace 的 prompt 改一行、模型换 Claude 4.8，重跑看差异。**LangSmith** 和 **Langfuse** 的强项。

• **确定性格栅**：要温度 0 + 锁版本模型 + 可重放的工具才能做到，绝大多数生产系统都做不到。

评估：把"质量"变成数字

评估分 **离线**和**在线**两种：

• **离线评估**：跑一个固定 dataset 上的若干个 case，比 prompt/模型变体之间的胜率。可以塞进 CI，每次改 prompt 自动跑一遍。

• **在线评估**：线上流量里随机抽样，让 LLM-as-judge 给每次输出打 1-5 分，发现回归就告警。**Braintrust**、**Phoenix**、**Maxim** 在这块最成熟。

05

框架全景：六大流派

市面上的 Agent 可观测性项目大致分 **六个流派**，定位和取舍各不相同：

| 流派 | 代表项目 | 卖点 |
| --- | --- | --- |
| 平台一体化 | LangSmith、Maxim | 开箱即用，trace + eval + prompt hub 一体 |
| 开源自托管 | Langfuse、Phoenix、LangWatch | 数据自有，可控可审计 |
| 网关代理 | Helicone、Portkey | 一行改 base_url 接入，路由+缓存+成本 |
| OTel 标准派 | OpenLLMetry / Traceloop、Honeycomb | 厂商中立，未来切换成本低 |
| 评估为先 | Braintrust、W&B Weave | dataset/scorer/CI 流水线最完善 |
| 企业 APM | Datadog LLM Obs、New Relic AI | 已有 APM 用户的统一面板 |

另外还有一类**"Agent 原生"**项目：**AgentOps**、**Maxim**，专门为多 agent 协作 / 工具调用 / 任务委派做了第一公民支持，是 CrewAI、AutoGen 这类多 agent 框架的官方推荐搭档。

06

五大主流框架详解

挑五个最值得关注的逐个过：定位、代码示例、优劣。看完你应该能直接选一个上手。

Langfuse：开源 + OTel 原生

- GitHub： langfuse/langfuse 。
- MIT 协议，Self-hostable，OTel 一等公民。
- Python/JS/Ruby SDK，自带 prompt 管理、dataset、LLM-as-judge、playground。
- LangChain / LlamaIndex / OpenAI / Bedrock / DSPy 全有官方集成。

langfuse_demo.py

from langfuse import observe, Langfuse
from langfuse.openai import openai  # drop-in instrumented client

@observe(name="research_agent")
def answer(q: str) -> str:
docs = retriever.search(q)  # 自动成为子 span
resp = openai.chat.completions.create(
model="gpt-4o",
messages=[{"role": "user", "content": f"{q}\n\n{docs}"}],
)
return resp.choices[0].message.content

**优势：**真正开源、数据自有、OTel 原生（导出到任何后端）、生态最广。
**劣势：**自托管要 ClickHouse 集群、运维成本；UI 比 LangSmith 略糙。

LangSmith：LangChain 用户的默认选择

- SDK 开源（ langchain-ai/langsmith-sdk ，MIT），平台闭源。
- 和 LangChain 配合最丝滑——所有 chain/agent 内部事件自动捕获。
- Dataset、Evaluator、Hub 配合做 prompt 迭代体验最好。

langsmith_demo.py

from langsmith import traceable

@traceable(run_type="chain", name="research_agent")
def run(q: str) -> str:
plan = call_llm(q)  # 嵌套 span
docs = retriever.search(plan)
return call_llm(q, docs)

**优势：**LangChain 一等公民、prompt hub 协作、回放/分支能力业界最强。
**劣势：**闭源平台、量大后单价贵、非 LangChain 项目接入略绕。

Arize Phoenix：评估最强的开源项目

- GitHub： Arize-ai/phoenix 。
- Elastic 协议，自托管能力扎实。
- 它的差异化在 Eval 库 ——幻觉检测、toxicity、relevance、Q&A 正确性、summarization 都有现成模板；RAG 诊断（哪些 chunk 真的有用）做得最深；embedding drift 用 UMAP 可视化。

phoenix_demo.py

import phoenix as px
from phoenix.trace.openai import OpenAIInstrumentor

px.launch_app()  # 本地 :6006 开 UI
OpenAIInstrumentor().instrument()  # auto-trace 所有 OpenAI 调用

resp = openai.chat.completions.create(model="gpt-4o", messages=[...])

**优势：**eval 模板最丰富、RAG 分析最强、embedding drift 工具独有。
**劣势：**Elastic 协议不是 OSI 认可、UI 偏 eval 而非 runtime 监控。

OpenLLMetry / Traceloop：OTel 标准的"官方实现"

- GitHub： traceloop/openllmetry 。
- Apache 2.0，OTel 委员会 GenAI 语义约定的主要贡献者。
- 它是 LLM 世界的 "OpenTelemetry 官方实现"—— 不绑定任何特定后端 ，trace 可以直接打到 Datadog、Honeycomb、Tempo、Jaeger、New Relic。

openllmetry_demo.py

from opentelemetry import trace
from opentelemetry.exporter.otlp.proto.http.trace_exporter import OTLPSpanExporter
from opentelemetry.sdk.trace.export import BatchSpanProcessor
from traceloop.sdk import Traceloop

provider = trace.get_tracer_provider()
provider.add_span_processor(BatchSpanProcessor(OTLPSpanExporter(endpoint="https://otel.honeycomb.io/v1/traces")))
Traceloop.init(app_name="research-agent")

# 之后所有 OpenAI/Anthropic/Bedrock 调用自动被埋点
openai.chat.completions.create(model="gpt-4o", messages=[...])

**优势：**厂商中立、auto-instrumentation 覆盖面最广（OpenAI / Anthropic / Bedrock / Vertex / LangChain 全都有）、未来切换零成本。
**劣势：**本身没有 UI，要么接 Traceloop Cloud 要么自己接 OTel 后端。

Braintrust + AgentOps：评估优先与 Agent 原生

**Braintrust**（ `braintrustdata/braintrust` ，SDK MIT）把"dataset + scorer + experiment"做成 CI 一等公民。GitHub Actions 里跑 eval、对比 prompt 版本、A/B 上线，工程师体验最好。
**AgentOps**（ `AgentOps-AI/agentops` ，MIT）是 **唯一从一开始就为 Agent 而生**的项目，对 LangChain / CrewAI / AutoGen / OpenAI Agents SDK 都有专门埋点，session replay + 多 agent 交接追踪。

agentops_demo.py

import agentops
from openai import OpenAI

agentops.init(api_key="sk-...")
client = OpenAI()

resp = client.chat.completions.create(model="gpt-4o", messages=[...])
agentops.record(event="tool_call", name="search", args={"q": "..."})

![](附件资源/Agent%20Harness%20可观测性：让%20LLM%20智能体的执行全过程可记录、可回放、可评估/img_3.png)

07

横向对比表

| 项目 | 开源 | OTel 原生 | Eval | Agent 优先 | 最适合 |
| --- | --- | --- | --- | --- | --- |
| ** LangSmith ** | 否 | 部分 | ★★★★★ | 中 | LangChain 团队 |
| ** Langfuse ** | 是 (MIT) | 是 | ★★★★ | 中 | 数据自有 + 生态广 |
| ** Helicone ** | 是 (Apache) | 部分 | ★★★ | 低 | 多 provider 成本控制 |
| ** Phoenix ** | 是 (Elastic) | 是 | ★★★★★ | 中 | RAG + eval 重 |
| ** OpenLLMetry ** | 是 (Apache) | 是 | ★★ | 中 | 厂商中立 |
| ** Braintrust ** | SDK | 部分 | ★★★★★ | 中 | CI eval 流水线 |
| ** AgentOps ** | 是 (MIT) | 部分 | ★★★ | ★★★★★ | 多 agent 系统 |
| ** Datadog LLM ** | 否 | 是 | ★★★ | 中 | 已有 Datadog |

08

不依赖商业平台：OTel 自建最小可观测层

不想用 SaaS 又不想被 LangChain 绑死？用 OpenTelemetry 自己手搓一个最小可观测层——大概 80 行代码就能拿到全链路 trace。

otel_agent_observer.py

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

# 导出:可同时接 ConsoleSpanExporter 调试 + OTLPSpanExporter 上生产
from opentelemetry.sdk.trace.export import ConsoleSpanExporter
provider.add_span_processor(BatchSpanProcessor(ConsoleSpanExporter()))

把这套埋点写进你的 Agent 主循环里，每一个 LLM 调用、每一个工具调用都是一条 span。生产时把  `ConsoleSpanExporter`  换成  `OTLPSpanExporter` ，把 trace 打到任何 OTel 后端：

• **想完全自托管**：Jaeger + Grafana Tempo + Loki，三件套跑在 K8s 上。

• **想要高级调试**：**Honeycomb.io**，BubbleUp 自动定位"哪类 span 在出错时突然变多"。

• **已有 Datadog**：直接  `ddtrace`  替换 exporter，trace 进同一面板。

关键在于：**一开始就按 OpenTelemetry GenAI 语义约定**写属性名（ `gen_ai.request.model` 、 `gen_ai.usage.input_tokens` 、 `gen_ai.tool.name` ）。将来无论换 Langfuse、Honeycomb 还是 Datadog，都不用改业务代码——只改 exporter。

09

从哪一步开始落地

如果你正准备给生产 Agent 接入可观测性，按下面这个顺序推进最省事：

第 1 步：埋点优先

不要在"选哪个平台"上纠结超过一天。直接  `@observe` （Langfuse）或  `@traceable` （LangSmith）或  `tracer.start_as_current_span` （OTel）三选一，把所有 LLM 调用和工具调用先包起来。30 分钟就能接完。

第 2 步：成本看板

第一周的目标：建一个按用户/会话/工具切分的成本看板。识别出"烧钱的那 10% 流量"比任何花哨评估都重要。

第 3 步：错误回放

把用户报错的 trace 拉出来，看 prompt / 工具返回 / guardrail 事件。修掉工具失败率 top 3 的工具。

第 4 步：离线 eval 跑起来

从 trace 库里挑 50-100 条典型 case 建 dataset，写一个 LLM-as-judge 评分函数，绑定 GitHub Action 每次改 prompt 自动跑。

第 5 步：在线 eval + 告警

线上流量 1% 抽样跑 judge，胜率跌破阈值就 Slack 告警。配合 **OpenRouter** 这类网关加 **Guardrails**，把"每周千美元预算上限"这种业务约束在网关层强制实施。

10

2026 年的三个趋势

• **OTel GenAI 语义约定进入稳定期**：OpenLLMetry、Traceloop、Langfuse、Datadog 都在跟进，未来一年的迁移成本会持续下降，新项目直接按  `gen_ai.*`  属性名埋点最稳。

• **Eval 从离线走向在线**：微软刚开源的 Adaptive Spec-driven Scoring 让"用文本描述生成测试用例"成为可能，叠加线上抽样 LLM-as-judge，质量门禁会越来越像传统 CI。

• **多 Agent 可观测性**：随着 CrewAI / AutoGen / 各类多 agent 编排框架成熟，"子 agent 委派 / 上下文交接 / 工具路由"成为第一公民，**AgentOps** 和 **Maxim** 这类 agent 原生平台会越来越被需要。

可观测性解决的问题很朴素：让 Agent 在生产环境里 **像传统软件一样可被运营**。成本能算、错误能回放、质量能回归、风险能告警——这四件事齐了，Agent 才算真正从 demo 走出来，进入能谈 ROI、谈合规、谈规模的阶段。

参考来源

• **Langfuse**

https://github.com/langfuse/langfuse

• **LangSmith SDK**

https://github.com/langchain-ai/langsmith-sdk

• **Arize Phoenix**

https://github.com/Arize-ai/phoenix

• **OpenLLMetry**

https://github.com/traceloop/openllmetry

• **AgentOps**

https://github.com/AgentOps-AI/agentops

• **Braintrust**

https://github.com/braintrustdata/braintrust

• **Helicone**

https://github.com/Helicone/helicone

• **W&B Weave**

https://github.com/wandb/weave

• **OpenInference**

https://github.com/Arize-ai/openinference

• **微软 Adaptive Spec-driven Scoring（2026-06-02）**

https://techcrunch.com/2026/06/02/new-microsoft-tool-lets-devs-spin-up-ai-behavior-tests-using-text-descriptions

• **OpenAI 第三方评估操作手册**

https://openai.com/index/trustworthy-third-party-evaluations-foundations

• **OpenRouter Guardrails**

https://openrouter.ai/announcements/guardrails

• **OpenTelemetry GenAI 语义约定**

https://opentelemetry.io/docs/specs/semconv/gen-ai/

---
原文链接：https://mp.weixin.qq.com/s?__biz=MzYzNDkwMjY1Mg%3D%3D&mid=2247485444&idx=1&sn=0892a4c2e2b19b9660ff995e07314774&chksm=f10721fc4efaedc2833e8ad44981cd2bfb36b4770918e4380c41b9bdf52436c198d487401558
