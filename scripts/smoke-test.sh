#!/usr/bin/env bash
# Post-build smoke checks for required English routes and theme CSS.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
PUBLIC_DIR="${1:-${REPO_ROOT}/public}"

MIN_HTML_BYTES=500

require_nonempty_file() {
  local label="$1"
  local path="$2"
  if [[ ! -f "${path}" ]]; then
    echo "FAIL: missing ${label}: ${path}" >&2
    return 1
  fi
  local size
  size="$(wc -c < "${path}" | tr -d ' ')"
  if [[ "${size}" -lt "${MIN_HTML_BYTES}" ]]; then
    echo "FAIL: ${label} too small (${size} bytes): ${path}" >&2
    return 1
  fi
  echo "OK: ${label} (${size} bytes): ${path}"
}

require_css() {
  local css="${PUBLIC_DIR}/css/style.css"
  if [[ ! -f "${css}" ]]; then
    echo "FAIL: missing theme CSS: ${css}" >&2
    return 1
  fi
  local size
  size="$(wc -c < "${css}" | tr -d ' ')"
  if [[ "${size}" -lt 100 ]]; then
    echo "FAIL: theme CSS too small (${size} bytes): ${css}" >&2
    return 1
  fi
  echo "OK: theme CSS (${size} bytes): ${css}"
}

html_references_css() {
  local page="$1"
  # Hugo --minify may emit href= without quotes; canonifyURLs may prepend baseURL.
  if grep -q 'css/style.css' "${page}"; then
    echo "OK: ${page} references css/style.css"
    return 0
  fi
  echo "FAIL: ${page} does not reference css/style.css" >&2
  return 1
}

echo "==> Smoke test public directory: ${PUBLIC_DIR}"

fail=0

require_nonempty_file "home (/en/)" "${PUBLIC_DIR}/en/index.html" || fail=1
require_nonempty_file "blog post" "${PUBLIC_DIR}/en/blogs/understanding-pe-files/index.html" || fail=1
require_nonempty_file "project pe-trainer" "${PUBLIC_DIR}/en/projects/pe-trainer/index.html" || fail=1
require_nonempty_file "resume" "${PUBLIC_DIR}/en/resume/index.html" || fail=1

require_css || fail=1
html_references_css "${PUBLIC_DIR}/en/index.html" || fail=1

HTML_COUNT="$(find "${PUBLIC_DIR}" -name '*.html' 2>/dev/null | wc -l | tr -d ' ')"
echo "==> HTML file count under public/: ${HTML_COUNT}"
if [[ "${HTML_COUNT}" -lt 10 ]]; then
  echo "FAIL: expected at least 10 HTML files, found ${HTML_COUNT}" >&2
  fail=1
else
  echo "OK: HTML file count >= 10"
fi

if [[ "${fail}" -ne 0 ]]; then
  echo "==> Smoke test FAILED" >&2
  exit 1
fi

echo "==> Smoke test PASSED"