---
source_url: "https://mp.weixin.qq.com/s?search_click_id=2577446274891197028-1784693167977-3465633198&__biz=MzIxMjc3MzgwMA==&mid=2247484209&idx=1&sn=2c24556ef1009d1976c72b79a1fc709e&chksm=96b6386ff282230185e80e84f66f95ce6c5e34a0cb4fc54890aeda47a8f69568dae66d742fa6&subscene=90&scene=7&clicktime=1784693167&enterid=1784693167&ascene=65&devicetype=iOS26.5.2&version=18004b42&nettype=3G+&abtest_cookie=AAACAA==&lang=zh_CN&countrycode=CN&fontScale=100&exportkey=n_ChQIAhIQFoFHPw/QC6FLBzGi/l1oMxLhAQIE97dBBAEAAAAAAB2fAG5rQJkAAAAOpnltbLcz9gKNyK89dVj0y5JkEYxUsBCiMKiXjcpkg7pDKeA78R+RI4ioLpV3omKORZ8Skfpg0RDnLcwjtHbXmse56E6RP6Tjyw/pP5Q/GZdEtmmCERx7T0YjRwBrAw3rvHfu+HPwqaKprPA48H6DIGeN4D7ZVYHfw1fHghaUjC3b5XmDFO5oI1OlIGoHp6FWqOgzpoeo9J1dKsnHetNP5MrOn1U8WXPe+Ij9EWKMXgfXXUr4B2RzgP7IsYBNCz03qcMJQTVUFQ6ChA==&pass_ticket=84/OZmSd6b5Y2Mdvg+NUo0nMBDbde+ojRPFYw4rkbTuwcq+mawi5CUoZornqo5di&wx_header=3"
title: "给 AI Agent 装上行车记录仪：Langfuse 可观测性完全指南"
account: "comqx技术杂货铺"
published_at: "2026-07-14T13:29:13.000Z"
saved_at: "2026-07-22T04:06:16.599Z"
sync_id: "art_f46c209f6bb74221accc40214ea0437e"
parse_status: "ok"
---

# 给 AI Agent 装上行车记录仪：Langfuse 可观测性完全指南

## 给 AI Agent 装上行车记录仪：Langfuse 可观测性完全指南

| 关注「Comqx」公众号，并设为「星标」，第一时间获取更多 LLM 工程实践文章。 ** 温馨提示 ** 本文约 3300 字，预计阅读 11 分钟。微信公众号阅读可能存在代码排版不佳等问题，建议收藏后对照代码食用。 |
| --- |

**目 录**

一、为什么 LLM / Agent 需要可观测性

二、Langfuse 是什么

三、数据模型与工作原理（Trace / Observation）

四、它与同类工具的差异

五、基础用法：30 分钟接入

六、进阶能力：不止于看链路

七、项目实践：可观测的 RAG Agent

八、总结与选型建议

先直接回答你的问题：**Langfuse 确实是一类面向智能体（Agent）和工作流的可观测性技术，但它不止于此**——它把自己定位为「开源的 LLM 工程平台」，把可观测性（Tracing）、评估（Evaluation）、提示词管理（Prompt）、实验（Experiments）和人工标注（Human Annotation）串成一条从原型到生产的持续迭代闭环。可观测性是它最基础、最核心的那一层，也是理解其余能力的总入口。

![](附件资源/给%20AI%20Agent%20装上行车记录仪：Langfuse%20可观测性完全指南/img_1.png)

═════════

## 一、为什么 LLM / Agent 需要可观测性

传统 APM（如 Datadog、SkyWalking）为「请求—响应」周期设计：输入确定、输出确定、延迟可预测。但 LLM 应用不是这样，它有三个让旧工具失灵的特征：

- 黑盒调用 ：一个 Agent 任务背后是一次「意图识别 → 知识检索 → 工具调用 → 安全校验 → 生成回答」的复杂链路，任一步出错都只表现为「回答不好」，故障定位极难。
- 非确定性 ：同样的输入，模型可能给出不同输出；质量无法靠肉眼批量判断，必须量化。
- 成本不可见 ：Token 消耗、跨模型调用、多轮会话，成本像水一样漏出去，没有人知道漏在哪一环。

可观测性的本质，就是把每一次模型调用、工具调用、检索步骤、评估结果，都结构化地记录成一条可下钻、可过滤、可度量的「Trace」，从而让调试从「感觉哪里不对」变成「检索那一步返回了无关文档，导致合成阶段多用了 3 倍 Token」。

═════════

## 二、Langfuse 是什么

Langfuse 是一个 **MIT 协议开源、可自托管、框架无关** 的 LLM 工程平台，核心基于 **OpenTelemetry（OTel）** 标准。它的官方定位是「Trace and evaluate AI Agents」——直接把 Agent 放在主语位置。

它有六个一体化模块，自上而下构成完整闭环：

| 模块 | 解决什么 | 关键能力 |
| --- | --- | --- |
| 可观测性 Observability | 链路口径黑盒 | 层级 Trace、按用户/会话/成本/延迟过滤、Agent 图可视化 |
| 评估 Evaluation | 质量无量化 | LLM-as-a-judge、启发式函数、人工评审 |
| 提示词管理 Prompt | Prompt 散落代码 | 版本控制、一键部署/回滚、Playground |
| 实验 Experiments | 改了不敢发 | 数据集批量跑、新旧版本并排对比 |
| 人工标注 Annotation | 黄金样本缺失 | Human-in-the-Loop、从 Trace 一键沉淀数据集 |
| 成本与延迟 Cost | 花了多少不知道 | 仪表板、自动化告警 |

对于你关心的「智能体、工作流」，Langfuse 做了专门适配：**多轮对话可作为一个 Session 追踪；Agent 的执行可被可视化为图结构**，清楚展示规划、检索、工具、生成之间的流转。它原生支持 Python/JS SDK，并通过 100+ 集成（LangChain、Vercel AI SDK、Pydantic AI、Claude Agent SDK、Dify、n8n、LiteLLM 等）降低接入成本。

═════════

## 三、数据模型与工作原理（Trace / Observation）

理解 Langfuse，关键在于理解它的两个核心概念：**Trace** 和 **Observation**。

- Trace（追踪） ：一次完整的用户会话或 Agent 任务，是观察的根节点。可以挂载 user_id 、 session_id 、业务场景等自定义元数据。
- Observation（观测） ：Trace 内部的细分步骤，分三类：
- Generation ：一次 LLM 调用，自动记录模型名、Token、温度等参数；
- Span ：一次工具调用、检索、函数执行等非 LLM 步骤；
- Event ：轻量事件标记。

每个 Observation 都会自动记录：耗时、输入/输出文本、Token 消耗、模型名称、自定义 metadata。你还能往 Trace 上  `Score` （打分），把质量量化为一个数值。

![](附件资源/给%20AI%20Agent%20装上行车记录仪：Langfuse%20可观测性完全指南/img_2.png)

底层存储采用**双存储模型**：PostgreSQL 存结构化元数据（Trace、Prompt、评估、用户、项目），ClickHouse 存海量时序遥测（每条 Observation 事件、Token 数、延迟）。列存压缩让它在百万级 Span 上做聚合查询依然秒级。SDK 全程异步上报，**几乎不给业务增加延迟**，且 SDK 自身报错会被捕获，绝不会拖垮你的主流程。

═════════

## 四、它与同类工具的差异

LLM 可观测赛道已经比较拥挤，选错工具会造成调试盲区、成本不透明或框架锁定。三款主流工具的差异如下：

![](附件资源/给%20AI%20Agent%20装上行车记录仪：Langfuse%20可观测性完全指南/img_3.png)

- Langfuse ：最强开源选项。MIT 协议、可自托管、数据完全自主可控；框架无关，OTel 原生；追踪 + 评估 + 提示词管理均衡。弱点是 LangChain 专有功能不如 LangSmith 精致，仪表板 UX 仍在快速追赶。
- LangSmith ：LangChain 团队出品，对 LangChain/LangGraph 追踪近乎零配置，Prompt Hub 成熟；但闭源、仅云端、强绑定 LangChain。
- Helicone ：代理层（改一行 BaseURL 即可接入），成本监控最强、上手最快；但只到请求级，拿不到复杂 Agent 循环的 Span 级粒度。

同赛道还有 **Phoenix（Arize，OTel 原生开源，适合 RAG）**、**Braintrust（评估优先，CI 质量门禁）**、**Portkey（AI 网关 + 治理）**。一句话选型：**要开源/自托管选 Langfuse，纯 LangChain 选 LangSmith，只要看成本且求快选 Helicone。**

═════════

## 五、基础用法：30 分钟接入

Langfuse 提供三种埋点方式：原生 SDK、 `@observe`  装饰器自动追踪、以及 OpenTelemetry / 框架集成。最推荐  `@observe()`  装饰器——零侵入、自动嵌套。

### 5.1 安装与凭证

```
bash
pip install langfuse
```

```
bash
# .env 配置文件，密钥与代码分离export LANGFUSE_PUBLIC_KEY="pk-lf-xxx"export LANGFUSE_SECRET_KEY="sk-lf-xxx"export LANGFUSE_BASE_URL="https://cloud.langfuse.com"   # 自托管改为你的地址
```

### 5.2 最小可运行示例

下面用装饰器自动追踪一个 RAG 流程：外层函数自动成为 Trace 根节点，内部调用自动嵌套为子 Observation， `as_type="generation"`  会额外记录模型和 Token。

```
python
from langfuse import observe, get_client # 检索步骤：自动作为一个 Observation 被追踪@observe()def retrieve_docs(query: str) -> str:    return f"关于'{query}'的相关文档内容..." # 标记为 LLM 调用，记录模型与 Token@observe(name="llm-answer", as_type="generation")def generate_answer(context: str, question: str) -> str:    return f"基于上下文的回答:{context[:20]}..." # 外层函数自动成为 Trace 的根节点@observe()def rag_pipeline(question: str) -> str:    context = retrieve_docs(question)    answer = generate_answer(context, question)    return answer result = rag_pipeline("什么是向量数据库?")print(f"回答:{result}")# 短生命周期脚本必须 flush，确保数据发送完毕get_client().flush()print("[DONE] 追踪数据已发送到 Langfuse")
```

执行结果如下：

```
plaintext
回答:基于上下文的回答:关于'什么是向量数据库?'的相关文档...[DONE] 追踪数据已发送到 Langfuse
```

打开 Langfuse 面板，你会看到一条 Trace，内部整齐地嵌套着  `retrieve_docs`  的 Span 和  `generate_answer`  的 Generation，耗时、输入输出一目了然。

![](附件资源/给%20AI%20Agent%20装上行车记录仪：Langfuse%20可观测性完全指南/img_4.png)

如果你用 LangChain，只需传入  `LangfuseCallbackHandler`  即可自动捕获 Chain / Agent 链路；用 LiteLLM 则走统一网关埋点，兼容 Ollama、Bedrock、Gemini。对 Claude Agent SDK、Dify、n8n 等也都有开箱集成。

═════════

## 六、进阶能力：不止于看链路

当链路数据积累起来，Langfuse 的价值才真正释放。

### 6.1 自动化评估（LLM-as-a-judge）

与其靠人肉看 Bad Case，不如配置评估器，对每条生产 Trace 自动打分（正确性、贴合度、话术友好度等），分数沉淀进 Trace，生成全局质量趋势。

```
python
# 给一条 Trace 打分，可叠加多个评估维度trace.score(name="helpfulness", value=0.9, comment="回答准确且友好")
```

### 6.2 提示词管理 + A/B

Prompt 从代码里抽离出来，在 UI 里版本化、一键部署到「production」标签，出问题一键回滚。通过  `user_id`  哈希做稳定分桶，把 20% 流量路由到 candidate 版本，对比两组的 Score 分布做数据驱动的 promotion 决策。

```
python
# 从 Langfuse 拉取受版本管理的 Prompt，无需改代码prompt = langfuse.get_prompt("support-answer", version=2)compiled = prompt.compile(customer_name="Alice", question="如何重置密码?")
```

### 6.3 数据集与实验

把生产中的失败样本、人工标注的边界问题，一键存成 Dataset（黄金测试集）；在 Experiments 里批量跑新旧 Prompt / 不同模型，并排对比「平均延迟、总成本、各评估平均分、错误样本数」，用数据判断是否上线——这就是「观察 → 沉淀 → 实验 → 部署」的迭代闭环。

### 6.4 MCP Server

Langfuse 自带原生 MCP Server（ `/api/public/mcp` ），把提示词管理能力暴露给 Claude Desktop、Cursor 等支持 MCP 的客户端。AI 编码助手能直接拉取最新生产版 Prompt，减少版本漂移。

═════════

## 七、项目实践：可观测的 RAG Agent

### 7.1 项目概述

目标：搭一个带检索的 Agent，让它的每一步（规划、检索、工具、生成）都自动进入 Langfuse，并在运行后触发一次 LLM 评估，验证「可观测 → 可评估」闭环。

### 7.2 系统架构

![](附件资源/给%20AI%20Agent%20装上行车记录仪：Langfuse%20可观测性完全指南/img_5.png)

### 7.3 环境准备

- 注册 Langfuse Cloud（或 Docker Compose 自托管）拿到 Key；
- 按 5.1 写好 .env ；
- pip install langfuse openai 。

### 7.4 核心代码实现

```
python
import osfrom langfuse import observe, get_clientfrom openai import OpenAI client = OpenAI()  # 读取 OPENAI_API_KEY @observe(as_type="retrieval")          # 检索步骤def retrieve(query: str) -> list:    # 这里接你的向量库，demo 用假数据    return [f"doc about {query}"] @observe(name="llm-call", as_type="generation")def answer(query: str, docs: list) -> str:    resp = client.chat.completions.create(        model="gpt-4o-mini",        messages=[{"role": "user", "content": f"{query}\n上下文:{docs}"}],    )    return resp.choices[0].message.content @observe()                              # Trace 根节点def agent(query: str) -> str:    docs = retrieve(query)    return answer(query, docs) if __name__ == "__main__":    out = agent("Langfuse 能自托管吗?")    print("Agent 回答:", out)    get_client().flush()
```

### 7.5 运行结果

执行后，Langfuse 面板会展示一条以  `agent`  为根的 Trace 树： `retrieve`  作为检索 Span、 `llm-call`  作为 Generation 并列其中，各自的耗时、Token、输入输出都可下钻。此时再追加一个  `score`  调用，就能把这条 Trace 纳入质量评估体系，后续可一键存为 Dataset 做回归实验。

| 提示：高流量场景用采样（如 `TRACE_SAMPLE_RATE=0.1` ）控制成本，但 ** 错误样本务必 100% 全量追踪 ** 。 |
| --- |

═════════

## 八、总结与选型建议

回到你最初的问题——**Langfuse 是针对智能体和工作流的可观测性技术吗？是的，而且它是目前开源阵营里最均衡的选择**：基于 OTel、框架无关、可自托管，把「看链路」延伸成「评估 → 实验 → 迭代」的完整 LLM 工程闭环。

给不同团队的三条建议：

- 数据合规 / 多框架栈 / 成本敏感 ：无脑选 Langfuse 自托管，数据留在自己机房，规模化后成本趋近于零（只付服务器）。
- 深度绑定 LangChain/LangGraph ：LangSmith 的零配置追踪体验更好，但接受闭源与云端锁定。
- 只想最快看到成本 ：Helicone 一行代理即接入，但拿不到 Agent 循环的 Span 级粒度。

想动手？最快路径是注册 Langfuse Cloud 免费额度，用  `@observe()`  装饰器埋一个最小脚本，三分钟看到第一条 Trace——这就是你 Agent 的「行车记录仪」第一帧。

| 如果本文对你有帮助，欢迎关注「Comqx」并在评论区聊聊：你的 Agent 现在用什么做可观测性？遇到过最离谱的「黑盒 Bug」是什么？ |
| --- |

---
原文链接：https://mp.weixin.qq.com/s?__biz=MzIxMjc3MzgwMA%3D%3D&mid=2247484209&idx=1&sn=2c24556ef1009d1976c72b79a1fc709e&chksm=96b6386ff282230185e80e84f66f95ce6c5e34a0cb4fc54890aeda47a8f69568dae66d742fa6
