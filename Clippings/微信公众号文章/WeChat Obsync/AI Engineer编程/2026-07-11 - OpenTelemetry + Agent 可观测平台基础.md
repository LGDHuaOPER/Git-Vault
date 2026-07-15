---
source_url: "https://mp.weixin.qq.com/s?search_click_id=10944039153882374254-1784128235491-8354691108&__biz=MzIzNTExNzMwNg==&mid=2647834076&idx=1&sn=7a7c87ecf2e9a23e651dfab22490a24e&chksm=f12aaf817cbfab26071c49ec407152c24eed47cb9b029ab646d80e197a4b7c8d618117bdf064&subscene=0&scene=7&clicktime=1784128235&enterid=1784128235&ascene=65&devicetype=iOS26.5.2&version=18004b3c&nettype=WIFI&abtest_cookie=AAACAA==&lang=zh_CN&countrycode=CN&fontScale=100&exportkey=n_ChQIAhIQQgXeeWXoNda7XcS/yKhhlxLhAQIE97dBBAEAAAAAAJteGovFymIAAAAOpnltbLcz9gKNyK89dVj0oiO/itTErHX/lZ5l0ocYVVKEqFZJSaHzAZXWfa8z2orP42O67huhsJCKizNAH3a6cNceJ+CBHkgjXDx0Ymesstri7nN33DFAM+Q2jbcEnS+YnDoDh6wPdV8vmnWI09/J/J6yjBzB6/nkn6LV8xfJut8oG1B6B4B+o4VnicoXJIZWFnWQQQsidLUZKrNwcGJyUTQw4dbnBUX9uY3qrovHadgKpoa8VQysuNiLNo40ABz6chle+R74rJa5gw==&pass_ticket=xxTWJqKgFgS2iB5F8shb63Pta0yI1iAskPDsvcyoEmyRfor1IPP92klXITejZnwN&wx_header=3"
title: "OpenTelemetry + Agent 可观测平台基础"
account: "AI Engineer编程"
published_at: "2026-07-11T02:23:47.000Z"
saved_at: "2026-07-15T15:10:43.316Z"
sync_id: "art_5f7e899efc3e4d8c977072fb7c2aa5f5"
parse_status: "ok"
---

# OpenTelemetry + Agent 可观测平台基础

# OpenTelemetry + Agent 可观测平台基础

> 只是个基础内容~，包括 OTel 核心概念、Python SDK 手动插桩、自动插桩扩展、Collector 部署、分布式问题处理、以及 Agent 专用语义与评估体系。

## 一、为什么需要可观测平台

### 1.1 Agent 系统的复杂性

AI Agent 正成为生产级 LLM 应用的默认架构。与简单的 API 调用不同，Agent 涉及：

- • 多步推理 ：规划 -> 执行 -> 反思 -> 再规划的循环
- • 工具调用 ：搜索、计算、数据库查询、第三方 API
- • 自主决策 ：条件分支、循环重试、错误恢复
- • 状态管理 ：跨轮次的上下文维护

这种复杂性使得传统的日志（ `print` / `logging` ）完全无法应对。

### 1.2 可观测性的三大支柱

| 支柱 | 解决的问题 | Agent 场景示例 |
| --- | --- | --- |
| ** Trace（追踪） ** | 请求在系统中的完整路径 | 用户提问 -> Agent 规划 -> 工具调用 -> LLM 生成 -> 返回 |
| ** Metric（指标） ** | 系统的整体健康趋势 | Token 消耗趋势、P99 延迟、工具成功率 |
| ** Log（日志） ** | 离散事件的详细记录 | Agent 决策日志、异常堆栈、审计记录 |

## 二、OpenTelemetry 核心架构

### 2.1 分层持有关系

OTel 的初始化遵循"从静态配置到动态数据"的分层架构：

![](附件资源/OpenTelemetry%20+%20Agent%20可观测平台基础/img_1.png)

**关键设计原则**：

- • 配置与使用分离 ：Provider 统一配置，Tracer 按需创建
- • 资源复用 ：一个 Provider 服务多个 Tracer
- • 链式扩展 ：Processor 可任意组合

### 2.2 核心组件详解

#### Resource（资源描述）

```
from opentelemetry.sdk.resources import Resource

resource = Resource.create({
"service.name": "my-agent-service",
"service.version": "1.0.0",
"deployment.environment": "production",
})
```

**作用**：描述产生 telemetry 的实体，每个 Span 都会带上这些属性，用于在后台区分"这是哪个服务的 Span"。

#### TracerProvider（管理中心）

```
from opentelemetry.sdk.trace import TracerProvider

provider = TracerProvider(resource=resource)
trace.set_tracer_provider(provider)
```

**职责**：

- • 创建 Tracer
- • 管理 SpanProcessor 链
- • 生成 trace_id、span_id

#### SpanProcessor（处理链）

```
from opentelemetry.sdk.trace.export import BatchSpanProcessor

processor = BatchSpanProcessor(otlp_exporter)
provider.add_span_processor(processor)
```

**工作方式**：

- 1. Span 结束后进入队列
- 2. 积累到一定数量或时间，批量发送
- 3. 减少网络请求次数，提高吞吐量

#### SpanExporter（导出器）

```
from opentelemetry.exporter.otlp.proto.grpc.trace_exporter import OTLPSpanExporter

exporter = OTLPSpanExporter(
endpoint="http://localhost:4317",
insecure=True,
)
```

**职责**：将数据发送到后端（Jaeger、Prometheus 等）。

## 三、Span 的核心概念

### 3.1 Span 的完整结构

```
{
"trace_id": "7bba9e3338b1c1e5d2b6a2b4c3d4e5f6",
"span_id": "a1b2c3d4e5f67890",
"parent_span_id": "1234567890abcdef",
"name": "llm.call",
"kind": "CLIENT",
"start_time_unix_nano": 1720615800000000000,
"end_time_unix_nano": 1720615800500000000,
"status": {"code": "OK"},
"attributes": {
"gen_ai.system": "openai",
"gen_ai.request.model": "gpt-4o",
"gen_ai.usage.input_tokens": 150
},
"events": [
{
"name": "prompt.sent",
"timestamp_unix_nano": 1720615800100000000,
"attributes": {"prompt.length": 150}
}
],
"links": []
}
```

### 3.2 Attribute vs Event 的区别

| 维度 | Attribute | Event |
| --- | --- | --- |
| ** 本质 ** | Span 的静态元数据 | Span 生命周期中的关键时刻 |
| ** 时间戳 ** | 无（属于整个 Span） | 有独立的时间戳 |
| ** 数量 ** | 通常 10-30 个 | 通常 0-5 个 |
| ** 用途 ** | 描述"这个操作是什么" | 记录"过程中发生了什么" |
| ** 查询方式 ** | "找出 model=deepseek的 Span" | "找出包含 prompt.sent 的 Span" |

**一句话总结**：

> Attribute = Span 的"身份证信息"（是谁、什么配置） Event = Span 的"时间线标记"（什么时候到了哪个阶段）

### 3.3 SpanKind（Span 类型）

| 类型 | 含义 | Agent 场景 |
| --- | --- | --- |
| ** INTERNAL ** | 内部操作 | Agent 规划、推理步骤 |
| ** SERVER ** | 接收外部请求 | FastAPI 入口、Agent 服务启动 |
| ** CLIENT ** | 向外部发起请求 | 调用 OpenAI API、搜索工具 |
| ** PRODUCER ** | 生产消息到队列 | Agent 发送任务到 Kafka |
| ** CONSUMER ** | 从队列消费消息 | Worker 消费任务 |

**核心原则**：SpanKind 回答的是"我在这次调用中扮演什么角色"，与物理位置（内网/外网）无关。

## 四、Python SDK 手动插桩

### 4.1 基础配置

```
from opentelemetry import trace
from opentelemetry.sdk.trace import TracerProvider
from opentelemetry.sdk.trace.export import BatchSpanProcessor
from opentelemetry.exporter.otlp.proto.grpc.trace_exporter import OTLPSpanExporter
from opentelemetry.sdk.resources import Resource

# 1. Resource
resource = Resource.create({
"service.name": "my-agent-service",
"service.version": "1.0.0",
})

# 2. Provider
provider = TracerProvider(resource=resource)
trace.set_tracer_provider(provider)

# 3. Exporter + Processor
exporter = OTLPSpanExporter(endpoint="http://localhost:4317", insecure=True)
processor = BatchSpanProcessor(exporter)
provider.add_span_processor(processor)

# 4. Tracer
tracer = trace.get_tracer("mycompany.agent")
```

### 4.2 Agent 场景的 Span 组织

```
def agent_run(user_query: str):
# Root Span：整个用户请求
with tracer.start_as_current_span(
"agent.run",
kind=trace.SpanKind.SERVER,
) as root:
root.set_attribute("agent.input", user_query)

# 规划（内部操作）
with tracer.start_as_current_span("agent.plan", kind=trace.SpanKind.INTERNAL):
plan = generate_plan(user_query)

# 工具调用（外部请求）
tool_result = call_tool("search", user_query)

# LLM 生成（外部请求）
answer = call_llm(tool_result)

root.set_attribute("agent.output", answer)
return answer

def call_tool(tool_name: str, query: str):
with tracer.start_as_current_span("tool.call", kind=trace.SpanKind.CLIENT) as span:
span.set_attribute("tool.name", tool_name)
# ... 调用工具
return result

def call_llm(prompt: str):
with tracer.start_as_current_span("llm.call", kind=trace.SpanKind.CLIENT) as span:
span.set_attribute("llm.model", "gpt-4o")
# ... 调用 LLM
return response
```

**层级结构**：

![](附件资源/OpenTelemetry%20+%20Agent%20可观测平台基础/img_2.png)

### 4.3 异常处理

```
from opentelemetry.trace import Status, StatusCode

def call_llm_with_retry(prompt: str, max_retries: int = 3):
for attempt in range(max_retries):
with tracer.start_as_current_span("llm.call") as span:
span.set_attribute("retry.attempt", attempt + 1)

try:
result = actual_call(prompt)
span.set_status(Status(StatusCode.OK))
return result

except ConnectionError as e:
span.record_exception(e)
span.set_status(Status(StatusCode.ERROR, "timeout"))

if attempt == max_retries - 1:
raise

delay = 2 ** attempt
span.add_event("retry.scheduled", {"delay_ms": delay * 1000})
time.sleep(delay)
```

**关键原则**：

- • record_exception() ：记录异常详情（类型、消息、堆栈）
- • set_status(ERROR) ：标记 Span 结果，让可视化工具标红
- • 业务规则不满足（如 Prompt 太短）-> StatusCode.OK + business.result=validation_failed
- • 系统异常（网络超时）-> StatusCode.ERROR + record_exception()

## 五、自动插桩与扩展

### 5.1 为什么需要自动插桩

手动插桩的问题：

- • 代码侵入性强
- • 容易遗漏
- • 第三方库无法修改

### 5.2 启动自动插桩

```
from opentelemetry.instrumentation.openai import OpenAIInstrumentor
from opentelemetry.instrumentation.langchain import LangchainInstrumentor
from opentelemetry.instrumentation.httpx import HTTPXInstrumentor

OpenAIInstrumentor().instrument()
LangchainInstrumentor().instrument()
HTTPXInstrumentor().instrument()
```

**效果**：OpenAI 的  `chat.completions.create` 、LangChain 的  `AgentExecutor.run`  等方法自动产生 Span，无需修改业务代码。

### 5.3 自动插桩的扩展模式

当自动插桩覆盖不到时，有四种扩展模式：

#### 模式 1：Span Processor（全局增强）

```
class BusinessContextProcessor(SpanProcessor):
def on_start(self, span, parent_context):
span.set_attribute("deployment.environment", "production")

from opentelemetry.context import get_value
user_id = get_value("business.user_id", parent_context)
if user_id:
span.set_attribute("business.user_id", user_id)

provider.add_span_processor(BusinessContextProcessor())
```

#### 模式 2：Context 传递（请求级属性）

```
from opentelemetry.context import set_value, attach, detach

# 请求入口设置 Context
current = get_current()
current = set_value("business.user_id", user_id, current)
token = attach(current)

# 后续所有 Span 自动继承
```

#### 模式 3：包装器模式（增强特定调用）

```
def call_service_b(data: dict):
with tracer.start_as_current_span("agent.call_b") as span:
span.set_attribute("business.request_id", generate_uuid())

headers = {"Content-Type": "application/json"}
inject(headers)  # 注入 trace context

return requests.post(url, json=data, headers=headers)
```

#### 模式 4：自定义 Instrumentor（为无插桩库创建插桩）

```
from opentelemetry.instrumentation.instrumentor import BaseInstrumentor

class MyToolInstrumentor(BaseInstrumentor):
def _instrument(self, **kwargs):
# 替换原始方法为插桩版本
pass
```

### 5.4 Context 传播的关键机制

** `traceparent`  头的格式**：

![](附件资源/OpenTelemetry%20+%20Agent%20可观测平台基础/img_3.png)

**传播流程**：

```
# 服务A（调用方）
with tracer.start_as_current_span("call_b") as span:
headers = {}
inject(headers)  # 写入当前 span 的 traceparent
requests.post(url, headers=headers)

# 服务B（被调用方）
carrier = dict(request.headers)
context = extract(carrier)  # 提取 trace context

with tracer.start_as_current_span("handle", context=context) as span:
# 这个 Span 的 parent 是服务A 的 Span
pass
```

**关键原则**：

- • inject() 必须在 start_span 之后调用（读取当前 active span）
- • extract() 返回的是 Context，不是 Span
- • 每次调用下游都要新建 headers 并重新 inject() （不能复用）

## 六、Collector 部署与后端存储

### 6.1 为什么需要 Collector

| 场景 | 直接发送到后端 | 经过 Collector |
| --- | --- | --- |
| 换后端 | 改代码，重启应用 | 改 Collector 配置，应用无感知 |
| 数据脱敏 | 每个应用自己实现 | Collector 统一处理 |
| 采样控制 | 各自配置 | 统一配置 |
| 多后端同时发送 | 应用发多份 | Collector 一份变多份 |

### 6.2 Collector 配置

```
receivers:
otlp:
protocols:
grpc:
endpoint: 0.0.0.0:4317

processors:
batch:
timeout: 1s
send_batch_size: 1024
memory_limiter:
limit_mib: 512

exporters:
jaeger:
endpoint: jaeger:14250
tls:
insecure: true
logging:
verbosity: detailed

service:
pipelines:
traces:
receivers: [otlp]
processors: [memory_limiter, batch]
exporters: [jaeger, logging]
```

### 6.3 采样策略

| 策略 | 原理 | 适用场景 |
| --- | --- | --- |
| ** 头部采样 ** | 请求入口处决策，下游跟随 | 简单，减少发送量 |
| ** 尾部采样 ** | 等 Trace 完成后按内容决策 | 保留错误、慢请求 |
| ** 混合采样 ** | 头部降采样 + 尾部精细决策 | 生产推荐 |

```
processors:
tail_sampling:
decision_wait: 10s
policies:
- name: errors
type: status_code
status_code: {status_codes: [ERROR]}
- name: slow
type: latency
latency: {threshold_ms: 1000}
- name: probabilistic
type: probabilistic
probabilistic: {sampling_percentage: 10}
```

## 七、分布式环境的常见问题

### 7.1 时钟漂移

**现象**：子 Span 显示在父 Span 之前（不可能）。

**根因**：服务器 NTP 未同步，或虚拟机时钟跳变。

**解决方案**：

- • NTP/Chrony 同步（基础）
- • OTel SDK 用单调时钟计算 duration （准确）
- • 后端校正显示（Jaeger 强制调整 + 警告）

**关键原则**：只比较 Duration，不比较绝对时间戳。

### 7.2 高基数问题

**现象**： `user.id`  作为 Attribute 导致索引爆炸。

**根因**：Attribute 默认建倒排索引，1000 万用户 = 1000 万个索引项。

**解决方案**：

| 数据类型 | 存储位置 | 原因 |
| --- | --- | --- |
| 低基数（service, method, status） | Span Attribute | 可索引、可分组 |
| 高基数（user.id, request.id） | Span Event 或 Log | 避免索引膨胀 |

**查询流程**：

```
日志系统（Elasticsearch/Loki）
查询：user_id = "user_123"
返回：trace_id 列表 [T1, T2, T3]

Trace 系统（Jaeger）
查询：trace_id IN [T1, T2, T3]
返回：完整链路
```

### 7.3 高流量下的降级保护

```
# 应用端：队列和超时
processor = BatchSpanProcessor(
exporter,
max_queue_size=2048,
schedule_delay_millis=5000,
export_timeout_millis=3000,
)

# 动态采样降级
class AdaptiveSampler(Sampler):
def should_sample(self, ...):
cpu = psutil.cpu_percent()
if cpu > 90:
return TraceIdRatioBased(0.001)  # 0.1% 采样
elif cpu > 70:
return TraceIdRatioBased(0.01)   # 1% 采样
return TraceIdRatioBased(0.1)        # 10% 采样
```

## 八、Agent 专用语义与评估

### 8.1 扩展 OTel 约定

OTel GenAI 约定已覆盖基础属性（ `gen_ai.system` ,  `gen_ai.usage.*` ），但 Agent 场景需要扩展：

```
# Agent 状态
span.set_attribute("mycompany.agent.type", "reAct")
span.set_attribute("mycompany.agent.plan_steps", 3)
span.set_attribute("mycompany.agent.iterations", 2)

# 质量评估
span.set_attribute("mycompany.eval.hallucination_score", 0.05)
span.set_attribute("mycompany.eval.relevance_score", 0.92)

# 成本追踪
span.set_attribute("mycompany.cost.input_usd", 0.003)
span.set_attribute("mycompany.cost.total_usd", 0.015)
```

### 8.2 LLM-as-a-Judge 评估

```
class LLMJudge:
def evaluate_faithfulness(self, question, context, answer):
with tracer.start_as_current_span("eval.faithfulness") as span:
# 构建评估 Prompt
prompt = "Evaluate if the answer is faithful to the context."
prompt += "Context: " + context
prompt += "Question: " + question
prompt += "Answer: " + answer
prompt += "Return JSON with score(float) and reason(str)"

response = self.client.chat.completions.create(
model="gpt-4o",
messages=[{"role": "user", "content": prompt}],
temperature=0.0,
)

result = json.loads(response.choices[0].message.content)

span.set_attribute("eval.score", result["score"])
span.set_attribute("eval.reason", result["reason"])

return result
```

### 8.3 评估闭环

![](附件资源/OpenTelemetry%20+%20Agent%20可观测平台基础/img_4.png)

## 结语

自建 Agent 可观测平台不是一次性工程，而是持续迭代的过程：

- 1. 先跑通 ：手动插桩 + Console 输出
- 2. 再自动化 ：自动插桩 + Collector + Jaeger
- 3. 后精细化 ：自定义语义 + 评估系统 + 告警闭环
- 4. 最终目标 ：从"看到发生了什么"到"自动优化系统"

OpenTelemetry 提供了标准化的基础设施，而 Agent 特有的规划、工具调用、质量评估等语义，需要你在其基础上扩展。两者结合，才能构建真正面向 LLM Agent 的可观测平台。

---
原文链接：https://mp.weixin.qq.com/s?__biz=MzIzNTExNzMwNg%3D%3D&mid=2647834076&idx=1&sn=7a7c87ecf2e9a23e651dfab22490a24e&chksm=f12aaf817cbfab26071c49ec407152c24eed47cb9b029ab646d80e197a4b7c8d618117bdf064
