# Lot PathPattern-36 — Deep Water Center Animation Persistence Bugfix V0

## 1. Résumé exécutif

Le bug réel ne venait pas de la chaîne `draft -> build request -> manifest` (les frames multi-cellules sont bien conservées), mais du flux de sauvegarde utilisateur: en Path Studio, le bouton/shortcut de sauvegarde pointait le flux map (`saveActiveMap`) au lieu du flux projet (`saveProjectManifest`), donc `project.json` restait statique.

Correction minimale appliquée:
- En workspace Path Studio (et non-map), le bouton save toolbar déclenche `saveProjectManifest`.
- Le shortcut `Cmd/Ctrl+S` dans le shell déclenche aussi `saveProjectManifest` hors workspace map.

## 2. Audit initial

Commandes d’audit exécutées:

```bash
pwd
git status --short --untracked-files=all
git diff --stat
git diff --name-status
git ls-files agent_rules.md
git ls-files reports/pathPattern/pathpattern_35_animated_water_golden_slice_v0.md
```

Constat initial (`git status --short --untracked-files=all`):

```text
?? packages/map_core/test/path_pattern_water_animated_golden_slice_test.dart
?? packages/map_editor/test/path_pattern/path_pattern_water_animated_editor_golden_slice_test.dart
?? packages/map_runtime/test/path_pattern_water_animated_runtime_golden_slice_test.dart
?? reports/pathPattern/pathpattern_35_animated_water_golden_slice_v0.md
```

## 3. Analyse du JSON réel deep_water

Fixture minimale créée pour documenter l’état observé:
- `packages/map_editor/test/fixtures/path_pattern/deep_water_static_saved_project_fixture.json`

Elle contient:
- tileset `deep_water`,
- base path `nouveau-chemin`,
- pattern `nouveau-chemin-pattern`,
- center 2x2 avec 1 seule frame par cellule (`durationMs: null`).

## 4. Diagnostic racine

Cause racine prouvée: **flux de sauvegarde UI mal branché pour Path Studio**.

- Le draft et les conversions conservent les frames animées.
- Le manifest en mémoire peut contenir les frames animées.
- Mais en Path Studio, l’action save exposée à l’utilisateur n’écrivait pas `project.json`.

Concrètement:
- `TopToolbar` utilisait `saveActiveMap` (map-only).
- `EditorShellPage` (`Cmd/Ctrl+S`) utilisait aussi `saveActiveMap`.
- `saveProjectManifest` existait déjà dans `EditorNotifier`, mais n’était pas utilisé dans ce contexte.

## 5. Maillon fautif identifié

Maillon fautif: **liaison UI save -> mauvais use case en Path Studio**.

Fichiers concernés:
- `packages/map_editor/lib/src/ui/shared/top_toolbar.dart`
- `packages/map_editor/lib/src/ui/editor_shell_page.dart`

## 6. Correction appliquée

1. `TopToolbar`:
- tooltip dynamique: `Save Map` en workspace map, sinon `Save Project`.
- action dynamique:
  - map => `saveActiveMap` (inchangé),
  - hors map => `saveProjectManifest` si projet chargé.

2. `EditorShellPage`:
- shortcut `Cmd/Ctrl+S`:
  - map => `saveActiveMap`,
  - hors map => `saveProjectManifest` si projet chargé.

## 7. Tests ajoutés

Nouveaux fichiers:

1) `packages/map_editor/test/fixtures/path_pattern/deep_water_static_saved_project_fixture.json`
- fixture minimale du cas réel statique.

2) `packages/map_editor/test/path_pattern/path_pattern_deep_water_persistence_bug_test.dart`
- `fixture deep_water statique documente une frame par cellule`
- `create flow conserve deep_water multi-frame jusqu au JSON roundtrip`
- `edit flow part de statique et persiste deep_water multi-frame`
- `saveProjectManifest serialize le manifest courant en memoire`

3) `packages/map_editor/test/top_toolbar_test.dart` (modifié)
- test Path Studio mis à jour:
  - save projet activé,
  - undo/redo map restent désactivés.

## 8. Tests de non-régression

### map_editor

```bash
flutter test test/path_pattern/path_pattern_deep_water_persistence_bug_test.dart --reporter expanded
flutter test test/path_pattern/path_studio_new_path_draft_test.dart --reporter expanded
flutter test test/path_pattern/path_studio_new_path_build_request_test.dart --reporter expanded
flutter test test/path_pattern/path_studio_new_path_save_flow_test.dart --reporter expanded
flutter test test/path_pattern/path_studio_edit_path_save_flow_test.dart --reporter expanded
flutter test test/path_pattern/path_studio_panel_test.dart --reporter expanded
flutter test test/path_pattern/ --reporter expanded
flutter test test/top_toolbar_test.dart --reporter expanded
flutter test test/editor_shell_page_smoke_test.dart --reporter expanded
flutter analyze lib/src/features/path_studio lib/src/features/path_pattern test/path_pattern
```

Résultats:
- Tous les tests ci-dessus passent.
- `flutter analyze ...` passe sans issue.

### map_core

```bash
dart test test/project_manifest_path_pattern_save_reload_test.dart --reporter expanded --no-color
dart test test/path_pattern_water_animated_golden_slice_test.dart --reporter expanded --no-color
dart test test/path_pattern_visual_resolution_test.dart --reporter expanded --no-color
dart analyze lib/src/models lib/src/operations test/project_manifest_path_pattern_save_reload_test.dart
```

Résultats:
- Tous les tests passent.
- `dart analyze ...` sans issue.

### map_runtime

```bash
flutter test test/path_pattern_runtime_reload_regression_test.dart --reporter expanded
flutter test test/path_pattern_runtime_render_resolution_test.dart --reporter expanded
flutter test test/map_layers_component_path_pattern_render_test.dart --reporter expanded
flutter test test/path_pattern_water_animated_runtime_golden_slice_test.dart --reporter expanded
```

Résultats:
- Tous les tests passent.

## 9. Fichiers créés

- `packages/map_editor/test/fixtures/path_pattern/deep_water_static_saved_project_fixture.json`
- `packages/map_editor/test/path_pattern/path_pattern_deep_water_persistence_bug_test.dart`
- `reports/pathPattern/pathpattern_36_deep_water_center_animation_persistence_bugfix_v0.md`

## 10. Fichiers modifiés

- `packages/map_editor/lib/src/ui/shared/top_toolbar.dart`
- `packages/map_editor/lib/src/ui/editor_shell_page.dart`
- `packages/map_editor/test/top_toolbar_test.dart`

## 11. Fichiers supprimés

Aucun.

## 12. Tests exécutés

Voir section 8 (liste exacte des commandes).

## 13. Résultats des validations

- `map_editor`: vert.
- `map_core`: vert.
- `map_runtime`: vert.
- lint/analysis ciblé: vert.

## 14. git status final

```text
 M packages/map_editor/lib/src/ui/editor_shell_page.dart
 M packages/map_editor/lib/src/ui/shared/top_toolbar.dart
 M packages/map_editor/test/top_toolbar_test.dart
?? packages/map_core/test/path_pattern_water_animated_golden_slice_test.dart
?? packages/map_editor/test/fixtures/path_pattern/deep_water_static_saved_project_fixture.json
?? packages/map_editor/test/path_pattern/path_pattern_deep_water_persistence_bug_test.dart
?? packages/map_editor/test/path_pattern/path_pattern_water_animated_editor_golden_slice_test.dart
?? packages/map_runtime/test/path_pattern_water_animated_runtime_golden_slice_test.dart
?? reports/pathPattern/pathpattern_35_animated_water_golden_slice_v0.md
?? reports/pathPattern/pathpattern_36_deep_water_center_animation_persistence_bugfix_v0.md
```

## 15. git diff --stat

```text
 packages/map_editor/lib/src/ui/editor_shell_page.dart  | 10 ++++++++--
 packages/map_editor/lib/src/ui/shared/top_toolbar.dart | 10 ++++++++--
 packages/map_editor/test/top_toolbar_test.dart         |  4 ++--
 3 files changed, 18 insertions(+), 6 deletions(-)
```

## 16. git diff --name-status

```text
M	packages/map_editor/lib/src/ui/editor_shell_page.dart
M	packages/map_editor/lib/src/ui/shared/top_toolbar.dart
M	packages/map_editor/test/top_toolbar_test.dart
```

## 17. Evidence Pack

### a) Réponses aux 10 points de flux demandés

1. Où les frames sont présentes dans le draft local  
   - `PathStudioNewPathDraft.centerCellFrames` (`path_studio_new_path_draft.dart`).

2. Où elles sont converties en `TilesetVisualFrame`  
   - `createPathCenterPatternFromNewPathDraft` convertit `frame.toFrame()` (`path_studio_save_plan.dart`).

3. Où elles entrent dans `ProjectPathPatternPreset.centerPattern`  
   - Dans `createPathStudioNewPathBuildPlan` et `createPathStudioEditPathBuildPlan`.

4. Où elles entrent dans `ProjectManifest.pathPatternPresets`  
   - `applyNewPathBuildRequestToManifest` / `applyPathPatternEditRequestToManifest`.

5. Où le `ProjectManifest` courant est mis à jour en mémoire  
   - `EditorNotifier.applyInMemoryProjectManifest`.

6. Où le projet est marqué dirty  
   - Pas de dirty projet dédié; le `isDirty` actuel est map-centric.

7. Quelle instance de `ProjectManifest` est utilisée par la sauvegarde  
   - `saveProjectManifest` sérialise `state.project`.

8. Si la sauvegarde disque utilise un manifest ancien  
   - Non pour `saveProjectManifest`; test dédié prouve que le manifest courant mémoire est écrit.

9. Si l’édition suit un autre chemin que la création  
   - Oui: `createPathStudioEditPathBuildPlan` + `applyPathPatternEditRequestToManifest` vs flux création `createPathStudioNewPathBuildPlan` + `applyNewPathBuildRequestToManifest`.

10. Si le bouton save projet ignore les modifs PathPattern  
   - Avant fix: oui (save map-only). Après fix: non, save projet branché hors map.

### b) Diff complet réel des fichiers modifiés

```diff
diff --git a/packages/map_editor/lib/src/ui/editor_shell_page.dart b/packages/map_editor/lib/src/ui/editor_shell_page.dart
index 2fd28ff6..6cf795fe 100644
--- a/packages/map_editor/lib/src/ui/editor_shell_page.dart
+++ b/packages/map_editor/lib/src/ui/editor_shell_page.dart
@@ -73,6 +73,7 @@ class _EditorShellPageState extends ConsumerState<EditorShellPage> {
   @override
   Widget build(BuildContext context) {
     final shell = ref.watch(editorShellSnapshotProvider);
+    final project = ref.watch(editorProjectManifestProvider);
     final workspaceMode = shell.workspaceMode;
     final notifier = ref.read(editorNotifierProvider.notifier);
@@ -138,8 +139,13 @@ class _EditorShellPageState extends ConsumerState<EditorShellPage> {
           _SaveIntent: CallbackAction<_SaveIntent>(
             onInvoke: (_) {
               if (_isTextInputFocused()) return null;
-              if (!shell.canSaveMap) return null;
-              notifier.saveActiveMap();
+              if (workspaceMode == EditorWorkspaceMode.map) {
+                if (!shell.canSaveMap) return null;
+                notifier.saveActiveMap();
+                return null;
+              }
+              if (project == null) return null;
+              notifier.saveProjectManifest();
               return null;
             },
           ),
diff --git a/packages/map_editor/lib/src/ui/shared/top_toolbar.dart b/packages/map_editor/lib/src/ui/shared/top_toolbar.dart
index 67a1ddf7..1585683b 100644
--- a/packages/map_editor/lib/src/ui/shared/top_toolbar.dart
+++ b/packages/map_editor/lib/src/ui/shared/top_toolbar.dart
@@ -167,9 +167,15 @@ class TopToolbar extends ConsumerWidget {
           else
             ToolbarCapsuleButton(
               icon: CupertinoIcons.floppy_disk,
-              tooltip: 'Save Map',
+              tooltip: toolbar.workspaceMode == EditorWorkspaceMode.map
+                  ? 'Save Map'
+                  : 'Save Project',
               selected: toolbar.isDirty,
-              onPressed: toolbar.canSaveMap ? notifier.saveActiveMap : null,
+              onPressed: switch (toolbar.workspaceMode) {
+                EditorWorkspaceMode.map =>
+                  toolbar.canSaveMap ? notifier.saveActiveMap : null,
+                _ => toolbar.project != null ? notifier.saveProjectManifest : null,
+              },
             ),
           ToolbarCapsuleButton(
             icon: CupertinoIcons.arrow_uturn_left,
diff --git a/packages/map_editor/test/top_toolbar_test.dart b/packages/map_editor/test/top_toolbar_test.dart
index 9ea36ac6..6e405066 100644
--- a/packages/map_editor/test/top_toolbar_test.dart
+++ b/packages/map_editor/test/top_toolbar_test.dart
@@ -60,7 +60,7 @@ void main() {
       expect(find.text('Pokemon Map  •  Trainer Studio'), findsOneWidget);
     });
 
-    testWidgets('disables map save and history actions in Path Studio',
+    testWidgets('enables project save and disables map history in Path Studio',
         (tester) async {
@@ -84,7 +84,7 @@ void main() {
         );
       }
 
-      expect(buttonWithTooltip('Save Map').onPressed, isNull);
+      expect(buttonWithTooltip('Save Project').onPressed, isNotNull);
       expect(buttonWithTooltip('Undo').onPressed, isNull);
       expect(buttonWithTooltip('Redo').onPressed, isNull);
     });
```

### c) Contenu complet des fichiers créés

#### `packages/map_editor/test/fixtures/path_pattern/deep_water_static_saved_project_fixture.json`

```json
{
  "name": "Deep Water Static Fixture",
  "maps": [],
  "tilesets": [
    {
      "id": "deep_water",
      "name": "Deep Water",
      "relativePath": "assets/tilesets/deep_water.png"
    }
  ],
  "pathPresets": [
    {
      "id": "nouveau-chemin",
      "name": "sea",
      "surfaceKind": "water",
      "tilesetId": "deep_water",
      "variants": []
    }
  ],
  "pathPatternPresets": [
    {
      "id": "nouveau-chemin-pattern",
      "name": "Nouveau chemin",
      "basePathPresetId": "nouveau-chemin",
      "sortOrder": 0,
      "centerPattern": {
        "size": {
          "width": 2,
          "height": 2
        },
        "cells": [
          {
            "localX": 0,
            "localY": 0,
            "frames": [
              {
                "tilesetId": "deep_water",
                "source": { "x": 0, "y": 0, "width": 1, "height": 1 },
                "durationMs": null
              }
            ]
          },
          {
            "localX": 1,
            "localY": 0,
            "frames": [
              {
                "tilesetId": "deep_water",
                "source": { "x": 1, "y": 0, "width": 1, "height": 1 },
                "durationMs": null
              }
            ]
          },
          {
            "localX": 0,
            "localY": 1,
            "frames": [
              {
                "tilesetId": "deep_water",
                "source": { "x": 0, "y": 1, "width": 1, "height": 1 },
                "durationMs": null
              }
            ]
          },
          {
            "localX": 1,
            "localY": 1,
            "frames": [
              {
                "tilesetId": "deep_water",
                "source": { "x": 1, "y": 1, "width": 1, "height": 1 },
                "durationMs": null
              }
            ]
          }
        ]
      }
    }
  ]
}
```

#### `packages/map_editor/test/path_pattern/path_pattern_deep_water_persistence_bug_test.dart`

Contenu complet: fichier ajouté tel que présent dans le repo (test fixture statique, flux create/edit, save notifier réel, assertions deep_water 2x2 A/B/C/D et durées 200 ms).

#### `reports/pathPattern/pathpattern_36_deep_water_center_animation_persistence_bugfix_v0.md`

Ce rapport.

### d) Sorties de tests ciblés principaux (extraits finaux exacts)

- `path_pattern_deep_water_persistence_bug_test.dart`
  - fin: `All tests passed!`
- `test/path_pattern/` (map_editor)
  - fin: `All tests passed!`
- `map_core` ciblé
  - fin tests: `All tests passed!`
  - analyze: `No issues found!`
- `map_runtime` ciblé
  - fin: `All tests passed!`
- `map_editor analyze` ciblé
  - fin: `No issues found!`

## 18. Auto-review

- Ce qui est prouvé:
  - Le flux draft/build/edit conserve les frames deep_water multi-frame.
  - Le save projet sérialise le manifest mémoire courant.
  - Le branchement save Path Studio utilisait le mauvais flux UI avant fix.
  - La correction est minimale et localisée à l’UI save wiring.
- Ce qui n’est pas changé volontairement:
  - Aucun changement `map_core` production.
  - Aucun changement runtime production.
  - Aucun changement de format JSON.
  - Aucun nouveau repository/service/provider.

## 19. Critique du prompt

Le prompt était très prescriptif et globalement exact pour forcer l’enquête “tuyau réel”.  
Point de friction mineur: certains chemins UI listés dans le prompt ne correspondent plus exactement à l’arborescence actuelle (`ui/shared/top_toolbar.dart`, `ui/editor_shell_page.dart` sont les points réels).

## 20. Conclusion

Pourquoi le `project.json` réel contenait une seule frame par cellule?

**Parce que les modifications PathPattern étaient bien en mémoire, mais le save utilisateur en Path Studio écrivait la map active (ou rien en Path Studio) au lieu d’écrire le manifest projet (`project.json`).**  

Après correction, le save en Path Studio utilise `saveProjectManifest`, et les frames animées deep_water sont persistées dans `project.json`.

---

## Checklist finale

- [x] Audit initial réalisé.
- [x] AGENTS.md et agent_rules.md lus.
- [x] JSON réel deep_water analysé.
- [x] Cause racine identifiée.
- [x] Aucun faux test.
- [x] Aucun provider inventé.
- [x] Aucun repository/service ajouté.
- [x] Aucun save disque applicatif ajouté.
- [x] Aucun FileProjectRepository ajouté.
- [x] Aucun map_core modifié sauf bug prouvé.
- [x] Aucun runtime modifié sauf bug prouvé.
- [x] Aucun format JSON modifié.
- [x] Aucun generated file.
- [x] Aucun build_runner.
- [x] Les frames multi-cellules deep_water sont conservées dans le draft.
- [x] Les frames deep_water sont conservées dans la build request.
- [x] Les frames deep_water sont conservées dans le manifest mémoire.
- [x] Les frames deep_water sont conservées dans JSON roundtrip.
- [x] Le flux création est couvert.
- [x] Le flux édition est couvert.
- [x] Le state/save project utilise le manifest courant ou le bug est documenté.
- [x] Les durationMs sont conservées.
- [x] Les source x/y sont conservées.
- [x] Les tilesetId deep_water sont conservés.
- [x] Aucun hardcode deep_water en production.
- [x] Rendu éditeur/runtime existant reste vert.
- [x] Tests ciblés passent.
- [x] Analyze ciblé passe.
- [x] Rapport final complet créé.
- [x] Auto-review faite.
- [x] Critique du prompt faite.
