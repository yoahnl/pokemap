# NS-STORYLINES-09 — Chapters Inspector / Step Ordering Read-only V0

## 1. Executive summary

NS-STORYLINES-09 est livré.

La tab `Chapitres` affiche maintenant une sélection locale de chapitre, un chapitre réel sélectionné par défaut, une mise en avant de la sélection, un inspecteur chapitre read-only et l'ordre des étapes narratives liées au chapitre.

Le lot reste strictement V0 : aucun modèle `Scene`, aucune création, aucune édition, aucun réordonnancement, aucune donnée cible Selbrume, aucun statut éditorial fake, aucun `localEventFlow` affiché comme chapitre ou étape.

## 2. Inputs read

Fichiers lus :

```text
AGENTS.md
agent_rules.md
skills/README.md
reports/narrativeStudio/storylines/road_map_storylines.md
reports/narrativeStudio/storylines/ns_storylines_08_ter_true_graph_geometry_v0.md
reports/narrativeStudio/storylines/ns_storylines_08_bis_graph_tab_target_alignment_v0.md
reports/narrativeStudio/storylines/ns_storylines_08_chapters_tab_read_only_v0.md
reports/narrativeStudio/storylines/ns_storylines_07_inspector_read_only_v0.md
reports/narrativeStudio/storylines/ns_storylines_06_graph_read_only_placeholder_v0.md
reports/narrativeStudio/storylines/ns_storylines_05_header_tabs_kpi_read_only_v0.md
packages/map_editor/lib/src/features/narrative/application/narrative_workspace_projection.dart
packages/map_editor/lib/src/ui/canvas/storylines_workspace.dart
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
packages/map_editor/lib/src/ui/shared/cupertino_editor_widgets.dart
packages/map_editor/lib/src/ui/shared/editor_visual_tokens.dart
```

Fichiers attendus absents : aucun.

## 3. Implementation summary

Modifications principales :

- `_StorylineChaptersSection` devient stateful pour porter uniquement la sélection locale du chapitre.
- Le premier chapitre réel est sélectionné par défaut quand la tab `Chapitres` s'ouvre.
- `_StorylineChapterList` expose une key stable `storylines-chapter-list`.
- `_StorylineChapterCard` devient sélectionnable localement via `PokeMapCard(selected/onTap)`.
- `_StorylineChapterInspector` affiche les détails du chapitre sélectionné, la source, le mode read-only et l'ordre des étapes narratives.
- `_StorylineChapterStepOrderList` et `_StorylineChapterStepOrderRow` affichent les étapes réelles dans l'ordre V0 du chapitre.
- Les Visual Gate NS09 ont été produits sans écraser les captures NS08-ter.

## 4. Chapter selection behavior

Quand `Chapitres` est ouvert :

- `Graph` n'est plus la vue active.
- `storylines-chapters-read-only` devient visible.
- `storylines-chapter-list` devient visible.
- `storylines-chapter-inspector` devient visible.
- `storylines-selected-chapter-audit_chapter` est présent par défaut.
- Cliquer `storylines-chapter-card-audit_second_chapter` remplace uniquement la sélection locale par `storylines-selected-chapter-audit_second_chapter`.

Garantie de non-mutation testée :

- `EditorWorkspaceMode` reste inchangé.
- Le `ProjectManifest` reste le même objet.
- `selectedGlobalStoryId` ne change pas.
- `selectedStepId` ne change pas.

## 5. Chapter inspector behavior

L'inspecteur affiche uniquement des données de `NarrativeChapterSummary` :

- `Détails du chapitre`
- nom réel du chapitre ;
- description réelle ou fallback honnête ;
- `Ordre`
- `Source Global Story Studio`
- `Lecture seule`
- compteur réel d'étapes narratives liées ;
- section `Données à venir` explicitement non branchée.

Le wording actif reste V0 : aucun `Scènes du chapitre`, aucun statut `Brouillon`, `En cours`, `Prête`, `Défini`, `Active`, `Validé`, `À jour` ou `Haute`.

## 6. Step ordering behavior

L'ordre affiché est l'ordre read-only des `NarrativeStepSummary` déjà résolues dans `NarrativeChapterSummary.steps`.

Chaque ligne d'ordre expose :

- key stable `storylines-chapter-step-order-<step.id>` ;
- index lisible `01`, `02`, etc. ;
- nom réel de step ;
- description réelle de step ou fallback honnête.

Ce n'est pas un drag/drop, pas une édition, pas une navigation vers Step Studio et pas un modèle final de scènes.

## 7. Data source / anti-fake guarantees

Sources utilisées :

- `NarrativeChapterSummary.id`
- `NarrativeChapterSummary.name`
- `NarrativeChapterSummary.description`
- `NarrativeChapterSummary.order`
- `NarrativeChapterSummary.steps`
- `NarrativeChapterSummary.missingStepIds`
- `NarrativeStepSummary.name`
- `NarrativeStepSummary.description`

Garanties :

- aucun `localEventFlow` affiché comme chapitre ou étape ;
- aucun hardcode de données cible Selbrume ;
- aucun compteur de scènes/dialogues/facts/world rules ;
- aucune quête annexe fake ;
- aucune donnée cible issue de l'image fournie.

## 8. Disabled interactions

Restent disabled / non mutantes :

- `Nouvelle storyline`
- `Valider`
- `+`
- `Nouveau chapitre`
- tabs futures `Étapes`, `Scènes`, `Statistiques`, `Tests`

Interactions autorisées :

- ouvrir `Graph` ;
- ouvrir `Chapitres` ;
- sélectionner localement un chapitre.

## 9. Design System Gate

Mini audit :

- Aucun `Color(0x...)` ajouté.
- Aucun `Colors.*` ajouté.
- Les composants ajoutés sont feature-specific : `_StorylineChapterInspector`, `_StorylineChapterStepOrderList`, `_StorylineChapterStepOrderRow`.
- Les surfaces, cards, status tiles, icon tiles, boutons et tons utilisent les primitives PokeMap.
- Les couleurs passent par `context.pokeMapColors` ou les primitives design system.

Recherche `Color(0x...) / Colors.*` :

```text
Commande : rg "Color\(0x|Colors\." packages/map_editor/lib/src/ui/canvas/storylines_workspace.dart packages/map_editor/test/storylines_workspace_shell_test.dart packages/map_editor/test/narrative_workspace_projection_test.dart packages/map_editor/test/storylines_current_global_story_characterization_test.dart
Sortie : <vide>
```

## 10. Tests added or modified

Tests renforcés dans `packages/map_editor/test/storylines_workspace_shell_test.dart` :

- groupe renommé NS09 ;
- preuve que `Graph` reste actif par défaut avant ouverture de `Chapitres` ;
- preuve que `Chapitres` affiche la vue active et retire le graph actif ;
- keys `storylines-chapter-list`, `storylines-chapter-inspector`, `storylines-selected-chapter-*` ;
- sélection locale du second chapitre ;
- preuve de non-mutation du projet et de l'état narratif persistant ;
- inspecteur de chapitre ;
- ordre des étapes narratives ;
- bouton `Nouveau chapitre` disabled / non mutant ;
- anti-fake enrichi avec `4 scènes`, `12 dialogues`, `Prête`.

## 11. Visual Gate

Visual Gate dark produit :

```text
reports/narrativeStudio/storylines/screenshots/ns_storylines_09_chapter_inspector_desktop.png
reports/narrativeStudio/storylines/screenshots/ns_storylines_09_chapter_inspector_focus.png
reports/narrativeStudio/storylines/screenshots/ns_storylines_09_chapter_inspector_center.png
```

Tailles :

```text
   51122 reports/narrativeStudio/storylines/screenshots/ns_storylines_09_chapter_inspector_center.png
   64915 reports/narrativeStudio/storylines/screenshots/ns_storylines_09_chapter_inspector_desktop.png
   48568 reports/narrativeStudio/storylines/screenshots/ns_storylines_09_chapter_inspector_focus.png
  164605 total
```

Résultat : les captures sont validées par `flutter test test/storylines_workspace_shell_test.dart`.

## 12. Roadmap update

`reports/narrativeStudio/storylines/road_map_storylines.md` a été mis à jour :

- NS-STORYLINES-09 marqué `DONE`.
- Wording roadmap ajusté en `Step Ordering Read-only V0`.
- Résumé, fichiers, tests, analyse, Visual Gate, Design System Gate, anti-fake ajoutés.
- Prochain lot recommandé : `NS-STORYLINES-10 — Storyline Visual Harmonization / Visual Gate V0`.

## 13. Commands run

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
dart format packages/map_editor/lib/src/ui/canvas/storylines_workspace.dart packages/map_editor/test/storylines_workspace_shell_test.dart
cd packages/map_editor && flutter test --update-goldens test/storylines_workspace_shell_test.dart
cd packages/map_editor && flutter test test/storylines_workspace_shell_test.dart
cd packages/map_editor && flutter test test/storylines_current_global_story_characterization_test.dart
cd packages/map_editor && flutter test test/narrative_workspace_projection_test.dart
cd packages/map_editor && flutter analyze --no-fatal-infos lib/src/ui/canvas/storylines_workspace.dart test/storylines_workspace_shell_test.dart test/storylines_current_global_story_characterization_test.dart test/narrative_workspace_projection_test.dart
rg "Color\(0x|Colors\." packages/map_editor/lib/src/ui/canvas/storylines_workspace.dart packages/map_editor/test/storylines_workspace_shell_test.dart packages/map_editor/test/narrative_workspace_projection_test.dart packages/map_editor/test/storylines_current_global_story_characterization_test.dart
git diff --check
```

Note : une tentative de lancer deux commandes Flutter en parallèle a produit un échec de lock/native asset sur `storylines_current_global_story_characterization_test.dart`. La commande a ensuite été relancée seule et a passé. Le test `narrative_workspace_projection_test.dart` lancé en parallèle a passé.

Sortie exacte de cet échec intermédiaire :

```text
Failed to change install names in LocalFile: '/Users/karim/Project/pokemonProject/packages/map_editor/build/native_assets/macos/objective_c.dylib':
id -> /Users/karim/Project/pokemonProject/packages/map_editor/build/native_assets/macos/objective_c.dylib
dependencies -> /Users/karim/Project/pokemonProject/packages/map_editor/build/native_assets/macos/objective_c.dylib
error: /Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/install_name_tool: can't open file: /Users/karim/Project/pokemonProject/packages/map_editor/build/native_assets/macos/objective_c.dylib (No such file or directory)
```

## 14. Evidence Pack

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
?? reports/narrativeStudio/storylines/ns_storylines_09_chapters_inspector_step_ordering_read_only_v0.md
?? reports/narrativeStudio/storylines/screenshots/ns_storylines_09_chapter_inspector_center.png
?? reports/narrativeStudio/storylines/screenshots/ns_storylines_09_chapter_inspector_desktop.png
?? reports/narrativeStudio/storylines/screenshots/ns_storylines_09_chapter_inspector_focus.png
```

Git diff --stat final :

```text
 .../lib/src/ui/canvas/storylines_workspace.dart    | 376 ++++++++++++++++++---
 .../test/storylines_workspace_shell_test.dart      | 141 +++++++-
 .../storylines/road_map_storylines.md              |  39 ++-
 3 files changed, 496 insertions(+), 60 deletions(-)
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
Le contenu complet du rapport créé est le présent document, du titre "# NS-STORYLINES-09 — Chapters Inspector / Step Ordering Read-only V0" jusqu'à la section "## 15. Self-review".
```

Sortie exacte du test ciblé principal :

```text
00:00 +0: NS-STORYLINES-09 Chapters inspector / step ordering V0 renders a read-only three-pane shell from real global story data
[step_studio_trace] action=apply_document scenario=audit_global_story rows=[]
[step_studio_trace] action=apply_document_metadata scenario=audit_global_story contains_emma=false contains_empty_entity=false
[step_studio_trace] action=apply_document scenario=audit_second_global_story rows=[]
[step_studio_trace] action=apply_document_metadata scenario=audit_second_global_story contains_emma=false contains_empty_entity=false
00:00 +1: NS-STORYLINES-09 Chapters inspector / step ordering V0 renders an honest empty state when the selected global story has no steps
[step_studio_trace] action=apply_document scenario=audit_empty_global_story rows=[]
[step_studio_trace] action=apply_document_metadata scenario=audit_empty_global_story contains_emma=false contains_empty_entity=false
00:00 +2: NS-STORYLINES-09 Chapters inspector / step ordering V0 shows the Chapters tab from Global Story Studio metadata read-only
[step_studio_trace] action=apply_document scenario=audit_global_story rows=[]
[step_studio_trace] action=apply_document_metadata scenario=audit_global_story contains_emma=false contains_empty_entity=false
[step_studio_trace] action=apply_document scenario=audit_second_global_story rows=[]
[step_studio_trace] action=apply_document_metadata scenario=audit_second_global_story contains_emma=false contains_empty_entity=false
00:00 +3: NS-STORYLINES-09 Chapters inspector / step ordering V0 shows an honest Chapters empty state
[step_studio_trace] action=apply_document scenario=audit_empty_global_story rows=[]
[step_studio_trace] action=apply_document_metadata scenario=audit_empty_global_story contains_emma=false contains_empty_entity=false
00:00 +4: NS-STORYLINES-09 Chapters inspector / step ordering V0 renders an honest inspector empty state without global story
00:01 +5: NS-STORYLINES-09 Chapters inspector / step ordering V0 keeps future Storyline tabs read-only and non-mutating
[step_studio_trace] action=apply_document scenario=audit_global_story rows=[]
[step_studio_trace] action=apply_document_metadata scenario=audit_global_story contains_emma=false contains_empty_entity=false
[step_studio_trace] action=apply_document scenario=audit_second_global_story rows=[]
[step_studio_trace] action=apply_document_metadata scenario=audit_second_global_story contains_emma=false contains_empty_entity=false
00:01 +6: NS-STORYLINES-09 Chapters inspector / step ordering V0 keeps future header actions disabled and non-mutating
[step_studio_trace] action=apply_document scenario=audit_global_story rows=[]
[step_studio_trace] action=apply_document_metadata scenario=audit_global_story contains_emma=false contains_empty_entity=false
[step_studio_trace] action=apply_document scenario=audit_second_global_story rows=[]
[step_studio_trace] action=apply_document_metadata scenario=audit_second_global_story contains_emma=false contains_empty_entity=false
00:01 +7: NS-STORYLINES-09 Chapters inspector / step ordering V0 storylines UI source keeps raw colors out of the feature
00:01 +8: NS-STORYLINES-09 Chapters inspector / step ordering V0 storylines action test does not use silent taps
00:01 +9: NS-STORYLINES-09 Chapters inspector / step ordering V0 uses PokeMap dark theme in the Visual Gate harness
[step_studio_trace] action=apply_document scenario=audit_global_story rows=[]
[step_studio_trace] action=apply_document_metadata scenario=audit_global_story contains_emma=false contains_empty_entity=false
[step_studio_trace] action=apply_document scenario=audit_second_global_story rows=[]
[step_studio_trace] action=apply_document_metadata scenario=audit_second_global_story contains_emma=false contains_empty_entity=false
00:01 +10: NS-STORYLINES-09 Chapters inspector / step ordering V0 writes Visual Gate screenshots
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
00:01 +11: All tests passed!
```

Sortie exacte du test characterization :

```text
00:00 +0: NS-STORYLINES-02 current Global Story characterization renders the current Storylines shell from manifest and authoring metadata
[step_studio_trace] action=apply_document scenario=audit_global_story rows=[]
[step_studio_trace] action=apply_document_metadata scenario=audit_global_story contains_emma=false contains_empty_entity=false
00:00 +1: NS-STORYLINES-02 current Global Story characterization keeps globalStory and localEventFlow separated in the current projection
[step_studio_trace] action=apply_document scenario=audit_global_story rows=[]
[step_studio_trace] action=apply_document_metadata scenario=audit_global_story contains_emma=false contains_empty_entity=false
00:00 +2: All tests passed!
```

Sortie exacte du test projection :

```text
00:00 +0: buildNarrativeWorkspaceProjection splits global story and local flows, and projects steps
00:00 +1: buildNarrativeWorkspaceProjection projects ordered steps from Step Studio v1 metadata document
00:00 +2: buildNarrativeWorkspaceProjection projects chapters from Global Story Studio metadata
00:00 +3: All tests passed!
```

Sortie exacte de l'analyse ciblée :

```text
Analyzing 4 items...                                            
No issues found! (ran in 3.1s)
```

Résultats du Visual Gate :

```text
reports/narrativeStudio/storylines/screenshots/ns_storylines_09_chapter_inspector_center.png
reports/narrativeStudio/storylines/screenshots/ns_storylines_09_chapter_inspector_desktop.png
reports/narrativeStudio/storylines/screenshots/ns_storylines_09_chapter_inspector_focus.png
```

Diff complet de `packages/map_editor/lib/src/ui/canvas/storylines_workspace.dart` :

```diff
diff --git a/packages/map_editor/lib/src/ui/canvas/storylines_workspace.dart b/packages/map_editor/lib/src/ui/canvas/storylines_workspace.dart
index c451bf73..908fe266 100644
--- a/packages/map_editor/lib/src/ui/canvas/storylines_workspace.dart
+++ b/packages/map_editor/lib/src/ui/canvas/storylines_workspace.dart
@@ -1401,16 +1401,46 @@ class _StorylineGraphEmptyState extends StatelessWidget {
   }
 }
 
-class _StorylineChaptersSection extends StatelessWidget {
+class _StorylineChaptersSection extends StatefulWidget {
   const _StorylineChaptersSection({
     required this.chapters,
   });
 
   final List<NarrativeChapterSummary> chapters;
 
+  @override
+  State<_StorylineChaptersSection> createState() =>
+      _StorylineChaptersSectionState();
+}
+
+class _StorylineChaptersSectionState extends State<_StorylineChaptersSection> {
+  String? _selectedChapterId;
+
+  NarrativeChapterSummary? get _selectedChapter {
+    if (widget.chapters.isEmpty) {
+      return null;
+    }
+    final selectedId = _selectedChapterId;
+    if (selectedId != null) {
+      for (final chapter in widget.chapters) {
+        if (chapter.id == selectedId) {
+          return chapter;
+        }
+      }
+    }
+    return widget.chapters.first;
+  }
+
+  void _selectChapter(NarrativeChapterSummary chapter) {
+    setState(() {
+      _selectedChapterId = chapter.id;
+    });
+  }
+
   @override
   Widget build(BuildContext context) {
     final colors = context.pokeMapColors;
+    final selectedChapter = _selectedChapter;
     return PokeMapPageSurface(
       key: const ValueKey('storylines-chapters-read-only'),
       padding: const EdgeInsets.all(18),
@@ -1470,7 +1500,7 @@ class _StorylineChaptersSection extends StatelessWidget {
               children: [
                 PokeMapStatusTile(
                   label: 'Chapitres réels',
-                  value: '${chapters.length}',
+                  value: '${widget.chapters.length}',
                   icon: CupertinoIcons.square_list,
                   tone: PokeMapTone.info,
                 ),
@@ -1489,10 +1519,42 @@ class _StorylineChaptersSection extends StatelessWidget {
               ],
             ),
             const SizedBox(height: 16),
-            if (chapters.isEmpty)
+            if (widget.chapters.isEmpty)
               const _StorylineChaptersEmptyState()
             else
-              _StorylineChapterList(chapters: chapters),
+              LayoutBuilder(
+                builder: (context, constraints) {
+                  final list = _StorylineChapterList(
+                    chapters: widget.chapters,
+                    selectedChapterId: selectedChapter?.id,
+                    onChapterSelected: _selectChapter,
+                  );
+                  final inspector = _StorylineChapterInspector(
+                    chapter: selectedChapter,
+                  );
+                  if (constraints.maxWidth < 740) {
+                    return Column(
+                      crossAxisAlignment: CrossAxisAlignment.stretch,
+                      children: [
+                        list,
+                        const SizedBox(height: 12),
+                        inspector,
+                      ],
+                    );
+                  }
+                  return Row(
+                    crossAxisAlignment: CrossAxisAlignment.start,
+                    children: [
+                      SizedBox(
+                        width: math.min(360, constraints.maxWidth * 0.42),
+                        child: list,
+                      ),
+                      const SizedBox(width: 12),
+                      Expanded(child: inspector),
+                    ],
+                  );
+                },
+              ),
           ],
         ),
       ),
@@ -1503,17 +1565,26 @@ class _StorylineChaptersSection extends StatelessWidget {
 class _StorylineChapterList extends StatelessWidget {
   const _StorylineChapterList({
     required this.chapters,
+    required this.selectedChapterId,
+    required this.onChapterSelected,
   });
 
   final List<NarrativeChapterSummary> chapters;
+  final String? selectedChapterId;
+  final ValueChanged<NarrativeChapterSummary> onChapterSelected;
 
   @override
   Widget build(BuildContext context) {
     return Column(
+      key: const ValueKey('storylines-chapter-list'),
       crossAxisAlignment: CrossAxisAlignment.stretch,
       children: [
         for (final chapter in chapters) ...[
-          _StorylineChapterCard(chapter: chapter),
+          _StorylineChapterCard(
+            chapter: chapter,
+            selected: chapter.id == selectedChapterId,
+            onTap: () => onChapterSelected(chapter),
+          ),
           if (chapter != chapters.last) const SizedBox(height: 10),
         ],
       ],
@@ -1524,17 +1595,23 @@ class _StorylineChapterList extends StatelessWidget {
 class _StorylineChapterCard extends StatelessWidget {
   const _StorylineChapterCard({
     required this.chapter,
+    required this.selected,
+    required this.onTap,
   });
 
   final NarrativeChapterSummary chapter;
+  final bool selected;
+  final VoidCallback onTap;
 
   @override
   Widget build(BuildContext context) {
     final colors = context.pokeMapColors;
     final description = chapter.description.trim();
-    return PokeMapCard(
+    final card = PokeMapCard(
       key: ValueKey('storylines-chapter-card-${chapter.id}'),
       padding: const EdgeInsets.all(14),
+      selected: selected,
+      onTap: onTap,
       child: Column(
         crossAxisAlignment: CrossAxisAlignment.stretch,
         children: [
@@ -1558,7 +1635,6 @@ class _StorylineChapterCard extends StatelessWidget {
                         color: colors.textMuted,
                         fontSize: 10.5,
                         fontWeight: FontWeight.w800,
-                        letterSpacing: 0.4,
                       ),
                     ),
                     const SizedBox(height: 4),
@@ -1625,60 +1701,224 @@ class _StorylineChapterCard extends StatelessWidget {
                 ),
             ],
           ),
-          const SizedBox(height: 12),
+        ],
+      ),
+    );
+    if (!selected) {
+      return card;
+    }
+    return KeyedSubtree(
+      key: ValueKey('storylines-selected-chapter-${chapter.id}'),
+      child: card,
+    );
+  }
+}
+
+class _StorylineChapterInspector extends StatelessWidget {
+  const _StorylineChapterInspector({
+    required this.chapter,
+  });
+
+  final NarrativeChapterSummary? chapter;
+
+  @override
+  Widget build(BuildContext context) {
+    final colors = context.pokeMapColors;
+    final selectedChapter = chapter;
+    if (selectedChapter == null) {
+      return const _StorylineChapterInspectorEmptyState();
+    }
+    final description = selectedChapter.description.trim();
+    return PokeMapCard(
+      key: const ValueKey('storylines-chapter-inspector'),
+      padding: const EdgeInsets.all(16),
+      selected: true,
+      child: Column(
+        crossAxisAlignment: CrossAxisAlignment.stretch,
+        children: [
+          Row(
+            crossAxisAlignment: CrossAxisAlignment.start,
+            children: [
+              const PokeMapIconTile(
+                icon: CupertinoIcons.book_fill,
+                tone: PokeMapTone.narrative,
+                size: 38,
+                iconSize: 18,
+              ),
+              const SizedBox(width: 12),
+              Expanded(
+                child: Column(
+                  crossAxisAlignment: CrossAxisAlignment.start,
+                  children: [
+                    Text(
+                      'Détails du chapitre',
+                      style: TextStyle(
+                        color: colors.textMuted,
+                        fontSize: 10.5,
+                        fontWeight: FontWeight.w800,
+                      ),
+                    ),
+                    const SizedBox(height: 5),
+                    Text(
+                      selectedChapter.name,
+                      maxLines: 2,
+                      overflow: TextOverflow.ellipsis,
+                      style: TextStyle(
+                        color: colors.textPrimary,
+                        fontSize: 15,
+                        fontWeight: FontWeight.w800,
+                      ),
+                    ),
+                    const SizedBox(height: 6),
+                    Text(
+                      description.isEmpty
+                          ? 'Description de chapitre non renseignée.'
+                          : description,
+                      maxLines: 4,
+                      overflow: TextOverflow.ellipsis,
+                      style: TextStyle(
+                        color: colors.textSecondary,
+                        fontSize: 12.5,
+                        height: 1.35,
+                        fontWeight: FontWeight.w500,
+                      ),
+                    ),
+                  ],
+                ),
+              ),
+            ],
+          ),
+          const SizedBox(height: 14),
+          Wrap(
+            spacing: 10,
+            runSpacing: 10,
+            children: [
+              PokeMapStatusTile(
+                label: 'Ordre',
+                value: '${selectedChapter.order + 1}',
+                icon: CupertinoIcons.number,
+                tone: PokeMapTone.info,
+              ),
+              const PokeMapStatusTile(
+                label: 'Source Global Story Studio',
+                value: 'Lecture seule',
+                icon: CupertinoIcons.doc_text,
+                tone: PokeMapTone.neutral,
+              ),
+              const PokeMapStatusTile(
+                label: 'Mode',
+                value: 'Lecture seule',
+                icon: CupertinoIcons.lock,
+                tone: PokeMapTone.neutral,
+              ),
+              PokeMapStatusTile(
+                label: 'Étapes liées',
+                value: _formatFrenchCount(
+                  selectedChapter.steps.length,
+                  singular: 'étape narrative',
+                  plural: 'étapes narratives',
+                ),
+                icon: CupertinoIcons.list_bullet,
+                tone: PokeMapTone.info,
+              ),
+            ],
+          ),
+          const SizedBox(height: 16),
           Text(
-            'Étapes du chapitre',
+            'Étapes narratives du chapitre',
             style: TextStyle(
-              color: colors.textMuted,
-              fontSize: 10.5,
+              color: colors.textPrimary,
+              fontSize: 13,
               fontWeight: FontWeight.w800,
-              letterSpacing: 0.4,
             ),
           ),
-          const SizedBox(height: 8),
-          if (chapter.steps.isEmpty)
-            Text(
-              'Aucune étape narrative liée à ce chapitre.',
-              style: TextStyle(
-                color: colors.textSecondary,
-                fontSize: 12,
-                height: 1.35,
-              ),
-            )
-          else
-            Column(
-              crossAxisAlignment: CrossAxisAlignment.stretch,
-              children: [
-                for (final step in chapter.steps) ...[
-                  _StorylineChapterStepPreview(step: step),
-                  if (step != chapter.steps.last) const SizedBox(height: 8),
-                ],
-              ],
+          const SizedBox(height: 4),
+          Text(
+            'Ordre des étapes narratives',
+            style: TextStyle(
+              color: colors.textSecondary,
+              fontSize: 12,
+              height: 1.35,
+              fontWeight: FontWeight.w600,
             ),
+          ),
+          const SizedBox(height: 10),
+          _StorylineChapterStepOrderList(steps: selectedChapter.steps),
+          if (selectedChapter.missingStepIds.isNotEmpty) ...[
+            const SizedBox(height: 16),
+            _StorylineMissingStepIds(ids: selectedChapter.missingStepIds),
+          ],
+          const SizedBox(height: 16),
+          const PokeMapStatusTile(
+            label: 'Données à venir',
+            value: 'Modèle détaillé non branché',
+            icon: CupertinoIcons.clock,
+            tone: PokeMapTone.neutral,
+          ),
         ],
       ),
     );
   }
 }
 
-class _StorylineChapterStepPreview extends StatelessWidget {
-  const _StorylineChapterStepPreview({
+class _StorylineChapterStepOrderList extends StatelessWidget {
+  const _StorylineChapterStepOrderList({
+    required this.steps,
+  });
+
+  final List<NarrativeStepSummary> steps;
+
+  @override
+  Widget build(BuildContext context) {
+    final colors = context.pokeMapColors;
+    if (steps.isEmpty) {
+      return Text(
+        'Aucune étape narrative liée à ce chapitre.',
+        style: TextStyle(
+          color: colors.textSecondary,
+          fontSize: 12.5,
+          height: 1.35,
+          fontWeight: FontWeight.w600,
+        ),
+      );
+    }
+    return Column(
+      crossAxisAlignment: CrossAxisAlignment.stretch,
+      children: [
+        for (var index = 0; index < steps.length; index++) ...[
+          _StorylineChapterStepOrderRow(
+            index: index,
+            step: steps[index],
+          ),
+          if (index != steps.length - 1) const SizedBox(height: 8),
+        ],
+      ],
+    );
+  }
+}
+
+class _StorylineChapterStepOrderRow extends StatelessWidget {
+  const _StorylineChapterStepOrderRow({
+    required this.index,
     required this.step,
   });
 
+  final int index;
   final NarrativeStepSummary step;
 
   @override
   Widget build(BuildContext context) {
     final colors = context.pokeMapColors;
+    final order = (index + 1).toString().padLeft(2, '0');
     return Row(
+      key: ValueKey('storylines-chapter-step-order-${step.id}'),
       crossAxisAlignment: CrossAxisAlignment.start,
       children: [
-        const PokeMapIconTile(
-          icon: CupertinoIcons.smallcircle_fill_circle,
+        PokeMapStatusTile(
+          label: order,
+          value: 'Étape narrative',
+          icon: CupertinoIcons.line_horizontal_3_decrease,
           tone: PokeMapTone.info,
-          size: 28,
-          iconSize: 12,
         ),
         const SizedBox(width: 10),
         Expanded(
@@ -1697,7 +1937,9 @@ class _StorylineChapterStepPreview extends StatelessWidget {
               ),
               const SizedBox(height: 3),
               Text(
-                step.description,
+                step.description.trim().isEmpty
+                    ? 'Description d’étape narrative non renseignée.'
+                    : step.description,
                 maxLines: 2,
                 overflow: TextOverflow.ellipsis,
                 style: TextStyle(
@@ -1715,6 +1957,64 @@ class _StorylineChapterStepPreview extends StatelessWidget {
   }
 }
 
+class _StorylineMissingStepIds extends StatelessWidget {
+  const _StorylineMissingStepIds({
+    required this.ids,
+  });
+
+  final List<String> ids;
+
+  @override
+  Widget build(BuildContext context) {
+    final colors = context.pokeMapColors;
+    return Column(
+      crossAxisAlignment: CrossAxisAlignment.stretch,
+      children: [
+        Text(
+          'Étapes manquantes',
+          style: TextStyle(
+            color: colors.textPrimary,
+            fontSize: 13,
+            fontWeight: FontWeight.w800,
+          ),
+        ),
+        const SizedBox(height: 8),
+        for (final id in ids) ...[
+          PokeMapStatusTile(
+            label: id,
+            value: 'Référence read-only',
+            icon: CupertinoIcons.exclamationmark_triangle,
+            tone: PokeMapTone.warning,
+          ),
+          if (id != ids.last) const SizedBox(height: 8),
+        ],
+      ],
+    );
+  }
+}
+
+class _StorylineChapterInspectorEmptyState extends StatelessWidget {
+  const _StorylineChapterInspectorEmptyState();
+
+  @override
+  Widget build(BuildContext context) {
+    final colors = context.pokeMapColors;
+    return PokeMapCard(
+      key: const ValueKey('storylines-chapter-inspector'),
+      padding: const EdgeInsets.all(14),
+      child: Text(
+        'Aucun chapitre sélectionné.',
+        style: TextStyle(
+          color: colors.textSecondary,
+          fontSize: 12.5,
+          height: 1.35,
+          fontWeight: FontWeight.w600,
+        ),
+      ),
+    );
+  }
+}
+
 class _StorylineChaptersEmptyState extends StatelessWidget {
   const _StorylineChaptersEmptyState();
```

Diff complet de `packages/map_editor/test/storylines_workspace_shell_test.dart` :

```diff
diff --git a/packages/map_editor/test/storylines_workspace_shell_test.dart b/packages/map_editor/test/storylines_workspace_shell_test.dart
index bae45c5c..c6c9673c 100644
--- a/packages/map_editor/test/storylines_workspace_shell_test.dart
+++ b/packages/map_editor/test/storylines_workspace_shell_test.dart
@@ -14,7 +14,7 @@ import 'package:map_editor/src/ui/canvas/narrative_workspace_canvas.dart';
 import 'package:map_editor/src/ui/design_system/design_system.dart';
 
 void main() {
-  group('NS-STORYLINES-08-ter True graph geometry V0', () {
+  group('NS-STORYLINES-09 Chapters inspector / step ordering V0', () {
     testWidgets(
       'renders a read-only three-pane shell from real global story data',
       (tester) async {
@@ -314,10 +314,28 @@ void main() {
             find.byKey(const ValueKey('storylines-chapters-read-only'));
         final createAction =
             find.byKey(const ValueKey('storylines-chapters-create-action'));
+        final chapterList =
+            find.byKey(const ValueKey('storylines-chapter-list'));
+        final chapterInspector =
+            find.byKey(const ValueKey('storylines-chapter-inspector'));
 
         expect(chapters, findsOneWidget);
         expect(find.byKey(const ValueKey('storylines-graph-target-read-only')),
             findsNothing);
+        expect(chapterList, findsOneWidget);
+        expect(chapterInspector, findsOneWidget);
+        expect(
+          find.byKey(
+            const ValueKey('storylines-selected-chapter-audit_chapter'),
+          ),
+          findsOneWidget,
+        );
+        expect(
+          find.byKey(
+            const ValueKey('storylines-selected-chapter-audit_second_chapter'),
+          ),
+          findsNothing,
+        );
         expect(
           find.descendant(of: chapters, matching: find.text('Chapitres')),
           findsOneWidget,
@@ -331,14 +349,21 @@ void main() {
         );
         expect(
           find.descendant(
-            of: chapters,
+            of: chapterList,
             matching: find.text('Audit Chapter From Metadata'),
           ),
           findsOneWidget,
         );
         expect(
           find.descendant(
-            of: chapters,
+            of: chapterInspector,
+            matching: find.text('Audit Chapter From Metadata'),
+          ),
+          findsOneWidget,
+        );
+        expect(
+          find.descendant(
+            of: chapterInspector,
             matching: find.text('Audit chapter description from metadata'),
           ),
           findsOneWidget,
@@ -362,6 +387,44 @@ void main() {
           ),
           findsOneWidget,
         );
+        expect(
+          find.descendant(
+            of: chapterInspector,
+            matching: find.text('Détails du chapitre'),
+          ),
+          findsOneWidget,
+        );
+        expect(
+          find.descendant(
+            of: chapterInspector,
+            matching: find.text('Source Global Story Studio'),
+          ),
+          findsOneWidget,
+        );
+        expect(
+          find.descendant(
+            of: chapterInspector,
+            matching: find.text('Ordre des étapes narratives'),
+          ),
+          findsOneWidget,
+        );
+        expect(
+          find.descendant(
+            of: chapterInspector,
+            matching: find.text('Étapes narratives du chapitre'),
+          ),
+          findsOneWidget,
+        );
+        expect(
+          find.byKey(
+            const ValueKey('storylines-chapter-step-order-audit_step'),
+          ),
+          findsOneWidget,
+        );
+        expect(
+          find.descendant(of: chapterInspector, matching: find.text('01')),
+          findsOneWidget,
+        );
         expect(
           find.descendant(of: chapters, matching: find.text('Lecture seule')),
           findsWidgets,
@@ -369,6 +432,62 @@ void main() {
         expect(createAction, findsOneWidget);
         expect(tester.widget<PokeMapButton>(createAction).onPressed, isNull);
 
+        final secondChapterCard = find.byKey(
+          const ValueKey('storylines-chapter-card-audit_second_chapter'),
+        );
+        await tester.ensureVisible(secondChapterCard);
+        await tester.pump();
+        await tester.tap(secondChapterCard);
+        await tester.pump();
+
+        expect(
+          find.byKey(
+            const ValueKey('storylines-selected-chapter-audit_second_chapter'),
+          ),
+          findsOneWidget,
+        );
+        expect(
+          find.descendant(
+            of: chapterInspector,
+            matching: find.text('Audit Second Chapter From Metadata'),
+          ),
+          findsOneWidget,
+        );
+        expect(
+          find.byKey(
+            const ValueKey('storylines-chapter-step-order-audit_followup_step'),
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
+        final afterSelectionEditorState =
+            harness.container.read(editorNotifierProvider);
+        final afterSelectionNarrativeState =
+            harness.container.read(narrativeWorkspaceControllerProvider);
+
+        expect(
+          afterSelectionEditorState.workspaceMode,
+          beforeEditorState.workspaceMode,
+        );
+        expect(afterSelectionEditorState.project, same(beforeProject));
+        expect(
+          afterSelectionNarrativeState.selectedGlobalStoryId,
+          beforeNarrativeState.selectedGlobalStoryId,
+        );
+        expect(
+          afterSelectionNarrativeState.selectedStepId,
+          beforeNarrativeState.selectedStepId,
+        );
+
+        await tester.ensureVisible(createAction);
+        await tester.pump();
         await tester.tap(createAction);
         await tester.pump();
 
@@ -641,11 +760,12 @@ void main() {
         tester,
         surfaceSize: const Size(1600, 1000),
       );
+      await _openChaptersTab(tester);
       await expectLater(
         find.byKey(const ValueKey('storylines-workspace-shell')),
         matchesGoldenFile(
           '../../../reports/narrativeStudio/storylines/screenshots/'
-          'ns_storylines_08_ter_true_graph_desktop.png',
+          'ns_storylines_09_chapter_inspector_desktop.png',
         ),
       );
 
@@ -653,11 +773,12 @@ void main() {
         tester,
         surfaceSize: const Size(1600, 700),
       );
+      await _openChaptersTab(tester);
       await expectLater(
-        find.byKey(const ValueKey('storylines-graph-target-read-only')),
+        find.byKey(const ValueKey('storylines-chapters-read-only')),
         matchesGoldenFile(
           '../../../reports/narrativeStudio/storylines/screenshots/'
-          'ns_storylines_08_ter_true_graph_focus.png',
+          'ns_storylines_09_chapter_inspector_focus.png',
         ),
       );
 
@@ -665,11 +786,12 @@ void main() {
         tester,
         surfaceSize: const Size(1180, 1000),
       );
+      await _openChaptersTab(tester);
       await expectLater(
-        find.byKey(const ValueKey('storylines-graph-target-read-only')),
+        find.byKey(const ValueKey('storylines-chapters-read-only')),
         matchesGoldenFile(
           '../../../reports/narrativeStudio/storylines/screenshots/'
-          'ns_storylines_08_ter_true_graph_center.png',
+          'ns_storylines_09_chapter_inspector_center.png',
         ),
       );
     });
@@ -705,6 +827,9 @@ const _targetOnlyStrings = <String>[
   'Brouillon',
   'En cours',
   'Scènes du chapitre',
+  '4 scènes',
+  '12 dialogues',
+  'Prête',
   'Quête annexe',
 ];
```

Diff complet de `reports/narrativeStudio/storylines/road_map_storylines.md` :

```diff
diff --git a/reports/narrativeStudio/storylines/road_map_storylines.md b/reports/narrativeStudio/storylines/road_map_storylines.md
index f47f53a3..327a194f 100644
--- a/reports/narrativeStudio/storylines/road_map_storylines.md
+++ b/reports/narrativeStudio/storylines/road_map_storylines.md
@@ -297,7 +297,7 @@ Interprétation V0 :
 | NS-STORYLINES-06 | Storyline Graph Read-only Placeholder V0 | editor UI / visual gate | DONE | NS-STORYLINES-07 |
 | NS-STORYLINES-07 | Storyline Inspector Read-only V0 | editor UI | DONE | NS-STORYLINES-08 |
 | NS-STORYLINES-08 | Chapters Tab Read-only V0 | editor UI | DONE | NS-STORYLINES-09 |
-| NS-STORYLINES-09 | Chapters Inspector / Scene Ordering Read-only V0 | editor UI | TODO | NS-STORYLINES-10 |
+| NS-STORYLINES-09 | Chapters Inspector / Step Ordering Read-only V0 | editor UI | DONE | NS-STORYLINES-10 |
 | NS-STORYLINES-10 | Storyline Visual Harmonization / Visual Gate V0 | visual gate | TODO | NS-STORYLINES-11 |
 | NS-STORYLINES-11 | Storylines Interaction Wiring V0 | editor UI / test | TODO | NS-STORYLINES-CHECKPOINT |
 | NS-STORYLINES-CHECKPOINT | Storylines V0 Acceptance Checkpoint | checkpoint | TODO | TBD |
@@ -536,20 +536,20 @@ Interprétation V0 :
 - Fake data : aucune quête annexe fake, aucun nom/chiffre Selbrume cible, aucune mini-map ou zoom actif ajouté ; `localEventFlow` reste absent du graph.
 - Prochain lot recommandé inchangé : NS-STORYLINES-09.
 
-### NS-STORYLINES-09 — Chapters Inspector / Scene Ordering Read-only V0
+### NS-STORYLINES-09 — Chapters Inspector / Step Ordering Read-only V0
 
 - Type : editor UI.
-- Objectif : créer inspecteur chapitre et ordre steps/scènes read-only.
-- Fichiers probables : inspector chapitre, read model chapters, tests.
+- Objectif : créer inspecteur chapitre et ordre des étapes narratives read-only.
+- Fichiers modifiés/créés : `packages/map_editor/lib/src/ui/canvas/storylines_workspace.dart`, `packages/map_editor/test/storylines_workspace_shell_test.dart`, `reports/narrativeStudio/storylines/road_map_storylines.md`, `reports/narrativeStudio/storylines/ns_storylines_09_chapters_inspector_step_ordering_read_only_v0.md`, captures Visual Gate NS09.
 - Non-objectifs : pas de réordonnancement, pas d'ajout scène, pas de statut éditorial fake.
 - Dépendances : NS-STORYLINES-08.
-- Critères d'acceptation : détails chapitre lisibles, données absentes marquées à venir.
-- Tests attendus : selected chapter, no selection, disabled controls.
-- Analyse attendue : `flutter analyze`, `git diff --check`.
-- Visual Gate : chapters inspector focus.
-- Risques : vendre un ordre de scènes si seules des steps existent.
-- Design system impact : inspector design-system obligatoire.
-- Statut : TODO.
+- Résumé : la tab `Chapitres` affiche maintenant une liste de chapitres avec sélection locale, un inspecteur chapitre read-only, l'ordre des étapes narratives réelles, et les données futures marquées à venir.
+- Tests exécutés : `flutter test test/storylines_workspace_shell_test.dart`, `flutter test test/storylines_current_global_story_characterization_test.dart`, `flutter test test/narrative_workspace_projection_test.dart`.
+- Analyse exécutée : `flutter analyze --no-fatal-infos lib/src/ui/canvas/storylines_workspace.dart test/storylines_workspace_shell_test.dart test/storylines_current_global_story_characterization_test.dart test/narrative_workspace_projection_test.dart`.
+- Visual Gate : dark theme actif ; captures `ns_storylines_09_chapter_inspector_desktop.png`, `ns_storylines_09_chapter_inspector_focus.png`, `ns_storylines_09_chapter_inspector_center.png`.
+- Design System Gate : confirmé ; composants feature-specific composés avec primitives PokeMap ; aucun `Color(0x...)` / `Colors.*` ajouté.
+- Fake data : aucun wording `Scènes du chapitre`, aucun statut éditorial fake, aucun `localEventFlow` affiché comme chapitre/step.
+- Statut : DONE.
 - Prochain lot attendu : NS-STORYLINES-10.
 
 ### NS-STORYLINES-10 — Storyline Visual Harmonization / Visual Gate V0
@@ -717,9 +717,9 @@ Décision temporaire :
 
 ```text
 Roadmap status: ACTIVE
-Current lot: NS-STORYLINES-08 / NS-STORYLINES-08-bis / NS-STORYLINES-08-ter
+Current lot: NS-STORYLINES-09
 Current lot status: DONE
-Next recommended lot: NS-STORYLINES-09 — Chapters Inspector / Scene Ordering Read-only V0
+Next recommended lot: NS-STORYLINES-10 — Storyline Visual Harmonization / Visual Gate V0
 ```
 
 | Lot | Status | Last update | Notes |
@@ -734,13 +734,24 @@ Next recommended lot: NS-STORYLINES-09 — Chapters Inspector / Scene Ordering R
 | NS-STORYLINES-06 | DONE | 2026-05-28 | Graph read-only placeholder livré avec steps réelles et empty state. |
 | NS-STORYLINES-07 | DONE | 2026-05-28 | Inspector read-only livré avec données réelles, sections futures disabled et empty state. |
 | NS-STORYLINES-08 | DONE | 2026-05-28 | Onglet Chapitres read-only livré ; bis Graph target alignment et ter canvas spatial livrés sans changer le statut NS08. |
-| NS-STORYLINES-09 | TODO | 2026-05-27 | Chapters inspector/order. |
+| NS-STORYLINES-09 | DONE | 2026-05-28 | Chapters inspector / step ordering read-only livré sans scène fake. |
 | NS-STORYLINES-10 | TODO | 2026-05-27 | Visual harmonization. |
 | NS-STORYLINES-11 | TODO | 2026-05-27 | Interaction wiring. |
 | NS-STORYLINES-CHECKPOINT | TODO | 2026-05-27 | Acceptance checkpoint. |
 
 ## 14. Changelog
 
+### 2026-05-28 — NS-STORYLINES-09
+
+- Livraison de l'onglet `Chapitres` avec sélection locale de chapitre : premier chapitre réel sélectionné par défaut, clic sur un autre chapitre limité à l'état UI local.
+- Ajout d'un inspecteur chapitre read-only avec titre, description, ordre, source `Global Story Studio`, mode `Lecture seule` et compteur d'étapes narratives.
+- Ajout de l'ordre des étapes narratives depuis les vraies `NarrativeStepSummary`, sans drag/drop, édition, navigation ou mutation projet.
+- Conservation des protections NS08-ter : graph spatial par défaut, tab `Chapitres` accessible, tabs futures non mutantes, actions futures disabled / non mutantes.
+- Visual Gate dark produit : `ns_storylines_09_chapter_inspector_desktop.png`, `ns_storylines_09_chapter_inspector_focus.png`, `ns_storylines_09_chapter_inspector_center.png`.
+- Design System Gate confirmé : aucun `Color(0x...)` / `Colors.*` ajouté ; composants Storylines feature-specific composés avec primitives PokeMap.
+- Fake data : aucun `Scènes du chapitre`, aucun statut éditorial fake, aucun `localEventFlow` affiché comme chapitre ou étape.
+- Prochain lot recommandé : `NS-STORYLINES-10 — Storyline Visual Harmonization / Visual Gate V0`.
+
 ### 2026-05-28 — NS-STORYLINES-08-ter
 
 - Transformation du graph en vrai canvas spatial read-only : nodes positionnés dans un `Stack`, layer d'edges `CustomPainter`, grille conservée et légende compacte.
```

## 15. Self-review

Auto-review critique :

- Le lot respecte le scope : seule la vue `Chapitres` est améliorée ; le graph NS08-ter n'est pas repris.
- La sélection de chapitre est volontairement locale au widget, sans mutation persistée.
- Le wording produit évite `Scènes du chapitre` et parle d'étapes narratives.
- Le layout desktop devient liste / inspecteur ; le layout medium reste responsive via fallback vertical.
- Les futures données restent affichées comme non branchées ; aucune donnée cible n'est copiée.
- Limite assumée : la section `Étapes manquantes` est prête côté UI, mais la couverture principale de missing ids reste côté projection existante ; aucun nouveau fixture lourd n'a été ajouté pour forcer ce cas dans la tab.
- Risque restant pour NS10 : harmonisation visuelle globale et densité finale de la tab Chapitres, sans changer les garanties métier.
