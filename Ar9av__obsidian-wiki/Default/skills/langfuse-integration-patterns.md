---
title: "Langfuse 集成模式"
category: skills
tags:
  - ai-agent
  - observability
  - langfuse
  - instrumentation
sources:
  - "Git 拆解: Langfuse 实战：部署、埋点、评估，跑通 LLM 可观测全流程 (2026-06-28)"
  - "IMBoy技术笔记: 可观测性：Langfuse、Langsmith 集成 (2026-07-03)"
summary: "Langfuse 埋点的四种模式：OpenAI drop-in 替换、@observe() 装饰器、LangChain CallbackHandler、Eino callbacks.Handler——从最简单到最灵活。"
base_confidence: 0.60
lifecycle: draft
lifecycle_changed: "2026-07-16"
tier: supporting
provenance:
  extracted: 0.65
  inferred: 0.25
  ambiguous: 0.10
created: "2026-07-16"
updated: "2026-07-16"
---

# Langfuse 集成模式

## 四种埋点方式

### 模式 1：OpenAI Drop-in 替换（最简）

改一行 import，零业务代码改动。^[extracted]

```python
# 替换前
from openai import OpenAI
client = OpenAI()

# 替换后
from langfuse.openai import OpenAI
client = OpenAI()
```

所有 `client.chat.completions.create()` 调用自动上报：输入、输出、token 用量、延迟、错误信息。^[extracted]

初始化只需环境变量：
```
LANGFUSE_PUBLIC_KEY=pk-lf-...
LANGFUSE_SECRET_KEY=sk-lf-...
LANGFUSE_HOST=https://your-langfuse.example.com
```

SDK 后台自动初始化，代码中无需显式 setup。^[extracted]

### 模式 2：@observe() 装饰器（自定义逻辑）

RAG pipeline、Agent 链等复杂流程用 `@observe()` 把自定义函数纳入 trace ^[extracted]：

```python
from langfuse import observe

@observe()
def retrieve_documents(query: str) -> list:
    docs = vector_store.similarity_search(query)
    return docs

@observe()
def generate_answer(query: str, docs: list) -> str:
    context = "\n".join([d.page_content for d in docs])
    return client.chat.completions.create(
        model="gpt-4o",
        messages=[
            {"role": "system", "content": f"Context:\n{context}"},
            {"role": "user", "content": query}
        ]
    ).choices[0].message.content

@observe()
def rag_pipeline(query: str) -> str:
    docs = retrieve_documents(query)
    return generate_answer(query, docs)
```

`@observe()` 自动把函数调用链串联成一条完整 trace，每个被装饰的函数成为一个 span，嵌套调用自动形成父子关系。^[extracted]

### 模式 3：LangChain CallbackHandler（框架集成）

```python
from langfuse.callback import CallbackHandler

handler = CallbackHandler()
chain.invoke({"query": "hello"}, config={"callbacks": [handler]})
```

LlamaIndex 同理通过 callback manager 接入。^[extracted]

### 模式 4：Eino callbacks.Handler（Go 深度集成）

Eino 框架通过统一的 `callbacks.Handler` 接口实现 Langfuse 接入，覆盖 5 个执行时机 ^[extracted]：

```go
type Handler interface {
    OnStart(ctx context.Context, info *RunInfo, input CallbackInput) context.Context
    OnEnd(ctx context.Context, info *RunInfo, output CallbackOutput) context.Context
    OnError(ctx context.Context, info *RunInfo, err error) context.Context
    OnStartWithStreamInput(ctx context.Context, info *RunInfo,
        input *schema.StreamReader[CallbackInput]) context.Context
    OnEndWithStreamOutput(ctx context.Context, info *RunInfo,
        output *schema.StreamReader[CallbackOutput]) context.Context
}
```

**初始化** ^[extracted]：

```go
import cbLangfuse "github.com/cloudwego/eino-ext/callbacks/langfuse"

handler, flusher := cbLangfuse.NewLangfuseHandler(&cbLangfuse.Config{
    Host:      "https://cloud.langfuse.com",
    PublicKey: os.Getenv("LANGFUSE_PUBLIC_KEY"),
    SecretKey: os.Getenv("LANGFUSE_SECRET_KEY"),
    Threads:          5,               // 并发上报 worker
    FlushAt:          50,              // 攒够 50 条就发
    FlushInterval:    10 * time.Second, // 刷新间隔
    MaxTaskQueueSize: 1000,            // 内存队列上限
    Name:      "my-agent",
    UserID:    "default-user",
    SessionID: "default-session",
})
defer flusher()
callbacks.AppendGlobalHandlers(handler)
```

三种注册方式 ^[extracted]：
- 全局注册：`callbacks.AppendGlobalHandlers(myHandler)` — 对所有节点、所有调用生效
- 单次调用：`runner.Invoke(ctx, input, compose.WithCallbacks(myHandler))`
- 指定节点：加 `.DesignateNode("model")` 只对特定节点生效

**节点映射**：`ComponentOfChatModel` → Langfuse **Generation**（含 model name、prompt messages、completion、token 用量）；其他节点 → Langfuse **Span**（输入输出 JSON、耗时）。^[extracted]

**请求级元数据覆盖** ^[extracted]：
```go
ctx = cbLangfuse.SetTrace(ctx,
    cbLangfuse.WithUserID("user-123"),
    cbLangfuse.WithSessionID("session-456"),
    cbLangfuse.WithTags("production", "v2"),
    cbLangfuse.WithRelease("v1.2.3"),
)
runner.Invoke(ctx, input)
```

**关键设计**：每个 Handler 方法返回的 `context.Context` 会传给同一 Handler 的下一个方法——`OnStart` 里存入 `traceID`，`OnEnd` 里就能取到，不依赖全局变量。^[extracted]

## 模式选择指南

| 场景 | 推荐模式 | 理由 |
|------|---------|------|
| 只用 OpenAI SDK | Drop-in 替换 | 零代码改动 |
| RAG / Agent 链 | @observe() 装饰器 | 灵活包裹自定义逻辑 |
| LangChain / LlamaIndex | CallbackHandler | 框架原生集成 |
| Go + Eino 框架 | callbacks.Handler | 类型安全 + 批量异步 |
| 不依赖外部平台 | HandlerBuilder | 自定义日志/metrics |

## 相关页面

- [[langfuse]] — Langfuse 平台完整功能介绍
- [[eino-callback-observability]] — Eino Callback 系统详解
- [[agent-trace-cost-quality-architecture]] — 埋点数据支撑的架构
