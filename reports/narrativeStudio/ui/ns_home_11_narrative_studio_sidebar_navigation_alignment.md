# NS-HOME-11 — Narrative Studio Sidebar / Workspace Navigation Alignment V0

## 1. Résumé exécutif

NS-HOME-11 aligne progressivement la navigation latérale existante autour de la page `Narrative Studio / Aperçu`, sans reconstruire la sidebar finale de l'image cible.

Le changement principal est volontairement limité : quand un workspace narratif est actif (`narrativeOverview`, `globalStory`, `step`, `cutscene`, `dialogue`), le `ProjectExplorerPanel` affiche un header narratif et remonte la carte `Narrative Studio` en première position. Les modules existants (`Tileset Library`, `Catalogues Pokémon`, `World Maps`, `Path Library`, `Environment Studio`, `Trainer Studio`, etc.) restent présents.

Aucune destination fake `Facts`, `World Rules` ou `Validateur` n'a été ajoutée dans la navigation latérale.

## 2. Rappel du scope NS-HOME-11

Objectif du lot :

- rendre `Narrative Studio` immédiatement lisible dans le Project Explorer en mode `Aperçu` ;
- exposer clairement la navigation narrative V0 existante : `Aperçu`, `Histoire globale`, `Étape`, `Cinématique`, `Dialogue` ;
- garder les autres workspaces accessibles ;
- produire un Visual Gate full shell / navigation ;
- ne pas ajouter de modèle métier, de faux module, de fausse donnée ou de refonte globale de sidebar.

Hors scope respecté :

- pas de sidebar finale pixel-perfect ;
- pas de création de vraies destinations `Facts`, `World Rules`, `Validateur` ;
- pas de modification `NarrativeOverviewReadModel` ;
- pas de modification `map_core`, runtime, gameplay ou battle ;
- pas de `FR`, `v0.3.0`, Selbrume ou chiffres de l'image cible hardcodés.

## 3. Audit de la navigation latérale existante

Avant le lot, `ProjectExplorerPanel` sélectionnait déjà `Narrative Studio` en mode `narrativeOverview`, mais :

- le header de l'explorateur restait `World Explorer` ;
- `Narrative Studio` arrivait après `Tileset Library` et `Catalogues Pokémon` ;
- la navigation narrative existait dans `NarrativeLibraryPanel`, mais elle était visuellement trop basse dans le shell ;
- le full shell NS-HOME-10 montrait donc une page Overview honnête entourée d'un chrome latéral encore trop orienté monde / tilesets.

`NarrativeLibraryPanel` exposait déjà les entrées utiles :

- `Aperçu` ;
- `Histoire globale` ;
- `Étape` ;
- `Cinématique` ;
- `Dialogue`.

## 4. Fichiers créés / modifiés

Fichiers créés :

- `reports/narrativeStudio/ui/ns_home_11_narrative_studio_sidebar_navigation_alignment.md`
- `reports/narrativeStudio/ui/screenshots/ns_home_11_sidebar_navigation_desktop.png`
- `reports/narrativeStudio/ui/screenshots/ns_home_11_sidebar_navigation_focus.png`

Fichiers modifiés :

- `packages/map_editor/lib/src/ui/panels/project_explorer_panel.dart`
- `packages/map_editor/test/ui/canvas/narrative_overview_shell_navigation_test.dart`

## 5. Choix d'alignement sidebar retenu

Choix retenu : combinaison minimale des options A et C du prompt.

- A : `Narrative Studio` est remonté en haut quand un workspace narratif est actif.
- C : le header / résumé de la navigation latérale devient narratif en mode narratif.

Je n'ai pas réordonné toute la sidebar. Le réordonnancement est conditionnel au mode narratif et se limite à promouvoir `Narrative Studio` avant `Tileset Library` / `Catalogues Pokémon`.

Ce choix est le plus sûr pour V0 parce qu'il rend `Narrative Studio / Aperçu` immédiatement lisible sans supprimer ni masquer les autres surfaces historiques.

## 6. UI / navigation créée ou ajustée

`ProjectExplorerPanel` utilise désormais le `workspaceMode` pour construire son header :

- mode narratif : `Narrative Studio` + `Aperçu, histoire globale, étapes, cinématiques et dialogues` ;
- autre mode : comportement historique `World Explorer`.

La carte `Narrative Studio` est extraite dans `_buildNarrativeModuleCard(...)`, ce qui évite de dupliquer la carte pour la placer différemment selon le mode actif.

Navigation narrative V0 conservée :

- `Aperçu` active `narrativeOverview` ;
- `Histoire globale` active `globalStory` ;
- `Étape`, `Cinématique`, `Dialogue` restent visibles et disponibles via le panneau existant.

Entrées non narratives conservées :

- `Tileset Library` ;
- `Catalogues Pokémon` ;
- `World Maps` ;
- `Path Library` ;
- `Environment Studio` ;
- `Trainer Studio` ;
- `Character Library`.

## 7. Ce qui reste volontairement hors scope

- Sidebar finale de l'image cible.
- Entrées fonctionnelles `Facts`, `World Rules`, `Validateur`.
- Nouvelles actions toolbar.
- Nouveau provider ou repository.
- Toute donnée métier supplémentaire.
- Correction du mode strip narratif à 1000 px : la tentative de screenshot full shell 1000 x 1000 a révélé un overflow préexistant dans `narrative_workspace_canvas.dart:245`. Pour ce lot sidebar, le screenshot focus a été produit en 1180 x 1000.

## 8. Tests ajoutés / modifiés

Dans `narrative_overview_shell_navigation_test.dart` :

- ajout du test de clic `Histoire globale` après `Aperçu` ;
- ajout d'assertions sur le header narratif ;
- ajout d'assertions d'ordre visuel : `Narrative Studio` apparaît au-dessus de `Tileset Library` et `Catalogues Pokémon` en mode `narrativeOverview` ;
- ajout d'un test dédié `ProjectExplorerPanel prioritizes narrative navigation in overview mode` ;
- ajout des captures screenshot NS-HOME-11 via dart-define :
  - `NS_HOME_11_CAPTURE_SIDEBAR_DESKTOP`
  - `NS_HOME_11_CAPTURE_SIDEBAR_FOCUS`

## 9. Visual Gate

Screenshots produits :

- `reports/narrativeStudio/ui/screenshots/ns_home_11_sidebar_navigation_desktop.png`
- `reports/narrativeStudio/ui/screenshots/ns_home_11_sidebar_navigation_focus.png`

Méthode :

- widget test `EditorShellPage` ;
- `matchesGoldenFile(...)` ;
- `--update-goldens` ;
- tailles :
  - desktop : 1600 x 1000 ;
  - focus : 1180 x 1000.

Améliorations depuis NS-HOME-10 :

- le header latéral indique `Narrative Studio` au lieu de `World Explorer` en mode `Aperçu` ;
- la carte `Narrative Studio` est visible immédiatement et sélectionnée ;
- les actions narratives existantes sont plus proches du haut de la sidebar ;
- le status bar reste conforme au lot NS-HOME-10 : pas de `Locale : FR` ni `v0.3.0` en mode `narrativeOverview`.

Correspondance avec l'image cible :

- l'utilisateur comprend mieux qu'il se trouve dans une zone narrative ;
- `Aperçu` devient le premier accès visible de la navigation narrative ;
- la direction visuelle reste sombre, dense et cohérente avec le shell existant.

Écarts assumés :

- la sidebar finale de l'image n'est pas recréée ;
- `Facts`, `World Rules`, `Validateur` ne sont pas ajoutés comme destinations ;
- les pictogrammes / capsules toolbar restent ceux du shell actuel ;
- certains textes compacts de la navigation restent rendus par le harness golden avec une fonte de test, comme sur les screenshots full shell précédents.

Inspection visuelle :

- desktop : le panneau latéral est lisible, `Narrative Studio` est sélectionné, la page `Aperçu` reste stable ;
- focus : le cadrage montre clairement que `Narrative Studio` est promu en haut et que les autres entrées restent sous-jacentes ;
- aucun faux compteur ou faux module n'apparaît ;
- aucun problème de layout évident dans les tailles retenues.

Correction après inspection :

- la première capture focus isolée utilisait un thème clair de test et a été remplacée par un full shell 1180 x 1000 ;
- la tentative full shell 1000 x 1000 a révélé un overflow du mode strip narratif ; la capture focus a été portée à 1180 px pour rester dans un état stable du shell actuel.

## 10. Commandes exécutées

```bash
git branch --show-current
git status --short --untracked-files=all

cd packages/map_editor && flutter test test/ui/canvas/narrative_overview_shell_navigation_test.dart
cd packages/map_editor && flutter test test/ui/canvas/narrative_overview_workspace_test.dart
cd packages/map_editor && flutter test test/pokemon_catalogs_project_explorer_entry_test.dart
cd packages/map_editor && flutter test test/editor_selectors_test.dart
cd packages/map_editor && flutter test test/ui/canvas/narrative_overview_shell_navigation_test.dart test/ui/canvas/narrative_overview_workspace_test.dart

cd packages/map_editor && flutter test test/ui/canvas/narrative_overview_shell_navigation_test.dart --update-goldens --dart-define=NS_HOME_11_CAPTURE_SIDEBAR_DESKTOP=true
cd packages/map_editor && flutter test test/ui/canvas/narrative_overview_shell_navigation_test.dart --update-goldens --dart-define=NS_HOME_11_CAPTURE_SIDEBAR_FOCUS=true

cd packages/map_editor && flutter analyze
cd packages/map_editor && flutter analyze --no-fatal-infos lib/src/ui/panels/project_explorer_panel.dart test/ui/canvas/narrative_overview_shell_navigation_test.dart
cd packages/map_editor && flutter analyze --no-fatal-infos lib/src/ui/panels/project_explorer_panel.dart test/ui/canvas/narrative_overview_shell_navigation_test.dart test/pokemon_catalogs_project_explorer_entry_test.dart test/editor_selectors_test.dart

git diff --check
git diff --stat
git diff --name-only
file reports/narrativeStudio/ui/screenshots/ns_home_11_sidebar_navigation_desktop.png reports/narrativeStudio/ui/screenshots/ns_home_11_sidebar_navigation_focus.png
```

## 11. Résultats des tests

### Shell navigation

```text
00:00 +0: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/ui/canvas/narrative_overview_shell_navigation_test.dart
00:00 +0: NarrativeWorkspaceCanvas routes overview mode to the overview shell
00:00 +1: NarrativeLibraryPanel exposes overview without removing existing studios
00:00 +2: EditorShellPage presents coherent Narrative Studio overview chrome
00:01 +3: ProjectExplorerPanel prioritizes narrative navigation in overview mode
00:01 +4: NarrativeOverviewWorkspace captures a full editor shell screenshot when requested
00:01 +5: NarrativeOverviewWorkspace captures NS-HOME-11 sidebar navigation screenshots when requested
00:01 +6: NarrativeOverviewWorkspace captures NS-HOME-10 shell chrome screenshots when requested
00:01 +7: All tests passed!
```

### Overview workspace

```text
00:00 +0: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/ui/canvas/narrative_overview_workspace_test.dart
00:00 +0: NarrativeOverviewWorkspace renders a minimal authoring overview from the read model
00:00 +1: NarrativeOverviewWorkspace does not present unavailable modules as real data
00:00 +2: NarrativeOverviewWorkspace renders honest upcoming data states and footer metadata
00:00 +3: NarrativeOverviewWorkspace KPI cards consume read model values
00:00 +4: NarrativeOverviewWorkspace KPI layout renders on a narrower desktop width
00:00 +5: NarrativeOverviewWorkspace renders an honest empty main story card
00:01 +6: NarrativeOverviewWorkspace renders explicit main story data from the read model
00:01 +7: NarrativeOverviewWorkspace explains missing description and fallback chapters
00:01 +8: NarrativeOverviewWorkspace renders ambiguous main story state explicitly
00:01 +9: NarrativeOverviewWorkspace renders honest narrative module cards
00:01 +10: NarrativeOverviewWorkspace module cards consume read model values
00:01 +11: NarrativeOverviewWorkspace module grid keeps previous overview blocks visible
00:01 +12: NarrativeOverviewWorkspace renders an honest structure inspector panel
00:01 +13: NarrativeOverviewWorkspace structure inspector consumes read model counters and chapters
00:01 +14: NarrativeOverviewWorkspace structure inspector shows clean validation as up to date
00:01 +15: NarrativeOverviewWorkspace structure inspector maps warnings to review state
00:01 +16: NarrativeOverviewWorkspace structure inspector maps errors to blocking state
00:01 +17: NarrativeOverviewWorkspace keeps the structure inspector beside the main column on large desktop
00:02 +18: NarrativeOverviewWorkspace stacks the structure inspector after the main column on medium desktop
00:02 +19: NarrativeOverviewWorkspace keeps V0 unavailable data honest after responsive polish
00:02 +20: NarrativeOverviewWorkspace captures KPI cards screenshot when requested
00:02 +21: NarrativeOverviewWorkspace captures main story card screenshot when requested
00:02 +22: NarrativeOverviewWorkspace captures module cards grid screenshot when requested
00:02 +23: NarrativeOverviewWorkspace captures structure inspector screenshot when requested
00:02 +24: NarrativeOverviewWorkspace captures empty states and footer screenshot when requested
00:02 +25: NarrativeOverviewWorkspace captures responsive polish desktop screenshot when requested
00:02 +26: NarrativeOverviewWorkspace captures responsive polish medium screenshot when requested
00:02 +27: All tests passed!
```

### Project Explorer / Catalogues Pokémon

```text
00:00 +0: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/pokemon_catalogs_project_explorer_entry_test.dart
00:00 +0: ProjectExplorerPanel shows Catalogues Pokémon with Pokédex, Moves and Items child entries
00:00 +1: ProjectExplorerPanel taps update the active catalog section
00:00 +2: All tests passed!
```

### Editor selectors

```text
00:00 +0: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/editor_selectors_test.dart
00:00 +0: editor selectors editorShellSnapshotProvider derives map title and save affordance
00:00 +1: editor selectors editorToolbarSnapshotProvider resolves selected tileset from layer
00:00 +2: editor selectors Path Studio snapshots hide map save and history actions
00:00 +3: editor selectors editorProjectExplorerSnapshotProvider exposes active map selection
00:00 +4: editor selectors editorShellSnapshotProvider exposes trainer studio labels
00:00 +5: editor selectors editorShellSnapshotProvider exposes Pokémon catalogs labels
00:00 +6: editor selectors editorShellSnapshotProvider exposes clean Environment Studio labels
00:00 +7: editor selectors editorTerrainLibrarySnapshotProvider exposes preset selection inputs
00:00 +8: editor selectors editorTilesetPaletteSnapshotProvider exposes palette panel state
00:00 +9: All tests passed!
```

### Combined Overview

```text
00:03 +34: All tests passed!
```

## 12. Résultats analyze

`flutter analyze` global échoue encore sur une dette préexistante hors lot, liée au Pokémon SDK / catalog converter. Extrait pertinent :

```text
exit=1
Analyzing map_editor...

  error • The named parameter 'dbSymbol' isn't defined • lib/src/application/services/pokemon_sdk_move_catalog_converter.dart:58:7 • undefined_named_parameter
  error • The named parameter 'battleEngineAimedTarget' isn't defined • lib/src/application/services/pokemon_sdk_move_catalog_converter.dart:64:7 • undefined_named_parameter
  error • The named parameter 'battleEngineMethod' isn't defined • lib/src/application/services/pokemon_sdk_move_catalog_converter.dart:72:7 • undefined_named_parameter
...
  error • The method 'fetchPokemonSdkStudioProjectPayload' isn't defined for the type 'PokemonExternalSourceRepository' • lib/src/application/use_cases/sync_pokemon_sdk_moves_catalog_use_case.dart:58:10 • undefined_method
  error • The getter 'dbSymbol' isn't defined for the type 'PokemonMove' • test/application/services/pokemon_sdk_move_catalog_converter_test.dart:45:19 • undefined_getter
  error • The named parameter 'dbSymbol' isn't defined • test/application/use_cases/sync_pokemon_sdk_moves_catalog_use_case_test.dart:338:7 • undefined_named_parameter
348 issues found. (ran in 4.2s)
```

Analyse ciblée des fichiers modifiés :

```text
Analyzing 2 items...
No issues found! (ran in 3.6s)
```

Analyse ciblée élargie aux tests explicitement demandés :

```text
Analyzing 4 items...

   info • Use 'const' with the constructor to improve performance • test/editor_selectors_test.dart:45:63 • prefer_const_constructors
   info • Use 'const' with the constructor to improve performance • test/editor_selectors_test.dart:46:18 • prefer_const_constructors
   info • Use 'const' with the constructor to improve performance • test/editor_selectors_test.dart:114:63 • prefer_const_constructors
   info • Use 'const' with the constructor to improve performance • test/editor_selectors_test.dart:117:18 • prefer_const_constructors
   info • Use 'const' with the constructor to improve performance • test/editor_selectors_test.dart:142:63 • prefer_const_constructors
   info • Use 'const' with the constructor to improve performance • test/editor_selectors_test.dart:144:18 • prefer_const_constructors
   info • Use 'const' with the constructor to improve performance • test/editor_selectors_test.dart:164:63 • prefer_const_constructors
   info • Use 'const' with the constructor to improve performance • test/editor_selectors_test.dart:166:18 • prefer_const_constructors
   info • Use 'const' with the constructor to improve performance • test/editor_selectors_test.dart:184:63 • prefer_const_constructors
   info • Use 'const' with the constructor to improve performance • test/editor_selectors_test.dart:186:18 • prefer_const_constructors
   info • Use 'const' with the constructor to improve performance • test/editor_selectors_test.dart:208:63 • prefer_const_constructors
   info • Use 'const' with the constructor to improve performance • test/editor_selectors_test.dart:209:18 • prefer_const_constructors
   info • Use 'const' with the constructor to improve performance • test/editor_selectors_test.dart:238:63 • prefer_const_constructors
   info • Use 'const' with the constructor to improve performance • test/editor_selectors_test.dart:240:18 • prefer_const_constructors
   info • Unnecessary 'const' keyword • test/pokemon_catalogs_project_explorer_entry_test.dart:21:48 • unnecessary_const
   info • Unnecessary 'const' keyword • test/pokemon_catalogs_project_explorer_entry_test.dart:80:48 • unnecessary_const

16 issues found. (ran in 1.5s)
```

Ces infos sont préexistantes dans des fichiers non modifiés par NS-HOME-11.

## 13. Limites

- La navigation latérale n'est pas la sidebar finale de l'image cible.
- `Facts`, `World Rules`, `Validateur` ne sont pas exposés comme destinations, volontairement.
- La largeur 1000 px du full shell révèle un overflow préexistant dans le mode strip narratif ; le screenshot focus est donc produit en 1180 x 1000.
- Le harness golden full shell garde quelques artefacts de fonte sur des contrôles compacts, déjà visibles sur les screenshots NS-HOME-09 / NS-HOME-10.

## 14. Prochain lot recommandé

Prochain lot recommandé :

```text
NS-HOME-12 — Narrative Studio Top Bar / Action Affordances V0
```

Objectif proposé : aligner les actions de top bar existantes autour de `Aperçu`, sans créer les boutons finaux fake (`Nouvelle storyline`, `Valider`, notifications) tant qu'ils ne sont pas branchés à des sources fiables.

## 15. Evidence Pack

### Branche

```text
main
```

### Git status initial

```text
(aucune sortie)
```

### Git status final

```text
 M packages/map_editor/lib/src/ui/panels/project_explorer_panel.dart
 M packages/map_editor/test/ui/canvas/narrative_overview_shell_navigation_test.dart
?? reports/narrativeStudio/ui/ns_home_11_narrative_studio_sidebar_navigation_alignment.md
?? reports/narrativeStudio/ui/screenshots/ns_home_11_sidebar_navigation_desktop.png
?? reports/narrativeStudio/ui/screenshots/ns_home_11_sidebar_navigation_focus.png
```

### Git diff stat final

```text
 .../lib/src/ui/panels/project_explorer_panel.dart  | 112 ++++++++-----
 .../narrative_overview_shell_navigation_test.dart  | 173 +++++++++++++++++++++
 2 files changed, 250 insertions(+), 35 deletions(-)
```

Note : les screenshots et ce rapport sont non trackés ; `git diff --stat` ne les inclut pas.

### Git diff name-only final

```text
packages/map_editor/lib/src/ui/panels/project_explorer_panel.dart
packages/map_editor/test/ui/canvas/narrative_overview_shell_navigation_test.dart
```

### Git diff check final

```text
(aucune sortie)
```

### Fichiers créés

```text
reports/narrativeStudio/ui/ns_home_11_narrative_studio_sidebar_navigation_alignment.md
reports/narrativeStudio/ui/screenshots/ns_home_11_sidebar_navigation_desktop.png
reports/narrativeStudio/ui/screenshots/ns_home_11_sidebar_navigation_focus.png
```

### Fichiers modifiés

```text
packages/map_editor/lib/src/ui/panels/project_explorer_panel.dart
packages/map_editor/test/ui/canvas/narrative_overview_shell_navigation_test.dart
```

### Extraits complets des sections modifiées

`project_explorer_panel.dart` — header contextuel :

```dart
Widget _buildHeader(BuildContext context, EditorWorkspaceMode workspaceMode) {
  final colors = context.pokeMapColors;
  final subtle = colors.textMuted;
  final label = colors.textPrimary;
  final isNarrativeWorkspace = _isNarrativeWorkspace(workspaceMode);
  final accent =
      isNarrativeWorkspace ? colors.narrative : colors.brandPrimary;
  final icon = isNarrativeWorkspace
      ? CupertinoIcons.link_circle_fill
      : CupertinoIcons.square_stack_3d_up;
  final title = isNarrativeWorkspace ? 'Narrative Studio' : 'World Explorer';
  final subtitle = isNarrativeWorkspace
      ? 'Aperçu, histoire globale, étapes, cinématiques et dialogues'
      : 'Cartes, tilesets, surfaces — dialogues dans Dialogue Studio';
  // ...
}

bool _isNarrativeWorkspace(EditorWorkspaceMode workspaceMode) {
  return workspaceMode == EditorWorkspaceMode.narrativeOverview ||
      workspaceMode == EditorWorkspaceMode.globalStory ||
      workspaceMode == EditorWorkspaceMode.step ||
      workspaceMode == EditorWorkspaceMode.cutscene ||
      workspaceMode == EditorWorkspaceMode.dialogue;
}
```

`project_explorer_panel.dart` — promotion conditionnelle :

```dart
final isNarrativeWorkspace = _isNarrativeWorkspace(snapshot.workspaceMode);
final narrativeModuleCard = _buildNarrativeModuleCard(
  context,
  project,
  snapshot,
  hNarrative,
);

return Column(
  crossAxisAlignment: CrossAxisAlignment.stretch,
  children: [
    if (isNarrativeWorkspace) narrativeModuleCard,
    ProjectExplorerModuleCard(
      title: 'Tileset Library',
      // ...
    ),
    ProjectExplorerModuleCard(
      title: 'Catalogues Pokémon',
      // ...
    ),
    if (!isNarrativeWorkspace) narrativeModuleCard,
    ProjectExplorerModuleCard(
      title: 'World Maps',
      // ...
    ),
  ],
);
```

`project_explorer_panel.dart` — carte narrative extraite :

```dart
Widget _buildNarrativeModuleCard(
  BuildContext context,
  ProjectManifest project,
  EditorProjectExplorerSnapshot snapshot,
  double expandedHeight,
) {
  final colors = context.pokeMapColors;
  return ProjectExplorerModuleCard(
    title: 'Narrative Studio',
    description: 'Accès aux espaces auteur narratifs existants',
    icon: CupertinoIcons.link_circle_fill,
    accentColor: colors.narrative,
    count: project.scenarios.length,
    selected: _isNarrativeWorkspace(snapshot.workspaceMode),
    expanded: _expandNarrative,
    onExpandToggle: () =>
        setState(() => _expandNarrative = !_expandNarrative),
    expandedHeight: expandedHeight,
    child: const NarrativeLibraryPanel(embedded: true),
  );
}
```

`narrative_overview_shell_navigation_test.dart` — tests et screenshots NS-HOME-11 :

```dart
await tester.tap(find.text('Histoire globale'));
await tester.pumpAndSettle();

expect(
  find.text('workspace:globalStory'),
  findsOneWidget,
);

expect(
  find.text('Aperçu, histoire globale, étapes, cinématiques et dialogues'),
  findsOneWidget,
);
expect(find.text('World Explorer'), findsNothing);

final narrativeCard = find.byWidgetPredicate(
  (widget) =>
      widget is ProjectExplorerModuleCard &&
      widget.title == 'Narrative Studio',
);
final tilesetCard = find.byWidgetPredicate(
  (widget) =>
      widget is ProjectExplorerModuleCard &&
      widget.title == 'Tileset Library',
);
final catalogsCard = find.byWidgetPredicate(
  (widget) =>
      widget is ProjectExplorerModuleCard &&
      widget.title == 'Catalogues Pokémon',
);

expect(
  tester.getTopLeft(narrativeCard).dy,
  lessThan(tester.getTopLeft(tilesetCard).dy),
);
expect(
  tester.getTopLeft(narrativeCard).dy,
  lessThan(tester.getTopLeft(catalogsCard).dy),
);

const captureDesktop =
    bool.fromEnvironment('NS_HOME_11_CAPTURE_SIDEBAR_DESKTOP');
const captureFocus =
    bool.fromEnvironment('NS_HOME_11_CAPTURE_SIDEBAR_FOCUS');
```

### Screenshots

```text
reports/narrativeStudio/ui/screenshots/ns_home_11_sidebar_navigation_desktop.png: PNG image data, 1600 x 1000, 8-bit/color RGBA, non-interlaced
reports/narrativeStudio/ui/screenshots/ns_home_11_sidebar_navigation_focus.png:   PNG image data, 1180 x 1000, 8-bit/color RGBA, non-interlaced
```

```text
reports/narrativeStudio/ui/screenshots/ns_home_11_sidebar_navigation_desktop.png May 27 14:42:21 2026 242908
reports/narrativeStudio/ui/screenshots/ns_home_11_sidebar_navigation_focus.png May 27 14:42:26 2026 185402
```

## 16. Auto-review critique

Points validés :

- changement limité au `ProjectExplorerPanel` et aux tests de navigation shell ;
- pas de nouveau module métier ;
- pas de fake `Facts`, `World Rules`, `Validateur` ;
- les workspaces existants restent présents ;
- les tests ciblés passent ;
- l'analyse ciblée des fichiers modifiés est clean ;
- deux screenshots full shell ont été produits.

Points de vigilance :

- la sidebar reste une version intermédiaire, pas la sidebar cible ;
- le mode strip narratif a un overflow à 1000 px, hors correction de ce lot ;
- les screenshots golden full shell gardent quelques limites de rendu de fonte sur les contrôles compacts.

## 17. Regard critique sur le prompt

Le prompt est bien borné : il force à améliorer la lisibilité narrative sans reconstruire la sidebar finale ni ajouter de destinations non branchées.

Point utile : la demande explicite de préserver `World Explorer`, `Tile Library`, `Pokémon Catalogs` et les studios existants évite un refactor trop large.

Point à clarifier pour un futur lot : si la cible devient la sidebar de l'image, il faudra décider si elle remplace le `ProjectExplorerPanel` actuel, si elle devient une sous-navigation narrative dédiée, ou si elle cohabite avec l'explorateur projet historique.
