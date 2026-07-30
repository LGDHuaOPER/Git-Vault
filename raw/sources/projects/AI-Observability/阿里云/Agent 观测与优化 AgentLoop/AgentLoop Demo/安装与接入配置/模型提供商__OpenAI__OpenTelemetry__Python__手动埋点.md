### 1. 前提条件

- 支持的 Python 版本：Python 版本在 3.7 及以上。

### 2. 下载所需包

```bash
pip install opentelemetry-api
pip install opentelemetry-sdk
pip install opentelemetry-exporter-otlp
```

### 3. 创建 Python Demo 应用

- 创建 main.py 文件，添加如下内容：

```python
from opentelemetry import trace, baggage
from opentelemetry.exporter.otlp.proto.http.trace_exporter import OTLPSpanExporter as OTLPSpanHttpExporter
from opentelemetry.sdk.resources import DEPLOYMENT_ENVIRONMENT, HOST_NAME, Resource, SERVICE_NAME, SERVICE_VERSION
from opentelemetry.sdk.trace import TracerProvider
from opentelemetry.sdk.trace.export import BatchSpanProcessor

def inner_method():
    tracer = trace.get_tracer(__name__)
    with tracer.start_as_current_span("child_span") as child_span:
        print("hello world")

def outer_method():
    tracer = trace.get_tracer(__name__)
    with tracer.start_as_current_span("parent_span") as parent_span:
        inner_method()

# 初始化 OpenTelemetry
def init_opentelemetry():
    # 设置服务名、主机名
    resource = Resource(attributes={
        SERVICE_NAME: "",
        SERVICE_VERSION: "",
        DEPLOYMENT_ENVIRONMENT: "",
        HOST_NAME: "${hostName}", # 请将 ${hostName} 替换为主机名
        "acs.cms.workspace": "default-cms-1819385687343877-cn-hongkong"
    })
    
    headers = {
        "x-arms-license-key": "auto",
        "x-arms-project": "",
        "x-cms-workspace": "default-cms-1819385687343877-cn-hongkong"
    }
    
    # 使用HTTP协议上报
    span_processor = BatchSpanProcessor(OTLPSpanHttpExporter(
        endpoint="https:///apm/trace/opentelemetry/v1/traces",
        headers=headers
    ))
    
    trace_provider = TracerProvider(resource=resource, active_span_processor=span_processor)
    trace.set_tracer_provider(trace_provider)

if __name__ == '__main__':
    init_opentelemetry()
    outer_method()
```

### 4. 启动应用程序

- 使用以下命令启动应用

```bash
python main.py
```
