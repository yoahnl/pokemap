#!/usr/bin/env bash
set -euo pipefail

test "$(uname -s)" = Darwin
export OPENSSL_BIN="${OPENSSL_BIN:-$(brew --prefix openssl@3)/bin/openssl}"
test "$#" = 2
contract_path="$1"
output_dir="$2"
test -f "$contract_path"
test ! -e "$output_dir"
mkdir -p "$output_dir"
version="$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1]))["version"])' "$contract_path")"
build_number="$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1]))["buildNumber"])' "$contract_path")"
revision="$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1]))["revision"])' "$contract_path")"
tag="avelune-converter-v$version"
for name in DEVELOPER_ID_P12_BASE64 DEVELOPER_ID_P12_PASSWORD KEYCHAIN_PASSWORD DEVELOPER_ID_APPLICATION APPLE_ID APPLE_TEAM_ID APP_SPECIFIC_PASSWORD AVELUNE_CONVERTER_SPARKLE_PUBLIC_ED_KEY AVELUNE_CONVERTER_SPARKLE_PRIVATE_ED_KEY_BASE64; do
  test -n "${!name:-}" || { echo "Missing release configuration: $name" >&2; exit 65; }
done
release_tmp="$(mktemp -d)"
keychain_path="$release_tmp/converter-release.keychain-db"
security list-keychains -d user > "$release_tmp/original-keychains"
cleanup() {
  python3 - "$release_tmp/original-keychains" <<'PY'
import shlex, subprocess, sys
subprocess.run(['security', 'list-keychains', '-d', 'user', '-s', *shlex.split(open(sys.argv[1]).read())], check=True)
PY
  security delete-keychain "$keychain_path" >/dev/null 2>&1 || true
  rm -rf "$release_tmp"
}
trap cleanup EXIT
umask 077
printf '%s' "$DEVELOPER_ID_P12_BASE64" | base64 --decode > "$release_tmp/developer-id.p12"
printf '%s' "$AVELUNE_CONVERTER_SPARKLE_PRIVATE_ED_KEY_BASE64" | base64 --decode > "$release_tmp/sparkle-private.key"
security create-keychain -p "$KEYCHAIN_PASSWORD" "$keychain_path"
security set-keychain-settings -lut 21600 "$keychain_path"
security unlock-keychain -p "$KEYCHAIN_PASSWORD" "$keychain_path"
security import "$release_tmp/developer-id.p12" -P "$DEVELOPER_ID_P12_PASSWORD" -t cert -f pkcs12 -k "$keychain_path" -T /usr/bin/codesign
security set-key-partition-list -S apple-tool:,apple: -k "$KEYCHAIN_PASSWORD" "$keychain_path"
security list-keychains -d user -s "$keychain_path"
flutter build macos --release --build-name="$version" --build-number="$build_number" \
  --dart-define="AVELUNE_CONVERTER_VERSION=$version" \
  --dart-define="AVELUNE_CONVERTER_BUILD_NUMBER=$build_number" \
  --dart-define="AVELUNE_CONVERTER_REVISION=$revision"
app_path='build/macos/Build/Products/Release/Avelune Converter.app'
plist="$app_path/Contents/Info.plist"
plutil -replace SUPublicEDKey -string "$AVELUNE_CONVERTER_SPARKLE_PUBLIC_ED_KEY" "$plist"
python3 - "$plist" "$version" "$build_number" <<'PY'
import base64, os, plistlib, sys
p = plistlib.load(open(sys.argv[1], 'rb'))
expected = {
    'CFBundleIdentifier': 'com.yoahnl.avelune.converter',
    'CFBundleShortVersionString': sys.argv[2], 'CFBundleVersion': sys.argv[3],
    'SUFeedURL': 'https://github.com/yoahnl/pokemap/releases/download/avelune-converter-update-stable/appcast-macos.xml',
    'SURequireSignedFeed': True, 'SUVerifyUpdateBeforeExtraction': True,
    'SUEnableAutomaticChecks': False, 'SUAllowsAutomaticUpdates': False,
    'SUSignedFeedFailureExpirationInterval': 0,
}
if any(p.get(k) != v for k, v in expected.items()):
    raise SystemExit('Built app identity or updater policy differs from the release contract')
if len(base64.b64decode(p['SUPublicEDKey'], validate=True)) != 32:
    raise SystemExit('Expected a dedicated 32-byte Converter Ed25519 public key')
PY
bash ../../tools/release/sign_macos_app.sh --app "$app_path" \
  --identity "$DEVELOPER_ID_APPLICATION" --entitlements macos/Runner/Release.entitlements
xcrun notarytool store-credentials avelune-converter-release \
  --keychain "$keychain_path" --apple-id "$APPLE_ID" --team-id "$APPLE_TEAM_ID" --password "$APP_SPECIFIC_PASSWORD"
bash ../../tools/release/notarize_macos_release.sh --app "$app_path" \
  --dmg "$output_dir/Avelune-Converter-$version-macOS.dmg" \
  --notary-profile avelune-converter-release --notary-keychain "$keychain_path" --result-json "$RUNNER_TEMP/converter-notary-logs/notary-result.json" \
  --log-directory "$RUNNER_TEMP/converter-notary-logs" --volume-name 'Avelune Converter'
archive_name="Avelune-Converter-$version-macOS.app.zip"
ditto -c -k --sequesterRsrc --keepParent "$app_path" "$output_dir/$archive_name"
mkdir "$release_tmp/update"
cp "$output_dir/$archive_name" "$release_tmp/update/$archive_name"
generator="$(find build/macos -type f -path '*/Sparkle/bin/generate_appcast' -perm -111 -print -quit)"
test -n "$generator"
"$generator" --ed-key-file "$release_tmp/sparkle-private.key" \
  --download-url-prefix "https://github.com/yoahnl/pokemap/releases/download/$tag/" \
  --maximum-deltas 0 -o "$output_dir/appcast-macos.xml" "$release_tmp/update"
python3 tool/release_metadata.py create --contract "$contract_path" --directory "$output_dir"
python3 tool/verify_sparkle.py --directory "$output_dir" --public-key "$AVELUNE_CONVERTER_SPARKLE_PUBLIC_ED_KEY"
