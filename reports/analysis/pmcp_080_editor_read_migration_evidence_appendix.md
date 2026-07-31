# PMCP-080 — Annexe des fichiers créés

Cette annexe reproduit intégralement les fichiers créés par le lot PMCP-080.

## `packages/map_editor/lib/src/application/authoring_api/authoring_query_adapter.dart`

```dart
import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';

/// Opens one coherent Authoring snapshot for the editor's read projections.
///
/// This adapter intentionally exposes typed PokeMap models to the editor while
/// keeping handles, path authorization, revision calculation, query ordering,
/// pagination, and reference diagnostics owned by `map_authoring`.
final class AuthoringQueryAdapter {
  AuthoringQueryAdapter({required ProjectFileReader fileReader})
      : _fileReader = fileReader;

  final ProjectFileReader _fileReader;
  final Map<String, Future<EditorAuthoringReadSession>> _sessions = {};

  Future<EditorAuthoringReadSession> open(String projectRootPath) async {
    final canonicalRoot =
        await _fileReader.canonicalizeDirectory(projectRootPath);
    final existing = _sessions[canonicalRoot];
    if (existing != null) {
      final session = await existing;
      if (!session.isClosed) return session;
      _sessions.remove(canonicalRoot);
    }
    final opening = _openCanonical(canonicalRoot);
    _sessions[canonicalRoot] = opening;
    try {
      return await opening;
    } on Object {
      if (identical(_sessions[canonicalRoot], opening)) {
        _sessions.remove(canonicalRoot);
      }
      rethrow;
    }
  }

  Future<void> invalidate(String projectRootPath) async {
    final canonicalRoot =
        await _fileReader.canonicalizeDirectory(projectRootPath);
    final session = _sessions.remove(canonicalRoot);
    if (session != null) await (await session).close();
  }

  Future<void> closeAll() async {
    final sessions = _sessions.values.toList(growable: false);
    _sessions.clear();
    for (final session in sessions) {
      await (await session).close();
    }
  }

  Future<EditorAuthoringReadSession> _openCanonical(
    String canonicalRoot,
  ) async {
    // The user-selected project is the complete allowed root for this direct
    // editor session. Every declared resource is subsequently constrained to
    // that canonical directory by WorkspacePolicy/ProjectFileReader.
    final policy = await WorkspacePolicy.create(
      allowedRootPaths: [canonicalRoot],
      fileReader: _fileReader,
    );
    final handles = WorkspaceHandleStore();
    final snapshots = ProjectSnapshotLoader(handles: handles);
    final api = AuthoringReadApi(
      openService: ProjectOpenService(
        policy: policy,
        fileReader: _fileReader,
        handles: handles,
      ),
      snapshotLoader: snapshots,
    );
    final opened = await api.open(canonicalRoot);
    final workspaceHandle =
        WorkspaceHandle(opened['workspaceHandle']! as String);
    final projectHandle = ProjectHandle(opened['projectHandle']! as String);
    try {
      final snapshot = await snapshots.load(
        projectHandle,
        policy: ProjectSnapshotLoadPolicy.editorReadProjection,
      );
      return EditorAuthoringReadSession._(
        api: api,
        workspaceHandle: workspaceHandle,
        projectHandle: projectHandle,
        snapshot: snapshot,
      );
    } on Object {
      await api.close(workspaceHandle);
      rethrow;
    }
  }
}

/// Immutable editor view over exactly one Authoring snapshot revision.
final class EditorAuthoringReadSession {
  EditorAuthoringReadSession._({
    required AuthoringReadApiPort api,
    required WorkspaceHandle workspaceHandle,
    required ProjectHandle projectHandle,
    required ProjectSnapshot snapshot,
  })  : _api = api,
        _workspaceHandle = workspaceHandle,
        _projectHandle = projectHandle,
        _snapshot = snapshot;

  final AuthoringReadApiPort _api;
  final WorkspaceHandle _workspaceHandle;
  final ProjectHandle _projectHandle;
  final ProjectSnapshot _snapshot;
  final ProjectQueryService _queries = const ProjectQueryService();
  bool _closed = false;

  bool get isClosed => _closed;

  String get snapshotRevision => _snapshot.revision;

  ProjectManifest get manifest {
    _requireOpen();
    return _snapshot.manifest;
  }

  List<MapData> get maps {
    _requireOpen();
    return _snapshot.maps;
  }

  MapData? mapById(String mapId) {
    _requireOpen();
    return _snapshot.mapById(mapId);
  }

  MapData? mapByStorageKey(String storageKey) {
    _requireOpen();
    for (final entry in _snapshot.resourceStorageKeys.entries) {
      if (entry.value == storageKey && entry.key.startsWith('map:')) {
        return _snapshot.mapById(entry.key.substring('map:'.length));
      }
    }
    return null;
  }

  String? resourceRevision(String resourceIdentity) {
    _requireOpen();
    if (!_snapshot.resourceFingerprints.containsKey(resourceIdentity)) {
      return null;
    }
    // Editor map CAS predates the Authoring project fingerprint and is defined
    // over the exact document bytes only. Convert explicitly; never pass the
    // path-aware Authoring resource fingerprint off as the editor revision.
    return narrativeEventBytesFingerprint(
      _snapshot.resourceBytes(resourceIdentity),
    );
  }

  /// Executes against the frozen snapshot; repeated UI projections cannot
  /// trigger another parse or observe a mixed disk revision.
  Map<String, Object?> query(AuthoringQueryRequest request) {
    _requireOpen();
    return _queries.query(_snapshot, request).toJson();
  }

  /// Validation is deliberately fresh. It uses the canonical API again so an
  /// external edit is visible instead of being hidden by the UI snapshot.
  Future<Map<String, Object?>> validateFresh() {
    _requireOpen();
    return _api.validate(_projectHandle);
  }

  /// Snapshot-local diagnostics used by ordinary panels. This avoids I/O and
  /// therefore cannot disagree with the models currently projected by the UI.
  Map<String, Object?> validate() {
    _requireOpen();
    final references = ProjectReferenceIndex.fromSnapshot(_snapshot);
    final hasErrors = references.diagnostics.any(
          (diagnostic) => diagnostic.severity == ProjectReferenceSeverity.error,
        ) ||
        _snapshot.loadDiagnostics.any((diagnostic) => diagnostic.blocking);
    return {
      'snapshotRevision': _snapshot.revision,
      'valid': !hasErrors,
      'references': <String, Object?>{
        'nodeCount': references.nodes.length,
        'edgeCount': references.edges.length,
        'hasErrors': hasErrors,
        'diagnostics': [
          for (final diagnostic in references.diagnostics) diagnostic.toJson(),
          for (final diagnostic in _snapshot.loadDiagnostics)
            diagnostic.toJson(),
        ],
      },
    };
  }

  Future<void> close() async {
    if (_closed) return;
    _closed = true;
    await _api.close(_workspaceHandle);
  }

  void _requireOpen() {
    if (_closed) {
      throw StateError('The editor Authoring read session is closed.');
    }
  }
}
```
## `packages/map_editor/lib/src/infrastructure/authoring_api/editor_project_file_reader.dart`

```dart
import 'package:map_authoring/map_authoring.dart';

/// Editor-owned adapter for the read-only filesystem capability expected by
/// `map_authoring`.
///
/// Keeping this class in infrastructure makes the ownership boundary visible:
/// application/UI code receives snapshots and query projections, never raw
/// filesystem paths or JSON bytes. Path canonicalization and symlink checks
/// remain delegated to the canonical Authoring implementation.
final class EditorProjectFileReader implements ProjectFileReader {
  const EditorProjectFileReader({
    ProjectFileReader delegate = const LocalProjectFileReader(),
  }) : _delegate = delegate;

  final ProjectFileReader _delegate;

  @override
  Future<String> canonicalizeDirectory(String path) {
    return _delegate.canonicalizeDirectory(path);
  }

  @override
  Future<List<int>> readBytes({
    required String projectRoot,
    required String relativePath,
  }) {
    return _delegate.readBytes(
      projectRoot: projectRoot,
      relativePath: relativePath,
    );
  }
}
```

## `packages/map_editor/test/authoring_api/editor_read_parity_test.dart`

```dart
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/application/authoring_api/authoring_query_adapter.dart';
import 'package:map_editor/src/infrastructure/authoring_api/editor_project_file_reader.dart';
import 'package:map_editor/src/infrastructure/repositories/file_repositories.dart';

void main() {
  group('AuthoringQueryAdapter', () {
    test('keeps project and map projections identical to the reference files',
        () async {
      final fixture = _goldenFangameFixture();
      final legacyManifest = ProjectManifest.fromJson(
        Map<String, dynamic>.from(
          jsonDecode(
            await File('${fixture.path}/project.json').readAsString(),
          ) as Map,
        ),
      );
      final reader = _CountingReader(const EditorProjectFileReader());
      final adapter = AuthoringQueryAdapter(fileReader: reader);

      final session = await adapter.open(fixture.path);
      addTearDown(session.close);

      expect(session.manifest.toJson(), legacyManifest.toJson());
      expect(
        session.maps.map((map) => map.id),
        ['golden_route', 'golden_summit', 'golden_town'],
      );
      for (final map in session.maps) {
        final entry = legacyManifest.maps.singleWhere(
          (candidate) => candidate.id == map.id,
        );
        final legacyMap = MapData.fromJson(
          Map<String, dynamic>.from(
            jsonDecode(
              await File('${fixture.path}/${entry.relativePath}')
                  .readAsString(),
            ) as Map,
          ),
        );
        expect(map.toJson(), legacyMap.toJson());
      }
      expect(session.snapshotRevision, matches(r'^sha256:[0-9a-f]{64}$'));
    });

    test('paginates and searches the frozen snapshot without rereading files',
        () async {
      final reader = _CountingReader(const EditorProjectFileReader());
      final session = await AuthoringQueryAdapter(fileReader: reader)
          .open(_goldenFangameFixture().path);
      addTearDown(session.close);
      final readsAfterOpen = reader.readCount;

      final first = session.query(
        AuthoringQueryRequest(
          resourceKind: 'map',
          operation: AuthoringQueryOperation.list,
          pageSize: 2,
        ),
      );
      final second = session.query(
        AuthoringQueryRequest(
          resourceKind: 'map',
          operation: AuthoringQueryOperation.list,
          pageSize: 2,
          cursor: first['nextCursor']! as String,
        ),
      );
      final search = session.query(
        AuthoringQueryRequest(
          resourceKind: 'map',
          operation: AuthoringQueryOperation.search,
          searchTerm: 'golden',
          sort: const [AuthoringQuerySort(field: 'name')],
          pageSize: 10,
        ),
      );

      expect(_ids(first), ['golden_route', 'golden_summit']);
      expect(_ids(second), ['golden_town']);
      expect(_ids(search), ['golden_route', 'golden_summit', 'golden_town']);
      expect(reader.readCount, readsAfterOpen);
    });

    test('reports reference diagnostics and closes handles fail-closed',
        () async {
      final session = await AuthoringQueryAdapter(
        fileReader: const EditorProjectFileReader(),
      ).open(_goldenFangameFixture().path);

      final validation = session.validate();
      expect(validation['snapshotRevision'], session.snapshotRevision);
      expect(validation['references'], isA<Map<String, Object?>>());

      await session.close();
      expect(
        () => session.query(
          AuthoringQueryRequest(
            resourceKind: 'project',
            operation: AuthoringQueryOperation.summary,
          ),
        ),
        throwsStateError,
      );
      await session.close();
    });

    test('shares one Authoring snapshot across project and map repositories',
        () async {
      final fixture = _goldenFangameFixture();
      final reader = _CountingReader(const EditorProjectFileReader());
      final adapter = AuthoringQueryAdapter(fileReader: reader);
      final projects = FileProjectRepository(authoringQueries: adapter);
      final maps = FileMapRepository(authoringQueries: adapter);

      final project =
          await projects.loadProject('${fixture.path}/project.json');
      final readsAfterProject = reader.readCount;
      final mapEntry = project.maps.singleWhere(
        (entry) => entry.id == 'golden_route',
      );
      final document = await maps.loadMapDocument(
        '${fixture.path}/${mapEntry.relativePath}',
      );

      expect(document.map.id, 'golden_route');
      expect(document.revision, matches(r'^sha256:[0-9a-f]{64}$'));
      expect(reader.readCount, readsAfterProject);
      await adapter.closeAll();
    });

    test('opens the reference project inside the read budget', () async {
      final stopwatch = Stopwatch()..start();
      final session = await AuthoringQueryAdapter(
        fileReader: const EditorProjectFileReader(),
      ).open(_goldenFangameFixture().path);
      stopwatch.stop();
      await session.close();

      // This is deliberately a generous regression ceiling, not a benchmark.
      // The immutable snapshot performs two filesystem passes by design.
      expect(stopwatch.elapsed, lessThan(const Duration(seconds: 5)));
    });

    test('opens the large Selbrume workspace inside the regression budget',
        () async {
      final stopwatch = Stopwatch()..start();
      final reader = _CountingReader(const EditorProjectFileReader());
      final session =
          await AuthoringQueryAdapter(fileReader: reader).open(_selbrume().path);
      stopwatch.stop();
      addTearDown(session.close);
      final readsAfterOpen = reader.readCount;

      final page = session.query(
        AuthoringQueryRequest(
          resourceKind: 'map',
          operation: AuthoringQueryOperation.list,
          pageSize: 100,
        ),
      );
      final dialogues = session.query(
        AuthoringQueryRequest(
          resourceKind: 'dialogue',
          operation: AuthoringQueryOperation.list,
          pageSize: 100,
        ),
      );
      final scenes = session.query(
        AuthoringQueryRequest(
          resourceKind: 'scene',
          operation: AuthoringQueryOperation.list,
          pageSize: 100,
        ),
      );

      expect(session.maps, hasLength(10));
      expect(page['totalAvailable'], 10);
      expect(dialogues['totalAvailable'], 24);
      expect(scenes['totalAvailable'], 35);
      expect(reader.readCount, readsAfterOpen);
      // Selbrume contains thousands of project files and large media assets.
      // Authoring reads only declared structured resources; this generous
      // ceiling guards an accidental workspace crawl without being a benchmark.
      expect(stopwatch.elapsed, lessThan(const Duration(seconds: 10)));
    });
  });
}

Directory _goldenFangameFixture() => Directory(
      '${Directory.current.parent.parent.path}/examples/'
      'playable_runtime_host/golden_fangame_slice',
    );

Directory _selbrume() => Directory(
      '${Directory.current.parent.parent.path}/selbrume',
    );

List<String> _ids(Map<String, Object?> page) => [
      for (final item in page['items']! as List<Object?>)
        (item! as Map<String, Object?>)['id']! as String,
    ];

final class _CountingReader implements ProjectFileReader {
  _CountingReader(this.delegate);

  final ProjectFileReader delegate;
  int readCount = 0;

  @override
  Future<String> canonicalizeDirectory(String path) {
    return delegate.canonicalizeDirectory(path);
  }

  @override
  Future<List<int>> readBytes({
    required String projectRoot,
    required String relativePath,
  }) {
    readCount++;
    return delegate.readBytes(
      projectRoot: projectRoot,
      relativePath: relativePath,
    );
  }
}
```

## `pokemap_authoring_api_mcp_phase_7_implementation_plan.md`

```markdown
# PokeMap Authoring API — Phase 7 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: use the repository's
> `executing-plans` workflow task by task. This run is inline because the user
> already requested implementation and the active instructions do not permit
> sub-agent delegation.

**Goal:** Make `map_editor` consume the canonical Authoring API and ship one
local MCP server that exposes the same read, mutation, render, playtest, job,
artifact, history, and recovery contracts without duplicating domain logic.

**Architecture:** Dart remains the only owner of PokeMap project semantics. The
Flutter editor uses small direct-Dart adapters, while the TypeScript MCP server
talks to the existing sandboxed JSONL worker over stdio. The MCP layer only
maps protocol schemas and errors; it never parses or writes project files.

**Tech stack:** Dart 3, Flutter/Riverpod, PokeMap `map_authoring`, Node 20+,
TypeScript 5, official MCP TypeScript SDK v2, Zod 4, Node test runner.

---

## Phase identity and baseline

- Roadmap phase: **Phase I — Parité éditeur et MCP**.
- Lots: **PMCP-080 → PMCP-084**.
- Execution: current branch, one verified commit per lot, no push.
- Initial Git base: `f61337c15 docs(authoring): correct PMCP-072 evidence wording`.
- Existing Smart Tiles/world-map edits, the host lockfile, and the untracked
  `.superpowers` prototype are external work and must never be staged.
- This phase changes no `FG-*` mechanic status and does not edit the gameplay
  roadmap.

## Phase exit contract

- Editor reads originate from one immutable Authoring snapshot per opened
  project and preserve UI ordering, typed models, diagnostics, and pagination.
- Product mutations use the Authoring plan/apply/history contracts at the
  migrated composition boundaries; receipts and conflicts are presented to UI
  code without importing Flutter into `map_authoring`.
- The selected MCP SDK/version/transport matrix is executable and documented.
- MCP read tools/resources inspect a real fixture and cannot write.
- MCP mutation tools expose plan/apply rather than one tool per action, keep
  retries idempotent, surface conflicts unchanged, and require confirmations.
- Render/playtest/job/artifact/history/recovery capabilities are advertised
  only when the configured Dart backend actually supports them.

## Task 1 — PMCP-080: editor read migration

**Files:**

- Create `packages/map_editor/lib/src/application/authoring_api/authoring_query_adapter.dart`.
- Create `packages/map_editor/lib/src/infrastructure/authoring_api/editor_project_file_reader.dart`.
- Create `packages/map_editor/test/authoring_api/editor_read_parity_test.dart`.
- Modify `packages/map_editor/pubspec.yaml` and the focused repository/provider
  composition files required to share one adapter.
- Create `reports/analysis/pmcp_080_editor_read_migration_evidence.md`.

- [ ] Write parity tests that open the reference fixture, compare typed project
  and map projections with the legacy decoder, assert stable search/pagination,
  reject a path outside the allowed root, and enforce a measured fixture budget.
- [ ] Run the test and record the expected missing-adapter failure.
- [ ] Implement one cached snapshot session with explicit close/invalidate;
  provide typed project/map reads and JSON query/validation projections.
- [ ] Inject the adapter at the editor repository composition root without
  changing any mutation behavior in this lot.
- [ ] Run focused tests, the complete editor suite/analyzer when affordable,
  `flutter build macos --debug` (or document the exact platform blocker), and
  write the evidence report.
- [ ] Stage only PMCP-080 paths, run `git diff --cached --check`, and commit
  `feat(editor): read projects through authoring snapshots`.

## Task 2 — PMCP-081: editor mutation migration

**Files:**

- Create `packages/map_editor/lib/src/application/authoring_api/authoring_mutation_adapter.dart`.
- Create `packages/map_editor/lib/src/application/authoring_api/editor_receipt_presenter.dart`.
- Create `packages/map_editor/test/authoring_api/editor_mutation_parity_test.dart`.
- Create `packages/map_editor/test/authoring_api/editor_write_boundary_test.dart`.
- Modify only clean editor repository/use-case composition files selected by
  the write-boundary inventory; do not touch the concurrent Smart Tiles files.
- Create `reports/analysis/pmcp_081_editor_mutation_migration_evidence.md`.

- [ ] Write failing tests for direct/API receipt parity, plan-before-apply,
  idempotent retry, stale external change, history-backed undo, and UI-safe
  conflict/confirmation presentation.
- [ ] Write a failing static guardrail that inventories project writes and
  accepts only named Authoring adapters plus explicitly documented platform
  sinks outside project authoring.
- [ ] Implement a session-bound mutation adapter over
  `AuthoringMutationApiPort`; it must never manufacture success receipts or
  swallow domain codes.
- [ ] Route the clean central project/map authoring composition boundaries
  through that adapter and keep Flutter types out of `map_authoring`.
- [ ] Run focused parity/guardrail tests, editor suite/analyzer/build, write the
  evidence report, and state honestly whether legacy specialized sinks keep the
  roadmap lot `PARTIAL`.
- [ ] Stage only PMCP-081 paths, check the staged diff, and commit
  `feat(editor): route mutations through authoring receipts`.

## Task 3 — PMCP-082: MCP SDK and protocol gate

**Files:**

- Create `tools/pokemap_mcp/package.json`, `package-lock.json`,
  `tsconfig.json`, `src/protocol.ts`, and focused SDK conformance tests.
- Create `reports/analysis/pmcp_082_mcp_sdk_compatibility_decision.md`.

- [ ] Pin the current official SDK and client packages rather than a moving
  range; record Node requirements and the exact npm metadata used.
- [ ] Write failing protocol tests for stdio discovery, tools/resources,
  structured content, protocol `2026-07-28`, documented fallback, and the Tasks
  extension behavior needed by PMCP-084.
- [ ] Implement the smallest server/client probe using the official SDK v2;
  include Streamable HTTP only if the stateless probe passes without adding
  project semantics to TypeScript.
- [ ] Run `npm test`, `npm run typecheck`, and `npm run build`; document the
  reproducible matrix, upgrade policy, and fallback.
- [ ] Stage only PMCP-082 paths, check the staged diff, and commit
  `build(mcp): select official sdk and protocol`.

## Task 4 — PMCP-083: read-only MCP and resources

**Files:**

- Create `tools/pokemap_mcp/src/authoring_client.ts`, server composition,
  read-only tool modules, resource modules, documentation, tests, and golden
  transcripts.
- Create `reports/analysis/pmcp_083_read_only_mcp_evidence.md`.

- [ ] Write failing tests for the stable tool list, schemas, real project open
  and query, validation, artifact read, pagination, invalid handles, invalid
  resource URIs, root escape, and absence of mutation tools.
- [ ] Implement a long-lived JSONL child-process client with correlated request
  IDs, bounded lines/timeouts, stderr isolation, close/kill cleanup, and no
  project parser.
- [ ] Register exactly `pokemap_describe`, read-only `pokemap_workspace`,
  `pokemap_query`, read-only `pokemap_validate`, and read-only
  `pokemap_artifact`, plus project/map/catalog/diagnostics templates.
- [ ] Run unit, protocol, golden, typecheck, build, and real-fixture smoke tests;
  write local connection documentation and the evidence report.
- [ ] Stage only PMCP-083 paths, check the staged diff, and commit
  `feat(mcp): add read-only pokemap server`.

## Task 5 — PMCP-084: mutation, render, playtest, jobs, history

**Files:**

- Extend the Dart JSONL backend only where protocol-neutral capabilities from
  phases 5/6 are not yet dispatchable.
- Extend `tools/pokemap_mcp/src/tools/`, `src/resources/`, client, tests, and
  transcripts without adding action-specific MCP tools.
- Create `reports/analysis/pmcp_084_full_mcp_authoring_evidence.md`.

- [ ] Write failing tests for plan/apply/confirmation, idempotent retry, stale
  conflict, render artifact, sandboxed playtest receipt, job status/events/
  cancel, history undo, and permission-gated recovery.
- [ ] Register exactly `pokemap_plan`, `pokemap_apply`, `pokemap_render`,
  `pokemap_playtest`, `pokemap_job`, `pokemap_history`, and
  `pokemap_recovery`; keep action growth behind `pokemap_apply`.
- [ ] Map Dart error envelopes into repairable MCP structured content without
  changing domain codes, retryability, remediation, or confirmation rules.
- [ ] Prove a real fixture batch can plan, preview, validate, apply, retry, and
  return artifacts; never advertise runtime-only capabilities without a real
  configured backend.
- [ ] Run Dart tests/analyzer plus all MCP tests/typecheck/build and the parity
  matrix; write the evidence report with remaining runtime-host limits.
- [ ] Stage only PMCP-084 paths, check the staged diff, and commit
  `feat(mcp): expose full authoring workflow`.

## Final verification and critique

- [ ] Re-read every PMCP-080…084 done criterion and mark `DONE`, `PARTIAL`, or
  `BLOCKED` from fresh proof only.
- [ ] Run five named local passes: Audit/Architecture, Implementation, Tests,
  Build/Validation, and Final Critique.
- [ ] Confirm every created source file is represented in the required evidence
  appendix/content and every external dirty file remains unstaged.
- [ ] Report exact commands/results, final commit list, known limits, and final
  `git status --short --untracked-files=all`; do not push.
```
