from __future__ import annotations

import xml.etree.ElementTree as ET
from pathlib import Path

from PIL import Image


GUIDE_COLORS = {(255, 245, 104), (240, 91, 161)}
RULE_MAPS = (
    ("rules_TECH_buildings.tmx", "buildings", "Bâtiment"),
    ("rules_TECH_trees.tmx", "trees", "Arbre"),
    ("rules_TECH_nature.tmx", "nature", "Élément naturel"),
    ("rules_TECH_assets.tmx", "props", "Mobilier ou accessoire"),
)


def _layer_cells(layer: ET.Element) -> dict[tuple[int, int], int]:
    data = layer.find("data")
    if data is None:
        return {}
    if data.get("encoding") != "csv" or data.get("compression"):
        raise ValueError(f"Unsupported tile encoding in {layer.get('name')}")
    if any(float(layer.get(key, "0")) for key in ("x", "y", "offsetx", "offsety")):
        raise ValueError(f"Unsupported layer offset in {layer.get('name')}")
    result = {}
    chunks = data.findall("chunk")
    if not chunks and not (data.text or "").strip():
        return result
    for chunk in chunks or [data]:
        width = int(chunk.get("width", layer.get("width", "0")))
        height = int(chunk.get("height", layer.get("height", "0")))
        x0, y0 = int(chunk.get("x", "0")), int(chunk.get("y", "0"))
        values = [int(value) for value in (chunk.text or "").split(",") if value.strip()]
        if width <= 0 or len(values) != width * height:
            raise ValueError(f"Invalid tile data in {layer.get('name')}")
        for index, value in enumerate(values):
            if value:
                result[(x0 + index % width, y0 + index // width)] = value
    return result


def _components(cells: set[tuple[int, int]]) -> list[set[tuple[int, int]]]:
    remaining = set(cells)
    result = []
    while remaining:
        start = remaining.pop()
        pending, component = [start], {start}
        while pending:
            x, y = pending.pop()
            for neighbor in ((x - 1, y), (x + 1, y), (x, y - 1), (x, y + 1)):
                if neighbor in remaining:
                    remaining.remove(neighbor)
                    component.add(neighbor)
                    pending.append(neighbor)
        result.append(component)
    return sorted(result, key=lambda cells: (min(y for x, y in cells), min(x for x, y in cells)))


def _tilesets(root: ET.Element, map_path: Path, tiled_root: Path) -> list[dict]:
    result = []
    for reference in root.findall("tileset"):
        source = reference.get("source")
        if not source:
            raise ValueError(f"External TSX required in {map_path}")
        tsx_path = (map_path.parent / source).resolve()
        tsx = ET.parse(tsx_path).getroot()
        image_node = tsx.find("image")
        if image_node is None:
            raise ValueError(f"Image tileset required in {tsx_path}")
        image_path = (tsx_path.parent / image_node.attrib["source"]).resolve()
        with Image.open(image_path) as opened:
            image = opened.convert("RGBA")
        result.append({
            "firstgid": int(reference.attrib["firstgid"]),
            "tilecount": int(tsx.attrib["tilecount"]),
            "columns": int(tsx.attrib["columns"]),
            "width": int(tsx.attrib["tilewidth"]),
            "height": int(tsx.attrib["tileheight"]),
            "spacing": int(tsx.get("spacing", "0")),
            "margin": int(tsx.get("margin", "0")),
            "source": image_path.relative_to(tiled_root).as_posix(),
            "image": image,
        })
    return sorted(result, key=lambda item: item["firstgid"], reverse=True)


def _tile_reference(gid: int, tilesets: list[dict]) -> tuple[dict, dict]:
    tile_gid, flags = gid & 0x0FFFFFFF, gid & 0xF0000000
    if flags & 0x30000000:
        raise ValueError(f"Diagonal or hexagonal tile transform needs explicit support: {gid}")
    tileset = next((item for item in tilesets if item["firstgid"] <= tile_gid), None)
    if tileset is None:
        raise ValueError(f"Unresolved GID {gid}")
    tile_id = tile_gid - tileset["firstgid"]
    return tileset, {
        "source": tileset["source"],
        "tx": tile_id % tileset["columns"],
        "ty": tile_id // tileset["columns"],
        "tileId": tile_id,
        "gid": gid,
        "flags": flags,
    }


def _tile_image(tileset: dict, reference: dict) -> Image.Image:
    if reference["tileId"] >= tileset["tilecount"]:
        raise ValueError(f"Tile {reference['tileId']} exceeds TSX tilecount {tileset['tilecount']}")
    width, height = tileset["width"], tileset["height"]
    left = tileset["margin"] + reference["tx"] * (width + tileset["spacing"])
    top = tileset["margin"] + reference["ty"] * (height + tileset["spacing"])
    if left + width > tileset["image"].width or top + height > tileset["image"].height:
        raise ValueError(f"Source tile exceeds image: {reference}")
    image = tileset["image"].crop((left, top, left + width, top + height))
    pixels = bytearray(image.tobytes())
    for offset in range(0, len(pixels), 4):
        if tuple(pixels[offset:offset + 3]) in GUIDE_COLORS:
            pixels[offset + 3] = 0
    image = Image.frombytes("RGBA", image.size, bytes(pixels))
    if reference["flags"] & 0x80000000:
        image = image.transpose(Image.Transpose.FLIP_LEFT_RIGHT)
    if reference["flags"] & 0x40000000:
        image = image.transpose(Image.Transpose.FLIP_TOP_BOTTOM)
    return image


def _coordinate_id(value: int) -> str:
    return f"m{-value}" if value < 0 else str(value)


def _extract_map(tiled_root: Path, filename: str, family: str, label: str) -> list[dict]:
    map_path = tiled_root / "Maps" / filename
    if not map_path.is_file():
        return []
    root = ET.parse(map_path).getroot()
    if root.get("orientation") != "orthogonal" or root.findall("group"):
        raise ValueError(f"Unsupported map layout in {map_path}")
    tile_width, tile_height = int(root.attrib["tilewidth"]), int(root.attrib["tileheight"])
    if (tile_width, tile_height) != (32, 32):
        raise ValueError(f"Expected native 32 px cells in {map_path}")
    layers = [(layer, _layer_cells(layer)) for layer in root.findall("layer")]
    region_cells = set().union(*(set(cells) for layer, cells in layers if layer.get("name", "").startswith("regions_")))
    input_mask = set().union(*(set(cells) for layer, cells in layers if layer.get("name", "").startswith("input_")))
    authored_regions = bool(region_cells)
    if not authored_regions:
        region_cells = set().union(*(set(cells) for layer, cells in layers))
    regions = _components(region_cells)
    input_groups = _components(input_mask)
    tilesets = _tilesets(root, map_path, tiled_root)
    unassigned_cells = []
    if authored_regions:
        for layer, cells in layers:
            name = layer.get("name", "")
            if not name.startswith("output_") or name == "output_passages":
                continue
            for (x, y), gid in sorted(cells.items(), key=lambda item: (item[0][1], item[0][0])):
                if (x, y) not in region_cells:
                    _, reference = _tile_reference(gid, tilesets)
                    unassigned_cells.append({**reference, "mapX": x, "mapY": y, "layer": name})
    tile_cache = {}
    results = []
    for region in regions:
        x0, y0 = min(x for x, y in region), min(y for x, y in region)
        width = max(x for x, y in region) - x0 + 1
        height = max(y for x, y in region) - y0 + 1
        image = Image.new("RGBA", (width * tile_width, height * tile_height))
        source_cells, input_cells, passage_cells, marker_cells, missing_cells = [], [], [], [], []
        input_group_count = sum(bool(group & region) for group in input_groups)
        notes = ["Libellé de classement initial ; identité visuelle à revoir."]
        confidence = "high" if authored_regions and input_group_count == 1 else "medium"
        if not authored_regions:
            notes.append("Pas de masque regions_* ; regroupement des cellules contiguës de la règle, à revoir.")
        if input_group_count != 1:
            confidence = "low"
            notes.append(f"Association ambiguë : {input_group_count} groupes de cellules d'entrée.")
        for layer, cells in layers:
            name = layer.get("name", "")
            if name == "regions_input":
                marker_cells.extend({"x": x - x0, "y": y - y0} for x, y in sorted(set(cells) & region, key=lambda point: (point[1], point[0])))
            if not name.startswith(("input_", "output_")):
                continue
            is_input = name.startswith("input_")
            is_passage = name == "output_passages"
            is_visual = not is_passage and not (is_input and family == "buildings")
            opacity = float(layer.get("opacity", "1"))
            for (x, y), gid in sorted(cells.items(), key=lambda item: (item[0][1], item[0][0])):
                if (x, y) not in region:
                    continue
                tileset, reference = _tile_reference(gid, tilesets)
                cell = {**reference, "x": x - x0, "y": y - y0, "layer": name}
                if is_input:
                    input_cells.append(cell.copy())
                if is_passage:
                    passage_cells.append(cell.copy())
                if not is_visual:
                    continue
                if (tileset["width"], tileset["height"]) != (tile_width, tile_height):
                    raise ValueError(f"Mismatched source cell dimensions in {map_path}")
                source_cells.append(cell)
                if gid not in tile_cache:
                    try:
                        tile_cache[gid] = _tile_image(tileset, reference)
                    except ValueError as error:
                        missing_cells.append({**cell, "reason": str(error)})
                        continue
                tile = tile_cache[gid]
                if opacity != 1:
                    tile = tile.copy()
                    tile.putalpha(tile.getchannel("A").point(lambda value: round(value * opacity)))
                image.alpha_composite(tile, ((x - x0) * tile_width, (y - y0) * tile_height))
        if not source_cells:
            continue
        if family == "buildings":
            notes.append("Marqueur input de bâtiment exclu de l'image ; tous les fragments output sont assemblés.")
        else:
            notes.append("Les cellules input visibles sont conservées : elles constituent le bas du motif.")
        if passage_cells:
            notes.append("Masque output_passages conservé brut ; sa sémantique de collision n'est pas documentée par le TSX.")
        for tileset in tilesets:
            if not any(cell["source"] == tileset["source"] for cell in source_cells):
                continue
            image_columns = (tileset["image"].width - 2 * tileset["margin"] + tileset["spacing"]) // (tileset["width"] + tileset["spacing"])
            image_rows = (tileset["image"].height - 2 * tileset["margin"] + tileset["spacing"]) // (tileset["height"] + tileset["spacing"])
            if image_columns * image_rows != tileset["tilecount"]:
                notes.append(f"Métadonnées incohérentes : {tileset['source']} contient {image_columns * image_rows} cellules, mais son TSX en déclare {tileset['tilecount']}.")
        if missing_cells:
            confidence = "low"
            notes.append(f"Patron incomplet et inutilisable en l'état : {len(missing_cells)} cellules source sont introuvables ; les zones manquantes restent transparentes.")
        anchor = None
        if len(marker_cells) == 1:
            anchor = {**marker_cells[0], "basis": "regions_input", "kind": "rule_input_marker"}
        else:
            notes.append("Aucun point d'ancrage unique déclaré ; consulter inputCells sans déduire un point au sol.")
        results.append({
            "id": f"psdk_{map_path.stem}_{_coordinate_id(x0)}_{_coordinate_id(y0)}",
            "label": f"{label} — motif {len(results) + 1:03d} ({width} × {height} cases)",
            "family": family,
            "kind": "assembled",
            "image": image,
            "ruleMap": map_path.relative_to(tiled_root).as_posix(),
            "ruleRect": {"x": x0 * tile_width, "y": y0 * tile_height, "width": width * tile_width, "height": height * tile_height},
            "tileSizePx": tile_width,
            "inputCells": input_cells,
            "anchor": anchor,
            "inputRegionCells": marker_cells,
            "sourceCells": source_cells,
            "missingSourceCells": missing_cells,
            "mapUnassignedCells": [],
            "status": "incomplete_source" if missing_cells else "assembled",
            "collisionCells": None,
            "passageCells": passage_cells,
            "confidence": confidence,
            "confidenceScope": "rule_geometry",
            "notes": notes,
        })
    if results:
        results[0]["mapUnassignedCells"] = unassigned_cells
    return results


def extract_rules(tiled_root: str | Path) -> list[dict]:
    tiled_root = Path(tiled_root).expanduser().resolve()
    if not (tiled_root / "Maps").is_dir() or not (tiled_root / "Tilesets").is_dir():
        raise ValueError(f"Expected a Data/Tiled root with Maps and Tilesets: {tiled_root}")
    result = []
    for filename, family, label in RULE_MAPS:
        result.extend(_extract_map(tiled_root, filename, family, label))
    return result
