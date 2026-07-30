> Go 支持范围：ARMS 支持 openai-go v1.5.0+ 和 go-openai v1.30.0+。

### 1. 下载最新版本的Golang Agent

- 下载链接：[OpenTelemetry Release 列表](https://github.com/alibaba/opentelemetry-go-auto-instrumentation/releases)。 并将对应架构的二进制包重命名为otel。

### 2. 使用Golang Agent二进制编译

参考[文档](https://github.com/alibaba/opentelemetry-go-auto-instrumentation/blob/main/README.md)，通过在go build指令之前添加编译前缀进行混合编译，比如：

```
otel go build -o app cmd/app
```

### 3. 启动应用

下述代码将直接运行您的应用并加载 OpenTelemetry Golang Agent，您需要将/path/to/your/app 替换为您在第二步中使用Golang Agent编译出的二进制文件的实际路径。

```bash
export OTEL_LOGS_EXPORTER=none
export OTEL_RESOURCE_ATTRIBUTES=service.name=,service.version=,deployment.environment=
export OTEL_EXPORTER_OTLP_HEADERS="x-arms-license-key=auto,x-arms-project=,x-cms-workspace=default-cms-1819385687343877-cn-hongkong"
export OTEL_EXPORTER_OTLP_TRACES_ENDPOINT=https:///apm/trace/opentelemetry/v1/traces
export OTEL_EXPORTER_OTLP_METRICS_ENDPOINT=https:///apm/trace/opentelemetry/v1/metrics

/path/to/your/app
```