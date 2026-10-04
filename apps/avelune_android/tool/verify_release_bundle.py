import argparse
import base64
import hashlib
import json
import re
import struct
import subprocess
import xml.etree.ElementTree as ET
import zipfile
from pathlib import Path


PACKAGE = "com.yoahnl.avelune.player"
ANDROID = "{http://schemas.android.com/apk/res/android}"
ABIS = {"armeabi-v7a", "arm64-v8a", "x86_64"}


def verify_manifest(xml, version_code, version_name):
    root = ET.fromstring(xml)
    expected = {
        "package": PACKAGE,
        ANDROID + "versionCode": str(version_code),
        ANDROID + "versionName": version_name,
    }
    for key, value in expected.items():
        if root.get(key) != value:
            raise ValueError(f"Manifest {key}: expected {value}, got {root.get(key)}")
    sdk = root.find("uses-sdk")
    if sdk is None or sdk.get(ANDROID + "minSdkVersion") != "24" or sdk.get(ANDROID + "targetSdkVersion") != "36":
        raise ValueError("The release must retain minSdk 24 and targetSdk 36")
    app = root.find("application")
    if app is None or app.get(ANDROID + "name") != PACKAGE + ".AveluneApplication":
        raise ValueError("The Kotlin application must own the release")
    if app.get(ANDROID + "debuggable", "false") != "false":
        raise ValueError("The release must not be debuggable")
    launchers = []
    probes = []
    for activity in app.findall("activity"):
        name = activity.get(ANDROID + "name", "")
        for intent in activity.findall("intent-filter"):
            categories = [item.get(ANDROID + "name") for item in intent.findall("category")]
            if "android.intent.category.LAUNCHER" in categories:
                launchers.append(name)
        if "SurfaceProbe" in name:
            probes.append(activity)
    if launchers != [PACKAGE + ".presentation.MainActivity"]:
        raise ValueError("The launcher must be the Kotlin MainActivity")
    if len(probes) != 2 or any(item.get(ANDROID + "enabled") != "false" for item in probes):
        raise ValueError("Both diagnostic activities must be disabled")


def verify_elf_alignment(data):
    if data[:5] != b"\x7fELF\x02" or data[5] not in (1, 2):
        raise ValueError("Expected an ELF64 library")
    endian = "<" if data[5] == 1 else ">"
    offset = struct.unpack_from(endian + "Q", data, 32)[0]
    entry_size, count = struct.unpack_from(endian + "HH", data, 54)
    loads = 0
    for index in range(count):
        entry = offset + entry_size * index
        kind = struct.unpack_from(endian + "I", data, entry)[0]
        if kind != 1:
            continue
        loads += 1
        file_offset, address = struct.unpack_from(endian + "QQ", data, entry + 8)
        alignment = struct.unpack_from(endian + "Q", data, entry + 48)[0]
        if alignment < 16384 or file_offset % 16384 != address % 16384:
            raise ValueError("ELF load segment is not compatible with 16 KB pages")
    if not loads:
        raise ValueError("ELF library has no load segments")


def verify_libraries(bundle):
    files = set(bundle.namelist())
    for abi in sorted(ABIS):
        for name in ("libapp.so", "libflutter.so"):
            if f"base/lib/{abi}/{name}" not in files:
                raise ValueError(f"Missing {abi}/{name}")
    checked = []
    for name in sorted(files):
        if re.fullmatch(r"base/lib/(arm64-v8a|x86_64)/[^/]+\.so", name):
            try:
                verify_elf_alignment(bundle.read(name))
            except (ValueError, struct.error) as error:
                raise ValueError(f"{name}: {error}") from error
            checked.append(name)
    return checked


def certificate_sha256(bundle):
    result = subprocess.run(["jarsigner", "-verify", str(bundle)], capture_output=True, text=True, check=True)
    output = result.stdout + result.stderr
    if "jar verified." not in output or "unsigned entries" in output:
        raise ValueError("The bundle does not have a complete valid JAR signature")
    certificate = subprocess.check_output(["keytool", "-printcert", "-jarfile", str(bundle), "-rfc"], text=True)
    match = re.search(r"-----BEGIN CERTIFICATE-----\s*(.*?)\s*-----END CERTIFICATE-----", certificate, re.S)
    if not match:
        raise ValueError("No upload certificate in the bundle")
    return hashlib.sha256(base64.b64decode(match[1])).hexdigest().upper()


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("bundle", type=Path)
    parser.add_argument("--bundletool", required=True, type=Path)
    parser.add_argument("--version-code", required=True, type=int)
    parser.add_argument("--version-name", required=True)
    parser.add_argument("--certificate-sha256")
    args = parser.parse_args()
    if args.version_code < 3:
        raise ValueError("The replacement version must be newer than Play version 2")
    subprocess.run(["java", "-jar", str(args.bundletool), "validate", f"--bundle={args.bundle}"], capture_output=True, text=True, check=True)
    manifest = subprocess.check_output([
        "java", "-jar", str(args.bundletool), "dump", "manifest", f"--bundle={args.bundle}", "--module=base",
    ], text=True)
    verify_manifest(manifest, args.version_code, args.version_name)
    with zipfile.ZipFile(args.bundle) as bundle:
        libraries = verify_libraries(bundle)
    signer = certificate_sha256(args.bundle) if args.certificate_sha256 else None
    if signer and signer != args.certificate_sha256.replace(":", "").upper():
        raise ValueError("The bundle was not signed with the existing Play upload key")
    with args.bundle.open("rb") as stream:
        digest = hashlib.file_digest(stream, "sha256").hexdigest()
    print(json.dumps({
        "package": PACKAGE, "versionCode": args.version_code, "versionName": args.version_name,
        "abis": sorted(ABIS), "alignedLibraries": libraries, "uploadCertificateSha256": signer,
        "bundleSha256": digest, "bundleBytes": args.bundle.stat().st_size,
    }, indent=2))


if __name__ == "__main__":
    main()
