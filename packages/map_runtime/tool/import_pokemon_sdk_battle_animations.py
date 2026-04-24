#!/usr/bin/env python3
"""Import Pokemon SDK battle animation PNGs into map_runtime.

The importer intentionally generates a Dart catalog next to the runtime code so
runtime startup never has to inspect the asset bundle.
"""

from __future__ import annotations

import argparse
import re
import shutil
import struct
import unicodedata
from dataclasses import dataclass
from pathlib import Path


PACKAGE_ROOT = Path(__file__).resolve().parents[1]
DEFAULT_SOURCE = Path(
    "/Users/karim/Project/pokemonProject/poke\u0301mon_sdk_test_project/graphics/animations"
)
DESTINATION = PACKAGE_ROOT / "assets" / "battle_animations"
CATALOG_PATH = (
    PACKAGE_ROOT / "lib" / "src" / "presentation" / "flame" / "battle_fx_catalog.dart"
)


@dataclass(frozen=True)
class AssetSpec:
    asset_id: str
    kind: str
    source_file_name: str
    copied_file_name: str
    width: int
    height: int
    frame_width: int
    frame_height: int
    frame_count: int
    columns: int
    rows: int
    origin_x: float
    origin_y: float
    default_scale: float


EXACT_OVERRIDES: dict[str, dict[str, object]] = {
    "acid_armor.png": {
        "asset_id": "acid_armor",
        "kind": "spriteSheet",
        "frame_width": 104,
        "frame_height": 192,
        "frame_count": 4,
        "columns": 4,
        "rows": 1,
        "origin_x": 52,
        "origin_y": 132,
        "default_scale": 1.0,
    },
    "Acrobatics.png": {
        "asset_id": "acrobatics",
        "kind": "spriteSheet",
        "frame_width": 104,
        "frame_height": 192,
        "frame_count": 3,
        "columns": 3,
        "rows": 1,
        "origin_x": 52,
        "origin_y": 132,
        "default_scale": 0.5,
    },
    "aerial_ace.png": {
        "asset_id": "aerial_ace",
        "kind": "spriteSheet",
        "frame_width": 208,
        "frame_height": 192,
        "frame_count": 13,
        "columns": 13,
        "rows": 1,
        "origin_x": 104,
        "origin_y": 132,
        "default_scale": 0.75,
    },
    "air_slash.png": {
        "asset_id": "air_slash",
        "kind": "spriteSheet",
        "frame_width": 208,
        "frame_height": 192,
        "frame_count": 7,
        "columns": 7,
        "rows": 1,
        "origin_x": 104,
        "origin_y": 132,
        "default_scale": 0.75,
    },
    "aqua_ring.png": {
        "asset_id": "aqua_ring",
        "kind": "spriteSheet",
        "frame_width": 104,
        "frame_height": 192,
        "frame_count": 3,
        "columns": 3,
        "rows": 1,
        "origin_x": 52,
        "origin_y": 132,
        "default_scale": 0.75,
    },
    "aqua_tail.png": {
        "asset_id": "aqua_tail",
        "kind": "spriteSheet",
        "frame_width": 104,
        "frame_height": 192,
        "frame_count": 7,
        "columns": 7,
        "rows": 1,
        "origin_x": 52,
        "origin_y": 132,
        "default_scale": 1.0,
    },
    "Assurance.png": {
        "asset_id": "assurance",
        "kind": "spriteSheet",
        "frame_width": 104,
        "frame_height": 192,
        "frame_count": 4,
        "columns": 4,
        "rows": 1,
        "origin_x": 52,
        "origin_y": 132,
        "default_scale": 1.0,
    },
    "Astonish.png": {
        "asset_id": "astonish",
        "kind": "spriteSheet",
        "frame_width": 104,
        "frame_height": 192,
        "frame_count": 5,
        "columns": 5,
        "rows": 1,
        "origin_x": 52,
        "origin_y": 132,
        "default_scale": 1.0,
    },
    "Avalanche.png": {
        "asset_id": "avalanche",
        "kind": "spriteSheet",
        "frame_width": 104,
        "frame_height": 192,
        "frame_count": 19,
        "columns": 19,
        "rows": 1,
        "origin_x": 52,
        "origin_y": 110,
        "default_scale": 1.25,
    },
    "017-thunder02.png": {
        "asset_id": "thunder_02",
        "kind": "spriteSheet",
        "frame_width": 192,
        "frame_height": 192,
        "frame_count": 10,
        "columns": 5,
        "rows": 2,
        "origin_x": 96,
        "origin_y": 192,
        "default_scale": 0.5,
    },
    "vine-whip.png": {
        "asset_id": "vine_whip",
        "kind": "spriteSheet",
        "frame_width": 200,
        "frame_height": 200,
        "frame_count": 56,
        "columns": 7,
        "rows": 8,
        "origin_x": 100,
        "origin_y": 100,
        "default_scale": 1.0,
    },
    "seed-growth.png": {
        "asset_id": "seed_growth",
        "kind": "spriteSheet",
        "frame_width": 32,
        "frame_height": 32,
        "frame_count": 5,
        "columns": 5,
        "rows": 1,
        "origin_x": 16,
        "origin_y": 32,
        "default_scale": 1.0,
    },
    "stat_up.png": {
        "asset_id": "stat_up",
        "kind": "statusSheet",
        "frame_width": 200,
        "frame_height": 200,
        "frame_count": 120,
        "columns": 12,
        "rows": 10,
        "origin_x": 100,
        "origin_y": 200,
        "default_scale": 0.75,
    },
    "stat_down.png": {
        "asset_id": "stat_down",
        "kind": "statusSheet",
        "frame_width": 200,
        "frame_height": 200,
        "frame_count": 120,
        "columns": 12,
        "rows": 10,
        "origin_x": 100,
        "origin_y": 200,
        "default_scale": 0.75,
    },
}


LEGACY_ALIASES: dict[str, str] = {
    "angry": "029_emotion01",
    "blackwisp": "022_darkness01",
    "bluefireball": "015_fire01",
    "bone": "011_weapon06",
    "bottombite": "morsure",
    "caltrop": "nail_1",
    "electroball": "anim008_elec",
    "energyball": "anim006_plante",
    "feather": "vol",
    "fireball": "015_fire01",
    "fist": "003_attack01",
    "fist1": "004_attack02",
    "foot": "attack4us_1",
    "flareball": "flame2_1",
    "gear": "circle_particle",
    "greenmetal1": "anim006_plante",
    "greenmetal2": "grass_1",
    "heart": "status_attract",
    "icicle": "016_ice01",
    "icicle-pink": "016_ice01",
    "iceball": "016_ice01",
    "impact": "003_attack01",
    "leaf1": "effflower_1",
    "leaf2": "grass_1",
    "leftchop": "hand_front_left",
    "leftclaw": "effscythe_1",
    "leftslash": "006_weapon01",
    "lightning": "017_thunder01",
    "mistball": "021_light01",
    "moon": "holy_1",
    "mudwisp": "019_earth01",
    "petal": "effflower_1",
    "pointer": "hand_front_right",
    "poisoncaltrop": "nail_1",
    "poisonwisp": "paralysis_1",
    "pokeball": "0000",
    "rainbow": "shiny",
    "rightchop": "hand_front_right",
    "rightclaw": "effscythe_1",
    "rightslash": "007_weapon02",
    "rock1": "019_earth01",
    "rock2": "2003ground_1",
    "rock3": "019_earth01",
    "rocks": "2003ground_1",
    "shadowball": "022_darkness01",
    "shell": "2003barrier_1",
    "shine": "star",
    "stare": "ray_1",
    "sword": "sword1_1",
    "tatsugiri": "t",
    "topbite": "morsure",
    "waterwisp": "018_water01",
    "web": "alterations_1",
    "wisp": "circle_blurry_m_2",
    "z-symbol": "star_4_ring_l",
}


def normalize(value: str) -> str:
    ascii_value = (
        unicodedata.normalize("NFKD", value).encode("ascii", "ignore").decode("ascii")
    )
    ascii_value = ascii_value.replace("%20", "_")
    normalized = re.sub(r"[^a-zA-Z0-9]+", "_", ascii_value).strip("_").lower()
    normalized = re.sub(r"_+", "_", normalized)
    return normalized or "asset"


def png_size(path: Path) -> tuple[int, int]:
    with path.open("rb") as handle:
        header = handle.read(24)
    if header[:8] != b"\x89PNG\r\n\x1a\n":
        raise ValueError(f"Not a PNG: {path}")
    return struct.unpack(">II", header[16:24])


def make_unique(name: str, used: set[str]) -> str:
    if name not in used:
        used.add(name)
        return name
    index = 2
    while f"{name}_{index}" in used:
        index += 1
    unique = f"{name}_{index}"
    used.add(unique)
    return unique


def infer_kind(relative_path: str) -> str:
    if relative_path.startswith("status/"):
        return "statusSheet"
    if relative_path.startswith("weather/"):
        return "weatherParticle"
    return "singleImage"


def build_specs(source: Path) -> list[AssetSpec]:
    copied_names: set[str] = set()
    asset_ids: set[str] = set()
    specs: list[AssetSpec] = []
    by_id: dict[str, AssetSpec] = {}

    for source_file in sorted(source.rglob("*.png")):
        relative = source_file.relative_to(source).as_posix()
        override = EXACT_OVERRIDES.get(relative) or EXACT_OVERRIDES.get(source_file.name)
        base_id = str(override.get("asset_id")) if override else normalize(relative[:-4])
        asset_id = make_unique(base_id, asset_ids)
        copied_stem = make_unique(normalize(relative[:-4]), copied_names)
        copied_file_name = f"{copied_stem}.png"
        width, height = png_size(source_file)
        kind = str(override.get("kind")) if override else infer_kind(relative)
        frame_width = int(override.get("frame_width", width)) if override else width
        frame_height = int(override.get("frame_height", height)) if override else height
        frame_count = int(override.get("frame_count", 1)) if override else 1
        columns = int(override.get("columns", max(1, width // frame_width))) if override else 1
        rows = int(override.get("rows", max(1, height // frame_height))) if override else 1
        origin_x = float(override.get("origin_x", frame_width / 2)) if override else frame_width / 2
        origin_y = float(override.get("origin_y", frame_height / 2)) if override else frame_height / 2
        default_scale = float(override.get("default_scale", 1.0)) if override else 1.0
        spec = AssetSpec(
            asset_id=asset_id,
            kind=kind,
            source_file_name=relative,
            copied_file_name=copied_file_name,
            width=width,
            height=height,
            frame_width=frame_width,
            frame_height=frame_height,
            frame_count=frame_count,
            columns=columns,
            rows=rows,
            origin_x=origin_x,
            origin_y=origin_y,
            default_scale=default_scale,
        )
        specs.append(spec)
        by_id[asset_id] = spec

    for alias, target in LEGACY_ALIASES.items():
        if alias in by_id or target not in by_id:
            continue
        target_spec = by_id[target]
        specs.append(
            AssetSpec(
                asset_id=alias,
                kind=target_spec.kind,
                source_file_name=f"alias:{target_spec.source_file_name}",
                copied_file_name=target_spec.copied_file_name,
                width=target_spec.width,
                height=target_spec.height,
                frame_width=target_spec.frame_width,
                frame_height=target_spec.frame_height,
                frame_count=target_spec.frame_count,
                columns=target_spec.columns,
                rows=target_spec.rows,
                origin_x=target_spec.origin_x,
                origin_y=target_spec.origin_y,
                default_scale=target_spec.default_scale,
            )
        )

    return sorted(specs, key=lambda spec: spec.asset_id)


def copy_assets(source: Path, specs: list[AssetSpec]) -> None:
    if DESTINATION.exists():
        shutil.rmtree(DESTINATION)
    DESTINATION.mkdir(parents=True)
    copied_by_source = {
        spec.source_file_name: spec.copied_file_name
        for spec in specs
        if not spec.source_file_name.startswith("alias:")
    }
    for relative, copied_file_name in copied_by_source.items():
        shutil.copy2(source / relative, DESTINATION / copied_file_name)


def dart_string(value: str) -> str:
    return value.replace("\\", "\\\\").replace("'", "\\'")


def generate_catalog(specs: list[AssetSpec]) -> str:
    entries = []
    for spec in specs:
        entries.append(
            f"""    '{dart_string(spec.asset_id)}': BattleFxAssetSpec(
      effectId: '{dart_string(spec.asset_id)}',
      assetKey: 'packages/map_runtime/assets/battle_animations/{dart_string(spec.copied_file_name)}',
      sourceFileName: '{dart_string(spec.source_file_name)}',
      kind: BattleFxAssetKind.{spec.kind},
      width: {spec.width},
      height: {spec.height},
      frameWidth: {spec.frame_width},
      frameHeight: {spec.frame_height},
      frameCount: {spec.frame_count},
      columns: {spec.columns},
      rows: {spec.rows},
      originX: {spec.origin_x:g},
      originY: {spec.origin_y:g},
      defaultScale: {spec.default_scale:g},
    ),"""
        )

    return f"""// Generated by tool/import_pokemon_sdk_battle_animations.py.
// Source: {dart_string(str(DEFAULT_SOURCE))}

enum BattleFxAssetKind {{
  singleImage,
  spriteSheet,
  statusSheet,
  weatherParticle,
}}

class BattleFxAssetSpec {{
  const BattleFxAssetSpec({{
    required this.effectId,
    required this.assetKey,
    required this.sourceFileName,
    required this.kind,
    required this.width,
    required this.height,
    required this.frameWidth,
    required this.frameHeight,
    required this.frameCount,
    required this.columns,
    required this.rows,
    required this.originX,
    required this.originY,
    required this.defaultScale,
  }});

  final String effectId;
  final String assetKey;
  final String sourceFileName;
  final BattleFxAssetKind kind;
  final int width;
  final int height;
  final int frameWidth;
  final int frameHeight;
  final int frameCount;
  final int columns;
  final int rows;
  final double originX;
  final double originY;
  final double defaultScale;
}}

final class BattleFxCatalog {{
  static const Map<String, BattleFxAssetSpec> byEffectId =
      <String, BattleFxAssetSpec>{{
{chr(10).join(entries)}
  }};

  static BattleFxAssetSpec require(String effectId) {{
    final spec = byEffectId[effectId];
    if (spec == null) {{
      throw StateError('Unknown battle SDK animation asset: $effectId');
    }}
    return spec;
  }}

  static bool contains(String effectId) => byEffectId.containsKey(effectId);

  static Iterable<String> get allEffectIds => byEffectId.keys;
}}
"""


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--source",
        type=Path,
        default=DEFAULT_SOURCE,
        help="Path to Pokemon SDK graphics/animations",
    )
    args = parser.parse_args()

    source = args.source
    if not source.exists():
        raise SystemExit(f"Source directory does not exist: {source}")
    specs = build_specs(source)
    copy_assets(source, specs)
    CATALOG_PATH.write_text(generate_catalog(specs), encoding="utf-8")
    print(f"Imported {len([s for s in specs if not s.source_file_name.startswith('alias:')])} PNGs")
    print(f"Catalog entries: {len(specs)}")


if __name__ == "__main__":
    main()
