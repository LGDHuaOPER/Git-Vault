> Java 支持范围：ARMS 支持 OpenAI Java SDK 1.1.0+、2.X+、3.X+，以及 Spring AI 1.X+ 的 OpenAI ChatModel / ChatClient 调用观测。

### 1. 下载 OpenTelemetry Java Agent

- 下载链接：[OpenTelemetry Java Agent](https://github.com/open-telemetry/opentelemetry-java-instrumentation/releases/latest/download/opentelemetry-javaagent.jar)。

### 2. 集成 Java Agent

> 如需验证 AI 调用观测，请使用 OpenAI Java SDK 1.1+、2.X+、3.X+ 或 Spring AI 1.X+ 的 OpenAI ChatModel / ChatClient 示例应用产生一次模型调用。OpenTelemetry Java Agent 对 OpenAI Java SDK 的支持范围请参见 [OpenTelemetry Java Agent Supported Libraries](https://opentelemetry.io/docs/zero-code/java/agent/supported-libraries/)。

- 下述代码将直接运行您的 OpenAI Java SDK 或 Spring AI OpenAI 应用并加载 OpenTelemetry Java Agent，您需要将其中 /path/to/opentelemetry-javaagent.jar 替换为已下载的 Java Agent 本地路径，将 /path/to/your/app.jar 替换为您的应用 Jar 包路径。

```bash
java -javaagent:/path/to/opentelemetry-javaagent.jar \
-Dotel.resource.attributes=service.name=,acs.cms.workspace=default-cms-1819385687343877-cn-hongkong,service.version=,deployment.environment= \
-Dotel.exporter.otlp.protocol=http/protobuf \
-Dotel.exporter.otlp.traces.endpoint=https:///apm/trace/opentelemetry/v1/traces \
-Dotel.exporter.otlp.metrics.endpoint=https:///apm/trace/opentelemetry/v1/metrics \
-Dotel.exporter.otlp.headers="x-arms-license-key=auto,x-arms-project=,x-cms-workspace=default-cms-1819385687343877-cn-hongkong" \
-Dotel.logs.exporter=none \
-jar /path/to/your/app.jar
```

- 产生测试数据：请访问您的服务或示例应用，触发一次 OpenAI Java SDK 或 Spring AI OpenAI 调用。
