# Phase R1 — Lot 7 corrective audit report

## 1. Résumé exécutif honnête

Cette passe ne réécrit pas le lot 7. Le code réel montre que le corrective pass précédent a déjà produit un vrai gain de maintenabilité : `trainer_library_panel.dart` est redevenu un orchestrateur raisonnablement lisible, et les `part` files voisins portent maintenant l’essentiel du bruit UI.

Après audit du code actuel et du diff réel, un seul problème comportemental local a été confirmé : `_loadReferenceData()` ne dégradait honnêtement que le chargement des espèces. Si le chargement du catalogue `moves` ou `items` échouait par une exception inattendue, le `FutureBuilder` pouvait rester sans données exploitables et la surface trainer pouvait devenir trompeuse.

Le correctif retenu est minimal :

- encapsuler le chargement `moves` et `items` dans des `try/catch` locaux, avec fallback explicite vers des vues “catalogue indisponible” ;
- ajouter un test widget qui prouve que la surface trainer reste utilisable avec saisie brute quand les lookups `moves` et `items` explosent.

Le reste de l’audit a conclu que les autres points demandés étaient globalement **non confirmés** comme bugs nécessitant du churn :

- le découpage en `part` files reste défendable ;
- `EditorNotifier` reste un orchestrateur ;
- `trainer_use_cases.dart` reste dans le métier ;
- le support `forms` reste honnête ;
- les messages principaux sont déjà acceptables pour ce scope.

## 2. État initial audité réel

Source de vérité utilisée pour cette passe :

- le code actuel dans `packages/map_editor/lib/src/ui/panels/`
- `packages/map_editor/lib/src/features/editor/state/editor_notifier.dart`
- `packages/map_editor/lib/src/application/use_cases/trainer_use_cases.dart`
- les tests réels du lot 7 et des lots voisins
- l’état git réel (`git status`, `git diff --stat`, `git ls-files --others`)

Le report précédent n’a pas été utilisé comme source de vérité.

Constats au départ :

- `trainer_library_panel.dart` est à **1071 lignes**.
- Les fichiers voisins existent et portent bien des responsabilités séparées :
  - `trainer_library_panel_support.dart` : helpers purs + petits modèles UI locaux
  - `trainer_library_panel_trainer_widgets.dart` : widgets trainer
  - `trainer_library_panel_pokemon_widgets.dart` : widgets Pokémon/team + assist fields
- `EditorNotifier` expose des méthodes d’orchestration trainer, mais n’absorbe pas de logique métier lourde.
- `trainer_use_cases.dart` contient surtout validation/normalisation métier simple et persistence, pas de conventions d’écran.

### Taille des fichiers au moment de l’audit

```text
   1071 packages/map_editor/lib/src/ui/panels/trainer_library_panel.dart
    120 packages/map_editor/lib/src/ui/panels/trainer_library_panel_support.dart
    396 packages/map_editor/lib/src/ui/panels/trainer_library_panel_trainer_widgets.dart
    876 packages/map_editor/lib/src/ui/panels/trainer_library_panel_pokemon_widgets.dart
   2463 total
```

### Problèmes confirmés

1. `_loadReferenceData()` traitait honnêtement l’échec `species`, mais pas les exceptions imprévues côté `moves` et `items`.
2. Cette asymétrie pouvait laisser la surface trainer dans un état peu honnête alors que la saisie brute devait rester possible.

### Problèmes non confirmés

1. Le corrective pass précédent n’a pas recréé une architecture trainer parallèle.
2. La répartition des `part` files n’est pas trompeuse en elle-même.
3. `EditorNotifier` n’a pas basculé en service métier trainer caché.
4. `trainer_use_cases.dart` ne porte pas de logique de formulaire UI.
5. Le support `forms` n’invente plus de suggestion `base` et reste permissif quand la donnée locale manque.

## 3. Conclusions des 5 sous-agents

### Sous-agent A — Architecture / scope

Conclusion :

- le corrective pass reste local ;
- le panel principal est redevenu un orchestrateur ;
- aucun découpage supplémentaire n’est strictement nécessaire ;
- le seul vrai correctif local justifié est la gestion honnête des échecs de chargement des références.

Retenu :

- pas de nouveau fichier ;
- pas de nouvelle couche trainer ;
- correctif local dans `_loadReferenceData()`.

Rejeté :

- extraction supplémentaire cosmétique ;
- nouveau store/notifier/service trainer.

### Sous-agent B — UI maintainability

Conclusion :

- la lisibilité du flux principal est maintenant réelle ;
- la répartition des `part` files est défendable ;
- le plus gros point restant est le comportement dégradé sur erreur de lookup `moves/items`.

Retenu :

- conserver le découpage actuel ;
- corriger seulement le cas où la surface pouvait devenir trompeuse.

Rejeté :

- nouvelle extraction de widgets juste pour faire baisser le nombre de lignes ;
- chantier de wording plus large.

### Sous-agent C — State / behavior reviewer

Conclusion :

- les helpers `_resetPokemonDraftFields()`, `_closePokemonEditor()`, `_closeTrainerEditor()` restent cohérents ;
- pas de fuite d’état locale évidente sur add/edit/cancel/delete ;
- pas de micro-correction nécessaire sur les resets eux-mêmes.

Retenu :

- aucun changement sur les resets/handlers.

Rejeté :

- refactor des flows d’ouverture/fermeture sans bug démontré.

### Sous-agent D — Product honesty reviewer

Conclusion :

- le support `forms` est honnête ;
- les messages sur form non suggérée sont acceptables ;
- la vraie faille d’honnêteté produit vient du cas où `moves/items` deviennent indisponibles par exception inattendue.

Retenu :

- fallback explicite “catalogue indisponible” pour `moves` et `items`.

Rejeté :

- chantier plus large de wording ;
- durcissement de validation forms.

### Sous-agent E — Test matrix reviewer

Conclusion :

- la couverture existante était déjà bonne ;
- un seul test supplémentaire apportait une vraie valeur : prouver que le panel reste utilisable si les lookups `moves/items` échouent brutalement.

Retenu :

- un widget test ciblé, pas plus.

Rejeté :

- duplication de tests de rendu décoratif ;
- nouveaux tests sur les resets alors qu’aucun bug n’a été confirmé.

## 4. Problèmes confirmés / non confirmés

### Confirmés

- Fallback incomplet dans `_loadReferenceData()` pour les erreurs imprévues de chargement du catalogue `moves`.
- Fallback incomplet dans `_loadReferenceData()` pour les erreurs imprévues de chargement du catalogue `items`.

### Non confirmés

- Besoin d’extraire encore des widgets hors des `part` files existants.
- Besoin de toucher `EditorNotifier`.
- Besoin de toucher `trainer_use_cases.dart`.
- Besoin de retoucher la logique `forms`.
- Besoin de revoir les helpers de reset.

## 5. Décisions retenues / rejetées

### Retenues

1. Corriger seulement `_loadReferenceData()` dans `trainer_library_panel.dart`.
2. Ajouter un test widget ciblé prouvant la dégradation honnête.
3. Laisser toute l’architecture lot 7 inchangée.

### Rejetées

1. Nouveau service/provider pour centraliser les fallbacks de références.
2. Refactor structurel supplémentaire du panel.
3. Retouches cosmétiques de wording hors cas directement liés au bug.
4. Modification d’`EditorNotifier` ou de `trainer_use_cases.dart` sans nécessité directe.

## 6. Liste exacte des fichiers modifiés / créés / supprimés

### Modifiés

- `packages/map_editor/lib/src/ui/panels/trainer_library_panel.dart`
- `packages/map_editor/test/trainer_library_panel_test.dart`

### Créés

- `reports/phase-r1-lot-7-corrective-audit-report.md`

### Supprimés

- aucun

## 7. Justification fichier par fichier

### `packages/map_editor/lib/src/ui/panels/trainer_library_panel.dart`

Pourquoi modifié :

- `_loadReferenceData()` ne gérait proprement que l’échec espèces ;
- les erreurs imprévues des loaders `moves/items` pouvaient casser l’honnêteté de la surface auteur.

Ce qui a été changé :

- ajout d’un `try/catch` autour du chargement du catalogue moves ;
- ajout d’un `try/catch` autour du chargement du catalogue items ;
- fallback vers `PokemonMovesCatalogView` / `PokemonItemsCatalogView` indisponibles, avec message explicite indiquant que la saisie brute reste possible ;
- commentaires pour documenter l’invariant : la surface trainer doit rester utilisable même si l’assistance locale tombe.

### `packages/map_editor/test/trainer_library_panel_test.dart`

Pourquoi modifié :

- il manquait un test qui prouve la résilience du panel aux erreurs imprévues des lookups `moves/items`.

Ce qui a été changé :

- ajout d’un widget test ciblé couvrant l’échec simultané des loaders `moves` et `items` ;
- extension minimale du fake repository pour pouvoir simuler une erreur de catalogue.

### `reports/phase-r1-lot-7-corrective-audit-report.md`

Pourquoi créé :

- fournir l’audit complet demandé, fondé sur le code réel, avec les preuves d’exécution et l’annexe complète.

## 8. Commandes réellement exécutées

### Audit / lecture

```bash
git status --short
git diff --stat -- packages/map_editor/lib/src/ui/panels/trainer_library_panel.dart packages/map_editor/test/trainer_library_panel_test.dart
git ls-files --others --exclude-standard
find /Users/karim/Project/pokemonProject/packages/map_editor -name AGENTS.md -print
wc -l /Users/karim/Project/pokemonProject/packages/map_editor/lib/src/ui/panels/trainer_library_panel.dart /Users/karim/Project/pokemonProject/packages/map_editor/lib/src/ui/panels/trainer_library_panel_support.dart /Users/karim/Project/pokemonProject/packages/map_editor/lib/src/ui/panels/trainer_library_panel_trainer_widgets.dart /Users/karim/Project/pokemonProject/packages/map_editor/lib/src/ui/panels/trainer_library_panel_pokemon_widgets.dart
cat /Users/karim/Project/pokemonProject/packages/map_editor/lib/src/ui/panels/trainer_library_panel.dart
cat /Users/karim/Project/pokemonProject/packages/map_editor/test/trainer_library_panel_test.dart
```

### Validation

```bash
/Users/karim/develop/flutter/bin/dart format /Users/karim/Project/pokemonProject/packages/map_editor/lib/src/ui/panels/trainer_library_panel.dart /Users/karim/Project/pokemonProject/packages/map_editor/test/trainer_library_panel_test.dart
/Users/karim/develop/flutter/bin/flutter analyze --no-pub lib/src/ui/panels/trainer_library_panel.dart test/trainer_library_panel_test.dart
/Users/karim/develop/flutter/bin/flutter test test/trainer_library_panel_test.dart test/trainer_use_cases_test.dart test/provider_wiring_test.dart test/pokemon_species_lookup_service_test.dart test/load_pokemon_items_catalog_use_case_test.dart test/local_catalog_lookup_service_test.dart test/pokemon_moves_catalog_lookup_service_test.dart test/pokedex_learnset_moves_assist_ui_test.dart test/pokedex_external_batch_execute_ui_test.dart
```

### Restauration de changements accidentels hors scope

Ces commandes n’écrivent pas dans l’historique git. Elles ont uniquement restauré des fichiers de travail modifiés par le tooling Flutter, hors périmètre de cette passe :

```bash
git show HEAD:packages/map_editor/pubspec.lock > /Users/karim/Project/pokemonProject/packages/map_editor/pubspec.lock
git show HEAD:.idea/libraries/Dart_Packages.xml > /Users/karim/Project/pokemonProject/.idea/libraries/Dart_Packages.xml
```

## 9. Résultats réels

### `dart format`

```text
Formatted 2 files (0 changed) in 0.02 seconds.
```

### `flutter analyze --no-pub`

```text
No issues found! (ran in 12.3s)
```

### `flutter test`

```text
00:05 +30: All tests passed!
```

## 10. Incidents rencontrés

1. Le run `flutter test` a modifié `packages/map_editor/pubspec.lock` et `.idea/libraries/Dart_Packages.xml` pendant la résolution de dépendances.
2. Ces changements étaient hors scope et ont été restaurés immédiatement depuis `HEAD` sans aucune écriture d’historique git.
3. Aucun autre incident bloquant n’a été rencontré.

## 11. État git utile

### `git status --short`

```text
 M packages/map_editor/lib/src/ui/panels/trainer_library_panel.dart
 M packages/map_editor/test/trainer_library_panel_test.dart
?? reports/phase-r1-lot-7-corrective-audit-report.md
```

### `git diff --stat`

```text
 .../lib/src/ui/panels/trainer_library_panel.dart   |  30 +++++-
 .../test/trainer_library_panel_test.dart           | 117 +++++++++++++++++++++
 2 files changed, 145 insertions(+), 2 deletions(-)
```

### `git ls-files --others --exclude-standard`

```text
reports/phase-r1-lot-7-corrective-audit-report.md
```

## 12. Checklist finale

- [x] je me suis basé sur le code réel, pas sur le report comme source de vérité
- [x] je n’ai pas créé de stack parallèle
- [x] je n’ai pas transformé cette passe en refonte trainer
- [x] j’ai vérifié si `trainer_library_panel.dart` est réellement redevenu lisible
- [x] j’ai vérifié la cohérence des part files
- [x] j’ai vérifié les resets et transitions de state local
- [x] j’ai vérifié l’honnêteté du support forms
- [x] j’ai vérifié les messages les plus sensibles
- [x] je n’ai touché `EditorNotifier` / `trainer_use_cases` que si nécessaire
- [x] j’ai exécuté `dart format`
- [x] j’ai exécuté `flutter analyze --no-pub`
- [x] j’ai exécuté les tests ciblés utiles
- [x] je n’ai fait aucun commit / merge / rebase / push / tag / stash / amend / reset
- [x] le rapport final markdown a bien été créé
- [x] le rapport contient le contenu complet de tous les fichiers modifiés / créés / supprimés

## 13. Conclusion honnête

Le corrective pass précédent du lot 7 avait déjà fait l’essentiel du travail de maintenabilité. Le code réel ne justifiait pas un nouveau découpage ni une correction de grande ampleur.

Le seul défaut confirmé et corrigé dans cette passe est un défaut d’honnêteté / résilience locale : la surface trainer devait continuer à fonctionner proprement si les lookups `moves` et `items` échouaient de manière imprévue. Ce point est maintenant couvert dans le code et prouvé par test.

Dette locale restante, acceptable à ce stade :

- `trainer_library_panel.dart` reste un gros orchestrateur, mais sa responsabilité est maintenant lisible ;
- le bloc `_buildTrainerTile()` reste dense, sans bug confirmé justifiant une extraction de plus ;
- la surface trainer garde une complexité inhérente à son périmètre, sans qu’un nouveau découpage soit clairement rentable aujourd’hui.

## 14. Annexe — contenu complet des fichiers touchés

Le report n’inclut pas son propre contenu dans cette annexe pour éviter une récursion infinie. En revanche, il inclut en intégralité tous les autres fichiers texte modifiés dans cette passe.

### 14.1 `packages/map_editor/lib/src/ui/panels/trainer_library_panel.dart`

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

    late final PokemonMovesCatalogView movesCatalogView;
    try {
      movesCatalogView = await movesLoader(workspace);
    } catch (error) {
      // The panel should degrade honestly if a loader blows up unexpectedly.
      // We keep the authoring surface usable with raw IDs instead of leaving
      // the future in an error state that the current builder does not render.
      movesCatalogView = PokemonMovesCatalogView(
        entries: const <PokemonMoveCatalogEntryView>[],
        isAvailable: false,
        description: 'Catalogue local des attaques indisponible.',
        message:
            'Impossible de charger le catalogue local des attaques. La saisie brute reste possible.\n$error',
      );
    }

    late final PokemonItemsCatalogView itemsCatalogView;
    try {
      itemsCatalogView = await itemsLoader.execute(workspace);
    } catch (error) {
      itemsCatalogView = PokemonItemsCatalogView(
        entries: const <PokemonItemCatalogEntryView>[],
        isAvailable: false,
        description: 'Catalogue local des objets indisponible.',
        message:
            'Impossible de charger le catalogue local des objets. La saisie brute reste possible.\n$error',
      );
    }

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

### 14.2 `packages/map_editor/test/trainer_library_panel_test.dart`

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

  testWidgets(
      'keeps the trainer surface usable when moves and items lookups fail unexpectedly',
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
          (_) async => throw StateError('moves loader exploded'),
        ),
        pokedexSpeciesDetailLoaderProvider.overrideWithValue(
          (_, speciesId) async =>
              _detailsById[speciesId] ??
              (throw EditorNotFoundException('Missing detail: $speciesId')),
        ),
        loadPokemonItemsCatalogUseCaseProvider.overrideWithValue(
          LoadPokemonItemsCatalogUseCase(
            readRepository: _FakePokemonReadRepository(
              catalogError: StateError('items loader exploded'),
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

    expect(
      find.textContaining(
        'Impossible de charger le catalogue local des attaques.',
      ),
      findsOneWidget,
    );
    expect(
      find.textContaining(
        'Impossible de charger le catalogue local des objets.',
      ),
      findsOneWidget,
    );

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
    await tester.scrollUntilVisible(
      find.byKey(const Key('trainer-library-pokemon-item-field')),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.enterText(
      find.byKey(const Key('trainer-library-pokemon-item-field')),
      'mystery_item',
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

    final savedTrainer =
        container.read(editorNotifierProvider).project!.trainers.single;
    final pokemon = savedTrainer.team.single;
    expect(pokemon.speciesId, 'bulbasaur');
    expect(pokemon.level, 10);
    expect(pokemon.moves, <String>['missing_move']);
    expect(pokemon.heldItemId, 'mystery_item');
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
    this.catalogError,
  });

  final Map<String, PokemonCatalogFile> catalogByKey;
  final Object? catalogError;

  @override
  Future<PokemonCatalogFile> readCatalogByKey(
    ProjectWorkspace workspace,
    String catalogKey,
  ) async {
    if (catalogError != null) {
      throw catalogError!;
    }
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

## 15. Confirmation explicite sur git

Aucune écriture git interdite n’a été faite dans cette passe :

- aucun commit
- aucun amend
- aucun merge
- aucun rebase
- aucun push
- aucun tag
- aucun stash
- aucun reset
