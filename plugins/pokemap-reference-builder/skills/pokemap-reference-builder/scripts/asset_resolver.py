#!/usr/bin/env python3
import argparse
import hashlib
import json
import re
import sys
from pathlib import Path

from PIL import Image


CELL_SIZE = 32
ELIGIBLE_PROVENANCE = {"hgss_ds", "custom_hgss_compatible"}
IGNORED_TAGS = {
    "asset",
    "assets",
    "custom",
    "compatible",
    "ds",
    "hgss",
    "image",
    "images",
    "png",
}


def tokenize(values: list[str]) -> set[str]:
    tokens: set[str] = set()
    for value in values:
        for token in re.findall(r"[a-z0-9]+", value.lower()):
            if token in IGNORED_TAGS or token.isdigit() or re.fullmatch(r"\d+x\d+", token):
                continue
            tokens.add(token)
    return tokens


def inspect_asset(path: Path, root: Path, provenance: str) -> dict:
    with Image.open(path) as source:
        image = source.convert("RGBA")
        alpha = image.getchannel("A")
        alpha_used = alpha.getextrema()[0] < 255
        colors = image.getcolors(maxcolors=65537)
        color_count = len(colors) if colors is not None else 65537
        width_cells = image.width // CELL_SIZE if image.width % CELL_SIZE == 0 else None
        height_cells = image.height // CELL_SIZE if image.height % CELL_SIZE == 0 else None
    relative = path.relative_to(root)
    tags = sorted(tokenize([str(relative.with_suffix(""))]))
    return {
        "id": "asset-" + hashlib.sha256(str(path.resolve()).encode("utf-8")).hexdigest()[:16],
        "path": str(path.resolve()),
        "relativePath": str(relative),
        "provenance": provenance,
        "widthPx": image.width,
        "heightPx": image.height,
        "widthCells": width_cells,
        "heightCells": height_cells,
        "alphaUsed": alpha_used,
        "colorCount": color_count,
        "tags": tags,
        "eligible": provenance in ELIGIBLE_PROVENANCE and width_cells is not None and height_cells is not None,
    }


def index_assets(roots: list[dict]) -> dict:
    assets = []
    normalized_roots = []
    for index, item in enumerate(roots):
        if not isinstance(item, dict):
            raise ValueError(f"roots[{index}] must be an object")
        path_value = item.get("path")
        provenance = item.get("provenance")
        if not isinstance(path_value, str) or not path_value:
            raise ValueError(f"roots[{index}].path is required")
        if not isinstance(provenance, str) or not provenance:
            raise ValueError(f"roots[{index}].provenance is required")
        root = Path(path_value).expanduser().resolve()
        if not root.is_dir():
            raise ValueError(f"asset root is not a directory: {root}")
        normalized_roots.append({"path": str(root), "provenance": provenance})
        for path in sorted(root.rglob("*.png")):
            try:
                assets.append(inspect_asset(path, root, provenance))
            except (OSError, ValueError):
                assets.append(
                    {
                        "id": "asset-" + hashlib.sha256(str(path.resolve()).encode("utf-8")).hexdigest()[:16],
                        "path": str(path.resolve()),
                        "relativePath": str(path.relative_to(root)),
                        "provenance": provenance,
                        "eligible": False,
                        "errors": ["unreadable PNG"],
                    }
                )
    return {
        "schemaVersion": 1,
        "cellSizePx": CELL_SIZE,
        "roots": normalized_roots,
        "assets": assets,
    }


def requirement_terms(requirement: dict) -> set[str]:
    values = [str(requirement.get("id", "")), str(requirement.get("semantic", ""))]
    tags = requirement.get("tags", [])
    references = requirement.get("styleReferences", [])
    if isinstance(tags, list):
        values.extend(str(value) for value in tags)
    if isinstance(references, list):
        values.extend(str(value) for value in references)
    return tokenize(values)


def score_candidate(requirement: dict, candidate: dict) -> int | None:
    if not candidate.get("eligible"):
        return None
    if candidate.get("widthCells") != requirement.get("widthCells"):
        return None
    if candidate.get("heightCells") != requirement.get("heightCells"):
        return None
    if requirement.get("alphaPolicy") == "required" and not candidate.get("alphaUsed"):
        return None
    expected = requirement_terms(requirement)
    actual = set(candidate.get("tags", []))
    shared = expected & actual
    semantic_score = 0 if not expected else round(30 * len(shared) / len(expected))
    return 40 + 20 + 10 + semantic_score


def resolve_missing_assets(blueprint: dict, catalog: dict, limit: int = 5) -> dict:
    if not isinstance(limit, int) or isinstance(limit, bool) or limit < 1:
        raise ValueError("limit must be a positive integer")
    assets = catalog.get("assets")
    if not isinstance(assets, list):
        raise ValueError("catalog.assets must be an array")
    requirements = blueprint.get("missingAssets")
    if not isinstance(requirements, list):
        raise ValueError("blueprint.missingAssets must be an array")
    resolutions = []
    for index, requirement in enumerate(requirements):
        if not isinstance(requirement, dict):
            raise ValueError(f"blueprint.missingAssets[{index}] must be an object")
        ranked = []
        for candidate in assets:
            if not isinstance(candidate, dict):
                continue
            score = score_candidate(requirement, candidate)
            if score is None:
                continue
            ranked.append({**candidate, "score": score})
        ranked.sort(key=lambda item: (-item["score"], item["relativePath"]))
        selected = ranked[:limit]
        decision = "reuse" if selected and selected[0]["score"] >= 80 else "gap"
        resolutions.append(
            {
                "assetId": requirement.get("id"),
                "semantic": requirement.get("semantic"),
                "decision": decision,
                "expectedCanvas": {
                    "widthPx": requirement.get("widthCells", 0) * CELL_SIZE,
                    "heightPx": requirement.get("heightCells", 0) * CELL_SIZE,
                },
                "candidates": selected if decision == "reuse" else [],
            }
        )
    return {
        "schemaVersion": 1,
        "cellSizePx": CELL_SIZE,
        "resolutions": resolutions,
        "requiresHumanReview": True,
    }


def materialize_gap_workshop(
    blueprint: dict,
    resolution_report: dict,
    output_directory: Path,
    force: bool = False,
) -> dict:
    requirements = blueprint.get("missingAssets")
    resolutions = resolution_report.get("resolutions")
    if not isinstance(requirements, list):
        raise ValueError("blueprint.missingAssets must be an array")
    if not isinstance(resolutions, list):
        raise ValueError("resolutionReport.resolutions must be an array")
    by_id = {requirement.get("id"): requirement for requirement in requirements if isinstance(requirement, dict)}
    output_directory = Path(output_directory).expanduser().resolve()
    output_directory.mkdir(parents=True, exist_ok=True)
    assets = []
    for resolution in resolutions:
        if not isinstance(resolution, dict) or resolution.get("decision") != "gap":
            continue
        asset_id = resolution.get("assetId")
        requirement = by_id.get(asset_id)
        if not isinstance(asset_id, str) or not isinstance(requirement, dict):
            raise ValueError(f"gap resolution has no matching requirement: {asset_id}")
        filename = re.sub(r"[^A-Za-z0-9._-]+", "-", asset_id).strip("-")
        canvas_path = output_directory / f"{filename}.canvas.png"
        contract_path = output_directory / f"{filename}.contract.json"
        if not force and (canvas_path.exists() or contract_path.exists()):
            raise FileExistsError(f"refusing to overwrite workshop files for {asset_id}; pass --force")
        width = requirement.get("widthCells")
        height = requirement.get("heightCells")
        if not isinstance(width, int) or not isinstance(height, int) or width < 1 or height < 1:
            raise ValueError(f"invalid footprint for {asset_id}")
        Image.new("RGBA", (width * CELL_SIZE, height * CELL_SIZE), (0, 0, 0, 0)).save(canvas_path)
        contract = {**requirement, "sourcePng": str(canvas_path)}
        write_json(contract_path, contract, force)
        assets.append(
            {
                "assetId": asset_id,
                "canvas": str(canvas_path),
                "contract": str(contract_path),
                "widthCells": width,
                "heightCells": height,
                "pixelWidth": width * CELL_SIZE,
                "pixelHeight": height * CELL_SIZE,
                "requiresHumanReview": True,
            }
        )
    return {
        "schemaVersion": 1,
        "cellSizePx": CELL_SIZE,
        "assets": assets,
        "requiresHumanReview": True,
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


def parse_root(value: str) -> dict:
    if "=" not in value:
        raise ValueError("asset roots must use PATH=PROVENANCE")
    path, provenance = value.rsplit("=", 1)
    if not path or not provenance:
        raise ValueError("asset roots must use PATH=PROVENANCE")
    return {"path": path, "provenance": provenance}


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(prog="asset_resolver.py")
    subparsers = parser.add_subparsers(dest="command", required=True)
    index = subparsers.add_parser("index")
    index.add_argument("--root", action="append", required=True)
    index.add_argument("--output", required=True)
    index.add_argument("--force", action="store_true")
    resolve = subparsers.add_parser("resolve")
    resolve.add_argument("--blueprint", required=True)
    resolve.add_argument("--catalog", required=True)
    resolve.add_argument("--output", required=True)
    resolve.add_argument("--limit", type=int, default=5)
    resolve.add_argument("--force", action="store_true")
    workshop = subparsers.add_parser("workshop")
    workshop.add_argument("--blueprint", required=True)
    workshop.add_argument("--resolution", required=True)
    workshop.add_argument("--output-dir", required=True)
    workshop.add_argument("--manifest")
    workshop.add_argument("--force", action="store_true")
    return parser


def main(argv: list[str] | None = None) -> int:
    args = build_parser().parse_args(argv)
    try:
        if args.command == "index":
            output = Path(args.output).expanduser().resolve()
            result = index_assets([parse_root(value) for value in args.root])
        elif args.command == "resolve":
            output = Path(args.output).expanduser().resolve()
            blueprint = load_json(Path(args.blueprint).expanduser().resolve())
            catalog = load_json(Path(args.catalog).expanduser().resolve())
            result = resolve_missing_assets(blueprint, catalog, args.limit)
        else:
            blueprint = load_json(Path(args.blueprint).expanduser().resolve())
            resolution = load_json(Path(args.resolution).expanduser().resolve())
            output_directory = Path(args.output_dir).expanduser().resolve()
            result = materialize_gap_workshop(blueprint, resolution, output_directory, args.force)
            output = Path(args.manifest).expanduser().resolve() if args.manifest else output_directory / "workshop-manifest.json"
        write_json(output, result, args.force)
        print(output)
        return 0
    except (OSError, ValueError, json.JSONDecodeError) as error:
        print(str(error), file=sys.stderr)
        return 2


if __name__ == "__main__":
    raise SystemExit(main())
