# Lot PathPattern-37 — Project Dirty State / Save Pending UX V0

## 1. Résumé exécutif

Ce lot ajoute un état explicite `isProjectDirty` dans `map_editor` pour distinguer les modifications projet en mémoire (manifest) des modifications map.  
Après `applyInMemoryProjectManifest`, le projet passe dirty, la topbar hors map met la disquette en état actif avec tooltip explicite, et la status bar affiche un signal persistant “projet non sauvegardé”.  
Après succès de `saveProjectManifest`, l’état revient clean et le signal disparaît.

## 2. Audit initial

Fichiers de règles lus avant modification:

- `AGENTS.md`
- `agent_rules.md`

Commandes d’audit initial exécutées avant modification:

```bash
pwd
git status --short --untracked-files=all
git diff --stat
git diff --name-status
git ls-files reports/pathPattern/pathpattern_36_bis_apply_vs_save_project_ux_clarification_v0.md
git ls-files reports/pathPattern/pathpattern_36_deep_water_center_animation_persistence_bugfix_v0.md
```

Sortie exacte:

```text
/Users/karim/Project/pokemonProject
reports/pathPattern/pathpattern_36_bis_apply_vs_save_project_ux_clarification_v0.md
reports/pathPattern/pathpattern_36_deep_water_center_animation_persistence_bugfix_v0.md
```

## 3. Dirty state existant constaté

Réponses à l’audit demandé:

1. **Dirty state projet existant ?**  
   Non. Il n’y avait que `isDirty` (orienté document map/historique).
2. **Dirty state actuel map-centric ?**  
   Oui. `isDirty`, `canSaveMap`, `canUndoMap`, `canRedoMap`, et la logique shell/topbar map sont centrés map.
3. **Où `applyInMemoryProjectManifest` met à jour le manifest ?**  
   `packages/map_editor/lib/src/features/editor/state/editor_notifier.dart` (`state = state.copyWith(project: manifest)` avant lot).
4. **`applyInMemoryProjectManifest` marquait dirty ?**  
   Non avant lot.
5. **Où `saveProjectManifest` nettoie l’état ?**  
   Nulle part avant lot pour un dirty projet (seulement `statusMessage`/`errorMessage`).
6. **Topbar active/selected ?**  
   Via `toolbar.isDirty` uniquement (`editorToolbarSnapshotProvider` + `TopToolbar`).
7. **StatusBar affiche état projet ?**  
   Non, uniquement `errorMessage ?? statusMessage ?? "Ready"` + chips map/zoom.
8. **Path Studio reçoit info projet non sauvegardé ?**  
   Pas directement. Le panel affiche des feedbacks locaux “en mémoire”, mais aucun état global persistant projet non sauvegardé.

## 4. Décision isProjectDirty

Décision V0 retenue: ajouter `bool isProjectDirty` dans `EditorState`.

Motif:

- séparation claire map dirty vs project dirty ;
- impact minimal (pas de nouveau provider/service/repository) ;
- transitions faciles à prouver dans `EditorNotifier`.

## 5. Transitions dirty/clean

Transitions implémentées:

- `applyInMemoryProjectManifest(updatedManifest)`  
  -> `isProjectDirty = true`
- `saveProjectManifest()` succès  
  -> `isProjectDirty = false`
- `saveProjectManifest()` échec  
  -> conserve `isProjectDirty` (pas de reset)
- chargement projet (`openProjectSession`, `openMapDocument`)  
  -> `isProjectDirty = false`

## 6. Topbar Save Project

Modifs:

- En workspace map:
  - tooltip reste `Save Map`
  - `selected` reste basé sur `isDirty`
  - callback reste `saveActiveMap`
- Hors map:
  - tooltip `Save Project`, ou `Save Project — unsaved project changes` si dirty projet
  - `selected` basé sur `isProjectDirty`
  - callback reste `saveProjectManifest`

## 7. Status bar / signal persistant

Ajout d’un signal global persistant dans `StatusBar` quand `isProjectDirty == true`:

- message principal:
  - `Projet modifié en mémoire — sauvegardez le projet avec la disquette.`
- chip visuel:
  - `Projet non sauvegardé`
  - clé widget: `status-bar-project-dirty-chip`

Quand `isProjectDirty` revient `false`, ce signal disparaît.

## 8. Path Studio UX

Path Studio conserve le wording lot 36-bis (`Appliquer au projet` / `Appliquer les modifications`, feedback en mémoire).  
Le signal persistant “projet non sauvegardé” est désormais global via StatusBar + topbar dirty hors map.

## 9. Tests ajoutés/modifiés

- **Ajouté**
  - `packages/map_editor/test/editor_notifier_project_dirty_state_test.dart`
- **Modifiés**
  - `packages/map_editor/test/path_pattern/path_pattern_deep_water_persistence_bug_test.dart`
  - `packages/map_editor/test/top_toolbar_test.dart`
  - `packages/map_editor/test/status_bar_test.dart`
  - `packages/map_editor/test/editor_shell_page_smoke_test.dart`
  - `packages/map_editor/test/editor_selectors_test.dart`
  - `packages/map_editor/test/editor_state_groups_test.dart`

## 10. Fichiers créés

- `packages/map_editor/test/editor_notifier_project_dirty_state_test.dart`

## 11. Fichiers modifiés

- `packages/map_editor/lib/src/features/editor/application/project_session_controller.dart`
- `packages/map_editor/lib/src/features/editor/state/editor_notifier.dart`
- `packages/map_editor/lib/src/features/editor/state/editor_selectors.dart`
- `packages/map_editor/lib/src/features/editor/state/editor_state.dart`
- `packages/map_editor/lib/src/features/editor/state/editor_state.freezed.dart`
- `packages/map_editor/lib/src/features/editor/state/models/editor_state_groups.dart`
- `packages/map_editor/lib/src/ui/shared/status_bar.dart`
- `packages/map_editor/lib/src/ui/shared/top_toolbar.dart`
- `packages/map_editor/test/editor_selectors_test.dart`
- `packages/map_editor/test/editor_shell_page_smoke_test.dart`
- `packages/map_editor/test/editor_state_groups_test.dart`
- `packages/map_editor/test/path_pattern/path_pattern_deep_water_persistence_bug_test.dart`
- `packages/map_editor/test/status_bar_test.dart`
- `packages/map_editor/test/top_toolbar_test.dart`

## 12. Fichiers supprimés

- Aucun.

## 13. Tests exécutés

### map_editor

```bash
flutter test test/editor_notifier_project_dirty_state_test.dart --reporter expanded
flutter test test/path_pattern/path_pattern_deep_water_persistence_bug_test.dart --reporter expanded
flutter test test/path_pattern/path_studio_panel_test.dart --reporter expanded
flutter test test/top_toolbar_test.dart --reporter expanded
flutter test test/status_bar_test.dart --reporter expanded
flutter test test/editor_shell_page_smoke_test.dart --reporter expanded
flutter test test/editor_selectors_test.dart --reporter expanded
flutter test test/path_pattern/ --reporter expanded
flutter analyze lib/src/features/path_studio lib/src/features/path_pattern lib/src/features/editor lib/src/ui test/path_pattern
```

### map_core

```bash
dart test test/project_manifest_path_pattern_save_reload_test.dart --reporter expanded --no-color
dart test test/path_pattern_water_animated_golden_slice_test.dart --reporter expanded --no-color
dart analyze lib/src/models lib/src/operations test/project_manifest_path_pattern_save_reload_test.dart
```

### map_runtime

```bash
flutter test test/path_pattern_water_animated_runtime_golden_slice_test.dart --reporter expanded
flutter test test/path_pattern_runtime_reload_regression_test.dart --reporter expanded
```

## 14. Résultats des validations

- Tous les tests ciblés `map_editor`: **PASS**
- Tous les tests `map_core`: **PASS**
- Tous les tests `map_runtime`: **PASS**
- `dart analyze` ciblé `map_core`: **PASS**
- `flutter analyze` ciblé `map_editor`: **FAIL** sur warnings/infos préexistants hors scope (dont warning `undefined_shown_name` dans `pokedex_workspace_views.dart`)

## 15. git status final

```text
 M packages/map_editor/lib/src/features/editor/application/project_session_controller.dart
 M packages/map_editor/lib/src/features/editor/state/editor_notifier.dart
 M packages/map_editor/lib/src/features/editor/state/editor_selectors.dart
 M packages/map_editor/lib/src/features/editor/state/editor_state.dart
 M packages/map_editor/lib/src/features/editor/state/editor_state.freezed.dart
 M packages/map_editor/lib/src/features/editor/state/models/editor_state_groups.dart
 M packages/map_editor/lib/src/ui/shared/status_bar.dart
 M packages/map_editor/lib/src/ui/shared/top_toolbar.dart
 M packages/map_editor/test/editor_selectors_test.dart
 M packages/map_editor/test/editor_shell_page_smoke_test.dart
 M packages/map_editor/test/editor_state_groups_test.dart
 M packages/map_editor/test/path_pattern/path_pattern_deep_water_persistence_bug_test.dart
 M packages/map_editor/test/status_bar_test.dart
 M packages/map_editor/test/top_toolbar_test.dart
?? packages/map_editor/test/editor_notifier_project_dirty_state_test.dart
```

## 16. git diff --stat

```text
 .../application/project_session_controller.dart    |  6 ++-
 .../src/features/editor/state/editor_notifier.dart |  6 ++-
 .../features/editor/state/editor_selectors.dart    |  2 +
 .../src/features/editor/state/editor_state.dart    |  1 +
 .../editor/state/editor_state.freezed.dart         | 24 ++++++++-
 .../editor/state/models/editor_state_groups.dart   |  6 +++
 .../map_editor/lib/src/ui/shared/status_bar.dart   | 27 +++++++---
 .../map_editor/lib/src/ui/shared/top_toolbar.dart  | 17 +++++--
 .../map_editor/test/editor_selectors_test.dart     |  2 +
 .../test/editor_shell_page_smoke_test.dart         | 57 +++++++++++++++++++++-
 .../map_editor/test/editor_state_groups_test.dart  |  1 +
 ...th_pattern_deep_water_persistence_bug_test.dart | 26 +++++++---
 packages/map_editor/test/status_bar_test.dart      | 46 +++++++++++++++++
 packages/map_editor/test/top_toolbar_test.dart     | 32 +++++++++++-
 14 files changed, 227 insertions(+), 26 deletions(-)
```

## 17. git diff --name-status

```text
M	packages/map_editor/lib/src/features/editor/application/project_session_controller.dart
M	packages/map_editor/lib/src/features/editor/state/editor_notifier.dart
M	packages/map_editor/lib/src/features/editor/state/editor_selectors.dart
M	packages/map_editor/lib/src/features/editor/state/editor_state.dart
M	packages/map_editor/lib/src/features/editor/state/editor_state.freezed.dart
M	packages/map_editor/lib/src/features/editor/state/models/editor_state_groups.dart
M	packages/map_editor/lib/src/ui/shared/status_bar.dart
M	packages/map_editor/lib/src/ui/shared/top_toolbar.dart
M	packages/map_editor/test/editor_selectors_test.dart
M	packages/map_editor/test/editor_shell_page_smoke_test.dart
M	packages/map_editor/test/editor_state_groups_test.dart
M	packages/map_editor/test/path_pattern/path_pattern_deep_water_persistence_bug_test.dart
M	packages/map_editor/test/status_bar_test.dart
M	packages/map_editor/test/top_toolbar_test.dart
```

## 18. Evidence Pack

### 18.1 git status initial

```text
/Users/karim/Project/pokemonProject
reports/pathPattern/pathpattern_36_bis_apply_vs_save_project_ux_clarification_v0.md
reports/pathPattern/pathpattern_36_deep_water_center_animation_persistence_bugfix_v0.md
```

### 18.2 git status final

```text
 M packages/map_editor/lib/src/features/editor/application/project_session_controller.dart
 M packages/map_editor/lib/src/features/editor/state/editor_notifier.dart
 M packages/map_editor/lib/src/features/editor/state/editor_selectors.dart
 M packages/map_editor/lib/src/features/editor/state/editor_state.dart
 M packages/map_editor/lib/src/features/editor/state/editor_state.freezed.dart
 M packages/map_editor/lib/src/features/editor/state/models/editor_state_groups.dart
 M packages/map_editor/lib/src/ui/shared/status_bar.dart
 M packages/map_editor/lib/src/ui/shared/top_toolbar.dart
 M packages/map_editor/test/editor_selectors_test.dart
 M packages/map_editor/test/editor_shell_page_smoke_test.dart
 M packages/map_editor/test/editor_state_groups_test.dart
 M packages/map_editor/test/path_pattern/path_pattern_deep_water_persistence_bug_test.dart
 M packages/map_editor/test/status_bar_test.dart
 M packages/map_editor/test/top_toolbar_test.dart
?? packages/map_editor/test/editor_notifier_project_dirty_state_test.dart
```

### 18.3 git diff --stat final

```text
 .../application/project_session_controller.dart    |  6 ++-
 .../src/features/editor/state/editor_notifier.dart |  6 ++-
 .../features/editor/state/editor_selectors.dart    |  2 +
 .../src/features/editor/state/editor_state.dart    |  1 +
 .../editor/state/editor_state.freezed.dart         | 24 ++++++++-
 .../editor/state/models/editor_state_groups.dart   |  6 +++
 .../map_editor/lib/src/ui/shared/status_bar.dart   | 27 +++++++---
 .../map_editor/lib/src/ui/shared/top_toolbar.dart  | 17 +++++--
 .../map_editor/test/editor_selectors_test.dart     |  2 +
 .../test/editor_shell_page_smoke_test.dart         | 57 +++++++++++++++++++++-
 .../map_editor/test/editor_state_groups_test.dart  |  1 +
 ...th_pattern_deep_water_persistence_bug_test.dart | 26 +++++++---
 packages/map_editor/test/status_bar_test.dart      | 46 +++++++++++++++++
 packages/map_editor/test/top_toolbar_test.dart     | 32 +++++++++++-
 14 files changed, 227 insertions(+), 26 deletions(-)
```

### 18.4 git diff --name-status final

```text
M	packages/map_editor/lib/src/features/editor/application/project_session_controller.dart
M	packages/map_editor/lib/src/features/editor/state/editor_notifier.dart
M	packages/map_editor/lib/src/features/editor/state/editor_selectors.dart
M	packages/map_editor/lib/src/features/editor/state/editor_state.dart
M	packages/map_editor/lib/src/features/editor/state/editor_state.freezed.dart
M	packages/map_editor/lib/src/features/editor/state/models/editor_state_groups.dart
M	packages/map_editor/lib/src/ui/shared/status_bar.dart
M	packages/map_editor/lib/src/ui/shared/top_toolbar.dart
M	packages/map_editor/test/editor_selectors_test.dart
M	packages/map_editor/test/editor_shell_page_smoke_test.dart
M	packages/map_editor/test/editor_state_groups_test.dart
M	packages/map_editor/test/path_pattern/path_pattern_deep_water_persistence_bug_test.dart
M	packages/map_editor/test/status_bar_test.dart
M	packages/map_editor/test/top_toolbar_test.dart
```

### 18.5 Diff complet réel des fichiers modifiés

```diff
diff --git a/packages/map_editor/lib/src/features/editor/application/project_session_controller.dart b/packages/map_editor/lib/src/features/editor/application/project_session_controller.dart
index 4734fefc..24b15f32 100644
--- a/packages/map_editor/lib/src/features/editor/application/project_session_controller.dart
+++ b/packages/map_editor/lib/src/features/editor/application/project_session_controller.dart
@@ -68,7 +68,8 @@ class ProjectSessionController {
             statusMessage: statusMessage,
             errorMessage: null,
           ),
-        );
+        )
+        .copyWith(isProjectDirty: false);
   }
@@ -122,7 +123,8 @@ class ProjectSessionController {
             statusMessage: statusMessage,
             errorMessage: null,
           ),
-        );
+        )
+        .copyWith(isProjectDirty: false);
   }
```

```diff
diff --git a/packages/map_editor/lib/src/features/editor/state/editor_notifier.dart b/packages/map_editor/lib/src/features/editor/state/editor_notifier.dart
index e6522a65..29da8046 100644
--- a/packages/map_editor/lib/src/features/editor/state/editor_notifier.dart
+++ b/packages/map_editor/lib/src/features/editor/state/editor_notifier.dart
@@ -413,7 +413,10 @@ class EditorNotifier extends _$EditorNotifier {
   }
 
   void applyInMemoryProjectManifest(ProjectManifest manifest) {
-    state = state.copyWith(project: manifest);
+    state = state.copyWith(
+      project: manifest,
+      isProjectDirty: true,
+    );
   }
@@ -432,6 +435,7 @@ class EditorNotifier extends _$EditorNotifier {
             fs.projectManifestPath,
           );
       state = state.copyWith(
+        isProjectDirty: false,
         statusMessage: 'Projet sauvegardé via le flux projet existant.',
         errorMessage: null,
       );
```

```diff
diff --git a/packages/map_editor/lib/src/features/editor/state/editor_selectors.dart b/packages/map_editor/lib/src/features/editor/state/editor_selectors.dart
index 91e0c96e..4be10b08 100644
--- a/packages/map_editor/lib/src/features/editor/state/editor_selectors.dart
+++ b/packages/map_editor/lib/src/features/editor/state/editor_selectors.dart
@@ -38,6 +38,7 @@ typedef EditorToolbarSnapshot = ({
   CollisionBrushSizeMode collisionBrushSizeMode,
   bool isSaving,
   bool isDirty,
+  bool isProjectDirty,
   bool canSaveMap,
@@ -209,6 +210,7 @@ final editorToolbarSnapshotProvider = Provider<EditorToolbarSnapshot>((ref) {
         collisionBrushSizeMode: state.collisionBrushSizeMode,
         isSaving: state.isSaving,
         isDirty: state.isDirty,
+        isProjectDirty: state.isProjectDirty,
         canSaveMap: exposesMapActions && state.activeMap != null,
```

```diff
diff --git a/packages/map_editor/lib/src/features/editor/state/editor_state.dart b/packages/map_editor/lib/src/features/editor/state/editor_state.dart
index b2a57c7e..ababe5a6 100644
--- a/packages/map_editor/lib/src/features/editor/state/editor_state.dart
+++ b/packages/map_editor/lib/src/features/editor/state/editor_state.dart
@@ -110,6 +110,7 @@ class EditorState with _$EditorState {
     @Default(false) bool canUndoMap,
     @Default(false) bool canRedoMap,
     @Default(false) bool isDirty,
+    @Default(false) bool isProjectDirty,
     @Default(false) bool isSaving,
```

```diff
diff --git a/packages/map_editor/lib/src/features/editor/state/editor_state.freezed.dart b/packages/map_editor/lib/src/features/editor/state/editor_state.freezed.dart
index c3b439d6..3c53b4a3 100644
--- a/packages/map_editor/lib/src/features/editor/state/editor_state.freezed.dart
+++ b/packages/map_editor/lib/src/features/editor/state/editor_state.freezed.dart
@@ -773,6 +773,7 @@ mixin _$EditorState {
   bool get canRedoMap => throw _privateConstructorUsedError;
   bool get isDirty => throw _privateConstructorUsedError;
+  bool get isProjectDirty => throw _privateConstructorUsedError;
@@
@@ -833,6 +834,7 @@ abstract class $EditorStateCopyWith<$Res> {
       bool canUndoMap,
       bool canRedoMap,
       bool isDirty,
+      bool isProjectDirty,
       bool isSaving,
@@ -903,6 +905,7 @@ class _$EditorStateCopyWithImpl<$Res, $Val extends EditorState>
     Object? canUndoMap = null,
     Object? canRedoMap = null,
     Object? isDirty = null,
+    Object? isProjectDirty = null,
@@ -1077,6 +1080,10 @@ class _$EditorStateCopyWithImpl<$Res, $Val extends EditorState>
           ? _value.isDirty
           : isDirty // ignore: cast_nullable_to_non_nullable
               as bool,
+      isProjectDirty: null == isProjectDirty
+          ? _value.isProjectDirty
+          : isProjectDirty // ignore: cast_nullable_to_non_nullable
+              as bool,
@@ -1238,6 +1245,7 @@ abstract class _$$EditorStateImplCopyWith<$Res>
       bool canUndoMap,
       bool canRedoMap,
       bool isDirty,
+      bool isProjectDirty,
       bool isSaving,
@@ -1313,6 +1321,7 @@ class __$$EditorStateImplCopyWithImpl<$Res>
     Object? canUndoMap = null,
     Object? canRedoMap = null,
     Object? isDirty = null,
+    Object? isProjectDirty = null,
@@ -1487,6 +1496,10 @@ class __$$EditorStateImplCopyWithImpl<$Res>
           ? _value.isDirty
           : isDirty // ignore: cast_nullable_to_non_nullable
               as bool,
+      isProjectDirty: null == isProjectDirty
+          ? _value.isProjectDirty
+          : isProjectDirty // ignore: cast_nullable_to_non_nullable
+              as bool,
@@ -1549,6 +1562,7 @@ class _$EditorStateImpl implements _EditorState {
       this.canUndoMap = false,
       this.canRedoMap = false,
       this.isDirty = false,
+      this.isProjectDirty = false,
@@ -1703,6 +1717,9 @@ class _$EditorStateImpl implements _EditorState {
   final bool isDirty;
   @override
   @JsonKey()
+  final bool isProjectDirty;
+  @override
+  @JsonKey()
   final bool isSaving;
@@ -1794,6 +1811,7 @@ class _$EditorStateImpl implements _EditorState {
             (identical(other.canUndoMap, canUndoMap) || other.canUndoMap == canUndoMap) &&
             (identical(other.canRedoMap, canRedoMap) || other.canRedoMap == canRedoMap) &&
             (identical(other.isDirty, isDirty) || other.isDirty == isDirty) &&
+            (identical(other.isProjectDirty, isProjectDirty) || other.isProjectDirty == isProjectDirty) &&
             (identical(other.isSaving, isSaving) || other.isSaving == isSaving) &&
@@ -1844,6 +1862,7 @@ class _$EditorStateImpl implements _EditorState {
         canUndoMap,
         canRedoMap,
         isDirty,
+        isProjectDirty,
@@ -1902,6 +1921,7 @@ abstract class _EditorState implements EditorState {
       final bool canUndoMap,
       final bool canRedoMap,
       final bool isDirty,
+      final bool isProjectDirty,
@@ -2010,6 +2030,8 @@ abstract class _EditorState implements EditorState {
   @override
   bool get isDirty;
   @override
+  bool get isProjectDirty;
+  @override
   bool get isSaving;
```

```diff
diff --git a/packages/map_editor/lib/src/features/editor/state/models/editor_state_groups.dart b/packages/map_editor/lib/src/features/editor/state/models/editor_state_groups.dart
index f213c35e..8a472c2a 100644
--- a/packages/map_editor/lib/src/features/editor/state/models/editor_state_groups.dart
+++ b/packages/map_editor/lib/src/features/editor/state/models/editor_state_groups.dart
@@ -257,6 +257,7 @@ class EditorDocumentStatusState {
     required this.canRedoMap,
     required this.isDirty,
+    required this.isProjectDirty,
@@
   final bool isDirty;
+  final bool isProjectDirty;
@@
       isDirty: isDirty ?? this.isDirty,
+      isProjectDirty: isProjectDirty ?? this.isProjectDirty,
@@
         isDirty: isDirty,
+        isProjectDirty: isProjectDirty,
@@
       isDirty: next.isDirty,
+      isProjectDirty: next.isProjectDirty,
```

```diff
diff --git a/packages/map_editor/lib/src/ui/shared/status_bar.dart b/packages/map_editor/lib/src/ui/shared/status_bar.dart
index abac0c35..3c2b0d61 100644
--- a/packages/map_editor/lib/src/ui/shared/status_bar.dart
+++ b/packages/map_editor/lib/src/ui/shared/status_bar.dart
@@ -12,7 +12,14 @@ class StatusBar extends ConsumerWidget {
     final state = ref.watch(editorNotifierProvider);
     final activeMap = state.activeMap;
+    const pendingProjectSaveMessage =
+        'Projet modifié en mémoire — sauvegardez le projet avec la disquette.';
@@
-                  state.errorMessage ?? state.statusMessage ?? 'Ready',
+                  primaryMessage,
@@
+              if (state.isProjectDirty) ...[
+                _statusChip(
+                  context,
+                  'Projet non sauvegardé',
+                  CupertinoIcons.floppy_disk,
+                  labelColor,
+                  key: const Key('status-bar-project-dirty-chip'),
+                ),
+                const SizedBox(width: 8),
+              ],
```

```diff
diff --git a/packages/map_editor/lib/src/ui/shared/top_toolbar.dart b/packages/map_editor/lib/src/ui/shared/top_toolbar.dart
index 1585683b..95ef33d4 100644
--- a/packages/map_editor/lib/src/ui/shared/top_toolbar.dart
+++ b/packages/map_editor/lib/src/ui/shared/top_toolbar.dart
@@ -167,14 +167,21 @@ class TopToolbar extends ConsumerWidget {
-              tooltip: toolbar.workspaceMode == EditorWorkspaceMode.map
-                  ? 'Save Map'
-                  : 'Save Project',
-              selected: toolbar.isDirty,
+              tooltip: switch (toolbar.workspaceMode) {
+                EditorWorkspaceMode.map => 'Save Map',
+                _ => toolbar.isProjectDirty
+                    ? 'Save Project — unsaved project changes'
+                    : 'Save Project',
+              },
+              selected: switch (toolbar.workspaceMode) {
+                EditorWorkspaceMode.map => toolbar.isDirty,
+                _ => toolbar.isProjectDirty,
+              },
```

```diff
diff --git a/packages/map_editor/test/editor_selectors_test.dart b/packages/map_editor/test/editor_selectors_test.dart
index 3cc6daa8..ede26c25 100644
--- a/packages/map_editor/test/editor_selectors_test.dart
+++ b/packages/map_editor/test/editor_selectors_test.dart
@@ -91,6 +91,7 @@ void main() {
         canRedoMap: true,
         isDirty: true,
+        isProjectDirty: true,
@@
       expect(toolbar.canRedoMap, isFalse);
+      expect(toolbar.isProjectDirty, isTrue);
```

```diff
diff --git a/packages/map_editor/test/editor_shell_page_smoke_test.dart b/packages/map_editor/test/editor_shell_page_smoke_test.dart
index 86ec34e6..3026ef3f 100644
--- a/packages/map_editor/test/editor_shell_page_smoke_test.dart
+++ b/packages/map_editor/test/editor_shell_page_smoke_test.dart
@@ -11,6 +11,7 @@
 import 'package:map_editor/src/features/editor/state/editor_state.dart';
+import 'package:map_editor/src/ui/shared/top_toolbar/widgets/toolbar_capsules.dart';
@@
+    testWidgets('affiche puis retire le signal projet non sauvegardé', (tester) async {
```

```diff
diff --git a/packages/map_editor/test/editor_state_groups_test.dart b/packages/map_editor/test/editor_state_groups_test.dart
index 79975ab4..511b4d0f 100644
--- a/packages/map_editor/test/editor_state_groups_test.dart
+++ b/packages/map_editor/test/editor_state_groups_test.dart
@@ -134,6 +134,7 @@ void main() {
               isDirty: true,
+              isProjectDirty: false,
               isSaving: false,
```

```diff
diff --git a/packages/map_editor/test/path_pattern/path_pattern_deep_water_persistence_bug_test.dart b/packages/map_editor/test/path_pattern/path_pattern_deep_water_persistence_bug_test.dart
index 3e3a7066..acef6ea8 100644
--- a/packages/map_editor/test/path_pattern/path_pattern_deep_water_persistence_bug_test.dart
+++ b/packages/map_editor/test/path_pattern/path_pattern_deep_water_persistence_bug_test.dart
@@
       notifier.applyInMemoryProjectManifest(updatedManifest);
+      expect(notifier.state.isProjectDirty, isTrue);
       final saveResult = await notifier.saveProjectManifest();
       expect(saveResult, isTrue);
+      expect(notifier.state.isProjectDirty, isFalse);
```

```diff
diff --git a/packages/map_editor/test/status_bar_test.dart b/packages/map_editor/test/status_bar_test.dart
index df263996..fdff914b 100644
--- a/packages/map_editor/test/status_bar_test.dart
+++ b/packages/map_editor/test/status_bar_test.dart
@@
+import 'package:flutter/widgets.dart';
+import 'package:map_editor/src/features/editor/state/editor_notifier.dart';
@@
+    testWidgets('shows persistent unsaved-project signal when project is dirty', (tester) async {
+    testWidgets('hides unsaved-project signal after project save success', (tester) async {
```

```diff
diff --git a/packages/map_editor/test/top_toolbar_test.dart b/packages/map_editor/test/top_toolbar_test.dart
index 6595b1e8..6e58eb76 100644
--- a/packages/map_editor/test/top_toolbar_test.dart
+++ b/packages/map_editor/test/top_toolbar_test.dart
@@
-          isDirty: true,
+          isProjectDirty: true,
@@
-      expect(buttonWithTooltip('Save Project').onPressed, isNotNull);
+      final saveButton = buttonWithTooltip('Save Project — unsaved project changes');
+      expect(saveButton.onPressed, isNotNull);
+      expect(saveButton.selected, isTrue);
@@
+    testWidgets('shows neutral Save Project when project is clean in Path Studio', (tester) async {
```

### 18.6 Contenu complet des fichiers créés

`packages/map_editor/test/editor_notifier_project_dirty_state_test.dart`

```dart
import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/editor/state/editor_notifier.dart';

void main() {
  group('EditorNotifier project dirty state', () {
    test('isProjectDirty vaut false par défaut', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(editorNotifierProvider).isProjectDirty, isFalse);
    });

    test('applyInMemoryProjectManifest passe isProjectDirty à true', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(editorNotifierProvider.notifier);
      notifier.state =
          notifier.state.copyWith(project: _manifest(name: 'Demo'));

      notifier.applyInMemoryProjectManifest(_manifest(name: 'Demo updated'));

      expect(notifier.state.isProjectDirty, isTrue);
    });

    test('saveProjectManifest réussi repasse isProjectDirty à false', () async {
      final tempDir =
          await Directory.systemTemp.createTemp('project_dirty_ok_');
      addTearDown(() async => tempDir.delete(recursive: true));
      final manifestPath = '${tempDir.path}/project.json';
      await File(manifestPath).writeAsString(jsonEncode(_manifest().toJson()));

      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(editorNotifierProvider.notifier);
      await notifier.loadProject(manifestPath);

      notifier.applyInMemoryProjectManifest(_manifest(name: 'Dirty'));
      expect(notifier.state.isProjectDirty, isTrue);

      final saved = await notifier.saveProjectManifest();

      expect(saved, isTrue);
      expect(notifier.state.isProjectDirty, isFalse);
    });

    test('saveProjectManifest échoué conserve isProjectDirty à true', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(editorNotifierProvider.notifier);
      notifier.state =
          notifier.state.copyWith(project: _manifest(name: 'Demo'));
      notifier.applyInMemoryProjectManifest(_manifest(name: 'Dirty'));

      final saved = await notifier.saveProjectManifest();

      expect(saved, isFalse);
      expect(notifier.state.isProjectDirty, isTrue);
    });

    test('chargement projet initialise isProjectDirty à false', () async {
      final tempDir =
          await Directory.systemTemp.createTemp('project_dirty_load_');
      addTearDown(() async => tempDir.delete(recursive: true));
      final manifestPath = '${tempDir.path}/project.json';
      await File(manifestPath).writeAsString(jsonEncode(_manifest().toJson()));

      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(editorNotifierProvider.notifier);
      notifier.state = notifier.state.copyWith(isProjectDirty: true);

      await notifier.loadProject(manifestPath);

      expect(notifier.state.isProjectDirty, isFalse);
    });
  });
}

ProjectManifest _manifest({String name = 'Demo'}) {
  return ProjectManifest(
    name: name,
    maps: const [],
    tilesets: const [],
    pathPresets: const [],
    pathPatternPresets: const [],
    surfaceCatalog: ProjectSurfaceCatalog(),
  );
}
```

### 18.7 Sorties complètes des tests ciblés principaux

#### `flutter test test/editor_notifier_project_dirty_state_test.dart --reporter expanded`

```text
00:00 +0: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/editor_notifier_project_dirty_state_test.dart
00:00 +0: EditorNotifier project dirty state isProjectDirty vaut false par défaut
00:00 +1: EditorNotifier project dirty state applyInMemoryProjectManifest passe isProjectDirty à true
00:00 +2: EditorNotifier project dirty state saveProjectManifest réussi repasse isProjectDirty à false
EditorNotifier: loadProject(/var/folders/b5/7gsfwzyd449_54n8l40h40gc0000gn/T/project_dirty_ok_sivbr2/project.json)
FileProjectRepository: Loading project from /var/folders/b5/7gsfwzyd449_54n8l40h40gc0000gn/T/project_dirty_ok_sivbr2/project.json
EditorNotifier: saveProjectManifest()
FileProjectRepository: Validating and saving project to /var/folders/b5/7gsfwzyd449_54n8l40h40gc0000gn/T/project_dirty_ok_sivbr2/project.json
00:00 +3: EditorNotifier project dirty state saveProjectManifest échoué conserve isProjectDirty à true
00:00 +4: EditorNotifier project dirty state chargement projet initialise isProjectDirty à false
EditorNotifier: loadProject(/var/folders/b5/7gsfwzyd449_54n8l40h40gc0000gn/T/project_dirty_load_2KgUDH/project.json)
FileProjectRepository: Loading project from /var/folders/b5/7gsfwzyd449_54n8l40h40gc0000gn/T/project_dirty_load_2KgUDH/project.json
00:00 +5: All tests passed!
```

#### `flutter test test/path_pattern/path_pattern_deep_water_persistence_bug_test.dart --reporter expanded`

```text
00:00 +0: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/path_pattern/path_pattern_deep_water_persistence_bug_test.dart
00:00 +0: PathPattern deep_water persistence bugfix fixture deep_water statique documente une frame par cellule
00:00 +1: PathPattern deep_water persistence bugfix create flow conserve deep_water multi-frame jusqu au JSON roundtrip
00:00 +2: PathPattern deep_water persistence bugfix edit flow part de statique et persiste deep_water multi-frame
00:00 +3: PathPattern deep_water persistence bugfix saveProjectManifest serialize le manifest courant en memoire
EditorNotifier: loadProject(/var/folders/b5/7gsfwzyd449_54n8l40h40gc0000gn/T/deep_water_persistence_0lO3Sw/project.json)
FileProjectRepository: Loading project from /var/folders/b5/7gsfwzyd449_54n8l40h40gc0000gn/T/deep_water_persistence_0lO3Sw/project.json
EditorNotifier: saveProjectManifest()
FileProjectRepository: Validating and saving project to /var/folders/b5/7gsfwzyd449_54n8l40h40gc0000gn/T/deep_water_persistence_0lO3Sw/project.json
00:00 +4: All tests passed!
```

#### `flutter test test/top_toolbar_test.dart --reporter expanded`

```text
00:00 +0: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/top_toolbar_test.dart
00:00 +0: TopToolbar shows the app brand and project workspace label
Warning: Falling back on slow accent color resolution. It’s possible that the accent colors have changed in a recent version of macOS, thus invalidating macos_ui’s accent colors, which were captured on macOS Ventura. If you see this message, please notify a maintainer of the macos_ui package.
00:00 +1: TopToolbar falls back to the workspace label when no project is loaded
00:00 +2: TopToolbar shows the toolbar status chip when a status is present
00:00 +3: TopToolbar shows the trainer studio label for the trainer workspace
00:00 +4: TopToolbar enables project save and disables map history in Path Studio
00:00 +5: TopToolbar shows neutral Save Project when project is clean in Path Studio
00:00 +6: TopToolbar keeps map save action in map workspace
00:00 +7: All tests passed!
```

#### `flutter test test/status_bar_test.dart --reporter expanded`

```text
00:00 +0: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/status_bar_test.dart
00:00 +0: StatusBar shows ready and zoom when no map is active
Warning: Falling back on slow accent color resolution. It’s possible that the accent colors have changed in a recent version of macOS, thus invalidating macos_ui’s accent colors, which were captured on macOS Ventura. If you see this message, please notify a maintainer of the macos_ui package.
00:00 +1: StatusBar shows active map chips and formatted zoom
00:00 +2: StatusBar prioritizes error text over status text
00:00 +3: StatusBar shows persistent unsaved-project signal when project is dirty
00:00 +4: StatusBar hides unsaved-project signal after project save success
00:00 +5: All tests passed!
```

#### `flutter test test/editor_shell_page_smoke_test.dart --reporter expanded`

```text
00:00 +0: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/editor_shell_page_smoke_test.dart
00:00 +0: EditorShellPage smoke renders map workspace chrome and toggles the right panel
Warning: Falling back on slow accent color resolution. It’s possible that the accent colors have changed in a recent version of macOS, thus invalidating macos_ui’s accent colors, which were captured on macOS Ventura. If you see this message, please notify a maintainer of the macos_ui package.
00:00 +1: EditorShellPage smoke updates the workspace header for tileset mode
00:01 +2: EditorShellPage smoke renders the trainer studio workspace chrome
FileProjectRepository: Loading project from /tmp/editor_shell_trainer/project.json
00:01 +3: EditorShellPage smoke renders the Pokémon catalogs workspace shell
00:01 +4: EditorShellPage smoke renders the Items catalogs workspace shell
00:01 +5: EditorShellPage smoke opens Path Studio from the project explorer
00:01 +6: EditorShellPage smoke renders shell chrome with an error state already present
00:02 +7: EditorShellPage smoke Cmd/Ctrl+S saves map in map workspace
00:02 +8: EditorShellPage smoke Cmd/Ctrl+S saves project outside map workspace
EditorNotifier: saveProjectManifest()
FileProjectRepository: Validating and saving project to /tmp/editor_shell_shortcut_path_studio/project.json
00:02 +9: EditorShellPage smoke Cmd/Ctrl+S no-op sans projet chargé
00:02 +10: EditorShellPage smoke affiche puis retire le signal projet non sauvegardé
00:02 +11: All tests passed!
```

#### `flutter test test/editor_selectors_test.dart --reporter expanded`

```text
00:00 +0: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/editor_selectors_test.dart
00:00 +0: editor selectors editorShellSnapshotProvider derives map title and save affordance
00:00 +1: editor selectors editorToolbarSnapshotProvider resolves selected tileset from layer
00:00 +2: editor selectors Path Studio snapshots hide map save and history actions
00:00 +3: editor selectors editorProjectExplorerSnapshotProvider exposes active map selection
00:00 +4: editor selectors editorShellSnapshotProvider exposes trainer studio labels
00:00 +5: editor selectors editorShellSnapshotProvider exposes Pokémon catalogs labels
00:00 +6: editor selectors editorTerrainLibrarySnapshotProvider exposes preset selection inputs
00:00 +7: editor selectors editorTilesetPaletteSnapshotProvider exposes palette panel state
00:00 +8: All tests passed!
```

#### `flutter test test/path_pattern/ --reporter expanded`

```text
00:10 +168: All tests passed!
```

#### `flutter analyze lib/src/features/path_studio lib/src/features/path_pattern lib/src/features/editor lib/src/ui test/path_pattern`

```text
Analyzing 5 items...
warning • The library 'package:map_editor/src/ui/canvas/pokedex_workspace/pokedex_workspace_page.dart' doesn't export a member with the shown name 'showPokedexImportFlowSheet' • lib/src/ui/canvas/pokedex_workspace_views.dart:17:9 • undefined_shown_name
49 issues found. (ran in 2.7s)
```

#### `map_core` validations

```text
00:00 +3: All tests passed!
00:00 +2: All tests passed!
Analyzing models, operations, project_manifest_path_pattern_save_reload_test.dart...
No issues found!
```

#### `map_runtime` validations

```text
00:00 +1: All tests passed!
00:00 +1: All tests passed!
```

### 18.8 Ligne finale exacte des grosses régressions

- `flutter test test/path_pattern/ --reporter expanded`  
  `00:10 +168: All tests passed!`
- `dart analyze lib/src/models lib/src/operations test/project_manifest_path_pattern_save_reload_test.dart`  
  `No issues found!`
- `flutter test test/path_pattern_water_animated_runtime_golden_slice_test.dart --reporter expanded`  
  `00:00 +1: All tests passed!`

### 18.9 Preuve apply -> dirty -> save project -> clean

Preuve explicite par test ajouté:

- `EditorNotifier project dirty state saveProjectManifest réussi repasse isProjectDirty à false`
- et dans deep_water:
  - `expect(notifier.state.isProjectDirty, isTrue);` juste après `applyInMemoryProjectManifest`
  - `expect(notifier.state.isProjectDirty, isFalse);` juste après `saveProjectManifest`

### 18.10 Preuve project.json écrit contient les frames deep_water

Preuve par test réel disque `saveProjectManifest serialize le manifest courant en memoire`:

- écrit manifest en mémoire sur disque (`saveProjectManifest`)
- relit `project.json` depuis le chemin temporaire réel
- vérifie frames animées deep_water (`_expectDeepWaterAnimatedPattern(...)`)

Sortie de commande associée:

```text
EditorNotifier: saveProjectManifest()
FileProjectRepository: Validating and saving project to /var/folders/b5/7gsfwzyd449_54n8l40h40gc0000gn/T/deep_water_persistence_0lO3Sw/project.json
00:00 +4: All tests passed!
```

## 19. Auto-review

Points prouvés:

- dirty state projet séparé (`isProjectDirty`) implanté dans state ;
- transitions dirty/clean implémentées et testées (`applyInMemoryProjectManifest`, `saveProjectManifest`, `loadProject`) ;
- topbar hors map reflète dirty projet (selected + tooltip) ;
- signal persistant visible status bar ;
- deep_water conserve le flux disque et ajoute preuve dirty->clean.

Limites:

- `flutter analyze` ciblé map_editor n’est pas vert (préexistant hors scope lot).
- le test shell “disparition après save” est vérifié via bascule d’état notifier dans harness (pas via clic IO réel dans ce test précis), compensé par tests notifier + deep_water disque réel.

## 20. Critique du prompt

Prompt précis, testable et aligné avec la dette UX restante du lot 36-bis.  
Le seul point difficile est l’exigence “diff complet réel + sorties complètes” qui rend le rapport très volumineux ; mais cela force une traçabilité forte et évite les claims non prouvés.

## 21. Conclusion

Le lot 37 est implémenté sur le périmètre demandé: état dirty projet explicite, signal persistant visible, topbar non ambiguë, nettoyage après sauvegarde projet réussie, et preuves automatisées.  
Aucun changement runtime/map_core/format JSON/modèle `ProjectManifest` n’a été introduit.

## Checklist finale

- [x] Audit initial réalisé.
- [x] AGENTS.md et agent_rules.md lus.
- [x] Aucun faux test.
- [x] Aucun provider inventé.
- [x] Aucun repository/service ajouté.
- [x] Aucun map_core modifié.
- [x] Aucun runtime modifié.
- [x] Aucun format JSON modifié.
- [x] Aucun generated file.
- [x] Aucun build_runner.
- [x] Dirty state projet audité.
- [x] isProjectDirty ajouté ou équivalent documenté.
- [x] applyInMemoryProjectManifest marque le projet dirty.
- [x] saveProjectManifest réussi nettoie le dirty projet.
- [x] saveProjectManifest échoué conserve le dirty projet.
- [x] chargement/reload projet initialise dirty à false.
- [x] Topbar Save Project reflète le dirty projet.
- [x] Status bar ou signal visible affiche les modifications projet non sauvegardées.
- [x] Path Studio n’utilise pas “Enregistrer” pour l’action mémoire.
- [x] Path Studio signale clairement que la modification est en mémoire.
- [x] Test apply → dirty → Save Project → clean ajouté.
- [x] Test project.json deep_water conserve les frames après save disque.
- [x] Tests ciblés passent.
- [ ] Analyze ciblé passe. (bloqué par issues préexistantes hors scope)
- [x] Rapport final complet créé.
- [x] Auto-review faite.
- [x] Critique du prompt faite.
