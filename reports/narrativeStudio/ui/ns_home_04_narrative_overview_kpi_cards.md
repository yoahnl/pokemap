# NS-HOME-04 — Narrative Overview KPI Cards / Availability States V0

## 1. Résumé exécutif

NS-HOME-04 ajoute la première brique visuelle réelle de la page `Narrative Studio / Aperçu` : une section `Indicateurs auteur` composée de six KPI cards branchées exclusivement sur `NarrativeOverviewReadModel`.

Le lot remplace la présentation textuelle principale des disponibilités par des cartes lisibles et honnêtes pour :

- `Chapitres`
- `Scènes`
- `Cinématiques`
- `Quêtes`
- `Dialogues`
- `Problèmes ouverts`

Les cartes distinguent les états `available`, `empty`, `unavailable`, `notEvaluated`, `outOfScope` et `needsModel` sans convertir une donnée indisponible en faux `0`.

Un screenshot a été produit et inspecté :

```text
reports/narrativeStudio/ui/screenshots/ns_home_04_overview_kpi_cards.png
```

Le lot ne crée pas la page finale de l’image : pas de grande carte `Histoire principale`, pas de grille complète des modules, pas de panneau droit `Structure narrative`, pas d’activité récente, pas de notifications et pas de top bar finale.

## 2. Rappel du scope NS-HOME-04

Objectif réalisé :

```text
Aperçu
-> NarrativeOverviewReadModel réel
-> KPI cards V0
-> availability states honnêtes
-> screenshot
-> critique visuelle
```

Non-objectifs respectés :

- pas de dashboard final complet ;
- pas de faux compteur ;
- pas de donnée Selbrume hardcodée ;
- pas de chiffre copié depuis l’image cible ;
- pas de modification de `map_core` ;
- pas de modification de `map_runtime`, `map_gameplay` ou `map_battle` ;
- pas de provider, repository, lecture disque ou parsing Yarn ;
- pas de build_runner.

## 3. Fichiers créés / modifiés

Fichiers modifiés :

```text
packages/map_editor/lib/src/ui/canvas/narrative_overview_workspace.dart
packages/map_editor/test/ui/canvas/narrative_overview_workspace_test.dart
```

Fichiers créés :

```text
reports/narrativeStudio/ui/screenshots/ns_home_04_overview_kpi_cards.png
reports/narrativeStudio/ui/ns_home_04_narrative_overview_kpi_cards.md
```

## 4. UI créée

La page `NarrativeOverviewWorkspace` affiche maintenant une section `Indicateurs auteur` sous le bloc projet.

Structure créée :

- un conteneur de section cohérent avec `EditorChrome.largeIslandSurfaceColor` ;
- une grille responsive en `Wrap` ;
- six cartes KPI ;
- une icône Cupertino simple par métrique ;
- une valeur principale ou un état principal ;
- un pill de support qui explique l’état de disponibilité ;
- des bordures et teintes colorées par availability.

La grille utilise une densité volontairement simple :

```text
largeur >= 1080 : 6 colonnes
largeur >= 720  : 3 colonnes
sinon           : 2 colonnes
```

Une hauteur stable de carte évite les overflows et les sauts de layout :

```dart
height: 154,
```

## 5. Mapping KPI → read model

| KPI affiché | Source exclusive |
|---|---|
| Chapitres | `readModel.metrics.chapters` |
| Scènes | `readModel.metrics.scenes` |
| Cinématiques | `readModel.metrics.cutscenes` |
| Quêtes | `readModel.metrics.quests` |
| Dialogues | `readModel.metrics.dialogues` |
| Problèmes ouverts | `readModel.metrics.openIssues` |

Les widgets ne recalculent pas les métriques à partir du manifest, des scénarios, des dialogues ou de metadata brute. Ils consomment uniquement les `NarrativeMetricSummary` déjà normalisés.

## 6. Gestion des availability states

Rendu principal :

| Availability | Valeur de carte |
|---|---|
| `available` | `count` réel |
| `empty` | `0` réel |
| `unavailable` | `Indisponible` |
| `notEvaluated` | `Non évalué` |
| `outOfScope` | `Hors scope V0` |
| `needsModel` | `Nécessite un modèle` |

Support label :

| Availability | Sous-label |
|---|---|
| `available` | `Disponible` |
| `empty` | `Disponible` |
| `unavailable` | `metric.unavailableMessage` |
| `notEvaluated` | `Validation non lancée` |
| `outOfScope` | `Pas de modèle Quest` pour `quests`, sinon message du read model |
| `needsModel` | `Registre absent` |

Le point important du contrat NS-HOME-01/02 est conservé :

```text
Quêtes != faux 0
Problèmes ouverts sans validation != 0
Facts sans registre != compteur réel
```

## 7. Ce qui reste volontairement hors scope

Restent hors scope de NS-HOME-04 :

- carte complète `Histoire principale` ;
- chips de chapitres ;
- grille complète de modules narratifs ;
- panneau droit `Structure narrative` ;
- tags ;
- statut éditorial détaillé ;
- activité récente réelle ;
- notifications ;
- top bar finale ;
- sidebar finale ;
- preview runtime ;
- progression joueur ;
- sauvegarde joueur.

Les lignes `Facts`, `Activité récente` et `Notifications` restent dans le bloc `V0 volontairement limitée`, car elles ne doivent pas être présentées comme données réelles.

## 8. Tests ajoutés / modifiés

Le fichier de test existant a été enrichi :

```text
packages/map_editor/test/ui/canvas/narrative_overview_workspace_test.dart
```

Couverture ajoutée :

- la section KPI cards est rendue ;
- les six KPI attendus sont présents ;
- chaque carte a une key stable `narrative-overview-kpi-*` ;
- les cartes consomment les valeurs du read model ;
- `Quêtes` affiche `Hors scope V0` et `Pas de modèle Quest` ;
- `Problèmes ouverts` affiche `Non évalué` et `Validation non lancée` ;
- les chiffres de l’image ne sont pas hardcodés ;
- `Selbrume` et `La brume du phare` ne sont pas hardcodés ;
- le layout ne crashe pas à une largeur desktop plus étroite ;
- un test de screenshot peut produire l’image du Visual Gate via un `dart-define`.

## 9. Visual Gate

Screenshot produit :

```text
reports/narrativeStudio/ui/screenshots/ns_home_04_overview_kpi_cards.png
```

Méthode utilisée :

```bash
cd packages/map_editor && flutter test test/ui/canvas/narrative_overview_workspace_test.dart --no-test-assets --dart-define=NS_HOME_04_CAPTURE_SCREENSHOT=true --update-goldens --plain-name "NarrativeOverviewWorkspace captures KPI cards screenshot when requested"
```

Métadonnées du screenshot :

```text
reports/narrativeStudio/ui/screenshots/ns_home_04_overview_kpi_cards.png: PNG image data, 1180 x 760, 8-bit/color RGBA, non-interlaced
May 27 01:35:34 2026 88042
```

Ce qui correspond à l’image cible :

- dark mode bleu nuit ;
- surfaces bleu-gris sombres ;
- bordures subtiles ;
- six cartes KPI alignées ;
- états colorés distincts ;
- densité professionnelle plutôt que landing page ;
- absence de progression joueur ;
- absence de faux compteur pour `Quêtes` et `Problèmes ouverts`.

Ce qui ne correspond pas encore :

- la top bar finale n’existe pas dans ce lot ;
- la sidebar finale n’est pas traitée ;
- la grande carte `Histoire principale` n’est pas créée ;
- la grille complète des modules narratifs n’est pas créée ;
- le panneau droit `Structure narrative` n’est pas créé ;
- les icônes restent des pictogrammes Cupertino simples, pas une direction iconographique finale ;
- la composition générale reste un shell V0, pas le dashboard premium complet.

Inspection visuelle :

- la section KPI est lisible ;
- les états `Disponible`, `Hors scope V0` et `Validation non lancée` sont compréhensibles ;
- aucun overflow visible sur le screenshot 1180x760 ;
- la hiérarchie titre -> projet -> indicateurs -> limites V0 est claire ;
- les cartes sont suffisamment denses sans devenir un formulaire.

Correction faite après inspection :

Le premier screenshot montrait des blocs typographiques dans certaines zones, à cause de l’héritage de police du `DefaultTextStyle` interne. La section a été ajustée pour préserver la famille de police héritée, puis le screenshot a été régénéré. Le screenshot final est lisible.

## 10. Commandes exécutées

Lectures et recherches :

```bash
git branch --show-current && git status --short --untracked-files=all && git diff --stat && git diff --name-only && git log --oneline -n 10
file reports/narrativeStudio/ui/screenshots/ns_home_04_overview_kpi_cards.png && stat -f '%Sm %z' reports/narrativeStudio/ui/screenshots/ns_home_04_overview_kpi_cards.png
rg -n "Card|Badge|Status|Pill|Metric|KPI|Summary|Availability|EditorChrome|largeIslandSurfaceColor|PokeMapBadge" packages/map_editor/lib/src packages/map_editor/test
rg -n "screenshot|golden|matchesGoldenFile|capture|takeScreenshot|flutter_test_config|screenshots" . --glob '!**/build/**' --glob '!**/.dart_tool/**'
```

Tests et screenshot :

```bash
cd packages/map_editor && flutter test test/ui/canvas/narrative_overview_workspace_test.dart
cd packages/map_editor && flutter test test/ui/canvas/narrative_overview_workspace_test.dart test/ui/canvas/narrative_overview_shell_navigation_test.dart
cd packages/map_editor && flutter test test/ui/canvas/narrative_overview_workspace_test.dart --no-test-assets --dart-define=NS_HOME_04_CAPTURE_SCREENSHOT=true --update-goldens --plain-name "NarrativeOverviewWorkspace captures KPI cards screenshot when requested"
```

Analyse et Git :

```bash
cd packages/map_editor && flutter analyze
cd packages/map_editor && flutter analyze --no-fatal-infos lib/src/ui/canvas/narrative_overview_workspace.dart test/ui/canvas/narrative_overview_workspace_test.dart
git diff --check
git status --short --untracked-files=all
git diff --stat
git diff --name-only
```

## 11. Résultats des tests

Commande :

```bash
cd packages/map_editor && flutter test test/ui/canvas/narrative_overview_workspace_test.dart
```

Sortie :

```text
00:00 +0: NarrativeOverviewWorkspace renders a minimal authoring overview from the read model
00:00 +1: NarrativeOverviewWorkspace does not present unavailable modules as real data
00:00 +2: NarrativeOverviewWorkspace KPI cards consume read model values
00:00 +3: NarrativeOverviewWorkspace KPI layout renders on a narrower desktop width
00:00 +4: NarrativeOverviewWorkspace captures KPI cards screenshot when requested
00:00 +5: All tests passed!
```

Commande :

```bash
cd packages/map_editor && flutter test test/ui/canvas/narrative_overview_workspace_test.dart test/ui/canvas/narrative_overview_shell_navigation_test.dart
```

Sortie :

```text
00:00 +0: /Users/karim/Project/pokemonProject/packages/map_editor/test/ui/canvas/narrative_overview_workspace_test.dart: NarrativeOverviewWorkspace renders a minimal authoring overview from the read model
00:00 +1: /Users/karim/Project/pokemonProject/packages/map_editor/test/ui/canvas/narrative_overview_shell_navigation_test.dart: NarrativeWorkspaceCanvas routes overview mode to the overview shell
00:00 +2: /Users/karim/Project/pokemonProject/packages/map_editor/test/ui/canvas/narrative_overview_shell_navigation_test.dart: NarrativeWorkspaceCanvas routes overview mode to the overview shell
00:00 +3: /Users/karim/Project/pokemonProject/packages/map_editor/test/ui/canvas/narrative_overview_shell_navigation_test.dart: NarrativeWorkspaceCanvas routes overview mode to the overview shell
00:00 +4: /Users/karim/Project/pokemonProject/packages/map_editor/test/ui/canvas/narrative_overview_shell_navigation_test.dart: NarrativeWorkspaceCanvas routes overview mode to the overview shell
00:00 +5: /Users/karim/Project/pokemonProject/packages/map_editor/test/ui/canvas/narrative_overview_shell_navigation_test.dart: NarrativeWorkspaceCanvas routes overview mode to the overview shell
00:00 +6: /Users/karim/Project/pokemonProject/packages/map_editor/test/ui/canvas/narrative_overview_shell_navigation_test.dart: NarrativeLibraryPanel exposes overview without removing existing studios
00:00 +7: All tests passed!
```

Commande screenshot :

```bash
cd packages/map_editor && flutter test test/ui/canvas/narrative_overview_workspace_test.dart --no-test-assets --dart-define=NS_HOME_04_CAPTURE_SCREENSHOT=true --update-goldens --plain-name "NarrativeOverviewWorkspace captures KPI cards screenshot when requested"
```

Sortie :

```text
00:00 +0: NarrativeOverviewWorkspace captures KPI cards screenshot when requested
00:00 +1: All tests passed!
```

## 12. Résultats analyze

Commande :

```bash
cd packages/map_editor && flutter analyze
```

Résultat :

```text
Analyzing map_editor...
...
  error • The named parameter 'dbSymbol' isn't defined • lib/src/application/services/pokemon_sdk_move_catalog_converter.dart:58:7 • undefined_named_parameter
  error • The named parameter 'battleEngineAimedTarget' isn't defined • lib/src/application/services/pokemon_sdk_move_catalog_converter.dart:64:7 • undefined_named_parameter
  error • The named parameter 'battleEngineMethod' isn't defined • lib/src/application/services/pokemon_sdk_move_catalog_converter.dart:72:7 • undefined_named_parameter
  error • The named parameter 'effectChance' isn't defined • lib/src/application/services/pokemon_sdk_move_catalog_converter.dart:73:7 • undefined_named_parameter
  error • The named parameter 'studioFlags' isn't defined • lib/src/application/services/pokemon_sdk_move_catalog_converter.dart:74:7 • undefined_named_parameter
  error • The named parameter 'battleStageMods' isn't defined • lib/src/application/services/pokemon_sdk_move_catalog_converter.dart:75:7 • undefined_named_parameter
  error • The named parameter 'moveStatuses' isn't defined • lib/src/application/services/pokemon_sdk_move_catalog_converter.dart:76:7 • undefined_named_parameter
  error • The named parameter 'psdkStudioMoveId' isn't defined • lib/src/application/services/pokemon_sdk_move_catalog_converter.dart:80:9 • undefined_named_parameter
  error • Undefined class 'PokemonMoveAimedTarget' • lib/src/application/services/pokemon_sdk_move_catalog_converter.dart:239:3 • undefined_class
  error • Undefined class 'PokemonMoveFlags' • lib/src/application/services/pokemon_sdk_move_catalog_converter.dart:284:3 • undefined_class
  error • The method 'fetchPokemonSdkStudioProjectPayload' isn't defined for the type 'PokemonExternalSourceRepository' • lib/src/application/use_cases/sync_pokemon_sdk_moves_catalog_use_case.dart:58:10 • undefined_method
warning • The library 'package:map_editor/src/ui/canvas/pokedex_workspace/pokedex_workspace_page.dart' doesn't export a member with the shown name 'showPokedexImportFlowSheet' • lib/src/ui/canvas/pokedex_workspace_views.dart:17:9 • undefined_shown_name
...
348 issues found. (ran in 3.0s)
```

Interprétation :

L’analyse globale échoue sur une dette préexistante hors NS-HOME-04, principalement côté Pokémon SDK / Pokédex. Aucun diagnostic global ne vise les fichiers modifiés par ce lot après correction de l’import inutile détecté pendant la vérification.

Commande ciblée :

```bash
cd packages/map_editor && flutter analyze --no-fatal-infos lib/src/ui/canvas/narrative_overview_workspace.dart test/ui/canvas/narrative_overview_workspace_test.dart
```

Sortie :

```text
Analyzing 2 items...

No issues found! (ran in 1.1s)
```

## 13. Limites

- Les KPI cards V0 sont structurelles et lisibles, mais pas encore la direction premium finale de toute la page.
- Les icônes restent des icônes Cupertino génériques.
- Le screenshot couvre le shell Overview, pas le shell global avec sidebar/top bar finale.
- `Quêtes`, `Facts`, `Activité récente` et `Notifications` restent non branchés comme prévu par le contrat de données.
- `Problèmes ouverts` affiche `Non évalué` tant qu’aucun validator n’est injecté.

## 14. Prochain lot recommandé

Prochain lot exact recommandé :

```text
NS-HOME-05 — Narrative Overview Main Story Card V0
```

Objectif recommandé :

Créer la première carte `Histoire principale` branchée sur `readModel.mainStory`, en gardant les mêmes règles :

- pas de synopsis Selbrume hardcodé ;
- pas de chiffres de l’image ;
- pas de progression joueur ;
- fallback honnête si aucune histoire principale explicite ;
- tests widget ;
- screenshot comparatif.

## 15. Evidence Pack

### Branche courante

Commande :

```bash
git branch --show-current
```

Sortie :

```text
main
```

### État initial documenté

Au début effectif du lot NS-HOME-04, le worktree contenait encore les fichiers NS-HOME-03 non finalisés côté Git :

```text
M  packages/map_editor/lib/src/features/editor/application/editor_workspace_controller.dart
M  packages/map_editor/lib/src/features/editor/state/editor_notifier.dart
M  packages/map_editor/lib/src/features/editor/state/editor_selectors.dart
M  packages/map_editor/lib/src/features/editor/state/models/editor_workspace_mode.dart
M  packages/map_editor/lib/src/ui/canvas/editor_canvas_host.dart
A  packages/map_editor/lib/src/ui/canvas/narrative_overview_workspace.dart
M  packages/map_editor/lib/src/ui/canvas/narrative_workspace_canvas.dart
M  packages/map_editor/lib/src/ui/editor_shell_page.dart
M  packages/map_editor/lib/src/ui/panels/narrative_library_panel.dart
M  packages/map_editor/lib/src/ui/panels/project_explorer_panel.dart
M  packages/map_editor/lib/src/ui/shared/top_toolbar.dart
A  packages/map_editor/test/ui/canvas/narrative_overview_shell_navigation_test.dart
A  packages/map_editor/test/ui/canvas/narrative_overview_workspace_test.dart
A  reports/narrativeStudio/ui/ns_home_03_narrative_overview_shell_placement.md
```

Pendant le lot, NS-HOME-03 a été intégré dans `HEAD` :

```text
ac3518ad feat(narrative-studio): add narrative overview shell and workspace
```

Les changements introduits par NS-HOME-04 sont donc les modifications de `narrative_overview_workspace.dart`, `narrative_overview_workspace_test.dart`, le screenshot et le présent rapport.

### Git final

Commande :

```bash
git status --short --untracked-files=all
```

Sortie :

```text
 M packages/map_editor/lib/src/ui/canvas/narrative_overview_workspace.dart
 M packages/map_editor/test/ui/canvas/narrative_overview_workspace_test.dart
?? reports/narrativeStudio/ui/ns_home_04_narrative_overview_kpi_cards.md
?? reports/narrativeStudio/ui/screenshots/ns_home_04_overview_kpi_cards.png
```

Commande :

```bash
git diff --stat
```

Sortie :

```text
 .../ui/canvas/narrative_overview_workspace.dart    | 254 +++++++++++++++++++--
 .../canvas/narrative_overview_workspace_test.dart  | 216 +++++++++++++++++-
 2 files changed, 448 insertions(+), 22 deletions(-)
```

Commande :

```bash
git diff --name-only
```

Sortie :

```text
packages/map_editor/lib/src/ui/canvas/narrative_overview_workspace.dart
packages/map_editor/test/ui/canvas/narrative_overview_workspace_test.dart
```

Commande :

```bash
git diff --check
```

Sortie :

```text
Sortie : <vide>
```

### Fichiers créés

```text
reports/narrativeStudio/ui/screenshots/ns_home_04_overview_kpi_cards.png
reports/narrativeStudio/ui/ns_home_04_narrative_overview_kpi_cards.md
```

### Fichiers modifiés

```text
packages/map_editor/lib/src/ui/canvas/narrative_overview_workspace.dart
packages/map_editor/test/ui/canvas/narrative_overview_workspace_test.dart
```

### Extraits complets des sections modifiées principales

Section KPI ajoutée :

```dart
class _KpiCardsSection extends StatelessWidget {
  const _KpiCardsSection({
    required this.metrics,
  });

  final List<NarrativeMetricSummary> metrics;

  @override
  Widget build(BuildContext context) {
    return _OverviewSection(
      title: 'Indicateurs auteur',
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            const spacing = 10.0;
            final maxWidth = constraints.maxWidth;
            final columns = switch (maxWidth) {
              >= 1080 => 6,
              >= 720 => 3,
              _ => 2,
            };
            final cardWidth = (maxWidth - spacing * (columns - 1)) / columns;

            return Wrap(
              key: const ValueKey('narrative-overview-kpi-grid'),
              spacing: spacing,
              runSpacing: spacing,
              children: [
                for (final metric in metrics)
                  SizedBox(
                    width: cardWidth,
                    child: _KpiCard(metric: metric),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}
```

Carte KPI :

```dart
class _KpiCard extends StatelessWidget {
  const _KpiCard({required this.metric});

  final NarrativeMetricSummary metric;

  @override
  Widget build(BuildContext context) {
    final accent = _availabilityAccent(context, metric.availability);
    return Container(
      key: ValueKey('narrative-overview-kpi-${metric.id}'),
      height: 154,
      decoration: BoxDecoration(
        color: EditorChrome.largeIslandSurfaceColor(
          context,
          tint: accent.withValues(alpha: 0.1),
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accent.withValues(alpha: 0.34)),
        boxShadow: EditorChrome.sectionCardShadows(context),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _MetricIcon(metricId: metric.id, accent: accent),
              const SizedBox(width: 9),
              Expanded(
                child: Text(
                  metric.label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: EditorChrome.primaryLabel(context),
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const Spacer(),
          Text(
            _metricCardValue(metric),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: EditorChrome.primaryLabel(context),
              fontSize: _metricCardValue(metric).length > 12 ? 18 : 24,
              fontWeight: FontWeight.w900,
              letterSpacing: 0,
            ),
          ),
          const SizedBox(height: 6),
          _AvailabilityPill(
            label: _metricSupportLabel(metric),
            accent: accent,
          ),
        ],
      ),
    );
  }
}
```

Mapping availability :

```dart
String _metricCardValue(NarrativeMetricSummary metric) {
  return switch (metric.availability) {
    NarrativeOverviewAvailability.available ||
    NarrativeOverviewAvailability.empty =>
      '${metric.count ?? 0}',
    NarrativeOverviewAvailability.unavailable => 'Indisponible',
    NarrativeOverviewAvailability.notEvaluated => 'Non évalué',
    NarrativeOverviewAvailability.outOfScope => 'Hors scope V0',
    NarrativeOverviewAvailability.needsModel => 'Nécessite un modèle',
  };
}

String _metricSupportLabel(NarrativeMetricSummary metric) {
  return switch (metric.availability) {
    NarrativeOverviewAvailability.available => 'Disponible',
    NarrativeOverviewAvailability.empty => 'Disponible',
    NarrativeOverviewAvailability.unavailable => metric.unavailableMessage,
    NarrativeOverviewAvailability.notEvaluated => 'Validation non lancée',
    NarrativeOverviewAvailability.outOfScope =>
      metric.id == 'quests' ? 'Pas de modèle Quest' : metric.unavailableMessage,
    NarrativeOverviewAvailability.needsModel => 'Registre absent',
  };
}
```

Test screenshot :

```dart
testWidgets(
  'NarrativeOverviewWorkspace captures KPI cards screenshot when requested',
  (tester) async {
    if (!const bool.fromEnvironment('NS_HOME_04_CAPTURE_SCREENSHOT')) {
      return;
    }

    await _loadScreenshotFont();
    tester.view.physicalSize = const Size(1180, 760);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final readModel = buildNarrativeOverviewReadModel(
      project: _minimalProject(
        'test_project',
        dialogues: const <ProjectDialogueEntry>[
          ProjectDialogueEntry(
            id: 'test_dialogue_1',
            name: 'Test Dialogue',
            relativePath: 'dialogues/test_dialogue_1.yarn',
          ),
        ],
      ),
    );

    await tester.pumpWidget(
      MacosTheme(
        data: MacosThemeData.dark(),
        child: CupertinoApp(
          home: CupertinoPageScaffold(
            child: ColoredBox(
              key: const ValueKey('ns-home-04-screenshot-root'),
              color: const Color(0xFF07111F),
              child: DefaultTextStyle.merge(
                style: const TextStyle(fontFamily: _screenshotFontFamily),
                child: Center(
                  child: SizedBox(
                    width: 1180,
                    height: 760,
                    child: NarrativeOverviewWorkspace(readModel: readModel),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));

    final screenshotFile = File(
      '../../reports/narrativeStudio/ui/screenshots/'
      'ns_home_04_overview_kpi_cards.png',
    );
    screenshotFile.parent.createSync(recursive: true);
    await expectLater(
      find.byKey(const ValueKey('ns-home-04-screenshot-root')),
      matchesGoldenFile(screenshotFile.absolute.path),
    );

    expect(screenshotFile.existsSync(), isTrue);
  },
);
```

### Confirmations de scope

- Aucun code `map_core` modifié.
- Aucun code `map_runtime` modifié.
- Aucun code `map_gameplay` modifié.
- Aucun code `map_battle` modifié.
- Aucun widget de page finale complète créé.
- Aucun read model modifié.
- Aucun provider créé.
- Aucun fake counter ajouté.
- Aucun hardcode Selbrume ajouté.
- Aucun chiffre de l’image cible hardcodé.
- Aucun commit et aucun staging effectués par Codex.

## 16. Auto-review critique

Ai-je créé la section KPI cards demandée ?

```text
Oui. Six cartes KPI sont rendues dans `NarrativeOverviewWorkspace`.
```

Ai-je consommé uniquement `NarrativeOverviewReadModel` ?

```text
Oui. Les cartes reçoivent des `NarrativeMetricSummary` déjà produits par le read model.
```

Ai-je évité les faux compteurs ?

```text
Oui. `Quêtes` reste `Hors scope V0`, `Problèmes ouverts` reste `Non évalué` sans validation, et `Facts` reste dans les limites V0.
```

Ai-je évité de modifier runtime/gameplay/battle/map_core ?

```text
Oui. Seul `map_editor` UI/test est modifié, plus le rapport et le screenshot.
```

Ai-je produit et inspecté un screenshot ?

```text
Oui. Le screenshot final est lisible et sauvegardé dans `reports/narrativeStudio/ui/screenshots/ns_home_04_overview_kpi_cards.png`.
```

Ai-je corrigé les défauts visuels dans le scope ?

```text
Oui. Un problème de police de screenshot et des risques d’overflow de carte ont été corrigés.
```

Ai-je lancé les tests ciblés et l’analyse ?

```text
Oui. Tests ciblés OK, analyse ciblée OK. L’analyse globale échoue sur dette préexistante hors lot.
```

## 17. Regard critique sur le prompt

Le prompt était bien cadré : il demandait une première brique UI concrète sans autoriser une dérive vers la page finale. La contrainte de screenshot était utile, car elle a révélé un problème de rendu typographique que les tests textuels seuls n’auraient pas montré.

Le seul point délicat est que le repo avait un état NS-HOME-03 encore mobile au démarrage effectif du lot, puis intégré dans `HEAD` pendant l’exécution. Le rapport distingue donc l’état initial préexistant et le diff final NS-HOME-04.
