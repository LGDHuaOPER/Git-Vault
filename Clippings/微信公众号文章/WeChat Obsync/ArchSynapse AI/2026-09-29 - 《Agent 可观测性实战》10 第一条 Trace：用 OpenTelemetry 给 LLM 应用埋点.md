---
source_url: "https://mp.weixin.qq.com/s?__biz=MzAwMTYwNzE2Mg%3D%3D&mid=2651040438&idx=1&sn=602147c3aaaabe33037708500a96bfce&chksm=81201e23b657973583381a79203f8b47a6a8438a201b331cd88a2c55b9406255cfcb391c1d4e"
title: "《Agent 可观测性实战》10 | 第一条 Trace：用 OpenTelemetry 给 LLM 应用埋点"
account: "ArchSynapse AI"
published_at: "2026-09-29 21:00:00"
saved_at: "2026-10-21 22:17:06"
sync_id: "art_ee21b51039f741578c64976a0a447cc9"
parse_status: "ok"
---

# 《Agent 可观测性实战》10 | 第一条 Trace：用 OpenTelemetry 给 LLM 应用埋点

![](附件资源/《Agent%20可观测性实战》10%20第一条%20Trace：用%20OpenTelemetry%20给%20LLM%20应用埋点/img_1.png)

**ArchSynapse AI**

《Agent 可观测性实战》10

# 第一条 Trace：用 OpenTelemetry 给 LLM 应用埋点

**// **你好，这里是公众号：【ArchSynapse AI】。

原理篇讲了六讲，你现在"想明白了、也知道该记什么"。是时候打开编辑器了。

这一讲的目标很具体、也很克制：**让示例项目产出第一条真正能看的 Trace，并在本地把它可视化地"看见"。** 我们今天只做一次 LLM 调用的埋点——先把从代码到可视化的**整条管道打通**，跑出一个最小闭环。多步 Agent、多轮 Session 的全链路，是下一讲的事。一口吃不成胖子，但这一口必须先咽下去，因为后面所有实战以这个为基础。

### 本讲代码基线 ：Python 3.10+，  `opentelemetry-api`  /  `opentelemetry-sdk`  ~1.30、  `opentelemetry-exporter-otlp-proto-http`  、  `openai`  ~1.x、  `arize-phoenix`  +  `openinference-instrumentation-openai`  。安装时取最新稳定版即可——OTel 的 API/SDK 已稳定在 1.x，破坏性变化主要发生在 GenAI 语义约定那一层，代码结构本身很稳。 模型名同样会变 ：本讲示例用 DeepSeek 的  `deepseek-flash`  （2026 年 9 月起的推荐名）。老名字  `deepseek-chat`  已于 2026-07-24 下线，网上旧教程照抄会直接报错。 以你所用厂商的官方模型列表为准 ——这也是为什么后面第 25 讲算成本时，要按  `gen_ai.response.model`  （实际响应的模型）而非请求名来记账。

- ●   ●

| ** 01 ** | ** 先搞清楚三个零件：SDK、Exporter、后端 ** |
| --- | --- |

在写代码前，你得知道数据是怎么从你的程序"流"到你眼前的。回忆第 3 讲那张四层架构图，最下面两层在这一讲会变成三个具体的零件：

| ** 1 ** | ** SDK ** ：在你的代码里 ** 产生 ** Span（  `TracerProvider`  造出  `Tracer`  ，  `Tracer`  造出 Span）； |
| --- | --- |
| ** 2 ** | ** Exporter ** ：把 Span ** 发出去 ** ，走的是 OTLP 协议； |
| ** 3 ** | ** 后端 ** ： ** 收集 + 可视化 ** 。生产上是观测平台，本地开发我们用 ** Phoenix ** （一个开箱即用、专为 LLM 设计的开源工具）。 |

一句话：**SDK 产出 → Exporter 发送 → 后端展示。** 装好依赖，我们就动手。

- ●  ●  bash

```
pip install "opentelemetry-api""opentelemetry-sdk" \
"opentelemetry-exporter-otlp-proto-http" \
"openai""arize-phoenix""openinference-instrumentation-openai"
```

- ●   ●

| ** 02 ** | ** 手动埋点：第一条 Trace 的最小骨架 ** |
| --- | --- |

先用**手动**方式来一遍。手动虽然啰嗦，但它能让你看清每一颗螺丝——理解了手动，你才知道自动埋点在背后替你做了什么。

下面这段是**完整、可独立运行**的代码，你复制下来、填上自己的 API Key 就能跑（我用了 OpenAI 兼容接口，所以把  `base_url`  换成 DeepSeek / 通义 / Kimi 都行）：

- ●  ●  python

```
from opentelemetry import trace
from opentelemetry.trace import Status, StatusCode
from opentelemetry.sdk.trace import TracerProvider
from opentelemetry.sdk.trace.export import BatchSpanProcessor
from opentelemetry.exporter.otlp.proto.http.trace_exporter import OTLPSpanExporter
from openai import OpenAI

# ① 初始化：TracerProvider + OTLP Exporter（指向本地 Phoenix，见第三节）
provider = TracerProvider()
provider.add_span_processor(
    BatchSpanProcessor(OTLPSpanExporter(endpoint="http://localhost:6006/v1/traces"))
)
trace.set_tracer_provider(provider)
tracer = trace.get_tracer("ecom-customer-agent")

# ② 一个 OpenAI 兼容客户端（改 base_url / api_key 即可切换到国内模型）
client = OpenAI(base_url="https://api.deepseek.com", api_key="sk-***")

def chat(user_msg: str) -> str:
    model = "deepseek-flash"
# ③ 把这次 LLM 调用包成一个 Span，按 gen_ai.* 记录请求侧
#    Span 名用"{操作} {模型}"的低基数写法，也是第 6 讲讲的命名约定
with tracer.start_as_current_span(f"chat {model}") as span:
        span.set_attribute("gen_ai.operation.name", "chat")
        span.set_attribute("gen_ai.provider.name", "deepseek")
        span.set_attribute("gen_ai.request.model", model)
        span.set_attribute("gen_ai.request.temperature", 0.2)
try:
            resp = client.chat.completions.create(
                model=model, temperature=0.2,
                messages=[{"role": "user", "content": user_msg}],
            )
# ④ 记录响应侧：token 用量、结束原因、实际模型
#    注意：OpenAI SDK 里叫 prompt_tokens/completion_tokens，
#    我们按 gen_ai 约定映射成 input/output_tokens（第 6 讲那次"改名"）
            u = resp.usage
            span.set_attribute("gen_ai.usage.input_tokens", u.prompt_tokens)
            span.set_attribute("gen_ai.usage.output_tokens", u.completion_tokens)
            span.set_attribute("gen_ai.response.model", resp.model)
            span.set_attribute("gen_ai.response.finish_reasons",
                               [resp.choices[0].finish_reason])
return resp.choices[0].message.content
except Exception as e:
# ⑤ 失败也要如实标 ERROR（第 5 讲那根"状态"弦）
            span.set_status(Status(StatusCode.ERROR, str(e)))
            span.record_exception(e)
raise

if __name__ == "__main__":
print(chat("我的订单还能退款吗？"))
```

这段代码不长，但把前面几讲的东西都落地了，五个标号逐一对应：

|  | ** ① 初始化 ** ：  `TracerProvider`  是 Span 工厂，  `BatchSpanProcessor`  攒一批再发（比来一条发一条高效），  `OTLPSpanExporter`  就是那个走 OTLP 的 Exporter。 |
| --- | --- |
|  | ** ② 客户端 ** ：故意用兼容接口——一行  `base_url`  就能在国内外模型间切换，这也是你将来做模型选型对比的基础。 |
|  | ** ③ 开 Span + 记请求 ** ：  `start_as_current_span(f"chat {model}")`  开出第 4 讲说的那个 Span；Span 名遵循第 6 讲的低基数约定（  `{操作} {模型}`  ，别把用户输入拼进 Span 名，否则基数爆炸），属性严格按  `gen_ai.*`  命名。 |
|  | ** ④ 记响应 ** ：token、结束原因、实际模型。这里我特意留了个注释——OpenAI SDK 用的还是老名字  `prompt_tokens`  ，你要 ** 手动映射 ** 到标准的  `input_tokens`  。这就是第 6 讲"字段会改名"的活生生的例子。 |
|  | ** ⑤ 记失败 ** ：别只记成功。工具/模型报错时标上  `ERROR`  、挂上异常，第 2 讲那个"静默失败"才抓得住。 |

跑一下，控制台会打印出模型的回答。但真正的重点不在控制台——在下一节。

- ●   ●

| ** 03 ** | ** 把它"看见"：本地启动 Phoenix ** |
| --- | --- |

Span 发出去了，得有个地方接住并画成瀑布图。本地开发，Phoenix 是最省事的选择。另起一个终端：

- ●  ●  bash

```
python -m phoenix.server.main serve   # 启动后访问 http://localhost:6006
```

（上面代码里 Exporter 的  `endpoint`  正是指向它的  `6006`  端口。）

启动后跑一遍你的  `chat("我的订单还能退款吗？")` ，刷新 Phoenix 页面—— **你人生中给 Agent 埋下的第一条 Trace，就躺在那里了。** 点开它，你会看到一个名叫  `chat`  的 Span，展开能看到你记的所有  `gen_ai.*`  属性：用了哪个模型、烧了多少 token、耗时多久、结束原因是什么。

这就是第 4 讲那张"瀑布图"的真身。现在它只有一根横条（因为我们只埋了一次调用），但**管道已经通了**。下一讲往里加 Span，这根横条就会长成一棵枝繁叶茂的树。

- ●   ●

| ** 04 ** | ** 自动埋点：一行的诱惑 ** |
| --- | --- |

手动埋点你已经体会到了——啰嗦，而且埋点代码和业务代码混合在一起，但每颗螺丝都在你手里。现在看看**自动**的活法。

把第二节那一整套手动代码，换成下面这几行，同样能出 Trace，而且 Span 记得比你手写的还全：

- ●  ●  python

```
from phoenix.otel import register
from openinference.instrumentation.openai import OpenAIInstrumentor
from openai import OpenAI

# 沿用第三节那个已经在跑的 Phoenix server（register 默认就指向 localhost:6006）
provider = register()           # 一步配好 TracerProvider + 指向 Phoenix 的 Exporter
OpenAIInstrumentor().instrument(tracer_provider=provider)   # 关键：自动给 openai 埋点

# 之后你原样调用 openai，Span 会自动产生——一行埋点都不用写
client = OpenAI(base_url="https://api.deepseek.com", api_key="sk-***")
client.chat.completions.create(
    model="deepseek-flash",
    messages=[{"role": "user", "content": "我的订单还能退款吗？"}],
)
```

### 一个容易踩的坑 ：Phoenix 文档里常见的  `px.launch_app()`  是 进程内 拉起 Phoenix，主要给 Notebook 用。如果你把它写进  `.py`  脚本，脚本一跑完 Phoenix 就随进程消失，你打开浏览器只会看到连不上的 6006。所以在脚本里，请 沿用第三节那个独立启动的 server （如上），别用  `launch_app()`  ；真要用，就在脚本末尾加一句  `input("看完按回车退出")`  把进程挂住。

 `OpenAIInstrumentor().instrument()`  这一行，会**猴子补丁（monkey-patch）**掉 openai 库的调用入口，自动把每次请求包成符合 OpenInference 约定的 Span——模型、token、prompt/completion 全都替你记好了。这就是第 7 讲说的"开箱即用的自动埋点"。对 LangChain、LlamaIndex、CrewAI，也各有对应的  `Instrumentor` ，套路一模一样。

看到这，你可能会想：那还手写个啥？直接自动不香吗？

- ●   ●

| ** 05 ** | ** 手动 vs 自动：不是二选一，是"打底 + 补刀" ** |
| --- | --- |

香，但有它够不着的地方。这也正是本讲思考题的答案。

**自动埋点的盲区，是"你的业务语义"。** 它能自动记下"这是一次 openai 调用、花了 350 token"——因为这些是**框架层**的通用信息。但它**不可能知道**：

|  | 这次调用属于哪一通对话（  `session.id`  ）； |
| --- | --- |
|  | 是哪个用户、哪个功能触发的； |
|  | 这一步是不是那个 ⚠️ ** 高风险的退款写操作 ** ； |
|  | 你自定义的、框架看不见的中间步骤。 |

这些**只有你知道**的业务语义，自动埋点一概抓不到。所以生产上的正解不是二选一，而是**分层叠加**：

自动埋点打底（省去 LLM/工具调用的样板），手动埋点补刀（补上 session、用户、业务标签、高风险标记、自定义 Span）。

具体怎么补？**自己开一个父 Span，把自动埋点的调用包在里面**，业务属性挂在这个父 Span 上：

- ●  ●  python

```
from opentelemetry import trace

tracer = trace.get_tracer("ecom-customer-agent")

# 自己开一个"本轮对话"的父 Span，业务语义挂在它身上
with tracer.start_as_current_span("handle_user_turn") as span:
    span.set_attribute("session.id", "S-1024")        # 多轮归因的钥匙
    span.set_attribute("app.user_id", "u_88671")
    span.set_attribute("app.is_high_risk", True)      # 退款等写操作

# 自动埋点产生的 LLM Span，会自动成为上面这个父 Span 的子 Span
    client.chat.completions.create(
        model="deepseek-flash",
        messages=[{"role": "user", "content": "我的订单还能退款吗？"}],
    )
```

**这里有个坑，我必须提醒你**：别图省事写成  `trace.get_current_span().set_attribute(...)`  然后放在调用之外——因为自动埋点的那个 Span 是在  `create()`  **内部**开、调用一结束就关的，你在它外面拿  `get_current_span()` ，拿到的是一个"非记录"的空 Span。 `set_attribute`  **不会报错，但属性会被静默丢掉**，你会在 Phoenix 里死活找不到  `session.id` ，还以为是平台的问题。所以务必像上面这样，**自己开一个真实的父 Span** 来承载业务属性。

顺便说，这个"手动父 Span + 自动子 Span"的结构，就是下一讲那棵全链路树的雏形了。

**自动负责"通用的、重复的"，手动负责"业务的、关键的"**——这套组合拳，才是既省力又不丢信息的实战姿势。

- ●   ●

| ** ✓ ** | ** 小结 ** |
| --- | --- |

第一条 Trace 落地了，你已经打通了从代码到可视化的整条管道：

| ** 1 ** | ** 三个零件 ** ：SDK 产出 Span → OTLP Exporter 发送 → 后端（本地用 Phoenix）展示。 |
| --- | --- |
| ** 2 ** | ** 手动埋点最小骨架 ** ：  `start_as_current_span`  开 Span，按  `gen_ai.*`  记请求/响应/token/状态；注意  `prompt_tokens → input_tokens`  这类要你手动对齐的"改名"。 |
| ** 3 ** | ** 自动埋点一行接入 ** ：  `Instrumentor().instrument()`  猴子补丁，省掉样板。 |
| ** 4 ** | ** 手动 vs 自动 = 打底 + 补刀 ** ：自动埋通用信息，手动补业务语义（session、用户、高风险标记）——这也是"自动埋点会漏什么"的答案： ** 它漏掉的，正是只有你才知道的那部分。 ** |

下一讲，我们把这根"单条横条"养成一棵**全链路的树**：给多步 Agent 的"规划—工具—观察—再规划"循环建起父子 Span，把多轮对话正确收敛进一个 Session，还要把那个"记忆/上下文"也变得可观测。

| ** ? ** | ** 思考题 ** |
| --- | --- |

| ** 1 ** | 正文讲了自动埋点会 ** 漏 ** 什么，现在请你反过来看一眼：把第四节的自动埋点跑起来，去 Phoenix 里逐个字段翻它记下的 Span，再和你第二节手写的那个 Span 对比—— ** 它记了哪些你自己动手时压根没想到要记的东西？ ** 找出两三个，想想它们在什么场景下能救你一命。（这正是"自动打底"真正的价值：它比你以为的更全。） |
| --- | --- |
| ** 2 ** | 动手挑战：把第二节的手动骨架，改造成能同时把  `session.id`  记进 Span。如果同一个用户连问三句，你希望在 Phoenix 里怎么把这三条 Trace 关联起来看？（这正是下一讲要系统解决的问题，先自己试试。） |

| ** ≡ ** | ** 本讲延伸阅读 ** |
| --- | --- |

|  | OpenTelemetry Python 官方文档： _ Instrumenting your application _ （手动埋点入门） |
| --- | --- |
|  | Arize Phoenix 文档： _ Quickstart: Tracing _ （本地跑通与 OpenInference 自动埋点） |
|  | OpenLLMetry（Traceloop）快速开始：另一套"一行接入"的自动埋点方案 |

**ArchSynapse AI**

看得见的 Agent，才是可信的 Agent

---
原文链接：https://mp.weixin.qq.com/s?__biz=MzAwMTYwNzE2Mg%3D%3D&mid=2651040438&idx=1&sn=602147c3aaaabe33037708500a96bfce&chksm=81201e23b657973583381a79203f8b47a6a8438a201b331cd88a2c55b9406255cfcb391c1d4e
