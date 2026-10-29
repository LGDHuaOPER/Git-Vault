---
source_url: "https://mp.weixin.qq.com/s?__biz=MzI5MTcwMzQ5Ng%3D%3D&mid=2247484062&idx=1&sn=a36e5d273be61dd06653705eed744447&chksm=ec0ddd39db7a542f8032374f7103179a1459ef8413d7cab0da69b36d1b54832afc15aea5ffa7"
title: "Langfuse Eval：Agent 评测原理与落地实践"
account: "AI渐渐"
published_at: "2026-10-24 20:59:33"
saved_at: "2026-10-24 21:54:56"
sync_id: "art_b3dafb55d31d414ea09ec2bb57ed8d29"
parse_status: "ok"
---

# Langfuse Eval：Agent 评测原理与落地实践

## 一、背景

之前分享过几篇 Agent 的可观测性和评测相关的技术文章，感兴趣的同学可以前往阅读：

- [Agent 可观测性基石：OpenTelemetry 学习与实践](https://mp.weixin.qq.com/s?__biz=MzI5MTcwMzQ5Ng==&mid=2247483996&idx=1&sn=7ade288a853a3e512ea856310de610fb&scene=21#wechat_redirect)：把 Agent 的 trajectory 记录成一棵 Trace 树。
- [从 OpenTelemetry 到 Langfuse：企业级 Agent 可观测性实践](https://mp.weixin.qq.com/s?__biz=MzI5MTcwMzQ5Ng==&mid=2247484014&idx=1&sn=1ebd7fd29dd45b1441c29333433afdfb&scene=21#wechat_redirect)：在 OTel 之上补 Agent 语义，做监控和分析。
- [Harbor 实战：Agent 评测从任务到轨迹](https://mp.weixin.qq.com/s?__biz=MzI5MTcwMzQ5Ng==&mid=2247484030&idx=1&sn=fa1cae27fde039feac738153ef020d5d&scene=21#wechat_redirect)：用标准化任务判断 Agent 有没有完成目标。

[从 OpenTelemetry 到 Langfuse：企业级 Agent 可观测性实践](https://mp.weixin.qq.com/s?__biz=MzI5MTcwMzQ5Ng==&mid=2247484014&idx=1&sn=1ebd7fd29dd45b1441c29333433afdfb&scene=21#wechat_redirect)，重点是分享怎么在项目中使用 Langfuse 实现 Agent 的 trajectory 记录：Trace、Observation、LLM 调用、Tool 调用、Token 消耗、执行耗时。这仅仅是 Langfuse 的一部分能力。

```
其实，Langfuse 也能像 Harbor 一样，也能够完成 Agent 评测工作，区别的是承载方式不同。Harbor 用 Task、Verifier 和独立沙箱组织一次评测；Langfuse 把评测放回 trace 体系里，执行产生 trace，评分挂在 trace 上，数据集和实验也围绕它组织。
```

它的评测机制核心，四个东西：

- Dataset（评测数据集）：一组固定的输入和期望输出，保证每次比较的是同一批题。
- Evaluator（评估器）：判断输出对不对，可以是代码规则、LLM Judge 或人工。
- Score（评测结果）：把判断结果存下来，挂在对应的 trace 上。
- Experiment（实验）：跑完一整轮数据集，汇总分数，比较版本。

它把四者串成一条执行链路：

![](附件资源/Langfuse%20Eval：Agent%20评测原理与落地实践/img_1.png)

## 二、Langfuse Eval 实现

### 2.1 Monitoring / Evaluation

Monitoring 负责记录 Agent 的执行过程，Evaluation 负责评测 Agent 执行结果质量。

![](附件资源/Langfuse%20Eval：Agent%20评测原理与落地实践/img_2.png)

譬如：一个 Agent 收到「帮我订明天北京到上海的机票」：

- Monitoring 记录输入、输出、模型调用、工具调用。
- Evaluation 检查：意图是不是订机票，出发地、目的地、日期有没有抽对，返回结构是否符合约定，接入真实预订流程后是否满足业务定义的成功条件。

### 2.2 Langfuse Eval 的核心概念

| 概念 | 作用 |
| --- | --- |
| Dataset | 保存一组可重复使用的评测样本 |
| Task | 执行待评测的应用 |
| Evaluator | 判断输出质量 |
| Score | 保存一次判断结果 |
| Experiment | 组织一轮数据集实验 |
| Trace / Observation | 记录执行过程 |

用订机票这一条样本，看六个东西分别长什么样（伪代码）。

**Dataset**：一条样本，输入加期望输出。

```
input:           帮我订明天北京到上海的机票expectedOutput:  intent=book_flight                 date=明天, from=北京, to=上海
```

**Task**：把现有 Agent 包成一个函数。

```
def task(*, item):    return my_agent.run(item.input)
```

**Evaluator**：拿输出和期望比，给一个分数。

```
def intent_match(*, output, expected_output, **kwargs):    return Evaluation(        name="intent_match",        value=float(output["intent"] == expected_output["intent"]),    )
```

**Score**：跑完一条样本后，存下来的结果。

```
trace: agent-eval-001├── intent_match = 1.0└── slot_f1      = 0.67
```

**Experiment**：三样串起来，跑一整轮。

```
result = dataset.run_experiment(    name="agent-eval-v1",    task=task,    evaluators=[intent_match, slot_f1],)
```

**Trace / Observation**：一次执行的过程记录，Score 挂在上面。

```
trace: agent-eval-001├── generation  understand-query├── tool        search-flight└── generation  generate-answer
```

### 2.3 Dataset

Dataset 是评测的基础。它提供两样东西：喂给 Agent 的输入，和用来判断结果的期望输出。

改完 Prompt 想判断有没有变好，如果每次换一批问题测，就分不清效果变化来自代码还是输入。固定 Dataset 就是为了消除这个变量。

一条评测样本通常是这个结构：

```
{  "input": "帮我订明天北京到上海的机票",  "expectedOutput": {    "intent": "book_flight",    "slots": {      "date": "明天",      "from": "北京",      "to": "上海"    }  },  "metadata": {    "task": "book_flight",    "source": "manual"  }}
```

-  `input`  ：Agent 收到的输入，字符串或结构化对象都行。
-  `expectedOutput`  ：期望结果，Evaluator 拿它做对比。开放式任务可以写参考答案或评分要点，也可以留空，交给 LLM Judge 判断。
-  `metadata`  ：可选元信息，记录任务类型、来源、难度，方便筛选和分组。

Langfuse 就按这个结构存 Dataset。条目可以从 SDK、UI 或 CSV 写入，也可以从已有 trace 里挑一条，带入输入后再补期望输出。

### 2.4 Evaluator

Dataset 提供测试数据，Evaluator 判断 Agent 执行后的效果。

譬如：订机票 Agent 这个例子，定义四个评测指标：

| 评测指标 | 判断逻辑 | 适用场景 |
| --- | --- | --- |
|  `json_valid`  | 输出是否符合约定的 JSON 结构 | 结构化输出 |
|  `intent_match`  | 预测意图是否与期望意图一致 | 意图识别 |
|  `slot_f1`  | 提取槽位与期望槽位的匹配程度 | 实体及参数提取 |
|  `task_success`  | 任务定义的全部必要条件是否满足 | 任务级验证 |

实现方式有三种，第三章分别展开。

- 代码评测：规则能写清楚时用代码判断，快、稳定、可复现。
- LLM-as-a-Judge：没有唯一答案时让模型按标准打分，需要人工样本校验。
- 人工评测：难自动判断时交给人，成本最高，也最可信。

三种评测方式不互斥，一个 Agent 可以同时用代码规则查结构和业务约束，再用 LLM Judge 判断开放式回答。

### 2.5 Score 与 Experiment

Evaluator 完成打分，Score 把这次打分存下来：指标名和结果。存下来的分数挂在对应的执行记录上，后面可以查、可以筛、可以比。

```
Trace: agent-eval-001  ├── Score: json_valid   = 1  ├── Score: intent_match = 1  └── Score: slot_f1      = 0.67
```

三个分数由三个 Evaluator 分别给出： `json_valid`  查输出结构是否合法， `intent_match`  查意图是否一致， `slot_f1`  逐项比对槽位：

| 槽位 | 期望 | Agent 输出 |
| --- | --- | --- |
| 日期 | 明天 | 明天 |
| 出发地 | 北京 | 北京 |
| 目的地 | 上海 | 杭州 |

对了 2 个（TP）；目的地写错，算 1 个错报（FP）、1 个漏报（FN）。 `slot_f1`  = 2×TP / (2×TP + FP + FN) = 4/6 ≈ 0.67。它不是 0/1：多个槽位里对了一部分，就会得到小数。

对整个 Dataset 跑一遍评测，Experiment 组织这一轮执行和评分。可以看单条样本，也可以看整体分数和不同实验之间的变化。

Langfuse 只提供每个指标单独统计，实验页展示各自的均值和分布。

## 三、Langfuse Eval 方式

### 3.1 基于 Dataset 的批量评测

实践部分用的就是这种方式：固定 Dataset，批量执行，Evaluator 打分。

典型用途：

- 改 Prompt 前后，比意图识别准确率；
- 换模型后，比槽位提取效果；
- 调整工具调用逻辑后，验证老用例有没有回归。

价值在于改动还没上生产，就能验证预期效果。

### 3.2 基于代码的确定性评测

能写成明确规则的，优先用代码：

- JSON 能否解析；
- 必要字段是否齐全；
- 分类是否正确；
- 数值是否在范围内；
- 工具参数是否符合业务规则。

比如  `json_valid` ，几行就能判断：

```
data = json.loads(output)valid = (    isinstance(data.get("intent"), str)    and isinstance(data.get("slots"), dict))
```

合法记 1，不合法记 0。

意图识别直接比标签。槽位提取算 Precision、Recall、F1，不要只比整个 JSON 是否相等。

适合有明确业务标准、需要稳定复现和持续回归的任务。

### 3.3 基于 LLM-as-a-Judge 的语义评测

开放式生成任务，标准答案往往不止一个。「杭州周末去哪玩」，几种推荐都合理，按字符串比对判断不出质量。

这时让 LLM Judge 按明确标准打分。比如判断回答是否切题，分成 Relevant、Somewhat relevant、Not relevant 三档。

Langfuse 提供了一批现成模板，模板里已经把评判范围、判定规则和标签写好。以 Check Answer Relevance 为例，把模板里的稳定规则整理成 system prompt 版：

```
You are an expert answer-relevance evaluator for AI conversations.## Scope- Judge relevance, topical alignment, completeness, and whether the response resolves the request.- Assess the output against the user request only; do not infer unstated requirements.## Golden RuleSelect Relevant only when the output directly addresses the user's primary request,covers all material parts, and stays on topic.## Decision Rules1. Identify the user's primary goal and any material sub-requests or constraints.2. Compare the assistant output against those requirements.3. If multiple requests exist, assess whether the output resolves the primary request and all material parts.4. Choose exactly one label. When evidence is ambiguous, choose the lower-supported label.## Labels- Relevant: directly addresses the primary request, covers all material parts, and remains on topic.- Somewhat relevant: addresses part of the request but misses a material requirement.- Not relevant: is off-topic, evasive, or fails to address the primary request.Return one label and one sentence of reasoning.
```

user 消息只放变量：

```
User request: {{user_input}}Assistant output: {{assistant_output}}
```

judge 的 system prompt 里这四块要按业务补全：

- 评判范围：只看回答是否切题，不评事实和文风。
- 判定规则：什么情况算 Relevant，边界 case 落到哪一档。
- 标签定义：三个档位各自的意思，避免 judge 自由发挥。
- 输出格式：标签加一句理由，和 Langfuse 的 categorical score 对齐。

上线前用人工标注样本校准 judge。高风险或判断不确定的 case，交给人复核。

### 3.4 人工评测

代码和 judge 都覆盖不了的，交给人。比如退款、改签这类业务判断，抽样让客服同学标「答复是否符合政策」。Langfuse 的标注队列可以把样本分给标注人，标注结果同样写成 Score。

人工成本最高，样本也最少。它更适合校准 judge，或者处理高风险、低容错的场景。

### 3.5 基于 Trace / Observation 的过程评测

Agent 多步推理、多次工具调用时，最终结果错了，还要知道错在哪一步。

```
用户请求   │   ▼意图识别       Score: 1.0   │   ▼参数提取       Score: 0.5   │   ▼工具调用       Score: 1.0   │   ▼最终结果       Score: 0.0
```

Langfuse 也支持逐环节打分，能看出问题集中在参数提取，而不是工具调用。

边界在这里：过程评测要求应用记录足够的中间信息，并为每个步骤定义标准。Langfuse 能承载和关联这些评分，不会自动推导每一步的业务正确性。

## 四、Langfuse Eval 实践

### 4.1 五类评测任务

假设 Agent 负责理解用户请求：识别意图，抽取对应参数。初始评测集五类：

| Task | 用户输入 | 期望意图 | 需要提取的槽位 |
| --- | --- | --- | --- |
| 订机票 | 帮我订明天北京到上海的机票 |  `book_flight`  |  `date`  、  `from`  、  `to`  |
| 查天气 | 上海今天天气怎么样 |  `check_weather`  |  `city`  、  `date`  |
| 设置提醒 | 提醒我下午三点开会 |  `set_reminder`  |  `time`  、  `event`  |
| 播放音乐 | 播放周杰伦的晴天 |  `play_music`  |  `artist`  、  `song`  |
| 取消订单 | 取消订单8848 |  `cancel_order`  |  `order_id`  |

五类任务覆盖不同意图和参数结构，用来验证同一套机制能否适用于不同任务。

每个样本至少三部分： `input` 、 `expectedOutput` 、可选的  `metadata` 。订机票的期望输出：

```
{  "intent": "book_flight",  "slots": {    "date": "明天",    "from": "北京",    "to": "上海"  }}
```

### 4.2 最小评测架构

![](附件资源/Langfuse%20Eval：Agent%20评测原理与落地实践/img_3.png)

### 4.3 接入要评测的 Agent

首先，把需要评测的 Agent 接进来，接法是把 Agent 包成一个 Task 函数：Langfuse 给一条样本，Task 调一次 Agent，返回输出。

同仓库的 Agent 直接调用：

```
def task(*, item, **kwargs):    return a_agent.run(item.input)
```

Agent 不在同一个进程里，就在 Task 里换成对应的调用方式：

| Agent 形态 | Task 里做什么 |
| --- | --- |
| HTTP 接口 | 发 POST，把  `item.input`  放进请求体，取返回里的  `output`  |
| CLI | 用  `subprocess`  起进程，参数传  `item.input`  ，读 stdout |
| 容器 | 同 CLI，命令换成  `docker run --rm ...`  |

比如 Agent 提供的是 CLI：

```
$ a-agent run "帮我订明天北京到上海的机票"{"intent": "book_flight", "slots": {"date": "明天", "from": "北京", "to": "上海"}}
```

Task 核心只做三件事：把  `item.input`  转成 Agent 的输入，调用，返回输出。

### 4.4 定义 Evaluator

定义核心评测指标：

-  `json_valid`  ：输出是合法 JSON 对象，且包含必要字段。
-  `intent_match`  ：预测意图与期望意图一致。
-  `slot_f1`  ：提取槽位与期望槽位的匹配程度。

Evaluator 的形状很固定：拿输出和期望输出，返回一个  `Evaluation` 。以  `json_valid`  为例：

```
def json_valid(*, output, **kwargs):    data = json.loads(output) if isinstance(output, str) else output    valid = (        isinstance(data, dict)        and isinstance(data.get("intent"), str)        and isinstance(data.get("slots"), dict)    )    return Evaluation(name="json_valid", value=1.0 if valid else 0.0)
```

另外两个指标同一个形状： `intent_match`  比意图， `slot_f1`  逐项比槽位，只是判断逻辑不同。示例省略了解析失败处理，完整代码放在附录。

 `slot_f1`  用精确 key-value 匹配，适合当前的结构化数据。遇到日期归一化、同义词、数字格式，要先做标准化，否则语义等价的结果会被判错。

 `Evaluation`  只做一件事：把指标名和分数包起来。 `comment`  可选，用来写失败原因。

要加  `task_success` ，定义成意图和全部必需槽位都正确即可。

### 4.5 运行 Experiment

Dataset、Task、Evaluator 齐了，跑一轮数据集实验：

```
from langfuse import get_clientlangfuse = get_client()dataset = langfuse.get_dataset("agent-eval-dataset")result = dataset.run_experiment(    name="agent-eval-v1",    task=task,    evaluators=[json_valid, intent_match, slot_f1],)print(result.format())
```

执行步骤：

-  `get_dataset`  按名字取回 Dataset。每个 item 带  `input`  、  `expectedOutput`  和可选的  `metadata`  。
-  `run_experiment`  遍历这些 item，把  `input`  交给  `task`  ，由它调用 Agent。每条执行生成一条 trace，记录输入、输出和耗时；某一条报错，不影响其他样本。
- 每条输出交给三个 Evaluator，和  `expectedOutput`  比对后返回 Score。分数挂在样本的运行记录上，并关联到 trace；最后按  `agent-eval-v1`  汇总，看各指标的均值和分布。

并发、失败隔离、trace 记录由 runner 处理，你只提供  `task`  和  `evaluators` 。 `result.format()`  会把这一轮的汇总打印出来。

### 4.6 评测结果

| 指标 | 修改前 | 修改后 |
| --- | --- | --- |
| JSON 合法率 | 100% | 100% |
| 意图准确率 | 80% | 100% |
| 槽位 F1 | 85% | 75% |

修改后意图从 80% 到 100%，槽位 F1 从 85% 掉到 75%。如果只看意图，会以为新版本全面胜出；分项对比才看得见新引入的问题。

再进 Trace 看原始输出、执行步骤和调用信息，判断问题出在格式、意图还是参数提取。修完用同一批数据再跑一轮 Experiment，对比新旧版本。

评测的价值**不是给 Agent 打一个分，而是用可重复的样本发现回归，并验证修复有效。**

这组数字只用于说明分析方法，不是真实运行数据。真实项目要有足够丰富、经过校验的数据集，并按任务类型分别统计。

## 五、评测闭环

### 5.1 badcase 采集

线上 badcase 按下面的优先级采集：

| 顺序 | 来源 | 作用 | 短板 |
| --- | --- | --- | --- |
| 1 | 用户反馈 | 最强信号，能直接对回 trace | 大多数人不会反馈 |
| 2 | 客诉单 + 人工抽样 | 信息最全，能挖到根因 | 慢，样本少 |
| 3 | 自动打分 | 覆盖沉默流量 | 有误判，只做召回 |

**用户反馈。** 点赞、点踩、转人工都是明确信号，也是获取线上效果最直接的方式。

**客诉单 + 人工抽样。** 系统客诉单里有用户原话、处理过程和最终结果，信息最全。用 user_id、session_id 或时间窗把工单对回 trace，能看到投诉之前发生了什么。人工抽样补另一类：没投诉、但体验很差的会话。按意图、模型版本、时间段分层抽，避免样本只来自少数活跃用户。

**自动打分。** 对生产 trace 采样，用一个 judge 按维度打分：用户回复是否存在负面情绪/消极态度/不满的成分，工具调用是否异常，有明确业务结果的请求里工具返回与最终答复是否一致，低分进候选池。

三条路汇到同一个候选池：人工确认问题属实，补上 expectedOutput，写进 Dataset。确认过的样本才是评测样本，没确认的只是线索。数据集越积越厚，下一次改 Prompt 或换模型，就能验证这些问题有没有复发。

### 5.2 闭环链路

![](附件资源/Langfuse%20Eval：Agent%20评测原理与落地实践/img_4.png)

评测不是一次性的开发测试，而是每次 Agent 迭代优化必要执行的一步。

### 5.3 小结

Langfuse 的 Monitoring 让 Agent 的执行可见，Evaluation 让 Agent 效果可验证。Monitoring 把每次执行落成 trace，Evaluation 在 trace 上打分；badcase 从 trace 里捞出来，补进 Dataset，再用 Experiment 验证修复。监控提供原料，评测给出判断，循环转起来，Agent 的能力才有持续改进的依据。

Langfuse 的评测实现可以压成一条链路：Dataset 定义问题，Task 接入 Agent，Evaluator 判分，Score 记录，Experiment 汇总对比。评分挂在执行记录上，所以监控和评测不是两套系统，而是同一份 trace 上的两层应用。

对 Agent 系统来说，评测不是上线前的一道检查，而是迭代的基础设施。Agent 的能力不是一次设计出来的，是改出来的。Prompt、模型、工具、上下文策略，每次调整都可能局部提升、别处回归。没有评测，迭代只能靠个例和感觉；有了评测，改动才有基线，效果提升才能被量化，回归才能被拦住。

线上 Agent 系统如果需要实现自迭代的能力，先得有一套稳定的判分标准，否则只是更快地盲目试错。badcase 沉淀成 Dataset，判断标准沉淀成 Evaluator，版本差异沉淀成 Experiment，模型和 Prompt 换了，这些资产还在。评测不保证 Agent 一定有变好，但能让每次变好都有据可查，每次变差能及时暴露。

## 附录：Evaluator 样例代码

 `parse_output`  负责统一字符串和 dict，三个指标都基于它判断； `slot_f1`  用集合算 TP、FP、FN。

```
import jsonfrom langfuse import Evaluationdef parse_output(output):    if isinstance(output, dict):        return output    if isinstance(output, str):        try:            value = json.loads(output)            if isinstance(value, dict):                return value        except json.JSONDecodeError:            pass    return Nonedef json_valid(*, output, **kwargs):    data = parse_output(output)    valid = (        data is not None        and isinstance(data.get("intent"), str)        and isinstance(data.get("slots"), dict)    )    return Evaluation(        name="json_valid",        value=1.0 if valid else 0.0,        comment="Valid structured output" if valid        else "Invalid JSON or missing required fields",    )def intent_match(*, output, expected_output, **kwargs):    actual = parse_output(output)    expected = parse_output(expected_output)    correct = (        actual is not None        and expected is not None        and actual.get("intent") == expected.get("intent")    )    return Evaluation(        name="intent_match",        value=1.0 if correct else 0.0,    )def slot_f1(*, output, expected_output, **kwargs):    actual = parse_output(output)    expected = parse_output(expected_output)    if actual is None or expected is None:        return Evaluation(name="slot_f1", value=0.0)    predicted = actual.get("slots", {})    target = expected.get("slots", {})    if not isinstance(predicted, dict) or not isinstance(target, dict):        return Evaluation(name="slot_f1", value=0.0)    predicted_facts = set(predicted.items())    target_facts = set(target.items())    true_positive = len(predicted_facts & target_facts)    false_positive = len(predicted_facts - target_facts)    false_negative = len(target_facts - predicted_facts)    denominator = (        2 * true_positive + false_positive + false_negative    )    f1 = (        2 * true_positive / denominator        if denominator > 0        else 1.0    )    return Evaluation(name="slot_f1", value=f1)
```

---
原文链接：https://mp.weixin.qq.com/s?__biz=MzI5MTcwMzQ5Ng%3D%3D&mid=2247484062&idx=1&sn=a36e5d273be61dd06653705eed744447&chksm=ec0ddd39db7a542f8032374f7103179a1459ef8413d7cab0da69b36d1b54832afc15aea5ffa7
