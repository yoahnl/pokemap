# NS-STORYLINES-V1-10 — Graph From StorylineAsset V0

## 1. Executive summary

NS-STORYLINES-V1-10 est livré. Le Graph Storylines affiche maintenant une vue read-only générée depuis la `StorylineAsset` sélectionnée : node racine storyline, nodes chapitres, steps regroupées dans leurs chapitres, grille spatiale et edges d'ordre auteur.

Structure reste la source d'authoring. Le graph ne crée aucune donnée. Les sideQuests restent autonomes : sélectionnées, elles ont leur propre graph ; depuis la main storyline, elles ne sont pas injectées comme branches.

## 2. Inputs read

Fichiers lus :

- `AGENTS.md`
- `agent_rules.md`
- `skills/README.md`
- `reports/narrativeStudio/storylines/road_map_storylines.md`
- `reports/narrativeStudio/storylines/ns_storylines_v1_09_create_side_quest_flow_v0.md`
- `packages/map_core/lib/src/models/storyline_asset.dart`
- `packages/map_core/lib/src/models/project_manifest.dart`
- `packages/map_core/lib/map_core.dart`
- `packages/map_editor/lib/src/ui/canvas/storylines_workspace.dart`
- `packages/map_editor/lib/src/ui/canvas/storylines/storylines_graph_model.dart`
- `packages/map_editor/lib/src/ui/canvas/storylines/storylines_graph_painter.dart`
- `packages/map_editor/lib/src/ui/canvas/storylines/storylines_graph_view.dart`
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
- `/Users/karim/.codex/skills/flutter-add-widget-test/SKILL.md`

Fichiers attendus mais absents :

- `reports/narrativeStudio/storylines/ns_storylines_v1_08_structure_tab_authoring_v0.md`
- `reports/narrativeStudio/storylines/ns_storylines_v1_07_bis_storylines_workspace_cleanup.md`
- `reports/narrativeStudio/storylines/ns_storylines_v1_07_create_main_storyline_flow_v0.md`
- `reports/narrativeStudio/storylines/ns_storylines_v1_03_storyline_asset_pure_model_v0.md`
- `reports/narrativeStudio/storylines/ns_storylines_v1_00_storyline_semantics_and_usable_authoring_contract.md`

## 3. Product problem addressed

Avant V1-10, le Graph affichait essentiellement une carte centrale avec un résumé. Il ne permettait pas encore de comprendre l'organisation réelle d'une storyline. Ce lot remplace cet état minimal par une projection visuelle des données auteur existantes : chapters, steps et ordre.

## 4. Implementation summary

- Extraction feature-specific sous `packages/map_editor/lib/src/ui/canvas/storylines/`.
- Ajout de `StorylineGraphViewModel` pour trier chapters/steps et exposer nodes/edges view-only.
- Ajout de `StorylinesGraphPainter` pour grille et edges d'ordre auteur.
- Ajout de `StorylinesGraphView` pour le canvas read-only, nodes, chips steps, légende et messages sideQuest.
- `storylines_workspace.dart` délègue le graph sélectionné à la vue extraite.
- Tests widget étendus pour nodes, edges, tri, sideQuest standalone, non-intégration sideQuest dans main graph et non-mutation.

## 5. Graph source of truth

La source du graph est la `StorylineAsset` sélectionnée depuis `ProjectManifest.storylines`.

Champs consommés : `id`, `type`, `status`, `title`, `description`, `chapters`, `chapter.id`, `chapter.title`, `chapter.description`, `chapter.order`, `chapter.steps`, `step.id`, `step.title`, `step.description`, `step.order`, `step.sceneLinkIds`, `step.expectedOutcomeIds`.

Le graph ne consomme pas `ScenarioAsset.globalStory`, `localEventFlow` ou la preview d'import legacy.

## 6. Graph node semantics

Nodes V1-10 :

- `storyline` : racine de la storyline sélectionnée, type, brouillon, compteurs réels chapters/steps.
- `chapter` : un node par chapter, trié par ordre auteur.
- `step` : chip dans son chapter, trié par ordre auteur, avec mention `Aucune scène liée` ou count réel de scene links.
- `emptyStepPlaceholder` : état honnête pour chapter sans step.

## 7. Graph edge semantics

Edges visibles V1-10 :

- racine -> premier chapter ;
- chapter N -> chapter N+1.

Ces edges signifient uniquement `ordre auteur`. Ils ne représentent pas condition runtime, branche narrative, outcome, disponibilité, prérequis ou convergence.

## 8. Main storyline graph behavior

Une main storyline sans chapter affiche le node racine et le message `Ajoutez un chapitre dans Structure`. Une main avec chapters/steps affiche les nodes réels, triés par `order`, puis titre/id en tie-breaker stable.

## 9. Side quest standalone graph behavior

Une sideQuest sélectionnée affiche son propre graph autonome avec badge `Quête annexe indépendante`, ses chapters et ses steps. La main storyline n'est pas affichée dans ce graph.

## 10. Main graph sideQuest non-integration guarantee

Quand la main storyline est sélectionnée et qu'une ou plusieurs sideQuests existent, le graph principal affiche seulement la main sélectionnée. Une note indique le nombre de quêtes annexes créées et que l'intégration viendra plus tard. Aucun node/edge sideQuest n'est dessiné dans le graph principal.

## 11. Structure source-of-authoring guarantee

Structure reste la seule source d'authoring de ce lot. Le Graph est read-only : il n'active ni édition, ni drag/drop, ni création de chapter/step/relationship/sceneLink.

## 12. Legacy non-import guarantee

Aucun import legacy automatique n'est ajouté. Les scénarios legacy restent intacts et ne génèrent pas le graph V1.

## 13. localEventFlow exclusion

`localEventFlow` n'apparaît pas comme Storyline, sideQuest, chapter, step, node ou edge. Les tests anti-fake et legacy/localEventFlow restent actifs.

## 14. Non-goals confirmed

Confirmé hors scope : aucun `map_core`, aucun runtime/gameplay/battle, aucun `StorylineRelationship`, aucune `SideQuestAvailability`, aucun scene placeholder, aucun `StorylineSceneLink`, aucune availability, aucune branche narrative fake, aucun zoom/minimap/éditeur de graph.

## 15. Design System Gate

Le graph utilise les primitives et tokens existants : `PokeMapCard`, `PokeMapIconTile`, `PokeMapTone`, `context.pokeMapColors`, et un `CustomPainter` feature-specific alimenté par les couleurs du thème.

Le `rg` anti-couleurs est vide.

## 16. Tests added or modified

Tests ajoutés/modifiés dans `packages/map_editor/test/storylines_workspace_shell_test.dart` :

- graph sans storyline : empty state, aucune node/canvas V1 ;
- main sans chapter : node racine + message Structure ;
- main avec chapters/steps : nodes chapter/step + edge root -> chapter ;
- tri stable chapters/steps par `order`, puis tie-breaker ;
- count réel de scene links sur une step ;
- sideQuest standalone : graph autonome sans main ;
- main graph avec sideQuest : note future, aucun node sideQuest dans le canvas ;
- non-mutation et anti-fake ;
- Visual Gate V1-10.

## 17. Visual Gate

Captures V1-10 générées :

```text
EXISTS reports/narrativeStudio/storylines/screenshots/ns_storylines_v1_10_graph_empty_storyline.png (42980 bytes)
EXISTS reports/narrativeStudio/storylines/screenshots/ns_storylines_v1_10_graph_main_chapters_steps.png (49729 bytes)
EXISTS reports/narrativeStudio/storylines/screenshots/ns_storylines_v1_10_graph_sidequest_standalone.png (47291 bytes)
EXISTS reports/narrativeStudio/storylines/screenshots/ns_storylines_v1_10_graph_main_ignores_sidequest.png (49729 bytes)
```

Commande de génération :

Commande : `cd packages/map_editor && flutter test --update-goldens test/storylines_workspace_shell_test.dart`

Exit code : `0`

```text
00:00 +0: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/storylines_workspace_shell_test.dart
00:00 +0: NS-STORYLINES-V1-10 graph from StorylineAsset flow shows only Graph and Structure tabs
00:00 +1: NS-STORYLINES-V1-10 graph from StorylineAsset flow shows V1 empty state without importing legacy globalStory
00:00 +2: NS-STORYLINES-V1-10 graph from StorylineAsset flow opens and cancels create main storyline dialog without mutation
00:00 +3: NS-STORYLINES-V1-10 graph from StorylineAsset flow requires title before create
00:00 +4: NS-STORYLINES-V1-10 graph from StorylineAsset flow does not create sideQuest before a main storyline exists
00:01 +5: NS-STORYLINES-V1-10 graph from StorylineAsset flow dialog selects sideQuest when a main storyline exists
00:01 +6: NS-STORYLINES-V1-10 graph from StorylineAsset flow creates a main StorylineAsset and syncs Graph and Structure
00:01 +7: NS-STORYLINES-V1-10 graph from StorylineAsset flow creates a sideQuest StorylineAsset and selects it
00:01 +8: NS-STORYLINES-V1-10 graph from StorylineAsset flow Structure without storyline has no chapter or step action
00:01 +9: NS-STORYLINES-V1-10 graph from StorylineAsset flow opens and cancels create chapter without mutation
00:01 +10: NS-STORYLINES-V1-10 graph from StorylineAsset flow requires chapter title before create
00:01 +11: NS-STORYLINES-V1-10 graph from StorylineAsset flow creates chapters with stable ids, order and selection
00:02 +12: NS-STORYLINES-V1-10 graph from StorylineAsset flow step action requires a selected chapter
00:02 +13: NS-STORYLINES-V1-10 graph from StorylineAsset flow opens and cancels create step without mutation
00:02 +14: NS-STORYLINES-V1-10 graph from StorylineAsset flow requires step title before create
00:02 +15: NS-STORYLINES-V1-10 graph from StorylineAsset flow creates steps with global unique ids and order
00:02 +16: NS-STORYLINES-V1-10 graph from StorylineAsset flow Structure authoring works on sideQuest without mutating main
00:02 +17: NS-STORYLINES-V1-10 graph from StorylineAsset flow Graph summarizes created structure without fake edges
00:03 +18: NS-STORYLINES-V1-10 graph from StorylineAsset flow Graph orders chapters and steps by author order
00:03 +19: NS-STORYLINES-V1-10 graph from StorylineAsset flow Graph explains sideQuest is not linked to main graph yet
00:03 +20: NS-STORYLINES-V1-10 graph from StorylineAsset flow main graph does not show sideQuest as a branch yet
00:03 +21: NS-STORYLINES-V1-10 graph from StorylineAsset flow generates stable unique main ids on collision
00:03 +22: NS-STORYLINES-V1-10 graph from StorylineAsset flow generates stable unique sideQuest ids on collision
00:03 +23: NS-STORYLINES-V1-10 graph from StorylineAsset flow does not allow creating a second main storyline
00:04 +24: NS-STORYLINES-V1-10 graph from StorylineAsset flow creation does not import legacy or promote localEventFlow
00:04 +25: NS-STORYLINES-V1-10 graph from StorylineAsset flow sideQuest creation never imports legacy or localEventFlow
00:04 +26: NS-STORYLINES-V1-10 graph from StorylineAsset flow Graph, Structure and disabled future actions do not mutate
00:04 +27: NS-STORYLINES-V1-10 graph from StorylineAsset flow Structure authoring does not import legacy or localEventFlow
00:04 +28: NS-STORYLINES-V1-10 graph from StorylineAsset flow keeps target fake data and Maps out of the V1 UI
00:04 +29: NS-STORYLINES-V1-10 graph from StorylineAsset flow storylines UI source keeps raw colors out of the feature
00:04 +30: NS-STORYLINES-V1-10 graph from StorylineAsset flow storylines shell test keeps raw colors out
00:04 +31: NS-STORYLINES-V1-10 graph from StorylineAsset flow uses PokeMap dark theme in the Visual Gate harness
00:04 +32: NS-STORYLINES-V1-10 graph from StorylineAsset flow writes V1-10 Graph From StorylineAsset screenshots
00:04 +33: All tests passed!
```

## 18. Commands run

- `git branch --show-current`
- `git status --short --untracked-files=all`
- `git diff --stat`
- `git diff --name-only`
- `git diff --check`
- `dart format packages/map_editor/lib/src/ui/canvas/storylines_workspace.dart packages/map_editor/lib/src/ui/canvas/storylines/storylines_graph_model.dart packages/map_editor/lib/src/ui/canvas/storylines/storylines_graph_painter.dart packages/map_editor/lib/src/ui/canvas/storylines/storylines_graph_view.dart packages/map_editor/test/storylines_workspace_shell_test.dart`
- `cd packages/map_editor && flutter test --update-goldens test/storylines_workspace_shell_test.dart`
- `cd packages/map_editor && flutter test test/storylines_workspace_shell_test.dart`
- `cd packages/map_editor && flutter test test/storylines_current_global_story_characterization_test.dart`
- `cd packages/map_editor && flutter test test/narrative_workspace_projection_test.dart`
- `cd packages/map_editor && flutter analyze --no-fatal-infos lib/src/ui/canvas/storylines_workspace.dart lib/src/ui/canvas/storylines/storylines_graph_model.dart lib/src/ui/canvas/storylines/storylines_graph_painter.dart lib/src/ui/canvas/storylines/storylines_graph_view.dart test/storylines_workspace_shell_test.dart test/storylines_current_global_story_characterization_test.dart test/narrative_workspace_projection_test.dart`
- `rg "Color\(0x|Colors\." packages/map_editor/lib/src/ui/canvas/storylines_workspace.dart packages/map_editor/lib/src/ui/canvas/storylines packages/map_editor/test/storylines_workspace_shell_test.dart`

## 19. Roadmap update

`reports/narrativeStudio/storylines/road_map_storylines.md` marque `NS-STORYLINES-V1-10` comme `DONE`, confirme le graph depuis `StorylineAsset`, confirme Structure comme source d'authoring, l'absence de relationship/availability/sceneLink/import legacy, et recommande `NS-STORYLINES-V1-11 — Side Quest Graph Integration V0`.

## 20. Evidence Pack

### Git branch initiale

```text
main
```

### Git status initial exact

Sortie : <vide>

### Git diff --stat initial

Sortie : <vide>

### Git diff --name-only initial

Sortie : <vide>

### Git diff --check initial

Sortie : <vide>

### Liste des fichiers lus

- `AGENTS.md`
- `agent_rules.md`
- `skills/README.md`
- `reports/narrativeStudio/storylines/road_map_storylines.md`
- `reports/narrativeStudio/storylines/ns_storylines_v1_09_create_side_quest_flow_v0.md`
- `packages/map_core/lib/src/models/storyline_asset.dart`
- `packages/map_core/lib/src/models/project_manifest.dart`
- `packages/map_core/lib/map_core.dart`
- `packages/map_editor/lib/src/ui/canvas/storylines_workspace.dart`
- `packages/map_editor/lib/src/ui/canvas/storylines/storylines_graph_model.dart`
- `packages/map_editor/lib/src/ui/canvas/storylines/storylines_graph_painter.dart`
- `packages/map_editor/lib/src/ui/canvas/storylines/storylines_graph_view.dart`
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
- `/Users/karim/.codex/skills/flutter-add-widget-test/SKILL.md`

### Liste des fichiers absents mais attendus

- `reports/narrativeStudio/storylines/ns_storylines_v1_08_structure_tab_authoring_v0.md`
- `reports/narrativeStudio/storylines/ns_storylines_v1_07_bis_storylines_workspace_cleanup.md`
- `reports/narrativeStudio/storylines/ns_storylines_v1_07_create_main_storyline_flow_v0.md`
- `reports/narrativeStudio/storylines/ns_storylines_v1_03_storyline_asset_pure_model_v0.md`
- `reports/narrativeStudio/storylines/ns_storylines_v1_00_storyline_semantics_and_usable_authoring_contract.md`

### Diff complet de storylines_workspace.dart

```text
diff --git a/packages/map_editor/lib/src/ui/canvas/storylines_workspace.dart b/packages/map_editor/lib/src/ui/canvas/storylines_workspace.dart
index 2c0059ca..8741e3a0 100644
--- a/packages/map_editor/lib/src/ui/canvas/storylines_workspace.dart
+++ b/packages/map_editor/lib/src/ui/canvas/storylines_workspace.dart
@@ -6,6 +6,7 @@ import '../../features/editor/state/editor_notifier.dart';
 import '../../features/narrative/application/narrative_workspace_projection.dart';
 import '../../theme/theme.dart';
 import '../design_system/design_system.dart';
+import 'storylines/storylines_graph_view.dart';
 
 class StorylinesWorkspace extends ConsumerStatefulWidget {
   const StorylinesWorkspace({
@@ -779,6 +780,7 @@ class _StorylinesV1MainPanel extends StatelessWidget {
                   )
                 : _StorylinesV1GraphSection(
                     storyline: selectedStoryline,
+                    storylines: storylines,
                     legacyGlobalStory: legacyGlobalStory,
                     legacyStep: legacyStep,
                     legacyStepCount: legacyStepCount,
@@ -953,130 +955,41 @@ class _StorylinesV1KpiStrip extends StatelessWidget {
 class _StorylinesV1GraphSection extends StatelessWidget {
   const _StorylinesV1GraphSection({
     required this.storyline,
+    required this.storylines,
     required this.legacyGlobalStory,
     required this.legacyStep,
     required this.legacyStepCount,
   });
 
   final StorylineAsset? storyline;
+  final List<StorylineAsset> storylines;
   final NarrativeScenarioSummary? legacyGlobalStory;
   final NarrativeStepSummary? legacyStep;
   final int legacyStepCount;
 
   @override
   Widget build(BuildContext context) {
-    final colors = context.pokeMapColors;
     final selectedStoryline = storyline;
-    final isSideQuest = selectedStoryline?.type == StorylineType.sideQuest;
-    final chapterCount = selectedStoryline?.chapters.length ?? 0;
-    final stepCount =
-        selectedStoryline == null ? 0 : _storylineStepCount(selectedStoryline);
-    return PokeMapCard(
-      key: const ValueKey('storylines-graph-target-read-only'),
-      padding: const EdgeInsets.all(18),
-      child: selectedStoryline == null
-          ? _StorylinesV1NoStorylineState(
-              legacyGlobalStory: legacyGlobalStory,
-              legacyStep: legacyStep,
-              legacyStepCount: legacyStepCount,
-            )
-          : Column(
-              crossAxisAlignment: CrossAxisAlignment.stretch,
-              children: [
-                Row(
-                  children: [
-                    const PokeMapIconTile(
-                      icon: CupertinoIcons.arrow_branch,
-                      tone: PokeMapTone.narrative,
-                      size: 42,
-                    ),
-                    const SizedBox(width: 12),
-                    Expanded(
-                      child: Column(
-                        crossAxisAlignment: CrossAxisAlignment.start,
-                        children: [
-                          Text(
-                            'Graph de compréhension',
-                            style: TextStyle(
-                              color: colors.textPrimary,
-                              fontSize: 16,
-                              fontWeight: FontWeight.w800,
-                            ),
-                          ),
-                          const SizedBox(height: 4),
-                          Text(
-                            'Vue générée depuis StorylineAsset. Lecture seule en V1 initial.',
-                            style: TextStyle(
-                              color: colors.textSecondary,
-                              fontSize: 12,
-                            ),
-                          ),
-                        ],
-                      ),
-                    ),
-                  ],
-                ),
-                const SizedBox(height: 18),
-                Expanded(
-                  child: Center(
-                    child: PokeMapCard(
-                      key: const ValueKey('storylines-v1-graph-empty-canvas'),
-                      padding: const EdgeInsets.all(18),
-                      selected: true,
-                      child: Column(
-                        mainAxisSize: MainAxisSize.min,
-                        children: [
-                          Text(
-                            selectedStoryline.title,
-                            textAlign: TextAlign.center,
-                            style: TextStyle(
-                              color: colors.textPrimary,
-                              fontSize: 16,
-                              fontWeight: FontWeight.w800,
-                            ),
-                          ),
-                          const SizedBox(height: 8),
-                          Text(
-                            chapterCount == 0
-                                ? 'Ajoutez des chapitres dans Structure.'
-                                : "${_formatCount(chapterCount, 'chapitre', 'chapitres')} · ${_formatCount(stepCount, 'étape', 'étapes')}",
-                            textAlign: TextAlign.center,
-                            style: TextStyle(
-                              color: colors.textSecondary,
-                              fontSize: 12,
-                            ),
-                          ),
-                          if (isSideQuest || chapterCount > 0) ...[
-                            const SizedBox(height: 8),
-                            Text(
-                              isSideQuest
-                                  ? 'Quête annexe non reliée au graph principal pour l’instant.'
-                                  : 'Graph détaillé à venir au lot Graph From StorylineAsset.',
-                              textAlign: TextAlign.center,
-                              style: TextStyle(
-                                color: colors.textSecondary,
-                                fontSize: 12,
-                              ),
-                            ),
-                          ],
-                          if (isSideQuest) ...[
-                            const SizedBox(height: 6),
-                            Text(
-                              'L’intégration au graph principal viendra dans Side Quest Graph Integration.',
-                              textAlign: TextAlign.center,
-                              style: TextStyle(
-                                color: colors.textMuted,
-                                fontSize: 11,
-                              ),
-                            ),
-                          ],
-                        ],
-                      ),
-                    ),
-                  ),
-                ),
-              ],
-            ),
+    if (selectedStoryline == null) {
+      return PokeMapCard(
+        key: const ValueKey('storylines-graph-target-read-only'),
+        padding: const EdgeInsets.all(18),
+        child: _StorylinesV1NoStorylineState(
+          legacyGlobalStory: legacyGlobalStory,
+          legacyStep: legacyStep,
+          legacyStepCount: legacyStepCount,
+        ),
+      );
+    }
+    final sideQuestCountOutsideSelected =
+        selectedStoryline.type == StorylineType.main
+            ? storylines
+                .where((storyline) => storyline.type == StorylineType.sideQuest)
+                .length
+            : 0;
+    return StorylinesGraphView(
+      storyline: selectedStoryline,
+      sideQuestCountOutsideSelected: sideQuestCountOutsideSelected,
     );
   }
 }
```

### Contenu complet des nouveaux fichiers graph créés

### Contenu complet de packages/map_editor/lib/src/ui/canvas/storylines/storylines_graph_model.dart

```text
import 'package:map_core/map_core.dart';

enum StorylineGraphNodeKind {
  storyline,
  chapter,
  step,
  emptyStepPlaceholder,
}

enum StorylineGraphEdgeKind {
  authorOrder,
  contains,
}

final class StorylineGraphViewModel {
  StorylineGraphViewModel._({
    required this.storylineId,
    required this.title,
    required this.type,
    required this.chapterCount,
    required this.stepCount,
    required this.sideQuestCountOutsideSelected,
    required this.chapters,
    required this.nodes,
    required this.edges,
  });

  factory StorylineGraphViewModel.fromStoryline(
    StorylineAsset storyline, {
    int sideQuestCountOutsideSelected = 0,
  }) {
    final chapters = [...storyline.chapters]
      ..sort(_compareChaptersByAuthorOrder);
    final graphChapters = [
      for (final chapter in chapters)
        StorylineGraphChapter(
          id: chapter.id,
          title: chapter.title,
          description: chapter.description,
          order: chapter.order,
          steps: ([...chapter.steps]..sort(_compareStepsByAuthorOrder)),
        ),
    ];
    final stepCount = graphChapters.fold<int>(
      0,
      (total, chapter) => total + chapter.steps.length,
    );

    final nodes = <StorylineGraphNode>[
      StorylineGraphNode(
        id: storylineNodeId(storyline.id),
        kind: StorylineGraphNodeKind.storyline,
        title: storyline.title,
        subtitle: _storylineTypeLabel(storyline.type),
        order: 0,
      ),
    ];
    final edges = <StorylineGraphEdge>[];
    String? previousChapterNodeId;
    for (final chapter in graphChapters) {
      final chapterNodeId = StorylineGraphViewModel.chapterNodeId(chapter.id);
      nodes.add(
        StorylineGraphNode(
          id: chapterNodeId,
          kind: StorylineGraphNodeKind.chapter,
          title: chapter.title,
          subtitle: _formatCount(chapter.steps.length, 'étape', 'étapes'),
          order: chapter.order,
          chapterId: chapter.id,
        ),
      );
      if (previousChapterNodeId == null) {
        edges.add(
          StorylineGraphEdge(
            id: 'edge:${storyline.id}:${chapter.id}',
            fromNodeId: storylineNodeId(storyline.id),
            toNodeId: chapterNodeId,
            kind: StorylineGraphEdgeKind.authorOrder,
          ),
        );
      } else {
        edges.add(
          StorylineGraphEdge(
            id: 'edge:$previousChapterNodeId:$chapterNodeId',
            fromNodeId: previousChapterNodeId,
            toNodeId: chapterNodeId,
            kind: StorylineGraphEdgeKind.authorOrder,
          ),
        );
      }
      previousChapterNodeId = chapterNodeId;

      if (chapter.steps.isEmpty) {
        nodes.add(
          StorylineGraphNode(
            id: emptyStepNodeId(chapter.id),
            kind: StorylineGraphNodeKind.emptyStepPlaceholder,
            title: 'Aucune étape narrative',
            subtitle: 'Ajoutez une étape dans Structure.',
            order: chapter.order,
            chapterId: chapter.id,
          ),
        );
      } else {
        for (final step in chapter.steps) {
          nodes.add(
            StorylineGraphNode(
              id: stepNodeId(step.id),
              kind: StorylineGraphNodeKind.step,
              title: step.title,
              subtitle: _sceneLinkLabel(step.sceneLinkIds.length),
              order: step.order,
              chapterId: chapter.id,
              stepId: step.id,
            ),
          );
          edges.add(
            StorylineGraphEdge(
              id: 'contains:${chapter.id}:${step.id}',
              fromNodeId: chapterNodeId,
              toNodeId: stepNodeId(step.id),
              kind: StorylineGraphEdgeKind.contains,
            ),
          );
        }
      }
    }

    return StorylineGraphViewModel._(
      storylineId: storyline.id,
      title: storyline.title,
      type: storyline.type,
      chapterCount: graphChapters.length,
      stepCount: stepCount,
      sideQuestCountOutsideSelected: sideQuestCountOutsideSelected,
      chapters: graphChapters,
      nodes: nodes,
      edges: edges,
    );
  }

  final String storylineId;
  final String title;
  final StorylineType type;
  final int chapterCount;
  final int stepCount;
  final int sideQuestCountOutsideSelected;
  final List<StorylineGraphChapter> chapters;
  final List<StorylineGraphNode> nodes;
  final List<StorylineGraphEdge> edges;

  bool get isSideQuest => type == StorylineType.sideQuest;

  bool get hasChapters => chapters.isNotEmpty;

  bool get hasSideQuestNote =>
      type == StorylineType.main && sideQuestCountOutsideSelected > 0;

  static String storylineNodeId(String storylineId) => 'storyline:$storylineId';

  static String chapterNodeId(String chapterId) => 'chapter:$chapterId';

  static String stepNodeId(String stepId) => 'step:$stepId';

  static String emptyStepNodeId(String chapterId) => 'empty-step:$chapterId';
}

final class StorylineGraphChapter {
  const StorylineGraphChapter({
    required this.id,
    required this.title,
    required this.description,
    required this.order,
    required this.steps,
  });

  final String id;
  final String title;
  final String? description;
  final int order;
  final List<StorylineStep> steps;
}

final class StorylineGraphNode {
  const StorylineGraphNode({
    required this.id,
    required this.kind,
    required this.title,
    required this.subtitle,
    required this.order,
    this.chapterId,
    this.stepId,
  });

  final String id;
  final StorylineGraphNodeKind kind;
  final String title;
  final String subtitle;
  final int order;
  final String? chapterId;
  final String? stepId;
}

final class StorylineGraphEdge {
  const StorylineGraphEdge({
    required this.id,
    required this.fromNodeId,
    required this.toNodeId,
    required this.kind,
  });

  final String id;
  final String fromNodeId;
  final String toNodeId;
  final StorylineGraphEdgeKind kind;
}

int _compareChaptersByAuthorOrder(
  StorylineChapter left,
  StorylineChapter right,
) {
  final order = left.order.compareTo(right.order);
  if (order != 0) return order;
  final title = left.title.compareTo(right.title);
  if (title != 0) return title;
  return left.id.compareTo(right.id);
}

int _compareStepsByAuthorOrder(StorylineStep left, StorylineStep right) {
  final order = left.order.compareTo(right.order);
  if (order != 0) return order;
  final title = left.title.compareTo(right.title);
  if (title != 0) return title;
  return left.id.compareTo(right.id);
}

String _storylineTypeLabel(StorylineType type) {
  return switch (type) {
    StorylineType.main => 'Histoire principale',
    StorylineType.sideQuest => 'Quête annexe',
    StorylineType.tutorial => 'Tutoriel',
    StorylineType.epilogue => 'Épilogue',
    StorylineType.episode => 'Épisode',
    StorylineType.postGame => 'Post-game',
    StorylineType.hiddenEvent => 'Événement caché',
  };
}

String _formatCount(int count, String singular, String plural) {
  return '$count ${count == 1 ? singular : plural}';
}

String _sceneLinkLabel(int count) {
  if (count == 0) return 'Aucune scène liée';
  return _formatCount(count, 'scène liée', 'scènes liées');
}
```

### Contenu complet de packages/map_editor/lib/src/ui/canvas/storylines/storylines_graph_painter.dart

```text
import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import 'storylines_graph_model.dart';

final class StorylineGraphPaintEdge {
  const StorylineGraphPaintEdge({
    required this.from,
    required this.to,
    required this.kind,
  });

  final Offset from;
  final Offset to;
  final StorylineGraphEdgeKind kind;
}

class StorylinesGraphPainter extends CustomPainter {
  const StorylinesGraphPainter({
    required this.edges,
    required this.gridColor,
    required this.authorOrderColor,
    required this.containsColor,
  });

  final List<StorylineGraphPaintEdge> edges;
  final Color gridColor;
  final Color authorOrderColor;
  final Color containsColor;

  @override
  void paint(Canvas canvas, Size size) {
    _paintGrid(canvas, size);
    for (final edge in edges) {
      _paintEdge(canvas, edge);
    }
  }

  void _paintGrid(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = gridColor
      ..strokeWidth = 1;
    const spacing = 28.0;
    for (var x = 0.0; x <= size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (var y = 0.0; y <= size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  void _paintEdge(Canvas canvas, StorylineGraphPaintEdge edge) {
    final color = edge.kind == StorylineGraphEdgeKind.authorOrder
        ? authorOrderColor
        : containsColor;
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth =
          edge.kind == StorylineGraphEdgeKind.authorOrder ? 2.4 : 1.4;
    final controlOffset =
        math.max((edge.to.dx - edge.from.dx).abs() * 0.42, 48);
    final path = Path()
      ..moveTo(edge.from.dx, edge.from.dy)
      ..cubicTo(
        edge.from.dx + controlOffset,
        edge.from.dy,
        edge.to.dx - controlOffset,
        edge.to.dy,
        edge.to.dx,
        edge.to.dy,
      );
    canvas.drawPath(path, paint);
    if (edge.kind == StorylineGraphEdgeKind.authorOrder) {
      _paintArrowHead(canvas, edge, color);
    }
  }

  void _paintArrowHead(
    Canvas canvas,
    StorylineGraphPaintEdge edge,
    Color color,
  ) {
    final angle =
        math.atan2(edge.to.dy - edge.from.dy, edge.to.dx - edge.from.dx);
    const size = 8.0;
    final left = Offset(
      edge.to.dx - math.cos(angle - math.pi / 7) * size,
      edge.to.dy - math.sin(angle - math.pi / 7) * size,
    );
    final right = Offset(
      edge.to.dx - math.cos(angle + math.pi / 7) * size,
      edge.to.dy - math.sin(angle + math.pi / 7) * size,
    );
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    canvas.drawPath(
      Path()
        ..moveTo(edge.to.dx, edge.to.dy)
        ..lineTo(left.dx, left.dy)
        ..lineTo(right.dx, right.dy)
        ..close(),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant StorylinesGraphPainter oldDelegate) {
    return edges != oldDelegate.edges ||
        gridColor != oldDelegate.gridColor ||
        authorOrderColor != oldDelegate.authorOrderColor ||
        containsColor != oldDelegate.containsColor;
  }
}
```

### Contenu complet de packages/map_editor/lib/src/ui/canvas/storylines/storylines_graph_view.dart

```text
import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:map_core/map_core.dart';

import '../../../theme/theme.dart';
import '../../design_system/design_system.dart';
import 'storylines_graph_model.dart';
import 'storylines_graph_painter.dart';

class StorylinesGraphView extends StatelessWidget {
  const StorylinesGraphView({
    super.key,
    required this.storyline,
    required this.sideQuestCountOutsideSelected,
  });

  final StorylineAsset storyline;
  final int sideQuestCountOutsideSelected;

  @override
  Widget build(BuildContext context) {
    final model = StorylineGraphViewModel.fromStoryline(
      storyline,
      sideQuestCountOutsideSelected: sideQuestCountOutsideSelected,
    );
    final colors = context.pokeMapColors;
    return Column(
      key: const ValueKey('storylines-graph-from-asset'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            const PokeMapIconTile(
              icon: CupertinoIcons.arrow_branch,
              tone: PokeMapTone.narrative,
              size: 42,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Graph de compréhension',
                    style: TextStyle(
                      color: colors.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Vue read-only générée depuis la StorylineAsset sélectionnée.',
                    style: TextStyle(
                      color: colors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            const _StorylinesGraphBadge(label: 'Read-only'),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            const _StorylinesGraphBadge(
              label: 'Lignes = ordre auteur',
            ),
            if (model.isSideQuest)
              const _StorylinesGraphBadge(
                label: 'Quête annexe indépendante',
              ),
            if (model.hasSideQuestNote)
              _StorylinesGraphBadge(
                label:
                    'Quêtes annexes créées : ${model.sideQuestCountOutsideSelected} — intégration à venir',
              ),
          ],
        ),
        const SizedBox(height: 12),
        Expanded(
          child: _StorylinesGraphCanvas(model: model),
        ),
      ],
    );
  }
}

class _StorylinesGraphCanvas extends StatelessWidget {
  const _StorylinesGraphCanvas({required this.model});

  static const double _rootWidth = 230;
  static const double _rootHeight = 164;
  static const double _chapterWidth = 260;
  static const double _chapterGap = 54;
  static const double _leftPadding = 32;
  static const double _topPadding = 42;
  static const double _rootToChapterGap = 70;
  static const double _stepHeight = 54;

  final StorylineGraphViewModel model;

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxStepCount = model.chapters.fold<int>(
          0,
          (current, chapter) => math.max(current, chapter.steps.length),
        );
        final chapterHeight = _chapterHeight(maxStepCount);
        final contentWidth = _leftPadding +
            _rootWidth +
            _rootToChapterGap +
            math.max(1, model.chapters.length) * (_chapterWidth + _chapterGap) +
            _leftPadding;
        final contentHeight = math.max(
          _topPadding + chapterHeight + 60,
          _topPadding + _rootHeight + 160,
        );
        final canvasWidth = math
            .max(
              constraints.maxWidth.isFinite ? constraints.maxWidth : 900,
              contentWidth,
            )
            .toDouble();
        final canvasHeight = math
            .max(
              constraints.maxHeight.isFinite ? constraints.maxHeight : 460,
              contentHeight,
            )
            .toDouble();
        final rootRect = Rect.fromLTWH(
          _leftPadding,
          math.max(_topPadding, (canvasHeight - _rootHeight) / 2),
          _rootWidth,
          _rootHeight,
        );
        final chapterRects = <String, Rect>{};
        for (var index = 0; index < model.chapters.length; index += 1) {
          final chapter = model.chapters[index];
          chapterRects[chapter.id] = Rect.fromLTWH(
            _leftPadding +
                _rootWidth +
                _rootToChapterGap +
                index * (_chapterWidth + _chapterGap),
            _topPadding,
            _chapterWidth,
            _chapterHeight(chapter.steps.length),
          );
        }
        final paintEdges = _paintEdges(rootRect, chapterRects);
        return DecoratedBox(
          decoration: BoxDecoration(
            color: colors.surfaceSubtle,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: colors.borderSubtle),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: SingleChildScrollView(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SizedBox(
                  key: const ValueKey('storylines-graph-canvas'),
                  width: canvasWidth,
                  height: canvasHeight,
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: CustomPaint(
                          painter: StorylinesGraphPainter(
                            edges: paintEdges,
                            gridColor: colors.borderSubtle,
                            authorOrderColor: colors.brandPrimaryBorder,
                            containsColor: colors.controlBorder,
                          ),
                        ),
                      ),
                      _GraphNodePosition(
                        rect: rootRect,
                        child: _GraphRootNode(model: model),
                      ),
                      for (final chapter in model.chapters)
                        _GraphNodePosition(
                          rect: chapterRects[chapter.id]!,
                          child: _GraphChapterNode(chapter: chapter),
                        ),
                      for (final marker in _edgeMarkers(rootRect, chapterRects))
                        Positioned(
                          key: ValueKey(marker.key),
                          left: marker.position.dx,
                          top: marker.position.dy,
                          child: const SizedBox(width: 1, height: 1),
                        ),
                      if (!model.hasChapters)
                        Positioned(
                          left: rootRect.right + 46,
                          top: rootRect.top + 18,
                          width: 320,
                          child: const _GraphEmptyHint(
                            key: ValueKey(
                              'storylines-graph-empty-storyline-message',
                            ),
                            title: 'Ajoutez un chapitre dans Structure',
                            body:
                                'Le graph se construit uniquement depuis les données auteur existantes.',
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  double _chapterHeight(int stepCount) {
    final effectiveSteps = math.max(1, stepCount);
    return 138 + effectiveSteps * (_stepHeight + 8);
  }

  List<StorylineGraphPaintEdge> _paintEdges(
    Rect rootRect,
    Map<String, Rect> chapterRects,
  ) {
    if (model.chapters.isEmpty) return const [];
    final edges = <StorylineGraphPaintEdge>[];
    final firstChapter = model.chapters.first;
    edges.add(
      StorylineGraphPaintEdge(
        from: Offset(rootRect.right, rootRect.center.dy),
        to: Offset(
          chapterRects[firstChapter.id]!.left,
          chapterRects[firstChapter.id]!.center.dy,
        ),
        kind: StorylineGraphEdgeKind.authorOrder,
      ),
    );
    for (var index = 0; index < model.chapters.length - 1; index += 1) {
      final current = chapterRects[model.chapters[index].id]!;
      final next = chapterRects[model.chapters[index + 1].id]!;
      edges.add(
        StorylineGraphPaintEdge(
          from: Offset(current.right, current.center.dy),
          to: Offset(next.left, next.center.dy),
          kind: StorylineGraphEdgeKind.authorOrder,
        ),
      );
    }
    return edges;
  }

  List<_EdgeMarker> _edgeMarkers(
    Rect rootRect,
    Map<String, Rect> chapterRects,
  ) {
    if (model.chapters.isEmpty) return const [];
    final markers = <_EdgeMarker>[
      _EdgeMarker(
        key: 'storylines-graph-edge-root-${model.chapters.first.id}',
        position: Offset(
          (rootRect.right + chapterRects[model.chapters.first.id]!.left) / 2,
          (rootRect.center.dy +
                  chapterRects[model.chapters.first.id]!.center.dy) /
              2,
        ),
      ),
    ];
    for (var index = 0; index < model.chapters.length - 1; index += 1) {
      final current = model.chapters[index];
      final next = model.chapters[index + 1];
      final currentRect = chapterRects[current.id]!;
      final nextRect = chapterRects[next.id]!;
      markers.add(
        _EdgeMarker(
          key: 'storylines-graph-edge-${current.id}-${next.id}',
          position: Offset(
            (currentRect.right + nextRect.left) / 2,
            (currentRect.center.dy + nextRect.center.dy) / 2,
          ),
        ),
      );
    }
    return markers;
  }
}

class _GraphNodePosition extends StatelessWidget {
  const _GraphNodePosition({
    required this.rect,
    required this.child,
  });

  final Rect rect;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: rect.left,
      top: rect.top,
      width: rect.width,
      height: rect.height,
      child: child,
    );
  }
}

class _GraphRootNode extends StatelessWidget {
  const _GraphRootNode({required this.model});

  final StorylineGraphViewModel model;

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    return KeyedSubtree(
      key: ValueKey('storylines-graph-node-storyline-${model.storylineId}'),
      child: PokeMapCard(
        selected: true,
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              model.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: colors.textPrimary,
                fontSize: 15,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                _StorylinesGraphBadge(label: _storylineTypeLabel(model.type)),
                const _StorylinesGraphBadge(label: 'Brouillon'),
              ],
            ),
            const Spacer(),
            Text(
              '${_formatCount(model.chapterCount, 'chapitre', 'chapitres')} · ${_formatCount(model.stepCount, 'étape', 'étapes')}',
              style: TextStyle(
                color: colors.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GraphChapterNode extends StatelessWidget {
  const _GraphChapterNode({required this.chapter});

  final StorylineGraphChapter chapter;

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    return KeyedSubtree(
      key: ValueKey('storylines-graph-node-chapter-${chapter.id}'),
      child: PokeMapCard(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              chapter.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: colors.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              'Ordre ${chapter.order} · ${_formatCount(chapter.steps.length, 'étape', 'étapes')}',
              style: TextStyle(
                color: colors.textSecondary,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
            if (chapter.description != null) ...[
              const SizedBox(height: 5),
              Text(
                chapter.description!,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: colors.textMuted,
                  fontSize: 11,
                  height: 1.25,
                ),
              ),
            ],
            const SizedBox(height: 10),
            if (chapter.steps.isEmpty)
              _GraphEmptyHint(
                key: ValueKey('storylines-graph-empty-steps-${chapter.id}'),
                title: 'Aucune étape narrative.',
                body: 'Les étapes restent créées depuis Structure.',
              )
            else
              Expanded(
                child: ListView.separated(
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: chapter.steps.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final step = chapter.steps[index];
                    return _GraphStepChip(step: step);
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _GraphStepChip extends StatelessWidget {
  const _GraphStepChip({required this.step});

  final StorylineStep step;

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    return DecoratedBox(
      key: ValueKey('storylines-graph-node-step-${step.id}'),
      decoration: BoxDecoration(
        color: colors.controlSurface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colors.borderSubtle),
      ),
      child: Padding(
        padding: const EdgeInsets.all(9),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              step.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: colors.textPrimary,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
            if (step.description != null) ...[
              const SizedBox(height: 3),
              Text(
                step.description!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: colors.textMuted,
                  fontSize: 10,
                ),
              ),
            ],
            const SizedBox(height: 4),
            Text(
              _sceneLinkLabel(step.sceneLinkIds.length),
              style: TextStyle(
                color: colors.textSecondary,
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GraphEmptyHint extends StatelessWidget {
  const _GraphEmptyHint({
    super.key,
    required this.title,
    required this.body,
  });

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.controlSurface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colors.borderSubtle),
      ),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                color: colors.textPrimary,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              body,
              style: TextStyle(
                color: colors.textSecondary,
                fontSize: 11,
                height: 1.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StorylinesGraphBadge extends StatelessWidget {
  const _StorylinesGraphBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.controlSurface,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: colors.borderSubtle),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Text(
          label,
          style: TextStyle(
            color: colors.textSecondary,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

final class _EdgeMarker {
  const _EdgeMarker({
    required this.key,
    required this.position,
  });

  final String key;
  final Offset position;
}

String _storylineTypeLabel(StorylineType type) {
  return switch (type) {
    StorylineType.main => 'Histoire principale',
    StorylineType.sideQuest => 'Quête annexe',
    StorylineType.tutorial => 'Tutoriel',
    StorylineType.epilogue => 'Épilogue',
    StorylineType.episode => 'Épisode',
    StorylineType.postGame => 'Post-game',
    StorylineType.hiddenEvent => 'Événement caché',
  };
}

String _formatCount(int count, String singular, String plural) {
  return '$count ${count == 1 ? singular : plural}';
}

String _sceneLinkLabel(int count) {
  if (count == 0) return 'Aucune scène liée';
  return _formatCount(count, 'scène liée', 'scènes liées');
}
```

### Diff complet des tests modifiés ou créés

```text
diff --git a/packages/map_editor/test/storylines_workspace_shell_test.dart b/packages/map_editor/test/storylines_workspace_shell_test.dart
index eef998de..ba4983ad 100644
--- a/packages/map_editor/test/storylines_workspace_shell_test.dart
+++ b/packages/map_editor/test/storylines_workspace_shell_test.dart
@@ -12,7 +12,7 @@ import 'package:map_editor/src/ui/canvas/narrative_workspace_canvas.dart';
 import 'package:map_editor/src/ui/design_system/design_system.dart';
 
 void main() {
-  group('NS-STORYLINES-V1-09 side quest authoring flow', () {
+  group('NS-STORYLINES-V1-10 graph from StorylineAsset flow', () {
     testWidgets('shows only Graph and Structure tabs', (tester) async {
       await _pumpStorylinesShell(tester);
 
@@ -43,6 +43,11 @@ void main() {
           findsOneWidget);
       expect(find.byKey(const ValueKey('storylines-graph-target-read-only')),
           findsOneWidget);
+      expect(
+          find.byKey(const ValueKey('storylines-graph-canvas')), findsNothing);
+      expect(
+          find.byKey(const ValueKey('storylines-graph-node-chapter-anything')),
+          findsNothing);
       expect(find.textContaining('ne sera pas importée automatiquement'),
           findsOneWidget);
       expect(find.byKey(const ValueKey('storylines-v1-legacy-preview-card')),
@@ -180,7 +185,17 @@ void main() {
 
       expect(find.text('Ma grande histoire'), findsWidgets);
       expect(
-          find.text('Ajoutez des chapitres dans Structure.'), findsOneWidget);
+        find.text('Ajoutez un chapitre dans Structure'),
+        findsOneWidget,
+      );
+      expect(
+        find.byKey(
+          const ValueKey(
+            'storylines-graph-node-storyline-storyline_ma_grande_histoire',
+          ),
+        ),
+        findsOneWidget,
+      );
 
       await _openStructureTab(tester);
       expect(find.byKey(const ValueKey('storylines-structure-read-only')),
@@ -541,21 +556,143 @@ void main() {
       await _createStep(tester, title: 'Premier jalon');
       await _openGraphTab(tester);
 
+      final graphCanvas = find.byKey(const ValueKey('storylines-graph-canvas'));
       expect(
         find.descendant(
-          of: find.byKey(const ValueKey('storylines-v1-graph-empty-canvas')),
-          matching: find.text('1 chapitre · 1 étape'),
+          of: graphCanvas,
+          matching: find.byKey(
+            const ValueKey(
+              'storylines-graph-node-storyline-storyline_existing_main',
+            ),
+          ),
         ),
         findsOneWidget,
       );
       expect(
-        find.text('Graph détaillé à venir au lot Graph From StorylineAsset.'),
+        find.descendant(
+          of: graphCanvas,
+          matching: find.byKey(
+            const ValueKey('storylines-graph-node-chapter-chapter_intro'),
+          ),
+        ),
+        findsOneWidget,
+      );
+      expect(
+        find.descendant(
+          of: graphCanvas,
+          matching: find.byKey(
+            const ValueKey('storylines-graph-node-step-step_premier_jalon'),
+          ),
+        ),
+        findsOneWidget,
+      );
+      expect(
+        find.byKey(const ValueKey('storylines-graph-edge-root-chapter_intro')),
         findsOneWidget,
       );
-      expect(find.text('Ajoutez des chapitres dans Structure.'), findsNothing);
+      expect(find.text('Lignes = ordre auteur'), findsOneWidget);
+      expect(find.text('Aucune scène liée'), findsOneWidget);
+      expect(find.text('Ajoutez un chapitre dans Structure'), findsNothing);
       expect(find.text('Quête annexe fake'), findsNothing);
     });
 
+    testWidgets('Graph orders chapters and steps by author order',
+        (tester) async {
+      await _pumpStorylinesShell(
+        tester,
+        project: _projectWithStorylines([
+          StorylineAsset(
+            id: 'storyline_ordered_main',
+            type: StorylineType.main,
+            title: 'Ordered main',
+            chapters: [
+              StorylineChapter(
+                id: 'chapter_second',
+                title: 'Second',
+                order: 2,
+              ),
+              StorylineChapter(
+                id: 'chapter_tie_b',
+                title: 'Tie B',
+                order: 1,
+              ),
+              StorylineChapter(
+                id: 'chapter_first',
+                title: 'First',
+                order: 0,
+                steps: [
+                  StorylineStep(
+                    id: 'step_second',
+                    title: 'Second step',
+                    order: 2,
+                  ),
+                  StorylineStep(
+                    id: 'step_first',
+                    title: 'First step',
+                    order: 0,
+                    sceneLinkIds: const ['scenario_scene_ref'],
+                  ),
+                ],
+              ),
+              StorylineChapter(
+                id: 'chapter_tie_a',
+                title: 'Tie A',
+                order: 1,
+              ),
+            ],
+          ),
+        ]),
+      );
+
+      await _openGraphTab(tester);
+
+      final firstX = tester
+          .getTopLeft(
+            find.byKey(
+              const ValueKey('storylines-graph-node-chapter-chapter_first'),
+            ),
+          )
+          .dx;
+      final tieAX = tester
+          .getTopLeft(
+            find.byKey(
+              const ValueKey('storylines-graph-node-chapter-chapter_tie_a'),
+            ),
+          )
+          .dx;
+      final tieBX = tester
+          .getTopLeft(
+            find.byKey(
+              const ValueKey('storylines-graph-node-chapter-chapter_tie_b'),
+            ),
+          )
+          .dx;
+      final secondX = tester
+          .getTopLeft(
+            find.byKey(
+              const ValueKey('storylines-graph-node-chapter-chapter_second'),
+            ),
+          )
+          .dx;
+      expect(firstX, lessThan(tieAX));
+      expect(tieAX, lessThan(tieBX));
+      expect(tieBX, lessThan(secondX));
+
+      final firstStepY = tester
+          .getTopLeft(
+            find.byKey(const ValueKey('storylines-graph-node-step-step_first')),
+          )
+          .dy;
+      final secondStepY = tester
+          .getTopLeft(
+            find.byKey(
+                const ValueKey('storylines-graph-node-step-step_second')),
+          )
+          .dy;
+      expect(firstStepY, lessThan(secondStepY));
+      expect(find.text('1 scène liée'), findsOneWidget);
+    });
+
     testWidgets('Graph explains sideQuest is not linked to main graph yet',
         (tester) async {
       await _pumpStorylinesShell(
@@ -574,8 +711,7 @@ void main() {
       await _createStep(tester, title: 'Find clue');
       await _openGraphTab(tester);
 
-      final graphCanvas =
-          find.byKey(const ValueKey('storylines-v1-graph-empty-canvas'));
+      final graphCanvas = find.byKey(const ValueKey('storylines-graph-canvas'));
       expect(
         find.descendant(of: graphCanvas, matching: find.text('Missing Bell')),
         findsOneWidget,
@@ -586,9 +722,31 @@ void main() {
         findsOneWidget,
       );
       expect(
-        find.text('Quête annexe non reliée au graph principal pour l’instant.'),
+        find.descendant(
+          of: graphCanvas,
+          matching: find.byKey(
+            const ValueKey('storylines-graph-node-chapter-chapter_side_intro'),
+          ),
+        ),
+        findsOneWidget,
+      );
+      expect(
+        find.descendant(
+          of: graphCanvas,
+          matching: find.byKey(
+            const ValueKey('storylines-graph-node-step-step_find_clue'),
+          ),
+        ),
+        findsOneWidget,
+      );
+      expect(
+        find.text('Quête annexe indépendante'),
         findsOneWidget,
       );
+      expect(
+        find.descendant(of: graphCanvas, matching: find.text('Existing main')),
+        findsNothing,
+      );
       expect(find.textContaining('availability'), findsNothing);
     });
 
@@ -612,8 +770,7 @@ void main() {
       await tester.pump();
       await _openGraphTab(tester);
 
-      final graphCanvas =
-          find.byKey(const ValueKey('storylines-v1-graph-empty-canvas'));
+      final graphCanvas = find.byKey(const ValueKey('storylines-graph-canvas'));
       expect(
         find.descendant(of: graphCanvas, matching: find.text('Existing main')),
         findsOneWidget,
@@ -623,8 +780,8 @@ void main() {
         findsNothing,
       );
       expect(
-        find.text('Quête annexe non reliée au graph principal pour l’instant.'),
-        findsNothing,
+        find.text('Quêtes annexes créées : 1 — intégration à venir'),
+        findsOneWidget,
       );
     });
 
@@ -887,63 +1044,61 @@ void main() {
       expect(Theme.of(shellContext).brightness, Brightness.dark);
     });
 
-    testWidgets('writes V1-09 Side Quest Visual Gate screenshots',
+    testWidgets('writes V1-10 Graph From StorylineAsset screenshots',
         (tester) async {
-      final project = _projectWithStorylines([
-        StorylineAsset(
-          id: 'storyline_visual_main',
-          type: StorylineType.main,
-          title: 'Visual Main',
-        ),
-      ]);
-
       await _pumpStorylinesShell(
         tester,
         surfaceSize: const Size(1600, 1000),
-        project: project,
+        project: _projectWithStorylines([
+          StorylineAsset(
+            id: 'storyline_visual_empty',
+            type: StorylineType.main,
+            title: 'Visual Empty Main',
+          ),
+        ]),
       );
-
-      await _openCreateDialog(tester);
       await expectLater(
-        find.byKey(const ValueKey('storylines-create-main-dialog')),
+        find.byKey(const ValueKey('storylines-workspace-shell')),
         matchesGoldenFile(
           '../../../reports/narrativeStudio/storylines/screenshots/'
-          'ns_storylines_v1_09_create_side_quest_dialog.png',
+          'ns_storylines_v1_10_graph_empty_storyline.png',
         ),
       );
-      await tester.tap(find.byKey(const ValueKey('storylines-create-cancel')));
-      await tester.pumpAndSettle();
 
-      await _createSideQuest(
+      await _pumpStorylinesShell(
         tester,
-        title: 'Visual Side Quest',
-        description: 'Optional visual storyline.',
+        surfaceSize: const Size(1600, 1000),
+        project: _visualGraphProject(),
       );
-      await _openGraphTab(tester);
       await expectLater(
         find.byKey(const ValueKey('storylines-workspace-shell')),
         matchesGoldenFile(
           '../../../reports/narrativeStudio/storylines/screenshots/'
-          'ns_storylines_v1_09_created_side_quest_graph.png',
+          'ns_storylines_v1_10_graph_main_chapters_steps.png',
         ),
       );
 
-      await _openStructureTab(tester);
-      await _createChapter(tester, title: 'Visual Side Chapter');
-      await _createStep(tester, title: 'Visual Side Step');
+      await tester.tap(
+        find.byKey(const ValueKey('storylines-v1-row-sidequest_visual')),
+      );
+      await tester.pump();
       await expectLater(
         find.byKey(const ValueKey('storylines-workspace-shell')),
         matchesGoldenFile(
           '../../../reports/narrativeStudio/storylines/screenshots/'
-          'ns_storylines_v1_09_created_side_quest_structure.png',
+          'ns_storylines_v1_10_graph_sidequest_standalone.png',
         ),
       );
 
+      await tester.tap(
+        find.byKey(const ValueKey('storylines-v1-row-storyline_visual_main')),
+      );
+      await tester.pump();
       await expectLater(
-        find.byKey(const ValueKey('storylines-secondary-panel')),
+        find.byKey(const ValueKey('storylines-workspace-shell')),
         matchesGoldenFile(
           '../../../reports/narrativeStudio/storylines/screenshots/'
-          'ns_storylines_v1_09_storyline_list_with_side_quest.png',
+          'ns_storylines_v1_10_graph_main_ignores_sidequest.png',
         ),
       );
     });
@@ -1210,6 +1365,70 @@ ProjectManifest _projectWithStorylines(List<StorylineAsset> storylines) {
   );
 }
 
+ProjectManifest _visualGraphProject() {
+  return _projectWithStorylines([
+    StorylineAsset(
+      id: 'storyline_visual_main',
+      type: StorylineType.main,
+      title: 'Visual Main',
+      description: 'Graph generated from authoring structure.',
+      chapters: [
+        StorylineChapter(
+          id: 'chapter_visual_start',
+          title: 'Opening',
+          description: 'First authoring beat.',
+          order: 0,
+          steps: [
+            StorylineStep(
+              id: 'step_visual_arrival',
+              title: 'Arrival',
+              description: 'Introduce the player goal.',
+              order: 0,
+            ),
+            StorylineStep(
+              id: 'step_visual_choice',
+              title: 'First choice',
+              order: 1,
+            ),
+          ],
+        ),
+        StorylineChapter(
+          id: 'chapter_visual_followup',
+          title: 'Follow-up',
+          order: 1,
+          steps: [
+            StorylineStep(
+              id: 'step_visual_resolution',
+              title: 'Resolution',
+              order: 0,
+            ),
+          ],
+        ),
+      ],
+    ),
+    StorylineAsset(
+      id: 'sidequest_visual',
+      type: StorylineType.sideQuest,
+      title: 'Visual Side Quest',
+      description: 'Standalone optional storyline.',
+      chapters: [
+        StorylineChapter(
+          id: 'chapter_visual_side',
+          title: 'Side opening',
+          order: 0,
+          steps: [
+            StorylineStep(
+              id: 'step_visual_side_clue',
+              title: 'Find clue',
+              order: 0,
+            ),
+          ],
+        ),
+      ],
+    ),
+  ]);
+}
+
 class _StorylinesHarness {
   const _StorylinesHarness(this.container);
 
```

### Diff complet de road_map_storylines.md

```text
diff --git a/reports/narrativeStudio/storylines/road_map_storylines.md b/reports/narrativeStudio/storylines/road_map_storylines.md
index ac7b82cb..aac43b54 100644
--- a/reports/narrativeStudio/storylines/road_map_storylines.md
+++ b/reports/narrativeStudio/storylines/road_map_storylines.md
@@ -312,7 +312,7 @@ Interprétation V0 :
 | NS-STORYLINES-V1-07-bis | Storylines Workspace Cleanup / Dead Legacy Removal | editor UI cleanup | DONE | NS-STORYLINES-V1-08 |
 | NS-STORYLINES-V1-08 | Structure Tab Authoring V0 | editor authoring | DONE | NS-STORYLINES-V1-09 |
 | NS-STORYLINES-V1-09 | Create Side Quest Flow V0 | editor authoring | DONE | NS-STORYLINES-V1-10 |
-| NS-STORYLINES-V1-10 | Graph From StorylineAsset V0 | editor graph | TODO | NS-STORYLINES-V1-11 |
+| NS-STORYLINES-V1-10 | Graph From StorylineAsset V0 | editor graph | DONE | NS-STORYLINES-V1-11 |
 | NS-STORYLINES-V1-11 | Side Quest Graph Integration V0 | editor graph | TODO | NS-STORYLINES-V1-12 |
 | NS-STORYLINES-V1-12 | V1 Visual Graph Enrichment | visual gate | TODO | NS-STORYLINES-V1-CHECKPOINT |
 | NS-STORYLINES-V1-CHECKPOINT | Storylines V1 Acceptance Checkpoint | checkpoint | TODO | TBD |
@@ -896,10 +896,10 @@ Décision temporaire :
 ## 13. Current status
 
 ```text
-Roadmap status: V0 ACCEPTED WITH V1 LIMITATIONS / V1 SIDE QUEST AUTHORING DONE
-Current lot: NS-STORYLINES-V1-09
+Roadmap status: V0 ACCEPTED WITH V1 LIMITATIONS / V1 GRAPH FROM STORYLINEASSET DONE
+Current lot: NS-STORYLINES-V1-10
 Current lot status: DONE
-Next recommended lot: NS-STORYLINES-V1-10 — Graph From StorylineAsset V0
+Next recommended lot: NS-STORYLINES-V1-11 — Side Quest Graph Integration V0
 ```
 
 | Lot | Status | Last update | Notes |
@@ -929,6 +929,7 @@ Next recommended lot: NS-STORYLINES-V1-10 — Graph From StorylineAsset V0
 | NS-STORYLINES-V1-07-bis | DONE | 2026-05-28 | Cleanup technique Storylines livré sans changement produit : legacy mort absent, tap silencieux supprimé, Visual Gate V1-07 régénéré. |
 | NS-STORYLINES-V1-08 | DONE | 2026-05-29 | Structure Tab Authoring V0 livré : création de chapitres et steps, Graph minimal honnête, aucun sceneLink/sideQuest/import legacy. |
 | NS-STORYLINES-V1-09 | DONE | 2026-05-29 | Create Side Quest Flow V0 livré : création réelle de `StorylineAsset(type: sideQuest, status: draft)`, liste main/sideQuest séparée, Structure réutilisée, aucune relationship/availability/sceneLink/import legacy. |
+| NS-STORYLINES-V1-10 | DONE | 2026-05-29 | Graph From StorylineAsset V0 livré : graph read-only généré depuis la StorylineAsset sélectionnée, nodes storyline/chapter/step, edges d'ordre auteur, sideQuest autonome non intégrée au graph principal. |
 
 ## 14. V1 Creation Readiness Notes
 
@@ -965,6 +966,19 @@ Suite V1 documentaire recommandée :
 
 ## 15. Changelog
 
+### 2026-05-29 — NS-STORYLINES-V1-10
+
+- Graph From StorylineAsset V0 livré côté editor : le Graph affiche un canvas read-only généré depuis la `StorylineAsset` sélectionnée.
+- Nodes réels : storyline racine, chapitres triés par `order`, steps triées par `order`, empty states honnêtes pour storyline sans chapitre et chapitre sans step.
+- Edges visibles : uniquement ordre auteur racine -> premier chapitre puis chapitre -> chapitre suivant ; aucune branche narrative, availability, outcome ou convergence fake.
+- SideQuest sélectionnée : graph autonome avec badge `Quête annexe indépendante`, sans lien vers la main storyline.
+- Main sélectionnée avec sideQuests existantes : note d'intégration future, aucune sideQuest injectée comme node/branche du graph principal.
+- Structure reste source d'authoring ; le graph ne crée ni chapter, ni step, ni relationship, ni `SideQuestAvailability`, ni scene placeholder, ni `StorylineSceneLink`.
+- Aucun import legacy automatique ; `localEventFlow` reste exclu.
+- Fichiers créés/modifiés : `storylines_graph_model.dart`, `storylines_graph_painter.dart`, `storylines_graph_view.dart`, `storylines_workspace.dart`, `storylines_workspace_shell_test.dart`, captures V1-10, rapport V1-10.
+- Tests exécutés : `flutter test test/storylines_workspace_shell_test.dart`, `flutter test test/storylines_current_global_story_characterization_test.dart`, `flutter test test/narrative_workspace_projection_test.dart`, analyse ciblée, `rg` anti-couleurs.
+- Prochain lot recommandé : `NS-STORYLINES-V1-11 — Side Quest Graph Integration V0`.
+
 ### 2026-05-29 — NS-STORYLINES-V1-09
 
 - Create Side Quest Flow V0 livré côté editor : `Nouvelle storyline` peut créer une vraie `StorylineAsset(type: sideQuest, status: draft)` après existence d'une main storyline.
```

### Sortie exacte du test shell Storylines

Commande : `cd packages/map_editor && flutter test test/storylines_workspace_shell_test.dart`

Exit code : `0`

```text
00:00 +0: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/storylines_workspace_shell_test.dart
00:00 +0: NS-STORYLINES-V1-10 graph from StorylineAsset flow shows only Graph and Structure tabs
00:00 +1: NS-STORYLINES-V1-10 graph from StorylineAsset flow shows V1 empty state without importing legacy globalStory
00:00 +2: NS-STORYLINES-V1-10 graph from StorylineAsset flow opens and cancels create main storyline dialog without mutation
00:00 +3: NS-STORYLINES-V1-10 graph from StorylineAsset flow requires title before create
00:00 +4: NS-STORYLINES-V1-10 graph from StorylineAsset flow does not create sideQuest before a main storyline exists
00:01 +5: NS-STORYLINES-V1-10 graph from StorylineAsset flow dialog selects sideQuest when a main storyline exists
00:01 +6: NS-STORYLINES-V1-10 graph from StorylineAsset flow creates a main StorylineAsset and syncs Graph and Structure
00:01 +7: NS-STORYLINES-V1-10 graph from StorylineAsset flow creates a sideQuest StorylineAsset and selects it
00:01 +8: NS-STORYLINES-V1-10 graph from StorylineAsset flow Structure without storyline has no chapter or step action
00:01 +9: NS-STORYLINES-V1-10 graph from StorylineAsset flow opens and cancels create chapter without mutation
00:01 +10: NS-STORYLINES-V1-10 graph from StorylineAsset flow requires chapter title before create
00:01 +11: NS-STORYLINES-V1-10 graph from StorylineAsset flow creates chapters with stable ids, order and selection
00:02 +12: NS-STORYLINES-V1-10 graph from StorylineAsset flow step action requires a selected chapter
00:02 +13: NS-STORYLINES-V1-10 graph from StorylineAsset flow opens and cancels create step without mutation
00:02 +14: NS-STORYLINES-V1-10 graph from StorylineAsset flow requires step title before create
00:02 +15: NS-STORYLINES-V1-10 graph from StorylineAsset flow creates steps with global unique ids and order
00:02 +16: NS-STORYLINES-V1-10 graph from StorylineAsset flow Structure authoring works on sideQuest without mutating main
00:02 +17: NS-STORYLINES-V1-10 graph from StorylineAsset flow Graph summarizes created structure without fake edges
00:03 +18: NS-STORYLINES-V1-10 graph from StorylineAsset flow Graph orders chapters and steps by author order
00:03 +19: NS-STORYLINES-V1-10 graph from StorylineAsset flow Graph explains sideQuest is not linked to main graph yet
00:03 +20: NS-STORYLINES-V1-10 graph from StorylineAsset flow main graph does not show sideQuest as a branch yet
00:03 +21: NS-STORYLINES-V1-10 graph from StorylineAsset flow generates stable unique main ids on collision
00:03 +22: NS-STORYLINES-V1-10 graph from StorylineAsset flow generates stable unique sideQuest ids on collision
00:03 +23: NS-STORYLINES-V1-10 graph from StorylineAsset flow does not allow creating a second main storyline
00:03 +24: NS-STORYLINES-V1-10 graph from StorylineAsset flow creation does not import legacy or promote localEventFlow
00:04 +25: NS-STORYLINES-V1-10 graph from StorylineAsset flow sideQuest creation never imports legacy or localEventFlow
00:04 +26: NS-STORYLINES-V1-10 graph from StorylineAsset flow Graph, Structure and disabled future actions do not mutate
00:04 +27: NS-STORYLINES-V1-10 graph from StorylineAsset flow Structure authoring does not import legacy or localEventFlow
00:04 +28: NS-STORYLINES-V1-10 graph from StorylineAsset flow keeps target fake data and Maps out of the V1 UI
00:04 +29: NS-STORYLINES-V1-10 graph from StorylineAsset flow storylines UI source keeps raw colors out of the feature
00:04 +30: NS-STORYLINES-V1-10 graph from StorylineAsset flow storylines shell test keeps raw colors out
00:04 +31: NS-STORYLINES-V1-10 graph from StorylineAsset flow uses PokeMap dark theme in the Visual Gate harness
00:04 +32: NS-STORYLINES-V1-10 graph from StorylineAsset flow writes V1-10 Graph From StorylineAsset screenshots
00:04 +33: All tests passed!
```

### Sortie exacte de la régression Global Story characterization

Commande : `cd packages/map_editor && flutter test test/storylines_current_global_story_characterization_test.dart`

Exit code : `0`

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

### Sortie exacte de la régression projection narrative

Commande : `cd packages/map_editor && flutter test test/narrative_workspace_projection_test.dart`

Exit code : `0`

```text
00:00 +0: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/narrative_workspace_projection_test.dart
00:00 +0: buildNarrativeWorkspaceProjection splits global story and local flows, and projects steps
00:00 +1: buildNarrativeWorkspaceProjection projects ordered steps from Step Studio v1 metadata document
00:00 +2: buildNarrativeWorkspaceProjection projects chapters from Global Story Studio metadata
00:00 +3: All tests passed!
```

### Sortie exacte de flutter analyze ciblé

Commande : `cd packages/map_editor && flutter analyze --no-fatal-infos lib/src/ui/canvas/storylines_workspace.dart lib/src/ui/canvas/storylines/storylines_graph_model.dart lib/src/ui/canvas/storylines/storylines_graph_painter.dart lib/src/ui/canvas/storylines/storylines_graph_view.dart test/storylines_workspace_shell_test.dart test/storylines_current_global_story_characterization_test.dart test/narrative_workspace_projection_test.dart`

Exit code : `0`

```text
Analyzing 7 items...                                            
No issues found! (ran in 1.5s)
```

### Sortie exacte du rg anti-couleurs

Commande : `rg "Color\(0x|Colors\." packages/map_editor/lib/src/ui/canvas/storylines_workspace.dart packages/map_editor/lib/src/ui/canvas/storylines packages/map_editor/test/storylines_workspace_shell_test.dart`

Exit code : `1`

Sortie : <vide>

### Résultats du Visual Gate

```text
EXISTS reports/narrativeStudio/storylines/screenshots/ns_storylines_v1_10_graph_empty_storyline.png (42980 bytes)
EXISTS reports/narrativeStudio/storylines/screenshots/ns_storylines_v1_10_graph_main_chapters_steps.png (49729 bytes)
EXISTS reports/narrativeStudio/storylines/screenshots/ns_storylines_v1_10_graph_sidequest_standalone.png (47291 bytes)
EXISTS reports/narrativeStudio/storylines/screenshots/ns_storylines_v1_10_graph_main_ignores_sidequest.png (49729 bytes)
```

### Git status final exact

```text
 M packages/map_editor/lib/src/ui/canvas/storylines_workspace.dart
 M packages/map_editor/test/storylines_workspace_shell_test.dart
 M reports/narrativeStudio/storylines/road_map_storylines.md
?? packages/map_editor/lib/src/ui/canvas/storylines/storylines_graph_model.dart
?? packages/map_editor/lib/src/ui/canvas/storylines/storylines_graph_painter.dart
?? packages/map_editor/lib/src/ui/canvas/storylines/storylines_graph_view.dart
?? reports/narrativeStudio/storylines/ns_storylines_v1_10_graph_from_storyline_asset_v0.md
?? reports/narrativeStudio/storylines/screenshots/ns_storylines_v1_10_graph_empty_storyline.png
?? reports/narrativeStudio/storylines/screenshots/ns_storylines_v1_10_graph_main_chapters_steps.png
?? reports/narrativeStudio/storylines/screenshots/ns_storylines_v1_10_graph_main_ignores_sidequest.png
?? reports/narrativeStudio/storylines/screenshots/ns_storylines_v1_10_graph_sidequest_standalone.png
```

### Git diff --stat final

```text
 .../lib/src/ui/canvas/storylines_workspace.dart    | 135 ++--------
 .../test/storylines_workspace_shell_test.dart      | 299 ++++++++++++++++++---
 .../storylines/road_map_storylines.md              |  22 +-
 3 files changed, 301 insertions(+), 155 deletions(-)
```

### Git diff --name-only final

```text
packages/map_editor/lib/src/ui/canvas/storylines_workspace.dart
packages/map_editor/test/storylines_workspace_shell_test.dart
reports/narrativeStudio/storylines/road_map_storylines.md
```

### Git diff --check final

Sortie : <vide>

## 21. Self-review

- Le graph est généré depuis la `StorylineAsset` sélectionnée, pas depuis le legacy.
- Structure reste source d'authoring ; le graph est read-only.
- Edges V1-10 signifient uniquement ordre auteur.
- SideQuest sélectionnée autonome ; sideQuest non injectée dans le graph principal.
- Aucun `map_core`, runtime, gameplay ou battle modifié.
- Aucun `StorylineRelationship`, `SideQuestAvailability`, scene placeholder ou `StorylineSceneLink` créé.
- Les tests ciblés, régressions, analyse et Visual Gate passent.
- Risque restant : V1-11 devra ajouter l'intégration sideQuest sans transformer les edges d'ordre auteur V1-10 en edges de disponibilité implicites.
