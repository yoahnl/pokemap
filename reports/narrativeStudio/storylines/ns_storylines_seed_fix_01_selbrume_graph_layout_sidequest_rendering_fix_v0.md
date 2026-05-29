# NS-STORYLINES-SEED-FIX-01 — Selbrume Graph Layout / SideQuest Rendering Fix V0

## 1. Executive summary

Lot livré en correction editor-ui post-seed. Le graph Storylines affiche désormais les quêtes annexes attachées comme nodes secondaires indépendants autour du flux principal, reliées par des edges de disponibilité, et non plus comme contenu lourd à l'intérieur des cards de chapitre.

Le graph gagne aussi de la hauteur utile : KPI compactés en mode Graph, canvas minimum plus confortable, chapters plus étroits, steps compactées et overflow `+N étapes`. Aucune donnée seedée, aucun modèle core et aucun runtime n'ont été modifiés.

## 2. Inputs read

Fichiers lus :

- `AGENTS.md`
- `agent_rules.md`
- `skills/README.md`
- `reports/narrativeStudio/storylines/road_map_storylines.md`
- `reports/narrativeStudio/storylines/ns_storylines_seed_00_selbrume_storylines_demo_seed_v0.md`
- `selbrume/project.json`
- `packages/map_core/lib/src/models/storyline_asset.dart`
- `packages/map_editor/lib/src/ui/canvas/storylines_workspace.dart`
- `packages/map_editor/lib/src/ui/canvas/storylines/storylines_graph_model.dart`
- `packages/map_editor/lib/src/ui/canvas/storylines/storylines_graph_painter.dart`
- `packages/map_editor/lib/src/ui/canvas/storylines/storylines_graph_view.dart`
- `packages/map_editor/test/storylines_workspace_shell_test.dart`

Fichier attendu absent :

- `reports/narrativeStudio/storylines/ns_storylines_v1_checkpoint_acceptance.md`

## 3. Seed relationship audit

Audit de `selbrume/project.json` :

```text
47:              "id": "step_rival_battle",
66:              "id": "step_enter_marais",
84:              "id": "step_report_to_soline",
229:          "id": "relationship_salt_crystals_available_enter_marais",
230:          "kind": "sideQuestAvailableDuring",
236:              "targetId": "step_enter_marais"
320:          "id": "relationship_goelise_port_available_rival_battle",
321:          "kind": "sideQuestAvailableDuring",
327:              "targetId": "step_rival_battle"
411:          "id": "relationship_lighthouse_cabin_available_report_soline",
412:          "kind": "sideQuestAvailableDuring",
418:              "targetId": "step_report_to_soline"
```

Conclusion : les trois relationships Selbrume existent, pointent vers des steps réelles de la main storyline, et le modèle graph résout bien ces anchors step vers leur chapter parent.

Mapping vérifié par test :

- `story_side_salt_crystals` -> `step_enter_marais` -> `chapter_2_marais`
- `story_side_goelise_port` -> `step_rival_battle` -> `chapter_1_port`
- `story_side_lighthouse_cabin` -> `step_report_to_soline` -> `chapter_2_marais`

## 4. Product problem addressed

Le problème était côté rendu, pas côté seed : le modèle lisait déjà les relations, mais le rendu plaçait les quêtes annexes dans les chapter cards. Avec Selbrume, cela rendait le graph trop dense, trop petit, et visuellement ambigu.

## 5. Graph layout changes

- Canvas minimum augmenté à `640`.
- Lanes verticales dédiées aux sideQuests au-dessus / sous les chapters.
- Node racine et chapters rendus plus compacts en largeur.
- KPI Storylines compactés en mode Graph pour libérer la zone centrale.
- Scroll interne conservé quand le graph dépasse.

## 6. SideQuest rendering changes

- Les sideQuests attachées deviennent des widgets `_GraphSideQuestNode` positionnés hors des chapters.
- Les edges `sideQuestAttachment` relient chapter parent -> node sideQuest.
- Les chapter cards n'affichent plus de grandes cartes sideQuest.
- Le label sideQuest conserve `Disponible depuis Étape · ...`.

## 7. Chapter node compaction

- Les chapters affichent un compteur discret `N quêtes disponibles`.
- Les steps affichent titre + état scène seulement dans le graph.
- Les descriptions détaillées restent dans Structure.
- Les chapters limitent les steps visibles et affichent `+N étapes` si nécessaire.

## 8. No-mutation / no-data-change guarantee

`selbrume/project.json` n'a pas été modifié.

```text
git diff -- selbrume/project.json
Sortie : <vide>
```

Aucun `map_core`, runtime, gameplay, battle, modèle, relationship, sceneLink ou seed n'a été modifié.

## 9. Design System Gate

Recherche anti-couleurs :

```text
rg "Color\(0x|Colors\." packages/map_editor/lib/src/ui/canvas/storylines_workspace.dart packages/map_editor/lib/src/ui/canvas/storylines packages/map_editor/test/storylines_workspace_shell_test.dart packages/map_editor/test/storylines_seed_graph_usability_test.dart
Sortie : <vide>
```

Recherche anti-hardcode Selbrume dans le code produit :

```text
rg "La brume du phare|Les cristaux de sel|Le Goélise du port|La cabane du phare|Maël|Lysa|Mado|Yvon|Soline" packages/map_editor/lib packages/map_core/lib
Sortie : <vide>
```

Les couleurs du graph continuent de venir de `context.pokeMapColors`.

## 10. Tests added or modified

Fichier créé :

- `packages/map_editor/test/storylines_seed_graph_usability_test.dart`

Couverture ajoutée :

- audit des 3 relationships Selbrume ;
- anchors step réelles ;
- résolution step -> chapter parent ;
- nodes sideQuest distincts ;
- edges `sideQuestAttachment` distincts ;
- sideQuests hors des chapter cards ;
- hauteur de canvas minimale ;
- non-mutation du ProjectManifest et de `selbrume/project.json` ;
- Visual Gate seed fix.

## 11. Visual Gate

Captures produites :

```text
-rw-r--r--  1 karim  staff  45400 May 29 12:14 reports/narrativeStudio/storylines/screenshots/ns_storylines_seed_fix_01_selbrume_graph_main.png
-rw-r--r--  1 karim  staff  38924 May 29 12:14 reports/narrativeStudio/storylines/screenshots/ns_storylines_seed_fix_01_selbrume_graph_sidequest_nodes.png
-rw-r--r--  1 karim  staff  56702 May 29 12:14 reports/narrativeStudio/storylines/screenshots/ns_storylines_seed_fix_01_selbrume_structure_regression.png
```

Résultat : les captures dark montrent le graph Selbrume avec sideQuest nodes séparés et une capture Structure de régression.

## 12. Commands run

```text
git branch --show-current
main
```

```text
git status --short --untracked-files=all
Sortie : <vide>
```

```text
git diff --stat
Sortie : <vide>
```

```text
git diff --name-only
Sortie : <vide>
```

```text
git diff --check
Sortie : <vide>
```

```text
cd packages/map_editor && flutter test --reporter=compact test/storylines_seed_graph_usability_test.dart --update-goldens
00:02 +4: All tests passed!
```

```text
cd packages/map_editor && flutter test --reporter=compact test/storylines_seed_graph_usability_test.dart
00:02 +4: All tests passed!
```

```text
cd packages/map_editor && flutter test --reporter=compact test/storylines_workspace_shell_test.dart
00:06 +35 -1: NS-STORYLINES-V1-12 visual graph enrichment writes V1-12 polished graph screenshots [E]
Could not be compared against non-existent file:
"../../../reports/narrativeStudio/storylines/screenshots/ns_storylines_v1_12_graph_empty_polished.png"
00:06 +35 -1: Some tests failed.
```

```text
cd packages/map_editor && flutter test --reporter=compact test/storylines_current_global_story_characterization_test.dart
00:02 +2: All tests passed!
```

```text
cd packages/map_editor && flutter test --reporter=compact test/narrative_workspace_projection_test.dart
00:01 +3: All tests passed!
```

```text
cd packages/map_editor && flutter analyze --no-fatal-infos lib/src/ui/canvas/storylines_workspace.dart lib/src/ui/canvas/storylines/storylines_graph_model.dart lib/src/ui/canvas/storylines/storylines_graph_painter.dart lib/src/ui/canvas/storylines/storylines_graph_view.dart test/storylines_workspace_shell_test.dart test/storylines_current_global_story_characterization_test.dart test/narrative_workspace_projection_test.dart test/storylines_seed_graph_usability_test.dart
Analyzing 8 items...
No issues found! (ran in 1.7s)
```

## 13. Roadmap update

Roadmap mise à jour :

- `NS-STORYLINES-SEED-FIX-01` ajouté en `DONE`.
- Correction post-seed documentée.
- Graph plus grand documenté.
- SideQuests attachées comme nodes indépendants documentées.
- Aucun seed/model/runtime modifié confirmé.
- Prochain lot recommandé : `NS-STORYLINES-V1.1-01 — Basic Edit / Delete Flow V0`.

## 14. Evidence Pack

Git initial :

```text
git branch --show-current
main
```

```text
git status --short --untracked-files=all
Sortie : <vide>
```

```text
git diff --stat
Sortie : <vide>
```

```text
git diff --name-only
Sortie : <vide>
```

```text
git diff --check
Sortie : <vide>
```

Diff `storylines_graph_model.dart` :

```text
Sortie : <vide>
```

Diff `storylines_graph_painter.dart` :

```text
Sortie : <vide>
```

Diff `storylines_graph_view.dart` :

```diff
diff --git a/packages/map_editor/lib/src/ui/canvas/storylines/storylines_graph_view.dart b/packages/map_editor/lib/src/ui/canvas/storylines/storylines_graph_view.dart
index ef55cf69..0e63c5c1 100644
--- a/packages/map_editor/lib/src/ui/canvas/storylines/storylines_graph_view.dart
+++ b/packages/map_editor/lib/src/ui/canvas/storylines/storylines_graph_view.dart
@@ -8,6 +8,8 @@ import '../../design_system/design_system.dart';
 import 'storylines_graph_model.dart';
 import 'storylines_graph_painter.dart';
 
+const int _maxVisibleStepsPerChapter = 3;
+
 class StorylinesGraphView extends StatelessWidget {
@@ -86,14 +88,18 @@ class StorylinesGraphView extends StatelessWidget {
-  static const double _rootWidth = 240;
-  static const double _rootHeight = 196;
-  static const double _chapterWidth = 304;
-  static const double _chapterGap = 42;
-  static const double _rootToChapterGap = 68;
-  static const double _leftPadding = 30;
-  static const double _topPadding = 10;
-  static const double _stepHeight = 54;
+  static const double _rootWidth = 220;
+  static const double _rootHeight = 188;
+  static const double _chapterWidth = 270;
+  static const double _chapterGap = 36;
+  static const double _sideQuestWidth = 224;
+  static const double _sideQuestHeight = 112;
+  static const double _rootToChapterGap = 56;
+  static const double _leftPadding = 28;
+  static const double _topPadding = 22;
+  static const double _sideQuestBandHeight = 132;
+  static const double _sideQuestGap = 24;
+  static const double _stepHeight = 42;
@@
-        final contentHeight = math.max(
-          _topPadding + chapterHeight + 60,
-          _topPadding + _rootHeight + 160,
-        );
+        final sideQuestRowsAbove = _sideQuestRowsAbove();
+        final sideQuestBandAbove = sideQuestRowsAbove == 0
+            ? 0.0
+            : sideQuestRowsAbove * (_sideQuestHeight + _sideQuestGap);
+        final chapterTop = _topPadding + sideQuestBandAbove;
+        final sideQuestRowsBelow = _sideQuestRowsBelow();
+        final sideQuestBandBelow = sideQuestRowsBelow == 0
+            ? 0.0
+            : _sideQuestGap +
+                sideQuestRowsBelow * (_sideQuestHeight + _sideQuestGap);
+        final contentHeight = math.max(
+          chapterTop + chapterHeight + sideQuestBandBelow + _topPadding,
+          _topPadding + _sideQuestBandHeight + _rootHeight + 220,
+        );
@@
-              constraints.maxHeight.isFinite ? constraints.maxHeight : 520,
+              constraints.maxHeight.isFinite ? constraints.maxHeight : 640,
               contentHeight,
             )
+            .clamp(640.0, double.infinity)
@@
-          math.max(_topPadding, (canvasHeight - _rootHeight) / 2),
+          chapterTop + (chapterHeight - _rootHeight) / 2,
@@
-            _topPadding,
+            chapterTop,
@@
-        final paintEdges = _paintEdges(rootRect, chapterRects);
+        final sideQuestRects = _sideQuestRects(chapterRects);
+        final paintEdges = _paintEdges(rootRect, chapterRects, sideQuestRects);
@@
-                      for (final marker in _edgeMarkers(rootRect, chapterRects))
+                      for (final attachment in model.sideQuestAttachments)
+                        if (sideQuestRects[attachment.relationshipId] != null)
+                          _GraphNodePosition(
+                            rect: sideQuestRects[attachment.relationshipId]!,
+                            child: _GraphSideQuestNode(
+                              attachment: attachment,
+                            ),
+                          ),
+                      for (final marker in _edgeMarkers(
+                        rootRect,
+                        chapterRects,
+                        sideQuestRects,
+                      ))
@@
-    final attachmentCount = sideQuestAttachmentsForChapter(
-      model.sideQuestAttachments,
-      chapter.id,
-    ).length;
-    return math.max(1, chapter.steps.length) + attachmentCount;
+    if (chapter.steps.isEmpty) return 1;
+    return math.min(chapter.steps.length, _maxVisibleStepsPerChapter) +
+        (chapter.steps.length > _maxVisibleStepsPerChapter ? 1 : 0);
@@
-    return 150 + effectiveItems * (_stepHeight + 12);
+    return 144 + effectiveItems * (_stepHeight + 8);
   }
+
+  int _sideQuestRowsBelow() { ... }
+  int _sideQuestRowsAbove() { ... }
+  Map<String, Rect> _sideQuestRects(Map<String, Rect> chapterRects) { ... }
@@
-          from: Offset(chapterRect.left + 22, chapterRect.top + verticalOffset),
-          to: Offset(chapterRect.right - 22, chapterRect.top + verticalOffset),
+          from: sideQuestAbove
+              ? Offset(chapterRect.center.dx, chapterRect.top)
+              : Offset(chapterRect.center.dx, chapterRect.bottom),
+          to: sideQuestAbove
+              ? Offset(sideQuestRect.center.dx, sideQuestRect.bottom)
+              : Offset(sideQuestRect.center.dx, sideQuestRect.top),
@@
-          position: Offset(chapterRect.right - 18, chapterRect.bottom - 18),
+          position: sideQuestRect.center,
@@
-      if (attachments.isNotEmpty)
-        _GraphSectionCaption(
-          key: ValueKey('storylines-graph-sidequest-caption-${chapter.id}'),
-          label: 'Quêtes annexes disponibles ici',
-        ),
-      for (final attachment in attachments)
-        _GraphSideQuestChip(attachment: attachment),
@@
+        for (final step in visibleSteps) _GraphStepChip(step: step),
+        if (hiddenStepCount > 0)
+          _GraphOverflowChip(hiddenStepCount: hiddenStepCount),
@@
-              'Ordre ${chapter.order} · ${_formatCount(chapter.steps.length, 'étape', 'étapes')}',
+              [
+                'Ordre ${chapter.order}',
+                _formatCount(chapter.steps.length, 'étape', 'étapes'),
+                if (attachments.isNotEmpty)
+                  _formatCount(
+                    attachments.length,
+                    'quête disponible',
+                    'quêtes disponibles',
+                  ),
+              ].join(' · '),
@@
-              child: ListView.separated(
-                physics: const NeverScrollableScrollPhysics(),
-                itemBuilder: (context, index) => items[index],
-                separatorBuilder: (context, index) => const SizedBox(height: 8),
-                itemCount: items.length,
+              child: Column(
+                crossAxisAlignment: CrossAxisAlignment.stretch,
+                children: [
+                  for (var index = 0; index < items.length; index += 1) ...[
+                    items[index],
+                    if (index < items.length - 1) const SizedBox(height: 6),
+                  ],
+                ],
@@
-class _GraphSideQuestChip extends StatelessWidget {
-  const _GraphSideQuestChip({required this.attachment});
+class _GraphOverflowChip extends StatelessWidget { ... }
+
+class _GraphSideQuestNode extends StatelessWidget {
+  const _GraphSideQuestNode({required this.attachment});
@@
+            const _StorylinesGraphBadge(label: 'Quête annexe'),
```

Diff `storylines_workspace.dart` :

```diff
diff --git a/packages/map_editor/lib/src/ui/canvas/storylines_workspace.dart b/packages/map_editor/lib/src/ui/canvas/storylines_workspace.dart
index b4b8c73a..b93a38d3 100644
--- a/packages/map_editor/lib/src/ui/canvas/storylines_workspace.dart
+++ b/packages/map_editor/lib/src/ui/canvas/storylines_workspace.dart
@@ -909,8 +909,11 @@ class _StorylinesV1MainPanel extends StatelessWidget {
-          _StorylinesV1KpiStrip(storylines: storylines),
-          const SizedBox(height: 16),
+          _StorylinesV1KpiStrip(
+            storylines: storylines,
+            compact: selectedTab == _StorylineContentTab.graph,
+          ),
+          SizedBox(height: selectedTab == _StorylineContentTab.graph ? 10 : 16),
@@
-  const _StorylinesV1KpiStrip({required this.storylines});
+  const _StorylinesV1KpiStrip({
+    required this.storylines,
+    required this.compact,
+  });
@@
+    if (compact) {
+      return KeyedSubtree(
+        key: const ValueKey('storylines-kpi-strip'),
+        child: DecoratedBox(
+          decoration: BoxDecoration(
+            color: colors.controlSurface,
+            borderRadius: BorderRadius.circular(10),
+            border: Border.all(color: colors.borderSubtle),
+          ),
+          child: Padding(
+            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
+            child: Row(
+              children: [
+                Expanded(child: _StorylinesV1CompactKpi(label: 'Storylines', value: storylines.length.toString())),
+                const SizedBox(width: 10),
+                Expanded(child: _StorylinesV1CompactKpi(label: 'Chapters', value: chapterCount.toString())),
+                const SizedBox(width: 10),
+                Expanded(child: _StorylinesV1CompactKpi(label: 'Story Steps', value: stepCount.toString())),
+                const SizedBox(width: 10),
+                Expanded(child: _StorylinesV1CompactKpi(label: 'Scene Links', value: sceneLinkCount.toString())),
+              ],
+            ),
+          ),
+        ),
+      );
+    }
@@
+class _StorylinesV1CompactKpi extends StatelessWidget { ... }
```

Diff tests créés :

```diff
diff --git a/packages/map_editor/test/storylines_seed_graph_usability_test.dart b/packages/map_editor/test/storylines_seed_graph_usability_test.dart
new file mode 100644
index 00000000..8db10e21
--- /dev/null
+++ b/packages/map_editor/test/storylines_seed_graph_usability_test.dart
@@ -0,0 +1,359 @@
+import 'dart:convert';
+import 'dart:io';
+
+import 'package:flutter/material.dart';
+import 'package:flutter_test/flutter_test.dart';
+import 'package:flutter_riverpod/flutter_riverpod.dart';
+import 'package:map_core/map_core.dart';
+import 'package:map_editor/src/features/editor/state/editor_notifier.dart';
+import 'package:map_editor/src/features/editor/state/editor_state.dart';
+import 'package:map_editor/src/features/narrative/state/narrative_workspace_state.dart';
+import 'package:map_editor/src/theme/theme.dart';
+import 'package:map_editor/src/ui/canvas/narrative_workspace_canvas.dart';
+import 'package:map_editor/src/ui/canvas/storylines/storylines_graph_model.dart';
+import 'package:map_editor/src/ui/canvas/storylines/storylines_graph_view.dart';
+...
+  group('NS-STORYLINES-SEED-FIX-01 Selbrume graph usability', () {
+    test('reads seeded sideQuest relationships and resolves step anchors', () { ... });
+    testWidgets('renders sideQuest nodes outside chapter cards on a larger canvas', (tester) async { ... });
+    testWidgets('graph rendering does not mutate ProjectManifest or seed file', (tester) async { ... });
+    testWidgets('writes seed fix visual gate screenshots', (tester) async { ... });
+  });
+...
```

Diff `road_map_storylines.md` :

```diff
diff --git a/reports/narrativeStudio/storylines/road_map_storylines.md b/reports/narrativeStudio/storylines/road_map_storylines.md
index c647c8b5..28f69df9 100644
--- a/reports/narrativeStudio/storylines/road_map_storylines.md
+++ b/reports/narrativeStudio/storylines/road_map_storylines.md
@@ -317,6 +317,7 @@ Interprétation V0 :
+| NS-STORYLINES-SEED-FIX-01 | Selbrume Graph Layout / SideQuest Rendering Fix V0 | editor graph fix | DONE | NS-STORYLINES-V1.1-01 |
@@
-Current lot: NS-STORYLINES-SEED-00
+Current lot: NS-STORYLINES-SEED-FIX-01
@@
-Next recommended lot: NS-SCENES-V1 — Scene Placeholder + Scene Linking Foundation
+Next recommended lot: NS-STORYLINES-V1.1-01 — Basic Edit / Delete Flow V0
@@
+| NS-STORYLINES-SEED-FIX-01 | DONE | 2026-05-29 | Correction post-seed : graph plus grand, sideQuests attachées rendues comme nodes indépendants, aucun seed/model/runtime modifié. |
@@
+### 2026-05-29 — NS-STORYLINES-SEED-FIX-01
+- Correction post-seed du rendu graph Selbrume : canvas plus grand et KPI compactés en mode Graph.
+- Les sideQuests attachées sont désormais rendues comme nodes indépendants autour du flux principal, reliées par edges de disponibilité, et non comme grandes cartes incluses dans les chapters.
+- Les chapters affichent un compteur discret de quêtes disponibles et des steps compactées avec overflow `+N étapes`.
+- Aucun seed, modèle core, runtime, gameplay, battle ou fichier `selbrume/project.json` modifié.
+- Tests dédiés Selbrume ajoutés, captures Visual Gate dark produites, analyse ciblée clean ; `storylines_workspace_shell_test.dart` reste bloqué uniquement par le golden V1-12 absent du repo courant.
+- Prochain lot recommandé : `NS-STORYLINES-V1.1-01 — Basic Edit / Delete Flow V0`.
```

Git final :

```text
git status --short --untracked-files=all
 M packages/map_editor/lib/src/ui/canvas/storylines/storylines_graph_view.dart
 M packages/map_editor/lib/src/ui/canvas/storylines_workspace.dart
 M reports/narrativeStudio/storylines/road_map_storylines.md
?? packages/map_editor/test/storylines_seed_graph_usability_test.dart
?? reports/narrativeStudio/storylines/screenshots/ns_storylines_seed_fix_01_selbrume_graph_main.png
?? reports/narrativeStudio/storylines/screenshots/ns_storylines_seed_fix_01_selbrume_graph_sidequest_nodes.png
?? reports/narrativeStudio/storylines/screenshots/ns_storylines_seed_fix_01_selbrume_structure_regression.png
?? reports/narrativeStudio/storylines/ns_storylines_seed_fix_01_selbrume_graph_layout_sidequest_rendering_fix_v0.md
```

```text
git diff --check
Sortie : <vide>
```

## 15. Self-review

- Le fix reste limité au rendu graph, au shell KPI compact et aux tests/rapport/roadmap.
- Les données Selbrume n'ont pas été modifiées.
- Les sideQuests ne sont pas inventées : elles viennent uniquement des relationships existantes.
- La lisibilité progresse sans ajouter zoom, mini-map, édition, suppression ou nouvelle donnée métier.
- Risque résiduel : `storylines_workspace_shell_test.dart` garde un test golden V1-12 dépendant d'images absentes du repo courant ; les 35 autres tests de ce fichier passent.
