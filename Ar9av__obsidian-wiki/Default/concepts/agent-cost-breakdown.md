---
title: "Agent Cost Breakdown"
category: concepts
tags:
  - ai-agent
  - observability
  - cost-management
  - token-economics
sources:
  - "小加号编程笔记: AI Agent 可观测性：如何记录推理、工具调用、失败与成本 (2026-07-13)"
  - "ThinkingAgent: AI安全和治理：AI Observability、Evaluation、治理、安全与成本 (2026-06-28)"
summary: "Agent 系统成本的四大构成（输入Token/输出Token/工具费用/重试浪费）及其观测方法，包括成本归因、智能路由降本、多租户计费模式。"
base_confidence: 0.73
lifecycle: draft
lifecycle_changed: "2026-07-16"
tier: supporting
provenance:
  extracted: 0.7
  inferred: 0.2
  ambiguous: 0.1
created: 2026-07-16
updated: 2026-07-16
---

# Agent Cost Breakdown

## 成本四层模型

Agent 的成本远不止一次模型调用的费用。它由四部分组成 ^[extracted]：

| 成本来源 | 说明 | 典型占比 |
|---------|------|---------|
| 输入 Token | 系统指令、用户输入、历史摘要、RAG 文档、工具结果 | 40-60% |
| 输出 Token | 模型生成的计划、回答、工具参数 | 20-30% |
| 工具成本 | 搜索 API、数据库查询、代码执行、第三方服务 | 10-20% |
| 重试成本 | 模型重试、工具重试、格式修复、反思再执行 | 10-30% |

## 成本失控的常见模式

很多 Agent 成本失控不是因为单次模型贵，而是循环和重试 ^[extracted]。一次看似简单的用户提问，背后可能发生：

- 4 次 LLM 调用（规划 + 推理 + 工具决策 + 总结）
- 6 次检索（向量搜索 + 重排序）
- 3 次工具调用（API + 数据库 + 文件读取）
- 2 次 JSON 格式修复重试
- 每次都携带 20KB 历史上下文

## 核心观测指标

至少需要记录的指标：

| 指标 | 用途 |
|------|------|
| `agent_run_cost_total` | 单次任务总成本 |
| `llm_input_tokens_total` | 输入 Token 消耗 |
| `llm_output_tokens_total` | 输出 Token 消耗 |
| `tool_cost_total` | 工具调用成本 |
| `retry_cost_total` | 重试额外成本 |
| `cost_by_model` | 不同模型成本拆分 |
| `cost_by_user` / `cost_by_tenant` | 多租户计费和限额 |
| `cost_by_task_type` | 找出最贵的任务类型 |

## 智能路由降本

智能路由是成本优化的核心技术之一：根据任务复杂度动态选择模型，简单问题用小模型，复杂问题用大模型 ^[extracted]。实施得当可降低 40-60% 的模型成本。

## 成本与质量平衡

成本优化的目标不是单纯省钱——有些高成本是值得的（高风险任务多做验证），有些是浪费（反复把同一段长文档塞进上下文）。成本的优化应该量化 ROI，不应为了省钱牺牲质量 ^[extracted]。

## 相关页面

- [[agent-observability-fundamentals]] — 成本观测是可观测性的核心维度
- [[agent-failure-taxonomy]] — 重试成本与失败模式的关系
- [[ai-production-engineering-five-pillars]] — 成本在运行工程化框架中的位置
