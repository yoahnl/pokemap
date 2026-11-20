#!/usr/bin/env bash

set -euo pipefail

app_path=''
dmg_path=''

usage() {
  echo 'Usage: package_macos_preview.sh --app <bundle.app> --dmg <output.dmg>' >&2
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
    *)
      usage
      exit 64
      ;;
  esac
done

if [[ -z "$app_path" || -z "$dmg_path" ]]; then
  usage
  exit 64
fi
if [[ ! -d "$app_path" || "$app_path" != *.app ]]; then
  echo "PokeMap app bundle is unavailable: $app_path" >&2
  exit 66
fi
if [[ "$dmg_path" != *.dmg ]]; then
  echo 'The PokeMap disk image must use the .dmg extension.' >&2
  exit 64
fi

hdiutil_bin="${HDIUTIL_BIN:-/usr/bin/hdiutil}"
if ! command -v "$hdiutil_bin" >/dev/null 2>&1; then
  echo "Required release tool is unavailable: $hdiutil_bin" >&2
  exit 69
fi

/bin/mkdir -p "$(/usr/bin/dirname "$dmg_path")"
"$hdiutil_bin" create \
  -volname 'PokeMap' \
  -srcfolder "$app_path" \
  -ov \
  -format UDZO \
  "$dmg_path"
"$hdiutil_bin" verify "$dmg_path"

echo "dmg_path=$dmg_path"
echo 'dmg_verified=true'
