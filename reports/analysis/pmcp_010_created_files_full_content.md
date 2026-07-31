# PMCP-010 — Full created-file contents

This appendix is part of the PMCP-010 Evidence Pack and reproduces every implementation, test, and plan file created by the lot. The report and appendix exclude themselves to avoid self-reference.

## `pokemap_authoring_api_mcp_phase_2_implementation_plan.md`

~~~~~~~~markdown
# PokeMap Authoring API Phase 2 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Let an external agent inspect a real PokeMap project through a safe, deterministic, read-only pure-Dart API and JSONL CLI.

**Architecture:** Extend `map_authoring` with four inward-facing layers: secure workspace handles, immutable project snapshots and queries, reference/capability diagnostics, then a thin JSONL transport. Filesystem access stays behind a read-only port, canonical contracts never expose machine paths, and the CLI delegates to the same API services tested directly.

**Tech Stack:** Dart 3.4+, `dart:io`, `dart:convert`, `map_core`, `package:test`, existing `AuthoringResult` contracts.

---

## Constraints and execution mode

- Execute inline on the current `main` branch because the user explicitly
  requested implementation and one commit per lot.
- Do not push.
- Follow strict red-green-refactor TDD for production behavior.
- Keep `map_authoring` pure Dart and dependent only on `map_core`.
- Do not add write, delete, rename, recovery, transaction, or mutation methods.
- Never serialize canonical project roots, absolute machine paths, stack
  traces, or raw exceptions.
- Use the existing
  `examples/playable_runtime_host/p3_narrative_smoke_slice` project as the real
  read-only fixture.
- Commit exactly once after each lot passes its focused tests and analyzer.

## Public surface after phase 2

```dart
final policy = await WorkspacePolicy.create(
  allowedRootPaths: [fixtureRoot],
  fileReader: const LocalProjectFileReader(),
);
final handles = WorkspaceHandleStore(
  clock: clock,
  tokenFactory: tokens,
);
final openService = ProjectOpenService(
  policy: policy,
  fileReader: const LocalProjectFileReader(),
  handles: handles,
);
final opened = await openService.openProject(fixtureRoot);

final snapshot = await ProjectSnapshotLoader(
  fileReader: const LocalProjectFileReader(),
  handles: handles,
).load(opened.projectHandle);

final page = ProjectQueryService().query(
  snapshot,
  const AuthoringQueryRequest(
    resourceKind: 'map',
    operation: AuthoringQueryOperation.list,
    pageSize: 20,
  ),
);
```

The JSONL worker must return the same serialized `page.toJson()` value for the
equivalent CLI query.

---

### Task 1: PMCP-010 — Define the read-only filesystem port and path policy

**Files:**

- Create: `packages/map_authoring/lib/src/ports/project_file_reader.dart`
- Create: `packages/map_authoring/lib/src/workspace/workspace_policy.dart`
- Create: `packages/map_authoring/test/workspace/workspace_path_security_test.dart`
- Modify: `packages/map_authoring/lib/map_authoring.dart`

- [ ] **Step 1: Write failing path-security tests**

Cover:

```dart
test('authorizes a real project below an allowed root', () async {
  final policy = await WorkspacePolicy.create(
    allowedRootPaths: [fixtureParent.path],
    fileReader: const LocalProjectFileReader(),
  );
  expect(
    await policy.authorizeProjectRoot(fixtureProject.path),
    isNotEmpty,
  );
});

test('rejects traversal before filesystem resolution', () async {
  expect(
    () => policy.authorizeProjectRoot('${fixtureProject.path}/../outside'),
    throwsA(
      isA<WorkspaceAccessException>().having(
        (error) => error.code,
        'code',
        'workspace.path_traversal',
      ),
    ),
  );
});

test('rejects an outward symlink', () async {
  expect(
    () => reader.readBytes(
      projectRoot: canonicalProjectRoot,
      relativePath: 'maps/outward.json',
    ),
    throwsA(
      isA<WorkspaceAccessException>().having(
        (error) => error.code,
        'code',
        'workspace.path_outside_project',
      ),
    ),
  );
});
```

- [ ] **Step 2: Run the tests and verify RED**

Run:

```bash
cd packages/map_authoring
dart test test/workspace/workspace_path_security_test.dart
```

Expected: compilation fails because the port and policy do not exist.

- [ ] **Step 3: Implement the minimal read-only port**

The port exposes only:

```dart
abstract interface class ProjectFileReader {
  Future<String> canonicalizeDirectory(String path);
  Future<List<int>> readBytes({
    required String projectRoot,
    required String relativePath,
  });
}

final class LocalProjectFileReader implements ProjectFileReader {
  const LocalProjectFileReader();
}
```

`LocalProjectFileReader` must:

- reject blank and NUL-containing paths;
- reject absolute project-relative paths and every `..` segment;
- resolve the target's symlinks before reading;
- require the resolved file to remain under the canonical project root;
- read bytes only and define no write method;
- throw `WorkspaceAccessException` with stable safe codes and messages.

- [ ] **Step 4: Implement allowed-root authorization**

`WorkspacePolicy.create` canonicalizes allowed roots once. Its
`authorizeProjectRoot` rejects lexical traversal and authorizes only a
canonical directory equal to or below an allowed root.

- [ ] **Step 5: Run focused tests and analyzer**

Run:

```bash
cd packages/map_authoring
dart test test/workspace/workspace_path_security_test.dart
dart analyze
```

Expected: all tests pass; analyzer reports no issues.

---

### Task 2: PMCP-010 — Add opaque handles and project opening

**Files:**

- Create: `packages/map_authoring/lib/src/workspace/workspace_handle_store.dart`
- Create: `packages/map_authoring/lib/src/workspace/project_open_service.dart`
- Create: `packages/map_authoring/test/workspace/project_open_service_test.dart`
- Modify: `packages/map_authoring/lib/map_authoring.dart`

- [ ] **Step 1: Write failing open/handle tests**

Cover:

```dart
test('opens the real fixture read-only with opaque handles', () async {
  final opened = await service.openProject(realFixture.path);

  expect(opened.workspaceHandle.value, startsWith('ws_'));
  expect(opened.projectHandle.value, startsWith('prj_'));
  expect(opened.projectName, 'P3 Narrative Smoke Slice');
  expect(opened.fingerprint, matches(r'^sha256:[0-9a-f]{64}$'));
  expect(opened.toJson().toString(), isNot(contains(realFixture.path)));
});

test('rejects unknown, expired, and closed handles', () async {
  expect(
    () => store.resolveProject(const ProjectHandle('prj_unknown')),
    throwsA(isA<WorkspaceHandleException>()),
  );
});
```

Assert that opening and closing do not change the fixture file fingerprints.

- [ ] **Step 2: Run and verify RED**

Run:

```bash
cd packages/map_authoring
dart test test/workspace/project_open_service_test.dart
```

Expected: compilation fails because handle and open-service types do not exist.

- [ ] **Step 3: Implement handles and store**

Define opaque value objects:

```dart
final class WorkspaceHandle {
  const WorkspaceHandle(this.value);
  final String value;
}

final class ProjectHandle {
  const ProjectHandle(this.value);
  final String value;
}
```

`WorkspaceHandleStore` accepts injected `DateTime Function()` and
`String Function(String prefix)` functions, stores canonical roots privately,
enforces expiry on every resolution, and supports idempotent `close`.

- [ ] **Step 4: Implement project opening**

`ProjectOpenService.openProject`:

1. authorizes the root;
2. reads `project.json` through the port;
3. decodes a JSON object and constructs `ProjectManifest`;
4. computes the initial `sha256:` fingerprint with
   `computeNarrativeProjectFingerprint`;
5. registers private handle state;
6. returns only opaque handles, project identity, expiry, and fingerprint.

Map parse and filesystem exceptions must become safe stable workspace
exceptions without embedding absolute paths.

- [ ] **Step 5: Verify PMCP-010 completely**

Run:

```bash
cd packages/map_authoring
dart test test/workspace
dart test
dart analyze
dart format --output=none --set-exit-if-changed lib test
```

Expected: all commands exit `0`.

- [ ] **Step 6: Write the PMCP-010 evidence report**

Create:

`reports/analysis/pmcp_010_secure_workspace_evidence.md`

Record the initial/final Git state, files, RED/GREEN evidence, exact commands,
real fixture proof, symlink/traversal proof, limitations, and critical review.

- [ ] **Step 7: Commit PMCP-010**

```bash
git add -- \
  packages/map_authoring \
  pokemap_authoring_api_mcp_phase_2_implementation_plan.md \
  reports/analysis/pmcp_010_secure_workspace_evidence.md
git commit -m "feat(authoring): add secure read-only workspaces"
```

Verify the commit with `git log -1 --oneline` and require a clean tree before
starting PMCP-011.

---

### Task 3: PMCP-011 — Load immutable coherent project snapshots

**Files:**

- Create: `packages/map_authoring/lib/src/workspace/project_snapshot.dart`
- Create: `packages/map_authoring/lib/src/workspace/project_snapshot_loader.dart`
- Create: `packages/map_authoring/test/workspace/project_snapshot_test.dart`
- Modify: `packages/map_authoring/lib/map_authoring.dart`

- [ ] **Step 1: Write failing snapshot tests**

Cover:

```dart
test('loads manifest and maps from the real fixture', () async {
  final snapshot = await loader.load(opened.projectHandle);

  expect(snapshot.manifest.name, 'P3 Narrative Smoke Slice');
  expect(snapshot.maps.single.id, 'p3_narrative_smoke_map');
  expect(snapshot.revision, matches(r'^sha256:[0-9a-f]{64}$'));
});

test('is deterministic independent of manifest map ordering', () async {
  expect(first.revision, second.revision);
});

test('rejects a resource changed during two-pass loading', () async {
  expect(
    () => loader.load(opened.projectHandle),
    throwsA(
      isA<ProjectSnapshotException>().having(
        (error) => error.code,
        'code',
        'project.changed_during_snapshot',
      ),
    ),
  );
});
```

Also reject duplicate manifest map IDs, mismatched map IDs, and unsafe map
paths.

- [ ] **Step 2: Run and verify RED**

Run:

```bash
cd packages/map_authoring
dart test test/workspace/project_snapshot_test.dart
```

Expected: compilation fails because snapshot types do not exist.

- [ ] **Step 3: Implement immutable snapshots**

`ProjectSnapshot` owns:

```dart
final ProjectHandle projectHandle;
final String revision;
final ProjectManifest manifest;
final List<MapData> maps;
final Map<String, String> resourceFingerprints;
```

Copy and sort mutable collections. Expose lookup by map ID without exposing
filesystem paths.

- [ ] **Step 4: Implement two-pass loading**

The loader reads `project.json` plus every declared map through the read-only
port, validates typed models, then reads the same resource set again. If any
exact byte payload differs, fail with `project.changed_during_snapshot`.
Compute the global revision from sorted `(relativePath, bytes)` frames.

- [ ] **Step 5: Run focused tests**

Run:

```bash
cd packages/map_authoring
dart test test/workspace/project_snapshot_test.dart
dart analyze
```

Expected: green.

---

### Task 4: PMCP-011 — Add deterministic queries, masks, cursors, and map regions

**Files:**

- Create: `packages/map_authoring/lib/src/contracts/query_request.dart`
- Create: `packages/map_authoring/lib/src/contracts/query_page.dart`
- Create: `packages/map_authoring/lib/src/workspace/project_query_service.dart`
- Create: `packages/map_authoring/lib/src/domains/maps/map_region_query.dart`
- Create: `packages/map_authoring/test/contracts/query_pagination_test.dart`
- Create: `packages/map_authoring/test/domains/maps/map_region_query_test.dart`
- Modify: `packages/map_authoring/lib/map_authoring.dart`

- [ ] **Step 1: Write failing query and cursor tests**

Test `list`, `get`, `batch_get`, `search`, and `summary`. Cover:

```dart
final first = service.query(
  snapshot,
  const AuthoringQueryRequest(
    resourceKind: 'map',
    operation: AuthoringQueryOperation.list,
    pageSize: 1,
  ),
);
final second = service.query(
  snapshot,
  AuthoringQueryRequest(
    resourceKind: 'map',
    operation: AuthoringQueryOperation.list,
    pageSize: 1,
    cursor: first.nextCursor,
  ),
);
expect({...first.items, ...second.items}.length, 2);
```

Reject a cursor when the snapshot revision or normalized query signature
differs. Verify deterministic filtering/sorting and dotted field masks. Compare
encoded summary and detail sizes while retaining `id`, `name`, and kind.

- [ ] **Step 2: Run query tests and verify RED**

Run:

```bash
cd packages/map_authoring
dart test test/contracts/query_pagination_test.dart
```

Expected: compilation failure for missing query contracts.

- [ ] **Step 3: Implement strict query contracts**

Define:

```dart
enum AuthoringQueryOperation { list, get, batchGet, search, summary }

final class AuthoringQueryRequest {
  const AuthoringQueryRequest({
    required this.resourceKind,
    required this.operation,
    this.ids = const [],
    this.searchTerm,
    this.fieldMask = const [],
    this.filters = const {},
    this.sort = const [],
    this.pageSize = 50,
    this.cursor,
  });
}

final class AuthoringQueryPage {
  final String snapshotRevision;
  final List<Map<String, Object?>> items;
  final String? nextCursor;
  final int returned;
}
```

Validate operation-specific fields, cap page size, canonicalize masks/filters,
and provide strict JSON round trips.

- [ ] **Step 4: Implement query execution**

`ProjectQueryService` supports `project` and `map` resources in phase 2. It:

- generates compact summary and full detail projections;
- applies exact equality filters and case-insensitive search;
- applies deterministic multi-field sort plus an ID tiebreaker;
- applies dotted field masks while always retaining identity;
- encodes a versioned base64url cursor containing revision, query signature,
  and offset;
- rejects stale or cross-query cursors.

- [ ] **Step 5: Write failing map-region tests**

Test clipped tile/collision/terrain/path rows, filtered entities and placed
elements, compact output, and bounds errors:

```dart
expect(
  () => queryMapRegion(
    map,
    const MapRegionQuery(x: 3, y: 3, width: 2, height: 2),
  ),
  throwsA(isA<MapRegionQueryException>()),
);
```

- [ ] **Step 6: Implement map-region projections**

Return only:

- map identity and requested bounds;
- clipped rows for flat grid layer payloads;
- filtered surface placements;
- layer metadata for non-grid layers;
- entities, placed elements, warps, triggers, and gameplay zones intersecting
  the region.

Never include the full `MapData.toJson()` payload.

- [ ] **Step 7: Verify PMCP-011 completely**

Run:

```bash
cd packages/map_authoring
dart test test/workspace/project_snapshot_test.dart
dart test test/contracts/query_pagination_test.dart
dart test test/domains/maps/map_region_query_test.dart
dart test
dart analyze
dart format --output=none --set-exit-if-changed lib test
```

- [ ] **Step 8: Write report and commit PMCP-011**

Create:

`reports/analysis/pmcp_011_snapshot_query_evidence.md`

Then:

```bash
git add -- packages/map_authoring \
  reports/analysis/pmcp_011_snapshot_query_evidence.md
git commit -m "feat(authoring): add snapshot query API"
```

Verify the commit and clean tree.

---

### Task 5: PMCP-012 — Build the typed project reference index

**Files:**

- Create: `packages/map_authoring/lib/src/references/project_reference_index.dart`
- Create: `packages/map_authoring/lib/src/references/reference_impact.dart`
- Create: `packages/map_authoring/lib/src/references/reference_queries.dart`
- Create: `packages/map_authoring/test/references/project_reference_index_test.dart`
- Modify: `packages/map_authoring/lib/map_authoring.dart`

- [ ] **Step 1: Write failing reference tests**

Build a project containing facts, scenes, storylines, events, a map warp, and a
missing target. Verify:

- cross-domain definitions and usages are present;
- `dependencies(owner)` and `dependents(target)` are deterministic;
- broken references carry stable codes and navigation data;
- delete and rename impact list all direct dependents;
- a cyclic graph terminates under `maxDepth` and `maxNodes`.

```dart
final graph = queries.graph(
  root,
  maxDepth: 8,
  maxNodes: 20,
);
expect(graph.nodes.length, lessThanOrEqualTo(20));
expect(graph.truncated, isFalse);
```

- [ ] **Step 2: Run and verify RED**

Run:

```bash
cd packages/map_authoring
dart test test/references/project_reference_index_test.dart
```

Expected: compilation failure for missing reference types.

- [ ] **Step 3: Implement the narrative index adapter**

Use `buildNarrativeDependencyIndex(project: manifest, maps: maps)` as the
canonical discovery engine. Adapt its definitions, usages, and issues into:

```dart
enum ProjectReferenceDiagnosticSeverity { info, warning, error }

final class ProjectReferenceNode {
  ProjectReferenceNode({
    required this.resource,
    required this.label,
    Map<String, Object?> metadata = const {},
  }) : metadata = Map.unmodifiable(metadata);

  final AuthoringResourceRef resource;
  final String label;
  final Map<String, Object?> metadata;
}

final class ProjectReferenceEdge {
  const ProjectReferenceEdge({
    required this.owner,
    required this.target,
    required this.path,
  });

  final AuthoringResourceRef owner;
  final AuthoringResourceRef target;
  final String path;
}

final class ProjectReferenceDiagnostic {
  const ProjectReferenceDiagnostic({
    required this.code,
    required this.severity,
    required this.message,
    required this.target,
    this.owner,
    this.fieldPath,
    this.navigation,
  });

  final String code;
  final ProjectReferenceDiagnosticSeverity severity;
  final String message;
  final AuthoringResourceRef target;
  final AuthoringResourceRef? owner;
  final String? fieldPath;
  final Map<String, Object?>? navigation;
}

final class ProjectReferenceIndex {
  ProjectReferenceIndex({
    required Iterable<ProjectReferenceNode> nodes,
    required Iterable<ProjectReferenceEdge> edges,
    required Iterable<ProjectReferenceDiagnostic> diagnostics,
  })  : nodes = List.unmodifiable(nodes),
        edges = List.unmodifiable(edges),
        diagnostics = List.unmodifiable(diagnostics);

  final List<ProjectReferenceNode> nodes;
  final List<ProjectReferenceEdge> edges;
  final List<ProjectReferenceDiagnostic> diagnostics;
}
```

Preserve typed kind/scope/source identity in `AuthoringResourceRef.extensions`.
Do not invent a promoted capability from a model's mere presence.

- [ ] **Step 4: Implement bounded queries and impact**

Use iterative breadth-first traversal with visited sets. Provide deterministic
dependencies, dependents, bounded graph, broken-reference query, delete impact,
and rename impact.

- [ ] **Step 5: Reuse narrative picker read models**

Add a picker projection that calls
`buildCanonicalNarrativeReferencePickerReadModel` and adapts the returned
options without duplicating narrative compatibility logic.

- [ ] **Step 6: Run focused tests**

Run:

```bash
cd packages/map_authoring
dart test test/references/project_reference_index_test.dart
dart analyze
```

---

### Task 6: PMCP-012 — Adapt explicit capability truth

**Files:**

- Create: `packages/map_authoring/lib/src/domains/project/capability_truth_adapter.dart`
- Create: `packages/map_authoring/test/domains/project/capability_truth_adapter_test.dart`
- Modify: `packages/map_authoring/lib/map_authoring.dart`

- [ ] **Step 1: Write failing capability tests**

Verify that explicit `ProjectCapabilityTruthRecord` attestations are preserved,
issues remain coded, output is deterministic, and a populated manifest alone
cannot create a promoted capability.

- [ ] **Step 2: Run and verify RED**

```bash
cd packages/map_authoring
dart test test/domains/project/capability_truth_adapter_test.dart
```

- [ ] **Step 3: Implement the adapter**

The adapter accepts explicit records and required capability IDs, delegates to
`ProjectCapabilityTruthReport.evaluate`, and returns an immutable JSON-safe
authoring projection. It has no API accepting only `ProjectManifest`.

- [ ] **Step 4: Verify PMCP-012 completely**

Run:

```bash
cd packages/map_authoring
dart test test/references
dart test test/domains/project/capability_truth_adapter_test.dart
dart test
dart analyze
dart format --output=none --set-exit-if-changed lib test
```

- [ ] **Step 5: Write report and commit PMCP-012**

Create:

`reports/analysis/pmcp_012_reference_diagnostics_evidence.md`

Then:

```bash
git add -- packages/map_authoring \
  reports/analysis/pmcp_012_reference_diagnostics_evidence.md
git commit -m "feat(authoring): add reference diagnostics"
```

Verify the commit and clean tree.

---

### Task 7: PMCP-013 — Build the shared read API and strict JSONL worker

**Files:**

- Create: `packages/map_authoring/lib/src/api/authoring_read_api.dart`
- Create: `packages/map_authoring/lib/src/tooling/jsonl_worker.dart`
- Create: `packages/map_authoring/lib/src/tooling/cli_exit_codes.dart`
- Create: `packages/map_authoring/test/tooling/jsonl_worker_test.dart`
- Create: `packages/map_authoring/test/tooling/goldens/describe_and_error.jsonl`
- Modify: `packages/map_authoring/lib/map_authoring.dart`

- [ ] **Step 1: Write failing worker tests**

Use deterministic clock/token injection and cover:

- `describe`, `open`, `query`, `validate`, and `close`;
- strict one-object-per-line responses;
- malformed JSON returning a coded failure while the next request succeeds;
- unknown commands;
- maximum UTF-8 input size;
- per-command timeout;
- no write command in `describe`;
- direct API result equals decoded worker result.

- [ ] **Step 2: Run and verify RED**

```bash
cd packages/map_authoring
dart test test/tooling/jsonl_worker_test.dart
```

- [ ] **Step 3: Implement the shared read API**

`AuthoringReadApi` owns the open service, snapshot loader, query service, and
reference/capability validation. Each public method returns JSON-safe maps and
throws only safe domain exceptions.

- [ ] **Step 4: Implement the worker**

`JsonlWorker.processLine`:

1. checks the UTF-8 byte limit;
2. decodes exactly one JSON object;
3. requires nonblank `id` and `command`;
4. dispatches only `describe`, `open`, `query`, `validate`, or `close`;
5. applies a timeout;
6. converts safe domain errors into `AuthoringResult.failure`;
7. converts unexpected errors into a generic non-retryable internal error
   without exception text;
8. returns exactly one `jsonEncode` line.

- [ ] **Step 5: Add deterministic golden transcript**

The golden contains exact `describe` and malformed-input results. The test
normalizes no fields; output must match byte-for-byte.

- [ ] **Step 6: Run focused tests**

```bash
cd packages/map_authoring
dart test test/tooling/jsonl_worker_test.dart
dart analyze
```

---

### Task 8: PMCP-013 — Add the executable and end-to-end CLI proof

**Files:**

- Create: `packages/map_authoring/bin/pokemap_authoring.dart`
- Create: `packages/map_authoring/test/tooling/cli_golden_test.dart`
- Modify: `packages/map_authoring/pubspec.yaml`

- [ ] **Step 1: Write failing CLI process tests**

Spawn the Dart executable with an allowed fixture root, send JSONL commands,
and assert:

- stdout contains only valid JSON objects;
- stderr is empty on the successful session;
- real project `open`, `query`, `validate`, and `close` succeed;
- malformed input produces a failure envelope and does not kill the worker;
- direct API and CLI query data are equal.

- [ ] **Step 2: Run and verify RED**

```bash
cd packages/map_authoring
dart test test/tooling/cli_golden_test.dart
```

Expected: failure because the executable does not exist.

- [ ] **Step 3: Implement CLI argument parsing and stream loop**

Support:

```text
pokemap_authoring --root <allowed-root> [--root <allowed-root> ...]
                  [--timeout-ms <positive-int>]
                  [--max-input-bytes <positive-int>]
```

Require at least one root. Reserve stdout for worker envelopes and stderr for
startup/operator diagnostics. Use documented sysexits-style constants from
`cli_exit_codes.dart`.

- [ ] **Step 4: Declare the executable**

```yaml
executables:
  pokemap_authoring: pokemap_authoring
```

- [ ] **Step 5: Verify PMCP-013 and phase 2**

Run:

```bash
cd packages/map_authoring
dart test test/tooling/jsonl_worker_test.dart
dart test test/tooling/cli_golden_test.dart
dart test
dart analyze
dart format --output=none --set-exit-if-changed bin lib test
dart compile exe bin/pokemap_authoring.dart -o /tmp/pokemap_authoring_phase_2
```

Then run:

```bash
cd packages/map_core
dart test
dart analyze
```

Expected: all commands exit `0`; the CLI binary compiles.

- [ ] **Step 6: Perform final critical review**

Review:

- path containment and symlink race limits;
- handle expiry and unknown-handle behavior;
- snapshot coherence and cursor binding;
- field-mask data leakage;
- graph cycle/limit behavior;
- capability promotion rules;
- stdout/stderr separation;
- input limits, timeouts, and raw-exception redaction;
- absence of filesystem write methods and forbidden dependencies.

Add a failing regression test before fixing every defect found.

- [ ] **Step 7: Write final lot and phase evidence**

Create:

- `reports/analysis/pmcp_013_read_only_jsonl_cli_evidence.md`
- `reports/analysis/pmcp_phase_2_read_api_evidence.md`

Include lot verdicts, initial/final Git states, commit hashes, complete file
inventory, exact commands and results, build proof, non-goals, risks, and
recommended next lot.

- [ ] **Step 8: Commit PMCP-013**

```bash
git add -- packages/map_authoring reports/analysis
git commit -m "feat(authoring): add read-only JSONL CLI"
```

Verify:

```bash
git status --short --untracked-files=all
git log -4 --oneline --decorate
```

Expected: clean working tree and four ordered phase 2 commits.

---

## Self-review

### Spec coverage

- `PMCP-010`: allowed roots, canonicalization, symlinks, opaque expiring
  handles, close, read-only behavior, and initial fingerprint are covered.
- `PMCP-011`: coherent snapshots, global revision, five query operations,
  masks, filters, deterministic sorting, revision-bound cursors, summary/detail,
  and map-region projection are covered.
- `PMCP-012`: typed index, dependencies/dependents, bounded graph, impacts,
  broken references, narrative read-model reuse, capability truth, and coded
  navigation diagnostics are covered.
- `PMCP-013`: executable, five commands, strict JSONL, output-channel rules,
  exit codes, limits, timeouts, goldens, direct/CLI parity, and real-project
  proof are covered.

### Type consistency

- Every lot consumes the public types introduced by the preceding lot.
- `ProjectHandle` is the only public lookup token; canonical paths remain
  private store state.
- `ProjectSnapshot.revision` is the cursor and diagnostic consistency token.
- JSONL `query` accepts `AuthoringQueryRequest.fromJson` and returns
  `AuthoringQueryPage.toJson`, ensuring direct/CLI parity.

### Non-goals preserved

- no write operation;
- no MCP transport;
- no Flutter/Flame import;
- no mutation registry handlers;
- no CAS, durable ledger, recovery, undo, render, or playtest;
- no claim of complete action-catalog parity.
~~~~~~~~
## `packages/map_authoring/lib/src/ports/project_file_reader.dart`

~~~~~~~~dart
import 'dart:io';

/// Stable, path-free failure raised by the read-only project filesystem port.
final class WorkspaceAccessException implements Exception {
  const WorkspaceAccessException(this.code, this.message);

  final String code;
  final String message;

  @override
  String toString() => 'WorkspaceAccessException($code): $message';
}

/// The complete filesystem capability available to the Authoring Read API.
///
/// Deliberately no mutation method is exposed by this port.
abstract interface class ProjectFileReader {
  Future<String> canonicalizeDirectory(String path);

  Future<List<int>> readBytes({
    required String projectRoot,
    required String relativePath,
  });
}

/// `dart:io` implementation constrained to an already-authorized project root.
final class LocalProjectFileReader implements ProjectFileReader {
  const LocalProjectFileReader();

  @override
  Future<String> canonicalizeDirectory(String path) async {
    final normalized = _requirePath(path, field: 'directory');
    try {
      final directory = Directory(normalized);
      final stat = await directory.stat();
      if (stat.type != FileSystemEntityType.directory) {
        throw const WorkspaceAccessException(
          'workspace.directory_required',
          'The requested workspace root is not a directory.',
        );
      }
      return await directory.resolveSymbolicLinks();
    } on WorkspaceAccessException {
      rethrow;
    } on FileSystemException {
      throw const WorkspaceAccessException(
        'workspace.directory_unavailable',
        'The requested workspace root is unavailable.',
      );
    }
  }

  @override
  Future<List<int>> readBytes({
    required String projectRoot,
    required String relativePath,
  }) async {
    final root = _requirePath(projectRoot, field: 'projectRoot');
    final segments = _projectRelativeSegments(relativePath);
    final lexicalTarget = [root, ...segments].join(Platform.pathSeparator);
    try {
      final resolvedBefore = await File(lexicalTarget).resolveSymbolicLinks();
      if (!workspacePathIsWithin(root: root, candidate: resolvedBefore)) {
        throw const WorkspaceAccessException(
          'workspace.path_outside_project',
          'The requested project resource resolves outside the project.',
        );
      }
      final file = File(resolvedBefore);
      final stat = await file.stat();
      if (stat.type != FileSystemEntityType.file) {
        throw const WorkspaceAccessException(
          'workspace.file_required',
          'The requested project resource is not a regular file.',
        );
      }
      final bytes = await file.readAsBytes();
      final resolvedAfter = await File(lexicalTarget).resolveSymbolicLinks();
      if (resolvedAfter != resolvedBefore ||
          !workspacePathIsWithin(root: root, candidate: resolvedAfter)) {
        throw const WorkspaceAccessException(
          'workspace.path_changed_during_read',
          'The requested project resource changed while it was read.',
        );
      }
      return List<int>.unmodifiable(bytes);
    } on WorkspaceAccessException {
      rethrow;
    } on FileSystemException {
      throw const WorkspaceAccessException(
        'workspace.file_unavailable',
        'The requested project resource is unavailable.',
      );
    }
  }
}

bool workspacePathIsWithin({
  required String root,
  required String candidate,
}) {
  if (candidate == root) return true;
  final rootWithSeparator = root.endsWith(Platform.pathSeparator)
      ? root
      : '$root${Platform.pathSeparator}';
  return candidate.startsWith(rootWithSeparator);
}

List<String> validateProjectRelativePath(String value) =>
    List<String>.unmodifiable(_projectRelativeSegments(value));

String _requirePath(String value, {required String field}) {
  final normalized = value.trim();
  if (normalized.isEmpty || normalized.contains('\u0000')) {
    throw WorkspaceAccessException(
      'workspace.path_invalid',
      'The $field path is invalid.',
    );
  }
  return normalized;
}

List<String> _projectRelativeSegments(String value) {
  final normalized = _requirePath(value, field: 'resource');
  if (File(normalized).isAbsolute ||
      normalized.startsWith('/') ||
      normalized.startsWith(r'\') ||
      RegExp(r'^[A-Za-z]:[\\/]').hasMatch(normalized)) {
    throw const WorkspaceAccessException(
      'workspace.path_absolute',
      'Project resource paths must be relative.',
    );
  }
  final segments = normalized.split(RegExp(r'[\\/]'));
  if (segments.any((segment) => segment == '..')) {
    throw const WorkspaceAccessException(
      'workspace.path_traversal',
      'Project resource paths cannot contain traversal segments.',
    );
  }
  final meaningful = segments.where((segment) => segment.isNotEmpty).toList();
  if (meaningful.isEmpty || meaningful.any((segment) => segment == '.')) {
    throw const WorkspaceAccessException(
      'workspace.path_invalid',
      'The project resource path is invalid.',
    );
  }
  return meaningful;
}
~~~~~~~~

## `packages/map_authoring/lib/src/workspace/workspace_policy.dart`

~~~~~~~~dart
import '../ports/project_file_reader.dart';

/// Canonical allow-list policy for read-only PokeMap project roots.
final class WorkspacePolicy {
  WorkspacePolicy._({
    required ProjectFileReader fileReader,
    required List<String> canonicalAllowedRoots,
  })  : _fileReader = fileReader,
        _canonicalAllowedRoots = List.unmodifiable(canonicalAllowedRoots);

  static Future<WorkspacePolicy> create({
    required Iterable<String> allowedRootPaths,
    required ProjectFileReader fileReader,
  }) async {
    final requestedRoots = allowedRootPaths.toList(growable: false);
    if (requestedRoots.isEmpty) {
      throw const WorkspaceAccessException(
        'workspace.allowed_roots_required',
        'At least one allowed workspace root is required.',
      );
    }
    final canonicalRoots = <String>{};
    for (final root in requestedRoots) {
      canonicalRoots.add(await fileReader.canonicalizeDirectory(root));
    }
    final orderedRoots = canonicalRoots.toList()..sort();
    return WorkspacePolicy._(
      fileReader: fileReader,
      canonicalAllowedRoots: orderedRoots,
    );
  }

  final ProjectFileReader _fileReader;
  final List<String> _canonicalAllowedRoots;

  Future<String> authorizeProjectRoot(String projectRootPath) async {
    _rejectTraversal(projectRootPath);
    final canonicalProjectRoot =
        await _fileReader.canonicalizeDirectory(projectRootPath);
    if (!_canonicalAllowedRoots.any(
      (root) => workspacePathIsWithin(
        root: root,
        candidate: canonicalProjectRoot,
      ),
    )) {
      throw const WorkspaceAccessException(
        'workspace.path_outside_allowed_roots',
        'The requested project is outside the allowed workspace roots.',
      );
    }
    return canonicalProjectRoot;
  }
}

void _rejectTraversal(String value) {
  if (value.trim().isEmpty || value.contains('\u0000')) {
    throw const WorkspaceAccessException(
      'workspace.path_invalid',
      'The requested project path is invalid.',
    );
  }
  if (value.split(RegExp(r'[\\/]')).any((segment) => segment == '..')) {
    throw const WorkspaceAccessException(
      'workspace.path_traversal',
      'Workspace paths cannot contain traversal segments.',
    );
  }
}
~~~~~~~~

## `packages/map_authoring/lib/src/workspace/workspace_handle_store.dart`

~~~~~~~~dart
import 'dart:math';

typedef WorkspaceClock = DateTime Function();
typedef WorkspaceTokenFactory = String Function(String prefix);
typedef ProjectResourceReader = Future<List<int>> Function(String relativePath);

final class WorkspaceHandle {
  const WorkspaceHandle(this.value);

  final String value;

  @override
  bool operator ==(Object other) =>
      other is WorkspaceHandle && other.value == value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => value;
}

final class ProjectHandle {
  const ProjectHandle(this.value);

  final String value;

  @override
  bool operator ==(Object other) =>
      other is ProjectHandle && other.value == value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => value;
}

final class WorkspaceHandleException implements Exception {
  const WorkspaceHandleException(this.code, this.message);

  final String code;
  final String message;

  @override
  String toString() => 'WorkspaceHandleException($code): $message';
}

/// Authorized read-only access associated with an opaque project handle.
///
/// The canonical filesystem root remains captured privately by [readBytes].
final class ProjectWorkspaceAccess {
  ProjectWorkspaceAccess._({
    required this.projectHandle,
    required this.projectName,
    required this.initialFingerprint,
    required this.expiresAt,
    required ProjectResourceReader readBytes,
  }) : _readBytes = readBytes;

  final ProjectHandle projectHandle;
  final String projectName;
  final String initialFingerprint;
  final DateTime expiresAt;
  final ProjectResourceReader _readBytes;

  Future<List<int>> readBytes(String relativePath) async =>
      List<int>.unmodifiable(await _readBytes(relativePath));
}

final class RegisteredProjectHandles {
  const RegisteredProjectHandles({
    required this.workspaceHandle,
    required this.projectHandle,
    required this.expiresAt,
  });

  final WorkspaceHandle workspaceHandle;
  final ProjectHandle projectHandle;
  final DateTime expiresAt;
}

/// In-memory, expiring handle store. Durable sessions are outside phase 2.
final class WorkspaceHandleStore {
  WorkspaceHandleStore({
    WorkspaceClock? clock,
    WorkspaceTokenFactory? tokenFactory,
    this.ttl = const Duration(minutes: 15),
  })  : _clock = clock ?? _systemClock,
        _tokenFactory = tokenFactory ?? _secureToken {
    if (ttl <= Duration.zero) {
      throw ArgumentError.value(ttl, 'ttl', 'must be positive');
    }
  }

  final WorkspaceClock _clock;
  final WorkspaceTokenFactory _tokenFactory;
  final Duration ttl;
  final Map<WorkspaceHandle, ProjectHandle> _projectsByWorkspace = {};
  final Map<ProjectHandle, _StoredProjectAccess> _projects = {};

  RegisteredProjectHandles registerProject({
    required String projectName,
    required String initialFingerprint,
    required ProjectResourceReader readBytes,
  }) {
    final workspaceHandle = WorkspaceHandle(_nextUniqueToken('ws_'));
    final projectHandle = ProjectHandle(_nextUniqueToken('prj_'));
    final expiresAt = _clock().toUtc().add(ttl);
    _projectsByWorkspace[workspaceHandle] = projectHandle;
    _projects[projectHandle] = _StoredProjectAccess(
      workspaceHandle: workspaceHandle,
      projectName: projectName,
      initialFingerprint: initialFingerprint,
      expiresAt: expiresAt,
      readBytes: readBytes,
    );
    return RegisteredProjectHandles(
      workspaceHandle: workspaceHandle,
      projectHandle: projectHandle,
      expiresAt: expiresAt,
    );
  }

  ProjectWorkspaceAccess resolveProject(ProjectHandle handle) {
    final stored = _requireActive(handle);
    return ProjectWorkspaceAccess._(
      projectHandle: handle,
      projectName: stored.projectName,
      initialFingerprint: stored.initialFingerprint,
      expiresAt: stored.expiresAt,
      readBytes: (relativePath) => _readForHandle(handle, relativePath),
    );
  }

  bool closeWorkspace(WorkspaceHandle handle) {
    final projectHandle = _projectsByWorkspace.remove(handle);
    if (projectHandle == null) return false;
    _projects.remove(projectHandle);
    return true;
  }

  _StoredProjectAccess _requireActive(ProjectHandle handle) {
    final stored = _projects[handle];
    if (stored == null) {
      throw const WorkspaceHandleException(
        'workspace.handle_unknown',
        'The requested project handle is unknown.',
      );
    }
    if (!_clock().toUtc().isBefore(stored.expiresAt)) {
      _remove(handle, stored);
      throw const WorkspaceHandleException(
        'workspace.handle_expired',
        'The requested project handle has expired.',
      );
    }
    return stored;
  }

  Future<List<int>> _readForHandle(
    ProjectHandle handle,
    String relativePath,
  ) async {
    final stored = _requireActive(handle);
    final bytes = await stored.readBytes(relativePath);
    _requireActive(handle);
    return List<int>.unmodifiable(bytes);
  }

  void _remove(ProjectHandle handle, _StoredProjectAccess stored) {
    _projects.remove(handle);
    _projectsByWorkspace.remove(stored.workspaceHandle);
  }

  String _nextUniqueToken(String prefix) {
    for (var attempt = 0; attempt < 32; attempt++) {
      final token = _tokenFactory(prefix).trim();
      if (!token.startsWith(prefix) || token.length <= prefix.length) {
        throw ArgumentError.value(
          token,
          'tokenFactory',
          'must return a nonblank token beginning with $prefix',
        );
      }
      final alreadyUsed =
          _projects.keys.any((handle) => handle.value == token) ||
              _projectsByWorkspace.keys.any((handle) => handle.value == token);
      if (!alreadyUsed) return token;
    }
    throw StateError('Unable to allocate a unique workspace handle.');
  }
}

final class _StoredProjectAccess {
  const _StoredProjectAccess({
    required this.workspaceHandle,
    required this.projectName,
    required this.initialFingerprint,
    required this.expiresAt,
    required this.readBytes,
  });

  final WorkspaceHandle workspaceHandle;
  final String projectName;
  final String initialFingerprint;
  final DateTime expiresAt;
  final ProjectResourceReader readBytes;
}

DateTime _systemClock() => DateTime.now().toUtc();

String _secureToken(String prefix) {
  final random = Random.secure();
  final body = List.generate(
    24,
    (_) => random.nextInt(256).toRadixString(16).padLeft(2, '0'),
  ).join();
  return '$prefix$body';
}
~~~~~~~~

## `packages/map_authoring/lib/src/workspace/project_open_service.dart`

~~~~~~~~dart
import 'dart:convert';

import 'package:map_core/map_core.dart';

import '../ports/project_file_reader.dart';
import 'workspace_handle_store.dart';
import 'workspace_policy.dart';

final class ProjectOpenException implements Exception {
  const ProjectOpenException(this.code, this.message);

  final String code;
  final String message;

  @override
  String toString() => 'ProjectOpenException($code): $message';
}

final class OpenedProject {
  const OpenedProject({
    required this.workspaceHandle,
    required this.projectHandle,
    required this.projectName,
    required this.fingerprint,
    required this.expiresAt,
  });

  final WorkspaceHandle workspaceHandle;
  final ProjectHandle projectHandle;
  final String projectName;
  final String fingerprint;
  final DateTime expiresAt;

  bool get readOnly => true;

  Map<String, Object?> toJson() => {
        'workspaceHandle': workspaceHandle.value,
        'projectHandle': projectHandle.value,
        'projectName': projectName,
        'fingerprint': fingerprint,
        'expiresAt': expiresAt.toUtc().toIso8601String(),
        'readOnly': true,
      };
}

final class ProjectOpenService {
  const ProjectOpenService({
    required WorkspacePolicy policy,
    required ProjectFileReader fileReader,
    required WorkspaceHandleStore handles,
  })  : _policy = policy,
        _fileReader = fileReader,
        _handles = handles;

  final WorkspacePolicy _policy;
  final ProjectFileReader _fileReader;
  final WorkspaceHandleStore _handles;

  Future<OpenedProject> openProject(String projectRootPath) async {
    final canonicalRoot = await _policy.authorizeProjectRoot(projectRootPath);
    final manifestBytes = await _fileReader.readBytes(
      projectRoot: canonicalRoot,
      relativePath: 'project.json',
    );
    final manifest = _decodeManifest(manifestBytes);
    final fingerprint = computeNarrativeProjectFingerprint([
      NarrativeProjectFingerprintEntry(
        relativePath: 'project.json',
        bytes: manifestBytes,
      ),
    ]);
    final registered = _handles.registerProject(
      projectName: manifest.name,
      initialFingerprint: fingerprint,
      readBytes: (relativePath) => _fileReader.readBytes(
        projectRoot: canonicalRoot,
        relativePath: relativePath,
      ),
    );
    return OpenedProject(
      workspaceHandle: registered.workspaceHandle,
      projectHandle: registered.projectHandle,
      projectName: manifest.name,
      fingerprint: fingerprint,
      expiresAt: registered.expiresAt,
    );
  }

  bool closeWorkspace(WorkspaceHandle handle) =>
      _handles.closeWorkspace(handle);
}

ProjectManifest _decodeManifest(List<int> bytes) {
  try {
    final decoded = jsonDecode(utf8.decode(bytes));
    if (decoded is! Map) {
      throw const FormatException('Expected a JSON object.');
    }
    return ProjectManifest.fromJson(Map<String, dynamic>.from(decoded));
  } on Object {
    throw const ProjectOpenException(
      'project.manifest_invalid',
      'The project manifest is not valid PokeMap JSON.',
    );
  }
}
~~~~~~~~

## `packages/map_authoring/test/workspace/workspace_path_security_test.dart`

~~~~~~~~dart
import 'dart:io';

import 'package:map_authoring/map_authoring.dart';
import 'package:test/test.dart';

void main() {
  group('WorkspacePolicy', () {
    test('authorizes the real project below an allowed root', () async {
      final fixture = _realFixtureDirectory();
      final policy = await WorkspacePolicy.create(
        allowedRootPaths: [fixture.parent.path],
        fileReader: const LocalProjectFileReader(),
      );

      final authorized = await policy.authorizeProjectRoot(fixture.path);

      expect(authorized, await fixture.resolveSymbolicLinks());
    });

    test('rejects a project outside every allowed root', () async {
      final sandbox = await Directory.systemTemp.createTemp(
        'pokemap_workspace_policy_',
      );
      addTearDown(() => sandbox.delete(recursive: true));
      final allowed = await Directory(_join(sandbox.path, 'allowed')).create();
      final outside = await Directory(_join(sandbox.path, 'outside')).create();
      final policy = await WorkspacePolicy.create(
        allowedRootPaths: [allowed.path],
        fileReader: const LocalProjectFileReader(),
      );

      await expectLater(
        () => policy.authorizeProjectRoot(outside.path),
        throwsA(
          isA<WorkspaceAccessException>().having(
            (error) => error.code,
            'code',
            'workspace.path_outside_allowed_roots',
          ),
        ),
      );
    });

    test('rejects traversal before filesystem resolution', () async {
      final sandbox = await Directory.systemTemp.createTemp(
        'pokemap_workspace_traversal_',
      );
      addTearDown(() => sandbox.delete(recursive: true));
      final allowed = await Directory(_join(sandbox.path, 'allowed')).create();
      final project = await Directory(_join(allowed.path, 'project')).create();
      final sibling = await Directory(_join(allowed.path, 'sibling')).create();
      final policy = await WorkspacePolicy.create(
        allowedRootPaths: [allowed.path],
        fileReader: const LocalProjectFileReader(),
      );

      await expectLater(
        () => policy.authorizeProjectRoot(
          _join(project.path, '..', sibling.uri.pathSegments.last),
        ),
        throwsA(
          isA<WorkspaceAccessException>().having(
            (error) => error.code,
            'code',
            'workspace.path_traversal',
          ),
        ),
      );
    });
  });

  group('LocalProjectFileReader', () {
    test('reads a regular project-relative file', () async {
      final sandbox = await Directory.systemTemp.createTemp(
        'pokemap_file_reader_',
      );
      addTearDown(() => sandbox.delete(recursive: true));
      final project = await Directory(_join(sandbox.path, 'project')).create();
      final maps = await Directory(_join(project.path, 'maps')).create();
      await File(_join(maps.path, 'field.json')).writeAsString('{"id":"map"}');
      final canonicalRoot = await project.resolveSymbolicLinks();

      final bytes = await const LocalProjectFileReader().readBytes(
        projectRoot: canonicalRoot,
        relativePath: 'maps/field.json',
      );

      expect(String.fromCharCodes(bytes), '{"id":"map"}');
    });

    test('rejects an absolute project-relative path', () async {
      final project = _realFixtureDirectory();
      final canonicalRoot = await project.resolveSymbolicLinks();

      await expectLater(
        () => const LocalProjectFileReader().readBytes(
          projectRoot: canonicalRoot,
          relativePath: _join(canonicalRoot, 'project.json'),
        ),
        throwsA(
          isA<WorkspaceAccessException>().having(
            (error) => error.code,
            'code',
            'workspace.path_absolute',
          ),
        ),
      );
    });

    test('rejects a relative traversal', () async {
      final project = _realFixtureDirectory();
      final canonicalRoot = await project.resolveSymbolicLinks();

      await expectLater(
        () => const LocalProjectFileReader().readBytes(
          projectRoot: canonicalRoot,
          relativePath: '../project.json',
        ),
        throwsA(
          isA<WorkspaceAccessException>().having(
            (error) => error.code,
            'code',
            'workspace.path_traversal',
          ),
        ),
      );
    });

    test('rejects an outward symlink', () async {
      final sandbox = await Directory.systemTemp.createTemp(
        'pokemap_outward_symlink_',
      );
      addTearDown(() => sandbox.delete(recursive: true));
      final allowed = await Directory(_join(sandbox.path, 'allowed')).create();
      final project = await Directory(_join(allowed.path, 'project')).create();
      final maps = await Directory(_join(project.path, 'maps')).create();
      final outside = await Directory(_join(sandbox.path, 'outside')).create();
      final secret = File(_join(outside.path, 'secret.json'));
      await secret.writeAsString('{"secret":true}');
      await Link(_join(maps.path, 'outward.json')).create(secret.path);
      final canonicalRoot = await project.resolveSymbolicLinks();

      await expectLater(
        () => const LocalProjectFileReader().readBytes(
          projectRoot: canonicalRoot,
          relativePath: 'maps/outward.json',
        ),
        throwsA(
          isA<WorkspaceAccessException>().having(
            (error) => error.code,
            'code',
            'workspace.path_outside_project',
          ),
        ),
      );
    });

    test('does not expose a filesystem write method', () {
      final source = File(
        _join(
          Directory.current.path,
          'lib',
          'src',
          'ports',
          'project_file_reader.dart',
        ),
      ).readAsStringSync();

      expect(source, isNot(contains('writeAs')));
      expect(source, isNot(contains('delete(')));
      expect(source, isNot(contains('rename(')));
    });
  });
}

Directory _realFixtureDirectory() {
  return Directory(
    _join(
      Directory.current.parent.parent.path,
      'examples',
      'playable_runtime_host',
      'p3_narrative_smoke_slice',
    ),
  );
}

String _join(
  String first,
  String second, [
  String? third,
  String? fourth,
  String? fifth,
]) {
  final parts = [
    first,
    second,
    if (third != null) third,
    if (fourth != null) fourth,
    if (fifth != null) fifth,
  ];
  return parts.join(Platform.pathSeparator);
}
~~~~~~~~

## `packages/map_authoring/test/workspace/project_open_service_test.dart`

~~~~~~~~dart
import 'dart:io';

import 'package:map_authoring/map_authoring.dart';
import 'package:test/test.dart';

void main() {
  group('ProjectOpenService', () {
    test('opens the real fixture with opaque read-only handles', () async {
      final fixture = _realFixtureDirectory();
      final projectFile = File(_join(fixture.path, 'project.json'));
      final before = await projectFile.readAsBytes();
      final harness = await _Harness.create(fixture.parent);

      final opened = await harness.service.openProject(fixture.path);

      expect(opened.workspaceHandle.value, startsWith('ws_'));
      expect(opened.projectHandle.value, startsWith('prj_'));
      expect(opened.projectName, 'P3 Narrative Smoke Slice');
      expect(opened.fingerprint, matches(r'^sha256:[0-9a-f]{64}$'));
      expect(opened.readOnly, isTrue);
      expect(opened.expiresAt, harness.now.add(const Duration(minutes: 5)));
      final serialized = opened.toJson().toString();
      expect(serialized, isNot(contains(fixture.path)));
      expect(serialized, isNot(contains('/Users/')));

      final access = harness.handles.resolveProject(opened.projectHandle);
      final manifestBytes = await access.readBytes('project.json');
      expect(manifestBytes, before);
      expect(await projectFile.readAsBytes(), before);
    });

    test('computes the same initial fingerprint for identical bytes', () async {
      final fixture = _realFixtureDirectory();
      final harness = await _Harness.create(fixture.parent);

      final first = await harness.service.openProject(fixture.path);
      final second = await harness.service.openProject(fixture.path);

      expect(second.fingerprint, first.fingerprint);
      expect(second.projectHandle, isNot(first.projectHandle));
    });

    test('rejects malformed project JSON with a safe code', () async {
      final sandbox = await Directory.systemTemp.createTemp(
        'pokemap_open_invalid_',
      );
      addTearDown(() => sandbox.delete(recursive: true));
      final project = await Directory(_join(sandbox.path, 'project')).create();
      await File(_join(project.path, 'project.json')).writeAsString('{broken');
      final harness = await _Harness.create(sandbox);

      await expectLater(
        () => harness.service.openProject(project.path),
        throwsA(
          isA<ProjectOpenException>()
              .having(
                (error) => error.code,
                'code',
                'project.manifest_invalid',
              )
              .having(
                (error) => error.toString(),
                'safe message',
                isNot(contains(project.path)),
              ),
        ),
      );
    });

    test('rejects an unknown project handle', () {
      var token = 0;
      final handles = WorkspaceHandleStore(
        clock: () => DateTime.utc(2026, 7, 31, 12),
        tokenFactory: (prefix) => '$prefix${token++}',
        ttl: const Duration(minutes: 5),
      );

      expect(
        () => handles.resolveProject(
          const ProjectHandle('prj_unknown'),
        ),
        throwsA(
          isA<WorkspaceHandleException>().having(
            (error) => error.code,
            'code',
            'workspace.handle_unknown',
          ),
        ),
      );
    });

    test('rejects and removes an expired project handle', () async {
      final fixture = _realFixtureDirectory();
      final harness = await _Harness.create(fixture.parent);
      final opened = await harness.service.openProject(fixture.path);
      final retainedAccess =
          harness.handles.resolveProject(opened.projectHandle);
      harness.now = harness.now.add(const Duration(minutes: 6));

      await expectLater(
        () => retainedAccess.readBytes('project.json'),
        throwsA(
          isA<WorkspaceHandleException>().having(
            (error) => error.code,
            'code',
            'workspace.handle_expired',
          ),
        ),
      );
      expect(
        () => harness.handles.resolveProject(opened.projectHandle),
        throwsA(
          isA<WorkspaceHandleException>().having(
            (error) => error.code,
            'code',
            'workspace.handle_unknown',
          ),
        ),
      );
    });

    test('closes a workspace idempotently and invalidates its project',
        () async {
      final fixture = _realFixtureDirectory();
      final harness = await _Harness.create(fixture.parent);
      final opened = await harness.service.openProject(fixture.path);
      final retainedAccess =
          harness.handles.resolveProject(opened.projectHandle);

      expect(
        harness.service.closeWorkspace(opened.workspaceHandle),
        isTrue,
      );
      expect(
        harness.service.closeWorkspace(opened.workspaceHandle),
        isFalse,
      );
      expect(
        () => harness.handles.resolveProject(opened.projectHandle),
        throwsA(isA<WorkspaceHandleException>()),
      );
      await expectLater(
        () => retainedAccess.readBytes('project.json'),
        throwsA(
          isA<WorkspaceHandleException>().having(
            (error) => error.code,
            'code',
            'workspace.handle_unknown',
          ),
        ),
      );
    });
  });
}

final class _Harness {
  _Harness._({
    required this.policy,
    required this.handles,
    required this.service,
    required _MutableClock clock,
  }) : _clock = clock;

  static Future<_Harness> create(Directory allowedRoot) async {
    var token = 0;
    final clock = _MutableClock(DateTime.utc(2026, 7, 31, 12));
    final reader = const LocalProjectFileReader();
    final policy = await WorkspacePolicy.create(
      allowedRootPaths: [allowedRoot.path],
      fileReader: reader,
    );
    final handles = WorkspaceHandleStore(
      clock: () => clock.value,
      tokenFactory: (prefix) => '$prefix${token++}',
      ttl: const Duration(minutes: 5),
    );
    return _Harness._(
      policy: policy,
      handles: handles,
      service: ProjectOpenService(
        policy: policy,
        fileReader: reader,
        handles: handles,
      ),
      clock: clock,
    );
  }

  final WorkspacePolicy policy;
  final WorkspaceHandleStore handles;
  final ProjectOpenService service;
  final _MutableClock _clock;

  DateTime get now => _clock.value;

  set now(DateTime value) => _clock.value = value;
}

final class _MutableClock {
  _MutableClock(this.value);

  DateTime value;
}

Directory _realFixtureDirectory() {
  return Directory(
    _join(
      Directory.current.parent.parent.path,
      'examples',
      'playable_runtime_host',
      'p3_narrative_smoke_slice',
    ),
  );
}

String _join(
  String first,
  String second, [
  String? third,
  String? fourth,
]) =>
    [
      first,
      second,
      if (third != null) third,
      if (fourth != null) fourth,
    ].join(Platform.pathSeparator);
~~~~~~~~
