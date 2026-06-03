# NS-SCENES-V1-66 — Evidence Pack

Date : 2026-06-03
Lot : `NS-SCENES-V1-66 — Cinematic Timeline Mouse Probe Help / Selection Explanation V0`
Statut propose : DONE

## 1. Inventaire

Fichiers produit/test modifies :

```text
packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart
packages/map_editor/test/cinematic_builder_workspace_test.dart
```

Fichiers rapport/roadmap modifies ou crees :

```text
reports/narrativeStudio/scenes/ns_scenes_v1_66_cinematic_timeline_mouse_probe_help_selection_explanation_v0.md
reports/narrativeStudio/scenes/ns_scenes_v1_66_evidence_pack.md
reports/narrativeStudio/scenes/road_map_scenes.md
reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_66_cinematic_timeline_mouse_probe_help_selection_explanation_v0.png
```

## 2. Gate 0

Le working tree etait propre avant V1-66. `git status --short --untracked-files=all`, `git diff --stat` et `git diff --name-only` n'ont rien imprime. HEAD etait :

```text
46cc0eb4 feat(narrative): add cinematic timeline mouse probe UX polish clear controls v0 (NS-SCENES-V1-65)
```

## 3. TDD RED

Commande :

```bash
cd packages/map_editor && flutter test --reporter=compact test/cinematic_builder_workspace_test.dart --plain-name 'shows local time probe help explaining selection and probe'
```

Echec attendu avant implementation :

```text
Expected: exactly one matching candidate
  Actual: _TextWidgetFinder:<Found 0 widgets with text "Aide repère": []>
```

Interpretation : le test echoue sur l'absence de l'aide locale, pas sur un probleme de fixture.

## 4. Implementation evidence

Changements UI principaux :

```diff
+  bool _timelineProbeHelpOpen = false;
+
+  void _toggleTimelineProbeHelp() {
+    _requestTimelineKeyboardFocus();
+    setState(() => _timelineProbeHelpOpen = !_timelineProbeHelpOpen);
+  }
+
+  @override
+  void didUpdateWidget(covariant _TimelinePlaceholder oldWidget) {
+    super.didUpdateWidget(oldWidget);
+    if (oldWidget.timelineProbeTimeMs != null &&
+        widget.timelineProbeTimeMs == null) {
+      _timelineProbeHelpOpen = false;
+    }
+  }
```

Controle local ajoute pres de `Effacer le repère` :

```diff
+                            _HeaderAction(
+                              label: 'Aide repère',
+                              button: PokeMapButton(
+                                key: const ValueKey(
+                                  'cinematic-builder-probe-help-button',
+                                ),
+                                onPressed: _toggleTimelineProbeHelp,
+                                variant: PokeMapButtonVariant.secondary,
+                                size: PokeMapButtonSize.small,
+                                leading: const Icon(
+                                  CupertinoIcons.question_circle,
+                                ),
+                                child: const SizedBox.shrink(),
+                              ),
+                            ),
```

Panneau local :

```diff
+class _TimelineProbeHelpPanel extends StatelessWidget {
+  const _TimelineProbeHelpPanel();
+
+  @override
+  Widget build(BuildContext context) {
+    return const PokeMapCard(
+      key: ValueKey('cinematic-builder-probe-help-panel'),
+      focused: true,
+      borderRadius: 6,
+      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
+      child: SizedBox(
+        width: 302,
+        child: Column(
+          crossAxisAlignment: CrossAxisAlignment.stretch,
+          children: [
+            _TimelineProbeHelpLine('Sélection : bloc inspecté.'),
+            SizedBox(height: 5),
+            _TimelineProbeHelpLine('Repère : position temporelle locale.'),
+            SizedBox(height: 5),
+            _TimelineProbeHelpLine(
+              'Alignement : repère calé sur une borne utile.',
+            ),
+            SizedBox(height: 5),
+            _TimelineProbeHelpLine('Preview : lecture réelle à venir.'),
+          ],
+        ),
+      ),
+    );
+  }
+}
```

Note de correction : une premiere implementation en bouton d'en-tete simple a cree un overflow sur un test existant ; une seconde en badge horizontal etait trop loin dans la zone scrollable. La solution finale preserve l'en-tete historique sans probe, puis utilise un `Wrap` seulement quand le probe est actif.

## 5. Test evidence

Test principal ajoute :

```text
shows local time probe help explaining selection and probe
```

Ce test couvre :

- absence du bouton/panneau sans probe ;
- apparition de `Aide repère` apres pose du probe ;
- contenu exact des quatre lignes d'aide ;
- absence des mots anglais `playback`, `seek`, `scrub` dans l'UI ;
- selection `step_face` preservee ;
- repere toujours present et cursor stable ;
- aucune mutation projet ;
- transports disabled ;
- coexistence avec `Aide clavier` ;
- toggle off/on ;
- clear apres ouverture.

Test Escape ajoute :

```text
clears local time probe with Escape after probe help is open
```

Il prouve que l'aide ne bloque pas le handler Escape local et ne mute pas le projet.

## 6. Visual Gate

Commande :

```bash
cd packages/map_editor && flutter test --update-goldens --dart-define=NS_SCENES_V1_66_CAPTURE_CINEMATIC_TIMELINE_MOUSE_PROBE_HELP=true --reporter=compact test/cinematic_builder_workspace_test.dart
```

Resultat :

```text
00:12 +68: All tests passed!
```

Screenshot :

```text
reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_66_cinematic_timeline_mouse_probe_help_selection_explanation_v0.png
```

## 7. Verifications finales

```bash
cd packages/map_editor && flutter test --reporter=compact test/cinematic_builder_workspace_test.dart
```

```text
00:11 +68: All tests passed!
```

```bash
cd packages/map_editor && flutter test --reporter=compact test/cinematics_library_workspace_test.dart
```

```text
00:05 +10: All tests passed!
```

```bash
cd packages/map_editor && flutter analyze --no-fatal-infos lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart test/cinematic_builder_workspace_test.dart
```

```text
No issues found! (ran in 1.5s)
```

```bash
cd packages/map_core && dart test test/cinematic_timeline_time_layout_read_model_test.dart
```

```text
00:00 +4: All tests passed!
```

```bash
cd packages/map_core && dart test test/cinematic_timeline_lane_read_model_test.dart
```

```text
00:00 +2: All tests passed!
```

```bash
cd packages/map_core && dart analyze
```

```text
Analyzing map_core...
No issues found!
```

## 8. Analyse globale editor

Commande :

```bash
cd packages/map_editor && flutter analyze
```

Resultat :

```text
344 issues found. (ran in 3.5s)
```

Les erreurs sont hors scope et preexistantes, notamment :

```text
lib/src/application/services/pokemon_sdk_move_catalog_converter.dart
lib/src/application/use_cases/sync_pokemon_sdk_moves_catalog_use_case.dart
```

Les fichiers V1-66 modifies passent l'analyse ciblee sans issue.

## 9. Anti-scope

Commande UI :

```bash
rg -n "ProjectManifest|map_runtime|Flame|playback|seek|scrub|runtime position|temps courant" packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart || true
```

Resultat : aucune sortie.

Commande UI + tests :

```bash
rg -n "playback|seek|scrub|temps courant|runtime position" packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart packages/map_editor/test/cinematic_builder_workspace_test.dart || true
```

Resultat :

```text
packages/map_editor/test/cinematic_builder_workspace_test.dart:680:    expect(find.text('playback'), findsNothing);
packages/map_editor/test/cinematic_builder_workspace_test.dart:681:    expect(find.text('seek'), findsNothing);
packages/map_editor/test/cinematic_builder_workspace_test.dart:682:    expect(find.text('scrub'), findsNothing);
```

Interpretation : seules des assertions negatives de test mentionnent ces mots.

Commande core :

```bash
git diff -- packages/map_core
```

Resultat : aucune sortie.

## 10. Roadmaps

- `road_map_scenes.md` : V1-66 marque DONE, prochain lot recommande V1-67.
- `road_map_scene_builder_authoring.md` : V1-66 marque DONE, V1-67 ajoute en TODO.

## 11. Verdict

V1-66 peut etre ferme DONE : l'aide locale explique le repere sans mutation, sans runtime et sans nouveau pouvoir temporel.
