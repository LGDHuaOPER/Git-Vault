---
source_url: "https://mp.weixin.qq.com/s?__biz=MzU3Mzg4OTMyNQ%3D%3D&mid=2247516295&idx=1&sn=0cc15558b066c630b0cde8cd0c9e8b2c&chksm=fc99e9165c2d5ab66b5ba3be94335cc10fdffab1514df161d60c269186e2bfb2a39ce9b5044e"
title: "Flink SQL × AI：一条 SQL 实现图文多模态理解与实时多标签打标"
account: "Apache Flink"
published_at: "2026-08-13T10:00:00.000Z"
saved_at: "2026-08-13T10:42:57.187Z"
sync_id: "art_8866d0c7131a4db7aaf2788727916d2b"
parse_status: "ok"
---

# Flink SQL × AI：一条 SQL 实现图文多模态理解与实时多标签打标

![](附件资源/Flink%20SQL%20×%20AI：一条%20SQL%20实现图文多模态理解与实时多标签打标/img_1.png)

内容平台、电商商品库和媒体资产库每天都会产生大量图文内容。一条内容通常同时包含标题、描述和图片：文字擅长表达主题与意图，图片则补充主体、场景和外观。下游的搜索、推荐、内容运营和资产治理，希望拿到的是口径稳定、可以直接消费的业务标签。

但真实内容很少只对应一个语义。比如，文字写着“和朋友一起去海边放松”，图片里还出现了一只宠物狗。这条内容既包含“海边休闲”的场景，也包含“宠物狗”的主体。只看文字会漏掉视觉信息，只看图片又可能忽略文字表达的意图；让大模型直接面对完整标签库自由判断，则容易带来上下文过长、标签口径漂移和推理成本不可控等问题。

本文使用阿里云实时计算 Flink 版搭建一条实时多标签打标链路：先用 Embedding 从预构建的标签向量库中召回少量候选，再让多模态大模型结合原始图文完成最终判断。文本处理、图片读取、模型调用、向量检索和标签输出都在一条持续运行的 Flink SQL 作业中完成。

**01**

两阶段语义打标：先召回，再判断

多标签打标要同时解决“找得到”和“判得准”两个问题。

Embedding 适合承担第一阶段的高召回任务。它把标签描述、事件文本和事件图片映射成向量，通过语义相似度从完整标签体系中快速找出少量候选。这个阶段的目标是缩小范围，而不是直接给出最终结论。

多模态大模型适合承担第二阶段的语义判断任务。模型重新查看原始文字、原始图片和两路召回候选，判断哪些标签真正成立，再输出结构化结果。这样既保留了受控标签体系，也让模型能够处理一条内容同时包含主体、场景和主题的情况。

两阶段设计还有一个直接收益：标签库规模增长时，二阶段模型的上下文不会随之线性增长。新增标签只需要进入向量库，实时链路仍然只把少量候选交给模型判断。

**02**

实时链路：一条事件串联两路召回

本文假定业务已经在 Milvus Collection product_label 中准备好标签名称、业务描述及其 1024 维向量。预构建标签库可以统一标签口径、避免实时重复计算完整标签集合，并让文本路与图片路复用同一份标签资产；标签库的具体构建过程不在本文展开。

![](附件资源/Flink%20SQL%20×%20AI：一条%20SQL%20实现图文多模态理解与实时多标签打标/img_2.png)

每条图文事件依次经过以下链路：

- 使用 AI_EMBED 生成文本向量，并从 product_label 召回 Top-3 标签。
- 使用 FETCH_CONTENT 读取 OSS 图片，在 Flink 内转换为 Base64 Data URL。
- 使用 AI_EMBED 生成图片向量，并从同一份 product_label 再召回 Top-3 标签。
- 将召回结果通过 Python Inline Function 完成输出列裁剪，然后与原始文本和原始图片一并交给多模态模型判断。
- 输出包含标签、排序、判断分和证据的结构化结果。

本文示例使用 Print Connector 直接展示结果。根据业务需要，最终标签也可以写入 Kafka、Paimon、Hologres 等下游。文本向量和图片向量还可以增加独立 Sink 进行持久化，写入 Milvus 或数据湖后继续用于语义检索、相似内容发现、去重和离线分析；当前示例直接使用这些向量完成标签召回，没有增加这条输出支路。

本文使用的主要服务如下：

| 服务或能力 | 在链路中的作用 |
| --- | --- |
| ** 阿里云实时计算 Flink 版 ** https://www.aliyun.com/product/bigdata/sc | 串联数据接入、图片读取、模型调用、向量检索与结果输出 |
| ** Flink AI 服务 ** https://help.aliyun.com/zh/flink/realtime-flink/flink-ai-service | 提供托管的 qwen3-vl-embedding 和 qwen3.6-plus 模型调用能力 |
| ** Milvus ** https://help.aliyun.com/zh/milvus/ | 保存预构建的标签向量，并为两路实时查询提供向量检索 |
| ** Flink SQL AI 与多模态函数 ** https://help.aliyun.com/zh/flink/realtime-flink/ml-predict | 通过 AI_EMBED 、 VECTOR_SEARCH_AGG 、 ML_PREDICT 、 FETCH_CONTENT 和 Python Inline Function 表达整条链路 |

本文示例按 VVR 11.9 Preview 2 编写，当前方案仍保留文本和图片两条单模态召回路。后续将提供图文融合 Embedding 能力，可以按业务需要增加融合召回。

**03**

跨模态对齐：文本与图片共享标签库

本文的标签描述、事件文本和事件图片都使用同一个 qwen3-vl-embedding 多模态向量模型，向量维度统一为 1024。该模型支持跨模态语义对齐，可以把文本和图片映射到同一语义空间。因此，文本向量和图片向量虽然来自不同输入，却都可以与标签描述向量计算语义相似度。

这意味着两条召回路不需要分别维护“文本标签库”和“图片标签库”。一份标签定义、一列向量和一套版本即可同时支持文搜标签与图搜标签，也避免了两套索引更新不同步的问题。Milvus Collection 的索引和实时查询都使用 COSINE，保证相似度口径一致。

实时召回使用 VECTOR_SEARCH_AGG。它会把 Top-K 结果以数组形式附加在当前事件上，因此每条事件在召回前后仍然是一条记录：

-
-
-
-
-
-
-
-

```
LATERAL TABLE(  VECTOR_SEARCH_AGG(    SEARCH_TABLE => TABLE product_label,    COLUMN_TO_SEARCH => DESCRIPTOR(embedding),    COLUMN_TO_QUERY => e.text_embedding,    TOP_K => 3  )) AS r
```

图片路使用相同写法，只把查询向量替换为 image_embedding。两路分别召回，可以保留“文字触发了哪些标签、画面触发了哪些标签”的信息，也便于分别评估文本和图片的 Recall@K。

VECTOR_SEARCH_AGG 的候选包含向量表的所有字段以及一个额外的 score 字段，但二阶段模型只需要其中的标签 ID、名称和业务描述，本文使用 VVR 11.9 Preview 1 新增的 Python Inline Function 直接将任意 Top-K 结果统一转换为精简 JSON。

**04**

顺序处理：对齐文本与图片的处理节奏

文本 Embedding 通常比图片下载和图片推理更轻。如果把文本路和图片路拆成两条独立流，再按事件 ID 汇合，就需要额外处理两路速度差、状态保留时间和 Join 完整性。

本文采用顺序链路：文本召回完成后，处理结果仍附着在当前事件上；随后才读取图片、生成图片向量并完成第二次召回。因为没有把一条事件拆成两条独立数据流，所以不需要窗口或 Join 来等待两路结果，速度差也不会造成事件错配。

图片存放在受限 OSS 地址时，模型服务无法直接访问原始 URL。Flink 先使用 FETCH_CONTENT 读取图片，再结合 MIME_TYPE 和 TO_BASE64 构造模型可接收的 Data URL：

-
-
-
-
-
-

```
CONCAT(  'data:',  MIME_TYPE(image_url),  ';base64,',  TO_BASE64(FETCH_CONTENT(image_url))) AS image_input
```

这份 image_input 会同时提供给图片 Embedding 模型和二阶段多模态模型。图片只读取和编码一次，图片链路也被放在文本召回之后，减少大对象过早进入处理链所带来的传输开销。

**05**

多模态二阶段判断：从候选到最终标签

第一阶段返回的是语义相似候选，并不是最终业务标签。相似度只能说明“内容与标签定义接近”，不能替代对完整图文语境的判断。

二阶段模型 qwen3.6-plus 会同时接收四类输入：原始文本、文本召回候选、图片召回候选和原始图片。标签描述为模型提供业务定义，原始图文提供判断证据。模型由此可以处理三类常见情况：文字和图片共同支持同一标签；某个标签只由其中一种模态触发；召回候选虽然相似，但结合完整内容后并不成立。

模型调用通过 ML_PREDICT 完成，四列的内容类型在模型 DDL 中统一声明为 text;text;text;image_url：

-
-
-
-
-
-
-
-
-
-
-
-
-
-
-

```
SELECT  event_id,  content AS judge_responseFROM TABLE(  ML_PREDICT(    TABLE judge_input,    MODEL label_judge_model,    DESCRIPTOR(      text_content,      text_candidates_json,      image_candidates_json,      image_input    )  ));
```

提示词统一配置在模型 DDL 上，数据 SQL 只负责传递字段。最终结果以 JSON 返回，包含标签 ID、标签名称、排序、judge_score 和简短证据，可以直接交给下游系统消费。

**06**

三类样例验证图文语义互补

示例标签数据库准备了 8 个标签，如图所示：

![](附件资源/Flink%20SQL%20×%20AI：一条%20SQL%20实现图文多模态理解与实时多标签打标/img_3.png)

示例作业使用 VALUES 准备了 3 条图文事件，覆盖三类典型输入：

| 输入 | 重点验证的问题 |
| --- | --- |
| 海边文字 + 人与狗的沙滩图片 | 图片能否补充文字未提及的主体 |
| 模糊代词文字 + 老虎图片 | 图片能否完成主体消歧 |
| 慢跑文字 + 运动鞋图片 | 两种模态能否相互验证 |

示例作业使用 Print Sink，运行后可以直接在作业日志中查看每个事件对应的最终标签。每条输入事件及结果如下图所示：

![](附件资源/Flink%20SQL%20×%20AI：一条%20SQL%20实现图文多模态理解与实时多标签打标/img_4.png)

**07**

总结

这条链路的关键不在于简单叠加多个模型，而在于明确各阶段职责：预构建标签库提供稳定的标签边界，Embedding 负责从完整标签体系中快速召回候选，多模态模型负责结合原始图文做最终判断，Flink 则把数据接入、图片读取、模型调用、向量检索和结果输出串成一条持续运行的实时流水线。

文本和图片分别生成向量，却可以查询同一份标签索引；两路处理顺序附着在同一事件上，不需要额外的流对齐；生成的事件向量既能服务当前标签召回，也可以持久化为后续检索和分析的数据资产。对于需要稳定标签体系和实时图文理解的业务，这种“先召回、再判断”的设计在效果、治理和工程复杂度之间取得了更好的平衡。

**08**

参考资料

· 阿里云实时计算 Flink 版

https://www.aliyun.com/product/bigdata/sc

· Flink AI 服务（内置模型）

https://help.aliyun.com/zh/flink/realtime-flink/flink-ai-service

· 模型设置

https://help.aliyun.com/zh/flink/realtime-flink/model-ddl

· AI_EMBED

https://help.aliyun.com/zh/flink/realtime-flink/ai-embed

· ML_PREDICT

https://help.aliyun.com/zh/flink/realtime-flink/ml-predict

· qwen3-vl-embedding

https://help.aliyun.com/zh/model-studio/qwen3-vl-embedding

· VECTOR_SEARCH_AGG

https://help.aliyun.com/zh/flink/realtime-flink/vector-search-agg

· Milvus Connector

https://help.aliyun.com/zh/flink/realtime-flink/developer-reference/milvus-connector-public-preview

**09**

附录

以下为完整示例作业（VVR 11.9 Preview 2），共 15 个步骤：

-
-
-
-
-
-
-
-
-
-
-
-
-
-
-
-
-
-
-
-
-
-
-
-
-
-
-
-
-
-
-
-
-
-
-
-
-
-
-
-
-
-
-
-
-
-
-
-
-
-
-
-
-
-
-
-
-
-
-
-
-
-
-
-
-
-
-
-
-
-
-
-
-
-
-
-
-
-
-
-
-
-
-
-
-
-
-
-
-
-
-
-
-
-
-
-
-
-
-
-
-
-
-
-
-
-
-
-
-
-
-
-
-
-
-
-
-
-
-
-
-
-
-
-
-
-
-
-
-
-
-
-
-
-
-
-
-
-
-
-
-
-
-
-
-
-
-
-
-
-
-
-
-
-
-
-
-
-
-
-
-
-
-
-
-
-
-
-
-
-
-
-
-
-
-
-
-
-
-
-
-
-
-
-
-
-
-
-
-
-
-
-
-
-
-
-
-
-
-
-
-
-
-
-
-
-
-
-
-
-
-
-
-
-
-
-
-
-
-
-
-
-
-
-
-
-
-
-
-
-
-
-
-
-
-
-
-
-
-
-
-
-
-
-
-
-
-
-
-
-
-
-
-
-
-
-
-
-
-
-
-
-
-
-
-
-
-
-
-
-
-
-
-
-
-
-
-
-
-
-
-
-
-
-
-
-
-
-
-
-
-
-
-
-
-
-
-
-
-
-

```
-- VVR 11.9 Preview 2 实时图文多标签打标作业。---- 主链路：文本召回 -> 图片读取与召回 -> 多模态二阶段判断 -> Print。-- 文本和图片分别使用 qwen3-vl-embedding，并查询同一个 Milvus 标签库。 -- 步骤 1：注册文本 Embedding 模型。CREATE TEMPORARY MODEL text_embedding_modelINPUT (  model_input STRING)OUTPUT (  embedding ARRAY)WITH (  'provider' = 'dashscope',  'task' = 'multimodal-embedding',  'model' = 'qwen3-vl-embedding',  'dimension' = '1024',  'content-type' = 'text'); -- 步骤 2：注册图片 Embedding 模型。-- 输入为 Flink 读取 OSS 图片后构造的 Base64 Data URL。CREATE TEMPORARY MODEL image_embedding_modelINPUT (  model_input STRING)OUTPUT (  embedding ARRAY)WITH (  'provider' = 'dashscope',  'task' = 'multimodal-embedding',  'model' = 'qwen3-vl-embedding',  'dimension' = '1024',  'content-type' = 'image_url'); -- 步骤 3：注册二阶段多模态判断模型。-- 四列输入依次为：原始文本、文本候选、图片候选、原始图片。CREATE TEMPORARY MODEL label_judge_modelINPUT (  text_content STRING,  text_candidates_json STRING,  image_candidates_json STRING,  image_input STRING)OUTPUT (  content STRING)WITH (  'provider' = 'dashscope',  'task' = 'chat/completions',  'model' = 'qwen3.6-plus',  'content-types' = 'text;text;text;image_url',  -- 较低温度让结构化分类结果更稳定；可结合评测集调整。  'temperature' = '0.1',  -- 覆盖少量标签 JSON，并限制单次输出成本。  'max-tokens' = '512',  'response-format' = 'json_object',  'system-prompt' = '你是受控多标签分类器。你将按顺序收到四段输入：第一段是原始文本，第二段是文本向量召回候选 JSON 数组，第三段是图片向量召回候选 JSON 数组，第四段是原始图片。每个候选只包含 id、name 和 description。description 是标签的业务定义，你必须结合它与原始图文判断标签是否成立。你只能从两个候选数组中出现的 id 选择标签，输出时将 id 写入 label_id、name 写入 label_name；同一 id 被两路召回时只输出一次；每个标签必须独立成立，不要为了凑数输出；最多输出 2 个，按 judge_score 从高到低排序并给出从 1 开始的连续 rank；没有合适标签时输出空数组。仅返回 JSON 对象，格式为 {"labels":[{"label_id":"...","label_name":"...","rank":1,"judge_score":0.0,"evidence":"不超过20字"}]}。judge_score 是模型判断分，不是校准后的概率。'); -- 步骤 4：准备三条有界图文事件。-- 生产环境可以替换为 Kafka、OSS CDC 或其他流式 Source，后续链路保持不变。CREATE TEMPORARY VIEW multimodal_event_source ASSELECT  CAST(event_id AS STRING) AS event_id,  CAST(text_content AS STRING) AS text_content,  CAST(image_url AS STRING) AS image_url,  event_timeFROM (  VALUES    (      'sample-001',      '和朋友一起去海边放松，度过一个悠闲的下午。',      'oss://*/dog_and_girl.jpeg',      TIMESTAMP '2026-08-04 14:00:01.000'    ),    (      'sample-002',      '它在林间安静地注视着镜头。',      'oss://*/tiger.png',      TIMESTAMP '2026-08-04 14:00:02.000'    ),    (      'sample-003',      '轻量透气，适合日常慢跑和通勤。',      'oss://*/shoes.jpeg',      TIMESTAMP '2026-08-04 14:00:03.000'    )) AS sample_events(event_id, text_content, image_url, event_time); -- 步骤 5：声明用于实时检索的 Milvus 标签表。CREATE TEMPORARY TABLE product_label (  id STRING,  embedding ARRAY,  name STRING,  description STRING,  PRIMARY KEY (id) NOT ENFORCED)WITH (  'connector' = 'milvus',  'endpoint' = '...',  'port' = '19530',  'userName' = '...',  'password' = '...',  'databaseName' = 'default',  'collectionName' = 'product_label',  'search.metric' = 'COSINE'); -- 步骤 6：注册召回结果裁剪函数。-- VECTOR_SEARCH_AGG 的每个候选包含 product_label 的全部声明字段，并在-- 末尾追加 score DOUBLE。函数只输出二阶段模型需要的 id、name 和-- description，并直接序列化为紧凑 JSON；调整 Top-K 时无需修改函数。CREATE TEMPORARY FUNCTION PROJECT_RECALL_CANDIDATES(  candidates ARRAY,    name STRING,    description STRING,    score DOUBLE  >>)RETURNS STRINGAS $$import json if candidates is None:    return '[]' return json.dumps(    [        {            'id': candidate.id,            'name': candidate.name,            'description': candidate.description        }        for candidate in candidates        if candidate is not None    ],    ensure_ascii=False,    separators=(',', ':'))$$ LANGUAGE PYTHON; -- 步骤 7：声明结果表。生产环境可替换为实际业务 Sink。CREATE TEMPORARY TABLE final_label_sink (  result_json STRING)WITH (  'connector' = 'print'); -- 步骤 8：生成文本向量。-- text_embedding 是普通 ARRAY 列；若需要复用，可另接向量 Sink 持久化。CREATE TEMPORARY VIEW text_embedded_events ASSELECT  e.event_id,  e.text_content,  e.image_url,  e.event_time,  a.embedding AS text_embeddingFROM multimodal_event_source AS e,LATERAL TABLE(  AI_EMBED(    MODEL => MODEL text_embedding_model,    INPUT => e.text_content,    DIMENSION => 1024  )) AS a; -- 步骤 9：使用文本向量从标签库召回 Top-3。-- VECTOR_SEARCH_AGG 将候选数组附加到当前事件，不需要额外窗口聚合。CREATE TEMPORARY VIEW text_recalled_events ASSELECT  e.event_id,  e.text_content,  e.image_url,  e.event_time,  r.search_results AS text_candidatesFROM text_embedded_events AS e,LATERAL TABLE(  VECTOR_SEARCH_AGG(    SEARCH_TABLE => TABLE product_label,    COLUMN_TO_SEARCH => DESCRIPTOR(embedding),    COLUMN_TO_QUERY => e.text_embedding,    TOP_K => 3  )) AS r; -- 步骤 10：文本召回后再读取图片，并直接构造 Base64 Data URL。-- image_input 同时提供给图片 Embedding 和二阶段模型，避免重复读取。CREATE TEMPORARY VIEW image_ready_events ASSELECT  event_id,  text_content,  image_url,  event_time,  text_candidates,  CONCAT(    'data:',    MIME_TYPE(image_url),    ';base64,',    TO_BASE64(FETCH_CONTENT(image_url))  ) AS image_inputFROM text_recalled_events; -- 步骤 11：生成图片向量。-- image_embedding 也可以通过独立 Sink 写入 Milvus 或数据湖；示例不增加该支路。CREATE TEMPORARY VIEW image_embedded_events ASSELECT  e.event_id,  e.text_content,  e.image_url,  e.event_time,  e.text_candidates,  e.image_input,  a.embedding AS image_embeddingFROM image_ready_events AS e,LATERAL TABLE(  AI_EMBED(    MODEL => MODEL image_embedding_model,    INPUT => e.image_input,    DIMENSION => 1024  )) AS a; -- 步骤 12：使用图片向量从同一标签库召回 Top-3。CREATE TEMPORARY VIEW recalled_events ASSELECT  e.event_id,  e.text_content,  e.image_url,  e.event_time,  e.text_candidates,  e.image_input,  r.search_results AS image_candidatesFROM image_embedded_events AS e,LATERAL TABLE(  VECTOR_SEARCH_AGG(    SEARCH_TABLE => TABLE product_label,    COLUMN_TO_SEARCH => DESCRIPTOR(embedding),    COLUMN_TO_QUERY => e.image_embedding,    TOP_K => 3  )) AS r; -- 步骤 13：构造二阶段模型输入。-- Inline Function 将两路候选数组转成只包含标签业务字段的 JSON，-- embedding 和召回 score 都不会进入二阶段模型。CREATE TEMPORARY VIEW judge_input ASSELECT  event_id,  text_content,  image_url,  event_time,  image_input,  PROJECT_RECALL_CANDIDATES(text_candidates) AS text_candidates_json,  PROJECT_RECALL_CANDIDATES(image_candidates) AS image_candidates_jsonFROM recalled_events; -- 步骤 14：调用多模态模型完成二阶段判断。CREATE TEMPORARY VIEW judged_events ASSELECT  event_id,  text_content,  image_url,  event_time,  content AS judge_responseFROM TABLE(  ML_PREDICT(    TABLE judge_input,    MODEL label_judge_model,    DESCRIPTOR(      text_content,      text_candidates_json,      image_candidates_json,      image_input    )  )); -- 步骤 15：提取 labels，并向 Print Sink 输出结构化 JSON。INSERT INTO final_label_sinkSELECT  CONCAT(    '{"event_id":', JSON_STRING(event_id),    ',"event_time":', JSON_STRING(CAST(event_time AS STRING)),    ',"text_content":', JSON_STRING(text_content),    ',"image_url":', JSON_STRING(image_url),    ',"labels":', JSON_QUERY(      judge_response,      'lax $.labels' EMPTY ARRAY ON EMPTY EMPTY ARRAY ON ERROR    ),    ',"judge_model":"qwen3.6-plus"',    '}'  ) AS result_jsonFROM judged_events;
```

![图片](附件资源/Flink%20SQL%20×%20AI：一条%20SQL%20实现图文多模态理解与实时多标签打标/img_5.webp)

▼ 「**Flink AI 训练营**」 ▼

面对海量电商评论，难以直接指导电商商品运营。**本期 Flink 实训教你实时对评论进行话题分类，自动打标评论中的关注点， 实现高性能实时数据分析与处理！**

使用 Flink AI 参照教程完成实操，根据任务完成进度即有机会获得 **F****link 定制洗漱包**等奖品！

点击查看详情[【Flink AI训练营】基于Flink对电商评论AI实时分类与情感分析](https://mp.weixin.qq.com/s?__biz=MzU3Mzg4OTMyNQ==&mid=2247516020&idx=1&sn=784a8e6da922b7b127306188487b9f26&scene=21#wechat_redirect)

![图片](附件资源/Flink%20SQL%20×%20AI：一条%20SQL%20实现图文多模态理解与实时多标签打标/img_6.webp)

- ### 作业提交链接： https://survey.aliyun.com/apps/zhiliao/2lBuSMpa_
- ### 实操文档链接 ： https://alidocs.dingtalk.com/i/nodes/EpGBa2Lm8aZxe5myCw0ajxqaWgN7R35y

| ![图片](附件资源/Flink%20SQL%20×%20AI：一条%20SQL%20实现图文多模态理解与实时多标签打标/img_7.webp) **（扫码查看文档）** | ![图片](附件资源/Flink%20SQL%20×%20AI：一条%20SQL%20实现图文多模态理解与实时多标签打标/img_8.webp) **（加入钉钉共学群）** |
| --- | --- |

▼ 「**实时计算 Flink 版**」 ▼

复制下方链接或者扫描左边二维码

即可免费试用阿里云 **Serverless Flink**，体验新一代实时计算平台的强大能力！

了解试用详情：https://free.aliyun.com/?productCode=sc

![图片](附件资源/Flink%20SQL%20×%20AI：一条%20SQL%20实现图文多模态理解与实时多标签打标/img_9.webp)

▼ 关注「**Apache Flink**」 ▼

回复 FFA 2026 获取大会资料

![图片](附件资源/Flink%20SQL%20×%20AI：一条%20SQL%20实现图文多模态理解与实时多标签打标/img_10.webp)

![图片](附件资源/Flink%20SQL%20×%20AI：一条%20SQL%20实现图文多模态理解与实时多标签打标/img_11.gif)

**  ****点击「阅****读****原文****」****跳转****阿里云实时计算 Flink～**

预览时标签不可点

---
原文链接：https://mp.weixin.qq.com/s?__biz=MzU3Mzg4OTMyNQ%3D%3D&mid=2247516295&idx=1&sn=0cc15558b066c630b0cde8cd0c9e8b2c&chksm=fc99e9165c2d5ab66b5ba3be94335cc10fdffab1514df161d60c269186e2bfb2a39ce9b5044e
