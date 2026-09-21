#!/usr/bin/env python3
"""Drops FlutterNativeTools from the generated package graph.

That package exposes a command plugin whose targets are named "Switch to Debug
Mode" and friends. Xcode 26 traps in SPMPIFBuilder.ModuleOrProduct.init on those
names, taking the whole IDE down with it, so the app cannot reference the graph
while it is present.

Nothing is lost: Scripts/flutter_integration.sh builds the assemble and prebuild
tools itself with `swift build` inside the package. Only the Xcode menu item for
switching build modes goes away.
"""
import pathlib
import sys

DEPENDENCY = '        .package(name: "FlutterNativeTools", path: "FlutterNativeTools"),\n'


def main() -> None:
    output = pathlib.Path(sys.argv[1])
    manifest = output / "FlutterNativeIntegration" / "Package.swift"
    if not manifest.exists():
        sys.exit(f"Manifeste introuvable : {manifest}")

    text = manifest.read_text()
    if DEPENDENCY not in text:
        print("  FlutterNativeTools déjà absent, rien à faire.")
        return

    manifest.write_text(text.replace(DEPENDENCY, ""))
    print("  FlutterNativeTools retiré du graphe de l'app.")


if __name__ == "__main__":
    main()
