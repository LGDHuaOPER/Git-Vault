---
title: "评估驱动开发 (EDD)"
category: concepts
tags:
  - ai-agent
  - evaluation
  - methodology
sources:
  - "SelectDB: Agent 时代为什么需要新的可观测范式？ (2026-05-21)"
  - "一臻数据: Litefuse 正式发布！Doris 原生 Agent 可观测平台来了 (2026-05-21)"
  - "一臻数据: 正式开源！Doris 驱动的Agent观测平台 (2026-07-05)"
  - "AI Engineer编程微信公众号: Agent 可观测与质量评测体系：从数据采集到数据飞轮的完整实践 (2026-07-12)"
summary: "EDD (Evaluation Driven Development)：先观测 Agent 真实行为，用量化评估打分，用评估数据驱动 Prompt 调优和模型选型——让'Agent 变好了'从主观感受变成可验证的事实。"
base_confidence: 0.67
lifecycle: draft
lifecycle_changed: "2026-07-16"
tier: supporting
provenance:
  extracted: 0.55
  inferred: 0.35
  ambiguous: 0.10
created: "2026-07-16"
updated: "2026-07-17"
relationships:
  - target: "[[entities/opencompass]]"
    type: related_to
  - target: "[[references/agent-observability-quality-evaluation-data-flywheel]]"
    type: related_to
---

# 评估驱动开发 (EDD)

## TDD vs EDD

TDD（测试驱动开发）在传统软件中的逻辑：写测试 → 跑用例 → 代码通过 → 重构。这套方法论保证的是**代码逻辑正确**——接口返回正确状态码，边界条件处理正确。

EDD 的逻辑不同。Agent 的核心质量问题不是接口返回 `200`，而是：**回答准不准？工具调没调对？任务路径合不合理？上下文有没有腐化？** ^[extracted]

这些问题，传统单元测试覆盖不到。^[inferred]

## EDD 闭环

```
观测 → 评估 → 归因 → 优化 → 再评估
```

1. **观测**：完整记录 Agent 每一步的真实行为（LLM 调用、工具执行、推理路径）
2. **评估**：用评估器（规则/LLM-as-Judge/人工）对输出打分，识别 Bad Case
3. **归因**：定位问题根因——是 Prompt 歧义？模型幻觉？上下文过长？工具调用语义漂移？
4. **优化**：调整 Prompt、换模型、修改工具描述、压缩上下文
5. **再评估**：用同一批数据集重跑，分数上升 → 上线；分数不变 → 继续迭代

## EDD 所需的基础设施

^[inferred]

EDD 闭环不是纯流程概念，它需要一整套基础设施支撑：

| 能力 | 组件 | 说明 |
|------|------|------|
| Trace 采集 | OTel SDK / Langfuse SDK | 自动捕获每次调用的输入输出、Token、耗时 |
| 可视化分析 | Trace 面板 + 指标看板 | 下钻单次 Trace，聚合全局指标 |
| 数据集管理 | Golden Dataset | 从线上 Trace 中沉淀 Bad Case 和 Good Case |
| 评估器 | LLM-as-Judge / Code Eval / 人工标注 | 多种评估方式组合 |
| 实验对比 | Experiments | 不同 Prompt/模型版本在相同数据集上跑分对比 |

当前将 EDD 闭环产品化的平台包括 [[litefuse]]（基于 Apache Doris）和 [[langfuse]]（基于 ClickHouse + PostgreSQL）。^[extracted]

## 离线评测流水线

将自动化评测嵌入 CI/CD 流水线，以质量门禁拦截回归风险：

```
评测集维护 → 环境准备 → 用例执行 → 评估执行 → 评估结果 → 质量门禁
```

### 质量门禁的三类机制

- **基线对比**：新版本 vs 旧版本的指标 Diff，检测回归
- **质量卡点**：核心用例必须 100% 通过，边缘用例允许容错
- **门禁规则**：硬性阈值（阻断发布）vs 软性阈值（告警通知）

## 评测集构建：三要素模型

高质量评测用例包含三个核心要素：

| 要素 | 内容 | 关键设计 |
|---|---|---|
| **任务输入** | 提问/多轮上下文、场景分类标签 | 多轮对话需精确复现对话状态 |
| **运行环境配置** | 状态类型与参数、Mock 服务 | 任何可能影响 Agent 行为的配置必须显式声明 |
| **Ground Truth** | 期望结果、关键证据、必/禁调工具 | 不仅验证"做了什么"，还验证"没做什么" |

### 评测集维护方式

支持类 Excel 工具（快速录入）和 Git 仓库维护（工程化版本管理）两种模式。Git 仓库结构标准化：

```
skill-name/
├── files/          # 评测用的文件
├── tests/          # Code 评估脚本
├── eval.json       # 定义评测任务
└── setup.yaml      # 定义环境配置
```

### 高质量评测集的核心特征

- **场景覆盖度**：对齐线上真实任务分布，核心场景优先覆盖
- **环境可复现性**：用例绑定环境快照，不依赖实时接口
- **动态更新机制**：线上真实 case 脱敏回流，持续补全评测集

## 仿真环境：确定性保障

Agent 的副作用（文件修改、API 调用）要求评测环境必须隔离。外部依赖抽象为三类接口：

| 接口类型 | 特征 | 隔离策略 |
|---|---|---|
| **静态只读接口** | 文档查询类，数据不变 | 本地镜像/版本化索引 |
| **Mock 服务** | 有状态/时效性工具 API | 录制真实响应，回放固定数据 |
| **沙箱环境** | 可在隔离环境运行工具 | Docker 容器 + OverlayFS + 网络命名空间 |

沙箱的核心价值：以文件修改类任务为例，无沙箱时文件被永久修改且多任务互相干扰；有沙箱后所有操作限制在容器内 `/workspace`，支持 100 个任务并行互不干扰。^[extracted]

## 评估器：分层策略

评估器采用分层策略，根据任务特性选择最合适的方法：

| 评估器类型 | 评估方法 | 特点 | 适用场景 |
|---|---|---|---|
| **人工评估** | 专家审查、客户反馈 | 高精度、高成本 | 基准标注、争议仲裁 |
| **Code 评估** | 单元测试、字符串相似性、轮次、Token、必/禁调工具 | 低成本、稳定 | 确定性任务、CI 门禁 |
| **LLM/Agent 评估** | 量表评分、断言评分、参考评分、对比评分 | 灵活、易波动、成本较高 | 开放性任务 |

LLM 评估的四种方法：

- **量表评分**：多维度 1-5 分制，适合细粒度质量分析
- **断言评分**：布尔断言集合，比量表更客观
- **参考评分**：与 Ground Truth 做语义匹配（非字面匹配）
- **对比评分**：Pairwise 比较，消除绝对评分尺度问题

**波动性问题解决方案**：多次评估投票（N-shot）+ 人工校准 + 迭代优化。^[extracted]

## Skills 仓库评测实践

评测对象是 **Skill**（技能/工具）级别，采用多 Agent 协作架构：

- **主 Agent**：评测 orchestrator，负责任务分发
- **Task 子 Agent**：执行具体用例任务
- **Eval 子 Agent**：对输出结果进行评估

这种"用 Agent 评测 Agent"的元设计，实现了评估系统的可扩展性和一致性。^[extracted]

## 三类任务的差异化评估

拒绝"一刀切"，按任务类型设计差异化评估：

- **数值类**：数学指标，追求精确（Coverage、Point Pass、Pearson、NRMSE）
- **工具链类**：规则匹配，追求合规（预期工具调用、查询语句合理性）
- **语义类**：LLM 理解，追求合理（LLM Judge + tool_list 验证）

## 与传统可观测的关系

传统可观测（Prometheus/Grafana/ELK）负责回答"系统正常吗"，EDD 负责回答"Agent 做对了吗"。两者不替代，是互补的维度。^[inferred]

生产环境通常两套体系并行：OTel 做 SLO 监控和告警，Langfuse/Litefuse 做 Prompt 质量分析和 session 回放。^[extracted]

## 相关页面

- [[concepts/agent-online-evaluation]] — 在线评估体系（离线评测的互补）
- [[concepts/agent-data-flywheel]] — 数据飞轮（EDD 的完整闭环实现）
- [[concepts/agent-observability-paradigm]] — 为什么需要新范式
- [[concepts/agent-trace-cost-quality-architecture]] — 具体的技术架构
- [[concepts/llm-as-judge-evaluation]] — LLM-as-Judge 评估方法论
- [[entities/litefuse]] — EDD 方法论的产品化实现
- [[entities/langfuse-llm-observability]] — EDD 工具链中的评估和实验功能
- [[concepts/agent-evaluation-framework]] — Agent 评估方法论（Anthropic Task/Trial/Grader + 阿里巴巴 P0/P1/P2 工程框架）
- [[concepts/agent-causal-attribution]] — Agent 因果归因（从"错在哪一步"到"为什么错"）
- [[concepts/rag-observability]] — RAG 可观测性（检索质量独立观测层）
- [[entities/opencompass]] — 开源大模型评测框架
- [[references/agent-observability-quality-evaluation-data-flywheel]] — 可观测与质量评测体系：从数据采集到数据飞轮
