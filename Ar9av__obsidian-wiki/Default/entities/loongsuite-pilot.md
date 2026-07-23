---
title: LoongSuite Pilot
category: entities
tags:
  - ai-agent
  - observability
  - alibaba
  - coding-agent
  - open-source
sources:
  - "阿里云开发者: 当 AI Coding Agent 成为基础设施：我们为什么要开源 LoongSuite Pilot (2026-06-12)"
summary: 阿里云 2026 年 6 月开源的端侧 AI Coding Agent 可观测采集器，统一采集 Cursor、Claude Code、Codex、Qoder 等本地 Agent 的行为数据，补齐端侧可观测盲区。
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
  - target: "[[entities/loongsuite-platform]]"
    type: related_to
  - target: "[[concepts/ai-coding-agent-observability]]"
    type: implements
  - target: "[[concepts/genai-observability-semconv]]"
    type: uses
  - target: "[[references/loongsuite-genai-semconv]]"
    type: related_to
  - target: "[[references/loongsuite-pilot-open-source]]"
    type: related_to
---

# LoongSuite Pilot

**LoongSuite Pilot** 是阿里云于 2026 年 6 月开源的**端侧 AI Coding Agent 可观测采集器**，专门解决 Cursor、Claude Code、Codex、Qoder 等 AI Coding Agent 运行在开发者本地机器上导致的可观测盲区。

- **GitHub**：https://github.com/alibaba/loongsuite-pilot
- **定位**：LoongSuite 可观测套件在端侧的延伸
- **核心问题**：团队里每个人的 AI Coding Agent 每天消耗多少 Token？哪些任务适合交给 Agent？Agent 输出不符预期时中间经历了什么？

## 端侧可观测的三层困难

1. **Agent 行为天然难以观测**：一次任务可能包含 10 轮以上 ReAct 循环，传统 Metrics + Log + Trace 只能看到独立 HTTP 请求。
2. **多 Agent 数据天然割裂**：Cursor、Claude Code、Codex、Qoder 的数据格式、存储位置、记录粒度各不相同。
3. **端侧是可观测盲区**：现有探针面向服务端，但 Coding Agent 数据散落在 IDE 历史文件、本地 SQLite 数据库、Session 日志中。

## 五大设计选择

### 1. ALL IN ONE 架构

不为每个 Agent 写专属脚本，而是定义统一的 Agent 行为数据模型。每个 Agent 的检测规则、部署模式、采集配置通过 `agents.d/*.json` 声明化，新增 Agent 只需实现数据格式转换逻辑。

### 2. 适配 Agent 而非改造 Agent

AI Coding Agent 多为第三方闭源产品，无法修改运行时。Pilot 抽象 5 种采集基类，让采集能力适配 Agent 原生运行模式：

| 采集基类 | 策略 | 适用场景 |
|---------|------|---------|
| BaseHookInput | Hook JSONL 日志增量读取 | Cursor、Claude Code、Codex |
| BaseIdeInput | IDE 历史文件快照轮询 | IDE 插件类 Agent |
| BaseSqliteInput | SQLite rowid 游标增量查询 | 使用本地数据库的 Agent |
| BaseSessionInput | Session 文件轮询 | 会话日志型 Agent |
| BaseCliForwarder | CLI 遥测日志转发 | CLI 类 Agent |

底层通过 Checkpoint 机制（StateStore + SnapshotStore）保障断点续采。

### 3. 语义规范统一异构数据

原始数据归一化为 `AgentActivityEntry` 事件格式，遵循 [[references/loongsuite-genai-semconv|LoongSuite GenAI 可观测语义规范]]，保留 `session → turn → step → response/tool_call` 完整层级。

### 4. 灵活粒度，平衡观测与安全

- 支持按 Agent 配置是否采集消息内容、工具参数等大字段
- 内置基于规则的敏感信息自动脱敏引擎（AccessKey、API Key、数据库连接串、私钥）
- 脱敏模式：`none | all | custom`，默认关闭

### 5. 多目标输出，不绑定后端

数据并行扇出到：本地 JSONL、SLS Logstore、HTTP Endpoint、OTLP Trace。单个目标失败不阻塞其他通道。

## 已适配 Agent

| Agent | 覆盖事件 |
|-------|---------|
| Claude Code | 用户提问、工具调用前后、任务完成、上下文压缩、子 Agent 生命周期等 |
| Codex | 会话启动、用户提问、工具调用前后、任务完成 |
| Cursor | 12 种事件，覆盖会话生命周期、工具调用、提问、子 Agent |
| Qoder / Qoder Work | Hook 日志 + IDE 历史记录 + 数据库 + 会话文件多路并行采集 |

## 数据驱动的四个关键问题

1. **AI Coding 的 ROI 如何度量？** 任务完成率、Token 效率比、人机协作比、自我修正率。
2. **多 Agent 并存时代如何选型？** 统一 Schema 支持跨 Agent 横向对比，找到团队的"甜蜜区"。
3. **Token 花得多就是效果好吗？** 识别循环试错、上下文膨胀、过度谨慎三种"Token 黑洞"。
4. **AI Agent 的操作谁来审计？** 从审计管理、风险态势、风险主体定位、数据泄露链路、实体关联调查到会话级追溯的六层安全审计体系。

## 与 LoongSuite 平台的关系

Pilot 与 [[entities/loongsuite-platform|LoongSuite Platform]] 中的 LoongCollector（主机探针）、语言 Agent SDK 共同构成从服务端到端侧的完整可观测链路。

## Related

- [[references/loongsuite-pilot-open-source]] — LoongSuite Pilot 开源文章：端侧 AI Coding Agent 可观测
