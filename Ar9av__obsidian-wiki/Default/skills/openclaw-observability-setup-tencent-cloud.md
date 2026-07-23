---
title: OpenClaw Observability Setup on Tencent Cloud
category: skills
tags: [observability, openclaw, tencent, setup, opentelemetry]
relationships:
  - target: "[[concepts/ai-agent-observability]]"
    type: implements
  - target: "[[skills/agent-observability-landing-guide]]"
    type: related_to
sources:
  - "腾讯云开发者: 告别“黑箱”养虾！腾讯云可观测平台给您的 OpenClaw 装上“透视眼” (2026-03-26)"
summary: 在腾讯云可观测平台上为 OpenClaw 接入 Trace 与 Metrics 监控的实操步骤：获取接入点、安装插件、修改配置、重启验证。
provenance:
  extracted: 0.70
  inferred: 0.25
  ambiguous: 0.05
base_confidence: 0.44
lifecycle: draft
lifecycle_changed: 2026-07-22
tier: supporting
created: 2026-07-22T00:00:00+08:00
updated: 2026-07-22T00:00:00+08:00
---

# OpenClaw Observability Setup on Tencent Cloud

本指南介绍如何通过腾讯云可观测平台为 OpenClaw 接入全链路 [[concepts/ai-agent-observability|可观测能力]]，实现 Trace 链路追踪与 Metrics 指标监控。

## 前置条件

- 已部署 OpenClaw（直接安装或 Docker 部署）
- 拥有腾讯云账号并开通可观测平台服务

## 步骤一：获取接入点和 Token

1. 登录腾讯云控制台 → 可观测平台
2. 选择 **LLM 可观测 → 应用列表**
3. 点击右上角"接入应用"
4. 选择地域与业务系统，单击 **OpenClaw**
5. 记录系统分配的接入点与 Token

## 步骤二：安装插件依赖

`openclaw-tencent-plugin` 是腾讯云 APM 可观测性增强插件，为 OpenClaw 提供全链路分布式追踪能力，自动构建 parent-child span 树。该插件依赖 `diagnostics-otel` 提供的全局 OTel SDK，需在 `diagnostics-otel` 之后加载。

在 OpenClaw 的 extensions 目录下安装：

```bash
cd ~/.openclaw/extensions/openclaw
plugins install openclaw-tencent-plugin
```

## 步骤三：修改配置文件

编辑 OpenClaw 配置文件：

- 直接安装：`~/.openclaw/openclaw.json`
- Docker 部署：宿主机上映射到容器的配置目录

添加插件启用和 OTel 导出配置（具体字段参考腾讯云控制台给出的配置示例）。

## 步骤四：重启 OpenClaw

直接安装：

```bash
openclaw gateway restart
```

Docker 部署：

```bash
docker compose restart
```

## 步骤五：接入验证

验证插件状态：

```bash
openclaw plugins list
```

在输出列表中找到 `diagnostics-otel`，确认状态为 `loaded`。

Docker 环境：

```bash
docker exec -it <container> openclaw plugins list
```

验证数据上报：

1. 确保 OpenClaw 有正常业务流量
2. 登录腾讯云可观测平台控制台
3. 选择 **LLM 可观测**，查看应用列表是否出现配置的应用名
4. 进入应用详情页 → 实例分析，确认可以看到接入的应用实例

> 可观测数据处理存在一定延时，若未立即看到数据，请等待约 30 秒后刷新。

## 接入后可观测内容

- **全链路结构化追踪**：`enter_openclaw_system → invoke_agent → chat → execute tool`
- **Token 消耗精细拆解**：输入 / 输出 / 缓存读写 Token，按模型与场景聚合
- **系统运行指标**：QPS、响应耗时、错误率、队列深度、会话总数、卡死会话、上下文大小变化

## Related

- [[concepts/ai-agent-observability]] — Agent 可观测性整体概念（本指南的实现基础）
- [[skills/agent-observability-landing-guide]] — Agent 可观测性从 0 到 1 落地路径
- [[entities/tencent-cloud-observability-llm]] — 腾讯云可观测平台 LLM 可观测
- [[entities/openclaw]] — OpenClaw 平台
- [[references/2026-03-26-tencent-cloud-openclaw-observability]] — 官方接入文档来源