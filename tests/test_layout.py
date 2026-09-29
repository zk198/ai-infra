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


def test_startup_script_validates_docker_env_and_compose_mode():
    script = (ROOT / "scripts/start-local.sh").read_text()

    assert 'mode="${1:-base}"' in script
    assert "docker info" in script
    assert "cp .env.example .env" in script
    assert "docker compose $compose_files config" in script
    assert "docker compose $compose_files up -d --build" in script
    assert 'check-stack-health.sh "$mode"' in script


def test_health_check_keeps_qdrant_internal():
    script = (ROOT / "scripts/check-stack-health.sh").read_text()

    assert "http://localhost:6333/healthz" in script
    assert "check_qdrant" in script
    assert 'check_host "Qdrant"' not in script
