# RAG Infrastructure

Local integration composition for the RAG stack.

The application repositories own their service Compose definitions. This repository uses Compose `include` rather than duplicating those service definitions.

## Layout

Check out these repositories as siblings:

```
rag-infra/
rag-ingestion/
rag-indexer/
rag-retrieval/
ai-gateway/
```

Then copy `.env.example` to `.env`, set a real JWT secret, and run:

```
docker compose up --build
```

The gateway is exposed on port 8000. PostgreSQL remains the authoritative source of truth and Qdrant is a rebuildable search index.

Qdrant is pinned to v1.19.1 for reproducible local integration. Production image digests and registry-based deployment are handled in Part 2.
