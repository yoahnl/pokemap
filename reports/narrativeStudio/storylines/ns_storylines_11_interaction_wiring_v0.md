# NS-STORYLINES-11 — Storylines Interaction Wiring V0 / V1 Creation Readiness

## 1. Executive summary

NS-STORYLINES-11 câble les interactions V0 honnêtes du workspace Storylines :

- sélection locale d'une `globalStory` existante depuis le panneau secondaire ;
- synchronisation du header, des KPI, du graph, de l'inspecteur Storyline et de la tab `Chapitres` avec la storyline sélectionnée ;
- navigation locale `Graph` / `Chapitres` conservée ;
- reset prudent de la sélection chapitre quand la storyline change ;
- actions futures toujours disabled / non mutantes ;
- V1 Creation Readiness documentée dans la roadmap et dans ce rapport.

Aucune création de storyline, aucun modèle `StorylineAsset`, aucune quête annexe fake et aucune mutation de `ProjectManifest` / `ScenarioAsset` n'ont été ajoutés.

## 2. Inputs read

Fichiers obligatoires lus :

- `AGENTS.md`
- `agent_rules.md`
- `skills/README.md`
- `reports/narrativeStudio/storylines/road_map_storylines.md`
- `reports/narrativeStudio/storylines/ns_storylines_10_visual_harmonization_visual_gate_v0.md`
- `reports/narrativeStudio/storylines/ns_storylines_09_chapters_inspector_step_ordering_read_only_v0.md`
- `reports/narrativeStudio/storylines/ns_storylines_08_ter_true_graph_geometry_v0.md`
- `reports/narrativeStudio/storylines/ns_storylines_08_chapters_tab_read_only_v0.md`
- `reports/narrativeStudio/storylines/ns_storylines_07_inspector_read_only_v0.md`
- `reports/narrativeStudio/storylines/ns_storylines_05_header_tabs_kpi_read_only_v0.md`
- `packages/map_editor/lib/src/ui/canvas/storylines_workspace.dart`
- `packages/map_editor/lib/src/ui/canvas/narrative_workspace_canvas.dart`
- `packages/map_editor/lib/src/ui/canvas/narrative_studio_shell.dart`
- `packages/map_editor/lib/src/ui/canvas/narrative_studio_sidebar.dart`
- `packages/map_editor/lib/src/ui/canvas/narrative_studio_header.dart`
- `packages/map_editor/lib/src/features/narrative/application/narrative_workspace_projection.dart`
- `packages/map_editor/lib/src/features/narrative/state/narrative_workspace_state.dart`
- `packages/map_editor/lib/src/features/narrative/state/narrative_workspace_providers.dart`
- `packages/map_editor/test/storylines_workspace_shell_test.dart`
- `packages/map_editor/test/storylines_current_global_story_characterization_test.dart`
- `packages/map_editor/test/narrative_workspace_projection_test.dart`

Design system inspecté :

- `packages/map_editor/lib/src/ui/design_system/design_system.dart`
- `packages/map_editor/lib/src/ui/design_system/pokemap_tone.dart`
- `packages/map_editor/lib/src/ui/design_system/pokemap_dashboard_primitives.dart`
- `packages/map_editor/lib/src/ui/design_system/pokemap_button.dart`
- `packages/map_editor/lib/src/ui/design_system/pokemap_card.dart`
- `packages/map_editor/lib/src/ui/design_system/pokemap_panel.dart`
- `packages/map_editor/lib/src/theme/pokemap_color_tokens.dart`
- `packages/map_editor/lib/src/theme/theme.dart`
- `packages/map_editor/lib/src/ui/shared/cupertino_editor_widgets.dart`
- `packages/map_editor/lib/src/ui/shared/editor_visual_tokens.dart`

Fichiers attendus absents :

```text
Sortie : <vide>
```

## 3. Implementation summary

Modifications production :

- `StorylinesWorkspace` conserve maintenant une sélection locale `_selectedGlobalStoryId`.
- La sélection effective reste `widget.selectedGlobalStoryId` tant qu'aucune sélection locale n'a été faite.
- Le panneau secondaire reçoit `onStorySelected` et rend les lignes de storylines réelles cliquables via `PokeMapCard.onTap`.
- Une key stable `storylines-secondary-selected-<storyId>` marque la storyline active.
- La sélection filtre les steps et chapters existants déjà dérivés par la projection.
- `_StorylineChaptersSection` reçoit `storyId` et reset sa sélection locale de chapitre quand la storyline change.

Modifications tests :

- groupe renommé `NS-STORYLINES-11 Interaction wiring V0` ;
- test de sélection de `Audit Second Story From Scenario` depuis le panneau secondaire ;
- vérification que header, KPI, graph, inspector et Chapitres se synchronisent ;
- vérification que `ProjectManifest`, `workspaceMode`, scénarios et état narratif persistant ne mutent pas ;
- Visual Gate NS11 remplacé par trois captures interaction.

## 4. Storyline selection behavior

Comportement livré :

- première `globalStory` disponible reste sélectionnée par défaut si l'état narratif ne pointe pas vers une story valide ;
- cliquer une storyline réelle du panneau secondaire change uniquement l'état UI local du workspace Storylines ;
- le header central affiche le nom et la description réels de la story sélectionnée ;
- les KPI se recalculent depuis les steps/chapters réels filtrés par `globalScenarioId` ;
- le graph affiche les chapters/steps de la story sélectionnée ;
- l'inspecteur Storyline affiche la story sélectionnée ;
- la tab `Chapitres` affiche les chapters de la story sélectionnée ;
- aucun `ProjectManifest`, `ScenarioAsset`, `NarrativeWorkspaceState` persistant ou `workspaceMode` n'est modifié par ce clic.

## 5. Tab interaction behavior

Interactions branchées :

- `Graph` : vue par défaut, état local d'affichage ;
- `Chapitres` : vue read-only avec sélection locale de chapitre ;
- retour `Chapitres` -> `Graph` conserve la storyline sélectionnée.

Interactions non branchées :

- `Étapes`
- `Scènes`
- `Statistiques`
- `Tests`

Ces tabs restent visibles mais ne changent pas la vue active et ne mutent rien.

## 6. Chapter selection behavior

La sélection chapitre reste locale à `_StorylineChaptersSection`.

Quand la storyline change :

- `storyId` change ;
- `_selectedChapterId` est remis à `null` ;
- la sélection effective retombe sur le premier chapitre réel disponible de la nouvelle storyline ;
- aucun chapitre de l'ancienne storyline ne reste affiché dans l'inspecteur chapitre.

## 7. Disabled actions behavior

Actions futures conservées disabled / non mutantes :

- `Nouvelle storyline`
- `Valider`
- `+`
- `Nouveau chapitre`
- recherche du panneau secondaire

Aucun flow de création, édition, suppression, drag/drop, validation globale, mini-map active, zoom actif ou réorganisation n'a été ajouté.

## 8. V1 Creation Readiness

NS-STORYLINES-11 prépare la suite V1 uniquement par documentation.

Pré-requis pour créer une storyline principale :

- décider si la source durable est un `StorylineAsset` dédié ou un `ScenarioAsset` enrichi ;
- décider la règle d'unicité de la storyline principale ;
- définir un flow auteur no-code avec titre, type, description, validation anti-duplicate et preview ;
- définir la compatibilité/migration avec `ScenarioAsset globalStory` actuel.

Pré-requis pour créer une quête annexe :

- disposer d'un type explicite `sideQuest` ou équivalent ;
- définir son lien optionnel avec une storyline principale ;
- définir sa représentation graph et inspecteur ;
- valider que ses chapters/steps sont cohérents.

Pourquoi `localEventFlow` ne suffit pas :

- `localEventFlow` représente un flow local de scénario, pas une intention produit de quête ;
- il ne porte pas de type storyline, statut, ownership, règle d'affichage ou contrat de graph ;
- le promouvoir par défaut créerait des quêtes annexes fake.

Suite documentaire proposée :

- `NS-STORYLINES-V1-00 — Storyline Creation Product Contract`
- `NS-STORYLINES-V1-01 — Storyline Authoring Model Decision`
- `NS-STORYLINES-V1-02 — Create Main Storyline Flow`
- `NS-STORYLINES-V1-03 — Create Side Quest Storyline Flow`
- `NS-STORYLINES-V1-04 — Storyline Type / Status / Validation`
- `NS-STORYLINES-V1-05 — Side Quest Graph Integration`

## 9. Data source / anti-fake guarantees

Données utilisées :

- `NarrativeScenarioSummary.id`
- `NarrativeScenarioSummary.name`
- `NarrativeScenarioSummary.description`
- `NarrativeChapterSummary`
- `NarrativeStepSummary`
- compteurs réels déjà dérivés par la projection
- empty states honnêtes
- disabled feature reasons

Garanties :

- aucune chaîne cible Selbrume n'est utilisée comme donnée positive ;
- aucun chiffre cible n'est hardcodé ;
- aucun `localEventFlow` ne devient storyline, quête annexe, node, chapitre ou donnée d'inspecteur ;
- aucune quête annexe fake n'est créée ;
- aucun tag/world rule/fact/activité récente réel n'est inventé.

## 10. Design System Gate

Mini audit :

- Aucun `Color(0x...)` ajouté.
- Aucun `Colors.*` ajouté.
- Aucun nouveau bouton custom local.
- Aucun nouveau panel/table/status générique local.
- Les composants modifiés restent feature-specific Storylines.
- Le câblage passe par `PokeMapCard.onTap`, `PokeMapButton`, `PokeMapPanel`, `PokeMapPageSurface`, `PokeMapStatusTile`, `PokeMapSegmentedTabs` et `context.pokeMapColors`.

Recherche `Color(0x...) / Colors.*` :

```text
Commande : rg "Color\(0x|Colors\." packages/map_editor/lib/src/ui/canvas/storylines_workspace.dart packages/map_editor/test/storylines_workspace_shell_test.dart packages/map_editor/test/narrative_workspace_projection_test.dart packages/map_editor/test/storylines_current_global_story_characterization_test.dart
Sortie : <vide>
```

## 11. Tests added or modified

Tests modifiés dans `packages/map_editor/test/storylines_workspace_shell_test.dart` :

- ajout du test `selects a real global story from the secondary panel and syncs read-only zones` ;
- vérification de la sélection par défaut ;
- vérification du clic sur `audit_second_global_story` ;
- vérification de la synchronisation header / KPI / graph / inspector / Chapitres ;
- vérification de la non-mutation projet et état persistant ;
- vérification de la navigation `Graph` / `Chapitres` après sélection ;
- vérification que les tabs futures restent non mutantes ;
- Visual Gate NS11 : trois captures interaction.

Test TDD rouge observé avant implémentation :

```text
Expected: exactly one matching candidate
  Actual: _KeyWidgetFinder:<Found 0 widgets with key
[<'storylines-secondary-selected-audit_global_story'>]: []>
```

## 12. Visual Gate

Captures produites :

- `reports/narrativeStudio/storylines/screenshots/ns_storylines_11_interaction_default_graph.png`
- `reports/narrativeStudio/storylines/screenshots/ns_storylines_11_interaction_selected_story_graph.png`
- `reports/narrativeStudio/storylines/screenshots/ns_storylines_11_interaction_selected_story_chapters.png`

Résultats :

```text
68155 reports/narrativeStudio/storylines/screenshots/ns_storylines_11_interaction_default_graph.png
67593 reports/narrativeStudio/storylines/screenshots/ns_storylines_11_interaction_selected_story_graph.png
66003 reports/narrativeStudio/storylines/screenshots/ns_storylines_11_interaction_selected_story_chapters.png
201751 total
```

SHA-256 :

```text
f7b3224c98207fd9ed6115e6bb2185db7ab0104302283a245e70a74ce4d4fa70  reports/narrativeStudio/storylines/screenshots/ns_storylines_11_interaction_default_graph.png
4099e5e3c3c5f7fe190ee3e05332087b796aaf2a1089e7b6c43d55303e790719  reports/narrativeStudio/storylines/screenshots/ns_storylines_11_interaction_selected_story_graph.png
aa707fdd81f13975d80fae673115550bb0d2ddd33c876942eaf3ded515651d1d  reports/narrativeStudio/storylines/screenshots/ns_storylines_11_interaction_selected_story_chapters.png
```

## 13. Roadmap update

`reports/narrativeStudio/storylines/road_map_storylines.md` a été mis à jour :

- `NS-STORYLINES-11` marqué `DONE`.
- Current lot passé à `NS-STORYLINES-11`.
- Prochain lot recommandé : `NS-STORYLINES-CHECKPOINT — Storylines V0 Acceptance Checkpoint`.
- Changelog NS11 ajouté.
- Section `V1 Creation Readiness Notes` ajoutée.
- Design System Gate, anti-fake et captures Visual Gate documentés.

## 14. Commands run

Commandes initiales :

```text
git branch --show-current
git status --short --untracked-files=all
git diff --stat
git diff --name-only
git diff --check
```

Commandes de développement et vérification :

```text
dart format lib/src/ui/canvas/storylines_workspace.dart test/storylines_workspace_shell_test.dart
cd packages/map_editor && flutter test test/storylines_workspace_shell_test.dart --plain-name "selects a real global story"
cd packages/map_editor && flutter test --update-goldens test/storylines_workspace_shell_test.dart
cd packages/map_editor && flutter test test/storylines_workspace_shell_test.dart
cd packages/map_editor && flutter test test/narrative_workspace_projection_test.dart
cd packages/map_editor && flutter analyze --no-fatal-infos lib/src/ui/canvas/storylines_workspace.dart test/storylines_workspace_shell_test.dart test/storylines_current_global_story_characterization_test.dart test/narrative_workspace_projection_test.dart
cd packages/map_editor && flutter test test/storylines_current_global_story_characterization_test.dart
rg "Color\(0x|Colors\." packages/map_editor/lib/src/ui/canvas/storylines_workspace.dart packages/map_editor/test/storylines_workspace_shell_test.dart packages/map_editor/test/narrative_workspace_projection_test.dart packages/map_editor/test/storylines_current_global_story_characterization_test.dart
git status --short --untracked-files=all
git diff --stat
git diff --name-only
git diff --check
```

Note : une tentative parallèle de `flutter test test/storylines_current_global_story_characterization_test.dart` a échoué à cause du startup lock Flutter natif pendant qu'une autre commande Flutter tournait. La commande a été relancée seule ensuite et passe.

## 15. Evidence Pack

Git branch initiale :

```text
main
```

Git status initial exact :

```text
Sortie : <vide>
```

Git diff --stat initial :

```text
Sortie : <vide>
```

Git diff --name-only initial :

```text
Sortie : <vide>
```

Git diff --check initial :

```text
Sortie : <vide>
```

Liste des fichiers lus : voir section 2.

Liste des fichiers absents mais attendus :

```text
Sortie : <vide>
```

Git status final exact :

```text
 M packages/map_editor/lib/src/ui/canvas/storylines_workspace.dart
 M packages/map_editor/test/storylines_workspace_shell_test.dart
 M reports/narrativeStudio/storylines/road_map_storylines.md
?? reports/narrativeStudio/storylines/ns_storylines_11_interaction_wiring_v0.md
?? reports/narrativeStudio/storylines/screenshots/ns_storylines_11_interaction_default_graph.png
?? reports/narrativeStudio/storylines/screenshots/ns_storylines_11_interaction_selected_story_chapters.png
?? reports/narrativeStudio/storylines/screenshots/ns_storylines_11_interaction_selected_story_graph.png
```

Git diff --stat final :

```text
 .../lib/src/ui/canvas/storylines_workspace.dart    |  59 ++++-
 .../test/storylines_workspace_shell_test.dart      | 273 +++++++++++++++++----
 .../storylines/road_map_storylines.md              |  45 +++-
 3 files changed, 326 insertions(+), 51 deletions(-)
```

Git diff --name-only final :

```text
packages/map_editor/lib/src/ui/canvas/storylines_workspace.dart
packages/map_editor/test/storylines_workspace_shell_test.dart
reports/narrativeStudio/storylines/road_map_storylines.md
```

Git diff --check final :

```text
Sortie : <vide>
```

Contenu complet du rapport créé :

```text
Le contenu complet du rapport créé est le présent document, du titre "# NS-STORYLINES-11 — Storylines Interaction Wiring V0 / V1 Creation Readiness" jusqu'à la section "## 16. Self-review".
```

Contenu complet des fichiers créés :

```text
reports/narrativeStudio/storylines/ns_storylines_11_interaction_wiring_v0.md
Le contenu complet est le présent document.

reports/narrativeStudio/storylines/screenshots/ns_storylines_11_interaction_default_graph.png
PNG binaire, 68155 octets, sha256 f7b3224c98207fd9ed6115e6bb2185db7ab0104302283a245e70a74ce4d4fa70.

reports/narrativeStudio/storylines/screenshots/ns_storylines_11_interaction_selected_story_graph.png
PNG binaire, 67593 octets, sha256 4099e5e3c3c5f7fe190ee3e05332087b796aaf2a1089e7b6c43d55303e790719.

reports/narrativeStudio/storylines/screenshots/ns_storylines_11_interaction_selected_story_chapters.png
PNG binaire, 66003 octets, sha256 aa707fdd81f13975d80fae673115550bb0d2ddd33c876942eaf3ded515651d1d.
```

Diff complet des fichiers modifiés :

```diff
diff --git a/packages/map_editor/lib/src/ui/canvas/storylines_workspace.dart b/packages/map_editor/lib/src/ui/canvas/storylines_workspace.dart
index 81b45a54..8489a062 100644
--- a/packages/map_editor/lib/src/ui/canvas/storylines_workspace.dart
+++ b/packages/map_editor/lib/src/ui/canvas/storylines_workspace.dart
@@ -22,6 +22,21 @@ class StorylinesWorkspace extends StatefulWidget {
 
 class _StorylinesWorkspaceState extends State<StorylinesWorkspace> {
   _StorylineContentTab _selectedTab = _StorylineContentTab.graph;
+  String? _selectedGlobalStoryId;
+
+  @override
+  void didUpdateWidget(covariant StorylinesWorkspace oldWidget) {
+    super.didUpdateWidget(oldWidget);
+    final localSelection = _selectedGlobalStoryId;
+    if (localSelection == null) {
+      return;
+    }
+    final stillExists = widget.projection.globalStories
+        .any((story) => story.id == localSelection);
+    if (!stillExists) {
+      _selectedGlobalStoryId = null;
+    }
+  }
 
   @override
   Widget build(BuildContext context) {
@@ -60,6 +75,7 @@ class _StorylinesWorkspaceState extends State<StorylinesWorkspace> {
               stories: widget.projection.globalStories,
               selectedStoryId: selectedStory?.id,
               stepCountsByStoryId: stepCountsByStoryId,
+              onStorySelected: _selectStory,
             ),
           ),
           const SizedBox(width: 12),
@@ -91,8 +107,10 @@ class _StorylinesWorkspaceState extends State<StorylinesWorkspace> {
   }
 
   NarrativeScenarioSummary? get _selectedStory {
+    final targetStoryId =
+        _selectedGlobalStoryId ?? widget.selectedGlobalStoryId;
     for (final story in widget.projection.globalStories) {
-      if (story.id == widget.selectedGlobalStoryId) {
+      if (story.id == targetStoryId) {
         return story;
       }
     }
@@ -109,6 +127,15 @@ class _StorylinesWorkspaceState extends State<StorylinesWorkspace> {
       _selectedTab = tab;
     });
   }
+
+  void _selectStory(NarrativeScenarioSummary story) {
+    if (_selectedStory?.id == story.id) {
+      return;
+    }
+    setState(() {
+      _selectedGlobalStoryId = story.id;
+    });
+  }
 }
 
 class _StorylinesSecondaryPanel extends StatelessWidget {
@@ -116,11 +143,13 @@ class _StorylinesSecondaryPanel extends StatelessWidget {
     required this.stories,
     required this.selectedStoryId,
     required this.stepCountsByStoryId,
+    required this.onStorySelected,
   });
 
   final List<NarrativeScenarioSummary> stories;
   final String? selectedStoryId;
   final Map<String, int> stepCountsByStoryId;
+  final ValueChanged<NarrativeScenarioSummary> onStorySelected;
 
   @override
   Widget build(BuildContext context) {
@@ -190,6 +219,7 @@ class _StorylinesSecondaryPanel extends StatelessWidget {
                     story: story,
                     selected: story.id == selectedStoryId,
                     stepCount: stepCountsByStoryId[story.id] ?? 0,
+                    onTap: () => onStorySelected(story),
                   ),
                 ),
               ),
@@ -250,19 +280,22 @@ class _StorylineSummaryRow extends StatelessWidget {
     required this.story,
     required this.selected,
     required this.stepCount,
+    required this.onTap,
   });
 
   final NarrativeScenarioSummary story;
   final bool selected;
   final int stepCount;
+  final VoidCallback onTap;
 
   @override
   Widget build(BuildContext context) {
     final colors = context.pokeMapColors;
     final description = story.description.trim();
-    return PokeMapCard(
+    final card = PokeMapCard(
       key: ValueKey('storylines-secondary-row-${story.id}'),
       selected: selected,
+      onTap: onTap,
       padding: const EdgeInsets.all(10),
       child: Row(
         crossAxisAlignment: CrossAxisAlignment.start,
@@ -333,6 +366,13 @@ class _StorylineSummaryRow extends StatelessWidget {
         ],
       ),
     );
+    if (!selected) {
+      return card;
+    }
+    return KeyedSubtree(
+      key: ValueKey('storylines-secondary-selected-${story.id}'),
+      child: card,
+    );
   }
 
   static String _formatStepCount(int count) {
@@ -390,7 +430,10 @@ class _StorylineMainPanel extends StatelessWidget {
           const SizedBox(height: 16),
           Expanded(
             child: selectedTab == _StorylineContentTab.chapters
-                ? _StorylineChaptersSection(chapters: chapters)
+                ? _StorylineChaptersSection(
+                    storyId: selectedStory?.id,
+                    chapters: chapters,
+                  )
                 : _StorylineGraphSection(
                     chapters: chapters,
                     steps: steps,
@@ -1392,9 +1435,11 @@ class _StorylineGraphEmptyState extends StatelessWidget {
 
 class _StorylineChaptersSection extends StatefulWidget {
   const _StorylineChaptersSection({
+    required this.storyId,
     required this.chapters,
   });
 
+  final String? storyId;
   final List<NarrativeChapterSummary> chapters;
 
   @override
@@ -1405,6 +1450,14 @@ class _StorylineChaptersSection extends StatefulWidget {
 class _StorylineChaptersSectionState extends State<_StorylineChaptersSection> {
   String? _selectedChapterId;
 
+  @override
+  void didUpdateWidget(covariant _StorylineChaptersSection oldWidget) {
+    super.didUpdateWidget(oldWidget);
+    if (oldWidget.storyId != widget.storyId) {
+      _selectedChapterId = null;
+    }
+  }
+
   NarrativeChapterSummary? get _selectedChapter {
     if (widget.chapters.isEmpty) {
       return null;
diff --git a/packages/map_editor/test/storylines_workspace_shell_test.dart b/packages/map_editor/test/storylines_workspace_shell_test.dart
index bd9485ce..ab343579 100644
--- a/packages/map_editor/test/storylines_workspace_shell_test.dart
+++ b/packages/map_editor/test/storylines_workspace_shell_test.dart
@@ -14,7 +14,7 @@ import 'package:map_editor/src/ui/canvas/narrative_workspace_canvas.dart';
 import 'package:map_editor/src/ui/design_system/design_system.dart';
 
 void main() {
-  group('NS-STORYLINES-10 Visual harmonization / visual gate V0', () {
+  group('NS-STORYLINES-11 Interaction wiring V0', () {
     testWidgets(
       'renders a read-only three-pane shell from real global story data',
       (tester) async {
@@ -272,6 +272,206 @@ void main() {
       },
     );
 
+    testWidgets(
+      'selects a real global story from the secondary panel and syncs read-only zones',
+      (tester) async {
+        final harness = await _pumpStorylinesShell(tester);
+        final beforeEditorState =
+            harness.container.read(editorNotifierProvider);
+        final beforeNarrativeState =
+            harness.container.read(narrativeWorkspaceControllerProvider);
+        final beforeProject = beforeEditorState.project!;
+        final beforeScenarioIds = beforeProject.scenarios
+            .map((scenario) => scenario.id)
+            .toList(growable: false);
+
+        expect(
+          find.byKey(
+            const ValueKey('storylines-secondary-selected-audit_global_story'),
+          ),
+          findsOneWidget,
+        );
+
+        await _selectSecondaryStory(tester, 'audit_second_global_story');
+
+        final header = find.byKey(const ValueKey('storylines-header-section'));
+        final graph =
+            find.byKey(const ValueKey('storylines-graph-target-read-only'));
+        final inspector =
+            find.byKey(const ValueKey('storylines-inspector-read-only'));
+
+        expect(
+          find.byKey(
+            const ValueKey(
+              'storylines-secondary-selected-audit_second_global_story',
+            ),
+          ),
+          findsOneWidget,
+        );
+        expect(
+          find.descendant(
+            of: header,
+            matching: find.text('Audit Second Story From Scenario'),
+          ),
+          findsOneWidget,
+        );
+        expect(
+          find.descendant(
+            of: header,
+            matching: find.text('Audit second description from scenario'),
+          ),
+          findsOneWidget,
+        );
+        expect(
+          find.descendant(
+            of: inspector,
+            matching: find.text('Audit Second Story From Scenario'),
+          ),
+          findsOneWidget,
+        );
+        expect(
+          find.descendant(
+            of: inspector,
+            matching: find.text('1 étape narrative'),
+          ),
+          findsOneWidget,
+        );
+        expect(
+          find.descendant(
+            of: graph,
+            matching: find.text('Audit Second Chapter From Metadata'),
+          ),
+          findsOneWidget,
+        );
+        expect(
+          find.descendant(
+            of: graph,
+            matching: find.text('Audit Second Step From Metadata'),
+          ),
+          findsOneWidget,
+        );
+        expect(
+          find.descendant(
+            of: graph,
+            matching: find.text('Audit Chapter From Metadata'),
+          ),
+          findsNothing,
+        );
+        expect(
+          find.descendant(
+            of: graph,
+            matching: find.text('Audit Step From Metadata'),
+          ),
+          findsNothing,
+        );
+        expect(
+          find.descendant(
+            of: find.byKey(const ValueKey('storylines-kpi-steps')),
+            matching: find.text('1'),
+          ),
+          findsOneWidget,
+        );
+
+        await _openChaptersTab(tester);
+
+        final chapters =
+            find.byKey(const ValueKey('storylines-chapters-read-only'));
+        final chapterInspector =
+            find.byKey(const ValueKey('storylines-chapter-inspector'));
+        expect(chapters, findsOneWidget);
+        expect(
+          find.descendant(
+            of: chapters,
+            matching: find.text('Audit Second Chapter From Metadata'),
+          ),
+          findsWidgets,
+        );
+        expect(
+          find.descendant(
+            of: chapters,
+            matching: find.text('Audit Chapter From Metadata'),
+          ),
+          findsNothing,
+        );
+        expect(
+          find.byKey(
+            const ValueKey('storylines-selected-chapter-audit_second_chapter'),
+          ),
+          findsOneWidget,
+        );
+        expect(
+          find.descendant(
+            of: chapterInspector,
+            matching: find.text('Audit Second Step From Metadata'),
+          ),
+          findsOneWidget,
+        );
+
+        await _openGraphTab(tester);
+
+        expect(
+          find.byKey(const ValueKey('storylines-graph-target-read-only')),
+          findsOneWidget,
+        );
+        expect(
+          find.descendant(
+            of: header,
+            matching: find.text('Audit Second Story From Scenario'),
+          ),
+          findsOneWidget,
+        );
+
+        for (final label in <String>[
+          'Étapes',
+          'Scènes',
+          'Statistiques',
+          'Tests',
+        ]) {
+          await tester.tap(
+            find.descendant(
+              of: find.byKey(const ValueKey('storylines-tabs')),
+              matching: find.text(label),
+            ),
+          );
+          await tester.pump();
+        }
+
+        expect(
+          find.byKey(const ValueKey('storylines-graph-target-read-only')),
+          findsOneWidget,
+        );
+        expect(
+          find.descendant(
+            of: header,
+            matching: find.text('Audit Second Story From Scenario'),
+          ),
+          findsOneWidget,
+        );
+
+        final afterEditorState = harness.container.read(editorNotifierProvider);
+        final afterNarrativeState =
+            harness.container.read(narrativeWorkspaceControllerProvider);
+
+        expect(afterEditorState.workspaceMode, beforeEditorState.workspaceMode);
+        expect(afterEditorState.project, same(beforeProject));
+        expect(
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
+        );
+        expect(find.text('Audit Local Event Flow'), findsNothing);
+      },
+    );
+
     testWidgets(
       'renders an honest empty state when the selected global story has no steps',
       (tester) async {
@@ -764,31 +964,7 @@ void main() {
         find.byKey(const ValueKey('storylines-workspace-shell')),
         matchesGoldenFile(
           '../../../reports/narrativeStudio/storylines/screenshots/'
-          'ns_storylines_10_graph_desktop.png',
-        ),
-      );
-
-      await _pumpStorylinesShell(
-        tester,
-        surfaceSize: const Size(1600, 700),
-      );
-      await expectLater(
-        find.byKey(const ValueKey('storylines-graph-target-read-only')),
-        matchesGoldenFile(
-          '../../../reports/narrativeStudio/storylines/screenshots/'
-          'ns_storylines_10_graph_focus.png',
-        ),
-      );
-
-      await _pumpStorylinesShell(
-        tester,
-        surfaceSize: const Size(1180, 1000),
-      );
-      await expectLater(
-        find.byKey(const ValueKey('storylines-graph-target-read-only')),
-        matchesGoldenFile(
-          '../../../reports/narrativeStudio/storylines/screenshots/'
-          'ns_storylines_10_graph_center.png',
+          'ns_storylines_11_interaction_default_graph.png',
         ),
       );
 
@@ -796,38 +972,26 @@ void main() {
         tester,
         surfaceSize: const Size(1600, 1000),
       );
-      await _openChaptersTab(tester);
+      await _selectSecondaryStory(tester, 'audit_second_global_story');
       await expectLater(
         find.byKey(const ValueKey('storylines-workspace-shell')),
         matchesGoldenFile(
           '../../../reports/narrativeStudio/storylines/screenshots/'
-          'ns_storylines_10_chapters_desktop.png',
-        ),
-      );
-
-      await _pumpStorylinesShell(
-        tester,
-        surfaceSize: const Size(1600, 700),
-      );
-      await _openChaptersTab(tester);
-      await expectLater(
-        find.byKey(const ValueKey('storylines-chapters-read-only')),
-        matchesGoldenFile(
-          '../../../reports/narrativeStudio/storylines/screenshots/'
-          'ns_storylines_10_chapters_focus.png',
+          'ns_storylines_11_interaction_selected_story_graph.png',
         ),
       );
 
       await _pumpStorylinesShell(
         tester,
-        surfaceSize: const Size(1180, 1000),
+        surfaceSize: const Size(1600, 1000),
       );
+      await _selectSecondaryStory(tester, 'audit_second_global_story');
       await _openChaptersTab(tester);
       await expectLater(
-        find.byKey(const ValueKey('storylines-chapters-read-only')),
+        find.byKey(const ValueKey('storylines-workspace-shell')),
         matchesGoldenFile(
           '../../../reports/narrativeStudio/storylines/screenshots/'
-          'ns_storylines_10_chapters_center.png',
+          'ns_storylines_11_interaction_selected_story_chapters.png',
         ),
       );
     });
@@ -885,6 +1049,27 @@ Future<void> _openChaptersTab(WidgetTester tester) async {
   await tester.pump();
 }
 
+Future<void> _openGraphTab(WidgetTester tester) async {
+  await tester.tap(
+    find.descendant(
+      of: find.byKey(const ValueKey('storylines-tabs')),
+      matching: find.text('Graph'),
+    ),
+  );
+  await tester.pump();
+}
+
+Future<void> _selectSecondaryStory(
+  WidgetTester tester,
+  String storyId,
+) async {
+  final row = find.byKey(ValueKey('storylines-secondary-row-$storyId'));
+  await tester.ensureVisible(row);
+  await tester.pump();
+  await tester.tap(row);
+  await tester.pump();
+}
+
 Future<_StorylinesHarness> _pumpStorylinesShell(
   WidgetTester tester, {
   Size surfaceSize = const Size(1600, 1000),
diff --git a/reports/narrativeStudio/storylines/road_map_storylines.md b/reports/narrativeStudio/storylines/road_map_storylines.md
index 50c4adb8..b79210a2 100644
--- a/reports/narrativeStudio/storylines/road_map_storylines.md
+++ b/reports/narrativeStudio/storylines/road_map_storylines.md
@@ -717,9 +717,9 @@ Décision temporaire :
 
 ```text
 Roadmap status: ACTIVE
-Current lot: NS-STORYLINES-10
+Current lot: NS-STORYLINES-11
 Current lot status: DONE
-Next recommended lot: NS-STORYLINES-11 — Storylines Interaction Wiring V0
+Next recommended lot: NS-STORYLINES-CHECKPOINT — Storylines V0 Acceptance Checkpoint
 ```
 
 | Lot | Status | Last update | Notes |
@@ -736,10 +736,47 @@ Next recommended lot: NS-STORYLINES-11 — Storylines Interaction Wiring V0
 | NS-STORYLINES-08 | DONE | 2026-05-28 | Onglet Chapitres read-only livré ; bis Graph target alignment et ter canvas spatial livrés sans changer le statut NS08. |
 | NS-STORYLINES-09 | DONE | 2026-05-28 | Chapters inspector / step ordering read-only livré sans scène fake. |
 | NS-STORYLINES-10 | DONE | 2026-05-28 | Visual harmonization Graph/Chapitres et Visual Gate complet livrés sans nouvelle feature. |
-| NS-STORYLINES-11 | TODO | 2026-05-27 | Interaction wiring. |
+| NS-STORYLINES-11 | DONE | 2026-05-28 | Interaction wiring V0 livré : sélection locale de globalStory existante, synchronisation zones read-only, actions futures non mutantes, notes V1 Creation Readiness. |
 | NS-STORYLINES-CHECKPOINT | TODO | 2026-05-27 | Acceptance checkpoint. |
 
-## 14. Changelog
+## 14. V1 Creation Readiness Notes
+
+NS-STORYLINES-11 reste un lot V0 : aucune création de storyline, aucun `StorylineAsset`, aucune quête annexe fake et aucune mutation projet.
+
+Pré-requis recommandés pour activer la création Storylines V1 :
+
+- Décision modèle : choisir entre un `StorylineAsset` dédié ou un `ScenarioAsset` enrichi, avec contrat editor/runtime explicite.
+- Types de storyline : prévoir au minimum `main`, `sideQuest`, `tutorial`, `epilogue`, `episode`, sans les inférer depuis `localEventFlow`.
+- Storyline principale : définir une règle d'unicité éventuelle, le comportement si une principale existe déjà, et le flow de remplacement ou migration.
+- Flow auteur : création no-code guidée avec titre, type, source, chapitre initial éventuel, validation immédiate et preview read-only avant sauvegarde.
+- Validation anti-duplicate : empêcher les ids/titres conflictuels, les types incompatibles et les liens de steps orphelins.
+- Compatibilité : décider comment migrer ou projeter le `ScenarioAsset globalStory` actuel sans casser les projets existants.
+- Quêtes annexes : les afficher uniquement quand le modèle existe ; `localEventFlow` ne suffit pas et ne doit jamais devenir une quête annexe par défaut.
+- Boutons activables plus tard : `Nouvelle storyline`, `+`, `Nouveau chapitre`, validation narrative et création de quête annexe après contrat modèle + tests anti-fake.
+
+Suite V1 documentaire possible, sans démarrage dans V0 :
+
+- `NS-STORYLINES-V1-00 — Storyline Creation Product Contract`
+- `NS-STORYLINES-V1-01 — Storyline Authoring Model Decision`
+- `NS-STORYLINES-V1-02 — Create Main Storyline Flow`
+- `NS-STORYLINES-V1-03 — Create Side Quest Storyline Flow`
+- `NS-STORYLINES-V1-04 — Storyline Type / Status / Validation`
+- `NS-STORYLINES-V1-05 — Side Quest Graph Integration`
+
+## 15. Changelog
+
+### 2026-05-28 — NS-STORYLINES-11
+
+- Câblage d'une sélection locale de `globalStory` existante depuis le panneau secondaire Storylines.
+- Synchronisation read-only du header, des KPI dérivés, du graph, de l'inspecteur Storyline et de la tab `Chapitres` avec la storyline sélectionnée.
+- Conservation des tabs réellement branchées à `Graph` / `Chapitres`; `Étapes`, `Scènes`, `Statistiques`, `Tests` restent non mutantes.
+- Réinitialisation prudente de la sélection de chapitre lorsque la storyline effective change.
+- Actions futures conservées disabled / non mutantes : `Nouvelle storyline`, `Valider`, `+`, `Nouveau chapitre`, recherche.
+- Visual Gate dark interaction produit : `ns_storylines_11_interaction_default_graph.png`, `ns_storylines_11_interaction_selected_story_graph.png`, `ns_storylines_11_interaction_selected_story_chapters.png`.
+- Design System Gate confirmé : aucun `Color(0x...)` / `Colors.*` ajouté ; wiring via primitives PokeMap existantes.
+- Fake data : aucune donnée cible Selbrume, aucune quête annexe fake, aucun `localEventFlow` promu en storyline/quête/chapter/node.
+- V1 Creation Readiness documenté : modèle, types, unicité, flow auteur, validation et migration à décider avant création.
+- Prochain lot recommandé : `NS-STORYLINES-CHECKPOINT — Storylines V0 Acceptance Checkpoint`.
 
 ### 2026-05-28 — NS-STORYLINES-10
```

Sortie exacte de `flutter test test/storylines_workspace_shell_test.dart` :

```text
00:00 +0: NS-STORYLINES-11 Interaction wiring V0 renders a read-only three-pane shell from real global story data
[step_studio_trace] action=apply_document scenario=audit_global_story rows=[]
[step_studio_trace] action=apply_document_metadata scenario=audit_global_story contains_emma=false contains_empty_entity=false
[step_studio_trace] action=apply_document scenario=audit_second_global_story rows=[]
[step_studio_trace] action=apply_document_metadata scenario=audit_second_global_story contains_emma=false contains_empty_entity=false
00:00 +1: NS-STORYLINES-11 Interaction wiring V0 selects a real global story from the secondary panel and syncs read-only zones
[step_studio_trace] action=apply_document scenario=audit_global_story rows=[]
[step_studio_trace] action=apply_document_metadata scenario=audit_global_story contains_emma=false contains_empty_entity=false
[step_studio_trace] action=apply_document scenario=audit_second_global_story rows=[]
[step_studio_trace] action=apply_document_metadata scenario=audit_second_global_story contains_emma=false contains_empty_entity=false
00:00 +2: NS-STORYLINES-11 Interaction wiring V0 renders an honest empty state when the selected global story has no steps
[step_studio_trace] action=apply_document scenario=audit_empty_global_story rows=[]
[step_studio_trace] action=apply_document_metadata scenario=audit_empty_global_story contains_emma=false contains_empty_entity=false
00:01 +3: NS-STORYLINES-11 Interaction wiring V0 shows the Chapters tab from Global Story Studio metadata read-only
[step_studio_trace] action=apply_document scenario=audit_global_story rows=[]
[step_studio_trace] action=apply_document_metadata scenario=audit_global_story contains_emma=false contains_empty_entity=false
[step_studio_trace] action=apply_document scenario=audit_second_global_story rows=[]
[step_studio_trace] action=apply_document_metadata scenario=audit_second_global_story contains_emma=false contains_empty_entity=false
00:01 +4: NS-STORYLINES-11 Interaction wiring V0 shows an honest Chapters empty state
[step_studio_trace] action=apply_document scenario=audit_empty_global_story rows=[]
[step_studio_trace] action=apply_document_metadata scenario=audit_empty_global_story contains_emma=false contains_empty_entity=false
00:01 +5: NS-STORYLINES-11 Interaction wiring V0 renders an honest inspector empty state without global story
00:01 +6: NS-STORYLINES-11 Interaction wiring V0 keeps future Storyline tabs read-only and non-mutating
[step_studio_trace] action=apply_document scenario=audit_global_story rows=[]
[step_studio_trace] action=apply_document_metadata scenario=audit_global_story contains_emma=false contains_empty_entity=false
[step_studio_trace] action=apply_document scenario=audit_second_global_story rows=[]
[step_studio_trace] action=apply_document_metadata scenario=audit_second_global_story contains_emma=false contains_empty_entity=false
00:01 +7: NS-STORYLINES-11 Interaction wiring V0 keeps future header actions disabled and non-mutating
[step_studio_trace] action=apply_document scenario=audit_global_story rows=[]
[step_studio_trace] action=apply_document_metadata scenario=audit_global_story contains_emma=false contains_empty_entity=false
[step_studio_trace] action=apply_document scenario=audit_second_global_story rows=[]
[step_studio_trace] action=apply_document_metadata scenario=audit_second_global_story contains_emma=false contains_empty_entity=false
00:01 +8: NS-STORYLINES-11 Interaction wiring V0 storylines UI source keeps raw colors out of the feature
00:01 +9: NS-STORYLINES-11 Interaction wiring V0 storylines action test does not use silent taps
00:01 +10: NS-STORYLINES-11 Interaction wiring V0 uses PokeMap dark theme in the Visual Gate harness
[step_studio_trace] action=apply_document scenario=audit_global_story rows=[]
[step_studio_trace] action=apply_document_metadata scenario=audit_global_story contains_emma=false contains_empty_entity=false
[step_studio_trace] action=apply_document scenario=audit_second_global_story rows=[]
[step_studio_trace] action=apply_document_metadata scenario=audit_second_global_story contains_emma=false contains_empty_entity=false
00:01 +11: NS-STORYLINES-11 Interaction wiring V0 writes Visual Gate screenshots
[step_studio_trace] action=apply_document scenario=audit_global_story rows=[]
[step_studio_trace] action=apply_document_metadata scenario=audit_global_story contains_emma=false contains_empty_entity=false
[step_studio_trace] action=apply_document scenario=audit_second_global_story rows=[]
[step_studio_trace] action=apply_document_metadata scenario=audit_second_global_story contains_emma=false contains_empty_entity=false
[step_studio_trace] action=apply_document scenario=audit_global_story rows=[]
[step_studio_trace] action=apply_document_metadata scenario=audit_global_story contains_emma=false contains_empty_entity=false
[step_studio_trace] action=apply_document scenario=audit_second_global_story rows=[]
[step_studio_trace] action=apply_document_metadata scenario=audit_second_global_story contains_emma=false contains_empty_entity=false
[step_studio_trace] action=apply_document scenario=audit_global_story rows=[]
[step_studio_trace] action=apply_document_metadata scenario=audit_global_story contains_emma=false contains_empty_entity=false
[step_studio_trace] action=apply_document scenario=audit_second_global_story rows=[]
[step_studio_trace] action=apply_document_metadata scenario=audit_second_global_story contains_emma=false contains_empty_entity=false
00:02 +12: All tests passed!
```

Sortie exacte de `flutter test test/storylines_current_global_story_characterization_test.dart` :

```text
00:00 +0: NS-STORYLINES-02 current Global Story characterization renders the current Storylines shell from manifest and authoring metadata
[step_studio_trace] action=apply_document scenario=audit_global_story rows=[]
[step_studio_trace] action=apply_document_metadata scenario=audit_global_story contains_emma=false contains_empty_entity=false
00:00 +1: NS-STORYLINES-02 current Global Story characterization keeps globalStory and localEventFlow separated in the current projection
[step_studio_trace] action=apply_document scenario=audit_global_story rows=[]
[step_studio_trace] action=apply_document_metadata scenario=audit_global_story contains_emma=false contains_empty_entity=false
00:00 +2: All tests passed!
```

Sortie exacte de `flutter test test/narrative_workspace_projection_test.dart` :

```text
00:00 +0: buildNarrativeWorkspaceProjection splits global story and local flows, and projects steps
00:00 +1: buildNarrativeWorkspaceProjection projects ordered steps from Step Studio v1 metadata document
00:00 +2: buildNarrativeWorkspaceProjection projects chapters from Global Story Studio metadata
00:00 +3: All tests passed!
```

Sortie exacte de l'analyse ciblée :

```text
Analyzing 4 items...                                            
No issues found! (ran in 5.8s)
```

Résultats du Visual Gate :

```text
cd packages/map_editor && flutter test --update-goldens test/storylines_workspace_shell_test.dart
00:02 +12: All tests passed!

Captures :
reports/narrativeStudio/storylines/screenshots/ns_storylines_11_interaction_default_graph.png
reports/narrativeStudio/storylines/screenshots/ns_storylines_11_interaction_selected_story_graph.png
reports/narrativeStudio/storylines/screenshots/ns_storylines_11_interaction_selected_story_chapters.png
```

Mini audit Design System :

```text
Aucun Color(0x...) / Colors.* dans les fichiers touchés.
Pas de bouton, panel, table ou design-system local générique ajouté.
Sélection secondaire câblée via PokeMapCard.onTap.
Boutons futurs conservés via PokeMapButton disabled.
```

Recherche Color(0x...) / Colors.* sur fichiers modifiés :

```text
Commande : rg "Color\(0x|Colors\." packages/map_editor/lib/src/ui/canvas/storylines_workspace.dart packages/map_editor/test/storylines_workspace_shell_test.dart packages/map_editor/test/narrative_workspace_projection_test.dart packages/map_editor/test/storylines_current_global_story_characterization_test.dart
Sortie : <vide>
```

Auto-review critique :

```text
- La sélection de storyline est locale au workspace Storylines, donc elle ne synchronise pas encore le contrôleur narratif global. C'est volontaire pour préserver la contrainte "aucune mutation persistante", mais un futur lot pourra décider de passer par NarrativeWorkspaceState si l'UX globale le demande.
- Les fixtures utilisent encore "Audit Second Chapter From Metadata" à la fois comme deuxième chapitre de la première story et comme chapitre de la seconde story. Les assertions évitent l'ambiguïté en vérifiant l'absence de "Audit Chapter From Metadata" et "Audit Step From Metadata" dans les zones dépendantes après sélection.
- Les screenshots Visual Gate sont des PNG binaires ; leur preuve est fournie par taille exacte et SHA-256.
```

## 16. Self-review

Critères relus :

- Sélection d'une `globalStory` existante depuis le panneau secondaire : couvert par test.
- Header / KPI / graph / inspector / Chapitres synchronisés : couvert par test.
- Aucune mutation `ProjectManifest` ou `ScenarioAsset` : projet identique et ids scénarios inchangés dans le test.
- `Graph` / `Chapitres` seuls branchés : couvert par test tabs futures.
- Sélection chapitre locale et reset au changement de story : implémenté par `storyId` + `didUpdateWidget`.
- Actions futures disabled / non mutantes : test existant conservé.
- `localEventFlow` jamais promu : tests anti-fake conservés.
- Maps absent : test existant conservé.
- Aucune donnée cible Selbrume : liste anti-fake conservée.
- Aucune création Storyline : aucun modèle, provider ou bouton de création activé.
- V1 Creation Readiness : roadmap + rapport.
- Aucun `Color(0x...)` / `Colors.*` : recherche vide.
- Tests ciblés et analyse : passés après relance séquentielle.
- Visual Gate interaction : trois captures NS11 produites.
- Prochain lot : `NS-STORYLINES-CHECKPOINT`.
