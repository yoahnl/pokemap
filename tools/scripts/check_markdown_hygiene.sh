#!/usr/bin/env bash
set -euo pipefail

# This guard checks only Markdown introduced by the current change. Historical
# documentation debt stays visible without blocking unrelated work.
REPO_ROOT="$(git -C "$(dirname "${BASH_SOURCE[0]}")" rev-parse --show-toplevel)"
BASE_REF=""
MAX_NEW="${POKEMAP_MARKDOWN_MAX_NEW:-0}"
MAX_BYTES="${POKEMAP_MARKDOWN_MAX_BYTES:-262144}"

usage() {
  echo "Usage: bash tools/scripts/check_markdown_hygiene.sh [--base <git-ref>]" >&2
}

is_markdown_path() {
  local lower_path
  lower_path="$(printf '%s' "$1" | tr '[:upper:]' '[:lower:]')"
  case "$lower_path" in
    *.md|*.mdx|*.markdown) return 0 ;;
    *) return 1 ;;
  esac
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --base)
      if [[ $# -lt 2 ]]; then
        usage
        exit 2
      fi
      BASE_REF="$2"
      shift 2
      ;;
    *)
      usage
      exit 2
      ;;
  esac
done

if [[ ! "$MAX_NEW" =~ ^[0-9]+$ ]]; then
  echo "POKEMAP_MARKDOWN_MAX_NEW must be a non-negative integer." >&2
  exit 2
fi
if [[ ! "$MAX_BYTES" =~ ^[0-9]+$ ]]; then
  echo "POKEMAP_MARKDOWN_MAX_BYTES must be a non-negative integer." >&2
  exit 2
fi

if [[ -n "$BASE_REF" ]] && ! git -C "$REPO_ROOT" rev-parse --verify \
  "$BASE_REF^{commit}" >/dev/null 2>&1; then
  echo "Unknown base ref: $BASE_REF" >&2
  exit 2
fi

candidate_file="$(mktemp)"
new_file="$(mktemp)"
markdown_file="$(mktemp)"
new_markdown_file="$(mktemp)"
ignored_file="$(mktemp)"
deleted_hash_file="$(mktemp)"
deleted_hash_next_file="$(mktemp)"
trap 'rm -f "$candidate_file" "$new_file" "$markdown_file" "$new_markdown_file" "$ignored_file" "$deleted_hash_file" "$deleted_hash_next_file"' EXIT

# Rename detection prevents a pure reorganization from being reported as new
# documentation, while still validating the rename destination. Worktree
# additions and untracked files are included locally.
if [[ -n "$BASE_REF" ]]; then
  git -C "$REPO_ROOT" diff --find-renames --name-only --diff-filter=AR \
    "$BASE_REF...HEAD" >> "$candidate_file"
  git -C "$REPO_ROOT" diff --find-renames --name-only --diff-filter=A \
    "$BASE_REF...HEAD" >> "$new_file"
fi
git -C "$REPO_ROOT" diff --find-renames --name-only --diff-filter=AR HEAD \
  >> "$candidate_file"
git -C "$REPO_ROOT" diff --find-renames --name-only --diff-filter=A HEAD \
  >> "$new_file"

# Git cannot label an unstaged delete + untracked destination as a rename. Hash
# deleted Markdown blobs so exact reorganizations are checked for placement but
# do not consume the new-document budget.
while IFS= read -r deleted_path; do
  if is_markdown_path "$deleted_path"; then
    git -C "$REPO_ROOT" show "HEAD:$deleted_path" | shasum -a 256 | \
      awk '{print $1}' >> "$deleted_hash_file"
  fi
done < <(git -C "$REPO_ROOT" diff --name-only --diff-filter=D HEAD)

while IFS= read -r path; do
  printf '%s\n' "$path" >> "$candidate_file"
  if is_markdown_path "$path"; then
    current_hash="$(shasum -a 256 "$REPO_ROOT/$path" | awk '{print $1}')"
    if grep -Fqx -- "$current_hash" "$deleted_hash_file"; then
      # A deleted source excuses exactly one identical destination. Consuming
      # the hash prevents one deletion from masking an arbitrary copy burst.
      awk -v target="$current_hash" '
        !removed && $0 == target { removed = 1; next }
        { print }
      ' "$deleted_hash_file" > "$deleted_hash_next_file"
      mv "$deleted_hash_next_file" "$deleted_hash_file"
      continue
    fi
  fi
  printf '%s\n' "$path" >> "$new_file"
done < <(git -C "$REPO_ROOT" ls-files --others --exclude-standard)

# Ignored Markdown is still local clutter. Disposable dependency/build trees
# are excluded because their contents are tool-owned.
while IFS= read -r path; do
  case "$path" in
    .dart_tool/*|build/*|node_modules/*|*/.dart_tool/*|*/build/*|*/node_modules/*|*/macos/Pods/*|sprites-master/*)
      continue
      ;;
  esac
  printf '%s\n' "$path" >> "$candidate_file"
  printf '%s\n' "$path" >> "$new_file"
  printf '%s\n' "$path" >> "$ignored_file"
done < <(
  git -C "$REPO_ROOT" ls-files --others --ignored --exclude-standard -- \
    ':(icase,glob)**/*.md' \
    ':(icase,glob)**/*.mdx' \
    ':(icase,glob)**/*.markdown'
)

sort -u "$candidate_file" | while IFS= read -r path; do
  if is_markdown_path "$path"; then
    printf '%s\n' "$path"
  fi
done > "$markdown_file"

sort -u "$new_file" | while IFS= read -r path; do
  if is_markdown_path "$path"; then
    printf '%s\n' "$path"
  fi
done > "$new_markdown_file"

candidate_count="$(wc -l < "$markdown_file" | tr -d ' ')"
new_count="$(wc -l < "$new_markdown_file" | tr -d ' ')"
if [[ "$candidate_count" -eq 0 ]]; then
  echo "Markdown hygiene: no new Markdown files."
  exit 0
fi

errors=0
while IFS= read -r path; do
  if is_markdown_path "$path"; then
    echo "Ignored Markdown is not allowed outside tool-owned generated directories: $path" >&2
    errors=1
  fi
done < "$ignored_file"

while IFS= read -r path; do
  lower_path="$(printf '%s' "$path" | tr '[:upper:]' '[:lower:]')"

  # Whole-source copies are redundant with Git and caused some of the largest
  # historical reports in this repository.
  if [[ "$lower_path" == *created_files_full_content* ]]; then
    echo "Forbidden generated source snapshot: $path (created_files_full_content)" >&2
    errors=1
  fi

  if grep -Fqx -- "$path" "$new_markdown_file" && \
    [[ -f "$REPO_ROOT/$path" ]]; then
    file_size="$(wc -c < "$REPO_ROOT/$path" | tr -d ' ')"
    if [[ "$file_size" -gt "$MAX_BYTES" ]]; then
      echo "Oversized new Markdown: $path is $file_size bytes and exceeds $MAX_BYTES bytes." >&2
      errors=1
    fi
  fi

  case "$path" in
    README.md|documentation/reports/*|documentation/*/*|skills/*/*|plugins/*/skills/*/*)
      ;;
    */README.md|*/CHANGELOG.md|*/CONTRIBUTING.md|*/SECURITY.md|*/AGENTS.md)
      ;;
    *)
      echo "Non-canonical Markdown location: $path" >&2
      errors=1
      ;;
  esac
done < "$markdown_file"

if [[ "$new_count" -gt "$MAX_NEW" ]]; then
  echo "Markdown hygiene: $new_count new Markdown files exceed the default limit of $MAX_NEW." >&2
  echo "Use POKEMAP_MARKDOWN_MAX_NEW only when the user explicitly approved a bounded bulk documentation task." >&2
  errors=1
fi

if [[ "$errors" -ne 0 ]]; then
  exit 1
fi

echo "Markdown hygiene: $new_count new Markdown file(s), all in canonical locations."
