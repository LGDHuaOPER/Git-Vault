> Java 支持范围：ARMS 支持 OpenAI Java SDK 1.1.0+、2.X+、3.X+，以及 Spring AI 1.X+ 的 OpenAI ChatModel / ChatClient 调用观测。

## 步骤一 下载Agent

#### 方式一：手动下载Agent

[点击下载探针](https://arms-apm-cn-hongkong.oss-cn-hongkong.aliyuncs.com/aliyun-java-agent.jar)，下载完成后将探针包传递到应用运行环境中

#### 方式二：通过wget下载Agent

通过如下命令将ARMS探针包下载到应用运行的环境中：

通过公网环境下载

```bash
wget http://arms-apm-cn-hongkong.oss-cn-hongkong.aliyuncs.com/aliyun-java-agent.jar -O aliyun-java-agent.jar
```

通过VPC网络下载

```bash
wget http://arms-apm-cn-hongkong.oss-cn-hongkong-internal.aliyuncs.com/aliyun-java-agent.jar -O aliyun-java-agent.jar
```

> **注意：** 当前下载的探针版本为线上最新推荐版本，如果需要下载指定版本探针, [点击查看探针版本列表](https://help.aliyun.com/zh/arms/application-monitoring/user-guide/versions-of-arms-agent-for-java?scm=20140722.S_help%40%40%E6%96%87%E6%A1%A3%40%40128811._.ID_help%40%40%E6%96%87%E6%A1%A3%40%40128811-RL_%E6%8E%A2%E9%92%88%E7%89%88%E6%9C%AC%E5%88%97%E8%A1%A8-LOC_doc%7EUND%7Eab-OR_ser-PAR1_212a5d4017479699695472430d8d06-V_4-RE_new5-P0_0-P1_0&spm=a2c4g.11186623.help-search.i35)

---

## 步骤二 安装Agent

#### 方式一：添加启动参数

启动应用时添加如下参数，参数顺序无要求，例：

```bash
-javaagent:path/to/aliyun-java-agent.jar
-Darms.licenseKey=auto
-Darms.appName=my-service
-Darms.workspace=default-cms-1819385687343877-cn-hongkong
```

#### 方式二：自定义配置文件

在探针所在目录创建一个arms-agent.config的配置文件，文件内容如下：

```properties
arms.licenseKey=auto
arms.appName=my-service
arms.workspace=default-cms-1819385687343877-cn-hongkong
```

启动应用时添加如下参数

```bash
-javaagent:path/to/aliyun-java-agent.jar
-Darms.config.file=/path/to/arms-agent.config
```

> **提示：** 安装Java Agent需确保目标JVM最大堆内存大于300M

#### 启动参数说明

- `arms.licenseKey` 【必填】是控制台自动生成的。
- `arms.appName` 【必填】是您的应用名称。
- `arms.workspace` 【选填】是您当前应用接入的workspace, 需要注意，探针从4.4.x版本开始支持指定该参数。

---

## 其他部署环境接入方式

- [Tomcat运行环境配置](https://help.aliyun.com/zh/arms/application-monitoring/user-guide/manually-install-arms-agent-for-java-applications?spm=5176.arms.console-base_help.dexternal.6c32f167QIwFCD#ECS)
- [Jetty运行环境配置](https://help.aliyun.com/zh/arms/application-monitoring/user-guide/manually-install-arms-agent-for-java-applications?spm=5176.arms.console-base_help.dexternal.6c32f167QIwFCD#ECS)

## 常见问题

- [探针接入常见问题](https://help.aliyun.com/zh/arms/application-monitoring/support/faqs-about-agent-integration)
