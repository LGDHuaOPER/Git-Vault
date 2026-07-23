---
title: 生成式 AI 可观测性 2.0
category: concepts
tags:
  - ai-agent
  - observability
  - cost-management
  - safety
  - quality
  - llm-as-judge
sources:
  - "腾讯云架构师技术同盟: 生成式 AI 可观测性 2.0：成本、安全、质量三大支柱 (2026-06-24)"
summary: 面向 LLM 和 AI Agent 的新一代可观测范式，在传统 APM 之外新增成本、安全、质量三大支柱，解决"响应成功不等于业务正确"的核心问题。
provenance:
  extracted: 0.70
  inferred: 0.25
  ambiguous: 0.05
base_confidence: 0.58
lifecycle: draft
lifecycle_changed: "2026-07-22"
tier: supporting
created: "2026-07-22"
updated: "2026-07-22"
relationships:
  - target: "[[concepts/ai-agent-observability]]"
    type: extends
  - target: "[[concepts/llm-as-judge-evaluation]]"
    type: uses
  - target: "[[concepts/agent-cost-breakdown]]"
    type: related_to
  - target: "[[concepts/agent-failure-taxonomy]]"
    type: related_to
---

# 生成式 AI 可观测性 2.0

**生成式 AI 可观测性 2.0** 是面向 LLM 和 AI Agent 的新一代可观测范式。微服务时代靠延迟、错误率、流量、饱和度四个指标就能安稳，但引入 LLM 后，这四个指标变成了陷阱——因为 LLM 可能一本正经胡说八道，同时返回结构完美的 JSON 和标准 HTTP 200。

## 核心洞察：监控为什么失效

传统基础设施监控只能回答"系统是否在运行"，无法回答"运行得是否正确"。LLM 陷入死循环疯狂消耗 Token 时，网关吞吐正常、微服务延迟极低、错误率 0% ^[extracted]。

**响应成功不再等同于业务正确。** 因此需要三根新支柱：成本、安全、质量。

## 支柱一：成本

### Token 计费带来的新风险

传统云原生架构中突发流量顶多导致算力扩容；但 LLM 成本按 Token 线性计算，衍生出两类新风险 ^[extracted]：

| 风险 | 说明 |
|------|------|
| **钱包拒绝服务攻击（Denial of Wallet）** | 恶意用户构造循环 Prompt 或滥用工具链诱导高频无限调用，API 额度几小时内被掏空 |
| **模型漂移** | 模型版本更新时 Token 吞吐和 Prompt 消耗规律可能质变，微小提示词不兼容可能引发多轮重试，账单隔夜暴涨 8-10 倍 |

### 应对方式

1. **Token 配额与断路器**：在网关层实现基于用户/租户维度的窗口期 Token 计数，某会话 1 分钟内超过阈值直接熔断
2. **工具调用预算**：为单次请求的 Agent 思考链设置最大深度，比如底层 API 调用不超过 N 次

## 支柱二：安全

传统攻击是确定性的（SQL 注入、XSS），而大模型面对的是自然语言模糊攻击：越狱、提示词注入、模型发散性导致的数据泄露。静态防火墙解析不了 Prompt 语义，需要在 Agent 输入和输出端各架一道语义护栏 ^[extracted]。

### 输入端护栏

- 实时扫描用户 Prompt
- 使用轻量级安全模型（如 Llama-Guard）或向量匹配检测越狱尝试和提示词注入

### 输出端护栏

- 对模型生成文本做正则与 NER 混合扫描
- 身份证号、信用卡、内部代码片段、敏感密钥一旦出现立即脱敏或拦截

## 支柱三：质量

人工刷日志成本极高且无法实时。可观测性 2.0 引入 **LLM-as-a-Judge** 机制，重点观测两个硬核指标（参考 RAGAS 框架） ^[extracted]：

| 指标 | 定义 |
|------|------|
| **上下文相关性（Context Relevance）** | 检索出来的知识是否真能回答用户问题，防止喂垃圾信息得垃圾输出 |
| **忠实度（Faithfulness）** | 模型回答是否有严谨依据来源于检索上下文；若包含上下文中没有的字段或数字，判定为幻觉 |

### 近线打分机制

将用户请求、检索上下文和模型回答拷贝推到 Kafka，由后置评估服务打分。示例 Judge Prompt ^[extracted]：

```
你是一个严谨的架构审计员。请根据提供的【上下文】，评估【AI回答】是否完全基于事实。
如果有任何一句回答是上下文中未提及的，或者矛盾的，请将其判定为"有幻觉"。
请输出 JSON 格式：{"faithfulness_score": 0.0到1.0, "reason": "原因"}
```

在 Grafana 上绘制系统幻觉率趋势图和回答质量水位线，平均得分低于 0.8 触发工程告警。

## 三根支柱的关系

成本、安全、质量三根支柱撑起来，Agent 才能从实验环境走到生产环境。每根支柱都不复杂，难的是三根一起建 ^[extracted]。

## 相关页面

- [[concepts/ai-agent-observability]] — AI Agent 可观测性整体概念
- [[concepts/llm-as-judge-evaluation]] — LLM-as-Judge 评估方法论
- [[concepts/agent-cost-breakdown]] — Agent 成本构成与优化
- [[concepts/agent-failure-taxonomy]] — Agent 失败分类
- [[concepts/rag-observability]] — RAG 可观测性
