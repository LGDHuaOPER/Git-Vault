---
title: "AIDD 2026 | 让智能体可观察可评估可进化：面向智能体的新一代可观测评估体系"
category: references
tags: [agent, observability, evaluation, alipay, nova-flow]
sources:
  - "安全进化论: 让智能体可观察可评估可进化构建面向智能体的新一代可观测评估体系 (2026-06-15)"
summary: 支付宝 AIDD 2026 演讲实录，提出 NovaFlow 三层破局框架，将 Agent 可观测从"系统健康"升维到"答对才是唯一健康指标"。
provenance:
  extracted: 0.72
  inferred: 0.23
  ambiguous: 0.05
base_confidence: 0.44
lifecycle: draft
lifecycle_changed: 2026-07-22
tier: supporting
created: 2026-07-22T00:00:00+08:00
updated: 2026-07-22T00:00:00+08:00
relationships:
  - target: "[[entities/nova-flow]]"
    type: related_to
---

# AIDD 2026 | 让智能体可观察可评估可进化：面向智能体的新一代可观测评估体系

支付宝架构师高梦飞在 AIDD 2026 上海峰会的演讲实录，系统阐述 Agent 时代可观测性的范式转变与工程实践。

## 核心论点

传统微服务可观测在 Agent 时代遭遇**三大水土不服**：

- **链路错位**：Agent 循环调用、回退的决策路径无法用线性 Trace 表达
- **指标失灵**：系统不报错、延迟低，但 Agent 可能"一本正经地胡说八道"
- **黑盒困境**：LLM 中间推理步骤不可见，无法定位逻辑错误与幻觉

因此，Agent 的健康标准必须重新定义：**答对，才是唯一的健康指标**。

## NovaFlow 三层破局框架

| 层级 | 目标 | 关键能力 |
|---|---|---|
| 在线效果可观测 | 实时评测 + 自动归因 | 流量自动化标准化评估，Badcase 归因到子节点 |
| 端到端链路可观测 | 白盒化思考路径 | 语义节点建模，统一可观测视图 |
| 问题处置修复可观测 | 可归因、可进化 | T+1 自动归因与定责，数据驱动策略迭代 |

## 技术实践亮点

- **行业 RAG 亿级知识库**：支持 BM25 / Embedding / Sparse 多索引，新数据零代码接入，亿级数据千万小时级导入
- **五类关键语义节点**：RAG 执行、LLM 意图/改写/抽槽、LLM Planning CoT、Tools 执行、LLM Summary
- **评测平台实测数据**：分析数据总量 40.44 万条，3 月 Badcase 19.65 万条（≈20%），4 月 7 日 Badcase 率降至 2.73%，知识缺失占 Badcase 24%
- **T+1 自动化归因更新**，Badcase 自动修复率达 **23%**

## 四条自进化链路

1. **Badcase 自修复链路**：自动采集 → T+1 归因 → Deep Search 生成正确知识 → 闭环验证
2. **缺失召回补全链路**：针对未命中 Query 自动生成知识，T+1 更新知识库
3. **知识保鲜巡检链路**：多智能体协同捕获热点，自动更新或淘汰过期内容
4. **PDCA 完整迭代循环**：效果评估 → 归因分析 → 修复计划 → 验证 → 发布

## Related

- [[entities/nova-flow]] — NovaFlow 框架详解
- [[concepts/ai-agent-observability]] — Agent 可观测性范式转变
- [[concepts/agent-data-flywheel]] — 数据飞轮与自进化闭环
- [[concepts/llm-as-judge-evaluation]] — LLM-as-Judge 评估方法论