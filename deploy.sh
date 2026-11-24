#!/usr/bin/env bash
# Local build + smoke verification only. Does not commit, push, or alter Git history.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="${SCRIPT_DIR}"

if [[ ! -f "${REPO_ROOT}/hugo.toml" ]]; then
  echo "error: hugo.toml not found. Run this script from the project root." >&2
  exit 1
fi

echo "==> Running reproducible site build (no Git writes)"
"${REPO_ROOT}/scripts/build-site.sh"

echo "==> Running smoke tests"
"${REPO_ROOT}/scripts/smoke-test.sh"

echo "==> Build and smoke checks passed. Publish via your normal Git/CI workflow (this script does not push)."