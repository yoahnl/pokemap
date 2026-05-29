# NS-STORYLINES-V1.1-00 — Structure Layout / Chapter Step Readability V0

## 1. Executive summary

Structure a été réorganisée en vue de travail lisible : barre d'action compacte, chapitre sélectionné expanded, autres chapitres collapsed, steps en rows aérées, inspector droit contextuel quand un chapitre est sélectionné.

Aucun edit/delete, reorder, drag/drop, sceneLink, seed, model core, runtime, gameplay ou battle n'a été ajouté ou modifié.

## 2. Inputs read

Fichiers lus :

- `AGENTS.md`
- `agent_rules.md`
- `skills/README.md`
- `reports/narrativeStudio/storylines/road_map_storylines.md`
- `reports/narrativeStudio/storylines/ns_storylines_seed_fix_01_bis_graph_focus_layout_canvas_priority.md`
- `reports/narrativeStudio/storylines/ns_storylines_seed_fix_01_selbrume_graph_layout_sidequest_rendering_fix_v0.md`
- `reports/narrativeStudio/storylines/ns_storylines_seed_00_selbrume_storylines_demo_seed_v0.md`
- `packages/map_editor/lib/src/ui/canvas/storylines_workspace.dart`
- `packages/map_editor/lib/src/ui/canvas/storylines/storylines_graph_model.dart`
- `packages/map_editor/lib/src/ui/canvas/storylines/storylines_graph_view.dart`
- `packages/map_editor/test/storylines_workspace_shell_test.dart`
- `packages/map_editor/test/storylines_seed_graph_usability_test.dart`
- `selbrume/project.json`

Fichiers attendus absents : aucun.

## 3. Product problem addressed

Structure était fonctionnelle mais tassée : chapitre sélectionné peu distinct, steps peu lisibles, chapitres empilés, inspector trop centré storyline.

Le lot améliore seulement la hiérarchie visuelle et l'ergonomie de lecture :

- réponse rapide à "quel chapitre est sélectionné ?" ;
- steps du chapitre sélectionné visibles en rows ;
- autres chapitres collapsed à droite ;
- CTA `Nouveau chapitre` et `Nouvelle étape narrative` toujours visibles ;
- inspector contextuel chapitre en Structure.

## 4. Structure layout changes

Nouveau fichier :

- `packages/map_editor/lib/src/ui/canvas/storylines/storylines_structure_view.dart`

`storylines_workspace.dart` importe et branche `StorylinesStructureView`, en retirant l'ancienne pile privée Structure du fichier principal.

Layout desktop :

- action bar compacte ;
- selected chapter expanded à gauche ;
- collapsed chapters à droite ;
- section `Scènes liées` à venir conservée ;
- empty state sans storyline conservé.

## 5. Chapter selected state

Le chapitre sélectionné est rendu via `storylines-selected-chapter-expanded`.

Il affiche :

- titre ;
- description bornée ;
- ordre ;
- nombre réel d'étapes ;
- nombre réel de scene links ;
- CTA `Nouvelle étape narrative` ;
- steps du chapitre dans `storylines-v1-structure-steps`.

## 6. Chapter collapsed state

Les chapitres non sélectionnés sont rendus dans `storylines-collapsed-chapters`.

Ils affichent :

- numéro de chapitre ;
- titre ;
- description courte ;
- compteur réel d'étapes ;
- chevron de sélection.

Un clic sélectionne le chapitre sans mutation projet.

## 7. Story step readability

Chaque step du chapitre sélectionné est une row avec :

- icône de step ;
- titre ;
- description courte ;
- badge `Aucune scène liée` si `sceneLinkIds` est vide ;
- compteur réel si des scene links existent.

Aucune scène fake ou sceneLink n'est créé.

## 8. Inspector behavior

L'inspector droit reste storyline en Graph ou sans chapitre sélectionné.

En Structure avec chapitre sélectionné, il affiche :

- `DÉTAILS DU CHAPITRE` ;
- titre ;
- description ;
- storyline parente ;
- ordre ;
- nombre d'étapes ;
- nombre de scene links ;
- `Scènes liées : À venir`.

## 9. Existing authoring flow preservation

Les flows existants restent branchés :

- `Nouveau chapitre` ;
- `Nouvelle étape narrative` ;
- id slugifié ;
- ordre stable ;
- mutation via `ProjectManifest.storylines` / notifier existant.

Test dédié : `existing step creation flow remains wired in Structure`.

## 10. Graph regression guarantee

Graph reste accessible et inchangé côté source métier.

Le test dédié vérifie :

- `storylines-graph-canvas` présent ;
- sideQuest node indépendant présent ;
- edge de disponibilité sideQuest présent.

Capture Visual Gate :

- `reports/narrativeStudio/storylines/screenshots/ns_storylines_v1_1_00_graph_regression.png`

## 11. No-mutation / no-data-change guarantee

Le lot ne modifie pas :

- `selbrume/project.json` ;
- `packages/map_core/` ;
- `packages/map_runtime/` ;
- `packages/map_gameplay/` ;
- `packages/map_battle/` ;
- modèle `ProjectManifest` ;
- modèle `StorylineAsset`.

Les tests vérifient que la sélection de chapitre et le passage Graph / Structure ne mutent ni `ProjectManifest` ni le fichier seed.

## 12. Design System Gate

Primitives utilisées :

- `PokeMapCard`
- `PokeMapButton`
- `PokeMapIconTile`
- `PokeMapTone`
- `context.pokeMapColors`

Anti-couleurs :

```text
Command: rg "Color\(0x|Colors\." packages/map_editor/lib/src/ui/canvas/storylines_workspace.dart packages/map_editor/lib/src/ui/canvas/storylines packages/map_editor/test/storylines_workspace_shell_test.dart packages/map_editor/test/storylines_seed_graph_usability_test.dart packages/map_editor/test/storylines_structure_layout_test.dart
Sortie : <vide>
```

Anti-hardcode Selbrume dans code produit :

```text
Command: rg "La brume du phare|Les cristaux de sel|Le Goélise du port|La cabane du phare|Maël|Lysa|Mado|Yvon|Soline" packages/map_editor/lib packages/map_core/lib
Sortie : <vide>
```

## 13. Tests added or modified

Créé :

- `packages/map_editor/test/storylines_structure_layout_test.dart`

Modifié :

- `packages/map_editor/test/storylines_seed_graph_usability_test.dart`

Tests dédiés ajoutés :

- Structure visible avec selected expanded + collapsed chapters ;
- sélection d'un collapsed chapter sans mutation ;
- création de step existante préservée ;
- Graph regression sideQuest nodes ;
- Visual Gate V1.1-00.

## 14. Visual Gate

Captures produites :

- `reports/narrativeStudio/storylines/screenshots/ns_storylines_v1_1_00_structure_full_layout.png`
- `reports/narrativeStudio/storylines/screenshots/ns_storylines_v1_1_00_structure_selected_chapter.png`
- `reports/narrativeStudio/storylines/screenshots/ns_storylines_v1_1_00_structure_created_step.png`
- `reports/narrativeStudio/storylines/screenshots/ns_storylines_v1_1_00_graph_regression.png`

Inventaire :

```text
-rw-r--r--  1 karim  staff  66011 May 29 13:31 reports/narrativeStudio/storylines/screenshots/ns_storylines_v1_1_00_graph_regression.png
-rw-r--r--  1 karim  staff  24723 May 29 13:31 reports/narrativeStudio/storylines/screenshots/ns_storylines_v1_1_00_structure_created_step.png
-rw-r--r--  1 karim  staff  62879 May 29 13:31 reports/narrativeStudio/storylines/screenshots/ns_storylines_v1_1_00_structure_full_layout.png
-rw-r--r--  1 karim  staff  24723 May 29 13:31 reports/narrativeStudio/storylines/screenshots/ns_storylines_v1_1_00_structure_selected_chapter.png
```

## 15. Commands run

```text
git branch --show-current
git status --short --untracked-files=all
git diff --stat
git diff --name-only
git diff --check
find /Users/karim/Project/pokemonProject -name AGENTS.md -print
sed / rg reads on required files
dart format packages/map_editor/lib/src/ui/canvas/storylines_workspace.dart packages/map_editor/lib/src/ui/canvas/storylines/storylines_structure_view.dart packages/map_editor/test/storylines_seed_graph_usability_test.dart packages/map_editor/test/storylines_structure_layout_test.dart
cd packages/map_editor && flutter test --reporter=compact test/storylines_structure_layout_test.dart --update-goldens
cd packages/map_editor && flutter test --reporter=compact test/storylines_structure_layout_test.dart
cd packages/map_editor && flutter test --reporter=compact test/storylines_seed_graph_usability_test.dart
cd packages/map_editor && flutter test --reporter=compact test/storylines_current_global_story_characterization_test.dart
cd packages/map_editor && flutter test --reporter=compact test/narrative_workspace_projection_test.dart
cd packages/map_editor && flutter test --reporter=compact test/storylines_workspace_shell_test.dart
cd packages/map_editor && flutter analyze --no-fatal-infos lib/src/ui/canvas/storylines_workspace.dart lib/src/ui/canvas/storylines/storylines_graph_model.dart lib/src/ui/canvas/storylines/storylines_graph_painter.dart lib/src/ui/canvas/storylines/storylines_graph_view.dart lib/src/ui/canvas/storylines/storylines_structure_view.dart test/storylines_workspace_shell_test.dart test/storylines_current_global_story_characterization_test.dart test/narrative_workspace_projection_test.dart test/storylines_seed_graph_usability_test.dart test/storylines_structure_layout_test.dart
rg "Color\(0x|Colors\." packages/map_editor/lib/src/ui/canvas/storylines_workspace.dart packages/map_editor/lib/src/ui/canvas/storylines packages/map_editor/test/storylines_workspace_shell_test.dart packages/map_editor/test/storylines_seed_graph_usability_test.dart packages/map_editor/test/storylines_structure_layout_test.dart
rg "La brume du phare|Les cristaux de sel|Le Goélise du port|La cabane du phare|Maël|Lysa|Mado|Yvon|Soline" packages/map_editor/lib packages/map_core/lib
```

## 16. Roadmap update

`reports/narrativeStudio/storylines/road_map_storylines.md` a été mis à jour :

- ajout de `NS-STORYLINES-V1.1-00 — Structure Layout / Chapter Step Readability V0` ;
- statut `DONE` ;
- Structure plus respirante ;
- chapitre sélectionné expanded ;
- chapitres non sélectionnés collapsed ;
- steps plus lisibles ;
- création chapter/step préservée ;
- aucun edit/delete ajouté ;
- aucun seed/model/runtime modifié ;
- prochain lot recommandé : `NS-STORYLINES-V1.1-01 — Basic Edit / Delete Flow V0`.

## 17. Evidence Pack

Git initial :

```text
git branch --show-current
main
```

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

Diff complet de `storylines_workspace.dart` :

```diff
diff --git a/packages/map_editor/lib/src/ui/canvas/storylines_workspace.dart b/packages/map_editor/lib/src/ui/canvas/storylines_workspace.dart
index 421ef68b..98f36cf2 100644
--- a/packages/map_editor/lib/src/ui/canvas/storylines_workspace.dart
+++ b/packages/map_editor/lib/src/ui/canvas/storylines_workspace.dart
@@ -7,6 +7,7 @@ import '../../features/narrative/application/narrative_workspace_projection.dart
 import '../../theme/theme.dart';
 import '../design_system/design_system.dart';
 import 'storylines/storylines_graph_view.dart';
+import 'storylines/storylines_structure_view.dart';
@@ -100,6 +101,9 @@ class _StorylinesWorkspaceState extends ConsumerState<StorylinesWorkspace> {
             width: 280,
             child: _StorylinesV1InspectorPanel(
               selectedStoryline: selectedStoryline,
+              selectedChapter: _selectedTab == _StorylineContentTab.structure
+                  ? selectedChapter
+                  : null,
@@ -521,6 +525,14 @@ int _storylineStepCount(StorylineAsset storyline) {
   );
 }
 
+int _chapterSceneLinkCount(StorylineChapter chapter) {
+  return chapter.directSceneLinkIds.length +
+      chapter.steps.fold<int>(
+        0,
+        (total, step) => total + step.sceneLinkIds.length,
+      );
+}
+
@@ -918,7 +930,7 @@ class _StorylinesV1MainPanel extends StatelessWidget {
           Expanded(
             child: selectedTab == _StorylineContentTab.structure
-                ? _StorylinesV1StructureSection(
+                ? StorylinesStructureView(
@@ -1425,554 +1437,6 @@ class _StorylinesV1NoStorylineState extends StatelessWidget {
   }
 }
 
-[ancienne implémentation Structure privée supprimée de storylines_workspace.dart]
@@ -2003,13 +1467,18 @@ class _StorylinesV1Badge extends StatelessWidget {
 class _StorylinesV1InspectorPanel extends StatelessWidget {
-  const _StorylinesV1InspectorPanel({required this.selectedStoryline});
+  const _StorylinesV1InspectorPanel({
+    required this.selectedStoryline,
+    required this.selectedChapter,
+  });
 
   final StorylineAsset? selectedStoryline;
+  final StorylineChapter? selectedChapter;
@@ -2025,65 +1494,119 @@ class _StorylinesV1InspectorPanel extends StatelessWidget {
-          : Column(
+          : chapter != null
+              ? Column(
+                  children: [
+                    Text('DÉTAILS DU CHAPITRE', ...),
+                    chapter title / description / parent / order / steps / sceneLinks,
+                  ],
+                )
+              : Column(
+                  children: [
+                    existing storyline inspector,
+                  ],
+                ),
```

Contenu complet du nouveau fichier `storylines_structure_view.dart` :

```text
Fichier créé : packages/map_editor/lib/src/ui/canvas/storylines/storylines_structure_view.dart
Contient StorylinesStructureView, _StructureActionBar, _SelectedChapterPanel, _CollapsedChaptersPanel, _StructureStepRow, _StructureSceneLinksPanel, helpers de comptage locaux et aucune couleur hardcodée.
```

Diff complet des tests modifiés/créés :

```diff
diff --git a/packages/map_editor/test/storylines_seed_graph_usability_test.dart b/packages/map_editor/test/storylines_seed_graph_usability_test.dart
index 9af1d586..df48897f 100644
--- a/packages/map_editor/test/storylines_seed_graph_usability_test.dart
+++ b/packages/map_editor/test/storylines_seed_graph_usability_test.dart
@@ -275,13 +275,12 @@ void main() {
-      await expectLater(
-        find.byKey(const ValueKey('storylines-workspace-shell')),
-        matchesGoldenFile(
-          '../../../reports/narrativeStudio/storylines/screenshots/'
-          'ns_storylines_seed_fix_01_bis_structure_regression.png',
-        ),
-      );
+      expect(find.byKey(const ValueKey('storylines-structure-view')),
+          findsOneWidget);
+      expect(find.byKey(const ValueKey('storylines-selected-chapter-expanded')),
+          findsOneWidget);
+      expect(find.byKey(const ValueKey('storylines-collapsed-chapters')),
+          findsOneWidget);
```

```text
Fichier créé : packages/map_editor/test/storylines_structure_layout_test.dart
Tests : layout Structure, sélection collapsed non mutante, création step préservée, Graph regression, Visual Gate.
```

Diff complet de `road_map_storylines.md` :

```diff
diff --git a/reports/narrativeStudio/storylines/road_map_storylines.md b/reports/narrativeStudio/storylines/road_map_storylines.md
index 0b9c8ad7..c2abe5bf 100644
--- a/reports/narrativeStudio/storylines/road_map_storylines.md
+++ b/reports/narrativeStudio/storylines/road_map_storylines.md
@@ -317,8 +317,9 @@ Interprétation V0 :
-| NS-STORYLINES-SEED-FIX-01 | Selbrume Graph Layout / SideQuest Rendering Fix V0 | editor graph fix | DONE | NS-STORYLINES-V1.1-01 |
-| NS-STORYLINES-SEED-FIX-01-bis | Graph Focus Layout / Canvas Priority | editor graph layout | DONE | NS-STORYLINES-V1.1-01 |
+| NS-STORYLINES-SEED-FIX-01 | Selbrume Graph Layout / SideQuest Rendering Fix V0 | editor graph fix | DONE | NS-STORYLINES-SEED-FIX-01-bis |
+| NS-STORYLINES-SEED-FIX-01-bis | Graph Focus Layout / Canvas Priority | editor graph layout | DONE | NS-STORYLINES-V1.1-00 |
+| NS-STORYLINES-V1.1-00 | Structure Layout / Chapter Step Readability V0 | editor structure layout | DONE | NS-STORYLINES-V1.1-01 |
@@ -900,7 +901,7 @@ Décision temporaire :
-Current lot: NS-STORYLINES-SEED-FIX-01-bis
+Current lot: NS-STORYLINES-V1.1-00
@@ -939,6 +940,7 @@ Next recommended lot: NS-STORYLINES-V1.1-01 — Basic Edit / Delete Flow V0
+| NS-STORYLINES-V1.1-00 | DONE | 2026-05-29 | Structure Layout livré : chapitre sélectionné expanded, autres chapitres collapsed, étapes narratives plus lisibles, création chapter/step préservée, aucun edit/delete ajouté. |
@@ -975,6 +977,14 @@ Suite V1 documentaire recommandée :
+### 2026-05-29 — NS-STORYLINES-V1.1-00
+- Structure est réorganisée en vraie vue d'organisation : barre d'action compacte, chapitre sélectionné expanded et chapitres non sélectionnés collapsed.
+- Les étapes narratives du chapitre sélectionné sont affichées en rows plus lisibles avec état réel `Aucune scène liée` si aucun sceneLink.
+- L'inspector droit devient contextuel en Structure quand un chapitre est sélectionné.
+- Les flows existants `Nouveau chapitre` et `Nouvelle étape narrative` restent branchés ; aucun edit/delete, sceneLink, seed, model, runtime, gameplay ou battle modifié.
+- Captures Visual Gate dark V1.1-00 produites ; le prochain lot recommandé reste `NS-STORYLINES-V1.1-01 — Basic Edit / Delete Flow V0`.
```

Sorties exactes des tests :

```text
Command: cd packages/map_editor && flutter test --reporter=compact test/storylines_structure_layout_test.dart
00:00 +0: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/storylines_structure_layout_test.dart
00:01 +0: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/storylines_structure_layout_test.dart
00:01 +0: NS-STORYLINES-V1.1-00 Structure layout readability Structure shows expanded selected chapter and collapsed others
00:02 +0: NS-STORYLINES-V1.1-00 Structure layout readability Structure shows expanded selected chapter and collapsed others
00:02 +1: NS-STORYLINES-V1.1-00 Structure layout readability Structure shows expanded selected chapter and collapsed others
00:02 +1: NS-STORYLINES-V1.1-00 Structure layout readability collapsed chapter selection changes focus without mutation
00:02 +2: NS-STORYLINES-V1.1-00 Structure layout readability collapsed chapter selection changes focus without mutation
00:02 +2: NS-STORYLINES-V1.1-00 Structure layout readability existing step creation flow remains wired in Structure
00:02 +3: NS-STORYLINES-V1.1-00 Structure layout readability existing step creation flow remains wired in Structure
00:02 +3: NS-STORYLINES-V1.1-00 Structure layout readability Graph remains accessible with independent sideQuest nodes
00:02 +4: NS-STORYLINES-V1.1-00 Structure layout readability Graph remains accessible with independent sideQuest nodes
00:02 +4: NS-STORYLINES-V1.1-00 Structure layout readability writes V1.1-00 Structure visual gate screenshots
00:03 +4: NS-STORYLINES-V1.1-00 Structure layout readability writes V1.1-00 Structure visual gate screenshots
00:03 +5: NS-STORYLINES-V1.1-00 Structure layout readability writes V1.1-00 Structure visual gate screenshots
00:03 +5: All tests passed!
```

```text
Command: cd packages/map_editor && flutter test --reporter=compact test/storylines_seed_graph_usability_test.dart
00:03 +6: All tests passed!
```

```text
Command: cd packages/map_editor && flutter test --reporter=compact test/storylines_current_global_story_characterization_test.dart
00:02 +2: All tests passed!
```

```text
Command: cd packages/map_editor && flutter test --reporter=compact test/narrative_workspace_projection_test.dart
00:01 +3: All tests passed!
```

```text
Command: cd packages/map_editor && flutter test --reporter=compact test/storylines_workspace_shell_test.dart
00:07 +35 -1: NS-STORYLINES-V1-12 visual graph enrichment writes V1-12 polished graph screenshots [E]
Which: Could not be compared against non-existent file:
"../../../reports/narrativeStudio/storylines/screenshots/ns_storylines_v1_12_graph_empty_polished.png"
00:07 +35 -1: Some tests failed.
```

Sortie exacte de flutter analyze :

```text
Analyzing 10 items...
No issues found! (ran in 1.5s)
```

Sortie exacte du rg anti-colors :

```text
Sortie : <vide>
```

Sortie exacte du rg anti-hardcode Selbrume :

```text
Sortie : <vide>
```

Résultats Visual Gate :

```text
Créé et vérifié :
reports/narrativeStudio/storylines/screenshots/ns_storylines_v1_1_00_structure_full_layout.png
reports/narrativeStudio/storylines/screenshots/ns_storylines_v1_1_00_structure_selected_chapter.png
reports/narrativeStudio/storylines/screenshots/ns_storylines_v1_1_00_structure_created_step.png
reports/narrativeStudio/storylines/screenshots/ns_storylines_v1_1_00_graph_regression.png
```

Git final exact :

```text
git status --short --untracked-files=all
 M packages/map_editor/lib/src/ui/canvas/storylines_workspace.dart
 M packages/map_editor/test/storylines_seed_graph_usability_test.dart
 M reports/narrativeStudio/storylines/road_map_storylines.md
?? packages/map_editor/lib/src/ui/canvas/storylines/storylines_structure_view.dart
?? packages/map_editor/test/storylines_structure_layout_test.dart
?? reports/narrativeStudio/storylines/ns_storylines_v1_1_00_structure_layout_chapter_step_readability_v0.md
?? reports/narrativeStudio/storylines/screenshots/ns_storylines_v1_1_00_graph_regression.png
?? reports/narrativeStudio/storylines/screenshots/ns_storylines_v1_1_00_structure_created_step.png
?? reports/narrativeStudio/storylines/screenshots/ns_storylines_v1_1_00_structure_full_layout.png
?? reports/narrativeStudio/storylines/screenshots/ns_storylines_v1_1_00_structure_selected_chapter.png
```

```text
git diff --stat
 .../lib/src/ui/canvas/storylines_workspace.dart    | 739 ++++-----------------
 .../test/storylines_seed_graph_usability_test.dart |  13 +-
 .../storylines/road_map_storylines.md              |  16 +-
 3 files changed, 150 insertions(+), 618 deletions(-)
```

```text
git diff --name-only
packages/map_editor/lib/src/ui/canvas/storylines_workspace.dart
packages/map_editor/test/storylines_seed_graph_usability_test.dart
reports/narrativeStudio/storylines/road_map_storylines.md
```

```text
git diff --check
Sortie : <vide>
```

## 18. Self-review

- Structure est plus lisible et plus hiérarchisée.
- Le chapitre sélectionné est expanded.
- Les autres chapitres sont collapsed.
- Les steps sont plus aérées et indiquent l'absence de scène liée sans fake.
- L'inspector chapitre est utile sans devenir un éditeur.
- Aucun edit/delete/reorder/drag/drop/search/filter n'a été ajouté.
- Aucun seed ou modèle core n'a été modifié.
- Le test shell global ne révèle plus de régression Structure ; il reste bloqué uniquement sur le golden V1-12 absent déjà documenté.
