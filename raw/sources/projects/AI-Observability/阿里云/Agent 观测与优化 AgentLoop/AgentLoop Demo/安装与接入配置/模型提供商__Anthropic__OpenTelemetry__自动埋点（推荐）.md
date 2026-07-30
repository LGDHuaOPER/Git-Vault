OpenTelemetry Python Agent 提供了无侵入的接入方式，支持多种常用 Python 框架自动埋点，完整列表请参考 [OpenTelemetry 支持自动埋点的 Python 框架和版本列表](https://github.com/open-telemetry/opentelemetry-python-contrib/tree/main/instrumentation)。

下面将介绍如何使用 OpenTelemetry Python Agent 自动将应用的 Trace 数据上报至可观测链路 OpenTelemetry 版。

### 1. 前提条件

- 支持的 Python 版本：Python 版本在 3.7 及以上。

### 2. 下载所需包

```bash
pip install opentelemetry-distro opentelemetry-exporter-otlp

opentelemetry-bootstrap -a install
```

> 说明：opentelemetry-bootstrap -a install 命令会扫描当前 Python 环境的 site-packages 文件夹，如果有 OpenTelemetry 支持自动埋点的框架，会自动下载框架对应的 OpenTelemetry 插件。 例如已经安装过 django，那么该命令会自动下载 opentelemetry-instrumentation-django 这个包。

> 针对 Anthropic Claude Python SDK，OpenTelemetry 社区提供了对应的 instrumentation 包，可自动捕获 Claude Messages API 调用、流式响应以及 Token 用量，接入时可在上述 bootstrap 步骤后额外安装：

```bash
pip install opentelemetry-instrumentation-anthropic
```

包地址与支持范围请参考 OpenTelemetry Python Contrib 仓库 instrumentation 目录下的 opentelemetry-instrumentation-anthropic。

### 3. 启动应用程序

- 通过环境变量配置OpenTelemetry，并运行您的应用

```python
export OTEL_SERVICE_NAME=
export OTEL_EXPORTER_OTLP_PROTOCOL=http/protobuf
export OTEL_EXPORTER_OTLP_TRACES_ENDPOINT=https:///apm/trace/opentelemetry/v1/traces
export OTEL_EXPORTER_OTLP_METRICS_ENDPOINT=https:///apm/trace/opentelemetry/v1/metrics
export OTEL_EXPORTER_OTLP_HEADERS="x-arms-license-key=auto,x-arms-project=,x-cms-workspace=default-cms-1819385687343877-cn-hongkong"
export OTEL_RESOURCE_ATTRIBUTES=service.name=,acs.cms.workspace=default-cms-1819385687343877-cn-hongkong,service.version=,deployment.environment=
opentelemetry-instrument <your_run_command>
```

- 您需要将 <your_run_command> 替换为需要 Python 应用的启动命令，<your_run_command> 可以是
    - 普通应用：python app.py
    - Flask应用：flask run -p 8000
    - Django应用：python manage.py runserver --noreload
    - uWGSI应用：uwsgi --http :8000 --module app.wsgi
    - Gunicorn应用: gunicorn app:app --bind=127.0.0.1:8000 或 gunicorn app:app --workers 2 --worker-class uvicorn.workers.UvicornWorker --bind 127.0.0.1:8000 (多worker模式)
    - Uvicorn应用: uvicorn app:app --host localhost --port 8000

> 注：使用自动埋点时，请勿启用热更新配置，如--reload或者reload=True，否则将使OpenTelemetry自动埋点失效。 Django开发环境默认启用热加载，使用OpenTelemetry自动埋点需要显式指定--noreload参数。 OpenTelemetry自动埋点暂不支持Uvicorn应用多worker模式。
