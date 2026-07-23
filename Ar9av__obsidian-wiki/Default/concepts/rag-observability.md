---
title: RAG Observability
aliases:
  - RAG 可观测性
  - RAG Observability
category: concepts
tags:
  - ai-agent
  - observability
  - rag
  - retrieval
  - evaluation
sources:
  - "祥聊AI: AI Agent 可观测性：看不见的链路，才是最贵的技术债 (2026-04-12)"
  - "智枢圈: [理论篇-14]大模型评估与可观测性——如何知道你的 AI 到底行不行 (2026-05-11)"
  - "机器之魂: LLM 可观测性：大多数生产级 AI 系统中缺失的那一层（完整指南） (2026-04-17)"
summary: RAG 可观测性将检索层作为独立观测对象——覆盖检索输入、召回结果、重排结果、引用片段四个信号层，以及 Context Precision、Faithfulness、Answer Relevance 三个 RAGAS 核心指标。RAG 质量是生产环境中最常被低估的故障源。
base_confidence: 0.55
lifecycle: draft
lifecycle_changed: "2026-07-22"
tier: supporting
provenance:
  extracted: 0.60
  inferred: 0.30
  ambiguous: 0.10
created: "2026-07-22"
updated: "2026-07-22"
relationships:
  - target: "[[concepts/ai-agent-observability]]"
    type: extends
  - target: "[[concepts/agent-evaluation-framework]]"
    type: related_to
  - target: "[[concepts/llm-as-judge-evaluation]]"
    type: related_to
  - target: "[[entities/arize-phoenix]]"
    type: related_to
  - target: "[[entities/langfuse-llm-observability]]"
    type: related_to
  - target: "[[entities/langsmith]]"
    type: related_to
---

# RAG Observability

RAG 可观测性将检索增强生成（RAG）层作为 Agent 可观测体系中的**独立观测对象**。大量 Agent 输出质量差，根因不在模型推理，而在输入给模型的上下文就是错的——检索没命中、召回质量差、知识库过期。Arize AI 在 2024 年的 LLM Observability 报告中指出，**RAG 质量是生产环境中最常被低估的故障源**。^[extracted]

## 为什么 RAG 层必须单独看

一个典型场景：用户问了一个运维知识问题，Agent 回答得驴唇不对马嘴。团队第一反应是"模型不够强"或"提示词不够好"。但如果能看到 RAG 检索的中间结果，很可能会发现 ^[extracted]：

- 检索压根就没命中正确的文档片段
- 命中了，但召回排序不对，正确答案排在第 5 条，而只取了 Top 3
- 命中了正确文档，但文档本身已经过期

这些问题，换再贵的模型也解决不了。没有对 RAG 层的独立观测，就会一直在"调提示词 → 没效果 → 再调 → 还是没效果"的循环里。

## 四层观测信号

RAG 可观测性需要在链路的四个关键节点埋点 ^[extracted]：

| 观测节点 | 核心问题 | 关键信号 |
|---------|---------|---------|
| **检索输入** | 用户 query 经过何种改写？ | 原始 query、改写后 query、改写策略 |
| **召回结果** | 返回了哪些文档片段？ | 文档 ID 列表、相似度得分分布、召回数量 |
| **重排结果** | rerank 后的排序变化？ | 重排前后排序对比、重排模型版本 |
| **引用片段** | 最终送给 LLM 的上下文是什么？ | 上下文本内容、Token 数、来源文档 ID |

有了这些数据，才能判断：是检索策略要调，还是知识库要更新，还是 rerank 模型要换。^[extracted]

## RAG 评估三板斧（RAGAS 框架）

RAGAS 框架定义了 RAG 评估的三个核心指标 ^[extracted]：

### ① Context Precision（上下文精确率）
检索到的文档片段中，有多少是真正相关的？衡量的是**检索质量**——图书馆找资料，找到的书有几本是有用的。

### ② Faithfulness（忠实性）⭐ 最核心指标
AI 回答的每个论点是否都能在检索到的文档里找到依据？衡量的是**有没有编造**——写论文时，每个引用是否都真实存在。

### ③ Answer Relevance（回答相关性）
回答是否真正回答了用户的问题？衡量的是**有没有跑题**——问"今天天气"答"气温 25 度" ✅ 相关，答"巴黎很美" ❌ 不相关。

其中，忠实性和检索相关性**不需要**精心策划的参考答案，可以在每个生产请求上运行，无需数据集。^[extracted]

## 静默检索失败

向量搜索可能在**不抛出任何错误**的情况下返回错误结果。检索器获取了与查询共享词汇但并未回答查询的片段。模型读取这些片段并产生一个听起来合理但错误的响应。没有异常触发，错误率保持为零。^[extracted]

一个具体例子：用户问"[[entities/langsmith|LangSmith]] 评估是如何工作的？"，检索器获取了"LangChain 智能体概述""嵌入介绍""通用 LLM 评估指标"——这些都没有解释 LangSmith 实际的评估 API。模型仍然读取并回答了。请求返回 HTTP 200，没有警报触发。有了 Trace，可以在三十秒内定位问题出在检索器而非模型；没有 Trace，只能猜测。^[extracted]

## RAG 可观测性在 Agent 链路中的位置

在 Agent 的完整请求链路中，RAG 是一个独立的观测节点 ^[extracted]：

```
用户请求
→ Gateway（鉴权/路由/限流）
→ Engine（Agent 编排/规划/推理）
→ Tool/MCP 调用（外部工具执行）
→ RAG 检索（知识检索/向量匹配）← 独立观测层
→ LLM 调用（模型推理）
→ 结果聚合
→ 响应用户
```

RAG 节点的 Span 需要携带的关键属性：检索延迟、召回数量、命中率、重排前后排序变化、引用片段 Token 数。^[extracted]

## 效果退化与知识保鲜

RAG 系统的特殊挑战在于知识库本身会持续变化 ^[extracted]：

| 退化原因 | 表现 | 应对 |
|---------|------|------|
| **知识过期** | 文档更新了但评估数据没更新 | 文档和评估数据同步更新 |
| **数据漂移** | 用户问的问题类型发生了变化 | 新问题及时补充到评估数据集 |
| **Embedding 漂移** | 向量空间分布随时间变化 | 定期重建索引，监控检索质量基线 |

支付宝 NovaFlow 的知识保鲜巡检链路：自动更新或淘汰过期内容，多智能体协同自动捕获新闻热点，实现高时效知识精准入库。^[extracted]

## 工具生态

| 工具 | RAG 观测能力 | 特点 |
|------|-------------|------|
| **[[entities/arize-phoenix|Arize Phoenix]]** | RAG 诊断（哪些 chunk 真的有用）、Embedding drift UMAP 可视化 | 评估模板最丰富、RAG 分析最强 ^[extracted] |
| **[[entities/langfuse-llm-observability|Langfuse]]** | Trace 中包含检索步骤，支持按检索质量过滤 | 开源、OTel 原生、数据自有 |
| **LangSmith** | 检索器标记为独立运行（`run_type="retriever"`），与 LLM 步骤同级展示 | LangChain 一等公民 |

## 相关页面

- [[concepts/ai-agent-observability]] — 可观测体系总览（RAG 是其中的独立观测层）
- [[concepts/agent-evaluation-framework]] — 评测框架（RAG 评估三板斧的评分实现）
- [[concepts/llm-as-judge-evaluation]] — LLM-as-Judge（Faithfulness 评估的核心方法）
- [[concepts/agent-trace-and-timeline]] — Trace 结构（RAG Span 在 Trace 中的位置）
