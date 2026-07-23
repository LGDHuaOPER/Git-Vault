---
title: Hot Cache
updated: 2026-07-23T16:30:00.000Z
---

# Hot Cache

## Recent Activity

- [2026-07-23] CROSS_LINK — Rescued all 21 orphan pages (0 incoming content links → ≥1 each, 79 incoming links total) and connected the fragmented 5-page #observability cluster (cohesion 0 → fully inter-linked). 45 wikilinks added across 21 pages with 44 typed relationships. Fixed a malformed wikilink in concepts/observability-3-0 pointing to references/2026-05-18-openobserve-llm-vs-traditional-observability.
- [2026-07-23] WIKI_SYNTHESIZE — Synthesized 5 cross-cutting pages from the #ai-agent cluster (67 pages, 69 co-occurrence pairs): GenAI SemConv × Langfuse (standard vs product), AI Agent Observability × Langfuse (theory vs implementation), AI Agent Observability × Dify (observability vs abstraction), LLM-as-Judge × Langfuse (evaluation-observability loop), AI Agent Observability × Arize Phoenix (general vs RAG-specialized). Back-linked from 6 source pages. 15 candidates skipped for future runs.
- [2026-07-22] CROSS_LINK — Cross-linked 96 mentions across 54 pages; 0 orphans remain. Connected newly ingested WeChat article pages to existing concepts/entities via inline wikilinks and typed relationships.


## Active Threads

- **AI Agent Observability** — 106 pages across 5 categories (now includes synthesis/). Comprehensive coverage spans data collection (3-layer architecture), trace/span design, evaluation (offline + online + data flywheel + causal attribution + LLM-as-Judge), production engineering, platform comparisons, industry standards (CAICT), and OTel GenAI six-layer architecture. 5 synthesis pages now connect cross-cutting themes: standard-vs-product, theory-vs-implementation, observability-vs-abstraction, evaluation-observability loop, general-vs-RAG-specialized.
- **Synthesis gaps** — 15 co-occurrence pairs identified but not yet synthesized. Top skipped: GenAI SemConv × Dify, LLM-as-Judge × Arize Phoenix, EDD × Langfuse, AI Agent Observability × Helicone, AI Agent Observability × Litefuse. Candidates for next synthesis run.
- **Langfuse ecosystem** — Deep coverage of Langfuse deployment, integration patterns, self-hosting, lifecycle observability, and comparison with Litefuse.
- **OpenTelemetry GenAI** — Standardized observability for LLM/Agent/MCP with six-layer semantic conventions.
- **eBPF + LLM observability** — Kernel-level zero-instrumentation monitoring for MCP protocols and Agent behavior via DeepFlow, MCPSpy, and AutoMQ meetup insights.
- **Production platforms** — Alibaba Cloud (LoongSuite, CloudMonitor, ARMS), Tencent Cloud, OpenObserve, GreptimeDB, Arize Phoenix, SigNoz, and open-source deployment patterns.


## Key Takeaways

- Agent failures are semantic, not system-level — HTTP 200 can mask wrong answers
- EDD (Evaluation Driven Development): observe → evaluate → attribute → optimize
- **NEW**: Agent causal attribution goes beyond failure location to "why it failed" — AgentRx, TraceElephant, Causal Agent Replay (CAR) with structural causal models
- **NEW**: RAG observability is a distinct layer — Context Precision, Faithfulness, Answer Relevance, silent retrieval failure detection
- **NEW**: OTel GenAI SemConv six-layer structure: Client Spans → Agent & Workflow Spans → MCP → Events → Metrics → Provider-specific
- **NEW**: CAICT standard defines five-layer observability capability model: Infrastructure → Middleware → Model → Model Service → Application
- Litefuse's single-process mode (358MB binary, 25s) dramatically lowers private deployment barriers
- OpenTelemetry GenAI Semantic Conventions are now the industry standard post-CNCF graduation
- Langfuse v3 multi-component deployment requires careful container networking (service names vs host IPs)
- MCPSpy demonstrates that eBPF can provide zero-instrumentation MCP protocol monitoring at kernel level
- Cost optimization is not just reducing spend — 40-60% savings via intelligent model routing
- **NEW**: GreptimeDB unifies traces/metrics/logs in one database with cross-signal SQL queries and Flow stream processing
- **NEW**: Arize Phoenix offers OTel-native observability with deep RAG analysis (document chunk visualization, relevance scoring)

- **NEW**: 89 WeChat articles distilled into 101-page wiki — major expansion of AI/LLM observability coverage
- **NEW**: Langfuse ecosystem now includes deployment guides, integration patterns, self-hosting, and comparison with Litefuse
- **NEW**: OpenTelemetry GenAI six-layer architecture (Client/Agent/MCP/Events/Metrics/Provider) is the emerging standard
- **NEW**: eBPF enables zero-instrumentation observability for AI Agents at the kernel level (DeepFlow, MCPSpy)
- **NEW**: Agent evaluation spans offline metrics, online monitoring, data flywheels, causal attribution, and LLM-as-Judge
- **NEW**: Production observability platforms from Alibaba Cloud, Tencent Cloud, OpenObserve, GreptimeDB, and Arize Phoenix offer differentiated approaches
- **NEW**: AI customer service evaluation requires moving from hard rules to LLM Judge for semantic correctness

## Flagged Contradictions

- Langfuse vs Litefuse cost claims: Litefuse claims 65-88% storage cost reduction, but this is based on vendor-published benchmarks. Real-world savings depend on deployment scale and workload patterns.
- OTel GenAI SemConv is still in Development status (not yet Stable) — attribute names and structures may change. Production environments should use `OTEL_SEMCONV_STABILITY_OPT_IN` to manage version transitions.