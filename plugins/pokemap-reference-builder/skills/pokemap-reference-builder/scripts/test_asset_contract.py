#!/usr/bin/env python3
import json
import struct
import tempfile
import unittest
import zlib
from pathlib import Path

from asset_contract import create_contract, validate_contract


def png_chunk(kind: bytes, data: bytes) -> bytes:
    return struct.pack(">I", len(data)) + kind + data + struct.pack(">I", zlib.crc32(kind + data) & 0xFFFFFFFF)


def write_rgba_png(path: Path, width: int, height: int, transparent: bool) -> None:
    rows = []
    for y in range(height):
        row = bytearray()
        for x in range(width):
            alpha = 0 if transparent and x == 0 and y == 0 else 255
            row.extend((80, 120, 90, alpha))
        rows.append(b"\x00" + bytes(row))
    ihdr = struct.pack(">IIBBBBB", width, height, 8, 6, 0, 0, 0)
    payload = (
        b"\x89PNG\r\n\x1a\n"
        + png_chunk(b"IHDR", ihdr)
        + png_chunk(b"IDAT", zlib.compress(b"".join(rows)))
        + png_chunk(b"IEND", b"")
    )
    path.write_bytes(payload)


class AssetContractTest(unittest.TestCase):
    def test_accepts_exact_rgba_canvas_with_transparency(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            png = Path(directory) / "torii.png"
            write_rgba_png(png, 64, 96, True)
            contract = create_contract(
                "asset-custom-torii",
                2,
                3,
                str(png),
                "required",
                ["TECH-Nature.png HGSS torii palette"],
            )
            contract["status"] = "approved"
            errors, metadata = validate_contract(contract)
            self.assertEqual(errors, [])
            self.assertTrue(metadata["alphaUsed"])

    def test_rejects_wrong_png_dimensions(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            png = Path(directory) / "small.png"
            write_rgba_png(png, 32, 32, True)
            contract = create_contract(
                "asset-custom-house",
                2,
                2,
                str(png),
                "required",
                ["HGSS house"],
            )
            contract["status"] = "approved"
            errors, _ = validate_contract(contract)
            self.assertTrue(any("expected 64x64" in error for error in errors))

    def test_rejects_opaque_png_when_alpha_is_required(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            png = Path(directory) / "opaque.png"
            write_rgba_png(png, 32, 32, False)
            contract = create_contract(
                "asset-custom-sign",
                1,
                1,
                str(png),
                "required",
                ["HGSS sign"],
            )
            contract["status"] = "approved"
            errors, _ = validate_contract(contract)
            self.assertTrue(any("transparent pixels" in error for error in errors))

    def test_rejects_gba_style_reference(self) -> None:
        contract = create_contract(
            "asset-custom-tree",
            2,
            4,
            None,
            "optional",
            ["GBA tree sheet"],
        )
        errors, _ = validate_contract(contract)
        self.assertTrue(any("GBA references" in error for error in errors))


if __name__ == "__main__":
    unittest.main()
