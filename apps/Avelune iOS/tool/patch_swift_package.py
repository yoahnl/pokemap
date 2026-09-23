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
VIDEO_PLAYER_MANIFEST = pathlib.Path(
    "FlutterNativeIntegration/.plugins/video_player_avfoundation/darwin/video_player_avfoundation/Package.swift"
)
FLUTTER_DEPENDENCY = '        .product(name: "FlutterFramework", package: "FlutterFramework"),\n'
OBJC_TARGET = '      name: "video_player_avfoundation_objc",\n      dependencies: [\n'
IOS_TARGET = '      name: "video_player_avfoundation_ios",\n'
IOS_DEPENDENCY = f"      dependencies: [\n{FLUTTER_DEPENDENCY}      ],\n"


def insert_dependency(source: str, anchor: str, insertion: str) -> str:
    if anchor + insertion in source:
        return source
    if anchor not in source:
        sys.exit(f"Cible Swift Package introuvable : {anchor.strip()}")
    return source.replace(anchor, anchor + insertion, 1)


def main() -> None:
    output = pathlib.Path(sys.argv[1])
    manifest = output / "FlutterNativeIntegration" / "Package.swift"
    if not manifest.exists():
        sys.exit(f"Manifeste introuvable : {manifest}")

    text = manifest.read_text()
    if DEPENDENCY in text:
        manifest.write_text(text.replace(DEPENDENCY, ""))
        print("  FlutterNativeTools retiré du graphe de l'app.")

    video_player_manifest = output / VIDEO_PLAYER_MANIFEST
    if not video_player_manifest.exists():
        sys.exit(f"Manifeste introuvable : {video_player_manifest}")

    source = video_player_manifest.read_text()
    source = insert_dependency(source, OBJC_TARGET, FLUTTER_DEPENDENCY)
    source = insert_dependency(source, IOS_TARGET, IOS_DEPENDENCY)
    video_player_manifest.write_text(source)


if __name__ == "__main__":
    main()
