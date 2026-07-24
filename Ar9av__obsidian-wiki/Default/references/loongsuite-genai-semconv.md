---
title: LoongSuite GenAI 可观测语义规范
category: references
tags:
  - ai-agent
  - observability
  - opentelemetry
  - standards
  - alibaba
  - ant
sources:
  - "阿里云开发者: 阿里巴巴 & 蚂蚁 LoongSuite GenAI 可观测语义规范 (2026-05-12)"
summary: 阿里云、阿里控股与蚂蚁集团 2025-2026 年在 OTel GenAI 语义基础上，针对内部真实场景提出 Entry/Step Span、Skill 语义、Token 级推理观测三项扩展，并配套 GenAI Utils 工程化能力层。
provenance:
  extracted: 0.72
  inferred: 0.23
  ambiguous: 0.05
base_confidence: 0.55
lifecycle: draft
lifecycle_changed: 2026-07-22
tier: supporting
created: 2026-07-22T00:00:00+08:00
updated: "2026-07-22"
relationships:
  - target: "[[concepts/genai-observability-semconv]]"
    type: extends
  - target: "[[entities/loongsuite-platform]]"
    type: related_to
  - target: "[[entities/dify]]"
    type: related_to
---

# LoongSuite GenAI 可观测语义规范

> 原文：阿里巴巴 & 蚂蚁 LoongSuite GenAI 可观测语义规范：从统一数据语言到规模化落地（阿里云开发者，2026-05-12）

## 背景与定位

OpenTelemetry 自 2024 年初推动 GenAI Semantic Conventions，目标是为 Model、Prompt、Token、Tool Calling、Agent、Memory、Session 等概念建立统一数据采集标准。SemConv 被社区 Maintainer 视为 OTel 的灵魂。

2025 年，阿里云、阿里控股与蚂蚁集团联合启动，在 OTel GenAI 语义基础上对内部场景中尚未覆盖的内容进行语义建模；2026 年在社区 Maintainer 建议下，先将成果开源至阿里巴巴 LoongSuite 品牌下，作为 OTel GenAI SemConv 的厂商增强标准。

## 三项核心扩展

### 1. Entry/Step Span

针对 Agent 长程任务中单个 Trace 包含成百上千 Span、调用链冗长难读的问题：

- **Entry Span**：Agent 调用入口处的 Span，还原模型和用户的原始输入输出，形成对话历史，避免被 System Prompt 或框架 Prompt 干扰。
- **Step Span**：每次 ReAct 过程的层次化表达，支持 Top-down 排查——先定位哪一轮 ReAct 出问题，再深入该轮具体步骤。

### 2. Skill 语义

电商购物助手等场景中，用户指令由 Agent 路由到对应 **Skill** 执行。Skill 是业务功能的最小可复用单元。LoongSuite 新增 `gen_ai.skill.*` 属性：

| 属性 | 说明 |
|------|------|
| `gen_ai.skill.name` | Skill 名称 |
| `gen_ai.skill.id` | Skill 实例标识，区分灰度/A/B 实验 |
| `gen_ai.skill.description` | Skill 功能描述 |
| `gen_ai.skill.version` | Skill 版本号 |

同时向 OTel 社区提交了独立 `invoke_skill` Span 的提案（[open-telemetry/semantic-conventions-genai#86](https://github.com/open-telemetry/semantic-conventions-genai/issues/86)）。

### 3. Token 级推理观测

蚂蚁可观测团队围绕推理云服务建设了全链路可观测体系。请求级 Trace 无法定位更深问题，因此把观测从宏观请求下沉到微观 Token：

**Token 性能数据**：

| 属性 | 描述 |
|------|------|
| `gen_ai.response.per_token_time_to_schedule` | 每个 Token 进入迭代的时间戳 |
| `gen_ai.response.per_token_time_to_generate` | 每个 Token 出迭代的时间戳 |
| `gen_ai.iteration.per_token_batch_size` | 每个 Token 所在迭代批的总请求数 |
| `gen_ai.iteration.per_token_cumulative_count` | 每个 Token 所在迭代批的总 Token 数 |

**Token 精度数据**：

| 属性 | 描述 |
|------|------|
| `gen_ai.response.candidate.per_position_decoded_tokens` | 每个位置 top-k 候选 Token 字符串 |
| `gen_ai.response.candidate.per_position_token_ids` | 每个位置 top-k 候选 Token ID |
| `gen_ai.response.candidate.per_position_logprobs` | 每个位置 top-k 候选 Token logits |

案例显示，该能力帮助定位慢 Token 的根因为其他租户请求的 prefill 中断了当前 decode，以及通过 BOS Token 异常定位"答非所问"问题。

### 引擎并发分析案例 ^[extracted]

Token 分析可进一步关联到**引擎并发剖析**，实现从"哪个 Token 慢"到"为什么慢"的因果闭环：

1. 通过 Token 分析页面发现某请求的 decode 阶段被中断 6s+（对应第 125 个 Token 生成异常慢）
2. 点击右上角"引擎并发分析"跳转到对应引擎实例的并发剖析页面
3. 发现根因：**其他租户的请求 prefill 中断了当前请求的 decode 过程**
4. 解决方案建议：做 Prefill-Decode (PD) 分离部署，避免跨请求干扰

### BOS Token 异常检测案例 ^[extracted]

另一个典型案例：某次模型输出"答非所问"——用户的 Prompt 和模型回答完全不相关。

- 通过 Token 分析页面发现生成的第一个 Token 是 `begin_of_sentence` (BOS)
- BOS 是用于分割两个不相关语料的特殊 Token——一旦出现，后续回答与 Prompt 无关联
- **关键**：BOS 在用户回复、引擎日志、网关日志中均显示为空串，没有 Token 级分析几乎无法定位

## GenAI Utils 三步编程模型 ^[extracted]

LoongSuite 在探针中实现了 GenAI Utils 工程化能力层，采用三步编程模型让插桩开发者无需直接操作 OTel API：

1. **获取 Handler 单例**：`handler = ExtendedTelemetryHandler.get_instance()`
2. **选择对应 Invocation 数据类，填充业务数据**：如 `LlmInvocation(model="gpt-4o", messages=[...], tokens=150)` 
3. **使用 Context Manager 完成遥测输出**：`with handler.trace(invocation) as span: ...`

**设计价值**：
- 插桩层只做数据提取，不直接操作 OTel API
- ExtendedTelemetryHandler 统一收口 Span 创建、属性挂载、Metrics 记录、Event 发送、Context 管理
- 语义规范升级时只改 Utils 一处，所有下游插桩库自动生效

已支持 Python 和 JS 版本，以及 DashScope、[[entities/dify|Dify]]、AgentScope、Mem0、MCP、Agno、Google ADK、LangChain 等框架插桩。
