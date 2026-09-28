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


def test_qdrant_is_version_pinned_persistent_and_internal():
    compose = (ROOT / "compose.yaml").read_text()

    assert "qdrant/qdrant:v1.19.1" in compose
    assert "qdrant-data:/qdrant/storage" in compose
    assert "6333:6333" not in compose
    assert "6334:6334" not in compose


def test_environment_has_no_default_secret():
    env = (ROOT / ".env.example").read_text()

    assert "replace-with-a-long-random-secret" in env
    assert "replace-me" not in env


def test_integrated_compose_does_not_redefine_included_services():
    compose = (ROOT / "compose.yaml").read_text()
    assert "  agent-core:" not in compose
    assert "  web:" not in compose
    assert "../ai-gateway/compose.yaml" in compose
