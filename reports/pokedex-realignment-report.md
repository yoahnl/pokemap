# Pokedex Workspace Realignment Report
## 1. Résumé exécutif
- Le workspace Pokédex a été transformé d’un duo de gros fichiers UI en un sous-dossier de composants UI spécialisés, sans modifier les use cases, les loaders, le save existant ni `project.json`.
- Le flux import JSON, la preview, la liste, la fiche détail et les onglets d’édition existants sont conservés.
- Le réalignement a surtout porté sur la structure du code, la lisibilité produit du wording et la maintenabilité.
- Tous les fichiers UI touchés passent sous la barre des 400 lignes.

## 2. Problèmes initiaux
- `pokedex_workspace.dart` et surtout `pokedex_workspace_views.dart` concentraient presque tout le workspace Pokédex dans des fichiers très longs.
- Le flux import et la fiche détail existaient déjà, mais le code était difficile à relire, à reviewer et à faire évoluer sans risque.
- Le wording visible dans certaines zones restait plus technique que produit.
- La règle locale “aucun fichier UI > 400 lignes” n’était plus respectée.

## 3. Décisions de refactor
- Conservation stricte de la logique métier existante : aucun use case changé, aucun provider métier ajouté, aucun accès JSON direct depuis l’UI.
- Découpage du workspace en `part` files sous `packages/map_editor/lib/src/ui/canvas/pokedex_workspace/` pour préserver les widgets privés et limiter le diff fonctionnel.
- Maintien des points d’entrée existants via deux shims fins : `pokedex_workspace.dart` et `pokedex_workspace_views.dart`.
- Extraction supplémentaire des sous-sections Learnset pour garder tous les fichiers sous 400 lignes.
- Ajustement ciblé du wording visible pour rapprocher l’UX des wireframes fournis, sans déplacer la logique applicative.

## 4. Sub-agents
- UI Architect : a validé le découpage du workspace en sous-composants UI sans nouvelle stack parallèle.
- UX Reviewer : a recommandé de garder le CTA import en tête, des filtres repliables et une séparation nette entre état vide, liste et détail.
- Test Reviewer : a signalé la fragilité potentielle des tests widget basés sur les clés/textes et a insisté pour garder la couverture du flow import.
- Code Reviewer contradictoire : a insisté pour laisser toute l’orchestration import/save dans le body principal et ne pas toucher le panneau explorer hors nécessité.
- Décisions retenues : split en `part` files, `project_explorer_panel.dart` laissé intact, orchestration conservée dans `_PokedexWorkspaceBodyState`.

## 5. Liste des fichiers modifiés
### Modifiés
- `packages/map_editor/lib/src/ui/canvas/pokedex_workspace.dart`
- `packages/map_editor/lib/src/ui/canvas/pokedex_workspace_views.dart`
- `packages/map_editor/test/pokedex_workspace_ui_test.dart`
- `reports/pokedex-realignment-report.md`

### Créés
- `packages/map_editor/lib/src/ui/canvas/pokedex_workspace/pokedex_workspace_page.dart`
- `packages/map_editor/lib/src/ui/canvas/pokedex_workspace/pokedex_workspace_body.dart`
- `packages/map_editor/lib/src/ui/canvas/pokedex_workspace/pokedex_workspace_logic.dart`
- `packages/map_editor/lib/src/ui/canvas/pokedex_workspace/pokedex_empty_state.dart`
- `packages/map_editor/lib/src/ui/canvas/pokedex_workspace/pokedex_feedback_banner.dart`
- `packages/map_editor/lib/src/ui/canvas/pokedex_workspace/pokedex_list_panel.dart`
- `packages/map_editor/lib/src/ui/canvas/pokedex_workspace/pokedex_toolbar.dart`
- `packages/map_editor/lib/src/ui/canvas/pokedex_workspace/pokedex_filters_panel.dart`
- `packages/map_editor/lib/src/ui/canvas/pokedex_workspace/pokedex_list_row.dart`
- `packages/map_editor/lib/src/ui/canvas/pokedex_workspace/pokedex_import_flow.dart`
- `packages/map_editor/lib/src/ui/canvas/pokedex_workspace/pokedex_import_flow_steps.dart`
- `packages/map_editor/lib/src/ui/canvas/pokedex_workspace/pokedex_import_flow_support.dart`
- `packages/map_editor/lib/src/ui/canvas/pokedex_workspace/pokedex_detail_panel.dart`
- `packages/map_editor/lib/src/ui/canvas/pokedex_workspace/pokedex_overview_panel.dart`
- `packages/map_editor/lib/src/ui/canvas/pokedex_workspace/pokedex_metadata_editor.dart`
- `packages/map_editor/lib/src/ui/canvas/pokedex_workspace/pokedex_metadata_editor_fields.dart`
- `packages/map_editor/lib/src/ui/canvas/pokedex_workspace/pokedex_forms_panel.dart`
- `packages/map_editor/lib/src/ui/canvas/pokedex_workspace/pokedex_learnset_panel.dart`
- `packages/map_editor/lib/src/ui/canvas/pokedex_workspace/pokedex_learnset_sections.dart`
- `packages/map_editor/lib/src/ui/canvas/pokedex_workspace/pokedex_evolution_panel.dart`
- `packages/map_editor/lib/src/ui/canvas/pokedex_workspace/pokedex_media_panel.dart`
- `packages/map_editor/lib/src/ui/canvas/pokedex_workspace/pokedex_common_widgets.dart`
- `packages/map_editor/lib/src/ui/canvas/pokedex_workspace/pokedex_formatters.dart`

### Supprimés
- Aucun fichier supprimé.

## 6. Justification fichier par fichier
- `pokedex_workspace.dart` : réduit à un export stable pour ne pas casser les imports existants.
- `pokedex_workspace_views.dart` : réduit à un shim de compatibilité pour les symboles publics existants.
- `pokedex_workspace/pokedex_workspace_page.dart` : nouvelle racine de bibliothèque du workspace et point de composition de tous les `part` files.
- `pokedex_workspace/pokedex_workspace_body.dart` : garde l’orchestration du workspace, la sélection locale, le refresh après save/import et le feedback.
- `pokedex_workspace/pokedex_workspace_logic.dart` : garde les helpers de filtrage/recherche hors du fichier d’orchestration.
- `pokedex_workspace/pokedex_empty_state.dart` : centralise loading/error/empty/no-results/state frame.
- `pokedex_workspace/pokedex_feedback_banner.dart` : isole la bannière de succès/erreur du workspace.
- `pokedex_workspace/pokedex_list_panel.dart` : isole la colonne liste, son header produit et ses états.
- `pokedex_workspace/pokedex_toolbar.dart` : isole la recherche et la barre d’outils de liste.
- `pokedex_workspace/pokedex_filters_panel.dart` : isole les dropdowns de filtres.
- `pokedex_workspace/pokedex_list_row.dart` : isole les rows de liste et les badges types/statut.
- `pokedex_workspace/pokedex_import_flow.dart` : garde l’orchestration du wizard d’import sans toucher aux use cases.
- `pokedex_workspace/pokedex_import_flow_steps.dart` : rend les étapes du wizard plus lisibles et plus produit.
- `pokedex_workspace/pokedex_import_flow_support.dart` : isole les petits widgets de preview/import.
- `pokedex_workspace/pokedex_detail_panel.dart` : isole la colonne droite et son shell d’onglets.
- `pokedex_workspace/pokedex_overview_panel.dart` : isole l’overview.
- `pokedex_workspace/pokedex_metadata_editor.dart` et `pokedex_metadata_editor_fields.dart` : séparent l’édition metadata de ses widgets de champ.
- `pokedex_workspace/pokedex_forms_panel.dart` : isole l’onglet formes/classification.
- `pokedex_workspace/pokedex_learnset_panel.dart` et `pokedex_learnset_sections.dart` : gardent l’onglet learnset sous 400 lignes.
- `pokedex_workspace/pokedex_evolution_panel.dart` : isole l’onglet évolutions.
- `pokedex_workspace/pokedex_media_panel.dart` : isole l’onglet médias.
- `pokedex_workspace/pokedex_common_widgets.dart` et `pokedex_formatters.dart` : regroupent widgets transverses et helpers de texte/parsing UI.
- `pokedex_workspace_ui_test.dart` : une expectation de wording a été réalignée sur le nouvel état vide.

## 7. Commandes exécutées
```bash
find /Users/karim/Project/pokemonProject/packages/map_editor -name AGENTS.md -print
wc -l /Users/karim/Project/pokemonProject/packages/map_editor/lib/src/ui/canvas/pokedex_workspace.dart /Users/karim/Project/pokemonProject/packages/map_editor/lib/src/ui/canvas/pokedex_workspace_views.dart /Users/karim/Project/pokemonProject/packages/map_editor/lib/src/ui/panels/project_explorer_panel.dart
git -C /Users/karim/Project/pokemonProject status --short
rg -n '^class |^Future<|^void show|^String ' /Users/karim/Project/pokemonProject/packages/map_editor/lib/src/ui/canvas/pokedex_workspace.dart /Users/karim/Project/pokemonProject/packages/map_editor/lib/src/ui/canvas/pokedex_workspace_views.dart
rg -n "pokedex_workspace_views\.dart|PokedexWorkspaceLoadingState|PokedexWorkspaceSpeciesList|showPokedexImportFlowSheet|PokedexWorkspaceDetailPane" /Users/karim/Project/pokemonProject/packages/map_editor/lib /Users/karim/Project/pokemonProject/packages/map_editor/test
sed -n '1,220p' /Users/karim/Project/pokemonProject/packages/map_editor/lib/src/ui/canvas/pokedex_workspace.dart
sed -n '1,220p' /Users/karim/Project/pokemonProject/packages/map_editor/lib/src/ui/canvas/pokedex_workspace_views.dart
nl -ba /Users/karim/Project/pokemonProject/packages/map_editor/lib/src/ui/canvas/pokedex_workspace.dart | sed -n '1,700p'
dart format /Users/karim/Project/pokemonProject/packages/map_editor/lib/src/ui/canvas/pokedex_workspace.dart /Users/karim/Project/pokemonProject/packages/map_editor/lib/src/ui/canvas/pokedex_workspace_views.dart /Users/karim/Project/pokemonProject/packages/map_editor/lib/src/ui/canvas/pokedex_workspace /Users/karim/Project/pokemonProject/packages/map_editor/test/pokedex_workspace_ui_test.dart
dart format /Users/karim/Project/pokemonProject/packages/map_editor/lib/src/ui/canvas/pokedex_workspace/pokedex_detail_panel.dart /Users/karim/Project/pokemonProject/packages/map_editor/lib/src/ui/canvas/pokedex_workspace/pokedex_import_flow_steps.dart
dart format /Users/karim/Project/pokemonProject/packages/map_editor/test/pokedex_workspace_ui_test.dart
cd /Users/karim/Project/pokemonProject/packages/map_editor && flutter analyze --no-pub lib/src/ui/canvas/pokedex_workspace.dart lib/src/ui/canvas/pokedex_workspace_views.dart lib/src/ui/canvas/pokedex_workspace lib/src/ui/canvas/pokedex_workspace_loader.dart lib/src/ui/panels/project_explorer_panel.dart test/pokedex_workspace_ui_test.dart test/import_pokemon_json_bundle_use_case_test.dart test/update_pokedex_species_metadata_use_case_test.dart
cd /Users/karim/Project/pokemonProject/packages/map_editor && flutter test test/pokedex_workspace_ui_test.dart test/import_pokemon_json_bundle_use_case_test.dart test/update_pokedex_species_metadata_use_case_test.dart
cd /Users/karim/Project/pokemonProject && git status --short -- packages/map_editor/lib/src/ui/canvas/pokedex_workspace.dart packages/map_editor/lib/src/ui/canvas/pokedex_workspace_views.dart packages/map_editor/lib/src/ui/canvas/pokedex_workspace packages/map_editor/test/pokedex_workspace_ui_test.dart reports/pokedex-realignment-report.md
cd /Users/karim/Project/pokemonProject && git diff --stat -- packages/map_editor/lib/src/ui/canvas/pokedex_workspace.dart packages/map_editor/lib/src/ui/canvas/pokedex_workspace_views.dart packages/map_editor/lib/src/ui/canvas/pokedex_workspace packages/map_editor/test/pokedex_workspace_ui_test.dart reports/pokedex-realignment-report.md
cd /Users/karim/Project/pokemonProject && git ls-files --others --exclude-standard -- packages/map_editor/lib/src/ui/canvas/pokedex_workspace reports/pokedex-realignment-report.md
```
## 8. Résultats réels
- `dart format`
  - première passe : échec de parsing, car la classe `_PokedexWorkspaceBodyState` avait été coupée entre deux `part` files
  - passe finale : `Formatted 26 files (0 changed) in 0.04 seconds.`
- `flutter analyze --no-pub ...`
  - première passe : 4 issues (`editorMacosHelperStyle` inexistant et un `unnecessary_to_list_in_spreads`)
  - passe finale : `No issues found! (ran in 1.3s)`
- `flutter test ...`
  - première passe : 1 échec sur un texte d’état vide devenu obsolète dans le test widget
  - passe finale : `00:05 +41: All tests passed!`

## 9. Incidents rencontrés
- Le premier split a tenté de répartir le corps de `_PokedexWorkspaceBodyState` entre deux `part` files. Dart ne le permet pas ; correction faite en gardant la classe entière dans `pokedex_workspace_body.dart` et en déplaçant seulement les helpers dans une extension.
- Une première passe de wording dans le wizard d’import utilisait `editorMacosHelperStyle`, qui n’existe pas dans la base actuelle. Correction faite avec `editorMacosFormLabelStyle(...).copyWith(...)`.
- Le test widget de l’état vide a cassé après le wording produit. L’assertion a été réalignée sur le nouveau texte visible.
- Un lancement parallèle `flutter analyze` / `flutter test` dans le même package a rencontré le startup lock Flutter normal ; les validations finales ont été relancées en séquentiel.

## 10. Limites restantes
- Le réalignement ne change pas le design system global de l’éditeur ; il rend surtout ce workspace plus clair et plus maintenable.
- `project_explorer_panel.dart` a été laissé intact volontairement pour éviter d’ouvrir un chantier de navigation hors scope.
- Le report n’inclut pas son propre contenu intégral en annexe, pour éviter une récursion infinie. Tous les autres fichiers de code touchés y sont reproduits intégralement.

## 11. État Git utile
### `git status --short -- ...`
```text
 M packages/map_editor/lib/src/ui/canvas/pokedex_workspace.dart
 M packages/map_editor/lib/src/ui/canvas/pokedex_workspace_views.dart
 M packages/map_editor/test/pokedex_workspace_ui_test.dart
?? packages/map_editor/lib/src/ui/canvas/pokedex_workspace/
?? reports/pokedex-realignment-report.md
```
### `git diff --stat -- ...`
```text
 .../lib/src/ui/canvas/pokedex_workspace.dart       |  637 +--
 .../lib/src/ui/canvas/pokedex_workspace_views.dart | 4734 +-------------------
 .../map_editor/test/pokedex_workspace_ui_test.dart |    2 +-
 3 files changed, 23 insertions(+), 5350 deletions(-)
```
### `git ls-files --others --exclude-standard -- ...`
```text
packages/map_editor/lib/src/ui/canvas/pokedex_workspace/pokedex_common_widgets.dart
packages/map_editor/lib/src/ui/canvas/pokedex_workspace/pokedex_detail_panel.dart
packages/map_editor/lib/src/ui/canvas/pokedex_workspace/pokedex_empty_state.dart
packages/map_editor/lib/src/ui/canvas/pokedex_workspace/pokedex_evolution_panel.dart
packages/map_editor/lib/src/ui/canvas/pokedex_workspace/pokedex_feedback_banner.dart
packages/map_editor/lib/src/ui/canvas/pokedex_workspace/pokedex_filters_panel.dart
packages/map_editor/lib/src/ui/canvas/pokedex_workspace/pokedex_formatters.dart
packages/map_editor/lib/src/ui/canvas/pokedex_workspace/pokedex_forms_panel.dart
packages/map_editor/lib/src/ui/canvas/pokedex_workspace/pokedex_import_flow.dart
packages/map_editor/lib/src/ui/canvas/pokedex_workspace/pokedex_import_flow_steps.dart
packages/map_editor/lib/src/ui/canvas/pokedex_workspace/pokedex_import_flow_support.dart
packages/map_editor/lib/src/ui/canvas/pokedex_workspace/pokedex_learnset_panel.dart
packages/map_editor/lib/src/ui/canvas/pokedex_workspace/pokedex_learnset_sections.dart
packages/map_editor/lib/src/ui/canvas/pokedex_workspace/pokedex_list_panel.dart
packages/map_editor/lib/src/ui/canvas/pokedex_workspace/pokedex_list_row.dart
packages/map_editor/lib/src/ui/canvas/pokedex_workspace/pokedex_media_panel.dart
packages/map_editor/lib/src/ui/canvas/pokedex_workspace/pokedex_metadata_editor.dart
packages/map_editor/lib/src/ui/canvas/pokedex_workspace/pokedex_metadata_editor_fields.dart
packages/map_editor/lib/src/ui/canvas/pokedex_workspace/pokedex_overview_panel.dart
packages/map_editor/lib/src/ui/canvas/pokedex_workspace/pokedex_toolbar.dart
packages/map_editor/lib/src/ui/canvas/pokedex_workspace/pokedex_workspace_body.dart
packages/map_editor/lib/src/ui/canvas/pokedex_workspace/pokedex_workspace_logic.dart
packages/map_editor/lib/src/ui/canvas/pokedex_workspace/pokedex_workspace_page.dart
reports/pokedex-realignment-report.md
```
## 12. Checklist finale
- [x] UI découpée proprement
- [x] aucun fichier UI touché ne dépasse 400 lignes
- [x] logique métier intacte
- [x] import non cassé
- [x] save non cassé
- [x] tests passent
- [x] analyse passe
- [x] UX améliorée
- [x] code commenté massivement dans les fichiers manuels touchés
- [x] rapport généré

## 13. Contenu complet des fichiers touchés
_Le report reproduit intégralement tous les fichiers de code modifiés ou créés par ce réalignement. Le report lui-même est exclu de cette annexe pour éviter une récursion infinie._

### `packages/map_editor/lib/src/ui/canvas/pokedex_workspace.dart`
```dart
// Point d'entrée public du workspace Pokédex.
//
// Le widget principal vit maintenant dans un sous-dossier dédié pour garder une
// architecture UI lisible. Cet export maintient le point d'import existant pour
// le reste de l'éditeur et pour les tests.
export 'pokedex_workspace/pokedex_workspace_page.dart';
```

### `packages/map_editor/lib/src/ui/canvas/pokedex_workspace_views.dart`
```dart
// Compatibilité de nommage pour les anciens imports UI du workspace Pokédex.
//
// Les vues ont été réparties dans le sous-dossier `pokedex_workspace/`. On
// réexporte les symboles publics existants pour éviter une casse artificielle du
// code extérieur à ce réalignement.
export 'pokedex_workspace/pokedex_workspace_page.dart'
    show
        PokedexWorkspaceLoadingState,
        PokedexWorkspaceErrorState,
        PokedexWorkspaceNoResultsState,
        PokedexWorkspaceSpeciesList,
        PokedexWorkspaceFeedbackBanner,
        PokedexWorkspaceImportEmptyState,
        PokedexWorkspaceDetailPane,
        PokedexWorkspaceStateCard,
        PokedexWorkspaceStateFrame,
        showPokedexImportFlowSheet;
```

### `packages/map_editor/test/pokedex_workspace_ui_test.dart`
```dart
import 'dart:async';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:macos_ui/macos_ui.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/app/providers/pokedex_providers.dart';
import 'package:map_editor/src/application/errors/application_errors.dart';
import 'package:map_editor/src/application/models/pokemon_database_index.dart';
import 'package:map_editor/src/application/models/pokedex_species_detail.dart';
import 'package:map_editor/src/application/models/pokemon_project_data_models.dart';
import 'package:map_editor/src/application/ports/project_workspace.dart';
import 'package:map_editor/src/application/services/pokemon_database_index.dart';
import 'package:map_editor/src/application/use_cases/import_pokemon_json_bundle_use_case.dart';
import 'package:map_editor/src/application/use_cases/update_pokedex_species_evolution_use_case.dart';
import 'package:map_editor/src/application/use_cases/update_pokedex_species_forms_classification_use_case.dart';
import 'package:map_editor/src/application/use_cases/update_pokedex_species_learnset_use_case.dart';
import 'package:map_editor/src/application/use_cases/project_management_use_cases.dart';
import 'package:map_editor/src/application/use_cases/update_pokedex_species_metadata_use_case.dart';
import 'package:map_editor/src/application/use_cases/update_pokedex_species_media_use_case.dart';
import 'package:map_editor/src/features/editor/state/editor_notifier.dart';
import 'package:map_editor/src/features/editor/state/editor_state.dart';
import 'package:map_editor/src/infrastructure/filesystem/project_filesystem.dart';
import 'package:map_editor/src/infrastructure/repositories/file_repositories.dart';
import 'package:map_editor/src/ui/canvas/pokedex_workspace.dart';
import 'package:map_editor/src/ui/canvas/pokedex_workspace_loader.dart';
import 'package:map_editor/src/ui/panels/project_explorer_panel.dart';

void main() {
  const sampleProject = ProjectManifest(
    name: 'pokedex_ui_test',
    maps: <ProjectMapEntry>[],
    tilesets: <ProjectTilesetEntry>[],
  );

  Future<void> pumpPokedexWidget(
    WidgetTester tester,
    ProviderContainer container, {
    required Widget child,
  }) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1440, 980);
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MacosTheme(
          data: MacosThemeData.light(),
          child: MaterialApp(
            home: CupertinoPageScaffold(
              child: SizedBox(
                width: 1280,
                height: 900,
                child: child,
              ),
            ),
          ),
        ),
      ),
    );
  }

  PokemonDatabaseIndexEntry buildEntry({
    required String id,
    required int nationalDex,
    required String primaryName,
    required List<String> types,
    required int genIntroduced,
    bool isEnabledInProject = true,
  }) {
    return PokemonDatabaseIndexEntry(
      id: id,
      nationalDex: nationalDex,
      primaryName: primaryName,
      genIntroduced: genIntroduced,
      types: types,
      isEnabledInProject: isEnabledInProject,
      refs: PokemonDatabaseIndexRefs(
        learnset: id,
        evolution: id,
        media: id,
      ),
    );
  }

  PokedexSpeciesDetail buildDetail({
    required String id,
    int nationalDex = 1,
    int genIntroduced = 1,
    List<String> types = const <String>['grass', 'poison'],
    String primaryAbility = 'overgrow',
    String? secondaryAbility,
    String? hiddenAbility = 'chlorophyll',
    List<String> otherForms = const <String>[],
    bool isEnabledInProject = true,
    Map<String, String> names = const <String, String>{
      'fr': 'Bulbizarre',
      'en': 'Bulbasaur',
    },
    String? flavorText =
        'Une étrange graine a été plantée sur son dos à la naissance.',
    bool starterEligible = true,
    bool giftOnly = false,
    bool tradeOnly = false,
    PokemonLearnsetFile? learnset,
    PokemonEvolutionFile? evolution,
    PokemonMediaFile? media,
  }) {
    return PokedexSpeciesDetail(
      species: PokemonSpeciesFile(
        id: id,
        slug: id,
        nationalDex: nationalDex,
        names: names,
        speciesName: const <String, String>{
          'fr': 'Pokémon Graine',
          'en': 'Seed Pokemon',
        },
        genIntroduced: genIntroduced,
        typing: PokemonSpeciesTyping(
          types: types,
        ),
        baseStats: const PokemonSpeciesBaseStats(
          hp: 45,
          atk: 49,
          def: 49,
          spa: 65,
          spd: 65,
          spe: 45,
          bst: 318,
        ),
        abilities: PokemonSpeciesAbilities(
          primary: primaryAbility,
          secondary: secondaryAbility,
          hidden: hiddenAbility,
        ),
        breeding: const PokemonSpeciesBreeding(
          genderRatio: <String, double>{'male': 0.875, 'female': 0.125},
          eggGroups: <String>['monster', 'grass'],
          hatchCycles: 20,
        ),
        progression: const PokemonSpeciesProgression(
          growthRateId: 'medium_slow',
          baseExp: 64,
          catchRate: 45,
          baseFriendship: 50,
        ),
        forms: PokemonSpeciesForms(
          baseFormId: id,
          isBaseForm: true,
          formId: 'base',
          otherForms: otherForms,
        ),
        classification: PokemonSpeciesClassification(
          isEnabledInProject: isEnabledInProject,
          isObtainable: true,
        ),
        refs: PokemonSpeciesRefs(
          learnset: id,
          evolution: id,
          media: id,
        ),
        dexContent: PokemonSpeciesDexContent(
          heightM: 0.7,
          weightKg: 6.9,
          color: 'green',
          flavorText: flavorText,
        ),
        gameplayFlags: PokemonSpeciesGameplayFlags(
          starterEligible: starterEligible,
          giftOnly: giftOnly,
          tradeOnly: tradeOnly,
        ),
        sourceMeta: const PokemonSpeciesSourceMeta(
          seededBy: 'ui-test',
          seedVersion: 1,
        ),
      ),
      learnset: learnset ??
          PokemonLearnsetFile(
            speciesId: id,
            startingMoves: const <String>['tackle', 'growl'],
            relearnMoves: const <String>['vine_whip'],
            levelUp: const <PokemonLearnsetLevelUpEntry>[
              PokemonLearnsetLevelUpEntry(
                moveId: 'vine_whip',
                level: 7,
                source: 'level_up',
                versionGroup: 'scarlet-violet',
              ),
            ],
            tm: const <PokemonLearnsetMoveEntry>[
              PokemonLearnsetMoveEntry(
                moveId: 'protect',
                versionGroup: 'scarlet-violet',
              ),
            ],
          ),
      evolution: evolution ??
          const PokemonEvolutionFile(
            speciesId: 'bulbasaur',
            preEvolution: null,
            evolutions: <PokemonEvolutionEntry>[
              PokemonEvolutionEntry(
                targetSpeciesId: 'ivysaur',
                method: 'level_up',
                minLevel: 16,
                conditionText: <String, String>{
                  'fr': 'Évolue au niveau 16',
                  'en': 'Evolves at level 16',
                },
              ),
            ],
          ),
      media: media ??
          PokemonMediaFile(
            speciesId: id,
            defaultFormId: 'base',
            variants: <String, PokemonMediaVariant>{
              'base': PokemonMediaVariant(
                frontStatic: 'assets/pokemon/sprites/$id/front.png',
                backStatic: 'assets/pokemon/sprites/$id/back.png',
                frontShinyStatic: 'assets/pokemon/sprites/$id/front_shiny.png',
                backShinyStatic: 'assets/pokemon/sprites/$id/back_shiny.png',
                icon: 'assets/pokemon/sprites/$id/icon.png',
                party: 'assets/pokemon/sprites/$id/party.png',
                portrait: 'assets/pokemon/portraits/$id.png',
                cry: 'assets/pokemon/cries/$id.ogg',
                animations: <String, PokemonMediaAnimationRef>{
                  'battleFront': PokemonMediaAnimationRef(
                    sheet: 'assets/pokemon/sprites/$id/battle_front_sheet.png',
                    animationId: 'battle_front',
                  ),
                },
              ),
            },
          ),
    );
  }

  Future<void> selectPopupFilter(
    WidgetTester tester, {
    required Key popupKey,
    required String itemLabel,
  }) async {
    if (find.byKey(popupKey).evaluate().isEmpty) {
      final toggleFinder =
          find.byKey(const Key('pokedex-toggle-filters-button'));
      if (toggleFinder.evaluate().isNotEmpty) {
        await tester.tap(toggleFinder);
        await tester.pumpAndSettle();
      }
    }
    await tester.ensureVisible(find.byKey(popupKey));
    await tester.tap(find.byKey(popupKey));
    await tester.pumpAndSettle();
    await tester.tap(find.text(itemLabel).last);
    await tester.pumpAndSettle();
  }

  PokemonDatabaseIndexEntry buildEntryFromSpecies(PokemonSpeciesFile species) {
    final speciesIndexEntry = PokemonSpeciesIndexEntry.fromSpeciesFile(
      species,
      relativePath:
          'data/pokemon/species/${species.nationalDex.toString().padLeft(4, '0')}-${species.slug}.json',
    );
    return PokemonDatabaseIndexEntry.fromSpeciesEntry(
      speciesIndexEntry: speciesIndexEntry,
      species: species,
    );
  }

  PokemonSpeciesFile applyMetadataUpdate(
    PokemonSpeciesFile species,
    UpdatePokedexSpeciesMetadataRequest request,
  ) {
    final normalizedTypes = request.types
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty)
        .toSet()
        .toList(growable: false);
    return PokemonSpeciesFile(
      id: species.id,
      slug: species.slug,
      nationalDex: species.nationalDex,
      names: Map<String, String>.from(request.names),
      speciesName: species.speciesName,
      genIntroduced: species.genIntroduced,
      typing: PokemonSpeciesTyping(
        types: normalizedTypes,
      ),
      baseStats: species.baseStats,
      abilities: species.abilities,
      breeding: species.breeding,
      progression: species.progression,
      forms: species.forms,
      classification: PokemonSpeciesClassification(
        isEnabledInProject: request.isEnabledInProject,
        isObtainable: species.classification.isObtainable,
        isLegendary: species.classification.isLegendary,
        isMythical: species.classification.isMythical,
        isBaby: species.classification.isBaby,
      ),
      refs: species.refs,
      dexContent: PokemonSpeciesDexContent(
        heightM: species.dexContent.heightM,
        weightKg: species.dexContent.weightKg,
        color: species.dexContent.color,
        flavorText: request.flavorText?.trim().isEmpty ?? true
            ? null
            : request.flavorText?.trim(),
      ),
      gameplayFlags: PokemonSpeciesGameplayFlags(
        starterEligible: request.starterEligible,
        giftOnly: request.giftOnly,
        tradeOnly: request.tradeOnly,
      ),
      sourceMeta: species.sourceMeta,
    );
  }

  PokemonSpeciesFile applyFormsClassificationUpdate(
    PokemonSpeciesFile species,
    UpdatePokedexSpeciesFormsClassificationRequest request,
  ) {
    return PokemonSpeciesFile(
      id: species.id,
      slug: species.slug,
      nationalDex: species.nationalDex,
      names: species.names,
      speciesName: species.speciesName,
      genIntroduced: species.genIntroduced,
      typing: species.typing,
      baseStats: species.baseStats,
      abilities: species.abilities,
      breeding: species.breeding,
      progression: species.progression,
      forms: PokemonSpeciesForms(
        baseFormId: request.isBaseForm ? species.id : request.baseFormId.trim(),
        isBaseForm: request.isBaseForm,
        formId: request.formId.trim(),
        formName: request.formName?.trim().isEmpty ?? true
            ? null
            : request.formName?.trim(),
        otherForms: request.otherForms
            .map((value) => value.trim())
            .where(
              (value) => value.isNotEmpty && value != request.formId.trim(),
            )
            .toSet()
            .toList(growable: false),
      ),
      classification: PokemonSpeciesClassification(
        isEnabledInProject: species.classification.isEnabledInProject,
        isObtainable: request.isObtainable,
        isLegendary: request.isLegendary,
        isMythical: request.isMythical,
        isBaby: request.isBaby,
      ),
      refs: species.refs,
      dexContent: species.dexContent,
      gameplayFlags: species.gameplayFlags,
      sourceMeta: species.sourceMeta,
    );
  }

  PokemonLearnsetFile applyLearnsetUpdate(
    PokedexSpeciesDetail detail,
    UpdatePokedexSpeciesLearnsetRequest request,
  ) {
    final learnsetRef = detail.species.refs.learnset.trim();
    return PokemonLearnsetFile(
      speciesId: learnsetRef.isEmpty ? detail.species.id : learnsetRef,
      startingMoves: request.startingMoves
          .map((value) => value.trim())
          .where((value) => value.isNotEmpty)
          .toSet()
          .toList(growable: false),
      relearnMoves: request.relearnMoves
          .map((value) => value.trim())
          .where((value) => value.isNotEmpty)
          .toSet()
          .toList(growable: false),
      levelUp: request.levelUp,
      tm: request.tm,
      tutor: request.tutor,
      egg: request.egg,
      event: request.event,
      transfer: request.transfer,
    );
  }

  PokemonEvolutionFile applyEvolutionUpdate(
    PokedexSpeciesDetail detail,
    UpdatePokedexSpeciesEvolutionRequest request,
  ) {
    final evolutionRef = detail.species.refs.evolution.trim();
    return PokemonEvolutionFile(
      speciesId: evolutionRef.isEmpty ? detail.species.id : evolutionRef,
      preEvolution: request.preEvolution?.trim().isEmpty ?? true
          ? null
          : request.preEvolution?.trim(),
      evolutions: request.evolutions,
    );
  }

  PokemonMediaFile applyMediaUpdate(
    PokedexSpeciesDetail detail,
    UpdatePokedexSpeciesMediaRequest request,
  ) {
    final mediaRef = detail.species.refs.media.trim();
    return PokemonMediaFile(
      speciesId: mediaRef.isEmpty ? detail.species.id : mediaRef,
      defaultFormId: request.defaultFormId.trim(),
      variants: request.variants,
    );
  }

  _FakePokedexWorkspaceStore buildStore({
    required List<PokedexSpeciesDetail> details,
  }) {
    return _FakePokedexWorkspaceStore(
      detailsById: <String, PokedexSpeciesDetail>{
        for (final detail in details) detail.species.id: detail,
      },
      entryBuilder: buildEntryFromSpecies,
      metadataUpdater: applyMetadataUpdate,
      formsClassificationUpdater: applyFormsClassificationUpdate,
      learnsetUpdater: applyLearnsetUpdate,
      evolutionUpdater: applyEvolutionUpdate,
      mediaUpdater: applyMediaUpdate,
    );
  }

  testWidgets('ProjectExplorerPanel shows a Pokédex entry tile',
      (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    // Ce test verrouille seulement la présence de l'entrée UI dans l'éditeur.
    // Il reste volontairement purement en mémoire pour éviter tout bruit
    // filesystem inutile dans un contrôle aussi simple.
    container.read(editorNotifierProvider.notifier).state = const EditorState(
      projectRootPath: '/tmp/pokedex_ui_test',
      project: sampleProject,
    );

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MacosTheme(
          data: MacosThemeData.light(),
          child: const MaterialApp(
            home: CupertinoPageScaffold(
              child: SizedBox(
                width: 420,
                height: 980,
                child: ProjectExplorerPanel(),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.byKey(const Key('pokedex-explorer-entry')), findsOneWidget);
    expect(find.text('Pokédex'), findsWidgets);
    expect(
      find.textContaining('Recherche, import, détail et édition locale'),
      findsOneWidget,
    );
  });

  testWidgets(
      'uses the provider-backed loader by default when no explicit loader is injected',
      (tester) async {
    final container = ProviderContainer(
      overrides: [
        pokedexEntryLoaderProvider.overrideWithValue(
          (_) async => <PokemonDatabaseIndexEntry>[
            buildEntry(
              id: 'treecko',
              nationalDex: 252,
              primaryName: 'Treecko',
              types: <String>['grass'],
              genIntroduced: 3,
            ),
          ],
        ),
      ],
    );
    addTearDown(container.dispose);
    container.read(editorNotifierProvider.notifier).state = const EditorState(
      projectRootPath: '/tmp/pokedex_ui_test',
      project: sampleProject,
      workspaceMode: EditorWorkspaceMode.pokedex,
    );

    await pumpPokedexWidget(
      tester,
      container,
      child: const PokedexWorkspace(),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Treecko'), findsOneWidget);
    expect(find.text('treecko'), findsOneWidget);
    expect(find.byKey(const Key('pokedex-species-list')), findsOneWidget);
  });

  testWidgets(
      'prefers the explicitly injected loader over the provider-backed default',
      (tester) async {
    final container = ProviderContainer(
      overrides: [
        pokedexEntryLoaderProvider.overrideWithValue(
          (_) async => <PokemonDatabaseIndexEntry>[
            buildEntry(
              id: 'treecko',
              nationalDex: 252,
              primaryName: 'Treecko',
              types: <String>['grass'],
              genIntroduced: 3,
            ),
          ],
        ),
      ],
    );
    addTearDown(container.dispose);
    container.read(editorNotifierProvider.notifier).state = const EditorState(
      projectRootPath: '/tmp/pokedex_ui_test',
      project: sampleProject,
      workspaceMode: EditorWorkspaceMode.pokedex,
    );

    await pumpPokedexWidget(
      tester,
      container,
      child: PokedexWorkspace(
        loader: (_) async => <PokemonDatabaseIndexEntry>[
          buildEntry(
            id: 'torchic',
            nationalDex: 255,
            primaryName: 'Torchic',
            types: <String>['fire'],
            genIntroduced: 3,
          ),
        ],
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Torchic'), findsOneWidget);
    expect(find.text('torchic'), findsOneWidget);
    expect(find.text('Treecko'), findsNothing);
    expect(find.text('treecko'), findsNothing);
  });

  testWidgets(
      'renders the editor list shell with import and collapsible filters',
      (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    container.read(editorNotifierProvider.notifier).state = const EditorState(
      projectRootPath: '/tmp/pokedex_ui_test',
      project: sampleProject,
      workspaceMode: EditorWorkspaceMode.pokedex,
    );

    await pumpPokedexWidget(
      tester,
      container,
      child: PokedexWorkspace(
        loader: (_) async => <PokemonDatabaseIndexEntry>[
          buildEntry(
            id: 'bulbasaur',
            nationalDex: 1,
            primaryName: 'Bulbasaur',
            types: <String>['grass', 'poison'],
            genIntroduced: 1,
          ),
          buildEntry(
            id: 'ivysaur',
            nationalDex: 2,
            primaryName: 'Ivysaur',
            types: <String>['grass', 'poison'],
            genIntroduced: 1,
          ),
        ],
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byKey(const Key('pokedex-species-list')), findsOneWidget);
    expect(find.text('Numéro'), findsOneWidget);
    expect(find.text('Nom'), findsOneWidget);
    expect(find.text('ID'), findsOneWidget);
    expect(find.text('Types'), findsOneWidget);
    expect(find.text('#0001'), findsOneWidget);
    expect(find.text('Bulbasaur'), findsOneWidget);
    expect(find.text('bulbasaur'), findsOneWidget);
    expect(find.text('grass'), findsWidgets);
    expect(find.text('poison'), findsWidgets);
    expect(find.byKey(const Key('pokedex-import-button')), findsOneWidget);
    expect(
      find.byKey(const Key('pokedex-toggle-filters-button')),
      findsOneWidget,
    );
    expect(find.byKey(const Key('pokedex-filters-panel')), findsNothing);
    expect(find.byKey(const Key('pokedex-detail-empty-state')), findsOneWidget);
  });

  testWidgets('selects a species row and shows the overview detail pane',
      (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    container.read(editorNotifierProvider.notifier).state = const EditorState(
      projectRootPath: '/tmp/pokedex_ui_test',
      project: sampleProject,
      workspaceMode: EditorWorkspaceMode.pokedex,
    );

    await pumpPokedexWidget(
      tester,
      container,
      child: PokedexWorkspace(
        loader: (_) async => <PokemonDatabaseIndexEntry>[
          buildEntry(
            id: 'bulbasaur',
            nationalDex: 1,
            primaryName: 'Bulbasaur',
            types: <String>['grass', 'poison'],
            genIntroduced: 1,
          ),
          buildEntry(
            id: 'ivysaur',
            nationalDex: 2,
            primaryName: 'Ivysaur',
            types: <String>['grass', 'poison'],
            genIntroduced: 1,
          ),
        ],
        detailLoader: (_, speciesId) async => buildDetail(id: speciesId),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byKey(const Key('pokedex-detail-empty-state')), findsOneWidget);

    await tester.tap(find.byKey(const Key('pokedex-row-bulbasaur')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byKey(const Key('pokedex-detail-pane')), findsOneWidget);
    expect(find.byKey(const Key('pokedex-overview-tab')), findsOneWidget);
    expect(find.text('Nom principal'), findsOneWidget);
    expect(find.text('Bulbasaur'), findsWidgets);
    expect(find.text('Talent principal'), findsOneWidget);
    expect(find.text('overgrow'), findsOneWidget);
    expect(find.text('Références locales'), findsOneWidget);
    expect(find.text('bulbasaur'), findsWidgets);
  });

  testWidgets('switches to forms learnset evolutions and media tabs',
      (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    container.read(editorNotifierProvider.notifier).state = const EditorState(
      projectRootPath: '/tmp/pokedex_ui_test',
      project: sampleProject,
      workspaceMode: EditorWorkspaceMode.pokedex,
    );

    await pumpPokedexWidget(
      tester,
      container,
      child: PokedexWorkspace(
        loader: (_) async => <PokemonDatabaseIndexEntry>[
          buildEntry(
            id: 'bulbasaur',
            nationalDex: 1,
            primaryName: 'Bulbasaur',
            types: <String>['grass', 'poison'],
            genIntroduced: 1,
          ),
        ],
        detailLoader: (_, speciesId) async => buildDetail(
          id: speciesId,
          otherForms: const <String>['mega'],
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    await tester.tap(find.byKey(const Key('pokedex-row-bulbasaur')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    await tester.tap(find.byKey(const Key('pokedex-tab-forms')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('pokedex-forms-tab')), findsOneWidget);
    expect(find.text('Forme courante'), findsOneWidget);
    expect(find.textContaining('mega'), findsOneWidget);
    expect(find.text('Formes et classification'), findsOneWidget);

    await tester.tap(find.byKey(const Key('pokedex-tab-learnset')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('pokedex-learnset-tab')), findsOneWidget);
    expect(find.text('vine_whip • niveau 7'), findsOneWidget);
    expect(find.text('scarlet-violet • source level_up'), findsOneWidget);

    await tester.tap(find.byKey(const Key('pokedex-tab-evolutions')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('pokedex-evolutions-tab')), findsOneWidget);
    expect(find.text('Pré-évolution'), findsOneWidget);
    expect(find.text('Évolue au niveau 16'), findsOneWidget);

    await tester.tap(find.byKey(const Key('pokedex-tab-media')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('pokedex-media-tab')), findsOneWidget);
    expect(
      find.text('assets/pokemon/sprites/bulbasaur/front.png'),
      findsOneWidget,
    );
    expect(
      find.text('assets/pokemon/portraits/bulbasaur.png'),
      findsOneWidget,
    );
    expect(find.textContaining('battleFront: battle_front'), findsOneWidget);
  });

  testWidgets(
      'clears the selection and resets the detail pane when search hides it',
      (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    container.read(editorNotifierProvider.notifier).state = const EditorState(
      projectRootPath: '/tmp/pokedex_ui_test',
      project: sampleProject,
      workspaceMode: EditorWorkspaceMode.pokedex,
    );

    await pumpPokedexWidget(
      tester,
      container,
      child: PokedexWorkspace(
        loader: (_) async => <PokemonDatabaseIndexEntry>[
          buildEntry(
            id: 'bulbasaur',
            nationalDex: 1,
            primaryName: 'Bulbasaur',
            types: <String>['grass', 'poison'],
            genIntroduced: 1,
          ),
          buildEntry(
            id: 'ivysaur',
            nationalDex: 2,
            primaryName: 'Ivysaur',
            types: <String>['grass', 'poison'],
            genIntroduced: 1,
          ),
        ],
        detailLoader: (_, speciesId) async => buildDetail(id: speciesId),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    await tester.tap(find.byKey(const Key('pokedex-row-bulbasaur')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('pokedex-tab-media')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('pokedex-media-tab')), findsOneWidget);

    await tester.enterText(
      find.byKey(const Key('pokedex-search-field')),
      'ivy',
    );
    await tester.pump();
    await tester.pump();

    expect(find.byKey(const Key('pokedex-detail-empty-state')), findsOneWidget);
    expect(find.byKey(const Key('pokedex-detail-pane')), findsNothing);

    await tester.enterText(
      find.byKey(const Key('pokedex-search-field')),
      '',
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('pokedex-row-bulbasaur')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('pokedex-overview-tab')), findsOneWidget);
    expect(find.byKey(const Key('pokedex-media-tab')), findsNothing);
  });

  testWidgets(
      'clears the selection and resets the detail pane when filters hide it',
      (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    container.read(editorNotifierProvider.notifier).state = const EditorState(
      projectRootPath: '/tmp/pokedex_ui_test',
      project: sampleProject,
      workspaceMode: EditorWorkspaceMode.pokedex,
    );

    await pumpPokedexWidget(
      tester,
      container,
      child: PokedexWorkspace(
        loader: (_) async => <PokemonDatabaseIndexEntry>[
          buildEntry(
            id: 'bulbasaur',
            nationalDex: 1,
            primaryName: 'Bulbasaur',
            types: <String>['grass', 'poison'],
            genIntroduced: 1,
          ),
          buildEntry(
            id: 'treecko',
            nationalDex: 252,
            primaryName: 'Treecko',
            types: <String>['grass'],
            genIntroduced: 3,
          ),
        ],
        detailLoader: (_, speciesId) async => buildDetail(id: speciesId),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    await tester.tap(find.byKey(const Key('pokedex-row-bulbasaur')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('pokedex-tab-learnset')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('pokedex-learnset-tab')), findsOneWidget);

    await selectPopupFilter(
      tester,
      popupKey: const Key('pokedex-generation-filter'),
      itemLabel: 'Génération 3',
    );
    await tester.pump();

    expect(find.byKey(const Key('pokedex-detail-empty-state')), findsOneWidget);
    expect(find.byKey(const Key('pokedex-detail-pane')), findsNothing);

    await selectPopupFilter(
      tester,
      popupKey: const Key('pokedex-generation-filter'),
      itemLabel: 'Toutes gén.',
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('pokedex-row-bulbasaur')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('pokedex-overview-tab')), findsOneWidget);
    expect(find.byKey(const Key('pokedex-learnset-tab')), findsNothing);
  });

  testWidgets(
      'shows the search field and simple filters in the Pokédex workspace',
      (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    container.read(editorNotifierProvider.notifier).state = const EditorState(
      projectRootPath: '/tmp/pokedex_ui_test',
      project: sampleProject,
      workspaceMode: EditorWorkspaceMode.pokedex,
    );

    await pumpPokedexWidget(
      tester,
      container,
      child: PokedexWorkspace(
        loader: (_) async => <PokemonDatabaseIndexEntry>[
          buildEntry(
            id: 'bulbasaur',
            nationalDex: 1,
            primaryName: 'Bulbasaur',
            types: <String>['grass', 'poison'],
            genIntroduced: 1,
          ),
        ],
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byKey(const Key('pokedex-search-field')), findsOneWidget);
    expect(find.byKey(const Key('pokedex-filters-panel')), findsNothing);
    await tester.tap(find.byKey(const Key('pokedex-toggle-filters-button')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('pokedex-filters-panel')), findsOneWidget);
    expect(find.byKey(const Key('pokedex-type-filter')), findsOneWidget);
    expect(find.byKey(const Key('pokedex-generation-filter')), findsOneWidget);
    expect(find.byKey(const Key('pokedex-status-filter')), findsOneWidget);
  });

  testWidgets('filters instantly by species primary name', (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    container.read(editorNotifierProvider.notifier).state = const EditorState(
      projectRootPath: '/tmp/pokedex_ui_test',
      project: sampleProject,
      workspaceMode: EditorWorkspaceMode.pokedex,
    );

    await pumpPokedexWidget(
      tester,
      container,
      child: PokedexWorkspace(
        loader: (_) async => <PokemonDatabaseIndexEntry>[
          buildEntry(
            id: 'bulbasaur',
            nationalDex: 1,
            primaryName: 'Bulbasaur',
            types: <String>['grass', 'poison'],
            genIntroduced: 1,
          ),
          buildEntry(
            id: 'ivysaur',
            nationalDex: 2,
            primaryName: 'Ivysaur',
            types: <String>['grass', 'poison'],
            genIntroduced: 1,
          ),
        ],
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    await tester.enterText(
      find.byKey(const Key('pokedex-search-field')),
      'ivy',
    );
    await tester.pump();

    expect(find.text('Ivysaur'), findsOneWidget);
    expect(find.text('Bulbasaur'), findsNothing);
  });

  testWidgets('filters instantly by species id', (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    container.read(editorNotifierProvider.notifier).state = const EditorState(
      projectRootPath: '/tmp/pokedex_ui_test',
      project: sampleProject,
      workspaceMode: EditorWorkspaceMode.pokedex,
    );

    await pumpPokedexWidget(
      tester,
      container,
      child: PokedexWorkspace(
        loader: (_) async => <PokemonDatabaseIndexEntry>[
          buildEntry(
            id: 'bulbasaur',
            nationalDex: 1,
            primaryName: 'Bulbasaur',
            types: <String>['grass', 'poison'],
            genIntroduced: 1,
          ),
          buildEntry(
            id: 'ivysaur',
            nationalDex: 2,
            primaryName: 'Ivysaur',
            types: <String>['grass', 'poison'],
            genIntroduced: 1,
          ),
        ],
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    await tester.enterText(
      find.byKey(const Key('pokedex-search-field')),
      'bulb',
    );
    await tester.pump();

    expect(find.text('Bulbasaur'), findsOneWidget);
    expect(find.text('Ivysaur'), findsNothing);
  });

  testWidgets('filters instantly by dex number with exact matching only',
      (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    container.read(editorNotifierProvider.notifier).state = const EditorState(
      projectRootPath: '/tmp/pokedex_ui_test',
      project: sampleProject,
      workspaceMode: EditorWorkspaceMode.pokedex,
    );

    await pumpPokedexWidget(
      tester,
      container,
      child: PokedexWorkspace(
        loader: (_) async => <PokemonDatabaseIndexEntry>[
          buildEntry(
            id: 'bulbasaur',
            nationalDex: 1,
            primaryName: 'Bulbasaur',
            types: <String>['grass', 'poison'],
            genIntroduced: 1,
          ),
          buildEntry(
            id: 'ivysaur',
            nationalDex: 10,
            primaryName: 'Ivysaur',
            types: <String>['grass', 'poison'],
            genIntroduced: 1,
          ),
        ],
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    await tester.enterText(
      find.byKey(const Key('pokedex-search-field')),
      '#0001',
    );
    await tester.pump();

    expect(find.text('Bulbasaur'), findsOneWidget);
    expect(find.text('Ivysaur'), findsNothing);
  });

  testWidgets('empty query restores the full list', (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    container.read(editorNotifierProvider.notifier).state = const EditorState(
      projectRootPath: '/tmp/pokedex_ui_test',
      project: sampleProject,
      workspaceMode: EditorWorkspaceMode.pokedex,
    );

    await pumpPokedexWidget(
      tester,
      container,
      child: PokedexWorkspace(
        loader: (_) async => <PokemonDatabaseIndexEntry>[
          buildEntry(
            id: 'bulbasaur',
            nationalDex: 1,
            primaryName: 'Bulbasaur',
            types: <String>['grass', 'poison'],
            genIntroduced: 1,
          ),
          buildEntry(
            id: 'ivysaur',
            nationalDex: 2,
            primaryName: 'Ivysaur',
            types: <String>['grass', 'poison'],
            genIntroduced: 1,
          ),
        ],
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    await tester.enterText(
      find.byKey(const Key('pokedex-search-field')),
      'ivy',
    );
    await tester.pump();
    expect(find.text('Ivysaur'), findsOneWidget);
    expect(find.text('Bulbasaur'), findsNothing);

    await tester.enterText(
      find.byKey(const Key('pokedex-search-field')),
      '   ',
    );
    await tester.pump();

    expect(find.text('Bulbasaur'), findsOneWidget);
    expect(find.text('Ivysaur'), findsOneWidget);
  });

  testWidgets('shows a dedicated no results state when search matches nothing',
      (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    container.read(editorNotifierProvider.notifier).state = const EditorState(
      projectRootPath: '/tmp/pokedex_ui_test',
      project: sampleProject,
      workspaceMode: EditorWorkspaceMode.pokedex,
    );

    await pumpPokedexWidget(
      tester,
      container,
      child: PokedexWorkspace(
        loader: (_) async => <PokemonDatabaseIndexEntry>[
          buildEntry(
            id: 'bulbasaur',
            nationalDex: 1,
            primaryName: 'Bulbasaur',
            types: <String>['grass', 'poison'],
            genIntroduced: 1,
          ),
        ],
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    await tester.enterText(
      find.byKey(const Key('pokedex-search-field')),
      'zzz',
    );
    await tester.pump();

    expect(find.byKey(const Key('pokedex-no-results-state')), findsOneWidget);
    expect(
      find.textContaining('Aucun résultat avec les critères actuels.'),
      findsOneWidget,
    );
    expect(find.textContaining('Recherche actuelle : "zzz"'), findsOneWidget);
    // Le champ reste visible pour corriger immédiatement la query.
    expect(find.byKey(const Key('pokedex-search-field')), findsOneWidget);
  });

  testWidgets('filters instantly by type', (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    container.read(editorNotifierProvider.notifier).state = const EditorState(
      projectRootPath: '/tmp/pokedex_ui_test',
      project: sampleProject,
      workspaceMode: EditorWorkspaceMode.pokedex,
    );

    await pumpPokedexWidget(
      tester,
      container,
      child: PokedexWorkspace(
        loader: (_) async => <PokemonDatabaseIndexEntry>[
          buildEntry(
            id: 'bulbasaur',
            nationalDex: 1,
            primaryName: 'Bulbasaur',
            types: <String>['grass', 'poison'],
            genIntroduced: 1,
          ),
          buildEntry(
            id: 'charmander',
            nationalDex: 4,
            primaryName: 'Charmander',
            types: <String>['fire'],
            genIntroduced: 1,
          ),
        ],
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    await selectPopupFilter(
      tester,
      popupKey: const Key('pokedex-type-filter'),
      itemLabel: 'fire',
    );

    expect(find.text('Charmander'), findsOneWidget);
    expect(find.text('Bulbasaur'), findsNothing);
  });

  testWidgets('filters instantly by generation', (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    container.read(editorNotifierProvider.notifier).state = const EditorState(
      projectRootPath: '/tmp/pokedex_ui_test',
      project: sampleProject,
      workspaceMode: EditorWorkspaceMode.pokedex,
    );

    await pumpPokedexWidget(
      tester,
      container,
      child: PokedexWorkspace(
        loader: (_) async => <PokemonDatabaseIndexEntry>[
          buildEntry(
            id: 'bulbasaur',
            nationalDex: 1,
            primaryName: 'Bulbasaur',
            types: <String>['grass', 'poison'],
            genIntroduced: 1,
          ),
          buildEntry(
            id: 'treecko',
            nationalDex: 252,
            primaryName: 'Treecko',
            types: <String>['grass'],
            genIntroduced: 3,
          ),
        ],
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    await selectPopupFilter(
      tester,
      popupKey: const Key('pokedex-generation-filter'),
      itemLabel: 'Génération 3',
    );

    expect(find.text('Treecko'), findsOneWidget);
    expect(find.text('Bulbasaur'), findsNothing);
  });

  testWidgets('combines text search with simple filters', (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    container.read(editorNotifierProvider.notifier).state = const EditorState(
      projectRootPath: '/tmp/pokedex_ui_test',
      project: sampleProject,
      workspaceMode: EditorWorkspaceMode.pokedex,
    );

    await pumpPokedexWidget(
      tester,
      container,
      child: PokedexWorkspace(
        loader: (_) async => <PokemonDatabaseIndexEntry>[
          buildEntry(
            id: 'bulbasaur',
            nationalDex: 1,
            primaryName: 'Bulbasaur',
            types: <String>['grass', 'poison'],
            genIntroduced: 1,
          ),
          buildEntry(
            id: 'bellsprout',
            nationalDex: 69,
            primaryName: 'Bellsprout',
            types: <String>['grass', 'poison'],
            genIntroduced: 1,
          ),
          buildEntry(
            id: 'treecko',
            nationalDex: 252,
            primaryName: 'Treecko',
            types: <String>['grass'],
            genIntroduced: 3,
          ),
        ],
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    await tester.enterText(
      find.byKey(const Key('pokedex-search-field')),
      'tree',
    );
    await tester.pump();
    await selectPopupFilter(
      tester,
      popupKey: const Key('pokedex-type-filter'),
      itemLabel: 'grass',
    );
    await selectPopupFilter(
      tester,
      popupKey: const Key('pokedex-generation-filter'),
      itemLabel: 'Génération 3',
    );

    expect(find.text('Treecko'), findsOneWidget);
    expect(find.text('Bulbasaur'), findsNothing);
    expect(find.text('Bellsprout'), findsNothing);
  });

  testWidgets('combines simple filters together', (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    container.read(editorNotifierProvider.notifier).state = const EditorState(
      projectRootPath: '/tmp/pokedex_ui_test',
      project: sampleProject,
      workspaceMode: EditorWorkspaceMode.pokedex,
    );

    await pumpPokedexWidget(
      tester,
      container,
      child: PokedexWorkspace(
        loader: (_) async => <PokemonDatabaseIndexEntry>[
          buildEntry(
            id: 'bulbasaur',
            nationalDex: 1,
            primaryName: 'Bulbasaur',
            types: <String>['grass', 'poison'],
            genIntroduced: 1,
          ),
          buildEntry(
            id: 'treecko',
            nationalDex: 252,
            primaryName: 'Treecko',
            types: <String>['grass'],
            genIntroduced: 3,
          ),
          buildEntry(
            id: 'torchic',
            nationalDex: 255,
            primaryName: 'Torchic',
            types: <String>['fire'],
            genIntroduced: 3,
          ),
        ],
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    await selectPopupFilter(
      tester,
      popupKey: const Key('pokedex-type-filter'),
      itemLabel: 'grass',
    );
    await selectPopupFilter(
      tester,
      popupKey: const Key('pokedex-generation-filter'),
      itemLabel: 'Génération 3',
    );

    expect(find.text('Treecko'), findsOneWidget);
    expect(find.text('Bulbasaur'), findsNothing);
    expect(find.text('Torchic'), findsNothing);
  });

  testWidgets('clearing all filters restores the full list', (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    container.read(editorNotifierProvider.notifier).state = const EditorState(
      projectRootPath: '/tmp/pokedex_ui_test',
      project: sampleProject,
      workspaceMode: EditorWorkspaceMode.pokedex,
    );

    await pumpPokedexWidget(
      tester,
      container,
      child: PokedexWorkspace(
        loader: (_) async => <PokemonDatabaseIndexEntry>[
          buildEntry(
            id: 'bulbasaur',
            nationalDex: 1,
            primaryName: 'Bulbasaur',
            types: <String>['grass', 'poison'],
            genIntroduced: 1,
          ),
          buildEntry(
            id: 'treecko',
            nationalDex: 252,
            primaryName: 'Treecko',
            types: <String>['grass'],
            genIntroduced: 3,
          ),
        ],
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    await selectPopupFilter(
      tester,
      popupKey: const Key('pokedex-generation-filter'),
      itemLabel: 'Génération 3',
    );
    expect(find.text('Treecko'), findsOneWidget);
    expect(find.text('Bulbasaur'), findsNothing);

    await selectPopupFilter(
      tester,
      popupKey: const Key('pokedex-generation-filter'),
      itemLabel: 'Toutes gén.',
    );

    expect(find.text('Bulbasaur'), findsOneWidget);
    expect(find.text('Treecko'), findsOneWidget);
  });

  testWidgets('shows no results when simple filters eliminate the list',
      (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    container.read(editorNotifierProvider.notifier).state = const EditorState(
      projectRootPath: '/tmp/pokedex_ui_test',
      project: sampleProject,
      workspaceMode: EditorWorkspaceMode.pokedex,
    );

    await pumpPokedexWidget(
      tester,
      container,
      child: PokedexWorkspace(
        loader: (_) async => <PokemonDatabaseIndexEntry>[
          buildEntry(
            id: 'bulbasaur',
            nationalDex: 1,
            primaryName: 'Bulbasaur',
            types: <String>['grass', 'poison'],
            genIntroduced: 1,
          ),
        ],
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    await selectPopupFilter(
      tester,
      popupKey: const Key('pokedex-type-filter'),
      itemLabel: 'poison',
    );
    await selectPopupFilter(
      tester,
      popupKey: const Key('pokedex-generation-filter'),
      itemLabel: 'Génération 1',
    );
    await tester.enterText(
      find.byKey(const Key('pokedex-search-field')),
      'zzz',
    );
    await tester.pump();

    expect(find.byKey(const Key('pokedex-no-results-state')), findsOneWidget);
    expect(find.textContaining('Aucun résultat avec les critères actuels.'),
        findsOneWidget);
    expect(find.textContaining('Recherche actuelle : "zzz".'), findsOneWidget);
    expect(find.textContaining('Type : poison.'), findsOneWidget);
    expect(find.textContaining('Génération : 1.'), findsOneWidget);
    expect(find.byKey(const Key('pokedex-search-field')), findsOneWidget);
    expect(find.byKey(const Key('pokedex-type-filter')), findsOneWidget);
    expect(find.byKey(const Key('pokedex-generation-filter')), findsOneWidget);
  });

  testWidgets('filters instantly by enabled status', (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    container.read(editorNotifierProvider.notifier).state = const EditorState(
      projectRootPath: '/tmp/pokedex_ui_test',
      project: sampleProject,
      workspaceMode: EditorWorkspaceMode.pokedex,
    );

    await pumpPokedexWidget(
      tester,
      container,
      child: PokedexWorkspace(
        loader: (_) async => <PokemonDatabaseIndexEntry>[
          buildEntry(
            id: 'bulbasaur',
            nationalDex: 1,
            primaryName: 'Bulbasaur',
            types: <String>['grass', 'poison'],
            genIntroduced: 1,
            isEnabledInProject: true,
          ),
          buildEntry(
            id: 'treecko',
            nationalDex: 252,
            primaryName: 'Treecko',
            types: <String>['grass'],
            genIntroduced: 3,
            isEnabledInProject: false,
          ),
        ],
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    await selectPopupFilter(
      tester,
      popupKey: const Key('pokedex-status-filter'),
      itemLabel: 'Activées',
    );

    expect(find.text('Bulbasaur'), findsOneWidget);
    expect(find.text('Treecko'), findsNothing);

    await selectPopupFilter(
      tester,
      popupKey: const Key('pokedex-status-filter'),
      itemLabel: 'Désactivées',
    );

    expect(find.text('Bulbasaur'), findsNothing);
    expect(find.text('Treecko'), findsOneWidget);
  });

  testWidgets(
      'enters edit mode saves simple metadata and keeps generation filtering stable',
      (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final store = buildStore(
      details: <PokedexSpeciesDetail>[
        buildDetail(
          id: 'bulbasaur',
          nationalDex: 1,
          genIntroduced: 1,
          names: const <String, String>{
            'fr': 'Bulbizarre',
            'en': 'Bulbasaur',
          },
          isEnabledInProject: true,
          starterEligible: true,
        ),
        buildDetail(
          id: 'treecko',
          nationalDex: 252,
          genIntroduced: 3,
          types: const <String>['grass'],
          names: const <String, String>{
            'fr': 'Arcko',
            'en': 'Treecko',
          },
        ),
      ],
    );

    container.read(editorNotifierProvider.notifier).state = const EditorState(
      projectRootPath: '/tmp/pokedex_ui_test',
      project: sampleProject,
      workspaceMode: EditorWorkspaceMode.pokedex,
    );

    await pumpPokedexWidget(
      tester,
      container,
      child: PokedexWorkspace(
        loader: store.loadEntries,
        detailLoader: store.loadDetail,
        metadataSaver: store.save,
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    await selectPopupFilter(
      tester,
      popupKey: const Key('pokedex-generation-filter'),
      itemLabel: 'Génération 1',
    );
    expect(find.text('Bulbasaur'), findsOneWidget);
    expect(find.text('Treecko'), findsNothing);

    await tester.tap(find.byKey(const Key('pokedex-row-bulbasaur')));
    await tester.pumpAndSettle();
    await tester
        .ensureVisible(find.byKey(const Key('pokedex-edit-metadata-button')));
    await tester.tap(find.byKey(const Key('pokedex-edit-metadata-button')));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.byKey(const Key('pokedex-enabled-switch')));
    await tester.tap(find.byKey(const Key('pokedex-enabled-switch')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('pokedex-name-field-fr')),
      'Bulbizarre Projet',
    );
    await tester.enterText(
      find.byKey(const Key('pokedex-name-field-en')),
      'Bulbasaur Project',
    );
    await tester.enterText(
      find.byKey(const Key('pokedex-type-field-0')),
      'electric',
    );
    await tester.enterText(
      find.byKey(const Key('pokedex-type-field-1')),
      'fairy',
    );
    await tester.enterText(
      find.byKey(const Key('pokedex-flavor-text-field')),
      'Texte édité depuis la fiche locale.',
    );
    await tester.tap(find.byKey(const Key('pokedex-gift-only-switch')));
    await tester.pumpAndSettle();
    await tester
        .ensureVisible(find.byKey(const Key('pokedex-save-metadata-button')));
    await tester.tap(find.byKey(const Key('pokedex-save-metadata-button')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(store.saveCallCount, 1);
    expect(store.speciesById('bulbasaur').classification.isEnabledInProject,
        isFalse);
    expect(store.speciesById('bulbasaur').names['fr'], 'Bulbizarre Projet');
    expect(store.speciesById('bulbasaur').names['en'], 'Bulbasaur Project');
    expect(
      store.speciesById('bulbasaur').typing.types,
      <String>['electric', 'fairy'],
    );
    expect(
      store.speciesById('bulbasaur').dexContent.flavorText,
      'Texte édité depuis la fiche locale.',
    );
    expect(store.speciesById('bulbasaur').gameplayFlags.giftOnly, isTrue);

    expect(find.text('Bulbasaur Project'), findsWidgets);
    expect(find.text('electric'), findsWidgets);
    expect(find.text('fairy'), findsWidgets);
    expect(find.text('Treecko'), findsNothing);
    expect(find.byKey(const Key('pokedex-name-field-fr')), findsNothing);
  });

  testWidgets('imports a pokemon from the wizard and refreshes the workspace',
      (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final importedDetailsById = <String, PokedexSpeciesDetail>{};
    var entries = <PokemonDatabaseIndexEntry>[];
    var previewCallCount = 0;
    var importCallCount = 0;
    String? selectedPathSeenByPreview;
    String? selectedPathSeenByImport;

    container.read(editorNotifierProvider.notifier).state = const EditorState(
      projectRootPath: '/tmp/pokedex_import_ui_test',
      project: sampleProject,
      workspaceMode: EditorWorkspaceMode.pokedex,
    );

    await pumpPokedexWidget(
      tester,
      container,
      child: PokedexWorkspace(
        loader: (_) async => entries,
        detailLoader: (_, speciesId) async => importedDetailsById[speciesId]!,
        pickJsonImportFile: () async => '/tmp/source/species/pikachu.json',
        importPreviewer: (_, absoluteSpeciesSourcePath) async {
          previewCallCount += 1;
          selectedPathSeenByPreview = absoluteSpeciesSourcePath;
          return const PokemonJsonImportPreview(
            speciesId: 'pikachu',
            nationalDex: 25,
            primaryName: 'Pikachu',
            types: <String>['electric'],
            learnset: PokemonImportArtifactPreview(
              label: 'Learnset',
              refId: 'pikachu',
              status: PokemonImportPreviewStatus.found,
              absoluteSourcePath: '/tmp/source/learnsets/pikachu.json',
            ),
            evolution: PokemonImportArtifactPreview(
              label: 'Évolutions',
              refId: 'pikachu',
              status: PokemonImportPreviewStatus.found,
              absoluteSourcePath: '/tmp/source/evolutions/pikachu.json',
            ),
            media: PokemonImportArtifactPreview(
              label: 'Médias',
              refId: 'pikachu',
              status: PokemonImportPreviewStatus.missing,
            ),
          );
        },
        importer: (_, absoluteSpeciesSourcePath) async {
          importCallCount += 1;
          selectedPathSeenByImport = absoluteSpeciesSourcePath;
          final detail = buildDetail(
            id: 'pikachu',
            nationalDex: 25,
            types: const <String>['electric'],
            primaryAbility: 'static',
            hiddenAbility: 'lightning_rod',
            names: const <String, String>{
              'fr': 'Pikachu',
              'en': 'Pikachu',
            },
            flavorText: 'Il emmagasine l’électricité dans ses joues.',
          );
          importedDetailsById['pikachu'] = detail;
          entries = <PokemonDatabaseIndexEntry>[
            buildEntryFromSpecies(detail.species),
          ];
          return const PokemonJsonImportResult(
            preview: PokemonJsonImportPreview(
              speciesId: 'pikachu',
              nationalDex: 25,
              primaryName: 'Pikachu',
              types: <String>['electric'],
              learnset: PokemonImportArtifactPreview(
                label: 'Learnset',
                refId: 'pikachu',
                status: PokemonImportPreviewStatus.found,
              ),
              evolution: PokemonImportArtifactPreview(
                label: 'Évolutions',
                refId: 'pikachu',
                status: PokemonImportPreviewStatus.found,
              ),
              media: PokemonImportArtifactPreview(
                label: 'Médias',
                refId: 'pikachu',
                status: PokemonImportPreviewStatus.missing,
              ),
            ),
            importedSpecies: true,
            importedLearnset: true,
            importedEvolution: true,
            importedMedia: false,
          );
        },
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byKey(const Key('pokedex-empty-state')), findsOneWidget);
    await tester
        .tap(find.byKey(const Key('pokedex-empty-state-import-button')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('pokedex-import-source-step')), findsOneWidget);
    await tester.tap(
      find.byKey(const Key('pokedex-import-source-continue-button')),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('pokedex-import-json-step')), findsOneWidget);
    await tester.tap(
      find.byKey(const Key('pokedex-import-pick-json-file-button')),
    );
    await tester.pumpAndSettle();
    expect(find.text('pikachu.json'), findsOneWidget);

    await tester.tap(
      find.byKey(const Key('pokedex-import-json-continue-button')),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(previewCallCount, 1);
    expect(selectedPathSeenByPreview, '/tmp/source/species/pikachu.json');
    expect(
        find.byKey(const Key('pokedex-import-preview-step')), findsOneWidget);
    expect(
        find.byKey(const Key('pokedex-import-preview-title')), findsOneWidget);
    expect(find.text('#025 Pikachu'), findsOneWidget);
    expect(find.text('Type : electric'), findsOneWidget);
    expect(find.text('Learnset trouvé'), findsOneWidget);
    expect(find.text('Évolutions trouvées'), findsOneWidget);
    expect(find.text('Médias manquants'), findsOneWidget);

    await tester.tap(find.byKey(const Key('pokedex-import-confirm-button')));
    await tester.pumpAndSettle();

    expect(importCallCount, 1);
    expect(selectedPathSeenByImport, '/tmp/source/species/pikachu.json');
    expect(find.byKey(const Key('pokedex-feedback-banner')), findsOneWidget);
    expect(find.textContaining('Pikachu'), findsWidgets);
    expect(find.byKey(const Key('pokedex-row-pikachu')), findsOneWidget);
    expect(find.byKey(const Key('pokedex-detail-pane')), findsOneWidget);
    expect(find.text('electric'), findsWidgets);
  });

  testWidgets('cancel discards metadata changes without writing',
      (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final store = buildStore(
      details: <PokedexSpeciesDetail>[
        buildDetail(
          id: 'bulbasaur',
          names: const <String, String>{
            'fr': 'Bulbizarre',
            'en': 'Bulbasaur',
          },
          isEnabledInProject: true,
        ),
      ],
    );

    container.read(editorNotifierProvider.notifier).state = const EditorState(
      projectRootPath: '/tmp/pokedex_ui_test',
      project: sampleProject,
      workspaceMode: EditorWorkspaceMode.pokedex,
    );

    await pumpPokedexWidget(
      tester,
      container,
      child: PokedexWorkspace(
        loader: store.loadEntries,
        detailLoader: store.loadDetail,
        metadataSaver: store.save,
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    await tester.tap(find.byKey(const Key('pokedex-row-bulbasaur')));
    await tester.pumpAndSettle();
    await tester
        .ensureVisible(find.byKey(const Key('pokedex-edit-metadata-button')));
    await tester.tap(find.byKey(const Key('pokedex-edit-metadata-button')));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.byKey(const Key('pokedex-enabled-switch')));
    await tester.tap(find.byKey(const Key('pokedex-enabled-switch')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('pokedex-name-field-fr')),
      'Bulbizarre Temporaire',
    );
    await tester.enterText(
      find.byKey(const Key('pokedex-flavor-text-field')),
      'Changement non enregistré.',
    );
    await tester
        .ensureVisible(find.byKey(const Key('pokedex-cancel-metadata-button')));
    await tester.tap(find.byKey(const Key('pokedex-cancel-metadata-button')));
    await tester.pumpAndSettle();

    expect(store.saveCallCount, 0);
    expect(store.speciesById('bulbasaur').classification.isEnabledInProject,
        isTrue);
    expect(store.speciesById('bulbasaur').names['fr'], 'Bulbizarre');
    expect(
      store.speciesById('bulbasaur').dexContent.flavorText,
      'Une étrange graine a été plantée sur son dos à la naissance.',
    );
    expect(find.text('Bulbizarre Temporaire'), findsNothing);
    expect(
        find.byKey(const Key('pokedex-edit-metadata-button')), findsOneWidget);
  });

  testWidgets(
      'keeps edit mode and shows a save error when all editable names are cleared without persisting anything',
      (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final store = buildStore(
      details: <PokedexSpeciesDetail>[
        buildDetail(
          id: 'bulbasaur',
          names: const <String, String>{
            'fr': 'Bulbizarre',
            'en': 'Bulbasaur',
          },
          isEnabledInProject: true,
        ),
      ],
    );
    var attemptedSaves = 0;

    Future<PokemonSpeciesFile> saveWithValidation(
      ProjectWorkspace workspace,
      UpdatePokedexSpeciesMetadataRequest request,
    ) async {
      attemptedSaves += 1;

      // Le use case applicatif couvre déjà le non-write disque réel.
      // Ici, le test UI verrouille le contrat d'interaction :
      // - l'erreur remonte lisiblement ;
      // - le formulaire reste ouvert ;
      // - la backing store locale n'est pas mutée.
      final normalizedNames = <String, String>{
        for (final entry in request.names.entries)
          if (entry.key.trim().isNotEmpty) entry.key.trim(): entry.value.trim(),
      };
      final hasUsableName = normalizedNames.values.any(
        (value) => value.isNotEmpty,
      );
      if (!hasUsableName) {
        throw const EditorValidationException(
          'Pokemon species names must contain at least one non-empty value',
        );
      }

      return store.save(workspace, request);
    }

    container.read(editorNotifierProvider.notifier).state = const EditorState(
      projectRootPath: '/tmp/pokedex_ui_test',
      project: sampleProject,
      workspaceMode: EditorWorkspaceMode.pokedex,
    );

    final persistedBefore = buildDetail(
      id: 'bulbasaur',
      names: const <String, String>{
        'fr': 'Bulbizarre',
        'en': 'Bulbasaur',
      },
      isEnabledInProject: true,
    );

    await pumpPokedexWidget(
      tester,
      container,
      child: PokedexWorkspace(
        loader: store.loadEntries,
        detailLoader: store.loadDetail,
        metadataSaver: saveWithValidation,
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    await tester.tap(find.byKey(const Key('pokedex-row-bulbasaur')));
    await tester.pumpAndSettle();
    await tester
        .ensureVisible(find.byKey(const Key('pokedex-edit-metadata-button')));
    await tester.tap(find.byKey(const Key('pokedex-edit-metadata-button')));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('pokedex-name-field-fr')),
      '   ',
    );
    await tester.enterText(
      find.byKey(const Key('pokedex-name-field-en')),
      ' \n ',
    );
    await tester.enterText(
      find.byKey(const Key('pokedex-flavor-text-field')),
      'Tentative refusée localement.',
    );
    await tester
        .ensureVisible(find.byKey(const Key('pokedex-save-metadata-button')));
    await tester.tap(find.byKey(const Key('pokedex-save-metadata-button')));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(milliseconds: 300));

    expect(attemptedSaves, 1);
    expect(find.byKey(const Key('pokedex-name-field-fr')), findsOneWidget);
    expect(find.byKey(const Key('pokedex-name-field-en')), findsOneWidget);
    expect(
        find.byKey(const Key('pokedex-save-metadata-button')), findsOneWidget);
    expect(find.byKey(const Key('pokedex-edit-metadata-button')), findsNothing);
    expect(
        find.byKey(const Key('pokedex-metadata-save-error')), findsOneWidget);
    expect(
      find.text(
          'Pokemon species names must contain at least one non-empty value'),
      findsOneWidget,
    );

    final readBack = store.speciesById('bulbasaur');
    expect(readBack.names, persistedBefore.species.names);
    expect(
      readBack.dexContent.flavorText,
      persistedBefore.species.dexContent.flavorText,
    );
    expect(
      readBack.classification.isEnabledInProject,
      persistedBefore.species.classification.isEnabledInProject,
    );
    expect(store.saveCallCount, 0);
  });

  testWidgets(
      'saving a disable under the enabled filter clears the current selection cleanly',
      (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final store = buildStore(
      details: <PokedexSpeciesDetail>[
        buildDetail(
          id: 'bulbasaur',
          nationalDex: 1,
          genIntroduced: 1,
          names: const <String, String>{
            'fr': 'Bulbizarre',
            'en': 'Bulbasaur',
          },
          isEnabledInProject: true,
        ),
        buildDetail(
          id: 'ivysaur',
          nationalDex: 2,
          genIntroduced: 1,
          names: const <String, String>{
            'fr': 'Herbizarre',
            'en': 'Ivysaur',
          },
          isEnabledInProject: true,
        ),
      ],
    );

    container.read(editorNotifierProvider.notifier).state = const EditorState(
      projectRootPath: '/tmp/pokedex_ui_test',
      project: sampleProject,
      workspaceMode: EditorWorkspaceMode.pokedex,
    );

    await pumpPokedexWidget(
      tester,
      container,
      child: PokedexWorkspace(
        loader: store.loadEntries,
        detailLoader: store.loadDetail,
        metadataSaver: store.save,
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    await selectPopupFilter(
      tester,
      popupKey: const Key('pokedex-status-filter'),
      itemLabel: 'Activées',
    );
    await tester.tap(find.byKey(const Key('pokedex-row-bulbasaur')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('pokedex-detail-pane')), findsOneWidget);

    await tester
        .ensureVisible(find.byKey(const Key('pokedex-edit-metadata-button')));
    await tester.tap(find.byKey(const Key('pokedex-edit-metadata-button')));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('pokedex-enabled-switch')));
    await tester.tap(find.byKey(const Key('pokedex-enabled-switch')));
    await tester.pumpAndSettle();
    await tester
        .ensureVisible(find.byKey(const Key('pokedex-save-metadata-button')));
    await tester.tap(find.byKey(const Key('pokedex-save-metadata-button')));
    await tester.pumpAndSettle();

    expect(store.speciesById('bulbasaur').classification.isEnabledInProject,
        isFalse);
    expect(find.byKey(const Key('pokedex-detail-empty-state')), findsOneWidget);
    expect(find.text('Ivysaur'), findsOneWidget);
    expect(find.text('Bulbizarre'), findsNothing);
  });

  testWidgets('edits forms and classification from the dedicated tab',
      (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final store = buildStore(
      details: <PokedexSpeciesDetail>[
        buildDetail(
          id: 'bulbasaur',
          names: const <String, String>{
            'fr': 'Bulbizarre',
            'en': 'Bulbasaur',
          },
        ),
      ],
    );

    container.read(editorNotifierProvider.notifier).state = const EditorState(
      projectRootPath: '/tmp/pokedex_ui_test',
      project: sampleProject,
      workspaceMode: EditorWorkspaceMode.pokedex,
    );

    await pumpPokedexWidget(
      tester,
      container,
      child: PokedexWorkspace(
        loader: store.loadEntries,
        detailLoader: store.loadDetail,
        metadataSaver: store.save,
        formsClassificationSaver: store.saveFormsClassification,
        learnsetSaver: store.saveLearnset,
        evolutionSaver: store.saveEvolution,
        mediaSaver: store.saveMedia,
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    await tester.tap(find.byKey(const Key('pokedex-row-bulbasaur')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('pokedex-tab-forms')));
    await tester.pumpAndSettle();
    await tester
        .ensureVisible(find.byKey(const Key('pokedex-edit-forms-button')));
    await tester.tap(find.byKey(const Key('pokedex-edit-forms-button')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('pokedex-is-base-form-switch')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('pokedex-form-id-field')),
      'mega',
    );
    await tester.enterText(
      find.byKey(const Key('pokedex-form-name-field')),
      'Méga',
    );
    await tester.enterText(
      find.byKey(const Key('pokedex-other-forms-field')),
      'base\ngmax',
    );
    await tester.ensureVisible(
      find.byKey(const Key('pokedex-is-legendary-switch')),
    );
    await tester.tap(find.byKey(const Key('pokedex-is-legendary-switch')));
    await tester.pumpAndSettle();
    await tester
        .ensureVisible(find.byKey(const Key('pokedex-save-forms-button')));
    await tester.tap(find.byKey(const Key('pokedex-save-forms-button')));
    await tester.pumpAndSettle();

    expect(store.formsSaveCallCount, 1);
    expect(store.speciesById('bulbasaur').forms.formId, 'mega');
    expect(store.speciesById('bulbasaur').forms.formName, 'Méga');
    expect(store.speciesById('bulbasaur').classification.isLegendary, isTrue);
    expect(find.text('Méga (mega)'), findsOneWidget);
    expect(find.byKey(const Key('pokedex-edit-forms-button')), findsOneWidget);
  });

  testWidgets('creates a learnset locally from the dedicated tab',
      (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final store = buildStore(
      details: <PokedexSpeciesDetail>[
        buildDetail(
          id: 'bulbasaur',
          learnset: null,
        ),
      ],
    );

    container.read(editorNotifierProvider.notifier).state = const EditorState(
      projectRootPath: '/tmp/pokedex_ui_test',
      project: sampleProject,
      workspaceMode: EditorWorkspaceMode.pokedex,
    );

    await pumpPokedexWidget(
      tester,
      container,
      child: PokedexWorkspace(
        loader: store.loadEntries,
        detailLoader: store.loadDetail,
        metadataSaver: store.save,
        formsClassificationSaver: store.saveFormsClassification,
        learnsetSaver: store.saveLearnset,
        evolutionSaver: store.saveEvolution,
        mediaSaver: store.saveMedia,
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    await tester.tap(find.byKey(const Key('pokedex-row-bulbasaur')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('pokedex-tab-learnset')));
    await tester.pumpAndSettle();
    await tester.ensureVisible(
      find.byKey(const Key('pokedex-edit-learnset-button')),
    );
    await tester.tap(find.byKey(const Key('pokedex-edit-learnset-button')));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('pokedex-learnset-starting-field')),
      'tackle\ngrowl',
    );
    await tester.enterText(
      find.byKey(const Key('pokedex-learnset-level-up-field')),
      'vine_whip|7|level_up|scarlet-violet',
    );
    await tester.enterText(
      find.byKey(const Key('pokedex-learnset-tm-field')),
      'protect|scarlet-violet',
    );
    await tester.ensureVisible(
      find.byKey(const Key('pokedex-save-learnset-button')),
    );
    await tester.tap(find.byKey(const Key('pokedex-save-learnset-button')));
    await tester.pumpAndSettle();

    expect(store.learnsetSaveCallCount, 1);
    expect(store.learnsetById('bulbasaur')?.startingMoves, <String>[
      'tackle',
      'growl',
    ]);
    expect(
      store.learnsetById('bulbasaur')?.levelUp.single.moveId,
      'vine_whip',
    );
    expect(find.text('tackle, growl'), findsOneWidget);
  });

  testWidgets('creates an evolution locally from the dedicated tab',
      (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final store = buildStore(
      details: <PokedexSpeciesDetail>[
        buildDetail(
          id: 'bulbasaur',
          evolution: null,
        ),
      ],
    );

    container.read(editorNotifierProvider.notifier).state = const EditorState(
      projectRootPath: '/tmp/pokedex_ui_test',
      project: sampleProject,
      workspaceMode: EditorWorkspaceMode.pokedex,
    );

    await pumpPokedexWidget(
      tester,
      container,
      child: PokedexWorkspace(
        loader: store.loadEntries,
        detailLoader: store.loadDetail,
        metadataSaver: store.save,
        formsClassificationSaver: store.saveFormsClassification,
        learnsetSaver: store.saveLearnset,
        evolutionSaver: store.saveEvolution,
        mediaSaver: store.saveMedia,
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    await tester.tap(find.byKey(const Key('pokedex-row-bulbasaur')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('pokedex-tab-evolutions')));
    await tester.pumpAndSettle();
    await tester.ensureVisible(
      find.byKey(const Key('pokedex-edit-evolution-button')),
    );
    await tester.tap(find.byKey(const Key('pokedex-edit-evolution-button')));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('pokedex-evolution-entries-field')),
      'ivysaur|level_up|16|||Évolue au niveau 16|Evolves at level 16',
    );
    await tester.ensureVisible(
      find.byKey(const Key('pokedex-save-evolution-button')),
    );
    await tester.tap(find.byKey(const Key('pokedex-save-evolution-button')));
    await tester.pumpAndSettle();

    expect(store.evolutionSaveCallCount, 1);
    expect(
      store.evolutionById('bulbasaur')?.evolutions.single.targetSpeciesId,
      'ivysaur',
    );
    expect(find.textContaining('Évolue au niveau 16'), findsOneWidget);
  });

  testWidgets('creates media references locally from the dedicated tab',
      (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final store = buildStore(
      details: <PokedexSpeciesDetail>[
        buildDetail(
          id: 'bulbasaur',
          media: null,
        ),
      ],
    );

    container.read(editorNotifierProvider.notifier).state = const EditorState(
      projectRootPath: '/tmp/pokedex_ui_test',
      project: sampleProject,
      workspaceMode: EditorWorkspaceMode.pokedex,
    );

    await pumpPokedexWidget(
      tester,
      container,
      child: PokedexWorkspace(
        loader: store.loadEntries,
        detailLoader: store.loadDetail,
        metadataSaver: store.save,
        formsClassificationSaver: store.saveFormsClassification,
        learnsetSaver: store.saveLearnset,
        evolutionSaver: store.saveEvolution,
        mediaSaver: store.saveMedia,
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    await tester.tap(find.byKey(const Key('pokedex-row-bulbasaur')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('pokedex-tab-media')));
    await tester.pumpAndSettle();
    await tester
        .ensureVisible(find.byKey(const Key('pokedex-edit-media-button')));
    await tester.tap(find.byKey(const Key('pokedex-edit-media-button')));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('pokedex-media-default-form-field')),
      'base',
    );
    await tester.enterText(
      find.byKey(const Key('pokedex-media-variants-field')),
      'base|assets/pokemon/sprites/bulbasaur/front.png|assets/pokemon/sprites/bulbasaur/back.png|||assets/pokemon/sprites/bulbasaur/icon.png|assets/pokemon/sprites/bulbasaur/party.png||assets/pokemon/portraits/bulbasaur.png|assets/pokemon/cries/bulbasaur.ogg',
    );
    await tester.enterText(
      find.byKey(const Key('pokedex-media-animations-field')),
      'base|battleFront|assets/pokemon/sprites/bulbasaur/battle_front_sheet.png|battle_front',
    );
    await tester.scrollUntilVisible(
      find.byKey(const Key('pokedex-save-media-button')),
      160,
      scrollable: find.byType(Scrollable).last,
    );
    await tester
        .ensureVisible(find.byKey(const Key('pokedex-save-media-button')));
    final saveMediaButton = tester.widget<CupertinoButton>(
      find.byKey(const Key('pokedex-save-media-button')),
    );
    saveMediaButton.onPressed!.call();
    await tester.pumpAndSettle();

    expect(store.mediaSaveCallCount, 1);
    expect(store.mediaById('bulbasaur')?.defaultFormId, 'base');
    expect(
      store.mediaById('bulbasaur')?.variants['base']?.portrait,
      'assets/pokemon/portraits/bulbasaur.png',
    );
    expect(find.text('assets/pokemon/portraits/bulbasaur.png'), findsOneWidget);
  });

  testWidgets('shows a loading state before the species list resolves',
      (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final completer = Completer<List<PokemonDatabaseIndexEntry>>();

    container.read(editorNotifierProvider.notifier).state = const EditorState(
      projectRootPath: '/tmp/pokedex_loading_test',
      workspaceMode: EditorWorkspaceMode.pokedex,
    );

    await pumpPokedexWidget(
      tester,
      container,
      child: PokedexWorkspace(
        loader: (_) => completer.future,
      ),
    );
    await tester.pump();

    expect(find.byKey(const Key('pokedex-loading-label')), findsOneWidget);

    // On prouve l'existence de l'état loading, puis on résout explicitement le
    // future avant teardown pour éviter de laisser un timer autoDispose Riverpod
    // en attente à la fin du test.
    completer.complete(const <PokemonDatabaseIndexEntry>[]);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });

  testWidgets('shows an empty state when no species files are present',
      (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    container.read(editorNotifierProvider.notifier).state = const EditorState(
      projectRootPath: '/tmp/pokedex_ui_test',
      project: sampleProject,
      workspaceMode: EditorWorkspaceMode.pokedex,
    );

    await pumpPokedexWidget(
      tester,
      container,
      child: PokedexWorkspace(
        loader: (_) async => const <PokemonDatabaseIndexEntry>[],
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byKey(const Key('pokedex-empty-state')), findsOneWidget);
    expect(find.textContaining('Pokédex est encore vide'), findsOneWidget);
  });

  testWidgets('shows an error state when species loading fails',
      (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    container.read(editorNotifierProvider.notifier).state = const EditorState(
      projectRootPath: '/tmp/pokedex_ui_test',
      project: sampleProject,
      workspaceMode: EditorWorkspaceMode.pokedex,
    );

    await pumpPokedexWidget(
      tester,
      container,
      child: PokedexWorkspace(
        loader: (_) => Future<List<PokemonDatabaseIndexEntry>>.error(
          const EditorPersistenceException(
            'Invalid JSON in Pokemon species file',
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byKey(const Key('pokedex-error-state')), findsOneWidget);
    expect(find.textContaining('Impossible de charger'), findsOneWidget);
    expect(find.textContaining('Invalid JSON'), findsOneWidget);
  });

  test(
    'returns an empty list when the configured species directory does not exist yet',
    () async {
      final tempProjectRoot =
          await Directory.systemTemp.createTemp('pokedex_loader_test_');
      try {
        final workspace = ProjectFileSystem(tempProjectRoot.path);
        final createProjectUseCase = CreateProjectUseCase(
          FileProjectRepository(),
          const FileProjectWorkspaceFactory(),
        );

        await createProjectUseCase.execute(
          'Pokedex Loader Project',
          tempProjectRoot.path,
        );

        final loader = createPokedexEntryLoader(
          projectRepository: FileProjectRepository(),
          databaseIndex: PokemonDatabaseIndex(
            projectRepository: FileProjectRepository(),
            pokemonReadRepository: const FilePokemonReadRepository(),
          ),
        );

        // Ce test verrouille le vrai nettoyage du mini-fix :
        // l'absence du dossier `species/` doit produire une liste vide
        // explicitement, sans dépendre du texte d'une exception remontée.
        final entries = await loader(workspace);
        expect(entries, isEmpty);
      } finally {
        if (await tempProjectRoot.exists()) {
          await tempProjectRoot.delete(recursive: true);
        }
      }
    },
  );
}

class _FakePokedexWorkspaceStore {
  _FakePokedexWorkspaceStore({
    required Map<String, PokedexSpeciesDetail> detailsById,
    required this.entryBuilder,
    required this.metadataUpdater,
    required this.formsClassificationUpdater,
    required this.learnsetUpdater,
    required this.evolutionUpdater,
    required this.mediaUpdater,
  }) : _detailsById = Map<String, PokedexSpeciesDetail>.from(detailsById);

  final Map<String, PokedexSpeciesDetail> _detailsById;
  final PokemonDatabaseIndexEntry Function(PokemonSpeciesFile species)
      entryBuilder;
  final PokemonSpeciesFile Function(
    PokemonSpeciesFile species,
    UpdatePokedexSpeciesMetadataRequest request,
  ) metadataUpdater;
  final PokemonSpeciesFile Function(
    PokemonSpeciesFile species,
    UpdatePokedexSpeciesFormsClassificationRequest request,
  ) formsClassificationUpdater;
  final PokemonLearnsetFile Function(
    PokedexSpeciesDetail detail,
    UpdatePokedexSpeciesLearnsetRequest request,
  ) learnsetUpdater;
  final PokemonEvolutionFile Function(
    PokedexSpeciesDetail detail,
    UpdatePokedexSpeciesEvolutionRequest request,
  ) evolutionUpdater;
  final PokemonMediaFile Function(
    PokedexSpeciesDetail detail,
    UpdatePokedexSpeciesMediaRequest request,
  ) mediaUpdater;

  int saveCallCount = 0;
  int formsSaveCallCount = 0;
  int learnsetSaveCallCount = 0;
  int evolutionSaveCallCount = 0;
  int mediaSaveCallCount = 0;

  Future<List<PokemonDatabaseIndexEntry>> loadEntries(
    ProjectWorkspace workspace,
  ) async {
    final entries = _detailsById.values
        .map((detail) => entryBuilder(detail.species))
        .toList(growable: false)
      ..sort((left, right) {
        final dexCompare = left.nationalDex.compareTo(right.nationalDex);
        if (dexCompare != 0) {
          return dexCompare;
        }
        return left.id.compareTo(right.id);
      });
    return entries;
  }

  Future<PokedexSpeciesDetail> loadDetail(
    ProjectWorkspace workspace,
    String speciesId,
  ) async {
    return _detailsById[speciesId]!;
  }

  Future<PokemonSpeciesFile> save(
    ProjectWorkspace workspace,
    UpdatePokedexSpeciesMetadataRequest request,
  ) async {
    saveCallCount += 1;
    final current = _detailsById[request.speciesId]!;
    final updatedSpecies = metadataUpdater(current.species, request);
    _detailsById[request.speciesId] = PokedexSpeciesDetail(
      species: updatedSpecies,
      learnset: current.learnset,
      evolution: current.evolution,
      media: current.media,
    );
    return updatedSpecies;
  }

  PokemonSpeciesFile speciesById(String speciesId) {
    return _detailsById[speciesId]!.species;
  }

  Future<PokemonSpeciesFile> saveFormsClassification(
    ProjectWorkspace workspace,
    UpdatePokedexSpeciesFormsClassificationRequest request,
  ) async {
    formsSaveCallCount += 1;
    final current = _detailsById[request.speciesId]!;
    final updatedSpecies = formsClassificationUpdater(current.species, request);
    _detailsById[request.speciesId] = PokedexSpeciesDetail(
      species: updatedSpecies,
      learnset: current.learnset,
      evolution: current.evolution,
      media: current.media,
    );
    return updatedSpecies;
  }

  Future<PokemonLearnsetFile> saveLearnset(
    ProjectWorkspace workspace,
    UpdatePokedexSpeciesLearnsetRequest request,
  ) async {
    learnsetSaveCallCount += 1;
    final current = _detailsById[request.speciesId]!;
    final updatedLearnset = learnsetUpdater(current, request);
    _detailsById[request.speciesId] = PokedexSpeciesDetail(
      species: current.species,
      learnset: updatedLearnset,
      evolution: current.evolution,
      media: current.media,
    );
    return updatedLearnset;
  }

  Future<PokemonEvolutionFile> saveEvolution(
    ProjectWorkspace workspace,
    UpdatePokedexSpeciesEvolutionRequest request,
  ) async {
    evolutionSaveCallCount += 1;
    final current = _detailsById[request.speciesId]!;
    final updatedEvolution = evolutionUpdater(current, request);
    _detailsById[request.speciesId] = PokedexSpeciesDetail(
      species: current.species,
      learnset: current.learnset,
      evolution: updatedEvolution,
      media: current.media,
    );
    return updatedEvolution;
  }

  Future<PokemonMediaFile> saveMedia(
    ProjectWorkspace workspace,
    UpdatePokedexSpeciesMediaRequest request,
  ) async {
    mediaSaveCallCount += 1;
    final current = _detailsById[request.speciesId]!;
    final updatedMedia = mediaUpdater(current, request);
    _detailsById[request.speciesId] = PokedexSpeciesDetail(
      species: current.species,
      learnset: current.learnset,
      evolution: current.evolution,
      media: updatedMedia,
    );
    return updatedMedia;
  }

  PokemonLearnsetFile? learnsetById(String speciesId) {
    return _detailsById[speciesId]!.learnset;
  }

  PokemonEvolutionFile? evolutionById(String speciesId) {
    return _detailsById[speciesId]!.evolution;
  }

  PokemonMediaFile? mediaById(String speciesId) {
    return _detailsById[speciesId]!.media;
  }
}
```

### `packages/map_editor/lib/src/ui/canvas/pokedex_workspace/pokedex_workspace_page.dart`
```dart
import 'dart:async';
import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:macos_ui/macos_ui.dart'
    show
        ControlSize,
        MacosIcon,
        MacosPopupButton,
        MacosPopupMenuItem,
        ProgressCircle,
        PushButton;
import 'package:path/path.dart' as p;

import '../../../app/providers/pokedex_providers.dart';
import '../../../application/errors/application_errors.dart';
import '../../../application/models/pokedex_species_detail.dart';
import '../../../application/models/pokemon_database_index.dart';
import '../../../application/models/pokemon_project_data_models.dart';
import '../../../application/ports/project_workspace.dart';
import '../../../application/use_cases/import_pokemon_json_bundle_use_case.dart';
import '../../../application/use_cases/update_pokedex_species_evolution_use_case.dart';
import '../../../application/use_cases/update_pokedex_species_forms_classification_use_case.dart';
import '../../../application/use_cases/update_pokedex_species_learnset_use_case.dart';
import '../../../application/use_cases/update_pokedex_species_media_use_case.dart';
import '../../../application/use_cases/update_pokedex_species_metadata_use_case.dart';
import '../../../features/editor/state/editor_notifier.dart';
import '../../../infrastructure/filesystem/project_filesystem.dart';
import '../pokedex_workspace_loader.dart';
import '../../shared/cupertino_editor_widgets.dart';

part 'pokedex_workspace_body.dart';
part 'pokedex_workspace_logic.dart';
part 'pokedex_empty_state.dart';
part 'pokedex_feedback_banner.dart';
part 'pokedex_list_panel.dart';
part 'pokedex_toolbar.dart';
part 'pokedex_filters_panel.dart';
part 'pokedex_list_row.dart';
part 'pokedex_import_flow.dart';
part 'pokedex_import_flow_steps.dart';
part 'pokedex_import_flow_support.dart';
part 'pokedex_detail_panel.dart';
part 'pokedex_overview_panel.dart';
part 'pokedex_metadata_editor.dart';
part 'pokedex_metadata_editor_fields.dart';
part 'pokedex_forms_panel.dart';
part 'pokedex_learnset_panel.dart';
part 'pokedex_learnset_sections.dart';
part 'pokedex_evolution_panel.dart';
part 'pokedex_media_panel.dart';
part 'pokedex_common_widgets.dart';
part 'pokedex_formatters.dart';

const String _allTypesFilterValue = '__all_types__';
const String _allGenerationsFilterValue = '__all_generations__';
const String _allStatusesFilterValue = '__all_statuses__';
const String _enabledStatusFilterValue = '__enabled_only__';
const String _overviewTabId = 'overview';

// Bibliothèque racine du workspace Pokédex.
//
// Toute la logique métier reste hors de l'UI :
// - les use cases et loaders sont injectés depuis les providers existants ;
// - cette couche orchestre uniquement l'affichage, la sélection locale et les
//   transitions utilisateur du workspace ;
// - le découpage en `part` garde les widgets privés déjà en place tout en
//   rendant l'écran maintenable et lisible pour l'équipe.
/// Workspace central Pokédex du lot 13.
///
/// Le widget public reste volontairement lisible :
/// - il lit le contexte éditeur existant ;
/// - il délègue le chargement par défaut à un helper local dédié ;
/// - il compose les quatre états UI strictement nécessaires.
///
/// On évite ainsi deux extrêmes :
/// - un gros widget fourre-tout mêlant UI et instanciation infra ;
/// - une nouvelle architecture Pokédex "future-ready" disproportionnée.
class PokedexWorkspace extends ConsumerWidget {
  const PokedexWorkspace({
    super.key,
    this.loader,
    this.detailLoader,
    this.importPreviewer,
    this.importer,
    this.pickJsonImportFile,
    this.metadataSaver,
    this.formsClassificationSaver,
    this.learnsetSaver,
    this.evolutionSaver,
    this.mediaSaver,
  });

  /// Injection locale utile aux tests ciblés du lot 13.
  ///
  /// On garde cette extension volontairement minimale : elle permet de tester
  /// le rendu des états UI sans introduire de notifier dédié supplémentaire.
  final PokedexEntryLoader? loader;
  final PokedexSpeciesDetailLoader? detailLoader;
  final PokedexImportPreviewer? importPreviewer;
  final PokedexImporter? importer;
  final Future<String?> Function()? pickJsonImportFile;
  final PokedexSpeciesMetadataSaver? metadataSaver;
  final PokedexSpeciesFormsClassificationSaver? formsClassificationSaver;
  final PokedexSpeciesLearnsetSaver? learnsetSaver;
  final PokedexSpeciesEvolutionSaver? evolutionSaver;
  final PokedexSpeciesMediaSaver? mediaSaver;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final projectRootPath =
        ref.watch(editorNotifierProvider.select((s) => s.projectRootPath));
    final PokedexEntryLoader resolvedLoader =
        loader ?? ref.watch(pokedexEntryLoaderProvider);
    final PokedexSpeciesDetailLoader resolvedDetailLoader =
        detailLoader ?? ref.watch(pokedexSpeciesDetailLoaderProvider);
    final PokedexImportPreviewer resolvedImportPreviewer =
        importPreviewer ?? ref.watch(pokedexImportPreviewerProvider);
    final PokedexImporter resolvedImporter =
        importer ?? ref.watch(pokedexImporterProvider);
    final PokedexSpeciesMetadataSaver resolvedMetadataSaver =
        metadataSaver ?? ref.watch(pokedexSpeciesMetadataSaverProvider);
    final PokedexSpeciesFormsClassificationSaver
        resolvedFormsClassificationSaver = formsClassificationSaver ??
            ref.watch(pokedexSpeciesFormsClassificationSaverProvider);
    final PokedexSpeciesLearnsetSaver resolvedLearnsetSaver =
        learnsetSaver ?? ref.watch(pokedexSpeciesLearnsetSaverProvider);
    final PokedexSpeciesEvolutionSaver resolvedEvolutionSaver =
        evolutionSaver ?? ref.watch(pokedexSpeciesEvolutionSaverProvider);
    final PokedexSpeciesMediaSaver resolvedMediaSaver =
        mediaSaver ?? ref.watch(pokedexSpeciesMediaSaverProvider);

    return _PokedexWorkspaceBody(
      projectRootPath: projectRootPath,
      loader: resolvedLoader,
      detailLoader: resolvedDetailLoader,
      importPreviewer: resolvedImportPreviewer,
      importer: resolvedImporter,
      pickJsonImportFile: pickJsonImportFile,
      metadataSaver: resolvedMetadataSaver,
      formsClassificationSaver: resolvedFormsClassificationSaver,
      learnsetSaver: resolvedLearnsetSaver,
      evolutionSaver: resolvedEvolutionSaver,
      mediaSaver: resolvedMediaSaver,
    );
  }
}

class _PokedexWorkspaceBody extends StatefulWidget {
  const _PokedexWorkspaceBody({
    required this.projectRootPath,
    required this.loader,
    required this.detailLoader,
    required this.importPreviewer,
    required this.importer,
    required this.pickJsonImportFile,
    required this.metadataSaver,
    required this.formsClassificationSaver,
    required this.learnsetSaver,
    required this.evolutionSaver,
    required this.mediaSaver,
  });

  final String? projectRootPath;
  final PokedexEntryLoader loader;
  final PokedexSpeciesDetailLoader detailLoader;
  final PokedexImportPreviewer importPreviewer;
  final PokedexImporter importer;
  final Future<String?> Function()? pickJsonImportFile;
  final PokedexSpeciesMetadataSaver metadataSaver;
  final PokedexSpeciesFormsClassificationSaver formsClassificationSaver;
  final PokedexSpeciesLearnsetSaver learnsetSaver;
  final PokedexSpeciesEvolutionSaver evolutionSaver;
  final PokedexSpeciesMediaSaver mediaSaver;

  @override
  State<_PokedexWorkspaceBody> createState() => _PokedexWorkspaceBodyState();
}
```

### `packages/map_editor/lib/src/ui/canvas/pokedex_workspace/pokedex_workspace_body.dart`
```dart
part of 'pokedex_workspace_page.dart';

// État principal du workspace.
//
// Cette partie porte seulement l'état d'écran local : recherche, filtres,
// sélection, feedback et chargement de la fiche détail. Elle ne remplace
// aucun provider métier et ne maintient aucun cache parallèle.

class _PokedexWorkspaceBodyState extends State<_PokedexWorkspaceBody> {
  late Future<List<PokemonDatabaseIndexEntry>> _entriesFuture;
  String _searchQuery = '';
  bool _filtersExpanded = false;
  String _selectedType = _allTypesFilterValue;
  String _selectedGeneration = _allGenerationsFilterValue;
  String _selectedStatus = _allStatusesFilterValue;
  String? _selectedSpeciesId;
  Future<PokedexSpeciesDetail>? _detailFuture;
  String _selectedDetailTabId = _overviewTabId;
  String? _feedbackMessage;
  bool _feedbackIsError = false;
  Timer? _feedbackTimer;

  @override
  void initState() {
    super.initState();
    _entriesFuture = _buildEntriesFuture();
  }

  @override
  void dispose() {
    _feedbackTimer?.cancel();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant _PokedexWorkspaceBody oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.projectRootPath != widget.projectRootPath ||
        oldWidget.loader != widget.loader ||
        oldWidget.detailLoader != widget.detailLoader) {
      _entriesFuture = _buildEntriesFuture();
      // Les raffinements UI des lots 14 et 15 restent purement locaux :
      // quand on change de workspace projet ou de source de chargement, on
      // réinitialise la query et les filtres pour éviter de conserver des
      // critères devenus trompeurs sur une autre liste déjà chargée.
      _searchQuery = '';
      _filtersExpanded = false;
      _selectedType = _allTypesFilterValue;
      _selectedGeneration = _allGenerationsFilterValue;
      _selectedStatus = _allStatusesFilterValue;
      _selectedSpeciesId = null;
      _detailFuture = null;
      _selectedDetailTabId = _overviewTabId;
    }
  }

  Future<List<PokemonDatabaseIndexEntry>> _buildEntriesFuture() {
    final projectRootPath = widget.projectRootPath?.trim();
    if (projectRootPath == null || projectRootPath.isEmpty) {
      return Future<List<PokemonDatabaseIndexEntry>>.value(
        const <PokemonDatabaseIndexEntry>[],
      );
    }

    final workspace = ProjectFileSystem(projectRootPath);
    return widget.loader(workspace);
  }

  @override
  Widget build(BuildContext context) {
    final projectRootPath = widget.projectRootPath?.trim();
    if (projectRootPath == null || projectRootPath.isEmpty) {
      return const PokedexWorkspaceStateCard(
        title: 'Pokédex',
        message:
            'Chargez un projet pour afficher la liste locale des espèces importées.',
      );
    }

    return FutureBuilder<List<PokemonDatabaseIndexEntry>>(
      future: _entriesFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const PokedexWorkspaceLoadingState();
        }

        if (snapshot.hasError) {
          return PokedexWorkspaceErrorState(error: snapshot.error);
        }

        final entries = snapshot.data ?? const <PokemonDatabaseIndexEntry>[];
        final availableTypes = _buildAvailableTypes(entries);
        final availableGenerations = _buildAvailableGenerations(entries);
        final workspace = ProjectFileSystem(projectRootPath);

        // Les lots 14 et 15 restent volontairement locaux à la UI :
        // - on ne recharge pas le disque à chaque frappe ou changement de filtre ;
        // - on ne crée pas de provider/notifier Pokédex dédié ;
        // - on filtre simplement la liste déjà chargée en mémoire ;
        // - on conserve l'ordre fourni par l'index local existant.
        final filteredEntries = _filterEntries(entries);
        final selectedEntry = _resolveSelectedEntry(filteredEntries);

        // Décision UX explicite du mini-fix :
        // si la sélection courante n'est plus visible dans la liste filtrée,
        // on vide la fiche détail au lieu de garder un élément "fantôme".
        // Le reset d'état est planifié hors build pour rester propre côté
        // Flutter, mais le rendu revient tout de suite à l'état vide car
        // `selectedEntry` est déjà résolu sur la liste visible.
        _clearSelectionIfInvisible(filteredEntries);

        return Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              flex: 5,
              child: PokedexWorkspaceSpeciesList(
                entries: filteredEntries,
                selectedSpeciesId: _selectedSpeciesId,
                onEntrySelected: (entry) => _selectEntry(
                  workspace: workspace,
                  entry: entry,
                ),
                onImportRequested: () => _openImportFlow(workspace),
                query: _searchQuery,
                onQueryChanged: _updateSearchQuery,
                filtersExpanded: _filtersExpanded,
                onToggleFiltersExpanded: _toggleFiltersExpanded,
                availableTypes: availableTypes,
                selectedType: _selectedType,
                onTypeChanged: _updateSelectedType,
                availableGenerations: availableGenerations,
                selectedGeneration: _selectedGeneration,
                onGenerationChanged: _updateSelectedGeneration,
                selectedStatus: _selectedStatus,
                onStatusChanged: _updateSelectedStatus,
                feedbackMessage: _feedbackMessage,
                feedbackIsError: _feedbackIsError,
                emptyStateChild: entries.isEmpty
                    ? PokedexWorkspaceImportEmptyState(
                        onImportRequested: () => _openImportFlow(workspace),
                      )
                    : null,
                emptyResultsChild: entries.isNotEmpty && filteredEntries.isEmpty
                    ? PokedexWorkspaceNoResultsState(
                        query: _searchQuery,
                        selectedType: _selectedType == _allTypesFilterValue
                            ? null
                            : _selectedType,
                        selectedGeneration:
                            _selectedGeneration == _allGenerationsFilterValue
                                ? null
                                : _selectedGeneration,
                        selectedStatus:
                            _selectedStatus == _allStatusesFilterValue
                                ? null
                                : _selectedStatus,
                      )
                    : null,
              ),
            ),
            const SizedBox(width: 18),
            SizedBox(
              width: 480,
              child: PokedexWorkspaceDetailPane(
                selectedEntry: selectedEntry,
                selectedTabId: _selectedDetailTabId,
                onTabChanged: _updateSelectedDetailTab,
                detailFuture: _detailFuture,
                onSaveMetadata: _saveMetadata,
                onSaveFormsClassification: _saveFormsClassification,
                onSaveLearnset: _saveLearnset,
                onSaveEvolution: _saveEvolution,
                onSaveMedia: _saveMedia,
              ),
            ),
          ],
        );
      },
    );
  }

  void _updateSearchQuery(String value) {
    if (value == _searchQuery) return;
    setState(() => _searchQuery = value);
  }

  void _toggleFiltersExpanded() {
    setState(() => _filtersExpanded = !_filtersExpanded);
  }

  void _updateSelectedType(String value) {
    if (value == _selectedType) return;
    setState(() => _selectedType = value);
  }

  void _updateSelectedGeneration(String value) {
    if (value == _selectedGeneration) return;
    setState(() => _selectedGeneration = value);
  }

  void _updateSelectedStatus(String value) {
    if (value == _selectedStatus) return;
    setState(() => _selectedStatus = value);
  }

  void _updateSelectedDetailTab(String value) {
    if (value == _selectedDetailTabId) return;
    setState(() => _selectedDetailTabId = value);
  }

  void _showFeedback(String message, {required bool isError}) {
    _feedbackTimer?.cancel();
    setState(() {
      _feedbackMessage = message;
      _feedbackIsError = isError;
    });
    _feedbackTimer = Timer(const Duration(seconds: 3), () {
      if (!mounted) {
        return;
      }
      setState(() => _feedbackMessage = null);
    });
  }

  Future<void> _openImportFlow(ProjectFileSystem workspace) async {
    final result = await showPokedexImportFlowSheet(
      context: context,
      workspace: workspace,
      previewImport: widget.importPreviewer,
      importPokemon: widget.importer,
      pickJsonSourceFile: widget.pickJsonImportFile,
    );
    if (!mounted || result == null) {
      return;
    }

    final importedSpeciesId = result.preview.speciesId.trim();
    setState(() {
      _entriesFuture = _buildEntriesFuture();
      _searchQuery = '';
      _filtersExpanded = false;
      _selectedType = _allTypesFilterValue;
      _selectedGeneration = _allGenerationsFilterValue;
      _selectedStatus = _allStatusesFilterValue;
      _selectedSpeciesId = importedSpeciesId;
      _selectedDetailTabId = _overviewTabId;
      _detailFuture = widget.detailLoader(workspace, importedSpeciesId);
    });

    final importedArtifacts = <String>[
      'espèce',
      if (result.importedLearnset) 'learnset',
      if (result.importedEvolution) 'évolutions',
      if (result.importedMedia) 'médias',
    ];
    _showFeedback(
      'Import terminé pour ${result.preview.primaryName} · ${importedArtifacts.join(', ')}',
      isError: false,
    );
  }

  void _selectEntry({
    required ProjectFileSystem workspace,
    required PokemonDatabaseIndexEntry entry,
  }) {
    if (_selectedSpeciesId == entry.id && _detailFuture != null) {
      return;
    }
    setState(() {
      _selectedSpeciesId = entry.id;
      _selectedDetailTabId = _overviewTabId;
      _detailFuture = widget.detailLoader(workspace, entry.id);
    });
  }

  void _clearSelectionIfInvisible(
    List<PokemonDatabaseIndexEntry> visibleEntries,
  ) {
    final selectedId = _selectedSpeciesId;
    if (selectedId == null || selectedId.isEmpty) {
      return;
    }

    final stillVisible = visibleEntries.any((entry) => entry.id == selectedId);
    if (stillVisible) {
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (_selectedSpeciesId != selectedId) return;
      setState(() {
        _selectedSpeciesId = null;
        _detailFuture = null;
        _selectedDetailTabId = _overviewTabId;
      });
    });
  }

  Future<void> _saveMetadata(
    UpdatePokedexSpeciesMetadataRequest request,
  ) async {
    await _runLocalPokemonSave(
      speciesId: request.speciesId,
      saveOperation: (workspace) => widget.metadataSaver(workspace, request),
    );
  }

  Future<void> _saveFormsClassification(
    UpdatePokedexSpeciesFormsClassificationRequest request,
  ) async {
    await _runLocalPokemonSave(
      speciesId: request.speciesId,
      saveOperation: (workspace) =>
          widget.formsClassificationSaver(workspace, request),
    );
  }

  Future<void> _saveLearnset(
    UpdatePokedexSpeciesLearnsetRequest request,
  ) async {
    await _runLocalPokemonSave(
      speciesId: request.speciesId,
      saveOperation: (workspace) => widget.learnsetSaver(workspace, request),
    );
  }

  Future<void> _saveEvolution(
    UpdatePokedexSpeciesEvolutionRequest request,
  ) async {
    await _runLocalPokemonSave(
      speciesId: request.speciesId,
      saveOperation: (workspace) => widget.evolutionSaver(workspace, request),
    );
  }

  Future<void> _saveMedia(
    UpdatePokedexSpeciesMediaRequest request,
  ) async {
    await _runLocalPokemonSave(
      speciesId: request.speciesId,
      saveOperation: (workspace) => widget.mediaSaver(workspace, request),
    );
  }

  Future<void> _runLocalPokemonSave({
    required String speciesId,
    required Future<void> Function(ProjectFileSystem workspace) saveOperation,
  }) async {
    final projectRootPath = widget.projectRootPath?.trim();
    if (projectRootPath == null || projectRootPath.isEmpty) {
      throw StateError(
        'Cannot save local Pokemon data without a loaded project',
      );
    }

    final workspace = ProjectFileSystem(projectRootPath);
    await saveOperation(workspace);
    if (!mounted) {
      return;
    }

    // Après une sauvegarde locale, on relit la même source de vérité que le
    // reste du workspace :
    // - l'index léger pour la liste et les filtres ;
    // - la fiche détail complète pour l'espèce sélectionnée.
    //
    // On évite ainsi tout cache parallèle "enabled" ou "draft saved" qui
    // pourrait diverger du JSON réellement persisté.
    setState(() {
      _entriesFuture = _buildEntriesFuture();
      if (_selectedSpeciesId == speciesId.trim()) {
        _detailFuture = widget.detailLoader(workspace, speciesId);
      }
    });
  }
}
```

### `packages/map_editor/lib/src/ui/canvas/pokedex_workspace/pokedex_workspace_logic.dart`
```dart
part of 'pokedex_workspace_page.dart';

// Helpers locaux du workspace.
//
// On garde ici les opérations purement UI : filtrage mémoire, résolution de la
// sélection visible et normalisation de la recherche dex. La source de vérité
// métier reste l'index et la fiche relus depuis le disque via les loaders.

extension _PokedexWorkspaceBodyStateLogic on _PokedexWorkspaceBodyState {
  List<PokemonDatabaseIndexEntry> _filterEntries(
    List<PokemonDatabaseIndexEntry> entries,
  ) {
    final normalizedQuery = _searchQuery.trim();
    final normalizedTextQuery = normalizedQuery.toLowerCase();
    final normalizedDexQuery = _normalizeDexQuery(normalizedQuery);
    final hasExactDexQuery = RegExp(r'^\d+$').hasMatch(normalizedDexQuery);

    // Le lot 15 demande des filtres simples, pas un moteur de règles :
    // chaque critère local vaut soit "tout", soit une valeur unique exacte.
    final typeFilter = _selectedType.toLowerCase();
    final hasTypeFilter = _selectedType != _allTypesFilterValue;
    final hasGenerationFilter =
        _selectedGeneration != _allGenerationsFilterValue;
    final hasStatusFilter = _selectedStatus != _allStatusesFilterValue;

    return entries.where((entry) {
      final matchesSearch = _matchesSearchQuery(
        entry: entry,
        normalizedQuery: normalizedQuery,
        normalizedTextQuery: normalizedTextQuery,
        normalizedDexQuery: normalizedDexQuery,
        hasExactDexQuery: hasExactDexQuery,
      );

      final matchesType = !hasTypeFilter ||
          entry.types.any((type) => type.toLowerCase() == typeFilter);
      final matchesGeneration = !hasGenerationFilter ||
          entry.genIntroduced.toString() == _selectedGeneration;
      final matchesStatus = !hasStatusFilter ||
          (_selectedStatus == _enabledStatusFilterValue
              ? entry.isEnabledInProject
              : !entry.isEnabledInProject);

      return matchesSearch && matchesType && matchesGeneration && matchesStatus;
    }).toList(growable: false);
  }

  bool _matchesSearchQuery({
    required PokemonDatabaseIndexEntry entry,
    required String normalizedQuery,
    required String normalizedTextQuery,
    required String normalizedDexQuery,
    required bool hasExactDexQuery,
  }) {
    if (normalizedQuery.isEmpty) {
      return true;
    }

    final matchesName =
        entry.primaryName.toLowerCase().contains(normalizedTextQuery);
    final matchesId = entry.id.toLowerCase().contains(normalizedTextQuery);

    // Règle produit explicite du lot 14 :
    // - si la query ressemble à un numéro dex, on ne fait pas un `contains`
    //   numérique ;
    // - on compare exactement `1`, `0001`, `#1`, `#0001` au dex courant ;
    // - cela évite qu'une recherche "1" remonte 10, 11, 21, etc.
    final matchesDex = hasExactDexQuery &&
        _matchesExactDexQuery(
          entry: entry,
          normalizedDexQuery: normalizedDexQuery,
        );

    return matchesName || matchesId || matchesDex;
  }

  List<String> _buildAvailableTypes(List<PokemonDatabaseIndexEntry> entries) {
    final uniqueTypes = entries
        .expand((entry) => entry.types)
        .map((type) => type.trim())
        .where((type) => type.isNotEmpty)
        .toSet()
        .toList(growable: false)
      ..sort(
          (left, right) => left.toLowerCase().compareTo(right.toLowerCase()));

    return uniqueTypes;
  }

  List<String> _buildAvailableGenerations(
    List<PokemonDatabaseIndexEntry> entries,
  ) {
    final uniqueGenerations = entries
        .map((entry) => entry.genIntroduced)
        .toSet()
        .toList(growable: false)
      ..sort();

    return uniqueGenerations
        .map((generation) => generation.toString())
        .toList(growable: false);
  }

  PokemonDatabaseIndexEntry? _resolveSelectedEntry(
    List<PokemonDatabaseIndexEntry> entries,
  ) {
    final selectedId = _selectedSpeciesId;
    if (selectedId == null || selectedId.isEmpty) {
      return null;
    }
    for (final entry in entries) {
      if (entry.id == selectedId) {
        return entry;
      }
    }
    return null;
  }

  String _normalizeDexQuery(String query) {
    final trimmed = query.trim();
    if (!trimmed.startsWith('#')) {
      return trimmed;
    }
    return trimmed.substring(1).trim();
  }

  bool _matchesExactDexQuery({
    required PokemonDatabaseIndexEntry entry,
    required String normalizedDexQuery,
  }) {
    final rawDex = entry.nationalDex.toString();
    final paddedDex = entry.nationalDex.toString().padLeft(4, '0');
    return normalizedDexQuery == rawDex || normalizedDexQuery == paddedDex;
  }
}
```

### `packages/map_editor/lib/src/ui/canvas/pokedex_workspace/pokedex_empty_state.dart`
```dart
part of 'pokedex_workspace_page.dart';

// États vides et cadres de présentation du workspace.
//
// Ces vues servent à garder une UX lisible dans tous les cas simples : projet
// absent, chargement, erreur, aucune espèce importée ou aucun résultat après
// filtres. Elles restent volontairement honnêtes et non techniques.

class PokedexWorkspaceLoadingState extends StatelessWidget {
  const PokedexWorkspaceLoadingState({super.key});

  @override
  Widget build(BuildContext context) {
    final subtle = EditorChrome.subtleLabel(context);

    return DefaultTextStyle(
      style: TextStyle(
        color: subtle,
        fontSize: 13,
        fontWeight: FontWeight.w600,
      ),
      child: const PokedexWorkspaceStateFrame(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 28,
              height: 28,
              child: ProgressCircle(),
            ),
            SizedBox(height: 14),
            Text(
              'Chargement de la liste Pokédex…',
              key: Key('pokedex-loading-label'),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

/// Carte d'erreur minimale du lot 13.
///
/// L'objectif n'est pas d'ajouter une UX de récupération riche ; on rend
/// simplement l'erreur lisible, sans masquer qu'un chargement a échoué.
class PokedexWorkspaceErrorState extends StatelessWidget {
  const PokedexWorkspaceErrorState({
    super.key,
    required this.error,
  });

  final Object? error;

  @override
  Widget build(BuildContext context) {
    final label = EditorChrome.primaryLabel(context);
    final subtle = EditorChrome.subtleLabel(context);
    final message = switch (error) {
      final EditorApplicationException applicationError =>
        applicationError.message,
      _ => error?.toString() ?? 'Erreur inconnue',
    };

    return PokedexWorkspaceStateCard(
      key: const Key('pokedex-error-state'),
      title: 'Pokédex',
      accent: EditorChrome.inspectorJoyCoral,
      titleStyle: TextStyle(
        color: label,
        fontSize: 24,
        fontWeight: FontWeight.w700,
      ),
      message: 'Impossible de charger la liste locale des espèces.\n$message',
      messageStyle: TextStyle(
        color: subtle,
        fontSize: 13,
        fontWeight: FontWeight.w600,
        height: 1.45,
      ),
    );
  }
}

/// Etat dédié des lots 14/15 quand les critères locaux ne matchent aucune entrée.
///
/// Il doit rester distinct de l'état "aucune espèce importée" :
/// - ici, la base locale contient des espèces ;
/// - ce sont uniquement les critères courants (recherche et/ou filtres) qui
///   n'ont trouvé aucun match.
/// On garde donc un message sobre, non anxiogène, et différent d'une erreur.
class PokedexWorkspaceNoResultsState extends StatelessWidget {
  const PokedexWorkspaceNoResultsState({
    super.key,
    required this.query,
    this.selectedType,
    this.selectedGeneration,
    this.selectedStatus,
  });

  final String query;
  final String? selectedType;
  final String? selectedGeneration;
  final String? selectedStatus;

  @override
  Widget build(BuildContext context) {
    final normalizedQuery = query.trim();
    final normalizedStatus = switch (selectedStatus) {
      _PokedexFilterDropdown.enabledOnlyValue => 'Activées',
      _PokedexFilterDropdown.disabledOnlyValue => 'Désactivées',
      _ => selectedStatus,
    };
    final activeCriteriaLines = <String>[
      if (normalizedQuery.isNotEmpty)
        'Recherche actuelle : "$normalizedQuery".',
      if (selectedType != null) 'Type : $selectedType.',
      if (selectedGeneration != null) 'Génération : $selectedGeneration.',
      if (normalizedStatus != null) 'Statut : $normalizedStatus.',
    ];
    final suffix = activeCriteriaLines.isEmpty
        ? ''
        : '\n${activeCriteriaLines.join('\n')}';

    return PokedexWorkspaceStateCard(
      key: const Key('pokedex-no-results-state'),
      title: 'Pokédex',
      message: 'Aucun résultat avec les critères actuels.$suffix',
    );
  }
}

/// Vue succès du lot 13.
///
/// Elle reste volontairement en lecture seule, mais la phase 5 ajoute une
/// vraie sélection locale de ligne pour ouvrir la fiche détail.

class PokedexWorkspaceImportEmptyState extends StatelessWidget {
  const PokedexWorkspaceImportEmptyState({
    super.key,
    required this.onImportRequested,
  });

  final VoidCallback onImportRequested;

  @override
  Widget build(BuildContext context) {
    final label = EditorChrome.primaryLabel(context);
    final subtle = EditorChrome.subtleLabel(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: EditorChrome.islandFillElevated(context),
            borderRadius: BorderRadius.circular(26),
            border: Border.all(
              color: EditorChrome.accentWarm.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 28),
            child: Column(
              key: const Key('pokedex-empty-state'),
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 76,
                  height: 76,
                  decoration: BoxDecoration(
                    color: EditorChrome.accentPrune.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  alignment: Alignment.center,
                  child: const Icon(
                    CupertinoIcons.folder,
                    size: 34,
                    color: EditorChrome.accentLilac,
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  'Importer des Pokémon',
                  style: TextStyle(
                    color: label,
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Votre Pokédex est encore vide. Importez un premier Pokémon pour commencer à construire la liste du projet.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: subtle,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 18),
                CupertinoButton(
                  key: const Key('pokedex-empty-state-import-button'),
                  color: EditorChrome.accentJade.withValues(alpha: 0.24),
                  borderRadius: BorderRadius.circular(16),
                  onPressed: onImportRequested,
                  child: const Text('Importer des Pokémon'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class PokedexWorkspaceStateCard extends StatelessWidget {
  const PokedexWorkspaceStateCard({
    super.key,
    required this.title,
    required this.message,
    this.accent = EditorChrome.inspectorJoyAmber,
    this.titleStyle,
    this.messageStyle,
  });

  final String title;
  final String message;
  final Color accent;
  final TextStyle? titleStyle;
  final TextStyle? messageStyle;

  @override
  Widget build(BuildContext context) {
    final label = EditorChrome.primaryLabel(context);
    final subtle = EditorChrome.subtleLabel(context);

    return PokedexWorkspaceStateFrame(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color.lerp(CupertinoColors.white, accent, 0.72)!,
                  Color.lerp(accent, const Color(0xFF1A1408), 0.35)!,
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: accent.withValues(alpha: 0.82),
                width: 1.2,
              ),
            ),
            alignment: Alignment.center,
            child: const MacosIcon(
              CupertinoIcons.book_fill,
              color: CupertinoColors.white,
              size: 24,
            ),
          ),
          const SizedBox(height: 18),
          Text(
            title,
            style: titleStyle ??
                TextStyle(
                  color: label,
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.4,
                ),
          ),
          const SizedBox(height: 10),
          Text(
            message,
            style: messageStyle ??
                TextStyle(
                  color: subtle,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  height: 1.45,
                ),
          ),
        ],
      ),
    );
  }
}

class PokedexWorkspaceStateFrame extends StatelessWidget {
  const PokedexWorkspaceStateFrame({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final surface = EditorChrome.islandFillElevated(context);

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 760),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: surface,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: EditorChrome.inspectorJoyAmber.withValues(alpha: 0.38),
              width: 1.1,
            ),
            boxShadow: EditorChrome.sectionCardShadows(context),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(28, 28, 28, 28),
            child: child,
          ),
        ),
      ),
    );
  }
}
```

### `packages/map_editor/lib/src/ui/canvas/pokedex_workspace/pokedex_feedback_banner.dart`
```dart
part of 'pokedex_workspace_page.dart';

// Bannière de feedback locale du workspace.
//
// Elle sert à donner un retour humain et immédiat après import ou sauvegarde,
// sans introduire de système global de notifications.

class PokedexWorkspaceFeedbackBanner extends StatelessWidget {
  const PokedexWorkspaceFeedbackBanner({
    super.key,
    required this.message,
    required this.isError,
  });

  final String message;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    final accent =
        isError ? EditorChrome.inspectorJoyCoral : EditorChrome.accentJade;
    final label = EditorChrome.primaryLabel(context);

    return Container(
      key: const Key('pokedex-feedback-banner'),
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accent.withValues(alpha: 0.45), width: 1),
      ),
      child: Row(
        children: [
          Icon(
            isError
                ? CupertinoIcons.exclamationmark_triangle_fill
                : CupertinoIcons.check_mark_circled_solid,
            size: 18,
            color: accent,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: label,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
```

### `packages/map_editor/lib/src/ui/canvas/pokedex_workspace/pokedex_list_panel.dart`
```dart
part of 'pokedex_workspace_page.dart';

// Colonne gauche du workspace Pokédex.
//
// Elle regroupe le header produit, la barre d'actions légère, les états vides
// et la liste des espèces. Toute la donnée vient des loaders et de l'état local
// du workspace ; aucun parsing ni accès fichier ne part d'ici.

class PokedexWorkspaceSpeciesList extends StatelessWidget {
  const PokedexWorkspaceSpeciesList({
    super.key,
    required this.entries,
    required this.selectedSpeciesId,
    required this.onEntrySelected,
    required this.onImportRequested,
    required this.query,
    required this.onQueryChanged,
    required this.filtersExpanded,
    required this.onToggleFiltersExpanded,
    required this.availableTypes,
    required this.selectedType,
    required this.onTypeChanged,
    required this.availableGenerations,
    required this.selectedGeneration,
    required this.onGenerationChanged,
    required this.selectedStatus,
    required this.onStatusChanged,
    this.feedbackMessage,
    this.feedbackIsError = false,
    this.emptyStateChild,
    this.emptyResultsChild,
  });

  final List<PokemonDatabaseIndexEntry> entries;
  final String? selectedSpeciesId;
  final ValueChanged<PokemonDatabaseIndexEntry> onEntrySelected;
  final VoidCallback onImportRequested;
  final String query;
  final ValueChanged<String> onQueryChanged;
  final bool filtersExpanded;
  final VoidCallback onToggleFiltersExpanded;
  final List<String> availableTypes;
  final String selectedType;
  final ValueChanged<String> onTypeChanged;
  final List<String> availableGenerations;
  final String selectedGeneration;
  final ValueChanged<String> onGenerationChanged;
  final String selectedStatus;
  final ValueChanged<String> onStatusChanged;
  final String? feedbackMessage;
  final bool feedbackIsError;
  final Widget? emptyStateChild;
  final Widget? emptyResultsChild;

  @override
  Widget build(BuildContext context) {
    final label = EditorChrome.primaryLabel(context);
    final subtle = EditorChrome.subtleLabel(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(6, 2, 6, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: EditorChrome.accentJade.withValues(alpha: 0.24),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: EditorChrome.accentJade.withValues(alpha: 0.55),
                        width: 1,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: const Icon(
                      CupertinoIcons.square_stack_3d_down_right_fill,
                      size: 18,
                      color: EditorChrome.accentJade,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Pokédex',
                          style: TextStyle(
                            color: label,
                            fontSize: 26,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.4,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Importez, filtrez et ouvrez les espèces locales du projet sans quitter l’éditeur.',
                          style: TextStyle(
                            color: subtle,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            height: 1.45,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  CupertinoButton(
                    key: const Key('pokedex-import-button'),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    color: EditorChrome.accentJade.withValues(alpha: 0.24),
                    borderRadius: BorderRadius.circular(14),
                    onPressed: onImportRequested,
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          CupertinoIcons.add,
                          size: 16,
                          color: CupertinoColors.white,
                        ),
                        SizedBox(width: 8),
                        Text('Importer des Pokémon'),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (feedbackMessage != null) ...[
                const SizedBox(height: 12),
                PokedexWorkspaceFeedbackBanner(
                  message: feedbackMessage!,
                  isError: feedbackIsError,
                ),
              ],
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: _PokedexSearchField(
                      query: query,
                      onChanged: onQueryChanged,
                    ),
                  ),
                  const SizedBox(width: 12),
                  CupertinoButton(
                    key: const Key('pokedex-toggle-filters-button'),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    color: EditorChrome.islandFillElevated(context),
                    borderRadius: BorderRadius.circular(14),
                    onPressed: onToggleFiltersExpanded,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          CupertinoIcons.slider_horizontal_3,
                          size: 16,
                          color: CupertinoColors.white,
                        ),
                        const SizedBox(width: 8),
                        Text(filtersExpanded ? 'Masquer' : 'Filtres'),
                      ],
                    ),
                  ),
                ],
              ),
              if (filtersExpanded) ...[
                const SizedBox(height: 12),
                _PokedexSimpleFiltersBar(
                  availableTypes: availableTypes,
                  selectedType: selectedType,
                  onTypeChanged: onTypeChanged,
                  availableGenerations: availableGenerations,
                  selectedGeneration: selectedGeneration,
                  onGenerationChanged: onGenerationChanged,
                  selectedStatus: selectedStatus,
                  onStatusChanged: onStatusChanged,
                ),
              ] else if (_hasAnyFilterApplied()) ...[
                const SizedBox(height: 10),
                Text(
                  _activeFiltersSummary(),
                  style: TextStyle(
                    color: subtle,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ],
          ),
        ),
        if (entries.isNotEmpty) ...[
          const _PokedexListHeader(),
          const SizedBox(height: 8),
        ],
        Expanded(
          child: emptyStateChild != null
              ? SingleChildScrollView(child: emptyStateChild)
              : emptyResultsChild != null
                  ? SingleChildScrollView(child: emptyResultsChild)
                  : ListView.separated(
                      key: const Key('pokedex-species-list'),
                      itemCount: entries.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final entry = entries[index];
                        return _PokedexListRow(
                          entry: entry,
                          isSelected: selectedSpeciesId == entry.id,
                          onPressed: () => onEntrySelected(entry),
                        );
                      },
                    ),
        ),
      ],
    );
  }

  bool _hasAnyFilterApplied() {
    return selectedType != _PokedexFilterDropdown.allTypesValue ||
        selectedGeneration != _PokedexFilterDropdown.allGenerationsValue ||
        selectedStatus != _PokedexFilterDropdown.allStatusesValue;
  }

  String _activeFiltersSummary() {
    final parts = <String>[];
    if (selectedType != _PokedexFilterDropdown.allTypesValue) {
      parts.add('Type : $selectedType');
    }
    if (selectedGeneration != _PokedexFilterDropdown.allGenerationsValue) {
      parts.add('Génération : $selectedGeneration');
    }
    if (selectedStatus == _PokedexFilterDropdown.enabledOnlyValue) {
      parts.add('Activées');
    } else if (selectedStatus == _PokedexFilterDropdown.disabledOnlyValue) {
      parts.add('Désactivées');
    }
    return parts.join(' · ');
  }
}

class _PokedexListHeader extends StatelessWidget {
  const _PokedexListHeader();

  @override
  Widget build(BuildContext context) {
    final subtle = EditorChrome.subtleLabel(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Row(
        children: [
          SizedBox(
            width: 88,
            child: Text(
              'Numéro',
              style: _headerStyle(subtle),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 3,
            child: Text(
              'Nom',
              style: _headerStyle(subtle),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: Text(
              'ID',
              style: _headerStyle(subtle),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 3,
            child: Text(
              'Types',
              style: _headerStyle(subtle),
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 92,
            child: Align(
              alignment: Alignment.centerRight,
              child: Text(
                'Statut',
                style: _headerStyle(subtle),
              ),
            ),
          ),
        ],
      ),
    );
  }

  TextStyle _headerStyle(Color color) {
    return TextStyle(
      color: color,
      fontSize: 11,
      fontWeight: FontWeight.w700,
      letterSpacing: 0.25,
    );
  }
}
```

### `packages/map_editor/lib/src/ui/canvas/pokedex_workspace/pokedex_toolbar.dart`
```dart
part of 'pokedex_workspace_page.dart';

// Barre d'outils locale du Pokédex.
//
// On sépare la recherche textuelle et le résumé des filtres pour que le haut du
// workspace reste lisible même quand la liste est vide ou très courte.

class _PokedexSimpleFiltersBar extends StatelessWidget {
  const _PokedexSimpleFiltersBar({
    required this.availableTypes,
    required this.selectedType,
    required this.onTypeChanged,
    required this.availableGenerations,
    required this.selectedGeneration,
    required this.onGenerationChanged,
    required this.selectedStatus,
    required this.onStatusChanged,
  });

  final List<String> availableTypes;
  final String selectedType;
  final ValueChanged<String> onTypeChanged;
  final List<String> availableGenerations;
  final String selectedGeneration;
  final ValueChanged<String> onGenerationChanged;
  final String selectedStatus;
  final ValueChanged<String> onStatusChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      key: const Key('pokedex-filters-panel'),
      spacing: 12,
      runSpacing: 12,
      children: [
        _PokedexFilterDropdown(
          label: 'Type',
          popupKey: const Key('pokedex-type-filter'),
          value: selectedType,
          onChanged: onTypeChanged,
          items: <String>[
            _PokedexFilterDropdown.allTypesValue,
            ...availableTypes,
          ],
          itemLabelBuilder: (value) {
            if (value == _PokedexFilterDropdown.allTypesValue) {
              return 'Tous types';
            }
            return value;
          },
        ),
        _PokedexFilterDropdown(
          label: 'Génération',
          popupKey: const Key('pokedex-generation-filter'),
          value: selectedGeneration,
          onChanged: onGenerationChanged,
          items: <String>[
            _PokedexFilterDropdown.allGenerationsValue,
            ...availableGenerations,
          ],
          itemLabelBuilder: (value) {
            if (value == _PokedexFilterDropdown.allGenerationsValue) {
              return 'Toutes gén.';
            }
            return 'Génération $value';
          },
        ),
        _PokedexFilterDropdown(
          label: 'Statut',
          popupKey: const Key('pokedex-status-filter'),
          value: selectedStatus,
          onChanged: onStatusChanged,
          items: const <String>[
            _PokedexFilterDropdown.allStatusesValue,
            _PokedexFilterDropdown.enabledOnlyValue,
            _PokedexFilterDropdown.disabledOnlyValue,
          ],
          itemLabelBuilder: (value) {
            switch (value) {
              case _PokedexFilterDropdown.allStatusesValue:
                return 'Toutes';
              case _PokedexFilterDropdown.enabledOnlyValue:
                return 'Activées';
              case _PokedexFilterDropdown.disabledOnlyValue:
                return 'Désactivées';
            }
            return value;
          },
        ),
      ],
    );
  }
}

class _PokedexSearchField extends StatefulWidget {
  const _PokedexSearchField({
    required this.query,
    required this.onChanged,
  });

  final String query;
  final ValueChanged<String> onChanged;

  @override
  State<_PokedexSearchField> createState() => _PokedexSearchFieldState();
}

class _PokedexSearchFieldState extends State<_PokedexSearchField> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.query);
  }

  @override
  void didUpdateWidget(covariant _PokedexSearchField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.query != _controller.text) {
      _controller.value = TextEditingValue(
        text: widget.query,
        selection: TextSelection.collapsed(offset: widget.query.length),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final subtle = EditorChrome.subtleLabel(context);
    final surface = EditorChrome.islandFillElevated(context);
    final border = EditorChrome.accentWarm.withValues(alpha: 0.28);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            Icon(
              CupertinoIcons.search,
              color: subtle,
              size: 16,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: CupertinoTextField.borderless(
                key: const Key('pokedex-search-field'),
                controller: _controller,
                onChanged: widget.onChanged,
                clearButtonMode: OverlayVisibilityMode.editing,
                placeholder: 'Rechercher un Pokémon, un ID ou un numéro',
                padding: EdgeInsets.zero,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

### `packages/map_editor/lib/src/ui/canvas/pokedex_workspace/pokedex_filters_panel.dart`
```dart
part of 'pokedex_workspace_page.dart';

// Dropdowns de filtres simples.
//
// Le but est de rester sur des critères compréhensibles par un utilisateur
// no-code : type, génération et statut. Aucun calcul métier ne vit ici.

class _PokedexFilterDropdown extends StatelessWidget {
  const _PokedexFilterDropdown({
    required this.label,
    required this.popupKey,
    required this.value,
    required this.onChanged,
    required this.items,
    required this.itemLabelBuilder,
  });

  static const String allTypesValue = '__all_types__';
  static const String allGenerationsValue = '__all_generations__';
  static const String allStatusesValue = '__all_statuses__';
  static const String enabledOnlyValue = '__enabled_only__';
  static const String disabledOnlyValue = '__disabled_only__';

  final String label;
  final Key popupKey;
  final String value;
  final ValueChanged<String> onChanged;
  final List<String> items;
  final String Function(String value) itemLabelBuilder;

  @override
  Widget build(BuildContext context) {
    final subtle = EditorChrome.subtleLabel(context);
    final surface = EditorChrome.islandFillElevated(context);
    final border = EditorChrome.accentWarm.withValues(alpha: 0.28);

    return SizedBox(
      // `MacosPopupButton` réserve de la place pour le libellé et l'icône
      // interne. On donne donc une largeur volontairement confortable pour
      // éviter les overflows de layout, notamment avec les libellés français
      // "Toutes les générations" / "Tous les types".
      width: 240,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: subtle,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.2,
            ),
          ),
          const SizedBox(height: 6),
          DecoratedBox(
            decoration: BoxDecoration(
              color: surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: border, width: 1),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
              child: SizedBox(
                width: double.infinity,
                child: MacosPopupButton<String>(
                  key: popupKey,
                  value: value,
                  onChanged: (nextValue) {
                    if (nextValue != null) {
                      onChanged(nextValue);
                    }
                  },
                  items: [
                    for (final item in items)
                      MacosPopupMenuItem<String>(
                        value: item,
                        child: Text(itemLabelBuilder(item)),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
```

### `packages/map_editor/lib/src/ui/canvas/pokedex_workspace/pokedex_list_row.dart`
```dart
part of 'pokedex_workspace_page.dart';

// Lignes de liste et badges visuels.
//
// Chaque ligne résume une espèce importée avec un statut clair et des types
// visibles. La sélection reste purement locale au workspace.

class _PokedexListRow extends StatelessWidget {
  const _PokedexListRow({
    required this.entry,
    required this.isSelected,
    required this.onPressed,
  });

  final PokemonDatabaseIndexEntry entry;
  final bool isSelected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final surface = isSelected
        ? Color.lerp(
            EditorChrome.islandFillElevated(context),
            EditorChrome.accentJade,
            0.12,
          )!
        : EditorChrome.islandFillElevated(context);
    final border = isSelected
        ? EditorChrome.accentJade.withValues(alpha: 0.65)
        : EditorChrome.accentWarm.withValues(alpha: 0.35);
    final label = EditorChrome.primaryLabel(context);
    final subtle = EditorChrome.subtleLabel(context);

    return CupertinoButton(
      key: Key('pokedex-row-${entry.id}'),
      padding: EdgeInsets.zero,
      onPressed: onPressed,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: border, width: isSelected ? 1.4 : 1),
          boxShadow: EditorChrome.sectionCardShadows(context),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 88,
                child: Text(
                  '#${entry.nationalDex.toString().padLeft(4, '0')}',
                  style: TextStyle(
                    color: label,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 3,
                child: Text(
                  entry.primaryName,
                  style: TextStyle(
                    color: label,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: Text(
                  entry.id,
                  style: TextStyle(
                    color: subtle,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 3,
                child: Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: entry.types
                      .map((type) => _PokedexTypeChip(label: type))
                      .toList(growable: false),
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: 92,
                child: Align(
                  alignment: Alignment.topRight,
                  child: _PokedexStatusChip(
                    label: entry.isEnabledInProject ? 'Activé' : 'Désactivé',
                    isEnabled: entry.isEnabledInProject,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PokedexTypeChip extends StatelessWidget {
  const _PokedexTypeChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final text = EditorChrome.primaryLabel(context);
    final fill = Color.lerp(
      EditorChrome.chipFill(context),
      EditorChrome.accentJade,
      0.18,
    )!;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: EditorChrome.accentJade.withValues(alpha: 0.45),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Text(
          label,
          style: TextStyle(
            color: text,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _PokedexStatusChip extends StatelessWidget {
  const _PokedexStatusChip({
    required this.label,
    required this.isEnabled,
  });

  final String label;
  final bool isEnabled;

  @override
  Widget build(BuildContext context) {
    final accent =
        isEnabled ? EditorChrome.accentJade : EditorChrome.inspectorJoyCoral;
    final text = EditorChrome.primaryLabel(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: accent.withValues(alpha: 0.45), width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Text(
          label,
          style: TextStyle(
            color: text,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
```

### `packages/map_editor/lib/src/ui/canvas/pokedex_workspace/pokedex_import_flow.dart`
```dart
part of 'pokedex_workspace_page.dart';

// Orchestration du flow d'import JSON.
//
// La feuille modale guide l'utilisateur dans un enchaînement lisible : source,
// fichier, aperçu puis confirmation. Les use cases existants restent la seule
// porte d'entrée métier de l'import.

Future<PokemonJsonImportResult?> showPokedexImportFlowSheet({
  required BuildContext context,
  required ProjectWorkspace workspace,
  required PokedexImportPreviewer previewImport,
  required PokedexImporter importPokemon,
  Future<String?> Function()? pickJsonSourceFile,
}) {
  // Le picker natif reste confiné à la présentation :
  // - la UI choisit un chemin local ;
  // - l’application lit, valide et importe ;
  // - aucun widget ne parse de JSON ni ne décide du write.
  return showMacosEditorTallSheet<PokemonJsonImportResult>(
    context: context,
    maxWidth: 760,
    builder: (sheetContext) => _PokedexImportFlowSheet(
      workspace: workspace,
      previewImport: previewImport,
      importPokemon: importPokemon,
      pickJsonSourceFile: pickJsonSourceFile ?? _pickPokedexJsonSourceFile,
    ),
  );
}

Future<String?> _pickPokedexJsonSourceFile() async {
  final result = await FilePicker.platform.pickFiles(
    type: FileType.custom,
    allowedExtensions: const ['json'],
    withData: false,
  );
  return result?.files.single.path;
}

enum _PokedexImportWizardStep {
  source,
  jsonFile,
  preview,
}

// Le wizard reste volontairement petit et séquentiel.
// On ne crée pas de route dédiée ni de nouveau state container global :
// - l’étape "source" choisit la famille d’import ;
// - l’étape "jsonFile" choisit le fichier local ;
// - l’étape "preview" montre la synthèse applicative avant le write.
class _PokedexImportFlowSheet extends StatefulWidget {
  const _PokedexImportFlowSheet({
    required this.workspace,
    required this.previewImport,
    required this.importPokemon,
    required this.pickJsonSourceFile,
  });

  final ProjectWorkspace workspace;
  final PokedexImportPreviewer previewImport;
  final PokedexImporter importPokemon;
  final Future<String?> Function() pickJsonSourceFile;

  @override
  State<_PokedexImportFlowSheet> createState() =>
      _PokedexImportFlowSheetState();
}

class _PokedexImportFlowSheetState extends State<_PokedexImportFlowSheet> {
  _PokedexImportWizardStep _step = _PokedexImportWizardStep.source;
  String? _selectedJsonSourcePath;
  PokemonJsonImportPreview? _preview;
  bool _isBusy = false;
  String? _errorMessage;

  Future<void> _pickJsonSource() async {
    final pickedPath = await widget.pickJsonSourceFile();
    if (!mounted || pickedPath == null) {
      return;
    }
    setState(() {
      _selectedJsonSourcePath = pickedPath;
      _errorMessage = null;
    });
  }

  Future<void> _loadPreview() async {
    final sourcePath = _selectedJsonSourcePath?.trim();
    if (sourcePath == null || sourcePath.isEmpty) {
      setState(() {
        _errorMessage = 'Sélectionnez un fichier JSON à importer.';
      });
      return;
    }

    setState(() {
      _isBusy = true;
      _errorMessage = null;
    });

    try {
      final preview = await widget.previewImport(
        widget.workspace,
        sourcePath,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _preview = preview;
        _step = _PokedexImportWizardStep.preview;
        _isBusy = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isBusy = false;
        _errorMessage = _resolveApplicationMessage(error);
      });
    }
  }

  Future<void> _confirmImport() async {
    final sourcePath = _selectedJsonSourcePath?.trim();
    if (sourcePath == null || sourcePath.isEmpty) {
      return;
    }

    setState(() {
      _isBusy = true;
      _errorMessage = null;
    });

    try {
      final result = await widget.importPokemon(
        widget.workspace,
        sourcePath,
      );
      if (!mounted) {
        return;
      }
      Navigator.of(context).pop(result);
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isBusy = false;
        _errorMessage = _resolveApplicationMessage(error);
      });
    }
  }

  String _resolveApplicationMessage(Object error) {
    return switch (error) {
      final EditorApplicationException applicationError =>
        applicationError.message,
      _ => error.toString(),
    };
  }

  @override
  Widget build(BuildContext context) {
    return switch (_step) {
      _PokedexImportWizardStep.source => _PokedexImportSourceStep(
          onContinue: () {
            setState(() {
              _step = _PokedexImportWizardStep.jsonFile;
              _errorMessage = null;
            });
          },
          onCancel: () => Navigator.of(context).pop(),
        ),
      _PokedexImportWizardStep.jsonFile => _PokedexImportJsonFileStep(
          selectedJsonSourcePath: _selectedJsonSourcePath,
          isBusy: _isBusy,
          errorMessage: _errorMessage,
          onPickJsonSource: _pickJsonSource,
          onContinue: _loadPreview,
          onCancel: () => Navigator.of(context).pop(),
        ),
      _PokedexImportWizardStep.preview => _PokedexImportPreviewStep(
          preview: _preview!,
          isBusy: _isBusy,
          errorMessage: _errorMessage,
          onBack: () {
            setState(() {
              _step = _PokedexImportWizardStep.jsonFile;
              _errorMessage = null;
            });
          },
          onImport: _confirmImport,
        ),
    };
  }
}
```

### `packages/map_editor/lib/src/ui/canvas/pokedex_workspace/pokedex_import_flow_steps.dart`
```dart
part of 'pokedex_workspace_page.dart';

// Étapes principales du wizard d'import.
//
// On garde ici le wording et la mise en forme du parcours utilisateur, sans y
// déplacer de logique de validation ou de parsing.

class _PokedexImportSourceStep extends StatelessWidget {
  const _PokedexImportSourceStep({
    required this.onContinue,
    required this.onCancel,
  });

  final VoidCallback onContinue;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final helperStyle = editorMacosFormLabelStyle(
      context,
    ).copyWith(
      fontSize: 12,
      fontWeight: FontWeight.w600,
      color: EditorChrome.subtleLabel(context),
      height: 1.4,
    );

    return Column(
      key: const Key('pokedex-import-source-step'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Importer des Pokémon',
          style: editorMacosSheetTitleStyle(context),
        ),
        const SizedBox(height: 8),
        Text(
          'Choisissez d’abord la source que vous voulez utiliser. Les autres sources sont déjà visibles pour préparer la suite, mais seul le JSON local est disponible pour le moment.',
          style: helperStyle,
        ),
        const SizedBox(height: 20),
        Text(
          'Choisir une source',
          style: editorMacosFormLabelStyle(context),
        ),
        const SizedBox(height: 12),
        const _PokedexImportSourceCard(
          cardKey: Key('pokedex-import-json-source-card'),
          title: 'Fichier JSON',
          icon: CupertinoIcons.doc_text_fill,
          isSelected: true,
        ),
        const SizedBox(height: 10),
        const _PokedexImportSourceCard(
          cardKey: Key('pokedex-import-pokeapi-source-card'),
          title: 'PokéAPI',
          icon: CupertinoIcons.cloud_fill,
          isEnabled: false,
          trailingLabel: 'Bientôt',
        ),
        const SizedBox(height: 10),
        const _PokedexImportSourceCard(
          cardKey: Key('pokedex-import-showdown-source-card'),
          title: 'Showdown',
          icon: CupertinoIcons.refresh_circled_solid,
          isEnabled: false,
          trailingLabel: 'Bientôt',
        ),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            PushButton(
              controlSize: ControlSize.large,
              secondary: true,
              onPressed: onCancel,
              child: const Text('Annuler'),
            ),
            const SizedBox(width: 12),
            PushButton(
              key: const Key('pokedex-import-source-continue-button'),
              controlSize: ControlSize.large,
              onPressed: onContinue,
              child: const Text('Continuer'),
            ),
          ],
        ),
      ],
    );
  }
}

class _PokedexImportJsonFileStep extends StatelessWidget {
  const _PokedexImportJsonFileStep({
    required this.selectedJsonSourcePath,
    required this.isBusy,
    required this.errorMessage,
    required this.onPickJsonSource,
    required this.onContinue,
    required this.onCancel,
  });

  final String? selectedJsonSourcePath;
  final bool isBusy;
  final String? errorMessage;
  final Future<void> Function() onPickJsonSource;
  final Future<void> Function() onContinue;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final subtle = EditorChrome.subtleLabel(context);
    final hasFile = selectedJsonSourcePath?.trim().isNotEmpty == true;
    final helperStyle = editorMacosFormLabelStyle(
      context,
    ).copyWith(
      fontSize: 12,
      fontWeight: FontWeight.w600,
      color: subtle,
      height: 1.4,
    );

    return Column(
      key: const Key('pokedex-import-json-step'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Import depuis fichier JSON',
          style: editorMacosSheetTitleStyle(context),
        ),
        const SizedBox(height: 8),
        Text(
          'Sélectionnez le fichier espèce à importer. L’aperçu vous montrera ensuite ce qui sera ajouté au projet.',
          style: helperStyle,
        ),
        const SizedBox(height: 20),
        Text(
          'Choisir un fichier',
          style: editorMacosFormLabelStyle(context),
        ),
        const SizedBox(height: 12),
        CupertinoButton(
          key: const Key('pokedex-import-pick-json-file-button'),
          color: EditorChrome.accentJade.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(16),
          onPressed: isBusy ? null : onPickJsonSource,
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(CupertinoIcons.folder_open, size: 18),
              SizedBox(width: 8),
              Text('Choisir un fichier'),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Container(
          key: const Key('pokedex-import-selected-file'),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            color: EditorChrome.islandFillElevated(context),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: EditorChrome.accentWarm.withValues(alpha: 0.25),
              width: 1,
            ),
          ),
          child: Text(
            hasFile
                ? p.basename(selectedJsonSourcePath!)
                : 'Aucun fichier sélectionné',
            style: TextStyle(
              color: hasFile ? CupertinoColors.white : subtle,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        if (errorMessage != null) ...[
          const SizedBox(height: 12),
          Text(
            errorMessage!,
            key: const Key('pokedex-import-error-message'),
            style: const TextStyle(
              color: EditorChrome.inspectorJoyCoral,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            PushButton(
              controlSize: ControlSize.large,
              secondary: true,
              onPressed: isBusy ? null : onCancel,
              child: const Text('Annuler'),
            ),
            const SizedBox(width: 12),
            PushButton(
              key: const Key('pokedex-import-json-continue-button'),
              controlSize: ControlSize.large,
              onPressed: isBusy ? null : onContinue,
              child: isBusy
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: ProgressCircle(),
                    )
                  : const Text('Continuer'),
            ),
          ],
        ),
      ],
    );
  }
}

class _PokedexImportPreviewStep extends StatelessWidget {
  const _PokedexImportPreviewStep({
    required this.preview,
    required this.isBusy,
    required this.errorMessage,
    required this.onBack,
    required this.onImport,
  });

  final PokemonJsonImportPreview preview;
  final bool isBusy;
  final String? errorMessage;
  final VoidCallback onBack;
  final Future<void> Function() onImport;

  @override
  Widget build(BuildContext context) {
    final helperStyle = editorMacosFormLabelStyle(
      context,
    ).copyWith(
      fontSize: 12,
      fontWeight: FontWeight.w600,
      color: EditorChrome.subtleLabel(context),
      height: 1.4,
    );

    return Column(
      key: const Key('pokedex-import-preview-step'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Aperçu de l\'import',
          style: editorMacosSheetTitleStyle(context),
        ),
        const SizedBox(height: 8),
        Text(
          'Vérifiez rapidement l’espèce et les fichiers trouvés avant de lancer l’import.',
          style: helperStyle,
        ),
        const SizedBox(height: 20),
        DecoratedBox(
          decoration: BoxDecoration(
            color: EditorChrome.islandFillElevated(context),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: EditorChrome.accentWarm.withValues(alpha: 0.25),
              width: 1,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '#${preview.nationalDex.toString().padLeft(3, '0')} ${preview.primaryName}',
                  key: const Key('pokedex-import-preview-title'),
                  style: const TextStyle(
                    color: CupertinoColors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Type : ${preview.types.join(' / ')}',
                  key: const Key('pokedex-import-preview-types'),
                  style: TextStyle(
                    color: EditorChrome.subtleLabel(context),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 18),
                _PokedexImportArtifactLine(
                  key: const Key('pokedex-import-preview-learnset-status'),
                  preview: preview.learnset,
                ),
                const SizedBox(height: 10),
                _PokedexImportArtifactLine(
                  key: const Key('pokedex-import-preview-evolution-status'),
                  preview: preview.evolution,
                ),
                const SizedBox(height: 10),
                _PokedexImportArtifactLine(
                  key: const Key('pokedex-import-preview-media-status'),
                  preview: preview.media,
                ),
              ],
            ),
          ),
        ),
        if (errorMessage != null) ...[
          const SizedBox(height: 12),
          Text(
            errorMessage!,
            key: const Key('pokedex-import-error-message'),
            style: const TextStyle(
              color: EditorChrome.inspectorJoyCoral,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            PushButton(
              key: const Key('pokedex-import-preview-back-button'),
              controlSize: ControlSize.large,
              secondary: true,
              onPressed: isBusy ? null : onBack,
              child: const Text('Retour'),
            ),
            const SizedBox(width: 12),
            PushButton(
              key: const Key('pokedex-import-confirm-button'),
              controlSize: ControlSize.large,
              onPressed: isBusy ? null : onImport,
              child: isBusy
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: ProgressCircle(),
                    )
                  : const Text('Importer'),
            ),
          ],
        ),
      ],
    );
  }
}
```

### `packages/map_editor/lib/src/ui/canvas/pokedex_workspace/pokedex_import_flow_support.dart`
```dart
part of 'pokedex_workspace_page.dart';

// Petits widgets réutilisés par le flow d'import.
//
// Ils rendent l'aperçu plus lisible sans introduire une seconde logique de
// preview. Toute la donnée affichée vient déjà du previeweur applicatif.

class _PokedexImportSourceCard extends StatelessWidget {
  const _PokedexImportSourceCard({
    required this.cardKey,
    required this.title,
    required this.icon,
    this.isSelected = false,
    this.isEnabled = true,
    this.trailingLabel,
  });

  final Key cardKey;
  final String title;
  final IconData icon;
  final bool isSelected;
  final bool isEnabled;
  final String? trailingLabel;

  @override
  Widget build(BuildContext context) {
    final accent = isSelected
        ? EditorChrome.accentJade
        : EditorChrome.accentWarm.withValues(alpha: 0.45);
    final text = isEnabled
        ? EditorChrome.primaryLabel(context)
        : EditorChrome.subtleLabel(context);

    return DecoratedBox(
      key: cardKey,
      decoration: BoxDecoration(
        color: EditorChrome.islandFillElevated(context),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: accent, width: isSelected ? 1.2 : 1),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Row(
          children: [
            Icon(icon, size: 18, color: text),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  color: text,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            if (trailingLabel != null)
              Text(
                trailingLabel!,
                style: TextStyle(
                  color: EditorChrome.subtleLabel(context),
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _PokedexImportArtifactLine extends StatelessWidget {
  const _PokedexImportArtifactLine({
    super.key,
    required this.preview,
  });

  final PokemonImportArtifactPreview preview;

  @override
  Widget build(BuildContext context) {
    final isFound = preview.isFound;
    final accent = isFound ? EditorChrome.accentJade : EditorChrome.accentWarm;
    final text = EditorChrome.primaryLabel(context);

    return Row(
      children: [
        Icon(
          isFound
              ? CupertinoIcons.check_mark_circled_solid
              : CupertinoIcons.exclamationmark_triangle_fill,
          size: 18,
          color: accent,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            '${preview.label} ${isFound ? 'trouvé${preview.label == 'Évolutions' ? 'es' : ''}' : 'manquants'}',
            style: TextStyle(
              color: text,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
```

### `packages/map_editor/lib/src/ui/canvas/pokedex_workspace/pokedex_detail_panel.dart`
```dart
part of 'pokedex_workspace_page.dart';

// Colonne droite du workspace Pokédex.
//
// Cette zone reste en lecture ou édition locale selon l'onglet actif. Elle ne
// décide jamais du contenu métier ; elle reflète uniquement la sélection et les
// loaders déjà résolus par le workspace principal.

class PokedexWorkspaceDetailPane extends StatelessWidget {
  const PokedexWorkspaceDetailPane({
    super.key,
    required this.selectedEntry,
    required this.selectedTabId,
    required this.onTabChanged,
    required this.detailFuture,
    required this.onSaveMetadata,
    required this.onSaveFormsClassification,
    required this.onSaveLearnset,
    required this.onSaveEvolution,
    required this.onSaveMedia,
  });

  final PokemonDatabaseIndexEntry? selectedEntry;
  final String selectedTabId;
  final ValueChanged<String> onTabChanged;
  final Future<PokedexSpeciesDetail>? detailFuture;
  final Future<void> Function(UpdatePokedexSpeciesMetadataRequest request)
      onSaveMetadata;
  final Future<void> Function(
    UpdatePokedexSpeciesFormsClassificationRequest request,
  ) onSaveFormsClassification;
  final Future<void> Function(UpdatePokedexSpeciesLearnsetRequest request)
      onSaveLearnset;
  final Future<void> Function(UpdatePokedexSpeciesEvolutionRequest request)
      onSaveEvolution;
  final Future<void> Function(UpdatePokedexSpeciesMediaRequest request)
      onSaveMedia;

  @override
  Widget build(BuildContext context) {
    final entry = selectedEntry;
    if (entry == null || detailFuture == null) {
      return const PokedexWorkspaceStateCard(
        key: Key('pokedex-detail-empty-state'),
        title: 'Fiche espèce',
        message:
            'Sélectionnez une espèce dans la liste pour voir sa fiche, ses formes, son learnset, ses évolutions et ses médias.',
      );
    }

    return FutureBuilder<PokedexSpeciesDetail>(
      future: detailFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const PokedexWorkspaceStateCard(
            key: Key('pokedex-detail-loading-state'),
            title: 'Fiche espèce',
            message: 'Chargement de la fiche Pokédex…',
          );
        }

        if (snapshot.hasError) {
          final message = switch (snapshot.error) {
            final EditorApplicationException applicationError =>
              applicationError.message,
            _ => snapshot.error?.toString() ?? 'Erreur inconnue',
          };
          return PokedexWorkspaceStateCard(
            key: const Key('pokedex-detail-error-state'),
            title: 'Fiche espèce',
            accent: EditorChrome.inspectorJoyCoral,
            message: 'Impossible de charger la fiche de ${entry.id}.\n$message',
          );
        }

        final detail = snapshot.data;
        if (detail == null) {
          return const PokedexWorkspaceStateCard(
            title: 'Fiche espèce',
            message: 'Aucune donnée Pokédex détaillée disponible.',
          );
        }

        return _PokedexSpeciesDetailView(
          entry: entry,
          detail: detail,
          selectedTabId: selectedTabId,
          onTabChanged: onTabChanged,
          onSaveMetadata: onSaveMetadata,
          onSaveFormsClassification: onSaveFormsClassification,
          onSaveLearnset: onSaveLearnset,
          onSaveEvolution: onSaveEvolution,
          onSaveMedia: onSaveMedia,
        );
      },
    );
  }
}

class _PokedexSpeciesDetailView extends StatelessWidget {
  const _PokedexSpeciesDetailView({
    required this.entry,
    required this.detail,
    required this.selectedTabId,
    required this.onTabChanged,
    required this.onSaveMetadata,
    required this.onSaveFormsClassification,
    required this.onSaveLearnset,
    required this.onSaveEvolution,
    required this.onSaveMedia,
  });

  final PokemonDatabaseIndexEntry entry;
  final PokedexSpeciesDetail detail;
  final String selectedTabId;
  final ValueChanged<String> onTabChanged;
  final Future<void> Function(UpdatePokedexSpeciesMetadataRequest request)
      onSaveMetadata;
  final Future<void> Function(
    UpdatePokedexSpeciesFormsClassificationRequest request,
  ) onSaveFormsClassification;
  final Future<void> Function(UpdatePokedexSpeciesLearnsetRequest request)
      onSaveLearnset;
  final Future<void> Function(UpdatePokedexSpeciesEvolutionRequest request)
      onSaveEvolution;
  final Future<void> Function(UpdatePokedexSpeciesMediaRequest request)
      onSaveMedia;

  @override
  Widget build(BuildContext context) {
    final surface = EditorChrome.islandFillElevated(context);
    final border = EditorChrome.accentWarm.withValues(alpha: 0.35);
    final label = EditorChrome.primaryLabel(context);
    final subtle = EditorChrome.subtleLabel(context);

    return DecoratedBox(
      key: const Key('pokedex-detail-pane'),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: border, width: 1),
        boxShadow: EditorChrome.sectionCardShadows(context),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              entry.primaryName,
              style: TextStyle(
                color: label,
                fontSize: 24,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.35,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '#${entry.nationalDex.toString().padLeft(4, '0')} • ${entry.id}',
              style: TextStyle(
                color: subtle,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                _PokedexStatusChip(
                  label: entry.isEnabledInProject ? 'Activée' : 'Désactivée',
                  isEnabled: entry.isEnabledInProject,
                ),
                ...entry.types.map((type) => _PokedexTypeChip(label: type)),
              ],
            ),
            const SizedBox(height: 16),
            CupertinoSlidingSegmentedControl<String>(
              key: const Key('pokedex-detail-tabs'),
              groupValue: selectedTabId,
              onValueChanged: (value) {
                if (value != null) {
                  onTabChanged(value);
                }
              },
              children: const <String, Widget>{
                'overview': Padding(
                  key: Key('pokedex-tab-overview'),
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  child: Text('Fiche'),
                ),
                'forms': Padding(
                  key: Key('pokedex-tab-forms'),
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  child: Text('Formes'),
                ),
                'learnset': Padding(
                  key: Key('pokedex-tab-learnset'),
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  child: Text('Learnset'),
                ),
                'evolutions': Padding(
                  key: Key('pokedex-tab-evolutions'),
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  child: Text('Évolutions'),
                ),
                'media': Padding(
                  key: Key('pokedex-tab-media'),
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  child: Text('Médias'),
                ),
              },
            ),
            const SizedBox(height: 18),
            Expanded(
              child: _PokedexDetailTabBody(
                entry: entry,
                detail: detail,
                selectedTabId: selectedTabId,
                onSaveMetadata: onSaveMetadata,
                onSaveFormsClassification: onSaveFormsClassification,
                onSaveLearnset: onSaveLearnset,
                onSaveEvolution: onSaveEvolution,
                onSaveMedia: onSaveMedia,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PokedexDetailTabBody extends StatelessWidget {
  const _PokedexDetailTabBody({
    required this.entry,
    required this.detail,
    required this.selectedTabId,
    required this.onSaveMetadata,
    required this.onSaveFormsClassification,
    required this.onSaveLearnset,
    required this.onSaveEvolution,
    required this.onSaveMedia,
  });

  final PokemonDatabaseIndexEntry entry;
  final PokedexSpeciesDetail detail;
  final String selectedTabId;
  final Future<void> Function(UpdatePokedexSpeciesMetadataRequest request)
      onSaveMetadata;
  final Future<void> Function(
    UpdatePokedexSpeciesFormsClassificationRequest request,
  ) onSaveFormsClassification;
  final Future<void> Function(UpdatePokedexSpeciesLearnsetRequest request)
      onSaveLearnset;
  final Future<void> Function(UpdatePokedexSpeciesEvolutionRequest request)
      onSaveEvolution;
  final Future<void> Function(UpdatePokedexSpeciesMediaRequest request)
      onSaveMedia;

  @override
  Widget build(BuildContext context) {
    return switch (selectedTabId) {
      'forms' => _PokedexFormsTab(
          detail: detail,
          onSave: onSaveFormsClassification,
        ),
      'learnset' => _PokedexLearnsetTab(
          detail: detail,
          onSave: onSaveLearnset,
        ),
      'evolutions' => _PokedexEvolutionTab(
          detail: detail,
          onSave: onSaveEvolution,
        ),
      'media' => _PokedexMediaTab(
          detail: detail,
          onSave: onSaveMedia,
        ),
      _ => _PokedexOverviewTab(
          entry: entry,
          detail: detail,
          onSaveMetadata: onSaveMetadata,
        ),
    };
  }
}
```

### `packages/map_editor/lib/src/ui/canvas/pokedex_workspace/pokedex_overview_panel.dart`
```dart
part of 'pokedex_workspace_page.dart';

// Onglet overview de la fiche détail.
//
// C'est la vue la plus orientée produit : identité, stats, talents, refs et
// métadonnées locales éditables. Elle doit rester lisible même pour un profil
// non technique.

class _PokedexOverviewTab extends StatelessWidget {
  const _PokedexOverviewTab({
    required this.entry,
    required this.detail,
    required this.onSaveMetadata,
  });

  final PokemonDatabaseIndexEntry entry;
  final PokedexSpeciesDetail detail;
  final Future<void> Function(UpdatePokedexSpeciesMetadataRequest request)
      onSaveMetadata;

  @override
  Widget build(BuildContext context) {
    final species = detail.species;

    return SingleChildScrollView(
      key: const Key('pokedex-overview-tab'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _PokedexDetailSectionCard(
            title: 'Identité',
            child: Column(
              children: [
                _PokedexPropertyLine(
                  label: 'Nom principal',
                  value: entry.primaryName,
                ),
                _PokedexPropertyLine(label: 'ID', value: species.id),
                _PokedexPropertyLine(
                  label: 'Numéro national',
                  value: species.nationalDex.toString(),
                ),
                _PokedexPropertyLine(
                  label: 'Nom espèce',
                  value: _localizedValue(species.speciesName),
                ),
                _PokedexPropertyLine(
                  label: 'Génération',
                  value: species.genIntroduced.toString(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _PokedexEditableMetadataSection(
            species: species,
            onSave: onSaveMetadata,
          ),
          const SizedBox(height: 12),
          _PokedexDetailSectionCard(
            title: 'Stats',
            child: Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _StatChip(label: 'HP', value: species.baseStats.hp),
                _StatChip(label: 'ATK', value: species.baseStats.atk),
                _StatChip(label: 'DEF', value: species.baseStats.def),
                _StatChip(label: 'SPA', value: species.baseStats.spa),
                _StatChip(label: 'SPD', value: species.baseStats.spd),
                _StatChip(label: 'SPE', value: species.baseStats.spe),
                _StatChip(label: 'BST', value: species.baseStats.bst),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _PokedexDetailSectionCard(
            title: 'Talents',
            child: Column(
              children: [
                _PokedexPropertyLine(
                  label: 'Talent principal',
                  value: species.abilities.primary,
                ),
                _PokedexPropertyLine(
                  label: 'Talent secondaire',
                  value: species.abilities.secondary ?? 'Aucun',
                ),
                _PokedexPropertyLine(
                  label: 'Talent caché',
                  value: species.abilities.hidden ?? 'Aucun',
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _PokedexDetailSectionCard(
            title: 'Références locales',
            child: Column(
              children: [
                _PokedexPropertyLine(
                  label: 'Learnset',
                  value: species.refs.learnset,
                ),
                _PokedexPropertyLine(
                  label: 'Évolution',
                  value: species.refs.evolution,
                ),
                _PokedexPropertyLine(
                  label: 'Média',
                  value: species.refs.media,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
```

### `packages/map_editor/lib/src/ui/canvas/pokedex_workspace/pokedex_metadata_editor.dart`
```dart
part of 'pokedex_workspace_page.dart';

// Édition locale des métadonnées simples.
//
// Cette section réutilise le use case métier déjà en place. Le composant garde
// seulement le draft d'écran, pour permettre modifier / annuler / enregistrer
// sans dupliquer la source de vérité persistée.

class _PokedexEditableMetadataSection extends StatefulWidget {
  const _PokedexEditableMetadataSection({
    required this.species,
    required this.onSave,
  });

  final PokemonSpeciesFile species;
  final Future<void> Function(UpdatePokedexSpeciesMetadataRequest request)
      onSave;

  @override
  State<_PokedexEditableMetadataSection> createState() =>
      _PokedexEditableMetadataSectionState();
}

class _PokedexEditableMetadataSectionState
    extends State<_PokedexEditableMetadataSection> {
  final Map<String, TextEditingController> _nameControllers =
      <String, TextEditingController>{};
  final List<TextEditingController> _typeControllers =
      <TextEditingController>[];
  late TextEditingController _flavorTextController;
  late List<String> _orderedLocales;
  late bool _isEnabledInProject;
  late bool _starterEligible;
  late bool _giftOnly;
  late bool _tradeOnly;
  bool _isEditing = false;
  bool _isSaving = false;
  String? _saveErrorMessage;

  @override
  void initState() {
    super.initState();
    _flavorTextController = TextEditingController();
    _replaceDraftFromSpecies(widget.species);
  }

  @override
  void didUpdateWidget(covariant _PokedexEditableMetadataSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.species != widget.species) {
      // Dès qu'une nouvelle espèce est relue depuis le workspace, on considère
      // qu'elle devient la nouvelle vérité locale :
      // - après sélection d'une autre ligne ;
      // - après sauvegarde réussie et rechargement ;
      // - après changement de filtres qui force une nouvelle fiche.
      //
      // On jette donc proprement tout draft local restant.
      _replaceDraftFromSpecies(widget.species);
      _isEditing = false;
      _isSaving = false;
      _saveErrorMessage = null;
    }
  }

  @override
  void dispose() {
    _disposeNameControllers();
    _disposeTypeControllers();
    _flavorTextController.dispose();
    super.dispose();
  }

  void _replaceDraftFromSpecies(PokemonSpeciesFile species) {
    _disposeNameControllers();
    _disposeTypeControllers();

    _orderedLocales = _orderedLocaleKeys(species.names);
    for (final locale in _orderedLocales) {
      _nameControllers[locale] = TextEditingController(
        text: species.names[locale] ?? '',
      );
    }
    final sourceTypes = species.typing.types.isEmpty
        ? const <String>['']
        : species.typing.types;
    for (final type in sourceTypes) {
      _typeControllers.add(TextEditingController(text: type));
    }

    _flavorTextController.value = TextEditingValue(
      text: species.dexContent.flavorText ?? '',
      selection: TextSelection.collapsed(
        offset: (species.dexContent.flavorText ?? '').length,
      ),
    );
    _isEnabledInProject = species.classification.isEnabledInProject;
    _starterEligible = species.gameplayFlags.starterEligible;
    _giftOnly = species.gameplayFlags.giftOnly;
    _tradeOnly = species.gameplayFlags.tradeOnly;
  }

  void _disposeNameControllers() {
    for (final controller in _nameControllers.values) {
      controller.dispose();
    }
    _nameControllers.clear();
  }

  void _disposeTypeControllers() {
    for (final controller in _typeControllers) {
      controller.dispose();
    }
    _typeControllers.clear();
  }

  Future<void> _saveDraft() async {
    if (_isSaving) {
      return;
    }

    setState(() {
      _isSaving = true;
      _saveErrorMessage = null;
    });

    try {
      await widget.onSave(
        UpdatePokedexSpeciesMetadataRequest(
          speciesId: widget.species.id,
          isEnabledInProject: _isEnabledInProject,
          names: <String, String>{
            for (final locale in _orderedLocales)
              locale: _nameControllers[locale]?.text ?? '',
          },
          types: _typeControllers.map((controller) => controller.text).toList(),
          flavorText: _flavorTextController.text,
          starterEligible: _starterEligible,
          giftOnly: _giftOnly,
          tradeOnly: _tradeOnly,
        ),
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _isEditing = false;
        _isSaving = false;
        _saveErrorMessage = null;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      final message = switch (error) {
        final EditorApplicationException applicationError =>
          applicationError.message,
        _ => error.toString(),
      };

      setState(() {
        _isSaving = false;
        _saveErrorMessage = message;
      });
    }
  }

  void _addTypeField() {
    setState(() {
      _typeControllers.add(TextEditingController());
    });
  }

  void _removeTypeField(int index) {
    if (_typeControllers.length <= 1) {
      return;
    }
    setState(() {
      final controller = _typeControllers.removeAt(index);
      controller.dispose();
    });
  }

  void _cancelEditing() {
    setState(() {
      _replaceDraftFromSpecies(widget.species);
      _isEditing = false;
      _isSaving = false;
      _saveErrorMessage = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final species = widget.species;

    return _PokedexDetailSectionCard(
      title: 'Métadonnées locales',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_isEditing) ...[
            _PokedexBooleanEditorRow(
              key: const Key('pokedex-enabled-switch-row'),
              label: 'Activée dans le projet',
              description:
                  'Le filtre liste et le statut local utilisent ce booléen persistant.',
              value: _isEnabledInProject,
              switchKey: const Key('pokedex-enabled-switch'),
              onChanged: _isSaving
                  ? null
                  : (value) => setState(() => _isEnabledInProject = value),
            ),
            const SizedBox(height: 12),
            for (final locale in _orderedLocales) ...[
              _PokedexEditorTextField(
                label: 'Nom (${locale.toUpperCase()})',
                fieldKey: Key('pokedex-name-field-$locale'),
                controller: _nameControllers[locale]!,
                enabled: !_isSaving,
              ),
              const SizedBox(height: 10),
            ],
            _PokedexEditableTypeFields(
              controllers: _typeControllers,
              enabled: !_isSaving,
              onAddType: _isSaving ? null : _addTypeField,
              onRemoveType: _isSaving ? null : _removeTypeField,
            ),
            const SizedBox(height: 12),
            _PokedexEditorTextField(
              label: 'Texte Pokédex',
              fieldKey: const Key('pokedex-flavor-text-field'),
              controller: _flavorTextController,
              enabled: !_isSaving,
              minLines: 3,
              maxLines: 6,
              placeholder: 'Texte local affiché dans la fiche Pokédex',
            ),
            const SizedBox(height: 12),
            _PokedexBooleanEditorRow(
              key: const Key('pokedex-starter-eligible-switch-row'),
              label: 'Starter éligible',
              value: _starterEligible,
              switchKey: const Key('pokedex-starter-eligible-switch'),
              onChanged: _isSaving
                  ? null
                  : (value) => setState(() => _starterEligible = value),
            ),
            const SizedBox(height: 10),
            _PokedexBooleanEditorRow(
              key: const Key('pokedex-gift-only-switch-row'),
              label: 'Obtenu par cadeau',
              value: _giftOnly,
              switchKey: const Key('pokedex-gift-only-switch'),
              onChanged: _isSaving
                  ? null
                  : (value) => setState(() => _giftOnly = value),
            ),
            const SizedBox(height: 10),
            _PokedexBooleanEditorRow(
              key: const Key('pokedex-trade-only-switch-row'),
              label: 'Échange uniquement',
              value: _tradeOnly,
              switchKey: const Key('pokedex-trade-only-switch'),
              onChanged: _isSaving
                  ? null
                  : (value) => setState(() => _tradeOnly = value),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                CupertinoButton.filled(
                  key: const Key('pokedex-save-metadata-button'),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  onPressed: _isSaving ? null : _saveDraft,
                  child: Text(_isSaving ? 'Enregistrement…' : 'Enregistrer'),
                ),
                const SizedBox(width: 10),
                CupertinoButton(
                  key: const Key('pokedex-cancel-metadata-button'),
                  onPressed: _isSaving ? null : _cancelEditing,
                  child: const Text('Annuler'),
                ),
              ],
            ),
            if (_saveErrorMessage != null) ...[
              const SizedBox(height: 10),
              Text(
                _saveErrorMessage!,
                key: const Key('pokedex-metadata-save-error'),
                style: const TextStyle(
                  color: EditorChrome.inspectorJoyCoral,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ] else ...[
            _PokedexPropertyLine(
              label: 'Statut projet',
              value: species.classification.isEnabledInProject
                  ? 'Activée'
                  : 'Désactivée',
            ),
            for (final locale in _orderedLocaleKeys(species.names))
              _PokedexPropertyLine(
                label: 'Nom (${locale.toUpperCase()})',
                value: (species.names[locale]?.trim().isNotEmpty ?? false)
                    ? species.names[locale]!.trim()
                    : 'Valeur vide',
              ),
            _PokedexPropertyLine(
              label: 'Texte Pokédex',
              value: species.dexContent.flavorText?.trim().isNotEmpty == true
                  ? species.dexContent.flavorText!.trim()
                  : 'Aucun texte local',
            ),
            _PokedexPropertyLine(
              label: 'Types',
              value: species.typing.types.isEmpty
                  ? 'Aucun type'
                  : species.typing.types.join(', '),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _FlagChip(
                  label: species.gameplayFlags.starterEligible
                      ? 'Starter éligible'
                      : 'Starter non éligible',
                ),
                _FlagChip(
                  label: species.gameplayFlags.giftOnly
                      ? 'Obtenu par cadeau'
                      : 'Pas cadeau uniquement',
                ),
                _FlagChip(
                  label: species.gameplayFlags.tradeOnly
                      ? 'Échange uniquement'
                      : 'Pas échange uniquement',
                ),
              ],
            ),
            const SizedBox(height: 14),
            CupertinoButton(
              key: const Key('pokedex-edit-metadata-button'),
              padding: EdgeInsets.zero,
              onPressed: () {
                setState(() {
                  _replaceDraftFromSpecies(widget.species);
                  _isEditing = true;
                  _saveErrorMessage = null;
                });
              },
              child: const Text('Modifier'),
            ),
          ],
        ],
      ),
    );
  }
}
```

### `packages/map_editor/lib/src/ui/canvas/pokedex_workspace/pokedex_metadata_editor_fields.dart`
```dart
part of 'pokedex_workspace_page.dart';

// Champs et switches réutilisés par l'édition locale.
//
// On les isole pour rendre le formulaire lisible et garder le fichier de la
// section metadata sous la barre des 400 lignes.

class _PokedexBooleanEditorRow extends StatelessWidget {
  const _PokedexBooleanEditorRow({
    super.key,
    required this.label,
    required this.value,
    required this.switchKey,
    required this.onChanged,
    this.description,
  });

  final String label;
  final bool value;
  final Key switchKey;
  final ValueChanged<bool>? onChanged;
  final String? description;

  @override
  Widget build(BuildContext context) {
    final labelColor = EditorChrome.primaryLabel(context);
    final subtle = EditorChrome.subtleLabel(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: labelColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (description != null) ...[
                const SizedBox(height: 4),
                Text(
                  description!,
                  style: TextStyle(
                    color: subtle,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    height: 1.35,
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(width: 12),
        CupertinoSwitch(
          key: switchKey,
          value: value,
          onChanged: onChanged,
        ),
      ],
    );
  }
}

class _PokedexEditorTextField extends StatelessWidget {
  const _PokedexEditorTextField({
    required this.label,
    required this.fieldKey,
    required this.controller,
    required this.enabled,
    this.minLines = 1,
    this.maxLines = 1,
    this.placeholder,
    this.description,
  });

  final String label;
  final Key fieldKey;
  final TextEditingController controller;
  final bool enabled;
  final int minLines;
  final int maxLines;
  final String? placeholder;
  final String? description;

  @override
  Widget build(BuildContext context) {
    final labelColor = EditorChrome.primaryLabel(context);
    final subtle = EditorChrome.subtleLabel(context);
    final surface = EditorChrome.islandFillElevated(context);
    final border = EditorChrome.accentWarm.withValues(alpha: 0.28);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: labelColor,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
        if (description != null) ...[
          const SizedBox(height: 4),
          Text(
            description!,
            style: TextStyle(
              color: subtle,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              height: 1.35,
            ),
          ),
        ],
        const SizedBox(height: 6),
        DecoratedBox(
          decoration: BoxDecoration(
            color: surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: border, width: 1),
          ),
          child: CupertinoTextField(
            key: fieldKey,
            controller: controller,
            enabled: enabled,
            minLines: minLines,
            maxLines: maxLines,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            placeholder: placeholder,
            placeholderStyle: TextStyle(
              color: subtle,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

class _PokedexEditableTypeFields extends StatelessWidget {
  const _PokedexEditableTypeFields({
    required this.controllers,
    required this.enabled,
    required this.onAddType,
    required this.onRemoveType,
  });

  final List<TextEditingController> controllers;
  final bool enabled;
  final VoidCallback? onAddType;
  final void Function(int index)? onRemoveType;

  @override
  Widget build(BuildContext context) {
    final labelColor = EditorChrome.primaryLabel(context);
    final subtle = EditorChrome.subtleLabel(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Types',
                style: TextStyle(
                  color: labelColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            CupertinoButton(
              key: const Key('pokedex-add-type-button'),
              padding: EdgeInsets.zero,
              onPressed: enabled ? onAddType : null,
              child: const Text('+ ajouter'),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Le premier type reste le type principal affiché dans la liste. Les valeurs vides sont ignorées à la sauvegarde.',
          style: TextStyle(
            color: subtle,
            fontSize: 11,
            fontWeight: FontWeight.w600,
            height: 1.35,
          ),
        ),
        const SizedBox(height: 8),
        for (var index = 0; index < controllers.length; index++) ...[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _PokedexEditorTextField(
                  label: 'Type ${index + 1}',
                  fieldKey: Key('pokedex-type-field-$index'),
                  controller: controllers[index],
                  enabled: enabled,
                  placeholder: 'electric',
                ),
              ),
              const SizedBox(width: 10),
              CupertinoButton(
                key: Key('pokedex-remove-type-button-$index'),
                padding: const EdgeInsets.only(top: 28),
                onPressed: enabled && controllers.length > 1
                    ? () => onRemoveType?.call(index)
                    : null,
                child: const Text('Retirer'),
              ),
            ],
          ),
          if (index != controllers.length - 1) const SizedBox(height: 10),
        ],
      ],
    );
  }
}
```

### `packages/map_editor/lib/src/ui/canvas/pokedex_workspace/pokedex_forms_panel.dart`
```dart
part of 'pokedex_workspace_page.dart';

// Onglet Formes / classification.
//
// Le flux reste identique à celui déjà branché aux use cases existants. Ici on
// améliore surtout la lisibilité et le découpage du code UI.

class _PokedexFormsTab extends StatefulWidget {
  const _PokedexFormsTab({
    required this.detail,
    required this.onSave,
  });

  final PokedexSpeciesDetail detail;
  final Future<void> Function(
    UpdatePokedexSpeciesFormsClassificationRequest request,
  ) onSave;

  @override
  State<_PokedexFormsTab> createState() => _PokedexFormsTabState();
}

class _PokedexFormsTabState extends State<_PokedexFormsTab> {
  late final TextEditingController _baseFormIdController;
  late final TextEditingController _formIdController;
  late final TextEditingController _formNameController;
  late final TextEditingController _otherFormsController;
  late bool _isBaseForm;
  late bool _isObtainable;
  late bool _isLegendary;
  late bool _isMythical;
  late bool _isBaby;
  bool _isEditing = false;
  bool _isSaving = false;
  String? _saveErrorMessage;

  @override
  void initState() {
    super.initState();
    _baseFormIdController = TextEditingController();
    _formIdController = TextEditingController();
    _formNameController = TextEditingController();
    _otherFormsController = TextEditingController();
    _replaceDraftFromSpecies(widget.detail.species);
  }

  @override
  void didUpdateWidget(covariant _PokedexFormsTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.detail != widget.detail) {
      _replaceDraftFromSpecies(widget.detail.species);
      _isEditing = false;
      _isSaving = false;
      _saveErrorMessage = null;
    }
  }

  @override
  void dispose() {
    _baseFormIdController.dispose();
    _formIdController.dispose();
    _formNameController.dispose();
    _otherFormsController.dispose();
    super.dispose();
  }

  void _replaceDraftFromSpecies(PokemonSpeciesFile species) {
    final forms = species.forms;
    final classification = species.classification;
    _baseFormIdController.text =
        forms.baseFormId.trim().isEmpty ? species.id : forms.baseFormId;
    _formIdController.text = forms.formId;
    _formNameController.text = forms.formName ?? '';
    _otherFormsController.text = forms.otherForms.join('\n');
    _isBaseForm = forms.isBaseForm;
    _isObtainable = classification.isObtainable;
    _isLegendary = classification.isLegendary;
    _isMythical = classification.isMythical;
    _isBaby = classification.isBaby;
  }

  Future<void> _saveDraft() async {
    if (_isSaving) {
      return;
    }

    setState(() {
      _isSaving = true;
      _saveErrorMessage = null;
    });

    try {
      await widget.onSave(
        UpdatePokedexSpeciesFormsClassificationRequest(
          speciesId: widget.detail.species.id,
          baseFormId: _isBaseForm
              ? widget.detail.species.id
              : _baseFormIdController.text,
          isBaseForm: _isBaseForm,
          formId: _formIdController.text,
          formName: _formNameController.text,
          otherForms: _splitNonEmptyLines(_otherFormsController.text),
          isObtainable: _isObtainable,
          isLegendary: _isLegendary,
          isMythical: _isMythical,
          isBaby: _isBaby,
        ),
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _isEditing = false;
        _isSaving = false;
        _saveErrorMessage = null;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      final message = switch (error) {
        final EditorApplicationException applicationError =>
          applicationError.message,
        _ => error.toString(),
      };
      setState(() {
        _isSaving = false;
        _saveErrorMessage = message;
      });
    }
  }

  void _cancelEditing() {
    setState(() {
      _replaceDraftFromSpecies(widget.detail.species);
      _isEditing = false;
      _isSaving = false;
      _saveErrorMessage = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final species = widget.detail.species;
    final forms = species.forms;
    final classification = species.classification;
    final currentFormId = forms.formId.isEmpty ? 'base' : forms.formId;
    final baseFormId = forms.baseFormId.isEmpty ? species.id : forms.baseFormId;

    return SingleChildScrollView(
      key: const Key('pokedex-forms-tab'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _PokedexDetailSectionCard(
            title: 'Formes et classification',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_isEditing) ...[
                  _PokedexBooleanEditorRow(
                    key: const Key('pokedex-is-base-form-switch-row'),
                    label: 'Forme de base',
                    description:
                        'Quand ce flag est actif, la baseFormId suit automatiquement l’id de l’espèce.',
                    value: _isBaseForm,
                    switchKey: const Key('pokedex-is-base-form-switch'),
                    onChanged: _isSaving
                        ? null
                        : (value) => setState(() => _isBaseForm = value),
                  ),
                  const SizedBox(height: 12),
                  _PokedexEditorTextField(
                    label: 'Form ID',
                    description:
                        'Identifiant local simple de la forme courante.',
                    fieldKey: const Key('pokedex-form-id-field'),
                    controller: _formIdController,
                    enabled: !_isSaving,
                  ),
                  const SizedBox(height: 10),
                  _PokedexEditorTextField(
                    label: 'Base form ID',
                    description:
                        'Référence locale de la forme de base. Verrouillée si cette espèce est la base.',
                    fieldKey: const Key('pokedex-base-form-id-field'),
                    controller: _baseFormIdController,
                    enabled: !_isSaving && !_isBaseForm,
                  ),
                  const SizedBox(height: 10),
                  _PokedexEditorTextField(
                    label: 'Nom de forme',
                    description:
                        'Valeur optionnelle affichée dans la fiche locale.',
                    fieldKey: const Key('pokedex-form-name-field'),
                    controller: _formNameController,
                    enabled: !_isSaving,
                    placeholder: 'Ex. Méga, Alola, Hisui…',
                  ),
                  const SizedBox(height: 10),
                  _PokedexEditorTextField(
                    label: 'Autres formes',
                    description:
                        'Une forme par ligne. Les valeurs vides, doublons et auto-références sont ignorés.',
                    fieldKey: const Key('pokedex-other-forms-field'),
                    controller: _otherFormsController,
                    enabled: !_isSaving,
                    minLines: 3,
                    maxLines: 6,
                    placeholder: 'mega\nalola\nhisui',
                  ),
                  const SizedBox(height: 12),
                  _PokedexBooleanEditorRow(
                    key: const Key('pokedex-is-obtainable-switch-row'),
                    label: 'Obtenable',
                    value: _isObtainable,
                    switchKey: const Key('pokedex-is-obtainable-switch'),
                    onChanged: _isSaving
                        ? null
                        : (value) => setState(() => _isObtainable = value),
                  ),
                  const SizedBox(height: 10),
                  _PokedexBooleanEditorRow(
                    key: const Key('pokedex-is-legendary-switch-row'),
                    label: 'Légendaire',
                    value: _isLegendary,
                    switchKey: const Key('pokedex-is-legendary-switch'),
                    onChanged: _isSaving
                        ? null
                        : (value) => setState(() => _isLegendary = value),
                  ),
                  const SizedBox(height: 10),
                  _PokedexBooleanEditorRow(
                    key: const Key('pokedex-is-mythical-switch-row'),
                    label: 'Mythique',
                    value: _isMythical,
                    switchKey: const Key('pokedex-is-mythical-switch'),
                    onChanged: _isSaving
                        ? null
                        : (value) => setState(() => _isMythical = value),
                  ),
                  const SizedBox(height: 10),
                  _PokedexBooleanEditorRow(
                    key: const Key('pokedex-is-baby-switch-row'),
                    label: 'Bébé',
                    value: _isBaby,
                    switchKey: const Key('pokedex-is-baby-switch'),
                    onChanged: _isSaving
                        ? null
                        : (value) => setState(() => _isBaby = value),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      CupertinoButton.filled(
                        key: const Key('pokedex-save-forms-button'),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        onPressed: _isSaving ? null : _saveDraft,
                        child: Text(
                          _isSaving ? 'Enregistrement…' : 'Enregistrer',
                        ),
                      ),
                      const SizedBox(width: 10),
                      CupertinoButton(
                        key: const Key('pokedex-cancel-forms-button'),
                        onPressed: _isSaving ? null : _cancelEditing,
                        child: const Text('Annuler'),
                      ),
                    ],
                  ),
                  if (_saveErrorMessage != null) ...[
                    const SizedBox(height: 10),
                    Text(
                      _saveErrorMessage!,
                      key: const Key('pokedex-forms-save-error'),
                      style: const TextStyle(
                        color: EditorChrome.inspectorJoyCoral,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ] else ...[
                  _PokedexPropertyLine(
                    label: 'Forme courante',
                    value: forms.formName == null || forms.formName!.isEmpty
                        ? currentFormId
                        : '${forms.formName} ($currentFormId)',
                  ),
                  _PokedexPropertyLine(
                    label: 'Forme de base',
                    value: baseFormId,
                  ),
                  _PokedexPropertyLine(
                    label: 'Est la forme de base',
                    value: forms.isBaseForm ? 'Oui' : 'Non',
                  ),
                  _PokedexPropertyLine(
                    label: 'Autres formes',
                    value: forms.otherForms.isEmpty
                        ? 'Aucune autre forme locale'
                        : forms.otherForms.join(', '),
                  ),
                  _PokedexPropertyLine(
                    label: 'Statut projet',
                    value: classification.isEnabledInProject
                        ? 'Activée'
                        : 'Désactivée',
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _FlagChip(
                        label: classification.isObtainable
                            ? 'Obtenable'
                            : 'Non obtenable',
                      ),
                      if (classification.isLegendary)
                        const _FlagChip(label: 'Légendaire'),
                      if (classification.isMythical)
                        const _FlagChip(label: 'Mythique'),
                      if (classification.isBaby) const _FlagChip(label: 'Bébé'),
                      if (!classification.isLegendary &&
                          !classification.isMythical &&
                          !classification.isBaby)
                        const _FlagChip(label: 'Aucun flag rare'),
                    ],
                  ),
                  const SizedBox(height: 14),
                  CupertinoButton(
                    key: const Key('pokedex-edit-forms-button'),
                    padding: EdgeInsets.zero,
                    onPressed: () {
                      setState(() {
                        _replaceDraftFromSpecies(widget.detail.species);
                        _isEditing = true;
                        _saveErrorMessage = null;
                      });
                    },
                    child: const Text('Modifier'),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 12),
          _PokedexDetailSectionCard(
            title: 'Flags gameplay simples',
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (species.gameplayFlags.starterEligible)
                  const _FlagChip(label: 'Starter éligible'),
                if (species.gameplayFlags.giftOnly)
                  const _FlagChip(label: 'Obtenu par cadeau'),
                if (species.gameplayFlags.tradeOnly)
                  const _FlagChip(label: 'Échange uniquement'),
                if (!species.gameplayFlags.starterEligible &&
                    !species.gameplayFlags.giftOnly &&
                    !species.gameplayFlags.tradeOnly)
                  const _FlagChip(label: 'Aucun flag gameplay'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
```

### `packages/map_editor/lib/src/ui/canvas/pokedex_workspace/pokedex_learnset_panel.dart`
```dart
part of 'pokedex_workspace_page.dart';

// Onglet Learnset.
//
// Cette vue expose les sections déjà supportées par l'application sans modifier
// le contrat métier. L'objectif de ce réalignement est de rendre l'écran plus
// facile à relire et à maintenir, pas de changer la logique d'édition.

class _PokedexLearnsetTab extends StatefulWidget {
  const _PokedexLearnsetTab({
    required this.detail,
    required this.onSave,
  });

  final PokedexSpeciesDetail detail;
  final Future<void> Function(UpdatePokedexSpeciesLearnsetRequest request)
      onSave;

  @override
  State<_PokedexLearnsetTab> createState() => _PokedexLearnsetTabState();
}

class _PokedexLearnsetTabState extends State<_PokedexLearnsetTab> {
  late final TextEditingController _startingMovesController;
  late final TextEditingController _relearnMovesController;
  late final TextEditingController _levelUpController;
  late final TextEditingController _tmController;
  late final TextEditingController _tutorController;
  late final TextEditingController _eggController;
  late final TextEditingController _eventController;
  late final TextEditingController _transferController;
  bool _isEditing = false;
  bool _isSaving = false;
  String? _saveErrorMessage;

  @override
  void initState() {
    super.initState();
    _startingMovesController = TextEditingController();
    _relearnMovesController = TextEditingController();
    _levelUpController = TextEditingController();
    _tmController = TextEditingController();
    _tutorController = TextEditingController();
    _eggController = TextEditingController();
    _eventController = TextEditingController();
    _transferController = TextEditingController();
    _replaceDraftFromDetail(widget.detail);
  }

  @override
  void didUpdateWidget(covariant _PokedexLearnsetTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.detail != widget.detail) {
      _replaceDraftFromDetail(widget.detail);
      _isEditing = false;
      _isSaving = false;
      _saveErrorMessage = null;
    }
  }

  @override
  void dispose() {
    _startingMovesController.dispose();
    _relearnMovesController.dispose();
    _levelUpController.dispose();
    _tmController.dispose();
    _tutorController.dispose();
    _eggController.dispose();
    _eventController.dispose();
    _transferController.dispose();
    super.dispose();
  }

  void _replaceDraftFromDetail(PokedexSpeciesDetail detail) {
    final learnset = detail.learnset;
    _startingMovesController.text =
        learnset == null ? '' : _formatLineList(learnset.startingMoves);
    _relearnMovesController.text =
        learnset == null ? '' : _formatLineList(learnset.relearnMoves);
    _levelUpController.text =
        learnset == null ? '' : _formatLearnsetLevelUpEntries(learnset.levelUp);
    _tmController.text =
        learnset == null ? '' : _formatLearnsetMoveEntries(learnset.tm);
    _tutorController.text =
        learnset == null ? '' : _formatLearnsetMoveEntries(learnset.tutor);
    _eggController.text =
        learnset == null ? '' : _formatLearnsetMoveEntries(learnset.egg);
    _eventController.text =
        learnset == null ? '' : _formatLearnsetMoveEntries(learnset.event);
    _transferController.text =
        learnset == null ? '' : _formatLearnsetMoveEntries(learnset.transfer);
  }

  Future<void> _saveDraft() async {
    if (_isSaving) {
      return;
    }

    setState(() {
      _isSaving = true;
      _saveErrorMessage = null;
    });

    try {
      await widget.onSave(
        UpdatePokedexSpeciesLearnsetRequest(
          speciesId: widget.detail.species.id,
          startingMoves: _splitNonEmptyLines(_startingMovesController.text),
          relearnMoves: _splitNonEmptyLines(_relearnMovesController.text),
          levelUp: _parseLearnsetLevelUpEntries(_levelUpController.text),
          tm: _parseLearnsetMoveEntries(_tmController.text, label: 'tm'),
          tutor: _parseLearnsetMoveEntries(
            _tutorController.text,
            label: 'tutor',
          ),
          egg: _parseLearnsetMoveEntries(_eggController.text, label: 'egg'),
          event: _parseLearnsetMoveEntries(
            _eventController.text,
            label: 'event',
          ),
          transfer: _parseLearnsetMoveEntries(
            _transferController.text,
            label: 'transfer',
          ),
        ),
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _isEditing = false;
        _isSaving = false;
        _saveErrorMessage = null;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      final message = switch (error) {
        final EditorApplicationException applicationError =>
          applicationError.message,
        _ => error.toString(),
      };
      setState(() {
        _isSaving = false;
        _saveErrorMessage = message;
      });
    }
  }

  void _cancelEditing() {
    setState(() {
      _replaceDraftFromDetail(widget.detail);
      _isEditing = false;
      _isSaving = false;
      _saveErrorMessage = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final learnset = widget.detail.learnset;
    final learnsetRef = widget.detail.species.refs.learnset.trim();

    return SingleChildScrollView(
      key: const Key('pokedex-learnset-tab'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_isEditing) ...[
            _PokedexLearnsetEditSection(
              learnsetRef: learnsetRef,
              isSaving: _isSaving,
              saveErrorMessage: _saveErrorMessage,
              startingMovesController: _startingMovesController,
              relearnMovesController: _relearnMovesController,
              levelUpController: _levelUpController,
              tmController: _tmController,
              tutorController: _tutorController,
              eggController: _eggController,
              eventController: _eventController,
              transferController: _transferController,
              onSave: _saveDraft,
              onCancel: _cancelEditing,
            ),
          ] else ...[
            _PokedexLearnsetReadOnlySection(
              learnset: learnset,
              learnsetRef: learnsetRef,
              onEditRequested: learnsetRef.isEmpty
                  ? null
                  : () {
                      setState(() {
                        _replaceDraftFromDetail(widget.detail);
                        _isEditing = true;
                        _saveErrorMessage = null;
                      });
                    },
            ),
          ],
        ],
      ),
    );
  }
}
```

### `packages/map_editor/lib/src/ui/canvas/pokedex_workspace/pokedex_learnset_sections.dart`
```dart
part of 'pokedex_workspace_page.dart';

// Sous-sections de l'onglet Learnset.
//
// On extrait le rendu lecture/édition pour garder l'onglet principal léger.
// Cela permet de conserver le même comportement applicatif tout en rendant le
// code UI plus facile à relire, à tester et à faire évoluer.

class _PokedexLearnsetEditSection extends StatelessWidget {
  const _PokedexLearnsetEditSection({
    required this.learnsetRef,
    required this.isSaving,
    required this.saveErrorMessage,
    required this.startingMovesController,
    required this.relearnMovesController,
    required this.levelUpController,
    required this.tmController,
    required this.tutorController,
    required this.eggController,
    required this.eventController,
    required this.transferController,
    required this.onSave,
    required this.onCancel,
  });

  final String learnsetRef;
  final bool isSaving;
  final String? saveErrorMessage;
  final TextEditingController startingMovesController;
  final TextEditingController relearnMovesController;
  final TextEditingController levelUpController;
  final TextEditingController tmController;
  final TextEditingController tutorController;
  final TextEditingController eggController;
  final TextEditingController eventController;
  final TextEditingController transferController;
  final VoidCallback onSave;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    return _PokedexDetailSectionCard(
      title: 'Édition learnset locale',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _PokedexPropertyLine(
            label: 'Ref learnset',
            value: learnsetRef.isEmpty ? 'Ref absente' : learnsetRef,
          ),
          const SizedBox(height: 10),
          _PokedexEditorTextField(
            label: 'Moves de départ',
            description:
                'Un move id par ligne. Les doublons exacts sont ignorés.',
            fieldKey: const Key('pokedex-learnset-starting-field'),
            controller: startingMovesController,
            enabled: !isSaving,
            minLines: 2,
            maxLines: 5,
            placeholder: 'tackle\ngrowl',
          ),
          const SizedBox(height: 10),
          _PokedexEditorTextField(
            label: 'Moves à réapprendre',
            description: 'Un move id par ligne.',
            fieldKey: const Key('pokedex-learnset-relearn-field'),
            controller: relearnMovesController,
            enabled: !isSaving,
            minLines: 2,
            maxLines: 5,
            placeholder: 'vine_whip',
          ),
          const SizedBox(height: 10),
          _PokedexEditorTextField(
            label: 'Level-up',
            description:
                'Une entrée par ligne au format moveId|level|source|versionGroup.',
            fieldKey: const Key('pokedex-learnset-level-up-field'),
            controller: levelUpController,
            enabled: !isSaving,
            minLines: 3,
            maxLines: 8,
            placeholder: 'vine_whip|7|level_up|scarlet-violet',
          ),
          const SizedBox(height: 10),
          _PokedexEditorTextField(
            label: 'TM',
            description: 'Une entrée par ligne au format moveId|versionGroup.',
            fieldKey: const Key('pokedex-learnset-tm-field'),
            controller: tmController,
            enabled: !isSaving,
            minLines: 2,
            maxLines: 6,
            placeholder: 'protect|scarlet-violet',
          ),
          const SizedBox(height: 10),
          _PokedexEditorTextField(
            label: 'Tutor',
            description: 'Une entrée par ligne au format moveId|versionGroup.',
            fieldKey: const Key('pokedex-learnset-tutor-field'),
            controller: tutorController,
            enabled: !isSaving,
            minLines: 2,
            maxLines: 6,
            placeholder: 'seed_bomb|scarlet-violet',
          ),
          const SizedBox(height: 10),
          _PokedexEditorTextField(
            label: 'Egg',
            description: 'Une entrée par ligne au format moveId|versionGroup.',
            fieldKey: const Key('pokedex-learnset-egg-field'),
            controller: eggController,
            enabled: !isSaving,
            minLines: 2,
            maxLines: 6,
            placeholder: 'petal_dance|scarlet-violet',
          ),
          const SizedBox(height: 10),
          _PokedexEditorTextField(
            label: 'Event',
            description: 'Une entrée par ligne au format moveId|versionGroup.',
            fieldKey: const Key('pokedex-learnset-event-field'),
            controller: eventController,
            enabled: !isSaving,
            minLines: 2,
            maxLines: 6,
            placeholder: 'celebrate|scarlet-violet',
          ),
          const SizedBox(height: 10),
          _PokedexEditorTextField(
            label: 'Transfer',
            description: 'Une entrée par ligne au format moveId|versionGroup.',
            fieldKey: const Key('pokedex-learnset-transfer-field'),
            controller: transferController,
            enabled: !isSaving,
            minLines: 2,
            maxLines: 6,
            placeholder: 'toxic|scarlet-violet',
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              CupertinoButton.filled(
                key: const Key('pokedex-save-learnset-button'),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                onPressed: isSaving ? null : onSave,
                child: Text(isSaving ? 'Enregistrement…' : 'Enregistrer'),
              ),
              const SizedBox(width: 10),
              CupertinoButton(
                key: const Key('pokedex-cancel-learnset-button'),
                onPressed: isSaving ? null : onCancel,
                child: const Text('Annuler'),
              ),
            ],
          ),
          if (saveErrorMessage != null) ...[
            const SizedBox(height: 10),
            Text(
              saveErrorMessage!,
              key: const Key('pokedex-learnset-save-error'),
              style: const TextStyle(
                color: EditorChrome.inspectorJoyCoral,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _PokedexLearnsetReadOnlySection extends StatelessWidget {
  const _PokedexLearnsetReadOnlySection({
    required this.learnset,
    required this.learnsetRef,
    required this.onEditRequested,
  });

  final PokemonLearnsetFile? learnset;
  final String learnsetRef;
  final VoidCallback? onEditRequested;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (learnset == null)
          _PokedexMissingSection(
            key: const Key('pokedex-learnset-missing'),
            title: 'Learnset',
            message: learnsetRef.isEmpty
                ? 'La ref learnset est vide dans l’espèce locale ; aucun learnset ne peut être édité depuis cette fiche.'
                : 'Aucun learnset local trouvé pour cette espèce. Vous pouvez en créer un depuis cet onglet.',
          )
        else ...[
          _PokedexDetailSectionCard(
            title: 'Moves de départ',
            child: Text(
              learnset!.startingMoves.isEmpty
                  ? 'Aucun move de départ déclaré.'
                  : learnset!.startingMoves.join(', '),
            ),
          ),
          const SizedBox(height: 12),
          _PokedexDetailSectionCard(
            title: 'Moves à réapprendre',
            child: Text(
              learnset!.relearnMoves.isEmpty
                  ? 'Aucun move à réapprendre déclaré.'
                  : learnset!.relearnMoves.join(', '),
            ),
          ),
          const SizedBox(height: 12),
          _PokedexDetailSectionCard(
            title: 'Level-up',
            child: learnset!.levelUp.isEmpty
                ? const Text('Aucune entrée level-up.')
                : Column(
                    children: learnset!.levelUp
                        .map(
                          (entry) => _PokedexPropertyLine(
                            label: '${entry.moveId} • niveau ${entry.level}',
                            value:
                                '${entry.versionGroup} • source ${entry.source}',
                          ),
                        )
                        .toList(growable: false),
                  ),
          ),
          const SizedBox(height: 12),
          _LearnsetMoveSection(title: 'TM', entries: learnset!.tm),
          const SizedBox(height: 12),
          _LearnsetMoveSection(title: 'Tutor', entries: learnset!.tutor),
          const SizedBox(height: 12),
          _LearnsetMoveSection(title: 'Egg', entries: learnset!.egg),
          const SizedBox(height: 12),
          _LearnsetMoveSection(title: 'Event', entries: learnset!.event),
          const SizedBox(height: 12),
          _LearnsetMoveSection(title: 'Transfer', entries: learnset!.transfer),
        ],
        const SizedBox(height: 12),
        _PokedexDetailSectionCard(
          title: 'Édition locale',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                learnsetRef.isEmpty
                    ? 'Impossible d’éditer ce learnset tant que la ref locale est vide.'
                    : 'Le learnset édité réécrit uniquement le JSON local déjà relié par les refs de l’espèce.',
              ),
              if (onEditRequested != null) ...[
                const SizedBox(height: 14),
                CupertinoButton(
                  key: const Key('pokedex-edit-learnset-button'),
                  padding: EdgeInsets.zero,
                  onPressed: onEditRequested,
                  child:
                      Text(learnset == null ? 'Créer localement' : 'Modifier'),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
```

### `packages/map_editor/lib/src/ui/canvas/pokedex_workspace/pokedex_evolution_panel.dart`
```dart
part of 'pokedex_workspace_page.dart';

// Onglet Évolutions.
//
// On garde l'édition texte structurée existante, mais dans un fichier dédié pour
// éviter qu'un seul widget monopolise toute la maintenance du workspace.

class _PokedexEvolutionTab extends StatefulWidget {
  const _PokedexEvolutionTab({
    required this.detail,
    required this.onSave,
  });

  final PokedexSpeciesDetail detail;
  final Future<void> Function(UpdatePokedexSpeciesEvolutionRequest request)
      onSave;

  @override
  State<_PokedexEvolutionTab> createState() => _PokedexEvolutionTabState();
}

class _PokedexEvolutionTabState extends State<_PokedexEvolutionTab> {
  late final TextEditingController _preEvolutionController;
  late final TextEditingController _entriesController;
  bool _isEditing = false;
  bool _isSaving = false;
  String? _saveErrorMessage;

  @override
  void initState() {
    super.initState();
    _preEvolutionController = TextEditingController();
    _entriesController = TextEditingController();
    _replaceDraftFromDetail(widget.detail);
  }

  @override
  void didUpdateWidget(covariant _PokedexEvolutionTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.detail != widget.detail) {
      _replaceDraftFromDetail(widget.detail);
      _isEditing = false;
      _isSaving = false;
      _saveErrorMessage = null;
    }
  }

  @override
  void dispose() {
    _preEvolutionController.dispose();
    _entriesController.dispose();
    super.dispose();
  }

  void _replaceDraftFromDetail(PokedexSpeciesDetail detail) {
    final evolution = detail.evolution;
    _preEvolutionController.text = evolution?.preEvolution ?? '';
    _entriesController.text =
        evolution == null ? '' : _formatEvolutionEntries(evolution.evolutions);
  }

  Future<void> _saveDraft() async {
    if (_isSaving) {
      return;
    }

    setState(() {
      _isSaving = true;
      _saveErrorMessage = null;
    });

    try {
      await widget.onSave(
        UpdatePokedexSpeciesEvolutionRequest(
          speciesId: widget.detail.species.id,
          preEvolution: _preEvolutionController.text,
          evolutions: _parseEvolutionEntries(_entriesController.text),
        ),
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _isEditing = false;
        _isSaving = false;
        _saveErrorMessage = null;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      final message = switch (error) {
        final EditorApplicationException applicationError =>
          applicationError.message,
        _ => error.toString(),
      };
      setState(() {
        _isSaving = false;
        _saveErrorMessage = message;
      });
    }
  }

  void _cancelEditing() {
    setState(() {
      _replaceDraftFromDetail(widget.detail);
      _isEditing = false;
      _isSaving = false;
      _saveErrorMessage = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final evolution = widget.detail.evolution;
    final evolutionRef = widget.detail.species.refs.evolution.trim();

    return SingleChildScrollView(
      key: const Key('pokedex-evolutions-tab'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_isEditing) ...[
            _PokedexDetailSectionCard(
              title: 'Édition évolution locale',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _PokedexPropertyLine(
                    label: 'Ref évolution',
                    value: evolutionRef.isEmpty ? 'Ref absente' : evolutionRef,
                  ),
                  const SizedBox(height: 10),
                  _PokedexEditorTextField(
                    label: 'Pré-évolution',
                    description:
                        'Laissez vide si l’espèce n’a pas de pré-évolution locale.',
                    fieldKey: const Key('pokedex-pre-evolution-field'),
                    controller: _preEvolutionController,
                    enabled: !_isSaving,
                    placeholder: 'bulbasaur',
                  ),
                  const SizedBox(height: 10),
                  _PokedexEditorTextField(
                    label: 'Évolutions suivantes',
                    description:
                        'Une entrée par ligne au format targetSpeciesId|method|minLevel|itemId|requiredMoveId|conditionFr|conditionEn.',
                    fieldKey: const Key('pokedex-evolution-entries-field'),
                    controller: _entriesController,
                    enabled: !_isSaving,
                    minLines: 3,
                    maxLines: 8,
                    placeholder:
                        'ivysaur|level_up|16|||Évolue au niveau 16|Evolves at level 16',
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      CupertinoButton.filled(
                        key: const Key('pokedex-save-evolution-button'),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        onPressed: _isSaving ? null : _saveDraft,
                        child: Text(
                          _isSaving ? 'Enregistrement…' : 'Enregistrer',
                        ),
                      ),
                      const SizedBox(width: 10),
                      CupertinoButton(
                        key: const Key('pokedex-cancel-evolution-button'),
                        onPressed: _isSaving ? null : _cancelEditing,
                        child: const Text('Annuler'),
                      ),
                    ],
                  ),
                  if (_saveErrorMessage != null) ...[
                    const SizedBox(height: 10),
                    Text(
                      _saveErrorMessage!,
                      key: const Key('pokedex-evolution-save-error'),
                      style: const TextStyle(
                        color: EditorChrome.inspectorJoyCoral,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ] else ...[
            if (evolution == null)
              _PokedexMissingSection(
                key: const Key('pokedex-evolutions-missing'),
                title: 'Évolutions',
                message: evolutionRef.isEmpty
                    ? 'La ref évolution est vide dans l’espèce locale ; aucune évolution ne peut être éditée depuis cette fiche.'
                    : 'Aucune donnée d’évolution locale trouvée pour cette espèce. Vous pouvez en créer une depuis cet onglet.',
              )
            else ...[
              _PokedexDetailSectionCard(
                title: 'Pré-évolution',
                child: Text(evolution.preEvolution?.trim().isNotEmpty == true
                    ? evolution.preEvolution!
                    : 'Aucune'),
              ),
              const SizedBox(height: 12),
              _PokedexDetailSectionCard(
                title: 'Évolutions suivantes',
                child: evolution.evolutions.isEmpty
                    ? const Text('Aucune évolution déclarée.')
                    : Column(
                        children: evolution.evolutions
                            .map(
                              (entry) => _PokedexPropertyLine(
                                label: entry.targetSpeciesId,
                                value: _describeEvolution(entry),
                              ),
                            )
                            .toList(growable: false),
                      ),
              ),
            ],
            const SizedBox(height: 12),
            _PokedexDetailSectionCard(
              title: 'Édition locale',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    evolutionRef.isEmpty
                        ? 'Impossible d’éditer cette chaîne tant que la ref locale est vide.'
                        : 'La chaîne d’évolution reste limitée au contrat déjà supporté par le modèle courant.',
                  ),
                  if (evolutionRef.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    CupertinoButton(
                      key: const Key('pokedex-edit-evolution-button'),
                      padding: EdgeInsets.zero,
                      onPressed: () {
                        setState(() {
                          _replaceDraftFromDetail(widget.detail);
                          _isEditing = true;
                          _saveErrorMessage = null;
                        });
                      },
                      child: Text(
                        evolution == null ? 'Créer localement' : 'Modifier',
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
```

### `packages/map_editor/lib/src/ui/canvas/pokedex_workspace/pokedex_media_panel.dart`
```dart
part of 'pokedex_workspace_page.dart';

// Onglet Médias.
//
// Même approche que le reste du workspace : l'UI reste un reflet lisible du
// modèle existant, sans créer de pipeline parallèle pour les assets.

class _PokedexMediaTab extends StatefulWidget {
  const _PokedexMediaTab({
    required this.detail,
    required this.onSave,
  });

  final PokedexSpeciesDetail detail;
  final Future<void> Function(UpdatePokedexSpeciesMediaRequest request) onSave;

  @override
  State<_PokedexMediaTab> createState() => _PokedexMediaTabState();
}

class _PokedexMediaTabState extends State<_PokedexMediaTab> {
  late final TextEditingController _defaultFormIdController;
  late final TextEditingController _variantEntriesController;
  late final TextEditingController _animationEntriesController;
  bool _isEditing = false;
  bool _isSaving = false;
  String? _saveErrorMessage;

  @override
  void initState() {
    super.initState();
    _defaultFormIdController = TextEditingController();
    _variantEntriesController = TextEditingController();
    _animationEntriesController = TextEditingController();
    _replaceDraftFromDetail(widget.detail);
  }

  @override
  void didUpdateWidget(covariant _PokedexMediaTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.detail != widget.detail) {
      _replaceDraftFromDetail(widget.detail);
      _isEditing = false;
      _isSaving = false;
      _saveErrorMessage = null;
    }
  }

  @override
  void dispose() {
    _defaultFormIdController.dispose();
    _variantEntriesController.dispose();
    _animationEntriesController.dispose();
    super.dispose();
  }

  void _replaceDraftFromDetail(PokedexSpeciesDetail detail) {
    final media = detail.media;
    _defaultFormIdController.text = media?.defaultFormId ?? '';
    _variantEntriesController.text =
        media == null ? '' : _formatMediaVariantEntries(media.variants);
    _animationEntriesController.text =
        media == null ? '' : _formatMediaAnimationEntries(media.variants);
  }

  Future<void> _saveDraft() async {
    if (_isSaving) {
      return;
    }

    setState(() {
      _isSaving = true;
      _saveErrorMessage = null;
    });

    try {
      final variants = _parseMediaVariants(_variantEntriesController.text);
      _applyMediaAnimationEntries(
        variants,
        _animationEntriesController.text,
      );

      await widget.onSave(
        UpdatePokedexSpeciesMediaRequest(
          speciesId: widget.detail.species.id,
          defaultFormId: _defaultFormIdController.text,
          variants: variants,
        ),
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _isEditing = false;
        _isSaving = false;
        _saveErrorMessage = null;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      final message = switch (error) {
        final EditorApplicationException applicationError =>
          applicationError.message,
        _ => error.toString(),
      };
      setState(() {
        _isSaving = false;
        _saveErrorMessage = message;
      });
    }
  }

  void _cancelEditing() {
    setState(() {
      _replaceDraftFromDetail(widget.detail);
      _isEditing = false;
      _isSaving = false;
      _saveErrorMessage = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final media = widget.detail.media;
    final mediaRef = widget.detail.species.refs.media.trim();

    return SingleChildScrollView(
      key: const Key('pokedex-media-tab'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_isEditing) ...[
            _PokedexDetailSectionCard(
              title: 'Édition média locale',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _PokedexPropertyLine(
                    label: 'Ref média',
                    value: mediaRef.isEmpty ? 'Ref absente' : mediaRef,
                  ),
                  const SizedBox(height: 10),
                  _PokedexEditorTextField(
                    label: 'Forme par défaut',
                    description:
                        'La forme par défaut doit exister dans la liste des variantes.',
                    fieldKey: const Key('pokedex-media-default-form-field'),
                    controller: _defaultFormIdController,
                    enabled: !_isSaving,
                    placeholder: 'base',
                  ),
                  const SizedBox(height: 10),
                  _PokedexEditorTextField(
                    label: 'Variantes média',
                    description:
                        'Une ligne par variante : variantId|front|back|frontShiny|backShiny|icon|party|overworld|portrait|cry.',
                    fieldKey: const Key('pokedex-media-variants-field'),
                    controller: _variantEntriesController,
                    enabled: !_isSaving,
                    minLines: 4,
                    maxLines: 10,
                    placeholder:
                        'base|assets/pokemon/sprites/bulbasaur/front.png|assets/pokemon/sprites/bulbasaur/back.png|||assets/pokemon/sprites/bulbasaur/icon.png|assets/pokemon/sprites/bulbasaur/party.png||assets/pokemon/portraits/bulbasaur.png|assets/pokemon/cries/bulbasaur.ogg',
                  ),
                  const SizedBox(height: 10),
                  _PokedexEditorTextField(
                    label: 'Animations',
                    description:
                        'Une ligne par animation : variantId|animationKey|sheet|animationId.',
                    fieldKey: const Key('pokedex-media-animations-field'),
                    controller: _animationEntriesController,
                    enabled: !_isSaving,
                    minLines: 3,
                    maxLines: 8,
                    placeholder:
                        'base|battleFront|assets/pokemon/sprites/bulbasaur/battle_front_sheet.png|battle_front',
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      CupertinoButton.filled(
                        key: const Key('pokedex-save-media-button'),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        onPressed: _isSaving ? null : _saveDraft,
                        child: Text(
                          _isSaving ? 'Enregistrement…' : 'Enregistrer',
                        ),
                      ),
                      const SizedBox(width: 10),
                      CupertinoButton(
                        key: const Key('pokedex-cancel-media-button'),
                        onPressed: _isSaving ? null : _cancelEditing,
                        child: const Text('Annuler'),
                      ),
                    ],
                  ),
                  if (_saveErrorMessage != null) ...[
                    const SizedBox(height: 10),
                    Text(
                      _saveErrorMessage!,
                      key: const Key('pokedex-media-save-error'),
                      style: const TextStyle(
                        color: EditorChrome.inspectorJoyCoral,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ] else ...[
            if (media == null)
              _PokedexMissingSection(
                key: const Key('pokedex-media-missing'),
                title: 'Médias',
                message: mediaRef.isEmpty
                    ? 'La ref média est vide dans l’espèce locale ; aucun média ne peut être édité depuis cette fiche.'
                    : 'Aucune donnée média locale trouvée pour cette espèce. Vous pouvez en créer une depuis cet onglet.',
              )
            else ...[
              _PokedexDetailSectionCard(
                title: 'Variante par défaut',
                child: Column(
                  children: [
                    _PokedexPropertyLine(
                      label: 'Forme par défaut',
                      value: media.defaultFormId,
                    ),
                    _PokedexPropertyLine(
                      label: 'Variantes déclarées',
                      value: media.variants.keys.join(', '),
                    ),
                  ],
                ),
              ),
              for (final entry in media.variants.entries) ...[
                const SizedBox(height: 12),
                _PokedexDetailSectionCard(
                  title: entry.key == media.defaultFormId
                      ? 'Variante ${entry.key} (défaut)'
                      : 'Variante ${entry.key}',
                  child: Column(
                    children: [
                      _PokedexPropertyLine(
                        label: 'front',
                        value: entry.value.frontStatic ?? 'Aucun',
                      ),
                      _PokedexPropertyLine(
                        label: 'back',
                        value: entry.value.backStatic ?? 'Aucun',
                      ),
                      _PokedexPropertyLine(
                        label: 'front shiny',
                        value: entry.value.frontShinyStatic ?? 'Aucun',
                      ),
                      _PokedexPropertyLine(
                        label: 'back shiny',
                        value: entry.value.backShinyStatic ?? 'Aucun',
                      ),
                      _PokedexPropertyLine(
                        label: 'icon',
                        value: entry.value.icon ?? 'Aucun',
                      ),
                      _PokedexPropertyLine(
                        label: 'party',
                        value: entry.value.party ?? 'Aucun',
                      ),
                      _PokedexPropertyLine(
                        label: 'overworld',
                        value: entry.value.overworld ?? 'Aucun',
                      ),
                      _PokedexPropertyLine(
                        label: 'portrait',
                        value: entry.value.portrait ?? 'Aucun',
                      ),
                      _PokedexPropertyLine(
                        label: 'cry',
                        value: entry.value.cry ?? 'Aucun',
                      ),
                      _PokedexPropertyLine(
                        label: 'Animations',
                        value: entry.value.animations.isEmpty
                            ? 'Aucune animation locale déclarée.'
                            : entry.value.animations.entries
                                .map(
                                  (animation) =>
                                      '${animation.key}: ${animation.value.animationId}',
                                )
                                .join(', '),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 12),
              const _PokedexDetailSectionCard(
                title: 'Contrat média',
                child: Text(
                  'Les médias Pokémon restent de simples références locales vers assets/pokemon/... et n’utilisent jamais de GIF.',
                ),
              ),
            ],
            const SizedBox(height: 12),
            _PokedexDetailSectionCard(
              title: 'Édition locale',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    mediaRef.isEmpty
                        ? 'Impossible d’éditer ces médias tant que la ref locale est vide.'
                        : 'Les chemins restent de simples refs locales cohérentes avec le contrat média actuel.',
                  ),
                  if (mediaRef.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    CupertinoButton(
                      key: const Key('pokedex-edit-media-button'),
                      padding: EdgeInsets.zero,
                      onPressed: () {
                        setState(() {
                          _replaceDraftFromDetail(widget.detail);
                          _isEditing = true;
                          _saveErrorMessage = null;
                        });
                      },
                      child:
                          Text(media == null ? 'Créer localement' : 'Modifier'),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
```

### `packages/map_editor/lib/src/ui/canvas/pokedex_workspace/pokedex_common_widgets.dart`
```dart
part of 'pokedex_workspace_page.dart';

// Widgets de présentation transverses à plusieurs onglets.
//
// On mutualise uniquement la couche visuelle commune : cartes de section,
// lignes propriété/valeur, chips simples et messages d'absence de données.

class _LearnsetMoveSection extends StatelessWidget {
  const _LearnsetMoveSection({
    required this.title,
    required this.entries,
  });

  final String title;
  final List<PokemonLearnsetMoveEntry> entries;

  @override
  Widget build(BuildContext context) {
    return _PokedexDetailSectionCard(
      title: title,
      child: entries.isEmpty
          ? Text('Aucune entrée $title.')
          : Column(
              children: entries
                  .map(
                    (entry) => _PokedexPropertyLine(
                      label: entry.moveId,
                      value: entry.versionGroup,
                    ),
                  )
                  .toList(growable: false),
            ),
    );
  }
}

class _PokedexMissingSection extends StatelessWidget {
  const _PokedexMissingSection({
    super.key,
    required this.title,
    required this.message,
  });

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return _PokedexDetailSectionCard(
      title: title,
      child: Text(message),
    );
  }
}

class _PokedexDetailSectionCard extends StatelessWidget {
  const _PokedexDetailSectionCard({
    required this.title,
    required this.child,
  });

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final surface = Color.lerp(
      EditorChrome.islandFillElevated(context),
      CupertinoColors.black,
      0.06,
    )!;
    final border = EditorChrome.accentWarm.withValues(alpha: 0.24);
    final label = EditorChrome.primaryLabel(context);
    final subtle = EditorChrome.subtleLabel(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
        child: DefaultTextStyle(
          style: TextStyle(
            color: subtle,
            fontSize: 12,
            fontWeight: FontWeight.w600,
            height: 1.4,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: label,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 10),
              child,
            ],
          ),
        ),
      ),
    );
  }
}

class _PokedexPropertyLine extends StatelessWidget {
  const _PokedexPropertyLine({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final labelColor = EditorChrome.primaryLabel(context);
    final subtle = EditorChrome.subtleLabel(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 160,
            child: Text(
              label,
              style: TextStyle(
                color: labelColor,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: subtle,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({
    required this.label,
    required this.value,
  });

  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    final fill = EditorChrome.islandFillElevated(context);
    final labelColor = EditorChrome.primaryLabel(context);
    final subtle = EditorChrome.subtleLabel(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: EditorChrome.accentJade.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                color: subtle,
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value.toString(),
              style: TextStyle(
                color: labelColor,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FlagChip extends StatelessWidget {
  const _FlagChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final text = EditorChrome.primaryLabel(context);
    final fill = Color.lerp(
      EditorChrome.chipFill(context),
      EditorChrome.accentWarm,
      0.18,
    )!;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: EditorChrome.accentWarm.withValues(alpha: 0.35),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Text(
          label,
          style: TextStyle(
            color: text,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
```

### `packages/map_editor/lib/src/ui/canvas/pokedex_workspace/pokedex_formatters.dart`
```dart
part of 'pokedex_workspace_page.dart';

// Helpers de formatage et de parsing propres au workspace.
//
// Ces fonctions servent seulement à convertir le texte des formulaires UI vers
// les objets applicatifs déjà existants, et inversement. Elles ne remplacent pas
// les validations métier des use cases.

String _localizedValue(Map<String, String> values) {
  for (final key in const <String>['fr', 'en']) {
    final value = values[key]?.trim();
    if (value != null && value.isNotEmpty) {
      return value;
    }
  }
  return values.values.firstWhere(
    (value) => value.trim().isNotEmpty,
    orElse: () => 'Aucune valeur locale',
  );
}

List<String> _orderedLocaleKeys(Map<String, String> values) {
  final locales = values.keys
      .map((key) => key.trim())
      .where((key) => key.isNotEmpty)
      .toSet()
      .toList(growable: false);

  // On garde un ordre stable et lisible dans la UI :
  // - `fr` puis `en` si présents, car ce sont les locales déjà privilégiées
  //   ailleurs dans le Pokédex ;
  // - puis le reste en ordre alphabétique pour éviter tout mouvement arbitraire
  //   des champs entre deux rebuilds.
  locales.sort((left, right) {
    final leftPriority = switch (left) {
      'fr' => 0,
      'en' => 1,
      _ => 2,
    };
    final rightPriority = switch (right) {
      'fr' => 0,
      'en' => 1,
      _ => 2,
    };
    final priorityCompare = leftPriority.compareTo(rightPriority);
    if (priorityCompare != 0) {
      return priorityCompare;
    }
    return left.compareTo(right);
  });

  return locales;
}

List<String> _splitNonEmptyLines(String raw) {
  return LineSplitter.split(raw)
      .map((line) => line.trim())
      .where((line) => line.isNotEmpty)
      .toList(growable: false);
}

String _formatLineList(List<String> values) {
  return values.join('\n');
}

String _formatLearnsetLevelUpEntries(
  List<PokemonLearnsetLevelUpEntry> entries,
) {
  return entries
      .map(
        (entry) =>
            '${entry.moveId}|${entry.level}|${entry.source}|${entry.versionGroup}',
      )
      .join('\n');
}

String _formatLearnsetMoveEntries(List<PokemonLearnsetMoveEntry> entries) {
  return entries
      .map((entry) => '${entry.moveId}|${entry.versionGroup}')
      .join('\n');
}

List<PokemonLearnsetLevelUpEntry> _parseLearnsetLevelUpEntries(String raw) {
  final entries = <PokemonLearnsetLevelUpEntry>[];
  final lines = LineSplitter.split(raw).toList(growable: false);

  for (var index = 0; index < lines.length; index++) {
    final line = lines[index].trim();
    if (line.isEmpty) {
      continue;
    }

    final parts = line.split('|');
    if (parts.length != 4) {
      throw EditorValidationException(
        'Pokemon learnset levelUp line ${index + 1} must use moveId|level|source|versionGroup',
      );
    }

    final level = int.tryParse(parts[1].trim());
    if (level == null) {
      throw EditorValidationException(
        'Pokemon learnset levelUp line ${index + 1} level must be an integer',
      );
    }

    entries.add(
      PokemonLearnsetLevelUpEntry(
        moveId: parts[0].trim(),
        level: level,
        source: parts[2].trim(),
        versionGroup: parts[3].trim(),
      ),
    );
  }

  return entries;
}

List<PokemonLearnsetMoveEntry> _parseLearnsetMoveEntries(
  String raw, {
  required String label,
}) {
  final entries = <PokemonLearnsetMoveEntry>[];
  final lines = LineSplitter.split(raw).toList(growable: false);

  for (var index = 0; index < lines.length; index++) {
    final line = lines[index].trim();
    if (line.isEmpty) {
      continue;
    }

    final parts = line.split('|');
    if (parts.length != 2) {
      throw EditorValidationException(
        'Pokemon learnset $label line ${index + 1} must use moveId|versionGroup',
      );
    }

    entries.add(
      PokemonLearnsetMoveEntry(
        moveId: parts[0].trim(),
        versionGroup: parts[1].trim(),
      ),
    );
  }

  return entries;
}

String _formatEvolutionEntries(List<PokemonEvolutionEntry> entries) {
  return entries
      .map(
        (entry) => [
          entry.targetSpeciesId,
          entry.method,
          entry.minLevel?.toString() ?? '',
          entry.itemId ?? '',
          entry.requiredMoveId ?? '',
          entry.conditionText['fr'] ?? '',
          entry.conditionText['en'] ?? '',
        ].join('|'),
      )
      .join('\n');
}

List<PokemonEvolutionEntry> _parseEvolutionEntries(String raw) {
  final entries = <PokemonEvolutionEntry>[];
  final lines = LineSplitter.split(raw).toList(growable: false);

  for (var index = 0; index < lines.length; index++) {
    final line = lines[index].trim();
    if (line.isEmpty) {
      continue;
    }

    final parts = line.split('|');
    if (parts.length < 2 || parts.length > 7) {
      throw EditorValidationException(
        'Pokemon evolution line ${index + 1} must use targetSpeciesId|method|minLevel|itemId|requiredMoveId|conditionFr|conditionEn',
      );
    }

    while (parts.length < 7) {
      parts.add('');
    }

    final rawLevel = parts[2].trim();
    final minLevel = rawLevel.isEmpty ? null : int.tryParse(rawLevel);
    if (rawLevel.isNotEmpty && minLevel == null) {
      throw EditorValidationException(
        'Pokemon evolution line ${index + 1} minLevel must be an integer',
      );
    }

    final conditionText = <String, String>{};
    final fr = parts[5].trim();
    final en = parts[6].trim();
    if (fr.isNotEmpty) {
      conditionText['fr'] = fr;
    }
    if (en.isNotEmpty) {
      conditionText['en'] = en;
    }

    entries.add(
      PokemonEvolutionEntry(
        targetSpeciesId: parts[0].trim(),
        method: parts[1].trim(),
        minLevel: minLevel,
        itemId: _trimmedOrNull(parts[3]),
        requiredMoveId: _trimmedOrNull(parts[4]),
        conditionText: conditionText,
      ),
    );
  }

  return entries;
}

String _formatMediaVariantEntries(Map<String, PokemonMediaVariant> variants) {
  return variants.entries
      .map(
        (entry) => [
          entry.key,
          entry.value.frontStatic ?? '',
          entry.value.backStatic ?? '',
          entry.value.frontShinyStatic ?? '',
          entry.value.backShinyStatic ?? '',
          entry.value.icon ?? '',
          entry.value.party ?? '',
          entry.value.overworld ?? '',
          entry.value.portrait ?? '',
          entry.value.cry ?? '',
        ].join('|'),
      )
      .join('\n');
}

String _formatMediaAnimationEntries(Map<String, PokemonMediaVariant> variants) {
  final lines = <String>[];
  for (final entry in variants.entries) {
    for (final animation in entry.value.animations.entries) {
      lines.add(
        [
          entry.key,
          animation.key,
          animation.value.sheet,
          animation.value.animationId,
        ].join('|'),
      );
    }
  }
  return lines.join('\n');
}

Map<String, PokemonMediaVariant> _parseMediaVariants(String raw) {
  final variants = <String, PokemonMediaVariant>{};
  final lines = LineSplitter.split(raw).toList(growable: false);

  for (var index = 0; index < lines.length; index++) {
    final line = lines[index].trim();
    if (line.isEmpty) {
      continue;
    }

    final parts = line.split('|');
    if (parts.length > 10) {
      throw EditorValidationException(
        'Pokemon media variant line ${index + 1} must use variantId|front|back|frontShiny|backShiny|icon|party|overworld|portrait|cry',
      );
    }

    while (parts.length < 10) {
      parts.add('');
    }

    variants[parts[0].trim()] = PokemonMediaVariant(
      frontStatic: _trimmedOrNull(parts[1]),
      backStatic: _trimmedOrNull(parts[2]),
      frontShinyStatic: _trimmedOrNull(parts[3]),
      backShinyStatic: _trimmedOrNull(parts[4]),
      icon: _trimmedOrNull(parts[5]),
      party: _trimmedOrNull(parts[6]),
      overworld: _trimmedOrNull(parts[7]),
      portrait: _trimmedOrNull(parts[8]),
      cry: _trimmedOrNull(parts[9]),
    );
  }

  return variants;
}

void _applyMediaAnimationEntries(
  Map<String, PokemonMediaVariant> variants,
  String raw,
) {
  final lines = LineSplitter.split(raw).toList(growable: false);

  for (var index = 0; index < lines.length; index++) {
    final line = lines[index].trim();
    if (line.isEmpty) {
      continue;
    }

    final parts = line.split('|');
    if (parts.length != 4) {
      throw EditorValidationException(
        'Pokemon media animation line ${index + 1} must use variantId|animationKey|sheet|animationId',
      );
    }

    final variantId = parts[0].trim();
    if (variantId.isEmpty) {
      throw EditorValidationException(
        'Pokemon media animation line ${index + 1} variantId cannot be empty',
      );
    }

    final currentVariant = variants[variantId] ?? const PokemonMediaVariant();
    final animations = <String, PokemonMediaAnimationRef>{
      ...currentVariant.animations,
      parts[1].trim(): PokemonMediaAnimationRef(
        sheet: parts[2].trim(),
        animationId: parts[3].trim(),
      ),
    };

    variants[variantId] = PokemonMediaVariant(
      frontStatic: currentVariant.frontStatic,
      backStatic: currentVariant.backStatic,
      frontShinyStatic: currentVariant.frontShinyStatic,
      backShinyStatic: currentVariant.backShinyStatic,
      icon: currentVariant.icon,
      party: currentVariant.party,
      overworld: currentVariant.overworld,
      portrait: currentVariant.portrait,
      cry: currentVariant.cry,
      animations: animations,
    );
  }
}

String? _trimmedOrNull(String? value) {
  final trimmed = value?.trim();
  if (trimmed == null || trimmed.isEmpty) {
    return null;
  }
  return trimmed;
}

String _describeEvolution(PokemonEvolutionEntry entry) {
  final explicit = _localizedValue(entry.conditionText);
  if (explicit != 'Aucune valeur locale') {
    return explicit;
  }
  if (entry.minLevel != null) {
    return 'Évolue au niveau ${entry.minLevel}';
  }
  if (entry.itemId != null && entry.itemId!.trim().isNotEmpty) {
    return 'Évolue avec ${entry.itemId}';
  }
  if (entry.requiredMoveId != null && entry.requiredMoveId!.trim().isNotEmpty) {
    return 'Évolue avec le move ${entry.requiredMoveId}';
  }
  if (entry.method.trim().isNotEmpty) {
    return 'Méthode : ${entry.method}';
  }
  return 'Condition non précisée';
}

/// Carte de base réutilisée pour "pas de projet", "vide" et "erreur".
///
/// On mutualise uniquement la présentation visuelle commune, sans introduire un
/// système d'état générique plus large que le besoin du lot 13.
```

