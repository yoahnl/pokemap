#!/usr/bin/env python3
"""Generate the static RMXP animation catalog used by the battle runtime.

Pokemon SDK stores generic move animations in RPG Maker XP data:
- Data/Animations.rxdata.yml contains RPG::Animation frames/cells/timings.
- Data/PSP_MTAU.dat maps move ids to user-side animations.
- Data/PSP_MTAT.dat maps move ids to target-side animations.

Runtime code should not parse Ruby/YAML data, so this tool snapshots the local
SDK data into a typed Dart catalog.
"""

from __future__ import annotations

import argparse
import json
import re
import subprocess
import unicodedata
from urllib.parse import unquote
from dataclasses import dataclass
from pathlib import Path
from typing import Any

import yaml


PACKAGE_ROOT = Path(__file__).resolve().parents[1]
DEFAULT_SDK_PROJECT = Path(
    "/Users/karim/Project/pokemonProject/poke\u0301mon_sdk_test_project"
)
OUTPUT = (
    PACKAGE_ROOT
    / "lib"
    / "src"
    / "presentation"
    / "flame"
    / "battle_sdk_rmxp_animation_catalog.dart"
)
SPEC_OUTPUT = (
    PACKAGE_ROOT
    / "lib"
    / "src"
    / "presentation"
    / "flame"
    / "battle_sdk_rmxp_animation_spec.dart"
)
BINARY_OUTPUT = (
    PACKAGE_ROOT
    / "assets"
    / "battle_animations"
    / "rmxp_animation_catalog.bin"
)


@dataclass(frozen=True)
class RmxpCell:
    index: int
    pattern: int
    x: int
    y: int
    zoom: int
    angle: int
    mirror: bool
    opacity: int
    blend_type: int


@dataclass(frozen=True)
class RmxpFrame:
    cell_max: int
    cells: tuple[RmxpCell, ...]


@dataclass(frozen=True)
class RmxpTiming:
    frame: int
    condition: int
    flash_scope: int
    flash_duration: int
    red: int
    green: int
    blue: int
    alpha: int
    se_name: str | None
    se_volume: int
    se_pitch: int


@dataclass(frozen=True)
class RmxpAnimation:
    id: int
    name: str
    animation_name: str
    asset_id: str
    animation_hue: int
    position: int
    frame_max: int
    option: str
    force_no_reverse: bool
    frames: tuple[RmxpFrame, ...]
    timings: tuple[RmxpTiming, ...]


def _normalize_asset_id(value: str) -> str:
    normalized = unicodedata.normalize("NFKD", unquote(value))
    normalized = normalized.encode("ascii", "ignore").decode("ascii")
    normalized = normalized.lower()
    normalized = re.sub(r"[^a-z0-9]+", "_", normalized)
    normalized = normalized.strip("_")
    return normalized or "0000"


def _normalize_move_id(value: str) -> str:
    normalized = unicodedata.normalize("NFKD", value)
    normalized = normalized.encode("ascii", "ignore").decode("ascii")
    normalized = normalized.lower()
    normalized = re.sub(r"[^a-z0-9]+", "", normalized)
    return normalized


def _as_int(value: Any, default: int = 0) -> int:
    if value is None:
        return default
    try:
        return int(value)
    except (TypeError, ValueError):
        return default


def _as_bool(value: Any) -> bool:
    if isinstance(value, bool):
        return value
    return str(value).lower() in {"true", "1", "yes"}


def _parse_table_rows(raw: str) -> list[list[int]]:
    rows: list[list[int]] = []
    for line in raw.splitlines():
        stripped = line.strip()
        if not stripped or stripped.startswith("init ") or stripped == "z = 0":
            continue
        rows.append([int(piece) for piece in stripped.split()])
    return rows


def _parse_frame(frame_data: dict[str, Any]) -> RmxpFrame:
    cell_max = _as_int(frame_data.get("cell_max"))
    table = frame_data.get("cell_data") or {}
    rows = _parse_table_rows(str(table.get("data") or ""))
    cells: list[RmxpCell] = []
    if len(rows) >= 8 and cell_max > 0:
        width = min(cell_max, *(len(row) for row in rows[:8]))
        for index in range(width):
            pattern = rows[0][index]
            if pattern < 0:
                continue
            cells.append(
                RmxpCell(
                    index=index,
                    pattern=pattern,
                    x=rows[1][index],
                    y=rows[2][index],
                    zoom=rows[3][index],
                    angle=rows[4][index],
                    mirror=_as_bool(rows[5][index]),
                    opacity=rows[6][index],
                    blend_type=rows[7][index],
                )
            )
    return RmxpFrame(cell_max=cell_max, cells=tuple(cells))


def _parse_timing(timing_data: dict[str, Any]) -> RmxpTiming:
    color = timing_data.get("flash_color") or {}
    se = timing_data.get("se") or {}
    se_name = str(se.get("name") or "")
    return RmxpTiming(
        frame=_as_int(timing_data.get("frame")),
        condition=_as_int(timing_data.get("condition")),
        flash_scope=_as_int(timing_data.get("flash_scope")),
        flash_duration=_as_int(timing_data.get("flash_duration")),
        red=_as_int(color.get("red")),
        green=_as_int(color.get("green")),
        blue=_as_int(color.get("blue")),
        alpha=_as_int(color.get("alpha")),
        se_name=se_name or None,
        se_volume=_as_int(se.get("volume"), 100),
        se_pitch=_as_int(se.get("pitch"), 100),
    )


def _animation_option(name: str) -> tuple[str, bool]:
    prefix = name.split("/", 1)[0] if "/" in name else ""
    if "N" in prefix:
        return "normal", True
    if "R" in prefix:
        return "rotateOnReverse", False
    if "M" in prefix:
        return "mirrorOnReverse", False
    return "normal", False


def _load_animations(path: Path) -> list[RmxpAnimation]:
    with path.open(encoding="utf-8") as handle:
        raw = yaml.load(handle, Loader=yaml.BaseLoader)
    animations: list[RmxpAnimation] = []
    for entry in raw:
        if not isinstance(entry, dict):
            continue
        animation_name = str(entry.get("animation_name") or "")
        name = str(entry.get("name") or "")
        option, force_no_reverse = _animation_option(name)
        animations.append(
            RmxpAnimation(
                id=_as_int(entry.get("id")),
                name=name,
                animation_name=animation_name,
                asset_id=_normalize_asset_id(animation_name),
                animation_hue=_as_int(entry.get("animation_hue")),
                position=_as_int(entry.get("position")),
                frame_max=_as_int(entry.get("frame_max")),
                option=option,
                force_no_reverse=force_no_reverse,
                frames=tuple(
                    _parse_frame(frame)
                    for frame in (entry.get("frames") or [])
                    if isinstance(frame, dict)
                ),
                timings=tuple(
                    _parse_timing(timing)
                    for timing in (entry.get("timings") or [])
                    if isinstance(timing, dict)
                ),
            )
        )
    return animations


def _load_marshal_hash(path: Path) -> dict[int, int | None]:
    ruby = (
        "require 'json'; "
        "hash = Marshal.load(File.binread(ARGV[0])); "
        "puts JSON.generate(hash)"
    )
    output = subprocess.check_output(["ruby", "-e", ruby, str(path)], text=True)
    raw = json.loads(output)
    return {int(key): value for key, value in raw.items()}


def _load_move_ids(moves_dir: Path) -> dict[str, int]:
    result: dict[str, int] = {}
    for path in sorted(moves_dir.glob("*.json")):
        data = json.loads(path.read_text(encoding="utf-8"))
        sdk_move_id = _as_int(data.get("id"))
        if sdk_move_id <= 0:
            continue
        candidates = {
            path.stem,
            str(data.get("dbSymbol") or ""),
        }
        for candidate in candidates:
            normalized = _normalize_move_id(candidate)
            if normalized:
                result[normalized] = sdk_move_id
    return result


def _quote(value: str) -> str:
    return json.dumps(value, ensure_ascii=False)


_OPTION_INDEX = {
    "normal": 0,
    "rotateOnReverse": 1,
    "mirrorOnReverse": 2,
}

_NULL_STRING_INDEX = 0xFFFF


def _encode_binary(animations: list[RmxpAnimation]) -> bytes:
    """Encode le catalogue au format binaire v1.

    Doit rester le miroir exact de
    lib/src/presentation/flame/battle_sdk_rmxp_animation_codec.dart
    (decodeRmxpAnimationCatalog). Toute evolution du format doit toucher les
    deux fichiers et incrementer la version.
    """
    import struct

    strings: dict[str, int] = {}

    def intern(value: str) -> int:
        if value not in strings:
            strings[value] = len(strings)
        return strings[value]

    ordered = sorted(animations, key=lambda item: item.id)
    for animation in ordered:
        intern(animation.name)
        intern(animation.animation_name)
        intern(animation.asset_id)
        for timing in animation.timings:
            if timing.se_name is not None:
                intern(timing.se_name)
    if len(strings) >= _NULL_STRING_INDEX:
        raise ValueError("RMXP catalog string table overflow")

    out = bytearray()
    out += b"RMXA"
    out += struct.pack("<B", 1)
    out += struct.pack("<H", len(strings))
    for value in strings:
        encoded = value.encode("utf-8")
        out += struct.pack("<H", len(encoded))
        out += encoded
    out += struct.pack("<H", len(ordered))
    for animation in ordered:
        out += struct.pack("<i", animation.id)
        out += struct.pack("<H", intern(animation.name))
        out += struct.pack("<H", intern(animation.animation_name))
        out += struct.pack("<H", intern(animation.asset_id))
        out += struct.pack("<h", animation.animation_hue)
        out += struct.pack("<B", animation.position)
        out += struct.pack("<H", animation.frame_max)
        out += struct.pack("<B", _OPTION_INDEX[animation.option])
        out += struct.pack("<B", 1 if animation.force_no_reverse else 0)
        out += struct.pack("<H", len(animation.frames))
        for frame in animation.frames:
            out += struct.pack("<H", frame.cell_max)
            out += struct.pack("<H", len(frame.cells))
            for cell in frame.cells:
                out += struct.pack(
                    "<hhhhhh",
                    cell.index,
                    cell.pattern,
                    cell.x,
                    cell.y,
                    cell.zoom,
                    cell.angle,
                )
                out += struct.pack("<B", 1 if cell.mirror else 0)
                out += struct.pack("<h", cell.opacity)
                out += struct.pack("<B", cell.blend_type)
        out += struct.pack("<H", len(animation.timings))
        for timing in animation.timings:
            out += struct.pack("<hh", timing.frame, timing.condition)
            out += struct.pack("<B", timing.flash_scope)
            out += struct.pack(
                "<hhhhh",
                timing.flash_duration,
                timing.red,
                timing.green,
                timing.blue,
                timing.alpha,
            )
            se_index = (
                _NULL_STRING_INDEX
                if timing.se_name is None
                else intern(timing.se_name)
            )
            out += struct.pack("<H", se_index)
            out += struct.pack("<hh", timing.se_volume, timing.se_pitch)
    return bytes(out)


def _dart_int_map(name: str, values: dict[int, int | None]) -> str:
    entries = ",".join(
        f"{key}:{'null' if value is None else value}"
        for key, value in sorted(values.items())
    )
    return f"static const Map<int,int?> {name}=<int,int?>{{{entries}}};"


def _dart_move_id_map(values: dict[str, int]) -> str:
    entries = ",".join(f"{_quote(key)}:{value}" for key, value in sorted(values.items()))
    return (
        "static const Map<String,int> sdkMoveIdByNormalizedMoveId="
        f"<String,int>{{{entries}}};"
    )


_GENERATED_HEADER = f"""// Generated by tool/import_pokemon_sdk_rmxp_animations.py.
// Sources:
// - {DEFAULT_SDK_PROJECT}/Data/Animations.rxdata.yml
// - {DEFAULT_SDK_PROJECT}/Data/PSP_MTAU.dat
// - {DEFAULT_SDK_PROJECT}/Data/PSP_MTAT.dat
//
// Do not edit by hand. Re-run the importer when SDK data changes.

// ignore_for_file: lines_longer_than_80_chars
"""


def _generate_spec_dart() -> str:
    return _GENERATED_HEADER + """
enum RmxpAnimationOption {
  normal,
  rotateOnReverse,
  mirrorOnReverse,
}

final class RmxpAnimationCellSpec {
  const RmxpAnimationCellSpec({
    required this.index,
    required this.pattern,
    required this.x,
    required this.y,
    required this.zoom,
    required this.angle,
    required this.mirror,
    required this.opacity,
    required this.blendType,
  });

  final int index;
  final int pattern;
  final int x;
  final int y;
  final int zoom;
  final int angle;
  final bool mirror;
  final int opacity;
  final int blendType;
}

final class RmxpAnimationFrameSpec {
  const RmxpAnimationFrameSpec({
    required this.cellMax,
    required this.cells,
  });

  final int cellMax;
  final List<RmxpAnimationCellSpec> cells;
}

final class RmxpAnimationTimingSpec {
  const RmxpAnimationTimingSpec({
    required this.frame,
    required this.condition,
    required this.flashScope,
    required this.flashDuration,
    required this.flashRed,
    required this.flashGreen,
    required this.flashBlue,
    required this.flashAlpha,
    required this.seName,
    required this.seVolume,
    required this.sePitch,
  });

  final int frame;
  final int condition;
  final int flashScope;
  final int flashDuration;
  final int flashRed;
  final int flashGreen;
  final int flashBlue;
  final int flashAlpha;
  final String? seName;
  final int seVolume;
  final int sePitch;
}

final class RmxpAnimationSpec {
  const RmxpAnimationSpec({
    required this.id,
    required this.name,
    required this.animationName,
    required this.assetId,
    required this.animationHue,
    required this.position,
    required this.frameMax,
    required this.option,
    required this.forceNoReverse,
    required this.frames,
    required this.timings,
  });

  static const double frameDurationSeconds = 0.05;

  final int id;
  final String name;
  final String animationName;
  final String assetId;
  final int animationHue;
  final int position;
  final int frameMax;
  final RmxpAnimationOption option;
  final bool forceNoReverse;
  final List<RmxpAnimationFrameSpec> frames;
  final List<RmxpAnimationTimingSpec> timings;

  double get durationSeconds => frameMax * frameDurationSeconds;
}
"""


def _generate_catalog_dart(
    target_map: dict[int, int | None],
    user_map: dict[int, int | None],
    move_ids: dict[str, int],
) -> str:
    user_non_null = {key: value for key, value in user_map.items() if value is not None}
    return _GENERATED_HEADER + f"""
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'battle_sdk_rmxp_animation_codec.dart';
import 'battle_sdk_rmxp_animation_spec.dart';

export 'battle_sdk_rmxp_animation_spec.dart';

final class BattleSdkRmxpAnimationCatalog {{
  /// Les specs d'animation vivent dans
  /// `assets/battle_animations/rmxp_animation_catalog.bin`, decodees
  /// paresseusement au premier combat via [ensureLoaded].
  static const String _assetPath =
      'assets/battle_animations/rmxp_animation_catalog.bin';

  static Map<int, RmxpAnimationSpec>? _loaded;
  static Future<Map<int, RmxpAnimationSpec>>? _loading;

  static bool get isLoaded => _loaded != null;

  /// Catalogue decode. Exige un [ensureLoaded] prealable — fait par
  /// `BattleOverlayComponent.onLoad`, donc avant toute planification
  /// d'animation d'un combat monte.
  static Map<int, RmxpAnimationSpec> get byAnimationId {{
    final loaded = _loaded;
    if (loaded == null) {{
      throw StateError(
        'BattleSdkRmxpAnimationCatalog is not loaded. '
        'Await BattleSdkRmxpAnimationCatalog.ensureLoaded() first.',
      );
    }}
    return loaded;
  }}

  static Future<void> ensureLoaded({{AssetBundle? bundle}}) async {{
    if (_loaded != null) {{
      return;
    }}
    final loading = _loading ??= _load(bundle ?? rootBundle);
    try {{
      _loaded = await loading;
    }} catch (_) {{
      if (identical(_loading, loading)) {{
        _loading = null;
      }}
      rethrow;
    }}
  }}

  static Future<Map<int, RmxpAnimationSpec>> _load(AssetBundle bundle) async {{
    ByteData data;
    try {{
      // Cle cote app hote (le package est une dependance).
      data = await bundle.load('packages/map_runtime/$_assetPath');
    }} on Object {{
      // Cle cote tests / execution du package lui-meme.
      data = await bundle.load(_assetPath);
    }}
    return decodeRmxpAnimationCatalog(
      data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
    );
  }}

  @visibleForTesting
  static void debugReset() {{
    _loaded = null;
    _loading = null;
  }}

  {_dart_int_map("moveTargetAnimationIdBySdkMoveId", target_map)}

  {_dart_int_map("moveUserAnimationIdBySdkMoveId", user_non_null)}

  static RmxpAnimationSpec require(int animationId) {{
    final spec = byAnimationId[animationId];
    if (spec == null) {{
      throw StateError('Unknown Pokemon SDK RMXP animation id: $animationId');
    }}
    return spec;
  }}

  static bool hasMoveAnimation(int sdkMoveId) {{
    return moveUserAnimationIdBySdkMoveId[sdkMoveId] != null ||
        moveTargetAnimationIdBySdkMoveId[sdkMoveId] != null;
  }}
}}

final class BattleSdkMoveIdCatalog {{
  {_dart_move_id_map(move_ids)}
}}
"""


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--sdk-project", type=Path, default=DEFAULT_SDK_PROJECT)
    parser.add_argument("--output", type=Path, default=OUTPUT)
    parser.add_argument("--spec-output", type=Path, default=SPEC_OUTPUT)
    parser.add_argument("--binary-output", type=Path, default=BINARY_OUTPUT)
    args = parser.parse_args()

    data_dir = args.sdk_project / "Data"
    animations = _load_animations(data_dir / "Animations.rxdata.yml")
    target_map = _load_marshal_hash(data_dir / "PSP_MTAT.dat")
    user_map = _load_marshal_hash(data_dir / "PSP_MTAU.dat")
    move_ids = _load_move_ids(data_dir / "Studio" / "moves")

    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.spec_output.write_text(_generate_spec_dart(), encoding="utf-8")
    args.output.write_text(
        _generate_catalog_dart(target_map, user_map, move_ids), encoding="utf-8"
    )
    args.binary_output.parent.mkdir(parents=True, exist_ok=True)
    binary = _encode_binary(animations)
    args.binary_output.write_bytes(binary)
    print(f"Wrote {args.spec_output}")
    print(f"Wrote {args.output}")
    print(f"Wrote {args.binary_output} ({len(binary)} bytes)")
    print(
        f"animations={len(animations)} target={len(target_map)} "
        f"user={sum(1 for value in user_map.values() if value is not None)} "
        f"move_ids={len(move_ids)}"
    )
    print(
        "Verify with: dart run tool/export_rmxp_animation_catalog_asset.dart"
    )


if __name__ == "__main__":
    main()
