import argparse
import hashlib
import json
import os
from pathlib import Path
import plistlib
import re
import shutil
import stat
import subprocess
import sys
import zlib


FIXTURE_LICENSE = (
    "Original synthetic fixture created for Avelune Converter qualification.\n"
    "The images are generated colored rectangles, not Pokemon media.\n"
    "The Ruby Marshal data is inert; no Ruby script is included or executed.\n"
    "This is conversion study data, not a certified playable game.\n"
).encode("utf-8")
FORBIDDEN_COMPONENTS = {
    "avelune_studio", "map_runtime", "map_player_ui", "map_render_3d", "flame",
    ".git", ".dart_tool", "node_modules",
}
SECRET_NAMES = {
    ".npmrc", ".netrc", ".pypirc", "id_rsa", "id_dsa", "id_ecdsa",
    "id_ed25519", "authorized_keys", "keychain", "keychain-db",
}
SECRET_PATTERN = re.compile(
    r"(?:^|[._-])(?:tokens?|secrets?|credentials?|password|passwd)(?:[._-]|$)"
)
MEDIA_SUFFIXES = {
    ".png", ".jpg", ".jpeg", ".gif", ".webp", ".bmp", ".ogg", ".wav",
    ".mp3", ".flac", ".mp4", ".mov", ".glb", ".gltf",
}
MAX_NOTICE_BYTES = 64 * 1024 * 1024


class PackageError(Exception):
    pass


def _hash_file(path):
    digest = hashlib.sha256()
    with path.open("rb") as source:
        for block in iter(lambda: source.read(1024 * 1024), b""):
            digest.update(block)
    return digest.hexdigest()


def _json_bytes(value):
    return (json.dumps(value, ensure_ascii=False, sort_keys=True, indent=2) + "\n").encode("utf-8")


def _inside(path, root):
    return path == root or root in path.parents


def _reject_names(relative):
    for part in relative.parts:
        name = part.casefold()
        stem = name.split(".", 1)[0]
        if name in FORBIDDEN_COMPONENTS or stem == "flame" or name.startswith("flame_"):
            raise PackageError(f"Forbidden bundled directory or file: {relative.as_posix()}")
        if (
            name in SECRET_NAMES
            or name == ".env"
            or name.startswith(".env.")
            or SECRET_PATTERN.search(name)
            or Path(name).suffix in {".pem", ".key", ".p12", ".pfx", ".keychain", ".keychain-db"}
        ):
            raise PackageError("A secret or token filename is present in an input")
    lowered = relative.as_posix().casefold()
    if relative.suffix.casefold() in MEDIA_SUFFIXES and any(
        marker in lowered for marker in ("pokemon", "pokémon", "pokemonsdk", "pmon", "kanto", "psdk")
    ):
        raise PackageError(f"Pokemon or PSDK media is forbidden: {relative.as_posix()}")


def _tree_inventory(root):
    entries = []

    def visit(directory):
        for path in sorted(directory.iterdir(), key=lambda item: item.name):
            relative = path.relative_to(root)
            _reject_names(relative)
            attributes = path.lstat()
            entry = {"path": relative.as_posix(), "mode": f"{stat.S_IMODE(attributes.st_mode):04o}"}
            if stat.S_ISLNK(attributes.st_mode):
                target = os.readlink(path)
                if Path(target).is_absolute():
                    raise PackageError(f"An absolute symlink is not relocatable: {relative.as_posix()}")
                immediate = Path(os.path.abspath(path.parent / target))
                if not _inside(immediate, root):
                    raise PackageError(f"Symlink leaves its input: {relative.as_posix()}")
                try:
                    resolved = path.resolve(strict=True)
                except (OSError, RuntimeError) as error:
                    raise PackageError(f"Invalid symlink: {relative.as_posix()}") from error
                if not _inside(resolved, root):
                    raise PackageError(f"Symlink escapes its input: {relative.as_posix()}")
                _reject_names(resolved.relative_to(root))
                entry.update(type="symlink", target=target, resolvedPath=resolved.relative_to(root).as_posix())
            elif stat.S_ISDIR(attributes.st_mode):
                entry["type"] = "directory"
            elif stat.S_ISREG(attributes.st_mode):
                entry.update(type="file", byteLength=attributes.st_size, sha256=_hash_file(path))
            else:
                raise PackageError(f"Special filesystem entry is forbidden: {relative.as_posix()}")
            entries.append(entry)
            if entry["type"] == "directory":
                visit(path)

    visit(root)
    return sorted(entries, key=lambda entry: entry["path"])


def _absolute_existing(path, directory):
    path = Path(path)
    if not path.is_absolute():
        raise PackageError("All four paths must be absolute")
    try:
        resolved = path.resolve(strict=True)
    except (OSError, RuntimeError) as error:
        raise PackageError("An input path does not exist or has an invalid symlink") from error
    if directory and not resolved.is_dir():
        raise PackageError("The app and fixture inputs must be directories")
    if not directory and (path.is_symlink() or not resolved.is_file()):
        raise PackageError("The CLI must be a regular executable file, not a symlink")
    return resolved


def _validate_app(app, entries):
    info = app / "Contents/Info.plist"
    try:
        document = plistlib.loads(info.read_bytes())
        name = document["CFBundleExecutable"]
    except (OSError, ValueError, KeyError, TypeError) as error:
        raise PackageError("The app has no valid Info.plist executable declaration") from error
    if not isinstance(name, str) or not name or Path(name).name != name:
        raise PackageError("The app executable declaration is invalid")
    executable = app / "Contents/MacOS" / name
    if not executable.is_file() or not executable.stat().st_mode & 0o111:
        raise PackageError("The declared app executable is missing or not executable")
    notices = [app / entry["path"] for entry in entries if entry["type"] == "file" and Path(entry["path"]).name == "NOTICES.Z"]
    if not notices:
        raise PackageError("The Flutter bundle must contain its actual NOTICES.Z")
    return notices


def _validate_fixture(fixture, entries):
    license_path = fixture / "FIXTURE_LICENSE.txt"
    if not license_path.is_file() or license_path.stat().st_size != len(FIXTURE_LICENSE) or license_path.read_bytes() != FIXTURE_LICENSE:
        raise PackageError("The fixture must carry the exact original synthetic fixture declaration")
    required = {"FIXTURE_LICENSE.txt", "README.md", "Data/MapInfos.rxdata", "Data/Tilesets.rxdata"}
    found = set()
    map_count = 0
    atlas_count = 0
    allowed_directories = {"Data", "Graphics", "Graphics/Tilesets"}
    for entry in entries:
        relative = entry["path"]
        if entry["type"] == "directory":
            if relative not in allowed_directories:
                raise PackageError(f"Unknown fixture directory: {relative}")
            continue
        if entry["type"] != "file":
            raise PackageError("The original synthetic fixture must contain regular files only")
        found.add(relative)
        if relative in required:
            continue
        if re.fullmatch(r"Data/Map\d{3,}\.rxdata", relative):
            map_count += 1
        elif re.fullmatch(r"Graphics/Tilesets/OriginalAtlas\d+\.png", relative):
            atlas_count += 1
            with (fixture / relative).open("rb") as image:
                if image.read(8) != b"\x89PNG\r\n\x1a\n":
                    raise PackageError("An OriginalAtlas fixture image is not PNG")
        else:
            raise PackageError(f"Unknown fixture file or media: {relative}")
    if not required.issubset(found) or map_count == 0 or atlas_count == 0:
        raise PackageError("The original fixture is incomplete")


def _read_notice(path):
    if path.stat().st_size > MAX_NOTICE_BYTES:
        raise PackageError("Compressed Flutter notices exceed the packaging limit")
    try:
        decoder = zlib.decompressobj(32 + zlib.MAX_WBITS)
        decoded = decoder.decompress(path.read_bytes(), MAX_NOTICE_BYTES + 1)
        if len(decoded) > MAX_NOTICE_BYTES or decoder.unconsumed_tail or not decoder.eof or decoder.unused_data:
            raise PackageError("Flutter notices are truncated, concatenated or exceed the packaging limit")
        decoded.decode("utf-8")
        if not decoded.strip():
            raise PackageError("Flutter notices are empty")
        return decoded
    except (zlib.error, UnicodeDecodeError) as error:
        raise PackageError("Flutter NOTICES.Z cannot be decoded") from error


def _acknowledgements(app, entries):
    files = [app / entry["path"] for entry in entries if entry["type"] == "file" and "acknowledgements" in Path(entry["path"]).name.casefold()]
    for ancestor in list(app.parents)[:8]:
        relative = app.relative_to(ancestor).parts
        if len(relative) != 6 or relative[:4] != ("build", "macos", "Build", "Products") or relative[4] not in {"Release", "Profile", "Debug"}:
            continue
        support = ancestor / "macos/Pods/Target Support Files/Pods-Runner"
        if not support.is_dir():
            break
        support = support.resolve(strict=True)
        if not _inside(support, ancestor):
            raise PackageError("The acknowledgement sidecar directory escapes its Flutter project")
        for path in sorted(support.glob("Pods-Runner-acknowledgements.*")):
            if path.is_symlink() or not path.is_file() or not _inside(path.resolve(strict=True), support):
                raise PackageError("An acknowledgement sidecar is not a regular bounded file")
            _reject_names(Path(path.name))
            files.append(path)
        break
    return list(dict.fromkeys(files))


def _readme(app_name):
    return (
        "Avelune Converter - local private validation archive\n\n"
        f"Open {app_name} on macOS, or run bin/avelune-converter --help.\n"
        "The fixture/ directory is an original synthetic offline conversion study.\n"
        "It contains generated coloured rectangles and inert Ruby Marshal data.\n"
        "No Ruby source scripts or Pokemon media are included in that fixture.\n"
        "A conversion study is not a certified playable game. Native battles use Avelune.\n\n"
        "This archive is for local private validation. It is not a public release,\n"
        "is not notarized by this tool, and has not been uploaded by this tool.\n"
        "No overall repository licence has been established or granted here.\n"
        "notices/ contains the actual decompressed Flutter notices and available\n"
        "CocoaPods acknowledgement files, with their original licence statements.\n"
        "These notices do not grant a licence for the entire application.\n\n"
        "inventory.json and receipt.json are adjacent to the ZIP in the local\n"
        "output directory. The inventory covers every payload file, directory\n"
        "and symlink; the receipt seals that inventory and the native ditto ZIP.\n"
    ).encode("utf-8")


def package_distribution(app, cli, fixture, output):
    declared_app = Path(app)
    if declared_app.suffix != ".app":
        raise PackageError("The app input must have the .app suffix")
    app = _absolute_existing(declared_app, True)
    cli = _absolute_existing(cli, False)
    fixture = _absolute_existing(fixture, True)
    output = Path(output)
    if not output.is_absolute():
        raise PackageError("All four paths must be absolute")
    if os.path.lexists(output):
        raise PackageError("The output directory must be new")
    try:
        output = output.parent.resolve(strict=True) / output.name
    except (OSError, RuntimeError) as error:
        raise PackageError("The output parent must exist") from error
    if output.name in {"", ".", ".."} or output.parent == Path("/"):
        raise PackageError("A local working output directory is required")
    if _inside(output, app) or _inside(output, fixture) or _inside(output, cli):
        raise PackageError("The output must not be inside an input")
    if not cli.stat().st_mode & 0o111:
        raise PackageError("The CLI must be executable")
    _reject_names(Path(cli.name))
    app_entries = _tree_inventory(app)
    fixture_entries = _tree_inventory(fixture)
    notice_paths = _validate_app(app, app_entries)
    _validate_fixture(fixture, fixture_entries)
    notices = [_read_notice(path) for path in notice_paths]
    acknowledgements = _acknowledgements(app, app_entries)
    acknowledgement_entries = [(path, _hash_file(path)) for path in acknowledgements]
    unique_acknowledgements = {}
    for path, expected_hash in acknowledgement_entries:
        existing = unique_acknowledgements.get(path.name)
        if existing is not None and existing[1] != expected_hash:
            raise PackageError("Conflicting acknowledgement basenames cannot be merged")
        unique_acknowledgements[path.name] = (path, expected_hash)
    cli_hash = _hash_file(cli)
    cli_mode = stat.S_IMODE(cli.stat().st_mode)
    if not Path("/usr/bin/ditto").is_file():
        raise PackageError("Native macOS /usr/bin/ditto is required")
    output.mkdir()
    payload = output / "payload/AveluneConverter-local-validation"
    payload.mkdir(parents=True)
    copied_app = payload / declared_app.name
    copied_fixture = payload / "fixture"
    shutil.copytree(app, copied_app, symlinks=True)
    shutil.copytree(fixture, copied_fixture, symlinks=True)
    (payload / "bin").mkdir()
    copied_cli = payload / "bin/avelune-converter"
    shutil.copy2(cli, copied_cli)
    (payload / "README.txt").write_bytes(_readme(declared_app.name))
    notice_directory = payload / "notices"
    notice_directory.mkdir()
    for index, content in enumerate(notices, start=1):
        (notice_directory / f"Flutter-NOTICES-{index}.txt").write_bytes(content)
    for path, expected_hash in unique_acknowledgements.values():
        target = notice_directory / path.name
        shutil.copy2(path, target)
        if _hash_file(target) != expected_hash:
            raise PackageError("An acknowledgement changed during packaging")
    if (
        _tree_inventory(copied_app) != app_entries
        or _tree_inventory(copied_fixture) != fixture_entries
        or _hash_file(copied_cli) != cli_hash
        or stat.S_IMODE(copied_cli.stat().st_mode) != cli_mode
    ):
        raise PackageError("A copied input does not match its original inventory")
    entries = _tree_inventory(payload)
    inventory_path = output / "inventory.json"
    inventory_bytes = _json_bytes({"kind": "localValidationPayloadInventory", "version": 1, "entries": entries})
    inventory_path.write_bytes(inventory_bytes)
    archive = output / "AveluneConverter-local-validation.zip"
    try:
        subprocess.run(
            ["/usr/bin/ditto", "-c", "-k", "--sequesterRsrc", "--keepParent", str(payload), str(archive)],
            check=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE,
        )
    except subprocess.CalledProcessError as error:
        raise PackageError("Native ditto failed to create the validation archive") from error
    if (
        _tree_inventory(payload) != entries
        or _tree_inventory(app) != app_entries
        or _tree_inventory(fixture) != fixture_entries
        or _hash_file(cli) != cli_hash
        or stat.S_IMODE(cli.stat().st_mode) != cli_mode
        or any(_hash_file(path) != expected for path, expected in acknowledgement_entries)
    ):
        raise PackageError("An input or payload changed while the archive was created")
    receipt = {
        "kind": "localPrivateValidationDistribution", "version": 1,
        "payloadPath": str(payload), "archivePath": str(archive),
        "archiveSha256": _hash_file(archive), "archiveBytes": archive.stat().st_size,
        "inventoryPath": str(inventory_path),
        "inventorySha256": hashlib.sha256(inventory_bytes).hexdigest(),
        "fileCount": sum(entry["type"] == "file" for entry in entries),
        "directoryCount": sum(entry["type"] == "directory" for entry in entries),
        "symlinkCount": sum(entry["type"] == "symlink" for entry in entries),
        "flutterNoticeCount": len(notices), "podsAcknowledgementCount": len(unique_acknowledgements),
        "notarized": False, "publiclyUploaded": False, "repositoryLicenseGranted": False,
    }
    (output / "receipt.json").write_bytes(_json_bytes(receipt))
    return receipt


def main():
    parser = argparse.ArgumentParser()
    for name in ("app", "cli", "fixture", "output"):
        parser.add_argument(f"--{name}", required=True, type=Path)
    arguments = parser.parse_args()
    try:
        receipt = package_distribution(
            arguments.app, arguments.cli, arguments.fixture, arguments.output
        )
    except (PackageError, OSError) as error:
        print(str(error), file=sys.stderr)
        return 2
    print(json.dumps(receipt, sort_keys=True))
    return 0


if __name__ == "__main__":
    sys.exit(main())
