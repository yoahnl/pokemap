#!/usr/bin/env python3
import argparse
import copy
import hashlib
import json
import math
import re
import sys
from collections import deque
from pathlib import Path

from PIL import Image, ImageDraw

from blueprint_tool import CELL_SIZE, create_blueprint, validate_blueprint


OVERLAY_COLORS = [
    (49, 130, 206, 96),
    (57, 168, 92, 96),
    (235, 179, 52, 96),
    (211, 78, 78, 96),
    (146, 91, 201, 96),
    (41, 184, 181, 96),
]


def require_profile(profile: dict) -> tuple[int, int, int, list[dict]]:
    if profile.get("schemaVersion") != 1:
        raise ValueError("profile.schemaVersion must be 1")
    cell_size = profile.get("cellSizePx")
    if cell_size != CELL_SIZE:
        raise ValueError(f"profile.cellSizePx must be {CELL_SIZE}")
    source_cell_size = profile.get("sourceCellSizePx", cell_size)
    if not isinstance(source_cell_size, int) or isinstance(source_cell_size, bool) or source_cell_size < 1:
        raise ValueError("profile.sourceCellSizePx must be a positive integer")
    inset = profile.get("sampleInsetPx", 0)
    if not isinstance(inset, int) or isinstance(inset, bool) or not 0 <= inset < source_cell_size / 2:
        raise ValueError("profile.sampleInsetPx must fit inside the source cell")
    classes = profile.get("classes")
    if not isinstance(classes, list) or not classes:
        raise ValueError("profile.classes must be a non-empty array")
    return cell_size, source_cell_size, inset, classes


def cell_mean(image: Image.Image, x: int, y: int, cell_size: int, inset: int) -> tuple[float, float, float]:
    left = x * cell_size + inset
    top = y * cell_size + inset
    right = (x + 1) * cell_size - inset
    bottom = (y + 1) * cell_size - inset
    pixels = image.crop((left, top, right, bottom)).get_flattened_data()
    count = (right - left) * (bottom - top)
    totals = [0, 0, 0]
    for red, green, blue in pixels:
        totals[0] += red
        totals[1] += green
        totals[2] += blue
    return tuple(total / count for total in totals)


def average(values: list[tuple[float, float, float]]) -> tuple[float, float, float]:
    return tuple(sum(value[channel] for value in values) / len(values) for channel in range(3))


def confidence(value: tuple[float, float, float], prototype: tuple[float, float, float]) -> float:
    distance = math.sqrt(sum((value[index] - prototype[index]) ** 2 for index in range(3)))
    return max(0.0, 1.0 - distance / (math.sqrt(3) * 255))


def identifier(value: str) -> str:
    normalized = re.sub(r"[^A-Za-z0-9._:-]+", "-", value.strip().lower()).strip("-")
    if not normalized:
        raise ValueError("semantic identifiers must contain letters or numbers")
    return normalized


def retained_component_cells(cells: list[dict], minimum: int) -> set[tuple[int, int]]:
    remaining = {(cell["x"], cell["y"]) for cell in cells}
    retained: set[tuple[int, int]] = set()
    while remaining:
        start = remaining.pop()
        component = {start}
        queue = deque([start])
        while queue:
            x, y = queue.popleft()
            for neighbor in ((x - 1, y), (x + 1, y), (x, y - 1), (x, y + 1)):
                if neighbor in remaining:
                    remaining.remove(neighbor)
                    component.add(neighbor)
                    queue.append(neighbor)
        if len(component) >= minimum:
            retained.update(component)
    return retained


def analyze_reference(
    reference: Path,
    map_id: str,
    name: str,
    profile: dict,
) -> tuple[dict, dict]:
    cell_size, source_cell_size, inset, classes = require_profile(profile)
    reference = Path(reference).expanduser().resolve()
    image = Image.open(reference).convert("RGB")
    if image.width % source_cell_size or image.height % source_cell_size:
        raise ValueError(f"reference dimensions must be a multiple of {source_cell_size}")
    width = image.width // source_cell_size
    height = image.height // source_cell_size
    descriptors = {
        (x, y): cell_mean(image, x, y, source_cell_size, inset)
        for y in range(height)
        for x in range(width)
    }
    configured: list[dict] = []
    semantics: set[str] = set()
    for index, item in enumerate(classes):
        if not isinstance(item, dict):
            raise ValueError(f"profile.classes[{index}] must be an object")
        semantic = item.get("semantic")
        if not isinstance(semantic, str) or not semantic:
            raise ValueError(f"profile.classes[{index}].semantic is required")
        if semantic in semantics:
            raise ValueError(f"duplicate semantic class {semantic}")
        semantics.add(semantic)
        seeds = item.get("seeds")
        if not isinstance(seeds, list) or not seeds:
            raise ValueError(f"profile.classes[{index}].seeds must not be empty")
        seed_values = []
        for seed_index, seed in enumerate(seeds):
            if not isinstance(seed, dict):
                raise ValueError(f"profile.classes[{index}].seeds[{seed_index}] must be an object")
            x = seed.get("x")
            y = seed.get("y")
            if not isinstance(x, int) or isinstance(x, bool) or not 0 <= x < width:
                raise ValueError(f"profile.classes[{index}].seeds[{seed_index}].x is outside the map")
            if not isinstance(y, int) or isinstance(y, bool) or not 0 <= y < height:
                raise ValueError(f"profile.classes[{index}].seeds[{seed_index}].y is outside the map")
            seed_values.append(descriptors[(x, y)])
        minimum = item.get("minimumConfidence", 0.0)
        if not isinstance(minimum, (int, float)) or isinstance(minimum, bool) or not 0 <= minimum <= 1:
            raise ValueError(f"profile.classes[{index}].minimumConfidence must be between 0 and 1")
        minimum_component = item.get("minimumComponentCells", 1)
        if not isinstance(minimum_component, int) or isinstance(minimum_component, bool) or minimum_component < 1:
            raise ValueError(f"profile.classes[{index}].minimumComponentCells must be a positive integer")
        configured.append(
            {
                **item,
                "prototype": average(seed_values),
                "minimumConfidence": float(minimum),
                "minimumComponentCells": minimum_component,
            }
        )
    assignments: dict[str, list[dict]] = {item["semantic"]: [] for item in configured}
    confidences: dict[str, list[float]] = {item["semantic"]: [] for item in configured}
    unclassified = 0
    ignored = 0
    for y in range(height):
        for x in range(width):
            ranked = sorted(
                ((confidence(descriptors[(x, y)], item["prototype"]), item) for item in configured),
                key=lambda value: value[0],
                reverse=True,
            )
            score, selected = ranked[0]
            if score < selected["minimumConfidence"]:
                unclassified += 1
                continue
            assignments[selected["semantic"]].append({"x": x, "y": y})
            confidences[selected["semantic"]].append(score)
            if selected.get("family") is None:
                ignored += 1
    removed_isolated: dict[str, int] = {}
    for item in configured:
        semantic = item["semantic"]
        cells = assignments[semantic]
        retained = retained_component_cells(cells, item["minimumComponentCells"])
        removed_isolated[semantic] = len(cells) - len(retained)
        kept_pairs = [
            (cell, score)
            for cell, score in zip(cells, confidences[semantic])
            if (cell["x"], cell["y"]) in retained
        ]
        assignments[semantic] = [cell for cell, _ in kept_pairs]
        confidences[semantic] = [score for _, score in kept_pairs]
    blueprint = create_blueprint(str(reference), map_id, name, width, height)
    blueprint["source"]["sha256"] = hashlib.sha256(reference.read_bytes()).hexdigest()
    missing_assets = profile.get("missingAssets", [])
    if not isinstance(missing_assets, list) or any(not isinstance(asset, dict) for asset in missing_assets):
        raise ValueError("profile.missingAssets must be an array of objects")
    blueprint["missingAssets"] = copy.deepcopy(missing_assets)
    for item in configured:
        family = item.get("family")
        cells = assignments[item["semantic"]]
        if family is None or not cells:
            continue
        constraints = item.get("constraints", {})
        notes = item.get("notes", [])
        blueprint["layers"].append(
            {
                "id": f"auto-{family}-{identifier(item['semantic'])}",
                "family": family,
                "semantic": item["semantic"],
                "name": item.get("name") or item["semantic"].replace("_", " ").title(),
                "status": "proposed",
                "geometry": {"kind": "cells", "cells": cells},
                "bindings": [],
                "constraints": constraints,
                "notes": notes,
            }
        )
    blueprint_errors = validate_blueprint(blueprint)
    if blueprint_errors:
        raise ValueError("generated blueprint is invalid: " + "; ".join(blueprint_errors))
    report_classes = []
    total_cells = width * height
    for item in configured:
        scores = confidences[item["semantic"]]
        report_classes.append(
            {
                "semantic": item["semantic"],
                "family": item.get("family"),
                "cells": len(assignments[item["semantic"]]),
                "coverage": len(assignments[item["semantic"]]) / total_cells,
                "meanConfidence": sum(scores) / len(scores) if scores else 0.0,
                "removedIsolatedCells": removed_isolated[item["semantic"]],
            }
        )
    report = {
        "schemaVersion": 1,
        "referenceImage": str(reference),
        "widthCells": width,
        "heightCells": height,
        "sourceCellSizePx": source_cell_size,
        "classes": report_classes,
        "ignoredCells": ignored,
        "unclassifiedCells": unclassified,
        "requiresHumanReview": True,
    }
    return blueprint, report


def render_analysis_overlay(
    reference: Path,
    blueprint: dict,
    report: dict,
    output: Path,
) -> None:
    source_cell_size = report.get("sourceCellSizePx")
    if not isinstance(source_cell_size, int) or source_cell_size < 1:
        raise ValueError("report.sourceCellSizePx must be a positive integer")
    image = Image.open(Path(reference).expanduser().resolve()).convert("RGBA")
    overlay = Image.new("RGBA", image.size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(overlay, "RGBA")
    layers = blueprint.get("layers", [])
    for index, layer in enumerate(layers):
        color = OVERLAY_COLORS[index % len(OVERLAY_COLORS)]
        geometry = layer.get("geometry", {}) if isinstance(layer, dict) else {}
        if geometry.get("kind") != "cells":
            continue
        for cell in geometry.get("cells", []):
            if not isinstance(cell, dict):
                continue
            x = cell.get("x")
            y = cell.get("y")
            if not isinstance(x, int) or not isinstance(y, int):
                continue
            left = x * source_cell_size
            top = y * source_cell_size
            draw.rectangle(
                (left, top, left + source_cell_size - 1, top + source_cell_size - 1),
                fill=color,
            )
    width = blueprint.get("map", {}).get("widthCells", 0)
    height = blueprint.get("map", {}).get("heightCells", 0)
    for x in range(width + 1):
        draw.line((x * source_cell_size, 0, x * source_cell_size, image.height), fill=(255, 255, 255, 70), width=1)
    for y in range(height + 1):
        draw.line((0, y * source_cell_size, image.width, y * source_cell_size), fill=(255, 255, 255, 70), width=1)
    output = Path(output).expanduser().resolve()
    output.parent.mkdir(parents=True, exist_ok=True)
    Image.alpha_composite(image, overlay).save(output)


def load_json(path: Path) -> dict:
    with path.open("r", encoding="utf-8") as handle:
        value = json.load(handle)
    if not isinstance(value, dict):
        raise ValueError(f"JSON root must be an object: {path}")
    return value


def write_json(path: Path, value: dict, force: bool) -> None:
    if path.exists() and not force:
        raise FileExistsError(f"refusing to overwrite {path}; pass --force")
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("w", encoding="utf-8") as handle:
        json.dump(value, handle, ensure_ascii=False, indent=2)
        handle.write("\n")


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(prog="reference_analyzer.py")
    subparsers = parser.add_subparsers(dest="command", required=True)
    analyze = subparsers.add_parser("analyze")
    analyze.add_argument("--reference", required=True)
    analyze.add_argument("--profile", required=True)
    analyze.add_argument("--map-id", required=True)
    analyze.add_argument("--name", required=True)
    analyze.add_argument("--output-blueprint", required=True)
    analyze.add_argument("--output-report", required=True)
    analyze.add_argument("--output-overlay")
    analyze.add_argument("--force", action="store_true")
    return parser


def main(argv: list[str] | None = None) -> int:
    args = build_parser().parse_args(argv)
    try:
        profile = load_json(Path(args.profile).expanduser().resolve())
        blueprint, report = analyze_reference(
            Path(args.reference),
            args.map_id,
            args.name,
            profile,
        )
        blueprint_path = Path(args.output_blueprint).expanduser().resolve()
        report_path = Path(args.output_report).expanduser().resolve()
        write_json(blueprint_path, blueprint, args.force)
        write_json(report_path, report, args.force)
        outputs = {"blueprint": str(blueprint_path), "report": str(report_path)}
        if args.output_overlay:
            overlay_path = Path(args.output_overlay).expanduser().resolve()
            if overlay_path.exists() and not args.force:
                raise FileExistsError(f"refusing to overwrite {overlay_path}; pass --force")
            render_analysis_overlay(Path(args.reference), blueprint, report, overlay_path)
            outputs["overlay"] = str(overlay_path)
        print(json.dumps(outputs, ensure_ascii=False))
        return 0
    except (OSError, ValueError, json.JSONDecodeError) as error:
        print(str(error), file=sys.stderr)
        return 2


if __name__ == "__main__":
    raise SystemExit(main())
