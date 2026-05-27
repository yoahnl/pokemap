# NS-HOME-12 — Narrative Studio Top Bar / Action Affordances V0

## 1. Résumé exécutif

NS-HOME-12 aligne la top bar existante autour de `Narrative Studio / Aperçu` sans construire la top bar finale de l'image cible.

Le changement principal est conditionnel au mode `EditorWorkspaceMode.narrativeOverview` : les groupes d'actions orientés carte (`Carte`, `Affichage`, `Outils`, `Calques`) ne sont plus affichés dans ce mode, et une capsule `Narrative Studio` dédiée apparaît à la place.

Cette capsule garde `Aperçu` comme action active réelle, puis expose des affordances désactivées et explicitement V0 pour `Nouvelle storyline`, `Validation narrative`, `Recherche narrative` et `Notifications`. Aucune vraie création de storyline, aucune validation fake, aucune recherche globale fake et aucun badge notification n'ont été ajoutés.

## 2. Rappel du scope NS-HOME-12

Objectif du lot :

- clarifier le libellé top bar en mode `Narrative Studio / Aperçu` ;
- éviter que les actions map/calques semblent s'appliquer à la page Overview ;
- représenter les actions narratives futures de manière honnête, désactivée, sans données inventées ;
- préserver les autres workspaces et les lots NS-HOME-03 à NS-HOME-11 ;
- produire un Visual Gate full shell centré sur la top bar.

Hors scope respecté :

- pas de vraie création de storyline ;
- pas de formulaire `Nouvelle storyline` ;
- pas de validation narrative branchée artificiellement ;
- pas de recherche globale fake ;
- pas de centre de notifications ni badge notification fake ;
- pas de modification de `NarrativeOverviewReadModel`, `map_core`, runtime, gameplay ou battle ;
- pas de `Selbrume`, `FR`, `v0.3.0`, tags ou chiffres de l'image cible hardcodés.

## 3. Audit top bar existante

Avant ce lot, les lots précédents avaient déjà corrigé le libellé principal du chrome :

```text
test_project  •  Narrative Studio / Aperçu
```

La top bar restait toutefois trop générique pour l'Overview :

- les groupes `Carte`, `Affichage`, `Outils` et `Calques` pouvaient apparaître autour d'une page narrative ;
- le bouton `New Map` et le toggle de calques pouvaient être visibles alors que l'utilisateur n'était pas dans un canvas map ;
- l'accès `Aperçu` existait dans le groupe général de switch workspace, mais il était noyé parmi les destinations map / tileset / catalogues ;
- aucune action narrative finale n'était réellement branchée, ce qui imposait de ne pas créer de bouton actif trompeur.

## 4. Fichiers créés / modifiés

Fichiers créés :

- `reports/narrativeStudio/ui/ns_home_12_narrative_studio_top_bar_action_affordances.md`
- `reports/narrativeStudio/ui/screenshots/ns_home_12_top_bar_desktop.png`
- `reports/narrativeStudio/ui/screenshots/ns_home_12_top_bar_action_focus.png`

Fichiers modifiés :

- `packages/map_editor/lib/src/ui/shared/top_toolbar.dart`
- `packages/map_editor/test/top_toolbar_test.dart`
- `packages/map_editor/test/ui/canvas/narrative_overview_shell_navigation_test.dart`

## 5. Choix d'affordances retenu

Choix retenu : afficher une capsule top bar `Narrative Studio` uniquement en mode `narrativeOverview`.

Dans cette capsule :

- `Aperçu` est actif et sélectionné, car c'est la page courante et l'action réelle existe ;
- `Nouvelle storyline` est visible seulement comme affordance désactivée, avec tooltip V0 ;
- `Validation narrative` est visible seulement comme affordance désactivée, avec tooltip V0 ;
- `Recherche narrative` est visible seulement comme affordance désactivée, avec tooltip V0 ;
- `Notifications` est visible seulement comme affordance désactivée, sans badge.

Les boutons finaux de l'image cible ne sont donc pas simulés comme fonctionnalités disponibles.

## 6. UI / top bar alignment réalisé

En mode `narrativeOverview`, la top bar conserve :

- le groupe `Fichier`, parce qu'il contient des actions globales projet existantes ;
- le libellé principal `Narrative Studio / Aperçu` déjà introduit avant ce lot ;
- la capsule `Narrative Studio` avec `Aperçu` sélectionné et les affordances narratives désactivées.

En mode `narrativeOverview`, la top bar masque :

- `Carte` ;
- `Affichage` ;
- `Outils` ;
- `Calques`.

Ce masquage est strictement conditionnel à `EditorWorkspaceMode.narrativeOverview`. Les autres workspaces gardent le comportement historique de la top bar.

## 7. Actions volontairement non créées

Actions non créées ou non activées :

- `Nouvelle storyline` : pas de vraie création, pas de formulaire, pas d'écriture projet ;
- `Valider` / validation narrative : pas de faux validateur global branché ;
- `Recherche` : pas de recherche globale inventée ;
- `Notifications` : pas de notification inventée, pas de badge ;
- `Paramètres narratifs` : aucun panneau narratif fake.

Les affordances désactivées servent seulement à indiquer la direction produit V0 sans mentir sur les capacités disponibles.

## 8. Ce qui reste volontairement hors scope

- Top bar finale pixel-perfect de l'image cible.
- Breadcrumb complet home / Narrative Studio.
- Boutons texte finaux `Nouvelle storyline`, `Aperçu`, `Valider`.
- Recherche globale réelle.
- Centre de notifications.
- Paramètres narratifs.
- Refonte de `EditorShellPage`.
- Refonte de la sidebar finale.

## 9. Tests ajoutés / modifiés

Dans `top_toolbar_test.dart`, le test existant `uses the French Narrative Studio overview chrome label` a été renforcé :

- `Narrative Studio / Aperçu` reste visible ;
- `Narrative Overview` n'est pas visible ;
- `Aperçu` reste sélectionné et actionnable ;
- `Carte`, `Affichage`, `Calques` ne sont pas visibles en overview ;
- `New Map` n'est pas rendu ;
- le toggle de calques n'est pas rendu ;
- les affordances `Nouvelle storyline`, `Validation narrative`, `Recherche narrative`, `Notifications` existent mais sont désactivées.

Dans `narrative_overview_shell_navigation_test.dart`, un test screenshot NS-HOME-12 a été ajouté avec deux flags :

- `NS_HOME_12_CAPTURE_TOP_BAR_DESKTOP`
- `NS_HOME_12_CAPTURE_TOP_BAR_FOCUS`

## 10. Visual Gate

Screenshots produits :

- `reports/narrativeStudio/ui/screenshots/ns_home_12_top_bar_desktop.png`
- `reports/narrativeStudio/ui/screenshots/ns_home_12_top_bar_action_focus.png`

Méthode :

- widget test `EditorShellPage` ;
- `matchesGoldenFile(...)` ;
- `--update-goldens` ;
- tailles :
  - desktop : 1600 x 1000 ;
  - action focus : 1600 x 700.

Améliorations depuis NS-HOME-11 :

- la top bar ne mélange plus les actions map/calques avec l'Overview narratif ;
- `Narrative Studio` devient le groupe d'action top bar principal en mode Overview ;
- l'action `Aperçu` est visible comme état courant ;
- les actions futures sont visibles uniquement comme affordances désactivées et non comme boutons actifs.

Correspondance avec l'image cible :

- la top bar commence à raconter un contexte narratif plutôt qu'un contexte map ;
- les actions attendues par la future direction produit sont évoquées ;
- le shell reste sombre, dense et cohérent avec les screenshots précédents.

Écarts assumés :

- pas de vraie top bar finale ;
- pas de breadcrumb complet ;
- pas de boutons texte verts/bleus finaux ;
- pas de recherche, notification, paramètres ou validation fonctionnels ;
- les screenshots full shell gardent quelques artefacts de fonte dans les contrôles compacts du harness golden, déjà observés sur les lots précédents.

Inspection visuelle :

- desktop : `Narrative Studio / Aperçu` est lisible, la sidebar NS-HOME-11 reste stable, la top bar ne montre plus les groupes map/calques ;
- focus : la capsule `Narrative Studio` et ses affordances sont visibles sans introduire de badge notification ou d'action active trompeuse ;
- aucun problème évident de layout ou d'overflow dans les tailles retenues.

Correction après inspection :

- le premier test rouge a confirmé que `Carte` restait visible en overview ; l'implémentation masque désormais les groupes map/calques en mode `narrativeOverview`.

## 11. Commandes exécutées

```bash
git branch --show-current
git status --short --untracked-files=all
git diff --stat
git diff --name-only
git diff --check

cd packages/map_editor && flutter test test/top_toolbar_test.dart
cd packages/map_editor && flutter test test/ui/canvas/narrative_overview_shell_navigation_test.dart
cd packages/map_editor && flutter test test/ui/canvas/narrative_overview_workspace_test.dart
cd packages/map_editor && flutter test test/editor_selectors_test.dart
cd packages/map_editor && flutter test test/status_bar_test.dart
cd packages/map_editor && flutter test test/top_toolbar_test.dart test/editor_selectors_test.dart test/status_bar_test.dart test/ui/canvas/narrative_overview_shell_navigation_test.dart

cd packages/map_editor && flutter test test/ui/canvas/narrative_overview_shell_navigation_test.dart --update-goldens --dart-define=NS_HOME_12_CAPTURE_TOP_BAR_DESKTOP=true
cd packages/map_editor && flutter test test/ui/canvas/narrative_overview_shell_navigation_test.dart --update-goldens --dart-define=NS_HOME_12_CAPTURE_TOP_BAR_FOCUS=true

cd packages/map_editor && flutter analyze
cd packages/map_editor && flutter analyze --no-fatal-infos lib/src/ui/shared/top_toolbar.dart test/top_toolbar_test.dart test/ui/canvas/narrative_overview_shell_navigation_test.dart

file reports/narrativeStudio/ui/screenshots/ns_home_12_top_bar_desktop.png reports/narrativeStudio/ui/screenshots/ns_home_12_top_bar_action_focus.png
stat -f '%Sm %z' reports/narrativeStudio/ui/screenshots/ns_home_12_top_bar_desktop.png reports/narrativeStudio/ui/screenshots/ns_home_12_top_bar_action_focus.png
```

## 12. Résultats des tests

### Top toolbar

```text
00:00 +0: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/top_toolbar_test.dart
00:00 +0: TopToolbar shows the app brand and project workspace label
00:00 +1: TopToolbar falls back to the workspace label when no project is loaded
00:00 +2: TopToolbar shows the toolbar status chip when a status is present
00:00 +3: TopToolbar shows the trainer studio label for the trainer workspace
00:00 +4: TopToolbar uses the French Narrative Studio overview chrome label
00:00 +5: TopToolbar enables project save and disables map history in Path Studio
00:00 +6: TopToolbar shows neutral Save Project when project is clean in Path Studio
00:00 +7: TopToolbar enables project save and disables map history in Environment Studio
00:00 +8: TopToolbar shows Environment Studio in the workspace brand strip
00:00 +9: TopToolbar keeps map save action in map workspace
00:00 +10: All tests passed!
```

### Shell navigation

```text
00:00 +0: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/ui/canvas/narrative_overview_shell_navigation_test.dart
00:00 +0: NarrativeWorkspaceCanvas routes overview mode to the overview shell
00:00 +1: NarrativeLibraryPanel exposes overview without removing existing studios
00:00 +2: EditorShellPage presents coherent Narrative Studio overview chrome
00:00 +3: ProjectExplorerPanel prioritizes narrative navigation in overview mode
00:00 +4: NarrativeOverviewWorkspace captures a full editor shell screenshot when requested
00:00 +5: NarrativeOverviewWorkspace captures NS-HOME-11 sidebar navigation screenshots when requested
00:00 +6: NarrativeOverviewWorkspace captures NS-HOME-12 top bar screenshots when requested
00:00 +7: NarrativeOverviewWorkspace captures NS-HOME-10 shell chrome screenshots when requested
00:01 +8: All tests passed!
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
00:01 +18: NarrativeOverviewWorkspace stacks the structure inspector after the main column on medium desktop
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

### Status bar

```text
00:00 +0: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/status_bar_test.dart
00:00 +0: StatusBar shows ready and zoom when no map is active
00:00 +1: StatusBar shows active map chips and formatted zoom
00:00 +2: StatusBar hides global locale and version metadata in Narrative Overview
00:00 +3: StatusBar prioritizes error text over status text
00:00 +4: StatusBar shows persistent unsaved-project signal when project is dirty
00:00 +5: StatusBar hides unsaved-project signal after project save success
00:00 +6: All tests passed!
```

### Régression combinée shell

```text
00:00 +0: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/top_toolbar_test.dart
00:00 +0: /Users/karim/Project/pokemonProject/packages/map_editor/test/editor_selectors_test.dart: editor selectors editorShellSnapshotProvider derives map title and save affordance
...
00:01 +31: /Users/karim/Project/pokemonProject/packages/map_editor/test/ui/canvas/narrative_overview_shell_navigation_test.dart: NarrativeOverviewWorkspace captures NS-HOME-12 top bar screenshots when requested
00:01 +32: /Users/karim/Project/pokemonProject/packages/map_editor/test/ui/canvas/narrative_overview_shell_navigation_test.dart: NarrativeOverviewWorkspace captures NS-HOME-10 shell chrome screenshots when requested
00:01 +33: All tests passed!
```

### Screenshots NS-HOME-12

```text
00:00 +0: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/ui/canvas/narrative_overview_shell_navigation_test.dart
00:00 +0: NarrativeWorkspaceCanvas routes overview mode to the overview shell
00:00 +1: NarrativeLibraryPanel exposes overview without removing existing studios
00:00 +2: EditorShellPage presents coherent Narrative Studio overview chrome
00:00 +3: ProjectExplorerPanel prioritizes narrative navigation in overview mode
00:01 +4: NarrativeOverviewWorkspace captures a full editor shell screenshot when requested
00:01 +5: NarrativeOverviewWorkspace captures NS-HOME-11 sidebar navigation screenshots when requested
00:01 +6: NarrativeOverviewWorkspace captures NS-HOME-12 top bar screenshots when requested
00:01 +7: NarrativeOverviewWorkspace captures NS-HOME-10 shell chrome screenshots when requested
00:01 +8: All tests passed!
```

## 13. Résultats analyze

`flutter analyze` global échoue encore sur une dette préexistante hors lot liée au Pokémon SDK / catalog converter. Extrait pertinent :

```text
Analyzing map_editor...

  error • The named parameter 'dbSymbol' isn't defined • lib/src/application/services/pokemon_sdk_move_catalog_converter.dart:58:7 • undefined_named_parameter
  error • The named parameter 'battleEngineAimedTarget' isn't defined • lib/src/application/services/pokemon_sdk_move_catalog_converter.dart:64:7 • undefined_named_parameter
  error • The named parameter 'battleEngineMethod' isn't defined • lib/src/application/services/pokemon_sdk_move_catalog_converter.dart:72:7 • undefined_named_parameter
  error • The named parameter 'effectChance' isn't defined • lib/src/application/services/pokemon_sdk_move_catalog_converter.dart:73:7 • undefined_named_parameter
  error • The named parameter 'studioFlags' isn't defined • lib/src/application/services/pokemon_sdk_move_catalog_converter.dart:74:7 • undefined_named_parameter
  error • The named parameter 'battleStageMods' isn't defined • lib/src/application/services/pokemon_sdk_move_catalog_converter.dart:75:7 • undefined_named_parameter
  error • The named parameter 'moveStatuses' isn't defined • lib/src/application/services/pokemon_sdk_move_catalog_converter.dart:76:7 • undefined_named_parameter
  error • The named parameter 'psdkStudioMoveId' isn't defined • lib/src/application/services/pokemon_sdk_move_catalog_converter.dart:80:9 • undefined_named_parameter
  error • The named parameter 'psdkDbSymbol' isn't defined • lib/src/application/services/pokemon_sdk_move_catalog_converter.dart:81:9 • undefined_named_parameter
  error • The method 'fetchPokemonSdkStudioProjectPayload' isn't defined for the type 'PokemonExternalSourceRepository' • lib/src/application/use_cases/sync_pokemon_sdk_moves_catalog_use_case.dart:58:10 • undefined_method
...
348 issues found. (ran in 3.2s)
```

Code de sortie global :

```text
1
```

Analyse ciblée des fichiers modifiés/créés côté Dart :

```text
Analyzing 3 items...
No issues found! (ran in 1.3s)
```

Conclusion : aucune erreur d'analyse introduite par NS-HOME-12 sur les fichiers modifiés.

## 14. Limites

- La top bar reste une top bar V0 avec icônes compactes, pas la top bar finale de l'image.
- Les actions futures sont visibles comme affordances désactivées ; il faudra une vraie décision produit avant de les rendre actives.
- Le groupe `Fichier` reste en anglais/historique, car il appartient au chrome global et le lot ne refond pas toute la top bar.
- Le harness screenshot full shell garde quelques rendus de fonte peu naturels sur les capsules compactes.

## 15. Prochain lot recommandé

Prochain lot recommandé :

```text
NS-HOME-13 — Narrative Studio Breadcrumb / Shell Header Refinement V0
```

Objectif proposé : améliorer le breadcrumb / header shell autour de `Narrative Studio / Aperçu` sans encore reconstruire la top bar finale ni activer les actions futures.

## 16. Evidence Pack

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
 M packages/map_editor/lib/src/ui/shared/top_toolbar.dart
 M packages/map_editor/test/top_toolbar_test.dart
 M packages/map_editor/test/ui/canvas/narrative_overview_shell_navigation_test.dart
?? reports/narrativeStudio/ui/ns_home_12_narrative_studio_top_bar_action_affordances.md
?? reports/narrativeStudio/ui/screenshots/ns_home_12_top_bar_action_focus.png
?? reports/narrativeStudio/ui/screenshots/ns_home_12_top_bar_desktop.png
```

### Git diff stat final

```text
 .../map_editor/lib/src/ui/shared/top_toolbar.dart  | 588 +++++++++++----------
 packages/map_editor/test/top_toolbar_test.dart     |  53 ++
 .../narrative_overview_shell_navigation_test.dart  |  38 ++
 3 files changed, 410 insertions(+), 269 deletions(-)
```

### Git diff name-only final

```text
packages/map_editor/lib/src/ui/shared/top_toolbar.dart
packages/map_editor/test/top_toolbar_test.dart
packages/map_editor/test/ui/canvas/narrative_overview_shell_navigation_test.dart
```

### Git diff check final

```text
(aucune sortie)
```

### Fichiers créés

```text
reports/narrativeStudio/ui/ns_home_12_narrative_studio_top_bar_action_affordances.md
reports/narrativeStudio/ui/screenshots/ns_home_12_top_bar_desktop.png
reports/narrativeStudio/ui/screenshots/ns_home_12_top_bar_action_focus.png
```

### Fichiers modifiés

```text
packages/map_editor/lib/src/ui/shared/top_toolbar.dart
packages/map_editor/test/top_toolbar_test.dart
packages/map_editor/test/ui/canvas/narrative_overview_shell_navigation_test.dart
```

### Note fichiers non trackés

Les screenshots et ce rapport sont non trackés tant que Karim ne les stage pas. Ils ne sont donc pas inclus dans `git diff --stat` / `git diff --name-only`.

### Extraits complets des sections modifiées

`top_toolbar.dart` — détection du mode overview et masquage des groupes map :

```dart
final isNarrativeOverview =
    toolbar.workspaceMode == EditorWorkspaceMode.narrativeOverview;

// ...

if (!isNarrativeOverview)
  _groupItem(
    context,
    title: 'Carte',
    overflowLabel: 'Carte',
    children: [
      ToolbarCapsuleButton(
        icon: CupertinoIcons.placemark,
        tooltip: 'New Map',
        onPressed: toolbar.project != null && toolbar.projectRootPath != null
            ? () => showTopToolbarNewMapDialog(
                  context,
                  notifier,
                  defaultWidth: settings.defaultMapWidth,
                  defaultHeight: settings.defaultMapHeight,
                )
            : null,
      ),
      ToolbarCapsuleButton(
        icon: CupertinoIcons.rectangle_arrow_up_right_arrow_down_left,
        tooltip: 'Resize Map',
        onPressed: isMapWorkspace && toolbar.activeMap != null
            ? () => showTopToolbarResizeMapDialog(
                  context,
                  notifier,
                  currentWidth: toolbar.activeMap!.size.width,
                  currentHeight: toolbar.activeMap!.size.height,
                )
            : null,
      ),
    ],
  ),
```

`top_toolbar.dart` — capsule narrative dédiée :

```dart
if (isNarrativeOverview)
  _groupItem(
    context,
    title: 'Narrative Studio',
    overflowLabel: 'Narrative Studio',
    selected: true,
    children: [
      ToolbarCapsuleButton(
        icon: CupertinoIcons.house,
        tooltip: 'Ouvrir Narrative Studio / Aperçu',
        selected: true,
        onPressed: toolbar.project != null
            ? notifier.selectNarrativeOverviewWorkspace
            : null,
      ),
      const ToolbarCapsuleButton(
        icon: CupertinoIcons.plus,
        tooltip: 'Nouvelle storyline à venir — création non branchée en V0',
        onPressed: null,
      ),
      const ToolbarCapsuleButton(
        icon: CupertinoIcons.checkmark_shield,
        tooltip:
            'Validation narrative à venir — aucun validateur global branché en V0',
        onPressed: null,
      ),
      const ToolbarCapsuleButton(
        icon: CupertinoIcons.search,
        tooltip:
            'Recherche narrative à venir — aucune recherche globale branchée en V0',
        onPressed: null,
      ),
      const ToolbarCapsuleButton(
        icon: CupertinoIcons.bell,
        tooltip: 'Notifications indisponibles — aucune source fiable en V0',
        onPressed: null,
      ),
    ],
  )
```

`top_toolbar_test.dart` — assertions NS-HOME-12 :

```dart
expect(find.text('Carte'), findsNothing);
expect(find.text('Affichage'), findsNothing);
expect(find.text('Calques'), findsNothing);

ToolbarCapsuleButton buttonWithTooltip(String tooltip) {
  return tester.widget<ToolbarCapsuleButton>(
    find.byWidgetPredicate(
      (widget) => widget is ToolbarCapsuleButton && widget.tooltip == tooltip,
    ),
  );
}

expect(
  buttonWithTooltip(
          'Nouvelle storyline à venir — création non branchée en V0')
      .onPressed,
  isNull,
);
expect(
  buttonWithTooltip(
          'Validation narrative à venir — aucun validateur global branché en V0')
      .onPressed,
  isNull,
);
expect(
  buttonWithTooltip(
          'Recherche narrative à venir — aucune recherche globale branchée en V0')
      .onPressed,
  isNull,
);
expect(
  buttonWithTooltip('Notifications indisponibles — aucune source fiable en V0')
      .onPressed,
  isNull,
);
expect(
  find.byWidgetPredicate(
    (widget) => widget is ToolbarCapsuleButton && widget.tooltip == 'New Map',
  ),
  findsNothing,
);
expect(
  find.byWidgetPredicate(
    (widget) =>
        widget is ToolbarCapsuleButton &&
        widget.tooltip == 'Masquer/Afficher le panneau des calques',
  ),
  findsNothing,
);
```

`narrative_overview_shell_navigation_test.dart` — screenshot NS-HOME-12 :

```dart
testWidgets(
  'NarrativeOverviewWorkspace captures NS-HOME-12 top bar screenshots when requested',
  (tester) async {
    const captureDesktop =
        bool.fromEnvironment('NS_HOME_12_CAPTURE_TOP_BAR_DESKTOP');
    const captureFocus =
        bool.fromEnvironment('NS_HOME_12_CAPTURE_TOP_BAR_FOCUS');
    if (!captureDesktop && !captureFocus) {
      return;
    }

    await _loadShellScreenshotFonts();
    await pumpEditorShellPage(
      tester,
      initialState: EditorState(
        projectRootPath: '/tmp/ns_home_12_test_project',
        workspaceMode: EditorWorkspaceMode.narrativeOverview,
        project: _minimalProject('test_project'),
      ),
      surfaceSize:
          captureFocus ? const Size(1600, 700) : const Size(1600, 1000),
    );
    await tester.pump(const Duration(milliseconds: 100));

    final screenshotFile = File(
      '../../reports/narrativeStudio/ui/screenshots/'
      '${captureFocus ? 'ns_home_12_top_bar_action_focus.png' : 'ns_home_12_top_bar_desktop.png'}',
    );
    screenshotFile.parent.createSync(recursive: true);
    await expectLater(
      find.byType(EditorShellPage),
      matchesGoldenFile(screenshotFile.absolute.path),
    );

    expect(screenshotFile.existsSync(), isTrue);
  },
);
```

### Confirmation screenshots

```text
reports/narrativeStudio/ui/screenshots/ns_home_12_top_bar_desktop.png:      PNG image data, 1600 x 1000, 8-bit/color RGBA, non-interlaced
reports/narrativeStudio/ui/screenshots/ns_home_12_top_bar_action_focus.png: PNG image data, 1600 x 700, 8-bit/color RGBA, non-interlaced
```

```text
reports/narrativeStudio/ui/screenshots/ns_home_12_top_bar_desktop.png May 27 15:04:48 2026 240762
reports/narrativeStudio/ui/screenshots/ns_home_12_top_bar_action_focus.png May 27 15:04:52 2026 167664
```

## 17. Auto-review critique

- Le lot ne crée pas d'action fake active : les futures actions narratives ont `onPressed: null`.
- Le lot est conditionnel à `narrativeOverview`, ce qui réduit le risque de casser les autres workspaces.
- Les tests vérifient explicitement l'absence de `New Map`, `Calques`, `Narrative Overview`, et l'état désactivé des affordances.
- La top bar reste encore icon-only sur les actions futures ; c'est acceptable en V0 mais il faudra traiter la lisibilité textuelle dans un prochain lot.
- La grosse variation de diff dans `top_toolbar.dart` vient surtout du fait que des groupes existants sont désormais enveloppés dans `if (!isNarrativeOverview)`.

## 18. Regard critique sur le prompt

Le prompt est bien cadré : il identifie le risque réel de la top bar sans demander une refonte prématurée.

Le point délicat est l'ambiguïté entre "ne pas créer de faux boutons" et "ajouter des affordances". Le compromis retenu est volontairement strict : les affordances existent visuellement mais restent désactivées, nommées comme `à venir`, et testées comme non actionnables.

Le prompt demande aussi de vérifier les autres workspaces ; les tests existants `top_toolbar_test.dart`, `editor_selectors_test.dart`, `status_bar_test.dart` et les tests shell overview couvrent ce risque sans élargir inutilement le lot.
