#!/usr/bin/env python3
"""Create a portable, evidence-first Markdown brief for one map reference."""

from __future__ import annotations

import argparse
import json
from pathlib import Path

from inventory_assets import image_metadata, sha256_file


def _parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--reference", required=True, type=Path)
    parser.add_argument("--map-id", required=True)
    parser.add_argument("--output", required=True, type=Path)
    parser.add_argument("--inventory", type=Path, help="Optional inventory JSON produced by inventory_assets.py.")
    parser.add_argument("--force", action="store_true")
    return parser


def _inventory_evidence(path: Path | None) -> tuple[str, str]:
    if path is None:
        return "not supplied", "not supplied"
    resolved = path.expanduser().resolve()
    payload = json.loads(resolved.read_text(encoding="utf-8"))
    count = payload.get("summary", {}).get("imageCount", "unknown")
    return resolved.name, f"{sha256_file(resolved)} ({count} images)"


def main() -> int:
    args = _parser().parse_args()
    reference = args.reference.expanduser().resolve()
    output = args.output.expanduser().resolve()
    map_id = args.map_id.strip()
    if not reference.is_file():
        raise SystemExit(f"error: reference does not exist: {reference}")
    if not map_id:
        raise SystemExit("error: --map-id cannot be empty")
    if output == reference:
        raise SystemExit("error: output must not overwrite the reference image")
    if output.exists() and not args.force:
        raise SystemExit(f"error: output already exists (use --force): {output}")
    metadata = image_metadata(reference)
    inventory_name, inventory_evidence = _inventory_evidence(args.inventory)
    width = metadata.get("width", "unknown")
    height = metadata.get("height", "unknown")
    digest = sha256_file(reference)

    # Persist only portable labels and content hashes. The local source path is
    # deliberately absent so the project never depends on one workstation.
    brief = f"""# Reference brief — {map_id}

## Evidence

- Map ID: `{map_id}`
- Reference role: `reference-only` (never a runtime underlay)
- Reference file: `{reference.name}`
- Reference SHA-256: `{digest}`
- Dimensions: `{width}×{height}`
- Asset inventory: `{inventory_name}`
- Inventory SHA-256 / count: `{inventory_evidence}`

## Map contract

- Map role and story moment: TODO
- Map mode (`new` / `rebuild-existing`): TODO
- Native grid size in cells: TODO
- Required entrances, exits, warps, interactions, and reservations: TODO
- Explicit non-goals: TODO

## Scale contract

| Benchmark | Native size | Runtime size | Relationship to player | Evidence |
|---|---:|---:|---|---|
| Project tile | TODO | TODO | TODO | project settings |
| Player sprite/collision | TODO | TODO | reference benchmark | scale-board capture |
| Standard door | TODO | TODO | player fits visually | scale-board capture |
| Representative seat/bed/tree/rail | TODO | TODO | plausible real-world ratio | scale-board capture |

Do not place production assets until the player, a door, and one representative
object from every used size family read coherently in one grid-off scale board.

## Functional topology

| Node | Cell/area | Required approach | Connected from | Blocking/occlusion rule |
|---|---|---|---|---|
| Primary entry | TODO | TODO | n/a | TODO |
| Required destination | TODO | TODO | primary entry | TODO |

- Main player route: TODO
- Intentional one-cell choke points: TODO
- Optional/decorative unreachable areas: TODO
- Collision component and reachability evidence: TODO

## Composition zones

| Zone | Approximate bounds/proportion | Visual purpose | Traversable? | Existing asset candidates |
|---|---|---|---|---|
| TODO | TODO | TODO | TODO | TODO |

## Landmarks and silhouettes

| Priority | Landmark | Approximate position | Footprint/anchor | Reuse, normalize, or gap | Gameplay contract |
|---|---|---|---|---|---|
| P0 | TODO | TODO | TODO | TODO | TODO |

## Navigation and protected cells

- Player route: TODO
- Entrances/exits/connections: TODO
- Door and warp approaches: TODO
- Interaction anchors: TODO
- Environment exclusions and one-cell buffers: TODO
- Foreground occlusion expectations: TODO

## Edge-independence proof

- Full-canvas composite elements: `none` unless an explicit backdrop exception is approved
- Placements outside map bounds: `none`
- Architecture relying on viewport/map clipping: `none`
- One-cell padded-canvas comparison: TODO
- Modular wall, corner, doorway, roof, and foreground pieces: TODO

The padded-canvas comparison must look intentionally complete. Map borders may
bound gameplay space; they must never act as a crop mask for oversized art.

## Asset decisions

| Visual need | Existing candidates checked | Decision | Provenance | Source/output hashes | New asset justification |
|---|---|---|---|---|---|
| TODO | TODO | TODO | TODO | TODO | `none` unless a named gap remains |

## Layer and occlusion plan

| Bottom-to-top layer | Contents | Editable primitive | Collision owner |
|---|---|---|---|
| TODO | TODO | tile / path / environment / placed element | TODO |

Do not replace floors, normal architecture, or furnished rooms with one flattened
map-sized element.

## Environment plan

| Layer/area | Target layer | Preset | Seed | Eligible mask | Protected mask | Coverage target |
|---|---|---|---:|---|---|---|
| TODO | TODO | TODO | TODO | TODO | TODO | TODO |

Regenerate twice and compare placement IDs, element IDs, and positions byte-for-byte.

## Water contract

- Contexts present (open sea / coast / foam / marsh): TODO
- Animation frames, duration, and loop: TODO
- Required inner/outer corners and isolated pools: TODO
- Context composite (rocks, docks, reeds, beach): TODO
- Seam and last-to-first loop evidence: TODO

## Collision and preservation contract

- Existing entities/triggers/zones/events/warps/connections to preserve: TODO
- Required IDs and narrative reservations: TODO
- Existing collision mode (`frozen` / `newly authored`): TODO
- Entrance-to-destination traversal evidence: TODO
- Real EditorNotifier load/save/reload evidence: TODO

## Engine proof

| Proof | Camera/viewport | Scale | Grid | Required result |
|---|---|---:|---|---|
| Native authoring overview | TODO | 1× | off | no clipping, seam, void, or placeholder |
| Scale board | TODO | 1× and runtime | off | player/door/props coherent |
| Collision overlay | full map | native | on | honest footprints and connected route |
| Padded-canvas edge test | +1 cell each side | native | off | composition independent from map crop |
| Actual runtime render | same crop | project display scale | off | matches authoring intent |
| Reference comparison | identical crop | identical | off | reference / candidate side by side |

## Visual review

| Axis | Score (1–5) | Evidence / correction |
|---|---:|---|
| Composition | TODO | TODO |
| Scale coherence | TODO | TODO |
| Style coherence | TODO | TODO |
| Navigation readability | TODO | TODO |
| Place identity | TODO | TODO |
| Edge independence | TODO | TODO |
| Finish | TODO | TODO |

Every axis requires 4/5 or higher plus explicit human approval.
"""
    output.parent.mkdir(parents=True, exist_ok=True)
    output.write_text(brief, encoding="utf-8")
    print(f"Wrote reference brief for {map_id}: {output}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
