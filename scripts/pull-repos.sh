#!/usr/bin/env sh
set -eu

# Keep this list aligned with the repository includes in compose.yaml and its
# optional Laya/LLM overlays. Private repositories require working Git credentials.
SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
ROOT_DIR=$(CDPATH= cd -- "$SCRIPT_DIR/.." && pwd)
PARENT_DIR=$(dirname -- "$ROOT_DIR")
OWNER="${GITHUB_OWNER:-zk198}"

repos="
rag-ingestion
rag-indexer
rag-retrieval
ai-gateway
agent-core
agent-tools-web
agent-tools-code
ai-ui
laya
llm-gateway
llm-inference
"

if ! command -v git >/dev/null 2>&1; then
  echo "Git is required. Install Git and retry." >&2
  exit 1
fi

for name in $repos; do
  path="$PARENT_DIR/$name"
  url="https://github.com/$OWNER/$name.git"
  if [ ! -e "$path" ]; then
    echo "Cloning $OWNER/$name -> $path"
    git clone "$url" "$path"
    continue
  fi

  if [ ! -d "$path/.git" ]; then
    echo "Refusing to use '$path': it exists but is not a Git checkout." >&2
    echo "Move it aside or remove it, then rerun this script." >&2
    exit 1
  fi

  current_origin=$(git -C "$path" remote get-url origin)
  if [ "$current_origin" != "$url" ] && [ "$current_origin" != "git@github.com:$OWNER/$name.git" ]; then
    echo "Refusing to update '$path': origin is '$current_origin', expected '$url'." >&2
    exit 1
  fi

  if [ -n "$(git -C "$path" status --porcelain)" ]; then
    echo "Refusing to pull '$path': it has local changes." >&2
    echo "Commit/stash the changes or clean the checkout, then rerun." >&2
    exit 1
  fi

  echo "Updating $OWNER/$name"
  git -C "$path" fetch --prune origin
  branch=$(git -C "$path" symbolic-ref --quiet --short HEAD || true)
  if [ -z "$branch" ]; then
    echo "Refusing to update '$path': checkout is detached." >&2
    exit 1
  fi
  git -C "$path" pull --ff-only origin "$branch"
done

echo "All stack repositories are present and up to date."
