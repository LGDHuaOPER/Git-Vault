---
title: "Agent Tracing：用一条 Trace 还原 Agent 为什么失败"
source: "https://mp.weixin.qq.com/s/oy49MaX30Vk5mGWY16vzKA"
author:
  - "[[Ralf]]"
published: 2026年8月7日 08:06
created: 2026-08-10
description: "Agent 出错时，一句 tool call failed 几乎没有排障价值。本文从 Trace、Span、父子关系、版本证据与脱敏讲起，用 8 个故障案例验证错误上下文、安全重试、跨 Worker 恢复和敏感信息保护，给出一套可本地复现的 Agent Tracing 工程方法。"
tags:
  - "Clippings"
  - "微信/公众号文章"
"word-count": "7087"
---
Ralf AI分享烩 *2026年8月7日 08:06*

![图片](https://mmbiz.qpic.cn/sz_mmbiz_png/ZmGD6crl4cYvnBd9QxEG429Kr7H534zLRTGITe4mdrSTNcvic87durxRjTpbp6MjETch3FY9gAIFbjzibicwKvDb7Tib8icRxIbAh2ammAzibrLRM/640?wx_fmt=png&from=appmsg&watermark=1&tp=webp&wxfrom=5&wx_lazy=1#imgIndex=0)

线上告警只有一行：

提示词

```
2026-08-03T10:14:22Z ERROR tool call failed
```

它说明某个工具失败了，却没有告诉我：

- Agent 当时读取了哪份资料；
- 模型选择了哪个动作；
- 失败的是第一次调用还是重试；
- 写操作是否已经在外部系统生效；
- 接管任务的新 Worker 是否沿用了同一个执行上下文；
- 当时运行的是哪个 Prompt、工具合同和策略版本。

如果任务只是一次普通函数调用，多加几行日志也许就够了。但 Agent 会检索、调用模型、选择工具、等待审批、重试和恢复，一行行日志很快变成一堆缺少因果关系的碎片。

这时需要的不是“记录更多文字”，而是 **Agent Tracing** ：把一次端到端任务拆成有父子关系的工作单元，并为每一步保留足以排障、复现和审计的证据。

本文是 AI Agent 工程进阶 第 7 篇。上一篇 Durable Loop 已经让 Agent 能在重启、重试和取消后继续正确运行；这一篇继续回答： **它恢复以后究竟走过哪条路径，第一次失败在哪里，我们又凭什么相信这次重试是安全的。**

| 项目 | 说明 |
| --- | --- |
| 内容类型 | Agent Tracing 入门、故障排查与可复现实验 |
| 适合读者 | 已经理解 Agent Loop，但第一次接触 Trace、Span 或 AI 可观测性的开发者 |
| 阅读时间 | 约 16-20 分钟 |
| 跟做时间 | 45-60 分钟 |
| 环境要求 | Python 3.10+，零第三方依赖，不需要 API Key |
| 代码检查点 | `79a417a` |
| 可带走产物 | 最小 Trace Schema、脱敏器、8 个故障案例、Review Gate 和四份检查报告 |
| 资料核对日期 |  |
| 实验边界 | 使用逻辑顺序和固定耗时；不测 Collector、采样、网络传播、存储性能或平台价格 |

> **先说明一个边界**
> 
> Trace 可以记录模型收到的来源 ID、工具调用、参数摘要、结果、错误和版本，但它不会也不应该声称读取模型隐藏的思维链。本文中的“为什么”指可观察的执行证据，不是模型内部逐字推理。

## 一分钟概览

如果只想先拿走结论，可以记住十点：

1. **Log 是事件，Trace 是一次任务的因果路径。**
	日志可以成为 Span 的 Event，但一堆日志不会自动组成 Trace。
2. **Trace 表示一次端到端任务，Span 表示其中一个有起止边界的工作单元。**
3. **父子关系比时间排序更重要。**
	它告诉你检索、模型、审批和工具调用分别由哪一步触发。
4. **不要记录“模型想了什么”，要记录它实际看见和做了什么。**
	来源 ID、路由结果、参数哈希、错误码和回执更可验证。
5. **最终答案正确，不代表路径安全。**
	Agent 可能读错资料、绕过审批，或者在重试中重复写入。
6. **模型、Prompt、工具、策略和代码版本要一起保存。**
	只记录模型名，通常仍无法复现一次行为变化。
7. **跨 Worker 恢复时要继续关联同一逻辑任务。**
	否则故障前后的证据会被切成两段。
8. **可观测性不等于记录一切。**
	默认使用字段白名单、哈希、长度和来源 ID，不保存密钥、完整 Prompt 与业务原文。
9. **Trace Review Gate 检查证据是否完整，不保证业务答案正确。**
	质量仍然需要 Eval。
10. **先用本地 JSONL 学会读 Trace，再决定是否接 OpenTelemetry、OpenAI Traces、Phoenix 或 Langfuse。**

如果这些名词都很陌生，第一次阅读只走最短路线：先读第 1-5 节看懂一条 Trace，再读第 7-8 节完成脱敏与实验。跨 Worker、平台映射和生产决策可以第二次再看，不影响完成本文练习。

![图片](https://mmbiz.qpic.cn/sz_mmbiz_png/ZmGD6crl4cZ8nfCxmaBxPks5JicZWLZPQHHBfhq9wFqBnwwWOKJ0gXp4GCvgNjyG6Y0SEYfDmgl3uXIScEzCjHHeIu6x54HPFN9Wh1E2SSicI/640?wx_fmt=png&from=appmsg&watermark=1&tp=webp&wxfrom=5&wx_lazy=1#imgIndex=1)

图 1：一条 Agent Trace 从检索、模型决策和审批走到工具超时，再通过回执证据完成安全重试

*图 1：本文的主线不是观测平台，而是一次可还原的故障。节点会按真实执行顺序点亮，失败出现后，右侧证据面板给出错误码、幂等键和版本元组。*

## 1\. 普通日志到底少了什么

先把开头那行日志展开成五个排障问题：

提示词

```
1. Context：Agent 实际看见了哪些来源？
2. Path：它按什么顺序调用了哪些工具？
3. Failure：第一次失败发生在哪一步？
4. Retry：重试前是否确认外部副作用？
5. Version：当时运行的是哪组模型、Prompt、工具、策略和代码？
```

一行 `tool call failed` 最多能回答第 3 个问题的一部分：某个工具失败了。它甚至没有稳定错误码，无法聚合“超时”和“参数错误”。

如果把日志扩成这样，会好一些：

提示词

```
retrieved handbook:refund-policy
model selected record_ticket_followup
approval accepted
tool timeout
receipt not found
retry success
```

但新的问题很快出现：这些行是否属于同一次任务？ `retry success` 是谁触发的？如果多个任务并发执行，哪条 `approval accepted` 对应哪次写入？如果进程中途重启，前后日志怎样连接？

Trace 增加的关键不是更多句子，而是结构：

提示词

```
trace_id          把同一次端到端任务关联起来
span_id           标识一个工作单元
parent_span_id    表示谁触发了谁
status            表示这个单元如何结束
attributes        保存少量、结构化、可检索的证据
versions          保存可复现实验条件
```

![图片](https://mmbiz.qpic.cn/mmbiz_png/ZmGD6crl4cbnbLvtXiablBKJAPsdqZDADAOqPIUFCQYXjykCiaVkAIgt6vB4E1fPlfhfgd8QbXgjBroIJvWGTibYKHJAfNdgx5Fy0mYYgsU7iaA/640?wx_fmt=png&from=appmsg&watermark=1&tp=webp&wxfrom=5&wx_lazy=1#imgIndex=2)

图 2：Log、Metric、Trace、RunState 与 Audit 分别回答不同问题

*图 2：这些对象互相补充，不应混成一个大 JSON。Trace 解释一次运行的路径，RunState 负责恢复，Audit 负责高风险操作的责任记录。*

### Trace、日志、指标、状态和审计的区别

Log

**最适合回答：** 某时发生了什么离散事件

**不应该独自承担：** 重建完整父子路径

Metric

**最适合回答：** 失败率、P95 延迟、Token 总量是否异常

**不应该独自承担：** 解释某一次具体失败

Trace

**最适合回答：** 一次任务沿哪条因果路径执行

**不应该独自承担：** 保存恢复所需的唯一状态

RunState

**最适合回答：** 中断后从哪里继续、哪些副作用待确认

**不应该独自承担：** 充当长期分析仓库

Audit

**最适合回答：** 谁在何时批准、拒绝或改变了高风险动作

**不应该独自承担：** 保存所有模型输入输出

一个常见组合是：指标先告诉你“工具超时率升高”，Trace 帮你找到受影响的运行，日志补充某个底层异常，RunState 决定能否恢复，审计记录说明谁批准了外部写入。

第一次阅读不需要同时掌握五套系统。先记住最关键的区别即可： **Log 是一条事件，Trace 是把同一次任务的事件按因果关系组织起来。** 另外三类先把它们当作边界提醒。

## 2\. 只用五个概念看懂第一条 Trace

第一次接触 Tracing，不需要先学习 Collector、OTLP 和采样策略。先掌握五个概念就够了。

### 2.1 Trace：一次端到端任务

在本文案例里，一个 Trace 对应“为工单 T-102 生成并记录跟进说明”这一次任务。

它从接收任务开始，到完成、失败、取消或进入人工对账结束。一次聊天 Session 可以包含多个 Trace，一次 Trace 也可以跨越多个进程或 Worker。

### 2.2 Span：一个有边界的工作单元

Span 不是任意代码行，而是值得单独观察的操作，例如：

提示词

```
agent        整次 Agent 运行
retrieval    检索资料
model        一次模型调用或决策
approval     等待并接收人工批准
tool         一次工具执行
```

一个 Span 至少需要名称、起止、状态和标识。失败 Span 还需要稳定错误码；否则只能搜索异常文本。

### 2.3 父子关系：谁触发了谁

每个非根 Span 都指向一个父 Span。这样才能把扁平事件还原成执行树：

提示词

```
ticket_followup_agent
├── retrieve_policy
├── choose_followup_action
├── approve_external_write
└── record_ticket_followup
```

OpenTelemetry Tracing API 对基础关系的定义很直接：一个 Span 至多有一个父 Span，可以有多个子 Span；相关 Span 组成一棵 Trace 树。本文的本地 Schema 沿用这个最小心智模型，但不宣称自己已经实现完整 OpenTelemetry SDK。

### 2.4 版本证据：这次行为来自哪一组系统

Agent 的行为通常不只由模型决定。我会把下面五项视为最小版本元组：

代码

```
{
  "model": "fixture-model@1",
  "prompt": "followup@3",
  "tool": "ticket-tools@2",
  "policy": "approval@4",
  "code": "ae-07-trace"
}
```

如果只记录 `model` ，当一次行为变化时，你仍然不知道是 Prompt、工具 Schema、审批策略还是代码改变了。

### 2.5 脱敏：只保存排障需要的最小证据

Trace 的价值来自可检索证据，不来自完整复制所有输入输出。

例如，工具写入一段工单说明时，报告可以保存：

代码

```
{
  "recipient_hash": "sha256:...",
  "body_length": 182,
  "argument_hash": "sha256:arguments-v1",
  "receipt_status": "committed"
}
```

通常没有必要保存邮箱、完整正文或授权 Token。

## 3\. 用一棵 Span 树还原一次安全重试

现在看完整案例。

Agent 先检索退款规则，模型决定写入工单，人工批准后调用工具。第一次调用超时，系统没有立即重写，而是先查询业务回执；确认不存在回执后，才用相同幂等键进行第二次尝试。

![图片](https://mmbiz.qpic.cn/mmbiz_png/ZmGD6crl4cYvXcKSlDQ9pTMUdD0vaXbCGbiaefxXYjG3QYEHj1o1wqKhviaOq7y9GtG79W0qzG2UHeuJDQcj2RfQJrWLYSIFVxbpFxzkkING4/640?wx_fmt=png&from=appmsg&watermark=1&tp=webp&wxfrom=5&wx_lazy=1#imgIndex=3)

图 3：安全重试案例的 Span 树，第一次工具调用超时，查询回执后再以相同动作身份重试

*图 3：错误 Span 不是终点。 `TOOL_TIMEOUT` 、 `receipt_status` 、稳定 `idempotency_key_hash` 和 `attempt=2` 一起解释了为什么第二次调用可以继续。*

这棵树至少留下四类事实：

1. `retrieval`
	Span 保存来源 ID，证明模型使用了哪份规则。
2. `model`
	Span 保存路由结果、Prompt 哈希和 Token 用量。
3. 第一次 `tool` Span 以 `error` 结束，并给出 `TOOL_TIMEOUT` 。
4. 第二次 `tool` Span 的 `attempt=2` ，且动作哈希和幂等键与第一次一致。

注意，Timeout 本身不能证明写入失败。真正允许重试的是后面的回执查询和稳定动作身份。这与上一篇 Durable Loop 的结论一致： **Trace 负责保留证据，恢复策略仍由 Harness 和工具合同执行。**

## 4\. 一个最小 Span 需要哪些字段

Trace Lab 0.7.0 中的一条工具 Span 是这样的：

代码

```
{
  "trace_id": "trace::safe-retry",
  "span_id": "tool-retry",
  "parent_span_id": "root",
  "name": "record_ticket_followup",
  "kind": "tool",
  "sequence": 7,
  "duration_ms": 10,
  "status": "ok",
  "attempt": 2,
  "versions": {
    "model": "fixture-model@1",
    "prompt": "followup@3",
    "tool": "ticket-tools@2",
    "policy": "approval@4",
    "code": "ae-07-trace"
  },
  "attributes": {
    "side_effecting": true,
    "argument_hash": "sha256:arguments-v1",
    "idempotency_key_hash": "sha256:action-t102",
    "receipt_status": "committed"
  },
  "usage": {
    "input_tokens": 0,
    "output_tokens": 0
  },
  "error_code": null
}
```

字段可以分成六组：

关联

**字段：** `trace_id` 、 `span_id` 、 `parent_span_id`

**用途：** 重建任务与父子关系

操作

**字段：** `name` 、 `kind`

**用途：** 区分检索、模型、审批和工具

顺序

**字段：** `sequence` 、 `duration_ms`

**用途：** 还原逻辑顺序并发现慢步骤

结果

**字段：** `status` 、 `error_code` 、 `attempt`

**用途：** 判断终态、失败类型和重试次数

复现

**字段：** `versions`

**用途：** 对齐模型、Prompt、工具、策略和代码

证据

**字段：** `attributes` 、 `usage`

**用途：** 保存经过脱敏的业务证据与用量

真实系统通常会使用时间戳，而 Lab 使用固定逻辑顺序和持续时间，是为了让测试在不同电脑上得到相同结果。它验证的是 Schema 与 Review Gate，不是时钟精度或性能。

### 不要把所有字段塞进 attributes

如果状态、错误码和版本全被放进一个无约束字典，后续很难写稳定查询和检查规则。应该把跨 Span 都需要的字段提升为固定结构，把只属于某个操作的少量证据留在 `attributes` 。

例如：

提示词

```
retrieval.attributes.source_ids
model.attributes.route
approval.attributes.approval_state
tool.attributes.receipt_status
```

## 5\. Trace 怎样回答五个排障问题

回到开头的五问。

### 5.1 Agent 看见了什么

不要只记录“检索成功”，至少要记录来源 ID、版本或更新时间：

代码

```
{"source_ids": ["handbook:refund-policy"]}
```

Lab 的 `wrong-context` 案例故意把它换成过期来源：

代码

```
{"source_ids": ["faq:refund-policy-2024"]}
```

Review Gate 将任务合同要求的来源与实际来源比较，得到 `context_mismatch` 。它不能证明模型的全部理解过程，却能证明错误决策之前进入了错误资料。

### 5.2 Agent 走了哪条工具路径

按 Span 树读取 `kind=tool` 的节点，可以得到：

提示词

```
record_ticket_followup
  -> lookup_write_receipt
  -> record_ticket_followup (attempt 2)
```

如果最终结果正确，但路径里出现未经批准的写工具，Trace 仍然应该把它暴露出来。

### 5.3 第一次失败在哪里

不要用最终 Root Span 的 `failed` 代替真正错误。应找到逻辑顺序最早的错误 Span：

提示词

```
span_id: tool
status: error
error_code: TOOL_TIMEOUT
attempt: 1
```

### 5.4 为什么可以重试

对有副作用的工具， `attempt=2` 必须同时出现至少一类安全证据：

提示词

```
稳定幂等键
业务回执查询
明确的 reconciliation 结果
```

Lab 会拒绝“有副作用、第二次尝试、但既没有幂等键也没有回执”的 Span。

### 5.5 怎样复现当时的行为

检查关键 `agent` 、 `model` 和 `tool` Span 的版本元组。如果模型 Span 缺少 `prompt` ，Review Gate 会报告 `missing_version_evidence` 。

这不是洁癖。没有版本证据，生产失败很难被准确加入 Eval：你可能复现了相同输入，却运行了不同 Prompt 和工具合同。

## 6\. 任务换了 Worker，Trace 要不要换

上一篇已经实现：Worker A 中断后，Worker B 从持久检查点继续。

从排障角度看，这仍然是同一个逻辑任务。Lab 保持同一个 `trace_id` ，并在恢复 Span 中保存：

代码

```
{
  "worker_id": "worker-b",
  "resume_from_span": "model"
}
```

![图片](https://mmbiz.qpic.cn/sz_mmbiz_png/ZmGD6crl4cZttryoaHcLHqyJr5NhD5t9gx7Ma7j2gibZ6lkMNRferxiclm5SAP7Sib6VJtWhZ17AjFAOqs1ocyjia95Q37yUVtdBOxwbXZtCvO0/640?wx_fmt=png&from=appmsg&watermark=1&tp=webp&wxfrom=5&wx_lazy=1#imgIndex=4)

图 4：Worker A 中断后，Worker B 通过检查点继续同一逻辑 Trace

*图 4：RunState 决定从哪里恢复，Trace 负责把恢复前后的执行证据关联起来。两者相关，但不是同一份数据。*

真实跨进程系统还要传播 Trace Context。对于持续数小时、跨信任边界或扇出汇总的任务，也可能选择新 Trace 再通过 Link 关联。本文不展开这些协议，只保留一个判断：

> 如果排障者认为它仍是同一次业务任务，就必须存在稳定关联，不能让 Worker 重启把证据切断。

## 7\. 先脱敏，再落盘

Agent Trace 比普通基础设施 Trace 更容易带上业务内容：模型输入输出、检索文档、工具参数和结果都可能含有个人信息、内部规则或密钥。

OpenAI Agents SDK 当前文档明确提示，generation 与 function Span 可能包含敏感输入输出； `RunConfig.trace_include_sensitive_data` 可以关闭这类捕获，而且该选项当前默认值为 `True` 。这意味着接入内置 tracing 后，仍要主动核对数据策略，而不是假设 SDK 已替业务完成脱敏。OpenAI Agents SDK Tracing

本文采用三层保护：

提示词

```
字段白名单
  -> 值模式扫描
  -> 只把安全副本写入 JSONL
```

![图片](https://mmbiz.qpic.cn/mmbiz_png/ZmGD6crl4cZaUTXTFPE3zia0UHqbX67UIZ6dQ0HwY0WR3iazHhEjwLKkylsWDv76mr36zW5lByP2dl8fBcIuuEhJlziaKZboxWH8Z4bPCGLglY/640?wx_fmt=png&from=appmsg&watermark=1&tp=webp&wxfrom=5&wx_lazy=1#imgIndex=5)

图 5：Agent Trace 从原始输入经过字段白名单、敏感值扫描和最小化后再落盘

*图 5： `email` 、完整正文和模拟 Token 被丢弃；来源 ID、哈希、长度、状态与版本留下。原始值不会出现在最终 `traces.jsonl` 。*

### 7.1 字段白名单

Lab 只允许一组明确字段，例如：

代码

```
ALLOWED_ATTRIBUTE_KEYS = {
    "source_ids",
    "route",
    "approval_state",
    "argument_hash",
    "body_length",
    "idempotency_key_hash",
    "receipt_status",
    "worker_id",
}
```

未声明的 `email` 、 `body` 、 `prompt` 和 `token` 不进入输出。

### 7.2 允许字段也要扫描值

字段名安全，不代表值一定安全。 `result_code` 如果意外收到 `Bearer ...`，仍会被敏感模式识别并移除。

### 7.3 哈希不是万能匿名化

低熵值、手机号和常见邮箱可能被反推或撞库。哈希只适合比较“是否同一对象”，不自动等于匿名化。生产系统还需要盐、访问控制、保留期限、环境隔离和删除机制。

## 8\. 跟着运行 Trace Lab 0.7.0

完整代码位于公开仓库 RalfNick/ai-agent-learn，本篇对应不可变 commit `79a417a` 。

下载 Agent Tracing Lab 0.7.0 ZIP

命令

```
git clone --branch agent-engineering-series https://github.com/RalfNick/ai-agent-learn.git
cd ai-agent-learn/phase-7-agent-engineering/agent-reliability-lab

python run_lab.py trace-review --output reports/local
python -m unittest discover -s tests -v
```

命令会生成四份文件：

提示词

```
reports/local/
├── trace-review.json      # 完整结构化结果
├── trace-review.md        # 五问矩阵与 Gate
├── trace-failures.md      # 问题案例和定位
└── traces.jsonl           # 已脱敏 Span
```

### 8.1 八个案例分别验证什么

`clean-run`

**要观察的证据：** 完整父子树与版本元组

**预期结果：** 无 Finding

`wrong-context`

**要观察的证据：** 实际来源与任务合同

**预期结果：** `context_mismatch`

`safe-retry`

**要观察的证据：** 错误码、回执、幂等键、attempt

**预期结果：** 无 Finding

`worker-resume`

**要观察的证据：** 同一 Trace、两个 Worker、恢复点

**预期结果：** 无 Finding

`missing-version`

**要观察的证据：** 模型 Span 的 Prompt 版本

**预期结果：** `missing_version_evidence`

`orphan-span`

**要观察的证据：** `parent_span_id` 是否存在

**预期结果：** `orphan_span`

`unclosed-span`

**要观察的证据：** Span 是否有明确终态

**预期结果：** `missing_terminal_status`

`secret-leak`

**要观察的证据：** 模拟 Token 是否进入报告

**预期结果：** `sensitive_attribute` ，值被移除

这里容易产生一个误解：有 Finding 的案例为什么还能让总 Gate 通过？

因为这些是 **故意构造的审查样本** 。Gate 验证的是审查器是否准确找出合同里声明的问题。它不是在声称八条 Trace 都健康。

### 8.2 本地结果怎样读

当前验证结果是：

提示词

```
Trace cases                         8
Expected findings matched          8 / 8
One-line log answerability         20.0%  (1 / 5)
Structured trace answerability     97.5%  (39 / 40)
Sensitive value in exported JSONL  0
Full unit tests                     62 passed
Review gate                        PASS
```

![图片](https://mmbiz.qpic.cn/sz_mmbiz_png/ZmGD6crl4cZBRibiaiaem097V8gMbXQ0Gd9tjzVaokLcerDGRXMeJIoJxqD7RUtNmeZbhP7tGrK7E2BicSx2IH8qpp6NBUBltbFXF9qVpRfxvcA/640?wx_fmt=png&from=appmsg&watermark=1&tp=webp&wxfrom=5&wx_lazy=1#imgIndex=6)

图 6：Trace Lab 的八个案例、五问矩阵与 Review Gate 结果

*图 6：97.5% 只表示这 8 个确定性案例中的 40 个“案例 × 排障问题”单元有 39 个可回答。缺少的一格正是 `missing-version` ；它不是生产效果指标。*

一行日志的 `20%` 同样只是教学控制：它只能回答“发生了工具失败”，不能回答来源、路径、重试证据和版本。不要把两组数字外推成通用收益。

### 8.3 两个值得亲手做的修改

**练习一：补齐版本证据**

在 `agent_lab/tracing.py` 中找到 `case.scenario == "missing_version"` 分支，把模型 Span 改回完整版本元组：

代码

```
spans[2] = replace(spans[2], versions=versions)
```

然后把 `datasets/trace-cases.jsonl` 中该案例的 `expected_findings` 从 `["missing_version_evidence"]` 改为 `[]` 。重新运行后，观察：

提示词

```
missing_version_evidence 消失
version_tuple 从 no 变为 yes
```

同时更新数据集里的 `expected_findings` ，否则 Review Gate 应该失败。这一步能帮助理解：Fixture 合同和实现必须一起变化。

**练习二：制造一次不安全重试**

在 `safe_retry` 分支的 `tool-retry` Span 中移除下面两项：

代码

```
"idempotency_key_hash": "sha256:action-t102",
"receipt_status": "committed",
```

再运行 `python run_lab.py trace-review --output reports/unsafe-retry` 。命令应以非零状态退出，因为数据集仍把 `safe-retry` 声明为健康案例； `trace-failures.md` 会出现 `unsafe_retry` 。观察完成后恢复这两个字段，即可让 Gate 再次通过。

它证明 Review Gate 检查的不是“是否重试成功”，而是“重试是否有安全证据”。

## 9\. 一份可复制的 Trace Review Gate

下面这份清单可以直接放进自己的 Agent 项目。

### 结构

- \[ \] 每条 Trace 只有一个 Root Span
- \[ \] 每个非根 Span 都能找到父 Span
- \[ \] 父 Span 的逻辑顺序早于子 Span
- \[ \] 每个 Span 都有明确终态
- \[ \] 错误 Span 使用稳定错误码，不只保存异常文本

### 行为证据

- \[ \] 检索 Span 保存来源 ID 或版本
- \[ \] 工具路径可以按父子关系重建
- \[ \] 有副作用的重试保存幂等键或回执证据
- \[ \] 审批 Span 能关联到被批准的具体动作
- \[ \] 跨 Worker 恢复保留稳定任务关联和恢复点

### 复现

- \[ \] 模型版本已记录
- \[ \] Prompt 或指令版本已记录
- \[ \] 工具合同版本已记录
- \[ \] 策略与审批规则版本已记录
- \[ \] 代码或发布版本已记录

### 隐私与运营

- \[ \] 属性采用白名单，而不是事后黑名单
- \[ \] 密钥、邮箱和个人信息在落盘前扫描
- \[ \] 默认不保存完整 Prompt、输出和工具正文
- \[ \] 不同环境分开，访问有审计
- \[ \] 已定义保留期限和删除流程
- \[ \] 短进程退出前确认批量 exporter 已 flush

## 10\. 怎样映射到现有框架与平台

理解本地 Schema 后，再看平台会容易很多。

一次任务

**OpenTelemetry：** Trace

**OpenAI Agents SDK：** Trace / workflow

**Phoenix：** Trace

**Langfuse：** Trace

一个步骤

**OpenTelemetry：** Span

**OpenAI Agents SDK：** Agent、generation、function、handoff 等 Span

**Phoenix：** Span / OpenInference SpanKind

**Langfuse：** Observation / Span / Generation

父子关系

**OpenTelemetry：** Parent Context

**OpenAI Agents SDK：** 当前 Trace 与最近 Span 自动嵌套

**Phoenix：** 嵌套 Span

**Langfuse：** 嵌套 Observation

自定义输出

**OpenTelemetry：** Exporter / OTLP

**OpenAI Agents SDK：** Trace processor

**Phoenix：** OTLP / Phoenix

**Langfuse：** OpenTelemetry / SDK

会话关联

**OpenTelemetry：** Attribute / Link

**OpenAI Agents SDK：** `group_id`

**Phoenix：** Session

**Langfuse：** Session

隐私控制

**OpenTelemetry：** 由 instrumentation 与 exporter 策略负责

**OpenAI Agents SDK：** `trace_include_sensitive_data`

**Phoenix：** 由采集与部署策略负责

**Langfuse：** 由 instrumentation、部署与保留策略负责

### 10.1 OpenTelemetry：通用骨架

OpenTelemetry 提供 Trace、Span、Context、Event、Status、Link 和 Exporter 等通用概念。基础 Tracing API 当前标记为 Stable；与生成式 AI 相关的语义约定已经迁移到独立的 OpenTelemetry GenAI Semantic Conventions 仓库，仍在持续演进。Tracing API

因此更稳妥的做法是：先保持自己的业务字段小而明确，再在 exporter 层映射标准字段；不要把今天看到的所有 GenAI 属性名直接写死成永远不变的业务合同。

### 10.2 OpenAI Agents SDK：开箱即用的运行 Trace

OpenAI Agents SDK Tracing 当前会记录模型生成、工具调用、handoff、guardrail 和自定义事件，并支持自定义 trace processor 将数据发送到其他目的地。短任务如果需要立即看到结果，可以在 Trace 结束后调用 `flush_traces()` 。

接入前至少核对三件事：

提示词

```
是否需要关闭敏感输入输出捕获
是否保留默认 exporter，还是替换 processor
短生命周期 Worker 是否在退出前 flush
```

### 10.3 Phoenix：适合可视化 Trace 并接 Eval

Phoenix Tracing Tutorial 使用 OpenTelemetry 记录模型调用、检索和工具执行，并把 Span 组织成可浏览的运行路径。它还可以把 Annotation 和 Eval 接到 Trace 上，适合从“看见一次失败”继续走向“统计某类失败”。

### 10.4 Langfuse：Trace、Observation 与 Session

Langfuse Data Model 将一次操作组织为 Trace，把模型、工具和检索步骤表示为可嵌套 Observation，并可用 Session 关联多轮交互。它建立在 OpenTelemetry 之上；官方文档也提醒，短生命周期程序要显式 `flush()` ，否则后台批量队列可能尚未发送完毕。

这些平台能省下采集、查询和界面建设，但不会自动替你决定：哪些业务字段应该记录、哪些数据不能离开本地、哪个版本元组才足以复现、哪类重试算安全。

## 11\. 什么时候本地 JSONL 已经够用

如果项目仍处于下面阶段，本地 JSONL 往往已经能带来很大帮助：

提示词

```
单进程或单 Worker
每天运行量不大
主要任务是开发期排障
暂时不需要跨服务关联
数据不能轻易上传外部平台
```

当出现这些需求，再考虑 OpenTelemetry 与平台：

- Trace 跨多个服务、队列和进程；
- 需要按版本、用户、错误码和工具聚合查询；
- 需要采样、保留策略和访问控制；
- 需要将 Trace 与 Eval、反馈、成本和发布版本关联；
- 多个团队共同排查同一条执行链；
- 本地文件已经无法支持查询与容量管理。

平台选择不是本文的主要结论。更重要的是：即使切换后端， `source_ids` 、 `receipt_status` 、版本元组和隐私边界这些业务证据仍然需要自己设计。

## 12\. 收藏清单：第一次给 Agent 加 Trace

可以按下面顺序开始，不需要一次做完整观测平台。

### 第 1 步：选一条真实失败任务

不要从“记录所有 Agent”开始。先选一条目前只能靠猜的失败，写出五个排障问题。

### 第 2 步：定义五类 Span

先覆盖 `agent` 、 `retrieval` 、 `model` 、 `approval` 和 `tool` 。只有真的需要时再增加种类。

### 第 3 步：建立版本元组

让模型、Prompt、工具、策略和代码版本能一起进入 Trace。

### 第 4 步：先写脱敏器

先定义允许字段，再开始导出。不要等数据已经进入平台后才讨论隐私。

### 第 5 步：写 Review Gate

至少检查 Root、父 Span、终态、错误码、版本、敏感信息与重试证据。

### 第 6 步：把生产失败转成 Eval

Trace 解释“发生了什么”，Eval 判断“改动是否更好”。当 Trace 找到一个稳定失败模式，把它加入任务集，才能防止回归。

## 结语：Trace 不是录像，而是证据链

给 Agent 加 Trace，不是把 Prompt、输出和工具正文全部录下来，也不是为了得到一张漂亮的瀑布图。

真正有价值的是建立一条可检查的证据链：

提示词

```
它看了哪些来源
  -> 做了哪个可观察决定
  -> 调用了什么工具
  -> 第一次在哪里失败
  -> 为什么可以重试或恢复
  -> 当时运行的是哪组版本
```

如果只记住一句：

> **好的 Agent Trace 不需要记录一切，但必须足以还原路径、定位第一个错误，并证明恢复与重试为什么安全。**

下一篇进入 **Memory Engineering** 。Trace 解决“这次运行发生了什么”，Memory 还要回答“哪些信息值得跨任务保留、谁有权写入、冲突怎样处理，以及什么时候必须删除”。

## 参考资料

### 标准与 OpenAI

- OpenTelemetry Tracing API
- OpenTelemetry GenAI Semantic Conventions
- OpenAI Agents SDK：Tracing
- OpenAI Cookbook：Agents SDK Deployment Manager - Tracing

### 观测平台

- Arize Phoenix：Tracing Tutorial
- Arize Phoenix：What are Traces
- Langfuse：Observability Data Model

### 本文代码与证据

- Agent Reliability Lab `79a417a`
- Trace Review report
- Trace Finding ledger
- Sanitized traces.jsonl

AI学习 · 目录

阅读原文

拖拽到此处完成下载

图片将完成下载

AIX智能下载器