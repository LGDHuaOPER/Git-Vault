---
title: Wiki Log
updated: 2026-07-16
---

# Wiki Log

- [2026-07-16] INIT vault_path="D:/Users/lgdhu/Documents/GitHub/Git-Vault_LLM-Wiki/Ar9av__obsidian-wiki/Default" categories=concepts,entities,skills,references,synthesis,journal
- [2026-07-16] INGEST batch 1 — 11 raw files on AI Agent observability topics distilled into pages across concepts/, entities/, skills/, references/
- [2026-07-16] INGEST batch 2 — 11 WeChat articles on AI Agent observability distilled into 10 pages (6 concepts, 3 entities, 3 references). Key topics: Agent observability fundamentals, trace/span taxonomy, LLM-as-Judge evaluation, cost breakdown, failure taxonomy, AI production engineering five-pillars framework, Langfuse deployment architecture, Litefuse vs Langfuse comparison, MCPSpy eBPF-based MCP monitoring, OpenTelemetry GenAI practical setup, Alibaba Cloud LoongCollector, and StepFun SelectDB PB-scale platform. All 11 raw files promoted to _raw/_archived/. Merged into existing batch 1 pages where collisions occurred.
- [2026-07-16] INGEST batch 3 — 11 WeChat articles on AI Agent observability (Litefuse, Langfuse, LoongSuite, AgentTrace, OTel semconv, EDD, cost-quality-trace architecture, Eino callback, AgentLogsBench, OpenClaw security, DeepSeek observability agent) distilled into 10 pages.
- [2026-07-16] DEDUP — merged 4 high-confidence duplicate pairs: langfuse, ai-agent-observability, genai-observability-semconv. 4 redirect stubs written.
- [2026-07-16] CROSS_LINK — added 20+ wikilinks and typed relationships across 9 pages; final manual pass eliminated remaining orphans.
- [2026-07-16T12:00:00+08:00] DEDUP mode=auto-merge pages_scanned=29 pairs_found=14 merged=4 kept_separate=10 needs_review=0 wikilinks_rewritten=0. Merged pairs: entities/langfuse→entities/langfuse-llm-observability, concepts/agent-observability-fundamentals+concepts/agent-observability-paradigm→concepts/ai-agent-observability, references/opentelemetry-genai-semconv→concepts/genai-observability-semconv. 4 redirect stubs written. Kept concepts/agent-trace-and-timeline vs concepts/agent-trace-span-taxonomy separate (different trace layers).
- [2026-07-16T14:00:00+08:00] CROSS_LINK pages_scanned=25 links_added=20 typed_relations_written=18 pages_modified=9 orphans_remaining=1 misc_affinity_updated=0 promotion_candidates=0
- [2026-07-17] QUERY query="什么是AI可观测" result_pages=1 mode=normal escalated=false
- [2026-07-17] INGEST source="AI Engineer编程: Agent 可观测与质量评测体系：从数据采集到数据飞轮的完整实践" pages_created=2 pages_updated=3 mode=append
  - Created: concepts/agent-online-evaluation, concepts/agent-data-flywheel
  - Updated: concepts/evaluation-driven-development (added offline pipeline, eval set, simulation env, evaluator layers), concepts/ai-agent-observability (added 3-layer architecture, TTFT/TPOT, UModel), concepts/agent-trace-cost-quality-architecture (added trajectory processing pipeline)
- [2026-07-20] QUERY query="AI 应用全链路可观测" result_pages=8 mode=normal escalated=false qmd_used=true
- [2026-07-21] QUERY query="AI 应用全链路可观测" experiments=3 result_pages=[3,8,0] mode=normal qmd_used=true qmd_transport=mcp note="escalated on last attempt due to MCP timeout"
