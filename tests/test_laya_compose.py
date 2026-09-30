from pathlib import Path

COMPOSE = Path(__file__).parents[1] / "compose.laya.yaml"

def test_laya_compose_is_internal_cpu_only():
    text = COMPOSE.read_text()
    assert "context: ../laya" in text
    assert 'LAYA_DEVICE: "${LAYA_DEVICE:-cpu}"' in text
    assert "expose:" in text
    assert "8000" in text
    assert "ports:" not in text
    assert "laya-model-cache:/home/laya/.cache/huggingface" in text
    assert "healthcheck:" in text
    assert "LAYA_ENABLED" in text
    assert "AGENT_LAYA_ENABLED" in text

def test_laya_compose_does_not_create_hard_startup_dependency():
    text = COMPOSE.read_text()
    assert "depends_on:" not in text
