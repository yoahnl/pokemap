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

codesign_arguments=(--force --options runtime)
if [[ "$timestamp_enabled" == true ]]; then
  codesign_arguments+=(--timestamp)
fi
codesign_arguments+=(--sign "$identity")

frameworks_path="$app_path/Contents/Frameworks"
if [[ -d "$frameworks_path" ]]; then
  while IFS= read -r -d '' binary; do
    /usr/bin/codesign "${codesign_arguments[@]}" "$binary"
  done < <(
    /usr/bin/find "$frameworks_path" -type f \
      \( -name '*.dylib' -o -perm -111 \) -print0
  )

  while IFS= read -r -d '' bundle; do
    /usr/bin/codesign "${codesign_arguments[@]}" "$bundle"
  done < <(
    /usr/bin/find "$frameworks_path" -depth -type d \
      \( -name '*.framework' -o -name '*.xpc' -o -name '*.app' \) -print0
  )
fi

/usr/bin/codesign \
  "${codesign_arguments[@]}" \
  --entitlements "$entitlements_path" \
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
