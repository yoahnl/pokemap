#!/bin/sh
# Xcode Cloud post-clone hook, run before package dependencies are resolved.
#
# The Xcode project depends on a local Swift package that is a build artifact
# weighing over a gigabyte, so it cannot live in the repository. Flutter is
# installed here and the package is produced on the spot.
set -e

FLUTTER_REVISION="e3005e3402d9cfa2043114c8bc53c59d12e9b98e"
FLUTTER_HOME="$HOME/flutter"

echo "--- Installation de Flutter ($FLUTTER_REVISION)"
git clone https://github.com/flutter/flutter.git "$FLUTTER_HOME"
git -C "$FLUTTER_HOME" checkout --quiet "$FLUTTER_REVISION"
export PATH="$FLUTTER_HOME/bin:$PATH"

flutter --version
flutter precache --ios

echo "--- Génération du paquet Swift de la runtime"
cd "$CI_PRIMARY_REPOSITORY_PATH/apps/Avelune iOS"
./tool/build_runtime.sh --no-codesign
