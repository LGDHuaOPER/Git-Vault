---
source_url: "https://mp.weixin.qq.com/s?search_click_id=10944039153882374254-1784128500847-4324232406&__biz=Mzg3Njc2NDAwOA==&mid=2247540831&idx=1&sn=d24b8e5930df1b87673d13006495c3db&chksm=ceeb08abde7c183aa3b20845325159ee1c8bad6ae989e872c52b0aa725449f406c09f91e675f&subscene=0&scene=7&clicktime=1784128500&enterid=1784128500&ascene=65&devicetype=iOS26.5.2&version=18004b3c&nettype=WIFI&abtest_cookie=AAACAA==&lang=zh_CN&countrycode=CN&fontScale=100&exportkey=n_ChQIAhIQ2ckcKnEjAYr6jRQYvEs1yxLhAQIE97dBBAEAAAAAAOebBk7A7O0AAAAOpnltbLcz9gKNyK89dVj0O2GF1+tz2ms6IKdaaHpQMTAXD1iHCpoIwRw60PEQ3k0Bwlc3jav2YBxhiKw4F3FSNRR2pDXKPIaZ5S7zPjwYD1+CzM36lkQK/uECR2ffWvZxsMjrWWco3ulbCns3YqhrI8cuewy3fqVJeSNrG44dGxuR8KK1H0BXcET8AfX8bvNrDqupbR2YlYo6E4yYs6D3VSw05oO8SWM325QgitLJd3TBprfggpuO4DEON+ifYzlxsZ9/q/zfaNPp9A==&pass_ticket=Nk8ayrTnct5dtnXFawtjyLrzK6fJkhKo9Cu4M1WskhSokM8NkTymHo23LAJiO7jK&wx_header=3"
title: "Apache Doris 在 AgentLogsBench 中领先，支撑 Agent 可观测性生产负载"
account: "SelectDB"
published_at: "2026-07-07T03:59:00.000Z"
saved_at: "2026-07-15T15:15:09.965Z"
sync_id: "art_7eae2588e5174f799b3d6bbb70f1a4af"
parse_status: "ok"
---

# Apache Doris 在 AgentLogsBench 中领先，支撑 Agent 可观测性生产负载

作者｜SelectDB 技术团队

注意：本文中的基准数据反映了 **2026 年 5 月**的 AgentLogsBench 结果。该基准会定期更新。如需查看最新结果，请参阅**实时排行榜**：https://velodb.github.io/agentlogsbench。

当一个 Coding Agent 在生产环境中陷入循环时，问题往往不会以清晰的错误码出现。它可能为了修复一个失败的测试反复编辑同一个文件，多次调用相同工具，持续消耗 token，最终仍然返回一个不可用的 patch。此时，平台团队需要在极短时间内判断：这是单条 trace 的异常、某个模型版本的退化、prompt 模板的问题、特定客户配置导致的异常，还是系统层面的整体故障？

这已经不是假设性场景。随着 AI Agent 从 Demo 走向生产，Agent 平台面临的可观测性问题正在发生根本变化。**Agent 产生的 trace 更长、更复杂，也包含更深层次的嵌套结构**。传统面向 request-response 服务设计的可观测工具，已经难以支撑这类新型工作负载。

01

Agent 可观测性与传统可观测性的差异

传统可观测性主要围绕结构化、稳定且可预测的遥测数据展开，例如 HTTP 状态码、延迟分位数、错误计数等。这类数据通常 schema 固定、payload 较小，通过指标看板和日志检索即可覆盖大多数运维场景。

Agent 可观测性打破了这些前提，主要体现在四个方面。

- 文本主体庞大且无结构 。一次模型调用可能输出 5KB 到 1MB 的内容，其中混合了自然语言、代码、文件路径、堆栈信息和 JSON 片段。诸如 “timeout awaiting headers” 这样的故障特征，往往隐藏在长文本正文中。此时系统需要支持面向大文本的短语搜索，而不是仅对短日志行进行简单字符串匹配。
- Agent 的关键分析字段具有高度动态性 。事故分析中真正重要的维度，例如模型版本、prompt 模板、发布环、客户等级、检索策略等，通常位于动态 JSON payload 中，而非固定列。不同租户、工具和模型供应商都会写入各自的属性，使得同一个 payload 列可能承载大量不同结构。如果依赖预先展开 JSON 路径并维护辅助表，可观测系统本身就会演变为复杂的 ETL 工程。
- Agent trace 是有序链路 ，而不是扁平日志。一个 trace 通常由一系列 observation 构成，包括模型 turn、工具调用、重试以及中间上下文。排查问题时，平台需要按执行顺序取回完整链路，并在回放过程中检索 payload.tool_result.stderr 等嵌套字段。
- 实时看板必须与持续写入并存 。在排障过程中，成本、延迟、失败率、工具调用分布等看板仍需持续刷新。即使 observation 表不断写入新数据，查询也需要在毫秒级或几十毫秒级完成响应。

![](附件资源/Apache%20Doris%20在%20AgentLogsBench%20中领先，支撑%20Agent%20可观测性生产负载/img_1.png)

这意味着，Agent 可观测性要求系统同时具备**短语搜索、动态 ****JSON**** 过滤、有序 trace 回放和实时聚合能力**。

**从本质上看，这已经不再是单点能力问题，而是一个“混合负载数据系统问题”。**

传统搜索引擎擅长文本检索，但分析聚合能力有限；OLAP 数据库擅长看板分析，但通常缺少完整文本搜索能力；文档数据库适合存储动态 JSON，但难以高效完成 trace 回放和分析聚合。

**因此，Agent 可观测性需要一种能够统一承载多种访问模式的新型系统能力。**

02

AgentLogsBench：面向真实混合负载的 Benchmark

**基于上述问题，现有系统难以通过单点指标评估真实能力，AgentLogsBench 正是为这种混合负载可观测系统能力边界而设计的 Benchmark。**

它关注的不是单一能力，例如列扫描速度或文本索引速度，而是 Agent 平台在真实生产环境中更常见的混合负载：回放 trace、搜索故障短语、按动态属性过滤、刷新实时看板，并且所有操作都发生在同一张 observation 表上。

该 Benchmark 位于  `velodb/agentlogsbench`  仓库中，使用同一套工作负载对 Apache Doris、ClickHouse、DuckDB、Elasticsearch、OpenSearch 和 PostgreSQL 进行对比。相关查询、schema、数据生成脚本和结果产物均已开放，便于用户审计与复现。实时排行榜地址为：https://velodb.github.io/agentlogsbench/。

**2.1 数据集设计**

评分对象是一张主表： `agent_observations` 。schema 会把稳定字段提升为列，例如  `trace_id` 、 `seq_no` 、 `event_time` 、 `tenant` 、 `model` 、 `tool_name` 、 `input` 、 `output` 、token 数、成本和延迟。其他内容都放在动态  `payload`  中，包括 tracing 标准字段、模型供应商元数据以及长尾  `attr.*`  字段。

这种单表设计是 benchmark 最重要的约束：它防止某个引擎通过把每个 JSON 路径预先摊平成辅助表，或者把文本搜索和分析拆进两个独立系统来取胜。

数据是合成的，但由 coding-agent trace 按 seed 驱动生成，input 正文从 5 KB 到 1 MB 不等。数据集会把强目标关键词注入 18% 的行，同时加入不应该命中的相似短语。只扫描任意子串的查询会发生过度计数。Benchmark 定义了三个规模等级；本文使用的是 M 级，约 1 亿行。

![](附件资源/Apache%20Doris%20在%20AgentLogsBench%20中领先，支撑%20Agent%20可观测性生产负载/img_2.png)

### 2.2 查询负载

Benchmark 使用 20 个固定查询，按四种访问模式分组：

![](附件资源/Apache%20Doris%20在%20AgentLogsBench%20中领先，支撑%20Agent%20可观测性生产负载/img_3.png)

### 2.3 引擎配置

每个引擎都使用自身原生表示方式，同时保持相同的逻辑表面。比较目标不是强行让所有引擎使用同一套语法，而是观察每个引擎如何用自己的常规存储和索引工具处理同一个 observation model。

![](附件资源/Apache%20Doris%20在%20AgentLogsBench%20中领先，支撑%20Agent%20可观测性生产负载/img_4.png)

Doris 会把文本谓词映射到  `MATCH_ALL`  和  `MATCH_PHRASE` ，把动态路径映射到  `CAST(payload['attr'][...] AS STRING)` 。ClickHouse 使用  `payload`  上的点号访问例如 `payload.attr` ，以及每个查询自己的 token、phrase、substring 或 regex 函数。仓库中的各引擎查询文件是最终依据。

### 2.4 测试方法

所有引擎均运行在相同规格的 AWS  `m6i.8xlarge`  实例上，配置为 32 vCPU、128 GiB 内存和 gp3 SSD。各引擎加载相同原始分片，数据规模约为 1 亿条 observation。runner 对每个查询执行三次计时，其中第一次作为 cold 结果，第三次作为 hot 结果。核心指标为相对每个查询最快结果的 slowdown 几何平均值。

需要注意的是，runner 会在 cold 查询之间清理 Linux page cache，但不会重置 Elasticsearch 内部的 field-data cache 和 filter cache。因此，Elasticsearch 的 cold 结果应理解为 page-cache-cold，而非完全意义上的首次访问。

03

测试结果

### 3.1 存储和加载时间

![](附件资源/Apache%20Doris%20在%20AgentLogsBench%20中领先，支撑%20Agent%20可观测性生产负载/img_5.png)

Doris 存储整个数据集需要 57.94 GiB，是最小存储占用的 1.35 倍，同时仍然在 `input`  和  `output`  上保留完整倒排索引。相比之下，Elasticsearch 和 OpenSearch 若要提供可比的文本检索能力，需要 3 到 4 倍更多存储空间。

加载性能方面，ClickHouse 用时 2,755 秒，排名第一；Doris 用时 4,396 秒，排名第二。

### 3.2 综合排行榜

Benchmark 的核心指标是 cold 与 hot 的综合相对时间，即相对每个查询最快结果的 slowdown 几何平均值，**数值越低表示整体表现越好**。

![](附件资源/Apache%20Doris%20在%20AgentLogsBench%20中领先，支撑%20Agent%20可观测性生产负载/img_6.png)

**Apache Doris 在综合排行榜上以 1.28 倍的成绩领先。**

### 3.3 Hot Query Runtime

![](附件资源/Apache%20Doris%20在%20AgentLogsBench%20中领先，支撑%20Agent%20可观测性生产负载/img_7.png)

**在 hot 场景下，Doris 以 x1.14 领先整体结果，相比 Elasticsearch、OpenSearch 等搜索引擎快约 3 倍，相比 ClickHouse 快约 17 倍。**

原因在于，当工作集被触达后，列式存储、排序键局部性和倒排索引共同降低了查询成本，使 Doris 在混合访问模式下获得稳定性能。

从单查询拆分来看，不同引擎的设计差异非常明显。

- 在 trace 回放场景中 ，Q03 和 Q04 上 Doris 分别为 0.020 秒和 0.036 秒，而 ClickHouse 分别为 2.289 秒和 2.411 秒。Doris 按 HASH(trace_id) 分布，使同一 trace 的所有 observation 位于同一 tablet 中；同时， DUPLICATE KEY(trace_id, observation_id, seq_no) 会在 flush 时完成排序，使过滤落在连续 page 上， ORDER BY seq_no 也能够退化为按存储顺序读取。因此，trace replay 变成顺序读取，而不是跨 tablet 的分散访问。
- 在多短语事故搜索场景中 ，Q13 和 Q15 上 Doris 分别为 0.088 秒和 0.081 秒，Elasticsearch 分别为 1.094 秒和 1.392 秒，ClickHouse 分别为 9.3 秒和 9.5 秒。Doris 在 input 和 output 列上构建倒排索引，并使用适配代码和路径标点的 tokenizer。当索引进入热状态后，基于索引的布尔求值能够显著降低查询成本。
- 在动态 payload 过滤场景中 ，Q16 和 Q17 上 Doris 分别为 0.078 秒和 0.030 秒，Elasticsearch 分别为 0.802 秒和 0.053 秒。Doris 的 VARIANT 类型能够将 payload 子路径提升为列式存储的 subcolumn。一旦 payload.attr.release_ring 等路径成为热路径，谓词只需读取对应列页，而无需逐行解析 JSON 文档。
- 在结构化文本检索场景中 ，Q08 是带短语约束的 rare-tail token-AND 查询。Doris hot 结果为 0.133 秒，Elasticsearch 为 0.452 秒。相比上一版 Benchmark 中 Elasticsearch 领先该查询，Doris 在新版中 cold 与 hot 均取得领先，主要得益于倒排索引交集策略的优化，即优先从稀有 token 开始推进。

### 3.4 Cold Query Runtime

**在 cold 场景下，Doris 以 x1.60 领先，略优于 Elasticsearch 的 x1.65。与上一版 Benchmark 中 Elasticsearch 在 cold 场景下领先幅度更大相比，本轮结果显示 Doris 在整体 cold 负载中已有明显提升。**

![](附件资源/Apache%20Doris%20在%20AgentLogsBench%20中领先，支撑%20Agent%20可观测性生产负载/img_8.png)

具体来看，**长文本短语搜索**在部分查询上仍更有利于 Elasticsearch。例如 Q05 cold 中，Elasticsearch 用时 0.757 秒，Doris 用时 11.3 秒。Elasticsearch 成熟的倒排索引实现在工作集尚未被触达时，对 cold phrase search 仍具备优势。不过，Doris 通过在 trace 回放、动态 payload 过滤和部分文本检索场景中取得更优结果，最终获得整体 cold 排行第一。相关查询仍有进一步优化空间。

**在 trace 回放和动态 payload 过滤场景中**，Doris cold 表现同样较为稳定。Q03 上 Doris 为 0.088 秒，Elasticsearch 为 0.043 秒。Q16 和 Q17 上 Doris 分别为 0.451 秒和 0.142 秒，接近 Elasticsearch 的 0.969 秒和 0.159 秒。

**在 cold rare-tail 文本检索场景中**，Doris 也取得领先。Q08 在上一版中由 Elasticsearch 领先，而本轮结果中 Doris cold 为 0.372 秒，Elasticsearch 为 1.266 秒，反映出 Doris 在倒排索引交集策略上的改进。

### 3.5 单查询拆分

![](附件资源/Apache%20Doris%20在%20AgentLogsBench%20中领先，支撑%20Agent%20可观测性生产负载/img_9.png)

**热力图**展示了每个查询的 cold runtime 和相对时间比例，并按四类访问模式分组。整体来看，

- Doris 在大多数查询中保持较浅颜色，说明其性能表现相对稳定。
- Elasticsearch 在短语搜索场景中表现较好，但在看板刷新和 trace replay 查询上出现更高耗时。
- ClickHouse 整体处于中间水平。
- DuckDB 和 PostgreSQL 在 Q10 以及 Q16 到 Q20 上出现明显性能尖峰，说明其在处理长尾 JSON 查询时存在瓶颈。

04

为什么 Doris 能在 Benchmark 领先

AgentLogsBench 衡量的不是单项能力，而是面向 Agent 可观测性的综合 workload。它通过 20 个查询要求同一张 observation 表同时支持短语搜索、动态字段过滤、trace 回放和实时看板刷新。

结果表明，对于 Agent 可观测性而言，关键不只是某一项能力的极致性能，而是能否在同一套存储模型上同时支撑多种访问模式。Doris 之所以能够领先综合排行榜，是因为**它将短语搜索、动态 JSON 过滤、有序 trace 回放和实时聚合都保留在同一个列式 SQL 引擎中完成**。

**这一结果主要由四项架构能力支撑。**

1) 文本列上的[倒排索引](https://mp.weixin.qq.com/s?__biz=Mzg3Njc2NDAwOA==&mid=2247527198&idx=1&sn=3f1f14dec59c309df2a8f28b5560e592&scene=21#wechat_redirect)让短语搜索由索引驱动。Doris 4.1 中的  `[search()](https://mp.weixin.qq.com/s?__biz=Mzg3Njc2NDAwOA==&mid=2247540167&idx=1&sn=7c6029e639a8fe4ec48326b3f7366199&scene=21#wechat_redirect)` [函数](https://mp.weixin.qq.com/s?__biz=Mzg3Njc2NDAwOA==&mid=2247540167&idx=1&sn=7c6029e639a8fe4ec48326b3f7366199&scene=21#wechat_redirect)能够将布尔逻辑和短语逻辑整合到一个类 Lucene 表达式中，使运维人员可以在一条 SQL 中跨  `input`  和  `output`  搜索多个故障特征。

```
WHERE search(
'input:("timeout awaiting headers" OR "retry budget depleted" OR "transient upstream failure")
OR output:("timeout awaiting headers" OR "retry budget depleted" OR "transient upstream failure")',
'{"mode":"lucene","minimum_should_match":1}'
)
```

2) 带分层子列存储的[VARIANT](https://mp.weixin.qq.com/s?__biz=Mzg3Njc2NDAwOA==&mid=2247538511&idx=1&sn=eae97bf74b188774e8cc54f88e662405&scene=21#wechat_redirect)使动态 JSON 过滤能够以列式速度执行。对于频繁访问的路径，系统可以将其提升为  `typed subcolumn` ；对于长尾属性，则通过稀疏存储降低扫描成本。运维人员无需为了查询新属性执行  `schema migration` 。

```
SELECT
event_time,
trace_id,
observation_id,
type,
status,
CAST(payload['attr']['release_ring'] AS STRING) AS release_ring,
CAST(payload['attr']['customer_tier'] AS STRING) AS customer_tier,
CAST(payload['attr']['traffic_cluster'] AS STRING) AS traffic_cluster
FROM agent_observations
WHERE tenant = ?
AND environment = 'prod'
AND type IN ('GENERATION','TOOL','RETRIEVAL')
AND CAST(payload['attr']['release_ring'] AS STRING) = ?
AND CAST(payload['attr']['customer_tier'] AS STRING) = ?
AND CAST(payload['attr']['traffic_cluster'] AS STRING) = ?
ORDER BY event_time DESC
LIMIT 50;
```

3) 基于  `trace_id`  的 HASH 分布与 DUPLICATE KEY 设计，使 replay 查询可以退化为顺序读取。同一 trace 的 observation 会落在同一 tablet 中，并在 flush 时按  `seq_no`  排序。Q03 hot 仅需 20 ms，原因正是查询读取的是连续 page，而不是分散 block。

```
SELECT
trace_id,
seq_no,
type,
status,
model,
tool_name,
input,
output
FROM agent_observations
WHERE trace_id = ?
ORDER BY seq_no ASC;
```

4) [分区裁剪](https://mp.weixin.qq.com/s?__biz=Mzg3Njc2NDAwOA==&mid=2247538439&idx=1&sn=189264c6c8dca32a7cc911121b2f384b&scene=21#wechat_redirect)、Bloom filter、zone map 和带版本感知的缓存让看板刷新可以扛住并发写入。Condition Cache 会缓存每个过滤条件在每个 segment 上的 bitmap，因此后续刷新可以跳过未变化 segment 上的过滤求值。Query Cache 会缓存 pipeline 结果，并在 ingest 提交新数据之前直接返回，无需再次扫描。

```
SELECT
event_time,
trace_id,
observation_id,
seq_no,
type,
status,
model,
tool_name,
latency_ms
FROM agent_observations
WHERE biz_date BETWEEN ? AND ?
AND tenant = ?
AND type IN ('GENERATION', 'TOOL')
AND status IN ('ok', 'error')
ORDER BY event_time DESC, seq_no DESC
LIMIT 50;
```

05

这对 Agent 可观测平台意味着什么

**Agent 可观测性正在形成一种新的系统需求：同一平台需要同时承担搜索引擎、分析数据库、文档存储和时序分析的能力。**它既要处理大文本短语搜索，也要支持动态 JSON 过滤；既要高效回放 trace，也要在持续写入下刷新实时看板。

从 AgentLogsBench 的结果看，这类能力本质上依赖的是一个**统一的混合负载数据底座**，而不仅仅是单一优化方向。

Apache Doris 在这一类工作负载上展现出较强的综合能力，其优势来自将多种访问路径统一在列式 SQL 引擎内部，并通过 VARIANT、倒排索引、排序键、分区裁剪和缓存机制共同支撑混合负载。

如果你想要以全托管的方式运行 Apache Doris，可以选择 SelectDB（www.selectdb.com），它提供了驱动 benchmark 结果的同一套 VARIANT、倒排索引和缓存能力。

在这一能力之上，如果进一步将其封装为面向 Agent 的可观测与评平台—— Litefuse（litefuse.ai），可以在底层数据能力之上，直接构建 trace 管理、评估体系、查询分析与多租户可观测的一体化平台。

06

一起来测试

AgentLogsBench 的 Benchmark 仓库、查询、schema 和数据生成脚本均已开放，用户可以自行审计并复现测试结果。实时排行榜位于：https://velodb.github.io/agentlogsbench/（复制到浏览器打开）

声明：文中部分配图借助 AI 生成

---
原文链接：https://mp.weixin.qq.com/s?__biz=Mzg3Njc2NDAwOA%3D%3D&mid=2247540831&idx=1&sn=d24b8e5930df1b87673d13006495c3db&chksm=ceeb08abde7c183aa3b20845325159ee1c8bad6ae989e872c52b0aa725449f406c09f91e675f
