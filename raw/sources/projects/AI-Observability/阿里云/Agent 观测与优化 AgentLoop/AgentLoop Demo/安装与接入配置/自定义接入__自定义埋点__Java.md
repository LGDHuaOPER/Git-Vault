# Java：不接入探针，直接通过 OpenTelemetry SDK 上报

## 1. 适用场景与边界

- JDK 8 及以上，使用 Maven 3.8 及以上或 Gradle 管理依赖。
- 应用不接入 ARMS Java 探针，需要自行初始化 OpenTelemetry SDK、Resource 和 OTLP Exporter。
- Agent、Chat 和 Tool Span 均由业务代码通过 otel-util-genai 手动创建。
- service.name、acs.cms.workspace、acs.arms.service.feature=genai_app 与 gen_ai.instrumentation.sdk.name=loongsuite-genai-utils 必须作为 Resource 属性上报。

## 2. 安装依赖

将版本占位符替换为 Maven Central 中 otel-util-genai 和 opentelemetry-bom 的最新稳定版本。

```xml
<dependencyManagement>
  <dependencies>
    <dependency>
      <groupId>io.opentelemetry</groupId>
      <artifactId>opentelemetry-bom</artifactId>
      <version>OPENTELEMETRY_VERSION</version>
      <type>pom</type>
      <scope>import</scope>
    </dependency>
  </dependencies>
</dependencyManagement>

<dependencies>
  <dependency>
    <groupId>com.alibaba.loongsuite</groupId>
    <artifactId>otel-util-genai</artifactId>
    <version>OTEL_UTIL_GENAI_VERSION</version>
  </dependency>
  <dependency>
    <groupId>io.opentelemetry</groupId>
    <artifactId>opentelemetry-sdk</artifactId>
  </dependency>
  <dependency>
    <groupId>io.opentelemetry</groupId>
    <artifactId>opentelemetry-exporter-otlp</artifactId>
  </dependency>
  <dependency>
    <groupId>io.opentelemetry</groupId>
    <artifactId>opentelemetry-sdk-extension-autoconfigure</artifactId>
  </dependency>
</dependencies>
```

## 3. 配置 Resource、OTLP 和内容采集

```bash
export OTEL_SERVICE_NAME=""
export OTEL_RESOURCE_ATTRIBUTES="service.version=v0.1.0,deployment.environment=production,acs.cms.workspace=default-cms-1819385687343877-cn-hongkong,acs.arms.service.feature=genai_app,gen_ai.instrumentation.sdk.name=loongsuite-genai-utils"
export OTEL_TRACES_EXPORTER=otlp
export OTEL_METRICS_EXPORTER=none
export OTEL_EXPORTER_OTLP_PROTOCOL=http/protobuf
export OTEL_EXPORTER_OTLP_TRACES_ENDPOINT="https://proj-xtrace-ee483ec157740929c4cb92d4ff85f-cn-hongkong.cn-hongkong-intranet.log.aliyuncs.com/apm/trace/opentelemetry/v1/traces"
export OTEL_EXPORTER_OTLP_HEADERS="x-arms-license-key=hwx28v3j7p@672218fb660eec3,x-arms-project=proj-xtrace-ee483ec157740929c4cb92d4ff85f-cn-hongkong,x-cms-workspace=default-cms-1819385687343877-cn-hongkong"
export OTEL_SEMCONV_STABILITY_OPT_IN=gen_ai_latest_experimental
export OTEL_INSTRUMENTATION_GENAI_CAPTURE_MESSAGE_CONTENT=span_and_event
```

## 4. 初始化 OpenTelemetry SDK

```java
import com.alibaba.loongsuite.otel.util.genai.GenAiTelemetryHandler;
import io.opentelemetry.api.OpenTelemetry;
import io.opentelemetry.sdk.autoconfigure.AutoConfiguredOpenTelemetrySdk;

OpenTelemetry openTelemetry =
    AutoConfiguredOpenTelemetrySdk.initialize().getOpenTelemetrySdk();
GenAiTelemetryHandler handler = GenAiTelemetryHandler.create(openTelemetry);
```

## 5. 手动创建 Agent、Chat 和 Tool Span

```java
import com.alibaba.loongsuite.otel.util.genai.AgentInvocation;
import com.alibaba.loongsuite.otel.util.genai.InferenceInvocation;
import com.alibaba.loongsuite.otel.util.genai.ToolInvocation;
import com.alibaba.loongsuite.otel.util.genai.types.InputMessage;
import com.alibaba.loongsuite.otel.util.genai.types.OutputMessage;
import com.alibaba.loongsuite.otel.util.genai.types.TextPart;
import java.util.Collections;

try (AgentInvocation agent =
         handler.invokeLocalAgent("dashscope", "qwen-plus", "")) {
  agent.setAgentDescription("Custom AI application");

  try (InferenceInvocation llm =
           handler.inference("dashscope", "qwen-plus", "dashscope.aliyuncs.com", 443, null)) {
    llm.setInputMessages(Collections.singletonList(
        new InputMessage(
            "user",
            Collections.singletonList(new TextPart("查询订单 123 的支付状态")))));

    // 替换为真实模型调用。
    String answer = "需要查询订单状态";
    llm.setOutputMessages(Collections.singletonList(
        new OutputMessage(
            "assistant",
            Collections.singletonList(new TextPart(answer)),
            "tool_calls")));
    llm.setInputTokens(12L);
    llm.setOutputTokens(8L);
  }

  try (ToolInvocation tool =
           handler.tool("lookup_order", "call-001", "function", "Query order status")) {
    tool.setArguments("{\"order_id\":\"123\"}");
    tool.setToolResult("{\"status\":\"paid\"}");
  }

  agent.setInputTokens(12L);
  agent.setOutputTokens(8L);
}
```

## 6. 查看数据

直接运行 Java 应用，不要添加 Java Agent。Java 的 try-with-resources 不会在异常时自动调用 fail，生产代码应在 catch 中显式标记失败，或使用 Handler 的 Run 回调。进入 AI Agent 可观测检查 Agent、Chat、Tool、Token 用量和调用链。

## 7. 更多参考

- [Java LLM 应用自定义埋点最佳实践](https://help.aliyun.com/zh/cms/cloudmonitor-2-0/best-practices-for-custom-instrumentation-in-java-llm-applications)
- [使用 OpenTelemetry GenAI Utils 进行 LLM 应用接入](https://help.aliyun.com/zh/cms/cloudmonitor-2-0/integrating-llm-applications-with-opentelemetry-genai-utils/)
