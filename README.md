# AI Infrastructure

Local integration composition for the AI stack, including the RAG platform, agent/tool services, gateway, UI, and optional local LLM and Laya runtimes.

The application repositories own their service Compose definitions. This repository uses Compose `include` rather than duplicating those service definitions.

## First-time local installation

Prerequisites:
- Git and Docker Engine/Desktop with the Docker Compose plugin.
- GitHub credentials configured for Git over HTTPS or SSH, including access to the private `llm-gateway` and `llm-inference` repositories.
- For the complete GPU-backed stack, a supported NVIDIA GPU, host driver, and Docker GPU runtime configured.

Clone `ai-infra`, then from its checkout run:

```bash
cp .env.example .env
# Edit .env: set RAG_JWT_SECRET and BIFROST_ENCRYPTION_KEY to random secrets.
sh scripts/pull-repos.sh
sh scripts/start-local.sh all
```

`start-local.sh` also invokes `pull-repos.sh`, so running both commands is optional. The pull script clones missing sibling repositories and fast-forward updates clean existing checkouts. It deliberately stops if a repository has local modifications, is detached, or has an unexpected origin; resolve that condition rather than losing local work. Private repository access must already be configured in Git.

## Repository layout

The script checks out these siblings next to `ai-infra/`:

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

Set `GITHUB_OWNER` if the repositories are hosted under a different owner. Do not use a different owner unless all listed repositories exist there.

## Starting and validating the stack

```bash
sh scripts/start-local.sh base   # Core RAG, agent, tools and UI
sh scripts/start-local.sh laya   # Core stack + Laya
sh scripts/start-local.sh llm    # Core stack + Bifrost + GPU-backed SGLang
sh scripts/start-local.sh all    # Core stack + Laya + Bifrost + GPU-backed SGLang
sh scripts/check-stack-health.sh all
```

The local host ports are controlled by `AI_GATEWAY_PORT` and `AI_UI_PORT` in `.env`; health-check host URLs derive from those ports unless the optional `AI_GATEWAY_HEALTH_URL` or `AI_UI_URL` override is set. Internal health URLs can also be overridden with the corresponding `*_URL` variables in `.env`. Internal service URLs default to Compose service/container endpoints.

### Optional Laya System-1 runtime

Laya is an optional CPU service. It is internal-only at `http://laya:8000`; no host port is published. Model weights persist in the `laya-model-cache` volume. The default preload is disabled so first use does not force a full model load during stack startup.

### Optional LLM runtime

The local LLM overlay includes private LLM service definitions and adds internal DNS aliases expected by `agent-core` (`llm-gateway`) and Bifrost (`llm-inference`). The overlay removes their host port publishing; they remain reachable on the internal Compose network. The GPU requirement is isolated to `llm-inference`; Bifrost itself is a CPU/network gateway.

The AI gateway and UI are the only application endpoints published on the host by the core integration stack. Internal agent/tool, PostgreSQL, Qdrant, Laya, and LLM services remain on the Compose network. PostgreSQL is the authoritative source of truth and Qdrant is a rebuildable search index.

Qdrant is pinned to v1.19.1 for reproducible local integration. Production image digests and registry-based deployment are handled in Part 2.

## Safety notes

- Do not commit `.env`; it contains local secrets and configuration.
- The example secret values are placeholders and must be replaced before starting.
- `scripts/pull-repos.sh` uses `git pull --ff-only`; it will not create merge commits or overwrite local modifications.
