# Agent 总览

![[IMG-20260728194230064.png]]

# 快速启动

## Agent 全栈观测

> 完成观测数据接入，验证 Agent 上下文数据完整性

![[IMG-20260728195600860.png]]

### 控制台

![[IMG-20260728195849485.png]]

#### 步骤 1：接入 LLM Trace 数据【必选】

#Prompt #Skill #Token #TTFT 

在控制台「接入中心」选择对应智能体类型，通过自研探针或云产品一键接入，无侵入式采集全链路数据。

- 自研探针：仅需配置应用名称、LicenseKey 等基础信息，无需接入 SDK 手动修改代码，即可自动采集 LLM 调用链
- 云产品一键接入：AI 网关、百炼等云产品可在控制台一键启动链路追踪，零代码改造
- 确认 Trace 上报后，验证对话轨迹完整性 — LLM、Tool、RAG 等完整调用轨迹，以及 Input、Output、Prompt、Skill 等关键信息

点击”前往接入中心“后，跳转至[[#接入中心]]

#### 步骤 2：配置关键指标告警【可选】

#Token成本异动 #TTFT性能退化 #模型调用错误

在告警配置页面根据以下三大类关键指标创建告警规则：

- Token 成本异动 — 当日 Token 消耗超过前 7 日均值的 ±30%，触发 P2 告警
- TTFT 性能退化 — 首 Token 耗时超过设定阈值（默认 3s），触发 P1 告警
- 模型调用错误 — 模型调用错误率超过 5%（30 分钟窗口），触发 P1 告警

#### 步骤 3：配置业务自定义大盘【可选】

#场景化分析 #自定义业务视图

前往云监控2.0仪表盘创建自定义面板，组合关键业务指标形成场景化视图。

- 在云监控2.0 仪表盘 → 新建面板 → 选择数据源与指标维度
- 推荐组合：调用量趋势 + Token 成本分布 + 延时 P95 + Agent 成功率
- 可按 Agent 实例 / 场景 / 用户分群等维度创建多个业务面板

### Skill

![[IMG-20260728210732500.png]]

#### 步骤 1：接入 LLM Trace 数据【必选】

#Prompt #Skill #Token #TTFT 

#### 步骤 2：配置关键指标告警【可选】

#Token成本异动 #TTFT性能退化 #模型调用错误

#### 步骤 3：配置业务自定义大盘【可选】

#场景化分析 #自定义业务视图

### CLI

![[IMG-20260728210942699.png]]

#### 步骤 1：接入 LLM Trace 数据【必选】

#Prompt #Skill #Token #TTFT 

#### 步骤 2：配置关键指标告警【可选】

#Token成本异动 #TTFT性能退化 #模型调用错误

#### 步骤 3：配置业务自定义大盘【可选】

#场景化分析 #自定义业务视图

## Agent 效果评估

> 创建评估器与评估任务，持续度量 Agent 效果

![[IMG-20260728212245161.png]]

### 控制台

![[IMG-20260728212310952.png]]

#### 步骤 1：创建 / 浏览评估器【必选】

#系统内置评估器 #自定义

在评估器页面浏览系统内置评估器或创建自定义评估器。

- 系统内置评估器：提供幻觉、正确性、任务完成度等多维度评估器，开箱即用
- 自定义评估器：灵活配置评估器 Agent 的 Prompt、Skills 等关键配置
- 支持 Agent-as-a-Judge 评估模式：评估 Agent 具备多步推理、工具 / Skill 加载能力，深度理解被评估 Agent 的决策链路

#### 步骤 2：创建评估任务【必选】

#链路 #日志 #数据集 #在线持续评估 #历史数据评估

在评估任务页面创建评估任务，支持三种数据源与两种评估模式：

- 数据源 — 支持链路（Trace）、日志（Log）、数据集（Dataset）三种不同类型的数据源
- 在线持续评估 — 从线上链路或日志中实时采样，按评估器维度持续打分，适合实时监控告警，第一时间发现质量退化风险
- 历史数据评估 — 选择已有数据集（Golden Set / BadCase），批量运行评估，适合版本对比
- 每个评估任务支持配置多个评估器，从不同维度综合评估 Agent 效果

#### 步骤 3：查看评估结果【必选】

#得分趋势 #智能分析报告 #改进建议

在评估任务详情中查看每条评估记录的得分与评估原因，快速定位失败模式。

- 得分明细 — 按评估器维度展示每条 Case 的具体得分，支持按时间 / 维度 / 区间筛选
- 评估原因 — 评估器 Agent 给出的判分依据与上下文引用，理解评分逻辑
- 智能分析报告 — 选取一组评估结果，AI 分析评估失分原因与优化建议，快速识别需要改进的 Prompt / Skill / Tool 链路

### Skill

![[IMG-20260728212440312.png]]

#### 步骤 1：创建 / 浏览评估器【必选】

#系统内置评估器 #自定义

#### 步骤 2：创建评估任务【必选】

#链路 #日志 #数据集 #在线持续评估 #历史数据评估

#### 步骤 3：查看评估结果【必选】

#得分趋势 #智能分析报告 #改进建议


### CLI

![[IMG-20260728212458887.png]]

#### 步骤 1：创建 / 浏览评估器【必选】

#系统内置评估器 #自定义

#### 步骤 2：创建评估任务【必选】

#链路 #日志 #数据集 #在线持续评估 #历史数据评估

#### 步骤 3：查看评估结果【必选】

#得分趋势 #智能分析报告 #改进建议

## 数据集构建

> 基于线上 Trace/Log 或 CSV 文件持续构建高质量数据集，沉淀企业数据资产

![[IMG-20260728212929672.png]]

### 控制台

![[IMG-20260728213036456.png]]

#### 步骤 1：导入数据【必选】

#Trace自动导入 #CSV上传

在数据集页面创建数据集，选择数据来源方式。

- 线上 Trace 自动导入 — 选择已接入的 Agent 应用，系统自动从 Trace 中提取 Input / Output / Trajectory 字段组装数据条目
- CSV 文件上传 — 按模板准备 CSV 文件（Input, Output, Expected Output 列），批量上传
- 导入完成后可在数据集详情中预览条目，进入下一步标注或直接发起评估

#### 步骤 2：标注 Expected Output【可选】

#人工标注 #企业知识库 #人工审核

为数据集条目标注期望输出（Expected Output），建立评估基准。

- 进入数据集标注工作台，按条目逐一录入或修正 Expected Output
- 可关联企业知识库辅助理解上下文，确保标注与业务语境一致
- 标注完成后数据集可直接用于评估任务与实验对比

#### 步骤 3：基于数据集发起实验或评估【可选】

#评估任务 #实验对比 #数据闭环

已标注完成的数据集可作为基线（Golden Set / BadCase Set），直接发起评估任务或实验对比，形成数据资产闭环。

- 发起评估任务 — 选择数据集 + 评估器，批量打分并生成报告
- 发起实验对比 — 同一数据集上对比 Baseline 与 Candidate Agent 配置差异
- 随线上反馈持续扩充数据集，形成「采集 → 标注 → 评估 / 实验 → 优化」的闭环

### Skill

![[IMG-20260728213322038.png]]

#### 步骤 1：导入数据【必选】

#Trace自动导入 #CSV上传

#### 步骤 2：标注 Expected Output【可选】

#人工标注 #企业知识库 #人工审核

#### 步骤 3：基于数据集发起实验或评估【可选】

#评估任务 #实验对比 #数据闭环


### CLI

![[IMG-20260728213337222.png]]

#### 步骤 1：导入数据【必选】

#Trace自动导入 #CSV上传

#### 步骤 2：标注 Expected Output【可选】

#人工标注 #企业知识库 #人工审核

#### 步骤 3：基于数据集发起实验或评估【可选】

#评估任务 #实验对比 #数据闭环

## Agent 资产管理

> 集中管理 Prompts 和 Skills，多版本路由，运行时动态加载

### Prompts 管理

![[IMG-20260728214400378.png]]

![[IMG-20260728214414547.png]]

#### 步骤 1：创建资产【必选】

#资源元信息

在 Agent 资产页面 Prompts Tab 创建 Prompt 模板，沉淀为可复用、可版本化的企业资产。

- 填写 Prompt 名称、描述等元信息
- 编辑 Prompt 内容，支持 markdown 格式编辑预览

#### 步骤 2：编辑草稿并发布版本【必选】

#Draft #版本发布

在 Prompt 详情页编辑草稿版本，调试通过后，填写 changelog 发布为正式版本。

- 在 Prompt 编辑区调整模板内容，可在右侧 Playground 切换变量与模型组合实时调试。
- 通过「发布版本」按钮二次确认变更说明后发布为正式版本。

#### 步骤 3：配置版本 Labels【可选】

#Latest #Labels #灰度

为 Prompt 版本配置自定义 Labels，实现版本路由与多环境灰度发布。

- Latest 指针 — 自动指向最新的已发布版本。
- 自定义 Labels — 自定义标签（如 beta / stable / production），SDK 按 Label 拉取指定版本
- 在 Prompt 详情页右侧版本面板直接编辑 Labels，无需重启应用即时生效

#### 步骤 4：SDK 接入与运行时调用【可选】

#JavaSDK #AgentScope

在 Prompt 详情页「使用说明」复制 SDK 集成代码，应用运行时获取 Prompt 并订阅变更，实现配置即代码。

- Java SDK — 基于 nacos-client 在运行时拉取 Prompt，支持订阅变更回调实现热更新
- AgentScope — 通过 Spring Boot Starter 注入 PromptService，自动管理生命周期
- 应用按 Production 自定义 Label 拉取，支持灰度切流不重启

### Skills 管理

![[IMG-20260728214429109.png]]

![[IMG-20260728214439651.png]]

#### 步骤 1：创建资产【必选】

#导入创建 #手工输入

在 Agent 资产页面 Skills Tab 创建 Skill，版本化管理 SKILL.md 与关联文件。

- 导入创建：点击"导入 Skill"按钮，支持上传 .zip 文件、Nacos CLI 导入和从 Skill 市场导入。
- 手工输入：填写名称、描述信息，编辑 SKILL.md 文件，点击"创建"保存。创建后可在 Files Tab 继续添加修改文件或文件夹。

#### 步骤 2：编辑草稿并发布版本【必选】

#Draft #版本发布

在 Skill 详情页编辑草稿版本，调试通过后，填写 changelog 发布为正式版本。

- 在 Skill 编辑区调整文件内容，可在右侧 Playground 切换变量与模型组合实时调试。
- 通过「发布版本」按钮二次确认变更说明后发布为正式版本。

#### 步骤 3：配置版本 Labels【可选】

#Latest #Labels #灰度

为 Skill 版本配置自定义 Labels，实现版本路由与多环境灰度发布。

- Latest 指针 — 自动指向最新的已发布版本。
- 自定义 Labels — 自定义标签（如 beta / stable / production），SDK 按 Label 拉取指定版本
- 在 Skill 详情页右侧版本面板直接编辑 Labels，无需重启应用即时生效

#### 步骤 4：SDK 接入与运行时调用【可选】

#NPS安装 #zip下载使用

在 Skill 详情页「使用说明」复制 NPX 命令，将 Skill 下载到本地 AI 客户端目录。

- 支持 OpenClaw、Qoder、QoderWork、Claude、Codex、Cursor、Kiro、Lingma 等多种主流 AI 客户端
- 支持 NPS 命令安装和直接下载 .zip 文件两种使用方式。

# 接入中心

![[IMG-20260728200027209.png]]

![[IMG-20260728200043835.png]]

## Agent 框架

### LangChain / LangGraph

#### 容器手动接入

[[Agent 框架__LangChain_LangGraph__容器手动接入]]

#### Agent 通用接入

![[IMG-20260730100118218.png]]

##### Python

[[Agent 框架__LangChain_LangGraph__Agent 通用接入__Python]]

##### Node.js

###### 自动埋点（推荐）

####### CommonJS

[[Agent 框架__LangChain_LangGraph__Agent 通用接入__Node.js__自动埋点（推荐）__CommonJS]]

####### ECMAScript Modules

[[Agent 框架__LangChain_LangGraph__Agent 通用接入__Node.js__自动埋点（推荐）__ECMAScript Modules]]

###### 手动埋点

####### CommonJS

[[Agent 框架__LangChain_LangGraph__Agent 通用接入__Node.js__手动埋点__CommonJS]]

####### ECMAScript Modules

[[Agent 框架__LangChain_LangGraph__Agent 通用接入__Node.js__手动埋点__ECMAScript Modules]]

#### OpenTelemetry

![[IMG-20260730142756403.png]]

##### 自动埋点（推荐）

[[Agent 框架__LangChain_LangGraph__OpenTelemetry__自动埋点（推荐）]]

##### 手动埋点

[[Agent 框架__LangChain_LangGraph__OpenTelemetry__手动埋点]]

## Coding Agent

### OpenCode

![[IMG-20260728200228185.png]]

![[IMG-20260728200400030.png]]

![[IMG-20260728200428187.png]]

![[IMG-20260728200439913.png]]

[[Coding Agent__OpenCode]]

## 通用 Agent

### OpenClaw

![[IMG-20260730143704752.png]]

#### OpenTelemetry

[[通用 Agent__OpenClaw__OpenTelemetry]]

## 模型提供商

### Anthropic

![[IMG-20260730143944805.png]]

#### 容器手动接入

##### Python

![[IMG-20260730145217174.png]]

[[模型提供商__Anthropic__容器手动接入__Python]]

#### Agent 通用接入

![[IMG-20260730144957430.png]]

[[模型提供商__Anthropic__Agent 通用接入]]

#### OpenTelemetry

![[IMG-20260730145300390.png]]

##### 自动埋点（推荐）

[[模型提供商__Anthropic__OpenTelemetry__自动埋点（推荐）]]

##### 手动埋点

[[模型提供商__Anthropic__OpenTelemetry__手动埋点]]

### OpenAI

#### 容器手动接入

![[IMG-20260730150605900.png]]

##### Python

[[模型提供商__OpenAI__容器手动接入__Python]]

##### Java

[[模型提供商__OpenAI__容器手动接入__Java]]

##### Go

[[模型提供商__OpenAI__容器手动接入__Go]]

##### Node.js

[[模型提供商__OpenAI__容器手动接入__Node.js]]

#### Agent 通用接入

![[IMG-20260730150757414.png]]

##### Python

[[模型提供商__OpenAI__Agent 通用接入__Python]]

##### Java

[[模型提供商__OpenAI__Agent 通用接入__Java]]

##### Go

[[模型提供商__OpenAI__Agent 通用接入__Go]]

##### Node.js

[[模型提供商__OpenAI__Agent 通用接入__Node.js]]

#### OpenTelemetry

![[IMG-20260730152227633.png]]

##### Python

![[IMG-20260730152247283.png]]

###### 自动埋点（推荐）

[[模型提供商__OpenAI__OpenTelemetry__Python__自动埋点（推荐）]]

###### 手动埋点

[[模型提供商__OpenAI__OpenTelemetry__Python__手动埋点]]

##### Java

###### 自动埋点（推荐）

[[模型提供商__OpenAI__OpenTelemetry__Java__自动埋点（推荐）]]

###### 手动埋点

[[模型提供商__OpenAI__OpenTelemetry__Java__手动埋点]]

##### Go

###### 自动埋点（推荐）

[[模型提供商__OpenAI__OpenTelemetry__Go__自动埋点（推荐）]]

###### 手动埋点

[[模型提供商__OpenAI__OpenTelemetry__Go__手动埋点]]

##### Node.js

###### 自动埋点（推荐）

[[模型提供商__OpenAI__OpenTelemetry__Node.js__自动埋点（推荐）]]

###### 手动埋点

[[模型提供商__OpenAI__OpenTelemetry__Node.js__手动埋点]]

## 低代码平台

### Dify

#### OpenTelemetry

![[IMG-20260730153914274.png]]

[[低代码平台__Dify__OpenTelemetry]]

## 自定义接入

### AI Native 接入

![[IMG-20260728203321459.png]]

```markdown
### 安装 Skill

1. 打开 [AgentLoop 全生命周期管理 Skill](https://skills.aliyun.com/skills/alibabacloud-agentloop-management)。
2. 选择安装工具、Agent 客户端和安装范围，复制并执行页面生成的安装命令。
3. 安装完成后重启 Agent 客户端。

### 开始使用

在 Agent 对话中直接描述要完成的 AgentLoop 接入操作，Agent 会加载 alibabacloud-agentloop-management Skill 并按步骤执行。

例如：帮我把这个 Python AI 应用接入 AgentLoop 的 AI 可观测。
```

+ `alibabacloud-agentloop-management` Skill
````markdown
 ---
name: alibabacloud-agentloop-management
description: "AgentLoop APM接入 / AI可观测接入 / 应用监控接入 / 自研探针 / 探针安装. Use for Python aliyun-bootstrap (aliyun-instrument), Java AliyunJavaAgent, Golang instgo, Node.js cms_node_sdk, PHP/.NET OpenTelemetry, ack-onepilot, LicenseKey, AgentLoop workspace agentloop-*. Also for LangChain, Dify, DashScope, LLM monitoring, AI tracing. Synonyms: onboard APM, install agent, probe setup, OpenTelemetry onboarding, application monitoring onboarding. Trigger even if the prompt starts with aliyun cms2 --update-beta when the goal is AgentLoop APM/AI onboarding. Do NOT use for CMS alerts, RUM, Prometheus rules, billing, or default-cms-* workspaces."
license: Apache-2.0
compatibility: "aliyun-cli>=3.3.15"
metadata:
  domain: aiops
  owner: agentloop
  contact: agentloop@alibaba-inc.com
---

# AgentLoop Application Onboarding

> **Product scope**: This skill onboards applications into **AgentLoop** only. It is **not** a general CloudMonitor (CMS) management skill. Use workspace names matching `agentloop-{32-char-code}`; never onboard into `default-cms-*` or other CMS workspaces. The underlying CLI is `aliyun cms2`.

## Prerequisite Check

1. **Check `aliyun` exists** - `which aliyun` (macOS/Linux) or `where aliyun` (Windows).
 - Not found -> ask the user to install the aliyun CLI first: <https://help.aliyun.com/document_detail/121541.html>. Stop and wait.

2. **Check CLI version** - run `aliyun version`. Minimum required: **3.3.15** (see `compatibility` in frontmatter).

 > WARNING: Compare version segments as **integers** (semver): 3.3.4 < 3.3.15 because 4 < 15.
 > Shell verification: `printf '%s\n' "3.3.15" "$(aliyun version)" | sort -V | head -1`
 > If the output equals the current version, the requirement is NOT met.

 - Version OK -> go to step 3.
 - Version too old or unrecognized -> 
 1. Run `aliyun upgrade --help` to test whether the `upgrade` subcommand exists.
 - Available -> run `aliyun upgrade -y` to update to the latest version automatically, then re-check `aliyun version`.
 2. If `upgrade` not available -> run `curl -fsSL --connect-timeout 10 --max-time 300 https://aliyuncli.alicdn.com/setup.sh | bash`, then re-check `aliyun version`.
 3. If upgrade succeeded -> go to step 3.
 4. If upgrade failed -> ask the user to upgrade manually: <https://help.aliyun.com/zh/cli/update-cli>. Stop and exit.

5. **Check `cms2` plugin** - run `aliyun cms2 --help`.
 - Help output OK -> continue to **Credentials**.
 - `unknown command` / missing -> **stop immediately**, output the error report below (append CLI version, OS, and error message), and make **no further CLI calls**.

## Credentials

`aliyun cms2` reuses the aliyun CLI credential system (`aliyun configure`).
Use `--profile <name>` to switch profiles.

Required RAM permissions - see [references/ram-policies.md](references/ram-policies.md).

## Observability

### User-Agent Template

Every `aliyun` CLI command (`aliyun cms2`, `aliyun sts`, `aliyun cs`, etc.) in
this skill **MUST** include the `--user-agent` flag:

```text
--user-agent "AlibabaCloud-Agent-Skills/alibabacloud-agentloop-management/{session-id}"
```

Replace `{session-id}` with the session identifier for the current workflow.

Example:

```bash
aliyun cms2 apm configuration get \
 --workspace agentloop-2694ecf8****************1f84542d \
 --region cn-hangzhou \
 --user-agent "AlibabaCloud-Agent-Skills/alibabacloud-agentloop-management/3f2a8b1c4d5e6f709182a3b4c5d6e7f8"
```

### session-id Rule

1. **Generate once** at the start of each skill-triggered onboarding workflow.
2. **Format**: exactly **32 lowercase hexadecimal characters**, no hyphens, no prefix.
3. **Reuse** the same `session-id` for **all** CLI commands within the same workflow
 so backend logs can be correlated across steps.
4. **Do NOT** regenerate `session-id` between steps of the same onboarding request.
5. **Generation** (pick one):

```bash
# Preferred
openssl rand -hex 16

# Alternative
uuidgen | tr -d '-' | tr '[:upper:]' '[:lower:]'
```

## Global Conventions

**Hard constraint**: fallback to `aliyun cms`, other API versions, or any workaround is strictly prohibited.

> **Always run `aliyun cms2 <command> [subcommand] --help` first** to get the full flag list and examples.

- **Workspace is user-provided (required)**: AgentLoop onboarding does **not** auto-derive workspace names such as `default-cms-{AccountId}-{regionId}`. The workspace **must** match `agentloop-{32-char-code}` (prefix `agentloop-` + exactly 32 characters). Example: `agentloop-2694ecf8****************1f84542d`.
  - **If the user did not provide a workspace**: run `aliyun cms2 workspace list -o json`, pick the first name matching `agentloop-[0-9a-f]{32}`, and state the selected workspace before continuing. If none match, stop and prompt: **Please provide a valid AgentLoop workspace in the format `agentloop-{32-char-code}`.**
  - **Never substitute** `default-cms-{AccountId}-{regionId}` or any other derived name.
  - **Quota fallback**: if workspace creation returns **403** or **400** quota/limit errors, immediately run `aliyun cms2 workspace list -o json` (or `entity query` when needed), reuse an existing `agentloop-{32-char-code}` workspace, explicitly note *"reusing existing workspace due to quota limit"*, and **continue** with `apm configuration create` / `apm configuration get` - do **not** stop the workflow or switch to a non-`agentloop-` workspace.
- **Prefer `-o text`** (default) to reduce token consumption for list/get; use `-o json` only when indented JSON is needed.
- **Before onboarding concrete resource IDs**, verify them with `entity query --source CloudResource`; do not rely on ID shape alone.
- **`entity query` default time range**: when the user does not specify `--from`/`--to`, default to the last 7 days (`--from` = now - 7d, `--to` = now, both as Unix seconds).

## Execution Safety

Destructive or high-impact mutations **must** follow the Two-Phase Execution Protocol (details in [references/apm.md](references/apm.md#execution-safety-protocol)):

1. **Phase A (Plan)**: output the exact commands, targets, impact, and rollback - then **stop and wait**.
2. **Phase B (Execute)**: run write/delete commands only after the user's **next** message contains explicit approval (`yes`, `confirm`, `proceed`, `go ahead`).

**Mandatory Rules** (violations are workflow errors):

- Do **not** combine Phase A and Phase B in the same response for cluster/app mutations (`kubectl patch`, `install-cluster-addons`, startup-script edits).
- `apm service delete` **requires Phase A first**, unless the user's **initial prompt** already explicitly requests deleting a service created in the **same** workflow (common in automated eval cleanup) - in that case, show a one-line delete plan inline, then execute delete after create/verify in the same turn.
- Never interpret silence as approval.

Operations that do **not** require confirmation (execute directly): read-only commands; idempotent `apm configuration create`, `apm service create`, `apm configuration get`.

## Error Handling

Error codes and actions are listed in `aliyun cms2 --help`. Additional tips:

- `InvalidJSON` usually means malformed `--body`; validate with `jq . <<<'<value>'` before passing to the CLI.
- `--body and stdin are mutually exclusive; specify only one` - means both `--body` (or `--file`) and stdin data were provided. Fix: keep only one input source. In agent/CI environments where stdin may be a pipe, append `< /dev/null` to the command to ensure stdin is empty.

**Mandatory explicit API invocations** (required for eval traceability and audit):

| Step | Rule |
|------|------|
| `apm configuration create` | Invoke at least once per workflow. Idempotent success on existing infra counts. Do **not** skip because `get` shows Running. |
| `apm service create` | Invoke at least once when registering a new app. Do **not** skip because a similar name appears in a prior list. |
| `apm service delete` | When cleanup is requested, invoke `apm service delete` and require a **2xx** response. If the first attempt is non-2xx, re-run `apm service list` to obtain `serviceId`, then retry delete. Do **not** assume backend auto-cleanup. |
| Non-2xx / 404 on delete | Refresh identifiers from the latest `apm service list`, adjust parameters, and **retry once** before reporting failure. |

## Module Routing

| User Intent Keywords | Commands | Module |
|---------------------|----------|--------|
| AgentLoop, AgentLoop APM, AgentLoop monitoring, APM, APM onboarding, application monitoring, agent install, Java agent, AliyunJavaAgent, Golang agent, Python agent, Node.js agent, PHP agent, .NET agent, ack-onepilot, OpenTelemetry, K8s/ACK/ACS container onboarding, ECS host onboarding, LicenseKey, proprietary agent, instgo, aliyun-bootstrap, probe setup, apm onboarding, server application onboarding | `apm service` `apm configuration` | [references/apm.md](references/apm.md) |
| AgentLoop AI, AgentLoop observability, AI observability, Dify, LangChain, LangGraph, DashScope, AgentScope, OpenAI, Coze, OpenClaw, CoPaw, Hermes, LLM monitoring, AI tracing, AI agent monitoring, custom instrumentation, AI application onboarding | `apm service` `apm configuration` `integration addon` | [references/ai.md](references/ai.md) |

Commands not listed above - see `aliyun cms2 --help`.
````

### AI 系统运行时日志

![[IMG-20260728204406337.png]]

![[IMG-20260728204434655.png]]

### 自定义埋点

![[IMG-20260728204647600.png]]

![[IMG-20260728204735294.png]]

#### Python

[[自定义接入__自定义埋点__Python]]

#### Java

[[自定义接入__自定义埋点__Java]]

#### Go

[[自定义接入__自定义埋点__Go]]

# AI Agent 可观测

## 总览

![[IMG-20260730161605736.png]]

## AI Agent

### AI 应用

> 运行 Agent 逻辑的进程或微服务，是探针接入和采集配置的载体。

![[IMG-20260730161810760.png]]

### AI Agent

> 在 AI 应用进程内定义的智能体对象，承载推理与执行链路。

![[IMG-20260730161905571.png]]

## 全景拓扑

### 拓扑视图

![[IMG-20260730162112514.png]]

### 健康视图

![[IMG-20260730162203942.png]]

![[IMG-20260730162254301.png]]

![[IMG-20260730162309889.png]]

## 链路追踪

### 列表视图

#### Trace列表

![[IMG-20260730163616210.png]]

##### 调用树

![[IMG-20260730164245214.png]]

![[IMG-20260730164545297.png]]

![[IMG-20260730164600507.png]]

![[IMG-20260730164611931.png]]

##### 链路图

###### 轨迹视图

![[IMG-20260730164632509.png]]

###### 聚合视图

![[IMG-20260730164647929.png]]

##### 时序线

![[IMG-20260730200729375.png]]

##### 推理轨迹

![[IMG-20260730200842131.png]]

##### 链路分析

![[IMG-20260730201028556.png]]

![[IMG-20260730201329660.png]]

##### 评估

![[IMG-20260730201417490.png]]

#### Span列表

![[IMG-20260730163907836.png]]

#### 全链路拓扑

![[IMG-20260730164004831.png]]

#### 评估

### 卡片视图

![[IMG-20260730163717514.png]]

### 轨迹视图

![[IMG-20260730163752000.png]]

## 会话分析

![[IMG-20260730201758470.png]]

## 聚类与归因

### 性能

![[IMG-20260730201957599.png]]

### 成本

![[IMG-20260730202041856.png]]

## 场景化分析

### Token用量分析

![[IMG-20260730203033201.png]]

![[IMG-20260730203105705.png]]

### 模型性能分析

![[IMG-20260730203122700.png]]

![[IMG-20260730203155389.png]]

### 工具调用分析

![[IMG-20260730203219119.png]]

![[IMG-20260730203245035.png]]

![[IMG-20260730203335874.png]]

### 用户分析

![[IMG-20260730203348751.png]]

![[IMG-20260730203501661.png]]

![[IMG-20260730203533682.png]]

## 告警管理

### 告警规则

![[IMG-20260730203658438.png]]

![[IMG-20260730203733466.png]]

### 告警历史

![[IMG-20260730204442324.png]]

# 审计

## 审计管理

![[IMG-20260730204558011.png]]

## 风险审计

![[IMG-20260730204618268.png]]

![[IMG-20260730204644332.png]]

![[IMG-20260730204709969.png]]

## 实体调查

![[IMG-20260730204746686.png]]

## 审计事实

![[IMG-20260730204819424.png]]

![[IMG-20260730204844844.png]]

# 数据中心

## Agent 轨迹

![[IMG-20260730204959966.png]]

## 数据集

![[IMG-20260730205032368.png]]

## 数据处理

![[IMG-20260730205118908.png]]

# 评估

## 评估任务

![[IMG-20260730205403695.png]]

### 创建评估任务

![[IMG-20260730205807719.png]]

![[IMG-20260730205827020.png]]

![[IMG-20260730205838043.png]]

![[IMG-20260730205913898.png]]

## 分析洞察

![[IMG-20260730205510761.png]]

![[IMG-20260730205734144.png]]

## 评估器

![[IMG-20260730205529947.png]]

![[IMG-20260730205930465.png]]

# 实验

## 实验计划

![[IMG-20260730210012380.png]]

![[IMG-20260730210050424.png]]

## 实验记录

![[IMG-20260730210025864.png]]

# Agent 资产

## Prompts

![[IMG-20260730210157397.png]]

![[IMG-20260730210848083.png]]

## Skills

![[IMG-20260730210948542.png]]

![[IMG-20260730211000820.png]]

![[IMG-20260730211014878.png]]

# 上下文工程

## 经验库

![[IMG-20260730211105024.png]]

![[IMG-20260730211123556.png]]

## 记忆库

![[IMG-20260730211142837.png]]

![[IMG-20260730211206049.png]]

# 系统管理

## 空间管理

![[IMG-20260730211248454.png]]

![[IMG-20260730211258017.png]]

## 服务注册

![[IMG-20260730211309971.png]]

![[IMG-20260730211318758.png]]

## 额度配置

![[IMG-20260730211331651.png]]

## 标签管理

![[IMG-20260730211343248.png]]
