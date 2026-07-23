---
title: "AgentLoop 控制台内嵌分享接入指南"
source: "https://help.aliyun.com/zh/document_detail/3033825.html?spm=a2c4g.11186623.help-menu-3033820.d_5_0.39162e97EUhoEP"
author:
  - "阿里云计算"
published:
created: 2026-07-23
description: "AgentLoop 是阿里云推出的面向企业级智能体的一站式自进化平台，提供 Agent全栈观测与审计、Agent评估与实验、Agent资产管理与持续优化等核心能力，助力企业构建智能体进化数据飞轮，持续提升企业 Agent的质量、效率、成本与安全性。面向企业真实生产环境 Agent应用提供 Agent-as-a-Judge、Agent Playground、Trace2Dataset等 Agent应用范式的场景化闭环能力，让 Agent在生产环境中形成可观测、可评估、可优化的持续进化飞轮。"
tags:
  - "Clippings"
  - "AI可观测"
  - "阿里云"
  - "阿里云/AgentLoop"
  - "官方文档"
"word-count": "1763"
更新时间: "2026-06-18 11:20:30"
---
## **概述**

AgentLoop 控制台支持以内嵌方式集成到第三方系统中。您可以通过免登录链接打开指定 AgentSpace 页面，并通过 URL 参数控制页面中的导航、切换入口和部分业务参数。

推荐使用以下域名作为内嵌访问入口：

```
https://agentloop4service.console.aliyun.com
```

请勿将普通控制台域名与内嵌域名混用。内嵌访问应始终使用本文中的 4service 域名，避免因登录态不一致导致页面无法访问。

## **页面地址格式**

AgentSpace 页面地址格式如下：

```
https://agentloop4service.console.aliyun.com/agentloop/region/{regionId}/agentspace/{agentSpaceName}/app/{appPath}
```

参数说明：

| **参数** | **说明** |
| --- | --- |
| `{regionId}` | AgentSpace 所在地域，例如`cn-hangzhou` |
| `{agentSpaceName}` | AgentSpace 名称 |
| `{appPath}` | 需要打开的页面路径 |

示例：

```
https://agentloop4service.console.aliyun.com/agentloop/region/{regionId}/agentspace/{agentSpaceName}/app/overview
```

常见页面路径：

| **页面** | `**appPath**` | **说明** |
| --- | --- | --- |
| 总览  | `overview` | 打开 AgentSpace 总览页面 |
| Agent 洞察 | `agent-insight` | 打开 Agent 观测分析页面 |
| AI Agent 可观测 | `llm-agent` | 打开 AI Agent 应用和 Trace 查看页面 |
| 评估  | `evaluation` | 打开评估任务页面 |
| 接入中心 | `integrating-center` | 打开接入中心页面 |

## **生成免登录链接**

您可以参考阿里云控制台免登录链接生成方式，将 AgentLoop 目标页面作为 `Destination`，生成可放入 iframe 的免登录链接。

### **步骤一：生成 Destination**

`Destination` 是用户免登录后最终打开的 AgentLoop 页面。

```
const destination = new URL(
  'https://agentloop4service.console.aliyun.com/agentloop/region/{regionId}/agentspace/{agentSpaceName}/app/evaluation'
);

destination.searchParams.set('hiddenSwitch', 'true');
destination.searchParams.set('hiddenBackHome', 'true');
destination.searchParams.set(
  'embed',
  JSON.stringify({
    sidebar: 'hidden',
    eval: {
      dataSource: 'trace',
      serviceName: '{serviceName}',
    },
  })
);
```

### **步骤二：获取临时身份**

第三方系统服务端调用 STS `AssumeRole`，获取临时身份。建议按用户、租户或业务资源范围配置最小权限。一个Token只能使用一次，详情可参考[AssumeRole - 获取扮演角色的临时身份凭证](https://help.aliyun.com/zh/ram/developer-reference/api-sts-2015-04-01-assumerole)。

常用参数：

| **参数** | **说明** |
| --- | --- |
| `RoleArn` | 被扮演的 RAM 角色 ARN |
| `RoleSessionName` | 会话名称，建议使用可审计的业务用户标识 |
| `DurationSeconds` | 临时身份有效期 |
| `Policy` | 可选，用于进一步收敛本次会话可访问的资源范围 |

请勿在浏览器前端保存或传输长期 AccessKey。

### **步骤三：获取 SigninToken**

调用RAM单点登录SSO，获取`SigninToken`。拼接链接的形式如下。注意：`TicketType`必须指定为`mini`。

```
http://signin.aliyun.com/federation?Action=GetSigninToken
                    &AccessKeyId=<STS返回的临时AK>
                    &AccessKeySecret=<STS返回的临时Secret>
                    &SecurityToken=<STS返回的安全Token>
                    &TicketType=mini
```

> 为避免泄露敏感信息，`GetSigninToken` 应仅在服务端调用，不要在浏览器前端拼接或暴露临时密钥。

### **步骤四：生成免登录链接**

将返回的`SigninToken`拼接到准备好的链接中，生成免密访问链接。

```
const loginUrl = new URL('https://signin.aliyun.com/federation');

loginUrl.searchParams.set('Action', 'Login');
loginUrl.searchParams.set('LoginUrl', 'https://{your-domain}/login-expired');
loginUrl.searchParams.set('Destination', destination.toString());
loginUrl.searchParams.set('SigninToken', signinToken);

console.log(loginUrl.toString());
```

最终 URL 形态：

```
http://signin.aliyun.com/federation?Action=Login
                            &LoginUrl=<登录失效跳转的地址，一般配置为自建Web配置302跳转的URL。需要使用encodeURL对LoginUrl进行转码。>
                            &Destination=<实际访问页面。如果有参数，则需要使用encodeURL对参数进行转码。>
                            &SigninToken=<获取的登录Token，需要使用encodeURL对Token进行转码。>
```

iframe 示例：

```
<iframe
  src="{loginUrl}"
  width="100%"
  height="100%"
  frameborder="0"
  allowfullscreen
></iframe>
```

## **内嵌参数**

AgentLoop 支持以下 URL 参数控制内嵌页面展示和行为。

### `**embed**`

`embed` 用于传递结构化内嵌配置，值为 JSON 字符串。实际拼接到 URL 时，需要进行 URL 编码。

可读形式：

```
?embed={"sidebar":"hidden","eval":{"dataSource":"trace","serviceName":"{serviceName}"}}
```

结构说明：

```
interface EmbedConfig {
  sidebar?: 'hidden';
  eval?: {
    dataSource?: 'trace' | 'log' | 'dataset';
    serviceName?: string;
  };
}
```

参数说明：

| **参数** | **可选值** | **说明** |
| --- | --- | --- |
| `embed.sidebar` | `hidden` | 隐藏 AgentLoop 左侧导航栏，适合第三方系统自行提供导航的场景 |
| `embed.eval.dataSource` | `trace` / `log` / `dataset` | 在评估页面新建任务时，预填数据源类型 |
| `embed.eval.serviceName` | 服务名 | 在评估页面新建任务时，预填 Trace 数据源的服务名 |

生成示例：

```
const targetUrl = new URL(
  'https://agentloop4service.console.aliyun.com/agentloop/region/{regionId}/agentspace/{agentSpaceName}/app/evaluation'
);

targetUrl.searchParams.set(
  'embed',
  JSON.stringify({
    sidebar: 'hidden',
    eval: {
      dataSource: 'trace',
      serviceName: '{serviceName}',
    },
  })
);
  
console.log(targetUrl.toString());
```

生成后的 URL 示例：

```
https://agentloop4service.console.aliyun.com/agentloop/region/{regionId}/agentspace/{agentSpaceName}/app/evaluation?embed=%7B%22sidebar%22%3A%22hidden%22%2C%22eval%22%3A%7B%22dataSource%22%3A%22trace%22%2C%22serviceName%22%3A%22%7BserviceName%7D%22%7D%7D
```

### `**hiddenSwitch**`

隐藏 AgentSpace 切换入口。

```
hiddenSwitch=true
```

如果第三方系统已经固定当前 AgentSpace，建议开启该参数，避免用户在内嵌页面中切换到其他空间。

### `**hiddenBackHome**`

隐藏“返回首页”入口。

```
hiddenBackHome=true
```

如果第三方系统只希望用户停留在指定 AgentSpace 页面，建议开启该参数，避免用户返回 AgentLoop 首页。

## **推荐参数组合**

### **隐藏左侧导航**

```
https://agentloop4service.console.aliyun.com/agentloop/region/{regionId}/agentspace/{agentSpaceName}/app/overview?embed=%7B%22sidebar%22%3A%22hidden%22%7D
```

### **禁止切换空间和返回首页**

```
https://agentloop4service.console.aliyun.com/agentloop/region/{regionId}/agentspace/{agentSpaceName}/app/overview?hiddenSwitch=true&hiddenBackHome=true
```

### **隐藏导航并预填评估任务参数**

```
https://agentloop4service.console.aliyun.com/agentloop/region/{regionId}/agentspace/{agentSpaceName}/app/evaluation?hiddenSwitch=true&hiddenBackHome=true&embed=%7B%22sidebar%22%3A%22hidden%22%2C%22eval%22%3A%7B%22dataSource%22%3A%22trace%22%2C%22serviceName%22%3A%22%7BserviceName%7D%22%7D%7D
```

## **AI Agent 可观测页面**

AI Agent 可观测页面路径为：

```
https://agentloop4service.console.aliyun.com/agentloop/region/{regionId}/agentspace/{agentSpaceName}/app/llm-agent
```

### **打开应用列表**

不传 `traceId` 时，页面默认打开应用列表。

```
https://agentloop4service.console.aliyun.com/agentloop/region/{regionId}/agentspace/{agentSpaceName}/app/llm-agent?hiddenSwitch=true&hiddenBackHome=true
```

### **打开 Trace 详情**

传入 `traceId` 时，页面打开对应 Trace 详情。

```
https://agentloop4service.console.aliyun.com/agentloop/region/{regionId}/agentspace/{agentSpaceName}/app/llm-agent?traceId={traceId}&startTime={startTime}&endTime={endTime}&hiddenSwitch=true&hiddenBackHome=true
```

参数说明：

| **参数** | **必填** | **说明** |
| --- | --- | --- |
| `traceId` | 是   | Trace ID，兼容 `traceid` 小写写法 |
| `startTime` | 否   | 查询开始时间，支持秒级或毫秒级时间戳 |
| `endTime` | 否   | 查询结束时间，支持秒级或毫秒级时间戳 |
| `spanId` | 否   | 指定 Span ID |
| `initialTab` | 否   | Trace 详情初始页签 |
| `querySource` | 否   | Trace 查询来源标识 |
| `source` | 否   | 页面来源标识 |
| `spanFiltersQuery` | 否   | Span 明细过滤条件 |
| `spanFiltersTimeSeriesQuery` | 否   | Span 时序过滤条件 |

如果未传 `startTime` 或 `endTime`，页面会使用默认时间范围查询。

## **接入中心页面**

接入中心页面路径为：

```
https://agentloop4service.console.aliyun.com/agentloop/region/{regionId}/agentspace/{agentSpaceName}/app/integrating-center
```

可按需组合内嵌参数，例如：

```
https://agentloop4service.console.aliyun.com/agentloop/region/{regionId}/agentspace/{agentSpaceName}/app/integrating-center?hiddenSwitch=true&hiddenBackHome=true&embed=%7B%22sidebar%22%3A%22hidden%22%7D
```

## **接入建议**

1.  **服务端生成免登录链接**：`AssumeRole`、`GetSigninToken` 和最终 Login URL 都应由服务端完成，浏览器前端只接收最终可访问的 iframe URL。
    
2.  **统一使用 4service 域名**：`Destination` 必须使用 `agentloop4service.console.aliyun.com`。
    
3.  **正确处理 URL 编码**：`Destination` 本身可能包含 query 参数，写入 Login URL 时必须整体编码。建议使用 `URL` 和 `URLSearchParams` 生成。
    
4.  **按需隐藏控制台导航**：如果外部系统已经提供导航，建议组合使用 `embed={"sidebar":"hidden"}`、`hiddenSwitch=true`、`hiddenBackHome=true`。
    
5.  **控制免登录链接有效期**：请在 `SigninToken` 失效前刷新免登录链接，避免 iframe 内页面因登录态过期无法访问。
    
6.  **最小权限授权**：RAM 角色权限应按业务需要收敛到必要的 AgentLoop、日志和观测资源范围。
    

## **常见问题**

| **问题**              | **排查建议**                                                                 |
| ------------------- | ------------------------------------------------------------------------ |
| iframe 中显示未登录       | 确认使用的是 `agentloop4service.console.aliyun.com`，且 `Destination` 已完整 URL 编码 |
| iframe 中提示无权限       | 确认 RAM 角色权限覆盖目标 AgentSpace 及其关联资源                                        |
| 用户可以切换 AgentSpace   | 在 URL 中增加 `hiddenSwitch=true`                                            |
| 用户可以返回 AgentLoop 首页 | 在 URL 中增加 `hiddenBackHome=true`                                          |
| 左侧导航仍显示             | 确认 `embed` 参数已正确 URL 编码，并包含 `{"sidebar":"hidden"}`                       |
| 评估新建任务未预填服务名        | 确认进入的是 `app/evaluation` 页面，并且 `embed.eval.serviceName` 对应的服务名存在          |