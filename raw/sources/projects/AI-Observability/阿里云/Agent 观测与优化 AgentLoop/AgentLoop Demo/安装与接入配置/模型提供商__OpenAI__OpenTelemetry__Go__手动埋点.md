> Go 支持范围：ARMS 支持 openai-go v1.5.0+ 和 go-openai v1.30.0+。

### 1. 设置依赖库

- go mod 中添加如下依赖

```
require (
	go.opentelemetry.io/otel v1.20.0
	go.opentelemetry.io/otel/exporters/otlp/otlptrace v1.20.0
	go.opentelemetry.io/otel/exporters/otlp/otlptrace/otlptracegrpc v1.20.0
	go.opentelemetry.io/otel/exporters/otlp/otlptrace/otlptracehttp v1.20.0
	go.opentelemetry.io/otel/sdk v1.20.0
)
```

### 2. 创建 OpenTelemetry 初始化工具代码

- 新建 opentelemetry_util.go 文件，并添加如下代码

```go
package otel_util

import (
	"context"
	"go.opentelemetry.io/otel"
	"go.opentelemetry.io/otel/exporters/otlp/otlptrace"
    "go.opentelemetry.io/otel/exporters/otlp/otlptrace/otlptracehttp"
	"go.opentelemetry.io/otel/propagation"
	"go.opentelemetry.io/otel/sdk/resource"
	sdktrace "go.opentelemetry.io/otel/sdk/trace"
	semconv "go.opentelemetry.io/otel/semconv/v1.15.0"
	"google.golang.org/grpc"
	"google.golang.org/grpc/encoding/gzip"
	"log"
	"os"
	"time"
)

const (
	SERVICE_NAME       = ""
	SERVICE_VERSION    = ""
	DEPLOY_ENVIRONMENT = ""
	HTTP_ENDPOINT      = ""
	HTTP_URL_PATH      = "apm/trace/opentelemetry/v1/traces"
)

// 设置应用资源
func newResource(ctx context.Context) *resource.Resource {
	hostName, _ := os.Hostname()

	r, err := resource.New(
		ctx,
		resource.WithFromEnv(),
		resource.WithProcess(),
		resource.WithTelemetrySDK(),
		resource.WithHost(),
		resource.WithAttributes(
			semconv.ServiceNameKey.String(SERVICE_NAME), // 应用名
			semconv.ServiceVersionKey.String(SERVICE_VERSION), // 应用版本
			semconv.DeploymentEnvironmentKey.String(DEPLOY_ENVIRONMENT), // 部署环境
			semconv.HostNameKey.String(hostName), // 主机名
			attribute.String("acs.cms.workspace", WORK_SPACE), // Workspace名称
		),
	)

	if err != nil {
		log.Fatalf("%s: %v", "Failed to create OpenTelemetry resource", err)
	}
	return r
}

func newHTTPExporterAndSpanProcessor(ctx context.Context) (*otlptrace.Exporter, sdktrace.SpanProcessor) {
	headers := map[string]string{
	    "x-arms-license-key": "auto",
	    "x-arms-project": "",
	    "x-cms-workspace": "default-cms-1819385687343877-cn-hongkong",
	}
	
	traceExporter, err := otlptrace.New(ctx, otlptracehttp.NewClient(
		otlptracehttp.WithEndpoint(HTTP_ENDPOINT),
		otlptracehttp.WithURLPath(HTTP_URL_PATH),
		otlptracehttp.WithHeaders(headers),
		otlptracehttp.WithCompression(1)))
	
	if err != nil {
		log.Fatalf("%s: %v", "Failed to create the OpenTelemetry trace exporter", err)
	}

	batchSpanProcessor := sdktrace.NewBatchSpanProcessor(traceExporter)

	return traceExporter, batchSpanProcessor
}

// InitOpenTelemetry OpenTelemetry 初始化方法
func InitOpenTelemetry() func() {
	ctx := context.Background()

	var traceExporter *otlptrace.Exporter
	var batchSpanProcessor sdktrace.SpanProcessor

	traceExporter, batchSpanProcessor = newHTTPExporterAndSpanProcessor(ctx)

	otelResource := newResource(ctx)

	traceProvider := sdktrace.NewTracerProvider(
		sdktrace.WithSampler(sdktrace.AlwaysSample()),
		sdktrace.WithResource(otelResource),
		sdktrace.WithSpanProcessor(batchSpanProcessor))

	otel.SetTracerProvider(traceProvider)
	otel.SetTextMapPropagator(propagation.NewCompositeTextMapPropagator(propagation.TraceContext{}, propagation.Baggage{}))

	return func() {
		cxt, cancel := context.WithTimeout(ctx, time.Second)
		defer cancel()
		if err := traceExporter.Shutdown(cxt); err != nil {
			otel.Handle(err)
		}
	}
}

```

### 3. 创建 Span

- 新建 main.go 文件，并添加如下代码。以下代码包含三个方法(除去main方法)，每个方法均创建了一个 Span。

```go
package main

import (
	"context"
	"fmt"
	"go.opentelemetry.io/otel"
	"go.opentelemetry.io/otel/attribute"
	"go.opentelemetry.io/otel/codes"
	otel_util "otel_go_demo/util"
	"time"
)

func main() {
	shutdown := otel_util.InitOpenTelemetry()
	defer shutdown()

	for i:= 0; i < 10; i++ {
		ctx := context.Background()
		parentMethod(ctx)
	}
	time.Sleep(10 * time.Second)
}

func parentMethod(ctx context.Context) {
	tracer := otel.Tracer("otel-go-tracer")
	ctx, span := tracer.Start(ctx, "parent span")
	fmt.Println(span.SpanContext().TraceID()) // 打印 TraceId
	span.SetAttributes(attribute.String("key", "value"))
	span.SetStatus(codes.Ok, "Success")
	childMethod(ctx)
	span.End()
}

func childMethod(ctx context.Context) {
	tracer := otel.Tracer("otel-go-tracer")
	ctx, span := tracer.Start(ctx, "child span")
	span.SetStatus(codes.Ok, "Success")
	grandChildMethod(ctx)
	span.End()
}

func grandChildMethod(ctx context.Context) {
	tracer := otel.Tracer("otel-go-tracer")
	ctx, span := tracer.Start(ctx, "grandchild span")
	span.SetStatus(codes.Error, "error")

	// 业务代码...

	span.End()
}
```

### 4. 运行程序以生成并上报 Trace 数据

- 通过以下命令运行程序：

```bash
go run main.go
```
