---
source_url: "https://mp.weixin.qq.com/s?search_click_id=10944039153882374254-1784128384587-3802022945&__biz=MzI3NjA1MTcyMQ==&mid=2650489174&idx=1&sn=0ed35d7d6b22a7e08eb47591b97ad227&chksm=f272f19f8b7e81849861d7698202d98b24ad03d56093b18c19b702b8029670dad1e1ed65cbec&subscene=0&scene=7&clicktime=1784128384&enterid=1784128384&ascene=65&devicetype=iOS26.5.2&version=18004b3c&nettype=WIFI&abtest_cookie=AAACAA==&lang=zh_CN&countrycode=CN&fontScale=100&exportkey=n_ChQIAhIQPprPK03zq2I4AiaD+YkJPBLhAQIE97dBBAEAAAAAAIl5GT7Kg+0AAAAOpnltbLcz9gKNyK89dVj01ZFD07ztvEmqvEbFHDu9MMQLfrC0XifanZGTRh8TZOP90s2LzYS1I9lzRn0ss94R4xnndTGIJHIP1Vyt0IHKgN9SCGP9q/iepYvJN4gT1gf1Wg5PkItoGqaYeJGyTh3X8ayIxfIWBdgAcxO3eFpjhTeQ+odmh6F1Opu7CST0j1fYCnfeKeH8dfYXSG2YWsX83ub9cy7bV//1iwP2enbNq5GNlvpAQ2fZKTmcPQPDt0Q7pnGgQY+nOnYpWA==&pass_ticket=xB6sDqvfJXKmziLlrYNtye7nunP57kzE7MnQc94s2CTdlzas4ULqx21fXVIgyF99&wx_header=3"
title: "正式开源！Doris 驱动的Agent观测平台"
account: "一臻数据"
published_at: "2026-07-05T16:18:54.000Z"
saved_at: "2026-07-15T15:13:11.525Z"
sync_id: "art_74e25079b3704330be143ef81afd7fa6"
parse_status: "ok"
---

# 正式开源！Doris 驱动的Agent观测平台

见字如面，我是**一臻**

![图片](附件资源/正式开源！Doris%20驱动的Agent观测平台/img_1.gif)

** ****90后新手奶爸，探索Doris x AI Agent**

点击关注 👇 免费领取**数智AI**知识库

> “ 前不久有个做 AI 应用的小伙伴跑来问我："你说奇不奇怪，我们的 Agent 系统，所有接口都是 200，延迟正常，错误率为零——但用户就是在反馈 答得不对 。我到底该查哪里？" 我没有立刻回答他，因为这个问题问出了Agent应用时代一个真实的困境： 传统监控告诉你系活着，但没有人告诉你 Agent 答对了没有。 这两件事，压根不是同一件事。

![](附件资源/正式开源！Doris%20驱动的Agent观测平台/img_2.png)

# 200 OK，是谎言

做传统后端的时候，接口返回 200、P99 延迟在阈值内、Grafana 绿灯一片，运维同学就可以安心下班了。

这套逻辑在面向Agent 的时候彻底失效。

举个栗子：某团队的 Agent 调用了一个内部工具来查询商品库存，工具返回了 JSON，大模型把 `price` 字段的值当成了 `quantity` 来理解，然后自信满满地告诉用户 `库存还有 299 件` 。

日志上显示：工具调用成功，响应时间 80ms，状态码 200。

这个错误静悄悄地生效了，没有任何告警。

Agent 的不确定性来自多个层面：模型幻觉、工具调用语义漂移、上下文过长导致的遗忘、多步推理的中途走偏。

这些问题不会触发任何 HTTP 异常，也不会体现在 QPS曲线上。

你需要的不是 `接口有没有通` 的监控，而是 `Agent 每一步在干什么、干得对不对` 的观测体系。

这正是 **EDD（Evaluation Driven Development，评估驱动开发）** 这个方法论被越来越多 Agent 团队接受的原因。

核心逻辑是三步：先完整记录 Agent 每一步的真实行为，再用测试集对行为结果做量化评估，最后拿评估数据驱动 Prompt 调优和模型选型决策。

这个闭环，才让 `Agent 变好了` 这句话有了可以验证的依据，而不只是研发同学的主观感受。

而 **基于 Apache Doris 构建的Litefuse**，就是把这套EDD 方法论产品化的可观测平台——这周，它正式开源了。

# 为什么要把 Clickhouse 换成 Doris

![](附件资源/正式开源！Doris%20驱动的Agent观测平台/img_3.png)

**Litefuse** 基于 Langfuse 构建，兼容其SDK 和 100多个 AI 生态集成，但在存储层做了一个核心替换：**把 Clickhouse 换成了 Apache Doris**。

Why？

用过 Langfuse 一段时间的团队，普遍会遇到几个问题。

第一是**存储成本失控**，几万月活的 Agent 系统，可观测数据动辄 TB 级，存储费用变成了整个 AI 应用成本里最显眼的一项支出。

第二是**搜索 Trace奇慢**，用户反馈 bad case 的时候只有一句话，你需要从几十万条 Trace 里靠内容关键词找出来，Langfuse 用LIKE 做全文检索，扫全表，往往要等十几秒。

第三是**自部署太重**，Langfuse 官方方案需要维护 6 个组件——Web服务、Worker、Redis、MinIO、Postgres、Clickhouse——出了问题，排查这套基础设施本身就要花不少时间。

这三个痛点对应的，恰好是 Apache Doris 的能力优势所在。

Agent 的Trace 数据天然是 `重数据` ：一次大模型调用，输入输出可能是 MB 级长文本，复杂任务的 Trace 可能有几万个 Span，数据里大量是嵌套 JSON 格式。

Doris 的 **VARIANT 数据类型**，专门为这类半结构化 JSON 设计——写入时自动把 JSON 字段按列拆分存储，查询时只读相关子列，既不需要先扫整行再解析 JSON，压缩比也大幅提升。

加上列存+ ZSTD 压缩，再配合 Doris 开源版本就支持的**存算分离架构**（数据写一份存对象存储，不需要多副本），**实际测试中Litefuse 相比 Langfuse 存储空间降低了 65% 到 88%，长对话场景降幅更大**。

Clickhouse 开源版本不支持存算分离，这是先天的架构限制，用户要靠本地多副本来保障可靠性，成本自然压不下去。

全文检索方面，Doris 从 2023 年开始完整支持倒排索引，支持关键词、短语、前缀、正则和多字段混合检索，中英文分词都覆盖。

这套能力已经在 MiniMax、阶跃星辰、字节、快手、腾讯等公司的 PB 级生产环境跑了多年，用来搜 Agent Trace 内容，响应时间稳定在秒级，比 Langfuse 的 LIKE 快 5 到 10 倍。

还有一个细节：Doris 的**延迟物化**技术，在处理 `取最新 Top N 条 Trace` 这类高频查询时，排序阶段只读时间戳字段，Top N 确定后才读完整记录，避免了把大量 MB 级长文本加载进内存。

按trace_id 哈希分桶、数据文件内部按 trace_id 排序，分析一个完整 Trace 时可以范围 scan 快速拿到所有 Span，不用散点式地到处查找。

这些能力组合在一起，是Doris 这些年在大规模可观测场景里沉淀出来的真实积累。从 PB 级用户行为日志，到现在的 Agent Trace，技术路线一脉相承。

# Litefuse 正式开源，25秒上手

![](附件资源/正式开源！Doris%20驱动的Agent观测平台/img_4.png)

目前，Litefuse 正式在 GitHub 开源：https://github.com/litefuse/litefuse

官网：https://litefuse.ai

Litefuse 开源的同时，推出了一个极致轻量的单进程部署模式，一行命令：

```
curl -fsSL https://litefuse.ai/install.sh | sh
```

大约 25 秒，下载 358MB 安装包，解压安装完成，服务启动，可以开始用了。

整个单机版是一个二进制包，Node.js 运行时和 JVM 运行时都打包在里面，底层数据库用嵌入式的 PGlite（Postgres）和 DorisLite（Doris），以库的形式加载，不是独立进程。

整个系统启动后，你只会看到一个进程。

拿它和 Langfuse 自部署对比一下，后者要先有 Docker 环境，拉镜像，国内拉取还要配镜像源，等下载，起来之后六个容器在后台跑着。

顺利的话几分钟，碰上网络问题半小时也等过。

当然，这并不是说 Langfuse 的架构不好，它的多组件拆分是为分布式高并发场景设计的，合理。问题是对于只需要在一台机器上跑起来的团队，这套复杂度明显溢出了使用需求。

有个做ToB 交付的朋友看到 25 秒这个数字，第一反应是："这个才对，我去给客户部署，人家服务器根本没有 Docker 环境，网络也不通外网，Langfuse 那套方案进不了门。"

单进程不代表能力弱，Litefuse 单机版可以处理 TB 级数据，对绝大多数中小规模 Agent 团队来说完全够用。

需要扩容时，切换到完整分布式部署也有清晰的路径。

# 结语

对于 Agent 可观测这件事，正在从锦上添花变成不得不做。

随着 Agent 复杂度提升、链路变长、规模扩大，靠主观感受和零散反馈来判断效果的方式会越来越不可靠。

EDD（观测-评估-优化） 给了一条务实的路：把每一步行为记录下来，用真实数据打分，让每次优化有迹可循。

**Doris 在这套体系里不只是存储组件，它的列存压缩、VARIANT 类型、倒排索引、延迟物化、存算分离，每一项能力都在对抗 Agent Trace 数据特有的挑战**。

Litefuse 目前已在 GitHub 开源，MIT 协议，没有使用限制。

如果你正在做 Agent 开发，值得花那25 秒装一下，先把行车记录仪开起来，出了问题至少知道往哪儿查。

![](附件资源/正式开源！Doris%20驱动的Agent观测平台/img_5.png)

**完**

关注 **一臻 ****免费领取**数智AI**资料，我们下期见**❗️

#大数据 #开源 #AI #Doris #SelectDB #Agent

---
原文链接：https://mp.weixin.qq.com/s?__biz=MzI3NjA1MTcyMQ%3D%3D&mid=2650489174&idx=1&sn=0ed35d7d6b22a7e08eb47591b97ad227&chksm=f272f19f8b7e81849861d7698202d98b24ad03d56093b18c19b702b8029670dad1e1ed65cbec
