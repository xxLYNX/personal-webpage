#!/usr/bin/env bash
# Reproducible Hugo + Tailwind build for personal-webpage.
# Tested: Hugo v0.170.0, Node.js v24.x, pnpm v12.9.0 (see docs/operations/build-locally.md).
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
THEME_DIR="${REPO_ROOT}/themes/hugo-void"

if [[ ! -f "${REPO_ROOT}/hugo.toml" ]]; then
  echo "error: hugo.toml not found at repo root (${REPO_ROOT})" >&2
  exit 1
fi

if [[ ! -f "${THEME_DIR}/package.json" ]]; then
  echo "error: theme missing at ${THEME_DIR}; run: git submodule update --init --recursive" >&2
  exit 1
fi

if ! command -v hugo >/dev/null 2>&1; then
  echo "error: hugo not found on PATH (tested with nixpkgs#hugo v0.170.0)" >&2
  exit 1
fi

if ! command -v pnpm >/dev/null 2>&1; then
  echo "error: pnpm not found on PATH (tested with nixpkgs#pnpm 12.9.0)" >&2
  exit 1
fi

if ! command -v node >/dev/null 2>&1; then
  echo "error: node not found on PATH" >&2
  exit 1
fi

if [[ ! -f "${THEME_DIR}/pnpm-lock.yaml" ]]; then
  echo "error: ${THEME_DIR}/pnpm-lock.yaml not found; theme must use pnpm lockfile" >&2
  exit 1
fi

echo "==> Repository: ${REPO_ROOT}"
echo "==> Hugo: $(hugo version)"
echo "==> Node: $(node --version)"
echo "==> pnpm: $(pnpm --version)"

echo "==> Ensuring theme submodule is present"
git -C "${REPO_ROOT}" submodule sync --recursive themes/hugo-void
sub_status="$(git -C "${REPO_ROOT}" submodule status themes/hugo-void 2>/dev/null || true)"
if [[ ! -f "${THEME_DIR}/layouts/_default/baseof.html" ]]; then
  git -C "${REPO_ROOT}" submodule update --init --recursive themes/hugo-void
elif [[ "${sub_status}" == -* ]]; then
  git -C "${REPO_ROOT}" submodule update --init --recursive themes/hugo-void
elif [[ "${sub_status}" == +* ]]; then
  echo "==> Theme checkout is ahead of parent gitlink (local development); not resetting submodule"
fi

echo "==> Installing theme dependencies (pnpm install --frozen-lockfile)"
(
  cd "${THEME_DIR}"
  pnpm install --frozen-lockfile
)

echo "==> Building Tailwind CSS (themes/hugo-void)"
(
  cd "${THEME_DIR}"
  pnpm run build:css
)

HUGO_LOG="$(mktemp)"
trap 'rm -f "${HUGO_LOG}"' EXIT

echo "==> Running Hugo (output: ${REPO_ROOT}/public/)"
set +e
hugo --source "${REPO_ROOT}" --minify 2>&1 | tee "${HUGO_LOG}"
HUGO_EXIT=${PIPESTATUS[0]}
set -e

if [[ "${HUGO_EXIT}" -ne 0 ]]; then
  echo "error: hugo exited with status ${HUGO_EXIT}" >&2
  exit "${HUGO_EXIT}"
fi

if grep -q 'found no layout file' "${HUGO_LOG}"; then
  echo "error: Hugo reported missing layout templates (is themes/hugo-void checked out?)" >&2
  exit 1
fi

echo "==> Build finished successfully"