#!/usr/bin/env bash
# Negative test: build must reject a theme checkout that does not match the parent gitlink.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
THEME_DIR="${REPO_ROOT}/themes/hugo-void"

EXPECTED="$(git -C "${REPO_ROOT}" rev-parse "HEAD:themes/hugo-void")"
SAVED="$(git -C "${THEME_DIR}" rev-parse HEAD)"

cleanup() {
  git -C "${THEME_DIR}" checkout --detach "${SAVED}" >/dev/null 2>&1 || git -C "${THEME_DIR}" checkout "${SAVED}" >/dev/null 2>&1 || true
}
trap cleanup EXIT

WRONG="$(git -C "${THEME_DIR}" rev-parse "${SAVED}~1" 2>/dev/null || true)"
if [[ -z "${WRONG}" ]] || [[ "${WRONG}" == "${SAVED}" ]]; then
  echo "SKIP: cannot find a distinct parent commit for negative test" >&2
  exit 0
fi

if [[ "${WRONG}" == "${EXPECTED}" ]]; then
  WRONG="$(git -C "${THEME_DIR}" rev-parse "${SAVED}~2" 2>/dev/null || true)"
fi

if [[ -z "${WRONG}" ]] || [[ "${WRONG}" == "${EXPECTED}" ]]; then
  echo "SKIP: no alternate commit available for negative test" >&2
  exit 0
fi

echo "==> Negative submodule pin test"
echo "    parent pin:  ${EXPECTED}"
echo "    saved HEAD:  ${SAVED}"
echo "    temporary:   ${WRONG}"

git -C "${THEME_DIR}" checkout --detach "${WRONG}" >/dev/null

set +e
"${REPO_ROOT}/scripts/build-site.sh" >/tmp/test-submodule-pin-negative.out 2>&1
BUILD_EXIT=$?
set -e

if [[ "${BUILD_EXIT}" -eq 0 ]]; then
  echo "FAIL: build succeeded with wrong theme commit" >&2
  cat /tmp/test-submodule-pin-negative.out >&2
  exit 1
fi

if ! grep -q 'theme submodule commit mismatch' /tmp/test-submodule-pin-negative.out; then
  echo "FAIL: build exited ${BUILD_EXIT} but without expected mismatch message" >&2
  cat /tmp/test-submodule-pin-negative.out >&2
  exit 1
fi

echo "OK: build rejected wrong theme commit (exit ${BUILD_EXIT})"
exit 0