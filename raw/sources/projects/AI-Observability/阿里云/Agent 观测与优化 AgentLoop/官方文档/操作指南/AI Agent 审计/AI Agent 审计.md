---
title: "AI Agent 审计"
source: "https://help.aliyun.com/zh/document_detail/3045691.html?spm=a2c4g.11186623.help-menu-3033820.d_3_3.6d4432c7fIMWqF&scm=20140722.H_3045691._.OR_help-T_cn~zh-V_1"
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
"word-count": "1408"
更新时间: "2026-07-08 19:01:40"
---
AI Agent 具备文件系统操控、Shell 命令执行、API 调用、网络外联等系统级能力，运行过程中存在数据泄漏、行为异常、权限越界和安全合规风险。AgentLoop 审计模块面向各类 AI Agent 应用，提供从数据接入、风险检测到证据调查的全链路审计能力，帮助安全团队和应用 Owner 建立 Agent 行为可观测与风险治理体系。

## 功能概述

AgentLoop 审计模块围绕"接入配置 → 审计管理 → 风险发现 → 实体调查 → 审计事实回放"的核心流程，提供以下核心功能：

-   **接入中心**：支持多种 AI Agent 类型的会话日志接入和 AI 节点 Runtime/eBPF 接入，当前支持 Qoder、Cursor、Claude Code、Codex 等 AI Coding Agent 以及 AI 节点 Runtime/eBPF 运行时采集。
    
-   **审计管理**：管理应用风险审计与运行时风险审计状态，通过应用风险审计开关和运行时风险审计开关启停安全检测任务，并查看已接入应用、运行时主机、最近数据时间和 24 小时流量趋势。
    
-   **风险审计**：提供风险相关 Dashboard 视图，需在审计管理中启用对应范围的风险审计检测后展示分析结果，用于查看风险概览、数据泄漏、敏感文件等维度。
    
-   **实体调查**：以实体为中心查看关联风险、出现会话和共现关系，支持从 Secret、PII、文件路径、外联域名、目标 IP、应用、主机、用户、来源 IP、Tool 和命令等实体出发反查上下文。
    
-   **审计事实**：提供 Session 浏览、Token 分析和行为分析，直接描述原始审计事实和标准化后的审计活动数据，不依赖风险审计 Scheduled SQL 开启。
    

## 核心价值

审计模块帮助用户回答以下关键问题：

-   今天最高优先级的风险是什么？
    
-   这个 Session 是否发生了数据泄漏？
    
-   某个 AccessKey / Domain / 用户牵涉了哪些调用链？
    
-   敏感信息是从哪里进入 Agent 上下文的？
    
-   应该生成什么样的防护策略？
    

## 适用角色

| **角色** | **主要诉求** |
| --- | --- |
| 安全运营人员 | 发现优先风险、调查和验证 |
| Agent 应用 Owner | 了解负责的 Agent 是否存在风险 |
| 平台管理员 | 管理采集和安全检查配置 |

## 前提条件

-   已开通 AgentLoop 服务。
    
-   已创建智能体空间（AgentSpace）。
    
-   目标主机或集群已部署 AI Agent 应用（如 Qoder、Cursor、Claude Code 等）。
    

## 使用流程

完成以下步骤即可使用审计功能：

1.  **接入数据**：在接入中心配置 AI 应用日志采集或 AI 节点 Runtime/eBPF 采集，将 Agent 行为数据上报至 AgentLoop。具体操作请参见[审计接入指南](https://help.aliyun.com/zh/document_detail/3045692.html)。
    
2.  **查看审计事实**：数据接入后即可在审计事实中浏览 Session、查看 Token 分析和行为分析，用于验证接入效果和还原原始交互上下文。具体操作请参见[审计事实](https://help.aliyun.com/zh/document_detail/3045698.html)。
    
3.  **开启风险审计**：在审计管理页面开启应用风险审计和运行时风险审计全局开关，系统将自动创建、更新或恢复安全检测任务。具体操作请参见[审计管理](https://help.aliyun.com/zh/document_detail/3045693.html)。
    
4.  **查看风险审计**：在风险审计查看风险态势、数据泄漏和敏感文件等安全视图。具体操作请参见[风险审计](https://help.aliyun.com/zh/document_detail/3045696.html)。
    
5.  **实体调查**：从风险相关实体出发反查出现会话、共现关系和风险证据，完成深入安全调查。具体操作请参见[实体调查](https://help.aliyun.com/zh/document_detail/3045697.html)。
    

## 数据架构简述

审计模块的数据处理分为以下层次：

-   **事实原始层**：应用侧 Agent 事件日志（agent-event、agent-event-webtracking）和 eBPF 运行时事件（ebpf-event），是风险检测、审计事实和调查分析的基础。
    
-   **标准化活动层**：把应用侧和运行时侧的 Agent 行为整理为统一口径的审计活动数据，供风险检测、审计事实和调查入口使用。
    
-   **低保真发现层**：security-event 存储规则型低保真安全发现。
    
-   **高保真事件层**：incident-event 存储可行动的高保真安全事件。
    
-   **风险查询视图层**：risk\_view 支撑风险排序、报表和调查入口。
    

数据存储基于日志服务 SLS，使用 Scheduled SQL 实现定时安全检测任务。

### Logstore 命名约定

SLS **物理 Logstore 名**（API `logstore` 参数、接入配置、查询示例）一律使用 **中划线（kebab-case）**，代码真源见 `src/constants/audit-logstores.ts`。

| **逻辑键** | **SLS 物理名** | **用途** |
| --- | --- | --- |
| `agentEvent` | agent-event | 存储 AI Agent 会话日志的标准化事件 |
| `agentEventWebtracking` | agent-event-webtracking | 存储 WebTracking 写入链路的 AI Agent 会话日志 |
| `ebpfEvent` | ebpf-event | 存储 eBPF Runtime 原始运行时事件 |
| `securityEvent` | security-event | 存储低保真安全发现 |
| `incidentEvent` | incident-event | 存储高保真安全事件 |

以下名称**不等于** Logstore 物理名，文档与 SQL 中可保留下划线写法：

-   SQL 字段名（如 `security_event_id`）
    
-   逻辑表 / 视图名和查询中间层名称
    
-   Scheduled SQL **任务名**（如 `agentloop_security_event_application_etl`）
    
-   数据契约中的逻辑标识（如 `source_scope = 'application'`）
    

## 相关文档

-   [审计接入指南](https://help.aliyun.com/zh/document_detail/3045692.html)
    
-   [审计管理](https://help.aliyun.com/zh/document_detail/3045693.html)
    
-   [审计规则说明](https://help.aliyun.com/zh/document_detail/3045694.html)
    
-   [风险事件字段说明](https://help.aliyun.com/zh/document_detail/3045695.html)
    
-   [风险审计](https://help.aliyun.com/zh/document_detail/3045696.html)
    
-   [实体调查](https://help.aliyun.com/zh/document_detail/3045697.html)
    
-   [审计事实](https://help.aliyun.com/zh/document_detail/3045698.html)