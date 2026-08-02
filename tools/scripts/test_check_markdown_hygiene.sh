#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
CHECKER="$REPO_ROOT/tools/scripts/check_markdown_hygiene.sh"
TEST_ROOT="$(mktemp -d)"
trap 'rm -rf "$TEST_ROOT"' EXIT

if [[ ! -f "$CHECKER" ]]; then
  echo "Missing checker: $CHECKER" >&2
  exit 1
fi

new_fixture() {
  local name="$1"
  local fixture="$TEST_ROOT/$name"

  mkdir -p "$fixture/tools/scripts"
  cp "$CHECKER" "$fixture/tools/scripts/check_markdown_hygiene.sh"
  git -C "$fixture" init -q
  git -C "$fixture" config user.email "markdown-hygiene@example.invalid"
  git -C "$fixture" config user.name "Markdown Hygiene Test"
  printf '# Historical root debt\n' > "$fixture/legacy.md"
  git -C "$fixture" add legacy.md tools/scripts/check_markdown_hygiene.sh
  git -C "$fixture" commit -qm "test fixture baseline"

  FIXTURE="$fixture"
}

expect_pass() {
  local label="$1"
  shift
  if ! "$@" > "$TEST_ROOT/output.log" 2>&1; then
    echo "FAIL: $label should pass" >&2
    cat "$TEST_ROOT/output.log" >&2
    exit 1
  fi
}

expect_fail_with() {
  local label="$1"
  local expected="$2"
  shift 2
  if "$@" > "$TEST_ROOT/output.log" 2>&1; then
    echo "FAIL: $label should fail" >&2
    exit 1
  fi
  if ! grep -Fq "$expected" "$TEST_ROOT/output.log"; then
    echo "FAIL: $label did not mention '$expected'" >&2
    cat "$TEST_ROOT/output.log" >&2
    exit 1
  fi
}

new_fixture existing_debt
expect_pass \
  "pre-existing Markdown debt is not re-litigated" \
  bash "$FIXTURE/tools/scripts/check_markdown_hygiene.sh"

new_fixture root_sprawl
printf '# Scratch\n' > "$FIXTURE/random_notes.md"
expect_fail_with \
  "new root Markdown is rejected" \
  "random_notes.md" \
  bash "$FIXTURE/tools/scripts/check_markdown_hygiene.sh"

new_fixture canonical_report
mkdir -p "$FIXTURE/documentation/reports/analysis"
printf '# Audit\n' > "$FIXTURE/documentation/reports/analysis/audit.md"
expect_fail_with \
  "persistent Markdown is rejected by default" \
  "default limit of 0" \
  bash "$FIXTURE/tools/scripts/check_markdown_hygiene.sh"
expect_pass \
  "one explicitly scoped report is accepted with a bounded override" \
  env POKEMAP_MARKDOWN_MAX_NEW=1 \
  bash "$FIXTURE/tools/scripts/check_markdown_hygiene.sh"

new_fixture legacy_report_directory
mkdir -p "$FIXTURE/reports/analysis"
printf '# Legacy report\n' > "$FIXTURE/reports/analysis/audit.md"
expect_fail_with \
  "the former reports directory is rejected" \
  "reports/analysis/audit.md" \
  env POKEMAP_MARKDOWN_MAX_NEW=1 \
  bash "$FIXTURE/tools/scripts/check_markdown_hygiene.sh"

new_fixture noncanonical_directory
mkdir -p "$FIXTURE/misc"
printf '# Scratch\n' > "$FIXTURE/misc/notes.md"
expect_fail_with \
  "Markdown outside canonical directories is rejected" \
  "misc/notes.md" \
  bash "$FIXTURE/tools/scripts/check_markdown_hygiene.sh"

new_fixture alternate_markdown_extension
mkdir -p "$FIXTURE/misc"
printf '# Scratch\n' > "$FIXTURE/misc/notes.markdown"
expect_fail_with \
  "alternate Markdown extensions are also checked" \
  "misc/notes.markdown" \
  bash "$FIXTURE/tools/scripts/check_markdown_hygiene.sh"

new_fixture ignored_markdown
printf 'documentation/ignored/\n' > "$FIXTURE/.gitignore"
git -C "$FIXTURE" add .gitignore
git -C "$FIXTURE" commit -qm "ignore generated documentation"
mkdir -p "$FIXTURE/documentation/ignored"
printf '# Hidden clutter\n' > "$FIXTURE/documentation/ignored/hidden.md"
expect_fail_with \
  "new ignored Markdown is still detected" \
  "documentation/ignored/hidden.md" \
  bash "$FIXTURE/tools/scripts/check_markdown_hygiene.sh"

new_fixture generated_build_markdown
printf 'build/\n' > "$FIXTURE/.gitignore"
git -C "$FIXTURE" add .gitignore
git -C "$FIXTURE" commit -qm "ignore generated build output"
mkdir -p "$FIXTURE/build"
printf '# Generated\n' > "$FIXTURE/build/generated.md"
expect_pass \
  "ignored build output remains tool-owned" \
  bash "$FIXTURE/tools/scripts/check_markdown_hygiene.sh"

new_fixture forbidden_rename
mkdir -p "$FIXTURE/documentation/reports/analysis"
printf '# Initially canonical\n' > "$FIXTURE/documentation/reports/analysis/allowed.md"
git -C "$FIXTURE" add documentation/reports/analysis/allowed.md
git -C "$FIXTURE" commit -qm "add canonical report"
mkdir -p "$FIXTURE/misc"
mv "$FIXTURE/documentation/reports/analysis/allowed.md" "$FIXTURE/misc/moved.md"
git -C "$FIXTURE" add -A
expect_fail_with \
  "renaming Markdown to a non-canonical location is rejected" \
  "misc/moved.md" \
  bash "$FIXTURE/tools/scripts/check_markdown_hygiene.sh"

new_fixture unstaged_reorganization
mkdir -p "$FIXTURE/documentation/reports/analysis"
mv "$FIXTURE/legacy.md" "$FIXTURE/documentation/reports/analysis/legacy.md"
expect_pass \
  "an exact unstaged move is validated but not counted as new" \
  bash "$FIXTURE/tools/scripts/check_markdown_hygiene.sh"

new_fixture duplicated_reorganization
mkdir -p "$FIXTURE/documentation/reports/analysis"
cp "$FIXTURE/legacy.md" "$FIXTURE/documentation/reports/analysis/first-copy.md"
cp "$FIXTURE/legacy.md" "$FIXTURE/documentation/reports/analysis/second-copy.md"
rm "$FIXTURE/legacy.md"
expect_fail_with \
  "one deletion cannot excuse multiple identical copies" \
  "1 new Markdown files" \
  bash "$FIXTURE/tools/scripts/check_markdown_hygiene.sh"

new_fixture package_report
mkdir -p "$FIXTURE/packages/map_editor/reports"
printf '# Dispersed report\n' > \
  "$FIXTURE/packages/map_editor/reports/dispersed.md"
expect_fail_with \
  "package-local reports are rejected" \
  "packages/map_editor/reports/dispersed.md" \
  env POKEMAP_MARKDOWN_MAX_NEW=1 \
  bash "$FIXTURE/tools/scripts/check_markdown_hygiene.sh"

new_fixture orphan_report
mkdir -p "$FIXTURE/documentation"
printf '# Misplaced report\n' > "$FIXTURE/documentation/report.md"
expect_fail_with \
  "reports must use the reports directory" \
  "documentation/report.md" \
  env POKEMAP_MARKDOWN_MAX_NEW=1 \
  bash "$FIXTURE/tools/scripts/check_markdown_hygiene.sh"

new_fixture durable_doc
mkdir -p "$FIXTURE/documentation/reference"
printf '# Durable guide\n' > "$FIXTURE/documentation/reference/guide.md"
expect_pass \
  "durable non-report documentation stays under documentation" \
  env POKEMAP_MARKDOWN_MAX_NEW=1 \
  bash "$FIXTURE/tools/scripts/check_markdown_hygiene.sh"

new_fixture legacy_docs_directory
mkdir -p "$FIXTURE/docs/reference"
printf '# Legacy doc\n' > "$FIXTURE/docs/reference/orphan.md"
expect_fail_with \
  "the former docs directory is rejected" \
  "docs/reference/orphan.md" \
  env POKEMAP_MARKDOWN_MAX_NEW=1 \
  bash "$FIXTURE/tools/scripts/check_markdown_hygiene.sh"

new_fixture orphan_skill
mkdir -p "$FIXTURE/skills"
printf '# Orphan skill\n' > "$FIXTURE/skills/orphan.md"
expect_fail_with \
  "skills require a skill directory" \
  "skills/orphan.md" \
  env POKEMAP_MARKDOWN_MAX_NEW=1 \
  bash "$FIXTURE/tools/scripts/check_markdown_hygiene.sh"

new_fixture full_content_snapshot
mkdir -p "$FIXTURE/documentation/reports/analysis"
printf '# Duplicate source dump\n' > \
  "$FIXTURE/documentation/reports/analysis/lot_created_files_full_content.md"
expect_fail_with \
  "full-content source snapshots are rejected" \
  "created_files_full_content" \
  bash "$FIXTURE/tools/scripts/check_markdown_hygiene.sh"

new_fixture oversized_report
mkdir -p "$FIXTURE/documentation/reports/analysis"
head -c 262145 /dev/zero | tr '\0' 'x' > \
  "$FIXTURE/documentation/reports/analysis/oversized.md"
expect_fail_with \
  "oversized Markdown is rejected" \
  "exceeds 262144 bytes" \
  env POKEMAP_MARKDOWN_MAX_NEW=1 \
  bash "$FIXTURE/tools/scripts/check_markdown_hygiene.sh"

new_fixture bulk_reports
mkdir -p "$FIXTURE/documentation/reports/analysis"
printf '# First\n' > "$FIXTURE/documentation/reports/analysis/first.md"
printf '# Second\n' > "$FIXTURE/documentation/reports/analysis/second.md"
expect_fail_with \
  "bulk Markdown creation is rejected by default" \
  "2 new Markdown files" \
  bash "$FIXTURE/tools/scripts/check_markdown_hygiene.sh"
expect_pass \
  "an explicit bounded override permits an approved bulk task" \
  env POKEMAP_MARKDOWN_MAX_NEW=2 \
  bash "$FIXTURE/tools/scripts/check_markdown_hygiene.sh"

echo "PASS: 21 Markdown hygiene scenarios"
