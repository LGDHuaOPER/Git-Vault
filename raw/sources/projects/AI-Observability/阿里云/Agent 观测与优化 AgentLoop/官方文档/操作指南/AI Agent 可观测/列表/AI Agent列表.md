---
title: "AI Agent列表"
source: "https://help.aliyun.com/zh/document_detail/3042598.html?spm=a2c4g.11186623.help-menu-3033820.d_3_1_2_0.5854c51flhrHDx"
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
"word-count": "615"
更新时间: "2026-06-25 11:30:21"
---
AI Agent列表页面以列表形式集中展示所有已接入的AI Agent及其核心性能指标，帮助您快速掌握各Agent的运行状态和资源消耗情况。

## 前提条件

-   已开通云监控2.0服务并创建工作空间。
    
-   已将AI Agent接入可观测平台，具体参考[开始接入 AI Agent 可观测](https://help.aliyun.com/zh/cms/cloudmonitor-2-0/starting-to-integrate-ai-agent-observability)。
    

## 操作步骤

1.  登录[云监控2.0控制台](https://cmsnext.console.aliyun.com/)，选择目标工作空间。
    
2.  在左侧导航栏选择**AI Agent可观测**。
    
3.  单击**AI Agent** Tab，进入**AI Agent**子Tab页面，即可查看AI Agent列表。
    

## 功能说明

### 搜索与筛选

页面顶部提供搜索栏和筛选按钮，支持按关键字快速定位目标Agent。

**说明**

搜索时需输入至少4个字符才能触发搜索。

### 列表字段说明

AI Agent列表包含以下字段：

| **字段** | **说明** |
| --- | --- |
| AI Agent名称 | Agent的标识名称，例如CodeTutor、order\\_agent、claude-agent等。单击名称可进入该Agent的详情页面，查看更详细的运行数据和调用链路。 |
| 应用名称 | Agent所属的AI应用名称，例如dashscope-multimodal、langgraph-multi-agent等。 |
| 平均请求次数 | Agent在选定时间范围内的平均请求数量。该列附带迷你趋势图，便于您直观观察请求量的变化趋势。 |
| 平均错误次数 | Agent在选定时间范围内的平均错误数量。该列附带迷你趋势图，便于您快速发现异常波动。 |
| 平均延迟时间 | Agent处理请求的平均响应延迟，反映Agent的整体处理性能。 |
| 平均TTFT | 首Token生成时间（Time To First Token），即从发起请求到返回第一个Token的平均耗时。该指标直接影响用户的感知响应速度。 |
| 每分钟平均Token消耗 | Agent每分钟消耗的Token数量，用于评估Agent的资源消耗水平和成本。 |

### 分页

列表默认每页展示10条记录，页面底部显示Agent总数及分页控件，您可以翻页查看更多Agent信息。

## 后续操作

在AI Agent列表中，单击目标Agent的名称，即可进入Agent详情页面，查看该Agent的详细性能指标、调用链路及历史趋势数据。