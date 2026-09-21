#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR"

echo "=== Avelune iOS — Setup ==="
echo ""

# 1. Flutter module dependencies
echo "[1/4] Installation des dépendances Flutter..."
cd flutter_runtime
flutter pub get
cd ..
echo "  Done."

# 2. Fix SWIFT_VERSION + pod install
echo "[2/4] Configuration iOS..."
cd flutter_runtime/.ios
ruby -e '
require "xcodeproj"
project = Xcodeproj::Project.open("Runner.xcodeproj")
project.targets.each do |target|
  target.build_configurations.each do |config|
    config.build_settings["SWIFT_VERSION"] = "5.0"
  end
end
project.save
'
pod install 2>&1 | grep -v "^\[!\] CocoaPods did not set" || true
cd ../..
echo "  Done."

# 3. Build Flutter frameworks (debug + release for plugin xcframeworks)
echo "[3/4] Build des frameworks Flutter..."
cd flutter_runtime
flutter build ios-framework --no-profile --output="$(pwd)/build/ios/framework"
cd ..
echo "  Done."

# 3b. Regenerate the framework list from what the build actually produced
echo "[3b/4] Synchronisation des frameworks dans project.yml..."
python3 tool/sync_frameworks.py
echo "  Done."

# 4. Generate Xcode project
echo "[4/4] Génération du projet Xcode..."
if command -v xcodegen &> /dev/null; then
    xcodegen generate
    echo "  Done."
    echo ""
    open AveluneiOS.xcodeproj 2>/dev/null || true
else
    echo "  xcodegen non trouvé: brew install xcodegen"
fi

echo ""
echo "=== Setup terminé ==="
echo ""
echo "Pour rebuilder après modification du code Dart:"
echo "  ./tool/build_frameworks.sh"
