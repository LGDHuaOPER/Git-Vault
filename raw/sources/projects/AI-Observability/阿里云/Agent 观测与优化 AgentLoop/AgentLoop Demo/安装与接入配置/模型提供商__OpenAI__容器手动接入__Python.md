## 步骤一 为应用所属容器集群安装组件ack-onepilot

1. 登录[容器服务管理控制台](https://cs.console.aliyun.com/)，在左侧导航栏单击集群，在集群列表页面单击目标集群名称。
2. 在左侧导航栏选择组件管理，在右侧点击安装组件，上方通过关键字搜索ack-onepilot。
3. 在弹出的页面中可以配置相关的参数，建议使用默认值，无需修改配置，点击 **下一步**。

> **注意：** 需要保证ack-onepilot组件版本大于等于5.1.0版本，如果已经安装较低版本ack-onepilot，可通过“组件管理-升级”功能升级即可。

## 步骤二 接入 AI Agent 可观测

1. 登录[容器服务管理控制台](https://cs.console.aliyun.com/)，在左侧导航栏单击集群，在集群列表页面单击目标集群名称。
2. 进入工作负载->无状态页面（有状态、守护进程集同理）
3. 切换命名空间，找到待监控的工作负载，点击最右侧操作列的 **更多图标**(三个点图标)，在弹出的对话框中点击 **YAML编辑**
4. 在弹出的 **编辑YAML** 对话框中将下方四个label添加到spec > template > metadata层级下。添加完成后点击 **更新**

```yaml
labels:
  aliyun.com/app-language: python
  armsPilotAutoEnable: "on"
  armsPilotCreateAppName: "<your-service-name>"    # 请将<your-service-name>替换为您的应用名称
  armsPilotAppWorkspace: default-cms-1819385687343877-cn-hongkong  # 当前workspace
```

一个接入 AI Agent 可观测的完整示例YAML如下

```yaml
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
        aliyun.com/app-language: python # Python应用必填，标明此应用是Python应用。
        armsPilotAutoEnable: 'on' 
        armsPilotCreateAppName: "arms-python-client"    #应用的展示名称。
        armsPilotAppWorkspace: default-cms-1819385687343877-cn-hongkong #应用接入的workspace。
    spec:
      containers:
        - image: registry.cn-hangzhou.aliyuncs.com/arms-default/python-agent:arms-python-client
          imagePullPolicy: Always
          name: client
          resources:
            requests:
              cpu: 250m
              memory: 300Mi
          terminationMessagePath: /dev/termination-log
          terminationMessagePolicy: File
      dnsPolicy: ClusterFirst
      restartPolicy: Always
      schedulerName: default-scheduler
      securityContext: {}
      terminationGracePeriodSeconds: 30
```

更详细的接入流程请[参见文档](https://help.aliyun.com/zh/arms/application-monitoring/user-guide/install-arms-agent-for-python-applications-deployed-in-ack-and-acs)
