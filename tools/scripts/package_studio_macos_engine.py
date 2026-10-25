import argparse
import hashlib
import json
import os
import plistlib
import re
import shutil
import subprocess
import sys
import tempfile
from pathlib import Path


class PackagingError(RuntimeError):
    pass


def contained(path, root):
    return path == root or root in path.parents


def canonical_directory(value, label):
    path = Path(value).absolute()
    if not path.is_dir() or path.is_symlink() or path.resolve() != path:
        raise PackagingError(f"{label} must be an existing canonical directory: {path}")
    return path


def validate_links(root):
    for directory, directories, files in os.walk(root, followlinks=False):
        for name in directories + files:
            entry = Path(directory) / name
            if entry.is_symlink():
                if Path(os.readlink(entry)).is_absolute():
                    raise PackagingError(f"Absolute bundle symlink is not portable: {entry}")
                try:
                    resolved = entry.resolve(strict=True)
                except (OSError, RuntimeError) as error:
                    raise PackagingError(f"Invalid symlink: {entry}") from error
                if not contained(resolved, root):
                    raise PackagingError(f"Symlink escapes its bundle: {entry}")
            elif not entry.is_dir() and not entry.is_file():
                raise PackagingError(f"Unsupported bundle entry: {entry}")


def sha256(path):
    digest = hashlib.sha256()
    with path.open("rb") as source:
        for chunk in iter(lambda: source.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def tree_digest(root):
    entries = {}
    for entry in sorted(root.rglob("*")):
        relative = entry.relative_to(root).as_posix()
        if entry.is_symlink():
            entries[relative] = {"symlink": os.readlink(entry)}
        elif entry.is_file():
            entries[relative] = {"sha256": sha256(entry)}
    payload = json.dumps(entries, sort_keys=True, separators=(",", ":")).encode()
    return {"sha256": hashlib.sha256(payload).hexdigest(), "entries": entries}


def dart_revision(root):
    deps = root / "DEPS"
    if not deps.is_file() or not contained(deps.resolve(), root):
        raise PackagingError(f"Missing Flutter DEPS: {deps}")
    matches = re.findall(
        r"""['"]dart_revision['"]\s*:\s*['"]([0-9a-f]{40})['"]""",
        deps.read_text(),
    )
    if len(matches) != 1:
        raise PackagingError(f"Expected one pinned Dart revision in {deps}")
    return matches[0]


def validate_source(root):
    source = root / "engine/src/flutter/shell/platform/darwin/macos/framework/Source/FlutterSurfaceManager.mm"
    if not source.is_file() or not contained(source.resolve(), root):
        raise PackagingError("Missing canonical FlutterSurfaceManager.mm")
    text = source.read_text()
    text = re.sub(r"/\*.*?\*/|//[^\n]*", "", text, flags=re.DOTALL)
    method = re.search(
        r"-\s*\(void\)\s*presentSurfaces:.*?\{(.*?)CGSize\s+size\s*=",
        text,
        re.DOTALL,
    )
    if method is None or re.search(
        r"\[commandBuffer\s+commit\]\s*;\s*\[commandBuffer\s+waitUntilCompleted\]\s*;",
        method.group(1),
    ) is None:
        raise PackagingError("The presentation completion fence is missing from the engine source")
    return source


def run_checked(command, commands, runner):
    command = [str(argument) for argument in command]
    result = runner(command, capture_output=True, text=True, check=False)
    commands.append({"argv": command, "exitCode": result.returncode})
    if result.returncode != 0:
        raise PackagingError(
            f"Command failed ({result.returncode}): {command[0]}\n{result.stderr.strip()}"
        )
    return result.stdout


def architectures(binary, commands, runner):
    result = run_checked(["lipo", "-archs", binary], commands, runner)
    values = set(result.strip().split())
    if not values or not values <= {"arm64", "arm64e", "x86_64", "i386"}:
        raise PackagingError(f"Unrecognized architectures for {binary}: {result!r}")
    return values


def strip_signing_attributes(root, commands, runner):
    listing = run_checked(["xattr", "-r", "-s", root], commands, runner)
    allowed = {"com.apple.FinderInfo", "com.apple.ResourceFork"}
    targets = set()
    for line in listing.splitlines():
        raw_path, separator, attribute = line.rpartition(": ")
        if not separator or attribute not in allowed:
            continue
        path = Path(raw_path)
        if not path.is_absolute() or not contained(path, root):
            raise PackagingError("Attribute listing points outside the staged app")
        if path.is_symlink():
            continue
        if not path.exists() or not contained(path.resolve(), root):
            raise PackagingError("Attribute target escaped the staged app")
        targets.add((path, attribute))
    removed = []
    for path, attribute in sorted(targets):
        run_checked(["xattr", "-d", "-s", attribute, path], commands, runner)
        removed.append({
            "path": path.relative_to(root).as_posix(),
            "attribute": attribute,
        })
    return removed


def package_app(
    *,
    app,
    output,
    framework,
    engine_source,
    producer_flutter_sdk,
    mode,
    runner=subprocess.run,
):
    if mode not in {"debug", "profile", "release"}:
        raise PackagingError("An explicit debug, profile or release mode is required")
    app = canonical_directory(app, "Input app")
    framework = canonical_directory(framework, "Replacement framework")
    engine_source = canonical_directory(engine_source, "Engine source")
    producer_flutter_sdk = canonical_directory(producer_flutter_sdk, "Producer Flutter SDK")
    output = Path(output).absolute()
    if app.suffix != ".app" or framework.name != "FlutterMacOS.framework":
        raise PackagingError("Expected an input .app and a FlutterMacOS.framework")
    if output.suffix != ".app" or os.path.lexists(output):
        raise PackagingError("Output must be a new, absent .app")
    if not output.parent.is_dir() or output.parent.resolve() != output.parent:
        raise PackagingError("Output parent must be an existing canonical directory")
    if "Applications" in output.parts or any(
        contained(output, root)
        for root in (app, framework, engine_source, producer_flutter_sdk)
    ) or any(
        (ancestor / "bin/flutter").is_file() and (ancestor / "DEPS").is_file()
        for ancestor in output.parents
    ):
        raise PackagingError("Output must be outside Applications, the source app and SDK/source trees")
    validate_links(app)
    validate_links(framework)
    info_path = app / "Contents/Info.plist"
    try:
        info = plistlib.loads(info_path.read_bytes())
    except (OSError, plistlib.InvalidFileException) as error:
        raise PackagingError(f"Invalid app Info.plist: {info_path}") from error
    executable = info.get("CFBundleExecutable")
    if not isinstance(executable, str) or not executable or Path(executable).name != executable:
        raise PackagingError("The app must declare a simple CFBundleExecutable")
    app_binary = app / "Contents/MacOS" / executable
    old_framework = app / "Contents/Frameworks/FlutterMacOS.framework"
    framework_binary = framework / "FlutterMacOS"
    if not app_binary.is_file() or not old_framework.is_dir() or not framework_binary.is_file():
        raise PackagingError("The app or replacement Flutter framework is incomplete")
    source = validate_source(engine_source)
    engine_dart = dart_revision(engine_source)
    producer_dart = dart_revision(producer_flutter_sdk)
    if engine_dart != producer_dart:
        raise PackagingError("Dart revision differs between the engine and producer Flutter SDK")
    commands = []
    app_architectures = architectures(app_binary, commands, runner)
    framework_architectures = architectures(framework_binary, commands, runner)
    if not app_architectures <= framework_architectures:
        raise PackagingError(
            f"Framework architectures {sorted(framework_architectures)} do not cover "
            f"the app architectures {sorted(app_architectures)}"
        )
    entitlements_text = run_checked(
        ["codesign", "-d", "--entitlements", ":-", app], commands, runner
    )
    try:
        entitlements = plistlib.loads(entitlements_text.encode()) if entitlements_text.strip() else {}
    except plistlib.InvalidFileException as error:
        raise PackagingError("Input app entitlements could not be decoded") from error
    if not isinstance(entitlements, dict):
        raise PackagingError("Input app entitlements must be a dictionary")
    engine_revision = run_checked(
        ["git", "-C", engine_source, "rev-parse", "HEAD"], commands, runner
    ).strip()
    producer_revision = run_checked(
        ["git", "-C", producer_flutter_sdk, "rev-parse", "HEAD"], commands, runner
    ).strip()
    if not all(re.fullmatch(r"[0-9a-f]{40}", value) for value in (engine_revision, producer_revision)):
        raise PackagingError("Could not determine immutable source revisions")
    original_binary_hash = sha256(app_binary)
    original_framework = tree_digest(old_framework)
    replacement_framework = tree_digest(framework)
    staging_root = Path(tempfile.mkdtemp(prefix=f".{output.stem}.engine-", dir=output.parent))
    try:
        staged_app = staging_root / output.name
        shutil.copytree(app, staged_app, symlinks=True)
        staged_framework = staged_app / "Contents/Frameworks/FlutterMacOS.framework"
        if staged_framework.is_symlink():
            staged_framework.unlink()
        else:
            shutil.rmtree(staged_framework)
        shutil.copytree(framework, staged_framework, symlinks=True)
        if tree_digest(staged_framework) != replacement_framework:
            raise PackagingError("Replacement framework changed while it was copied")
        removed_attributes = strip_signing_attributes(staged_app, commands, runner)
        run_checked(["codesign", "--force", "--sign", "-", staged_framework], commands, runner)
        entitlements_path = staging_root / "preserved-entitlements.plist"
        entitlements_path.write_bytes(plistlib.dumps(entitlements, sort_keys=True))
        sign_command = [
            "codesign", "--force", "--sign", "-",
            "--preserve-metadata=identifier,flags,runtime",
            "--entitlements", str(entitlements_path), str(staged_app),
        ]
        verify_command = ["codesign", "--verify", "--deep", "--strict", str(staged_app)]
        inspect_command = ["codesign", "-d", "--entitlements", ":-", str(staged_app)]
        receipt = {
            "schemaVersion": 1,
            "purpose": "isolated macOS Studio native engine packaging",
            "inputApp": str(app),
            "outputApp": str(output),
            "mode": mode,
            "modeSource": "explicit caller argument; runtime compatibility requires a separate launch test",
            "engineSource": str(engine_source),
            "engineRevision": engine_revision,
            "producerFlutterSdk": str(producer_flutter_sdk),
            "producerFlutterRevision": producer_revision,
            "dartRevision": engine_dart,
            "presentationSource": str(source),
            "presentationSourceSha256": sha256(source),
            "inputAppExecutableSha256": original_binary_hash,
            "originalFramework": original_framework,
            "replacementFramework": replacement_framework,
            "packagedFramework": tree_digest(staged_framework),
            "appArchitectures": sorted(app_architectures),
            "frameworkArchitectures": sorted(framework_architectures),
            "entitlementsPlistSha256": sha256(entitlements_path),
            "entitlementKeys": sorted(entitlements),
            "signing": "ad-hoc",
            "removedSigningAttributes": removed_attributes,
            "publicationRule": "published only after the final signing and verification commands succeed",
            "provenanceLimit": "source fence and binary hashes are verified separately; retain the engine build receipt to attest that this binary came from this checkout",
            "costScope": "local opt-in packaging only; no download, SDK mutation, Flutter build or CI scheduling",
            "commands": commands + [
                {"argv": sign_command, "requiredExitCode": 0},
                {"argv": verify_command, "requiredExitCode": 0},
                {"argv": inspect_command, "requiredExitCode": 0},
            ],
        }
        receipt_path = staged_app / "Contents/Resources/avelune-native-engine-receipt.json"
        receipt_path.parent.mkdir(parents=True, exist_ok=True)
        receipt_path.write_text(json.dumps(receipt, indent=2, sort_keys=True) + "\n")
        run_checked(sign_command, commands, runner)
        run_checked(verify_command, commands, runner)
        packaged_entitlements_text = run_checked(inspect_command, commands, runner)
        packaged_entitlements = (
            plistlib.loads(packaged_entitlements_text.encode())
            if packaged_entitlements_text.strip()
            else {}
        )
        if packaged_entitlements != entitlements:
            raise PackagingError("The packaged app did not retain its original entitlements")
        if sha256(app_binary) != original_binary_hash or tree_digest(old_framework) != original_framework:
            raise PackagingError("The input app changed during packaging")
        if os.path.lexists(output):
            raise PackagingError("Output appeared during packaging; refusing replacement")
        os.replace(staged_app, output)
        return receipt
    finally:
        shutil.rmtree(staging_root)


def main(argv=None):
    parser = argparse.ArgumentParser()
    for name in ("app", "output", "framework", "engine-source", "producer-flutter-sdk"):
        parser.add_argument(f"--{name}", required=True, type=Path)
    parser.add_argument("--mode", required=True, choices=("debug", "profile", "release"))
    arguments = parser.parse_args(argv)
    try:
        receipt = package_app(**vars(arguments))
    except (PackagingError, OSError, subprocess.SubprocessError) as error:
        print(str(error), file=sys.stderr)
        return 1
    print(json.dumps({
        "outputApp": receipt["outputApp"],
        "mode": receipt["mode"],
        "receipt": str(Path(receipt["outputApp"]) / "Contents/Resources/avelune-native-engine-receipt.json"),
    }, indent=2))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
