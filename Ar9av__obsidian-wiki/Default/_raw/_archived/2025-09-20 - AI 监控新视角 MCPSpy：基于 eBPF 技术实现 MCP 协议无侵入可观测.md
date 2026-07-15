---
source_url: "https://mp.weixin.qq.com/s?__biz=MzA3NzUzNTM4NA==&mid=2649615785&idx=1&sn=5baf1c7175b5308e5d92711d79d23364&chksm=866a713402b3d16c0254d2e3f2c6302b490ef053a20a12649d927a58972b126b8baa43baca72&mpshare=1&scene=1&srcid=0921ahtt4g4HnJj4mG5B4B37&sharer_shareinfo=769804acade90317c682a34ca0b9c849&sharer_shareinfo_first=769804acade90317c682a34ca0b9c849"
title: "AI 监控新视角 MCPSpy：基于 eBPF 技术实现 MCP 协议无侵入可观测"
account: "深入浅出BPF"
published_at: "2025-09-20T03:43:56.000Z"
saved_at: "2026-07-15T15:33:34.555Z"
sync_id: "art_f4c81a554d8b4a9298f9a59d8238c682"
parse_status: "ok"
---

# AI 监控新视角 MCPSpy：基于 eBPF 技术实现 MCP 协议无侵入可观测

## 1. 前言

在本系列的第一部分中，我将会分享 **MCPSpy**[1] 的动机和设计，MCPSpy 工具我开发的用于监控**模型上下文协议 （MCP）**[2] 流量的开源工具。本文我会从 MCP 重要性，使用 eBPF 监控 MCP 原因，MCPSpy 简易版本实现，以及存在的限制方面进行介绍。未来的章节将探讨例如通过 TLS 检查基于 HTTPS 的加密 MCP 通信等其他功能。首先，让我们先从 MCP 及 MCPSpy 相关的基础知识开始介绍。

## 2. 为什么要关注 MCP？

**MCP** （模型上下文协议）是 AI 领域通信的一种新的协议标准，其定义了 AI 应用程序（客户端）如何与外部工具和数据源（服务器）通信。MCP 基于 JSON-RPC 2.0 构建交换消息，定义服务器可以向 AI 客户端公开的 **工具（Tools）**、**资源（Resources）** 和 **提示词（Prompts）** 等核心原语。换句话说，MCP 为 AI 助手提供了一个_统一的界面_ ，用于调用函数、获取数据或使用来自外部服务的预定义的提示词。

基于 MCP 协议的优势是为每个 AI 产品提供了都可以使用**通用协议** ，而不是每个 AI 产品为每个**外部服务**编写**自定义集成**代码。这类似于不同的 Web 服务在 HTTP 上标准化的方式—使用者不会为 GitHub、Slack 和 Google Maps 单独编写自定义网络栈。你只需对所有人使用 HTTP 协议即可。同样，AI 客户端和工具可以通过 MCP 而不是自定义 API 进行交互。

![](附件资源/AI%20监控新视角%20MCPSpy：基于%20eBPF%20技术实现%20MCP%20协议无侵入可观测/img_1.png)

图片来自：https://www.claudemcp.com/zh/blog/mcp-vs-api[3]

**MCP 的应用正在快速增长**。大多数人工智能平台已经支持 MCP。例如，**Claude Desktop**、**GitHub Copilot**、**Cursor** 和许多其他工具可以充当 **MCP 客户端** ，与各种 **MCP 服务器** （工具）无缝连接。 MCP 成为已成为第三方功能的 AI 助手的事实上的标准。

### 2.1 安全的 MCP（Security MCP） ![](附件资源/AI%20监控新视角%20MCPSpy：基于%20eBPF%20技术实现%20MCP%20协议无侵入可观测/img_2.svg)

但是随着人工智能创新的步伐和 MCP 的快速发展，在观测和理解 AI 工具方面却捉襟见肘。当 AI 助手使用 MCP 执行时，我们如何知道它正在发送或接收哪些数据？它是否存在做意外或恶意的事情的潜在风险？ 例如，LLM 客户端（在本例中为 Cursor）在运行 MCP 命令（使用 GitHub MCP）的场景，但在我们确认并执行分析数据之前，我们其实并不会知道发送了哪些实际数据：

![](附件资源/AI%20监控新视角%20MCPSpy：基于%20eBPF%20技术实现%20MCP%20协议无侵入可观测/img_3.png)

在用户确认前进行运行操作，这是一个很好的场景，但我们相信用户确认批准的情况同会越来越少，尤其是在**后台 AI 代理** （如 Cursor 后台代理或 OpenAI 的 Codex）时代。

另一个问题是**检测 AI 精心策划的异常或危险工具使用**。假设 AI 助手使用 GitHub MCP 服务器 [4]，该服务目前提供 **80 多种不同的工具** （！用于各种 GitHub 操作作）。即使你通过确认尝来允许某些工具来运行，但只需要一个强大的工具使用不当也会造成损坏（例如， `create_or_update_file`  工具）。

![](附件资源/AI%20监控新视角%20MCPSpy：基于%20eBPF%20技术实现%20MCP%20协议无侵入可观测/img_4.png)

此外，AI Agent 可能会**产生幻觉**或犯错误并更新**错误的文件**或发出**破坏性命令** 。更糟糕的是，如果 AI 获得了 MCP 服务器的**特权访问令牌** ，那么除了我们相信 AI 不会行为不端之外， _没有什么技术_可以阻止其滥用该令牌。我们都知道人工智能模型是不可预测的——尽管它们无意搞破坏，但意想不到的举动也无法彻底避免。如果 AI  Agent 决定（或被提示）执行一系列有害的工具调用，我们将如何捕获它？

**上述的这些挑战促使我来创建 MCPSpy 工具**。我的目标是构建可以_迭代改善我们_围绕 AI 能力使用的安全态势的工具：首先是获得对 MCP 通信的可见性，其次是检测可疑活动，最终是防止真正的恶意行为。 **可见性是第一步** — 我们无法保护看不到的东西。

在深入了解 MCPSpy 工作原理之前，值得一提的是 MCPSpy **没有涵盖**如下的内容：

- 仅支持 Linux： MCPSpy 依赖于 Linux 内核的 eBPF 技术。MCPSpy 还无法在 Windows 或 macOS 上运行。（正在进行将 [5] eBPF 功能引入 Windows 的工作，但目前还远未达到与 Linux 的功能对等）
- 不覆盖恶意 MCP 服务器： MCPSpy 是关于监控 协议的使用情况 ，而不是验证服务器本身。如果你连接到恶意 MCP 服务器（旨在窃取数据或运行有害代码的服务器），则这是一种不同的威胁模型。假设你正在运行受信任的 MCP 服务器，通过代码审查、沙盒或其他运行时保护等手段进行防护完全是另一个挑战，而不是 MCPSpy 的用途。
- 不涉及 MCP 服务器中的漏洞： 同样，如果 MCP 服务器存在漏洞（例如可能导致 RCE 的注入），MCPSpy 在这方面也无能为力。

## 3. 为什么选择 eBPF

在考虑监控主机上 MCP 流量的所有方法时，我们当然有多种方案可选。最终，我选择了使用 **eBPF**，但值得通过替代方案分析来了解选择 eBPF 的 _原因_ 。

### 3.1 LD_PRELOAD 钩子（Hooking） ![](附件资源/AI%20监控新视角%20MCPSpy：基于%20eBPF%20技术实现%20MCP%20协议无侵入可观测/img_5.svg)

该方式是通过  `LD_PRELOAD`  机制将共享库注入进程来拦截相关功能。从理论上讲，这可以让我们在用户空间中包装  `read（）` / `write（）`  或更高级别的 MCP 库调用等函数。

然而，这种方法有明显的缺点：

- 需要使用自定义 LD_PRELOAD 库启动要监视的每个进程，这在许多情况下是不切实际的，特别是当你需要附加到生产环境中的进程而不修改它们的启动方式时。
- 无法挂接到内核内部探针，内核探针有时会提供对内核结构的更多控制和可见性（例如，获取 inode 编号）。
- 开发复杂化，因为该机制需要针对各种 libc 和发行版进行测试。

### 3.2 自定义内核模块 ![](附件资源/AI%20监控新视角%20MCPSpy：基于%20eBPF%20技术实现%20MCP%20协议无侵入可观测/img_6.svg)

另一个方案是编写一个 **Linux 内核模块**来监控 MCP 流量。虽然这种方案完全可行，但开发自定义模块是一项繁重的任务：

- 学习曲线陡峭，而且风险很大—一个错误可能会使整个系统崩溃，因此你需要非常小心并针对许多内核版本进行测试。
- 挂接到用户模式事件并非易事，这是监控加密 TLS 流量（对于远程 MCP 调用）所必需的。

### 3.3 eBPF ![](附件资源/AI%20监控新视角%20MCPSpy：基于%20eBPF%20技术实现%20MCP%20协议无侵入可观测/img_7.svg)

随着过去几年 Linux 的快速发展，eBPF[6]（Extended Berkeley Packet Filter）已经彻底改变了我们**检测和监控内核**的方式。eBPF 允许我们在**运行时将小型安全程序加载到内核**中 ，并将它们附加到各种**钩子** （通过 uprobes 的内核和用户空间）。

关键是 eBPF 程序在运行前要经过内核**验证器的**安全性验证——保障 eBPF 程序不会使系统崩溃，并且它们能做的事情受到限制（没有无限循环、有界内存访问等）。因此，即使在生产环境中也可以安全地使用它们。

总结一下：**eBPF 就是这样。** 现在让我们看看我如何使用 eBPF 来跟踪 MCP 流量，以及 MCPSpy 是如何在幕后实现的。

![](附件资源/AI%20监控新视角%20MCPSpy：基于%20eBPF%20技术实现%20MCP%20协议无侵入可观测/img_8.png)

图片来自: https://ebpf.io/what-is-ebpf/[7]

## 4. 实施阶段

我们生活在 AI 辅助编码的时代。事实上，我依靠 **Cursor + Claude Sonnet** 来支撑这个项目，包括生成许多样板。尽管如此， **使用 AI 编写 eBPF 代码**可能很棘手。人工智能可以训练的代码库并不多，编写 eBPF  代码需要对 Linux 代码库有深入的了解，而理解验证者错误的神秘消息需要专业知识。因此，虽然欢迎你使用代码助手编写 eBPF，但当你遇到让您发疯的神秘验证器错误时， 请准备好投入其中 。

以下是 MCPSpy 的**高级**架构，包含以下**逻辑层** ：

- eBPF 程序和 maps： 核心监控程序 。
- eBPF 加载器（用户空间）： 将 eBPF 程序加载到内核中的 Go 程序 。
- 事件处理程序： 用户空间中监听来自 eBPF 程序的事件的组件。
- MCP 解析器： 一个解析器，可获取捕获的原始数据并根据 MCP 协议对其进行解释。
- 展示层： 以有用的格式输出解析后的信息。

### 4.1 MCP 监控程序设计 ![](附件资源/AI%20监控新视角%20MCPSpy：基于%20eBPF%20技术实现%20MCP%20协议无侵入可观测/img_9.svg)

在编写第一个 eBPF 代码之前，我们需要考虑我们想要监控内容。

MCP 支持**两种主要的传输机制，** 如规范中[8]所述：

- Stdio: 客户端和服务器通过读取和写入 MCP 服务器进程的 标准流 （stdin/stdout） 进行通信。因此，通过 stdio 监控 MCP 归 结为拦截这些文件描述符上的所有读写调用。
- 流式传输 HTTP： 客户端使用 HTTP 将 请求 传达给服务器，服务器使用 服务器发送事件 （SSE） 流式 传输 回客户端。我们将在接下来的几章中探讨这种方法。

在 MCPSpy 的第一次迭代中，我将重点介绍了 **Stdio 传输** ，因为这是当今本地 MCP 服务器中最常见的传输。

### 4.2 eBPF 程序 ![](附件资源/AI%20监控新视角%20MCPSpy：基于%20eBPF%20技术实现%20MCP%20协议无侵入可观测/img_10.svg)

我们可以在 eBPF 中使用许多不同的**程序类型和钩子** ，但我们不会在这里涵盖它们——如你想要更广泛的概述，可在 eunomia.dev[9] 获取更多优秀资源。对于 MCPSpy，关键问题是： _我们应该在内核中的哪个位置挂钩才能看到 MCP stdio 流量？_

问题的答案在于 Linux 虚拟文件系统 （VFS）。用户空间中的所有  `read（）`  和  `write（）`  系统调用最终都流经内部内核函数  `vfs_read`  和  `vfs_write` 。因此，通过将 eBPF 程序附加到  `vfs_read`  和  `vfs_write` ，我们可以观察文件系统中发生的每一个读写作。

让我们以  `vfs_read`  的流程为例，并附上注释进行解释：

```
// "SEC" is a macro to place this function in a specific ELF section
// so the eBPF loader knows it's an eBPF program for fexit.
SEC("fexit/vfs_read")

// BPF_PROG is an helper macro which expands the signature of vfs_read parameters,
// so we can use them directly within the program.
intBPF_PROG(exit_vfs_read, struct file *file, constchar *buf, size_t count,
loff_t *_pos, ssize_t ret) {

// The reason we use fexit for this program is:
// - fentry / fexit are more performant than kprobe / kretprobe
// - we have access to entry parameters within fexit context.
//   if we were using kprobe, we should hook both kprobe and kretprobe
//   and transfer entry params to the exit hook which is less efficient.
if (ret header.event_type = EVENT_READ;
event->header.pid = bpf_get_current_pid_tgid() >> 32;
bpf_get_current_comm(&event->header.comm, sizeof(event->header.comm));

// Because we are limiting the actual copied size,
// we preserve the original size as well.
event->size = ret;

// To satisfy the verifier, we need to bound the buffer to resonable size.
event->buf_size = ret buf, event->buf_size, buf);

bpf_ringbuf_submit(event, 0);

return0;
}
```

就是_这样！这就是 eBPF 的美妙之处_ 。

### 4.3 eBPF 加载器 ![](附件资源/AI%20监控新视角%20MCPSpy：基于%20eBPF%20技术实现%20MCP%20协议无侵入可观测/img_11.svg)

为了快速编写 MCPSpy，我使用了 cilium/eBPF 项目附带的 **bpf2go**[10] 工具。结合  `loader.go`  中的  `go：generate`  指令，很容易生成 Go 样例代码，可用于编译 C 语言编写的 eBPF 代码、创建绑定并将程序和 maps 直接发布为 Go 语言对象。

当然，你仍然需要编写实际的代码来将这些程序附加到正确的内核钩子上。在 MCPSpy 的案例中，这意味着通过跟踪附件将我们的程序挂钩到  `vfs_read` （和  `vfs_write` ）：

```
// Attaching exit_vfs_read with Fexit
readEnterLink, err := link.AttachTracing(link.TracingOptions{
Program:    l.objs.ExitVfsRead,
AttachType: ebpf.AttachTraceFExit,
})
if err != nil {
return fmt.Errorf("failed to attach %s tracepoint: %w",
l.objs.ExitVfsRead.String(), err)
}
l.links = append(l.links, readEnterLink)
```

### 4.4 事件处理 ![](附件资源/AI%20监控新视角%20MCPSpy：基于%20eBPF%20技术实现%20MCP%20协议无侵入可观测/img_12.svg)

事件处理程序本质上是一个在**单独的 goroutine** 中运行的循环，它等待来自内核的事件并处理它们。以下是事件处理程序循环在 MCPSpy 中的简化版本：

```
// The handler must run as a seperate go routine
gofunc() {
...
// infinite loop, until the context is cancelled.
for {
select {
case

// Producing the events for further analysis.
select {
case l.eventCh 最后，我们需要解释捕获的内容。幸运的是，该协议相对简单，可参考此处的文档介绍[11]。

请记住，对于 stdio 传输， **我们在读/写事件中看到的数据**正是 **MCP 的 JSON-RPC 消息**的 JSON 文本。

MCP（即 JSON-RPC 2.0）具有简单的消息格式：

- 有带有 methord 和 id 的 请求 ，如下所示：

```
{
"id": 6,
"jsonrpc": "2.0",
"method": "tools/list"
}
```

- 有带有 id 和 结果 或 result 的 响应 ，但没有 methord 字段，如下所示：

```
{
"id":6,
"jsonrpc":"2.0",
"result":{
"tools":[
{
// ...
}
]
}
}
```

- 此外还有一些 通知 类似于请求，但没有 id ，因为它们不期望得到响应。例

```
{
"jsonrpc":"2.0",
"method":"notifications/message",
"params":{
"data":"Completed get_weather operation",
"level":"info"
}
}
```

MCP 在 JSON-RPC 之上定义了一组特定的**方法名称** 。一些关键方法包括：

- initialize – 用于启动连接（客户端和服务器之间的握手、交换功能等）。
- tools/list – 来自客户端的请求，用于从服务器获取可用工具的列表。
- tools/call – 在服务器上执行特定工具的请求。
- 其他原语也存在类似的模式，例如 resources/get 或 prompts/list 等，如 MCP 模式中定义的 schema.ts [12] 。

但基于我们捕获数据的方式需要注意的是 ：我们看到每条消息**两次** ——一次是在一端写入时，一次是在另一端读取时。例如，当客户端发送   `tools/call`   请求时，我们的 eBPF 钩子将捕获来自客户端进程的**写入** ，不久之后，服务器进程将**读取**该数据，这再次触发我们的钩子。

为了处理这个问题，MCPSpy 的解析器实现了一种简单的**关联机制** ：当收到写入事件时，存储消息（由内容的哈希键）并等待匹配的读取事件。一旦在读取的时候发现对应的消息，我们就会跳过继续处理。此机制还帮助我们识别客户端和服务器的进程名称和 PID。

### 4.6 展示层 ![](附件资源/AI%20监控新视角%20MCPSpy：基于%20eBPF%20技术实现%20MCP%20协议无侵入可观测/img_13.svg)

解析 JSON 并关联对后， **展示层**接管。目前，MCPSpy 有两种输出模式：**人性化的控制台和 JSON 行**日志模式输出。

![](附件资源/AI%20监控新视角%20MCPSpy：基于%20eBPF%20技术实现%20MCP%20协议无侵入可观测/img_14.png)

## 5. 总结

**实时查看 MCP 通信的能力是**提高 AI 驱动工具安全性和透明度的第一步。在本系列的下一部分中，我将分享扩展 MCPSpy 以处理 **TLS 加密的 HTTP 传输**的过程，这带来了一系列挑战（提示：我们可能会为像 OpenSSL 这样的库提供用户空间 uprobe 钩子来动态解密）。这有望成为 eBPF 和安全领域同样有趣的冒险。

作者：Alex Ilgayev

原文地址：https://blog.alexil.me/monitoring-mcp-traffic-using-ebpf-part-1-c445b76377cf[13]

### 引用链接 ![](附件资源/AI%20监控新视角%20MCPSpy：基于%20eBPF%20技术实现%20MCP%20协议无侵入可观测/img_15.svg)

[1]MCPSpy: _https://github.com/alex-ilgayev/mcpspy_

[2]模型上下文协议 （MCP）: _https://modelcontextprotocol.io/_

[3]_https://www.claudemcp.com/zh/blog/mcp-vs-api_

[4]GitHub MCP 服务器 : _https://github.com/github/github-mcp-server_

[5]将 : _https://github.com/microsoft/ebpf-for-windows_

[6]eBPF: _https://ebpf.io/_

[7]_https://ebpf.io/what-is-ebpf/_

[8]规范中: _https://modelcontextprotocol.io/specification/2025-06-18/basic/transports_

[9]eunomia.dev: _https://eunomia.dev/_

[10]bpf2go: _https://github.com/cilium/ebpf/tree/main/cmd/bpf2go_

[11]文档介绍: _https://modelcontextprotocol.io/docs/getting-started/intro_

[12]schema.ts: _https://github.com/modelcontextprotocol/modelcontextprotocol/blob/main/schema/2025-06-18/schema.ts_

[13]_https://blog.alexil.me/monitoring-mcp-traffic-using-ebpf-part-1-c445b76377cf_

---
原文链接：https://mp.weixin.qq.com/s?__biz=MzA3NzUzNTM4NA%3D%3D&mid=2649615785&idx=1&sn=5baf1c7175b5308e5d92711d79d23364&chksm=866a713402b3d16c0254d2e3f2c6302b490ef053a20a12649d927a58972b126b8baa43baca72
