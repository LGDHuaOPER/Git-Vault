---
source_url: "https://mp.weixin.qq.com/s?__biz=Mzg2ODEwNjU0Nw%3D%3D&mid=2247489493&idx=1&sn=a54380917b03cfd4e2798a78b2c0b49b&chksm=ceb03f89f9c7b69f73429fae868df1925b8509fe63854bab708f922669753d2ba726ff586cab"
title: "Agent可观测思考：OpenTelemetry GenAI语义约定、四根支柱及六平台选型对照"
account: "老贾探AI"
published_at: "2026-09-28 12:16:21"
saved_at: "2026-10-20 18:14:50"
sync_id: "art_81b9dff5884f47d98ac3e0140691f612"
parse_status: "ok"
---

# Agent可观测思考：OpenTelemetry GenAI语义约定、四根支柱及六平台选型对照

> **❝**Agent 上生产之后，最容易被低估、也最容易在半夜救你一命的，是「可观测」。我们来看看 **Agent 可观测（Agent Observability）**到底是什么、它和传统 APM 差在哪、OpenTelemetry GenAI 语义约定怎么把链路追平了，并重点关注六类平台怎么选、以及哪些问题到现在还没真正解决。

## 一、Agent 可观测 ≠ 传统监控

先说结论：**传统 APM 假设失败是确定性的，Agent 可观测要处理的是概率性的失败。**

传统应用监控看的是延迟、错误率、在线率——它隐含一个前提：失败会抛错（500、timeout），失败发生在单一调用上。Agent 不这样。一个 Agent 任务可能 fan out 成几十次模型调用、嵌套的工具调用、子 agent 委派、甚至等待人工审批数小时；当答案出错时，产生错误答案的那段推理，埋在三层四层的调用图里。更扎心的是：**监控可以全绿，用户已经翻车**——HTTP 200 返回的，是一句流畅但错误的回答。

![](附件资源/Agent可观测思考：OpenTelemetry%20GenAI语义约定、四根支柱及六平台选型对照/img_1.jpg)

六个维度的差异是硬性的（见图1）：

![](附件资源/Agent可观测思考：OpenTelemetry%20GenAI语义约定、四根支柱及六平台选型对照/img_2.jpg)

核心点出来了：**Agent 的失败是「涌现」的**——它从上下文的累积里长出来，而不是从某一行代码崩出来。所以「看系统指标」永远看不到 Agent 为什么答错。

## 二、误区：可观测不是「加个日志」

这个是有趣的。很多人以为给 Agent 套一层  `console.log`  就算可观测了，其实差得远。

第一性原理上，Agent 一次任务产生的信号形状，和微服务请求完全不同：它是一棵「决策树」，模型调用里嵌套工具调用，每个分支带着自己的 token 记账，还带着看起来根本不像普通错误的「幻觉信号」。标准 APM 是为 HTTP 请求和数据库查询生的，它读不懂这种形状。

一个真实的 war story（来自 chanl.ai 的 2AM 复盘）：生产环境的 Agent 在「幻觉」订单状态——不是每个客户、不是固定模式，只是 3–4% 的对话，自信地告诉用户「已发货」但其实没发。错误率是 0，延迟正常，健康检查全绿。团队花了六小时 grep 非结构化日志，最后发现：**一个工具执行从陈旧的连接池里静默返回了缓存数据，Agent 把陈旧数据当成了新数据。** 模型没说错，工具没抛错，根因在于—— **工具执行根本没被当成 first-class 的 span 来追踪**。

这一点尤其要注意：Agent 可观测要抓的不是「模型」本身，而是「整条执行图」——每一次 LLM 调用、每一次工具调用、每一次记忆读取、每一个规划步骤，串成一条可回放的 trace。它和微服务里的分布式 tracing 很像，**区别只是 span 现在代表「推理片段」，而不是纯软件调用**（eugeneasahara，2026）。

## 三、核心点：OpenTelemetry GenAI 语义约定

先说结论：2025 末到 2026，行业收敛到一个答案—— **「一个 agent 的 trace 长什么样」= OpenTelemetry GenAI 语义约定。**

这套约定（已迁移到 OpenTelemetry 专属仓库  `semantic-conventions-genai` ）把 telemetry 的标准化做到了「埋点一次，到处导出」：

- LLM call spans ：model、provider、token 数（input / output / cached）、finish reason、temperature、response format。
- Tool execution spans ：tool name、参数、结果状态、执行时长。
- Agent orchestration spans ：planning 步骤、reasoning chain、memory 操作、goal completion。

在经典的  `chat`  /  `text_completion`  model-call span 之上，又叠了专门的 span 类型： `invoke_agent` 、 `execute_tool` 、 `create_agent` 、 `invoke_workflow` 。

![](附件资源/Agent可观测思考：OpenTelemetry%20GenAI语义约定、四根支柱及六平台选型对照/img_3.jpg)

关键属性命名空间是这套约定的灵魂（见图3）： `gen_ai.system` 、 `gen_ai.request.model` 、 `gen_ai.usage.input_tokens` 、 `gen_ai.usage.output_tokens` 、 `gen_ai.usage.cached_tokens` 、 `gen_ai.response.finish_reasons` 、 `gen_ai.operation.name` ，再加上应用扩展  `agent.task_type` 、 `agent.step_index` 、 `agent.tenant_id` 。**用标准命名而非 vendor 私有命名，意味着 telemetry 可移植**——从 Langfuse 切到 Grafana，过去要重写每个埋点，现在只换一个 exporter。OTel 每次调用开销 <1ms，而 LLM 延迟普遍 100ms–30s，所以埋点从延迟预算上看几乎免费（agentic-ai / technspire）。

![](附件资源/Agent可观测思考：OpenTelemetry%20GenAI语义约定、四根支柱及六平台选型对照/img_4.jpg)

**MCP 约定是今年一个很关键的补丁。** 过去 Agent 通过 Model Context Protocol 调工具，会产出两条断裂的 trace——一条属于 agent 进程，一条属于 MCP server——因为没有共享的关联机制。MCP 语义约定（ `mcp.session.id` 、 `mcp.method.name` 、通过  `_meta`  字段传播 W3C Trace Context，即 SEP-414）把 MCP server 的 span **嵌套到调用它的工具 span 之下**，而不是复制成一个孤儿 trace。这个可以借鉴：它把「跨进程边界的因果链」真正闭合了。

## 四、四根支柱：追踪、指标、日志、评估

先说一个误区：可观测不是「看得见的日志」就完了。**没有评估的可观测，只是昂贵的日志。** 这句话要刻在脑子里——追踪告诉你「发生了什么」，评估告诉你「好不好」，两者必须一起上（app-lab.ai / standarity.com 都把这个当成硬约束）。

Agent 可观测的四根支柱：

- Traces（追踪） ：每次 LLM 调用、工具调用、记忆读取，都是父 trace 下的一个子 span，拼出完整的执行图。
- Metrics（指标） ：latency、token 成本、成功率、工具错误率的时间序列，供看板和告警。
- Logs（日志） ：结构化事件记录，供调试和审计。
- Evaluations（评估） ：LLM-as-judge、幻觉检测、回归测试。它把「失败评分」直接链回 trace——精确到产生失败那一刻的 prompt、工具输出、记忆状态。

Agent 专属、传统 APM 根本不提供的指标尤其重要：**reasoning depth（推理深度）、backtracks（回退次数）、per-tool error rate（单个工具错误率）、loop count（循环次数）**。这些才是告诉你「Agent 为什么在失败」的信号。

**成本可观测要当成安全网。** 多步工作流里，失控的成本往往先于质量退化出现——Agent 卡在 replanning 循环、冗余工具调用、上下文窗口膨胀，用户还没抱怨，账单先报警。行业经验是：错误 100% 全采，成功请求采 10–20%；PII 落盘前做检测脱敏。

## 五、六平台格局与选型对照

先说结论：平台之间的差异化，越来越不在「能不能抓到 trace」（大多靠 OTel 都能），而在「**抓到 trace 之后干嘛**」。

![](附件资源/Agent可观测思考：OpenTelemetry%20GenAI语义约定、四根支柱及六平台选型对照/img_5.jpg)

- Langfuse ：开源领先，自托管与云功能对等，对数据驻留最友好；把失败 trace 直接变成 eval 回归测试。2025 年 6 月把 LLM-as-judge、标注队列、prompt 实验等模块以 MIT 许可证开源——对「prompt 管理与评估迭代是核心工作流」的团队最合适。
- Arize Phoenix ：评估深度见长（官方称 50+ 研究支撑的度量），通过自有 OpenInference 属性层实现，项目本身强调它 与 OTel GenAI semconv 互补而非竞争 。幻觉检测、embedding drift、RAGAS 原生支持，统计严谨优先时选它。
- LangSmith ：LangGraph 最深，node-by-node state diff、replay 能力最强。 代价是锁定风险最高 ——离开 LangGraph，就等于离开了 LangSmith。
- Datadog / Honeycomb ：把既有 infra 可观测延伸到 agent 形态。Honeycomb 把一切存为统一的「wide events」而非 logs/metrics/traces 三分，号称更能扛住 agent telemetry 的高基数。
- Braintrust / AgentOps ：分别站在 eval-first 和 lifecycle-hook 这一端。

有趣的细节又来了：选型的锚点不该是「谁功能多」，而是你的约束—— **自托管/数据驻留优先 → Langfuse；评估严谨优先 → Phoenix；已经在 LangGraph 栈里 → LangSmith（但要接受锁定）；高基数事件 → Honeycomb**。

## 六、没解决的事 + 决策标尺

先说结论：**可观测的「抓」已经标准化，可「读懂」还远没解决。**

2026 年学术界开始盯上两个真问题：当完整的 step-level tracing 要么没抓到、要么量大到人手读不过来时，怎么归因与调试？一是多 agent 系统的「只有最终文本存活」问题（arXiv:2603.17445）；二是用 counterfactual replay（反事实回放）从一千个 span 的 trace 里，找出那个唯一有因果决定性的事件（arXiv:2606.14805）。这两个方向都还没收敛成工程标配。

把上面的内容压成一条**可迁移的决策标尺**，供你直接套：

- 第一天就埋点 ，别等上线后 retrofit——后补日志抓不到中间推理步骤，也拼不出完整执行图。
- 可移植性优先 ：用 OTel GenAI semconv 命名空间，换后端只换 exporter，别被私有 schema 锁死。
- MCP 边界要闭合 ：让 MCP server 的 span 嵌套进工具 span，不要留下孤儿 trace。
- 追踪 + 评估一起上 ：没有 eval 的可观测只是昂贵的日志；采样上 10–20% 成功流量做 LLM-as-judge。
- 别只追延迟 ：把 reasoning depth、backtracks、per-tool error rate、loop count 列为 KPI。
- 选型看约束不看功能 ：自托管→Langfuse，评估→Phoenix，LangGraph 栈→LangSmith（接受锁定），高基数→Honeycomb。

一句话收口：**可观测没有最佳，只有合适。**

## 总结

本文主要介绍了 Agent 可观测的定义、第一性原理、OpenTelemetry GenAI 语义约定、四根支柱与六平台选型。重点看了 OTel 如何把链路追平、MCP 如何闭合断裂的 trace、以及「评估」为何不可或缺。

一句可迁移结论：**可观测不是「看得见的日志」，而是「能 replay、能归因、能回归」的执行图**——先上 OTel 标准埋点，再上评估闭环，平台只是把 trace 之后的活做厚。

## 关于我们

老贾探AI团队，专注企业级 RAG 知识库 / Agent 智能体 / 本体论技术拆解，定期发布相关方向的深度解读与冷思考，欢迎关注。对 KG、RAG/GRAG/OAG、Agent、Ontology 落地感兴趣，欢迎**后台私信-加入社区交流**。

**点关注

![图片](附件资源/Agent可观测思考：OpenTelemetry%20GenAI语义约定、四根支柱及六平台选型对照/img_6.gif)

****不迷路**

## 参考文献

- OpenTelemetry GenAI Semantic Conventions（专属仓库）— https://github.com/open-telemetry/semantic-conventions-genai
- OpenTelemetry GenAI semconv 文档页（迁移说明）— https://opentelemetry.io/docs/specs/semconv/gen-ai/
- Agentic AI Knowledge Base · Observability 生产最佳实践 — https://agentic-ai.readthedocs.io/en/latest/ProductionBestPractices/observability/
- What to Trace When Your AI Agent Hits Production（chanl.ai）— https://www.chanl.ai/blog/ai-agent-observability-opentelemetry-production
- AI Agent Observability in 2026（app-lab.ai）— https://app-lab.ai/blog/ai-agent-observability
- Agent Observability and Debugging（Zylos Research）— https://zylos.ai/zh/research/2026-05-29-agent-observability-debugging
- Agent Observability: Tracing Decisions and Tool Calls（technspire）— https://technspire.com/blog/agent-observability-tracing-decisions-tool-calls

---
原文链接：https://mp.weixin.qq.com/s?__biz=Mzg2ODEwNjU0Nw%3D%3D&mid=2247489493&idx=1&sn=a54380917b03cfd4e2798a78b2c0b49b&chksm=ceb03f89f9c7b69f73429fae868df1925b8509fe63854bab708f922669753d2ba726ff586cab
