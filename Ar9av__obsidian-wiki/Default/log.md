---
title: Wiki Log
updated: 2026-07-23
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
- [2026-07-22] INGEST source="Inbox + WeChat Obsync (56 files)" pages_created=8 pages_updated=3 mode=append
  - Created: concepts/agent-causal-attribution, concepts/agent-evaluation-framework, concepts/rag-observability, references/caict-llm-observability-standard, entities/greptimedb, references/spring-ai-otel-langfuse, references/dify-phoenix-integration, entities/arize-phoenix
  - Updated: concepts/ai-agent-observability (added CAICT standard, Alibaba 1-5-10 framework, GenAI observability 2.0 three pillars), concepts/genai-observability-semconv (added OTel GenAI six-layer structure), concepts/agent-harness (added ETCLOVG framework, 8-dimension capture model)
  - Key new topics: CAICT LLM observability standard, OTel GenAI six-layer architecture (Client/Agent/MCP/Events/Metrics/Provider), GreptimeDB unified observability database, Spring AI production observability, Dify+Phoenix integration, Arize Phoenix platform, Agent causal attribution, Agent evaluation framework (Anthropic+Alibaba), RAG observability

- [2026-07-22] INGEST source="WeChat Obsync + Inbox" files=89 pages_created=65 pages_updated=15 mode=append
  - New by category: 9 concepts, 21 entities, 32 references, 3 skills
  - New pages (sample): concepts/agent-evaluation-framework, concepts/agent-observability-metrics, concepts/ai-coding-agent-observability, concepts/ai-observability-layered-architecture, concepts/ebpf-observability-agent, concepts/genai-observability-2.0, concepts/llm-observability-tool-selection, concepts/observability-3-0, concepts/umodel, entities/acs-agent-sandbox, entities/alicloud-cloudmonitor-ai-agent-observability, entities/automq, entities/bonree-one, entities/coze-loop, entities/deepflow, entities/dify, entities/greptimedb, entities/helicone, entities/langsmith, entities/loongsuite-pilot...
  - Updated pages (sample): concepts/agent-failure-taxonomy, concepts/agent-harness, concepts/agent-trace-span-taxonomy, concepts/ai-agent-observability, concepts/ai-production-engineering-five-pillars, concepts/genai-observability-semconv, concepts/llm-as-judge-evaluation, entities/ai-observe-stack, entities/apache-doris-agent-observability, entities/langfuse-llm-observability...
- [2026-07-22] CROSS_LINK pages_scanned=101 links_added=96 typed_relations_written=96 pages_modified=54 orphans_remaining=0 misc_affinity_updated=0 promotion_candidates=0

- [2026-07-23] LINT issues_found=43 orphans=21 broken_links=0 stale=0 contradictions=0 prov_issues=0 missing_summary=4 fragmented_clusters=2 visibility_issues=0 promotion_candidates=0 synthesis_gaps=1 relationship_issues=20 lifecycle_issues=4
- [2026-07-23] WIKI_SYNTHESIZE pages_scanned=101 synthesis_created=5 candidates_skipped=15 cluster=ai-agent(67) co_occurrence_pairs=69
  - Created: synthesis/genai-observability-semconv-x-langfuse-llm-observability, synthesis/ai-agent-observability-x-langfuse-llm-observability, synthesis/ai-agent-observability-x-dify, synthesis/llm-as-judge-evaluation-x-langfuse-llm-observability, synthesis/ai-agent-observability-x-arize-phoenix
  - Back-linked from: concepts/genai-observability-semconv, entities/langfuse-llm-observability, concepts/ai-agent-observability, entities/dify, concepts/llm-as-judge-evaluation, entities/arize-phoenix
- [2026-07-23] CROSS_LINK pages_scanned=101 links_added=45 typed_relations_written=44 pages_modified=21 orphans_remaining=0 misc_affinity_updated=0 promotion_candidates=0
  - TARGET A (fragmented #observability cluster, 5 pages → connected): concepts/ai-agent-observability, concepts/observability-3-0, references/7-llm-observability-tools, skills/agent-observability-landing-guide, skills/openclaw-observability-setup-tencent-cloud. 13 cross-links + 13 typed relations.
  - TARGET B (orphan rescue): 21 pages with 0 incoming content links rescued via 32 wikilinks (8 inline + 1 broken-link fix + 23 Related-section) + 31 typed relations. All 21 now have ≥1 incoming content link.
