---
title: Hot Cache
updated: 2026-07-17T16:00:00+08:00
---

# Hot Cache

## Recent Activity

- [2026-07-17] INGEST — "Agent 可观测与质量评测体系：从数据采集到数据飞轮的完整实践" from AI Engineer编程. Created 2 pages (agent-online-evaluation, agent-data-flywheel), updated 3 pages (evaluation-driven-development with offline pipeline/eval set/evaluator taxonomy, ai-agent-observability with 3-layer architecture/TTFT/UModel, agent-trace-cost-quality-architecture with trajectory processing). Now at 30 knowledge pages.
- [2026-07-16] CROSS_LINK — cross-linked 20+ mentions across 9 pages. 18 typed relationships written. Zero orphans.
- [2026-07-16] INGEST batches 1-3 — full AI Agent observability theme ingest from ~33 WeChat articles.

## Active Threads

- **AI Agent Observability** — 30 pages across 4 categories. Full stack coverage: data collection (3-layer architecture), trace design, evaluation (offline + online + data flywheel), production engineering, platform comparisons.
- **Evaluation methodology** — EDD expanded with complete offline pipeline (CI/CD quality gates, eval set 3-element model, simulation environment, evaluator layered strategy, Skills repo practice). Online evaluation and data flywheel now have dedicated pages.
- **Open source platforms** — Langfuse, Litefuse, LoongSuite, AgentTrace, MCPSpy as key reference implementations.

## Key Takeaways

- Agent failures are semantic, not system-level — HTTP 200 can mask wrong answers
- EDD (Evaluation Driven Development): observe → evaluate → attribute → optimize
- Litefuse's single-process mode (358MB binary, 25s) dramatically lowers private deployment barriers
- OpenTelemetry GenAI Semantic Conventions are now the industry standard post-CNCF graduation
- Langfuse v3 multi-component deployment requires careful container networking (service names vs host IPs)
- MCPSpy demonstrates that eBPF can provide zero-instrumentation MCP protocol monitoring at kernel level
- Cost optimization is not just reducing spend — 40-60% savings via intelligent model routing

## Flagged Contradictions

- Langfuse vs Litefuse cost claims: Litefuse claims 65-88% storage cost reduction, but this is based on vendor-published benchmarks. Real-world savings depend on deployment scale and workload patterns.
