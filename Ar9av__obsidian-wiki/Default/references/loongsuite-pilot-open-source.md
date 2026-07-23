---
title: LoongSuite Pilot 开源：端侧 AI Coding Agent 可观测
category: references
tags:
  - ai-agent
  - observability
  - alibaba
  - loongsuite
  - coding-agent
sources:
  - "阿里云开发者: 当 AI Coding Agent 成为基础设施：我们为什么要开源 LoongSuite Pilot (2026-06-12)"
summary: 阿里云 2026 年 6 月宣布开源 LoongSuite Pilot，补齐 AI Coding Agent（Cursor、Claude Code、Codex、Qoder）运行在开发者本地机器导致的可观测盲区。
provenance:
  extracted: 0.75
  inferred: 0.20
  ambiguous: 0.05
base_confidence: 0.55
lifecycle: draft
lifecycle_changed: 2026-07-22
tier: supporting
created: 2026-07-22T00:00:00+08:00
updated: "2026-07-22"
relationships:
  - target: "[[entities/loongsuite-pilot]]"
    type: describes
  - target: "[[entities/loongsuite-platform]]"
    type: part_of
  - target: "[[concepts/ai-coding-agent-observability]]"
    type: related_to
  - target: "[[references/loongsuite-genai-semconv]]"
    type: related_to
---

# [[entities/loongsuite-pilot|LoongSuite Pilot]] 开源：端侧 AI Coding Agent 可观测

> 原文：当 AI Coding Agent 成为基础设施：我们为什么要开源 LoongSuite Pilot（阿里云开发者，2026-06-12）

## 核心问题

2025 年以来，Cursor、Claude Code、Codex、Qoder 等 AI Coding Agent 从"尝鲜玩具"变成团队日常生产力工具，但企业对它们的运行行为几乎没有可观测性。具体困难来自三个层面：

- **Agent 行为天然难以观测**：一次任务执行可能包含 10 轮以上 ReAct 循环，传统 Metrics + Log + Trace 三板斧只能看到独立 HTTP 请求，无法还原分层决策流程。
- **多 Agent 数据天然割裂**：Cursor、Claude Code 各自的数据格式、存储位置、记录粒度不同，横向对比困难。
- **端侧是可观测盲区**：现有探针面向服务端，但 Coding Agent 运行在开发者本地，数据散落在 IDE 历史文件、SQLite 数据库、Session 日志中。

## 五大设计选择

1. **ALL IN ONE 架构**：不做单点适配，而是统一采集平台，通过 `agents.d/*.json` 声明化扩展新 Agent。
2. **适配 Agent 而非改造 Agent**：抽象 5 种采集基类（Hook / IDE / SQLite / Session / CLI Forwarder），让采集能力适配 Agent 原生运行模式。
3. **语义规范统一异构数据**：原始数据归一化为 `AgentActivityEntry` 事件格式，遵循 [[references/loongsuite-genai-semconv|LoongSuite GenAI 可观测语义规范]]。
4. **灵活粒度，平衡观测与安全**：支持按 Agent 配置是否采集消息内容、工具参数；内置基于规则的敏感信息自动脱敏引擎。
5. **多目标输出，不绑定后端**：本地 JSONL、SLS Logstore、HTTP Endpoint、OTLP Trace 并行扇出。

## 已适配 Agent

| Agent | 覆盖事件 |
|-------|---------|
| Claude Code | 用户提问、工具调用前后、任务完成、上下文压缩、子 Agent 生命周期等 |
| Codex | 会话启动、用户提问、工具调用前后、任务完成 |
| Cursor | 12 种事件，覆盖会话生命周期、工具调用、提问、子 Agent |
| Qoder / Qoder Work | Hook 日志 + IDE 历史记录 + 数据库 + 会话文件多路并行采集 |

## 四层数据价值

文章用四个问题说明采集价值：

- **AI Coding 的 ROI 如何度量？** 通过 Trace 树构建任务完成率、Token 效率比、人机协作比、自我修正率。
- **多 Agent 并存时代如何选型？** 统一 Schema 让跨 Agent 横向对比成为可能，同一任务交给不同 Agent 可观察行为模式差异。
- **Token 花得多就是效果好吗？** 识别循环试错、上下文膨胀、过度谨慎三种典型"Token 黑洞"模式。
- **AI Agent 的操作谁来审计？** 从审计管理、风险态势、风险主体定位、数据泄露链路、实体关联调查到会话级追溯的六层安全审计体系。

## 开源信息

- GitHub：https://github.com/alibaba/loongsuite-pilot
- 关联项目：LoongCollector、LoongSuite Python/Go/Java Agent、LoongSuite Semantic Conventions
