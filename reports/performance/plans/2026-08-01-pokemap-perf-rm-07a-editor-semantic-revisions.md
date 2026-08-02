# PERF-RM-07A Editor Semantic Revisions Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Prevent tile, viewport, and unrelated editor mutations from rebuilding the editor shell or its narrative projections while keeping map switches and narrative changes fresh.

**Architecture:** Keep `EditorState` as the single state system and use Riverpod semantic projections as the invalidation boundary. The shell will subscribe to the full active map only while a Narrative Studio product shell is visible; the World Map workspace keeps its existing focused providers. Narrative search construction becomes lazy, so a tile-only mutation cannot execute it.

**Tech Stack:** Dart 3, Flutter, Riverpod, `flutter_test`, existing PokeMap editor selectors and performance harnesses.

---

## Audit and constraints

- Baseline HEAD: `818db8a14c001bd932116dfe16a5df276223ce9c` on `main`, with unrelated pre-existing editor-tool files left unstaged.
- `EditorShellPage.build` currently watches `state.activeMap` unconditionally and calls `_globalSearchIndexFor` whenever the map identity changes.
- `editorShellSnapshotProvider` already emits a value-equal record for tile-only mutations; the unconditional full-map watch bypasses that isolation.
- `world_map_rebuild_isolation_test.dart` is green before the patch. The combined shell smoke baseline has an existing `pumpAndSettle` timeout and must be reported honestly rather than hidden.
- No new state-management system, persisted revision field, project schema, editor command, or MCP action is introduced.
- The local worktree is used because the user explicitly requested commits on the current phase and did not authorize branch/worktree creation; this is the narrow adaptation to the worktree recommendation in the planning skill.

### Task 1: Characterize shell invalidation

**Files:**

- Modify: `packages/map_editor/test/editor_shell_page_smoke_test.dart`

- [ ] **Step 1: Add the failing tile-isolation test**

Use the mounted `EditorShellPage` element's public `dirty` flag so the test observes real Riverpod invalidation without adding a test-only production callback:

```dart
testWidgets('tile-only map edits do not dirty the editor shell', (tester) async {
  final map = buildShellChromeMap(
    layers: <MapLayer>[
      TileLayer(
        id: 'ground',
        name: 'Ground',
        tilesetId: 'tiles',
        tiles: List<int>.filled(20 * 15, 0, growable: false),
      ),
    ],
  );
  final container = await pumpEditorShellPage(
    tester,
    initialState: EditorState(
      projectRootPath: '/tmp/perf_rm_07a',
      project: buildShellChromeProject(),
      activeMap: map,
      activeLayerId: 'ground',
    ),
    settleInitialFrame: false,
  );
  final shellElement = tester.element(find.byType(EditorShellPage));

  container.read(editorNotifierProvider.notifier).state =
      container.read(editorNotifierProvider).copyWith(
            activeMap: paintTileOnLayer(
              map,
              layerId: 'ground',
              pos: const GridPos(x: 1, y: 1),
              tileId: 1,
            ),
          );

  expect(shellElement.dirty, isFalse);
}
```

- [ ] **Step 2: Run RED and record the expected failure**

Run:

```bash
cd packages/map_editor
flutter test test/editor_shell_page_smoke_test.dart \
  --plain-name 'EditorShellPage smoke tile-only map edits do not dirty the editor shell'
```

Expected: `FAIL`, because the unconditional `activeMap` subscription marks `EditorShellPage` dirty.

- [ ] **Step 3: Add positive invalidation coverage**

Extend the test group with a map metadata/map-switch case that pumps once and verifies the refreshed title. Riverpod schedules derived-provider delivery, so rendered output is the stable positive assertion while `Element.dirty` remains the precise synchronous negative assertion for the unwanted direct subscription.

### Task 2: Split the narrative projection subscription

**Files:**

- Modify: `packages/map_editor/lib/src/features/editor/state/editor_selectors.dart`
- Modify: `packages/map_editor/lib/src/ui/editor_shell_page.dart`

- [ ] **Step 1: Add one semantic narrative projection provider**

Add a record and provider beside the existing document/viewport/interaction projections:

```dart
typedef EditorNarrativeProjectionSnapshot = ({
  String? projectRootPath,
  MapData? activeMap,
  bool projectIsDirty,
});

final editorNarrativeProjectionSnapshotProvider =
    Provider<EditorNarrativeProjectionSnapshot>((ref) {
  return ref.watch(
    editorNotifierProvider.select(
      (state) => (
        projectRootPath: state.projectRootPath,
        activeMap: state.activeMap,
        projectIsDirty: state.isDirty || state.isProjectDirty,
      ),
    ),
  );
});
```

This provider is intentionally not a second source of truth; it is a read-only invalidation domain over `EditorState`.

- [ ] **Step 2: Make the shell subscribe only when narrative UI consumes the projection**

In `EditorShellPage.build`, determine `usesNarrativeStudioProductShell` from the already focused workspace/project inputs, then conditionally watch the narrative projection:

```dart
final narrativeProjection = usesNarrativeStudioProductShell
    ? ref.watch(editorNarrativeProjectionSnapshotProvider)
    : null;
final editorState = ref.read(editorNotifierProvider);
final projectRootPath =
    narrativeProjection?.projectRootPath ?? editorState.projectRootPath;
final activeMap = narrativeProjection?.activeMap ?? editorState.activeMap;
final projectIsDirty = narrativeProjection?.projectIsDirty ?? false;
```

Remove the unconditional `activeMap` and dirty-state watches. Keep the existing focused shell, project, error, status, and workspace listeners.

- [ ] **Step 3: Make narrative index construction lazy**

Replace the unconditional project-based construction with:

```dart
final narrativeSearchIndex = !usesNarrativeStudioProductShell || project == null
    ? null
    : _globalSearchIndexFor(
        project: project,
        activeMap: activeMap,
        diagnostics: narrativeDiagnostics,
      );
```

- [ ] **Step 4: Run GREEN**

Run the two focused tests by plain name. Expected: both tile isolation and metadata invalidation pass.

### Task 3: Prove behavior, profile, and report

**Files:**

- Modify: `packages/map_editor/test/ui/world_map/world_map_rebuild_isolation_test.dart`
- Modify: `packages/map_editor/integration_test/editor_project_journey_test.dart`
- Create: `reports/performance/perf_rm_07a_editor_semantic_revisions.md`

- [ ] **Step 1: Add deterministic domain-isolation coverage**

Add provider listeners that prove viewport changes notify only the viewport projection, tile changes notify the map document projection, and neither notifies the narrative projection while the narrative projection has no listener in the World Map shell.

- [ ] **Step 2: Run focused and package checks**

Pin the integration fixture to `1280x800` before mounting `MapEditorApp`; the
production layout rejects smaller transient host-window sizes, and a profile
must measure the editor rather than an error frame.

```bash
cd packages/map_editor
flutter test test/editor_shell_page_smoke_test.dart \
  --plain-name 'EditorShellPage smoke tile-only map edits do not dirty the editor shell'
flutter test test/editor_shell_page_smoke_test.dart \
  --plain-name 'EditorShellPage smoke map metadata changes still refresh the editor shell'
flutter test test/ui/world_map/world_map_rebuild_isolation_test.dart
flutter analyze
flutter drive --profile -d macos \
  --driver=test_driver/performance_driver.dart \
  --target=integration_test/editor_project_journey_test.dart \
  --dart-define=POKEMAP_PERF_OUTPUT=build/performance/phase3/rm07a_editor_project_journey.json
```

Run the broader smoke file separately and preserve any pre-existing timeout as an explicit limit.

- [ ] **Step 3: Assess PokeMap MCP parity**

Record `N/A`: this lot changes only editor subscription/performance behavior. It adds no authoring semantic, project data, validation, import/export, rendering result, or editor command; direct API/JSONL/MCP contracts remain unchanged.

- [ ] **Step 4: Write the Evidence Pack**

Follow `codex_rule.md`: include initial/final Git state, exact diff zones, every command/result, named Audit/Architecture, Implementation, Tests, Build/Validation, and Final Critique verdicts, plus the full content of this created plan. Exclude the Evidence Pack's own recursively self-referential content and state that exception explicitly.

- [ ] **Step 5: Commit only this lot**

```bash
git add \
  packages/map_editor/lib/src/features/editor/state/editor_selectors.dart \
  packages/map_editor/lib/src/ui/editor_shell_page.dart \
  packages/map_editor/test/editor_shell_page_smoke_test.dart \
  packages/map_editor/test/ui/world_map/world_map_rebuild_isolation_test.dart \
  packages/map_editor/integration_test/editor_project_journey_test.dart \
  reports/performance/plans/2026-08-01-pokemap-perf-rm-07a-editor-semantic-revisions.md \
  reports/performance/perf_rm_07a_editor_semantic_revisions.md
git diff --cached --check
git commit -m 'perf(editor): isolate semantic shell revisions'
```

Do not stage unrelated World Map tool-activation changes and do not push yet.

## Self-review

- Spec coverage: profile decision, tile/narrative invalidation, map switch freshness, focused tests, evidence, and commit boundary are all mapped above.
- Placeholder scan: no `TBD`, deferred implementation, or unspecified test step remains.
- Type consistency: the single new record/provider name and its three fields are consistent across production and tests.
- Non-goals: no global Riverpod refactor, integer revision counters, persistence/schema change, UI redesign, or authoring API change.
