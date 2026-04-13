# Phase R1 — Lot 7 corrective verification report

## 1. Résumé exécutif honnête

Je me suis basé sur le code réel du worktree, pas sur le report précédent. Le constat global est que le corrective pass précédent était **majoritairement juste** :

- `trainer_library_panel.dart` est bien redevenu un orchestrateur raisonnable ;
- le découpage en `part` files est défendable ;
- `EditorNotifier` reste un orchestrateur ;
- `trainer_use_cases.dart` reste métier ;
- le fallback `moves/items` ajouté précédemment est réel et utile ;
- le test widget ajouté pour ce fallback prouve bien le point principal.

En revanche, après audit contradictoire du code actuel, j’ai confirmé **deux petites failles d’honnêteté UI supplémentaires** que le report précédent n’avait pas signalées :

1. la ligne de résumé d’un Pokémon disait toujours `Species absente du Pokédex local.` quand `speciesEntry == null`, même si l’index local des espèces était simplement indisponible ;
2. le bloc `forms` affichait `Aucune suggestion de forme locale disponible...` même dans le cas où on ne pouvait en réalité pas vérifier les formes locales.

J’ai corrigé ces deux points localement, sans réouvrir le lot 7 ni toucher à l’architecture :

- branchement du statut `isSpeciesCatalogAvailable` dans le résumé Pokémon ;
- message forms plus honnête quand l’espèce n’est pas renseignée ou quand la vérification locale ne peut pas être faite ;
- ajout d’un test widget ciblé qui prouve ce comportement.

Je n’ai pas modifié `EditorNotifier` ni `trainer_use_cases.dart`.

## 2. État initial audité réel

Source de vérité utilisée :

- `git status --short`
- `git diff --stat`
- `git diff` ciblé sur les fichiers trainer
- `git ls-files --others --exclude-standard`
- lecture directe des fichiers :
  - `/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/ui/panels/trainer_library_panel.dart`
  - `/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/ui/panels/trainer_library_panel_support.dart`
  - `/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/ui/panels/trainer_library_panel_trainer_widgets.dart`
  - `/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/ui/panels/trainer_library_panel_pokemon_widgets.dart`
  - `/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/features/editor/state/editor_notifier.dart`
  - `/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/application/use_cases/trainer_use_cases.dart`
  - `/Users/karim/Project/pokemonProject/packages/map_editor/test/trainer_library_panel_test.dart`

Constats initiaux :

- le corrective pass précédent avait déjà déplacé le gros du bruit UI dans les `part` files ;
- le diff réel montrait déjà un fallback `moves/items` dans `_loadReferenceData()` ;
- le test `keeps the trainer surface usable when moves and items lookups fail unexpectedly` existait bien ;
- aucune preuve directe n’indiquait un besoin de toucher `EditorNotifier` ou `trainer_use_cases.dart`.

Points encore douteux avant correction :

- honnêteté du message résumé Pokémon quand l’index espèces est indisponible ;
- honnêteté du message `forms` quand la vérification locale est impossible ;
- comportement réel des resets et transitions après corrective pass ;
- exactitude du report précédent sur le fait qu’“aucune autre correction n’était nécessaire”.

## 3. Conclusions détaillées des 5 sous-agents

Je n’ai pas pu ouvrir cinq nouveaux threads, la limite de threads étant atteinte. J’ai donc réutilisé honnêtement les threads existants du workspace, puis complété l’angle manquant avec une relecture locale stricte.

### Sous-agent A — Architecture / scope

Conclusions :

- le corrective pass reste local ;
- `trainer_library_panel.dart` reste bien l’orchestrateur ;
- la séparation en `support / trainer widgets / pokemon widgets` est défendable ;
- aucun nouveau système trainer n’a été introduit ;
- pas de besoin structurel de refactor supplémentaire.

Retenu :

- pas de nouvelle extraction ;
- pas de nouvelle couche ;
- pas de toucher au notifier ni aux use cases.

Rejeté :

- toute refonte structurelle supplémentaire juste pour “baisser les lignes”.

### Sous-agent B — UI maintainability

Conclusions :

- le split en `part` files aide vraiment ;
- les responsabilités sont globalement bien placées ;
- un petit point d’honnêteté UI restait encore sur les messages species/forms ;
- la duplication de binding listeners dans `_TrainerPokemonEditorCardState` existe, mais reste un souci de propreté mineur, pas un bug à corriger dans cette passe.

Retenu :

- corriger les messages species/forms ;
- ne pas toucher à la mécanique de binding listeners sans nécessité comportementale.

Rejeté :

- extraction supplémentaire ou helper de listeners “pour faire plus propre”.

### Sous-agent C — State / behavior reviewer

Conclusions :

- les resets principaux restent cohérents ;
- fermeture sur succès / maintien ouvert sur erreur restent corrects ;
- add/edit/cancel/delete trainer et Pokémon tiennent ;
- un petit point de rétention de draft caché peut subsister sur le formulaire de création trainer quand on bascule vers un autre mode, mais ce n’est pas un bug bloquant et le changer maintenant modifierait une sémantique d’édition sans nécessité directe.

Retenu :

- ne pas toucher aux resets/fermetures.

Rejeté :

- changement du comportement de rétention du draft create trainer dans cette passe.

### Sous-agent D — Product honesty reviewer

Conclusions :

- le fallback `moves/items` est bien corrigé dans le code ;
- le support `forms` n’invente plus `base` ;
- mais deux messages restaient légèrement trompeurs :
  - résumé Pokémon quand l’index espèces est indisponible ;
  - message forms quand la vérification locale est impossible.

Retenu :

- correction locale de ces deux messages/branches.

Rejeté :

- nouveau sous-système de statut forms ;
- enrichissement plus large des messages.

### Sous-agent E — Test matrix reviewer

Conclusions :

- le test `moves/items` couvre bien le bug principal précédent ;
- les non-régressions demandées restent suffisantes ;
- un seul test supplémentaire à forte valeur était utile : prouver l’honnêteté species/forms quand l’assistance espèces n’est pas disponible.

Retenu :

- un test widget ciblé de plus.

Rejeté :

- multiplication de tests décoratifs.

## 4. Problèmes confirmés / non confirmés

### Confirmés

1. Message résumé Pokémon trop affirmatif quand l’index espèces est indisponible.
2. Message forms qui confondait “aucune suggestion” et “impossible de vérifier”.

### Non confirmés

1. Besoin de refactor supplémentaire de `trainer_library_panel.dart`.
2. Besoin de retoucher `trainer_library_panel_support.dart`.
3. Besoin de retoucher `trainer_library_panel_trainer_widgets.dart`.
4. Besoin de modifier `EditorNotifier`.
5. Besoin de modifier `trainer_use_cases.dart`.

## 5. Vérification de la véracité du report précédent

### Ce qui était vrai

- `trainer_library_panel.dart` est bien redevenu un orchestrateur lisible.
- Le split en `part` files est réel et utile.
- Le fallback `moves/items` a bien été implémenté dans `_loadReferenceData()`.
- Le test widget associé existe bien et prouve que la surface trainer reste utilisable malgré des erreurs inattendues `moves/items`.
- Il n’y avait pas de raison directe de toucher `EditorNotifier` ou `trainer_use_cases.dart`.

### Ce qui était approximatif

- Le report précédent laissait entendre qu’aucune autre micro-correction n’était réellement nécessaire. Le code montrait encore deux petits écarts d’honnêteté UI.

### Ce qui était incomplet

- Le report précédent ne signalait pas que :
  - le résumé d’un Pokémon non résolu racontait la mauvaise histoire si l’index espèces était indisponible ;
  - le bloc forms ne distinguait pas “pas de suggestion” et “vérification impossible”.

### Ce qui restait volontairement acceptable

- La rétention potentielle d’un draft create trainer caché lors d’un changement de mode n’a pas été traitée. C’est un point UX discutable, mais le changer ici aurait modifié le comportement d’édition sans bug bloquant confirmé.

## 6. Décisions retenues / rejetées

### Retenues

1. Garder l’architecture trainer telle quelle.
2. Corriger uniquement les deux écarts d’honnêteté UI confirmés.
3. Ajouter un seul test widget ciblé pour prouver ce comportement.

### Rejetées

1. Nouveau découpage de `trainer_library_panel.dart`.
2. Extraction de helpers/listeners supplémentaires.
3. Refactor du cycle de reset create/edit/add Pokémon.
4. Modification d’`EditorNotifier`.
5. Modification de `trainer_use_cases.dart`.

## 7. Liste exacte des fichiers modifiés / créés / supprimés

### Modifiés

- `/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/ui/panels/trainer_library_panel.dart`
- `/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/ui/panels/trainer_library_panel_pokemon_widgets.dart`
- `/Users/karim/Project/pokemonProject/packages/map_editor/test/trainer_library_panel_test.dart`

### Créé

- `/Users/karim/Project/pokemonProject/reports/phase-r1-lot-7-corrective-verification-report.md`

### Non modifiés malgré audit

- `/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/ui/panels/trainer_library_panel_support.dart`
- `/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/ui/panels/trainer_library_panel_trainer_widgets.dart`
- `/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/features/editor/state/editor_notifier.dart`
- `/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/application/use_cases/trainer_use_cases.dart`

### Supprimés

- aucun

## 8. Justification fichier par fichier

### `/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/ui/panels/trainer_library_panel.dart`

Justification :

- le call site de `_TrainerPokemonSummaryRow` devait transmettre l’état réel de disponibilité de l’index espèces ;
- aucun autre changement comportemental n’a été fait dans ce fichier.

### `/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/ui/panels/trainer_library_panel_pokemon_widgets.dart`

Justification :

- corriger le message du résumé Pokémon pour ne pas confondre “espèce absente” et “index indisponible” ;
- corriger le message `forms` pour distinguer :
  - espèce non renseignée ;
  - vérification impossible ;
  - aucune suggestion réelle.

### `/Users/karim/Project/pokemonProject/packages/map_editor/test/trainer_library_panel_test.dart`

Justification :

- ajouter un test widget ciblé qui prouve :
  - le banner espèces indisponibles ;
  - le message forms “impossible de vérifier” ;
  - le maintien de la saisie brute ;
  - le message résumé honnête après sauvegarde.

### `/Users/karim/Project/pokemonProject/reports/phase-r1-lot-7-corrective-verification-report.md`

Justification :

- fournir la trace complète demandée, fondée sur le code réel.

## 9. Commandes réellement exécutées

### Audit git et diff

```bash
git status --short
git diff --stat
git diff -- packages/map_editor/lib/src/ui/panels/trainer_library_panel.dart packages/map_editor/lib/src/ui/panels/trainer_library_panel_support.dart packages/map_editor/lib/src/ui/panels/trainer_library_panel_trainer_widgets.dart packages/map_editor/lib/src/ui/panels/trainer_library_panel_pokemon_widgets.dart packages/map_editor/test/trainer_library_panel_test.dart packages/map_editor/lib/src/features/editor/state/editor_notifier.dart packages/map_editor/lib/src/application/use_cases/trainer_use_cases.dart
git ls-files --others --exclude-standard
```

### Audit code

```bash
sed -n '1,260p' packages/map_editor/lib/src/ui/panels/trainer_library_panel_support.dart
sed -n '1,260p' packages/map_editor/lib/src/ui/panels/trainer_library_panel_trainer_widgets.dart
sed -n '1,360p' packages/map_editor/lib/src/ui/panels/trainer_library_panel_pokemon_widgets.dart
sed -n '360,760p' packages/map_editor/lib/src/ui/panels/trainer_library_panel_pokemon_widgets.dart
sed -n '1,260p' packages/map_editor/lib/src/features/editor/state/editor_notifier.dart
sed -n '1,280p' packages/map_editor/lib/src/application/use_cases/trainer_use_cases.dart
sed -n '260,520p' packages/map_editor/lib/src/application/use_cases/trainer_use_cases.dart
rg -n "_closePokemonEditor|_resetPokemonDraftFields|_closeTrainerEditor|Failed to save trainer Pokémon|Aucune suggestion de forme|Catalogue local des attaques indisponible|Catalogue local des objets indisponible" packages/map_editor/lib/src/ui/panels/trainer_library_panel*.dart packages/map_editor/test/trainer_library_panel_test.dart
cat /Users/karim/Project/pokemonProject/packages/map_editor/lib/src/ui/panels/trainer_library_panel.dart
cat /Users/karim/Project/pokemonProject/packages/map_editor/lib/src/ui/panels/trainer_library_panel_pokemon_widgets.dart
cat /Users/karim/Project/pokemonProject/packages/map_editor/test/trainer_library_panel_test.dart
```

### Validation

```bash
/Users/karim/develop/flutter/bin/dart format /Users/karim/Project/pokemonProject/packages/map_editor/lib/src/ui/panels/trainer_library_panel.dart /Users/karim/Project/pokemonProject/packages/map_editor/lib/src/ui/panels/trainer_library_panel_pokemon_widgets.dart /Users/karim/Project/pokemonProject/packages/map_editor/test/trainer_library_panel_test.dart
/Users/karim/develop/flutter/bin/flutter analyze --no-pub lib/src/ui/panels/trainer_library_panel.dart lib/src/ui/panels/trainer_library_panel_pokemon_widgets.dart test/trainer_library_panel_test.dart
/Users/karim/develop/flutter/bin/flutter test test/trainer_library_panel_test.dart test/trainer_use_cases_test.dart test/provider_wiring_test.dart test/pokemon_species_lookup_service_test.dart test/load_pokemon_items_catalog_use_case_test.dart test/local_catalog_lookup_service_test.dart test/pokemon_moves_catalog_lookup_service_test.dart test/pokedex_learnset_moves_assist_ui_test.dart test/pokedex_external_batch_execute_ui_test.dart
```

## 10. Résultats réels

### `dart format`

```text
Formatted /Users/karim/Project/pokemonProject/packages/map_editor/lib/src/ui/panels/trainer_library_panel_pokemon_widgets.dart
Formatted 3 files (1 changed) in 0.04 seconds.
```

### `flutter analyze --no-pub`

```text
No issues found! (ran in 14.5s)
```

### `flutter test`

```text
00:04 +31: All tests passed!
```

## 11. Incidents rencontrés

1. Le lancement parallèle de `flutter analyze` et `flutter test` a déclenché le startup lock Flutter.
2. Je les ai laissés se sérialiser proprement au lieu de forcer d’autres actions concurrentes.
3. Aucun autre incident bloquant n’a été rencontré.

## 12. État git utile

### `git status --short` final

```text
 M packages/map_editor/lib/src/ui/panels/trainer_library_panel.dart
 M packages/map_editor/lib/src/ui/panels/trainer_library_panel_pokemon_widgets.dart
 M packages/map_editor/test/trainer_library_panel_test.dart
?? reports/phase-r1-lot-7-corrective-audit-report.md
?? reports/phase-r1-lot-7-corrective-verification-report.md
```

### `git diff --stat` sur les fichiers de code touchés

```text
 .../lib/src/ui/panels/trainer_library_panel.dart   |  31 ++-
 .../trainer_library_panel_pokemon_widgets.dart     |  22 +-
 .../test/trainer_library_panel_test.dart           | 225 +++++++++++++++++++++
 3 files changed, 269 insertions(+), 9 deletions(-)
```

### `git ls-files --others --exclude-standard` final

```text
reports/phase-r1-lot-7-corrective-audit-report.md
reports/phase-r1-lot-7-corrective-verification-report.md
```

## 13. Checklist finale

- [x] je me suis basé sur le code réel, pas sur le report comme source de vérité
- [x] je n’ai pas créé de stack parallèle
- [x] je n’ai pas transformé cette passe en refonte trainer
- [x] j’ai vérifié le découpage réel de `trainer_library_panel.dart`
- [x] j’ai vérifié la cohérence des `part` files
- [x] j’ai vérifié le fallback `moves/items`
- [x] j’ai vérifié les resets et transitions de state local
- [x] j’ai revérifié l’honnêteté du support `forms`
- [x] j’ai vérifié les messages les plus sensibles
- [x] je n’ai touché `EditorNotifier` / `trainer_use_cases` que si nécessaire
- [x] j’ai exécuté `dart format`
- [x] j’ai exécuté `flutter analyze --no-pub`
- [x] j’ai exécuté les tests ciblés utiles
- [x] je n’ai fait aucun commit / merge / rebase / push / tag / stash / amend / reset
- [x] le rapport final markdown a bien été créé
- [x] le rapport contient le contenu complet de tous les fichiers modifiés / créés / supprimés

## 14. Conclusion honnête

Le corrective audit précédent était globalement correct, mais il n’était pas totalement exhaustif. Deux petits écarts d’honnêteté UI restaient dans le code réel. Ils sont maintenant corrigés.

Ce que cette passe a réellement amélioré :

- le résumé Pokémon ne raconte plus une fausse absence d’espèce quand l’index local est indisponible ;
- le bloc forms ne confond plus “pas de suggestion” et “impossible de vérifier” ;
- la couverture de test prouve désormais ce comportement.

Ce qui reste volontairement une dette locale acceptable :

- `trainer_library_panel.dart` reste un gros orchestrateur, mais sa responsabilité reste lisible ;
- la duplication interne de binding listeners dans `_TrainerPokemonEditorCardState` reste un petit smell de maintenabilité, pas un bug ;
- la rétention éventuelle d’un draft create trainer masqué n’a pas été modifiée, car le changer ici aurait modifié une sémantique de formulaire sans nécessité directe.

## 15. Annexe — contenu complet de tous les fichiers modifiés / créés / supprimés

Je n’inclus pas le contenu complet de ce report dans sa propre annexe pour éviter une récursion infinie. En revanche, j’inclus intégralement tous les fichiers de code modifiés dans cette passe.

### 15.1 `/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/ui/panels/trainer_library_panel.dart`

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
              isSpeciesCatalogAvailable: references.isSpeciesAvailable,
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

### 15.2 `/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/ui/panels/trainer_library_panel_pokemon_widgets.dart`

```dart
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:macos_ui/macos_ui.dart';
import 'package:map_core/map_core.dart';

part of 'trainer_library_panel.dart';

class _TrainerPokemonSummaryRow extends StatelessWidget {
  const _TrainerPokemonSummaryRow({
    super.key,
    required this.pokemon,
    required this.speciesEntry,
    required this.isSpeciesCatalogAvailable,
    required this.moveCatalogView,
    required this.itemCatalogView,
    required this.onEdit,
    required this.onDelete,
  });

  final ProjectTrainerPokemonEntry pokemon;
  final PokemonDatabaseIndexEntry? speciesEntry;
  final bool isSpeciesCatalogAvailable;
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
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    isSpeciesCatalogAvailable
                        ? 'Species absente du Pokédex local.'
                        : 'Index local des espèces indisponible. La valeur brute est conservée.',
                    style: const TextStyle(
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
                          : widget.speciesController.text.trim().isEmpty
                              ? 'Renseignez une espèce pour vérifier les formes locales.'
                              : detail == null
                                  ? 'Impossible de vérifier les formes locales pour cette espèce. La saisie brute reste possible.'
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

### 15.3 `/Users/karim/Project/pokemonProject/packages/map_editor/test/trainer_library_panel_test.dart`

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
      'keeps species and form messaging honest when local species assistance is unavailable',
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
          (_) async => throw StateError('species loader exploded'),
        ),
        pokedexMovesCatalogLoaderProvider.overrideWithValue(
          (_) async => _movesCatalogView,
        ),
        pokedexSpeciesDetailLoaderProvider.overrideWithValue(
          (_, __) async => throw StateError('detail loader exploded'),
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

    expect(
      find.textContaining(
        'Impossible de charger les espèces locales. La saisie brute reste possible.',
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
    await tester.scrollUntilVisible(
      find.byKey(const Key('trainer-library-pokemon-form-field')),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    expect(
      find.text(
        'Impossible de vérifier les formes locales pour cette espèce. La saisie brute reste possible.',
      ),
      findsOneWidget,
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
      find.text(
        'Index local des espèces indisponible. La valeur brute est conservée.',
      ),
      findsOneWidget,
    );
    final savedTrainer =
        container.read(editorNotifierProvider).project!.trainers.single;
    expect(savedTrainer.team.single.speciesId, 'bulbasaur');
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

## 16. Confirmation explicite sur git

Aucune écriture git interdite n’a été faite :

- aucun commit
- aucun amend
- aucun merge
- aucun rebase
- aucun push
- aucun tag
- aucun stash
- aucun reset
- aucun checkout / switch / cherry-pick
