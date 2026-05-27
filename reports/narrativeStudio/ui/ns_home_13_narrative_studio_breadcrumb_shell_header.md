# NS-HOME-13 — Narrative Studio Breadcrumb / Shell Header Refinement V0

## 1. Résumé exécutif

NS-HOME-13 affine le contexte supérieur de la page `Narrative Studio / Aperçu` sans reconstruire la top bar finale.

Le workspace Overview affiche maintenant un breadcrumb informatif non cliquable :

```text
PokeMap / Narrative Studio / Aperçu
```

Le titre interne reste sobre (`Aperçu`) pour éviter de répéter lourdement le header shell, tandis que le sous-titre devient plus explicite :

```text
Vue d’ensemble auteur : métriques disponibles, statuts honnêtes et prochaines sections du dashboard.
```

Aucune action future n'a été activée. Les affordances NS-HOME-12 restent désactivées.

## 2. Rappel du scope NS-HOME-13

Objectif du lot :

- clarifier le contexte `PokeMap → Narrative Studio → Aperçu` ;
- garder l'écran dans une logique dashboard auteur ;
- éviter les termes runtime / progression joueur ;
- ne pas créer de router global ou bouton Home fake ;
- préserver la top bar NS-HOME-12, la sidebar NS-HOME-11 et le status bar NS-HOME-10 ;
- produire deux screenshots Visual Gate.

Hors scope respecté :

- pas de top bar finale complète ;
- pas de sidebar finale complète ;
- pas de vraie storyline ;
- pas de validation narrative globale ;
- pas de recherche globale ;
- pas de notifications ;
- pas de modification du read model ou des modèles projet ;
- pas de runtime/gameplay/battle/map_core touché.

## 3. Audit du header / breadcrumb existant

Avant NS-HOME-13, le shell indiquait déjà `Narrative Studio / Aperçu` dans le chrome, mais la page interne commençait seulement par :

```text
Aperçu
Vue d’ensemble auteur du Narrative Studio.
```

Ce header était honnête mais peu contextualisé. Il ne montrait pas clairement la hiérarchie `PokeMap / Narrative Studio / Aperçu` visible dans l'image cible.

Le screenshot NS-HOME-12 montrait aussi que dupliquer `Narrative Studio / Aperçu` dans plusieurs niveaux pouvait vite devenir lourd. Le lot retient donc un breadcrumb informatif + un titre court.

## 4. Fichiers créés / modifiés

Fichiers créés :

- `reports/narrativeStudio/ui/ns_home_13_narrative_studio_breadcrumb_shell_header.md`
- `reports/narrativeStudio/ui/screenshots/ns_home_13_breadcrumb_header_desktop.png`
- `reports/narrativeStudio/ui/screenshots/ns_home_13_breadcrumb_header_focus.png`

Fichiers modifiés :

- `packages/map_editor/lib/src/ui/canvas/narrative_overview_workspace.dart`
- `packages/map_editor/test/ui/canvas/narrative_overview_workspace_test.dart`
- `packages/map_editor/test/ui/canvas/narrative_overview_shell_navigation_test.dart`

## 5. Décision breadcrumb / header retenue

Décision : ajouter un breadcrumb interne V0, purement informatif et non cliquable.

Raisons :

- le shell indique déjà le workspace courant ;
- l'image cible suggère une hiérarchie visuelle ;
- un breadcrumb textuel clarifie le contexte sans créer de navigation fictive ;
- le titre interne peut rester `Aperçu`, ce qui évite le doublon `Narrative Studio / Aperçu` répété deux fois dans la même zone.

Le breadcrumb n'est pas un bouton. Il n'ouvre pas Home. Il ne crée pas de route.

## 6. UI / header alignment réalisé

Dans `NarrativeOverviewWorkspace` :

- ajout de `_OverviewPageHeader` ;
- ajout de `_BreadcrumbSegment` et `_BreadcrumbSeparator` ;
- breadcrumb :
  - `PokeMap` ;
  - `Narrative Studio` ;
  - `Aperçu` en chip active ;
- titre interne :
  - `Aperçu` ;
- sous-titre :
  - `Vue d’ensemble auteur : métriques disponibles, statuts honnêtes et prochaines sections du dashboard.`

La page conserve ensuite les blocs existants :

- Projet ;
- Indicateurs auteur ;
- Histoire principale ;
- Modules narratifs ;
- Structure narrative ;
- Données à venir ;
- Footer metadata.

## 7. Actions volontairement non activées

Les affordances NS-HOME-12 restent inchangées :

- `Aperçu` actif ;
- `Nouvelle storyline` désactivée ;
- `Validation narrative` désactivée ;
- `Recherche narrative` désactivée ;
- `Notifications` désactivées, sans badge.

Aucune nouvelle action n'a été créée dans le breadcrumb.

## 8. Ce qui reste volontairement hors scope

- Breadcrumb final connecté à un vrai routeur.
- Bouton Home actif.
- Top bar finale de l'image cible.
- Actions narratives réelles.
- Recherche / notifications / paramètres.
- Refonte de `EditorShellPage`.
- Refonte de la sidebar.

## 9. Tests ajoutés / modifiés

Dans `narrative_overview_workspace_test.dart` :

- vérification du header `narrative-overview-page-header` ;
- vérification du breadcrumb `narrative-overview-breadcrumb` ;
- vérification de `PokeMap`, `Narrative Studio`, `Aperçu` ;
- vérification que `PokeMap` n'est pas un `CupertinoButton` ;
- vérification du nouveau sous-titre auteur ;
- vérification que `Narrative Overview`, `progression`, `jouable` ne sont pas rendus ;
- adaptation d'un test responsive qui attendait auparavant une seule occurrence de `Aperçu`.

Dans `narrative_overview_shell_navigation_test.dart` :

- ajout du test screenshot NS-HOME-13 avec :
  - `NS_HOME_13_CAPTURE_BREADCRUMB_HEADER_DESKTOP` ;
  - `NS_HOME_13_CAPTURE_BREADCRUMB_HEADER_FOCUS`.

## 10. Visual Gate

Screenshots produits :

- `reports/narrativeStudio/ui/screenshots/ns_home_13_breadcrumb_header_desktop.png`
- `reports/narrativeStudio/ui/screenshots/ns_home_13_breadcrumb_header_focus.png`

Méthode :

- widget test `EditorShellPage` ;
- `matchesGoldenFile(...)` ;
- `--update-goldens` ;
- tailles :
  - desktop : 1600 x 1000 ;
  - focus : 1600 x 700.

Amélioration depuis NS-HOME-12 :

- le contexte interne est plus clair : `PokeMap / Narrative Studio / Aperçu` ;
- le titre interne ne prétend pas être une nouvelle destination ;
- le sous-titre indique explicitement métriques disponibles, statuts honnêtes, prochaines sections ;
- les actions top bar restent désactivées quand elles ne sont pas branchées.

Breadcrumb ajouté :

- oui, en version informative ;
- pas de bouton Home ;
- pas de route fictive.

Écarts avec l'image cible :

- pas de breadcrumb top bar final ;
- pas de boutons texte finaux ;
- pas de recherche ou notifications actives ;
- la sidebar et la top bar restent les composants existants.

Inspection visuelle :

- desktop : le header est lisible, la sidebar reste stable, le panneau Structure narrative reste visible ;
- focus : le breadcrumb et le début des KPI sont visibles sans overflow ;
- le premier rendu avec titre `Narrative Studio / Aperçu` interne a été jugé trop redondant avec le header shell ; il a été corrigé en titre `Aperçu`.

## 11. Commandes exécutées

```bash
git branch --show-current
git status --short --untracked-files=all

cd packages/map_editor && flutter test test/ui/canvas/narrative_overview_workspace_test.dart
cd packages/map_editor && flutter test test/ui/canvas/narrative_overview_shell_navigation_test.dart
cd packages/map_editor && flutter test test/top_toolbar_test.dart
cd packages/map_editor && flutter test test/editor_selectors_test.dart
cd packages/map_editor && flutter test test/status_bar_test.dart
cd packages/map_editor && flutter test test/ui/canvas/narrative_overview_workspace_test.dart test/ui/canvas/narrative_overview_shell_navigation_test.dart test/top_toolbar_test.dart test/editor_selectors_test.dart test/status_bar_test.dart

cd packages/map_editor && flutter test test/ui/canvas/narrative_overview_shell_navigation_test.dart --update-goldens --dart-define=NS_HOME_13_CAPTURE_BREADCRUMB_HEADER_DESKTOP=true
cd packages/map_editor && flutter test test/ui/canvas/narrative_overview_shell_navigation_test.dart --update-goldens --dart-define=NS_HOME_13_CAPTURE_BREADCRUMB_HEADER_FOCUS=true

cd packages/map_editor && flutter analyze
cd packages/map_editor && flutter analyze --no-fatal-infos lib/src/ui/canvas/narrative_overview_workspace.dart test/ui/canvas/narrative_overview_workspace_test.dart test/ui/canvas/narrative_overview_shell_navigation_test.dart

git diff --check
git diff --stat
git diff --name-only

file reports/narrativeStudio/ui/screenshots/ns_home_13_breadcrumb_header_desktop.png reports/narrativeStudio/ui/screenshots/ns_home_13_breadcrumb_header_focus.png
stat -f '%Sm %z' reports/narrativeStudio/ui/screenshots/ns_home_13_breadcrumb_header_desktop.png reports/narrativeStudio/ui/screenshots/ns_home_13_breadcrumb_header_focus.png
```

## 12. Résultats des tests

### Workspace overview

```text
00:00 +0: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/ui/canvas/narrative_overview_workspace_test.dart
00:00 +0: NarrativeOverviewWorkspace renders a minimal authoring overview from the read model
00:00 +1: NarrativeOverviewWorkspace does not present unavailable modules as real data
00:00 +2: NarrativeOverviewWorkspace renders honest upcoming data states and footer metadata
00:00 +3: NarrativeOverviewWorkspace KPI cards consume read model values
00:00 +4: NarrativeOverviewWorkspace KPI layout renders on a narrower desktop width
00:01 +5: NarrativeOverviewWorkspace renders an honest empty main story card
00:01 +6: NarrativeOverviewWorkspace renders explicit main story data from the read model
00:01 +7: NarrativeOverviewWorkspace explains missing description and fallback chapters
00:01 +8: NarrativeOverviewWorkspace renders ambiguous main story state explicitly
00:01 +9: NarrativeOverviewWorkspace renders honest narrative module cards
00:01 +10: NarrativeOverviewWorkspace module cards consume read model values
00:01 +11: NarrativeOverviewWorkspace module grid keeps previous overview blocks visible
00:01 +12: NarrativeOverviewWorkspace renders an honest structure inspector panel
00:01 +13: NarrativeOverviewWorkspace structure inspector consumes read model counters and chapters
00:01 +14: NarrativeOverviewWorkspace structure inspector shows clean validation as up to date
00:02 +15: NarrativeOverviewWorkspace structure inspector maps warnings to review state
00:02 +16: NarrativeOverviewWorkspace structure inspector maps errors to blocking state
00:02 +17: NarrativeOverviewWorkspace keeps the structure inspector beside the main column on large desktop
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

### Shell navigation

```text
00:00 +0: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/ui/canvas/narrative_overview_shell_navigation_test.dart
00:00 +0: NarrativeWorkspaceCanvas routes overview mode to the overview shell
00:00 +1: NarrativeLibraryPanel exposes overview without removing existing studios
00:00 +2: EditorShellPage presents coherent Narrative Studio overview chrome
00:01 +3: ProjectExplorerPanel prioritizes narrative navigation in overview mode
00:01 +4: NarrativeOverviewWorkspace captures a full editor shell screenshot when requested
00:01 +5: NarrativeOverviewWorkspace captures NS-HOME-11 sidebar navigation screenshots when requested
00:01 +6: NarrativeOverviewWorkspace captures NS-HOME-12 top bar screenshots when requested
00:01 +7: NarrativeOverviewWorkspace captures NS-HOME-13 breadcrumb header screenshots when requested
00:01 +8: NarrativeOverviewWorkspace captures NS-HOME-10 shell chrome screenshots when requested
00:01 +9: All tests passed!
```

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
00:01 +9: TopToolbar keeps map save action in map workspace
00:01 +10: All tests passed!
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

### Régression combinée

```text
00:02 +60: /Users/karim/Project/pokemonProject/packages/map_editor/test/ui/canvas/narrative_overview_workspace_test.dart: NarrativeOverviewWorkspace captures responsive polish medium screenshot when requested
00:02 +61: All tests passed!
```

### Screenshots NS-HOME-13

```text
00:00 +0: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/ui/canvas/narrative_overview_shell_navigation_test.dart
00:00 +0: NarrativeWorkspaceCanvas routes overview mode to the overview shell
00:00 +1: NarrativeLibraryPanel exposes overview without removing existing studios
00:00 +2: EditorShellPage presents coherent Narrative Studio overview chrome
00:01 +3: ProjectExplorerPanel prioritizes narrative navigation in overview mode
00:01 +4: NarrativeOverviewWorkspace captures a full editor shell screenshot when requested
00:01 +5: NarrativeOverviewWorkspace captures NS-HOME-11 sidebar navigation screenshots when requested
00:01 +6: NarrativeOverviewWorkspace captures NS-HOME-12 top bar screenshots when requested
00:01 +7: NarrativeOverviewWorkspace captures NS-HOME-13 breadcrumb header screenshots when requested
00:01 +8: NarrativeOverviewWorkspace captures NS-HOME-10 shell chrome screenshots when requested
00:01 +9: All tests passed!
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
  error • The method 'fetchPokemonSdkStudioProjectPayload' isn't defined for the type 'PokemonExternalSourceRepository' • lib/src/application/use_cases/sync_pokemon_sdk_moves_catalog_use_case.dart:58:10 • undefined_method
...
349 issues found. (ran in 3.2s)
```

Analyse ciblée des fichiers modifiés :

```text
Analyzing 3 items...
No issues found! (ran in 1.3s)
```

Conclusion : aucune erreur d'analyse introduite par NS-HOME-13 sur les fichiers modifiés.

## 14. Limites

- Le breadcrumb est informatif, pas une vraie navigation.
- Le shell conserve encore le header supérieur existant ; le lot ne reconstruit pas la top bar finale.
- Le texte `Narrative Overview` subsiste dans un nom de test historique `StatusBar hides global locale and version metadata in Narrative Overview`, mais il n'est pas une surface utilisateur.
- Les screenshots golden gardent quelques artefacts de fonte sur les contrôles compacts, déjà observés sur NS-HOME-09 à NS-HOME-12.

## 15. Prochain lot recommandé

Prochain lot recommandé :

```text
NS-HOME-14 — Narrative Studio Shell Header Density / Top Strip Harmonization V0
```

Objectif proposé : réduire les redondances restantes entre header shell, top strip et page header, sans activer les actions futures ni reconstruire le shell final.

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
 M packages/map_editor/lib/src/ui/canvas/narrative_overview_workspace.dart
 M packages/map_editor/test/ui/canvas/narrative_overview_shell_navigation_test.dart
 M packages/map_editor/test/ui/canvas/narrative_overview_workspace_test.dart
?? reports/narrativeStudio/ui/ns_home_13_narrative_studio_breadcrumb_shell_header.md
?? reports/narrativeStudio/ui/screenshots/ns_home_13_breadcrumb_header_desktop.png
?? reports/narrativeStudio/ui/screenshots/ns_home_13_breadcrumb_header_focus.png
```

### Git diff stat final

```text
 .../ui/canvas/narrative_overview_workspace.dart    | 93 +++++++++++++++++++++-
 .../narrative_overview_shell_navigation_test.dart  | 38 +++++++++
 .../canvas/narrative_overview_workspace_test.dart  | 30 +++++--
 3 files changed, 153 insertions(+), 8 deletions(-)
```

### Git diff name-only final

```text
packages/map_editor/lib/src/ui/canvas/narrative_overview_workspace.dart
packages/map_editor/test/ui/canvas/narrative_overview_shell_navigation_test.dart
packages/map_editor/test/ui/canvas/narrative_overview_workspace_test.dart
```

### Git diff check final

```text
(aucune sortie)
```

### Fichiers créés

```text
reports/narrativeStudio/ui/ns_home_13_narrative_studio_breadcrumb_shell_header.md
reports/narrativeStudio/ui/screenshots/ns_home_13_breadcrumb_header_desktop.png
reports/narrativeStudio/ui/screenshots/ns_home_13_breadcrumb_header_focus.png
```

### Fichiers modifiés

```text
packages/map_editor/lib/src/ui/canvas/narrative_overview_workspace.dart
packages/map_editor/test/ui/canvas/narrative_overview_workspace_test.dart
packages/map_editor/test/ui/canvas/narrative_overview_shell_navigation_test.dart
```

### Note fichiers non trackés

Le rapport et les screenshots sont non trackés tant que Karim ne les stage pas. Ils ne sont donc pas listés dans `git diff --stat` / `git diff --name-only`.

### Extraits complets des sections modifiées

`narrative_overview_workspace.dart` — header / breadcrumb :

```dart
class NarrativeOverviewWorkspace extends StatelessWidget {
  const NarrativeOverviewWorkspace({
    super.key,
    required this.readModel,
  });

  final NarrativeOverviewReadModel readModel;

  @override
  Widget build(BuildContext context) {
    return ListView(
      key: const ValueKey('narrative-overview-scroll'),
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
      children: [
        const _OverviewPageHeader(),
        const SizedBox(height: 14),
        _OverviewResponsiveBody(readModel: readModel),
      ],
    );
  }
}

class _OverviewPageHeader extends StatelessWidget {
  const _OverviewPageHeader();

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const ValueKey('narrative-overview-page-header'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Wrap(
          key: ValueKey('narrative-overview-breadcrumb'),
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 7,
          runSpacing: 4,
          children: [
            _BreadcrumbSegment(label: 'PokeMap'),
            _BreadcrumbSeparator(),
            _BreadcrumbSegment(label: 'Narrative Studio'),
            _BreadcrumbSeparator(),
            _BreadcrumbSegment(label: 'Aperçu', current: true),
          ],
        ),
        const SizedBox(height: 10),
        Text(
          'Aperçu',
          style: TextStyle(
            color: EditorChrome.primaryLabel(context),
            fontSize: 26,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Vue d’ensemble auteur : métriques disponibles, statuts honnêtes et prochaines sections du dashboard.',
          style: TextStyle(
            color: EditorChrome.subtleLabel(context),
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
```

`narrative_overview_workspace_test.dart` — header assertions :

```dart
expect(
  find.byKey(const ValueKey('narrative-overview-page-header')),
  findsOneWidget,
);
expect(
  find.byKey(const ValueKey('narrative-overview-breadcrumb')),
  findsOneWidget,
);
expect(find.text('PokeMap'), findsOneWidget);
expect(find.widgetWithText(CupertinoButton, 'PokeMap'), findsNothing);
expect(find.text('Narrative Studio'), findsOneWidget);
expect(find.text('Aperçu'), findsWidgets);
expect(
  find.text(
    'Vue d’ensemble auteur : métriques disponibles, statuts honnêtes et prochaines sections du dashboard.',
  ),
  findsOneWidget,
);
expect(find.textContaining('Narrative Overview'), findsNothing);
expect(find.textContaining('progression'), findsNothing);
expect(find.textContaining('jouable'), findsNothing);
```

`narrative_overview_shell_navigation_test.dart` — screenshot NS-HOME-13 :

```dart
testWidgets(
  'NarrativeOverviewWorkspace captures NS-HOME-13 breadcrumb header screenshots when requested',
  (tester) async {
    const captureDesktop =
        bool.fromEnvironment('NS_HOME_13_CAPTURE_BREADCRUMB_HEADER_DESKTOP');
    const captureFocus =
        bool.fromEnvironment('NS_HOME_13_CAPTURE_BREADCRUMB_HEADER_FOCUS');
    if (!captureDesktop && !captureFocus) {
      return;
    }

    await _loadShellScreenshotFonts();
    await pumpEditorShellPage(
      tester,
      initialState: EditorState(
        projectRootPath: '/tmp/ns_home_13_test_project',
        workspaceMode: EditorWorkspaceMode.narrativeOverview,
        project: _minimalProject('test_project'),
      ),
      surfaceSize:
          captureFocus ? const Size(1600, 700) : const Size(1600, 1000),
    );
    await tester.pump(const Duration(milliseconds: 100));

    final screenshotFile = File(
      '../../reports/narrativeStudio/ui/screenshots/'
      '${captureFocus ? 'ns_home_13_breadcrumb_header_focus.png' : 'ns_home_13_breadcrumb_header_desktop.png'}',
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
reports/narrativeStudio/ui/screenshots/ns_home_13_breadcrumb_header_desktop.png: PNG image data, 1600 x 1000, 8-bit/color RGBA, non-interlaced
reports/narrativeStudio/ui/screenshots/ns_home_13_breadcrumb_header_focus.png:   PNG image data, 1600 x 700, 8-bit/color RGBA, non-interlaced
May 27 15:26:02 2026 244660
May 27 15:26:07 2026 169352
```

## 17. Auto-review critique

- Le breadcrumb améliore le contexte sans créer de navigation fictive.
- Le titre interne `Aperçu` évite une répétition excessive avec le header shell.
- Le test vérifie explicitement que `PokeMap` n'est pas un bouton.
- Les actions top bar futures restent sous la couverture NS-HOME-12 et ne sont pas activées.
- Le lot ne touche pas au read model ni aux packages interdits.

Point à surveiller :

- le header shell supérieur et le header interne portent encore des informations proches ; un lot suivant peut harmoniser leur densité.

## 18. Regard critique sur le prompt

Le prompt est bien calibré : il force à traiter le contexte supérieur sans brûler l'étape de la top bar finale.

Le point le plus utile est la clause "ne pas dupliquer sans raison" : l'inspection visuelle a montré qu'un titre interne `Narrative Studio / Aperçu` était trop redondant. La version finale garde donc le breadcrumb complet et un titre interne court.
