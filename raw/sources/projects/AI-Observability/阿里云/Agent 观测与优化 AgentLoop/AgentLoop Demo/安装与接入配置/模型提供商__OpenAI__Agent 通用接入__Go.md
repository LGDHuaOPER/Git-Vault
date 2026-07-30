> Go 支持范围：ARMS 支持 openai-go v1.5.0+ 和 go-openai v1.30.0+。

## 下载 Instgo

**手动下载Instgo**

通过如下命令下载Instgo编译工具，并添加到编译流程中运行：

### Linux AMD64

```bash
wget http://arms-apm-cn-hongkong.oss-cn-hongkong.aliyuncs.com/instgo/instgo-linux-amd64 -O instgo
```

### Linux ARM64

```bash
wget http://arms-apm-cn-hongkong.oss-cn-hongkong.aliyuncs.com/instgo/instgo-linux-arm64" -O instgo
```

### MAC ARM64

```bash
wget http://arms-apm-cn-hongkong.oss-cn-hongkong.aliyuncs.com/instgo/instgo-darwin-arm64" -O instgo
```

### MAC AMD64

```bash
wget http://arms-apm-cn-hongkong.oss-cn-hongkong.aliyuncs.com/instgo/instgo-darwin-amd64" -O instgo
```

---

## 安装 Agent

### 1. 编译二进制

```bash
chmod +x instgo
./instgo set --licenseKey=auto --regionId=cn-hongkong --dev=false
##将instgo 添加到go build编译命令前
./instgo go build {arg1} {arg2} {arg3}
```

### 1. 添加appName以及licenseKey启动参数

启动应用时添加如下参数，参数顺序无要求，例：

```bash
export ARMS_ENABLE=true
export ARMS_APP_NAME=my-service
export ARMS_REGION_ID=cn-hongkong
export ARMS_LICENSE_KEY=auto
export ARMS_WORKSPACE=default-cms-1819385687343877-cn-hongkong
```

### 2. 启动二进制

```bash
./my-service
```

---

## 其他部署环境接入方式

- [手动接入](https://help.aliyun.com/zh/arms/application-monitoring/user-guide/manually-install-the-golang-probe)
- [容器接入](https://help.aliyun.com/zh/arms/application-monitoring/user-guide/install-arms-agent-for-golang-applications-deployed-in-ack-and-acs)
