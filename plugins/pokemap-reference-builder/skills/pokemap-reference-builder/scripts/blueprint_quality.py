#!/usr/bin/env python3
import argparse
import json
import sys
from collections import defaultdict, deque
from pathlib import Path

from visual_quality import compare_images


WATER_TERMS = {"water", "river", "canal", "pond", "lake", "basin", "paddy"}
TREE_TERMS = {"tree", "trees", "forest", "grove", "woodland"}
RAIL_TERMS = {"rail", "rails", "track", "tracks", "railway"}
TERRAIN_NETWORK_TERMS = WATER_TERMS | TREE_TERMS | RAIL_TERMS | {
    "bank",
    "cliff",
    "field",
    "grass",
    "ground",
    "meadow",
    "path",
    "road",
    "sand",
    "shore",
    "soil",
}


def semantic_terms(value: object) -> set[str]:
    if not isinstance(value, str):
        return set()
    normalized = value.lower().replace("-", "_").replace(".", "_")
    return {term for term in normalized.split("_") if term}


def line_cells(start: tuple[int, int], end: tuple[int, int]) -> set[tuple[int, int]]:
    x0, y0 = start
    x1, y1 = end
    dx = abs(x1 - x0)
    dy = -abs(y1 - y0)
    step_x = 1 if x0 < x1 else -1
    step_y = 1 if y0 < y1 else -1
    error = dx + dy
    cells = set()
    while True:
        cells.add((x0, y0))
        if x0 == x1 and y0 == y1:
            break
        doubled = 2 * error
        if doubled >= dy:
            error += dy
            x0 += step_x
        if doubled <= dx:
            error += dx
            y0 += step_y
    return cells


def polygon_contains(points: list[tuple[int, int]], x: int, y: int) -> bool:
    inside = False
    previous = points[-1]
    sample_x = x + 0.5
    sample_y = y + 0.5
    for current in points:
        x1, y1 = previous
        x2, y2 = current
        intersects = (y1 > sample_y) != (y2 > sample_y)
        if intersects:
            boundary_x = (x2 - x1) * (sample_y - y1) / (y2 - y1) + x1
            if sample_x < boundary_x:
                inside = not inside
        previous = current
    return inside


def geometry_cells(layer: dict, width: int, height: int) -> set[tuple[int, int]]:
    geometry = layer.get("geometry")
    if not isinstance(geometry, dict):
        return set()
    kind = geometry.get("kind")
    cells: set[tuple[int, int]] = set()
    if kind == "cells":
        for cell in geometry.get("cells", []):
            if isinstance(cell, dict) and isinstance(cell.get("x"), int) and isinstance(cell.get("y"), int):
                cells.add((cell["x"], cell["y"]))
    elif kind == "placement":
        origin = geometry.get("origin", {})
        size = geometry.get("size", {})
        if all(isinstance(value, int) for value in [origin.get("x"), origin.get("y"), size.get("width"), size.get("height")]):
            cells.update(
                (x, y)
                for y in range(origin["y"], origin["y"] + size["height"])
                for x in range(origin["x"], origin["x"] + size["width"])
            )
    elif kind == "polygon":
        points = [
            (point["x"], point["y"])
            for point in geometry.get("points", [])
            if isinstance(point, dict) and isinstance(point.get("x"), int) and isinstance(point.get("y"), int)
        ]
        if len(points) >= 3:
            cells.update((x, y) for y in range(height) for x in range(width) if polygon_contains(points, x, y))
    elif kind in {"polyline", "connection"}:
        points = [
            (point["x"], point["y"])
            for point in geometry.get("points", [])
            if isinstance(point, dict) and isinstance(point.get("x"), int) and isinstance(point.get("y"), int)
        ]
        for start, end in zip(points, points[1:]):
            cells.update(line_cells(start, end))
        constraints = layer.get("constraints", {})
        network_width = constraints.get("networkWidthCells", 1) if isinstance(constraints, dict) else 1
        if isinstance(network_width, int) and network_width > 1:
            radius = network_width // 2
            cells = {
                (x + offset_x, y + offset_y)
                for x, y in cells
                for offset_y in range(-radius, radius + 1)
                for offset_x in range(-radius, radius + 1)
            }
    return {(x, y) for x, y in cells if 0 <= x < width and 0 <= y < height}


def connected_components(cells: set[tuple[int, int]]) -> int:
    remaining = set(cells)
    components = 0
    while remaining:
        components += 1
        queue = deque([remaining.pop()])
        while queue:
            x, y = queue.popleft()
            for neighbor in ((x - 1, y), (x + 1, y), (x, y - 1), (x, y + 1)):
                if neighbor in remaining:
                    remaining.remove(neighbor)
                    queue.append(neighbor)
    return components


def map_dimensions(blueprint: dict) -> tuple[int, int]:
    map_data = blueprint.get("map", {})
    width = map_data.get("widthCells")
    height = map_data.get("heightCells")
    if not isinstance(width, int) or not isinstance(height, int) or width < 1 or height < 1:
        raise ValueError("blueprint map dimensions are invalid")
    return width, height


def layer_records(blueprint: dict) -> list[dict]:
    width, height = map_dimensions(blueprint)
    layers = blueprint.get("layers")
    if not isinstance(layers, list):
        raise ValueError("blueprint.layers must be an array")
    return [
        {"layer": layer, "cells": geometry_cells(layer, width, height), "terms": semantic_terms(layer.get("semantic"))}
        for layer in layers
        if isinstance(layer, dict)
    ]


def lint_blueprint(blueprint: dict) -> dict:
    width, height = map_dimensions(blueprint)
    records = layer_records(blueprint)
    water = set().union(*(record["cells"] for record in records if record["terms"] & WATER_TERMS))
    rails = set().union(*(record["cells"] for record in records if record["terms"] & RAIL_TERMS))
    structures = set().union(*(record["cells"] for record in records if record["layer"].get("family") == "structure"))
    trees = set().union(*(record["cells"] for record in records if record["terms"] & TREE_TERMS))
    errors = []
    overlaps = [
        ("tree_in_water", trees & water, "Trees overlap water cells"),
        ("tree_in_structure", trees & structures, "Trees overlap structure cells"),
        ("tree_on_rail", trees & rails, "Trees overlap rail cells"),
    ]
    for code, cells, message in overlaps:
        if cells:
            errors.append(
                {
                    "code": code,
                    "message": message,
                    "cells": [{"x": x, "y": y} for x, y in sorted(cells, key=lambda value: (value[1], value[0]))],
                }
            )
    flattened: dict[str, list[dict]] = defaultdict(list)
    for record in records:
        layer = record["layer"]
        geometry = layer.get("geometry", {})
        semantic = layer.get("semantic")
        if (
            layer.get("family") in {"structure", "decoration"}
            and isinstance(geometry, dict)
            and geometry.get("kind") == "placement"
            and isinstance(semantic, str)
            and record["terms"] & TERRAIN_NETWORK_TERMS
        ):
            flattened[semantic].append(record)
    map_cell_count = width * height
    for semantic, semantic_records in flattened.items():
        covered = set().union(*(record["cells"] for record in semantic_records))
        coverage_ratio = len(covered) / map_cell_count
        largest_ratio = max(len(record["cells"]) / map_cell_count for record in semantic_records)
        if largest_ratio >= 0.15 or (len(semantic_records) >= 2 and coverage_ratio >= 0.25):
            errors.append(
                {
                    "code": "semantic_family_flattening",
                    "message": "Large placed assets replace terrain or network semantics instead of composing editable primitives",
                    "semantic": semantic,
                    "placementCount": len(semantic_records),
                    "coverageRatio": round(coverage_ratio, 4),
                    "largestPlacementRatio": round(largest_ratio, 4),
                    "layerIds": [record["layer"].get("id") for record in semantic_records],
                }
            )
    for record in records:
        layer = record["layer"]
        constraints = layer.get("constraints", {})
        if layer.get("family") != "network" or not isinstance(constraints, dict):
            continue
        if constraints.get("continuityRequired") is True:
            components = connected_components(record["cells"])
            if components != 1:
                errors.append(
                    {
                        "code": "network_disconnected",
                        "message": f"Network {layer.get('id')} has {components} connected components",
                        "layerId": layer.get("id"),
                        "components": components,
                    }
                )
    return {
        "valid": not errors,
        "errors": errors,
        "warnings": [],
        "requiresHumanReview": True,
    }


def semantic_masks(blueprint: dict) -> dict[str, set[tuple[int, int]]]:
    masks: dict[str, set[tuple[int, int]]] = defaultdict(set)
    for record in layer_records(blueprint):
        semantic = record["layer"].get("semantic")
        if isinstance(semantic, str):
            masks[semantic].update(record["cells"])
    return dict(masks)


def intersection_over_union(expected: set[tuple[int, int]], actual: set[tuple[int, int]]) -> float:
    union = expected | actual
    if not union:
        return 1.0
    return len(expected & actual) / len(union)


def composition_score(reference: dict, candidate: dict) -> int:
    expected = semantic_masks(reference)
    actual = semantic_masks(candidate)
    if not expected:
        return 0
    return round(100 * sum(intersection_over_union(cells, actual.get(semantic, set())) for semantic, cells in expected.items()) / len(expected))


def topology_score(reference: dict, candidate: dict) -> int | None:
    expected = {
        record["layer"].get("semantic"): connected_components(record["cells"])
        for record in layer_records(reference)
        if record["layer"].get("family") == "network"
    }
    if not expected:
        return None
    actual = {
        record["layer"].get("semantic"): connected_components(record["cells"])
        for record in layer_records(candidate)
        if record["layer"].get("family") == "network"
    }
    scores = []
    for semantic, expected_components in expected.items():
        actual_components = actual.get(semantic, 0)
        maximum = max(expected_components, actual_components, 1)
        scores.append(1 - abs(expected_components - actual_components) / maximum)
    return round(100 * sum(scores) / len(scores))


def placement_sizes(blueprint: dict) -> dict[str, list[tuple[int, int]]]:
    values: dict[str, list[tuple[int, int]]] = defaultdict(list)
    for record in layer_records(blueprint):
        layer = record["layer"]
        geometry = layer.get("geometry", {})
        if layer.get("family") != "structure" or geometry.get("kind") != "placement":
            continue
        size = geometry.get("size", {})
        if isinstance(size.get("width"), int) and isinstance(size.get("height"), int):
            values[str(layer.get("semantic"))].append((size["width"], size["height"]))
    return {semantic: sorted(sizes) for semantic, sizes in values.items()}


def scale_score(reference: dict, candidate: dict) -> int | None:
    expected = placement_sizes(reference)
    if not expected:
        return None
    actual = placement_sizes(candidate)
    scores = []
    for semantic, expected_sizes in expected.items():
        actual_sizes = actual.get(semantic, [])
        if len(actual_sizes) != len(expected_sizes):
            scores.append(0.0)
            continue
        pairs = zip(expected_sizes, actual_sizes)
        scores.append(
            sum(
                min(expected_width * expected_height, actual_width * actual_height)
                / max(expected_width * expected_height, actual_width * actual_height)
                for (expected_width, expected_height), (actual_width, actual_height) in pairs
            )
            / len(expected_sizes)
        )
    return round(100 * sum(scores) / len(scores))


def asset_score(reference: dict, asset_report: dict | None) -> int | None:
    requirements = reference.get("missingAssets")
    if not isinstance(requirements, list) or not requirements:
        return None
    if not isinstance(asset_report, dict) or not isinstance(asset_report.get("resolutions"), list):
        return 0
    resolved = sum(1 for item in asset_report["resolutions"] if isinstance(item, dict) and item.get("decision") == "reuse")
    return round(100 * resolved / len(requirements))


def repair_plan(axes: dict, lint: dict, visual_report: dict | None = None) -> list[dict]:
    repairs = []
    tree_errors = [error for error in lint["errors"] if str(error.get("code", "")).startswith("tree_")]
    if tree_errors:
        repairs.append(
            {
                "priority": "blocking",
                "action": "remove_tree_overlap",
                "reason": "Tree anchors intersect forbidden semantic masks",
                "violations": [error["code"] for error in tree_errors],
                "cells": [cell for error in tree_errors for cell in error.get("cells", [])],
            }
        )
    disconnected = [error for error in lint["errors"] if error.get("code") == "network_disconnected"]
    if disconnected:
        repairs.append(
            {
                "priority": "blocking",
                "action": "connect_required_networks",
                "reason": "One or more required networks are disconnected",
                "layers": [error.get("layerId") for error in disconnected],
            }
        )
    flattened = [error for error in lint["errors"] if error.get("code") == "semantic_family_flattening"]
    if flattened:
        repairs.append(
            {
                "priority": "blocking",
                "action": "decompose_flattened_assets",
                "reason": "Terrain and network families must remain editable instead of being replaced by large multi-family sprites",
                "semantics": [error.get("semantic") for error in flattened],
                "layers": [layer_id for error in flattened for layer_id in error.get("layerIds", [])],
            }
        )
    if axes["composition"] < 85:
        repairs.append(
            {
                "priority": "high",
                "action": "review_semantic_masks",
                "reason": f"Composition score is {axes['composition']}, below 85",
            }
        )
    if axes["topology"] is not None and axes["topology"] < 100:
        repairs.append(
            {
                "priority": "high",
                "action": "repair_network_topology",
                "reason": f"Topology score is {axes['topology']}, expected 100",
            }
        )
    if axes["scale"] is not None and axes["scale"] < 90:
        repairs.append(
            {
                "priority": "high",
                "action": "correct_structure_footprints",
                "reason": f"Scale score is {axes['scale']}, below 90",
            }
        )
    if axes["assets"] is not None and axes["assets"] < 80:
        repairs.append(
            {
                "priority": "high",
                "action": "resolve_asset_gaps",
                "reason": f"Asset resolution score is {axes['assets']}, below 80",
            }
        )
    if visual_report is None:
        repairs.append(
            {
                "priority": "blocking",
                "action": "capture_comparable_visual_evidence",
                "reason": "A same-crop reference image and current PokeMap render are required before publishing a quality score",
            }
        )
    else:
        repairs.extend(visual_report.get("repairPlan", []))
    return repairs


def visual_fidelity_score(visual_report: dict | None) -> int | None:
    if visual_report is None:
        return None
    score = visual_report.get("score")
    if not isinstance(score, int) or isinstance(score, bool) or not 0 <= score <= 100:
        raise ValueError("visual report score must be an integer between 0 and 100")
    if not isinstance(visual_report.get("eligibleForVisualReview"), bool):
        raise ValueError("visual report eligibleForVisualReview must be a boolean")
    return score


def compare_blueprints(
    reference: dict,
    candidate: dict,
    asset_report: dict | None = None,
    visual_report: dict | None = None,
    threshold: int = 80,
) -> dict:
    if not isinstance(threshold, int) or isinstance(threshold, bool) or not 0 <= threshold <= 100:
        raise ValueError("threshold must be an integer between 0 and 100")
    reference_dimensions = map_dimensions(reference)
    candidate_dimensions = map_dimensions(candidate)
    if reference_dimensions != candidate_dimensions:
        raise ValueError("reference and candidate map dimensions must match")
    lint = lint_blueprint(candidate)
    axes = {
        "composition": composition_score(reference, candidate),
        "topology": topology_score(reference, candidate),
        "scale": scale_score(reference, candidate),
        "assets": asset_score(reference, asset_report),
        "spatialRules": 100 if lint["valid"] else 0,
        "visualFidelity": visual_fidelity_score(visual_report),
    }
    technical_weights = {"composition": 35, "topology": 25, "scale": 20, "assets": 10}
    technical_applicable = {
        axis: weight for axis, weight in technical_weights.items() if axes[axis] is not None
    }
    technical_score = round(
        sum(axes[axis] * weight for axis, weight in technical_applicable.items())
        / sum(technical_applicable.values())
    )
    score = None
    if axes["visualFidelity"] is not None:
        weights = {
            "composition": 20,
            "topology": 15,
            "scale": 10,
            "assets": 5,
            "visualFidelity": 50,
        }
        applicable = {axis: weight for axis, weight in weights.items() if axes[axis] is not None}
        score = round(
            sum(axes[axis] * weight for axis, weight in applicable.items())
            / sum(applicable.values())
        )
    failed_gates = []
    if score is None:
        failed_gates.append("visual_evidence_missing")
    elif score < threshold:
        failed_gates.append("score")
    if visual_report is not None and not visual_report["eligibleForVisualReview"]:
        failed_gates.append("visual_fidelity")
    if not lint["valid"]:
        failed_gates.append("spatial_rules")
    if axes["topology"] is not None and axes["topology"] < 100:
        failed_gates.append("topology")
    if axes["scale"] is not None and axes["scale"] < 90:
        failed_gates.append("scale")
    if axes["assets"] is not None and axes["assets"] < 80:
        failed_gates.append("assets")
    return {
        "schemaVersion": 1,
        "threshold": threshold,
        "score": score,
        "technicalScore": technical_score,
        "axes": axes,
        "failedGates": failed_gates,
        "eligibleForHumanReview": not failed_gates,
        "humanAccepted": False,
        "lint": lint,
        "visualReport": visual_report,
        "repairPlan": repair_plan(axes, lint, visual_report),
    }


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
    parser = argparse.ArgumentParser(prog="blueprint_quality.py")
    subparsers = parser.add_subparsers(dest="command", required=True)
    lint = subparsers.add_parser("lint")
    lint.add_argument("--blueprint", required=True)
    lint.add_argument("--output", required=True)
    lint.add_argument("--force", action="store_true")
    compare = subparsers.add_parser("compare")
    compare.add_argument("--reference", required=True)
    compare.add_argument("--candidate", required=True)
    compare.add_argument("--asset-report")
    compare.add_argument("--reference-image")
    compare.add_argument("--candidate-image")
    compare.add_argument("--threshold", type=int, default=80)
    compare.add_argument("--output", required=True)
    compare.add_argument("--force", action="store_true")
    return parser


def main(argv: list[str] | None = None) -> int:
    args = build_parser().parse_args(argv)
    try:
        if args.command == "lint":
            blueprint = load_json(Path(args.blueprint).expanduser().resolve())
            result = lint_blueprint(blueprint)
            exit_code = 0 if result["valid"] else 1
        else:
            reference = load_json(Path(args.reference).expanduser().resolve())
            candidate = load_json(Path(args.candidate).expanduser().resolve())
            asset_report = load_json(Path(args.asset_report).expanduser().resolve()) if args.asset_report else None
            if bool(args.reference_image) != bool(args.candidate_image):
                raise ValueError("--reference-image and --candidate-image must be provided together")
            visual_report = (
                compare_images(
                    Path(args.reference_image),
                    Path(args.candidate_image),
                    threshold=args.threshold,
                )
                if args.reference_image
                else None
            )
            result = compare_blueprints(
                reference,
                candidate,
                asset_report=asset_report,
                visual_report=visual_report,
                threshold=args.threshold,
            )
            exit_code = 0 if result["eligibleForHumanReview"] else 1
        output = Path(args.output).expanduser().resolve()
        write_json(output, result, args.force)
        print(output)
        return exit_code
    except (OSError, ValueError, json.JSONDecodeError) as error:
        print(str(error), file=sys.stderr)
        return 2


if __name__ == "__main__":
    raise SystemExit(main())
