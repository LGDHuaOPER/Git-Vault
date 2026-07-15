---
source_url: "https://mp.weixin.qq.com/s?search_click_id=10944039153882374254-1784128189999-2391845295&__biz=MzIwNjkwNDc1OQ==&mid=2247484275&idx=1&sn=24853f3ee14f01e7171b5e163f00a1c8&chksm=9633f28b918e73125b1f22d5f98d565aff0e9307f3f1e7a02f0c0bc551a24d98bb441488d511&subscene=0&scene=7&clicktime=1784128190&enterid=1784128190&ascene=65&devicetype=iOS26.5.2&version=18004b3c&nettype=WIFI&abtest_cookie=AAACAA==&lang=zh_CN&countrycode=CN&fontScale=100&exportkey=n_ChQIAhIQVhJqgmMZ9SaiBgmbXzaagxLhAQIE97dBBAEAAAAAAJZ8KQyW0kkAAAAOpnltbLcz9gKNyK89dVj0v9CbSoH9TBN8T7OU26/vTJpuVWIHt9jbmbPFhTre1gmjyEcYie5Sm1XjgWQ+V/3VQmnuz73kVniP5nVmDaWXIG7WFOwgUDDutcipSL2CVpCrppNZYyPhLnQhPtN8JQo7Rh48SNYfKtSXeyHrW9+ZNOy87n7Zo4mIs1Kf6T7dCTXRMwUTP+XO8x0zwkdCtxg++QYZS9mqWPUx5FOm7Hp1JJ+Pw+tt9TLJC0LWWZaq4ovZQmr0ft4w7ea4Iw==&pass_ticket=wYOb2TmmNzfySl+ixsJkHrgc4qIYm2u1IklVywjsrUYn8vwV5c431QOyDz4skRrI&wx_header=3"
title: "AI可观测性-Trace-Cost-质量三合一"
account: "程序猿架构之路"
published_at: "2026-07-01T15:32:25.000Z"
saved_at: "2026-07-15T15:09:58.758Z"
sync_id: "art_586a179084a547b0ad1bfe85b3e6a6c6"
parse_status: "ok"
---

# AI可观测性-Trace-Cost-质量三合一

#

> 🏠 返回 README ｜ ⬅️ 07-AI-Gateway-LLM网关与多模型路由.md ｜ ➡️ 03-Embedding与Reranker-选型与微调.md

> 风格说明 ：本篇是 操作型（主） ——把 Langfuse / Phoenix / Helicone 与 OpenTelemetry GenAI Semantic Conventions 对齐，构建 trace + cost + quality 三合一看板与告警。与 07-Serving FinOps、06-Eval 指标闭环。 前置阅读 ：24-Gateway（租户标签注入）；07-部署（TTFT/TPOT）。 后续展开 ：26-Embedding（embed 成本归因）。

## L1 · 是什么

### 1.1 一句话定义

**AI 可观测性**：对 LLM 应用建立 **分布式追踪 + 成本账本 + 质量评分** 的统一.telemetry 契约——让 on-call 能在 **5 分钟内** 回答「慢在哪、贵在哪、错在哪」。

### 1.2 三合一对照

| 支柱 | 回答的问题 | 核心指标 |
| --- | --- | --- |
| ** Trace ** | 哪一步慢/失败？ | span 树、TTFT、tool latency |
| ** Cost ** | 谁花了多少钱？ | /token |
| 质量 | 错误码 | ** 语义分数、幻觉 ** |
| 标准 | OpenTelemetry 通用 | ** + GenAI semconv ** |

## L2 · 原理与实现

### 2.1 OpenTelemetry GenAI Semantic Conventions

**关键 span 属性（2025 OTel gen-ai 草案口径，命名以实际 SDK 为准）**：

| 属性 | 示例 | 用途 |
| --- | --- | --- |
| `gen_ai.system` | `openai` / `anthropic` | 供应商 |
| `gen_ai.request.model` | `gpt-4o-mini` | 路由对账 |
| `gen_ai.usage.input_tokens` | `2400` | 成本 |
| `gen_ai.usage.output_tokens` | `180` | 成本 |
| `gen_ai.response.finish_reasons` | `stop` | 截断诊断 |
| `app.tenant_id` | `shop_882` | chargeback |
| `app.feature` | `checkout_assist` | 预算 |
| `app.trace.quality.faithfulness` | `0.87` | 质量 |

![](附件资源/AI可观测性-Trace-Cost-质量三合一/img_1.png)

**Spring AI 埋点（示意）**：

-
-
-
-
-

```
@Autowired ObservationRegistry registry;Observation.createNotStarted("chat.completion", registry)    .lowCardinalityKeyValue("gen_ai.request.model", "smart")    .highCardinalityKeyValue("app.tenant_id", shopId)    .observe(() -> chatClient.prompt().user(q).call());
```

### 2.2 Langfuse · Phoenix · Helicone 选型

| 产品 | 强项 | 弱项 | 电商交易推荐 |
| --- | --- | --- | --- |
| ** Langfuse ** | trace + eval + prompt 管理一体 | 自托管运维 | ** 默认主栈 ** （开源可私有化） |
| ** Phoenix (Arize) ** | 向量漂移、RAG eval | 商业功能分层 | ** RAG 质量深析 ** |
| ** Helicone ** | 代理式成本日志极快 | 依赖代理链路 | ** API 流量侧快速接入 ** |
| ** Datadog LLM ** | 与现有 APM 统一 | 单价高 | 已有 DD 的企业 |

**推荐组合**：

- Langfuse 做 trace + dataset + 在线 eval；
- Prometheus 抓 vLLM TTFT/TPOT/GPU；
- LiteLLM spend_logs 对账云账单；
- Phoenix 周度 RAG 漂移分析。

### 2.3 Trace 设计：一棵会话树

-
-
-
-
-
-
-
-
-
-

```
session_trace (root)├── guardrail_span (12ms)├── retrieve_span (85ms, top_k=8)│   ├── embed_span (22ms)│   └── vector_search_span (41ms)├── rerank_span (120ms)├── chat_span (TTFT 620ms, TPOT 38ms, tokens in/out)│   ├── tool_call get_order (45ms)│   └── tool_call get_logistics (38ms)└── async_judge_span (faithfulness 0.89)
```

**SLO 映射**：

| Span | SLO | 告警 |
| --- | --- | --- |
| retrieve P99 | 200ms 5min |
| chat TTFT P99 | 1s |
| tool error rate | 1% |
| e2e P99 | 15s |

### 2.4 Cost 账本与 Scorecard 合并

**/task P50**

**

![](附件资源/AI可观测性-Trace-Cost-质量三合一/img_2.png)

### 2.5 质量分：在线 vs 离线

**

|  |  |  | TTFT P99 | faith P50 | 拒答率 | 采纳率 |
| --- | --- | --- | --- | --- | --- | --- |
| cs_bot | 1.2M | 0.042 | 980ms | 0.86 | 3% | 54% |

| 方式 | 延迟 | 成本 | 用途 |
| --- | --- | --- | --- |
| ** 规则 ** | 实时 | 低 | 价格格式、引用存在 |
| ** LLM-as-judge ** | 秒级 | 高 | faithfulness |
| ** 人工抽检 ** | 天级 | 中 | 校准 judge |
| ** 用户反馈 ** | 实时 | 低 | 👎/转人工 |

**在线采样**：**5%** 会话异步 judge；faithfulness **<0.8** 自动打标  `quality_incident` 。

### 2.6 与 Eval Harness 闭环

-

```
线上 faithfulness P50 连续 3 天

## L3 · 边界陷阱

### 3.1 只采 trace 不算 token

- span 无 usage.* → FinOps 黑洞 ；
- Fix ：Gateway 统一注入；vLLM 用 prometheus vllm:prompt_tokens_total 。

### 3.2 PII 进 trace

- 用户手机号、地址明文 → 合规失败；
- Fix ：hash/掩码； gen_ai.prompt 默认 不记录全文 ，只记 hash + 长度。

### 3.3 质量分与业务 KPI 脱节

- faithfulness 高但 转化率降 → 评错维度；
- Fix ：scorecard 必含 采纳率/转人工/资损工单 。

### 3.4 多工具链 trace 断裂

- Langfuse + 自研日志 trace_id 不一致 ；
- Fix ：W3C traceparent 全链路透传；入口生成 trace_id 写 MDC。

### 3.5 告警风暴

- 单模型抖动 → 数百告警；
- Fix ：SLO burn rate；按 tenant/feature 分组；faithfulness 用 同比 而非绝对值。

## L4 · 架构师视角

### 4.1 可观测性成熟度

| 等级 | 能力 |
| --- | --- |
| L1 | 仅日志 + 账单 |
| L2 | OTel trace + token |
| L3 | + 在线 judge 采样 + 看板 |
| L4 | + 自动回流 Harness + 成本预算自治 |

### 4.2 Incident 响应 Runbook（5min）

- 看 三合一看板 哪一柱异常（延迟/成本/质量）；
- 下钻 trace 样本 （P99 最慢 10 条）；
- 对照 发布/路由/索引 变更日历；
- 止血：降级路由、关语义缓存、缩 prompt；
- 事后：样本进 golden + 19。

### 4.3 Datadog 与开源栈共存

- 用 OTel Collector 扇出：一路 Langfuse、一路 Datadog；
- 单一 truth 的 8k/月

→ 头部采样 + 错误全采；
- 归因后 P99 1.05s ；
- 存储降 62% 。

**(4) 落地清单**：

- Langfuse + OTel；
- retrieve_latency histogram；
- 回滚：Milvus 参数 ConfigMap。

**(5) 追问**：

- 追问 1：采样丢问题？ 错误 100% 采集 ；高价值 tenant 100%；其余 10% 随机。聚合指标用 exemplar 链接 trace。
- 追问 2：流式 token 怎么 trace？ span 记录 首 token 事件 与 complete 两事件；TPOT 由 (complete-first)/out_tokens 算出。
- 追问 3：跨服务 trace？ traceparent 从网关传入；Java Reactor 用 context 传播 （见 13-Playbook）。

### 9.2 🟧 阿里 · 三合一看板与 FinOps Chargeback

**(1) 标准答案**：**42k/月**；

- 看板查询 P95

**(4) 落地清单**：

- spend_logs ETL；
- Grafana 三合一面板；
- 月报 CSV chargeback。

**(5) 追问**：

- 追问 1：GPU 成本怎么摊？ gpu_sec × $rate 写入 chat span attribute；与 token 成本 相加 为 $/task。vLLM prometheus 导出 per-request gpu 时间 （近似用 batch 份额）。
- 追问 2：多模型比价？ 看板加 counterfactual ：若全走 fast 的 0.0008/会话 （8B judge）；
- 检测延迟 **(4) 落地清单**：

- judge worker 扩缩容；
- quality_incident 工单；
- 回滚： judge_enforced=false 仅紧急。

**(5) 追问**：

- 追问 1：judge 与线上一致？ 每月 200 条 人工校准；漂移 >5% 换 rubric 或模型。
- 追问 2：用户👎信号？ 作为 弱标签 加权，不替代 judge；👎 且 faith 高 → 查 UX 非质量 。
- 追问 3：多语言 judge？ 分语言 rubric；英文 judge 评中文 偏差大 → 禁用。

### 9.5 🟡 美团 · Phoenix 向量漂移与 RAG 质量

**(1) 标准答案**：Phoenix 看 **embedding 分布漂移** + 检索距离分布；与 faithfulness 下降 **相关性 0.8+** 时优先查索引/embedding 版本。

**(2) 原理 walk**：

-
-
-
-
-
-

```
每周:  sample 10k query embed  UMAP 对比 baseline 云图  KL 散度 > 0.12 → 告警关联:  2025-07 一次 KL 0.18 → embed 模型误升级 → faith -0.12
```

**(3) 权衡与量化**：

- 报告生成 15min ；
- 提前 3 天 发现漂移（相对人工客诉）；
- 重建索引成本 $200 vs 事故 >$50k 。

**(4) 落地清单**：

- Phoenix 定时 job；
- embedding_revision 标签；
- 链 03-RAG CI 探针。

**(5) 追问**：

- 追问 1：Langfuse vs Phoenix 分工？ Langfuse 日常 trace + eval ；Phoenix 深度 RAG 分析 。不重复建两套 trace 存储，Phoenix 可 ingest OTel。
- 追问 2：OTel semconv 变更快？ SDK pin 版本；属性 双写 旧字段 1 个季度；文档化 mapping 表。
- 追问 3：三合一看板谁维护？ 平台 SRE 维护数据管道； Applied AI 定义 faith/采纳阈值； 财务 认 $/task 定义。

## 10. 真实事故复盘（电商交易场景）· Faithfulness 骤降

### 10.1 索引漂移未进 Trace 导致质量盲点

#### S（Situation）

- 业务 ：跨境 RAG 客服， faithfulness P50 0.90 ，三合一看板 绿色 ；
- 栈 ：Langfuse + LiteLLM + Milvus + Cohere rerank；
- 告警 ：仅 TTFT 与 $/task 阈值。

#### T（Trigger）

- 2025-07-14 09:00 ：转人工率 +8% （绝对值 12%→20%）；
- 11:00 ：客服反馈「答非所问」激增；
- 14:00 ：在线 judge 抽样 faithfulness 0.74 （上周 0.89）。

#### A（Approach）

**第 1 步：Trace 显示「正常」**

-
-
-

```
retrieve P99 120ms ✓chat TTFT P99 700ms ✓cost 1.2k（一次性）P（Prevention） Scorecard 必须三柱 同屏，禁止只看 latencyembedding_revision 进每个 retrieve span Phoenix 周报进 on-call 手册 与 19-Harness 联动自动建集 OTel semconv 扩展属性 文档化关联文件 + 一句话速记避免资损估算—~80 万元文件速记07-部署TTFT/TPOT/GPU 与 $/task24-Gateway租户标签与 spend 日志06-评估faithfulness 定义19-Harness线上→离线数据集回流17-安全治理PII 与审计保留🧭 章节导航#文件风格0000-README.md索引0703-部署-模型Serving-Caching与Cost.md操作2407-AI-Gateway-LLM网关与多模型路由.md设计25本篇 · Trace / Cost / 质量操作2603-Embedding与Reranker-选型与微调.md机制+操作9898-面试高频题满分答与Checklist.md总览官方文档与源码（一级依据）L1 · 官方文档Spring AI ReferenceLangGraph InterruptsLangChain4j DocsL2 · 官方源码spring-projects/spring-ailangchain-ai/langgraphlangchain4j/langchain4jL3 · 论文 / 开放规范L3 MCP Specification
```

---
原文链接：https://mp.weixin.qq.com/s?__biz=MzIwNjkwNDc1OQ%3D%3D&mid=2247484275&idx=1&sn=24853f3ee14f01e7171b5e163f00a1c8&chksm=9633f28b918e73125b1f22d5f98d565aff0e9307f3f1e7a02f0c0bc551a24d98bb441488d511
