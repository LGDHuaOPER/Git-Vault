---
source_url: "https://mp.weixin.qq.com/s?__biz=MzkxOTY3NTg4Ng==&mid=2247484179&idx=1&sn=5151f74de6374bbe2269092282f6c084&chksm=c0ed7e0ce23bbb3f5a220e9688d45cfe5e4399505f1309bcb7855117d8923a47d4fd94630077&mpshare=1&scene=1&srcid=0708M7MJSuWLsBLZkLQ42HCB&sharer_shareinfo=e8102967b45cc54d839148e168d01828&sharer_shareinfo_first=e8102967b45cc54d839148e168d01828"
title: "可观测性：Langfuse、Langsmith 集成"
account: "IMBoy技术笔记"
published_at: "2026-07-03T23:39:28.000Z"
saved_at: "2026-07-15T16:59:52.395Z"
sync_id: "art_546695c08b854c3a9e4d4de06f913463"
parse_status: "ok"
---

# 可观测性：Langfuse、Langsmith 集成

> 系列「企业级 AI Agent 实现拆解」E28 篇。上一篇讲了[调试工具：Eino Dev 交互式调试](https://mp.weixin.qq.com/s?__biz=MzkxOTY3NTg4Ng==&mid=2247484174&idx=1&sn=f2636856fae369b1e9f38bf5c23b69b5&scene=21#wechat_redirect)——开发期在浏览器里单步执行图。这篇讲 生产期可观测性 ——把每次 Agent 调用的完整链路、Token 消耗、模型参数发到 Langfuse 或 Langsmith。

# 读完这篇你会知道

> - callbacks.Handler 接口：5 个方法，覆盖所有执行时机 - 三种注册方式：全局 / 单次调用 / 指定节点 - Langfuse 接入： NewLangfuseHandler + 批量异步上报 + SetTrace 设置请求元数据 - Langsmith 接入： NewLangsmithHandler + run tree 结构 - HandlerBuilder ：不依赖任何外部平台，自建轻量追踪 - Langfuse vs DeepFlux OTel：两种观测维度，可以同时跑

## 一、问题：LLM 应用的可观测性缺口

传统分布式追踪（OTel）能告诉你每个服务的耗时、错误率、调用关系。但 LLM 应用有它特有的信息：

- 模型收到的 prompt 是什么？
- 输出的 completion 是什么？
- 用了多少 Token？哪个模型？temperature 是多少？
- 同一个用户的多次对话怎么归到一条 session？

这些信息放在 OTel span 里不自然，放在专为 LLM 设计的平台（Langfuse、Langsmith）里才好用。

Eino 把两者都留了接入口——同一个  `callbacks.Handler`  接口。

## 二、Handler 接口：5 个时机

-
-
-
-
-
-
-
-
-

```
type Handler interface {    OnStart(ctx context.Context, info *RunInfo, input CallbackInput) context.Context    OnEnd(ctx context.Context, info *RunInfo, output CallbackOutput) context.Context    OnError(ctx context.Context, info *RunInfo, err error) context.Context    OnStartWithStreamInput(ctx context.Context, info *RunInfo,        input *schema.StreamReader[CallbackInput]) context.Context    OnEndWithStreamOutput(ctx context.Context, info *RunInfo,        output *schema.StreamReader[CallbackOutput]) context.Context}
```

每个节点执行前调  `OnStart` （或流式版），执行后调  `OnEnd` ，出错调  `OnError` 。

`RunInfo`  告诉你是哪个节点：

-
-
-
-
-

```
type RunInfo struct {    Name      string               // 节点名（compose.WithNodeName 指定）    Type      string               // 实现类型，如 "OpenAI"    Component components.Component // 节点类别，如 ComponentOfChatModel}
```

**关键设计**：每个方法返回的  `context.Context`  会传给同一个 Handler 的下一个方法。这样  `OnStart`  里存入  `traceID` ， `OnEnd`  里就能取到——用  `context.WithValue`  在 Handler 内部传状态，不依赖全局变量。

## 三、三种注册方式

-
-
-
-
-
-

```
// 1. 全局注册：对所有节点、所有调用都生效callbacks.AppendGlobalHandlers(myHandler)// 2. 单次调用：仅对这次 Invoke/Stream 生效runner.Invoke(ctx, input, compose.WithCallbacks(myHandler))// 3. 指定节点：仅对名为 "model" 的节点生效runner.Invoke(ctx, input, compose.WithCallbacks(myHandler).DesignateNode("model"))
```

全局注册比 per-invocation 优先级高——先执行全局 Handler，再执行调用时传入的 Handler。

## 四、Langfuse 接入

### 安装

-

```
go get github.com/cloudwego/eino-ext/callbacks/langfuse
```

### 初始化

-
-
-
-
-
-
-
-
-
-
-
-
-
-
-
-
-
-

```
import cbLangfuse "github.com/cloudwego/eino-ext/callbacks/langfuse"handler, flusher := cbLangfuse.NewLangfuseHandler(&cbLangfuse.Config{    Host:      "https://cloud.langfuse.com",    PublicKey: os.Getenv("LANGFUSE_PUBLIC_KEY"),    SecretKey: os.Getenv("LANGFUSE_SECRET_KEY"),    // 批量上报配置（可选）    Threads:          5,               // 并发上报 worker 数，默认 1    FlushAt:          50,              // 攒够 50 条就发，默认 15    FlushInterval:    10 * time.Second,// 每 10 秒刷一次，默认 500ms    MaxTaskQueueSize: 1000,            // 内存队列上限，默认 100    // Trace 元数据（请求级别可覆盖）    Name:      "my-agent",    UserID:    "default-user",    SessionID: "default-session",})// 进程退出前确保所有缓冲事件发出去defer flusher()callbacks.AppendGlobalHandlers(handler)
```

### 节点映射规则

Langfuse 有两种观测单元：

| Eino 节点类型 | Langfuse 对象 | 包含的额外信息 |
| --- | --- | --- |
| `ComponentOfChatModel` | ** Generation ** | model name、model params、prompt messages、completion message、token 用量 |
| 其他节点（Lambda、Tool 等） | ** Span ** | 节点输入（JSON）、节点输出（JSON）、耗时 |

这个区分是自动的，Handler 内部用  `info.Component`  判断分支：ChatModel 走  `cli.CreateGeneration/EndGeneration` ，其他走  `cli.CreateSpan/EndSpan` 。

### 流式处理

流式响应（ `OnEndWithStreamOutput` ）会启一个 goroutine 消费 StreamReader，收集完所有 chunks 之后再调  `EndGeneration` ，所以 Langfuse 上看到的 completion 是完整的，不是一块一块的。

-
-
-
-
-
-
-
-
-
-
-

```
go func() {    defer output.Close()    var outs []callbacks.CallbackOutput    for {        chunk, err := output.Recv()        if err == io.EOF { break }        outs = append(outs, chunk)    }    // 合并后上报    c.cli.EndGeneration(body)}()
```

### 请求级别的 Trace 元数据

全局配置的  `UserID` 、 `SessionID`  是默认值。每个请求可以覆盖：

-
-
-
-
-
-
-

```
ctx = cbLangfuse.SetTrace(ctx,    cbLangfuse.WithUserID("user-123"),    cbLangfuse.WithSessionID("session-456"),    cbLangfuse.WithTags("production", "v2"),    cbLangfuse.WithRelease("v1.2.3"),)runner.Invoke(ctx, input)
```

`SetTrace`  在 context 里存一个  `traceOptions` ，Handler 的  `getOrInitState`  检测到有这个 key 就用它覆盖默认值。

## 五、Langsmith 接入

-

```
go get github.com/cloudwego/eino-ext/callbacks/langsmith
```

-
-
-
-
-
-
-
-
-

```
import cbLangsmith "github.com/cloudwego/eino-ext/callbacks/langsmith"handler, err := cbLangsmith.NewLangsmithHandler(&cbLangsmith.Config{    APIKey: os.Getenv("LANGSMITH_API_KEY"),    APIURL: "https://api.smith.langchain.com", // 默认值，可不填})if err != nil {    log.Fatal(err)}callbacks.AppendGlobalHandlers(handler)
```

Langsmith 在 context 里维护一个  `LangsmithState` ，记录  `TraceID` 、 `ParentRunID` 、 `ParentDottedOrder` ——这是 Langsmith 用来重建 run tree 层级的核心数据。每个节点的运行对应一个 run，嵌套节点的 run 挂在父 run 下面，Langsmith 界面上展示成树形。

## 六、Cozeloop 接入

字节跳动 Coze 平台的可观测工具，接入方式类似：

-

```
go get github.com/cloudwego/eino-ext/callbacks/cozeloop
```

-
-
-
-
-
-
-

```
import (    "github.com/cloudwego/eino-ext/callbacks/cozeloop"    cozeloopcli "github.com/coze-dev/cozeloop-go")client := cozeloopcli.New(cozeloopcli.WithAPIToken(os.Getenv("COZELOOP_TOKEN")))handler := cozeloop.NewLoopHandler(client, cozeloop.WithTracing(true))callbacks.AppendGlobalHandlers(handler)
```

## 七、HandlerBuilder：自建轻量追踪

不想依赖外部平台，只想在本地打日志或推 metrics？用  `HandlerBuilder` ：

-
-
-
-
-
-
-
-
-
-
-
-
-
-
-
-
-
-
-
-
-
-
-
-

```
handler := callbacks.NewHandlerBuilder().    OnStartFn(func(ctx context.Context, info *callbacks.RunInfo, input callbacks.CallbackInput) context.Context {        mi := model.ConvCallbackInput(input)        if mi != nil {            log.Printf("[%s] model call: %d messages", info.Name, len(mi.Messages))        }        return context.WithValue(ctx, startTimeKey{}, time.Now())    }).    OnEndFn(func(ctx context.Context, info *callbacks.RunInfo, output callbacks.CallbackOutput) context.Context {        start, _ := ctx.Value(startTimeKey{}).(time.Time)        mo := model.ConvCallbackOutput(output)        if mo != nil && mo.Message.ResponseMeta != nil {            usage := mo.Message.ResponseMeta.Usage            log.Printf("[%s] done in %v, tokens: %d+%d",                info.Name,                time.Since(start),                usage.PromptTokens,                usage.CompletionTokens,            )        }        return ctx    }).    Build()callbacks.AppendGlobalHandlers(handler)
```

`model.ConvCallbackInput(input)`  把  `CallbackInput`  安全转型为  `*model.CallbackInput` ，如果不是 ChatModel 节点就返回 nil，可以直接 nil-check 跳过。

## 八、Langfuse vs DeepFlux OTel：两个维度

DeepFlux 用 OTel（ `server/internal/observability` ）做全平台追踪，Langfuse 用于 LLM 质量监控——两者不冲突，可以同时运行：

| 维度 | Langfuse / Langsmith | DeepFlux OTel |
| --- | --- | --- |
| 关注点 | LLM 语义：prompt / completion / token | 基础设施：延迟 / 错误率 / 服务依赖 |
| 存储 | 专属后端（云端或自托管） | Tempo（trace）+ Prometheus（metrics） |
| 调试场景 | “这个回答为什么差” | “这个请求为什么慢” |
| 告警 | Langfuse score / evaluation | Grafana alertmanager |
| 接入成本 | 两行代码 | OTel SDK 初始化 + 中间件 |

生产环境两套都跑：OTel 负责 SLO 监控和告警，Langfuse 负责 prompt 质量分析和 session 回放。

## 小结

Eino 的 Callback 接口是可观测性的统一入口。5 个时机（OnStart / OnEnd / OnError / stream 版本），任何实现了接口的对象都能插进去。

Langfuse 接入只需  `NewLangfuseHandler(cfg)`  +  `defer flusher()` ，ChatModel 节点自动上报为 Generation（带 token 用量），其他节点上报为 Span。流式响应在 goroutine 里收集完再上报。 `SetTrace(ctx, ...)`  在请求粒度覆盖 userID 和 sessionID。

Langsmith 同理，核心差异是用 DottedOrder 维护 run tree 层级。

不依赖外部平台的场景用  `HandlerBuilder`  自建，几行代码实现自定义追踪逻辑。

下篇继续。

_代码来源：cloudwego/eino-ext · cloudwego/eino_

---
原文链接：https://mp.weixin.qq.com/s?__biz=MzkxOTY3NTg4Ng%3D%3D&mid=2247484179&idx=1&sn=5151f74de6374bbe2269092282f6c084&chksm=c0ed7e0ce23bbb3f5a220e9688d45cfe5e4399505f1309bcb7855117d8923a47d4fd94630077
