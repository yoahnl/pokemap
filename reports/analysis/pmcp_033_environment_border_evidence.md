# PMCP-033 — Environment and Border Evidence Pack

Date: 2026-07-31

Lot: `PMCP-033`

Verdict proposed: `DONE`
Scope: pure authoring API in `packages/map_authoring`; no roadmap status changed.

## 1. Initial audit

Initial Git state was clean at
`f02d4a6dd8c0bddaa380784392ca62bba494639f`
(`feat(authoring): add semantic map painting`).

The audit found two different source situations:

- Environment models, codecs, validation, and editor use cases already existed,
  but deterministic generation orchestration was owned by `map_editor` and was
  not reachable through the pure authoring API.
- Border already had canonical pure operations in `map_core` for strokes,
  features, resolution, relink, materialization, resize, diagnostics, and
  publication readiness. Reimplementing those rules in `map_authoring` would
  have created a second source of truth.

The selected boundary therefore adapts Border operations and extracts only the
Environment orchestration required by the API. `map_authoring` remains pure
Dart and depends only on `map_core`.

The TDD red command was:

```text
cd packages/map_authoring && dart test \
  test/domains/maps/environment_actions_test.dart \
  test/domains/maps/border_actions_test.dart
```

It failed to load both tests because `EnvironmentActions`,
`EnvironmentGenerationRegion`, and `BorderActions` did not exist. The Border
fixture also exposed the required `previewSeed` field before implementation.

## 2. Implemented result

### Environment

`EnvironmentActions` now exposes 17 canonical mutation descriptors covering:

- Tile-layer attach/detach;
- area create/update/delete, preset, seed, and parameter overrides;
- mask paint/erase/clear;
- deterministic full generation, bounded regeneration, and seed shuffle;
- tracked generated placement add/move/delete/clear as manual overrides.

`EnvironmentGenerationPreview` is immutable and binds its fingerprint to:

- map ID and exact map resource revision;
- Environment layer and area IDs;
- persisted area seed;
- requested region and documented resolution halo;
- canonical generated placement list.

Generation is bounded to 4,096 resolution cells per preview. Its halo is
`max(1, minSpacingCells)`. Applying a local preview removes and recreates only
tracked placements inside that resolution region; tracked placements outside
the halo retain their exact objects and properties. Apply recomputes the
canonical preview and rejects stale revision, stale seed, or altered previews.

### Border

`BorderActions` now exposes 18 canonical mutation descriptors covering:

- stroke add/update/delete and region fill/clear;
- feature create/update/move/reorder/delete;
- published blueprint assignment and relink;
- slot variation, lock/unlock, and keep-out regions;
- materialization and whole-map Border-aware resize.

Read-side methods expose canonical resolution previews, diagnostics, relink
plans, resize plans, and publication readiness without duplicating `map_core`
rules. Feature creation and relink require a real published blueprint revision;
draft-only blueprints fail with `border.blueprint_not_published`. Cross-family
relink requires explicit loss confirmation. Materialization uses the canonical
resolver and optimistic feature fingerprint.

`BorderPreviewArtifact` binds its fingerprint to project revision, feature
seed, published blueprint revision, resolver version, diagnostics, and canonical
input/output fingerprints.

### Transaction integration

Both domains are registered in `MapMutationDispatcher.canonical()`. Their
writes use the existing plan/confirm/apply/idempotency/revision/undo pipeline.
`SemanticMapActionContext.draftMap` adds a single map-wide change set for
operations that alter both layer content and spatial collections, or resize a
map. Projected maps are validated before a draft is accepted.

## 3. Proof against done criteria

| Criterion | Evidence | Verdict |
|---|---|---|
| Deterministic generation | Same input/revision/seed produces the same Environment preview fingerprint and placements | PASS |
| Local edit does not regenerate outside documented halo | Test marks an outside placement, regenerates a 1-cell region, and proves the outside object properties remain exact | PASS |
| Non-publishable blueprint refused | Draft-only catalog record raises stable `border.blueprint_not_published` | PASS |
| Preview bound to revision and seed | Environment and Border tests prove fingerprint changes independently with revision/seed | PASS |
| Canonical Border logic reused | Relink, resolver, apply-preview, resize, and publication-readiness calls delegate to `map_core` | PASS |
| Transaction safety | One validated map-wide resource change; existing revision/idempotency/undo guarantees retained | PASS |

## 4. Named review passes

No sub-agent was used because the active repository instruction forbade
delegation unless explicitly requested. The required independent viewpoints
were performed as named local passes:

1. **Initial architecture pass — PASS.** Confirmed `map_authoring -> map_core`
   only, found the editor-owned Environment orchestration, and inventoried the
   canonical Border operations.
2. **Contract/TDD pass — PASS.** Captured the missing API as red tests, then
   proved deterministic Environment generation, locality, unpublished
   blueprint rejection, preview binding, stroke adaptation, and dispatcher
   registration.
3. **Conformity pass — PASS.** Checked action IDs against the authoring action
   catalog and preserved plan/apply, revision, idempotency, and undo guarantees.
4. **Quality pass — PASS with documented limits.** Removed an unnecessary
   Environment-to-Border implementation dependency, made preview application
   canonical and stale-safe, rejected duplicate feature creation, and rejected
   unknown Border generation fields.
5. **Verification pass — PASS.** Focused tests, complete package tests, static
   analysis, formatting gate, and targeted `map_core` regressions are green.

## 5. File inventory

Modified:

- `packages/map_authoring/lib/map_authoring.dart` — exports Environment and
  Border public contracts.
- `packages/map_authoring/lib/src/domains/maps/map_mutation_dispatcher.dart` —
  registers both canonical action families.
- `packages/map_authoring/lib/src/domains/maps/semantic_map_action_support.dart`
  — adds validated map-wide mutation drafts and compact map summaries.

Created:

- `packages/map_authoring/lib/src/domains/maps/environment_actions.dart`;
- `packages/map_authoring/lib/src/domains/maps/border_actions.dart`;
- `packages/map_authoring/test/domains/maps/environment_actions_test.dart`;
- `packages/map_authoring/test/domains/maps/border_actions_test.dart`;
- `reports/analysis/pmcp_033_environment_border_evidence.md` (this report);
- `reports/analysis/pmcp_033_environment_border_evidence_appendix.md`.

The complete content of every created implementation/test file is reproduced
in the appendix. This report is already its own complete content; the appendix
does not recursively embed itself.

## 6. Precise changed zones

- `map_authoring.dart:25-26`: two public exports.
- `map_mutation_dispatcher.dart:5-6,40-41,74-87`: imports, instances, and
  canonical registrations.
- `semantic_map_action_support.dart:168-225`: `draftMap` validation and atomic
  change-set creation.
- `semantic_map_action_support.dart:345-356`: compact map-level diff summary.
- `environment_actions.dart:11-126`: region, placement, and revision-bound
  preview contracts.
- `environment_actions.dart:129-667`: descriptors, deterministic preview/apply,
  and transaction builder.
- `environment_actions.dart:669-end`: target validation, deterministic PRNG,
  bounded generation, area/mask/placement operations.
- `border_actions.dart:11-69`: revision/seed-bound preview artifact.
- `border_actions.dart:71-755`: canonical descriptors, read adapters, and
  mutation builder.
- `border_actions.dart:757-end`: strict parsing, geometry translation,
  keep-outs, and slot lock helpers.
- Both new test files cover the lot-specific proof matrix.

## 7. Commands and exact results

### Focused authoring tests

```text
cd packages/map_authoring && dart test \
  test/domains/maps/environment_actions_test.dart \
  test/domains/maps/border_actions_test.dart
```

Result: `00:00 +7: All tests passed!`

### Complete authoring package

```text
cd packages/map_authoring && dart test
```

Result: `00:12 +215: All tests passed!`

```text
cd packages/map_authoring && dart analyze
```

Result: `Analyzing map_authoring... No issues found!`

```text
cd packages/map_authoring && \
  dart format --output=none --set-exit-if-changed lib test bin
```

Result: `Formatted 115 files (0 changed)`; exit code 0.

### Canonical core regression checks

```text
cd packages/map_core && dart test \
  test/environment_layer_map_layer_integration_test.dart \
  test/border/border_relink_operations_test.dart \
  test/border/border_resolution_test.dart \
  test/map_resize_plan_test.dart
```

Result: `+48: All tests passed!`

```text
cd packages/map_core && dart analyze
```

Result: `Analyzing map_core... No issues found!`

## 8. Decisions and non-goals

- Query-like catalog entries (`generate_plan`, `resolve`, `diagnostics`,
  `publication_readiness`, and preview operations) are pure methods. Mutating
  catalog entries are dispatcher descriptors and automatically support dry-run
  planning through the canonical mutation API.
- No Flutter or editor controller entered `map_authoring`.
- No Border algorithm was copied from `map_core`.
- No roadmap status was edited.
- No `worldLayout`, renderer, spatial-object authoring, or cross-map behavior
  was added; those belong to PMCP-034/035.

## 9. Risks and known limitations

- Environment generation is now independently testable but remains duplicated
  with legacy `map_editor` use cases until the editor migration lot. Drift is a
  risk; PMCP-081 should route editor gestures through this canonical adapter.
- Local regeneration intentionally preserves all placements outside the
  documented halo. With high spacing values, chunk seams can be more
  conservative than a fresh whole-map generation because the accepted set is
  scoped to the resolution region.
- Border publication readiness is a direct typed delegate. This lot proves the
  unpublished-blueprint gate and relies on the existing `map_core` publication
  test matrix for complex asset/gallery fixtures.
- Full-map Environment generation above 4,096 resolution cells must be chunked.
  This is a safety bound, not silent truncation.

## 10. Final self-critique

The lot closes the requested API surface without moving domain rules into the
dispatcher. The strongest choices are the revision/seed-bound artifacts,
canonical preview recomputation before Environment apply, explicit relink loss
confirmation, and reuse of Border optimistic fingerprints.

The main debt is file size: both action adapters intentionally group a broad XL
lot and contain strict JSON-to-domain parsing plus orchestration. Future splits
should be mechanical (contracts, parsing, generation service) and must preserve
the public barrel and action IDs. The next lot should not refactor these files
unless PMCP-034 genuinely needs shared spatial helpers.

## 11. Git evidence

Initial:

```text
HEAD f02d4a6dd8c0bddaa380784392ca62bba494639f
working tree clean
```

Pre-commit state contains only the files listed in section 5. The final commit
hash and clean post-commit status are recorded by the enclosing phase workflow.

Proposed roadmap disposition: `PMCP-033` can be marked `DONE` from this fresh
evidence; no roadmap file was modified.
