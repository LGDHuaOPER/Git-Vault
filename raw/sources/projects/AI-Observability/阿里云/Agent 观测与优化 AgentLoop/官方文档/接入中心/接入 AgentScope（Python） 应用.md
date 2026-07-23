---
title: "接入 AgentScope（Python） 应用"
source: "https://help.aliyun.com/zh/document_detail/3042583.html?spm=a2c4g.11186623.help-menu-3033820.d_2_2.2fe3121beh3IVm"
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
"word-count": "1571"
更新时间: "2026-06-25 11:29:26"
---
大模型可观测支持通过Python探针对AgentScope应用进行可观测，Python探针是阿里云可观测产品自研的Python语言的可观测采集探针，其基于OpenTelemetry标准实现了自动化埋点能力。本文介绍如何将AgentScope应用接入云监控2.0，以帮助用户实时了解 AI 应用运行状态。

大模型可观测支持通过Python探针对AgentScope应用进行可观测，Python探针是阿里云可观测产品自研的Python语言的可观测采集探针，其基于OpenTelemetry标准实现了自动化埋点能力。本文介绍如何将AgentScope应用接入ARMS应用监控，以帮助用户实时了解 AI 应用运行状态。

## **框架介绍**

[AgentScope](https://github.com/agentscope-ai/agentscope) 是阿里巴巴开源的多 Agent 应用开发框架，提供 ReActAgent 等多种 Agent 类型，内置 DashScope、OpenAI 等模型适配器，支持工具调用、记忆管理和多 Agent 协作。

接入后，以下能力将被自动监控：

-   Agent 执行链路
    
-   LLM 调用（模型调用的 Token 用量、输入/输出内容）
    
-   工具调用链路（Toolkit 中各工具的调用详情）
    
-   ReAct Step（每一步循环轮次的行动观察）
    

## **接入方式**

### **容器服务 ACK 和容器计算服务 ACS 接入**

### **步骤一：探针接入助手（ack-onepilot）安装**

1.  登录[容器服务管理控制台](https://cs.console.aliyun.com)，在**集群列表**页面单击目标集群名称。
    
2.  在左侧导航栏单击**组件管理**，然后在右上角通过关键字搜索**ack-onepilot**。
    
3.  在**ack-onepilot**卡片上单击**安装**。配置相关的参数，建议使用默认值，单击**确认****。**
    
    **说明**
    
    需要保证ack-onepilot组件版本大于等于5.1.1版本，在上述步骤3中会展示当前安装的ack-onepilot版本。如果已经安装较低版本ack-onepilot，可重复上述步骤1、2，在步骤3中点击升级即可
    

### **步骤二：修改配置以启动 AI 应用监控**

1.  登录[容器服务管理控制台](https://cs.console.aliyun.com)[容器服务管理控制台](http://cs4service.console.aliyun.com)，在左侧导航栏选择**集群列表**。
    
2.  在**集群列表**页面，单击目标集群名称，然后在左侧导航栏，选择**工作负载** > **无状态**。
    
3.  切换命名空间，找到待监控的工作负载，点击最右侧操作列的更多图标![[raw/assets/Pictures/obsidian-local-images-plus/2026-07-23/接入 AgentScope（Python） 应用/af25478d48357beb4e41bab4a4f88179_MD5.png]]后，在弹出的对话框中点击**YAML编辑**。
    
4.  在YAML文件中将以下`labels`添加到spec > template > metadata层级下。添加完成后点击 **更新**。
    
    ```
    labels:
      aliyun.com/app-language: python # Python应用必填，标明此应用是Python应用。
      armsPilotAutoEnable: 'on'
      armsPilotCreateAppName: "deployment-name"    # 应用在ARMS中的展示名称
      armsPilotAppWorkspace: "workspace"    # 替换为当前workspace名称，如未指定则使用默认工作空间。
    ```
    
    ```
    apiVersion: apps/v1
    kind: Deployment
    metadata:
      labels:
        app: arms-python-client
      name: arms-python-client
      namespace: arms-demo
    spec:
      progressDeadlineSeconds: 600
      replicas: 1
      revisionHistoryLimit: 10
      selector:
        matchLabels:
          app: arms-python-client
      strategy:
        rollingUpdate:
          maxSurge: 25%
          maxUnavailable: 25%
        type: RollingUpdate
      template:
        metadata:
          labels:
            app: arms-python-client
            aliyun.com/app-language: python
            armsPilotAutoEnable: 'on'
            armsPilotCreateAppName: "arms-python-client"
            armsPilotAppWorkspace: "workspace"
        spec:
          containers:
            - image: registry.cn-hangzhou.aliyuncs.com/arms-default/python-agent:arms-python-client
    ```
    
    在YAML文件中将以下`labels`添加到spec > template > metadata层级下。添加完成后点击 **更新**。
    
    ```
    labels:
      aliyun.com/app-language: python # Python应用必填，标明此应用是Python应用。
      armsPilotAutoEnable: 'on'
      armsPilotCreateAppName: "deployment-name"    # 应用在ARMS中的展示名称
    ```
    
    ![[raw/assets/Pictures/obsidian-local-images-plus/2026-07-23/接入 AgentScope（Python） 应用/10489ef30130a028924251f4392019a0_MD5.png]]
    

### **手动接入探针**

#### 步骤一：下载探针安装器 **aliyun-bootstrap**

从PyPI仓库下载探针安装器。

```
pip3 install aliyun-bootstrap
```

### **步骤二：配置环境变量**

您需要手动为Python应用添加以下环境变量：

```
# 方式一：为本SHELL中所有进程添加环境变量
export ARMS_APP_NAME=xxx   # 应用名称。
export ARMS_WORKSPACE=xxx   # 替换为当前Workspace名称。
export ARMS_REGION_ID=xxx   # 对应的阿里云账号的RegionID。
export ARMS_LICENSE_KEY=xxx   # 阿里云 LicenseKey。
```

```
# 方式一：为本SHELL中所有进程添加环境变量
export ARMS_APP_NAME=xxx   # 应用名称。
export ARMS_REGION_ID=xxx   # 对应的阿里云账号的RegionID。
export ARMS_LICENSE_KEY=xxx   # 阿里云 LicenseKey。
```

```
# 方式二：为某个进程单独添加环境变量
ARMS_APP_NAME=xxx ARMS_WORKSPACE=xxx ARMS_REGION_ID=xxx ARMS_LICENSE_KEY=xxx aliyun-instrument xxx.py
```

```
# 方式二：为某个进程单独添加环境变量
ARMS_APP_NAME=xxx ARMS_REGION_ID=xxx ARMS_LICENSE_KEY=xxx aliyun-instrument xxx.py
```

其中LicenseKey可以通过OpenAPI获取，具体参见[获取应用可观测](https://help.aliyun.com/zh/cms/cloudmonitor-2-0/developer-reference/api-cms-2024-03-30-getserviceobservability)接口返回值中的authToken字段。

### **（可选）Docker环境安装参考**

对于Docker环境，可以参考以下Dockerfile示例修改您的Dockerfile文件。

```
# 添加环境变量
ENV ARMS_APP_NAME={AppName}
ENV ARMS_REGION_ID={regionId}
ENV ARMS_LICENSE_KEY={licenseKey}
ENV ARMS_WORKSPACE={worksapce}

## 原有环境
```

```
# 添加环境变量
ENV ARMS_APP_NAME={AppName}
ENV ARMS_REGION_ID={regionId}
ENV ARMS_LICENSE_KEY={licenseKey}
## 原有环境
```

#### 步骤三：使用aliyun-bootstrap安装Python探针

1.  为了加快安装，建议您使用如下命令先配置镜像仓库。
    
    ```
    pip config set global.index-url https://mirrors.aliyun.com/pypi/simple/ && pip config set install.trusted-host mirrors.aliyun.com
    ```
    
2.  安装探针。
    
    ```
    aliyun-bootstrap -a install
    ```
    

#### 步骤四：启动应用

##### **通过ARMS Python探针启动应用**

```
aliyun-instrument python app.py
```

## **示例代码**

```
import asyncio
import os
from agentscope.agent import ReActAgent
from agentscope.formatter import DashScopeChatFormatter
from agentscope.message import Msg, TextBlock
from agentscope.model import DashScopeChatModel
from agentscope.tool import Toolkit, ToolResponse

def get_weather(city: str) -> ToolResponse:
    weather_data = {
        "Beijing": "Sunny 25°C",
        "Shanghai": "Cloudy 22°C",
        "Hangzhou": "Light rain 20°C",
    }
    result = weather_data.get(city, f"{city}: No weather data available")
    return ToolResponse(content=[TextBlock(type="text", text=result)])

def search_info(keyword: str) -> ToolResponse:
    info = {
        "West Lake": "West Lake in Hangzhou is a famous freshwater lake, UNESCO World Heritage",
        "Great Wall": "Ancient Chinese defensive structure, UNESCO World Heritage",
    }
    result = info.get(keyword, f"No information found for '{keyword}'")
    return ToolResponse(content=[TextBlock(type="text", text=result)])

async def main():
    model = DashScopeChatModel(
        model_name=os.environ.get("MODEL_NAME", "qwen-plus"),
        api_key=os.environ.get("DASHSCOPE_API_KEY"),
    )
    toolkit = Toolkit()
    toolkit.register_tool_function(get_weather)
    toolkit.register_tool_function(search_info)
    agent = ReActAgent(
        name="TravelAgent",
        sys_prompt="You are a travel assistant. Use tools to query weather and travel info.",
        model=model,
        formatter=DashScopeChatFormatter(),
        toolkit=toolkit,
        max_iters=5,
    )
    msg = Msg(
        name="user",
        content="What's the weather in Hangzhou today? Is West Lake worth visiting?",
        role="user",
    )
    result = await agent(msg)
    print(result.content)

asyncio.run(main())
```

## **查看监控详情**

1.  登录[云监控2.0控制台](https://cmsnext.console.aliyun.com/)，选择目标工作空间，在左侧导航栏选择**所有功能** > ****AI应用可观测****。
    
2.  在**AI应用列表**页面可以看到已接入的应用，单击**应用名称**可以查看详细的应用监控数据。
    

![[raw/assets/Pictures/obsidian-local-images-plus/2026-07-23/接入 AgentScope（Python） 应用/e436279847b8a8ea0dd4b8a361cb6081_MD5.png]]

## **查看监控详情**

1.  在[云监控 2.0 控制台](https://cmsnext.console.aliyun.com/#/home)的**LLM 应用监控** **>** **应用列表**页面单击目标 AI 应用名称，可以查看详细的应用监控数据。
    

![[raw/assets/Pictures/obsidian-local-images-plus/2026-07-23/接入 AgentScope（Python） 应用/3aa4d353f8096e727638bf909746ad59_MD5.png]]

## **更多参考**

#### 常见问题排查

[Python探针使用常见问题](https://help.aliyun.com/zh/arms/application-monitoring/user-guide/python-agent-faq)