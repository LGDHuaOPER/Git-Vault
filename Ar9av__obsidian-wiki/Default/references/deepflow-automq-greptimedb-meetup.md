---
title: 从 eBPF 到 LLM：可观测性管道的每一层都在变｜上海 Meetup 回顾
category: references
tags:
  - observability
  - ebpf
  - kafka
  - greptimedb
  - meetup
sources:
  - "DeepFlow: 从 eBPF 到 LLM：可观测性管道的每一层都在变｜上海 Meetup 回顾 (2026-04-28)"
summary: 2026 年 4 月上海 Meetup 回顾，DeepFlow、AutoMQ、GreptimeDB 三家公司分别从 eBPF 零侵扰采集、Diskless Kafka 传输、统一存储与 LLM 分析三个层面讨论下一代可观测数据栈的工程实践。
provenance:
  extracted: 0.75
  inferred: 0.20
  ambiguous: 0.05
base_confidence: 0.53
lifecycle: draft
lifecycle_changed: 2026-07-22
tier: supporting
created: 2026-07-22T00:00:00+08:00
updated: 2026-07-22T00:00:00+08:00
relationships:
  - target: "[[entities/deepflow]]"
    type: related_to
  - target: "[[entities/automq]]"
    type: related_to
  - target: "[[entities/greptimedb]]"
    type: related_to
---

# 从 eBPF 到 LLM：可观测性管道的每一层都在变｜上海 Meetup 回顾

2026 年 4 月 25 日，Greptime、AutoMQ、DeepFlow（云杉网络）在上海联合主办「当可观测性遇上 AI：下一代数据栈的工程实践」Meetup。^[extracted] 议题覆盖 eBPF 零侵扰采集、云原生 Diskless 消息队列、Metrics/Logs/Traces 统一存储三个层面，并通过 Lightning Talk 把三者串成一条完整管道。^[extracted]

## 议题一：谁来监管你的 AI Agent？

**讲师**：向阳（云杉网络总裁，清华大学博士，曾在 ACM SIGCOMM 发表可观测性方向论文）^[extracted]

核心观点：
- 日志像"口供"，APM 像"行车记录仪"，智能体治理需要"电子眼"。^[extracted]
- DeepFlow 用 eBPF 从操作系统内核层采集进程行为：网络通信、文件操作、权限变化、命令执行。^[extracted]
- 自动识别智能体进程（调用大模型或向量数据库），记录包括子进程、孙进程在内的完整调用链。^[extracted]
- 在智能体流量源发端"盖戳"，让防火墙和服务端识别"这是智能体的流量"。^[extracted]
- 治理思路："边发展、边审计、边治理"，先记录再规范，不一刀切限制。^[extracted]

## 议题二：AutoMQ：基于共享存储架构的新一代 Diskless Kafka

**讲师**：万凯明（AutoMQ 解决方案架构总监）^[extracted]

核心观点：
- 传统 Kafka 的 Shared-Nothing 架构在云上出现错配：云盘贵、扩缩容困难、跨 AZ 流量费高。^[extracted]
- AutoMQ fork Kafka 代码，将存储层替换为自研 S3 Stream 引擎，100% 兼容 Kafka 协议，Broker 无状态。^[extracted]
- 通过 WAL Storage 抽象层将 P99 延迟控制在 10ms 以内。^[extracted]
- 落地案例：米哈游 350K+ QPS、爱奇艺成本降低 70%、吉利汽车稳定运行近三年、得物 40+ GiB/s 峰值吞吐。^[extracted]

## Lightning Talk：从 eBPF 到 LLM 的端到端 Demo

**讲师**：庄晓丹（Greptime CEO）^[extracted]

演示管道：

```
DeepFlow 零侵扰采集 → AutoMQ 传输 → GreptimeDB 统一存储 → MCP + LLM 智能分析
```

- 全程 Diskless，数据存在对象存储上（本地用 MinIO 模拟）。^[extracted]
- 20 个 Pod、5 个 Namespace 的 K8s 集群上运行。^[extracted]
- 北极星指标：端到端延迟约 5 秒，错误率 0.24%，吞吐 200+ span/秒，累计采集超 140 万条 Span。^[extracted]
- 通过 GreptimeDB 的 MCP Server 接入大模型，可用自然语言查询 Metrics、Logs、Traces 统一存储的数据。^[extracted]

## 议题三：GreptimeDB 在 OB Cloud 多云的大规模日志存储实践

**讲师**：闫树松（OceanBase 公有云高级研发专家）^[extracted]

核心数据：
- OB Cloud 日志存储已全部切换到 GreptimeDB 企业版。^[extracted]
- **80+ 套集群，300 TB 数据（7 天保留），最大单集群超 50 TB，平均写入流量超 1 GB/s**。^[extracted]
- 日志存储成本降低 **60%**，同步下调对客 SQL 审计服务定价，帮助用户节省 60% 以上 SQL 审计成本。^[extracted]

OB Cloud 智能诊断 Agent 通过 GreptimeDB 的 MCP Server 查日志和 SQL 审计数据，通过 OB Server MCP Server 查内部表，配合 PromQL 查指标。^[extracted]

## 相关页面

- [[entities/deepflow]] — eBPF 零侵扰可观测平台
- [[entities/automq]] — Diskless Kafka
- [[entities/greptimedb]] — 统一可观测性数据库
