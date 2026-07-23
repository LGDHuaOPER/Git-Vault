---
title: "AI 应用接入：AI Coding Agent"
source: "https://help.aliyun.com/zh/document_detail/3033878.html?spm=a2c4g.11186623.help-menu-3033820.d_2_1.5e6d5e3f6sxbIS"
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
"word-count": "2563"
更新时间: "2026-07-17 09:59:44"
---
通过 LoongSuite Pilot 将开发者本机的 AI Coding Agent 运行数据接入 AgentLoop，实现会话、模型调用、工具调用、Token 用量和 Trace 数据的统一观测与分析。

## LoongSuite Pilot 简介

LoongSuite Pilot 是运行在开发者本机的轻量级采集器，用于自动发现本机已安装的 AI Coding Agent 并部署所需的 Hook 或插件。LoongSuite Pilot 将不同 Agent 的原始活动数据归一化为统一事件格式，上报到 AgentLoop 使用的日志或 Trace 后端。

## 适用场景

当团队使用 Claude Code、Codex、Cursor、Qoder 等 AI Coding Agent 进行日常研发时，可通过 LoongSuite Pilot 采集端侧活动数据，用于以下场景：

-   查看团队使用了哪些 AI Coding Agent。
    
-   分析会话、模型调用、工具调用和错误事件。
    
-   按 Agent 维度统计 Token 用量。
    
-   通过日志检索、Trace 链路或自定义接口分析 Agent 运行过程。
    
-   在数据上报前过滤 Prompt、Completion、工具参数等敏感内容。
    

## 支持的 AI Coding Agent

### macOS / Linux 支持情况

| **AI Coding Agent** | **集成方式** | **Trace 上报** | **日志上报** | **Token 采集** | **对话和 Tool Call 采集** |
| --- | --- | --- | --- | --- | --- |
| Claude Code | Hook | 支持  | 支持  | 支持  | 支持  |
| Codex | Hook | 支持  | 支持  | 支持  | 支持  |
| Cursor | Hook | 支持  | 支持  | 支持  | 支持  |
| Qoder | Hook | 支持  | 支持  | 支持  | 支持  |
| Qoder CN | Hook | 支持  | 支持  | 支持  | 支持  |
| Qoder CLI | Hook / Logs | 支持  | 支持  | 支持  | 支持  |
| Qoder for JetBrains | Hook / SQLite | 支持  | 支持  | 支持  | 支持  |
| Qoder Work | Hook / Logs | 支持  | 支持  | 不支持 | 支持  |
| Qoder Work CN | Hook / Logs | 支持  | 支持  | 不支持 | 支持  |
| Qwen Code CLI | Hook | 支持  | 支持  | 支持  | 支持  |
| OpenCode | Plugin | 支持  | 支持  | 支持  | 支持  |
| Wukong | CLI API | 支持  | 支持  | 支持  | 支持  |

### Windows 支持情况

| **AI Coding Agent** | **集成方式** | **Trace 上报** | **日志上报** | **Token 采集** | **对话和 Tool Call 采集** |
| --- | --- | --- | --- | --- | --- |
| Claude Code | Hook | 支持  | 支持  | 支持  | 支持  |
| Cursor | Hook | 支持  | 支持  | 支持  | 支持  |
| Qoder Work（User 版本） | Hook / 本地数据源 | 支持  | 支持  | 不支持 | 支持  |
| Qoder CLI | Hook | 支持  | 支持  | 不支持 | 支持  |
| Qoder IDE（Qoder >= 1.10.0 User 版本） | Hook / 本地数据源 | 支持  | 支持  | 支持  | 支持  |
| OpenCode | Plugin | 支持  | 支持  | 支持  | 支持  |

## 前提条件

开始接入前，请确认本机满足以下条件：

-   目标 AI Coding Agent 已安装，并至少使用过一次。
    
-   已在 AgentLoop 中完成 AI Coding Agent 接入资源初始化，并获取控制台自动生成的安装命令。
    

### macOS / Linux 环境要求

-   已安装 Node.js 22.22 或更高版本。
    
-   已安装 `npm`。
    
-   已安装 `curl` 或 `wget`。
    

### Windows 环境要求

-   Windows 10 及以上版本。
    
-   PowerShell 5.x。
    
-   nvm 和 Node.js 22.22，按以下步骤安装：
    
    1.  安装 nvm-windows。在 PowerShell 中执行：
        
        ```
        curl.exe -L -o "$env:TEMP\nvm-setup.exe" "https://github.com/coreybutler/nvm-windows/releases/download/1.2.2/nvm-setup.exe" && Start-Process -FilePath "$env:TEMP\nvm-setup.exe" -ArgumentList "/SILENT" -Wait
        ```
        
    2.  安装 Node.js。重新打开一个 PowerShell 窗口，执行：
        
        ```
        nvm install 22.22
        nvm use 22.22
        ```
        

## 安装 LoongSuite Pilot

对于 AgentLoop 用户，建议直接复制 AgentLoop 控制台自动生成的安装命令进行安装。命令中除 `true`、`false` 外的资源名称和接入参数，通常由 AgentLoop 在初始化接入资源时自动生成。

在安装前，需要通过 AgentLoop 控制台获取对应的 CMS、SLS 参数，在安装命令中替换为实际值。

### macOS / Linux 安装步骤

```
# 执行安装命令，下面所有参数需要替换为上面获取到的参数
curl -fsSL https://aliyun-observability-release-cn-shanghai.oss-cn-shanghai.aliyuncs.com/loongsuite-pilot/installer.sh -o /tmp/loongsuite-pilot-installer.sh && bash /tmp/loongsuite-pilot-installer.sh install \
  --collect-log "true" \
  --collect-trace "true" \
  --sls-project "您的SLS Project名" \
  --sls-logstore "您的SLS Logstore名" \
  --sls-endpoint "您的SLS Endpoint" \
  --cms-license-key "您的Trace License Key" \
  --cms-endpoint "您的Trace Endpoint" \
  --cms-workspace "您的Trace Workspace" \
  --service-name-prefix "您的服务名前缀"
```

### Windows 安装步骤

```
# 下载安装脚本
Invoke-WebRequest `
    -Uri 'https://aliyun-observability-release-cn-shanghai.oss-cn-shanghai.aliyuncs.com/loongsuite-pilot/installer.ps1' `
    -OutFile installer.ps1

# 执行安装命令，下面所有参数需要替换为上面获取到的参数
.\installer.ps1 install `
    -CollectLog 'true' `
    -CollectTrace 'true' `
    -SlsProject "您的SLS Project名" `
    -SlsLogstore "您的SLS Logstore名" `
    -SlsEndpoint "您的SLS Endpoint" `
    -CmsLicenseKey "您的Trace License Key" `
    -CmsEndpoint "您的Trace Endpoint" `
    -CmsWorkspace "您的Trace Workspace" `
    -ServiceNamePrefix "您的服务名前缀"
```

安装器会自动完成以下操作：

-   检测本机支持的 AI Coding Agent。
    
-   让您选择需要采集的 Agent。
    
-   部署对应的 Hook 或插件。
    
-   写入本地配置。
    
-   启动 LoongSuite Pilot 后台服务。
    

安装完成后，执行以下命令查看服务状态：

**macOS / Linux / Windows：**

```
loongsuite-pilot status
loongsuite-pilot info
```

默认情况下，LoongSuite Pilot 会把本地配置、运行状态和 JSONL 采集结果写入当前用户目录下的 `.loongsuite-pilot` 目录。默认路径如下：

| **用途** | **macOS / Linux** | **Windows** |
| --- | --- | --- |
| 数据根目录 | `~/.loongsuite-pilot/` | `C:\\Users\\<用户名>\\.loongsuite-pilot\\` |
| 配置文件 | `~/.loongsuite-pilot/config.json` | `C:\\Users\\<用户名>\\.loongsuite-pilot\\config.json` |
| 本地 JSONL 输出目录 | `~/.loongsuite-pilot/logs/output/` | `C:\\Users\\<用户名>\\.loongsuite-pilot\\logs\\output\\` |
| Agent 准入控制文件 | `~/.loongsuite-pilot/agent-control.json` | `C:\\Users\\<用户名>\\.loongsuite-pilot\\agent-control.json` |

## 管理 LoongSuite Pilot

如需开启本地 Dashboard，可以执行：

```
loongsuite-pilot monitor start
```

然后访问：

```
http://127.0.0.1:8765/
```

如需卸载 LoongSuite Pilot 并保留本地数据，执行：

**macOS / Linux：**

```
curl -fsSL https://aliyun-observability-release-cn-shanghai.oss-cn-shanghai.aliyuncs.com/loongsuite-pilot/installer.sh -o /tmp/loongsuite-pilot-installer.sh && bash /tmp/loongsuite-pilot-installer.sh uninstall
```

**Windows：**

```
.\installer.ps1 uninstall
```

如需同时移除安装文件和本地数据，执行：

**macOS / Linux：**

```
curl -fsSL https://aliyun-observability-release-cn-shanghai.oss-cn-shanghai.aliyuncs.com/loongsuite-pilot/installer.sh -o /tmp/loongsuite-pilot-installer.sh && bash /tmp/loongsuite-pilot-installer.sh uninstall --purge
```

**Windows：**

```
.\installer.ps1 uninstall -Purge
```

## 配置 Agent 采集

安装完成后，可以通过本地配置文件中的 `agents` 配置控制是否采集某个 AI Coding Agent。默认配置文件路径如下：

| **系统** | **配置文件路径** |
| --- | --- |
| macOS / Linux | `~/.loongsuite-pilot/config.json` |
| Windows | `C:\\Users\\<用户名>\\.loongsuite-pilot\\config.json` |

```
{
  "agents": {
    "claude-code": {
      "enabled": true
    },
    "cursor": {
      "enabled": true
    },
    "qoder": {
      "enabled": false
    }
  }
}
```

| **配置项** | **说明** |
| --- | --- |
| `enabled: true` | 开启该 Agent 的采集。LoongSuite Pilot 仍会检测本机是否存在对应数据源。 |
| `enabled: false` | 关闭该 Agent 的采集。 |

例如，需要采集 Claude Code 和 Cursor、关闭 Qoder 时，可以使用上面的配置。修改后需要重启 LoongSuite Pilot：

```
loongsuite-pilot restart
```

## 配置数据脱敏

LoongSuite Pilot 可以在规范化事件发送到输出后端前，对常见密钥进行脱敏。脱敏适用于 Prompt、Completion、工具参数或工具结果中可能出现凭证的场景。

如需开启或调整脱敏策略，请修改本地配置文件：

| **系统** | **配置文件路径** |
| --- | --- |
| macOS / Linux | `~/.loongsuite-pilot/config.json` |
| Windows | `C:\\Users\\<用户名>\\.loongsuite-pilot\\config.json` |

开启全部脱敏规则：

```
{
  "mask": {
    "mode": "all"
  }
}
```

仅开启指定脱敏规则：

```
{
  "mask": {
    "mode": "custom",
    "types": [
      "apiKey",
      "databaseUrl"
    ]
  }
}
```

脱敏模式如下。

| **模式** | **说明** |
| --- | --- |
| `none` | 不进行脱敏。未配置 mask mode 时默认使用该模式。 |
| `all` | 开启所有内置敏感数据规则。 |
| `custom` | 只开启 `mask.types` 中列出的脱敏类型。 |

脱敏类型如下。

| **类型** | **覆盖内容** | **替换标记** |
| --- | --- | --- |
| `cloudAccessKey` | 阿里云、AWS、腾讯云风格的 AccessKey ID。 | `[ACCESSKEY_MASKED]` |
| `apiKey` | OpenAI-compatible 和常见平台风格 API Key。 | `[APIKEY_MASKED]` |
| `privateKey` | PEM 或 OpenSSH 私钥块。 | `[PRIVATEKEY_MASKED]` |
| `databaseUrl` | 包含密码的数据库 URL。 | `[DATABASEURL_MASKED]` |

LoongSuite Pilot 重点扫描可能包含用户或工具内容的字段，例如：

-   LLM 输入和输出消息。
    
-   工具调用参数。
    
-   工具调用结果。
    
-   已知 Agent 内容字段。
    

模型名、Token 数、耗时、Git 分支、Workspace 路径等稳定元数据不作为密钥内容字段扫描。

修改配置后，执行以下命令重启 LoongSuite Pilot：

```
loongsuite-pilot restart
```

## 验证接入结果

安装或修改配置后，可以按以下步骤验证接入是否生效。

**说明**

如果重启 LoongSuite Pilot 后发现采集状态异常，请手动执行 `loongsuite-pilot start` 命令开启采集。

### 查看本地服务状态

```
loongsuite-pilot status
loongsuite-pilot info
```

### 查看本地采集输出

**macOS / Linux：**

```
ls ~/.loongsuite-pilot/logs/output
tail -f ~/.loongsuite-pilot/logs/output/*.jsonl
```

**Windows：**

```
Get-ChildItem "$env:USERPROFILE\.loongsuite-pilot\logs\output"

Get-ChildItem "$env:USERPROFILE\.loongsuite-pilot\logs\output\*.jsonl" |
  Sort-Object LastWriteTime |
  Select-Object -Last 1 |
  Get-Content -Wait
```

如果本地输出目录中可以看到新事件，说明 AI Coding Agent 采集链路已经生效。

### 查看 AgentLoop 控制台

触发一次新的 AI Coding Agent 活动后，回到 AgentLoop 控制台查看对应接入任务的数据状态。数据到达时间可能受本地批量发送和后端处理延迟影响。

### 验证 Agent 采集

如果预期 Agent 没有数据，请按以下步骤检查：

1.  确认目标 Agent 已安装，并至少使用过一次。
    
2.  确认准入控制文件中没有将该 Agent 设置为 `off`。macOS / Linux 默认路径为 `~/.loongsuite-pilot/agent-control.json`，Windows 默认路径为 `C:\Users\<用户名>\.loongsuite-pilot\agent-control.json`。
    
3.  确认配置文件中没有将该 Agent 设置为 `"enabled": false`。macOS / Linux 默认路径为 `~/.loongsuite-pilot/config.json`，Windows 默认路径为 `C:\Users\<用户名>\.loongsuite-pilot\config.json`。
    
4.  修改配置后，执行 `loongsuite-pilot restart`。
    
5.  触发一次新的 Agent 活动，再查看本地输出或 AgentLoop 控制台。
    

## 常见问题

### 未发现预期 Agent 怎么办？

请确认目标 Agent 已安装、已使用过一次，并且没有在 `agent-control.json` 或 `config.json` 中被关闭。修改配置后，执行 `loongsuite-pilot restart`。

### 本地没有新数据怎么办？

请确认 LoongSuite Pilot 处于运行状态，并在服务启动后触发一次新的 AI Coding Agent 活动。然后查看本地 JSONL 输出目录：macOS / Linux 默认为 `~/.loongsuite-pilot/logs/output/`，Windows 默认为 `C:\Users\<用户名>\.loongsuite-pilot\logs\output\`。

### AgentLoop 控制台暂时没有数据怎么办？

请先确认本地输出中是否已有新事件。如果本地已有事件但控制台暂未展示，请稍后刷新控制台，或检查安装命令是否来自当前 AgentLoop 接入任务。

### 如何开启数据脱敏？

修改本地配置文件中的 `mask` 配置，保存后执行 `loongsuite-pilot restart`。配置文件默认路径：macOS / Linux 为 `~/.loongsuite-pilot/config.json`，Windows 为 `C:\Users\<用户名>\.loongsuite-pilot\config.json`。