# NS-HOME-10 — Narrative Studio Shell Chrome Alignment V0

## 1. Résumé exécutif

NS-HOME-10 aligne le chrome existant autour de `Narrative Studio / Aperçu` sans refondre la top bar, la sidebar ou le shell global.

Le lot livre trois ajustements ciblés :

- la toolbar affiche maintenant `Narrative Studio / Aperçu` au lieu de `Narrative Overview` pour le mode `narrativeOverview` ;
- le bouton toolbar d'accès à l'aperçu utilise un tooltip français : `Ouvrir Narrative Studio / Aperçu` ;
- le status bar global masque `Locale : FR` et `v0.3.0` uniquement en mode `EditorWorkspaceMode.narrativeOverview`, afin de ne plus contredire le footer honnête de la page Overview.

Le contenu interne de la page n'a pas été modifié. Aucun read model, aucun modèle `map_core`, aucun runtime, gameplay ou battle n'a été touché.

Deux screenshots full shell ont été produits :

- `reports/narrativeStudio/ui/screenshots/ns_home_10_shell_chrome_desktop.png`
- `reports/narrativeStudio/ui/screenshots/ns_home_10_shell_chrome_footer.png`

## 2. Rappel du scope NS-HOME-10

Objectif du lot :

- améliorer le vocabulaire chrome autour de l'Overview ;
- clarifier l'entrée `Narrative Studio / Aperçu` dans le shell existant ;
- éviter que le status bar global fasse croire que `FR` ou `v0.3.0` sont des métadonnées narratives ;
- conserver les anciennes surfaces de navigation ;
- ne pas ajouter de données métier.

Non-objectifs respectés :

- pas de top bar finale façon image cible ;
- pas de sidebar finale ;
- pas de bouton fake `Nouvelle storyline`, `Valider` ou notifications ;
- pas de vraie activité récente ;
- pas de tags réels ;
- pas de modification de `NarrativeOverviewReadModel` ;
- pas de modification de `map_core`, `map_runtime`, `map_gameplay` ou `map_battle`.

## 3. Audit du chrome existant

Sources et fichiers relus :

- `AGENTS.md`
- `agent_rules.md`
- `skills/README.md`
- `MVP Selbrume/road_map_global.md`
- `MVP Selbrume/road_map_phase_1.md`
- rapports NS-HOME-00 à NS-HOME-09 ;
- `packages/map_editor/lib/src/features/editor/state/models/editor_workspace_mode.dart`
- `packages/map_editor/lib/src/features/editor/application/editor_workspace_controller.dart`
- `packages/map_editor/lib/src/features/editor/state/editor_notifier.dart`
- `packages/map_editor/lib/src/features/editor/state/editor_selectors.dart`
- `packages/map_editor/lib/src/features/editor/state/editor_state.dart`
- `packages/map_editor/lib/src/ui/editor_shell_page.dart`
- `packages/map_editor/lib/src/ui/shared/top_toolbar.dart`
- `packages/map_editor/lib/src/ui/shared/status_bar.dart`
- `packages/map_editor/lib/src/ui/panels/project_explorer_panel.dart`
- `packages/map_editor/lib/src/ui/panels/narrative_library_panel.dart`
- `packages/map_editor/lib/src/ui/canvas/narrative_workspace_canvas.dart`
- `packages/map_editor/lib/src/ui/canvas/narrative_overview_workspace.dart`
- tests shell / toolbar / status bar associés.

Constats :

- `editor_selectors.dart` exposait déjà le titre `Narrative Studio / Aperçu` et le sous-titre auteur ;
- `NarrativeLibraryPanel` exposait déjà `Aperçu`, `Histoire globale`, `Étape`, `Cinématique`, `Dialogue` ;
- `ProjectExplorerPanel` marquait déjà `Narrative Studio` comme sélectionné pour `narrativeOverview` ;
- `top_toolbar.dart` gardait encore le label visible `Narrative Overview` ;
- `status_bar.dart` affichait toujours `Locale : FR` et `v0.3.0` en largeur large, sans distinction du workspace.

## 4. Fichiers créés / modifiés

Fichiers modifiés :

- `packages/map_editor/lib/src/ui/shared/top_toolbar.dart`
- `packages/map_editor/lib/src/ui/shared/status_bar.dart`
- `packages/map_editor/test/top_toolbar_test.dart`
- `packages/map_editor/test/status_bar_test.dart`
- `packages/map_editor/test/editor_selectors_test.dart`
- `packages/map_editor/test/ui/canvas/narrative_overview_shell_navigation_test.dart`

Fichiers créés :

- `reports/narrativeStudio/ui/screenshots/ns_home_10_shell_chrome_desktop.png`
- `reports/narrativeStudio/ui/screenshots/ns_home_10_shell_chrome_footer.png`
- `reports/narrativeStudio/ui/ns_home_10_narrative_studio_shell_chrome_alignment.md`

Fichiers explicitement non modifiés :

- `packages/map_editor/lib/src/features/narrative/application/overview/narrative_overview_read_model.dart`
- `packages/map_core/**`
- `packages/map_runtime/**`
- `packages/map_gameplay/**`
- `packages/map_battle/**`

## 5. UI / shell chrome alignment réalisé

Dans `top_toolbar.dart` :

- label workspace :
  - avant : `Narrative Overview`
  - après : `Narrative Studio / Aperçu`
- tooltip de la capsule overview :
  - avant : `Switch to Narrative Overview`
  - après : `Ouvrir Narrative Studio / Aperçu`

Dans `status_bar.dart` :

- ajout d'un test de mode :

```dart
final isNarrativeOverview =
    state.workspaceMode == EditorWorkspaceMode.narrativeOverview;
```

- masquage des segments locale/version uniquement dans ce mode :

```dart
if (isWide && !isNarrativeOverview) ...[
  ...
]
```

Les autres workspaces conservent le comportement existant.

## 6. Décision sur le status bar global

Décision retenue : option A du prompt.

En mode `narrativeOverview`, le status bar global ne rend plus `Locale : FR` ni `v0.3.0`.

Raison :

- le footer Overview indique honnêtement `Locale : non définie` et `Version : non définie` ;
- `FR` / `v0.3.0` ne viennent pas du read model Overview ;
- les afficher au niveau global pendant l'Overview pouvait les faire passer pour des métadonnées narratives réelles ;
- le changement est strictement limité au mode `narrativeOverview`.

## 7. Actions shell conservées / non créées

Actions conservées :

- les capsules toolbar existantes restent présentes ;
- les anciens studios narratifs restent accessibles ;
- le Project Explorer conserve son architecture actuelle ;
- le status bar conserve `Prêt`, synchronisation, sauvegarde, projet et zoom.

Actions non créées :

- pas de bouton `Nouvelle storyline` ;
- pas de bouton `Valider` ;
- pas de recherche finale ;
- pas de centre de notifications ;
- pas de fausse notification ;
- pas de validation narrative branchée artificiellement.

## 8. Ce qui reste volontairement hors scope

La sidebar finale de l'image cible n'est pas implémentée.

Le Project Explorer reste le chrome actuel. Il marque bien `Narrative Studio` comme sélectionné en mode Overview, mais le screenshot desktop montre encore l'ordre existant du panel, avec d'autres modules au-dessus. Reordonner ou reconstruire la navigation latérale doit rester un lot séparé.

Les libellés historiques `Global Story`, `Step Studio`, `Cutscene Studio` et `Dialogue Studio` restent en partie anglais dans certains endroits du shell existant. NS-HOME-10 ne renomme que l'entrée Overview visible comme incohérente.

## 9. Tests ajoutés / modifiés

Ajouts :

- `top_toolbar_test.dart` vérifie le label `Narrative Studio / Aperçu`, le tooltip français et l'absence de `Narrative Overview` visible ;
- `status_bar_test.dart` vérifie qu'en mode `narrativeOverview`, `Locale : FR` et `v0.3.0` ne sont pas affichés ;
- `narrative_overview_shell_navigation_test.dart` vérifie le chrome full shell, la sélection `ProjectExplorerModuleCard`, les studios existants, l'absence de boutons fake et les screenshots NS-HOME-10.

Adaptation :

- `editor_selectors_test.dart` avait une assertion obsolète sur l'ancien texte anglais `battle-ready rosters`; elle a été alignée sur le sous-titre français réel déjà présent dans le code : `prêtes au combat`.

## 10. Visual Gate

Screenshots produits :

- desktop : `reports/narrativeStudio/ui/screenshots/ns_home_10_shell_chrome_desktop.png` (`1600 x 1000`) ;
- footer : `reports/narrativeStudio/ui/screenshots/ns_home_10_shell_chrome_footer.png` (`1600 x 1300`).

Méthode :

- widget test full shell `EditorShellPage` ;
- `matchesGoldenFile(...)` avec `--update-goldens` ;
- chargement de polices système déjà utilisé par les screenshots NS-HOME-09 ;
- scroll programmatique vers `narrative-overview-footer` pour le screenshot footer.

Comparaison visuelle :

- amélioration depuis NS-HOME-09 : le status bar ne montre plus `Locale : FR` ni `v0.3.0` pendant l'Overview ;
- le stage header indique clairement `Narrative Studio / Aperçu` ;
- le footer Overview reste visible avec `Locale : non définie` et `Version : non définie` ;
- la toolbar reste le chrome existant, pas la top bar finale de l'image cible ;
- le Project Explorer reste l'explorer actuel, pas la sidebar finale de l'image cible ;
- aucune activité récente, notification, storyline ou validation fake n'apparaît dans le chrome.

Problème / limite observée :

- le screenshot desktop garde l'ordre actuel du Project Explorer ; `Narrative Studio` est sélectionné dans l'arbre de widgets, mais pas forcément la carte la plus visible dans la capture à cause de l'explorer existant. Ce point est volontairement reporté.

Correction après inspection :

- le test screenshot footer utilisait d'abord la `ListView` comme `Scrollable`; il a été corrigé pour cibler le vrai descendant `Scrollable`.

## 11. Commandes exécutées

```bash
git status --short --untracked-files=all
git branch --show-current
flutter test test/top_toolbar_test.dart test/status_bar_test.dart test/ui/canvas/narrative_overview_shell_navigation_test.dart
flutter test --update-goldens test/ui/canvas/narrative_overview_shell_navigation_test.dart --dart-define=NS_HOME_10_CAPTURE_SHELL_DESKTOP=true
flutter test --update-goldens test/ui/canvas/narrative_overview_shell_navigation_test.dart --dart-define=NS_HOME_10_CAPTURE_SHELL_FOOTER=true
flutter test test/ui/canvas/narrative_overview_workspace_test.dart test/ui/canvas/narrative_overview_shell_navigation_test.dart
flutter test test/top_toolbar_test.dart test/editor_selectors_test.dart test/status_bar_test.dart test/ui/shell/pokemap_bottom_bar_redesign_test.dart
flutter analyze
flutter analyze --no-fatal-infos lib/src/ui/shared/top_toolbar.dart lib/src/ui/shared/status_bar.dart test/top_toolbar_test.dart test/status_bar_test.dart test/ui/canvas/narrative_overview_shell_navigation_test.dart test/editor_selectors_test.dart
dart format lib/src/ui/shared/top_toolbar.dart lib/src/ui/shared/status_bar.dart test/top_toolbar_test.dart test/status_bar_test.dart test/ui/canvas/narrative_overview_shell_navigation_test.dart test/editor_selectors_test.dart
file reports/narrativeStudio/ui/screenshots/ns_home_10_shell_chrome_desktop.png reports/narrativeStudio/ui/screenshots/ns_home_10_shell_chrome_footer.png
stat -f '%N %Sm %z' reports/narrativeStudio/ui/screenshots/ns_home_10_shell_chrome_desktop.png reports/narrativeStudio/ui/screenshots/ns_home_10_shell_chrome_footer.png
```

## 12. Résultats des tests

Phase RED observée avant correction :

```text
StatusBar hides global locale and version metadata in Narrative Overview [E]
Expected: no matching candidates
Actual: Found 1 widget with text "Locale : FR"

TopToolbar uses the French Narrative Studio overview chrome label [E]
Expected: exactly one matching candidate
Actual: Found 0 widgets with text "test_project  •  Narrative Studio / Aperçu"

EditorShellPage presents coherent Narrative Studio overview chrome [E]
Actual: Text("test_project  •  Narrative Overview")
```

Tests Overview / shell après correction :

```text
flutter test test/ui/canvas/narrative_overview_workspace_test.dart test/ui/canvas/narrative_overview_shell_navigation_test.dart
...
00:02 +32: All tests passed!
```

Tests toolbar / selectors / status bar :

```text
flutter test test/top_toolbar_test.dart test/editor_selectors_test.dart test/status_bar_test.dart test/ui/shell/pokemap_bottom_bar_redesign_test.dart
...
00:01 +27: All tests passed!
```

Screenshots :

```text
flutter test --update-goldens test/ui/canvas/narrative_overview_shell_navigation_test.dart --dart-define=NS_HOME_10_CAPTURE_SHELL_DESKTOP=true
...
00:01 +5: All tests passed!

flutter test --update-goldens test/ui/canvas/narrative_overview_shell_navigation_test.dart --dart-define=NS_HOME_10_CAPTURE_SHELL_FOOTER=true
...
00:01 +5: All tests passed!
```

## 13. Résultats analyze

Analyse globale :

```text
flutter analyze
Analyzing map_editor...
error • The named parameter 'dbSymbol' isn't defined • lib/src/application/services/pokemon_sdk_move_catalog_converter.dart:58:7 • undefined_named_parameter
error • Undefined class 'PokemonMoveAimedTarget' • lib/src/application/services/pokemon_sdk_move_catalog_converter.dart:239:3 • undefined_class
error • The method 'fetchPokemonSdkStudioProjectPayload' isn't defined for the type 'PokemonExternalSourceRepository' • lib/src/application/use_cases/sync_pokemon_sdk_moves_catalog_use_case.dart:58:10 • undefined_method
warning • The library 'package:map_editor/src/ui/canvas/pokedex_workspace/pokedex_workspace_page.dart' doesn't export a member with the shown name 'showPokedexImportFlowSheet' • lib/src/ui/canvas/pokedex_workspace_views.dart:17:9 • undefined_shown_name
348 issues found. (ran in 2.5s)
```

Interprétation : échec global préexistant hors NS-HOME-10, principalement Pokémon SDK / Pokédex et infos de lint historiques.

Analyse ciblée :

```text
flutter analyze --no-fatal-infos lib/src/ui/shared/top_toolbar.dart lib/src/ui/shared/status_bar.dart test/top_toolbar_test.dart test/status_bar_test.dart test/ui/canvas/narrative_overview_shell_navigation_test.dart test/editor_selectors_test.dart
Analyzing 6 items...

info • Use 'const' with the constructor to improve performance • test/editor_selectors_test.dart:45:63 • prefer_const_constructors
...
info • Use 'const' with the constructor to improve performance • test/editor_selectors_test.dart:240:18 • prefer_const_constructors

14 issues found. (ran in 2.0s)
```

La commande ciblée sort avec code `0` grâce à `--no-fatal-infos`. Les 14 infos sont des `prefer_const_constructors` préexistants dans `editor_selectors_test.dart`; aucun fichier de production touché par NS-HOME-10 ne remonte d'erreur.

## 14. Limites

- Le Project Explorer n'est pas encore réorganisé pour mettre `Narrative Studio` en première intention visuelle.
- Les anciens sous-studios gardent des labels historiques en anglais dans certaines surfaces.
- Les screenshots full shell montrent le chrome existant, pas le shell final de l'image cible.
- `flutter analyze` global reste rouge à cause de dettes hors lot.

## 15. Prochain lot recommandé

Prochain lot recommandé :

```text
NS-HOME-11 — Narrative Studio Sidebar / Workspace Navigation Alignment V0
```

Objectif proposé : traiter la prochaine tension visible du full shell sans refaire toute l'application :

- rendre l'entrée Narrative Studio plus immédiatement lisible dans la navigation latérale ;
- clarifier l'ordre / l'expansion du Project Explorer quand on est en workspace narratif ;
- harmoniser les labels des anciens studios narratifs sans casser leurs routes ;
- produire un nouveau full-shell Visual Gate.

## 16. Evidence Pack

### Git initial

```text
git branch --show-current
main

git status --short --untracked-files=all
<aucune sortie au début du lot>
```

### Fichiers créés

```text
reports/narrativeStudio/ui/screenshots/ns_home_10_shell_chrome_desktop.png
reports/narrativeStudio/ui/screenshots/ns_home_10_shell_chrome_footer.png
reports/narrativeStudio/ui/ns_home_10_narrative_studio_shell_chrome_alignment.md
```

### Fichiers modifiés

```text
packages/map_editor/lib/src/ui/shared/status_bar.dart
packages/map_editor/lib/src/ui/shared/top_toolbar.dart
packages/map_editor/test/editor_selectors_test.dart
packages/map_editor/test/status_bar_test.dart
packages/map_editor/test/top_toolbar_test.dart
packages/map_editor/test/ui/canvas/narrative_overview_shell_navigation_test.dart
```

### Screenshot files

```text
reports/narrativeStudio/ui/screenshots/ns_home_10_shell_chrome_desktop.png: PNG image data, 1600 x 1000, 8-bit/color RGBA, non-interlaced
reports/narrativeStudio/ui/screenshots/ns_home_10_shell_chrome_footer.png:  PNG image data, 1600 x 1300, 8-bit/color RGBA, non-interlaced
reports/narrativeStudio/ui/screenshots/ns_home_10_shell_chrome_desktop.png May 27 03:59:58 2026 250240
reports/narrativeStudio/ui/screenshots/ns_home_10_shell_chrome_footer.png May 27 04:00:02 2026 252060
```

### Extraits complets des sections modifiées

`status_bar.dart` :

```diff
+import '../../features/editor/state/models/editor_workspace_mode.dart';
+
+    final isNarrativeOverview =
+        state.workspaceMode == EditorWorkspaceMode.narrativeOverview;
...
-              if (isWide) ...[
+              if (isWide && !isNarrativeOverview) ...[
```

`top_toolbar.dart` :

```diff
-            tooltip: 'Switch to Narrative Overview',
+            tooltip: 'Ouvrir Narrative Studio / Aperçu',
...
-          EditorWorkspaceMode.narrativeOverview => 'Narrative Overview',
+          EditorWorkspaceMode.narrativeOverview => 'Narrative Studio / Aperçu',
```

`status_bar_test.dart` :

```dart
testWidgets(
    'hides global locale and version metadata in Narrative Overview',
    (tester) async {
  await pumpStatusBarHarness(
    tester,
    initialState: const EditorState(
      workspaceMode: EditorWorkspaceMode.narrativeOverview,
      statusMessage: 'Aperçu narratif prêt',
    ),
    surfaceSize: const Size(1280, 200),
  );

  expect(find.text('Aperçu narratif prêt'), findsOneWidget);
  expect(find.text('Locale : FR'), findsNothing);
  expect(find.text('v0.3.0'), findsNothing);
});
```

`top_toolbar_test.dart` :

```dart
testWidgets('uses the French Narrative Studio overview chrome label',
    (tester) async {
  await pumpTopToolbarHarness(
    tester,
    initialState: EditorState(
      projectRootPath: '/tmp/top_toolbar_narrative_overview',
      project: buildShellChromeProject(name: 'test_project'),
      workspaceMode: EditorWorkspaceMode.narrativeOverview,
    ),
  );

  expect(
    find.text('test_project  •  Narrative Studio / Aperçu'),
    findsOneWidget,
  );
  expect(find.textContaining('Narrative Overview'), findsNothing);

  final overviewButton = tester.widget<ToolbarCapsuleButton>(
    find.byWidgetPredicate(
      (widget) =>
          widget is ToolbarCapsuleButton &&
          widget.tooltip == 'Ouvrir Narrative Studio / Aperçu',
    ),
  );
  expect(overviewButton.selected, isTrue);
  expect(overviewButton.onPressed, isNotNull);
});
```

`editor_selectors_test.dart` :

```diff
-        contains('battle-ready rosters'),
+        contains('prêtes au combat'),
```

`narrative_overview_shell_navigation_test.dart` :

```dart
testWidgets(
  'EditorShellPage presents coherent Narrative Studio overview chrome',
  (tester) async {
    await pumpEditorShellPage(
      tester,
      initialState: EditorState(
        projectRootPath: '/tmp/ns_home_10_test_project',
        workspaceMode: EditorWorkspaceMode.narrativeOverview,
        project: _minimalProject('test_project'),
      ),
      surfaceSize: const Size(1600, 1000),
    );

    expect(find.textContaining('Narrative Studio / Aperçu'), findsWidgets);
    expect(find.textContaining('Vue d’ensemble auteur'), findsWidgets);
    expect(find.textContaining('Narrative Overview'), findsNothing);

    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is ProjectExplorerModuleCard &&
            widget.title == 'Narrative Studio' &&
            widget.selected,
      ),
      findsOneWidget,
    );

    expect(find.text('Aperçu'), findsWidgets);
    expect(find.text('Histoire globale'), findsOneWidget);
    expect(find.text('Étape'), findsOneWidget);
    expect(find.text('Cinématique'), findsOneWidget);
    expect(find.text('Dialogue'), findsWidgets);

    expect(find.text('Locale : FR'), findsNothing);
    expect(find.text('v0.3.0'), findsNothing);
    expect(find.text('Nouvelle storyline'), findsNothing);
    expect(find.text('Valider'), findsNothing);
    expect(find.textContaining('Selbrume'), findsNothing);
    expect(find.text('42'), findsNothing);
    expect(find.text('1 236'), findsNothing);
    expect(find.text('1236'), findsNothing);
    expect(find.text('24'), findsNothing);
    expect(find.text('12'), findsNothing);
  },
);
```

```dart
testWidgets(
  'NarrativeOverviewWorkspace captures NS-HOME-10 shell chrome screenshots when requested',
  (tester) async {
    const captureDesktop =
        bool.fromEnvironment('NS_HOME_10_CAPTURE_SHELL_DESKTOP');
    const captureFooter =
        bool.fromEnvironment('NS_HOME_10_CAPTURE_SHELL_FOOTER');
    if (!captureDesktop && !captureFooter) {
      return;
    }

    await _loadShellScreenshotFonts();
    await pumpEditorShellPage(
      tester,
      initialState: EditorState(
        projectRootPath: '/tmp/ns_home_10_test_project',
        workspaceMode: EditorWorkspaceMode.narrativeOverview,
        project: _minimalProject('test_project'),
      ),
      surfaceSize:
          captureFooter ? const Size(1600, 1300) : const Size(1600, 1000),
    );
    await tester.pump(const Duration(milliseconds: 100));

    if (captureFooter) {
      await tester.scrollUntilVisible(
        find.byKey(const ValueKey('narrative-overview-footer')),
        650,
        scrollable: find.descendant(
          of: find.byKey(const ValueKey('narrative-overview-scroll')),
          matching: find.byType(Scrollable),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));
    }

    final screenshotFile = File(
      '../../reports/narrativeStudio/ui/screenshots/'
      '${captureFooter ? 'ns_home_10_shell_chrome_footer.png' : 'ns_home_10_shell_chrome_desktop.png'}',
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

### Git final

```text
git status --short --untracked-files=all
 M packages/map_editor/lib/src/ui/shared/status_bar.dart
 M packages/map_editor/lib/src/ui/shared/top_toolbar.dart
 M packages/map_editor/test/editor_selectors_test.dart
 M packages/map_editor/test/status_bar_test.dart
 M packages/map_editor/test/top_toolbar_test.dart
 M packages/map_editor/test/ui/canvas/narrative_overview_shell_navigation_test.dart
?? reports/narrativeStudio/ui/ns_home_10_narrative_studio_shell_chrome_alignment.md
?? reports/narrativeStudio/ui/screenshots/ns_home_10_shell_chrome_desktop.png
?? reports/narrativeStudio/ui/screenshots/ns_home_10_shell_chrome_footer.png

git diff --stat
 .../map_editor/lib/src/ui/shared/status_bar.dart   |  5 +-
 .../map_editor/lib/src/ui/shared/top_toolbar.dart  |  4 +-
 .../map_editor/test/editor_selectors_test.dart     |  2 +-
 packages/map_editor/test/status_bar_test.dart      | 17 ++++
 packages/map_editor/test/top_toolbar_test.dart     | 28 +++++++
 .../narrative_overview_shell_navigation_test.dart  | 97 ++++++++++++++++++++++
 6 files changed, 149 insertions(+), 4 deletions(-)

git diff --name-only
packages/map_editor/lib/src/ui/shared/status_bar.dart
packages/map_editor/lib/src/ui/shared/top_toolbar.dart
packages/map_editor/test/editor_selectors_test.dart
packages/map_editor/test/status_bar_test.dart
packages/map_editor/test/top_toolbar_test.dart
packages/map_editor/test/ui/canvas/narrative_overview_shell_navigation_test.dart

git diff --check
<aucune sortie>
```

Note : les fichiers non trackés (`rapport` et `screenshots`) ne sont pas listés par `git diff --stat` / `git diff --name-only`. Ils sont listés par `git status` et dans l'inventaire des fichiers créés.

## 17. Auto-review critique

Ce qui est prouvé :

- le label visible `Narrative Overview` a disparu de la toolbar en mode Overview ;
- le status bar ne montre plus `Locale : FR` ni `v0.3.0` en mode `narrativeOverview` ;
- les autres workspaces conservent le comportement wide du status bar ;
- les screenshots full shell sont générés ;
- aucun fake bouton `Nouvelle storyline` / `Valider` n'a été ajouté ;
- aucun package runtime/gameplay/battle/core n'a été touché.

Ce qui n'est pas prouvé :

- une navigation latérale finale premium ;
- une top bar finale comparable pixel à l'image ;
- une vraie source globale fiable pour locale/version ;
- un réordonnancement du Project Explorer.

Risque principal :

- le Project Explorer peut encore raconter une histoire visuelle trop large (`World Explorer`, `Tile Library`) alors que l'utilisateur est dans `Narrative Studio / Aperçu`. Ce risque doit être traité par un lot dédié, pas par une retouche opportuniste dans NS-HOME-10.

## 18. Regard critique sur le prompt

Le prompt est bien cadré : il force à traiter le risque du chrome sans retomber dans la création de la page finale.

Point de vigilance : les critères demandent à la fois de ne pas refaire la sidebar et de vérifier que le Project Explorer rend l'entrée `Narrative Studio` lisible. Dans le repo actuel, la sélection existe mais la visibilité immédiate dans le screenshot dépend de l'ordre historique du Project Explorer. J'ai donc choisi de tester la sélection réelle sans refondre l'IA latérale, et de recommander NS-HOME-11 pour traiter ce sujet proprement.
