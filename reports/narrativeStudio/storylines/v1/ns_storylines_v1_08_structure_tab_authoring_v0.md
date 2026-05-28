# NS-STORYLINES-V1-08 — Structure Tab Authoring V0

## 1. Executive summary

NS-STORYLINES-V1-08 is delivered.

Structure now lets an author create chapters inside an existing `StorylineAsset`, then create story steps inside a selected chapter. Mutations go through the existing editor notifier and update `ProjectManifest.storylines` immutably. Graph remains read-only and minimal, but no longer lies after chapters/steps exist: it shows real counts and a clear future-graph message.

No `map_core`, runtime, gameplay, battle, legacy import, sideQuest, scene placeholder, or scene link was added.

## 2. Inputs read

- `AGENTS.md`
- `agent_rules.md`
- `skills/README.md`
- `reports/narrativeStudio/storylines/road_map_storylines.md`
- `reports/narrativeStudio/storylines/ns_storylines_v1_07_bis_storylines_workspace_cleanup.md`
- `reports/narrativeStudio/storylines/ns_storylines_v1_07_create_main_storyline_flow_v0.md`
- `reports/narrativeStudio/storylines/ns_storylines_v1_05_project_manifest_storylines_integration_v0.md`
- `reports/narrativeStudio/storylines/ns_storylines_v1_03_storyline_asset_pure_model_v0.md`
- `reports/narrativeStudio/storylines/ns_storylines_v1_00_storyline_semantics_and_usable_authoring_contract.md`
- `packages/map_core/lib/src/models/storyline_asset.dart`
- `packages/map_core/lib/src/models/project_manifest.dart`
- `packages/map_core/lib/map_core.dart`
- `packages/map_editor/lib/src/ui/canvas/storylines_workspace.dart`
- `packages/map_editor/test/storylines_workspace_shell_test.dart`
- `packages/map_editor/test/storylines_current_global_story_characterization_test.dart`
- `packages/map_editor/test/narrative_workspace_projection_test.dart`
- `packages/map_editor/lib/src/features/editor/state/editor_notifier.dart`
- `packages/map_editor/lib/src/features/editor/state/editor_selectors.dart`
- `packages/map_editor/lib/src/ui/design_system/design_system.dart`
- `packages/map_editor/lib/src/ui/design_system/pokemap_tone.dart`
- `packages/map_editor/lib/src/ui/design_system/pokemap_dashboard_primitives.dart`
- `packages/map_editor/lib/src/ui/design_system/pokemap_button.dart`
- `packages/map_editor/lib/src/ui/design_system/pokemap_card.dart`
- `packages/map_editor/lib/src/ui/design_system/pokemap_panel.dart`
- `packages/map_editor/lib/src/theme/pokemap_color_tokens.dart`
- `packages/map_editor/lib/src/theme/theme.dart`

Missing expected files:

Sortie : <vide>

## 3. Product problem addressed

V1-07 made Storylines useful enough to create a main storyline. V1-08 makes the Structure tab useful enough to organize that storyline into chapters and durable narrative steps, while keeping Graph as generated/read-only context.

## 4. Implementation summary

- Added selected-chapter state local to `StorylinesWorkspace`.
- Added chapter creation dialog and step creation dialog using existing design system primitives.
- Added immutable update helpers that rebuild `StorylineAsset` / `StorylineChapter` without mutating existing lists.
- Replaced the disabled chapter placeholder with an active `Nouveau chapitre` action when a storyline is selected.
- Added chapter detail, steps list, and disabled `Lier une scène — bientôt` section.
- Added V1-08 widget coverage and Visual Gate screenshots.

## 5. Chapter creation flow

`Nouveau chapitre` is active only when a `StorylineAsset` is selected.

The dialog captures a required title and optional description. On submit it creates a `StorylineChapter` with:

- id: `chapter_<slug>` with `_2`, `_3`, etc. on collision;
- title and optional description from the form;
- order: max existing chapter order + 1, or 0 for the first chapter;
- empty steps and default model fields.

The created chapter is selected in Structure.

## 6. Story step creation flow

`Nouvelle étape narrative` is available when a chapter is selected.

The dialog captures a required title and optional description. On submit it creates a `StorylineStep` with:

- id: `step_<slug>` with collision suffixes unique across the whole storyline;
- order: max existing step order inside the selected chapter + 1, or 0 for the first step;
- empty `sceneLinkIds` and `expectedOutcomeIds`;
- no scene placeholder or scene link.

## 7. Structure tab behavior

Structure now shows:

- storyline summary;
- chapters section with active chapter creation;
- selected chapter detail;
- story steps for the selected chapter;
- linked scenes section as disabled/future.

Empty states remain honest when no storyline, chapter, step, or linked scene exists.

## 8. Graph minimal behavior

Graph remains read-only and minimal. If chapters/steps exist, it displays real counts and the message:

```text
Graph détaillé à venir au lot Graph From StorylineAsset.
```

No branches, edges, side quests, minimap, zoom, or graph editing are introduced.

## 9. ID generation and ordering

ID generation uses the existing slugifier pattern from V1-07, generalized by prefix:

- storyline: `storyline_<slug>`;
- chapter: `chapter_<slug>`;
- step: `step_<slug>`.

Chapter ids are unique within the selected storyline. Step ids are unique across all chapters of the selected storyline.

Ordering is append-only in V1-08. Reordering/drag-drop remains out of scope.

## 10. Mutation strategy

Mutations rebuild immutable model instances and call:

```dart
EditorNotifier.applyInMemoryProjectManifest(...)
```

No project file is written directly. No list from an existing model is mutated in place.

## 11. Legacy non-import guarantee

Legacy `ScenarioAsset(scope == globalStory)` is not imported automatically. V1-08 Structure authoring manipulates only `ProjectManifest.storylines`.

## 12. localEventFlow exclusion

`ScenarioAsset(scope == localEventFlow)` is not displayed or promoted as a storyline, sideQuest, chapter, step, or graph node.

## 13. Non-goals confirmed

Confirmed absent:

- no `map_core` modification;
- no `StorylineAsset` / `ProjectManifest` / `ScenarioAsset` modification;
- no generated files;
- no build_runner;
- no sideQuest creation;
- no scene placeholder;
- no `StorylineSceneLink`;
- no legacy import application;
- no rich graph;
- no drag/drop or reordering;
- no runtime/gameplay/battle change.

## 14. Design System Gate

Command:

```bash
rg "Color\(0x|Colors\." packages/map_editor/lib/src/ui/canvas/storylines_workspace.dart packages/map_editor/test/storylines_workspace_shell_test.dart || true
```

Output:

```text
Sortie : <vide>
```

Result: PASS.

## 15. Tests added or modified

`packages/map_editor/test/storylines_workspace_shell_test.dart` now covers:

- Structure without storyline;
- chapter creation cancel / required title / valid create / collision and order;
- step creation precondition / cancel / required title / valid create / global id collision and order;
- Graph minimal summary after structure data exists;
- disabled future scene-link action non-mutation;
- legacy/globalStory and localEventFlow non-import during Structure authoring;
- V1-08 Visual Gate.

## 16. Visual Gate

Visual Gate command:

```bash
cd packages/map_editor && flutter test --update-goldens test/storylines_workspace_shell_test.dart
```

Output:

```text
00:00 +0: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/storylines_workspace_shell_test.dart
00:00 +0: NS-STORYLINES-V1-08 structure tab authoring flow shows only Graph and Structure tabs
00:00 +1: NS-STORYLINES-V1-08 structure tab authoring flow shows V1 empty state without importing legacy globalStory
00:00 +2: NS-STORYLINES-V1-08 structure tab authoring flow opens and cancels create main storyline dialog without mutation
00:00 +3: NS-STORYLINES-V1-08 structure tab authoring flow requires title before create
00:01 +4: NS-STORYLINES-V1-08 structure tab authoring flow creates a main StorylineAsset and syncs Graph and Structure
00:01 +5: NS-STORYLINES-V1-08 structure tab authoring flow Structure without storyline has no chapter or step action
00:01 +6: NS-STORYLINES-V1-08 structure tab authoring flow opens and cancels create chapter without mutation
00:01 +7: NS-STORYLINES-V1-08 structure tab authoring flow requires chapter title before create
00:01 +8: NS-STORYLINES-V1-08 structure tab authoring flow creates chapters with stable ids, order and selection
00:01 +9: NS-STORYLINES-V1-08 structure tab authoring flow step action requires a selected chapter
00:02 +10: NS-STORYLINES-V1-08 structure tab authoring flow opens and cancels create step without mutation
00:02 +11: NS-STORYLINES-V1-08 structure tab authoring flow requires step title before create
00:02 +12: NS-STORYLINES-V1-08 structure tab authoring flow creates steps with global unique ids and order
00:03 +13: NS-STORYLINES-V1-08 structure tab authoring flow Graph summarizes created structure without fake edges
00:03 +14: NS-STORYLINES-V1-08 structure tab authoring flow generates stable unique ids on collision
00:03 +15: NS-STORYLINES-V1-08 structure tab authoring flow does not allow creating a second main storyline
00:03 +16: NS-STORYLINES-V1-08 structure tab authoring flow creation does not import legacy or promote localEventFlow
00:03 +17: NS-STORYLINES-V1-08 structure tab authoring flow Graph, Structure and disabled future actions do not mutate
00:03 +18: NS-STORYLINES-V1-08 structure tab authoring flow Structure authoring does not import legacy or localEventFlow
00:03 +19: NS-STORYLINES-V1-08 structure tab authoring flow keeps target fake data and Maps out of the V1 UI
00:04 +20: NS-STORYLINES-V1-08 structure tab authoring flow storylines UI source keeps raw colors out of the feature
00:04 +21: NS-STORYLINES-V1-08 structure tab authoring flow storylines shell test keeps raw colors out
00:04 +22: NS-STORYLINES-V1-08 structure tab authoring flow uses PokeMap dark theme in the Visual Gate harness
00:04 +23: NS-STORYLINES-V1-08 structure tab authoring flow writes V1-08 Structure Visual Gate screenshots
00:04 +24: All tests passed!
```

Screenshots:

```text
-rw-r--r--  1 karim  staff  10814 May 29 00:24 reports/narrativeStudio/storylines/screenshots/ns_storylines_v1_08_create_chapter_dialog.png
-rw-r--r--  1 karim  staff  42858 May 29 00:24 reports/narrativeStudio/storylines/screenshots/ns_storylines_v1_08_created_chapter.png
-rw-r--r--  1 karim  staff  44042 May 29 00:24 reports/narrativeStudio/storylines/screenshots/ns_storylines_v1_08_created_step.png
-rw-r--r--  1 karim  staff  40637 May 29 00:24 reports/narrativeStudio/storylines/screenshots/ns_storylines_v1_08_structure_empty.png
```

## 17. Commands run

- `flutter test --update-goldens test/storylines_workspace_shell_test.dart` (cwd: `/Users/karim/Project/pokemonProject/packages/map_editor`) -> exit 0
- `flutter test test/storylines_workspace_shell_test.dart` (cwd: `/Users/karim/Project/pokemonProject/packages/map_editor`) -> exit 0
- `flutter test test/storylines_current_global_story_characterization_test.dart` (cwd: `/Users/karim/Project/pokemonProject/packages/map_editor`) -> exit 0
- `flutter test test/narrative_workspace_projection_test.dart` (cwd: `/Users/karim/Project/pokemonProject/packages/map_editor`) -> exit 0
- `flutter analyze --no-fatal-infos lib/src/ui/canvas/storylines_workspace.dart test/storylines_workspace_shell_test.dart test/storylines_current_global_story_characterization_test.dart test/narrative_workspace_projection_test.dart` (cwd: `/Users/karim/Project/pokemonProject/packages/map_editor`) -> exit 0
- `rg "Color\(0x|Colors\." packages/map_editor/lib/src/ui/canvas/storylines_workspace.dart packages/map_editor/test/storylines_workspace_shell_test.dart || true` (cwd: `/Users/karim/Project/pokemonProject`) -> exit 0
- `ls -l reports/narrativeStudio/storylines/screenshots/ns_storylines_v1_08_structure_empty.png reports/narrativeStudio/storylines/screenshots/ns_storylines_v1_08_create_chapter_dialog.png reports/narrativeStudio/storylines/screenshots/ns_storylines_v1_08_created_chapter.png reports/narrativeStudio/storylines/screenshots/ns_storylines_v1_08_created_step.png` (cwd: `/Users/karim/Project/pokemonProject`) -> exit 0
- `git status --short --untracked-files=all` (cwd: `/Users/karim/Project/pokemonProject`) -> exit 0
- `git diff --stat` (cwd: `/Users/karim/Project/pokemonProject`) -> exit 0
- `git diff --name-only` (cwd: `/Users/karim/Project/pokemonProject`) -> exit 0
- `git diff --check` (cwd: `/Users/karim/Project/pokemonProject`) -> exit 0
- `git diff -- packages/map_editor/lib/src/ui/canvas/storylines_workspace.dart` (cwd: `/Users/karim/Project/pokemonProject`) -> exit 0
- `git diff -- packages/map_editor/test/storylines_workspace_shell_test.dart` (cwd: `/Users/karim/Project/pokemonProject`) -> exit 0
- `git diff -- reports/narrativeStudio/storylines/road_map_storylines.md` (cwd: `/Users/karim/Project/pokemonProject`) -> exit 0

## 18. Roadmap update

Roadmap updated:

- `NS-STORYLINES-V1-08` marked DONE;
- Structure chapter/step authoring summarized;
- Graph minimal behavior documented;
- no sideQuest, scene placeholder, scene link, legacy import, or `map_core` change confirmed;
- next recommended lot set to `NS-STORYLINES-V1-09 — Create Side Quest Flow V0`.

## 19. Evidence Pack

### Git branch initiale

```text
main
```

### Git status initial exact

```text
 M packages/map_editor/lib/src/ui/canvas/storylines_workspace.dart
 M packages/map_editor/test/storylines_workspace_shell_test.dart
 M reports/narrativeStudio/storylines/road_map_storylines.md
 M reports/narrativeStudio/storylines/screenshots/ns_storylines_v1_07_created_main_graph.png
 M reports/narrativeStudio/storylines/screenshots/ns_storylines_v1_07_created_main_structure.png
?? reports/narrativeStudio/storylines/ns_storylines_v1_07_bis_storylines_workspace_cleanup.md
```

### Git diff --stat initial

```text
 .../lib/src/ui/canvas/storylines_workspace.dart    | 2659 +-------------------
 .../test/storylines_workspace_shell_test.dart      |    9 +-
 .../storylines/road_map_storylines.md              |   30 +-
 .../ns_storylines_v1_07_created_main_graph.png     |  Bin 34131 -> 34175 bytes
 .../ns_storylines_v1_07_created_main_structure.png |  Bin 37655 -> 37704 bytes
 5 files changed, 84 insertions(+), 2614 deletions(-)
```

### Git diff --name-only initial

```text
packages/map_editor/lib/src/ui/canvas/storylines_workspace.dart
packages/map_editor/test/storylines_workspace_shell_test.dart
reports/narrativeStudio/storylines/road_map_storylines.md
reports/narrativeStudio/storylines/screenshots/ns_storylines_v1_07_created_main_graph.png
reports/narrativeStudio/storylines/screenshots/ns_storylines_v1_07_created_main_structure.png
```

### Git diff --check initial

```text
Sortie : <vide>
```

### Liste des fichiers lus

- `AGENTS.md`
- `agent_rules.md`
- `skills/README.md`
- `reports/narrativeStudio/storylines/road_map_storylines.md`
- `reports/narrativeStudio/storylines/ns_storylines_v1_07_bis_storylines_workspace_cleanup.md`
- `reports/narrativeStudio/storylines/ns_storylines_v1_07_create_main_storyline_flow_v0.md`
- `reports/narrativeStudio/storylines/ns_storylines_v1_05_project_manifest_storylines_integration_v0.md`
- `reports/narrativeStudio/storylines/ns_storylines_v1_03_storyline_asset_pure_model_v0.md`
- `reports/narrativeStudio/storylines/ns_storylines_v1_00_storyline_semantics_and_usable_authoring_contract.md`
- `packages/map_core/lib/src/models/storyline_asset.dart`
- `packages/map_core/lib/src/models/project_manifest.dart`
- `packages/map_core/lib/map_core.dart`
- `packages/map_editor/lib/src/ui/canvas/storylines_workspace.dart`
- `packages/map_editor/test/storylines_workspace_shell_test.dart`
- `packages/map_editor/test/storylines_current_global_story_characterization_test.dart`
- `packages/map_editor/test/narrative_workspace_projection_test.dart`
- `packages/map_editor/lib/src/features/editor/state/editor_notifier.dart`
- `packages/map_editor/lib/src/features/editor/state/editor_selectors.dart`
- `packages/map_editor/lib/src/ui/design_system/design_system.dart`
- `packages/map_editor/lib/src/ui/design_system/pokemap_tone.dart`
- `packages/map_editor/lib/src/ui/design_system/pokemap_dashboard_primitives.dart`
- `packages/map_editor/lib/src/ui/design_system/pokemap_button.dart`
- `packages/map_editor/lib/src/ui/design_system/pokemap_card.dart`
- `packages/map_editor/lib/src/ui/design_system/pokemap_panel.dart`
- `packages/map_editor/lib/src/theme/pokemap_color_tokens.dart`
- `packages/map_editor/lib/src/theme/theme.dart`

### Liste des fichiers absents mais attendus

Sortie : <vide>

### Diff complet de storylines_workspace.dart

```diff
diff --git a/packages/map_editor/lib/src/ui/canvas/storylines_workspace.dart b/packages/map_editor/lib/src/ui/canvas/storylines_workspace.dart
index 622fa9eb..dec818b2 100644
--- a/packages/map_editor/lib/src/ui/canvas/storylines_workspace.dart
+++ b/packages/map_editor/lib/src/ui/canvas/storylines_workspace.dart
@@ -25,6 +25,7 @@ class StorylinesWorkspace extends ConsumerStatefulWidget {
 class _StorylinesWorkspaceState extends ConsumerState<StorylinesWorkspace> {
   _StorylineContentTab _selectedTab = _StorylineContentTab.graph;
   String? _selectedStorylineId;
+  String? _selectedChapterId;
 
   @override
   Widget build(BuildContext context) {
@@ -32,6 +33,7 @@ class _StorylinesWorkspaceState extends ConsumerState<StorylinesWorkspace> {
     final project = editorState.project;
     final storylines = project?.storylines ?? const <StorylineAsset>[];
     final selectedStoryline = _selectedStoryline(storylines);
+    final selectedChapter = _selectedChapter(selectedStoryline);
     final legacyGlobalStory = widget.projection.globalStories.isEmpty
         ? null
         : widget.projection.globalStories.first;
@@ -58,6 +60,7 @@ class _StorylinesWorkspaceState extends ConsumerState<StorylinesWorkspace> {
           Expanded(
             child: _StorylinesV1MainPanel(
               selectedStoryline: selectedStoryline,
+              selectedChapter: selectedChapter,
               storylines: storylines,
               selectedTab: _selectedTab,
               legacyGlobalStory: legacyGlobalStory,
@@ -65,10 +68,23 @@ class _StorylinesWorkspaceState extends ConsumerState<StorylinesWorkspace> {
               legacyStepCount: legacyStepCount,
               canCreateMainStoryline: _canCreateMainStoryline(storylines),
               onTabSelected: _selectTab,
+              onChapterSelected: _selectChapter,
               onCreateMainStoryline:
                   project == null || !_canCreateMainStoryline(storylines)
                       ? null
                       : () => _openCreateMainStorylineDialog(project),
+              onCreateChapter: project == null || selectedStoryline == null
+                  ? null
+                  : () => _openCreateChapterDialog(project, selectedStoryline),
+              onCreateStep: project == null ||
+                      selectedStoryline == null ||
+                      selectedChapter == null
+                  ? null
+                  : () => _openCreateStepDialog(
+                        project,
+                        selectedStoryline,
+                        selectedChapter,
+                      ),
             ),
           ),
           const SizedBox(width: 12),
@@ -99,12 +115,38 @@ class _StorylinesWorkspaceState extends ConsumerState<StorylinesWorkspace> {
     return !storylines.any((storyline) => storyline.type == StorylineType.main);
   }
 
+  StorylineChapter? _selectedChapter(StorylineAsset? storyline) {
+    if (storyline == null || storyline.chapters.isEmpty) {
+      return null;
+    }
+    final targetId = _selectedChapterId;
+    if (targetId != null) {
+      for (final chapter in storyline.chapters) {
+        if (chapter.id == targetId) {
+          return chapter;
+        }
+      }
+    }
+    return storyline.chapters.first;
+  }
+
   void _selectStoryline(StorylineAsset storyline) {
     if (_selectedStorylineId == storyline.id) {
       return;
     }
     setState(() {
       _selectedStorylineId = storyline.id;
+      _selectedChapterId =
+          storyline.chapters.isEmpty ? null : storyline.chapters.first.id;
+    });
+  }
+
+  void _selectChapter(StorylineChapter chapter) {
+    if (_selectedChapterId == chapter.id) {
+      return;
+    }
+    setState(() {
+      _selectedChapterId = chapter.id;
     });
   }
 
@@ -144,17 +186,133 @@ class _StorylinesWorkspaceState extends ConsumerState<StorylinesWorkspace> {
         );
     setState(() {
       _selectedStorylineId = storyline.id;
+      _selectedChapterId = null;
       _selectedTab = _StorylineContentTab.graph;
     });
   }
 
+  Future<void> _openCreateChapterDialog(
+    ProjectManifest project,
+    StorylineAsset storyline,
+  ) async {
+    final draft = await showCupertinoDialog<_StructureItemDraft>(
+      context: context,
+      builder: (context) => const _CreateStructureItemDialog(
+        dialogKey: ValueKey('storylines-create-chapter-dialog'),
+        title: 'Nouveau chapitre',
+        titleFieldKey: ValueKey('storylines-create-chapter-title-field'),
+        descriptionFieldKey: ValueKey(
+          'storylines-create-chapter-description-field',
+        ),
+        cancelKey: ValueKey('storylines-create-chapter-cancel'),
+        submitKey: ValueKey('storylines-create-chapter-submit'),
+      ),
+    );
+    if (draft == null || !mounted) {
+      return;
+    }
+    final chapter = StorylineChapter(
+      id: _generateScopedId(
+        prefix: 'chapter',
+        title: draft.title,
+        existingIds: storyline.chapters.map((chapter) => chapter.id).toSet(),
+      ),
+      title: draft.title,
+      description: draft.description,
+      order: _nextChapterOrder(storyline),
+    );
+    final updatedStoryline = _copyStorylineWith(
+      storyline,
+      chapters: [...storyline.chapters, chapter],
+    );
+    _applyStorylineUpdate(
+      project,
+      updatedStoryline,
+      statusMessage: 'Chapitre créé',
+    );
+    setState(() {
+      _selectedStorylineId = storyline.id;
+      _selectedChapterId = chapter.id;
+      _selectedTab = _StorylineContentTab.structure;
+    });
+  }
+
+  Future<void> _openCreateStepDialog(
+    ProjectManifest project,
+    StorylineAsset storyline,
+    StorylineChapter chapter,
+  ) async {
+    final draft = await showCupertinoDialog<_StructureItemDraft>(
+      context: context,
+      builder: (context) => const _CreateStructureItemDialog(
+        dialogKey: ValueKey('storylines-create-step-dialog'),
+        title: 'Nouvelle étape narrative',
+        titleFieldKey: ValueKey('storylines-create-step-title-field'),
+        descriptionFieldKey: ValueKey(
+          'storylines-create-step-description-field',
+        ),
+        cancelKey: ValueKey('storylines-create-step-cancel'),
+        submitKey: ValueKey('storylines-create-step-submit'),
+      ),
+    );
+    if (draft == null || !mounted) {
+      return;
+    }
+    final step = StorylineStep(
+      id: _generateScopedId(
+        prefix: 'step',
+        title: draft.title,
+        existingIds: _storylineStepIds(storyline),
+      ),
+      title: draft.title,
+      description: draft.description,
+      order: _nextStepOrder(chapter),
+    );
+    final updatedChapter = _copyChapterWith(
+      chapter,
+      steps: [...chapter.steps, step],
+    );
+    final updatedStoryline = _copyStorylineWith(
+      storyline,
+      chapters: storyline.chapters
+          .map(
+            (current) => current.id == chapter.id ? updatedChapter : current,
+          )
+          .toList(growable: false),
+    );
+    _applyStorylineUpdate(
+      project,
+      updatedStoryline,
+      statusMessage: 'Étape narrative créée',
+    );
+    setState(() {
+      _selectedStorylineId = storyline.id;
+      _selectedChapterId = chapter.id;
+      _selectedTab = _StorylineContentTab.structure;
+    });
+  }
+
   String _generateStorylineId(
     String title,
     List<StorylineAsset> storylines,
   ) {
     final existingIds = storylines.map((storyline) => storyline.id).toSet();
+    return _generateScopedId(
+      prefix: 'storyline',
+      title: title,
+      existingIds: existingIds,
+      fallback: 'main',
+    );
+  }
+
+  String _generateScopedId({
+    required String prefix,
+    required String title,
+    required Set<String> existingIds,
+    String fallback = 'item',
+  }) {
     final slug = _slugifyStorylineTitle(title);
-    final base = 'storyline_${slug.isEmpty ? 'main' : slug}';
+    final base = '${prefix}_${slug.isEmpty ? fallback : slug}';
     if (!existingIds.contains(base)) {
       return base;
     }
@@ -165,6 +323,53 @@ class _StorylinesWorkspaceState extends ConsumerState<StorylinesWorkspace> {
     return '${base}_$suffix';
   }
 
+  Set<String> _storylineStepIds(StorylineAsset storyline) {
+    return {
+      for (final chapter in storyline.chapters)
+        for (final step in chapter.steps) step.id,
+    };
+  }
+
+  int _nextChapterOrder(StorylineAsset storyline) {
+    var nextOrder = 0;
+    for (final chapter in storyline.chapters) {
+      if (chapter.order >= nextOrder) {
+        nextOrder = chapter.order + 1;
+      }
+    }
+    return nextOrder;
+  }
+
+  int _nextStepOrder(StorylineChapter chapter) {
+    var nextOrder = 0;
+    for (final step in chapter.steps) {
+      if (step.order >= nextOrder) {
+        nextOrder = step.order + 1;
+      }
+    }
+    return nextOrder;
+  }
+
+  void _applyStorylineUpdate(
+    ProjectManifest project,
+    StorylineAsset updatedStoryline, {
+    required String statusMessage,
+  }) {
+    final updated = project.copyWith(
+      storylines: project.storylines
+          .map(
+            (storyline) => storyline.id == updatedStoryline.id
+                ? updatedStoryline
+                : storyline,
+          )
+          .toList(growable: false),
+    );
+    ref.read(editorNotifierProvider.notifier).applyInMemoryProjectManifest(
+          updated,
+          statusMessage: statusMessage,
+        );
+  }
+
   String _slugifyStorylineTitle(String title) {
     final normalized = title.trim().toLowerCase();
     final buffer = StringBuffer();
@@ -195,6 +400,56 @@ class _StorylinesWorkspaceState extends ConsumerState<StorylinesWorkspace> {
   }
 }
 
+StorylineAsset _copyStorylineWith(
+  StorylineAsset storyline, {
+  List<StorylineChapter>? chapters,
+}) {
+  return StorylineAsset(
+    id: storyline.id,
+    schemaVersion: storyline.schemaVersion,
+    type: storyline.type,
+    status: storyline.status,
+    title: storyline.title,
+    description: storyline.description,
+    sortOrder: storyline.sortOrder,
+    locale: storyline.locale,
+    chapters: chapters ?? storyline.chapters,
+    sceneLinks: storyline.sceneLinks,
+    relationships: storyline.relationships,
+    legacySource: storyline.legacySource,
+    authorNotes: storyline.authorNotes,
+    metadata: storyline.metadata,
+  );
+}
+
+StorylineChapter _copyChapterWith(
+  StorylineChapter chapter, {
+  List<StorylineStep>? steps,
+}) {
+  return StorylineChapter(
+    id: chapter.id,
+    title: chapter.title,
+    description: chapter.description,
+    order: chapter.order,
+    steps: steps ?? chapter.steps,
+    directSceneLinkIds: chapter.directSceneLinkIds,
+    status: chapter.status,
+    authorNotes: chapter.authorNotes,
+    metadata: chapter.metadata,
+  );
+}
+
+int _storylineStepCount(StorylineAsset storyline) {
+  return storyline.chapters.fold<int>(
+    0,
+    (total, chapter) => total + chapter.steps.length,
+  );
+}
+
+String _formatCount(int count, String singular, String plural) {
+  return '$count ${count == 1 ? singular : plural}';
+}
+
 class _StorylinesV1SecondaryPanel extends StatelessWidget {
   const _StorylinesV1SecondaryPanel({
     required this.storylines,
@@ -350,6 +605,16 @@ class _StorylinesV1Row extends StatelessWidget {
                       fontSize: 11,
                     ),
                   ),
+                  if (storyline.chapters.isNotEmpty) ...[
+                    const SizedBox(height: 3),
+                    Text(
+                      "${_formatCount(storyline.chapters.length, 'chapitre', 'chapitres')} · ${_formatCount(_storylineStepCount(storyline), 'étape', 'étapes')}",
+                      style: TextStyle(
+                        color: colors.textSecondary,
+                        fontSize: 11,
+                      ),
+                    ),
+                  ],
                 ],
               ),
             ),
@@ -363,6 +628,7 @@ class _StorylinesV1Row extends StatelessWidget {
 class _StorylinesV1MainPanel extends StatelessWidget {
   const _StorylinesV1MainPanel({
     required this.selectedStoryline,
+    required this.selectedChapter,
     required this.storylines,
     required this.selectedTab,
     required this.legacyGlobalStory,
@@ -370,10 +636,14 @@ class _StorylinesV1MainPanel extends StatelessWidget {
     required this.legacyStepCount,
     required this.canCreateMainStoryline,
     required this.onTabSelected,
+    required this.onChapterSelected,
     required this.onCreateMainStoryline,
+    required this.onCreateChapter,
+    required this.onCreateStep,
   });
 
   final StorylineAsset? selectedStoryline;
+  final StorylineChapter? selectedChapter;
   final List<StorylineAsset> storylines;
   final _StorylineContentTab selectedTab;
   final NarrativeScenarioSummary? legacyGlobalStory;
@@ -381,7 +651,10 @@ class _StorylinesV1MainPanel extends StatelessWidget {
   final int legacyStepCount;
   final bool canCreateMainStoryline;
   final ValueChanged<_StorylineContentTab> onTabSelected;
+  final ValueChanged<StorylineChapter> onChapterSelected;
   final VoidCallback? onCreateMainStoryline;
+  final VoidCallback? onCreateChapter;
+  final VoidCallback? onCreateStep;
 
   @override
   Widget build(BuildContext context) {
@@ -407,7 +680,13 @@ class _StorylinesV1MainPanel extends StatelessWidget {
           const SizedBox(height: 16),
           Expanded(
             child: selectedTab == _StorylineContentTab.structure
-                ? _StorylinesV1StructureSection(storyline: selectedStoryline)
+                ? _StorylinesV1StructureSection(
+                    storyline: selectedStoryline,
+                    selectedChapter: selectedChapter,
+                    onChapterSelected: onChapterSelected,
+                    onCreateChapter: onCreateChapter,
+                    onCreateStep: onCreateStep,
+                  )
                 : _StorylinesV1GraphSection(
                     storyline: selectedStoryline,
                     legacyGlobalStory: legacyGlobalStory,
@@ -578,10 +857,14 @@ class _StorylinesV1GraphSection extends StatelessWidget {
   @override
   Widget build(BuildContext context) {
     final colors = context.pokeMapColors;
+    final selectedStoryline = storyline;
+    final chapterCount = selectedStoryline?.chapters.length ?? 0;
+    final stepCount =
+        selectedStoryline == null ? 0 : _storylineStepCount(selectedStoryline);
     return PokeMapCard(
       key: const ValueKey('storylines-graph-target-read-only'),
       padding: const EdgeInsets.all(18),
-      child: storyline == null
+      child: selectedStoryline == null
           ? _StorylinesV1NoStorylineState(
               legacyGlobalStory: legacyGlobalStory,
               legacyStep: legacyStep,
@@ -634,7 +917,7 @@ class _StorylinesV1GraphSection extends StatelessWidget {
                         mainAxisSize: MainAxisSize.min,
                         children: [
                           Text(
-                            storyline!.title,
+                            selectedStoryline.title,
                             textAlign: TextAlign.center,
                             style: TextStyle(
                               color: colors.textPrimary,
@@ -644,13 +927,26 @@ class _StorylinesV1GraphSection extends StatelessWidget {
                           ),
                           const SizedBox(height: 8),
                           Text(
-                            'Ajoutez des chapitres dans Structure.',
+                            chapterCount == 0
+                                ? 'Ajoutez des chapitres dans Structure.'
+                                : "${_formatCount(chapterCount, 'chapitre', 'chapitres')} · ${_formatCount(stepCount, 'étape', 'étapes')}",
                             textAlign: TextAlign.center,
                             style: TextStyle(
                               color: colors.textSecondary,
                               fontSize: 12,
                             ),
                           ),
+                          if (chapterCount > 0) ...[
+                            const SizedBox(height: 8),
+                            Text(
+                              'Graph détaillé à venir au lot Graph From StorylineAsset.',
+                              textAlign: TextAlign.center,
+                              style: TextStyle(
+                                color: colors.textSecondary,
+                                fontSize: 12,
+                              ),
+                            ),
+                          ],
                         ],
                       ),
                     ),
@@ -791,13 +1087,24 @@ class _StorylinesV1NoStorylineState extends StatelessWidget {
 }
 
 class _StorylinesV1StructureSection extends StatelessWidget {
-  const _StorylinesV1StructureSection({required this.storyline});
+  const _StorylinesV1StructureSection({
+    required this.storyline,
+    required this.selectedChapter,
+    required this.onChapterSelected,
+    required this.onCreateChapter,
+    required this.onCreateStep,
+  });
 
   final StorylineAsset? storyline;
+  final StorylineChapter? selectedChapter;
+  final ValueChanged<StorylineChapter> onChapterSelected;
+  final VoidCallback? onCreateChapter;
+  final VoidCallback? onCreateStep;
 
   @override
   Widget build(BuildContext context) {
     final colors = context.pokeMapColors;
+    final chapter = selectedChapter;
     return PokeMapCard(
       key: const ValueKey('storylines-structure-read-only'),
       padding: const EdgeInsets.all(18),
@@ -817,23 +1124,31 @@ class _StorylinesV1StructureSection extends StatelessWidget {
                 children: [
                   _StorylinesV1StructureSummary(storyline: storyline!),
                   const SizedBox(height: 12),
-                  const _StorylinesV1StructureBucket(
-                    key: ValueKey('storylines-v1-structure-chapters'),
-                    title: 'Chapitres',
-                    body: 'Aucun chapitre pour le moment.',
-                    action: 'Nouveau chapitre — bientôt',
+                  _StorylinesV1ChaptersSection(
+                    key: const ValueKey('storylines-v1-structure-chapters'),
+                    storyline: storyline!,
+                    selectedChapter: chapter,
+                    onChapterSelected: onChapterSelected,
+                    onCreateChapter: onCreateChapter,
                   ),
                   const SizedBox(height: 10),
-                  const _StorylinesV1StructureBucket(
-                    key: ValueKey('storylines-v1-structure-steps'),
-                    title: 'Étapes narratives',
-                    body: 'Les étapes seront organisées dans les chapitres.',
+                  _StorylinesV1ChapterDetail(
+                    chapter: chapter,
+                    onCreateStep: onCreateStep,
+                  ),
+                  const SizedBox(height: 10),
+                  _StorylinesV1StepsSection(
+                    key: const ValueKey('storylines-v1-structure-steps'),
+                    chapter: chapter,
                   ),
                   const SizedBox(height: 10),
                   const _StorylinesV1StructureBucket(
                     key: ValueKey('storylines-v1-structure-scenes'),
                     title: 'Scènes liées',
-                    body: 'Liens de scènes non branchés dans ce lot.',
+                    body:
+                        'Scènes liées à venir. Les scènes seront reliées dans un prochain lot.',
+                    action: 'Lier une scène — bientôt',
+                    actionKey: ValueKey('storylines-link-scene-disabled'),
                   ),
                 ],
               ),
@@ -888,17 +1203,344 @@ class _StorylinesV1StructureSummary extends StatelessWidget {
   }
 }
 
+class _StorylinesV1ChaptersSection extends StatelessWidget {
+  const _StorylinesV1ChaptersSection({
+    super.key,
+    required this.storyline,
+    required this.selectedChapter,
+    required this.onChapterSelected,
+    required this.onCreateChapter,
+  });
+
+  final StorylineAsset storyline;
+  final StorylineChapter? selectedChapter;
+  final ValueChanged<StorylineChapter> onChapterSelected;
+  final VoidCallback? onCreateChapter;
+
+  @override
+  Widget build(BuildContext context) {
+    final colors = context.pokeMapColors;
+    return PokeMapCard(
+      padding: const EdgeInsets.all(14),
+      child: Column(
+        crossAxisAlignment: CrossAxisAlignment.stretch,
+        children: [
+          Row(
+            children: [
+              Expanded(
+                child: Text(
+                  'Chapitres',
+                  style: TextStyle(
+                    color: colors.textPrimary,
+                    fontSize: 13,
+                    fontWeight: FontWeight.w800,
+                  ),
+                ),
+              ),
+              PokeMapButton(
+                key: const ValueKey('storylines-new-chapter-action'),
+                onPressed: onCreateChapter,
+                variant: PokeMapButtonVariant.primary,
+                size: PokeMapButtonSize.small,
+                leading: const Icon(CupertinoIcons.add),
+                child: const Text('Nouveau chapitre'),
+              ),
+            ],
+          ),
+          const SizedBox(height: 10),
+          if (storyline.chapters.isEmpty)
+            Text(
+              'Aucun chapitre\nCréez un premier chapitre pour organiser votre histoire.',
+              style: TextStyle(
+                color: colors.textSecondary,
+                fontSize: 12,
+                height: 1.35,
+              ),
+            )
+          else
+            ...storyline.chapters.map(
+              (chapter) => Padding(
+                padding: const EdgeInsets.only(bottom: 8),
+                child: _StorylinesV1ChapterRow(
+                  chapter: chapter,
+                  selected: chapter.id == selectedChapter?.id,
+                  onTap: () => onChapterSelected(chapter),
+                ),
+              ),
+            ),
+        ],
+      ),
+    );
+  }
+}
+
+class _StorylinesV1ChapterRow extends StatelessWidget {
+  const _StorylinesV1ChapterRow({
+    required this.chapter,
+    required this.selected,
+    required this.onTap,
+  });
+
+  final StorylineChapter chapter;
+  final bool selected;
+  final VoidCallback onTap;
+
+  @override
+  Widget build(BuildContext context) {
+    final colors = context.pokeMapColors;
+    return PokeMapCard(
+      key: ValueKey('storylines-chapter-row-${chapter.id}'),
+      padding: const EdgeInsets.all(12),
+      selected: selected,
+      onTap: onTap,
+      child: Row(
+        children: [
+          PokeMapIconTile(
+            icon: CupertinoIcons.bookmark,
+            tone: selected ? PokeMapTone.narrative : PokeMapTone.neutral,
+            size: 30,
+          ),
+          const SizedBox(width: 10),
+          Expanded(
+            child: Column(
+              crossAxisAlignment: CrossAxisAlignment.start,
+              children: [
+                Text(
+                  chapter.title,
+                  maxLines: 1,
+                  overflow: TextOverflow.ellipsis,
+                  style: TextStyle(
+                    color: colors.textPrimary,
+                    fontSize: 12.5,
+                    fontWeight: FontWeight.w800,
+                  ),
+                ),
+                const SizedBox(height: 3),
+                Text(
+                  '${_formatCount(chapter.steps.length, 'étape narrative', 'étapes narratives')} · ordre ${chapter.order}',
+                  style: TextStyle(
+                    color: colors.textSecondary,
+                    fontSize: 11,
+                  ),
+                ),
+              ],
+            ),
+          ),
+        ],
+      ),
+    );
+  }
+}
+
+class _StorylinesV1ChapterDetail extends StatelessWidget {
+  const _StorylinesV1ChapterDetail({
+    required this.chapter,
+    required this.onCreateStep,
+  });
+
+  final StorylineChapter? chapter;
+  final VoidCallback? onCreateStep;
+
+  @override
+  Widget build(BuildContext context) {
+    final colors = context.pokeMapColors;
+    return PokeMapCard(
+      key: const ValueKey('storylines-v1-chapter-detail'),
+      padding: const EdgeInsets.all(14),
+      selected: chapter != null,
+      child: chapter == null
+          ? Text(
+              'Détail du chapitre\nCréez ou sélectionnez un chapitre pour ajouter des étapes narratives.',
+              style: TextStyle(
+                color: colors.textSecondary,
+                fontSize: 12,
+                height: 1.35,
+              ),
+            )
+          : Column(
+              crossAxisAlignment: CrossAxisAlignment.stretch,
+              children: [
+                Row(
+                  crossAxisAlignment: CrossAxisAlignment.start,
+                  children: [
+                    Expanded(
+                      child: Column(
+                        crossAxisAlignment: CrossAxisAlignment.start,
+                        children: [
+                          Text(
+                            'Détail du chapitre',
+                            style: TextStyle(
+                              color: colors.textMuted,
+                              fontSize: 10.5,
+                              fontWeight: FontWeight.w800,
+                            ),
+                          ),
+                          const SizedBox(height: 6),
+                          Text(
+                            chapter!.title,
+                            style: TextStyle(
+                              color: colors.textPrimary,
+                              fontSize: 14,
+                              fontWeight: FontWeight.w800,
+                            ),
+                          ),
+                          const SizedBox(height: 5),
+                          Text(
+                            chapter!.description ?? 'Aucune description.',
+                            style: TextStyle(
+                              color: colors.textSecondary,
+                              fontSize: 12,
+                              height: 1.35,
+                            ),
+                          ),
+                          const SizedBox(height: 8),
+                          Text(
+                            'Ordre ${chapter!.order} · ${_formatCount(chapter!.steps.length, 'étape', 'étapes')}',
+                            style: TextStyle(
+                              color: colors.textSecondary,
+                              fontSize: 11,
+                              fontWeight: FontWeight.w700,
+                            ),
+                          ),
+                        ],
+                      ),
+                    ),
+                    const SizedBox(width: 10),
+                    PokeMapButton(
+                      key: const ValueKey('storylines-new-step-action'),
+                      onPressed: onCreateStep,
+                      variant: PokeMapButtonVariant.secondary,
+                      size: PokeMapButtonSize.small,
+                      leading: const Icon(CupertinoIcons.add),
+                      child: const Text('Nouvelle étape narrative'),
+                    ),
+                  ],
+                ),
+              ],
+            ),
+    );
+  }
+}
+
+class _StorylinesV1StepsSection extends StatelessWidget {
+  const _StorylinesV1StepsSection({
+    super.key,
+    required this.chapter,
+  });
+
+  final StorylineChapter? chapter;
+
+  @override
+  Widget build(BuildContext context) {
+    final colors = context.pokeMapColors;
+    return PokeMapCard(
+      padding: const EdgeInsets.all(14),
+      child: Column(
+        crossAxisAlignment: CrossAxisAlignment.stretch,
+        children: [
+          Text(
+            'Étapes narratives',
+            style: TextStyle(
+              color: colors.textPrimary,
+              fontSize: 13,
+              fontWeight: FontWeight.w800,
+            ),
+          ),
+          const SizedBox(height: 8),
+          if (chapter == null)
+            Text(
+              'Sélectionnez un chapitre pour voir ses étapes.',
+              style: TextStyle(color: colors.textSecondary, fontSize: 12),
+            )
+          else if (chapter!.steps.isEmpty)
+            Text(
+              'Aucune étape narrative\nAjoutez une première étape pour définir la progression du chapitre.',
+              style: TextStyle(
+                color: colors.textSecondary,
+                fontSize: 12,
+                height: 1.35,
+              ),
+            )
+          else
+            ...chapter!.steps.map(
+              (step) => Padding(
+                padding: const EdgeInsets.only(bottom: 8),
+                child: _StorylinesV1StepRow(step: step),
+              ),
+            ),
+        ],
+      ),
+    );
+  }
+}
+
+class _StorylinesV1StepRow extends StatelessWidget {
+  const _StorylinesV1StepRow({required this.step});
+
+  final StorylineStep step;
+
+  @override
+  Widget build(BuildContext context) {
+    final colors = context.pokeMapColors;
+    return PokeMapCard(
+      key: ValueKey('storylines-step-row-${step.id}'),
+      padding: const EdgeInsets.all(12),
+      child: Row(
+        children: [
+          const PokeMapIconTile(
+            icon: CupertinoIcons.flag,
+            tone: PokeMapTone.info,
+            size: 28,
+          ),
+          const SizedBox(width: 10),
+          Expanded(
+            child: Column(
+              crossAxisAlignment: CrossAxisAlignment.start,
+              children: [
+                Text(
+                  step.title,
+                  maxLines: 1,
+                  overflow: TextOverflow.ellipsis,
+                  style: TextStyle(
+                    color: colors.textPrimary,
+                    fontSize: 12.5,
+                    fontWeight: FontWeight.w800,
+                  ),
+                ),
+                const SizedBox(height: 3),
+                Text(
+                  step.description ?? 'Aucune description.',
+                  maxLines: 2,
+                  overflow: TextOverflow.ellipsis,
+                  style: TextStyle(
+                    color: colors.textSecondary,
+                    fontSize: 11,
+                  ),
+                ),
+              ],
+            ),
+          ),
+          const SizedBox(width: 10),
+          const _StorylinesV1Badge(label: 'Aucune scène liée'),
+        ],
+      ),
+    );
+  }
+}
+
 class _StorylinesV1StructureBucket extends StatelessWidget {
   const _StorylinesV1StructureBucket({
     super.key,
     required this.title,
     required this.body,
     this.action,
+    this.actionKey,
   });
 
   final String title;
   final String body;
   final String? action;
+  final Key? actionKey;
 
   @override
   Widget build(BuildContext context) {
@@ -933,7 +1575,7 @@ class _StorylinesV1StructureBucket extends StatelessWidget {
           if (action != null) ...[
             const SizedBox(width: 10),
             PokeMapButton(
-              key: const ValueKey('storylines-new-chapter-disabled'),
+              key: actionKey,
               onPressed: null,
               variant: PokeMapButtonVariant.secondary,
               size: PokeMapButtonSize.small,
@@ -1040,6 +1682,10 @@ class _StorylinesV1InspectorPanel extends StatelessWidget {
                   label: 'Chapitres',
                   value: selectedStoryline!.chapters.length.toString(),
                 ),
+                _StorylineInspectorTextLine(
+                  label: 'Étapes',
+                  value: _storylineStepCount(selectedStoryline!).toString(),
+                ),
                 _StorylineInspectorTextLine(
                   label: 'Scene links',
                   value: selectedStoryline!.sceneLinks.length.toString(),
@@ -1060,6 +1706,135 @@ class _CreateMainStorylineDraft {
   final String? description;
 }
 
+class _StructureItemDraft {
+  const _StructureItemDraft({
+    required this.title,
+    required this.description,
+  });
+
+  final String title;
+  final String? description;
+}
+
+class _CreateStructureItemDialog extends StatefulWidget {
+  const _CreateStructureItemDialog({
+    required this.dialogKey,
+    required this.title,
+    required this.titleFieldKey,
+    required this.descriptionFieldKey,
+    required this.cancelKey,
+    required this.submitKey,
+  });
+
+  final Key dialogKey;
+  final String title;
+  final Key titleFieldKey;
+  final Key descriptionFieldKey;
+  final Key cancelKey;
+  final Key submitKey;
+
+  @override
+  State<_CreateStructureItemDialog> createState() =>
+      _CreateStructureItemDialogState();
+}
+
+class _CreateStructureItemDialogState
+    extends State<_CreateStructureItemDialog> {
+  final TextEditingController _titleController = TextEditingController();
+  final TextEditingController _descriptionController = TextEditingController();
+
+  @override
+  void dispose() {
+    _titleController.dispose();
+    _descriptionController.dispose();
+    super.dispose();
+  }
+
+  @override
+  Widget build(BuildContext context) {
+    final colors = context.pokeMapColors;
+    final title = _titleController.text.trim();
+    return Center(
+      child: SizedBox(
+        width: 460,
+        child: PokeMapPanel(
+          key: widget.dialogKey,
+          padding: const EdgeInsets.all(18),
+          child: Column(
+            mainAxisSize: MainAxisSize.min,
+            crossAxisAlignment: CrossAxisAlignment.stretch,
+            children: [
+              Text(
+                widget.title,
+                style: TextStyle(
+                  color: colors.textPrimary,
+                  fontSize: 18,
+                  fontWeight: FontWeight.w800,
+                ),
+              ),
+              const SizedBox(height: 14),
+              _StorylinesV1TextField(
+                key: widget.titleFieldKey,
+                controller: _titleController,
+                placeholder: 'Titre',
+                onChanged: (_) => setState(() {}),
+              ),
+              const SizedBox(height: 10),
+              _StorylinesV1TextField(
+                key: widget.descriptionFieldKey,
+                controller: _descriptionController,
+                placeholder: 'Description optionnelle',
+                maxLines: 3,
+              ),
+              if (title.isEmpty) ...[
+                const SizedBox(height: 8),
+                Text(
+                  'Titre obligatoire.',
+                  style: TextStyle(
+                    color: colors.warning,
+                    fontSize: 12,
+                  ),
+                ),
+              ],
+              const SizedBox(height: 16),
+              Row(
+                mainAxisAlignment: MainAxisAlignment.end,
+                children: [
+                  PokeMapButton(
+                    key: widget.cancelKey,
+                    onPressed: () => Navigator.of(context).pop(),
+                    variant: PokeMapButtonVariant.secondary,
+                    child: const Text('Annuler'),
+                  ),
+                  const SizedBox(width: 10),
+                  PokeMapButton(
+                    key: widget.submitKey,
+                    onPressed: title.isEmpty
+                        ? null
+                        : () {
+                            final description =
+                                _descriptionController.text.trim();
+                            Navigator.of(context).pop(
+                              _StructureItemDraft(
+                                title: title,
+                                description:
+                                    description.isEmpty ? null : description,
+                              ),
+                            );
+                          },
+                    variant: PokeMapButtonVariant.primary,
+                    child: const Text('Créer'),
+                  ),
+                ],
+              ),
+            ],
+          ),
+        ),
+      ),
+    );
+  }
+}
+
 class _CreateMainStorylineDialog extends StatefulWidget {
   const _CreateMainStorylineDialog({required this.existingIds});
 
```

### Diff complet des tests modifiés ou créés

```diff
diff --git a/packages/map_editor/test/storylines_workspace_shell_test.dart b/packages/map_editor/test/storylines_workspace_shell_test.dart
index 7b9e33ae..f57269a7 100644
--- a/packages/map_editor/test/storylines_workspace_shell_test.dart
+++ b/packages/map_editor/test/storylines_workspace_shell_test.dart
@@ -12,7 +12,7 @@ import 'package:map_editor/src/ui/canvas/narrative_workspace_canvas.dart';
 import 'package:map_editor/src/ui/design_system/design_system.dart';
 
 void main() {
-  group('NS-STORYLINES-V1-07 create main storyline flow', () {
+  group('NS-STORYLINES-V1-08 structure tab authoring flow', () {
     testWidgets('shows only Graph and Structure tabs', (tester) async {
       await _pumpStorylinesShell(tester);
 
@@ -133,7 +133,283 @@ void main() {
         ),
         findsOneWidget,
       );
-      expect(find.text('Nouveau chapitre — bientôt'), findsOneWidget);
+      expect(find.byKey(const ValueKey('storylines-new-chapter-action')),
+          findsOneWidget);
+      expect(find.text('Nouveau chapitre'), findsOneWidget);
+    });
+
+    testWidgets('Structure without storyline has no chapter or step action',
+        (tester) async {
+      final harness = await _pumpStorylinesShell(tester);
+      final before = harness.project.toJson();
+
+      await _openStructureTab(tester);
+
+      expect(find.text('Créez une storyline pour commencer.'), findsOneWidget);
+      expect(find.byKey(const ValueKey('storylines-new-chapter-action')),
+          findsNothing);
+      expect(find.byKey(const ValueKey('storylines-new-step-action')),
+          findsNothing);
+      expect(harness.project.toJson(), before);
+    });
+
+    testWidgets('opens and cancels create chapter without mutation',
+        (tester) async {
+      final harness = await _pumpStorylinesShell(
+        tester,
+        project: _projectWithStorylines([
+          StorylineAsset(
+            id: 'storyline_existing_main',
+            type: StorylineType.main,
+            title: 'Existing main',
+          ),
+        ]),
+      );
+      final before = harness.project.toJson();
+
+      await _openCreateChapterDialog(tester);
+      expect(find.byKey(const ValueKey('storylines-create-chapter-dialog')),
+          findsOneWidget);
+      expect(
+          find.byKey(const ValueKey('storylines-create-chapter-title-field')),
+          findsOneWidget);
+      expect(
+          find.byKey(
+            const ValueKey('storylines-create-chapter-description-field'),
+          ),
+          findsOneWidget);
+
+      await tester.tap(
+        find.byKey(const ValueKey('storylines-create-chapter-cancel')),
+      );
+      await tester.pumpAndSettle();
+
+      expect(find.byKey(const ValueKey('storylines-create-chapter-dialog')),
+          findsNothing);
+      expect(harness.project.toJson(), before);
+    });
+
+    testWidgets('requires chapter title before create', (tester) async {
+      final harness = await _pumpStorylinesShell(
+        tester,
+        project: _projectWithStorylines([
+          StorylineAsset(
+            id: 'storyline_existing_main',
+            type: StorylineType.main,
+            title: 'Existing main',
+          ),
+        ]),
+      );
+
+      await _openCreateChapterDialog(tester);
+
+      final submit = tester.widget<PokeMapButton>(
+        find.byKey(const ValueKey('storylines-create-chapter-submit')),
+      );
+      expect(submit.onPressed, isNull);
+      expect(find.text('Titre obligatoire.'), findsOneWidget);
+      expect(harness.project.storylines.single.chapters, isEmpty);
+    });
+
+    testWidgets('creates chapters with stable ids, order and selection',
+        (tester) async {
+      final harness = await _pumpStorylinesShell(
+        tester,
+        project: _projectWithStorylines([
+          StorylineAsset(
+            id: 'storyline_existing_main',
+            type: StorylineType.main,
+            title: 'Existing main',
+          ),
+        ]),
+      );
+
+      await _createChapter(
+        tester,
+        title: 'Intro',
+        description: 'Premier arc auteur.',
+      );
+      await _createChapter(tester, title: 'Intro');
+
+      final chapters = harness.project.storylines.single.chapters;
+      expect(chapters, hasLength(2));
+      expect(chapters.map((chapter) => chapter.id), [
+        'chapter_intro',
+        'chapter_intro_2',
+      ]);
+      expect(chapters.map((chapter) => chapter.order), [0, 1]);
+      expect(chapters.first.title, 'Intro');
+      expect(chapters.first.description, 'Premier arc auteur.');
+      expect(chapters.first.steps, isEmpty);
+      expect(find.byKey(const ValueKey('storylines-chapter-row-chapter_intro')),
+          findsOneWidget);
+      expect(
+          find.byKey(
+            const ValueKey('storylines-chapter-row-chapter_intro_2'),
+          ),
+          findsOneWidget);
+      expect(find.text('Détail du chapitre'), findsOneWidget);
+    });
+
+    testWidgets('step action requires a selected chapter', (tester) async {
+      final harness = await _pumpStorylinesShell(
+        tester,
+        project: _projectWithStorylines([
+          StorylineAsset(
+            id: 'storyline_existing_main',
+            type: StorylineType.main,
+            title: 'Existing main',
+          ),
+        ]),
+      );
+      final before = harness.project.toJson();
+
+      await _openStructureTab(tester);
+
+      expect(find.byKey(const ValueKey('storylines-new-step-action')),
+          findsNothing);
+      expect(harness.project.toJson(), before);
+    });
+
+    testWidgets('opens and cancels create step without mutation',
+        (tester) async {
+      final harness = await _pumpStorylinesShell(
+        tester,
+        project: _projectWithStorylines([
+          StorylineAsset(
+            id: 'storyline_existing_main',
+            type: StorylineType.main,
+            title: 'Existing main',
+            chapters: [
+              StorylineChapter(
+                id: 'chapter_intro',
+                title: 'Intro',
+                order: 0,
+              ),
+            ],
+          ),
+        ]),
+      );
+      final before = harness.project.toJson();
+
+      await _openCreateStepDialog(tester);
+      expect(find.byKey(const ValueKey('storylines-create-step-dialog')),
+          findsOneWidget);
+
+      await tester.tap(
+        find.byKey(const ValueKey('storylines-create-step-cancel')),
+      );
+      await tester.pumpAndSettle();
+
+      expect(find.byKey(const ValueKey('storylines-create-step-dialog')),
+          findsNothing);
+      expect(harness.project.toJson(), before);
+    });
+
+    testWidgets('requires step title before create', (tester) async {
+      final harness = await _pumpStorylinesShell(
+        tester,
+        project: _projectWithStorylines([
+          StorylineAsset(
+            id: 'storyline_existing_main',
+            type: StorylineType.main,
+            title: 'Existing main',
+            chapters: [
+              StorylineChapter(
+                id: 'chapter_intro',
+                title: 'Intro',
+                order: 0,
+              ),
+            ],
+          ),
+        ]),
+      );
+
+      await _openCreateStepDialog(tester);
+
+      final submit = tester.widget<PokeMapButton>(
+        find.byKey(const ValueKey('storylines-create-step-submit')),
+      );
+      expect(submit.onPressed, isNull);
+      expect(find.text('Titre obligatoire.'), findsOneWidget);
+      expect(harness.project.storylines.single.chapters.single.steps, isEmpty);
+    });
+
+    testWidgets('creates steps with global unique ids and order',
+        (tester) async {
+      final harness = await _pumpStorylinesShell(
+        tester,
+        project: _projectWithStorylines([
+          StorylineAsset(
+            id: 'storyline_existing_main',
+            type: StorylineType.main,
+            title: 'Existing main',
+          ),
+        ]),
+      );
+
+      await _createChapter(tester, title: 'Intro');
+      await _createStep(
+        tester,
+        title: 'Premier jalon',
+        description: 'Définir la progression.',
+      );
+      await _createStep(tester, title: 'Premier jalon');
+      await _createChapter(tester, title: 'Second arc');
+      await _createStep(tester, title: 'Premier jalon');
+
+      final chapters = harness.project.storylines.single.chapters;
+      final allSteps = [
+        for (final chapter in chapters) ...chapter.steps,
+      ];
+      expect(allSteps.map((step) => step.id), [
+        'step_premier_jalon',
+        'step_premier_jalon_2',
+        'step_premier_jalon_3',
+      ]);
+      expect(chapters.first.steps.map((step) => step.order), [0, 1]);
+      expect(chapters.last.steps.single.order, 0);
+      expect(chapters.first.steps.first.title, 'Premier jalon');
+      expect(chapters.first.steps.first.description, 'Définir la progression.');
+      expect(chapters.first.steps.first.sceneLinkIds, isEmpty);
+      expect(chapters.first.steps.first.expectedOutcomeIds, isEmpty);
+      expect(
+          find.byKey(
+            const ValueKey('storylines-step-row-step_premier_jalon_3'),
+          ),
+          findsOneWidget);
+    });
+
+    testWidgets('Graph summarizes created structure without fake edges',
+        (tester) async {
+      await _pumpStorylinesShell(
+        tester,
+        project: _projectWithStorylines([
+          StorylineAsset(
+            id: 'storyline_existing_main',
+            type: StorylineType.main,
+            title: 'Existing main',
+          ),
+        ]),
+      );
+
+      await _createChapter(tester, title: 'Intro');
+      await _createStep(tester, title: 'Premier jalon');
+      await _openGraphTab(tester);
+
+      expect(
+        find.descendant(
+          of: find.byKey(const ValueKey('storylines-v1-graph-empty-canvas')),
+          matching: find.text('1 chapitre · 1 étape'),
+        ),
+        findsOneWidget,
+      );
+      expect(
+        find.text('Graph détaillé à venir au lot Graph From StorylineAsset.'),
+        findsOneWidget,
+      );
+      expect(find.text('Ajoutez des chapitres dans Structure.'), findsNothing);
+      expect(find.text('Quête annexe fake'), findsNothing);
     });
 
     testWidgets('generates stable unique ids on collision', (tester) async {
@@ -207,7 +483,7 @@ void main() {
       expect(find.text('Local Event Flow'), findsNothing);
     });
 
-    testWidgets('Graph, Structure and disabled chapter CTA do not mutate',
+    testWidgets('Graph, Structure and disabled future actions do not mutate',
         (tester) async {
       final harness = await _pumpStorylinesShell(
         tester,
@@ -223,11 +499,11 @@ void main() {
       final beforeMode = harness.editorState.workspaceMode;
 
       await _openStructureTab(tester);
-      final newChapterButton = find.byKey(
-        const ValueKey('storylines-new-chapter-disabled'),
+      final linkSceneButton = find.byKey(
+        const ValueKey('storylines-link-scene-disabled'),
       );
-      expect(newChapterButton, findsOneWidget);
-      expect(tester.widget<PokeMapButton>(newChapterButton).onPressed, isNull);
+      expect(linkSceneButton, findsOneWidget);
+      expect(tester.widget<PokeMapButton>(linkSceneButton).onPressed, isNull);
 
       await _openGraphTab(tester);
 
@@ -235,6 +511,41 @@ void main() {
       expect(harness.editorState.workspaceMode, beforeMode);
     });
 
+    testWidgets('Structure authoring does not import legacy or localEventFlow',
+        (tester) async {
+      final project = ProjectManifest(
+        surfaceCatalog: const ProjectSurfaceCatalog.empty(),
+        name: 'Legacy With Authoring',
+        maps: const <ProjectMapEntry>[],
+        tilesets: const <ProjectTilesetEntry>[],
+        scenarios: _legacyAndLocalEventProject().scenarios,
+        storylines: [
+          StorylineAsset(
+            id: 'storyline_existing_main',
+            type: StorylineType.main,
+            title: 'Existing main',
+          ),
+        ],
+      );
+      final harness = await _pumpStorylinesShell(tester, project: project);
+      final beforeScenarios = harness.project.scenarios;
+
+      await _createChapter(tester, title: 'Intro');
+      await _createStep(tester, title: 'Premier jalon');
+
+      expect(harness.project.scenarios, beforeScenarios);
+      expect(harness.project.storylines, hasLength(1));
+      expect(harness.project.storylines.single.legacySource, isNull);
+      expect(
+        harness.project.storylines
+            .where((s) => s.type == StorylineType.sideQuest),
+        isEmpty,
+      );
+      expect(harness.project.storylines.single.sceneLinks, isEmpty);
+      expect(find.text('Local Event Flow'), findsNothing);
+      expect(find.text('Legacy Global Story'), findsNothing);
+    });
+
     testWidgets('keeps target fake data and Maps out of the V1 UI',
         (tester) async {
       await _pumpStorylinesShell(tester,
@@ -278,44 +589,60 @@ void main() {
       expect(Theme.of(shellContext).brightness, Brightness.dark);
     });
 
-    testWidgets('writes V1-07 Visual Gate screenshots', (tester) async {
-      await _pumpStorylinesShell(tester, surfaceSize: const Size(1600, 1000));
+    testWidgets('writes V1-08 Structure Visual Gate screenshots',
+        (tester) async {
+      final project = _projectWithStorylines([
+        StorylineAsset(
+          id: 'storyline_visual_main',
+          type: StorylineType.main,
+          title: 'Visual Main',
+        ),
+      ]);
+
+      await _pumpStorylinesShell(
+        tester,
+        surfaceSize: const Size(1600, 1000),
+        project: project,
+      );
+      await _openStructureTab(tester);
       await expectLater(
         find.byKey(const ValueKey('storylines-workspace-shell')),
         matchesGoldenFile(
           '../../../reports/narrativeStudio/storylines/screenshots/'
-          'ns_storylines_v1_07_empty_storylines_desktop.png',
+          'ns_storylines_v1_08_structure_empty.png',
         ),
       );
 
-      await _pumpStorylinesShell(tester, surfaceSize: const Size(1600, 1000));
-      await _openCreateDialog(tester);
+      await tester
+          .tap(find.byKey(const ValueKey('storylines-new-chapter-action')));
+      await tester.pumpAndSettle();
       await expectLater(
-        find.byKey(const ValueKey('storylines-create-main-dialog')),
+        find.byKey(const ValueKey('storylines-create-chapter-dialog')),
         matchesGoldenFile(
           '../../../reports/narrativeStudio/storylines/screenshots/'
-          'ns_storylines_v1_07_create_main_dialog.png',
+          'ns_storylines_v1_08_create_chapter_dialog.png',
         ),
       );
-      await tester.tap(find.byKey(const ValueKey('storylines-create-cancel')));
+      await tester.tap(
+        find.byKey(const ValueKey('storylines-create-chapter-cancel')),
+      );
       await tester.pumpAndSettle();
 
-      await _pumpStorylinesShell(tester, surfaceSize: const Size(1600, 1000));
-      await _createMainStoryline(tester, title: 'Visual Gate Main');
+      await _createChapter(tester, title: 'Visual Chapter');
       await expectLater(
         find.byKey(const ValueKey('storylines-workspace-shell')),
         matchesGoldenFile(
           '../../../reports/narrativeStudio/storylines/screenshots/'
-          'ns_storylines_v1_07_created_main_graph.png',
+          'ns_storylines_v1_08_created_chapter.png',
         ),
       );
 
-      await _openStructureTab(tester);
+      await _createStep(tester, title: 'Visual Step');
       await expectLater(
         find.byKey(const ValueKey('storylines-workspace-shell')),
         matchesGoldenFile(
           '../../../reports/narrativeStudio/storylines/screenshots/'
-          'ns_storylines_v1_07_created_main_structure.png',
+          'ns_storylines_v1_08_created_step.png',
         ),
       );
     });
@@ -374,6 +701,61 @@ Future<void> _createMainStoryline(
   await tester.pumpAndSettle();
 }
 
+Future<void> _openCreateChapterDialog(WidgetTester tester) async {
+  await _openStructureTab(tester);
+  await tester.tap(find.byKey(const ValueKey('storylines-new-chapter-action')));
+  await tester.pumpAndSettle();
+}
+
+Future<void> _createChapter(
+  WidgetTester tester, {
+  required String title,
+  String? description,
+}) async {
+  await _openCreateChapterDialog(tester);
+  await tester.enterText(
+    find.byKey(const ValueKey('storylines-create-chapter-title-field')),
+    title,
+  );
+  if (description != null) {
+    await tester.enterText(
+      find.byKey(const ValueKey('storylines-create-chapter-description-field')),
+      description,
+    );
+  }
+  await tester.pump();
+  await tester
+      .tap(find.byKey(const ValueKey('storylines-create-chapter-submit')));
+  await tester.pumpAndSettle();
+}
+
+Future<void> _openCreateStepDialog(WidgetTester tester) async {
+  await _openStructureTab(tester);
+  await tester.tap(find.byKey(const ValueKey('storylines-new-step-action')));
+  await tester.pumpAndSettle();
+}
+
+Future<void> _createStep(
+  WidgetTester tester, {
+  required String title,
+  String? description,
+}) async {
+  await _openCreateStepDialog(tester);
+  await tester.enterText(
+    find.byKey(const ValueKey('storylines-create-step-title-field')),
+    title,
+  );
+  if (description != null) {
+    await tester.enterText(
+      find.byKey(const ValueKey('storylines-create-step-description-field')),
+      description,
+    );
+  }
+  await tester.pump();
+  await tester.tap(find.byKey(const ValueKey('storylines-create-step-submit')));
+  await tester.pumpAndSettle();
+}
+
 Future<void> _openStructureTab(WidgetTester tester) async {
   await tester.tap(
     find.descendant(
```

### Diff complet de road_map_storylines.md

```diff
diff --git a/reports/narrativeStudio/storylines/road_map_storylines.md b/reports/narrativeStudio/storylines/road_map_storylines.md
index 26848e7e..17694454 100644
--- a/reports/narrativeStudio/storylines/road_map_storylines.md
+++ b/reports/narrativeStudio/storylines/road_map_storylines.md
@@ -310,7 +310,7 @@ Interprétation V0 :
 | NS-STORYLINES-V1-06 | Legacy GlobalStory Import Preview V0 | migration preview | DONE | NS-STORYLINES-V1-07 |
 | NS-STORYLINES-V1-07 | Create Main Storyline Flow V0 | editor authoring | DONE | NS-STORYLINES-V1-07-bis |
 | NS-STORYLINES-V1-07-bis | Storylines Workspace Cleanup / Dead Legacy Removal | editor UI cleanup | DONE | NS-STORYLINES-V1-08 |
-| NS-STORYLINES-V1-08 | Structure Tab Authoring V0 | editor authoring | TODO | NS-STORYLINES-V1-09 |
+| NS-STORYLINES-V1-08 | Structure Tab Authoring V0 | editor authoring | DONE | NS-STORYLINES-V1-09 |
 | NS-STORYLINES-V1-09 | Create Side Quest Flow V0 | editor authoring | TODO | NS-STORYLINES-V1-10 |
 | NS-STORYLINES-V1-10 | Graph From StorylineAsset V0 | editor graph | TODO | NS-STORYLINES-V1-11 |
 | NS-STORYLINES-V1-11 | Side Quest Graph Integration V0 | editor graph | TODO | NS-STORYLINES-V1-12 |
@@ -764,6 +764,22 @@ Interprétation V0 :
 - Statut : DONE.
 - Prochain lot attendu : NS-STORYLINES-V1-08 — Structure Tab Authoring V0.
 
+### NS-STORYLINES-V1-08 — Structure Tab Authoring V0
+
+- Type : editor UI / authoring flow / structure tab / tests / visual gate.
+- Objectif : rendre l'onglet Structure utilisable pour créer des chapitres et des étapes narratives dans une `StorylineAsset` existante.
+- Résultat : `Nouveau chapitre` ouvre un formulaire minimal, crée un `StorylineChapter` draft avec id slugifié unique, ordre calculé et sélection locale du chapitre créé.
+- Résultat : `Nouvelle étape narrative` ouvre un formulaire minimal depuis un chapitre sélectionné, crée une `StorylineStep` avec id slugifié unique à l'échelle de la storyline, ordre calculé dans le chapitre, puis l'affiche dans Structure.
+- Structure : affiche résumé storyline, liste des chapitres, détail du chapitre sélectionné, liste des étapes narratives et section `Scènes liées` désactivée.
+- Graph : reste minimal et read-only ; après création de chapitres/steps il affiche un résumé réel et le message que le graph détaillé viendra au lot `Graph From StorylineAsset`.
+- Fichiers modifiés/créés : `packages/map_editor/lib/src/ui/canvas/storylines_workspace.dart`, `packages/map_editor/test/storylines_workspace_shell_test.dart`, `reports/narrativeStudio/storylines/road_map_storylines.md`, `reports/narrativeStudio/storylines/ns_storylines_v1_08_structure_tab_authoring_v0.md`, captures Visual Gate V1-08.
+- Tests exécutés : `flutter test test/storylines_workspace_shell_test.dart`, `flutter test test/storylines_current_global_story_characterization_test.dart`, `flutter test test/narrative_workspace_projection_test.dart`.
+- Analyse exécutée : `flutter analyze --no-fatal-infos lib/src/ui/canvas/storylines_workspace.dart test/storylines_workspace_shell_test.dart test/storylines_current_global_story_characterization_test.dart test/narrative_workspace_projection_test.dart`.
+- Design System Gate : confirmé ; aucun `Color(0x...)` / `Colors.*` dans les fichiers touchés.
+- Non-objectifs confirmés : aucune sideQuest, aucun scene placeholder, aucun sceneLink, aucun import legacy automatique, aucun `localEventFlow` promu, aucun `map_core`, runtime, gameplay ou battle modifié.
+- Statut : DONE.
+- Prochain lot attendu : NS-STORYLINES-V1-09 — Create Side Quest Flow V0.
+
 ## 10. Update protocol for every future lot
 
 Chaque futur lot Storylines doit :
@@ -880,10 +896,10 @@ Décision temporaire :
 ## 13. Current status
 
 ```text
-Roadmap status: V0 ACCEPTED WITH V1 LIMITATIONS / V1 CREATE MAIN STORYLINE FLOW DONE / V1-07-bis CLEANUP DONE
-Current lot: NS-STORYLINES-V1-07-bis
+Roadmap status: V0 ACCEPTED WITH V1 LIMITATIONS / V1 STRUCTURE AUTHORING DONE
+Current lot: NS-STORYLINES-V1-08
 Current lot status: DONE
-Next recommended lot: NS-STORYLINES-V1-08 — Structure Tab Authoring V0
+Next recommended lot: NS-STORYLINES-V1-09 — Create Side Quest Flow V0
 ```
 
 | Lot | Status | Last update | Notes |
@@ -911,7 +927,8 @@ Next recommended lot: NS-STORYLINES-V1-08 — Structure Tab Authoring V0
 | NS-STORYLINES-V1-06 | DONE | 2026-05-28 | Legacy GlobalStory Import Preview V0 livré : candidats non destructifs depuis `globalStory`, issues stables, `localEventFlow` ignoré. |
 | NS-STORYLINES-V1-07 | DONE | 2026-05-28 | Create Main Storyline Flow V0 livré : création main `StorylineAsset`, Graph/Structure seulement, aucun import legacy automatique. |
 | NS-STORYLINES-V1-07-bis | DONE | 2026-05-28 | Cleanup technique Storylines livré sans changement produit : legacy mort absent, tap silencieux supprimé, Visual Gate V1-07 régénéré. |
-| NS-STORYLINES-V1-08 | TODO | 2026-05-28 | Structure Tab Authoring V0 recommandé comme prochain lot. |
+| NS-STORYLINES-V1-08 | DONE | 2026-05-29 | Structure Tab Authoring V0 livré : création de chapitres et steps, Graph minimal honnête, aucun sceneLink/sideQuest/import legacy. |
+| NS-STORYLINES-V1-09 | TODO | 2026-05-29 | Create Side Quest Flow V0 recommandé comme prochain lot. |
 
 ## 14. V1 Creation Readiness Notes
 
@@ -948,6 +965,15 @@ Suite V1 documentaire recommandée :
 
 ## 15. Changelog
 
+### 2026-05-29 — NS-STORYLINES-V1-08
+
+- Structure Tab Authoring V0 livré côté editor : création de chapitres et d'étapes narratives dans `ProjectManifest.storylines`.
+- Mutations immuables via le notifier editor existant ; aucun modèle `map_core` modifié.
+- IDs `chapter_...` et `step_...` slugifiés, stables et collision-safe ; ordre chapitre/step calculé depuis les données existantes.
+- Graph minimal mis à jour pour afficher les vrais compteurs chapitres/steps sans branches ou edges fake.
+- Visual Gate V1-08 produit en dark theme.
+- Prochain lot recommandé : `NS-STORYLINES-V1-09 — Create Side Quest Flow V0`.
+
 ### 2026-05-28 — NS-STORYLINES-V1-07-bis
 
 - Cleanup technique sans changement produit sur `storylines_workspace.dart`.
```

### Sorties exactes des tests ciblés

`flutter test test/storylines_workspace_shell_test.dart`:

```text
00:00 +0: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/storylines_workspace_shell_test.dart
00:00 +0: NS-STORYLINES-V1-08 structure tab authoring flow shows only Graph and Structure tabs
00:00 +1: NS-STORYLINES-V1-08 structure tab authoring flow shows V1 empty state without importing legacy globalStory
00:00 +2: NS-STORYLINES-V1-08 structure tab authoring flow opens and cancels create main storyline dialog without mutation
00:00 +3: NS-STORYLINES-V1-08 structure tab authoring flow requires title before create
00:01 +4: NS-STORYLINES-V1-08 structure tab authoring flow creates a main StorylineAsset and syncs Graph and Structure
00:01 +5: NS-STORYLINES-V1-08 structure tab authoring flow Structure without storyline has no chapter or step action
00:01 +6: NS-STORYLINES-V1-08 structure tab authoring flow opens and cancels create chapter without mutation
00:01 +7: NS-STORYLINES-V1-08 structure tab authoring flow requires chapter title before create
00:01 +8: NS-STORYLINES-V1-08 structure tab authoring flow creates chapters with stable ids, order and selection
00:01 +9: NS-STORYLINES-V1-08 structure tab authoring flow step action requires a selected chapter
00:01 +10: NS-STORYLINES-V1-08 structure tab authoring flow opens and cancels create step without mutation
00:01 +11: NS-STORYLINES-V1-08 structure tab authoring flow requires step title before create
00:01 +12: NS-STORYLINES-V1-08 structure tab authoring flow creates steps with global unique ids and order
00:02 +13: NS-STORYLINES-V1-08 structure tab authoring flow Graph summarizes created structure without fake edges
00:02 +14: NS-STORYLINES-V1-08 structure tab authoring flow generates stable unique ids on collision
00:02 +15: NS-STORYLINES-V1-08 structure tab authoring flow does not allow creating a second main storyline
00:02 +16: NS-STORYLINES-V1-08 structure tab authoring flow creation does not import legacy or promote localEventFlow
00:02 +17: NS-STORYLINES-V1-08 structure tab authoring flow Graph, Structure and disabled future actions do not mutate
00:02 +18: NS-STORYLINES-V1-08 structure tab authoring flow Structure authoring does not import legacy or localEventFlow
00:03 +19: NS-STORYLINES-V1-08 structure tab authoring flow keeps target fake data and Maps out of the V1 UI
00:03 +20: NS-STORYLINES-V1-08 structure tab authoring flow storylines UI source keeps raw colors out of the feature
00:03 +21: NS-STORYLINES-V1-08 structure tab authoring flow storylines shell test keeps raw colors out
00:03 +22: NS-STORYLINES-V1-08 structure tab authoring flow uses PokeMap dark theme in the Visual Gate harness
00:03 +23: NS-STORYLINES-V1-08 structure tab authoring flow writes V1-08 Structure Visual Gate screenshots
00:03 +24: All tests passed!
```

`flutter test test/storylines_current_global_story_characterization_test.dart`:

```text
00:00 +0: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/storylines_current_global_story_characterization_test.dart
00:00 +0: NS-STORYLINES-02 current Global Story characterization renders the current Storylines shell from manifest and authoring metadata
[step_studio_trace] action=apply_document scenario=audit_global_story rows=[]
[step_studio_trace] action=apply_document_metadata scenario=audit_global_story contains_emma=false contains_empty_entity=false
00:00 +1: NS-STORYLINES-02 current Global Story characterization keeps globalStory and localEventFlow separated in the current projection
[step_studio_trace] action=apply_document scenario=audit_global_story rows=[]
[step_studio_trace] action=apply_document_metadata scenario=audit_global_story contains_emma=false contains_empty_entity=false
00:00 +2: All tests passed!
```

`flutter test test/narrative_workspace_projection_test.dart`:

```text
00:00 +0: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/narrative_workspace_projection_test.dart
00:00 +0: buildNarrativeWorkspaceProjection splits global story and local flows, and projects steps
00:00 +1: buildNarrativeWorkspaceProjection projects ordered steps from Step Studio v1 metadata document
00:00 +2: buildNarrativeWorkspaceProjection projects chapters from Global Story Studio metadata
00:00 +3: All tests passed!
```

### Sortie exacte de flutter analyze ciblé

```text
Analyzing 4 items...                                            
No issues found! (ran in 1.5s)
```

### Sortie exacte du rg anti-couleurs

```text
Sortie : <vide>
```

### Résultats du Visual Gate

```text
00:00 +0: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/storylines_workspace_shell_test.dart
00:00 +0: NS-STORYLINES-V1-08 structure tab authoring flow shows only Graph and Structure tabs
00:00 +1: NS-STORYLINES-V1-08 structure tab authoring flow shows V1 empty state without importing legacy globalStory
00:00 +2: NS-STORYLINES-V1-08 structure tab authoring flow opens and cancels create main storyline dialog without mutation
00:00 +3: NS-STORYLINES-V1-08 structure tab authoring flow requires title before create
00:01 +4: NS-STORYLINES-V1-08 structure tab authoring flow creates a main StorylineAsset and syncs Graph and Structure
00:01 +5: NS-STORYLINES-V1-08 structure tab authoring flow Structure without storyline has no chapter or step action
00:01 +6: NS-STORYLINES-V1-08 structure tab authoring flow opens and cancels create chapter without mutation
00:01 +7: NS-STORYLINES-V1-08 structure tab authoring flow requires chapter title before create
00:01 +8: NS-STORYLINES-V1-08 structure tab authoring flow creates chapters with stable ids, order and selection
00:01 +9: NS-STORYLINES-V1-08 structure tab authoring flow step action requires a selected chapter
00:02 +10: NS-STORYLINES-V1-08 structure tab authoring flow opens and cancels create step without mutation
00:02 +11: NS-STORYLINES-V1-08 structure tab authoring flow requires step title before create
00:02 +12: NS-STORYLINES-V1-08 structure tab authoring flow creates steps with global unique ids and order
00:03 +13: NS-STORYLINES-V1-08 structure tab authoring flow Graph summarizes created structure without fake edges
00:03 +14: NS-STORYLINES-V1-08 structure tab authoring flow generates stable unique ids on collision
00:03 +15: NS-STORYLINES-V1-08 structure tab authoring flow does not allow creating a second main storyline
00:03 +16: NS-STORYLINES-V1-08 structure tab authoring flow creation does not import legacy or promote localEventFlow
00:03 +17: NS-STORYLINES-V1-08 structure tab authoring flow Graph, Structure and disabled future actions do not mutate
00:03 +18: NS-STORYLINES-V1-08 structure tab authoring flow Structure authoring does not import legacy or localEventFlow
00:03 +19: NS-STORYLINES-V1-08 structure tab authoring flow keeps target fake data and Maps out of the V1 UI
00:04 +20: NS-STORYLINES-V1-08 structure tab authoring flow storylines UI source keeps raw colors out of the feature
00:04 +21: NS-STORYLINES-V1-08 structure tab authoring flow storylines shell test keeps raw colors out
00:04 +22: NS-STORYLINES-V1-08 structure tab authoring flow uses PokeMap dark theme in the Visual Gate harness
00:04 +23: NS-STORYLINES-V1-08 structure tab authoring flow writes V1-08 Structure Visual Gate screenshots
00:04 +24: All tests passed!
```

```text
-rw-r--r--  1 karim  staff  10814 May 29 00:24 reports/narrativeStudio/storylines/screenshots/ns_storylines_v1_08_create_chapter_dialog.png
-rw-r--r--  1 karim  staff  42858 May 29 00:24 reports/narrativeStudio/storylines/screenshots/ns_storylines_v1_08_created_chapter.png
-rw-r--r--  1 karim  staff  44042 May 29 00:24 reports/narrativeStudio/storylines/screenshots/ns_storylines_v1_08_created_step.png
-rw-r--r--  1 karim  staff  40637 May 29 00:24 reports/narrativeStudio/storylines/screenshots/ns_storylines_v1_08_structure_empty.png
```

### Git status final exact

```text
 M packages/map_editor/lib/src/ui/canvas/storylines_workspace.dart
 M packages/map_editor/test/storylines_workspace_shell_test.dart
 M reports/narrativeStudio/storylines/road_map_storylines.md
?? reports/narrativeStudio/storylines/ns_storylines_v1_08_structure_tab_authoring_v0.md
?? reports/narrativeStudio/storylines/screenshots/ns_storylines_v1_08_create_chapter_dialog.png
?? reports/narrativeStudio/storylines/screenshots/ns_storylines_v1_08_created_chapter.png
?? reports/narrativeStudio/storylines/screenshots/ns_storylines_v1_08_created_step.png
?? reports/narrativeStudio/storylines/screenshots/ns_storylines_v1_08_structure_empty.png
```

### Git diff --stat final

```text
 .../lib/src/ui/canvas/storylines_workspace.dart    | 809 ++++++++++++++++++++-
 .../test/storylines_workspace_shell_test.dart      | 422 ++++++++++-
 .../storylines/road_map_storylines.md              |  36 +-
 3 files changed, 1225 insertions(+), 42 deletions(-)
```

### Git diff --name-only final

```text
packages/map_editor/lib/src/ui/canvas/storylines_workspace.dart
packages/map_editor/test/storylines_workspace_shell_test.dart
reports/narrativeStudio/storylines/road_map_storylines.md
```

### Git diff --check final

```text
Sortie : <vide>
```

### Auto-review critique

- Scope respected: only allowed editor UI/test/roadmap/report/V1-08 screenshot files changed.
- `selbrume/project.json` was temporarily modified by the harness during verification, then manually restored before final status.
- Temporary Flutter golden failure artifacts were removed before final status.
- Old V1-07 screenshot files were not modified in final status; V1-08 uses new screenshot files.
- Test group still covers V1-07 create-main behavior as regression while adding V1-08 Structure authoring coverage.
- No `Color(0x...)` or `Colors.*` is present in touched Storylines source/test files.

## 20. Self-review

Verdict: DONE.

Structure is now usable for the V1 initial authoring chain: selected storyline -> chapters -> story steps. The next lot should be `NS-STORYLINES-V1-09 — Create Side Quest Flow V0`.
