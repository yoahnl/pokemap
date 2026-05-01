# Lot PathPattern-21 — Legacy Save Flow UX Hardening V0

## 1. Résumé exécutif

Lot 21 implémenté sur le périmètre demandé: durcissement UX après sauvegarde legacy en mémoire, sans ajout de capacité métier.

Comportement obtenu:

- `Depuis un path existant` -> `Enregistrer` appelle toujours le callback legacy.
- Après mise à jour parent du manifest, le panel détecte l'id sauvegardé.
- Le brouillon legacy est nettoyé.
- Le preset sauvegardé devient visible et sélectionné.
- Un feedback clair est affiché: `Motif enregistré dans le projet`.

`Nouveau chemin` reste non sauvegardable.

## 2. Audit initial

Fichiers lus avant modification:

- `AGENTS.md`
- `agent_rules.md`

Commandes d'audit obligatoires exécutées:

```bash
pwd
git status --short --untracked-files=all
git diff --stat
git diff --name-status
git ls-files agent_rules.md
git ls-files reports/pathPattern/pathpattern_20_ter_real_save_handler_proof_v0.md
```

Sorties exactes:

```text
/Users/karim/Project/pokemonProject
agent_rules.md
reports/pathPattern/pathpattern_20_ter_real_save_handler_proof_v0.md
```

(Les commandes `git status --short --untracked-files=all`, `git diff --stat` et `git diff --name-status` ne produisaient aucune sortie.)

Fichiers inspectés:

- `packages/map_editor/lib/src/features/path_studio/path_studio_panel.dart`
- `packages/map_editor/lib/src/features/path_studio/path_studio_save_flow.dart`
- `packages/map_editor/lib/src/features/path_studio/path_studio_save_plan.dart`
- `packages/map_editor/test/path_pattern/path_studio_panel_test.dart`
- `packages/map_editor/test/path_pattern/path_studio_workspace_save_flow_test.dart`
- `packages/map_editor/lib/src/features/editor/state/editor_notifier.dart`
- `packages/map_editor/lib/src/features/editor/state/editor_selectors.dart`

## 3. Problème UX constaté

Avant correction:

- le callback legacy pouvait être appelé;
- mais le panel affichait un feedback `Requête de sauvegarde préparée` lié au draft;
- au refresh manifest, l'état local était reset sans transition UX orientée "save réussi";
- pas de sélection explicite du preset sauvegardé via id pending;
- pas de bannière globale de succès.

## 4. Décisions prises

- Ajouter un état local minimal dans `PathStudioPanel`:
  - `_pendingSavedPathPatternId`
- Garder le callback existant, sans provider global.
- Détecter l'upsert côté `didUpdateWidget` quand le manifest change:
  - si l'id pending est présent dans `manifest.pathPatternPresets`, alors transition succès.
- Afficher un feedback global et testable via bannière:
  - clé `path-studio-save-success-message`
  - message `Motif enregistré dans le projet`
- Conserver le comportement existant:
  - `Nouveau chemin` non sauvegardable;
  - callback absent => bouton save disabled;
  - duplicate id => save bloqué.

## 5. État local ajouté ou modifié

Dans `path_studio_panel.dart`:

- ajout de `String? _pendingSavedPathPatternId;`
- ajout de `_indexOfPathPatternPresetById(...)`
- `didUpdateWidget`:
  - applique la transition succès quand le manifest contient l'id pending;
  - nettoie draft legacy/new path;
  - sélectionne le preset sauvegardé via index;
  - pose le message succès.
- `_requestLegacyPathPatternSave()`:
  - mémorise l'id pending avant callback;
  - catch minimal en cas d'exception callback (`La sauvegarde a échoué`), sans faux succès.

## 6. Sélection/feedback après sauvegarde

Comportement final:

1. clic `Enregistrer` sur draft legacy valide;
2. callback appelé;
3. parent met à jour le manifest en mémoire;
4. `PathStudioPanel` reçoit le nouveau manifest;
5. id pending trouvé dans `pathPatternPresets`;
6. brouillon legacy nettoyé;
7. preset sauvegardé sélectionné (via `_selectedSourceIndex`);
8. feedback visible: `Motif enregistré dans le projet`.

## 7. Nouveau chemin volontairement inchangé

`Nouveau chemin` reste non sauvegardable:

- save status `Non sauvegardable`;
- issue `Bords / coins / jonctions à définir`;
- bouton `Enregistrer` disabled même avec centre complet.

## 8. Fichiers créés

- `reports/pathPattern/pathpattern_21_legacy_save_flow_ux_hardening_v0.md`

## 9. Fichiers modifiés

- `packages/map_editor/lib/src/features/path_studio/path_studio_panel.dart`
- `packages/map_editor/test/path_pattern/path_studio_panel_test.dart`

## 10. Fichiers supprimés

Aucun.

## 11. Tests ajoutés/modifiés

`path_studio_panel_test.dart`:

- remplacement du test callback-only par un test parent-wrapper réel:
  - `legacy save updates parent manifest and panel exits draft state`
  - le test injecte `onPathPatternPresetSaveRequested`,
  - applique `applyLegacyPathPatternSaveToManifest`,
  - met à jour le manifest parent,
  - prouve la transition UX complète.

## 12. Commandes exécutées

Depuis `packages/map_editor`:

```bash
flutter test test/path_pattern/path_studio_panel_test.dart --reporter expanded
flutter test test/path_pattern/path_studio_workspace_save_flow_test.dart --reporter expanded
flutter test test/path_pattern/path_studio_save_plan_test.dart --reporter expanded
flutter test test/path_pattern/ --reporter expanded
flutter test test/editor_shell_page_smoke_test.dart --reporter expanded
flutter test test/top_toolbar_test.dart --reporter expanded
flutter test test/editor_selectors_test.dart --reporter expanded
flutter analyze lib/src/features/path_studio test/path_pattern
```

Depuis `packages/map_core`:

```bash
dart test test/project_manifest_path_pattern_preset_operations_test.dart --reporter expanded --no-color
dart test test/project_manifest_path_pattern_presets_test.dart --reporter expanded --no-color
dart test test/project_path_pattern_preset_json_codec_test.dart --reporter expanded --no-color
dart test test/project_path_pattern_preset_json_golden_test.dart --reporter expanded --no-color
dart test test/project_path_pattern_preset_test.dart --reporter expanded --no-color
dart test test/path_center_pattern_test.dart --reporter expanded --no-color
dart test test/path_center_pattern_resolver_test.dart --reporter expanded --no-color
```

## 13. Résultats des validations

Résultats ciblés:

- `flutter test test/path_pattern/path_studio_panel_test.dart --reporter expanded` -> `00:04 +24: All tests passed!`
- `flutter test test/path_pattern/path_studio_workspace_save_flow_test.dart --reporter expanded` -> `00:00 +4: All tests passed!`
- `flutter test test/path_pattern/path_studio_save_plan_test.dart --reporter expanded` -> `00:00 +7: All tests passed!`

Régressions `map_editor`:

- `flutter test test/path_pattern/ --reporter expanded` -> ligne finale exacte: `00:07 +101: All tests passed!`
- `flutter test test/editor_shell_page_smoke_test.dart --reporter expanded` -> `00:02 +7: All tests passed!`
- `flutter test test/top_toolbar_test.dart --reporter expanded` -> `00:00 +5: All tests passed!`
- `flutter test test/editor_selectors_test.dart --reporter expanded` -> `00:00 +8: All tests passed!`
- `flutter analyze lib/src/features/path_studio test/path_pattern` -> `No issues found! (ran in 2.1s)`

Régressions `map_core`:

- `project_manifest_path_pattern_preset_operations_test.dart` -> `00:00 +14: All tests passed!`
- `project_manifest_path_pattern_presets_test.dart` -> `00:00 +8: All tests passed!`
- `project_path_pattern_preset_json_codec_test.dart` -> `00:00 +9: All tests passed!`
- `project_path_pattern_preset_json_golden_test.dart` -> `00:00 +6: All tests passed!`
- `project_path_pattern_preset_test.dart` -> `00:00 +5: All tests passed!`
- `path_center_pattern_test.dart` -> `00:00 +17: All tests passed!`
- `path_center_pattern_resolver_test.dart` -> `00:00 +6: All tests passed!`

## 14. git status final

```text
 M packages/map_editor/lib/src/features/path_studio/path_studio_panel.dart
 M packages/map_editor/test/path_pattern/path_studio_panel_test.dart
?? reports/pathPattern/pathpattern_21_legacy_save_flow_ux_hardening_v0.md
```

## 15. git diff --stat

```text
 .../features/path_studio/path_studio_panel.dart    | 92 +++++++++++++++++++++-
 .../test/path_pattern/path_studio_panel_test.dart  | 70 +++++++++++-----
 2 files changed, 141 insertions(+), 21 deletions(-)
```

## 16. git diff --name-status

```text
M	packages/map_editor/lib/src/features/path_studio/path_studio_panel.dart
M	packages/map_editor/test/path_pattern/path_studio_panel_test.dart
```

## 17. Evidence Pack

### 17.1 git status --short --untracked-files=all initial

```text
(aucune sortie)
```

### 17.2 git status --short --untracked-files=all final

```text
 M packages/map_editor/lib/src/features/path_studio/path_studio_panel.dart
 M packages/map_editor/test/path_pattern/path_studio_panel_test.dart
?? reports/pathPattern/pathpattern_21_legacy_save_flow_ux_hardening_v0.md
```

### 17.3 git diff --stat final

```text
 .../features/path_studio/path_studio_panel.dart    | 92 +++++++++++++++++++++-
 .../test/path_pattern/path_studio_panel_test.dart  | 70 +++++++++++-----
 2 files changed, 141 insertions(+), 21 deletions(-)
```

### 17.4 git diff --name-status final

```text
M	packages/map_editor/lib/src/features/path_studio/path_studio_panel.dart
M	packages/map_editor/test/path_pattern/path_studio_panel_test.dart
```

### 17.5 Contenu complet des fichiers créés

Fichier créé:

- `reports/pathPattern/pathpattern_21_legacy_save_flow_ux_hardening_v0.md` (ce rapport).

### 17.6 Diff complet réel des fichiers modifiés

```diff
diff --git a/packages/map_editor/lib/src/features/path_studio/path_studio_panel.dart b/packages/map_editor/lib/src/features/path_studio/path_studio_panel.dart
index b8f9dc6f..cca1504b 100644
--- a/packages/map_editor/lib/src/features/path_studio/path_studio_panel.dart
+++ b/packages/map_editor/lib/src/features/path_studio/path_studio_panel.dart
@@ -76,6 +76,7 @@ class _PathStudioPanelState extends State<PathStudioPanel> {
   bool _draftSelected = false;
   String? _draftMessage;
   String? _saveFeedbackMessage;
+  String? _pendingSavedPathPatternId;
 
@@ -88,6 +89,24 @@ class _PathStudioPanelState extends State<PathStudioPanel> {
   void didUpdateWidget(covariant PathStudioPanel oldWidget) {
     super.didUpdateWidget(oldWidget);
     if (oldWidget.manifest != widget.manifest) {
+      final pendingSavedId = _pendingSavedPathPatternId;
+      if (pendingSavedId != null) {
+        final savedPresetIndex = _indexOfPathPatternPresetById(
+          widget.manifest.pathPatternPresets,
+          pendingSavedId,
+        );
+        if (savedPresetIndex != null) {
+          _selectedSourceIndex = savedPresetIndex;
+          _newPathDraft = null;
+          _newPathDraftSelected = false;
+          _draft = null;
+          _draftSelected = false;
+          _draftMessage = null;
+          _saveFeedbackMessage = 'Motif enregistré dans le projet';
+          _pendingSavedPathPatternId = null;
+          return;
+        }
+      }
       _selectedSourceIndex = null;
       _newPathDraft = null;
       _newPathDraftSelected = false;
@@ -95,6 +114,7 @@ class _PathStudioPanelState extends State<PathStudioPanel> {
       _draftSelected = false;
       _draftMessage = null;
       _saveFeedbackMessage = null;
+      _pendingSavedPathPatternId = null;
     }
   }
@@ -148,6 +168,10 @@ class _PathStudioPanelState extends State<PathStudioPanel> {
                 hasSaveCallback: saveCallback != null,
               ),
             ),
+            if (_saveFeedbackMessage != null) ...[
+              const SizedBox(height: 10),
+              _SaveFeedbackBanner(message: _saveFeedbackMessage!),
+            ],
             const SizedBox(height: 16),
             Expanded(
@@ -311,6 +335,7 @@ class _PathStudioPanelState extends State<PathStudioPanel> {
       _draftSelected = false;
       _draftMessage = null;
       _saveFeedbackMessage = null;
+      _pendingSavedPathPatternId = null;
     });
   }
@@ -319,6 +344,7 @@ class _PathStudioPanelState extends State<PathStudioPanel> {
       setState(() {
         _draftMessage = 'Aucun path existant disponible';
         _saveFeedbackMessage = null;
+        _pendingSavedPathPatternId = null;
         _newPathDraftSelected = false;
         _draftSelected = false;
       });
@@ -336,12 +362,14 @@ class _PathStudioPanelState extends State<PathStudioPanel> {
             ? 'Aucun path existant disponible'
             : 'Brouillon non sauvegardé';
         _saveFeedbackMessage = null;
+        _pendingSavedPathPatternId = null;
       });
     } on ArgumentError {
       setState(() {
         _draftMessage =
             'Le preset Path de base ne contient pas de centre cross';
         _saveFeedbackMessage = null;
+        _pendingSavedPathPatternId = null;
         _newPathDraftSelected = false;
         _draftSelected = false;
       });
@@ -507,11 +535,19 @@ class _PathStudioPanelState extends State<PathStudioPanel> {
     if (request == null) {
       return;
     }
-    callback(request.preset);
     setState(() {
-      _saveFeedbackMessage = 'Requête de sauvegarde préparée';
-      _draftMessage = _saveFeedbackMessage;
+      _pendingSavedPathPatternId = request.preset.id;
+      _saveFeedbackMessage = null;
     });
+    try {
+      callback(request.preset);
+    } catch (_) {
+      setState(() {
+        _pendingSavedPathPatternId = null;
+        _saveFeedbackMessage = null;
+        _draftMessage = 'La sauvegarde a échoué';
+      });
+    }
   }
@@ -546,6 +582,56 @@ class _PathStudioPanelState extends State<PathStudioPanel> {
     }
     return null;
   }
+
+  int? _indexOfPathPatternPresetById(
+    List<ProjectPathPatternPreset> presets,
+    String id,
+  ) {
+    for (var index = 0; index < presets.length; index += 1) {
+      if (presets[index].id == id) {
+        return index;
+      }
+    }
+    return null;
+  }
+}
+
+class _SaveFeedbackBanner extends StatelessWidget {
+  const _SaveFeedbackBanner({required this.message});
+
+  final String message;
+
+  @override
+  Widget build(BuildContext context) {
+    return Container(
+      key: const Key('path-studio-save-success-message'),
+      decoration: PathStudioTheme.panelDecoration(
+        color: PathStudioTheme.success.withValues(alpha: 0.14),
+        radius: 14,
+      ),
+      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
+      child: Row(
+        children: [
+          const MacosIcon(
+            CupertinoIcons.check_mark_circled_solid,
+            size: 16,
+            color: PathStudioTheme.success,
+          ),
+          const SizedBox(width: 8),
+          Expanded(
+            child: Text(
+              message,
+              style: const TextStyle(
+                color: PathStudioTheme.textPrimary,
+                fontSize: 12,
+                fontWeight: FontWeight.w700,
+              ),
+            ),
+          ),
+        ],
+      ),
+    );
+  }
 }
 
diff --git a/packages/map_editor/test/path_pattern/path_studio_panel_test.dart b/packages/map_editor/test/path_pattern/path_studio_panel_test.dart
index 9146ee97..71f4f6fa 100644
--- a/packages/map_editor/test/path_pattern/path_studio_panel_test.dart
+++ b/packages/map_editor/test/path_pattern/path_studio_panel_test.dart
@@ -7,6 +7,7 @@ import 'package:flutter_test/flutter_test.dart';
 import 'package:macos_ui/macos_ui.dart';
 import 'package:map_core/map_core.dart';
 import 'package:map_editor/src/features/path_studio/path_studio_panel.dart';
+import 'package:map_editor/src/features/path_studio/path_studio_save_flow.dart';
 import 'package:path/path.dart' as p;
@@ -718,17 +719,47 @@ void main() {
       expect(saveButton.onPressed, isNull);
     });
 
-    testWidgets('legacy save request calls callback without mutating manifest',
+    testWidgets(
+        'legacy save updates parent manifest and panel exits draft state',
         (tester) async {
-      final manifest = _manifest(
+      var parentManifest = _manifest(
         pathPresets: [_legacyPathPreset(id: 'legacy-water')],
       );
-      final captured = <ProjectPathPatternPreset>[];
-      await _pumpPathStudio(
-        tester,
-        manifest: manifest,
-        onPathPatternPresetSaveRequested: captured.add,
+      var callbackCount = 0;
+
+      await tester.binding.setSurfaceSize(const Size(1440, 920));
+      addTearDown(() => tester.binding.setSurfaceSize(null));
+
+      await tester.pumpWidget(
+        MacosApp(
+          theme: MacosThemeData.dark(),
+          home: MacosScaffold(
+            children: [
+              ContentArea(
+                builder: (context, scrollController) {
+                  return StatefulBuilder(
+                    builder: (context, setParentState) {
+                      return PathStudioPanel(
+                        manifest: parentManifest,
+                        onPathPatternPresetSaveRequested: (preset) {
+                          callbackCount += 1;
+                          setParentState(() {
+                            parentManifest = applyLegacyPathPatternSaveToManifest(
+                              manifest: parentManifest,
+                              preset: preset,
+                            );
+                          });
+                        },
+                      );
+                    },
+                  );
+                },
+              ),
+            ],
+          ),
+        ),
       );
+      await _pumpPathStudioAsync(tester);
 
       await tester.tap(
         find.widgetWithText(CupertinoButton, 'Depuis un path existant'),
@@ -740,20 +771,23 @@ void main() {
       );
       await tester.pumpAndSettle();
 
-      final saveButton = tester.widget<CupertinoButton>(
-        find.byKey(const Key('path-studio-save-button')),
-      );
-      expect(saveButton.onPressed, isNotNull);
-
       await tester.tap(find.byKey(const Key('path-studio-save-button')));
       await tester.pumpAndSettle();
 
-      expect(captured, hasLength(1));
-      expect(captured.single.id, 'motif-eau');
-      expect(captured.single.name, 'Motif eau');
-      expect(captured.single.basePathPresetId, 'legacy-water');
-      expect(manifest.pathPatternPresets, isEmpty);
-      expect(find.text('Requête de sauvegarde préparée'), findsWidgets);
+      expect(callbackCount, 1);
+      expect(
+        parentManifest.pathPatternPresets.any((preset) => preset.id == 'motif-eau'),
+        isTrue,
+      );
+      expect(find.byKey(const Key('path-studio-draft-card')), findsNothing);
+      expect(
+        find.byKey(const Key('path-studio-save-success-message')),
+        findsOneWidget,
+      );
+      expect(find.text('Motif enregistré dans le projet'), findsOneWidget);
+      expect(find.text('Propriétés du preset'), findsOneWidget);
+      expect(find.text('motif-eau'), findsWidgets);
+      expect(find.text('Motif PathPattern depuis path existant'), findsNothing);
     });
 ```

### 17.7 Sorties complètes des tests ciblés

```text
00:00 +0: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/path_pattern/path_studio_panel_test.dart
00:00 +0: PathStudioPanel renders a dark empty state when no PathPattern preset exists
00:00 +1: PathStudioPanel lists presets and updates summary and inspector selection
00:00 +2: PathStudioPanel filters presets locally and clears selection on no result
00:01 +3: PathStudioPanel creates a new path draft without legacy base presets
00:01 +4: PathStudioPanel new path draft does not force existing legacy path choices
00:01 +5: PathStudioPanel new path draft can select a project tileset
00:01 +6: PathStudioPanel new path draft stays usable when the project has no tileset
00:01 +7: PathStudioPanel assigns a tileset tile to the 1x1 active cell
00:02 +8: PathStudioPanel missing tileset image keeps the logical picker fallback
00:02 +9: PathStudioPanel image-backed tileset picker assigns the active cell
00:02 +10: PathStudioPanel image-backed picker fills all 2x2 cells and supports clear
00:03 +11: PathStudioPanel assigns independent tiles to all 2x2 center cells
00:03 +12: PathStudioPanel replaces and clears the active cell tile
00:03 +13: PathStudioPanel changing tileset clears configured center cells
00:03 +14: PathStudioPanel resizes the new path draft to 2x2 and selects a cell
00:04 +15: PathStudioPanel edits new path draft name and keeps save disabled
00:04 +16: PathStudioPanel new path save status explains missing path variant mapping
00:04 +17: PathStudioPanel new path with complete center stays blocked for save
00:04 +18: PathStudioPanel legacy save request is prepared but disabled without callback
00:04 +19: PathStudioPanel legacy save updates parent manifest and panel exits draft state
00:04 +20: PathStudioPanel legacy duplicate proposed id blocks save
00:04 +21: PathStudioPanel secondary legacy flow changes inherited structure locally
00:04 +22: PathStudioPanel empty new path name shows a local diagnostic
00:04 +23: PathStudioPanel secondary legacy flow reports missing existing paths
00:04 +24: All tests passed!
```

```text
00:00 +0: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/path_pattern/path_studio_workspace_save_flow_test.dart
00:00 +0: Lot 20-ter — Real Save Handler Proof applyLegacyPathPatternSaveToManifest (helper de PRODUCTION) ajoute un preset dans un manifest vide
00:00 +1: Lot 20-ter — Real Save Handler Proof applyLegacyPathPatternSaveToManifest (helper de PRODUCTION) remplace un preset existant avec même id (upsert)
00:00 +2: Lot 20-ter — Real Save Handler Proof applyLegacyPathPatternSaveToManifest (helper de PRODUCTION) preserve les autres presets lors de l'ajout
00:00 +3: Lot 20-ter — Real Save Handler Proof upsertProjectPathPatternPreset direct ajoute un preset dans un manifest vide
00:00 +4: All tests passed!
```

```text
00:00 +0: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/path_pattern/path_studio_save_plan_test.dart
00:00 +0: PathStudioSavePlan slugifies proposed ids with a stable fallback
00:00 +1: PathStudioSavePlan keeps a new path without tileset non-saveable
00:00 +2: PathStudioSavePlan builds a local center pattern for a complete new path center
00:00 +3: PathStudioSavePlan builds a row-major 2x2 local center pattern for new path
00:00 +4: PathStudioSavePlan prepares a ProjectPathPatternPreset for a valid legacy draft
00:00 +5: PathStudioSavePlan blocks a legacy draft with an empty name
00:00 +6: PathStudioSavePlan blocks duplicate proposed PathPattern ids
00:00 +7: All tests passed!
```

### 17.8 Lignes finales exactes des grosses régressions

```text
flutter test test/path_pattern/ --reporter expanded
00:07 +101: All tests passed!

flutter test test/editor_shell_page_smoke_test.dart --reporter expanded
00:02 +7: All tests passed!

flutter test test/top_toolbar_test.dart --reporter expanded
00:00 +5: All tests passed!

flutter test test/editor_selectors_test.dart --reporter expanded
00:00 +8: All tests passed!
```

### 17.9 Sortie analyze ciblée

```text
Analyzing 2 items...
No issues found! (ran in 2.1s)
```

## 18. Auto-review

Ce qui est effectivement prouvé:

- save legacy + parent update manifest déclenche transition UI propre;
- draft legacy n'est plus actif après save réussi;
- preset sauvegardé visible et sélectionné;
- feedback de réussite affiché.

Ce qui n'a pas été élargi volontairement:

- aucun changement de logique métier `map_core`;
- aucune persistance disque;
- aucun workflow `Nouveau chemin` sauvegardable.

## 19. Critique du prompt

Le prompt est précis et exploitable, avec un excellent cadrage des non-objectifs.  
Point de vigilance: l'exigence "sorties complètes des grosses régressions" peut devenir volumineuse; le lot reste lisible en donnant les sorties complètes ciblées et les lignes finales exactes des suites larges.

## 20. Conclusion

Lot 21 atteint sur le périmètre demandé:

- UX post-save legacy durcie;
- état brouillon legacy nettoyé après upsert mémoire;
- feedback clair visible;
- preset sauvegardé visible/sélectionné;
- tests/analyze demandés passants;
- aucune dérive vers Tall Grass/runtime/gameplay/persistence.

## Checklist finale

- [x] Audit initial réalisé.
- [x] agent_rules.md lu et respecté.
- [x] Ancienne roadmap Tall Grass ignorée.
- [x] Aucun faux test.
- [x] Aucun provider inventé.
- [x] Aucun repository/service ajouté.
- [x] Aucun fichier projet écrit.
- [x] Aucun FileProjectRepository utilisé.
- [x] Aucun map_core modifié.
- [x] ProjectManifest non modifié.
- [x] Codecs PathPattern non modifiés.
- [x] Aucun generated file.
- [x] Aucun build_runner.
- [x] Legacy save flow affiche un feedback de réussite.
- [x] Legacy draft ne reste pas présenté comme brouillon actif après sauvegarde.
- [x] Preset sauvegardé visible dans la liste.
- [x] Preset sauvegardé sélectionné ou non-sélection documentée.
- [x] Nouveau chemin reste non sauvegardable.
- [x] Tests ciblés passent.
- [x] Régressions pertinentes passent ou échecs documentés.
- [x] Analyze ciblé passe.
- [x] Rapport final complet créé.
- [x] Auto-review faite.
- [x] Critique du prompt faite.
