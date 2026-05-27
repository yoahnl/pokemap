# NS-HOME-05 — Narrative Overview Main Story Card V0

## 1. Résumé exécutif

NS-HOME-05 ajoute la première carte centrale `Histoire principale` dans `NarrativeOverviewWorkspace`.

La carte est branchée exclusivement sur :

```dart
readModel.mainStory
```

Elle affiche :

- un titre de section `Histoire principale` ;
- un état vide honnête quand aucune histoire principale n’existe ;
- un état ambigu explicite quand plusieurs global stories existent ;
- le titre réel et la description réelle quand une histoire principale explicite existe ;
- `Synopsis non renseigné.` quand la description est absente ;
- les métriques `Scènes liées`, `Dialogues liés`, `Problèmes ouverts` depuis `mainStory` ;
- `Non évalué` pour les problèmes ouverts sans validation ;
- les chapitres disponibles ;
- une indication visuelle quand les chapitres viennent d’un fallback ;
- une affordance `Modifier à venir` non fonctionnelle.

Le lot ne crée pas de formulaire d’édition, ne modifie pas le read model et ne touche ni au runtime, ni au gameplay, ni au battle, ni à `map_core`.

## 2. Rappel du scope NS-HOME-05

Objectif réalisé :

```text
Aperçu
-> KPI cards réelles
-> Histoire principale réelle ou empty state honnête
-> readModel.mainStory
-> screenshot
-> critique visuelle
```

Non-objectifs respectés :

- pas de dashboard final complet ;
- pas de grille complète des modules narratifs ;
- pas de panneau droit `Structure narrative` ;
- pas d’activité récente ;
- pas de notifications ;
- pas de top bar finale ;
- pas de sidebar finale ;
- pas de nouveau provider ;
- pas de repository ;
- pas de lecture disque ;
- pas de parsing Yarn ;
- pas de build_runner ;
- pas de vraie édition storyline.

## 3. Fichiers créés / modifiés

Fichiers modifiés :

```text
packages/map_editor/lib/src/ui/canvas/narrative_overview_workspace.dart
packages/map_editor/test/ui/canvas/narrative_overview_workspace_test.dart
```

Fichiers créés :

```text
reports/narrativeStudio/ui/screenshots/ns_home_05_overview_main_story_card.png
reports/narrativeStudio/ui/ns_home_05_narrative_overview_main_story_card.md
```

## 4. UI créée

La carte `Histoire principale` est insérée sous la section `Indicateurs auteur`.

Structure créée :

- header avec icône, titre et affordance `Modifier à venir` ;
- pictogramme symbolique compact, sans image décorative obligatoire ;
- titre principal résolu depuis `mainStory.title` ;
- description depuis `mainStory.description` ou message honnête si absente ;
- pill de source : `Source explicite`, `Source fallback`, `Source manquante`, `Source ambiguë` ;
- trois métriques liées ;
- ligne de chapitres sous forme de chips ;
- bouton visuel `+ Chapitre à venir` non fonctionnel.

L’affordance `Modifier à venir` est rendue comme un bouton désactivé via `Semantics(enabled: false)`. Elle ne déclenche aucune action et ne prétend pas modifier des données.

## 5. Mapping Main Story Card → readModel.mainStory

| Zone UI | Source |
|---|---|
| état général | `readModel.mainStory.availability` |
| statut de source | `readModel.mainStory.sourceStatus` |
| message état vide / ambigu | `readModel.mainStory.message` |
| titre | `readModel.mainStory.title` |
| description | `readModel.mainStory.description` |
| scènes liées | `readModel.mainStory.linkedScenes` |
| dialogues liés | `readModel.mainStory.linkedDialogues` |
| problèmes ouverts | `readModel.mainStory.openIssues` |
| chapitres | `readModel.mainStory.chapters` |
| édition possible | `readModel.mainStory.canEdit`, mais aucune action réelle n’est branchée en V0 |

Le widget ne lit pas `ProjectManifest.scenarios`, ne parse pas les metadata, ne cherche pas les dialogues et ne recalcule pas les chapitres.

## 6. Gestion des états empty / explicit / fallback / ambiguous / notEvaluated

État `empty` :

```text
Titre affiché : Aucune histoire principale
Message : readModel.mainStory.message
Métriques : 0 réel pour scènes/dialogues, Non évalué pour problèmes ouverts
```

État `explicit` :

```text
Titre affiché : mainStory.title
Description : mainStory.description ou Synopsis non renseigné.
Pill : Source explicite
Chapitres : chips authoring
```

État `fallback` :

```text
Le titre d’histoire reste celui de la global story.
Les chapitres affichent une indication : Chapitres issus d’un fallback.
```

État `ambiguous` :

```text
Titre affiché : Sélection requise
Message : Plusieurs histoires principales possibles.
Pill : Source ambiguë
Métriques : Indisponible
```

État `notEvaluated` :

```text
Problèmes ouverts : Non évalué
```

La carte ne produit jamais `À jour` sans validator.

## 7. Ce qui reste volontairement hors scope

Restent hors scope :

- formulaire `Modifier` ;
- création réelle de chapitre ;
- sélection explicite d’une histoire principale en cas d’ambiguïté ;
- édition complète des storylines ;
- chips finaux avec états éditoriaux définitifs ;
- panneau droit complet ;
- grille modules ;
- activité récente ;
- notifications ;
- top bar et sidebar finales ;
- toute progression joueur.

## 8. Tests ajoutés / modifiés

Le fichier suivant a été enrichi :

```text
packages/map_editor/test/ui/canvas/narrative_overview_workspace_test.dart
```

Couverture ajoutée :

- carte `Histoire principale` rendue ;
- empty state honnête sans histoire principale ;
- histoire explicite avec titre réel ;
- histoire explicite avec description réelle ;
- histoire sans description affichant `Synopsis non renseigné.` ;
- métriques `Scènes liées`, `Dialogues liés`, `Problèmes ouverts` depuis `mainStory` ;
- `Problèmes ouverts` affiche `Non évalué` sans validation ;
- chapitres explicites affichés ;
- chapitres fallback indiqués ;
- plusieurs global stories affichent `Sélection requise` et `Source ambiguë` ;
- aucune donnée Selbrume hardcodée ;
- aucun chiffre de l’image comme texte affiché ;
- KPI cards NS-HOME-04 toujours visibles ;
- layout desktop raisonnable ;
- screenshot NS-HOME-05 générable via `dart-define`.

## 9. Visual Gate

Screenshot produit :

```text
reports/narrativeStudio/ui/screenshots/ns_home_05_overview_main_story_card.png
```

Méthode utilisée :

```bash
cd packages/map_editor && flutter test test/ui/canvas/narrative_overview_workspace_test.dart --no-test-assets --dart-define=NS_HOME_05_CAPTURE_SCREENSHOT=true --update-goldens --plain-name "NarrativeOverviewWorkspace captures main story card screenshot when requested"
```

Métadonnées du screenshot :

```text
reports/narrativeStudio/ui/screenshots/ns_home_05_overview_main_story_card.png: PNG image data, 1180 x 980, 8-bit/color RGBA, non-interlaced
May 27 02:03:36 2026 123440
```

Ce qui correspond à l’image cible :

- la carte `Histoire principale` est large et située sous les KPI ;
- le rendu reste dark mode bleu nuit ;
- la carte a une bordure subtile et une surface sombre ;
- le pictogramme reste symbolique, pas décoratif ;
- les métriques liées sont visibles ;
- les chapitres apparaissent sous forme de chips ;
- `Modifier à venir` est visible sans être une vraie action ;
- aucune progression joueur, aucun pourcentage, aucun statut `Jouable`.

Ce qui ne correspond pas encore :

- la carte n’est pas pixel-perfect ;
- les chips ne portent pas encore la direction finale de l’image ;
- le panneau droit `Structure narrative` n’existe pas ;
- la top bar et la sidebar finales ne sont pas présentes ;
- l’état éditorial des chapitres dépend encore de la validation disponible ;
- l’iconographie reste générique.

Inspection visuelle :

- la carte est lisible ;
- les métriques `Scènes liées`, `Dialogues liés`, `Problèmes ouverts` sont compréhensibles ;
- `Non évalué` est visible pour les problèmes ouverts ;
- le layout ne montre pas d’overflow évident ;
- la densité reste V0 mais cohérente avec le dashboard en construction ;
- le bloc `V0 volontairement limitée` reste visible dans le screenshot final.

Correction faite après inspection :

Le screenshot initial coupait légèrement le bas du bloc V0 ; la hauteur de capture a été portée à `1180x980`. Un `42` de taille d’icône a aussi été remplacé par `40` pour éviter toute ambiguïté avec les chiffres de l’image cible.

## 10. Commandes exécutées

Lectures et Gate initial :

```bash
pwd && git branch --show-current && git status --short --untracked-files=all && git diff --stat && git diff --name-only && git log --oneline -n 10
sed -n '1,220p' AGENTS.md && sed -n '1,220p' agent_rules.md && sed -n '1,220p' skills/README.md
sed -n '1,220p' 'MVP Selbrume/road_map_global.md' && sed -n '1,220p' 'MVP Selbrume/road_map_phase_1.md'
sed -n '1,180p' reports/narrativeStudio/ui/ns_home_00_overview_roadmap_proposal.md
sed -n '1,180p' reports/narrativeStudio/ui/ns_home_01_overview_data_contract.md
sed -n '1,180p' reports/narrativeStudio/ui/ns_home_02_narrative_overview_read_model.md
sed -n '1,180p' reports/narrativeStudio/ui/ns_home_03_narrative_overview_shell_placement.md
sed -n '1,180p' reports/narrativeStudio/ui/ns_home_04_narrative_overview_kpi_cards.md
```

Tests et screenshot :

```bash
cd packages/map_editor && flutter test test/ui/canvas/narrative_overview_workspace_test.dart
cd packages/map_editor && flutter test test/ui/canvas/narrative_overview_workspace_test.dart test/ui/canvas/narrative_overview_shell_navigation_test.dart
cd packages/map_editor && flutter test test/ui/canvas/narrative_overview_workspace_test.dart --no-test-assets --dart-define=NS_HOME_05_CAPTURE_SCREENSHOT=true --update-goldens --plain-name "NarrativeOverviewWorkspace captures main story card screenshot when requested"
```

Format / analyse / Git :

```bash
cd packages/map_editor && dart format lib/src/ui/canvas/narrative_overview_workspace.dart test/ui/canvas/narrative_overview_workspace_test.dart
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
00:00 +4: NarrativeOverviewWorkspace renders an honest empty main story card
00:00 +5: NarrativeOverviewWorkspace renders explicit main story data from the read model
00:00 +6: NarrativeOverviewWorkspace explains missing description and fallback chapters
00:00 +7: NarrativeOverviewWorkspace renders ambiguous main story state explicitly
00:01 +8: NarrativeOverviewWorkspace captures KPI cards screenshot when requested
00:01 +9: NarrativeOverviewWorkspace captures main story card screenshot when requested
00:01 +10: All tests passed!
```

Commande :

```bash
cd packages/map_editor && flutter test test/ui/canvas/narrative_overview_workspace_test.dart test/ui/canvas/narrative_overview_shell_navigation_test.dart
```

Sortie :

```text
00:00 +0: /Users/karim/Project/pokemonProject/packages/map_editor/test/ui/canvas/narrative_overview_workspace_test.dart: NarrativeOverviewWorkspace renders a minimal authoring overview from the read model
00:00 +1: /Users/karim/Project/pokemonProject/packages/map_editor/test/ui/canvas/narrative_overview_workspace_test.dart: NarrativeOverviewWorkspace does not present unavailable modules as real data
00:00 +2: /Users/karim/Project/pokemonProject/packages/map_editor/test/ui/canvas/narrative_overview_workspace_test.dart: NarrativeOverviewWorkspace KPI cards consume read model values
00:00 +3: /Users/karim/Project/pokemonProject/packages/map_editor/test/ui/canvas/narrative_overview_workspace_test.dart: NarrativeOverviewWorkspace KPI layout renders on a narrower desktop width
00:00 +4: /Users/karim/Project/pokemonProject/packages/map_editor/test/ui/canvas/narrative_overview_workspace_test.dart: NarrativeOverviewWorkspace renders an honest empty main story card
00:00 +5: /Users/karim/Project/pokemonProject/packages/map_editor/test/ui/canvas/narrative_overview_workspace_test.dart: NarrativeOverviewWorkspace renders explicit main story data from the read model
00:00 +6: /Users/karim/Project/pokemonProject/packages/map_editor/test/ui/canvas/narrative_overview_workspace_test.dart: NarrativeOverviewWorkspace explains missing description and fallback chapters
00:01 +7: /Users/karim/Project/pokemonProject/packages/map_editor/test/ui/canvas/narrative_overview_workspace_test.dart: NarrativeOverviewWorkspace renders ambiguous main story state explicitly
00:01 +8: /Users/karim/Project/pokemonProject/packages/map_editor/test/ui/canvas/narrative_overview_workspace_test.dart: NarrativeOverviewWorkspace captures KPI cards screenshot when requested
00:01 +9: /Users/karim/Project/pokemonProject/packages/map_editor/test/ui/canvas/narrative_overview_workspace_test.dart: NarrativeOverviewWorkspace captures main story card screenshot when requested
00:02 +10: /Users/karim/Project/pokemonProject/packages/map_editor/test/ui/canvas/narrative_overview_shell_navigation_test.dart: NarrativeWorkspaceCanvas routes overview mode to the overview shell
00:03 +11: /Users/karim/Project/pokemonProject/packages/map_editor/test/ui/canvas/narrative_overview_shell_navigation_test.dart: NarrativeLibraryPanel exposes overview without removing existing studios
00:03 +12: All tests passed!
```

Commande screenshot :

```bash
cd packages/map_editor && flutter test test/ui/canvas/narrative_overview_workspace_test.dart --no-test-assets --dart-define=NS_HOME_05_CAPTURE_SCREENSHOT=true --update-goldens --plain-name "NarrativeOverviewWorkspace captures main story card screenshot when requested"
```

Sortie :

```text
00:00 +0: NarrativeOverviewWorkspace captures main story card screenshot when requested
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
  error • Undefined class 'PokemonMoveAimedTarget' • lib/src/application/services/pokemon_sdk_move_catalog_converter.dart:239:3 • undefined_class
  error • Undefined class 'PokemonMoveFlags' • lib/src/application/services/pokemon_sdk_move_catalog_converter.dart:284:3 • undefined_class
  error • The method 'fetchPokemonSdkStudioProjectPayload' isn't defined for the type 'PokemonExternalSourceRepository' • lib/src/application/use_cases/sync_pokemon_sdk_moves_catalog_use_case.dart:58:10 • undefined_method
warning • The library 'package:map_editor/src/ui/canvas/pokedex_workspace/pokedex_workspace_page.dart' doesn't export a member with the shown name 'showPokedexImportFlowSheet' • lib/src/ui/canvas/pokedex_workspace_views.dart:17:9 • undefined_shown_name
...
348 issues found. (ran in 3.5s)
```

Interprétation :

L’analyse globale échoue sur une dette préexistante hors NS-HOME-05, principalement côté Pokémon SDK / Pokédex. Les fichiers touchés par NS-HOME-05 ne sont pas signalés dans le résultat final après correction des infos locales.

Commande ciblée :

```bash
cd packages/map_editor && flutter analyze --no-fatal-infos lib/src/ui/canvas/narrative_overview_workspace.dart test/ui/canvas/narrative_overview_workspace_test.dart
```

Sortie :

```text
Analyzing 2 items...
No issues found! (ran in 1.4s)
```

## 13. Limites

- La carte est une V0, pas le rendu final premium.
- `Modifier à venir` est une affordance visuelle désactivée.
- `+ Chapitre à venir` ne crée rien.
- La sélection explicite d’une histoire principale en cas d’ambiguïté est reportée.
- La validation narrative n’est pas lancée depuis cette carte.
- Les états éditoriaux des chapitres restent dépendants du read model existant.

## 14. Prochain lot recommandé

Prochain lot exact recommandé :

```text
NS-HOME-06 — Narrative Overview Module Cards Grid V0
```

Objectif :

Ajouter la première grille de modules narratifs branchée sur `readModel.modules`, sans faux compteurs pour `Quêtes` ou `Facts`, et avec screenshot Visual Gate.

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

### État Git initial

Commande :

```bash
git status --short --untracked-files=all
```

Sortie :

```text
Sortie : <vide>
```

Commande :

```bash
git diff --stat
```

Sortie :

```text
Sortie : <vide>
```

Commande :

```bash
git diff --name-only
```

Sortie :

```text
Sortie : <vide>
```

Log initial :

```text
22eaad9c feat(narrative-studio): add narrative overview KPI cards
ac3518ad feat(narrative-studio): add narrative overview shell and workspace
0bc7bb9c docs: update narrative overview read model report
e0b389e7 feat(narrative-studio): add narrative overview read model
ef3224a0 docs: add narrative studio UI home overview data contract
6239b5fd docs: add narrative studio UI home overview roadmap proposal
0e2beef8 docs: add Phase 7 narrative studio information architecture and creator journey design
9a95f1b5 docs: add Phase 7 modern app shell and narrative studio UX inventory audit
1de262a2 docs: add Phase 7 roadmap bootstrap and narrative studio modern UI scope audit
1ca0154d docs: add Phase 7 roadmap and P6 checkpoint 01 Selbrume beta slice readiness review
```

### Git final

Commande :

```bash
git status --short --untracked-files=all
```

Sortie :

```text
 M packages/map_editor/lib/src/ui/canvas/narrative_overview_workspace.dart
 M packages/map_editor/test/ui/canvas/narrative_overview_workspace_test.dart
?? reports/narrativeStudio/ui/ns_home_05_narrative_overview_main_story_card.md
?? reports/narrativeStudio/ui/screenshots/ns_home_05_overview_main_story_card.png
```

Commande :

```bash
git diff --stat
```

Sortie :

```text
 .../ui/canvas/narrative_overview_workspace.dart    | 482 +++++++++++++++++++++
 .../canvas/narrative_overview_workspace_test.dart  | 426 +++++++++++++++---
 2 files changed, 851 insertions(+), 57 deletions(-)
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
reports/narrativeStudio/ui/screenshots/ns_home_05_overview_main_story_card.png
reports/narrativeStudio/ui/ns_home_05_narrative_overview_main_story_card.md
```

### Fichiers modifiés

```text
packages/map_editor/lib/src/ui/canvas/narrative_overview_workspace.dart
packages/map_editor/test/ui/canvas/narrative_overview_workspace_test.dart
```

### Extraits complets des sections modifiées principales

Insertion dans `NarrativeOverviewWorkspace` :

```dart
_KpiCardsSection(
  metrics: [
    readModel.metrics.chapters,
    readModel.metrics.scenes,
    readModel.metrics.cutscenes,
    readModel.metrics.quests,
    readModel.metrics.dialogues,
    readModel.metrics.openIssues,
  ],
),
const SizedBox(height: 12),
_MainStoryCard(story: readModel.mainStory),
const SizedBox(height: 12),
```

Carte principale :

```dart
class _MainStoryCard extends StatelessWidget {
  const _MainStoryCard({required this.story});

  final MainStoryOverviewSummary story;

  @override
  Widget build(BuildContext context) {
    final accent = _sourceStatusAccent(context, story.sourceStatus);
    return Container(
      key: const ValueKey('narrative-overview-main-story-card'),
      decoration: BoxDecoration(
        color: EditorChrome.largeIslandSurfaceColor(
          context,
          tint: EditorChrome.islandCoolTint.withValues(alpha: 0.18),
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: accent.withValues(alpha: 0.32)),
        boxShadow: EditorChrome.sectionCardShadows(context),
      ),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                CupertinoIcons.star_fill,
                color: EditorChrome.accentPrimary,
                size: 14,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Histoire principale',
                  style: TextStyle(
                    color: EditorChrome.primaryLabel(context),
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              _DisabledEditAffordance(accent: accent),
            ],
          ),
          const SizedBox(height: 14),
          LayoutBuilder(
            builder: (context, constraints) {
              final useWideLayout = constraints.maxWidth >= 760;
              final visual = _MainStoryVisual(accent: accent);
              final content = _MainStoryContent(story: story, accent: accent);
              if (!useWideLayout) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    visual,
                    const SizedBox(height: 14),
                    content,
                  ],
                );
              }
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  visual,
                  const SizedBox(width: 18),
                  Expanded(child: content),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}
```

Mapping titre / description / source :

```dart
String _mainStoryTitle(MainStoryOverviewSummary story) {
  if (story.availability == NarrativeOverviewAvailability.empty) {
    return 'Aucune histoire principale';
  }
  if (story.sourceStatus == NarrativeOverviewSourceStatus.ambiguous) {
    return 'Sélection requise';
  }
  return story.title?.trim().isNotEmpty == true
      ? story.title!.trim()
      : 'Histoire principale sans titre';
}

String _mainStoryDescription(MainStoryOverviewSummary story) {
  if (story.availability != NarrativeOverviewAvailability.available) {
    return story.message;
  }
  return story.description?.trim().isNotEmpty == true
      ? story.description!.trim()
      : 'Synopsis non renseigné.';
}
```

Tests principaux ajoutés :

```dart
testWidgets(
  'NarrativeOverviewWorkspace renders an honest empty main story card',
  (tester) async {
    final readModel = buildNarrativeOverviewReadModel(
      project: _minimalProject('test_project'),
    );

    await _pumpOverview(tester, readModel);

    expect(find.byKey(const ValueKey('narrative-overview-main-story-card')),
        findsOneWidget);
    expect(find.text('Histoire principale'), findsOneWidget);
    expect(find.text('Aucune histoire principale'), findsOneWidget);
    expect(find.text('Aucune histoire principale définie.'), findsOneWidget);
    expect(find.text('Modifier à venir'), findsOneWidget);
    expect(_textInMainStory('Problèmes ouverts'), findsOneWidget);
    expect(_textInMainStory('Non évalué'), findsWidgets);
  },
);
```

```dart
testWidgets(
  'NarrativeOverviewWorkspace renders ambiguous main story state explicitly',
  (tester) async {
    final readModel = buildNarrativeOverviewReadModel(
      project: _minimalProject(
        'test_project',
        scenarios: const <ScenarioAsset>[
          ScenarioAsset(
            id: 'test_global_story_a',
            name: 'Test Story A',
            scope: ScenarioScope.globalStory,
            entryNodeId: 'start',
          ),
          ScenarioAsset(
            id: 'test_global_story_b',
            name: 'Test Story B',
            scope: ScenarioScope.globalStory,
            entryNodeId: 'start',
          ),
        ],
      ),
    );

    await _pumpOverview(tester, readModel);

    expect(find.text('Sélection requise'), findsOneWidget);
    expect(find.text('Plusieurs histoires principales possibles.'),
        findsOneWidget);
    expect(find.text('Source ambiguë'), findsOneWidget);
    expect(_textInMainStory('Indisponible'), findsWidgets);
    expect(find.text('Test Story A'), findsNothing);
    expect(find.text('Test Story B'), findsNothing);
  },
);
```

### Anti-hardcode

Commande :

```bash
rg -n "Selbrume|La brume du phare|Le départ|Le phare|Révélation|42|412|27|1 236|1236" packages/map_editor/lib/src/ui/canvas/narrative_overview_workspace.dart packages/map_editor/test/ui/canvas/narrative_overview_workspace_test.dart || true
```

Sortie :

```text
packages/map_editor/test/ui/canvas/narrative_overview_workspace_test.dart:102:      expect(find.textContaining('Selbrume'), findsNothing);
packages/map_editor/test/ui/canvas/narrative_overview_workspace_test.dart:103:      expect(find.textContaining('La brume du phare'), findsNothing);
packages/map_editor/test/ui/canvas/narrative_overview_workspace_test.dart:104:      expect(find.text('42'), findsNothing);
packages/map_editor/test/ui/canvas/narrative_overview_workspace_test.dart:105:      expect(find.text('1 236'), findsNothing);
packages/map_editor/test/ui/canvas/narrative_overview_workspace_test.dart:106:      expect(find.text('1236'), findsNothing);
packages/map_editor/test/ui/canvas/narrative_overview_workspace_test.dart:211:      expect(find.textContaining('Selbrume'), findsNothing);
packages/map_editor/test/ui/canvas/narrative_overview_workspace_test.dart:212:      expect(find.textContaining('La brume du phare'), findsNothing);
packages/map_editor/test/ui/canvas/narrative_overview_workspace_test.dart:213:      expect(find.text('42'), findsNothing);
packages/map_editor/test/ui/canvas/narrative_overview_workspace_test.dart:214:      expect(find.text('27'), findsNothing);
packages/map_editor/test/ui/canvas/narrative_overview_workspace_test.dart:215:      expect(find.text('412'), findsNothing);
```

Interprétation : les occurrences restantes sont uniquement des assertions négatives de test.

### Confirmations de scope

- Aucun fichier `map_core` modifié.
- Aucun fichier `map_runtime` modifié.
- Aucun fichier `map_gameplay` modifié.
- Aucun fichier `map_battle` modifié.
- `NarrativeOverviewReadModel` non modifié.
- Aucun provider créé.
- Aucun repository créé.
- Aucun fake compteur ajouté.
- Aucun hardcode Selbrume ajouté.
- Aucun chiffre de l’image cible ajouté comme donnée affichée.
- Aucun commit et aucun staging effectués par Codex.

## 16. Auto-review critique

Ai-je ajouté la carte `Histoire principale` ?

```text
Oui. La carte est rendue sous les KPI cards.
```

Ai-je consommé exclusivement `readModel.mainStory` ?

```text
Oui. Le widget reçoit `MainStoryOverviewSummary` et n’accède pas aux sources brutes.
```

Ai-je géré empty / explicit / fallback / ambiguous ?

```text
Oui. Les tests couvrent empty, explicit, fallback et ambiguous.
```

Ai-je évité de créer un vrai formulaire d’édition ?

```text
Oui. `Modifier à venir` est une affordance visuelle désactivée.
```

Ai-je évité les faux compteurs et la progression joueur ?

```text
Oui. Les métriques viennent du read model et `Problèmes ouverts` reste `Non évalué` sans validation.
```

Ai-je produit et inspecté un screenshot ?

```text
Oui. Le screenshot final est lisible, sans overflow évident, et documenté.
```

Ai-je lancé les vérifications ?

```text
Oui. Tests ciblés OK, analyse ciblée OK, `git diff --check` OK. L’analyse globale échoue sur dette préexistante hors lot.
```

## 17. Regard critique sur le prompt

Le prompt est bien calibré pour une deuxième brique visuelle : il demande une carte centrale utile sans autoriser le piège du dashboard complet. La contrainte la plus importante est la source unique `readModel.mainStory`, qui évite de refaire du parsing UI ou de recoder une logique métier dans les widgets.

Le Visual Gate reste utile : il a confirmé que la carte est lisible, mais aussi que le rendu reste encore V0. C’est acceptable pour NS-HOME-05 ; la page aura besoin d’un lot futur de composition globale et de polish une fois les blocs principaux posés.
