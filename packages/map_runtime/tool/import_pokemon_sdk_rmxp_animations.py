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


def _dart_cell(cell: RmxpCell) -> str:
    return (
        "RmxpAnimationCellSpec("
        f"index:{cell.index},pattern:{cell.pattern},x:{cell.x},y:{cell.y},"
        f"zoom:{cell.zoom},angle:{cell.angle},mirror:{str(cell.mirror).lower()},"
        f"opacity:{cell.opacity},blendType:{cell.blend_type})"
    )


def _dart_frame(frame: RmxpFrame) -> str:
    cells = ",".join(_dart_cell(cell) for cell in frame.cells)
    return (
        "RmxpAnimationFrameSpec("
        f"cellMax:{frame.cell_max},"
        f"cells:<RmxpAnimationCellSpec>[{cells}])"
    )


def _dart_timing(timing: RmxpTiming) -> str:
    se_name = "null" if timing.se_name is None else _quote(timing.se_name)
    return (
        "RmxpAnimationTimingSpec("
        f"frame:{timing.frame},condition:{timing.condition},"
        f"flashScope:{timing.flash_scope},flashDuration:{timing.flash_duration},"
        f"flashRed:{timing.red},flashGreen:{timing.green},"
        f"flashBlue:{timing.blue},flashAlpha:{timing.alpha},"
        f"seName:{se_name},seVolume:{timing.se_volume},sePitch:{timing.se_pitch})"
    )


def _dart_animation(animation: RmxpAnimation) -> str:
    frames = ",".join(_dart_frame(frame) for frame in animation.frames)
    timings = ",".join(_dart_timing(timing) for timing in animation.timings)
    return (
        "RmxpAnimationSpec("
        f"id:{animation.id},"
        f"name:{_quote(animation.name)},"
        f"animationName:{_quote(animation.animation_name)},"
        f"assetId:{_quote(animation.asset_id)},"
        f"animationHue:{animation.animation_hue},"
        f"position:{animation.position},"
        f"frameMax:{animation.frame_max},"
        f"option:RmxpAnimationOption.{animation.option},"
        f"forceNoReverse:{str(animation.force_no_reverse).lower()},"
        f"frames:<RmxpAnimationFrameSpec>[{frames}],"
        f"timings:<RmxpAnimationTimingSpec>[{timings}])"
    )


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


def _generate_dart(
    animations: list[RmxpAnimation],
    target_map: dict[int, int | None],
    user_map: dict[int, int | None],
    move_ids: dict[str, int],
) -> str:
    animation_entries = ",".join(
        f"{animation.id}:{_dart_animation(animation)}"
        for animation in sorted(animations, key=lambda item: item.id)
    )
    user_non_null = {key: value for key, value in user_map.items() if value is not None}
    return f"""// Generated by tool/import_pokemon_sdk_rmxp_animations.py.
// Sources:
// - {DEFAULT_SDK_PROJECT}/Data/Animations.rxdata.yml
// - {DEFAULT_SDK_PROJECT}/Data/PSP_MTAU.dat
// - {DEFAULT_SDK_PROJECT}/Data/PSP_MTAT.dat
//
// Do not edit by hand. Re-run the importer when SDK data changes.

// ignore_for_file: lines_longer_than_80_chars

enum RmxpAnimationOption {{
  normal,
  rotateOnReverse,
  mirrorOnReverse,
}}

final class RmxpAnimationCellSpec {{
  const RmxpAnimationCellSpec({{
    required this.index,
    required this.pattern,
    required this.x,
    required this.y,
    required this.zoom,
    required this.angle,
    required this.mirror,
    required this.opacity,
    required this.blendType,
  }});

  final int index;
  final int pattern;
  final int x;
  final int y;
  final int zoom;
  final int angle;
  final bool mirror;
  final int opacity;
  final int blendType;
}}

final class RmxpAnimationFrameSpec {{
  const RmxpAnimationFrameSpec({{
    required this.cellMax,
    required this.cells,
  }});

  final int cellMax;
  final List<RmxpAnimationCellSpec> cells;
}}

final class RmxpAnimationTimingSpec {{
  const RmxpAnimationTimingSpec({{
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
  }});

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
}}

final class RmxpAnimationSpec {{
  const RmxpAnimationSpec({{
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
  }});

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
}}

final class BattleSdkRmxpAnimationCatalog {{
  static const Map<int,RmxpAnimationSpec> byAnimationId=<int,RmxpAnimationSpec>{{{animation_entries}}};

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
    args = parser.parse_args()

    data_dir = args.sdk_project / "Data"
    animations = _load_animations(data_dir / "Animations.rxdata.yml")
    target_map = _load_marshal_hash(data_dir / "PSP_MTAT.dat")
    user_map = _load_marshal_hash(data_dir / "PSP_MTAU.dat")
    move_ids = _load_move_ids(data_dir / "Studio" / "moves")
    dart = _generate_dart(animations, target_map, user_map, move_ids)
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(dart, encoding="utf-8")
    print(f"Wrote {args.output}")
    print(
        f"animations={len(animations)} target={len(target_map)} "
        f"user={sum(1 for value in user_map.values() if value is not None)} "
        f"move_ids={len(move_ids)}"
    )


if __name__ == "__main__":
    main()
