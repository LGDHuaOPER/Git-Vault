---
source_url: "https://mp.weixin.qq.com/s?__biz=Mzg3ODkxNDk0Nw%3D%3D&mid=2247488689&idx=1&sn=daead4a71a3967c35d334932390c4577&chksm=cf0d285df87aa14b0e427240eda14491904c3253997de1a3f8aebdc70d1114215860e6375371"
title: "Agent 可观测性：从 Trace 到任务失败归因——基于 Go、Java、OpenTelem）etry 与 Kubernetes 的生产级设计、实现与验证"
account: "Ray的银河技术"
published_at: "2026-10-21 22:35:44"
saved_at: "2026-10-23 12:35:47"
sync_id: "art_06fe99d861be4ee39e736b5d216b2230"
parse_status: "ok"
---

# Agent 可观测性：从 Trace 到任务失败归因——基于 Go、Java、OpenTelem）etry 与 Kubernetes 的生产级设计、实现与验证

# Agent 可观测性：从 Trace 到任务失败归因——基于 Go、Java、OpenTelem)etry 与 Kubernetes 的生产级设计、实现与验证

> 面向 Go / Java 后端、分布式系统、DevOps 与 SRE 工程师技术资料核对日期：2026-10-21。本文提供生产级**设计与验证方法**；除明确标为“已验证”的项目外，不将示例、配置或实验方案表述为已在线上联调通过。

## 如何使用本文

本文不是把一次 Agent 执行塞进一条超长 Trace 的教程，而是一份围绕“任务事实、外部副作用与遥测证据”建立可归因系统的设计说明。建议按职责阅读：

| 读者 | 建议先读 | 读完应能回答的问题 |
| --- | --- | --- |
| 后端工程师 | 二、五、七、八、九、十、附录 A/B | 如何持久化身份、传播上下文、避免旧执行覆盖与重复副作用？ |
| SRE / 值班工程师 | 一、三、六、十一至十五、十七 | 一项失败任务如何从状态事实重建到基础设施与发布证据？ |
| 平台 / 安全工程师 | 三、十、十一、十三、十六 | 授权、审计、数据保留、Collector 与发布事件怎样形成边界清晰的系统？ |
| 架构负责人 | 一、二、四、七、十七 | 哪些数据必须可靠持久化，哪些遥测可以按预算降级？ |

### 阅读前必须锁定的版本契约

本文故意不把“最新版本”写进代码。落地仓库应在  `go.mod` 、Maven/Gradle lockfile、镜像 digest 与部署清单中锁定并记录下列兼容性矩阵：

| 契约 | 至少锁定的内容 | 验证动作 |
| --- | --- | --- |
| OTel SDK | API、SDK、OTLP exporter、自动插桩库版本 | 编译、单测、Collector 端到端导出 |
| MCP | 协商的协议版本、客户端/服务端 SDK 与 transport | 初始化协商、  `tools/call`  成功和失败路径 |
| Collector | distribution、镜像 digest、组件与配置 schema | 使用该镜像执行配置校验并抓取  `/metrics`  |
| Kubernetes / Argo CD | 集群版本、client-go、Argo CD 与 Notifications 版本 | 隔离 namespace 演练和发布事件去重测试 |
| 存储与模型供应商 | 数据库隔离级别、schema 版本、模型与价格版本 | 并发领取测试、账本对账与回放测试 |

“生产级”在本文中指可审查的边界、失败模型与验收标准；它不替代上述锁定版本上的编译、部署、压测和演练。

## 先看一个值班时真正需要回答的问题

用户提交了一项 Agent 任务：查询资源、生成变更方案、等待审批，再通过 MCP 执行变更。API 返回了  `202 Accepted` ，模型请求返回成功，工具请求也曾返回成功，但任务最终停在  `FAILED` 。

此时，一条红色 Span 并不能回答全部问题：

- 失败的是哪次执行？用户任务是否已经产生副作用？
- Worker 是执行失败、丢失所有权，还是进程直接消失？
- 恢复后的 Worker 是否沿用了原来的审批与幂等键？
- 重试是否再次消耗 Token、再次收费、再次修改资源？
- 同期发布改变了代码、模型、策略，还是仅仅与失败时间接近？

这是一个**用于推演的故障场景**，并非本文作者实测的生产事故。更不能仅凭这些描述断言发生了 OOM：Lease 超时、网络分区、主动发布和节点故障都可能造成相似表象。

Agent 的困难在于：一次用户意图可能跨越多个进程、多个 Trace、多个审批周期，以及多次结果不确定的外部调用。正确的目标不是“让一条 Trace 永远不断”，而是让任务的执行、状态、授权、副作用和基础设施证据能够重新对齐。

本文的核心约束是：**任务事实存储负责证明状态，可观测系统负责解释状态；二者共享关联键，但不能互相替代。**

### 本文证据等级

| 等级 | 本文实际包含什么 | 不能据此声称什么 |
| --- | --- | --- |
| 官方依据 | 已核对的 OTel、MCP、Prometheus、Kubernetes、Argo CD 文档 | 某版本 SDK、后端与部署组合已经联调通过 |
| 工程设计 | SQL 事务边界、Go 插桩代码、指标口径与配置片段 | 已构成完整可上线 Runtime |
| 实验方案 | 注入步骤、证据清单、通过条件、空白记录表 | 实验已执行或性能已经改善 |
| 本次交付验证 | 文档结构、代码块及关键口径检查 | Go 编译、Kubernetes 部署、Grafana 联调已通过 |

本文随文提供的是设计级代码与配置片段，不附带锁定依赖的可运行仓库；因此下文不会标注“编译通过”或“部署成功”。将其接入真实系统前，必须以本章的版本契约完成编译、配置校验与故障演练；所有实验结果在未填入原始证据前均视为待执行。

## 一、HTTP APM 没有失效，任务模型缺了一层

HTTP APM 很擅长解释一次同步请求：入口、依赖调用、耗时和错误。然而，Agent API 的响应通常只表示“任务被接收”。它与任务完成是两个时间点。

长任务还会经历排队、限流、模型重试、审批等待和恢复调度。若把这些时间全部折叠成一个  `task.duration` ，慢在哪里仍然不可知。

应分别记录：

| 时间口径 | 起止点 | 诊断用途 |
| --- | --- | --- |
| 接收延迟 | API 接收 → 任务事务提交 | API 与数据库接收能力 |
| 队列等待 | 可执行时间 → 获得执行权 | 调度、积压与配额 |
| 执行时长 | Attempt 开始 → Attempt 结束 | Worker 的实际占用 |
| 审批等待 | 进入等待 → 审批决定生效 | 人工流程耗时 |
| 恢复延迟 | 满足接管条件 → 新 Attempt 获得执行权 | 恢复调度能力 |
| 任务墙钟时间 | 接收 → 终态 | 用户体验与业务 SLO |

并行 Step 的耗时之和可以大于任务墙钟时间；LLM 重试次数增加也不等于用户任务失败率增加。Dashboard 必须明确展示的是哪一个口径。

以下三个常见误解需要先修正：

- 1. 父 Span 已结束，并不妨碍之后创建关联的子 Span。 OpenTelemetry 的消费者 Span 可以晚于生产者结束才开始。长时间跨度是否使用父子关系，是建模选择，并非物理限制。
- 2. 动态 Step 数量本身不违反 Trace 模型。 真正的问题是生命周期跨度、数据体量、采样、未结束 Span 丢失，以及任务状态不属于单次调用。
- 3. request context 取消主要影响后台业务操作。 不能直接推导为所有 Span 无法导出。SDK 的导出队列与 Span 生命周期需要单独分析。

本文选择“每次 Worker 执行一个新 Trace，使用 Links 关联来源”，目的是控制单条链路规模并表达异步因果，不是为了修复 OTel 的不存在限制。[1]

## 二、Task、Step、Attempt、Invocation：先给事实命名

### 2.1 不再让 Attempt 同时表示三种重试

| 实体 | 定义 | 生命周期与关联键 |
| --- | --- | --- |
| Task | 用户提交的逻辑工作 |  `task_id`  ，跨恢复不变 |
| Step | 一个持久化的逻辑动作 |  `task_id + step_id`  ，重试时不变 |
| Execution Attempt | Worker 一次获取执行权后的执行区间 |  `execution_id`  ；接管产生新的编号 |
| Step Attempt | 同一逻辑 Step 的一次尝试 |  `step_attempt_id`  ，可有多个 |
| Invocation | 一次实际发往 LLM / MCP 的请求 |  `invocation_id`  ，每次网络尝试唯一 |
| Effect | 一次逻辑副作用 |  `effect_id / idempotency_key`  ，重试沿用 |
| Trace | 一组追踪 Span |  `trace_id`  ，允许跨 Attempt 改变 |

一次 Execution 可以包含多个 Step；一次 Step Attempt 可能因为客户端内部重试产生多个 Invocation。不要只增加一个  `attempt`  字段，然后让成本、错误率和幂等全部依赖它。

 `step_id`  应来自工作流计划或持久化步骤记录，而非“当前数组下标”。若支持分支、并行和动态展开，还需要  `parent_step_id` 、分支标识与依赖关系；单个递增  `step_seq`  不能表达完整 DAG。

### 2.2 关联键分三层放置

- 业务事实与审计： Task、Step、Execution、Invocation、Effect、授权决定、审批决定的 ID。
- Trace 与结构化日志： 上述 ID 的必要子集，以及  `trace_id`  、  `span_id`  、Pod UID、版本。
- Metrics： 有界的服务、工作流类型、模型别名、工具类别、错误类别、结果。默认不放 Task、用户、审批或请求 ID。

高基数 ID 可以作为 Trace 属性，也可以作为日志字段，但仍有索引成本。Loki 中不要把  `task_id` 、 `trace_id`  直接提升为长期 stream label；使用 JSON 字段或经版本验证的 structured metadata。

Task ID 是跨信号关联键，不是授权凭据。查询任务证据时仍须做租户与资源级权限校验。

### 2.3 Span 名称与资源属性

使用固定 Span 名称，例如  `agent.execution` 、 `agent.step` 、 `llm.request` 、 `mcp.tools.call` 。不要把任务 ID、用户问题或资源名称拼进 Span 名称。

资源层记录  `service.name` 、 `service.version` 、 `service.instance.id` 、 `k8s.namespace.name` 、 `k8s.pod.uid` 。应用扩展字段使用自己的命名空间，例如  `aegis.task.id` 、 `aegis.execution.id` 、 `aegis.effect.id` 、 `aegis.release.id` 。

LLM 属性尽量映射到已锁定版本的 GenAI 语义约定，例如模型名和输入输出 Token 字段。GenAI 文档目前发生了仓库迁移，采用前必须锁定语义约定版本或提交，并逐项核对稳定性；不要宣称所有  `gen_ai.*`  字段都已稳定。[3]

## 三、五类信号各管什么

Events 与 Audit 在这里是应用层的语义分类，不表示必须分别部署五套 OTel 协议或存储。事件可以通过日志管道发送，审计也可以写入数据库与对象存储。关键在于可靠性、权限和保留策略不同。

| 信号 | 主要问题 | 例子 | 可靠性边界 |
| --- | --- | --- | --- |
| Trace | 一次执行调用了什么、耗时在哪里 | LLM、MCP、数据库、队列消费 | 可能被采样或在崩溃时丢失 |
| Metrics | 多少任务受到影响、趋势如何 | 失败率、队列年龄、Token、延迟 | 聚合信息，无法证明单任务事实 |
| Logs | 某次操作具体发生了什么 | 错误类别、依赖状态、异常栈 | 普通 stdout 不等于可靠审计 |
| Events | 状态何时改变 | 接管、审批通过、Checkpoint 提交、发布 | 关键事件应从事务化事实生成 |
| Audit | 谁在什么授权下尝试并产生了什么影响 | 策略决定、审批、工具请求、效果确认 | 独立权限、完整性保护、明确持久化策略 |

Span Event 是附着于 Span 的时间点信息；任务状态事件是持久化业务事实。 `span.AddEvent("checkpoint.saved")`  不意味着数据库已经提交。反之，关键状态事件完全可以同时投影到日志与 Span Event，只要复用同一  `event_id` 。

**不要从群体指标倒推单任务调用顺序。** 某时段模型 P99 变高只能说明排查方向，不能证明某个任务因模型变慢而重试。

## 四、整体架构：业务证据链与遥测管道分工

```
遥测

遥测

遥测

API：接收任务PostgreSQL：任务与执行事实事务 Outbox队列：投递与重投Worker：执行与恢复LLM：调用与用量MCP：授权与副作用审计与效果账本OpenTelemetry CollectorTrace / Metrics / Logs 后端任务证据查询与投影Grafana：检索与关联Kubernetes 与 Argo CD 事件采集
```

这里有两条不同的数据路径：

- Trace、普通日志、性能指标允许在明确预算内降级，不能因为遥测后端故障无限阻塞业务。
- 状态转换、效果记录和关键审计必须按业务可靠性要求提交。高风险工具若不能持久化授权及执行意图，通常应拒绝执行，而不是当成“日志失败”忽略。

Outbox 保证的是数据库内状态与待发送事件共同提交。它**不保证外部工具已经且仅执行一次**。

## 五、跨 API、队列、Worker、MCP 传播上下文

### 5.1 API 接收成功，要先让任务和发送意图落库

API 应在同一个事务中写 Task 与 Outbox，然后返回 202。Outbox 消息携带  `task_id` 、消息 ID、schema 版本和必要的 Trace Context。不要序列化 Go  `context.Context` ，不要把用户 Token、Cookie 或完整 Baggage 一并保存。

API 的 Trace Context 是执行来源；它不决定 Worker 的超时与取消。Worker 使用自己的进程 context，并为每次执行设置独立 deadline。

Outbox Relay 也应插桩：其 publish Span 可以 link 回接收来源，再把自己的上下文注入消息。任务表保留来源引用，避免 Relay 改写后丢失最初入口。

### 5.2 新 Trace + Link 的 Go 实现

下面是完整函数与所需类型，可放入  `package telemetry` 。它依赖 OTel API，初始化见后文；没有伪造某个 MCP SDK 的字段。

```
package telemetryimport (    "context"    "go.opentelemetry.io/otel/attribute"    "go.opentelemetry.io/otel/propagation"    "go.opentelemetry.io/otel/trace")type ExecutionMeta struct {    TaskID      string    ExecutionID string    Attempt     int    Trigger     map[string]string // 消息来源上下文    Previous    map[string]string // 前次 Execution 上下文}func StartExecution(    workerCtx context.Context,    tr trace.Tracer,    m ExecutionMeta,) (context.Context, trace.Span, map[string]string) {    prop := propagation.TraceContext{}    links := make([]trace.Link, 0, 2)    seen := map[string]bool{}    add := func(carrier map[string]string, relation string) {        extracted := prop.Extract(context.Background(), propagation.MapCarrier(carrier))        sc := trace.SpanContextFromContext(extracted)        if !sc.IsValid() {            return        }        key := sc.TraceID().String() + ":" + sc.SpanID().String()        if seen[key] {            return        }        seen[key] = true        links = append(links, trace.Link{            SpanContext: sc,            Attributes: []attribute.KeyValue{                attribute.String("aegis.link.relation", relation),            },        })    }    add(m.Previous, "resumes_execution")    add(m.Trigger, "triggered_by")    ctx, span := tr.Start(workerCtx, "agent.execution",        trace.WithNewRoot(),        trace.WithSpanKind(trace.SpanKindConsumer),        trace.WithLinks(links...),        trace.WithAttributes(            attribute.String("aegis.task.id", m.TaskID),            attribute.String("aegis.execution.id", m.ExecutionID),            attribute.Int("aegis.execution.attempt", m.Attempt),        ),    )    carrier := propagation.MapCarrier{}    prop.Inject(ctx, carrier)    return ctx, span, map[string]string(carrier)}
```

 `WithNewRoot()`  明确切断父子继承；仅使用  `WithLinks()`  不保证新建 Trace。 `workerCtx`  仍保留进程退出信号；Trace 的父子关系与 context 的取消关系是两件事。[2]

执行上下文应在**任何外部副作用之前**写入 Execution 记录，并核对当前所有权。不能等成功 Checkpoint 时才保存：首次工具调用后就崩溃的 Attempt 否则没有可恢复的 Trace 引用。

Link 使用 Trace ID 与 Span ID 对去重，不依赖  `SpanContext`  内部结构是否可比较。恢复来源与消息来源可能相同，去重后不重复记录。

### 5.3 HTTP 与 MCP 的传播不能混用成一个假设

普通 HTTP 客户端可用  `otelhttp.NewTransport`  注入 W3C headers，服务端使用  `otelhttp.NewHandler`  提取。要避免手动 Span 与自动插桩重复产生同义 Span。

MCP 则需核对实际协商的协议版本和 SDK 支持。核对到的  `2026-07-28`  规范中， `_meta`  已保留  `traceparent` 、 `tracestate`  和  `baggage`  传播键，不能再笼统写成“MCP 没有上下文传播约定”。协议约定也不代表客户端和服务端自动启用了插桩。[4]

以下是**应用适配结构**，并非官方 SDK 类型。关键点是：Trace Context 必须与 SDK 生成的协议元数据**合并**，绝不能以只有  `traceparent`  的新 map 覆盖完整  `_meta` 。对于  `2026-07-28`  协议，请求还要求由客户端 SDK 生成协议版本与客户端能力等字段；适配器不应伪造或删除它们。[4]

```
// 与 StartExecution 放在同一个 package；沿用前文 imports。type CallToolParams struct {    Name      string         `json:"name"`    Arguments map[string]any `json:"arguments"`    Meta      map[string]any `json:"_meta,omitempty"`}// protocolMeta 由已完成协议协商的 MCP SDK 生成，其中可能包含// io.modelcontextprotocol/protocolVersion、clientCapabilities 等必需字段。// 此函数只复制并附加遥测字段，不能替代 SDK 的请求构造器。func BuildToolParams(    ctx context.Context,    name string,    args map[string]any,    protocolMeta map[string]any,) CallToolParams {    carrier := propagation.MapCarrier{}    propagation.TraceContext{}.Inject(ctx, carrier)    meta := make(map[string]any, len(protocolMeta)+len(carrier))    for k, v := range protocolMeta {        meta[k] = v    }    for k, v := range carrier {        meta[k] = v    }    return CallToolParams{Name: name, Arguments: args, Meta: meta}}func ExtractToolContext(ctx context.Context, meta map[string]any) context.Context {    carrier := propagation.MapCarrier{}    // 此示例有意不转发 baggage。若业务确有需要，应逐键白名单、    // 限制大小，并在跨信任边界前移除租户或内部身份信息。    for _, key := range []string{"traceparent", "tracestate"} {        if value, ok := meta[key].(string); ok {            carrier[key] = value        }    }    return (propagation.TraceContext{}).Extract(ctx, carrier)}
```

客户端应先使用 SDK 构造经过协商的请求参数，再在  `mcp.tools.call`  Span 下合并 Trace Context；服务端提取后启动 Server Span。 `tools/call`  返回的业务失败也要解析，例如工具结果的失败标记；HTTP 200 或 JSON-RPC 无传输错误不代表工具成功。

stdio Transport 的 stdout 必须留给协议报文，诊断日志写 stderr。代理若只看到加密或未解析的报文，无法凭空恢复内部 metadata；网关能提取上下文的前提是它实际解析了对应消息。

跨不可信边界可根据本地策略新建 Trace 并保留 Link。传入 Trace Context 只用于关联，绝不能据此决定租户、授权或绕过采样限额。

### 5.4 调用时序：恢复不是重放整个任务

```
恢复 WorkerMCPWorker状态库与 OutboxAPI恢复 WorkerMCPWorker状态库与 OutboxAPI进程中断，调用结果可能未保存事务写 Task 与投递意图返回 202原子领取并登记 Execution 上下文调用工具，携带 Effect ID 和 Trace Context持久化效果与审计Lease 到期后接管，创建新 ExecutionCheckpoint、前次上下文、Effect ID新 Trace link 前次 Execution按 Effect ID 查询或幂等重试返回已确认效果事务写 Checkpoint、状态事件与 Outbox
```

等待审批不应保持数据库事务、Worker 协程与 Span 跨小时打开。持久化  `WAITING_APPROVAL`  后释放执行资源；审批回调产生新事件，后续 Execution link 等待前的执行与审批决定。

## 六、崩溃之后，谁证明旧 Attempt 怎么了

### 6.1 崩溃进程不能可靠地给自己写遗言

SIGKILL 与 OOMKilled 没有可靠的 Go  `defer`  清理机会。SDK 常在 Span 结束后才交给处理器；尚未结束或尚未导出的 Span 可能完全不存在。Collector 无法补救从未到达它的数据。

因此：

- Execution 开始、所有权转移、状态转换写入持久化事实。
- 外部控制器采集 Pod、Container、Node 证据。
- 恢复方记录“观察到旧租约过期并接管”，而不是直接填写“旧 Worker OOM”。

同一 Pod UID 可能包含多次容器重启。关联时至少使用  `cluster + namespace + pod_uid + container + container_id/restart_count + 时间区间` ，不能只按 Pod 名称关联。

### 6.2 状态事件必须表达不确定性

推荐事件字段：

```
{  "event_type": "execution.taken_over",  "event_id": "由事务生成的唯一事件ID",  "task_id": "任务ID",  "previous_execution_id": "旧执行ID",  "execution_id": "新执行ID",  "observed_reason": "lease_expired",  "termination_cause": "unknown",  "evidence_refs": [],  "occurred_at": "事实发生时间；无法确定时允许为空",  "observed_at": "观察者记录时间",  "schema_version": 1}
```

这是字段示意，不是实际实验输出。后续若采集到对应容器的  `reason=OOMKilled` ，可以追加  `execution.evidence_attached`  事件。保留原记录，不用新推断悄悄覆盖历史事实。

 `lease_expired`  证明领取条件成立，不能证明进程死亡； `exitCode=137`  也不能单独证明 OOM。Pod 删除、驱逐、容器重启和节点失联要分别建模。

### 6.3 恢复时间线：相对次序，不伪造耗时

```
异步证据

T0：登记 Execution 与 Trace ContextT1：工具产生效果，响应未落库T2：Worker 中断，末尾 Span 可能丢失T3：租约满足接管条件T4：新 Execution 与 Fencing Token 提交T5：新 Trace link 旧执行，核对效果T6：Checkpoint 与事件共同提交附加容器终止或发布证据
```

这是设计顺序图，T0 到 T6 没有附会任何实测秒数。跨主机时间线还要考虑时钟偏差；所有权顺序优先依赖数据库事务、版本号和事件序号，不能只比较日志时间戳。

## 七、Lease、Fencing、Checkpoint、Outbox 的可观测性

### 7.1 Kubernetes Lease 不能自动提供业务 Fencing

Kubernetes Lease 常用于心跳与 Leader Election。 `leaseTransitions`  是持有者变化字段，不能直接等同于可靠的业务 Fencing Token：对象删除重建可能丢失历史，更新依赖客户端实现，下游资源也不会自动验证这个字段。client-go 的 Leader Election 实现明确提醒：它不保证 fencing。[5]

本文选择 PostgreSQL 单行任务状态维护业务所有权。每次领取在事务中增加 Task 作用域的  `fencing_token` ，下游写入则按资源自己的并发模型验证。**不同 Task 的 Token 不能直接比较大小，解决同一共享资源竞争还需要资源级版本或独立的 fencing 域。**

所有权变化可能来自恢复、主动交接、重新调度或人工操作。不要把  `takeover_total`  直接命名为“崩溃次数”。

### 7.2 最小事实表

以下为简化 PostgreSQL schema，省略租户索引、外键和分区；生产库需补齐权限与约束：

```
CREATE TABLE agent_task (    task_id text PRIMARY KEY,    status text NOT NULL,    current_execution_id text,    lease_owner text,    lease_until timestamptz,    fencing_token bigint NOT NULL DEFAULT 0,    checkpoint_version bigint NOT NULL DEFAULT 0,    checkpoint jsonb NOT NULL DEFAULT '{}'::jsonb,    updated_at timestamptz NOT NULL DEFAULT clock_timestamp());CREATE TABLE agent_execution (    execution_id text PRIMARY KEY,    task_id text NOT NULL,    execution_no bigint NOT NULL,    fencing_token bigint NOT NULL,    trace_context jsonb NOT NULL,    worker_instance text NOT NULL,    pod_uid text,    started_at timestamptz NOT NULL,    ended_at timestamptz,    outcome text,    UNIQUE (task_id, execution_no));CREATE TABLE agent_event_outbox (    event_id text PRIMARY KEY,    task_id text NOT NULL,    event_type text NOT NULL,    payload jsonb NOT NULL,    created_at timestamptz NOT NULL DEFAULT clock_timestamp(),    published_at timestamptz);
```

领取事务用  `SELECT ... FOR UPDATE SKIP LOCKED`  选取符合状态与 Lease 条件的任务；更新 owner、execution、token、lease；写入 Execution 与接管事件；提交成功后才执行外部操作。这里不把领取算法伪装成完整 SQL：需要明确任务状态机、执行编号分配、竞争重试和数据库隔离级别后再实现。

不要把前次关联上下文只保存在最后成功 Checkpoint 内。Execution 表保留全部执行区间，Checkpoint 只表示可恢复进度。

### 7.3 Checkpoint 提交必须验证当前执行身份

```
UPDATE agent_taskSET checkpoint = $1::jsonb,    checkpoint_version = checkpoint_version + 1,    updated_at = clock_timestamp()WHERE task_id = $2  AND current_execution_id = $3  AND lease_owner = $4  AND fencing_token = $5  AND checkpoint_version = $6  AND lease_until > clock_timestamp()  AND status = 'RUNNING';
```

要求当前 Token **相等**，不能只用  `stored_token <= incoming_token` 。Token 必须来自原子领取，不允许写入方自行声明更大值。

 `ExecContext`  返回  `err == nil`  只代表 SQL 被执行，不代表更新成功。Go 端必须检查行数：

```
package checkpointimport (    "context"    "database/sql"    "errors")var ErrCheckpointNotCommitted = errors.New("checkpoint not committed")func UpdateOne(ctx context.Context, tx *sql.Tx, query string, args ...any) error {    result, err := tx.ExecContext(ctx, query, args...)    if err != nil {        return err    }    rows, err := result.RowsAffected()    if err != nil {        return err    }    if rows != 1 {        return ErrCheckpointNotCommitted    }    return nil}
```

0 行可能是租约失效、CAS 冲突、状态变化或记录不存在，不能统一宣称是 Fencing 拒绝。除非同一事务内有可靠诊断，否则先记录  `checkpoint_precondition_failed` 。

Checkpoint 更新、Execution 结果和对应 Outbox 事件应在同一事务内提交；任意一步出错都回滚。提交结果如果因连接中断而未知，应按  `event_id / checkpoint_version`  回查，不能直接重做副作用。

续租同样校验 owner、execution、token 与尚未到期条件。续租失败时取消执行 context；但取消并不能撤回已发送的远端调用，仍然需要幂等或效果确认。

### 7.4 每一种机制观测不同的失败面

| 机制 | 建议事件或指标 | 必须保留的含义 |
| --- | --- | --- |
| Lease | 获取时长、续租失败、接管次数 | 所有权观察，不直接等于崩溃 |
| Fencing | 下游拒绝旧 owner、任务写入条件失败 | 保护生效也可能意味着调度异常 |
| Checkpoint | 提交时长、版本、失败类别 | 只有事务提交后才计成功 |
| Outbox | pending 数、最老可投递年龄、发布重试 | 已提交事件是否及时发送 |
| Effect Ledger | 未知效果数、去重命中、确认耗时 | 远端副作用是否可判定 |

Outbox pending 不代表“工具副作用没有执行”。它可能只是某条状态通知没发出去。Effect Ledger 才负责表达工具结果的不确定性。

Outbox 投递通常至少一次。消费者按  `event_id`  去重；任务终态计数等关键聚合可从去重后的事实投影计算。直接在 Worker 中  `counter.Add(1)`  可能因进程死亡少计，或重放多计。

## 八、Go 插桩：初始化、错误结束和结构化日志

### 8.1 SDK 初始化不能只创建一个 Tracer

以下为独立  `package telemetry`  文件；生产版本应锁定 API、SDK、OTLP exporter 的兼容版本，并提交  `go.mod/go.sum` 。

```
package telemetryimport (    "context"    "fmt"    "go.opentelemetry.io/otel"    "go.opentelemetry.io/otel/attribute"    "go.opentelemetry.io/otel/exporters/otlp/otlptrace/otlptracegrpc"    "go.opentelemetry.io/otel/propagation"    "go.opentelemetry.io/otel/sdk/resource"    sdktrace "go.opentelemetry.io/otel/sdk/trace")func Init(ctx context.Context, service, version string) (*sdktrace.TracerProvider, error) {    exporter, err := otlptracegrpc.New(ctx) // endpoint / TLS 由受控环境配置    if err != nil {        return nil, fmt.Errorf("create trace exporter: %w", err)    }    res, err := resource.New(ctx,        resource.WithFromEnv(),        resource.WithAttributes(            attribute.String("service.name", service),            attribute.String("service.version", version),        ),    )    if err != nil {        return nil, fmt.Errorf("create resource: %w", err)    }    provider := sdktrace.NewTracerProvider(        sdktrace.WithResource(res),        sdktrace.WithBatcher(exporter),        // 仅用于实验：生产采样策略见后文。        sdktrace.WithSampler(sdktrace.AlwaysSample()),    )    otel.SetTracerProvider(provider)    otel.SetTextMapPropagator(propagation.TraceContext{})    return provider, nil}
```

服务正常退出时先停止领取任务，处理或中断在途执行，再用独立、有限超时的 context 调用  `provider.Shutdown` 。不要传已经取消的进程 context，也不要认为 Shutdown 能挽救 OOMKilled。

本段只初始化 Trace；Metrics 仍需配置 MeterProvider、reader/exporter 与聚合，JSON stdout 日志也需要采集器。不能把这段初始化称为“五类信号全部接通”。

### 8.2  `RecordError`  不代替  `SetStatus`

错误分类需先于插桩定义。内部错误消息可能含凭证和请求内容，不应原样成为 Span status description。

```
package telemetryimport (    "context"    "errors"    "fmt"    "log/slog"    "go.opentelemetry.io/otel/codes"    "go.opentelemetry.io/otel/trace")func ObserveOperation(    ctx context.Context,    tr trace.Tracer,    logger *slog.Logger,    taskID, executionID string,    fn func(context.Context) error,) (err error) {    ctx, span := tr.Start(ctx, "agent.step")    defer func() {        panicValue := recover()        if panicValue != nil {            // 不直接输出 panic 内容，避免泄露输入或凭证。            err = fmt.Errorf("worker panic type=%T", panicValue)        }        if err != nil {            category := "dependency_error"            if errors.Is(err, context.Canceled) {                category = "canceled"            } else if errors.Is(err, context.DeadlineExceeded) {                category = "deadline_exceeded"            }            if panicValue != nil {                category = "worker_panic"            }            span.RecordError(errors.New(category))            span.SetStatus(codes.Error, category)            sc := span.SpanContext()            logger.ErrorContext(ctx, "agent operation ended",                "task_id", taskID,                "execution_id", executionID,                "trace_id", sc.TraceID().String(),                "span_id", sc.SpanID().String(),                "error_category", category,            )        }        span.End()        if panicValue != nil {            panic(panicValue) // 由上层明确决定隔离、重启与任务状态处理        }    }()    return fn(ctx)}
```

这里在同一个 defer 中先记录再 End，避免异常处理发生在 Span 已结束之后。受控异常栈可写到受限诊断通道；不要记录带用户内容的任意 panic 文本。

这只是观测包装，不负责提交终态、释放租约或完成恢复。 `context.Canceled`  是否算故障，还需依据用户取消、发布排空或所有权丢失进一步分类。

### 8.3 错误分类要能驱动恢复策略

| 类别 | 常见证据 | 重试策略 |
| --- | --- | --- |
|  `llm_rate_limited`  | 供应商状态及限流字段 | 限额内退避，遵守提示 |
|  `llm_output_invalid`  | schema 校验失败 | 有上限修复，不循环到耗尽预算 |
|  `tool_auth_denied`  | 授权决定 ID | 不做相同权限下的盲重试 |
|  `approval_expired`  | 审批版本与有效期 | 重新申请或终止 |
|  `lease_lost`  | 续租失败与 owner 核对 | 停止提交，交给接管逻辑 |
|  `checkpoint_precondition_failed`  | 更新 0 行 | 回查事实，不能覆盖 |
|  `effect_unknown`  | 请求已发出，结果不确定 | 查询或按相同幂等键重试 |
|  `worker_termination_unknown`  | Execution 中断，无确定外部证据 | 保留未知，等待补证 |
|  `business_validation_failed`  | 领域规则错误码 | 通常不可重试 |

错误类别是有限枚举，错误详情放脱敏日志。不要把动态异常字符串当作 Prometheus label。

## 九、LLM 的 Token、Latency 与 Cost：三种口径不能混算

### 9.1 Latency 至少区分总时长与首个内容 Token

非流式请求记录总时长即可；流式请求记录：

- 请求发出到首个有效内容 Token 的时间，而非第一条 SSE 心跳。
- 首个内容 Token 到完成的生成时间。
- 完整请求总时长与最终结果。

并非所有流式调用都有内容 Token，例如纯工具调用输出。此时 TTFT 可缺失或使用专门口径，不能写成 0。

### 9.2 Token 缺失不是零

优先使用供应商实际返回的 usage。客户端 tokenizer 推算值标记为  `estimated` ；取消、超时、流断开导致 usage 缺失时标记为  `missing` 。HTTP 超时不意味着供应商没有处理或没有收费。

缓存 Token、推理 Token、音频或图像用量是否包含于其他字段，取决于供应商定义。归一化后必须形成互不重叠的收费类别，防止重复计费。

### 9.3 Cost 是账本计算，Metrics 是趋势投影

通用计算式为：

[C_{estimated}=\sum_{k\in billing\ categories} U_k\times P_k(model,region,price_version)]

其中  `U_k`  是互不重叠的计费单位， `P_k`  是每单位价格。不要在单位未归一化时把“每百万 Token 价格”直接乘 Token 总数。

调用账本至少记录： `invocation_id` 、供应商请求 ID、Task/Step/Execution、模型解析版本、usage 来源、分类用量、币种、价格版本、估算费用和对账状态。金额使用 decimal 或整数最小计价单位，避免 float64 作为财务事实。

一次逻辑调用可能发生多次实际请求，每次真实消耗都要计入；去重依据 Invocation / 供应商请求标识，而不是简单按 Task 去重。估算费用与供应商结算费用可能不同，应独立展示。

下列为**本文自定义指标**，不是声称等同于官方 GenAI instrument：

| 指标 | 类型 | 有界标签 |
| --- | --- | --- |
|  `agent_llm_request_duration_seconds`  | Histogram | workflow、model、outcome |
|  `agent_llm_time_to_first_token_seconds`  | Histogram | workflow、model |
|  `agent_llm_tokens_total`  | Counter | model、token_type、usage_source |
|  `agent_llm_usage_missing_total`  | Counter | model、reason |
|  `agent_llm_estimated_cost_usd_total`  | Counter | model |

固定美元指标只适用于统一折算后的趋势；原始币种与汇率版本保留在账本。每 Task 费用查询账本，不向 Prometheus 注入  `task_id` 。这些指标独立于 Trace 采样，从原始调用结果或去重账本投影产生。

## 十、MCP 授权、审批、审计与副作用如何闭环

工具成功与授权成功是两个不同事实。至少需要关联：

 `task_id → step_id → invocation_id → authorization_decision_id → approval_id/version → effect_id → external_receipt_ref`

授权审计包含主体、作用资源、策略版本、决定、原因码和参数摘要；执行审计包含实际调用、幂等键、结果状态和效果凭证。审计事件要区分  `attempted` 、 `accepted` 、 `confirmed` 、 `rejected` 、 `unknown` 。

审批需要绑定**规范化后的工具参数摘要、目标资源和操作版本**。任务恢复后若参数、目标或审批有效期改变，必须重新检查授权。审批只证明某时刻的批准，不能成为永久权限通行证。

工具 Trace 可以附带授权结果和审计 ID；审计系统独立保存事实，不能因 Trace 未采样而缺失。外部凭证只保存受控引用，不把 bearer token 放进日志或 Span。

对非幂等工具，最危险的窗口是“远端执行成功，本地结果提交前崩溃”。解决办法依赖工具能力：

- 1. 支持幂等键：恢复沿用同一 Effect ID，而不是新 Invocation ID。
- 2. 支持结果查询：优先查询原操作状态，再决定是否重试。
- 3. 都不支持：进入  `effect_unknown`  并人工核对，不能以重试成功掩盖重复副作用风险。

Fencing 只能保护实际检查 Token 的资源；无法阻止一个不校验 Token 的外部支付或云 API。Outbox、Checkpoint 与 Trace 关联也不能创造端到端 exactly-once。

## 十一、Collector 与 Kubernetes：让观测链本身可观测

### 11.1 Collector 基础配置

下例是 **Collector Contrib 实验配置模板**，OTLP/gRPC 入口 4317，Trace 发往内部 Tempo，OTLP Metrics 通过 8889 暴露给 Prometheus。未配置日志管道，应用 JSON stdout 由另行部署的日志采集器接收。

```
receivers:  otlp:    protocols:      grpc:        endpoint: 0.0.0.0:4317processors:  memory_limiter:    check_interval: 1s    limit_mib: 384    spike_limit_mib: 96  batch:    timeout: 2s    send_batch_size: 512extensions:  file_storage:    directory: /var/lib/otelcol/storageexporters:  otlp/tempo:    endpoint: tempo.observability.svc.cluster.local:4317    tls:      insecure: true # 仅可信隔离实验网；生产配置 TLS/mTLS    sending_queue:      enabled: true      storage: file_storage      queue_size: 5000    retry_on_failure:      enabled: true      initial_interval: 1s      max_interval: 10s      max_elapsed_time: 60s  prometheus:    endpoint: 0.0.0.0:8889service:  extensions: [file_storage]  pipelines:    traces:      receivers: [otlp]      processors: [memory_limiter, batch]      exporters: [otlp/tempo]    metrics:      receivers: [otlp]      processors: [memory_limiter, batch]      exporters: [prometheus]
```

必须锁定 Collector 镜像并使用该镜像执行配置验证；组件和字段是否可用，以镜像版本为准。不要把这个模板当作已经部署成功的配置。

持久队列减少已接收遥测在后端暂不可用时的丢失，但磁盘写满、超出重试窗口、节点永久丢失仍可能造成缺口；还未到 Collector 的数据不在保护范围内。[6]

 `/var/lib/otelcol/storage`  要挂载持久卷，并配置容量与告警。多副本通常每个实例使用独立存储目录和卷，不能让多个进程随意共享同一个本地队列数据库。临时  `emptyDir`  不是跨 Pod 重建的持久保护。

上述  `queue_size=5000`  是待验证配置值，不是容量承诺；具体计量单位、请求批量和内存占用需按锁定版本确认。memory limiter 预算也不等于 Pod 的全部 RSS 上限，要给队列、运行时和 exporter 留空间。

观测管道自身至少监控接收/导出失败、队列使用率、磁盘空间、内存、重试与数据丢弃。具体  `otelcol_*`  名称从当前版本  `/metrics`  核对，不能照抄过时名称。

### 11.2 Worker 身份通过 Downward API 注入

以下是 Deployment 的  `spec.template.spec`  合并片段：

```
terminationGracePeriodSeconds: 60containers:  - name: worker    image: registry.example.com/aegis-worker:replace-with-pinned-version    env:      - name: OTEL_SERVICE_NAME        value: aegis-worker      - name: POD_UID        valueFrom:          fieldRef:            fieldPath: metadata.uid      - name: POD_NAME        valueFrom:          fieldRef:            fieldPath: metadata.name      - name: POD_NAMESPACE        valueFrom:          fieldRef:            fieldPath: metadata.namespace      - name: OTEL_RESOURCE_ATTRIBUTES        value: k8s.pod.uid=$(POD_UID),k8s.pod.name=$(POD_NAME),k8s.namespace.name=$(POD_NAMESPACE)      - name: OTEL_EXPORTER_OTLP_ENDPOINT        value: http://otel-collector.observability.svc.cluster.local:4317      - name: RELEASE_ID        value: replace-with-immutable-release-id
```

 `POD_*`  必须先于引用它们的环境变量定义。生产镜像使用 digest；版本信息从构建或可信部署配置注入，不能运行时随意改写成“最新 Git 分支”。

收到 SIGTERM 后停止领取、撤销 ready、排空或持久化执行状态。Liveness 检查进程是否能继续工作，不应因为单次 LLM 超时直接重启 Worker；Readiness 失败也不会自动阻止后台队列消费者领取，应用必须自己实现领取开关。

## 十二、PromQL 与 Grafana Dashboard：先明确指标从哪里来

以下 PromQL 基于本文自定义指标契约。实际 exporter 若改名或没有相应指标，查询不会自动生效。上线前用  `/metrics` 、Prometheus targets 和样例序列检查名称、单位与标签。

### 12.1 用户任务失败比例

假定  `agent_task_terminal_total{workflow,outcome}`  从去重任务终态事件投影产生，且 outcome 为  `success / failed / canceled` 。下面把用户取消排除：

```
sum by (workflow) (  rate(agent_task_terminal_total{outcome="failed"}[15m]))/sum by (workflow) (  rate(agent_task_terminal_total{outcome=~"success|failed"}[15m]))
```

没有样本或没有终态任务时应显示“无数据/无完成任务”，不要用任意  `clamp_min(..., 1)`  把低流量错误率压低。告警增加最小事件数，例如同窗口  `increase`  的成功加失败总数超过团队定义的样本阈值。

长任务在进入终态前不会进入分母，因此还要有运行任务数量、最老可执行队列年龄、无进展任务数，防止“所有任务都卡住，失败率却是零”。

### 12.2 MCP 工具调用 P99

```
histogram_quantile(  0.99,  sum by (le, tool_class) (    rate(agent_tool_call_duration_seconds_bucket[5m])  ))
```

经典 Histogram 必须在聚合时保留  `le` 。先对各序列  `rate` ，再聚合，最后求分位数；不能平均各 Pod 的 P99。P99 是桶插值估计，低样本时结合调用数量解读。[7]

### 12.3 模型用量与估算成本

```
sum by (model, token_type, usage_source) (  increase(agent_llm_tokens_total[1h]))
```

```
sum by (model) (  increase(agent_llm_estimated_cost_usd_total[1h]))
```

 `increase`  可能因抓取边界外推呈现小数，这是趋势估计，不是账单。缺失 usage 单独画面板，不能从 Token 曲线“正常”推断成本完整。

### 12.4 Lease、Checkpoint 与 Outbox

```
sum by (reason) (  increase(agent_execution_takeover_total[1h]))
```

```
sum by (reason) (  increase(agent_checkpoint_commit_failure_total[15m]))
```

```
max by (queue) (agent_outbox_oldest_ready_age_seconds)
```

 `oldest_ready_age`  定义为当前已满足投递时间且未完成事件的最老年龄；延迟投递事件不要提前计为积压。没有 pending 时输出 0；采集失败时暴露错误或缺失，不把数据库不可用伪装成无积压。

如果每个 Relay 都扫描全局 Outbox，pending gauge 不能按实例相加，否则重复计算。明确指标代表全局、分片还是实例本地队列。

### 12.5 Dashboard 应支持从整体到单任务下钻

| 区域 | 面板 | 下钻方向 |
| --- | --- | --- |
| 用户结果 | 成功/失败/取消、端到端耗时、等待原因 | 工作流 → 时间段 |
| 执行健康 | 活跃执行、接管原因、续租失败、Checkpoint 冲突 | Worker / 版本 → 日志 |
| LLM | 总延迟、TTFT、调用数量、Token、usage 缺失、估算费用 | 模型 → 调用 Trace / 账本 |
| MCP 与权限 | 工具延迟、拒绝、审批等待、未知效果 | 审计决定 → Effect |
| 基础设施与发布 | Pod 终止、资源变化、发布 annotation | Pod UID / Release |
| 观测质量 | 导出失败、队列、遥测缺口 | Collector 实例 |

单任务证据页从 Task Store 查询所有 Execution 的 Trace ID，再分别跳转。不要把“后端自动遍历所有 Span Links”作为核心依赖：索引、UI 与查询支持必须实测。

Grafana 中的 Trace、Logs、Audit 跳转都要透传可授权的查询条件。面板变量不是安全边界，浏览器改个  `task_id`  不应看到别的租户数据。

## 十三、Argo CD 发布与故障关联：时间相近只是线索

一次 Sync 不等于所有 Pod 已运行新镜像。需要记录至少三类证据：

- 1. Argo CD 同步的期望 revision、应用、环境与操作结果。
- 2. 实际 Deployment / ReplicaSet 的模板变更及 rollout 状态。
- 3. 具体 Execution 所在 Pod 的镜像 digest、应用版本、配置摘要与策略版本。

以下是 Argo CD Notifications 的 trigger 片段，不是完整 webhook 部署：

```
apiVersion: v1kind: ConfigMapmetadata:  name: argocd-notifications-cm  namespace: argocddata:  trigger.on-agent-deployed: |    - when: app.status.operationState.phase in ['Succeeded'] and app.status.health.status == 'Healthy'      oncePer: app.status.sync.revision      send: [agent-deployment-event]
```

还需配置同名 template、webhook service 与 Application subscription。接收端验证身份、按事件 ID 去重，记录应用 UID、观察时间、revision、release ID，再写事件流和 Grafana annotation。[8]

 `oncePer: revision`  适合“每个 revision 只通知一次”的设计，却可能隐藏相同 revision 下的重部署；多 source 应用也不能只依赖单一 revision 字段。需要检测每次操作时，按实际 Argo CD 版本选择 operation 身份及去重规则。

故障关联遵循递进证据：

| 证据 | 可以说什么 |
| --- | --- |
| 失败率与发布 annotation 重叠 | 时间相关，值得排查 |
| 失败 Execution 集中在新版本 Pod | 版本相关性增强 |
| 新版本修改续租路径，日志与状态显示续租异常 | 有机制解释的候选原因 |
| 相同输入对照、可重复注入、修复或回滚后现象消退 | 更强因果证据，仍需排除共同变量 |

恢复耗时可拆为剩余租约等待、调度轮询、冷启动、状态读取与效果核对。它们可能重叠，应结合时间点测量，不能把所有 P99 相加当成实际恢复 P99。

## 十四、任务失败归因：输出结论，也输出证据缺口

### 14.1 以 Task 为入口重建事实

值班流程建议固定为：

- 1. 查 Task 状态、版本和最后进展点，确认失败还是仅等待。
- 2. 列出全部 Execution、Step Attempt 和 Invocation，而非只看最后一条 Trace。
- 3. 找到首次偏离预期的事实：权限拒绝、依赖错误、所有权变化或未知效果。
- 4. 联查授权、审批和 Effect Ledger，确定副作用是否发生。
- 5. 按容器实例与时间区间附加 Kubernetes 终止证据。
- 6. 核对实际执行版本、配置与发布记录，形成候选解释。
- 7. 记录未证实部分及下一步验证，避免强行给所有任务分配根因。

### 14.2 归因记录模板

```
task_id: 待填final_state: 待填failure_stage: 待填observed_failure: 待填candidate_cause: unknownconfidence: insufficientfacts:  - source: task_store    ref: 待填  - source: execution_event    ref: 待填trace_refs: []audit_refs: []effect_state: unknownkubernetes_evidence: []release_evidence: []missing_evidence: []alternative_explanations: []next_verification: 待填
```

“原因未知，但已确认未重复执行工具”可以比“怀疑 OOM 导致一切”更有价值。归因的目标是减少不确定性，而不是生成听起来完整的事故故事。

LLM 可以帮助归纳日志，但其输出必须引用可访问的证据 ID、受权限限制，并允许  `unknown` ；不能让模型根据几条日志自行编造根因。

## 十五、故障注入实验：怎么做，什么才算通过

### 15.1 前置条件与固定版本

只在隔离测试 namespace 执行。固定 Worker 镜像 digest、Go 版本、OTel 模块版本、MCP 协议及 SDK、Collector 镜像、数据库 schema、Trace 后端、Grafana、Prometheus 与 Argo CD 版本。

使用可控 LLM stub 和带 Effect Ledger 的 MCP mock。stub 支持流中断、usage 缺失、限流和慢响应；工具 mock 支持“已提交副作用但响应延迟”。为故障窗口设置测试专用 barrier，而不是靠人工碰巧删到正确时刻。

测试配置中的超时、Token 和费用都是**输入参数**，不能当作真实供应商性能数据。

### 15.2 实验矩阵

| 实验 | 注入点 | 必须看到的事实 | 通过条件 |
| --- | --- | --- | --- |
| E1 强制终止 | Execution 上下文提交后、Checkpoint 前 | 新旧执行、接管事件、新 Trace Link | Task ID 不变，新 Execution 不复用旧身份 |
| E2 响应丢失 | 工具效果提交后、响应前 | effect unknown、原 Effect ID、效果查询 | 副作用实际计数为 1；无法确认则停在未知 |
| E3 旧 owner 回写 | 旧 Worker 失去 Lease 后恢复 | 新 token、旧条件更新 0 行 | Checkpoint 不回退，旧 owner 不覆盖 |
| E4 Collector 断连 | 执行期间停止遥测出口 | 导出队列与丢弃情况、业务事件 | 任务事实完整；Trace 缺口被承认 |
| E5 审批变化 | 审批后修改参数或让审批过期 | 授权重新检查与拒绝审计 | 不能复用失效审批执行新参数 |
| E6 流式中断 | 首内容 Token 后断开流 | 错误、缺失 usage、费用未决 | 不伪造完整 usage 或零费用 |
| E7 发布排空 | 运行中触发滚动更新 | Release、Pod、Execution 关联 | 主动停止领取、无旧 owner 提交 |
| E8 上下文恶意输入 | 无效或越权 Trace / Baggage | 解析结果、本地授权与限制 | 不影响身份，不产生无限基数 |

E3 应区分数据库写入拒绝与下游效果拒绝，两者分别测试。仅看到本地 SQL 更新 0 行，不能宣称外部工具也受到 Fencing 保护。

### 15.3 可复用的 Kubernetes 观察命令

先把变量替换为测试资源。保存原始输出，而不是只截取 Dashboard：

```
kubectl -n aegis-observe-lab get pods -l app=aegis-worker -o widekubectl -n aegis-observe-lab get pod "$TEST_POD" -o jsonkubectl -n aegis-observe-lab logs "$TEST_POD" -c worker --timestampskubectl -n aegis-observe-lab logs "$TEST_POD" -c worker --previous --timestampskubectl -n aegis-observe-lab get events --sort-by=.metadata.creationTimestamp
```

 `--previous`  仅对仍可查询且保留上次容器日志的 Pod 有效；Pod 删除或节点日志回收后可能失败。Kubernetes Events 也有保留窗口，应在实验开始前持续采集。

测试强制删除：

```
kubectl -n aegis-observe-lab delete pod "$TEST_POD" --grace-period=0 --force
```

这验证 API 强制删除后的接管与隔离，不保证旧进程立即停止，也不等价于真实 OOM。若使用进程 SIGKILL、压力容器触发 OOM 或节点故障，分别记录注入方法与可观察证据，不混写为一个实验。

### 15.4 SQL 核对与对账

```
SELECT execution_id, execution_no, fencing_token, trace_context,       worker_instance, pod_uid, started_at, ended_at, outcomeFROM agent_executionWHERE task_id = $1ORDER BY execution_no;SELECT task_id, status, current_execution_id, fencing_token,       checkpoint_version, checkpointFROM agent_taskWHERE task_id = $1;SELECT event_id, event_type, created_at, published_at, payloadFROM agent_event_outboxWHERE task_id = $1ORDER BY created_at, event_id;
```

同时间戳的  `event_id`  排序只便于稳定展示，不证明因果顺序；严格顺序需额外的事务版本或 Task 内事件序号。再按 Effect ID 查询工具 mock 的实际写入次数，检查新 Trace 中 Link 指向已持久化的旧上下文。

实验环境暂设全量 Trace 采样，先验证传播与恢复；再另做采样实验。否则看不到旧 Trace 可能只是采样丢弃，而不是恢复逻辑错误。

### 15.5 实验记录表：本次均未执行

| 项目 | 记录 |
| --- | --- |
| 实验编号 / 版本清单 | 待执行后填写 |
| Task / Execution / Effect ID | 待填写 |
| 注入 barrier 与触发时间 | 待填写 |
| 原始 SQL、OTLP、日志与 K8s 证据 | 待填写 |
| 预期 | 按实验矩阵填写 |
| 实际观察 | 未执行 |
| 判定 | 未验证 |
| 证据缺口 / 后续动作 | 待填写 |

没有实验记录就不写“恢复时间下降”“定位效率提升”或“无重复副作用”。只有端到端实验通过后，才允许把对应结论升级为已验证。

## 十六、采样、隐私与成本：完整归因不能靠无限采集

### 16.1 每 Task 一致采样是应用设计，不是默认能力

新 Execution 使用新 Trace ID 时，默认按 Trace ID 采样可能让同一 Task 的不同执行取样不一致。

可在 Task 创建时基于受控随机决策或带密钥的 Task ID hash 得到  `telemetry_sampled` ，随持久化上下文传递，由自定义 Sampler 在根 Span 创建时读取。对子 Span 使用 ParentBased 行为保持一致。决策值由服务端产生，不能由外部 metadata 任意要求全量采集。

这需要实际实现、传播并测试。OTel 默认 Sampler 不会自动按  `task_id`  关联多个 Trace；普通 tail sampling 也不会自动跨 Trace 重组一个持续数小时的 Task。

头部采样丢弃后，尾部采样无法恢复那些根本未发送的 Span。即使全量采样，进程突然终止仍可能丢失未结束 Span。

因此无论是否采样，状态事件、关键审计、调用用量与费用账本都按各自可靠性要求保留。Span Links 只是导航，不能承担唯一恢复证据。

### 16.2 控制采集体量

先预算：任务量 × 每任务平均执行次数 × 每执行 Span 数 × 单 Span 大小 × 保留时间。日志与指标另算，不能只计算 Trace。

优先压缩无诊断价值的重复事件，限制工具输出长度，采用有界标签与版本化字段。错误摘要保留类别和证据引用，不输出完整 prompt、检索文档与工具参数。采样率、索引字段和保留周期都要有可解释预算。

### 16.3 哈希不等于脱敏，引用也需要权限

手机号、邮箱、短枚举直接哈希仍可能被枚举；必要时使用有密钥 HMAC 并管理轮换。内容引用不应是永久公开 URL，也不要在 Span 中放长期签名下载地址。

Baggage 默认只保留明确白名单，设置大小和数量限制；跨外部域不传播租户内部信息。本文 Go 示例只传播 TraceContext，未启用全量 Baggage。

Trace、日志、审计与原始内容使用不同访问控制与保留周期。审计保留多久由实际合同、业务和合规要求确定，不能通用地写成“所有场景保留几年”。

## 十七、从最小闭环到生产验收

落地顺序应围绕可解释性逐步增加能力：

- 1. 先统一 Task、Execution、Step、Invocation、Effect 身份与错误枚举。
- 2. 在副作用之前持久化 Execution 上下文，打通 API、Worker、MCP 传播。
- 3. 完成接管事件、Checkpoint 条件更新和 Effect 状态核对。
- 4. 接入独立的 Metrics、结构化日志与审计，验证 Trace 缺失时仍能查事实。
- 5. 增加 Kubernetes 容器证据、Release 标识与 Argo CD 发布 annotation。
- 6. 执行 E1–E8，最后验证采样、后端故障与数据权限边界。

上线验收要能回答这些具体问题：

- 随机给一个 Task ID，能否找到所有执行区间、步骤尝试和外部效果？
- 旧 Trace 不存在时，能否明确说明缺的是采样、未导出还是尚不能判断？
- 旧 owner 活过来之后，状态与外部写入分别由什么机制保护？
- 审批失效、工具返回业务失败、usage 缺失是否都有独立口径？
- 集群发布后，能否定位实际受影响的容器实例与版本？
- 关闭观测后端，任务事实和关键审计还能否按约定保存？

本文的关键是：把“查找最后一条失败 Trace”升级为“围绕 Task 重建执行与副作用证据”。Trace 展示调用过程，Metrics 刻画影响范围，Logs 提供细节，Events 还原状态变化，Audit 证明权限与执行。只有把它们建立在可验证的任务事实之上，断点续跑才不只是执行恢复，也是可解释性的恢复。

## 附录 A：Java 对照实现——同一模型，不复制 Go 的生命周期假设

本文的任务模型与语言无关： `Task / Execution / Step Attempt / Invocation / Effect` 、事实库、Lease、Fencing 与 Effect Ledger 不能因为服务换成 Java 而改变。变化的只是 SDK 生命周期、线程池取消与日志关联的实现方式。

### A.1 从消息来源创建新 Trace 并保留 Links

以下片段展示与前文 Go  `StartExecution`  相同的语义：Worker Execution 始终创建新根 Span；消息来源和前次 Execution 只作为 Link。 `traceparent`  不是授权凭据，且解析失败只意味着不建立 Link，绝不能阻断业务领取。

```
package example.telemetry;import io.opentelemetry.api.common.AttributeKey;import io.opentelemetry.api.common.Attributes;import io.opentelemetry.api.trace.Span;import io.opentelemetry.api.trace.SpanContext;import io.opentelemetry.api.trace.SpanKind;import io.opentelemetry.api.trace.Tracer;import io.opentelemetry.context.Context;import io.opentelemetry.context.propagation.TextMapGetter;import io.opentelemetry.api.trace.propagation.W3CTraceContextPropagator;import java.util.Map;import java.util.Set;import java.util.HashSet;public final class ExecutionTracing {  private static final TextMapGetter<Map<String, String>> MAP_GETTER =      new TextMapGetter<>() {        @Override public Iterable<String> keys(Map<String, String> carrier) {          return carrier.keySet();        }        @Override public String get(Map<String, String> carrier, String key) {          return carrier.get(key);        }      };  public record ExecutionMeta(      String taskId,      String executionId,      long attempt,      Map<String, String> trigger,      Map<String, String> previous) {}  public static Span startExecution(Tracer tracer, ExecutionMeta meta) {    var builder = tracer.spanBuilder("agent.execution")        .setNoParent()        .setSpanKind(SpanKind.CONSUMER)        .setAttribute("aegis.task.id", meta.taskId())        .setAttribute("aegis.execution.id", meta.executionId())        .setAttribute("aegis.execution.attempt", meta.attempt());    Set<String> seen = new HashSet<>();    addLink(builder, meta.previous(), "resumes_execution", seen);    addLink(builder, meta.trigger(), "triggered_by", seen);    return builder.startSpan();  }  private static void addLink(      io.opentelemetry.api.trace.SpanBuilder builder,      Map<String, String> carrier,      String relation,      Set<String> seen) {    if (carrier == null) return;    Context extracted = W3CTraceContextPropagator.getInstance()        .extract(Context.root(), carrier, MAP_GETTER);    SpanContext sc = Span.fromContext(extracted).getSpanContext();    if (!sc.isValid()) return;    String key = sc.getTraceId() + ":" + sc.getSpanId();    if (!seen.add(key)) return;    builder.addLink(sc, Attributes.of(        AttributeKey.stringKey("aegis.link.relation"), relation));  }}
```

调用侧须将  `Span`  放入当前  `Context`  的 scope，且 scope 生命周期只覆盖当前 Execution 内真正需要继承父子关系的工作。不要把请求线程的  `Context`  直接保存到数据库或跨线程无限持有；应只持久化 W3C Trace Context 的有限 carrier，并在恢复时按上述方式提取为 Link。

```
Span span = ExecutionTracing.startExecution(tracer, meta);try (var scope = span.makeCurrent()) {  runClaimedExecution(); // 线程池任务须显式传播 Context，不能假定自动继承} catch (Exception e) {  span.recordException(e);  span.setStatus(io.opentelemetry.api.trace.StatusCode.ERROR, "dependency_error");  throw e;} finally {  span.end();}
```

异常的原始内容也可能含 prompt、令牌或工具参数。生产实现应先映射为有限  `error_category` ，把受控诊断引用写入受限日志或审计系统；不要把  `e.getMessage()`  直接作为 Span status description。

### A.2 Java 的关闭、线程与恢复边界

 `SdkTracerProvider.shutdown()`  与 Java Executor 的关闭是不同动作。优雅终止的正确顺序仍是：停止领取 → 撤销 Readiness → 取消或持久化在途 Execution → 关闭线程池 → 使用独立且有限的时间预算 flush/shutdown OTel。JVM 被 SIGKILL、OOM killer 终止时同样不能依赖 shutdown hook 交付最后一个 Span，因此 Execution 登记和 Effect 账本必须先于外部副作用提交。

对于  `CompletableFuture` 、Reactor、Kotlin coroutine 或框架线程池，先以集成测试验证 Context 是否被正确传播。若未验证，不要因日志中偶尔出现 trace ID 就假设异步链路完整；将  `task_id` 、 `execution_id`  作为显式结构化字段仍是必要的兜底。

## 附录 B：交付物、验收证据与“完成”定义

要把本文从设计文档升级为可上线能力，交付物不能只有 Dashboard。每一项应有版本、负责人、证据位置与复核日期：

| 交付物 | 最低完成标准 | 不足以证明完成的现象 |
| --- | --- | --- |
| 任务事实 schema 与迁移 | 并发领取、旧 owner 回写、未知效果均有自动化测试 | 只创建了几张表 |
| Go / Java 插桩库 | 锁定依赖，可编译；HTTP、队列、MCP 传播测试通过 | 本地能看到一个 Span |
| MCP 适配器 | SDK 协商元数据未丢失；业务失败、JSON-RPC 失败、超时均分类 | HTTP 200 返回 |
| Effect Ledger | 幂等查询、重复投递、结果未知路径有回归测试 | 仅在日志里记录 effect ID |
| Collector 与后端 | 镜像配置校验、持久卷、队列/丢弃/磁盘告警已演练 | Pod 处于 Running |
| Dashboard 与权限 | Task 下钻、租户隔离、Trace/Log/Audit 跳转授权测试 | 面板变量能筛选 task ID |
| 故障实验 | E1–E8 的版本、原始证据、实际判定与缺口已归档 | 演练口头通过 |

建议把 E1、E2、E3、E5、E7 设为发布前阻断项：它们分别覆盖中断恢复、未知副作用、旧 owner 隔离、审批失效与滚动发布。E4、E6、E8 则验证遥测降级、供应商用量缺失与恶意上下文边界。任一项失败时，结论应准确写成“能力未通过该场景验证”，而非泛化为整套方案不可用。

## 官方参考与适用边界

以下为本次核对的官方资料。示例仍需按实际锁定版本进行编译、配置检查与集成验证。

- 1. OpenTelemetry Traces：Span、Link 与异步消费者
- 2. OpenTelemetry Go Instrumentation
- 3. OpenTelemetry GenAI 语义约定迁移说明 ； GenAI 属性注册表 。迁移后应跟随官方链接锁定新仓库提交，而非依赖旧路径长期不变。
- 4. MCP 2026-07-28 Base Protocol：  `_meta`  的 Trace Context 键 ； SEP-414 。旧协议与 SDK 的支持情况须另验。
- 5. Kubernetes Leases ； client-go Leader Election 的 fencing 边界 。生产引用请固定到实际模块版本，避免依赖 master。
- 6. OpenTelemetry Collector Resiliency
- 7. Prometheus Query Functions ； Histograms and Summaries
- 8. Argo CD Notifications Triggers

---
原文链接：https://mp.weixin.qq.com/s?__biz=Mzg3ODkxNDk0Nw%3D%3D&mid=2247488689&idx=1&sn=daead4a71a3967c35d334932390c4577&chksm=cf0d285df87aa14b0e427240eda14491904c3253997de1a3f8aebdc70d1114215860e6375371
