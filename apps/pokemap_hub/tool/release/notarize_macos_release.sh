#!/usr/bin/env bash

set -euo pipefail

app_path=''
dmg_path=''
notary_profile=''
result_json=''
log_directory=''

usage() {
  echo 'Usage: notarize_macos_release.sh --app <bundle.app> --dmg <output.dmg> --notary-profile <profile> --result-json <file> [--log-directory <directory>]' >&2
}

while (($# > 0)); do
  case "$1" in
    --app)
      app_path="${2:-}"
      shift 2
      ;;
    --dmg)
      dmg_path="${2:-}"
      shift 2
      ;;
    --notary-profile)
      notary_profile="${2:-}"
      shift 2
      ;;
    --result-json)
      result_json="${2:-}"
      shift 2
      ;;
    --log-directory)
      log_directory="${2:-}"
      shift 2
      ;;
    *)
      usage
      exit 64
      ;;
  esac
done

if [[ -z "$app_path" || -z "$dmg_path" || -z "$notary_profile" || -z "$result_json" ]]; then
  usage
  exit 64
fi
if [[ ! -d "$app_path" || "$app_path" != *.app ]]; then
  echo "App bundle is unavailable: $app_path" >&2
  exit 66
fi
if [[ "$dmg_path" != *.dmg || "$result_json" != *.json ]]; then
  echo 'The DMG and result paths must use .dmg and .json extensions.' >&2
  exit 64
fi

xcrun_bin="${XCRUN_BIN:-/usr/bin/xcrun}"
hdiutil_bin="${HDIUTIL_BIN:-/usr/bin/hdiutil}"
ditto_bin="${DITTO_BIN:-/usr/bin/ditto}"
spctl_bin="${SPCTL_BIN:-/usr/sbin/spctl}"
codesign_bin="${CODESIGN_BIN:-/usr/bin/codesign}"
jq_bin="${JQ_BIN:-jq}"

for required_tool in \
  "$xcrun_bin" \
  "$hdiutil_bin" \
  "$ditto_bin" \
  "$spctl_bin" \
  "$codesign_bin" \
  "$jq_bin"; do
  if ! command -v "$required_tool" >/dev/null 2>&1; then
    echo "Required release tool is unavailable: $required_tool" >&2
    exit 69
  fi
done

if [[ -z "$log_directory" ]]; then
  log_directory="$(/usr/bin/dirname "$result_json")"
fi
/bin/mkdir -p \
  "$(/usr/bin/dirname "$dmg_path")" \
  "$(/usr/bin/dirname "$result_json")" \
  "$log_directory"

temporary_root="$(/usr/bin/mktemp -d "${TMPDIR:-/tmp}/pokemap-notary.XXXXXX")"
cleanup() {
  if [[ -n "${temporary_root:-}" && -d "$temporary_root" ]]; then
    /bin/rm -rf "$temporary_root"
  fi
}
trap cleanup EXIT

app_archive="$temporary_root/PokeMapHub.zip"
app_result="$log_directory/app-notary-result.json"
app_log="$log_directory/app-notary-log.json"
dmg_log="$log_directory/dmg-notary-log.json"

"$codesign_bin" --verify --deep --strict --verbose=4 "$app_path"
"$ditto_bin" -c -k --keepParent "$app_path" "$app_archive"

"$xcrun_bin" notarytool submit "$app_archive" \
  --keychain-profile "$notary_profile" \
  --wait \
  --output-format json > "$app_result"
app_status="$("$jq_bin" -r '.status // empty' "$app_result")"
app_submission_id="$("$jq_bin" -r '.id // empty' "$app_result")"
if [[ "$app_status" != 'Accepted' || -z "$app_submission_id" ]]; then
  echo 'Apple rejected the app notarization submission.' >&2
  exit 65
fi
"$xcrun_bin" notarytool log "$app_submission_id" \
  --keychain-profile "$notary_profile" \
  "$app_log"
"$xcrun_bin" stapler staple "$app_path"
"$xcrun_bin" stapler validate "$app_path"
"$codesign_bin" --verify --deep --strict --verbose=4 "$app_path"
"$spctl_bin" --assess --type execute --verbose=4 "$app_path"

"$hdiutil_bin" create \
  -volname 'PokeMap Hub' \
  -srcfolder "$app_path" \
  -ov \
  -format UDZO \
  "$dmg_path"
"$hdiutil_bin" verify "$dmg_path"

"$xcrun_bin" notarytool submit "$dmg_path" \
  --keychain-profile "$notary_profile" \
  --wait \
  --output-format json > "$result_json"
dmg_status="$("$jq_bin" -r '.status // empty' "$result_json")"
dmg_submission_id="$("$jq_bin" -r '.id // empty' "$result_json")"
if [[ "$dmg_status" != 'Accepted' || -z "$dmg_submission_id" ]]; then
  echo 'Apple rejected the DMG notarization submission.' >&2
  exit 65
fi
"$xcrun_bin" notarytool log "$dmg_submission_id" \
  --keychain-profile "$notary_profile" \
  "$dmg_log"
"$xcrun_bin" stapler staple "$dmg_path"
"$xcrun_bin" stapler validate "$dmg_path"
"$hdiutil_bin" verify "$dmg_path"
"$spctl_bin" --assess \
  --type open \
  --context context:primary-signature \
  --verbose=4 \
  "$dmg_path"

echo "app_notary_submission_id=$app_submission_id"
echo "dmg_notary_submission_id=$dmg_submission_id"
echo 'notarization_verified=true'
