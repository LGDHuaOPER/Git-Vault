# 接入 OpenCode

LoongSuite Pilot 是本地采集服务，同一台机器只需要安装一次；安装后会自动发现已支持的 AI 编程助手，并通过插件注入采集 OpenCode 的对话、工具调用和 Token 事件。

## 前提条件

- 已安装 OpenCode CLI，并且本机存在 ~/.config/opencode 配置目录。
- 已安装 Node.js 22；如果本机未安装，可使用 nvm 安装：

```bash
# 安装 nvm
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash

# 用 nvm 安装 v22 版本的 Node.js
nvm install 22
```

- 在日常使用 OpenCode 的同一个用户下执行安装命令。

## 安装 LoongSuite Pilot

请先按需选择 Trace 接入和日志接入，确认连接方式和应用名前缀后，再复制以下命令到终端中执行。若开启 Trace 接入，请先在上方点击获取 LicenseKey；若开启日志接入，请先完成资源初始化。命令中如果仍显示“请先...”占位，请先回到上方完成对应操作后再执行。

macOS、Linux、WSL：

```bash
curl -fsSL https://aliyun-observability-release-cn-shanghai.oss-cn-shanghai.aliyuncs.com/loongsuite-pilot/installer.sh -o /tmp/loongsuite-pilot-installer.sh && bash /tmp/loongsuite-pilot-installer.sh install \
  --collect-log "true" \
  --collect-trace "true" \
  --sls-project "agentloop-c260254f99d705a28d1309acb0e53fda" \
  --sls-logstore "agent-event-webtracking" \
  --sls-endpoint "cn-hongkong.log.aliyuncs.com" \
  --cms-license-key "请先点击获取 LicenseKey" \
  --cms-endpoint "请先点击获取 LicenseKey" \
  --cms-workspace "default-cms-1819385687343877-cn-hongkong" \
  --service-name-prefix "ai-coding-agent"
```

执行安装命令后，安装流程中如出现用户 ID，该项为选填项，用于标识本地 Pilot 采集数据所属用户，便于在 Trace 和审计日志中按用户检索和区分。例如填写 zhangsan，效果是上报的 Trace 和审计日志会带上 user.id=zhangsan，可按该值筛选该用户的 AI 编程助手数据。

## 验证接入状态

```bash
# 查看 LoongSuite Pilot 运行状态
loongsuite-pilot status

# 查看当前采集配置和组件发现结果
loongsuite-pilot info
```

使用 OpenCode 完成一次对话或工具调用后，应产生按日期滚动的 JSONL 日志。

可通过以下命令查看日志目录：

```bash
ls "$HOME/.loongsuite-pilot/logs/opencode"
```

如机器重启后发现采集状态异常，请手动执行 loongsuite-pilot start 命令开启采集。

## 升级

LoongSuite Pilot 会自动检查并在后台完成升级，无需手动执行升级命令；升级后会继续使用当前采集配置。

## 卸载

```bash
curl -fsSL https://aliyun-observability-release-cn-shanghai.oss-cn-shanghai.aliyuncs.com/loongsuite-pilot/installer.sh | bash -s -- uninstall --purge
```
