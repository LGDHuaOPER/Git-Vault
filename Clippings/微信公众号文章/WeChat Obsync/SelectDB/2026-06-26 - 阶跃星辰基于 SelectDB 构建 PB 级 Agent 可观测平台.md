---
source_url: "https://mp.weixin.qq.com/s?search_click_id=10944039153882374254-1784128355350-6561968838&__biz=Mzg3Njc2NDAwOA==&mid=2247540754&idx=1&sn=a21575976363e986acde83999f7034c4&chksm=cee584a23c1934bc76052891366847e274ce77e448e947241fc9be8c27fd0db0e47bf6b88eba&subscene=0&scene=7&clicktime=1784128355&enterid=1784128355&ascene=65&devicetype=iOS26.5.2&version=18004b3c&nettype=WIFI&abtest_cookie=AAACAA==&lang=zh_CN&countrycode=CN&fontScale=100&exportkey=n_ChQIAhIQAhVTs8f3Zes1Kp4d5nyufBLhAQIE97dBBAEAAAAAAAl0EF1/i8oAAAAOpnltbLcz9gKNyK89dVj0dHpPwyOLHNkfhUuKh1eW9oDIuB0hmcP4N0IeoaXi69OHRsPTCm/Nels1TchfT/qXHd7DVrHFRG0DnHNhVeCGPKzVbjba6c8LmXrxzojuCBm/GW3YYHK1kSnWdePVfeYOp/bSVrgJ9oOFA0LI2GpNvBb37MvLGsEfd5JoQBfwwrq9tUourfZnpghiFKJ5labvb6f/zyW4CEAC3hFMAKZ8CW7aRzyhSGinhGonw0iiI9krKVphj/8JI2sejw==&pass_ticket=Reuddn0FmXxD5eY0gSo7aEMh/rKfmLIl3tk7ya9qaR8F1Fzu0GCFV4aE87CyY4JO&wx_header=3"
title: "阶跃星辰基于 SelectDB 构建 PB 级 Agent 可观测平台"
account: "SelectDB"
published_at: "2026-06-26T08:50:00.000Z"
saved_at: "2026-07-15T15:12:42.515Z"
sync_id: "art_037c3a6e321f48d3bd11aa7c15952880"
parse_status: "ok"
---

# 阶跃星辰基于 SelectDB 构建 PB 级 Agent 可观测平台

![](附件资源/阶跃星辰基于%20SelectDB%20构建%20PB%20级%20Agent%20可观测平台/img_1.png)

**导读：****在[SelectDB AI 产品发布会](https://mp.weixin.qq.com/s?__biz=Mzg3Njc2NDAwOA==&mid=2247540674&idx=1&sn=2f7dc0d4800460f440060741779faa56&scene=21#wechat_redirect)上，阶跃星辰可观测性专家 Ric 分享了 Agent 不确定性带来的可观测性挑战，为什么选择 SelectDB 作为 Agent 可观测平台 StepTrace 的数据底座，获得 Agent Trace 实时写入、全文检索、成本和延迟分析等方面的优势，并在 SWE-Agent 代码评测与智能座舱两个真实场景中落地。**

![](附件资源/阶跃星辰基于%20SelectDB%20构建%20PB%20级%20Agent%20可观测平台/img_2.png)

大家好，我是 Ric，目前在阶跃星辰负责可观测性系统的建设，这次我将给大家介绍围绕 SelectDB 构建 Agent 可观测相关的能力。

01

Agent 可观测的挑战

我们先来看 Agent 时代给可观测性带来的哪些挑战？我认为最本质的变化是**观测对象从原来的确定性的程序变成了一个概率行为的系统**，整套系统的不确定性大大增加。

我们举一个简单的例子，在传统的微服务的场景下，我们排查问题很多时候查到几条日志，结合我们自己对代码和对系统本身的理解，其实就可以有效定位到问题。这个过程它的排障决策树，其实是体现在代码和系统架构中的。

![](附件资源/阶跃星辰基于%20SelectDB%20构建%20PB%20级%20Agent%20可观测平台/img_3.jpg)

但是在 Agent 场景下，我们每一步的决策的过程，每步决策的结果，都没有办法收敛成一个确定的流程。怎么去观测这么一个不确定性的过程，就成了一个很重要的话题。对于作为我们 AI 时代的这种原生的应用 Agent， 我们需要围绕它去构建 Agent Trace 系统来分析他的动态执行过程，构建这个系统的过程中，**我们觉得应该去思考这 6 个部分的能力**。

![](附件资源/阶跃星辰基于%20SelectDB%20构建%20PB%20级%20Agent%20可观测平台/img_4.jpg)

第一个是**数据模型层面**，Agent Trace 有一些 Agent 特有的属性，比如说 prompt 和 reasoning 以及 toolcall 这些，都是在设计之初就应该考虑进去的。

第二个是 **session 级别的分析**，用户使用 Agent 的时候，往往是多轮对话才能够达成目标，那么这种会话级别的还原和复盘分析就成为一个很重要的一个能力。

第三个是**成本层面的分析**，因为 Agent 自身每一步的 token 消耗都需要体现在 trace 中，所以 trace 它从一开始就要为这种成本统计、成本治理来提供支持。

第四个是 **Trace 检索**，包括用户、标签、环境等元数据检索，也包括输入输出中的文本检索，这些对于找到待分析的 Trace 是很关键的。

第五个是**评测闭环**，Agent trace 必须具备可分析、可回放的能力，能够为 Agent 的持续迭代优化提供测试数据或者是样本集。

最后第六个是**与基础设施层面的关联**，Agent 的效果一方面是由模型和 harness 来决定，另一方面 Infra 在这个过程中也扮演了很重要的角色，影响到 Agent 的效果。业务的一次 Agent 调用中，我们希望 trace  能够关联到我们底层的基础设施，无论是沙箱还是 KV Cache 还是调度。

**上面这些能力的要求，对支撑 Agent Trace 的数据底座也提出了新的挑战。**

一方面，** 需要复杂数据的实时存储和查询能力**，其中很多字段天然是是高基数的，还有很多灵活的半结构化 JSON 数据，对元数据检索、文本检索和点查的要求很高，数据的写入还必须实时可见。 另一方面，**需要很强的实时数据分析能力**。因为我们前面介绍了， AgentOps 是一个 EDD 驱动的流程，它天生就需要对数据回流做评估和多个维度的分析，来帮助他自己来提升效果。

![](附件资源/阶跃星辰基于%20SelectDB%20构建%20PB%20级%20Agent%20可观测平台/img_5.jpg)

**那基于上面两个特点，我觉得 Agent Trace 的数据底座应该有下面四个要求。**

第一个是**能够支撑这种宽表的建模**，比如说很多 Trace 属性能够在宽表建模和分析。

第二个是**灵活的检索**，除了 trace id 的这种点查之外，同时也要支持关键字的全文检索，以及 metadata 嵌套 JSON 的检索。

第三个是**多维指标的聚合**，从 trace 这张底表要能够支持各种灵活的 rollup。比如说可以聚合出成功率、质量或 token 成本这种多维的派生数据。

第四个是**混合负载的治理**，离在线一体的查询也需要这个数据底座来支撑，怎么去隔离和管理这些不同场景查询的负载，也是一个重要的话题。

02

为什么选择 SelectDB

应对上面的一些能力，我们觉得 SelectDB（基于Apache Doris 内核构建）其实提供了这些非常优秀的特性，来支撑这些需求。

- VARIANT 类型 ，能够很好地支撑 JSON 半结构化数据。在写入时自动识别 JSON 数据中的字段名和类型，将它们拆分成子列，采用列式存储，提升存储压缩率和查询性能。
- 倒排索引 ，能够支持这种高效的点查以及关键词的过滤。SelectDB 早在 2023 年开始支持了倒排索引，被很多公司大规模应用，经过了多年 PB 级生产环境的打磨和验证成熟。
- 异步物化视图提供了一种灵活、轻量的 rollup 能力 ，能够让我们去做这种多维度的聚合，以及透明改写。
- Stream Load 实时导入能力 ，它能够很好的去承接大批量数据写入的吞吐，我们在实践过程中 ， Stream Load p99 延迟在 1s 以内 ， 一次请求甚至可以达到 500MB 的大批次 。Workload group 能够让我们隔离开在线和离线的负载。
- SelectDB 的它这种 FE BE 元数据和数据分离的架构 ，扩展会更灵活，而且运维成本是大大的降低了，这也是我们选择 SelectDB 一个很重要的点，扩容、升级等操作非常方便，不用像 Clickhouse 手动搬迁数据。

![](附件资源/阶跃星辰基于%20SelectDB%20构建%20PB%20级%20Agent%20可观测平台/img_6.jpg)

03

基于 SelectDB 的 StepTrace 落地实践

介绍了 SelectDB 在 Agent Trace 这个场景下的一些优点之后，我们介绍一下 Agent Trace 系统 StepTrace 在阶跃星辰的实践。

![](附件资源/阶跃星辰基于%20SelectDB%20构建%20PB%20级%20Agent%20可观测平台/img_7.jpg)

StepTrace 这套系统在传输的协议上兼容 Langfuse, Litefuse 和 OpenTelemetry 协议，在 trace 上下文中，我们用 W3C 的协议，复用了 OpenTelemetry 的 grpc、collector 等技术栈。

数据采集后通过 Stream Load 写入 SelectDB，**可以 GB/s 高吞吐写入的负载下达到秒级实时可见的效果**。

写入之后，我们去会通过一些物化视图来实现预聚合和预计算。比如说 token 整条，因为我们每个 span 或者是 Agent 的每一步上，它其实都有一些产生一些 token 的消耗，那我们最后计算的是某一个 trace 或者是某一个会话它的 token 具体消耗了多少，那这个时候需要很多的这种预预计算的能力，通过物化视图来实现。

SWE-Agent

SWE-Agent 是 step trace 的一个重要的应用。SWE Bench 是一个 coding 能力的一个重要评测集，我们通过对 SWE Agent 做 SDK 埋点，来实现各个环节的观测，比如说镜像拉取、沙盒创建、沙盒执行、多轮模型调用，以及工具调用，来保障 SWE Agent 的稳定性。 **通过 SWE-Agent 的 trace  能清楚的看到 rollup 这个链路上有哪些环节，在 evaluation 的评测链路上有哪些环节**。传统的算法工程师工作模式，往往是通过日志，或者是通过一些轨迹文件，没有这种统一的高性能的存储，限制了很多分析，比如 Agent 多版本的横向比较，以及时序上的性能变化，及成功率等高级分析，现在在 StepTrace 上都能够统一的去支持。

![](附件资源/阶跃星辰基于%20SelectDB%20构建%20PB%20级%20Agent%20可观测平台/img_8.jpg)

智能座仓 Agent

另一个案例是座舱 Agent，智能座舱是当前比较前沿的一个产品，得益于端侧算力的提升和车机 OTA， 以及云端协同的能力，现在很多先进的座舱也开始引入了 Agent，提高汽车的驾乘体验，同时也带来了安全、成本等方面的挑战。

座舱 Agent 的观测，是它能够高效、安全、稳定运转的一个基石，尤其是安全。座舱 Agent 肯定对这个安全做了很多的约束，这些约束的生效情况到底如何？在测试场景下，它的闭环率到底如何？其实都是 Agent 可观测要服务的重点。

这个智能座舱场景下，很多用户的输入往往是一些零散的语音片段，意图在最开始可能是相对发散的，经过多轮对话之后才会体现出最终目的。这就导致获得最后结果的时候，不确定性很高。**要保证 Agent 的效果，就必须通过这种 trace 的方法去观测链路的每一次推理过程，然后来分析为什么我们没有得到用户预期的结果，再去针对性提升它的效果。**

在此之上还需要构建一个优秀的评测集，能够让 Agent 在替换新模型或者更新新架构的时候，进行量化效果评估，确保用户真的能感受到优化，而不是只是一个我们一个拍脑袋的优化。

![](附件资源/阶跃星辰基于%20SelectDB%20构建%20PB%20级%20Agent%20可观测平台/img_9.jpg)

其他场景

基于 SelectDB 其实我们内部也做了更多 Agent 相关的系统，比如说 OpenClaw 的 trace 和 log， 还有一套类似 WanDB 的高性能训练指标系统，都是围绕我们 SelectDB 来构建的。

![](附件资源/阶跃星辰基于%20SelectDB%20构建%20PB%20级%20Agent%20可观测平台/img_10.jpg)

04

未来展望

我们最终的目标是**围绕 SelectDB 去构建一体化的 Agent 数据分析平台**。这里有六个部分，前三个点前面都已经有了介绍，我这里着重介绍是后面三个点。

- 在技术侧基础设施层面的打通方面。生产级 Agent 运行链路复杂，它从模型的决策、沙箱执行、推理调度以及引擎层面的优化，都需要统一的观测，才能够去定位到问题，比如说假设我们有一个用户的报障，我们去怎么去确定它到底是在基础设施的哪一个环节？可能出现了一些非预期的效果，非预期的结果导致了它整个效果不好。那比如说 vLLM 层的 prefill、decode，以及沙箱中怎么去做 eBPF 无侵入的观测，或者说做很多安全的拦截。
- 在数据闭环这一层面，我们希望能够能够把 trace 数据直接对接 ATIF，它是一种 Agent 运行轨迹的格式。打通这个 ATIF 格式，我们才可以直接对接到 OpenHands、SWE-Bench 、Gemini 的 CLI 等评测的框架。打通 Trace 数据应用的最后一公里，才能为一个全面赋能 SFT 、RL、Evaluation 的数据底座。
- 在数据开放这个层面，我们希望能够接入这种企业级的数据平台，对接我们公司内部的这种大数据的组件，来构建一个基于 Trace 的完整数仓体系。

![](附件资源/阶跃星辰基于%20SelectDB%20构建%20PB%20级%20Agent%20可观测平台/img_11.jpg)

阶跃星辰基于 SelectDB 构建 Agent 可观测平台 StepTrace 的实践表明，Agent 可观测也是一个实时数据分析问题，它面临的实时写入、超长 Trace 检索分析、成本控制等挑战，SelectDB 的列式存储和聚合物化视图、倒排索引、VARIANT 半结构化数据类型、存算分离架构等能力可以很好的应对解决，是能够真实落地、经得起生产规模检验的 Agent 可观测数据底座。

**SelectDB 把这些能力进一步产品化为 **[Litefuse](https://mp.weixin.qq.com/s?__biz=Mzg3Njc2NDAwOA==&mid=2247540527&idx=1&sn=8cab803eef180f79971d49ffef1221b8&scene=21&token=365338700&lang=zh_CN#wechat_redirect)**，一个开箱即用的 Agent 可观测与评估产品**。如果你也在开发 Agent，需要跟踪和分析 Agent 的效果，你可以参考阶跃星辰的实践自己基于** SelectDB**（https://www.selectdb.com/） 构建 Agent 可观测与评估平台，也可以选择现成的** Litefuse**（https://litefuse.ai/），快速让 Agent 迭代起来，个性化的需求可以基于 Litefuse 开源代码持续迭代。

_**最后，欢迎大家加入 Litefuse 社群，与 Litefuse 的开发者和用户交流 Agent 可观测与评估，打造可靠有效的 AI Agent。**_

![](附件资源/阶跃星辰基于%20SelectDB%20构建%20PB%20级%20Agent%20可观测平台/img_12.png)

![](附件资源/阶跃星辰基于%20SelectDB%20构建%20PB%20级%20Agent%20可观测平台/img_13.gif)

---
原文链接：https://mp.weixin.qq.com/s?__biz=Mzg3Njc2NDAwOA%3D%3D&mid=2247540754&idx=1&sn=a21575976363e986acde83999f7034c4&chksm=cee584a23c1934bc76052891366847e274ce77e448e947241fc9be8c27fd0db0e47bf6b88eba
