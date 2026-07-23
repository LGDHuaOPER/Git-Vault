---
title: "通过 AI Agent 接入 AgentLoop 应用监控"
source: "https://help.aliyun.com/zh/document_detail/3046111.html?spm=a2c4g.11186623.help-menu-3033820.d_2_0.ec8e543eHQrEi9"
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
"word-count": "3787"
更新时间: "2026-07-11 11:48:32"
---
接入 AgentLoop 应用监控通常需要逐步完成 Workspace 配置、APM 初始化、服务注册和探针注入。alibabacloud-agentloop-management Skill 将这一流程封装为 AI Agent 可执行的结构化工作流——将该 Skill 安装到 QoderWork、Cursor 或 Claude Code 后，只需用一句自然语言描述接入需求，Agent 即可自动编排并执行全流程接入。接入完成后，可通过控制台查看以下监控数据：

-   **服务端应用**：应用拓扑、接口调用、异常事务、慢事务等 APM 数据
    
-   **AI 应用**：LLM 调用耗时、Token 使用量、Agent 链路、工具调用（Tool Call）等 AI 可观测指标
    

**说明**

AI Agent 接入是对传统控制台接入流程的智能化封装，底层使用 AgentLoop CLI 与标准探针方案（如 ack-onepilot、AliyunJavaAgent、aliyun-bootstrap、instgo、OpenTelemetry 等）。针对 AI Coding Agent 运行数据采集的场景，可使用 LoongSuite Pilot 方式接入（[AI 应用接入：AI Coding Agent](https://help.aliyun.com/zh/document_detail/3033878.html)），两者是独立的接入路径。若应用部署于容器服务 ACK 或 ACS，请确保集群已[通过 ack-onepilot 组件安装探针](https://help.aliyun.com/zh/cms/cloudmonitor-2-0/install-the-arms-agent-for-java-applications-deployed-in-ack-and-acs-clusters-by-using-the-ack-onepilot-component)并完成授权。

**重要**

AI Agent 由大语言模型驱动，可能存在命令参数错误、资源识别偏差等模型幻觉风险。尽管 Skill 内置了两阶段确认机制，仍需在批准执行前仔细核对 Agent 生成的命令与目标资源。接入操作可能涉及集群组件变更、应用重启等影响生产的变更，建议先在测试环境完成接入验证与效果评估，确认探针对应用性能与稳定性的影响可接受后，再在生产环境使用。

## 适用场景

根据应用类型，Agent 会自动选择对应的探针与接入路径：

| **应用类型** | **典型技术栈** | **关注指标** | **典型部署环境** |
| --- | --- | --- | --- |
| **服务端应用** | Java、Golang、Python、Node.js 等微服务 | 接口 QPS/RT、应用拓扑、慢事务 | ACK/ACS、ECS |
| **AI 应用** | LangChain、DashScope、Dify、AgentScope 等 | LLM 调用、Token 用量、Agent 链路 | ACK/ACS、ECS |

## AI Agent 接入说明

alibabacloud-agentloop-management Skill 将 AgentLoop CLI 的接入流程封装为 AI Agent 可执行的结构化工作流，核心能力包括：

-   **自然语言驱动**：用一句话描述接入需求，无需记忆 CLI 命令与参数。
    
-   **场景感知**：根据应用类型、语言、部署环境（ECS、ACK/ACS）自动选择探针方案。
    
-   **自动编排**：完成 Workspace 确认、APM 初始化、凭证获取、服务注册与探针配置。
    
-   **安全可控**：对 Patch Deployment、修改启动参数等变更操作执行两阶段确认，用户审核后再执行。
    

典型工作流程：

1.  用户描述接入需求（Workspace、应用类型、语言/框架、应用名、部署环境）。若未提供符合 `agentloop-{32位编码}` 格式的 Workspace，Agent 会主动询问。
    
2.  Agent 检查 CLI 环境与凭证，初始化 APM 基础设施。
    
3.  Agent 生成执行计划，展示命令、影响范围与回滚方式。
    
4.  用户确认后，Agent 执行探针注入或启动参数变更。
    
5.  Agent 验证接入结果，引导用户通过控制台查看监控数据。
    

## 支持的探针方案

### 服务端应用

AI Agent 会根据应用语言与部署环境，自动选择以下接入方式之一：

| **语言** | **ack-onepilot（K8s）** | **自研探针** | **OpenTelemetry** |
| --- | --- | --- | --- |
| Java | 支持  | AliyunJavaAgent | OTel Java Agent |
| Golang | 支持  | instgo | OTel Go SDK |
| Python | 支持  | aliyun-bootstrap | opentelemetry-instrument |
| Node.js | —   | @loongsuite/cms\\_node\\_sdk | OTel Node SDK |
| PHP | —   | —   | OTel PHP extension |
| .NET | —   | —   | OTel .NET Auto-Instrument |

K8s 场景下优先使用 ack-onepilot 无侵入注入，无需修改应用代码或 Dockerfile。ECS 场景下通常通过修改 JVM 启动参数（Java）或安装探针包（Golang/Python）完成接入。

### AI 应用

| **AI 框架** | **底层探针** | **典型部署环境** |
| --- | --- | --- |
| LangChain / LangGraph | Python aliyun-bootstrap | ACK/ACS、ECS |
| DashScope | Python aliyun-bootstrap | ACK/ACS、ECS |
| AgentScope | Python aliyun-bootstrap | ACK/ACS、ECS |
| OpenAI SDK | Python aliyun-bootstrap | ACK/ACS、ECS |
| Dify | Dify 内置 OTel | 自建部署、K8s |
| Coze | Golang instgo | ACK/ACS、ECS |
| OpenClaw / CoPaw / Hermes | 专用 installer 脚本 | 视具体方案 |

Python 系 AI 框架在 K8s 场景下通常通过 ack-onepilot 自动注入 `aliyun-bootstrap` 探针。Dify 等已内置 OpenTelemetry 的应用，Agent 将引导配置 OTel Exporter 指向 AgentLoop Endpoint，无需通过 ack-onepilot 注入。

## 前提条件

| **条件** | **说明** |
| --- | --- |
| 阿里云账号 | 已开通 AgentLoop，并对目标 Workspace 具有管理权限 |
| AgentLoop Workspace | 必填，格式为 `agentloop-` 加 32 位编码（例如 `agentloop-2694ecf8****************1f84542d`） |
| 阿里云 CLI | 版本 ≥ 3.3.15，已安装 `cms2` 插件。安装方式见下方步骤一 |
| CLI 凭证 | 已通过 `aliyun configure` 配置 AccessKey。配置方式见下方步骤一 |
| AI Agent | 已安装 QoderWork、Cursor、Claude Code 或其他支持 Agent Skill 的工具。Skill 安装方式见下方步骤二 |
| K8s 场景 | ACK/ACS 集群已安装 ack-onepilot（版本 ≥ 5.1.0）并完成 ARMS 资源授权 |
| ECS 场景 | 目标 ECS 实例可通过 Cloud Assistant 或 SSH 执行命令 |

**重要**

K8s 场景下 ack-onepilot 接入涉及集群组件的安装或配置变更，以及为目标应用添加 Label 后触发的 Pod 滚动重启，可能对运行中的业务或 AI 推理服务产生影响。

## 步骤一：安装并配置 CLI 环境

若尚未[安装阿里云 CLI](https://help.aliyun.com/zh/cli/install-update-alibaba-cloud-cli)，请先完成安装。

```
# 确认 CLI 版本 >= 3.3.15
aliyun version

# 验证 cms2 插件可用
aliyun cms2 --help
```

若 `cms2` 命令不可用：

```
aliyun plugin update
```

配置访问凭证：

```
aliyun configure
```

**说明**

建议使用 RAM 子账号，并授予 AgentLoop（`cms2` API）、ARMS、容器服务等必要权限。K8s 场景下，托管集群通常通过 ARMS Addon Token 免密授权；专有版集群或 ACS 集群可能需要通过 ack-onepilot 配置 AK/SK，详情见[通过 ack-onepilot 组件安装 Java 探针](https://help.aliyun.com/zh/cms/cloudmonitor-2-0/install-the-arms-agent-for-java-applications-deployed-in-ack-and-acs-clusters-by-using-the-ack-onepilot-component)的授权章节。

## 步骤二：安装 alibabacloud-agentloop-management Skill

1.  打开 Skill 市场页面：[alibabacloud-agentloop-management](https://skills.aliyun.com/skills/alibabacloud-agentloop-management)。
    
2.  根据页面指引，将 Skill 安装到 Cursor、Claude Code 或 QoderWork。
    
3.  安装完成后，重启 AI 助手或通过对话确认 Skill 已加载。
    

自然语言触发示例：

| **触发关键词示例** | **对应能力** |
| --- | --- |
| "接入 Java 应用"、"Spring Boot 监控" | Java 服务端应用 K8s/ECS 接入 |
| "Golang 探针接入"、"instgo" | Golang 应用接入 |
| "LangChain 接入"、"LangGraph 监控" | Python AI 应用 K8s/ECS 接入 |
| "DashScope 应用接入 AgentLoop" | 通义千问 SDK 应用接入 |
| "AI Agent 监控"、"LLM 调用监控" | AI 可观测指标采集 |
| "Dify 接入 OpenTelemetry" | Dify OTel 配置引导 |
| "ack-onepilot 接入 APM" | K8s 容器无侵入探针注入 |
| "ECS 上安装 Java 探针" | ECS 裸机 AliyunJavaAgent 接入 |

## 步骤三：使用自然语言发起接入

描述接入需求时，建议包含以下信息（缺失时 Agent 会自动探测或询问）：

| **信息** | **是否必填** | **示例** |
| --- | --- | --- |
| AgentLoop Workspace | 是   | `agentloop-2694ecf8****************1f84542d` |
| 应用类型 / 语言 / 框架 | 是   | Java、LangChain、DashScope、Dify |
| 应用名称 | 是   | `order-service`、`customer-support-agent` |
| 部署环境 | 是   | ACK 集群、ECS |
| 集群/实例信息 | 视场景 | 命名空间/Deployment 名称、ECS 实例 ID |
| 地域  | 可选  | 需单独提供，或从集群信息自动推导 |

### 服务端应用示例

**K8s 中 Java 应用：**

```
将 ACK 集群 default 命名空间下的 order-service 部署接入 AgentLoop APM，语言是 Java，Workspace 是 agentloop-2694ecf8****************1f84542d
```

**ECS 上 Java 应用：**

```
帮我在 ECS 实例 i-bp1xxxxxxxxxx 上为 Spring Boot 应用 order-api 接入 APM 监控，Workspace 是 agentloop-2694ecf8****************1f84542d
```

**K8s 中 Golang 应用：**

```
帮我把 ACK 集群里的 Golang 微服务 payment-service 接入 AgentLoop 应用监控，Workspace 是 agentloop-2694ecf8****************1f84542d
```

### AI 应用示例

**K8s 中 LangChain 应用：**

```
帮我把 ACK 集群里的 LangChain 应用 customer-support-agent 接入 AgentLoop 监控，Workspace 是 agentloop-2694ecf8****************1f84542d
```

**DashScope 应用 ECS 接入：**

```
帮我在 ECS 上为 DashScope 对话应用 qa-bot 接入 AgentLoop AI 可观测监控，Workspace 是 agentloop-2694ecf8****************1f84542d
```

**Dify 自建部署：**

```
我的 Dify 部署在 K8s 上，帮我配置 OpenTelemetry 上报到 AgentLoop，Workspace 是 agentloop-2694ecf8****************1f84542d
```

## 步骤四：确认执行计划并完成接入

Agent 生成执行计划后，会展示目标资源、具体命令、影响范围与回滚方式，等待确认后才执行变更操作。

### 两阶段确认协议

| **阶段** | **行为** |
| --- | --- |
| **Phase A（计划）** | 展示目标资源、具体命令、影响范围与回滚方式，结束当前轮次等待确认 |
| **Phase B（执行）** | 仅在用户明确批准（如回复"yes"或"确认"）后执行 |

只读命令（`get`、`list`）与幂等初始化（`apm configuration create`）无需确认，Agent 可直接执行。

K8s 场景下，Agent 完成 APM 初始化和服务注册后，将通过 Patch Deployment 为 Pod Template 添加 Label 触发 ack-onepilot 自动注入探针。详细执行流程参见 [Agent 执行流程参考](#h2-agent-01)，Label 配置说明参见 [K8s 接入 Label 配置参考](#h2-k8s-lab-01)。

### ECS 场景接入说明

ECS 场景下，Agent 将通过 Cloud Assistant 或 SSH 在目标实例上执行以下操作：

1.  下载并解压对应语言探针（如 AliyunJavaAgent、aliyun-bootstrap）。
    
2.  配置探针属性（LicenseKey、AppName、Workspace）。
    
3.  修改应用启动参数或环境变量。
    
4.  重启应用并验证探针加载。
    

Java 应用 JVM 启动参数示例：

```
java -javaagent:/opt/arms/AliyunJavaAgent/aliyun-java-agent.jar \
  -Darms.licenseKey=<LicenseKey> \
  -Darms.appName=order-api \
  -Darms.workspace=agentloop-2694ecf8****************1f84542d \
  -jar app.jar
```

**重要**

ECS 接入涉及修改应用启动脚本并重启进程，Agent 会通过执行计划明确列出变更内容与回滚步骤。

### Dify 等非 ack-onepilot 场景

Dify 内置 OpenTelemetry 支持，Agent 将引导配置 OTel Exporter，将 Trace 数据上报至 AgentLoop APM Endpoint（LicenseKey + Endpoint 由 `apm configuration get` 获取），无需通过 ack-onepilot 注入。

接入完成后，Agent 会提示等待 2～3 分钟，然后通过控制台查看监控数据。

## 步骤五：验证接入结果

### 通过 CLI 验证

```
aliyun cms2 apm service list \
    --workspace agentloop-2694ecf8****************1f84542d \
    --service-name <应用名称> \
    --region cn-hangzhou
```

成功标准：应用出现于服务列表，状态为 Running。

### 通过 K8s 验证（容器场景）

```
kubectl rollout status deployment/<deployment-name> -n <namespace>

kubectl get pods -n <namespace> -l app=<app-label> \
  -o jsonpath='{range .items[*]}{.metadata.name}: initContainers={.spec.initContainers[*].name}{"\n"}{end}'

kubectl logs -n <namespace> -l app=<app-label> --tail=30 | grep -i "arms\|OneAgent\|bootstrap\|agent"
```

### 通过 ECS 验证

```
# Java 应用：确认进程中已加载 ARMS Agent
ps aux | grep "aliyun-java-agent" | grep -v grep
```

## 查看控制台监控数据

1.  登录 [AgentLoop 控制台](https://cmsnext.console.aliyun.com/)。
    
2.  选择目标 **Workspace**。
    
3.  在左侧导航栏选择**所有功能** > **应用可观测** > **应用监控**。
    
4.  单击目标应用名称，查看监控数据：
    
    -   **服务端应用**：应用拓扑、接口调用（QPS/RT/错误率）、异常事务、慢事务
        
    -   **AI 应用**：LLM 调用（模型名称、耗时、成功率）、Token 统计、Agent 链路、Tool Call 拓扑、异常追踪
        

## Agent 执行流程参考

以下以 K8s 场景为例，展示 Agent 接到确认指令后的典型执行流程，仅供了解 Agent 的内部行为，无需手动执行这些命令。Java 服务端与 Python AI 应用步骤相同，仅 Label 的语言标识不同。

**（1）获取账号与集群信息**

```
aliyun sts get-caller-identity --force -o json
aliyun cs describe-clusters
```

**（2）初始化 APM 基础设施并获取凭证**

```
aliyun cms2 apm configuration create \
    --workspace agentloop-2694ecf8****************1f84542d \
    --region cn-hangzhou

aliyun cms2 apm configuration get \
    --workspace agentloop-2694ecf8****************1f84542d \
    --region cn-hangzhou -o json
```

返回的 `authToken` 即为 LicenseKey，`publicDomain` / `privateDomain` 为数据上报 Endpoint。

**（3）注册应用服务**

```
# 服务端 Java 应用示例
aliyun cms2 apm service create \
    --workspace agentloop-2694ecf8****************1f84542d \
    --region cn-hangzhou \
    --body '{"serviceName":"order-service","serviceType":"TRACE","attributes":"{\"language\":\"java\"}"}' \
    < /dev/null

# AI Python 应用示例
aliyun cms2 apm service create \
    --workspace agentloop-2694ecf8****************1f84542d \
    --region cn-hangzhou \
    --body '{"serviceName":"customer-support-agent","serviceType":"TRACE","attributes":"{\"language\":\"python\"}"}' \
    < /dev/null
```

**（4）检查 ack-onepilot 组件状态**

```
kubectl get pods -n ack-onepilot
```

**（5）Patch Deployment 注入探针**

Java 服务端应用：

```
kubectl patch deployment order-service -n default \
    --type=strategic -p '{
      "spec":{"template":{"metadata":{"labels":{
        "aliyun.com/app-language":"java",
        "armsPilotAutoEnable":"on",
        "armsPilotCreateAppName":"order-service",
        "armsPilotAppWorkspace":"agentloop-2694ecf8****************1f84542d"
      }}}}}
    }'
```

Python AI 应用（LangChain / DashScope 等）：

```
kubectl patch deployment customer-support-agent -n default \
    --type=strategic -p '{
      "spec":{"template":{"metadata":{"labels":{
        "aliyun.com/app-language":"python",
        "armsPilotAutoEnable":"on",
        "armsPilotCreateAppName":"customer-support-agent",
        "armsPilotAppWorkspace":"agentloop-2694ecf8****************1f84542d"
      }}}}}
    }'
```

**（6）验证滚动更新**

```
kubectl rollout status deployment/<deployment-name> -n <namespace> --timeout=120s
```

接入完成后，Agent 会提示等待 2～3 分钟，然后通过控制台查看监控数据。

**重要**

Patch Deployment 添加 Label 后会触发应用 Pod 滚动重启。受 AI 模型幻觉影响，Agent 可能误识别集群、命名空间或 Deployment 名称，或在 Label、Workspace 等参数上出现偏差，请在批准执行前逐项核对 Agent 生成的命令与目标资源。

## K8s 接入 Label 配置参考

K8s 场景下，AI Agent 通过为 Pod Template 添加 Label 触发 ack-onepilot 自动注入探针。Label 必须添加在 `spec.template.metadata.labels` 层级（Pod Template），而非 Deployment 的 `metadata.labels`。

```
labels:
  armsPilotAutoEnable: "on"
  armsPilotCreateAppName: "<应用名称>"
  armsPilotAppWorkspace: "<Workspace 名称>"
  aliyun.com/app-language: "<语言>"   # 如 java、golang、python
```

完整 YAML 示例（Java 服务端应用）：

```
apiVersion: apps/v1
kind: Deployment
metadata:
  name: order-service
  namespace: default
spec:
  replicas: 2
  selector:
    matchLabels:
      app: order-service
  template:
    metadata:
      labels:
        app: order-service
        armsPilotAutoEnable: "on"
        armsPilotCreateAppName: "order-service"
        armsPilotAppWorkspace: "agentloop-2694ecf8****************1f84542d"
        aliyun.com/app-language: java
    spec:
      containers:
        - name: order-service
          image: registry.example.com/order-service:latest
          ports:
            - containerPort: 8080
```

完整 YAML 示例（Python AI 应用）：

```
apiVersion: apps/v1
kind: Deployment
metadata:
  name: customer-support-agent
  namespace: default
spec:
  replicas: 2
  selector:
    matchLabels:
      app: customer-support-agent
  template:
    metadata:
      labels:
        app: customer-support-agent
        armsPilotAutoEnable: "on"
        armsPilotCreateAppName: "customer-support-agent"
        armsPilotAppWorkspace: "agentloop-2694ecf8****************1f84542d"
        aliyun.com/app-language: python
    spec:
      containers:
        - name: customer-support-agent
          image: registry.example.com/customer-support-agent:latest
          ports:
            - containerPort: 8000
```

**重要**

使用 AI Agent 生成或执行 Label 配置时，请逐项核对应用名称、Workspace 及语言参数是否与预期一致。

## 常见问题

### Agent 提示 cms2 命令不可用

**原因**：CLI 版本过低或未安装 cms2 插件。

**解决方法**：

```
aliyun upgrade -y
aliyun plugin update
aliyun cms2 --help
```

### K8s 场景下 Pod 未注入探针

**原因**：ack-onepilot 未安装、版本过低，或 ARMS 授权未完成。

**解决方法**：

1.  确认 ack-onepilot 版本 ≥ 5.1.0。
    
2.  检查 `kubectl get pods -n ack-onepilot` 输出是否正常。
    
3.  确认集群 ARMS Addon Token 或 AK/SK 授权已配置。
    
4.  确认 `aliyun.com/app-language` 与实际应用语言一致。
    
5.  确认 Label 添加在 Pod Template 层级。
    

### Pod CrashLoopBackOff

**原因**：探针注入失败或探针与应用运行环境不兼容。

**解决方法**：

1.  查看 initContainer 日志排查注入失败原因。
    
2.  确认 `aliyun.com/app-language` 与实际应用语言一致。
    
3.  在测试环境验证通过后，再重新执行接入。
    

### 探针已加载但控制台无数据

**原因**：LicenseKey、Workspace 或 Endpoint 配置错误，或网络不通。

**解决方法**：

1.  重新执行 `aliyun cms2 apm configuration get` 核对凭证。
    
2.  确认 `armsPilotAppWorkspace` Label 值与 Workspace 名称一致。
    
3.  检查集群/ECS 到 APM Endpoint 的网络连通性（VPC 内网建议使用 privateDomain）。
    
4.  触发一次业务请求或 LLM 调用后等待 2～3 分钟再查看控制台。
    

### AI 应用接入后看不到 LLM 调用数据

**原因**：探针未正确加载，或 AI 框架尚未被探针识别。

**解决方法**：

1.  确认 Pod 中 ack-onepilot 已成功注入 initContainer。
    
2.  确认应用使用的是 aliyun-bootstrap 支持的 Python AI 框架（LangChain、DashScope 等）。
    
3.  触发一次 LLM 调用后等待 2～3 分钟再查看控制台。
    
4.  查看应用日志中是否有探针初始化成功的输出。
    

### 如何回滚接入

**K8s 场景**：移除 ARMS 相关 Label 后 Pod 会重新滚动，探针注入即被移除。

```
kubectl patch deployment <deployment-name> -n <namespace> \
    --type json \
    --patch '[
      {"op": "remove", "path": "/spec/template/metadata/labels/armsPilotAutoEnable"},
      {"op": "remove", "path": "/spec/template/metadata/labels/armsPilotCreateAppName"},
      {"op": "remove", "path": "/spec/template/metadata/labels/armsPilotAppWorkspace"}
    ]'
```

**ECS 场景**：移除启动参数中的 `-javaagent` 及相关 `-Darms.*` 配置，重启应用即可。