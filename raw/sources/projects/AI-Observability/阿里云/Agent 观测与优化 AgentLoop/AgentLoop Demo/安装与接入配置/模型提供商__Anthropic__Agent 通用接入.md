# 下载安装Python Agent

## 从PyPI仓库下载探针安装器

```bash
pip3 install aliyun-bootstrap
```

## 您需要手动为Python应用添加以下环境变量

```bash
export ARMS_APP_NAME=my-service
export ARMS_REGION_ID=cn-hongkong
export ARMS_WORKSPACE=default-cms-1819385687343877-cn-hongkong
export ARMS_LICENSE_KEY=auto
```

## （可选）Docker环境安装参考对于Docker环境，可以参考以下Dockerfile示例修改您的Dockerfile文件

```bash
# 添加环境变量
ENV ARMS_APP_NAME=my-service
ENV ARMS_REGION_ID=cn-hongkong
ENV ARMS_WORKSPACE=default-cms-1819385687343877-cn-hongkong
ENV ARMS_LICENSE_KEY=auto
```

## 使用aliyun-bootstrap安装Python探针

### 1.为了加快安装，建议您使用如下命令先配置镜像仓库

```bash
pip config set global.index-url https://mirrors.aliyun.com/pypi/simple/ && pip config set install.trusted-host mirrors.aliyun.com
```

### 2.安装探针

```bash
aliyun-bootstrap -a install
```

## 通过ARMS Python探针启动应用

```bash
aliyun-instrument python app.py
```

## （可选）不使用Python探针启动的方式 在应用主入口文件引入Python探针，然后启动应用。例如在main.py/app.py文件中引入Python探针

```bash
from aliyun.opentelemetry.instrumentation.auto_instrumentation import  sitecustomize
```

#### 启动参数说明

- ARMS_LICENSE_KEY 【必填】是控制台自动生成的。
- ARMS_APP_NAME 【必填】是您的应用名称。

---

## 注意事项

### 1.如果应用使用Unicorn启动，需要替换为Gunicorn

### 2.如果有使用gevent协程，则需要设置环境变量GEVENT_ENABLE=true

## 更多请参考文档

- [Python应用接入](https://help.aliyun.com/zh/arms/application-monitoring/user-guide/manually-install-the-python-probe)
