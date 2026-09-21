#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR"

echo "=== Avelune iOS — Setup ==="
echo ""

if ! command -v xcodegen &> /dev/null; then
    echo "xcodegen est requis: brew install xcodegen"
    exit 1
fi

echo "[1/2] Build de la runtime Flutter en paquet Swift..."
./tool/build_runtime.sh
echo "  Done."

echo "[2/2] Ouverture du projet..."
open AveluneiOS.xcodeproj 2>/dev/null || true
echo "  Done."

echo ""
echo "=== Setup terminé ==="
echo ""
echo "Après modification du code Dart:  ./tool/build_runtime.sh"
echo "Sur simulateur:                   ./tool/build_simulator.sh"
