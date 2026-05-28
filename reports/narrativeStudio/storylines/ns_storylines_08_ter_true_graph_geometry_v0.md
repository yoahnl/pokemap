# NS-STORYLINES-08-ter — True Graph Geometry / Spatial Canvas V0

## 1. Executive summary

NS-STORYLINES-08-ter transforme l'onglet `Graph` par défaut en canvas spatial read-only : nodes positionnés dans un `Stack`, layer d'edges visible via `CustomPainter`, grille dark conservée, légende compacte et contrôles explicitement non actifs.

Le lot ne change aucune donnée métier. Les nodes restent sourcés par `NarrativeChapterSummary` et `NarrativeStepSummary`. L'image cible a été utilisée comme référence de composition et de layout uniquement, jamais comme source de données.

## 2. Inputs read

Fichiers lus :
- `AGENTS.md`
- `agent_rules.md`
- `skills/README.md`
- `reports/narrativeStudio/storylines/road_map_storylines.md`
- `reports/narrativeStudio/storylines/ns_storylines_08_bis_graph_tab_target_alignment_v0.md`
- `reports/narrativeStudio/storylines/ns_storylines_08_chapters_tab_read_only_v0.md`
- `reports/narrativeStudio/storylines/ns_storylines_07_inspector_read_only_v0.md`
- `reports/narrativeStudio/storylines/ns_storylines_06_graph_read_only_placeholder_v0.md`
- `reports/narrativeStudio/storylines/ns_storylines_05_header_tabs_kpi_read_only_v0.md`
- `packages/map_editor/lib/src/ui/canvas/storylines_workspace.dart`
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
- `packages/map_editor/lib/src/ui/shared/cupertino_editor_widgets.dart`
- `packages/map_editor/lib/src/ui/shared/editor_visual_tokens.dart`

Fichiers absents mais attendus : aucun.

Skills lus :
- `superpowers:test-driven-development`
- `superpowers:verification-before-completion`

## 3. Visual issue summary

Le lot 08-bis avait introduit un canvas et des nodes, mais le rendu reposait encore sur un `Wrap` de widgets avec connecteurs iconographiques. Le résultat restait proche d'une succession de cards, sans vraie géométrie spatiale ni layer d'edges.

## 4. Implementation summary

- Remplacement du flux `Wrap` par une couche spatiale `storylines-graph-spatial-layer`.
- Ajout d'une géométrie feature-specific `_StorylineGraphGeometry` qui calcule les positions depuis la taille du canvas et le nombre de nodes.
- Ajout de `_StorylineGraphEdgePainter` pour dessiner les connexions entre nodes.
- Compactage des nodes de chapitre : previews de steps limitées, détails longs gardés pour l'onglet `Chapitres`.
- Légende et contrôles read-only transformés en bande compacte, sans mini-map ni zoom actif.
- Tests Storylines mis à jour avec les clés 08-ter et nouveaux screenshots Visual Gate.

## 5. Graph geometry behavior

Sur desktop large, le flow principal est positionné horizontalement : `Début de lecture` -> chapitres réels -> `Relations à venir`. Pour des données plus denses, la géométrie garde une amplitude verticale prudente afin de produire un canvas spatial sans basculer vers une liste.

Si aucun chapitre n'est disponible, le fallback existant par steps reste read-only. Si aucune step n'est disponible, l'empty state honnête existant reste affiché.

## 6. Edge / connection behavior

Les connexions visibles sont dessinées par `_StorylineGraphEdgePainter`. Elles représentent uniquement une lecture read-only séquentielle du canvas, pas des relations métier finales. Aucune branche conditionnelle, quête annexe, relation optionnelle, mini-map ou zoom actif n'a été ajouté.

Les couleurs du painter viennent de `context.pokeMapColors` :
- `colors.textMuted.withValues(alpha: 0.58)`
- `colors.brandPrimaryBorder.withValues(alpha: 0.78)`

## 7. Data source / anti-fake guarantees

Données affichées :
- `NarrativeChapterSummary.name`
- `NarrativeChapterSummary.order`
- `NarrativeChapterSummary.steps`
- `NarrativeStepSummary.name`
- `NarrativeStepSummary.description`

Données explicitement non ajoutées :
- aucune quête annexe fake ;
- aucun nom ou chiffre Selbrume cible ;
- aucun tag fake ;
- aucune world rule fake ;
- aucun fact fake ;
- aucune activité récente fake ;
- aucun `localEventFlow` dans le graph.

## 8. Disabled interactions

Le graph reste strictement read-only :
- pas de création ;
- pas d'édition ;
- pas de drag/drop ;
- pas d'édition de node ou edge ;
- pas de zoom actif ;
- pas de mini-map active ;
- pas de mutation projet.

## 9. Design System Gate

Design System Gate respecté :
- primitives PokeMap conservées : `PokeMapPageSurface`, `PokeMapCard`, `PokeMapIconTile`, `PokeMapStatusTile`, `PokeMapTone` ;
- tokens via `context.pokeMapColors` ;
- aucun `Color(0x...)` ou `Colors.*` ajouté ;
- aucun composant générique local hors design system créé ;
- les composants ajoutés sont feature-specific : `_StorylineGraphGeometry`, `_StorylineGraphNodePosition`, `_StorylineGraphEdge`, `_StorylineGraphEdgePainter`, `_StorylineGraphLegendItem`.

Recherche couleurs :

```text
Commande :
rg "Color\(0x|Colors\." packages/map_editor/lib/src/ui/canvas/storylines_workspace.dart packages/map_editor/test/storylines_workspace_shell_test.dart packages/map_editor/test/narrative_workspace_projection_test.dart packages/map_editor/test/storylines_current_global_story_characterization_test.dart || true

Sortie : <vide>
```

## 10. Tests added or modified

Fichier modifié :
- `packages/map_editor/test/storylines_workspace_shell_test.dart`

Assertions ajoutées ou durcies :
- `storylines-graph-spatial-layer`
- `storylines-graph-edge-layer`
- `storylines-graph-node-start`
- `storylines-graph-node-audit_chapter`
- `storylines-graph-node-audit_second_chapter`
- `storylines-graph-node-read-only-note`
- nouveaux chemins Visual Gate 08-ter.

## 11. Visual Gate

Captures générées :
- `reports/narrativeStudio/storylines/screenshots/ns_storylines_08_ter_true_graph_desktop.png`
- `reports/narrativeStudio/storylines/screenshots/ns_storylines_08_ter_true_graph_focus.png`
- `reports/narrativeStudio/storylines/screenshots/ns_storylines_08_ter_true_graph_center.png`

Résultat Visual Gate :
- dark theme actif ;
- graph vue par défaut ;
- canvas graph dominant ;
- nodes positionnés dans l'espace ;
- edge layer présent ;
- panneau secondaire, header/tabs/KPI, onglet Chapitres et inspecteur conservés ;
- pas d'overflow après compactage de la légende ;
- pas de fake data.

## 12. Roadmap update

`reports/narrativeStudio/storylines/road_map_storylines.md` a été mis à jour :
- `NS-STORYLINES-08` reste `DONE` ;
- ajout du détail `NS-STORYLINES-08-ter` ;
- ajout d'une entrée changelog 2026-05-28 ;
- prochain lot recommandé inchangé : `NS-STORYLINES-09 — Chapters Inspector / Scene Ordering Read-only V0`.

## 13. Commands run

```text
git branch --show-current
Sortie :
main
```

```text
git status --short --untracked-files=all
Sortie initiale : <vide>
```

```text
git diff --stat
Sortie initiale : <vide>
```

```text
git diff --name-only
Sortie initiale : <vide>
```

```text
git diff --check
Sortie initiale : <vide>
```

```text
cd packages/map_editor && flutter test test/storylines_workspace_shell_test.dart
Sortie RED attendue :
Expected: exactly one matching candidate
Actual: _KeyWidgetFinder:<Found 0 widgets with key [<'storylines-graph-spatial-layer'>]: []>
```

```text
cd packages/map_editor && flutter test --update-goldens test/storylines_workspace_shell_test.dart
Sortie finale :
00:01 +11: All tests passed!
```

```text
cd packages/map_editor && flutter test test/storylines_workspace_shell_test.dart
Sortie finale :
00:01 +11: All tests passed!
```

```text
cd packages/map_editor && flutter test test/storylines_current_global_story_characterization_test.dart
Sortie finale :
00:00 +2: All tests passed!
```

```text
cd packages/map_editor && flutter test test/narrative_workspace_projection_test.dart
Sortie finale :
00:00 +3: All tests passed!
```

```text
cd packages/map_editor && flutter analyze --no-fatal-infos lib/src/ui/canvas/storylines_workspace.dart test/storylines_workspace_shell_test.dart test/storylines_current_global_story_characterization_test.dart test/narrative_workspace_projection_test.dart
Sortie :
Analyzing 4 items...
No issues found! (ran in 8.2s)
```

```text
git diff --check
Sortie finale avant rapport : <vide>
```

## 14. Evidence Pack

Git initial :

```text
Branche initiale :
main

Status initial exact :
Sortie : <vide>

Diff stat initial :
Sortie : <vide>

Diff name-only initial :
Sortie : <vide>

Diff check initial :
Sortie : <vide>
```

Git final exact après création de ce rapport :

```text
 M packages/map_editor/lib/src/ui/canvas/storylines_workspace.dart
 M packages/map_editor/test/storylines_workspace_shell_test.dart
 M reports/narrativeStudio/storylines/road_map_storylines.md
?? reports/narrativeStudio/storylines/ns_storylines_08_ter_true_graph_geometry_v0.md
?? reports/narrativeStudio/storylines/screenshots/ns_storylines_08_ter_true_graph_center.png
?? reports/narrativeStudio/storylines/screenshots/ns_storylines_08_ter_true_graph_desktop.png
?? reports/narrativeStudio/storylines/screenshots/ns_storylines_08_ter_true_graph_focus.png
```

Diff stat final exact :

```text
 packages/map_editor/lib/src/ui/canvas/storylines_workspace.dart | 604 +++++++++++++++------
 packages/map_editor/test/storylines_workspace_shell_test.dart   |  24 +-
 reports/narrativeStudio/storylines/road_map_storylines.md       |  29 +-
 3 files changed, 475 insertions(+), 182 deletions(-)
```

Diff name-only final exact :

```text
packages/map_editor/lib/src/ui/canvas/storylines_workspace.dart
packages/map_editor/test/storylines_workspace_shell_test.dart
reports/narrativeStudio/storylines/road_map_storylines.md
```

Diff check final exact :

```text
Sortie : <vide>
```

Contenu complet des fichiers créés :
- `reports/narrativeStudio/storylines/ns_storylines_08_ter_true_graph_geometry_v0.md` : présent document.
- screenshots Visual Gate PNG listés en section 11.

Résumé du diff complet des fichiers modifiés :
- `storylines_workspace.dart` : remplacement du flow `Wrap` par canvas spatial, ajout géométrie, edge painter, nodes compacts, légende compacte.
- `storylines_workspace_shell_test.dart` : groupe renommé 08-ter, clés spatiales/edges ajoutées, chemins de screenshots 08-ter.
- `road_map_storylines.md` : note détaillée 08-ter, statut courant et changelog mis à jour.

Artefacts nettoyés :
- les fichiers `packages/map_editor/test/failures/ns_storylines_08_ter_true_graph_*.png` générés par un mismatch golden intermédiaire ont été supprimés.
- `.idea/libraries/Dart_Packages.xml` et `packages/map_editor/pubspec.lock` ont été restaurés à leur état initial après mutation automatique par l'outillage Flutter.

Mini audit Design System :
- aucun token local ajouté ;
- aucun `Color(0x...)` ;
- aucun `Colors.*` ;
- edge painter alimenté par `context.pokeMapColors` ;
- composants graph limités au feature scope Storylines.

## 15. Self-review

Points validés :
- Graph reste la vue par défaut.
- Canvas spatial et edge layer existent.
- Nodes de chapitres réels et previews de steps réelles visibles.
- Onglet `Chapitres` NS08 conservé.
- Actions et tabs futures restent non mutantes via tests existants.
- Maps reste absent de la sidebar interne.
- Tests ciblés et analyse ciblée passent.

Limite assumée :
- Les screenshots Flutter gardent la police de test Ahem ; ils prouvent structure, thème, densité et absence d'overflow, pas la typographie finale.
