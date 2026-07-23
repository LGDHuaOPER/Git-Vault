---
title: "RAM权限策略参考"
source: "https://help.aliyun.com/zh/document_detail/3033852.html?spm=a2c4g.11186623.help-menu-3033820.d_4_0.999d5bf872j0Zl"
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
"word-count": "748"
更新时间: "2026-07-10 10:33:05"
---
在使用AgentLoop 服务时，不同的使用人员可能需要不同的访问权限，此时主账号使用者可以通过对RAM设置不同的权限策略来实现对AgentLoop的资源的访问控制。

## **权限策略类型**

若您使用RAM，请根据需要向主账号使用者申请权限策略。授权操作请参考[管理RAM用户的权限](https://help.aliyun.com/zh/ram/user-guide/grant-permissions-to-the-ram-user)。

阿里云为用户提供了两类策略类型，分别是系统权限策略与自定义策略。

-   系统权限策略：由阿里云统一创建，使用更简单，无法修改。
    
-   自定义策略：需要用户自定义策略内容，若系统权限策略不能满足要求，可创建自定义权限策略实现最小授权，实现权限精细化管控。
    

### **系统权限策略**

系统权限策略统一由阿里云创建，策略的版本更新由阿里云维护，用户只能使用不能修改。AgentLoop的系统权限策略如下：

-   AliyunAgentLoopFullAccess：授予管理AgentLoop的权限。
    
-   AliyunAgentLoopReadOnlyAccess：授予只读访问AgentLoop的权限。
    

### **自定义权限配置**

使用场景：客户希望针对子账号以及角色，配置细粒度管控权限，可以按需添加自定义权限点，适合精细管理场景。

## **读权限**

| 权限点 | 说明  |
| --- | --- |
| ``` { "Action": [ "agentloop:Get*", "agentloop:List*", "agentloop:Describe*", "agentloop:ExecuteQuery" ], "Resource": "*", "Effect": "Allow" } ``` | AgentLoop 服务读权限，包含Agent空间，数据集，经验库等 |
| ``` { "Action": [ "log:GetLogStoreLogs", "log:GetLogStoreHistogram", "log:GetIndex", "log:GetLogStore", "log:GetProject", "log:ListLogStores", "log:ListProject" ], "Resource": "*", "Effect": "Allow" } ``` | 查询日志服务已有的 LogStore 中数据 |
| ``` { "Action": [ "airegistry:ListNamespaces", "airegistry:ListPrompts", "airegistry:ListPromptVersions", "airegistry:ListSkills", "airegistry:GetNamespace", "airegistry:GetPrompt", "airegistry:GetPromptVersion", "airegistry:GetPromptVersionDetail", "airegistry:GetPromptGovernance", "airegistry:GetSkillDetail", "airegistry:GetSkillVersionDetail", "airegistry:DownloadSkillVersion", "airegistry:DownloadSkillVersionViaOss" ], "Resource": "*", "Effect": "Allow" } ``` | 包含 AI 治理中心 Prompt 和Skill 读权限。 |
| ``` { "Action": [ "cms:GetWorkspace", "cms:GetEntityStoreData", "cms:GetServiceObservability", "cms:GetUmodelCommonSchemaRef", "cms:GetAddon", "cms:GetAddonSchema", "cms:GetAddonCodeTemplate", "cms:GetAddonMetrics", "cms:GetAddonAlertTemplates", "cms:GetAddonRelease", "cms:GetPrometheusUserSetting", "cms:GetCmsService", "cms:GetCloudResource", "cms:GetCloudResourceData", "cms:ListWorkspaces", "cms:ListServices", "cms:ListAddons", "cms:ListIntegrationPolicies", "cms:ListAddonReleases", "cms:ListIntegrationPolicyResources", "cms:ListIntegrationPolicyCollectors", "cms:ListPrometheusInstances" ], "Resource": "*", "Effect": "Allow" } ``` | 云监控2.0 工作空间，数据实体，Addon，APM服务，Umodel 相关读权限 |
| ``` { "Action": [ "resourcecenter:GetResourceCenterServiceStatus" ], "Resource": "*", "Effect": "Allow" } ``` | 查询资源中心服务状态的权限 |

## **写权限**

在读权限基础上，额外新增写操作权限点如下:

| 权限点                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   | 说明                                         |
| ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------ |
| ``` { "Action": [ "agentloop:*" ], "Resource": "*", "Effect": "Allow" } ```                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                           | AgentLoop 服务管理权限                           |
| ``` { "Action": [ "airegistry:CreatePrompt", "airegistry:UpdatePrompt", "airegistry:DeletePrompt", "airegistry:CreatePromptVersion", "airegistry:UpdatePromptVersion", "airegistry:SubmitPromptVersion", "airegistry:DeletePromptVersion", "airegistry:CreateSkillDraft", "airegistry:UpdateSkillDraft", "airegistry:DeleteSkillDraft", "airegistry:SubmitSkillVersion", "airegistry:PublishSkillVersion", "airegistry:ForcePublishSkillVersion", "airegistry:UpdateSkillBizTags", "airegistry:UpdateSkillLabels", "airegistry:OnlineSkill", "airegistry:OfflineSkill", "airegistry:UpdateSkillScope", "airegistry:DeleteSkill", "airegistry:UploadSkill", "airegistry:UploadSkillViaOss" ], "Resource": "*", "Effect": "Allow" } ``` | AI 治理中心 Prompt 和Skill 创建、编辑、发布、删除、调试等全部权限。 |
| ``` { "Action": [ "log:CreateIndex", "log:CreateLogStore" ], "Resource": "*", "Effect": "Allow" } ```                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 | 日志服务创建LogStore 和索引配置权限                     |
| ``` { "Action": [ "cms:CreateService", "cms:CreateIntegrationPolicy", "cms:CreateAddonRelease", "cms:CreateCloudResource", "cms:CreateServiceObservability", "cms:ProxyApiForMemberAccount", "cms:UpsertUmodelCommonSchemaRef", "cms:UpsertUmodelData" ], "Resource": "*", "Effect": "Allow" } ```                                                                                                                                                                                                                                                                                                                                                                                                                                    | 云监控2.0 工作空间，APM服务，可观测服务，Umodel 相关创建，修改权限。  |
| ``` { "Action": "ram:CreateServiceLinkedRole", "Resource": "*", "Effect": "Allow", "Condition": { "StringEquals": { "ram:ServiceName": [ "agentloop.aliyuncs.com" ] } } } ```                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         | 创建AgentLoop 服务关联角色                         |