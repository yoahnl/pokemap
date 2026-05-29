# NS-SCENES-V1-06 — Graph Read-only Skeleton

## Résumé exécutif

Verdict : DONE.

Le placeholder `Graph — bientôt` est remplacé par un graph read-only réel. Le graph lit uniquement le `SceneAsset` sélectionné depuis `ProjectManifest.scenes`, affiche ses nodes et edges, utilise `SceneGraphLayout.nodeLayouts` quand complet, et calcule un fallback layout déterministe en mémoire quand le layout est absent ou incomplet.

Aucun authoring, drag and drop, node inspector, runtime, sceneLink ou mutation de projet n'est ajouté.

## Design gate / décision UI

- Placement : graph read-only dans la zone centrale, au-dessus des détails/outcomes/tags de la scène.
- Nodes : cards compactes positionnées dans un `Stack`, label type + titre/description.
- Edges : `CustomPainter` read-only, courbes simples, flèche, labels overlay.
- Layout réel : positions issues de `SceneGraphLayout.nodeLayouts` si chaque node a une position.
- Layout fallback : positions par niveaux dérivés des edges, stable, non persisté.
- Node kinds : icônes Cupertino + `PokeMapTone`; aucune couleur hardcodée.
- Edge labels : `SceneEdge.label` si présent, sinon `kind · fromPortId`.
- V1-07 préparé : aucun node selection state maintenant, aucun inspector complet.
- Primitives : `PokeMapCard`, `PokeMapIconTile`, `PokeMapTone`, `context.pokeMapColors`, `PokeMapPanel`.

## Scope réalisé

- Création de `SceneGraphReadOnlyView`.
- Enrichissement de `NarrativeSceneSummary` avec `graph` et `layout`.
- Remplacement du placeholder central par le graph read-only.
- Tests ajoutés pour layout réel, layout dérivé, nodes, edges, labels, non-mutation et absence d'inspector.
- Screenshot Visual Gate V1-06 créé.
- Roadmap mise à jour : V1-06 `DONE`, prochain lot V1-07.

## Fichiers créés/modifiés

Créés :

- `packages/map_editor/lib/src/ui/canvas/scenes/scene_graph_read_only_view.dart`
- `reports/narrativeStudio/scenes/ns_scenes_v1_06_graph_read_only_skeleton.md`
- `reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_06_graph_read_only_skeleton.png`

Modifiés :

- `packages/map_editor/lib/src/ui/canvas/scenes_workspace.dart`
- `packages/map_editor/lib/src/features/narrative/application/narrative_workspace_projection.dart`
- `packages/map_editor/test/scenes_workspace_shell_test.dart`
- `reports/narrativeStudio/scenes/road_map_scenes.md`

## Décisions techniques

- `SceneGraphReadOnlyView` est séparé pour éviter de regrossir `scenes_workspace.dart`.
- Le painter reçoit les couleurs depuis `context.pokeMapColors`; il ne connaît aucune palette hardcodée.
- Le fallback layout ne modifie jamais `SceneAsset.layout`.
- Les tests utilisent des scènes locales neutres uniquement dans le test.

## Layout réel / fallback layout

Layout réel :

```text
scene.layout.nodeLayouts contient tous les nodeId du graph.
Le widget utilise directement x/y.
Badge : Layout réel.
```

Fallback :

```text
scene.layout.nodeLayouts absent ou incomplet.
Le widget calcule des niveaux depuis SceneEdge.fromNodeId/toNodeId.
Chaque node reçoit une position stable en mémoire.
Badge : Layout dérivé.
Aucune écriture dans ProjectManifest.
```

## Écarts au prompt éventuels

- Pas de zoom/pan/minimap : non requis et hors scope.
- Pas de node selection : volontaire, réservé à V1-07.
- Le layout dérivé est simple ; suffisant pour un squelette read-only mais pas un moteur final de graph.

## Tests exécutés

Test rouge TDD :

```text
cd packages/map_editor && flutter test --reporter=compact test/scenes_workspace_shell_test.dart --plain-name 'uses a derived layout for scenes with incomplete layout'

Expected: exactly one matching candidate
Actual: _KeyWidgetFinder:<Found 0 widgets with key [<'scene-graph-read-only-view'>]: []>
Test failed.
```

Tests verts :

```text
cd packages/map_editor && flutter test --reporter=compact test/scenes_workspace_shell_test.dart
00:02 +8: All tests passed!
```

```text
cd packages/map_editor && flutter test --reporter=compact test/ui/canvas/narrative_overview_shell_navigation_test.dart
00:04 +19: All tests passed!
```

```text
cd packages/map_editor && flutter test --reporter=compact test/ui/canvas/narrative_studio_header_test.dart
00:02 +3: All tests passed!
```

```text
cd packages/map_editor && flutter test --reporter=compact test/narrative_workspace_projection_test.dart
00:01 +3: All tests passed!
```

Note : un lancement parallèle header/projection a échoué sur le startup lock natif Flutter (`objective_c.dylib`). Les commandes ont été relancées en séquentiel et ont passé.

## Résultats exacts

Sortie principale :

```text
00:01 +0: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/scenes_workspace_shell_test.dart
00:01 +0: NS-SCENES-V1-06 graph read-only skeleton Narrative Studio exposes a real Scenes navigation entry
00:02 +1: NS-SCENES-V1-06 graph read-only skeleton Narrative Studio exposes a real Scenes navigation entry
00:02 +1: NS-SCENES-V1-06 graph read-only skeleton shows an honest empty state when ProjectManifest.scenes is empty
00:02 +2: NS-SCENES-V1-06 graph read-only skeleton shows an honest empty state when ProjectManifest.scenes is empty
00:02 +2: NS-SCENES-V1-06 graph read-only skeleton disabled actions do not mutate ProjectManifest
00:02 +3: NS-SCENES-V1-06 graph read-only skeleton disabled actions do not mutate ProjectManifest
00:02 +3: NS-SCENES-V1-06 graph read-only skeleton shows real SceneAsset data in the read-only tree and summary
00:02 +4: NS-SCENES-V1-06 graph read-only skeleton shows real SceneAsset data in the read-only tree and summary
00:02 +4: NS-SCENES-V1-06 graph read-only skeleton uses a derived layout for scenes with incomplete layout
00:02 +5: NS-SCENES-V1-06 graph read-only skeleton uses a derived layout for scenes with incomplete layout
00:02 +5: NS-SCENES-V1-06 graph read-only skeleton local scene selection updates summary without mutating project
00:02 +6: NS-SCENES-V1-06 graph read-only skeleton local scene selection updates summary without mutating project
00:02 +6: NS-SCENES-V1-06 graph read-only skeleton Storylines workspace remains selectable
00:02 +7: NS-SCENES-V1-06 graph read-only skeleton Storylines workspace remains selectable
00:02 +7: NS-SCENES-V1-06 graph read-only skeleton writes V1-06 visual gate screenshot
00:02 +8: NS-SCENES-V1-06 graph read-only skeleton writes V1-06 visual gate screenshot
00:02 +8: All tests passed!
```

## Analyze exact

```text
cd packages/map_editor && flutter analyze --no-fatal-infos lib/src/ui/canvas/scenes_workspace.dart lib/src/ui/canvas/scenes/scene_graph_read_only_view.dart lib/src/features/narrative/application/narrative_workspace_projection.dart test/scenes_workspace_shell_test.dart test/ui/canvas/narrative_overview_shell_navigation_test.dart test/ui/canvas/narrative_studio_header_test.dart test/narrative_workspace_projection_test.dart

Analyzing 7 items...

No issues found! (ran in 1.9s)
```

## Visual Gate

Chemin :

```text
reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_06_graph_read_only_skeleton.png
```

Commande :

```text
cd packages/map_editor && flutter test --update-goldens --reporter=compact test/scenes_workspace_shell_test.dart --plain-name 'writes V1-06 visual gate screenshot'
00:02 +1: All tests passed!
```

Visible : workspace Scènes, arborescence gauche, scène locale de test sélectionnée, graph read-only central, nodes visibles, edges visibles, layout réel, actions désactivées, aucun node inspector complet.

## Git status initial

```text
pwd
/Users/karim/Project/pokemonProject

git branch --show-current
main

git status --short --untracked-files=all
Sortie : <vide>

git diff --stat
Sortie : <vide>

git log --oneline -n 10
7fcd3c87 chore: auto-commit changes
6bbff623 scènes workspace shell UI
3253c8d5 chore: auto-commit changes
e75b3876 chore: auto-commit changes
00bcaa4d chore: auto-commit changes
a85fc3c4 docs(scenes): add scene system audit and roadmap v1.0.0
af6c491b feat(storylines): update structure layout and tests v1.1.1
04cce3b7 feat(storylines): add structure layout chapter/step readability v1.1.0
2c536dbd feat(storylines): fix graph focus layout canvas priority
a428448e feat(storylines): fix Selbrume graph layout side quest rendering v0
```

## Git status final

```text
 M packages/map_editor/lib/src/features/narrative/application/narrative_workspace_projection.dart
 M packages/map_editor/lib/src/ui/canvas/scenes_workspace.dart
 M packages/map_editor/test/scenes_workspace_shell_test.dart
 M reports/narrativeStudio/scenes/road_map_scenes.md
?? packages/map_editor/lib/src/ui/canvas/scenes/scene_graph_read_only_view.dart
?? reports/narrativeStudio/scenes/ns_scenes_v1_06_graph_read_only_skeleton.md
?? reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_06_graph_read_only_skeleton.png
```

## Git diff --stat

```text
 .../narrative_workspace_projection.dart            |  6 ++
 .../lib/src/ui/canvas/scenes_workspace.dart        | 29 +--------
 .../test/scenes_workspace_shell_test.dart          | 71 ++++++++++++++++++++--
 reports/narrativeStudio/scenes/road_map_scenes.md  | 24 +++++++-
 4 files changed, 94 insertions(+), 36 deletions(-)
```

## Git diff --name-only

```text
packages/map_editor/lib/src/features/narrative/application/narrative_workspace_projection.dart
packages/map_editor/lib/src/ui/canvas/scenes_workspace.dart
packages/map_editor/test/scenes_workspace_shell_test.dart
reports/narrativeStudio/scenes/road_map_scenes.md
```

## Git diff --check

```text
Sortie : <vide>
```

## Evidence Pack

Fichiers obligatoires lus : tous présents.

Commandes principales :

```text
pwd
git branch --show-current
git status --short --untracked-files=all
git diff --stat
git log --oneline -n 10
flutter test --reporter=compact test/scenes_workspace_shell_test.dart --plain-name 'uses a derived layout for scenes with incomplete layout'
flutter test --update-goldens --reporter=compact test/scenes_workspace_shell_test.dart --plain-name 'writes V1-06 visual gate screenshot'
flutter test --reporter=compact test/scenes_workspace_shell_test.dart
flutter test --reporter=compact test/ui/canvas/narrative_overview_shell_navigation_test.dart
flutter test --reporter=compact test/ui/canvas/narrative_studio_header_test.dart
flutter test --reporter=compact test/narrative_workspace_projection_test.dart
flutter analyze --no-fatal-infos <fichiers cibles V1-06>
rg "Color\(0x|Colors\." packages/map_editor/lib/src/ui/canvas/scenes_workspace.dart packages/map_editor/lib/src/ui/canvas/scenes/scene_graph_read_only_view.dart packages/map_editor/test/scenes_workspace_shell_test.dart
rg "fakeScenes|demoScenes|hardcodedSceneList|Annonce au port|Selbrume Demo|Maël|Lysa|Port des Brisants|La brume du phare|Le Goélise" packages/map_editor/lib/src/ui/canvas/scenes_workspace.dart packages/map_editor/lib/src/ui/canvas/scenes/scene_graph_read_only_view.dart packages/map_editor/lib/src/features/narrative/application/narrative_workspace_projection.dart
git status --short --untracked-files=all
git diff --stat
git diff --name-only
git diff --check
```

Recherches :

```text
rg "Color\(0x|Colors\." packages/map_editor/lib/src/ui/canvas/scenes_workspace.dart packages/map_editor/lib/src/ui/canvas/scenes/scene_graph_read_only_view.dart packages/map_editor/test/scenes_workspace_shell_test.dart
Sortie : <vide>

rg "fakeScenes|demoScenes|hardcodedSceneList|Annonce au port|Selbrume Demo|Maël|Lysa|Port des Brisants|La brume du phare|Le Goélise" packages/map_editor/lib/src/ui/canvas/scenes_workspace.dart packages/map_editor/lib/src/ui/canvas/scenes/scene_graph_read_only_view.dart packages/map_editor/lib/src/features/narrative/application/narrative_workspace_projection.dart
Sortie : <vide>
```

Sections modifiées clefs :

```text
NarrativeSceneSummary ajoute graph et layout.
ScenesWorkspace remplace le placeholder par SceneGraphReadOnlyView.
SceneGraphReadOnlyView affiche nodes/edges/layout réel ou fallback.
Tests vérifient graph, nodes, edges, labels, layout réel, layout dérivé, non-mutation.
road_map_scenes.md marque V1-06 DONE et recommande V1-07.
```

Diff complet des fichiers suivis modifiés :

```diff
diff --git a/packages/map_editor/lib/src/features/narrative/application/narrative_workspace_projection.dart b/packages/map_editor/lib/src/features/narrative/application/narrative_workspace_projection.dart
index a08ecd44..399abad7 100644
--- a/packages/map_editor/lib/src/features/narrative/application/narrative_workspace_projection.dart
+++ b/packages/map_editor/lib/src/features/narrative/application/narrative_workspace_projection.dart
@@ -135,6 +135,8 @@ class NarrativeSceneSummary {
     required this.declaredOutcomeCount,
     required this.declaredOutcomes,
     required this.tags,
+    required this.graph,
+    required this.layout,
   });
 
   final String id;
@@ -147,6 +149,8 @@ class NarrativeSceneSummary {
   final int declaredOutcomeCount;
   final List<String> declaredOutcomes;
   final List<String> tags;
+  final SceneGraph graph;
+  final SceneGraphLayout layout;
 }
 
 /// Projection consolidée de la donnée narrative pour l'UI.
@@ -304,6 +308,8 @@ List<NarrativeSceneSummary> _buildSceneSummaries(List<SceneAsset> scenes) {
             outcome.label.trim().isEmpty ? outcome.id : outcome.label,
         ],
         tags: scene.tags.toList(growable: false),
+        graph: scene.graph,
+        layout: scene.layout,
       ),
   ];
 }
diff --git a/packages/map_editor/lib/src/ui/canvas/scenes_workspace.dart b/packages/map_editor/lib/src/ui/canvas/scenes_workspace.dart
index 7724b93f..db40589b 100644
--- a/packages/map_editor/lib/src/ui/canvas/scenes_workspace.dart
+++ b/packages/map_editor/lib/src/ui/canvas/scenes_workspace.dart
@@ -3,6 +3,7 @@ import 'package:flutter/cupertino.dart';
 import '../../features/narrative/application/narrative_workspace_projection.dart';
 import '../../theme/theme.dart';
 import '../design_system/design_system.dart';
+import 'scenes/scene_graph_read_only_view.dart';
 
 class ScenesWorkspace extends StatefulWidget {
   const ScenesWorkspace({
@@ -495,33 +496,7 @@ class _SelectedSceneSummary extends StatelessWidget {
             ],
           ),
           const SizedBox(height: 16),
-          PokeMapCard(
-            key: const ValueKey('scenes-graph-placeholder-read-only'),
-            padding: const EdgeInsets.all(14),
-            child: Row(
-              children: [
-                const PokeMapIconTile(
-                  icon: CupertinoIcons.circle_grid_hex,
-                  tone: PokeMapTone.neutral,
-                  size: 34,
-                  iconSize: 17,
-                ),
-                const SizedBox(width: 10),
-                Expanded(
-                  child: Text(
-                    'Le graph read-only arrive dans NS-SCENES-V1-06. '
-                    'Aucun canvas, node ou edge n’est rendu dans ce lot.',
-                    style: TextStyle(
-                      color: colors.textSecondary,
-                      fontSize: 12,
-                      height: 1.35,
-                      fontWeight: FontWeight.w700,
-                    ),
-                  ),
-                ),
-              ],
-            ),
-          ),
+          SceneGraphReadOnlyView(scene: scene),
           const SizedBox(height: 16),
           _SceneDetailsSection(scene: scene),
           const SizedBox(height: 16),
diff --git a/packages/map_editor/test/scenes_workspace_shell_test.dart b/packages/map_editor/test/scenes_workspace_shell_test.dart
index f0259c2c..1c26cd8c 100644
--- a/packages/map_editor/test/scenes_workspace_shell_test.dart
+++ b/packages/map_editor/test/scenes_workspace_shell_test.dart
@@ -9,7 +9,7 @@ import 'package:map_editor/src/ui/canvas/narrative_workspace_canvas.dart';
 import 'package:map_editor/src/ui/design_system/design_system.dart';
 
 void main() {
-  group('NS-SCENES-V1-05 scene tree panel read-only', () {
+  group('NS-SCENES-V1-06 graph read-only skeleton', () {
     testWidgets('Narrative Studio exposes a real Scenes navigation entry',
         (tester) async {
       final container = await _pumpNarrativeShell(
@@ -111,10 +111,53 @@ void main() {
       expect(find.text('chapter_test'), findsWidgets);
       expect(find.text('Intro done'), findsOneWidget);
       expect(find.text('Branch done'), findsOneWidget);
-      expect(find.byKey(const ValueKey('scene-graph-canvas')), findsNothing);
+      expect(
+        find.byKey(const ValueKey('scene-graph-read-only-view')),
+        findsOneWidget,
+      );
+      expect(find.byKey(const ValueKey('scene-graph-layout-source-real')),
+          findsOneWidget);
+      expect(find.byKey(const ValueKey('scene-graph-node-node_start')),
+          findsOneWidget);
+      expect(find.byKey(const ValueKey('scene-graph-node-node_merge')),
+          findsOneWidget);
+      expect(find.byKey(const ValueKey('scene-graph-edge-edge_start_merge')),
+          findsOneWidget);
+      expect(find.text('completed'), findsWidgets);
       expect(find.byKey(const ValueKey('scene-node-inspector')), findsNothing);
     });
 
+    testWidgets('uses a derived layout for scenes with incomplete layout',
+        (tester) async {
+      final project = _projectWithTwoScenes();
+      final container = await _pumpNarrativeShell(
+        tester,
+        project: project,
+        workspaceMode: EditorWorkspaceMode.scenes,
+      );
+
+      await tester.tap(
+        find.byKey(const ValueKey('scenes-tree-item-scene_test_branch')),
+      );
+      await tester.pumpAndSettle();
+
+      expect(
+        find.byKey(const ValueKey('scene-graph-read-only-view')),
+        findsOneWidget,
+      );
+      expect(
+        find.byKey(const ValueKey('scene-graph-layout-source-derived')),
+        findsOneWidget,
+      );
+      expect(find.byKey(const ValueKey('scene-graph-node-node_start')),
+          findsOneWidget);
+      expect(find.byKey(const ValueKey('scene-graph-node-node_end')),
+          findsOneWidget);
+      expect(find.byKey(const ValueKey('scene-graph-edge-edge_start_end')),
+          findsOneWidget);
+      expect(container.read(editorNotifierProvider).project, equals(project));
+    });
+
     testWidgets(
         'local scene selection updates summary without mutating project',
         (tester) async {
@@ -142,6 +185,8 @@ void main() {
         findsOneWidget,
       );
       expect(find.text('Second Test Scene'), findsWidgets);
+      expect(find.byKey(const ValueKey('scene-graph-layout-source-derived')),
+          findsOneWidget);
       expect(container.read(editorNotifierProvider).project, equals(project));
     });
 
@@ -167,7 +212,7 @@ void main() {
       );
     });
 
-    testWidgets('writes V1-05 visual gate screenshot', (tester) async {
+    testWidgets('writes V1-06 visual gate screenshot', (tester) async {
       await _pumpNarrativeShell(
         tester,
         project: _projectWithTwoScenes(),
@@ -178,7 +223,7 @@ void main() {
         find.byKey(const ValueKey('scenes-workspace-shell')),
         matchesGoldenFile(
           '../../../reports/narrativeStudio/scenes/screenshots/'
-          'ns_scenes_v1_05_scene_tree_panel_read_only.png',
+          'ns_scenes_v1_06_graph_read_only_skeleton.png',
         ),
       );
     });
@@ -269,8 +314,13 @@ SceneAsset _testIntroScene() {
       startNodeId: 'node_start',
       nodes: [
         SceneNode(id: 'node_start', kind: SceneNodeKind.start),
-        SceneNode(id: 'node_merge', kind: SceneNodeKind.merge),
-        SceneNode(id: 'node_end', kind: SceneNodeKind.end),
+        SceneNode(
+          id: 'node_merge',
+          kind: SceneNodeKind.merge,
+          title: 'Merge test',
+          description: 'Node réel de test.',
+        ),
+        SceneNode(id: 'node_end', kind: SceneNodeKind.end, title: 'End test'),
       ],
       edges: [
         SceneEdge(
@@ -279,6 +329,7 @@ SceneAsset _testIntroScene() {
           fromPortId: 'completed',
           toNodeId: 'node_merge',
           kind: SceneEdgeKind.defaultFlow,
+          label: 'completed',
         ),
         SceneEdge(
           id: 'edge_merge_end',
@@ -286,9 +337,17 @@ SceneAsset _testIntroScene() {
           fromPortId: 'completed',
           toNodeId: 'node_end',
           kind: SceneEdgeKind.defaultFlow,
+          label: 'done',
         ),
       ],
     ),
+    layout: SceneGraphLayout(
+      nodeLayouts: [
+        SceneNodeLayout(nodeId: 'node_start', x: 24, y: 80),
+        SceneNodeLayout(nodeId: 'node_merge', x: 260, y: 80),
+        SceneNodeLayout(nodeId: 'node_end', x: 500, y: 80),
+      ],
+    ),
     declaredOutcomes: [
       SceneOutcome(id: 'intro_done', label: 'Intro done'),
       SceneOutcome(id: 'branch_done', label: 'Branch done'),
diff --git a/reports/narrativeStudio/scenes/road_map_scenes.md b/reports/narrativeStudio/scenes/road_map_scenes.md
index 65ce336c..8895842d 100644
--- a/reports/narrativeStudio/scenes/road_map_scenes.md
+++ b/reports/narrativeStudio/scenes/road_map_scenes.md
@@ -42,7 +42,7 @@ Ces briques sont utiles, mais elles ne constituent pas encore une Scene V1 propr
 | NS-SCENES-V1-03 — Scene Core Model V0 | DONE | Modele core `SceneAsset` ajoute dans `map_core` avec `SceneGraph`, `SceneGraphLayout`, nodes/edges/outcomes, `ProjectManifest.scenes`, export public et tests core/JSON/manifest. |
 | NS-SCENES-V1-04 — Workspace Shell Scenes | DONE | Shell editor `Scenes` branche dans Narrative Studio, lecture read-only de `ProjectManifest.scenes`, empty state honnete, actions non supportees desactivees. |
 | NS-SCENES-V1-05 — Scene Tree Panel Read-only | DONE | Arborescence read-only des scenes reelles, selection locale, resume central, header Scenes compacte, aucun graph ni mutation. |
-| NS-SCENES-V1-06 — Graph Read-only Skeleton | TODO | Afficher un graph Scene V1 read-only avec start/end et nodes reels du read model. |
+| NS-SCENES-V1-06 — Graph Read-only Skeleton | DONE | Graph Scene V1 read-only depuis le `SceneAsset` selectionne : nodes, edges, labels, layout persiste ou layout derive non persiste. |
 | NS-SCENES-V1-07 — Node Inspector Read-only | TODO | Inspecteur contextuel pour node selectionne, conditions, sorties et notes. |
 | NS-SCENES-V1-08 — Authoring Minimal Scene Draft | TODO | Creer/editer une scene draft minimale, sans brancher Storylines ni runtime complet. |
 | NS-SCENES-V1-09 — Scene Validation Diagnostics | TODO | Diagnostics de graphe : start/end, edges invalides, nodes incomplets, refs manquantes, outcomes orphelins. |
@@ -51,9 +51,27 @@ Ces briques sont utiles, mais elles ne constituent pas encore une Scene V1 propr
 
 ## Prochain lot recommande
 
-`NS-SCENES-V1-06 — Graph Read-only Skeleton`
+`NS-SCENES-V1-07 — Node Inspector Read-only`
 
-Raison : le workspace Scenes possede maintenant un panneau d'arborescence read-only, une selection locale de scene et un resume central derive de `ProjectManifest.scenes`. Le prochain lot peut ajouter un squelette de graph read-only sans authoring, sans runtime et sans mutation.
+Raison : le workspace Scenes affiche maintenant un graph read-only reel pour la scene selectionnee. Le prochain lot peut ajouter un inspecteur read-only du node selectionne, sans authoring ni runtime.
+
+## Decisions V1-06
+
+- Le placeholder `Graph — bientôt` est remplace par `SceneGraphReadOnlyView`.
+- Le graph lit `scene.graph.nodes`, `scene.graph.edges` et `scene.layout.nodeLayouts`.
+- Un layout persiste complet est utilise tel quel.
+- Si le layout est absent ou incomplet, un layout derive deterministe est calcule en memoire et non persiste.
+- Les edges sont dessines par un `CustomPainter` read-only avec couleurs injectees depuis le theme.
+- Les labels d'edges viennent de `SceneEdge.label` ou du couple `kind/fromPortId`.
+- Aucun node inspector, drag and drop, edition de node/edge ou runtime n'est ajoute.
+
+## Limites V1-06
+
+- Layout derive simple, suffisant pour V1-06 mais pas un moteur de graph final.
+- Pas de zoom/pan/minimap.
+- Pas de selection de node.
+- Pas de payload detaille.
+- Pas d'inspecteur read-only avant V1-07.
 
 ## Decisions V1-05
```

Contenu complet du nouveau fichier source `packages/map_editor/lib/src/ui/canvas/scenes/scene_graph_read_only_view.dart` :

```dart
import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:map_core/map_core.dart';

import '../../../features/narrative/application/narrative_workspace_projection.dart';
import '../../../theme/theme.dart';
import '../../design_system/design_system.dart';

class SceneGraphReadOnlyView extends StatelessWidget {
  const SceneGraphReadOnlyView({
    super.key,
    required this.scene,
  });

  final NarrativeSceneSummary scene;

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    final layout = _SceneGraphLayoutPlan.fromScene(scene);

    return PokeMapCard(
      key: const ValueKey('scene-graph-read-only-view'),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const PokeMapIconTile(
                icon: CupertinoIcons.flowchart,
                tone: PokeMapTone.narrative,
                size: 34,
                iconSize: 17,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Graph read-only',
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              _SceneGraphBadge(
                key: ValueKey(
                  layout.usesPersistedLayout
                      ? 'scene-graph-layout-source-real'
                      : 'scene-graph-layout-source-derived',
                ),
                label: layout.usesPersistedLayout
                    ? 'Layout réel'
                    : 'Layout dérivé',
              ),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: layout.canvasHeight,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: colors.backgroundShell,
                  border: Border.all(color: colors.borderSubtle),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: CustomPaint(
                        painter: _SceneGraphEdgePainter(
                          edges: scene.graph.edges,
                          positions: layout.positions,
                          lineColor: colors.borderStrong,
                          labelColor: colors.textSecondary,
                          labelBackground: colors.cardSurface,
                        ),
                      ),
                    ),
                    for (final node in scene.graph.nodes)
                      _SceneGraphNodeCard(
                        node: node,
                        position: layout.positions[node.id]!,
                      ),
                    for (final edge in scene.graph.edges)
                      _SceneGraphEdgeLabel(
                        edge: edge,
                        position: layout.edgeLabelPosition(edge),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SceneGraphNodeCard extends StatelessWidget {
  const _SceneGraphNodeCard({
    required this.node,
    required this.position,
  });

  final SceneNode node;
  final Offset position;

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    final tone = _toneForNode(node.kind);
    return Positioned(
      left: position.dx,
      top: position.dy,
      width: _SceneGraphLayoutPlan.nodeWidth,
      height: _SceneGraphLayoutPlan.nodeHeight,
      child: PokeMapCard(
        key: ValueKey('scene-graph-node-${node.id}'),
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                PokeMapIconTile(
                  icon: _iconForNode(node.kind),
                  tone: tone,
                  size: 24,
                  iconSize: 13,
                ),
                const SizedBox(width: 7),
                Expanded(
                  child: Text(
                    node.title ?? _nodeKindLabel(node.kind),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: colors.textPrimary,
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              _nodeKindLabel(node.kind),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: colors.textSecondary,
                fontSize: 10,
                fontWeight: FontWeight.w800,
              ),
            ),
            if (node.description != null) ...[
              const SizedBox(height: 4),
              Text(
                node.description!,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: colors.textMuted,
                  fontSize: 10,
                  height: 1.2,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SceneGraphEdgeLabel extends StatelessWidget {
  const _SceneGraphEdgeLabel({
    required this.edge,
    required this.position,
  });

  final SceneEdge edge;
  final Offset position;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      key: ValueKey('scene-graph-edge-${edge.id}'),
      left: position.dx,
      top: position.dy,
      child: _SceneGraphBadge(
        label:
            edge.label ?? '${_edgeKindLabel(edge.kind)} · ${edge.fromPortId}',
      ),
    );
  }
}

class _SceneGraphBadge extends StatelessWidget {
  const _SceneGraphBadge({
    super.key,
    required this.label,
  });

  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.controlSurface,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: colors.borderSubtle),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Text(
          label,
          style: TextStyle(
            color: colors.textSecondary,
            fontSize: 10,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class _SceneGraphEdgePainter extends CustomPainter {
  const _SceneGraphEdgePainter({
    required this.edges,
    required this.positions,
    required this.lineColor,
    required this.labelColor,
    required this.labelBackground,
  });

  final List<SceneEdge> edges;
  final Map<String, Offset> positions;
  final Color lineColor;
  final Color labelColor;
  final Color labelBackground;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = lineColor
      ..strokeWidth = 1.4
      ..style = PaintingStyle.stroke;

    for (final edge in edges) {
      final from = positions[edge.fromNodeId];
      final to = positions[edge.toNodeId];
      if (from == null || to == null) {
        continue;
      }
      final start = Offset(
        from.dx + _SceneGraphLayoutPlan.nodeWidth,
        from.dy + (_SceneGraphLayoutPlan.nodeHeight / 2),
      );
      final end = Offset(
        to.dx,
        to.dy + (_SceneGraphLayoutPlan.nodeHeight / 2),
      );
      final controlDistance = math.max(48, (end.dx - start.dx).abs() / 2);
      final path = Path()
        ..moveTo(start.dx, start.dy)
        ..cubicTo(
          start.dx + controlDistance,
          start.dy,
          end.dx - controlDistance,
          end.dy,
          end.dx,
          end.dy,
        );
      canvas.drawPath(path, paint);
      _drawArrow(canvas, paint, end);
    }
  }

  void _drawArrow(Canvas canvas, Paint paint, Offset end) {
    final path = Path()
      ..moveTo(end.dx, end.dy)
      ..lineTo(end.dx - 7, end.dy - 4)
      ..moveTo(end.dx, end.dy)
      ..lineTo(end.dx - 7, end.dy + 4);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _SceneGraphEdgePainter oldDelegate) {
    return oldDelegate.edges != edges ||
        oldDelegate.positions != positions ||
        oldDelegate.lineColor != lineColor ||
        oldDelegate.labelColor != labelColor ||
        oldDelegate.labelBackground != labelBackground;
  }
}

class _SceneGraphLayoutPlan {
  const _SceneGraphLayoutPlan({
    required this.positions,
    required this.usesPersistedLayout,
    required this.canvasHeight,
  });

  static const nodeWidth = 168.0;
  static const nodeHeight = 104.0;
  static const horizontalGap = 92.0;
  static const verticalGap = 34.0;

  final Map<String, Offset> positions;
  final bool usesPersistedLayout;
  final double canvasHeight;

  static _SceneGraphLayoutPlan fromScene(NarrativeSceneSummary scene) {
    final persisted = {
      for (final layout in scene.layout.nodeLayouts)
        layout.nodeId: Offset(layout.x, layout.y),
    };
    final hasCompleteLayout =
        scene.graph.nodes.every((node) => persisted.containsKey(node.id));
    final positions = hasCompleteLayout
        ? persisted
        : _derivePositions(scene.graph.nodes, scene.graph.edges);

    final maxY = positions.values.fold<double>(
      0,
      (value, position) => math.max(value, position.dy),
    );
    return _SceneGraphLayoutPlan(
      positions: positions,
      usesPersistedLayout: hasCompleteLayout && positions.isNotEmpty,
      canvasHeight: math.max(280, maxY + nodeHeight + 32),
    );
  }

  static Map<String, Offset> _derivePositions(
    List<SceneNode> nodes,
    List<SceneEdge> edges,
  ) {
    final levels = <String, int>{};
    if (nodes.isEmpty) {
      return {};
    }
    levels[nodes.first.id] = 0;
    var changed = true;
    while (changed) {
      changed = false;
      for (final edge in edges) {
        final fromLevel = levels[edge.fromNodeId];
        if (fromLevel == null) {
          continue;
        }
        final next = fromLevel + 1;
        if ((levels[edge.toNodeId] ?? -1) < next) {
          levels[edge.toNodeId] = next;
          changed = true;
        }
      }
    }
    for (var index = 0; index < nodes.length; index++) {
      levels.putIfAbsent(nodes[index].id, () => index);
    }

    final rowByLevel = <int, int>{};
    final positions = <String, Offset>{};
    for (final node in nodes) {
      final level = levels[node.id] ?? 0;
      final row =
          rowByLevel.update(level, (value) => value + 1, ifAbsent: () => 0);
      positions[node.id] = Offset(
        24 + (level * (nodeWidth + horizontalGap)),
        42 + (row * (nodeHeight + verticalGap)),
      );
    }
    return positions;
  }

  Offset edgeLabelPosition(SceneEdge edge) {
    final from = positions[edge.fromNodeId];
    final to = positions[edge.toNodeId];
    if (from == null || to == null) {
      return const Offset(12, 12);
    }
    return Offset(
      (from.dx + to.dx + nodeWidth) / 2 - 38,
      (from.dy + to.dy + nodeHeight) / 2 - 14,
    );
  }
}

PokeMapTone _toneForNode(SceneNodeKind kind) {
  return switch (kind) {
    SceneNodeKind.start => PokeMapTone.success,
    SceneNodeKind.end => PokeMapTone.info,
    SceneNodeKind.yarnDialogue => PokeMapTone.info,
    SceneNodeKind.condition => PokeMapTone.warning,
    SceneNodeKind.action => PokeMapTone.warning,
    SceneNodeKind.battle => PokeMapTone.danger,
    SceneNodeKind.cinematic => PokeMapTone.narrative,
    SceneNodeKind.branchByOutcome => PokeMapTone.narrative,
    SceneNodeKind.merge => PokeMapTone.neutral,
  };
}

IconData _iconForNode(SceneNodeKind kind) {
  return switch (kind) {
    SceneNodeKind.start => CupertinoIcons.play_circle,
    SceneNodeKind.end => CupertinoIcons.flag,
    SceneNodeKind.yarnDialogue => CupertinoIcons.text_bubble,
    SceneNodeKind.condition => CupertinoIcons.check_mark_circled,
    SceneNodeKind.action => CupertinoIcons.bolt,
    SceneNodeKind.battle => CupertinoIcons.asterisk_circle,
    SceneNodeKind.cinematic => CupertinoIcons.film,
    SceneNodeKind.branchByOutcome => CupertinoIcons.arrow_branch,
    SceneNodeKind.merge => CupertinoIcons.arrow_merge,
  };
}

String _nodeKindLabel(SceneNodeKind kind) {
  return switch (kind) {
    SceneNodeKind.start => 'Début',
    SceneNodeKind.end => 'Fin',
    SceneNodeKind.yarnDialogue => 'Dialogue Yarn',
    SceneNodeKind.condition => 'Condition',
    SceneNodeKind.action => 'Action',
    SceneNodeKind.battle => 'Combat',
    SceneNodeKind.cinematic => 'Cinématique',
    SceneNodeKind.branchByOutcome => 'Branche',
    SceneNodeKind.merge => 'Merge',
  };
}

String _edgeKindLabel(SceneEdgeKind kind) {
  return switch (kind) {
    SceneEdgeKind.defaultFlow => 'default',
    SceneEdgeKind.conditionTrue => 'true',
    SceneEdgeKind.conditionFalse => 'false',
    SceneEdgeKind.dialogueOutcome => 'dialogue',
    SceneEdgeKind.battleVictory => 'victory',
    SceneEdgeKind.battleDefeat => 'defeat',
    SceneEdgeKind.cinematicCompleted => 'cinematic',
    SceneEdgeKind.actionCompleted => 'action',
    SceneEdgeKind.branchOutcome => 'branch',
    SceneEdgeKind.error => 'error',
    SceneEdgeKind.blocked => 'blocked',
  };
}
```

## Auto-review critique

- Le graph est lisible et strictement read-only.
- Le fallback layout est volontairement simple ; il faudra le remplacer par un layout plus robuste si les scènes deviennent larges.
- Le painter ne dépend pas du runtime ni du layout UI pour exécuter une scène.
- Aucun node selection state n'est ajouté, ce qui garde V1-07 propre.

## Regard critique sur le prompt

Le prompt est bien borné : il demande un vrai graph mais interdit le builder. Le risque principal était de glisser vers de l'interaction ; ce lot l'évite en limitant le widget à un rendu stable et non mutable.
