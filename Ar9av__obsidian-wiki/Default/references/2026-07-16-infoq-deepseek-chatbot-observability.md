---
title: "AI 原生应用全栈可观测实践：以 DeepSeek 对话机器人为例"
category: references
tags: [observability, deepseek, alibaba, full-stack, qcon]

relationships:
  - target: "[[entities/dify]]"
    type: related_to
sources:
  - "InfoQ: AI 原生应用全栈可观测实践：以 DeepSeek 对话机器人为例 (2026-07-16)"
summary: InfoQ 转载的阿里云高级技术专家夏明演讲，介绍 DeepSeek 对话机器人场景下的全栈可观测架构、新指标与流式 Trace 处理。
provenance:
  extracted: 0.68
  inferred: 0.27
  ambiguous: 0.05
base_confidence: 0.44
lifecycle: draft
lifecycle_changed: 2026-07-22
tier: supporting
created: 2026-07-22T00:00:00+08:00
updated: "2026-07-25"
---

# AI 原生应用全栈可观测实践：以 DeepSeek 对话机器人为例

阿里云高级技术专家夏明在 QCon 北京站的演讲，以 DeepSeek 对话机器人为例，剖析 AI 原生应用从研发到生产落地的可观测需求与挑战。

## AI 原生应用架构与痛点

应用形态演进三阶段：

1. 简单对话机器人（直接调用模型 + RAG）
2. 领域化 Copilot 智能助手
3. 多 Agent 协同（规划、编排、生成、执行）

核心痛点：

- GPU 资源昂贵，利用率难优化
- 推理需求是训练的百倍千倍，存在安全/隐私/合规/投毒风险
- **MCP Token 黑洞**：MCP Server 内部不可见，恶意或反复调用快速消耗 token 额度

## 阿里云 AI 全栈可观测架构

从终端用户 → 网关 → 应用模型层（[[entities/dify|Dify]]）→ 向量数据库 / 缓存 / MCP 工具 → AI 网关（自动路由模型）→ 模型服务层，三层核心观测诉求：

1. **AI 全栈统一监控**：覆盖用户业务层、模型应用层、外部工具层、模型服务层、AI Infra 层
2. **端到端模型调用全链路诊断**：从终端问答到后端流转定位瓶颈
3. **模型生成结果评估**：自动化评估生成质量

## 大模型应用可观测新技术点

### 新指标

- **TTFT**（Time To First Token）— 首包响应时间
- **TPOT**（Time Per Output Token）— 每 Token 处理时间
- **Token per Second** — 每秒 token 数

这些指标分别对应 prefill / decode 阶段可能存在的性能问题。

### LLM Span Chunk 分段采集与合并

流式场景下，大模型调用上下文可能达数 MB、持续数小时。若等待完整再上报，探针压力大；若简单分段，后续分析困难。最终方案是：**分段采集上报 + 服务端重新合并为一条记录**，平衡客户端性能、实时性与分析易用性。

### 内置评估服务

基于 Trace 数据天然记录模型调用上下文，提供开箱即用的评估模板，支持质量检测、安全检测、意图提取等。上限较低时支持自定义扩展，并解决 embedding + retrieval 结合、语义检索 + 关键词混合检索的工程问题。

## AI In 可观测实战

- **Copilot 智能助手**：用 workflow 方式分析复杂 trace、性能优化（CPU 热点、内存 OOM）
- **Problem Insights 智能洞察**：面向故障应急，自动发现故障、推理传播链、根因分析，结合 MCP 工具实现故障自愈

## Dify 在生产中的可观测问题

阿里云在实践中发现 [[entities/dify|Dify]] 原生可观测能力存在多个短板 ^[extracted]：

1. **观测维度单一**：每个应用需单独配置，只能看到 workflow 每一步的耗时，但无法与外部微服务或模型侧调用串联
2. **数据孤岛**：可观测数据存储在 PGSQL 中，规模大时查询效率极低，长时间范围查询卡顿严重
3. **缺少多应用视图**：Dify 平台上运行多个 LLM 应用，但原生无法按应用维度拆分成本和性能，不满足生产级部门间协同需求
4. **全栈链路断裂**：Dify 只是 AI 全栈调用链路中的一环，它与外部依赖、模型服务层、AI 网关的协同观测无法通过框架本身实现

使用阿里云探针可解决上述问题：一次接入全应用生效、多应用数据拆分、端到端串联、多层全局维度分析。^[extracted]

## AI In 可观测实战详解

### Copilot 智能助手（三类已上线功能）

1. **日志分析 Copilot**：自然语言转 SQL、SQL 分析与优化，偏日志服务场景 ^[extracted]
2. **Trace 分析 Copilot**：识别 Trace 慢/错/异常，指出入口服务报错原因（如下游 SQL 语法问题），给出优化建议。背后涉及 trace 结构分析、领域问题识别、多模态 profiling/日志/metrics 关联，通过 workflow 编排 ^[extracted]
3. **Profiling 分析 Copilot**：常态化持续性能剖析，支持发布前后的差分火焰图对比，定位性能问题代码。未来计划关联发布变更的 Pod 镜像版本，甚至 Git commit 信息及责任人 ^[extracted]

### Problem Insights 智能洞察

面向故障应急场景，目标是实现真正的智能洞察 ^[extracted]：

1. 智能检测系统核心问题，或关联告警事件触发洞察
2. 展示推理过程：根因定界（自身服务/下游/基础环境问题）→ 进一步分析（资源/代码问题）→ 分析上游业务影响
3. 对 SRE 和运维人员：展示故障传播链、相关事件流、影响面，结合多模态数据给出根因和解决方案
4. 目标：简化运维操作，降低 MTTR，提升企业可用性

> Copilot 倾向于用 workflow 方式提高确定性和规避模型幻觉，而 Problem Insights 场景更复杂，倾向于通过 Agent 方式尝试回答，内部涉及多种工具。^[extracted]

## Related

- [[concepts/ai-agent-observability]] — AI Agent 可观测性范式
- [[entities/deepseek-observability-agent]] — DeepSeek 可观测实践
- [[entities/loongsuite-platform]] — 阿里云 LoongSuite 可观测体系
- [[entities/dify]] — Dify 开源 LLMOps 平台
- [[references/aliyun-end-to-end-ai-observability]] — 阿里云端到端 AI 可观测实践（同体系）