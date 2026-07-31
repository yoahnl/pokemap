---
name: creating-pokemap-maps-from-reference
description: Use when authoring, rebuilding, or reviewing an editable PokeMap map from a screenshot, concept image, bible, mockup, or full-map render, especially after attempts with incoherent scale, broken circulation, edge clipping, giant composite assets, empty voids, or poor visual quality.
---

# Creating PokeMap Maps From Reference

## Overview

Translate visual intent into a coherent playable place, never into a pasted picture.
Require three truths at once: spatial logic, visual credibility at player scale, and
native PokeMap editability.

**REQUIRED SUB-SKILL:** Use `using-pokemap-mcp` for project inspection, authoring,
validation, rendering, and MCP parity handling. Do not edit project JSON directly when
the canonical MCP contract supports the operation.

## Required references

Before authoring, read:

1. `references/map-quality-gates.md` for composition, scale, anti-cheat rules, and evidence.
2. `references/pokemap-contract.md` for PokeMap serialization, layers, collisions, and bounds.

Read `references/visual-acceptance.md` before the first visual review.

## Reference interpretation

A reference image is a design and composition brief by default, not a
pixel-for-pixel blueprint. Extract its useful rules: room identity, functional
zones, proportions, circulation, visual hierarchy, palette, material language,
decorative density, and the relationship between the player and the scenery.

Preserve those intentions, but adapt the layout when doing so improves gameplay
clarity, believable use, modularity, or native PokeMap authoring. Moving a prop,
opening a route, changing an empty margin, or rebuilding a wall from reusable
modules is valid when the result remains faithful to the place. Exact spatial or
pixel matching is required only when the owner explicitly asks for it.

A reference must never become a full-map runtime layer merely to reproduce its
appearance. Reconstruct the place with surfaces, borders, openings, architecture,
props, collisions, and occlusion layers that remain independently editable.

## Iron laws

- Never ship a complete reference render as a runtime underlay.
- Never use map or viewport boundaries as a crop mask.
- Never use one full-canvas placed element to impersonate normal floors, walls,
  architecture, vegetation, or a furnished room.
- Never place production scenery before proving player/door/prop scale in one scale board.
- Never decorate before drawing entrances, destinations, approaches, and a connected route.
- Never call a script preview sufficient; inspect an actual editor render and runtime render.
- Never hide missing assets with black voids, oversized sprites, clipping, or unexplained emptiness.
- Never claim artistic success from valid JSON, hashes, test counts, or human politeness.

An explicit owner-approved backdrop exception may waive the full-canvas rule. Record
the element ID and reason; it never waives bounds, navigation, or runtime proof.

## Workflow

### 1. Establish the contract

Classify the task as `new` or `rebuild-existing`. For a rebuild, preserve gameplay
contracts unless the user scopes changes. For a new map, author collisions and routes
from the approved floor plan; do not pretend an absent collision contract is frozen.

Inventory the reference, bibles, scale guide, project settings, player sprite, existing
assets, current map data, and required story interactions. Generate the brief:

```bash
python3 skills/creating-pokemap-maps-from-reference/scripts/create_reference_brief.py \
  --reference <reference.png> --map-id <id> --inventory <inventory.json> \
  --output <brief.md>
```

Stop while any required brief field is `TODO`.

### 2. Pass scale and topology gates

Create the grid-off scale board required by `map-quality-gates.md`. Reject implausible
player/door/furniture/building/rail relationships before map assembly.

Draw the functional graph next: entries, exits, interactions, story reservations,
main route, optional branches, occluders, and collisions. Every required target must
be reachable from the primary entry.

### 3. Resolve assets deliberately

Match each visual need to an approved asset. Record `reuse`, `normalize`, or `gap`.
Create raster art only for a named gap and only after scale and footprint are fixed.
Keep transparent art independently bounded, free of chroma fringe, and aligned to the
project grid. Do not use a new image to bypass modular authoring.

### 4. Author natively

Use tile/path/surface data for repeatable ground, modular placed elements for
architecture and props, Environment for eligible natural masses, and separate
foreground/occlusion layers. Keep every placement inside bounds. Build interiors from
floors, walls, corners, openings, and foreground pieces instead of a room-sized shell.

Use `pokemap_describe` before choosing resource kinds or actions, then use the canonical
plan/apply workflow. If a required authoring feature is absent from the live catalog,
record an MCP parity gap instead of writing around it. Implement deterministic asset
generators with a check-only mode when a generator is required.

### 5. Validate before polishing

Run the structural validator with every required route endpoint:

```bash
python3 skills/creating-pokemap-maps-from-reference/scripts/validate_authored_map.py \
  --project <project.json> --map <map.json> \
  --entry <x,y> --target <x,y> --report <quality.json>
```

Fix every error. Warnings require written disposition. Do not add a
`--allow-full-canvas-element` exception merely to make validation green.

### 6. Prove the real result

Produce the mandatory capture pack: native overview, scale board, collision overlay,
one-cell padded-canvas edge test, actual runtime render, and same-crop comparison.
Score every visual axis at least 4/5. Human approval remains mandatory, but approval
does not erase documented technical failures.

Run editor load/save/reload, runtime loading/rendering, targeted tests, and analyzer
checks required by the changed packages.

## Red flags — stop and rebuild the affected layer

- “The engine clips it anyway.”
- “The black outside area hides it.”
- “It looks right only at this crop.”
- “One big sprite is faster and still editable.”
- “We can fix scale after the room is assembled.”
- “The preview is close enough; runtime should match.”
- “The user can infer where to walk.”
- “The reference is pretty, so tracing it is sufficient.”

These are evidence of a broken authoring method, not acceptable trade-offs.

## Utility commands

```bash
python3 skills/creating-pokemap-maps-from-reference/scripts/inventory_assets.py \
  --root <assets> --output <inventory.json> --provenance <provenance.json> \
  --require-approved-provenance --strict
python3 -m unittest \
  skills/creating-pokemap-maps-from-reference/scripts/test_scripts.py -v
```

Use `audit_project_asset_usage.py` only for an explicitly requested cleanup lot.
Never delete uncertain assets or perform Git writes without authorization.
