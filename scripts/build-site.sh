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

if ! command -v git >/dev/null 2>&1; then
  echo "error: git not found on PATH" >&2
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

echo "==> Repository: ${REPO_ROOT}"
echo "==> Hugo: $(hugo version)"
echo "==> Node: $(node --version)"
echo "==> pnpm: $(pnpm --version)"

echo "==> Theme submodule (pinned to parent gitlink)"
git -C "${REPO_ROOT}" submodule sync --recursive themes/hugo-void

EXPECTED_THEME_SHA="$(git -C "${REPO_ROOT}" rev-parse "HEAD:themes/hugo-void")"
if [[ -z "${EXPECTED_THEME_SHA}" ]]; then
  echo "error: could not read themes/hugo-void gitlink from parent HEAD" >&2
  exit 1
fi
echo "==> Parent records theme commit: ${EXPECTED_THEME_SHA}"

sub_line="$(git -C "${REPO_ROOT}" submodule status themes/hugo-void 2>/dev/null || true)"
if [[ "${sub_line}" == -* ]] || [[ ! -f "${THEME_DIR}/layouts/_default/baseof.html" ]]; then
  echo "==> Initializing themes/hugo-void submodule"
  git -C "${REPO_ROOT}" submodule update --init --recursive themes/hugo-void
fi

if [[ ! -f "${THEME_DIR}/package.json" ]] || [[ ! -f "${THEME_DIR}/pnpm-lock.yaml" ]]; then
  echo "error: theme at ${THEME_DIR} is incomplete; expected commit ${EXPECTED_THEME_SHA}" >&2
  echo "error: run: git submodule update --init themes/hugo-void" >&2
  exit 1
fi

ACTUAL_THEME_SHA="$(git -C "${THEME_DIR}" rev-parse HEAD)"
echo "==> Theme checkout commit: ${ACTUAL_THEME_SHA}"

if [[ "${ACTUAL_THEME_SHA}" != "${EXPECTED_THEME_SHA}" ]]; then
  if [[ "${ALLOW_THEME_SUBMODULE_DRIFT:-0}" == "1" ]]; then
    echo "WARNING: ALLOW_THEME_SUBMODULE_DRIFT=1 — building theme ${ACTUAL_THEME_SHA}, not parent pin ${EXPECTED_THEME_SHA}" >&2
  else
    echo "error: theme submodule commit mismatch" >&2
    echo "error:   parent pin (HEAD:themes/hugo-void): ${EXPECTED_THEME_SHA}" >&2
    echo "error:   checkout (themes/hugo-void HEAD):    ${ACTUAL_THEME_SHA}" >&2
    echo "error: align the submodule without discarding work: git submodule update --init themes/hugo-void" >&2
    echo "error: or commit a new parent gitlink after bumping the submodule intentionally" >&2
    echo "error: explicit theme development override (local only): ALLOW_THEME_SUBMODULE_DRIFT=1" >&2
    exit 1
  fi
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