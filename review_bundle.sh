#!/usr/bin/env bash
set -euo pipefail

BASE_REF="${1:-HEAD}"
TIMESTAMP="$(date +"%Y%m%d-%H%M%S")"
OUT_DIR=".review"
OUT_FILE="$OUT_DIR/review-$TIMESTAMP.txt"

mkdir -p "$OUT_DIR"

if git rev-parse --verify "$BASE_REF" >/dev/null 2>&1; then
  DIFF_RANGE="$BASE_REF"
else
  echo "Référence git invalide: $BASE_REF" >&2
  exit 1
fi

{
  echo "# REVIEW BUNDLE"
  echo
  echo "Generated at: $(date +"%Y-%m-%d %H:%M:%S")"
  echo "Repository: $(basename "$(git rev-parse --show-toplevel)")"
  echo "Branch: $(git rev-parse --abbrev-ref HEAD)"
  echo "Base ref: $DIFF_RANGE"
  echo "Head commit: $(git rev-parse HEAD)"
  echo

  echo "## GIT STATUS --SHORT"
  echo
  git status --short
  echo

  echo "## GIT DIFF --STAT"
  echo
  git diff --stat "$DIFF_RANGE"
  echo

  echo "## CHANGED FILES"
  echo
  git diff --name-only "$DIFF_RANGE"
  echo

  echo "## RECENT COMMITS"
  echo
  git log --oneline -n 15
  echo

  echo "## FULL DIFF"
  echo
  git diff "$DIFF_RANGE"
  echo

  for file in AI_PROJECT_STATE.md PROJECT_STATUS.md; do
    echo "## FILE: $file"
    echo
    if [ -f "$file" ]; then
      cat "$file"
    else
      echo "[MISSING] $file"
    fi
    echo
  done
} > "$OUT_FILE"

echo "$OUT_FILE"