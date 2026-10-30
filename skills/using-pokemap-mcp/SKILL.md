---
name: using-pokemap-mcp
description: Use when inspecting or modifying a PokeMap project, automating PokeMap authoring, checking whether editor functionality is exposed through the PokeMap MCP, or diagnosing PokeMap workspace, path, and permission errors.
---

# Using PokeMap MCP

## Overview

Use the canonical PokeMap authoring API. Treat editor, API, and MCP parity as one contract.

## Preflight

1. Use `pokemap_describe` as the health check.
2. Resolve the game-project directory to a canonical path. Never send `.`, a
   guess, the repository instead of the project, or a symlink escape.
3. When available, inspect `codex mcp get pokemap`. Verify the project is equal to or below
   a configured `--root` before calling `pokemap_workspace`.
4. If it is outside, report the project and allowed roots, then request authorization for
   the narrowest useful root. Never broaden access to the home directory or `/` for convenience.

`workspace.path_outside_allowed_roots` is a security rejection, not a crash. Re-run
`pokemap_describe` to distinguish a live rejection from a dead server.

## Project workflow

1. Call `pokemap_describe` with `domain: map3d`, `view: compact` for map work. Follow
   `nextRequest`; request full details by `actionIds` before using an action. The unfiltered
   default remains the full catalogue. Never assume versions, kinds or parameters.
2. Open the absolute project directory and retain its opaque handles.
3. Query content, follow `nextCursor`, never invent handles or URIs.
4. For admitted edits of one existing 3D map, prefer `pokemap_map_edit`. Create and retain
   `operationId` before calling; provide versioned operations and a stable seed (default 0).
   Inspect a `dryRun` when needed, then send the same intent with `dryRun: false`.
   Discover `map3d.edit_batch` details for admitted actions, intent schemas and guards.
   Explicit workshop preparation admits editing indexes when requested; it may inspect the
   project and must stay separate from routine edits. Creation of maps/layers and other
   actions still use `pokemap_workshop read`, `pokemap_plan` and `pokemap_apply`.
   Obtain the exact confirmation when required; the facade does not auto-confirm.
5. Validate, re-query, and render or playtest when runtime or visuals change. On a 3D map,
   `pokemap_render` shows no GLB, terrain surface or Border face: inspect reliefs, joints
   and holes with `pokemap_render_3d` (macOS, floating window, first call is slow).
6. Close the workspace when finished.

After a lost `map_edit` response, reopen the same project and repeat the exact semantic
request with the same `operationId` and new opaque handle. Do not reread a revision into
that request or invent another operation identity. The facade consults the durable result
first. `recovery_required`, `busy`, `expired` and `compensated` are not successful edits;
inspect the returned status and use canonical recovery when appropriate. Retention is
30 days; an expired recognized identity is never permission to apply it again. A new
intention, including identical painting after undo, gets a new identity. Dry runs reserve
nothing.

Inside a batch, Smart Tile operations can select `material: {name: "mer"}` instead of
`materialId`. Ambiguous names or ground suggestions return candidates without writing;
choose explicit IDs and submit the corrected intention. Never automatically apply a
suggestion copied from an old report.

Use `pokemap_map_check` for a revision-bound `pass`, `fail` or `incomplete` verdict.
`visual: none` covers only requested structural checks; default `full` also asks for a
native scan. Read `coverage`, issues and pagination. `incomplete` requires resolving a
missing proof, not repeating calls until green. A zero hole ratio proves only absence of
enclosed sentinel background in those views. Keep independent visual/editability checks.

The batch bounds repeated composition, but final integrity still scans the selected map.
Do not claim constant local cost, the UI latency targets, or large-project acceptance from
the small headless fixtures. `--profile map-builder` is optional; default full tools remain.

Do not bypass MCP by editing project JSON. Filesystem work remains valid for source and
assets. If an action is absent, report a parity gap instead of simulating it.

## Feature parity gate

Apply this gate to new or changed authoring behavior, project data, editor commands,
validation, import/export, rendering, or playtest flows.

- Put shared data contracts in `map_core` and canonical authoring behavior in
  `map_authoring`; keep MCP independent from editor controllers and widgets.
- Register discoverable action and resource contracts where applicable.
- Make the editor use the same canonical contract; an editor-only path is debt.
- Make `pokemap_describe` expose the new resource kinds and actions. Generic whole-map save
  or raw JSON serialization does not prove semantic MCP support.
- Prove direct API, JSONL/CLI, editor, and MCP behavior; justify every N/A.
- Run PMCP-085 and MCP conformance, rebuild/reload the server, and inspect the live catalog.
- Mark missing exposure `PARTIAL` or `BLOCKED`, even when data survives load/save.

## Verification commands

Run from the named package directories:

```bash
cd packages/map_authoring
dart run tool/pmcp085_conformance.dart
dart test test/parity/full_authoring_parity_test.dart
dart analyze

cd ../../tools/pokemap_mcp
npm run check
npm test
```

Then describe, open an absolute fixture, query, safely mutate when applicable, validate, and
close through the live MCP. Report exact results, gaps, and Git status.

## Red flags

- "It is in the JSON, so the MCP supports it."
- "The editor can call this controller directly."
- "Use `/` as an allowed root so paths stop failing."
- "Tests passed; the running server must already be updated."

Each statement requires stopping and restoring the missing safety or parity proof.
