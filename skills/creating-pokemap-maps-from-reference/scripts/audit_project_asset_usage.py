#!/usr/bin/env python3
"""Build or apply a hash-locked PokeMap asset-usage manifest."""

from __future__ import annotations

import argparse
import hashlib
import json
from collections import defaultdict, deque
from pathlib import Path
from typing import Any, Iterable


def _sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as stream:
        for chunk in iter(lambda: stream.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def _canonical_hash(payload: dict[str, Any]) -> str:
    encoded = json.dumps(
        payload, sort_keys=True, ensure_ascii=False, separators=(",", ":")
    ).encode("utf-8")
    return hashlib.sha256(encoded).hexdigest()


def _walk_strings(value: Any) -> Iterable[str]:
    if isinstance(value, str):
        yield value
    elif isinstance(value, list):
        for item in value:
            yield from _walk_strings(item)
    elif isinstance(value, dict):
        for item in value.values():
            yield from _walk_strings(item)


def _load_json(path: Path) -> Any:
    try:
        return json.loads(path.read_text(encoding="utf-8"))
    except (OSError, UnicodeDecodeError, json.JSONDecodeError) as error:
        raise SystemExit(f"error: cannot decode JSON {path}: {error}") from error


def _relative_asset_reference(
    value: str, *, project_root: Path, asset_root: Path
) -> str | None:
    normalized = value.replace("\\", "/").strip()
    if not normalized or "://" in normalized:
        return None
    candidate = (project_root / normalized).resolve()
    try:
        return candidate.relative_to(asset_root).as_posix()
    except ValueError:
        return None


def _catalog_entries(project: dict[str, Any]) -> tuple[dict[str, list[tuple[str, dict[str, Any]]]], list[tuple[str, dict[str, Any]]]]:
    by_id: dict[str, list[tuple[str, dict[str, Any]]]] = defaultdict(list)
    entries: list[tuple[str, dict[str, Any]]] = []
    for catalog, value in project.items():
        if not isinstance(value, list):
            continue
        for item in value:
            if not isinstance(item, dict):
                continue
            identifier = item.get("id")
            if not isinstance(identifier, str) or not identifier.strip():
                continue
            record = (catalog, item)
            entries.append(record)
            by_id[identifier.strip()].append(record)
    return by_id, entries


def _runtime_graph(
    project_root: Path, asset_root: Path
) -> tuple[dict[str, set[str]], set[str]]:
    project_file = project_root / "project.json"
    if not project_file.is_file():
        raise SystemExit(f"error: missing PokeMap manifest: {project_file}")
    project = _load_json(project_file)
    if not isinstance(project, dict):
        raise SystemExit("error: project.json root must be an object")
    runtime_files: list[Path] = []
    for directory_name in ("maps", "data", "dialogues"):
        directory = project_root / directory_name
        if directory.is_dir():
            runtime_files.extend(directory.rglob("*.json"))
    runtime_files.sort(key=lambda path: path.relative_to(project_root).as_posix())
    runtime_values = [(path, _load_json(path)) for path in runtime_files]
    by_id, _ = _catalog_entries(project)
    by_runtime_token: dict[str, set[str]] = defaultdict(set)
    for identifier, records in by_id.items():
        for _, entry in records:
            # Terrain layers persist semantic terrain symbols rather than a
            # terrain-preset ID. Surface families can follow the same pattern.
            # Index only these explicit selector fields; indexing every string
            # (for example "global" or a display name) would protect unrelated
            # stale catalogs and make the cleanup report useless.
            for selector in ("terrainType", "surfaceKind"):
                token = entry.get(selector)
                if isinstance(token, str) and token.strip():
                    by_runtime_token[token.strip()].add(identifier)

    # Seed the graph from authored maps, then follow project catalog IDs. This
    # avoids treating every stale manifest entry as runtime-used merely because
    # it still exists in project.json.
    queue: deque[str] = deque()
    seen_ids: set[str] = set()
    file_referrers: dict[str, set[str]] = defaultdict(set)
    for runtime_file, value in runtime_values:
        label = runtime_file.relative_to(project_root).as_posix()
        for string in _walk_strings(value):
            if string in by_id and string not in seen_ids:
                queue.append(string)
            for identifier in by_runtime_token.get(string, set()):
                if identifier not in seen_ids:
                    queue.append(identifier)
            asset = _relative_asset_reference(
                string, project_root=project_root, asset_root=asset_root
            )
            if asset is not None:
                file_referrers[asset].add(label)

    # Root settings can reference global files without a catalog entry.
    for key, value in project.items():
        if isinstance(value, list):
            continue
        for string in _walk_strings(value):
            asset = _relative_asset_reference(
                string, project_root=project_root, asset_root=asset_root
            )
            if asset is not None:
                file_referrers[asset].add(f"project.json#{key}")

    used_records: set[tuple[str, str]] = set()
    while queue:
        identifier = queue.popleft()
        if identifier in seen_ids:
            continue
        seen_ids.add(identifier)
        for catalog, entry in by_id.get(identifier, []):
            record_key = (catalog, identifier)
            if record_key in used_records:
                continue
            used_records.add(record_key)
            label = f"project.json#{catalog}/{identifier}"
            for string in _walk_strings(entry):
                if string in by_id and string not in seen_ids:
                    queue.append(string)
                for referenced_id in by_runtime_token.get(string, set()):
                    if referenced_id not in seen_ids:
                        queue.append(referenced_id)
                asset = _relative_asset_reference(
                    string, project_root=project_root, asset_root=asset_root
                )
                if asset is not None:
                    file_referrers[asset].add(label)
    return file_referrers, seen_ids


def _atlas_source_names(asset_root: Path) -> tuple[set[str], str | None]:
    layout = asset_root / "ATLAS_LAYOUTS.json"
    if not layout.is_file():
        return set(), None
    value = _load_json(layout)
    names: set[str] = set()
    atlases = value.get("atlases", {}) if isinstance(value, dict) else {}
    if isinstance(atlases, dict):
        for atlas in atlases.values():
            if not isinstance(atlas, dict):
                continue
            for item in atlas.get("items", []):
                if isinstance(item, dict) and isinstance(item.get("file"), str):
                    names.add(Path(item["file"]).name)
    return names, "ATLAS_LAYOUTS.json"


def _manifest_asset_references(
    project_root: Path, asset_root: Path
) -> dict[str, set[str]]:
    """Return every catalog registration, including currently unreachable ones."""
    project = _load_json(project_root / "project.json")
    references: dict[str, set[str]] = defaultdict(set)
    if not isinstance(project, dict):
        return references
    for catalog, value in project.items():
        if not isinstance(value, list):
            continue
        for index, entry in enumerate(value):
            if not isinstance(entry, dict):
                continue
            identifier = entry.get("id")
            label = f"project.json#{catalog}/{identifier or index}"
            for string in _walk_strings(entry):
                asset = _relative_asset_reference(
                    string, project_root=project_root, asset_root=asset_root
                )
                if asset is not None:
                    references[asset].add(label)
    return references


def _text_references(root: Path, asset_paths: list[str]) -> dict[str, set[str]]:
    references: dict[str, set[str]] = defaultdict(set)
    if not root.exists():
        return references
    needles = {path: (path, Path(path).name) for path in asset_paths}
    for source in sorted(path for path in root.rglob("*") if path.is_file()):
        if source.stat().st_size > 5 * 1024 * 1024:
            continue
        try:
            text = source.read_text(encoding="utf-8")
        except (OSError, UnicodeDecodeError):
            continue
        label = source.relative_to(root).as_posix()
        for asset, variants in needles.items():
            if any(variant in text for variant in variants):
                references[asset].add(label)
    return references


def _scan_root_fingerprint(root: Path) -> dict[str, Any]:
    if not root.is_dir() or root.is_symlink():
        raise SystemExit(f"error: scan root must be a real directory: {root}")
    digest = hashlib.sha256()
    count = 0
    for path in sorted(root.rglob("*"), key=lambda entry: entry.as_posix()):
        if path.is_symlink():
            raise SystemExit(f"error: symlinks are forbidden in scan roots: {path}")
        if not path.is_file():
            continue
        relative = path.relative_to(root).as_posix()
        digest.update(relative.encode("utf-8"))
        digest.update(b"\0")
        digest.update(str(path.stat().st_size).encode("ascii"))
        digest.update(b"\0")
        digest.update(_sha256(path).encode("ascii"))
        digest.update(b"\n")
        count += 1
    return {"label": root.name, "fileCount": count, "sha256": digest.hexdigest()}


def _resolve_asset_root(project_root: Path, value: str) -> Path:
    relative = Path(value)
    if relative.is_absolute() or ".." in relative.parts:
        raise SystemExit("error: asset root must be relative and cannot contain '..'")
    cursor = project_root
    for part in relative.parts:
        cursor = cursor / part
        if cursor.is_symlink():
            raise SystemExit(f"error: asset root cannot traverse a symlink: {cursor}")
    resolved = cursor.resolve()
    try:
        resolved.relative_to(project_root)
    except ValueError as error:
        raise SystemExit("error: asset root escapes project root") from error
    return resolved


def _all_asset_files(asset_root: Path) -> list[Path]:
    files: list[Path] = []
    for path in asset_root.rglob("*"):
        # Following a symlink would let the manifest hash and later unlink
        # describe a target outside the reviewed asset tree. Reject the whole
        # audit instead of silently skipping or resolving it.
        if path.is_symlink():
            raise SystemExit(f"error: symlinks are forbidden in asset roots: {path}")
        if path.is_file() and path.name != ".DS_Store":
            files.append(path)
    return sorted(files, key=lambda path: path.relative_to(asset_root).as_posix())


def build_manifest(
    *,
    project_root: Path,
    asset_root: Path,
    test_roots: list[Path],
    reference_roots: list[Path],
) -> dict[str, Any]:
    files = _all_asset_files(asset_root)
    relative_paths = [path.relative_to(asset_root).as_posix() for path in files]
    runtime_refs, used_ids = _runtime_graph(project_root, asset_root)
    manifest_refs = _manifest_asset_references(project_root, asset_root)
    atlas_names, layout_label = _atlas_source_names(asset_root)
    test_refs: dict[str, set[str]] = defaultdict(set)
    reference_refs: dict[str, set[str]] = defaultdict(set)
    test_root_evidence = [_scan_root_fingerprint(root) for root in test_roots]
    reference_root_evidence = [
        _scan_root_fingerprint(root) for root in reference_roots
    ]
    for root in test_roots:
        for asset, refs in _text_references(root, relative_paths).items():
            test_refs[asset].update(f"{root.name}:{ref}" for ref in refs)
    for root in reference_roots:
        for asset, refs in _text_references(root, relative_paths).items():
            reference_refs[asset].update(f"{root.name}:{ref}" for ref in refs)

    entries: list[dict[str, Any]] = []
    counts: dict[str, int] = defaultdict(int)
    for path, relative in zip(files, relative_paths):
        references: set[str] = set()
        if relative in runtime_refs:
            classification = "runtime-used"
            references.update(runtime_refs[relative])
        elif "source" in Path(relative).parts and path.name in atlas_names:
            classification = "atlas-source-used"
            if layout_label:
                references.add(layout_label)
        elif relative == "ATLAS_LAYOUTS.json":
            classification = "atlas-source-used"
            references.add("atlas build root")
        elif relative in test_refs:
            classification = "test-only"
            references.update(test_refs[relative])
        elif relative in reference_refs:
            classification = "reference-retained"
            references.update(reference_refs[relative])
        elif relative in manifest_refs:
            # A registered-but-unreachable asset needs an explicit manifest
            # entry removal and engine-convention review. Never promote it to
            # automatic deletion based only on a generic string graph.
            classification = "reference-retained"
            references.update(
                f"{ref} (catalog entry currently unreachable)"
                for ref in manifest_refs[relative]
            )
        elif path.suffix.lower() in {".md", ".txt"}:
            classification = "reference-retained"
            references.add("project asset documentation")
        else:
            classification = "delete"
        counts[classification] += 1
        entries.append(
            {
                "path": relative,
                "classification": classification,
                "sizeBytes": path.stat().st_size,
                "sha256": _sha256(path),
                "references": sorted(references),
            }
        )

    payload: dict[str, Any] = {
        "schemaVersion": 1,
        "projectRootLabel": project_root.name,
        "assetRoot": asset_root.relative_to(project_root).as_posix(),
        "summary": {
            "fileCount": len(entries),
            "usedCatalogIdCount": len(used_ids),
            **{key: counts[key] for key in sorted(counts)},
        },
        "scanRoots": {
            "test": sorted(
                test_root_evidence,
                key=lambda entry: (entry["label"], entry["sha256"]),
            ),
            "reference": sorted(
                reference_root_evidence,
                key=lambda entry: (entry["label"], entry["sha256"]),
            ),
        },
        "files": entries,
    }
    return {**payload, "manifestSha256": _canonical_hash(payload)}


def _write_manifest(path: Path, manifest: dict[str, Any], force: bool) -> None:
    if path.exists() and not force:
        raise SystemExit(f"error: manifest exists (use --force): {path}")
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(
        json.dumps(manifest, indent=2, ensure_ascii=False) + "\n", encoding="utf-8"
    )


def _apply_manifest(
    *,
    project_root: Path,
    manifest_path: Path,
    expected_sha256: str,
    test_roots: list[Path],
    reference_roots: list[Path],
) -> int:
    manifest = _load_json(manifest_path)
    if not isinstance(manifest, dict):
        raise SystemExit("error: cleanup manifest root must be an object")
    stored_hash = manifest.get("manifestSha256")
    payload = {key: value for key, value in manifest.items() if key != "manifestSha256"}
    actual_hash = _canonical_hash(payload)
    if stored_hash != actual_hash or expected_sha256 != actual_hash:
        raise SystemExit(
            "error: manifest hash mismatch; rerun dry-run and review the new candidate list"
        )
    asset_root_value = manifest.get("assetRoot")
    if not isinstance(asset_root_value, str):
        raise SystemExit("error: manifest assetRoot is invalid")
    asset_root = _resolve_asset_root(project_root, asset_root_value)

    current = build_manifest(
        project_root=project_root,
        asset_root=asset_root,
        test_roots=test_roots,
        reference_roots=reference_roots,
    )
    if current.get("scanRoots") != manifest.get("scanRoots"):
        raise SystemExit(
            "error: apply must use the same --test-root and --reference-root labels as dry-run"
        )
    current_by_path = {
        entry["path"]: entry
        for entry in current.get("files", [])
        if isinstance(entry, dict) and isinstance(entry.get("path"), str)
    }

    candidates = [
        entry
        for entry in manifest.get("files", [])
        if isinstance(entry, dict) and entry.get("classification") == "delete"
    ]
    resolved: list[tuple[Path, dict[str, Any]]] = []
    for entry in candidates:
        relative = entry.get("path")
        if not isinstance(relative, str):
            raise SystemExit("error: invalid candidate path")
        path = (asset_root / relative).resolve()
        try:
            path.relative_to(asset_root)
        except ValueError as error:
            raise SystemExit(f"error: candidate escapes asset root: {relative}") from error
        if not path.is_file():
            raise SystemExit(f"error: candidate is missing: {relative}")
        current_entry = current_by_path.get(relative)
        if current_entry is None or current_entry.get("classification") != "delete":
            current_classification = (
                current_entry.get("classification") if current_entry else "missing"
            )
            raise SystemExit(
                f"error: candidate became {current_classification} after review: {relative}"
            )
        if path.stat().st_size != entry.get("sizeBytes") or _sha256(path) != entry.get("sha256"):
            raise SystemExit(f"error: candidate changed after review: {relative}")
        resolved.append((path, entry))

    # Validation above is intentionally complete before the first unlink, so
    # a stale manifest cannot produce a partially applied deletion batch.
    for path, _ in resolved:
        path.unlink()
    print(f"Deleted {len(resolved)} hash-locked assets from {asset_root}")
    return 0


def _parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--project-root", required=True, type=Path)
    parser.add_argument("--asset-root", default="assets")
    mode = parser.add_mutually_exclusive_group(required=True)
    mode.add_argument("--dry-run", action="store_true")
    mode.add_argument("--apply", action="store_true")
    parser.add_argument("--manifest", required=True, type=Path)
    parser.add_argument("--expected-sha256")
    parser.add_argument("--test-root", action="append", default=[], type=Path)
    parser.add_argument("--reference-root", action="append", default=[], type=Path)
    parser.add_argument("--force", action="store_true")
    return parser


def main() -> int:
    args = _parser().parse_args()
    project_root = args.project_root.expanduser().resolve()
    if not project_root.is_dir():
        raise SystemExit(f"error: project root does not exist: {project_root}")
    manifest_path = args.manifest.expanduser().resolve()
    if args.apply:
        if not args.expected_sha256:
            raise SystemExit("error: --apply requires --expected-sha256")
        return _apply_manifest(
            project_root=project_root,
            manifest_path=manifest_path,
            expected_sha256=args.expected_sha256,
            test_roots=[path.expanduser().resolve() for path in args.test_root],
            reference_roots=[path.expanduser().resolve() for path in args.reference_root],
        )

    asset_root = _resolve_asset_root(project_root, args.asset_root)
    if not asset_root.is_dir():
        raise SystemExit(f"error: asset root does not exist: {asset_root}")
    try:
        manifest_path.relative_to(asset_root)
    except ValueError:
        pass
    else:
        raise SystemExit("error: cleanup manifest must be written outside the asset root")
    manifest = build_manifest(
        project_root=project_root,
        asset_root=asset_root,
        test_roots=[path.expanduser().resolve() for path in args.test_root],
        reference_roots=[path.expanduser().resolve() for path in args.reference_root],
    )
    _write_manifest(manifest_path, manifest, args.force)
    deletions = [
        entry["path"]
        for entry in manifest["files"]
        if entry["classification"] == "delete"
    ]
    print(json.dumps(manifest["summary"], ensure_ascii=False, sort_keys=True))
    print(f"manifestSha256={manifest['manifestSha256']}")
    for path in deletions:
        print(f"DELETE {path}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
