# NS-STORYLINES-03-bis — Disabled Header Actions & Dark Visual Gate Hardening

## 1. Executive summary

Bis chirurgical livré.

Objectif traité :

- test des actions futures `Nouvelle storyline` / `Valider` durci ;
- suppression du tap silencieux `warnIfMissed: false` ;
- preuve explicite que les actions existent, sont disabled (`PokeMapButton.onPressed == null`) et ne mutent ni projet, ni workspace, ni sélection narrative ;
- harness Visual Gate passé sur `PokeMapTheme.dark()` via thème existant PokeMap ;
- trois screenshots Visual Gate régénérés en dark.

Aucun code production modifié.

Prochain lot inchangé :

```text
NS-STORYLINES-04 — Storylines Secondary List Panel Read-only V0
```

## 2. Inputs read

Fichiers lus :

```text
reports/narrativeStudio/storylines/road_map_storylines.md
reports/narrativeStudio/storylines/ns_storylines_03_storylines_workspace_shell_layout_v0.md
packages/map_editor/test/storylines_workspace_shell_test.dart
packages/map_editor/test/storylines_current_global_story_characterization_test.dart
packages/map_editor/lib/src/ui/canvas/storylines_workspace.dart
packages/map_editor/lib/src/ui/canvas/narrative_workspace_canvas.dart
packages/map_editor/lib/src/ui/canvas/narrative_studio_header.dart
packages/map_editor/lib/src/ui/design_system/design_system.dart
packages/map_editor/lib/src/ui/design_system/pokemap_tone.dart
packages/map_editor/lib/src/ui/design_system/pokemap_dashboard_primitives.dart
packages/map_editor/lib/src/theme/pokemap_color_tokens.dart
packages/map_editor/lib/src/theme/theme.dart
packages/map_editor/lib/src/ui/shared/cupertino_editor_widgets.dart
packages/map_editor/lib/src/ui/shared/editor_visual_tokens.dart
```

Fichiers attendus absents : aucun.

## 3. Header actions test hardening

État avant bis :

```dart
await tester.tap(
  find.byKey(
    const ValueKey('narrative-studio-header-action-new-storyline'),
  ),
  warnIfMissed: false,
);
```

Problème : le test pouvait passer si la cible n'était pas tapable ou mal trouvée.

Durcissement livré dans `packages/map_editor/test/storylines_workspace_shell_test.dart` :

```dart
final newStorylineAction = find.byKey(
  const ValueKey('narrative-studio-header-action-new-storyline'),
);
final validateAction = find.byKey(
  const ValueKey('narrative-studio-header-action-validate'),
);
final newStorylineButton = find.descendant(
  of: newStorylineAction,
  matching: find.byType(PokeMapButton),
);
final validateButton = find.descendant(
  of: validateAction,
  matching: find.byType(PokeMapButton),
);

expect(newStorylineAction, findsOneWidget);
expect(validateAction, findsOneWidget);
expect(newStorylineButton, findsOneWidget);
expect(validateButton, findsOneWidget);
expect(
  tester.widget<PokeMapButton>(newStorylineButton).onPressed,
  isNull,
);
expect(tester.widget<PokeMapButton>(validateButton).onPressed, isNull);
```

Un test source empêche aussi le retour du tap silencieux :

```dart
const silentTapArgument = 'warnIfMissed' ': false';

expect(contents.contains(silentTapArgument), isFalse);
```

TDD rouge observé avant correction :

```text
Commande :
cd packages/map_editor && flutter test test/storylines_workspace_shell_test.dart

Sortie exacte pertinente :
00:00 +3 -1: NS-STORYLINES-03 Storylines shell V0 storylines action test does not use silent taps [E]
  Expected: false
    Actual: <true>

00:00 +3 -2: NS-STORYLINES-03 Storylines shell V0 uses PokeMap dark theme in the Visual Gate harness [E]
  Test failed. See exception logs above.
  The test description was: uses PokeMap dark theme in the Visual Gate harness

00:00 +4 -2: Some tests failed.
```

## 4. Mutation guarantees

Le test capture maintenant avant interaction :

```text
workspaceMode
project instance
project.scenarios.length
project.scenarios ids
selectedGlobalStoryId
selectedStepId
```

Puis il tape les deux actions et vérifie :

```text
- workspaceMode inchangé ;
- workspaceMode reste EditorWorkspaceMode.globalStory ;
- même instance ProjectManifest ;
- même nombre de scenarios ;
- mêmes scenario ids ;
- même selectedGlobalStoryId ;
- même selectedStepId ;
- la Storyline fixture reste visible ;
- la description fixture reste visible ;
- aucune chaîne cible fake n'apparaît après interaction.
```

Actions testées :

```text
Nouvelle storyline
Valider
```

Conclusion : les actions futures sont présentes, disabled, et non mutantes.

## 5. Visual Gate theme investigation

Cause identifiée :

```text
Le harness pompait un MaterialApp nu :

MaterialApp(
  home: Scaffold(...)
)
```

Sans `theme`, `darkTheme` ni `themeMode`, Flutter utilisait le thème light de test.

Correction appliquée dans le harness de test uniquement :

```dart
MaterialApp(
  theme: PokeMapTheme.light(),
  darkTheme: PokeMapTheme.dark(),
  themeMode: ThemeMode.dark,
  home: Scaffold(...),
)
```

Aucune couleur locale, aucun thème bricolé, aucun changement dans `StorylinesWorkspace`.

Le test suivant verrouille le résultat :

```dart
testWidgets('uses PokeMap dark theme in the Visual Gate harness',
    (tester) async {
  await _pumpStorylinesShell(tester);

  final shellContext =
      tester.element(find.byKey(const ValueKey('storylines-workspace-shell')));

  expect(Theme.of(shellContext).brightness, Brightness.dark);
});
```

## 6. Visual Gate result

Screenshots régénérés :

```text
reports/narrativeStudio/storylines/screenshots/ns_storylines_03_shell_desktop.png
reports/narrativeStudio/storylines/screenshots/ns_storylines_03_shell_focus.png
reports/narrativeStudio/storylines/screenshots/ns_storylines_03_shell_panels.png
```

Dimensions :

```text
reports/narrativeStudio/storylines/screenshots/ns_storylines_03_shell_desktop.png: PNG image data, 1600 x 1000, 8-bit/color RGBA, non-interlaced
reports/narrativeStudio/storylines/screenshots/ns_storylines_03_shell_focus.png:   PNG image data, 1600 x 700, 8-bit/color RGBA, non-interlaced
reports/narrativeStudio/storylines/screenshots/ns_storylines_03_shell_panels.png:  PNG image data, 1180 x 1000, 8-bit/color RGBA, non-interlaced
```

Observation visuelle :

- le desktop est maintenant en dark premium via `PokeMapTheme.dark()` ;
- layout trois zones conservé ;
- sidebar interne conservée ;
- actions futures toujours visibles en disabled ;
- pas d'overflow visible ;
- rendu Ahem toujours attendu en test golden, donc le gate valide structure, densité, dark theme et absence d'overflow, pas la typographie finale.

Artifacts temporaires `packages/map_editor/test/failures/ns_storylines_03_shell_*` créés par le rouge golden ont été supprimés après régénération. Ce sont des artefacts de test, pas des livrables.

## 7. Design System Gate

Respect :

```text
- aucun code production modifié ;
- aucun StorylinesWorkspace modifié ;
- aucun thème local créé ;
- aucune couleur locale ajoutée ;
- aucun Color(0x...) ajouté ;
- aucun Colors.* ajouté ;
- dark appliqué via PokeMapTheme.light(), PokeMapTheme.dark(), ThemeMode.dark ;
- composants existants conservés.
```

Recherche demandée :

```text
Commande :
rg "Color\(0x|Colors\." packages/map_editor/lib/src/ui/canvas/storylines_workspace.dart packages/map_editor/test/storylines_workspace_shell_test.dart packages/map_editor/test/storylines_current_global_story_characterization_test.dart || true

Sortie exacte :
<vide>
```

## 8. Roadmap update

Roadmap modifiée :

```text
reports/narrativeStudio/storylines/road_map_storylines.md
```

Ajouts :

- note NS-STORYLINES-03-bis dans le détail du lot NS-STORYLINES-03 ;
- entrée changelog `2026-05-28 — NS-STORYLINES-03-bis` ;
- confirmation que NS-STORYLINES-03 reste `DONE` ;
- prochain lot inchangé : `NS-STORYLINES-04`.

## 9. Commands run

### Rouge TDD

```text
Commande :
cd packages/map_editor && flutter test test/storylines_workspace_shell_test.dart

Sortie exacte pertinente :
00:00 +0: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/storylines_workspace_shell_test.dart
00:00 +0: NS-STORYLINES-03 Storylines shell V0 renders a read-only three-pane shell from real global story data
[step_studio_trace] action=apply_document scenario=audit_global_story rows=[]
[step_studio_trace] action=apply_document_metadata scenario=audit_global_story contains_emma=false contains_empty_entity=false
00:00 +1: NS-STORYLINES-03 Storylines shell V0 keeps future header actions disabled and non-mutating
[step_studio_trace] action=apply_document scenario=audit_global_story rows=[]
[step_studio_trace] action=apply_document_metadata scenario=audit_global_story contains_emma=false contains_empty_entity=false
00:00 +2: NS-STORYLINES-03 Storylines shell V0 storylines UI source keeps raw colors out of the feature
00:00 +3: NS-STORYLINES-03 Storylines shell V0 storylines action test does not use silent taps
00:00 +3 -1: NS-STORYLINES-03 Storylines shell V0 storylines action test does not use silent taps [E]
  Expected: false
    Actual: <true>

00:00 +3 -2: NS-STORYLINES-03 Storylines shell V0 uses PokeMap dark theme in the Visual Gate harness [E]
  Expected: Brightness:<Brightness.dark>
    Actual: Brightness:<Brightness.light>

00:01 +4 -2: Some tests failed.
```

### Régénération Visual Gate dark

```text
Commande :
cd packages/map_editor && flutter test --update-goldens test/storylines_workspace_shell_test.dart

Sortie exacte :
00:00 +0: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/storylines_workspace_shell_test.dart
00:00 +0: NS-STORYLINES-03 Storylines shell V0 renders a read-only three-pane shell from real global story data
[step_studio_trace] action=apply_document scenario=audit_global_story rows=[]
[step_studio_trace] action=apply_document_metadata scenario=audit_global_story contains_emma=false contains_empty_entity=false
00:00 +1: NS-STORYLINES-03 Storylines shell V0 keeps future header actions disabled and non-mutating
[step_studio_trace] action=apply_document scenario=audit_global_story rows=[]
[step_studio_trace] action=apply_document_metadata scenario=audit_global_story contains_emma=false contains_empty_entity=false
00:00 +2: NS-STORYLINES-03 Storylines shell V0 storylines UI source keeps raw colors out of the feature
00:00 +3: NS-STORYLINES-03 Storylines shell V0 storylines action test does not use silent taps
00:00 +4: NS-STORYLINES-03 Storylines shell V0 uses PokeMap dark theme in the Visual Gate harness
[step_studio_trace] action=apply_document scenario=audit_global_story rows=[]
[step_studio_trace] action=apply_document_metadata scenario=audit_global_story contains_emma=false contains_empty_entity=false
00:00 +5: NS-STORYLINES-03 Storylines shell V0 writes Visual Gate screenshots
[step_studio_trace] action=apply_document scenario=audit_global_story rows=[]
[step_studio_trace] action=apply_document_metadata scenario=audit_global_story contains_emma=false contains_empty_entity=false
[step_studio_trace] action=apply_document scenario=audit_global_story rows=[]
[step_studio_trace] action=apply_document_metadata scenario=audit_global_story contains_emma=false contains_empty_entity=false
[step_studio_trace] action=apply_document scenario=audit_global_story rows=[]
[step_studio_trace] action=apply_document_metadata scenario=audit_global_story contains_emma=false contains_empty_entity=false
00:01 +6: All tests passed!
```

### Tests finaux

```text
Commande :
cd packages/map_editor && flutter test test/storylines_workspace_shell_test.dart

Sortie exacte :
00:00 +0: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/storylines_workspace_shell_test.dart
00:00 +0: NS-STORYLINES-03 Storylines shell V0 renders a read-only three-pane shell from real global story data
[step_studio_trace] action=apply_document scenario=audit_global_story rows=[]
[step_studio_trace] action=apply_document_metadata scenario=audit_global_story contains_emma=false contains_empty_entity=false
00:00 +1: NS-STORYLINES-03 Storylines shell V0 keeps future header actions disabled and non-mutating
[step_studio_trace] action=apply_document scenario=audit_global_story rows=[]
[step_studio_trace] action=apply_document_metadata scenario=audit_global_story contains_emma=false contains_empty_entity=false
00:00 +2: NS-STORYLINES-03 Storylines shell V0 storylines UI source keeps raw colors out of the feature
00:00 +3: NS-STORYLINES-03 Storylines shell V0 storylines action test does not use silent taps
00:00 +4: NS-STORYLINES-03 Storylines shell V0 uses PokeMap dark theme in the Visual Gate harness
[step_studio_trace] action=apply_document scenario=audit_global_story rows=[]
[step_studio_trace] action=apply_document_metadata scenario=audit_global_story contains_emma=false contains_empty_entity=false
00:00 +5: NS-STORYLINES-03 Storylines shell V0 writes Visual Gate screenshots
[step_studio_trace] action=apply_document scenario=audit_global_story rows=[]
[step_studio_trace] action=apply_document_metadata scenario=audit_global_story contains_emma=false contains_empty_entity=false
[step_studio_trace] action=apply_document scenario=audit_global_story rows=[]
[step_studio_trace] action=apply_document_metadata scenario=audit_global_story contains_emma=false contains_empty_entity=false
[step_studio_trace] action=apply_document scenario=audit_global_story rows=[]
[step_studio_trace] action=apply_document_metadata scenario=audit_global_story contains_emma=false contains_empty_entity=false
00:00 +6: All tests passed!
```

```text
Commande :
cd packages/map_editor && flutter test test/storylines_current_global_story_characterization_test.dart

Sortie exacte :
00:00 +0: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/storylines_current_global_story_characterization_test.dart
00:00 +0: NS-STORYLINES-02 current Global Story characterization renders the current Storylines shell from manifest and authoring metadata
[step_studio_trace] action=apply_document scenario=audit_global_story rows=[]
[step_studio_trace] action=apply_document_metadata scenario=audit_global_story contains_emma=false contains_empty_entity=false
00:00 +1: NS-STORYLINES-02 current Global Story characterization keeps globalStory and localEventFlow separated in the current projection
[step_studio_trace] action=apply_document scenario=audit_global_story rows=[]
[step_studio_trace] action=apply_document_metadata scenario=audit_global_story contains_emma=false contains_empty_entity=false
00:00 +2: All tests passed!
```

### Analyse ciblée

```text
Commande :
cd packages/map_editor && flutter analyze --no-fatal-infos lib/src/ui/canvas/storylines_workspace.dart lib/src/ui/canvas/narrative_workspace_canvas.dart test/storylines_workspace_shell_test.dart test/storylines_current_global_story_characterization_test.dart

Sortie exacte :
Analyzing 4 items...

No issues found! (ran in 2.4s)
```

## 10. Evidence Pack

### Git initial

```text
Commande :
git branch --show-current

Sortie exacte :
main
```

```text
Commande :
git status --short --untracked-files=all

Sortie initiale exacte :
<vide>
```

```text
Commande :
git diff --stat

Sortie initiale exacte :
<vide>
```

```text
Commande :
git diff --name-only

Sortie initiale exacte :
<vide>
```

```text
Commande :
git diff --check

Sortie initiale exacte :
<vide>
```

### Git final

À rafraîchir après création du rapport :

```text
git status final exact:
 M packages/map_editor/test/storylines_workspace_shell_test.dart
 M reports/narrativeStudio/storylines/road_map_storylines.md
 M reports/narrativeStudio/storylines/screenshots/ns_storylines_03_shell_desktop.png
 M reports/narrativeStudio/storylines/screenshots/ns_storylines_03_shell_focus.png
 M reports/narrativeStudio/storylines/screenshots/ns_storylines_03_shell_panels.png
?? reports/narrativeStudio/storylines/ns_storylines_03_bis_disabled_header_actions_dark_visual_gate_hardening.md

git diff --stat final:
 .../test/storylines_workspace_shell_test.dart      | 106 ++++++++++++++++++---
 .../storylines/road_map_storylines.md              |  11 +++
 .../screenshots/ns_storylines_03_shell_desktop.png | Bin 34407 -> 35110 bytes
 .../screenshots/ns_storylines_03_shell_focus.png   | Bin 31784 -> 32490 bytes
 .../screenshots/ns_storylines_03_shell_panels.png  | Bin 33006 -> 33481 bytes
 5 files changed, 104 insertions(+), 13 deletions(-)

git diff --name-only final:
packages/map_editor/test/storylines_workspace_shell_test.dart
reports/narrativeStudio/storylines/road_map_storylines.md
reports/narrativeStudio/storylines/screenshots/ns_storylines_03_shell_desktop.png
reports/narrativeStudio/storylines/screenshots/ns_storylines_03_shell_focus.png
reports/narrativeStudio/storylines/screenshots/ns_storylines_03_shell_panels.png

git diff --check final:
<vide>
```

### Fichiers modifiés / créés par le bis

Modifiés :

```text
packages/map_editor/test/storylines_workspace_shell_test.dart
reports/narrativeStudio/storylines/road_map_storylines.md
reports/narrativeStudio/storylines/screenshots/ns_storylines_03_shell_desktop.png
reports/narrativeStudio/storylines/screenshots/ns_storylines_03_shell_focus.png
reports/narrativeStudio/storylines/screenshots/ns_storylines_03_shell_panels.png
```

Créé :

```text
reports/narrativeStudio/storylines/ns_storylines_03_bis_disabled_header_actions_dark_visual_gate_hardening.md
```

Code production modifié :

```text
<vide>
```

### Diff complet test + roadmap

```diff
diff --git a/packages/map_editor/test/storylines_workspace_shell_test.dart b/packages/map_editor/test/storylines_workspace_shell_test.dart
index 08fba152..82f64c4e 100644
--- a/packages/map_editor/test/storylines_workspace_shell_test.dart
+++ b/packages/map_editor/test/storylines_workspace_shell_test.dart
@@ -9,7 +9,9 @@ import 'package:map_editor/src/features/editor/state/editor_state.dart';
 import 'package:map_editor/src/features/narrative/application/global_story_studio_authoring.dart';
 import 'package:map_editor/src/features/narrative/application/step_studio_authoring.dart';
 import 'package:map_editor/src/features/narrative/state/narrative_workspace_state.dart';
+import 'package:map_editor/src/theme/theme.dart';
 import 'package:map_editor/src/ui/canvas/narrative_workspace_canvas.dart';
+import 'package:map_editor/src/ui/design_system/design_system.dart';
 
 void main() {
   group('NS-STORYLINES-03 Storylines shell V0', () {
@@ -63,26 +65,79 @@ void main() {
       'keeps future header actions disabled and non-mutating',
       (tester) async {
         final harness = await _pumpStorylinesShell(tester);
+        final newStorylineAction = find.byKey(
+          const ValueKey('narrative-studio-header-action-new-storyline'),
+        );
+        final validateAction = find.byKey(
+          const ValueKey('narrative-studio-header-action-validate'),
+        );
+        final newStorylineButton = find.descendant(
+          of: newStorylineAction,
+          matching: find.byType(PokeMapButton),
+        );
+        final validateButton = find.descendant(
+          of: validateAction,
+          matching: find.byType(PokeMapButton),
+        );
 
-        await tester.tap(
-          find.byKey(
-            const ValueKey('narrative-studio-header-action-new-storyline'),
-          ),
-          warnIfMissed: false,
+        expect(newStorylineAction, findsOneWidget);
+        expect(validateAction, findsOneWidget);
+        expect(newStorylineButton, findsOneWidget);
+        expect(validateButton, findsOneWidget);
+        expect(
+          tester.widget<PokeMapButton>(newStorylineButton).onPressed,
+          isNull,
         );
+        expect(tester.widget<PokeMapButton>(validateButton).onPressed, isNull);
+
+        final beforeEditorState =
+            harness.container.read(editorNotifierProvider);
+        final beforeNarrativeState =
+            harness.container.read(narrativeWorkspaceControllerProvider);
+        final beforeProject = beforeEditorState.project!;
+        final beforeScenarioIds = beforeProject.scenarios
+            .map((scenario) => scenario.id)
+            .toList(growable: false);
+        final beforeScenarioCount = beforeProject.scenarios.length;
+
+        await tester.tap(newStorylineAction);
         await tester.pump();
 
-        await tester.tap(
-          find.byKey(const ValueKey('narrative-studio-header-action-validate')),
-          warnIfMissed: false,
-        );
+        await tester.tap(validateAction);
         await tester.pump();
 
+        final afterEditorState = harness.container.read(editorNotifierProvider);
+        final afterNarrativeState =
+            harness.container.read(narrativeWorkspaceControllerProvider);
+
+        expect(afterEditorState.workspaceMode, beforeEditorState.workspaceMode);
+        expect(afterEditorState.workspaceMode, EditorWorkspaceMode.globalStory);
+        expect(afterEditorState.project, same(beforeProject));
+        expect(afterEditorState.project!.scenarios.length, beforeScenarioCount);
         expect(
-          harness.container.read(editorNotifierProvider).workspaceMode,
-          EditorWorkspaceMode.globalStory,
+          afterEditorState.project!.scenarios
+              .map((scenario) => scenario.id)
+              .toList(growable: false),
+          beforeScenarioIds,
+        );
+        expect(
+          afterNarrativeState.selectedGlobalStoryId,
+          beforeNarrativeState.selectedGlobalStoryId,
+        );
+        expect(
+          afterNarrativeState.selectedStepId,
+          beforeNarrativeState.selectedStepId,
         );
         expect(find.text('Audit Story From Scenario'), findsWidgets);
+        expect(find.text('Audit description from scenario'), findsOneWidget);
+
+        for (final forbidden in _targetOnlyStrings) {
+          expect(
+            find.text(forbidden),
+            findsNothing,
+            reason: '$forbidden must not appear after disabled interactions.',
+          );
+        }
       },
     );
 
@@ -91,9 +146,31 @@ void main() {
       expect(source.existsSync(), isTrue);
 
       final contents = source.readAsStringSync();
+      const rawColorConstructor = 'Color' '(0x';
+      const materialColorAccessor = 'Colors' '.';
+
+      expect(contents.contains(rawColorConstructor), isFalse);
+      expect(contents.contains(materialColorAccessor), isFalse);
+    });
+
+    test('storylines action test does not use silent taps', () {
+      final source = File('test/storylines_workspace_shell_test.dart');
+      expect(source.existsSync(), isTrue);
+
+      final contents = source.readAsStringSync();
+      const silentTapArgument = 'warnIfMissed' ': false';
+
+      expect(contents.contains(silentTapArgument), isFalse);
+    });
+
+    testWidgets('uses PokeMap dark theme in the Visual Gate harness',
+        (tester) async {
+      await _pumpStorylinesShell(tester);
+
+      final shellContext =
+          tester.element(find.byKey(const ValueKey('storylines-workspace-shell')));
 
-      expect(contents.contains('Color(0x'), isFalse);
-      expect(contents.contains('Colors.'), isFalse);
+      expect(Theme.of(shellContext).brightness, Brightness.dark);
     });
 
     testWidgets('writes Visual Gate screenshots', (tester) async {
@@ -178,6 +255,9 @@ Future<_StorylinesHarness> _pumpStorylinesShell(
     UncontrolledProviderScope(
       container: container,
       child: MaterialApp(
+        theme: PokeMapTheme.light(),
+        darkTheme: PokeMapTheme.dark(),
+        themeMode: ThemeMode.dark,
         home: Scaffold(
           body: SizedBox(
             width: surfaceSize.width,
diff --git a/reports/narrativeStudio/storylines/road_map_storylines.md b/reports/narrativeStudio/storylines/road_map_storylines.md
index 1dae538f..65dc150a 100644
--- a/reports/narrativeStudio/storylines/road_map_storylines.md
+++ b/reports/narrativeStudio/storylines/road_map_storylines.md
@@ -374,6 +374,7 @@ Interprétation V0 :
 - Visual Gate : `ns_storylines_03_shell_desktop.png`, `ns_storylines_03_shell_focus.png`, `ns_storylines_03_shell_panels.png`.
 - Design System Gate : confirmé ; primitives `PokeMapPageSurface`, `PokeMapInspectorPanel`, `PokeMapStatusTile`, `PokeMapIconTile`, `PokeMapTone` utilisées ; aucun `Color(0x...)` / `Colors.*` ajouté dans les fichiers du lot.
 - Fake data : aucune donnée Selbrume/cible ajoutée ; actions futures affichées disabled/read-only.
+- Bis NS-STORYLINES-03-bis : test des actions futures durci avec présence obligatoire, `PokeMapButton.onPressed == null`, non-mutation du projet/workspace/sélection ; harness Visual Gate passé sur `PokeMapTheme.dark()`.
 - Prochain lot attendu : NS-STORYLINES-04.
 
 ### NS-STORYLINES-04 — Storylines Secondary List Panel Read-only V0
@@ -673,6 +674,16 @@ Next recommended lot: NS-STORYLINES-04 — Storylines Secondary List Panel Read-
 - Tests ciblés Storylines / Global Story / Projection passés ; analyse ciblée clean.
 - Prochain lot recommandé : `NS-STORYLINES-04 — Storylines Secondary List Panel Read-only V0`.
 
+### 2026-05-28 — NS-STORYLINES-03-bis
+
+- Durcissement du test `keeps future header actions disabled and non-mutating`.
+- Vérification explicite que `Nouvelle storyline` et `Valider` existent, que leurs `PokeMapButton.onPressed` sont `null`, et qu'un tap ne modifie ni workspace, ni projet, ni scénario sélectionné.
+- Suppression du tap silencieux `warnIfMissed: false` dans le test.
+- Application de `PokeMapTheme.light()`, `PokeMapTheme.dark()` et `ThemeMode.dark` dans le harness Visual Gate.
+- Régénération des trois screenshots `ns_storylines_03_shell_desktop.png`, `ns_storylines_03_shell_focus.png`, `ns_storylines_03_shell_panels.png`.
+- Aucun code production, aucune UI, aucun modèle et aucune primitive design system modifiés.
+- Prochain lot recommandé inchangé : `NS-STORYLINES-04 — Storylines Secondary List Panel Read-only V0`.
+
 ### 2026-05-27 — NS-STORYLINES-02
 
 - Ajout du test `storylines_current_global_story_characterization_test.dart`.
```

### Screenshots modifiés

```text
reports/narrativeStudio/storylines/screenshots/ns_storylines_03_shell_desktop.png
reports/narrativeStudio/storylines/screenshots/ns_storylines_03_shell_focus.png
reports/narrativeStudio/storylines/screenshots/ns_storylines_03_shell_panels.png
```

Ces screenshots sont régénérés en dark via le harness PokeMap. Les fichiers PNG sont binaires ; le rapport liste leurs chemins et dimensions.

### Confirmation production

```text
Aucun fichier sous packages/map_editor/lib/ n'a été modifié par NS-STORYLINES-03-bis.
Aucun fichier map_core, map_runtime, map_gameplay, map_battle n'a été modifié.
Aucun modèle métier n'a été modifié.
Aucun widget production n'a été créé.
```

## 11. Self-review

Checklist :

```text
- Actions futures trouvées explicitement : oui.
- `warnIfMissed: false` supprimé : oui.
- `PokeMapButton.onPressed == null` vérifié : oui.
- Non-mutation projet/workspace/sélection vérifiée : oui.
- Fake strings absentes après interaction : oui.
- Harness dark via design system : oui.
- StorylinesWorkspace inchangé : oui.
- Code production inchangé : oui.
- Screenshots régénérés : oui.
- Roadmap mise à jour : oui.
- Prochain lot inchangé : NS-STORYLINES-04.
```

Limite :

```text
Les goldens utilisent toujours la police Ahem. Le bis corrige le thème dark, pas la validation typographique finale.
```
