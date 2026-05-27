# NS-HOME-21 - Narrative Studio Visual Harmonization Against Target V0

## 1. Résumé exécutif

NS-HOME-21 harmonise visuellement l'écran `Narrative Studio / Aperçu` sans ajouter de nouvelle fonctionnalité métier.

Le travail réalisé reste volontairement dans le polish :

- `NarrativeStudioShell` est plus compact entre la sidebar interne et la zone principale.
- `NarrativeStudioSidebar` est un peu plus lisible, avec un état actif plus net et des entrées disabled toujours non fonctionnelles.
- `NarrativeStudioHeader` est moins massif et mieux intégré au shell interne.
- les KPI tiennent désormais en une ligne sur le desktop avec Project Explorer réduit, tout en évitant l'overflow.
- la carte Histoire principale, les modules et Structure narrative ont été légèrement densifiés.
- les screenshots Visual Gate NS-HOME-21 ont été produits.

Aucune destination future n'a été activée. `Maps` n'a pas été réintroduit. `Facts`, `Règles du monde` et `Validateur` restent disabled. `ProjectExplorerPanel` n'a pas été modifié et reste global.

## 2. Rappel du scope NS-HOME-21

Objectif du lot :

```text
Harmoniser visuellement la page Narrative Studio / Aperçu contre l'image cible,
maintenant que l'architecture est correcte :
Project Explorer global réduit,
NarrativeStudioSidebar interne,
NarrativeStudioHeader interne,
dashboard Aperçu,
Structure narrative,
actions V0 honnêtes.
```

Non-objectifs respectés :

- pas de nouvelle storyline ;
- pas de validation globale active ;
- pas de recherche narrative active ;
- pas de notifications inventées ;
- pas de badge notification fake ;
- pas de `Maps` dans la sidebar interne ;
- pas de données cible hardcodées ;
- pas de modification de `ProjectExplorerPanel` ;
- pas de modification de read model ;
- pas de modification `map_core`, runtime, gameplay ou battle.

## 3. Analyse visuelle de l'état NS-HOME-20

L'état NS-HOME-20 était techniquement sain, mais encore un peu "assemblage de couches" :

- le Project Explorer réduit fonctionnait ;
- la sidebar interne était bien distincte ;
- le header interne existait ;
- le dashboard était honnête et interactif ;
- mais la densité restait perfectible entre le header, le breadcrumb, le bloc Projet et les KPI ;
- les KPI passaient encore sur deux lignes dans le desktop réduit, ce qui éloignait l'écran de l'image cible ;
- les rayons, paddings et bordures n'étaient pas encore totalement cohérents entre shell, sidebar, header, cards et inspector.

## 4. Écarts avec l'image cible

Ce qui se rapproche :

- navigation interne verticale dédiée au Narrative Studio ;
- header d'actions narratives dans la zone Narrative Studio ;
- Project Explorer global réduit ;
- dashboard auteur avec KPI, Histoire principale, modules et Structure narrative ;
- dark mode cohérent ;
- panneau Structure narrative à droite sur desktop large.

Ce qui reste différent :

- la top toolbar globale PokeMap n'est pas reconstruite dans ce lot ;
- le Project Explorer reste visible en rail réduit, alors que l'image cible ne montre pas ce rail global ;
- les fixtures de test restent génériques (`test_project`, zéros, états non évalués) au lieu des données visuelles de la cible ;
- les actions futures sont disabled, contrairement à l'image cible qui les montre comme des actions finales ;
- les fonts des golden tests restent partiellement remplacées par des rectangles dans certains textes, limitation connue de la méthode de screenshot.

## 5. Fichiers créés / modifiés

Fichiers modifiés :

- `packages/map_editor/lib/src/ui/canvas/narrative_studio_shell.dart`
- `packages/map_editor/lib/src/ui/canvas/narrative_studio_sidebar.dart`
- `packages/map_editor/lib/src/ui/canvas/narrative_studio_header.dart`
- `packages/map_editor/lib/src/ui/canvas/narrative_overview_workspace.dart`
- `packages/map_editor/lib/src/ui/canvas/narrative_overview_structure_inspector.dart`
- `packages/map_editor/test/ui/canvas/narrative_overview_shell_navigation_test.dart`

Fichiers créés :

- `reports/narrativeStudio/ui/ns_home_21_narrative_studio_visual_harmonization.md`
- `reports/narrativeStudio/ui/screenshots/ns_home_21_visual_harmonization_desktop.png`
- `reports/narrativeStudio/ui/screenshots/ns_home_21_visual_harmonization_focus.png`
- `reports/narrativeStudio/ui/screenshots/ns_home_21_visual_harmonization_medium.png`
- `reports/narrativeStudio/ui/screenshots/ns_home_21_visual_harmonization_against_target.png`

Aucun fichier Dart nouveau n'a été créé.

## 6. Harmonisation réalisée

### Shell interne

Le shell interne consomme moins d'espace entre la sidebar et le contenu :

```dart
SizedBox(width: compactSidebar ? 7 : 8),
...
const SizedBox(height: 7),
```

### Sidebar interne

La sidebar interne gagne un peu en largeur utile et un actif plus lisible :

```dart
width: compact ? 136 : 164,
borderRadius: BorderRadius.circular(12),
padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 9),
...
final borderColor = selected
    ? EditorChrome.inspectorJoyCyan.withValues(alpha: 0.82)
    : _NarrativeSidebarColors.itemBorder;
final fill = selected
    ? EditorChrome.inspectorJoyCyan.withValues(alpha: 0.18)
    : _enabled
        ? _NarrativeSidebarColors.itemFill
        : _NarrativeSidebarColors.disabledFill;
```

Les entrées restent :

- actives : `Aperçu`, `Storylines`, `Scènes`, `Cinématiques`, `Dialogues` ;
- disabled : `Facts`, `Règles du monde`, `Validateur` ;
- absente : `Maps`.

### Header interne

Le header est plus léger et s'intègre mieux à la zone Narrative Studio :

```dart
padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
decoration: BoxDecoration(
  color: const Color(0xFF102033).withValues(alpha: 0.58),
  borderRadius: BorderRadius.circular(12),
  border: Border.all(
    color: EditorChrome.activeAccent(context).withValues(alpha: 0.3),
  ),
),
```

Les actions restent honnêtes :

- `Aperçu` est la seule action réelle ;
- `Nouvelle storyline`, `Valider`, `Recherche`, `Notifications`, `Paramètres` restent disabled ;
- aucun badge notification n'est rendu.

### Overview et KPI

Le haut du dashboard est plus dense :

```dart
padding: const EdgeInsets.fromLTRB(18, 6, 18, 18),
...
const SizedBox(height: 7),
```

Les KPI peuvent tenir en six colonnes dès que la largeur utile le permet :

```dart
final columns = switch (maxWidth) {
  >= 900 => 6,
  >= 640 => 3,
  _ => 2,
};
...
height: 130,
```

Note d'auto-correction : une première hauteur à `116` a provoqué un overflow sur `Quêtes` et `Problèmes ouverts`. La hauteur a été remontée à `130`, ce qui conserve la densité tout en supprimant l'overflow.

### Cards et Structure narrative

Les rayons et paddings des modules, de la carte Histoire principale et de Structure narrative ont été légèrement réduits pour mieux aligner les surfaces :

```dart
borderRadius: BorderRadius.circular(14),
padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
```

Le panneau Structure narrative reste strictement alimenté par le read model existant.

## 7. Éléments volontairement non modifiés

- `ProjectExplorerPanel` n'a pas été touché.
- La top toolbar globale n'a pas été reconstruite.
- Le read model n'a pas été modifié.
- Les valeurs métier n'ont pas été modifiées.
- Les workspaces existants ne changent pas de destination.
- `Facts`, `Règles du monde` et `Validateur` restent non actifs.
- Le rail réduit du Project Explorer reste visible : c'est le comportement NS-HOME-19, pas un bug de NS-HOME-21.

## 8. Interactions et disabled states préservés

Les tests confirment que :

- les KPI `Chapitres`, `Scènes`, `Cinématiques`, `Dialogues` restent interactifs ;
- les KPI `Quêtes` et `Problèmes ouverts` ne naviguent pas ;
- les modules `Cinématiques` et `Dialogues` restent interactifs ;
- les modules `Quêtes annexes`, `Conditions narratives`, `Règles du monde`, `Facts` ne naviguent pas ;
- les actions futures du header ne changent pas de workspace ;
- la sidebar interne ne contient pas `Maps` ;
- `ProjectExplorerPanel` reste distinct de `NarrativeStudioSidebar`.

## 9. Ce qui reste volontairement hors scope

- collapse automatique du Project Explorer ;
- sidebar interne finale pixel-perfect ;
- top bar finale complète ;
- création de storyline ;
- validation narrative globale ;
- recherche narrative ;
- centre de notifications ;
- paramètres narratifs ;
- données `Facts` et `World Rules` réelles ;
- changement des fixtures de test vers les données de l'image cible.

## 10. Tests ajoutés / modifiés

Test modifié :

- `packages/map_editor/test/ui/canvas/narrative_overview_shell_navigation_test.dart`

Ajouts principaux :

- test `EditorShellPage keeps the NS-HOME-21 visual harmonization contract` ;
- génération conditionnelle des screenshots NS-HOME-21 ;
- assertions sur Project Explorer réduit, sidebar interne, header interne, KPI, Structure narrative, absence de `Maps`, disabled states et absence de badge notification.

Extrait :

```dart
expect(find.byKey(const ValueKey('project-explorer-reduced')),
    findsOneWidget);
expect(find.byKey(const ValueKey('narrative-studio-sidebar')),
    findsOneWidget);
expect(find.byKey(const ValueKey('narrative-studio-header')),
    findsOneWidget);
expect(find.byKey(const ValueKey('narrative-overview-kpi-grid')),
    findsOneWidget);
expect(
  find.byKey(const ValueKey('narrative-overview-structure-inspector')),
  findsOneWidget,
);
...
expect(kpiGrid.height, lessThanOrEqualTo(130));
```

## 11. Visual Gate

Screenshots produits :

- `reports/narrativeStudio/ui/screenshots/ns_home_21_visual_harmonization_desktop.png`
- `reports/narrativeStudio/ui/screenshots/ns_home_21_visual_harmonization_focus.png`
- `reports/narrativeStudio/ui/screenshots/ns_home_21_visual_harmonization_medium.png`
- `reports/narrativeStudio/ui/screenshots/ns_home_21_visual_harmonization_against_target.png`

Méthode :

- golden tests Flutter avec `--update-goldens` ;
- `EditorShellPage` complet ;
- Project Explorer réduit via `project-explorer-toggle` ;
- fixtures génériques existantes, sans données cible hardcodées.

Analyse du desktop :

- le Project Explorer global est réduit ;
- la sidebar interne est visible et distincte ;
- le header interne est plus discret que NS-HOME-20 ;
- les KPI tiennent en une ligne ;
- la carte Histoire principale et le début des modules sont visibles ;
- Structure narrative reste visible à droite ;
- aucun overflow évident.

Analyse du focus :

- la zone haute montre le header, les actions, le breadcrumb, les KPI et Structure narrative ;
- les actions futures restent visuellement disabled ;
- le rail Project Explorer reste distinct de la sidebar interne ;
- les KPI restent lisibles dans la hauteur réduite.

Analyse du medium :

- la sidebar interne reste lisible ;
- les KPI passent en deux lignes, ce qui est préférable à une compression excessive ;
- le dashboard garde une hiérarchie lisible ;
- Structure narrative reste accessible plus bas dans le scroll.

Analyse against target :

- le fichier reprend le viewport desktop stabilisé pour servir de comparaison directe avec l'image cible ;
- l'écran se rapproche de la cible sur la densité des KPI, la présence de la sidebar interne, le header d'actions et le panneau droit ;
- les écarts restants sont volontaires : rail global réduit, actions futures disabled, données génériques de fixture.

Ce qui a été corrigé après inspection :

- overflow vertical sur les KPI disabled après passage en six colonnes ;
- hauteur KPI remontée à `130` pour garder la densité sans couper le contenu.

## 12. Commandes exécutées

```bash
dart format packages/map_editor/lib/src/ui/canvas/narrative_studio_shell.dart packages/map_editor/lib/src/ui/canvas/narrative_studio_sidebar.dart packages/map_editor/lib/src/ui/canvas/narrative_studio_header.dart packages/map_editor/lib/src/ui/canvas/narrative_overview_workspace.dart packages/map_editor/lib/src/ui/canvas/narrative_overview_structure_inspector.dart packages/map_editor/test/ui/canvas/narrative_overview_shell_navigation_test.dart
cd packages/map_editor && flutter test test/ui/canvas/narrative_overview_shell_navigation_test.dart
cd packages/map_editor && flutter test test/ui/canvas/narrative_overview_workspace_test.dart
cd packages/map_editor && flutter test test/ui/canvas/narrative_overview_shell_navigation_test.dart --update-goldens --dart-define=NS_HOME_21_CAPTURE_VISUAL_DESKTOP=true
cd packages/map_editor && flutter test test/ui/canvas/narrative_overview_shell_navigation_test.dart --update-goldens --dart-define=NS_HOME_21_CAPTURE_VISUAL_FOCUS=true
cd packages/map_editor && flutter test test/ui/canvas/narrative_overview_shell_navigation_test.dart --update-goldens --dart-define=NS_HOME_21_CAPTURE_VISUAL_MEDIUM=true
cd packages/map_editor && flutter test test/ui/canvas/narrative_overview_shell_navigation_test.dart --update-goldens --dart-define=NS_HOME_21_CAPTURE_VISUAL_AGAINST_TARGET=true
cd packages/map_editor && flutter test test/ui/canvas/narrative_studio_header_test.dart
cd packages/map_editor && flutter test test/ui/shell/project_explorer_handoff_test.dart
cd packages/map_editor && flutter test test/top_toolbar_test.dart
cd packages/map_editor && flutter test test/editor_selectors_test.dart
cd packages/map_editor && flutter test test/status_bar_test.dart
cd packages/map_editor && flutter test test/ui/canvas/narrative_overview_workspace_test.dart test/ui/canvas/narrative_overview_shell_navigation_test.dart test/ui/canvas/narrative_studio_header_test.dart test/ui/shell/project_explorer_handoff_test.dart test/top_toolbar_test.dart test/editor_selectors_test.dart test/status_bar_test.dart
cd packages/map_editor && flutter analyze
cd packages/map_editor && flutter analyze --no-fatal-infos lib/src/ui/canvas/narrative_studio_shell.dart lib/src/ui/canvas/narrative_studio_sidebar.dart lib/src/ui/canvas/narrative_studio_header.dart lib/src/ui/canvas/narrative_overview_workspace.dart lib/src/ui/canvas/narrative_overview_structure_inspector.dart test/ui/canvas/narrative_overview_shell_navigation_test.dart
git diff --check
```

## 13. Résultats des tests

### `narrative_overview_shell_navigation_test.dart`

```text
00:00 +0: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/ui/canvas/narrative_overview_shell_navigation_test.dart
00:00 +0: NarrativeWorkspaceCanvas routes overview mode to the overview shell
00:00 +1: NarrativeWorkspaceCanvas renders the internal Narrative Studio shell
00:01 +2: NarrativeWorkspaceCanvas wires overview cards only to real narrative workspaces
00:01 +3: NarrativeLibraryPanel exposes overview without removing existing studios
00:01 +4: EditorShellPage presents coherent Narrative Studio overview chrome
00:02 +5: ProjectExplorerPanel prioritizes narrative navigation in overview mode
00:02 +6: EditorShellPage keeps the NS-HOME-21 visual harmonization contract
00:02 +7: NarrativeOverviewWorkspace captures a full editor shell screenshot when requested
00:02 +8: NarrativeOverviewWorkspace captures NS-HOME-11 sidebar navigation screenshots when requested
00:02 +9: NarrativeOverviewWorkspace captures NS-HOME-12 top bar screenshots when requested
00:02 +10: NarrativeOverviewWorkspace captures NS-HOME-13 breadcrumb header screenshots when requested
00:02 +11: NarrativeOverviewWorkspace captures NS-HOME-14 header density screenshots when requested
00:02 +12: NarrativeOverviewWorkspace captures NS-HOME-16 internal shell screenshots when requested
00:02 +13: NarrativeOverviewWorkspace captures NS-HOME-17 internal sidebar screenshots when requested
00:02 +14: NarrativeOverviewWorkspace captures NS-HOME-18 interaction wiring screenshots when requested
00:02 +15: NarrativeOverviewWorkspace captures NS-HOME-20 internal header screenshots when requested
00:02 +16: NarrativeOverviewWorkspace captures NS-HOME-21 visual harmonization screenshots when requested
00:02 +17: NarrativeOverviewWorkspace captures NS-HOME-10 shell chrome screenshots when requested
00:02 +18: All tests passed!
```

### `narrative_overview_workspace_test.dart`

```text
00:00 +0: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/ui/canvas/narrative_overview_workspace_test.dart
00:00 +0: NarrativeOverviewWorkspace renders a minimal authoring overview from the read model
00:00 +1: NarrativeOverviewWorkspace does not present unavailable modules as real data
00:00 +2: NarrativeOverviewWorkspace renders honest upcoming data states and footer metadata
00:00 +3: NarrativeOverviewWorkspace KPI cards consume read model values
00:01 +4: NarrativeOverviewWorkspace KPI layout renders on a narrower desktop width
00:01 +5: NarrativeOverviewWorkspace keeps KPI cards visible after header density polish
00:01 +6: NarrativeOverviewWorkspace renders an honest empty main story card
00:01 +7: NarrativeOverviewWorkspace renders explicit main story data from the read model
00:01 +8: NarrativeOverviewWorkspace opens Storylines only for explicit main story data
00:01 +9: NarrativeOverviewWorkspace explains missing description and fallback chapters
00:01 +10: NarrativeOverviewWorkspace renders ambiguous main story state explicitly
00:01 +11: NarrativeOverviewWorkspace renders honest narrative module cards
00:02 +12: NarrativeOverviewWorkspace module cards consume read model values
00:02 +13: NarrativeOverviewWorkspace module grid keeps previous overview blocks visible
00:02 +14: NarrativeOverviewWorkspace renders an honest structure inspector panel
00:02 +15: NarrativeOverviewWorkspace structure inspector consumes read model counters and chapters
00:02 +16: NarrativeOverviewWorkspace structure inspector shows clean validation as up to date
00:02 +17: NarrativeOverviewWorkspace structure inspector maps warnings to review state
00:02 +18: NarrativeOverviewWorkspace structure inspector maps errors to blocking state
00:02 +19: NarrativeOverviewWorkspace keeps the structure inspector beside the main column on large desktop
00:02 +20: NarrativeOverviewWorkspace stacks the structure inspector after the main column on medium desktop
00:03 +21: NarrativeOverviewWorkspace keeps V0 unavailable data honest after responsive polish
00:03 +22: NarrativeOverviewWorkspace captures KPI cards screenshot when requested
00:03 +23: NarrativeOverviewWorkspace captures main story card screenshot when requested
00:03 +24: NarrativeOverviewWorkspace captures module cards grid screenshot when requested
00:03 +25: NarrativeOverviewWorkspace captures structure inspector screenshot when requested
00:03 +26: NarrativeOverviewWorkspace captures empty states and footer screenshot when requested
00:03 +27: NarrativeOverviewWorkspace captures responsive polish desktop screenshot when requested
00:03 +28: NarrativeOverviewWorkspace captures responsive polish medium screenshot when requested
00:03 +29: All tests passed!
```

### Tests shell connexes

```text
test/ui/canvas/narrative_studio_header_test.dart
00:00 +3: All tests passed!

test/ui/shell/project_explorer_handoff_test.dart
00:01 +3: All tests passed!

test/top_toolbar_test.dart
00:01 +10: All tests passed!

test/editor_selectors_test.dart
00:00 +9: All tests passed!

test/status_bar_test.dart
00:00 +6: All tests passed!
```

### Régression combinée

```text
cd packages/map_editor && flutter test test/ui/canvas/narrative_overview_workspace_test.dart test/ui/canvas/narrative_overview_shell_navigation_test.dart test/ui/canvas/narrative_studio_header_test.dart test/ui/shell/project_explorer_handoff_test.dart test/top_toolbar_test.dart test/editor_selectors_test.dart test/status_bar_test.dart
00:03 +78: All tests passed!
```

## 14. Résultats analyze

Analyse globale :

```text
cd packages/map_editor && flutter analyze
Analyzing map_editor...

error • The named parameter 'dbSymbol' isn't defined • lib/src/application/services/pokemon_sdk_move_catalog_converter.dart:58:7 • undefined_named_parameter
error • The named parameter 'battleEngineAimedTarget' isn't defined • lib/src/application/services/pokemon_sdk_move_catalog_converter.dart:64:7 • undefined_named_parameter
error • The named parameter 'battleEngineMethod' isn't defined • lib/src/application/services/pokemon_sdk_move_catalog_converter.dart:72:7 • undefined_named_parameter
error • Undefined class 'PokemonMoveAimedTarget' • lib/src/application/services/pokemon_sdk_move_catalog_converter.dart:239:3 • undefined_class
error • The method 'fetchPokemonSdkStudioProjectPayload' isn't defined for the type 'PokemonExternalSourceRepository' • lib/src/application/use_cases/sync_pokemon_sdk_moves_catalog_use_case.dart:58:10 • undefined_method
warning • The declaration '_buildHeader' isn't referenced • lib/src/features/environment_studio/environment_studio_panel.dart:433:10 • unused_element
warning • The library 'package:map_editor/src/ui/canvas/pokedex_workspace/pokedex_workspace_page.dart' doesn't export a member with the shown name 'showPokedexImportFlowSheet' • lib/src/ui/canvas/pokedex_workspace_views.dart:17:9 • undefined_shown_name
347 issues found. (ran in 3.6s)
```

Conclusion : l'analyse globale échoue sur une dette préexistante hors scope, principalement autour de l'import/conversion Pokémon SDK. Aucun fichier NS-HOME-21 n'est cité dans les erreurs.

Analyse ciblée :

```text
cd packages/map_editor && flutter analyze --no-fatal-infos lib/src/ui/canvas/narrative_studio_shell.dart lib/src/ui/canvas/narrative_studio_sidebar.dart lib/src/ui/canvas/narrative_studio_header.dart lib/src/ui/canvas/narrative_overview_workspace.dart lib/src/ui/canvas/narrative_overview_structure_inspector.dart test/ui/canvas/narrative_overview_shell_navigation_test.dart
Analyzing 6 items...
No issues found! (ran in 2.5s)
```

## 15. Limites

- L'analyse globale `flutter analyze` reste rouge sur dette hors scope.
- Les screenshots golden utilisent une police de substitution qui affiche certains textes comme des rectangles.
- Le rail Project Explorer réduit reste visible, conformément à NS-HOME-19.
- Le medium garde les KPI en deux lignes pour éviter une compression excessive.
- L'écran n'est pas pixel-perfect avec l'image cible et ne cherche pas à l'être.

## 16. Prochain lot recommandé

```text
NS-HOME-22 - Narrative Studio Final Acceptance Checkpoint V0
```

Objectif recommandé :

- vérifier l'ensemble NS-HOME-15 à NS-HOME-21 ;
- confirmer la séparation Project Explorer global / Narrative Studio interne ;
- valider interactions réelles vs disabled states ;
- consolider les screenshots finaux ;
- lister précisément les derniers écarts avant les lots métier suivants.

## 17. Evidence Pack

### Branche

```text
git branch --show-current
main
```

### Git status initial

```text
git status --short --untracked-files=all
```

Sortie initiale : aucune ligne, working tree propre avant NS-HOME-21.

### Git status final

```text
git status --short --untracked-files=all
 M packages/map_editor/lib/src/ui/canvas/narrative_overview_structure_inspector.dart
 M packages/map_editor/lib/src/ui/canvas/narrative_overview_workspace.dart
 M packages/map_editor/lib/src/ui/canvas/narrative_studio_header.dart
 M packages/map_editor/lib/src/ui/canvas/narrative_studio_shell.dart
 M packages/map_editor/lib/src/ui/canvas/narrative_studio_sidebar.dart
 M packages/map_editor/test/ui/canvas/narrative_overview_shell_navigation_test.dart
?? reports/narrativeStudio/ui/ns_home_21_narrative_studio_visual_harmonization.md
?? reports/narrativeStudio/ui/screenshots/ns_home_21_visual_harmonization_against_target.png
?? reports/narrativeStudio/ui/screenshots/ns_home_21_visual_harmonization_desktop.png
?? reports/narrativeStudio/ui/screenshots/ns_home_21_visual_harmonization_focus.png
?? reports/narrativeStudio/ui/screenshots/ns_home_21_visual_harmonization_medium.png
```

### Git diff stat final

```text
git diff --stat
 .../narrative_overview_structure_inspector.dart    |  26 ++---
 .../ui/canvas/narrative_overview_workspace.dart    |  86 +++++++-------
 .../lib/src/ui/canvas/narrative_studio_header.dart |  20 ++--
 .../lib/src/ui/canvas/narrative_studio_shell.dart  |   4 +-
 .../src/ui/canvas/narrative_studio_sidebar.dart    |  16 +--
 .../narrative_overview_shell_navigation_test.dart  | 127 +++++++++++++++++++++
 6 files changed, 203 insertions(+), 76 deletions(-)
```

Rappel : les fichiers non trackés ne sont pas listés par `git diff --stat`. Le rapport et les screenshots sont listés dans `git status`.

### Git diff name-only final

```text
git diff --name-only
packages/map_editor/lib/src/ui/canvas/narrative_overview_structure_inspector.dart
packages/map_editor/lib/src/ui/canvas/narrative_overview_workspace.dart
packages/map_editor/lib/src/ui/canvas/narrative_studio_header.dart
packages/map_editor/lib/src/ui/canvas/narrative_studio_shell.dart
packages/map_editor/lib/src/ui/canvas/narrative_studio_sidebar.dart
packages/map_editor/test/ui/canvas/narrative_overview_shell_navigation_test.dart
```

Rappel : `git diff --name-only` ne liste pas les nouveaux fichiers non trackés. Les nouveaux fichiers sont :

- `reports/narrativeStudio/ui/ns_home_21_narrative_studio_visual_harmonization.md`
- `reports/narrativeStudio/ui/screenshots/ns_home_21_visual_harmonization_desktop.png`
- `reports/narrativeStudio/ui/screenshots/ns_home_21_visual_harmonization_focus.png`
- `reports/narrativeStudio/ui/screenshots/ns_home_21_visual_harmonization_medium.png`
- `reports/narrativeStudio/ui/screenshots/ns_home_21_visual_harmonization_against_target.png`

### Git diff check final

```text
git diff --check
```

Sortie : aucune ligne.

### Screenshots produits

```text
reports/narrativeStudio/ui/screenshots/ns_home_21_visual_harmonization_focus.png:          PNG image data, 1600 x 700, 8-bit/color RGBA, non-interlaced
reports/narrativeStudio/ui/screenshots/ns_home_21_visual_harmonization_desktop.png:        PNG image data, 1600 x 1000, 8-bit/color RGBA, non-interlaced
reports/narrativeStudio/ui/screenshots/ns_home_21_visual_harmonization_medium.png:         PNG image data, 1180 x 1000, 8-bit/color RGBA, non-interlaced
reports/narrativeStudio/ui/screenshots/ns_home_21_visual_harmonization_against_target.png: PNG image data, 1600 x 1000, 8-bit/color RGBA, non-interlaced
```

```text
reports/narrativeStudio/ui/screenshots/ns_home_21_visual_harmonization_focus.png May 27 20:18:33 2026 159965
reports/narrativeStudio/ui/screenshots/ns_home_21_visual_harmonization_desktop.png May 27 20:18:10 2026 228756
reports/narrativeStudio/ui/screenshots/ns_home_21_visual_harmonization_medium.png May 27 20:18:55 2026 148399
reports/narrativeStudio/ui/screenshots/ns_home_21_visual_harmonization_against_target.png May 27 20:19:17 2026 228756
```

### Confirmation de périmètre

- aucun `ProjectExplorerPanel` modifié ;
- aucun read model modifié ;
- aucun provider créé ;
- aucun repository créé ;
- aucun fichier `map_core` modifié ;
- aucun fichier runtime modifié ;
- aucun fichier gameplay modifié ;
- aucun fichier battle modifié ;
- aucun build runner lancé ;
- aucune commande Git d'écriture lancée.

## 18. Auto-review critique

Points positifs :

- la densité desktop progresse nettement grâce aux KPI en une ligne ;
- le header interne est moins lourd que NS-HOME-20 ;
- le test NS-HOME-21 capture les invariants anti-fake ;
- le Visual Gate couvre desktop, focus, medium et comparaison cible ;
- l'overflow initial a été détecté et corrigé avant finalisation.

Points à surveiller :

- le seuil `>= 900 => 6` pour les KPI est visuellement bon sur le desktop réduit, mais devra être revérifié si la sidebar interne change de largeur ;
- les textes longs dans les KPI restent contraints par la largeur des six colonnes ;
- le rail global réduit reste visible et peut continuer à donner une impression de double chrome ;
- les screenshots golden ne rendent pas toute la typographie parfaitement.

## 19. Regard critique sur le prompt

Le prompt est strict et utile : il empêche de confondre harmonisation visuelle et ajout de fonctionnalités.

Point de vigilance : la demande de rapprochement contre l'image cible pourrait pousser à copier des données ou à activer des actions. Les garde-fous du prompt évitent ce piège. La meilleure lecture pour NS-HOME-21 est donc bien : améliorer densité, hiérarchie et cohérence, sans simuler l'écran final complet.
