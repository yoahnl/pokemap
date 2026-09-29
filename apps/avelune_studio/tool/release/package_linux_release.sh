#!/usr/bin/env bash
set -euo pipefail

version=''
bundle_dir=''
output_dir=''

while [[ $# -gt 0 ]]; do
  case "$1" in
    --version) version="$2"; shift 2 ;;
    --bundle) bundle_dir="$2"; shift 2 ;;
    --output-dir) output_dir="$2"; shift 2 ;;
    *) echo "Unknown argument: $1" >&2; exit 64 ;;
  esac
done

if [[ ! "$version" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ || -z "$bundle_dir" || -z "$output_dir" ]]; then
  echo 'Usage: package_linux_release.sh --version X.Y.Z --bundle <dir> --output-dir <dir>' >&2
  exit 64
fi

if [[ ! -x "$bundle_dir/pokemap" || ! -d "$bundle_dir/data" || ! -d "$bundle_dir/lib" || ! -s "$bundle_dir/data/studio_icon.png" ]]; then
  echo 'Avelune Studio Linux bundle is incomplete.' >&2
  exit 66
fi

mkdir -p "$output_dir"
archive="$output_dir/PokeMap-Editor-$version-linux-x64.tar.gz"
tar -C "$bundle_dir" -czf "$archive" .
tar -tzf "$archive" > /dev/null
echo "$archive"
