---
title: "接入 Hermes Agent 应用"
source: "https://help.aliyun.com/zh/document_detail/3042582.html?spm=a2c4g.11186623.help-menu-3033820.d_2_4.5cd96ef58Q3kRT"
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
"word-count": "2180"
更新时间: "2026-06-25 11:29:39"
---
Hermes Agent 可通过 Hermes Agent 可观测插件接入云监控 2.0。插件会在 Hermes 运行环境中启用 OpenTelemetry 自动埋点，并将 AI Agent 的调用链路上报到云监控 2.0。接入后，您可以查看 Hermes Agent 的 Agent 执行链路、模型调用、工具调用、Token 消耗和错误信息。

## **接入方式**

根据 Hermes Agent 的部署环境和探针类型，选择容器环境内接入、商业版 Python 探针接入或开源 LoongSuite 接入。

#### 容器环境内接入

适用于 Hermes Agent 部署在 ACK、ACS、自建 Kubernetes 或其他容器环境中的场景。Hermes Agent 官方 Docker 镜像和官方 Ubuntu curl 安装方式均未提供 ack-onepilot Python 自动接入所需的 pip3，因此不推荐使用 ACK OnePilot 自动接入。请在镜像中安装云监控 2.0 Python 探针，并通过 PYTHONPATH 让 Hermes Python 进程启动时自动加载探针。

#### **步骤一：获取接入参数**

1.  登录[云监控 2.0 控制台](https://cmsnext.console.aliyun.com/)，选择目标工作空间。
    
2.  在左侧导航栏单击**接入中心**。
    
3.  在**AI 应用可观测**区域选择 Hermes Agent 接入项。
    
4.  在参数配置区域输入应用名，根据部署环境选择连接方式，然后单击**LicenseKey**右侧的**点击获取**。
    
5.  记录页面生成的 Endpoint、LicenseKey、Project、Workspace 和 serviceName 等接入参数。
    

#### **步骤二：构建内置探针的 Hermes Agent 镜像**

```
FROM nousresearch/hermes-agent:latest

USER root

# 安装下载探针包所需的基础工具。
# Hermes 官方镜像已包含 Python、uv 和 Hermes 虚拟环境，这里不额外安装 pip。
RUN apt-get update \
  && apt-get install -y --no-install-recommends curl ca-certificates \
  && rm -rf /var/lib/apt/lists/*

# 下载云监控 2.0 Python 探针包，并将探针 wheel 安装到 Hermes 官方镜像内置的 Python 虚拟环境中。
# /opt/hermes/.venv/bin/python 为 Hermes Agent 当前使用的 Python 解释器。
RUN curl -fsSL https://arms-apm-cn-hangzhou.oss-cn-hangzhou.aliyuncs.com/aliyun-python-agent/aliyun-python-agent.tar.gz \
    -o /tmp/aliyun-python-agent.tar.gz \
  && mkdir -p /tmp/aliyun-python-agent \
  && tar -zxf /tmp/aliyun-python-agent.tar.gz -C /tmp/aliyun-python-agent \
  && uv pip install --python /opt/hermes/.venv/bin/python /tmp/aliyun-python-agent/target/*.whl \
  && rm -rf /tmp/aliyun-python-agent /tmp/aliyun-python-agent.tar.gz

# 配置应用名、地域、工作空间和 LicenseKey。
# 请将以下占位符替换为云监控 2.0 控制台接入页面生成的实际参数。
ENV ARMS_APP_NAME="hermes-agent-demo"
ENV ARMS_REGION_ID="<RegionId>"
ENV ARMS_WORKSPACE="<Your-Workspace>"
ENV ARMS_LICENSE_KEY="<Your-LicenseKey>"

# 通过 PYTHONPATH 在 Hermes Python 进程启动时自动加载探针。
# 第一个路径用于触发自动埋点初始化，第二个路径用于让 Python 找到探针及其依赖。
# 如果 Hermes 镜像中的 Python 版本不是 3.13，请按实际 site-packages 路径替换。
ENV PYTHONPATH="/opt/hermes/.venv/lib/python3.13/site-packages/aliyun/opentelemetry/instrumentation/auto_instrumentation:/opt/hermes/.venv/lib/python3.13/site-packages"
```

上述 `PYTHONPATH` 路径基于 Hermes Agent 官方镜像当前的 Python 3.13 虚拟环境。如果您基于其他 Python 版本构建镜像，请使用 `/opt/hermes/.venv/bin/python -c "import site; print(site.getsitepackages()[0])"` 查询实际 `site-packages` 路径，并替换示例中的路径。

保持 Hermes Agent 原有启动命令不变，例如继续使用 `hermes gateway start`。启动后在 Hermes Agent 服务日志中查找 `Aliyun python agent is started`，表示商业化 Python 探针已经随 Hermes 进程加载。

#### **商业版 Python 探针接入**

适用于本地 macOS、Linux、Windows WSL 或个人开发机上希望接入云监控 2.0 商业版 Python 探针的场景。该方式将商业版 Python 探针安装到独立目录，并通过 PYTHONPATH 在 Hermes Python 进程启动时自动加载探针，无需修改 Hermes Agent 源码，也可用于 hermes gateway start 等长期运行方式。

#### **步骤一：获取接入参数**

1.  登录[云监控 2.0 控制台](https://cmsnext.console.aliyun.com/)，选择目标工作空间。
    
2.  在左侧导航栏单击**接入中心**。
    
3.  在**AI 应用可观测**区域选择 Hermes Agent 接入项。
    
4.  在参数配置区域输入应用名，根据本地开发机所在网络选择连接方式，然后记录 RegionId、Workspace、LicenseKey 和 serviceName 等接入参数。
    

#### **步骤二：安装 Hermes Agent**

如果本机尚未安装 Hermes Agent，请先使用 Hermes Agent 官方安装脚本完成安装。已安装可跳过本步骤。

```
curl -fsSL https://hermes-agent.nousresearch.com/install.sh | bash
```

官方脚本默认将 Hermes Agent 安装到 `~/.hermes/hermes-agent`，并创建 Python 虚拟环境 `~/.hermes/hermes-agent/venv`。若通过自定义目录安装，请在下方 `HERMES_AGENT_PYTHON` 中填写实际 Python 解释器路径。

#### **步骤三：安装商业版 Python 探针**

请使用 Hermes Agent 运行时实际使用的 Python 解释器执行以下命令。命令会下载云监控 2.0 Python 探针包，将探针 wheel 安装到独立目录，并写入 sitecustomize.py 以便后续通过 PYTHONPATH 自动注入。

```
export ALIYUN_PYTHON_AGENT_HOME="$HOME/.aliyun-python-agent/hermes"
export HERMES_AGENT_PYTHON="${HERMES_AGENT_PYTHON:-$HOME/.hermes/hermes-agent/venv/bin/python}"
mkdir -p "$ALIYUN_PYTHON_AGENT_HOME" /tmp/aliyun-python-agent
curl -fsSL https://arms-apm-cn-hangzhou.oss-cn-hangzhou.aliyuncs.com/aliyun-python-agent/aliyun-python-agent.tar.gz -o /tmp/aliyun-python-agent.tar.gz
tar -zxf /tmp/aliyun-python-agent.tar.gz -C /tmp/aliyun-python-agent
"$HERMES_AGENT_PYTHON" -m pip install --target "$ALIYUN_PYTHON_AGENT_HOME" --no-cache-dir /tmp/aliyun-python-agent/target/*.whl
"$HERMES_AGENT_PYTHON" -c 'from pathlib import Path; import os; Path(os.environ["ALIYUN_PYTHON_AGENT_HOME"], "sitecustomize.py").write_text("from aliyun.opentelemetry.instrumentation.auto_instrumentation import sitecustomize\n")'
rm -rf /tmp/aliyun-python-agent /tmp/aliyun-python-agent.tar.gz
```

安装完成后，探针目录中应包含 `sitecustomize.py`，并包含 `aliyun-loongsuite-instrumentation-hermes-agent`。

#### **步骤四：启动 Hermes Agent**

启动前配置云监控 2.0 接入参数，并将商业版 Python 探针目录加入 PYTHONPATH：

```
export ARMS_APP_NAME="hermes-agent-demo"
export ARMS_REGION_ID="<RegionId>"
export ARMS_WORKSPACE="<Your-Workspace>"
export ARMS_LICENSE_KEY="<Your-LicenseKey>"
export PYTHONPATH="$HOME/.aliyun-python-agent/hermes:${PYTHONPATH:-}"

hermes
# 或常驻运行：
# hermes gateway start
```

如果 Hermes Agent 已经在运行，请先停止后重新启动。启动日志中出现 `Aliyun python agent is started`，表示商业版 Python 探针已经随 Hermes 进程加载。

#### **开源 LoongSuite 接入**

适用于本地开发、PoC 验证、问题复现，或希望使用开源 LoongSuite Python Agent 的场景。该方式通过官方 bash 脚本安装 LoongSuite site bootstrap 和 Hermes Agent 可观测插件，安装步骤较轻量。LoongSuite Python Agent 开源地址：[https://github.com/alibaba/loongsuite-python-agent](https://github.com/alibaba/loongsuite-python-agent)。

#### **步骤一：获取开源接入命令**

1.  登录[云监控 2.0 控制台](https://cmsnext.console.aliyun.com/)，选择目标工作空间。
    
2.  在左侧导航栏单击**接入中心**。
    
3.  在**AI 应用可观测**区域选择 Hermes Agent 接入项。
    
4.  在参数配置区域输入应用名，选择开源 LoongSuite 接入方式后复制页面生成的安装命令。命令中包含 Endpoint、LicenseKey、Project、Workspace 和 serviceName 等信息。
    

#### **步骤二：安装可观测插件**

在 Hermes Agent 所在机器上执行安装命令。如果 Hermes Agent 运行在 conda 或 venv 环境中，请先切换到 Hermes 日常使用的 Python 环境。

```
curl -fsSL https://arms-apm-cn-hangzhou-pre.oss-cn-hangzhou.aliyuncs.com/hermes-agent-cms-plugin/hermes-cms.sh | bash -s -- install \
  --x-arms-license-key "<Your-LicenseKey>" \
  --x-arms-project "<Your-Project>" \
  --x-cms-workspace "<Your-Workspace>" \
  --serviceName "hermes-agent-demo" \
  --endpoint "https://<Endpoint>/apm/trace/opentelemetry"
```

安装成功后，终端会输出类似如下内容：

```
hermes-agent-cms-plugin installed successfully!
```

插件会在本地注册 `hermes-cms` 命令。如果当前环境没有将 `~/.local/bin` 加入 `PATH`，可以使用以下命令：

```
~/.loongsuite/bin/hermes-cms enable
```

#### **步骤三：启动 Hermes Agent**

启用可观测插件：

```
hermes-cms enable
```

前台启动 Hermes Agent：

```
hermes
```

开源 LoongSuite 接入不建议用于 Gateway 后台长期运行场景。如果需要通过 hermes gateway start 常驻运行 Hermes Agent，请使用商业版 Python 探针接入或容器环境内接入，通过 PYTHONPATH 在 Python 进程启动时自动加载探针。

如果 Hermes Agent 已经在运行，请先停止后重新启动，使可观测插件生效。

## **查看监控详情**

1.  登录[云监控 2.0 控制台](https://cmsnext.console.aliyun.com/)，选择目标工作空间。
    
2.  在左侧导航栏选择**应用可观测** > **AI 应用可观测**。
    
3.  在应用列表中找到 `hermes-agent-demo`。
    
4.  单击应用名称，查看调用链路、模型调用、Token 消耗、工具调用详情和错误信息。
    

## **常见问题排查**

### 开源 LoongSuite 接入后 Python 进程启动变慢或日志较多

开源 LoongSuite 接入执行 `hermes-cms enable` 后，会启用 `loongsuite-site-bootstrap`。Python 进程启动时会执行一次自动接入初始化，因此可能增加一段固定启动耗时。

开源 LoongSuite 接入如果日志中持续出现 site bootstrap 初始化成功提示，请将 `loongsuite-site-bootstrap` 升级到 0.6.1 或以上版本，并设置以下环境变量关闭成功日志：

```
pip install -U "loongsuite-site-bootstrap>=0.6.1"
LOONGSUITE_PYTHON_SITE_BOOTSTRAP_LOG_SUCCESS=False
```

### 接入完成后控制台暂时没有数据

接入完成后，首次上报和控制台展示可能存在几分钟延迟。建议连续触发多次实际 Hermes Agent 调用，并等待 5 到 10 分钟后刷新控制台查看数据；如果仍未看到调用链，请再触发一次调用并结合探针日志、应用名、工作空间和上报入口配置继续排查。

### **其他**

如果接入后出现 Python 探针安装失败、应用启动后没有探针初始化日志、控制台没有调用链数据或环境变量未生效等问题，请参见：

[Python探针使用常见问题](https://help.aliyun.com/zh/arms/application-monitoring/user-guide/python-agent-faq)