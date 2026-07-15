---
source_url: "https://mp.weixin.qq.com/s?__biz=MzkwODY2NTk0OQ==&mid=2247485800&idx=1&sn=692c279092340fb018c6c8c05b0bc2b7&chksm=c1cdaf63f4892a3d803a3a42c878aa451a5105f9db43f946f9f4da23885b676508b9acf39d00&mpshare=1&scene=1&srcid=0406y4MSXBEmATioDLD8wVYW&sharer_shareinfo=2510bc929142867aadd5b7035c5e605f&sharer_shareinfo_first=2510bc929142867aadd5b7035c5e605f&hit_product=1"
title: "LoongCollector + ACS Agent Sandbox：构建 AI Agent 生产级运行平台"
account: "阿里云可观测"
published_at: "2026-04-06T10:51:43.000Z"
saved_at: "2026-07-15T17:04:42.459Z"
sync_id: "art_48f4930b2d72447cb7a0909d38917005"
parse_status: "ok"
---

# LoongCollector + ACS Agent Sandbox：构建 AI Agent 生产级运行平台

**01**

_**AI Agent 的安全与可观测性挑战**_

_Cloud Native_

随着大语言模型（LLM）的快速发展，AI Agent 正在从实验室走向生产环境。从智能客服到代码助手，从数据分析到自动化运维，AI Agent 正在改变我们的工作方式。然而，与传统应用不同，AI Agent 有两个特点：

- 行为不可预测 ： 同样的输入可能产生不同的输出，调用不同的工具链路。
- 具备执行能力 ： Agent 不仅能“说”，还能“做”——访问数据、调用 API、执行操作。

这两个特点，给我们带来了全新的挑战。

▍**核心挑战一：运行时安全（Agent 能做什么？谁来控制边界？）**

想象一下这个场景：一个客服 Agent 在回答用户问题时，因为 Prompt 注入攻击，意外访问了其他用户的订单信息，甚至调用了退款接口。这不是科幻，而是真实的安全风险。

AI Agent 的安全风险主要来自两个方面：

**1. 执行环境缺少强隔离**

Agent 在运行时需要访问数据、调用工具、执行操作，如果没有严格的权限控制，Prompt 注入或误触发就可能导致越权访问、数据泄露或误操作，比如 Agent 被注入恶意 Prompt，绕过权限检查，访问了不该访问的数据库。

**2. 外部能力缺少管控**

Agent 最大的威胁往往来自外部能力被滥用——异常外呼、SSRF/内网探测、敏感数据落盘或外传。比如 Agent 调用了一个“查询天气”的工具，但实际发起了对内网服务的扫描

▍**核心挑战二：全链路可观测（Agent 做了什么？为什么这么做？效果如何？）**

传统应用的行为是确定的，相同输入必然产生相同输出。但 AI Agent 不同——它的每一步决策都可能不同，这带来了三大可观测难题：

**1. 行为难以复现和定位**

同一个问题，Agent 今天可能调用工具 A，明天可能调用工具 B，后天可能直接回答。当出现错误时，很难知道“在哪一步出了问题”。

**2. 成本难以控制和归因**

Agent 的成本主要来自 LLM Token 消耗和外部 API 调用，且波动巨大。不知道哪些用户、哪些任务、哪些模型在“烧钱”。

**3. 质量难以度量和优化**

Agent 的输出质量受模型能力、Prompt 设计、检索数据等多重因素影响，且会不断变化。不知道“哪里好、哪里差、怎么改”。

▍**为什么需要专门的解决方案？**

传统的监控和安全方案在 AI Agent 场景下力不从心：

![图片](附件资源/LoongCollector%20+%20ACS%20Agent%20Sandbox：构建%20AI%20Agent%20生产级运行平台/img_1.png)

这就是为什么我们需要专门为 AI Agent 设计的运行平台和可观测方案。接下来，让我们看看 ACS Agent Sandbox 和 LoongCollector 如何解决这些挑战和问题。

**02**

_**ACS Agent Sandbox **_

_**与 LoongCollector：**_

_**安全与可观测的完整保障**_

_Cloud Native_

ACS Agent Sandbox 提供了基于 Kubernetes 的安全运行环境，而 LoongCollector 则作为可观测数据采集器，为 Agent 提供全方位的监控和分析能力。两者的深度集成，构建了一个完整的 AI Agent 生产级运行平台。

▍**2.1 ACS Agent Sandbox：提供运行时安全保障**

ACS（Alibaba Cloud Container Service）Agent Sandbox 是阿里云容器服务推出的 AI Agent 运行沙箱环境。它基于 Kubernetes 提供了一个**安全、隔离、可扩展**的 AI Agent 运行平台。

![图片](附件资源/LoongCollector%20+%20ACS%20Agent%20Sandbox：构建%20AI%20Agent%20生产级运行平台/img_2.png)

▍**2.2 LoongCollector：提供 Sandbox 可观测能力保障**

LoongCollector 是阿里云可观测团队开源的统一可观测数据采集器，专为云原生和高性能场景设计。在 AI Agent 场景，它具有独特优势：

![图片](附件资源/LoongCollector%20+%20ACS%20Agent%20Sandbox：构建%20AI%20Agent%20生产级运行平台/img_3.webp)

### 极致性能与超低开销

AI Agent 计算密集，可观测组件必须轻量不拖累业务：

- 零拷贝架构：Memory Arena + Zero-Copy，减少不必要的内存拷贝。
- 事件池化复用：高频对象池化，降低内存分配与 GC 压力。
- 单核高吞吐：单核可支撑 500MB/s 日志采集吞吐。

### 一体化采集：日志 / 指标 / 链路全覆盖

- 日志：stdout/stderr、文件日志；自动关联 Kubernetes 元信息（Pod/Namespace/Labels）。
- 指标：原生支持 Prometheus Exporter；系统指标（CPU/内存/网络/磁盘 I/O）；GPU 指标（NVIDIA DCGM）。
- 链路：完整支持 OpenTelemetry。

### 端侧计算：把处理前置到数据源头

不仅采集，更能在端侧完成预处理，降低传输与存储成本：

- 高性能 C++ 插件/SPL 引擎。
- 支持过滤、转换、聚合等复杂处理。
- 端侧降维：在源头减少噪声与数据量。

### 企业级可靠性：数据不丢、运行稳定

**数据可靠性****：**

- At-Least-Once 投递语义。
- 本地磁盘缓存：网络异常落盘，恢复后重传。
- 自动重试 + 指数退避。
- 反压限流：下游拥塞时保护系统。

**运行可靠性****：**

- 多租户 Pipeline 隔离。
- 优先级调度：关键数据优先。
- 热更新/优雅变更：配置变更无需重启、零中断。

### 大规模弹性场景统一管控

- ConfigServer：集中配置管理，支撑万级 Agent。
- 远程配置下发：变更实时生效，无需登录机器。
- 状态与性能监控：统一查看健康度与资源开销。

▍**2.3 深度集成：LoongCollector 为 Sandbox 提供零侵入、自动化、高可靠的可观测能力**

![图片](附件资源/LoongCollector%20+%20ACS%20Agent%20Sandbox：构建%20AI%20Agent%20生产级运行平台/img_4.webp)

- ACS 管控会自动为 Sandbox 注入 LoongCollector 容器。

- 通过挂载共享文件路径。
- 通过 Pod 网络，可以对 AI Agent 进行 Prometheus 抓取或者接收 OpenTelemetry 数据。

通过 ACS Agent Sandbox 与 LoongCollector 的深度集成，我们为 AI Agent 构建了一个完整的生产级运行平台：

![图片](附件资源/LoongCollector%20+%20ACS%20Agent%20Sandbox：构建%20AI%20Agent%20生产级运行平台/img_5.webp)

**03**

_**基于 ACS Agent Sandbox **_

_**+ LoongCollector**_

_**运行 OpenClaw 的方案**_

_Cloud Native_

OpenClaw 是最近爆火的一个 AI 应用，它重新定义了 AI 助理的边界——其核心价值不再是回答问题，而是真正理解意图、规划步骤并调用工具去完成任务，成为一个永不下线的“数字员工”。接下来，我们就看下如何使用 ACS Agent Sandbox + LoongCollector，安全、可观测的运行 OpenClaw。

▍**3.1 开启 ACK/ACS 集群 Sandbox LoongCollector 注入**

### ACK 集群

PS：需要预先安装组件

- 组件管理 中安装 LoongCollector 组件。

- 组件管理 中安装 ACK Virtual Node 组件。
- 组件管理 中安装 ack-agent-sandbox-controller 组件，版本>=v0.5.3。
- 如果需要通过 eip 暴露服务，则需要在应用市场 中安装 ack-extend-network-controller 组件。具体配置方案参考 帮助文档 （ https://help.aliyun.com/zh/ack/ack-managed-and-ack-dedicated/user-guide/associate-an-eip-with-a-pod-1 ） 。

修改 kube-system 下，eci-profile 这个 configmap ，其中 slsMachineGroup 即为 Sandbox 机器组标识，建议设置一个单独的标识，不要跟 ACK 的 daemonset 机器组一样。

### ACS 集群

PS：需要预先安装组件

- 组件管理 中安装 ack-agent-sandbox-controller 组件，版本>=v0.5.3。
- 如果需要通过 eip 暴露服务，则在 ACK 集群的 组件管理 中安装 ack-extend-network-controller 组件。
- 组件管理 中安装 alibaba-log-controller 组件。

机器组标识为 ACS 集群统一机器组标识：k8s-log-${集群 id}

▍**3.2 在 ACS Agent Sandbox 中的部署 OpenClaw**

### OpenClaw 开启 Otel 插件

**需要注意**

- OpenClaw 打包镜像的时候，需要包含 extensions/diagnostics-otel。
- 需要在配置中打开 diagnostics-otel，才能进行指标和 Trace 数据的上报。

配置** **~/.openclaw/openclaw.json********

**PS：需要注意这里配置的 endpoint，需要在后面 LoongCollector 采集配置中用到。**

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
-
-
-
-

```
{  "plugins": {    "allow": ["diagnostics-otel"],    "entries": {      "diagnostics-otel": { "enabled": true }    }  },  "diagnostics": {    "enabled": true,    "otel": {      "enabled": true,      "endpoint": "http://127.0.0.1:4318",      "protocol": "http/protobuf",      "serviceName": "openclaw-gateway",      "traces": true,      "metrics": true,      "logs": true,      "sampleRate": 1,      "flushIntervalMs": 60000    }  }}
```

### OpenClaw沙箱部署样例

这里我以一个最简化的部署为例，通过 Sandbox CR 直接创建 OpenClaw 沙箱：

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
apiVersion: agents.kruise.io/v1alpha1kind: Sandboxmetadata:  name: openclaw  namespace: defaultspec:  template:    metadata:      labels:        alibabacloud.com/acs: 'true'        app: openclaw    spec:      containers:        - name: openclaw          # 请替换为实际的 OpenClaw 镜像地址          image:            imagePullPolicy: IfNotPresent           resources:            limits:              cpu: '4'              memory: 8Gi            requests:              cpu: '4'              memory: 8Gi          securityContext:            readOnlyRootFilesystem: false          terminationMessagePath: /dev/termination-log          terminationMessagePolicy: File      dnsPolicy: ClusterFirst      paused: true      restartPolicy: Always      schedulerName: default-scheduler      securityContext: {}      terminationGracePeriodSeconds: 1
```

▍**3.3 完整可观测采集配置**

从《[你的 OpenClaw 真的在受控运行吗？](https://mp.weixin.qq.com/s?__biz=MzUzNzYxNjAzMg==&mid=2247582344&idx=1&sn=7d5c0a6f1d886879a52e8f4fe1c97e6e&scene=21#wechat_redirect)》可以看到，OpenClaw 对应的可观测数据如下：

![图片](附件资源/LoongCollector%20+%20ACS%20Agent%20Sandbox：构建%20AI%20Agent%20生产级运行平台/img_6.webp)

### Session 日志

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
apiVersion: telemetry.alibabacloud.com/v1alpha1kind: ClusterAliyunPipelineConfigmetadata:  name: openclaw-session-logspec:  config:    aggregators: []    global: {}    inputs:      - Type: input_file        # 这里的路径根据镜像openclaw的运行路径不同而不同        FilePaths:          - /home/node/.openclaw/agents/main/sessions/*.jsonl        MaxDirSearchDepth: 0        FileEncoding: utf8        EnableContainerDiscovery: true        # 根据OpenClaw沙箱信息进行容器过滤        ContainerFilters:          K8sPodRegex: ^(openclaw.*)$    processors:      - Type: processor_parse_json_native        SourceKey: content    flushers:      - Type: flusher_sls        Logstore: openclaw-session-log    sample: ''  # 请替换为 ACK/ACS 集群对应的 Sandbox 机器组名称  machineGroups:    - name:   # 要采集到的Project  project:    name: k8s-log-xxx  # 要采集到的logstore  logstores:    - name: openclaw-session-log
```

### 应用日志

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
apiVersion: telemetry.alibabacloud.com/v1alpha1kind: ClusterAliyunPipelineConfigmetadata:  name: openclaw-app-logspec:  config:    aggregators: []    global: {}    inputs:      - Type: input_file        FilePaths:          - /tmp/openclaw/*.log        MaxDirSearchDepth: 0        FileEncoding: utf8        EnableContainerDiscovery: true        # 根据OpenClaw沙箱信息进行容器过滤        ContainerFilters:          K8sPodRegex: ^(openclaw.*)$    processors:      - Type: processor_parse_json_native        SourceKey: content    flushers:      - Type: flusher_sls        Logstore: openclaw-app-log    sample: ''  # 请替换为 ACK/ACS 集群对应的 Sandbox 机器组名称  machineGroups:    - name:   # 要采集到的Project  project:    name: k8s-log-xxx  # 要采集到的logstore  logstores:    - name: openclaw-app-log
```

### OpenTelemetry

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
-
-
-

```
apiVersion: telemetry.alibabacloud.com/v1alpha1kind: ClusterAliyunPipelineConfigmetadata:  name: openclaw-otel-configspec:  config:    # 这里跟下面的logstores对应，分布存储Opentelemetry的日志、指标、Trace数据    aggregators:      - Type: aggregator_opentelemetry        MetricsLogstore: openclaw-otel-metrics        TraceLogstore: openclaw-otel-traces        LogLogstore: openclaw-otel-logs    global: {}    inputs:      - Type: service_otlp        Protocals:          HTTP:            # 这里跟OpenClaw开启的diagnostics-otel的endpoint对应            Endpoint: '127.0.0.1:4318'            ReadTimeoutSec: 10            ShutdownTimeoutSec: 5            MaxRecvMsgSizeMiB: 64    processors: []    flushers:      - Type: flusher_sls        Logstore: openclaw-otel-logs  # 请替换为 ACK/ACS 集群对应的 Sandbox 机器组名称  machineGroups:    - name:   # 要采集到的Project  project:    name: k8s-log-xxx  # 要采集到的logstore，需要注意Opentelemetry有三类数据，需要定义三个logstore  # metrics数据需要指定telemetryType: Metrics  logstores:    - name: openclaw-otel-logs    - name: openclaw-otel-metrics      telemetryType: Metrics    - name: openclaw-otel-traces
```

▍**3.4 方案总结：完整解决 OpenClaw 的安全挑战**

### Sandbox 实现 OpenClaw 安全、隔离运行

- 单 Sandbox 运行在独立内核沙箱环境，避免恶意代码攻击主机系统程序。
- 单 Sandbox 独立隔离临时文件系统，避免读取/篡改/删除主机文件。

### LoongCollector 实现 OpenClaw 全栈可观测

![图片](附件资源/LoongCollector%20+%20ACS%20Agent%20Sandbox：构建%20AI%20Agent%20生产级运行平台/img_7.png)

**04**

_**总结与展望**_

_Cloud Native_

AI Agent 的生产化不是“能不能”的问题，而是“怎么做”的问题。安全与可观测不是可选项，而是必选项。

如果你正在构建 AI Agent 应用：

- 从现在开始 重视运行时安全和可观测性。
- 选择合适的工具 而不是重复造轮子。
- 建立最佳实践 并在团队中推广。
- 持续学习优化 ， 让 Agent 真正创造价值。

ACS Agent Sandbox 和 LoongCollector 都是开放的平台，欢迎你尝试并反馈。让我们一起构建更安全、更可靠、更高效的 AI Agent 生产环境。希望本文能够为你的 AI Agent 可观测性建设提供参考和启发。

## 参考资料：

- 《 [你的 OpenClaw 真的在受控运行吗？](https://mp.weixin.qq.com/s?__biz=MzUzNzYxNjAzMg==&mid=2247582344&idx=1&sn=7d5c0a6f1d886879a52e8f4fe1c97e6e&scene=21#wechat_redirect) 》

- LoongCollector 开源项目 https://github.com/alibaba/loongcollector
- 阿里云日志服务 SLS https://www.aliyun.com/product/sls
- 面向智算服务构建下一代可观测 Pipeline https://developer.aliyun.com/article/1440374

![图片](http://mmbiz.qpic.cn/mmbiz_png/h6RT2cavUBStFESpDgicub0zQtxO2Oj4DQ9Kdz25SRDYHbqf8ESDj8cKK6IPYFnHOb2VicngZWXfK9tMbJ0G3wtQ/640?wx_fmt=other&wxfrom=10005&wx_lazy=1&wx_co=1&tp=webp#imgIndex=20)

---
原文链接：https://mp.weixin.qq.com/s?__biz=MzkwODY2NTk0OQ%3D%3D&mid=2247485800&idx=1&sn=692c279092340fb018c6c8c05b0bc2b7&chksm=c1cdaf63f4892a3d803a3a42c878aa451a5105f9db43f946f9f4da23885b676508b9acf39d00
