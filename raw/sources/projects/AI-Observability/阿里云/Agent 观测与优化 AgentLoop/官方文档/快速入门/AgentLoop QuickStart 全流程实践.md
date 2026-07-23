---
title: "AgentLoop QuickStart 全流程实践"
source: "https://help.aliyun.com/zh/document_detail/3033823.html?spm=a2c4g.11186623.help-menu-3033820.d_1_0.69a82661d85lg3"
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
"word-count": "3366"
更新时间: "2026-07-10 10:35:08"
---
本文面向首次使用 AgentLoop 的 Agent 开发者与 AI 平台团队，按**创建智能体空间 → 接入观测数据 → 构建评估器 → 创建评估任务 → 导入与标注数据集 → 管理 Agent 资产 → 使用记忆库**的顺序，串联 AgentLoop 自进化闭环的完整实操路径。完成全部步骤后可在生产环境中复用。

## 前置条件

请完成以下准备工作后再开始后续操作。

-   已注册并实名认证阿里云账号。
    
-   已开通**云监控 2.0**、**SLS 日志服务**、**MSE 微服务引擎（AI 治理中心）**、**AgentLoop**。
    
-   当前 RAM 用户已被授予 `AliyunAgentLoopFullAccess` 系统策略。
    
-   已为 RAM 用户创建 AccessKey，用于 SDK / OpenAPI 鉴权。
    

## 步骤一：创建智能体空间

智能体空间（AgentSpace）是 AgentLoop 资源管理的基本单元。每个 AgentSpace 与云监控 2.0 工作空间、MSE AI 治理中心命名空间、SLS Project 形成一一绑定关系。

### 创建步骤

1.  登录 [AgentLoop 控制台](https://agentloop.console.aliyun.com/)。
    
2.  在控制台首页**智能体空间**列表区域，单击右上角**新建空间**。
    
3.  在**新建智能体空间**对话框中，配置参数。
    
    | **参数** | **说明** |
    | --- | --- |
    | 所在地域 | 选择 cn-hangzhou、cn-shanghai 或 cn-hongkong。**创建后不可更换**。 |
    | 智能体空间（AgentSpace） | 空间名称。3–63 个字符，支持小写字母、数字、连字符（`-`）和下划线（`_`），所有用户全局唯一。**创建后不可更换**。 |
    | 空间描述 | 空间用途简要说明（可选）。 |
    | 云监控 2.0 工作空间 | **自动创建**：系统创建命名为 `agentloop-<32位编码>` 的新工作空间。 **选择已有**：从下拉列表中选择当前账号下、同地域的 CMS 2.0 工作空间复用，便于与已有应用监控统一视图。 **创建后绑定关系不可更换**。 |
    | MSE 命名空间 | 系统自动创建（命名 `agentloop-<32 位编码>`），承载 Prompts、Skills 等 Agent 资产。 |
    | SLS Project | 系统自动创建（命名 `agentloop-<32 位编码>`），承载审计与评估等日志。 |
    
4.  单击**创建空间**。系统自动执行 AgentLoop 资源及关联云产品资源创建与映射关系绑定。如某一步失败，已创建的资源不会回滚，未创建资源可在空间管理页面进行重建。
    

### 验证

进入**系统管理 > 空间管理**，在**基础信息**与**资源绑定**区块确认 AgentSpace 名称、地域、关联的 CMS 2.0 工作空间、MSE 命名空间、SLS Project 均已就绪。

## 步骤二：接入可观测数据

可观测数据是 AgentLoop 构建进化数据飞轮的重要前提。本节以 ARMS 自动探针接入为例，在控制台查看 Agent Trace 推理轨迹。

### 1\. 选择接入方式

进入**接入中心**，根据 Agent 技术栈选择接入方式。

| **类别** | **适用对象** |
| --- | --- |
| AI 可观测 | Dify、LangChain/LangGraph、AgentScope、DashScope、Coze、OpenAI、OpenClaw、Hermes、Claude Code、Qoder、Qoder Work、Codex、Cursor、QwenPaw等 |
| 应用监控&链路追踪 | Java、Go、Python、Node.js、PHP、.NET、OpenTelemetry、Nginx、Kong、APISIX等 |

### 2\. 完成 SDK 接入

以 LangChain/LangGraph 应用为例：

```
# 安装阿里云探针
pip install aliyun-bootstrap
aliyun-bootstrap -a install

# 配置环境变量
export ARMS_APP_NAME=my-agent-app
export ARMS_REGION_ID=cn-hangzhou
export ARMS_LICENSE_KEY=<从接入中心获取>
export ARMS_WORKSPACE=<AgentSpace 关联的 CMS 2.0 工作空间名称>

# 使用探针启动应用
aliyun-instrument python app.py
```

业务代码无需改造，探针会自动采集 LLM 调用、工具调用、Retriever、LangGraph 节点等链路数据。

### 3\. 验证接入

进入**AI Agent 可观测**，在**链路追踪** 标签页中查看：

-   **Trace 数、平均耗时、Token 数**折线图随接入流量上涨。
    
-   **Trace 列表**列出最新 Trace 记录，单击 Trace ID 进入调用链详情，可逐 Span 查看模型输入输出、工具参数、耗时与 Token 消耗。
    

### 4\. 在 Agent 总览中查看核心指标

进入 **Agent 总览**，可在 Agent 洞察页面查看**会话数、对话数、用户数、Token 用量、平均耗时**等核心指标，并在**趋势图**与 **Agent 列表**中按 Agent 维度查看每个 Agent 的关键指标。

## 步骤三：构建评估器

评估器是 Agent 效果度量的基础。AgentLoop 支持 Agent-as-a-Judge 评估范式，以及**预置评估器**与**自定义评估器**两种类型，可以灵活扩展评估 Prompt 和 Skills。

### 1\. 使用预置评估器

进入**评估 > 评估器**，左侧分组列出 AgentLoop 内置评估器：

| **类别** | **示例评估器** |
| --- | --- |
| Agent 评估 | Agent 正确性、Agent 任务完成度、Agent 执行步骤效率、Agent 工具选择合理性、Agent 幻觉检测等 |

单击评估器名称进入详情页，在 **Prompt & 能力**标签页中查看评估器的 Prompt 和能力挂载（如 Skills、MCP）。预置评估器开箱即用，**无需额外配置**。

### 2\. 创建自定义评估器

业务专属评估场景（如复杂任务规划合理性、多轮对话连贯性）可通过创建自定义评估器进行精准评估。

1.  在评估器列表页右上角，单击**创建评估器**。
    
2.  输入评估器基本信息，如名称、描述、标签等。
    
3.  配置 **Prompt**：编写评估指令，明确评估目标、评估维度、打分尺度。例如 Skill 完整度评估器：
    
    ```
    你是一个严谨、严格的 AI Agent 评测专家，针对待评测的 Agent
    Trace（即 Agent 完整执行轨迹），从以下维度进行打分（0–1）：
    1. 任务理解准确性
    2. 工具调用合理性
    3. 多步推理正确性
    4. 最终输出完整性
    ```
    
4.  查看**已提取变量**：例如 `input`、`output`、`agent_trajectory`、`tool_context`、`rag_context`，由评估任务运行时自动绑定到对应映射字段。
    
5.  配置**能力扩展**（可选）：为评估器 Agent 绑定 Skills 或 MCP，使其在评估过程中可调用外部检索、规则校验、知识库查询等能力，实现 **Agent-as-a-Judge** 评估范式。
    
6.  查看输出定义，确认是否开启**评估过程轨迹**。
    
7.  点击右上角进行**保存**。
    

## 步骤四：创建评估任务并解读结果

评估任务用于将评估器批量应用到目标数据上，输出可分析的质量指标。

### 创建评估任务

1.  进入**评估 > 评估任务**，单击右上角**新建任务**，按**数据配置 → 选择评估器**两步向导配置。
    
2.  参考下表进行数据配置：
    
    | **配置项** | **说明** |
    | --- | --- |
    | 任务名称 | 评估任务的业务标识。 |
    | 任务描述 | 用途简述（可选）。 |
    | 数据来源 | 链路（Trace）、日志、数据集 三选一。 |
    | Agent 智能体 | 选择目标 Agent 应用，例如 `ai-coding-agent-claude-code`。 |
    | 运行策略 | **基于新数据持续评估**：对未来上报的数据实时打分； **基于历史数据评估**：对指定时间窗口内的历史数据进行回测。 |
    | 时间范围 | 历史数据评估的时间范围配置（如最近 24 小时）。 |
    | 采样比例 | 控制评估数据采样率（1%–100%），结合**最大评估条数**控制单次评估任务执行的条数。 |
    
3.  选择评估器：
    
    -   左侧勾选预置或自定义评估器，支持多选并行运行。
        
    -   右侧**配置信息**区按评估器要求绑定变量映射字段：常见映射如 `input ← trace.input`、`output ← trace.output`、`agent_trajectory ← trace.agent_trajectory`。
        
    -   配置完成后单击**更新并运行**立即保存任务并触发执行，或点击**运行测试**进行调试。
        

### 解读评估结果

任务运行后，在**评估任务详情页**查看评估结果明细与分布。

## 步骤五：导入与标注数据集

数据集是评估、实验、调优的基础。AgentLoop 提供**数据中心**模块，支持从 Trace 导入、CSV 上传、手动编辑三种方式构建数据集。

### 1\. 导入 Trace 数据

进入**数据中心 > 数据集**，单击**创建数据集**：

1.  输入数据集名称和描述。
    
2.  数据来源选择**从 Trace 数据处理**。
    
3.  数据筛选中下拉选择 **Agent 应用**。
    
4.  数据处理中选择需要的处理模板，比如 ot\_trace\_qa\_extract（Trace QA 问答对提取）以及时间范围。
    
5.  数据预览点击右侧**生成预览**查看预览数据。
    
6.  确认无误后，点击右下角**创建数据集**，系统将在后台创建数据集及关联的 Pipeline 任务完成数据处理与导入。
    

### 2\. 人工标注

进入数据集详情页，点击**标注**页签**创建标注模板**：

-   在左侧配置**数据标注界面**和**标注控件**。右侧可预览效果。
    
-   配置完成后点击右上角**开始标注**，进行逐项标注，可以选择跳过。
    
-   已标注内容可以在数据集 **agentloop\_annotations** 字段中查看标注结果。
    

### 3\. 沉淀 Golden Set 与 BadCase Set

基于评估结果与人工标注审核，可将数据集拆分为：

| **数据集类型** | **用途** |
| --- | --- |
| Golden Dataset | 经人工审核的高质量样本，作为 Agent 回归测试的黄金基准。 |
| BadCase Dataset | 评估识别的失败样本，用于定向优化与质量门禁。 |
| 人工标注集 | 由领域专家标注的小样本高保真集合。 |

## 步骤六：管理 Agent 资产

Agent 资产指构成 Agent 行为逻辑的 Prompts 与 Skills。AgentLoop 提供集中管理、版本控制与协同迭代能力。

### 1\. 创建 Prompt 资产

进入**Agent 资产 > Prompts**，单击**新建 Prompt**：

1.  填写**基础信息**：名称（如 `my-prompt`）和描述。
    
2.  在 **Prompt** 编辑区编写 Prompt 内容，使用 `{{input}}` 等占位符声明变量。
    
3.  单击**保存草稿**或**发布版本**。每次编辑发布将自动递增版本号（v0.0.1、v0.0.2、v0.0.3 …）。
    

### 2\. 版本管理

资产详情页右侧**版本信息**展示历史版本：

-   每个版本显示版本号、提交人、变更说明与时间戳。
    
-   单击**版本对比**可对比当前版本与目标版本的差异。
    
-   单击**使用说明**可查看 Agent 引用该资产的客户端接入方式。
    

### 3\. 灰度发布与协同

Agent 资产可配合 MSE AI 治理中心进行流量切分；多人编辑时通过版本锁与提交说明避免冲突。Skills 资产管理流程与 Prompts 类似。

## 步骤七：创建并使用记忆库

记忆库为 Agent 提供跨会话的长期记忆能力。

### 1\. 创建记忆库

进入**上下文工程 > 记忆库**，单击**创建记忆库**：

| **参数** | **说明** |
| --- | --- |
| 名称  | 记忆库名称，如 `my_memory`。 |
| 描述信息 | 记忆库描述信息，可选。 |

### 2\. 在 Agent 中集成记忆库

选择记忆库实例，进入**集成方式**标签页获取接入示例，如：

```
# 初始化客户端

from mem0 import MemoryClient

client = MemoryClient(
    api_key="sk-xxxxxxxx",  # 在「API Key」页签创建并复制
    host="https://agentloop.cn-hongkong.aliyuncs.com",
)

# 写入对话（短期记忆）
client.add(
    messages=[
        {"role": "user", "content": "我住在杭州，喜欢喝无糖美式咖啡"},
        {"role": "assistant", "content": "好的，已记住你住在杭州、喜欢无糖美式。"},
    ],
    user_id="user-001",
    infer=True,
)

# 在 Agent 推理前检索相关记忆
res = client.search(
    query="我住在哪里？喜欢喝什么？",
    user_id="user-001",
    limit=5,
)
print(res)
```

API Key 在 **API Key** 标签页创建，建议按环境（dev / prod）分别签发，避免越权访问。

### 3\. 通过控制台检索记忆

进入记忆库详情页**长期记忆检索**标签页：

-   在搜索框输入查询语句（例如"用户偏好查看哪些告警？"），配置 `topK` 返回数量。
    
-   单击**开始检索**，结果区按相关性展示长期记忆条目，可在**分页**与**检索召回配置信息**区块查看召回链路。
    
-   切换到**短期记忆检索**标签页可按会话维度查询当前活跃上下文。
    

## 步骤八：闭环验证

完成上述步骤后，建议跑通一次端到端闭环以验证整体可用性：

1.  触发线上 Agent 流量，确认 **AI Agent 可观测**中 Trace 持续上报。
    
2.  评估任务输出当日质量分数，定位 1–2 个低分 Bad Case。
    
3.  将 Bad Case 加入数据集并人工标注 Expected Output。
    
4.  在 **Agent 资产**中迭代 Prompt 版本，针对 Bad Case 优化指令。
    
5.  重新运行评估任务，对比新旧版本得分变化。
    
6.  将稳定的人物画像与偏好沉淀到记忆库，作为下一轮交互的上下文。
    

整个闭环跑通即建立了**观测 → 评估 → 数据资产化 → 资产优化 → 上下文增强**的 Agent 自进化飞轮。