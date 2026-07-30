### 使用方法

> 请先在上方点击**获取** LicenseKey，确认连接方式和应用名后，再复制以下命令到终端中执行。

macOS、Linux、WSL：

```bash
curl -fsSL https://arms-apm-cn-hangzhou-pre.oss-cn-hangzhou.aliyuncs.com/opentelemetry-instrumentation-openclaw/install.sh | bash -s -- \
  --x-arms-license-key "auto" \
  --x-arms-project "" \
  --x-cms-workspace "default-cms-1819385687343877-cn-hongkong" \
  --serviceName "openclaw" \
  --endpoint "https:///apm/trace/opentelemetry"
```

默认安装会启用全量数据原生 OpenTelemetry 上报。如仅需安装 Trace、不需要安装 Metrics，可在安装命令中追加 --disable-metrics 参数，跳过 diagnostics-otel 配置，仅启用 Trace 上报。

### 确认安装成功

执行命令后，若终端出现以下提示，即表示安装成功：

```
════════════════════════════════════════════════════
  ✅ opentelemetry-instrumentation-openclaw installed successfully!
════════════════════════════════════════════════════
```