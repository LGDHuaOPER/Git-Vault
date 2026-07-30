# Go：不接入探针，直接通过 OpenTelemetry SDK 上报

## 1. 适用场景与边界

- Go 版本不低于 1.24。
- 应用不接入 ARMS Go 探针，需要自行初始化 OpenTelemetry TracerProvider、Resource 和 OTLP Exporter。
- Agent、LLM 和 Tool Span 均由业务代码通过 util-genai 手动创建。
- service.name、acs.cms.workspace、acs.arms.service.feature=genai_app 与 gen_ai.instrumentation.sdk.name=loongsuite-genai-utils 必须作为 Resource 属性上报。

## 2. 安装依赖

```bash
go get github.com/alibaba/loongsuite-go/util-genai@latest
go get go.opentelemetry.io/otel@v1.40.0
go get go.opentelemetry.io/otel/sdk@v1.40.0
go get go.opentelemetry.io/otel/exporters/otlp/otlptrace/otlptracehttp@v1.40.0
```

## 3. 配置内容采集策略

```bash
export OTEL_SEMCONV_STABILITY_OPT_IN=gen_ai_latest_experimental
export OTEL_INSTRUMENTATION_GENAI_CAPTURE_MESSAGE_CONTENT=SPAN_ONLY
```

## 4. 初始化 OpenTelemetry SDK 和 Exporter

```go
package main

import (
    "context"
    "go.opentelemetry.io/otel/attribute"
    "go.opentelemetry.io/otel/exporters/otlp/otlptrace/otlptracehttp"
    "go.opentelemetry.io/otel/sdk/resource"
    sdktrace "go.opentelemetry.io/otel/sdk/trace"
    semconv "go.opentelemetry.io/otel/semconv/v1.26.0"
)

func initTracer(ctx context.Context) (*sdktrace.TracerProvider, error) {
    headers := map[string]string{
        "x-arms-license-key": "hwx28v3j7p@672218fb660eec3",
        "x-arms-project":     "proj-xtrace-ee483ec157740929c4cb92d4ff85f-cn-hongkong",
        "x-cms-workspace":    "default-cms-1819385687343877-cn-hongkong",
    }

    exporter, err := otlptracehttp.New(
        ctx,
        otlptracehttp.WithEndpoint("proj-xtrace-ee483ec157740929c4cb92d4ff85f-cn-hongkong.cn-hongkong-intranet.log.aliyuncs.com"),
        otlptracehttp.WithURLPath("/apm/trace/opentelemetry/v1/traces"),
        otlptracehttp.WithHeaders(headers),
    )
    if err != nil {
        return nil, err
    }

    res := resource.NewWithAttributes(
        semconv.SchemaURL,
        semconv.ServiceNameKey.String(""),
        semconv.ServiceVersionKey.String("v0.1.0"),
        attribute.String("deployment.environment", "production"),
        attribute.String("acs.cms.workspace", "default-cms-1819385687343877-cn-hongkong"),
        attribute.String("acs.arms.service.feature", "genai_app"),
        attribute.String("gen_ai.instrumentation.sdk.name", "loongsuite-genai-utils"),
    )

    provider := sdktrace.NewTracerProvider(
        sdktrace.WithBatcher(exporter),
        sdktrace.WithResource(res),
    )
    return provider, nil
}
```

## 5. 手动创建 Agent、LLM 和 Tool Span

```go
package main

import (
    "context"
    "log"

    utilgenai "github.com/alibaba/loongsuite-go/util-genai"
)

func main() {
    ctx := context.Background()
    provider, err := initTracer(ctx)
    if err != nil {
        log.Fatal(err)
    }
    defer provider.Shutdown(ctx)

    handler := utilgenai.NewTelemetryHandler(
        utilgenai.WithTracerProvider(provider),
    )
    agent := utilgenai.NewInvokeAgentInvocation()
    agent.Provider = "dashscope"
    agent.AgentName = ""
    agent.AgentDescription = "Custom AI application"
    agent.Attributes[utilgenai.AttrGenAIRequestModel] = "qwen-plus"
    agent.InputMessages = []utilgenai.InputMessage{
        {
            Role: "user",
            Parts: []utilgenai.MessagePart{utilgenai.Text{Content: "查询订单 123 的支付状态"}},
        },
    }
    agentCtx := handler.StartInvokeAgent(ctx, agent)

    llm := utilgenai.NewLLMInvocation("qwen-plus")
    llm.Provider = "dashscope"
    llm.OperationName = utilgenai.OperationChat
    llm.InputMessages = []utilgenai.InputMessage{
        {
            Role: "user",
            Parts: []utilgenai.MessagePart{utilgenai.Text{Content: "查询订单 123 的支付状态"}},
        },
    }
    _ = handler.StartLLM(agentCtx, llm)
    llm.OutputMessages = []utilgenai.OutputMessage{
        {
            Role: "assistant",
            Parts: []utilgenai.MessagePart{utilgenai.Text{Content: "需要查询订单状态"}},
            FinishReason: utilgenai.FinishReasonStop,
        },
    }
    inputTokens, outputTokens := 12, 8
    llm.InputTokens = &inputTokens
    llm.OutputTokens = &outputTokens
    handler.StopLLM(llm)

    tool := utilgenai.NewExecuteToolInvocation("lookup_order")
    tool.ToolCallID = "call-001"
    tool.ToolType = "function"
    tool.Input = map[string]any{"order_id": "123"}
    _ = handler.StartExecuteTool(agentCtx, tool)
    tool.Output = map[string]any{"status": "paid"}
    handler.StopExecuteTool(tool)

    agent.OutputMessages = []utilgenai.OutputMessage{
        {
            Role: "assistant",
            Parts: []utilgenai.MessagePart{utilgenai.Text{Content: "订单已支付"}},
            FinishReason: utilgenai.FinishReasonStop,
        },
    }
    agent.Attributes[utilgenai.AttrGenAIUsageInputTokens] = inputTokens
    agent.Attributes[utilgenai.AttrGenAIUsageOutputTokens] = outputTokens
    handler.StopInvokeAgent(agent)
}
```

## 6. 查看数据

直接运行 Go 二进制，不要使用 instgo 编译。业务异常时应调用对应的 FailLLM、FailExecuteTool 或 FailInvokeAgent。所有 Start 方法返回的 Context 必须继续向下传递，以保持父子关系。

## 7. 更多参考

- [Go LLM 应用自定义埋点最佳实践](https://help.aliyun.com/zh/cms/cloudmonitor-2-0/go-llm-application-custom-burial-best-practices)
- [使用 OpenTelemetry GenAI Utils 进行 LLM 应用接入](https://help.aliyun.com/zh/cms/cloudmonitor-2-0/integrating-llm-applications-with-opentelemetry-genai-utils/)
