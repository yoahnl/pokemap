#!/usr/bin/env python3
import argparse
import colorsys
import hashlib
import json
import math
import sys
from pathlib import Path

from PIL import Image, ImageFilter, ImageOps

AXIS_WEIGHTS = {
    "paletteAndStyle": 35,
    "visualHierarchy": 40,
    "detailDensity": 25,
}

SEMANTIC_AXIS_WEIGHTS = {
    "paletteAndStyle": 25,
    "visualHierarchy": 30,
    "detailDensity": 15,
    "semanticMaterials": 30,
}


def mean(values: list[float] | tuple[float, ...]) -> float:
    return sum(values) / len(values) if values else 0.0


def sha256(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def normalized_size(width: int, height: int, maximum_edge: int = 256) -> tuple[int, int]:
    if width >= height:
        return maximum_edge, max(16, round(maximum_edge * height / width))
    return max(16, round(maximum_edge * width / height)), maximum_edge


def normalize_image(image: Image.Image, size: tuple[int, int]) -> Image.Image:
    if image.size == size:
        return image.copy()
    resampling = Image.Resampling.BOX if image.width >= size[0] and image.height >= size[1] else Image.Resampling.LANCZOS
    return image.resize(size, resampling)


def load_comparable_images(reference_path: Path, candidate_path: Path) -> tuple[Image.Image, Image.Image, dict]:
    reference_path = reference_path.expanduser().resolve()
    candidate_path = candidate_path.expanduser().resolve()
    reference = Image.open(reference_path).convert("RGB")
    candidate = Image.open(candidate_path).convert("RGB")
    if reference.width * candidate.height != candidate.width * reference.height:
        raise ValueError(
            "reference and candidate aspect ratio must match; use an explicit same-crop capture before comparison"
        )
    maximum_edge = min(256, max(reference.size), max(candidate.size))
    size = normalized_size(reference.width, reference.height, maximum_edge)
    normalized_reference = normalize_image(reference, size)
    normalized_candidate = normalize_image(candidate, size)
    inputs = {
        "reference": {
            "path": str(reference_path),
            "sha256": sha256(reference_path),
            "width": reference.width,
            "height": reference.height,
        },
        "candidate": {
            "path": str(candidate_path),
            "sha256": sha256(candidate_path),
            "width": candidate.width,
            "height": candidate.height,
        },
        "normalizedWidth": size[0],
        "normalizedHeight": size[1],
    }
    return normalized_reference, normalized_candidate, inputs


def region_boxes(image: Image.Image, columns: int, rows: int) -> list[tuple[int, int, tuple[int, int, int, int]]]:
    return [
        (
            x,
            y,
            (
                x * image.width // columns,
                y * image.height // rows,
                (x + 1) * image.width // columns,
                (y + 1) * image.height // rows,
            ),
        )
        for y in range(rows)
        for x in range(columns)
    ]


def color_histogram(image: Image.Image, box: tuple[int, int, int, int]) -> list[float]:
    hue_bins = 8
    saturation_bins = 3
    value_bins = 3
    values = [0] * (hue_bins * saturation_bins * value_bins)
    sample = image.crop(box).resize((48, 48), Image.Resampling.BILINEAR)
    for red, green, blue in sample.get_flattened_data():
        hue, saturation, value = colorsys.rgb_to_hsv(red / 255, green / 255, blue / 255)
        hue_index = min(hue_bins - 1, int(hue * hue_bins))
        saturation_index = min(saturation_bins - 1, int(saturation * saturation_bins))
        value_index = min(value_bins - 1, int(value * value_bins))
        values[(hue_index * saturation_bins + saturation_index) * value_bins + value_index] += 1
    total = sum(values)
    return [count / total for count in values]


def color_histogram_boxes(image: Image.Image, boxes: list[tuple[int, int, int, int]]) -> list[float]:
    hue_bins = 8
    saturation_bins = 3
    value_bins = 3
    values = [0] * (hue_bins * saturation_bins * value_bins)
    for box in boxes:
        for red, green, blue in image.crop(box).get_flattened_data():
            hue, saturation, value = colorsys.rgb_to_hsv(red / 255, green / 255, blue / 255)
            hue_index = min(hue_bins - 1, int(hue * hue_bins))
            saturation_index = min(saturation_bins - 1, int(saturation * saturation_bins))
            value_index = min(value_bins - 1, int(value * value_bins))
            values[(hue_index * saturation_bins + saturation_index) * value_bins + value_index] += 1
    total = sum(values)
    return [count / total for count in values] if total else [0.0] * len(values)


def histogram_intersection(reference: list[float], candidate: list[float]) -> float:
    return sum(min(expected, actual) for expected, actual in zip(reference, candidate))


def palette_regions(reference: Image.Image, candidate: Image.Image, columns: int, rows: int) -> list[float]:
    return [
        100
        * histogram_intersection(
            color_histogram(reference, box),
            color_histogram(candidate, box),
        )
        for _, _, box in region_boxes(reference, columns, rows)
    ]


def structural_similarity(reference_values: tuple[int, ...], candidate_values: tuple[int, ...]) -> float:
    reference_mean = mean(reference_values)
    candidate_mean = mean(candidate_values)
    reference_variance = mean([(value - reference_mean) ** 2 for value in reference_values])
    candidate_variance = mean([(value - candidate_mean) ** 2 for value in candidate_values])
    covariance = mean(
        [
            (expected - reference_mean) * (actual - candidate_mean)
            for expected, actual in zip(reference_values, candidate_values)
        ]
    )
    luminance_constant = (0.01 * 255) ** 2
    contrast_constant = (0.03 * 255) ** 2
    numerator = (2 * reference_mean * candidate_mean + luminance_constant) * (
        2 * covariance + contrast_constant
    )
    denominator = (
        reference_mean**2 + candidate_mean**2 + luminance_constant
    ) * (reference_variance + candidate_variance + contrast_constant)
    return max(0.0, numerator / denominator) if denominator else 1.0


def hierarchy_images(reference: Image.Image, candidate: Image.Image) -> tuple[Image.Image, Image.Image]:
    radius = max(1, round(min(reference.size) / 104))
    expected = ImageOps.autocontrast(reference.convert("L")).filter(ImageFilter.GaussianBlur(radius))
    actual = ImageOps.autocontrast(candidate.convert("L")).filter(ImageFilter.GaussianBlur(radius))
    return expected, actual


def hierarchy_regions(reference: Image.Image, candidate: Image.Image, columns: int, rows: int) -> list[float]:
    expected, actual = hierarchy_images(reference, candidate)
    return [
        100
        * structural_similarity(
            tuple(expected.crop(box).get_flattened_data()),
            tuple(actual.crop(box).get_flattened_data()),
        )
        for _, _, box in region_boxes(reference, columns, rows)
    ]


def detail_images(reference: Image.Image, candidate: Image.Image) -> tuple[Image.Image, Image.Image]:
    expected = ImageOps.autocontrast(reference.convert("L")).filter(ImageFilter.FIND_EDGES)
    actual = ImageOps.autocontrast(candidate.convert("L")).filter(ImageFilter.FIND_EDGES)
    return expected, actual


def detail_regions(reference: Image.Image, candidate: Image.Image, columns: int, rows: int) -> list[float]:
    expected, actual = detail_images(reference, candidate)
    values = []
    for _, _, box in region_boxes(reference, columns, rows):
        expected_density = mean(tuple(expected.crop(box).get_flattened_data()))
        actual_density = mean(tuple(actual.crop(box).get_flattened_data()))
        maximum = max(expected_density, actual_density)
        values.append(100 if maximum == 0 else 100 * min(expected_density, actual_density) / maximum)
    return values


def visual_axes(reference: Image.Image, candidate: Image.Image) -> dict[str, int]:
    palette = mean(palette_regions(reference, candidate, 4, 4))
    hierarchy = mean(
        [
            *hierarchy_regions(reference, candidate, 16, 13),
            *hierarchy_regions(reference, candidate, 8, 7),
        ]
    )
    detail = mean(detail_regions(reference, candidate, 8, 7))
    return {
        "paletteAndStyle": round(palette),
        "visualHierarchy": round(hierarchy),
        "detailDensity": round(detail),
    }


def semantic_material_metrics(reference: Image.Image, candidate: Image.Image, blueprint: dict) -> dict:
    map_value = blueprint.get("map")
    if not isinstance(map_value, dict):
        raise ValueError("blueprint map metadata is missing")
    width_cells = map_value.get("widthCells")
    height_cells = map_value.get("heightCells")
    if not isinstance(width_cells, int) or not isinstance(height_cells, int) or width_cells <= 0 or height_cells <= 0:
        raise ValueError("blueprint map dimensions must be positive integers")
    hierarchy_reference, hierarchy_candidate = hierarchy_images(reference, candidate)
    detail_reference, detail_candidate = detail_images(reference, candidate)
    families = []
    for layer in blueprint.get("layers", []):
        geometry = layer.get("geometry") if isinstance(layer, dict) else None
        cells = geometry.get("cells") if isinstance(geometry, dict) else None
        if not isinstance(cells, list) or not cells:
            continue
        boxes = []
        for cell in cells:
            if not isinstance(cell, dict):
                raise ValueError("blueprint geometry cells must be objects")
            x = cell.get("x")
            y = cell.get("y")
            if not isinstance(x, int) or not isinstance(y, int) or not 0 <= x < width_cells or not 0 <= y < height_cells:
                raise ValueError("blueprint geometry cell is outside map bounds")
            boxes.append(
                (
                    x * reference.width // width_cells,
                    y * reference.height // height_cells,
                    (x + 1) * reference.width // width_cells,
                    (y + 1) * reference.height // height_cells,
                )
            )

        def flattened(image: Image.Image) -> tuple[int, ...]:
            return tuple(value for box in boxes for value in image.crop(box).get_flattened_data())

        palette = 100 * histogram_intersection(
            color_histogram_boxes(reference, boxes),
            color_histogram_boxes(candidate, boxes),
        )
        hierarchy = 100 * structural_similarity(
            flattened(hierarchy_reference),
            flattened(hierarchy_candidate),
        )
        reference_detail = mean(flattened(detail_reference))
        candidate_detail = mean(flattened(detail_candidate))
        maximum_detail = max(reference_detail, candidate_detail)
        detail = 100 if maximum_detail == 0 else 100 * min(reference_detail, candidate_detail) / maximum_detail
        axes = {
            "paletteAndStyle": round(palette),
            "visualHierarchy": round(hierarchy),
            "detailDensity": round(detail),
        }
        score = round(
            sum(axes[axis] * weight for axis, weight in AXIS_WEIGHTS.items())
            / sum(AXIS_WEIGHTS.values())
        )
        families.append(
            {
                "layerId": layer.get("id"),
                "name": layer.get("name"),
                "family": layer.get("family"),
                "cellCount": len(cells),
                "score": score,
                "axes": axes,
            }
        )
    if not families:
        raise ValueError("blueprint must contain at least one non-empty semantic layer")
    return {
        "score": round(mean([family["score"] for family in families])),
        "families": sorted(families, key=lambda family: (family["score"], family["layerId"] or "")),
    }


def weakest_regions(reference: Image.Image, candidate: Image.Image) -> list[dict]:
    columns = 4
    rows = 4
    palettes = palette_regions(reference, candidate, columns, rows)
    hierarchies = hierarchy_regions(reference, candidate, columns, rows)
    details = detail_regions(reference, candidate, columns, rows)
    regions = []
    for index, (x, y, _) in enumerate(region_boxes(reference, columns, rows)):
        axes = {
            "paletteAndStyle": round(palettes[index]),
            "visualHierarchy": round(hierarchies[index]),
            "detailDensity": round(details[index]),
        }
        score = round(
            sum(axes[axis] * weight for axis, weight in AXIS_WEIGHTS.items())
            / sum(AXIS_WEIGHTS.values())
        )
        regions.append(
            {
                "gridX": x,
                "gridY": y,
                "boundsRatio": {
                    "left": x / columns,
                    "top": y / rows,
                    "right": (x + 1) / columns,
                    "bottom": (y + 1) / rows,
                },
                "score": score,
                "axes": axes,
            }
        )
    return sorted(regions, key=lambda region: (region["score"], region["gridY"], region["gridX"]))[:6]


def repair_plan(axes: dict[str, int], threshold: int) -> list[dict]:
    repairs = []
    rules = {
        "paletteAndStyle": (
            "match_palette_and_materials",
            "Palette, saturation, values, and material rendering diverge from the reference",
        ),
        "visualHierarchy": (
            "repair_visual_hierarchy",
            "Major masses, negative space, and landmark hierarchy diverge from the reference",
        ),
        "detailDensity": (
            "restore_detail_density",
            "Visual detail density is too sparse or too noisy compared with the reference",
        ),
        "semanticMaterials": (
            "repair_semantic_material_families",
            "One or more semantic surface or network families diverge from their reference regions",
        ),
    }
    for axis, (action, reason) in rules.items():
        if axis in axes and axes[axis] < threshold:
            repairs.append(
                {
                    "priority": "blocking",
                    "action": action,
                    "axis": axis,
                    "score": axes[axis],
                    "threshold": threshold,
                    "reason": reason,
                }
            )
    return repairs


def compare_images(
    reference_path: Path,
    candidate_path: Path,
    threshold: int = 80,
    blueprint_path: Path | None = None,
) -> dict:
    if not isinstance(threshold, int) or isinstance(threshold, bool) or not 0 <= threshold <= 100:
        raise ValueError("threshold must be an integer between 0 and 100")
    reference, candidate, inputs = load_comparable_images(Path(reference_path), Path(candidate_path))
    axes = visual_axes(reference, candidate)
    semantic_materials = None
    if blueprint_path is not None:
        resolved_blueprint_path = Path(blueprint_path).expanduser().resolve()
        blueprint = json.loads(resolved_blueprint_path.read_text(encoding="utf-8"))
        if not isinstance(blueprint, dict):
            raise ValueError("blueprint must be a JSON object")
        semantic_materials = semantic_material_metrics(reference, candidate, blueprint)
        axes["semanticMaterials"] = semantic_materials["score"]
        inputs["blueprint"] = {
            "path": str(resolved_blueprint_path),
            "sha256": sha256(resolved_blueprint_path),
        }
    weights = SEMANTIC_AXIS_WEIGHTS if semantic_materials is not None else AXIS_WEIGHTS
    score = round(
        sum(axes[axis] * weight for axis, weight in weights.items())
        / sum(weights.values())
    )
    failed_axes = [axis for axis in weights if axes[axis] < threshold]
    return {
        "schemaVersion": 1,
        "threshold": threshold,
        "score": score,
        "axes": axes,
        "failedAxes": failed_axes,
        "eligibleForVisualReview": score >= threshold and not failed_axes,
        "humanAccepted": False,
        "regions": weakest_regions(reference, candidate),
        "semanticFamilies": semantic_materials["families"] if semantic_materials is not None else [],
        "repairPlan": repair_plan(axes, threshold),
        "inputs": inputs,
    }


def write_json(path: Path, value: dict, force: bool) -> None:
    if path.exists() and not force:
        raise FileExistsError(f"refusing to overwrite {path}; pass --force")
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("w", encoding="utf-8") as handle:
        json.dump(value, handle, ensure_ascii=False, indent=2)
        handle.write("\n")


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(prog="visual_quality.py")
    subparsers = parser.add_subparsers(dest="command", required=True)
    compare = subparsers.add_parser("compare")
    compare.add_argument("--reference", required=True)
    compare.add_argument("--candidate", required=True)
    compare.add_argument("--threshold", type=int, default=80)
    compare.add_argument("--blueprint")
    compare.add_argument("--output", required=True)
    compare.add_argument("--force", action="store_true")
    return parser


def main(argv: list[str] | None = None) -> int:
    args = build_parser().parse_args(argv)
    report = compare_images(
        Path(args.reference),
        Path(args.candidate),
        threshold=args.threshold,
        blueprint_path=Path(args.blueprint) if args.blueprint else None,
    )
    output = Path(args.output).expanduser().resolve()
    write_json(output, report, args.force)
    print(output)
    return 0 if report["eligibleForVisualReview"] else 2


if __name__ == "__main__":
    sys.exit(main())
