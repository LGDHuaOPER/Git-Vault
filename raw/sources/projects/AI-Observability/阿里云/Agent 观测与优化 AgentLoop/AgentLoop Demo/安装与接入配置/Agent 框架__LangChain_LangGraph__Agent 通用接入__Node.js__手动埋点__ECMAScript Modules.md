以下内容使用 阿里云 CMS Node.js SDK 构造 Express 框架应用的 Trace 数据并上传到云监控。

### 1. 前提条件

- 支持的运行时环境：
    
    - Node.js v16 及以上版本。
    - 需要注意的是，仅支持 Node.js 的 Active（活跃）或 Maintenance LTS（长期维护）版本。虽然更早的 Node 版本可能可以工作，但它们未经过官方测试，因此不保证能够正常运行。
    - 更多版本兼容性问题，请查看 [Node.js Supported Versions](https://nodejs.org/en/about/releases/)。
- 支持的库和框架 阿里云 CMS Node.js SDK 支持多种流行的 Node.js 库自动埋点，包括：
    
    - HTTP/HTTPS 客户端和服务端
    - Express、Koa 等 Web 框架
    - MySQL、PostgreSQL、MongoDB 等数据库客户端
    - Redis、Kafka 等中间件
    - gRPC、Socket.IO 等通信协议
- 特别注意：务必确保nodesdk.start() 方法 的执行 先于所有的业务代码
    

### 2. 创建示例应用程序（可选）

> 这一步将演示如何构建一个简单的 Web 应用程序。如果您已经有编写好的 Node.js 应用程序，这一步可跳过。

- 新建一个项目目录，在目录下执行以下的命令，会创建一个空的 package.json 文件

```bash
npm init -y
```

- 安装依赖包

```bash
npm install express
```

- 编写应用代码 创建一个名为 app.js 的文件，添加如下内容，这段代码模拟扔骰子游戏，返回1-6之间的一个随机数。

```javascript
// import './instrumentation.js';
import express from 'express';


const PORT = parseInt(process.env.PORT || '8080');
const app = express();

function getRandomNumber(min, max) {
  return Math.floor(Math.random() * (max - min + 1) + min);
}

app.get('/rolldice', (req, res) => {
  res.send(getRandomNumber(1, 6).toString());
});

app.listen(PORT, () => {
  console.log(`Listening for requests on http://localhost:${PORT}`);
});
```

- 此时应用已经编写完成，执行 `node app.js` 命令即可运行应用，访问地址为 [http://localhost:8080/rolldice](http://localhost:8080/rolldice)

### 3. 安装 阿里云 CMS Node.js SDK

- 运行以下命令来安装相应的包。

```bash
npm install @loongsuite/cms_node_sdk
```

### 4. 配置 阿里云 CMS Node.js SDK

为了让 阿里云 CMS Node.js SDK 能够自动收集应用程序的追踪数据并上报到云监控2.0平台，需要创建一个插桩配置文件。该文件负责初始化 SDK、配置数据导出器和启用自动插桩功能。 创建一个名为 instrumentation.js 的文件。

```javascript
/*instrumentation.js*/
import { NodeSDK } from '@loongsuite/cms_node_sdk';

const sdk = new NodeSDK({
  serviceName: "",
  licenseKey: "auto",
  regionId: "cn-hongkong",
  workspace: "default-cms-1819385687343877-cn-hongkong", // 如果是默认 workspace, 则不需要设置
});

sdk.start();

export { sdk };

/** 业务代码主入口 **/
// 第一行导入 instrumentation.js
import './instrumentation.js';
//  然后 其他模块导入 ..
// import express from 'express';

```

### 5. 手动创建 Span（可选）

在某些场景下您可能需要手动创建 Span 来获得更细粒度的追踪信息，下面给出示例：

```javascript
const tracer = sdk.getTracerManager().getTracer('manual-demo');

const server = http.createServer((req, res) => {
  const span = tracer.startSpan(`${req.method} ${req.url}`, { kind: 1 /* SERVER */ });
  try {
    // 从 sdk 上获取上下文管理对象 和 trace管理对象，用tm.startSpan 创建Span对象
    const tm = sdk.getTracerManager();
    const cm = sdk.getContextManager();
    cm.with(tm.setSpan(cm.active(), span), () => {
      const child = tracer.startSpan('work:handle_request');
      child.end();
      res.statusCode = 200;
      res.setHeader('content-type', 'text/plain');
      res.end('ok');
    });
  } finally {
    span.end();
  }
});

```

### 6. 运行应用

```bash
node --experimental-loader=@loongsuite/cms_node_sdk/import-hooks app.js
```

## 更多请参考文档

- [Node.js应用接入](https://help.aliyun.com/zh/cms/cloudmonitor-2-0/manually-install-the-node-js-agent)

接入过程遇到任何问题，欢迎与我们联系！
