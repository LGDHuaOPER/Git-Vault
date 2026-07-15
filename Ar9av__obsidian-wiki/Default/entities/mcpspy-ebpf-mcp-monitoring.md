---
title: "MCPSpy: eBPF-based MCP Monitoring"
category: entities
tags:
  - ai-agent
  - observability
  - ebpf
  - mcp-protocol
  - kernel-tracing
sources:
  - "深入浅出BPF: AI 监控新视角 MCPSpy：基于 eBPF 技术实现 MCP 协议无侵入可观测 (2025-09-20)"
summary: "MCPSpy——基于 eBPF 内核技术的 MCP 协议无侵入可观测工具。在操作系统内核层面拦截 MCP 协议的 JSON-RPC 通信，无需修改任何应用代码即可捕获完整的 MCP 交互轨迹。"
base_confidence: 0.47
lifecycle: draft
lifecycle_changed: "2026-07-16"
tier: supporting
provenance:
  extracted: 0.3
  inferred: 0.5
  ambiguous: 0.2
created: 2026-07-16
updated: 2026-07-16
---

# MCPSpy: eBPF-based MCP Monitoring

MCPSpy 是一个基于 eBPF 技术实现的 MCP（Model Context Protocol）协议无侵入可观测工具 ^[extracted]。它通过在 Linux 内核层面拦截 MCP 协议的 JSON-RPC 通信，实现零代码改造的全量 MCP 流量监控。

## 技术原理

### 为什么选择 eBPF

eBPF（Extended Berkeley Packet Filter）允许在 Linux 内核中安全地运行沙箱化程序，无需修改内核源码或加载内核模块。相比其他方案：

| 方案 | 侵入性 | 稳定性 | 覆盖范围 |
|------|--------|--------|---------|
| LD_PRELOAD Hook | 用户态 Hook，需重启进程 | 中等 | 仅覆盖动态链接的可执行文件 |
| 自定义内核模块 | 内核态，风险高 | 低（可能导致内核崩溃） | 全量 |
| **eBPF** | 内核态，沙箱化 | 高（内核验证器保证安全） | 全量，无需应用配合 |

### MCPSpy 工作流程

1. **eBPF 程序加载**：通过 eBPF 加载器将监控程序注入内核，挂载到 `read()`/`write()` 等系统调用
2. **MCP 流量识别**：在内核层面解析 JSON-RPC 协议帧，识别 MCP 特定的方法调用（`tools/list`, `tools/call`, `resources/read` 等）
3. **事件提取**：提取 MCP 请求/响应的关键字段（方法名、参数、返回状态），构建事件并发送到用户态处理程序
4. **事件处理与导出**：用户态程序将事件转换为结构化 Trace，导出到 [[opentelemetry-genai-agent-setup|OpenTelemetry]] 或可观测后端

## 关键技术点

- **协议解析**：基于 MCP 规范的 JSON-RPC 2.0 帧格式解析，参考 `schema.ts` 中的类型定义 ^[extracted]
- **eBPF Maps**：使用 BPF maps 在内核和用户态之间传递数据，使用 per-CPU maps 避免锁竞争
- **事件关联**：通过 JSON-RPC `id` 字段将请求和响应对齐为一个完整的 MCP 操作 Span

## 适用场景

- MCP 服务器的安全审计——捕获所有工具调用和资源访问 ^[inferred]
- MCP 客户端的行为分析——了解 Agent 如何使用外部工具
- 性能瓶颈定位——识别慢速 MCP 操作
- 无需修改 MCP 客户端/服务器代码的零侵入部署

## 局限性

- 仅支持 Linux（eBPF 依赖 Linux 内核 4.x+）
- 需要 CAP_BPF 或 root 权限
- 协议解析依赖 MCP 规范的稳定性——协议变更需要更新 eBPF 程序
- 对于加密通信（TLS），eBPF 需要在加密前/解密后的 Hook 点捕获 ^[inferred]

## 相关页面

- [[agent-observability-fundamentals]] — Agent 可观测性基础
- [[agent-trace-span-taxonomy]] — Trace/Span 结构
- [[langfuse-platform]] — 应用层可观测平台
- [[opentelemetry-genai-agent-setup]] — 标准化观测协议
