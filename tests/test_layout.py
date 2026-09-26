from pathlib import Path

ROOT = Path(__file__).parents[1]


def test_compose_includes_backend_service_repositories():
    compose = (ROOT / "compose.yaml").read_text()

    assert "../rag-ingestion/docker-compose.yml" in compose
    assert "../rag-indexer/compose.yaml" in compose
    assert "../rag-retrieval/compose.yaml" in compose
    assert "../ai-gateway/compose.yaml" in compose
    assert "../agent-core/docker-compose.yml" in compose
    assert "../agent-tools-web/docker-compose.yml" in compose
    assert "../agent-tools-code/docker-compose.yml" in compose


def test_qdrant_is_version_pinned_and_persistent():
    compose = (ROOT / "compose.yaml").read_text()

    assert "qdrant/qdrant:v1.19.1" in compose
    assert "qdrant-data:/qdrant/storage" in compose
    assert "6333:6333" in compose
    assert "6334:6334" in compose


def test_environment_has_no_default_secret():
    env = (ROOT / ".env.example").read_text()

    assert "replace-with-a-long-random-secret" in env
    assert "replace-me" not in env


def test_ai_gateway_is_only_published_application_service():
    compose = (ROOT / "compose.yaml").read_text()
    assert '  agent-core:\n    ports: []' in compose
    assert '  web:\n    ports: []' in compose
    assert "../ai-gateway/compose.yaml" in compose
