---
title: "Skills 管理"
source: "https://help.aliyun.com/zh/document_detail/3041731.html?spm=a2c4g.11186623.help-menu-3033820.d_3_6_2.60e323d1qoJMKN"
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
"word-count": "656"
更新时间: "2026-06-17 17:45:15"
---
AgentLoop 通过 Agent 资产中的 Skills 模块，提供 Skill 的集中管理、版本控制与协同迭代能力。可以手动新建或导入 Skill，并通过版本对比和 Labels 标签管理 Skill 的迭代过程。

## 新建 Skill

支持手动新增和导入两种方式创建 Skill。

### 手动新增

1.  在 **Agent 资产** 页面，选择 **Skills** 标签页。
    
2.  单击 **添加 Skill**。
    
3.  在 `SKILL.md` 编辑区编写 Skill 定义。编辑区支持 Markdown 格式，提供以下三种视图：
    
    -   **编辑模式**：仅显示编辑器。
        
    -   **编辑 + 预览模式**：左右分栏同时显示编辑器和渲染预览。
        
    -   **预览模式**：仅显示渲染后的预览效果。
        
4.  单击 **创建**。
    

### 导入 Skill

1.  在 **Agent 资产** 页面，选择 **Skills** 标签页。
    
2.  单击 **导入 Skill**。
    
3.  在弹出的对话框中选择导入方式：
    
    -   **本地上传**：上传本地的 Skill 目录。
        
    -   **Git 仓库导入**：输入 Git 仓库地址，导入 Skill 定义文件。
        
4.  确认导入，自动解析 `SKILL.md` 文件内容并创建版本。
    
    **说明**
    
    -   导入后的 Skill，Name 字段不可修改。
        
    -   若 Git 仓库导入失败，请检查：仓库地址是否正确且可公开访问（或已配置访问凭证）；当前账号是否具备仓库读取权限；仓库根目录是否包含合规的 `SKILL.md` 文件。
        
    

## 版本管理

在 Skill 列表中，单击目标 Skill 名称进入 Skill 详情页。

### 版本对比

在详情页中选择**版本对比**标签页，选择任意两个版本进行 Diff 对比，查看版本之间的内容差异。

### 版本标签（Labels）

Labels 用于标记特定版本的用途或环境。

-   **添加或移除标签**：在版本列表中，单击编辑按钮为版本添加或移除标签。
    
-   **发布时指定标签**：在发布或创建草稿版本时指定标签。
    
-   **新建标签**：输入标签名后按回车创建。
    

**说明**

每个 Label 仅可标记一个版本。若所选 Label 已被其他版本使用，系统自动将该 Label 转移至当前版本。

## 下载与使用Skill

通过手动下载 ZIP 文件或 NPX 命令行工具（支持 QwenPaw、Qoder、Claude、Cursor 等多种 CLI）将 Skill 下载到本地使用。

#### **手动下载**

在 Skill 详情页右侧**使用指南**区域，点击**下载 .zip 文件**，下载当前版本的完整 Skill 包。

适用于本地查看、备份或迁移到其他环境。

#### **通过 CLI 下载**

在详情页右侧**NPX 下载**区域，选择对应的 CLI 工具后按步骤操作：

**支持的 CLI 工具：** QwenPaw、OpenClaw、Qoder、QoderWork、Claude、Codex、Cursor、Kiro、Lingma

**步骤：**

1.  首次使用，配置登录凭证，可参考[Nacos CLI 接入 AI 治理中心](https://help.aliyun.com/zh/mse/user-guide/nacos-cli-access-ai-registry-login-credential-configuration-guide)。
    
    ```
    npx @nacos-group/cli profile edit
    ```
    
2.  下载 Skill 到本地：
    
    ```
    npx @nacos-group/cli skill-get <skill-name> --version <version> -o <output-path>
    ```
    
    不同 CLI 工具有各自的默认 Skill 存储路径，页面会根据选择自动生成对应命令。