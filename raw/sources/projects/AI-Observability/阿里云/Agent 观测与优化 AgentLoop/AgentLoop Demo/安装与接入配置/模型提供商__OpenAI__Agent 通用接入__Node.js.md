## 安装 NodeSDK

```bash
npm install @ali/cms_node_sdk 
```

## 您需要手动为 Node.js 应用添加以下环境变量

```bash
export ARMS_APP_NAME=my-openai-service
export ARMS_REGION_ID=cn-hongkong
export ARMS_WORKSPACE=default-cms-1819385687343877-cn-hongkong
export ARMS_LICENSE_KEY=auto
```

## 通过 NodeSDK 自动埋点启动 OpenAI 应用

推荐使用 `-r @ali/cms_node_sdk/register` 预加载方式启动。该方式会在业务代码加载前启动 NodeSDK，并自动启用 OpenAI 插桩。

```bash
node -r @ali/cms_node_sdk/register app.js
```

应用示例：

```js
const openaiModule = require('openai');

const OpenAI = openaiModule.OpenAI || openaiModule.default || openaiModule;

const client = new OpenAI({
  apiKey: '<your-openai-api-key>',
});

async function main() {
  const response = await client.chat.completions.create({
    model: 'gpt-4o-mini',
    messages: [
      { role: 'user', content: '你好，请用一句话介绍 阿里云可观测' },
    ],
  });

  console.log(response.choices[0]?.message?.content);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
```

## （可选）在代码中手动初始化 NodeSDK

如果您不使用 `-r @ali/cms_node_sdk/register`，也可以在应用入口中手动创建并启动 NodeSDK。请确保在加载 `openai` 模块前完成 `sdk.start()`。

```js
const { NodeSDK } = require('@ali/cms_node_sdk');

async function main() {
  const sdk = new NodeSDK({
    serviceName: process.env.ARMS_APP_NAME,
    regionId: process.env.ARMS_REGION_ID,
    workspace: process.env.ARMS_WORKSPACE,
    licenseKey: process.env.ARMS_LICENSE_KEY,
    instrumentations: {
      openai: {
        traceContent: true,
      },
    },
  });

  await sdk.start();

  const openaiModule = require('openai');
  const OpenAI = openaiModule.OpenAI || openaiModule.default || openaiModule;

  const client = new OpenAI({
    apiKey: '<your-openai-api-key>',
  });

  const response = await client.chat.completions.create({
    model: 'gpt-4o-mini',
    messages: [
      { role: 'user', content: '你好，请用一句话介绍 NodeSDK。' },
    ],
  });

  console.log(response.choices[0]?.message?.content);
  await sdk.shutdown();
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
```

## 启动参数说明

- `ARMS_LICENSE_KEY`【必填】是控制台自动生成的 LicenseKey。
- `ARMS_APP_NAME`【必填】是您的应用名称，对应 NodeSDK 的 `serviceName`。
- `ARMS_REGION_ID`【必填】是 ARMS 所属地域。
- `ARMS_WORKSPACE`【可选】是 ARMS 工作空间。

## 注意事项

### 1. OpenAI 模块需要在 NodeSDK 启动后加载

使用自动埋点方式时，请通过以下命令启动应用：

```bash
node -r @ali/cms_node_sdk/register app.js
```

使用手动初始化方式时，请在 `await sdk.start()` 之后再执行 `require('openai')`。

### 2. 关于输入输出内容采集

OpenAI 插桩支持采集 prompt、response 等内容。当前 NodeSDK 默认开启 OpenAI 内容采集；如果您在代码中显式配置，可使用：

```js
instrumentations: {
  openai: {
    traceContent: true,
  },
}
```

如业务请求中包含敏感信息，请根据安全与合规要求评估是否开启内容采集。

### 3. 验证方式

启动应用并触发 OpenAI 调用后，在 ARMS 控制台查看应用 `my-openai-service` 的 Trace。预期可以看到 OpenAI 调用链路、模型信息、Token 使用量、输入输出内容等数据。

## 更多请参考文档

- [Node.js 应用接入](https://help.aliyun.com/zh/cms/cloudmonitor-2-0/manually-install-the-node-js-agent)
