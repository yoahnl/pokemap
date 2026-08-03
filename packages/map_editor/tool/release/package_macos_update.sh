#!/usr/bin/env bash
set -euo pipefail

app_path=''
version=''
output_dir=''
generate_appcast=''
private_key_file=''
download_url_prefix=''

while [[ $# -gt 0 ]]; do
  case "$1" in
    --app) app_path="$2"; shift 2 ;;
    --version) version="$2"; shift 2 ;;
    --output-dir) output_dir="$2"; shift 2 ;;
    --generate-appcast) generate_appcast="$2"; shift 2 ;;
    --private-key-file) private_key_file="$2"; shift 2 ;;
    --download-url-prefix) download_url_prefix="$2"; shift 2 ;;
    *) echo "Unknown argument: $1" >&2; exit 64 ;;
  esac
done

for required in app_path version output_dir generate_appcast private_key_file download_url_prefix; do
  if [[ -z "${!required}" ]]; then
    echo "Missing required argument: $required" >&2
    exit 64
  fi
done

[[ -d "$app_path" ]] || { echo "App bundle not found: $app_path" >&2; exit 66; }
[[ -x "$generate_appcast" ]] || { echo "generate_appcast not executable" >&2; exit 69; }
[[ -f "$private_key_file" ]] || { echo "Sparkle private key not found" >&2; exit 66; }
[[ "$download_url_prefix" == https://github.com/* ]] || {
  echo "Download prefix must be a trusted GitHub HTTPS URL" >&2
  exit 65
}

mkdir -p "$output_dir"
phase3_tmp="$(mktemp -d)"
trap 'rm -rf "$phase3_tmp"' EXIT

archive_name="PokeMap-Editor-${version}-macOS.app.zip"
archive_path="$output_dir/$archive_name"
ditto -c -k --sequesterRsrc --keepParent "$app_path" "$archive_path"
cp "$archive_path" "$phase3_tmp/$archive_name"

"$generate_appcast" \
  --ed-key-file "$private_key_file" \
  --download-url-prefix "$download_url_prefix" \
  --maximum-deltas 0 \
  -o "$output_dir/appcast-macos.xml" \
  "$phase3_tmp"

grep -q 'sparkle:edSignature=' "$output_dir/appcast-macos.xml"
codesign --verify --deep --strict --verbose=2 "$app_path"
