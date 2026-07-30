> Java 支持范围：ARMS 支持 OpenAI Java SDK 1.1.0+、2.X+、3.X+，以及 Spring AI 1.X+ 的 OpenAI ChatModel / ChatClient 调用观测。

当 OpenTelemetry 自动埋点不满足您的场景或者需要增加一些自定义业务埋点时，可以使用 OpenTelemetry SDK 手动构造 Trace 数据并上传到可观测链路 OpenTelemetry 版。此处以 Maven 方式为例，示例代码请参见 [OpenTelemetry Demo](https://github.com/alibabacloud-observability/java-demo/tree/main/opentelemetry-demo/otel-sdk-usage)。

### 1. 添加Maven依赖

```xml
<dependencies>
    <dependency>
        <groupId>io.opentelemetry</groupId>
        <artifactId>opentelemetry-api</artifactId>
    </dependency>
    <dependency>
        <groupId>io.opentelemetry</groupId>
        <artifactId>opentelemetry-sdk-trace</artifactId>
    </dependency>
    <dependency>
        <groupId>io.opentelemetry</groupId>
        <artifactId>opentelemetry-exporter-otlp</artifactId>
    </dependency>
    <dependency>
        <groupId>io.opentelemetry</groupId>
        <artifactId>opentelemetry-sdk</artifactId>
    </dependency>
    <dependency>
        <groupId>io.opentelemetry</groupId>
        <artifactId>opentelemetry-semconv</artifactId>
        <version>1.30.0-alpha</version>
    </dependency>
</dependencies>

<dependencyManagement>
<dependencies>
    <dependency>
        <groupId>io.opentelemetry</groupId>
        <artifactId>opentelemetry-bom</artifactId>
        <version>1.30.0</version>
        <type>pom</type>
        <scope>import</scope>
    </dependency>
</dependencies>
</dependencyManagement>
```

### 2. 添加 OpenTelemetry 初始化代码

```java
import io.opentelemetry.api.OpenTelemetry;
import io.opentelemetry.api.common.Attributes;
import io.opentelemetry.api.trace.Tracer;
import io.opentelemetry.api.trace.propagation.W3CTraceContextPropagator;
import io.opentelemetry.context.propagation.ContextPropagators;
import io.opentelemetry.exporter.otlp.http.trace.OtlpHttpSpanExporter;
import io.opentelemetry.sdk.OpenTelemetrySdk;
import io.opentelemetry.sdk.resources.Resource;
import io.opentelemetry.sdk.trace.SdkTracerProvider;
import io.opentelemetry.sdk.trace.export.BatchSpanProcessor;
import io.opentelemetry.semconv.resource.attributes.ResourceAttributes;

public class OpenTelemetrySupport {

    static {
        // 获取OpenTelemetry Tracer
        Resource resource = Resource.getDefault()
                .merge(Resource.create(Attributes.of(
                        ResourceAttributes.SERVICE_NAME, "",
                        ResourceAttributes.SERVICE_VERSION, "",
                        ResourceAttributes.DEPLOYMENT_ENVIRONMENT, "",
                        ResourceAttributes.HOST_NAME, "${host-name}", // 请将 ${host-name} 替换为您的主机名,
                        AttributeKey.stringKey("acs.cms.workspace"), "default-cms-1819385687343877-cn-hongkong"
                )));
        
        SdkTracerProvider sdkTracerProvider = SdkTracerProvider.builder()
                .addSpanProcessor(BatchSpanProcessor.builder(OtlpHttpSpanExporter.builder()
                        .setEndpoint("https:///apm/trace/opentelemetry/v1/traces")
                        .addHeader("x-arms-license-key", "auto")
                        .addHeader("x-arms-project", "")
                        .addHeader("x-cms-workspace", "default-cms-1819385687343877-cn-hongkong")
                        .build()).build())
                .setResource(resource)
                .build();
        
        OpenTelemetry openTelemetry = OpenTelemetrySdk.builder()
                .setTracerProvider(sdkTracerProvider)
                .setPropagators(ContextPropagators.create(W3CTraceContextPropagator.getInstance()))
                .buildAndRegisterGlobal();

        tracer = openTelemetry.getTracer("OpenTelemetry Tracer", "1.0.0");
    }

    private static Tracer tracer;

    public static Tracer getTracer() {
        return tracer;
    }
}
```

### 3. 创建 Span

```java
import io.opentelemetry.api.trace.Span;
import io.opentelemetry.api.trace.StatusCode;
import io.opentelemetry.context.Scope;

public class Main {
    
    public static void parentMethod() {
        Span span = OpenTelemetrySupport.getTracer().spanBuilder("parent span").startSpan();
        try (Scope scope = span.makeCurrent()) {
            span.setAttribute("good", "job");
            childMethod();
        } catch (Throwable t) {
            span.setStatus(StatusCode.ERROR, "handle parent span error");
        } finally {
            span.end();
        }
    }

    public static void childMethod() {
        Span span = OpenTelemetrySupport.getTracer().spanBuilder("child span").startSpan();
        try (Scope scope = span.makeCurrent()) {
            span.setAttribute("hello", "world");
        } catch (Throwable t) {
            span.setStatus(StatusCode.ERROR, "handle child span error");
        } finally {
            span.end();
        }
    }

    public static void main(String[] args) {
        parentMethod();
    }
}
```

### 4. 运行程序以生成并上报 Trace 数据
