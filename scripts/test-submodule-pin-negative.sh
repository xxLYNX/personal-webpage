#!/usr/bin/env bash
# Negative test: build must reject a theme checkout that does not match the parent gitlink.
# Uses a disposable git worktree; does not change the main submodule branch/HEAD/working tree.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
THEME_DIR="${REPO_ROOT}/themes/hugo-void"

SKIP_EXIT=77

WORKTREE_DIR=""
cleanup() {
  if [[ -n "${WORKTREE_DIR}" ]] && [[ -d "${WORKTREE_DIR}" ]]; then
    git -C "${THEME_DIR}" worktree remove --force "${WORKTREE_DIR}" >/dev/null 2>&1 || true
    rm -rf "${WORKTREE_DIR}" 2>/dev/null || true
  fi
}
trap cleanup EXIT

# Snapshot main submodule state (must be unchanged when we finish).
if ! git -C "${THEME_DIR}" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  echo "FAIL: ${THEME_DIR} is not a git checkout" >&2
  exit 1
fi

BEFORE_REF="$(git -C "${THEME_DIR}" symbolic-ref -q HEAD 2>/dev/null || true)"
BEFORE_SHA="$(git -C "${THEME_DIR}" rev-parse HEAD)"
BEFORE_STATUS="$(git -C "${THEME_DIR}" status --porcelain)"

EXPECTED="$(git -C "${REPO_ROOT}" rev-parse "HEAD:themes/hugo-void")"

WRONG="$(git -C "${THEME_DIR}" rev-parse "${BEFORE_SHA}~1" 2>/dev/null || true)"
if [[ -z "${WRONG}" ]] || [[ "${WRONG}" == "${BEFORE_SHA}" ]]; then
  echo "SKIP: cannot find a distinct parent commit for negative test" >&2
  exit "${SKIP_EXIT}"
fi

if [[ "${WRONG}" == "${EXPECTED}" ]]; then
  WRONG="$(git -C "${THEME_DIR}" rev-parse "${BEFORE_SHA}~2" 2>/dev/null || true)"
fi

if [[ -z "${WRONG}" ]] || [[ "${WRONG}" == "${EXPECTED}" ]]; then
  echo "SKIP: no alternate commit available for negative test" >&2
  exit "${SKIP_EXIT}"
fi

echo "==> Negative submodule pin test (disposable worktree)"
echo "    parent pin:       ${EXPECTED}"
echo "    main submodule:   ${BEFORE_SHA} (${BEFORE_REF:-detached})"
echo "    disposable commit: ${WRONG}"

WORKTREE_DIR="$(mktemp -d)"
git -C "${THEME_DIR}" worktree add --detach "${WORKTREE_DIR}" "${WRONG}" >/dev/null

set +e
THEME_SUBMODULE_PATH="${WORKTREE_DIR}" "${REPO_ROOT}/scripts/build-site.sh" >/tmp/test-submodule-pin-negative.out 2>&1
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

AFTER_REF="$(git -C "${THEME_DIR}" symbolic-ref -q HEAD 2>/dev/null || true)"
AFTER_SHA="$(git -C "${THEME_DIR}" rev-parse HEAD)"
AFTER_STATUS="$(git -C "${THEME_DIR}" status --porcelain)"

if [[ "${BEFORE_SHA}" != "${AFTER_SHA}" ]] || [[ "${BEFORE_REF}" != "${AFTER_REF}" ]] || [[ "${BEFORE_STATUS}" != "${AFTER_STATUS}" ]]; then
  echo "FAIL: main theme submodule state changed during negative test" >&2
  echo "  before: ${BEFORE_SHA} ${BEFORE_REF:-detached}" >&2
  echo "  after:  ${AFTER_SHA} ${AFTER_REF:-detached}" >&2
  exit 1
fi

echo "OK: build rejected wrong theme commit (exit ${BUILD_EXIT})"
echo "OK: main submodule state preserved (${AFTER_SHA})"
exit 0