# NSC-41 — Real Map Sources Implementation Plan

> **Lot:** NSC-41 — Workflow Source et Trigger fondé sur les éléments réels de map
> **Roadmap:** `docs/superpowers/plans/2026-07-19-narrative-studio-completion-roadmap.md`
> **Mechanics context:** this lot reinforces the authoring side of the MVP dialogue/event loop; it does not claim any FG mechanics lot as complete.

## Goal

Make the Event Builder present the physical project truth: maps own map-entry sources, zones own trigger-entry sources, and interactable map entities own interaction sources. The Event Builder may reference those sources, but it never creates or edits their physical identity or geometry.

## Preserved boundaries

- `map_core` remains the only source-catalog and compatibility authority.
- `map_editor` renders catalog state and invokes existing authoring operations; it does not infer source identities.
- `outcomeReceived` remains a separate non-spatial source family.
- Placed decorative elements without an Event V2 identity stay visible but unavailable; this lot does not add a fifth wire source kind.
- Source deletion or identity-breaking edits remain blocked by the existing dependency guard.

## Task 1 — Catalog presentation contract (TDD)

**Files:**

- Modify: `packages/map_core/test/narrative_spatial_event_source_catalog_test.dart`
- Modify: `packages/map_core/lib/src/catalogs/narrative_spatial_event_source_catalog.dart`
- Modify: `packages/map_core/lib/src/operations/build_narrative_spatial_event_source_catalog.dart`

**Steps:**

1. Add failing tests for deterministic map groups, map-entry/zone/PNJ/object categories, compatibility filtering, geometry refresh after a move, duplicate/cross-map/legacy states, and explicit unavailable placed elements.
2. Add a closed presentation category and reference-state contract to source options.
3. Add immutable per-map groups and catalog compatibility queries without changing canonical `NarrativeEventSourceRef` identities.
4. Populate the new contract from actual `MapData` kinds and preserve legacy provenance.
5. Run focused core tests and analysis.

## Task 2 — No-code source picker (TDD)

**Files:**

- Modify: `packages/map_editor/test/ui/canvas/event_builder_v2_creation_flow_test.dart`
- Modify: `packages/map_editor/lib/src/application/use_cases/narrative_event_builder_v2_use_case.dart`
- Modify: `packages/map_editor/lib/src/ui/canvas/events_v2/event_builder_v2_authoring_sheets.dart`
- Modify: `packages/map_editor/lib/src/ui/canvas/events_v2/event_builder_v2_inspector.dart`

**Steps:**

1. Add failing widget tests proving sources are grouped by map/category, unavailable references stay visible but cannot be selected, and outcomes remain in a global group.
2. Load all catalog options into the editor snapshot while exposing selectable choices explicitly.
3. Replace the flat source dropdown with Design System cards, semantic icons, type/state badges and map headings.
4. Explain in the sheet and inspector that physical creation/editing belongs to Map Editor.
5. Keep the existing exact Map Editor intent/return flow for source-less map-scoped Events.

## Task 3 — Source-change revalidation signal (TDD)

**Files:**

- Modify: `packages/map_editor/test/narrative_event_source_dependency_guard_test.dart`
- Modify: `packages/map_editor/lib/src/application/services/narrative_event_source_dependency_guard.dart`
- Modify: `packages/map_editor/lib/src/features/editor/state/editor_notifier.dart`

**Steps:**

1. Add failing tests for moved/resized/renamed sources and unchanged sources.
2. Return linked Event IDs and a revalidation requirement for source-preserving physical edits.
3. Preserve blocking behavior for deletion, identity changes and incompatible kind changes.
4. Surface a truthful “revalidate after save” status from normal Map Editor mutations; do not run a second validator in the notifier.

## Task 4 — Evidence, validation and commit

**Files:**

- Create: `reports/narrativeStudio/completion/nsc_41_real_map_sources_evidence_pack.md`

**Steps:**

1. Run focused core/editor tests, package analyses, `git diff --check`, and a macOS debug build.
2. Perform named Architecture, Implementation, Tests, Build/Validation and Final Critique passes.
3. Record initial/final git state, exact commands/results, file inventory, changed zones, limitations and risks.
4. Stage only NSC-41 files and commit the lot independently.
