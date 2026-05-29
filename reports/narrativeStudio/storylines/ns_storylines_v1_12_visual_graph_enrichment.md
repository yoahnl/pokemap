# NS-STORYLINES-V1-12 — V1 Visual Graph Enrichment

## 1. Executive summary

NS-STORYLINES-V1-12 est livré en visual-only. Le graph Storylines V1 reste read-only et généré depuis les `StorylineAsset`, mais il gagne une légende compacte, une hiérarchie visuelle plus claire, des nodes sideQuest attachées plus distinctes, et des edges de disponibilité différenciés des edges d'ordre auteur.

## 2. Inputs read

- `AGENTS.md`
- `agent_rules.md`
- `skills/README.md`
- `reports/narrativeStudio/storylines/road_map_storylines.md`
- `reports/narrativeStudio/storylines/ns_storylines_v1_11_side_quest_attachment_graph_integration_v0.md` : absent
- `reports/narrativeStudio/storylines/ns_storylines_v1_10_graph_from_storyline_asset_v0.md` : absent
- `reports/narrativeStudio/storylines/ns_storylines_v1_09_create_side_quest_flow_v0.md` : absent
- `reports/narrativeStudio/storylines/ns_storylines_v1_08_structure_tab_authoring_v0.md` : absent
- `reports/narrativeStudio/storylines/ns_storylines_v1_00_storyline_semantics_and_usable_authoring_contract.md` : absent
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
- `packages/map_editor/lib/src/ui/design_system/design_system.dart`
- `packages/map_editor/lib/src/ui/design_system/pokemap_tone.dart`
- `packages/map_editor/lib/src/ui/design_system/pokemap_dashboard_primitives.dart`
- `packages/map_editor/lib/src/ui/design_system/pokemap_button.dart`
- `packages/map_editor/lib/src/ui/design_system/pokemap_card.dart`
- `packages/map_editor/lib/src/ui/design_system/pokemap_panel.dart`
- `packages/map_editor/lib/src/theme/pokemap_color_tokens.dart`
- `packages/map_editor/lib/src/theme/theme.dart`

## 3. Product problem addressed

Le graph V1-11 était correct fonctionnellement, mais trop brut pour un checkpoint : légende implicite, sideQuest attachée peu différenciée, edges non distingués visuellement, et densité desktop perfectible. V1-12 améliore la lisibilité sans ajouter de nouvelle logique métier.

## 4. Implementation summary

- Ajout de compteurs view-only `chapterCount` / `stepCount` sur les attachments sideQuest du modèle graph editor.
- Ajout d'une couleur de disponibilité transmise au `CustomPainter` depuis `context.pokeMapColors`.
- Rendu des edges `sideQuestAttachment` en pointillé avec arrowhead plus discrète.
- Remplacement de la rangée de badges implicite par une légende compacte et testable.
- Repositionnement visuel des sideQuests attachées dans les chapters pour éviter le clipping en capture desktop.
- Mise à jour des tests shell et des goldens V1-12.

## 5. Visual changes

- Canvas plus dense avec nodes chapters plus larges.
- Root node plus explicite avec libellé `Storyline`.
- Chapters annotés avec `Chapitre N`.
- Steps plus compacts, avec description courte quand disponible.
- SideQuest attachée en surface warning, distincte des chapters et des steps.

## 6. Graph layout improvements

Le layout reste dans `storylines_graph_view.dart` et garde le canvas scrollable. Les espacements et dimensions de nodes ont été ajustés pour mieux exploiter le desktop 1600x1000 sans ajouter de zoom, mini-map ou interaction graph.

## 7. Node hierarchy improvements

La hiérarchie visuelle distingue maintenant :

- Storyline root : node sélectionné et titré.
- Chapter : bloc principal, ordre visible.
- Step : chip secondaire compact.
- SideQuest attachée : chip warning avec disponibilité.

## 8. Edge and legend improvements

La légende clarifie :

- `Ordre auteur`
- `Disponibilité quête annexe`

Les edges d'ordre auteur restent pleins. Les edges de disponibilité sideQuest sont pointillés et utilisent un ton issu du design system.

## 9. Side quest visual treatment

Une sideQuest attachée affiche son titre, son type, ses compteurs réels chapters/steps, et `Disponible depuis ...`. Une sideQuest non attachée reste absente du graph principal. Une sideQuest sélectionnée conserve son graph autonome.

## 10. Empty state treatment

Le message de storyline sans chapter reste honnête : le graph reste vide tant qu'aucun chapitre réel n'existe. Aucun graph legacy ni donnée cible fake n'est affiché.

## 11. Read-only / no-mutation guarantee

V1-12 ne crée aucune donnée. Le graph reste read-only. Les tests existants de non-mutation restent verts.

## 12. Structure source-of-authoring guarantee

Structure reste la source d'authoring pour créer storylines, chapters, steps et attachments. Le graph ne devient pas éditeur.

## 13. Legacy non-import guarantee

Aucun import legacy automatique n'a été ajouté ou appelé. Les tests legacy existants restent verts.

## 14. localEventFlow exclusion

`localEventFlow` reste exclu des storylines, sideQuests, chapters, steps et nodes graph.

## 15. Non-goals confirmed

- Aucun `map_core` modifié.
- Aucun `ProjectManifest`, `StorylineAsset` ou `ScenarioAsset` modifié.
- Aucun generated file modifié.
- Aucun build_runner lancé.
- Aucune création de storyline, sideQuest, chapter, step, scene placeholder, scene link, relationship ou availability par ce lot.
- Aucun import legacy automatique.
- Aucun zoom, mini-map, drag/drop ou édition graph.
- Aucun runtime/gameplay/battle modifié.

## 16. Design System Gate

Les couleurs du graph viennent de `context.pokeMapColors`. Le `rg` anti-couleurs ne trouve aucune occurrence `Color(0x...)` ni `Colors.*` dans les fichiers contrôlés.

## 17. Tests added or modified

`packages/map_editor/test/storylines_workspace_shell_test.dart` a été adapté :

- groupe V1-12 ;
- assertions de légende `Ordre auteur` / `Disponibilité quête annexe` ;
- assertions du node sideQuest attachée `Disponible depuis ...` ;
- test source anti-couleurs élargi aux fichiers graph ;
- Visual Gate V1-12 avec quatre captures dark.

## 18. Visual Gate

Captures générées :

- `reports/narrativeStudio/storylines/screenshots/ns_storylines_v1_12_graph_main_polished.png`
- `reports/narrativeStudio/storylines/screenshots/ns_storylines_v1_12_graph_sidequest_attached_polished.png`
- `reports/narrativeStudio/storylines/screenshots/ns_storylines_v1_12_graph_sidequest_standalone_polished.png`
- `reports/narrativeStudio/storylines/screenshots/ns_storylines_v1_12_graph_empty_polished.png`

Résultat visuel : captures inspectées, sideQuest attachée visible, légende présente, graph principal sans sideQuest non attachée, graph sideQuest autonome.

## 19. Commands run

```bash
cd packages/map_editor && dart format lib/src/ui/canvas/storylines/storylines_graph_model.dart lib/src/ui/canvas/storylines/storylines_graph_painter.dart lib/src/ui/canvas/storylines/storylines_graph_view.dart test/storylines_workspace_shell_test.dart
cd packages/map_editor && flutter test test/storylines_workspace_shell_test.dart --update-goldens
cd packages/map_editor && flutter test test/storylines_workspace_shell_test.dart
cd packages/map_editor && flutter test test/storylines_current_global_story_characterization_test.dart
cd packages/map_editor && flutter test test/narrative_workspace_projection_test.dart
cd packages/map_editor && flutter analyze --no-fatal-infos lib/src/ui/canvas/storylines_workspace.dart lib/src/ui/canvas/storylines/storylines_graph_model.dart lib/src/ui/canvas/storylines/storylines_graph_painter.dart lib/src/ui/canvas/storylines/storylines_graph_view.dart test/storylines_workspace_shell_test.dart test/storylines_current_global_story_characterization_test.dart test/narrative_workspace_projection_test.dart
rg "Color\(0x|Colors\." packages/map_editor/lib/src/ui/canvas/storylines_workspace.dart packages/map_editor/lib/src/ui/canvas/storylines packages/map_editor/test/storylines_workspace_shell_test.dart
rg "SideQuestAvailability\(|StorylineRelationship\(|StorylineSceneLink\(" packages/map_editor/lib/src/ui/canvas/storylines packages/map_editor/lib/src/ui/canvas/storylines_workspace.dart
```

Note : une tentative de lancement parallèle de commandes Flutter a produit un crash Flutter native-assets lié au startup lock. Les commandes ont été relancées séquentiellement avec succès et le crash log local généré a été supprimé.

## 20. Roadmap update

`road_map_storylines.md` marque `NS-STORYLINES-V1-12` comme DONE, confirme le lot visual-only, et recommande `NS-STORYLINES-V1-CHECKPOINT — Storylines V1 Acceptance Checkpoint` comme prochain lot.

## 21. Evidence Pack

### Git branch initiale

```text
main
```

### Git status initial exact

```text
Sortie : <vide>
```

### Git diff --stat initial

```text
Sortie : <vide>
```

### Git diff --name-only initial

```text
Sortie : <vide>
```

### Git diff --check initial

```text
Sortie : <vide>
```

### Liste des fichiers lus

```text
AGENTS.md
agent_rules.md
skills/README.md
reports/narrativeStudio/storylines/road_map_storylines.md
packages/map_core/lib/src/models/storyline_asset.dart
packages/map_core/lib/src/models/project_manifest.dart
packages/map_core/lib/map_core.dart
packages/map_editor/lib/src/ui/canvas/storylines_workspace.dart
packages/map_editor/lib/src/ui/canvas/storylines/storylines_graph_model.dart
packages/map_editor/lib/src/ui/canvas/storylines/storylines_graph_painter.dart
packages/map_editor/lib/src/ui/canvas/storylines/storylines_graph_view.dart
packages/map_editor/test/storylines_workspace_shell_test.dart
packages/map_editor/test/storylines_current_global_story_characterization_test.dart
packages/map_editor/test/narrative_workspace_projection_test.dart
packages/map_editor/lib/src/ui/design_system/design_system.dart
packages/map_editor/lib/src/ui/design_system/pokemap_tone.dart
packages/map_editor/lib/src/ui/design_system/pokemap_dashboard_primitives.dart
packages/map_editor/lib/src/ui/design_system/pokemap_button.dart
packages/map_editor/lib/src/ui/design_system/pokemap_card.dart
packages/map_editor/lib/src/ui/design_system/pokemap_panel.dart
packages/map_editor/lib/src/theme/pokemap_color_tokens.dart
packages/map_editor/lib/src/theme/theme.dart
```

### Liste des fichiers absents mais attendus

```text
reports/narrativeStudio/storylines/ns_storylines_v1_11_side_quest_attachment_graph_integration_v0.md
reports/narrativeStudio/storylines/ns_storylines_v1_10_graph_from_storyline_asset_v0.md
reports/narrativeStudio/storylines/ns_storylines_v1_09_create_side_quest_flow_v0.md
reports/narrativeStudio/storylines/ns_storylines_v1_08_structure_tab_authoring_v0.md
reports/narrativeStudio/storylines/ns_storylines_v1_00_storyline_semantics_and_usable_authoring_contract.md
```

### Diff complet de storylines_workspace.dart si modifié

```text
Sortie : <vide>
```

### Diff complet de storylines_graph_model.dart

```diff
diff --git a/packages/map_editor/lib/src/ui/canvas/storylines/storylines_graph_model.dart b/packages/map_editor/lib/src/ui/canvas/storylines/storylines_graph_model.dart
index 1485df2b..cdef7d25 100644
--- a/packages/map_editor/lib/src/ui/canvas/storylines/storylines_graph_model.dart
+++ b/packages/map_editor/lib/src/ui/canvas/storylines/storylines_graph_model.dart
@@ -226,6 +226,8 @@ final class StorylineGraphSideQuestAttachment {
     required this.sideQuestId,
     required this.relationshipId,
     required this.title,
+    required this.chapterCount,
+    required this.stepCount,
     required this.chapterId,
     required this.anchorKind,
     required this.anchorId,
@@ -237,6 +239,8 @@ final class StorylineGraphSideQuestAttachment {
   final String sideQuestId;
   final String relationshipId;
   final String title;
+  final int chapterCount;
+  final int stepCount;
   final String chapterId;
   final StorylineAnchorKind anchorKind;
   final String anchorId;
@@ -367,6 +371,8 @@ StorylineGraphSideQuestAttachment? _chapterAttachment(
     sideQuestId: sideQuest.id,
     relationshipId: relationship.id,
     title: sideQuest.title,
+    chapterCount: sideQuest.chapters.length,
+    stepCount: _storylineStepCount(sideQuest),
     chapterId: chapter.id,
     anchorKind: anchor.kind,
     anchorId: anchor.targetId,
@@ -389,6 +395,8 @@ StorylineGraphSideQuestAttachment? _stepAttachment(
     sideQuestId: sideQuest.id,
     relationshipId: relationship.id,
     title: sideQuest.title,
+    chapterCount: sideQuest.chapters.length,
+    stepCount: _storylineStepCount(sideQuest),
     chapterId: chapter.id,
     anchorKind: anchor.kind,
     anchorId: anchor.targetId,
@@ -408,6 +416,13 @@ bool _isSideQuestAttachment(
           relationship.kind == StorylineRelationshipKind.sideQuestUnlockedBy);
 }
 
+int _storylineStepCount(StorylineAsset storyline) {
+  return storyline.chapters.fold<int>(
+    0,
+    (total, chapter) => total + chapter.steps.length,
+  );
+}
+
 int _compareChaptersByAuthorOrder(
   StorylineChapter left,
   StorylineChapter right,
```

### Diff complet de storylines_graph_painter.dart

```diff
diff --git a/packages/map_editor/lib/src/ui/canvas/storylines/storylines_graph_painter.dart b/packages/map_editor/lib/src/ui/canvas/storylines/storylines_graph_painter.dart
index 33c3432e..9ee489dd 100644
--- a/packages/map_editor/lib/src/ui/canvas/storylines/storylines_graph_painter.dart
+++ b/packages/map_editor/lib/src/ui/canvas/storylines/storylines_graph_painter.dart
@@ -22,12 +22,14 @@ class StorylinesGraphPainter extends CustomPainter {
     required this.gridColor,
     required this.authorOrderColor,
     required this.containsColor,
+    required this.sideQuestAvailabilityColor,
   });
 
   final List<StorylineGraphPaintEdge> edges;
   final Color gridColor;
   final Color authorOrderColor;
   final Color containsColor;
+  final Color sideQuestAvailabilityColor;
 
   @override
   void paint(Canvas canvas, Size size) {
@@ -51,15 +53,20 @@ class StorylinesGraphPainter extends CustomPainter {
   }
 
   void _paintEdge(Canvas canvas, StorylineGraphPaintEdge edge) {
-    final color = edge.kind == StorylineGraphEdgeKind.authorOrder
-        ? authorOrderColor
-        : containsColor;
+    final color = switch (edge.kind) {
+      StorylineGraphEdgeKind.authorOrder => authorOrderColor,
+      StorylineGraphEdgeKind.sideQuestAttachment => sideQuestAvailabilityColor,
+      StorylineGraphEdgeKind.contains => containsColor,
+    };
     final paint = Paint()
       ..color = color
       ..style = PaintingStyle.stroke
       ..strokeCap = StrokeCap.round
-      ..strokeWidth =
-          edge.kind == StorylineGraphEdgeKind.authorOrder ? 2.4 : 1.4;
+      ..strokeWidth = switch (edge.kind) {
+        StorylineGraphEdgeKind.authorOrder => 2.4,
+        StorylineGraphEdgeKind.sideQuestAttachment => 1.8,
+        StorylineGraphEdgeKind.contains => 1.4,
+      };
     final controlOffset =
         math.max((edge.to.dx - edge.from.dx).abs() * 0.42, 48);
     final path = Path()
@@ -72,20 +79,39 @@ class StorylinesGraphPainter extends CustomPainter {
         edge.to.dx,
         edge.to.dy,
       );
-    canvas.drawPath(path, paint);
-    if (edge.kind == StorylineGraphEdgeKind.authorOrder) {
-      _paintArrowHead(canvas, edge, color);
+    switch (edge.kind) {
+      case StorylineGraphEdgeKind.sideQuestAttachment:
+        _paintDashedPath(canvas, path, paint);
+        _paintArrowHead(canvas, edge, color, size: 6);
+      case StorylineGraphEdgeKind.authorOrder:
+        canvas.drawPath(path, paint);
+        _paintArrowHead(canvas, edge, color);
+      case StorylineGraphEdgeKind.contains:
+        canvas.drawPath(path, paint);
+    }
+  }
+
+  void _paintDashedPath(Canvas canvas, Path path, Paint paint) {
+    const dash = 8.0;
+    const gap = 7.0;
+    for (final metric in path.computeMetrics()) {
+      var distance = 0.0;
+      while (distance < metric.length) {
+        final end = math.min(distance + dash, metric.length);
+        canvas.drawPath(metric.extractPath(distance, end), paint);
+        distance = end + gap;
+      }
     }
   }
 
   void _paintArrowHead(
     Canvas canvas,
     StorylineGraphPaintEdge edge,
-    Color color,
-  ) {
+    Color color, {
+    double size = 8,
+  }) {
     final angle =
         math.atan2(edge.to.dy - edge.from.dy, edge.to.dx - edge.from.dx);
-    const size = 8.0;
     final left = Offset(
       edge.to.dx - math.cos(angle - math.pi / 7) * size,
       edge.to.dy - math.sin(angle - math.pi / 7) * size,
@@ -112,6 +138,7 @@ class StorylinesGraphPainter extends CustomPainter {
     return edges != oldDelegate.edges ||
         gridColor != oldDelegate.gridColor ||
         authorOrderColor != oldDelegate.authorOrderColor ||
-        containsColor != oldDelegate.containsColor;
+        containsColor != oldDelegate.containsColor ||
+        sideQuestAvailabilityColor != oldDelegate.sideQuestAvailabilityColor;
   }
 }
```

### Diff complet de storylines_graph_view.dart

```diff
diff --git a/packages/map_editor/lib/src/ui/canvas/storylines/storylines_graph_view.dart b/packages/map_editor/lib/src/ui/canvas/storylines/storylines_graph_view.dart
index 9fac6542..ef55cf69 100644
--- a/packages/map_editor/lib/src/ui/canvas/storylines/storylines_graph_view.dart
+++ b/packages/map_editor/lib/src/ui/canvas/storylines/storylines_graph_view.dart
@@ -70,42 +70,11 @@ class StorylinesGraphView extends StatelessWidget {
           ],
         ),
         const SizedBox(height: 12),
-        Wrap(
-          spacing: 8,
-          runSpacing: 8,
-          children: [
-            const _StorylinesGraphBadge(
-              label: 'Lignes = ordre auteur',
-            ),
-            if (model.isSideQuest)
-              _StorylinesGraphBadge(
-                label: sideQuestAttached
-                    ? 'Quête annexe attachée'
-                    : 'Quête annexe indépendante',
-              ),
-            if (model.isSideQuest)
-              _StorylinesGraphBadge(
-                label: sideQuestAttached
-                    ? 'Relation principale explicite'
-                    : 'Non reliée au graph principal pour l’instant',
-              ),
-            if (model.hasSideQuestNote && model.sideQuestAttachments.isEmpty)
-              _StorylinesGraphBadge(
-                label:
-                    'Quêtes annexes créées : ${model.sideQuestCountOutsideSelected} — attachement explicite requis',
-              ),
-            if (model.sideQuestAttachments.isNotEmpty)
-              _StorylinesGraphBadge(
-                label:
-                    'Quêtes annexes attachées : ${model.sideQuestAttachments.length}',
-              ),
-            if (model.unattachedSideQuestCount > 0 &&
-                model.sideQuestAttachments.isNotEmpty)
-              _StorylinesGraphBadge(
-                label:
-                    '${model.unattachedSideQuestCount} quête(s) annexe(s) non attachée(s)',
-              ),
-          ],
+        const _StorylinesGraphLegend(),
+        const SizedBox(height: 10),
+        _GraphStatusBadges(
+          model: model,
+          sideQuestAttached: sideQuestAttached,
         ),
         const SizedBox(height: 12),
         Expanded(child: _StorylineGraphCanvas(model: model)),
@@ -118,12 +87,12 @@ class _StorylineGraphCanvas extends StatelessWidget {
   const _StorylineGraphCanvas({required this.model});
 
   static const double _rootWidth = 240;
-  static const double _rootHeight = 172;
-  static const double _chapterWidth = 276;
-  static const double _chapterGap = 46;
-  static const double _rootToChapterGap = 76;
-  static const double _leftPadding = 28;
-  static const double _topPadding = 24;
+  static const double _rootHeight = 196;
+  static const double _chapterWidth = 304;
+  static const double _chapterGap = 42;
+  static const double _rootToChapterGap = 68;
+  static const double _leftPadding = 30;
+  static const double _topPadding = 10;
   static const double _stepHeight = 54;
 
   final StorylineGraphViewModel model;
@@ -206,6 +175,7 @@ class _StorylineGraphCanvas extends StatelessWidget {
                             gridColor: colors.borderSubtle,
                             authorOrderColor: colors.brandPrimaryBorder,
                             containsColor: colors.controlBorder,
+                            sideQuestAvailabilityColor: colors.warning,
                           ),
                         ),
                       ),
@@ -242,7 +212,7 @@ class _StorylineGraphCanvas extends StatelessWidget {
                             ),
                             title: 'Ajoutez un chapitre dans Structure',
                             body:
-                                'Le graph se construit uniquement depuis les données auteur existantes.',
+                                'Le graph restera vide tant qu’aucun chapitre réel n’existe.',
                           ),
                         ),
                     ],
@@ -266,7 +236,7 @@ class _StorylineGraphCanvas extends StatelessWidget {
 
   double _chapterHeight(int itemCount) {
     final effectiveItems = math.max(1, itemCount);
-    return 142 + effectiveItems * (_stepHeight + 8);
+    return 150 + effectiveItems * (_stepHeight + 12);
   }
 
   List<StorylineGraphPaintEdge> _paintEdges(
@@ -297,6 +267,21 @@ class _StorylineGraphCanvas extends StatelessWidget {
         ),
       );
     }
+    for (final attachment in model.sideQuestAttachments) {
+      final chapterRect = chapterRects[attachment.chapterId];
+      if (chapterRect == null) continue;
+      final verticalOffset = math.min(
+        chapterRect.height - 34,
+        116 + attachment.order * 20,
+      );
+      edges.add(
+        StorylineGraphPaintEdge(
+          from: Offset(chapterRect.left + 22, chapterRect.top + verticalOffset),
+          to: Offset(chapterRect.right - 22, chapterRect.top + verticalOffset),
+          kind: StorylineGraphEdgeKind.sideQuestAttachment,
+        ),
+      );
+    }
     return edges;
   }
 
@@ -378,10 +363,19 @@ class _GraphRootNode extends StatelessWidget {
       key: ValueKey('storylines-graph-node-storyline-${model.storylineId}'),
       child: PokeMapCard(
         selected: true,
-        padding: const EdgeInsets.all(14),
+        padding: const EdgeInsets.all(13),
         child: Column(
           crossAxisAlignment: CrossAxisAlignment.start,
           children: [
+            Text(
+              'Storyline',
+              style: TextStyle(
+                color: colors.brandPrimary,
+                fontSize: 10.5,
+                fontWeight: FontWeight.w800,
+              ),
+            ),
+            const SizedBox(height: 5),
             Text(
               model.title,
               maxLines: 1,
@@ -430,6 +424,13 @@ class _GraphChapterNode extends StatelessWidget {
   Widget build(BuildContext context) {
     final colors = context.pokeMapColors;
     final items = <Widget>[
+      if (attachments.isNotEmpty)
+        _GraphSectionCaption(
+          key: ValueKey('storylines-graph-sidequest-caption-${chapter.id}'),
+          label: 'Quêtes annexes disponibles ici',
+        ),
+      for (final attachment in attachments)
+        _GraphSideQuestChip(attachment: attachment),
       if (chapter.steps.isEmpty)
         _GraphEmptyHint(
           key: ValueKey('storylines-graph-empty-steps-${chapter.id}'),
@@ -438,13 +439,6 @@ class _GraphChapterNode extends StatelessWidget {
         )
       else
         for (final step in chapter.steps) _GraphStepChip(step: step),
-      if (attachments.isNotEmpty)
-        _GraphSectionCaption(
-          key: ValueKey('storylines-graph-sidequest-caption-${chapter.id}'),
-          label: 'Quêtes annexes disponibles ici',
-        ),
-      for (final attachment in attachments)
-        _GraphSideQuestChip(attachment: attachment),
     ];
     return KeyedSubtree(
       key: ValueKey('storylines-graph-node-chapter-${chapter.id}'),
@@ -453,6 +447,15 @@ class _GraphChapterNode extends StatelessWidget {
         child: Column(
           crossAxisAlignment: CrossAxisAlignment.start,
           children: [
+            Text(
+              'Chapitre ${chapter.order + 1}',
+              style: TextStyle(
+                color: colors.brandPrimary,
+                fontSize: 10.5,
+                fontWeight: FontWeight.w800,
+              ),
+            ),
+            const SizedBox(height: 5),
             Text(
               chapter.title,
               maxLines: 1,
@@ -476,7 +479,7 @@ class _GraphChapterNode extends StatelessWidget {
               const SizedBox(height: 6),
               Text(
                 chapter.description!,
-                maxLines: 2,
+                maxLines: 1,
                 overflow: TextOverflow.ellipsis,
                 style: TextStyle(
                   color: colors.textMuted,
@@ -517,7 +520,7 @@ class _GraphStepChip extends StatelessWidget {
         border: Border.all(color: colors.borderSubtle),
       ),
       child: Padding(
-        padding: const EdgeInsets.all(10),
+        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
         child: Column(
           crossAxisAlignment: CrossAxisAlignment.start,
           children: [
@@ -531,7 +534,7 @@ class _GraphStepChip extends StatelessWidget {
                 fontWeight: FontWeight.w800,
               ),
             ),
-            const SizedBox(height: 4),
+            const SizedBox(height: 3),
             Text(
               _sceneLinkLabel(step.sceneLinkIds.length),
               style: TextStyle(
@@ -540,6 +543,19 @@ class _GraphStepChip extends StatelessWidget {
                 fontWeight: FontWeight.w700,
               ),
             ),
+            if (step.description != null) ...[
+              const SizedBox(height: 3),
+              Text(
+                step.description!,
+                maxLines: 1,
+                overflow: TextOverflow.ellipsis,
+                style: TextStyle(
+                  color: colors.textMuted,
+                  fontSize: 10.5,
+                  height: 1.2,
+                ),
+              ),
+            ],
           ],
         ),
       ),
@@ -559,47 +575,35 @@ class _GraphSideQuestChip extends StatelessWidget {
       key:
           ValueKey('storylines-graph-node-sidequest-${attachment.sideQuestId}'),
       decoration: BoxDecoration(
-        color: colors.controlSurface,
+        color: colors.warningSoft,
         borderRadius: BorderRadius.circular(8),
-        border: Border.all(color: colors.brandPrimaryBorder),
+        border: Border.all(color: colors.warningBorder),
       ),
       child: Padding(
-        padding: const EdgeInsets.all(10),
-        child: Row(
+        padding: const EdgeInsets.all(8),
+        child: Column(
           crossAxisAlignment: CrossAxisAlignment.start,
           children: [
-            const PokeMapIconTile(
-              icon: CupertinoIcons.link,
-              tone: PokeMapTone.narrative,
-              size: 26,
+            Text(
+              attachment.title,
+              maxLines: 1,
+              overflow: TextOverflow.ellipsis,
+              style: TextStyle(
+                color: colors.textPrimary,
+                fontSize: 12,
+                fontWeight: FontWeight.w800,
+              ),
             ),
-            const SizedBox(width: 8),
-            Expanded(
-              child: Column(
-                crossAxisAlignment: CrossAxisAlignment.start,
-                children: [
-                  Text(
-                    attachment.title,
-                    maxLines: 1,
-                    overflow: TextOverflow.ellipsis,
-                    style: TextStyle(
-                      color: colors.textPrimary,
-                      fontSize: 12,
-                      fontWeight: FontWeight.w800,
-                    ),
-                  ),
-                  const SizedBox(height: 4),
-                  Text(
-                    'Relation explicite · ${attachment.anchorLabel}',
-                    maxLines: 2,
-                    overflow: TextOverflow.ellipsis,
-                    style: TextStyle(
-                      color: colors.textSecondary,
-                      fontSize: 10.5,
-                      height: 1.25,
-                    ),
-                  ),
-                ],
+            const SizedBox(height: 4),
+            Text(
+              'Quête annexe · ${_formatCount(attachment.chapterCount, 'chapitre', 'chapitres')} · ${_formatCount(attachment.stepCount, 'étape', 'étapes')}\nDisponible depuis ${attachment.anchorLabel}',
+              maxLines: 2,
+              overflow: TextOverflow.ellipsis,
+              style: TextStyle(
+                color: colors.textSecondary,
+                fontSize: 10.5,
+                height: 1.18,
+                fontWeight: FontWeight.w700,
               ),
             ),
           ],
@@ -689,6 +693,195 @@ class _EdgeMarker {
   final Offset position;
 }
 
+class _StorylinesGraphLegend extends StatelessWidget {
+  const _StorylinesGraphLegend();
+
+  @override
+  Widget build(BuildContext context) {
+    final colors = context.pokeMapColors;
+    return DecoratedBox(
+      key: const ValueKey('storylines-graph-legend'),
+      decoration: BoxDecoration(
+        color: colors.controlSurface,
+        borderRadius: BorderRadius.circular(10),
+        border: Border.all(color: colors.borderSubtle),
+      ),
+      child: Padding(
+        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
+        child: Wrap(
+          spacing: 14,
+          runSpacing: 8,
+          crossAxisAlignment: WrapCrossAlignment.center,
+          children: [
+            _GraphLegendSwatch(
+              label: 'Storyline',
+              color: colors.brandPrimaryBorder,
+            ),
+            _GraphLegendSwatch(
+              label: 'Chapitre',
+              color: colors.controlBorder,
+            ),
+            _GraphLegendSwatch(
+              label: 'Étape narrative',
+              color: colors.borderSubtle,
+            ),
+            _GraphLegendSwatch(
+              label: 'Quête annexe',
+              color: colors.warningBorder,
+            ),
+            _GraphLegendLine(
+              key: const ValueKey('storylines-graph-legend-author-order'),
+              label: 'Ordre auteur',
+              color: colors.brandPrimaryBorder,
+            ),
+            _GraphLegendLine(
+              key: const ValueKey(
+                'storylines-graph-legend-sidequest-availability',
+              ),
+              label: 'Disponibilité quête annexe',
+              color: colors.warning,
+              dashed: true,
+            ),
+          ],
+        ),
+      ),
+    );
+  }
+}
+
+class _GraphLegendSwatch extends StatelessWidget {
+  const _GraphLegendSwatch({
+    required this.label,
+    required this.color,
+  });
+
+  final String label;
+  final Color color;
+
+  @override
+  Widget build(BuildContext context) {
+    final colors = context.pokeMapColors;
+    return Row(
+      mainAxisSize: MainAxisSize.min,
+      children: [
+        DecoratedBox(
+          decoration: BoxDecoration(
+            color: color.withValues(alpha: 0.18),
+            borderRadius: BorderRadius.circular(4),
+            border: Border.all(color: color),
+          ),
+          child: const SizedBox(width: 14, height: 10),
+        ),
+        const SizedBox(width: 6),
+        Text(
+          label,
+          style: TextStyle(
+            color: colors.textSecondary,
+            fontSize: 10.5,
+            fontWeight: FontWeight.w800,
+          ),
+        ),
+      ],
+    );
+  }
+}
+
+class _GraphLegendLine extends StatelessWidget {
+  const _GraphLegendLine({
+    super.key,
+    required this.label,
+    required this.color,
+    this.dashed = false,
+  });
+
+  final String label;
+  final Color color;
+  final bool dashed;
+
+  @override
+  Widget build(BuildContext context) {
+    final colors = context.pokeMapColors;
+    final segments = dashed ? 3 : 1;
+    return Row(
+      mainAxisSize: MainAxisSize.min,
+      children: [
+        Row(
+          mainAxisSize: MainAxisSize.min,
+          children: [
+            for (var index = 0; index < segments; index += 1) ...[
+              DecoratedBox(
+                decoration: BoxDecoration(
+                  color: color,
+                  borderRadius: BorderRadius.circular(999),
+                ),
+                child: SizedBox(width: dashed ? 8 : 26, height: 2),
+              ),
+              if (dashed && index < segments - 1) const SizedBox(width: 3),
+            ],
+          ],
+        ),
+        const SizedBox(width: 6),
+        Text(
+          label,
+          style: TextStyle(
+            color: colors.textSecondary,
+            fontSize: 10.5,
+            fontWeight: FontWeight.w800,
+          ),
+        ),
+      ],
+    );
+  }
+}
+
+class _GraphStatusBadges extends StatelessWidget {
+  const _GraphStatusBadges({
+    required this.model,
+    required this.sideQuestAttached,
+  });
+
+  final StorylineGraphViewModel model;
+  final bool sideQuestAttached;
+
+  @override
+  Widget build(BuildContext context) {
+    return Wrap(
+      spacing: 8,
+      runSpacing: 8,
+      children: [
+        if (model.isSideQuest)
+          _StorylinesGraphBadge(
+            label: sideQuestAttached
+                ? 'Quête annexe attachée'
+                : 'Quête annexe indépendante',
+          ),
+        if (model.isSideQuest)
+          _StorylinesGraphBadge(
+            label: sideQuestAttached
+                ? 'Relation principale explicite'
+                : 'Non reliée au graph principal pour l’instant',
+          ),
+        if (model.hasSideQuestNote && model.sideQuestAttachments.isEmpty)
+          _StorylinesGraphBadge(
+            label:
+                'Quêtes annexes créées : ${model.sideQuestCountOutsideSelected} — attachement explicite requis',
+          ),
+        if (model.sideQuestAttachments.isNotEmpty)
+          _StorylinesGraphBadge(
+            label:
+                'Quêtes annexes attachées : ${model.sideQuestAttachments.length}',
+          ),
+        if (model.unattachedSideQuestCount > 0 &&
+            model.sideQuestAttachments.isNotEmpty)
+          _StorylinesGraphBadge(
+            label:
+                '${model.unattachedSideQuestCount} quête(s) annexe(s) non attachée(s)',
+          ),
+      ],
+    );
+  }
+}
+
 class _StorylinesGraphBadge extends StatelessWidget {
   const _StorylinesGraphBadge({required this.label});
```

### Contenu complet des nouveaux fichiers créés

```text
Sortie : <vide>
```

### Diff complet des tests modifiés ou créés

```diff
diff --git a/packages/map_editor/test/storylines_workspace_shell_test.dart b/packages/map_editor/test/storylines_workspace_shell_test.dart
index 102ac857..bc905188 100644
--- a/packages/map_editor/test/storylines_workspace_shell_test.dart
+++ b/packages/map_editor/test/storylines_workspace_shell_test.dart
@@ -12,7 +12,7 @@ import 'package:map_editor/src/ui/canvas/narrative_workspace_canvas.dart';
 import 'package:map_editor/src/ui/design_system/design_system.dart';
 
 void main() {
-  group('NS-STORYLINES-V1-11 sideQuest attachment graph flow', () {
+  group('NS-STORYLINES-V1-12 visual graph enrichment', () {
@@ -143,8 +143,13 @@ void main() {
 
       await _openCreateDialog(tester);
 
+      final dialog =
+          find.byKey(const ValueKey('storylines-create-main-dialog'));
       expect(find.text('Une histoire principale existe déjà.'), findsWidgets);
-      expect(find.text('Quête annexe'), findsOneWidget);
+      expect(
+        find.descendant(of: dialog, matching: find.text('Quête annexe')),
+        findsOneWidget,
+      );
@@ -590,7 +595,11 @@ void main() {
         find.byKey(const ValueKey('storylines-graph-edge-root-chapter_intro')),
         findsOneWidget,
       );
-      expect(find.text('Lignes = ordre auteur'), findsOneWidget);
+      expect(
+        find.byKey(const ValueKey('storylines-graph-legend-author-order')),
+        findsOneWidget,
+      );
+      expect(find.text('Ordre auteur'), findsOneWidget);
@@ -879,7 +888,18 @@ void main() {
         findsOneWidget,
       );
       expect(find.text('Quêtes annexes attachées : 1'), findsOneWidget);
-      expect(find.textContaining('Relation explicite · Étape · Signal'),
+      expect(
+        find.byKey(
+          const ValueKey(
+            'storylines-graph-legend-sidequest-availability',
+          ),
+        ),
+        findsOneWidget,
+      );
+      expect(find.text('Disponibilité quête annexe'), findsOneWidget);
+      expect(find.textContaining('Disponible depuis Étape · Signal'),
+          findsOneWidget);
+      expect(find.textContaining('Quête annexe · 0 chapitres · 0 étapes'),
           findsOneWidget);
@@ -1152,14 +1172,23 @@ void main() {
     });
 
     test('storylines UI source keeps raw colors out of the feature', () {
-      final source = File('lib/src/ui/canvas/storylines_workspace.dart');
-      expect(source.existsSync(), isTrue);
-
-      final contents = source.readAsStringSync();
+      final sources = [
+        File('lib/src/ui/canvas/storylines_workspace.dart'),
+        File('lib/src/ui/canvas/storylines/storylines_graph_model.dart'),
+        File('lib/src/ui/canvas/storylines/storylines_graph_painter.dart'),
+        File('lib/src/ui/canvas/storylines/storylines_graph_view.dart'),
+      ];
       const rawColorPattern = 'Color' '(0x';
       const materialColorsPattern = 'Colors' '.';
-      expect(contents, isNot(contains(rawColorPattern)));
-      expect(contents, isNot(contains(materialColorsPattern)));
+
+      for (final source in sources) {
+        expect(source.existsSync(), isTrue, reason: source.path);
+
+        final contents = source.readAsStringSync();
+        expect(contents, isNot(contains(rawColorPattern)), reason: source.path);
+        expect(contents, isNot(contains(materialColorsPattern)),
+            reason: source.path);
+      }
@@ -1183,13 +1212,39 @@ void main() {
       expect(Theme.of(shellContext).brightness, Brightness.dark);
     });
 
-    testWidgets('writes V1-11 sideQuest attachment graph screenshots',
-        (tester) async {
+    testWidgets('writes V1-12 polished graph screenshots', (tester) async {
+      await _pumpStorylinesShell(
+        tester,
+        surfaceSize: const Size(1600, 1000),
+        project: _projectWithStorylines([
+          StorylineAsset(
+            id: 'storyline_empty_visual',
+            type: StorylineType.main,
+            title: 'Empty Visual Main',
+          ),
+        ]),
+      );
+      await expectLater(
+        find.byKey(const ValueKey('storylines-workspace-shell')),
+        matchesGoldenFile(
+          '../../../reports/narrativeStudio/storylines/screenshots/'
+          'ns_storylines_v1_12_graph_empty_polished.png',
+        ),
+      );
+
       await _pumpStorylinesShell(
         tester,
         surfaceSize: const Size(1600, 1000),
         project: _visualGraphProject(),
       );
+      await expectLater(
+        find.byKey(const ValueKey('storylines-workspace-shell')),
+        matchesGoldenFile(
+          '../../../reports/narrativeStudio/storylines/screenshots/'
+          'ns_storylines_v1_12_graph_main_polished.png',
+        ),
+      );
@@ -1199,14 +1254,6 @@ void main() {
         find.byKey(const ValueKey('storylines-attach-sidequest-action')),
       );
       await tester.pumpAndSettle();
-      await expectLater(
-        find.byKey(const ValueKey('storylines-workspace-shell')),
-        matchesGoldenFile(
-          '../../../reports/narrativeStudio/storylines/screenshots/'
-          'ns_storylines_v1_11_attach_side_quest_dialog.png',
-        ),
-      );
-
@@ -1226,7 +1273,7 @@ void main() {
         find.byKey(const ValueKey('storylines-workspace-shell')),
         matchesGoldenFile(
           '../../../reports/narrativeStudio/storylines/screenshots/'
-          'ns_storylines_v1_11_attached_main_graph.png',
+          'ns_storylines_v1_12_graph_sidequest_attached_polished.png',
         ),
       );
@@ -1234,25 +1281,12 @@ void main() {
         find.byKey(const ValueKey('storylines-v1-row-sidequest_visual')),
       );
       await tester.pump();
-      await _openStructureTab(tester);
-      await expectLater(
-        find.byKey(const ValueKey('storylines-workspace-shell')),
-        matchesGoldenFile(
-          '../../../reports/narrativeStudio/storylines/screenshots/'
-          'ns_storylines_v1_11_attached_sidequest_structure.png',
-        ),
-      );
-
-      await _pumpStorylinesShell(
-        tester,
-        surfaceSize: const Size(1600, 1000),
-        project: _visualGraphProject(),
-      );
+      await _openGraphTab(tester);
       await expectLater(
         find.byKey(const ValueKey('storylines-workspace-shell')),
         matchesGoldenFile(
           '../../../reports/narrativeStudio/storylines/screenshots/'
-          'ns_storylines_v1_11_unattached_sidequest_hidden_from_main_graph.png',
+          'ns_storylines_v1_12_graph_sidequest_standalone_polished.png',
         ),
       );
```

### Diff complet de road_map_storylines.md

```diff
diff --git a/reports/narrativeStudio/storylines/road_map_storylines.md b/reports/narrativeStudio/storylines/road_map_storylines.md
index 015cc142..3cca63a6 100644
--- a/reports/narrativeStudio/storylines/road_map_storylines.md
+++ b/reports/narrativeStudio/storylines/road_map_storylines.md
@@ -314,7 +314,7 @@ Interprétation V0 :
 | NS-STORYLINES-V1-09 | Create Side Quest Flow V0 | editor authoring | DONE | NS-STORYLINES-V1-10 |
 | NS-STORYLINES-V1-10 | Graph From StorylineAsset V0 | editor graph | DONE | NS-STORYLINES-V1-11 |
 | NS-STORYLINES-V1-11 | Side Quest Attachment + Graph Integration V0 | editor graph | DONE | NS-STORYLINES-V1-12 |
-| NS-STORYLINES-V1-12 | V1 Visual Graph Enrichment | visual gate | TODO | NS-STORYLINES-V1-CHECKPOINT |
+| NS-STORYLINES-V1-12 | V1 Visual Graph Enrichment | visual gate | DONE | NS-STORYLINES-V1-CHECKPOINT |
 | NS-STORYLINES-V1-CHECKPOINT | Storylines V1 Acceptance Checkpoint | checkpoint | TODO | TBD |
@@ -896,10 +896,10 @@ Décision temporaire :
 ## 13. Current status
 
 ```text
-Roadmap status: V0 ACCEPTED WITH V1 LIMITATIONS / V1 SIDE QUEST ATTACHMENT DONE
-Current lot: NS-STORYLINES-V1-11
+Roadmap status: V0 ACCEPTED WITH V1 LIMITATIONS / V1 VISUAL GRAPH ENRICHMENT DONE
+Current lot: NS-STORYLINES-V1-12
 Current lot status: DONE
-Next recommended lot: NS-STORYLINES-V1-12 — V1 Visual Graph Enrichment
+Next recommended lot: NS-STORYLINES-V1-CHECKPOINT — Storylines V1 Acceptance Checkpoint
 ```
@@ -966,6 +966,17 @@ Suite V1 documentaire recommandée :
 
 ## 15. Changelog
 
+### 2026-05-29 — NS-STORYLINES-V1-12
+
+- V1 Visual Graph Enrichment livré côté editor : le graph read-only est plus lisible sans ajouter de comportement produit.
+- Améliorations visuelles : légende compacte, hiérarchie des nodes storyline/chapter/step/sideQuest, canvas plus dense, sideQuest attachée plus distincte.
+- Edges clarifiés : ordre auteur en ligne principale, disponibilité de quête annexe en ligne secondaire pointillée via tokens du design system.
+- Visual-only confirmé : aucune donnée métier créée, aucune mutation de `ProjectManifest`, aucune création de relationship/availability/sceneLink/scene placeholder dans ce lot.
+- `Structure` reste la source d'authoring ; le graph reste read-only ; aucun import legacy automatique ; `localEventFlow` reste exclu.
+- Fichiers créés/modifiés : `storylines_graph_model.dart`, `storylines_graph_painter.dart`, `storylines_graph_view.dart`, `storylines_workspace_shell_test.dart`, captures V1-12, rapport V1-12.
+- Tests exécutés : `flutter test test/storylines_workspace_shell_test.dart`, `flutter test test/storylines_current_global_story_characterization_test.dart`, `flutter test test/narrative_workspace_projection_test.dart`, analyse ciblée, `rg` anti-couleurs, `rg` contrôle features interdites.
+- Prochain lot recommandé : `NS-STORYLINES-V1-CHECKPOINT — Storylines V1 Acceptance Checkpoint`.
+
 ### 2026-05-29 — NS-STORYLINES-V1-11
```

### Sorties exactes des tests ciblés

`cd packages/map_editor && flutter test test/storylines_workspace_shell_test.dart`

```text
00:00 +0: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/storylines_workspace_shell_test.dart
00:00 +0: NS-STORYLINES-V1-12 visual graph enrichment shows only Graph and Structure tabs
00:00 +1: NS-STORYLINES-V1-12 visual graph enrichment shows V1 empty state without importing legacy globalStory
00:00 +2: NS-STORYLINES-V1-12 visual graph enrichment opens and cancels create main storyline dialog without mutation
00:00 +3: NS-STORYLINES-V1-12 visual graph enrichment requires title before create
00:00 +4: NS-STORYLINES-V1-12 visual graph enrichment does not create sideQuest before a main storyline exists
00:01 +5: NS-STORYLINES-V1-12 visual graph enrichment dialog selects sideQuest when a main storyline exists
00:01 +6: NS-STORYLINES-V1-12 visual graph enrichment creates a main StorylineAsset and syncs Graph and Structure
00:01 +7: NS-STORYLINES-V1-12 visual graph enrichment creates a sideQuest StorylineAsset and selects it
00:01 +8: NS-STORYLINES-V1-12 visual graph enrichment Structure without storyline has no chapter or step action
00:01 +9: NS-STORYLINES-V1-12 visual graph enrichment opens and cancels create chapter without mutation
00:01 +10: NS-STORYLINES-V1-12 visual graph enrichment requires chapter title before create
00:01 +11: NS-STORYLINES-V1-12 visual graph enrichment creates chapters with stable ids, order and selection
00:01 +12: NS-STORYLINES-V1-12 visual graph enrichment step action requires a selected chapter
00:01 +13: NS-STORYLINES-V1-12 visual graph enrichment opens and cancels create step without mutation
00:01 +14: NS-STORYLINES-V1-12 visual graph enrichment requires step title before create
00:02 +15: NS-STORYLINES-V1-12 visual graph enrichment creates steps with global unique ids and order
00:02 +16: NS-STORYLINES-V1-12 visual graph enrichment Structure authoring works on sideQuest without mutating main
00:02 +17: NS-STORYLINES-V1-12 visual graph enrichment Graph summarizes created structure without fake edges
00:02 +18: NS-STORYLINES-V1-12 visual graph enrichment Graph orders chapters and steps by author order
00:02 +19: NS-STORYLINES-V1-12 visual graph enrichment Graph explains sideQuest is not linked to main graph yet
00:03 +20: NS-STORYLINES-V1-12 visual graph enrichment main graph does not show sideQuest as a branch yet
00:03 +21: NS-STORYLINES-V1-12 visual graph enrichment attaches sideQuest to an explicit main step anchor
00:03 +22: NS-STORYLINES-V1-12 visual graph enrichment attached sideQuest appears in main graph from relation only
00:03 +23: NS-STORYLINES-V1-12 visual graph enrichment canceling sideQuest attachment does not mutate project
00:03 +24: NS-STORYLINES-V1-12 visual graph enrichment generates stable unique main ids on collision
00:03 +25: NS-STORYLINES-V1-12 visual graph enrichment generates stable unique sideQuest ids on collision
00:04 +26: NS-STORYLINES-V1-12 visual graph enrichment does not allow creating a second main storyline
00:04 +27: NS-STORYLINES-V1-12 visual graph enrichment creation does not import legacy or promote localEventFlow
00:04 +28: NS-STORYLINES-V1-12 visual graph enrichment sideQuest creation never imports legacy or localEventFlow
00:04 +29: NS-STORYLINES-V1-12 visual graph enrichment Graph, Structure and disabled future actions do not mutate
00:04 +30: NS-STORYLINES-V1-12 visual graph enrichment Structure authoring does not import legacy or localEventFlow
00:04 +31: NS-STORYLINES-V1-12 visual graph enrichment keeps target fake data and Maps out of the V1 UI
00:04 +32: NS-STORYLINES-V1-12 visual graph enrichment storylines UI source keeps raw colors out of the feature
00:04 +33: NS-STORYLINES-V1-12 visual graph enrichment storylines shell test keeps raw colors out
00:04 +34: NS-STORYLINES-V1-12 visual graph enrichment uses PokeMap dark theme in the Visual Gate harness
00:04 +35: NS-STORYLINES-V1-12 visual graph enrichment writes V1-12 polished graph screenshots
00:04 +36: All tests passed!
```

`cd packages/map_editor && flutter test test/storylines_current_global_story_characterization_test.dart`

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

`cd packages/map_editor && flutter test test/narrative_workspace_projection_test.dart`

```text
00:00 +0: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/narrative_workspace_projection_test.dart
00:00 +0: buildNarrativeWorkspaceProjection splits global story and local flows, and projects steps
00:00 +1: buildNarrativeWorkspaceProjection projects ordered steps from Step Studio v1 metadata document
00:00 +2: buildNarrativeWorkspaceProjection projects chapters from Global Story Studio metadata
00:00 +3: All tests passed!
```

### Sortie exacte de flutter analyze ciblé

```text
Analyzing 7 items...                                            
No issues found! (ran in 1.4s)
```

### Sortie exacte du rg anti-couleurs

```text
Sortie : <vide>
```

### Sortie exacte du rg de contrôle feature interdite

```text
packages/map_editor/lib/src/ui/canvas/storylines_workspace.dart:    final relationship = StorylineRelationship(
packages/map_editor/lib/src/ui/canvas/storylines_workspace.dart:      availability: SideQuestAvailability(startAnchor: anchor),
```

Ces deux occurrences correspondent au code V1-11 d'attachement existant dans `storylines_workspace.dart`. V1-12 n'ajoute aucune création de `StorylineRelationship`, `SideQuestAvailability` ou `StorylineSceneLink`.

### Résultats du Visual Gate

```text
- ns_storylines_v1_12_graph_main_polished.png : générée et inspectée.
- ns_storylines_v1_12_graph_sidequest_attached_polished.png : générée et inspectée.
- ns_storylines_v1_12_graph_sidequest_standalone_polished.png : générée et inspectée.
- ns_storylines_v1_12_graph_empty_polished.png : générée et inspectée.
```

### Git status final exact

```text
 M packages/map_editor/lib/src/ui/canvas/storylines/storylines_graph_model.dart
 M packages/map_editor/lib/src/ui/canvas/storylines/storylines_graph_painter.dart
 M packages/map_editor/lib/src/ui/canvas/storylines/storylines_graph_view.dart
 M packages/map_editor/test/storylines_workspace_shell_test.dart
 M reports/narrativeStudio/storylines/road_map_storylines.md
?? reports/narrativeStudio/storylines/ns_storylines_v1_12_visual_graph_enrichment.md
?? reports/narrativeStudio/storylines/screenshots/ns_storylines_v1_12_graph_empty_polished.png
?? reports/narrativeStudio/storylines/screenshots/ns_storylines_v1_12_graph_main_polished.png
?? reports/narrativeStudio/storylines/screenshots/ns_storylines_v1_12_graph_sidequest_attached_polished.png
?? reports/narrativeStudio/storylines/screenshots/ns_storylines_v1_12_graph_sidequest_standalone_polished.png
```

### Git diff --stat final

```text
 .../canvas/storylines/storylines_graph_model.dart  |  15 +
 .../storylines/storylines_graph_painter.dart       |  51 ++-
 .../canvas/storylines/storylines_graph_view.dart   | 373 ++++++++++++++++-----
 .../test/storylines_workspace_shell_test.dart      | 106 ++++--
 .../storylines/road_map_storylines.md              |  19 +-
 5 files changed, 422 insertions(+), 142 deletions(-)
```

### Git diff --name-only final

```text
packages/map_editor/lib/src/ui/canvas/storylines/storylines_graph_model.dart
packages/map_editor/lib/src/ui/canvas/storylines/storylines_graph_painter.dart
packages/map_editor/lib/src/ui/canvas/storylines/storylines_graph_view.dart
packages/map_editor/test/storylines_workspace_shell_test.dart
reports/narrativeStudio/storylines/road_map_storylines.md
```

### Git diff --check final

```text
Sortie : <vide>
```

### Auto-review critique

- Le lot reste visual-only : pas de nouvelle mutation, pas de nouveau modèle, pas de changement `map_core`.
- Le `rg` feature interdite signale uniquement l'attachement V1-11 préexistant dans `storylines_workspace.dart`.
- Le graph est plus lisible et les sideQuests attachées sont mieux distinguées, mais le layout reste volontairement simple et read-only avant le checkpoint.
- Le diff de `storylines_graph_view.dart` est plus grand que les autres, mais il reste contenu dans le fichier feature-specific existant.

## 22. Self-review

Accepté pour V1-12 : graph visuellement enrichi, tests ciblés et régressions verts, analyse ciblée verte, aucun hardcoded color, aucune feature métier nouvelle, roadmap mise à jour vers le checkpoint.
