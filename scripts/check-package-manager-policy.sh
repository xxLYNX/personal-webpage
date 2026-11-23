#!/usr/bin/env bash
# Fail if active build/deploy scripts reference npm, npx, or yarn.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

SCAN_PATHS=(
  "${REPO_ROOT}/scripts/build-site.sh"
  "${REPO_ROOT}/scripts/smoke-test.sh"
  "${REPO_ROOT}/deploy.sh"
)

PATTERN='\b(npm|npx|yarn)\b'

fail=0
for file in "${SCAN_PATHS[@]}"; do
  if [[ ! -f "${file}" ]]; then
    echo "FAIL: missing expected file: ${file}" >&2
    fail=1
    continue
  fi
  if grep -qE "${PATTERN}" "${file}"; then
    echo "FAIL: disallowed package manager reference in ${file}" >&2
    grep -nE "${PATTERN}" "${file}" >&2 || true
    fail=1
  else
    echo "OK: ${file}"
  fi
done

if [[ "${fail}" -ne 0 ]]; then
  echo "Package manager policy check FAILED" >&2
  exit 1
fi

echo "Package manager policy check PASSED (pnpm-only in active workflow docs/scripts)"