# Phase 1.c — Product and RAG Experience

Phase 1.c builds on the Phase 1.b retrieval UI without changing the meaning of the retrieval API.

## Deferred from Phase 1.b

### Identity and access
- OIDC integration (Keycloak, Authentik, or another OIDC provider)
- user provisioning
- tenant administration
- RBAC and finer-grained authorization
- token rotation and production secret handling

### Chat / answer generation
- evaluate a separate open-source chat/RAG orchestration library
- generated answers must sit above retrieval and must not turn the search endpoint into a chat endpoint
- citation-aware answer generation
- conversation/session state
- prompt/model routing
- streaming responses

### Search experience
- advanced filters
- saved searches
- richer source filtering
- pagination and result ranking controls
- search history

### Knowledge lifecycle
- richer upload/indexing progress
- indexing failure and retry visibility
- source management
- document/email annotation
- document editing

### Connectors
- mailbox synchronization
- Outlook/Gmail connectors
- scheduled ingestion
- incremental sync and deletion handling

### Operations
- observability dashboards
- ingestion/indexer/retrieval health views
- audit logging
- performance/load testing
- large-file upload strategy
- production CSP/CSRF hardening

## Architectural constraints

- The browser talks only to ai-gateway.
- PostgreSQL remains the authoritative store.
- Qdrant remains a rebuildable retrieval index.
- The search endpoint remains retrieval-only and returns ranked evidence.
- Answer generation is a separate layer above retrieval.
- The UI must not gain direct access to PostgreSQL, Qdrant, ingestion, or indexer services.

## Private UI repository

zk198/rag-ui is currently private. Its Compose file can be included locally alongside the other service repositories. Integrated CI in rag-infra does not clone the private UI repository until an appropriate cross-repository GitHub credential is configured. This avoids introducing a personal access token or other long-lived credential into CI.

When the repository access model is settled, Phase 1.c should make the integrated deployment validate the UI Compose include as well.
