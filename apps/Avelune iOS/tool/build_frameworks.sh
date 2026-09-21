#!/bin/bash
# Rebuilds the Flutter frameworks the Xcode project embeds.
#
# `flutter pub get` regenerates flutter_runtime/.ios and drops the SWIFT_VERSION
# attribute the Runner target needs, which makes `pod install` fail during the
# framework build. Re-apply it every time rather than once at setup.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT/flutter_runtime"

flutter pub get

cd .ios
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
cd ..

# --no-plugins keeps CocoaPods from compiling plugin frameworks; the host app
# supplies plugin implementations itself.
flutter build ios-framework --no-profile --no-plugins --output="$ROOT/flutter_runtime/build/ios/framework"

cd "$ROOT"
python3 tool/sync_frameworks.py
xcodegen generate
