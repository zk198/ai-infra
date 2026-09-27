# AI Infrastructure

Local integration composition for the AI stack, including the RAG platform, agent/tool services, gateway, UI, and optional local LLM runtime.

The application repositories own their service Compose definitions. This repository uses Compose `include` rather than duplicating those service definitions.

## Layout

Check out these repositories as siblings:

```
ai-infra/
rag-ingestion/
rag-indexer/
rag-retrieval/
ai-gateway/
agent-core/
agent-tools-web/
agent-tools-code/
ai-ui/
llm-gateway/
llm-inference/
```

Then copy `.env.example` to `.env`, set a real JWT secret, and run the base stack:

```
docker compose up --build
```

For the complete local stack, including Bifrost and GPU-backed SGLang, check out `llm-gateway/` and `llm-inference/` as siblings and run:

```
docker compose -f compose.yaml -f compose.llm.yaml up --build
```

`compose.llm.yaml` includes the private LLM service definitions and adds the internal DNS aliases expected by `agent-core` (`llm-gateway`) and Bifrost (`llm-inference`). It removes their host port publishing; they remain reachable on the internal Compose network. The GPU requirement is isolated to `llm-inference`; Bifrost itself is a CPU/network gateway.

The AI gateway is exposed on port 8200; internal agent/tool services are not published to the host. PostgreSQL remains the authoritative source of truth and Qdrant is a rebuildable search index.

Qdrant is pinned to v1.19.1 for reproducible local integration. Production image digests and registry-based deployment are handled in Part 2.
