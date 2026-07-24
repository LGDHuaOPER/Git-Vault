---
title: "LLM GPU Observability"
category: concepts
tags:
  - llm
  - gpu
  - observability
  - inference
  - monitoring
sources:
  - "技术工匠: LLM 可观测性：从 GPU 监控到安全护栏（第五章） (2026-04-20)"
  - "云原生观测: 使用 OpenTelemetry 观测 vLLM (2026-05-25)"
summary: "LLM 推理场景下的 GPU 级监控——从传统的 CPU/请求数监控转向 Token 维度（TTFT/TPOT/Token 吞吐量），覆盖 vLLM 指标采集、NVIDIA DCGM/AMD ROCm/Intel XPU 三厂商 GPU 监控工具链，以及模型质量与安全护栏的联合观测。"
base_confidence: 0.55
lifecycle: draft
lifecycle_changed: "2026-07-24"
tier: supporting
provenance:
  extracted: 0.60
  inferred: 0.30
  ambiguous: 0.10
created: 2026-07-24
updated: 2026-07-25
relationships:
  - target: "[[concepts/ai-agent-observability]]"
    type: extends
  - target: "[[concepts/genai-observability-2.0]]"
    type: related_to
  - target: "[[entities/vllm]]"
    type: uses
  - target: "[[concepts/llm-as-judge-evaluation]]"
    type: uses
---

# LLM GPU Observability

LLM 推理的可观测性与传统微服务有本质差异：计算主力是 GPU 而非 CPU，且推理的两个阶段——**Prefill（预填充，计算密集型）**和**Decode（解码，显存密集型）**——表现特征截然不同 ^[extracted]。传统的"请求数"在 LLM 场景中几乎没有参考价值，**Token 才是真正的计量单位**。

## Token 级关键指标

### TTFT — 首 Token 时间

TTFT（Time To First Token）衡量用户从发出请求到收到第一个 Token 的等待时间，本质上是 Prefill 阶段的耗时 ^[extracted]。对于聊天机器人等实时场景，这是最关键的用户体验指标；离线批处理则可放松此要求。vLLM 通过 `vllm:time_to_first_token_seconds` 暴露此指标。

### TPOT — 每 Token 耗时

TPOT（Time Per Output Token，也称 Inter-Token Latency / ITL）衡量每个后续 Token 的生成速度 ^[extracted]。人类平均阅读速度约每秒 3 个词，因此至少需保证 4~5 tokens/sec 才能让用户感知不到延迟。这是 Decode 阶段的直接反映，通过 `vllm:time_per_output_token_seconds` 暴露。

### Token 吞吐量

vLLM 分别提供输入 Token 处理速率（`prompt_tokens_total`）和输出 Token 生成速率（`generation_tokens_total`），以及合计指标（`tokens_total`）^[extracted]。需注意：一个长请求可能把 GPU 全占满，请求数和 Token 数之间没有简单换算关系。

### 请求队列

`num_requests_waiting` 和 `num_requests_running` 是自动伸缩的天然触发信号 ^[extracted]。当请求超过当前 Batch 容量时，vLLM 会排队。

## vLLM OpenTelemetry Span 属性

设置 `--otlp-traces-endpoint` 后，vLLM 为每次推理请求导出 OTel span（需 `pip install vllm[otel]` 安装 OTel 可选依赖）^[extracted]。Span 属性定义在 vLLM 的 `SpanAttributes` 类（`vllm/tracing/utils.py`）中，关键设计决策：**vLLM 刻意固定自己的属性名，而不是紧跟不断演进的 OTel GenAI 语义约定**——这是为了稳定性，但也意味着 vLLM 完全不发出 OTel span 事件，追踪完全基于属性 ^[extracted]。

| 属性 | 含义 |
|------|------|
| `gen_ai.request.model` / `gen_ai.response.model` | 处理请求的模型 |
| `gen_ai.usage.prompt_tokens` | 输入 token 数，用于成本与容量跟踪 |
| `gen_ai.usage.completion_tokens` | 输出 token 数 |
| `gen_ai.system` | 固定为 `vllm` |
| `gen_ai.operation.name` | 操作名（如 `chat`） |

推理延迟的拆分是 vLLM OTel 的核心价值——将一次请求拆为调度、prefill、decode 三个阶段，各阶段的延迟在负载下表现不同，调优策略也不同 ^[extracted]。KV 缓存压力会引发抢占导致吞吐下降但不一定表现为错误，TTFT 与 TPOT 在批处理负载下可能明显背离，队列深度能在用户感知到变慢之前提前预警容量上限 ^[extracted]。

## GPU 厂商工具链

各 GPU 厂商的方案思路一致：管理组件采集 GPU 使用数据 → 导出器暴露 `/metrics` → Prometheus 接入 ^[extracted]。

| 厂商 | 管理组件 | 导出器 | 部署方式 |
|------|---------|--------|---------|
| NVIDIA | DCGM (Data Center GPU Manager) | DCGM-Exporter | GPU Operator 一键 Helm 部署 |
| AMD | ROCm SMI | AMD Device Metrics Exporter | AMD GPU Operator |
| Intel | XPU Manager | Prometheus Metric Exporter | — |

这些工具覆盖利用率、显存、温度、功耗、PCIe 带宽等底层指标。各厂商的指标命名尚未统一，但通过 GPU Operator 的自动部署能力，运维负担已大幅降低 ^[ambiguous]。

## Prometheus + KServe 采集

在 KServe 环境中配置监控仅需两步 ^[extracted]：

1. 在 ServingRuntime 上通过注解声明指标端点：
   - `prometheus.kserve.io/port: '8080'`
   - `prometheus.kserve.io/path: "/metrics"`
2. 在 InferenceService 上启用 `serving.kserve.io/enable-prometheus-scraping: "true"`

KServe 控制器会自动将 Prometheus 注解注入 Pod，配合 ServiceMonitor 实现 15 秒间隔自动抓取。

**Knative 模式注意**：Pod 中同时运行模型服务器、Knative Sidecar 和 Istio Proxy，Prometheus 只能抓取单一端点。KServe 提供 qpext 指标聚合组件（通过 `serving.kserve.io/enable-metric-aggregation` 启用）来聚合所有容器的指标。

## 模型质量监控

LLM 有一个传统应用没有的风险：**它不会崩溃，但会一本正经地胡说八道** ^[extracted]。传统应用遇到异常数据会报错，但 LLM 会"优雅地"返回一个听起来合理、实际完全错误的结果。

### [[concepts/llm-as-judge-evaluation|LLM-as-a-Judge]] 异步评估

从全部推理请求中抽取 1%~10% 的响应，用 GPT-4 或专用裁判模型从相关性、连贯性、事实性、安全性等维度打分 ^[extracted]。关键是**异步处理**——不能阻塞用户请求。评估结果导出为 Prometheus 指标后，与基础设施指标一起做趋势追踪和降级告警。

评估提示词要具体——不要问"这个回答对不对？"，而是问"这个回答的语气是否正式？""是否包含个人隐私信息？"——越聚焦，裁判模型越可靠。

## 安全护栏（Guardrails）

在输入端和输出端双重部署安全护栏 ^[extracted]：

| 方案 | 来源 | 特点 |
|------|------|------|
| **NeMo Guardrails** | NVIDIA | Colang 领域语言定义对话流和安全约束，支持输入/对话/检索/执行/输出五类 Rails，可部署为 K8s 容器 |
| **FMS Guardrails Orchestrator** | IBM | 集成 TrustyAI，编排多个检测器形成安全管道，违规行为自动导出为 Prometheus 指标 |
| **Guardrails AI** | 社区 | Python 库 + Hub 预置检测器，代码级集成，适合嵌入应用层 |
| **Llama Stack Safety** | Meta | Safety API + Shield 机制 + `/v1/moderations` 端点，预训练分类模型 |

**成本 vs 安全的平衡**：用另一个 LLM（如 7B 的 Llama Guard）做安全检测会增加延迟和资源消耗。关键是在精确度（更小的专用模型）和召回率（更强大的通用模型）之间找到适合场景的平衡点 ^[inferred]。

## SLI/SLO/SLA：用 Token 指标定义服务质量

传统 SRE 的 SLI/SLO/SLA 层次在 LLM 领域同样适用，只是指标需要"换血" ^[extracted]：

- **SLI**：实测的 TPOT 值——这是用户最直接的感受
- **SLO**：承诺 99.999% 的请求 TPOT 低于 0.1 秒
- **SLA**：月度可用性 99.9%，违反则进入合同处罚

建议把质量指标也纳入 SLI 体系——不仅是基础设施快不快，还要看模型输出对不对、安不安全。建立**质量 SLO**，与延迟 SLO 并列追踪 ^[inferred]。

## 与传统应用监控的差异

| 维度 | 传统微服务 | LLM 推理 |
|------|-----------|---------|
| 计算主力 | CPU | GPU |
| 计量单位 | 请求数 (QPS) | Token 数 (TPS) |
| 故障模式 | 报错/500 | 返回 200 但答案错误 |
| 延迟特征 | 固定/可预测 | 非确定，Prefill vs Decode 两极 |
| 质量监控 | 不需要 | 必须（幻觉/注入检测） |

## 采集架构

```
LLM 应用 → vLLM (OpenMetrics /metrics) → Prometheus → Grafana
         → vLLM (OTLP traces) → Jaeger/Tempo
         → 日志 → Grafana Loki
         → GPU 指标 → DCGM-Exporter → Prometheus
         → 质量评估 → LLM-as-Judge (异步) → Prometheus
```
