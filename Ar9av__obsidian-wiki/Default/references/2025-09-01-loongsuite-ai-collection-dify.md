---
title: "零代码改造！LoongSuite AI 采集套件观测实战"
category: references
tags: [observability, loongsuite, dify, alibaba, zero-code]
sources:
  - "阿里云可观测: 零代码改造！LoongSuite AI 采集套件观测实战 (2025-09-01)"
summary: 阿里云 LoongSuite AI 采集套件无侵入观测 Dify 的实战文章，覆盖 Python/Go 埋点原理与端到端链路串联。
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
relationships:
  - target: "[[entities/loongsuite-platform]]"
    type: describes
---

# 零代码改造！LoongSuite AI 采集套件观测实战

阿里云可观测团队介绍 LoongSuite AI 采集套件如何以零代码方式接入 Dify，实现 AI 原生应用的全链路可观测。

## AI 原生应用的可观测诉求

典型 AI 原生应用链路：用户终端 → Higress 网关 → 模型应用层（Dify / LangChain / Spring AI Alibaba）→ 模型服务层（Qwen / DeepSeek 等）。

可观测需要解决三个问题：

1. **调用链串联**：一次调用经过哪些组件，快速定界问题环节
2. **全栈数据关联**：链路、指标、GPU 利用率等数据跨维度关联分析
3. **模型输入输出与评估**：利用每次调用的 prompt/response 做质量评估

Agent 场景中尤其需要关注 **MCP Token 黑洞**——最终输出 token 不多，但中间多轮交互消耗惊人，甚至可能陷入死循环。

## LoongSuite 无侵入埋点原理

### Python Agent

利用 Python 的 **monkey patch** 机制，在运行时动态替换目标函数，在原始方法前后插入包装逻辑采集数据，无需修改业务代码。

### Go Agent

源于 `alibaba/opentelemetry-go-auto-instrumentation` 项目，通过 Go 的 `go toolexec` 能力在编译器前端和后端之间插入中间层，基于 AST 语法树分析在编译时注入埋点代码。只需修改编译命令，无需修改代码。

## Dify 观测实战

- 在 ACK/SAE 上一键部署 Dify
- 给 `dify-api`（Python）添加 label 即可无侵入接入 LoongSuite
- 对 `dify-plugin-daemon`（Go）使用 LoongSuite Go Agent 重新编译镜像
- 最终可在控制台同时看到 Python 与 Go 组件的监控数据，且调用链成功串联

## 方案优势

相比 Dify 原生可观测或纯 OTel 方案，LoongSuite 提供：

- 更全面的端到端链路追踪
- 一次接入对所有 Dify 应用生效
- 无侵入式集成，不受 gevent 等运行时限制
- 后期升级维护成本低

## Related

- [[entities/loongsuite-platform]] — LoongSuite 产品体系
- [[entities/dify]] — Dify LLMOps 平台
- [[concepts/genai-observability-semconv]] — OpenTelemetry GenAI 语义规范