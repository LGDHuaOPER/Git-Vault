通过阿里云 CMS Node.js SDK 的自动插桩技术，无需修改应用代码即可实现 Node.js 应用的可观测性数据采集并接入云监控。

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
    - langchain、langgraph、openai、 vercel ai 、@anthropic-ai/claude-agent-sdk 等AI 框架或SDK

### 2. 安装依赖包

- 运行以下命令来安装相应的包。

```bash
npm install @loongsuite/cms_node_sdk
```

### 3. 配置阿里云 CMS Node SDK

```bash
export ARMS_LICENSE=auto
export CMS_SERVICE_NAME=
export ARMS_REGION_ID=cn-hongkong
# 如果是默认 workspace, 则不需要设置
export ARMS_WORKSPACE=default-cms-1819385687343877-cn-hongkong
node -r @loongsuite/cms_node_sdk/register app.js
```

## 更多请参考文档

- [Node.js应用接入](https://help.aliyun.com/zh/cms/cloudmonitor-2-0/manually-install-the-node-js-agent)

接入过程遇到任何问题，欢迎与我们联系！
