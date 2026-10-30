#!/usr/bin/env bash

set -euo pipefail

app_path=''
identity=''
entitlements_path=''
timestamp_enabled=true

usage() {
  echo 'Usage: sign_macos_app.sh --app <bundle.app> --identity <identity> --entitlements <file> [--no-timestamp]' >&2
}

while (($# > 0)); do
  case "$1" in
    --app)
      app_path="${2:-}"
      shift 2
      ;;
    --identity)
      identity="${2:-}"
      shift 2
      ;;
    --entitlements)
      entitlements_path="${2:-}"
      shift 2
      ;;
    --no-timestamp)
      timestamp_enabled=false
      shift
      ;;
    *)
      usage
      exit 64
      ;;
  esac
done

if [[ -z "$app_path" || -z "$identity" || -z "$entitlements_path" ]]; then
  usage
  exit 64
fi
if [[ ! -d "$app_path" || "$app_path" != *.app ]]; then
  echo "App bundle is unavailable: $app_path" >&2
  exit 66
fi
if [[ ! -f "$entitlements_path" ]]; then
  echo "Entitlements are unavailable: $entitlements_path" >&2
  exit 66
fi
if [[ "$timestamp_enabled" == false && "$identity" != '-' ]]; then
  echo '--no-timestamp is restricted to ad hoc test signatures.' >&2
  exit 64
fi

info_plist_path="$app_path/Contents/Info.plist"
if ! bundle_identifier="$(
  /usr/bin/plutil -extract CFBundleIdentifier raw "$info_plist_path" 2>/dev/null
)" || [[ ! "$bundle_identifier" =~ ^[A-Za-z0-9][A-Za-z0-9.-]*$ ]]; then
  echo "The app has no valid CFBundleIdentifier: $app_path" >&2
  exit 66
fi

expanded_entitlements_path="$(
  /usr/bin/mktemp "${TMPDIR:-/tmp}/pokemap-signing-entitlements.XXXXXX"
)"
cleanup() {
  /bin/rm -f "$expanded_entitlements_path"
}
trap cleanup EXIT

/usr/bin/sed \
  -e "s|\$(PRODUCT_BUNDLE_IDENTIFIER)|$bundle_identifier|g" \
  -e "s|\${PRODUCT_BUNDLE_IDENTIFIER}|$bundle_identifier|g" \
  "$entitlements_path" > "$expanded_entitlements_path"
if /usr/bin/grep -q -E \
  '\$\(PRODUCT_BUNDLE_IDENTIFIER\)|\$\{PRODUCT_BUNDLE_IDENTIFIER\}' \
  "$expanded_entitlements_path"; then
  echo 'CFBundleIdentifier expansion failed in release entitlements.' >&2
  exit 65
fi
/usr/bin/plutil -lint "$expanded_entitlements_path" >/dev/null

codesign_arguments=(--force --options runtime)
if [[ "$timestamp_enabled" == true ]]; then
  codesign_arguments+=(--timestamp)
fi
codesign_arguments+=(--sign "$identity")

mcp_path="$app_path/Contents/Resources/mcp"
if [[ -f "$mcp_path/runtime-manifest.json" ]]; then
  helper_entitlements="$(cd "$(dirname "${BASH_SOURCE[0]}")/../pokemap_mcp/native" && pwd)/helper.entitlements"
  headless_entitlements="$(dirname "$helper_entitlements")/headless.entitlements"
  while IFS= read -r -d '' binary; do
    if [[ "$binary" == */Contents/MacOS/* ]]; then
      continue
    fi
    if ! /usr/bin/file -b "$binary" | /usr/bin/grep -q 'Mach-O'; then
      continue
    fi
    if /usr/bin/file -b "$binary" | /usr/bin/grep -q 'executable'; then
      binary_entitlements="$helper_entitlements"
      if [[ "$binary" == */bin/*-headless* ]]; then binary_entitlements="$headless_entitlements"; fi
      if [[ "$binary" == */bin/authoring-* || "$binary" == */bin/node-*x64 ]]; then
        binary_entitlements="$(dirname "$helper_entitlements")/authoring-helper.entitlements"
        if [[ "$binary" == */bin/authoring-headless-* || "$binary" == */bin/node-headless-x64 ]]; then
          binary_entitlements="$(dirname "$helper_entitlements")/authoring-headless.entitlements"
        fi
      fi
      /usr/bin/codesign "${codesign_arguments[@]}" --entitlements "$binary_entitlements" "$binary"
    else
      /usr/bin/codesign "${codesign_arguments[@]}" "$binary"
    fi
  done < <(/usr/bin/find "$mcp_path" -type f -print0)
  while IFS= read -r -d '' bundle; do
    if [[ "$bundle" == *.app ]]; then
      bundle_entitlements="$helper_entitlements"
      if [[ "$bundle" == */runtime-headless.app ]]; then bundle_entitlements="$headless_entitlements"; fi
      /usr/bin/codesign "${codesign_arguments[@]}" --entitlements "$bundle_entitlements" "$bundle"
    else
      /usr/bin/codesign "${codesign_arguments[@]}" "$bundle"
    fi
  done < <(/usr/bin/find "$mcp_path" -depth -type d \( -name '*.framework' -o -name '*.app' \) -print0)
  python3 - "$mcp_path/runtime-manifest.json" <<'PY'
import hashlib
import json
import pathlib
import sys
root = pathlib.Path(sys.argv[1]).resolve(strict=True).parent
for manifest_path in root.glob('runtime-manifest*.json'):
    manifest = json.loads(manifest_path.read_text())
    for component in manifest['components']:
        source = (root / component['path']).resolve(strict=True)
        source.relative_to(root)
        with source.open('rb') as stream:
            component['sha256'] = hashlib.file_digest(stream, 'sha256').hexdigest()
    manifest_path.write_text(json.dumps(manifest, indent=2) + '\n')
PY
fi

frameworks_path="$app_path/Contents/Frameworks"
if [[ -d "$frameworks_path" ]]; then
  while IFS= read -r -d '' binary; do
    if ! /usr/bin/file -b "$binary" | /usr/bin/grep -q 'Mach-O'; then
      continue
    fi
    /usr/bin/codesign "${codesign_arguments[@]}" "$binary"
  done < <(/usr/bin/find "$frameworks_path" -type f -print0)

  while IFS= read -r -d '' bundle; do
    /usr/bin/codesign "${codesign_arguments[@]}" "$bundle"
  done < <(
    /usr/bin/find "$frameworks_path" -depth -type d \
      \( -name '*.framework' -o -name '*.xpc' -o -name '*.app' \) -print0
  )
fi

/usr/bin/codesign \
  "${codesign_arguments[@]}" \
  --entitlements "$expanded_entitlements_path" \
  "$app_path"

/usr/bin/codesign --verify --deep --strict --verbose=4 "$app_path"

if [[ "$identity" != '-' ]]; then
  signature_details="$(
    /usr/bin/codesign --display --verbose=4 "$app_path" 2>&1
  )"
  if [[ "$signature_details" != *'Authority=Developer ID Application:'* ]]; then
    echo 'The app is not signed with a Developer ID Application identity.' >&2
    exit 65
  fi
  team_identifier="$(
    printf '%s\n' "$signature_details" |
      /usr/bin/sed -n 's/^TeamIdentifier=//p' |
      /usr/bin/head -n 1
  )"
  if [[ -z "$team_identifier" || "$team_identifier" == 'not set' ]]; then
    echo 'The Developer ID signature has no TeamIdentifier.' >&2
    exit 65
  fi
  while IFS= read -r -d '' candidate; do
    if ! /usr/bin/file -b "$candidate" | /usr/bin/grep -q 'Mach-O'; then
      continue
    fi
    candidate_details="$(
      /usr/bin/codesign --display --verbose=4 "$candidate" 2>&1
    )"
    candidate_team="$(
      printf '%s\n' "$candidate_details" |
        /usr/bin/sed -n 's/^TeamIdentifier=//p' |
        /usr/bin/head -n 1
    )"
    if [[ "$candidate_team" != "$team_identifier" ]]; then
      echo "Nested code TeamIdentifier mismatch: $candidate" >&2
      exit 65
    fi
  done < <(/usr/bin/find "$app_path/Contents" -type f -print0)
  echo "team_identifier=$team_identifier"
  echo 'team_consistent=true'
fi

echo 'signature_verified=true'
