#!/usr/bin/env bash
set -euo pipefail

flame_repository="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
flame_runtime="$flame_repository/packages/map_runtime"
flame_config="$flame_runtime/.dart_tool/package_config.json"

if [[ ! -f "$flame_config" ]]; then
  (cd "$flame_runtime" && flutter pub get)
fi

flame_entry="$(python3 - "$flame_config" <<'PY'
import json
import pathlib
import sys
import urllib.parse

config = pathlib.Path(sys.argv[1])
packages = json.loads(config.read_text())['packages']
package = next((entry for entry in packages if entry['name'] == 'flame_cli'), None)
if package is None:
    raise SystemExit('Run flutter pub get in packages/map_runtime to install Flame CLI.')
root_uri = urllib.parse.urljoin(config.as_uri(), package['rootUri'])
root = pathlib.Path(urllib.parse.unquote(urllib.parse.urlparse(root_uri).path))
print(root / 'bin' / 'flame_cli.dart')
PY
)"

exec dart "--packages=$flame_config" "$flame_entry" "$@"
