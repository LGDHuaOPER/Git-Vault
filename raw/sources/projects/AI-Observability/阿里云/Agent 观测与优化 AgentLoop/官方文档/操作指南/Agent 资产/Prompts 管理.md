---
title: "Prompts 管理"
source: "https://help.aliyun.com/zh/document_detail/3041730.html?spm=a2c4g.11186623.help-menu-3033820.d_3_6_1.35395819QGll5f"
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
"word-count": "1309"
更新时间: "2026-06-17 17:45:13"
---
在多人协作的 Agent 开发场景中，提示词（Prompt）的管理和迭代往往缺乏版本控制和统一入口。AgentLoop 的 Agent 资产功能提供 Prompt 的集中管理、版本控制与标签化发布能力，支持通过 SDK 在应用运行时动态加载 Prompt，无需重新部署。

## 新建 Prompt

1.  登录[AgentLoop 控制台](https://agentloop.console.aliyun.com/)，进入目标智能体空间。
    
2.  在左侧导航栏中，单击**Agent 资产**，选择**Prompts**标签页。
    
3.  单击**新建 Prompt**。
    
4.  填写基本信息。
    
    | **参数** | **是否必填** | **说明** |
    | --- | --- | --- |
    | **Name** | 是   | Prompt 资源的唯一标识。限 64 字符，支持字母、数字、下划线（`_`）和短横线（`-`），需在当前空间内唯一。 |
    | **描述** | 是   | Prompt 的用途说明。建议用一句话描述该 Prompt 的适用场景与关键输入输出。 |
    
5.  在 Prompt 编辑区编写内容。编辑器支持以下功能：
    
    -   **变量插入**：使用 `{{variableName}}` 语法定义模板变量。单击**添加变量**可快速插入变量。
        
    -   **分栏编辑**：通过编辑区右上角的图标切换三种视图模式——纯编辑、编辑 + 预览、纯预览。
        
    -   **变量高亮**：编辑区中的变量以蓝色高亮显示，右侧预览区域实时渲染效果。
        
6.  在右侧**版本信息**面板中填写版本号和变更说明。
    
7.  完成编辑后，选择以下任一操作：
    
    -   单击**保存草稿**：将当前内容保存为草稿状态，后续可继续编辑。
        
    -   单击**发布版本**：在弹窗中确认版本号和变更说明后，单击**确认发布**。发布后该版本为已发布状态，不可修改。
        

## 版本管理

Prompt 发布后，可创建新草稿版本来迭代内容。在 Prompt 详情页的**版本信息**侧边栏中，单击**创建草稿**，填写版本号和变更说明，即可基于当前已发布版本创建新草稿。

### 版本对比

在 Prompt 详情页中，选择**版本对比**标签页，选择任意两个版本进行 Diff 对比，查看内容差异。

### 标签（Labels）

标签（Labels）用于标记版本的用途或环境（例如 Latest、Production），便于通过 SDK 按标签加载指定版本的 Prompt。

支持以下操作：

-   在版本列表中为版本添加或移除标签。
    
-   在发布版本或创建草稿版本时指定标签。
    
-   输入标签名称后按回车创建新标签。
    

**说明**

每个标签仅可标记一个版本。若所选标签已被其他版本使用，该标签将自动转移至当前版本。

## 通过 SDK 加载 Prompt

发布后的 Prompt 支持通过 SDK 在应用代码中动态加载，按 Name 或标签（Labels）获取指定版本，无需重新部署应用即可更新提示词内容。

### Java SDK

#### 前提条件

-   `nacos-client` 版本 ≥ 3.2.1
    
-   `nacos-client-mse-extension` 版本 ≥ 1.0.6
    

#### **操作步骤**

1.  在项目的 `pom.xml` 中添加以下依赖：
    
    ```
    <dependency>
        <groupId>com.alibaba.nacos</groupId>
        <artifactId>nacos-client</artifactId>
        <version>${nacos-client-version}</version>
    </dependency>
    <!-- 鉴权插件 -->
    <dependency>
        <groupId>com.alibaba.nacos</groupId>
        <artifactId>nacos-client-mse-extension</artifactId>
        <version>${nacos-client-mse-extension-version}</version>
    </dependency>
    ```
    
2.  鉴权配置，按需选择一种方式即可：
    
    ## **AccessKey / SecretKey 方式**（适用于服务端长期运行的应用）
    
    ```
    Properties properties = new Properties();
    properties.put(PropertyKeyConst.SERVER_ADDR, "airegistry.cn-hangzhou.mse.aliyuncs.com:80");
    properties.put(PropertyKeyConst.NAMESPACE, "95408e87-...");
    properties.put(PropertyKeyConst.ACCESS_KEY, "${access-key}");
    properties.put(PropertyKeyConst.SECRET_KEY, "${secret-key}");
    properties.put(AiConstants.AI_TRANSPORT_MODE, AiConstants.AI_TRANSPORT_MODE_HTTP);
    
    AiService aiService = AiFactory.createAiService(properties);
    ```
    
    ## **STS Token 方式**（适用于需要临时授权的场景）
    
    ```
    Properties properties = new Properties();
    properties.put(PropertyKeyConst.SERVER_ADDR, "airegistry.cn-hangzhou.mse.aliyuncs.com:80");
    properties.put(PropertyKeyConst.NAMESPACE, "95408e87-...");
    properties.put(ExtensionAuthConstants.ACCESS_KEY_ID_KEY, "${sts-access-key-id}");
    properties.put(ExtensionAuthConstants.ACCESS_KEY_SECRET_KEY, "${sts-access-key-secret}");
    properties.put(ExtensionAuthConstants.SECURITY_TOKEN_KEY, "${sts-security-token}");
    properties.put(AiConstants.AI_TRANSPORT_MODE, AiConstants.AI_TRANSPORT_MODE_HTTP);
    
    AiService aiService = AiFactory.createAiService(properties);
    ```
    
3.  获取 Prompt，支持三种获取方式：
    
    ## **默认获取 Latest 版本**
    
    ```
    Prompt prompt = aiService.getPrompt("document-to-ppt");
    System.out.println(prompt.getTemplate());
    ```
    
    ## **按版本号获取（锁定版本）**
    
    ```
    Prompt prompt = aiService.getPrompt("document-to-ppt", "0.0.1", null);
    ```
    
    ## **按 Label 获取（环境隔离/灰度发布）**
    
    ```
    Prompt prompt = aiService.getPrompt("document-to-ppt", null, "prod");
    ```
    
    **说明**
    
    version 和 label 互斥。都不指定时默认获取 Latest 标签对应的版本。
    
4.  灰度发布实践。
    
    1.  将 `staging` 标签绑定到新版本 1.1.0。
        
    2.  部分实例配置 `label=staging` 进行验证。
        
    3.  验证通过后，将 `prod` 标签切换到 1.1.0。
        
    4.  所有配置 `label=prod` 的实例自动获取新版本。
        
5.  模板变量渲染，Prompt 模板支持 `{{ variableName }}` 占位符语法，通过 `render()` 方法传入变量值进行渲染：
    
    ```
    Map<String, String> variables = Map.of(
        "role", "技术顾问",
        "department", "研发部"
    );
    String rendered = prompt.render(variables);
    // 模板: "你是 {{role}}，负责 {{department}} 的工作。"
    // 结果: "你是 技术顾问，负责 研发部 的工作。"
    ```
    
6.  订阅变更（动态更新），订阅后，当 Prompt 内容或标签绑定发生变更时自动收到通知（默认轮询间隔 10 秒）：
    
    ```
    Prompt prompt = aiService.subscribePrompt("document-to-ppt", null, "prod",
        new AbstractNacosPromptListener() {
            @Override
            public void onEvent(NacosPromptEvent event) {
                Prompt updated = event.getPrompt();
                System.out.println("Prompt 已更新: version=" + updated.getVersion());
            }
        });
    ```
    

### AgentScope Java 接入

AgentScope 提供 Spring Boot Starter，可自动从远程加载 Prompt 作为 Agent 系统提示词，支持动态更新。

#### 前提条件

-   `agentscope-*` 版本 ≥ 1.0.11
    
-   `nacos-client-mse-extension` 版本 ≥ 1.0.6
    

#### 操作步骤

1.  添加依赖。
    
    ```
    <!-- AgentScope Spring Boot Starter -->
    <dependency>
        <groupId>io.agentscope</groupId>
        <artifactId>agentscope-spring-boot-starter</artifactId>
        <version>${agentscope-version}</version>
    </dependency>
    <!-- Prompt 管理集成 Starter -->
    <dependency>
        <groupId>io.agentscope</groupId>
        <artifactId>agentscope-nacos-spring-boot-starter</artifactId>
        <version>${agentscope-version}</version>
    </dependency>
    <!-- 鉴权插件 -->
    <dependency>
        <groupId>com.alibaba.nacos</groupId>
        <artifactId>nacos-client-mse-extension</artifactId>
        <version>${nacos-client-mse-extension-version}</version>
    </dependency>
    ```
    
2.  Spring Boot 配置，按需选择一种方式即可：
    
    -   **AccessKey / SecretKey 方式（推荐通过环境变量注入凭证）：**
        
        ## **AccessKey / SecretKey 方式（推荐通过环境变量注入凭证）**
        
        ```
        agentscope:
          nacos:
            server-addr: airegistry.cn-hangzhou.mse.aliyuncs.com:80
            namespace: 95408e87-...
            access-key: ${NACOS_ACCESS_KEY}
            secret-key: ${NACOS_SECRET_KEY}
            properties:
              nacosAiTransportMode: "http"
            prompt:
              enabled: true
              sys-prompt-key: document-to-ppt
              label: "prod"
              variables:
                role: "AI 助手"
                department: "技术支持"
        ```
        
        ## **STS Token 方式**
        
        ```
        agentscope:
          nacos:
            server-addr: airegistry.cn-hangzhou.mse.aliyuncs.com:80
            namespace: 95408e87-...
            properties:
              nacosAiTransportMode: "http"
              alibabaCloudAccessKeyId: ${sts-access-key-id}
              alibabaCloudAccessKeySecret: ${sts-access-key-secret}
              alibabaCloudSecurityToken: ${sts-security-token}
            prompt:
              enabled: true
              sys-prompt-key: document-to-ppt
        ```