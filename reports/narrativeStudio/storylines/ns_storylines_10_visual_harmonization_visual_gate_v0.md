# NS-STORYLINES-10 — Storyline Visual Harmonization / Visual Gate V0

## 1. Executive summary

NS-STORYLINES-10 est livré.

Le lot harmonise visuellement le workspace Storylines V0 sans ajouter de feature métier. La vue Graph reste la vue par défaut, avec canvas plus dominant, nodes plus compacts, edges plus lisibles et légende/contrôles plus discrets. La vue Chapitres reste read-only, avec proportions liste/inspecteur plus stables et rows d'étapes narratives plus denses.

Aucune donnée fake, aucune action future activée, aucun `Color(0x...)` / `Colors.*` ajouté.

## 2. Inputs read

Fichiers lus :

```text
AGENTS.md
agent_rules.md
skills/README.md
reports/narrativeStudio/storylines/road_map_storylines.md
reports/narrativeStudio/storylines/ns_storylines_09_chapters_inspector_step_ordering_read_only_v0.md
reports/narrativeStudio/storylines/ns_storylines_08_ter_true_graph_geometry_v0.md
reports/narrativeStudio/storylines/ns_storylines_08_bis_graph_tab_target_alignment_v0.md
reports/narrativeStudio/storylines/ns_storylines_08_chapters_tab_read_only_v0.md
reports/narrativeStudio/storylines/ns_storylines_07_inspector_read_only_v0.md
reports/narrativeStudio/storylines/ns_storylines_06_graph_read_only_placeholder_v0.md
reports/narrativeStudio/storylines/ns_storylines_05_header_tabs_kpi_read_only_v0.md
reports/narrativeStudio/storylines/ns_storylines_04_secondary_list_panel_read_only_v0.md
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

Fichiers attendus absents : aucun fichier obligatoire absent.

Note image cible : l'image Graph est fournie dans le prompt. Une image Chapitres séparée n'est pas listée dans les fichiers attachés du tour ; l'interprétation Chapitres repose sur la description cible du prompt et sur l'état NS09.

## 3. Current Visual Gap Against Target

Vue Graph :

- Le canvas était déjà spatial, mais le header et les marges consommaient trop de hauteur par rapport à la cible.
- Les nodes restaient plus proches de cards textuelles que de nodes compacts.
- Les edges existaient mais étaient encore trop discrets pour porter la lecture du flux.
- La légende et les contrôles read-only prenaient une présence un peu forte en bas du graph.
- Le graph respirait correctement, mais le ratio canvas/header/KPI pouvait être resserré pour donner plus de poids à la zone centrale.

Vue Chapitres :

- La structure liste / inspecteur existait depuis NS09.
- La liste de chapitres était lisible mais légèrement large et card-like.
- L'inspecteur chapitre était fonctionnel mais un peu haut/dense dans ses surfaces.
- Les rows d'étapes utilisaient des status tiles, trop visuelles pour un ordre read-only compact.
- Les boutons disabled étaient corrects ; aucun besoin d'action nouvelle.

Décisions d'harmonisation retenues :

- Compacter les headers Graph et Chapitres.
- Donner plus de hauteur utile au canvas graph.
- Réduire la largeur/hauteur logique des nodes graph.
- Renforcer légèrement l'edge layer via tokens existants.
- Rendre légende et contrôles plus discrets.
- Stabiliser la proportion liste/inspecteur Chapitres.
- Compacter chapter cards et rows d'ordre des étapes.

## 4. Target image interpretation

Les images cibles sont utilisées comme références de composition et layout uniquement.

Elles guident :

- hiérarchie globale ;
- densité ;
- place du graph ;
- lecture en nodes connectés ;
- équilibre liste / détail dans Chapitres ;
- ambiance dark premium.

Elles ne sont jamais utilisées comme :

- source de données ;
- fixture ;
- texte produit à copier ;
- vérité métier.

## 5. Implementation summary

Fichiers modifiés :

- `packages/map_editor/lib/src/ui/canvas/storylines_workspace.dart`
- `packages/map_editor/test/storylines_workspace_shell_test.dart`
- `reports/narrativeStudio/storylines/road_map_storylines.md`

Fichiers créés :

- `reports/narrativeStudio/storylines/ns_storylines_10_visual_harmonization_visual_gate_v0.md`
- `reports/narrativeStudio/storylines/screenshots/ns_storylines_10_graph_desktop.png`
- `reports/narrativeStudio/storylines/screenshots/ns_storylines_10_graph_focus.png`
- `reports/narrativeStudio/storylines/screenshots/ns_storylines_10_graph_center.png`
- `reports/narrativeStudio/storylines/screenshots/ns_storylines_10_chapters_desktop.png`
- `reports/narrativeStudio/storylines/screenshots/ns_storylines_10_chapters_focus.png`
- `reports/narrativeStudio/storylines/screenshots/ns_storylines_10_chapters_center.png`

## 6. Graph visual harmonization

Changements Graph :

- Padding de surface réduit.
- Hauteur minimale canvas augmentée.
- Canvas élargi légèrement dans sa contrainte interne.
- Radius de surface harmonisé.
- Nodes chapitre/step/boundary rendus plus compacts.
- Géométrie ajustée : nodes plus étroits et plus bas, espacements recalculés.
- Edges rendus plus visibles via alpha/stroke tokens.
- Légende et contrôles read-only rendus plus discrets.

Garanties :

- Graph reste vue par défaut.
- `storylines-graph-target-read-only`, `storylines-graph-canvas`, `storylines-graph-spatial-layer`, `storylines-graph-edge-layer` restent testés.
- Aucune branche, quête annexe, mini-map active ou zoom actif ajouté.

## 7. Chapters visual harmonization

Changements Chapitres :

- Padding de surface réduit.
- Header compacté.
- Largeur liste/inspecteur ajustée pour donner plus d'air à l'inspecteur.
- Chapter cards compactées.
- Inspecteur chapitre compacté.
- Rows d'ordre des étapes remplacées par une présentation plus dense, feature-specific, sourcée par tokens.

Garanties :

- Tab Chapitres reste read-only.
- Sélection locale inchangée.
- `Nouveau chapitre` reste disabled / non mutant.
- Aucun wording actif `Scènes du chapitre`.

## 8. Data source / anti-fake guarantees

Sources utilisées inchangées :

- `NarrativeScenarioSummary`
- `NarrativeChapterSummary`
- `NarrativeStepSummary`
- compteurs réels déjà présents
- empty states honnêtes
- disabled feature reasons

Interdits maintenus par test :

- données cible Selbrume ;
- quêtes annexes fake ;
- tags/world rules/facts/activité récente ;
- statuts éditoriaux fake ;
- `Scènes du chapitre`, `4 scènes`, `12 dialogues`, `Prête` ;
- `Fin de l’histoire`, `Conclusion`.

## 9. Disabled interactions

Restent disabled / non mutantes :

- `Nouvelle storyline`
- `Valider`
- `+`
- `Nouveau chapitre`
- tabs futures `Étapes`, `Scènes`, `Statistiques`, `Tests`

Aucune navigation, édition, création, suppression, drag/drop, zoom actif ou mini-map active n'a été ajoutée.

## 10. Design System Gate

Mini audit :

- Aucun `Color(0x...)` ajouté.
- Aucun `Colors.*` ajouté.
- Pas de composant générique local hors design system.
- Les composants Storylines restent feature-specific.
- Surfaces/cards/status/icon/buttons utilisent les primitives PokeMap.
- Les couleurs du painter restent injectées depuis `context.pokeMapColors`.

Recherche `Color(0x...) / Colors.*` :

```text
Commande : rg "Color\(0x|Colors\." packages/map_editor/lib/src/ui/canvas/storylines_workspace.dart packages/map_editor/test/storylines_workspace_shell_test.dart packages/map_editor/test/narrative_workspace_projection_test.dart packages/map_editor/test/storylines_current_global_story_characterization_test.dart
Sortie : <vide>
```

## 11. Tests added or modified

Tests modifiés dans `packages/map_editor/test/storylines_workspace_shell_test.dart` :

- groupe renommé NS10 ;
- Visual Gate Graph ajouté : desktop, focus, center ;
- Visual Gate Chapitres ajouté : desktop, focus, center ;
- anti-fake étendu avec `Histoire globale`, `Le port`, `Les marais`, `Le phare`, `Fin de l’histoire`, `Conclusion`.

Les tests de comportement existants restent inchangés sur le fond :

- Graph actif par défaut ;
- canvas spatial ;
- edge layer ;
- nodes réels ;
- tab Chapitres accessible ;
- sélection locale ;
- inspecteur chapitre ;
- actions/tabs futures non mutantes ;
- dark theme ;
- no raw colors.

## 12. Visual Gate

Captures Graph :

```text
reports/narrativeStudio/storylines/screenshots/ns_storylines_10_graph_desktop.png
reports/narrativeStudio/storylines/screenshots/ns_storylines_10_graph_focus.png
reports/narrativeStudio/storylines/screenshots/ns_storylines_10_graph_center.png
```

Captures Chapitres :

```text
reports/narrativeStudio/storylines/screenshots/ns_storylines_10_chapters_desktop.png
reports/narrativeStudio/storylines/screenshots/ns_storylines_10_chapters_focus.png
reports/narrativeStudio/storylines/screenshots/ns_storylines_10_chapters_center.png
```

Tailles :

```text
   51308 reports/narrativeStudio/storylines/screenshots/ns_storylines_10_chapters_center.png
   67224 reports/narrativeStudio/storylines/screenshots/ns_storylines_10_chapters_desktop.png
   48886 reports/narrativeStudio/storylines/screenshots/ns_storylines_10_chapters_focus.png
   59000 reports/narrativeStudio/storylines/screenshots/ns_storylines_10_graph_center.png
   68155 reports/narrativeStudio/storylines/screenshots/ns_storylines_10_graph_desktop.png
   46699 reports/narrativeStudio/storylines/screenshots/ns_storylines_10_graph_focus.png
  341272 total
```

## 13. Roadmap update

`reports/narrativeStudio/storylines/road_map_storylines.md` a été mis à jour :

- NS-STORYLINES-10 marqué `DONE`.
- Résumé, fichiers, tests, analyse, screenshots, Design System Gate et anti-fake ajoutés.
- Prochain lot recommandé : `NS-STORYLINES-11 — Storylines Interaction Wiring V0`.

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
dart format packages/map_editor/lib/src/ui/canvas/storylines_workspace.dart
dart format packages/map_editor/test/storylines_workspace_shell_test.dart
cd packages/map_editor && flutter test --update-goldens test/storylines_workspace_shell_test.dart
cd packages/map_editor && flutter test test/storylines_workspace_shell_test.dart
cd packages/map_editor && flutter test test/storylines_current_global_story_characterization_test.dart
cd packages/map_editor && flutter test test/narrative_workspace_projection_test.dart
cd packages/map_editor && flutter analyze --no-fatal-infos lib/src/ui/canvas/storylines_workspace.dart test/storylines_workspace_shell_test.dart test/storylines_current_global_story_characterization_test.dart test/narrative_workspace_projection_test.dart
rg "Color\(0x|Colors\." packages/map_editor/lib/src/ui/canvas/storylines_workspace.dart packages/map_editor/test/storylines_workspace_shell_test.dart packages/map_editor/test/narrative_workspace_projection_test.dart packages/map_editor/test/storylines_current_global_story_characterization_test.dart
git diff --check
```

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
?? reports/narrativeStudio/storylines/ns_storylines_10_visual_harmonization_visual_gate_v0.md
?? reports/narrativeStudio/storylines/screenshots/ns_storylines_10_chapters_center.png
?? reports/narrativeStudio/storylines/screenshots/ns_storylines_10_chapters_desktop.png
?? reports/narrativeStudio/storylines/screenshots/ns_storylines_10_chapters_focus.png
?? reports/narrativeStudio/storylines/screenshots/ns_storylines_10_graph_center.png
?? reports/narrativeStudio/storylines/screenshots/ns_storylines_10_graph_desktop.png
?? reports/narrativeStudio/storylines/screenshots/ns_storylines_10_graph_focus.png
```

Git diff --stat final :

```text
 .../lib/src/ui/canvas/storylines_workspace.dart    | 549 +++++++++++----------
 .../test/storylines_workspace_shell_test.dart      |  50 +-
 .../storylines/road_map_storylines.md              |  34 +-
 3 files changed, 350 insertions(+), 283 deletions(-)
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
Le contenu complet du rapport créé est le présent document, du titre "# NS-STORYLINES-10 — Storyline Visual Harmonization / Visual Gate V0" jusqu'à la section "## 16. Self-review".
```

Sortie exacte de `flutter test test/storylines_workspace_shell_test.dart` :

```text
00:00 +0: NS-STORYLINES-10 Visual harmonization / visual gate V0 renders a read-only three-pane shell from real global story data
[step_studio_trace] action=apply_document scenario=audit_global_story rows=[]
[step_studio_trace] action=apply_document_metadata scenario=audit_global_story contains_emma=false contains_empty_entity=false
[step_studio_trace] action=apply_document scenario=audit_second_global_story rows=[]
[step_studio_trace] action=apply_document_metadata scenario=audit_second_global_story contains_emma=false contains_empty_entity=false
00:00 +1: NS-STORYLINES-10 Visual harmonization / visual gate V0 renders an honest empty state when the selected global story has no steps
[step_studio_trace] action=apply_document scenario=audit_empty_global_story rows=[]
[step_studio_trace] action=apply_document_metadata scenario=audit_empty_global_story contains_emma=false contains_empty_entity=false
00:00 +2: NS-STORYLINES-10 Visual harmonization / visual gate V0 shows the Chapters tab from Global Story Studio metadata read-only
[step_studio_trace] action=apply_document scenario=audit_global_story rows=[]
[step_studio_trace] action=apply_document_metadata scenario=audit_global_story contains_emma=false contains_empty_entity=false
[step_studio_trace] action=apply_document scenario=audit_second_global_story rows=[]
[step_studio_trace] action=apply_document_metadata scenario=audit_second_global_story contains_emma=false contains_empty_entity=false
00:01 +3: NS-STORYLINES-10 Visual harmonization / visual gate V0 shows an honest Chapters empty state
[step_studio_trace] action=apply_document scenario=audit_empty_global_story rows=[]
[step_studio_trace] action=apply_document_metadata scenario=audit_empty_global_story contains_emma=false contains_empty_entity=false
00:01 +4: NS-STORYLINES-10 Visual harmonization / visual gate V0 renders an honest inspector empty state without global story
00:01 +5: NS-STORYLINES-10 Visual harmonization / visual gate V0 keeps future Storyline tabs read-only and non-mutating
[step_studio_trace] action=apply_document scenario=audit_global_story rows=[]
[step_studio_trace] action=apply_document_metadata scenario=audit_global_story contains_emma=false contains_empty_entity=false
[step_studio_trace] action=apply_document scenario=audit_second_global_story rows=[]
[step_studio_trace] action=apply_document_metadata scenario=audit_second_global_story contains_emma=false contains_empty_entity=false
00:01 +6: NS-STORYLINES-10 Visual harmonization / visual gate V0 keeps future header actions disabled and non-mutating
[step_studio_trace] action=apply_document scenario=audit_global_story rows=[]
[step_studio_trace] action=apply_document_metadata scenario=audit_global_story contains_emma=false contains_empty_entity=false
[step_studio_trace] action=apply_document scenario=audit_second_global_story rows=[]
[step_studio_trace] action=apply_document_metadata scenario=audit_second_global_story contains_emma=false contains_empty_entity=false
00:01 +7: NS-STORYLINES-10 Visual harmonization / visual gate V0 storylines UI source keeps raw colors out of the feature
00:01 +8: NS-STORYLINES-10 Visual harmonization / visual gate V0 storylines action test does not use silent taps
00:01 +9: NS-STORYLINES-10 Visual harmonization / visual gate V0 uses PokeMap dark theme in the Visual Gate harness
[step_studio_trace] action=apply_document scenario=audit_global_story rows=[]
[step_studio_trace] action=apply_document_metadata scenario=audit_global_story contains_emma=false contains_empty_entity=false
[step_studio_trace] action=apply_document scenario=audit_second_global_story rows=[]
[step_studio_trace] action=apply_document_metadata scenario=audit_second_global_story contains_emma=false contains_empty_entity=false
00:01 +10: NS-STORYLINES-10 Visual harmonization / visual gate V0 writes Visual Gate screenshots
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
No issues found! (ran in 3.7s)
```

Résultats du Visual Gate :

```text
reports/narrativeStudio/storylines/screenshots/ns_storylines_10_chapters_center.png
reports/narrativeStudio/storylines/screenshots/ns_storylines_10_chapters_desktop.png
reports/narrativeStudio/storylines/screenshots/ns_storylines_10_chapters_focus.png
reports/narrativeStudio/storylines/screenshots/ns_storylines_10_graph_center.png
reports/narrativeStudio/storylines/screenshots/ns_storylines_10_graph_desktop.png
reports/narrativeStudio/storylines/screenshots/ns_storylines_10_graph_focus.png
```

Diff complet de `packages/map_editor/lib/src/ui/canvas/storylines_workspace.dart` :

```diff
diff --git a/packages/map_editor/lib/src/ui/canvas/storylines_workspace.dart b/packages/map_editor/lib/src/ui/canvas/storylines_workspace.dart
index 908fe266..81b45a54 100644
--- a/packages/map_editor/lib/src/ui/canvas/storylines_workspace.dart
+++ b/packages/map_editor/lib/src/ui/canvas/storylines_workspace.dart
@@ -422,14 +422,14 @@ class _StorylineGraphSection extends StatelessWidget {
     final hasChapters = chapters.isNotEmpty;
     return PokeMapPageSurface(
       key: const ValueKey('storylines-graph-target-read-only'),
-      padding: const EdgeInsets.all(18),
+      padding: const EdgeInsets.all(14),
       child: LayoutBuilder(
         builder: (context, constraints) {
           final availableCanvasHeight = constraints.maxHeight.isFinite
-              ? constraints.maxHeight - 72
+              ? constraints.maxHeight - 56
               : 380.0;
           final canvasHeight =
-              availableCanvasHeight < 320 ? 320.0 : availableCanvasHeight;
+              availableCanvasHeight < 360 ? 360.0 : availableCanvasHeight;
           return SingleChildScrollView(
             child: Column(
               crossAxisAlignment: CrossAxisAlignment.stretch,
@@ -440,10 +440,10 @@ class _StorylineGraphSection extends StatelessWidget {
                     const PokeMapIconTile(
                       icon: CupertinoIcons.arrow_branch,
                       tone: PokeMapTone.narrative,
-                      size: 38,
-                      iconSize: 18,
+                      size: 34,
+                      iconSize: 16,
                     ),
-                    const SizedBox(width: 12),
+                    const SizedBox(width: 10),
                     Expanded(
                       child: Column(
                         crossAxisAlignment: CrossAxisAlignment.start,
@@ -452,18 +452,18 @@ class _StorylineGraphSection extends StatelessWidget {
                             'Graph read-only',
                             style: TextStyle(
                               color: colors.textPrimary,
-                              fontSize: 15,
+                              fontSize: 14.5,
                               fontWeight: FontWeight.w800,
                             ),
                           ),
-                          const SizedBox(height: 6),
+                          const SizedBox(height: 4),
                           Text(
                             hasChapters
                                 ? 'Canvas spatial issu de Global Story Studio. Les steps restent visibles en aperçu, sans relations inventées.'
                                 : 'Lecture linéaire prudente depuis Step Studio. Les relations détaillées restent non branchées.',
                             style: TextStyle(
                               color: colors.textSecondary,
-                              fontSize: 12.5,
+                              fontSize: 12,
                               height: 1.35,
                             ),
                           ),
@@ -472,7 +472,7 @@ class _StorylineGraphSection extends StatelessWidget {
                     ),
                   ],
                 ),
-                const SizedBox(height: 12),
+                const SizedBox(height: 10),
                 if (chapters.isEmpty && steps.isEmpty)
                   const _StorylineGraphEmptyState()
                 else
@@ -508,7 +508,7 @@ class _StorylineGraphCanvas extends StatelessWidget {
       builder: (context, constraints) {
         final canvasWidth =
             constraints.maxWidth.isFinite && constraints.maxWidth > 48
-                ? constraints.maxWidth - 32
+                ? constraints.maxWidth - 24
                 : 720.0;
         final canvasHeight =
             constraints.maxHeight.isFinite && constraints.maxHeight > 0
@@ -529,7 +529,7 @@ class _StorylineGraphCanvas extends StatelessWidget {
           clipBehavior: Clip.antiAlias,
           decoration: BoxDecoration(
             color: colors.surfaceSubtle,
-            borderRadius: BorderRadius.circular(10),
+            borderRadius: BorderRadius.circular(6),
             border: Border.all(color: colors.borderSubtle),
           ),
           child: Stack(
@@ -556,9 +556,9 @@ class _StorylineGraphCanvas extends StatelessWidget {
                             painter: _StorylineGraphEdgePainter(
                               edges: geometry.edges,
                               lineColor:
-                                  colors.textMuted.withValues(alpha: 0.58),
+                                  colors.textMuted.withValues(alpha: 0.72),
                               arrowColor: colors.brandPrimaryBorder
-                                  .withValues(alpha: 0.78),
+                                  .withValues(alpha: 0.88),
                             ),
                           ),
                         ),
@@ -570,9 +570,9 @@ class _StorylineGraphCanvas extends StatelessWidget {
                             child: nodes[index],
                           ),
                         Positioned(
-                          left: 18,
-                          right: 18,
-                          bottom: 16,
+                          left: 14,
+                          right: 14,
+                          bottom: 12,
                           child: Wrap(
                             alignment: WrapAlignment.spaceBetween,
                             crossAxisAlignment: WrapCrossAlignment.center,
@@ -658,8 +658,8 @@ class _StorylineGraphGeometry {
     required int nodeCount,
   }) {
     final compact = size.width < 760;
-    final nodeWidth = compact ? 168.0 : 186.0;
-    final nodeHeight = compact ? 132.0 : 148.0;
+    final nodeWidth = compact ? 152.0 : 172.0;
+    final nodeHeight = compact ? 112.0 : 124.0;
     final positions = <_StorylineGraphNodePosition>[];
 
     if (compact) {
@@ -671,9 +671,9 @@ class _StorylineGraphGeometry {
       final rightColumn = horizontalPadding + nodeWidth + columnGap;
       final rowCount = (nodeCount / 2).ceil().clamp(1, 4);
       final rowSpacing = _bounded(
-        (size.height - 126 - topPadding - nodeHeight) / rowCount,
-        118,
-        166,
+        (size.height - 104 - topPadding - nodeHeight) / rowCount,
+        104,
+        150,
       );
       for (var index = 0; index < nodeCount; index++) {
         final row = index ~/ 2;
@@ -692,13 +692,13 @@ class _StorylineGraphGeometry {
       final availableWidth = size.width - horizontalPadding * 2 - nodeWidth;
       final step = nodeCount <= 1 ? 0.0 : availableWidth / (nodeCount - 1);
       final baseTop = _bounded(
-        (size.height - 104 - nodeHeight) / 2,
-        34,
-        118,
+        (size.height - 92 - nodeHeight) / 2,
+        42,
+        130,
       );
       for (var index = 0; index < nodeCount; index++) {
         final isChapterNode = index > 0 && index < nodeCount - 1;
-        final amplitude = nodeCount > 4 && size.height > 430 ? 34.0 : 0.0;
+        final amplitude = nodeCount > 4 && size.height > 430 ? 38.0 : 0.0;
         final lift = isChapterNode && index.isOdd ? -amplitude : 0.0;
         final drop = isChapterNode && index.isEven ? amplitude : 0.0;
         positions.add(
@@ -787,104 +787,99 @@ class _StorylineGraphChapterNode extends StatelessWidget {
     final colors = context.pokeMapColors;
     final visibleSteps = chapter.steps.take(2).toList(growable: false);
     final remainingStepCount = chapter.steps.length - visibleSteps.length;
-    return SizedBox(
+    return PokeMapCard(
       key: ValueKey('storylines-graph-node-${chapter.id}'),
-      width: 186,
-      child: PokeMapCard(
-        padding: const EdgeInsets.all(11),
-        child: Column(
-          crossAxisAlignment: CrossAxisAlignment.start,
-          children: [
-            Row(
-              crossAxisAlignment: CrossAxisAlignment.start,
-              children: [
-                const PokeMapIconTile(
-                  icon: CupertinoIcons.book,
-                  tone: PokeMapTone.narrative,
-                  size: 34,
-                  iconSize: 16,
-                ),
-                const SizedBox(width: 10),
-                Expanded(
-                  child: Column(
-                    crossAxisAlignment: CrossAxisAlignment.start,
-                    children: [
-                      Text(
-                        'Chapitre ${chapter.order + 1}',
-                        style: TextStyle(
-                          color: colors.textMuted,
-                          fontSize: 10.5,
-                          fontWeight: FontWeight.w800,
-                          letterSpacing: 0.4,
-                        ),
+      padding: const EdgeInsets.all(10),
+      child: Column(
+        crossAxisAlignment: CrossAxisAlignment.start,
+        children: [
+          Row(
+            crossAxisAlignment: CrossAxisAlignment.start,
+            children: [
+              const PokeMapIconTile(
+                icon: CupertinoIcons.book,
+                tone: PokeMapTone.narrative,
+                size: 28,
+                iconSize: 13,
+              ),
+              const SizedBox(width: 8),
+              Expanded(
+                child: Column(
+                  crossAxisAlignment: CrossAxisAlignment.start,
+                  children: [
+                    Text(
+                      'Chapitre ${chapter.order + 1}',
+                      style: TextStyle(
+                        color: colors.textMuted,
+                        fontSize: 10,
+                        fontWeight: FontWeight.w800,
                       ),
-                      const SizedBox(height: 4),
-                      Text(
-                        chapter.name,
-                        maxLines: 2,
-                        overflow: TextOverflow.ellipsis,
-                        style: TextStyle(
-                          color: colors.textPrimary,
-                          fontSize: 13.5,
-                          fontWeight: FontWeight.w800,
-                        ),
+                    ),
+                    const SizedBox(height: 3),
+                    Text(
+                      chapter.name,
+                      maxLines: 2,
+                      overflow: TextOverflow.ellipsis,
+                      style: TextStyle(
+                        color: colors.textPrimary,
+                        fontSize: 12.5,
+                        fontWeight: FontWeight.w800,
                       ),
-                    ],
-                  ),
+                    ),
+                  ],
                 ),
-              ],
+              )
+            ],
+          ),
+          const SizedBox(height: 6),
+          Text(
+            _formatFrenchCount(
+              chapter.steps.length,
+              singular: 'étape narrative liée',
+              plural: 'étapes narratives liées',
             ),
-            const SizedBox(height: 8),
+            style: TextStyle(
+              color: colors.textMuted,
+              fontSize: 10,
+              fontWeight: FontWeight.w800,
+            ),
+          ),
+          const SizedBox(height: 6),
+          if (visibleSteps.isEmpty)
             Text(
-              _formatFrenchCount(
-                chapter.steps.length,
-                singular: 'étape narrative liée',
-                plural: 'étapes narratives liées',
-              ),
+              'Aucune étape narrative liée à ce chapitre.',
               style: TextStyle(
-                color: colors.textMuted,
-                fontSize: 10.5,
-                fontWeight: FontWeight.w800,
-                letterSpacing: 0.25,
+                color: colors.textSecondary,
+                fontSize: 11,
+                height: 1.25,
               ),
-            ),
-            const SizedBox(height: 8),
-            if (visibleSteps.isEmpty)
-              Text(
-                'Aucune étape narrative liée à ce chapitre.',
-                style: TextStyle(
-                  color: colors.textSecondary,
-                  fontSize: 11.5,
-                  height: 1.3,
-                ),
-              )
-            else
-              Column(
-                crossAxisAlignment: CrossAxisAlignment.start,
-                children: [
-                  for (final step in visibleSteps) ...[
-                    _StorylineGraphStepPreview(step: step),
-                    if (step != visibleSteps.last) const SizedBox(height: 8),
-                  ],
-                  if (remainingStepCount > 0) ...[
-                    const SizedBox(height: 8),
-                    Text(
-                      '+ ${_formatFrenchCount(
-                        remainingStepCount,
-                        singular: 'étape narrative réelle',
-                        plural: 'étapes narratives réelles',
-                      )}',
-                      style: TextStyle(
-                        color: colors.textMuted,
-                        fontSize: 11,
-                        fontWeight: FontWeight.w700,
-                      ),
+            )
+          else
+            Column(
+              crossAxisAlignment: CrossAxisAlignment.start,
+              children: [
+                for (final step in visibleSteps) ...[
+                  _StorylineGraphStepPreview(step: step),
+                  if (step != visibleSteps.last) const SizedBox(height: 6),
+                ],
+                if (remainingStepCount > 0) ...[
+                  const SizedBox(height: 6),
+                  Text(
+                    '+ ${_formatFrenchCount(
+                      remainingStepCount,
+                      singular: 'étape narrative réelle',
+                      plural: 'étapes narratives réelles',
+                    )}',
+                    style: TextStyle(
+                      color: colors.textMuted,
+                      fontSize: 10.5,
+                      fontWeight: FontWeight.w700,
                     ),
-                  ],
+                  ),
                 ],
-              ),
-          ],
-        ),
+              ],
+            ),
+        ],
       ),
     );
   }
@@ -903,67 +898,64 @@ class _StorylineGraphStepNode extends StatelessWidget {
   Widget build(BuildContext context) {
     final colors = context.pokeMapColors;
     final description = step.description.trim();
-    return SizedBox(
+    return PokeMapCard(
       key: ValueKey('storylines-graph-step-node-${step.id}'),
-      width: 186,
-      child: PokeMapCard(
-        padding: const EdgeInsets.all(13),
-        child: Column(
-          crossAxisAlignment: CrossAxisAlignment.start,
-          children: [
-            Row(
-              crossAxisAlignment: CrossAxisAlignment.start,
-              children: [
-                const PokeMapIconTile(
-                  icon: CupertinoIcons.smallcircle_fill_circle,
-                  tone: PokeMapTone.info,
-                  size: 34,
-                  iconSize: 15,
-                ),
-                const SizedBox(width: 10),
-                Expanded(
-                  child: Column(
-                    crossAxisAlignment: CrossAxisAlignment.start,
-                    children: [
-                      Text(
-                        'Étape narrative $position',
-                        style: TextStyle(
-                          color: colors.textMuted,
-                          fontSize: 11,
-                          fontWeight: FontWeight.w700,
-                        ),
+      padding: const EdgeInsets.all(10),
+      child: Column(
+        crossAxisAlignment: CrossAxisAlignment.start,
+        children: [
+          Row(
+            crossAxisAlignment: CrossAxisAlignment.start,
+            children: [
+              const PokeMapIconTile(
+                icon: CupertinoIcons.smallcircle_fill_circle,
+                tone: PokeMapTone.info,
+                size: 28,
+                iconSize: 12,
+              ),
+              const SizedBox(width: 8),
+              Expanded(
+                child: Column(
+                  crossAxisAlignment: CrossAxisAlignment.start,
+                  children: [
+                    Text(
+                      'Étape narrative $position',
+                      style: TextStyle(
+                        color: colors.textMuted,
+                        fontSize: 10,
+                        fontWeight: FontWeight.w700,
                       ),
-                      const SizedBox(height: 5),
-                      Text(
-                        step.name,
-                        maxLines: 2,
-                        overflow: TextOverflow.ellipsis,
-                        style: TextStyle(
-                          color: colors.textPrimary,
-                          fontSize: 13.5,
-                          fontWeight: FontWeight.w800,
-                        ),
+                    ),
+                    const SizedBox(height: 3),
+                    Text(
+                      step.name,
+                      maxLines: 2,
+                      overflow: TextOverflow.ellipsis,
+                      style: TextStyle(
+                        color: colors.textPrimary,
+                        fontSize: 12.5,
+                        fontWeight: FontWeight.w800,
                       ),
-                    ],
-                  ),
-                ),
-              ],
-            ),
-            if (description.isNotEmpty) ...[
-              const SizedBox(height: 8),
-              Text(
-                description,
-                maxLines: 3,
-                overflow: TextOverflow.ellipsis,
-                style: TextStyle(
-                  color: colors.textSecondary,
-                  fontSize: 11.5,
-                  height: 1.3,
+                    ),
+                  ],
                 ),
               ),
             ],
+          ),
+          if (description.isNotEmpty) ...[
+            const SizedBox(height: 6),
+            Text(
+              description,
+              maxLines: 2,
+              overflow: TextOverflow.ellipsis,
+              style: TextStyle(
+                color: colors.textSecondary,
+                fontSize: 11,
+                height: 1.25,
+              ),
+            ),
           ],
-        ),
+        ],
       ),
     );
   }
@@ -986,10 +978,10 @@ class _StorylineGraphStepPreview extends StatelessWidget {
         const PokeMapIconTile(
           icon: CupertinoIcons.smallcircle_fill_circle,
           tone: PokeMapTone.info,
-          size: 24,
-          iconSize: 10,
+          size: 20,
+          iconSize: 8,
         ),
-        const SizedBox(width: 8),
+        const SizedBox(width: 6),
         Expanded(
           child: Column(
             crossAxisAlignment: CrossAxisAlignment.start,
@@ -1000,19 +992,19 @@ class _StorylineGraphStepPreview extends StatelessWidget {
                 overflow: TextOverflow.ellipsis,
                 style: TextStyle(
                   color: colors.textPrimary,
-                  fontSize: 11.5,
+                  fontSize: 11,
                   fontWeight: FontWeight.w800,
                 ),
               ),
               if (description.isNotEmpty) ...[
-                const SizedBox(height: 3),
+                const SizedBox(height: 2),
                 Text(
                   description,
                   maxLines: 1,
                   overflow: TextOverflow.ellipsis,
                   style: TextStyle(
                     color: colors.textSecondary,
-                    fontSize: 10.5,
+                    fontSize: 10,
                     height: 1.25,
                   ),
                 ),
@@ -1042,43 +1034,40 @@ class _StorylineGraphBoundaryNode extends StatelessWidget {
   @override
   Widget build(BuildContext context) {
     final colors = context.pokeMapColors;
-    return SizedBox(
-      width: 156,
-      child: PokeMapCard(
-        padding: const EdgeInsets.all(12),
-        child: Column(
-          crossAxisAlignment: CrossAxisAlignment.start,
-          children: [
-            PokeMapIconTile(
-              icon: icon,
-              tone: tone,
-              size: 32,
-              iconSize: 15,
-            ),
-            const SizedBox(height: 9),
-            Text(
-              title,
-              maxLines: 2,
-              overflow: TextOverflow.ellipsis,
-              style: TextStyle(
-                color: colors.textPrimary,
-                fontSize: 12.5,
-                fontWeight: FontWeight.w800,
-              ),
+    return PokeMapCard(
+      padding: const EdgeInsets.all(10),
+      child: Column(
+        crossAxisAlignment: CrossAxisAlignment.start,
+        children: [
+          PokeMapIconTile(
+            icon: icon,
+            tone: tone,
+            size: 28,
+            iconSize: 13,
+          ),
+          const SizedBox(height: 7),
+          Text(
+            title,
+            maxLines: 2,
+            overflow: TextOverflow.ellipsis,
+            style: TextStyle(
+              color: colors.textPrimary,
+              fontSize: 12,
+              fontWeight: FontWeight.w800,
             ),
-            const SizedBox(height: 4),
-            Text(
-              subtitle,
-              maxLines: 2,
-              overflow: TextOverflow.ellipsis,
-              style: TextStyle(
-                color: colors.textSecondary,
-                fontSize: 10.5,
-                height: 1.25,
-              ),
+          ),
+          const SizedBox(height: 3),
+          Text(
+            subtitle,
+            maxLines: 2,
+            overflow: TextOverflow.ellipsis,
+            style: TextStyle(
+              color: colors.textSecondary,
+              fontSize: 10,
+              height: 1.25,
             ),
-          ],
-        ),
+          ),
+        ],
       ),
     );
   }
@@ -1102,7 +1091,7 @@ class _StorylineGraphEdgePainter extends CustomPainter {
     }
     final linePaint = Paint()
       ..color = lineColor
-      ..strokeWidth = 1.5
+      ..strokeWidth = 1.8
       ..style = PaintingStyle.stroke
       ..strokeCap = StrokeCap.round;
     final arrowPaint = Paint()
@@ -1139,7 +1128,7 @@ class _StorylineGraphEdgePainter extends CustomPainter {
 
   void _drawArrow(Canvas canvas, _StorylineGraphEdge edge, Paint paint) {
     final direction = (edge.to - edge.from).direction;
-    const arrowSize = 7.0;
+    const arrowSize = 7.5;
     final arrow = Path()
       ..moveTo(edge.to.dx, edge.to.dy)
       ..lineTo(
@@ -1183,10 +1172,10 @@ class _StorylineGraphLegend extends StatelessWidget {
           border: Border.all(color: colors.borderSubtle),
         ),
         child: Padding(
-          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
+          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
           child: Wrap(
-            spacing: 12,
-            runSpacing: 6,
+            spacing: 10,
+            runSpacing: 5,
             crossAxisAlignment: WrapCrossAlignment.center,
             children: [
               const _StorylineGraphLegendItem(
@@ -1244,7 +1233,7 @@ class _StorylineGraphLegendItem extends StatelessWidget {
           icon: icon,
           tone: tone,
           size: 22,
-          iconSize: 10,
+          iconSize: 9,
         ),
         const SizedBox(width: 6),
         Flexible(
@@ -1254,7 +1243,7 @@ class _StorylineGraphLegendItem extends StatelessWidget {
             overflow: TextOverflow.ellipsis,
             style: TextStyle(
               color: colors.textSecondary,
-              fontSize: 10.5,
+              fontSize: 10,
               fontWeight: FontWeight.w700,
             ),
           ),
@@ -1275,11 +1264,11 @@ class _StorylineGraphReadOnlyControls extends StatelessWidget {
       child: DecoratedBox(
         decoration: BoxDecoration(
           color: colors.surfaceSubtle.withValues(alpha: 0.72),
-          borderRadius: BorderRadius.circular(8),
+          borderRadius: BorderRadius.circular(6),
           border: Border.all(color: colors.borderSubtle),
         ),
         child: Padding(
-          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
+          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
           child: Row(
             mainAxisSize: MainAxisSize.min,
             children: [
@@ -1287,7 +1276,7 @@ class _StorylineGraphReadOnlyControls extends StatelessWidget {
                 icon: CupertinoIcons.lock,
                 tone: PokeMapTone.neutral,
                 size: 22,
-                iconSize: 10,
+                iconSize: 9,
               ),
               const SizedBox(width: 6),
               Flexible(
@@ -1301,7 +1290,7 @@ class _StorylineGraphReadOnlyControls extends StatelessWidget {
                       overflow: TextOverflow.ellipsis,
                       style: TextStyle(
                         color: colors.textSecondary,
-                        fontSize: 10.5,
+                        fontSize: 10,
                         fontWeight: FontWeight.w700,
                       ),
                     ),
@@ -1311,7 +1300,7 @@ class _StorylineGraphReadOnlyControls extends StatelessWidget {
                       overflow: TextOverflow.ellipsis,
                       style: TextStyle(
                         color: colors.textMuted,
-                        fontSize: 9.5,
+                        fontSize: 9,
                         fontWeight: FontWeight.w600,
                       ),
                     ),
@@ -1443,7 +1432,7 @@ class _StorylineChaptersSectionState extends State<_StorylineChaptersSection> {
     final selectedChapter = _selectedChapter;
     return PokeMapPageSurface(
       key: const ValueKey('storylines-chapters-read-only'),
-      padding: const EdgeInsets.all(18),
+      padding: const EdgeInsets.all(16),
       child: SingleChildScrollView(
         child: Column(
           crossAxisAlignment: CrossAxisAlignment.stretch,
@@ -1454,10 +1443,10 @@ class _StorylineChaptersSectionState extends State<_StorylineChaptersSection> {
                 const PokeMapIconTile(
                   icon: CupertinoIcons.square_list,
                   tone: PokeMapTone.narrative,
-                  size: 38,
-                  iconSize: 18,
+                  size: 34,
+                  iconSize: 16,
                 ),
-                const SizedBox(width: 12),
+                const SizedBox(width: 10),
                 Expanded(
                   child: Column(
                     crossAxisAlignment: CrossAxisAlignment.start,
@@ -1466,23 +1455,23 @@ class _StorylineChaptersSectionState extends State<_StorylineChaptersSection> {
                         'Chapitres',
                         style: TextStyle(
                           color: colors.textPrimary,
-                          fontSize: 15,
+                          fontSize: 14.5,
                           fontWeight: FontWeight.w800,
                         ),
                       ),
-                      const SizedBox(height: 6),
+                      const SizedBox(height: 4),
                       Text(
                         'Lecture read-only des chapitres issus de Global Story Studio.',
                         style: TextStyle(
                           color: colors.textSecondary,
-                          fontSize: 12.5,
+                          fontSize: 12,
                           height: 1.35,
                         ),
                       ),
                     ],
                   ),
                 ),
-                const SizedBox(width: 12),
+                const SizedBox(width: 10),
                 const PokeMapButton(
                   key: ValueKey('storylines-chapters-create-action'),
                   onPressed: null,
@@ -1493,7 +1482,7 @@ class _StorylineChaptersSectionState extends State<_StorylineChaptersSection> {
                 ),
               ],
             ),
-            const SizedBox(height: 14),
+            const SizedBox(height: 12),
             Wrap(
               spacing: 10,
               runSpacing: 10,
@@ -1518,7 +1507,7 @@ class _StorylineChaptersSectionState extends State<_StorylineChaptersSection> {
                 ),
               ],
             ),
-            const SizedBox(height: 16),
+            const SizedBox(height: 14),
             if (widget.chapters.isEmpty)
               const _StorylineChaptersEmptyState()
             else
@@ -1546,7 +1535,7 @@ class _StorylineChaptersSectionState extends State<_StorylineChaptersSection> {
                     crossAxisAlignment: CrossAxisAlignment.start,
                     children: [
                       SizedBox(
-                        width: math.min(360, constraints.maxWidth * 0.42),
+                        width: math.min(330, constraints.maxWidth * 0.38),
                         child: list,
                       ),
                       const SizedBox(width: 12),
@@ -1609,7 +1598,7 @@ class _StorylineChapterCard extends StatelessWidget {
     final description = chapter.description.trim();
     final card = PokeMapCard(
       key: ValueKey('storylines-chapter-card-${chapter.id}'),
-      padding: const EdgeInsets.all(14),
+      padding: const EdgeInsets.all(12),
       selected: selected,
       onTap: onTap,
       child: Column(
@@ -1621,10 +1610,10 @@ class _StorylineChapterCard extends StatelessWidget {
               const PokeMapIconTile(
                 icon: CupertinoIcons.book,
                 tone: PokeMapTone.narrative,
-                size: 34,
-                iconSize: 16,
+                size: 30,
+                iconSize: 14,
               ),
-              const SizedBox(width: 12),
+              const SizedBox(width: 10),
               Expanded(
                 child: Column(
                   crossAxisAlignment: CrossAxisAlignment.start,
@@ -1644,16 +1633,16 @@ class _StorylineChapterCard extends StatelessWidget {
                       overflow: TextOverflow.ellipsis,
                       style: TextStyle(
                         color: colors.textPrimary,
-                        fontSize: 14,
+                        fontSize: 13.5,
                         fontWeight: FontWeight.w800,
                       ),
                     ),
-                    const SizedBox(height: 6),
+                    const SizedBox(height: 5),
                     Text(
                       description.isEmpty
                           ? 'Description de chapitre non renseignée.'
                           : description,
-                      maxLines: 3,
+                      maxLines: 2,
                       overflow: TextOverflow.ellipsis,
                       style: TextStyle(
                         color: colors.textSecondary,
@@ -1667,10 +1656,10 @@ class _StorylineChapterCard extends StatelessWidget {
               ),
             ],
           ),
-          const SizedBox(height: 12),
+          const SizedBox(height: 10),
           Wrap(
-            spacing: 10,
-            runSpacing: 10,
+            spacing: 8,
+            runSpacing: 8,
             children: [
               PokeMapStatusTile(
                 label: 'Étapes narratives liées',
@@ -1731,7 +1720,7 @@ class _StorylineChapterInspector extends StatelessWidget {
     final description = selectedChapter.description.trim();
     return PokeMapCard(
       key: const ValueKey('storylines-chapter-inspector'),
-      padding: const EdgeInsets.all(16),
+      padding: const EdgeInsets.all(14),
       selected: true,
       child: Column(
         crossAxisAlignment: CrossAxisAlignment.stretch,
@@ -1742,10 +1731,10 @@ class _StorylineChapterInspector extends StatelessWidget {
               const PokeMapIconTile(
                 icon: CupertinoIcons.book_fill,
                 tone: PokeMapTone.narrative,
-                size: 38,
-                iconSize: 18,
+                size: 34,
+                iconSize: 16,
               ),
-              const SizedBox(width: 12),
+              const SizedBox(width: 10),
               Expanded(
                 child: Column(
                   crossAxisAlignment: CrossAxisAlignment.start,
@@ -1765,16 +1754,16 @@ class _StorylineChapterInspector extends StatelessWidget {
                       overflow: TextOverflow.ellipsis,
                       style: TextStyle(
                         color: colors.textPrimary,
-                        fontSize: 15,
+                        fontSize: 14.5,
                         fontWeight: FontWeight.w800,
                       ),
                     ),
-                    const SizedBox(height: 6),
+                    const SizedBox(height: 5),
                     Text(
                       description.isEmpty
                           ? 'Description de chapitre non renseignée.'
                           : description,
-                      maxLines: 4,
+                      maxLines: 3,
                       overflow: TextOverflow.ellipsis,
                       style: TextStyle(
                         color: colors.textSecondary,
@@ -1788,10 +1777,10 @@ class _StorylineChapterInspector extends StatelessWidget {
               ),
             ],
           ),
-          const SizedBox(height: 14),
+          const SizedBox(height: 12),
           Wrap(
-            spacing: 10,
-            runSpacing: 10,
+            spacing: 8,
+            runSpacing: 8,
             children: [
               PokeMapStatusTile(
                 label: 'Ordre',
@@ -1823,7 +1812,7 @@ class _StorylineChapterInspector extends StatelessWidget {
               ),
             ],
           ),
-          const SizedBox(height: 16),
+          const SizedBox(height: 14),
           Text(
             'Étapes narratives du chapitre',
             style: TextStyle(
@@ -1842,13 +1831,13 @@ class _StorylineChapterInspector extends StatelessWidget {
               fontWeight: FontWeight.w600,
             ),
           ),
-          const SizedBox(height: 10),
+          const SizedBox(height: 8),
           _StorylineChapterStepOrderList(steps: selectedChapter.steps),
           if (selectedChapter.missingStepIds.isNotEmpty) ...[
-            const SizedBox(height: 16),
+            const SizedBox(height: 14),
             _StorylineMissingStepIds(ids: selectedChapter.missingStepIds),
           ],
-          const SizedBox(height: 16),
+          const SizedBox(height: 14),
           const PokeMapStatusTile(
             label: 'Données à venir',
             value: 'Modèle détaillé non branché',
@@ -1890,7 +1879,7 @@ class _StorylineChapterStepOrderList extends StatelessWidget {
             index: index,
             step: steps[index],
           ),
-          if (index != steps.length - 1) const SizedBox(height: 8),
+          if (index != steps.length - 1) const SizedBox(height: 7),
         ],
       ],
     );
@@ -1914,28 +1903,54 @@ class _StorylineChapterStepOrderRow extends StatelessWidget {
       key: ValueKey('storylines-chapter-step-order-${step.id}'),
       crossAxisAlignment: CrossAxisAlignment.start,
       children: [
-        PokeMapStatusTile(
-          label: order,
-          value: 'Étape narrative',
-          icon: CupertinoIcons.line_horizontal_3_decrease,
-          tone: PokeMapTone.info,
+        SizedBox(
+          width: 34,
+          height: 34,
+          child: DecoratedBox(
+            decoration: BoxDecoration(
+              color: colors.surfaceSubtle,
+              borderRadius: BorderRadius.circular(8),
+              border: Border.all(color: colors.borderSubtle),
+            ),
+            child: Center(
+              child: Text(
+                order,
+                style: TextStyle(
+                  color: colors.textPrimary,
+                  fontSize: 11,
+                  fontWeight: FontWeight.w800,
+                ),
+              ),
+            ),
+          ),
         ),
-        const SizedBox(width: 10),
+        const SizedBox(width: 9),
         Expanded(
           child: Column(
             crossAxisAlignment: CrossAxisAlignment.start,
             children: [
+              Text(
+                'Étape narrative',
+                maxLines: 1,
+                overflow: TextOverflow.ellipsis,
+                style: TextStyle(
+                  color: colors.textMuted,
+                  fontSize: 10,
+                  fontWeight: FontWeight.w700,
+                ),
+              ),
+              const SizedBox(height: 2),
               Text(
                 step.name,
                 maxLines: 1,
                 overflow: TextOverflow.ellipsis,
                 style: TextStyle(
                   color: colors.textPrimary,
-                  fontSize: 12.5,
+                  fontSize: 12.3,
                   fontWeight: FontWeight.w800,
                 ),
               ),
-              const SizedBox(height: 3),
+              const SizedBox(height: 2),
               Text(
                 step.description.trim().isEmpty
                     ? 'Description d’étape narrative non renseignée.'
@@ -1944,8 +1959,8 @@ class _StorylineChapterStepOrderRow extends StatelessWidget {
                 overflow: TextOverflow.ellipsis,
                 style: TextStyle(
                   color: colors.textSecondary,
-                  fontSize: 11.5,
-                  height: 1.3,
+                  fontSize: 11,
+                  height: 1.25,
                   fontWeight: FontWeight.w500,
                 ),
               ),
```

Diff complet de `packages/map_editor/test/storylines_workspace_shell_test.dart` :

```diff
diff --git a/packages/map_editor/test/storylines_workspace_shell_test.dart b/packages/map_editor/test/storylines_workspace_shell_test.dart
index c6c9673c..bd9485ce 100644
--- a/packages/map_editor/test/storylines_workspace_shell_test.dart
+++ b/packages/map_editor/test/storylines_workspace_shell_test.dart
@@ -14,7 +14,7 @@ import 'package:map_editor/src/ui/canvas/narrative_workspace_canvas.dart';
 import 'package:map_editor/src/ui/design_system/design_system.dart';
 
 void main() {
-  group('NS-STORYLINES-09 Chapters inspector / step ordering V0', () {
+  group('NS-STORYLINES-10 Visual harmonization / visual gate V0', () {
     testWidgets(
       'renders a read-only three-pane shell from real global story data',
       (tester) async {
@@ -756,6 +756,42 @@ void main() {
     });
 
     testWidgets('writes Visual Gate screenshots', (tester) async {
+      await _pumpStorylinesShell(
+        tester,
+        surfaceSize: const Size(1600, 1000),
+      );
+      await expectLater(
+        find.byKey(const ValueKey('storylines-workspace-shell')),
+        matchesGoldenFile(
+          '../../../reports/narrativeStudio/storylines/screenshots/'
+          'ns_storylines_10_graph_desktop.png',
+        ),
+      );
+
+      await _pumpStorylinesShell(
+        tester,
+        surfaceSize: const Size(1600, 700),
+      );
+      await expectLater(
+        find.byKey(const ValueKey('storylines-graph-target-read-only')),
+        matchesGoldenFile(
+          '../../../reports/narrativeStudio/storylines/screenshots/'
+          'ns_storylines_10_graph_focus.png',
+        ),
+      );
+
+      await _pumpStorylinesShell(
+        tester,
+        surfaceSize: const Size(1180, 1000),
+      );
+      await expectLater(
+        find.byKey(const ValueKey('storylines-graph-target-read-only')),
+        matchesGoldenFile(
+          '../../../reports/narrativeStudio/storylines/screenshots/'
+          'ns_storylines_10_graph_center.png',
+        ),
+      );
+
       await _pumpStorylinesShell(
         tester,
         surfaceSize: const Size(1600, 1000),
@@ -765,7 +801,7 @@ void main() {
         find.byKey(const ValueKey('storylines-workspace-shell')),
         matchesGoldenFile(
           '../../../reports/narrativeStudio/storylines/screenshots/'
-          'ns_storylines_09_chapter_inspector_desktop.png',
+          'ns_storylines_10_chapters_desktop.png',
         ),
       );
 
@@ -778,7 +814,7 @@ void main() {
         find.byKey(const ValueKey('storylines-chapters-read-only')),
         matchesGoldenFile(
           '../../../reports/narrativeStudio/storylines/screenshots/'
-          'ns_storylines_09_chapter_inspector_focus.png',
+          'ns_storylines_10_chapters_focus.png',
         ),
       );
 
@@ -791,7 +827,7 @@ void main() {
         find.byKey(const ValueKey('storylines-chapters-read-only')),
         matchesGoldenFile(
           '../../../reports/narrativeStudio/storylines/screenshots/'
-          'ns_storylines_09_chapter_inspector_center.png',
+          'ns_storylines_10_chapters_center.png',
         ),
       );
     });
@@ -799,7 +835,11 @@ void main() {
 }
 
 const _targetOnlyStrings = <String>[
+  'Histoire globale',
   'La brume du phare',
+  'Le port',
+  'Les marais',
+  'Le phare',
   'Les cristaux de sel',
   'Le Goélise du port',
   'La cabane du phare',
@@ -831,6 +871,8 @@ const _targetOnlyStrings = <String>[
   '12 dialogues',
   'Prête',
   'Quête annexe',
+  'Fin de l’histoire',
+  'Conclusion',
 ];
 
 Future<void> _openChaptersTab(WidgetTester tester) async {
```

Diff complet de `reports/narrativeStudio/storylines/road_map_storylines.md` :

```diff
diff --git a/reports/narrativeStudio/storylines/road_map_storylines.md b/reports/narrativeStudio/storylines/road_map_storylines.md
index 327a194f..50c4adb8 100644
--- a/reports/narrativeStudio/storylines/road_map_storylines.md
+++ b/reports/narrativeStudio/storylines/road_map_storylines.md
@@ -298,7 +298,7 @@ Interprétation V0 :
 | NS-STORYLINES-07 | Storyline Inspector Read-only V0 | editor UI | DONE | NS-STORYLINES-08 |
 | NS-STORYLINES-08 | Chapters Tab Read-only V0 | editor UI | DONE | NS-STORYLINES-09 |
 | NS-STORYLINES-09 | Chapters Inspector / Step Ordering Read-only V0 | editor UI | DONE | NS-STORYLINES-10 |
-| NS-STORYLINES-10 | Storyline Visual Harmonization / Visual Gate V0 | visual gate | TODO | NS-STORYLINES-11 |
+| NS-STORYLINES-10 | Storyline Visual Harmonization / Visual Gate V0 | visual gate | DONE | NS-STORYLINES-11 |
 | NS-STORYLINES-11 | Storylines Interaction Wiring V0 | editor UI / test | TODO | NS-STORYLINES-CHECKPOINT |
 | NS-STORYLINES-CHECKPOINT | Storylines V0 Acceptance Checkpoint | checkpoint | TODO | TBD |
 
@@ -556,16 +556,16 @@ Interprétation V0 :
 
 - Type : visual gate.
 - Objectif : harmoniser contre les deux cibles sans ajouter de feature.
-- Fichiers probables : widgets Storylines existants, rapport, screenshots.
+- Fichiers modifiés/créés : `packages/map_editor/lib/src/ui/canvas/storylines_workspace.dart`, `packages/map_editor/test/storylines_workspace_shell_test.dart`, `reports/narrativeStudio/storylines/road_map_storylines.md`, `reports/narrativeStudio/storylines/ns_storylines_10_visual_harmonization_visual_gate_v0.md`, captures Visual Gate NS10.
 - Non-objectifs : pas de donnée fake, pas de pixel-perfect.
 - Dépendances : NS-STORYLINES-09.
-- Critères d'acceptation : Visual Gate complet, comparaison honnête, disabled states lisibles.
-- Tests attendus : régression UI/storylines, tests design-system si tokens/surfaces touchés.
-- Analyse attendue : `flutter analyze`, `git diff --check`.
-- Visual Gate : Graph desktop, Graph focus, Chapters desktop, medium.
-- Risques : polir au lieu de corriger une source manquante.
-- Design system impact : très fort ; mini audit obligatoire.
-- Statut : TODO.
+- Résumé : harmonisation visuelle V0 du graph et de la tab Chapitres, avec canvas plus dominant, nodes plus compacts, edges plus lisibles, légende/contrôles plus discrets et rows d'étapes plus denses.
+- Tests exécutés : `flutter test test/storylines_workspace_shell_test.dart`, `flutter test test/storylines_current_global_story_characterization_test.dart`, `flutter test test/narrative_workspace_projection_test.dart`.
+- Analyse exécutée : `flutter analyze --no-fatal-infos lib/src/ui/canvas/storylines_workspace.dart test/storylines_workspace_shell_test.dart test/storylines_current_global_story_characterization_test.dart test/narrative_workspace_projection_test.dart`.
+- Visual Gate : captures Graph et Chapitres desktop/focus/center produites en dark theme.
+- Design System Gate : confirmé ; aucun `Color(0x...)` / `Colors.*` ajouté ; couleurs via tokens / primitives PokeMap.
+- Fake data : aucune donnée cible Selbrume, aucune quête annexe, aucun tag/world rule/fact/activité, aucune action future activée.
+- Statut : DONE.
 - Prochain lot attendu : NS-STORYLINES-11.
 
 ### NS-STORYLINES-11 — Storylines Interaction Wiring V0
@@ -717,9 +717,9 @@ Décision temporaire :
 
 ```text
 Roadmap status: ACTIVE
-Current lot: NS-STORYLINES-09
+Current lot: NS-STORYLINES-10
 Current lot status: DONE
-Next recommended lot: NS-STORYLINES-10 — Storyline Visual Harmonization / Visual Gate V0
+Next recommended lot: NS-STORYLINES-11 — Storylines Interaction Wiring V0
 ```
 
 | Lot | Status | Last update | Notes |
@@ -735,12 +735,22 @@ Next recommended lot: NS-STORYLINES-10 — Storyline Visual Harmonization / Visu
 | NS-STORYLINES-07 | DONE | 2026-05-28 | Inspector read-only livré avec données réelles, sections futures disabled et empty state. |
 | NS-STORYLINES-08 | DONE | 2026-05-28 | Onglet Chapitres read-only livré ; bis Graph target alignment et ter canvas spatial livrés sans changer le statut NS08. |
 | NS-STORYLINES-09 | DONE | 2026-05-28 | Chapters inspector / step ordering read-only livré sans scène fake. |
-| NS-STORYLINES-10 | TODO | 2026-05-27 | Visual harmonization. |
+| NS-STORYLINES-10 | DONE | 2026-05-28 | Visual harmonization Graph/Chapitres et Visual Gate complet livrés sans nouvelle feature. |
 | NS-STORYLINES-11 | TODO | 2026-05-27 | Interaction wiring. |
 | NS-STORYLINES-CHECKPOINT | TODO | 2026-05-27 | Acceptance checkpoint. |
 
 ## 14. Changelog
 
+### 2026-05-28 — NS-STORYLINES-10
+
+- Harmonisation visuelle V0 du workspace Storylines sans ajout de feature métier.
+- Vue `Graph` : canvas plus dominant, header plus compact, nodes plus compacts, edge layer plus lisible, légende et contrôles read-only plus discrets.
+- Vue `Chapitres` : proportion liste/inspecteur stabilisée, cards de chapitres et rows d'étapes narratives compactées, inspecteur chapitre mieux équilibré.
+- Visual Gate dark complet produit : `ns_storylines_10_graph_desktop.png`, `ns_storylines_10_graph_focus.png`, `ns_storylines_10_graph_center.png`, `ns_storylines_10_chapters_desktop.png`, `ns_storylines_10_chapters_focus.png`, `ns_storylines_10_chapters_center.png`.
+- Design System Gate confirmé : aucun `Color(0x...)` / `Colors.*` ajouté ; harmonisation via primitives PokeMap et `context.pokeMapColors`.
+- Fake data : aucune donnée cible Selbrume, aucun tag/world rule/fact/activité, aucune quête annexe fake, aucune action future activée.
+- Prochain lot recommandé : `NS-STORYLINES-11 — Storylines Interaction Wiring V0`.
+
 ### 2026-05-28 — NS-STORYLINES-09
 
 - Livraison de l'onglet `Chapitres` avec sélection locale de chapitre : premier chapitre réel sélectionné par défaut, clic sur un autre chapitre limité à l'état UI local.
```

## 16. Self-review

Auto-review critique :

- Le lot reste une harmonisation visuelle : aucune donnée, modèle, provider ou feature métier ajouté.
- Graph : la vue est plus dense et plus proche d'un canvas dominant, sans inventer de branches.
- Chapitres : la vue est plus lisible en liste/inspecteur, sans `Scènes du chapitre`.
- Les strings interdites sont mieux couvertes par test.
- Les screenshots Graph et Chapitres NS10 couvrent desktop/focus/center.
- Limite : l'image cible Chapitres n'était pas attachée comme fichier distinct dans ce tour ; la passe Chapitres suit donc la description cible et l'état NS09, pas une comparaison pixel à pixel.
- Prochain risque : NS11 doit rester strictement interaction wiring, sans transformer les contrôles disabled en actions métier sans source.
