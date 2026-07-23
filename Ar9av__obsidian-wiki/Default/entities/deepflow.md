---
title: DeepFlow
category: entities
tags:
  - ai-agent
  - observability
  - ebpf
  - zero-code-instrumentation
  - distributed-tracing
sources:
  - "DeepFlow: eBPF + LLM：实现可观测性智能体的基础设施 (2024-05-20)"
  - "DeepFlow: 从 eBPF 到 LLM：可观测性管道的每一层都在变｜上海 Meetup 回顾 (2026-04-28)"
summary: 云杉网络开源的可观测性产品，基于 eBPF 实现零侵扰（Zero Code）应用性能指标、分布式追踪和持续性能剖析，并通过 LLM 构建工单、变更、漏洞等场景的可观测性智能体，也作为 Agent 治理的"电子眼"从内核层记录智能体行为。
provenance:
  extracted: 0.70
  inferred: 0.25
  ambiguous: 0.05
base_confidence: 0.60
lifecycle: draft
lifecycle_changed: "2026-07-22"
tier: supporting
created: "2026-07-22"
updated: "2026-07-22"
relationships:
  - target: "[[concepts/ebpf-observability-agent]]"
    type: implements
  - target: "[[concepts/ai-agent-observability]]"
    type: related_to
  - target: "[[concepts/agent-trace-and-timeline]]"
    type: related_to
  - target: "[[entities/loongsuite-platform]]"
    type: related_to
  - target: "[[entities/automq]]"
    type: related_to
  - target: "[[entities/greptimedb]]"
    type: related_to
---

# DeepFlow

**DeepFlow** 是云杉网络（Yunshan Networks）开发并开源的可观测性产品，基于 **eBPF** 实现应用性能指标、分布式追踪和持续性能剖析的**零侵扰（Zero Code）**采集，并结合 **SmartEncoding / AutoTagging** 技术实现全栈数据关联。

- **GitHub**：https://github.com/deepflowio/deepflow
- **官网**：https://deepflow.io
- **核心定位**：用 eBPF 解决可观测数据质量，用 LLM 构建高效率可观测性智能体。

## 核心能力

### 1. 零侵扰全栈采集

eBPF 程序运行时无需修改、重编译或重启应用进程，可 Hook 业务函数、系统调用、内核函数、网络/磁盘驱动函数。DeepFlow 基于 eBPF 采集的原始数据类型包括 ^[extracted]：

- Process Events（进程事件）
- File Events（文件事件）
- Perf Events（性能事件）
- Socket Events（套接字事件）
- Kernel Events（内核事件）
- Hardware Events（硬件事件）

从 Socket Events 可提取 API 的黄金指标（Request/Error/Delay），构建 Service Map、分布式追踪调用链和细粒度 API Map。

### 2. 零侵扰分布式追踪

DeepFlow 原创的**基于 eBPF 的零侵扰分布式追踪**无需插桩、无需注入 TraceID 即可实现分布式追踪，覆盖 APM 通常难以覆盖的 API 网关、微服务网关、服务网格、DNS、Redis、MySQL 等组件。该工作已被 **ACM SIGCOMM** 录用 ^[extracted]。

### 3. WebAssembly 业务 Payload 解析

针对 HTTP Payload 中的业务错误码、交易流水号、订单 ID，以及 Protobuf/Thrift 等序列化数据，DeepFlow 使用 **WebAssembly** 插件机制实现按需解析，支持 Golang、Rust、C/C++ 等语言编写插件。

### 4. AutoTagging / SmartEncoding

为数据注入统一标签：横向关联 K8s、Cloud、CMDB 资源/业务标签；纵向关联进程、线程、协程、Subnet、IP、TCP SEQ 等标签，实现全栈数据关联。

## AI Agent 治理：从"口供"到"电子眼"

AI Agent 能自主决策、调用工具，行为路径带有随机性。DeepFlow 用三个比喻切入 Agent 治理：^[extracted]

- **日志像"口供"**：靠智能体自己打印。
- **APM 像"行车记录仪"**：需要提前安装，覆盖面有限。
- **智能体治理真正需要"电子眼"**：从操作系统层独立观测，不依赖任何插桩，逻辑上无法被绕过。

企业落地 AI Agent 面临四个挑战：影子智能体不可见、行为不可预测、禁止操作无法查证、责任链难以追溯。^[extracted] 治理思路应该是"边发展、边审计、边治理"——先用电子眼把行为记录下来，出了问题再追溯并生成规范，而不是一刀切限制使用。^[extracted]

DeepFlow 通过 eBPF 从内核层采集进程行为：网络通信、文件操作、权限变化、命令执行。^[extracted] 一旦发现某个进程是智能体（如调用了大模型或向量数据库），就自动记录其所有行为，包括子进程和孙进程的完整调用链。^[extracted] 同时 DeepFlow 在智能体流量源发端给流量"盖戳"，让防火墙和服务端识别"这是智能体的流量"，实现流量层面的差异化治理。^[extracted]

## eBPF + LLM 智能体实践

DeepFlow 将 eBPF 高质量数据与 LLM 结合，聚焦三个低效场景 ^[extracted]：

### 工单智能体

工单群创建初期的混乱过程往往耗时一个多小时。AI Agent 自动拉入工单群后，调用 DeepFlow API 查看追踪、指标、事件、日志等数据，使用统计算法特征总结降低 Token 数量，再调用 LLM（主要是 GPT-4）分析。利用 Function Calling / JSON Mode 决定下一步需要分析的数据类型，最后归纳总结。

效果：虽然准确率尚未达到 100%，但已能在大多数情况下将工单群初期混乱的一多小时压缩到一分钟，并显著减少群人数 ^[extracted]。

### 变更智能体

服务发版后性能劣化根因定位困难。eBPF 能够零侵扰获取进程运行时的业务函数、库函数、运行时函数、内核函数调用栈，Profiling 可持续开启。AI Agent 利用这些 Profiling 数据快速完成根因定界。

DeepFlow 采用**分层技术栈增强策略** ^[inferred]：
- LLM 已掌握的内核/运行时/基础库函数：直接分析
- 通用库函数（如 Python Requests）：RAG 机制向量化文档增强
- 企业内部业务代码：通过 K8s Git commit_id label 注入，让 Agent 定位最近代码修改

### 漏洞智能体（探索中）

基于 eBPF 的 Cloud Workload Security 数据采集能力，覆盖 Isovalent 总结的**安全四大黄金观测信号**：Process Execution、Network Socket、File Access、Layer 7 Network Identity ^[extracted]。

## 版本形态

- **企业版**：页面中可从拓扑图、调用链追踪、持续剖析页面唤出 AI Agent，API 可被飞书 ChatBot 调用实现工单专家。
- **社区版**：已发布 AI Agent 能力，支持对 Grafana Panel 数据（Topo、Tracing）进行分析，适配 GPT、通义千问、文心一言、ChatGLM 四种大模型。

## 未来演进方向

1. 将 eBPF 能力扩展到端侧：智能汽车自动驾驶/智能空间域控、权限允许的智能手机场景 ^[extracted]
2. 持续优化 RAG 机制

## 相关页面

- [[concepts/ebpf-observability-agent]] — eBPF 在可观测性智能体中的角色
- [[concepts/ai-agent-observability]] — AI Agent 可观测性整体概念
- [[entities/loongsuite-platform]] — 阿里云类似定位的可观测产品体系
- [[entities/mcpspy-ebpf-mcp-monitoring]] — 另一个基于 eBPF 的 MCP 可观测工具
