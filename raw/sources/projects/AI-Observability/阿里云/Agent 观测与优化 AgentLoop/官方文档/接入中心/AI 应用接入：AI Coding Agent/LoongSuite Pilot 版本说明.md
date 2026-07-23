---
title: "LoongSuite Pilot 版本说明"
source: "https://help.aliyun.com/zh/document_detail/3047147.html?spm=a2c4g.11186623.help-menu-3033820.d_2_1_0.27242056JDv7GG"
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
"word-count": "1000"
更新时间: "2026-07-22 17:10:05"
---
本文记录 LoongSuite Pilot 各版本的功能更新和问题修复，包括新增的 Agent 支持和采集能力等内容，可作为版本升级的评估依据。如尚未接入 LoongSuite Pilot，可参阅AI 应用接入：AI Coding Agent完成接入配置。

## v1.1.16

发布时间：2026-07-22

### 新功能

-   支持将 Trace 同时发送到多个后端，便于同时接入平台托管观测和用户自有观测系统。
    
-   支持上游 Trace 关联和调用级 Span 属性透传，外部编排系统可以更完整地追踪一次 Agent 调用链路。
    

### 问题修复

-   修复 root 环境下服务安装仍依赖 `sudo` 的问题，容器和 root 用户场景下安装/卸载更稳定。
    
-   修复 QoderWork 系列应用可能加载错误 worker runtime 的问题，避免跨应用 runtime 混用导致采集异常。
    
-   修复 Codex、QoderWork CN 和 hook log 的若干采集稳定性问题，减少 turn 恢复、trace-quality 和日期切换场景下的数据遗漏。
    

## v1.1.15

发布时间：2026-07-20

### 新功能

-   新增 Trace Span 的 `git.*` 和自定义属性注入能力，并提供 `span-attr` 命令，便于按项目、环境补充观测维度。
    
-   新增本地 output log 清理能力，降低本地日志长期累积带来的磁盘压力。
    

### 改进

-   优化 OpenCode 会话的工作区归因，Trace 和事件记录能更准确关联仓库、分支与当前工作区。
    
-   调整部署诊断能力结构和文档索引，补齐 Qoder JetBrains、依赖注入等运维排查材料。
    

### 问题修复

-   修复 Wukong 活动快照中工具参数、结果和错误状态映射不一致的问题，结构化工具数据会更完整。
    
-   修复 updater 自愈路径过早标记重启成功的问题，注册失败或进程未启动时会继续走备用恢复逻辑。
    
-   移除安装器中已废弃的 `--system-service` 路径，并与新的启动系统检测逻辑对齐，降低安装和重启失败概率。
    
-   调整 Linux 启动系统检测为自动级联，并移除 `nohup` 兜底启动逻辑，避免服务注册失败后运行态判断不一致。
    

### 构建/打包改进

-   修复开源版发布流程的打包脚本调用，避免发布包缺失或脚本路径错误。
    

## v1.1.14

发布时间：2026-07-15

### 新 Agent 支持

-   新增 Kiro CLI 采集支持。LoongSuite Pilot 可从 shell hook、SQLite transcript 与 session JSONL 等来源采集 Kiro CLI 的会话数据，支持交互式会话的延迟采集、去重与时序恢复。启用后，AgentLoop 可更完整地观测 Kiro CLI 的模型调用和工具调用链路。
    

### 新功能

-   新增通用 pipeline 文件采集子系统和 Qoder API 采集通道，支持多 pipeline 生命周期管理、滑动窗口采集、失败日志持久化，且兼容旧版本配置。
    
-   新增 alarm-triage 告警分诊能力。LoongSuite Pilot 可基于日志服务 SLS 中的异常快照并行分析根因，生成结构化问题记录，帮助将告警处理从人工排查收敛到可复现的修复建议。
    

### 改进

-   优化 LoongSuite 相关仓库链接和 Java 项目说明，方便准确跳转到目标项目。
    
-   刷新 AgentTeams 本地运行时资源包，使本地运行时与最新 AgentTeams 能力保持一致。
    

### 问题修复

-   修复 Codex 分叉 transcript 中历史 turn 被重复采集的问题，减少 fork 场景下的重复 span 和重复会话数据。
    
-   修复 alarm-triage 调用阿里云 CLI 时未显式指定 cn-shanghai 地域的问题，避免默认 profile 地域不一致导致告警快照查询失败。
    
-   修复 AgentTeams worker runtime bundles 相关问题，确保纳管 worker 使用更新后的运行时资源。