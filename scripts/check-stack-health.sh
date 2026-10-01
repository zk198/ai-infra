#!/usr/bin/env sh
set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
ROOT_DIR=$(CDPATH= cd -- "$SCRIPT_DIR/.." && pwd)
cd "$ROOT_DIR"
if [ ! -f .env ]; then
  echo "Missing .env. Create it first: cp .env.example .env" >&2
  exit 1
fi
set -a
. ./.env
set +a

mode="${1:-base}"
compose="docker compose -f compose.yaml"
case "$mode" in
  base) ;;
  laya) compose="$compose -f compose.laya.yaml" ;;
  llm) compose="$compose -f compose.llm.yaml" ;;
  all) compose="$compose -f compose.laya.yaml -f compose.llm.yaml" ;;
  *)
    echo "Usage: sh scripts/check-stack-health.sh [base|laya|llm|all]" >&2
    exit 2
    ;;
esac

AI_GATEWAY_PORT="${AI_GATEWAY_PORT:-8200}"
AI_UI_PORT="${AI_UI_PORT:-3000}"
# Host-published endpoints derive from the same port variables as Compose.
AI_GATEWAY_HEALTH_URL="${AI_GATEWAY_HEALTH_URL:-http://localhost:$AI_GATEWAY_PORT/health}"
AI_UI_URL="${AI_UI_URL:-http://localhost:$AI_UI_PORT/}"
# Internal endpoints are explicitly configured in .env.example and use
# container-localhost because these probes execute inside each target container.
QDRANT_HEALTH_URL="${QDRANT_HEALTH_URL:-http://localhost:6333/healthz}"
: "${AGENT_CORE_READY_URL:?Set AGENT_CORE_READY_URL in .env}"
: "${AI_GATEWAY_READY_URL:?Set AI_GATEWAY_READY_URL in .env}"
: "${LAYA_HEALTH_URL:?Set LAYA_HEALTH_URL in .env}"
: "${SGLANG_HEALTH_URL:?Set SGLANG_HEALTH_URL in .env}"
: "${BIFROST_HEALTH_URL:?Set BIFROST_HEALTH_URL in .env}"

fail=0
check_host() {
  name="$1"; url="$2"
  printf '%s: ' "$name"
  if curl -fsS --max-time 5 "$url" >/dev/null; then echo ok; else echo failed; fail=1; fi
}

check_exec() {
  name="$1"; service="$2"; url="$3"
  printf '%s: ' "$name"
  if $compose exec -T "$service" python -c 'import sys,urllib.request; urllib.request.urlopen(sys.argv[1], timeout=5).read()' "$url" >/dev/null 2>&1; then echo ok; else echo failed; fail=1; fi
}

check_qdrant() {
  printf '%s: ' "Qdrant"
  if $compose exec -T qdrant wget --spider -q --timeout=5 "$QDRANT_HEALTH_URL" >/dev/null 2>&1; then echo ok; else echo failed; fail=1; fi
}

check_host "AI gateway" "$AI_GATEWAY_HEALTH_URL"
check_host "AI UI" "$AI_UI_URL"
check_qdrant
check_exec "Agent core readiness" "agent-core" "$AGENT_CORE_READY_URL"
check_exec "Gateway readiness" "ai-gateway" "$AI_GATEWAY_READY_URL"

if [ "$mode" = "laya" ] || [ "$mode" = "all" ]; then
  check_exec "Laya health" "laya" "$LAYA_HEALTH_URL"
fi
if [ "$mode" = "llm" ] || [ "$mode" = "all" ]; then
  check_exec "SGLang health" "inference" "$SGLANG_HEALTH_URL"
  check_exec "Bifrost HTTP" "gateway" "$BIFROST_HEALTH_URL"
fi

if [ "$fail" -ne 0 ]; then
  echo "Stack health validation failed; dumping Compose state and recent logs." >&2
  $compose ps || true
  $compose logs --no-color --tail=100 || true
  exit 1
fi

$compose ps
