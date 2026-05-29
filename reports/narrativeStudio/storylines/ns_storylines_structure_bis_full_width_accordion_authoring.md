# NS-STORYLINES — lot bis — Structure tab full-width accordion authoring

## 1. Audit initial

Le rendu précédent de `Structure` était effectivement un split layout : `StorylinesStructureView` composait une `_SelectedChapterPanel` à gauche et une `_CollapsedChaptersPanel` à droite. Cette structure contredisait l'intention demandée : liste verticale naturelle, occupation centrale large, chapitres en accordéons et authoring direct.

Fichiers lus / audités :

- `AGENTS.md`
- `agent_rules.md`
- `skills/README.md`
- `reports/narrativeStudio/storylines/road_map_storylines.md`
- `reports/narrativeStudio/storylines/ns_storylines_seed_fix_01_bis_graph_focus_layout_canvas_priority.md`
- `packages/map_core/lib/src/models/storyline_asset.dart`
- `packages/map_editor/lib/src/ui/canvas/storylines_workspace.dart`
- `packages/map_editor/lib/src/ui/canvas/storylines/storylines_structure_view.dart`
- `packages/map_editor/test/storylines_structure_layout_test.dart`
- `packages/map_editor/test/storylines_seed_graph_usability_test.dart`
- `packages/map_editor/test/storylines_workspace_shell_test.dart`

## 2. Plan d'implémentation

1. Verrouiller la cible par tests : accordéon pleine largeur, sélection sans mutation, edit/delete chapter, edit/delete/reorder step, création existante préservée et régression Graph.
2. Remplacer le split layout par une toolbar locale + liste verticale d'accordéons.
3. Brancher les mutations dans `StorylinesWorkspace` via `ProjectManifest.copyWith` et reconstruction immuable de `StorylineAsset` / `StorylineChapter` / `StorylineStep`.
4. Garder `Lier une scène` disabled : le modèle a des `sceneLinkIds`, mais ce lot ne dispose pas d'un picker de scènes existantes fiable et ne doit pas créer de placeholder.
5. Produire les captures Visual Gate et relancer tests/analyse/gates.

## 3. Fichiers modifiés

- `packages/map_editor/lib/src/ui/canvas/storylines/storylines_structure_view.dart`
- `packages/map_editor/lib/src/ui/canvas/storylines_workspace.dart`
- `packages/map_editor/test/storylines_structure_layout_test.dart`
- `packages/map_editor/test/storylines_seed_graph_usability_test.dart`
- `packages/map_editor/test/storylines_workspace_shell_test.dart`
- `reports/narrativeStudio/storylines/road_map_storylines.md`

## 4. Fichiers créés

- `reports/narrativeStudio/storylines/ns_storylines_structure_bis_full_width_accordion_authoring.md`
- `reports/narrativeStudio/storylines/screenshots/ns_storylines_structure_bis_full_width_accordion.png`
- `reports/narrativeStudio/storylines/screenshots/ns_storylines_structure_bis_collapsed_chapter.png`
- `reports/narrativeStudio/storylines/screenshots/ns_storylines_structure_bis_expanded_chapter_steps.png`
- `reports/narrativeStudio/storylines/screenshots/ns_storylines_structure_bis_authoring_actions.png`
- `reports/narrativeStudio/storylines/screenshots/ns_storylines_structure_bis_graph_regression.png`

## 5. UI finale

La vue `Structure` affiche maintenant :

- une toolbar locale `Chapitres` avec compteurs réels, `Nouveau chapitre`, et actions disabled honnêtes `Recherche`, `Filtre`, `Tri`, `Lier une scène` ;
- une liste verticale pleine largeur d'accordéons de chapitres ;
- un chapitre ouvert qui révèle ses étapes narratives sous forme de rows compactes ;
- des actions d'authoring visibles sur chapitre et step : modifier, supprimer, créer, réordonner les steps via drag handle ;
- les autres chapitres restent des accordéons collapsed dans la même pile, sans mini-colonne latérale.

## 6. Choix de scope

Implémenté :

- création chapitre/step existante préservée ;
- édition chapter ;
- suppression chapter ;
- édition step ;
- suppression step ;
- reorder DnD des steps dans un chapitre ;
- toolbar locale ;
- Visual Gate dark.

Limité volontairement :

- pas de reorder DnD des chapitres dans ce bis ;
- pas de liaison de scène réelle, faute de picker/scène cible fiable dans ce scope ;
- recherche/filtre/tri affichés disabled pour ne pas simuler des fonctionnalités non branchées ;
- pas de modification de seed Selbrume ni `map_core`.

## 7. Validations effectuées

### TDD red phase

```text
Command: cd packages/map_editor && flutter test --reporter=compact test/storylines_structure_layout_test.dart
Résultat: échec attendu avant implémentation.
Signal: toolbar accordion absente, toggle chapitre absent, actions edit/delete/drag absentes.
```

### Tests verts

```text
Command: cd packages/map_editor && flutter test --reporter=compact test/storylines_structure_layout_test.dart --update-goldens
Résultat: 00:05 +7: All tests passed!
```

```text
Command: cd packages/map_editor && flutter test --reporter=compact test/storylines_structure_layout_test.dart
Résultat: 00:05 +7: All tests passed!
```

```text
Command: cd packages/map_editor && flutter test --reporter=compact test/storylines_seed_graph_usability_test.dart
Résultat: 00:03 +6: All tests passed!
```

```text
Command: cd packages/map_editor && flutter test --reporter=compact test/storylines_current_global_story_characterization_test.dart
Résultat: 00:02 +2: All tests passed!
```

```text
Command: cd packages/map_editor && flutter test --reporter=compact test/narrative_workspace_projection_test.dart
Résultat: 00:01 +3: All tests passed!
```

### Shell Storylines

```text
Command: cd packages/map_editor && flutter test --reporter=compact test/storylines_workspace_shell_test.dart
Résultat: 00:08 +35 -1: Some tests failed.
Échec restant: golden préexistant absent `reports/narrativeStudio/storylines/screenshots/ns_storylines_v1_12_graph_empty_polished.png`.
Signal utile: les 35 tests non-golden passent après adaptation des clés Structure.
```

### Analyse

```text
Command: cd packages/map_editor && flutter analyze --no-fatal-infos lib/src/ui/canvas/storylines_workspace.dart lib/src/ui/canvas/storylines/storylines_graph_model.dart lib/src/ui/canvas/storylines/storylines_graph_painter.dart lib/src/ui/canvas/storylines/storylines_graph_view.dart lib/src/ui/canvas/storylines/storylines_structure_view.dart test/storylines_workspace_shell_test.dart test/storylines_current_global_story_characterization_test.dart test/narrative_workspace_projection_test.dart test/storylines_seed_graph_usability_test.dart test/storylines_structure_layout_test.dart
Sortie:
Analyzing 10 items...
No issues found! (ran in 2.0s)
```

### Gates rg

```text
Command: rg "Color\(0x|Colors\." packages/map_editor/lib/src/ui/canvas/storylines_workspace.dart packages/map_editor/lib/src/ui/canvas/storylines packages/map_editor/test/storylines_workspace_shell_test.dart packages/map_editor/test/storylines_seed_graph_usability_test.dart packages/map_editor/test/storylines_structure_layout_test.dart
Sortie : <vide>
```

```text
Command: rg "La brume du phare|Les cristaux de sel|Le Goélise du port|La cabane du phare|Maël|Lysa|Mado|Yvon|Soline" packages/map_editor/lib packages/map_core/lib
Sortie : <vide>
```

## 19. État final actualisé après addenda

Ce bloc actualise l'evidence pack après :

- alignement du chapeau `Structure` sur `Graph` ;
- migration de la liste de chapitres vers `ExpansionPanelList` / `ExpansionPanel` Flutter natifs ;
- déplacement des actions destructives dans les fenêtres `Modifier le chapitre` et `Modifier l'étape narrative` ;
- régénération des captures Structure bis.

```text
git status --short --untracked-files=all
 M packages/map_editor/lib/src/ui/canvas/storylines/storylines_structure_view.dart
 M packages/map_editor/lib/src/ui/canvas/storylines_workspace.dart
 M packages/map_editor/test/storylines_seed_graph_usability_test.dart
 M packages/map_editor/test/storylines_structure_layout_test.dart
 M packages/map_editor/test/storylines_workspace_shell_test.dart
 M reports/narrativeStudio/storylines/road_map_storylines.md
?? reports/narrativeStudio/storylines/ns_storylines_structure_bis_full_width_accordion_authoring.md
?? reports/narrativeStudio/storylines/screenshots/ns_storylines_structure_bis_authoring_actions.png
?? reports/narrativeStudio/storylines/screenshots/ns_storylines_structure_bis_collapsed_chapter.png
?? reports/narrativeStudio/storylines/screenshots/ns_storylines_structure_bis_expanded_chapter_steps.png
?? reports/narrativeStudio/storylines/screenshots/ns_storylines_structure_bis_full_width_accordion.png
?? reports/narrativeStudio/storylines/screenshots/ns_storylines_structure_bis_graph_regression.png
```

```text
git diff --stat
 .../storylines/storylines_structure_view.dart      | 922 ++++++++++++---------
 .../lib/src/ui/canvas/storylines_workspace.dart    | 510 +++++++++++-
 .../test/storylines_seed_graph_usability_test.dart |  10 +-
 .../test/storylines_structure_layout_test.dart     | 270 +++++-
 .../test/storylines_workspace_shell_test.dart      |  24 +-
 .../storylines/road_map_storylines.md              |  16 +-
 6 files changed, 1270 insertions(+), 482 deletions(-)
```

```text
git diff --name-only
packages/map_editor/lib/src/ui/canvas/storylines/storylines_structure_view.dart
packages/map_editor/lib/src/ui/canvas/storylines_workspace.dart
packages/map_editor/test/storylines_seed_graph_usability_test.dart
packages/map_editor/test/storylines_structure_layout_test.dart
packages/map_editor/test/storylines_workspace_shell_test.dart
reports/narrativeStudio/storylines/road_map_storylines.md
```

```text
git diff --check
Sortie : <vide>
```

Note de validation : un premier lancement parallèle de `test/narrative_workspace_projection_test.dart` a échoué sur un lock/native asset Flutter, puis la même commande relancée seule a passé avec `00:01 +3: All tests passed!`.

```text
Command: rg "storylines-chapter-row|selected-chapter-expanded|collapsed-chapters|structure-action-bar|structure-chapters-zone" packages/map_editor/lib/src/ui/canvas/storylines_workspace.dart packages/map_editor/lib/src/ui/canvas/storylines packages/map_editor/test/storylines_workspace_shell_test.dart packages/map_editor/test/storylines_seed_graph_usability_test.dart packages/map_editor/test/storylines_structure_layout_test.dart
Sortie : <vide>
```

```text
Command: git diff --check
Sortie : <vide>
```

## 8. Visual Gate

- `reports/narrativeStudio/storylines/screenshots/ns_storylines_structure_bis_full_width_accordion.png` — 57960 bytes
- `reports/narrativeStudio/storylines/screenshots/ns_storylines_structure_bis_collapsed_chapter.png` — 19474 bytes
- `reports/narrativeStudio/storylines/screenshots/ns_storylines_structure_bis_expanded_chapter_steps.png` — 19474 bytes
- `reports/narrativeStudio/storylines/screenshots/ns_storylines_structure_bis_authoring_actions.png` — 19474 bytes
- `reports/narrativeStudio/storylines/screenshots/ns_storylines_structure_bis_graph_regression.png` — 66011 bytes

Résultat visuel : la vue Structure n'est plus un split artificiel. Les chapitres sont empilés dans une liste accordéon, le chapitre ouvert révèle ses étapes, les actions d'authoring sont visibles, et la régression Graph garde les sideQuest nodes indépendants.

## 9. Git initial

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

## 10. Git courant avant création du rapport

```text
git status --short --untracked-files=all
M packages/map_editor/lib/src/ui/canvas/storylines/storylines_structure_view.dart
 M packages/map_editor/lib/src/ui/canvas/storylines_workspace.dart
 M packages/map_editor/test/storylines_seed_graph_usability_test.dart
 M packages/map_editor/test/storylines_structure_layout_test.dart
 M packages/map_editor/test/storylines_workspace_shell_test.dart
 M reports/narrativeStudio/storylines/road_map_storylines.md
?? reports/narrativeStudio/storylines/screenshots/ns_storylines_structure_bis_authoring_actions.png
?? reports/narrativeStudio/storylines/screenshots/ns_storylines_structure_bis_collapsed_chapter.png
?? reports/narrativeStudio/storylines/screenshots/ns_storylines_structure_bis_expanded_chapter_steps.png
?? reports/narrativeStudio/storylines/screenshots/ns_storylines_structure_bis_full_width_accordion.png
?? reports/narrativeStudio/storylines/screenshots/ns_storylines_structure_bis_graph_regression.png
```

```text
git diff --stat
.../storylines/storylines_structure_view.dart      | 955 ++++++++++++---------
 .../lib/src/ui/canvas/storylines_workspace.dart    | 428 ++++++++-
 .../test/storylines_seed_graph_usability_test.dart |  10 +-
 .../test/storylines_structure_layout_test.dart     | 217 ++++-
 .../test/storylines_workspace_shell_test.dart      |  24 +-
 .../storylines/road_map_storylines.md              |  16 +-
 6 files changed, 1198 insertions(+), 452 deletions(-)
```

```text
git diff --name-only
packages/map_editor/lib/src/ui/canvas/storylines/storylines_structure_view.dart
packages/map_editor/lib/src/ui/canvas/storylines_workspace.dart
packages/map_editor/test/storylines_seed_graph_usability_test.dart
packages/map_editor/test/storylines_structure_layout_test.dart
packages/map_editor/test/storylines_workspace_shell_test.dart
reports/narrativeStudio/storylines/road_map_storylines.md
```

```text
git diff --check
Sortie : <vide>
```

## 11. Diff des fichiers texte modifiés

```diff
diff --git a/packages/map_editor/lib/src/ui/canvas/storylines/storylines_structure_view.dart b/packages/map_editor/lib/src/ui/canvas/storylines/storylines_structure_view.dart
index ac5ccd14..2841fa34 100644
--- a/packages/map_editor/lib/src/ui/canvas/storylines/storylines_structure_view.dart
+++ b/packages/map_editor/lib/src/ui/canvas/storylines/storylines_structure_view.dart
@@ -1,9 +1,22 @@
 import 'package:flutter/cupertino.dart';
+import 'package:flutter/material.dart'
+    show ReorderableDragStartListener, ReorderableListView;
 import 'package:map_core/map_core.dart';
 
 import '../../../theme/theme.dart';
 import '../../design_system/design_system.dart';
 
+typedef StorylineStepAction = void Function(
+  StorylineChapter chapter,
+  StorylineStep step,
+);
+
+typedef StorylineStepReorder = void Function(
+  StorylineChapter chapter,
+  int oldIndex,
+  int newIndex,
+);
+
 class StorylinesStructureView extends StatelessWidget {
   const StorylinesStructureView({
     super.key,
@@ -11,7 +24,12 @@ class StorylinesStructureView extends StatelessWidget {
     required this.selectedChapter,
     required this.onChapterSelected,
     required this.onCreateChapter,
+    required this.onEditChapter,
+    required this.onDeleteChapter,
     required this.onCreateStep,
+    required this.onEditStep,
+    required this.onDeleteStep,
+    required this.onReorderSteps,
     required this.onAttachSideQuest,
   });
 
@@ -19,7 +37,12 @@ class StorylinesStructureView extends StatelessWidget {
   final StorylineChapter? selectedChapter;
   final ValueChanged<StorylineChapter> onChapterSelected;
   final VoidCallback? onCreateChapter;
+  final ValueChanged<StorylineChapter>? onEditChapter;
+  final ValueChanged<StorylineChapter>? onDeleteChapter;
   final VoidCallback? onCreateStep;
+  final StorylineStepAction? onEditStep;
+  final StorylineStepAction? onDeleteStep;
+  final StorylineStepReorder? onReorderSteps;
   final VoidCallback? onAttachSideQuest;
 
   @override
@@ -41,56 +64,61 @@ class StorylinesStructureView extends StatelessWidget {
       );
     }
 
-    final selectedChapter = this.selectedChapter;
-    final collapsedChapters = storyline.chapters
-        .where((chapter) => chapter.id != selectedChapter?.id)
-        .toList();
+    final chapters = _orderedChapters(storyline);
+    final selectedChapter = _selectedChapterFrom(chapters);
     return KeyedSubtree(
       key: const ValueKey('storylines-structure-read-only'),
-      child: SingleChildScrollView(
-        key: const ValueKey('storylines-structure-view'),
-        child: Column(
-          crossAxisAlignment: CrossAxisAlignment.stretch,
-          children: [
-            _StructureActionBar(
-              storyline: storyline,
-              onCreateChapter: onCreateChapter,
-              onAttachSideQuest: onAttachSideQuest,
-            ),
-            const SizedBox(height: 12),
-            Row(
-              crossAxisAlignment: CrossAxisAlignment.start,
-              children: [
-                Expanded(
-                  flex: 3,
-                  child: _SelectedChapterPanel(
+      child: LayoutBuilder(
+        builder: (context, constraints) {
+          return SingleChildScrollView(
+            key: const ValueKey('storylines-structure-view'),
+            child: ConstrainedBox(
+              constraints: BoxConstraints(minHeight: constraints.maxHeight),
+              child: Column(
+                crossAxisAlignment: CrossAxisAlignment.stretch,
+                children: [
+                  _StructureToolbar(
                     storyline: storyline,
-                    chapter: selectedChapter,
-                    onCreateStep: onCreateStep,
+                    onCreateChapter: onCreateChapter,
+                    onAttachSideQuest: onAttachSideQuest,
                   ),
-                ),
-                const SizedBox(width: 12),
-                Expanded(
-                  flex: 2,
-                  child: _CollapsedChaptersPanel(
-                    chapters: collapsedChapters,
-                    hasSelectedChapter: selectedChapter != null,
+                  const SizedBox(height: 12),
+                  _ChapterAccordionList(
+                    storyline: storyline,
+                    chapters: chapters,
+                    selectedChapter: selectedChapter,
                     onChapterSelected: onChapterSelected,
+                    onEditChapter: onEditChapter,
+                    onDeleteChapter: onDeleteChapter,
+                    onCreateStep: onCreateStep,
+                    onEditStep: onEditStep,
+                    onDeleteStep: onDeleteStep,
+                    onReorderSteps: onReorderSteps,
                   ),
-                ),
-              ],
+                ],
+              ),
             ),
-            const SizedBox(height: 12),
-            const _StructureSceneLinksPanel(),
-          ],
-        ),
+          );
+        },
       ),
     );
   }
+
+  StorylineChapter? _selectedChapterFrom(List<StorylineChapter> chapters) {
+    final selectedChapter = this.selectedChapter;
+    if (selectedChapter != null) {
+      for (final chapter in chapters) {
+        if (chapter.id == selectedChapter.id) {
+          return chapter;
+        }
+      }
+    }
+    return chapters.isEmpty ? null : chapters.first;
+  }
 }
 
-class _StructureActionBar extends StatelessWidget {
-  const _StructureActionBar({
+class _StructureToolbar extends StatelessWidget {
+  const _StructureToolbar({
     required this.storyline,
     required this.onCreateChapter,
     required this.onAttachSideQuest,
@@ -104,8 +132,8 @@ class _StructureActionBar extends StatelessWidget {
   Widget build(BuildContext context) {
     final colors = context.pokeMapColors;
     return PokeMapCard(
-      key: const ValueKey('storylines-structure-action-bar'),
-      padding: const EdgeInsets.all(14),
+      key: const ValueKey('storylines-structure-toolbar'),
+      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
       child: Column(
         crossAxisAlignment: CrossAxisAlignment.stretch,
         children: [
@@ -122,14 +150,14 @@ class _StructureActionBar extends StatelessWidget {
                   crossAxisAlignment: CrossAxisAlignment.start,
                   children: [
                     Text(
-                      'Structure de la storyline',
+                      'Chapitres',
                       style: TextStyle(
                         color: colors.textPrimary,
                         fontSize: 15,
                         fontWeight: FontWeight.w800,
                       ),
                     ),
-                    const SizedBox(height: 5),
+                    const SizedBox(height: 4),
                     Text(
                       storyline.title,
                       maxLines: 1,
@@ -143,25 +171,60 @@ class _StructureActionBar extends StatelessWidget {
                   ],
                 ),
               ),
-            ],
-          ),
-          const SizedBox(height: 10),
-          Wrap(
-            spacing: 8,
-            runSpacing: 8,
-            crossAxisAlignment: WrapCrossAlignment.center,
-            children: [
+              const SizedBox(width: 10),
               _StructureCompactMetric(
                 value: storyline.chapters.length.toString(),
                 label: 'Chapitres',
               ),
+              const SizedBox(width: 8),
               _StructureCompactMetric(
                 value: _storylineStepCount(storyline).toString(),
                 label: 'Étapes',
               ),
+              const SizedBox(width: 8),
               _StructureCompactMetric(
                 value: storyline.sceneLinks.length.toString(),
-                label: 'Scene links',
+                label: 'Scènes',
+              ),
+            ],
+          ),
+          const SizedBox(height: 10),
+          Wrap(
+            spacing: 8,
+            runSpacing: 8,
+            crossAxisAlignment: WrapCrossAlignment.center,
+            children: [
+              const PokeMapButton(
+                key: ValueKey('storylines-structure-search-action'),
+                onPressed: null,
+                variant: PokeMapButtonVariant.secondary,
+                size: PokeMapButtonSize.small,
+                leading: Icon(CupertinoIcons.search),
+                child: Text('Recherche'),
+              ),
+              const PokeMapButton(
+                key: ValueKey('storylines-structure-filter-action'),
+                onPressed: null,
+                variant: PokeMapButtonVariant.secondary,
+                size: PokeMapButtonSize.small,
+                leading: Icon(CupertinoIcons.slider_horizontal_3),
+                child: Text('Filtre'),
+              ),
+              const PokeMapButton(
+                key: ValueKey('storylines-structure-sort-action'),
+                onPressed: null,
+                variant: PokeMapButtonVariant.secondary,
+                size: PokeMapButtonSize.small,
+                leading: Icon(CupertinoIcons.arrow_up_arrow_down),
+                child: Text('Tri'),
+              ),
+              const PokeMapButton(
+                key: ValueKey('storylines-link-scene-disabled'),
+                onPressed: null,
+                variant: PokeMapButtonVariant.secondary,
+                size: PokeMapButtonSize.small,
+                leading: Icon(CupertinoIcons.link),
+                child: Text('Lier une scène'),
               ),
               if (storyline.type == StorylineType.sideQuest)
                 PokeMapButton(
@@ -194,205 +257,269 @@ class _StructureActionBar extends StatelessWidget {
   }
 }
 
-class _SelectedChapterPanel extends StatelessWidget {
-  const _SelectedChapterPanel({
+class _ChapterAccordionList extends StatelessWidget {
+  const _ChapterAccordionList({
     required this.storyline,
-    required this.chapter,
+    required this.chapters,
+    required this.selectedChapter,
+    required this.onChapterSelected,
+    required this.onEditChapter,
+    required this.onDeleteChapter,
     required this.onCreateStep,
+    required this.onEditStep,
+    required this.onDeleteStep,
+    required this.onReorderSteps,
   });
 
   final StorylineAsset storyline;
-  final StorylineChapter? chapter;
+  final List<StorylineChapter> chapters;
+  final StorylineChapter? selectedChapter;
+  final ValueChanged<StorylineChapter> onChapterSelected;
+  final ValueChanged<StorylineChapter>? onEditChapter;
+  final ValueChanged<StorylineChapter>? onDeleteChapter;
   final VoidCallback? onCreateStep;
+  final StorylineStepAction? onEditStep;
+  final StorylineStepAction? onDeleteStep;
+  final StorylineStepReorder? onReorderSteps;
 
   @override
   Widget build(BuildContext context) {
     final colors = context.pokeMapColors;
-    final chapter = this.chapter;
-    return KeyedSubtree(
-      key: const ValueKey('storylines-selected-chapter-expanded'),
-      child: PokeMapCard(
-        key: chapter == null
-            ? null
-            : ValueKey('storylines-chapter-row-${chapter.id}'),
+    if (chapters.isEmpty) {
+      return PokeMapCard(
+        key: const ValueKey('storylines-structure-accordion-list'),
         padding: const EdgeInsets.all(18),
-        selected: chapter != null,
-        child: chapter == null
-            ? _NoSelectedChapter(storyline: storyline)
-            : Column(
-                crossAxisAlignment: CrossAxisAlignment.stretch,
-                children: [
-                  Row(
-                    crossAxisAlignment: CrossAxisAlignment.start,
-                    children: [
-                      const PokeMapIconTile(
-                        icon: CupertinoIcons.bookmark_fill,
-                        tone: PokeMapTone.narrative,
-                        size: 38,
-                      ),
-                      const SizedBox(width: 14),
-                      Expanded(
-                        child: Column(
-                          crossAxisAlignment: CrossAxisAlignment.start,
-                          children: [
-                            Text(
-                              'Détail du chapitre',
-                              style: TextStyle(
-                                color: colors.textMuted,
-                                fontSize: 10.5,
-                                fontWeight: FontWeight.w800,
-                              ),
-                            ),
-                            const SizedBox(height: 6),
-                            Text(
-                              chapter.title,
-                              maxLines: 1,
-                              overflow: TextOverflow.ellipsis,
-                              style: TextStyle(
-                                color: colors.textPrimary,
-                                fontSize: 18,
-                                fontWeight: FontWeight.w800,
-                              ),
-                            ),
-                            const SizedBox(height: 6),
-                            Text(
-                              chapter.description ??
-                                  'Aucune description renseignée.',
-                              maxLines: 2,
-                              overflow: TextOverflow.ellipsis,
-                              style: TextStyle(
-                                color: colors.textSecondary,
-                                fontSize: 12.5,
-                                height: 1.4,
-                              ),
-                            ),
-                          ],
-                        ),
-                      ),
-                      const SizedBox(width: 12),
-                      PokeMapButton(
-                        key: const ValueKey('storylines-new-step-action'),
-                        onPressed: onCreateStep,
-                        variant: PokeMapButtonVariant.secondary,
-                        size: PokeMapButtonSize.small,
-                        leading: const Icon(CupertinoIcons.add),
-                        child: const Text('Nouvelle étape narrative'),
-                      ),
-                    ],
-                  ),
-                  const SizedBox(height: 14),
-                  Wrap(
-                    spacing: 8,
-                    runSpacing: 8,
-                    children: [
-                      _StructureBadge(label: 'Ordre ${chapter.order}'),
-                      _StructureBadge(
-                        label: _formatCount(
-                          chapter.steps.length,
-                          'étape narrative',
-                          'étapes narratives',
-                        ),
-                      ),
-                      _StructureBadge(
-                        label: _formatCount(
-                          _chapterSceneLinkCount(chapter),
-                          'scene link',
-                          'scene links',
-                        ),
-                      ),
-                    ],
-                  ),
-                  const SizedBox(height: 16),
-                  _SelectedChapterSteps(chapter: chapter),
-                ],
+        child: Column(
+          crossAxisAlignment: CrossAxisAlignment.start,
+          children: [
+            Text(
+              'Aucun chapitre',
+              style: TextStyle(
+                color: colors.textPrimary,
+                fontSize: 15,
+                fontWeight: FontWeight.w800,
               ),
-      ),
+            ),
+            const SizedBox(height: 8),
+            Text(
+              'Créez un premier chapitre pour organiser la progression de la storyline.',
+              style: TextStyle(
+                color: colors.textSecondary,
+                fontSize: 12.5,
+                height: 1.4,
+              ),
+            ),
+          ],
+        ),
+      );
+    }
+
+    return Column(
+      key: const ValueKey('storylines-structure-accordion-list'),
+      crossAxisAlignment: CrossAxisAlignment.stretch,
+      children: [
+        for (final chapter in chapters)
+          Padding(
+            padding: const EdgeInsets.only(bottom: 12),
+            child: _ChapterAccordionCard(
+              storyline: storyline,
+              chapter: chapter,
+              expanded: chapter.id == selectedChapter?.id,
+              onToggle: () => onChapterSelected(chapter),
+              onEditChapter:
+                  onEditChapter == null ? null : () => onEditChapter!(chapter),
+              onDeleteChapter: onDeleteChapter == null
+                  ? null
+                  : () => onDeleteChapter!(chapter),
+              onCreateStep:
+                  chapter.id == selectedChapter?.id ? onCreateStep : null,
+              onEditStep: onEditStep,
+              onDeleteStep: onDeleteStep,
+              onReorderSteps: onReorderSteps,
+            ),
+          ),
+      ],
     );
   }
 }
 
-class _NoSelectedChapter extends StatelessWidget {
-  const _NoSelectedChapter({required this.storyline});
+class _ChapterAccordionCard extends StatelessWidget {
+  const _ChapterAccordionCard({
+    required this.storyline,
+    required this.chapter,
+    required this.expanded,
+    required this.onToggle,
+    required this.onEditChapter,
+    required this.onDeleteChapter,
+    required this.onCreateStep,
+    required this.onEditStep,
+    required this.onDeleteStep,
+    required this.onReorderSteps,
+  });
 
   final StorylineAsset storyline;
+  final StorylineChapter chapter;
+  final bool expanded;
+  final VoidCallback onToggle;
+  final VoidCallback? onEditChapter;
+  final VoidCallback? onDeleteChapter;
+  final VoidCallback? onCreateStep;
+  final StorylineStepAction? onEditStep;
+  final StorylineStepAction? onDeleteStep;
+  final StorylineStepReorder? onReorderSteps;
 
   @override
   Widget build(BuildContext context) {
     final colors = context.pokeMapColors;
-    return Column(
-      crossAxisAlignment: CrossAxisAlignment.start,
-      children: [
-        Text(
-          'Chapitres',
-          style: TextStyle(
-            color: colors.textPrimary,
-            fontSize: 15,
-            fontWeight: FontWeight.w800,
-          ),
-        ),
-        const SizedBox(height: 8),
-        Text(
-          storyline.chapters.isEmpty
-              ? 'Aucun chapitre\nCréez un premier chapitre pour organiser votre histoire.'
-              : 'Sélectionnez un chapitre pour voir ses étapes narratives.',
-          style: TextStyle(
-            color: colors.textSecondary,
-            fontSize: 12.5,
-            height: 1.4,
-          ),
-        ),
-        const SizedBox(height: 14),
-        KeyedSubtree(
-          key: const ValueKey('storylines-v1-structure-steps'),
-          child: Text(
-            'Étapes narratives',
-            style: TextStyle(
-              color: colors.textPrimary,
-              fontSize: 14,
-              fontWeight: FontWeight.w800,
+    return PokeMapCard(
+      key: ValueKey('storylines-chapter-accordion-${chapter.id}'),
+      padding: const EdgeInsets.all(14),
+      selected: expanded,
+      child: Column(
+        crossAxisAlignment: CrossAxisAlignment.stretch,
+        children: [
+          KeyedSubtree(
+            key: ValueKey(
+              expanded
+                  ? 'storylines-chapter-expanded-${chapter.id}'
+                  : 'storylines-chapter-collapsed-${chapter.id}',
+            ),
+            child: Row(
+              crossAxisAlignment: CrossAxisAlignment.start,
+              children: [
+                const PokeMapIconTile(
+                  icon: CupertinoIcons.bookmark,
+                  tone: PokeMapTone.narrative,
+                  size: 34,
+                ),
+                const SizedBox(width: 12),
+                Expanded(
+                  child: Column(
+                    crossAxisAlignment: CrossAxisAlignment.start,
+                    children: [
+                      Text(
+                        'Chapitre ${chapter.order + 1}',
+                        style: TextStyle(
+                          color: colors.textMuted,
+                          fontSize: 10.5,
+                          fontWeight: FontWeight.w800,
+                        ),
+                      ),
+                      const SizedBox(height: 5),
+                      Text(
+                        chapter.title,
+                        maxLines: 1,
+                        overflow: TextOverflow.ellipsis,
+                        style: TextStyle(
+                          color: colors.textPrimary,
+                          fontSize: expanded ? 16 : 14,
+                          fontWeight: FontWeight.w800,
+                        ),
+                      ),
+                      const SizedBox(height: 5),
+                      Text(
+                        chapter.description ?? 'Aucune description.',
+                        maxLines: expanded ? 2 : 1,
+                        overflow: TextOverflow.ellipsis,
+                        style: TextStyle(
+                          color: colors.textSecondary,
+                          fontSize: 12,
+                          height: 1.35,
+                        ),
+                      ),
+                    ],
+                  ),
+                ),
+                const SizedBox(width: 12),
+                _ChapterHeaderMetrics(
+                  chapter: chapter,
+                  attachedSideQuestCount:
+                      _attachedSideQuestCount(storyline, chapter),
+                ),
+                const SizedBox(width: 10),
+                PokeMapButton(
+                  key: ValueKey('storylines-edit-chapter-action-${chapter.id}'),
+                  onPressed: onEditChapter,
+                  variant: PokeMapButtonVariant.secondary,
+                  size: PokeMapButtonSize.small,
+                  leading: const Icon(CupertinoIcons.pencil),
+                  child: const Text('Modifier'),
+                ),
+                const SizedBox(width: 8),
+                PokeMapButton(
+                  key: ValueKey(
+                    'storylines-delete-chapter-action-${chapter.id}',
+                  ),
+                  onPressed: onDeleteChapter,
+                  variant: PokeMapButtonVariant.danger,
+                  size: PokeMapButtonSize.small,
+                  leading: const Icon(CupertinoIcons.trash),
+                  child: const Text('Supprimer'),
+                ),
+                const SizedBox(width: 8),
+                PokeMapButton(
+                  key: ValueKey('storylines-chapter-toggle-${chapter.id}'),
+                  onPressed: onToggle,
+                  variant: PokeMapButtonVariant.ghost,
+                  size: PokeMapButtonSize.small,
+                  leading: Icon(
+                    expanded
+                        ? CupertinoIcons.chevron_up
+                        : CupertinoIcons.chevron_down,
+                  ),
+                  child: Text(expanded ? 'Ouvert' : 'Ouvrir'),
+                ),
+              ],
             ),
           ),
-        ),
-      ],
+          if (expanded) ...[
+            const SizedBox(height: 14),
+            _ExpandedChapterBody(
+              chapter: chapter,
+              onCreateStep: onCreateStep,
+              onEditStep: onEditStep,
+              onDeleteStep: onDeleteStep,
+              onReorderSteps: onReorderSteps,
+            ),
+          ],
+        ],
+      ),
     );
   }
 }
 
-class _SelectedChapterSteps extends StatelessWidget {
-  const _SelectedChapterSteps({required this.chapter});
+class _ChapterHeaderMetrics extends StatelessWidget {
+  const _ChapterHeaderMetrics({
+    required this.chapter,
+    required this.attachedSideQuestCount,
+  });
 
   final StorylineChapter chapter;
+  final int attachedSideQuestCount;
 
   @override
   Widget build(BuildContext context) {
-    final colors = context.pokeMapColors;
-    return Column(
-      key: const ValueKey('storylines-v1-structure-steps'),
-      crossAxisAlignment: CrossAxisAlignment.stretch,
+    return Wrap(
+      spacing: 6,
+      runSpacing: 6,
+      alignment: WrapAlignment.end,
       children: [
-        Text(
-          'Étapes narratives',
-          style: TextStyle(
-            color: colors.textPrimary,
-            fontSize: 14,
-            fontWeight: FontWeight.w800,
+        _StructureBadge(
+          label: _formatCount(chapter.steps.length, 'étape', 'étapes'),
+        ),
+        _StructureBadge(
+          label: _formatCount(
+            _chapterSceneLinkCount(chapter),
+            'scène liée',
+            'scènes liées',
           ),
         ),
-        const SizedBox(height: 10),
-        if (chapter.steps.isEmpty)
-          Text(
-            'Aucune étape narrative\nAjoutez une première étape pour définir la progression du chapitre.',
-            style: TextStyle(
-              color: colors.textSecondary,
-              fontSize: 12,
-              height: 1.35,
-            ),
-          )
-        else
-          ...chapter.steps.map(
-            (step) => Padding(
-              padding: const EdgeInsets.only(bottom: 10),
-              child: _StructureStepRow(step: step),
+        if (attachedSideQuestCount > 0)
+          _StructureBadge(
+            label: _formatCount(
+              attachedSideQuestCount,
+              'quête disponible',
+              'quêtes disponibles',
             ),
           ),
       ],
@@ -400,165 +527,110 @@ class _SelectedChapterSteps extends StatelessWidget {
   }
 }
 
-class _CollapsedChaptersPanel extends StatelessWidget {
-  const _CollapsedChaptersPanel({
-    required this.chapters,
-    required this.hasSelectedChapter,
-    required this.onChapterSelected,
+class _ExpandedChapterBody extends StatelessWidget {
+  const _ExpandedChapterBody({
+    required this.chapter,
+    required this.onCreateStep,
+    required this.onEditStep,
+    required this.onDeleteStep,
+    required this.onReorderSteps,
   });
 
-  final List<StorylineChapter> chapters;
-  final bool hasSelectedChapter;
-  final ValueChanged<StorylineChapter> onChapterSelected;
+  final StorylineChapter chapter;
+  final VoidCallback? onCreateStep;
+  final StorylineStepAction? onEditStep;
+  final StorylineStepAction? onDeleteStep;
+  final StorylineStepReorder? onReorderSteps;
 
   @override
   Widget build(BuildContext context) {
     final colors = context.pokeMapColors;
+    final steps = _orderedSteps(chapter);
     return Column(
-      key: const ValueKey('storylines-structure-chapters-zone'),
+      key: const ValueKey('storylines-v1-structure-steps'),
       crossAxisAlignment: CrossAxisAlignment.stretch,
       children: [
         Row(
           children: [
             Expanded(
               child: Text(
-                hasSelectedChapter ? 'Autres chapitres' : 'Chapitres',
+                'Étapes narratives',
                 style: TextStyle(
                   color: colors.textPrimary,
-                  fontSize: 14,
+                  fontSize: 13.5,
                   fontWeight: FontWeight.w800,
                 ),
               ),
             ),
-            Text(
-              chapters.isEmpty && hasSelectedChapter
-                  ? 'Aucun autre chapitre'
-                  : _formatCount(chapters.length, 'chapitre', 'chapitres'),
-              style: TextStyle(
-                color: colors.textSecondary,
-                fontSize: 11.5,
-                fontWeight: FontWeight.w700,
-              ),
+            PokeMapButton(
+              key: const ValueKey('storylines-new-step-action'),
+              onPressed: onCreateStep,
+              variant: PokeMapButtonVariant.secondary,
+              size: PokeMapButtonSize.small,
+              leading: const Icon(CupertinoIcons.add),
+              child: const Text('Nouvelle étape narrative'),
             ),
           ],
         ),
-        const SizedBox(height: 8),
-        if (chapters.isEmpty)
+        const SizedBox(height: 10),
+        if (steps.isEmpty)
           PokeMapCard(
-            key: const ValueKey('storylines-collapsed-chapters'),
             padding: const EdgeInsets.all(12),
             child: Text(
-              hasSelectedChapter
-                  ? 'Le chapitre sélectionné est le seul chapitre.'
-                  : 'Aucun chapitre fermé à afficher.',
-              style: TextStyle(color: colors.textSecondary, fontSize: 12),
+              'Aucune étape narrative. Ajoutez une première étape pour définir la progression du chapitre.',
+              style: TextStyle(
+                color: colors.textSecondary,
+                fontSize: 12,
+                height: 1.35,
+              ),
             ),
           )
         else
-          Column(
-            key: const ValueKey('storylines-collapsed-chapters'),
-            children: [
-              for (final chapter in chapters)
-                Padding(
-                  padding: const EdgeInsets.only(bottom: 10),
-                  child: _CollapsedChapterCard(
-                    chapter: chapter,
-                    onTap: () => onChapterSelected(chapter),
-                  ),
+          ReorderableListView.builder(
+            key: ValueKey('storylines-steps-reorder-list-${chapter.id}'),
+            shrinkWrap: true,
+            physics: const NeverScrollableScrollPhysics(),
+            buildDefaultDragHandles: false,
+            onReorderItem: (oldIndex, newIndex) {
+              onReorderSteps?.call(chapter, oldIndex, newIndex);
+            },
+            itemCount: steps.length,
+            itemBuilder: (context, index) {
+              final step = steps[index];
+              return Padding(
+                key: ValueKey('storylines-step-row-wrapper-${step.id}'),
+                padding: const EdgeInsets.only(bottom: 8),
+                child: _StructureStepRow(
+                  chapter: chapter,
+                  step: step,
+                  index: index,
+                  onEditStep: onEditStep,
+                  onDeleteStep: onDeleteStep,
                 ),
-            ],
+              );
+            },
           ),
+        const SizedBox(height: 8),
+        const _SceneLinkNotice(),
       ],
     );
   }
 }
 
-class _CollapsedChapterCard extends StatelessWidget {
-  const _CollapsedChapterCard({
+class _StructureStepRow extends StatelessWidget {
+  const _StructureStepRow({
     required this.chapter,
-    required this.onTap,
+    required this.step,
+    required this.index,
+    required this.onEditStep,
+    required this.onDeleteStep,
   });
 
   final StorylineChapter chapter;
-  final VoidCallback onTap;
-
-  @override
-  Widget build(BuildContext context) {
-    final colors = context.pokeMapColors;
-    return PokeMapCard(
-      key: ValueKey('storylines-chapter-row-${chapter.id}'),
-      padding: const EdgeInsets.all(12),
-      onTap: onTap,
-      child: Row(
-        crossAxisAlignment: CrossAxisAlignment.start,
-        children: [
-          const PokeMapIconTile(
-            icon: CupertinoIcons.bookmark,
-            tone: PokeMapTone.neutral,
-            size: 30,
-          ),
-          const SizedBox(width: 10),
-          Expanded(
-            child: Column(
-              crossAxisAlignment: CrossAxisAlignment.start,
-              children: [
-                Text(
-                  'Chapitre ${chapter.order + 1}',
-                  style: TextStyle(
-                    color: colors.textMuted,
-                    fontSize: 10.5,
-                    fontWeight: FontWeight.w800,
-                  ),
-                ),
-                const SizedBox(height: 4),
-                Text(
-                  chapter.title,
-                  maxLines: 1,
-                  overflow: TextOverflow.ellipsis,
-                  style: TextStyle(
-                    color: colors.textPrimary,
-                    fontSize: 12.5,
-                    fontWeight: FontWeight.w800,
-                  ),
-                ),
-                const SizedBox(height: 4),
-                Text(
-                  chapter.description ?? 'Aucune description.',
-                  maxLines: 2,
-                  overflow: TextOverflow.ellipsis,
-                  style: TextStyle(
-                    color: colors.textSecondary,
-                    fontSize: 11,
-                    height: 1.25,
-                  ),
-                ),
-                const SizedBox(height: 7),
-                _StructureBadge(
-                  label: _formatCount(
-                    chapter.steps.length,
-                    'étape',
-                    'étapes',
-                  ),
-                ),
-              ],
-            ),
-          ),
-          const SizedBox(width: 6),
-          Icon(
-            CupertinoIcons.chevron_right,
-            color: colors.textMuted,
-            size: 14,
-          ),
-        ],
-      ),
-    );
-  }
-}
-
-class _StructureStepRow extends StatelessWidget {
-  const _StructureStepRow({required this.step});
-
   final StorylineStep step;
+  final int index;
+  final StorylineStepAction? onEditStep;
+  final StorylineStepAction? onDeleteStep;
 
   @override
   Widget build(BuildContext context) {
@@ -566,15 +638,24 @@ class _StructureStepRow extends StatelessWidget {
     final sceneLinkCount = step.sceneLinkIds.length;
     return PokeMapCard(
       key: ValueKey('storylines-step-row-${step.id}'),
-      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
+      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
       child: Row(
         crossAxisAlignment: CrossAxisAlignment.start,
         children: [
-          const PokeMapIconTile(
-            icon: CupertinoIcons.flag,
-            tone: PokeMapTone.info,
-            size: 28,
+          ReorderableDragStartListener(
+            key: ValueKey('storylines-step-drag-${step.id}'),
+            index: index,
+            child: Padding(
+              padding: const EdgeInsets.only(top: 3),
+              child: Icon(
+                CupertinoIcons.line_horizontal_3,
+                color: colors.textMuted,
+                size: 18,
+              ),
+            ),
           ),
+          const SizedBox(width: 10),
+          _StructureBadge(label: 'Étape ${step.order + 1}'),
           const SizedBox(width: 12),
           Expanded(
             child: Column(
@@ -604,11 +685,36 @@ class _StructureStepRow extends StatelessWidget {
               ],
             ),
           ),
-          const SizedBox(width: 12),
+          const SizedBox(width: 10),
           _StructureBadge(
             label: sceneLinkCount == 0
                 ? 'Aucune scène liée'
-                : _formatCount(sceneLinkCount, 'scène liée', 'scènes liées'),
+                : _formatCount(
+                    sceneLinkCount,
+                    'scène liée',
+                    'scènes liées',
+                  ),
+          ),
+          const SizedBox(width: 8),
+          PokeMapButton(
+            key: ValueKey('storylines-edit-step-action-${step.id}'),
+            onPressed:
+                onEditStep == null ? null : () => onEditStep!(chapter, step),
+            variant: PokeMapButtonVariant.secondary,
+            size: PokeMapButtonSize.small,
+            leading: const Icon(CupertinoIcons.pencil),
+            child: const Text('Éditer'),
+          ),
+          const SizedBox(width: 8),
+          PokeMapButton(
+            key: ValueKey('storylines-delete-step-action-${step.id}'),
+            onPressed: onDeleteStep == null
+                ? null
+                : () => onDeleteStep!(chapter, step),
+            variant: PokeMapButtonVariant.danger,
+            size: PokeMapButtonSize.small,
+            leading: const Icon(CupertinoIcons.trash),
+            child: const Text('Retirer'),
           ),
         ],
       ),
@@ -616,47 +722,32 @@ class _StructureStepRow extends StatelessWidget {
   }
 }
 
-class _StructureSceneLinksPanel extends StatelessWidget {
-  const _StructureSceneLinksPanel();
+class _SceneLinkNotice extends StatelessWidget {
+  const _SceneLinkNotice();
 
   @override
   Widget build(BuildContext context) {
     final colors = context.pokeMapColors;
     return PokeMapCard(
       key: const ValueKey('storylines-v1-structure-scenes'),
-      padding: const EdgeInsets.all(14),
+      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
       child: Row(
         children: [
-          Expanded(
-            child: Column(
-              crossAxisAlignment: CrossAxisAlignment.start,
-              children: [
-                Text(
-                  'Scènes liées',
-                  style: TextStyle(
-                    color: colors.textPrimary,
-                    fontSize: 13,
-                    fontWeight: FontWeight.w800,
-                  ),
-                ),
-                const SizedBox(height: 5),
-                Text(
-                  'Scènes liées à venir. Les scènes seront reliées dans un prochain lot.',
-                  style: TextStyle(
-                    color: colors.textSecondary,
-                    fontSize: 12,
-                  ),
-                ),
-              ],
-            ),
+          const PokeMapIconTile(
+            icon: CupertinoIcons.link,
+            tone: PokeMapTone.neutral,
+            size: 28,
           ),
           const SizedBox(width: 10),
-          const PokeMapButton(
-            key: ValueKey('storylines-link-scene-disabled'),
-            onPressed: null,
-            variant: PokeMapButtonVariant.secondary,
-            size: PokeMapButtonSize.small,
-            child: Text('Lier une scène — bientôt'),
+          Expanded(
+            child: Text(
+              'Liaison de scène à venir : aucune scène placeholder ni sceneLink n’est créé depuis cette vue.',
+              style: TextStyle(
+                color: colors.textSecondary,
+                fontSize: 11.5,
+                height: 1.3,
+              ),
+            ),
           ),
         ],
       ),
@@ -676,36 +767,30 @@ class _StructureCompactMetric extends StatelessWidget {
   @override
   Widget build(BuildContext context) {
     final colors = context.pokeMapColors;
-    return DecoratedBox(
-      decoration: BoxDecoration(
-        color: colors.controlSurface,
-        borderRadius: BorderRadius.circular(8),
-        border: Border.all(color: colors.borderSubtle),
-      ),
-      child: Padding(
-        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
-        child: Row(
-          mainAxisSize: MainAxisSize.min,
-          children: [
-            Text(
-              value,
-              style: TextStyle(
-                color: colors.textPrimary,
-                fontSize: 13,
-                fontWeight: FontWeight.w800,
-              ),
+    return PokeMapCard(
+      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
+      child: Column(
+        mainAxisSize: MainAxisSize.min,
+        crossAxisAlignment: CrossAxisAlignment.start,
+        children: [
+          Text(
+            value,
+            style: TextStyle(
+              color: colors.textPrimary,
+              fontSize: 13,
+              fontWeight: FontWeight.w800,
             ),
-            const SizedBox(width: 5),
-            Text(
-              label,
-              style: TextStyle(
-                color: colors.textSecondary,
-                fontSize: 10.5,
-                fontWeight: FontWeight.w700,
-              ),
+          ),
+          const SizedBox(height: 2),
+          Text(
+            label,
+            style: TextStyle(
+              color: colors.textMuted,
+              fontSize: 9.5,
+              fontWeight: FontWeight.w700,
             ),
-          ],
-        ),
+          ),
+        ],
       ),
     );
   }
@@ -719,27 +804,40 @@ class _StructureBadge extends StatelessWidget {
   @override
   Widget build(BuildContext context) {
     final colors = context.pokeMapColors;
-    return DecoratedBox(
-      decoration: BoxDecoration(
-        color: colors.controlSurface,
-        borderRadius: BorderRadius.circular(6),
-        border: Border.all(color: colors.borderSubtle),
-      ),
-      child: Padding(
-        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
-        child: Text(
-          label,
-          style: TextStyle(
-            color: colors.textSecondary,
-            fontSize: 11,
-            fontWeight: FontWeight.w700,
-          ),
+    return PokeMapCard(
+      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
+      child: Text(
+        label,
+        style: TextStyle(
+          color: colors.textSecondary,
+          fontSize: 10.5,
+          fontWeight: FontWeight.w700,
         ),
       ),
     );
   }
 }
 
+List<StorylineChapter> _orderedChapters(StorylineAsset storyline) {
+  return [...storyline.chapters]..sort((a, b) {
+      final order = a.order.compareTo(b.order);
+      if (order != 0) return order;
+      final title = a.title.compareTo(b.title);
+      if (title != 0) return title;
+      return a.id.compareTo(b.id);
+    });
+}
+
+List<StorylineStep> _orderedSteps(StorylineChapter chapter) {
+  return [...chapter.steps]..sort((a, b) {
+      final order = a.order.compareTo(b.order);
+      if (order != 0) return order;
+      final title = a.title.compareTo(b.title);
+      if (title != 0) return title;
+      return a.id.compareTo(b.id);
+    });
+}
+
 int _storylineStepCount(StorylineAsset storyline) {
   return storyline.chapters.fold<int>(
     0,
@@ -755,6 +853,35 @@ int _chapterSceneLinkCount(StorylineChapter chapter) {
       );
 }
 
+int _attachedSideQuestCount(
+  StorylineAsset storyline,
+  StorylineChapter chapter,
+) {
+  if (storyline.type != StorylineType.main) {
+    return 0;
+  }
+  final chapterStepIds = chapter.steps.map((step) => step.id).toSet();
+  var count = 0;
+  for (final relationship in storyline.relationships) {
+    if (relationship.kind !=
+        StorylineRelationshipKind.sideQuestAvailableDuring) {
+      continue;
+    }
+    final anchor =
+        relationship.anchor ?? relationship.availability?.startAnchor;
+    if (anchor == null) continue;
+    if (anchor.kind == StorylineAnchorKind.chapter &&
+        anchor.targetId == chapter.id) {
+      count += 1;
+    }
+    if (anchor.kind == StorylineAnchorKind.step &&
+        chapterStepIds.contains(anchor.targetId)) {
+      count += 1;
+    }
+  }
+  return count;
+}
+
 String _formatCount(int count, String singular, String plural) {
   return '$count ${count == 1 ? singular : plural}';
 }
diff --git a/packages/map_editor/lib/src/ui/canvas/storylines_workspace.dart b/packages/map_editor/lib/src/ui/canvas/storylines_workspace.dart
index 98f36cf2..ff9774bc 100644
--- a/packages/map_editor/lib/src/ui/canvas/storylines_workspace.dart
+++ b/packages/map_editor/lib/src/ui/canvas/storylines_workspace.dart
@@ -77,6 +77,20 @@ class _StorylinesWorkspaceState extends ConsumerState<StorylinesWorkspace> {
               onCreateChapter: project == null || selectedStoryline == null
                   ? null
                   : () => _openCreateChapterDialog(project, selectedStoryline),
+              onEditChapter: project == null || selectedStoryline == null
+                  ? null
+                  : (chapter) => _openEditChapterDialog(
+                        project,
+                        selectedStoryline,
+                        chapter,
+                      ),
+              onDeleteChapter: project == null || selectedStoryline == null
+                  ? null
+                  : (chapter) => _deleteChapter(
+                        project,
+                        selectedStoryline,
+                        chapter,
+                      ),
               onCreateStep: project == null ||
                       selectedStoryline == null ||
                       selectedChapter == null
@@ -86,6 +100,31 @@ class _StorylinesWorkspaceState extends ConsumerState<StorylinesWorkspace> {
                         selectedStoryline,
                         selectedChapter,
                       ),
+              onEditStep: project == null || selectedStoryline == null
+                  ? null
+                  : (chapter, step) => _openEditStepDialog(
+                        project,
+                        selectedStoryline,
+                        chapter,
+                        step,
+                      ),
+              onDeleteStep: project == null || selectedStoryline == null
+                  ? null
+                  : (chapter, step) => _deleteStep(
+                        project,
+                        selectedStoryline,
+                        chapter,
+                        step,
+                      ),
+              onReorderSteps: project == null || selectedStoryline == null
+                  ? null
+                  : (chapter, oldIndex, newIndex) => _reorderSteps(
+                        project,
+                        selectedStoryline,
+                        chapter,
+                        oldIndex,
+                        newIndex,
+                      ),
               onAttachSideQuest: project == null ||
                       selectedStoryline == null ||
                       selectedStoryline.type != StorylineType.sideQuest
@@ -303,6 +342,245 @@ class _StorylinesWorkspaceState extends ConsumerState<StorylinesWorkspace> {
     });
   }
 
+  Future<void> _openEditChapterDialog(
+    ProjectManifest project,
+    StorylineAsset storyline,
+    StorylineChapter chapter,
+  ) async {
+    final draft = await showCupertinoDialog<_StructureItemDraft>(
+      context: context,
+      builder: (context) => _CreateStructureItemDialog(
+        dialogKey: const ValueKey('storylines-edit-chapter-dialog'),
+        title: 'Modifier le chapitre',
+        titleFieldKey: const ValueKey('storylines-edit-chapter-title-field'),
+        descriptionFieldKey: const ValueKey(
+          'storylines-edit-chapter-description-field',
+        ),
+        cancelKey: const ValueKey('storylines-edit-chapter-cancel'),
+        submitKey: const ValueKey('storylines-edit-chapter-submit'),
+        initialTitle: chapter.title,
+        initialDescription: chapter.description,
+        submitLabel: 'Enregistrer',
+      ),
+    );
+    if (draft == null || !mounted) {
+      return;
+    }
+    final updatedChapter = _copyChapterWith(
+      chapter,
+      title: draft.title,
+      description: draft.description,
+      replaceDescription: true,
+    );
+    final updatedStoryline = _copyStorylineWith(
+      storyline,
+      chapters: storyline.chapters
+          .map(
+            (current) => current.id == chapter.id ? updatedChapter : current,
+          )
+          .toList(growable: false),
+    );
+    _applyStorylineUpdate(
+      project,
+      updatedStoryline,
+      statusMessage: 'Chapitre modifié',
+    );
+    setState(() {
+      _selectedStorylineId = storyline.id;
+      _selectedChapterId = chapter.id;
+      _selectedTab = _StorylineContentTab.structure;
+    });
+  }
+
+  Future<void> _deleteChapter(
+    ProjectManifest project,
+    StorylineAsset storyline,
+    StorylineChapter chapter,
+  ) async {
+    final confirmed = await showCupertinoDialog<bool>(
+      context: context,
+      builder: (context) => _ConfirmStructureDeleteDialog(
+        title: 'Supprimer le chapitre',
+        message:
+            'Le chapitre "${chapter.title}" et ses étapes narratives seront retirés de cette storyline.',
+      ),
+    );
+    if (confirmed != true || !mounted) {
+      return;
+    }
+    final removedIndex =
+        storyline.chapters.indexWhere((current) => current.id == chapter.id);
+    final remaining = storyline.chapters
+        .where((current) => current.id != chapter.id)
+        .toList(growable: false);
+    final normalized = _normalizeChapterOrders(remaining);
+    final updatedStoryline = _copyStorylineWith(
+      storyline,
+      chapters: normalized,
+    );
+    _applyStorylineUpdate(
+      project,
+      updatedStoryline,
+      statusMessage: 'Chapitre supprimé',
+    );
+    setState(() {
+      _selectedStorylineId = storyline.id;
+      if (normalized.isEmpty) {
+        _selectedChapterId = null;
+      } else {
+        final nextIndex = removedIndex >= normalized.length
+            ? normalized.length - 1
+            : removedIndex;
+        _selectedChapterId = normalized[nextIndex].id;
+      }
+      _selectedTab = _StorylineContentTab.structure;
+    });
+  }
+
+  Future<void> _openEditStepDialog(
+    ProjectManifest project,
+    StorylineAsset storyline,
+    StorylineChapter chapter,
+    StorylineStep step,
+  ) async {
+    final draft = await showCupertinoDialog<_StructureItemDraft>(
+      context: context,
+      builder: (context) => _CreateStructureItemDialog(
+        dialogKey: const ValueKey('storylines-edit-step-dialog'),
+        title: 'Modifier l’étape narrative',
+        titleFieldKey: const ValueKey('storylines-edit-step-title-field'),
+        descriptionFieldKey: const ValueKey(
+          'storylines-edit-step-description-field',
+        ),
+        cancelKey: const ValueKey('storylines-edit-step-cancel'),
+        submitKey: const ValueKey('storylines-edit-step-submit'),
+        initialTitle: step.title,
+        initialDescription: step.description,
+        submitLabel: 'Enregistrer',
+      ),
+    );
+    if (draft == null || !mounted) {
+      return;
+    }
+    final updatedStep = _copyStepWith(
+      step,
+      title: draft.title,
+      description: draft.description,
+      replaceDescription: true,
+    );
+    final updatedChapter = _copyChapterWith(
+      chapter,
+      steps: chapter.steps
+          .map((current) => current.id == step.id ? updatedStep : current)
+          .toList(growable: false),
+    );
+    final updatedStoryline = _copyStorylineWith(
+      storyline,
+      chapters: storyline.chapters
+          .map(
+            (current) => current.id == chapter.id ? updatedChapter : current,
+          )
+          .toList(growable: false),
+    );
+    _applyStorylineUpdate(
+      project,
+      updatedStoryline,
+      statusMessage: 'Étape narrative modifiée',
+    );
+    setState(() {
+      _selectedStorylineId = storyline.id;
+      _selectedChapterId = chapter.id;
+      _selectedTab = _StorylineContentTab.structure;
+    });
+  }
+
+  Future<void> _deleteStep(
+    ProjectManifest project,
+    StorylineAsset storyline,
+    StorylineChapter chapter,
+    StorylineStep step,
+  ) async {
+    final confirmed = await showCupertinoDialog<bool>(
+      context: context,
+      builder: (context) => _ConfirmStructureDeleteDialog(
+        title: 'Supprimer l’étape narrative',
+        message:
+            'L’étape "${step.title}" sera retirée de ce chapitre sans créer ni supprimer de scène.',
+      ),
+    );
+    if (confirmed != true || !mounted) {
+      return;
+    }
+    final updatedSteps = _normalizeStepOrders(
+      chapter.steps
+          .where((current) => current.id != step.id)
+          .toList(growable: false),
+    );
+    final updatedChapter = _copyChapterWith(chapter, steps: updatedSteps);
+    final updatedStoryline = _copyStorylineWith(
+      storyline,
+      chapters: storyline.chapters
+          .map(
+            (current) => current.id == chapter.id ? updatedChapter : current,
+          )
+          .toList(growable: false),
+    );
+    _applyStorylineUpdate(
+      project,
+      updatedStoryline,
+      statusMessage: 'Étape narrative supprimée',
+    );
+    setState(() {
+      _selectedStorylineId = storyline.id;
+      _selectedChapterId = chapter.id;
+      _selectedTab = _StorylineContentTab.structure;
+    });
+  }
+
+  void _reorderSteps(
+    ProjectManifest project,
+    StorylineAsset storyline,
+    StorylineChapter chapter,
+    int oldIndex,
+    int newIndex,
+  ) {
+    final steps = _orderedStepsForMutation(chapter);
+    if (oldIndex < 0 || oldIndex >= steps.length) {
+      return;
+    }
+    var targetIndex = newIndex;
+    if (targetIndex < 0) {
+      targetIndex = 0;
+    }
+    if (targetIndex >= steps.length) {
+      targetIndex = steps.length - 1;
+    }
+    final moved = steps.removeAt(oldIndex);
+    steps.insert(targetIndex, moved);
+    final updatedChapter = _copyChapterWith(
+      chapter,
+      steps: _normalizeStepOrders(steps),
+    );
+    final updatedStoryline = _copyStorylineWith(
+      storyline,
+      chapters: storyline.chapters
+          .map(
+            (current) => current.id == chapter.id ? updatedChapter : current,
+          )
+          .toList(growable: false),
+    );
+    _applyStorylineUpdate(
+      project,
+      updatedStoryline,
+      statusMessage: 'Étapes narratives réordonnées',
+    );
+    setState(() {
+      _selectedStorylineId = storyline.id;
+      _selectedChapterId = chapter.id;
+      _selectedTab = _StorylineContentTab.structure;
+    });
+  }
+
   Future<void> _openAttachSideQuestDialog(
     ProjectManifest project,
     StorylineAsset sideQuest,
@@ -503,13 +781,18 @@ StorylineAsset _copyStorylineWith(
 
 StorylineChapter _copyChapterWith(
   StorylineChapter chapter, {
+  String? title,
+  String? description,
+  bool replaceDescription = false,
+  int? order,
   List<StorylineStep>? steps,
 }) {
   return StorylineChapter(
     id: chapter.id,
-    title: chapter.title,
-    description: chapter.description,
-    order: chapter.order,
+    title: title ?? chapter.title,
+    description:
+        replaceDescription ? description : description ?? chapter.description,
+    order: order ?? chapter.order,
     steps: steps ?? chapter.steps,
     directSceneLinkIds: chapter.directSceneLinkIds,
     status: chapter.status,
@@ -518,6 +801,49 @@ StorylineChapter _copyChapterWith(
   );
 }
 
+StorylineStep _copyStepWith(
+  StorylineStep step, {
+  String? title,
+  String? description,
+  bool replaceDescription = false,
+  int? order,
+}) {
+  return StorylineStep(
+    id: step.id,
+    title: title ?? step.title,
+    description:
+        replaceDescription ? description : description ?? step.description,
+    order: order ?? step.order,
+    entryCondition: step.entryCondition,
+    completionCondition: step.completionCondition,
+    sceneLinkIds: step.sceneLinkIds,
+    expectedOutcomeIds: step.expectedOutcomeIds,
+    status: step.status,
+    authorNotes: step.authorNotes,
+    metadata: step.metadata,
+  );
+}
+
+List<StorylineChapter> _normalizeChapterOrders(
+  List<StorylineChapter> chapters,
+) {
+  return [
+    for (var index = 0; index < chapters.length; index += 1)
+      _copyChapterWith(chapters[index], order: index),
+  ];
+}
+
+List<StorylineStep> _normalizeStepOrders(List<StorylineStep> steps) {
+  return [
+    for (var index = 0; index < steps.length; index += 1)
+      _copyStepWith(steps[index], order: index),
+  ];
+}
+
+List<StorylineStep> _orderedStepsForMutation(StorylineChapter chapter) {
+  return [...chapter.steps]..sort(_compareStepsByAuthorOrder);
+}
+
 int _storylineStepCount(StorylineAsset storyline) {
   return storyline.chapters.fold<int>(
     0,
@@ -882,7 +1208,12 @@ class _StorylinesV1MainPanel extends StatelessWidget {
     required this.onChapterSelected,
     required this.onCreateStoryline,
     required this.onCreateChapter,
+    required this.onEditChapter,
+    required this.onDeleteChapter,
     required this.onCreateStep,
+    required this.onEditStep,
+    required this.onDeleteStep,
+    required this.onReorderSteps,
     required this.onAttachSideQuest,
   });
 
@@ -898,7 +1229,12 @@ class _StorylinesV1MainPanel extends StatelessWidget {
   final ValueChanged<StorylineChapter> onChapterSelected;
   final VoidCallback? onCreateStoryline;
   final VoidCallback? onCreateChapter;
+  final ValueChanged<StorylineChapter>? onEditChapter;
+  final ValueChanged<StorylineChapter>? onDeleteChapter;
   final VoidCallback? onCreateStep;
+  final StorylineStepAction? onEditStep;
+  final StorylineStepAction? onDeleteStep;
+  final StorylineStepReorder? onReorderSteps;
   final VoidCallback? onAttachSideQuest;
 
   @override
@@ -935,7 +1271,12 @@ class _StorylinesV1MainPanel extends StatelessWidget {
                     selectedChapter: selectedChapter,
                     onChapterSelected: onChapterSelected,
                     onCreateChapter: onCreateChapter,
+                    onEditChapter: onEditChapter,
+                    onDeleteChapter: onDeleteChapter,
                     onCreateStep: onCreateStep,
+                    onEditStep: onEditStep,
+                    onDeleteStep: onDeleteStep,
+                    onReorderSteps: onReorderSteps,
                     onAttachSideQuest: onAttachSideQuest,
                   )
                 : _StorylinesV1GraphSection(
@@ -1878,6 +2219,9 @@ class _CreateStructureItemDialog extends StatefulWidget {
     required this.descriptionFieldKey,
     required this.cancelKey,
     required this.submitKey,
+    this.initialTitle,
+    this.initialDescription,
+    this.submitLabel = 'Créer',
   });
 
   final Key dialogKey;
@@ -1886,6 +2230,9 @@ class _CreateStructureItemDialog extends StatefulWidget {
   final Key descriptionFieldKey;
   final Key cancelKey;
   final Key submitKey;
+  final String? initialTitle;
+  final String? initialDescription;
+  final String submitLabel;
 
   @override
   State<_CreateStructureItemDialog> createState() =>
@@ -1897,6 +2244,13 @@ class _CreateStructureItemDialogState
   final TextEditingController _titleController = TextEditingController();
   final TextEditingController _descriptionController = TextEditingController();
 
+  @override
+  void initState() {
+    super.initState();
+    _titleController.text = widget.initialTitle ?? '';
+    _descriptionController.text = widget.initialDescription ?? '';
+  }
+
   @override
   void dispose() {
     _titleController.dispose();
@@ -1977,7 +2331,73 @@ class _CreateStructureItemDialogState
                             );
                           },
                     variant: PokeMapButtonVariant.primary,
-                    child: const Text('Créer'),
+                    child: Text(widget.submitLabel),
+                  ),
+                ],
+              ),
+            ],
+          ),
+        ),
+      ),
+    );
+  }
+}
+
+class _ConfirmStructureDeleteDialog extends StatelessWidget {
+  const _ConfirmStructureDeleteDialog({
+    required this.title,
+    required this.message,
+  });
+
+  final String title;
+  final String message;
+
+  @override
+  Widget build(BuildContext context) {
+    final colors = context.pokeMapColors;
+    return Center(
+      child: SizedBox(
+        width: 460,
+        child: PokeMapPanel(
+          key: const ValueKey('storylines-confirm-delete-dialog'),
+          padding: const EdgeInsets.all(18),
+          child: Column(
+            mainAxisSize: MainAxisSize.min,
+            crossAxisAlignment: CrossAxisAlignment.stretch,
+            children: [
+              Text(
+                title,
+                style: TextStyle(
+                  color: colors.textPrimary,
+                  fontSize: 18,
+                  fontWeight: FontWeight.w800,
+                ),
+              ),
+              const SizedBox(height: 10),
+              Text(
+                message,
+                style: TextStyle(
+                  color: colors.textSecondary,
+                  fontSize: 12.5,
+                  height: 1.35,
+                ),
+              ),
+              const SizedBox(height: 16),
+              Row(
+                mainAxisAlignment: MainAxisAlignment.end,
+                children: [
+                  PokeMapButton(
+                    key: const ValueKey('storylines-confirm-delete-cancel'),
+                    onPressed: () => Navigator.of(context).pop(false),
+                    variant: PokeMapButtonVariant.secondary,
+                    child: const Text('Annuler'),
+                  ),
+                  const SizedBox(width: 10),
+                  PokeMapButton(
+                    key: const ValueKey('storylines-confirm-delete-submit'),
+                    onPressed: () => Navigator.of(context).pop(true),
+                    variant: PokeMapButtonVariant.danger,
+                    child: const Text('Supprimer'),
                   ),
                 ],
               ),
diff --git a/packages/map_editor/test/storylines_seed_graph_usability_test.dart b/packages/map_editor/test/storylines_seed_graph_usability_test.dart
index df48897f..5fcdcaa8 100644
--- a/packages/map_editor/test/storylines_seed_graph_usability_test.dart
+++ b/packages/map_editor/test/storylines_seed_graph_usability_test.dart
@@ -277,9 +277,15 @@ void main() {
       await tester.pumpAndSettle();
       expect(find.byKey(const ValueKey('storylines-structure-view')),
           findsOneWidget);
-      expect(find.byKey(const ValueKey('storylines-selected-chapter-expanded')),
+      expect(
+          find.byKey(
+            const ValueKey('storylines-chapter-expanded-chapter_1_port'),
+          ),
           findsOneWidget);
-      expect(find.byKey(const ValueKey('storylines-collapsed-chapters')),
+      expect(
+          find.byKey(
+            const ValueKey('storylines-chapter-collapsed-chapter_2_marais'),
+          ),
           findsOneWidget);
     });
   });
diff --git a/packages/map_editor/test/storylines_structure_layout_test.dart b/packages/map_editor/test/storylines_structure_layout_test.dart
index 1a52eab1..d8333cbc 100644
--- a/packages/map_editor/test/storylines_structure_layout_test.dart
+++ b/packages/map_editor/test/storylines_structure_layout_test.dart
@@ -12,9 +12,8 @@ import 'package:map_editor/src/theme/theme.dart';
 import 'package:map_editor/src/ui/canvas/narrative_workspace_canvas.dart';
 
 void main() {
-  group('NS-STORYLINES-V1.1-00 Structure layout readability', () {
-    testWidgets(
-        'Structure shows expanded selected chapter and collapsed others',
+  group('NS-STORYLINES Structure full-width accordion authoring', () {
+    testWidgets('Structure uses a full-width vertical chapter accordion',
         (tester) async {
       final project = _loadSelbrumeProject();
 
@@ -23,21 +22,49 @@ void main() {
 
       expect(find.byKey(const ValueKey('storylines-structure-view')),
           findsOneWidget);
-      expect(find.byKey(const ValueKey('storylines-structure-action-bar')),
+      expect(find.byKey(const ValueKey('storylines-structure-toolbar')),
+          findsOneWidget);
+      expect(find.byKey(const ValueKey('storylines-structure-accordion-list')),
+          findsOneWidget);
+      expect(
+          tester
+              .getSize(
+                find.byKey(
+                  const ValueKey('storylines-structure-accordion-list'),
+                ),
+              )
+              .width,
+          greaterThan(760));
+      expect(
+          find.byKey(
+            const ValueKey('storylines-chapter-accordion-chapter_1_port'),
+          ),
+          findsOneWidget);
+      expect(
+          find.byKey(
+            const ValueKey('storylines-chapter-accordion-chapter_2_marais'),
+          ),
+          findsOneWidget);
+      expect(
+          find.byKey(
+            const ValueKey('storylines-chapter-expanded-chapter_1_port'),
+          ),
+          findsOneWidget);
+      expect(
+          find.byKey(
+            const ValueKey('storylines-chapter-collapsed-chapter_2_marais'),
+          ),
           findsOneWidget);
-      expect(find.byKey(const ValueKey('storylines-structure-chapters-zone')),
+      expect(find.byKey(const ValueKey('storylines-structure-search-action')),
           findsOneWidget);
-      expect(find.byKey(const ValueKey('storylines-selected-chapter-expanded')),
+      expect(find.byKey(const ValueKey('storylines-structure-filter-action')),
           findsOneWidget);
-      expect(find.byKey(const ValueKey('storylines-collapsed-chapters')),
+      expect(find.byKey(const ValueKey('storylines-structure-sort-action')),
           findsOneWidget);
-      expect(find.text('Détail du chapitre'), findsOneWidget);
       expect(find.text('Nouveau chapitre'), findsOneWidget);
       expect(find.text('Nouvelle étape narrative'), findsOneWidget);
       expect(find.byKey(const ValueKey('storylines-v1-structure-steps')),
           findsOneWidget);
-      expect(find.byKey(const ValueKey('storylines-v1-structure-scenes')),
-          findsOneWidget);
 
       expect(
           find.byKey(const ValueKey('storylines-step-row-step_intro_selbrume')),
@@ -48,7 +75,7 @@ void main() {
       expect(find.textContaining('Aucune scène liée'), findsWidgets);
     });
 
-    testWidgets('collapsed chapter selection changes focus without mutation',
+    testWidgets('accordion chapter selection opens another without mutation',
         (tester) async {
       final seedFile = _selbrumeProjectFile();
       final seedBefore = seedFile.readAsStringSync();
@@ -57,8 +84,15 @@ void main() {
 
       await _pumpStorylinesShell(tester, project: project);
       await _openStructureTab(tester);
+      await tester.ensureVisible(
+        find.byKey(
+          const ValueKey('storylines-chapter-toggle-chapter_2_marais'),
+        ),
+      );
       await tester.tap(
-        find.byKey(const ValueKey('storylines-chapter-row-chapter_2_marais')),
+        find.byKey(
+          const ValueKey('storylines-chapter-toggle-chapter_2_marais'),
+        ),
       );
       await tester.pumpAndSettle();
 
@@ -73,6 +107,137 @@ void main() {
       expect(seedFile.readAsStringSync(), seedBefore);
     });
 
+    testWidgets('chapter edit and delete mutate ProjectManifest.storylines',
+        (tester) async {
+      final seedFile = _selbrumeProjectFile();
+      final seedBefore = seedFile.readAsStringSync();
+      final project = _loadSelbrumeProject();
+
+      final container = await _pumpStorylinesShell(tester, project: project);
+      await _openStructureTab(tester);
+      await tester.tap(
+        find.byKey(
+          const ValueKey('storylines-edit-chapter-action-chapter_1_port'),
+        ),
+      );
+      await tester.pumpAndSettle();
+      await tester.enterText(
+        find.byKey(const ValueKey('storylines-edit-chapter-title-field')),
+        'Port révisé',
+      );
+      await tester.enterText(
+        find.byKey(
+          const ValueKey('storylines-edit-chapter-description-field'),
+        ),
+        'Chapitre ajusté depuis la vue Structure.',
+      );
+      await tester.pump();
+      await tester
+          .tap(find.byKey(const ValueKey('storylines-edit-chapter-submit')));
+      await tester.pumpAndSettle();
+
+      var updatedProject = container.read(editorNotifierProvider).project!;
+      var main = _selbrumeMain(updatedProject);
+      expect(main.chapters.first.title, 'Port révisé');
+      expect(
+        main.chapters.first.description,
+        'Chapitre ajusté depuis la vue Structure.',
+      );
+
+      await tester.ensureVisible(
+        find.byKey(
+          const ValueKey('storylines-delete-chapter-action-chapter_4_epilogue'),
+        ),
+      );
+      await tester.tap(
+        find.byKey(
+          const ValueKey('storylines-delete-chapter-action-chapter_4_epilogue'),
+        ),
+      );
+      await tester.pumpAndSettle();
+      await tester.tap(
+        find.byKey(const ValueKey('storylines-confirm-delete-submit')),
+      );
+      await tester.pumpAndSettle();
+
+      updatedProject = container.read(editorNotifierProvider).project!;
+      main = _selbrumeMain(updatedProject);
+      expect(main.chapters.map((chapter) => chapter.id),
+          isNot(contains('chapter_4_epilogue')));
+      expect(main.chapters, hasLength(3));
+      expect(seedFile.readAsStringSync(), seedBefore);
+    });
+
+    testWidgets(
+        'step edit delete and drag reorder update only selected chapter',
+        (tester) async {
+      final seedFile = _selbrumeProjectFile();
+      final seedBefore = seedFile.readAsStringSync();
+      final project = _loadSelbrumeProject();
+
+      final container = await _pumpStorylinesShell(tester, project: project);
+      await _openStructureTab(tester);
+
+      await tester.tap(
+        find.byKey(
+          const ValueKey('storylines-edit-step-action-step_intro_selbrume'),
+        ),
+      );
+      await tester.pumpAndSettle();
+      await tester.enterText(
+        find.byKey(const ValueKey('storylines-edit-step-title-field')),
+        'Introduction révisée',
+      );
+      await tester.pump();
+      await tester
+          .tap(find.byKey(const ValueKey('storylines-edit-step-submit')));
+      await tester.pumpAndSettle();
+
+      var updatedProject = container.read(editorNotifierProvider).project!;
+      var main = _selbrumeMain(updatedProject);
+      expect(main.chapters.first.steps.first.title, 'Introduction révisée');
+
+      await tester.ensureVisible(
+        find.byKey(
+          const ValueKey('storylines-step-drag-step_receive_mission'),
+        ),
+      );
+      await tester.drag(
+        find.byKey(
+          const ValueKey('storylines-step-drag-step_receive_mission'),
+        ),
+        const Offset(0, -80),
+      );
+      await tester.pumpAndSettle();
+
+      updatedProject = container.read(editorNotifierProvider).project!;
+      main = _selbrumeMain(updatedProject);
+      expect(main.chapters.first.steps.first.id, 'step_receive_mission');
+      expect(main.chapters.first.steps.first.order, 0);
+      expect(main.chapters.first.steps[1].id, 'step_intro_selbrume');
+      expect(main.chapters.first.steps[1].order, 1);
+
+      await tester.tap(
+        find.byKey(
+          const ValueKey('storylines-delete-step-action-step_go_to_port'),
+        ),
+      );
+      await tester.pumpAndSettle();
+      await tester.tap(
+        find.byKey(const ValueKey('storylines-confirm-delete-submit')),
+      );
+      await tester.pumpAndSettle();
+
+      updatedProject = container.read(editorNotifierProvider).project!;
+      main = _selbrumeMain(updatedProject);
+      expect(main.chapters.first.steps.map((step) => step.id),
+          isNot(contains('step_go_to_port')));
+      expect(main.chapters.first.steps, hasLength(3));
+      expect(main.chapters[1].steps.map((step) => step.id),
+          contains('step_enter_marais'));
+      expect(seedFile.readAsStringSync(), seedBefore);
+    });
+
     testWidgets('existing step creation flow remains wired in Structure',
         (tester) async {
       final seedFile = _selbrumeProjectFile();
@@ -135,7 +300,7 @@ void main() {
       );
     });
 
-    testWidgets('writes V1.1-00 Structure visual gate screenshots',
+    testWidgets('writes Structure accordion bis visual gate screenshots',
         (tester) async {
       final project = _loadSelbrumeProject();
 
@@ -145,15 +310,27 @@ void main() {
         find.byKey(const ValueKey('storylines-workspace-shell')),
         matchesGoldenFile(
           '../../../reports/narrativeStudio/storylines/screenshots/'
-          'ns_storylines_v1_1_00_structure_full_layout.png',
+          'ns_storylines_structure_bis_full_width_accordion.png',
+        ),
+      );
+
+      await expectLater(
+        find.byKey(
+          const ValueKey('storylines-chapter-expanded-chapter_1_port'),
+        ),
+        matchesGoldenFile(
+          '../../../reports/narrativeStudio/storylines/screenshots/'
+          'ns_storylines_structure_bis_expanded_chapter_steps.png',
         ),
       );
 
       await expectLater(
-        find.byKey(const ValueKey('storylines-selected-chapter-expanded')),
+        find.byKey(
+          const ValueKey('storylines-chapter-collapsed-chapter_2_marais'),
+        ),
         matchesGoldenFile(
           '../../../reports/narrativeStudio/storylines/screenshots/'
-          'ns_storylines_v1_1_00_structure_selected_chapter.png',
+          'ns_storylines_structure_bis_collapsed_chapter.png',
         ),
       );
 
@@ -173,10 +350,12 @@ void main() {
           .tap(find.byKey(const ValueKey('storylines-create-step-submit')));
       await tester.pumpAndSettle();
       await expectLater(
-        find.byKey(const ValueKey('storylines-selected-chapter-expanded')),
+        find.byKey(
+          const ValueKey('storylines-chapter-expanded-chapter_1_port'),
+        ),
         matchesGoldenFile(
           '../../../reports/narrativeStudio/storylines/screenshots/'
-          'ns_storylines_v1_1_00_structure_created_step.png',
+          'ns_storylines_structure_bis_authoring_actions.png',
         ),
       );
 
@@ -191,7 +370,7 @@ void main() {
         find.byKey(const ValueKey('storylines-workspace-shell')),
         matchesGoldenFile(
           '../../../reports/narrativeStudio/storylines/screenshots/'
-          'ns_storylines_v1_1_00_graph_regression.png',
+          'ns_storylines_structure_bis_graph_regression.png',
         ),
       );
     });
diff --git a/packages/map_editor/test/storylines_workspace_shell_test.dart b/packages/map_editor/test/storylines_workspace_shell_test.dart
index bc905188..84440da8 100644
--- a/packages/map_editor/test/storylines_workspace_shell_test.dart
+++ b/packages/map_editor/test/storylines_workspace_shell_test.dart
@@ -207,16 +207,12 @@ void main() {
           findsOneWidget);
       expect(find.text('Chapitres'), findsWidgets);
       expect(
-        find.descendant(
-          of: find.byKey(const ValueKey('storylines-v1-structure-steps')),
-          matching: find.text('Étapes narratives'),
-        ),
+        find.byKey(const ValueKey('storylines-structure-accordion-list')),
         findsOneWidget,
       );
       expect(
-        find.descendant(
-          of: find.byKey(const ValueKey('storylines-v1-structure-scenes')),
-          matching: find.text('Scènes liées'),
+        find.text(
+          'Créez un premier chapitre pour organiser la progression de la storyline.',
         ),
         findsOneWidget,
       );
@@ -369,14 +365,17 @@ void main() {
       expect(chapters.first.title, 'Intro');
       expect(chapters.first.description, 'Premier arc auteur.');
       expect(chapters.first.steps, isEmpty);
-      expect(find.byKey(const ValueKey('storylines-chapter-row-chapter_intro')),
+      expect(
+          find.byKey(
+            const ValueKey('storylines-chapter-accordion-chapter_intro'),
+          ),
           findsOneWidget);
       expect(
           find.byKey(
-            const ValueKey('storylines-chapter-row-chapter_intro_2'),
+            const ValueKey('storylines-chapter-accordion-chapter_intro_2'),
           ),
           findsOneWidget);
-      expect(find.text('Détail du chapitre'), findsOneWidget);
+      expect(find.text('Étapes narratives'), findsWidgets);
     });
 
     testWidgets('step action requires a selected chapter', (tester) async {
@@ -1414,7 +1413,10 @@ Future<void> _createChapter(
 
 Future<void> _openCreateStepDialog(WidgetTester tester) async {
   await _openStructureTab(tester);
-  await tester.tap(find.byKey(const ValueKey('storylines-new-step-action')));
+  final newStepAction =
+      find.byKey(const ValueKey('storylines-new-step-action'));
+  await tester.ensureVisible(newStepAction);
+  await tester.tap(newStepAction);
   await tester.pumpAndSettle();
 }
 
diff --git a/reports/narrativeStudio/storylines/road_map_storylines.md b/reports/narrativeStudio/storylines/road_map_storylines.md
index c2abe5bf..b0a5bd02 100644
--- a/reports/narrativeStudio/storylines/road_map_storylines.md
+++ b/reports/narrativeStudio/storylines/road_map_storylines.md
@@ -319,7 +319,8 @@ Interprétation V0 :
 | NS-STORYLINES-SEED-00 | Selbrume Storylines Demo Seed V0 | demo data | DONE | NS-SCENES-V1 |
 | NS-STORYLINES-SEED-FIX-01 | Selbrume Graph Layout / SideQuest Rendering Fix V0 | editor graph fix | DONE | NS-STORYLINES-SEED-FIX-01-bis |
 | NS-STORYLINES-SEED-FIX-01-bis | Graph Focus Layout / Canvas Priority | editor graph layout | DONE | NS-STORYLINES-V1.1-00 |
-| NS-STORYLINES-V1.1-00 | Structure Layout / Chapter Step Readability V0 | editor structure layout | DONE | NS-STORYLINES-V1.1-01 |
+| NS-STORYLINES-V1.1-00 | Structure Layout / Chapter Step Readability V0 | editor structure layout | DONE | NS-STORYLINES-V1.1-00-bis |
+| NS-STORYLINES-V1.1-00-bis | Structure Tab Full-width Accordion Authoring | editor structure authoring | DONE | NS-STORYLINES-V1.1-01 |
 
 ## 9. Detailed lots
 
@@ -901,7 +902,7 @@ Décision temporaire :
 
 ```text
 Roadmap status: V0 ACCEPTED WITH V1 LIMITATIONS / V1 ACCEPTED WITH LIMITATIONS
-Current lot: NS-STORYLINES-V1.1-00
+Current lot: NS-STORYLINES-V1.1-00-bis
 Current lot status: DONE
 Next recommended lot: NS-STORYLINES-V1.1-01 — Basic Edit / Delete Flow V0
 ```
@@ -941,6 +942,7 @@ Next recommended lot: NS-STORYLINES-V1.1-01 — Basic Edit / Delete Flow V0
 | NS-STORYLINES-SEED-FIX-01 | DONE | 2026-05-29 | Correction post-seed : graph plus grand, sideQuests attachées rendues comme nodes indépendants, aucun seed/model/runtime modifié. |
 | NS-STORYLINES-SEED-FIX-01-bis | DONE | 2026-05-29 | Graph Focus Layout livré : graph par défaut agrandi, KPI/header compactés en mode Graph, sideQuest nodes indépendants préservés, aucun seed ni donnée métier modifié. |
 | NS-STORYLINES-V1.1-00 | DONE | 2026-05-29 | Structure Layout livré : chapitre sélectionné expanded, autres chapitres collapsed, étapes narratives plus lisibles, création chapter/step préservée, aucun edit/delete ajouté. |
+| NS-STORYLINES-V1.1-00-bis | DONE | 2026-05-29 | Structure full-width accordion livré : liste verticale de chapitres en accordéon, toolbar locale, edit/delete chapters et steps, reorder DnD des steps, aucun seed/core/runtime modifié. |
 
 ## 14. V1 Creation Readiness Notes
 
@@ -977,6 +979,16 @@ Suite V1 documentaire recommandée :
 
 ## 15. Changelog
 
+### 2026-05-29 — NS-STORYLINES-V1.1-00-bis
+
+- Refonte de `Structure` en vue centrale pleine largeur fondée sur une liste verticale d'accordéons de chapitres ; suppression du split artificiel chapitre sélectionné / colonne des autres chapitres.
+- Toolbar locale Structure ajoutée : recherche, filtre, tri et liaison scène affichés en disabled honnête ; création `Nouveau chapitre` reste active.
+- Authoring minimal livré : création existante préservée, édition/suppression des chapitres, édition/suppression des étapes narratives et réordonnancement DnD des étapes dans le chapitre.
+- Les lignes d'étapes restent compactes, affichent `Aucune scène liée` ou le compteur réel, et ne créent aucun sceneLink ni placeholder de scène.
+- Selbrume reste data-only ; aucun seed, map_core, runtime, gameplay ou battle modifié ; Graph et sideQuest nodes indépendants préservés.
+- Captures Visual Gate dark bis produites : full layout, chapitre fermé, chapitre ouvert avec steps, actions d'authoring et régression Graph.
+- Prochain lot recommandé : `NS-STORYLINES-V1.1-01 — Basic Edit / Delete Flow V0`.
+
 ### 2026-05-29 — NS-STORYLINES-V1.1-00
 
 - Structure est réorganisée en vraie vue d'organisation : barre d'action compacte, chapitre sélectionné expanded et chapitres non sélectionnés collapsed.
```

## 12. Contenu complet des fichiers texte modifiés

### packages/map_editor/lib/src/ui/canvas/storylines/storylines_structure_view.dart

```text
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart'
    show ReorderableDragStartListener, ReorderableListView;
import 'package:map_core/map_core.dart';

import '../../../theme/theme.dart';
import '../../design_system/design_system.dart';

typedef StorylineStepAction = void Function(
  StorylineChapter chapter,
  StorylineStep step,
);

typedef StorylineStepReorder = void Function(
  StorylineChapter chapter,
  int oldIndex,
  int newIndex,
);

class StorylinesStructureView extends StatelessWidget {
  const StorylinesStructureView({
    super.key,
    required this.storyline,
    required this.selectedChapter,
    required this.onChapterSelected,
    required this.onCreateChapter,
    required this.onEditChapter,
    required this.onDeleteChapter,
    required this.onCreateStep,
    required this.onEditStep,
    required this.onDeleteStep,
    required this.onReorderSteps,
    required this.onAttachSideQuest,
  });

  final StorylineAsset? storyline;
  final StorylineChapter? selectedChapter;
  final ValueChanged<StorylineChapter> onChapterSelected;
  final VoidCallback? onCreateChapter;
  final ValueChanged<StorylineChapter>? onEditChapter;
  final ValueChanged<StorylineChapter>? onDeleteChapter;
  final VoidCallback? onCreateStep;
  final StorylineStepAction? onEditStep;
  final StorylineStepAction? onDeleteStep;
  final StorylineStepReorder? onReorderSteps;
  final VoidCallback? onAttachSideQuest;

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    final storyline = this.storyline;
    if (storyline == null) {
      return KeyedSubtree(
        key: const ValueKey('storylines-structure-read-only'),
        child: Center(
          child: Text(
            'Créez une storyline pour commencer.',
            style: TextStyle(
              color: colors.textSecondary,
              fontSize: 14,
            ),
          ),
        ),
      );
    }

    final chapters = _orderedChapters(storyline);
    final selectedChapter = _selectedChapterFrom(chapters);
    return KeyedSubtree(
      key: const ValueKey('storylines-structure-read-only'),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            key: const ValueKey('storylines-structure-view'),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _StructureToolbar(
                    storyline: storyline,
                    onCreateChapter: onCreateChapter,
                    onAttachSideQuest: onAttachSideQuest,
                  ),
                  const SizedBox(height: 12),
                  _ChapterAccordionList(
                    storyline: storyline,
                    chapters: chapters,
                    selectedChapter: selectedChapter,
                    onChapterSelected: onChapterSelected,
                    onEditChapter: onEditChapter,
                    onDeleteChapter: onDeleteChapter,
                    onCreateStep: onCreateStep,
                    onEditStep: onEditStep,
                    onDeleteStep: onDeleteStep,
                    onReorderSteps: onReorderSteps,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  StorylineChapter? _selectedChapterFrom(List<StorylineChapter> chapters) {
    final selectedChapter = this.selectedChapter;
    if (selectedChapter != null) {
      for (final chapter in chapters) {
        if (chapter.id == selectedChapter.id) {
          return chapter;
        }
      }
    }
    return chapters.isEmpty ? null : chapters.first;
  }
}

class _StructureToolbar extends StatelessWidget {
  const _StructureToolbar({
    required this.storyline,
    required this.onCreateChapter,
    required this.onAttachSideQuest,
  });

  final StorylineAsset storyline;
  final VoidCallback? onCreateChapter;
  final VoidCallback? onAttachSideQuest;

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    return PokeMapCard(
      key: const ValueKey('storylines-structure-toolbar'),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const PokeMapIconTile(
                icon: CupertinoIcons.square_stack_3d_up,
                tone: PokeMapTone.narrative,
                size: 34,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Chapitres',
                      style: TextStyle(
                        color: colors.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      storyline.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: colors.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              _StructureCompactMetric(
                value: storyline.chapters.length.toString(),
                label: 'Chapitres',
              ),
              const SizedBox(width: 8),
              _StructureCompactMetric(
                value: _storylineStepCount(storyline).toString(),
                label: 'Étapes',
              ),
              const SizedBox(width: 8),
              _StructureCompactMetric(
                value: storyline.sceneLinks.length.toString(),
                label: 'Scènes',
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              const PokeMapButton(
                key: ValueKey('storylines-structure-search-action'),
                onPressed: null,
                variant: PokeMapButtonVariant.secondary,
                size: PokeMapButtonSize.small,
                leading: Icon(CupertinoIcons.search),
                child: Text('Recherche'),
              ),
              const PokeMapButton(
                key: ValueKey('storylines-structure-filter-action'),
                onPressed: null,
                variant: PokeMapButtonVariant.secondary,
                size: PokeMapButtonSize.small,
                leading: Icon(CupertinoIcons.slider_horizontal_3),
                child: Text('Filtre'),
              ),
              const PokeMapButton(
                key: ValueKey('storylines-structure-sort-action'),
                onPressed: null,
                variant: PokeMapButtonVariant.secondary,
                size: PokeMapButtonSize.small,
                leading: Icon(CupertinoIcons.arrow_up_arrow_down),
                child: Text('Tri'),
              ),
              const PokeMapButton(
                key: ValueKey('storylines-link-scene-disabled'),
                onPressed: null,
                variant: PokeMapButtonVariant.secondary,
                size: PokeMapButtonSize.small,
                leading: Icon(CupertinoIcons.link),
                child: Text('Lier une scène'),
              ),
              if (storyline.type == StorylineType.sideQuest)
                PokeMapButton(
                  key: const ValueKey('storylines-attach-sidequest-action'),
                  onPressed: _sideQuestMainAttachment(storyline) == null
                      ? onAttachSideQuest
                      : null,
                  variant: PokeMapButtonVariant.secondary,
                  size: PokeMapButtonSize.small,
                  leading: const Icon(CupertinoIcons.link),
                  child: Text(
                    _sideQuestMainAttachment(storyline) == null
                        ? 'Attacher'
                        : 'Déjà attachée',
                  ),
                ),
              PokeMapButton(
                key: const ValueKey('storylines-new-chapter-action'),
                onPressed: onCreateChapter,
                variant: PokeMapButtonVariant.primary,
                size: PokeMapButtonSize.small,
                leading: const Icon(CupertinoIcons.add),
                child: const Text('Nouveau chapitre'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ChapterAccordionList extends StatelessWidget {
  const _ChapterAccordionList({
    required this.storyline,
    required this.chapters,
    required this.selectedChapter,
    required this.onChapterSelected,
    required this.onEditChapter,
    required this.onDeleteChapter,
    required this.onCreateStep,
    required this.onEditStep,
    required this.onDeleteStep,
    required this.onReorderSteps,
  });

  final StorylineAsset storyline;
  final List<StorylineChapter> chapters;
  final StorylineChapter? selectedChapter;
  final ValueChanged<StorylineChapter> onChapterSelected;
  final ValueChanged<StorylineChapter>? onEditChapter;
  final ValueChanged<StorylineChapter>? onDeleteChapter;
  final VoidCallback? onCreateStep;
  final StorylineStepAction? onEditStep;
  final StorylineStepAction? onDeleteStep;
  final StorylineStepReorder? onReorderSteps;

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    if (chapters.isEmpty) {
      return PokeMapCard(
        key: const ValueKey('storylines-structure-accordion-list'),
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Aucun chapitre',
              style: TextStyle(
                color: colors.textPrimary,
                fontSize: 15,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Créez un premier chapitre pour organiser la progression de la storyline.',
              style: TextStyle(
                color: colors.textSecondary,
                fontSize: 12.5,
                height: 1.4,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      key: const ValueKey('storylines-structure-accordion-list'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final chapter in chapters)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _ChapterAccordionCard(
              storyline: storyline,
              chapter: chapter,
              expanded: chapter.id == selectedChapter?.id,
              onToggle: () => onChapterSelected(chapter),
              onEditChapter:
                  onEditChapter == null ? null : () => onEditChapter!(chapter),
              onDeleteChapter: onDeleteChapter == null
                  ? null
                  : () => onDeleteChapter!(chapter),
              onCreateStep:
                  chapter.id == selectedChapter?.id ? onCreateStep : null,
              onEditStep: onEditStep,
              onDeleteStep: onDeleteStep,
              onReorderSteps: onReorderSteps,
            ),
          ),
      ],
    );
  }
}

class _ChapterAccordionCard extends StatelessWidget {
  const _ChapterAccordionCard({
    required this.storyline,
    required this.chapter,
    required this.expanded,
    required this.onToggle,
    required this.onEditChapter,
    required this.onDeleteChapter,
    required this.onCreateStep,
    required this.onEditStep,
    required this.onDeleteStep,
    required this.onReorderSteps,
  });

  final StorylineAsset storyline;
  final StorylineChapter chapter;
  final bool expanded;
  final VoidCallback onToggle;
  final VoidCallback? onEditChapter;
  final VoidCallback? onDeleteChapter;
  final VoidCallback? onCreateStep;
  final StorylineStepAction? onEditStep;
  final StorylineStepAction? onDeleteStep;
  final StorylineStepReorder? onReorderSteps;

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    return PokeMapCard(
      key: ValueKey('storylines-chapter-accordion-${chapter.id}'),
      padding: const EdgeInsets.all(14),
      selected: expanded,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          KeyedSubtree(
            key: ValueKey(
              expanded
                  ? 'storylines-chapter-expanded-${chapter.id}'
                  : 'storylines-chapter-collapsed-${chapter.id}',
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const PokeMapIconTile(
                  icon: CupertinoIcons.bookmark,
                  tone: PokeMapTone.narrative,
                  size: 34,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Chapitre ${chapter.order + 1}',
                        style: TextStyle(
                          color: colors.textMuted,
                          fontSize: 10.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        chapter.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: colors.textPrimary,
                          fontSize: expanded ? 16 : 14,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        chapter.description ?? 'Aucune description.',
                        maxLines: expanded ? 2 : 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: colors.textSecondary,
                          fontSize: 12,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                _ChapterHeaderMetrics(
                  chapter: chapter,
                  attachedSideQuestCount:
                      _attachedSideQuestCount(storyline, chapter),
                ),
                const SizedBox(width: 10),
                PokeMapButton(
                  key: ValueKey('storylines-edit-chapter-action-${chapter.id}'),
                  onPressed: onEditChapter,
                  variant: PokeMapButtonVariant.secondary,
                  size: PokeMapButtonSize.small,
                  leading: const Icon(CupertinoIcons.pencil),
                  child: const Text('Modifier'),
                ),
                const SizedBox(width: 8),
                PokeMapButton(
                  key: ValueKey(
                    'storylines-delete-chapter-action-${chapter.id}',
                  ),
                  onPressed: onDeleteChapter,
                  variant: PokeMapButtonVariant.danger,
                  size: PokeMapButtonSize.small,
                  leading: const Icon(CupertinoIcons.trash),
                  child: const Text('Supprimer'),
                ),
                const SizedBox(width: 8),
                PokeMapButton(
                  key: ValueKey('storylines-chapter-toggle-${chapter.id}'),
                  onPressed: onToggle,
                  variant: PokeMapButtonVariant.ghost,
                  size: PokeMapButtonSize.small,
                  leading: Icon(
                    expanded
                        ? CupertinoIcons.chevron_up
                        : CupertinoIcons.chevron_down,
                  ),
                  child: Text(expanded ? 'Ouvert' : 'Ouvrir'),
                ),
              ],
            ),
          ),
          if (expanded) ...[
            const SizedBox(height: 14),
            _ExpandedChapterBody(
              chapter: chapter,
              onCreateStep: onCreateStep,
              onEditStep: onEditStep,
              onDeleteStep: onDeleteStep,
              onReorderSteps: onReorderSteps,
            ),
          ],
        ],
      ),
    );
  }
}

class _ChapterHeaderMetrics extends StatelessWidget {
  const _ChapterHeaderMetrics({
    required this.chapter,
    required this.attachedSideQuestCount,
  });

  final StorylineChapter chapter;
  final int attachedSideQuestCount;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      alignment: WrapAlignment.end,
      children: [
        _StructureBadge(
          label: _formatCount(chapter.steps.length, 'étape', 'étapes'),
        ),
        _StructureBadge(
          label: _formatCount(
            _chapterSceneLinkCount(chapter),
            'scène liée',
            'scènes liées',
          ),
        ),
        if (attachedSideQuestCount > 0)
          _StructureBadge(
            label: _formatCount(
              attachedSideQuestCount,
              'quête disponible',
              'quêtes disponibles',
            ),
          ),
      ],
    );
  }
}

class _ExpandedChapterBody extends StatelessWidget {
  const _ExpandedChapterBody({
    required this.chapter,
    required this.onCreateStep,
    required this.onEditStep,
    required this.onDeleteStep,
    required this.onReorderSteps,
  });

  final StorylineChapter chapter;
  final VoidCallback? onCreateStep;
  final StorylineStepAction? onEditStep;
  final StorylineStepAction? onDeleteStep;
  final StorylineStepReorder? onReorderSteps;

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    final steps = _orderedSteps(chapter);
    return Column(
      key: const ValueKey('storylines-v1-structure-steps'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Étapes narratives',
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            PokeMapButton(
              key: const ValueKey('storylines-new-step-action'),
              onPressed: onCreateStep,
              variant: PokeMapButtonVariant.secondary,
              size: PokeMapButtonSize.small,
              leading: const Icon(CupertinoIcons.add),
              child: const Text('Nouvelle étape narrative'),
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (steps.isEmpty)
          PokeMapCard(
            padding: const EdgeInsets.all(12),
            child: Text(
              'Aucune étape narrative. Ajoutez une première étape pour définir la progression du chapitre.',
              style: TextStyle(
                color: colors.textSecondary,
                fontSize: 12,
                height: 1.35,
              ),
            ),
          )
        else
          ReorderableListView.builder(
            key: ValueKey('storylines-steps-reorder-list-${chapter.id}'),
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            buildDefaultDragHandles: false,
            onReorderItem: (oldIndex, newIndex) {
              onReorderSteps?.call(chapter, oldIndex, newIndex);
            },
            itemCount: steps.length,
            itemBuilder: (context, index) {
              final step = steps[index];
              return Padding(
                key: ValueKey('storylines-step-row-wrapper-${step.id}'),
                padding: const EdgeInsets.only(bottom: 8),
                child: _StructureStepRow(
                  chapter: chapter,
                  step: step,
                  index: index,
                  onEditStep: onEditStep,
                  onDeleteStep: onDeleteStep,
                ),
              );
            },
          ),
        const SizedBox(height: 8),
        const _SceneLinkNotice(),
      ],
    );
  }
}

class _StructureStepRow extends StatelessWidget {
  const _StructureStepRow({
    required this.chapter,
    required this.step,
    required this.index,
    required this.onEditStep,
    required this.onDeleteStep,
  });

  final StorylineChapter chapter;
  final StorylineStep step;
  final int index;
  final StorylineStepAction? onEditStep;
  final StorylineStepAction? onDeleteStep;

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    final sceneLinkCount = step.sceneLinkIds.length;
    return PokeMapCard(
      key: ValueKey('storylines-step-row-${step.id}'),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ReorderableDragStartListener(
            key: ValueKey('storylines-step-drag-${step.id}'),
            index: index,
            child: Padding(
              padding: const EdgeInsets.only(top: 3),
              child: Icon(
                CupertinoIcons.line_horizontal_3,
                color: colors.textMuted,
                size: 18,
              ),
            ),
          ),
          const SizedBox(width: 10),
          _StructureBadge(label: 'Étape ${step.order + 1}'),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  step.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  step.description ?? 'Aucune description.',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: colors.textSecondary,
                    fontSize: 11.5,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          _StructureBadge(
            label: sceneLinkCount == 0
                ? 'Aucune scène liée'
                : _formatCount(
                    sceneLinkCount,
                    'scène liée',
                    'scènes liées',
                  ),
          ),
          const SizedBox(width: 8),
          PokeMapButton(
            key: ValueKey('storylines-edit-step-action-${step.id}'),
            onPressed:
                onEditStep == null ? null : () => onEditStep!(chapter, step),
            variant: PokeMapButtonVariant.secondary,
            size: PokeMapButtonSize.small,
            leading: const Icon(CupertinoIcons.pencil),
            child: const Text('Éditer'),
          ),
          const SizedBox(width: 8),
          PokeMapButton(
            key: ValueKey('storylines-delete-step-action-${step.id}'),
            onPressed: onDeleteStep == null
                ? null
                : () => onDeleteStep!(chapter, step),
            variant: PokeMapButtonVariant.danger,
            size: PokeMapButtonSize.small,
            leading: const Icon(CupertinoIcons.trash),
            child: const Text('Retirer'),
          ),
        ],
      ),
    );
  }
}

class _SceneLinkNotice extends StatelessWidget {
  const _SceneLinkNotice();

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    return PokeMapCard(
      key: const ValueKey('storylines-v1-structure-scenes'),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          const PokeMapIconTile(
            icon: CupertinoIcons.link,
            tone: PokeMapTone.neutral,
            size: 28,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Liaison de scène à venir : aucune scène placeholder ni sceneLink n’est créé depuis cette vue.',
              style: TextStyle(
                color: colors.textSecondary,
                fontSize: 11.5,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StructureCompactMetric extends StatelessWidget {
  const _StructureCompactMetric({
    required this.value,
    required this.label,
  });

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    return PokeMapCard(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: TextStyle(
              color: colors.textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              color: colors.textMuted,
              fontSize: 9.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _StructureBadge extends StatelessWidget {
  const _StructureBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    return PokeMapCard(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      child: Text(
        label,
        style: TextStyle(
          color: colors.textSecondary,
          fontSize: 10.5,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

List<StorylineChapter> _orderedChapters(StorylineAsset storyline) {
  return [...storyline.chapters]..sort((a, b) {
      final order = a.order.compareTo(b.order);
      if (order != 0) return order;
      final title = a.title.compareTo(b.title);
      if (title != 0) return title;
      return a.id.compareTo(b.id);
    });
}

List<StorylineStep> _orderedSteps(StorylineChapter chapter) {
  return [...chapter.steps]..sort((a, b) {
      final order = a.order.compareTo(b.order);
      if (order != 0) return order;
      final title = a.title.compareTo(b.title);
      if (title != 0) return title;
      return a.id.compareTo(b.id);
    });
}

int _storylineStepCount(StorylineAsset storyline) {
  return storyline.chapters.fold<int>(
    0,
    (total, chapter) => total + chapter.steps.length,
  );
}

int _chapterSceneLinkCount(StorylineChapter chapter) {
  return chapter.directSceneLinkIds.length +
      chapter.steps.fold<int>(
        0,
        (total, step) => total + step.sceneLinkIds.length,
      );
}

int _attachedSideQuestCount(
  StorylineAsset storyline,
  StorylineChapter chapter,
) {
  if (storyline.type != StorylineType.main) {
    return 0;
  }
  final chapterStepIds = chapter.steps.map((step) => step.id).toSet();
  var count = 0;
  for (final relationship in storyline.relationships) {
    if (relationship.kind !=
        StorylineRelationshipKind.sideQuestAvailableDuring) {
      continue;
    }
    final anchor =
        relationship.anchor ?? relationship.availability?.startAnchor;
    if (anchor == null) continue;
    if (anchor.kind == StorylineAnchorKind.chapter &&
        anchor.targetId == chapter.id) {
      count += 1;
    }
    if (anchor.kind == StorylineAnchorKind.step &&
        chapterStepIds.contains(anchor.targetId)) {
      count += 1;
    }
  }
  return count;
}

String _formatCount(int count, String singular, String plural) {
  return '$count ${count == 1 ? singular : plural}';
}

StorylineRelationship? _sideQuestMainAttachment(StorylineAsset storyline) {
  if (storyline.type != StorylineType.sideQuest) {
    return null;
  }
  for (final relationship in storyline.relationships) {
    if (relationship.kind ==
            StorylineRelationshipKind.sideQuestAvailableDuring ||
        relationship.kind == StorylineRelationshipKind.sideQuestUnlockedBy) {
      return relationship;
    }
  }
  return null;
}

```

### packages/map_editor/lib/src/ui/canvas/storylines_workspace.dart

```text
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:map_core/map_core.dart';

import '../../features/editor/state/editor_notifier.dart';
import '../../features/narrative/application/narrative_workspace_projection.dart';
import '../../theme/theme.dart';
import '../design_system/design_system.dart';
import 'storylines/storylines_graph_view.dart';
import 'storylines/storylines_structure_view.dart';

class StorylinesWorkspace extends ConsumerStatefulWidget {
  const StorylinesWorkspace({
    super.key,
    required this.projection,
    required this.selectedGlobalStoryId,
  });

  final NarrativeWorkspaceProjection projection;
  final String? selectedGlobalStoryId;

  @override
  ConsumerState<StorylinesWorkspace> createState() =>
      _StorylinesWorkspaceState();
}

class _StorylinesWorkspaceState extends ConsumerState<StorylinesWorkspace> {
  _StorylineContentTab _selectedTab = _StorylineContentTab.graph;
  String? _selectedStorylineId;
  String? _selectedChapterId;

  @override
  Widget build(BuildContext context) {
    final editorState = ref.watch(editorNotifierProvider);
    final project = editorState.project;
    final storylines = project?.storylines ?? const <StorylineAsset>[];
    final selectedStoryline = _selectedStoryline(storylines);
    final selectedChapter = _selectedChapter(selectedStoryline);
    final legacyGlobalStory = widget.projection.globalStories.isEmpty
        ? null
        : widget.projection.globalStories.first;
    final legacyStep =
        widget.projection.steps.isEmpty ? null : widget.projection.steps.first;
    final legacyStepCount = widget.projection.steps.length;

    return PokeMapPageSurface(
      key: const ValueKey('storylines-workspace-shell'),
      padding: const EdgeInsets.all(12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 240,
            child: _StorylinesV1SecondaryPanel(
              storylines: storylines,
              selectedStorylineId: selectedStoryline?.id,
              legacyGlobalStory: legacyGlobalStory,
              onStorylineSelected: _selectStoryline,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _StorylinesV1MainPanel(
              selectedStoryline: selectedStoryline,
              selectedChapter: selectedChapter,
              storylines: storylines,
              selectedTab: _selectedTab,
              legacyGlobalStory: legacyGlobalStory,
              legacyStep: legacyStep,
              legacyStepCount: legacyStepCount,
              canCreateStoryline: project != null,
              onTabSelected: _selectTab,
              onChapterSelected: _selectChapter,
              onCreateStoryline: project == null
                  ? null
                  : () => _openCreateStorylineDialog(project),
              onCreateChapter: project == null || selectedStoryline == null
                  ? null
                  : () => _openCreateChapterDialog(project, selectedStoryline),
              onEditChapter: project == null || selectedStoryline == null
                  ? null
                  : (chapter) => _openEditChapterDialog(
                        project,
                        selectedStoryline,
                        chapter,
                      ),
              onDeleteChapter: project == null || selectedStoryline == null
                  ? null
                  : (chapter) => _deleteChapter(
                        project,
                        selectedStoryline,
                        chapter,
                      ),
              onCreateStep: project == null ||
                      selectedStoryline == null ||
                      selectedChapter == null
                  ? null
                  : () => _openCreateStepDialog(
                        project,
                        selectedStoryline,
                        selectedChapter,
                      ),
              onEditStep: project == null || selectedStoryline == null
                  ? null
                  : (chapter, step) => _openEditStepDialog(
                        project,
                        selectedStoryline,
                        chapter,
                        step,
                      ),
              onDeleteStep: project == null || selectedStoryline == null
                  ? null
                  : (chapter, step) => _deleteStep(
                        project,
                        selectedStoryline,
                        chapter,
                        step,
                      ),
              onReorderSteps: project == null || selectedStoryline == null
                  ? null
                  : (chapter, oldIndex, newIndex) => _reorderSteps(
                        project,
                        selectedStoryline,
                        chapter,
                        oldIndex,
                        newIndex,
                      ),
              onAttachSideQuest: project == null ||
                      selectedStoryline == null ||
                      selectedStoryline.type != StorylineType.sideQuest
                  ? null
                  : () => _openAttachSideQuestDialog(
                        project,
                        selectedStoryline,
                      ),
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 280,
            child: _StorylinesV1InspectorPanel(
              selectedStoryline: selectedStoryline,
              selectedChapter: _selectedTab == _StorylineContentTab.structure
                  ? selectedChapter
                  : null,
            ),
          ),
        ],
      ),
    );
  }

  StorylineAsset? _selectedStoryline(List<StorylineAsset> storylines) {
    final targetId = _selectedStorylineId;
    if (targetId != null) {
      for (final storyline in storylines) {
        if (storyline.id == targetId) {
          return storyline;
        }
      }
    }
    return storylines.isEmpty ? null : storylines.first;
  }

  StorylineChapter? _selectedChapter(StorylineAsset? storyline) {
    if (storyline == null || storyline.chapters.isEmpty) {
      return null;
    }
    final targetId = _selectedChapterId;
    if (targetId != null) {
      for (final chapter in storyline.chapters) {
        if (chapter.id == targetId) {
          return chapter;
        }
      }
    }
    return storyline.chapters.first;
  }

  void _selectStoryline(StorylineAsset storyline) {
    if (_selectedStorylineId == storyline.id) {
      return;
    }
    setState(() {
      _selectedStorylineId = storyline.id;
      _selectedChapterId =
          storyline.chapters.isEmpty ? null : storyline.chapters.first.id;
    });
  }

  void _selectChapter(StorylineChapter chapter) {
    if (_selectedChapterId == chapter.id) {
      return;
    }
    setState(() {
      _selectedChapterId = chapter.id;
    });
  }

  void _selectTab(_StorylineContentTab tab) {
    if (_selectedTab == tab) {
      return;
    }
    setState(() {
      _selectedTab = tab;
    });
  }

  Future<void> _openCreateStorylineDialog(ProjectManifest project) async {
    final draft = await showCupertinoDialog<_CreateStorylineDraft>(
      context: context,
      builder: (context) => _CreateStorylineDialog(
        storylines: project.storylines,
      ),
    );
    if (draft == null || !mounted) {
      return;
    }
    final storyline = StorylineAsset(
      id: _generateStorylineId(draft.title, draft.type, project.storylines),
      type: draft.type,
      status: StorylineStatus.draft,
      title: draft.title,
      description: draft.description,
    );
    final updated = project.copyWith(
      storylines: [...project.storylines, storyline],
    );
    ref.read(editorNotifierProvider.notifier).applyInMemoryProjectManifest(
          updated,
          statusMessage: draft.type == StorylineType.sideQuest
              ? 'Quête annexe créée'
              : 'Storyline principale créée',
        );
    setState(() {
      _selectedStorylineId = storyline.id;
      _selectedChapterId = null;
      _selectedTab = draft.type == StorylineType.sideQuest
          ? _StorylineContentTab.structure
          : _StorylineContentTab.graph;
    });
  }

  Future<void> _openCreateChapterDialog(
    ProjectManifest project,
    StorylineAsset storyline,
  ) async {
    final draft = await showCupertinoDialog<_StructureItemDraft>(
      context: context,
      builder: (context) => const _CreateStructureItemDialog(
        dialogKey: ValueKey('storylines-create-chapter-dialog'),
        title: 'Nouveau chapitre',
        titleFieldKey: ValueKey('storylines-create-chapter-title-field'),
        descriptionFieldKey: ValueKey(
          'storylines-create-chapter-description-field',
        ),
        cancelKey: ValueKey('storylines-create-chapter-cancel'),
        submitKey: ValueKey('storylines-create-chapter-submit'),
      ),
    );
    if (draft == null || !mounted) {
      return;
    }
    final chapter = StorylineChapter(
      id: _generateScopedId(
        prefix: 'chapter',
        title: draft.title,
        existingIds: storyline.chapters.map((chapter) => chapter.id).toSet(),
      ),
      title: draft.title,
      description: draft.description,
      order: _nextChapterOrder(storyline),
    );
    final updatedStoryline = _copyStorylineWith(
      storyline,
      chapters: [...storyline.chapters, chapter],
    );
    _applyStorylineUpdate(
      project,
      updatedStoryline,
      statusMessage: 'Chapitre créé',
    );
    setState(() {
      _selectedStorylineId = storyline.id;
      _selectedChapterId = chapter.id;
      _selectedTab = _StorylineContentTab.structure;
    });
  }

  Future<void> _openCreateStepDialog(
    ProjectManifest project,
    StorylineAsset storyline,
    StorylineChapter chapter,
  ) async {
    final draft = await showCupertinoDialog<_StructureItemDraft>(
      context: context,
      builder: (context) => const _CreateStructureItemDialog(
        dialogKey: ValueKey('storylines-create-step-dialog'),
        title: 'Nouvelle étape narrative',
        titleFieldKey: ValueKey('storylines-create-step-title-field'),
        descriptionFieldKey: ValueKey(
          'storylines-create-step-description-field',
        ),
        cancelKey: ValueKey('storylines-create-step-cancel'),
        submitKey: ValueKey('storylines-create-step-submit'),
      ),
    );
    if (draft == null || !mounted) {
      return;
    }
    final step = StorylineStep(
      id: _generateScopedId(
        prefix: 'step',
        title: draft.title,
        existingIds: _storylineStepIds(storyline),
      ),
      title: draft.title,
      description: draft.description,
      order: _nextStepOrder(chapter),
    );
    final updatedChapter = _copyChapterWith(
      chapter,
      steps: [...chapter.steps, step],
    );
    final updatedStoryline = _copyStorylineWith(
      storyline,
      chapters: storyline.chapters
          .map(
            (current) => current.id == chapter.id ? updatedChapter : current,
          )
          .toList(growable: false),
    );
    _applyStorylineUpdate(
      project,
      updatedStoryline,
      statusMessage: 'Étape narrative créée',
    );
    setState(() {
      _selectedStorylineId = storyline.id;
      _selectedChapterId = chapter.id;
      _selectedTab = _StorylineContentTab.structure;
    });
  }

  Future<void> _openEditChapterDialog(
    ProjectManifest project,
    StorylineAsset storyline,
    StorylineChapter chapter,
  ) async {
    final draft = await showCupertinoDialog<_StructureItemDraft>(
      context: context,
      builder: (context) => _CreateStructureItemDialog(
        dialogKey: const ValueKey('storylines-edit-chapter-dialog'),
        title: 'Modifier le chapitre',
        titleFieldKey: const ValueKey('storylines-edit-chapter-title-field'),
        descriptionFieldKey: const ValueKey(
          'storylines-edit-chapter-description-field',
        ),
        cancelKey: const ValueKey('storylines-edit-chapter-cancel'),
        submitKey: const ValueKey('storylines-edit-chapter-submit'),
        initialTitle: chapter.title,
        initialDescription: chapter.description,
        submitLabel: 'Enregistrer',
      ),
    );
    if (draft == null || !mounted) {
      return;
    }
    final updatedChapter = _copyChapterWith(
      chapter,
      title: draft.title,
      description: draft.description,
      replaceDescription: true,
    );
    final updatedStoryline = _copyStorylineWith(
      storyline,
      chapters: storyline.chapters
          .map(
            (current) => current.id == chapter.id ? updatedChapter : current,
          )
          .toList(growable: false),
    );
    _applyStorylineUpdate(
      project,
      updatedStoryline,
      statusMessage: 'Chapitre modifié',
    );
    setState(() {
      _selectedStorylineId = storyline.id;
      _selectedChapterId = chapter.id;
      _selectedTab = _StorylineContentTab.structure;
    });
  }

  Future<void> _deleteChapter(
    ProjectManifest project,
    StorylineAsset storyline,
    StorylineChapter chapter,
  ) async {
    final confirmed = await showCupertinoDialog<bool>(
      context: context,
      builder: (context) => _ConfirmStructureDeleteDialog(
        title: 'Supprimer le chapitre',
        message:
            'Le chapitre "${chapter.title}" et ses étapes narratives seront retirés de cette storyline.',
      ),
    );
    if (confirmed != true || !mounted) {
      return;
    }
    final removedIndex =
        storyline.chapters.indexWhere((current) => current.id == chapter.id);
    final remaining = storyline.chapters
        .where((current) => current.id != chapter.id)
        .toList(growable: false);
    final normalized = _normalizeChapterOrders(remaining);
    final updatedStoryline = _copyStorylineWith(
      storyline,
      chapters: normalized,
    );
    _applyStorylineUpdate(
      project,
      updatedStoryline,
      statusMessage: 'Chapitre supprimé',
    );
    setState(() {
      _selectedStorylineId = storyline.id;
      if (normalized.isEmpty) {
        _selectedChapterId = null;
      } else {
        final nextIndex = removedIndex >= normalized.length
            ? normalized.length - 1
            : removedIndex;
        _selectedChapterId = normalized[nextIndex].id;
      }
      _selectedTab = _StorylineContentTab.structure;
    });
  }

  Future<void> _openEditStepDialog(
    ProjectManifest project,
    StorylineAsset storyline,
    StorylineChapter chapter,
    StorylineStep step,
  ) async {
    final draft = await showCupertinoDialog<_StructureItemDraft>(
      context: context,
      builder: (context) => _CreateStructureItemDialog(
        dialogKey: const ValueKey('storylines-edit-step-dialog'),
        title: 'Modifier l’étape narrative',
        titleFieldKey: const ValueKey('storylines-edit-step-title-field'),
        descriptionFieldKey: const ValueKey(
          'storylines-edit-step-description-field',
        ),
        cancelKey: const ValueKey('storylines-edit-step-cancel'),
        submitKey: const ValueKey('storylines-edit-step-submit'),
        initialTitle: step.title,
        initialDescription: step.description,
        submitLabel: 'Enregistrer',
      ),
    );
    if (draft == null || !mounted) {
      return;
    }
    final updatedStep = _copyStepWith(
      step,
      title: draft.title,
      description: draft.description,
      replaceDescription: true,
    );
    final updatedChapter = _copyChapterWith(
      chapter,
      steps: chapter.steps
          .map((current) => current.id == step.id ? updatedStep : current)
          .toList(growable: false),
    );
    final updatedStoryline = _copyStorylineWith(
      storyline,
      chapters: storyline.chapters
          .map(
            (current) => current.id == chapter.id ? updatedChapter : current,
          )
          .toList(growable: false),
    );
    _applyStorylineUpdate(
      project,
      updatedStoryline,
      statusMessage: 'Étape narrative modifiée',
    );
    setState(() {
      _selectedStorylineId = storyline.id;
      _selectedChapterId = chapter.id;
      _selectedTab = _StorylineContentTab.structure;
    });
  }

  Future<void> _deleteStep(
    ProjectManifest project,
    StorylineAsset storyline,
    StorylineChapter chapter,
    StorylineStep step,
  ) async {
    final confirmed = await showCupertinoDialog<bool>(
      context: context,
      builder: (context) => _ConfirmStructureDeleteDialog(
        title: 'Supprimer l’étape narrative',
        message:
            'L’étape "${step.title}" sera retirée de ce chapitre sans créer ni supprimer de scène.',
      ),
    );
    if (confirmed != true || !mounted) {
      return;
    }
    final updatedSteps = _normalizeStepOrders(
      chapter.steps
          .where((current) => current.id != step.id)
          .toList(growable: false),
    );
    final updatedChapter = _copyChapterWith(chapter, steps: updatedSteps);
    final updatedStoryline = _copyStorylineWith(
      storyline,
      chapters: storyline.chapters
          .map(
            (current) => current.id == chapter.id ? updatedChapter : current,
          )
          .toList(growable: false),
    );
    _applyStorylineUpdate(
      project,
      updatedStoryline,
      statusMessage: 'Étape narrative supprimée',
    );
    setState(() {
      _selectedStorylineId = storyline.id;
      _selectedChapterId = chapter.id;
      _selectedTab = _StorylineContentTab.structure;
    });
  }

  void _reorderSteps(
    ProjectManifest project,
    StorylineAsset storyline,
    StorylineChapter chapter,
    int oldIndex,
    int newIndex,
  ) {
    final steps = _orderedStepsForMutation(chapter);
    if (oldIndex < 0 || oldIndex >= steps.length) {
      return;
    }
    var targetIndex = newIndex;
    if (targetIndex < 0) {
      targetIndex = 0;
    }
    if (targetIndex >= steps.length) {
      targetIndex = steps.length - 1;
    }
    final moved = steps.removeAt(oldIndex);
    steps.insert(targetIndex, moved);
    final updatedChapter = _copyChapterWith(
      chapter,
      steps: _normalizeStepOrders(steps),
    );
    final updatedStoryline = _copyStorylineWith(
      storyline,
      chapters: storyline.chapters
          .map(
            (current) => current.id == chapter.id ? updatedChapter : current,
          )
          .toList(growable: false),
    );
    _applyStorylineUpdate(
      project,
      updatedStoryline,
      statusMessage: 'Étapes narratives réordonnées',
    );
    setState(() {
      _selectedStorylineId = storyline.id;
      _selectedChapterId = chapter.id;
      _selectedTab = _StorylineContentTab.structure;
    });
  }

  Future<void> _openAttachSideQuestDialog(
    ProjectManifest project,
    StorylineAsset sideQuest,
  ) async {
    if (_sideQuestMainAttachment(sideQuest) != null) {
      return;
    }
    final draft = await showCupertinoDialog<_SideQuestAttachmentDraft>(
      context: context,
      builder: (context) => _AttachSideQuestDialog(
        sideQuest: sideQuest,
        storylines: project.storylines,
      ),
    );
    if (draft == null || !mounted) {
      return;
    }
    final anchor = StorylineAnchor(
      kind: draft.anchor.kind,
      targetId: draft.anchor.targetId,
    );
    final relationship = StorylineRelationship(
      id: _generateRelationshipId(
        sideQuest,
        draft.mainStoryline,
        anchor,
      ),
      kind: StorylineRelationshipKind.sideQuestAvailableDuring,
      sourceStorylineId: sideQuest.id,
      targetStorylineId: draft.mainStoryline.id,
      anchor: anchor,
      availability: SideQuestAvailability(startAnchor: anchor),
      notes: 'Side quest available from ${draft.anchor.label}.',
    );
    final updatedSideQuest = _copyStorylineWith(
      sideQuest,
      relationships: [...sideQuest.relationships, relationship],
    );
    _applyStorylineUpdate(
      project,
      updatedSideQuest,
      statusMessage: 'Quête annexe attachée',
    );
    setState(() {
      _selectedStorylineId = sideQuest.id;
      _selectedChapterId =
          sideQuest.chapters.isEmpty ? null : sideQuest.chapters.first.id;
      _selectedTab = _StorylineContentTab.graph;
    });
  }

  String _generateStorylineId(
    String title,
    StorylineType type,
    List<StorylineAsset> storylines,
  ) {
    final existingIds = storylines.map((storyline) => storyline.id).toSet();
    return _generateScopedId(
      prefix: type == StorylineType.sideQuest ? 'sidequest' : 'storyline',
      title: title,
      existingIds: existingIds,
      fallback: type == StorylineType.sideQuest ? 'sidequest' : 'main',
    );
  }

  String _generateRelationshipId(
    StorylineAsset sideQuest,
    StorylineAsset mainStoryline,
    StorylineAnchor anchor,
  ) {
    final existingIds =
        sideQuest.relationships.map((relationship) => relationship.id).toSet();
    return _generateScopedId(
      prefix: 'sidequest_attach',
      title: '${sideQuest.id}_${mainStoryline.id}_${anchor.targetId}',
      existingIds: existingIds,
      fallback: 'main',
    );
  }

  String _generateScopedId({
    required String prefix,
    required String title,
    required Set<String> existingIds,
    String fallback = 'item',
  }) {
    final slug = _slugifyStorylineTitle(title);
    final base = '${prefix}_${slug.isEmpty ? fallback : slug}';
    if (!existingIds.contains(base)) {
      return base;
    }
    var suffix = 2;
    while (existingIds.contains('${base}_$suffix')) {
      suffix += 1;
    }
    return '${base}_$suffix';
  }

  Set<String> _storylineStepIds(StorylineAsset storyline) {
    return {
      for (final chapter in storyline.chapters)
        for (final step in chapter.steps) step.id,
    };
  }

  int _nextChapterOrder(StorylineAsset storyline) {
    var nextOrder = 0;
    for (final chapter in storyline.chapters) {
      if (chapter.order >= nextOrder) {
        nextOrder = chapter.order + 1;
      }
    }
    return nextOrder;
  }

  int _nextStepOrder(StorylineChapter chapter) {
    var nextOrder = 0;
    for (final step in chapter.steps) {
      if (step.order >= nextOrder) {
        nextOrder = step.order + 1;
      }
    }
    return nextOrder;
  }

  void _applyStorylineUpdate(
    ProjectManifest project,
    StorylineAsset updatedStoryline, {
    required String statusMessage,
  }) {
    final updated = project.copyWith(
      storylines: project.storylines
          .map(
            (storyline) => storyline.id == updatedStoryline.id
                ? updatedStoryline
                : storyline,
          )
          .toList(growable: false),
    );
    ref.read(editorNotifierProvider.notifier).applyInMemoryProjectManifest(
          updated,
          statusMessage: statusMessage,
        );
  }

  String _slugifyStorylineTitle(String title) {
    final normalized = title.trim().toLowerCase();
    final buffer = StringBuffer();
    var lastWasSeparator = false;
    for (final rune in normalized.runes) {
      final char = String.fromCharCode(rune);
      final replacement = switch (char) {
        'à' || 'á' || 'â' || 'ä' || 'ã' || 'å' => 'a',
        'ç' => 'c',
        'è' || 'é' || 'ê' || 'ë' => 'e',
        'ì' || 'í' || 'î' || 'ï' => 'i',
        'ñ' => 'n',
        'ò' || 'ó' || 'ô' || 'ö' || 'õ' => 'o',
        'ù' || 'ú' || 'û' || 'ü' => 'u',
        'ý' || 'ÿ' => 'y',
        _ => char,
      };
      final isAlphaNumeric = RegExp(r'[a-z0-9]').hasMatch(replacement);
      if (isAlphaNumeric) {
        buffer.write(replacement);
        lastWasSeparator = false;
      } else if (!lastWasSeparator && buffer.isNotEmpty) {
        buffer.write('_');
        lastWasSeparator = true;
      }
    }
    return buffer.toString().replaceAll(RegExp(r'_+$'), '');
  }
}

StorylineAsset _copyStorylineWith(
  StorylineAsset storyline, {
  List<StorylineChapter>? chapters,
  List<StorylineRelationship>? relationships,
}) {
  return StorylineAsset(
    id: storyline.id,
    schemaVersion: storyline.schemaVersion,
    type: storyline.type,
    status: storyline.status,
    title: storyline.title,
    description: storyline.description,
    sortOrder: storyline.sortOrder,
    locale: storyline.locale,
    chapters: chapters ?? storyline.chapters,
    sceneLinks: storyline.sceneLinks,
    relationships: relationships ?? storyline.relationships,
    legacySource: storyline.legacySource,
    authorNotes: storyline.authorNotes,
    metadata: storyline.metadata,
  );
}

StorylineChapter _copyChapterWith(
  StorylineChapter chapter, {
  String? title,
  String? description,
  bool replaceDescription = false,
  int? order,
  List<StorylineStep>? steps,
}) {
  return StorylineChapter(
    id: chapter.id,
    title: title ?? chapter.title,
    description:
        replaceDescription ? description : description ?? chapter.description,
    order: order ?? chapter.order,
    steps: steps ?? chapter.steps,
    directSceneLinkIds: chapter.directSceneLinkIds,
    status: chapter.status,
    authorNotes: chapter.authorNotes,
    metadata: chapter.metadata,
  );
}

StorylineStep _copyStepWith(
  StorylineStep step, {
  String? title,
  String? description,
  bool replaceDescription = false,
  int? order,
}) {
  return StorylineStep(
    id: step.id,
    title: title ?? step.title,
    description:
        replaceDescription ? description : description ?? step.description,
    order: order ?? step.order,
    entryCondition: step.entryCondition,
    completionCondition: step.completionCondition,
    sceneLinkIds: step.sceneLinkIds,
    expectedOutcomeIds: step.expectedOutcomeIds,
    status: step.status,
    authorNotes: step.authorNotes,
    metadata: step.metadata,
  );
}

List<StorylineChapter> _normalizeChapterOrders(
  List<StorylineChapter> chapters,
) {
  return [
    for (var index = 0; index < chapters.length; index += 1)
      _copyChapterWith(chapters[index], order: index),
  ];
}

List<StorylineStep> _normalizeStepOrders(List<StorylineStep> steps) {
  return [
    for (var index = 0; index < steps.length; index += 1)
      _copyStepWith(steps[index], order: index),
  ];
}

List<StorylineStep> _orderedStepsForMutation(StorylineChapter chapter) {
  return [...chapter.steps]..sort(_compareStepsByAuthorOrder);
}

int _storylineStepCount(StorylineAsset storyline) {
  return storyline.chapters.fold<int>(
    0,
    (total, chapter) => total + chapter.steps.length,
  );
}

int _chapterSceneLinkCount(StorylineChapter chapter) {
  return chapter.directSceneLinkIds.length +
      chapter.steps.fold<int>(
        0,
        (total, step) => total + step.sceneLinkIds.length,
      );
}

String _formatCount(int count, String singular, String plural) {
  return '$count ${count == 1 ? singular : plural}';
}

StorylineRelationship? _sideQuestMainAttachment(StorylineAsset storyline) {
  if (storyline.type != StorylineType.sideQuest) {
    return null;
  }
  for (final relationship in storyline.relationships) {
    if (relationship.kind ==
            StorylineRelationshipKind.sideQuestAvailableDuring ||
        relationship.kind == StorylineRelationshipKind.sideQuestUnlockedBy) {
      return relationship;
    }
  }
  return null;
}

String _sideQuestAttachmentStatus(StorylineAsset storyline) {
  return _sideQuestMainAttachment(storyline) == null
      ? 'Non reliée au graph principal'
      : 'Reliée au graph principal';
}

List<_SideQuestAnchorChoice> _anchorChoicesFor(StorylineAsset mainStoryline) {
  final chapters = [...mainStoryline.chapters]
    ..sort(_compareChaptersByAuthorOrder);
  return [
    for (final chapter in chapters) ...[
      _SideQuestAnchorChoice(
        kind: StorylineAnchorKind.chapter,
        targetId: chapter.id,
        label: 'Chapitre · ${chapter.title}',
        description: 'Disponible au début de ce chapitre.',
      ),
      for (final step in ([...chapter.steps]..sort(_compareStepsByAuthorOrder)))
        _SideQuestAnchorChoice(
          kind: StorylineAnchorKind.step,
          targetId: step.id,
          label: 'Étape · ${step.title}',
          description: 'Disponible à cette étape narrative.',
        ),
    ],
  ];
}

String _anchorKey(_SideQuestAnchorChoice anchor) {
  return '${anchor.kind.name}-${anchor.targetId}';
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

class _StorylinesV1SecondaryPanel extends StatelessWidget {
  const _StorylinesV1SecondaryPanel({
    required this.storylines,
    required this.selectedStorylineId,
    required this.legacyGlobalStory,
    required this.onStorylineSelected,
  });

  final List<StorylineAsset> storylines;
  final String? selectedStorylineId;
  final NarrativeScenarioSummary? legacyGlobalStory;
  final ValueChanged<StorylineAsset> onStorylineSelected;

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    final mainStorylines = storylines
        .where((storyline) => storyline.type == StorylineType.main)
        .toList(growable: false);
    final sideQuests = storylines
        .where((storyline) => storyline.type == StorylineType.sideQuest)
        .toList(growable: false);
    return PokeMapPanel(
      key: const ValueKey('storylines-secondary-panel'),
      expandChild: true,
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _StorylinesSectionLabel(
            label: 'STORYLINES',
            color: colors.textMuted,
          ),
          const SizedBox(height: 12),
          if (storylines.isEmpty)
            const _StorylinesV1EmptyList()
          else ...[
            _StorylinesSectionLabel(
              label: 'HISTOIRE PRINCIPALE',
              color: colors.textMuted,
            ),
            const SizedBox(height: 8),
            if (mainStorylines.isEmpty)
              const _StorylinesV1CompactEmpty(
                title: 'Aucune histoire principale',
                body:
                    'Créez une histoire principale depuis Nouvelle storyline.',
              )
            else
              ...mainStorylines.map(
                (storyline) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _StorylinesV1Row(
                    storyline: storyline,
                    selected: storyline.id == selectedStorylineId,
                    onTap: () => onStorylineSelected(storyline),
                  ),
                ),
              ),
            const SizedBox(height: 8),
            _StorylinesSectionLabel(
              label: 'QUÊTES ANNEXES',
              color: colors.textMuted,
            ),
            const SizedBox(height: 8),
            if (sideQuests.isEmpty)
              const _StorylinesV1CompactEmpty(
                title: 'Aucune quête annexe',
                body: 'Créez une quête annexe depuis Nouvelle storyline.',
              )
            else
              ...sideQuests.map(
                (storyline) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _StorylinesV1Row(
                    storyline: storyline,
                    selected: storyline.id == selectedStorylineId,
                    onTap: () => onStorylineSelected(storyline),
                  ),
                ),
              ),
          ],
          const Spacer(),
          if (storylines.isEmpty && legacyGlobalStory != null)
            PokeMapCard(
              key: const ValueKey('storylines-legacy-global-story-note'),
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Ancienne Global Story détectée',
                    style: TextStyle(
                      color: colors.textPrimary,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    legacyGlobalStory!.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: colors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Import manuel à venir.',
                    style: TextStyle(
                      color: colors.textMuted,
                      fontSize: 11,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _StorylinesV1EmptyList extends StatelessWidget {
  const _StorylinesV1EmptyList();

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    return PokeMapCard(
      key: const ValueKey('storylines-v1-secondary-empty'),
      padding: const EdgeInsets.all(12),
      child: Text(
        'Aucune storyline auteur',
        style: TextStyle(
          color: colors.textSecondary,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _StorylinesV1CompactEmpty extends StatelessWidget {
  const _StorylinesV1CompactEmpty({
    required this.title,
    required this.body,
  });

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    return PokeMapCard(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: colors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            body,
            style: TextStyle(
              color: colors.textMuted,
              fontSize: 11,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }
}

class _StorylinesV1Row extends StatelessWidget {
  const _StorylinesV1Row({
    required this.storyline,
    required this.selected,
    required this.onTap,
  });

  final StorylineAsset storyline;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    return KeyedSubtree(
      key: ValueKey('storylines-v1-row-${storyline.id}'),
      child: PokeMapCard(
        padding: const EdgeInsets.all(12),
        selected: selected,
        onTap: onTap,
        child: Row(
          children: [
            const PokeMapIconTile(
              icon: CupertinoIcons.book,
              tone: PokeMapTone.narrative,
              size: 34,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    storyline.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: colors.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _storylineTypeLabel(storyline.type),
                    style: TextStyle(
                      color: colors.textSecondary,
                      fontSize: 11,
                    ),
                  ),
                  if (storyline.type == StorylineType.sideQuest) ...[
                    const SizedBox(height: 3),
                    Text(
                      _sideQuestAttachmentStatus(storyline),
                      style: TextStyle(
                        color: colors.textMuted,
                        fontSize: 11,
                      ),
                    ),
                  ],
                  if (storyline.chapters.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(
                      "${_formatCount(storyline.chapters.length, 'chapitre', 'chapitres')} · ${_formatCount(_storylineStepCount(storyline), 'étape', 'étapes')}",
                      style: TextStyle(
                        color: colors.textSecondary,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StorylinesV1MainPanel extends StatelessWidget {
  const _StorylinesV1MainPanel({
    required this.selectedStoryline,
    required this.selectedChapter,
    required this.storylines,
    required this.selectedTab,
    required this.legacyGlobalStory,
    required this.legacyStep,
    required this.legacyStepCount,
    required this.canCreateStoryline,
    required this.onTabSelected,
    required this.onChapterSelected,
    required this.onCreateStoryline,
    required this.onCreateChapter,
    required this.onEditChapter,
    required this.onDeleteChapter,
    required this.onCreateStep,
    required this.onEditStep,
    required this.onDeleteStep,
    required this.onReorderSteps,
    required this.onAttachSideQuest,
  });

  final StorylineAsset? selectedStoryline;
  final StorylineChapter? selectedChapter;
  final List<StorylineAsset> storylines;
  final _StorylineContentTab selectedTab;
  final NarrativeScenarioSummary? legacyGlobalStory;
  final NarrativeStepSummary? legacyStep;
  final int legacyStepCount;
  final bool canCreateStoryline;
  final ValueChanged<_StorylineContentTab> onTabSelected;
  final ValueChanged<StorylineChapter> onChapterSelected;
  final VoidCallback? onCreateStoryline;
  final VoidCallback? onCreateChapter;
  final ValueChanged<StorylineChapter>? onEditChapter;
  final ValueChanged<StorylineChapter>? onDeleteChapter;
  final VoidCallback? onCreateStep;
  final StorylineStepAction? onEditStep;
  final StorylineStepAction? onDeleteStep;
  final StorylineStepReorder? onReorderSteps;
  final VoidCallback? onAttachSideQuest;

  @override
  Widget build(BuildContext context) {
    final graphMode = selectedTab == _StorylineContentTab.graph;
    return PokeMapPanel(
      key: const ValueKey('storylines-main-panel'),
      expandChild: true,
      padding: EdgeInsets.all(graphMode ? 10 : 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _StorylinesV1Header(
            selectedStoryline: selectedStoryline,
            canCreateStoryline: canCreateStoryline,
            onCreateStoryline: onCreateStoryline,
            compact: graphMode,
          ),
          SizedBox(height: graphMode ? 8 : 12),
          _StorylineTabsRow(
            selectedTab: selectedTab,
            onTabSelected: onTabSelected,
          ),
          SizedBox(height: graphMode ? 6 : 12),
          _StorylinesV1KpiStrip(
            storylines: storylines,
            compact: graphMode,
          ),
          SizedBox(height: graphMode ? 6 : 16),
          Expanded(
            child: selectedTab == _StorylineContentTab.structure
                ? StorylinesStructureView(
                    storyline: selectedStoryline,
                    selectedChapter: selectedChapter,
                    onChapterSelected: onChapterSelected,
                    onCreateChapter: onCreateChapter,
                    onEditChapter: onEditChapter,
                    onDeleteChapter: onDeleteChapter,
                    onCreateStep: onCreateStep,
                    onEditStep: onEditStep,
                    onDeleteStep: onDeleteStep,
                    onReorderSteps: onReorderSteps,
                    onAttachSideQuest: onAttachSideQuest,
                  )
                : _StorylinesV1GraphSection(
                    storyline: selectedStoryline,
                    storylines: storylines,
                    legacyGlobalStory: legacyGlobalStory,
                    legacyStep: legacyStep,
                    legacyStepCount: legacyStepCount,
                  ),
          ),
        ],
      ),
    );
  }
}

class _StorylinesV1Header extends StatelessWidget {
  const _StorylinesV1Header({
    required this.selectedStoryline,
    required this.canCreateStoryline,
    required this.onCreateStoryline,
    required this.compact,
  });

  final StorylineAsset? selectedStoryline;
  final bool canCreateStoryline;
  final VoidCallback? onCreateStoryline;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    final title = selectedStoryline?.title ?? 'Storylines';
    if (compact) {
      return KeyedSubtree(
        key: const ValueKey('storylines-header-section'),
        child: Row(
          key: const ValueKey('storylines-header-section-compact'),
          children: [
            Expanded(
              child: Wrap(
                spacing: 8,
                runSpacing: 6,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: colors.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  if (selectedStoryline != null) ...[
                    _StorylinesV1Badge(
                      label: _storylineTypeLabel(selectedStoryline!.type),
                    ),
                    const _StorylinesV1Badge(label: 'Brouillon'),
                    if (selectedStoryline!.type == StorylineType.sideQuest)
                      _StorylinesV1Badge(
                        label: _sideQuestAttachmentStatus(selectedStoryline!),
                      ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 12),
            PokeMapButton(
              key: const ValueKey('storylines-create-main-cta'),
              onPressed: canCreateStoryline ? onCreateStoryline : null,
              variant: PokeMapButtonVariant.primary,
              leading: const Icon(CupertinoIcons.plus, size: 16),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Nouvelle'),
                  Text(' storyline'),
                ],
              ),
            ),
          ],
        ),
      );
    }
    return KeyedSubtree(
      key: const ValueKey('storylines-header-section'),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                if (selectedStoryline != null) ...[
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      _StorylinesV1Badge(
                        label: _storylineTypeLabel(selectedStoryline!.type),
                      ),
                      const _StorylinesV1Badge(label: 'Brouillon'),
                      if (selectedStoryline!.type == StorylineType.sideQuest)
                        _StorylinesV1Badge(
                          label: _sideQuestAttachmentStatus(
                            selectedStoryline!,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                ],
                Text(
                  selectedStoryline == null
                      ? 'Créez une histoire principale pour commencer à structurer votre jeu.'
                      : selectedStoryline!.description ??
                          (selectedStoryline!.type == StorylineType.sideQuest
                              ? 'Quête annexe prête à structurer.'
                              : 'Storyline principale prête à structurer.'),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: colors.textSecondary,
                    fontSize: 13,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          PokeMapButton(
            key: const ValueKey('storylines-create-main-cta'),
            onPressed: canCreateStoryline ? onCreateStoryline : null,
            variant: PokeMapButtonVariant.primary,
            leading: const Icon(CupertinoIcons.plus, size: 16),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Nouvelle'),
                Text(' storyline'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StorylinesV1KpiStrip extends StatelessWidget {
  const _StorylinesV1KpiStrip({
    required this.storylines,
    required this.compact,
  });

  final List<StorylineAsset> storylines;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    final chapterCount = storylines.fold<int>(
      0,
      (total, storyline) => total + storyline.chapters.length,
    );
    final stepCount = storylines.fold<int>(
      0,
      (total, storyline) =>
          total +
          storyline.chapters.fold<int>(
            0,
            (chapterTotal, chapter) => chapterTotal + chapter.steps.length,
          ),
    );
    final sceneLinkCount = storylines.fold<int>(
      0,
      (total, storyline) => total + storyline.sceneLinks.length,
    );
    if (compact) {
      return KeyedSubtree(
        key: const ValueKey('storylines-kpi-strip'),
        child: SizedBox(
          key: const ValueKey('storylines-kpi-strip-compact'),
          height: 34,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: colors.controlSurface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: colors.borderSubtle),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              child: Row(
                children: [
                  Expanded(
                    child: _StorylinesV1CompactKpi(
                      label: 'Storylines',
                      value: storylines.length.toString(),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _StorylinesV1CompactKpi(
                      label: 'Chapters',
                      value: chapterCount.toString(),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _StorylinesV1CompactKpi(
                      label: 'Story Steps',
                      value: stepCount.toString(),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _StorylinesV1CompactKpi(
                      label: 'Scene Links',
                      value: sceneLinkCount.toString(),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }
    return KeyedSubtree(
      key: const ValueKey('storylines-kpi-strip'),
      child: SizedBox(
        height: 128,
        child: Row(
          children: [
            Expanded(
              child: PokeMapMetricCard(
                title: 'Storylines',
                value: storylines.length.toString(),
                icon: CupertinoIcons.book,
                tone: PokeMapTone.narrative,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: PokeMapMetricCard(
                title: 'Chapters',
                value: chapterCount.toString(),
                icon: CupertinoIcons.square_list,
                tone: PokeMapTone.neutral,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: PokeMapMetricCard(
                title: 'Story Steps',
                value: stepCount.toString(),
                icon: CupertinoIcons.list_bullet,
                tone: PokeMapTone.neutral,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: PokeMapMetricCard(
                title: 'Scene Links',
                value: sceneLinkCount.toString(),
                icon: CupertinoIcons.link,
                tone: PokeMapTone.neutral,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StorylinesV1CompactKpi extends StatelessWidget {
  const _StorylinesV1CompactKpi({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: TextStyle(
            color: colors.textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(width: 5),
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: colors.textSecondary,
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

class _StorylinesV1GraphSection extends StatelessWidget {
  const _StorylinesV1GraphSection({
    required this.storyline,
    required this.storylines,
    required this.legacyGlobalStory,
    required this.legacyStep,
    required this.legacyStepCount,
  });

  final StorylineAsset? storyline;
  final List<StorylineAsset> storylines;
  final NarrativeScenarioSummary? legacyGlobalStory;
  final NarrativeStepSummary? legacyStep;
  final int legacyStepCount;

  @override
  Widget build(BuildContext context) {
    final selectedStoryline = storyline;
    if (selectedStoryline == null) {
      return PokeMapCard(
        key: const ValueKey('storylines-graph-target-read-only'),
        padding: const EdgeInsets.all(18),
        child: _StorylinesV1NoStorylineState(
          legacyGlobalStory: legacyGlobalStory,
          legacyStep: legacyStep,
          legacyStepCount: legacyStepCount,
        ),
      );
    }
    final sideQuestCountOutsideSelected =
        selectedStoryline.type == StorylineType.main
            ? storylines
                .where((storyline) => storyline.type == StorylineType.sideQuest)
                .length
            : 0;
    return StorylinesGraphView(
      storyline: selectedStoryline,
      storylines: storylines,
      sideQuestCountOutsideSelected: sideQuestCountOutsideSelected,
    );
  }
}

class _StorylinesV1NoStorylineState extends StatelessWidget {
  const _StorylinesV1NoStorylineState({
    required this.legacyGlobalStory,
    required this.legacyStep,
    required this.legacyStepCount,
  });

  final NarrativeScenarioSummary? legacyGlobalStory;
  final NarrativeStepSummary? legacyStep;
  final int legacyStepCount;

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const PokeMapIconTile(
              icon: CupertinoIcons.book,
              tone: PokeMapTone.narrative,
              size: 48,
            ),
            const SizedBox(height: 14),
            Text(
              'Aucune storyline auteur',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: colors.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Créez une histoire principale pour commencer à structurer votre jeu.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: colors.textSecondary,
                fontSize: 13,
                height: 1.35,
              ),
            ),
            if (legacyGlobalStory != null) ...[
              const SizedBox(height: 12),
              Text(
                'Une ancienne Global Story peut exister dans les scénarios legacy. Elle ne sera pas importée automatiquement.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: colors.textMuted,
                  fontSize: 12,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 12),
              PokeMapCard(
                key: const ValueKey('storylines-v1-legacy-preview-card'),
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Mode lecture seule',
                      style: TextStyle(
                        color: colors.textMuted,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      legacyGlobalStory!.name,
                      style: TextStyle(
                        color: colors.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    if (legacyGlobalStory!.description.trim().isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        legacyGlobalStory!.description,
                        style: TextStyle(
                          color: colors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                    const SizedBox(height: 8),
                    Text(
                      'Graph read-only',
                      style: TextStyle(
                        color: colors.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (legacyStep != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        legacyStep!.name,
                        style: TextStyle(
                          color: colors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                    const SizedBox(height: 6),
                    Text(
                      legacyStepCount.toString(),
                      style: TextStyle(
                        color: colors.textMuted,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _StorylinesV1Badge extends StatelessWidget {
  const _StorylinesV1Badge({required this.label});

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

class _StorylinesV1InspectorPanel extends StatelessWidget {
  const _StorylinesV1InspectorPanel({
    required this.selectedStoryline,
    required this.selectedChapter,
  });

  final StorylineAsset? selectedStoryline;
  final StorylineChapter? selectedChapter;

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    final chapter = selectedChapter;
    return PokeMapPanel(
      key: const ValueKey('storylines-inspector-read-only'),
      expandChild: true,
      padding: const EdgeInsets.all(14),
      child: selectedStoryline == null
          ? Center(
              child: Text(
                'Aucune storyline sélectionnée.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: colors.textSecondary,
                  fontSize: 13,
                ),
              ),
            )
          : chapter != null
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'DÉTAILS DU CHAPITRE',
                      style: TextStyle(
                        color: colors.textMuted,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      chapter.title,
                      style: TextStyle(
                        color: colors.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      chapter.description ?? 'Aucune description.',
                      style: TextStyle(
                        color: colors.textSecondary,
                        fontSize: 12,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _StorylineInspectorTextLine(
                      label: 'Storyline',
                      value: selectedStoryline!.title,
                    ),
                    _StorylineInspectorTextLine(
                      label: 'Ordre',
                      value: chapter.order.toString(),
                    ),
                    _StorylineInspectorTextLine(
                      label: 'Étapes',
                      value: chapter.steps.length.toString(),
                    ),
                    _StorylineInspectorTextLine(
                      label: 'Scene links',
                      value: _chapterSceneLinkCount(chapter).toString(),
                    ),
                    const _StorylineInspectorTextLine(
                      label: 'Scènes liées',
                      value: 'À venir',
                    ),
                  ],
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'DÉTAILS STORYLINE',
                      style: TextStyle(
                        color: colors.textMuted,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      selectedStoryline!.title,
                      style: TextStyle(
                        color: colors.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      selectedStoryline!.description ?? 'Aucune description.',
                      style: TextStyle(
                        color: colors.textSecondary,
                        fontSize: 12,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _StorylineInspectorTextLine(
                      label: 'Type',
                      value: _storylineTypeLabel(selectedStoryline!.type),
                    ),
                    const _StorylineInspectorTextLine(
                      label: 'Statut',
                      value: 'Draft',
                    ),
                    _StorylineInspectorTextLine(
                      label: 'Chapitres',
                      value: selectedStoryline!.chapters.length.toString(),
                    ),
                    _StorylineInspectorTextLine(
                      label: 'Étapes',
                      value: _storylineStepCount(selectedStoryline!).toString(),
                    ),
                    _StorylineInspectorTextLine(
                      label: 'Scene links',
                      value: selectedStoryline!.sceneLinks.length.toString(),
                    ),
                    if (selectedStoryline!.type == StorylineType.sideQuest)
                      _StorylineInspectorTextLine(
                        label: 'Relation principale',
                        value:
                            _sideQuestMainAttachment(selectedStoryline!) == null
                                ? 'Non reliée'
                                : 'Reliée',
                      ),
                  ],
                ),
    );
  }
}

class _CreateStorylineDraft {
  const _CreateStorylineDraft({
    required this.type,
    required this.title,
    required this.description,
  });

  final StorylineType type;
  final String title;
  final String? description;
}

class _StructureItemDraft {
  const _StructureItemDraft({
    required this.title,
    required this.description,
  });

  final String title;
  final String? description;
}

class _SideQuestAttachmentDraft {
  const _SideQuestAttachmentDraft({
    required this.mainStoryline,
    required this.anchor,
  });

  final StorylineAsset mainStoryline;
  final _SideQuestAnchorChoice anchor;
}

class _SideQuestAnchorChoice {
  const _SideQuestAnchorChoice({
    required this.kind,
    required this.targetId,
    required this.label,
    required this.description,
  });

  final StorylineAnchorKind kind;
  final String targetId;
  final String label;
  final String description;
}

class _AttachSideQuestDialog extends StatefulWidget {
  const _AttachSideQuestDialog({
    required this.sideQuest,
    required this.storylines,
  });

  final StorylineAsset sideQuest;
  final List<StorylineAsset> storylines;

  @override
  State<_AttachSideQuestDialog> createState() => _AttachSideQuestDialogState();
}

class _AttachSideQuestDialogState extends State<_AttachSideQuestDialog> {
  String? _selectedMainId;
  String? _selectedAnchorId;

  @override
  void initState() {
    super.initState();
    final mainStorylines = _mainStorylines;
    if (mainStorylines.isNotEmpty) {
      _selectedMainId = mainStorylines.first.id;
      final anchors = _anchorChoicesFor(mainStorylines.first);
      if (anchors.isNotEmpty) {
        _selectedAnchorId = _anchorKey(anchors.first);
      }
    }
  }

  List<StorylineAsset> get _mainStorylines {
    return widget.storylines
        .where((storyline) => storyline.type == StorylineType.main)
        .toList(growable: false);
  }

  StorylineAsset? get _selectedMainStoryline {
    for (final storyline in _mainStorylines) {
      if (storyline.id == _selectedMainId) {
        return storyline;
      }
    }
    return _mainStorylines.isEmpty ? null : _mainStorylines.first;
  }

  _SideQuestAnchorChoice? get _selectedAnchor {
    final mainStoryline = _selectedMainStoryline;
    if (mainStoryline == null) return null;
    final anchors = _anchorChoicesFor(mainStoryline);
    for (final anchor in anchors) {
      if (_anchorKey(anchor) == _selectedAnchorId) {
        return anchor;
      }
    }
    return anchors.isEmpty ? null : anchors.first;
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    final mainStorylines = _mainStorylines;
    final mainStoryline = _selectedMainStoryline;
    final anchors = mainStoryline == null
        ? const <_SideQuestAnchorChoice>[]
        : _anchorChoicesFor(mainStoryline);
    final selectedAnchor = _selectedAnchor;
    final canSubmit = mainStoryline != null && selectedAnchor != null;
    return Center(
      child: SizedBox(
        width: 560,
        child: PokeMapPanel(
          key: const ValueKey('storylines-attach-sidequest-dialog'),
          padding: const EdgeInsets.all(18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Attacher la quête annexe',
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                widget.sideQuest.title,
                style: TextStyle(
                  color: colors.textSecondary,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'Histoire principale cible',
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              if (mainStorylines.isEmpty)
                Text(
                  'Créez d’abord une histoire principale.',
                  style: TextStyle(color: colors.textSecondary, fontSize: 12),
                )
              else
                ...mainStorylines.map(
                  (storyline) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _StorylineTypeChoice(
                      key: ValueKey('storylines-attach-main-${storyline.id}'),
                      label: storyline.title,
                      description: _formatCount(
                        storyline.chapters.length,
                        'chapitre disponible',
                        'chapitres disponibles',
                      ),
                      selected: storyline.id == mainStoryline?.id,
                      enabled: true,
                      disabledReason: null,
                      onTap: () => setState(() {
                        _selectedMainId = storyline.id;
                        final nextAnchors = _anchorChoicesFor(storyline);
                        _selectedAnchorId = nextAnchors.isEmpty
                            ? null
                            : _anchorKey(nextAnchors.first);
                      }),
                    ),
                  ),
                ),
              const SizedBox(height: 10),
              Text(
                'Point d’ancrage',
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              if (anchors.isEmpty)
                Text(
                  'Créez un chapitre ou une étape dans l’histoire principale avant d’attacher une quête annexe.',
                  style: TextStyle(
                    color: colors.textSecondary,
                    fontSize: 12,
                    height: 1.35,
                  ),
                )
              else
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 260),
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        for (final anchor in anchors)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: _StorylineTypeChoice(
                              key: ValueKey(
                                'storylines-attach-anchor-${_anchorKey(anchor)}',
                              ),
                              label: anchor.label,
                              description: anchor.description,
                              selected: _anchorKey(anchor) == _selectedAnchorId,
                              enabled: true,
                              disabledReason: null,
                              onTap: () => setState(() {
                                _selectedAnchorId = _anchorKey(anchor);
                              }),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  PokeMapButton(
                    key: const ValueKey('storylines-attach-cancel'),
                    onPressed: () => Navigator.of(context).pop(),
                    variant: PokeMapButtonVariant.secondary,
                    child: const Text('Annuler'),
                  ),
                  const SizedBox(width: 10),
                  PokeMapButton(
                    key: const ValueKey('storylines-attach-submit'),
                    onPressed: canSubmit
                        ? () => Navigator.of(context).pop(
                              _SideQuestAttachmentDraft(
                                mainStoryline: mainStoryline,
                                anchor: selectedAnchor,
                              ),
                            )
                        : null,
                    variant: PokeMapButtonVariant.primary,
                    child: const Text('Attacher'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CreateStructureItemDialog extends StatefulWidget {
  const _CreateStructureItemDialog({
    required this.dialogKey,
    required this.title,
    required this.titleFieldKey,
    required this.descriptionFieldKey,
    required this.cancelKey,
    required this.submitKey,
    this.initialTitle,
    this.initialDescription,
    this.submitLabel = 'Créer',
  });

  final Key dialogKey;
  final String title;
  final Key titleFieldKey;
  final Key descriptionFieldKey;
  final Key cancelKey;
  final Key submitKey;
  final String? initialTitle;
  final String? initialDescription;
  final String submitLabel;

  @override
  State<_CreateStructureItemDialog> createState() =>
      _CreateStructureItemDialogState();
}

class _CreateStructureItemDialogState
    extends State<_CreateStructureItemDialog> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _titleController.text = widget.initialTitle ?? '';
    _descriptionController.text = widget.initialDescription ?? '';
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    final title = _titleController.text.trim();
    return Center(
      child: SizedBox(
        width: 460,
        child: PokeMapPanel(
          key: widget.dialogKey,
          padding: const EdgeInsets.all(18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                widget.title,
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 14),
              _StorylinesV1TextField(
                key: widget.titleFieldKey,
                controller: _titleController,
                placeholder: 'Titre',
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 10),
              _StorylinesV1TextField(
                key: widget.descriptionFieldKey,
                controller: _descriptionController,
                placeholder: 'Description optionnelle',
                maxLines: 3,
              ),
              if (title.isEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  'Titre obligatoire.',
                  style: TextStyle(
                    color: colors.warning,
                    fontSize: 12,
                  ),
                ),
              ],
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  PokeMapButton(
                    key: widget.cancelKey,
                    onPressed: () => Navigator.of(context).pop(),
                    variant: PokeMapButtonVariant.secondary,
                    child: const Text('Annuler'),
                  ),
                  const SizedBox(width: 10),
                  PokeMapButton(
                    key: widget.submitKey,
                    onPressed: title.isEmpty
                        ? null
                        : () {
                            final description =
                                _descriptionController.text.trim();
                            Navigator.of(context).pop(
                              _StructureItemDraft(
                                title: title,
                                description:
                                    description.isEmpty ? null : description,
                              ),
                            );
                          },
                    variant: PokeMapButtonVariant.primary,
                    child: Text(widget.submitLabel),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ConfirmStructureDeleteDialog extends StatelessWidget {
  const _ConfirmStructureDeleteDialog({
    required this.title,
    required this.message,
  });

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    return Center(
      child: SizedBox(
        width: 460,
        child: PokeMapPanel(
          key: const ValueKey('storylines-confirm-delete-dialog'),
          padding: const EdgeInsets.all(18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                message,
                style: TextStyle(
                  color: colors.textSecondary,
                  fontSize: 12.5,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  PokeMapButton(
                    key: const ValueKey('storylines-confirm-delete-cancel'),
                    onPressed: () => Navigator.of(context).pop(false),
                    variant: PokeMapButtonVariant.secondary,
                    child: const Text('Annuler'),
                  ),
                  const SizedBox(width: 10),
                  PokeMapButton(
                    key: const ValueKey('storylines-confirm-delete-submit'),
                    onPressed: () => Navigator.of(context).pop(true),
                    variant: PokeMapButtonVariant.danger,
                    child: const Text('Supprimer'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CreateStorylineDialog extends StatefulWidget {
  const _CreateStorylineDialog({required this.storylines});

  final List<StorylineAsset> storylines;

  @override
  State<_CreateStorylineDialog> createState() => _CreateStorylineDialogState();
}

class _CreateStorylineDialogState extends State<_CreateStorylineDialog> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  late StorylineType _selectedType;

  bool get _hasMainStoryline => widget.storylines
      .any((storyline) => storyline.type == StorylineType.main);

  bool get _canCreateMain => !_hasMainStoryline;

  bool get _canCreateSideQuest => _hasMainStoryline;

  bool get _canCreateSelectedType {
    return switch (_selectedType) {
      StorylineType.main => _canCreateMain,
      StorylineType.sideQuest => _canCreateSideQuest,
      _ => false,
    };
  }

  @override
  void initState() {
    super.initState();
    _selectedType =
        _hasMainStoryline ? StorylineType.sideQuest : StorylineType.main;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    final title = _titleController.text.trim();
    final canSubmit = title.isNotEmpty && _canCreateSelectedType;
    return Center(
      child: SizedBox(
        width: 520,
        child: PokeMapPanel(
          key: const ValueKey('storylines-create-main-dialog'),
          padding: const EdgeInsets.all(18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Nouvelle storyline',
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 14),
              _StorylineTypeChoice(
                key: const ValueKey('storylines-create-type-main'),
                label: 'Histoire principale',
                description: 'Structure principale du jeu.',
                selected: _selectedType == StorylineType.main,
                enabled: _canCreateMain,
                disabledReason: _hasMainStoryline
                    ? 'Une histoire principale existe déjà.'
                    : null,
                onTap: () => setState(() {
                  _selectedType = StorylineType.main;
                }),
              ),
              const SizedBox(height: 8),
              _StorylineTypeChoice(
                key: const ValueKey('storylines-create-type-sidequest'),
                label: 'Quête annexe',
                description: 'Histoire secondaire optionnelle.',
                selected: _selectedType == StorylineType.sideQuest,
                enabled: _canCreateSideQuest,
                disabledReason: _canCreateSideQuest
                    ? null
                    : 'Créez d’abord une histoire principale pour organiser les quêtes annexes.',
                onTap: () => setState(() {
                  _selectedType = StorylineType.sideQuest;
                }),
              ),
              const SizedBox(height: 14),
              _StorylinesV1TextField(
                key: const ValueKey('storylines-create-title-field'),
                controller: _titleController,
                placeholder: 'Titre',
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 10),
              _StorylinesV1TextField(
                key: const ValueKey('storylines-create-description-field'),
                controller: _descriptionController,
                placeholder: 'Description optionnelle',
                maxLines: 3,
              ),
              if (title.isEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  'Titre obligatoire.',
                  style: TextStyle(
                    color: colors.warning,
                    fontSize: 12,
                  ),
                ),
              ],
              if (!_canCreateSelectedType) ...[
                const SizedBox(height: 8),
                Text(
                  _selectedType == StorylineType.sideQuest
                      ? 'Créez d’abord une histoire principale.'
                      : 'Une histoire principale existe déjà.',
                  style: TextStyle(
                    color: colors.textMuted,
                    fontSize: 12,
                  ),
                ),
              ],
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  PokeMapButton(
                    key: const ValueKey('storylines-create-cancel'),
                    onPressed: () => Navigator.of(context).pop(),
                    variant: PokeMapButtonVariant.secondary,
                    child: const Text('Annuler'),
                  ),
                  const SizedBox(width: 10),
                  PokeMapButton(
                    key: const ValueKey('storylines-create-submit'),
                    onPressed: !canSubmit
                        ? null
                        : () {
                            final description =
                                _descriptionController.text.trim();
                            Navigator.of(context).pop(
                              _CreateStorylineDraft(
                                type: _selectedType,
                                title: title,
                                description:
                                    description.isEmpty ? null : description,
                              ),
                            );
                          },
                    variant: PokeMapButtonVariant.primary,
                    child: const Text('Créer'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StorylineTypeChoice extends StatelessWidget {
  const _StorylineTypeChoice({
    super.key,
    required this.label,
    required this.description,
    required this.selected,
    required this.enabled,
    required this.disabledReason,
    required this.onTap,
  });

  final String label;
  final String description;
  final bool selected;
  final bool enabled;
  final String? disabledReason;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    return PokeMapCard(
      selected: selected,
      padding: const EdgeInsets.all(12),
      onTap: enabled ? onTap : null,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: enabled ? colors.textPrimary : colors.textMuted,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    color: enabled ? colors.textSecondary : colors.textMuted,
                    fontSize: 12,
                  ),
                ),
                if (!enabled && disabledReason != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    disabledReason!,
                    style: TextStyle(
                      color: colors.textMuted,
                      fontSize: 11,
                      height: 1.3,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 10),
          if (selected)
            const _StorylinesV1Badge(label: 'Sélectionné')
          else if (!enabled)
            const _StorylinesV1Badge(label: 'Indisponible'),
        ],
      ),
    );
  }
}

class _StorylinesV1TextField extends StatelessWidget {
  const _StorylinesV1TextField({
    super.key,
    required this.controller,
    required this.placeholder,
    this.maxLines = 1,
    this.onChanged,
  });

  final TextEditingController controller;
  final String placeholder;
  final int maxLines;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    return CupertinoTextField(
      controller: controller,
      maxLines: maxLines,
      onChanged: onChanged,
      placeholder: placeholder,
      style: TextStyle(color: colors.textPrimary, fontSize: 13),
      placeholderStyle: TextStyle(color: colors.textMuted, fontSize: 13),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: colors.controlSurface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colors.borderSubtle),
      ),
    );
  }
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

enum _StorylineContentTab { graph, structure }

class _StorylineTabsRow extends StatelessWidget {
  const _StorylineTabsRow({
    required this.selectedTab,
    required this.onTabSelected,
  });

  final _StorylineContentTab selectedTab;
  final ValueChanged<_StorylineContentTab> onTabSelected;

  @override
  Widget build(BuildContext context) {
    return KeyedSubtree(
      key: const ValueKey('storylines-tabs'),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: PokeMapSegmentedTabs(
          tabs: [
            PokeMapSegmentedTab(
              label: 'Graph',
              selected: selectedTab == _StorylineContentTab.graph,
              icon: CupertinoIcons.arrow_branch,
              onTap: () => onTabSelected(_StorylineContentTab.graph),
            ),
            PokeMapSegmentedTab(
              label: 'Structure',
              selected: selectedTab == _StorylineContentTab.structure,
              icon: CupertinoIcons.square_list,
              onTap: () => onTabSelected(_StorylineContentTab.structure),
            ),
          ],
        ),
      ),
    );
  }
}

class _StorylinesSectionLabel extends StatelessWidget {
  const _StorylinesSectionLabel({
    required this.label,
    required this.color,
  });

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: TextStyle(
        color: color,
        fontSize: 10.5,
        fontWeight: FontWeight.w800,
        letterSpacing: 0.4,
      ),
    );
  }
}

class _StorylineInspectorTextLine extends StatelessWidget {
  const _StorylineInspectorTextLine({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 96,
          child: Text(
            label,
            style: TextStyle(
              color: colors.textMuted,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: TextStyle(
              color: colors.textPrimary,
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

```

### packages/map_editor/test/storylines_structure_layout_test.dart

```text
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/editor/state/editor_notifier.dart';
import 'package:map_editor/src/features/editor/state/editor_state.dart';
import 'package:map_editor/src/features/narrative/state/narrative_workspace_state.dart';
import 'package:map_editor/src/theme/theme.dart';
import 'package:map_editor/src/ui/canvas/narrative_workspace_canvas.dart';

void main() {
  group('NS-STORYLINES Structure full-width accordion authoring', () {
    testWidgets('Structure uses a full-width vertical chapter accordion',
        (tester) async {
      final project = _loadSelbrumeProject();

      await _pumpStorylinesShell(tester, project: project);
      await _openStructureTab(tester);

      expect(find.byKey(const ValueKey('storylines-structure-view')),
          findsOneWidget);
      expect(find.byKey(const ValueKey('storylines-structure-toolbar')),
          findsOneWidget);
      expect(find.byKey(const ValueKey('storylines-structure-accordion-list')),
          findsOneWidget);
      expect(
          tester
              .getSize(
                find.byKey(
                  const ValueKey('storylines-structure-accordion-list'),
                ),
              )
              .width,
          greaterThan(760));
      expect(
          find.byKey(
            const ValueKey('storylines-chapter-accordion-chapter_1_port'),
          ),
          findsOneWidget);
      expect(
          find.byKey(
            const ValueKey('storylines-chapter-accordion-chapter_2_marais'),
          ),
          findsOneWidget);
      expect(
          find.byKey(
            const ValueKey('storylines-chapter-expanded-chapter_1_port'),
          ),
          findsOneWidget);
      expect(
          find.byKey(
            const ValueKey('storylines-chapter-collapsed-chapter_2_marais'),
          ),
          findsOneWidget);
      expect(find.byKey(const ValueKey('storylines-structure-search-action')),
          findsOneWidget);
      expect(find.byKey(const ValueKey('storylines-structure-filter-action')),
          findsOneWidget);
      expect(find.byKey(const ValueKey('storylines-structure-sort-action')),
          findsOneWidget);
      expect(find.text('Nouveau chapitre'), findsOneWidget);
      expect(find.text('Nouvelle étape narrative'), findsOneWidget);
      expect(find.byKey(const ValueKey('storylines-v1-structure-steps')),
          findsOneWidget);

      expect(
          find.byKey(const ValueKey('storylines-step-row-step_intro_selbrume')),
          findsOneWidget);
      expect(
          find.byKey(const ValueKey('storylines-step-row-step_enter_marais')),
          findsNothing);
      expect(find.textContaining('Aucune scène liée'), findsWidgets);
    });

    testWidgets('accordion chapter selection opens another without mutation',
        (tester) async {
      final seedFile = _selbrumeProjectFile();
      final seedBefore = seedFile.readAsStringSync();
      final project = _loadSelbrumeProject();
      final before = project.toJson();

      await _pumpStorylinesShell(tester, project: project);
      await _openStructureTab(tester);
      await tester.ensureVisible(
        find.byKey(
          const ValueKey('storylines-chapter-toggle-chapter_2_marais'),
        ),
      );
      await tester.tap(
        find.byKey(
          const ValueKey('storylines-chapter-toggle-chapter_2_marais'),
        ),
      );
      await tester.pumpAndSettle();

      expect(
          find.byKey(const ValueKey('storylines-step-row-step_enter_marais')),
          findsOneWidget);
      expect(
          find.byKey(const ValueKey('storylines-step-row-step_intro_selbrume')),
          findsNothing);
      expect(find.text('DÉTAILS DU CHAPITRE'), findsOneWidget);
      expect(project.toJson(), before);
      expect(seedFile.readAsStringSync(), seedBefore);
    });

    testWidgets('chapter edit and delete mutate ProjectManifest.storylines',
        (tester) async {
      final seedFile = _selbrumeProjectFile();
      final seedBefore = seedFile.readAsStringSync();
      final project = _loadSelbrumeProject();

      final container = await _pumpStorylinesShell(tester, project: project);
      await _openStructureTab(tester);
      await tester.tap(
        find.byKey(
          const ValueKey('storylines-edit-chapter-action-chapter_1_port'),
        ),
      );
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey('storylines-edit-chapter-title-field')),
        'Port révisé',
      );
      await tester.enterText(
        find.byKey(
          const ValueKey('storylines-edit-chapter-description-field'),
        ),
        'Chapitre ajusté depuis la vue Structure.',
      );
      await tester.pump();
      await tester
          .tap(find.byKey(const ValueKey('storylines-edit-chapter-submit')));
      await tester.pumpAndSettle();

      var updatedProject = container.read(editorNotifierProvider).project!;
      var main = _selbrumeMain(updatedProject);
      expect(main.chapters.first.title, 'Port révisé');
      expect(
        main.chapters.first.description,
        'Chapitre ajusté depuis la vue Structure.',
      );

      await tester.ensureVisible(
        find.byKey(
          const ValueKey('storylines-delete-chapter-action-chapter_4_epilogue'),
        ),
      );
      await tester.tap(
        find.byKey(
          const ValueKey('storylines-delete-chapter-action-chapter_4_epilogue'),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const ValueKey('storylines-confirm-delete-submit')),
      );
      await tester.pumpAndSettle();

      updatedProject = container.read(editorNotifierProvider).project!;
      main = _selbrumeMain(updatedProject);
      expect(main.chapters.map((chapter) => chapter.id),
          isNot(contains('chapter_4_epilogue')));
      expect(main.chapters, hasLength(3));
      expect(seedFile.readAsStringSync(), seedBefore);
    });

    testWidgets(
        'step edit delete and drag reorder update only selected chapter',
        (tester) async {
      final seedFile = _selbrumeProjectFile();
      final seedBefore = seedFile.readAsStringSync();
      final project = _loadSelbrumeProject();

      final container = await _pumpStorylinesShell(tester, project: project);
      await _openStructureTab(tester);

      await tester.tap(
        find.byKey(
          const ValueKey('storylines-edit-step-action-step_intro_selbrume'),
        ),
      );
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey('storylines-edit-step-title-field')),
        'Introduction révisée',
      );
      await tester.pump();
      await tester
          .tap(find.byKey(const ValueKey('storylines-edit-step-submit')));
      await tester.pumpAndSettle();

      var updatedProject = container.read(editorNotifierProvider).project!;
      var main = _selbrumeMain(updatedProject);
      expect(main.chapters.first.steps.first.title, 'Introduction révisée');

      await tester.ensureVisible(
        find.byKey(
          const ValueKey('storylines-step-drag-step_receive_mission'),
        ),
      );
      await tester.drag(
        find.byKey(
          const ValueKey('storylines-step-drag-step_receive_mission'),
        ),
        const Offset(0, -80),
      );
      await tester.pumpAndSettle();

      updatedProject = container.read(editorNotifierProvider).project!;
      main = _selbrumeMain(updatedProject);
      expect(main.chapters.first.steps.first.id, 'step_receive_mission');
      expect(main.chapters.first.steps.first.order, 0);
      expect(main.chapters.first.steps[1].id, 'step_intro_selbrume');
      expect(main.chapters.first.steps[1].order, 1);

      await tester.tap(
        find.byKey(
          const ValueKey('storylines-delete-step-action-step_go_to_port'),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const ValueKey('storylines-confirm-delete-submit')),
      );
      await tester.pumpAndSettle();

      updatedProject = container.read(editorNotifierProvider).project!;
      main = _selbrumeMain(updatedProject);
      expect(main.chapters.first.steps.map((step) => step.id),
          isNot(contains('step_go_to_port')));
      expect(main.chapters.first.steps, hasLength(3));
      expect(main.chapters[1].steps.map((step) => step.id),
          contains('step_enter_marais'));
      expect(seedFile.readAsStringSync(), seedBefore);
    });

    testWidgets('existing step creation flow remains wired in Structure',
        (tester) async {
      final seedFile = _selbrumeProjectFile();
      final seedBefore = seedFile.readAsStringSync();
      final project = _loadSelbrumeProject();

      final container = await _pumpStorylinesShell(tester, project: project);
      await _openStructureTab(tester);
      await tester
          .tap(find.byKey(const ValueKey('storylines-new-step-action')));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey('storylines-create-step-title-field')),
        'Note de structure',
      );
      await tester.enterText(
        find.byKey(const ValueKey('storylines-create-step-description-field')),
        'Step créée par le flow auteur existant.',
      );
      await tester.pump();
      await tester
          .tap(find.byKey(const ValueKey('storylines-create-step-submit')));
      await tester.pumpAndSettle();

      final updatedProject = container.read(editorNotifierProvider).project!;
      final main = _selbrumeMain(updatedProject);
      final firstChapter = main.chapters.first;
      expect(firstChapter.steps.last.id, 'step_note_de_structure');
      expect(firstChapter.steps.last.order, 4);
      expect(
          find.byKey(
              const ValueKey('storylines-step-row-step_note_de_structure')),
          findsOneWidget);
      expect(seedFile.readAsStringSync(), seedBefore);
    });

    testWidgets('Graph remains accessible with independent sideQuest nodes',
        (tester) async {
      final project = _loadSelbrumeProject();

      await _pumpStorylinesShell(tester, project: project);

      expect(find.byKey(const ValueKey('storylines-graph-canvas')),
          findsOneWidget);
      expect(
        find.byKey(
          const ValueKey(
            'storylines-graph-node-sidequest-story_side_salt_crystals',
          ),
        ),
        findsOneWidget,
      );
      expect(
        find.byKey(
          const ValueKey(
            'storylines-graph-edge-sidequest-relationship_salt_crystals_available_enter_marais',
          ),
        ),
        findsOneWidget,
      );
    });

    testWidgets('writes Structure accordion bis visual gate screenshots',
        (tester) async {
      final project = _loadSelbrumeProject();

      await _pumpStorylinesShell(tester, project: project);
      await _openStructureTab(tester);
      await expectLater(
        find.byKey(const ValueKey('storylines-workspace-shell')),
        matchesGoldenFile(
          '../../../reports/narrativeStudio/storylines/screenshots/'
          'ns_storylines_structure_bis_full_width_accordion.png',
        ),
      );

      await expectLater(
        find.byKey(
          const ValueKey('storylines-chapter-expanded-chapter_1_port'),
        ),
        matchesGoldenFile(
          '../../../reports/narrativeStudio/storylines/screenshots/'
          'ns_storylines_structure_bis_expanded_chapter_steps.png',
        ),
      );

      await expectLater(
        find.byKey(
          const ValueKey('storylines-chapter-collapsed-chapter_2_marais'),
        ),
        matchesGoldenFile(
          '../../../reports/narrativeStudio/storylines/screenshots/'
          'ns_storylines_structure_bis_collapsed_chapter.png',
        ),
      );

      await tester
          .tap(find.byKey(const ValueKey('storylines-new-step-action')));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey('storylines-create-step-title-field')),
        'Point de lecture',
      );
      await tester.enterText(
        find.byKey(const ValueKey('storylines-create-step-description-field')),
        'Capture de régression Structure.',
      );
      await tester.pump();
      await tester
          .tap(find.byKey(const ValueKey('storylines-create-step-submit')));
      await tester.pumpAndSettle();
      await expectLater(
        find.byKey(
          const ValueKey('storylines-chapter-expanded-chapter_1_port'),
        ),
        matchesGoldenFile(
          '../../../reports/narrativeStudio/storylines/screenshots/'
          'ns_storylines_structure_bis_authoring_actions.png',
        ),
      );

      await tester.tap(
        find.descendant(
          of: find.byKey(const ValueKey('storylines-tabs')),
          matching: find.text('Graph'),
        ),
      );
      await tester.pumpAndSettle();
      await expectLater(
        find.byKey(const ValueKey('storylines-workspace-shell')),
        matchesGoldenFile(
          '../../../reports/narrativeStudio/storylines/screenshots/'
          'ns_storylines_structure_bis_graph_regression.png',
        ),
      );
    });
  });
}

Future<ProviderContainer> _pumpStorylinesShell(
  WidgetTester tester, {
  required ProjectManifest project,
}) async {
  await tester.binding.setSurfaceSize(const Size(1600, 1000));
  addTearDown(() => tester.binding.setSurfaceSize(null));

  final container = ProviderContainer();
  addTearDown(container.dispose);
  final editorSubscription = container.listen(
    editorNotifierProvider,
    (_, __) {},
  );
  addTearDown(editorSubscription.close);

  container.read(editorNotifierProvider.notifier).state = EditorState(
    project: project,
    workspaceMode: EditorWorkspaceMode.globalStory,
  );
  container
      .read(narrativeWorkspaceControllerProvider.notifier)
      .openGlobalStory();

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        theme: PokeMapTheme.light(),
        darkTheme: PokeMapTheme.dark(),
        themeMode: ThemeMode.dark,
        home: const Scaffold(
          body: SizedBox(
            width: 1600,
            height: 1000,
            child: NarrativeWorkspaceCanvas(),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
  await tester.pump();
  return container;
}

Future<void> _openStructureTab(WidgetTester tester) async {
  await tester.tap(
    find.descendant(
      of: find.byKey(const ValueKey('storylines-tabs')),
      matching: find.text('Structure'),
    ),
  );
  await tester.pumpAndSettle();
}

ProjectManifest _loadSelbrumeProject() {
  final file = _selbrumeProjectFile();
  final json = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
  return ProjectManifest.fromJson(json);
}

File _selbrumeProjectFile() {
  final file = File('../../selbrume/project.json');
  if (!file.existsSync()) {
    throw StateError('Missing Selbrume project fixture at ${file.path}');
  }
  return file;
}

StorylineAsset _selbrumeMain(ProjectManifest project) {
  return project.storylines.singleWhere(
    (storyline) => storyline.id == 'story_main_brume_phare',
  );
}

```

### packages/map_editor/test/storylines_seed_graph_usability_test.dart

```text
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/editor/state/editor_notifier.dart';
import 'package:map_editor/src/features/editor/state/editor_state.dart';
import 'package:map_editor/src/features/narrative/state/narrative_workspace_state.dart';
import 'package:map_editor/src/theme/theme.dart';
import 'package:map_editor/src/ui/canvas/narrative_workspace_canvas.dart';
import 'package:map_editor/src/ui/canvas/storylines/storylines_graph_model.dart';
import 'package:map_editor/src/ui/canvas/storylines/storylines_graph_view.dart';

void main() {
  group('NS-STORYLINES-SEED-FIX Selbrume graph usability', () {
    test('reads seeded sideQuest relationships and resolves step anchors', () {
      final project = _loadSelbrumeProject();
      final main = _selbrumeMain(project);
      final relationships = _selbrumeAttachmentRelationships(project);

      expect(relationships, hasLength(3));
      expect(
        relationships.map((relationship) => relationship.id),
        containsAll(<String>[
          'relationship_salt_crystals_available_enter_marais',
          'relationship_goelise_port_available_rival_battle',
          'relationship_lighthouse_cabin_available_report_soline',
        ]),
      );

      final anchorTargets = {
        for (final relationship in relationships)
          relationship.id: relationship.availability!.startAnchor.targetId,
      };
      expect(
        anchorTargets,
        containsPair(
          'relationship_salt_crystals_available_enter_marais',
          'step_enter_marais',
        ),
      );
      expect(
        anchorTargets,
        containsPair(
          'relationship_goelise_port_available_rival_battle',
          'step_rival_battle',
        ),
      );
      expect(
        anchorTargets,
        containsPair(
          'relationship_lighthouse_cabin_available_report_soline',
          'step_report_to_soline',
        ),
      );
      for (final targetId in anchorTargets.values) {
        expect(_mainStepIds(main), contains(targetId));
      }

      final model = StorylineGraphViewModel.fromStoryline(
        main,
        storylines: project.storylines,
        sideQuestCountOutsideSelected: 3,
      );

      expect(model.sideQuestAttachments, hasLength(3));
      expect(
        _attachmentBySideQuest(model, 'story_side_salt_crystals').chapterId,
        'chapter_2_marais',
      );
      expect(
        _attachmentBySideQuest(model, 'story_side_goelise_port').chapterId,
        'chapter_1_port',
      );
      expect(
        _attachmentBySideQuest(model, 'story_side_lighthouse_cabin').chapterId,
        'chapter_2_marais',
      );
      expect(
        model.sideQuestAttachments
            .map((attachment) => attachment.anchorKind)
            .toSet(),
        {StorylineAnchorKind.step},
      );
      expect(
        model.nodes
            .where((node) => node.kind == StorylineGraphNodeKind.sideQuest),
        hasLength(3),
      );
      expect(
        model.edges.where(
          (edge) => edge.kind == StorylineGraphEdgeKind.sideQuestAttachment,
        ),
        hasLength(3),
      );
    });

    testWidgets(
      'renders sideQuest nodes outside chapter cards on a larger canvas',
      (tester) async {
        final project = _loadSelbrumeProject();
        await _pumpGraph(tester, project);

        final canvas = find.byKey(const ValueKey('storylines-graph-canvas'));
        expect(canvas, findsOneWidget);
        expect(tester.getSize(canvas).height, greaterThanOrEqualTo(760));

        final portChapter = find.byKey(
            const ValueKey('storylines-graph-node-chapter-chapter_1_port'));
        final maraisChapter = find.byKey(
          const ValueKey('storylines-graph-node-chapter-chapter_2_marais'),
        );
        final saltNode = find.byKey(
          const ValueKey(
              'storylines-graph-node-sidequest-story_side_salt_crystals'),
        );
        final goeliseNode = find.byKey(
          const ValueKey(
              'storylines-graph-node-sidequest-story_side_goelise_port'),
        );
        final cabinNode = find.byKey(
          const ValueKey(
              'storylines-graph-node-sidequest-story_side_lighthouse_cabin'),
        );

        expect(portChapter, findsOneWidget);
        expect(maraisChapter, findsOneWidget);
        expect(saltNode, findsOneWidget);
        expect(goeliseNode, findsOneWidget);
        expect(cabinNode, findsOneWidget);
        expect(
            tester.getRect(goeliseNode).overlaps(tester.getRect(portChapter)),
            isFalse);
        expect(tester.getRect(saltNode).overlaps(tester.getRect(maraisChapter)),
            isFalse);
        expect(
            tester.getRect(cabinNode).overlaps(tester.getRect(maraisChapter)),
            isFalse);

        expect(
          find.byKey(
            const ValueKey(
                'storylines-graph-sidequest-caption-chapter_2_marais'),
          ),
          findsNothing,
        );
        expect(find.textContaining('2 quêtes disponibles'), findsOneWidget);
        expect(find.byKey(const ValueKey('storylines-graph-steps-overflow')),
            findsWidgets);
        expect(
          find.byKey(
            const ValueKey(
              'storylines-graph-edge-sidequest-relationship_salt_crystals_available_enter_marais',
            ),
          ),
          findsOneWidget,
        );
        expect(
          find.byKey(
            const ValueKey(
              'storylines-graph-edge-sidequest-relationship_goelise_port_available_rival_battle',
            ),
          ),
          findsOneWidget,
        );
        expect(
          find.byKey(
            const ValueKey(
              'storylines-graph-edge-sidequest-relationship_lighthouse_cabin_available_report_soline',
            ),
          ),
          findsOneWidget,
        );
      },
    );

    testWidgets('graph rendering does not mutate ProjectManifest or seed file',
        (tester) async {
      final seedFile = _selbrumeProjectFile();
      final seedBefore = seedFile.readAsStringSync();
      final project = _loadSelbrumeProject();
      final before = project.toJson();

      await _pumpGraph(tester, project);
      await tester.tap(find.byKey(const ValueKey('storylines-graph-canvas')));
      await tester.pump();

      expect(project.toJson(), before);
      expect(seedFile.readAsStringSync(), seedBefore);
      expect(_selbrumeMain(project).sceneLinks, isEmpty);
      expect(_selbrumeAttachmentRelationships(project), hasLength(3));
    });

    testWidgets('full Storylines shell prioritizes Graph canvas',
        (tester) async {
      final project = _loadSelbrumeProject();
      await _pumpStorylinesShell(tester, project: project);

      final canvas = find.byKey(const ValueKey('storylines-graph-canvas'));
      final panel = find.byKey(const ValueKey('storylines-main-panel'));
      expect(canvas, findsOneWidget);
      expect(panel, findsOneWidget);
      expect(find.byKey(const ValueKey('storylines-header-section-compact')),
          findsOneWidget);
      expect(find.byKey(const ValueKey('storylines-kpi-strip-compact')),
          findsOneWidget);
      expect(find.byKey(const ValueKey('storylines-graph-toolbar')),
          findsOneWidget);
      expect(
        tester.getSize(canvas).height / tester.getSize(panel).height,
        greaterThanOrEqualTo(0.62),
      );
    });

    testWidgets('Graph and Structure switching stays non-mutating',
        (tester) async {
      final seedFile = _selbrumeProjectFile();
      final seedBefore = seedFile.readAsStringSync();
      final project = _loadSelbrumeProject();
      final before = project.toJson();

      await _pumpStorylinesShell(tester, project: project);
      await tester.tap(
        find.descendant(
          of: find.byKey(const ValueKey('storylines-tabs')),
          matching: find.text('Structure'),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Chapitres'), findsWidgets);
      expect(find.text('Étapes narratives'), findsWidgets);

      await tester.tap(
        find.descendant(
          of: find.byKey(const ValueKey('storylines-tabs')),
          matching: find.text('Graph'),
        ),
      );
      await tester.pumpAndSettle();

      expect(project.toJson(), before);
      expect(seedFile.readAsStringSync(), seedBefore);
      expect(_selbrumeAttachmentRelationships(project), hasLength(3));
      expect(_selbrumeMain(project).sceneLinks, isEmpty);
    });

    testWidgets('writes seed fix bis visual gate screenshots', (tester) async {
      final project = _loadSelbrumeProject();

      await _pumpStorylinesShell(tester, project: project);
      await expectLater(
        find.byKey(const ValueKey('storylines-workspace-shell')),
        matchesGoldenFile(
          '../../../reports/narrativeStudio/storylines/screenshots/'
          'ns_storylines_seed_fix_01_bis_graph_full_layout.png',
        ),
      );

      await _pumpGraph(tester, project);
      await expectLater(
        find.byKey(const ValueKey('storylines-graph-canvas')),
        matchesGoldenFile(
          '../../../reports/narrativeStudio/storylines/screenshots/'
          'ns_storylines_seed_fix_01_bis_graph_focus_canvas.png',
        ),
      );

      await _pumpStorylinesShell(tester, project: project);
      await tester.tap(
        find.descendant(
          of: find.byKey(const ValueKey('storylines-tabs')),
          matching: find.text('Structure'),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('storylines-structure-view')),
          findsOneWidget);
      expect(
          find.byKey(
            const ValueKey('storylines-chapter-expanded-chapter_1_port'),
          ),
          findsOneWidget);
      expect(
          find.byKey(
            const ValueKey('storylines-chapter-collapsed-chapter_2_marais'),
          ),
          findsOneWidget);
    });
  });
}

Future<void> _pumpGraph(
  WidgetTester tester,
  ProjectManifest project,
) async {
  await tester.binding.setSurfaceSize(const Size(1600, 1000));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  final main = _selbrumeMain(project);
  await tester.pumpWidget(
    MaterialApp(
      theme: PokeMapTheme.light(),
      darkTheme: PokeMapTheme.dark(),
      themeMode: ThemeMode.dark,
      home: Scaffold(
        body: SizedBox(
          width: 1600,
          height: 1000,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: StorylinesGraphView(
              storyline: main,
              storylines: project.storylines,
              sideQuestCountOutsideSelected: 3,
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
  await tester.pump();
}

Future<void> _pumpStorylinesShell(
  WidgetTester tester, {
  required ProjectManifest project,
}) async {
  await tester.binding.setSurfaceSize(const Size(1600, 1000));
  addTearDown(() => tester.binding.setSurfaceSize(null));

  final container = ProviderContainer();
  addTearDown(container.dispose);
  final editorSubscription = container.listen(
    editorNotifierProvider,
    (_, __) {},
  );
  addTearDown(editorSubscription.close);

  container.read(editorNotifierProvider.notifier).state = EditorState(
    project: project,
    workspaceMode: EditorWorkspaceMode.globalStory,
  );
  container
      .read(narrativeWorkspaceControllerProvider.notifier)
      .openGlobalStory();

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        theme: PokeMapTheme.light(),
        darkTheme: PokeMapTheme.dark(),
        themeMode: ThemeMode.dark,
        home: const Scaffold(
          body: SizedBox(
            width: 1600,
            height: 1000,
            child: NarrativeWorkspaceCanvas(),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
  await tester.pump();
}

ProjectManifest _loadSelbrumeProject() {
  final file = _selbrumeProjectFile();
  final json = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
  return ProjectManifest.fromJson(json);
}

File _selbrumeProjectFile() {
  final file = File('../../selbrume/project.json');
  if (!file.existsSync()) {
    throw StateError('Missing Selbrume project fixture at ${file.path}');
  }
  return file;
}

StorylineAsset _selbrumeMain(ProjectManifest project) {
  return project.storylines.singleWhere(
    (storyline) => storyline.id == 'story_main_brume_phare',
  );
}

List<StorylineRelationship> _selbrumeAttachmentRelationships(
  ProjectManifest project,
) {
  return [
    for (final storyline in project.storylines)
      for (final relationship in storyline.relationships)
        if (relationship.kind ==
                StorylineRelationshipKind.sideQuestAvailableDuring &&
            relationship.targetStorylineId == 'story_main_brume_phare')
          relationship,
  ];
}

Set<String> _mainStepIds(StorylineAsset main) {
  return {
    for (final chapter in main.chapters)
      for (final step in chapter.steps) step.id,
  };
}

StorylineGraphSideQuestAttachment _attachmentBySideQuest(
  StorylineGraphViewModel model,
  String sideQuestId,
) {
  return model.sideQuestAttachments.singleWhere(
    (attachment) => attachment.sideQuestId == sideQuestId,
  );
}

```

### packages/map_editor/test/storylines_workspace_shell_test.dart

```text
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/editor/state/editor_notifier.dart';
import 'package:map_editor/src/features/editor/state/editor_state.dart';
import 'package:map_editor/src/features/narrative/state/narrative_workspace_state.dart';
import 'package:map_editor/src/theme/theme.dart';
import 'package:map_editor/src/ui/canvas/narrative_workspace_canvas.dart';
import 'package:map_editor/src/ui/design_system/design_system.dart';

void main() {
  group('NS-STORYLINES-V1-12 visual graph enrichment', () {
    testWidgets('shows only Graph and Structure tabs', (tester) async {
      await _pumpStorylinesShell(tester);

      final tabs = find.byKey(const ValueKey('storylines-tabs'));
      expect(find.descendant(of: tabs, matching: find.text('Graph')),
          findsOneWidget);
      expect(find.descendant(of: tabs, matching: find.text('Structure')),
          findsOneWidget);
      expect(find.descendant(of: tabs, matching: find.text('Étapes')),
          findsNothing);
      expect(find.descendant(of: tabs, matching: find.text('Scènes')),
          findsNothing);
      expect(find.descendant(of: tabs, matching: find.text('Statistiques')),
          findsNothing);
      expect(find.descendant(of: tabs, matching: find.text('Tests')),
          findsNothing);
    });

    testWidgets('shows V1 empty state without importing legacy globalStory',
        (tester) async {
      final harness = await _pumpStorylinesShell(
        tester,
        project: _legacyOnlyProject(),
      );

      expect(find.text('Aucune storyline auteur'), findsWidgets);
      expect(find.byKey(const ValueKey('storylines-create-main-cta')),
          findsOneWidget);
      expect(find.byKey(const ValueKey('storylines-graph-target-read-only')),
          findsOneWidget);
      expect(
          find.byKey(const ValueKey('storylines-graph-canvas')), findsNothing);
      expect(
          find.byKey(const ValueKey('storylines-graph-node-chapter-anything')),
          findsNothing);
      expect(find.textContaining('ne sera pas importée automatiquement'),
          findsOneWidget);
      expect(find.byKey(const ValueKey('storylines-v1-legacy-preview-card')),
          findsOneWidget);
      expect(find.text('Legacy Global Story'), findsWidgets);
      expect(harness.project.storylines, isEmpty);
      expect(harness.project.scenarios.single.scope, ScenarioScope.globalStory);
    });

    testWidgets(
        'opens and cancels create main storyline dialog without mutation',
        (tester) async {
      final harness = await _pumpStorylinesShell(tester);
      final before = harness.project.toJson();

      await _openCreateDialog(tester);
      expect(find.byKey(const ValueKey('storylines-create-main-dialog')),
          findsOneWidget);
      expect(find.text('Histoire principale'), findsOneWidget);
      expect(find.text('Quête annexe'), findsOneWidget);
      expect(
        find.text(
          'Créez d’abord une histoire principale pour organiser les quêtes annexes.',
        ),
        findsOneWidget,
      );
      expect(find.text('Sélectionné'), findsOneWidget);
      expect(find.byKey(const ValueKey('storylines-create-title-field')),
          findsOneWidget);
      expect(find.byKey(const ValueKey('storylines-create-description-field')),
          findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('storylines-create-cancel')));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('storylines-create-main-dialog')),
          findsNothing);
      expect(harness.project.storylines, isEmpty);
      expect(harness.project.toJson(), before);
    });

    testWidgets('requires title before create', (tester) async {
      final harness = await _pumpStorylinesShell(tester);

      await _openCreateDialog(tester);

      final submit = tester.widget<PokeMapButton>(
        find.byKey(const ValueKey('storylines-create-submit')),
      );
      expect(submit.onPressed, isNull);
      expect(find.text('Titre obligatoire.'), findsOneWidget);
      expect(harness.project.storylines, isEmpty);
    });

    testWidgets('does not create sideQuest before a main storyline exists',
        (tester) async {
      final harness = await _pumpStorylinesShell(tester);

      await _openCreateDialog(tester);
      await tester
          .tap(find.byKey(const ValueKey('storylines-create-type-sidequest')));
      await tester.pump();
      await tester.enterText(
        find.byKey(const ValueKey('storylines-create-title-field')),
        'Early side quest',
      );
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('storylines-create-submit')));
      await tester.pumpAndSettle();

      expect(harness.project.storylines, hasLength(1));
      expect(harness.project.storylines.single.type, StorylineType.main);
      expect(
        harness.project.storylines
            .where((storyline) => storyline.type == StorylineType.sideQuest),
        isEmpty,
      );
    });

    testWidgets('dialog selects sideQuest when a main storyline exists',
        (tester) async {
      final harness = await _pumpStorylinesShell(
        tester,
        project: _projectWithStorylines([
          StorylineAsset(
            id: 'storyline_existing_main',
            type: StorylineType.main,
            title: 'Existing main',
          ),
        ]),
      );
      final before = harness.project.toJson();

      await _openCreateDialog(tester);

      final dialog =
          find.byKey(const ValueKey('storylines-create-main-dialog'));
      expect(find.text('Une histoire principale existe déjà.'), findsWidgets);
      expect(
        find.descendant(of: dialog, matching: find.text('Quête annexe')),
        findsOneWidget,
      );
      expect(find.text('Sélectionné'), findsOneWidget);
      expect(find.byKey(const ValueKey('storylines-create-title-field')),
          findsOneWidget);
      expect(find.byKey(const ValueKey('storylines-create-description-field')),
          findsOneWidget);

      final submit = tester.widget<PokeMapButton>(
        find.byKey(const ValueKey('storylines-create-submit')),
      );
      expect(submit.onPressed, isNull);

      await tester.tap(find.byKey(const ValueKey('storylines-create-cancel')));
      await tester.pumpAndSettle();
      expect(harness.project.toJson(), before);
    });

    testWidgets('creates a main StorylineAsset and syncs Graph and Structure',
        (tester) async {
      final harness = await _pumpStorylinesShell(tester);

      await _createMainStoryline(
        tester,
        title: 'Ma grande histoire',
        description: 'Une structure auteur propre.',
      );

      final storylines = harness.project.storylines;
      expect(storylines, hasLength(1));
      final storyline = storylines.single;
      expect(storyline.id, 'storyline_ma_grande_histoire');
      expect(storyline.type, StorylineType.main);
      expect(storyline.status, StorylineStatus.draft);
      expect(storyline.title, 'Ma grande histoire');
      expect(storyline.description, 'Une structure auteur propre.');
      expect(storyline.chapters, isEmpty);
      expect(storyline.sceneLinks, isEmpty);
      expect(storyline.relationships, isEmpty);

      expect(find.text('Ma grande histoire'), findsWidgets);
      expect(
        find.text('Ajoutez un chapitre dans Structure'),
        findsOneWidget,
      );
      expect(
        find.byKey(
          const ValueKey(
            'storylines-graph-node-storyline-storyline_ma_grande_histoire',
          ),
        ),
        findsOneWidget,
      );

      await _openStructureTab(tester);
      expect(find.byKey(const ValueKey('storylines-structure-read-only')),
          findsOneWidget);
      expect(find.text('Chapitres'), findsWidgets);
      expect(
        find.byKey(const ValueKey('storylines-structure-accordion-list')),
        findsOneWidget,
      );
      expect(
        find.text(
          'Créez un premier chapitre pour organiser la progression de la storyline.',
        ),
        findsOneWidget,
      );
      expect(find.byKey(const ValueKey('storylines-new-chapter-action')),
          findsOneWidget);
      expect(find.text('Nouveau chapitre'), findsOneWidget);
    });

    testWidgets('creates a sideQuest StorylineAsset and selects it',
        (tester) async {
      final harness = await _pumpStorylinesShell(
        tester,
        project: _projectWithStorylines([
          StorylineAsset(
            id: 'storyline_existing_main',
            type: StorylineType.main,
            title: 'Existing main',
          ),
        ]),
      );

      await _createSideQuest(
        tester,
        title: 'Missing Bell',
        description: 'Optional story arc.',
      );

      final storylines = harness.project.storylines;
      expect(storylines, hasLength(2));
      final sideQuest = storylines.singleWhere(
        (storyline) => storyline.type == StorylineType.sideQuest,
      );
      expect(sideQuest.id, 'sidequest_missing_bell');
      expect(sideQuest.status, StorylineStatus.draft);
      expect(sideQuest.title, 'Missing Bell');
      expect(sideQuest.description, 'Optional story arc.');
      expect(sideQuest.chapters, isEmpty);
      expect(sideQuest.sceneLinks, isEmpty);
      expect(sideQuest.relationships, isEmpty);

      expect(find.text('Missing Bell'), findsWidgets);
      expect(find.text('Quête annexe'), findsWidgets);
      expect(find.text('HISTOIRE PRINCIPALE'), findsOneWidget);
      expect(find.text('QUÊTES ANNEXES'), findsOneWidget);
      expect(find.text('Non reliée au graph principal'), findsWidgets);
      expect(find.byKey(const ValueKey('storylines-structure-read-only')),
          findsOneWidget);
    });

    testWidgets('Structure without storyline has no chapter or step action',
        (tester) async {
      final harness = await _pumpStorylinesShell(tester);
      final before = harness.project.toJson();

      await _openStructureTab(tester);

      expect(find.text('Créez une storyline pour commencer.'), findsOneWidget);
      expect(find.byKey(const ValueKey('storylines-new-chapter-action')),
          findsNothing);
      expect(find.byKey(const ValueKey('storylines-new-step-action')),
          findsNothing);
      expect(harness.project.toJson(), before);
    });

    testWidgets('opens and cancels create chapter without mutation',
        (tester) async {
      final harness = await _pumpStorylinesShell(
        tester,
        project: _projectWithStorylines([
          StorylineAsset(
            id: 'storyline_existing_main',
            type: StorylineType.main,
            title: 'Existing main',
          ),
        ]),
      );
      final before = harness.project.toJson();

      await _openCreateChapterDialog(tester);
      expect(find.byKey(const ValueKey('storylines-create-chapter-dialog')),
          findsOneWidget);
      expect(
          find.byKey(const ValueKey('storylines-create-chapter-title-field')),
          findsOneWidget);
      expect(
          find.byKey(
            const ValueKey('storylines-create-chapter-description-field'),
          ),
          findsOneWidget);

      await tester.tap(
        find.byKey(const ValueKey('storylines-create-chapter-cancel')),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('storylines-create-chapter-dialog')),
          findsNothing);
      expect(harness.project.toJson(), before);
    });

    testWidgets('requires chapter title before create', (tester) async {
      final harness = await _pumpStorylinesShell(
        tester,
        project: _projectWithStorylines([
          StorylineAsset(
            id: 'storyline_existing_main',
            type: StorylineType.main,
            title: 'Existing main',
          ),
        ]),
      );

      await _openCreateChapterDialog(tester);

      final submit = tester.widget<PokeMapButton>(
        find.byKey(const ValueKey('storylines-create-chapter-submit')),
      );
      expect(submit.onPressed, isNull);
      expect(find.text('Titre obligatoire.'), findsOneWidget);
      expect(harness.project.storylines.single.chapters, isEmpty);
    });

    testWidgets('creates chapters with stable ids, order and selection',
        (tester) async {
      final harness = await _pumpStorylinesShell(
        tester,
        project: _projectWithStorylines([
          StorylineAsset(
            id: 'storyline_existing_main',
            type: StorylineType.main,
            title: 'Existing main',
          ),
        ]),
      );

      await _createChapter(
        tester,
        title: 'Intro',
        description: 'Premier arc auteur.',
      );
      await _createChapter(tester, title: 'Intro');

      final chapters = harness.project.storylines.single.chapters;
      expect(chapters, hasLength(2));
      expect(chapters.map((chapter) => chapter.id), [
        'chapter_intro',
        'chapter_intro_2',
      ]);
      expect(chapters.map((chapter) => chapter.order), [0, 1]);
      expect(chapters.first.title, 'Intro');
      expect(chapters.first.description, 'Premier arc auteur.');
      expect(chapters.first.steps, isEmpty);
      expect(
          find.byKey(
            const ValueKey('storylines-chapter-accordion-chapter_intro'),
          ),
          findsOneWidget);
      expect(
          find.byKey(
            const ValueKey('storylines-chapter-accordion-chapter_intro_2'),
          ),
          findsOneWidget);
      expect(find.text('Étapes narratives'), findsWidgets);
    });

    testWidgets('step action requires a selected chapter', (tester) async {
      final harness = await _pumpStorylinesShell(
        tester,
        project: _projectWithStorylines([
          StorylineAsset(
            id: 'storyline_existing_main',
            type: StorylineType.main,
            title: 'Existing main',
          ),
        ]),
      );
      final before = harness.project.toJson();

      await _openStructureTab(tester);

      expect(find.byKey(const ValueKey('storylines-new-step-action')),
          findsNothing);
      expect(harness.project.toJson(), before);
    });

    testWidgets('opens and cancels create step without mutation',
        (tester) async {
      final harness = await _pumpStorylinesShell(
        tester,
        project: _projectWithStorylines([
          StorylineAsset(
            id: 'storyline_existing_main',
            type: StorylineType.main,
            title: 'Existing main',
            chapters: [
              StorylineChapter(
                id: 'chapter_intro',
                title: 'Intro',
                order: 0,
              ),
            ],
          ),
        ]),
      );
      final before = harness.project.toJson();

      await _openCreateStepDialog(tester);
      expect(find.byKey(const ValueKey('storylines-create-step-dialog')),
          findsOneWidget);

      await tester.tap(
        find.byKey(const ValueKey('storylines-create-step-cancel')),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('storylines-create-step-dialog')),
          findsNothing);
      expect(harness.project.toJson(), before);
    });

    testWidgets('requires step title before create', (tester) async {
      final harness = await _pumpStorylinesShell(
        tester,
        project: _projectWithStorylines([
          StorylineAsset(
            id: 'storyline_existing_main',
            type: StorylineType.main,
            title: 'Existing main',
            chapters: [
              StorylineChapter(
                id: 'chapter_intro',
                title: 'Intro',
                order: 0,
              ),
            ],
          ),
        ]),
      );

      await _openCreateStepDialog(tester);

      final submit = tester.widget<PokeMapButton>(
        find.byKey(const ValueKey('storylines-create-step-submit')),
      );
      expect(submit.onPressed, isNull);
      expect(find.text('Titre obligatoire.'), findsOneWidget);
      expect(harness.project.storylines.single.chapters.single.steps, isEmpty);
    });

    testWidgets('creates steps with global unique ids and order',
        (tester) async {
      final harness = await _pumpStorylinesShell(
        tester,
        project: _projectWithStorylines([
          StorylineAsset(
            id: 'storyline_existing_main',
            type: StorylineType.main,
            title: 'Existing main',
          ),
        ]),
      );

      await _createChapter(tester, title: 'Intro');
      await _createStep(
        tester,
        title: 'Premier jalon',
        description: 'Définir la progression.',
      );
      await _createStep(tester, title: 'Premier jalon');
      await _createChapter(tester, title: 'Second arc');
      await _createStep(tester, title: 'Premier jalon');

      final chapters = harness.project.storylines.single.chapters;
      final allSteps = [
        for (final chapter in chapters) ...chapter.steps,
      ];
      expect(allSteps.map((step) => step.id), [
        'step_premier_jalon',
        'step_premier_jalon_2',
        'step_premier_jalon_3',
      ]);
      expect(chapters.first.steps.map((step) => step.order), [0, 1]);
      expect(chapters.last.steps.single.order, 0);
      expect(chapters.first.steps.first.title, 'Premier jalon');
      expect(chapters.first.steps.first.description, 'Définir la progression.');
      expect(chapters.first.steps.first.sceneLinkIds, isEmpty);
      expect(chapters.first.steps.first.expectedOutcomeIds, isEmpty);
      expect(
          find.byKey(
            const ValueKey('storylines-step-row-step_premier_jalon_3'),
          ),
          findsOneWidget);
    });

    testWidgets('Structure authoring works on sideQuest without mutating main',
        (tester) async {
      final harness = await _pumpStorylinesShell(
        tester,
        project: _projectWithStorylines([
          StorylineAsset(
            id: 'storyline_existing_main',
            type: StorylineType.main,
            title: 'Existing main',
          ),
        ]),
      );

      await _createSideQuest(tester, title: 'Missing Bell');
      await _createChapter(tester, title: 'Side intro');
      await _createStep(tester, title: 'Find clue');

      final main = harness.project.storylines.singleWhere(
        (storyline) => storyline.type == StorylineType.main,
      );
      final sideQuest = harness.project.storylines.singleWhere(
        (storyline) => storyline.type == StorylineType.sideQuest,
      );
      expect(main.chapters, isEmpty);
      expect(sideQuest.chapters, hasLength(1));
      expect(sideQuest.chapters.single.id, 'chapter_side_intro');
      expect(sideQuest.chapters.single.steps, hasLength(1));
      expect(sideQuest.chapters.single.steps.single.id, 'step_find_clue');
      expect(sideQuest.chapters.single.steps.single.sceneLinkIds, isEmpty);
      expect(sideQuest.sceneLinks, isEmpty);
      expect(sideQuest.relationships, isEmpty);
      expect(find.text('Missing Bell'), findsWidgets);
      expect(find.byKey(const ValueKey('storylines-step-row-step_find_clue')),
          findsOneWidget);
    });

    testWidgets('Graph summarizes created structure without fake edges',
        (tester) async {
      await _pumpStorylinesShell(
        tester,
        project: _projectWithStorylines([
          StorylineAsset(
            id: 'storyline_existing_main',
            type: StorylineType.main,
            title: 'Existing main',
          ),
        ]),
      );

      await _createChapter(tester, title: 'Intro');
      await _createStep(tester, title: 'Premier jalon');
      await _openGraphTab(tester);

      final graphCanvas = find.byKey(const ValueKey('storylines-graph-canvas'));
      expect(
        find.descendant(
          of: graphCanvas,
          matching: find.byKey(
            const ValueKey(
              'storylines-graph-node-storyline-storyline_existing_main',
            ),
          ),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: graphCanvas,
          matching: find.byKey(
            const ValueKey('storylines-graph-node-chapter-chapter_intro'),
          ),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: graphCanvas,
          matching: find.byKey(
            const ValueKey('storylines-graph-node-step-step_premier_jalon'),
          ),
        ),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('storylines-graph-edge-root-chapter_intro')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('storylines-graph-legend-author-order')),
        findsOneWidget,
      );
      expect(find.text('Ordre auteur'), findsOneWidget);
      expect(find.text('Aucune scène liée'), findsOneWidget);
      expect(find.text('Ajoutez un chapitre dans Structure'), findsNothing);
      expect(find.text('Quête annexe fake'), findsNothing);
    });

    testWidgets('Graph orders chapters and steps by author order',
        (tester) async {
      await _pumpStorylinesShell(
        tester,
        project: _projectWithStorylines([
          StorylineAsset(
            id: 'storyline_ordered_main',
            type: StorylineType.main,
            title: 'Ordered main',
            chapters: [
              StorylineChapter(
                id: 'chapter_second',
                title: 'Second',
                order: 2,
              ),
              StorylineChapter(
                id: 'chapter_tie_b',
                title: 'Tie B',
                order: 1,
              ),
              StorylineChapter(
                id: 'chapter_first',
                title: 'First',
                order: 0,
                steps: [
                  StorylineStep(
                    id: 'step_second',
                    title: 'Second step',
                    order: 2,
                  ),
                  StorylineStep(
                    id: 'step_first',
                    title: 'First step',
                    order: 0,
                    sceneLinkIds: const ['scenario_scene_ref'],
                  ),
                ],
              ),
              StorylineChapter(
                id: 'chapter_tie_a',
                title: 'Tie A',
                order: 1,
              ),
            ],
          ),
        ]),
      );

      await _openGraphTab(tester);

      final firstX = tester
          .getTopLeft(
            find.byKey(
              const ValueKey('storylines-graph-node-chapter-chapter_first'),
            ),
          )
          .dx;
      final tieAX = tester
          .getTopLeft(
            find.byKey(
              const ValueKey('storylines-graph-node-chapter-chapter_tie_a'),
            ),
          )
          .dx;
      final tieBX = tester
          .getTopLeft(
            find.byKey(
              const ValueKey('storylines-graph-node-chapter-chapter_tie_b'),
            ),
          )
          .dx;
      final secondX = tester
          .getTopLeft(
            find.byKey(
              const ValueKey('storylines-graph-node-chapter-chapter_second'),
            ),
          )
          .dx;
      expect(firstX, lessThan(tieAX));
      expect(tieAX, lessThan(tieBX));
      expect(tieBX, lessThan(secondX));

      final firstStepY = tester
          .getTopLeft(
            find.byKey(const ValueKey('storylines-graph-node-step-step_first')),
          )
          .dy;
      final secondStepY = tester
          .getTopLeft(
            find.byKey(
                const ValueKey('storylines-graph-node-step-step_second')),
          )
          .dy;
      expect(firstStepY, lessThan(secondStepY));
      expect(find.text('1 scène liée'), findsOneWidget);
    });

    testWidgets('Graph explains sideQuest is not linked to main graph yet',
        (tester) async {
      await _pumpStorylinesShell(
        tester,
        project: _projectWithStorylines([
          StorylineAsset(
            id: 'storyline_existing_main',
            type: StorylineType.main,
            title: 'Existing main',
          ),
        ]),
      );

      await _createSideQuest(tester, title: 'Missing Bell');
      await _createChapter(tester, title: 'Side intro');
      await _createStep(tester, title: 'Find clue');
      await _openGraphTab(tester);

      final graphCanvas = find.byKey(const ValueKey('storylines-graph-canvas'));
      expect(
        find.descendant(of: graphCanvas, matching: find.text('Missing Bell')),
        findsOneWidget,
      );
      expect(
        find.descendant(
            of: graphCanvas, matching: find.text('1 chapitre · 1 étape')),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: graphCanvas,
          matching: find.byKey(
            const ValueKey('storylines-graph-node-chapter-chapter_side_intro'),
          ),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: graphCanvas,
          matching: find.byKey(
            const ValueKey('storylines-graph-node-step-step_find_clue'),
          ),
        ),
        findsOneWidget,
      );
      expect(
        find.text('Quête annexe indépendante'),
        findsOneWidget,
      );
      expect(
        find.descendant(of: graphCanvas, matching: find.text('Existing main')),
        findsNothing,
      );
      expect(find.textContaining('availability'), findsNothing);
    });

    testWidgets('main graph does not show sideQuest as a branch yet',
        (tester) async {
      await _pumpStorylinesShell(
        tester,
        project: _projectWithStorylines([
          StorylineAsset(
            id: 'storyline_existing_main',
            type: StorylineType.main,
            title: 'Existing main',
          ),
        ]),
      );

      await _createSideQuest(tester, title: 'Missing Bell');
      await tester.tap(
        find.byKey(const ValueKey('storylines-v1-row-storyline_existing_main')),
      );
      await tester.pump();
      await _openGraphTab(tester);

      final graphCanvas = find.byKey(const ValueKey('storylines-graph-canvas'));
      expect(
        find.descendant(of: graphCanvas, matching: find.text('Existing main')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: graphCanvas, matching: find.text('Missing Bell')),
        findsNothing,
      );
      expect(
        find.text(
          'Quêtes annexes créées : 1 — attachement explicite requis',
        ),
        findsOneWidget,
      );
    });

    testWidgets('attaches sideQuest to an explicit main step anchor',
        (tester) async {
      final harness = await _pumpStorylinesShell(tester);

      await _createMainStoryline(tester, title: 'Main Path');
      await _createChapter(tester, title: 'Opening');
      await _createStep(tester, title: 'Signal');
      await _createSideQuest(tester, title: 'Lost Charm');

      final beforeScenarios = harness.project.scenarios;
      await _openStructureTab(tester);
      await tester.tap(
        find.byKey(const ValueKey('storylines-attach-sidequest-action')),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('storylines-attach-sidequest-dialog')),
          findsOneWidget);
      expect(find.text('Attacher la quête annexe'), findsOneWidget);
      expect(find.text('Main Path'), findsWidgets);
      expect(find.text('Chapitre · Opening'), findsOneWidget);
      expect(find.text('Étape · Signal'), findsOneWidget);

      await tester.tap(
        find.byKey(const ValueKey('storylines-attach-anchor-step-step_signal')),
      );
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('storylines-attach-submit')));
      await tester.pumpAndSettle();

      final main = harness.project.storylines.singleWhere(
        (storyline) => storyline.type == StorylineType.main,
      );
      final sideQuest = harness.project.storylines.singleWhere(
        (storyline) => storyline.type == StorylineType.sideQuest,
      );
      expect(main.relationships, isEmpty);
      expect(sideQuest.relationships, hasLength(1));
      final relationship = sideQuest.relationships.single;
      expect(relationship.kind,
          StorylineRelationshipKind.sideQuestAvailableDuring);
      expect(relationship.sourceStorylineId, sideQuest.id);
      expect(relationship.targetStorylineId, main.id);
      expect(relationship.anchor?.kind, StorylineAnchorKind.step);
      expect(relationship.anchor?.targetId, 'step_signal');
      expect(relationship.availability?.startAnchor.kind,
          StorylineAnchorKind.step);
      expect(relationship.availability?.startAnchor.targetId, 'step_signal');
      expect(sideQuest.sceneLinks, isEmpty);
      expect(harness.project.scenarios, beforeScenarios);
      expect(find.text('Reliée au graph principal'), findsWidgets);
    });

    testWidgets('attached sideQuest appears in main graph from relation only',
        (tester) async {
      final harness = await _pumpStorylinesShell(tester);

      await _createMainStoryline(tester, title: 'Main Path');
      await _createChapter(tester, title: 'Opening');
      await _createStep(tester, title: 'Signal');
      await _createSideQuest(tester, title: 'Lost Charm');
      await _attachSideQuestToAnchor(
        tester,
        anchorKey: 'storylines-attach-anchor-step-step_signal',
      );

      await tester.tap(
        find.byKey(const ValueKey('storylines-v1-row-storyline_main_path')),
      );
      await tester.pump();
      await _openGraphTab(tester);

      final graphCanvas = find.byKey(const ValueKey('storylines-graph-canvas'));
      expect(
        find.descendant(of: graphCanvas, matching: find.text('Main Path')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: graphCanvas, matching: find.text('Lost Charm')),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: graphCanvas,
          matching: find.byKey(
            const ValueKey(
                'storylines-graph-node-sidequest-sidequest_lost_charm'),
          ),
        ),
        findsOneWidget,
      );
      expect(find.text('Quêtes annexes attachées : 1'), findsOneWidget);
      expect(
        find.byKey(
          const ValueKey(
            'storylines-graph-legend-sidequest-availability',
          ),
        ),
        findsOneWidget,
      );
      expect(find.text('Disponibilité quête annexe'), findsOneWidget);
      expect(find.textContaining('Disponible depuis Étape · Signal'),
          findsOneWidget);
      expect(find.textContaining('Quête annexe · 0 chapitres · 0 étapes'),
          findsOneWidget);
      expect(
        find.byKey(
          ValueKey(
            'storylines-graph-edge-sidequest-'
            '${harness.project.storylines.singleWhere((s) => s.type == StorylineType.sideQuest).relationships.single.id}',
          ),
        ),
        findsOneWidget,
      );
      expect(
        harness.project.storylines
            .singleWhere((s) => s.type == StorylineType.sideQuest)
            .relationships,
        hasLength(1),
      );
    });

    testWidgets('canceling sideQuest attachment does not mutate project',
        (tester) async {
      final harness = await _pumpStorylinesShell(tester);

      await _createMainStoryline(tester, title: 'Main Path');
      await _createChapter(tester, title: 'Opening');
      await _createSideQuest(tester, title: 'Lost Charm');
      final before = harness.project.toJson();

      await _openStructureTab(tester);
      await tester.tap(
        find.byKey(const ValueKey('storylines-attach-sidequest-action')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('storylines-attach-cancel')));
      await tester.pumpAndSettle();

      expect(harness.project.toJson(), before);
      expect(
        harness.project.storylines
            .singleWhere((s) => s.type == StorylineType.sideQuest)
            .relationships,
        isEmpty,
      );
    });

    testWidgets('generates stable unique main ids on collision',
        (tester) async {
      final harness = await _pumpStorylinesShell(
        tester,
        project: _projectWithStorylines([
          StorylineAsset(
            id: 'storyline_main_story',
            type: StorylineType.sideQuest,
            title: 'Existing secondary',
          ),
        ]),
      );

      await _createMainStoryline(tester, title: 'Main Story');

      final ids = harness.project.storylines.map((s) => s.id).toList();
      expect(ids, contains('storyline_main_story'));
      expect(ids, contains('storyline_main_story_2'));
      expect(ids.toSet(), hasLength(ids.length));
      expect(
        harness.project.storylines
            .where((s) => s.type == StorylineType.sideQuest),
        hasLength(1),
      );
    });

    testWidgets('generates stable unique sideQuest ids on collision',
        (tester) async {
      final harness = await _pumpStorylinesShell(
        tester,
        project: _projectWithStorylines([
          StorylineAsset(
            id: 'storyline_existing_main',
            type: StorylineType.main,
            title: 'Existing main',
          ),
        ]),
      );

      await _createSideQuest(tester, title: 'Lost Key');
      await _createSideQuest(tester, title: 'Lost Key');

      final ids = harness.project.storylines.map((s) => s.id).toList();
      expect(ids, contains('sidequest_lost_key'));
      expect(ids, contains('sidequest_lost_key_2'));
      expect(ids.toSet(), hasLength(ids.length));
      expect(
        harness.project.storylines.where(
          (storyline) => storyline.type == StorylineType.sideQuest,
        ),
        hasLength(2),
      );
    });

    testWidgets('does not allow creating a second main storyline',
        (tester) async {
      final harness = await _pumpStorylinesShell(
        tester,
        project: _projectWithStorylines([
          StorylineAsset(
            id: 'storyline_existing_main',
            type: StorylineType.main,
            title: 'Existing main',
          ),
        ]),
      );

      await _openCreateDialog(tester);
      expect(find.text('Une histoire principale existe déjà.'), findsWidgets);
      await tester
          .tap(find.byKey(const ValueKey('storylines-create-type-main')));
      await tester.pump();
      await tester.enterText(
        find.byKey(const ValueKey('storylines-create-title-field')),
        'Second main',
      );
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('storylines-create-submit')));
      await tester.pumpAndSettle();

      expect(
        harness.project.storylines
            .where((storyline) => storyline.type == StorylineType.main),
        hasLength(1),
      );
      expect(
        harness.project.storylines
            .where((storyline) => storyline.type == StorylineType.sideQuest),
        hasLength(1),
      );
    });

    testWidgets('creation does not import legacy or promote localEventFlow',
        (tester) async {
      final harness = await _pumpStorylinesShell(
        tester,
        project: _legacyAndLocalEventProject(),
      );

      await _createMainStoryline(tester, title: 'Fresh Main Story');

      expect(harness.project.storylines, hasLength(1));
      expect(harness.project.storylines.single.title, 'Fresh Main Story');
      expect(harness.project.storylines.single.legacySource, isNull);
      expect(
        harness.project.storylines
            .where((s) => s.type == StorylineType.sideQuest),
        isEmpty,
      );
      expect(harness.project.scenarios, hasLength(2));
      expect(
        harness.project.scenarios.map((scenario) => scenario.scope),
        containsAll([ScenarioScope.globalStory, ScenarioScope.localEventFlow]),
      );
      expect(find.text('Legacy Global Story'), findsNothing);
      expect(find.text('Local Event Flow'), findsNothing);
    });

    testWidgets('sideQuest creation never imports legacy or localEventFlow',
        (tester) async {
      final base = _legacyAndLocalEventProject();
      final project = ProjectManifest(
        surfaceCatalog: const ProjectSurfaceCatalog.empty(),
        name: 'Legacy With Main',
        maps: const <ProjectMapEntry>[],
        tilesets: const <ProjectTilesetEntry>[],
        scenarios: base.scenarios,
        storylines: [
          StorylineAsset(
            id: 'storyline_existing_main',
            type: StorylineType.main,
            title: 'Existing main',
          ),
        ],
      );
      final harness = await _pumpStorylinesShell(tester, project: project);
      final beforeScenarios = harness.project.scenarios;

      await _createSideQuest(tester, title: 'Missing Bell');

      expect(harness.project.scenarios, beforeScenarios);
      expect(harness.project.storylines, hasLength(2));
      expect(
        harness.project.storylines
            .singleWhere(
                (storyline) => storyline.type == StorylineType.sideQuest)
            .legacySource,
        isNull,
      );
      expect(find.text('Legacy Global Story'), findsNothing);
      expect(find.text('Local Event Flow'), findsNothing);
    });

    testWidgets('Graph, Structure and disabled future actions do not mutate',
        (tester) async {
      final harness = await _pumpStorylinesShell(
        tester,
        project: _projectWithStorylines([
          StorylineAsset(
            id: 'storyline_existing_main',
            type: StorylineType.main,
            title: 'Existing main',
          ),
        ]),
      );
      final before = harness.project.toJson();
      final beforeMode = harness.editorState.workspaceMode;

      await _openStructureTab(tester);
      final linkSceneButton = find.byKey(
        const ValueKey('storylines-link-scene-disabled'),
      );
      expect(linkSceneButton, findsOneWidget);
      expect(tester.widget<PokeMapButton>(linkSceneButton).onPressed, isNull);

      await _openGraphTab(tester);

      expect(harness.project.toJson(), before);
      expect(harness.editorState.workspaceMode, beforeMode);
    });

    testWidgets('Structure authoring does not import legacy or localEventFlow',
        (tester) async {
      final project = ProjectManifest(
        surfaceCatalog: const ProjectSurfaceCatalog.empty(),
        name: 'Legacy With Authoring',
        maps: const <ProjectMapEntry>[],
        tilesets: const <ProjectTilesetEntry>[],
        scenarios: _legacyAndLocalEventProject().scenarios,
        storylines: [
          StorylineAsset(
            id: 'storyline_existing_main',
            type: StorylineType.main,
            title: 'Existing main',
          ),
        ],
      );
      final harness = await _pumpStorylinesShell(tester, project: project);
      final beforeScenarios = harness.project.scenarios;

      await _createChapter(tester, title: 'Intro');
      await _createStep(tester, title: 'Premier jalon');

      expect(harness.project.scenarios, beforeScenarios);
      expect(harness.project.storylines, hasLength(1));
      expect(harness.project.storylines.single.legacySource, isNull);
      expect(
        harness.project.storylines
            .where((s) => s.type == StorylineType.sideQuest),
        isEmpty,
      );
      expect(harness.project.storylines.single.sceneLinks, isEmpty);
      expect(find.text('Local Event Flow'), findsNothing);
      expect(find.text('Legacy Global Story'), findsNothing);
    });

    testWidgets('keeps target fake data and Maps out of the V1 UI',
        (tester) async {
      await _pumpStorylinesShell(tester,
          project: _legacyAndLocalEventProject());

      for (final value in _targetOnlyStrings) {
        expect(find.text(value), findsNothing, reason: value);
      }
      expect(find.text('Maps'), findsNothing);
    });

    test('storylines UI source keeps raw colors out of the feature', () {
      final sources = [
        File('lib/src/ui/canvas/storylines_workspace.dart'),
        File('lib/src/ui/canvas/storylines/storylines_graph_model.dart'),
        File('lib/src/ui/canvas/storylines/storylines_graph_painter.dart'),
        File('lib/src/ui/canvas/storylines/storylines_graph_view.dart'),
      ];
      const rawColorPattern = 'Color' '(0x';
      const materialColorsPattern = 'Colors' '.';

      for (final source in sources) {
        expect(source.existsSync(), isTrue, reason: source.path);

        final contents = source.readAsStringSync();
        expect(contents, isNot(contains(rawColorPattern)), reason: source.path);
        expect(contents, isNot(contains(materialColorsPattern)),
            reason: source.path);
      }
    });

    test('storylines shell test keeps raw colors out', () {
      final source = File('test/storylines_workspace_shell_test.dart');
      expect(source.existsSync(), isTrue);

      final contents = source.readAsStringSync();
      const rawColorPattern = 'Color' '(0x';
      const materialColorsPattern = 'Colors' '.';
      expect(contents, isNot(contains(rawColorPattern)));
      expect(contents, isNot(contains(materialColorsPattern)));
    });

    testWidgets('uses PokeMap dark theme in the Visual Gate harness',
        (tester) async {
      await _pumpStorylinesShell(tester);

      final shellContext = tester.element(
        find.byKey(const ValueKey('storylines-workspace-shell')),
      );
      expect(Theme.of(shellContext).brightness, Brightness.dark);
    });

    testWidgets('writes V1-12 polished graph screenshots', (tester) async {
      await _pumpStorylinesShell(
        tester,
        surfaceSize: const Size(1600, 1000),
        project: _projectWithStorylines([
          StorylineAsset(
            id: 'storyline_empty_visual',
            type: StorylineType.main,
            title: 'Empty Visual Main',
          ),
        ]),
      );
      await expectLater(
        find.byKey(const ValueKey('storylines-workspace-shell')),
        matchesGoldenFile(
          '../../../reports/narrativeStudio/storylines/screenshots/'
          'ns_storylines_v1_12_graph_empty_polished.png',
        ),
      );

      await _pumpStorylinesShell(
        tester,
        surfaceSize: const Size(1600, 1000),
        project: _visualGraphProject(),
      );
      await expectLater(
        find.byKey(const ValueKey('storylines-workspace-shell')),
        matchesGoldenFile(
          '../../../reports/narrativeStudio/storylines/screenshots/'
          'ns_storylines_v1_12_graph_main_polished.png',
        ),
      );

      await tester.tap(
        find.byKey(const ValueKey('storylines-v1-row-sidequest_visual')),
      );
      await tester.pump();
      await _openStructureTab(tester);
      await tester.tap(
        find.byKey(const ValueKey('storylines-attach-sidequest-action')),
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(
          const ValueKey(
            'storylines-attach-anchor-step-step_visual_choice',
          ),
        ),
      );
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('storylines-attach-submit')));
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const ValueKey('storylines-v1-row-storyline_visual_main')),
      );
      await tester.pump();
      await _openGraphTab(tester);
      await expectLater(
        find.byKey(const ValueKey('storylines-workspace-shell')),
        matchesGoldenFile(
          '../../../reports/narrativeStudio/storylines/screenshots/'
          'ns_storylines_v1_12_graph_sidequest_attached_polished.png',
        ),
      );

      await tester.tap(
        find.byKey(const ValueKey('storylines-v1-row-sidequest_visual')),
      );
      await tester.pump();
      await _openGraphTab(tester);
      await expectLater(
        find.byKey(const ValueKey('storylines-workspace-shell')),
        matchesGoldenFile(
          '../../../reports/narrativeStudio/storylines/screenshots/'
          'ns_storylines_v1_12_graph_sidequest_standalone_polished.png',
        ),
      );
    });
  });
}

const _targetOnlyStrings = <String>[
  'Histoire globale',
  'La brume du phare',
  'Le port',
  'Les marais',
  'Le phare',
  'Les cristaux de sel',
  'Le Goélise du port',
  'La cabane du phare',
  'Mystère',
  'Exploration',
  'Phare',
  'Côtiers',
  '5 chapitres',
  '27 scènes',
  '412 dialogues',
  '18 facts',
  '3 problèmes',
  'Active',
  'Haute',
  'Validé',
  'Défini',
  'En cours',
  'Quête annexe fake',
];

Future<void> _openCreateDialog(WidgetTester tester) async {
  await tester.tap(find.byKey(const ValueKey('storylines-create-main-cta')));
  await tester.pumpAndSettle();
}

Future<void> _createMainStoryline(
  WidgetTester tester, {
  required String title,
  String? description,
}) async {
  await _openCreateDialog(tester);
  await tester.enterText(
    find.byKey(const ValueKey('storylines-create-title-field')),
    title,
  );
  if (description != null) {
    await tester.enterText(
      find.byKey(const ValueKey('storylines-create-description-field')),
      description,
    );
  }
  await tester.pump();
  await tester.tap(find.byKey(const ValueKey('storylines-create-submit')));
  await tester.pumpAndSettle();
}

Future<void> _createSideQuest(
  WidgetTester tester, {
  required String title,
  String? description,
}) async {
  await _openCreateDialog(tester);
  await tester
      .tap(find.byKey(const ValueKey('storylines-create-type-sidequest')));
  await tester.pump();
  await tester.enterText(
    find.byKey(const ValueKey('storylines-create-title-field')),
    title,
  );
  if (description != null) {
    await tester.enterText(
      find.byKey(const ValueKey('storylines-create-description-field')),
      description,
    );
  }
  await tester.pump();
  await tester.tap(find.byKey(const ValueKey('storylines-create-submit')));
  await tester.pumpAndSettle();
}

Future<void> _attachSideQuestToAnchor(
  WidgetTester tester, {
  required String anchorKey,
}) async {
  await _openStructureTab(tester);
  await tester.tap(
    find.byKey(const ValueKey('storylines-attach-sidequest-action')),
  );
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(ValueKey(anchorKey)));
  await tester.pump();
  await tester.tap(find.byKey(const ValueKey('storylines-attach-submit')));
  await tester.pumpAndSettle();
}

Future<void> _openCreateChapterDialog(WidgetTester tester) async {
  await _openStructureTab(tester);
  await tester.tap(find.byKey(const ValueKey('storylines-new-chapter-action')));
  await tester.pumpAndSettle();
}

Future<void> _createChapter(
  WidgetTester tester, {
  required String title,
  String? description,
}) async {
  await _openCreateChapterDialog(tester);
  await tester.enterText(
    find.byKey(const ValueKey('storylines-create-chapter-title-field')),
    title,
  );
  if (description != null) {
    await tester.enterText(
      find.byKey(const ValueKey('storylines-create-chapter-description-field')),
      description,
    );
  }
  await tester.pump();
  await tester
      .tap(find.byKey(const ValueKey('storylines-create-chapter-submit')));
  await tester.pumpAndSettle();
}

Future<void> _openCreateStepDialog(WidgetTester tester) async {
  await _openStructureTab(tester);
  final newStepAction =
      find.byKey(const ValueKey('storylines-new-step-action'));
  await tester.ensureVisible(newStepAction);
  await tester.tap(newStepAction);
  await tester.pumpAndSettle();
}

Future<void> _createStep(
  WidgetTester tester, {
  required String title,
  String? description,
}) async {
  await _openCreateStepDialog(tester);
  await tester.enterText(
    find.byKey(const ValueKey('storylines-create-step-title-field')),
    title,
  );
  if (description != null) {
    await tester.enterText(
      find.byKey(const ValueKey('storylines-create-step-description-field')),
      description,
    );
  }
  await tester.pump();
  await tester.tap(find.byKey(const ValueKey('storylines-create-step-submit')));
  await tester.pumpAndSettle();
}

Future<void> _openStructureTab(WidgetTester tester) async {
  await tester.tap(
    find.descendant(
      of: find.byKey(const ValueKey('storylines-tabs')),
      matching: find.text('Structure'),
    ),
  );
  await tester.pump();
}

Future<void> _openGraphTab(WidgetTester tester) async {
  await tester.tap(
    find.descendant(
      of: find.byKey(const ValueKey('storylines-tabs')),
      matching: find.text('Graph'),
    ),
  );
  await tester.pump();
}

Future<_StorylinesHarness> _pumpStorylinesShell(
  WidgetTester tester, {
  Size surfaceSize = const Size(1600, 1000),
  ProjectManifest? project,
}) async {
  await tester.binding.setSurfaceSize(surfaceSize);
  addTearDown(() => tester.binding.setSurfaceSize(null));

  final container = ProviderContainer();
  addTearDown(container.dispose);
  final editorSubscription = container.listen(
    editorNotifierProvider,
    (_, __) {},
  );
  addTearDown(editorSubscription.close);

  container.read(editorNotifierProvider.notifier).state = EditorState(
    project: project ?? _emptyStorylinesProject(),
    workspaceMode: EditorWorkspaceMode.globalStory,
  );
  container
      .read(narrativeWorkspaceControllerProvider.notifier)
      .openGlobalStory();

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        theme: PokeMapTheme.light(),
        darkTheme: PokeMapTheme.dark(),
        themeMode: ThemeMode.dark,
        home: Scaffold(
          body: SizedBox(
            width: surfaceSize.width,
            height: surfaceSize.height,
            child: const NarrativeWorkspaceCanvas(),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
  await tester.pump();

  return _StorylinesHarness(container);
}

ProjectManifest _emptyStorylinesProject() {
  return const ProjectManifest(
    surfaceCatalog: ProjectSurfaceCatalog.empty(),
    name: 'Audit Project',
    maps: <ProjectMapEntry>[],
    tilesets: <ProjectTilesetEntry>[],
  );
}

ProjectManifest _legacyOnlyProject() {
  return const ProjectManifest(
    surfaceCatalog: ProjectSurfaceCatalog.empty(),
    name: 'Legacy Project',
    maps: <ProjectMapEntry>[],
    tilesets: <ProjectTilesetEntry>[],
    scenarios: <ScenarioAsset>[
      ScenarioAsset(
        id: 'legacy_global_story',
        name: 'Legacy Global Story',
        description: 'Legacy description',
        scope: ScenarioScope.globalStory,
        entryNodeId: 'start',
      ),
    ],
  );
}

ProjectManifest _legacyAndLocalEventProject() {
  return const ProjectManifest(
    surfaceCatalog: ProjectSurfaceCatalog.empty(),
    name: 'Legacy Project',
    maps: <ProjectMapEntry>[],
    tilesets: <ProjectTilesetEntry>[],
    scenarios: <ScenarioAsset>[
      ScenarioAsset(
        id: 'legacy_global_story',
        name: 'Legacy Global Story',
        description: 'Legacy description',
        scope: ScenarioScope.globalStory,
        entryNodeId: 'start',
      ),
      ScenarioAsset(
        id: 'local_event_flow',
        name: 'Local Event Flow',
        description: 'Must not become side quest',
        scope: ScenarioScope.localEventFlow,
        entryNodeId: 'local_start',
      ),
    ],
  );
}

ProjectManifest _projectWithStorylines(List<StorylineAsset> storylines) {
  return ProjectManifest(
    surfaceCatalog: const ProjectSurfaceCatalog.empty(),
    name: 'Storylines Project',
    maps: const <ProjectMapEntry>[],
    tilesets: const <ProjectTilesetEntry>[],
    storylines: storylines,
  );
}

ProjectManifest _visualGraphProject() {
  return _projectWithStorylines([
    StorylineAsset(
      id: 'storyline_visual_main',
      type: StorylineType.main,
      title: 'Visual Main',
      description: 'Graph generated from authoring structure.',
      chapters: [
        StorylineChapter(
          id: 'chapter_visual_start',
          title: 'Opening',
          description: 'First authoring beat.',
          order: 0,
          steps: [
            StorylineStep(
              id: 'step_visual_arrival',
              title: 'Arrival',
              description: 'Introduce the player goal.',
              order: 0,
            ),
            StorylineStep(
              id: 'step_visual_choice',
              title: 'First choice',
              order: 1,
            ),
          ],
        ),
        StorylineChapter(
          id: 'chapter_visual_followup',
          title: 'Follow-up',
          order: 1,
          steps: [
            StorylineStep(
              id: 'step_visual_resolution',
              title: 'Resolution',
              order: 0,
            ),
          ],
        ),
      ],
    ),
    StorylineAsset(
      id: 'sidequest_visual',
      type: StorylineType.sideQuest,
      title: 'Visual Side Quest',
      description: 'Standalone optional storyline.',
      chapters: [
        StorylineChapter(
          id: 'chapter_visual_side',
          title: 'Side opening',
          order: 0,
          steps: [
            StorylineStep(
              id: 'step_visual_side_clue',
              title: 'Find clue',
              order: 0,
            ),
          ],
        ),
      ],
    ),
  ]);
}

class _StorylinesHarness {
  const _StorylinesHarness(this.container);

  final ProviderContainer container;

  EditorState get editorState => container.read(editorNotifierProvider);

  ProjectManifest get project => editorState.project!;
}

```

### reports/narrativeStudio/storylines/road_map_storylines.md

```text
# Narrative Studio Storylines Roadmap

## 1. Purpose

Cette roadmap est le fichier vivant de référence du chantier `Narrative Studio / Storylines V0`.

Elle sert à :

- remplacer progressivement l'ancien `Global Story Studio v1` ;
- préparer une UI proche des cibles `1 - global storyline.png` et `2 - chapitres.png` ;
- commencer par un read model / data contract avant toute refonte UI ;
- éviter les données fake ;
- imposer le design system PokeMap à chaque lot Storylines.

Chaque futur lot Storylines doit lire, respecter et mettre à jour ce fichier.

## 2. Canonical context

Contexte fermé :

```text
NS-HOME / Narrative Studio Aperçu V0 : fermé
```

Audit fondateur :

```text
reports/narrativeStudio/storylines/ns_storylines_00_current_state_target_gap_audit.md
```

Constats canoniques :

- l'écran actuel est encore l'ancien `GlobalStoryStudioWorkspace` ;
- il ne faut pas commencer par une refonte UI directe ;
- il faut d'abord définir un read model / data contract ;
- beaucoup de données visibles dans la cible seraient fake aujourd'hui ;
- la séparation `ProjectExplorerPanel` global / `NarrativeStudioSidebar` interne reste obligatoire ;
- le design system PokeMap est obligatoire.

Architecture canonique :

```text
ProjectExplorerPanel = sidebar globale PokeMap
NarrativeStudioSidebar = sidebar interne Narrative Studio
```

## 3. Non-negotiable guardrails

- Ne pas rouvrir ou repolir la page `Aperçu`.
- Ne pas transformer `ProjectExplorerPanel` en sidebar Storylines.
- Ne pas déplacer `NarrativeStudioSidebar` dans `ProjectExplorerPanel`.
- Ne pas modifier `map_runtime`, `map_gameplay`, `map_battle` pour Storylines V0.
- Ne pas utiliser `GameState` runtime comme source d'authoring.
- Ne pas activer `Nouvelle storyline` sans vrai modèle et flow.
- Ne pas activer `Valider` sans validation globale réelle.
- Ne pas créer de recherche, notification, badge, tags, facts, world rules ou activité récente fake.
- Ne pas copier les données de l'image cible dans le code produit.

Données explicitement interdites en hardcode feature :

```text
Histoire globale
La brume du phare
Le port
Les marais
Le phare
Les cristaux de sel
Le Goélise du port
La cabane du phare
Mystère
Exploration
Phare
Côtiers
5 chapitres
27 scènes
412 dialogues
18 facts
3 problèmes
activité récente
world rules affectées
```

Si une démo riche est nécessaire plus tard, elle doit être un lot dédié, une fixture explicite, isolée, testée et non mélangée au code produit.

## 4. Design System Guardrails

Règle d'or :

```text
Toute UI Storylines doit utiliser le design system PokeMap.
```

Interdit :

- widget générique ad hoc dans Storylines ;
- mini design system caché dans la feature ;
- duplication locale de cards, pills, tabs, panels, icon tiles, inspector sections ou KPI cards ;
- `Color(0x...)` ajouté dans une feature ;
- `Colors.*` ajouté dans une feature ;
- couleur locale hardcodée.

Autorisé :

- primitives PokeMap existantes ;
- primitives editor partagées existantes ;
- nouvelle primitive uniquement si créée/étendue dans le design system avant usage feature.

Primitives stables observées :

- `PokeMapColorTokens`
- `PokeMapTheme`
- `EditorChrome`
- `EditorPaneSurface`
- `EditorSidebarSectionTitle`
- `EditorSidebarListRow`
- `EditorHorizontalDivider`
- `EditorVerticalDivider`
- `EditorToolbarIconButton`
- `EditorVisualTokens`

Primitives design-system observées dans le worktree local au bootstrap, à revérifier au début de chaque lot car elles sont préexistantes/non trackées ou en cours :

- `PokeMapTone`
- `PokeMapToneColors`
- `PokeMapPageSurface`
- `PokeMapIconTile`
- `PokeMapMetricCard`
- `PokeMapModuleCard`
- `PokeMapStatusTile`
- `PokeMapInspectorPanel`
- `PokeMapSegmentedTab`
- `PokeMapSegmentedTabs`

Chemins demandés mais absents exactement :

```text
packages/map_editor/lib/src/ui/shared/pokemap_tone.dart
packages/map_editor/lib/src/ui/shared/pokemap_dashboard_primitives.dart
```

Équivalents observés :

```text
packages/map_editor/lib/src/ui/design_system/pokemap_tone.dart
packages/map_editor/lib/src/ui/design_system/pokemap_dashboard_primitives.dart
```

### Design System Gate

Chaque lot UI Storylines doit confirmer :

```text
- [ ] Aucun Color(0x...) ajouté dans une feature.
- [ ] Aucun Colors.* ajouté dans une feature.
- [ ] Aucun composant générique local ajouté dans Storylines.
- [ ] Primitives PokeMap existantes utilisées quand disponibles.
- [ ] Nouvelle primitive éventuelle créée dans le design system, pas dans la feature.
- [ ] Tons via PokeMapTone / tokens / context.pokeMapColors.
- [ ] Surfaces via EditorChrome / PokeMap tokens / composants partagés.
- [ ] Tests design-system pertinents lancés ou skip justifié.
- [ ] Rapport inclut un mini audit design system.
```

Si ce gate ne peut pas être respecté, le lot doit s'arrêter et recommander un lot design-system préalable.

## 5. Current state summary

État réel actuel :

```text
EditorWorkspaceMode.globalStory
→ NarrativeWorkspaceCanvas
→ NarrativeStudioShell
→ GlobalStoryStudioWorkspace
→ GlobalStoryStudioShell
```

UI actuelle :

- `Global Story Workspace` ;
- panel `STRUCTURE / Votre récit` ;
- canvas `FIL NARRATIF / Progression globale` ;
- inspecteur `DÉTAIL DE L'ÉTAPE` ;
- un seul global story ;
- logique chapters + steps ;
- beaucoup de vide ;
- inspecteur centré sur la step, pas sur la storyline.

Données réellement disponibles ou partielles :

- `ProjectManifest.scenarios`
- `ScenarioAsset(scope == globalStory)`
- `ScenarioAsset(scope == localEventFlow)`
- `ScenarioAsset.name`
- `ScenarioAsset.description`
- `ScenarioAsset.nodes`
- `ScenarioAsset.edges`
- `ScenarioAsset.metadata`
- `GlobalStoryStudioDocument`
- `GlobalStoryChapter`
- `GlobalStoryStepNode`
- `GlobalStoryStepLink`
- `StepStudioDocument`
- `StepStudioStep`
- `StepStudioCutsceneLink`
- `StepStudioOutcomeDefinition`
- `StepStudioWorldChange`
- `ProjectManifest.dialogues`
- `ProjectManifest.scripts`
- `NarrativeWorkspaceProjection`

Données absentes ou trop risquées :

- liste de storylines multiples ;
- type de storyline ;
- priorité ;
- statut storyline fiable ;
- quêtes annexes ;
- tags ;
- facts modifiés ;
- world rules affectées ;
- activité récente ;
- validation globale Storylines ;
- statistiques Storylines ;
- tests Storylines ;
- graph riche avec mini-map et zoom.

## 6. Target state summary

Cible Graph :

- panneau secondaire Storylines ;
- breadcrumb `Narrative Studio > Storylines > Histoire globale` ;
- header storyline ;
- tabs `Graph`, `Chapitres`, `Étapes`, `Scènes`, `Statistiques`, `Tests` ;
- KPI ;
- graph macro ;
- quêtes annexes liées ;
- mini-map ;
- légende ;
- zoom controls ;
- inspecteur de storyline ;
- tags ;
- world rules affectées ;
- dernière activité.

Cible Chapitres :

- liste de chapitres ;
- chapitre sélectionné ;
- scènes du chapitre ;
- recherche / filtre / tri ;
- bouton `Nouveau chapitre` ;
- inspecteur de chapitre ;
- ordre des scènes ;
- contenu lié ;
- statut éditorial.

Interprétation V0 :

- afficher seulement ce qui est disponible ou dérivable ;
- rendre le reste absent, disabled ou explicitement à venir ;
- ne pas simuler une densité projet avec des données hardcodées ;
- préparer les futurs flows sans les activer.

## 7. Data readiness summary

| Data target | Current readiness | Decision |
|---|---|---|
| Storyline title | Available via `ScenarioAsset.name` | Safe read-only. |
| Storyline description | Available via `ScenarioAsset.description` | Safe read-only. |
| Single global story | Available via `ScenarioScope.globalStory` | Safe read-only. |
| Chapters | Available via `GlobalStoryStudioDocument.chapters` | Safe read-only. |
| Steps | Available via `StepStudioDocument.steps` | Safe read-only, wording prudent. |
| Step links | Partial via `GlobalStoryStepLink` | Safe for limited graph. |
| Cutscenes linked to steps | Available via `StepStudioCutsceneLink` | Safe read-only. |
| Dialogues linked | Partial | Needs read model. |
| Multiple storylines | Missing | Do not fake. |
| Side quests | Missing | Do not fake. |
| Tags | Missing | Do not fake. |
| Priority | Missing | Do not fake. |
| Facts modified | Partial / fake risk | Keep disabled. |
| World rules affected | Partial / fake risk | Keep disabled. |
| Recent activity | Missing | Do not fake. |
| Validation issues | Partial | Use only existing diagnostics. |
| Graph minimap / zoom | Missing UI contract | Later after graph model. |

## 8. Roadmap overview

| Lot | Title | Type | Status | Next |
|---|---|---|---|---|
| NS-STORYLINES-01 | Storylines Read Model / Data Contract V0 | core/design | DONE | NS-STORYLINES-02 |
| NS-STORYLINES-02 | Current Global Story Characterization / Anti-Fake Tests V0 | test/audit | DONE | NS-STORYLINES-03 |
| NS-STORYLINES-03 | Storylines Workspace Shell Layout V0 | editor UI | DONE | NS-STORYLINES-04 |
| NS-STORYLINES-04 | Storylines Secondary List Panel Read-only V0 | editor UI | DONE | NS-STORYLINES-05 |
| NS-STORYLINES-05 | Storyline Header / Tabs / KPI Read-only V0 | editor UI | DONE | NS-STORYLINES-06 |
| NS-STORYLINES-06 | Storyline Graph Read-only Placeholder V0 | editor UI / visual gate | DONE | NS-STORYLINES-07 |
| NS-STORYLINES-07 | Storyline Inspector Read-only V0 | editor UI | DONE | NS-STORYLINES-08 |
| NS-STORYLINES-08 | Chapters Tab Read-only V0 | editor UI | DONE | NS-STORYLINES-09 |
| NS-STORYLINES-09 | Chapters Inspector / Step Ordering Read-only V0 | editor UI | DONE | NS-STORYLINES-10 |
| NS-STORYLINES-10 | Storyline Visual Harmonization / Visual Gate V0 | visual gate | DONE | NS-STORYLINES-11 |
| NS-STORYLINES-11 | Storylines Interaction Wiring V0 | editor UI / test | DONE | NS-STORYLINES-CHECKPOINT |
| NS-STORYLINES-CHECKPOINT | Storylines V0 Acceptance Checkpoint | checkpoint | DONE | NS-STORYLINES-V1-00 |
| NS-STORYLINES-V1-00 | Storyline Semantics Reset / Usable Authoring Contract | product contract | DONE | NS-STORYLINES-V1-01 |
| NS-STORYLINES-V1-01 | Storyline Authoring Model Decision | model decision | DONE | NS-STORYLINES-V1-02 |
| NS-STORYLINES-V1-02 | Storyline Authoring Data Shape Contract | data contract | DONE | NS-STORYLINES-V1-03 |
| NS-STORYLINES-V1-03 | StorylineAsset Pure Model V0 | core model / pure dart | DONE | NS-STORYLINES-V1-04 |
| NS-STORYLINES-V1-04 | StorylineAsset JSON Codec V0 | core codec | DONE | NS-STORYLINES-V1-05 |
| NS-STORYLINES-V1-05 | ProjectManifest.storylines Integration V0 | core manifest | DONE | NS-STORYLINES-V1-06 |
| NS-STORYLINES-V1-06 | Legacy GlobalStory Import Preview V0 | migration preview | DONE | NS-STORYLINES-V1-07 |
| NS-STORYLINES-V1-07 | Create Main Storyline Flow V0 | editor authoring | DONE | NS-STORYLINES-V1-07-bis |
| NS-STORYLINES-V1-07-bis | Storylines Workspace Cleanup / Dead Legacy Removal | editor UI cleanup | DONE | NS-STORYLINES-V1-08 |
| NS-STORYLINES-V1-08 | Structure Tab Authoring V0 | editor authoring | DONE | NS-STORYLINES-V1-09 |
| NS-STORYLINES-V1-09 | Create Side Quest Flow V0 | editor authoring | DONE | NS-STORYLINES-V1-10 |
| NS-STORYLINES-V1-10 | Graph From StorylineAsset V0 | editor graph | DONE | NS-STORYLINES-V1-11 |
| NS-STORYLINES-V1-11 | Side Quest Attachment + Graph Integration V0 | editor graph | DONE | NS-STORYLINES-V1-12 |
| NS-STORYLINES-V1-12 | V1 Visual Graph Enrichment | visual gate | DONE | NS-STORYLINES-V1-CHECKPOINT |
| NS-STORYLINES-V1-CHECKPOINT | Storylines V1 Acceptance Checkpoint | checkpoint | DONE | NS-SCENES-V1 |
| NS-STORYLINES-SEED-00 | Selbrume Storylines Demo Seed V0 | demo data | DONE | NS-SCENES-V1 |
| NS-STORYLINES-SEED-FIX-01 | Selbrume Graph Layout / SideQuest Rendering Fix V0 | editor graph fix | DONE | NS-STORYLINES-SEED-FIX-01-bis |
| NS-STORYLINES-SEED-FIX-01-bis | Graph Focus Layout / Canvas Priority | editor graph layout | DONE | NS-STORYLINES-V1.1-00 |
| NS-STORYLINES-V1.1-00 | Structure Layout / Chapter Step Readability V0 | editor structure layout | DONE | NS-STORYLINES-V1.1-00-bis |
| NS-STORYLINES-V1.1-00-bis | Structure Tab Full-width Accordion Authoring | editor structure authoring | DONE | NS-STORYLINES-V1.1-01 |

## 9. Detailed lots

### NS-STORYLINES-01 — Storylines Read Model / Data Contract V0

- Type : core/design.
- Objectif : définir le read model Storylines V0 ; mapper chaque donnée cible ; décider le vocabulaire `Storyline`, `Chapter`, `Step`, `Scene`, `Quest`, `Map`.
- Fichiers probables : rapport data contract ; éventuellement tests de contrat si prompt autorise du code.
- Non-objectifs : pas d'UI, pas de widget, pas de graph, pas de création storyline.
- Dépendances : NS-STORYLINES-00, cette roadmap.
- Critères d'acceptation : matrice complète, fake risks explicites, décision Maps documentée.
- Tests attendus : aucun si rapport-only ; tests unitaires si read model codé dans un prompt futur.
- Analyse attendue : `git diff --check`; analyze seulement si code.
- Visual Gate : non.
- Risques : inférer trop de données depuis des noms ; confondre `ScenarioAsset` et `Storyline`.
- Design system impact : rappel du gate, pas de code UI.
- Statut : DONE.
- Résultat NS-STORYLINES-01 : contrat de données Storylines V0 documenté dans `reports/narrativeStudio/storylines/ns_storylines_01_read_model_data_contract_v0.md`.
- Fichiers créés : `reports/narrativeStudio/storylines/ns_storylines_01_read_model_data_contract_v0.md`.
- Fichiers modifiés : `reports/narrativeStudio/storylines/road_map_storylines.md`.
- Code : aucun fichier Dart modifié.
- Tests/analyze : non lancés, car lot documentation-only / no-code / no-test-change.
- Design System Gate : confirmé pour les futurs lots UI ; aucune couleur hardcodée ajoutée.
- Fake data : aucune donnée cible ou fixture Selbrume ajoutée ; les champs `Missing` / `Fake risk` restent disabled, cachés ou reportés.
- Prochain lot attendu : NS-STORYLINES-02.

### NS-STORYLINES-02 — Current Global Story Characterization / Anti-Fake Tests V0

- Type : test/audit.
- Objectif : verrouiller l'ancien écran et prouver que les données viennent du manifest / metadata.
- Fichiers probables : tests `global_story_studio_*`, rapport de caractérisation.
- Non-objectifs : pas de refonte UI, pas de nouveau modèle, pas de fixtures cible.
- Dépendances : NS-STORYLINES-01.
- Critères d'acceptation : comportements actuels caractérisés, anti-fake explicite.
- Tests attendus : tests Global Story existants + navigation/shell pertinents.
- Analyse attendue : `flutter analyze` ciblé si code/tests touchés ; `git diff --check`.
- Visual Gate : optionnel.
- Risques : figer une UI destinée à être remplacée.
- Design system impact : aucun nouveau composant local.
- Statut : DONE.
- Résultat NS-STORYLINES-02 : ajout d'un test de caractérisation anti-fake qui verrouille l'ancien Global Story Studio sans toucher au code production.
- Fichiers créés : `packages/map_editor/test/storylines_current_global_story_characterization_test.dart`, `reports/narrativeStudio/storylines/ns_storylines_02_current_global_story_characterization_anti_fake_tests_v0.md`.
- Fichiers modifiés : `reports/narrativeStudio/storylines/road_map_storylines.md`.
- Code production : aucun fichier `packages/map_editor/lib`, `map_core`, `map_runtime`, `map_gameplay` ou `map_battle` modifié.
- Tests exécutés : `flutter test test/storylines_current_global_story_characterization_test.dart`, régression groupée Global Story / Projection.
- Analyse exécutée : `flutter analyze test/storylines_current_global_story_characterization_test.dart`.
- Design System Gate : confirmé ; aucun widget production, aucune couleur, aucune primitive design system modifiée.
- Fake data : aucune donnée cible ajoutée ; les chaînes cible sont assertées absentes quand la fixture neutre ne les contient pas.
- Prochain lot attendu : NS-STORYLINES-03.

### NS-STORYLINES-03 — Storylines Workspace Shell Layout V0

- Type : editor UI.
- Objectif : poser le layout Storylines V0 : secondary list panel, main area, inspector.
- Fichiers probables : `narrative_workspace_canvas.dart`, widgets Storylines, tests UI, rapport.
- Non-objectifs : pas de graph riche, pas de création storyline, pas de validation globale.
- Dépendances : NS-STORYLINES-01, NS-STORYLINES-02.
- Critères d'acceptation : layout visible, `ProjectExplorerPanel` global, `NarrativeStudioSidebar` interne, Design System Gate respecté.
- Tests attendus : widget tests shell, navigation, disabled states, absence de fake.
- Analyse attendue : `flutter analyze`, `git diff --check`.
- Visual Gate : desktop + focus.
- Risques : créer un shell visuel sans source de données.
- Design system impact : fort ; bloquer si primitive manquante.
- Statut : DONE.
- Résultat NS-STORYLINES-03 : premier shell Storylines V0 livré et branché sur `EditorWorkspaceMode.globalStory`, avec panneau secondaire, zone centrale et inspecteur placeholder.
- Fichiers créés : `packages/map_editor/lib/src/ui/canvas/storylines_workspace.dart`, `packages/map_editor/test/storylines_workspace_shell_test.dart`, captures Visual Gate sous `reports/narrativeStudio/storylines/screenshots/`.
- Fichiers modifiés : `packages/map_editor/lib/src/ui/canvas/narrative_workspace_canvas.dart`, `packages/map_editor/test/storylines_current_global_story_characterization_test.dart`, `reports/narrativeStudio/storylines/road_map_storylines.md`.
- Données : `ScenarioAsset.name`, `ScenarioAsset.description`, nombre réel de global stories et nombre dérivé de steps affichés ; aucune donnée cible hardcodée.
- Tests exécutés : `flutter test test/storylines_workspace_shell_test.dart`, `flutter test test/storylines_current_global_story_characterization_test.dart`, `flutter test test/global_story_studio_workspace_test.dart`, `flutter test test/narrative_workspace_projection_test.dart`.
- Analyse exécutée : `flutter analyze` global lancé et échoué sur dette préexistante ; analyse ciblée des fichiers touchés propre.
- Visual Gate : `ns_storylines_03_shell_desktop.png`, `ns_storylines_03_shell_focus.png`, `ns_storylines_03_shell_panels.png`.
- Design System Gate : confirmé ; primitives `PokeMapPageSurface`, `PokeMapInspectorPanel`, `PokeMapStatusTile`, `PokeMapIconTile`, `PokeMapTone` utilisées ; aucun `Color(0x...)` / `Colors.*` ajouté dans les fichiers du lot.
- Fake data : aucune donnée Selbrume/cible ajoutée ; actions futures affichées disabled/read-only.
- Bis NS-STORYLINES-03-bis : test des actions futures durci avec présence obligatoire, `PokeMapButton.onPressed == null`, non-mutation du projet/workspace/sélection ; harness Visual Gate passé sur `PokeMapTheme.dark()`.
- Prochain lot attendu : NS-STORYLINES-04.

### NS-STORYLINES-04 — Storylines Secondary List Panel Read-only V0

- Type : editor UI.
- Objectif : afficher un panneau secondaire Storylines read-only basé sur le read model.
- Fichiers probables : widgets Storylines, read model, tests de rendu.
- Non-objectifs : pas de quête annexe fake, pas de recherche active.
- Dépendances : NS-STORYLINES-03.
- Critères d'acceptation : liste réelle ou empty state honnête, aucun item cible fake.
- Tests attendus : rendu liste, disabled interactions, absence de données cible.
- Analyse attendue : `flutter analyze`, `git diff --check`.
- Visual Gate : desktop + focus.
- Risques : faire croire à des storylines multiples.
- Design system impact : utiliser `PokeMapPanel`, `PokeMapSidebarItem`, `EditorSidebarListRow` ou équivalent.
- Statut : DONE.
- Résultat NS-STORYLINES-04 : panneau secondaire Storylines structuré en read-only avec header, action `+` disabled, recherche à venir, section `Histoire principale`, liste des `ScenarioAsset globalStory` réels, nombre d'étapes dérivé et section `Quêtes annexes` explicitement non branchée.
- Fichiers modifiés : `packages/map_editor/lib/src/ui/canvas/storylines_workspace.dart`, `packages/map_editor/test/storylines_workspace_shell_test.dart`, `packages/map_editor/test/storylines_current_global_story_characterization_test.dart`, `reports/narrativeStudio/storylines/road_map_storylines.md`.
- Fichiers créés : `reports/narrativeStudio/storylines/ns_storylines_04_secondary_list_panel_read_only_v0.md`, captures Visual Gate `ns_storylines_04_secondary_panel_desktop.png`, `ns_storylines_04_secondary_panel_focus.png`, `ns_storylines_04_secondary_panel_only.png`.
- Tests exécutés : `flutter test test/storylines_workspace_shell_test.dart`, `flutter test test/storylines_current_global_story_characterization_test.dart`, `flutter test test/narrative_workspace_projection_test.dart`.
- Analyse exécutée : `flutter analyze --no-fatal-infos lib/src/ui/canvas/storylines_workspace.dart lib/src/ui/canvas/narrative_workspace_canvas.dart test/storylines_workspace_shell_test.dart test/storylines_current_global_story_characterization_test.dart`.
- Visual Gate : dark theme actif via harness NS-STORYLINES-03-bis ; captures desktop, focus et medium produites.
- Design System Gate : confirmé ; `PokeMapPanel`, `PokeMapCard`, `PokeMapIconTile`, `PokeMapStatusTile`, `PokeMapButton`, `PokeMapTone` et `context.pokeMapColors` utilisés ; aucun `Color(0x...)` / `Colors.*` ajouté.
- Fake data : aucune donnée cible ajoutée ; `localEventFlow` reste absent de la liste et les quêtes annexes restent à venir.
- Prochain lot attendu : NS-STORYLINES-05.

### NS-STORYLINES-05 — Storyline Header / Tabs / KPI Read-only V0

- Type : editor UI.
- Objectif : créer header Storyline V0, tabs read-only/disabled, KPI honnêtes.
- Fichiers probables : widgets header/tabs/KPI, `PokeMapSegmentedTabs`, read model, tests.
- Non-objectifs : pas de statistiques fake, pas d'onglet Tests actif, pas de bouton Nouvelle storyline actif.
- Dépendances : NS-STORYLINES-04.
- Critères d'acceptation : header lisible, tabs cohérents, KPI sourcés.
- Tests attendus : active tab, disabled tabs, KPI no fake, actions disabled.
- Analyse attendue : `flutter analyze`, `git diff --check`.
- Visual Gate : focus header.
- Risques : copier les chiffres cible.
- Design system impact : utiliser `PokeMapMetricCard`, `PokeMapSegmentedTabs` si disponibles.
- Statut : DONE.
- Résultat NS-STORYLINES-05 : header central Storyline V0, tabs Storyline read-only et KPI honnêtes livrés dans la zone centrale haute.
- Fichiers modifiés : `packages/map_editor/lib/src/ui/canvas/storylines_workspace.dart`, `packages/map_editor/test/storylines_workspace_shell_test.dart`, `packages/map_editor/test/storylines_current_global_story_characterization_test.dart`, `reports/narrativeStudio/storylines/road_map_storylines.md`.
- Fichiers créés : `reports/narrativeStudio/storylines/ns_storylines_05_header_tabs_kpi_read_only_v0.md`, captures Visual Gate `ns_storylines_05_header_tabs_kpi_desktop.png`, `ns_storylines_05_header_tabs_kpi_focus.png`, `ns_storylines_05_header_tabs_kpi_center.png`.
- Données : `ScenarioAsset.name`, `ScenarioAsset.description`, `projection.globalStories.length`, steps filtrées par `globalScenarioId` et cutscenes liées dérivées des steps ; chapitres et diagnostics restent `À venir` faute de source branchée dans le widget.
- Tabs : `Graph` visible comme tab principal ; `Chapitres`, `Étapes`, `Scènes`, `Statistiques`, `Tests` visibles mais non mutantes / non branchées.
- Tests exécutés : `flutter test test/storylines_workspace_shell_test.dart`, `flutter test test/storylines_current_global_story_characterization_test.dart`, `flutter test test/narrative_workspace_projection_test.dart`.
- Analyse exécutée : `flutter analyze --no-fatal-infos lib/src/ui/canvas/storylines_workspace.dart lib/src/ui/canvas/narrative_workspace_canvas.dart test/storylines_workspace_shell_test.dart test/storylines_current_global_story_characterization_test.dart`.
- Visual Gate : dark theme actif via harness NS-STORYLINES-03-bis ; captures desktop, focus et medium produites.
- Design System Gate : confirmé ; `PokeMapPanel`, `PokeMapPageSurface`, `PokeMapIconTile`, `PokeMapStatusTile`, `PokeMapMetricCard`, `PokeMapSegmentedTabs`, `PokeMapTone` et `context.pokeMapColors` utilisés ; aucun `Color(0x...)` / `Colors.*` ajouté.
- Fake data : aucune donnée cible hardcodée ; aucun `localEventFlow` affiché comme quête / storyline / KPI ; actions futures restent disabled ou non mutantes.
- Prochain lot attendu : NS-STORYLINES-06.

### NS-STORYLINES-06 — Storyline Graph Read-only Placeholder V0

- Type : editor UI / visual gate.
- Objectif : remplacer le vide central par un graph ou placeholder read-only honnête.
- Fichiers probables : graph Storylines read-only, layout helpers, tests.
- Non-objectifs : pas de drag/drop, pas d'édition liens, pas de quêtes annexes fake.
- Dépendances : NS-STORYLINES-05.
- Critères d'acceptation : graph limité ou empty state honnête, Visual Gate produit.
- Tests attendus : rendu minimal, empty state, absence de side quests fake.
- Analyse attendue : `flutter analyze`, `git diff --check`.
- Visual Gate : desktop + graph focus.
- Risques : dessiner un faux graph premium.
- Design system impact : graph générique dans design system ou composant spécifique non réutilisable.
- Statut : DONE.
- Résultat NS-STORYLINES-06 : zone graph read-only livrée avec titre, source, relation détaillée à venir, noeuds d'étapes narratives réelles et empty state honnête.
- Fichiers modifiés : `packages/map_editor/lib/src/ui/canvas/storylines_workspace.dart`, `packages/map_editor/test/storylines_workspace_shell_test.dart`, `packages/map_editor/test/storylines_current_global_story_characterization_test.dart`, `reports/narrativeStudio/storylines/road_map_storylines.md`.
- Fichiers créés : `reports/narrativeStudio/storylines/ns_storylines_06_graph_read_only_placeholder_v0.md`, captures Visual Gate `ns_storylines_06_graph_placeholder_desktop.png`, `ns_storylines_06_graph_placeholder_focus.png`, `ns_storylines_06_graph_placeholder_center.png`.
- Données : steps filtrées par `globalScenarioId`, `NarrativeStepSummary.name`, `NarrativeStepSummary.description`, compteur réel de steps ; aucune relation complexe inventée.
- Empty state : document Step Studio explicitement vide couvert par test ; wording `Aucune étape narrative disponible pour cette storyline.`.
- Tests exécutés : `flutter test test/storylines_workspace_shell_test.dart`, `flutter test test/storylines_current_global_story_characterization_test.dart`, `flutter test test/narrative_workspace_projection_test.dart`.
- Analyse exécutée : `flutter analyze --no-fatal-infos lib/src/ui/canvas/storylines_workspace.dart lib/src/ui/canvas/narrative_workspace_canvas.dart test/storylines_workspace_shell_test.dart test/storylines_current_global_story_characterization_test.dart`.
- Visual Gate : dark theme actif ; captures desktop, focus et medium produites.
- Design System Gate : confirmé ; `PokeMapPageSurface`, `PokeMapCard`, `PokeMapIconTile`, `PokeMapStatusTile`, `PokeMapTone` et `context.pokeMapColors` utilisés ; aucun `Color(0x...)` / `Colors.*` ajouté.
- Fake data : aucune quête annexe, branche riche, mini-map, zoom control, chiffre cible ou donnée Selbrume ajouté ; `localEventFlow` reste absent du graph.
- Prochain lot attendu : NS-STORYLINES-07.

### NS-STORYLINES-07 — Storyline Inspector Read-only V0

- Type : editor UI.
- Objectif : créer l'inspecteur `Détails de la storyline` read-only.
- Fichiers probables : inspector Storylines, read model, tests inspector.
- Non-objectifs : pas de tags fake, pas de world rules fake, pas d'activité récente fake.
- Dépendances : NS-STORYLINES-06.
- Critères d'acceptation : inspecteur storyline, sections absentes/disabled honnêtes.
- Tests attendus : description présente/absente, disabled missing data.
- Analyse attendue : `flutter analyze`, `git diff --check`.
- Visual Gate : inspector focus.
- Risques : afficher priorité/statut sans source.
- Design system impact : utiliser `PokeMapInspectorPanel` ou primitive partagée.
- Statut : DONE.
- Résultat NS-STORYLINES-07 : inspecteur droit remplacé par un panneau `Détails de la storyline` read-only, sourcé par la storyline sélectionnée.
- Fichiers modifiés : `packages/map_editor/lib/src/ui/canvas/storylines_workspace.dart`, `packages/map_editor/test/storylines_workspace_shell_test.dart`, `packages/map_editor/test/storylines_current_global_story_characterization_test.dart`, `reports/narrativeStudio/storylines/road_map_storylines.md`.
- Fichiers créés : `reports/narrativeStudio/storylines/ns_storylines_07_inspector_read_only_v0.md`, captures Visual Gate `ns_storylines_07_inspector_desktop.png`, `ns_storylines_07_inspector_focus.png`, `ns_storylines_07_inspector_panel.png`.
- Données : nom et description réels via `NarrativeScenarioSummary`, type prudent `Storyline principale`, source `ScenarioAsset globalStory`, compteurs d'étapes et cutscenes liées dérivés des steps filtrées.
- Sections futures : `Tags`, `Règles du monde`, `Facts`, `Activité récente`, `Quêtes liées` affichées uniquement comme `À venir`, `Non branché` ou `Modèle absent en V0`.
- Empty state : absence de globalStory couverte par test avec `Aucune storyline sélectionnée.`.
- Tests exécutés : `flutter test test/storylines_workspace_shell_test.dart`, `flutter test test/storylines_current_global_story_characterization_test.dart`, `flutter test test/narrative_workspace_projection_test.dart`.
- Analyse exécutée : `flutter analyze --no-fatal-infos lib/src/ui/canvas/storylines_workspace.dart lib/src/ui/canvas/narrative_workspace_canvas.dart test/storylines_workspace_shell_test.dart test/storylines_current_global_story_characterization_test.dart`.
- Visual Gate : dark theme actif ; captures desktop, focus et panel produites.
- Design System Gate : confirmé ; `PokeMapInspectorPanel`, `PokeMapCard`, `PokeMapIconTile`, `PokeMapStatusTile`, `PokeMapTone` et `context.pokeMapColors` utilisés ; aucun `Color(0x...)` / `Colors.*` ajouté.
- Fake data : aucun tag réel, world rule, fact, activité récente, priorité, statut `Active`, niveau `Haute`, donnée Selbrume ou chiffre cible ajouté ; `localEventFlow` reste absent de l'inspecteur.
- Prochain lot attendu : NS-STORYLINES-08.

### NS-STORYLINES-08 — Chapters Tab Read-only V0

- Type : editor UI.
- Objectif : créer l'onglet `Chapitres` read-only avec chapters et steps réels.
- Fichiers probables : tab chapters, tests chapters, rapport.
- Non-objectifs : pas de création chapitre, pas de drag/drop, pas de scènes fake.
- Dépendances : NS-STORYLINES-07.
- Critères d'acceptation : liste chapitres visible, sélection read-only, wording `Scènes` prudent.
- Tests attendus : rendu chapters, empty state, sélection read-only.
- Analyse attendue : `flutter analyze`, `git diff --check`.
- Visual Gate : chapters desktop/focus.
- Risques : confondre steps et scènes finales.
- Design system impact : cards/list rows partagés.
- Statut : DONE.
- Résultat NS-STORYLINES-08 : onglet `Chapitres` read-only livré avec état local de tab, chapitres réels issus de `GlobalStoryStudioDocument.chapters`, étapes liées résolues depuis `NarrativeStepSummary`, et empty state honnête.
- Fichiers modifiés : `packages/map_editor/lib/src/features/narrative/application/narrative_workspace_projection.dart`, `packages/map_editor/lib/src/ui/canvas/storylines_workspace.dart`, `packages/map_editor/test/storylines_workspace_shell_test.dart`, `packages/map_editor/test/narrative_workspace_projection_test.dart`, `reports/narrativeStudio/storylines/road_map_storylines.md`.
- Fichiers créés : `reports/narrativeStudio/storylines/ns_storylines_08_chapters_tab_read_only_v0.md`, captures Visual Gate `ns_storylines_08_chapters_tab_desktop.png`, `ns_storylines_08_chapters_tab_focus.png`, `ns_storylines_08_chapters_tab_center.png`.
- Données : `NarrativeChapterSummary` editor-side avec id, scenario id, nom, description, ordre, step ids normalisés, steps résolues et step ids manquants détectés depuis la metadata brute.
- Interactions : `Graph` et `Chapitres` changent uniquement l'état UI local ; `Étapes`, `Scènes`, `Statistiques`, `Tests` restent non branchés / non mutants ; `Nouveau chapitre` est disabled.
- Tests exécutés : `flutter test test/storylines_workspace_shell_test.dart`, `flutter test test/storylines_current_global_story_characterization_test.dart`, `flutter test test/narrative_workspace_projection_test.dart`.
- Analyse exécutée : `flutter analyze --no-fatal-infos lib/src/ui/canvas/storylines_workspace.dart lib/src/ui/canvas/narrative_workspace_canvas.dart lib/src/features/narrative/application/narrative_workspace_projection.dart test/storylines_workspace_shell_test.dart test/storylines_current_global_story_characterization_test.dart test/narrative_workspace_projection_test.dart`.
- Visual Gate : dark theme actif ; captures desktop, focus et center produites sur l'onglet `Chapitres`.
- Design System Gate : confirmé ; `PokeMapPageSurface`, `PokeMapCard`, `PokeMapIconTile`, `PokeMapStatusTile`, `PokeMapMetricCard`, `PokeMapSegmentedTabs`, `PokeMapButton`, `PokeMapTone` et `context.pokeMapColors` utilisés ; aucun `Color(0x...)` / `Colors.*` ajouté.
- Fake data : aucun statut éditorial, scène, quête annexe, donnée Selbrume, world rule, fact, activité récente ou chiffre cible ajouté ; `localEventFlow` reste absent de la tab Chapitres.
- Prochain lot attendu : NS-STORYLINES-09.

#### NS-STORYLINES-08-bis — Graph Tab Target Alignment / Default View V0

- Statut : DONE, sans changer le statut de `NS-STORYLINES-08`.
- Résultat : l'onglet `Graph` reste la vue par défaut et devient une vue canvas plus dominante, avec grille subtile, flux principal, nodes de chapitres réels et previews de steps réelles.
- Source : nodes macro depuis les `NarrativeChapterSummary` disponibles ; fallback read-only par steps si aucun chapitre ; empty state honnête si aucune step.
- Image cible : utilisée comme référence visuelle/layout uniquement, jamais comme source de données.
- Fichiers modifiés : `packages/map_editor/lib/src/ui/canvas/storylines_workspace.dart`, `packages/map_editor/test/storylines_workspace_shell_test.dart`, `reports/narrativeStudio/storylines/road_map_storylines.md`.
- Fichiers créés : `reports/narrativeStudio/storylines/ns_storylines_08_bis_graph_tab_target_alignment_v0.md`, captures Visual Gate `ns_storylines_08_bis_graph_target_desktop.png`, `ns_storylines_08_bis_graph_target_focus.png`, `ns_storylines_08_bis_graph_target_center.png`.
- Tests exécutés : `flutter test test/storylines_workspace_shell_test.dart`, `flutter test test/storylines_current_global_story_characterization_test.dart`, `flutter test test/narrative_workspace_projection_test.dart`.
- Analyse exécutée : `flutter analyze --no-fatal-infos lib/src/ui/canvas/storylines_workspace.dart test/storylines_workspace_shell_test.dart test/storylines_current_global_story_characterization_test.dart test/narrative_workspace_projection_test.dart`.
- Visual Gate : dark theme actif ; captures desktop, focus et center produites pour le Graph aligné cible.
- Design System Gate : confirmé ; aucun `Color(0x...)` / `Colors.*` ajouté ; surfaces et accents via primitives PokeMap et `context.pokeMapColors`.
- Fake data : aucune quête annexe fake, aucun nom/chiffre Selbrume cible, aucune mini-map ou zoom actif ajouté ; `localEventFlow` reste absent du graph.
- Prochain lot recommandé inchangé : NS-STORYLINES-09.

#### NS-STORYLINES-08-ter — True Graph Geometry / Spatial Canvas V0

- Statut : DONE, sans changer le statut de `NS-STORYLINES-08`.
- Résultat : l'onglet `Graph` reste la vue par défaut et passe d'un flow `Wrap` à un vrai canvas spatial read-only avec nodes positionnés, layer d'edges, grille et légende compacte.
- Géométrie : positions calculées depuis la taille du canvas et le nombre de nodes ; flow `Début de lecture` -> chapitres réels -> `Relations à venir`, avec fallback steps si aucun chapitre.
- Edges : `CustomPainter` feature-specific, couleurs injectées via `context.pokeMapColors`, aucune relation métier inventée.
- Fichiers modifiés : `packages/map_editor/lib/src/ui/canvas/storylines_workspace.dart`, `packages/map_editor/test/storylines_workspace_shell_test.dart`, `reports/narrativeStudio/storylines/road_map_storylines.md`.
- Fichiers créés : `reports/narrativeStudio/storylines/ns_storylines_08_ter_true_graph_geometry_v0.md`, captures Visual Gate `ns_storylines_08_ter_true_graph_desktop.png`, `ns_storylines_08_ter_true_graph_focus.png`, `ns_storylines_08_ter_true_graph_center.png`.
- Tests exécutés : `flutter test test/storylines_workspace_shell_test.dart`, `flutter test test/storylines_current_global_story_characterization_test.dart`, `flutter test test/narrative_workspace_projection_test.dart`.
- Analyse exécutée : `flutter analyze --no-fatal-infos lib/src/ui/canvas/storylines_workspace.dart test/storylines_workspace_shell_test.dart test/storylines_current_global_story_characterization_test.dart test/narrative_workspace_projection_test.dart`.
- Visual Gate : dark theme actif ; captures desktop, focus et center produites pour le canvas spatial.
- Design System Gate : confirmé ; aucun `Color(0x...)` / `Colors.*` ajouté ; graph composé avec primitives PokeMap et tokens `context.pokeMapColors`.
- Fake data : aucune quête annexe fake, aucun nom/chiffre Selbrume cible, aucune mini-map ou zoom actif ajouté ; `localEventFlow` reste absent du graph.
- Prochain lot recommandé inchangé : NS-STORYLINES-09.

### NS-STORYLINES-09 — Chapters Inspector / Step Ordering Read-only V0

- Type : editor UI.
- Objectif : créer inspecteur chapitre et ordre des étapes narratives read-only.
- Fichiers modifiés/créés : `packages/map_editor/lib/src/ui/canvas/storylines_workspace.dart`, `packages/map_editor/test/storylines_workspace_shell_test.dart`, `reports/narrativeStudio/storylines/road_map_storylines.md`, `reports/narrativeStudio/storylines/ns_storylines_09_chapters_inspector_step_ordering_read_only_v0.md`, captures Visual Gate NS09.
- Non-objectifs : pas de réordonnancement, pas d'ajout scène, pas de statut éditorial fake.
- Dépendances : NS-STORYLINES-08.
- Résumé : la tab `Chapitres` affiche maintenant une liste de chapitres avec sélection locale, un inspecteur chapitre read-only, l'ordre des étapes narratives réelles, et les données futures marquées à venir.
- Tests exécutés : `flutter test test/storylines_workspace_shell_test.dart`, `flutter test test/storylines_current_global_story_characterization_test.dart`, `flutter test test/narrative_workspace_projection_test.dart`.
- Analyse exécutée : `flutter analyze --no-fatal-infos lib/src/ui/canvas/storylines_workspace.dart test/storylines_workspace_shell_test.dart test/storylines_current_global_story_characterization_test.dart test/narrative_workspace_projection_test.dart`.
- Visual Gate : dark theme actif ; captures `ns_storylines_09_chapter_inspector_desktop.png`, `ns_storylines_09_chapter_inspector_focus.png`, `ns_storylines_09_chapter_inspector_center.png`.
- Design System Gate : confirmé ; composants feature-specific composés avec primitives PokeMap ; aucun `Color(0x...)` / `Colors.*` ajouté.
- Fake data : aucun wording `Scènes du chapitre`, aucun statut éditorial fake, aucun `localEventFlow` affiché comme chapitre/step.
- Statut : DONE.
- Prochain lot attendu : NS-STORYLINES-10.

### NS-STORYLINES-10 — Storyline Visual Harmonization / Visual Gate V0

- Type : visual gate.
- Objectif : harmoniser contre les deux cibles sans ajouter de feature.
- Fichiers modifiés/créés : `packages/map_editor/lib/src/ui/canvas/storylines_workspace.dart`, `packages/map_editor/test/storylines_workspace_shell_test.dart`, `reports/narrativeStudio/storylines/road_map_storylines.md`, `reports/narrativeStudio/storylines/ns_storylines_10_visual_harmonization_visual_gate_v0.md`, captures Visual Gate NS10.
- Non-objectifs : pas de donnée fake, pas de pixel-perfect.
- Dépendances : NS-STORYLINES-09.
- Résumé : harmonisation visuelle V0 du graph et de la tab Chapitres, avec canvas plus dominant, nodes plus compacts, edges plus lisibles, légende/contrôles plus discrets et rows d'étapes plus denses.
- Tests exécutés : `flutter test test/storylines_workspace_shell_test.dart`, `flutter test test/storylines_current_global_story_characterization_test.dart`, `flutter test test/narrative_workspace_projection_test.dart`.
- Analyse exécutée : `flutter analyze --no-fatal-infos lib/src/ui/canvas/storylines_workspace.dart test/storylines_workspace_shell_test.dart test/storylines_current_global_story_characterization_test.dart test/narrative_workspace_projection_test.dart`.
- Visual Gate : captures Graph et Chapitres desktop/focus/center produites en dark theme.
- Design System Gate : confirmé ; aucun `Color(0x...)` / `Colors.*` ajouté ; couleurs via tokens / primitives PokeMap.
- Fake data : aucune donnée cible Selbrume, aucune quête annexe, aucun tag/world rule/fact/activité, aucune action future activée.
- Statut : DONE.
- Prochain lot attendu : NS-STORYLINES-11.

### NS-STORYLINES-11 — Storylines Interaction Wiring V0

- Type : editor UI / test.
- Objectif : brancher uniquement les interactions honnêtes.
- Résultat : sélection locale de `globalStory` existante, synchronisation des zones read-only, actions futures non mutantes, V1 Creation Readiness documenté.
- Fichiers modifiés/créés : `packages/map_editor/lib/src/ui/canvas/storylines_workspace.dart`, `packages/map_editor/test/storylines_workspace_shell_test.dart`, `reports/narrativeStudio/storylines/road_map_storylines.md`, `reports/narrativeStudio/storylines/ns_storylines_11_interaction_wiring_v0.md`, captures Visual Gate NS11.
- Non-objectifs respectés : pas de création Storyline, pas de validation globale, pas de graph editing, pas de modèle `StorylineAsset`, pas de quête annexe fake.
- Dépendances : NS-STORYLINES-10.
- Critères d'acceptation : interactions réelles fonctionnent, futures disabled, aucune mutation non prévue.
- Tests exécutés : `flutter test test/storylines_workspace_shell_test.dart`, `flutter test test/storylines_current_global_story_characterization_test.dart`, `flutter test test/narrative_workspace_projection_test.dart`.
- Analyse exécutée : analyse ciblée Storylines avec `flutter analyze --no-fatal-infos`.
- Visual Gate : `ns_storylines_11_interaction_default_graph.png`, `ns_storylines_11_interaction_selected_story_graph.png`, `ns_storylines_11_interaction_selected_story_chapters.png`.
- Design System Gate : confirmé, aucun `Color(0x...)` / `Colors.*` ajouté.
- Fake data : aucune donnée cible, aucune quête annexe fake, aucun `localEventFlow` promu.
- Statut : DONE.
- Prochain lot attendu : NS-STORYLINES-CHECKPOINT.

### NS-STORYLINES-CHECKPOINT — Storylines V0 Acceptance Checkpoint

- Type : checkpoint.
- Objectif : décider si Storylines V0 est acceptable et documenter les limites V1.
- Résultat : Storylines V0 accepté avec limites V1 documentées.
- Fichiers créés/modifiés : `reports/narrativeStudio/storylines/ns_storylines_checkpoint_v0_acceptance.md`, `reports/narrativeStudio/storylines/road_map_storylines.md`.
- Non-objectifs : pas de code, pas de tests modifiés, pas de polish.
- Dépendances : NS-STORYLINES-11.
- Critères d'acceptation : verdict clair, checklist V0, limites V1, recommandation de suite.
- Tests exécutés : `flutter test test/storylines_workspace_shell_test.dart`, `flutter test test/storylines_current_global_story_characterization_test.dart`, `flutter test test/narrative_workspace_projection_test.dart`.
- Analyse exécutée : analyse ciblée Storylines avec `flutter analyze --no-fatal-infos`.
- Visual Gate : inventaire des screenshots finaux NS10/NS11 inspecté ; captures utiles pour structure/theme/overflow, limitées par Ahem.
- Design system impact : gate confirmé, aucun `Color(0x...)` / `Colors.*`.
- Verdict : ACCEPTED V0 WITH V1 LIMITATIONS.
- Statut : DONE.
- Prochain lot attendu : NS-STORYLINES-V1-00 — Storyline Semantics Reset / Usable Authoring Contract.

### NS-STORYLINES-V1-00 — Storyline Semantics Reset / Usable Authoring Contract

- Type : product-contract / design-only / documentation-only.
- Objectif : clarifier le modèle produit Storylines V1 avant toute nouvelle implémentation.
- Résultat : contrat sémantique créé ; boundaries Storyline / Chapter / Story Step / Scene clarifiées ; Graph et Structure définis ; triage UI V1 documenté.
- Fichiers créés/modifiés : `reports/narrativeStudio/storylines/ns_storylines_v1_00_storyline_semantics_and_usable_authoring_contract.md`, `reports/narrativeStudio/storylines/road_map_storylines.md`.
- Non-objectifs respectés : aucun code, widget, modèle, test, screenshot ou bouton activé.
- Dépendances : NS-STORYLINES-CHECKPOINT.
- Critères d'acceptation : contrat produit clair, matrices obligatoires, actions V1 utiles définies, `localEventFlow` exclu comme `sideQuest` par défaut.
- Tests exécutés : aucun, lot documentation-only.
- Analyse exécutée : aucune, lot documentation-only.
- Note produit : le problème principal était sémantique / produit, pas technique ; Storylines V0 reste une fondation valide mais V1 doit rendre la création et l'organisation réellement utilisables.
- Statut : DONE.
- Prochain lot attendu : NS-STORYLINES-V1-01 — Storyline Authoring Model Decision.

### NS-STORYLINES-V1-01 — Storyline Authoring Model Decision

- Type : model decision / product architecture.
- Objectif : décider le modèle durable pour créer et relier Storylines, Chapters, Story Steps et Scenes.
- Résultat : décision hybride retenue.
- Modèle recommandé : `StorylineAsset` authoring model + `ScenarioAsset` executable scene flow.
- Rôle `StorylineAsset` : structure produit auteur, types de storyline, chapters, story steps, scene links, outcomes, relationships, side quest availability, validation issues.
- Rôle `ScenarioAsset` : flow exécutable, scènes/orchestrations runtime, graph local, outcomes déclarés et conditions.
- Décisions clés : Structure est source d'authoring ; Graph est généré/read-only en V1 initial ; `localEventFlow` reste exclu comme `sideQuest` par défaut.
- Risques : migration douce de `ScenarioAsset globalStory`, duplication temporaire pendant transition, besoin d'un contrat précis pour scene placeholders/outcomes.
- Fichiers créés/modifiés : `reports/narrativeStudio/storylines/ns_storylines_v1_01_storyline_authoring_model_decision.md`, `reports/narrativeStudio/storylines/road_map_storylines.md`.
- Tests exécutés : aucun, lot documentation-only.
- Analyse exécutée : aucune, lot documentation-only.
- Non-objectifs respectés : aucun code, modèle core, widget, test, screenshot ou bouton activé.
- Dépendances : NS-STORYLINES-V1-00.
- Statut : DONE.
- Prochain lot attendu : NS-STORYLINES-V1-02 — Storyline Authoring Data Shape Contract.

### NS-STORYLINES-V1-02 — Storyline Authoring Data Shape Contract

- Type : data-contract / architecture.
- Objectif : transformer la décision V1-01 en contrat de données précis avant implémentation.
- Résultat : data shape conceptuelle livrée pour `StorylineAsset`, enums, chapters, steps, scene links, outcome links, relationships, conditions/effects, JSON, invariants, validations, migration legacy et tests futurs.
- Décisions majeures : `ProjectManifest.storylines: List<StorylineAsset>` futur avec `[]` par défaut ; chapters/steps/scene links inline dans `StorylineAsset`; outcome links au niveau scene link ; relationships au niveau projet recommandé plus tard ; legacy import preview non destructif.
- Risques : schéma JSON à implémenter avec compatibilité vieux projets ; wrappers no-code au-dessus de `ScriptCondition` à préciser en code ; relation side quest disponible mais UI de création encore future.
- Fichiers créés/modifiés : `reports/narrativeStudio/storylines/ns_storylines_v1_02_storyline_authoring_data_shape_contract.md`, `reports/narrativeStudio/storylines/road_map_storylines.md`.
- Tests exécutés : aucun, lot documentation-only.
- Analyse exécutée : aucune, lot documentation-only.
- Non-objectifs : pas d'UI de création avant contrat data shape.
- Dépendances : NS-STORYLINES-V1-01.
- Statut : DONE.
- Prochain lot attendu : NS-STORYLINES-V1-03 — StorylineAsset Pure Model V0.

### NS-STORYLINES-V1-03 — StorylineAsset Pure Model V0

- Type : core model / pure Dart / tests.
- Objectif : implémenter le modèle pur `StorylineAsset` V0 et ses sous-objets essentiels, sans codec JSON, sans `ProjectManifest.storylines`, sans migration legacy et sans UI.
- Résultat : modèle pur livré dans `map_core`, export public ajouté et tests unitaires ciblés ajoutés.
- Modèle livré : enums Storylines V1, `StorylineAsset`, chapters, steps, scene links, scene refs, outcome links, effects, relationships, side quest availability, anchors, validation issues et legacy source.
- Validations : ids/titres non vides, unicité locale, références internes chapter/step, règles d'état placeholder/linkedScenario/brokenLink/needsImplementation, source relationship inline.
- Immutabilité : champs `final`, collections copiées défensivement et exposées en non modifiable, equality/hashCode/toString manuels.
- Fichiers créés/modifiés : `packages/map_core/lib/src/models/storyline_asset.dart`, `packages/map_core/lib/map_core.dart`, `packages/map_core/test/storyline_asset_test.dart`, `reports/narrativeStudio/storylines/ns_storylines_v1_03_storyline_asset_pure_model_v0.md`, `reports/narrativeStudio/storylines/road_map_storylines.md`.
- Tests exécutés : `dart test test/storyline_asset_test.dart`, `dart test test/scenario_assets_test.dart`, `dart test`.
- Analyse exécutée : `dart analyze lib/src/models/storyline_asset.dart test/storyline_asset_test.dart`.
- Non-objectifs confirmés : aucun JSON `toJson/fromJson`, aucun `ProjectManifest`, aucun `ScenarioAsset`, aucun generated file, aucun build_runner, aucune UI.
- Dépendances : NS-STORYLINES-V1-02.
- Statut : DONE.
- Prochain lot attendu : NS-STORYLINES-V1-04 — StorylineAsset JSON Codec V0.

### NS-STORYLINES-V1-04 — StorylineAsset JSON Codec V0

- Type : core codec / manual JSON / pure Dart / tests.
- Objectif : ajouter un codec JSON manuel pour `StorylineAsset` et ses sous-objets, sans intégration `ProjectManifest.storylines`.
- Résultat : `StorylineAsset` peut faire `model -> toJson() -> fromJson(...) -> model équivalent`.
- JSON : enums encodés en strings lowerCamel stables via `.name`, listes/maps présentes en `[]` / `{}`, champs optionnels null omis.
- Decode : defaults `schemaVersion = 1`, `status = draft`, `chapters = []`, `sceneLinks = []`, `relationships = []`, `metadata = {}` ; erreurs de forme en `FormatException`, invariants via constructeurs / `ValidationException`.
- ScriptCondition : codec officiel existant réutilisé (`ScriptCondition.fromJson` / `toJson` générés), sans nouveau langage conditionnel.
- Fichiers créés/modifiés : `packages/map_core/lib/src/models/storyline_asset.dart`, `packages/map_core/test/storyline_asset_test.dart`, `packages/map_core/test/storyline_asset_json_test.dart`, `reports/narrativeStudio/storylines/ns_storylines_v1_04_storyline_asset_json_codec_v0.md`, `reports/narrativeStudio/storylines/road_map_storylines.md`.
- Tests exécutés : `dart test test/storyline_asset_json_test.dart`, `dart test test/storyline_asset_test.dart`, `dart test test/scenario_assets_test.dart`, `dart test`.
- Analyse exécutée : `dart analyze lib/src/models/storyline_asset.dart test/storyline_asset_test.dart test/storyline_asset_json_test.dart`.
- Non-objectifs confirmés : aucun `ProjectManifest`, aucun `ScenarioAsset`, aucun generated file, aucun build_runner, aucune UI.
- Dépendances : NS-STORYLINES-V1-03.
- Statut : DONE.
- Prochain lot attendu : NS-STORYLINES-V1-05 — ProjectManifest.storylines Integration V0.

### NS-STORYLINES-V1-05 — ProjectManifest.storylines Integration V0

- Type : core manifest / JSON compatibility / pure Dart / tests.
- Objectif : intégrer `StorylineAsset` dans `ProjectManifest.storylines`, sans migration legacy, sans UI et sans runtime.
- Résultat : `ProjectManifest` porte désormais `storylines: List<StorylineAsset>` avec default `[]`, roundtrip JSON et compatibilité vieux projets sans champ `storylines`.
- JSON : `storylines` est sérialisé via `StorylineAsset.toJson()` et désérialisé via `StorylineAsset.fromJson(...)`; champ absent ou `null` donne `[]`.
- Compatibilité : les anciens `ScenarioAsset(scope == globalStory)` restent dans `ProjectManifest.scenarios`; aucune `StorylineAsset` n'est créée automatiquement.
- Non-promotion : `ScenarioAsset(scope == localEventFlow)` reste un scénario local et n'est jamais promu en `sideQuest`.
- Generated files : `ProjectManifest` utilise Freezed/json_serializable ; build_runner limité à `packages/map_core` a régénéré uniquement les fichiers générés du manifest.
- Fichiers créés/modifiés : `packages/map_core/lib/src/models/project_manifest.dart`, `packages/map_core/lib/src/models/project_manifest.freezed.dart`, `packages/map_core/lib/src/models/project_manifest.g.dart`, `packages/map_core/test/project_manifest_storylines_test.dart`, `reports/narrativeStudio/storylines/ns_storylines_v1_05_project_manifest_storylines_integration_v0.md`, `reports/narrativeStudio/storylines/road_map_storylines.md`.
- Tests exécutés : `dart test test/project_manifest_storylines_test.dart`, `dart test test/storyline_asset_json_test.dart`, `dart test test/storyline_asset_test.dart`, `dart test test/scenario_assets_test.dart`, `dart test`.
- Analyse exécutée : `dart analyze lib/src/models/project_manifest.dart test/project_manifest_storylines_test.dart`.
- Non-objectifs confirmés : `StorylineAsset` non modifié, `ScenarioAsset` non modifié, aucune migration legacy, aucun import globalStory, aucune UI, aucun runtime.
- Dépendances : NS-STORYLINES-V1-04.
- Statut : DONE.
- Prochain lot attendu : NS-STORYLINES-V1-06 — Legacy GlobalStory Import Preview V0.

### NS-STORYLINES-V1-06 — Legacy GlobalStory Import Preview V0

- Type : core authoring / pure Dart / legacy preview / tests.
- Objectif : proposer une preview non destructive de conversion des anciens `ScenarioAsset(scope == globalStory)` vers des `StorylineAsset(type: main)` drafts.
- Résultat : API pure `buildLegacyGlobalStoryImportPreview(ProjectManifest)` livrée dans `map_core`.
- Mapping : chaque `globalStory` legacy produit un candidat draft `StorylineAsset` avec id déterministe `legacy_<scenario.id>`, type `main`, status `draft`, titre/description issus du scénario et `legacySource.kind = scenario.globalStory`.
- Metadata legacy : chapitres et steps sont importés quand les metadata `authoring.globalStoryStudioDocument` et `authoring.stepStudioDocument` sont lisibles ; sinon le candidat reste minimal avec issues stables.
- Diagnostics : issues stables via `StorylineValidationIssue` pour aucun globalStory, multiples globalStory, storylines existantes, collision d'id, metadata absente/invalide, step manquante, step non assignée, outcomes non mappés et `localEventFlow` ignoré.
- Non-mutation : la preview ne modifie jamais `ProjectManifest`, `ProjectManifest.storylines`, `ProjectManifest.scenarios` ou les assets existants.
- Non-promotion : `ScenarioAsset(scope == localEventFlow)` est explicitement ignoré et ne devient jamais une `sideQuest`.
- Fichiers créés/modifiés : `packages/map_core/lib/src/authoring/storyline_legacy_import_preview.dart`, `packages/map_core/test/storyline_legacy_import_preview_test.dart`, `packages/map_core/lib/map_core.dart`, `reports/narrativeStudio/storylines/ns_storylines_v1_06_legacy_global_story_import_preview_v0.md`, `reports/narrativeStudio/storylines/road_map_storylines.md`.
- Tests exécutés : `dart test test/storyline_legacy_import_preview_test.dart`, `dart test test/project_manifest_storylines_test.dart`, `dart test test/storyline_asset_json_test.dart`, `dart test test/storyline_asset_test.dart`, `dart test test/scenario_assets_test.dart`, `dart test`.
- Analyse exécutée : `dart analyze lib/src/authoring/storyline_legacy_import_preview.dart test/storyline_legacy_import_preview_test.dart`.
- Non-objectifs confirmés : aucun `ProjectManifest` modifié, aucun `StorylineAsset` modifié, aucun `ScenarioAsset` modifié, aucun build_runner, aucune UI, aucun runtime, aucun import/apply mutateur.
- Dépendances : NS-STORYLINES-V1-05.
- Statut : DONE.
- Prochain lot attendu : NS-STORYLINES-V1-07 — Create Main Storyline Flow V0.

### NS-STORYLINES-V1-07 — Create Main Storyline Flow V0 / Storylines UI Usability Reset

- Type : editor UI / authoring flow / tests / visual gate.
- Objectif : rendre Storylines utile en créant une vraie Storyline principale dans `ProjectManifest.storylines`.
- Résultat : flow `Nouvelle storyline` livré avec formulaire minimal, type `main` verrouillé, titre obligatoire, description optionnelle, id slugifié unique, mutation contrôlée du manifest et sélection de la storyline créée.
- Source de vérité : `ProjectManifest.storylines` devient la source V1 authoring ; le legacy `ScenarioAsset.globalStory` reste visible uniquement comme information non importée et non sélectionnable.
- UI reset : tabs principales limitées à `Graph` / `Structure`, panneau secondaire simplifié, recherche fake retirée, side quests fake absentes, CTA secondaire `+` supprimé/non actif, `Nouveau chapitre` reste disabled / bientôt.
- Graph : read-only honnête depuis `StorylineAsset`; si la storyline n'a pas de chapitre, affiche un node/storyline vide avec instruction d'ajouter des chapitres dans Structure.
- Structure : affiche titre, description, type, status draft, sections vides `Chapitres`, `Étapes narratives`, `Scènes liées`, avec création de chapitre reportée.
- Fichiers modifiés/créés : `packages/map_editor/lib/src/ui/canvas/storylines_workspace.dart`, `packages/map_editor/test/storylines_workspace_shell_test.dart`, `reports/narrativeStudio/storylines/road_map_storylines.md`, `reports/narrativeStudio/storylines/ns_storylines_v1_07_create_main_storyline_flow_v0.md`, captures Visual Gate V1-07.
- Tests exécutés : `flutter test test/storylines_workspace_shell_test.dart`, `flutter test test/storylines_current_global_story_characterization_test.dart`, `flutter test test/narrative_workspace_projection_test.dart`.
- Analyse exécutée : `flutter analyze --no-fatal-infos lib/src/ui/canvas/storylines_workspace.dart test/storylines_workspace_shell_test.dart test/storylines_current_global_story_characterization_test.dart test/narrative_workspace_projection_test.dart`.
- Visual Gate : `ns_storylines_v1_07_empty_storylines_desktop.png`, `ns_storylines_v1_07_create_main_dialog.png`, `ns_storylines_v1_07_created_main_graph.png`, `ns_storylines_v1_07_created_main_structure.png`.
- Design System Gate : confirmé ; aucun `Color(0x...)` / `Colors.*` ajouté dans les fichiers touchés.
- Non-objectifs confirmés : aucun `map_core` modifié, aucune sideQuest, aucun chapter, aucune step, aucune scene placeholder, aucun import legacy automatique, aucun `localEventFlow` promu, aucun runtime/gameplay/battle modifié.
- Statut : DONE.
- Prochain lot attendu : NS-STORYLINES-V1-08 — Structure Tab Authoring V0.

### NS-STORYLINES-V1-07-bis — Storylines Workspace Cleanup / Dead Legacy Removal

- Type : editor UI cleanup / technical debt / tests / visual regression.
- Objectif : nettoyer la dette laissée par V1-07 sans changer le comportement produit.
- Résultat : suppression de l'état `_selectedGlobalStoryId` mort, confirmation que `_LegacyStorylinesWorkspaceState` et `_StorylineContentTab.chapters` sont absents, et remplacement du tap silencieux `warnIfMissed: false` par une assertion explicite sur le CTA `Nouveau chapitre — bientôt` désactivé.
- Comportement préservé : `Nouvelle storyline` crée toujours une main `StorylineAsset(type: main, status: draft)`, les tabs principales restent `Graph` / `Structure`, aucun import legacy automatique, aucun `localEventFlow` promu, aucune sideQuest/chapter/step/scene créée.
- Fichiers modifiés/créés : `packages/map_editor/lib/src/ui/canvas/storylines_workspace.dart`, `packages/map_editor/test/storylines_workspace_shell_test.dart`, `reports/narrativeStudio/storylines/road_map_storylines.md`, `reports/narrativeStudio/storylines/ns_storylines_v1_07_bis_storylines_workspace_cleanup.md`, captures Visual Gate V1-07 régénérées.
- Tests exécutés : `flutter test test/storylines_workspace_shell_test.dart`, `flutter test test/storylines_current_global_story_characterization_test.dart`, `flutter test test/narrative_workspace_projection_test.dart`.
- Analyse exécutée : `flutter analyze --no-fatal-infos lib/src/ui/canvas/storylines_workspace.dart test/storylines_workspace_shell_test.dart test/storylines_current_global_story_characterization_test.dart test/narrative_workspace_projection_test.dart`.
- Design System Gate : confirmé ; aucun `Color(0x...)` / `Colors.*` dans les fichiers touchés.
- Non-objectifs confirmés : aucun `map_core`, runtime, gameplay, battle, modèle core, generated file ou build_runner modifié/lancé.
- Statut : DONE.
- Prochain lot attendu : NS-STORYLINES-V1-08 — Structure Tab Authoring V0.

### NS-STORYLINES-V1-08 — Structure Tab Authoring V0

- Type : editor UI / authoring flow / structure tab / tests / visual gate.
- Objectif : rendre l'onglet Structure utilisable pour créer des chapitres et des étapes narratives dans une `StorylineAsset` existante.
- Résultat : `Nouveau chapitre` ouvre un formulaire minimal, crée un `StorylineChapter` draft avec id slugifié unique, ordre calculé et sélection locale du chapitre créé.
- Résultat : `Nouvelle étape narrative` ouvre un formulaire minimal depuis un chapitre sélectionné, crée une `StorylineStep` avec id slugifié unique à l'échelle de la storyline, ordre calculé dans le chapitre, puis l'affiche dans Structure.
- Structure : affiche résumé storyline, liste des chapitres, détail du chapitre sélectionné, liste des étapes narratives et section `Scènes liées` désactivée.
- Graph : reste minimal et read-only ; après création de chapitres/steps il affiche un résumé réel et le message que le graph détaillé viendra au lot `Graph From StorylineAsset`.
- Fichiers modifiés/créés : `packages/map_editor/lib/src/ui/canvas/storylines_workspace.dart`, `packages/map_editor/test/storylines_workspace_shell_test.dart`, `reports/narrativeStudio/storylines/road_map_storylines.md`, `reports/narrativeStudio/storylines/ns_storylines_v1_08_structure_tab_authoring_v0.md`, captures Visual Gate V1-08.
- Tests exécutés : `flutter test test/storylines_workspace_shell_test.dart`, `flutter test test/storylines_current_global_story_characterization_test.dart`, `flutter test test/narrative_workspace_projection_test.dart`.
- Analyse exécutée : `flutter analyze --no-fatal-infos lib/src/ui/canvas/storylines_workspace.dart test/storylines_workspace_shell_test.dart test/storylines_current_global_story_characterization_test.dart test/narrative_workspace_projection_test.dart`.
- Design System Gate : confirmé ; aucun `Color(0x...)` / `Colors.*` dans les fichiers touchés.
- Non-objectifs confirmés : aucune sideQuest, aucun scene placeholder, aucun sceneLink, aucun import legacy automatique, aucun `localEventFlow` promu, aucun `map_core`, runtime, gameplay ou battle modifié.
- Statut : DONE.
- Prochain lot attendu : NS-STORYLINES-V1-09 — Create Side Quest Flow V0.

## 10. Update protocol for every future lot

Chaque futur lot Storylines doit :

1. lire `road_map_storylines.md` avant toute modification ;
2. lire le rapport du lot précédent ;
3. respecter le lot courant exact ;
4. ne pas démarrer le lot suivant ;
5. mettre à jour `road_map_storylines.md` à la fin ;
6. marquer le lot courant avec son statut réel ;
7. ajouter un court résumé du résultat ;
8. lister les fichiers modifiés / créés ;
9. lister les tests et analyze exécutés ;
10. lister les limites et dettes ;
11. confirmer le prochain lot recommandé ;
12. confirmer le respect des règles design system ;
13. confirmer l'absence de couleurs hardcodées ;
14. confirmer l'absence de données fake ;
15. confirmer que les actions futures restent disabled si non supportées.

Bloc standard futur :

```text
Avant modification :
- lire reports/narrativeStudio/storylines/road_map_storylines.md ;
- lire le rapport du lot précédent ;
- capturer git status initial ;
- confirmer les changements préexistants.

Après modification :
- mettre à jour road_map_storylines.md ;
- marquer le lot courant TODO / IN PROGRESS / DONE / BLOCKED / SKIPPED ;
- ajouter résumé, fichiers, tests, analyze, limites ;
- confirmer Design System Gate ;
- confirmer absence de fake data ;
- confirmer prochain lot ;
- capturer git status final, diff stat, diff name-only, diff check.
```

## 11. Definition of Done

Un lot Storylines V0 est `DONE` seulement si :

- son objectif exact est atteint ;
- aucun non-objectif n'a été implémenté ;
- les fichiers modifiés sont dans le périmètre autorisé ;
- les tests attendus passent ou les skips sont justifiés ;
- `flutter analyze` ou analyse ciblée est propre si code touché ;
- `git diff --check` est propre ;
- aucun fake data n'est ajouté ;
- aucune action future n'est activée sans source réelle ;
- Design System Gate est respecté ;
- rapport de lot complet ;
- roadmap mise à jour.

Un lot doit rester `BLOCKED` si :

- une décision produit manque ;
- une primitive design system manque et ne peut pas être créée dans le lot ;
- une source de données manque et l'UI serait fake ;
- un changement hors périmètre serait nécessaire.

## 12. Open decisions

### Maps dans la sidebar Narrative Studio

État :

- NS-HOME a retiré `Maps` de la sidebar interne ;
- les nouvelles cibles montrent `Maps` ;
- l'architecture canonique sépare Project Explorer global et sidebar interne.

Décision actuelle :

- ne pas réintroduire `Maps` dans la sidebar interne sans décision explicite.

Option recommandée :

- traiter les cartes liées comme `Lieux liés` ou `Cartes liées` dans l'inspecteur Storyline / Chapter ;
- garder `Maps` global dans `ProjectExplorerPanel` ou dans le workspace Maps existant ;
- ne pas casser la séparation des deux sidebars.

### Storyline comme modèle core

Question :

- faut-il un `StorylineAsset` ou un read model editor suffit-il pour V0 ?

Décision temporaire :

- commencer par read model / data contract ;
- ne pas modifier `map_core` sans preuve.

### Scènes vs Steps

Question :

- la cible `Scènes` représente-t-elle des steps narratives, des cutscenes, ou un futur concept ?

Décision temporaire :

- utiliser un wording prudent jusqu'à clarification.

### Quêtes annexes

Question :

- side quests sont-elles des storylines secondaires, des chapters, des scenarios, ou un futur modèle ?

Décision temporaire :

- ne pas les afficher comme données réelles tant que le modèle manque.

## 13. Current status

```text
Roadmap status: V0 ACCEPTED WITH V1 LIMITATIONS / V1 ACCEPTED WITH LIMITATIONS
Current lot: NS-STORYLINES-V1.1-00-bis
Current lot status: DONE
Next recommended lot: NS-STORYLINES-V1.1-01 — Basic Edit / Delete Flow V0
```

| Lot | Status | Last update | Notes |
|---|---|---|---|
| NS-STORYLINES-00 | DONE | 2026-05-27 | Audit actuel/cible produit. |
| NS-STORYLINES-ROADMAP-00 | DONE | 2026-05-27 | Roadmap vivante créée. |
| NS-STORYLINES-01 | DONE | 2026-05-27 | Contrat de données Storylines V0 documenté ; aucun code/test modifié. |
| NS-STORYLINES-02 | DONE | 2026-05-27 | Tests de caractérisation anti-fake ajoutés ; ancien Global Story Studio verrouillé sans code production. |
| NS-STORYLINES-03 | DONE | 2026-05-28 | Shell Storylines V0 read-only livré avec layout 3 zones, anti-fake, captures Visual Gate et tests ciblés. |
| NS-STORYLINES-04 | DONE | 2026-05-28 | Panneau secondaire read-only structuré sur les globalStory réelles ; recherche / création / quêtes annexes disabled. |
| NS-STORYLINES-05 | DONE | 2026-05-28 | Header/tabs/KPI read-only livrés avec KPI sourcés ou disabled. |
| NS-STORYLINES-06 | DONE | 2026-05-28 | Graph read-only placeholder livré avec steps réelles et empty state. |
| NS-STORYLINES-07 | DONE | 2026-05-28 | Inspector read-only livré avec données réelles, sections futures disabled et empty state. |
| NS-STORYLINES-08 | DONE | 2026-05-28 | Onglet Chapitres read-only livré ; bis Graph target alignment et ter canvas spatial livrés sans changer le statut NS08. |
| NS-STORYLINES-09 | DONE | 2026-05-28 | Chapters inspector / step ordering read-only livré sans scène fake. |
| NS-STORYLINES-10 | DONE | 2026-05-28 | Visual harmonization Graph/Chapitres et Visual Gate complet livrés sans nouvelle feature. |
| NS-STORYLINES-11 | DONE | 2026-05-28 | Interaction wiring V0 livré : sélection locale de globalStory existante, synchronisation zones read-only, actions futures non mutantes, notes V1 Creation Readiness. |
| NS-STORYLINES-CHECKPOINT | DONE | 2026-05-28 | Storylines V0 acceptance checkpoint livré : ACCEPTED V0 WITH V1 LIMITATIONS ; prochaine phase recommandée V1 semantic/product contract. |
| NS-STORYLINES-V1-00 | DONE | 2026-05-28 | Reset sémantique produit livré : Storylines V0 techniquement valide, V1 doit clarifier et rendre utilisables Storyline / Chapter / Story Step / Scene / Graph / Structure. |
| NS-STORYLINES-V1-01 | DONE | 2026-05-28 | Modèle hybride retenu : `StorylineAsset` authoring + `ScenarioAsset` executable scene flow ; Structure source d'authoring, Graph généré. |
| NS-STORYLINES-V1-02 | DONE | 2026-05-28 | Contrat data shape `StorylineAsset` livré : champs, enums, invariants, validations, JSON, migration legacy, UI actions et tests futurs. |
| NS-STORYLINES-V1-03 | DONE | 2026-05-28 | StorylineAsset Pure Model V0 livré dans `map_core`, sans JSON/manifest/UI. |
| NS-STORYLINES-V1-04 | DONE | 2026-05-28 | StorylineAsset JSON Codec V0 livré, sans manifest/migration/UI. |
| NS-STORYLINES-V1-05 | DONE | 2026-05-28 | ProjectManifest.storylines Integration V0 livré avec compatibilité vieux JSON et sans migration legacy. |
| NS-STORYLINES-V1-06 | DONE | 2026-05-28 | Legacy GlobalStory Import Preview V0 livré : candidats non destructifs depuis `globalStory`, issues stables, `localEventFlow` ignoré. |
| NS-STORYLINES-V1-07 | DONE | 2026-05-28 | Create Main Storyline Flow V0 livré : création main `StorylineAsset`, Graph/Structure seulement, aucun import legacy automatique. |
| NS-STORYLINES-V1-07-bis | DONE | 2026-05-28 | Cleanup technique Storylines livré sans changement produit : legacy mort absent, tap silencieux supprimé, Visual Gate V1-07 régénéré. |
| NS-STORYLINES-V1-08 | DONE | 2026-05-29 | Structure Tab Authoring V0 livré : création de chapitres et steps, Graph minimal honnête, aucun sceneLink/sideQuest/import legacy. |
| NS-STORYLINES-V1-09 | DONE | 2026-05-29 | Create Side Quest Flow V0 livré : création réelle de `StorylineAsset(type: sideQuest, status: draft)`, liste main/sideQuest séparée, Structure réutilisée, aucune relationship/availability/sceneLink/import legacy. |
| NS-STORYLINES-V1-10 | DONE | 2026-05-29 | Graph From StorylineAsset V0 livré : graph read-only généré depuis la StorylineAsset sélectionnée, nodes storyline/chapter/step, edges d'ordre auteur, sideQuest autonome non intégrée au graph principal. |
| NS-STORYLINES-V1-11 | DONE | 2026-05-29 | Side Quest Attachment + Graph Integration V0 livré : attachement explicite sideQuest -> main chapter/step, relation persistée, graph principal sourcé uniquement par relation. |
| NS-STORYLINES-V1-12 | DONE | 2026-05-29 | V1 Visual Graph Enrichment livré : polish visuel read-only, distinction ordre auteur / disponibilité sideQuest, aucune donnée métier créée. |
| NS-STORYLINES-V1-CHECKPOINT | DONE | 2026-05-29 | Verdict `ACCEPTED WITH LIMITATIONS` : Storylines V1 fermé comme atelier auteur initial. |
| NS-STORYLINES-SEED-00 | DONE | 2026-05-29 | Selbrume Storylines Demo Seed V0 livré comme data-only : 1 main, 3 sideQuests, chapters, steps et attachements explicites. |
| NS-STORYLINES-SEED-FIX-01 | DONE | 2026-05-29 | Correction post-seed : graph plus grand, sideQuests attachées rendues comme nodes indépendants, aucun seed/model/runtime modifié. |
| NS-STORYLINES-SEED-FIX-01-bis | DONE | 2026-05-29 | Graph Focus Layout livré : graph par défaut agrandi, KPI/header compactés en mode Graph, sideQuest nodes indépendants préservés, aucun seed ni donnée métier modifié. |
| NS-STORYLINES-V1.1-00 | DONE | 2026-05-29 | Structure Layout livré : chapitre sélectionné expanded, autres chapitres collapsed, étapes narratives plus lisibles, création chapter/step préservée, aucun edit/delete ajouté. |
| NS-STORYLINES-V1.1-00-bis | DONE | 2026-05-29 | Structure full-width accordion livré : liste verticale de chapitres en accordéon, toolbar locale, edit/delete chapters et steps, reorder DnD des steps, aucun seed/core/runtime modifié. |

## 14. V1 Creation Readiness Notes

NS-STORYLINES-11 reste un lot V0 : aucune création de storyline, aucun `StorylineAsset`, aucune quête annexe fake et aucune mutation projet.

Pré-requis recommandés pour activer la création Storylines V1 :

- Décision modèle : choisir entre un `StorylineAsset` dédié ou un `ScenarioAsset` enrichi, avec contrat editor/runtime explicite.
- Types de storyline : prévoir au minimum `main`, `sideQuest`, `tutorial`, `epilogue`, `episode`, sans les inférer depuis `localEventFlow`.
- Storyline principale : définir une règle d'unicité éventuelle, le comportement si une principale existe déjà, et le flow de remplacement ou migration.
- Flow auteur : création no-code guidée avec titre, type, source, chapitre initial éventuel, validation immédiate et preview read-only avant sauvegarde.
- Validation anti-duplicate : empêcher les ids/titres conflictuels, les types incompatibles et les liens de steps orphelins.
- Compatibilité : décider comment migrer ou projeter le `ScenarioAsset globalStory` actuel sans casser les projets existants.
- Quêtes annexes : les afficher uniquement quand le modèle existe ; `localEventFlow` ne suffit pas et ne doit jamais devenir une quête annexe par défaut.
- Création : storyline principale et quête annexe prévues pour V1 uniquement, pas en V0.
- Boutons activables plus tard : `Nouvelle storyline`, `+`, `Nouveau chapitre`, validation narrative et création de quête annexe après contrat modèle + tests anti-fake.

Suite V1 documentaire recommandée :

- `NS-STORYLINES-V1-00 — Storyline Semantics Reset / Usable Authoring Contract`
- `NS-STORYLINES-V1-01 — Storyline Authoring Model Decision`
- `NS-STORYLINES-V1-02 — Storyline Authoring Data Shape Contract`
- `NS-STORYLINES-V1-03 — StorylineAsset Pure Model V0`
- `NS-STORYLINES-V1-04 — StorylineAsset JSON Codec V0`
- `NS-STORYLINES-V1-05 — ProjectManifest.storylines Integration V0`
- `NS-STORYLINES-V1-06 — Legacy GlobalStory Import Preview V0`
- `NS-STORYLINES-V1-07 — Create Main Storyline Flow V0`
- `NS-STORYLINES-V1-08 — Structure Tab Authoring V0`
- `NS-STORYLINES-V1-09 — Create Side Quest Flow V0`
- `NS-STORYLINES-V1-10 — Graph From StorylineAsset V0`
- `NS-STORYLINES-V1-11 — Side Quest Attachment + Graph Integration V0`
- `NS-STORYLINES-V1-12 — V1 Visual Graph Enrichment`
- `NS-STORYLINES-V1-CHECKPOINT — Storylines V1 Acceptance Checkpoint`

## 15. Changelog

### 2026-05-29 — NS-STORYLINES-V1.1-00-bis

- Refonte de `Structure` en vue centrale pleine largeur fondée sur une liste verticale d'accordéons de chapitres ; suppression du split artificiel chapitre sélectionné / colonne des autres chapitres.
- Toolbar locale Structure ajoutée : recherche, filtre, tri et liaison scène affichés en disabled honnête ; création `Nouveau chapitre` reste active.
- Authoring minimal livré : création existante préservée, édition/suppression des chapitres, édition/suppression des étapes narratives et réordonnancement DnD des étapes dans le chapitre.
- Les lignes d'étapes restent compactes, affichent `Aucune scène liée` ou le compteur réel, et ne créent aucun sceneLink ni placeholder de scène.
- Selbrume reste data-only ; aucun seed, map_core, runtime, gameplay ou battle modifié ; Graph et sideQuest nodes indépendants préservés.
- Captures Visual Gate dark bis produites : full layout, chapitre fermé, chapitre ouvert avec steps, actions d'authoring et régression Graph.
- Prochain lot recommandé : `NS-STORYLINES-V1.1-01 — Basic Edit / Delete Flow V0`.

### 2026-05-29 — NS-STORYLINES-V1.1-00

- Structure est réorganisée en vraie vue d'organisation : barre d'action compacte, chapitre sélectionné expanded et chapitres non sélectionnés collapsed.
- Les étapes narratives du chapitre sélectionné sont affichées en rows plus lisibles avec état réel `Aucune scène liée` si aucun sceneLink.
- L'inspector droit devient contextuel en Structure quand un chapitre est sélectionné.
- Les flows existants `Nouveau chapitre` et `Nouvelle étape narrative` restent branchés ; aucun edit/delete, sceneLink, seed, model, runtime, gameplay ou battle modifié.
- Captures Visual Gate dark V1.1-00 produites ; le prochain lot recommandé reste `NS-STORYLINES-V1.1-01 — Basic Edit / Delete Flow V0`.

### 2026-05-29 — NS-STORYLINES-SEED-FIX-01-bis

- Correction layout post-seed : le graph par défaut démarre plus haut et occupe nettement plus de place dans la zone centrale Storylines.
- Les KPI et le header interne sont compactés en mode Graph afin de laisser la priorité au canvas.
- Les sideQuest nodes indépendants et les edges de disponibilité du lot précédent sont préservés ; aucune sideQuest n'est réintégrée dans les chapter cards.
- Aucune donnée métier, aucun seed, aucun modèle core, runtime, gameplay, battle ou fichier `selbrume/project.json` modifié.
- Captures Visual Gate dark bis produites ; le prochain lot recommandé reste `NS-STORYLINES-V1.1-01 — Basic Edit / Delete Flow V0`.

### 2026-05-29 — NS-STORYLINES-SEED-FIX-01

- Correction post-seed du rendu graph Selbrume : canvas plus grand et KPI compactés en mode Graph.
- Les sideQuests attachées sont désormais rendues comme nodes indépendants autour du flux principal, reliées par edges de disponibilité, et non comme grandes cartes incluses dans les chapters.
- Les chapters affichent un compteur discret de quêtes disponibles et des steps compactées avec overflow `+N étapes`.
- Aucun seed, modèle core, runtime, gameplay, battle ou fichier `selbrume/project.json` modifié.
- Tests dédiés Selbrume ajoutés, captures Visual Gate dark produites, analyse ciblée clean ; `storylines_workspace_shell_test.dart` reste bloqué uniquement par le golden V1-12 absent du repo courant.
- Prochain lot recommandé : `NS-STORYLINES-V1.1-01 — Basic Edit / Delete Flow V0`.

### 2026-05-29 — NS-STORYLINES-SEED-00

- Selbrume Storylines Demo Seed V0 livré comme data-only dans `selbrume/project.json`.
- Seed ajouté uniquement dans `ProjectManifest.storylines` : 1 main storyline, 3 sideQuests, chapters, steps et attachements explicites sideQuest -> main step.
- Aucun code produit, test, runtime, gameplay, battle, event, scene, fact, world rule, dialogue, cinématique ou combat importé.
- Source documentaire utilisée : `MVP Selbrume/selbrume.md`.
- Validation JSON et tests core ciblés passent ; le test editor global `storylines_workspace_shell_test.dart` échoue sur le golden Visual Gate V1-12 absent du repo courant, sans modification de test dans ce lot.
- Storylines V1 reste fermé par checkpoint ; prochaine phase recommandée : `NS-SCENES-V1 — Scene Placeholder + Scene Linking Foundation`.

### 2026-05-29 — NS-STORYLINES-V1-CHECKPOINT

- Storylines V1 Acceptance Checkpoint livré en audit-only / documentation-only.
- Verdict : `ACCEPTED WITH LIMITATIONS`.
- Storylines V1 est fermé comme atelier auteur initial : modèle, JSON, `ProjectManifest.storylines`, preview legacy, création main/sideQuest, chapters/steps, attachement sideQuest explicite, graph read-only et polish V1 sont couverts par tests ciblés.
- Limites acceptées : pas encore de scene placeholder, sceneLink, Scene Outcome branch, facts/world rules, validation narrative globale, edit/delete/reorder avancé, import legacy appliqué ou runtime execution.
- Limite d'évidence : les rapports V1-00 à V1-11 et les captures V1-07 à V1-11 attendus sont absents du repo courant ; les tests et le rapport V1-12 restent présents.
- Prochaine phase recommandée : `NS-SCENES-V1 — Scene Placeholder + Scene Linking Foundation`.

### 2026-05-29 — NS-STORYLINES-V1-12

- V1 Visual Graph Enrichment livré côté editor : le graph read-only est plus lisible sans ajouter de comportement produit.
- Améliorations visuelles : légende compacte, hiérarchie des nodes storyline/chapter/step/sideQuest, canvas plus dense, sideQuest attachée plus distincte.
- Edges clarifiés : ordre auteur en ligne principale, disponibilité de quête annexe en ligne secondaire pointillée via tokens du design system.
- Visual-only confirmé : aucune donnée métier créée, aucune mutation de `ProjectManifest`, aucune création de relationship/availability/sceneLink/scene placeholder dans ce lot.
- `Structure` reste la source d'authoring ; le graph reste read-only ; aucun import legacy automatique ; `localEventFlow` reste exclu.
- Fichiers créés/modifiés : `storylines_graph_model.dart`, `storylines_graph_painter.dart`, `storylines_graph_view.dart`, `storylines_workspace_shell_test.dart`, captures V1-12, rapport V1-12.
- Tests exécutés : `flutter test test/storylines_workspace_shell_test.dart`, `flutter test test/storylines_current_global_story_characterization_test.dart`, `flutter test test/narrative_workspace_projection_test.dart`, analyse ciblée, `rg` anti-couleurs, `rg` contrôle features interdites.
- Prochain lot recommandé : `NS-STORYLINES-V1-CHECKPOINT — Storylines V1 Acceptance Checkpoint`.

### 2026-05-29 — NS-STORYLINES-V1-11

- Side Quest Attachment + Graph Integration V0 livré côté editor : une sideQuest peut être attachée explicitement à une main storyline depuis Structure.
- L'attachement crée une vraie `StorylineRelationship(kind: sideQuestAvailableDuring)` inline sur la sideQuest, avec `SideQuestAvailability.startAnchor` sur un chapitre ou une étape de la main storyline.
- Le graph principal affiche une sideQuest seulement quand cette relation existe ; les sideQuests non attachées restent absentes du graph principal.
- Le graph sideQuest indique l'état attaché/non attaché sans devenir éditeur interactif.
- Aucun `map_core` modifié ; aucun `StorylineSceneLink`, scene placeholder, outcome, fact, world rule, import legacy automatique ou `localEventFlow` promu.
- Fichiers créés/modifiés : `storylines_workspace.dart`, `storylines_graph_model.dart`, `storylines_graph_view.dart`, `storylines_workspace_shell_test.dart`, captures V1-11, rapport V1-11.
- Tests exécutés : `flutter test test/storylines_workspace_shell_test.dart`, `flutter test test/storylines_current_global_story_characterization_test.dart`, `flutter test test/narrative_workspace_projection_test.dart`, analyse ciblée, `rg` anti-couleurs.
- Prochain lot recommandé : `NS-STORYLINES-V1-12 — V1 Visual Graph Enrichment`.

### 2026-05-29 — NS-STORYLINES-V1-10

- Graph From StorylineAsset V0 livré côté editor : le Graph affiche un canvas read-only généré depuis la `StorylineAsset` sélectionnée.
- Nodes réels : storyline racine, chapitres triés par `order`, steps triées par `order`, empty states honnêtes pour storyline sans chapitre et chapitre sans step.
- Edges visibles : uniquement ordre auteur racine -> premier chapitre puis chapitre -> chapitre suivant ; aucune branche narrative, availability, outcome ou convergence fake.
- SideQuest sélectionnée : graph autonome avec badge `Quête annexe indépendante`, sans lien vers la main storyline.
- Main sélectionnée avec sideQuests existantes : note d'intégration future, aucune sideQuest injectée comme node/branche du graph principal.
- Structure reste source d'authoring ; le graph ne crée ni chapter, ni step, ni relationship, ni `SideQuestAvailability`, ni scene placeholder, ni `StorylineSceneLink`.
- Aucun import legacy automatique ; `localEventFlow` reste exclu.
- Fichiers créés/modifiés : `storylines_graph_model.dart`, `storylines_graph_painter.dart`, `storylines_graph_view.dart`, `storylines_workspace.dart`, `storylines_workspace_shell_test.dart`, captures V1-10, rapport V1-10.
- Tests exécutés : `flutter test test/storylines_workspace_shell_test.dart`, `flutter test test/storylines_current_global_story_characterization_test.dart`, `flutter test test/narrative_workspace_projection_test.dart`, analyse ciblée, `rg` anti-couleurs.
- Prochain lot recommandé : `NS-STORYLINES-V1-11 — Side Quest Graph Integration V0`.

### 2026-05-29 — NS-STORYLINES-V1-09

- Create Side Quest Flow V0 livré côté editor : `Nouvelle storyline` peut créer une vraie `StorylineAsset(type: sideQuest, status: draft)` après existence d'une main storyline.
- Le dialog de création choisit entre `Histoire principale` et `Quête annexe` ; la main reste unique et la sideQuest est sélectionnée après création.
- Le panneau secondaire sépare `Histoire principale` et `Quêtes annexes`, avec compteurs réels depuis `ProjectManifest.storylines`.
- Structure réutilise le même authoring chapters/steps pour une sideQuest sans modifier la main storyline.
- Graph reste minimal et honnête : une sideQuest sélectionnée indique qu'elle n'est pas reliée au graph principal ; aucune `StorylineRelationship`, `SideQuestAvailability`, scene placeholder ou `StorylineSceneLink` n'est créée.
- Aucun import legacy automatique ; `localEventFlow` reste exclu.
- Visual Gate V1-09 produit en dark theme.
- Fichiers modifiés/créés : `packages/map_editor/lib/src/ui/canvas/storylines_workspace.dart`, `packages/map_editor/test/storylines_workspace_shell_test.dart`, captures V1-09, rapport V1-09.
- Tests exécutés : `flutter test test/storylines_workspace_shell_test.dart`, `flutter test test/storylines_current_global_story_characterization_test.dart`, `flutter test test/narrative_workspace_projection_test.dart`, analyse ciblée, `rg` anti-couleurs.
- Prochain lot recommandé : `NS-STORYLINES-V1-10 — Graph From StorylineAsset V0`.

### 2026-05-29 — NS-STORYLINES-V1-08

- Structure Tab Authoring V0 livré côté editor : création de chapitres et d'étapes narratives dans `ProjectManifest.storylines`.
- Mutations immuables via le notifier editor existant ; aucun modèle `map_core` modifié.
- IDs `chapter_...` et `step_...` slugifiés, stables et collision-safe ; ordre chapitre/step calculé depuis les données existantes.
- Graph minimal mis à jour pour afficher les vrais compteurs chapitres/steps sans branches ou edges fake.
- Visual Gate V1-08 produit en dark theme.
- Prochain lot recommandé : `NS-STORYLINES-V1-09 — Create Side Quest Flow V0`.

### 2026-05-28 — NS-STORYLINES-V1-07-bis

- Cleanup technique sans changement produit sur `storylines_workspace.dart`.
- Suppression de l'état local mort `_selectedGlobalStoryId`; confirmation que `_LegacyStorylinesWorkspaceState` et `_StorylineContentTab.chapters` ne sont plus présents.
- Suppression du `warnIfMissed: false` restant dans le test shell ; le CTA `Nouveau chapitre — bientôt` est maintenant asserté présent et désactivé.
- Tests ciblés, analyse ciblée, Design System Gate et Visual Gate V1-07 validés.
- Prochain lot recommandé : `NS-STORYLINES-V1-08 — Structure Tab Authoring V0`.

### 2026-05-28 — NS-STORYLINES-V1-07

- Create Main Storyline Flow V0 livré côté editor : `Nouvelle storyline` ouvre un formulaire minimal, crée une `StorylineAsset(type: main, status: draft)` dans `ProjectManifest.storylines`, puis sélectionne la storyline créée.
- UI Storylines reset vers deux tabs principales seulement : `Graph` et `Structure`.
- Graph et Structure se synchronisent sur `ProjectManifest.storylines`; le legacy `globalStory` reste non importé automatiquement.
- Aucun `map_core`, runtime, gameplay, battle, sideQuest, chapter, step ou scene placeholder modifié/créé.
- Visual Gate V1-07 produit en dark theme.
- Prochain lot recommandé : `NS-STORYLINES-V1-08 — Structure Tab Authoring V0`.

### 2026-05-28 — NS-STORYLINES-V1-06

- Preview d'import legacy livrée dans `map_core` via `buildLegacyGlobalStoryImportPreview(ProjectManifest)`.
- Les `ScenarioAsset(scope == globalStory)` produisent des candidats `StorylineAsset(type: main, status: draft)` sans mutation du manifest.
- Les metadata legacy Global Story / Step Studio sont importées quand elles sont lisibles ; sinon des issues stables signalent les limites.
- `localEventFlow` est explicitement ignoré et n'est jamais promu en `sideQuest`.
- Tests ajoutés pour aucun / un / plusieurs globalStory, existing storylines, collision d'id, import chapters/steps, missing step, outcomes non mappés, invalid metadata et no-mutation JSON.
- Non-objectifs respectés : aucun `ProjectManifest`, `StorylineAsset`, `ScenarioAsset`, generated file, build_runner, UI ou runtime modifié.
- Prochain lot recommandé : `NS-STORYLINES-V1-07 — Create Main Storyline Flow V0`.

### 2026-05-28 — NS-STORYLINES-V1-05

- `ProjectManifest.storylines: List<StorylineAsset>` intégré dans `map_core`.
- Compatibilité vieux projets confirmée : absence du champ `storylines` décodée en `[]`.
- Roundtrip JSON `ProjectManifest` avec storylines couvert par tests.
- Aucune migration legacy : `ScenarioAsset.globalStory` reste dans `scenarios` et ne crée pas automatiquement de `StorylineAsset`.
- `localEventFlow` reste exclu comme `sideQuest` par défaut.
- Non-objectifs respectés : `StorylineAsset` non modifié, `ScenarioAsset` non modifié, aucune UI, aucun runtime.
- Prochain lot recommandé : `NS-STORYLINES-V1-06 — Legacy GlobalStory Import Preview V0`.

### 2026-05-28 — NS-STORYLINES-V1-04

- Codec JSON manuel livré pour `StorylineAsset` et ses sous-objets essentiels.
- Enums Storylines sérialisés en strings lowerCamel stables, jamais en index.
- Decode strict : erreurs de forme en `FormatException`, invariants métiers préservés par les constructeurs.
- `ScriptCondition` sérialisé via le codec officiel existant ; aucun langage conditionnel local ajouté.
- Tests JSON ajoutés : roundtrip minimal/complet, defaults, enums, invalid JSON et validations au decode.
- Non-objectifs respectés : aucun `ProjectManifest.storylines`, aucune migration legacy, aucun `ScenarioAsset`, aucun generated file, aucun build_runner, aucune UI.
- Prochain lot recommandé : `NS-STORYLINES-V1-05 — ProjectManifest.storylines Integration V0`.

### 2026-05-28 — NS-STORYLINES-V1-03

- Premier modèle pur Storylines V1 livré dans `map_core`.
- `StorylineAsset` et sous-objets essentiels ajoutés : chapters, steps, scene links, scene refs, outcome links, effects, relationships, side quest availability, anchors, validation issues et legacy source.
- Enums Storylines V1 ajoutés pour type, status, scene link state/role, relationship kind, validation severity, effect type, anchor kind et scene ref kind.
- Tests ciblés ajoutés pour constructions valides, validations locales, références internes, règles d'état, immutabilité, equality/hashCode et absence de JSON codec.
- Non-objectifs respectés : aucun `toJson/fromJson`, aucun `ProjectManifest.storylines`, aucune migration legacy, aucune UI, aucun generated file.
- Prochain lot recommandé : `NS-STORYLINES-V1-04 — StorylineAsset JSON Codec V0`.

### 2026-05-28 — NS-STORYLINES-V1-02

- Contrat de données Storylines V1 livré.
- Data shape conceptuelle définie pour `StorylineAsset`, `StorylineType`, `StorylineStatus`, chapters, steps, scene links, outcome links, relationships, availability et validation issues.
- Décision : `StorylineAsset` stockera chapters/steps/scene links inline ; `ProjectManifest.storylines` futur devra décoder les vieux projets en `[]`.
- Décision : `StorylineSceneLink` V1 initial démarre avec `placeholder` et `linkedScenario`; dialogue/cinematic/battle restent dans le `ScenarioAsset` exécutable.
- Décision : outcome links V1 initial activent/complètent des `StorylineStep`; facts/world rules réservés à plus tard.
- Migration : legacy import preview non destructif depuis `ScenarioAsset.globalStory`; `localEventFlow` jamais promu automatiquement.
- Prochain lot recommandé : `NS-STORYLINES-V1-03 — StorylineAsset Pure Model V0`.

### 2026-05-28 — NS-STORYLINES-V1-01

- Décision d'architecture Storylines V1 livrée.
- Modèle recommandé : `StorylineAsset` authoring model + `ScenarioAsset` executable scene flow.
- `StorylineAsset` devient la source produit pour Storylines, Chapters, Story Steps, scene links, outcomes, relationships, side quest availability et validation issues.
- `ScenarioAsset` reste le modèle exécutable pour les scènes/flows runtime et n'est pas enrichi comme conteneur produit Storyline.
- `localEventFlow` reste exclu comme `sideQuest` par défaut.
- Décision Graph : `Structure` est source d'authoring ; `Graph` est généré/read-only en V1 initial, édition limitée plus tard.
- Prochain lot recommandé : `NS-STORYLINES-V1-02 — Storyline Authoring Data Shape Contract`.

### 2026-05-28 — NS-STORYLINES-V1-00

- Reset sémantique produit Storylines V1 livré.
- Clarification : le problème principal n'était pas technique mais sémantique / produit.
- Storylines V0 reste valide comme fondation, mais V1 doit rendre la création et l'organisation réellement utilisables.
- Contrat canonique documenté : Storyline, Chapter, Story Step, Scene, Scene inputs/outputs/outcomes, Side Quest, Event/Scene/Map chain.
- Décision produit recommandée : deux onglets principaux `Graph` et `Structure`; pas d'onglets globaux `Étapes` ou `Scènes`.
- Prochain lot recommandé : `NS-STORYLINES-V1-01 — Storyline Authoring Model Decision`.

### 2026-05-28 — NS-STORYLINES-CHECKPOINT

- Storylines V0 accepté avec limites V1 documentées.
- Vérifications ciblées passées : Storylines shell, caractérisation anti-fake, projection narrative et analyse ciblée.
- Design System Gate confirmé : aucun `Color(0x...)` / `Colors.*`.
- Visual Gate final inventorié : captures NS10 et NS11 recommandées pour structure/theme/overflow, avec limite Ahem.
- Limites V0 actées : pas de création storyline, pas de quête annexe, pas de modèle `StorylineAsset`, pas de graph editing, pas de scène métier finale.
- Prochain lot recommandé : `NS-STORYLINES-V1-00 — Storyline Semantics Reset / Usable Authoring Contract`.

### 2026-05-28 — NS-STORYLINES-11-bis

- Correction de cohérence documentaire de la roadmap.
- `NS-STORYLINES-11` est maintenant `DONE` dans toutes les sections structurantes.
- Le prochain lot reste `NS-STORYLINES-CHECKPOINT`.
- Aucun code, test, screenshot ou modèle modifié.

### 2026-05-28 — NS-STORYLINES-11

- Câblage d'une sélection locale de `globalStory` existante depuis le panneau secondaire Storylines.
- Synchronisation read-only du header, des KPI dérivés, du graph, de l'inspecteur Storyline et de la tab `Chapitres` avec la storyline sélectionnée.
- Conservation des tabs réellement branchées à `Graph` / `Chapitres`; `Étapes`, `Scènes`, `Statistiques`, `Tests` restent non mutantes.
- Réinitialisation prudente de la sélection de chapitre lorsque la storyline effective change.
- Actions futures conservées disabled / non mutantes : `Nouvelle storyline`, `Valider`, `+`, `Nouveau chapitre`, recherche.
- Visual Gate dark interaction produit : `ns_storylines_11_interaction_default_graph.png`, `ns_storylines_11_interaction_selected_story_graph.png`, `ns_storylines_11_interaction_selected_story_chapters.png`.
- Design System Gate confirmé : aucun `Color(0x...)` / `Colors.*` ajouté ; wiring via primitives PokeMap existantes.
- Fake data : aucune donnée cible Selbrume, aucune quête annexe fake, aucun `localEventFlow` promu en storyline/quête/chapter/node.
- V1 Creation Readiness documenté : modèle, types, unicité, flow auteur, validation et migration à décider avant création.
- Prochain lot recommandé : `NS-STORYLINES-CHECKPOINT — Storylines V0 Acceptance Checkpoint`.

### 2026-05-28 — NS-STORYLINES-10

- Harmonisation visuelle V0 du workspace Storylines sans ajout de feature métier.
- Vue `Graph` : canvas plus dominant, header plus compact, nodes plus compacts, edge layer plus lisible, légende et contrôles read-only plus discrets.
- Vue `Chapitres` : proportion liste/inspecteur stabilisée, cards de chapitres et rows d'étapes narratives compactées, inspecteur chapitre mieux équilibré.
- Visual Gate dark complet produit : `ns_storylines_10_graph_desktop.png`, `ns_storylines_10_graph_focus.png`, `ns_storylines_10_graph_center.png`, `ns_storylines_10_chapters_desktop.png`, `ns_storylines_10_chapters_focus.png`, `ns_storylines_10_chapters_center.png`.
- Design System Gate confirmé : aucun `Color(0x...)` / `Colors.*` ajouté ; harmonisation via primitives PokeMap et `context.pokeMapColors`.
- Fake data : aucune donnée cible Selbrume, aucun tag/world rule/fact/activité, aucune quête annexe fake, aucune action future activée.
- Prochain lot recommandé : `NS-STORYLINES-11 — Storylines Interaction Wiring V0`.

### 2026-05-28 — NS-STORYLINES-09

- Livraison de l'onglet `Chapitres` avec sélection locale de chapitre : premier chapitre réel sélectionné par défaut, clic sur un autre chapitre limité à l'état UI local.
- Ajout d'un inspecteur chapitre read-only avec titre, description, ordre, source `Global Story Studio`, mode `Lecture seule` et compteur d'étapes narratives.
- Ajout de l'ordre des étapes narratives depuis les vraies `NarrativeStepSummary`, sans drag/drop, édition, navigation ou mutation projet.
- Conservation des protections NS08-ter : graph spatial par défaut, tab `Chapitres` accessible, tabs futures non mutantes, actions futures disabled / non mutantes.
- Visual Gate dark produit : `ns_storylines_09_chapter_inspector_desktop.png`, `ns_storylines_09_chapter_inspector_focus.png`, `ns_storylines_09_chapter_inspector_center.png`.
- Design System Gate confirmé : aucun `Color(0x...)` / `Colors.*` ajouté ; composants Storylines feature-specific composés avec primitives PokeMap.
- Fake data : aucun `Scènes du chapitre`, aucun statut éditorial fake, aucun `localEventFlow` affiché comme chapitre ou étape.
- Prochain lot recommandé : `NS-STORYLINES-10 — Storyline Visual Harmonization / Visual Gate V0`.

### 2026-05-28 — NS-STORYLINES-08-ter

- Transformation du graph en vrai canvas spatial read-only : nodes positionnés dans un `Stack`, layer d'edges `CustomPainter`, grille conservée et légende compacte.
- Conservation stricte des données réelles : `NarrativeChapterSummary` comme nodes macro, previews compactes de `NarrativeStepSummary`, fallback steps et empty state existants.
- Aucun changement métier : pas de création, édition, drag/drop, mini-map active, zoom actif, quêtes annexes, tags, world rules, facts ou activité récente.
- Tests Storylines renforcés avec clés `storylines-graph-spatial-layer`, `storylines-graph-edge-layer`, `storylines-graph-node-start`, nodes de chapters et note read-only.
- Visual Gate dark produit : `ns_storylines_08_ter_true_graph_desktop.png`, `ns_storylines_08_ter_true_graph_focus.png`, `ns_storylines_08_ter_true_graph_center.png`.
- Design System Gate confirmé : aucun `Color(0x...)` / `Colors.*` ajouté ; couleurs des edges et surfaces via `context.pokeMapColors`.
- Prochain lot recommandé inchangé : `NS-STORYLINES-09 — Chapters Inspector / Scene Ordering Read-only V0`.

### 2026-05-28 — NS-STORYLINES-08-bis

- Réalignement visuel de l'onglet `Graph` avec l'image cible principale, utilisée uniquement comme référence de composition.
- Conservation de `Graph` comme vue par défaut.
- Remplacement de la lecture graph trop verticale par un canvas sombre avec grille tokenisée, flux principal, nodes macro de chapitres réels et previews de steps réelles.
- Conservation de la tab `Chapitres` NS-STORYLINES-08 et des tabs futures non mutantes.
- Conservation des actions futures disabled / non mutantes : `Nouvelle storyline`, `Valider`, `+`, `Nouveau chapitre`.
- Aucun changement métier, aucun modèle core, aucun provider, aucun runtime/gameplay/battle.
- Production des captures Visual Gate dark `ns_storylines_08_bis_graph_target_desktop.png`, `ns_storylines_08_bis_graph_target_focus.png`, `ns_storylines_08_bis_graph_target_center.png`.
- Confirmation : aucune donnée cible hardcodée, aucune quête annexe fake, aucune mini-map / zoom actif, aucun `Color(0x...)` / `Colors.*` ajouté dans les fichiers touchés.
- Prochain lot recommandé inchangé : `NS-STORYLINES-09 — Chapters Inspector / Scene Ordering Read-only V0`.

### 2026-05-28 — NS-STORYLINES-08

- Ajout d'un read model editor-side `NarrativeChapterSummary` dans la projection narrative.
- Extraction des chapitres depuis `GlobalStoryStudioDocument.chapters`, avec ordre conservé, steps résolues, step ids manquants détectés depuis la metadata brute, et exclusion des `localEventFlow`.
- Ajout d'un état UI local pour basculer uniquement entre `Graph` et `Chapitres` sans mutation projet ou état narratif persistant.
- Ajout du contenu `Chapitres` read-only : source `Global Story Studio`, liste ordonnée, description réelle, compteur d'étapes narratives, aperçu des étapes liées, bouton `Nouveau chapitre` disabled et empty state honnête.
- Conservation du panneau secondaire NS-STORYLINES-04, du header/tabs/KPI NS-STORYLINES-05, du graph NS-STORYLINES-06 et de l'inspecteur NS-STORYLINES-07.
- Adaptation des tests Storylines et projection ; vérification des tabs futures non mutantes, de l'absence de `localEventFlow`, de l'absence de `Scènes du chapitre` et de l'absence de statuts éditoriaux fake.
- Production des captures Visual Gate dark `ns_storylines_08_chapters_tab_desktop.png`, `ns_storylines_08_chapters_tab_focus.png`, `ns_storylines_08_chapters_tab_center.png`.
- Confirmation : aucune donnée cible hardcodée, aucune création/édition/suppression/réorganisation active, aucun `Color(0x...)` / `Colors.*` ajouté dans les fichiers touchés.
- Tests ciblés Storylines / caractérisation / projection passés ; analyse ciblée clean.
- Prochain lot recommandé : `NS-STORYLINES-09 — Chapters Inspector / Scene Ordering Read-only V0`.

### 2026-05-28 — NS-STORYLINES-07

- Remplacement de l'inspecteur placeholder droit par un panneau `Détails de la storyline` read-only.
- Affichage des données réelles de la storyline sélectionnée : titre, description, type prudent `Storyline principale`, source `ScenarioAsset globalStory`, compteur d'étapes narratives et compteur de cutscenes liées.
- Ajout de sections futures explicitement non branchées : `Tags`, `Règles du monde`, `Facts`, `Activité récente`, `Quêtes liées`.
- Ajout d'un empty state honnête `Aucune storyline sélectionnée.` lorsqu'aucune globalStory n'est disponible.
- Conservation du panneau secondaire NS-STORYLINES-04, du header/tabs/KPI NS-STORYLINES-05 et du graph placeholder NS-STORYLINES-06.
- Adaptation des tests Storylines et caractérisation ; vérification que `localEventFlow` ne devient pas une donnée d'inspecteur.
- Production des captures Visual Gate dark `ns_storylines_07_inspector_desktop.png`, `ns_storylines_07_inspector_focus.png`, `ns_storylines_07_inspector_panel.png`.
- Confirmation : aucune donnée cible hardcodée, aucune section future active, aucune action mutante, aucun `Color(0x...)` / `Colors.*` ajouté dans les fichiers touchés.
- Tests ciblés Storylines / caractérisation / projection passés ; analyse ciblée clean.
- Prochain lot recommandé : `NS-STORYLINES-08 — Chapters Tab Read-only V0`.

### 2026-05-28 — NS-STORYLINES-06

- Remplacement du placeholder `Graph — à venir / Placeholder read-only` par une zone `Graph read-only`.
- Affichage des étapes narratives réelles de la storyline sélectionnée via `NarrativeStepSummary`.
- Ajout d'un état vide honnête pour une storyline avec document Step Studio explicitement vide.
- Les relations détaillées restent `à venir` ; aucun réseau de branches, quête annexe, mini-map, zoom control ou interaction graph n'a été ajouté.
- Conservation du header/tabs/KPI NS-STORYLINES-05, du panneau secondaire NS-STORYLINES-04 et de l'inspecteur placeholder.
- Adaptation des tests Storylines et caractérisation ; vérification de l'absence de `localEventFlow` dans le graph.
- Production des captures Visual Gate dark `ns_storylines_06_graph_placeholder_desktop.png`, `ns_storylines_06_graph_placeholder_focus.png`, `ns_storylines_06_graph_placeholder_center.png`.
- Confirmation : aucune donnée cible hardcodée, aucune branche imaginaire, aucune action future activée, aucun `Color(0x...)` / `Colors.*` ajouté dans les fichiers touchés.
- Tests ciblés Storylines / caractérisation / projection passés ; analyse ciblée clean.
- Prochain lot recommandé : `NS-STORYLINES-07 — Storyline Inspector Read-only V0`.

### 2026-05-28 — NS-STORYLINES-05

- Ajout du header central Storyline V0 avec titre réel, description réelle, type prudent `Storyline principale`, état `Lecture seule`, source réelle et mode `Storylines V0`.
- Ajout de tabs Storyline visibles via `PokeMapSegmentedTabs` : `Graph` principal, `Chapitres`, `Étapes`, `Scènes`, `Statistiques`, `Tests` non branchés / non mutants.
- Ajout de KPI read-only avec `PokeMapMetricCard` : `Storylines globales`, `Étapes narratives`, `Cutscenes liées` sourcés ; `Chapitres` et `Avertissements structurels` restent `À venir`.
- Conservation du panneau secondaire NS-STORYLINES-04 et du layout trois zones ; aucun graph riche, inspector final ou onglet Chapitres actif n'a été ajouté.
- Adaptation des tests Storylines et caractérisation ; vérification de la non-mutation des tabs futures et de l'absence de données cible fake.
- Production des captures Visual Gate dark `ns_storylines_05_header_tabs_kpi_desktop.png`, `ns_storylines_05_header_tabs_kpi_focus.png`, `ns_storylines_05_header_tabs_kpi_center.png`.
- Confirmation : aucune donnée cible hardcodée, aucun `localEventFlow` promu en quête/storyline/KPI, aucune action future activée, aucun `Color(0x...)` / `Colors.*` ajouté dans les fichiers touchés.
- Tests ciblés Storylines / caractérisation / projection passés ; analyse ciblée clean.
- Prochain lot recommandé : `NS-STORYLINES-06 — Storyline Graph Read-only Placeholder V0`.

### 2026-05-28 — NS-STORYLINES-04

- Transformation du panneau secondaire placeholder en liste Storylines read-only structurée.
- Affichage des `ScenarioAsset globalStory` réels avec nom, description, type prudent `Storyline principale`, nombre d'étapes dérivé, et mention `Read-only / Source réelle`.
- Ajout d'une action `+` visible mais disabled/non mutante et d'une recherche `Recherche à venir`.
- Ajout d'une section `Quêtes annexes` explicitement à venir ; aucun `localEventFlow` n'est présenté comme quête annexe.
- Rendu du panneau secondaire scrollable via `PokeMapPanel(expandChild: true)` pour éviter l'overflow medium.
- Adaptation des tests Storylines et caractérisation NS-STORYLINES-02 ; les données réelles peuvent désormais apparaître à la fois dans le panneau secondaire et la zone centrale.
- Production des captures Visual Gate dark `ns_storylines_04_secondary_panel_desktop.png`, `ns_storylines_04_secondary_panel_focus.png`, `ns_storylines_04_secondary_panel_only.png`.
- Confirmation : aucune donnée cible hardcodée, aucune action future activée, aucun `Color(0x...)` / `Colors.*` ajouté dans les fichiers touchés.
- Tests ciblés Storylines / caractérisation / projection passés ; analyse ciblée clean.
- Prochain lot recommandé : `NS-STORYLINES-05 — Storyline Header / Tabs / KPI Read-only V0`.

### 2026-05-28 — NS-STORYLINES-03

- Création de `StorylinesWorkspace`, premier shell Storylines V0 read-only.
- Branchement de `EditorWorkspaceMode.globalStory` vers le shell Storylines V0 dans `NarrativeWorkspaceCanvas`.
- Conservation des anciens fichiers Global Story Studio sans suppression.
- Adaptation du test de caractérisation NS-STORYLINES-02 pour préserver les garanties anti-fake sur le nouveau shell.
- Ajout de `storylines_workspace_shell_test.dart` couvrant le shell, les données réelles, les actions disabled, l'absence de Maps et le gate anti-couleurs.
- Production des captures Visual Gate desktop, focus et medium/panels.
- Confirmation : aucune donnée cible hardcodée, aucune action future activée, aucun `Color(0x...)` / `Colors.*` ajouté dans les fichiers du lot.
- Tests ciblés Storylines / Global Story / Projection passés ; analyse ciblée clean.
- Prochain lot recommandé : `NS-STORYLINES-04 — Storylines Secondary List Panel Read-only V0`.

### 2026-05-28 — NS-STORYLINES-03-bis

- Durcissement du test `keeps future header actions disabled and non-mutating`.
- Vérification explicite que `Nouvelle storyline` et `Valider` existent, que leurs `PokeMapButton.onPressed` sont `null`, et qu'un tap ne modifie ni workspace, ni projet, ni scénario sélectionné.
- Suppression du tap silencieux `warnIfMissed: false` dans le test.
- Application de `PokeMapTheme.light()`, `PokeMapTheme.dark()` et `ThemeMode.dark` dans le harness Visual Gate.
- Régénération des trois screenshots `ns_storylines_03_shell_desktop.png`, `ns_storylines_03_shell_focus.png`, `ns_storylines_03_shell_panels.png`.
- Aucun code production, aucune UI, aucun modèle et aucune primitive design system modifiés.
- Prochain lot recommandé inchangé : `NS-STORYLINES-04 — Storylines Secondary List Panel Read-only V0`.

### 2026-05-27 — NS-STORYLINES-02

- Ajout du test `storylines_current_global_story_characterization_test.dart`.
- Vérification que `EditorWorkspaceMode.globalStory` rend encore `NarrativeWorkspaceCanvas > NarrativeStudioShell > GlobalStoryStudioWorkspace`.
- Vérification que les données visibles viennent du `ScenarioAsset globalStory` et des metadata `GlobalStoryStudioDocument` / `StepStudioDocument`.
- Vérification anti-fake : données cible Storylines (`La brume du phare`, quêtes annexes cible, tags cible, `412`, `18`, etc.) absentes avec une fixture neutre.
- Vérification que `localEventFlow` n'est pas affiché comme quête annexe Storylines.
- Vérification que `Maps` reste absent de la sidebar interne Narrative Studio.
- Régressions Global Story / Projection passées et analyse ciblée clean.
- Aucun code production, modèle, widget ou design system modifié.
- Prochain lot recommandé : `NS-STORYLINES-03 — Storylines Workspace Shell Layout V0`.

### 2026-05-27 — NS-STORYLINES-01

- Création du contrat de données Storylines V0.
- Clarification du mapping `Storyline = ScenarioAsset globalStory` en V0.
- Clarification `Chapter = GlobalStoryChapter`.
- Clarification `Step = Étape narrative` et prudence sur le terme `Scène`.
- Documentation des KPI affichables, disabled ou fake risk.
- Documentation du graph V0 read-only et de l'inspecteur V0.
- Confirmation que `Maps` reste absent de la sidebar interne en V0.
- Aucun code, test, modèle, widget ou provider modifié.
- Prochain lot recommandé : `NS-STORYLINES-02 — Current Global Story Characterization / Anti-Fake Tests V0`.

### 2026-05-27 — NS-STORYLINES-ROADMAP-00

- Création de la roadmap Storylines.
- Ajout des garde-fous design system.
- Ajout du Design System Gate obligatoire.
- Ajout des lots Storylines V0 de `NS-STORYLINES-01` à `NS-STORYLINES-CHECKPOINT`.
- Ajout du protocole de mise à jour obligatoire pour les futurs lots.
- Documentation de la tension `Maps` / sidebar.
- Prochain lot recommandé : `NS-STORYLINES-01 — Storylines Read Model / Data Contract V0`.

```


## 13. Limites restantes

- La liaison de scène reste disabled : aucun `StorylineSceneLink` n'est créé.
- Le reorder des chapitres n'est pas livré dans ce bis ; seul le reorder DnD des steps est actif.
- Recherche / filtre / tri sont visibles mais disabled, afin de ne pas mentir sur une fonctionnalité non implémentée.
- Le test shell complet reste bloqué par un golden V1-12 préexistant absent, hors fichiers de ce lot.

## 14. Autocritique honnête

Le premier patch a trop augmenté la hauteur des rows de steps en mettant les actions sur une seconde ligne ; les tests ont révélé que les chapitres suivants partaient hors écran. La correction finale garde les rows compactes, avec edit/delete visibles et la liaison scène déplacée en action disabled toolbar + note de chapitre.

Le scope demandé mélangeait un bis layout et des capacités qui étaient prévues pour le lot suivant. J'ai livré l'authoring minimal demandé pour chapters/steps, mais j'ai laissé les fonctionnalités qui nécessitent un vrai modèle/picker de scènes hors scope.

## 15. Regard critique sur le prompt

Le prompt demande à la fois de ne pas démarrer le lot edit/delete et de fournir edit/delete/reorder. J'ai interprété cela comme : ne pas faire une refonte globale V1.1-01, mais fournir l'authoring minimal directement nécessaire à la vue accordéon. Cette ambiguïté devrait être clarifiée avant le prochain lot pour éviter de dupliquer le périmètre.

## 16. Git final

```text
git status --short --untracked-files=all
 M packages/map_editor/lib/src/ui/canvas/storylines/storylines_structure_view.dart
 M packages/map_editor/lib/src/ui/canvas/storylines_workspace.dart
 M packages/map_editor/test/storylines_seed_graph_usability_test.dart
 M packages/map_editor/test/storylines_structure_layout_test.dart
 M packages/map_editor/test/storylines_workspace_shell_test.dart
 M reports/narrativeStudio/storylines/road_map_storylines.md
?? reports/narrativeStudio/storylines/ns_storylines_structure_bis_full_width_accordion_authoring.md
?? reports/narrativeStudio/storylines/screenshots/ns_storylines_structure_bis_authoring_actions.png
?? reports/narrativeStudio/storylines/screenshots/ns_storylines_structure_bis_collapsed_chapter.png
?? reports/narrativeStudio/storylines/screenshots/ns_storylines_structure_bis_expanded_chapter_steps.png
?? reports/narrativeStudio/storylines/screenshots/ns_storylines_structure_bis_full_width_accordion.png
?? reports/narrativeStudio/storylines/screenshots/ns_storylines_structure_bis_graph_regression.png
```

```text
git diff --stat
 .../storylines/storylines_structure_view.dart      | 955 ++++++++++++---------
 .../lib/src/ui/canvas/storylines_workspace.dart    | 428 ++++++++-
 .../test/storylines_seed_graph_usability_test.dart |  10 +-
 .../test/storylines_structure_layout_test.dart     | 217 ++++-
 .../test/storylines_workspace_shell_test.dart      |  24 +-
 .../storylines/road_map_storylines.md              |  16 +-
 6 files changed, 1198 insertions(+), 452 deletions(-)
```

```text
git diff --name-only
packages/map_editor/lib/src/ui/canvas/storylines/storylines_structure_view.dart
packages/map_editor/lib/src/ui/canvas/storylines_workspace.dart
packages/map_editor/test/storylines_seed_graph_usability_test.dart
packages/map_editor/test/storylines_structure_layout_test.dart
packages/map_editor/test/storylines_workspace_shell_test.dart
reports/narrativeStudio/storylines/road_map_storylines.md
```

```text
git diff --check
Sortie : <vide>
```

## 17. Addendum — chapeau Graph / Structure

Après revue visuelle, le chapeau de `Structure` a été aligné exactement sur celui de `Graph` :

- `_StorylinesV1MainPanel` utilise maintenant un mode compact partagé pour `Graph` et `Structure` ;
- le rendu du contenu central passe par un `switch (selectedTab)` ;
- les captures Structure bis ont été régénérées avec le header compact et la micro-row KPI ;
- le test `Structure uses a full-width vertical chapter accordion` vérifie désormais `storylines-header-section-compact` et `storylines-kpi-strip-compact`.

Vérifications additionnelles :

```text
Command: cd packages/map_editor && flutter test --reporter=compact test/storylines_structure_layout_test.dart --plain-name "Structure uses a full-width vertical chapter accordion"
Résultat: 00:02 +1: All tests passed!
```

```text
Command: cd packages/map_editor && flutter test --reporter=compact test/storylines_structure_layout_test.dart --update-goldens
Résultat: 00:05 +7: All tests passed!
```

```text
Command: cd packages/map_editor && flutter test --reporter=compact test/storylines_structure_layout_test.dart
Résultat: 00:04 +7: All tests passed!
```

```text
Command: cd packages/map_editor && flutter test --reporter=compact test/storylines_seed_graph_usability_test.dart
Résultat: 00:04 +6: All tests passed!
```

```text
Command: cd packages/map_editor && flutter analyze --no-fatal-infos lib/src/ui/canvas/storylines_workspace.dart lib/src/ui/canvas/storylines/storylines_structure_view.dart test/storylines_structure_layout_test.dart test/storylines_seed_graph_usability_test.dart
Sortie:
Analyzing 4 items...
No issues found! (ran in 2.9s)
```

## 18. Addendum — accordéons natifs et suppression dans Modifier

Après revue visuelle, les cards accordéon custom de `Structure` ont été remplacées par les accordéons natifs Flutter :

- `StorylinesStructureView` utilise `ExpansionPanelList` / `ExpansionPanel` ;
- le chapitre ouvert peut maintenant être refermé ;
- les boutons inline `Supprimer` ont été retirés des headers de chapitre et des rows d'étape ;
- la suppression est disponible depuis `Modifier le chapitre` et `Modifier l'étape narrative`, puis conserve le confirm dialog existant ;
- les captures Structure bis ont été régénérées avec le rendu accordéon natif.

Vérifications additionnelles :

```text
Command: cd packages/map_editor && flutter test --reporter=compact test/storylines_structure_layout_test.dart
Résultat: 00:05 +8: All tests passed!
```

```text
Command: cd packages/map_editor && flutter test --reporter=compact test/storylines_seed_graph_usability_test.dart
Résultat: 00:03 +6: All tests passed!
```

```text
Command: cd packages/map_editor && flutter test --reporter=compact test/storylines_current_global_story_characterization_test.dart
Résultat: 00:02 +2: All tests passed!
```

```text
Command: cd packages/map_editor && flutter test --reporter=compact test/narrative_workspace_projection_test.dart
Résultat: 00:01 +3: All tests passed!
```

```text
Command: cd packages/map_editor && flutter analyze --no-fatal-infos lib/src/ui/canvas/storylines_workspace.dart lib/src/ui/canvas/storylines/storylines_graph_model.dart lib/src/ui/canvas/storylines/storylines_graph_painter.dart lib/src/ui/canvas/storylines/storylines_graph_view.dart lib/src/ui/canvas/storylines/storylines_structure_view.dart test/storylines_workspace_shell_test.dart test/storylines_current_global_story_characterization_test.dart test/narrative_workspace_projection_test.dart test/storylines_seed_graph_usability_test.dart test/storylines_structure_layout_test.dart
Sortie:
Analyzing 10 items...
No issues found! (ran in 2.0s)
```

```text
Command: rg "Color\(0x|Colors\." packages/map_editor/lib/src/ui/canvas/storylines_workspace.dart packages/map_editor/lib/src/ui/canvas/storylines packages/map_editor/test/storylines_workspace_shell_test.dart packages/map_editor/test/storylines_seed_graph_usability_test.dart packages/map_editor/test/storylines_structure_layout_test.dart
Sortie : <vide>
```

```text
Command: rg "La brume du phare|Les cristaux de sel|Le Goélise du port|La cabane du phare|Maël|Lysa|Mado|Yvon|Soline" packages/map_editor/lib packages/map_core/lib
Sortie : <vide>
```
