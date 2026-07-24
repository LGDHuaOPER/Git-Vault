---
title: 阿里云：从 AI Agent 到模型推理的端到端 AI 可观测实践
category: references
tags:
  - ai-agent
  - observability
  - opentelemetry
  - alibaba
  - model-inference
sources:
  - "阿里云开发者社区: 从 AI Agent 到模型推理：端到端 AI 可观测实践 (2026-07-16)"
summary: 阿里云基于 OpenTelemetry 的端到端 AI 可观测实践，覆盖 AI 应用层、AI 网关、模型推理层，重点解决用得起来、用得省、用得好的三类痛点。
base_confidence: 0.72
lifecycle: draft
lifecycle_changed: "2026-07-22"
tier: supporting
provenance:
  extracted: 0.75
  inferred: 0.20
  ambiguous: 0.05
created: "2026-07-22"
updated: "2026-07-25"
relationships:
  - target: "[[entities/loongsuite-platform]]"
    type: related_to
  - target: "[[concepts/ai-agent-observability]]"
    type: related_to
  - target: "[[concepts/genai-observability-semconv]]"
    type: related_to
  - target: "[[entities/dify]]"
    type: related_to
  - target: "[[entities/vllm]]"
    type: related_to
  - target: "[[references/aliyun-python-probe-llm]]"
    type: related_to
---

# 阿里云：从 AI Agent 到模型推理的端到端 AI 可观测实践

## AI 应用开发的三类痛点

1. **用起来**：同样问题多次询问回答不同、换模型效果打折、响应卡住回不来
2. **用得省**：不知道每次调用消耗多少 Token、哪些应用消耗高
3. **用得好**：回答质量是否达标、是否存在不合理不合规内容 ^[extracted]

## 典型架构分层

从用户业务层 → AI 应用层（AI Agent）→ 模型服务层，中间通过 API 网关（如 Higress）和 AI 网关做流量防护、Token 限流、敏感信息过滤、模型内容缓存、多模型切换 ^[extracted]。

## 基于 Trace 的全链路诊断

基于 OpenTelemetry 规范，从用户端侧、API 网关、AI 应用层、AI 网关到模型层进行埋点。网关层手动埋点，应用层和模型内部层采用无侵入自动埋点，最终上报阿里云可观测平台 ^[extracted]。

AI 应用内部对 RAG、工具使用、模型调用等关键节点埋点；模型推理阶段（如 [[entities/vllm|vLLM]]/SGLang）本身也是 Python 程序，可部署探针采集内部推理信息 ^[extracted]。

## AI 应用黄金三指标

与传统微服务黄金三指标（请求数、错误、耗时）类比，AI 应用的黄金三指标可能是 **Token、Error、Duration** ^[extracted]。

关键性能指标：
- **TTFT**（Time to First Token）：首包延迟，反映响应速度
- **TPOT**（Time Per Output Token）：每输出 Token 平均耗时，反映生成效率和流畅度
- **吞吐率**：模型同时支撑的推理请求数
- **GPU 利用率、KV Cache 命中率**：基础设施层指标 ^[extracted]

## Python 探针无侵入埋点

基于 OpenTelemetry Python Agent 底座扩展，支持 [[entities/dify|Dify]]、LangChain、LlamaIndex 等框架。利用 Python monkey patch 机制，在原始方法执行前后插入采集逻辑，实现用户代码不修改即可采集 ^[extracted]。

相比开源探针，阿里云方案增强了对多进程（unicorn/gunicorn）、gevent 协程、流式上报等生产场景的支持，解决了开源探针在 gevent 模式下卡死进程的问题 ^[extracted]。

## MCP Token 黑洞问题

使用 MCP 工具的 Agent 可能最终输出 1000 Token，但背后调用几十次模型、大量 MCP Tools，实际消耗上万个 Token。中间每次调用都把历史对话和工具结果作为 input 再发给大模型，Token 消耗不断叠加。因此需要采集每个 MCP Tool 的调用耗时和 Token 消耗 ^[extracted]。

## Dify 生产环境优化实践

阿里云在实践中发现 [[entities/dify|Dify]] 在生产环境存在多个架构层面问题 ^[extracted]：

| 问题 | 表现 | 建议 |
|------|------|------|
| **Nginx 上传限制** | RAG 文档上传超过默认 Nginx body size 限制 | 调大 `NGINX_CLIENT_MAX_BODY_SIZE` |
| **PGSQL 连接池打满** | Dify workflow 每个请求保持一个 DB 连接，默认连接池过小导致业务卡住 | 调大 PGSQL 连接池至 300+ |
| **Redis 轮询过度** | Dify 通过 Redis 管理任务状态，一次 workflow 请求可能访问上千次 Redis（轮询任务状态直到结束），本质上应使用消息队列 | 大规模场景用 RocketMQ 替换 Redis 作为消息队列 |
| **gevent 协程挂死** | 挂载开源 OTel 探针时，gevent 模式导致进程 hang 住，业务无法运行 | 使用阿里云探针（已修复 gevent 兼容性） |
| **内置存储可靠性** | Dify 默认本地存储和内置向量数据库在高可用性和稳定性上存在问题 | 替换为云存储和第三方向量数据库 |
| **可观测数据孤立** | Dify 原生可观测需每个应用单独配置，数据存 PGSQL 查询效率低，无法与外部微服务串联 | 使用 OpenTelemetry 探针统一采集，支持多应用拆分、端到端串联 |

^[extracted]

## TTFT 与 TPOT 深度解析

模型推理的两个核心阶段及其关键指标 ^[extracted]：

### Prefill 阶段（TTFT）

从提示词输入 → tokenize → 计算 Token 间相似度 → 结果保存到 KV Cache → 模型吐出第一个 Token。**TTFT（Time to First Token）** 衡量此阶段耗时，是推理效率的核心指标。^[extracted]

### Decode 阶段（TPOT）

从第二个 Token 开始，每个新 Token 都需将过去生成结果作为输入重新喂给模型计算下一个 Token——这是一个不断迭代的过程。**TPOT（Time Per Output Token）** 衡量每个 Token 的平均生成间隔。^[extracted]

总推理耗时 ≈ `TTFT + TPOT × (总Token数 - 1)` ^[inferred]

### 在线 vs 离线场景的权衡

三个关键指标（TTFT、TPOT、吞吐率）无法同时最优 ^[extracted]：
- **在线推理**：优先关注更快的 TTFT 和 TPOT
- **离线分析**：优先追求更高的吞吐率，TTFT 反而没那么关注

## vLLM 推理性能定位实战

一个通过全链路可观测定位 DeepSeek 模型推理超时的真实案例 ^[extracted]：

1. 通过全链路追踪分析调用链，定位到问题在模型推理层而非应用层
2. 观察模型侧黄金指标：TTFT 正常（排除 Prefill 阶段问题），TPOT 正常（排除 Decode 阶段问题）
3. 进一步检查推理引擎排队情况 → 确认是请求队列大小不足导致排队耗时升高
4. 解决：调大推理引擎请求队列大小配置

> 这个案例展示了"端到端串接 + 推理层指标分层下钻"的排障方法论：先做层间定界，再做层内细分。^[extracted]

## MCP Token 黑洞机制

使用 MCP 工具的 Agent 面临 **Token 黑洞**问题——最终输出可能只消耗 1,000 Token，但背后调用几十次模型和大量 MCP Tools，实际消耗数万 Token。每次与模型对话时，历史对话和 MCP Tools 调用结果都作为 input 堆积给大模型，Token 消耗不断叠加。^[extracted]

因此需要采集每个 MCP Tool 的调用耗时和 Token 消耗，将 MCP 的"隐形开销"显性化。^[extracted]

## 模型质量评估管道

基于采集的模型 input/output 数据进行评估 ^[extracted]：

1. 将模型 input/output 全量采集到日志平台
2. 筛选目标记录，通过数据加工引用外部裁判员模型
3. 使用内置评估模板（质量检测/安全检测/意图提取）进行打分
4. 对评估结果进行**分类和聚类**——语义化标签孵化（如"友善回答""文化类问题"）
5. 未来支持自定义评估模板（如幻觉检测、MCP 投毒攻击检测）

^[extracted]

## 相关页面

- [[entities/agentloop]] — 阿里云 AgentLoop 自进化平台（同体系产品）
- [[entities/loongsuite-platform]] — 阿里云 LoongSuite 可观测产品体系
- [[entities/dify]] — Dify 开源 LLMOps 平台
- [[entities/vllm]] — vLLM 推理加速框架
- [[concepts/ai-agent-observability]] — Agent 可观测性整体概念
- [[concepts/genai-observability-semconv]] — OpenTelemetry GenAI 语义规范
- [[references/aliyun-python-probe-llm]] — 阿里云 Python 应用可观测：解决 LLM 落地最后一公里
