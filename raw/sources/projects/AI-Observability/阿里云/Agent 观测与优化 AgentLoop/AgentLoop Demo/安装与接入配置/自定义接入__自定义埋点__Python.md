# Python：不接入探针，直接通过 OpenTelemetry SDK 上报

## 1. 适用场景与边界

- Python 版本建议为 3.10 及以上。
- 应用不接入 ARMS Python 探针，需要自行初始化 OpenTelemetry TracerProvider、Resource 和 OTLP Exporter。
- Agent、LLM 和 Tool Span 均由业务代码通过 loongsuite-otel-util-genai 手动创建。
- service.name、acs.cms.workspace、acs.arms.service.feature=genai_app 与 gen_ai.instrumentation.sdk.name=loongsuite-genai-utils 必须作为 Resource 属性上报。

## 2. 安装依赖

```bash
pip install -U opentelemetry-api opentelemetry-sdk opentelemetry-exporter-otlp "loongsuite-otel-util-genai>=0.6.1"
```

## 3. 配置内容采集策略

以下配置用于在 Span 中记录模型输入和输出。生产环境请根据隐私要求决定是否开启正文采集。

```bash
export OTEL_SEMCONV_STABILITY_OPT_IN=gen_ai_latest_experimental
export OTEL_INSTRUMENTATION_GENAI_CAPTURE_MESSAGE_CONTENT=SPAN_ONLY
```

## 4. 初始化 OpenTelemetry SDK 和 Exporter

```python
from opentelemetry import trace
from opentelemetry.exporter.otlp.proto.http.trace_exporter import OTLPSpanExporter
from opentelemetry.sdk.resources import Resource
from opentelemetry.sdk.trace import TracerProvider
from opentelemetry.sdk.trace.export import BatchSpanProcessor
from opentelemetry.util.genai.extended_handler import get_extended_telemetry_handler

resource = Resource.create({
    "service.name": "",
    "service.version": "v0.1.0",
    "deployment.environment": "production",
    "acs.cms.workspace": "default-cms-1819385687343877-cn-hongkong",
    "acs.arms.service.feature": "genai_app",
    "gen_ai.instrumentation.sdk.name": "loongsuite-genai-utils",
})
headers = {
    "x-arms-license-key": "hwx28v3j7p@672218fb660eec3",
    "x-arms-project": "proj-xtrace-ee483ec157740929c4cb92d4ff85f-cn-hongkong",
    "x-cms-workspace": "default-cms-1819385687343877-cn-hongkong",
}
exporter = OTLPSpanExporter(
    endpoint="https://proj-xtrace-ee483ec157740929c4cb92d4ff85f-cn-hongkong.cn-hongkong-intranet.log.aliyuncs.com/apm/trace/opentelemetry/v1/traces",
    headers=headers,
)
provider = TracerProvider(resource=resource)
provider.add_span_processor(BatchSpanProcessor(exporter))
trace.set_tracer_provider(provider)

handler = get_extended_telemetry_handler(tracer_provider=provider)
```

必须先初始化 Provider，再首次调用 get_extended_telemetry_handler()，避免单例 Handler 绑定到默认 NoOp Provider。

## 5. 手动创建 Agent、LLM 和 Tool Span

```python
import json

from opentelemetry.util.genai.extended_types import ExecuteToolInvocation, InvokeAgentInvocation
from opentelemetry.util.genai.types import Error, InputMessage, LLMInvocation, OutputMessage, Text


def run_agent(user_input: str) -> str:
    agent = InvokeAgentInvocation(
        provider="dashscope",
        agent_name="",
        agent_description="Custom AI application",
        request_model="qwen-plus",
    )
    handler.start_invoke_agent(agent)
    try:
        llm = LLMInvocation(
            provider="dashscope",
            request_model="qwen-plus",
            input_messages=[
                InputMessage(role="user", parts=[Text(content=user_input)]),
            ],
        )
        with handler.llm(llm) as invocation:
            # 替换为真实模型调用。
            answer = "需要查询订单状态"
            invocation.output_messages = [
                OutputMessage(
                    role="assistant",
                    parts=[Text(content=answer)],
                    finish_reason="tool_calls",
                ),
            ]
            invocation.input_tokens = 12
            invocation.output_tokens = 8

        tool = ExecuteToolInvocation(
            tool_name="lookup_order",
            tool_call_id="call-001",
            tool_call_arguments=json.dumps({"order_id": "123"}),
            tool_type="function",
        )
        handler.start_execute_tool(tool)
        tool.tool_call_result = json.dumps({"status": "paid"})
        handler.stop_execute_tool(tool)

        agent.input_tokens = 12
        agent.output_tokens = 8
        handler.stop_invoke_agent(agent)
        return answer
    except Exception as exc:
        handler.fail_invoke_agent(
            agent,
            Error(message=str(exc), type=type(exc)),
        )
        raise
```

## 6. 查看数据

直接运行应用，不需要 aliyun-instrument。进入云监控 2.0 控制台的 AI Agent 可观测，检查 Agent、LLM、Tool、Token 用量和调用链。应用退出前应确保 TracerProvider 完成 flush 或 shutdown。

## 7. 更多参考

- [Python LLM 应用自定义埋点最佳实践](https://help.aliyun.com/zh/cms/cloudmonitor-2-0/python-llm-application-best-practices-with-loongsuite-otel-util-genai-custom-instrumentation)
- [使用 OpenTelemetry GenAI Utils 进行 LLM 应用接入](https://help.aliyun.com/zh/cms/cloudmonitor-2-0/integrating-llm-applications-with-opentelemetry-genai-utils/)
