import argparse
import hashlib
import io
import json
import struct
import zipfile
from pathlib import Path


MAPPINGS = {
    "poke_ball": "ball_1", "great_ball": "ball_2", "ultra_ball": "ball_3",
    "master_ball": "ball_4", "premier_ball": "ball_5", "cherish_ball": "ball_6",
    "luxury_ball": "ball_7", "nest_ball": "ball_8", "net_ball": "ball_9",
    "dive_ball": "ball_10", "repeat_ball": "ball_11", "timer_ball": "ball_12",
    "safari_ball": "ball_13", "quick_ball": "ball_14", "dusk_ball": "ball_15",
    "heal_ball": "ball_16", "beast_ball": "ball_17", "fast_ball": "ball_19",
    "lure_ball": "ball_20", "level_ball": "ball_21", "heavy_ball": "ball_22",
    "love_ball": "ball_23", "friend_ball": "ball_24", "moon_ball": "ball_25",
    "park_ball": "ball_26", "sport_ball": "ball_27", "dream_ball": "ball_28",
}
AUXILIARIES = ["ball-retreat", "ball_catch", "ball_s1", "ball_s2", "ball_stars"]
SHEETS = [f"ball_{index}" for index in range(1, 29)]
DESTINATION = Path(__file__).resolve().parents[2] / "apps/avelune_studio/assets/pokemon/capture_sprites"


def digest(data):
    return hashlib.sha256(data).hexdigest()


def dimensions(data):
    if data[:8] != b"\x89PNG\r\n\x1a\n" or data[12:16] != b"IHDR":
        raise ValueError("Expected a PNG with an IHDR header")
    return struct.unpack(">II", data[16:24])


def read_source(root, relative):
    path = root / relative
    if path.is_symlink() or not path.is_file() or not path.resolve().is_relative_to(root):
        raise ValueError(f"Unsafe or missing source: {relative}")
    return path.read_bytes()


def import_pack(root, destination):
    if root.is_symlink() or not root.is_dir():
        raise ValueError("Expected a PSDK project directory without symlinks")
    root = root.resolve()
    files = {}
    archive = io.BytesIO()
    with zipfile.ZipFile(archive, "w", compression=zipfile.ZIP_DEFLATED, compresslevel=9) as output:
        for name in sorted(SHEETS + AUXILIARIES):
            relative = f"graphics/ball/{name}.png"
            data = read_source(root, relative)
            width, height = dimensions(data)
            if name in SHEETS and (width, height) != (64, 2048):
                raise ValueError(f"Expected a 64x2048 capture sheet: {name}")
            info = zipfile.ZipInfo(f"{name}.png", date_time=(1980, 1, 1, 0, 0, 0))
            info.compress_type = zipfile.ZIP_DEFLATED
            output.writestr(info, data)
            files[name] = {"sourcePath": relative, "sha256": digest(data),
                           "bytes": len(data), "width": width, "height": height}
    mappings = {}
    for item, sheet in sorted(MAPPINGS.items()):
        relative = f"Data/Studio/items/{item}.json"
        data = read_source(root, relative)
        definition = json.loads(data)
        if definition.get("klass") != "BallItem" or definition.get("dbSymbol") != item or definition.get("spriteFilename") != sheet:
            raise ValueError(f"PSDK BallItem mapping changed: {item}")
        mappings[item] = {"sourcePath": relative, "sha256": digest(data),
                          "itemId": definition["id"], "spriteFilename": sheet}
    data = archive.getvalue()
    manifest = {
        "schemaVersion": 1, "source": "PSDK runnable test project",
        "sourceDirectory": "graphics/ball", "mappingDirectory": "Data/Studio/items",
        "importer": "tools/scripts/import_project_ball_sprites.py",
        "licenseStatus": "No license or copyright declaration supplied by this source pack.",
        "copyrightNotice": None, "archiveSha256": digest(data),
        "itemMappings": dict(sorted(MAPPINGS.items())), "mappingSources": mappings,
        "unusedSheets": ["ball_18"], "auxiliaryFiles": AUXILIARIES, "files": files,
    }
    destination.mkdir(parents=True, exist_ok=True)
    (destination / "sprites.zip").write_bytes(data)
    (destination / "manifest.json").write_text(json.dumps(manifest, ensure_ascii=False, indent=2) + "\n")


def verify_pack(destination):
    manifest = json.loads((destination / "manifest.json").read_text())
    data = (destination / "sprites.zip").read_bytes()
    if manifest["archiveSha256"] != digest(data) or manifest["itemMappings"] != MAPPINGS:
        raise ValueError("Pack archive or mappings differ from the manifest")
    with zipfile.ZipFile(io.BytesIO(data)) as archive:
        if sorted(archive.namelist()) != sorted(f"{name}.png" for name in SHEETS + AUXILIARIES):
            raise ValueError("Pack inventory differs from the 33 approved PNGs")
        for name, info in manifest["files"].items():
            image = archive.read(f"{name}.png")
            if digest(image) != info["sha256"] or len(image) != info["bytes"] or dimensions(image) != (info["width"], info["height"]):
                raise ValueError(f"Pack image differs: {name}")
    return {"pngCount": len(manifest["files"]), "itemMappingCount": len(MAPPINGS),
            "unusedSheets": manifest["unusedSheets"], "archiveSha256": manifest["archiveSha256"]}


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--source", type=Path)
    parser.add_argument("--destination", type=Path, default=DESTINATION)
    parser.add_argument("--verify", action="store_true")
    args = parser.parse_args()
    if not args.verify and args.source is None:
        parser.error("--source is required when importing a PSDK pack")
    try:
        if not args.verify:
            import_pack(args.source, args.destination)
        print(json.dumps(verify_pack(args.destination), sort_keys=True))
    except (ValueError, KeyError, OSError, zipfile.BadZipFile) as error:
        parser.exit(1, f"Ball sprite import failed: {error}\n")


if __name__ == "__main__":
    main()
