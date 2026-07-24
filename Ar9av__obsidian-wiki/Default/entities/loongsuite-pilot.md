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
base_confidence: 0.62
lifecycle: draft
lifecycle_changed: 2026-07-22
tier: supporting
created: 2026-07-22T00:00:00+08:00
updated: "2026-07-24"
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

## AgentActivityEntry OTel Trace 输出示例

Pilot 将所有 Agent 原始数据归一化为统一的 OTel 格式 ^[extracted]：

```json
{
  "event.name": "tool.call",
  "gen_ai.agent.type": "claude-code",
  "gen_ai.session.id": "8e06a611-d9ae-4c43-b03d-a285e8bda3ab",
  "gen_ai.turn.id": "...:t1",
  "gen_ai.step.id": "...:t1:s3",
  "gen_ai.tool.name": "Bash",
  "gen_ai.tool.call.id": "toolu_vrtx_0115QdGCWqoQ4Mnj6aKwcEuy",
  "gen_ai.tool.call.parameters": "{\"command\":\"ls -la\"}",
  "trace_id": "09f11db9fca4348e70ad34aa620e810c"
}
```

保留完整的 `session → turn → step → response/tool_call` 层级结构，支持通过 SQL 按用户/Agent类型/模型/Token量多维聚合查询。

## 多 Agent 横向对比发现 ^[extracted]

基于 Pilot 统一 Schema 采集的生产数据，阿里云团队对三种主流 AI Coding Agent 做了横向对比：

| 维度 | Claude Code | Cursor | Qoder |
|------|------------|--------|-------|
| 总耗时 | **最短** — LLM 单轮推理最快 | 最长 — 深度思考模式 | 居中 |
| 工具调用风格 | Bash 为主，精确定位后一次写出 | Shell+Read+Grep+Write，搜索-阅读-理解-编写四步流 | API 轻量级（Glob/Read），时间几乎全花在推理 |
| LLM 调用次数 | 中等 | **最少** — 但单轮时间最长 | **最多** — "小步快跑"风格 |
| Token 消耗 | 中等 | 最高 — 输出 Token 最多，代码更详尽 | **最低** — 上下文管理最紧凑 |
| 自我修正特征 | 较少 | 每 12 轮中有 2 轮自我回退重写（~15% Token） | 频繁迭代 |

> 没有普适的最优解 — 每个团队应基于自己的实际数据找到"甜蜜区"：代码质量优先选 Cursor，速度优先选 Claude Code，成本敏感选 Qoder。^[inferred]

## 一键安装

```bash
curl -fsSL https://loongcollector-community-edition.oss-cn-shanghai.aliyuncs.com/loongsuite-pilot/installer.sh \
  | bash -s -- install --sls-endpoint "https://cn-xx.log.aliyuncs.com" \
  --sls-project "my-project" --sls-logstore "my-logstore"
```

安装后自动下载最新版本、部署到 `~/.loongsuite-pilot/`、安装 Hook 脚本并启动后台进程，即刻开始扫描 AI Coding Agent。^[extracted]

## 数据驱动的四个关键问题

1. **AI Coding 的 ROI 如何度量？** 任务完成率、Token 效率比、人机协作比、自我修正率。
2. **多 Agent 并存时代如何选型？** 统一 Schema 支持跨 Agent 横向对比，找到团队的"甜蜜区"。
3. **Token 花得多就是效果好吗？** 识别循环试错、上下文膨胀、过度谨慎三种"Token 黑洞"。
4. **AI Agent 的操作谁来审计？** 从审计管理、风险态势、风险主体定位、数据泄露链路、实体关联调查到会话级追溯的六层安全审计体系。

## 与 LoongSuite 平台的关系

Pilot 与 [[entities/loongsuite-platform|LoongSuite Platform]] 中的 LoongCollector（主机探针）、语言 Agent SDK 共同构成从服务端到端侧的完整可观测链路。

## Related

- [[references/loongsuite-pilot-open-source]] — LoongSuite Pilot 开源文章：端侧 AI Coding Agent 可观测
