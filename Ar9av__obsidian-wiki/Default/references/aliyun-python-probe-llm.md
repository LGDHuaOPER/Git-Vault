---
title: 阿里云 Python 应用可观测：解决 LLM 落地最后一公里
category: references
tags:
  - ai-agent
  - observability
  - alibaba
  - python
  - arms
sources:
  - "阿里云可观测: Python 应用可观测重磅上线：解决 LLM 应用落地的“最后一公里”问题 (2024-11-08)"
summary: 阿里云 2024 年 11 月推出 Python 探针，面向 Langchain、Llama-index、Dify、PromptFlow、OpenAI、Dashscope 等 Python LLM 应用提供零代码改造的可观测接入。
provenance:
  extracted: 0.75
  inferred: 0.20
  ambiguous: 0.05
base_confidence: 0.73
lifecycle: draft
lifecycle_changed: 2026-07-22
tier: supporting
created: 2026-07-22T00:00:00+08:00
updated: "2026-07-22"
relationships:
  - target: "[[entities/loongsuite-platform]]"
    type: related_to
  - target: "[[concepts/ai-agent-observability]]"
    type: related_to
  - target: "[[entities/dify]]"
    type: related_to
---

# 阿里云 Python 应用可观测：解决 LLM 落地最后一公里

> 原文：Python 应用可观测重磅上线：解决 LLM 应用落地的“最后一公里”问题（阿里云可观测，2024-11-08）

## 背景

Python 是 AI 时代主流编程语言，Langchain、Llama-index、[[entities/dify|Dify]]、PromptFlow、OpenAI、Dashscope 等热门 LLM 项目均使用 Python。阿里云推出 Python 探针，旨在降低 LLM 应用落地门槛。

## 接入方式

以 ACK 环境为例：

1. **安装 ARMS 应用监控组件**：在容器服务控制台安装 `ack-onepilot`（版本需 ≥ 3.2.4）。
2. **修改 Dockerfile**：
   - `pip3 install aliyun-bootstrap`
   - `aliyun-bootstrap -a install`
   - 使用 `aliyun-instrument python app.py` 启动
3. **授予 ARMS 资源访问权限**：配置 AliyunARMSFullAccess 权限，填写有 ARMS 权限的阿里云账号 AK/SK。
4. **开启应用监控**：在 Deployment YAML 的 `spec.template.metadata.labels` 中添加：
   - `aliyun.com/app-language: python`
   - `armsPilotAutoEnable: 'on'`
   - `armsPilotCreateAppName: <应用名>`

## 产品能力

- **调用链分析**：自由组合筛选与聚合维度，支持错/慢 Trace 分析。
- **大模型场景新版 TraceView**：直观分析不同操作类型的输入输出、Token 消耗。
- **监控指标**：应用概览、应用拓扑。
- **配置告警**：针对特定应用制定告警规则，支持钉钉等通知方式。

## 兼容性

Python 版本 ≥ 3.8。

## 参考链接

- 应用监控指南：https://help.aliyun.com/zh/arms/application-monitoring/user-guide/start-monitoring-python-applications/
- Python 探针兼容性：https://help.aliyun.com/zh/arms/application-monitoring/developer-reference/python-probe-compatibility-requirements
