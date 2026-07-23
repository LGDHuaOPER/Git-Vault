---
title: "接入 Dify 应用"
source: "https://help.aliyun.com/zh/document_detail/3042579.html?spm=a2c4g.11186623.help-menu-3033820.d_2_3.6a4f64ac4uLvP2"
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
"word-count": "2318"
更新时间: "2026-06-25 11:29:33"
---
本文介绍接入Dify应用的操作流程。

## **组件介绍**

1.  **workflow 应用（LLM 应用）**：用户通过 Dify 可视化界面构建的 LLM 应用本身，通常以工作流（Workflow） 或对话应用（Chatbot） 的形式存在。它定义了应用的逻辑流程、提示词（Prompt）、模型选择、变量处理、条件分支、工具调用等。
    
2.  **dify-api（执行引擎 API）：**Dify 的核心后端服务，负责接收前端请求、管理用户/应用数据、调度工作流执行、调用大模型、协调插件调用，并返回最终结果。
    
3.  **dify-plugin-daemon（插件引擎）**：Dify的插件引擎，用于安全、隔离地执行用户自定义或官方提供的插件（Plugin）。
    
4.  **nginx（入口网关）：**Dify的入口网关，用来进行流量的分发。
    

**重要**

-   如果您是通过ACK的ack-dify组件来使用Dify，建议您直接通过更新Helm的方式进行一键接入，您可以在ACK集群的应用页面对ack-dify组件进行更新：
    

![[raw/assets/Pictures/obsidian-local-images-plus/2026-07-23/接入 Dify 应用/dc7556d46cca77a634f7fa633e50601f_MD5.png]]

![[raw/assets/Pictures/obsidian-local-images-plus/2026-07-23/接入 Dify 应用/46ede623007c04e171501864850d0b08_MD5.png]]

或者在创建ack-dify组件时进行相关配置，以开启应用监控的相关能力：

![[raw/assets/Pictures/obsidian-local-images-plus/2026-07-23/接入 Dify 应用/5044619bc3d965a14a08e5e2468da850_MD5.png]]

## **前提条件**

-   ack-onepilot 版本 >= 5.1.2
    
-   Python探针版本 >= 2.2.0
    

## **接入步骤**

### **步骤一：Dify API管控组件接入**

1.  根据Dify API的部署类型，选择如下两种接入方法之一：
    
    -   K8s容器自动接入(推荐)：请参考[容器服务 ACK 和容器计算服务 ACS 通过 ack-onepilot 组件安装 Python 探针](https://help.aliyun.com/zh/arms/application-monitoring/user-guide/install-arms-agent-for-python-applications-deployed-in-ack-and-acs-clusters) 为Dify API的Deployment添加如下label：
        
        ```
        labels:
          apsara.apm/application-type: Dify
          aliyun.com/app-language: python # Python应用必填，标明此应用是Python应用。
          armsPilotAutoEnable: 'on'
          armsPilotCreateAppName: "deployment-name"    # 应用在ARMS中的展示名称
        ```
        
    -   获取[启动脚本entrypoint.sh](https://github.com/langgenius/dify/blob/main/api/docker/entrypoint.sh)，并进行以下修改：
        
        1.  启动脚本开头添加如下命令，卸载冲突的插件，下载并安装 Python 探针。
            
            ```
            python3 -m ensurepip --upgrade# 卸载冲突的OTel插件pip3 uninstall -y opentelemetry-instrumentation-celery \ opentelemetry-instrumentation-flask \ opentelemetry-instrumentation-redis \ opentelemetry-instrumentation-requests \ opentelemetry-instrumentation-logging \ opentelemetry-instrumentation-wsgi \ opentelemetry-instrumentation-fastapi \ opentelemetry-instrumentation-asgi \ opentelemetry-instrumentation-sqlalchemy# 安装Python探针pip3 config set global.index-url https://mirrors.aliyun.com/pypi/simple/ && pip3 config set install.trusted-host mirrors.aliyun.compip3 install aliyun-bootstrap && aliyun-bootstrap -a install
            ```
            
        2.  脚本最后启动部分添加`aliyun-instrument`启动命令。
            
            ```
            # 使用aliyun-instrument启动exec aliyun-instrument gunicorn \ --bind "${DIFY_BIND_ADDRESS:-0.0.0.0}:${DIFY_PORT:-5001}" \ --workers ${SERVER_WORKER_AMOUNT:-1} \ --worker-class ${SERVER_WORKER_CLASS:-gevent} \ --worker-connections ${SERVER_WORKER_CONNECTIONS:-10} \ --timeout ${GUNICORN_TIMEOUT:-200} \ app:app
            ```
            
    -   配置环境变量。
        
        | **变量名** | **示例值** | **说明** |
        | --- | --- | --- |
        | GEVENT\\_ENABLE | true | Dify 使用 gevent，必须设为true。 |
        | ARMS\\_APP\\_NAME | dify-api | 应用名。 |
        | ARMS\\_REGION\\_ID | cn-heyuan | 地域，修改为对应地域值。 |
        | ARMS\\_LICENSE\\_KEY | xxx | License Key。 |
        | APSARA\\_APM\\_APP\\_TYPE | microservice | 将应用标识为微服务应用。 |
        

2\. 查看Dify API组件监控数据，进入应用监控列表可以看到 dify-api 应用，应用详情示例：![[raw/assets/Pictures/obsidian-local-images-plus/2026-07-23/接入 Dify 应用/e9738af07ee825a3dbea92f870a47667_MD5.png]]

调用链会串联上下游调用信息，示例数据：

![[raw/assets/Pictures/obsidian-local-images-plus/2026-07-23/接入 Dify 应用/5da99ca0742303bfd0cc9306b92d777c_MD5.png]]

### **步骤二：Dify工作流应用接入**

## **1.6.0 < dify-api组件版本 < 1.11.2**

-   单个应用接入：请参考 [Dify应用可观测接入](https://help.aliyun.com/zh/arms/tracing-analysis/enable-tracing-for-dify-application) 在对应的Dify应用进行相应的配置。
    
-   批量应用接入：请参考 [Dify 大模型应用监控批量接入](https://help.aliyun.com/zh/arms/application-monitoring/use-cases/batch-integration-of-dify-llm-applications-with-arms) 进行批量接入。
    

## **dify-api组件版本 <= 1.6.0或组件版本 >= 1.11.2**

此时Dify工作流应用的接入并不需要额外进行配置，只要按上一步骤接入了dify-api组件，工作流产生的链路数据会自动上报并关联。

## **dify-api组件版本 >= 1.13.0**

请参考[Dify配置OTel](https://docs.dify.ai/en/self-host/configuration/environments#otlp-/-opentelemetry-configuration)，在dify-worker组件上配置对应的环境变量，OTel接入点的获取可以参考[准备工作](https://help.aliyun.com/zh/arms/tracing-analysis/before-you-begin)。

#### **查看workflow应用监控数据**

**应用详情示例：**

![[raw/assets/Pictures/obsidian-local-images-plus/2026-07-23/接入 Dify 应用/e14e90d205221eb350fb2a44ede27b62_MD5.png]]

**调用链详情示例：**链路中会采集LLM调用，召回，工具调用等节点的详细信息。

![[raw/assets/Pictures/obsidian-local-images-plus/2026-07-23/接入 Dify 应用/e14e90d205221eb350fb2a44ede27b62_MD5.png]]

### **步骤三：Dify插件引擎接入**

1.  修改Dockerfile文件重新编译对应镜像，local.dockerfile 修改示例：
    
    ```
    FROM golang:1.23-alpine AS builder
    
    ARG VERSION=unknown
    
    # copy project
    COPY . /app
    
    # set working directory
    WORKDIR /app
    
    # using goproxy if you have network issues
    # ENV GOPROXY=https://goproxy.cn,direct
    
    # download arms instgo
    RUN wget "http://arms-apm-cn-hangzhou.oss-cn-hangzhou.aliyuncs.com/instgo/instgo-linux-amd64" -O instgo
    
    RUN chmod 777 instgo
    
    # instgo build
    RUN INSTGO_EXTRA_RULES="dify_python" ./instgo go build \
        -ldflags "\
        -X 'github.com/langgenius/dify-plugin-daemon/internal/manifest.VersionX=${VERSION}' \
        -X 'github.com/langgenius/dify-plugin-daemon/internal/manifest.BuildTimeX=$(date -u +%Y-%m-%dT%H:%M:%S%z)'" \
        -o /app/main cmd/server/main.go
    
    # copy entrypoint.sh
    COPY entrypoint.sh /app/entrypoint.sh
    RUN chmod +x /app/entrypoint.sh
    
    FROM ubuntu:24.04
    
    WORKDIR /app
    
    # check build args
    ARG PLATFORM=local
    
    # Install python3.12 if PLATFORM is local
    RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y curl python3.12 python3.12-venv python3.12-dev python3-pip ffmpeg build-essential \
        && apt-get clean \
        && rm -rf /var/lib/apt/lists/* \
        && update-alternatives --install /usr/bin/python3 python3 /usr/bin/python3.12 1;
    
    # preload tiktoken
    ENV TIKTOKEN_CACHE_DIR=/app/.tiktoken
    
    # Install dify_plugin to speedup the environment setup, test uv and preload tiktoken
    RUN mv /usr/lib/python3.12/EXTERNALLY-MANAGED /usr/lib/python3.12/EXTERNALLY-MANAGED.bk \
        && python3 -m pip install uv \
        && uv pip install --system dify_plugin \
        && python3 -c "from uv._find_uv import find_uv_bin;print(find_uv_bin());" \
        && python3 -c "import tiktoken; encodings = ['o200k_base', 'cl100k_base', 'p50k_base', 'r50k_base', 'p50k_edit', 'gpt2']; [tiktoken.get_encoding(encoding).special_tokens_set for encoding in encodings]"
    
    ENV UV_PATH=/usr/local/bin/uv
    ENV PLATFORM=$PLATFORM
    ENV GIN_MODE=release
    
    COPY --from=builder /app/main /app/entrypoint.sh /app/
    
    # run the server, using sh as the entrypoint to avoid process being the root process
    # and using bash to recycle resources
    CMD ["/bin/bash", "-c", "/app/entrypoint.sh"]
    ```
    
    **说明**
    
    注意 INSTGO\_EXTRA\_RULES 选项会开启 Plugin 运行时自动监测功能，如果不需要在 Plugin-Daemon 启动时拉起对 Plugin 探针，可以去除编译文件中的`INSTGO_EXTRA_RULES="dify_python"`
    
2.  配置环境变量：
    
    -   ECS 环境：
        
        | **变量名** | **示例值** | **说明** |
        | --- | --- | --- |
        | ARMS\\_LICENSE\\_KEY | xxx@xxx | License Key\\[1\\] |
        | ARMS\\_REGION\\_ID | cn-heyuan | 地域  |
        | ARMS\\_ENABLE | true | 探针开关 |
        | ARMS\\_APP\\_NAME | dify-plugin-daemon | 应用名 |
        
    -   容器化 ack-onepilot 环境：在 dify-plugin-daemon 应用的 YAML 配置中将以下 labels 添加到 spec.template.metadata 层级下。
        
        ```
        labels:
          aliyun.com/app-language: golang
          armsPilotAutoEnable: 'on'
          armsPilotCreateAppName: "dify-daemon-plugin"
        ```
        
3.  部署并查看 dify-plugin-daemon 监控：在应用列表页面进入dify-plugin-daemon应用，监控详情如下。![[raw/assets/Pictures/obsidian-local-images-plus/2026-07-23/接入 Dify 应用/e14e90d205221eb350fb2a44ede27b62_MD5.png]]
    
    调用链详情：
    
    ![[raw/assets/Pictures/obsidian-local-images-plus/2026-07-23/接入 Dify 应用/e14e90d205221eb350fb2a44ede27b62_MD5.png]]
    
4.  查看 Plugin 监控：挂载探针后，Plugin-Daemon 会自动拉起插件运行时的探针。每个插件运行时对应一个可观测应用，应用名为 {plugin\_daemon\_name}\_plugin\_{plugin\_name}\_{plugin\_version}。例如，Plugin-Daemon 配置的应用名为 local-dify-plugin-daemon，安装了 tongyi 的 version 0.0.53 插件时，会自动生成应用 local-dify-plugin-daemon\_plugin\_tongyi\_0.0.53，插件监控概览页示例：
    
    ![[raw/assets/Pictures/obsidian-local-images-plus/2026-07-23/接入 Dify 应用/e14e90d205221eb350fb2a44ede27b62_MD5.png]]
    

### **（可选）步骤四：监控代码沙箱 Sandbox**

Sandbox 是 Dify 代码沙箱引擎，负责执行 Workflow 中的 Python/Node.js 代码。Go 探针支持监控 Sandbox，需修改Dockerfile、重新编译镜像后配置环境变量开启。

1.  修改Dockerfile文件重新编译对应镜像，修改./build/build\_\[amd64|arm64\].sh文件。
    
    1.  添加instgo下载命令。下载命令示例如下，其他地域和架构的下载命令请参见[下载 instgo](https://help.aliyun.com/zh/arms/application-monitoring/developer-reference/instgo-tool-introduction#9b94bbe8a62ra)。
        
        ```
        wget "http://arms-apm-cn-hangzhou.oss-cn-hangzhou.aliyuncs.com/instgo/instgo-linux-amd64" -O instgo
        chmod 777 instgo
        ```
        
    2.  在 `go build` 前添加`instgo` 命令。以amd64为例，修改示例如下：
        
        ```
        rm -f internal/core/runner/python/python.so
        rm -f internal/core/runner/nodejs/nodejs.so
        rm -f /tmp/sandbox-python/python.so
        rm -f /tmp/sandbox-nodejs/nodejs.so
        wget "http://arms-apm-cn-hangzhou.oss-cn-hangzhou.aliyuncs.com/instgo/instgo-linux-amd64" -O instgo
        chmod 777 instgo
        echo "Building Python lib"
        CGO_ENABLED=1 GOOS=linux GOARCH=amd64 ./instgo go build -o internal/core/runner/python/python.so -buildmode=c-shared -ldflags="-s -w" cmd/lib/python/main.go &&
        echo "Building Nodejs lib" &&
        CGO_ENABLED=1 GOOS=linux GOARCH=amd64 ./instgo go build -o internal/core/runner/nodejs/nodejs.so -buildmode=c-shared -ldflags="-s -w" cmd/lib/nodejs/main.go &&
        echo "Building main" &&
        GOOS=linux GOARCH=amd64 ./instgo go build -o main -ldflags="-s -w" cmd/server/main.go
        echo "Building env"
        GOOS=linux GOARCH=amd64 ./instgo go build -o env -ldflags="-s -w" cmd/dependencies/init.go
        ```
        
2.  配置环境变量。
    
    -   K8s容器方式接入：在 dify-plugin-daemon 应用的 YAML 配置中将以下 labels 添加到 spec.template.metadata 层级下。
        
        ```
        labels:
          aliyun.com/app-language: golang
          armsPilotAutoEnable: 'on'
          armsPilotCreateAppName: "dify-daemon-plugin"
        ```
        
    -   手动接入：
        
        | **变量名** | **示例值** | **说明** |
        | --- | --- | --- |
        | ARMS\\_LICENSE\\_KEY | xxx | License Key |
        | ARMS\\_REGION\\_ID | cn-heyuan | 地域  |
        | ARMS\\_ENABLE | true | 探针开关 |
        | ARMS\\_APP\\_NAME | dify-plugin-daemon | 应用名 |
        
3.  部署并查看 sandbox 监控，在应用列表页面进入dify-sandbox应用，监控详情如下：![[raw/assets/Pictures/obsidian-local-images-plus/2026-07-23/接入 Dify 应用/e14e90d205221eb350fb2a44ede27b62_MD5.png]]
    
    调用链详情：
    
    ![[raw/assets/Pictures/obsidian-local-images-plus/2026-07-23/接入 Dify 应用/e14e90d205221eb350fb2a44ede27b62_MD5.png]]
    

### **（可选）步骤五：监控入口网关 Nginx**

Nginx 是 Dify 的入口网关，一些超时问题和知识库/插件/Workflow的文件上传问题可能和 Nginx 配置有关。请参考[使用OpenTelemetry对Nginx进行链路追踪](https://help.aliyun.com/zh/opentelemetry/user-guide/use-opentelemetry-to-perform-tracing-analysis-on-nginx)直接使用 Opentelemetry 方式上报即可。

## **接入配置**

#### **输入/输出内容采集**

默认值：True，默认开启采集。

关闭后的效果：用户query时，模型、工具、知识库的input/output等详情字段只采集字段大小，不采集字段内容。

配置方式：设置环境变量`OTEL_INSTRUMENTATION_GENAI_CAPTURE_MESSAGE_CONTENT=False`。

#### **大模型应用拆分**

默认值： False，默认不做应用拆分。

开启后的效果：上报的数据拆分到LLM子应用，每个大模型应用（如Dify Workflow/Agent/Chat App）对应一个ARMS应用。

配置方式：设置环境变量`PROFILER_GENAI_SPLITAPP_ENABLE=True`。

支持的地域：河源、新加坡。

#### **消息内容字段长度限制**

默认值：4K 字符。

开启后的效果：限制LLM每条消息内容（如input/output的消息内容字段）的长度，超过指定字符长度的消息内容将会被截断。

当前生效插件：仅Dify、LangChain支持此配置。

配置方式：如果您的探针版本>=1.8.3可以通过设置环境变量`OTEL_INSTRUMENTATION_GENAI_MESSAGE_CONTENT_MAX_LENGTH=<integer_value>`，将 `<integer_value>` 替换为希望限制的字符长度大小整数值。

#### **Span属性值长度采集限制**

默认值：不设置，默认没有限制。

开启后的效果：限制上报的Span属性值（如 gen\_ai.agent.description）的长度，超过指定字符长度的属性值将会被截断。

当前生效插件：该配置适用于所有支持 OpenTelemetry 的插件（如LangChain/DashScope/Dify等）。

配置方式：设置环境变量`OTEL_SPAN_ATTRIBUTE_VALUE_LENGTH_LIMIT=<integer_value>`，将 `<integer_value>` 替换为希望限制的字符长度大小整数值。