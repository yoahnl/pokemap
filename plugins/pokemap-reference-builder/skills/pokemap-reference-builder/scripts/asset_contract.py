#!/usr/bin/env python3
import argparse
import json
import struct
import sys
import zlib
from pathlib import Path


PNG_SIGNATURE = b"\x89PNG\r\n\x1a\n"
CELL_SIZE = 32
MAX_CELLS = 64
STATUS_VALUES = {"proposed", "approved", "imported", "verified"}


def create_contract(
    asset_id: str,
    width_cells: int,
    height_cells: int,
    png: str | None,
    alpha_policy: str,
    style_references: list[str],
) -> dict:
    value = {
        "id": asset_id,
        "status": "proposed",
        "widthCells": width_cells,
        "heightCells": height_cells,
        "pixelWidth": width_cells * CELL_SIZE,
        "pixelHeight": height_cells * CELL_SIZE,
        "anchor": {"x": width_cells // 2, "y": height_cells - 1},
        "collisionCells": [],
        "provenance": "custom_hgss_compatible",
        "alphaPolicy": alpha_policy,
        "styleReferences": style_references,
    }
    if png:
        value["sourcePng"] = str(Path(png).expanduser().resolve())
    return value


def load_json(path: Path) -> dict:
    with path.open("r", encoding="utf-8") as handle:
        value = json.load(handle)
    if not isinstance(value, dict):
        raise ValueError("contract root must be an object")
    return value


def write_json(path: Path, value: dict, force: bool) -> None:
    if path.exists() and not force:
        raise FileExistsError(f"refusing to overwrite {path}; pass --force")
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("w", encoding="utf-8") as handle:
        json.dump(value, handle, ensure_ascii=False, indent=2)
        handle.write("\n")


def paeth(left: int, above: int, upper_left: int) -> int:
    value = left + above - upper_left
    left_distance = abs(value - left)
    above_distance = abs(value - above)
    upper_left_distance = abs(value - upper_left)
    if left_distance <= above_distance and left_distance <= upper_left_distance:
        return left
    if above_distance <= upper_left_distance:
        return above
    return upper_left


def unfilter_rows(raw: bytes, width: int, height: int, channels: int) -> list[bytes]:
    row_length = width * channels
    expected = height * (row_length + 1)
    if len(raw) != expected:
        raise ValueError(f"decoded PNG length {len(raw)} does not match expected {expected}")
    rows: list[bytes] = []
    previous = bytearray(row_length)
    offset = 0
    for _ in range(height):
        filter_type = raw[offset]
        offset += 1
        encoded = raw[offset : offset + row_length]
        offset += row_length
        current = bytearray(row_length)
        for index, byte in enumerate(encoded):
            left = current[index - channels] if index >= channels else 0
            above = previous[index]
            upper_left = previous[index - channels] if index >= channels else 0
            if filter_type == 0:
                value = byte
            elif filter_type == 1:
                value = byte + left
            elif filter_type == 2:
                value = byte + above
            elif filter_type == 3:
                value = byte + ((left + above) // 2)
            elif filter_type == 4:
                value = byte + paeth(left, above, upper_left)
            else:
                raise ValueError(f"unsupported PNG filter {filter_type}")
            current[index] = value & 0xFF
        rows.append(bytes(current))
        previous = current
    return rows


def decode_png(path: Path, expected_width: int, expected_height: int) -> dict:
    data = path.read_bytes()
    if not data.startswith(PNG_SIGNATURE):
        raise ValueError("sourcePng is not a PNG file")
    offset = len(PNG_SIGNATURE)
    ihdr: bytes | None = None
    compressed = bytearray()
    transparency: bytes | None = None
    while offset < len(data):
        if offset + 12 > len(data):
            raise ValueError("truncated PNG chunk")
        length = struct.unpack(">I", data[offset : offset + 4])[0]
        chunk_type = data[offset + 4 : offset + 8]
        start = offset + 8
        end = start + length
        if end + 4 > len(data):
            raise ValueError("truncated PNG chunk data")
        chunk_data = data[start:end]
        expected_crc = struct.unpack(">I", data[end : end + 4])[0]
        actual_crc = zlib.crc32(chunk_type + chunk_data) & 0xFFFFFFFF
        if actual_crc != expected_crc:
            raise ValueError(f"invalid CRC in {chunk_type.decode('ascii', errors='replace')} chunk")
        if chunk_type == b"IHDR":
            ihdr = chunk_data
        elif chunk_type == b"IDAT":
            compressed.extend(chunk_data)
        elif chunk_type == b"tRNS":
            transparency = chunk_data
        elif chunk_type == b"IEND":
            break
        offset = end + 4
    if ihdr is None or len(ihdr) != 13:
        raise ValueError("PNG has no valid IHDR")
    width, height, bit_depth, color_type, compression, filtering, interlace = struct.unpack(
        ">IIBBBBB", ihdr
    )
    if width != expected_width or height != expected_height:
        raise ValueError(
            f"PNG dimensions are {width}x{height}; expected {expected_width}x{expected_height}"
        )
    if bit_depth != 8:
        raise ValueError("only 8-bit PNG assets are accepted")
    if compression != 0 or filtering != 0 or interlace != 0:
        raise ValueError("PNG must use standard compression, filtering, and no interlace")
    channels = {0: 1, 2: 3, 3: 1, 4: 2, 6: 4}.get(color_type)
    if channels is None:
        raise ValueError(f"unsupported PNG color type {color_type}")
    expected_decoded = height * (width * channels + 1)
    decompressor = zlib.decompressobj()
    raw = decompressor.decompress(bytes(compressed), expected_decoded + 1)
    if decompressor.unconsumed_tail or len(raw) > expected_decoded:
        raise ValueError("decoded PNG exceeds its declared canvas")
    raw += decompressor.flush(expected_decoded + 1 - len(raw))
    if len(raw) > expected_decoded:
        raise ValueError("decoded PNG exceeds its declared canvas")
    rows = unfilter_rows(raw, width, height, channels)
    alpha_values: list[int] = []
    if color_type == 6:
        alpha_values = [row[index] for row in rows for index in range(3, len(row), 4)]
    elif color_type == 4:
        alpha_values = [row[index] for row in rows for index in range(1, len(row), 2)]
    elif color_type == 3 and transparency is not None:
        alpha_values = [
            transparency[index] if index < len(transparency) else 255
            for row in rows
            for index in row
        ]
    elif color_type == 2 and transparency is not None and len(transparency) == 6:
        transparent_rgb = tuple(struct.unpack(">HHH", transparency))
        alpha_values = [
            0 if tuple(row[index : index + 3]) == transparent_rgb else 255
            for row in rows
            for index in range(0, len(row), 3)
        ]
    elif color_type == 0 and transparency is not None and len(transparency) == 2:
        transparent_gray = struct.unpack(">H", transparency)[0]
        alpha_values = [0 if value == transparent_gray else 255 for row in rows for value in row]
    supports_alpha = color_type in {4, 6} or transparency is not None
    alpha_used = any(value < 255 for value in alpha_values)
    partial_alpha = any(0 < value < 255 for value in alpha_values)
    return {
        "width": width,
        "height": height,
        "bitDepth": bit_depth,
        "colorType": color_type,
        "supportsAlpha": supports_alpha,
        "alphaUsed": alpha_used,
        "partialAlpha": partial_alpha,
    }


def validate_cell(value: object, path: str, width: int, height: int, errors: list[str]) -> None:
    if not isinstance(value, dict):
        errors.append(f"{path}: expected object")
        return
    x = value.get("x")
    y = value.get("y")
    if not isinstance(x, int) or isinstance(x, bool) or not 0 <= x < width:
        errors.append(f"{path}.x: outside local footprint")
    if not isinstance(y, int) or isinstance(y, bool) or not 0 <= y < height:
        errors.append(f"{path}.y: outside local footprint")


def validate_contract(contract: dict, base_directory: Path | None = None) -> tuple[list[str], dict | None]:
    errors: list[str] = []
    status = contract.get("status")
    if not isinstance(contract.get("id"), str) or not contract.get("id"):
        errors.append("id: required")
    if status not in STATUS_VALUES:
        errors.append("status: unsupported status")
    width = contract.get("widthCells")
    height = contract.get("heightCells")
    if not isinstance(width, int) or isinstance(width, bool) or not 1 <= width <= MAX_CELLS:
        errors.append(f"widthCells: expected 1..{MAX_CELLS}")
        width = 0
    if not isinstance(height, int) or isinstance(height, bool) or not 1 <= height <= MAX_CELLS:
        errors.append(f"heightCells: expected 1..{MAX_CELLS}")
        height = 0
    pixel_width = width * CELL_SIZE
    pixel_height = height * CELL_SIZE
    if contract.get("pixelWidth") != pixel_width:
        errors.append("pixelWidth: must equal widthCells * 32")
    if contract.get("pixelHeight") != pixel_height:
        errors.append("pixelHeight: must equal heightCells * 32")
    validate_cell(contract.get("anchor"), "anchor", width, height, errors)
    collisions = contract.get("collisionCells")
    if not isinstance(collisions, list):
        errors.append("collisionCells: expected array")
        collisions = []
    for index, cell in enumerate(collisions):
        validate_cell(cell, f"collisionCells[{index}]", width, height, errors)
    if contract.get("provenance") != "custom_hgss_compatible":
        errors.append("provenance: must be custom_hgss_compatible")
    alpha_policy = contract.get("alphaPolicy")
    if alpha_policy not in {"required", "optional"}:
        errors.append("alphaPolicy: expected required or optional")
    references = contract.get("styleReferences")
    if not isinstance(references, list) or any(not isinstance(value, str) or not value for value in references):
        errors.append("styleReferences: expected an array of non-empty strings")
        references = []
    if any("gba" in value.lower() for value in references):
        errors.append("styleReferences: GBA references are forbidden")
    png_metadata = None
    source_png = contract.get("sourcePng")
    if status in {"approved", "imported", "verified"} and not source_png:
        errors.append("sourcePng: required after approval")
    if status in {"approved", "imported", "verified"} and not references:
        errors.append("styleReferences: at least one HGSS/DS reference is required after approval")
    if isinstance(source_png, str) and source_png:
        png_path = Path(source_png).expanduser()
        if not png_path.is_absolute() and base_directory is not None:
            png_path = base_directory / png_path
        try:
            png_metadata = decode_png(png_path.resolve(), pixel_width, pixel_height)
            if alpha_policy == "required" and not png_metadata["alphaUsed"]:
                errors.append("sourcePng: alphaPolicy requires actual transparent pixels")
        except (OSError, ValueError, zlib.error) as error:
            errors.append(f"sourcePng: {error}")
    return errors, png_metadata


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(prog="asset_contract.py")
    subparsers = parser.add_subparsers(dest="command", required=True)
    init = subparsers.add_parser("init")
    init.add_argument("--output", required=True)
    init.add_argument("--asset-id", required=True)
    init.add_argument("--width-cells", required=True, type=int)
    init.add_argument("--height-cells", required=True, type=int)
    init.add_argument("--png")
    init.add_argument("--alpha-policy", choices=["required", "optional"], default="required")
    init.add_argument("--style-reference", action="append", default=[])
    init.add_argument("--force", action="store_true")
    validate = subparsers.add_parser("validate")
    validate.add_argument("path")
    validate.add_argument("--json", action="store_true")
    return parser


def main(argv: list[str] | None = None) -> int:
    args = build_parser().parse_args(argv)
    try:
        if args.command == "init":
            if not 1 <= args.width_cells <= MAX_CELLS or not 1 <= args.height_cells <= MAX_CELLS:
                raise ValueError(f"asset dimensions must be between 1 and {MAX_CELLS} cells")
            contract = create_contract(
                args.asset_id,
                args.width_cells,
                args.height_cells,
                args.png,
                args.alpha_policy,
                args.style_reference,
            )
            output = Path(args.output).expanduser().resolve()
            write_json(output, contract, args.force)
            print(output)
            return 0
        path = Path(args.path).expanduser().resolve()
        contract = load_json(path)
        errors, metadata = validate_contract(contract, path.parent)
        result = {"valid": not errors, "errors": errors, "png": metadata}
        print(json.dumps(result, ensure_ascii=False, indent=2) if args.json else ("valid" if not errors else "\n".join(errors)))
        return 0 if not errors else 1
    except (OSError, ValueError, json.JSONDecodeError) as error:
        print(str(error), file=sys.stderr)
        return 2


if __name__ == "__main__":
    raise SystemExit(main())
