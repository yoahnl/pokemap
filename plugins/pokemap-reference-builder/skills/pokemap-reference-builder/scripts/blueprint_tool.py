#!/usr/bin/env python3
import argparse
import json
import sys
from collections import Counter
from pathlib import Path


CELL_SIZE = 32
FAMILY_ORDER = [
    "surface",
    "network",
    "border",
    "structure",
    "decoration",
    "navigation",
]
LAYER_STATUSES = ["proposed", "approved", "applied", "verified"]
ASSET_STATUSES = ["proposed", "approved", "imported", "verified"]
PROVENANCE = {"hgss_ds", "custom_hgss_compatible"}
ACTION_FAMILIES = {
    "environment",
    "smart_tile",
    "border_layer",
    "placed_element",
    "collision_layer",
    "connection",
}
GEOMETRY_KINDS = {"cells", "polygon", "polyline", "placement", "connection"}


def create_blueprint(reference: str, map_id: str, name: str, width: int, height: int) -> dict:
    return {
        "schemaVersion": 1,
        "cellSizePx": CELL_SIZE,
        "source": {
            "referenceImage": str(Path(reference).expanduser().resolve()),
            "role": "composition_reference",
        },
        "map": {
            "id": map_id,
            "name": name,
            "widthCells": width,
            "heightCells": height,
        },
        "familyOrder": FAMILY_ORDER,
        "layers": [],
        "missingAssets": [],
        "review": {"status": "proposed", "notes": []},
    }


def load_document(path: Path) -> dict:
    with path.open("r", encoding="utf-8") as handle:
        value = json.load(handle)
    if not isinstance(value, dict):
        raise ValueError("document root must be an object")
    return value


def require_object(value: object, path: str, errors: list[str]) -> dict:
    if not isinstance(value, dict):
        errors.append(f"{path}: expected object")
        return {}
    return value


def require_list(value: object, path: str, errors: list[str]) -> list:
    if not isinstance(value, list):
        errors.append(f"{path}: expected array")
        return []
    return value


def positive_int(value: object, path: str, errors: list[str], maximum: int | None = None) -> int:
    if not isinstance(value, int) or isinstance(value, bool) or value < 1:
        errors.append(f"{path}: expected positive integer")
        return 0
    if maximum is not None and value > maximum:
        errors.append(f"{path}: must be <= {maximum}")
    return value


def validate_cell(value: object, path: str, width: int, height: int, errors: list[str]) -> None:
    cell = require_object(value, path, errors)
    x = cell.get("x")
    y = cell.get("y")
    if not isinstance(x, int) or isinstance(x, bool) or not 0 <= x < width:
        errors.append(f"{path}.x: outside 0..{max(width - 1, 0)}")
    if not isinstance(y, int) or isinstance(y, bool) or not 0 <= y < height:
        errors.append(f"{path}.y: outside 0..{max(height - 1, 0)}")


def validate_geometry(value: object, path: str, width: int, height: int, errors: list[str]) -> None:
    geometry = require_object(value, path, errors)
    kind = geometry.get("kind")
    if kind not in GEOMETRY_KINDS:
        errors.append(f"{path}.kind: unsupported geometry kind")
        return
    if kind == "cells":
        cells = require_list(geometry.get("cells"), f"{path}.cells", errors)
        if not cells:
            errors.append(f"{path}.cells: must not be empty")
        for index, cell in enumerate(cells):
            validate_cell(cell, f"{path}.cells[{index}]", width, height, errors)
    if kind in {"polygon", "polyline", "connection"}:
        points = require_list(geometry.get("points"), f"{path}.points", errors)
        minimum = 3 if kind == "polygon" else 2
        if len(points) < minimum:
            errors.append(f"{path}.points: requires at least {minimum} points")
        for index, point in enumerate(points):
            validate_cell(point, f"{path}.points[{index}]", width, height, errors)
    if kind == "placement":
        origin = require_object(geometry.get("origin"), f"{path}.origin", errors)
        size = require_object(geometry.get("size"), f"{path}.size", errors)
        placement_width = positive_int(size.get("width"), f"{path}.size.width", errors)
        placement_height = positive_int(size.get("height"), f"{path}.size.height", errors)
        validate_cell(origin, f"{path}.origin", width, height, errors)
        x = origin.get("x")
        y = origin.get("y")
        if isinstance(x, int) and x + placement_width > width:
            errors.append(f"{path}: placement exceeds map width")
        if isinstance(y, int) and y + placement_height > height:
            errors.append(f"{path}: placement exceeds map height")


def validate_binding(value: object, path: str, errors: list[str]) -> dict:
    binding = require_object(value, path, errors)
    resource_id = binding.get("resourceId")
    action_family = binding.get("actionFamily")
    provenance = binding.get("provenance")
    if not isinstance(binding.get("role"), str) or not binding.get("role"):
        errors.append(f"{path}.role: required")
    if not isinstance(resource_id, str) or not resource_id:
        errors.append(f"{path}.resourceId: required")
    if action_family not in ACTION_FAMILIES:
        errors.append(f"{path}.actionFamily: unsupported action family")
    if provenance not in PROVENANCE:
        errors.append(f"{path}.provenance: only hgss_ds or custom_hgss_compatible is accepted")
    if "gba" in str(resource_id).lower() or "gba" in str(provenance).lower():
        errors.append(f"{path}: GBA provenance is forbidden")
    return binding


def validate_layer(value: object, path: str, width: int, height: int, errors: list[str]) -> str | None:
    layer = require_object(value, path, errors)
    layer_id = layer.get("id")
    family = layer.get("family")
    semantic = layer.get("semantic")
    status = layer.get("status")
    if not isinstance(layer_id, str) or not layer_id:
        errors.append(f"{path}.id: required")
        layer_id = None
    if family not in FAMILY_ORDER:
        errors.append(f"{path}.family: unsupported family")
    if not isinstance(semantic, str) or not semantic:
        errors.append(f"{path}.semantic: required")
    if not isinstance(layer.get("name"), str) or not layer.get("name"):
        errors.append(f"{path}.name: required")
    if status not in LAYER_STATUSES:
        errors.append(f"{path}.status: unsupported status")
    validate_geometry(layer.get("geometry"), f"{path}.geometry", width, height, errors)
    bindings = require_list(layer.get("bindings"), f"{path}.bindings", errors)
    validated_bindings = [
        validate_binding(binding, f"{path}.bindings[{index}]", errors)
        for index, binding in enumerate(bindings)
    ]
    constraints = require_object(layer.get("constraints"), f"{path}.constraints", errors)
    if status in {"approved", "applied", "verified"} and not bindings:
        errors.append(f"{path}.bindings: approved and later layers require a live resource binding")
    semantic_key = str(semantic).lower()
    if status in {"approved", "applied", "verified"} and semantic_key == "forest":
        if not any(binding.get("actionFamily") == "environment" for binding in validated_bindings):
            errors.append(f"{path}: forest must bind to the Environment capability")
    if semantic_key == "river":
        if constraints.get("waterBodyType") != "river":
            errors.append(f"{path}.constraints.waterBodyType: river is required")
        for binding in validated_bindings:
            if "ocean" in str(binding.get("resourceId", "")).lower():
                errors.append(f"{path}: ocean resources cannot bind a river")
    if family == "border" and status in {"approved", "applied", "verified"}:
        if constraints.get("explicitApproval") is not True:
            errors.append(f"{path}.constraints.explicitApproval: required for borders")
    return layer_id


def validate_missing_asset(value: object, path: str, errors: list[str]) -> str | None:
    asset = require_object(value, path, errors)
    asset_id = asset.get("id")
    status = asset.get("status")
    if not isinstance(asset_id, str) or not asset_id:
        errors.append(f"{path}.id: required")
        asset_id = None
    if status not in ASSET_STATUSES:
        errors.append(f"{path}.status: unsupported status")
    width = positive_int(asset.get("widthCells"), f"{path}.widthCells", errors, 64)
    height = positive_int(asset.get("heightCells"), f"{path}.heightCells", errors, 64)
    if asset.get("pixelWidth") != width * CELL_SIZE:
        errors.append(f"{path}.pixelWidth: must equal widthCells * 32")
    if asset.get("pixelHeight") != height * CELL_SIZE:
        errors.append(f"{path}.pixelHeight: must equal heightCells * 32")
    validate_cell(asset.get("anchor"), f"{path}.anchor", width, height, errors)
    collisions = require_list(asset.get("collisionCells"), f"{path}.collisionCells", errors)
    for index, cell in enumerate(collisions):
        validate_cell(cell, f"{path}.collisionCells[{index}]", width, height, errors)
    if asset.get("provenance") != "custom_hgss_compatible":
        errors.append(f"{path}.provenance: must be custom_hgss_compatible")
    if asset.get("alphaPolicy") not in {"required", "optional"}:
        errors.append(f"{path}.alphaPolicy: expected required or optional")
    references = require_list(asset.get("styleReferences"), f"{path}.styleReferences", errors)
    if status in {"approved", "imported", "verified"}:
        if not isinstance(asset.get("sourcePng"), str) or not asset.get("sourcePng"):
            errors.append(f"{path}.sourcePng: required after approval")
        if not references:
            errors.append(f"{path}.styleReferences: at least one HGSS/DS reference is required")
    return asset_id


def validate_blueprint(document: dict) -> list[str]:
    errors: list[str] = []
    if document.get("schemaVersion") != 1:
        errors.append("schemaVersion: expected 1")
    if document.get("cellSizePx") != CELL_SIZE:
        errors.append("cellSizePx: expected 32")
    source = require_object(document.get("source"), "source", errors)
    if not isinstance(source.get("referenceImage"), str) or not source.get("referenceImage"):
        errors.append("source.referenceImage: required")
    if source.get("role") != "composition_reference":
        errors.append("source.role: expected composition_reference")
    map_data = require_object(document.get("map"), "map", errors)
    if not isinstance(map_data.get("id"), str) or not map_data.get("id"):
        errors.append("map.id: required")
    if not isinstance(map_data.get("name"), str) or not map_data.get("name"):
        errors.append("map.name: required")
    width = positive_int(map_data.get("widthCells"), "map.widthCells", errors)
    height = positive_int(map_data.get("heightCells"), "map.heightCells", errors)
    if document.get("familyOrder") != FAMILY_ORDER:
        errors.append("familyOrder: expected canonical family order")
    layers = require_list(document.get("layers"), "layers", errors)
    layer_ids = [
        validate_layer(layer, f"layers[{index}]", width, height, errors)
        for index, layer in enumerate(layers)
    ]
    assets = require_list(document.get("missingAssets"), "missingAssets", errors)
    asset_ids = [
        validate_missing_asset(asset, f"missingAssets[{index}]", errors)
        for index, asset in enumerate(assets)
    ]
    identifiers = [identifier for identifier in layer_ids + asset_ids if identifier]
    duplicates = [identifier for identifier, count in Counter(identifiers).items() if count > 1]
    for identifier in duplicates:
        errors.append(f"id: duplicate identifier {identifier}")
    review = require_object(document.get("review"), "review", errors)
    if review.get("status") not in LAYER_STATUSES:
        errors.append("review.status: unsupported status")
    require_list(review.get("notes"), "review.notes", errors)
    return errors


def summarize(document: dict) -> dict:
    layers = document.get("layers") if isinstance(document.get("layers"), list) else []
    assets = document.get("missingAssets") if isinstance(document.get("missingAssets"), list) else []
    return {
        "map": document.get("map"),
        "cellSizePx": document.get("cellSizePx"),
        "layers": len(layers),
        "byFamily": dict(Counter(layer.get("family") for layer in layers if isinstance(layer, dict))),
        "byStatus": dict(Counter(layer.get("status") for layer in layers if isinstance(layer, dict))),
        "missingAssets": len(assets),
        "unresolvedLayerIds": [
            layer.get("id")
            for layer in layers
            if isinstance(layer, dict) and layer.get("status") == "proposed"
        ],
    }


def write_json(path: Path, value: dict, force: bool) -> None:
    if path.exists() and not force:
        raise FileExistsError(f"refusing to overwrite {path}; pass --force")
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("w", encoding="utf-8") as handle:
        json.dump(value, handle, ensure_ascii=False, indent=2)
        handle.write("\n")


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(prog="blueprint_tool.py")
    subparsers = parser.add_subparsers(dest="command", required=True)
    init = subparsers.add_parser("init")
    init.add_argument("--output", required=True)
    init.add_argument("--reference", required=True)
    init.add_argument("--map-id", required=True)
    init.add_argument("--name")
    init.add_argument("--width", required=True, type=int)
    init.add_argument("--height", required=True, type=int)
    init.add_argument("--force", action="store_true")
    validate = subparsers.add_parser("validate")
    validate.add_argument("path")
    validate.add_argument("--json", action="store_true")
    summary = subparsers.add_parser("summary")
    summary.add_argument("path")
    summary.add_argument("--json", action="store_true")
    return parser


def main(argv: list[str] | None = None) -> int:
    args = build_parser().parse_args(argv)
    try:
        if args.command == "init":
            if args.width < 1 or args.height < 1:
                raise ValueError("map dimensions must be positive")
            blueprint = create_blueprint(
                args.reference,
                args.map_id,
                args.name or args.map_id,
                args.width,
                args.height,
            )
            output = Path(args.output).expanduser().resolve()
            write_json(output, blueprint, args.force)
            print(output)
            return 0
        document = load_document(Path(args.path).expanduser().resolve())
        if args.command == "validate":
            errors = validate_blueprint(document)
            result = {"valid": not errors, "errors": errors, "summary": summarize(document)}
            print(json.dumps(result, ensure_ascii=False, indent=2) if args.json else ("valid" if not errors else "\n".join(errors)))
            return 0 if not errors else 1
        result = summarize(document)
        print(json.dumps(result, ensure_ascii=False, indent=2) if args.json else json.dumps(result, ensure_ascii=False))
        return 0
    except (OSError, ValueError, json.JSONDecodeError) as error:
        print(str(error), file=sys.stderr)
        return 2


if __name__ == "__main__":
    raise SystemExit(main())
