---
source_url: "https://mp.weixin.qq.com/s?search_click_id=4566775704178140990-1784705538518-5078444583&__biz=MzUzNzYxNjAzMg==&mid=2247584128&idx=1&sn=593bb39e81ea1d642dfa6a1902430c1b&chksm=fb895cfdfc47160e53afc7944a5dfb2b1f60e040e4017fab25d8eee5eb73f893cb6aff33d97e&subscene=90&scene=7&clicktime=1784705538&enterid=1784705538&ascene=65&devicetype=iOS26.5.2&version=18004b43&nettype=3G+&abtest_cookie=AAACAA==&lang=zh_CN&countrycode=CN&fontScale=100&exportkey=n_ChQIAhIQzR8HMb4dvHcZSY2vc90CNRLhAQIE97dBBAEAAAAAANz/CB5c0M8AAAAOpnltbLcz9gKNyK89dVj0WbONqtYg91UxDn1aHyO64LJ7vB44H7dCQXFLFlrc+WdzqnVMSyR+BNGG+7gh8chi4TCM9RGNpxi7ldkpQB87unsU078LbLDbiGWdpNBqNR3gt89En58O0fLKpPMlzjB6vNjHLiaqNEYxoM36DDeWJ5VmWK2LdVBkrYxC6cvs8Cjcd4SpKdFT5wrFasI7hxseShDgUV1+5fvose2a+kX33TahAK6Y+pI0tsxFRC5bRqS+wAbTjx95JoIJfQ==&pass_ticket=7R8PJKTDiuFQqwK8VEPN24fGoMsM9Sgsp5uDpzp6uLQWWxoWVu1ZhfwDtIbYKV8v&wx_header=3"
title: "重磅发布丨云监控 AI Agent 可观测，企业生产级 Agent 首选全域观测平台"
account: "阿里云云原生"
published_at: "2026-05-31T02:00:00.000Z"
saved_at: "2026-07-22T07:32:27.841Z"
sync_id: "art_acc7ab8c73c54958bffd23eec2ca381e"
parse_status: "ok"
---

# 重磅发布丨云监控 AI Agent 可观测，企业生产级 Agent 首选全域观测平台

_**背景：AI Agent 已经进入生产落地的深水区**_

_Cloud Native_

AI Agent 正加速从实验走向规模化生产，行业进入高速增长期：据 Multimodal.dev 统计，2025年全球 AI Agent 市场规模已达 792 亿美元；Arcade.dev 调研显示，超过 66% 的落地项目已采用更复杂的 Multi-Agent 协作架构；Gartner 更是预测，到 2026 年将有 40% 的企业应用内嵌 AI Agent 能力**[****1]**。

与之相伴的，是 AI Agent 能力边界拓展带来的复杂度指数级跃迁：从早期的单轮问答，到如今的工具调用（Tool Use）；从单一智能体，到 Planner/Worker/Critic 多角色协同的 Multi-Agent 网状拓扑。在典型的生产级 Agent 场景中，工具调用已成为核心交互方式，覆盖外部 API、数据库、代码沙箱等各类外部能力；Plan-Act-Observe-Reflect 的多步循环，让单次任务的决策点较传统应用成倍增长；同时，Agent 还需要同步处理文本、图像、音视频、PDF 等多模态数据，整个执行过程早已成为一个难以透视的“黑箱”。

_**生产落地的核心挑战**_

_Cloud Native_

![](附件资源/重磅发布丨云监控%20AI%20Agent%20可观测，企业生产级%20Agent%20首选全域观测平台/img_1.png)

**当 Agent 架构日趋复杂，缺乏可观测体系的 Agent 应用在生产环境中，面临四个核心挑战：**

- 成本失控风险 ： Token 作为 AI 应用的核心成本单元，传统方式缺乏实时用量监测能力，异常重试、重复调用等隐性消耗往往要到月底账单出具时才能被发现，成本治理的响应周期长达数周，企业难以对成本进行精细化管控。
- 故障定位低效 ： Multi-Agent 的网状调用链，让故障的传播路径变得极其复杂。当问题发生时，研发人员很难快速定位是哪个 Agent 角色、哪个模型调用、还是哪个工具环节出了问题，跨模块的性能瓶颈和错误节点难以快速下钻，导致故障排查的平均修复时间（MTTR）居高不下。
- 安全边界模糊 ： 随着工具调用的增多，Agent 的攻击面也在快速扩大，Prompt 注入、工具越权调用等风险层出不穷，这也正是 OWASP LLM Top 10 重点关注的安全风险 [ 2] ，但传统体系缺乏对这些风险的过程化监测能力。
- 质量难以量化 ： 幻觉、决策偏离等 Agent 特有的质量问题，因为缺乏完整的过程数据支撑，研发人员无法复现问题、评估影响，更难以开展评估和持续的模型优化，导致 Agent 的效果难以稳定迭代。

面对这些新的挑战，传统的应用可观测体系已经力不从心。传统体系是为微服务架构设计的，它只能追踪请求在服务间的流转，却看不到 Agent 内部的推理逻辑、多角色的协作路径、工具调用的细节，更无法捕捉决策偏差的根源。**为解决这一问题，阿里云云监控正式发布上线 AI Agent 可观测产品****，**帮助用户实现 Agent 执行过程的全链路追踪、实时健康度监控和数据驱动的持续优化。本文将从产品架构、核心能力和典型场景三个方面，全面介绍这一产品如何为 AI Agent 的生产落地保驾护航。

_**产品架构：四层体系，覆盖端到端全链路**_

_Cloud Native_

![](附件资源/重磅发布丨云监控%20AI%20Agent%20可观测，企业生产级%20Agent%20首选全域观测平台/img_2.png)

AI Agent 可观测采用接入层、数据层、分析层、应用层的四层架构设计，实现从数据采集到 Agentic 分析的端到端全覆盖。

### ▍ 接入层：灵活适配，分钟级快速接入

- 针对使用主流 AI 框架的智能体，提供多语言自研探针（Python/Node.js/Golang/Java），支持 LangChain/LangGraph、AgentScope、Dify、OpenClaw、Hermes、QoderWork、Claude Code、Codex 等 20+ 主流 AI 框架或智能体应用，对业务代码零侵入，分钟级完成接入。
- 针对未使用标准化框架或有自定义采集需求的场景，提供 GenAI Utils 自定义埋点 SDK。
- 同时兼容 OpenTelemetry GenAI 数据规范，支持 OTLP gRPC/HTTP 传输协议，存量可观测体系可平滑迁移并自动适配 Agent 观测体系，无需重复改造。

### ▍ 数据层：统一建模，全域数据无缝关联

基于 UModel 统一建模体系，将基础设施（GPU、ACK/ECS/FC）、AI 服务（推理服务、训练任务、SandBox）、AI 资产（模型、AI Agent、AI 应用、工具、数据集）等实体进行统一建模，对全域数据进行默认关联。完整存储推理过程数据，不丢失任何决策过程的细节，并支持多模态数据的原生预览。

### ▍ 分析层：多维分析，从全局到细节的完整洞察

全景拓扑、链路追踪、会话分析、指标大盘、智能告警五大核心模块协同工作，提供从全局视图到单链路下钻的完整分析路径。

### ▍ 应用层：Agentic 化，让可观测能力可被 Agent 原生使用

区别于传统可观测产品“人用工具”的定位，应用层将可观测能力全面 Agentic 化，提供与控制台对等的 CLI/Skills 接口，支持 AI Agent 直接调用可观测能力进行快速接入、智能查询、分析和告警处理。并在全路径内嵌 AI 辅助分析能力。

_**核心能力：全方位破解 Agent 可观测难题**_

_Cloud Native_

![](附件资源/重磅发布丨云监控%20AI%20Agent%20可观测，企业生产级%20Agent%20首选全域观测平台/img_3.png)

### ▍ 全场景接入：三种模式，适配所有 Agent 形态

![](附件资源/重磅发布丨云监控%20AI%20Agent%20可观测，企业生产级%20Agent%20首选全域观测平台/img_4.png)

### ▍ 全局总览大盘：实时掌握整体运行态势

产品为用户提供了全局总览大盘，对已接入的 Agent 提供全局总览视图，覆盖会话统计、Token 用量统计、模型性能、Agent 调用和智能体框架分布等维度，帮助用户实时了解 Agent 整体运行态势。

### ▍ 拓扑与健康度：主动巡检，提前发现风险

**全景拓扑****：**实时展示 AI 应用、AI Agent、模型、工具等实体的全局拓扑关系。支持 Multi-Agent 调用关系的逐层下钻，帮助用户梳理 AI 资产并构建智能体业务 CMDB。

**主动式健康巡检****：**通过内置巡检规则和纳管自定义告警规则，为 AI 应用和 AI Agent 提供主动式健康检查。按需开启后以“红绿灯”方式直观呈现实时健康状态。当出现健康问题时，健康度详情页面展示具体异常事件和上下游影响面，并支持 AI 智能分析生成健康巡检报告。还可以通过 IM、电话等多种渠道订阅健康事件，第一时间收到风险通知。

### ▍ 全链路追踪：穿透黑箱，还原每一次推理与决策

基于标准 GenAI 数据规范记录 Agent 执行过程中的所有操作（LLM 调用、Tool 调用等），提供以下能力：

- 轨迹追踪与回溯 ： 通过调用树、链路图、时序线和链路分析大盘等多种视图，完整还原 Agent 内部执行轨迹。
- 工作流执行路径图 ： 将 Agent 工作流以图谱形式展现决策路径和工具调用关系，帮助用户评估 Agent 决策路径是否符合预期。
- 推理过程数据还原 ： 以推理轨迹为时间线，将 Agent 内部推理过程数据完整还原，提供以过程数据为核心的专属视图。
- 多模态数据原生预览 ： 支持文本、图像、音视频及 PDF 等追踪数据的捕获与原生预览。
- 评估能力关联 ： 在链路追踪视图中关联评估能力，支持基于链路数据发起评估任务、按评估结果快速筛选高质量链路。
- 链路转数据集 ： 支持批量将高价值链路转换为数据集，转换过程可配置自定义 Pipeline，满足不同场景的数据加工需求。

### ▍ 会话分析：从用户视角还原交互全流程

产品还提供了终端用户视角的会话分析能力，还原用户与 Agent 的多轮对话交互全过程，完美适配多轮对话、长周期会话、多模态等复杂场景。

通过 USER→SESSION→TRACE 的三层数据聚合结构，产品将分散的推理过程数据按照用户会话进行统一组织，支持多维度的灵活查询，完美满足业务统计、问题排查、用户交互体验等多种需求。

### ▍ 场景化分析：针对性解决核心业务问题

为每个 AI Agent/AI 应用提供独立的详情大盘，覆盖会话统计、调用统计、Token 统计、模型性能和工具调用维度。此外提供三类全局场景化分析视图：

- Token 用量分析 ： 支持模型/AI 应用/AI Agent 多维筛选，提供输入/输出/缓存命中率统计及 Token 消耗分布明细，快速拆解成本构成，定位高消耗的环节和对象。
- 模型性能分析 ： 提供调用 RED 指标（Rate/Error/Duration）、TTFT（首 Token 时间）、TPOT（每 Token 处理时间）等多维统计与趋势，支持多模型性能对比，帮助用户选择最优的模型配置。
- 工具调用分析 ： 提供全局工具调用分布与性能明细、技能（Skills）加载统计，帮助分析工具/技能调用瓶颈，优化工具/技能的响应效率。
- RAG 调用分析 ： 聚焦 Retrieval、Rerank、Embedding 调用的 RED 指标与数据趋势，辅助优化 RAG 应用的效果与性能。

### ▍ 智能告警与根因定位：分钟级定位问题根源

对 AI Agent/AI 应用提供覆盖模型调用、工具调用、Token 消耗和 Agent 自身调用等维度的告警指标集，实时记录异常告警事件并支持多维度筛选。

告警触发后，支持对异常进行 AI 智能分析和根因定位，并可通过多轮对话方式追问细节和进行二次分析。

### ▍ Agentic Ops 能力

区别于传统可观测产品，AI Agent 可观测从设计之初就融入了 Agentic 的理念，让可观测能力不再只是给人用的工具，更能被 Agent 自己使用：

- 能力全开放 ： 从接入到查数、统计、分析和告警的全链路，均提供与控制台对等的 CLI/Skills 接口，支持 AI Agent 直接集成和调用可观测能力。
- 全域数据关联 ： 基于 UModel 体系对实体进行统一建模和默认关联，覆盖从 GPU 到 Agent 的全栈观测对象和数据，实现一次查询即可获取全域关联上下文， 无需用户自己拼接数据。
- 全链路 AI 辅助 ： 在 Trace 分析、健康度分析、指标异动分析和告警根因定位等场景内嵌 AI 辅助能力， 帮助用户更快更方便地找到问题和定位问题。

_**典型落地场景：解决生产落地的核心痛点**_

_Cloud Native_

### ▍ 场景一：Token 成本治理

![](附件资源/重磅发布丨云监控%20AI%20Agent%20可观测，企业生产级%20Agent%20首选全域观测平台/img_5.png)

**问题****：**缺乏实时 Token 用量观测，异常重试、重复调用等 Token 黑洞问题难以及时发现，成本归因周期长。

**方案****：**借助 AI Agent 可观测进行全方位的 Token 成本分析，支持按模型/Agent/应用多维度追踪 Token 消耗分布，提供输入输出 Token 数、缓存命中率与各 Agent 使用分布等明细数据的秒级趋势大盘。支持通过 AI 辅助定位高消耗链路，帮助用户快速识别 Token 消耗异常来源。

### ▍ 场景二：故障根因快速定位

![](附件资源/重磅发布丨云监控%20AI%20Agent%20可观测，企业生产级%20Agent%20首选全域观测平台/img_6.png)

**问题****：**在复杂的 Multi-Agent 场景下，网状的调用链让故障定位变得极其困难，传统方式 MTTR 长。

**方案****：**异常告警触发后（T+0s），健康度大盘下钻定位异常 Agent 节点（T+10s），链路追踪聚焦失败路径并通过工作流图展示决策环节（T+30s），AI 智能根因分析综合推理过程数据和调用上下文自动生成分析报告（T+60s），价值链路数据可一键转为数据集用于后续优化（T+90s）。

### ▍ 场景三：数据驱动的 Agent 持续优化

![](附件资源/重磅发布丨云监控%20AI%20Agent%20可观测，企业生产级%20Agent%20首选全域观测平台/img_7.png)

**问题****：**传统的 Agent 优化中，数据集的构建高度依赖人工标注，成本高、效率低，而且标注好的数据集往往缺少 Agent 推理过程的上下文，导致评估和优化脱节，Agent 的效果难以持续迭代。

**方案****：**通过链路追踪关联评估能力，筛选高质量链路并批量转换为数据集。转换过程支持自定义 Pipeline 灵活加工，完整保留推理过程与多模态上下文，支持评估结果直接驱动数据集筛选，形成“观测→评估→筛选→回灌”的闭环。

_**产品优势**_

_Cloud Native_

![](附件资源/重磅发布丨云监控%20AI%20Agent%20可观测，企业生产级%20Agent%20首选全域观测平台/img_8.png)

![](附件资源/重磅发布丨云监控%20AI%20Agent%20可观测，企业生产级%20Agent%20首选全域观测平台/img_9.png)

_**总结**_

_Cloud Native_

随着 Multi-Agent 多角色协作、多工具调用、多模态数据处理的快速普及，AI Agent 的复杂度正在指数级增长，可观测已经成为 AI Agent 规模化落地的必备能力。阿里云云监控的 AI Agent 可观测产品，提供从接入、建模、分析到 Agentic Ops 的全域观测和分析能力，帮助企业彻底打开 Agent 的黑箱，实现 Agent 执行过程的可追踪、可诊断、可优化。

**让每次决策可追、可解、可优。**

****

欢迎访问阿里云可观测 Playground 官网进行产品体验：_https://sls.aliyun.com/doc/playground/cmsdemo.html_。

**参考资料：**

[1] 市场数据来源：Multimodal.dev/Arcade.dev（2025 年 AI Agent 市场规模）、Arcade.dev 行业调研（Multi-Agent 架构采用率）、Gartner 预测（2026 年企业应用 AI Agent 内嵌率）

[2] OWASP LLM Top 10

_https://owasp.org/www-project-top-10-for-large-language-model-applications/_

[3] OpenTelemetry GenAI Semantic Conventions

_https://opentelemetry.io/docs/specs/semconv/gen-ai/_

---
原文链接：https://mp.weixin.qq.com/s?__biz=MzUzNzYxNjAzMg%3D%3D&mid=2247584128&idx=1&sn=593bb39e81ea1d642dfa6a1902430c1b&chksm=fb895cfdfc47160e53afc7944a5dfb2b1f60e040e4017fab25d8eee5eb73f893cb6aff33d97e
