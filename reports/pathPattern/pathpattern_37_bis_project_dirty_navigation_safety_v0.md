# Lot PathPattern-37-bis — Project Dirty State Navigation Safety V0

## 1. Résumé exécutif

Le risque était réel: `openMapDocument(...)` remettait `isProjectDirty` à `false`, ce qui pouvait éteindre le signal “projet non sauvegardé” après un simple changement de map, sans écriture de `project.json`.  
La correction V0 retire ce reset dans `openMapDocument` et conserve les resets sur les vraies transitions disque (`loadProject` via `openProjectSession`, `saveProjectManifest` succès).  
Un test RED->GREEN prouve le scénario demandé: `apply -> dirty -> open map -> still dirty -> save project -> clean`.

## 2. Audit initial

Fichiers de règles relus avant modification:

- `AGENTS.md`
- `agent_rules.md`

Commande d’audit initial exécutée:

```bash
pwd
git status --short --untracked-files=all
git diff --stat
git diff --name-status
git ls-files reports/pathPattern/pathpattern_37_project_dirty_save_pending_ux_v0.md
```

Sortie exacte observée:

```text
/Users/karim/Project/pokemonProject
reports/pathPattern/pathpattern_37_project_dirty_save_pending_ux_v0.md
```

## 3. Méthodes qui nettoyaient isProjectDirty

Constat d’audit:

- `ProjectSessionController.openProjectSession(...)` faisait `copyWith(isProjectDirty: false)` (attendu pour un chargement projet disque).
- `ProjectSessionController.openMapDocument(...)` faisait aussi `copyWith(isProjectDirty: false)` (suspect).
- `EditorNotifier.saveProjectManifest()` succès fait `isProjectDirty: false` (attendu).
- `EditorNotifier.loadProject()` passe par `openProjectSession(...)` (attendu).

Réponses aux questions d’audit:

1. **Quelles méthodes remettaient `isProjectDirty` à false ?**  
   `openProjectSession`, `openMapDocument`, `saveProjectManifest` (succès).
2. **`openMapDocument` recharge-t-il le projet disque ?**  
   Non. Il change le document map actif et l’état de sélection/historique, sans relire `project.json`.
3. **`openMapDocument` doit-il nettoyer `isProjectDirty` ?**  
   Non.
4. **Un changement de map pouvait-il cacher le signal ?**  
   Oui, via le reset dans `openMapDocument`.
5. **Transition à corriger ?**  
   Retirer le reset `isProjectDirty` dans `openMapDocument` uniquement.
6. **`editor_state.freezed.dart` a-t-il été modifié au lot 37 ?**  
   Oui (cf rapport lot 37 et historique de travail local).
7. **Cohérence avec `editor_state.dart` ?**  
   Oui: ajout de `isProjectDirty` dans `editor_state.dart` implique la mise à jour Freezed générée.
8. **Faut-il toucher au generated dans ce lot ?**  
   Non, aucune évolution de modèle `EditorState` dans 37-bis.

## 4. Décision sur openMapDocument

Décision retenue:

- **Conserver** `isProjectDirty=false` pour `openProjectSession` (chargement projet disque).
- **Supprimer** le reset dans `openMapDocument` (navigation map non disque).

## 5. Correction appliquée

Fichier corrigé:

- `packages/map_editor/lib/src/features/editor/application/project_session_controller.dart`

Changement:

- suppression de `.copyWith(isProjectDirty: false)` à la fin de `openMapDocument(...)`.
- aucun autre changement de transition dirty/clean.

## 6. Clarification generated / editor_state.freezed.dart

Clarification factuelle:

- `editor_state.freezed.dart` est un fichier generated.
- il a été modifié au lot 37 car `EditorState` a changé (`isProjectDirty`).
- ce lot 37-bis **n’a pas modifié** `editor_state.dart` ni `editor_state.freezed.dart`.
- aucun `build_runner` n’a été lancé dans 37-bis.
- la contradiction du rapport lot 37 (“aucun generated file” vs modification de `editor_state.freezed.dart`) est réelle; ici elle est explicitement corrigée dans le reporting.

## 7. Tests ajoutés/modifiés

### Modifiés

- `packages/map_editor/test/editor_notifier_project_dirty_state_test.dart`
  - ajout du test réel:
    - `apply -> project dirty -> open map -> still dirty -> save project -> clean`
- `packages/map_editor/test/editor_project_session_controller_test.dart`
  - assertion explicite:
    - `openProjectSession` nettoie `isProjectDirty`
    - `openMapDocument` conserve `isProjectDirty` si déjà `true`

### Aucun nouveau provider/service/repository

- respecté.

## 8. Tests exécutés

### map_editor

```bash
flutter test test/editor_notifier_project_dirty_state_test.dart --reporter expanded
flutter test test/path_pattern/path_pattern_deep_water_persistence_bug_test.dart --reporter expanded
flutter test test/top_toolbar_test.dart --reporter expanded
flutter test test/status_bar_test.dart --reporter expanded
flutter test test/editor_shell_page_smoke_test.dart --reporter expanded
flutter test test/editor_selectors_test.dart --reporter expanded
flutter test test/path_pattern/ --reporter expanded
flutter analyze lib/src/features/editor lib/src/ui/shared lib/src/features/path_studio lib/src/features/path_pattern test/path_pattern
flutter analyze lib/src/features/editor/application/project_session_controller.dart lib/src/features/editor/state/editor_notifier.dart lib/src/features/editor/state/editor_state.dart lib/src/features/editor/state/models/editor_state_groups.dart lib/src/ui/shared/status_bar.dart lib/src/ui/shared/top_toolbar.dart test/editor_notifier_project_dirty_state_test.dart test/status_bar_test.dart test/top_toolbar_test.dart
flutter test test/editor_project_session_controller_test.dart --reporter expanded
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

## 9. Résultats des validations

- `editor_notifier_project_dirty_state_test.dart`: **PASS**
- `path_pattern_deep_water_persistence_bug_test.dart`: **PASS**
- `top_toolbar_test.dart`: **PASS**
- `status_bar_test.dart`: **PASS**
- `editor_shell_page_smoke_test.dart`: **PASS**
- `editor_selectors_test.dart`: **PASS**
- `test/path_pattern/`: **PASS** (`00:11 +168: All tests passed!`)
- `editor_project_session_controller_test.dart`: **PASS**
- `flutter analyze` large ciblé: **FAIL** (1 info hors lot, préexistant)
- `flutter analyze` borné fichiers modifiés: **PASS**
- `map_core` tests/analyze: **PASS**
- `map_runtime` tests: **PASS**

## 10. Fichiers créés

- `reports/pathPattern/pathpattern_37_bis_project_dirty_navigation_safety_v0.md`

## 11. Fichiers modifiés

- `packages/map_editor/lib/src/features/editor/application/project_session_controller.dart`
- `packages/map_editor/test/editor_notifier_project_dirty_state_test.dart`
- `packages/map_editor/test/editor_project_session_controller_test.dart`

## 12. Fichiers supprimés

- Aucun.

## 13. git status final

```text
 M packages/map_editor/lib/src/features/editor/application/project_session_controller.dart
 M packages/map_editor/test/editor_notifier_project_dirty_state_test.dart
 M packages/map_editor/test/editor_project_session_controller_test.dart
?? reports/pathPattern/pathpattern_37_bis_project_dirty_navigation_safety_v0.md
```

## 14. git diff --stat

```text
 .../application/project_session_controller.dart    |  3 +-
 .../editor_notifier_project_dirty_state_test.dart  | 56 ++++++++++++++++++++++
 .../editor_project_session_controller_test.dart    | 25 ++++++----
 3 files changed, 74 insertions(+), 10 deletions(-)
```

## 15. git diff --name-status

```text
M	packages/map_editor/lib/src/features/editor/application/project_session_controller.dart
M	packages/map_editor/test/editor_notifier_project_dirty_state_test.dart
M	packages/map_editor/test/editor_project_session_controller_test.dart
```

## 16. Evidence Pack

### 16.1 git status initial

```text
/Users/karim/Project/pokemonProject
reports/pathPattern/pathpattern_37_project_dirty_save_pending_ux_v0.md
```

### 16.2 git status final

```text
 M packages/map_editor/lib/src/features/editor/application/project_session_controller.dart
 M packages/map_editor/test/editor_notifier_project_dirty_state_test.dart
 M packages/map_editor/test/editor_project_session_controller_test.dart
?? reports/pathPattern/pathpattern_37_bis_project_dirty_navigation_safety_v0.md
```

### 16.3 git diff --stat final

```text
 .../application/project_session_controller.dart    |  3 +-
 .../editor_notifier_project_dirty_state_test.dart  | 56 ++++++++++++++++++++++
 .../editor_project_session_controller_test.dart    | 25 ++++++----
 3 files changed, 74 insertions(+), 10 deletions(-)
```

### 16.4 git diff --name-status final

```text
M	packages/map_editor/lib/src/features/editor/application/project_session_controller.dart
M	packages/map_editor/test/editor_notifier_project_dirty_state_test.dart
M	packages/map_editor/test/editor_project_session_controller_test.dart
```

### 16.5 Diff complet réel des fichiers modifiés

```diff
diff --git a/packages/map_editor/lib/src/features/editor/application/project_session_controller.dart b/packages/map_editor/lib/src/features/editor/application/project_session_controller.dart
index 24b15f32..87a2645d 100644
--- a/packages/map_editor/lib/src/features/editor/application/project_session_controller.dart
+++ b/packages/map_editor/lib/src/features/editor/application/project_session_controller.dart
@@ -123,8 +123,7 @@ class ProjectSessionController {
             statusMessage: statusMessage,
             errorMessage: null,
           ),
-        )
-        .copyWith(isProjectDirty: false);
+        );
   }
```

```diff
diff --git a/packages/map_editor/test/editor_notifier_project_dirty_state_test.dart b/packages/map_editor/test/editor_notifier_project_dirty_state_test.dart
index 98753661..369c2fa1 100644
--- a/packages/map_editor/test/editor_notifier_project_dirty_state_test.dart
+++ b/packages/map_editor/test/editor_notifier_project_dirty_state_test.dart
@@ -78,6 +78,36 @@ void main() {
 
       expect(notifier.state.isProjectDirty, isFalse);
     });
+
+    test(
+        'apply -> project dirty -> open map -> still dirty -> save project -> clean',
+        () async {
+      final tempDir =
+          await Directory.systemTemp.createTemp('project_dirty_open_map_');
+      addTearDown(() async => tempDir.delete(recursive: true));
+      final manifestPath = '${tempDir.path}/project.json';
+      final mapsDir = Directory('${tempDir.path}/maps');
+      await mapsDir.create(recursive: true);
+      await File('${mapsDir.path}/town.json')
+          .writeAsString(jsonEncode(_mapData(id: 'town').toJson()));
+      await File(manifestPath)
+          .writeAsString(jsonEncode(_manifestWithMap().toJson()));
+
+      final container = ProviderContainer();
+      addTearDown(container.dispose);
+      final notifier = container.read(editorNotifierProvider.notifier);
+
+      await notifier.loadProject(manifestPath);
+      notifier.applyInMemoryProjectManifest(_manifestWithMap(name: 'Dirty'));
+      expect(notifier.state.isProjectDirty, isTrue);
+
+      await notifier.loadMap('maps/town.json');
+      expect(notifier.state.isProjectDirty, isTrue);
+
+      final saved = await notifier.saveProjectManifest();
+      expect(saved, isTrue);
+      expect(notifier.state.isProjectDirty, isFalse);
+    });
   });
 }
@@ -91,3 +121,29 @@ ProjectManifest _manifest({String name = 'Demo'}) {
     surfaceCatalog: ProjectSurfaceCatalog(),
   );
 }
+
+ProjectManifest _manifestWithMap({String name = 'Demo'}) {
+  return ProjectManifest(
+    name: name,
+    maps: const [
+      ProjectMapEntry(
+        id: 'town',
+        name: 'Town',
+        relativePath: 'maps/town.json',
+      ),
+    ],
+    tilesets: const [],
+    pathPresets: const [],
+    pathPatternPresets: const [],
+    surfaceCatalog: ProjectSurfaceCatalog(),
+  );
+}
+
+MapData _mapData({required String id}) {
+  return MapData(
+    id: id,
+    name: 'Town',
+    size: const GridSize(width: 8, height: 8),
+    layers: const [],
+  );
+}
```

```diff
diff --git a/packages/map_editor/test/editor_project_session_controller_test.dart b/packages/map_editor/test/editor_project_session_controller_test.dart
index 54fe9286..b74aa0cd 100644
--- a/packages/map_editor/test/editor_project_session_controller_test.dart
+++ b/packages/map_editor/test/editor_project_session_controller_test.dart
@@ -26,10 +26,12 @@ void main() {
         mapRedoStack: [],
         canUndoMap: true,
         isDirty: true,
+        isProjectDirty: true,
         errorMessage: 'Old error',
       );
 
-      const updated = ProjectManifest(surfaceCatalog: ProjectSurfaceCatalog(), 
+      final updated = ProjectManifest(
+        surfaceCatalog: ProjectSurfaceCatalog(),
         name: 'Demo',
         maps: [],
         tilesets: [],
@@ -37,7 +39,7 @@ void main() {
 
       final next = controller.openProjectSession(
         current: state,
-        session: const ProjectSessionLoadResult(
+        session: ProjectSessionLoadResult(
           projectRootPath: '/tmp/new',
           project: updated,
           presetSelection: TerrainPresetSelection(
@@ -63,6 +65,7 @@ void main() {
       expect(next.selectedTerrainPresetId, 'grass-a');
       expect(next.selectedPathPresetId, 'path-a');
       expect(next.isDirty, isFalse);
+      expect(next.isProjectDirty, isFalse);
       expect(next.errorMessage, isNull);
       expect(next.statusMessage, 'Loaded');
     });
@@ -76,6 +79,7 @@ void main() {
         mapUndoStack: [],
         mapRedoStack: [],
         isDirty: true,
+        isProjectDirty: true,
       );
@@ -118,6 +122,7 @@ void main() {
       expect(next.selectedPathPresetId, 'path-road');
       expect(next.savedMapSnapshot, map);
       expect(next.isDirty, isFalse);
+      expect(next.isProjectDirty, isTrue);
       expect(next.statusMessage, 'Map loaded');
     });
@@ -129,8 +134,9 @@ void main() {
-      const state = EditorState(
-        project: ProjectManifest(surfaceCatalog: ProjectSurfaceCatalog(), 
+      final state = EditorState(
+        project: ProjectManifest(
+          surfaceCatalog: ProjectSurfaceCatalog(),
           name: 'Demo',
@@ -147,7 +153,8 @@ void main() {
-        updatedProject: const ProjectManifest(surfaceCatalog: ProjectSurfaceCatalog(), 
+        updatedProject: ProjectManifest(
+          surfaceCatalog: ProjectSurfaceCatalog(),
           name: 'Demo',
@@ -173,8 +180,9 @@ void main() {
-      const state = EditorState(
-        project: ProjectManifest(surfaceCatalog: ProjectSurfaceCatalog(), 
+      final state = EditorState(
+        project: ProjectManifest(
+          surfaceCatalog: ProjectSurfaceCatalog(),
           name: 'Demo',
@@ -195,7 +203,8 @@ void main() {
-        updatedProject: const ProjectManifest(surfaceCatalog: ProjectSurfaceCatalog(), 
+        updatedProject: ProjectManifest(
+          surfaceCatalog: ProjectSurfaceCatalog(),
           name: 'Demo',
```

### 16.6 Contenu complet des fichiers créés

Fichier créé:

- `reports/pathPattern/pathpattern_37_bis_project_dirty_navigation_safety_v0.md` (ce rapport).

### 16.7 Sorties complètes des tests ciblés principaux

#### `flutter test test/editor_notifier_project_dirty_state_test.dart --reporter expanded`

```text
00:00 +0: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/editor_notifier_project_dirty_state_test.dart
00:00 +0: EditorNotifier project dirty state isProjectDirty vaut false par défaut
00:00 +1: EditorNotifier project dirty state applyInMemoryProjectManifest passe isProjectDirty à true
00:00 +2: EditorNotifier project dirty state saveProjectManifest réussi repasse isProjectDirty à false
EditorNotifier: loadProject(/var/folders/b5/7gsfwzyd449_54n8l40h40gc0000gn/T/project_dirty_ok_G1dQKJ/project.json)
FileProjectRepository: Loading project from /var/folders/b5/7gsfwzyd449_54n8l40h40gc0000gn/T/project_dirty_ok_G1dQKJ/project.json
EditorNotifier: saveProjectManifest()
FileProjectRepository: Validating and saving project to /var/folders/b5/7gsfwzyd449_54n8l40h40gc0000gn/T/project_dirty_ok_G1dQKJ/project.json
00:00 +3: EditorNotifier project dirty state saveProjectManifest échoué conserve isProjectDirty à true
00:00 +4: EditorNotifier project dirty state chargement projet initialise isProjectDirty à false
EditorNotifier: loadProject(/var/folders/b5/7gsfwzyd449_54n8l40h40gc0000gn/T/project_dirty_load_bt6hsQ/project.json)
FileProjectRepository: Loading project from /var/folders/b5/7gsfwzyd449_54n8l40h40gc0000gn/T/project_dirty_load_bt6hsQ/project.json
00:00 +5: EditorNotifier project dirty state apply -> project dirty -> open map -> still dirty -> save project -> clean
EditorNotifier: loadProject(/var/folders/b5/7gsfwzyd449_54n8l40h40gc0000gn/T/project_dirty_open_map_rCsOt9/project.json)
FileProjectRepository: Loading project from /var/folders/b5/7gsfwzyd449_54n8l40h40gc0000gn/T/project_dirty_open_map_rCsOt9/project.json
EditorNotifier: loadMap(maps/town.json)
FileMapRepository: Loading map from /var/folders/b5/7gsfwzyd449_54n8l40h40gc0000gn/T/project_dirty_open_map_rCsOt9/maps/town.json
EditorNotifier: saveProjectManifest()
FileProjectRepository: Validating and saving project to /var/folders/b5/7gsfwzyd449_54n8l40h40gc0000gn/T/project_dirty_open_map_rCsOt9/project.json
00:00 +6: All tests passed!
```

#### `flutter test test/editor_project_session_controller_test.dart --reporter expanded`

```text
00:00 +0: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/editor_project_session_controller_test.dart
00:00 +0: ProjectSessionController openProjectSession resets document and transient selections
00:00 +1: ProjectSessionController openMapDocument swaps the active document and resets history
00:00 +2: ProjectSessionController afterMapRenamed resets history when the active document changed id
00:00 +3: ProjectSessionController afterMapDeleted clears the active document when it was selected
00:00 +4: All tests passed!
```

#### `flutter test test/path_pattern/path_pattern_deep_water_persistence_bug_test.dart --reporter expanded`

```text
00:00 +0: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/path_pattern/path_pattern_deep_water_persistence_bug_test.dart
00:00 +0: PathPattern deep_water persistence bugfix fixture deep_water statique documente une frame par cellule
00:00 +1: PathPattern deep_water persistence bugfix create flow conserve deep_water multi-frame jusqu au JSON roundtrip
00:00 +2: PathPattern deep_water persistence bugfix edit flow part de statique et persiste deep_water multi-frame
00:00 +3: PathPattern deep_water persistence bugfix saveProjectManifest serialize le manifest courant en memoire
EditorNotifier: loadProject(/var/folders/b5/7gsfwzyd449_54n8l40h40gc0000gn/T/deep_water_persistence_dV4z2p/project.json)
FileProjectRepository: Loading project from /var/folders/b5/7gsfwzyd449_54n8l40h40gc0000gn/T/deep_water_persistence_dV4z2p/project.json
EditorNotifier: saveProjectManifest()
FileProjectRepository: Validating and saving project to /var/folders/b5/7gsfwzyd449_54n8l40h40gc0000gn/T/deep_water_persistence_dV4z2p/project.json
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
00:01 +7: All tests passed!
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
00:02 +6: EditorShellPage smoke renders shell chrome with an error state already present
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
00:11 +168: All tests passed!
```

#### `flutter analyze ...` (large ciblé)

```text
Analyzing 5 items...
info • 'appBackgroundGradient' is deprecated and shouldn't be used. Use appRootDecoration; dark theme is solid • lib/src/ui/shared/cupertino_editor_widgets.dart:126:7 • deprecated_member_use_from_same_package
1 issue found. (ran in 2.5s)
```

#### `flutter analyze ...` (borné fichiers modifiés)

```text
Analyzing 9 items...
No issues found! (ran in 1.8s)
```

#### `map_core`

```text
00:00 +3: All tests passed!
00:00 +2: All tests passed!
Analyzing models, operations, project_manifest_path_pattern_save_reload_test.dart...
No issues found!
```

#### `map_runtime`

```text
00:00 +1: All tests passed!
00:00 +1: All tests passed!
```

### 16.8 Preuve du scénario apply -> dirty -> open map -> still dirty -> save -> clean

La preuve est le test:

- `EditorNotifier project dirty state apply -> project dirty -> open map -> still dirty -> save project -> clean`

et ses logs:

```text
EditorNotifier: loadMap(maps/town.json)
FileMapRepository: Loading map from .../maps/town.json
EditorNotifier: saveProjectManifest()
FileProjectRepository: Validating and saving project to .../project.json
00:00 +6: All tests passed!
```

### 16.9 Clarification explicite editor_state.freezed.dart

`editor_state.freezed.dart` n’est pas touché dans 37-bis.  
Sa modification appartient au lot 37 (ajout `isProjectDirty` dans `EditorState`), et cette dépendance generated est normale.

## 17. Auto-review

Ce qui est prouvé:

- le reset dangereux était dans `openMapDocument`;
- il est supprimé;
- `openProjectSession` continue de nettoyer `isProjectDirty`;
- scénario critique navigation + sauvegarde prouvé en test réel notifier;
- non-régressions demandées exécutées.

Ce qui n’est pas prouvé:

- rien de plus que le scope lot (pas d’élargissement UI/navigation hors flux couvert).

## 18. Critique du Lot 37

Le lot 37 a correctement introduit `isProjectDirty` et le signal UX.  
La faiblesse était la transition `openMapDocument -> isProjectDirty=false`, qui confondait navigation map et rechargement projet disque.  
La contradiction de reporting sur les generated (`editor_state.freezed.dart`) est aussi un point à corriger explicitement, fait dans ce lot.

## 19. Conclusion

Le lot 37-bis corrige le point de sécurité navigation: changer/ouvrir une map ne peut plus éteindre le voyant “projet non sauvegardé”.  
Seuls `loadProject` (rechargement disque) et `saveProjectManifest` réussi nettoient l’état projet dirty.

## Checklist finale

- [x] Audit initial réalisé.
- [x] AGENTS.md et agent_rules.md lus.
- [x] Aucun faux test.
- [x] Aucun provider inventé.
- [x] Aucun repository/service ajouté.
- [x] Aucun map_core modifié.
- [x] Aucun runtime modifié.
- [x] Aucun format JSON modifié.
- [x] Aucun build_runner lancé sauf justification explicite.
- [x] openMapDocument audité.
- [x] Les méthodes qui nettoient isProjectDirty sont listées.
- [x] openMapDocument ne nettoie pas isProjectDirty sauf preuve de reload disque.
- [x] loadProject/reload projet nettoie isProjectDirty.
- [x] saveProjectManifest succès nettoie isProjectDirty.
- [x] saveProjectManifest échec conserve isProjectDirty.
- [x] Test apply → dirty → open map → still dirty ajouté.
- [x] Test save project → clean conservé.
- [x] Signal UI projet non sauvegardé non régressé.
- [x] editor_state.freezed.dart clarifié honnêtement dans le rapport.
- [x] Tests ciblés passent.
- [x] Analyze borné aux fichiers modifiés passe ou échec documenté précisément.
- [x] Rapport final complet créé.
- [x] Auto-review faite.
