# AI Infrastructure

Local integration composition for the AI stack.

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
```

Then copy `.env.example` to `.env`, set a real JWT secret, and run:

```
docker compose up --build
```

The AI gateway is exposed on port 8200; internal agent/tool services are not published to the host. PostgreSQL remains the authoritative source of truth and Qdrant is a rebuildable search index.

Qdrant is pinned to v1.19.1 for reproducible local integration. Production image digests and registry-based deployment are handled in Part 2.
