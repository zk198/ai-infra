#!/usr/bin/env sh
set -eu

# Run from the ai-infra checkout; sibling repositories are cloned beside it.
SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
ROOT_DIR=$(CDPATH= cd -- "$SCRIPT_DIR/.." && pwd)
cd "$ROOT_DIR"

mode="${1:-base}"
case "$mode" in
  base) compose_files="-f compose.yaml" ;;
  laya) compose_files="-f compose.yaml -f compose.laya.yaml" ;;
  llm) compose_files="-f compose.yaml -f compose.llm.yaml" ;;
  all) compose_files="-f compose.yaml -f compose.laya.yaml -f compose.llm.yaml" ;;
  *)
    echo "Usage: sh scripts/start-local.sh [base|laya|llm|all]" >&2
    exit 2
    ;;
esac

if ! command -v git >/dev/null 2>&1; then
  echo "Git is required to clone/update the stack repositories." >&2
  exit 1
fi
if ! command -v docker >/dev/null 2>&1 || ! docker info >/dev/null 2>&1; then
  echo "Docker is not available. Start Docker Engine/Desktop and retry." >&2
  exit 1
fi

if [ ! -f .env ]; then
  echo "Missing .env. Create it first: cp .env.example .env" >&2
  exit 1
fi

# Pull all stack repositories before Compose validates their build contexts.
sh scripts/pull-repos.sh

echo "Validating Compose configuration..."
# Intentional word splitting: compose_files contains multiple -f arguments.
# shellcheck disable=SC2086
docker compose $compose_files config >/dev/null

echo "Starting $mode stack..."
# shellcheck disable=SC2086
docker compose $compose_files up -d --build

echo "Waiting for service health..."
if ! sh scripts/check-stack-health.sh "$mode"; then
  echo "Startup validation failed. Inspect the service logs above, or run:" >&2
  # shellcheck disable=SC2086
  echo "  docker compose $compose_files ps" >&2
  exit 1
fi

# Load .env for user-facing endpoint output; defaults mirror Compose.
set -a
. ./.env
set +a
AI_GATEWAY_PORT="${AI_GATEWAY_PORT:-8200}"
AI_UI_PORT="${AI_UI_PORT:-3000}"
printf '\nLocal AI stack is up.\n'
printf 'UI:          http://localhost:%s\n' "$AI_UI_PORT"
printf 'AI gateway:  http://localhost:%s\n' "$AI_GATEWAY_PORT"
printf 'Gateway:     http://localhost:%s/health\n' "$AI_GATEWAY_PORT"
