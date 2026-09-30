# AI Infrastructure

Local integration composition for the AI stack, including the RAG platform, agent/tool services, gateway, UI, and optional local LLM and Laya runtimes.

The application repositories own their service Compose definitions. This repository uses Compose `include` rather than duplicating those service definitions.

## Layout

Check out these repositories as siblings:

```text
ai-infra/
rag-ingestion/
rag-indexer/
rag-retrieval/
ai-gateway/
agent-core/
agent-tools-web/
agent-tools-code/
ai-ui/
laya/
llm-gateway/
llm-inference/
```

Then copy `.env.example` to `.env`, set a real JWT secret, and run the base stack:

```bash
docker compose up --build
```

### Optional Laya System-1 runtime

Laya is an optional CPU service. The base stack does not start it and does not depend on it. To start Laya after the base services are running, check out `zk198/laya` as the sibling `laya/` repository and run:

```bash
docker compose -f compose.yaml -f compose.laya.yaml up --build -d laya
```

Laya is internal-only at `http://laya:8000`; no host port is published. Model weights persist in the `laya-model-cache` volume. English is the primary checkpoint and multilingual remains available. The default preload is disabled so first use does not force a full model load during stack startup.

Validate the optional runtime with:

```bash
sh scripts/check-stack-health.sh laya
```

### Optional LLM runtime

For the complete local stack, including Bifrost and GPU-backed SGLang, check out `llm-gateway/` and `llm-inference/` as siblings and run:

```bash
docker compose -f compose.yaml -f compose.llm.yaml up --build
```

`compose.llm.yaml` includes the private LLM service definitions and adds the internal DNS aliases expected by `agent-core` (`llm-gateway`) and Bifrost (`llm-inference`). It removes their host port publishing; they remain reachable on the internal Compose network. The GPU requirement is isolated to `llm-inference`; Bifrost itself is a CPU/network gateway.

The AI gateway is the only application service exposed on the host by the base integration stack. Internal agent/tool, PostgreSQL, Qdrant, Laya, and LLM services remain on the Compose network. PostgreSQL is the authoritative source of truth and Qdrant is a rebuildable search index.

Qdrant is pinned to v1.19.1 for reproducible local integration. Production image digests and registry-based deployment are handled in Part 2.

## Stack health validation

After starting the base stack, run `sh scripts/check-stack-health.sh`. For optional Laya, run `sh scripts/check-stack-health.sh laya`. For the optional GPU LLM stack, run `sh scripts/check-stack-health.sh llm`. The script checks externally published endpoints and internal service readiness and prints Compose state/logs on failure.
