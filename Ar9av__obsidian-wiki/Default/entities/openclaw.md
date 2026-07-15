---
title: OpenClaw
category: entities
tags: [ai, agent, security, open-source]
sources:
  - "SelectDB: 我们用 AI Observe Stack 观测了 OpenClaw (2026-03-04)"
summary: OpenClaw 是 2026 年最受关注的开源 AI Agent 平台，支持多 Channel 交互和全能力工具调用，但上线初期暴露出严重的安全问题——近千个实例暴露、512 个漏洞、CVSS 8.8 的 RCE 漏洞。
provenance:
  extracted: 0.65
  inferred: 0.25
  ambiguous: 0.10
base_confidence: 0.44
lifecycle: draft
lifecycle_changed: 2026-07-16
tier: supporting
created: 2026-07-16T00:00:00+08:00
updated: 2026-07-16T00:00:00+08:00
relationships:
  - target: "[[concepts/ai-agent-observability]]"
    type: related_to
  - target: "[[entities/ai-observe-stack]]"
    type: related_to
  - target: "[[concepts/agent-harness]]"
    type: related_to
  - target: "[[concepts/agent-trace-and-timeline]]"
    type: related_to
---

# OpenClaw

OpenClaw 是 2026 年风靡全球的开源 AI Agent 平台。它支持通过 WhatsApp、Telegram、Web 等多种渠道与用户交互，Agent 可以调用 shell 命令、浏览网页、搜索信息、操作文件、发送消息——几乎无所不能。

## 安全危机

OpenClaw 上线几周内，安全事件井喷。来自 Kaspersky、Cisco、CrowdStrike、Trend Micro、BitSight 等安全厂商的报告揭示了严峻的安全态势：

- **近 1000 个暴露实例** — 通过 Shodan 发现的 OpenClaw 实例无需认证即可访问，泄露 API 密钥、Telegram bot token 和完整聊天记录
- **512 个漏洞** — 安全审计发现 512 个漏洞，其中 8 个高危
- **CVSS 8.8 远程代码执行漏洞** — CVE-2026-25253，允许通过精心构造的输入执行任意代码 ^[ambiguous]
- **Prompt Injection 攻击** — 仅凭一封精心构造的邮件即可诱导 OpenClaw 窃取私有 SSH 密钥和 API token

## 三大黑盒问题

SelectDB 团队在搭建 OpenClaw 可观测系统时，将其问题归纳为三个黑盒：

### 安全黑盒
Agent 拥有 shell 执行权限时，它在执行什么命令？参数是什么？执行结果如何？没有可观测性时，Agent 就是服务器上一个拥有 root 权限的黑盒。

### 成本黑盒
每个用户的每次请求消耗了多少 Token？哪些 Agent 行为（工具调用、检索、推理循环）消耗了最多的 API 费用？月底账单无法回答这些问题。

### 行为黑盒
Agent 做某个决策时经历了怎样的推理链路？为什么选择了工具 A 而非工具 B？为什么在第三步开始循环？传统日志完全无法还原这种多步骤推理。

## 可观测性方案

SelectDB 团队使用 **AI Observe Stack**（基于 Apache Doris）为 OpenClaw 搭建了可观测系统，用 AI 辅助开发**在一天内完成**：

- 实时捕获所有 Agent 执行的 shell 命令及其上下文
- 建立敏感操作特征库（访问 `/etc/passwd`、SSH 密钥外传、未授权网络连接等）
- 按用户、Session、Task 维度聚合 Token 消耗
- 提供 Timeline 回放完整推理链路

这验证了"Agent 可观测性基础设施可以快速搭建"的假设，但也暴露了 Agent 安全的核心矛盾：**功能越强大的 Agent，其可观测需求越迫切** ^[inferred]。

## 行业意义

OpenClaw 的安全事件是 AI Agent 进入生产环境的标志性事件——它证明 Agent 的安全问题不是理论上的，而是正在发生的。CVE-2026-25253 和近千个暴露实例的数据，为 Agent 可观测性和安全治理的必要性提供了实证案例。^[inferred]

## Related

- [[concepts/agent-harness]] — Harness 层的执行日志和异常检测可以直接防止 OpenClaw 式的安全黑盒
- [[concepts/agent-trace-and-timeline]] — Timeline 回放是排查 OpenClaw 行为黑盒的核心手段
