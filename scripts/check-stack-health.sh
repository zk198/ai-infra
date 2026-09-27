#!/usr/bin/env sh
set -eu

compose="docker compose -f compose.yaml"
if [ "${1:-base}" = "llm" ]; then
  compose="$compose -f compose.llm.yaml"
fi

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

check_host "AI gateway" "http://localhost:8200/health"
check_host "AI UI" "http://localhost:3000/"
check_host "Qdrant" "http://localhost:6333/healthz"
check_exec "Agent core readiness" "agent-core" "http://localhost:8000/api/v1/ready"
check_exec "Gateway readiness" "ai-gateway" "http://localhost:8200/ready"

if [ "${1:-base}" = "llm" ]; then
  check_exec "SGLang health" "inference" "http://localhost:30000/health"
  check_exec "Bifrost HTTP" "gateway" "http://localhost:8080/"
fi

if [ "$fail" -ne 0 ]; then
  echo "Stack health validation failed; dumping Compose state and recent logs." >&2
  $compose ps || true
  $compose logs --no-color --tail=100 || true
  exit 1
fi

$compose ps
