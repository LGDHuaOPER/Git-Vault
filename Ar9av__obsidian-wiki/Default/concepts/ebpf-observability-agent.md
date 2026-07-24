---
title: eBPF 可观测性智能体
category: concepts
tags:
  - ai-agent
  - observability
  - ebpf
  - zero-code-instrumentation
  - distributed-tracing
  - data-quality
sources:
  - "DeepFlow: eBPF + LLM：实现可观测性智能体的基础设施 (2024-05-20)"
  - "DeepFlow: 从 eBPF 到 LLM：可观测性管道的每一层都在变｜上海 Meetup 回顾 (2026-04-28)"
summary: 以 eBPF 作为高质量可观测信号源基础设施，叠加 LLM 的推理与决策能力，构建零侵扰、全栈、高效率的可观测性智能体。
provenance:
  extracted: 0.65
  inferred: 0.30
  ambiguous: 0.05
base_confidence: 0.58
lifecycle: draft
lifecycle_changed: "2026-07-22"
tier: supporting
created: "2026-07-22"
updated: "2026-07-22"
relationships:
  - target: "[[entities/deepflow]]"
    type: uses
  - target: "[[concepts/ai-agent-observability]]"
    type: extends
  - target: "[[concepts/agent-trace-and-timeline]]"
    type: related_to
  - target: "[[entities/mcpspy-ebpf-mcp-monitoring]]"
    type: related_to
---

# eBPF 可观测性智能体

**eBPF 可观测性智能体**是一种将 eBPF 作为高质量可观测信号源基础设施，再叠加 LLM 推理与决策能力，实现高效率、零侵扰可观测的智能体范式。

## 核心命题

传统 APM 的可观测数据存在两个根本问题 ^[extracted]：

1. **完整性不足**：客户端访问服务端可能经过 K8s 网络、网关、中间件、数据库、DNS 等，这些环节 APM 无法覆盖
2. **一致性不足**：客户端观测到 500ms 延迟，服务端可能只有 10ms，甚至服务端未插桩

这本质上是**数据治理问题**。获得高质量数据后，才能利用 LLM 结合提示词工程、RAG、微调等手段建设高效的可观测性智能体。

## eBPF 作为高质量信号源的基础设施

eBPF 的两个独特优势 ^[extracted]：

| 优势 | 说明 |
|------|------|
| **零侵扰（Zero Code）** | 无需修改、重编译、重启应用进程，可插即用，可直接上生产环境 |
| **全栈（Full Stack）** | 覆盖业务进程、网关、消息队列、数据库、操作系统，甚至 K8s 网络传输、文件读写 |

eBPF 的安全性由 eBPF Verifier 保证，性能由 JIT 编译机制保证，可媲美内核原生代码。

## 从 Raw Data 到高质量观测信号

eBPF 采集的 Raw Data 需要经过识别、提取、转换、关联、聚合等操作才能使用。典型处理链路 ^[extracted]：

```
Socket Events → API Request/Error/Delay 指标 → Service Map
              → 关联调用链 → 分布式追踪
              → 聚合调用链 → API Map
Process Events → 进程启停日志
File Events → File Access Log
Perf Events → CPU / 内存 / GPU / 显存 / 锁事件 → 火焰图
```

## 数据增强：WebAssembly 业务解析

标准协议（HTTP、MySQL 等）只能解析头部字段。对于 HTTP Payload 中的业务错误码、交易流水号、订单 ID，以及 Protobuf/Thrift 序列化数据，需要结合 Schema 解析。DeepFlow 使用 **WebAssembly** 实现安全、高性能、热加载的插件机制 ^[extracted]。

## LLM 智能体的三个落地场景

### 1. 工单智能体

**痛点**：告警触发创建工单群后，需要逐人排查、逐人拉入，匹配到正确责任人之前耗时可长达一个多小时。

**AI Agent 方案** ^[extracted]：
- 工单创建时自动将 AI Agent 拉入群聊
- Agent 先调用 DeepFlow API 查看追踪、指标、事件、日志数据中的一种
- 使用统计算法对数据进行特征总结（有效降低 Token 数量）
- 特征信息作为 Prompt 调用 LLM（GPT-4）分析，利用 Function Calling 或 JSON Mode 决定还需分析哪些类型数据
- 基于所有分析结果请求 LLM 做归纳总结
- 利用 `label.owner` 等标签将正确负责人拉入群

**效果**：工单群初期混乱的一个多小时压缩到一分钟，显著减少群内人数，大幅提升团队效率。^[extracted]

### 2. 变更智能体

**痛点**：云原生环境下服务发版后性能劣化原因复杂，On Call 难以定位根因。

**AI Agent 方案** ^[extracted]：
- 利用 eBPF 零侵扰持续 Profiling，获取进程运行时的业务函数、库函数、运行时函数、内核函数调用栈
- 通过组合 LLM + Fine-tuning + RAG + Prompt Engineering 覆盖全栈 Profiling 数据涉及的所有专业领域：
  - **LLM 原知**：内核函数、运行时函数、基础库函数——LLM 通常已掌握
  - **Fine-tuning**：更新频率低、通用知识的函数
  - **RAG**：数量多、迭代快、接口文档丰富的应用库函数（如 Python Requests）
  - **Prompt Engineering**：企业业务代码——通过 K8s 注入 Git commit_id label，Agent 定位最近的代码修改

### 3. 漏洞智能体

**痛点**：漏洞整改可能做了 76% 的无用功，仅有 3% 的漏洞应优先关注。

**方案**：基于 eBPF 的 Cloud Workload Security 数据采集，利用 Isovalent 总结的四大安全黄金观测信号：Process Execution、Network Socket、File Access、Layer 7 Network Identity。^[extracted]

## 持续改进闭环

- **测试环境**：利用混沌工程构造大量异常数据（已知根因），用于评估和改进 AI Agent
- **生产环境**：加入使用者评分机制，Agent 开发人员基于评分持续改进 ^[extracted]

## DeepFlow 社区版 AI Agent

DeepFlow 社区版也发布了 AI Agent 能力，当前支持对 Grafana Panel 数据进行分析（Topo、Tracing），适配 GPT、通义千问、文心一言、ChatGLM 四种大模型。^[extracted]

## 与传统 APM 的对比

| 维度 | 传统 APM | eBPF + LLM 智能体 |
|------|----------|-------------------|
| 接入方式 | 代码插桩 | 零侵扰 |
| 覆盖范围 | 已插桩的进程 | 全栈全链路 |
| 数据质量 | 依赖业务侧覆盖率 | 内核级完整数据 |
| 故障分析 | 人工排查 | LLM 自动分析根因 |
| 场景能力 | 监控告警 | 工单、变更、漏洞智能体 |

## 相关页面

- [[entities/deepflow]] — DeepFlow 是 eBPF 可观测性智能体的典型实践
- [[entities/mcpspy-ebpf-mcp-monitoring]] — 基于 eBPF 的 MCP 协议可观测工具
- [[concepts/ai-agent-observability]] — AI Agent 可观测性整体概念
- [[concepts/agent-trace-and-timeline]] — Trace 链路追踪基础
