#!/usr/bin/env python3
"""Validate structural quality gates for an editable PokeMap map."""

from __future__ import annotations

import argparse
from collections import deque
from dataclasses import asdict, dataclass
import json
from pathlib import Path
from typing import Any


@dataclass(frozen=True)
class Finding:
    severity: str
    code: str
    message: str


def _parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--project", required=True, type=Path)
    parser.add_argument("--map", required=True, dest="map_path", type=Path)
    parser.add_argument(
        "--entry",
        action="append",
        default=[],
        metavar="X,Y",
        help="Required walkable entry cell. Repeat for multiple entries.",
    )
    parser.add_argument(
        "--target",
        action="append",
        default=[],
        metavar="X,Y",
        help="Required walkable destination cell. Repeat for interactions/exits.",
    )
    parser.add_argument(
        "--allow-full-canvas-element",
        action="append",
        default=[],
        metavar="ELEMENT_ID",
        help="Explicit exception for a deliberate backdrop, never for normal map architecture.",
    )
    parser.add_argument("--report", type=Path, help="Optional JSON report path.")
    return parser


def _load_object(path: Path, label: str) -> dict[str, Any]:
    resolved = path.expanduser().resolve()
    if not resolved.is_file():
        raise SystemExit(f"error: {label} does not exist: {resolved}")
    try:
        payload = json.loads(resolved.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as error:
        raise SystemExit(f"error: cannot decode {label}: {error}") from error
    if not isinstance(payload, dict):
        raise SystemExit(f"error: {label} root must be a JSON object")
    return payload


def _positive_int(value: Any) -> int | None:
    if isinstance(value, bool) or not isinstance(value, int) or value <= 0:
        return None
    return value


def _cell(value: str) -> tuple[int, int]:
    parts = value.split(",")
    if len(parts) != 2:
        raise argparse.ArgumentTypeError(f"expected X,Y, got {value!r}")
    try:
        return int(parts[0].strip()), int(parts[1].strip())
    except ValueError as error:
        raise argparse.ArgumentTypeError(f"expected integer X,Y, got {value!r}") from error


def _frame_footprint(element: dict[str, Any]) -> tuple[float, float] | None:
    footprints: list[tuple[float, float]] = []
    for frame in element.get("frames", []):
        if not isinstance(frame, dict):
            continue
        source = frame.get("source")
        if not isinstance(source, dict):
            continue
        width = source.get("width")
        height = source.get("height")
        if (
            isinstance(width, (int, float))
            and not isinstance(width, bool)
            and width > 0
            and isinstance(height, (int, float))
            and not isinstance(height, bool)
            and height > 0
        ):
            footprints.append((float(width), float(height)))
    if not footprints:
        return None
    return max(width for width, _ in footprints), max(
        height for _, height in footprints
    )


def _collision_grid(
    layers: list[Any],
    expected_cells: int,
    findings: list[Finding],
) -> list[bool] | None:
    candidates = [
        layer
        for layer in layers
        if isinstance(layer, dict)
        and (
            layer.get("runtimeType") == "collision"
            or isinstance(layer.get("collisions"), list)
        )
    ]
    if len(candidates) != 1:
        findings.append(
            Finding(
                "error",
                "collision-layer-count",
                f"Expected exactly one collision layer, found {len(candidates)}.",
            )
        )
        return None
    collisions = candidates[0].get("collisions")
    if not isinstance(collisions, list) or len(collisions) != expected_cells:
        findings.append(
            Finding(
                "error",
                "collision-grid-size",
                f"Collision grid must contain {expected_cells} cells.",
            )
        )
        return None
    if any(not isinstance(value, bool) for value in collisions):
        findings.append(
            Finding(
                "error",
                "collision-grid-values",
                "Collision grid values must be booleans.",
            )
        )
        return None
    return collisions


def _reachable(
    collisions: list[bool],
    width: int,
    height: int,
    start: tuple[int, int],
) -> set[tuple[int, int]]:
    reached = {start}
    queue = deque([start])
    while queue:
        x, y = queue.popleft()
        for candidate in ((x - 1, y), (x + 1, y), (x, y - 1), (x, y + 1)):
            next_x, next_y = candidate
            if not (0 <= next_x < width and 0 <= next_y < height):
                continue
            if collisions[next_y * width + next_x] or candidate in reached:
                continue
            reached.add(candidate)
            queue.append(candidate)
    return reached


def _validate_navigation(
    collisions: list[bool] | None,
    width: int,
    height: int,
    entries: list[tuple[int, int]],
    targets: list[tuple[int, int]],
    findings: list[Finding],
) -> None:
    if collisions is None:
        return
    if not entries:
        findings.append(
            Finding(
                "warning",
                "navigation-not-checked",
                "No --entry was supplied; route reachability remains unproven.",
            )
        )
        return

    def validate_cell(cell: tuple[int, int], role: str) -> bool:
        x, y = cell
        if not (0 <= x < width and 0 <= y < height):
            findings.append(
                Finding(
                    "error",
                    f"{role}-out-of-bounds",
                    f"{role.capitalize()} cell {x},{y} is outside the map.",
                )
            )
            return False
        if collisions[y * width + x]:
            findings.append(
                Finding(
                    "error",
                    f"blocked-{role}",
                    f"{role.capitalize()} cell {x},{y} is blocked.",
                )
            )
            return False
        return True

    valid_entries = [cell for cell in entries if validate_cell(cell, "entry")]
    valid_targets = [cell for cell in targets if validate_cell(cell, "target")]
    if not valid_entries:
        return
    reached = _reachable(collisions, width, height, valid_entries[0])
    for target in valid_targets:
        if target not in reached:
            findings.append(
                Finding(
                    "error",
                    "unreachable-target",
                    f"Required target {target[0]},{target[1]} is unreachable from "
                    f"entry {valid_entries[0][0]},{valid_entries[0][1]}.",
                )
            )
    for entry in valid_entries[1:]:
        if entry not in reached:
            findings.append(
                Finding(
                    "error",
                    "disconnected-entry",
                    f"Entry {entry[0]},{entry[1]} is disconnected from the primary entry.",
                )
            )


def _validate(
    project: dict[str, Any],
    map_data: dict[str, Any],
    entries: list[tuple[int, int]],
    targets: list[tuple[int, int]],
    allowed_full_canvas: set[str],
) -> list[Finding]:
    findings: list[Finding] = []
    settings = project.get("settings")
    settings = settings if isinstance(settings, dict) else {}
    tile_width = _positive_int(settings.get("tileWidth"))
    tile_height = _positive_int(settings.get("tileHeight"))
    if tile_width is None or tile_height is None:
        findings.append(
            Finding(
                "error",
                "invalid-project-grid",
                "Project settings require positive integer tileWidth and tileHeight.",
            )
        )

    size = map_data.get("size")
    size = size if isinstance(size, dict) else {}
    width = _positive_int(size.get("width"))
    height = _positive_int(size.get("height"))
    if width is None or height is None:
        findings.append(
            Finding(
                "error",
                "invalid-map-size",
                "Map size requires positive integer width and height.",
            )
        )
        return findings
    expected_cells = width * height

    tilesets = {
        tileset.get("id")
        for tileset in project.get("tilesets", [])
        if isinstance(tileset, dict) and isinstance(tileset.get("id"), str)
    }
    if map_data.get("tilesetId") not in tilesets:
        findings.append(
            Finding(
                "error",
                "unknown-map-tileset",
                f"Map tileset {map_data.get('tilesetId')!r} is absent from project.json.",
            )
        )

    layers = map_data.get("layers")
    layers = layers if isinstance(layers, list) else []
    layer_ids = [
        layer.get("id")
        for layer in layers
        if isinstance(layer, dict) and isinstance(layer.get("id"), str)
    ]
    if len(layer_ids) != len(set(layer_ids)):
        findings.append(
            Finding("error", "duplicate-layer-id", "Layer IDs must be unique.")
        )
    layer_id_set = set(layer_ids)
    for layer in layers:
        if not isinstance(layer, dict) or not isinstance(layer.get("tiles"), list):
            continue
        if len(layer["tiles"]) != expected_cells:
            findings.append(
                Finding(
                    "error",
                    "tile-grid-size",
                    f"Layer {layer.get('id')!r} must contain {expected_cells} tiles.",
                )
            )

    collisions = _collision_grid(layers, expected_cells, findings)

    elements = {
        element.get("id"): element
        for element in project.get("elements", [])
        if isinstance(element, dict) and isinstance(element.get("id"), str)
    }
    placement_ids: set[str] = set()
    placeholder_tokens = ("asset manquant", "missing asset", "placeholder", "todo")
    for placement in map_data.get("placedElements", []):
        if not isinstance(placement, dict):
            findings.append(
                Finding("error", "invalid-placement", "Placements must be objects.")
            )
            continue
        placement_id = placement.get("id")
        if isinstance(placement_id, str):
            if placement_id in placement_ids:
                findings.append(
                    Finding(
                        "error",
                        "duplicate-placement-id",
                        f"Placement ID {placement_id!r} is duplicated.",
                    )
                )
            placement_ids.add(placement_id)
        if placement.get("layerId") not in layer_id_set:
            findings.append(
                Finding(
                    "error",
                    "unknown-placement-layer",
                    f"Placement {placement_id!r} references an unknown layer.",
                )
            )
        element_id = placement.get("elementId")
        element = elements.get(element_id)
        if element is None:
            findings.append(
                Finding(
                    "error",
                    "unknown-element",
                    f"Placement {placement_id!r} references {element_id!r}.",
                )
            )
            continue
        searchable = f"{element_id} {element.get('name', '')}".lower()
        if any(token in searchable for token in placeholder_tokens):
            findings.append(
                Finding(
                    "error",
                    "placeholder-element",
                    f"Placement {placement_id!r} still uses a placeholder element.",
                )
            )
        footprint = _frame_footprint(element)
        position = placement.get("pos")
        position = position if isinstance(position, dict) else {}
        x = position.get("x")
        y = position.get("y")
        if (
            footprint is None
            or not isinstance(x, (int, float))
            or isinstance(x, bool)
            or not isinstance(y, (int, float))
            or isinstance(y, bool)
        ):
            findings.append(
                Finding(
                    "error",
                    "unknown-placement-footprint",
                    f"Cannot establish bounds for placement {placement_id!r}.",
                )
            )
            continue
        element_width, element_height = footprint
        right = float(x) + element_width
        bottom = float(y) + element_height
        if float(x) < 0 or float(y) < 0 or right > width or bottom > height:
            findings.append(
                Finding(
                    "error",
                    "out-of-bounds-element",
                    f"Placement {placement_id!r} spans ({x},{y})–"
                    f"({right:g},{bottom:g}) outside {width}×{height}; "
                    "engine clipping is not an authoring technique.",
                )
            )
        covers_canvas = (
            float(x) <= 0
            and float(y) <= 0
            and right >= width
            and bottom >= height
        )
        if covers_canvas and element_id not in allowed_full_canvas:
            findings.append(
                Finding(
                    "error",
                    "full-canvas-composite",
                    f"Element {element_id!r} covers all four map edges. "
                    "Build normal architecture from modular, independently bounded parts.",
                )
            )

    properties = map_data.get("properties")
    properties = properties if isinstance(properties, dict) else {}
    if properties.get("referenceRuntimeUnderlay") is True:
        findings.append(
            Finding(
                "error",
                "reference-underlay",
                "A complete reference render cannot be a runtime map layer.",
            )
        )

    _validate_navigation(collisions, width, height, entries, targets, findings)
    return findings


def main() -> int:
    args = _parser().parse_args()
    try:
        entries = [_cell(value) for value in args.entry]
        targets = [_cell(value) for value in args.target]
    except argparse.ArgumentTypeError as error:
        raise SystemExit(f"error: {error}") from error
    project = _load_object(args.project, "project")
    map_data = _load_object(args.map_path, "map")
    findings = _validate(
        project,
        map_data,
        entries,
        targets,
        set(args.allow_full_canvas_element),
    )
    errors = [finding for finding in findings if finding.severity == "error"]
    warnings = [finding for finding in findings if finding.severity == "warning"]
    status = "FAIL" if errors else "PASS"
    print(f"{status}: {len(errors)} error(s), {len(warnings)} warning(s)")
    for finding in findings:
        print(f"[{finding.severity.upper()}] {finding.code}: {finding.message}")

    if args.report is not None:
        report = args.report.expanduser().resolve()
        report.parent.mkdir(parents=True, exist_ok=True)
        report.write_text(
            json.dumps(
                {
                    "schemaVersion": 1,
                    "status": status,
                    "mapId": map_data.get("id"),
                    "findings": [asdict(finding) for finding in findings],
                    "summary": {
                        "errorCount": len(errors),
                        "warningCount": len(warnings),
                    },
                },
                ensure_ascii=False,
                indent=2,
            )
            + "\n",
            encoding="utf-8",
        )
    return 1 if errors else 0


if __name__ == "__main__":
    raise SystemExit(main())
