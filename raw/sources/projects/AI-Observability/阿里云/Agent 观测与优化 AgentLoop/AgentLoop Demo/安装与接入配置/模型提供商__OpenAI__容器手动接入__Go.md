> Go 支持范围：ARMS 支持 openai-go v1.5.0+ 和 go-openai v1.30.0+。

## 步骤一：安装 AI Agent 可观测接入组件（ack-onepilot）

1. 登录[容器服务管理控制台](https://cs.console.aliyun.com/)，在左侧导航栏单击集群，在集群列表页面单击目标集群名称。
2. 在左侧导航栏选择组件管理，在右侧点击安装组件，上方通过关键字搜索ack-onepilot。
3. 在弹出的页面中可以配置相关的参数，建议使用默认值，无需修改配置，点击 **下一步**。

> **注意：** 需要保证ack-onepilot组件版本大于等于5.1.0版本，如果已经安装较低版本ack-onepilot，可通过“组件管理-升级”功能升级即可。

## 步骤二：编译Go二进制文件

1. 下载instgo

##### Linux AMD64

```bash
wget http://arms-apm-cn-hongkong.oss-cn-hongkong.aliyuncs.com/instgo/instgo-linux-amd64 -O instgo
```

##### Linux ARM64

```bash
wget http://arms-apm-cn-hongkong.oss-cn-hongkong.aliyuncs.com/instgo/instgo-linux-arm64" -O instgo
```

##### MAC ARM64

```bash
wget http://arms-apm-cn-hongkong.oss-cn-hongkong.aliyuncs.com/instgo/instgo-darwin-arm64" -O instgo
```

##### MAC AMD64

```bash
wget http://arms-apm-cn-hongkong.oss-cn-hongkong.aliyuncs.com/instgo/instgo-darwin-amd64" -O instgo
```

2. 为编译工具赋予可执行权限。

```shell
# 赋予可执行权限
chmod +x instgo
```

3. 将instgo 添加到你的编译命令go build前

```shell
instgo go build {arg1} {arg2} {arg3}
```

4. 使用上一步编译的二进制文件构建镜像（容器化环境运行）。

## 步骤三：运行

容器ACK环境：

在YAML文件中将以下labels添加到spec.template.metadata层级下。

```yaml
labels:
  aliyun.com/app-language: golang # Go应用必填，标明此应用是Go应用。
  armsPilotAutoEnable: 'on'
  armsPilotCreateAppName: "<your-deployment-name>"    #请将<your-deployment-name>替换为您的应用名称。
  armsPilotAppWorkspace: default-cms-1819385687343877-cn-hongkong  # 当前workspace
```

如果想进一步了解如何接入Go应用监控，请[参考文档](https://help.aliyun.com/zh/arms/application-monitoring/user-guide/monitoring-the-golang-applications/?spm=a2c4g.11186623.0.0.37543319CS9eeY)
