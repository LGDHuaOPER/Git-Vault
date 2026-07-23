---
title: Wiki Index
updated: 2026-07-23T00:00:00.000Z
---

# Wiki Index

*This index is automatically maintained. Last updated: 2026-07-23T00:00:00.000Z*

## Concepts

- [[concepts/agent-causal-attribution]] — Agent 因果归因超越
- [[concepts/agent-cost-breakdown]] — Agent 系统成本的四大构成（输入Token/输出Token/工具费用/重试浪费）及其观测方法，包括成本归因、智能路由降本、多租户计费模式。
- [[concepts/agent-data-flywheel]] — Agent 质量提升的数据飞轮模式——将全链路观测、Trace 评估、迭代优化、实验评测整合为自增强闭环，持续提升系统质量。
- [[concepts/agent-evaluation-framework]] — Agent 评测的完整方法论框架——涵盖 Anthropic 评测流水线（Task/Trial/Transcript/Outcome/Grader/Suite/Harness）、pass@k 与 pass^k 指标、能力评测 vs 回归评测攻守策略、阿里工程化体系（P0/P1/P2 指标分级、分层筛查、5 步根因定位、3 条反馈生产线）、评测集四类来源构建、五维评测维度设计。
- [[concepts/agent-failure-taxonomy]] — Agent 失败的分类体系：不只是 binary error，而是细分为 LLM 错误、工具错误、检索错误、格式错误、权限错误、上下文错误、循环错误、安全错误、人工介入等具体类别，每类有不同的根因和恢复策略。
- [[concepts/agent-harness]] — Agent Harness 是围绕 AI Agent 执行环境的工程框架层，涵盖执行日志、Trace 链路、指标采集、决策归因、任务状态、异常检测、评估回放等能力，是生产级 Agent 项目的基础设施。
- [[concepts/agent-observability-fundamentals]]
- [[concepts/agent-observability-metrics]] — Agent 可观测性指标应以 SLO 为驱动，围绕结果、过程、成本、质量四组核心指标构建，避免
- [[concepts/agent-observability-paradigm]]
- [[concepts/agent-online-evaluation]] — Agent 在线评估体系的设计——实时告警、Badcase 挖掘、在线加工引擎，以及离线与在线互补的差分评估策略。
- [[concepts/agent-trace-and-timeline]] — Agent Trace 是有序的、多层级嵌套的执行链路记录，区别于传统 APM 的扁平 request-response trace。Agent Timeline 将 Trace 可视化为时间轴，支持按执行顺序回放完整推理过程。
- [[concepts/agent-trace-cost-quality-architecture]] — 将分布式追踪、成本账本、质量评分统一在 OpenTelemetry GenAI 语义约定之上——让 on-call 在 5 分钟内回答
- [[concepts/agent-trace-span-taxonomy]] — Agent Run 的 Trace/Span 结构设计：树状层次模型、SpanKind 映射规则、推理过程与工具调用的记录策略、以及 Attribute vs Event 的正确使用边界。
- [[concepts/ai-agent-observability]] — AI Agent 可观测性是理解、调试和治理 AI Agent 系统内部状态与行为的完整能力体系。核心问题是
- [[concepts/ai-coding-agent-observability]] — 专门针对运行在开发者本地机器上的 AI Coding Agent（Cursor、Claude Code、Codex、Qoder 等）的可观测性实践，核心挑战是端侧数据分散、Agent 格式异构、行为链路分层复杂。
- [[concepts/ai-observability-layered-architecture]] — 将 AI 可观测性工具按职责分为标准层、语义层、工作台层和网关/成本层，避免
- [[concepts/ai-production-engineering-five-pillars]] — AI 运行工程化的五维框架：可观测性、评估、治理、安全、成本。从实验品到生产基础设施所需的全套工程实践，以及分阶段落地路线图。
- [[concepts/ebpf-observability-agent]] — 以 eBPF 作为高质量可观测信号源基础设施，叠加 LLM 的推理与决策能力，构建零侵扰、全栈、高效率的可观测性智能体。
- [[concepts/evaluation-driven-development]] — EDD (Evaluation Driven Development)：先观测 Agent 真实行为，用量化评估打分，用评估数据驱动 Prompt 调优和模型选型——让
- [[concepts/genai-observability-2.0]] — 面向 LLM 和 AI Agent 的新一代可观测范式，在传统 APM 之外新增成本、安全、质量三大支柱，解决
- [[concepts/genai-observability-semconv]] — OpenTelemetry GenAI Semantic Conventions 是 OTel 社区为生成式 AI 场景制定的可观测数据采集标准，2026 年 5 月随 OTel CNCF 毕业进入稳定期。定义了 Model、Prompt、Token、Tool Calling、Agent、Session 等概念的统一字段命名和数据模型。中国社区（阿里/蚂蚁）在此基础上提出了 Entry/Step Span、Skill 语义、Token 级推理观测三项扩展。
- [[concepts/llm-as-judge-evaluation]] — LLM-as-Judge 评估方法论：用 LLM 作为评判器对 Agent 输出进行自动化质量评估，涵盖忠实度、相关性、安全性等维度，以及三级评估体系（自动化/半自动/人工）。
- [[concepts/llm-observability-tool-selection]] — 基于 LangSmith、Langfuse、Arize Phoenix、Datadog、Lunary、TruLens、Helicone 七款主流 LLM 可观测性平台的能力差异与适用场景，建立按现有技术栈、数据要求和当前痛点三维度选型的决策框架。
- [[concepts/observability-3-0]] — 可观测性的第三代演进，从“还活着吗”到“为什么答错了、怎么改、改完会不会更好”，将 Trace/Metric/Log/Prompt/Score/Dataset/Experiment 纳入统一底座。
- [[concepts/rag-observability]] — RAG 可观测性将检索层作为独立观测对象——覆盖检索输入、召回结果、重排结果、引用片段四个信号层，以及 Context Precision、Faithfulness、Answer Relevance 三个 RAGAS 核心指标。RAG 质量是生产环境中最常被低估的故障源。
- [[concepts/umodel]] — 阿里云云监控 AI Agent 可观测产品的统一建模体系，将基础设施、AI 服务、AI 资产等实体默认关联，实现全域数据无缝关联。

## Entities

- [[entities/acs-agent-sandbox]] — 阿里云容器服务推出的 AI Agent 运行沙箱环境，基于 Kubernetes 提供安全、隔离、可扩展的 Agent 运行平台。
- [[entities/agenttrace]] — UC Berkeley 提出的 LLM Agent 三层结构化追踪框架——操作面（做了什么）、认知面（为什么这样做）、上下文面（与外部世界的交互）——统一为一个共享信封 Schema。
- [[entities/ai-observe-stack]] — AI Observe Stack 是基于 Apache Doris / SelectDB 构建的开源 AI Agent 可观测平台，通过 OpenTelemetry Collector + Doris + Grafana 提供 Traces/Metrics/Logs 三合一能力，5 分钟可完成部署。
- [[entities/alicloud-cloudmonitor-ai-agent-observability]] — 阿里云云监控 2026 年发布的 AI Agent 可观测产品，定位为企业生产级 Agent 首选全域观测平台，采用四层架构覆盖接入/数据/分析/应用。
- [[entities/apache-doris-agent-observability]] — Apache Doris 如何通过 VARIANT 类型、倒排索引、PipelineX 执行引擎和存算分离架构，成为 AI Agent 可观测性场景的理想存储分析引擎。
- [[entities/arize-phoenix]] — Arize Phoenix 是基于 OpenTelemetry 的开源 AI 可观测性平台，专为 LLM 应用设计，提供 Tracing、Evaluation、Prompt 管理等核心能力，支持自托管部署和多种 Agent 框架集成。
- [[entities/automq]] — 基于共享存储架构的云原生 Diskless Kafka，100% 兼容 Kafka 协议，通过 S3 Stream 引擎实现秒级扩缩容、跨 AZ 零流量费和低成本可观测数据管道。
- [[entities/bonree-one]] — 博睿数据核心产品 Bonree ONE，一体化智能可观测平台，2026 年 3 月正式上架华为云国际站基线解决方案库。
- [[entities/coze-loop]] — 字节跳动开源的 AgentOps 平台（扣子罗盘），通过全链路 Trace、性能监控、评测集与评估器闭环，以及 BadCase 自动回流，实现智能体从开发到运维的工程化迭代。
- [[entities/deepflow]] — 云杉网络开源的可观测性产品，基于 eBPF 实现零侵扰（Zero Code）应用性能指标、分布式追踪和持续性能剖析，并通过 LLM 构建工单、变更、漏洞等场景的可观测性智能体，也作为 Agent 治理的
- [[entities/deepseek-observability-agent]] — 云观秋毫团队在故障定位智能体中的大模型选型实践——DeepSeek 在 JSON 理解、自然语言规则执行准确率和成本三方面综合表现最优。
- [[entities/dify]] — 开源 LLMOps 平台，通过声明式 YAML 定义 AI 应用，提供可视化 Prompt 编排、运营和数据集管理，广泛用于快速构建 LLM 应用和 Agent。
- [[entities/greptimedb]] — GreptimeDB 是新一代可观测性数据库，基于 OpenTelemetry GenAI 语义规范，将 Traces、Metrics 和对话记录统一存储在同一数据库中，支持跨信号关联查询、流处理聚合、全文检索和自然语言分析。
- [[entities/helicone]] — 偏网关与成本层的 LLM 可观测性方案，通过请求代理、多模型路由、Token 计费与配额控制，解决生产入口治理问题。
- [[entities/langfuse-llm-observability]] — Langfuse 是目前最成熟的开源 LLM 可观测平台（约 29K Star，月 SDK 安装超 5000 万次），提供 Trace 可视化、Prompt 版本管理、数据集评估、Playground 调试环境等核心能力，支持自托管与 SaaS，被 63 家财富 500 强企业采用。
- [[entities/langfuse]]
- [[entities/langsmith]] — LangChain 公司推出的商业闭源 LLM 应用可观测与评测平台，深度绑定 LangChain/LangGraph 生态，提供思维链可视化、生产监控、LLM-as-Judge 和人工标注集成。
- [[entities/litefuse]] — 基于 Apache Doris 构建的开源 Agent 可观测与评估平台，兼容 Langfuse SDK，存储成本降低 65%-88%，支持单进程 25 秒极简部署。
- [[entities/loongsuite-pilot]] — 阿里云 2026 年 6 月开源的端侧 AI Coding Agent 可观测采集器，统一采集 Cursor、Claude Code、Codex、Qoder 等本地 Agent 的行为数据，补齐端侧可观测盲区。
- [[entities/loongsuite-platform]] — LoongSuite 是阿里云推出的 AI 可观测产品体系，包含 LoongCollector（主机探针）、语言 Agent SDK（自动插桩）、和 LoongSuite Pilot（端侧 AI Coding Agent 采集器），基于 OpenTelemetry GenAI SemConv 实现标准化采集。
- [[entities/lunary]] — 开源 LLM 可观测性平台，强调轻量接入，侧重用户会话、成本统计和用户反馈，适合早期产品团队快速看清线上使用情况。
- [[entities/mcpspy-ebpf-mcp-monitoring]] — MCPSpy——基于 eBPF 内核技术的 MCP 协议无侵入可观测工具。在操作系统内核层面拦截 MCP 协议的 JSON-RPC 通信，无需修改任何应用代码即可捕获完整的 MCP 交互轨迹。
- [[entities/mlflow]] — Linux 基金会旗下的开源 MLOps 平台，通过 Trace 与 GenAI Evaluation 模块为智能体提供可观测性与评测能力，适合作为底层实验管理底座。
- [[entities/nova-flow]] — 支付宝面向行业 Agent 的 NovaFlow 三层可观测评估框架，聚焦在线效果、端到端链路、问题处置修复三大能力。
- [[entities/openclaw]] — OpenClaw 是 2026 年最受关注的开源 AI Agent 平台，支持多 Channel 交互和全能力工具调用，但上线初期暴露出严重的安全问题——近千个实例暴露、512 个漏洞、CVSS 8.8 的 RCE 漏洞。SelectDB 团队用 AI Observe Stack 对其 7 天全量审计，揭示了 Agent 的安全、成本、行为三大黑盒问题。
- [[entities/opencompass]] — 上海人工智能实验室开源的大模型及智能体全维度评测平台（司南评测体系），提供工具调用、任务规划、代码解释器等专项评测集，偏基准测试而非生产可观测。
- [[entities/openllmetry]] — Traceloop 推出的 OpenTelemetry 库，用于快速为 LangChain 等 LLM 应用自动插桩，自动捕获 OpenAI 调用、Vector DB 检索等遥测数据。
- [[entities/openobserve]] — 基于 Rust 的开源全栈可观测性平台，单二进制部署，内置 Logs/Metrics/Traces/Dashboards/Alerts，通过 Parquet + 对象存储降低存储成本。
- [[entities/signoz]] — 天生支持 OpenTelemetry 的开源 APM，为 traces、metrics、logs 提供统一可视化后端，常与 OpenLLMetry 配合构建开源 LLM 可观测栈。
- [[entities/tencent-cloud-observability-llm]] — 腾讯云可观测平台面向 LLM 应用的可观测解决方案，通过 OpenTelemetry + 双插件协同为 OpenClaw 等 Agent 提供 Trace 与 Metrics 一体化监控。
- [[entities/trulens]] — 以评测为中心的开源框架，提出 RAG Triad 从上下文相关性、回答相关性和事实依据三个维度系统评估 RAG 质量。
- [[entities/vllm]] — 开源大模型推理加速框架，通过 PagedAttention、KV Cache 复用等技术提升推理效率，其 Python 程序特性使其可被 OpenTelemetry 探针无侵入观测。

## Synthesis

- [[synthesis/genai-observability-semconv-x-langfuse-llm-observability]] — Standard vs Product: the gap between evolving OTel GenAI SemConv telemetry fields and Langfuse's production workflow artifacts (Prompt versions, Datasets, Scores).
- [[synthesis/ai-agent-observability-x-langfuse-llm-observability]] — Theory vs Implementation: the framework's six failure categories and closed-loop ambition vs Langfuse's three trace statuses and open-tool architecture.
- [[synthesis/ai-agent-observability-x-dify]] — Observability vs Abstraction: Dify's low-code YAML orchestration that accelerates building is the same abstraction that creates observability blind spots.
- [[synthesis/llm-as-judge-evaluation-x-langfuse-llm-observability]] — Evaluation-Observability Loop: LLM-as-Judge and Langfuse form a closed loop in theory but require explicit wiring in practice.
- [[synthesis/ai-agent-observability-x-arize-phoenix]] — General vs RAG-specialized: the framework's four dimensions under-specify RAG's four sub-layers (Input/Recall/Rerank/Citation) that Phoenix's RAG analysis reveals.

## Skills

- [[skills/agent-observability-landing-guide]] — 从 0 到 1 搭建 AI Agent 可观测性的实操路径：定义最小任务单元、埋齐关键字段与事件、叠加轻量评估、沉淀失败数据集、用实验驱动迭代，再逐步扩展成本、失败分类、隐私脱敏与告警面板。
- [[skills/langfuse-integration-patterns]] — Langfuse 埋点的四种模式：OpenAI drop-in 替换、@observe() 装饰器、LangChain CallbackHandler、Eino callbacks.Handler——从最简单到最灵活。
- [[skills/langfuse-self-hosting]] — 使用 Docker Compose 自托管 Langfuse v3 的实操要点，包括组件关系、端口边界、存储权限和环境变量配置。
- [[skills/openclaw-observability-setup-tencent-cloud]] — 在腾讯云可观测平台上为 OpenClaw 接入 Trace 与 Metrics 监控的实操步骤：获取接入点、安装插件、修改配置、重启验证。

## References

- [[references/2025-09-01-loongsuite-ai-collection-dify]] — 阿里云 LoongSuite AI 采集套件无侵入观测 Dify 的实战文章，覆盖 Python/Go 埋点原理与端到端链路串联。
- [[references/2026-03-26-tencent-cloud-openclaw-observability]] — 腾讯云可观测平台通过 openclaw-tencent-plugin + OpenClaw 原生 diagnostics-otel 双插件，为 OpenClaw 提供 Trace 与 Metrics 一体化监控方案。
- [[references/2026-03-27-bonree-huawei-cloud-llm-observability]] — 博睿数据 Bonree ONE LLM 智能可观测平台正式上架华为云国际站基线解决方案库，面向全球企业提供 AI 全栈可观测解决方案。
- [[references/2026-04-06-loongcollector-acs-agent-sandbox]] — 阿里云介绍 ACS Agent Sandbox 与 LoongCollector 深度集成，为 OpenClaw 等 AI Agent 提供运行时安全隔离与全栈可观测能力。
- [[references/2026-04-27-langfuse-lifecycle-observability]] — 一篇关于 Langfuse 全生命周期可观测性的微信公众号文章，但正文仅包含标题图片，无可用文字内容。
- [[references/2026-05-18-openobserve-llm-vs-traditional-observability]] — OpenObserve 科普 LLM 可观测与传统可观测的根本差异，提出 Observability 3.0 应将 Trace/Metric/Log/Prompt/Score/Dataset/Experiment 放在同一数据底座。
- [[references/2026-06-01-cloudmonitor-ai-agent-observability]] — 阿里云云监控发布 AI Agent 可观测产品，采用接入层/数据层/分析层/应用层四层架构，覆盖 Token 成本治理、故障根因定位、数据驱动持续优化三大场景。
- [[references/2026-06-15-aidd-nova-flow-agent-observability]] — 支付宝 AIDD 2026 演讲实录，提出 NovaFlow 三层破局框架，将 Agent 可观测从
- [[references/2026-07-16-infoq-deepseek-chatbot-observability]] — InfoQ 转载的阿里云高级技术专家夏明演讲，介绍 DeepSeek 对话机器人场景下的全栈可观测架构、新指标与流式 Trace 处理。
- [[references/7-llm-observability-tools]] — 尼可同学 2026 年 7 月对 7 款主流 LLM 可观测与评测工具的选型指南：LangSmith、Langfuse、Arize Phoenix、Datadog、Lunary、TruLens、Helicone 的定位、适用场景与选择逻辑。
- [[references/agent-harness-observability]] — 企业大模型应用和开发对 ETCLOVG 框架中 O 层（Observability and Operations）的解读，涵盖追踪、监控、分析三大组件，成本追踪、可靠性工程、挑战与案例。
- [[references/agent-new-observability-paradigm-litefuse]] — 传统可观测性无法回答 Agent
- [[references/agent-observability-quality-evaluation-data-flywheel]] — 面向 Agent 原生的全链路可观测与质量评测体系：三层采集架构、离线评测流水线、在线评估体系、数据飞轮闭环，以及 AIOps 场景下的工程落地。
- [[references/agent-observability-seeing-thoughts]] — FutureCraft AI 第 12 篇从 Traces、Metrics、Logs 三支柱重新定义 Agent 可观测性，对比 LangSmith、Arize、Langfuse、Galileo 等平台，并给出最小可观测性配置。
- [[references/agentlogsbench]] — AgentLogsBench 是面向 AI Agent 可观测存储场景的基准测试，对比不同数据库在 Agent Trace 数据的存储、短语搜索、JSON 过滤、有序回放和实时聚合场景下的性能。Apache Doris 在综合排名中领先。
- [[references/ai-agent-observability-invisible-chain]] — 祥聊AI 从工程实践角度提出 Agent 可观测应沿请求链路在任务/会话、Agent 编排、工具/MCP、RAG 检索、LLM 调用五个节点埋观测点，并以 SLO 驱动四组核心指标。
- [[references/ai-customer-service-evaluation-alan]] — 一套面向 AI 客服的四层评测工程实践：L1 确定性业务规则、L2 行为意图识别、L3 七维 LLM Judge、L4 多轮流程回归，配套数据集设计、专业指标体系和可下钻报告。
- [[references/alicloud-cloudmonitor-ai-agent-observability]] — 阿里云云监控发布的 AI Agent 可观测产品，提供接入层、数据层、分析层、应用层四层架构，支持 Multi-Agent 全链路追踪、会话分析、Token 成本治理、智能告警与根因定位、Agentic Ops 能力。
- [[references/alicloud-loongcollector-agent-sandbox]] — 阿里云 ARMS AI 可观测方案：LoongCollector 实现全栈数据采集（业务/应用/模型层）、ACS Agent Sandbox 提供安全隔离的 Agent 执行环境，构成生产级 Agent 运行与观测一体化平台。
- [[references/aliyun-end-to-end-ai-observability]] — 阿里云基于 OpenTelemetry 的端到端 AI 可观测实践，覆盖 AI 应用层、AI 网关、模型推理层，重点解决用得起来、用得省、用得好的三类痛点。
- [[references/aliyun-llm-observability-full-chain]] — 阿里云面向 QwQ/DeepSeek 等 LLM 应用的可观测解决方案，覆盖采集治理、领域视图、根因定位，并给出 Dify 自动化埋点与端到端链路追踪实战。
- [[references/aliyun-python-probe-llm]] — 阿里云 2024 年 11 月推出 Python 探针，面向 Langchain、Llama-index、Dify、PromptFlow、OpenAI、Dashscope 等 Python LLM 应用提供零代码改造的可观测接入。
- [[references/apache-doris-agentlogsbench-leadership]] — 2026 年 5 月 AgentLogsBench 结果显示 Apache Doris 在面向 Agent 可观测的混合负载 benchmark 中以 1.28 倍 slowdown 领先，支撑短语搜索、动态 JSON 过滤、trace 回放和实时看板刷新。
- [[references/caict-llm-observability-standard]] — 中国信息通信研究院联合阿里云、华为云、腾讯云、百度等 29 家单位发布的国内首个面向 LLM 应用的可观测性能力分级标准，以数据采集、建模、存储、应用为主线，规范了基础设施层、中间件层、模型层、模型服务层和应用层的可观测能力要求。
- [[references/datadog-llm-observability]] — Datadog 知识中心对 LLM 可观测性的定义：覆盖输入输出监控、请求链路追踪、延迟与 Token 追踪，以及幻觉、成本超支、安全漏洞等问题的提前发现。
- [[references/deepflow-automq-greptimedb-meetup]] — 2026 年 4 月上海 Meetup 回顾，DeepFlow、AutoMQ、GreptimeDB 三家公司分别从 eBPF 零侵扰采集、Diskless Kafka 传输、统一存储与 LLM 分析三个层面讨论下一代可观测数据栈的工程实践。
- [[references/dify-phoenix-integration]] — Dify 低代码平台通过内置 OpsTrace 事件机制与 Arize Phoenix 集成，以 OpenTelemetry 标准格式将 Workflow/Agent 执行过程中的 LLM 调用、工具调用、知识库检索等关键节点信息发送至 Phoenix，实现全链路可观测。
- [[references/langfuse-deployment-practice]] — 南哥聊技术分享的 Langfuse v3 Docker Compose 自部署笔记，重点讲组件关系、端口边界、存储权限和环境变量配置。
- [[references/litefuse-single-process-mode]] — SelectDB 2026 年 6 月宣布 Litefuse 开源并推出业界首个单进程轻量模式，约 25 秒完成单机部署，基于 Apache Doris 解决 Agent 可观测的长文本、超长 Trace、半结构化数据、成本挑战。
- [[references/llm-observability-agent-interview]] — 一道考察生产环境经验的高级面试题，强调 LLM 可观测性在 DataCamp 等面试资源中的重要性。
- [[references/llm-observability-five-pillars]] — 从 Arize 五大支柱出发解析 LLM 可观测性：Evaluation、Traces/Spans、Prompt Analysis、Search/Retrieval、Fine-tuning，并覆盖性能追踪、深度理解、可靠性保证和准确率核心要素。
- [[references/loongsuite-genai-semconv]] — 阿里云、阿里控股与蚂蚁集团 2025-2026 年在 OTel GenAI 语义基础上，针对内部真实场景提出 Entry/Step Span、Skill 语义、Token 级推理观测三项扩展，并配套 GenAI Utils 工程化能力层。
- [[references/loongsuite-pilot-open-source]] — 阿里云 2026 年 6 月宣布开源 LoongSuite Pilot，补齐 AI Coding Agent（Cursor、Claude Code、Codex、Qoder）运行在开发者本地机器导致的可观测盲区。
- [[references/openobserve-otel-landing]] — 一篇从 OpenTelemetry 协议理解到存储方案对比，最终选择 OpenObserve 落地的实战记录，包含部署架构、OTel Collector 配置和实际踩坑经验。
- [[references/opentelemetry-genai-agent-setup]] — OpenTelemetry 在 GenAI Agent 可观测场景中的实战配置：TracerProvider/SpanProcessor/SpanExporter 三层架构、手动插桩模式、Collector 部署与采样策略、分布式追踪的 Context 传播。
- [[references/opentelemetry-genai-semconv]]
- [[references/opentelemetry-signoz-llm-observability]] — 使用 OpenTelemetry 与 SigNoz 为 LangChain 应用构建开源 LLM 可观测性栈，支持手动插桩和 OpenLLMetry 自动插桩，并提供成本与性能监控仪表板。
- [[references/spring-ai-otel-langfuse]] — 基于 Spring AI + OpenTelemetry + 自托管 Langfuse 的生产级 LLM 应用可观测方案，通过 OTLP 将 LLM 调用封装为 Trace/Span 导出到 Langfuse，实现 Prompt、Token、延迟、成本和错误的统一观测。
- [[references/stepfun-selectdb-pb-observability]] — 阶跃星辰（StepFun）基于 SelectDB（Apache Doris）构建 PB 级 Agent 可观测平台 StepTrace 的架构实践，包括 Agent Trace 数据模型、检索分析、成本治理、评测闭环和基础设施关联六大能力要求。

