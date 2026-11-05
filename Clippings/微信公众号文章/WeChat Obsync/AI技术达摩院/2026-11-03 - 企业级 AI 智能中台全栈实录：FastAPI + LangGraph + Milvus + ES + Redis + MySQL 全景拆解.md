---
source_url: "https://mp.weixin.qq.com/s?__biz=MzY4OTQzMzY0OQ%3D%3D&mid=2247483849&idx=1&sn=a3e2245f50f92dd5080562540bfbebad&chksm=f3d6fc97c4a17581f49d9e17004a86fe2bbad239b85170688a80140839bca73213f051d7274c"
title: "企业级 AI 智能中台全栈实录：FastAPI + LangGraph + Milvus + ES + Redis + MySQL 全景拆解"
account: "AI技术达摩院"
published_at: "2026-11-03 14:01:15"
saved_at: "2026-11-04 18:46:03"
sync_id: "art_49b50ff7a1fb4c56a2cca5f79adefcdb"
parse_status: "ok"
---

# 企业级 AI 智能中台全栈实录：FastAPI + LangGraph + Milvus + ES + Redis + MySQL 全景拆解

> 一套代码，把「RAG 知识问答」「C 端 AI 导购商城」「多租户后台治理」装进同一个中台。这篇文章只讲三件事：全景架构长什么样、每一步选型为什么、踩过的坑值多少学费。所有截图来自项目真实运行界面。

## 写在前面：企业级 AI 中台和玩具 Demo 的分水岭，不在模型，在治理

很多人做完一个 RAG Demo，觉得自己已经「做完了」。

真实差距在哪里？不是模型选得多新、不是向量库用得有多快，而是：有没有网关、有没有鉴权、有没有租户隔离、有没有计量计费、有没有审计、AI 敢不敢碰钱、碰了钱谁负责。

这篇文章要拆的这套「企业级 AI 智能中台」，就是冲着这些缺口去的：Java 管钱、Python 管脑、LangGraph 管流程、MCP 管工具，六个进程 + 六类中间件全部跑通，端到端截图如下。先看整体——它不是一个聊天窗口，而是一套有边界的业务系统。

![](附件资源/企业级%20AI%20智能中台全栈实录：FastAPI%20+%20LangGraph%20+%20Milvus%20+%20ES%20+%20Redis%20+%20MySQL%20全景拆解/img_1.png)

> 一切从「你是谁」开始：C 端会员与员工体系物理隔离，注册即入商城租户。

## 01 全景架构：五层各司其职，谁也别越权

一句话主线：接入层收口，编排层动脑，检索存储层分工，数据层归一，治理层兜底。

```bash
┌────────────────────────────────────────────────────────────┐
│  接入层  Spring Cloud Gateway (:8888)                        │
│  JWT 鉴权 · 白名单/黑名单 · 令牌桶限流 · CORS · SSE 透传       │
└───────────────────────┬────────────────────────────────────┘
                        │ /api/business/**  /api/shop/**  /api/agent/**
        ┌───────────────┴───────────────┐        ┌────────────┴───────────┐
        │ ai-business-service  (:8081)  │  发现  │ ai-intel-platform       │
        │ Spring Boot 4 · Java 21       │◀──────│ (:8001) FastAPI         │
        │ 登录签发 JWT · 知识库/文档 CRUD │  Nacos │ LangGraph 工作流         │
        │ 商城订单两段式 · 配额/计量/审计  │        │ 混合检索 + rerank         │
        │ MCP Server（15 个工具）        │        │ RocketMQ 消费 · SSE 流式   │
        └────────┬──────────────┬──────┘        └─────────┬───────────────┘
                 │ 生产          │                        │ 读写
        ┌────────▼────────┐  ┌──▼─────────────────────────▼──┐
        │ RocketMQ 5.x    │  │ Milvus 向量 · ES 全文          │
        │ 异步文档摄入      │  │ Redis 会话/缓存 · MySQL 元数据  │
        └─────────────────┘  └──────────────────────────────┘
```

三端各管一段：前端只管交互，网关只认三个前缀，业务中台管「人、钱、单」，智能体中台管「脑、知识、流程」。两条核心链路贯穿其中：

链路 A · 异步文档摄入（HTTP 立即返回，重活后台干）

```
前端上传 → 网关 → 业务登记 PENDING + 发 RocketMQ → Python 消费
→ 解析 → 分块 → 向量化 → 写 Milvus + ES → 回写 DONE → 前端轮询见进度
```

大文档上传永远不会把请求拖到超时——这是把「导入」从同步接口里拿出来的原因。

链路 B · 流式知识问答（SSE 逐字输出）

```bash
提问 → 网关 /api/agent/qa/stream → LangGraph：
load_memory → retrieve（Milvus 向量 + ES BM25 → RRF 融合 → rerank）
→ grade（相关性裁判：充分则生成 / 不足则拒答，不臆造）→ save_memory
→ SSE 事件流 refs → delta* → done 原样透传 → 前端逐字渲染 + 引用卡片
```

## 02 技术栈与选型思考：每一个「为什么」都值得说

先给结论表，再讲三个关键决策。

| 层 | 选型 | 为什么是它 |
| --- | --- | --- |
| 编排 | LangGraph | 工作流是一等公民：状态、条件边、分支、循环、Human-in-the-loop 都有标准表达，比手写  `if/else`  编排可维护一个量级 |
| 工具协议 | MCP | 工具即资源：15 个业务工具按会话  `app`  域隔离（商城 8 个 / 企业 7 个），新增工具不用改编排代码 |
| 向量库 | Milvus 2.5 | 生产级向量检索，HNSW/COSINE，支持租户分区与一致性级别 |
| 全文库 | Elasticsearch 8 + IK 分词 | 中文 BM25 的关键： 必须装与 ES 版本严格匹配的 analysis-ik ，否则中文检索退化成单字切分 |
| 混合检索 | Milvus + ES → RRF → rerank | 语义召回 + 关键词召回互补，RRF 只看排名规避「余弦分数和 BM25 分数不可比」的归一化难题 |
| 缓存/状态 | Redis | 会话窗口、语义缓存、分布式锁、网关令牌桶限流、confirmToken 快照 |
| 元数据 | MySQL 8 | 用户/租户/知识库/订单/审计/计量，金额一律「分」整数 |
| 消息 | RocketMQ 5.x | 跨语言（Java remoting 客户端 ↔ Python gRPC 客户端）落到同一 broker，实测两端 msgId 一致 |
| 注册发现 | Nacos | Java 与 Python 双栈共用一套注册中心，网关  `lb://`  按服务名路由 |
| 网关 | Spring Cloud Gateway（WebFlux） | SSE 必须用它 ：响应式网关对  `text/event-stream`  天然透传不缓冲，servlet 网关会卡流 |
| 模型 | qwen-plus / text-embedding-v3 / gte-rerank-v2 | 一套 DashScope 打通 chat / embedding / rerank 三件事 |

决策一：Java 管钱，Python 管脑——双栈不是炫技，是各管各的命。

交易、鉴权、计量、审计这些要「事务 + 强一致 + 审计留痕」的活，交给 Spring Boot；Agent 编排、检索、流式生成这些要「生态迭代快」的活，交给 Python。两边通过Nacos 注册发现 + RocketMQ 消息 + MCP 工具协议 + 网关统一入口四件事解耦。跨语言契约有个硬经验：字段名就是契约——Python 侧 Pydantic 模型刻意用驼峰（kbId/fileName/docId），与 Java record 逐字对齐，少一层命名策略转换，就少一个静默拿到 null 的机会。

决策二：网关是安全的第一道也是唯一一道闸。

白名单之外的路径一律要 JWT，校验通过后网关把 X-Auth-Uid/Tid/Role/App 透传给下游——这些头入站时被剥离，防伪造；/api/business/internal/** 直接黑名单 404，服务间调用只走 Nacos 内网直连。还有两个「影子模式」的灰度技巧（详见 04 代码）：

-  `casbin.enforce=false`  ：授权引擎观察模式，命中的拒绝只记日志不真拦，先看会误伤谁，再打开；
-  `conditional-access.dry-run=true`  ：条件访问（IP/时段/UA 准入）同样影子运行，观察无误再收口。

决策三：LangGraph 把「问答」升级成「流程」。

知识问答的工作流不是一段顺序代码，而是一张图：load_memory → retrieve → grade →（充分）generate /（不足）refuse → save_memory。拒答是独立节点而不是异常分支——资料不足时返回固定话术 refused=true，不编答案。ask() 与 ask_stream() 跑同一张图，区别只在 ainvoke 还是 astream_events，同步/流式一条链路复用。

## 03 全景业务功能：一个中台，两套业务域，四个入口

### 3.1 知识问答中台（中台的原点）

上传文档 → 异步摄入 → 提问带引用作答。向量模型、维度、分块参数都是租户知识库可配置的：

![](附件资源/企业级%20AI%20智能中台全栈实录：FastAPI%20+%20LangGraph%20+%20Milvus%20+%20ES%20+%20Redis%20+%20MySQL%20全景拆解/img_2.png)

> 「AI常见面试题」库：text-embedding-v3、维度 1024、分块 500/80，文档 53 块已索引完成。

问答页右侧是记忆状态、左侧是引用来源——答案带 [n] 脚注，每条引用给相关度，证据链可回溯：

![](附件资源/企业级%20AI%20智能中台全栈实录：FastAPI%20+%20LangGraph%20+%20Milvus%20+%20ES%20+%20Redis%20+%20MySQL%20全景拆解/img_3.png)

> 问「什么是过拟合」，5 条引用、相关度从 86% 到 14% 全部列出来，由相关性裁判把关，答不上来就拒答。

### 3.2 C 端商城：会员体系与员工体系物理隔离

![](附件资源/企业级%20AI%20智能中台全栈实录：FastAPI%20+%20LangGraph%20+%20Milvus%20+%20ES%20+%20Redis%20+%20MySQL%20全景拆解/img_4.png)

> K8 ¥699 / K12 ¥1299 / M3 ¥199 / M7 ¥399 / U2 ¥1599，五件演示商品，搜索 + 分类 + 价格区间筛选。

商城有自己独立的会员体系：shop_user 自增起点 10 亿，数值上不与员工 sys_user 撞号；JWT 带 app 声明（SHOP / CONSOLE），网关按路径拦「主体与资源域不匹配」——会员 token 打企业接口、员工 token 打商城接口，一律 403 且落审计。

### 3.3 AI 导购：最强的一张图

这是整套系统最有产品感的页面——四步问卷、实时查库、预览式下单：

![](附件资源/企业级%20AI%20智能中台全栈实录：FastAPI%20+%20LangGraph%20+%20Milvus%20+%20ES%20+%20Redis%20+%20MySQL%20全景拆解/img_5.png)

![](附件资源/企业级%20AI%20智能中台全栈实录：FastAPI%20+%20LangGraph%20+%20Milvus%20+%20ES%20+%20Redis%20+%20MySQL%20全景拆解/img_6.png)

![](附件资源/企业级%20AI%20智能中台全栈实录：FastAPI%20+%20LangGraph%20+%20Milvus%20+%20ES%20+%20Redis%20+%20MySQL%20全景拆解/img_7.png)

![](附件资源/企业级%20AI%20智能中台全栈实录：FastAPI%20+%20LangGraph%20+%20Milvus%20+%20ES%20+%20Redis%20+%20MySQL%20全景拆解/img_8.png)

![](附件资源/企业级%20AI%20智能中台全栈实录：FastAPI%20+%20LangGraph%20+%20Milvus%20+%20ES%20+%20Redis%20+%20MySQL%20全景拆解/img_9.png)

![](附件资源/企业级%20AI%20智能中台全栈实录：FastAPI%20+%20LangGraph%20+%20Milvus%20+%20ES%20+%20Redis%20+%20MySQL%20全景拆解/img_10.png)

> 四步问卷（品类/场景/预算/偏好）+ AI 值守 + 余额提示 + 右侧「本期五块能力」边界说明。副标题一句话锁死产品边界：「先问清条件，再实时查库；只出预览，付款与确认永远由你完成」。

导购开始对话后，条件槽位逐步收敛，价格库存走工具实时查：

![](附件资源/企业级%20AI%20智能中台全栈实录：FastAPI%20+%20LangGraph%20+%20Milvus%20+%20ES%20+%20Redis%20+%20MySQL%20全景拆解/img_11.png)

> 3/4 条件已确认，AI 调  `get_product_detail`  拿实时价格库存，输出 M3 vs M7 对比表——数据是刚查到的当前值，不是模型背的。

### 3.4 后台治理：数据、订单、租户一个不落

平台超管可以全局下钻租户，看板把 Token 计量与成本折算做到「今日成本 ¥0.0062」这种精度：

![](附件资源/企业级%20AI%20智能中台全栈实录：FastAPI%20+%20LangGraph%20+%20Milvus%20+%20ES%20+%20Redis%20+%20MySQL%20全景拆解/img_12.png)

> 今日 Token / 成本 / 限流 429 / 鉴权拒绝 / 总调用，30 天趋势 + 按场景 Token 分布——AI 花钱花在哪，一笔笔看得见。

订单页能看到真实链路：网页下单和 AI 助手下单同库同表，金额、来源、状态清晰可查：

![](附件资源/企业级%20AI%20智能中台全栈实录：FastAPI%20+%20LangGraph%20+%20Milvus%20+%20ES%20+%20Redis%20+%20MySQL%20全景拆解/img_13.png)

> AI 助手下单 SO2026110300000001 ¥1,197.00——但注意，落单发生在用户点击确认之后，AI 只有 preview。

租户是治理的最小单元，套餐、状态、下钻、禁用，平台超管专属：

![](附件资源/企业级%20AI%20智能中台全栈实录：FastAPI%20+%20LangGraph%20+%20Milvus%20+%20ES%20+%20Redis%20+%20MySQL%20全景拆解/img_14.png)

> 多租户行级隔离 + 套餐配额，后台每一个「仅平台超管可见」的能力都有后端二次拦截。

## 04 项目亮点代码示例：四段最值得抄的代码

### 亮点 1 · 混合检索用 RRF 融合，绕开分数归一化

ai-intel-platform/app/rag/retriever.py

```python
def _rrf_fuse(vec_hits, bm_hits):
    ”””RRF（Reciprocal Rank Fusion）只看排名不看原始分数。
    score(d) = Σ 1/(k + rank)，k 取 60。
    天然规避「余弦相似度和 BM25 分数量纲不可比、需要归一化」的麻烦。”””
    fused = {}
    for rank, h in enumerate(vec_hits + bm_hits, start=1):
        ...
        slot[”rrf”] += 1.0 / (60 + rank)
    return sorted(fused.values(), key=lambda d: d[”rrf”], reverse=True)

async def hybrid_retrieve(query, kb_id, top_k=5, candidate_k=20, tenant_id=None):

# 两路并行召回，互不阻塞；都带 tenant_id，召回严格限定在本租户内
    vec_hits, bm_hits = await asyncio.gather(
        milvus_store.search(vec, kb_id=kb_id, tenant_id=tenant_id, limit=candidate_k),
        es_store.search(query, kb_id=kb_id, tenant_id=tenant_id, limit=candidate_k),
    )
    fused = _rrf_fuse(vec_hits, bm_hits)

# 融合后再交 gte-rerank 精排，rerank 失败优雅降级为 RRF 排序，主链路不断
    ...
```

设计思考：向量分数和 BM25 分数量纲完全不同，直接加权求和是常见的坑。RRF 只比较排名，天然归一化；rerank 再精排一遍，把「候选多召回、精排小池子」（top_k*2）做到延迟可控。

### 亮点 2 · 两段式下单：confirm 只收 token，一个业务参数都不收

ai-business-service/.../shop/dto/ConfirmSnapshot.java（设计注释即架构）：

```cs
/**
 * confirmToken 背后的【服务端参数快照】。
 * confirm 接口只收一个 token：商品、单价、数量、金额一律从这份快照取，
 * 客户端（无论网页还是 AI）在 confirm 阶段【没有任何字段可改】。
 * 快照绑定 uid+tid+actor，A 拿到 B 的 token 也用不了。
 */
```

OrderService.java：

```typescript
public ActionResult confirmCreate(ShopPrincipal p, String confirmToken) {
    String token = trimToken(confirmToken);
    // token 消费（Redis GETDEL）在事务外先做：即使事务回滚令牌也已消费，
    // 绝不会因回滚而能重放同一令牌二次扣款；重复 confirm 读回首次结果（幂等）
}
```

设计思考：一旦 confirm 收参数，就等于「用户点了由 AI 填写的表单」，服务端无法分辨哪个字段被改过。两段式的本质不是「预览再确认」，而是把 AI 的写权限在协议层归零——MCP 只有 5 读 + 3 预览写，confirm 端点从不暴露给 MCP，只有前端 HTTP API 能调。

### 亮点 3 · MCP 工具按会话域分流：商城只会看到商城工具

ai-business-service/.../mcp/ShopMcpTools.java：

```javascript
.tool(McpSchema.Tool.builder(”get_product_detail”, inputSchema)    // 读：实时价格库存
      .withDescription(”查询商品实时价格、库存与描述（实时值，勿凭记忆作答）”)
      .build(), handler)
.tool(McpSchema.Tool.builder(”get_account_balance”, inputSchema)   // 读：余额与流水
      .build(), handler)
.tool(McpSchema.Tool.builder(”preview_create_order”, inputSchema) // 预览写：只算账发 token
      .build(), handler)
// 8 个商城工具 = 5 读 + 3 preview_*（下单/取消/完成预览），
// 不存在任何 create/confirm 执行态工具
```

设计思考：工具集是「会话来源端（app 域）」决定的，商城会话根本看不到企业工具。即使 LLM 完全失控（幻觉/提示词注入），协议层也没有任何路径完成扣款——这是比任何提示词护栏都硬的物理保证。

### 亮点 4 · 网关：一条 yml 把路由、限流、白名单、观察模式写清楚

ai-gateway/src/main/resources/application.yml：

```bash
routes:
  - id: shop-route
    uri: lb://ai-business-service

# Nacos 服务名路由
    predicates: [ Path=/api/shop/** ]
    filters:
      - name: RequestRateLimiter

# Redis 令牌桶：写接口收紧、AI 接口更紧
        args: { redis-rate-limiter.replenishRate: ${GW_RL_SHOP_REPLENISH:10}, ... }
      - RewritePath=/api/shop/(?.*), /shop/$\{segment}

# 精确改写，勿用 StripPrefix

gateway:
  auth:
    whitelist: /api/business/auth/login,...,/api/agent/health

# 之外全要 JWT
    blacklist: /api/business/internal/**

# 内部接口 404 挡死
casbin:
  enforce: ${CASBIN_ENFORCE:false}

# 观察模式：命中拒绝只记日志，先看误伤再收口
```

设计思考：路由用 RewritePath 而不是 StripPrefix——业务后端在 /business/、智能体本就在 /api/，剥的层数不一样，StripPrefix 会把既有路径削错。观察模式（enforce=false）是灰度授权策略的标准动作：先影子运行收集证据，再置 true 强制拦截。

## 05 项目经验：这些坑，换一个环境照样会踩

- Spring Boot 4 默认是 Jackson 3，不是 Jackson 2。 自动装配的是  `tools.jackson.databind.ObjectMapper`  ，按老包名注入直接失败。JWT 库选 nimbus-jose-jwt——它不绑定具体 Jackson 版本，正好避开 2/3 并存问题。
- MyBatis-Plus 要用 boot4 专用 starter ：普通  `mybatis-plus-boot-starter`  跑不了 Spring 7 / Boot 4，必须  `mybatis-plus-spring-boot4-starter`  。
- 网关 starter 改名 + 配置命名空间变了 ：  `spring-cloud-starter-gateway-server-webflux`  ，yml 是  `spring.cloud.gateway.server.webflux.routes`  ，不是老坐标。
- RocketMQ 跨语言是「两条协议、一个 broker」 ：Java 侧 remoting 客户端连 namesrv 9876；Python 侧用  `rocketmq-python-client`  （5.x gRPC）连 proxy，PyPI 包名别装错成 4.x 的  `rocketmq`  。proxy 默认 gRPC 8081 极易撞端口，改  `rmq-proxy.json`  避让即可。
- Milvus 写后有 bounded-consistency 窗口 ：upsert/delete 后立刻 query 可能读到旧值，导入后自检要么等几秒，要么传  `consistency_level="Strong"`  。
- Nacos 空 namespace  `''`  和字面量  `'public'`  是两个不同租户 ：Java 侧留空会自动归一化成  `public`  ，Python 侧老 SDK 原样上线——两侧写法要刻意不对称，排查时别信 SDK 查询结果，看控制台。
- 前端 SSE 用  `fetch + ReadableStream`  ，不用 EventSource ：EventSource 只支持 GET 且不能带 Authorization 头，问答是 POST + JWT，只能手工读流按  `\n\n`  切帧。
- 金额全链路用「分」整数（BIGINT），禁用浮点。 前端「元」转「分」再传，MCP 输出带  `Fen`  后缀——拿小数当金额是必踩的坑。
- 记忆压缩是 LLM 依赖，不是纯算法 ：摘要合并调大模型，一限流压缩就失败。重试→降级→熔断要一套，摘要模型别用 turbo 档（实测持续 429）。

## 06 边界与下一步

这套系统有意识的不做，和做了一样重要：

- 不做多模态导购、主动营销、代客下单 ——分别依赖外部能力、前端埋点与法务口径，能力边界写死在产品方案里；
- 不做生产级高可用 ——单机单副本，面向开发与演示；分布式部署要换共享对象存储（或改走内联文本入口）、加 Sentinel/熔断、Nacos 配置中心；
- 灰度开关留好了 ：Casbin、配额、条件访问、下单限额四组开关默认「影子模式」，验证无误后再逐项打开—— 先观察、后收口 ，这是企业级发布的标准动作。

## 写在最后

回头看，这套中台最值钱的不是哪段代码，而是三句判断：

- AI 进业务系统，先解决「AI 能不能碰钱、碰了谁负责」，再谈模型效果；
- 双栈不是炫技：交易归 Java，智能归 Python，用网关 + 消息 + MCP 把边界焊死；
- 灰度永远先于强制：观察模式跑一阵，再打开闸门。

如果这篇文章让你有「我也想把它跑起来看看」的冲动——这套系统我已经整理成完整的开源代码仓库（含 24 张表的建库脚本、三套前端、评测集与验收脚本）；关注公众号「AI技术达摩院」，回复「智能中台」，我会把最新的部署手册和踩坑清单打包发你。源码不是收藏品，跑起来才算你的。

觉得有用，点个「在看」，让更多正在做 AI 中台的人看到这篇。

---
原文链接：https://mp.weixin.qq.com/s?__biz=MzY4OTQzMzY0OQ%3D%3D&mid=2247483849&idx=1&sn=a3e2245f50f92dd5080562540bfbebad&chksm=f3d6fc97c4a17581f49d9e17004a86fe2bbad239b85170688a80140839bca73213f051d7274c
