# PMCP-011 — Snapshot and Query Evidence Pack

Date: 2026-07-31
Lot: `PMCP-011 — Snapshot projet, queries et pagination`
Verdict proposed: `DONE`

## Executive summary

`map_authoring` now loads an immutable manifest-plus-maps snapshot from an
opaque project handle, rejects resources that change during its two-pass read,
and derives one global SHA-256 revision from exact sorted resource frames.

Clients can query `project` and `map` resources through strict `list`, `get`,
`batch_get`, `search`, and `summary` operations with compact/detail views,
field masks, deep JSON equality filters, deterministic multi-field sorting,
bounded page sizes, and revision/query-bound cursors. Map regions return clipped
grid rows and intersecting spatial resources without serializing the complete
map.

The persisted editor `mistralApiKey` and manifest-relative map paths are
explicitly removed from project detail projections.

## Scope confirmation

Implemented:

- manifest and declared-map snapshot;
- duplicate map ID/path and map identity validation;
- exact resource and global SHA-256 fingerprints;
- two-pass change detection;
- deterministic map and fingerprint ordering;
- strict query request/page JSON contracts;
- five read operations;
- summary/detail projections;
- equality filters including composite JSON values;
- deterministic sorting and identity tie-breaking;
- dotted field masks;
- cursor pagination bound to snapshot revision and normalized query;
- map region bounds validation and compact spatial projections;
- clipped tile, collision, terrain, path, and smart-tile material rows;
- surface placement filtering and deterministic ordering;
- metadata-only projections for object, environment, and border layers.

Explicitly not implemented:

- non-map resource domains beyond the project manifest;
- reference graph and capability truth (`PMCP-012`);
- CLI transport (`PMCP-013`);
- filesystem writes or mutation actions;
- signed/tamper-proof pagination cursors;
- full border/environment regional materialization.

## Initial audit

Initial branch and state:

```text
eea69e83e (HEAD -> main) feat(authoring): add secure read-only workspaces
<clean working tree>
```

Relevant existing contracts:

- `ProjectManifest`, `ProjectMapEntry`, `MapData`, `MapLayer`, and spatial
  models from `map_core`;
- `computeNarrativeProjectFingerprint`;
- `WorkspaceHandleStore` live read validation from `PMCP-010`;
- strict phase 1 JSON helpers and extension rules;
- persisted `ProjectSettings.mistralApiKey`, identified as a secret-bearing
  field requiring removal;
- flat row-major payloads for tile, collision, terrain, path, and smart-tile
  material layers.

Key design decision:

The global revision binds the exact bytes of `project.json`. Reordering
persisted manifest data therefore changes the revision, as it should for disk
concurrency detection. Exposed map collections are still sorted
deterministically. The phase plan was corrected to state this explicitly.

## Named pass verdicts

No sub-agent was launched because delegation was not authorized. Required
independent passes were executed inline:

| Pass | Verdict | Evidence |
|---|---|---|
| Audit / Architecture | `PASS` | exact models, JSON shapes, layer encodings, and secret field inspected |
| Implementation | `PASS` | snapshot, contracts, query service, and region projection remain pure Dart |
| Tests | `PASS` | 24 focused tests; 73 package tests |
| Build / Validation | `PASS` | all test targets compile; analyzer and formatter clean |
| Critique finale | `PASS_WITH_FIXES`, then `PASS` | direct snapshot invariants, returned count, deep filters, and placement order hardened |

## File inventory

### Modified files

`packages/map_authoring/lib/map_authoring.dart`

- Zone: public exports.
- Change: exports query contracts, map-region API, query service, snapshot, and
  snapshot loader.
- Reason: expose the complete lot through the canonical package barrel.
- Impact: direct API and future CLI share the same types.

Exact diff zone:

```diff
+export 'src/contracts/query_page.dart';
+export 'src/contracts/query_request.dart';
+export 'src/domains/maps/map_region_query.dart';
+export 'src/workspace/project_query_service.dart';
+export 'src/workspace/project_snapshot.dart';
+export 'src/workspace/project_snapshot_loader.dart';
```

`pokemap_authoring_api_mcp_phase_2_implementation_plan.md`

- Zone: PMCP-011 snapshot determinism test and loader explanation.
- Change: replaces the incorrect claim that manifest reordering leaves a
  byte-level revision unchanged.
- Reason: exact persisted bytes must participate in concurrency fingerprints.
- Impact: plan and implementation now describe the same invariant.

Exact changed intent:

```diff
-test('is deterministic independent of manifest map ordering', () async {
+test('is deterministic when the exact resource bytes are unchanged', () async {
   expect(first.revision, second.revision);
+  expect(first.maps.map((map) => map.id), orderedEquals(['a-map', 'z-map']));
 });
```

The adjacent loader paragraph now states that exact manifest byte changes alter
the revision while exposed resources remain sorted.

### Created production files

`packages/map_authoring/lib/src/workspace/project_snapshot.dart`

- `ProjectSnapshotException`, `ProjectSnapshot`.
- Immutable typed project revision, direct-construction uniqueness guards,
  resource fingerprint validation, sorted maps, and ID lookup.

`packages/map_authoring/lib/src/workspace/project_snapshot_loader.dart`

- `ProjectSnapshotLoader`.
- Reads manifest and maps twice, validates identities, detects mixed revisions,
  and derives global/resource fingerprints.

`packages/map_authoring/lib/src/contracts/query_request.dart`

- `AuthoringQueryOperation`, `AuthoringQueryView`, `AuthoringQuerySort`,
  `AuthoringQueryRequest`.
- Strict normalized query request and semantic SHA-256 signature.

`packages/map_authoring/lib/src/contracts/query_page.dart`

- `AuthoringQueryPage`.
- Immutable page envelope with snapshot revision, exact returned count, total,
  and continuation cursor.

`packages/map_authoring/lib/src/workspace/project_query_service.dart`

- `AuthoringQueryException`, `ProjectQueryService`.
- Project/map projections, sanitization, operations, deep filters, masks,
  deterministic sorting, and cursors.

`packages/map_authoring/lib/src/domains/maps/map_region_query.dart`

- `MapRegionQueryException`, `MapRegionQuery`, `MapRegionResult`,
  `queryMapRegion`.
- Bounds-safe compact regional projections.

### Created tests

`packages/map_authoring/test/workspace/project_snapshot_test.dart`

- real fixture, stable revision, deterministic ordering, immutability,
  concurrent change, duplicate IDs, identity mismatch, unknown handles,
  direct-construction invariants.

`packages/map_authoring/test/contracts/query_pagination_test.dart`

- strict JSON, five operations, stable pages, stale/mismatched/malformed
  cursors, filters, sort, masks, compactness, secret/path redaction, page count.

`packages/map_authoring/test/domains/maps/map_region_query_test.dart`

- clipped rows, spatial intersections, surface ordering, metadata-only layers,
  compactness, strict JSON, invalid sizes, and bounds.

### Full-content appendix

`reports/analysis/pmcp_011_created_files_full_content.md` reproduces the nine
created production and test files in full. The report and appendix exclude
themselves to avoid recursive content.

## TDD evidence

Snapshot RED:

```text
dart test test/workspace/project_snapshot_test.dart
Exit code: 1
Type 'ProjectSnapshotLoader' not found.
Type 'ProjectSnapshotException' not found.
```

Snapshot first GREEN:

```text
+6: All tests passed!
Exit code: 0
```

Query RED:

```text
dart test test/contracts/query_pagination_test.dart
Exit code: 1
Undefined name 'AuthoringQueryOperation'.
Type 'AuthoringQueryRequest' not found.
Type 'ProjectQueryService' not found.
```

Query first GREEN:

```text
+9: All tests passed!
Exit code: 0
```

Map-region RED:

```text
dart test test/domains/maps/map_region_query_test.dart
Exit code: 1
Type 'MapRegionQuery' not found.
Method 'queryMapRegion' not found.
```

The first map-region implementation exposed generated nested geometry objects
instead of pure JSON. The test failed with:

```text
Invalid argument (mapRegion.gameplayZones[0].area.pos):
must contain only JSON-compatible values
```

Deep JSON conversion fixed that defect:

```text
+5: All tests passed!
Exit code: 0
```

Critical-review regressions observed before fixes:

- composite list filters returned no match due identity equality;
- a forged serialized `returned: 99` was accepted;
- surface placements followed source order rather than canonical spatial order;
- the public snapshot constructor accepted duplicate IDs and malformed resource
  fingerprints.

Final focused result:

```text
dart test test/workspace/project_snapshot_test.dart \
  test/contracts/query_pagination_test.dart \
  test/domains/maps/map_region_query_test.dart

+24: All tests passed!
Exit code: 0
```

## Final commands and exact results

Full package tests:

```text
Command:
set -o pipefail
dart test --reporter expanded 2>&1 | tail -n 10

Result:
+73: All tests passed!
Exit code: 0
```

Static analysis:

```text
Command:
dart analyze

Result:
Analyzing map_authoring...
No issues found!
Exit code: 0
```

Formatting:

```text
Command:
dart format --output=none --set-exit-if-changed lib test

Result:
Formatted 37 files (0 changed) in 0.05 seconds.
Exit code: 0
```

Build:

`map_authoring` remains a pure Dart library and `PMCP-011` adds no executable.
The proportional build proof is compilation of every package test target plus
package-wide static analysis. The standalone executable build is reserved for
`PMCP-013`.

## Final Git state before the lot commit

```text
 M packages/map_authoring/lib/map_authoring.dart
 M pokemap_authoring_api_mcp_phase_2_implementation_plan.md
?? packages/map_authoring/lib/src/contracts/query_page.dart
?? packages/map_authoring/lib/src/contracts/query_request.dart
?? packages/map_authoring/lib/src/domains/maps/map_region_query.dart
?? packages/map_authoring/lib/src/workspace/project_query_service.dart
?? packages/map_authoring/lib/src/workspace/project_snapshot.dart
?? packages/map_authoring/lib/src/workspace/project_snapshot_loader.dart
?? packages/map_authoring/test/contracts/query_pagination_test.dart
?? packages/map_authoring/test/domains/maps/map_region_query_test.dart
?? packages/map_authoring/test/workspace/project_snapshot_test.dart
?? reports/analysis/pmcp_011_created_files_full_content.md
?? reports/analysis/pmcp_011_snapshot_query_evidence.md
```

## Critical self-review

Strengths:

- project-wide revision binds exact manifest and map bytes;
- two-pass reads fail explicitly on observed concurrent changes;
- public snapshots enforce invariants even outside the loader;
- cursors cannot cross revisions or normalized queries;
- summaries remain identity-complete and materially smaller;
- project detail removes the known persisted editor API key and map paths;
- region responses are bounded by requested dimensions.

Remaining risks:

1. Two-pass portable reads detect observed changes but cannot create a true
   multi-file filesystem transaction. A resource could change after its second
   read; the phase 3 write kernel must use revision checks at mutation time.
2. Cursors are bound but unsigned. A client can alter an offset if it also
   preserves the visible query signature; this can skip data but cannot access
   another revision or bypass filters.
3. Only `project` and `map` generic resources are implemented. Later content
   lots must add resource kinds through the same contracts.
4. Environment and border regional payloads are metadata-only because their
   compact spatial materialization needs domain-specific projections.
   Full map detail remains available.
5. Deep map detail may still be large. Callers should prefer summary, masks,
   pagination, and regions.
6. Sanitization explicitly covers the known `mistralApiKey`. Future
   secret-bearing manifest fields must be added to a centralized policy before
   they can enter detail projections.

## Next step

Proceed to `PMCP-012 — Références, diagnostics et capability truth`: adapt the
existing `map_core` narrative dependency index and explicit capability truth
without inferring support from model presence.

## Full-content appendix

`reports/analysis/pmcp_011_created_files_full_content.md`
