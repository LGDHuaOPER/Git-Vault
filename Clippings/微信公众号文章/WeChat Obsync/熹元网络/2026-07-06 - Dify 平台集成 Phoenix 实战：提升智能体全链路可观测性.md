---
source_url: "https://mp.weixin.qq.com/s?search_click_id=4566775704178140990-1784704998681-4140121486&__biz=MzU2OTc5NTU1NQ==&mid=2247484672&idx=1&sn=035e2b63996192424db10c0c0425992f&chksm=fd0b94976091fc21993abb6dd0be2de70b1666696c0ccdfe0eaf5172330470631f33e40dfb8b&subscene=90&scene=7&clicktime=1784704998&enterid=1784704998&ascene=65&devicetype=iOS26.5.2&version=18004b43&nettype=3G+&abtest_cookie=AAACAA==&lang=zh_CN&countrycode=CN&fontScale=100&exportkey=n_ChQIAhIQnEOiTiet2dH1TcliSxm/wxLhAQIE97dBBAEAAAAAALibBwqjE+wAAAAOpnltbLcz9gKNyK89dVj0KldDzb2CtFjNtCvxtU7oAtF0nAAlSax0nDFhnb5ZOWdfdel3gtH+/SqS9GvhPf7QBxhkU2SNsTHzb1VU1RtPXWvIoK0mVRvwIuEuV6EKnDsNQUFbX58xSMnq0EMQX9QLyMQykfngrALCEH6x6Sak4tgtJjKIQ9s2B7yHnOzbQvBCneqQuqMYIonBZDHd3ifBZsXTyQ4dXip+eNBUEGBx6J8QCDYSVtfV2x1pusrHpUv5B8xmGdmWu2qfVw==&pass_ticket=khIy8BywtKRLu6z2ixgIQBoQ/EnWq12uloAu9iRFMqw4eANfDYuf5zyXl8rYTVGC&wx_header=3"
title: "Dify 平台集成 Phoenix 实战：提升智能体全链路可观测性"
account: "熹元网络"
published_at: "2026-07-06T23:44:00.000Z"
saved_at: "2026-07-22T07:23:53.677Z"
sync_id: "art_a83fa38451bd4491ad349d2d19c0a9e2"
parse_status: "ok"
---

# Dify 平台集成 Phoenix 实战：提升智能体全链路可观测性

###

### 文章目录

- 一、前言
- 1.1 技术背景
- 1.2 本文目标与读者收获
- 1.3 整体架构概览

- 二、环境准备
- 2.1 硬件与软件要求
- 2.2 安装 Docker 环境
- 2.3 确认 Dify 版本

- 三、部署 Phoenix 服务
- 3.1 方式一：Docker 自托管部署
- 3.1.1 创建 Docker Compose 配置文件
- 3.1.2 启动 Phoenix 服务
- 3.1.3 验证 Phoenix 服务
- 3.1.4 获取 API Key

- 3.2 方式二：使用 Phoenix Cloud
- 3.2.1 注册 Phoenix Cloud 账号
- 3.2.2 创建 Phoenix 空间
- 3.2.3 获取 API Key

- 3.3 两种部署方式对比

- 四、Dify 集成 Phoenix 配置
- 4.1 配置流程概览
- 4.2 自托管 Phoenix 集成配置
- 4.3 Phoenix Cloud 集成配置
- 4.4 验证集成是否成功

- 五、Phoenix 可观测性能力详解
- 5.1 Trace 数据模型
- 5.1.1 工作流/对话流追踪
- 5.1.2 消息追踪（LLM 调用）
- 5.1.3 数据集检索追踪（RAG）
- 5.1.4 工具调用追踪

- 5.2 Phoenix Traces 可视化
- 5.3 多维度性能分析

- 六、实战案例：构建可观测的 RAG 智能客服
- 6.1 场景描述
- 6.2 在 Dify 中创建 Workflow
- 6.3 启用 Phoenix 监控
- 6.4 使用 Phoenix 分析 Trace 数据
- 6.4.1 查看单次请求的完整链路
- 6.4.2 识别性能瓶颈
- 6.4.3 使用 Phoenix Span Replay 调试

- 6.5 使用 Phoenix Python SDK 进行高级分析
- 6.6 使用 Phoenix 评估功能

- 七、故障排查与问题解决
- 7.1 集成配置问题
- 问题 1：Dify 保存 Phoenix 配置时报错 "Connection refused"
- 问题 2：Dify 配置成功但 Phoenix 中看不到 Trace 数据

- 7.2 性能问题
- 问题 3：Phoenix 服务响应缓慢
- 问题 4：Dify 应用响应变慢（启用 Phoenix 后）

- 7.3 调试技巧总结

- 八、总结
- 8.1 核心知识点回顾
- 8.2 扩展学习方向
- 8.3 学习资源

## 一、前言

### 1.1 技术背景

随着大语言模型（LLM）技术的快速普及，越来越多的团队基于 Dify 这类低代码平台搭建生产级的智能体应用。从简单的智能客服、文档问答机器人，到复杂的多步骤 Workflow 和 Agent 系统，LLM 正在渗透到业务的每一个环节。

然而，LLM 应用的"黑盒"特性给生产运维带来了巨大挑战。传统的日志监控手段在 LLM 场景下几乎完全失效——输入输出不匹配、Prompt 动态组装、多模型调用链复杂，这些问题让开发者在排查线上故障时如同"大海捞针"。具体来说，团队通常面临以下痛点：

- 推理性能黑洞 ：Token 消耗异常激增、API 延迟陡升，却缺乏细粒度的指标追踪手段
- 幻觉诊断困难 ：错误回答背后究竟是知识库检索失败还是 Prompt 设计缺陷？无法快速定位根因
- 成本失控风险 ：模型误用导致单日账单飙升，缺乏实时的 Token 消耗监控和告警机制
- 迭代优化无据 ：改了 Prompt 后"感觉"效果更好了，但缺少量化数据支撑决策

**Arize Phoenix**（以下简称 Phoenix）正是为解决这些问题而生的开源 AI 可观测性平台。它基于 **OpenTelemetry** 标准构建，提供 LLM 链路追踪（Tracing）、模型评估（Evaluation）、Prompt 管理和性能监控等核心能力，能够与 Dify 平台无缝集成，为智能体应用构建全链路可观测体系。

### 1.2 本文目标与读者收获

本文将手把手带你完成 Dify 与 Phoenix 的集成，读者将学到：

- 理解 Phoenix 的核心架构与可观测性能力
- 掌握 Phoenix 自部署（Docker）和云版本两种部署方式
- 完成 Dify 应用与 Phoenix 的对接配置
- 学会利用 Phoenix 追踪 Workflow、Agent、RAG 等全链路执行过程
- 掌握基于 Phoenix 的性能分析与故障排查方法

**技术栈：**

- 平台框架：Dify（v1.6.0+）
- 可观测性工具：Arize Phoenix（开源版 / Cloud 版）
- 协议标准：OpenTelemetry、OpenInference
- 部署工具：Docker、Docker Compose
- 数据库：PostgreSQL（Phoenix 后端存储）

### 1.3 整体架构概览

在深入实操之前，先来理解 Dify 与 Phoenix 集成后的整体数据流架构：

![](附件资源/Dify%20平台集成%20Phoenix%20实战：提升智能体全链路可观测性/img_1.png)

Dify 通过内置的 **OpsTrace 事件机制**，将 Workflow/Agent 执行过程中的 LLM 调用、工具调用、知识库检索等关键节点信息，以 OpenTelemetry 标准格式发送至 Phoenix。Phoenix 接收这些 Trace 数据后，提供可视化的链路追踪、多维度性能分析和异常检测能力。

## 二、环境准备

### 2.1 硬件与软件要求

**硬件要求：**

| 资源 | 最低配置 | 推荐配置 |
| --- | --- | --- |
| CPU | 2 核 | 4 核+ |
| 内存 | 4 GB | 8 GB+ |
| 磁盘 | 20 GB | 50 GB+（SSD） |

**软件依赖：**

| 软件 | 版本要求 | 用途 |
| --- | --- | --- |
| Dify | v1.6.0+ | LLM 应用开发平台 |
| Docker | 20.10+ | 容器化部署 |
| Docker Compose | v2.0+ | 多容器编排 |
| Python | 3.8+（可选） | Phoenix SDK 使用 |

### 2.2 安装 Docker 环境

如果你的机器尚未安装 Docker，请根据操作系统执行以下步骤：

**macOS 系统：**

-
-
-
-
-

```
# 使用 Homebrew 安装 Docker Desktopbrew install --cask docker# 启动 Docker Desktop 后验证安装docker --versiondocker compose version
```

**Linux 系统（Ubuntu/Debian）：**

-
-
-
-
-
-
-
-
-
-

```
# 更新包索引sudo apt update# 安装 Dockersudo apt install -y docker.io docker-compose-plugin# 启动 Docker 服务sudo systemctl start dockersudo systemctl enable docker# 验证安装docker --versiondocker compose version
```

**验证 Docker 环境：**

-
-

```
docker compose versionDocker Compose version v2.23.0
```

> 💡 提示：确保 Docker Compose 版本为 v2.0+，本文使用 docker compose （V2 语法）而非旧版 docker-compose 。

### 2.3 确认 Dify 版本

Phoenix 集成功能需要 Dify v1.6.0 及以上版本。登录 Dify 控制台后，可在左下角查看当前版本号。如果版本低于 1.6.0，请先升级 Dify。

-
-

```
# 如果使用 Docker 部署的 Dify，可通过以下命令查看版本docker ps | grep dify
```

## 三、部署 Phoenix 服务

Phoenix 支持两种部署方式：**自托管部署**（Docker）和 **Cloud 云服务**。本章将分别介绍这两种方式。

### 3.1 方式一：Docker 自托管部署

自托管部署适合对数据安全有要求、需要完全掌控数据流向的团队。

#### 3.1.1 创建 Docker Compose 配置文件

在你的工作目录下创建  `docker-compose.yml`  文件：

-
-
-
-
-

```
# docker-compose.yml# Phoenix 自托管部署配置（含 PostgreSQL 后端）services:  phoenix:    image: arizephoenix/phoenix:latest  # Phoenix 主服务镜像    depends_on:      - db  # 依赖 PostgreSQL 数据库    ports:      - "6006:6006"   # Phoenix Web UI 端口      - "4317:4317"   # OTLP gRPC 端口（接收 Trace 数据）      - "9090:9090"   # Prometheus 指标端口（可选）    environment:      # 数据库连接字符串      - PHOENIX_SQL_DATABASE_URL=postgresql://postgres:postgres@db:5432/postgres      # 启用身份验证（生产环境强烈建议开启）      - PHOENIX_ENABLE_AUTH=True      # 设置认证密钥（请替换为你自己的安全密钥）      - PHOENIX_SECRET=your-secure-secret-key-change-me    restart: unless-stopped  db:    image: postgres:16  # PostgreSQL 16 数据库    ports:      - "5432:5432"    environment:      - POSTGRES_USER=postgres      - POSTGRES_PASSWORD=postgres      - POSTGRES_DB=postgres    volumes:      # 持久化数据库数据，防止容器重启后数据丢失      - phoenix_pgdata:/var/lib/postgresql/data    restart: unless-stoppedvolumes:  phoenix_pgdata:    driver: local
```

**关键配置说明：**

| 配置项 | 说明 |
| --- | --- |
| `6006` 端口 | Phoenix Web UI 和 OTLP HTTP 收集器 |
| `4317` 端口 | OTLP gRPC 收集器，用于接收 Trace 数据 |
| `9090` 端口 | Prometheus 指标暴露端口（可选） |
| `PHOENIX_ENABLE_AUTH` | 是否启用身份验证，生产环境建议设为 `True` |
| `PHOENIX_SECRET` | 认证密钥，用于生成 API Key |

#### 3.1.2 启动 Phoenix 服务

-
-
-
-

```
# 在 docker-compose.yml 所在目录执行docker compose up -d# 查看服务启动状态docker compose ps
```

预期输出：

-
-
-

```
NAME                IMAGE                          STATUS          PORTSphoenix-phoenix-1   arizephoenix/phoenix:latest    Up 30 seconds   0.0.0.0:4317->4317/tcp, 0.0.0.0:6006->6006/tcp, 0.0.0.0:9090->9090/tcpphoenix-db-1        postgres:16                    Up 31 seconds   0.0.0.0:5432->5432/tcp
```

#### 3.1.3 验证 Phoenix 服务

打开浏览器访问  `http://localhost:6006` ，你应该能看到 Phoenix 的 Web UI 界面。

-
-

```
# 也可以通过命令行验证服务是否正常响应curl -s http://localhost:6006/healthz
```

> ⚠️ 注意：如果 Phoenix 部署在远程服务器上，请将 localhost 替换为服务器的实际 IP 地址，并确保防火墙已放行 6006 和 4317 端口。

#### 3.1.4 获取 API Key

登录 Phoenix Web UI 后，从右上角的用户菜单中获取 API Key：

- 点击右上角的用户头像
- 选择 API Key 选项
- 点击生成新的 API Key
- 复制并妥善保存 API Key（后续配置 Dify 时需要使用）

### 3.2 方式二：使用 Phoenix Cloud

如果你不想自行维护 Phoenix 服务，可以使用 Arize 提供的 Phoenix Cloud 托管服务。

#### 3.2.1 注册 Phoenix Cloud 账号

访问 https://app.arize.com/auth/phoenix/signup 注册账号。

#### 3.2.2 创建 Phoenix 空间

登录后，在右上角的用户菜单中创建 Phoenix 空间：

- 点击 创建空间
- 为你的空间提供一个唯一的 URL 标识符（例如 my-company-ai ）
- 保存后，在概览页面查看空间状态

#### 3.2.3 获取 API Key

空间启动后，获取 API Key：

- 点击左下角的 设置
- 选择 系统密钥
- 点击创建新的 API Key 并命名
- 复制 API Key 和空间主机名（格式如 https://my-company-ai.phoenix.arize.com ）

### 3.3 两种部署方式对比

| 对比维度 | Docker 自托管 | Phoenix Cloud |
| --- | --- | --- |
| 数据安全 | 数据完全本地化，安全性最高 | 数据存储在 Arize 云端 |
| 运维成本 | 需自行维护服务器和数据库 | 零运维，全托管 |
| 扩展性 | 需手动扩容 | 自动弹性扩展 |
| 费用 | 仅服务器成本 | 有免费额度，超出按量付费 |
| 适用场景 | 企业内网、数据合规要求高 | 快速验证、中小团队 |

## 四、Dify 集成 Phoenix 配置

### 4.1 配置流程概览

![](附件资源/Dify%20平台集成%20Phoenix%20实战：提升智能体全链路可观测性/img_2.png)

### 4.2 自托管 Phoenix 集成配置

**步骤 1：登录 Dify 控制台**

打开浏览器访问你的 Dify 实例，使用管理员账号登录。

**步骤 2：进入目标应用的监控设置**

- 在 Dify 控制台中，选择你需要监控的应用（Chatbot、Workflow 或 Agent 类型均可）
- 在左侧菜单中点击 监控
- 在页面中找到 追踪应用性能 区域

**步骤 3：配置 Phoenix 连接参数**

点击 Phoenix 的 **配置** 按钮，在弹出的对话框中填写以下信息：

| 配置项 | 值 | 说明 |
| --- | --- | --- |
| API Key | `phoenix-api-key-xxx` | 从 Phoenix UI 获取的 API Key |
| Project Name | `my-dify-app` | 项目名称，用于在 Phoenix 中区分不同应用 |
| Host | `http://your-server-ip:6006` | Phoenix 服务地址（自托管时填写） |

**步骤 4：保存并启用**

点击 **保存并启用** 按钮。如果配置正确，页面会显示监控状态为"已启用"。

> ⚠️ 注意：如果 Dify 和 Phoenix 都部署在同一台服务器的 Docker 环境中，Host 地址不能填 localhost ，需要使用 Docker 网络中的服务名或宿主机的实际 IP 地址。

### 4.3 Phoenix Cloud 集成配置

Cloud 版本的配置流程与自托管类似，区别在于需要额外填写 **空间主机名**：

| 配置项 | 值 | 说明 |
| --- | --- | --- |
| API Key | `phoenix-cloud-api-key-xxx` | 从 Phoenix Cloud 设置中获取 |
| Project Name | `my-dify-app` | 项目名称 |
| Host | `https://my-space.phoenix.arize.com` | Phoenix Cloud 空间主机名 |

### 4.4 验证集成是否成功

配置完成后，通过以下方式验证集成是否正常工作：

**方法 1：在 Dify 中发送测试消息**

在 Dify 应用的调试界面中发送一条测试消息，等待回复完成。

**方法 2：在 Phoenix 中查看 Trace 数据**

- 打开 Phoenix Web UI（ http://localhost:6006 或 Cloud 地址）
- 在左侧导航栏中选择 Traces
- 你应该能看到刚才测试消息产生的完整调用链路

如果能在 Phoenix 中看到 Trace 数据，说明集成配置成功。

-
-
-
-
-
-
-
-
-
-

```
# 快速验证：通过 Dify API 发送一条测试请求curl -X POST 'http://your-dify-host/v1/chat-messages' \  -H 'Authorization: Bearer your-dify-api-key' \  -H 'Content-Type: application/json' \  -d '{    "inputs": {},    "query": "你好，这是一条测试消息",    "response_mode": "blocking",    "user": "test-user"  }'
```

## 五、Phoenix 可观测性能力详解

### 5.1 Trace 数据模型

Dify 集成 Phoenix 后，会自动采集以下六类 Trace 数据，覆盖智能体应用的全链路执行过程：

![](附件资源/Dify%20平台集成%20Phoenix%20实战：提升智能体全链路可观测性/img_3.png)

#### 5.1.1 工作流/对话流追踪

这是最核心的追踪类型，记录了整个 Workflow 或对话流的执行全貌：

-
-
-
-
-

```
# 工作流追踪数据结构示例（Phoenix 中的 Span 数据）workflow_trace = {    "name": "workflow_{workflow_id}",      # Span 名称    "span_kind": "CHAIN",                  # Span 类型    "status": "OK",                        # 执行状态    "start_time": "2025-03-06T10:00:00Z",  # 开始时间    "end_time": "2025-03-06T10:00:05Z",    # 结束时间    "attributes": {        "workflow_id": "wf-abc123",        # 工作流唯一标识        "conversation_id": "conv-xyz789",  # 对话 ID        "workflow_run_id": "run-001",      # 本次运行 ID        "tenant_id": "tenant-001",         # 租户 ID        "total_tokens": 1520,              # 总 Token 消耗        "elapsed_time": 4.8,               # 耗时（秒）        "version": "2025-03-06",           # 工作流版本        "triggered_from": "api",           # 触发来源        "status": "succeeded"              # 运行状态    },    "inputs": {"query": "什么是 RAG？"},    "outputs": {"answer": "RAG 是检索增强生成..."},    "tags": ["workflow"]}
```

#### 5.1.2 消息追踪（LLM 调用）

记录每次 LLM 模型调用的详细信息，是分析模型性能和成本的关键数据：

-
-
-
-
-
-
-
-
-
-
-
-
-
-
-
-
-
-

```
# 消息追踪数据结构示例message_trace = {    "name": "llm",                          # Span 名称    "span_kind": "LLM",                     # Phoenix LLM 类型    "attributes": {        "message_id": "msg-001",        "conversation_id": "conv-xyz789",        "ls_provider": "openai",            # 模型提供商        "ls_model_name": "gpt-4",           # 模型名称        "message_tokens": 256,              # 输入 Token 数        "answer_tokens": 512,               # 输出 Token 数        "total_tokens": 768,                # 总 Token 数        "conversation_mode": "chat",        # 对话模式        "agent_based": True,                # 是否基于 Agent        "from_source": "api"                # 消息来源    },    "tags": ["message", "chat"]}
```

#### 5.1.3 数据集检索追踪（RAG）

追踪知识库检索过程，帮助诊断 RAG 应用中的检索质量问题：

-
-
-
-
-

```
# 数据集检索追踪数据结构示例retrieval_trace = {    "name": "dataset_retrieval",            # Span 名称    "span_kind": "RETRIEVER",               # Phoenix Retriever 类型    "attributes": {        "message_id": "msg-001",        "inputs": "什么是 RAG？",        "documents": [                      # 检索到的文档列表            {                "content": "RAG 全称 Retrieval-Augmented Generation...",                "score": 0.92,              # 相关性分数                "metadata": {"source": "ai_glossary.pdf", "page": 15}            },            {                "content": "检索增强生成是一种结合检索和生成的技术...",                "score": 0.87,                "metadata": {"source": "llm_handbook.pdf", "page": 42}            }        ]    },    "tags": ["dataset_retrieval"]}
```

#### 5.1.4 工具调用追踪

记录 Agent 在推理过程中调用外部工具的详细信息：

-
-
-
-
-
-
-
-
-
-
-
-
-
-
-

```
# 工具调用追踪数据结构示例tool_trace = {    "name": "web_search",                   # 工具名称    "span_kind": "TOOL",                    # Phoenix Tool 类型    "attributes": {        "message_id": "msg-001",        "tool_name": "web_search",          # 工具名称        "tool_inputs": {"query": "2025年AI趋势"},  # 工具输入        "tool_outputs": "根据搜索结果...",   # 工具输出        "time_cost": 2.3,                   # 耗时（秒）        "tool_config": {"provider": "google"},        "tool_parameters": {"max_results": 5}    },    "tags": ["tool", "web_search"]}
```

### 5.2 Phoenix Traces 可视化

集成完成后，在 Phoenix 的 Traces 页面中，你可以看到每次请求的完整调用链路。Phoenix 将 Dify 的执行过程以树状结构展示，每个节点（Span）代表一个执行步骤：

**典型的 Workflow Trace 结构：**

-
-
-
-
-
-
-
-
-
-
-

```
📋 workflow_my_rag_app (4.8s, 1520 tokens)├── 🔍 dataset_retrieval (0.8s)│   └── 检索到 3 个相关文档，最高分 0.92├── 🤖 llm (3.2s, 768 tokens)│   ├── Provider: openai│   ├── Model: gpt-4│   ├── Input tokens: 256│   └── Output tokens: 512├── 🔧 web_search (0.5s)│   └── 搜索关键词: "2025年AI趋势"└── ✅ 审核通过 (0.3s)
```

通过这种可视化的链路追踪，你可以一目了然地看到：

- 每个步骤的执行耗时，快速定位性能瓶颈
- LLM 调用的 Token 消耗，监控成本
- 知识库检索的文档列表和相关性分数，诊断 RAG 质量
- 工具调用的输入输出，排查工具集成问题

### 5.3 多维度性能分析

Phoenix 提供了丰富的分析维度，帮助你从不同角度理解应用的运行状况：

**按模型维度分析：**

| 分析指标 | 说明 | 典型用途 |
| --- | --- | --- |
| Token 消耗分布 | 各模型的 Token 使用量 | 成本优化，识别高消耗模型 |
| 延迟分布 | 各模型的响应时间分布 | 性能优化，选择更快的模型 |
| 错误率 | 各模型的调用失败率 | 稳定性监控，及时切换备用模型 |
| 吞吐量 | 单位时间内的请求处理数 | 容量规划，评估是否需要扩容 |

**按应用维度分析：**

通过  `Project Name`  区分不同的 Dify 应用，可以对比不同应用的性能表现，识别需要优化的应用。

**按用户维度分析：**

通过  `user_session_id`  追踪特定用户的交互历史，分析用户体验问题。

## 六、实战案例：构建可观测的 RAG 智能客服

### 6.1 场景描述

假设我们在 Dify 上构建了一个基于 RAG 的智能客服 Workflow，包含以下节点：

- 用户输入 → 2. 知识库检索 → 3. Prompt 组装 → 4. LLM 生成回答 → 5. 内容审核 → 6. 返回结果

我们希望通过 Phoenix 监控以下关键指标：

- 知识库检索的召回质量（相关性分数）
- LLM 生成的 Token 消耗和延迟
- 内容审核的拦截率
- 端到端的响应时间

### 6.2 在 Dify 中创建 Workflow

在 Dify 控制台中创建一个新的 Workflow 应用，按以下结构编排节点：

![](附件资源/Dify%20平台集成%20Phoenix%20实战：提升智能体全链路可观测性/img_4.png)

### 6.3 启用 Phoenix 监控

按照第四章的配置步骤，为该 Workflow 应用启用 Phoenix 追踪。配置完成后，每次用户与智能客服的交互都会自动生成 Trace 数据。

### 6.4 使用 Phoenix 分析 Trace 数据

#### 6.4.1 查看单次请求的完整链路

在 Phoenix Traces 页面中，点击任意一条 Trace 记录，可以展开查看完整的执行链路：

-
-
-
-
-

```
📋 workflow_rag_customer_service (5.2s, 2048 tokens)│├── 🔍 dataset_retrieval (1.1s)│   ├── Query: "如何退换货？"│   ├── Retrieved Documents: 3│   ├── Top Score: 0.95│   └── Documents:│       ├── [1] 退换货政策说明 (score: 0.95)│       ├── [2] 售后服务流程 (score: 0.88)│       └── [3] 常见问题FAQ (score: 0.72)│├── 🤖 llm_generate_answer (3.5s, 1856 tokens)│   ├── Provider: openai│   ├── Model: gpt-4│   ├── Input: "基于以下上下文回答用户问题..."│   ├── Output: "根据我们的退换货政策，您可以在..."│   ├── Input Tokens: 1024│   ├── Output Tokens: 832│   └── Latency: 3.5s│├── ✅ moderation (0.4s)│   ├── Flagged: false│   └── Action: pass│└── 📤 response (0.2s)    └── "根据我们的退换货政策，您可以在购买后7天内..."
```

#### 6.4.2 识别性能瓶颈

通过分析多条 Trace 数据，你可能会发现：

- LLM 调用耗时占比最大 （约 67%）：考虑使用更快的模型（如 gpt-4o-mini）或优化 Prompt 减少输入 Token
- 知识库检索偶尔超时 ：检查向量数据库的索引配置，或增加检索超时时间
- 部分请求的检索相关性分数偏低 （Phoenix 提供了 **Span Replay** 功能，可以重放 LLM 的调用过程。你可以：

- 在 Traces 中找到一个回答质量不佳的请求
- 点击对应的 LLM Span
- 使用 Span Replay 修改 Prompt 或模型参数
- 对比修改前后的输出效果

这个功能在优化 Prompt 时非常有用，无需重新发起完整的请求，就能快速验证 Prompt 修改的效果。

### 6.5 使用 Phoenix Python SDK 进行高级分析

除了 Web UI，你还可以通过 Phoenix 的 Python SDK 进行更灵活的数据分析：

-
-
-
-
-

```
"""Phoenix Python SDK 高级分析示例功能：连接 Phoenix 服务，查询 Trace 数据并进行统计分析"""from phoenix.client import Clientimport pandas as pdfrom datetime import datetime, timedelta# 连接 Phoenix 服务# 自托管版本client = Client(endpoint="http://localhost:6006")# 或 Cloud 版本# client = Client(#     endpoint="https://my-space.phoenix.arize.com",#     api_key="your-phoenix-cloud-api-key"# )# 获取指定项目的 Trace 数据project_name = "my-dify-app"# 查询最近 24 小时的 Tracestraces_df = client.get_traces_dataframe(    project_name=project_name,    start_time=datetime.now() - timedelta(hours=24),    end_time=datetime.now())print(f"最近 24 小时共有 {len(traces_df)} 条 Trace 记录")# 获取所有 Spans 数据（包含 LLM、Tool、Retriever 等）spans_df = client.get_spans_dataframe(    project_name=project_name,    start_time=datetime.now() - timedelta(hours=24),    end_time=datetime.now())# ========== 分析 1：Token 消耗统计 ==========llm_spans = spans_df[spans_df["span_kind"] == "LLM"]if not llm_spans.empty:    total_tokens = llm_spans["attributes.total_tokens"].sum()    avg_tokens = llm_spans["attributes.total_tokens"].mean()    max_tokens = llm_spans["attributes.total_tokens"].max()    print(f"\n📊 Token 消耗统计：")    print(f"  总消耗: {total_tokens:,.0f} tokens")    print(f"  平均每次: {avg_tokens:,.0f} tokens")    print(f"  单次最高: {max_tokens:,.0f} tokens")# ========== 分析 2：延迟分布 ==========if "latency_ms" in spans_df.columns:    p50 = spans_df["latency_ms"].quantile(0.5)    p95 = spans_df["latency_ms"].quantile(0.95)    p99 = spans_df["latency_ms"].quantile(0.99)    print(f"\n⏱️ 延迟分布：")    print(f"  P50: {p50:.0f}ms")    print(f"  P95: {p95:.0f}ms")    print(f"  P99: {p99:.0f}ms")# ========== 分析 3：检索质量分析 ==========retriever_spans = spans_df[spans_df["span_kind"] == "RETRIEVER"]if not retriever_spans.empty:    print(f"\n🔍 知识库检索统计：")    print(f"  总检索次数: {len(retriever_spans)}")# ========== 分析 4：错误率统计 ==========error_spans = spans_df[spans_df["status"] == "ERROR"]error_rate = len(error_spans) / len(spans_df) * 100 if len(spans_df) > 0 else 0print(f"\n❌ 错误率: {error_rate:.2f}%")if not error_spans.empty:    print(f"  错误 Span 数: {len(error_spans)}")    # 打印错误详情    for _, span in error_spans.head(5).iterrows():        print(f"  - [{span.get('name', 'unknown')}] {span.get('status_message', 'N/A')}")
```

运行结果示例：

-
-
-
-
-
-
-
-
-
-
-
-
-
-
-

```
最近 24 小时共有 156 条 Trace 记录📊 Token 消耗统计：  总消耗: 238,560 tokens  平均每次: 1,529 tokens  单次最高: 4,096 tokens⏱️ 延迟分布：  P50: 2,340ms  P95: 5,120ms  P99: 8,750ms🔍 知识库检索统计：  总检索次数: 142❌ 错误率: 1.28%  错误 Span 数: 2  - [llm] Rate limit exceeded  - [dataset_retrieval] Connection timeout
```

### 6.6 使用 Phoenix 评估功能

Phoenix 不仅提供追踪能力，还内置了 LLM 评估框架。你可以利用评估功能自动检测 RAG 应用中的常见问题：

-
-
-
-
-

```
"""使用 Phoenix Evals 评估 RAG 应用质量功能：自动评估检索相关性和回答质量"""from phoenix.evals import (    HallucinationEvaluator,    QAEvaluator,    RelevanceEvaluator,    run_evals,)from phoenix.client import Client# 连接 Phoenixclient = Client(endpoint="http://localhost:6006")# 获取需要评估的 Trace 数据spans_df = client.get_spans_dataframe(    project_name="my-dify-app",    span_kind="LLM"  # 只获取 LLM 类型的 Span)# 初始化评估器hallucination_eval = HallucinationEvaluator()  # 幻觉检测qa_eval = QAEvaluator()                        # 问答质量评估relevance_eval = RelevanceEvaluator()           # 检索相关性评估# 运行评估eval_results = run_evals(    dataframe=spans_df,    evaluators=[hallucination_eval, qa_eval, relevance_eval],    provide_explanation=True  # 提供评估解释)# 查看评估结果print("📋 评估结果摘要：")for eval_name, result_df in eval_results.items():    pass_rate = (result_df["score"] >= 0.7).mean() * 100    print(f"  {eval_name}: 通过率 {pass_rate:.1f}%")
```

## 七、故障排查与问题解决

### 7.1 集成配置问题

#### 问题 1：Dify 保存 Phoenix 配置时报错 “Connection refused”

**错误现象：**

在 Dify 中配置 Phoenix 并点击保存时，提示连接被拒绝。

**原因分析：**

- Phoenix 服务未启动或启动失败
- Dify 与 Phoenix 之间的网络不通
- Host 地址填写错误

**解决方案：**

**方案 1：检查 Phoenix 服务状态**

-
-
-
-
-
-

```
# 查看 Phoenix 容器是否正常运行docker compose ps# 查看 Phoenix 容器日志docker compose logs phoenix# 测试 Phoenix 服务是否可访问curl -v http://localhost:6006/healthz
```

**方案 2：检查网络连通性**

-
-
-
-
-
-
-

```
# 如果 Dify 和 Phoenix 在同一台机器的不同 Docker 网络中# 需要使用宿主机 IP 而非 localhost# 获取宿主机 IP# macOSifconfig | grep "inet " | grep -v 127.0.0.1# Linuxhostname -I
```

**方案 3：Docker 网络配置**

如果 Dify 和 Phoenix 都通过 Docker 部署，建议将它们放入同一个 Docker 网络：

-
-
-
-
-

```
# 在 Phoenix 的 docker-compose.yml 中添加外部网络networks:  default:    external: true    name: dify_default  # 使用 Dify 的 Docker 网络名称
```

**验证修复：**

-
-

```
# 从 Dify 容器内部测试 Phoenix 连通性docker exec -it dify-api-1 curl http://phoenix-phoenix-1:6006/healthz
```

#### 问题 2：Dify 配置成功但 Phoenix 中看不到 Trace 数据

**错误现象：**

Dify 中显示 Phoenix 监控已启用，但在 Phoenix UI 中看不到任何 Trace 数据。

**原因分析：**

- Project Name 不匹配
- API Key 权限不足
- OTLP 端口（4317）未正确暴露
- Dify 应用尚未产生实际请求

**解决方案：**

**方案 1：确认 Project Name**

确保 Dify 中配置的 Project Name 与你在 Phoenix 中查看的项目一致。在 Phoenix UI 的左上角项目选择器中切换到对应项目。

**方案 2：检查 OTLP 端口**

-
-
-
-
-
-
-

```
# 确认 4317 端口已暴露docker compose port phoenix 4317# 测试 gRPC 端口连通性# 安装 grpcurl 工具brew install grpcurl  # macOS# 测试 gRPC 连接grpcurl -plaintext localhost:4317 list
```

**方案 3：发送测试请求**

在 Dify 应用中发送一条实际的用户消息，然后等待 10-30 秒后刷新 Phoenix Traces 页面。

**验证修复：**

在 Phoenix UI 的 Traces 页面中能看到新的 Trace 记录即为成功。

### 7.2 性能问题

#### 问题 3：Phoenix 服务响应缓慢

**错误现象：**

Phoenix Web UI 加载缓慢，Traces 页面查询超时。

**原因分析：**

- PostgreSQL 数据库性能不足
- Trace 数据量过大，未配置数据清理策略
- 服务器资源不足

**解决方案：**

**方案 1：优化 PostgreSQL 配置**

-
-
-
-
-
-
-
-
-
-
-
-
-
-
-

```
# 在 docker-compose.yml 中为 PostgreSQL 添加性能优化参数services:  db:    image: postgres:16    command:      - "postgres"      - "-c"      - "shared_buffers=256MB"       # 增加共享缓冲区      - "-c"      - "work_mem=16MB"              # 增加工作内存      - "-c"      - "effective_cache_size=512MB" # 增加有效缓存大小      - "-c"      - "max_connections=100"        # 最大连接数    # ... 其他配置不变
```

**方案 2：配置数据保留策略**

通过 Phoenix 环境变量配置 Trace 数据的自动清理：

-
-
-
-
-

```
services:  phoenix:    environment:      # 设置 Trace 数据保留天数（例如保留 30 天）      - PHOENIX_RETENTION_PERIOD_DAYS=30
```

**方案 3：增加服务器资源**

-
-
-
-
-
-
-
-
-
-
-

```
# 在 docker-compose.yml 中限制和分配资源services:  phoenix:    deploy:      resources:        limits:          cpus: '2'          memory: 4G        reservations:          cpus: '1'          memory: 2G
```

#### 问题 4：Dify 应用响应变慢（启用 Phoenix 后）

**错误现象：**

启用 Phoenix 追踪后，Dify 应用的响应时间明显增加。

**原因分析：**

Trace 数据的发送通常是异步的，不应显著影响应用性能。如果出现明显延迟，可能是：

- Phoenix 服务不可用导致 Trace 发送超时
- 网络延迟过高

**解决方案：**

-
-
-
-

```
# 检查 Dify 到 Phoenix 的网络延迟ping your-phoenix-server-ip# 如果延迟过高，考虑将 Phoenix 部署在与 Dify 同一内网中# 或使用 Phoenix Cloud 的就近区域节点
```

> 💡 提示：正常情况下，启用 Phoenix 追踪对 Dify 应用性能的影响应在 5% 以内。如果影响超过 10%，请检查网络配置。

### 7.3 调试技巧总结

**调试流程：**

![](附件资源/Dify%20平台集成%20Phoenix%20实战：提升智能体全链路可观测性/img_5.png)

**常用调试命令速查：**

-
-
-
-
-
-
-
-
-
-
-
-
-
-

```
# 查看 Phoenix 容器日志（实时跟踪）docker compose logs -f phoenix# 查看 Dify API 容器日志docker compose logs -f dify-api# 检查 Phoenix 服务健康状态curl http://localhost:6006/healthz# 检查端口占用lsof -i :6006lsof -i :4317# 查看 Docker 网络配置docker network lsdocker network inspect dify_default# 查看容器资源使用情况docker stats
```

## 八、总结

### 8.1 核心知识点回顾

- Phoenix 定位 ：Phoenix 是基于 OpenTelemetry 的开源 AI 可观测性平台，专为 LLM 应用设计，提供 Tracing、Evaluation、Prompt 管理等核心能力
- 集成原理 ：Dify 通过内置的 OpsTrace 事件机制，以 OpenTelemetry 标准格式将 Trace 数据发送至 Phoenix
- 数据覆盖 ：集成后可自动采集工作流追踪、消息追踪、知识库检索、工具调用、内容审核、建议问题等六类 Trace 数据
- 部署选择 ：Docker 自托管适合数据安全要求高的场景，Phoenix Cloud 适合快速验证和中小团队
- 分析能力 ：通过 Phoenix 可实现 Token 消耗分析、延迟分布统计、错误率监控、RAG 检索质量评估等多维度分析

### 8.2 扩展学习方向

- Phoenix Evaluation 深度使用 ：利用 Phoenix 的评估框架构建自动化的 RAG 质量评估流水线
- Prompt 版本管理 ：使用 Phoenix 的 Prompt Management 功能管理和追踪 Prompt 的迭代历史
- 多应用统一监控 ：将多个 Dify 应用的 Trace 数据汇聚到同一个 Phoenix 实例，构建统一的可观测性仪表盘
- 告警与自动化 ：结合 Prometheus + Grafana 构建基于 Phoenix 指标的告警体系
- 与 CI/CD 集成 ：在部署流水线中集成 Phoenix 评估，实现 Prompt 变更的自动化回归测试

### 8.3 学习资源

**官方文档：**

- Phoenix 官方文档
- Dify 官方文档 - 集成 Phoenix
- OpenTelemetry 官方文档

**官方 GitHub：**

- Phoenix GitHub 仓库
- Dify GitHub 仓库
- OpenInference 项目

**官方博客：**

- Dify x Arize: How to Evaluate, Monitor, and Improve Agents

---
原文链接：https://mp.weixin.qq.com/s?__biz=MzU2OTc5NTU1NQ%3D%3D&mid=2247484672&idx=1&sn=035e2b63996192424db10c0c0425992f&chksm=fd0b94976091fc21993abb6dd0be2de70b1666696c0ccdfe0eaf5172330470631f33e40dfb8b
