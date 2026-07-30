下面是使用 OpenTelemetry 为 Dify 应用自动埋点并接入云监控2.0的步骤。

### 1. 前提条件

- Dify 版本 >= 1.6.0

### 2. 配置应用性能追踪

1. 登录 Dify 控制台，并进入需要监控的 Dify 应用。
2. 在左侧导航栏单击**监测**。
3. 单击**追踪应用性能**，然后在**云监控**区域单击**配置**。
4. 在弹出的对话框中输入 License Key 和 Endpoint，并自定义App Name（云监控2.0控制台显示的应用名称），然后单击**保存并启用**。

- **License Key**（鉴权Token）

```bash
auto
```

- **Endpoint**（上报点）

```bash
https:///apm/trace/opentelemetry/default-cms-1819385687343877-cn-hongkong/
```

更详细的接入流程请[参见文档](https://help.aliyun.com/zh/arms/application-monitoring/user-guide/connect-a-dify-application-to-arms-application-monitoring)
