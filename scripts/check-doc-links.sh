#!/usr/bin/env bash
# Verify that every relative markdown link under doc/ resolves to a real file.
#
# The docs in doc/ are the upstream source for the Docusaurus site in
# phoenixai-anywhere-docs, which builds with onBrokenLinks enabled. Catching
# dangling links here keeps that build green.
#
# Usage: scripts/check-doc-links.sh [doc-dir]
set -uo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DOC_DIR="${1:-${REPO_ROOT}/doc}"

report="$(
  find "$DOC_DIR" -name '*.md' -print0 |
  while IFS= read -r -d '' file; do
    dir="$(dirname "$file")"

    # Pull the target out of every ](...) link, then discard the ones we can't
    # or shouldn't resolve: external URLs, in-page anchors, and Docusaurus'
    # pathname:// escape hatch.
    grep -oE '\]\([^)]+\)' "$file" 2>/dev/null |
      sed -E 's/^\]\(//; s/\)$//' |
      grep -vE '^(https?:|mailto:|pathname:|#|<)' |
      while IFS= read -r link; do
        target="${link%%#*}"          # strip any anchor
        [ -n "$target" ] || continue  # was a bare anchor
        [ -e "${dir}/${target}" ] ||
          printf 'BROKEN  %s\n        -> %s\n' "${file#"${REPO_ROOT}/"}" "$link"
      done
  done
)"

total="$(find "$DOC_DIR" -name '*.md' | wc -l | tr -d ' ')"

if [ -n "$report" ]; then
  printf '%s\n\n' "$report"
  echo "FAIL: $(grep -c '^BROKEN' <<< "$report") broken relative link(s) across ${total} files."
  exit 1
fi

echo "OK: all relative links resolve (${total} files checked)."
