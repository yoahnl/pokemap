#!/usr/bin/env python3
"""Create a deterministic image inventory without persisting machine paths."""

from __future__ import annotations

import argparse
import hashlib
import json
import struct
import zlib
from pathlib import Path
from typing import Any, Iterable


IMAGE_SUFFIXES = {".png", ".jpg", ".jpeg", ".gif", ".webp"}
PNG_SIGNATURE = b"\x89PNG\r\n\x1a\n"


def sha256_file(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as stream:
        for chunk in iter(lambda: stream.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def _paeth(left: int, up: int, upper_left: int) -> int:
    estimate = left + up - upper_left
    distance_left = abs(estimate - left)
    distance_up = abs(estimate - up)
    distance_upper_left = abs(estimate - upper_left)
    if distance_left <= distance_up and distance_left <= distance_upper_left:
        return left
    if distance_up <= distance_upper_left:
        return up
    return upper_left


def _unfilter_png_rows(
    raw: bytes, *, width: int, height: int, channels: int
) -> list[bytes]:
    """Decode the non-interlaced 8-bit rows needed for alpha inspection."""
    stride = width * channels
    expected = height * (stride + 1)
    if len(raw) != expected:
        raise ValueError(f"unexpected PNG payload length {len(raw)} != {expected}")
    rows: list[bytes] = []
    previous = bytearray(stride)
    offset = 0
    for _ in range(height):
        filter_type = raw[offset]
        encoded = raw[offset + 1 : offset + 1 + stride]
        offset += stride + 1
        decoded = bytearray(stride)
        for index, value in enumerate(encoded):
            left = decoded[index - channels] if index >= channels else 0
            up = previous[index]
            upper_left = previous[index - channels] if index >= channels else 0
            if filter_type == 0:
                predictor = 0
            elif filter_type == 1:
                predictor = left
            elif filter_type == 2:
                predictor = up
            elif filter_type == 3:
                predictor = (left + up) // 2
            elif filter_type == 4:
                predictor = _paeth(left, up, upper_left)
            else:
                raise ValueError(f"unsupported PNG filter {filter_type}")
            decoded[index] = (value + predictor) & 0xFF
        rows.append(bytes(decoded))
        previous = decoded
    return rows


def _png_metadata(data: bytes) -> dict[str, Any]:
    if not data.startswith(PNG_SIGNATURE):
        raise ValueError("invalid PNG signature")
    offset = len(PNG_SIGNATURE)
    ihdr: tuple[int, int, int, int, int, int, int] | None = None
    compressed = bytearray()
    transparency_chunk: bytes | None = None
    while offset + 12 <= len(data):
        length = struct.unpack(">I", data[offset : offset + 4])[0]
        kind = data[offset + 4 : offset + 8]
        payload_start = offset + 8
        payload_end = payload_start + length
        if payload_end + 4 > len(data):
            raise ValueError("truncated PNG chunk")
        payload = data[payload_start:payload_end]
        if kind == b"IHDR":
            ihdr = struct.unpack(">IIBBBBB", payload)
        elif kind == b"IDAT":
            compressed.extend(payload)
        elif kind == b"tRNS":
            transparency_chunk = payload
        elif kind == b"IEND":
            break
        offset = payload_end + 4
    if ihdr is None:
        raise ValueError("missing PNG IHDR")
    width, height, bit_depth, color_type, _, _, interlace = ihdr
    declared_alpha = color_type in (4, 6) or transparency_chunk is not None
    metadata: dict[str, Any] = {
        "format": "png",
        "width": width,
        "height": height,
        "bitDepth": bit_depth,
        "colorType": color_type,
        "declaresAlpha": declared_alpha,
        "alphaInspection": "not-applicable" if not declared_alpha else "unknown",
        "transparentPixels": None,
        "translucentPixels": None,
    }

    # Most game sprites are non-interlaced RGBA/GA PNGs. Inspect their real
    # alpha so an opaque RGBA export is not mistaken for a cut-out asset.
    if bit_depth == 8 and interlace == 0 and color_type in (4, 6):
        channels = 2 if color_type == 4 else 4
        rows = _unfilter_png_rows(
            zlib.decompress(bytes(compressed)),
            width=width,
            height=height,
            channels=channels,
        )
        transparent = 0
        translucent = 0
        for row in rows:
            for alpha in row[channels - 1 :: channels]:
                if alpha == 0:
                    transparent += 1
                elif alpha < 255:
                    translucent += 1
        metadata.update(
            {
                "alphaInspection": "used" if transparent or translucent else "opaque",
                "transparentPixels": transparent,
                "translucentPixels": translucent,
            }
        )
    elif transparency_chunk is not None:
        metadata["alphaInspection"] = "declared"
    return metadata


def _jpeg_size(data: bytes) -> tuple[int, int]:
    if not data.startswith(b"\xff\xd8"):
        raise ValueError("invalid JPEG signature")
    offset = 2
    while offset + 4 <= len(data):
        if data[offset] != 0xFF:
            offset += 1
            continue
        marker = data[offset + 1]
        offset += 2
        if marker in (0xD8, 0xD9) or 0xD0 <= marker <= 0xD7:
            continue
        if offset + 2 > len(data):
            break
        length = struct.unpack(">H", data[offset : offset + 2])[0]
        if length < 2 or offset + length > len(data):
            break
        if marker in {
            0xC0,
            0xC1,
            0xC2,
            0xC3,
            0xC5,
            0xC6,
            0xC7,
            0xC9,
            0xCA,
            0xCB,
            0xCD,
            0xCE,
            0xCF,
        }:
            height, width = struct.unpack(">HH", data[offset + 3 : offset + 7])
            return width, height
        offset += length
    raise ValueError("JPEG dimensions not found")


def image_metadata(path: Path) -> dict[str, Any]:
    data = path.read_bytes()
    suffix = path.suffix.lower()
    if suffix == ".png":
        return _png_metadata(data)
    if suffix in {".jpg", ".jpeg"}:
        width, height = _jpeg_size(data)
        return {"format": "jpeg", "width": width, "height": height, "declaresAlpha": False}
    if suffix == ".gif" and data[:6] in {b"GIF87a", b"GIF89a"}:
        width, height = struct.unpack("<HH", data[6:10])
        return {"format": "gif", "width": width, "height": height, "declaresAlpha": None}
    return {"format": suffix.lstrip("."), "width": None, "height": None, "declaresAlpha": None}


def _image_files(root: Path) -> Iterable[Path]:
    return sorted(
        (
            path
            for path in root.rglob("*")
            if path.is_file() and path.suffix.lower() in IMAGE_SUFFIXES
        ),
        key=lambda path: path.relative_to(root).as_posix(),
    )


def _load_provenance(path: Path | None) -> dict[str, dict[str, str]]:
    if path is None:
        return {}
    try:
        decoded = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, UnicodeDecodeError, json.JSONDecodeError) as error:
        raise SystemExit(f"error: cannot decode provenance manifest: {error}") from error
    assets = decoded.get("assets") if isinstance(decoded, dict) else None
    if not isinstance(assets, dict):
        raise SystemExit("error: provenance manifest must contain an assets object")
    result: dict[str, dict[str, str]] = {}
    for relative, value in assets.items():
        if not isinstance(relative, str) or not isinstance(value, dict):
            raise SystemExit("error: provenance assets must map paths to objects")
        record: dict[str, str] = {}
        for field in ("source", "license", "status"):
            field_value = value.get(field)
            if isinstance(field_value, str) and field_value.strip():
                record[field] = field_value.strip()
        result[Path(relative).as_posix()] = record
    return result


def build_inventory(
    root: Path, label: str, provenance: dict[str, dict[str, str]] | None = None
) -> dict[str, Any]:
    provenance = provenance or {}
    assets: list[dict[str, Any]] = []
    by_hash: dict[str, list[str]] = {}
    errors: list[dict[str, str]] = []
    for path in _image_files(root):
        relative = path.relative_to(root).as_posix()
        digest = sha256_file(path)
        entry: dict[str, Any] = {
            "path": relative,
            "sizeBytes": path.stat().st_size,
            "sha256": digest,
            "provenance": provenance.get(relative),
        }
        try:
            entry.update(image_metadata(path))
        except (OSError, ValueError, zlib.error) as error:
            entry.update({"format": path.suffix.lower().lstrip("."), "decodeError": str(error)})
            errors.append({"path": relative, "error": str(error)})
        assets.append(entry)
        by_hash.setdefault(digest, []).append(relative)
    duplicates = [paths for paths in by_hash.values() if len(paths) > 1]
    duplicates.sort(key=lambda paths: paths[0])
    missing_provenance = [
        entry["path"] for entry in assets if not isinstance(entry.get("provenance"), dict)
    ]
    unapproved_provenance = [
        entry["path"]
        for entry in assets
        if isinstance(entry.get("provenance"), dict)
        and (
            entry["provenance"].get("status") != "approved"
            or not entry["provenance"].get("source")
            or not entry["provenance"].get("license")
        )
    ]
    inspection_warnings = [
        entry["path"]
        for entry in assets
        if entry.get("decodeError")
        or entry.get("width") is None
        or entry.get("height") is None
        or (
            entry.get("format") == "png"
            and entry.get("declaresAlpha") is True
            and entry.get("alphaInspection") not in {"used", "opaque"}
        )
    ]
    return {
        "schemaVersion": 1,
        "rootLabel": label,
        "summary": {
            "imageCount": len(assets),
            "totalBytes": sum(entry["sizeBytes"] for entry in assets),
            "duplicateGroupCount": len(duplicates),
            "decodeErrorCount": len(errors),
            "inspectionWarningCount": len(inspection_warnings),
            "missingProvenanceCount": len(missing_provenance),
            "unapprovedProvenanceCount": len(unapproved_provenance),
            "realTransparencyCount": sum(
                1 for entry in assets if entry.get("alphaInspection") == "used"
            ),
        },
        "duplicateGroups": duplicates,
        "decodeErrors": errors,
        "inspectionWarnings": inspection_warnings,
        "missingProvenance": missing_provenance,
        "unapprovedProvenance": unapproved_provenance,
        "assets": assets,
    }


def _parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--root", required=True, type=Path)
    parser.add_argument("--output", required=True, type=Path)
    parser.add_argument("--label", help="Portable root label; defaults to the directory name.")
    parser.add_argument("--provenance", type=Path, help="JSON mapping relative asset paths to source, license, and status.")
    parser.add_argument(
        "--require-approved-provenance",
        action="store_true",
        help="Fail unless every asset has source, license, and status=approved.",
    )
    parser.add_argument(
        "--strict",
        action="store_true",
        help="Fail on decode errors, unknown dimensions, or uninspected declared PNG alpha.",
    )
    parser.add_argument("--force", action="store_true", help="Replace an existing output file.")
    return parser


def main() -> int:
    args = _parser().parse_args()
    root = args.root.expanduser().resolve()
    output = args.output.expanduser().resolve()
    if not root.is_dir():
        raise SystemExit(f"error: asset root does not exist: {root}")
    if output.exists() and not args.force:
        raise SystemExit(f"error: output already exists (use --force): {output}")
    if output == root or output in set(_image_files(root)):
        raise SystemExit("error: output must not overwrite an inventoried asset")
    provenance_path = args.provenance.expanduser().resolve() if args.provenance else None
    provenance = _load_provenance(provenance_path)
    inventory = build_inventory(root, args.label or root.name, provenance)
    output.parent.mkdir(parents=True, exist_ok=True)
    output.write_text(json.dumps(inventory, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
    summary = inventory["summary"]
    print(
        f"Inventoried {summary['imageCount']} images, "
        f"{summary['duplicateGroupCount']} duplicate groups, "
        f"{summary['decodeErrorCount']} decode errors -> {output}"
    )
    if summary["decodeErrorCount"]:
        return 2
    if args.strict and summary["inspectionWarningCount"]:
        return 3
    if args.require_approved_provenance and (
        summary["missingProvenanceCount"] or summary["unapprovedProvenanceCount"]
    ):
        return 4
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
