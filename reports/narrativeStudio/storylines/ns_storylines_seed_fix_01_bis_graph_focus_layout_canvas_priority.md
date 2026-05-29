# NS-STORYLINES-SEED-FIX-01-bis — Graph Focus Layout / Canvas Priority

## 1. Executive summary

NS-STORYLINES-SEED-FIX-01-bis agrandit la place réelle du graph Storylines en mode Graph sans ajouter de feature métier.

Le header Storylines et la ligne KPI passent en version compacte quand Graph est actif, la toolbar interne du graph remplace l'ancien empilement titre / légende / badges, et le canvas devient l'élément dominant de la zone centrale. Les sideQuests attachées restent des nodes indépendants reliés par edges de disponibilité, hors des chapter cards.

## 2. Inputs read

Fichiers lus :

- `AGENTS.md`
- `agent_rules.md`
- `skills/README.md`
- `reports/narrativeStudio/storylines/road_map_storylines.md`
- `reports/narrativeStudio/storylines/ns_storylines_seed_fix_01_selbrume_graph_layout_sidequest_rendering_fix_v0.md`
- `reports/narrativeStudio/storylines/ns_storylines_seed_00_selbrume_storylines_demo_seed_v0.md`
- `packages/map_editor/lib/src/ui/canvas/storylines_workspace.dart`
- `packages/map_editor/lib/src/ui/canvas/storylines/storylines_graph_model.dart`
- `packages/map_editor/lib/src/ui/canvas/storylines/storylines_graph_painter.dart`
- `packages/map_editor/lib/src/ui/canvas/storylines/storylines_graph_view.dart`
- `packages/map_editor/test/storylines_workspace_shell_test.dart`
- `packages/map_editor/test/storylines_seed_graph_usability_test.dart`
- `selbrume/project.json`

Fichiers attendus absents : aucun.

## 3. Product problem addressed

Après SEED-FIX-01, le graph savait lire les attachments Selbrume et afficher les sideQuests comme nodes indépendants, mais l'écran complet restait visuellement dominé par le shell, le header et les KPI. Le canvas graph démarrait trop bas et paraissait encore secondaire.

Ce bis traite uniquement la priorité de layout :

- moins de hauteur consommée avant le canvas ;
- KPI compactés en mode Graph ;
- header interne compacté ;
- toolbar graph plus dense ;
- canvas plus grand dans le shell complet ;
- aucune mutation projet et aucun nouveau concept métier.

## 4. Graph layout changes

Dans `storylines_workspace.dart`, `_StorylinesV1MainPanel` détecte le mode Graph et réduit padding / espacements autour du header, des tabs, des KPI et du canvas.

Dans `storylines_graph_view.dart`, la section graph remplace l'ancien bloc vertical par `_StorylinesGraphToolbar`, une toolbar compacte contenant titre, badge read-only, status et légende compacte. Le canvas reste `Expanded` et reçoit davantage de hauteur utile.

Test de protection ajouté :

- `full Storylines shell prioritizes Graph canvas`
- assertion de présence du header compact, KPI compact, toolbar graph ;
- assertion que `storylines-graph-canvas` occupe au moins 62% de la hauteur du main panel dans le harness desktop.

## 5. KPI / header compaction

En mode Graph :

- `_StorylinesV1Header` affiche une version compacte en ligne avec titre, badges réels et CTA ;
- `_StorylinesV1KpiStrip` affiche une micro-row de 34 px de hauteur avec la key `storylines-kpi-strip-compact` ;
- la description longue de storyline est retirée du header Graph pour laisser la priorité au canvas ;
- Structure conserve le header et les KPI existants.

## 6. SideQuest rendering preservation

Le modèle graph et le painter ne sont pas modifiés dans ce bis.

Les garanties livrées par SEED-FIX-01 restent préservées :

- sideQuests attachées comme nodes indépendants ;
- kind `sideQuest` distinct dans le graph model ;
- edges `sideQuestAvailability` distincts ;
- aucune sideQuest réintégrée dans les chapter cards ;
- chapter cards compactes avec compteur discret de quêtes disponibles.

Les tests existants du fichier `storylines_seed_graph_usability_test.dart` continuent de couvrir ces invariants.

## 7. Focus mode decision

Aucun mode focus persistant n'a été ajouté.

Décision : le défaut Graph a été agrandi assez fortement pour répondre au problème principal sans introduire d'état local supplémentaire ni masquer l'inspector droit. La capture `graph_focus_canvas` est produite via le harness ciblé sur le canvas agrandi, comme autorisé par le lot si le mode focus n'est pas ajouté.

## 8. No-mutation / no-data-change guarantee

Le bis ne modifie pas :

- `selbrume/project.json` ;
- `packages/map_core/` ;
- `packages/map_runtime/` ;
- `packages/map_gameplay/` ;
- `packages/map_battle/` ;
- les modèles `StorylineAsset` / `ProjectManifest` ;
- les relationships / sceneLinks / chapters / steps.

Le test `Graph and Structure switching stays non-mutating` vérifie que le rendu et le changement Graph / Structure ne modifient ni `ProjectManifest.toJson()` ni le fichier seed Selbrume.

## 9. Design System Gate

Les changements UI utilisent les primitives existantes :

- `PokeMapPanel`
- `PokeMapButton`
- `PokeMapIconTile`
- `PokeMapTone`
- `context.pokeMapColors`

Recherche anti-couleurs :

```text
Command: rg "Color\(0x|Colors\." packages/map_editor/lib/src/ui/canvas/storylines_workspace.dart packages/map_editor/lib/src/ui/canvas/storylines packages/map_editor/test/storylines_workspace_shell_test.dart packages/map_editor/test/storylines_seed_graph_usability_test.dart
Sortie : <vide>
```

Recherche anti-hardcode Selbrume dans le code produit :

```text
Command: rg "La brume du phare|Les cristaux de sel|Le Goélise du port|La cabane du phare|Maël|Lysa|Mado|Yvon|Soline" packages/map_editor/lib packages/map_core/lib
Sortie : <vide>
```

## 10. Tests added or modified

Fichier modifié :

- `packages/map_editor/test/storylines_seed_graph_usability_test.dart`

Tests ajoutés / renforcés :

- hauteur directe du canvas portée à au moins 760 px dans le harness graph ;
- `full Storylines shell prioritizes Graph canvas` ;
- `Graph and Structure switching stays non-mutating` ;
- Visual Gate bis sur les trois nouvelles captures.

## 11. Visual Gate

Captures dark produites et vérifiées visuellement :

- `reports/narrativeStudio/storylines/screenshots/ns_storylines_seed_fix_01_bis_graph_full_layout.png`
- `reports/narrativeStudio/storylines/screenshots/ns_storylines_seed_fix_01_bis_graph_focus_canvas.png`
- `reports/narrativeStudio/storylines/screenshots/ns_storylines_seed_fix_01_bis_structure_regression.png`

Résultat :

- `graph_full_layout` montre le shell complet avec graph plus grand, KPI compacts, sideQuest nodes séparés et edges de disponibilité ;
- `graph_focus_canvas` montre le canvas agrandi centré sur les nodes et edges ;
- `structure_regression` montre que Structure reste lisible et fonctionnelle.

Inventaire :

```text
-rw-r--r--  1 karim  staff  39737 May 29 12:45 reports/narrativeStudio/storylines/screenshots/ns_storylines_seed_fix_01_bis_graph_focus_canvas.png
-rw-r--r--  1 karim  staff  66009 May 29 12:45 reports/narrativeStudio/storylines/screenshots/ns_storylines_seed_fix_01_bis_graph_full_layout.png
-rw-r--r--  1 karim  staff  56702 May 29 12:45 reports/narrativeStudio/storylines/screenshots/ns_storylines_seed_fix_01_bis_structure_regression.png
```

## 12. Commands run

```text
git branch --show-current
git status --short --untracked-files=all
git diff --stat
git diff --name-only
git diff --check
sed / rg / ls reads on required files
dart format packages/map_editor/lib/src/ui/canvas/storylines_workspace.dart packages/map_editor/lib/src/ui/canvas/storylines/storylines_graph_view.dart packages/map_editor/test/storylines_seed_graph_usability_test.dart
cd packages/map_editor && flutter test --reporter=compact test/storylines_seed_graph_usability_test.dart --update-goldens
cd packages/map_editor && flutter test --reporter=compact test/storylines_seed_graph_usability_test.dart
cd packages/map_editor && flutter test --reporter=compact test/storylines_current_global_story_characterization_test.dart
cd packages/map_editor && flutter test --reporter=compact test/narrative_workspace_projection_test.dart
cd packages/map_editor && flutter test --reporter=compact test/storylines_workspace_shell_test.dart
cd packages/map_editor && flutter analyze --no-fatal-infos lib/src/ui/canvas/storylines_workspace.dart lib/src/ui/canvas/storylines/storylines_graph_model.dart lib/src/ui/canvas/storylines/storylines_graph_painter.dart lib/src/ui/canvas/storylines/storylines_graph_view.dart test/storylines_workspace_shell_test.dart test/storylines_current_global_story_characterization_test.dart test/narrative_workspace_projection_test.dart test/storylines_seed_graph_usability_test.dart
rg "Color\(0x|Colors\." packages/map_editor/lib/src/ui/canvas/storylines_workspace.dart packages/map_editor/lib/src/ui/canvas/storylines packages/map_editor/test/storylines_workspace_shell_test.dart packages/map_editor/test/storylines_seed_graph_usability_test.dart
rg "La brume du phare|Les cristaux de sel|Le Goélise du port|La cabane du phare|Maël|Lysa|Mado|Yvon|Soline" packages/map_editor/lib packages/map_core/lib
```

## 13. Roadmap update

`reports/narrativeStudio/storylines/road_map_storylines.md` a été mis à jour :

- ajout de `NS-STORYLINES-SEED-FIX-01-bis — Graph Focus Layout / Canvas Priority` ;
- statut `DONE` ;
- mention du graph par défaut agrandi ;
- mention des KPI/header compactés en mode Graph ;
- mention de la préservation des sideQuest nodes indépendants ;
- confirmation qu'aucune donnée métier et aucun seed ne sont modifiés ;
- prochain lot recommandé : `NS-STORYLINES-V1.1-01 — Basic Edit / Delete Flow V0`.

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

Diff complet de `storylines_graph_view.dart` :

```diff
diff --git a/packages/map_editor/lib/src/ui/canvas/storylines/storylines_graph_view.dart b/packages/map_editor/lib/src/ui/canvas/storylines/storylines_graph_view.dart
index 0e63c5c1..4c4310ca 100644
--- a/packages/map_editor/lib/src/ui/canvas/storylines/storylines_graph_view.dart
+++ b/packages/map_editor/lib/src/ui/canvas/storylines/storylines_graph_view.dart
@@ -31,56 +31,80 @@ class StorylinesGraphView extends StatelessWidget {
       storylines: storylines,
       sideQuestCountOutsideSelected: sideQuestCountOutsideSelected,
     );
-    final colors = context.pokeMapColors;
     return Column(
       key: const ValueKey('storylines-graph-from-asset'),
       crossAxisAlignment: CrossAxisAlignment.stretch,
       children: [
-        Row(
+        _StorylinesGraphToolbar(
+          model: model,
+          sideQuestAttached: sideQuestAttached,
+        ),
+        const SizedBox(height: 6),
+        Expanded(child: _StorylineGraphCanvas(model: model)),
+      ],
+    );
+  }
+}
+
+class _StorylinesGraphToolbar extends StatelessWidget {
+  const _StorylinesGraphToolbar({
+    required this.model,
+    required this.sideQuestAttached,
+  });
+
+  final StorylineGraphViewModel model;
+  final bool sideQuestAttached;
+
+  @override
+  Widget build(BuildContext context) {
+    final colors = context.pokeMapColors;
+    return DecoratedBox(
+      key: const ValueKey('storylines-graph-toolbar'),
+      decoration: BoxDecoration(
+        color: colors.controlSurface,
+        borderRadius: BorderRadius.circular(10),
+        border: Border.all(color: colors.borderSubtle),
+      ),
+      child: Padding(
+        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
+        child: Column(
+          crossAxisAlignment: CrossAxisAlignment.stretch,
           children: [
-            const PokeMapIconTile(
-              icon: CupertinoIcons.arrow_branch,
-              tone: PokeMapTone.narrative,
-              size: 42,
-            ),
-            const SizedBox(width: 12),
-            Expanded(
-              child: Column(
-                crossAxisAlignment: CrossAxisAlignment.start,
-                children: [
-                  Text(
-                    'Graph de compréhension',
-                    style: TextStyle(
-                      color: colors.textPrimary,
-                      fontSize: 16,
-                      fontWeight: FontWeight.w800,
-                    ),
+            Row(
+              children: [
+                const PokeMapIconTile(
+                  icon: CupertinoIcons.arrow_branch,
+                  tone: PokeMapTone.narrative,
+                  size: 32,
+                ),
+                const SizedBox(width: 10),
+                Text(
+                  'Graph read-only',
+                  style: TextStyle(
+                    color: colors.textPrimary,
+                    fontSize: 13.5,
+                    fontWeight: FontWeight.w800,
                   ),
-                  const SizedBox(height: 4),
-                  Text(
-                    'Vue read-only générée depuis les StorylineAsset et leurs relations explicites.',
-                    style: TextStyle(
-                      color: colors.textSecondary,
-                      fontSize: 12,
+                ),
+                const SizedBox(width: 12),
+                const _StorylinesGraphBadge(label: 'Read-only'),
+                const Spacer(),
+                Flexible(
+                  child: Align(
+                    alignment: Alignment.centerRight,
+                    child: _GraphStatusBadges(
+                      model: model,
+                      sideQuestAttached: sideQuestAttached,
                     ),
                   ),
-                ],
-              ),
+                ),
+              ],
             ),
-            const SizedBox(width: 12),
-            const _StorylinesGraphBadge(label: 'Read-only'),
+            const SizedBox(height: 6),
+            const _StorylinesGraphLegend(compact: true),
           ],
         ),
-        const SizedBox(height: 12),
-        const _StorylinesGraphLegend(),
-        const SizedBox(height: 10),
-        _GraphStatusBadges(
-          model: model,
-          sideQuestAttached: sideQuestAttached,
-        ),
-        const SizedBox(height: 12),
-        Expanded(child: _StorylineGraphCanvas(model: model)),
-      ],
+      ),
     );
   }
 }
@@ -791,11 +815,55 @@ class _EdgeMarker {
 }
 
 class _StorylinesGraphLegend extends StatelessWidget {
-  const _StorylinesGraphLegend();
+  const _StorylinesGraphLegend({this.compact = false});
+
+  final bool compact;
 
   @override
   Widget build(BuildContext context) {
     final colors = context.pokeMapColors;
+    final legend = Wrap(
+      spacing: compact ? 10 : 14,
+      runSpacing: compact ? 6 : 8,
+      crossAxisAlignment: WrapCrossAlignment.center,
+      children: [
+        _GraphLegendSwatch(
+          label: 'Storyline',
+          color: colors.brandPrimaryBorder,
+        ),
+        _GraphLegendSwatch(
+          label: 'Chapitre',
+          color: colors.controlBorder,
+        ),
+        _GraphLegendSwatch(
+          label: 'Étape narrative',
+          color: colors.borderSubtle,
+        ),
+        _GraphLegendSwatch(
+          label: 'Quête annexe',
+          color: colors.warningBorder,
+        ),
+        _GraphLegendLine(
+          key: const ValueKey('storylines-graph-legend-author-order'),
+          label: 'Ordre auteur',
+          color: colors.brandPrimaryBorder,
+        ),
+        _GraphLegendLine(
+          key: const ValueKey(
+            'storylines-graph-legend-sidequest-availability',
+          ),
+          label: 'Disponibilité quête annexe',
+          color: colors.warning,
+          dashed: true,
+        ),
+      ],
+    );
+    if (compact) {
+      return KeyedSubtree(
+        key: const ValueKey('storylines-graph-legend'),
+        child: legend,
+      );
+    }
     return DecoratedBox(
       key: const ValueKey('storylines-graph-legend'),
       decoration: BoxDecoration(
@@ -805,42 +873,7 @@ class _StorylinesGraphLegend extends StatelessWidget {
       ),
       child: Padding(
         padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
-        child: Wrap(
-          spacing: 14,
-          runSpacing: 8,
-          crossAxisAlignment: WrapCrossAlignment.center,
-          children: [
-            _GraphLegendSwatch(
-              label: 'Storyline',
-              color: colors.brandPrimaryBorder,
-            ),
-            _GraphLegendSwatch(
-              label: 'Chapitre',
-              color: colors.controlBorder,
-            ),
-            _GraphLegendSwatch(
-              label: 'Étape narrative',
-              color: colors.borderSubtle,
-            ),
-            _GraphLegendSwatch(
-              label: 'Quête annexe',
-              color: colors.warningBorder,
-            ),
-            _GraphLegendLine(
-              key: const ValueKey('storylines-graph-legend-author-order'),
-              label: 'Ordre auteur',
-              color: colors.brandPrimaryBorder,
-            ),
-            _GraphLegendLine(
-              key: const ValueKey(
-                'storylines-graph-legend-sidequest-availability',
-              ),
-              label: 'Disponibilité quête annexe',
-              color: colors.warning,
-              dashed: true,
-            ),
-          ],
-        ),
+        child: legend,
       ),
     );
   }
```

Diff complet de `storylines_workspace.dart` :

```diff
diff --git a/packages/map_editor/lib/src/ui/canvas/storylines_workspace.dart b/packages/map_editor/lib/src/ui/canvas/storylines_workspace.dart
index b93a38d3..421ef68b 100644
--- a/packages/map_editor/lib/src/ui/canvas/storylines_workspace.dart
+++ b/packages/map_editor/lib/src/ui/canvas/storylines_workspace.dart
@@ -891,10 +891,11 @@ class _StorylinesV1MainPanel extends StatelessWidget {
 
   @override
   Widget build(BuildContext context) {
+    final graphMode = selectedTab == _StorylineContentTab.graph;
     return PokeMapPanel(
       key: const ValueKey('storylines-main-panel'),
       expandChild: true,
-      padding: const EdgeInsets.all(16),
+      padding: EdgeInsets.all(graphMode ? 10 : 16),
       child: Column(
         crossAxisAlignment: CrossAxisAlignment.stretch,
         children: [
@@ -902,18 +903,19 @@ class _StorylinesV1MainPanel extends StatelessWidget {
             selectedStoryline: selectedStoryline,
             canCreateStoryline: canCreateStoryline,
             onCreateStoryline: onCreateStoryline,
+            compact: graphMode,
           ),
-          const SizedBox(height: 12),
+          SizedBox(height: graphMode ? 8 : 12),
           _StorylineTabsRow(
             selectedTab: selectedTab,
             onTabSelected: onTabSelected,
           ),
-          const SizedBox(height: 12),
+          SizedBox(height: graphMode ? 6 : 12),
           _StorylinesV1KpiStrip(
             storylines: storylines,
-            compact: selectedTab == _StorylineContentTab.graph,
+            compact: graphMode,
           ),
-          SizedBox(height: selectedTab == _StorylineContentTab.graph ? 10 : 16),
+          SizedBox(height: graphMode ? 6 : 16),
           Expanded(
             child: selectedTab == _StorylineContentTab.structure
                 ? _StorylinesV1StructureSection(
@@ -943,15 +945,71 @@ class _StorylinesV1Header extends StatelessWidget {
     required this.selectedStoryline,
     required this.canCreateStoryline,
     required this.onCreateStoryline,
+    required this.compact,
   });
 
   final StorylineAsset? selectedStoryline;
   final bool canCreateStoryline;
   final VoidCallback? onCreateStoryline;
+  final bool compact;
 
   @override
   Widget build(BuildContext context) {
     final colors = context.pokeMapColors;
+    final title = selectedStoryline?.title ?? 'Storylines';
+    if (compact) {
+      return KeyedSubtree(
+        key: const ValueKey('storylines-header-section'),
+        child: Row(
+          key: const ValueKey('storylines-header-section-compact'),
+          children: [
+            Expanded(
+              child: Wrap(
+                spacing: 8,
+                runSpacing: 6,
+                crossAxisAlignment: WrapCrossAlignment.center,
+                children: [
+                  Text(
+                    title,
+                    maxLines: 1,
+                    overflow: TextOverflow.ellipsis,
+                    style: TextStyle(
+                      color: colors.textPrimary,
+                      fontSize: 18,
+                      fontWeight: FontWeight.w800,
+                    ),
+                  ),
+                  if (selectedStoryline != null) ...[
+                    _StorylinesV1Badge(
+                      label: _storylineTypeLabel(selectedStoryline!.type),
+                    ),
+                    const _StorylinesV1Badge(label: 'Brouillon'),
+                    if (selectedStoryline!.type == StorylineType.sideQuest)
+                      _StorylinesV1Badge(
+                        label: _sideQuestAttachmentStatus(selectedStoryline!),
+                      ),
+                  ],
+                ],
+              ),
+            ),
+            const SizedBox(width: 12),
+            PokeMapButton(
+              key: const ValueKey('storylines-create-main-cta'),
+              onPressed: canCreateStoryline ? onCreateStoryline : null,
+              variant: PokeMapButtonVariant.primary,
+              leading: const Icon(CupertinoIcons.plus, size: 16),
+              child: const Row(
+                mainAxisSize: MainAxisSize.min,
+                children: [
+                  Text('Nouvelle'),
+                  Text(' storyline'),
+                ],
+              ),
+            ),
+          ],
+        ),
+      );
+    }
     return KeyedSubtree(
       key: const ValueKey('storylines-header-section'),
       child: Row(
@@ -961,7 +1019,7 @@ class _StorylinesV1Header extends StatelessWidget {
               crossAxisAlignment: CrossAxisAlignment.start,
               children: [
                 Text(
-                  selectedStoryline?.title ?? 'Storylines',
+                  title,
                   maxLines: 1,
                   overflow: TextOverflow.ellipsis,
                   style: TextStyle(
@@ -1060,44 +1118,48 @@ class _StorylinesV1KpiStrip extends StatelessWidget {
     if (compact) {
       return KeyedSubtree(
         key: const ValueKey('storylines-kpi-strip'),
-        child: DecoratedBox(
-          decoration: BoxDecoration(
-            color: colors.controlSurface,
-            borderRadius: BorderRadius.circular(10),
-            border: Border.all(color: colors.borderSubtle),
-          ),
-          child: Padding(
-            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
-            child: Row(
-              children: [
-                Expanded(
-                  child: _StorylinesV1CompactKpi(
-                    label: 'Storylines',
-                    value: storylines.length.toString(),
+        child: SizedBox(
+          key: const ValueKey('storylines-kpi-strip-compact'),
+          height: 34,
+          child: DecoratedBox(
+            decoration: BoxDecoration(
+              color: colors.controlSurface,
+              borderRadius: BorderRadius.circular(10),
+              border: Border.all(color: colors.borderSubtle),
+            ),
+            child: Padding(
+              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
+              child: Row(
+                children: [
+                  Expanded(
+                    child: _StorylinesV1CompactKpi(
+                      label: 'Storylines',
+                      value: storylines.length.toString(),
+                    ),
                   ),
-                ),
-                const SizedBox(width: 10),
-                Expanded(
-                  child: _StorylinesV1CompactKpi(
-                    label: 'Chapters',
-                    value: chapterCount.toString(),
+                  const SizedBox(width: 10),
+                  Expanded(
+                    child: _StorylinesV1CompactKpi(
+                      label: 'Chapters',
+                      value: chapterCount.toString(),
+                    ),
                   ),
-                ),
-                const SizedBox(width: 10),
-                Expanded(
-                  child: _StorylinesV1CompactKpi(
-                    label: 'Story Steps',
-                    value: stepCount.toString(),
+                  const SizedBox(width: 10),
+                  Expanded(
+                    child: _StorylinesV1CompactKpi(
+                      label: 'Story Steps',
+                      value: stepCount.toString(),
+                    ),
                   ),
-                ),
-                const SizedBox(width: 10),
-                Expanded(
-                  child: _StorylinesV1CompactKpi(
-                    label: 'Scene Links',
-                    value: sceneLinkCount.toString(),
+                  const SizedBox(width: 10),
+                  Expanded(
+                    child: _StorylinesV1CompactKpi(
+                      label: 'Scene Links',
+                      value: sceneLinkCount.toString(),
+                    ),
                   ),
-                ),
-              ],
+                ],
+              ),
             ),
           ),
         ),
@@ -1170,11 +1232,11 @@ class _StorylinesV1CompactKpi extends StatelessWidget {
           value,
           style: TextStyle(
             color: colors.textPrimary,
-            fontSize: 16,
+            fontSize: 14,
             fontWeight: FontWeight.w800,
           ),
         ),
-        const SizedBox(width: 6),
+        const SizedBox(width: 5),
         Flexible(
           child: Text(
             label,
@@ -1182,7 +1244,7 @@ class _StorylinesV1CompactKpi extends StatelessWidget {
             overflow: TextOverflow.ellipsis,
             style: TextStyle(
               color: colors.textSecondary,
-              fontSize: 11,
+              fontSize: 10.5,
               fontWeight: FontWeight.w700,
             ),
           ),
```

Diff complet de `storylines_graph_model.dart` :

```text
Sortie : <vide>
```

Diff complet de `storylines_graph_painter.dart` :

```text
Sortie : <vide>
```

Diff complet de `storylines_seed_graph_usability_test.dart` :

```diff
diff --git a/packages/map_editor/test/storylines_seed_graph_usability_test.dart b/packages/map_editor/test/storylines_seed_graph_usability_test.dart
index 8db10e21..9af1d586 100644
--- a/packages/map_editor/test/storylines_seed_graph_usability_test.dart
+++ b/packages/map_editor/test/storylines_seed_graph_usability_test.dart
@@ -14,7 +14,7 @@ import 'package:map_editor/src/ui/canvas/storylines/storylines_graph_model.dart'
 import 'package:map_editor/src/ui/canvas/storylines/storylines_graph_view.dart';
 
 void main() {
-  group('NS-STORYLINES-SEED-FIX-01 Selbrume graph usability', () {
+  group('NS-STORYLINES-SEED-FIX Selbrume graph usability', () {
     test('reads seeded sideQuest relationships and resolves step anchors', () {
       final project = _loadSelbrumeProject();
       final main = _selbrumeMain(project);
@@ -105,7 +105,7 @@ void main() {
 
         final canvas = find.byKey(const ValueKey('storylines-graph-canvas'));
         expect(canvas, findsOneWidget);
-        expect(tester.getSize(canvas).height, greaterThanOrEqualTo(640));
+        expect(tester.getSize(canvas).height, greaterThanOrEqualTo(760));
 
         final portChapter = find.byKey(
             const ValueKey('storylines-graph-node-chapter-chapter_1_port'));
@@ -193,15 +193,68 @@ void main() {
       expect(_selbrumeAttachmentRelationships(project), hasLength(3));
     });
 
-    testWidgets('writes seed fix visual gate screenshots', (tester) async {
+    testWidgets('full Storylines shell prioritizes Graph canvas',
+        (tester) async {
       final project = _loadSelbrumeProject();
+      await _pumpStorylinesShell(tester, project: project);
 
-      await _pumpGraph(tester, project);
+      final canvas = find.byKey(const ValueKey('storylines-graph-canvas'));
+      final panel = find.byKey(const ValueKey('storylines-main-panel'));
+      expect(canvas, findsOneWidget);
+      expect(panel, findsOneWidget);
+      expect(find.byKey(const ValueKey('storylines-header-section-compact')),
+          findsOneWidget);
+      expect(find.byKey(const ValueKey('storylines-kpi-strip-compact')),
+          findsOneWidget);
+      expect(find.byKey(const ValueKey('storylines-graph-toolbar')),
+          findsOneWidget);
+      expect(
+        tester.getSize(canvas).height / tester.getSize(panel).height,
+        greaterThanOrEqualTo(0.62),
+      );
+    });
+
+    testWidgets('Graph and Structure switching stays non-mutating',
+        (tester) async {
+      final seedFile = _selbrumeProjectFile();
+      final seedBefore = seedFile.readAsStringSync();
+      final project = _loadSelbrumeProject();
+      final before = project.toJson();
+
+      await _pumpStorylinesShell(tester, project: project);
+      await tester.tap(
+        find.descendant(
+          of: find.byKey(const ValueKey('storylines-tabs')),
+          matching: find.text('Structure'),
+        ),
+      );
+      await tester.pumpAndSettle();
+      expect(find.text('Chapitres'), findsWidgets);
+      expect(find.text('Étapes narratives'), findsWidgets);
+
+      await tester.tap(
+        find.descendant(
+          of: find.byKey(const ValueKey('storylines-tabs')),
+          matching: find.text('Graph'),
+        ),
+      );
+      await tester.pumpAndSettle();
+
+      expect(project.toJson(), before);
+      expect(seedFile.readAsStringSync(), seedBefore);
+      expect(_selbrumeAttachmentRelationships(project), hasLength(3));
+      expect(_selbrumeMain(project).sceneLinks, isEmpty);
+    });
+
+    testWidgets('writes seed fix bis visual gate screenshots', (tester) async {
+      final project = _loadSelbrumeProject();
+
+      await _pumpStorylinesShell(tester, project: project);
       await expectLater(
-        find.byKey(const ValueKey('storylines-graph-from-asset')),
+        find.byKey(const ValueKey('storylines-workspace-shell')),
         matchesGoldenFile(
           '../../../reports/narrativeStudio/storylines/screenshots/'
-          'ns_storylines_seed_fix_01_selbrume_graph_main.png',
+          'ns_storylines_seed_fix_01_bis_graph_full_layout.png',
         ),
       );
 
@@ -210,7 +263,7 @@ void main() {
         find.byKey(const ValueKey('storylines-graph-canvas')),
         matchesGoldenFile(
           '../../../reports/narrativeStudio/storylines/screenshots/'
-          'ns_storylines_seed_fix_01_selbrume_graph_sidequest_nodes.png',
+          'ns_storylines_seed_fix_01_bis_graph_focus_canvas.png',
         ),
       );
 
@@ -226,7 +279,7 @@ void main() {
         find.byKey(const ValueKey('storylines-workspace-shell')),
         matchesGoldenFile(
           '../../../reports/narrativeStudio/storylines/screenshots/'
-          'ns_storylines_seed_fix_01_selbrume_structure_regression.png',
+          'ns_storylines_seed_fix_01_bis_structure_regression.png',
         ),
       );
     });
```

Diff complet de `road_map_storylines.md` :

```diff
diff --git a/reports/narrativeStudio/storylines/road_map_storylines.md b/reports/narrativeStudio/storylines/road_map_storylines.md
index 28f69df9..0b9c8ad7 100644
--- a/reports/narrativeStudio/storylines/road_map_storylines.md
+++ b/reports/narrativeStudio/storylines/road_map_storylines.md
@@ -318,6 +318,7 @@ Interprétation V0 :
 | NS-STORYLINES-V1-CHECKPOINT | Storylines V1 Acceptance Checkpoint | checkpoint | DONE | NS-SCENES-V1 |
 | NS-STORYLINES-SEED-00 | Selbrume Storylines Demo Seed V0 | demo data | DONE | NS-SCENES-V1 |
 | NS-STORYLINES-SEED-FIX-01 | Selbrume Graph Layout / SideQuest Rendering Fix V0 | editor graph fix | DONE | NS-STORYLINES-V1.1-01 |
+| NS-STORYLINES-SEED-FIX-01-bis | Graph Focus Layout / Canvas Priority | editor graph layout | DONE | NS-STORYLINES-V1.1-01 |
 
 ## 9. Detailed lots
 
@@ -899,7 +900,7 @@ Décision temporaire :
 
 ```text
 Roadmap status: V0 ACCEPTED WITH V1 LIMITATIONS / V1 ACCEPTED WITH LIMITATIONS
-Current lot: NS-STORYLINES-SEED-FIX-01
+Current lot: NS-STORYLINES-SEED-FIX-01-bis
 Current lot status: DONE
 Next recommended lot: NS-STORYLINES-V1.1-01 — Basic Edit / Delete Flow V0
 ```
@@ -937,6 +938,7 @@ Next recommended lot: NS-STORYLINES-V1.1-01 — Basic Edit / Delete Flow V0
 | NS-STORYLINES-V1-CHECKPOINT | DONE | 2026-05-29 | Verdict `ACCEPTED WITH LIMITATIONS` : Storylines V1 fermé comme atelier auteur initial. |
 | NS-STORYLINES-SEED-00 | DONE | 2026-05-29 | Selbrume Storylines Demo Seed V0 livré comme data-only : 1 main, 3 sideQuests, chapters, steps et attachements explicites. |
 | NS-STORYLINES-SEED-FIX-01 | DONE | 2026-05-29 | Correction post-seed : graph plus grand, sideQuests attachées rendues comme nodes indépendants, aucun seed/model/runtime modifié. |
+| NS-STORYLINES-SEED-FIX-01-bis | DONE | 2026-05-29 | Graph Focus Layout livré : graph par défaut agrandi, KPI/header compactés en mode Graph, sideQuest nodes indépendants préservés, aucun seed ni donnée métier modifié. |
 
 ## 14. V1 Creation Readiness Notes
 
@@ -973,6 +975,14 @@ Suite V1 documentaire recommandée :
 
 ## 15. Changelog
 
+### 2026-05-29 — NS-STORYLINES-SEED-FIX-01-bis
+
+- Correction layout post-seed : le graph par défaut démarre plus haut et occupe nettement plus de place dans la zone centrale Storylines.
+- Les KPI et le header interne sont compactés en mode Graph afin de laisser la priorité au canvas.
+- Les sideQuest nodes indépendants et les edges de disponibilité du lot précédent sont préservés ; aucune sideQuest n'est réintégrée dans les chapter cards.
+- Aucune donnée métier, aucun seed, aucun modèle core, runtime, gameplay, battle ou fichier `selbrume/project.json` modifié.
+- Captures Visual Gate dark bis produites ; le prochain lot recommandé reste `NS-STORYLINES-V1.1-01 — Basic Edit / Delete Flow V0`.
+
 ### 2026-05-29 — NS-STORYLINES-SEED-FIX-01
 
 - Correction post-seed du rendu graph Selbrume : canvas plus grand et KPI compactés en mode Graph.
```

Sorties exactes des tests :

```text
Command: cd packages/map_editor && flutter test --reporter=compact test/storylines_seed_graph_usability_test.dart
00:00 +0: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/storylines_seed_graph_usability_test.dart
00:01 +0: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/storylines_seed_graph_usability_test.dart
00:02 +0: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/storylines_seed_graph_usability_test.dart
00:02 +0: NS-STORYLINES-SEED-FIX Selbrume graph usability reads seeded sideQuest relationships and resolves step anchors
00:02 +1: NS-STORYLINES-SEED-FIX Selbrume graph usability reads seeded sideQuest relationships and resolves step anchors
00:02 +1: NS-STORYLINES-SEED-FIX Selbrume graph usability renders sideQuest nodes outside chapter cards on a larger canvas
00:02 +2: NS-STORYLINES-SEED-FIX Selbrume graph usability renders sideQuest nodes outside chapter cards on a larger canvas
00:02 +2: NS-STORYLINES-SEED-FIX Selbrume graph usability graph rendering does not mutate ProjectManifest or seed file
00:02 +3: NS-STORYLINES-SEED-FIX Selbrume graph usability graph rendering does not mutate ProjectManifest or seed file
00:02 +3: NS-STORYLINES-SEED-FIX Selbrume graph usability full Storylines shell prioritizes Graph canvas
00:02 +4: NS-STORYLINES-SEED-FIX Selbrume graph usability full Storylines shell prioritizes Graph canvas
00:02 +4: NS-STORYLINES-SEED-FIX Selbrume graph usability Graph and Structure switching stays non-mutating
00:03 +4: NS-STORYLINES-SEED-FIX Selbrume graph usability Graph and Structure switching stays non-mutating
00:03 +5: NS-STORYLINES-SEED-FIX Selbrume graph usability Graph and Structure switching stays non-mutating
00:03 +5: NS-STORYLINES-SEED-FIX Selbrume graph usability writes seed fix bis visual gate screenshots
00:03 +6: NS-STORYLINES-SEED-FIX Selbrume graph usability writes seed fix bis visual gate screenshots
00:03 +6: All tests passed!
```

```text
Command: cd packages/map_editor && flutter test --reporter=compact test/storylines_current_global_story_characterization_test.dart
00:00 +0: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/storylines_current_global_story_characterization_test.dart
00:01 +0: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/storylines_current_global_story_characterization_test.dart
00:02 +0: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/storylines_current_global_story_characterization_test.dart
00:02 +0: NS-STORYLINES-02 current Global Story characterization renders the current Storylines shell from manifest and authoring metadata
00:02 +0: NS-STORYLINES-02 current Global Story characterization renders the current Storylines shell from manifest and authoring metadata
[step_studio_trace] action=apply_document scenario=audit_global_story rows=[]
[step_studio_trace] action=apply_document_metadata scenario=audit_global_story contains_emma=false contains_empty_entity=false
00:02 +1: NS-STORYLINES-02 current Global Story characterization renders the current Storylines shell from manifest and authoring metadata
00:02 +1: NS-STORYLINES-02 current Global Story characterization keeps globalStory and localEventFlow separated in the current projection
00:02 +1: NS-STORYLINES-02 current Global Story characterization keeps globalStory and localEventFlow separated in the current projection
[step_studio_trace] action=apply_document scenario=audit_global_story rows=[]
[step_studio_trace] action=apply_document_metadata scenario=audit_global_story contains_emma=false contains_empty_entity=false
00:02 +2: NS-STORYLINES-02 current Global Story characterization keeps globalStory and localEventFlow separated in the current projection
00:02 +2: All tests passed!
```

```text
Command: cd packages/map_editor && flutter test --reporter=compact test/narrative_workspace_projection_test.dart
00:00 +0: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/narrative_workspace_projection_test.dart
00:01 +0: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/narrative_workspace_projection_test.dart
00:01 +0: buildNarrativeWorkspaceProjection splits global story and local flows, and projects steps
00:01 +1: buildNarrativeWorkspaceProjection splits global story and local flows, and projects steps
00:01 +1: buildNarrativeWorkspaceProjection projects ordered steps from Step Studio v1 metadata document
00:01 +2: buildNarrativeWorkspaceProjection projects ordered steps from Step Studio v1 metadata document
00:01 +2: buildNarrativeWorkspaceProjection projects chapters from Global Story Studio metadata
00:01 +3: buildNarrativeWorkspaceProjection projects chapters from Global Story Studio metadata
00:01 +3: All tests passed!
```

```text
Command: cd packages/map_editor && flutter test --reporter=compact test/storylines_workspace_shell_test.dart
00:00 +0: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/storylines_workspace_shell_test.dart
00:01 +0: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/storylines_workspace_shell_test.dart
00:01 +0: NS-STORYLINES-V1-12 visual graph enrichment shows only Graph and Structure tabs
00:02 +0: NS-STORYLINES-V1-12 visual graph enrichment shows only Graph and Structure tabs
00:02 +1: NS-STORYLINES-V1-12 visual graph enrichment shows only Graph and Structure tabs
00:02 +1: NS-STORYLINES-V1-12 visual graph enrichment shows V1 empty state without importing legacy globalStory
00:02 +2: NS-STORYLINES-V1-12 visual graph enrichment shows V1 empty state without importing legacy globalStory
00:02 +2: NS-STORYLINES-V1-12 visual graph enrichment opens and cancels create main storyline dialog without mutation
00:02 +3: NS-STORYLINES-V1-12 visual graph enrichment opens and cancels create main storyline dialog without mutation
00:02 +3: NS-STORYLINES-V1-12 visual graph enrichment requires title before create
00:02 +4: NS-STORYLINES-V1-12 visual graph enrichment requires title before create
00:02 +4: NS-STORYLINES-V1-12 visual graph enrichment does not create sideQuest before a main storyline exists
00:03 +4: NS-STORYLINES-V1-12 visual graph enrichment does not create sideQuest before a main storyline exists
00:03 +5: NS-STORYLINES-V1-12 visual graph enrichment does not create sideQuest before a main storyline exists
00:03 +5: NS-STORYLINES-V1-12 visual graph enrichment dialog selects sideQuest when a main storyline exists
00:03 +6: NS-STORYLINES-V1-12 visual graph enrichment dialog selects sideQuest when a main storyline exists
00:03 +6: NS-STORYLINES-V1-12 visual graph enrichment creates a main StorylineAsset and syncs Graph and Structure
00:03 +7: NS-STORYLINES-V1-12 visual graph enrichment creates a main StorylineAsset and syncs Graph and Structure
00:03 +7: NS-STORYLINES-V1-12 visual graph enrichment creates a sideQuest StorylineAsset and selects it
00:03 +8: NS-STORYLINES-V1-12 visual graph enrichment creates a sideQuest StorylineAsset and selects it
00:03 +8: NS-STORYLINES-V1-12 visual graph enrichment Structure without storyline has no chapter or step action
00:03 +9: NS-STORYLINES-V1-12 visual graph enrichment Structure without storyline has no chapter or step action
00:03 +9: NS-STORYLINES-V1-12 visual graph enrichment opens and cancels create chapter without mutation
00:03 +10: NS-STORYLINES-V1-12 visual graph enrichment opens and cancels create chapter without mutation
00:03 +10: NS-STORYLINES-V1-12 visual graph enrichment requires chapter title before create
00:03 +11: NS-STORYLINES-V1-12 visual graph enrichment requires chapter title before create
00:03 +11: NS-STORYLINES-V1-12 visual graph enrichment creates chapters with stable ids, order and selection
00:04 +11: NS-STORYLINES-V1-12 visual graph enrichment creates chapters with stable ids, order and selection
00:04 +12: NS-STORYLINES-V1-12 visual graph enrichment creates chapters with stable ids, order and selection
00:04 +12: NS-STORYLINES-V1-12 visual graph enrichment step action requires a selected chapter
00:04 +13: NS-STORYLINES-V1-12 visual graph enrichment step action requires a selected chapter
00:04 +13: NS-STORYLINES-V1-12 visual graph enrichment opens and cancels create step without mutation
00:04 +14: NS-STORYLINES-V1-12 visual graph enrichment opens and cancels create step without mutation
00:04 +14: NS-STORYLINES-V1-12 visual graph enrichment requires step title before create
00:04 +15: NS-STORYLINES-V1-12 visual graph enrichment requires step title before create
00:04 +15: NS-STORYLINES-V1-12 visual graph enrichment creates steps with global unique ids and order
00:04 +16: NS-STORYLINES-V1-12 visual graph enrichment creates steps with global unique ids and order
00:04 +16: NS-STORYLINES-V1-12 visual graph enrichment Structure authoring works on sideQuest without mutating main
00:04 +17: NS-STORYLINES-V1-12 visual graph enrichment Structure authoring works on sideQuest without mutating main
00:04 +17: NS-STORYLINES-V1-12 visual graph enrichment Graph summarizes created structure without fake edges
00:05 +17: NS-STORYLINES-V1-12 visual graph enrichment Graph summarizes created structure without fake edges
00:05 +18: NS-STORYLINES-V1-12 visual graph enrichment Graph summarizes created structure without fake edges
00:05 +18: NS-STORYLINES-V1-12 visual graph enrichment Graph orders chapters and steps by author order
00:05 +19: NS-STORYLINES-V1-12 visual graph enrichment Graph orders chapters and steps by author order
00:05 +19: NS-STORYLINES-V1-12 visual graph enrichment Graph explains sideQuest is not linked to main graph yet
00:05 +20: NS-STORYLINES-V1-12 visual graph enrichment Graph explains sideQuest is not linked to main graph yet
00:05 +20: NS-STORYLINES-V1-12 visual graph enrichment main graph does not show sideQuest as a branch yet
00:05 +21: NS-STORYLINES-V1-12 visual graph enrichment main graph does not show sideQuest as a branch yet
00:05 +21: NS-STORYLINES-V1-12 visual graph enrichment attaches sideQuest to an explicit main step anchor
00:05 +22: NS-STORYLINES-V1-12 visual graph enrichment attaches sideQuest to an explicit main step anchor
00:05 +22: NS-STORYLINES-V1-12 visual graph enrichment attached sideQuest appears in main graph from relation only
00:06 +22: NS-STORYLINES-V1-12 visual graph enrichment attached sideQuest appears in main graph from relation only
00:06 +23: NS-STORYLINES-V1-12 visual graph enrichment attached sideQuest appears in main graph from relation only
00:06 +23: NS-STORYLINES-V1-12 visual graph enrichment canceling sideQuest attachment does not mutate project
00:06 +24: NS-STORYLINES-V1-12 visual graph enrichment canceling sideQuest attachment does not mutate project
00:06 +24: NS-STORYLINES-V1-12 visual graph enrichment generates stable unique main ids on collision
00:06 +25: NS-STORYLINES-V1-12 visual graph enrichment generates stable unique main ids on collision
00:06 +25: NS-STORYLINES-V1-12 visual graph enrichment generates stable unique sideQuest ids on collision
00:06 +26: NS-STORYLINES-V1-12 visual graph enrichment generates stable unique sideQuest ids on collision
00:06 +26: NS-STORYLINES-V1-12 visual graph enrichment does not allow creating a second main storyline
00:06 +27: NS-STORYLINES-V1-12 visual graph enrichment does not allow creating a second main storyline
00:06 +27: NS-STORYLINES-V1-12 visual graph enrichment creation does not import legacy or promote localEventFlow
00:06 +28: NS-STORYLINES-V1-12 visual graph enrichment creation does not import legacy or promote localEventFlow
00:06 +28: NS-STORYLINES-V1-12 visual graph enrichment sideQuest creation never imports legacy or localEventFlow
00:06 +29: NS-STORYLINES-V1-12 visual graph enrichment sideQuest creation never imports legacy or localEventFlow
00:06 +29: NS-STORYLINES-V1-12 visual graph enrichment Graph, Structure and disabled future actions do not mutate
00:06 +30: NS-STORYLINES-V1-12 visual graph enrichment Graph, Structure and disabled future actions do not mutate
00:06 +30: NS-STORYLINES-V1-12 visual graph enrichment Structure authoring does not import legacy or localEventFlow
00:07 +30: NS-STORYLINES-V1-12 visual graph enrichment Structure authoring does not import legacy or localEventFlow
00:07 +31: NS-STORYLINES-V1-12 visual graph enrichment Structure authoring does not import legacy or localEventFlow
00:07 +31: NS-STORYLINES-V1-12 visual graph enrichment keeps target fake data and Maps out of the V1 UI
00:07 +32: NS-STORYLINES-V1-12 visual graph enrichment keeps target fake data and Maps out of the V1 UI
00:07 +32: NS-STORYLINES-V1-12 visual graph enrichment storylines UI source keeps raw colors out of the feature
00:07 +33: NS-STORYLINES-V1-12 visual graph enrichment storylines UI source keeps raw colors out of the feature
00:07 +33: NS-STORYLINES-V1-12 visual graph enrichment storylines shell test keeps raw colors out
00:07 +34: NS-STORYLINES-V1-12 visual graph enrichment storylines shell test keeps raw colors out
00:07 +34: NS-STORYLINES-V1-12 visual graph enrichment uses PokeMap dark theme in the Visual Gate harness
00:07 +35: NS-STORYLINES-V1-12 visual graph enrichment uses PokeMap dark theme in the Visual Gate harness
00:07 +35: NS-STORYLINES-V1-12 visual graph enrichment writes V1-12 polished graph screenshots
00:07 +35: NS-STORYLINES-V1-12 visual graph enrichment writes V1-12 polished graph screenshots
══╡ EXCEPTION CAUGHT BY FLUTTER TEST FRAMEWORK ╞════════════════════════════════════════════════════
The following TestFailure was thrown running a test:
Expected: one widget whose rasterized image matches golden image
"../../../reports/narrativeStudio/storylines/screenshots/ns_storylines_v1_12_graph_empty_polished.png"
  Actual: _KeyWidgetFinder:<Found 1 widget with key [<'storylines-workspace-shell'>]: [
            PokeMapPageSurface-[<'storylines-workspace-shell'>](dependencies:
[InheritedCupertinoTheme, _InheritedTheme, _LocalizationsScope-[GlobalKey#f2f12]]),
          ]>
   Which: Could not be compared against non-existent file:
"../../../reports/narrativeStudio/storylines/screenshots/ns_storylines_v1_12_graph_empty_polished.png"

When the exception was thrown, this was the stack:
#0      fail (package:matcher/src/expect/expect.dart:187:31)
#1      _expect.<anonymous closure> (package:matcher/src/expect/expect.dart:155:13)
<asynchronous suspension>
<asynchronous suspension>
#8      expectLater.<anonymous closure> (package:flutter_test/src/widget_tester.dart:508:19)
<asynchronous suspension>
#9      main.<anonymous closure>.<anonymous closure> (file:///Users/karim/Project/pokemonProject/packages/map_editor/test/storylines_workspace_shell_test.dart:1227:7)
<asynchronous suspension>
#10     testWidgets.<anonymous closure>.<anonymous closure> (package:flutter_test/src/widget_tester.dart:192:15)
<asynchronous suspension>
#11     TestWidgetsFlutterBinding._runTestBody (package:flutter_test/src/binding.dart:1952:5)
<asynchronous suspension>
<asynchronous suspension>
(elided 7 frames from dart:async and package:stack_trace)

The test description was:
  writes V1-12 polished graph screenshots
════════════════════════════════════════════════════════════════════════════════════════════════════
00:07 +35 -1: NS-STORYLINES-V1-12 visual graph enrichment writes V1-12 polished graph screenshots [E]
  Test failed. See exception logs above.
  The test description was: writes V1-12 polished graph screenshots

To run this test again: /opt/homebrew/share/flutter/bin/cache/dart-sdk/bin/dart test /Users/karim/Project/pokemonProject/packages/map_editor/test/storylines_workspace_shell_test.dart -p vm --plain-name 'NS-STORYLINES-V1-12 visual graph enrichment writes V1-12 polished graph screenshots'
00:07 +35 -1: Some tests failed.
```

Sortie exacte de flutter analyze ciblé :

```text
Command: cd packages/map_editor && flutter analyze --no-fatal-infos lib/src/ui/canvas/storylines_workspace.dart lib/src/ui/canvas/storylines/storylines_graph_model.dart lib/src/ui/canvas/storylines/storylines_graph_painter.dart lib/src/ui/canvas/storylines/storylines_graph_view.dart test/storylines_workspace_shell_test.dart test/storylines_current_global_story_characterization_test.dart test/narrative_workspace_projection_test.dart test/storylines_seed_graph_usability_test.dart
Analyzing 8 items...
No issues found! (ran in 2.1s)
```

Sortie exacte du rg anti-colors :

```text
Command: rg "Color\(0x|Colors\." packages/map_editor/lib/src/ui/canvas/storylines_workspace.dart packages/map_editor/lib/src/ui/canvas/storylines packages/map_editor/test/storylines_workspace_shell_test.dart packages/map_editor/test/storylines_seed_graph_usability_test.dart
Sortie : <vide>
```

Sortie exacte du rg anti-hardcode Selbrume :

```text
Command: rg "La brume du phare|Les cristaux de sel|Le Goélise du port|La cabane du phare|Maël|Lysa|Mado|Yvon|Soline" packages/map_editor/lib packages/map_core/lib
Sortie : <vide>
```

Résultats Visual Gate :

```text
Créé et vérifié :
reports/narrativeStudio/storylines/screenshots/ns_storylines_seed_fix_01_bis_graph_full_layout.png
reports/narrativeStudio/storylines/screenshots/ns_storylines_seed_fix_01_bis_graph_focus_canvas.png
reports/narrativeStudio/storylines/screenshots/ns_storylines_seed_fix_01_bis_structure_regression.png
```

Git final exact après création du rapport :

```text
git status --short --untracked-files=all
 M packages/map_editor/lib/src/ui/canvas/storylines/storylines_graph_view.dart
 M packages/map_editor/lib/src/ui/canvas/storylines_workspace.dart
 M packages/map_editor/test/storylines_seed_graph_usability_test.dart
 M reports/narrativeStudio/storylines/road_map_storylines.md
?? reports/narrativeStudio/storylines/ns_storylines_seed_fix_01_bis_graph_focus_layout_canvas_priority.md
?? reports/narrativeStudio/storylines/screenshots/ns_storylines_seed_fix_01_bis_graph_focus_canvas.png
?? reports/narrativeStudio/storylines/screenshots/ns_storylines_seed_fix_01_bis_graph_full_layout.png
?? reports/narrativeStudio/storylines/screenshots/ns_storylines_seed_fix_01_bis_structure_regression.png
```

```text
git diff --stat
 .../canvas/storylines/storylines_graph_view.dart   | 185 ++++++++++++---------
 .../lib/src/ui/canvas/storylines_workspace.dart    | 148 ++++++++++++-----
 .../test/storylines_seed_graph_usability_test.dart |  69 +++++++-
 .../storylines/road_map_storylines.md              |  12 +-
 4 files changed, 286 insertions(+), 128 deletions(-)
```

```text
git diff --name-only
packages/map_editor/lib/src/ui/canvas/storylines/storylines_graph_view.dart
packages/map_editor/lib/src/ui/canvas/storylines_workspace.dart
packages/map_editor/test/storylines_seed_graph_usability_test.dart
reports/narrativeStudio/storylines/road_map_storylines.md
```

```text
git diff --check
Sortie : <vide>
```

## 15. Self-review

- Le changement reste strictement layout / lisibilité graph.
- Aucun modèle core, seed, runtime, gameplay ou battle n'est modifié.
- Aucun hardcode Selbrume n'apparaît dans `packages/map_editor/lib` ou `packages/map_core/lib`.
- Les sideQuest nodes indépendants sont préservés.
- Structure n'est pas modifiée côté comportement.
- Le test global `storylines_workspace_shell_test.dart` échoue encore uniquement sur le golden V1-12 absent, déjà documenté par les lots précédents ; les 35 tests précédents de ce fichier passent avant cet échec.
- Limite : pas de mode focus interactif ajouté ; décision volontaire pour garder le lot sans nouvel état UI et concentré sur le layout par défaut.
