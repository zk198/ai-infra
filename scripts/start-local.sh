#!/usr/bin/env sh
set -eu

mode="${1:-base}"
case "$mode" in
  base|llm) ;;
  *)
    echo "Usage: sh scripts/start-local.sh [base|llm]" >&2
    exit 2
    ;;
esac

if ! docker info >/dev/null 2>&1; then
  echo "Docker is not available. Start Docker Desktop/Engine and retry." >&2
  exit 1
fi

if [ ! -f .env ]; then
  echo "Missing .env. Create it first: cp .env.example .env" >&2
  exit 1
fi

if [ "$mode" = "llm" ]; then
  for repo in ../llm-gateway ../llm-inference; do
    if [ ! -d "$repo" ]; then
      echo "Missing sibling repository: $repo" >&2
      exit 1
    fi
  done
  compose_files="-f compose.yaml -f compose.llm.yaml"
else
  compose_files="-f compose.yaml"
fi

echo "Validating Compose configuration..."
docker compose $compose_files config >/dev/null

echo "Starting $mode stack..."
docker compose $compose_files up -d --build

echo "Waiting for service health..."
if ! sh scripts/check-stack-health.sh "$mode"; then
  echo "Startup validation failed. Inspect the service logs above, or run:" >&2
  echo "  docker compose $compose_files ps" >&2
  exit 1
fi

echo
echo "Local AI stack is up."
echo "UI:          http://localhost:3000"
echo "AI gateway:  http://localhost:8200"
echo "Gateway:     http://localhost:8200/health"
