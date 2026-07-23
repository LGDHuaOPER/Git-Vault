---
title: Agent 可观测与质量评测体系：从数据采集到数据飞轮
category: references
tags:
  - ai-agent
  - observability
  - evaluation
  - data-flywheel
  - ailiops
sources:
  - "AI Engineer编程: Agent 可观测与质量评测体系：从数据采集到数据飞轮的完整实践 (2026-07-12)"
summary: 面向 Agent 原生的全链路可观测与质量评测体系：三层采集架构、离线评测流水线、在线评估体系、数据飞轮闭环，以及 AIOps 场景下的工程落地。
base_confidence: 0.72
lifecycle: draft
lifecycle_changed: "2026-07-22"
tier: supporting
provenance:
  extracted: 0.70
  inferred: 0.25
  ambiguous: 0.05
created: "2026-07-22"
updated: "2026-07-22"
relationships:
  - target: "[[concepts/ai-agent-observability]]"
    type: related_to
  - target: "[[concepts/agent-data-flywheel]]"
    type: related_to
  - target: "[[concepts/agent-online-evaluation]]"
    type: related_to
  - target: "[[concepts/evaluation-driven-development]]"
    type: related_to
  - target: "[[entities/dify]]"
    type: related_to
  - target: "[[concepts/umodel]]"
    type: related_to
  - target: "[[entities/openclaw]]"
    type: related_to
---

# Agent 可观测与质量评测体系：从数据采集到数据飞轮

## Agent 时代数据采集的新挑战

1. **应用框架碎片化**：LangChain、LlamaIndex、[[entities/dify|Dify]]、Spring AI 等抽象层次和调用方式迥异
2. **推理执行链路复杂**：RAG、Function Calling、MCP、A2A 协议构成多步骤编排
3. **性能指标维度扩展**：TTFT、TPOT、SSE 流式输出质量、对话轮次等
4. **数据采集目标多元化**：Token、文本、图片、音频、视频等多模态内容 ^[extracted]

## 全链路可观测架构：三层设计

### 接入层

| 接入形态 | 代表框架 | 策略 |
|----------|----------|------|
| 高代码 | LangChain、LlamaIndex、AutoGen、Spring AI | SDK 深度埋点 |
| 低代码 | Dify、Langflow | 平台扩展机制注入 |
| 通用 Agent | [[entities/openclaw|OpenClaw]] | 运行时统一采集 |
| 多语言 | Python/Node.js/Java/Go | 字节码增强/eBPF 无侵入埋点 |

基于 OTEL 标准保证兼容性，通过 LoongSuite 进行 GenAI 语义扩展 ^[extracted]。

### 计算 & 存储层

- **GENAI 语义对齐**：将技术 Span 转化为语义角色（llm_call、retriever_search、tool_execution）
- **Trace 尾采样**：基于错误、慢请求、异常模式做尾部采样
- **[[concepts/umodel|UModel]] 实体拓扑**：构建 LLM 模型、Tool、Knowledge Base、Agent 实例的关联图谱 ^[extracted]

### 应用层

| 维度 | 分析内容 | 业务价值 |
|------|----------|----------|
| 性能分析 | Token 消耗、LLM/工具调用耗时、平均推理轮次 | 优化用户体验 |
| 安全审计 | 敏感信息泄露、越权工具调用、Prompt 注入 | 合规与风控 |
| 成本分析 | 模型调用费用趋势、会话成本核算 | FinOps 决策 |

## 离线评测体系

### 评测流水线

`评测集维护 → 环境准备 → 用例执行 → 评估执行 → 评估结果 → 质量门禁`

质量门禁三类机制：基线对比、质量卡点、硬性/软性阈值规则 ^[extracted]。

### 评测集三要素

- **任务输入**：提问/多轮上下文、场景分类标签
- **运行环境配置**：状态类型与参数、Mock 服务
- **Ground Truth**：期望结果、关键证据、必/禁调工具 ^[extracted]

### 仿真环境

外部依赖抽象为三类接口：静态只读接口（本地镜像/版本化索引）、Mock 服务（录制真实响应）、沙箱环境（Docker + OverlayFS + 网络命名空间）^[extracted]。

### 评估器分层

| 评估器类型 | 评估方法 | 适用场景 |
|------------|----------|----------|
| 人工评估 | 专家审查、客户反馈 | 基准标注、争议仲裁 |
| Code 评估 | 单元测试、字符串相似性、轮次、Token、必/禁调工具 | 确定性任务、CI 门禁 |
| LLM/Agent 评估 | 量表评分、断言评分、参考评分、对比评分 | 开放性任务 |

LLM 评估的四种方法：量表评分、断言评分、参考评分、对比评分（Pairwise）。波动性问题通过多次评估投票（N-shot）+ 人工校准解决 ^[extracted]。

### Agent 轨迹评估

原始 Trace 信息多、密度低，设计了三阶段加工流水线：轨迹提取（保留决策逻辑和工具调用关系）→ 轨迹评估 → 结果聚合。工具返回压缩为 `${response}` 占位，保留调用结构 ^[extracted]。

## 在线评估体系

静态 Benchmark 的四大局限：依赖漂移、长尾输入、会话状态累积、测试用例难以全面覆盖。

在线评估双轨：实时告警与监测（Reactive）、Badcase 挖掘（Proactive）。实时告警基于 TTFT、TPOT、Token 消耗、工具调用成功率、用户反馈差评率设置动态阈值；Badcase 挖掘流程为：线上流量 → 异常检测 → 聚类分析 → 根因分类 → 脱敏回流 → 评测集更新 → 离线验证 → 发布新版本 ^[extracted]。

## 数据飞轮

四阶段循环：全链路观测 → Trace 评估 → 迭代优化 → 实验评测 → 回到全链路观测。

AIOps 场景下通过 Chaosblade 故障注入、线上问题回放、人机协作边界增强飞轮。三类任务差异化评估：数值/时序类（Code 评估）、工具链/结构类（Code + LLM 评估）、语义/回答质量类（LLM 评估）^[extracted]。

## 核心设计哲学

1. 离线 + 在线互补，而非替代
2. 分层信息处理：保留决策逻辑，丢弃执行细节
3. 评估分化策略：数值类求精确、工具链类求合规、语义类求合理
4. 数据飞轮 > 单点优化 ^[extracted]

## 相关页面

- [[concepts/ai-agent-observability]] — Agent 可观测性整体概念
- [[concepts/agent-data-flywheel]] — 数据飞轮完整闭环
- [[concepts/agent-online-evaluation]] — 在线评估体系
- [[concepts/evaluation-driven-development]] — 评估驱动开发方法论
