#!/usr/bin/env python3
"""Rewrite the framework dependency list in project.yml from the built xcframeworks.

The Flutter module gains or loses plugin frameworks whenever its pubspec changes,
so the list is derived from the build output instead of being maintained by hand.
"""
import pathlib
import re
import sys

ROOT = pathlib.Path(__file__).resolve().parent.parent
FRAMEWORK_DIR = ROOT / "flutter_runtime/build/ios/framework/Release"
PROJECT = ROOT / "project.yml"


def framework_entries() -> list[str]:
    names = sorted(p.name for p in FRAMEWORK_DIR.glob("*.xcframework"))
    if not names:
        sys.exit(f"Aucun xcframework dans {FRAMEWORK_DIR}. Lancer d'abord le build Flutter.")
    return [
        f"      - framework: flutter_runtime/build/ios/framework/Release/{name}\n"
        f"        embed: true\n"
        for name in names
    ]


def main() -> None:
    text = PROJECT.read_text()
    block = "    dependencies:\n" + "".join(framework_entries())
    pattern = re.compile(r"^    dependencies:\n(?:      .*\n|\n)*", re.MULTILINE)
    if not pattern.search(text):
        sys.exit("Bloc 'dependencies:' introuvable dans project.yml.")
    PROJECT.write_text(pattern.sub(block, text, count=1))
    print(f"  {len(framework_entries())} frameworks listés.")


if __name__ == "__main__":
    main()
