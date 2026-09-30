---
source_url: "https://mp.weixin.qq.com/s?__biz=Mzg5NTA0MTEyNw%3D%3D&mid=2247484588&idx=1&sn=b2edb6e55b1b49abe0d1a6080e6c0703&chksm=c0172fa4f760a6b2ccaf8b27fc92e076893f161ec1b3453a783dbecb4b75d9d8a848e1bf23ca"
title: "实操落地｜WeKnora打通MinerU+Confluence！实现文档解析+知识库联动一体化"
account: "随笔随记随意"
published_at: "2026-09-21 15:41:19"
saved_at: "2026-09-21 22:09:20"
sync_id: "art_b509336f72474d83954bb718bc9311bc"
parse_status: "ok"
---

# 实操落地｜WeKnora打通MinerU+Confluence！实现文档解析+知识库联动一体化

在企业日常办公中，海量PDF、Word、PPT、扫描件文档分散存储，人工整理、归档、上传Confluence知识库效率极低；同时，传统Confluence仅支持手动查阅、编辑，无法依托AI实现智能检索、内容总结与自动更新，知识库利用率大打折扣。

针对这一痛点，本文带来在**WeKnora中对接Confluence和MinerU**，通过MCP协议搭建联动链路，依托MinerU完成全格式文档高精度解析，再通过Confluence MCP服务实现知识库读写、更新、检索自动化，无需定制开发、无需手动搬运，一站式解决企业文档处理与知识库运维难题。

## 一、整体方案架构与核心能力

整套方案以WeKnora AI平台为核心中枢，联动两大核心服务：**MinerU文档智能解析服务**负责各类文件结构化提取，**Confluence MCP服务**负责知识库的读写与运维，形成「文档上传→智能解析→AI整理→知识库归档→智能检索」的全闭环流程。

### 核心联动能力

- MinerU能力 ：精准解析电子PDF、扫描件、Word、PPT、图片等全格式文档，支持中文识别、公式还原、表格结构化提取、图文分离，彻底解决文档乱码、格式错乱、扫描件无法编辑的问题
- Confluence MCP能力 ：基于MCP协议对接企业Confluence知识库，支持文档检索、页面读取、子页面拉取、页面创建、内容更新、标签管理等全量操作
- WeKnora联动能力 ：串联双服务，AI自动梳理解析后的文档内容、剔除冗余信息、标准化排版，一键归档至Confluence，同时支持基于知识库智能问答、内容总结、批量梳理

## 二、Confluence MCP服务部署（核心对接配置）

在[企业知识库神器 Confluence：研发团队的知识沉淀终极方案](https://mp.weixin.qq.com/s?__biz=Mzg5NTA0MTEyNw==&mid=2247484422&idx=1&sn=aa7e871b2a2080316fedf877d3c2ad0d&scene=21#wechat_redirect)中，我们介绍了企业知识库的标杆产品Confluence。接下来将通过Docker容器快速部署mcp-atlassian服务，打通WeKnora与Confluence知识库的通信通道，提供标准化SSE传输接口，支持AI调用知识库各类工具。注意：在这里我们将Weknora和mcp-atlassian部署在同一个服务器内并复用weknora_WeKnora-network。

需要在Confluence上创建一个个人访问令牌用作mcp授权：

![](附件资源/实操落地｜WeKnora打通MinerU+Confluence！实现文档解析+知识库联动一体化/img_1.png)

### 1. 完整部署配置文件

新建 **confluence-mcp.yaml** 配置文件，内容如下：

```
services:
  mcp-atlassian:
    image: ghcr.io/sooperset/mcp-atlassian:latest
    container_name: confluence-mcp
    restart: unless-stopped
    ports:
      - "9000:9000"
    environment:
        - CONFLUENCE_URL=${your_confluence_url}
        - CONFLUENCE_USER=${your_confluence_username}
        - CONFLUENCE_PERSONAL_TOKEN=${your_confluence_token}
        - MCP_TRANSPORT=sse
        - MCP_PORT=9000
        - MCP_HOST=0.0.0.0
        - ALLOW_GLOBAL_CRED_FALLBACK=true
        # 可按需开启指定工具集
        #- ENABLED_TOOLS=confluence_search,confluence_get_page,confluence_get_spaces
        #- TOOLSETS=confluence
    command: --transport sse --port 9000
    networks:
      - weknora_WeKnora-network
networks:
  weknora_WeKnora-network:
    external: true
```

### 2. 关键配置参数解析

- CONFLUENCE_URL ：企业内部Confluence知识库访问地址，确保内网可正常访问
- 账号与令牌 ：通过专属账号+个人访问令牌完成接口鉴权，保障知识库操作安全
- MCP传输协议 ：采用SSE长连接模式，完美适配WeKnora平台接入规范，保障服务稳定联动
- 网络配置 ：复用WeKnora外部专属网络，实现容器与平台内网互通，规避跨网络访问故障

```perl
root@ai:~# docker network ls
NETWORK ID     NAME                      DRIVER    SCOPE
856a463917d9   bridge                    bridge    local
38adf4a24a67   host                      host      local
2af736a367a7   weknora_WeKnora-network   bridge    local
```

### 3. 服务启动命令

```
docker-compose -f confluence-mcp.yaml up -d
```

启动成功后，Confluence MCP服务访问端点：

```bash
http://confluence-mcp:9000/sse
```

## 三、MinerU文档解析服务对接配置

在前面的文章中[MinerU完整版Docker GPU部署（本地私有化）](https://mp.weixin.qq.com/s?__biz=Mzg5NTA0MTEyNw==&mid=2247484321&idx=1&sn=ba2048acb3fa20c8e5e803ffc3f7b162&scene=21#wechat_redirect)，我们介绍了MinerU的本地部署，MinerU作为前置解析服务，可为Confluence知识库提供标准化文档素材，解决非结构化文档无法直接归档知识库的痛点。只需要开启MinerU的API，即可进行对接：

```css
docker compose -f compose.yaml --profile api up -d
```

### 核心对接参数

- 服务端点地址 ：

```javascript
http://192.168.0.8:8000
```

- 运行后端 ：pipeline
- 核心功能开启 ：公式识别、智能表格识别、中文解析模式
- 解析适配规则 ：电子PDF极速提取文本格式，扫描件自动触发OCR图文识别，完整保留原文档排版、表格、公式结构

配置完成后，MinerU可自动完成各类办公文档的结构化处理，为后续Confluence归档提供高质量内容素材。

## 四、WeKnora平台双服务联动配置

在WeKnora后台统一配置两大服务，实现解析、归档、检索全流程自动化，是整套方案的核心联动步骤。

### 1. Confluence MCP服务接入

- 服务名称：自定义为「confluence-mcp知识库服务」
- 传输类型：选择 SSE 协议
- 服务URL：

```bash
http://confluence-mcp:9000/sse
```

- 请求头认证：新增 Authorization 头部，值为 Bearer + Confluence个人令牌 ![](附件资源/实操落地｜WeKnora打通MinerU+Confluence！实现文档解析+知识库联动一体化/img_2.png)
- 配置完成后点击「测试连接」，连通后自动加载35项Confluence工具能力，涵盖检索、读页、建页、更新、标签管理等 可按需选择需要人工审核的工具： ![](附件资源/实操落地｜WeKnora打通MinerU+Confluence！实现文档解析+知识库联动一体化/img_3.png)

### 2. MinerU服务接入生效

在WeKnora文件处理模块绑定上述MinerU端点，开启默认解析服务，后续所有上传文档将自动调用MinerU完成结构化解析，无需手动操作。

![](附件资源/实操落地｜WeKnora打通MinerU+Confluence！实现文档解析+知识库联动一体化/img_4.png)

## 五、完整业务联动流程

整套服务打通后，可实现标准化自动化办公流程，适配绝大多数企业知识库运维场景：

**文档上传 → MinerU智能解析 → WeKnora AI优化整理 → Confluence自动归档/更新 → AI智能检索问答**

- 文件上传 ：用户在WeKnora平台上传PDF、Word、PPT、扫描件等任意格式文档
- 结构化解析 ：自动调用MinerU服务，精准提取文本、表格、公式、图片，修复乱码、排版错乱问题，生成标准化结构化内容
- AI内容优化 ：WeKnora AI自动剔除冗余内容、梳理逻辑、标准化排版、提炼核心要点
- 知识库联动 ：通过Confluence MCP服务，一键创建新页面归档文档，或更新对应历史知识库页面、补充标签分类
- 智能复用 ：后续可通过AI检索Confluence全量知识库，智能解答业务问题、总结文档内容、梳理知识库目录

智能推理智能体配置MCP服务：

![](附件资源/实操落地｜WeKnora打通MinerU+Confluence！实现文档解析+知识库联动一体化/img_5.png)

MCP选confluence-mcp，智能体选智能推理：

![](附件资源/实操落地｜WeKnora打通MinerU+Confluence！实现文档解析+知识库联动一体化/img_6.png)

问题提交后自动调用confluence-mcp对接confluence进行内容查找：

![](附件资源/实操落地｜WeKnora打通MinerU+Confluence！实现文档解析+知识库联动一体化/img_7.png)

## 六、核心落地应用场景

- 文档自动化归档 ：项目资料、会议纪要、技术手册、培训课件上传后，自动解析整理并归档至Confluence对应空间，告别手动复制粘贴
- 知识库智能更新 ：新版制度、技术文档更新后，AI自动对比新旧内容，一键更新Confluence页面，同步更新标签与目录
- 精准知识库问答 ：依托解析后的标准化知识库，AI精准调取Confluence内容，解答员工业务咨询、技术疑问
- 批量知识库梳理 ：自动拉取Confluence页面树，批量总结文档核心内容，生成知识库总目录、内容综述

## 七、运维注意事项

- 网络互通要求 ：Confluence MCP容器必须接入WeKnora专属外部网络，确保平台可正常访问9000端口SSE服务，MinerU端点需内网全程通畅
- 权限安全管控 ：Confluence个人令牌遵循最小权限原则，生产环境可限制指定空间的读写权限，避免全域操作风险
- 操作风险规避 ：Confluence页面创建、更新等写操作，默认开启人工审核机制，防止AI误修改、误删除线上知识库内容
- 故障排查优先级 ：连接异常时，优先检查容器运行日志、内网端口连通性、令牌有效性、双服务端点配置准确性
- 解析质量优化 ：扫描件文档建议固定开启OCR识别，复杂公式、表格文档可手动勾选精准解析模式，保障归档内容质量

## 八、总结

依托 WeKnora 作为核心中枢，同时对接 MinerU 文档解析服务与 Confluence 知识库，基于 MCP 协议完成低代码集成。一方面借助 MinerU 完成 PDF、扫描件、PPT 等非结构化文档的高精度提取，解决文档入库难题；另一方面打通 Confluence 读写能力，让大模型直接检索、创建、更新 Wiki 页面。整套方案部署简单、稳定可靠，无需大量定制开发，快速落地文档解析 + 知识库联动，释放 Confluence 的 AI 能力，减少人工整理归档成本，最大化企业知识库价值。值得一提的是，WekNora中的全套模型也是使用GPUStack搭建的，实现整体的私有化部署，保证了知识库的安全。

![](附件资源/实操落地｜WeKnora打通MinerU+Confluence！实现文档解析+知识库联动一体化/img_8.png)

---
原文链接：https://mp.weixin.qq.com/s?__biz=Mzg5NTA0MTEyNw%3D%3D&mid=2247484588&idx=1&sn=b2edb6e55b1b49abe0d1a6080e6c0703&chksm=c0172fa4f760a6b2ccaf8b27fc92e076893f161ec1b3453a783dbecb4b75d9d8a848e1bf23ca
