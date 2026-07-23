---
title: NovaFlow
category: entities
tags: [agent, observability, evaluation, alipay, framework]
sources:
  - "安全进化论: 让智能体可观察可评估可进化构建面向智能体的新一代可观测评估体系 (2026-06-15)"
summary: 支付宝面向行业 Agent 的 NovaFlow 三层可观测评估框架，聚焦在线效果、端到端链路、问题处置修复三大能力。
provenance:
  extracted: 0.70
  inferred: 0.25
  ambiguous: 0.05
base_confidence: 0.44
lifecycle: draft
lifecycle_changed: 2026-07-22
tier: supporting
created: 2026-07-22T00:00:00+08:00
updated: 2026-07-22T00:00:00+08:00
relationships:
  - target: "[[concepts/ai-agent-observability]]"
    type: implements
  - target: "[[concepts/agent-data-flywheel]]"
    type: uses
  - target: "[[concepts/llm-as-judge-evaluation]]"
    type: uses
---

# NovaFlow

**NovaFlow** 是支付宝提出的面向行业 Agent 的可观测评估工程框架，将"可观察、可评估、可进化"作为 Agent 生产化的三大核心能力，围绕 "Benchmark（考纲）+ User Simulator（考题）+ Judge Model（考官）" 构建闭环。

## 三层破局框架

| 层级 | 目标 | 关键动作 |
|---|---|---|
| 在线效果可观测 | 实时评测 + 自动归因 = 质量闭环 | 流量自动化标准化评估，Badcase 实时发现并归因到具体子节点 |
| 端到端链路可观测 | 白盒化透视思考路径 | 语义节点建模，统一可观测视图，所有角色看到同一份数据链 |
| 问题处置修复可观测 | 可归因、可进化 | 问题自动归因与定责，数据驱动策略持续迭代 |

## 行业 RAG 亿级知识库支撑

- **多索引知识平台**：支持 BM25、Embedding、Sparse 多种索引；新数据零代码接入；在线 RAG 策略控制，请求增强并发多路检索
- **Deep Research Agent**：针对缺失 Query 深入调研补充业务数据；Function Calling + ReAct 机制智能选择工具

## 五类关键语义节点

NovaFlow 将 Agent 执行过程抽象为五类语义节点，超越传统函数级 Tracing：

1. RAG 全链路节点执行数据（多路检索、精排粗排）
2. LLM 意图、改写、抽槽数据
3. LLM Planning 的 CoT 数据与决策结果
4. Tools 的执行数据
5. LLM Summary 的最终输出

## 实测数据

| 指标 | 数值 |
|---|---|
| 分析数据总量 | 40.44 万条 |
| Badcase 数量（3 月） | 19.65 万条（≈20%） |
| Badcase 率（4 月 7 日） | 2.73% |
| 知识缺失占 Badcase 比 | 24% |
| Badcase 自动修复率 | 23% |
| 归因更新策略 | T+1 自动化 |

## 四条自进化链路

1. **Badcase 自修复链路**：自动采集线上 Badcase → T+1 归因定位知识缺失 → 自动触发 Deep Search 生成并上线正确知识 → 闭环验证
2. **缺失召回补全链路**：针对未命中 Query 自动生成知识，T+1 更新知识库
3. **知识保鲜巡检链路**：自动更新或淘汰过期内容，多智能体协同捕获热点
4. **PDCA 完整迭代循环**：效果评估 → 链路归因分析 → 修复计划 → 验证 → 发布

## Related

- [[references/2026-06-15-aidd-nova-flow-agent-observability]] — 来源演讲实录
- [[concepts/ai-agent-observability]] — Agent 可观测性范式
- [[concepts/agent-data-flywheel]] — 数据飞轮与自进化闭环
- [[concepts/llm-as-judge-evaluation]] — LLM-as-Judge 评估