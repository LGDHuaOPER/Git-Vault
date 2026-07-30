> Java 支持范围：ARMS 支持 OpenAI Java SDK 1.1.0+、2.X+、3.X+，以及 Spring AI 1.X+ 的 OpenAI ChatModel / ChatClient 调用观测。

## 步骤一 安装 AI Agent 可观测组件ack-onepilot

1. 登录[容器服务管理控制台](https://cs.console.aliyun.com/)，在左侧导航栏单击集群，在集群列表页面单击目标集群名称。
2. 在左侧导航栏选择组件管理，在右侧点击安装组件，上方通过关键字搜索ack-onepilot。
3. 在弹出的页面中可以配置相关的参数，建议使用默认值，无需修改配置，点击 **下一步**。

> **注意：** 需要保证ack-onepilot组件版本大于等于5.1.0版本，如果已经安装较低版本ack-onepilot，可通过“组件管理-升级”功能升级即可。

---

## 步骤二 接入 AI Agent 可观测

1. 登录[容器服务管理控制台](https://cs.console.aliyun.com/)，在左侧导航栏单击集群，在集群列表页面单击目标集群名称。
2. 进入工作负载->无状态页面（有状态、守护进程集同理）
3. 切换命名空间，找到待监控的工作负载，点击最右侧操作列的 **更多图标**(三个点图标)，在弹出的对话框中点击 **YAML编辑**
4. 在弹出的 **编辑YAML** 对话框中将下方四个label添加到spec > template > metadata层级下。添加完成后点击 **更新**

```yaml
labels:
  aliyun.com/app-language: java
  armsPilotAutoEnable: "on"
  armsPilotCreateAppName: "<your-service-name>"    # 请将<your-service-name>替换为您的应用名称
  armsPilotAppWorkspace: default-cms-1819385687343877-cn-hongkong  # 当前workspace
```

一个接入 AI Agent 可观测的完整示例YAML如下

```yaml
apiVersion: apps/v1 # for versions before 1.8.0 use apps/v1beta1
kind: Deployment
metadata:
  name: arms-springboot-demo
  namespace: arms-demo
  labels:
    app: arms-springboot-demo
spec:
  replicas: 2
  selector:
    matchLabels:
      app: arms-springboot-demo
  template:
    metadata:
      labels:
        app: arms-springboot-demo
        aliyun.com/app-language: java # Java应用必填，标明此应用是Java应用。
        armsPilotAutoEnable: "on"
        armsPilotCreateAppName: "arms-k8s-demo"
        armsPilotAppWorkspace: default-cms-1819385687343877-cn-hongkong
    spec:
      containers:
        - resources:
            limits:
              cpu: 0.5
          image: registry.cn-hangzhou.aliyuncs.com/arms-docker-repo/arms-springboot-demo:v0.1
          imagePullPolicy: Always
          name: arms-springboot-demo
          env:
            - name: SELF_INVOKE_SWITCH
              value: "true"
            - name: COMPONENT_HOST
              value: "arms-demo-component"
            - name: COMPONENT_PORT
              value: "6666"
            - name: MYSQL_SERVICE_HOST
              value: "arms-demo-mysql"
            - name: MYSQL_SERVICE_PORT
              value: "3306"
```

更详细的接入流程请[参见文档](https://help.aliyun.com/zh/arms/application-monitoring/user-guide/install-arms-agent-for-java-applications-deployed-in-ack-and-acs?spm=5176.2020520112.console-base_help.dexternal.424a462e7UeJz7)
