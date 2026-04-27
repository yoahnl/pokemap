# Phase R1 — Lot 7 corrective pass report

## 1. Résumé exécutif honnête

Cette passe corrective n’a pas réécrit le lot 7. Elle a gardé le comportement produit livré et a ciblé le principal défaut de maintenabilité : le monolithe [`/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/ui/panels/trainer_library_panel.dart`](/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/ui/panels/trainer_library_panel.dart).

Le correctif réel est :
- découpage du panel en `part` files locaux pour garder les privates et éviter toute nouvelle stack ;
- réduction du fichier principal à un rôle d’orchestrateur lisible ;
- nettoyage local de quelques resets d’état et messages trompeurs ;
- correction d’un point d’honnêteté sur les suggestions de `forms` ;
- ajout d’un test widget ciblé pour verrouiller ce point.

Je n’ai pas rouvert le lot 7, je n’ai pas ajouté de nouvelle architecture trainer, et je n’ai pas modifié la roadmap produit parce que cette passe est un correctif de maintenabilité, pas un changement de périmètre.

## 2. État initial audité

### 2.1 Fichier principal

Le point critique était [`/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/ui/panels/trainer_library_panel.dart`](/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/ui/panels/trainer_library_panel.dart).

Constat avant correction :
- le fichier mélangeait état local du panel, chargement des références, validation inline, handlers CRUD, handlers de team, widgets de rendu, widgets d’assistance catalogue et helpers purs ;
- les dernières définitions privées commençaient après les lignes 1600, 2000 et 2300, ce qui confirmait un fichier largement au-delà de 2000 lignes ;
- le flux principal était lisible si on connaissait déjà le lot 7, mais devenait difficile à relire pour une maintenance future.

### 2.2 Frontières métier / UI

Audit de [`/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/features/editor/state/editor_notifier.dart`](/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/features/editor/state/editor_notifier.dart) :
- les méthodes trainers restent des orchestrateurs ;
- elles délèguent aux use cases ;
- elles ne portent pas de logique métier trainer secondaire ;
- je n’ai donc pas ajouté de churn artificiel.

Audit de [`/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/application/use_cases/trainer_use_cases.dart`](/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/application/use_cases/trainer_use_cases.dart) :
- la normalisation existante (`trim`, suppression des vides, validation élémentaire) reste de la logique applicative défendable ;
- je n’ai pas détecté de fuite UI claire qui justifiait une correction locale sûre ;
- je l’ai donc laissé intact pour éviter un faux refactor.

### 2.3 Forms

Le support `forms` était globalement honnête :
- la saisie brute restait possible ;
- la validation ne bloquait que quand des suggestions locales existaient réellement.

Le petit défaut repéré était plus subtil :
- `_buildSpeciesFormSuggestions(...)` injectait un `base` synthétique si `formId` était vide ;
- cela pouvait faire croire qu’une forme locale explicite existait alors que la donnée ne la fournissait pas.

C’est le seul point `forms` que j’ai corrigé.

## 3. Problèmes traités

### 3.1 Réduction massive du monolithe UI

J’ai extrait les blocs suivants en fichiers voisins :
- support local du panel ;
- widgets trainer ;
- widgets Pokémon / assistance catalogue.

Le fichier principal reste maintenant l’orchestrateur :
- état local ;
- chargement des références ;
- handlers create/update/delete ;
- handlers add/update/delete Pokémon ;
- construction du flux principal.

### 3.2 Nettoyage des resets locaux

J’ai réduit deux duplications locales :
- reset du draft Pokémon centralisé dans `_resetPokemonDraftFields()` ;
- fermeture de l’éditeur trainer centralisée dans `_closeTrainerEditor()`.

Cela évite que les branches `add/edit/cancel/delete` divergent silencieusement à la prochaine évolution du panel.

### 3.3 Messages plus honnêtes

Ajustements ciblés :
- le trainer sans équipe n’est plus présenté comme une quasi-erreur rouge ;
- le message d’aide explique maintenant qu’on peut sauvegarder puis compléter la team plus tard ;
- le texte sur les refs optionnelles trainer précise que seul le portrait est vérifié localement, pas `battleTheme`, `victoryTheme` ni `tags`.

### 3.4 Support forms plus honnête

Correction :
- plus de suggestion `base` inventée quand l’espèce locale ne fournit aucune forme explicite ;
- message explicite : aucune suggestion locale, saisie brute toujours possible ;
- test ajouté pour verrouiller ce comportement.

## 4. Problèmes volontairement non traités

Je ne les ai pas traités parce que cela aurait rouvert le lot au-delà du correctif local :
- pas de migration de la validation inline trainer vers un validateur applicatif dédié ;
- pas de nouveau store/notifier trainer ;
- pas d’extraction d’un widget `TrainerCard` public ou d’un mini-framework de formulaire ;
- pas de changement du lot 6 au-delà de l’usage existant du lookup local ;
- pas d’harmonisation globale de toute la copy anglais/français dans `map_editor`.

## 5. Décisions d’architecture

### 5.1 Découpage choisi

J’ai choisi des `part` files, pas de nouveaux widgets publics ni de nouvelle couche :
- [`/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/ui/panels/trainer_library_panel_support.dart`](/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/ui/panels/trainer_library_panel_support.dart)
- [`/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/ui/panels/trainer_library_panel_trainer_widgets.dart`](/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/ui/panels/trainer_library_panel_trainer_widgets.dart)
- [`/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/ui/panels/trainer_library_panel_pokemon_widgets.dart`](/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/ui/panels/trainer_library_panel_pokemon_widgets.dart)

Pourquoi :
- garde les identifiants privés ;
- garde la bibliothèque trainer comme unité locale ;
- évite de propager un nouveau contrat à travers le repo ;
- donne un gros gain de lisibilité sans toucher au comportement produit.

### 5.2 Ce que j’ai délibérément laissé dans le fichier principal

Je n’ai pas extrait hors du panel principal :
- le stateful shell ;
- les handlers create/update/delete trainer ;
- les handlers add/update/delete Pokémon ;
- le chargement des références locales ;
- la validation inline locale du draft.

Raison : ce sont les véritables points d’orchestration du flux ; les sortir aurait commencé à créer une architecture trainer supplémentaire.

## 6. Liste exacte des fichiers modifiés / créés / supprimés

### Fichiers modifiés
- `/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/ui/panels/trainer_library_panel.dart`
- `/Users/karim/Project/pokemonProject/packages/map_editor/test/trainer_library_panel_test.dart`

### Fichiers créés
- `/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/ui/panels/trainer_library_panel_support.dart`
- `/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/ui/panels/trainer_library_panel_trainer_widgets.dart`
- `/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/ui/panels/trainer_library_panel_pokemon_widgets.dart`

### Fichiers supprimés
- aucun

## 7. Justification fichier par fichier

### `/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/ui/panels/trainer_library_panel.dart`
- redevient le fichier orchestrateur ;
- garde les handlers et l’état ;
- gagne des helpers de reset locaux plus lisibles ;
- enlève le bruit des gros widgets privés.

### `/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/ui/panels/trainer_library_panel_support.dart`
- regroupe les types privés et helpers purs ;
- contient la correction d’honnêteté des suggestions de `forms` ;
- évite de laisser ces helpers noyés en bas du panel principal.

### `/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/ui/panels/trainer_library_panel_trainer_widgets.dart`
- isole la surface trainer CRUD / optional refs / banners ;
- améliore la lisibilité du flux principal ;
- clarifie les messages sur les refs optionnelles.

### `/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/ui/panels/trainer_library_panel_pokemon_widgets.dart`
- isole la partie la plus volumineuse du lot 7 ;
- garde toute l’assistance `species/moves/items/forms` au même endroit ;
- ajoute des commentaires pour rappeler que l’assist field reste un widget local, pas une plateforme de recherche générique.

### `/Users/karim/Project/pokemonProject/packages/map_editor/test/trainer_library_panel_test.dart`
- conserve les tests lot 7 existants ;
- ajoute un test ciblé sur l’honnêteté du support `forms` ;
- adapte le helper `_buildDetail(...)` pour rendre ce scénario testable sans créer un faux infra layer.

## 8. Sub-agents utilisés, conclusions, retenu / rejeté

Le plafond de threads empêchait de créer de nouveaux agents. J’ai donc réutilisé honnêtement les reviewers existants.

### Reviewer A — architecture / scope
Conclusion :
- extraire `_TrainerPokemonEditorCard` et `_TrainerEditorCard` était le plus rentable ;
- garder le shell stateful, l’orchestration async et les handlers dans le fichier principal ;
- surtout ne pas créer une nouvelle stack trainer.

Retenu :
- découpage local en morceaux UI voisins.

Rejeté :
- nouvelle couche trainer dédiée ;
- généralisation supplémentaire du lot 6.

### Reviewer B — UI / maintainability
Conclusion :
- le vrai problème est le mélange de trois flux : trainer CRUD, refs locales, draft Pokémon ;
- attention aux messages trompeurs sur trainer sans équipe et refs optionnelles.

Retenu :
- extraction des gros widgets ;
- amélioration de deux messages ;
- conservation du flux principal dans le panel orchestrateur.

Rejeté :
- extraction de tout l’état du panel dans un controller séparé.

### Reviewer C — domain boundary
Conclusion :
- `EditorNotifier` reste acceptable comme orchestrateur ;
- `trainer_use_cases.dart` reste globalement propre ;
- la validation inline existe dans l’UI, mais une migration applicative complète sortirait du scope du correctif.

Retenu :
- audit + conservation de `EditorNotifier` et des use cases tels quels ;
- correction locale seulement côté panel.

Rejeté :
- nouveau validateur applicatif dédié dans cette passe.

### Reviewer D — contradicteur anti-sur-ingénierie
Conclusion :
- rejeter toute “trainers v2” déguisée ;
- corriger seulement ce qui améliore réellement le lot 7.

Retenu :
- `part` files locaux ;
- zéro nouveau provider / store / framework.

Rejeté :
- toute plateforme “trainer catalog” ou framework de formulaire.

### Reviewer E — tests
Conclusion :
- priorité à `trainer_library_panel_test.dart`, `trainer_use_cases_test.dart`, et aux lookups lot 5/6 ;
- un smoke lot 4 est utile pour prouver l’absence de casse transversale ;
- les items n’avaient pas besoin d’une nouvelle abstraction pour cette passe.

Retenu :
- matrice ciblée lot 7 + non-régressions lot 5/6 + smoke lot 4 ;
- ajout d’un test forms ciblé.

Rejeté :
- grosse avalanche de tests décoratifs.

## 9. Commandes réellement exécutées

### Audit
```bash
find /Users/karim/Project/pokemonProject -name AGENTS.md -print
rg -n "^(class|final class|typedef|enum|extension)|^_[A-Za-z].*\(" /Users/karim/Project/pokemonProject/packages/map_editor/lib/src/ui/panels/trainer_library_panel.dart
sed -n '1,240p' /Users/karim/Project/pokemonProject/packages/map_editor/lib/src/ui/panels/trainer_library_panel.dart
sed -n '240,520p' /Users/karim/Project/pokemonProject/packages/map_editor/lib/src/ui/panels/trainer_library_panel.dart
sed -n '520,820p' /Users/karim/Project/pokemonProject/packages/map_editor/lib/src/ui/panels/trainer_library_panel.dart
sed -n '820,1125p' /Users/karim/Project/pokemonProject/packages/map_editor/lib/src/ui/panels/trainer_library_panel.dart
sed -n '1126,1617p' /Users/karim/Project/pokemonProject/packages/map_editor/lib/src/ui/panels/trainer_library_panel.dart
sed -n '1618,2096p' /Users/karim/Project/pokemonProject/packages/map_editor/lib/src/ui/panels/trainer_library_panel.dart
sed -n '2097,2525p' /Users/karim/Project/pokemonProject/packages/map_editor/lib/src/ui/panels/trainer_library_panel.dart
sed -n '5920,6155p' /Users/karim/Project/pokemonProject/packages/map_editor/lib/src/features/editor/state/editor_notifier.dart
sed -n '1,260p' /Users/karim/Project/pokemonProject/packages/map_editor/lib/src/application/use_cases/trainer_use_cases.dart
sed -n '1,260p' /Users/karim/Project/pokemonProject/packages/map_editor/test/trainer_library_panel_test.dart
sed -n '260,460p' /Users/karim/Project/pokemonProject/packages/map_editor/test/trainer_library_panel_test.dart
```

### Validation
```bash
dart format /Users/karim/Project/pokemonProject/packages/map_editor/lib/src/ui/panels/trainer_library_panel.dart /Users/karim/Project/pokemonProject/packages/map_editor/lib/src/ui/panels/trainer_library_panel_support.dart /Users/karim/Project/pokemonProject/packages/map_editor/lib/src/ui/panels/trainer_library_panel_trainer_widgets.dart /Users/karim/Project/pokemonProject/packages/map_editor/lib/src/ui/panels/trainer_library_panel_pokemon_widgets.dart /Users/karim/Project/pokemonProject/packages/map_editor/test/trainer_library_panel_test.dart
flutter analyze --no-pub lib/src/ui/panels/trainer_library_panel.dart lib/src/ui/panels/trainer_library_panel_support.dart lib/src/ui/panels/trainer_library_panel_trainer_widgets.dart lib/src/ui/panels/trainer_library_panel_pokemon_widgets.dart test/trainer_library_panel_test.dart
flutter test test/trainer_use_cases_test.dart test/trainer_library_panel_test.dart test/provider_wiring_test.dart test/pokemon_species_lookup_service_test.dart test/load_pokemon_items_catalog_use_case_test.dart test/local_catalog_lookup_service_test.dart test/pokemon_moves_catalog_lookup_service_test.dart test/pokedex_learnset_moves_assist_ui_test.dart test/pokedex_external_batch_execute_ui_test.dart
```

### État git
```bash
git status --short
git diff --stat
git ls-files --others --exclude-standard
```

## 10. Résultats réels

### Format
```text
Formatted 5 files (0 changed) in 0.03 seconds.
Formatted 5 files (0 changed) in 0.02 seconds.
```

### Analyze
```text
No issues found! (ran in 1.8s)
```

### Tests
```text
00:05 +29: All tests passed!
```

## 11. Incidents rencontrés

Incident mineur :
- le premier `flutter analyze` a remonté uniquement des `prefer_const_constructors` sur le panel et le helper de test ;
- correction immédiate ;
- pas d’incident fonctionnel, pas de régression comportementale détectée.

## 12. État git utile

### `git status --short`
```text
 M packages/map_editor/lib/src/ui/panels/trainer_library_panel.dart
 M packages/map_editor/test/trainer_library_panel_test.dart
?? packages/map_editor/lib/src/ui/panels/trainer_library_panel_pokemon_widgets.dart
?? packages/map_editor/lib/src/ui/panels/trainer_library_panel_support.dart
?? packages/map_editor/lib/src/ui/panels/trainer_library_panel_trainer_widgets.dart
```

### `git diff --stat`
```text
 .../lib/src/ui/panels/trainer_library_panel.dart   | 1441 +-------------------
 .../test/trainer_library_panel_test.dart           |  137 +-
 2 files changed, 151 insertions(+), 1427 deletions(-)
```

### `git ls-files --others --exclude-standard`
```text
packages/map_editor/lib/src/ui/panels/trainer_library_panel_pokemon_widgets.dart
packages/map_editor/lib/src/ui/panels/trainer_library_panel_support.dart
packages/map_editor/lib/src/ui/panels/trainer_library_panel_trainer_widgets.dart
```

Note : `git diff --stat` n’affiche ici que les fichiers déjà suivis. Les trois nouveaux fichiers apparaissent bien dans `git status` et `git ls-files --others --exclude-standard`.

## 13. Checklist finale

- [x] je n’ai pas créé de stack parallèle
- [x] je n’ai pas réécrit 11A / 11B / lots 1 à 6
- [x] je n’ai pas ajouté de provider/use case/repository artificiel
- [x] j’ai gardé cette passe corrective bornée
- [x] `trainer_library_panel.dart` est significativement plus petit et plus lisible
- [x] le comportement produit du lot 7 est conservé
- [x] `EditorNotifier` a été audité et laissé orchestrateur
- [x] `trainer_use_cases.dart` a été audité et laissé métier
- [x] le support `forms` est plus honnête
- [x] les messages les plus trompeurs ont été corrigés localement
- [x] le lot 5 n’est pas cassé
- [x] `dart format` a été exécuté
- [x] `flutter analyze --no-pub` a été exécuté
- [x] les tests ciblés et non-régressions utiles ont été exécutés
- [x] aucun commit git n’a été fait
- [x] aucun merge / rebase / push / tag / stash / amend / reset n’a été fait
- [x] le report markdown a bien été créé
- [x] l’annexe contient tous les fichiers texte modifiés / créés

## 14. Conclusion honnête

Oui, cette passe corrective améliore réellement le lot 7.

Ce qui a été réellement amélioré :
- lisibilité du flux principal ;
- taille du fichier principal ;
- séparation locale des responsabilités UI ;
- honnêteté du support `forms` ;
- quelques messages de validation / guidance.

Dette locale encore acceptable :
- le panel principal reste un orchestrateur conséquent, même s’il n’est plus monolithique ;
- la validation inline trainer reste partiellement dans la couche UI ;
- la copy du panneau n’est pas encore uniformisée globalement.

Je considère que le lot 7 correctif est terminé dans son scope.

## 15. Annexe — contenu complet des fichiers touchés

Note explicite : le report ne se recopie pas lui-même intégralement dans cette annexe pour éviter une récursion infinie.

### `/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/ui/panels/trainer_library_panel.dart`

```dart
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:macos_ui/macos_ui.dart';
import 'package:map_core/map_core.dart';

import '../../app/providers/core/repository_providers.dart';
import '../../app/providers/pokedex/pokedex_providers.dart';
import '../../application/models/pokedex_species_detail.dart';
import '../../application/models/pokemon_database_index.dart';
import '../../application/models/pokemon_project_data_models.dart';
import '../../application/ports/project_workspace.dart';
import '../../application/services/local_catalog_lookup_service.dart';
import '../../application/services/pokemon_items_catalog_lookup_service.dart';
import '../../application/services/pokemon_moves_catalog_lookup_service.dart';
import '../../application/services/pokemon_species_lookup_service.dart';
import '../../application/use_cases/load_pokemon_items_catalog_use_case.dart';
import '../../application/use_cases/sync_pokemon_moves_catalog_use_case.dart';
import '../../features/editor/state/editor_notifier.dart';
import '../../features/editor/state/editor_state.dart';
import '../shared/cupertino_editor_widgets.dart';
import '../shared/inspector_embedded_widgets.dart';

// Keep the trainer library in one Dart library so we can split the corrective
// pass into neighboring `part` files without changing visibility or adding a
// new trainer-specific architecture.
part 'trainer_library_panel_support.dart';
part 'trainer_library_panel_trainer_widgets.dart';
part 'trainer_library_panel_pokemon_widgets.dart';

const PokemonSpeciesLookupService _speciesLookupService =
    PokemonSpeciesLookupService();
const PokemonMovesCatalogLookupService _movesLookupService =
    PokemonMovesCatalogLookupService();
const PokemonItemsCatalogLookupService _itemsLookupService =
    PokemonItemsCatalogLookupService();
const List<String> _trainerQuickGenderValues = <String>[
  'male',
  'female',
  'any',
];

class TrainerLibraryPanel extends ConsumerStatefulWidget {
  const TrainerLibraryPanel({
    super.key,
    this.embedded = false,
  });

  final bool embedded;

  @override
  ConsumerState<TrainerLibraryPanel> createState() =>
      _TrainerLibraryPanelState();
}

class _TrainerLibraryPanelState extends ConsumerState<TrainerLibraryPanel> {
  // -------------------------------------------------------------------------
  // Formulaire de création d'un trainer
  // -------------------------------------------------------------------------

  final _newNameController = TextEditingController();
  final _newClassController = TextEditingController();
  final _newPortraitController = TextEditingController();
  final _newBattleThemeController = TextEditingController();
  final _newVictoryThemeController = TextEditingController();
  final _newTagsController = TextEditingController();
  String? _newCharacterId;
  bool _showCreateForm = false;
  bool _showCreateAdvanced = false;
  String? _createTrainerValidationMessage;

  // -------------------------------------------------------------------------
  // Formulaire d'édition du trainer sélectionné
  // -------------------------------------------------------------------------

  String? _editingTrainerId;
  final _editNameController = TextEditingController();
  final _editClassController = TextEditingController();
  final _editPortraitController = TextEditingController();
  final _editBattleThemeController = TextEditingController();
  final _editVictoryThemeController = TextEditingController();
  final _editTagsController = TextEditingController();
  String? _editCharacterId;
  bool _showEditAdvanced = false;
  String? _editTrainerValidationMessage;

  // -------------------------------------------------------------------------
  // Draft partagé pour ajout / édition d'un Pokémon de team
  // -------------------------------------------------------------------------

  String? _activePokemonTrainerId;
  int? _editingPokemonIndex;
  final _pokemonSpeciesController = TextEditingController();
  final _pokemonLevelController = TextEditingController(text: '1');
  final _pokemonItemController = TextEditingController();
  final _pokemonFormController = TextEditingController();
  final _pokemonGenderController = TextEditingController();
  late final List<TextEditingController> _pokemonMoveControllers =
      List<TextEditingController>.generate(
    4,
    (_) => TextEditingController(),
  );
  bool _pokemonShiny = false;
  String? _pokemonValidationMessage;

  // -------------------------------------------------------------------------
  // Références locales réutilisées par la surface auteur
  // -------------------------------------------------------------------------

  String? _referenceProjectRootPath;
  Future<_TrainerReferenceData>? _referenceDataFuture;
  final Map<String, Future<PokedexSpeciesDetail?>> _speciesDetailFutureCache =
      <String, Future<PokedexSpeciesDetail?>>{};

  @override
  void dispose() {
    _newNameController.dispose();
    _newClassController.dispose();
    _newPortraitController.dispose();
    _newBattleThemeController.dispose();
    _newVictoryThemeController.dispose();
    _newTagsController.dispose();

    _editNameController.dispose();
    _editClassController.dispose();
    _editPortraitController.dispose();
    _editBattleThemeController.dispose();
    _editVictoryThemeController.dispose();
    _editTagsController.dispose();

    _pokemonSpeciesController.dispose();
    _pokemonLevelController.dispose();
    _pokemonItemController.dispose();
    _pokemonFormController.dispose();
    _pokemonGenderController.dispose();
    for (final controller in _pokemonMoveControllers) {
      controller.dispose();
    }

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(editorNotifierProvider);
    final notifier = ref.read(editorNotifierProvider.notifier);
    final project = state.project;

    _ensureReferenceDataForState(state);

    final subtle = CupertinoColors.secondaryLabel.resolveFrom(context);
    const accent = EditorChrome.accentCoral;

    final content = project == null
        ? Center(
            child: Text(
              'No project loaded',
              style: TextStyle(
                color: CupertinoColors.placeholderText.resolveFrom(context),
              ),
            ),
          )
        : FutureBuilder<_TrainerReferenceData>(
            future: _referenceDataFuture,
            initialData: const _TrainerReferenceData.loading(),
            builder: (context, snapshot) {
              final references =
                  snapshot.data ?? const _TrainerReferenceData.loading();
              return ListView(
                padding: widget.embedded
                    ? kInspectorTileBodyPadding
                    : const EdgeInsets.fromLTRB(8, 8, 8, 8),
                children: [
                  _TrainerReferencesBanner(
                    references: references,
                    onRefresh: () => _refreshReferenceData(state),
                  ),
                  if ((state.errorMessage ?? '').trim().isNotEmpty ||
                      (state.statusMessage ?? '').trim().isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 8, bottom: 8),
                      child: _TrainerOperationBanner(
                        message:
                            (state.errorMessage?.trim().isNotEmpty ?? false)
                                ? state.errorMessage!.trim()
                                : state.statusMessage!.trim(),
                        isError:
                            (state.errorMessage?.trim().isNotEmpty ?? false),
                      ),
                    ),
                  if (!_showCreateForm)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: CupertinoButton.filled(
                        key: const Key('trainer-library-new-trainer-button'),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        minimumSize: const Size(1, 28),
                        onPressed: () => setState(() {
                          _showCreateForm = true;
                          _createTrainerValidationMessage = null;
                          _editingTrainerId = null;
                          _closePokemonEditor();
                        }),
                        child: const Text(
                          'New Trainer',
                          style: TextStyle(fontSize: 13),
                        ),
                      ),
                    )
                  else
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: _TrainerEditorCard(
                        key: const Key('trainer-library-create-card'),
                        title: 'NEW TRAINER',
                        accent: accent,
                        nameController: _newNameController,
                        classController: _newClassController,
                        portraitController: _newPortraitController,
                        battleThemeController: _newBattleThemeController,
                        victoryThemeController: _newVictoryThemeController,
                        tagsController: _newTagsController,
                        characters: project.characters,
                        elements: project.elements,
                        selectedCharacterId: _newCharacterId,
                        validationMessage: _createTrainerValidationMessage,
                        showAdvanced: _showCreateAdvanced,
                        createMode: true,
                        onToggleAdvanced: () => setState(() {
                          _showCreateAdvanced = !_showCreateAdvanced;
                        }),
                        onSelectCharacter: (characterId) => setState(() {
                          _newCharacterId = characterId;
                        }),
                        onCancel: () => setState(_resetCreateTrainerDraft),
                        onSubmit: () => _handleCreateTrainer(
                          notifier: notifier,
                          project: project,
                        ),
                      ),
                    ),
                  if (project.trainers.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Center(
                        child: Text(
                          'No trainers yet',
                          style: TextStyle(color: subtle, fontSize: 13),
                        ),
                      ),
                    ),
                  for (final trainer in project.trainers)
                    _buildTrainerTile(
                      context: context,
                      trainer: trainer,
                      project: project,
                      notifier: notifier,
                      references: references,
                      accent: accent,
                    ),
                ],
              );
            },
          );

    if (widget.embedded) {
      return content;
    }
    return ColoredBox(
      color: EditorChrome.largeIslandSurfaceColor(context),
      child: content,
    );
  }

  // -------------------------------------------------------------------------
  // Chargement des références locales
  // -------------------------------------------------------------------------

  void _ensureReferenceDataForState(EditorState state) {
    final projectRootPath = state.projectRootPath?.trim();
    if (_referenceProjectRootPath == projectRootPath &&
        _referenceDataFuture != null) {
      return;
    }

    _referenceProjectRootPath = projectRootPath;
    _speciesDetailFutureCache.clear();

    final workspace = _workspaceForState(state);
    _referenceDataFuture = workspace == null
        ? Future<_TrainerReferenceData>.value(
            const _TrainerReferenceData.unavailable(),
          )
        : _loadReferenceData(workspace);
  }

  Future<void> _refreshReferenceData(EditorState state) async {
    final workspace = _workspaceForState(state);
    if (workspace == null) {
      return;
    }

    setState(() {
      _speciesDetailFutureCache.clear();
      _referenceDataFuture = _loadReferenceData(workspace);
    });
  }

  ProjectWorkspace? _workspaceForState(EditorState state) {
    final projectRootPath = state.projectRootPath?.trim();
    if (projectRootPath == null || projectRootPath.isEmpty) {
      return null;
    }
    return ref.read(projectWorkspaceFactoryProvider).create(projectRootPath);
  }

  Future<_TrainerReferenceData> _loadReferenceData(
    ProjectWorkspace workspace,
  ) async {
    final speciesLoader = ref.read(pokedexEntryLoaderProvider);
    final movesLoader = ref.read(pokedexMovesCatalogLoaderProvider);
    final itemsLoader = ref.read(loadPokemonItemsCatalogUseCaseProvider);

    List<PokemonDatabaseIndexEntry> speciesEntries = const [];
    String speciesMessage =
        'Aucune espèce locale disponible. La saisie brute reste possible.';
    var isSpeciesAvailable = false;

    try {
      speciesEntries = await speciesLoader(workspace);
      isSpeciesAvailable = speciesEntries.isNotEmpty;
      speciesMessage = speciesEntries.isEmpty
          ? 'Aucune espèce locale n’a encore été indexée. La saisie brute reste possible.'
          : 'Recherche locale active sur ${speciesEntries.length} espèces du projet.';
    } catch (error) {
      speciesMessage =
          'Impossible de charger les espèces locales. La saisie brute reste possible.\n$error';
    }

    final movesCatalogView = await movesLoader(workspace);
    final itemsCatalogView = await itemsLoader.execute(workspace);

    return _TrainerReferenceData(
      speciesEntries: speciesEntries,
      isSpeciesAvailable: isSpeciesAvailable,
      speciesMessage: speciesMessage,
      movesCatalogView: movesCatalogView,
      itemsCatalogView: itemsCatalogView,
    );
  }

  Future<PokedexSpeciesDetail?> _loadSpeciesDetailIfPossible(
    ProjectWorkspace workspace,
    String rawSpeciesId,
  ) {
    final speciesId = rawSpeciesId.trim();
    if (speciesId.isEmpty) {
      return Future<PokedexSpeciesDetail?>.value(null);
    }

    final existingFuture = _speciesDetailFutureCache[speciesId];
    if (existingFuture != null) {
      return existingFuture;
    }

    final loader = ref.read(pokedexSpeciesDetailLoaderProvider);
    final future = loader(workspace, speciesId)
        .then<PokedexSpeciesDetail?>((detail) => detail)
        .catchError((_) => null);
    _speciesDetailFutureCache[speciesId] = future;
    return future;
  }

  // -------------------------------------------------------------------------
  // Trainer CRUD
  // -------------------------------------------------------------------------

  Future<void> _handleCreateTrainer({
    required EditorNotifier notifier,
    required ProjectManifest project,
  }) async {
    final validation = _validateTrainerDraft(
      project: project,
      name: _newNameController.text,
      trainerClass: _newClassController.text,
      portraitElementId: _newPortraitController.text,
    );
    setState(() {
      _createTrainerValidationMessage = validation;
    });
    if (validation != null) {
      return;
    }

    final success = await notifier.createTrainer(
      name: _newNameController.text,
      trainerClass: _newClassController.text,
      characterId: _newCharacterId,
      portraitElementId: _newPortraitController.text,
      battleThemeId: _newBattleThemeController.text,
      victoryThemeId: _newVictoryThemeController.text,
      tags: _splitCommaSeparatedValues(_newTagsController.text),
    );
    if (!mounted) {
      return;
    }

    if (success) {
      setState(_resetCreateTrainerDraft);
      return;
    }

    setState(() {
      _createTrainerValidationMessage =
          ref.read(editorNotifierProvider).errorMessage ??
              'Failed to create trainer.';
    });
  }

  Future<void> _handleUpdateTrainer({
    required EditorNotifier notifier,
    required ProjectManifest project,
    required ProjectTrainerEntry trainer,
  }) async {
    final validation = _validateTrainerDraft(
      project: project,
      name: _editNameController.text,
      trainerClass: _editClassController.text,
      portraitElementId: _editPortraitController.text,
    );
    setState(() {
      _editTrainerValidationMessage = validation;
    });
    if (validation != null) {
      return;
    }

    final success = await notifier.updateTrainer(
      trainerId: trainer.id,
      name: _editNameController.text,
      trainerClass: _editClassController.text,
      characterId: _editCharacterId,
      portraitElementId: _editPortraitController.text,
      battleThemeId: _editBattleThemeController.text,
      victoryThemeId: _editVictoryThemeController.text,
      tags: _splitCommaSeparatedValues(_editTagsController.text),
    );
    if (!mounted) {
      return;
    }

    if (success) {
      setState(_closeTrainerEditor);
      return;
    }

    setState(() {
      _editTrainerValidationMessage =
          ref.read(editorNotifierProvider).errorMessage ??
              'Failed to update trainer.';
    });
  }

  Future<void> _handleDeleteTrainer({
    required EditorNotifier notifier,
    required ProjectTrainerEntry trainer,
  }) async {
    final success = await notifier.deleteTrainer(trainer.id);
    if (!mounted || !success) {
      return;
    }
    setState(() {
      if (_editingTrainerId == trainer.id) {
        _closeTrainerEditor();
      }
      if (_activePokemonTrainerId == trainer.id) {
        _closePokemonEditor();
      }
    });
  }

  String? _validateTrainerDraft({
    required ProjectManifest project,
    required String name,
    required String trainerClass,
    required String portraitElementId,
  }) {
    if (name.trim().isEmpty) {
      return 'Trainer name cannot be empty.';
    }
    if (trainerClass.trim().isEmpty) {
      return 'Trainer class cannot be empty.';
    }

    final portraitId = portraitElementId.trim();
    if (portraitId.isNotEmpty &&
        !project.elements.any((element) => element.id == portraitId)) {
      return 'Portrait element "$portraitId" does not exist in this project.';
    }

    return null;
  }

  void _resetCreateTrainerDraft() {
    _showCreateForm = false;
    _showCreateAdvanced = false;
    _createTrainerValidationMessage = null;
    _newNameController.clear();
    _newClassController.clear();
    _newPortraitController.clear();
    _newBattleThemeController.clear();
    _newVictoryThemeController.clear();
    _newTagsController.clear();
    _newCharacterId = null;
  }

  void _startEditingTrainer(ProjectTrainerEntry trainer) {
    setState(() {
      _editingTrainerId = trainer.id;
      _editNameController.text = trainer.name;
      _editClassController.text = trainer.trainerClass;
      _editPortraitController.text = trainer.portraitElementId ?? '';
      _editBattleThemeController.text = trainer.battleThemeId ?? '';
      _editVictoryThemeController.text = trainer.victoryThemeId ?? '';
      _editTagsController.text = trainer.tags.join(', ');
      _editCharacterId = trainer.characterId;
      _showEditAdvanced = false;
      _editTrainerValidationMessage = null;
      _showCreateForm = false;
      _closePokemonEditor();
    });
  }

  // -------------------------------------------------------------------------
  // Draft Pokémon team
  // -------------------------------------------------------------------------

  bool get _isAddingPokemon =>
      _activePokemonTrainerId != null && _editingPokemonIndex == null;

  bool _isEditingPokemon(
    String trainerId,
    int pokemonIndex,
  ) {
    return _activePokemonTrainerId == trainerId &&
        _editingPokemonIndex == pokemonIndex;
  }

  void _closePokemonEditor() {
    _activePokemonTrainerId = null;
    _editingPokemonIndex = null;
    _resetPokemonDraftFields();
  }

  // Keeping the shared Pokémon draft reset in one place avoids tiny
  // field-reset mismatches between add/edit/cancel flows.
  void _resetPokemonDraftFields() {
    _pokemonValidationMessage = null;
    _pokemonSpeciesController.clear();
    _pokemonLevelController.text = '1';
    _pokemonItemController.clear();
    _pokemonFormController.clear();
    _pokemonGenderController.clear();
    _clearTextControllers(_pokemonMoveControllers);
    _pokemonShiny = false;
  }

  void _startAddingPokemon(String trainerId) {
    setState(() {
      _activePokemonTrainerId = trainerId;
      _editingPokemonIndex = null;
      _resetPokemonDraftFields();
      _closeTrainerEditor();
      _showCreateForm = false;
    });
  }

  void _startEditingPokemon(
    String trainerId,
    int pokemonIndex,
    ProjectTrainerPokemonEntry pokemon,
  ) {
    setState(() {
      _activePokemonTrainerId = trainerId;
      _editingPokemonIndex = pokemonIndex;
      _pokemonValidationMessage = null;
      _pokemonSpeciesController.text = pokemon.speciesId;
      _pokemonLevelController.text = pokemon.level.toString();
      _pokemonItemController.text = pokemon.heldItemId ?? '';
      _pokemonFormController.text = pokemon.formId ?? '';
      _pokemonGenderController.text = pokemon.gender ?? '';
      for (var i = 0; i < _pokemonMoveControllers.length; i++) {
        _pokemonMoveControllers[i].text =
            i < pokemon.moves.length ? pokemon.moves[i] : '';
      }
      _pokemonShiny = pokemon.shiny;
      _closeTrainerEditor();
      _showCreateForm = false;
    });
  }

  Future<void> _handleSavePokemonDraft({
    required EditorNotifier notifier,
    required ProjectWorkspace workspace,
    required _TrainerReferenceData references,
  }) async {
    final trainerId = _activePokemonTrainerId;
    if (trainerId == null) {
      return;
    }

    final speciesDetail = await _loadSpeciesDetailIfPossible(
        workspace, _pokemonSpeciesController.text);
    final validation = _validatePokemonDraft(
      references: references,
      speciesDetail: speciesDetail,
    );
    if (!mounted) {
      return;
    }

    setState(() {
      _pokemonValidationMessage = validation;
    });
    if (validation != null) {
      return;
    }

    final draft = _buildPokemonDraft();
    if (draft.level == null) {
      setState(() {
        _pokemonValidationMessage = 'Level must be a positive integer.';
      });
      return;
    }

    final success = _editingPokemonIndex == null
        ? await notifier.addTrainerPokemon(
            trainerId: trainerId,
            speciesId: draft.speciesId,
            level: draft.level!,
            moves: draft.moves,
            heldItemId: draft.heldItemId,
            formId: draft.formId,
            gender: draft.gender,
            shiny: draft.shiny,
          )
        : await notifier.updateTrainerPokemon(
            trainerId: trainerId,
            pokemonIndex: _editingPokemonIndex!,
            speciesId: draft.speciesId,
            level: draft.level!,
            moves: draft.moves,
            heldItemId: draft.heldItemId,
            formId: draft.formId,
            gender: draft.gender,
            shiny: draft.shiny,
          );
    if (!mounted) {
      return;
    }

    if (success) {
      setState(_closePokemonEditor);
      return;
    }

    setState(() {
      _pokemonValidationMessage =
          ref.read(editorNotifierProvider).errorMessage ??
              'Failed to save trainer Pokémon.';
    });
  }

  Future<void> _handleDeletePokemon({
    required EditorNotifier notifier,
    required String trainerId,
    required int pokemonIndex,
  }) async {
    final success = await notifier.deleteTrainerPokemon(
      trainerId: trainerId,
      pokemonIndex: pokemonIndex,
    );
    if (!mounted || !success) {
      return;
    }

    setState(() {
      if (_isEditingPokemon(trainerId, pokemonIndex)) {
        _closePokemonEditor();
      }
    });
  }

  _TrainerPokemonDraft _buildPokemonDraft() {
    return _TrainerPokemonDraft(
      speciesId: _pokemonSpeciesController.text.trim(),
      level: int.tryParse(_pokemonLevelController.text.trim()),
      moves: _pokemonMoveControllers
          .map((controller) => controller.text.trim())
          .where((value) => value.isNotEmpty)
          .toList(growable: false),
      heldItemId: _normalizeOptionalField(_pokemonItemController.text),
      formId: _normalizeOptionalField(_pokemonFormController.text),
      gender: _normalizeOptionalField(_pokemonGenderController.text),
      shiny: _pokemonShiny,
    );
  }

  String? _validatePokemonDraft({
    required _TrainerReferenceData references,
    required PokedexSpeciesDetail? speciesDetail,
  }) {
    final draft = _buildPokemonDraft();
    if (draft.speciesId.isEmpty) {
      return 'Species ID cannot be empty.';
    }

    if (draft.level == null || draft.level! <= 0) {
      return 'Level must be a positive integer.';
    }

    if (references.isSpeciesAvailable &&
        _speciesLookupService.findById(
                references.speciesEntries, draft.speciesId) ==
            null) {
      return 'Species "${draft.speciesId}" is not present in the local Pokédex.';
    }

    if (references.movesCatalogView.isAvailable) {
      for (var i = 0; i < draft.moves.length; i++) {
        final moveId = draft.moves[i];
        if (_movesLookupService.findById(
              references.movesCatalogView.entries,
              moveId,
            ) ==
            null) {
          return 'Move ${i + 1} references an unknown local move: $moveId';
        }
      }
    }

    if (references.itemsCatalogView.isAvailable &&
        draft.heldItemId != null &&
        draft.heldItemId!.isNotEmpty &&
        _itemsLookupService.findById(
              references.itemsCatalogView.entries,
              draft.heldItemId!,
            ) ==
            null) {
      return 'Held item "${draft.heldItemId}" is not present in the local items catalog.';
    }

    final availableForms = speciesDetail == null
        ? const <String>[]
        : _buildSpeciesFormSuggestions(speciesDetail.species);
    if (availableForms.isNotEmpty &&
        draft.formId != null &&
        draft.formId!.isNotEmpty &&
        !availableForms.contains(draft.formId)) {
      return 'Form "${draft.formId}" does not match the selected species.';
    }

    return null;
  }

  // -------------------------------------------------------------------------
  // Construction UI
  // -------------------------------------------------------------------------

  // Trainer edition is a presentation concern only. Keeping this reset local
  // avoids pushing UI mode flags into the notifier or the use cases.
  void _closeTrainerEditor() {
    _editingTrainerId = null;
    _editTrainerValidationMessage = null;
    _showEditAdvanced = false;
  }

  Widget _buildTrainerTile({
    required BuildContext context,
    required ProjectTrainerEntry trainer,
    required ProjectManifest project,
    required EditorNotifier notifier,
    required _TrainerReferenceData references,
    required Color accent,
  }) {
    final workspace = _workspaceForState(ref.read(editorNotifierProvider));
    final subtle = CupertinoColors.secondaryLabel.resolveFrom(context);
    final isEditing = _editingTrainerId == trainer.id;
    final isAddingPokemon =
        _isAddingPokemon && _activePokemonTrainerId == trainer.id;

    return Container(
      key: ValueKey(trainer.id),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: EditorChrome.largeIslandSurfaceColor(context),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isEditing
              ? accent.withValues(alpha: 0.5)
              : CupertinoColors.separator.resolveFrom(context),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 8, 6, 8),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        trainer.name,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${trainer.trainerClass} • ${trainer.id}',
                        style: TextStyle(fontSize: 11, color: subtle),
                      ),
                      if (trainer.team.isEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            'No Pokémon assigned yet.',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: subtle,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(1, 28),
                  onPressed: () {
                    if (isEditing) {
                      setState(_closeTrainerEditor);
                    } else {
                      _startEditingTrainer(trainer);
                    }
                  },
                  child: Icon(
                    isEditing
                        ? CupertinoIcons.chevron_up
                        : CupertinoIcons.pencil,
                    size: 16,
                  ),
                ),
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(1, 28),
                  onPressed: () => _handleDeleteTrainer(
                    notifier: notifier,
                    trainer: trainer,
                  ),
                  child: const Icon(
                    CupertinoIcons.trash,
                    size: 16,
                    color: CupertinoColors.destructiveRed,
                  ),
                ),
              ],
            ),
          ),
          if (isEditing)
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 0, 10, 8),
              child: _TrainerEditorCard(
                key: Key('trainer-library-edit-card-${trainer.id}'),
                title: 'EDIT TRAINER',
                accent: accent,
                nameController: _editNameController,
                classController: _editClassController,
                portraitController: _editPortraitController,
                battleThemeController: _editBattleThemeController,
                victoryThemeController: _editVictoryThemeController,
                tagsController: _editTagsController,
                characters: project.characters,
                elements: project.elements,
                selectedCharacterId: _editCharacterId,
                validationMessage: _editTrainerValidationMessage,
                showAdvanced: _showEditAdvanced,
                createMode: false,
                onToggleAdvanced: () => setState(() {
                  _showEditAdvanced = !_showEditAdvanced;
                }),
                onSelectCharacter: (characterId) => setState(() {
                  _editCharacterId = characterId;
                }),
                onCancel: () => setState(_closeTrainerEditor),
                onSubmit: () => _handleUpdateTrainer(
                  notifier: notifier,
                  project: project,
                  trainer: trainer,
                ),
              ),
            ),
          Container(
            height: 1,
            color: CupertinoColors.separator.resolveFrom(context),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 6, 10, 0),
            child: InspectorEmbeddedSectionLabel(
              'TEAM (${trainer.team.length})',
            ),
          ),
          if (trainer.team.isEmpty && !isAddingPokemon)
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 2),
              child: Text(
                'You can save this trainer now and add the team later.',
                style: TextStyle(
                  color: subtle,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          for (var i = 0; i < trainer.team.length; i++) ...[
            _TrainerPokemonSummaryRow(
              key: Key('trainer-library-pokemon-row-${trainer.id}-$i'),
              pokemon: trainer.team[i],
              speciesEntry: _speciesLookupService.findById(
                references.speciesEntries,
                trainer.team[i].speciesId,
              ),
              moveCatalogView: references.movesCatalogView,
              itemCatalogView: references.itemsCatalogView,
              onEdit: () =>
                  _startEditingPokemon(trainer.id, i, trainer.team[i]),
              onDelete: () => _handleDeletePokemon(
                notifier: notifier,
                trainerId: trainer.id,
                pokemonIndex: i,
              ),
            ),
            if (_isEditingPokemon(trainer.id, i) && workspace != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 6, 10, 8),
                child: _TrainerPokemonEditorCard(
                  key:
                      Key('trainer-library-edit-pokemon-card-${trainer.id}-$i'),
                  trainerId: trainer.id,
                  references: references,
                  speciesController: _pokemonSpeciesController,
                  levelController: _pokemonLevelController,
                  itemController: _pokemonItemController,
                  formController: _pokemonFormController,
                  genderController: _pokemonGenderController,
                  moveControllers: _pokemonMoveControllers,
                  shiny: _pokemonShiny,
                  validationMessage: _pokemonValidationMessage,
                  onToggleShiny: (value) => setState(() {
                    _pokemonShiny = value;
                  }),
                  onCancel: () => setState(_closePokemonEditor),
                  onSave: () => _handleSavePokemonDraft(
                    notifier: notifier,
                    workspace: workspace,
                    references: references,
                  ),
                  loadSpeciesDetail: (speciesId) =>
                      _loadSpeciesDetailIfPossible(workspace, speciesId),
                ),
              ),
          ],
          if (isAddingPokemon && workspace != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 6, 10, 8),
              child: _TrainerPokemonEditorCard(
                key: Key('trainer-library-add-pokemon-card-${trainer.id}'),
                trainerId: trainer.id,
                references: references,
                speciesController: _pokemonSpeciesController,
                levelController: _pokemonLevelController,
                itemController: _pokemonItemController,
                formController: _pokemonFormController,
                genderController: _pokemonGenderController,
                moveControllers: _pokemonMoveControllers,
                shiny: _pokemonShiny,
                validationMessage: _pokemonValidationMessage,
                onToggleShiny: (value) => setState(() {
                  _pokemonShiny = value;
                }),
                onCancel: () => setState(_closePokemonEditor),
                onSave: () => _handleSavePokemonDraft(
                  notifier: notifier,
                  workspace: workspace,
                  references: references,
                ),
                loadSpeciesDetail: (speciesId) =>
                    _loadSpeciesDetailIfPossible(workspace, speciesId),
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 4, 10, 8),
            child: CupertinoButton(
              key: Key('trainer-library-add-pokemon-button-${trainer.id}'),
              padding: EdgeInsets.zero,
              minimumSize: const Size(1, 28),
              onPressed: () {
                if (isAddingPokemon) {
                  setState(_closePokemonEditor);
                } else {
                  _startAddingPokemon(trainer.id);
                }
              },
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isAddingPokemon
                        ? CupertinoIcons.minus_circle
                        : CupertinoIcons.plus_circle,
                    size: 14,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    isAddingPokemon ? 'Cancel' : 'Add Pokémon',
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

```

### `/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/ui/panels/trainer_library_panel_support.dart`

```dart
part of 'trainer_library_panel.dart';

// ---------------------------------------------------------------------------
// Références locales et draft UI
// ---------------------------------------------------------------------------

class _TrainerReferenceData {
  const _TrainerReferenceData({
    required this.speciesEntries,
    required this.isSpeciesAvailable,
    required this.speciesMessage,
    required this.movesCatalogView,
    required this.itemsCatalogView,
  });

  const _TrainerReferenceData.loading()
      : speciesEntries = const <PokemonDatabaseIndexEntry>[],
        isSpeciesAvailable = false,
        speciesMessage =
            'Chargement des références locales… La saisie brute reste possible pendant ce chargement.',
        movesCatalogView = const PokemonMovesCatalogView(
          entries: <PokemonMoveCatalogEntryView>[],
          isAvailable: false,
          description: 'Chargement du catalogue local des attaques…',
        ),
        itemsCatalogView = const PokemonItemsCatalogView(
          entries: <PokemonItemCatalogEntryView>[],
          isAvailable: false,
          description: 'Chargement du catalogue local des objets…',
        );

  const _TrainerReferenceData.unavailable()
      : speciesEntries = const <PokemonDatabaseIndexEntry>[],
        isSpeciesAvailable = false,
        speciesMessage =
            'Aucun workspace Pokémon exploitable. La saisie brute reste possible, mais sans assistance locale.',
        movesCatalogView = const PokemonMovesCatalogView(
          entries: <PokemonMoveCatalogEntryView>[],
          isAvailable: false,
          description: 'Catalogue local des attaques indisponible.',
        ),
        itemsCatalogView = const PokemonItemsCatalogView(
          entries: <PokemonItemCatalogEntryView>[],
          isAvailable: false,
          description: 'Catalogue local des objets indisponible.',
        );

  final List<PokemonDatabaseIndexEntry> speciesEntries;
  final bool isSpeciesAvailable;
  final String speciesMessage;
  final PokemonMovesCatalogView movesCatalogView;
  final PokemonItemsCatalogView itemsCatalogView;
}

class _TrainerPokemonDraft {
  const _TrainerPokemonDraft({
    required this.speciesId,
    required this.level,
    required this.moves,
    required this.heldItemId,
    required this.formId,
    required this.gender,
    required this.shiny,
  });

  final String speciesId;
  final int? level;
  final List<String> moves;
  final String? heldItemId;
  final String? formId;
  final String? gender;
  final bool shiny;
}

// ---------------------------------------------------------------------------
// Helpers purs
// ---------------------------------------------------------------------------

String? _normalizeOptionalField(String rawValue) {
  final trimmed = rawValue.trim();
  return trimmed.isEmpty ? null : trimmed;
}

List<String> _splitCommaSeparatedValues(String rawValue) {
  return rawValue
      .split(',')
      .map((value) => value.trim())
      .where((value) => value.isNotEmpty)
      .toList(growable: false);
}

void _clearTextControllers(Iterable<TextEditingController> controllers) {
  for (final controller in controllers) {
    controller.clear();
  }
}

List<String> _buildSpeciesFormSuggestions(PokemonSpeciesFile species) {
  // We only expose forms that truly exist in the local species payload.
  // Earlier code synthesized a `base` value when the data did not provide one,
  // which made the assist UI look more certain than it really was.
  final candidates = <String>[
    if (species.forms.formId.trim().isNotEmpty) species.forms.formId.trim(),
    ...species.forms.otherForms
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty),
  ];

  final unique = <String>[];
  final seen = <String>{};
  for (final candidate in candidates) {
    if (candidate.isEmpty) {
      continue;
    }
    if (seen.add(candidate)) {
      unique.add(candidate);
    }
  }
  return unique;
}

```

### `/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/ui/panels/trainer_library_panel_trainer_widgets.dart`

```dart
part of 'trainer_library_panel.dart';

// ---------------------------------------------------------------------------
// Widgets trainer
// ---------------------------------------------------------------------------

class _TrainerReferencesBanner extends StatelessWidget {
  const _TrainerReferencesBanner({
    required this.references,
    required this.onRefresh,
  });

  final _TrainerReferenceData references;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    final label = EditorChrome.primaryLabel(context);
    final subtle = EditorChrome.subtleLabel(context);
    final itemState = references.itemsCatalogView.isAvailable
        ? '${references.itemsCatalogView.entries.length} items'
        : 'items indisponibles';
    final moveState = references.movesCatalogView.isAvailable
        ? '${references.movesCatalogView.entries.length} moves'
        : 'moves indisponibles';
    final speciesState = references.isSpeciesAvailable
        ? '${references.speciesEntries.length} espèces'
        : 'espèces indisponibles';

    return DecoratedBox(
      decoration: BoxDecoration(
        color: EditorChrome.chipFill(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: EditorChrome.accentWarm.withValues(alpha: 0.18),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Local trainer assistance · $speciesState · $moveState · $itemState',
                    style: TextStyle(
                      color: label,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                CupertinoButton(
                  key: const Key('trainer-library-refresh-references-button'),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  minimumSize: const Size(1, 28),
                  onPressed: onRefresh,
                  child: const Text(
                    'Refresh',
                    style: TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              references.speciesMessage,
              style: TextStyle(
                color: subtle,
                fontSize: 11,
                fontWeight: FontWeight.w600,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              references.movesCatalogView.isAvailable
                  ? references.movesCatalogView.description
                  : references.movesCatalogView.message ??
                      references.movesCatalogView.description,
              style: TextStyle(
                color: subtle,
                fontSize: 11,
                fontWeight: FontWeight.w600,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              references.itemsCatalogView.isAvailable
                  ? references.itemsCatalogView.description
                  : references.itemsCatalogView.message ??
                      references.itemsCatalogView.description,
              style: TextStyle(
                color: subtle,
                fontSize: 11,
                fontWeight: FontWeight.w600,
                height: 1.35,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TrainerOperationBanner extends StatelessWidget {
  const _TrainerOperationBanner({
    required this.message,
    required this.isError,
  });

  final String message;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    final accent =
        isError ? EditorChrome.inspectorJoyCoral : EditorChrome.accentJade;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: EditorChrome.chipFill(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: accent.withValues(alpha: 0.28), width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Text(
          message,
          style: TextStyle(
            color: accent,
            fontSize: 11,
            fontWeight: FontWeight.w700,
            height: 1.35,
          ),
        ),
      ),
    );
  }
}

class _TrainerEditorCard extends StatelessWidget {
  const _TrainerEditorCard({
    super.key,
    required this.title,
    required this.accent,
    required this.nameController,
    required this.classController,
    required this.portraitController,
    required this.battleThemeController,
    required this.victoryThemeController,
    required this.tagsController,
    required this.characters,
    required this.elements,
    required this.selectedCharacterId,
    required this.validationMessage,
    required this.showAdvanced,
    required this.createMode,
    required this.onToggleAdvanced,
    required this.onSelectCharacter,
    required this.onCancel,
    required this.onSubmit,
  });

  final String title;
  final Color accent;
  final TextEditingController nameController;
  final TextEditingController classController;
  final TextEditingController portraitController;
  final TextEditingController battleThemeController;
  final TextEditingController victoryThemeController;
  final TextEditingController tagsController;
  final List<ProjectCharacterEntry> characters;
  final List<ProjectElementEntry> elements;
  final String? selectedCharacterId;
  final String? validationMessage;
  final bool showAdvanced;
  final bool createMode;
  final VoidCallback onToggleAdvanced;
  final ValueChanged<String?> onSelectCharacter;
  final VoidCallback onCancel;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    final subtle = CupertinoColors.secondaryLabel.resolveFrom(context);
    final knownPortraitIds = elements.map((element) => element.id).toSet();
    final portraitId = portraitController.text.trim();
    final portraitIsKnown =
        portraitId.isEmpty || knownPortraitIds.contains(portraitId);

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: EditorChrome.largeIslandSurfaceColor(
          context,
          tint: accent.withValues(alpha: 0.06),
        ),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: accent.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InspectorEmbeddedSectionLabel(title),
          const SizedBox(height: 6),
          CupertinoTextField(
            key: Key(
              createMode
                  ? 'trainer-library-create-name-field'
                  : 'trainer-library-edit-name-field',
            ),
            controller: nameController,
            placeholder: 'Name (e.g. Ash)',
          ),
          const SizedBox(height: 6),
          CupertinoTextField(
            key: Key(
              createMode
                  ? 'trainer-library-create-class-field'
                  : 'trainer-library-edit-class-field',
            ),
            controller: classController,
            placeholder: 'Class (e.g. Pokémon Trainer)',
          ),
          const SizedBox(height: 6),
          _TrainerCharacterPicker(
            characters: characters,
            selectedCharacterId: selectedCharacterId,
            onSelected: onSelectCharacter,
          ),
          const SizedBox(height: 8),
          CupertinoButton(
            padding: EdgeInsets.zero,
            minimumSize: const Size(1, 24),
            alignment: Alignment.centerLeft,
            onPressed: onToggleAdvanced,
            child: Text(
              showAdvanced ? 'Hide optional refs' : 'Show optional refs',
              style: const TextStyle(fontSize: 12),
            ),
          ),
          if (showAdvanced) ...[
            const SizedBox(height: 8),
            CupertinoTextField(
              key: Key(
                createMode
                    ? 'trainer-library-create-portrait-field'
                    : 'trainer-library-edit-portrait-field',
              ),
              controller: portraitController,
              placeholder: 'Portrait element ID (optional)',
            ),
            if (!portraitIsKnown)
              const Padding(
                padding: EdgeInsets.only(top: 4),
                child: Text(
                  'Portrait element ID is not present in the project elements.',
                  style: TextStyle(
                    color: EditorChrome.inspectorJoyCoral,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            const SizedBox(height: 6),
            CupertinoTextField(
              key: Key(
                createMode
                    ? 'trainer-library-create-battle-theme-field'
                    : 'trainer-library-edit-battle-theme-field',
              ),
              controller: battleThemeController,
              placeholder: 'Battle theme ID (optional)',
            ),
            const SizedBox(height: 6),
            CupertinoTextField(
              key: Key(
                createMode
                    ? 'trainer-library-create-victory-theme-field'
                    : 'trainer-library-edit-victory-theme-field',
              ),
              controller: victoryThemeController,
              placeholder: 'Victory theme ID (optional)',
            ),
            const SizedBox(height: 6),
            CupertinoTextField(
              key: Key(
                createMode
                    ? 'trainer-library-create-tags-field'
                    : 'trainer-library-edit-tags-field',
              ),
              controller: tagsController,
              placeholder: 'Tags (comma separated, optional)',
            ),
            const SizedBox(height: 6),
            Text(
              'Ces refs optionnelles restent brutes pour le moment. Seul le portrait est vérifié contre les éléments du projet ; battle theme, victory theme et tags sont conservés tels quels.',
              style: TextStyle(
                color: subtle,
                fontSize: 11,
                fontWeight: FontWeight.w600,
                height: 1.35,
              ),
            ),
          ],
          if (validationMessage != null) ...[
            const SizedBox(height: 8),
            Text(
              validationMessage!,
              style: const TextStyle(
                color: EditorChrome.inspectorJoyCoral,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                height: 1.35,
              ),
            ),
          ],
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              CupertinoButton(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                minimumSize: const Size(1, 28),
                onPressed: onCancel,
                child: const Text('Cancel', style: TextStyle(fontSize: 13)),
              ),
              const SizedBox(width: 6),
              CupertinoButton.filled(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                minimumSize: const Size(1, 28),
                onPressed: onSubmit,
                child: Text(
                  createMode ? 'Create' : 'Save',
                  style: const TextStyle(fontSize: 13),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TrainerCharacterPicker extends StatelessWidget {
  const _TrainerCharacterPicker({
    required this.characters,
    required this.selectedCharacterId,
    required this.onSelected,
  });

  final List<ProjectCharacterEntry> characters;
  final String? selectedCharacterId;
  final ValueChanged<String?> onSelected;

  @override
  Widget build(BuildContext context) {
    ProjectCharacterEntry? selected;
    for (final character in characters) {
      if (character.id == selectedCharacterId) {
        selected = character;
        break;
      }
    }
    final label = selected?.name ?? 'None';

    return Align(
      alignment: Alignment.centerLeft,
      child: PushButton(
        controlSize: ControlSize.regular,
        secondary: true,
        onPressed: () async {
          final picked = await showCupertinoListPicker<ProjectCharacterEntry?>(
            context: context,
            title: 'Trainer Character',
            items: [null, ...characters],
            labelOf: (value) => value?.name ?? 'None',
          );
          onSelected(picked?.id);
        },
        child: Text('Character: $label'),
      ),
    );
  }
}

```

### `/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/ui/panels/trainer_library_panel_pokemon_widgets.dart`

```dart
part of 'trainer_library_panel.dart';

class _TrainerPokemonSummaryRow extends StatelessWidget {
  const _TrainerPokemonSummaryRow({
    super.key,
    required this.pokemon,
    required this.speciesEntry,
    required this.moveCatalogView,
    required this.itemCatalogView,
    required this.onEdit,
    required this.onDelete,
  });

  final ProjectTrainerPokemonEntry pokemon;
  final PokemonDatabaseIndexEntry? speciesEntry;
  final PokemonMovesCatalogView moveCatalogView;
  final PokemonItemsCatalogView itemCatalogView;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final subtle = CupertinoColors.secondaryLabel.resolveFrom(context);
    final resolvedMoveLabels = pokemon.moves.map((moveId) {
      if (!moveCatalogView.isAvailable) {
        return moveId;
      }
      final match = _movesLookupService.findById(
        moveCatalogView.entries,
        moveId,
      );
      return match == null ? '$moveId (?)' : match.name;
    }).toList(growable: false);
    final resolvedItemLabel = pokemon.heldItemId == null ||
            pokemon.heldItemId!.trim().isEmpty ||
            !itemCatalogView.isAvailable
        ? pokemon.heldItemId?.trim()
        : _itemsLookupService
                .findById(itemCatalogView.entries, pokemon.heldItemId!.trim())
                ?.name ??
            '${pokemon.heldItemId!.trim()} (?)';

    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 6, 6, 4),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: EditorChrome.islandFillElevated(context),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: CupertinoColors.separator.resolveFrom(context),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 8, 6, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      speciesEntry == null
                          ? '${pokemon.speciesId} • Lv.${pokemon.level}'
                          : '${speciesEntry!.primaryName} • ${pokemon.speciesId} • Lv.${pokemon.level}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(1, 24),
                    onPressed: onEdit,
                    child: const Icon(
                      CupertinoIcons.pencil,
                      size: 14,
                    ),
                  ),
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(1, 24),
                    onPressed: onDelete,
                    child: const Icon(
                      CupertinoIcons.xmark,
                      size: 12,
                      color: CupertinoColors.destructiveRed,
                    ),
                  ),
                ],
              ),
              if (speciesEntry == null)
                const Padding(
                  padding: EdgeInsets.only(top: 4),
                  child: Text(
                    'Species absente du Pokédex local.',
                    style: TextStyle(
                      color: EditorChrome.inspectorJoyCoral,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              if (resolvedMoveLabels.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  'Moves: ${resolvedMoveLabels.join(', ')}',
                  style: TextStyle(fontSize: 11, color: subtle),
                ),
              ],
              if (resolvedItemLabel != null &&
                  resolvedItemLabel.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  'Item: $resolvedItemLabel',
                  style: TextStyle(fontSize: 11, color: subtle),
                ),
              ],
              if ((pokemon.formId ?? '').trim().isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  'Form: ${pokemon.formId!.trim()}',
                  style: TextStyle(fontSize: 11, color: subtle),
                ),
              ],
              if ((pokemon.gender ?? '').trim().isNotEmpty ||
                  pokemon.shiny) ...[
                const SizedBox(height: 4),
                Text(
                  [
                    if ((pokemon.gender ?? '').trim().isNotEmpty)
                      'Gender: ${pokemon.gender!.trim()}',
                    if (pokemon.shiny) 'Shiny',
                  ].join(' • '),
                  style: TextStyle(fontSize: 11, color: subtle),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _TrainerPokemonEditorCard extends StatefulWidget {
  const _TrainerPokemonEditorCard({
    super.key,
    required this.trainerId,
    required this.references,
    required this.speciesController,
    required this.levelController,
    required this.itemController,
    required this.formController,
    required this.genderController,
    required this.moveControllers,
    required this.shiny,
    required this.validationMessage,
    required this.onToggleShiny,
    required this.onCancel,
    required this.onSave,
    required this.loadSpeciesDetail,
  });

  final String trainerId;
  final _TrainerReferenceData references;
  final TextEditingController speciesController;
  final TextEditingController levelController;
  final TextEditingController itemController;
  final TextEditingController formController;
  final TextEditingController genderController;
  final List<TextEditingController> moveControllers;
  final bool shiny;
  final String? validationMessage;
  final ValueChanged<bool> onToggleShiny;
  final VoidCallback onCancel;
  final VoidCallback onSave;
  final Future<PokedexSpeciesDetail?> Function(String speciesId)
      loadSpeciesDetail;

  @override
  State<_TrainerPokemonEditorCard> createState() =>
      _TrainerPokemonEditorCardState();
}

class _TrainerPokemonEditorCardState extends State<_TrainerPokemonEditorCard> {
  Future<PokedexSpeciesDetail?>? _speciesDetailFuture;
  String _lastSpeciesId = '';

  @override
  void initState() {
    super.initState();
    _bindDraftControllers();
    _refreshSpeciesDetailFuture(force: true);
  }

  @override
  void didUpdateWidget(covariant _TrainerPokemonEditorCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.speciesController != widget.speciesController) {
      oldWidget.speciesController.removeListener(_onDraftFieldChanged);
      widget.speciesController.addListener(_onDraftFieldChanged);
    }
    if (oldWidget.levelController != widget.levelController) {
      oldWidget.levelController.removeListener(_onDraftFieldChanged);
      widget.levelController.addListener(_onDraftFieldChanged);
    }
    if (oldWidget.itemController != widget.itemController) {
      oldWidget.itemController.removeListener(_onDraftFieldChanged);
      widget.itemController.addListener(_onDraftFieldChanged);
    }
    if (oldWidget.formController != widget.formController) {
      oldWidget.formController.removeListener(_onDraftFieldChanged);
      widget.formController.addListener(_onDraftFieldChanged);
    }
    if (oldWidget.genderController != widget.genderController) {
      oldWidget.genderController.removeListener(_onDraftFieldChanged);
      widget.genderController.addListener(_onDraftFieldChanged);
    }
    if (oldWidget.moveControllers != widget.moveControllers) {
      for (final controller in oldWidget.moveControllers) {
        controller.removeListener(_onDraftFieldChanged);
      }
      for (final controller in widget.moveControllers) {
        controller.addListener(_onDraftFieldChanged);
      }
    }
    _refreshSpeciesDetailFuture(force: true);
  }

  @override
  void dispose() {
    _unbindDraftControllers();
    super.dispose();
  }

  void _bindDraftControllers() {
    widget.speciesController.addListener(_onDraftFieldChanged);
    widget.levelController.addListener(_onDraftFieldChanged);
    widget.itemController.addListener(_onDraftFieldChanged);
    widget.formController.addListener(_onDraftFieldChanged);
    widget.genderController.addListener(_onDraftFieldChanged);
    for (final controller in widget.moveControllers) {
      controller.addListener(_onDraftFieldChanged);
    }
  }

  void _unbindDraftControllers() {
    widget.speciesController.removeListener(_onDraftFieldChanged);
    widget.levelController.removeListener(_onDraftFieldChanged);
    widget.itemController.removeListener(_onDraftFieldChanged);
    widget.formController.removeListener(_onDraftFieldChanged);
    widget.genderController.removeListener(_onDraftFieldChanged);
    for (final controller in widget.moveControllers) {
      controller.removeListener(_onDraftFieldChanged);
    }
  }

  void _onDraftFieldChanged() {
    _refreshSpeciesDetailFuture();
    if (mounted) {
      setState(() {});
    }
  }

  void _refreshSpeciesDetailFuture({bool force = false}) {
    final speciesId = widget.speciesController.text.trim();
    if (!force && speciesId == _lastSpeciesId) {
      return;
    }
    _lastSpeciesId = speciesId;
    _speciesDetailFuture = widget.loadSpeciesDetail(speciesId);
  }

  @override
  Widget build(BuildContext context) {
    final subtle = CupertinoColors.secondaryLabel.resolveFrom(context);
    final resolvedSpecies = widget.references.isSpeciesAvailable
        ? _speciesLookupService.findById(
            widget.references.speciesEntries,
            widget.speciesController.text,
          )
        : null;
    final speciesCatalogReady = widget.references.isSpeciesAvailable;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: EditorChrome.largeIslandSurfaceColor(
          context,
          tint: EditorChrome.accentWarm.withValues(alpha: 0.06),
        ),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: EditorChrome.accentWarm.withValues(alpha: 0.35),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const InspectorEmbeddedSectionLabel('TRAINER POKÉMON'),
            const SizedBox(height: 8),
            _TrainerInlineField(
              label: 'Species ID',
              fieldKey: const Key('trainer-library-pokemon-species-field'),
              controller: widget.speciesController,
              placeholder: 'pikachu',
            ),
            const SizedBox(height: 8),
            _TrainerCatalogAssistField<PokemonDatabaseIndexEntry>(
              keyPrefix: 'trainer-library-pokemon-species',
              title: 'Species assist',
              description: speciesCatalogReady
                  ? 'Recherche locale par id, nom ou dex.'
                  : widget.references.speciesMessage,
              entries: widget.references.speciesEntries,
              lookupService: _speciesLookupService,
              enabled: speciesCatalogReady,
              searchPlaceholder: 'Chercher une espèce locale',
              subtitleBuilder: (entry) =>
                  '#${entry.nationalDex.toString().padLeft(4, '0')} • ${entry.id}',
              onSelected: (entry) {
                widget.speciesController.text = entry.id;
              },
            ),
            const SizedBox(height: 6),
            Text(
              resolvedSpecies == null
                  ? speciesCatalogReady
                      ? 'Espèce brute non résolue dans le Pokédex local.'
                      : 'La validation d’espèce reste limitée tant que l’index local est indisponible.'
                  : 'Espèce retenue : ${resolvedSpecies.primaryName} • ${resolvedSpecies.id}',
              style: TextStyle(
                color: resolvedSpecies == null
                    ? EditorChrome.inspectorJoyCoral
                    : subtle,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _TrainerInlineField(
                    label: 'Level',
                    fieldKey: const Key('trainer-library-pokemon-level-field'),
                    controller: widget.levelController,
                    placeholder: '1',
                    keyboardType: TextInputType.number,
                    inputFormatters: <TextInputFormatter>[
                      FilteringTextInputFormatter.digitsOnly,
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _TrainerInlineField(
                    label: 'Gender',
                    fieldKey: const Key('trainer-library-pokemon-gender-field'),
                    controller: widget.genderController,
                    placeholder: 'male / female / any',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final gender in _trainerQuickGenderValues)
                  PushButton(
                    controlSize: ControlSize.small,
                    secondary: widget.genderController.text.trim() != gender,
                    onPressed: () {
                      widget.genderController.text = gender;
                    },
                    child: Text(gender),
                  ),
                PushButton(
                  controlSize: ControlSize.small,
                  secondary: widget.genderController.text.trim().isNotEmpty,
                  onPressed: () {
                    widget.genderController.clear();
                  },
                  child: const Text('Clear gender'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Text(
                  'Shiny',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(width: 8),
                MacosSwitch(
                  value: widget.shiny,
                  onChanged: widget.onToggleShiny,
                ),
              ],
            ),
            const SizedBox(height: 12),
            const InspectorEmbeddedSectionLabel('MOVES'),
            const SizedBox(height: 8),
            for (var i = 0; i < widget.moveControllers.length; i++) ...[
              _TrainerMoveSlotEditor(
                slotIndex: i,
                controller: widget.moveControllers[i],
                catalogView: widget.references.movesCatalogView,
              ),
              if (i != widget.moveControllers.length - 1)
                const SizedBox(height: 10),
            ],
            const SizedBox(height: 12),
            const InspectorEmbeddedSectionLabel('ITEM / FORM'),
            const SizedBox(height: 8),
            _TrainerInlineField(
              label: 'Held item ID',
              fieldKey: const Key('trainer-library-pokemon-item-field'),
              controller: widget.itemController,
              placeholder: 'oran_berry',
            ),
            const SizedBox(height: 8),
            _TrainerCatalogAssistField<PokemonItemCatalogEntryView>(
              keyPrefix: 'trainer-library-pokemon-item',
              title: 'Item assist',
              description: widget.references.itemsCatalogView.isAvailable
                  ? 'Recherche locale par id ou nom.'
                  : widget.references.itemsCatalogView.message ??
                      widget.references.itemsCatalogView.description,
              entries: widget.references.itemsCatalogView.entries,
              lookupService: _itemsLookupService,
              enabled: widget.references.itemsCatalogView.isAvailable,
              searchPlaceholder: 'Chercher un objet local',
              subtitleBuilder: (entry) => entry.id,
              onSelected: (entry) {
                widget.itemController.text = entry.id;
              },
            ),
            const SizedBox(height: 8),
            _TrainerInlineField(
              label: 'Form ID',
              fieldKey: const Key('trainer-library-pokemon-form-field'),
              controller: widget.formController,
              placeholder: 'base / alternate form id',
            ),
            const SizedBox(height: 8),
            FutureBuilder<PokedexSpeciesDetail?>(
              future: _speciesDetailFuture,
              builder: (context, snapshot) {
                final detail = snapshot.data;
                final availableForms = detail == null
                    ? const <String>[]
                    : _buildSpeciesFormSuggestions(detail.species);

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      snapshot.connectionState == ConnectionState.waiting &&
                              widget.speciesController.text.trim().isNotEmpty
                          ? 'Chargement des formes locales pour cette espèce…'
                          : availableForms.isEmpty
                              ? 'Aucune suggestion de forme locale disponible pour cette espèce. La saisie brute reste possible.'
                              : 'Suggestions de formes locales :',
                      style: TextStyle(
                        color: subtle,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        height: 1.35,
                      ),
                    ),
                    if (availableForms.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          for (final formId in availableForms)
                            PushButton(
                              key: Key(
                                'trainer-library-pokemon-form-suggestion-$formId',
                              ),
                              controlSize: ControlSize.small,
                              secondary:
                                  widget.formController.text.trim() != formId,
                              onPressed: () {
                                widget.formController.text = formId;
                              },
                              child: Text(formId),
                            ),
                          PushButton(
                            key: const Key(
                              'trainer-library-pokemon-form-clear-button',
                            ),
                            controlSize: ControlSize.small,
                            secondary:
                                widget.formController.text.trim().isNotEmpty,
                            onPressed: () {
                              widget.formController.clear();
                            },
                            child: const Text('Clear form'),
                          ),
                        ],
                      ),
                    ],
                  ],
                );
              },
            ),
            if (widget.validationMessage != null) ...[
              const SizedBox(height: 10),
              Text(
                widget.validationMessage!,
                style: const TextStyle(
                  color: EditorChrome.inspectorJoyCoral,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  height: 1.35,
                ),
              ),
            ],
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                CupertinoButton(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  minimumSize: const Size(1, 28),
                  onPressed: widget.onCancel,
                  child: const Text('Cancel', style: TextStyle(fontSize: 13)),
                ),
                const SizedBox(width: 6),
                CupertinoButton.filled(
                  key: const Key('trainer-library-pokemon-save-button'),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  minimumSize: const Size(1, 28),
                  onPressed: widget.onSave,
                  child: const Text(
                    'Save Pokémon',
                    style: TextStyle(fontSize: 13),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _TrainerMoveSlotEditor extends StatelessWidget {
  const _TrainerMoveSlotEditor({
    required this.slotIndex,
    required this.controller,
    required this.catalogView,
  });

  final int slotIndex;
  final TextEditingController controller;
  final PokemonMovesCatalogView catalogView;

  @override
  Widget build(BuildContext context) {
    final subtle = CupertinoColors.secondaryLabel.resolveFrom(context);
    final moveId = controller.text.trim();
    final resolvedMove = catalogView.isAvailable
        ? _movesLookupService.findById(catalogView.entries, moveId)
        : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _TrainerInlineField(
          label: 'Move ${slotIndex + 1}',
          fieldKey: Key('trainer-library-pokemon-move-$slotIndex-field'),
          controller: controller,
          placeholder: 'move id',
        ),
        const SizedBox(height: 6),
        _TrainerCatalogAssistField<PokemonMoveCatalogEntryView>(
          keyPrefix: 'trainer-library-pokemon-move-$slotIndex',
          title: 'Move ${slotIndex + 1} assist',
          description: catalogView.isAvailable
              ? 'Recherche locale par id ou nom.'
              : catalogView.message ?? catalogView.description,
          entries: catalogView.entries,
          lookupService: _movesLookupService,
          enabled: catalogView.isAvailable,
          searchPlaceholder: 'Chercher un move local',
          subtitleBuilder: (entry) => [
            if (entry.type != null) entry.type!,
            if (entry.category != null) entry.category!,
            if (entry.pp != null) 'PP ${entry.pp}',
          ].join(' • '),
          onSelected: (entry) {
            controller.text = entry.id;
          },
        ),
        const SizedBox(height: 4),
        Text(
          moveId.isEmpty
              ? 'Slot vide.'
              : resolvedMove == null
                  ? catalogView.isAvailable
                      ? 'Move brut non résolu dans le catalogue local.'
                      : 'Catalogue moves indisponible : la valeur brute reste conservée.'
                  : 'Move retenu : ${resolvedMove.name} • ${resolvedMove.id}',
          style: TextStyle(
            color: moveId.isNotEmpty && resolvedMove == null
                ? EditorChrome.inspectorJoyCoral
                : subtle,
            fontSize: 11,
            fontWeight: FontWeight.w700,
            height: 1.35,
          ),
        ),
      ],
    );
  }
}

// This stays a local trainer widget on purpose: it is a small affordance for
// catalog-backed authoring, not a generic search framework for the editor.
class _TrainerCatalogAssistField<T> extends StatefulWidget {
  const _TrainerCatalogAssistField({
    required this.keyPrefix,
    required this.title,
    required this.description,
    required this.entries,
    required this.lookupService,
    required this.enabled,
    required this.searchPlaceholder,
    required this.onSelected,
    this.subtitleBuilder,
  });

  final String keyPrefix;
  final String title;
  final String description;
  final List<T> entries;
  final ProgressiveLocalCatalogLookupService<T> lookupService;
  final bool enabled;
  final String searchPlaceholder;
  final ValueChanged<T> onSelected;
  final String Function(T entry)? subtitleBuilder;

  @override
  State<_TrainerCatalogAssistField<T>> createState() =>
      _TrainerCatalogAssistFieldState<T>();
}

class _TrainerCatalogAssistFieldState<T>
    extends State<_TrainerCatalogAssistField<T>> {
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController()..addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController
      ..removeListener(_onSearchChanged)
      ..dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  void _selectEntry(T entry) {
    widget.onSelected(entry);
    _searchController.clear();
  }

  @override
  Widget build(BuildContext context) {
    final subtle = CupertinoColors.secondaryLabel.resolveFrom(context);
    final canSearch = widget.enabled && widget.entries.isNotEmpty;
    final suggestions = canSearch
        ? widget.lookupService.search(
            widget.entries,
            _searchController.text,
            limit: 8,
          )
        : List<T>.empty(growable: false);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.title,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 6),
        CupertinoTextField(
          key: Key('${widget.keyPrefix}-search-field'),
          controller: _searchController,
          enabled: canSearch,
          placeholder: widget.enabled
              ? widget.searchPlaceholder
              : 'Assistance locale indisponible',
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        ),
        const SizedBox(height: 4),
        Text(
          widget.description,
          style: TextStyle(
            color: subtle,
            fontSize: 11,
            fontWeight: FontWeight.w600,
            height: 1.35,
          ),
        ),
        if (_searchController.text.trim().isNotEmpty) ...[
          const SizedBox(height: 8),
          if (!canSearch)
            Text(
              'Aucune suggestion locale disponible pour le moment.',
              key: Key('${widget.keyPrefix}-search-unavailable'),
              style: const TextStyle(
                color: EditorChrome.inspectorJoyCoral,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            )
          else if (suggestions.isEmpty)
            Text(
              'Aucun résultat local pour cette recherche.',
              key: Key('${widget.keyPrefix}-search-empty'),
              style: const TextStyle(
                color: EditorChrome.inspectorJoyCoral,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            )
          else
            Container(
              key: Key('${widget.keyPrefix}-suggestions'),
              constraints: const BoxConstraints(maxHeight: 180),
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: suggestions.length,
                separatorBuilder: (_, __) => const SizedBox(height: 6),
                itemBuilder: (context, index) {
                  final entry = suggestions[index];
                  final title = widget.lookupService.labelOf(entry);
                  final id = widget.lookupService.idOf(entry);
                  final subtitle = widget.subtitleBuilder?.call(entry);
                  return DecoratedBox(
                    decoration: BoxDecoration(
                      color: EditorChrome.islandFillElevated(context),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: EditorChrome.accentWarm.withValues(alpha: 0.22),
                        width: 1,
                      ),
                    ),
                    child: CupertinoButton(
                      key: Key('${widget.keyPrefix}-suggestion-$id'),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      onPressed: () => _selectEntry(entry),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '$title • $id',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                if (subtitle != null &&
                                    subtitle.trim().isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    subtitle,
                                    style: TextStyle(
                                      color: subtle,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Use',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ],
    );
  }
}

class _TrainerInlineField extends StatelessWidget {
  const _TrainerInlineField({
    required this.label,
    required this.fieldKey,
    required this.controller,
    required this.placeholder,
    this.keyboardType,
    this.inputFormatters,
  });

  final String label;
  final Key fieldKey;
  final TextEditingController controller;
  final String placeholder;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 6),
        CupertinoTextField(
          key: fieldKey,
          controller: controller,
          placeholder: placeholder,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
        ),
      ],
    );
  }
}

```

### `/Users/karim/Project/pokemonProject/packages/map_editor/test/trainer_library_panel_test.dart`

```dart
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:macos_ui/macos_ui.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/app/providers/core/repository_providers.dart';
import 'package:map_editor/src/app/providers/pokedex/pokedex_providers.dart';
import 'package:map_editor/src/application/errors/application_errors.dart';
import 'package:map_editor/src/application/models/pokedex_species_detail.dart';
import 'package:map_editor/src/application/models/pokemon_database_index.dart';
import 'package:map_editor/src/application/models/pokemon_project_data_models.dart';
import 'package:map_editor/src/application/ports/pokemon_read_repository.dart';
import 'package:map_editor/src/application/ports/project_workspace.dart';
import 'package:map_editor/src/application/use_cases/load_pokemon_items_catalog_use_case.dart';
import 'package:map_editor/src/application/use_cases/sync_pokemon_moves_catalog_use_case.dart';
import 'package:map_editor/src/domain/repositories/repositories.dart';
import 'package:map_editor/src/features/editor/state/editor_notifier.dart';
import 'package:map_editor/src/features/editor/state/editor_state.dart';
import 'package:map_editor/src/ui/panels/trainer_library_panel.dart';

void main() {
  Future<void> pumpTrainerPanel(
    WidgetTester tester,
    ProviderContainer container,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1600, 2200);
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MacosTheme(
          data: MacosThemeData.light(),
          child: const MaterialApp(
            home: CupertinoPageScaffold(
              child: SizedBox(
                width: 1280,
                height: 1800,
                child: TrainerLibraryPanel(),
              ),
            ),
          ),
        ),
      ),
    );
  }

  testWidgets(
      'creates a trainer and saves a complete team entry with assisted refs',
      (tester) async {
    final repository = _FakeProjectRepository();
    const workspace = _FakeWorkspace();
    final container = ProviderContainer(
      overrides: [
        projectRepositoryProvider.overrideWithValue(repository),
        projectWorkspaceFactoryProvider.overrideWithValue(
          const _FakeWorkspaceFactory(workspace),
        ),
        pokedexEntryLoaderProvider.overrideWithValue(
          (_) async => _speciesEntries,
        ),
        pokedexMovesCatalogLoaderProvider.overrideWithValue(
          (_) async => _movesCatalogView,
        ),
        pokedexSpeciesDetailLoaderProvider.overrideWithValue(
          (_, speciesId) async =>
              _detailsById[speciesId] ??
              (throw EditorNotFoundException('Missing detail: $speciesId')),
        ),
        loadPokemonItemsCatalogUseCaseProvider.overrideWithValue(
          LoadPokemonItemsCatalogUseCase(
            readRepository: _FakePokemonReadRepository(
              catalogByKey: <String, PokemonCatalogFile>{
                'items': _itemsCatalog,
              },
            ),
          ),
        ),
      ],
    );
    addTearDown(container.dispose);

    container.read(editorNotifierProvider.notifier).state = const EditorState(
      projectRootPath: '/tmp/trainers_panel_test',
      project: ProjectManifest(
        name: 'trainers_panel_test',
        maps: <ProjectMapEntry>[],
        tilesets: <ProjectTilesetEntry>[],
      ),
    );

    await pumpTrainerPanel(tester, container);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    await tester.tap(
      find.byKey(const Key('trainer-library-new-trainer-button')),
    );
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('trainer-library-create-name-field')),
      'Misty',
    );
    await tester.enterText(
      find.byKey(const Key('trainer-library-create-class-field')),
      'Gym Leader',
    );
    await tester.tap(find.text('Show optional refs'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('trainer-library-create-battle-theme-field')),
      'battle_misty',
    );
    await tester.enterText(
      find.byKey(const Key('trainer-library-create-victory-theme-field')),
      'victory_misty',
    );
    await tester.enterText(
      find.byKey(const Key('trainer-library-create-tags-field')),
      ' rival, gym ',
    );

    await tester.tap(find.text('Create'));
    await tester.pumpAndSettle();

    final trainer =
        container.read(editorNotifierProvider).project!.trainers.single;
    expect(trainer.name, 'Misty');
    expect(trainer.battleThemeId, 'battle_misty');
    expect(trainer.victoryThemeId, 'victory_misty');
    expect(trainer.tags, <String>['rival', 'gym']);

    await tester.tap(
      find.byKey(Key('trainer-library-add-pokemon-button-${trainer.id}')),
    );
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('trainer-library-pokemon-species-search-field')),
      'bulba',
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(
        const Key('trainer-library-pokemon-species-suggestion-bulbasaur'),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('trainer-library-pokemon-level-field')),
      '12',
    );
    await tester.tap(find.text('female'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('trainer-library-pokemon-move-0-search-field')),
      'tackle',
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(
        const Key('trainer-library-pokemon-move-0-suggestion-tackle'),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('trainer-library-pokemon-move-1-search-field')),
      'growl',
    );
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('trainer-library-pokemon-move-1-field')),
      'growl',
    );
    await tester.scrollUntilVisible(
      find.byKey(const Key('trainer-library-pokemon-item-field')),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.enterText(
      find.byKey(const Key('trainer-library-pokemon-item-field')),
      'oran_berry',
    );
    await tester.enterText(
      find.byKey(const Key('trainer-library-pokemon-form-field')),
      'blossom',
    );
    await tester.pumpAndSettle();

    final savePokemonButton =
        find.byKey(const Key('trainer-library-pokemon-save-button'));
    await tester.dragUntilVisible(
      savePokemonButton,
      find.byType(ListView).first,
      const Offset(0, -220),
    );
    await tester.tap(savePokemonButton);
    await tester.pumpAndSettle();

    final savedTrainer =
        container.read(editorNotifierProvider).project!.trainers.single;
    final pokemon = savedTrainer.team.single;
    expect(pokemon.speciesId, 'bulbasaur');
    expect(pokemon.level, 12);
    expect(pokemon.moves, <String>['tackle', 'growl']);
    expect(pokemon.heldItemId, 'oran_berry');
    expect(pokemon.formId, 'blossom');
    expect(pokemon.gender, 'female');
    expect(pokemon.shiny, isFalse);
    expect(
      find.byKey(Key('trainer-library-pokemon-row-${trainer.id}-0')),
      findsOneWidget,
    );
  });

  testWidgets('shows inline validation when a move is unknown locally',
      (tester) async {
    final repository = _FakeProjectRepository();
    const workspace = _FakeWorkspace();
    final container = ProviderContainer(
      overrides: [
        projectRepositoryProvider.overrideWithValue(repository),
        projectWorkspaceFactoryProvider.overrideWithValue(
          const _FakeWorkspaceFactory(workspace),
        ),
        pokedexEntryLoaderProvider.overrideWithValue(
          (_) async => _speciesEntries,
        ),
        pokedexMovesCatalogLoaderProvider.overrideWithValue(
          (_) async => _movesCatalogView,
        ),
        pokedexSpeciesDetailLoaderProvider.overrideWithValue(
          (_, speciesId) async =>
              _detailsById[speciesId] ??
              (throw EditorNotFoundException('Missing detail: $speciesId')),
        ),
        loadPokemonItemsCatalogUseCaseProvider.overrideWithValue(
          LoadPokemonItemsCatalogUseCase(
            readRepository: _FakePokemonReadRepository(
              catalogByKey: <String, PokemonCatalogFile>{
                'items': _itemsCatalog,
              },
            ),
          ),
        ),
      ],
    );
    addTearDown(container.dispose);

    container.read(editorNotifierProvider.notifier).state = const EditorState(
      projectRootPath: '/tmp/trainers_panel_test',
      project: ProjectManifest(
        name: 'trainers_panel_test',
        maps: <ProjectMapEntry>[],
        tilesets: <ProjectTilesetEntry>[],
        trainers: <ProjectTrainerEntry>[
          ProjectTrainerEntry(
            id: 'misty',
            name: 'Misty',
            trainerClass: 'Gym Leader',
          ),
        ],
      ),
    );

    await pumpTrainerPanel(tester, container);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    await tester.tap(
      find.byKey(const Key('trainer-library-add-pokemon-button-misty')),
    );
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('trainer-library-pokemon-species-field')),
      'bulbasaur',
    );
    await tester.enterText(
      find.byKey(const Key('trainer-library-pokemon-level-field')),
      '10',
    );
    await tester.enterText(
      find.byKey(const Key('trainer-library-pokemon-move-0-field')),
      'missing_move',
    );

    final savePokemonButton =
        find.byKey(const Key('trainer-library-pokemon-save-button'));
    await tester.dragUntilVisible(
      savePokemonButton,
      find.byType(ListView).first,
      const Offset(0, -220),
    );
    await tester.tap(savePokemonButton);
    await tester.pumpAndSettle();

    expect(
      find.text('Move 1 references an unknown local move: missing_move'),
      findsOneWidget,
    );
    expect(
      container.read(editorNotifierProvider).project!.trainers.single.team,
      isEmpty,
    );
  });

  testWidgets(
      'does not invent a base form suggestion when the local species detail has none',
      (tester) async {
    final repository = _FakeProjectRepository();
    const workspace = _FakeWorkspace();
    final container = ProviderContainer(
      overrides: [
        projectRepositoryProvider.overrideWithValue(repository),
        projectWorkspaceFactoryProvider.overrideWithValue(
          const _FakeWorkspaceFactory(workspace),
        ),
        pokedexEntryLoaderProvider.overrideWithValue(
          (_) async => _speciesEntries,
        ),
        pokedexMovesCatalogLoaderProvider.overrideWithValue(
          (_) async => _movesCatalogView,
        ),
        pokedexSpeciesDetailLoaderProvider.overrideWithValue(
          (_, speciesId) async => speciesId == 'bulbasaur'
              ? _buildDetail(
                  forms: const PokemonSpeciesForms(
                    baseFormId: 'bulbasaur',
                    isBaseForm: true,
                    formId: '',
                    otherForms: <String>[],
                  ),
                )
              : (throw EditorNotFoundException('Missing detail: $speciesId')),
        ),
        loadPokemonItemsCatalogUseCaseProvider.overrideWithValue(
          LoadPokemonItemsCatalogUseCase(
            readRepository: _FakePokemonReadRepository(
              catalogByKey: <String, PokemonCatalogFile>{
                'items': _itemsCatalog,
              },
            ),
          ),
        ),
      ],
    );
    addTearDown(container.dispose);

    container.read(editorNotifierProvider.notifier).state = const EditorState(
      projectRootPath: '/tmp/trainers_panel_test',
      project: ProjectManifest(
        name: 'trainers_panel_test',
        maps: <ProjectMapEntry>[],
        tilesets: <ProjectTilesetEntry>[],
        trainers: <ProjectTrainerEntry>[
          ProjectTrainerEntry(
            id: 'misty',
            name: 'Misty',
            trainerClass: 'Gym Leader',
          ),
        ],
      ),
    );

    await pumpTrainerPanel(tester, container);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    await tester.tap(
      find.byKey(const Key('trainer-library-add-pokemon-button-misty')),
    );
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('trainer-library-pokemon-species-field')),
      'bulbasaur',
    );
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.byKey(const Key('trainer-library-pokemon-form-field')),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    expect(
      find.text(
        'Aucune suggestion de forme locale disponible pour cette espèce. La saisie brute reste possible.',
      ),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('trainer-library-pokemon-form-suggestion-base')),
      findsNothing,
    );
  });
}

const List<PokemonDatabaseIndexEntry> _speciesEntries =
    <PokemonDatabaseIndexEntry>[
  PokemonDatabaseIndexEntry(
    id: 'bulbasaur',
    nationalDex: 1,
    primaryName: 'Bulbasaur',
    genIntroduced: 1,
    types: <String>['grass', 'poison'],
    isEnabledInProject: true,
    refs: PokemonDatabaseIndexRefs(
      learnset: 'bulbasaur',
      evolution: 'bulbasaur',
      media: 'bulbasaur',
    ),
  ),
];

const PokemonMovesCatalogView _movesCatalogView = PokemonMovesCatalogView(
  entries: <PokemonMoveCatalogEntryView>[
    PokemonMoveCatalogEntryView(
      id: 'growl',
      name: 'Growl',
      type: 'normal',
      category: 'status',
      pp: 40,
    ),
    PokemonMoveCatalogEntryView(
      id: 'tackle',
      name: 'Tackle',
      type: 'normal',
      category: 'physical',
      power: 40,
      pp: 35,
    ),
  ],
  isAvailable: true,
  description: 'Catalogue local des attaques.',
);

const PokemonCatalogFile _itemsCatalog = PokemonCatalogFile(
  schemaVersion: 1,
  kind: 'pokemon_catalog',
  catalog: 'items',
  meta: PokemonDataMeta(description: 'Catalogue local des objets.'),
  entries: <Map<String, dynamic>>[
    <String, dynamic>{
      'id': 'oran_berry',
      'name': 'Oran Berry',
      'aliases': <String>['oran'],
    },
  ],
);

final Map<String, PokedexSpeciesDetail> _detailsById =
    <String, PokedexSpeciesDetail>{
  'bulbasaur': _buildDetail(),
};

PokedexSpeciesDetail _buildDetail({
  PokemonSpeciesForms forms = const PokemonSpeciesForms(
    baseFormId: 'bulbasaur',
    isBaseForm: true,
    formId: 'base',
    otherForms: <String>['blossom'],
  ),
}) {
  return PokedexSpeciesDetail(
    species: PokemonSpeciesFile(
      id: 'bulbasaur',
      slug: 'bulbasaur',
      nationalDex: 1,
      names: <String, String>{'en': 'Bulbasaur'},
      speciesName: <String, String>{'en': 'Seed Pokemon'},
      genIntroduced: 1,
      typing: const PokemonSpeciesTyping(types: <String>['grass', 'poison']),
      baseStats: const PokemonSpeciesBaseStats(
        hp: 45,
        atk: 49,
        def: 49,
        spa: 65,
        spd: 65,
        spe: 45,
        bst: 318,
      ),
      abilities: const PokemonSpeciesAbilities(primary: 'overgrow'),
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
      forms: forms,
      classification: const PokemonSpeciesClassification(
        isEnabledInProject: true,
        isObtainable: true,
      ),
      refs: const PokemonSpeciesRefs(
        learnset: 'bulbasaur',
        evolution: 'bulbasaur',
        media: 'bulbasaur',
      ),
      dexContent: const PokemonSpeciesDexContent(
        heightM: 0.7,
        weightKg: 6.9,
        color: 'green',
        flavorText: 'A strange seed was planted on its back at birth.',
      ),
      gameplayFlags: const PokemonSpeciesGameplayFlags(starterEligible: true),
      sourceMeta:
          const PokemonSpeciesSourceMeta(seededBy: 'test', seedVersion: 1),
    ),
    learnset: const PokemonLearnsetFile(
      speciesId: 'bulbasaur',
      startingMoves: <String>['tackle'],
    ),
    evolution: const PokemonEvolutionFile(
      speciesId: 'bulbasaur',
      evolutions: <PokemonEvolutionEntry>[],
    ),
    media: const PokemonMediaFile(
      speciesId: 'bulbasaur',
      defaultFormId: 'base',
      variants: <String, PokemonMediaVariant>{},
    ),
  );
}

class _FakeProjectRepository implements ProjectRepository {
  ProjectManifest? lastSavedProject;

  @override
  Future<ProjectManifest> loadProject(String path) {
    throw UnimplementedError();
  }

  @override
  Future<void> saveProject(ProjectManifest project, String path) async {
    lastSavedProject = project;
  }
}

class _FakeWorkspaceFactory implements ProjectWorkspaceFactory {
  const _FakeWorkspaceFactory(this.workspace);

  final ProjectWorkspace workspace;

  @override
  ProjectWorkspace create(String projectRoot) => workspace;
}

class _FakeWorkspace implements ProjectWorkspace {
  const _FakeWorkspace();

  @override
  String get projectManifestPath => '/tmp/project.json';

  @override
  String get projectRoot => '/tmp';

  @override
  Future<void> copyFile(String sourcePath, String destinationPath) async {}

  @override
  Future<void> deleteDirectoryIfEmpty(String path) async {}

  @override
  Future<void> deleteRelativeFile(String relativePath) async {}

  @override
  Future<bool> directoryExists(String path) async => false;

  @override
  Future<void> ensureDirectoryExists(String path) async {}

  @override
  Future<bool> fileExists(String path) async => false;

  @override
  String getMapPath(String mapId) => '/tmp/$mapId.json';

  @override
  String getMapRelativePath(String mapId) => '$mapId.json';

  @override
  Future<String> importTilesetImage(
    String sourcePath, {
    String? preferredName,
  }) async {
    return sourcePath;
  }

  @override
  Future<void> moveDirectory(String sourcePath, String destinationPath) async {}

  @override
  Future<void> moveFile(String sourcePath, String destinationPath) async {}

  @override
  Future<String> readTextFile(String path) async => '';

  @override
  String resolveMapPath(String relativePath) => '/tmp/$relativePath';

  @override
  String resolveProjectRelativePath(String relativePath) =>
      '/tmp/$relativePath';

  @override
  String resolveTilesetPath(String relativePath) => '/tmp/$relativePath';

  @override
  Future<void> writeTextFile(String path, String contents) async {}
}

class _FakePokemonReadRepository implements PokemonReadRepository {
  _FakePokemonReadRepository({
    this.catalogByKey = const <String, PokemonCatalogFile>{},
  });

  final Map<String, PokemonCatalogFile> catalogByKey;

  @override
  Future<PokemonCatalogFile> readCatalogByKey(
    ProjectWorkspace workspace,
    String catalogKey,
  ) async {
    final catalog = catalogByKey[catalogKey];
    if (catalog == null) {
      throw EditorNotFoundException('Missing catalog: $catalogKey');
    }
    return catalog;
  }

  @override
  Future<PokemonDataManifest> readManifest(ProjectWorkspace workspace) {
    throw UnimplementedError();
  }

  @override
  Future<List<PokemonSpeciesIndexEntry>> listSpeciesIndexEntries(
    ProjectWorkspace workspace,
  ) {
    throw UnimplementedError();
  }

  @override
  Future<List<PokemonDatabaseIndexEntry>> listDatabaseIndexEntries(
    ProjectWorkspace workspace, {
    required String speciesDirectoryRelativePath,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<List<String>> listSpeciesFiles(ProjectWorkspace workspace) {
    throw UnimplementedError();
  }

  @override
  Future<PokemonSpeciesFile> readSpeciesByRelativePath(
    ProjectWorkspace workspace,
    String relativePath,
  ) {
    throw UnimplementedError();
  }

  @override
  Future<PokemonSpeciesFile> readSpeciesById(
    ProjectWorkspace workspace,
    String speciesId,
  ) {
    throw UnimplementedError();
  }

  @override
  Future<List<String>> listLearnsetIds(ProjectWorkspace workspace) {
    throw UnimplementedError();
  }

  @override
  Future<PokemonLearnsetFile> readLearnsetById(
    ProjectWorkspace workspace,
    String speciesId,
  ) {
    throw UnimplementedError();
  }

  @override
  Future<List<String>> listEvolutionIds(ProjectWorkspace workspace) {
    throw UnimplementedError();
  }

  @override
  Future<PokemonEvolutionFile> readEvolutionById(
    ProjectWorkspace workspace,
    String speciesId,
  ) {
    throw UnimplementedError();
  }

  @override
  Future<List<String>> listMediaIds(ProjectWorkspace workspace) {
    throw UnimplementedError();
  }

  @override
  Future<PokemonMediaFile> readMediaById(
    ProjectWorkspace workspace,
    String speciesId,
  ) {
    throw UnimplementedError();
  }
}

```
