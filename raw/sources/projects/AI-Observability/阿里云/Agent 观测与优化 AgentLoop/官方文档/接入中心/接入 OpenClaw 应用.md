---
title: "接入 OpenClaw 应用"
source: "https://help.aliyun.com/zh/document_detail/3042581.html?spm=a2c4g.11186623.help-menu-3033820.d_2_6.6f51972e4BUo9N"
author:
  - "阿里云计算"
published:
created: 2026-07-23
description: "AgentLoop 是阿里云推出的面向企业级智能体的一站式自进化平台，提供 Agent全栈观测与审计、Agent评估与实验、Agent资产管理与持续优化等核心能力，助力企业构建智能体进化数据飞轮，持续提升企业 Agent的质量、效率、成本与安全性。面向企业真实生产环境 Agent应用提供 Agent-as-a-Judge、Agent Playground、Trace2Dataset等 Agent应用范式的场景化闭环能力，让 Agent在生产环境中形成可观测、可评估、可优化的持续进化飞轮。"
tags:
  - "Clippings"
  - "AI可观测"
  - "阿里云"
  - "阿里云/AgentLoop"
  - "官方文档"
"word-count": "3162"
更新时间: "2026-06-25 11:29:52"
---
OpenClaw 可通过 `opentelemetry-instrumentation-openclaw` 和 `diagnostics-otel` 两个插件协同工作，将 AI Agent 的完整调用链路（Trace）和运行指标（Metrics）上报至云监控 2.0 应用监控。`opentelemetry-instrumentation-openclaw` 负责 Trace 上报，遵循 OpenTelemetry GenAI 语义规范，为每一次请求生成结构化的调用链路；`diagnostics-otel` 负责 Metrics 上报，实时采集 Token 消耗速率、调用 QPS、队列深度等运行指标。启用后，您可以在云监控 2.0 中查看 OpenClaw 的完整调用链路、模型调用耗时、Token 消耗明细、工具调用详情等监控数据。

## 使用限制

| **限制项** | **说明** |
| --- | --- |
| OpenClaw 版本 | v26.2.19 及以上。低于此版本不包含 `diagnostics-otel` 插件，请先升级。 |
| 上报协议 | 仅支持 HTTP/Protobuf，暂不支持 HTTP/JSON 和 gRPC。 |
| 数据类型 | 当前仅支持接收 Trace 和 Metric 数据，暂不支持 Log 数据。 |
| 云监控服务 | 已开通云监控 2.0 服务，并创建了工作空间。 |

## 步骤一：获取接入命令

在安装插件之前，您需要先从云监控 2.0 控制台获取接入命令。

1.  登录[云监控 2.0 控制台](https://cmsnext.console.aliyun.com/)，选择目标工作空间。
    
2.  在左侧导航栏单击**接入中心**。
    
3.  在**AI 应用可观测**区域单击 **OpenClaw** 卡片。
    
4.  在参数配置区域输入应用名，根据需求选择连接方式，然后单击 LicenseKey 右侧的**点击获取**。
    
    页面下方将根据配置参数生成相应的接入命令，单击右上角可一键复制。命令中包含 Endpoint、LicenseKey 等接入点信息，如需手动安装请记录：
    
    | **参数** | **说明** | **示例** |
    | Endpoint | OTLP Trace/Metric 数据上报地址 | - `https://proj-xtrace-xxx.cn-hangzhou-intranet.log.aliyuncs.com/apm/trace/opentelemetry/v1/traces` - `https://proj-xtrace-xxx.cn-hangzhou-intranet.log.aliyuncs.com/apm/trace/opentelemetry/v1/metrics` |
    | x-arms-license-key | 数据写入鉴权的 LicenseKey | `d95vgxi0cn@xxxxx` |
    | x-arms-project | 日志服务项目名称 | `proj-xtrace-xxx-cn-hangzhou` |
    | x-cms-workspace | 云监控 2.0 工作空间标识 | `default-cms-xxx-cn-hangzhou` |
    | serviceName | 应用名 | openclaw-xxx |
    

## 步骤二：安装接入

### 方式一：**一键安装（推荐）**

打开 OpenClaw 所在机器的终端，粘贴上一步复制的安装命令然后执行：

```
curl -fsSL https://arms-apm-cn-hangzhou-pre.oss-cn-hangzhou.aliyuncs.com/opentelemetry-instrumentation-openclaw/install.sh | bash -s -- \
  --endpoint "https://你的Endpoint地址" \
  --x-arms-license-key "你的License-Key" \
  --x-arms-project "你的Project" \
  --x-cms-workspace "你的Workspace" \
  --serviceName "你的服务名"
```

安装脚本将自动完成以下操作：

1.  检查环境（Node.js、npm、OpenClaw CLI）。
    
2.  下载并解压 `opentelemetry-instrumentation-openclaw` 到 OpenClaw 扩展目录。
    
3.  安装插件的运行时依赖。
    
4.  自动定位 `diagnostics-otel` 扩展，如果未安装依赖会自动安装。
    
5.  更新 `openclaw.json` 配置（两个插件的配置一次写完；OpenClaw版本 >= 2026.4.25 时自动写入 `hooks.allowConversationAccess: true`）。
    
6.  重启网关使配置生效。
    

预期输出类似如下内容：

```
[INFO]  Checking prerequisites...
[OK]    Node.js v24.14.0
[OK]    npm 11.9.0
[OK]    OpenClaw CLI found
[INFO]  Downloading plugin...
[OK]    Downloaded
[INFO]  Extracting...
[OK]    Extracted
[INFO]  Installing npm dependencies...
[OK]    Dependencies installed
[INFO]  Locating diagnostics-otel extension...
[OK]    Found diagnostics-otel at: /home/.../extensions/diagnostics-otel
[OK]    diagnostics-otel dependencies already present
[INFO]  Updating config...
[OK]    Config updated
[INFO]  Restarting OpenClaw gateway...
[OK]    Gateway restarted
════════════════════════════════════════════════════
  ✅ opentelemetry-instrumentation-openclaw installed successfully!
════════════════════════════════════════════════════
```

#### **安装参数**

| 参数  | 必填  | 说明  |
| --- | --- | --- |
| `--endpoint` | 是   | OTLP 数据上报地址，从云监控 2.0 接入中心获取 |
| `--x-arms-license-key` | 是   | 数据写入鉴权的 LicenseKey |
| `--x-arms-project` | 是   | 日志服务项目名称 |
| `--x-cms-workspace` | 是   | 云监控 2.0 工作空间标识 |
| `--serviceName` | 是   | 上报的服务名称，将作为应用名显示在云监控 2.0 的应用列表中 |
| `--plugin-url` | 否   | 自定义 tarball 下载地址 |
| `--install-dir` | 否   | 自定义安装目录 |
| `--disable-metrics` | 否   | 跳过 diagnostics-otel 配置，仅启用 Trace 上报，不启用 Metrics |

### 方式二：手动安装

如需手动安装，请按照以下步骤操作。

#### 1\. 下载并解压插件

```
curl -fsSL -o opentelemetry-instrumentation-openclaw.tar.gz https://arms-apm-cn-hangzhou-pre.oss-cn-hangzhou.aliyuncs.com/opentelemetry-instrumentation-openclaw/opentelemetry-instrumentation-openclaw.tar.gz
tar -xzf opentelemetry-instrumentation-openclaw.tar.gz
cd opentelemetry-instrumentation-openclaw
npm install --omit=dev
```

#### 2\. 启用 diagnostics-otel 插件

```
openclaw plugins enable diagnostics-otel
```

#### 3\. 编辑配置文件

编辑 `~/.openclaw/openclaw.json`，写入以下配置（将[步骤一](#60fc81a8bdp6n)接入点信息替换到以下配置中）：

```
{
  "plugins": {
    "allow": ["opentelemetry-instrumentation-openclaw", "diagnostics-otel"],
    "load": {
      "paths": ["<opentelemetry-instrumentation-openclaw 的安装路径>"]
    },
    "entries": {
      "opentelemetry-instrumentation-openclaw": {
        "enabled": true,
        "hooks": {
          "allowConversationAccess": true
        },
        "config": {
          "endpoint": "<Endpoint>",
          "headers": {
            "x-arms-license-key": "<YOUR-LICENSE-KEY>",
            "x-arms-project": "<YOUR-ARMS-PROJECT>",
            "x-cms-workspace": "<YOUR-WORKSPACE-ID>"
          },
          "serviceName": "<YOUR-SERVICE-NAME>"
        }
      },
      "diagnostics-otel": {
        "enabled": true
      }
    }
  },
  "diagnostics": {
    "enabled": true,
    "otel": {
      "enabled": true,
      "endpoint": "<Endpoint>",
      "protocol": "http/protobuf",
      "headers": {
        "x-arms-license-key": "<YOUR-LICENSE-KEY>",
        "x-arms-project": "<YOUR-ARMS-PROJECT>",
        "x-cms-workspace": "<YOUR-WORKSPACE-ID>"
      },
      "serviceName": "<YOUR-SERVICE-NAME>",
      "traces": false,
      "metrics": true,
      "logs": false
    }
  }
}
```

> **版本兼容**：`hooks.allowConversationAccess` 仅 OpenClaw版本 >= 2026.4.25 支持。低于此版本请删除 `hooks` 段，否则网关启动会报 "Unrecognized key" 错误。

#### 4\. 重启网关

```
openclaw gateway restart
```

### 方式三：容器环境下接入

请你首先选择[OpenClaw基础镜像](https://github.com/openclaw/openclaw/pkgs/container/openclaw/versions?filters%5Bversion_type%5D=tagged)（如果您已经基于官方的基础镜像构建了自己的基础镜像，可以直接使用您自己构建的OpenClaw基础镜像），之后在基础镜像的基础上，安装OpenClaw可观测相关插件，之后重新构建您自己的OpenClaw镜像，如下所示：

```
FROM ghcr.io/openclaw/openclaw:latest
RUN curl -fsSL https://arms-apm-cn-hangzhou-pre.oss-cn-hangzhou.aliyuncs.com/opentelemetry-instrumentation-openclaw/install.sh | bash -s -- \
  --endpoint "https://你的Endpoint地址" \
  --x-arms-license-key "你的License-Key" \
  --x-arms-project "你的Project" \
  --x-cms-workspace "你的Workspace" \
  --serviceName "你的服务名"
```

安装脚本与方式一种一键安装的脚本一致。

之后基于此Dockerfile构建您自己的OpenClaw镜像，并用这个镜像来作为容器环境下的运行镜像。

如果您需要可以动态配置OpenClaw实例的上报端点，上报应用名等信息，可以按照如下方式构建OpenClaw镜像：

```
FROM ghcr.io/openclaw/openclaw:latest
RUN curl -fsSL https://arms-apm-cn-hangzhou-pre.oss-cn-hangzhou.aliyuncs.com/opentelemetry-instrumentation-openclaw/install-ack.sh | bash -s
```

之后在运行镜像时，配置如下环境变量以指定上报端点，应用名等信息：

| **环境变量名** | **描述** |
| --- | --- |
| `ARMS_OTLP_ENDPOINT` | 你的Endpoint地址 |
| `ARMS_LICENSE_KEY` | 你的License-Key |
| `ARMS_PROJECT` | 你的Project |
| `ARMS_CMS_WORKSPACE` | 你的Workspace |
| `ARMS_SERVICE_NAME` | 你的服务名 |

### 配置参数说明

#### opentelemetry-instrumentation-openclaw 配置

| **参数** | **类型** | **必填** | **说明** |
| --- | --- | --- | --- |
| `endpoint` | String | 是   | OTLP 数据上报地址，从云监控 2.0 接入中心获取。 |
| `headers.x-arms-license-key` | String | 是   | 数据写入鉴权的 LicenseKey，用于身份认证。 |
| `headers.x-arms-project` | String | 是   | 项目标识，指链路数据归属的日志服务项目名称。 |
| `headers.x-cms-workspace` | String | 是   | 云监控 2.0 工作空间标识，指定数据上报的目标工作空间。 |
| `serviceName` | String | 是   | 上报的服务名称，将作为应用名显示在云监控 2.0 的应用列表中。 |
| `debug` | Boolean | 否   | 启用调试日志，默认 `false`。 |
| `batchSize` | Number | 否   | Span 缓冲区大小，达到后批量发送，默认 `10`。 |
| `flushIntervalMs` | Number | 否   | 最大缓冲等待时间（毫秒），默认 `5000`。 |
| `enableTracePropagation` | Boolean | 否   | 启用 W3C Trace Context 传播，关联上下游链路，默认 `false`。 |
| `propagationTargetUrls` | String\\[\\] | 否   | 向匹配的下游 URL 注入 `traceparent` 头（URL 子串匹配）。 |
| `resourceAttributes` | Object | 否   | 自定义 Resource 属性，注入到 OTel Resource（如 `{"deployment.environment": "production"}`）。 |
| `globalSpanAttributes` | Object | 否   | 全局 Span 属性，注入到所有 span（如 `{"biz.team": "payment"}`）。 |

> **说明**：`hooks.allowConversationAccess: true` 必须配置在插件 entries 的 `hooks` 字段中（与 `config` 平级），否则对话类 hooks 将被 OpenClaw 安全策略拦截。仅 OpenClaw版本 >= 2026.4.25 支持此字段，低版本请勿配置。

#### 环境变量降级

当配置文件中未设置对应字段时，插件自动从环境变量读取（适用于容器/K8s 部署场景）：

| **环境变量** | **对应配置** | **说明** |
| --- | --- | --- |
| `ARMS_OTLP_ENDPOINT` | `endpoint` | OTLP 上报地址 |
| `ARMS_LICENSE_KEY` | `headers.x-arms-license-key` | ARMS LicenseKey |
| `ARMS_PROJECT` | `headers.x-arms-project` | ARMS 项目名 |
| `ARMS_CMS_WORKSPACE` | `headers.x-cms-workspace` | 工作空间标识 |
| `ARMS_SERVICE_NAME` / `OTEL_SERVICE_NAME` | `serviceName` | 服务名 |
| `ARMS_TRACE_DEBUG` | `debug` | 调试日志（`true` / `1`） |
| `OTEL_RESOURCE_ATTRIBUTES` | `resourceAttributes` | 自定义 Resource 属性（`key1=value1,key2=value2`） |
| `OTEL_SPAN_ATTRIBUTES` | `globalSpanAttributes` | 全局 Span 属性（`key1=value1,key2=value2`） |

优先级：**配置文件 > 环境变量 > 默认值**。

> **注意**：OpenClaw gateway 默认以 daemon 模式运行，不继承调用 shell 的环境变量。本地开发请使用配置文件方式；环境变量适用于 Docker/K8s 等容器环境。

#### diagnostics-otel 配置

| **参数** | **类型** | **必填** | **说明** |
| --- | --- | --- | --- |
| `enabled` | Boolean | 是   | 是否启用 diagnostics 诊断功能。设置为 `true` 开启。 |
| `otel.enabled` | Boolean | 是   | 是否启用 OpenTelemetry 数据导出。设置为 `true` 开启。 |
| `otel.endpoint` | String | 是   | OTLP 数据上报地址。插件会自动追加 `/v1/traces` 或 `/v1/metrics` 路径。 |
| `otel.protocol` | String | 是   | 上报协议。当前仅支持 `http/protobuf`。 |
| `otel.headers` | Object | 是   | 上报请求携带的认证头信息。 |
| `otel.serviceName` | String | 是   | 上报的服务名称，建议与 `opentelemetry-instrumentation-openclaw` 配置的 `serviceName` 保持一致。 |
| `otel.traces` | Boolean | 是   | 是否上报 Trace 数据。建议设为 `false`，Trace 由 `opentelemetry-instrumentation-openclaw` 负责。 |
| `otel.metrics` | Boolean | 是   | 是否上报 Metric 数据。设为 `true` 可查看 Token 用量、调用次数、耗时等指标。 |
| `otel.logs` | Boolean | 是   | 是否上报 Log 数据。云监控 2.0 暂不支持，建议设为 `false`。 |
| `otel.sampleRate` | Number | 否   | Trace 采样率，取值 0.0 ~ 1.0，仅对根 Span 生效。`1` 表示全量采集。 |
| `otel.flushIntervalMs` | Number | 否   | 数据批量刷新间隔，单位毫秒，最小值 `1000`，默认 `60000`。 |

## 步骤三：验证安装

执行以下命令检查插件是否生效：

```
openclaw plugins list
```

预期输出类似如下内容：

```
┌───────────────────┬─────────────────┬──────────┬──────────┬────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┬────────────┐
│ Name              │ ID              │ Format   │ Status   │ Source                                                                                                                                                                     │ Version    │
├───────────────────┼─────────────────┼──────────┼──────────┼────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┼────────────┤
│ OpenClaw OTel     │ opentelemetry-  │ openclaw │ enabled  │ ~/.openclaw/extensions/opentelemetry-instrumentation-openclaw/dist/index.js                                                                                                │ 0.1.3-beta │
│ Plugin            │ instrumentation │          │          │ Report OpenClaw AI agent execution traces to any OTLP-compatible backend via OpenTelemetry                                                                                 │            │
│ @openclaw/        │ diagnostics-    │ openclaw │ enabled  │ ~/.openclaw/npm/node_modules/@openclaw/diagnostics-otel/dist/index.js                                                                                                      │ 2026.5.6   │
│ diagnostics-otel  │ otel            │          │          │                                                                                                                                                                            │            │
└───────────────────┴─────────────────┴──────────┴──────────┴────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┴────────────┘
```

## 步骤四：查看监控数据

安装完成后， 向 OpenClaw 发送几条消息，触发 Agent 执行。之后您可以在云监控 2.0 控制台查看 OpenClaw 上报的监控数据。

1.  登录[云监控 2.0 控制台](https://cmsnext.console.aliyun.com/)，选择目标工作空间。
    
2.  在左侧导航栏选择**应用可观测 > AI 应用可观测**。
    
3.  在应用列表中找到您配置的服务名称（如 `openclaw-gateway`）。
    
4.  单击应用名称或选择**调用链分析**查看调用链路、Token 消耗、LLM 输入输出和耗时分布。
    

## 卸载

如需卸载插件，执行以下命令：

```
curl -fsSL https://arms-apm-cn-hangzhou-pre.oss-cn-hangzhou.aliyuncs.com/opentelemetry-instrumentation-openclaw/uninstall.sh | bash
```

卸载脚本将自动清理 `opentelemetry-instrumentation-openclaw` 的安装目录和 `openclaw.json` 中的所有相关配置，包括 `diagnostics-otel` 的配置也会一并禁用。

| 参数  | 说明  |
| --- | --- |
| `-y` / `--yes` | 跳过确认提示。 |
| `--install-dir` | 指定插件安装目录（不传则自动探测）。 |
| `--keep-metrics` | 仅卸载 `opentelemetry-instrumentation-openclaw`（Trace），保留 `diagnostics-otel`（Metrics）的配置。 |

## 常见问题

### 配置完成后控制台看不到数据？

请依次排查：

1.  确认 OpenClaw 版本 ≥ v26.2.19（执行 `openclaw --version` 检查）。
    
2.  确认网关已重启（一键安装会自动重启，手动安装需执行 `openclaw gateway restart`）。如果重启失败，可执行`openclaw doctor`，完成修复后再重启网关。
    
3.  确认 Endpoint 地址正确，且网络可达（可通过 `curl` 测试连通性）。
    
4.  确认三个 Header 值（`x-arms-license-key`、`x-arms-project`、`x-cms-workspace`）均已正确填写。
    
5.  如果 OpenClaw 版本 >= 2026.4.25，确认插件配置中 `hooks.allowConversationAccess` 设为 `true`（缺失会导致对话类 hooks 被安全策略拦截）；如果版本低于 2026.4.25，确认配置中没有 `hooks` 字段（否则会报 "Unrecognized key" 错误）。
    
6.  注意 `flushIntervalMs` 默认为 60 秒，短时任务可能需要等待一段时间才能看到数据。
    

### 接入会影响 OpenClaw 的性能吗？

影响极小。`opentelemetry-instrumentation-openclaw` 使用 OpenTelemetry 的批量导出机制，Span 数据在内存中缓冲、定时批量上报，不会阻塞 Agent 的正常处理流程。

### 可以只装 Trace 不装 Metrics 吗？

可以。安装时加 `--disable-metrics` 参数即可跳过 `diagnostics-otel` 的配置，仅启用 Trace 上报。

### diagnostics-otel 的 Trace 和 opentelemetry-instrumentation-openclaw 的 Trace 会冲突吗？

不会。安装脚本默认将 `diagnostics.otel.traces` 设为 `false`，由 `opentelemetry-instrumentation-openclaw` 专门负责 Trace 上报。两者同时上报也不会有冲突。

### 已经配置过 diagnostics-otel 了，安装会覆盖我的配置吗？

不会。安装脚本采用合并更新策略——只更新 `endpoint`、`headers` 等必要字段，保留您已有的 `traces`、`logs`、`sampleRate` 等配置不变。

### 为什么 Token 消耗一直是 0？

OpenClaw 从 v2026.3.8 版本开始引入了一个 BUG，会导致 Token 消耗采集有误，已在 v2026.4.5 版本后修复。

### 可以使用 gRPC 协议上报吗？

当前 OpenClaw 的 `diagnostics-otel` 插件仅支持 `http/protobuf` 协议，设置 `grpc` 会被静默忽略，不会有报错但也不会生效。