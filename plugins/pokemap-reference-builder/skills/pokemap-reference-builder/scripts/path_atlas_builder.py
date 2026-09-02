from __future__ import annotations

import argparse
import json
import xml.etree.ElementTree as ET
from colorsys import hsv_to_rgb, rgb_to_hsv
from pathlib import Path

from PIL import Image, ImageChops, ImageEnhance, ImageFilter
from PIL.PngImagePlugin import PngInfo


TILE_SIZE = 32
MASK_COUNT = 16


def parse_tile_ids(value: str) -> list[int]:
    tile_ids = [int(part.strip()) for part in value.split(",") if part.strip()]
    if not tile_ids:
        raise argparse.ArgumentTypeError("At least one tile id is required")
    return tile_ids


def crop_tile(atlas: Image.Image, columns: int, tile_id: int) -> Image.Image:
    x = tile_id % columns * TILE_SIZE
    y = tile_id // columns * TILE_SIZE
    if x + TILE_SIZE > atlas.width or y + TILE_SIZE > atlas.height:
        raise ValueError(f"Tile {tile_id} is outside the source atlas")
    return atlas.crop((x, y, x + TILE_SIZE, y + TILE_SIZE)).convert("RGBA")


def paste_tile(atlas: Image.Image, columns: int, tile_id: int, tile: Image.Image) -> None:
    x = tile_id % columns * TILE_SIZE
    y = tile_id // columns * TILE_SIZE
    atlas.alpha_composite(tile, (x, y))


def connected(mask: int, bit: int) -> bool:
    return mask & bit != 0


def path_shape(mask: int, variant: int) -> list[list[bool]]:
    inset = 7
    high = TILE_SIZE - inset - 1
    shape = [[False for _ in range(TILE_SIZE)] for _ in range(TILE_SIZE)]
    for y in range(TILE_SIZE):
        for x in range(TILE_SIZE):
            inside = inset <= x <= high and inset <= y <= high
            inside = inside or connected(mask, 1) and inset <= x <= high and y <= high
            inside = inside or connected(mask, 2) and x >= inset and inset <= y <= high
            inside = inside or connected(mask, 4) and inset <= x <= high and y >= inset
            inside = inside or connected(mask, 8) and x <= high and inset <= y <= high
            inside = inside or connected(mask, 1) and connected(mask, 2) and x >= inset and y <= high
            inside = inside or connected(mask, 2) and connected(mask, 4) and x >= inset and y >= inset
            inside = inside or connected(mask, 4) and connected(mask, 8) and x <= high and y >= inset
            inside = inside or connected(mask, 8) and connected(mask, 1) and x <= high and y <= high
            if inside and not (mask == 15):
                noise = ((x * 17 + y * 29 + mask * 13 + variant * 31) % 23) - 11
                near_vertical_edge = x in (inset, high)
                near_horizontal_edge = y in (inset, high)
                if noise > 8 and (near_vertical_edge or near_horizontal_edge):
                    inside = False
            shape[y][x] = inside
    return shape


def has_outside_neighbour(shape: list[list[bool]], x: int, y: int) -> bool:
    for dx, dy in ((0, -1), (1, 0), (0, 1), (-1, 0)):
        nx = x + dx
        ny = y + dy
        if nx < 0 or nx >= TILE_SIZE or ny < 0 or ny >= TILE_SIZE or not shape[ny][nx]:
            return True
    return False


def has_inside_neighbour(shape: list[list[bool]], x: int, y: int) -> bool:
    for dx, dy in ((0, -1), (1, 0), (0, 1), (-1, 0)):
        nx = x + dx
        ny = y + dy
        if 0 <= nx < TILE_SIZE and 0 <= ny < TILE_SIZE and shape[ny][nx]:
            return True
    return False


def build_ground_tile(texture: Image.Image, mask: int, variant: int) -> Image.Image:
    shape = path_shape(mask, variant)
    output = Image.new("RGBA", (TILE_SIZE, TILE_SIZE))
    source = texture.load()
    target = output.load()
    shift_x = variant * 7 % TILE_SIZE
    shift_y = variant * 11 % TILE_SIZE
    for y in range(TILE_SIZE):
        for x in range(TILE_SIZE):
            if shape[y][x]:
                red, green, blue, alpha = source[(x + shift_x) % TILE_SIZE, (y + shift_y) % TILE_SIZE]
                if has_outside_neighbour(shape, x, y):
                    red = max(0, red - 35)
                    green = max(0, green - 30)
                    blue = max(0, blue - 18)
                target[x, y] = red, green, blue, alpha
            elif has_inside_neighbour(shape, x, y) and (x * 5 + y * 7 + mask + variant) % 4 != 0:
                grass = ((70, 133, 38), (84, 148, 43), (99, 153, 49))[(x + y + variant) % 3]
                target[x, y] = *grass, 215
    return output


def wang_id(mask: int) -> str:
    return ",".join(
        str(value)
        for value in (
            1 if connected(mask, 1) else 0,
            0,
            1 if connected(mask, 2) else 0,
            0,
            1 if connected(mask, 4) else 0,
            0,
            1 if connected(mask, 8) else 0,
            0,
        )
    )


def corner_wang_id(mask: int) -> str:
    return ",".join(
        str(value)
        for value in (
            0,
            1 if connected(mask, 1) else 0,
            0,
            1 if connected(mask, 2) else 0,
            0,
            1 if connected(mask, 4) else 0,
            0,
            1 if connected(mask, 8) else 0,
        )
    )


def animation_frames(tsx_path: Path, base_tile_id: int, frame_count: int) -> list[int]:
    root = ET.parse(tsx_path).getroot()
    tile = next((candidate for candidate in root.findall("tile") if int(candidate.attrib["id"]) == base_tile_id), None)
    if tile is None or tile.find("animation") is None:
        raise ValueError(f"Tile {base_tile_id} has no animation in {tsx_path}")
    source_frames = [int(frame.attrib["tileid"]) for frame in tile.find("animation")]
    if len(source_frames) < frame_count:
        raise ValueError(f"Tile {base_tile_id} exposes only {len(source_frames)} frames")
    indexes = [round(index * (len(source_frames) - 1) / max(1, frame_count - 1)) for index in range(frame_count)]
    return [source_frames[index] for index in indexes]


def build_ground(args: argparse.Namespace) -> tuple[int, int, int]:
    source = Image.open(args.source_atlas).convert("RGBA")
    correction = Image.open(args.correction_overlay).convert("RGBA") if args.correction_overlay else None
    variants = [crop_tile(source, args.source_columns, tile_id) for tile_id in args.texture_tile_ids]
    tile_count = len(variants) * MASK_COUNT
    columns = 8
    rows = (tile_count + columns - 1) // columns
    atlas = Image.new("RGBA", (columns * TILE_SIZE, rows * TILE_SIZE))
    for variant, texture in enumerate(variants):
        for mask in range(MASK_COUNT):
            tile_id = variant * MASK_COUNT + mask
            tile = build_ground_tile(texture, mask, variant)
            if correction is not None:
                tile.alpha_composite(crop_tile(correction, 4, mask))
            paste_tile(atlas, columns, tile_id, tile)
    atlas.save(args.output_png, optimize=True)
    write_tsx(
        output_path=args.output_tsx,
        image_name=args.output_png.name,
        name=args.name,
        columns=columns,
        rows=rows,
        variants=len(variants),
        frame_count=1,
        frame_duration_ms=args.frame_duration_ms,
    )
    return columns, rows, tile_count


def build_grass_fill(args: argparse.Namespace) -> tuple[int, int, int]:
    source = Image.open(args.source_atlas).convert("RGBA")
    variants = []
    for variant, tile_id in enumerate(args.texture_tile_ids):
        texture = crop_tile(source, args.source_columns, tile_id)
        if not getattr(args, "source_seamless", False):
            texture = make_seamless_texture(texture)
        if getattr(args, "shift_variants", False):
            texture = ImageChops.offset(texture, variant * 7 % TILE_SIZE, variant * 11 % TILE_SIZE)
        texture = ImageEnhance.Contrast(texture).enhance(getattr(args, "texture_contrast", 1.0))
        pixels = texture.load()
        hue_shift = getattr(args, "hue_shift_degrees", 0.0) / 360.0
        saturation_factor = getattr(args, "texture_saturation", 1.0)
        brightness_factor = getattr(args, "texture_brightness", 1.0)
        for y in range(TILE_SIZE):
            for x in range(TILE_SIZE):
                red, green, blue, alpha = pixels[x, y]
                hue, saturation, value = rgb_to_hsv(red / 255, green / 255, blue / 255)
                changed = hsv_to_rgb(
                    (hue + hue_shift) % 1.0,
                    max(0.0, min(1.0, saturation * saturation_factor)),
                    max(0.0, min(1.0, value * brightness_factor)),
                )
                pixels[x, y] = tuple(round(channel * 255) for channel in changed) + (alpha,)
        variants.append(texture)
    tile_count = len(variants) * MASK_COUNT
    columns = 8
    rows = (tile_count + columns - 1) // columns
    atlas = Image.new("RGBA", (columns * TILE_SIZE, rows * TILE_SIZE))
    for variant, texture in enumerate(variants):
        for mask in range(1, MASK_COUNT):
            tile = Image.new("RGBA", (TILE_SIZE, TILE_SIZE))
            source_pixels = texture.load()
            target_pixels = tile.load()
            for y in range(TILE_SIZE):
                for x in range(TILE_SIZE):
                    bit = 8 if x < TILE_SIZE // 2 and y < TILE_SIZE // 2 else 1 if y < TILE_SIZE // 2 else 4 if x < TILE_SIZE // 2 else 2
                    if connected(mask, bit):
                        target_pixels[x, y] = source_pixels[x, y]
            paste_tile(atlas, columns, variant * MASK_COUNT + mask, tile)
    atlas.save(args.output_png, optimize=True)
    write_tsx(
        output_path=args.output_tsx,
        image_name=args.output_png.name,
        name=args.name,
        columns=columns,
        rows=rows,
        variants=len(variants),
        frame_count=1,
        frame_duration_ms=args.frame_duration_ms,
        wang_type="corner",
    )
    return columns, rows, tile_count


def build_sampled_ground(args: argparse.Namespace) -> tuple[int, int, int]:
    render = Image.open(args.render).convert("RGBA")
    map_data = json.loads(args.map_json.read_text(encoding="utf-8"))
    layer = next((candidate for candidate in map_data["layers"] if candidate["id"] == args.layer_id), None)
    if layer is None or layer.get("runtimeType") != "smart_tile":
        raise ValueError(f"Smart Tile layer {args.layer_id} is missing")
    width = map_data["size"]["width"]
    height = map_data["size"]["height"]
    if render.size != (width * TILE_SIZE, height * TILE_SIZE):
        raise ValueError(f"Expected a {width * TILE_SIZE}x{height * TILE_SIZE} source render")
    if getattr(args, "derive_from_all_corners", False):
        corners = layer["field"].get("corners")
        if corners is None:
            raise ValueError(f"Smart Tile layer {args.layer_id} has no corner lattice")
        stride = width + 1
        occupied = {
            (x, y)
            for y in range(height)
            for x in range(width)
            if all(
                corners[index] != 0
                for index in (
                    y * stride + x,
                    y * stride + x + 1,
                    (y + 1) * stride + x,
                    (y + 1) * stride + x + 1,
                )
            )
        }
    elif getattr(args, "derive_from_render", False):
        minimum_coverage = getattr(args, "minimum_path_coverage", 0.18)
        minimum_red = getattr(args, "minimum_path_red", 145)
        red_over_green = getattr(args, "path_red_over_green", 18)
        green_over_blue = getattr(args, "path_green_over_blue", 35)
        occupied = set()
        for y in range(height):
            for x in range(width):
                tile = render.crop((x * TILE_SIZE, y * TILE_SIZE, (x + 1) * TILE_SIZE, (y + 1) * TILE_SIZE))
                pixels = tile.get_flattened_data() if hasattr(tile, "get_flattened_data") else tile.getdata()
                path_pixels = sum(
                    1
                    for red, green, blue, alpha in pixels
                    if alpha > 0
                    and red >= minimum_red
                    and red - green >= red_over_green
                    and green - blue >= green_over_blue
                )
                if path_pixels / (TILE_SIZE * TILE_SIZE) >= minimum_coverage:
                    occupied.add((x, y))
    else:
        occupied = {
            (index % width, index // width)
            for index, value in enumerate(layer["field"]["semanticCells"])
            if value != 0
        }
    output_cells_json = getattr(args, "output_cells_json", None)
    if output_cells_json is not None:
        output_cells_json.parent.mkdir(parents=True, exist_ok=True)
        output_cells_json.write_text(
            json.dumps(
                {
                    "width": width,
                    "height": height,
                    "cells": [{"x": x, "y": y} for x, y in sorted(occupied, key=lambda cell: (cell[1], cell[0]))],
                },
                indent=2,
            )
            + "\n",
            encoding="utf-8",
        )
    by_mask: dict[int, list[tuple[int, int]]] = {mask: [] for mask in range(MASK_COUNT)}
    if getattr(args, "edge_field_projection", False):
        for y in range(height):
            for x in range(width):
                mask = (
                    (1 if (x, y) in occupied or (x, y - 1) in occupied else 0)
                    + (2 if (x, y) in occupied or (x + 1, y) in occupied else 0)
                    + (4 if (x, y) in occupied or (x, y + 1) in occupied else 0)
                    + (8 if (x, y) in occupied or (x - 1, y) in occupied else 0)
                )
                by_mask[mask].append((x, y))
    else:
        for x, y in occupied:
            mask = (
                (1 if (x, y - 1) in occupied else 0)
                + (2 if (x + 1, y) in occupied else 0)
                + (4 if (x, y + 1) in occupied else 0)
                + (8 if (x - 1, y) in occupied else 0)
            )
            by_mask[mask].append((x, y))
    background = render.crop((0, 0, TILE_SIZE, TILE_SIZE))
    tile_count = args.variants * MASK_COUNT
    columns = 8
    rows = (tile_count + columns - 1) // columns
    atlas = Image.new("RGBA", (columns * TILE_SIZE, rows * TILE_SIZE))
    for mask in range(MASK_COUNT):
        candidates = sorted(
            by_mask[mask],
            key=lambda cell: (
                min(cell[0], width - 1 - cell[0], cell[1], height - 1 - cell[1]),
                (cell[0] * 37 + cell[1] * 53 + mask * 71) % 997,
            ),
            reverse=True,
        )
        for variant in range(args.variants):
            tile_id = variant * MASK_COUNT + mask
            if candidates:
                index = round(variant * (len(candidates) - 1) / max(1, args.variants - 1))
                x, y = candidates[index]
                tile = render.crop((x * TILE_SIZE, y * TILE_SIZE, (x + 1) * TILE_SIZE, (y + 1) * TILE_SIZE))
            else:
                source_candidates = by_mask[1] or by_mask[2] or by_mask[4] or by_mask[8]
                if not source_candidates:
                    raise ValueError("The source path exposes no terminal tile")
                x, y = source_candidates[variant % len(source_candidates)]
                source = render.crop((x * TILE_SIZE, y * TILE_SIZE, (x + 1) * TILE_SIZE, (y + 1) * TILE_SIZE))
                tile = background.copy()
                tile.alpha_composite(source.crop((8, 8, 24, 24)), (8, 8))
            paste_tile(atlas, columns, tile_id, tile)
    atlas.save(args.output_png, optimize=True)
    write_tsx(
        output_path=args.output_tsx,
        image_name=args.output_png.name,
        name=args.name,
        columns=columns,
        rows=rows,
        variants=args.variants,
        frame_count=1,
        frame_duration_ms=args.frame_duration_ms,
    )
    return columns, rows, tile_count


def build_sampled_corner(args: argparse.Namespace) -> tuple[int, int, int]:
    render = Image.open(args.render).convert("RGBA")
    map_data = json.loads(args.map_json.read_text(encoding="utf-8"))
    layer = next((candidate for candidate in map_data["layers"] if candidate["id"] == args.layer_id), None)
    if layer is None or layer.get("runtimeType") != "smart_tile" or layer.get("field", {}).get("kind") != "corner":
        raise ValueError(f"Corner Smart Tile layer {args.layer_id} is missing")
    width = map_data["size"]["width"]
    height = map_data["size"]["height"]
    if render.size != (width * TILE_SIZE, height * TILE_SIZE):
        raise ValueError(f"Expected a {width * TILE_SIZE}x{height * TILE_SIZE} source render")
    corners = layer["field"]["corners"]
    stride = width + 1
    by_mask: dict[int, list[tuple[int, int]]] = {mask: [] for mask in range(1, MASK_COUNT)}
    for y in range(height):
        for x in range(width):
            mask = (
                (1 if corners[y * stride + x + 1] else 0)
                + (2 if corners[(y + 1) * stride + x + 1] else 0)
                + (4 if corners[(y + 1) * stride + x] else 0)
                + (8 if corners[y * stride + x] else 0)
            )
            if mask != 0:
                by_mask[mask].append((x, y))
    tile_count = args.variants * MASK_COUNT
    columns = 8
    rows = (tile_count + columns - 1) // columns
    atlas = Image.new("RGBA", (columns * TILE_SIZE, rows * TILE_SIZE))
    for mask, cells in by_mask.items():
        if not cells:
            source_mask = min(
                (candidate_mask for candidate_mask, candidate_cells in by_mask.items() if candidate_cells),
                key=lambda candidate_mask: (mask ^ candidate_mask).bit_count(),
            )
            cells = by_mask[source_mask]
        candidates = sorted(
            cells,
            key=lambda cell: (
                min(cell[0], width - 1 - cell[0], cell[1], height - 1 - cell[1]),
                (cell[0] * 37 + cell[1] * 53 + mask * 71) % 997,
            ),
            reverse=True,
        )
        for variant in range(args.variants):
            index = round(variant * (len(candidates) - 1) / max(1, args.variants - 1))
            x, y = candidates[index]
            tile = render.crop((x * TILE_SIZE, y * TILE_SIZE, (x + 1) * TILE_SIZE, (y + 1) * TILE_SIZE))
            paste_tile(atlas, columns, variant * MASK_COUNT + mask, tile)
    atlas.save(args.output_png, optimize=True)
    write_tsx(
        output_path=args.output_tsx,
        image_name=args.output_png.name,
        name=args.name,
        columns=columns,
        rows=rows,
        variants=args.variants,
        frame_count=1,
        frame_duration_ms=args.frame_duration_ms,
        wang_type="corner",
    )
    return columns, rows, tile_count


def is_water_pixel(pixel: tuple[int, int, int, int]) -> bool:
    red, green, blue, alpha = pixel
    return alpha > 0 and red < 130 and green > 70 and blue > 60 and blue >= red - 15


def animate_water_tile(tile: Image.Image, frame_index: int) -> Image.Image:
    if frame_index == 0:
        return tile.copy()
    shifts = ((0, 0), (1, 0), (1, 1), (0, 1))
    shift_x, shift_y = shifts[frame_index % len(shifts)]
    source = tile.load()
    output = tile.copy()
    target = output.load()
    for y in range(TILE_SIZE):
        for x in range(TILE_SIZE):
            destination = source[x, y]
            if not is_water_pixel(destination):
                continue
            sampled = source[(x + shift_x) % TILE_SIZE, (y + shift_y) % TILE_SIZE]
            if is_water_pixel(sampled):
                target[x, y] = sampled[0], sampled[1], sampled[2], destination[3]
    return output


def has_non_water_neighbour(tile: Image.Image, x: int, y: int, radius: int = 2) -> bool:
    pixels = tile.load()
    for offset_y in range(-radius, radius + 1):
        for offset_x in range(-radius, radius + 1):
            neighbour_x = x + offset_x
            neighbour_y = y + offset_y
            if not (0 <= neighbour_x < TILE_SIZE and 0 <= neighbour_y < TILE_SIZE):
                continue
            if not is_water_pixel(pixels[neighbour_x, neighbour_y]):
                return True
    return False


def apply_water_shoreline(tile: Image.Image, mask: int | None = None) -> Image.Image:
    if mask == MASK_COUNT - 1:
        return tile.copy()
    source = tile.load()
    output = tile.copy()
    target = output.load()
    raw_water = [[is_water_pixel(source[x, y]) for x in range(TILE_SIZE)] for y in range(TILE_SIZE)]
    water_shape = [[False for _ in range(TILE_SIZE)] for _ in range(TILE_SIZE)]
    radius = 2
    for y in range(TILE_SIZE):
        for x in range(TILE_SIZE):
            neighbours = [
                raw_water[neighbour_y][neighbour_x]
                for neighbour_y in range(max(0, y - radius), min(TILE_SIZE, y + radius + 1))
                for neighbour_x in range(max(0, x - radius), min(TILE_SIZE, x + radius + 1))
            ]
            water_shape[y][x] = sum(neighbours) / len(neighbours) >= 0.58
    for y in range(TILE_SIZE):
        for x in range(TILE_SIZE):
            if not raw_water[y][x] or not water_shape[y][x]:
                continue
            neighbours = (
                (x, y - 1),
                (x + 1, y),
                (x, y + 1),
                (x - 1, y),
            )
            if any(
                0 <= neighbour_x < TILE_SIZE
                and 0 <= neighbour_y < TILE_SIZE
                and not water_shape[neighbour_y][neighbour_x]
                for neighbour_x, neighbour_y in neighbours
            ):
                target[x, y] = (112, 104, 56, source[x, y][3])
    return output


def apply_seamless_water_texture(tile: Image.Image, texture: Image.Image) -> Image.Image:
    output = tile.copy()
    source = tile.load()
    water = texture.load()
    target = output.load()
    for y in range(TILE_SIZE):
        for x in range(TILE_SIZE):
            destination = source[x, y]
            if is_water_pixel(destination) and not has_non_water_neighbour(tile, x, y):
                sampled = water[x, y]
                target[x, y] = sampled[0], sampled[1], sampled[2], destination[3]
    return output


def make_seamless_texture(atlas: Image.Image) -> Image.Image:
    texture = atlas.resize((TILE_SIZE, TILE_SIZE), Image.Resampling.LANCZOS).convert("RGBA")
    pixels = texture.load()
    border = 4
    for y in range(TILE_SIZE):
        left = pixels[0, y]
        right = pixels[TILE_SIZE - 1, y]
        average = tuple(round((left[index] + right[index]) / 2) for index in range(4))
        for offset in range(border):
            weight = (border - offset) / border
            for x in (offset, TILE_SIZE - 1 - offset):
                current = pixels[x, y]
                pixels[x, y] = tuple(round(current[index] * (1 - weight) + average[index] * weight) for index in range(4))
    for x in range(TILE_SIZE):
        top = pixels[x, 0]
        bottom = pixels[x, TILE_SIZE - 1]
        average = tuple(round((top[index] + bottom[index]) / 2) for index in range(4))
        for offset in range(border):
            weight = (border - offset) / border
            for y in (offset, TILE_SIZE - 1 - offset):
                current = pixels[x, y]
                pixels[x, y] = tuple(round(current[index] * (1 - weight) + average[index] * weight) for index in range(4))
    return texture


def build_sampled_corner_animated(args: argparse.Namespace) -> tuple[int, int, int]:
    columns, _, base_count = build_sampled_corner(args)
    base_atlas = Image.open(args.output_png).convert("RGBA")
    texture_atlas = Image.open(args.water_texture_atlas).convert("RGBA")
    water_texture = make_seamless_texture(texture_atlas) if args.water_texture_use_full_atlas else crop_tile(
        texture_atlas,
        args.water_texture_columns,
        args.water_texture_tile_id,
    )
    tile_count = base_count * args.frame_count
    rows = (tile_count + columns - 1) // columns
    atlas = Image.new("RGBA", (columns * TILE_SIZE, rows * TILE_SIZE))
    for frame_index in range(args.frame_count):
        frame_texture = animate_water_tile(water_texture, frame_index)
        for tile_id in range(base_count):
            tile = crop_tile(base_atlas, columns, tile_id)
            if getattr(args, "water_shoreline", False):
                tile = apply_water_shoreline(tile, tile_id % MASK_COUNT)
            paste_tile(
                atlas,
                columns,
                frame_index * base_count + tile_id,
                apply_seamless_water_texture(tile, frame_texture),
            )
    atlas.save(args.output_png, optimize=True)
    write_tsx(
        output_path=args.output_tsx,
        image_name=args.output_png.name,
        name=args.name,
        columns=columns,
        rows=rows,
        variants=args.variants,
        frame_count=args.frame_count,
        frame_duration_ms=args.frame_duration_ms,
        wang_type="corner",
    )
    return columns, rows, tile_count


def build_water(args: argparse.Namespace) -> tuple[int, int, int]:
    source = Image.open(args.source_atlas).convert("RGBA")
    bank = Image.open(args.bank_overlay).convert("RGBA") if args.bank_overlay else None
    tone = Image.open(args.tone_overlay).convert("RGBA") if args.tone_overlay else None
    frame_sets = [animation_frames(args.source_tsx, tile_id, args.frame_count) for tile_id in args.base_tile_ids]
    variants = len(frame_sets)
    base_count = variants * MASK_COUNT
    tile_count = base_count * args.frame_count
    columns = 8
    rows = (tile_count + columns - 1) // columns
    atlas = Image.new("RGBA", (columns * TILE_SIZE, rows * TILE_SIZE))
    for frame_index in range(args.frame_count):
        for variant, frame_ids in enumerate(frame_sets):
            water = crop_tile(source, args.source_columns, frame_ids[frame_index])
            for mask in range(MASK_COUNT):
                tile_id = frame_index * base_count + variant * MASK_COUNT + mask
                tile = water.copy()
                if bank is not None:
                    tile.alpha_composite(crop_tile(bank, 4, mask))
                if tone is not None:
                    tile.alpha_composite(crop_tile(tone, 4, mask))
                paste_tile(atlas, columns, tile_id, tile)
    atlas.save(args.output_png, optimize=True)
    write_tsx(
        output_path=args.output_tsx,
        image_name=args.output_png.name,
        name=args.name,
        columns=columns,
        rows=rows,
        variants=variants,
        frame_count=args.frame_count,
        frame_duration_ms=args.frame_duration_ms,
    )
    return columns, rows, tile_count


def build_bank(args: argparse.Namespace) -> tuple[int, int, int]:
    bank = Image.open(args.bank_overlay).convert("RGBA")
    tone = Image.open(args.tone_overlay).convert("RGBA") if args.tone_overlay else None
    columns = 8
    rows = 2
    atlas = Image.new("RGBA", (columns * TILE_SIZE, rows * TILE_SIZE))
    for mask in range(MASK_COUNT):
        tile = crop_tile(bank, 4, mask)
        if tone is not None:
            tile.alpha_composite(crop_tile(tone, 4, mask))
        paste_tile(atlas, columns, mask, tile)
    atlas.save(args.output_png, optimize=True)
    write_tsx(
        output_path=args.output_tsx,
        image_name=args.output_png.name,
        name=args.name,
        columns=columns,
        rows=rows,
        variants=1,
        frame_count=1,
        frame_duration_ms=args.frame_duration_ms,
    )
    return columns, rows, MASK_COUNT


def adapt_erw_water_pixel(
    pixel: tuple[int, int, int, int],
    target_hue: float | None = None,
    saturation_factor: float = 1.0,
    minimum_saturation: float = 0.0,
    maximum_saturation: float = 1.0,
    brightness_factor: float = 1.0,
) -> tuple[int, int, int, int]:
    red, green, blue, alpha = pixel
    if alpha == 0:
        return pixel
    hue, saturation, value = rgb_to_hsv(red / 255, green / 255, blue / 255)
    if 0.47 <= hue <= 0.62 and saturation >= 0.18:
        if target_hue is not None:
            saturation = max(minimum_saturation, min(maximum_saturation, saturation * saturation_factor))
            value = max(0.0, min(1.0, value * brightness_factor))
            changed = hsv_to_rgb(target_hue, saturation, value)
            return tuple(round(channel * 255) for channel in changed) + (alpha,)
        blue = round(red + (blue - red) * 0.64)
        return red, green, max(0, min(255, blue)), alpha
    if 0.05 <= hue <= 0.18 and saturation >= 0.15:
        hue = 0.12
        saturation = max(0.58, saturation)
        value *= 0.85
        changed = hsv_to_rgb(hue, saturation, value)
        return tuple(round(channel * 255) for channel in changed) + (alpha,)
    return pixel


def is_erw_water_pixel(pixel: tuple[int, int, int, int]) -> bool:
    red, green, blue, alpha = pixel
    if alpha == 0:
        return False
    hue, saturation, _ = rgb_to_hsv(red / 255, green / 255, blue / 255)
    return 0.47 <= hue <= 0.62 and saturation >= 0.18


def expanded_erw_water_mask(image: Image.Image, radius: int) -> Image.Image:
    mask = Image.new("L", image.size)
    source = image.load()
    pixels = mask.load()
    for y in range(image.height):
        for x in range(image.width):
            if is_erw_water_pixel(source[x, y]):
                pixels[x, y] = 255
    if radius <= 0:
        return mask
    expanded = Image.new("L", image.size)
    for tile_top in range(0, image.height, TILE_SIZE):
        for tile_left in range(0, image.width, TILE_SIZE):
            box = (
                tile_left,
                tile_top,
                min(image.width, tile_left + TILE_SIZE),
                min(image.height, tile_top + TILE_SIZE),
            )
            expanded.paste(mask.crop(box).filter(ImageFilter.MaxFilter(radius * 2 + 1)), box[:2])
    return expanded


def adjust_texture_hsv(
    image: Image.Image,
    hue_shift_degrees: float,
    saturation_factor: float,
    brightness_factor: float,
) -> Image.Image:
    result = image.copy()
    pixels = result.load()
    hue_shift = hue_shift_degrees / 360.0
    for y in range(result.height):
        for x in range(result.width):
            red, green, blue, alpha = pixels[x, y]
            hue, saturation, value = rgb_to_hsv(red / 255, green / 255, blue / 255)
            changed = hsv_to_rgb(
                (hue + hue_shift) % 1.0,
                max(0.0, min(1.0, saturation * saturation_factor)),
                max(0.0, min(1.0, value * brightness_factor)),
            )
            pixels[x, y] = tuple(round(channel * 255) for channel in changed) + (alpha,)
    return result


def apply_erw_water_inner_shadow(
    image: Image.Image,
    source: Image.Image,
    radius: int,
    strength: float,
) -> Image.Image:
    if radius <= 0 or strength <= 0:
        return image
    result = image.copy()
    source_pixels = source.load()
    target_pixels = result.load()
    for y in range(image.height):
        tile_top = y // TILE_SIZE * TILE_SIZE
        tile_bottom = min(image.height, tile_top + TILE_SIZE)
        for x in range(image.width):
            if not is_erw_water_pixel(source_pixels[x, y]):
                continue
            tile_left = x // TILE_SIZE * TILE_SIZE
            tile_right = min(image.width, tile_left + TILE_SIZE)
            distance = None
            for current_distance in range(1, radius + 1):
                found = False
                for offset_y in range(-current_distance, current_distance + 1):
                    for offset_x in range(-current_distance, current_distance + 1):
                        if max(abs(offset_x), abs(offset_y)) != current_distance:
                            continue
                        neighbour_x = x + offset_x
                        neighbour_y = y + offset_y
                        if not (tile_left <= neighbour_x < tile_right and tile_top <= neighbour_y < tile_bottom):
                            continue
                        if not is_erw_water_pixel(source_pixels[neighbour_x, neighbour_y]):
                            distance = current_distance
                            found = True
                            break
                    if found:
                        break
                if found:
                    break
            if distance is None:
                continue
            factor = 1.0 - strength * (radius - distance + 1) / radius
            red, green, blue, alpha = target_pixels[x, y]
            target_pixels[x, y] = round(red * factor), round(green * factor), round(blue * factor), alpha
    return result


def apply_erw_water_inner_highlight(
    image: Image.Image,
    mask: Image.Image,
    radius: int,
    strength: float,
) -> Image.Image:
    if radius <= 0 or strength <= 0:
        return image
    result = image.copy()
    mask_pixels = mask.load()
    target_pixels = result.load()
    for y in range(image.height):
        tile_top = y // TILE_SIZE * TILE_SIZE
        tile_bottom = min(image.height, tile_top + TILE_SIZE)
        for x in range(image.width):
            if not is_erw_water_pixel(mask_pixels[x, y]):
                continue
            tile_left = x // TILE_SIZE * TILE_SIZE
            tile_right = min(image.width, tile_left + TILE_SIZE)
            distance = None
            for current_distance in range(1, radius + 1):
                found = False
                for offset_y in range(-current_distance, current_distance + 1):
                    for offset_x in range(-current_distance, current_distance + 1):
                        if max(abs(offset_x), abs(offset_y)) != current_distance:
                            continue
                        neighbour_x = x + offset_x
                        neighbour_y = y + offset_y
                        if not (tile_left <= neighbour_x < tile_right and tile_top <= neighbour_y < tile_bottom):
                            continue
                        if not is_erw_water_pixel(mask_pixels[neighbour_x, neighbour_y]):
                            distance = current_distance
                            found = True
                            break
                    if found:
                        break
                if found:
                    break
            if distance is None:
                continue
            factor = strength * (radius - distance + 1) / radius
            red, green, blue, alpha = target_pixels[x, y]
            target = (170, 220, 210)
            target_pixels[x, y] = tuple(
                round(channel + (highlight - channel) * factor)
                for channel, highlight in zip((red, green, blue), target)
            ) + (alpha,)
    return result


def adapt_erw_ground_pixel(
    pixel: tuple[int, int, int, int],
    target_hue: float = 0.105,
    saturation_factor: float = 1.35,
    minimum_saturation: float = 0.5,
    maximum_saturation: float = 0.7,
    brightness_factor: float = 1.08,
) -> tuple[int, int, int, int]:
    red, green, blue, alpha = pixel
    if alpha == 0:
        return pixel
    hue, saturation, value = rgb_to_hsv(red / 255, green / 255, blue / 255)
    if is_erw_ground_pixel(pixel):
        hue = target_hue
        saturation = max(minimum_saturation, min(maximum_saturation, saturation * saturation_factor))
        value = min(1.0, value * brightness_factor)
        changed = hsv_to_rgb(hue, saturation, value)
        return tuple(round(channel * 255) for channel in changed) + (alpha,)
    return pixel


def is_erw_ground_pixel(pixel: tuple[int, int, int, int]) -> bool:
    red, green, blue, alpha = pixel
    if alpha == 0:
        return False
    hue, saturation, value = rgb_to_hsv(red / 255, green / 255, blue / 255)
    return 0.055 <= hue <= 0.18 and saturation >= 0.18 and value >= 0.32


def adapt_erw_grass_pixel(
    pixel: tuple[int, int, int, int],
    target_hue: float,
    saturation_factor: float = 1.0,
    minimum_saturation: float = 0.0,
    maximum_saturation: float = 1.0,
    brightness_factor: float = 1.0,
) -> tuple[int, int, int, int]:
    red, green, blue, alpha = pixel
    if alpha == 0:
        return pixel
    hue, saturation, value = rgb_to_hsv(red / 255, green / 255, blue / 255)
    if 0.2 <= hue <= 0.48 and saturation >= 0.2 and value >= 0.25:
        saturation = max(minimum_saturation, min(maximum_saturation, saturation * saturation_factor))
        value = min(1.0, value * brightness_factor)
        changed = hsv_to_rgb(target_hue, saturation, value)
        return tuple(round(channel * 255) for channel in changed) + (alpha,)
    return pixel


def write_adapted_erw_tileset(args: argparse.Namespace, image: Image.Image) -> tuple[int, int, int]:
    image.save(args.output_png, optimize=True)
    root = ET.parse(args.source_tsx).getroot()
    root.attrib["name"] = args.name
    source_image = root.find("image")
    if source_image is None:
        raise ValueError(f"The ERW tileset has no image: {args.source_tsx}")
    source_image.attrib["source"] = args.output_png.name
    for wangset in root.findall("wangsets/wangset"):
        wangset.attrib["name"] = f"{args.name} — {wangset.attrib['name']}"
    if getattr(args, "strip_animations", False):
        for tile in root.findall("tile"):
            animation = tile.find("animation")
            if animation is not None:
                tile.remove(animation)
    ET.indent(root, space="  ")
    args.output_tsx.write_text(
        '<?xml version="1.0" encoding="UTF-8"?>\n' + ET.tostring(root, encoding="unicode") + "\n",
        encoding="utf-8",
    )
    return int(root.attrib["columns"]), (image.height + TILE_SIZE - 1) // TILE_SIZE, int(root.attrib["tilecount"])


def build_erw_wang_canonical(args: argparse.Namespace) -> tuple[int, int, int]:
    image = Image.open(args.source_atlas).convert("RGBA")
    metadata = PngInfo()
    metadata.add_text("Description", args.name)
    image.save(args.output_png, optimize=True, pnginfo=metadata)
    root = ET.parse(args.source_tsx).getroot()
    wangsets = root.findall("wangsets/wangset")
    if not 0 <= args.wang_set_index < len(wangsets):
        raise ValueError(f"The ERW Wang Set index is out of range: {args.wang_set_index}")
    wangset = wangsets[args.wang_set_index]
    seen_signatures: set[str] = set()
    for wangtile in list(wangset.findall("wangtile")):
        signature = wangtile.attrib["wangid"]
        if signature in seen_signatures:
            wangset.remove(wangtile)
        else:
            seen_signatures.add(signature)
    root.attrib["name"] = args.name
    image_node = root.find("image")
    if image_node is None:
        raise ValueError(f"The ERW tileset has no image: {args.source_tsx}")
    image_node.attrib["source"] = args.output_png.name
    wangset.attrib["name"] = args.name
    ET.indent(root, space="  ")
    args.output_tsx.write_text(
        '<?xml version="1.0" encoding="UTF-8"?>\n' + ET.tostring(root, encoding="unicode") + "\n",
        encoding="utf-8",
    )
    return int(root.attrib["columns"]), (image.height + TILE_SIZE - 1) // TILE_SIZE, int(root.attrib["tilecount"])


def build_erw_ground(args: argparse.Namespace) -> tuple[int, int, int]:
    image = Image.open(args.source_atlas).convert("RGBA")
    output = image.load()
    for y in range(image.height):
        for x in range(image.width):
            pixel = output[x, y]
            output[x, y] = adapt_erw_ground_pixel(
                pixel,
                target_hue=getattr(args, "ground_hue", 0.105),
                saturation_factor=getattr(args, "ground_saturation", 1.35),
                minimum_saturation=getattr(args, "ground_minimum_saturation", 0.5),
                maximum_saturation=getattr(args, "ground_maximum_saturation", 0.7),
                brightness_factor=getattr(args, "ground_brightness", 1.08),
            )
            grass_hue = getattr(args, "grass_hue", None)
            if grass_hue is not None and not is_erw_ground_pixel(pixel):
                output[x, y] = adapt_erw_grass_pixel(
                    pixel,
                    target_hue=grass_hue,
                    saturation_factor=getattr(args, "grass_saturation", 1.0),
                    minimum_saturation=getattr(args, "grass_minimum_saturation", 0.0),
                    maximum_saturation=getattr(args, "grass_maximum_saturation", 1.0),
                    brightness_factor=getattr(args, "grass_brightness", 1.0),
                )
    return write_adapted_erw_tileset(args, image)


def build_erw_ground_outline(args: argparse.Namespace) -> tuple[int, int, int]:
    source = Image.open(args.source_atlas).convert("RGBA")
    texture = crop_tile(
        Image.open(args.texture_atlas).convert("RGBA"),
        args.texture_columns,
        args.texture_tile_id,
    )
    texture = adjust_texture_hsv(
        texture,
        getattr(args, "texture_hue_shift_degrees", 0.0),
        getattr(args, "texture_saturation", 1.0),
        getattr(args, "texture_brightness", 1.0),
    )
    texture_pixels = texture.load()
    result = Image.new("RGBA", source.size)
    border_colors = ((118, 91, 45), (105, 119, 39), (93, 143, 35))
    for tile_top in range(0, source.height, TILE_SIZE):
        for tile_left in range(0, source.width, TILE_SIZE):
            box = (
                tile_left,
                tile_top,
                min(source.width, tile_left + TILE_SIZE),
                min(source.height, tile_top + TILE_SIZE),
            )
            tile = source.crop(box)
            material_mask = Image.new("L", tile.size)
            material_pixels = material_mask.load()
            tile_pixels = tile.load()
            for y in range(tile.height):
                for x in range(tile.width):
                    if is_erw_ground_pixel(tile_pixels[x, y]):
                        material_pixels[x, y] = 255
            if material_mask.getbbox() is None:
                continue
            material_close_px = getattr(args, "material_close_px", 0)
            if material_close_px > 0:
                filter_size = material_close_px * 2 + 1
                material_mask = material_mask.filter(ImageFilter.MaxFilter(filter_size)).filter(ImageFilter.MinFilter(filter_size))
            material_expand_px = getattr(args, "material_expand_px", 1)
            if material_expand_px > 0:
                material_mask = material_mask.filter(ImageFilter.MaxFilter(material_expand_px * 2 + 1))
            expanded_masks = [material_mask]
            for radius in range(1, args.border_width + 1):
                expanded_masks.append(material_mask.filter(ImageFilter.MaxFilter(radius * 2 + 1)))
            output_tile = Image.new("RGBA", tile.size)
            output_pixels = output_tile.load()
            mask_pixels = [mask.load() for mask in expanded_masks]
            for y in range(tile.height):
                for x in range(tile.width):
                    if mask_pixels[0][x, y] > 0:
                        output_pixels[x, y] = (
                            tile_pixels[x, y]
                            if getattr(args, "preserve_source_material", False) and is_erw_ground_pixel(tile_pixels[x, y])
                            else texture_pixels[x % TILE_SIZE, y % TILE_SIZE]
                        )
                        continue
                    ring = next(
                        (index for index in range(1, len(mask_pixels)) if mask_pixels[index][x, y] > 0),
                        None,
                    )
                    if ring is None:
                        continue
                    base = border_colors[min(ring - 1, len(border_colors) - 1)]
                    texture_pixel = texture_pixels[x % TILE_SIZE, y % TILE_SIZE]
                    variation = round((sum(texture_pixel[:3]) / 3 - 142) * 0.08)
                    output_pixels[x, y] = tuple(max(0, min(255, channel + variation)) for channel in base) + (255,)
            result.alpha_composite(output_tile, (tile_left, tile_top))
    return write_adapted_erw_tileset(args, result)


def build_erw_water(args: argparse.Namespace) -> tuple[int, int, int]:
    image = Image.open(args.source_atlas).convert("RGBA")
    texture_path = getattr(args, "water_texture_atlas", None)
    texture_source = None if texture_path is None else Image.open(texture_path).convert("RGBA")
    texture = None if texture_source is None else (
        make_seamless_texture(texture_source)
        if getattr(args, "water_texture_use_full_atlas", False)
        else crop_tile(
            texture_source,
            getattr(args, "water_texture_columns", 1),
            getattr(args, "water_texture_tile_id", 0),
        )
    )
    if texture is not None:
        texture = ImageEnhance.Contrast(texture).enhance(getattr(args, "water_texture_contrast", 1.0))
        texture = adjust_texture_hsv(
            texture,
            getattr(args, "water_texture_hue_shift_degrees", 0.0),
            getattr(args, "water_texture_saturation", 1.0),
            getattr(args, "water_texture_brightness", 1.0),
        )
    source = image.load()
    target = image.copy()
    output = target.load()
    texture_pixels = None if texture is None else texture.load()
    expanded_mask = expanded_erw_water_mask(image, getattr(args, "water_expand_px", 0)).load()
    for y in range(image.height):
        for x in range(image.width):
            pixel = source[x, y]
            replace_with_texture = is_erw_water_pixel(pixel) or (
                pixel[3] > 0 and expanded_mask[x, y] > 0
            )
            if texture_pixels is not None and replace_with_texture:
                texture_pixel = texture_pixels[x % TILE_SIZE, y % TILE_SIZE]
                luminance = pixel[0] * 0.25 + pixel[1] * 0.5 + pixel[2] * 0.25
                delta = round((luminance - 108) * 0.35)
                output[x, y] = tuple(max(0, min(255, texture_pixel[index] + delta)) for index in range(3)) + (pixel[3],)
            else:
                output[x, y] = adapt_erw_water_pixel(
                    pixel,
                    target_hue=getattr(args, "water_hue", None),
                    saturation_factor=getattr(args, "water_saturation", 1.0),
                    minimum_saturation=getattr(args, "water_minimum_saturation", 0.0),
                    maximum_saturation=getattr(args, "water_maximum_saturation", 1.0),
                    brightness_factor=getattr(args, "water_brightness", 1.0),
                )
            grass_hue = getattr(args, "grass_hue", None)
            if grass_hue is not None and not is_erw_water_pixel(pixel) and not is_erw_ground_pixel(pixel):
                output[x, y] = adapt_erw_grass_pixel(
                    output[x, y],
                    target_hue=grass_hue,
                    saturation_factor=getattr(args, "grass_saturation", 1.0),
                    minimum_saturation=getattr(args, "grass_minimum_saturation", 0.0),
                    maximum_saturation=getattr(args, "grass_maximum_saturation", 1.0),
                    brightness_factor=getattr(args, "grass_brightness", 1.0),
                )
    target = apply_erw_water_inner_shadow(
        target,
        image,
        getattr(args, "water_inner_shadow_px", 0),
        getattr(args, "water_inner_shadow_strength", 0.28),
    )
    return write_adapted_erw_tileset(args, target)


def build_erw_water_retune(args: argparse.Namespace) -> tuple[int, int, int]:
    source = Image.open(args.source_atlas).convert("RGBA")
    mask = Image.open(args.water_mask_atlas).convert("RGBA")
    if source.size != mask.size:
        raise ValueError("The ERW water source and mask atlases must have identical dimensions")
    tuned = adjust_texture_hsv(
        source,
        args.water_hue_shift_degrees,
        args.water_saturation,
        args.water_brightness,
    )
    result = source.copy()
    source_pixels = source.load()
    mask_pixels = mask.load()
    tuned_pixels = tuned.load()
    result_pixels = result.load()
    for y in range(source.height):
        for x in range(source.width):
            if is_erw_water_pixel(mask_pixels[x, y]):
                result_pixels[x, y] = tuned_pixels[x, y]
            else:
                result_pixels[x, y] = source_pixels[x, y]
    return write_adapted_erw_tileset(args, result)


def build_erw_water_edge_highlight(args: argparse.Namespace) -> tuple[int, int, int]:
    source = Image.open(args.source_atlas).convert("RGBA")
    mask = Image.open(args.water_mask_atlas).convert("RGBA")
    if source.size != mask.size:
        raise ValueError("The ERW water source and mask atlases must have identical dimensions")
    result = apply_erw_water_inner_highlight(
        source,
        mask,
        args.edge_highlight_px,
        args.edge_highlight_strength,
    )
    return write_adapted_erw_tileset(args, result)


def write_tsx(
    *,
    output_path: Path,
    image_name: str,
    name: str,
    columns: int,
    rows: int,
    variants: int,
    frame_count: int,
    frame_duration_ms: int,
    wang_type: str = "edge",
) -> None:
    base_count = variants * MASK_COUNT
    tile_count = base_count * frame_count
    root = ET.Element(
        "tileset",
        {
            "version": "1.10",
            "tiledversion": "1.10.2",
            "name": name,
            "tilewidth": str(TILE_SIZE),
            "tileheight": str(TILE_SIZE),
            "tilecount": str(tile_count),
            "columns": str(columns),
        },
    )
    ET.SubElement(
        root,
        "image",
        {
            "source": image_name,
            "width": str(columns * TILE_SIZE),
            "height": str(rows * TILE_SIZE),
        },
    )
    if frame_count > 1:
        for tile_id in range(base_count):
            tile = ET.SubElement(root, "tile", {"id": str(tile_id), "probability": "1"})
            animation = ET.SubElement(tile, "animation")
            for frame_index in range(frame_count):
                ET.SubElement(
                    animation,
                    "frame",
                    {
                        "tileid": str(tile_id + frame_index * base_count),
                        "duration": str(frame_duration_ms),
                    },
                )
    wangsets = ET.SubElement(root, "wangsets")
    wangset = ET.SubElement(wangsets, "wangset", {"name": name, "type": wang_type, "tile": "-1"})
    ET.SubElement(wangset, "wangcolor", {"name": name, "color": "#c5964c", "tile": "15", "probability": "1"})
    for variant in range(variants):
        for mask in range(1 if wang_type == "corner" else 0, MASK_COUNT):
            ET.SubElement(
                wangset,
                "wangtile",
                {
                    "tileid": str(variant * MASK_COUNT + mask),
                    "wangid": corner_wang_id(mask) if wang_type == "corner" else wang_id(mask),
                },
            )
    ET.indent(root, space="  ")
    output_path.write_text('<?xml version="1.0" encoding="UTF-8"?>\n' + ET.tostring(root, encoding="unicode") + "\n", encoding="utf-8")


def parser() -> argparse.ArgumentParser:
    result = argparse.ArgumentParser()
    subparsers = result.add_subparsers(dest="kind", required=True)

    def common(subparser: argparse.ArgumentParser) -> None:
        subparser.add_argument("--source-atlas", type=Path, required=True)
        subparser.add_argument("--source-columns", type=int, required=True)
        subparser.add_argument("--output-png", type=Path, required=True)
        subparser.add_argument("--output-tsx", type=Path, required=True)
        subparser.add_argument("--name", required=True)
        subparser.add_argument("--frame-duration-ms", type=int, default=120)

    ground = subparsers.add_parser("ground")
    common(ground)
    ground.add_argument("--texture-tile-ids", type=parse_tile_ids, required=True)
    ground.add_argument("--correction-overlay", type=Path)

    grass_fill = subparsers.add_parser("grass-fill")
    common(grass_fill)
    grass_fill.add_argument("--texture-tile-ids", type=parse_tile_ids, required=True)
    grass_fill.add_argument("--source-seamless", action="store_true")
    grass_fill.add_argument("--shift-variants", action="store_true")
    grass_fill.add_argument("--hue-shift-degrees", type=float, default=0.0)
    grass_fill.add_argument("--texture-saturation", type=float, default=1.0)
    grass_fill.add_argument("--texture-brightness", type=float, default=1.0)
    grass_fill.add_argument("--texture-contrast", type=float, default=1.0)

    sampled_ground = subparsers.add_parser("sampled-ground")
    sampled_ground.add_argument("--render", type=Path, required=True)
    sampled_ground.add_argument("--map-json", type=Path, required=True)
    sampled_ground.add_argument("--layer-id", required=True)
    sampled_ground.add_argument("--variants", type=int, default=3)
    sampled_ground.add_argument("--derive-from-render", action="store_true")
    sampled_ground.add_argument("--derive-from-all-corners", action="store_true")
    sampled_ground.add_argument("--edge-field-projection", action="store_true")
    sampled_ground.add_argument("--minimum-path-coverage", type=float, default=0.18)
    sampled_ground.add_argument("--minimum-path-red", type=int, default=145)
    sampled_ground.add_argument("--path-red-over-green", type=int, default=18)
    sampled_ground.add_argument("--path-green-over-blue", type=int, default=35)
    sampled_ground.add_argument("--output-cells-json", type=Path)
    sampled_ground.add_argument("--output-png", type=Path, required=True)
    sampled_ground.add_argument("--output-tsx", type=Path, required=True)
    sampled_ground.add_argument("--name", required=True)
    sampled_ground.add_argument("--frame-duration-ms", type=int, default=120)

    sampled_corner = subparsers.add_parser("sampled-corner")
    sampled_corner.add_argument("--render", type=Path, required=True)
    sampled_corner.add_argument("--map-json", type=Path, required=True)
    sampled_corner.add_argument("--layer-id", required=True)
    sampled_corner.add_argument("--variants", type=int, default=5)
    sampled_corner.add_argument("--output-png", type=Path, required=True)
    sampled_corner.add_argument("--output-tsx", type=Path, required=True)
    sampled_corner.add_argument("--name", required=True)
    sampled_corner.add_argument("--frame-duration-ms", type=int, default=120)

    sampled_corner_animated = subparsers.add_parser("sampled-corner-animated")
    sampled_corner_animated.add_argument("--render", type=Path, required=True)
    sampled_corner_animated.add_argument("--map-json", type=Path, required=True)
    sampled_corner_animated.add_argument("--layer-id", required=True)
    sampled_corner_animated.add_argument("--variants", type=int, default=3)
    sampled_corner_animated.add_argument("--frame-count", type=int, default=4)
    sampled_corner_animated.add_argument("--water-texture-atlas", type=Path, required=True)
    sampled_corner_animated.add_argument("--water-texture-columns", type=int, default=4)
    sampled_corner_animated.add_argument("--water-texture-tile-id", type=int, default=0)
    sampled_corner_animated.add_argument("--water-texture-use-full-atlas", action="store_true")
    sampled_corner_animated.add_argument("--water-shoreline", action="store_true")
    sampled_corner_animated.add_argument("--output-png", type=Path, required=True)
    sampled_corner_animated.add_argument("--output-tsx", type=Path, required=True)
    sampled_corner_animated.add_argument("--name", required=True)
    sampled_corner_animated.add_argument("--frame-duration-ms", type=int, default=140)

    water = subparsers.add_parser("water")
    common(water)
    water.add_argument("--source-tsx", type=Path, required=True)
    water.add_argument("--base-tile-ids", type=parse_tile_ids, required=True)
    water.add_argument("--frame-count", type=int, default=4)
    water.add_argument("--bank-overlay", type=Path)
    water.add_argument("--tone-overlay", type=Path)

    bank = subparsers.add_parser("bank")
    bank.add_argument("--bank-overlay", type=Path, required=True)
    bank.add_argument("--tone-overlay", type=Path)
    bank.add_argument("--output-png", type=Path, required=True)
    bank.add_argument("--output-tsx", type=Path, required=True)
    bank.add_argument("--name", required=True)
    bank.add_argument("--frame-duration-ms", type=int, default=120)

    erw_water = subparsers.add_parser("erw-water")
    erw_water.add_argument("--source-atlas", type=Path, required=True)
    erw_water.add_argument("--source-tsx", type=Path, required=True)
    erw_water.add_argument("--water-texture-atlas", type=Path)
    erw_water.add_argument("--water-texture-columns", type=int, default=1)
    erw_water.add_argument("--water-texture-tile-id", type=int, default=0)
    erw_water.add_argument("--water-texture-use-full-atlas", action="store_true")
    erw_water.add_argument("--water-texture-contrast", type=float, default=1.0)
    erw_water.add_argument("--water-texture-hue-shift-degrees", type=float, default=0.0)
    erw_water.add_argument("--water-texture-saturation", type=float, default=1.0)
    erw_water.add_argument("--water-texture-brightness", type=float, default=1.0)
    erw_water.add_argument("--water-hue", type=float)
    erw_water.add_argument("--water-saturation", type=float, default=1.0)
    erw_water.add_argument("--water-minimum-saturation", type=float, default=0.0)
    erw_water.add_argument("--water-maximum-saturation", type=float, default=1.0)
    erw_water.add_argument("--water-brightness", type=float, default=1.0)
    erw_water.add_argument("--grass-hue", type=float)
    erw_water.add_argument("--grass-saturation", type=float, default=1.0)
    erw_water.add_argument("--grass-minimum-saturation", type=float, default=0.0)
    erw_water.add_argument("--grass-maximum-saturation", type=float, default=1.0)
    erw_water.add_argument("--grass-brightness", type=float, default=1.0)
    erw_water.add_argument("--water-inner-shadow-px", type=int, default=0)
    erw_water.add_argument("--water-inner-shadow-strength", type=float, default=0.28)
    erw_water.add_argument("--water-expand-px", type=int, default=0)
    erw_water.add_argument("--strip-animations", action="store_true")
    erw_water.add_argument("--output-png", type=Path, required=True)
    erw_water.add_argument("--output-tsx", type=Path, required=True)
    erw_water.add_argument("--name", required=True)

    erw_water_retune = subparsers.add_parser("erw-water-retune")
    erw_water_retune.add_argument("--source-atlas", type=Path, required=True)
    erw_water_retune.add_argument("--source-tsx", type=Path, required=True)
    erw_water_retune.add_argument("--water-mask-atlas", type=Path, required=True)
    erw_water_retune.add_argument("--water-hue-shift-degrees", type=float, default=0.0)
    erw_water_retune.add_argument("--water-saturation", type=float, default=1.0)
    erw_water_retune.add_argument("--water-brightness", type=float, default=1.0)
    erw_water_retune.add_argument("--output-png", type=Path, required=True)
    erw_water_retune.add_argument("--output-tsx", type=Path, required=True)
    erw_water_retune.add_argument("--name", required=True)

    erw_water_edge_highlight = subparsers.add_parser("erw-water-edge-highlight")
    erw_water_edge_highlight.add_argument("--source-atlas", type=Path, required=True)
    erw_water_edge_highlight.add_argument("--source-tsx", type=Path, required=True)
    erw_water_edge_highlight.add_argument("--water-mask-atlas", type=Path, required=True)
    erw_water_edge_highlight.add_argument("--edge-highlight-px", type=int, default=1)
    erw_water_edge_highlight.add_argument("--edge-highlight-strength", type=float, default=0.16)
    erw_water_edge_highlight.add_argument("--output-png", type=Path, required=True)
    erw_water_edge_highlight.add_argument("--output-tsx", type=Path, required=True)
    erw_water_edge_highlight.add_argument("--name", required=True)

    erw_wang_canonical = subparsers.add_parser("erw-wang-canonical")
    erw_wang_canonical.add_argument("--source-atlas", type=Path, required=True)
    erw_wang_canonical.add_argument("--source-tsx", type=Path, required=True)
    erw_wang_canonical.add_argument("--wang-set-index", type=int, required=True)
    erw_wang_canonical.add_argument("--output-png", type=Path, required=True)
    erw_wang_canonical.add_argument("--output-tsx", type=Path, required=True)
    erw_wang_canonical.add_argument("--name", required=True)

    erw_ground_outline = subparsers.add_parser("erw-ground-outline")
    erw_ground_outline.add_argument("--source-atlas", type=Path, required=True)
    erw_ground_outline.add_argument("--source-tsx", type=Path, required=True)
    erw_ground_outline.add_argument("--texture-atlas", type=Path, required=True)
    erw_ground_outline.add_argument("--texture-columns", type=int, default=1)
    erw_ground_outline.add_argument("--texture-tile-id", type=int, default=0)
    erw_ground_outline.add_argument("--texture-hue-shift-degrees", type=float, default=0.0)
    erw_ground_outline.add_argument("--texture-saturation", type=float, default=1.0)
    erw_ground_outline.add_argument("--texture-brightness", type=float, default=1.0)
    erw_ground_outline.add_argument("--preserve-source-material", action="store_true")
    erw_ground_outline.add_argument("--material-close-px", type=int, default=0)
    erw_ground_outline.add_argument("--material-expand-px", type=int, default=1)
    erw_ground_outline.add_argument("--border-width", type=int, default=3)
    erw_ground_outline.add_argument("--output-png", type=Path, required=True)
    erw_ground_outline.add_argument("--output-tsx", type=Path, required=True)
    erw_ground_outline.add_argument("--name", required=True)

    erw_ground = subparsers.add_parser("erw-ground")
    erw_ground.add_argument("--source-atlas", type=Path, required=True)
    erw_ground.add_argument("--source-tsx", type=Path, required=True)
    erw_ground.add_argument("--ground-hue", type=float, default=0.105)
    erw_ground.add_argument("--ground-saturation", type=float, default=1.35)
    erw_ground.add_argument("--ground-minimum-saturation", type=float, default=0.5)
    erw_ground.add_argument("--ground-maximum-saturation", type=float, default=0.7)
    erw_ground.add_argument("--ground-brightness", type=float, default=1.08)
    erw_ground.add_argument("--grass-hue", type=float)
    erw_ground.add_argument("--grass-saturation", type=float, default=1.0)
    erw_ground.add_argument("--grass-minimum-saturation", type=float, default=0.0)
    erw_ground.add_argument("--grass-maximum-saturation", type=float, default=1.0)
    erw_ground.add_argument("--grass-brightness", type=float, default=1.0)
    erw_ground.add_argument("--output-png", type=Path, required=True)
    erw_ground.add_argument("--output-tsx", type=Path, required=True)
    erw_ground.add_argument("--name", required=True)
    return result


def main() -> None:
    args = parser().parse_args()
    args.output_png.parent.mkdir(parents=True, exist_ok=True)
    args.output_tsx.parent.mkdir(parents=True, exist_ok=True)
    columns, rows, tile_count = (
        build_ground(args)
        if args.kind == "ground"
        else build_grass_fill(args)
        if args.kind == "grass-fill"
        else build_sampled_ground(args)
        if args.kind == "sampled-ground"
        else build_sampled_corner(args)
        if args.kind == "sampled-corner"
        else build_sampled_corner_animated(args)
        if args.kind == "sampled-corner-animated"
        else build_bank(args)
        if args.kind == "bank"
        else build_erw_water_retune(args)
        if args.kind == "erw-water-retune"
        else build_erw_water_edge_highlight(args)
        if args.kind == "erw-water-edge-highlight"
        else build_erw_water(args)
        if args.kind == "erw-water"
        else build_erw_wang_canonical(args)
        if args.kind == "erw-wang-canonical"
        else build_erw_ground_outline(args)
        if args.kind == "erw-ground-outline"
        else build_erw_ground(args)
        if args.kind == "erw-ground"
        else build_water(args)
    )
    print(f"{args.output_png}\t{columns * TILE_SIZE}x{rows * TILE_SIZE}\t{tile_count} tiles")
    topology = "corner16" if args.kind in {"grass-fill", "sampled-corner", "sampled-corner-animated", "erw-water", "erw-water-retune", "erw-water-edge-highlight", "erw-wang-canonical", "erw-ground-outline", "erw-ground"} else "edge16"
    print(f"{args.output_tsx}\t{topology}\t{args.name}")


if __name__ == "__main__":
    main()
