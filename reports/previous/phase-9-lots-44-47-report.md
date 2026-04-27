# Phase 9 — Lots 44 à 47

## 1. Résumé exécutif honnête

- Lots couverts : 44, 45, 46, 47.
- Lot 44 a été livré en étendant le modèle existant `PlayerPokemon`, qui était déjà le modèle de Pokémon possédé dans la stack de save du repo, plutôt qu’en introduisant un second modèle concurrent `OwnedPokemon`.
- Lot 45 a été livré via le nouveau modèle `TrainerProfile` dans `map_core`.
- Lot 46 a été livré via les nouveaux modèles `Bag` et `BagEntry` dans `map_core`.
- Lot 47 a été livré en étendant l’agrégat existant `SaveData` et le flux de persistance existant `FileGameSaveRepository`, sans créer un second système de save parallèle.
- Le bouton minimal de sauvegarde n’a pas été ajouté : il existait déjà dans `examples/playable_runtime_host/lib/main.dart` et a été explicitement réutilisé comme surface UI minimale honnête.
- `project.json` n’a pas été modifié.
- Aucun lot 48+ n’a été commencé.

## 2. Lots couverts exactement

- Lot 44 — Définir le modèle `OwnedPokemon` : couvert sémantiquement en enrichissant le modèle existant `PlayerPokemon` déjà utilisé par la save/runtime, afin d’éviter un doublon de modèle.
- Lot 45 — Définir le modèle `TrainerProfile` : couvert.
- Lot 46 — Définir le modèle `Bag` : couvert.
- Lot 47 — Définir `SaveGame` et le flux de save simple : couvert via l’extension de `SaveData` et du flux de save existant.

## 3. Périmètre inclus

- Modèles purs sérialisables dans `packages/map_core`.
- Canonicalisation et validation minimale des données de save phase 9.
- Conversion `SaveData <-> GameState`.
- Persistance locale JSON existante dans `packages/map_runtime`.
- Réutilisation de la surface UI runtime existante (`Sauvegarder` / `Charger`) sans UI nouvelle.
- Tests ciblés `map_core`, `map_gameplay`, `map_runtime`.

## 4. Périmètre exclu

- Lots 48 à 51.
- Menu principal du jeu.
- Écran Pokédex in-game.
- Écran Sac.
- Écran Dresseur.
- Autosave.
- Slots de sauvegarde.
- Cloud save.
- Refonte de l’architecture runtime/editor.
- Modification de `project.json`.

## 5. Utilisation réelle des sub-agents

- Tentatives initiales : plusieurs appels `spawn_agent` ont d’abord échoué à cause de la limite de threads (`agent thread limit reached (max 6)`). Des tentatives de `send_input` vers des ids historiques ont aussi échoué (`agent with id ... not found`).
- Sous-agent `Averroes` : audit architecture / placement. Conclusion retenue : `map_core` pour les modèles purs, `map_runtime` pour l’I/O, réutilisation acceptable du bouton existant du host.
- Sous-agent `Archimedes` : review couverture tests. Conclusion retenue : la couverture métier/persistance était solide, pas de nécessité stricte d’ajouter un widget test du host puisque le bouton existant n’a pas été modifié.
- Sous-agent `Chandrasekhar` : review contradictoire. Conclusion retenue : un vrai trou restait dans `FileGameSaveRepository.save`, qui validait les données phase 9 sans écrire la forme normalisée. Ce point a été corrigé.
- Une seule implémentation finale a été conservée. Aucun brouillon ou fichier alternatif n’a été gardé.

## 6. Design retenu

- Le repo possédait déjà une stack de save avec `PlayerPokemon`, `PlayerParty`, `PlayerProgression`, `SaveData`, `GameState`, `gameStateFromSaveData`, `saveDataFromGameState`, `FileGameSaveRepository`, `SaveGameUseCase`, `LoadGameUseCase` et un bouton `Sauvegarder` dans le host runtime.
- Plutôt que de créer des modèles parallèles `OwnedPokemon` / `SaveGame`, la phase 9 a étendu les modèles existants pour couvrir exactement le périmètre demandé.
- `PlayerPokemon` a été enrichi pour porter le contrat du lot 44.
- `TrainerProfile` et `Bag` ont été ajoutés au niveau `map_core` et branchés dans `SaveData` puis `GameState`.
- `FileGameSaveRepository` continue d’écrire le JSON `GameState` complet pour ne pas perdre les champs runtime déjà persistés (`scriptVariables`, `consumedEventIds`, `storyFlags`, etc.), mais il écrit désormais une version normalisée du `GameState` sur les champs phase 9 au lieu d’un état brut seulement validé.
- Le bouton minimal du lot 47 a été considéré comme déjà satisfait par la surface existante du host runtime ; aucun nouvel écran ni nouvelle UI n’a été ajouté.

## 7. Liste exacte des fichiers touchés

### Modifiés
- `packages/map_core/analysis_options.yaml`
- `packages/map_core/lib/src/models/game_state.dart`
- `packages/map_core/lib/src/models/game_state.freezed.dart`
- `packages/map_core/lib/src/models/game_state.g.dart`
- `packages/map_core/lib/src/models/save_data.dart`
- `packages/map_core/lib/src/models/save_data.freezed.dart`
- `packages/map_core/lib/src/models/save_data.g.dart`
- `packages/map_core/lib/src/operations/game_state_persistence.dart`
- `packages/map_core/test/game_state_persistence_test.dart`
- `packages/map_core/test/save_data_test.dart`
- `packages/map_gameplay/test/script_system_integration_test.dart`
- `packages/map_gameplay/test/surf_evaluation_test.dart`
- `packages/map_runtime/lib/src/infrastructure/file_game_save_repository.dart`
- `packages/map_runtime/test/file_game_save_repository_test.dart`

### Créés
- `reports/phase-9-lots-44-47-report.md`

### Supprimés
- Aucun.

### Audités mais non touchés
- `packages/map_core/pubspec.yaml`
- `packages/map_gameplay/pubspec.yaml`
- `packages/map_runtime/pubspec.yaml`
- `packages/map_runtime/lib/src/application/save_game_use_case.dart`
- `packages/map_runtime/lib/src/application/load_game_use_case.dart`
- `packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart`
- `examples/playable_runtime_host/pubspec.yaml`
- `examples/playable_runtime_host/lib/main.dart`

## 8. Justification fichier par fichier

- `packages/map_core/analysis_options.yaml` : ajout d’un ignore package-local pour `invalid_annotation_target`, nécessaire pour analyser proprement le pattern Freezed/JsonSerializable déjà utilisé dans le package.
- `packages/map_core/lib/src/models/save_data.dart` : extension des modèles de save existants pour couvrir les lots 44, 45, 46 et une partie du 47.
- `packages/map_core/lib/src/models/save_data.freezed.dart` : régénéré par `build_runner` après modification des modèles Freezed.
- `packages/map_core/lib/src/models/save_data.g.dart` : régénéré par `build_runner` après modification des modèles JSON.
- `packages/map_core/lib/src/models/game_state.dart` : ajout de `trainerProfile` et `bag` dans l’état runtime sérialisable.
- `packages/map_core/lib/src/models/game_state.freezed.dart` : régénéré par `build_runner`.
- `packages/map_core/lib/src/models/game_state.g.dart` : régénéré par `build_runner`.
- `packages/map_core/lib/src/operations/game_state_persistence.dart` : branchement `SaveData <-> GameState` pour les nouveaux champs et normalisation au passage.
- `packages/map_core/test/save_data_test.dart` : couverture des modèles phase 9 et de leurs invariants.
- `packages/map_core/test/game_state_persistence_test.dart` : couverture du mapping entre `SaveData` et `GameState`.
- `packages/map_gameplay/test/surf_evaluation_test.dart` : adaptation au nouveau contrat `PlayerPokemon` sans casser le gameplay existant.
- `packages/map_gameplay/test/script_system_integration_test.dart` : même adaptation ciblée au nouveau contrat `PlayerPokemon`.
- `packages/map_runtime/lib/src/infrastructure/file_game_save_repository.dart` : correction du point critique relevé par la review contradictoire, pour écrire un `GameState` normalisé sur les champs phase 9 sans perdre les autres champs runtime.
- `packages/map_runtime/test/file_game_save_repository_test.dart` : preuves E2E sur écriture réelle, structure JSON, non-régression `project.json`, canonicalisation écrite et no-write sur erreur nested-validator.
- `reports/phase-9-lots-44-47-report.md` : rapport final complet.

## 9. Commandes réellement exécutées

### Audit
```bash
find /Users/karim/Project/pokemonProject -name AGENTS.md -print
git status --short
git diff --stat
sed -n '1,220p' packages/map_core/pubspec.yaml
sed -n '1,220p' packages/map_runtime/pubspec.yaml
sed -n '1,220p' examples/playable_runtime_host/pubspec.yaml
sed -n '1,320p' packages/map_core/lib/src/models/save_data.dart
sed -n '1,260p' packages/map_core/lib/src/models/game_state.dart
sed -n '1,220p' packages/map_core/lib/src/operations/game_state_persistence.dart
sed -n '1,220p' packages/map_runtime/lib/src/application/save_game_use_case.dart
sed -n '1,220p' packages/map_runtime/lib/src/application/load_game_use_case.dart
sed -n '1,260p' packages/map_runtime/lib/src/infrastructure/file_game_save_repository.dart
sed -n '1,260p' packages/map_runtime/test/file_game_save_repository_test.dart
sed -n '1,260p' examples/playable_runtime_host/lib/main.dart
rg -n 'PlayerPokemon|OwnedPokemon|SaveData|TrainerProfile|BagEntry|Bag\(' packages/map_core packages/map_gameplay packages/map_runtime examples/playable_runtime_host
find examples/playable_runtime_host -maxdepth 3 -type f \( -name '*test.dart' -o -name '*_test.dart' \) -print
rg -n 'invalid_annotation_target|JsonSerializable\(explicitToJson: true\)|analyzer:' -g 'analysis_options.yaml' -g 'analysis_options.yml' -g 'pubspec.yaml' packages/map_core packages/map_runtime /Users/karim/Project/pokemonProject
```

### Codegen
```bash
cd /Users/karim/Project/pokemonProject/packages/map_core && dart run build_runner build --delete-conflicting-outputs
```

### Format
```bash
cd /Users/karim/Project/pokemonProject/packages/map_core && dart format lib/src/models/save_data.dart lib/src/models/game_state.dart lib/src/operations/game_state_persistence.dart test/save_data_test.dart test/game_state_persistence_test.dart
cd /Users/karim/Project/pokemonProject/packages/map_gameplay && dart format test/surf_evaluation_test.dart test/script_system_integration_test.dart
cd /Users/karim/Project/pokemonProject/packages/map_runtime && dart format lib/src/infrastructure/file_game_save_repository.dart test/file_game_save_repository_test.dart
cd /Users/karim/Project/pokemonProject/packages/map_runtime && dart format test/file_game_save_repository_test.dart
cd /Users/karim/Project/pokemonProject/packages/map_core && dart format analysis_options.yaml
```

### Tests
```bash
cd /Users/karim/Project/pokemonProject/packages/map_core && dart test test/save_data_test.dart test/game_state_persistence_test.dart
cd /Users/karim/Project/pokemonProject/packages/map_gameplay && dart test test/surf_evaluation_test.dart test/script_system_integration_test.dart
cd /Users/karim/Project/pokemonProject/packages/map_runtime && flutter test test/file_game_save_repository_test.dart test/playable_map_game_public_getters_test.dart
```

### Analyse
```bash
cd /Users/karim/Project/pokemonProject/packages/map_core && dart analyze lib/src/models/save_data.dart lib/src/models/game_state.dart lib/src/operations/game_state_persistence.dart test/save_data_test.dart test/game_state_persistence_test.dart
cd /Users/karim/Project/pokemonProject/packages/map_gameplay && dart analyze test/surf_evaluation_test.dart test/script_system_integration_test.dart
cd /Users/karim/Project/pokemonProject/packages/map_runtime && flutter analyze --no-pub lib/src/infrastructure/file_game_save_repository.dart test/file_game_save_repository_test.dart test/playable_map_game_public_getters_test.dart
```

### Git lecture seule
```bash
cd /Users/karim/Project/pokemonProject && git status --short
cd /Users/karim/Project/pokemonProject && git diff --stat
cd /Users/karim/Project/pokemonProject && git ls-files --others --exclude-standard -- reports/phase-9-lots-44-47-report.md
```

## 10. Résultats réels

- `find ... AGENTS.md` : seul `/Users/karim/Project/pokemonProject/AGENTS.md` a été trouvé.
- `dart run build_runner build --delete-conflicting-outputs` dans `packages/map_core` : succès ; sortie notable `Built with build_runner in 7s; wrote 21 outputs.` avec warnings de compat de versions, sans échec.
- `dart format` dans `map_core` : `Formatted 5 files (0 changed) in 0.01 seconds.` lors du dernier passage.
- `dart format` dans `map_gameplay` : `Formatted 2 files (0 changed) in 0.01 seconds.` lors du dernier passage.
- `dart format` dans `map_runtime` : `Formatted 2 files (0 changed) in 0.01 seconds.` puis `Formatted 1 file (0 changed) in 0.01 seconds.`
- `dart format analysis_options.yaml` : échec attendu car `dart format` ne formate pas du YAML ; voir section incidents.
- `dart test` dans `map_core` : `All tests passed!`
- `dart test` dans `map_gameplay` : `00:00 +31: All tests passed!`
- `flutter test` dans `map_runtime` : `All tests passed!`
- Première passe runtime plus tôt dans le chantier : échec après une tentative de persister `SaveData` directement, ce qui faisait perdre des champs `GameState` hors phase 9 ; voir incidents.
- `dart analyze` dans `map_gameplay` : `No issues found!`
- Première passe `dart analyze` dans `map_core` : 10 warnings `invalid_annotation_target` sur le pattern Freezed/JsonSerializable, corrigés ensuite via `analysis_options.yaml` package-local.
- Dernière passe `dart analyze` dans `map_core` : `No issues found!`
- Première passe `flutter analyze --no-pub` dans `map_runtime` : infos `prefer_const_constructors` puis warnings `invalid_use_of_protected_member`, corrigés ensuite dans le test.
- Dernière passe `flutter analyze --no-pub` dans `map_runtime` : `No issues found! (ran in 1.0s)`

## 11. Incidents rencontrés

- Tentatives initiales de sub-agents bloquées par la limite de threads ; des tentatives de recyclage de threads existants ont aussi échoué (`agent with id ... not found`). Des sub-agents ont ensuite pu être relancés avec succès.
- Une première implémentation du lot 47 écrivait `SaveData` directement sur disque. Les tests runtime ont révélé que cela supprimait des champs `GameState` existants hors phase 9 (`scriptVariables`, `consumedEventIds`, etc.). Cette approche a été abandonnée.
- La review contradictoire a pointé un vrai trou résiduel : après correction précédente, le repository validait les données phase 9 mais écrivait encore le `GameState` brut au lieu d’un état normalisé. Le flux a été corrigé en reconstruisant un `GameState` normalisé sur les champs phase 9 avant write.
- `dart format analysis_options.yaml` a été lancé par erreur. Aucun impact sur le repo, mais la commande a naturellement échoué car le fichier est en YAML.
- `packages/map_gameplay/.dart_tool/package_config.json` a été temporairement sali par les commandes Dart. Le fichier a été restauré à son état initial et ne fait pas partie du diff final.

## 12. État Git utile final

### git status --short
```text
 M packages/map_core/analysis_options.yaml
 M packages/map_core/lib/src/models/game_state.dart
 M packages/map_core/lib/src/models/game_state.freezed.dart
 M packages/map_core/lib/src/models/game_state.g.dart
 M packages/map_core/lib/src/models/save_data.dart
 M packages/map_core/lib/src/models/save_data.freezed.dart
 M packages/map_core/lib/src/models/save_data.g.dart
 M packages/map_core/lib/src/operations/game_state_persistence.dart
 M packages/map_core/test/game_state_persistence_test.dart
 M packages/map_core/test/save_data_test.dart
 M packages/map_gameplay/test/script_system_integration_test.dart
 M packages/map_gameplay/test/surf_evaluation_test.dart
 M packages/map_runtime/lib/src/infrastructure/file_game_save_repository.dart
 M packages/map_runtime/test/file_game_save_repository_test.dart
?? reports/phase-9-lots-44-47-report.md
```

### git diff --stat
```text
 packages/map_core/analysis_options.yaml            |    4 +
 packages/map_core/lib/src/models/game_state.dart   |    5 +-
 .../lib/src/models/game_state.freezed.dart         |   73 +-
 packages/map_core/lib/src/models/game_state.g.dart |    9 +
 packages/map_core/lib/src/models/save_data.dart    |  272 ++++-
 .../map_core/lib/src/models/save_data.freezed.dart | 1205 ++++++++++++++++++--
 packages/map_core/lib/src/models/save_data.g.dart  |  102 +-
 .../lib/src/operations/game_state_persistence.dart |   23 +-
 .../map_core/test/game_state_persistence_test.dart |   31 +-
 packages/map_core/test/save_data_test.dart         |  187 ++-
 .../test/script_system_integration_test.dart       |   27 +-
 .../map_gameplay/test/surf_evaluation_test.dart    |   31 +-
 .../infrastructure/file_game_save_repository.dart  |   18 +-
 .../test/file_game_save_repository_test.dart       |  163 ++-
 14 files changed, 2002 insertions(+), 148 deletions(-)
```

### git ls-files --others --exclude-standard -- reports/phase-9-lots-44-47-report.md
```text
reports/phase-9-lots-44-47-report.md
```

## 13. Limites restantes

- Aucun nouvel écran phase 10 n’a été commencé.
- Aucun widget test dédié n’a été ajouté dans `examples/playable_runtime_host`, car le bouton `Sauvegarder` existait déjà et n’a pas été modifié dans cette phase ; la preuve forte reste côté persistance/runtime.
- Le nom métier des lots 44 et 47 (`OwnedPokemon`, `SaveGame`) n’a pas été matérialisé par de nouveaux types concurrents. Le repo a été aligné sur son modèle existant (`PlayerPokemon`, `SaveData`) pour éviter un double schéma de save.

## 14. Contenu complet de tous les fichiers touchés

- Le contenu complet du rapport créé est ce document lui-même.

### `packages/map_core/analysis_options.yaml`

```yaml
# This file configures the static analysis results for your project (errors,
# warnings, and lints).
#
# This enables the 'recommended' set of lints from `package:lints`.
# This set helps identify many issues that may lead to problems when running
# or consuming Dart code, and enforces writing Dart using a single, idiomatic
# style and format.
#
# If you want a smaller set of lints you can change this to specify
# 'package:lints/core.yaml'. These are just the most critical lints
# (the recommended set includes the core lints).
# The core lints are also what is used by pub.dev for scoring packages.

include: package:lints/recommended.yaml

analyzer:
  errors:
    invalid_annotation_target: ignore

# Uncomment the following section to specify additional rules.

# linter:
#   rules:
#     - camel_case_types

# analyzer:
#   exclude:
#     - path/to/excluded/files/**

# For more information about the core and recommended set of lints, see
# https://dart.dev/go/core-lints

# For additional information about configuring this file, see
# https://dart.dev/guides/language/analysis-options

```

### `packages/map_core/lib/src/models/game_state.dart`

```dart
import 'package:freezed_annotation/freezed_annotation.dart';

import 'enums.dart';
import 'geometry.dart';
import 'save_data.dart';

part 'game_state.freezed.dart';
part 'game_state.g.dart';

/// Valeur scalaire pour les variables de script.
///
/// Types supportés : bool, int, string.
/// Le double est exclu volontairement pour éviter les problèmes de précision
/// dans les comparaisons de conditions.
@freezed
class ScriptVariableValue with _$ScriptVariableValue {
  const factory ScriptVariableValue.bool(bool value) = ScriptVariableValueBool;
  const factory ScriptVariableValue.int(int value) = ScriptVariableValueInt;
  const factory ScriptVariableValue.string(String value) =
      ScriptVariableValueString;

  factory ScriptVariableValue.fromJson(Map<String, dynamic> json) =>
      _$ScriptVariableValueFromJson(json);
}

/// Collection de variables de script.
///
/// Clés : identifiants alphanumériques (ex: "rival_defeated", "starter_chosen").
/// Valeurs : [ScriptVariableValue] (bool/int/string).
@freezed
class ScriptVariables with _$ScriptVariables {
  @JsonSerializable(explicitToJson: true)
  const factory ScriptVariables({
    @Default({}) Map<String, ScriptVariableValue> values,
  }) = _ScriptVariables;

  factory ScriptVariables.fromJson(Map<String, dynamic> json) =>
      _$ScriptVariablesFromJson(json);
}

/// Flags narratifs / progression.
///
/// Contrairement aux variables, les flags sont purement booléens
/// et représentent des états binaires (accompli / non accompli).
///
/// Exemples : "professor_met", "starter_received", "surf_unlocked".
@freezed
class StoryFlags with _$StoryFlags {
  const factory StoryFlags({
    @Default({}) Set<String> activeFlags,
  }) = _StoryFlags;

  factory StoryFlags.fromJson(Map<String, dynamic> json) =>
      _$StoryFlagsFromJson(json);
}

/// État de partie complet.
///
/// Inclut :
/// - identité de la save
/// - état du monde (map, position, facing)
/// - équipe du joueur
/// - progression (flags, variables, field abilities)
/// - état des événements consommés
///
/// Immutable, sérialisable JSON, indépendant du runtime.
@freezed
class GameState with _$GameState {
  @JsonSerializable(explicitToJson: true)
  const factory GameState({
    /// Identifiant unique de la sauvegarde.
    required String saveId,

    /// Map actuelle du joueur.
    @Default('') String currentMapId,

    /// Position du joueur sur la map.
    @Default(GridPos(x: 0, y: 0)) GridPos playerPosition,

    /// Orientation du joueur.
    @Default(EntityFacing.south) EntityFacing playerFacing,

    /// Mode de déplacement actuel (walk / surf).
    @Default(MovementMode.walk) MovementMode playerMovementMode,

    /// Équipe du joueur.
    @Default(PlayerParty()) PlayerParty party,
    @Default(TrainerProfile(name: 'Player')) TrainerProfile trainerProfile,
    @Default(Bag()) Bag bag,

    /// Progression narrative et capacités.
    @Default(PlayerProgression()) PlayerProgression progression,

    /// Variables de script (int/bool/string).
    @Default(ScriptVariables()) ScriptVariables scriptVariables,

    /// Flags narratifs (booléens).
    @Default(StoryFlags()) StoryFlags storyFlags,

    /// IDs d'événements déjà consommés (objets ramassés, etc.).
    @Default({}) Set<String> consumedEventIds,

    /// Métadonnées internes (timestamp, version, etc.).
    @Default({}) Map<String, String> metadata,
  }) = _GameState;

  factory GameState.fromJson(Map<String, dynamic> json) =>
      _$GameStateFromJson(json);
}

```

### `packages/map_core/lib/src/models/game_state.freezed.dart`

```dart
// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'game_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

ScriptVariableValue _$ScriptVariableValueFromJson(Map<String, dynamic> json) {
  switch (json['runtimeType']) {
    case 'bool':
      return ScriptVariableValueBool.fromJson(json);
    case 'int':
      return ScriptVariableValueInt.fromJson(json);
    case 'string':
      return ScriptVariableValueString.fromJson(json);

    default:
      throw CheckedFromJsonException(json, 'runtimeType', 'ScriptVariableValue',
          'Invalid union type "${json['runtimeType']}"!');
  }
}

/// @nodoc
mixin _$ScriptVariableValue {
  Object get value => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(bool value) bool,
    required TResult Function(int value) int,
    required TResult Function(String value) string,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(bool value)? bool,
    TResult? Function(int value)? int,
    TResult? Function(String value)? string,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(bool value)? bool,
    TResult Function(int value)? int,
    TResult Function(String value)? string,
    required TResult orElse(),
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(ScriptVariableValueBool value) bool,
    required TResult Function(ScriptVariableValueInt value) int,
    required TResult Function(ScriptVariableValueString value) string,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(ScriptVariableValueBool value)? bool,
    TResult? Function(ScriptVariableValueInt value)? int,
    TResult? Function(ScriptVariableValueString value)? string,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(ScriptVariableValueBool value)? bool,
    TResult Function(ScriptVariableValueInt value)? int,
    TResult Function(ScriptVariableValueString value)? string,
    required TResult orElse(),
  }) =>
      throw _privateConstructorUsedError;

  /// Serializes this ScriptVariableValue to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ScriptVariableValueCopyWith<$Res> {
  factory $ScriptVariableValueCopyWith(
          ScriptVariableValue value, $Res Function(ScriptVariableValue) then) =
      _$ScriptVariableValueCopyWithImpl<$Res, ScriptVariableValue>;
}

/// @nodoc
class _$ScriptVariableValueCopyWithImpl<$Res, $Val extends ScriptVariableValue>
    implements $ScriptVariableValueCopyWith<$Res> {
  _$ScriptVariableValueCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ScriptVariableValue
  /// with the given fields replaced by the non-null parameter values.
}

/// @nodoc
abstract class _$$ScriptVariableValueBoolImplCopyWith<$Res> {
  factory _$$ScriptVariableValueBoolImplCopyWith(
          _$ScriptVariableValueBoolImpl value,
          $Res Function(_$ScriptVariableValueBoolImpl) then) =
      __$$ScriptVariableValueBoolImplCopyWithImpl<$Res>;
  @useResult
  $Res call({bool value});
}

/// @nodoc
class __$$ScriptVariableValueBoolImplCopyWithImpl<$Res>
    extends _$ScriptVariableValueCopyWithImpl<$Res,
        _$ScriptVariableValueBoolImpl>
    implements _$$ScriptVariableValueBoolImplCopyWith<$Res> {
  __$$ScriptVariableValueBoolImplCopyWithImpl(
      _$ScriptVariableValueBoolImpl _value,
      $Res Function(_$ScriptVariableValueBoolImpl) _then)
      : super(_value, _then);

  /// Create a copy of ScriptVariableValue
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? value = null,
  }) {
    return _then(_$ScriptVariableValueBoolImpl(
      null == value
          ? _value.value
          : value // ignore: cast_nullable_to_non_nullable
              as bool,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$ScriptVariableValueBoolImpl implements ScriptVariableValueBool {
  const _$ScriptVariableValueBoolImpl(this.value, {final String? $type})
      : $type = $type ?? 'bool';

  factory _$ScriptVariableValueBoolImpl.fromJson(Map<String, dynamic> json) =>
      _$$ScriptVariableValueBoolImplFromJson(json);

  @override
  final bool value;

  @JsonKey(name: 'runtimeType')
  final String $type;

  @override
  String toString() {
    return 'ScriptVariableValue.bool(value: $value)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ScriptVariableValueBoolImpl &&
            (identical(other.value, value) || other.value == value));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, value);

  /// Create a copy of ScriptVariableValue
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ScriptVariableValueBoolImplCopyWith<_$ScriptVariableValueBoolImpl>
      get copyWith => __$$ScriptVariableValueBoolImplCopyWithImpl<
          _$ScriptVariableValueBoolImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(bool value) bool,
    required TResult Function(int value) int,
    required TResult Function(String value) string,
  }) {
    return bool(value);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(bool value)? bool,
    TResult? Function(int value)? int,
    TResult? Function(String value)? string,
  }) {
    return bool?.call(value);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(bool value)? bool,
    TResult Function(int value)? int,
    TResult Function(String value)? string,
    required TResult orElse(),
  }) {
    if (bool != null) {
      return bool(value);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(ScriptVariableValueBool value) bool,
    required TResult Function(ScriptVariableValueInt value) int,
    required TResult Function(ScriptVariableValueString value) string,
  }) {
    return bool(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(ScriptVariableValueBool value)? bool,
    TResult? Function(ScriptVariableValueInt value)? int,
    TResult? Function(ScriptVariableValueString value)? string,
  }) {
    return bool?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(ScriptVariableValueBool value)? bool,
    TResult Function(ScriptVariableValueInt value)? int,
    TResult Function(ScriptVariableValueString value)? string,
    required TResult orElse(),
  }) {
    if (bool != null) {
      return bool(this);
    }
    return orElse();
  }

  @override
  Map<String, dynamic> toJson() {
    return _$$ScriptVariableValueBoolImplToJson(
      this,
    );
  }
}

abstract class ScriptVariableValueBool implements ScriptVariableValue {
  const factory ScriptVariableValueBool(final bool value) =
      _$ScriptVariableValueBoolImpl;

  factory ScriptVariableValueBool.fromJson(Map<String, dynamic> json) =
      _$ScriptVariableValueBoolImpl.fromJson;

  @override
  bool get value;

  /// Create a copy of ScriptVariableValue
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ScriptVariableValueBoolImplCopyWith<_$ScriptVariableValueBoolImpl>
      get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$ScriptVariableValueIntImplCopyWith<$Res> {
  factory _$$ScriptVariableValueIntImplCopyWith(
          _$ScriptVariableValueIntImpl value,
          $Res Function(_$ScriptVariableValueIntImpl) then) =
      __$$ScriptVariableValueIntImplCopyWithImpl<$Res>;
  @useResult
  $Res call({int value});
}

/// @nodoc
class __$$ScriptVariableValueIntImplCopyWithImpl<$Res>
    extends _$ScriptVariableValueCopyWithImpl<$Res,
        _$ScriptVariableValueIntImpl>
    implements _$$ScriptVariableValueIntImplCopyWith<$Res> {
  __$$ScriptVariableValueIntImplCopyWithImpl(
      _$ScriptVariableValueIntImpl _value,
      $Res Function(_$ScriptVariableValueIntImpl) _then)
      : super(_value, _then);

  /// Create a copy of ScriptVariableValue
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? value = null,
  }) {
    return _then(_$ScriptVariableValueIntImpl(
      null == value
          ? _value.value
          : value // ignore: cast_nullable_to_non_nullable
              as int,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$ScriptVariableValueIntImpl implements ScriptVariableValueInt {
  const _$ScriptVariableValueIntImpl(this.value, {final String? $type})
      : $type = $type ?? 'int';

  factory _$ScriptVariableValueIntImpl.fromJson(Map<String, dynamic> json) =>
      _$$ScriptVariableValueIntImplFromJson(json);

  @override
  final int value;

  @JsonKey(name: 'runtimeType')
  final String $type;

  @override
  String toString() {
    return 'ScriptVariableValue.int(value: $value)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ScriptVariableValueIntImpl &&
            (identical(other.value, value) || other.value == value));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, value);

  /// Create a copy of ScriptVariableValue
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ScriptVariableValueIntImplCopyWith<_$ScriptVariableValueIntImpl>
      get copyWith => __$$ScriptVariableValueIntImplCopyWithImpl<
          _$ScriptVariableValueIntImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(bool value) bool,
    required TResult Function(int value) int,
    required TResult Function(String value) string,
  }) {
    return int(value);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(bool value)? bool,
    TResult? Function(int value)? int,
    TResult? Function(String value)? string,
  }) {
    return int?.call(value);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(bool value)? bool,
    TResult Function(int value)? int,
    TResult Function(String value)? string,
    required TResult orElse(),
  }) {
    if (int != null) {
      return int(value);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(ScriptVariableValueBool value) bool,
    required TResult Function(ScriptVariableValueInt value) int,
    required TResult Function(ScriptVariableValueString value) string,
  }) {
    return int(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(ScriptVariableValueBool value)? bool,
    TResult? Function(ScriptVariableValueInt value)? int,
    TResult? Function(ScriptVariableValueString value)? string,
  }) {
    return int?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(ScriptVariableValueBool value)? bool,
    TResult Function(ScriptVariableValueInt value)? int,
    TResult Function(ScriptVariableValueString value)? string,
    required TResult orElse(),
  }) {
    if (int != null) {
      return int(this);
    }
    return orElse();
  }

  @override
  Map<String, dynamic> toJson() {
    return _$$ScriptVariableValueIntImplToJson(
      this,
    );
  }
}

abstract class ScriptVariableValueInt implements ScriptVariableValue {
  const factory ScriptVariableValueInt(final int value) =
      _$ScriptVariableValueIntImpl;

  factory ScriptVariableValueInt.fromJson(Map<String, dynamic> json) =
      _$ScriptVariableValueIntImpl.fromJson;

  @override
  int get value;

  /// Create a copy of ScriptVariableValue
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ScriptVariableValueIntImplCopyWith<_$ScriptVariableValueIntImpl>
      get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$ScriptVariableValueStringImplCopyWith<$Res> {
  factory _$$ScriptVariableValueStringImplCopyWith(
          _$ScriptVariableValueStringImpl value,
          $Res Function(_$ScriptVariableValueStringImpl) then) =
      __$$ScriptVariableValueStringImplCopyWithImpl<$Res>;
  @useResult
  $Res call({String value});
}

/// @nodoc
class __$$ScriptVariableValueStringImplCopyWithImpl<$Res>
    extends _$ScriptVariableValueCopyWithImpl<$Res,
        _$ScriptVariableValueStringImpl>
    implements _$$ScriptVariableValueStringImplCopyWith<$Res> {
  __$$ScriptVariableValueStringImplCopyWithImpl(
      _$ScriptVariableValueStringImpl _value,
      $Res Function(_$ScriptVariableValueStringImpl) _then)
      : super(_value, _then);

  /// Create a copy of ScriptVariableValue
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? value = null,
  }) {
    return _then(_$ScriptVariableValueStringImpl(
      null == value
          ? _value.value
          : value // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$ScriptVariableValueStringImpl implements ScriptVariableValueString {
  const _$ScriptVariableValueStringImpl(this.value, {final String? $type})
      : $type = $type ?? 'string';

  factory _$ScriptVariableValueStringImpl.fromJson(Map<String, dynamic> json) =>
      _$$ScriptVariableValueStringImplFromJson(json);

  @override
  final String value;

  @JsonKey(name: 'runtimeType')
  final String $type;

  @override
  String toString() {
    return 'ScriptVariableValue.string(value: $value)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ScriptVariableValueStringImpl &&
            (identical(other.value, value) || other.value == value));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, value);

  /// Create a copy of ScriptVariableValue
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ScriptVariableValueStringImplCopyWith<_$ScriptVariableValueStringImpl>
      get copyWith => __$$ScriptVariableValueStringImplCopyWithImpl<
          _$ScriptVariableValueStringImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(bool value) bool,
    required TResult Function(int value) int,
    required TResult Function(String value) string,
  }) {
    return string(value);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(bool value)? bool,
    TResult? Function(int value)? int,
    TResult? Function(String value)? string,
  }) {
    return string?.call(value);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(bool value)? bool,
    TResult Function(int value)? int,
    TResult Function(String value)? string,
    required TResult orElse(),
  }) {
    if (string != null) {
      return string(value);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(ScriptVariableValueBool value) bool,
    required TResult Function(ScriptVariableValueInt value) int,
    required TResult Function(ScriptVariableValueString value) string,
  }) {
    return string(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(ScriptVariableValueBool value)? bool,
    TResult? Function(ScriptVariableValueInt value)? int,
    TResult? Function(ScriptVariableValueString value)? string,
  }) {
    return string?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(ScriptVariableValueBool value)? bool,
    TResult Function(ScriptVariableValueInt value)? int,
    TResult Function(ScriptVariableValueString value)? string,
    required TResult orElse(),
  }) {
    if (string != null) {
      return string(this);
    }
    return orElse();
  }

  @override
  Map<String, dynamic> toJson() {
    return _$$ScriptVariableValueStringImplToJson(
      this,
    );
  }
}

abstract class ScriptVariableValueString implements ScriptVariableValue {
  const factory ScriptVariableValueString(final String value) =
      _$ScriptVariableValueStringImpl;

  factory ScriptVariableValueString.fromJson(Map<String, dynamic> json) =
      _$ScriptVariableValueStringImpl.fromJson;

  @override
  String get value;

  /// Create a copy of ScriptVariableValue
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ScriptVariableValueStringImplCopyWith<_$ScriptVariableValueStringImpl>
      get copyWith => throw _privateConstructorUsedError;
}

ScriptVariables _$ScriptVariablesFromJson(Map<String, dynamic> json) {
  return _ScriptVariables.fromJson(json);
}

/// @nodoc
mixin _$ScriptVariables {
  Map<String, ScriptVariableValue> get values =>
      throw _privateConstructorUsedError;

  /// Serializes this ScriptVariables to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of ScriptVariables
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ScriptVariablesCopyWith<ScriptVariables> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ScriptVariablesCopyWith<$Res> {
  factory $ScriptVariablesCopyWith(
          ScriptVariables value, $Res Function(ScriptVariables) then) =
      _$ScriptVariablesCopyWithImpl<$Res, ScriptVariables>;
  @useResult
  $Res call({Map<String, ScriptVariableValue> values});
}

/// @nodoc
class _$ScriptVariablesCopyWithImpl<$Res, $Val extends ScriptVariables>
    implements $ScriptVariablesCopyWith<$Res> {
  _$ScriptVariablesCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ScriptVariables
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? values = null,
  }) {
    return _then(_value.copyWith(
      values: null == values
          ? _value.values
          : values // ignore: cast_nullable_to_non_nullable
              as Map<String, ScriptVariableValue>,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$ScriptVariablesImplCopyWith<$Res>
    implements $ScriptVariablesCopyWith<$Res> {
  factory _$$ScriptVariablesImplCopyWith(_$ScriptVariablesImpl value,
          $Res Function(_$ScriptVariablesImpl) then) =
      __$$ScriptVariablesImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({Map<String, ScriptVariableValue> values});
}

/// @nodoc
class __$$ScriptVariablesImplCopyWithImpl<$Res>
    extends _$ScriptVariablesCopyWithImpl<$Res, _$ScriptVariablesImpl>
    implements _$$ScriptVariablesImplCopyWith<$Res> {
  __$$ScriptVariablesImplCopyWithImpl(
      _$ScriptVariablesImpl _value, $Res Function(_$ScriptVariablesImpl) _then)
      : super(_value, _then);

  /// Create a copy of ScriptVariables
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? values = null,
  }) {
    return _then(_$ScriptVariablesImpl(
      values: null == values
          ? _value._values
          : values // ignore: cast_nullable_to_non_nullable
              as Map<String, ScriptVariableValue>,
    ));
  }
}

/// @nodoc

@JsonSerializable(explicitToJson: true)
class _$ScriptVariablesImpl implements _ScriptVariables {
  const _$ScriptVariablesImpl(
      {final Map<String, ScriptVariableValue> values = const {}})
      : _values = values;

  factory _$ScriptVariablesImpl.fromJson(Map<String, dynamic> json) =>
      _$$ScriptVariablesImplFromJson(json);

  final Map<String, ScriptVariableValue> _values;
  @override
  @JsonKey()
  Map<String, ScriptVariableValue> get values {
    if (_values is EqualUnmodifiableMapView) return _values;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_values);
  }

  @override
  String toString() {
    return 'ScriptVariables(values: $values)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ScriptVariablesImpl &&
            const DeepCollectionEquality().equals(other._values, _values));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, const DeepCollectionEquality().hash(_values));

  /// Create a copy of ScriptVariables
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ScriptVariablesImplCopyWith<_$ScriptVariablesImpl> get copyWith =>
      __$$ScriptVariablesImplCopyWithImpl<_$ScriptVariablesImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ScriptVariablesImplToJson(
      this,
    );
  }
}

abstract class _ScriptVariables implements ScriptVariables {
  const factory _ScriptVariables(
      {final Map<String, ScriptVariableValue> values}) = _$ScriptVariablesImpl;

  factory _ScriptVariables.fromJson(Map<String, dynamic> json) =
      _$ScriptVariablesImpl.fromJson;

  @override
  Map<String, ScriptVariableValue> get values;

  /// Create a copy of ScriptVariables
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ScriptVariablesImplCopyWith<_$ScriptVariablesImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

StoryFlags _$StoryFlagsFromJson(Map<String, dynamic> json) {
  return _StoryFlags.fromJson(json);
}

/// @nodoc
mixin _$StoryFlags {
  Set<String> get activeFlags => throw _privateConstructorUsedError;

  /// Serializes this StoryFlags to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of StoryFlags
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $StoryFlagsCopyWith<StoryFlags> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $StoryFlagsCopyWith<$Res> {
  factory $StoryFlagsCopyWith(
          StoryFlags value, $Res Function(StoryFlags) then) =
      _$StoryFlagsCopyWithImpl<$Res, StoryFlags>;
  @useResult
  $Res call({Set<String> activeFlags});
}

/// @nodoc
class _$StoryFlagsCopyWithImpl<$Res, $Val extends StoryFlags>
    implements $StoryFlagsCopyWith<$Res> {
  _$StoryFlagsCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of StoryFlags
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? activeFlags = null,
  }) {
    return _then(_value.copyWith(
      activeFlags: null == activeFlags
          ? _value.activeFlags
          : activeFlags // ignore: cast_nullable_to_non_nullable
              as Set<String>,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$StoryFlagsImplCopyWith<$Res>
    implements $StoryFlagsCopyWith<$Res> {
  factory _$$StoryFlagsImplCopyWith(
          _$StoryFlagsImpl value, $Res Function(_$StoryFlagsImpl) then) =
      __$$StoryFlagsImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({Set<String> activeFlags});
}

/// @nodoc
class __$$StoryFlagsImplCopyWithImpl<$Res>
    extends _$StoryFlagsCopyWithImpl<$Res, _$StoryFlagsImpl>
    implements _$$StoryFlagsImplCopyWith<$Res> {
  __$$StoryFlagsImplCopyWithImpl(
      _$StoryFlagsImpl _value, $Res Function(_$StoryFlagsImpl) _then)
      : super(_value, _then);

  /// Create a copy of StoryFlags
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? activeFlags = null,
  }) {
    return _then(_$StoryFlagsImpl(
      activeFlags: null == activeFlags
          ? _value._activeFlags
          : activeFlags // ignore: cast_nullable_to_non_nullable
              as Set<String>,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$StoryFlagsImpl implements _StoryFlags {
  const _$StoryFlagsImpl({final Set<String> activeFlags = const {}})
      : _activeFlags = activeFlags;

  factory _$StoryFlagsImpl.fromJson(Map<String, dynamic> json) =>
      _$$StoryFlagsImplFromJson(json);

  final Set<String> _activeFlags;
  @override
  @JsonKey()
  Set<String> get activeFlags {
    if (_activeFlags is EqualUnmodifiableSetView) return _activeFlags;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableSetView(_activeFlags);
  }

  @override
  String toString() {
    return 'StoryFlags(activeFlags: $activeFlags)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$StoryFlagsImpl &&
            const DeepCollectionEquality()
                .equals(other._activeFlags, _activeFlags));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType, const DeepCollectionEquality().hash(_activeFlags));

  /// Create a copy of StoryFlags
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$StoryFlagsImplCopyWith<_$StoryFlagsImpl> get copyWith =>
      __$$StoryFlagsImplCopyWithImpl<_$StoryFlagsImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$StoryFlagsImplToJson(
      this,
    );
  }
}

abstract class _StoryFlags implements StoryFlags {
  const factory _StoryFlags({final Set<String> activeFlags}) = _$StoryFlagsImpl;

  factory _StoryFlags.fromJson(Map<String, dynamic> json) =
      _$StoryFlagsImpl.fromJson;

  @override
  Set<String> get activeFlags;

  /// Create a copy of StoryFlags
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$StoryFlagsImplCopyWith<_$StoryFlagsImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

GameState _$GameStateFromJson(Map<String, dynamic> json) {
  return _GameState.fromJson(json);
}

/// @nodoc
mixin _$GameState {
  /// Identifiant unique de la sauvegarde.
  String get saveId => throw _privateConstructorUsedError;

  /// Map actuelle du joueur.
  String get currentMapId => throw _privateConstructorUsedError;

  /// Position du joueur sur la map.
  GridPos get playerPosition => throw _privateConstructorUsedError;

  /// Orientation du joueur.
  EntityFacing get playerFacing => throw _privateConstructorUsedError;

  /// Mode de déplacement actuel (walk / surf).
  MovementMode get playerMovementMode => throw _privateConstructorUsedError;

  /// Équipe du joueur.
  PlayerParty get party => throw _privateConstructorUsedError;
  TrainerProfile get trainerProfile => throw _privateConstructorUsedError;
  Bag get bag => throw _privateConstructorUsedError;

  /// Progression narrative et capacités.
  PlayerProgression get progression => throw _privateConstructorUsedError;

  /// Variables de script (int/bool/string).
  ScriptVariables get scriptVariables => throw _privateConstructorUsedError;

  /// Flags narratifs (booléens).
  StoryFlags get storyFlags => throw _privateConstructorUsedError;

  /// IDs d'événements déjà consommés (objets ramassés, etc.).
  Set<String> get consumedEventIds => throw _privateConstructorUsedError;

  /// Métadonnées internes (timestamp, version, etc.).
  Map<String, String> get metadata => throw _privateConstructorUsedError;

  /// Serializes this GameState to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of GameState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $GameStateCopyWith<GameState> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $GameStateCopyWith<$Res> {
  factory $GameStateCopyWith(GameState value, $Res Function(GameState) then) =
      _$GameStateCopyWithImpl<$Res, GameState>;
  @useResult
  $Res call(
      {String saveId,
      String currentMapId,
      GridPos playerPosition,
      EntityFacing playerFacing,
      MovementMode playerMovementMode,
      PlayerParty party,
      TrainerProfile trainerProfile,
      Bag bag,
      PlayerProgression progression,
      ScriptVariables scriptVariables,
      StoryFlags storyFlags,
      Set<String> consumedEventIds,
      Map<String, String> metadata});

  $GridPosCopyWith<$Res> get playerPosition;
  $PlayerPartyCopyWith<$Res> get party;
  $TrainerProfileCopyWith<$Res> get trainerProfile;
  $BagCopyWith<$Res> get bag;
  $PlayerProgressionCopyWith<$Res> get progression;
  $ScriptVariablesCopyWith<$Res> get scriptVariables;
  $StoryFlagsCopyWith<$Res> get storyFlags;
}

/// @nodoc
class _$GameStateCopyWithImpl<$Res, $Val extends GameState>
    implements $GameStateCopyWith<$Res> {
  _$GameStateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of GameState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? saveId = null,
    Object? currentMapId = null,
    Object? playerPosition = null,
    Object? playerFacing = null,
    Object? playerMovementMode = null,
    Object? party = null,
    Object? trainerProfile = null,
    Object? bag = null,
    Object? progression = null,
    Object? scriptVariables = null,
    Object? storyFlags = null,
    Object? consumedEventIds = null,
    Object? metadata = null,
  }) {
    return _then(_value.copyWith(
      saveId: null == saveId
          ? _value.saveId
          : saveId // ignore: cast_nullable_to_non_nullable
              as String,
      currentMapId: null == currentMapId
          ? _value.currentMapId
          : currentMapId // ignore: cast_nullable_to_non_nullable
              as String,
      playerPosition: null == playerPosition
          ? _value.playerPosition
          : playerPosition // ignore: cast_nullable_to_non_nullable
              as GridPos,
      playerFacing: null == playerFacing
          ? _value.playerFacing
          : playerFacing // ignore: cast_nullable_to_non_nullable
              as EntityFacing,
      playerMovementMode: null == playerMovementMode
          ? _value.playerMovementMode
          : playerMovementMode // ignore: cast_nullable_to_non_nullable
              as MovementMode,
      party: null == party
          ? _value.party
          : party // ignore: cast_nullable_to_non_nullable
              as PlayerParty,
      trainerProfile: null == trainerProfile
          ? _value.trainerProfile
          : trainerProfile // ignore: cast_nullable_to_non_nullable
              as TrainerProfile,
      bag: null == bag
          ? _value.bag
          : bag // ignore: cast_nullable_to_non_nullable
              as Bag,
      progression: null == progression
          ? _value.progression
          : progression // ignore: cast_nullable_to_non_nullable
              as PlayerProgression,
      scriptVariables: null == scriptVariables
          ? _value.scriptVariables
          : scriptVariables // ignore: cast_nullable_to_non_nullable
              as ScriptVariables,
      storyFlags: null == storyFlags
          ? _value.storyFlags
          : storyFlags // ignore: cast_nullable_to_non_nullable
              as StoryFlags,
      consumedEventIds: null == consumedEventIds
          ? _value.consumedEventIds
          : consumedEventIds // ignore: cast_nullable_to_non_nullable
              as Set<String>,
      metadata: null == metadata
          ? _value.metadata
          : metadata // ignore: cast_nullable_to_non_nullable
              as Map<String, String>,
    ) as $Val);
  }

  /// Create a copy of GameState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $GridPosCopyWith<$Res> get playerPosition {
    return $GridPosCopyWith<$Res>(_value.playerPosition, (value) {
      return _then(_value.copyWith(playerPosition: value) as $Val);
    });
  }

  /// Create a copy of GameState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $PlayerPartyCopyWith<$Res> get party {
    return $PlayerPartyCopyWith<$Res>(_value.party, (value) {
      return _then(_value.copyWith(party: value) as $Val);
    });
  }

  /// Create a copy of GameState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $TrainerProfileCopyWith<$Res> get trainerProfile {
    return $TrainerProfileCopyWith<$Res>(_value.trainerProfile, (value) {
      return _then(_value.copyWith(trainerProfile: value) as $Val);
    });
  }

  /// Create a copy of GameState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $BagCopyWith<$Res> get bag {
    return $BagCopyWith<$Res>(_value.bag, (value) {
      return _then(_value.copyWith(bag: value) as $Val);
    });
  }

  /// Create a copy of GameState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $PlayerProgressionCopyWith<$Res> get progression {
    return $PlayerProgressionCopyWith<$Res>(_value.progression, (value) {
      return _then(_value.copyWith(progression: value) as $Val);
    });
  }

  /// Create a copy of GameState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $ScriptVariablesCopyWith<$Res> get scriptVariables {
    return $ScriptVariablesCopyWith<$Res>(_value.scriptVariables, (value) {
      return _then(_value.copyWith(scriptVariables: value) as $Val);
    });
  }

  /// Create a copy of GameState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $StoryFlagsCopyWith<$Res> get storyFlags {
    return $StoryFlagsCopyWith<$Res>(_value.storyFlags, (value) {
      return _then(_value.copyWith(storyFlags: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$GameStateImplCopyWith<$Res>
    implements $GameStateCopyWith<$Res> {
  factory _$$GameStateImplCopyWith(
          _$GameStateImpl value, $Res Function(_$GameStateImpl) then) =
      __$$GameStateImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String saveId,
      String currentMapId,
      GridPos playerPosition,
      EntityFacing playerFacing,
      MovementMode playerMovementMode,
      PlayerParty party,
      TrainerProfile trainerProfile,
      Bag bag,
      PlayerProgression progression,
      ScriptVariables scriptVariables,
      StoryFlags storyFlags,
      Set<String> consumedEventIds,
      Map<String, String> metadata});

  @override
  $GridPosCopyWith<$Res> get playerPosition;
  @override
  $PlayerPartyCopyWith<$Res> get party;
  @override
  $TrainerProfileCopyWith<$Res> get trainerProfile;
  @override
  $BagCopyWith<$Res> get bag;
  @override
  $PlayerProgressionCopyWith<$Res> get progression;
  @override
  $ScriptVariablesCopyWith<$Res> get scriptVariables;
  @override
  $StoryFlagsCopyWith<$Res> get storyFlags;
}

/// @nodoc
class __$$GameStateImplCopyWithImpl<$Res>
    extends _$GameStateCopyWithImpl<$Res, _$GameStateImpl>
    implements _$$GameStateImplCopyWith<$Res> {
  __$$GameStateImplCopyWithImpl(
      _$GameStateImpl _value, $Res Function(_$GameStateImpl) _then)
      : super(_value, _then);

  /// Create a copy of GameState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? saveId = null,
    Object? currentMapId = null,
    Object? playerPosition = null,
    Object? playerFacing = null,
    Object? playerMovementMode = null,
    Object? party = null,
    Object? trainerProfile = null,
    Object? bag = null,
    Object? progression = null,
    Object? scriptVariables = null,
    Object? storyFlags = null,
    Object? consumedEventIds = null,
    Object? metadata = null,
  }) {
    return _then(_$GameStateImpl(
      saveId: null == saveId
          ? _value.saveId
          : saveId // ignore: cast_nullable_to_non_nullable
              as String,
      currentMapId: null == currentMapId
          ? _value.currentMapId
          : currentMapId // ignore: cast_nullable_to_non_nullable
              as String,
      playerPosition: null == playerPosition
          ? _value.playerPosition
          : playerPosition // ignore: cast_nullable_to_non_nullable
              as GridPos,
      playerFacing: null == playerFacing
          ? _value.playerFacing
          : playerFacing // ignore: cast_nullable_to_non_nullable
              as EntityFacing,
      playerMovementMode: null == playerMovementMode
          ? _value.playerMovementMode
          : playerMovementMode // ignore: cast_nullable_to_non_nullable
              as MovementMode,
      party: null == party
          ? _value.party
          : party // ignore: cast_nullable_to_non_nullable
              as PlayerParty,
      trainerProfile: null == trainerProfile
          ? _value.trainerProfile
          : trainerProfile // ignore: cast_nullable_to_non_nullable
              as TrainerProfile,
      bag: null == bag
          ? _value.bag
          : bag // ignore: cast_nullable_to_non_nullable
              as Bag,
      progression: null == progression
          ? _value.progression
          : progression // ignore: cast_nullable_to_non_nullable
              as PlayerProgression,
      scriptVariables: null == scriptVariables
          ? _value.scriptVariables
          : scriptVariables // ignore: cast_nullable_to_non_nullable
              as ScriptVariables,
      storyFlags: null == storyFlags
          ? _value.storyFlags
          : storyFlags // ignore: cast_nullable_to_non_nullable
              as StoryFlags,
      consumedEventIds: null == consumedEventIds
          ? _value._consumedEventIds
          : consumedEventIds // ignore: cast_nullable_to_non_nullable
              as Set<String>,
      metadata: null == metadata
          ? _value._metadata
          : metadata // ignore: cast_nullable_to_non_nullable
              as Map<String, String>,
    ));
  }
}

/// @nodoc

@JsonSerializable(explicitToJson: true)
class _$GameStateImpl implements _GameState {
  const _$GameStateImpl(
      {required this.saveId,
      this.currentMapId = '',
      this.playerPosition = const GridPos(x: 0, y: 0),
      this.playerFacing = EntityFacing.south,
      this.playerMovementMode = MovementMode.walk,
      this.party = const PlayerParty(),
      this.trainerProfile = const TrainerProfile(name: 'Player'),
      this.bag = const Bag(),
      this.progression = const PlayerProgression(),
      this.scriptVariables = const ScriptVariables(),
      this.storyFlags = const StoryFlags(),
      final Set<String> consumedEventIds = const {},
      final Map<String, String> metadata = const {}})
      : _consumedEventIds = consumedEventIds,
        _metadata = metadata;

  factory _$GameStateImpl.fromJson(Map<String, dynamic> json) =>
      _$$GameStateImplFromJson(json);

  /// Identifiant unique de la sauvegarde.
  @override
  final String saveId;

  /// Map actuelle du joueur.
  @override
  @JsonKey()
  final String currentMapId;

  /// Position du joueur sur la map.
  @override
  @JsonKey()
  final GridPos playerPosition;

  /// Orientation du joueur.
  @override
  @JsonKey()
  final EntityFacing playerFacing;

  /// Mode de déplacement actuel (walk / surf).
  @override
  @JsonKey()
  final MovementMode playerMovementMode;

  /// Équipe du joueur.
  @override
  @JsonKey()
  final PlayerParty party;
  @override
  @JsonKey()
  final TrainerProfile trainerProfile;
  @override
  @JsonKey()
  final Bag bag;

  /// Progression narrative et capacités.
  @override
  @JsonKey()
  final PlayerProgression progression;

  /// Variables de script (int/bool/string).
  @override
  @JsonKey()
  final ScriptVariables scriptVariables;

  /// Flags narratifs (booléens).
  @override
  @JsonKey()
  final StoryFlags storyFlags;

  /// IDs d'événements déjà consommés (objets ramassés, etc.).
  final Set<String> _consumedEventIds;

  /// IDs d'événements déjà consommés (objets ramassés, etc.).
  @override
  @JsonKey()
  Set<String> get consumedEventIds {
    if (_consumedEventIds is EqualUnmodifiableSetView) return _consumedEventIds;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableSetView(_consumedEventIds);
  }

  /// Métadonnées internes (timestamp, version, etc.).
  final Map<String, String> _metadata;

  /// Métadonnées internes (timestamp, version, etc.).
  @override
  @JsonKey()
  Map<String, String> get metadata {
    if (_metadata is EqualUnmodifiableMapView) return _metadata;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_metadata);
  }

  @override
  String toString() {
    return 'GameState(saveId: $saveId, currentMapId: $currentMapId, playerPosition: $playerPosition, playerFacing: $playerFacing, playerMovementMode: $playerMovementMode, party: $party, trainerProfile: $trainerProfile, bag: $bag, progression: $progression, scriptVariables: $scriptVariables, storyFlags: $storyFlags, consumedEventIds: $consumedEventIds, metadata: $metadata)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$GameStateImpl &&
            (identical(other.saveId, saveId) || other.saveId == saveId) &&
            (identical(other.currentMapId, currentMapId) ||
                other.currentMapId == currentMapId) &&
            (identical(other.playerPosition, playerPosition) ||
                other.playerPosition == playerPosition) &&
            (identical(other.playerFacing, playerFacing) ||
                other.playerFacing == playerFacing) &&
            (identical(other.playerMovementMode, playerMovementMode) ||
                other.playerMovementMode == playerMovementMode) &&
            (identical(other.party, party) || other.party == party) &&
            (identical(other.trainerProfile, trainerProfile) ||
                other.trainerProfile == trainerProfile) &&
            (identical(other.bag, bag) || other.bag == bag) &&
            (identical(other.progression, progression) ||
                other.progression == progression) &&
            (identical(other.scriptVariables, scriptVariables) ||
                other.scriptVariables == scriptVariables) &&
            (identical(other.storyFlags, storyFlags) ||
                other.storyFlags == storyFlags) &&
            const DeepCollectionEquality()
                .equals(other._consumedEventIds, _consumedEventIds) &&
            const DeepCollectionEquality().equals(other._metadata, _metadata));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      saveId,
      currentMapId,
      playerPosition,
      playerFacing,
      playerMovementMode,
      party,
      trainerProfile,
      bag,
      progression,
      scriptVariables,
      storyFlags,
      const DeepCollectionEquality().hash(_consumedEventIds),
      const DeepCollectionEquality().hash(_metadata));

  /// Create a copy of GameState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$GameStateImplCopyWith<_$GameStateImpl> get copyWith =>
      __$$GameStateImplCopyWithImpl<_$GameStateImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$GameStateImplToJson(
      this,
    );
  }
}

abstract class _GameState implements GameState {
  const factory _GameState(
      {required final String saveId,
      final String currentMapId,
      final GridPos playerPosition,
      final EntityFacing playerFacing,
      final MovementMode playerMovementMode,
      final PlayerParty party,
      final TrainerProfile trainerProfile,
      final Bag bag,
      final PlayerProgression progression,
      final ScriptVariables scriptVariables,
      final StoryFlags storyFlags,
      final Set<String> consumedEventIds,
      final Map<String, String> metadata}) = _$GameStateImpl;

  factory _GameState.fromJson(Map<String, dynamic> json) =
      _$GameStateImpl.fromJson;

  /// Identifiant unique de la sauvegarde.
  @override
  String get saveId;

  /// Map actuelle du joueur.
  @override
  String get currentMapId;

  /// Position du joueur sur la map.
  @override
  GridPos get playerPosition;

  /// Orientation du joueur.
  @override
  EntityFacing get playerFacing;

  /// Mode de déplacement actuel (walk / surf).
  @override
  MovementMode get playerMovementMode;

  /// Équipe du joueur.
  @override
  PlayerParty get party;
  @override
  TrainerProfile get trainerProfile;
  @override
  Bag get bag;

  /// Progression narrative et capacités.
  @override
  PlayerProgression get progression;

  /// Variables de script (int/bool/string).
  @override
  ScriptVariables get scriptVariables;

  /// Flags narratifs (booléens).
  @override
  StoryFlags get storyFlags;

  /// IDs d'événements déjà consommés (objets ramassés, etc.).
  @override
  Set<String> get consumedEventIds;

  /// Métadonnées internes (timestamp, version, etc.).
  @override
  Map<String, String> get metadata;

  /// Create a copy of GameState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$GameStateImplCopyWith<_$GameStateImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

```

### `packages/map_core/lib/src/models/game_state.g.dart`

```dart
// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'game_state.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$ScriptVariableValueBoolImpl _$$ScriptVariableValueBoolImplFromJson(
        Map<String, dynamic> json) =>
    _$ScriptVariableValueBoolImpl(
      json['value'] as bool,
      $type: json['runtimeType'] as String?,
    );

Map<String, dynamic> _$$ScriptVariableValueBoolImplToJson(
        _$ScriptVariableValueBoolImpl instance) =>
    <String, dynamic>{
      'value': instance.value,
      'runtimeType': instance.$type,
    };

_$ScriptVariableValueIntImpl _$$ScriptVariableValueIntImplFromJson(
        Map<String, dynamic> json) =>
    _$ScriptVariableValueIntImpl(
      (json['value'] as num).toInt(),
      $type: json['runtimeType'] as String?,
    );

Map<String, dynamic> _$$ScriptVariableValueIntImplToJson(
        _$ScriptVariableValueIntImpl instance) =>
    <String, dynamic>{
      'value': instance.value,
      'runtimeType': instance.$type,
    };

_$ScriptVariableValueStringImpl _$$ScriptVariableValueStringImplFromJson(
        Map<String, dynamic> json) =>
    _$ScriptVariableValueStringImpl(
      json['value'] as String,
      $type: json['runtimeType'] as String?,
    );

Map<String, dynamic> _$$ScriptVariableValueStringImplToJson(
        _$ScriptVariableValueStringImpl instance) =>
    <String, dynamic>{
      'value': instance.value,
      'runtimeType': instance.$type,
    };

_$ScriptVariablesImpl _$$ScriptVariablesImplFromJson(
        Map<String, dynamic> json) =>
    _$ScriptVariablesImpl(
      values: (json['values'] as Map<String, dynamic>?)?.map(
            (k, e) => MapEntry(
                k, ScriptVariableValue.fromJson(e as Map<String, dynamic>)),
          ) ??
          const {},
    );

Map<String, dynamic> _$$ScriptVariablesImplToJson(
        _$ScriptVariablesImpl instance) =>
    <String, dynamic>{
      'values': instance.values.map((k, e) => MapEntry(k, e.toJson())),
    };

_$StoryFlagsImpl _$$StoryFlagsImplFromJson(Map<String, dynamic> json) =>
    _$StoryFlagsImpl(
      activeFlags: (json['activeFlags'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toSet() ??
          const {},
    );

Map<String, dynamic> _$$StoryFlagsImplToJson(_$StoryFlagsImpl instance) =>
    <String, dynamic>{
      'activeFlags': instance.activeFlags.toList(),
    };

_$GameStateImpl _$$GameStateImplFromJson(Map<String, dynamic> json) =>
    _$GameStateImpl(
      saveId: json['saveId'] as String,
      currentMapId: json['currentMapId'] as String? ?? '',
      playerPosition: json['playerPosition'] == null
          ? const GridPos(x: 0, y: 0)
          : GridPos.fromJson(json['playerPosition'] as Map<String, dynamic>),
      playerFacing:
          $enumDecodeNullable(_$EntityFacingEnumMap, json['playerFacing']) ??
              EntityFacing.south,
      playerMovementMode: $enumDecodeNullable(
              _$MovementModeEnumMap, json['playerMovementMode']) ??
          MovementMode.walk,
      party: json['party'] == null
          ? const PlayerParty()
          : PlayerParty.fromJson(json['party'] as Map<String, dynamic>),
      trainerProfile: json['trainerProfile'] == null
          ? const TrainerProfile(name: 'Player')
          : TrainerProfile.fromJson(
              json['trainerProfile'] as Map<String, dynamic>),
      bag: json['bag'] == null
          ? const Bag()
          : Bag.fromJson(json['bag'] as Map<String, dynamic>),
      progression: json['progression'] == null
          ? const PlayerProgression()
          : PlayerProgression.fromJson(
              json['progression'] as Map<String, dynamic>),
      scriptVariables: json['scriptVariables'] == null
          ? const ScriptVariables()
          : ScriptVariables.fromJson(
              json['scriptVariables'] as Map<String, dynamic>),
      storyFlags: json['storyFlags'] == null
          ? const StoryFlags()
          : StoryFlags.fromJson(json['storyFlags'] as Map<String, dynamic>),
      consumedEventIds: (json['consumedEventIds'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toSet() ??
          const {},
      metadata: (json['metadata'] as Map<String, dynamic>?)?.map(
            (k, e) => MapEntry(k, e as String),
          ) ??
          const {},
    );

Map<String, dynamic> _$$GameStateImplToJson(_$GameStateImpl instance) =>
    <String, dynamic>{
      'saveId': instance.saveId,
      'currentMapId': instance.currentMapId,
      'playerPosition': instance.playerPosition.toJson(),
      'playerFacing': _$EntityFacingEnumMap[instance.playerFacing]!,
      'playerMovementMode': _$MovementModeEnumMap[instance.playerMovementMode]!,
      'party': instance.party.toJson(),
      'trainerProfile': instance.trainerProfile.toJson(),
      'bag': instance.bag.toJson(),
      'progression': instance.progression.toJson(),
      'scriptVariables': instance.scriptVariables.toJson(),
      'storyFlags': instance.storyFlags.toJson(),
      'consumedEventIds': instance.consumedEventIds.toList(),
      'metadata': instance.metadata,
    };

const _$EntityFacingEnumMap = {
  EntityFacing.north: 'north',
  EntityFacing.south: 'south',
  EntityFacing.east: 'east',
  EntityFacing.west: 'west',
};

const _$MovementModeEnumMap = {
  MovementMode.walk: 'walk',
  MovementMode.surf: 'surf',
  MovementMode.fly: 'fly',
  MovementMode.cut: 'cut',
  MovementMode.strength: 'strength',
  MovementMode.rockSmash: 'rock_smash',
};

```

### `packages/map_core/lib/src/models/save_data.dart`

```dart
import 'package:freezed_annotation/freezed_annotation.dart';

import 'enums.dart';
import 'geometry.dart';

part 'save_data.freezed.dart';
part 'save_data.g.dart';

List<String> _normalizeUniqueStringsPreserveOrder(List<String> values) {
  final normalized = <String>[];
  final seen = <String>{};
  for (final value in values) {
    final trimmed = value.trim();
    if (trimmed.isEmpty || !seen.add(trimmed)) {
      continue;
    }
    normalized.add(trimmed);
  }
  return List.unmodifiable(normalized);
}

List<String> _normalizeUniqueStringsSorted(List<String> values) {
  final normalized = _normalizeUniqueStringsPreserveOrder(values).toList()
    ..sort();
  return List.unmodifiable(normalized);
}

Map<String, String> _normalizeStringMap(Map<String, String> values) {
  final normalizedEntries = values.entries
      .map(
        (entry) => MapEntry(entry.key.trim(), entry.value.trim()),
      )
      .where((entry) => entry.key.isNotEmpty)
      .toList(growable: false)
    ..sort((a, b) => a.key.compareTo(b.key));
  return Map<String, String>.fromEntries(normalizedEntries);
}

@freezed
class PokemonStatSpread with _$PokemonStatSpread {
  const PokemonStatSpread._();

  @JsonSerializable(explicitToJson: true)
  const factory PokemonStatSpread({
    @Default(0) int hp,
    @Default(0) int attack,
    @Default(0) int defense,
    @Default(0) int specialAttack,
    @Default(0) int specialDefense,
    @Default(0) int speed,
  }) = _PokemonStatSpread;

  factory PokemonStatSpread.fromJson(Map<String, dynamic> json) =>
      _$PokemonStatSpreadFromJson(json);

  PokemonStatSpread normalized() {
    if (hp < 0 ||
        attack < 0 ||
        defense < 0 ||
        specialAttack < 0 ||
        specialDefense < 0 ||
        speed < 0) {
      throw StateError('Pokemon stat values must be non-negative');
    }
    return this;
  }
}

/// Un Pokémon possédé par le joueur — modèle minimal pour raisonner
/// sur les field moves et l'état de l'équipe.
@freezed
class PlayerPokemon with _$PlayerPokemon {
  const PlayerPokemon._();

  @JsonSerializable(explicitToJson: true)
  const factory PlayerPokemon({
    required String speciesId,
    required String natureId,
    required String abilityId,
    @Default(1) int level,
    @Default(PokemonStatSpread()) PokemonStatSpread ivs,
    @Default(PokemonStatSpread()) PokemonStatSpread evs,
    @Default([]) List<String> knownMoveIds,
    @Default(1) int currentHp,
    @Default('') String statusId,
    @Default(false) bool isShiny,
    @Default('') String heldItemId,
  }) = _PlayerPokemon;

  factory PlayerPokemon.fromJson(Map<String, dynamic> json) =>
      _$PlayerPokemonFromJson(json);

  bool get isFainted => currentHp <= 0;

  PlayerPokemon normalized() {
    final normalizedSpeciesId = speciesId.trim();
    final normalizedNatureId = natureId.trim();
    final normalizedAbilityId = abilityId.trim();
    if (knownMoveIds.any((moveId) => moveId.trim().isEmpty)) {
      throw StateError(
          'PlayerPokemon knownMoveIds must not contain empty values');
    }
    final normalizedMoveIds =
        _normalizeUniqueStringsPreserveOrder(knownMoveIds);
    final normalizedStatusId = statusId.trim();
    final normalizedHeldItemId = heldItemId.trim();

    if (normalizedSpeciesId.isEmpty) {
      throw StateError('PlayerPokemon speciesId must not be empty');
    }
    if (normalizedNatureId.isEmpty) {
      throw StateError('PlayerPokemon natureId must not be empty');
    }
    if (normalizedAbilityId.isEmpty) {
      throw StateError('PlayerPokemon abilityId must not be empty');
    }
    if (level <= 0 || level > 100) {
      throw StateError('PlayerPokemon level must be between 1 and 100');
    }
    if (currentHp < 0) {
      throw StateError('PlayerPokemon currentHp must be non-negative');
    }
    if (normalizedMoveIds.length > 4) {
      throw StateError(
          'PlayerPokemon knownMoveIds must contain at most 4 moves');
    }

    ivs.normalized();
    evs.normalized();

    return copyWith(
      speciesId: normalizedSpeciesId,
      natureId: normalizedNatureId,
      abilityId: normalizedAbilityId,
      ivs: ivs.normalized(),
      evs: evs.normalized(),
      knownMoveIds: normalizedMoveIds,
      statusId: normalizedStatusId,
      heldItemId: normalizedHeldItemId,
    );
  }
}

/// Équipe active du joueur (max 6 en pratique, non contraint ici).
@freezed
class PlayerParty with _$PlayerParty {
  const PlayerParty._();

  @JsonSerializable(explicitToJson: true)
  const factory PlayerParty({
    @Default([]) List<PlayerPokemon> members,
  }) = _PlayerParty;

  factory PlayerParty.fromJson(Map<String, dynamic> json) =>
      _$PlayerPartyFromJson(json);

  PlayerParty normalized() => copyWith(
        members: members
            .map((member) => member.normalized())
            .toList(growable: false),
      );
}

/// Progression du joueur — field abilities débloquées, flags scénaristiques.
///
/// [completedStepIds] : identifiants des steps **Step Studio** déjà terminées
/// côté runtime (ex. completion `whenCutsceneEnds`). Persistance save/load
/// via [SaveData.progression] ; distinct des flags narratifs génériques.
@freezed
class PlayerProgression with _$PlayerProgression {
  const PlayerProgression._();

  @JsonSerializable(explicitToJson: true)
  const factory PlayerProgression({
    @Default([]) List<FieldAbility> unlockedFieldAbilities,
    @Default([]) List<String> storyFlags,

    /// Steps du document `authoring.stepStudioDocument` marquées comme
    /// complétées (ordre stable = ordre d’insertion ; dédoublonnage à l’écriture).
    @Default([]) List<String> completedStepIds,

    /// Scénarios **locaux** (cutscenes) dont le graphe a atteint un nœud `end`
    /// au moins une fois dans cette partie — utilisé pour prédicats
    /// `cutsceneCompleted` sur les PNJ (ids = [ScenarioAsset.id]).
    @Default([]) List<String> completedCutsceneIds,
  }) = _PlayerProgression;

  factory PlayerProgression.fromJson(Map<String, dynamic> json) =>
      _$PlayerProgressionFromJson(json);

  PlayerProgression normalized() => copyWith(
        storyFlags: _normalizeUniqueStringsSorted(storyFlags),
        completedStepIds:
            _normalizeUniqueStringsPreserveOrder(completedStepIds),
        completedCutsceneIds:
            _normalizeUniqueStringsPreserveOrder(completedCutsceneIds),
      );
}

@freezed
class TrainerProfile with _$TrainerProfile {
  const TrainerProfile._();

  @JsonSerializable(explicitToJson: true)
  const factory TrainerProfile({
    required String name,
    @Default([]) List<String> badgeIds,
    @Default(0) int money,
    @Default(0) int playtimeSeconds,
  }) = _TrainerProfile;

  factory TrainerProfile.fromJson(Map<String, dynamic> json) =>
      _$TrainerProfileFromJson(json);

  TrainerProfile normalized() {
    final normalizedName = name.trim();
    if (badgeIds.any((badgeId) => badgeId.trim().isEmpty)) {
      throw StateError('TrainerProfile badgeIds must not contain empty values');
    }
    final normalizedBadgeIds = _normalizeUniqueStringsSorted(badgeIds);

    if (normalizedName.isEmpty) {
      throw StateError('TrainerProfile name must not be empty');
    }
    if (money < 0) {
      throw StateError('TrainerProfile money must be non-negative');
    }
    if (playtimeSeconds < 0) {
      throw StateError('TrainerProfile playtimeSeconds must be non-negative');
    }

    return copyWith(
      name: normalizedName,
      badgeIds: normalizedBadgeIds,
    );
  }
}

@freezed
class BagEntry with _$BagEntry {
  const BagEntry._();

  @JsonSerializable(explicitToJson: true)
  const factory BagEntry({
    required String itemId,
    required String categoryId,
    required int quantity,
  }) = _BagEntry;

  factory BagEntry.fromJson(Map<String, dynamic> json) =>
      _$BagEntryFromJson(json);

  BagEntry normalized() {
    final normalizedItemId = itemId.trim();
    final normalizedCategoryId = categoryId.trim();

    if (normalizedItemId.isEmpty) {
      throw StateError('BagEntry itemId must not be empty');
    }
    if (normalizedCategoryId.isEmpty) {
      throw StateError('BagEntry categoryId must not be empty');
    }
    if (quantity <= 0) {
      throw StateError('BagEntry quantity must be positive');
    }

    return copyWith(
      itemId: normalizedItemId,
      categoryId: normalizedCategoryId,
    );
  }
}

List<BagEntry> _normalizeBagEntries(List<BagEntry> entries) {
  final merged = <String, BagEntry>{};
  for (final entry in entries.map((entry) => entry.normalized())) {
    final key = '${entry.categoryId}\u0000${entry.itemId}';
    final current = merged[key];
    merged[key] = current == null
        ? entry
        : current.copyWith(quantity: current.quantity + entry.quantity);
  }
  final normalized = merged.values.toList(growable: false)
    ..sort((a, b) {
      final byCategory = a.categoryId.compareTo(b.categoryId);
      if (byCategory != 0) {
        return byCategory;
      }
      return a.itemId.compareTo(b.itemId);
    });
  return List.unmodifiable(normalized);
}

@freezed
class Bag with _$Bag {
  const Bag._();

  @JsonSerializable(explicitToJson: true)
  const factory Bag({
    @Default([]) List<BagEntry> entries,
  }) = _Bag;

  factory Bag.fromJson(Map<String, dynamic> json) => _$BagFromJson(json);

  Bag normalized() => copyWith(entries: _normalizeBagEntries(entries));
}

/// Racine de l'état persistant de la partie.
///
/// Sérialisable JSON, immutable, indépendant du runtime.
/// Pensé pour évoluer vers une vraie sauvegarde disque.
@freezed
class SaveData with _$SaveData {
  const SaveData._();

  @JsonSerializable(explicitToJson: true)
  const factory SaveData({
    required String saveId,
    @Default('') String currentMapId,
    @Default(GridPos(x: 0, y: 0)) GridPos playerPosition,
    @Default(EntityFacing.south) EntityFacing playerFacing,
    @Default(PlayerParty()) PlayerParty party,
    @Default(TrainerProfile(name: 'Player')) TrainerProfile trainerProfile,
    @Default(Bag()) Bag bag,
    @Default(PlayerProgression()) PlayerProgression progression,
    @Default({}) Map<String, String> properties,
  }) = _SaveData;

  factory SaveData.fromJson(Map<String, dynamic> json) =>
      _$SaveDataFromJson(json);

  SaveData normalized() {
    final normalizedSaveId = saveId.trim();
    final normalizedCurrentMapId = currentMapId.trim();

    if (normalizedSaveId.isEmpty) {
      throw StateError('SaveData saveId must not be empty');
    }

    return copyWith(
      saveId: normalizedSaveId,
      currentMapId: normalizedCurrentMapId,
      party: party.normalized(),
      trainerProfile: trainerProfile.normalized(),
      bag: bag.normalized(),
      progression: progression.normalized(),
      properties: _normalizeStringMap(properties),
    );
  }
}

```

### `packages/map_core/lib/src/models/save_data.freezed.dart`

```dart
// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'save_data.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

PokemonStatSpread _$PokemonStatSpreadFromJson(Map<String, dynamic> json) {
  return _PokemonStatSpread.fromJson(json);
}

/// @nodoc
mixin _$PokemonStatSpread {
  int get hp => throw _privateConstructorUsedError;
  int get attack => throw _privateConstructorUsedError;
  int get defense => throw _privateConstructorUsedError;
  int get specialAttack => throw _privateConstructorUsedError;
  int get specialDefense => throw _privateConstructorUsedError;
  int get speed => throw _privateConstructorUsedError;

  /// Serializes this PokemonStatSpread to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of PokemonStatSpread
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $PokemonStatSpreadCopyWith<PokemonStatSpread> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $PokemonStatSpreadCopyWith<$Res> {
  factory $PokemonStatSpreadCopyWith(
          PokemonStatSpread value, $Res Function(PokemonStatSpread) then) =
      _$PokemonStatSpreadCopyWithImpl<$Res, PokemonStatSpread>;
  @useResult
  $Res call(
      {int hp,
      int attack,
      int defense,
      int specialAttack,
      int specialDefense,
      int speed});
}

/// @nodoc
class _$PokemonStatSpreadCopyWithImpl<$Res, $Val extends PokemonStatSpread>
    implements $PokemonStatSpreadCopyWith<$Res> {
  _$PokemonStatSpreadCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of PokemonStatSpread
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? hp = null,
    Object? attack = null,
    Object? defense = null,
    Object? specialAttack = null,
    Object? specialDefense = null,
    Object? speed = null,
  }) {
    return _then(_value.copyWith(
      hp: null == hp
          ? _value.hp
          : hp // ignore: cast_nullable_to_non_nullable
              as int,
      attack: null == attack
          ? _value.attack
          : attack // ignore: cast_nullable_to_non_nullable
              as int,
      defense: null == defense
          ? _value.defense
          : defense // ignore: cast_nullable_to_non_nullable
              as int,
      specialAttack: null == specialAttack
          ? _value.specialAttack
          : specialAttack // ignore: cast_nullable_to_non_nullable
              as int,
      specialDefense: null == specialDefense
          ? _value.specialDefense
          : specialDefense // ignore: cast_nullable_to_non_nullable
              as int,
      speed: null == speed
          ? _value.speed
          : speed // ignore: cast_nullable_to_non_nullable
              as int,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$PokemonStatSpreadImplCopyWith<$Res>
    implements $PokemonStatSpreadCopyWith<$Res> {
  factory _$$PokemonStatSpreadImplCopyWith(_$PokemonStatSpreadImpl value,
          $Res Function(_$PokemonStatSpreadImpl) then) =
      __$$PokemonStatSpreadImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {int hp,
      int attack,
      int defense,
      int specialAttack,
      int specialDefense,
      int speed});
}

/// @nodoc
class __$$PokemonStatSpreadImplCopyWithImpl<$Res>
    extends _$PokemonStatSpreadCopyWithImpl<$Res, _$PokemonStatSpreadImpl>
    implements _$$PokemonStatSpreadImplCopyWith<$Res> {
  __$$PokemonStatSpreadImplCopyWithImpl(_$PokemonStatSpreadImpl _value,
      $Res Function(_$PokemonStatSpreadImpl) _then)
      : super(_value, _then);

  /// Create a copy of PokemonStatSpread
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? hp = null,
    Object? attack = null,
    Object? defense = null,
    Object? specialAttack = null,
    Object? specialDefense = null,
    Object? speed = null,
  }) {
    return _then(_$PokemonStatSpreadImpl(
      hp: null == hp
          ? _value.hp
          : hp // ignore: cast_nullable_to_non_nullable
              as int,
      attack: null == attack
          ? _value.attack
          : attack // ignore: cast_nullable_to_non_nullable
              as int,
      defense: null == defense
          ? _value.defense
          : defense // ignore: cast_nullable_to_non_nullable
              as int,
      specialAttack: null == specialAttack
          ? _value.specialAttack
          : specialAttack // ignore: cast_nullable_to_non_nullable
              as int,
      specialDefense: null == specialDefense
          ? _value.specialDefense
          : specialDefense // ignore: cast_nullable_to_non_nullable
              as int,
      speed: null == speed
          ? _value.speed
          : speed // ignore: cast_nullable_to_non_nullable
              as int,
    ));
  }
}

/// @nodoc

@JsonSerializable(explicitToJson: true)
class _$PokemonStatSpreadImpl extends _PokemonStatSpread {
  const _$PokemonStatSpreadImpl(
      {this.hp = 0,
      this.attack = 0,
      this.defense = 0,
      this.specialAttack = 0,
      this.specialDefense = 0,
      this.speed = 0})
      : super._();

  factory _$PokemonStatSpreadImpl.fromJson(Map<String, dynamic> json) =>
      _$$PokemonStatSpreadImplFromJson(json);

  @override
  @JsonKey()
  final int hp;
  @override
  @JsonKey()
  final int attack;
  @override
  @JsonKey()
  final int defense;
  @override
  @JsonKey()
  final int specialAttack;
  @override
  @JsonKey()
  final int specialDefense;
  @override
  @JsonKey()
  final int speed;

  @override
  String toString() {
    return 'PokemonStatSpread(hp: $hp, attack: $attack, defense: $defense, specialAttack: $specialAttack, specialDefense: $specialDefense, speed: $speed)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PokemonStatSpreadImpl &&
            (identical(other.hp, hp) || other.hp == hp) &&
            (identical(other.attack, attack) || other.attack == attack) &&
            (identical(other.defense, defense) || other.defense == defense) &&
            (identical(other.specialAttack, specialAttack) ||
                other.specialAttack == specialAttack) &&
            (identical(other.specialDefense, specialDefense) ||
                other.specialDefense == specialDefense) &&
            (identical(other.speed, speed) || other.speed == speed));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType, hp, attack, defense, specialAttack, specialDefense, speed);

  /// Create a copy of PokemonStatSpread
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$PokemonStatSpreadImplCopyWith<_$PokemonStatSpreadImpl> get copyWith =>
      __$$PokemonStatSpreadImplCopyWithImpl<_$PokemonStatSpreadImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$PokemonStatSpreadImplToJson(
      this,
    );
  }
}

abstract class _PokemonStatSpread extends PokemonStatSpread {
  const factory _PokemonStatSpread(
      {final int hp,
      final int attack,
      final int defense,
      final int specialAttack,
      final int specialDefense,
      final int speed}) = _$PokemonStatSpreadImpl;
  const _PokemonStatSpread._() : super._();

  factory _PokemonStatSpread.fromJson(Map<String, dynamic> json) =
      _$PokemonStatSpreadImpl.fromJson;

  @override
  int get hp;
  @override
  int get attack;
  @override
  int get defense;
  @override
  int get specialAttack;
  @override
  int get specialDefense;
  @override
  int get speed;

  /// Create a copy of PokemonStatSpread
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$PokemonStatSpreadImplCopyWith<_$PokemonStatSpreadImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

PlayerPokemon _$PlayerPokemonFromJson(Map<String, dynamic> json) {
  return _PlayerPokemon.fromJson(json);
}

/// @nodoc
mixin _$PlayerPokemon {
  String get speciesId => throw _privateConstructorUsedError;
  String get natureId => throw _privateConstructorUsedError;
  String get abilityId => throw _privateConstructorUsedError;
  int get level => throw _privateConstructorUsedError;
  PokemonStatSpread get ivs => throw _privateConstructorUsedError;
  PokemonStatSpread get evs => throw _privateConstructorUsedError;
  List<String> get knownMoveIds => throw _privateConstructorUsedError;
  int get currentHp => throw _privateConstructorUsedError;
  String get statusId => throw _privateConstructorUsedError;
  bool get isShiny => throw _privateConstructorUsedError;
  String get heldItemId => throw _privateConstructorUsedError;

  /// Serializes this PlayerPokemon to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of PlayerPokemon
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $PlayerPokemonCopyWith<PlayerPokemon> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $PlayerPokemonCopyWith<$Res> {
  factory $PlayerPokemonCopyWith(
          PlayerPokemon value, $Res Function(PlayerPokemon) then) =
      _$PlayerPokemonCopyWithImpl<$Res, PlayerPokemon>;
  @useResult
  $Res call(
      {String speciesId,
      String natureId,
      String abilityId,
      int level,
      PokemonStatSpread ivs,
      PokemonStatSpread evs,
      List<String> knownMoveIds,
      int currentHp,
      String statusId,
      bool isShiny,
      String heldItemId});

  $PokemonStatSpreadCopyWith<$Res> get ivs;
  $PokemonStatSpreadCopyWith<$Res> get evs;
}

/// @nodoc
class _$PlayerPokemonCopyWithImpl<$Res, $Val extends PlayerPokemon>
    implements $PlayerPokemonCopyWith<$Res> {
  _$PlayerPokemonCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of PlayerPokemon
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? speciesId = null,
    Object? natureId = null,
    Object? abilityId = null,
    Object? level = null,
    Object? ivs = null,
    Object? evs = null,
    Object? knownMoveIds = null,
    Object? currentHp = null,
    Object? statusId = null,
    Object? isShiny = null,
    Object? heldItemId = null,
  }) {
    return _then(_value.copyWith(
      speciesId: null == speciesId
          ? _value.speciesId
          : speciesId // ignore: cast_nullable_to_non_nullable
              as String,
      natureId: null == natureId
          ? _value.natureId
          : natureId // ignore: cast_nullable_to_non_nullable
              as String,
      abilityId: null == abilityId
          ? _value.abilityId
          : abilityId // ignore: cast_nullable_to_non_nullable
              as String,
      level: null == level
          ? _value.level
          : level // ignore: cast_nullable_to_non_nullable
              as int,
      ivs: null == ivs
          ? _value.ivs
          : ivs // ignore: cast_nullable_to_non_nullable
              as PokemonStatSpread,
      evs: null == evs
          ? _value.evs
          : evs // ignore: cast_nullable_to_non_nullable
              as PokemonStatSpread,
      knownMoveIds: null == knownMoveIds
          ? _value.knownMoveIds
          : knownMoveIds // ignore: cast_nullable_to_non_nullable
              as List<String>,
      currentHp: null == currentHp
          ? _value.currentHp
          : currentHp // ignore: cast_nullable_to_non_nullable
              as int,
      statusId: null == statusId
          ? _value.statusId
          : statusId // ignore: cast_nullable_to_non_nullable
              as String,
      isShiny: null == isShiny
          ? _value.isShiny
          : isShiny // ignore: cast_nullable_to_non_nullable
              as bool,
      heldItemId: null == heldItemId
          ? _value.heldItemId
          : heldItemId // ignore: cast_nullable_to_non_nullable
              as String,
    ) as $Val);
  }

  /// Create a copy of PlayerPokemon
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $PokemonStatSpreadCopyWith<$Res> get ivs {
    return $PokemonStatSpreadCopyWith<$Res>(_value.ivs, (value) {
      return _then(_value.copyWith(ivs: value) as $Val);
    });
  }

  /// Create a copy of PlayerPokemon
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $PokemonStatSpreadCopyWith<$Res> get evs {
    return $PokemonStatSpreadCopyWith<$Res>(_value.evs, (value) {
      return _then(_value.copyWith(evs: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$PlayerPokemonImplCopyWith<$Res>
    implements $PlayerPokemonCopyWith<$Res> {
  factory _$$PlayerPokemonImplCopyWith(
          _$PlayerPokemonImpl value, $Res Function(_$PlayerPokemonImpl) then) =
      __$$PlayerPokemonImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String speciesId,
      String natureId,
      String abilityId,
      int level,
      PokemonStatSpread ivs,
      PokemonStatSpread evs,
      List<String> knownMoveIds,
      int currentHp,
      String statusId,
      bool isShiny,
      String heldItemId});

  @override
  $PokemonStatSpreadCopyWith<$Res> get ivs;
  @override
  $PokemonStatSpreadCopyWith<$Res> get evs;
}

/// @nodoc
class __$$PlayerPokemonImplCopyWithImpl<$Res>
    extends _$PlayerPokemonCopyWithImpl<$Res, _$PlayerPokemonImpl>
    implements _$$PlayerPokemonImplCopyWith<$Res> {
  __$$PlayerPokemonImplCopyWithImpl(
      _$PlayerPokemonImpl _value, $Res Function(_$PlayerPokemonImpl) _then)
      : super(_value, _then);

  /// Create a copy of PlayerPokemon
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? speciesId = null,
    Object? natureId = null,
    Object? abilityId = null,
    Object? level = null,
    Object? ivs = null,
    Object? evs = null,
    Object? knownMoveIds = null,
    Object? currentHp = null,
    Object? statusId = null,
    Object? isShiny = null,
    Object? heldItemId = null,
  }) {
    return _then(_$PlayerPokemonImpl(
      speciesId: null == speciesId
          ? _value.speciesId
          : speciesId // ignore: cast_nullable_to_non_nullable
              as String,
      natureId: null == natureId
          ? _value.natureId
          : natureId // ignore: cast_nullable_to_non_nullable
              as String,
      abilityId: null == abilityId
          ? _value.abilityId
          : abilityId // ignore: cast_nullable_to_non_nullable
              as String,
      level: null == level
          ? _value.level
          : level // ignore: cast_nullable_to_non_nullable
              as int,
      ivs: null == ivs
          ? _value.ivs
          : ivs // ignore: cast_nullable_to_non_nullable
              as PokemonStatSpread,
      evs: null == evs
          ? _value.evs
          : evs // ignore: cast_nullable_to_non_nullable
              as PokemonStatSpread,
      knownMoveIds: null == knownMoveIds
          ? _value._knownMoveIds
          : knownMoveIds // ignore: cast_nullable_to_non_nullable
              as List<String>,
      currentHp: null == currentHp
          ? _value.currentHp
          : currentHp // ignore: cast_nullable_to_non_nullable
              as int,
      statusId: null == statusId
          ? _value.statusId
          : statusId // ignore: cast_nullable_to_non_nullable
              as String,
      isShiny: null == isShiny
          ? _value.isShiny
          : isShiny // ignore: cast_nullable_to_non_nullable
              as bool,
      heldItemId: null == heldItemId
          ? _value.heldItemId
          : heldItemId // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc

@JsonSerializable(explicitToJson: true)
class _$PlayerPokemonImpl extends _PlayerPokemon {
  const _$PlayerPokemonImpl(
      {required this.speciesId,
      required this.natureId,
      required this.abilityId,
      this.level = 1,
      this.ivs = const PokemonStatSpread(),
      this.evs = const PokemonStatSpread(),
      final List<String> knownMoveIds = const [],
      this.currentHp = 1,
      this.statusId = '',
      this.isShiny = false,
      this.heldItemId = ''})
      : _knownMoveIds = knownMoveIds,
        super._();

  factory _$PlayerPokemonImpl.fromJson(Map<String, dynamic> json) =>
      _$$PlayerPokemonImplFromJson(json);

  @override
  final String speciesId;
  @override
  final String natureId;
  @override
  final String abilityId;
  @override
  @JsonKey()
  final int level;
  @override
  @JsonKey()
  final PokemonStatSpread ivs;
  @override
  @JsonKey()
  final PokemonStatSpread evs;
  final List<String> _knownMoveIds;
  @override
  @JsonKey()
  List<String> get knownMoveIds {
    if (_knownMoveIds is EqualUnmodifiableListView) return _knownMoveIds;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_knownMoveIds);
  }

  @override
  @JsonKey()
  final int currentHp;
  @override
  @JsonKey()
  final String statusId;
  @override
  @JsonKey()
  final bool isShiny;
  @override
  @JsonKey()
  final String heldItemId;

  @override
  String toString() {
    return 'PlayerPokemon(speciesId: $speciesId, natureId: $natureId, abilityId: $abilityId, level: $level, ivs: $ivs, evs: $evs, knownMoveIds: $knownMoveIds, currentHp: $currentHp, statusId: $statusId, isShiny: $isShiny, heldItemId: $heldItemId)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PlayerPokemonImpl &&
            (identical(other.speciesId, speciesId) ||
                other.speciesId == speciesId) &&
            (identical(other.natureId, natureId) ||
                other.natureId == natureId) &&
            (identical(other.abilityId, abilityId) ||
                other.abilityId == abilityId) &&
            (identical(other.level, level) || other.level == level) &&
            (identical(other.ivs, ivs) || other.ivs == ivs) &&
            (identical(other.evs, evs) || other.evs == evs) &&
            const DeepCollectionEquality()
                .equals(other._knownMoveIds, _knownMoveIds) &&
            (identical(other.currentHp, currentHp) ||
                other.currentHp == currentHp) &&
            (identical(other.statusId, statusId) ||
                other.statusId == statusId) &&
            (identical(other.isShiny, isShiny) || other.isShiny == isShiny) &&
            (identical(other.heldItemId, heldItemId) ||
                other.heldItemId == heldItemId));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      speciesId,
      natureId,
      abilityId,
      level,
      ivs,
      evs,
      const DeepCollectionEquality().hash(_knownMoveIds),
      currentHp,
      statusId,
      isShiny,
      heldItemId);

  /// Create a copy of PlayerPokemon
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$PlayerPokemonImplCopyWith<_$PlayerPokemonImpl> get copyWith =>
      __$$PlayerPokemonImplCopyWithImpl<_$PlayerPokemonImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$PlayerPokemonImplToJson(
      this,
    );
  }
}

abstract class _PlayerPokemon extends PlayerPokemon {
  const factory _PlayerPokemon(
      {required final String speciesId,
      required final String natureId,
      required final String abilityId,
      final int level,
      final PokemonStatSpread ivs,
      final PokemonStatSpread evs,
      final List<String> knownMoveIds,
      final int currentHp,
      final String statusId,
      final bool isShiny,
      final String heldItemId}) = _$PlayerPokemonImpl;
  const _PlayerPokemon._() : super._();

  factory _PlayerPokemon.fromJson(Map<String, dynamic> json) =
      _$PlayerPokemonImpl.fromJson;

  @override
  String get speciesId;
  @override
  String get natureId;
  @override
  String get abilityId;
  @override
  int get level;
  @override
  PokemonStatSpread get ivs;
  @override
  PokemonStatSpread get evs;
  @override
  List<String> get knownMoveIds;
  @override
  int get currentHp;
  @override
  String get statusId;
  @override
  bool get isShiny;
  @override
  String get heldItemId;

  /// Create a copy of PlayerPokemon
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$PlayerPokemonImplCopyWith<_$PlayerPokemonImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

PlayerParty _$PlayerPartyFromJson(Map<String, dynamic> json) {
  return _PlayerParty.fromJson(json);
}

/// @nodoc
mixin _$PlayerParty {
  List<PlayerPokemon> get members => throw _privateConstructorUsedError;

  /// Serializes this PlayerParty to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of PlayerParty
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $PlayerPartyCopyWith<PlayerParty> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $PlayerPartyCopyWith<$Res> {
  factory $PlayerPartyCopyWith(
          PlayerParty value, $Res Function(PlayerParty) then) =
      _$PlayerPartyCopyWithImpl<$Res, PlayerParty>;
  @useResult
  $Res call({List<PlayerPokemon> members});
}

/// @nodoc
class _$PlayerPartyCopyWithImpl<$Res, $Val extends PlayerParty>
    implements $PlayerPartyCopyWith<$Res> {
  _$PlayerPartyCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of PlayerParty
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? members = null,
  }) {
    return _then(_value.copyWith(
      members: null == members
          ? _value.members
          : members // ignore: cast_nullable_to_non_nullable
              as List<PlayerPokemon>,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$PlayerPartyImplCopyWith<$Res>
    implements $PlayerPartyCopyWith<$Res> {
  factory _$$PlayerPartyImplCopyWith(
          _$PlayerPartyImpl value, $Res Function(_$PlayerPartyImpl) then) =
      __$$PlayerPartyImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({List<PlayerPokemon> members});
}

/// @nodoc
class __$$PlayerPartyImplCopyWithImpl<$Res>
    extends _$PlayerPartyCopyWithImpl<$Res, _$PlayerPartyImpl>
    implements _$$PlayerPartyImplCopyWith<$Res> {
  __$$PlayerPartyImplCopyWithImpl(
      _$PlayerPartyImpl _value, $Res Function(_$PlayerPartyImpl) _then)
      : super(_value, _then);

  /// Create a copy of PlayerParty
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? members = null,
  }) {
    return _then(_$PlayerPartyImpl(
      members: null == members
          ? _value._members
          : members // ignore: cast_nullable_to_non_nullable
              as List<PlayerPokemon>,
    ));
  }
}

/// @nodoc

@JsonSerializable(explicitToJson: true)
class _$PlayerPartyImpl extends _PlayerParty {
  const _$PlayerPartyImpl({final List<PlayerPokemon> members = const []})
      : _members = members,
        super._();

  factory _$PlayerPartyImpl.fromJson(Map<String, dynamic> json) =>
      _$$PlayerPartyImplFromJson(json);

  final List<PlayerPokemon> _members;
  @override
  @JsonKey()
  List<PlayerPokemon> get members {
    if (_members is EqualUnmodifiableListView) return _members;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_members);
  }

  @override
  String toString() {
    return 'PlayerParty(members: $members)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PlayerPartyImpl &&
            const DeepCollectionEquality().equals(other._members, _members));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, const DeepCollectionEquality().hash(_members));

  /// Create a copy of PlayerParty
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$PlayerPartyImplCopyWith<_$PlayerPartyImpl> get copyWith =>
      __$$PlayerPartyImplCopyWithImpl<_$PlayerPartyImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$PlayerPartyImplToJson(
      this,
    );
  }
}

abstract class _PlayerParty extends PlayerParty {
  const factory _PlayerParty({final List<PlayerPokemon> members}) =
      _$PlayerPartyImpl;
  const _PlayerParty._() : super._();

  factory _PlayerParty.fromJson(Map<String, dynamic> json) =
      _$PlayerPartyImpl.fromJson;

  @override
  List<PlayerPokemon> get members;

  /// Create a copy of PlayerParty
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$PlayerPartyImplCopyWith<_$PlayerPartyImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

PlayerProgression _$PlayerProgressionFromJson(Map<String, dynamic> json) {
  return _PlayerProgression.fromJson(json);
}

/// @nodoc
mixin _$PlayerProgression {
  List<FieldAbility> get unlockedFieldAbilities =>
      throw _privateConstructorUsedError;
  List<String> get storyFlags => throw _privateConstructorUsedError;

  /// Steps du document `authoring.stepStudioDocument` marquées comme
  /// complétées (ordre stable = ordre d’insertion ; dédoublonnage à l’écriture).
  List<String> get completedStepIds => throw _privateConstructorUsedError;

  /// Scénarios **locaux** (cutscenes) dont le graphe a atteint un nœud `end`
  /// au moins une fois dans cette partie — utilisé pour prédicats
  /// `cutsceneCompleted` sur les PNJ (ids = [ScenarioAsset.id]).
  List<String> get completedCutsceneIds => throw _privateConstructorUsedError;

  /// Serializes this PlayerProgression to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of PlayerProgression
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $PlayerProgressionCopyWith<PlayerProgression> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $PlayerProgressionCopyWith<$Res> {
  factory $PlayerProgressionCopyWith(
          PlayerProgression value, $Res Function(PlayerProgression) then) =
      _$PlayerProgressionCopyWithImpl<$Res, PlayerProgression>;
  @useResult
  $Res call(
      {List<FieldAbility> unlockedFieldAbilities,
      List<String> storyFlags,
      List<String> completedStepIds,
      List<String> completedCutsceneIds});
}

/// @nodoc
class _$PlayerProgressionCopyWithImpl<$Res, $Val extends PlayerProgression>
    implements $PlayerProgressionCopyWith<$Res> {
  _$PlayerProgressionCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of PlayerProgression
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? unlockedFieldAbilities = null,
    Object? storyFlags = null,
    Object? completedStepIds = null,
    Object? completedCutsceneIds = null,
  }) {
    return _then(_value.copyWith(
      unlockedFieldAbilities: null == unlockedFieldAbilities
          ? _value.unlockedFieldAbilities
          : unlockedFieldAbilities // ignore: cast_nullable_to_non_nullable
              as List<FieldAbility>,
      storyFlags: null == storyFlags
          ? _value.storyFlags
          : storyFlags // ignore: cast_nullable_to_non_nullable
              as List<String>,
      completedStepIds: null == completedStepIds
          ? _value.completedStepIds
          : completedStepIds // ignore: cast_nullable_to_non_nullable
              as List<String>,
      completedCutsceneIds: null == completedCutsceneIds
          ? _value.completedCutsceneIds
          : completedCutsceneIds // ignore: cast_nullable_to_non_nullable
              as List<String>,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$PlayerProgressionImplCopyWith<$Res>
    implements $PlayerProgressionCopyWith<$Res> {
  factory _$$PlayerProgressionImplCopyWith(_$PlayerProgressionImpl value,
          $Res Function(_$PlayerProgressionImpl) then) =
      __$$PlayerProgressionImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {List<FieldAbility> unlockedFieldAbilities,
      List<String> storyFlags,
      List<String> completedStepIds,
      List<String> completedCutsceneIds});
}

/// @nodoc
class __$$PlayerProgressionImplCopyWithImpl<$Res>
    extends _$PlayerProgressionCopyWithImpl<$Res, _$PlayerProgressionImpl>
    implements _$$PlayerProgressionImplCopyWith<$Res> {
  __$$PlayerProgressionImplCopyWithImpl(_$PlayerProgressionImpl _value,
      $Res Function(_$PlayerProgressionImpl) _then)
      : super(_value, _then);

  /// Create a copy of PlayerProgression
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? unlockedFieldAbilities = null,
    Object? storyFlags = null,
    Object? completedStepIds = null,
    Object? completedCutsceneIds = null,
  }) {
    return _then(_$PlayerProgressionImpl(
      unlockedFieldAbilities: null == unlockedFieldAbilities
          ? _value._unlockedFieldAbilities
          : unlockedFieldAbilities // ignore: cast_nullable_to_non_nullable
              as List<FieldAbility>,
      storyFlags: null == storyFlags
          ? _value._storyFlags
          : storyFlags // ignore: cast_nullable_to_non_nullable
              as List<String>,
      completedStepIds: null == completedStepIds
          ? _value._completedStepIds
          : completedStepIds // ignore: cast_nullable_to_non_nullable
              as List<String>,
      completedCutsceneIds: null == completedCutsceneIds
          ? _value._completedCutsceneIds
          : completedCutsceneIds // ignore: cast_nullable_to_non_nullable
              as List<String>,
    ));
  }
}

/// @nodoc

@JsonSerializable(explicitToJson: true)
class _$PlayerProgressionImpl extends _PlayerProgression {
  const _$PlayerProgressionImpl(
      {final List<FieldAbility> unlockedFieldAbilities = const [],
      final List<String> storyFlags = const [],
      final List<String> completedStepIds = const [],
      final List<String> completedCutsceneIds = const []})
      : _unlockedFieldAbilities = unlockedFieldAbilities,
        _storyFlags = storyFlags,
        _completedStepIds = completedStepIds,
        _completedCutsceneIds = completedCutsceneIds,
        super._();

  factory _$PlayerProgressionImpl.fromJson(Map<String, dynamic> json) =>
      _$$PlayerProgressionImplFromJson(json);

  final List<FieldAbility> _unlockedFieldAbilities;
  @override
  @JsonKey()
  List<FieldAbility> get unlockedFieldAbilities {
    if (_unlockedFieldAbilities is EqualUnmodifiableListView)
      return _unlockedFieldAbilities;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_unlockedFieldAbilities);
  }

  final List<String> _storyFlags;
  @override
  @JsonKey()
  List<String> get storyFlags {
    if (_storyFlags is EqualUnmodifiableListView) return _storyFlags;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_storyFlags);
  }

  /// Steps du document `authoring.stepStudioDocument` marquées comme
  /// complétées (ordre stable = ordre d’insertion ; dédoublonnage à l’écriture).
  final List<String> _completedStepIds;

  /// Steps du document `authoring.stepStudioDocument` marquées comme
  /// complétées (ordre stable = ordre d’insertion ; dédoublonnage à l’écriture).
  @override
  @JsonKey()
  List<String> get completedStepIds {
    if (_completedStepIds is EqualUnmodifiableListView)
      return _completedStepIds;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_completedStepIds);
  }

  /// Scénarios **locaux** (cutscenes) dont le graphe a atteint un nœud `end`
  /// au moins une fois dans cette partie — utilisé pour prédicats
  /// `cutsceneCompleted` sur les PNJ (ids = [ScenarioAsset.id]).
  final List<String> _completedCutsceneIds;

  /// Scénarios **locaux** (cutscenes) dont le graphe a atteint un nœud `end`
  /// au moins une fois dans cette partie — utilisé pour prédicats
  /// `cutsceneCompleted` sur les PNJ (ids = [ScenarioAsset.id]).
  @override
  @JsonKey()
  List<String> get completedCutsceneIds {
    if (_completedCutsceneIds is EqualUnmodifiableListView)
      return _completedCutsceneIds;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_completedCutsceneIds);
  }

  @override
  String toString() {
    return 'PlayerProgression(unlockedFieldAbilities: $unlockedFieldAbilities, storyFlags: $storyFlags, completedStepIds: $completedStepIds, completedCutsceneIds: $completedCutsceneIds)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PlayerProgressionImpl &&
            const DeepCollectionEquality().equals(
                other._unlockedFieldAbilities, _unlockedFieldAbilities) &&
            const DeepCollectionEquality()
                .equals(other._storyFlags, _storyFlags) &&
            const DeepCollectionEquality()
                .equals(other._completedStepIds, _completedStepIds) &&
            const DeepCollectionEquality()
                .equals(other._completedCutsceneIds, _completedCutsceneIds));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      const DeepCollectionEquality().hash(_unlockedFieldAbilities),
      const DeepCollectionEquality().hash(_storyFlags),
      const DeepCollectionEquality().hash(_completedStepIds),
      const DeepCollectionEquality().hash(_completedCutsceneIds));

  /// Create a copy of PlayerProgression
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$PlayerProgressionImplCopyWith<_$PlayerProgressionImpl> get copyWith =>
      __$$PlayerProgressionImplCopyWithImpl<_$PlayerProgressionImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$PlayerProgressionImplToJson(
      this,
    );
  }
}

abstract class _PlayerProgression extends PlayerProgression {
  const factory _PlayerProgression(
      {final List<FieldAbility> unlockedFieldAbilities,
      final List<String> storyFlags,
      final List<String> completedStepIds,
      final List<String> completedCutsceneIds}) = _$PlayerProgressionImpl;
  const _PlayerProgression._() : super._();

  factory _PlayerProgression.fromJson(Map<String, dynamic> json) =
      _$PlayerProgressionImpl.fromJson;

  @override
  List<FieldAbility> get unlockedFieldAbilities;
  @override
  List<String> get storyFlags;

  /// Steps du document `authoring.stepStudioDocument` marquées comme
  /// complétées (ordre stable = ordre d’insertion ; dédoublonnage à l’écriture).
  @override
  List<String> get completedStepIds;

  /// Scénarios **locaux** (cutscenes) dont le graphe a atteint un nœud `end`
  /// au moins une fois dans cette partie — utilisé pour prédicats
  /// `cutsceneCompleted` sur les PNJ (ids = [ScenarioAsset.id]).
  @override
  List<String> get completedCutsceneIds;

  /// Create a copy of PlayerProgression
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$PlayerProgressionImplCopyWith<_$PlayerProgressionImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

TrainerProfile _$TrainerProfileFromJson(Map<String, dynamic> json) {
  return _TrainerProfile.fromJson(json);
}

/// @nodoc
mixin _$TrainerProfile {
  String get name => throw _privateConstructorUsedError;
  List<String> get badgeIds => throw _privateConstructorUsedError;
  int get money => throw _privateConstructorUsedError;
  int get playtimeSeconds => throw _privateConstructorUsedError;

  /// Serializes this TrainerProfile to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of TrainerProfile
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $TrainerProfileCopyWith<TrainerProfile> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $TrainerProfileCopyWith<$Res> {
  factory $TrainerProfileCopyWith(
          TrainerProfile value, $Res Function(TrainerProfile) then) =
      _$TrainerProfileCopyWithImpl<$Res, TrainerProfile>;
  @useResult
  $Res call(
      {String name, List<String> badgeIds, int money, int playtimeSeconds});
}

/// @nodoc
class _$TrainerProfileCopyWithImpl<$Res, $Val extends TrainerProfile>
    implements $TrainerProfileCopyWith<$Res> {
  _$TrainerProfileCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of TrainerProfile
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? name = null,
    Object? badgeIds = null,
    Object? money = null,
    Object? playtimeSeconds = null,
  }) {
    return _then(_value.copyWith(
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      badgeIds: null == badgeIds
          ? _value.badgeIds
          : badgeIds // ignore: cast_nullable_to_non_nullable
              as List<String>,
      money: null == money
          ? _value.money
          : money // ignore: cast_nullable_to_non_nullable
              as int,
      playtimeSeconds: null == playtimeSeconds
          ? _value.playtimeSeconds
          : playtimeSeconds // ignore: cast_nullable_to_non_nullable
              as int,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$TrainerProfileImplCopyWith<$Res>
    implements $TrainerProfileCopyWith<$Res> {
  factory _$$TrainerProfileImplCopyWith(_$TrainerProfileImpl value,
          $Res Function(_$TrainerProfileImpl) then) =
      __$$TrainerProfileImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String name, List<String> badgeIds, int money, int playtimeSeconds});
}

/// @nodoc
class __$$TrainerProfileImplCopyWithImpl<$Res>
    extends _$TrainerProfileCopyWithImpl<$Res, _$TrainerProfileImpl>
    implements _$$TrainerProfileImplCopyWith<$Res> {
  __$$TrainerProfileImplCopyWithImpl(
      _$TrainerProfileImpl _value, $Res Function(_$TrainerProfileImpl) _then)
      : super(_value, _then);

  /// Create a copy of TrainerProfile
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? name = null,
    Object? badgeIds = null,
    Object? money = null,
    Object? playtimeSeconds = null,
  }) {
    return _then(_$TrainerProfileImpl(
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      badgeIds: null == badgeIds
          ? _value._badgeIds
          : badgeIds // ignore: cast_nullable_to_non_nullable
              as List<String>,
      money: null == money
          ? _value.money
          : money // ignore: cast_nullable_to_non_nullable
              as int,
      playtimeSeconds: null == playtimeSeconds
          ? _value.playtimeSeconds
          : playtimeSeconds // ignore: cast_nullable_to_non_nullable
              as int,
    ));
  }
}

/// @nodoc

@JsonSerializable(explicitToJson: true)
class _$TrainerProfileImpl extends _TrainerProfile {
  const _$TrainerProfileImpl(
      {required this.name,
      final List<String> badgeIds = const [],
      this.money = 0,
      this.playtimeSeconds = 0})
      : _badgeIds = badgeIds,
        super._();

  factory _$TrainerProfileImpl.fromJson(Map<String, dynamic> json) =>
      _$$TrainerProfileImplFromJson(json);

  @override
  final String name;
  final List<String> _badgeIds;
  @override
  @JsonKey()
  List<String> get badgeIds {
    if (_badgeIds is EqualUnmodifiableListView) return _badgeIds;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_badgeIds);
  }

  @override
  @JsonKey()
  final int money;
  @override
  @JsonKey()
  final int playtimeSeconds;

  @override
  String toString() {
    return 'TrainerProfile(name: $name, badgeIds: $badgeIds, money: $money, playtimeSeconds: $playtimeSeconds)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$TrainerProfileImpl &&
            (identical(other.name, name) || other.name == name) &&
            const DeepCollectionEquality().equals(other._badgeIds, _badgeIds) &&
            (identical(other.money, money) || other.money == money) &&
            (identical(other.playtimeSeconds, playtimeSeconds) ||
                other.playtimeSeconds == playtimeSeconds));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, name,
      const DeepCollectionEquality().hash(_badgeIds), money, playtimeSeconds);

  /// Create a copy of TrainerProfile
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$TrainerProfileImplCopyWith<_$TrainerProfileImpl> get copyWith =>
      __$$TrainerProfileImplCopyWithImpl<_$TrainerProfileImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$TrainerProfileImplToJson(
      this,
    );
  }
}

abstract class _TrainerProfile extends TrainerProfile {
  const factory _TrainerProfile(
      {required final String name,
      final List<String> badgeIds,
      final int money,
      final int playtimeSeconds}) = _$TrainerProfileImpl;
  const _TrainerProfile._() : super._();

  factory _TrainerProfile.fromJson(Map<String, dynamic> json) =
      _$TrainerProfileImpl.fromJson;

  @override
  String get name;
  @override
  List<String> get badgeIds;
  @override
  int get money;
  @override
  int get playtimeSeconds;

  /// Create a copy of TrainerProfile
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$TrainerProfileImplCopyWith<_$TrainerProfileImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

BagEntry _$BagEntryFromJson(Map<String, dynamic> json) {
  return _BagEntry.fromJson(json);
}

/// @nodoc
mixin _$BagEntry {
  String get itemId => throw _privateConstructorUsedError;
  String get categoryId => throw _privateConstructorUsedError;
  int get quantity => throw _privateConstructorUsedError;

  /// Serializes this BagEntry to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of BagEntry
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $BagEntryCopyWith<BagEntry> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $BagEntryCopyWith<$Res> {
  factory $BagEntryCopyWith(BagEntry value, $Res Function(BagEntry) then) =
      _$BagEntryCopyWithImpl<$Res, BagEntry>;
  @useResult
  $Res call({String itemId, String categoryId, int quantity});
}

/// @nodoc
class _$BagEntryCopyWithImpl<$Res, $Val extends BagEntry>
    implements $BagEntryCopyWith<$Res> {
  _$BagEntryCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of BagEntry
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? itemId = null,
    Object? categoryId = null,
    Object? quantity = null,
  }) {
    return _then(_value.copyWith(
      itemId: null == itemId
          ? _value.itemId
          : itemId // ignore: cast_nullable_to_non_nullable
              as String,
      categoryId: null == categoryId
          ? _value.categoryId
          : categoryId // ignore: cast_nullable_to_non_nullable
              as String,
      quantity: null == quantity
          ? _value.quantity
          : quantity // ignore: cast_nullable_to_non_nullable
              as int,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$BagEntryImplCopyWith<$Res>
    implements $BagEntryCopyWith<$Res> {
  factory _$$BagEntryImplCopyWith(
          _$BagEntryImpl value, $Res Function(_$BagEntryImpl) then) =
      __$$BagEntryImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String itemId, String categoryId, int quantity});
}

/// @nodoc
class __$$BagEntryImplCopyWithImpl<$Res>
    extends _$BagEntryCopyWithImpl<$Res, _$BagEntryImpl>
    implements _$$BagEntryImplCopyWith<$Res> {
  __$$BagEntryImplCopyWithImpl(
      _$BagEntryImpl _value, $Res Function(_$BagEntryImpl) _then)
      : super(_value, _then);

  /// Create a copy of BagEntry
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? itemId = null,
    Object? categoryId = null,
    Object? quantity = null,
  }) {
    return _then(_$BagEntryImpl(
      itemId: null == itemId
          ? _value.itemId
          : itemId // ignore: cast_nullable_to_non_nullable
              as String,
      categoryId: null == categoryId
          ? _value.categoryId
          : categoryId // ignore: cast_nullable_to_non_nullable
              as String,
      quantity: null == quantity
          ? _value.quantity
          : quantity // ignore: cast_nullable_to_non_nullable
              as int,
    ));
  }
}

/// @nodoc

@JsonSerializable(explicitToJson: true)
class _$BagEntryImpl extends _BagEntry {
  const _$BagEntryImpl(
      {required this.itemId, required this.categoryId, required this.quantity})
      : super._();

  factory _$BagEntryImpl.fromJson(Map<String, dynamic> json) =>
      _$$BagEntryImplFromJson(json);

  @override
  final String itemId;
  @override
  final String categoryId;
  @override
  final int quantity;

  @override
  String toString() {
    return 'BagEntry(itemId: $itemId, categoryId: $categoryId, quantity: $quantity)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$BagEntryImpl &&
            (identical(other.itemId, itemId) || other.itemId == itemId) &&
            (identical(other.categoryId, categoryId) ||
                other.categoryId == categoryId) &&
            (identical(other.quantity, quantity) ||
                other.quantity == quantity));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, itemId, categoryId, quantity);

  /// Create a copy of BagEntry
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$BagEntryImplCopyWith<_$BagEntryImpl> get copyWith =>
      __$$BagEntryImplCopyWithImpl<_$BagEntryImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$BagEntryImplToJson(
      this,
    );
  }
}

abstract class _BagEntry extends BagEntry {
  const factory _BagEntry(
      {required final String itemId,
      required final String categoryId,
      required final int quantity}) = _$BagEntryImpl;
  const _BagEntry._() : super._();

  factory _BagEntry.fromJson(Map<String, dynamic> json) =
      _$BagEntryImpl.fromJson;

  @override
  String get itemId;
  @override
  String get categoryId;
  @override
  int get quantity;

  /// Create a copy of BagEntry
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$BagEntryImplCopyWith<_$BagEntryImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

Bag _$BagFromJson(Map<String, dynamic> json) {
  return _Bag.fromJson(json);
}

/// @nodoc
mixin _$Bag {
  List<BagEntry> get entries => throw _privateConstructorUsedError;

  /// Serializes this Bag to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of Bag
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $BagCopyWith<Bag> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $BagCopyWith<$Res> {
  factory $BagCopyWith(Bag value, $Res Function(Bag) then) =
      _$BagCopyWithImpl<$Res, Bag>;
  @useResult
  $Res call({List<BagEntry> entries});
}

/// @nodoc
class _$BagCopyWithImpl<$Res, $Val extends Bag> implements $BagCopyWith<$Res> {
  _$BagCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Bag
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? entries = null,
  }) {
    return _then(_value.copyWith(
      entries: null == entries
          ? _value.entries
          : entries // ignore: cast_nullable_to_non_nullable
              as List<BagEntry>,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$BagImplCopyWith<$Res> implements $BagCopyWith<$Res> {
  factory _$$BagImplCopyWith(_$BagImpl value, $Res Function(_$BagImpl) then) =
      __$$BagImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({List<BagEntry> entries});
}

/// @nodoc
class __$$BagImplCopyWithImpl<$Res> extends _$BagCopyWithImpl<$Res, _$BagImpl>
    implements _$$BagImplCopyWith<$Res> {
  __$$BagImplCopyWithImpl(_$BagImpl _value, $Res Function(_$BagImpl) _then)
      : super(_value, _then);

  /// Create a copy of Bag
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? entries = null,
  }) {
    return _then(_$BagImpl(
      entries: null == entries
          ? _value._entries
          : entries // ignore: cast_nullable_to_non_nullable
              as List<BagEntry>,
    ));
  }
}

/// @nodoc

@JsonSerializable(explicitToJson: true)
class _$BagImpl extends _Bag {
  const _$BagImpl({final List<BagEntry> entries = const []})
      : _entries = entries,
        super._();

  factory _$BagImpl.fromJson(Map<String, dynamic> json) =>
      _$$BagImplFromJson(json);

  final List<BagEntry> _entries;
  @override
  @JsonKey()
  List<BagEntry> get entries {
    if (_entries is EqualUnmodifiableListView) return _entries;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_entries);
  }

  @override
  String toString() {
    return 'Bag(entries: $entries)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$BagImpl &&
            const DeepCollectionEquality().equals(other._entries, _entries));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, const DeepCollectionEquality().hash(_entries));

  /// Create a copy of Bag
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$BagImplCopyWith<_$BagImpl> get copyWith =>
      __$$BagImplCopyWithImpl<_$BagImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$BagImplToJson(
      this,
    );
  }
}

abstract class _Bag extends Bag {
  const factory _Bag({final List<BagEntry> entries}) = _$BagImpl;
  const _Bag._() : super._();

  factory _Bag.fromJson(Map<String, dynamic> json) = _$BagImpl.fromJson;

  @override
  List<BagEntry> get entries;

  /// Create a copy of Bag
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$BagImplCopyWith<_$BagImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

SaveData _$SaveDataFromJson(Map<String, dynamic> json) {
  return _SaveData.fromJson(json);
}

/// @nodoc
mixin _$SaveData {
  String get saveId => throw _privateConstructorUsedError;
  String get currentMapId => throw _privateConstructorUsedError;
  GridPos get playerPosition => throw _privateConstructorUsedError;
  EntityFacing get playerFacing => throw _privateConstructorUsedError;
  PlayerParty get party => throw _privateConstructorUsedError;
  TrainerProfile get trainerProfile => throw _privateConstructorUsedError;
  Bag get bag => throw _privateConstructorUsedError;
  PlayerProgression get progression => throw _privateConstructorUsedError;
  Map<String, String> get properties => throw _privateConstructorUsedError;

  /// Serializes this SaveData to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of SaveData
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $SaveDataCopyWith<SaveData> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $SaveDataCopyWith<$Res> {
  factory $SaveDataCopyWith(SaveData value, $Res Function(SaveData) then) =
      _$SaveDataCopyWithImpl<$Res, SaveData>;
  @useResult
  $Res call(
      {String saveId,
      String currentMapId,
      GridPos playerPosition,
      EntityFacing playerFacing,
      PlayerParty party,
      TrainerProfile trainerProfile,
      Bag bag,
      PlayerProgression progression,
      Map<String, String> properties});

  $GridPosCopyWith<$Res> get playerPosition;
  $PlayerPartyCopyWith<$Res> get party;
  $TrainerProfileCopyWith<$Res> get trainerProfile;
  $BagCopyWith<$Res> get bag;
  $PlayerProgressionCopyWith<$Res> get progression;
}

/// @nodoc
class _$SaveDataCopyWithImpl<$Res, $Val extends SaveData>
    implements $SaveDataCopyWith<$Res> {
  _$SaveDataCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of SaveData
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? saveId = null,
    Object? currentMapId = null,
    Object? playerPosition = null,
    Object? playerFacing = null,
    Object? party = null,
    Object? trainerProfile = null,
    Object? bag = null,
    Object? progression = null,
    Object? properties = null,
  }) {
    return _then(_value.copyWith(
      saveId: null == saveId
          ? _value.saveId
          : saveId // ignore: cast_nullable_to_non_nullable
              as String,
      currentMapId: null == currentMapId
          ? _value.currentMapId
          : currentMapId // ignore: cast_nullable_to_non_nullable
              as String,
      playerPosition: null == playerPosition
          ? _value.playerPosition
          : playerPosition // ignore: cast_nullable_to_non_nullable
              as GridPos,
      playerFacing: null == playerFacing
          ? _value.playerFacing
          : playerFacing // ignore: cast_nullable_to_non_nullable
              as EntityFacing,
      party: null == party
          ? _value.party
          : party // ignore: cast_nullable_to_non_nullable
              as PlayerParty,
      trainerProfile: null == trainerProfile
          ? _value.trainerProfile
          : trainerProfile // ignore: cast_nullable_to_non_nullable
              as TrainerProfile,
      bag: null == bag
          ? _value.bag
          : bag // ignore: cast_nullable_to_non_nullable
              as Bag,
      progression: null == progression
          ? _value.progression
          : progression // ignore: cast_nullable_to_non_nullable
              as PlayerProgression,
      properties: null == properties
          ? _value.properties
          : properties // ignore: cast_nullable_to_non_nullable
              as Map<String, String>,
    ) as $Val);
  }

  /// Create a copy of SaveData
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $GridPosCopyWith<$Res> get playerPosition {
    return $GridPosCopyWith<$Res>(_value.playerPosition, (value) {
      return _then(_value.copyWith(playerPosition: value) as $Val);
    });
  }

  /// Create a copy of SaveData
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $PlayerPartyCopyWith<$Res> get party {
    return $PlayerPartyCopyWith<$Res>(_value.party, (value) {
      return _then(_value.copyWith(party: value) as $Val);
    });
  }

  /// Create a copy of SaveData
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $TrainerProfileCopyWith<$Res> get trainerProfile {
    return $TrainerProfileCopyWith<$Res>(_value.trainerProfile, (value) {
      return _then(_value.copyWith(trainerProfile: value) as $Val);
    });
  }

  /// Create a copy of SaveData
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $BagCopyWith<$Res> get bag {
    return $BagCopyWith<$Res>(_value.bag, (value) {
      return _then(_value.copyWith(bag: value) as $Val);
    });
  }

  /// Create a copy of SaveData
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $PlayerProgressionCopyWith<$Res> get progression {
    return $PlayerProgressionCopyWith<$Res>(_value.progression, (value) {
      return _then(_value.copyWith(progression: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$SaveDataImplCopyWith<$Res>
    implements $SaveDataCopyWith<$Res> {
  factory _$$SaveDataImplCopyWith(
          _$SaveDataImpl value, $Res Function(_$SaveDataImpl) then) =
      __$$SaveDataImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String saveId,
      String currentMapId,
      GridPos playerPosition,
      EntityFacing playerFacing,
      PlayerParty party,
      TrainerProfile trainerProfile,
      Bag bag,
      PlayerProgression progression,
      Map<String, String> properties});

  @override
  $GridPosCopyWith<$Res> get playerPosition;
  @override
  $PlayerPartyCopyWith<$Res> get party;
  @override
  $TrainerProfileCopyWith<$Res> get trainerProfile;
  @override
  $BagCopyWith<$Res> get bag;
  @override
  $PlayerProgressionCopyWith<$Res> get progression;
}

/// @nodoc
class __$$SaveDataImplCopyWithImpl<$Res>
    extends _$SaveDataCopyWithImpl<$Res, _$SaveDataImpl>
    implements _$$SaveDataImplCopyWith<$Res> {
  __$$SaveDataImplCopyWithImpl(
      _$SaveDataImpl _value, $Res Function(_$SaveDataImpl) _then)
      : super(_value, _then);

  /// Create a copy of SaveData
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? saveId = null,
    Object? currentMapId = null,
    Object? playerPosition = null,
    Object? playerFacing = null,
    Object? party = null,
    Object? trainerProfile = null,
    Object? bag = null,
    Object? progression = null,
    Object? properties = null,
  }) {
    return _then(_$SaveDataImpl(
      saveId: null == saveId
          ? _value.saveId
          : saveId // ignore: cast_nullable_to_non_nullable
              as String,
      currentMapId: null == currentMapId
          ? _value.currentMapId
          : currentMapId // ignore: cast_nullable_to_non_nullable
              as String,
      playerPosition: null == playerPosition
          ? _value.playerPosition
          : playerPosition // ignore: cast_nullable_to_non_nullable
              as GridPos,
      playerFacing: null == playerFacing
          ? _value.playerFacing
          : playerFacing // ignore: cast_nullable_to_non_nullable
              as EntityFacing,
      party: null == party
          ? _value.party
          : party // ignore: cast_nullable_to_non_nullable
              as PlayerParty,
      trainerProfile: null == trainerProfile
          ? _value.trainerProfile
          : trainerProfile // ignore: cast_nullable_to_non_nullable
              as TrainerProfile,
      bag: null == bag
          ? _value.bag
          : bag // ignore: cast_nullable_to_non_nullable
              as Bag,
      progression: null == progression
          ? _value.progression
          : progression // ignore: cast_nullable_to_non_nullable
              as PlayerProgression,
      properties: null == properties
          ? _value._properties
          : properties // ignore: cast_nullable_to_non_nullable
              as Map<String, String>,
    ));
  }
}

/// @nodoc

@JsonSerializable(explicitToJson: true)
class _$SaveDataImpl extends _SaveData {
  const _$SaveDataImpl(
      {required this.saveId,
      this.currentMapId = '',
      this.playerPosition = const GridPos(x: 0, y: 0),
      this.playerFacing = EntityFacing.south,
      this.party = const PlayerParty(),
      this.trainerProfile = const TrainerProfile(name: 'Player'),
      this.bag = const Bag(),
      this.progression = const PlayerProgression(),
      final Map<String, String> properties = const {}})
      : _properties = properties,
        super._();

  factory _$SaveDataImpl.fromJson(Map<String, dynamic> json) =>
      _$$SaveDataImplFromJson(json);

  @override
  final String saveId;
  @override
  @JsonKey()
  final String currentMapId;
  @override
  @JsonKey()
  final GridPos playerPosition;
  @override
  @JsonKey()
  final EntityFacing playerFacing;
  @override
  @JsonKey()
  final PlayerParty party;
  @override
  @JsonKey()
  final TrainerProfile trainerProfile;
  @override
  @JsonKey()
  final Bag bag;
  @override
  @JsonKey()
  final PlayerProgression progression;
  final Map<String, String> _properties;
  @override
  @JsonKey()
  Map<String, String> get properties {
    if (_properties is EqualUnmodifiableMapView) return _properties;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_properties);
  }

  @override
  String toString() {
    return 'SaveData(saveId: $saveId, currentMapId: $currentMapId, playerPosition: $playerPosition, playerFacing: $playerFacing, party: $party, trainerProfile: $trainerProfile, bag: $bag, progression: $progression, properties: $properties)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SaveDataImpl &&
            (identical(other.saveId, saveId) || other.saveId == saveId) &&
            (identical(other.currentMapId, currentMapId) ||
                other.currentMapId == currentMapId) &&
            (identical(other.playerPosition, playerPosition) ||
                other.playerPosition == playerPosition) &&
            (identical(other.playerFacing, playerFacing) ||
                other.playerFacing == playerFacing) &&
            (identical(other.party, party) || other.party == party) &&
            (identical(other.trainerProfile, trainerProfile) ||
                other.trainerProfile == trainerProfile) &&
            (identical(other.bag, bag) || other.bag == bag) &&
            (identical(other.progression, progression) ||
                other.progression == progression) &&
            const DeepCollectionEquality()
                .equals(other._properties, _properties));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      saveId,
      currentMapId,
      playerPosition,
      playerFacing,
      party,
      trainerProfile,
      bag,
      progression,
      const DeepCollectionEquality().hash(_properties));

  /// Create a copy of SaveData
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$SaveDataImplCopyWith<_$SaveDataImpl> get copyWith =>
      __$$SaveDataImplCopyWithImpl<_$SaveDataImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$SaveDataImplToJson(
      this,
    );
  }
}

abstract class _SaveData extends SaveData {
  const factory _SaveData(
      {required final String saveId,
      final String currentMapId,
      final GridPos playerPosition,
      final EntityFacing playerFacing,
      final PlayerParty party,
      final TrainerProfile trainerProfile,
      final Bag bag,
      final PlayerProgression progression,
      final Map<String, String> properties}) = _$SaveDataImpl;
  const _SaveData._() : super._();

  factory _SaveData.fromJson(Map<String, dynamic> json) =
      _$SaveDataImpl.fromJson;

  @override
  String get saveId;
  @override
  String get currentMapId;
  @override
  GridPos get playerPosition;
  @override
  EntityFacing get playerFacing;
  @override
  PlayerParty get party;
  @override
  TrainerProfile get trainerProfile;
  @override
  Bag get bag;
  @override
  PlayerProgression get progression;
  @override
  Map<String, String> get properties;

  /// Create a copy of SaveData
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$SaveDataImplCopyWith<_$SaveDataImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

```

### `packages/map_core/lib/src/models/save_data.g.dart`

```dart
// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'save_data.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$PokemonStatSpreadImpl _$$PokemonStatSpreadImplFromJson(
        Map<String, dynamic> json) =>
    _$PokemonStatSpreadImpl(
      hp: (json['hp'] as num?)?.toInt() ?? 0,
      attack: (json['attack'] as num?)?.toInt() ?? 0,
      defense: (json['defense'] as num?)?.toInt() ?? 0,
      specialAttack: (json['specialAttack'] as num?)?.toInt() ?? 0,
      specialDefense: (json['specialDefense'] as num?)?.toInt() ?? 0,
      speed: (json['speed'] as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> _$$PokemonStatSpreadImplToJson(
        _$PokemonStatSpreadImpl instance) =>
    <String, dynamic>{
      'hp': instance.hp,
      'attack': instance.attack,
      'defense': instance.defense,
      'specialAttack': instance.specialAttack,
      'specialDefense': instance.specialDefense,
      'speed': instance.speed,
    };

_$PlayerPokemonImpl _$$PlayerPokemonImplFromJson(Map<String, dynamic> json) =>
    _$PlayerPokemonImpl(
      speciesId: json['speciesId'] as String,
      natureId: json['natureId'] as String,
      abilityId: json['abilityId'] as String,
      level: (json['level'] as num?)?.toInt() ?? 1,
      ivs: json['ivs'] == null
          ? const PokemonStatSpread()
          : PokemonStatSpread.fromJson(json['ivs'] as Map<String, dynamic>),
      evs: json['evs'] == null
          ? const PokemonStatSpread()
          : PokemonStatSpread.fromJson(json['evs'] as Map<String, dynamic>),
      knownMoveIds: (json['knownMoveIds'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      currentHp: (json['currentHp'] as num?)?.toInt() ?? 1,
      statusId: json['statusId'] as String? ?? '',
      isShiny: json['isShiny'] as bool? ?? false,
      heldItemId: json['heldItemId'] as String? ?? '',
    );

Map<String, dynamic> _$$PlayerPokemonImplToJson(_$PlayerPokemonImpl instance) =>
    <String, dynamic>{
      'speciesId': instance.speciesId,
      'natureId': instance.natureId,
      'abilityId': instance.abilityId,
      'level': instance.level,
      'ivs': instance.ivs.toJson(),
      'evs': instance.evs.toJson(),
      'knownMoveIds': instance.knownMoveIds,
      'currentHp': instance.currentHp,
      'statusId': instance.statusId,
      'isShiny': instance.isShiny,
      'heldItemId': instance.heldItemId,
    };

_$PlayerPartyImpl _$$PlayerPartyImplFromJson(Map<String, dynamic> json) =>
    _$PlayerPartyImpl(
      members: (json['members'] as List<dynamic>?)
              ?.map((e) => PlayerPokemon.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );

Map<String, dynamic> _$$PlayerPartyImplToJson(_$PlayerPartyImpl instance) =>
    <String, dynamic>{
      'members': instance.members.map((e) => e.toJson()).toList(),
    };

_$PlayerProgressionImpl _$$PlayerProgressionImplFromJson(
        Map<String, dynamic> json) =>
    _$PlayerProgressionImpl(
      unlockedFieldAbilities: (json['unlockedFieldAbilities'] as List<dynamic>?)
              ?.map((e) => $enumDecode(_$FieldAbilityEnumMap, e))
              .toList() ??
          const [],
      storyFlags: (json['storyFlags'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      completedStepIds: (json['completedStepIds'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      completedCutsceneIds: (json['completedCutsceneIds'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
    );

Map<String, dynamic> _$$PlayerProgressionImplToJson(
        _$PlayerProgressionImpl instance) =>
    <String, dynamic>{
      'unlockedFieldAbilities': instance.unlockedFieldAbilities
          .map((e) => _$FieldAbilityEnumMap[e]!)
          .toList(),
      'storyFlags': instance.storyFlags,
      'completedStepIds': instance.completedStepIds,
      'completedCutsceneIds': instance.completedCutsceneIds,
    };

const _$FieldAbilityEnumMap = {
  FieldAbility.surf: 'surf',
  FieldAbility.cut: 'cut',
  FieldAbility.strength: 'strength',
  FieldAbility.flash: 'flash',
  FieldAbility.rockSmash: 'rock_smash',
  FieldAbility.waterfall: 'waterfall',
  FieldAbility.dive: 'dive',
};

_$TrainerProfileImpl _$$TrainerProfileImplFromJson(Map<String, dynamic> json) =>
    _$TrainerProfileImpl(
      name: json['name'] as String,
      badgeIds: (json['badgeIds'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      money: (json['money'] as num?)?.toInt() ?? 0,
      playtimeSeconds: (json['playtimeSeconds'] as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> _$$TrainerProfileImplToJson(
        _$TrainerProfileImpl instance) =>
    <String, dynamic>{
      'name': instance.name,
      'badgeIds': instance.badgeIds,
      'money': instance.money,
      'playtimeSeconds': instance.playtimeSeconds,
    };

_$BagEntryImpl _$$BagEntryImplFromJson(Map<String, dynamic> json) =>
    _$BagEntryImpl(
      itemId: json['itemId'] as String,
      categoryId: json['categoryId'] as String,
      quantity: (json['quantity'] as num).toInt(),
    );

Map<String, dynamic> _$$BagEntryImplToJson(_$BagEntryImpl instance) =>
    <String, dynamic>{
      'itemId': instance.itemId,
      'categoryId': instance.categoryId,
      'quantity': instance.quantity,
    };

_$BagImpl _$$BagImplFromJson(Map<String, dynamic> json) => _$BagImpl(
      entries: (json['entries'] as List<dynamic>?)
              ?.map((e) => BagEntry.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );

Map<String, dynamic> _$$BagImplToJson(_$BagImpl instance) => <String, dynamic>{
      'entries': instance.entries.map((e) => e.toJson()).toList(),
    };

_$SaveDataImpl _$$SaveDataImplFromJson(Map<String, dynamic> json) =>
    _$SaveDataImpl(
      saveId: json['saveId'] as String,
      currentMapId: json['currentMapId'] as String? ?? '',
      playerPosition: json['playerPosition'] == null
          ? const GridPos(x: 0, y: 0)
          : GridPos.fromJson(json['playerPosition'] as Map<String, dynamic>),
      playerFacing:
          $enumDecodeNullable(_$EntityFacingEnumMap, json['playerFacing']) ??
              EntityFacing.south,
      party: json['party'] == null
          ? const PlayerParty()
          : PlayerParty.fromJson(json['party'] as Map<String, dynamic>),
      trainerProfile: json['trainerProfile'] == null
          ? const TrainerProfile(name: 'Player')
          : TrainerProfile.fromJson(
              json['trainerProfile'] as Map<String, dynamic>),
      bag: json['bag'] == null
          ? const Bag()
          : Bag.fromJson(json['bag'] as Map<String, dynamic>),
      progression: json['progression'] == null
          ? const PlayerProgression()
          : PlayerProgression.fromJson(
              json['progression'] as Map<String, dynamic>),
      properties: (json['properties'] as Map<String, dynamic>?)?.map(
            (k, e) => MapEntry(k, e as String),
          ) ??
          const {},
    );

Map<String, dynamic> _$$SaveDataImplToJson(_$SaveDataImpl instance) =>
    <String, dynamic>{
      'saveId': instance.saveId,
      'currentMapId': instance.currentMapId,
      'playerPosition': instance.playerPosition.toJson(),
      'playerFacing': _$EntityFacingEnumMap[instance.playerFacing]!,
      'party': instance.party.toJson(),
      'trainerProfile': instance.trainerProfile.toJson(),
      'bag': instance.bag.toJson(),
      'progression': instance.progression.toJson(),
      'properties': instance.properties,
    };

const _$EntityFacingEnumMap = {
  EntityFacing.north: 'north',
  EntityFacing.south: 'south',
  EntityFacing.east: 'east',
  EntityFacing.west: 'west',
};

```

### `packages/map_core/lib/src/operations/game_state_persistence.dart`

```dart
import '../models/enums.dart';
import '../models/game_state.dart';
import '../models/save_data.dart';

GameState gameStateFromSaveData(SaveData saveData) {
  final normalizedSaveData = saveData.normalized();
  final migratedFlags = normalizedSaveData.progression.storyFlags
      .map((flag) => flag.trim())
      .where((flag) => flag.isNotEmpty)
      .toSet();

  return GameState(
    saveId: normalizedSaveData.saveId,
    currentMapId: normalizedSaveData.currentMapId,
    playerPosition: normalizedSaveData.playerPosition,
    playerFacing: normalizedSaveData.playerFacing,
    playerMovementMode: MovementMode.walk,
    party: normalizedSaveData.party,
    trainerProfile: normalizedSaveData.trainerProfile,
    bag: normalizedSaveData.bag,
    progression: normalizedSaveData.progression,
    storyFlags: StoryFlags(activeFlags: migratedFlags),
    scriptVariables: const ScriptVariables(),
    consumedEventIds: const {},
    metadata: normalizedSaveData.properties,
  );
}

SaveData saveDataFromGameState(GameState gameState) {
  final mergedProgressionFlags = <String>{
    ...gameState.progression.storyFlags,
    ...gameState.storyFlags.activeFlags,
  };

  return SaveData(
    saveId: gameState.saveId,
    currentMapId: gameState.currentMapId,
    playerPosition: gameState.playerPosition,
    playerFacing: gameState.playerFacing,
    party: gameState.party,
    trainerProfile: gameState.trainerProfile,
    bag: gameState.bag,
    progression: gameState.progression.copyWith(
      storyFlags: mergedProgressionFlags.toList(growable: false),
    ),
    properties: gameState.metadata,
  ).normalized();
}

GameState normalizeLoadedGameState(GameState state) {
  if (state.storyFlags.activeFlags.isNotEmpty ||
      state.progression.storyFlags.isEmpty) {
    return state;
  }
  final migratedFlags = state.progression.storyFlags
      .map((flag) => flag.trim())
      .where((flag) => flag.isNotEmpty)
      .toSet();
  return state.copyWith(
    storyFlags: state.storyFlags.copyWith(activeFlags: migratedFlags),
  );
}

```

### `packages/map_core/test/game_state_persistence_test.dart`

```dart
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('gameStateFromSaveData', () {
    test('migrates legacy save fields to GameState', () {
      const save = SaveData(
        saveId: 'legacy_1',
        currentMapId: 'vova_center',
        playerPosition: GridPos(x: 7, y: 9),
        playerFacing: EntityFacing.west,
        party: PlayerParty(
          members: [
            PlayerPokemon(
              speciesId: 'lapras',
              natureId: 'modest',
              abilityId: 'water-absorb',
              knownMoveIds: ['surf'],
            ),
          ],
        ),
        trainerProfile: TrainerProfile(
          name: 'Red',
          badgeIds: ['boulder'],
          money: 1200,
          playtimeSeconds: 42,
        ),
        bag: Bag(
          entries: [
            BagEntry(itemId: 'poke-ball', categoryId: 'items', quantity: 3),
          ],
        ),
        progression: PlayerProgression(
          unlockedFieldAbilities: [FieldAbility.surf],
          storyFlags: ['met_professor', 'starter_received'],
          completedStepIds: ['step_a'],
        ),
        properties: {'legacy': 'ok'},
      );

      final state = gameStateFromSaveData(save);

      expect(state.saveId, equals('legacy_1'));
      expect(state.currentMapId, equals('vova_center'));
      expect(state.playerPosition, equals(const GridPos(x: 7, y: 9)));
      expect(state.playerFacing, equals(EntityFacing.west));
      expect(state.party.members.length, equals(1));
      expect(state.trainerProfile.name, equals('Red'));
      expect(state.bag.entries.single.itemId, equals('poke-ball'));
      expect(state.progression.unlockedFieldAbilities,
          contains(FieldAbility.surf));
      expect(state.storyFlags.activeFlags,
          containsAll(['met_professor', 'starter_received']));
      expect(state.progression.completedStepIds, ['step_a']);
      expect(state.metadata['legacy'], equals('ok'));
    });
  });

  group('saveDataFromGameState', () {
    test('keeps core fields and merges story flags in legacy slot', () {
      final state = GameState(
        saveId: 'save_2',
        currentMapId: 'route_1',
        playerPosition: const GridPos(x: 3, y: 4),
        playerFacing: EntityFacing.north,
        trainerProfile: const TrainerProfile(
          name: 'Leaf',
          badgeIds: ['cascade', 'boulder'],
          money: 500,
          playtimeSeconds: 99,
        ),
        bag: const Bag(
          entries: [
            BagEntry(itemId: 'potion', categoryId: 'medicine', quantity: 2),
            BagEntry(itemId: 'poke-ball', categoryId: 'items', quantity: 5),
          ],
        ),
        progression: const PlayerProgression(
          storyFlags: ['from_progression'],
          completedStepIds: ['step_done'],
        ),
        storyFlags: const StoryFlags(activeFlags: {'from_story_flags'}),
      );

      final save = saveDataFromGameState(state);

      expect(save.saveId, equals('save_2'));
      expect(save.currentMapId, equals('route_1'));
      expect(save.playerPosition, equals(const GridPos(x: 3, y: 4)));
      expect(save.playerFacing, equals(EntityFacing.north));
      expect(save.trainerProfile.name, equals('Leaf'));
      expect(save.trainerProfile.badgeIds, equals(['boulder', 'cascade']));
      expect(save.bag.entries.length, equals(2));
      expect(
        save.progression.storyFlags.toSet(),
        containsAll(<String>{'from_progression', 'from_story_flags'}),
      );
      expect(save.progression.completedStepIds, ['step_done']);
    });
  });

  group('normalizeLoadedGameState', () {
    test('hydrates storyFlags from progression when storyFlags are empty', () {
      final state = GameState(
        saveId: 'save_3',
        progression: const PlayerProgression(
          storyFlags: ['trainer_defeated:gym_leader_1', 'badge_cascade'],
        ),
        storyFlags: const StoryFlags(activeFlags: <String>{}),
      );

      final normalized = normalizeLoadedGameState(state);

      expect(
        normalized.storyFlags.activeFlags,
        containsAll(['trainer_defeated:gym_leader_1', 'badge_cascade']),
      );
    });

    test('keeps explicit storyFlags as source of truth when already set', () {
      final state = GameState(
        saveId: 'save_4',
        progression: const PlayerProgression(storyFlags: ['legacy_flag']),
        storyFlags: const StoryFlags(activeFlags: {'runtime_flag'}),
      );

      final normalized = normalizeLoadedGameState(state);

      expect(normalized.storyFlags.activeFlags, equals({'runtime_flag'}));
    });
  });
}

```

### `packages/map_core/test/save_data_test.dart`

```dart
import 'dart:convert';

import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('PokemonStatSpread', () {
    test('serialization round-trip', () {
      const stats = PokemonStatSpread(
        hp: 31,
        attack: 30,
        defense: 29,
        specialAttack: 28,
        specialDefense: 27,
        speed: 26,
      );

      final json = stats.toJson();
      final restored = PokemonStatSpread.fromJson(json);

      expect(restored, stats);
    });
  });

  group('PlayerPokemon', () {
    test('serialization round-trip', () {
      const pokemon = PlayerPokemon(
        speciesId: 'lapras',
        natureId: 'modest',
        abilityId: 'water-absorb',
        level: 30,
        ivs: PokemonStatSpread(
          hp: 31,
          attack: 12,
          defense: 22,
          specialAttack: 31,
          specialDefense: 25,
          speed: 18,
        ),
        evs: PokemonStatSpread(
          hp: 0,
          attack: 0,
          defense: 4,
          specialAttack: 252,
          specialDefense: 0,
          speed: 252,
        ),
        knownMoveIds: ['surf', 'ice_beam'],
        currentHp: 99,
        statusId: 'poison',
        isShiny: true,
        heldItemId: 'mystic-water',
      );
      final json = pokemon.toJson();
      final restored = PlayerPokemon.fromJson(json);
      expect(restored, pokemon);
    });

    test('defaults are coherent', () {
      const pokemon = PlayerPokemon(
        speciesId: 'magikarp',
        natureId: 'hardy',
        abilityId: 'swift-swim',
      );
      expect(pokemon.level, 1);
      expect(pokemon.knownMoveIds, isEmpty);
      expect(pokemon.currentHp, 1);
      expect(pokemon.isFainted, false);
    });

    test('JSON keys match expected structure', () {
      const pokemon = PlayerPokemon(
        speciesId: 'pikachu',
        natureId: 'jolly',
        abilityId: 'static',
        knownMoveIds: ['thunderbolt'],
      );
      final json = pokemon.toJson();
      expect(json['speciesId'], 'pikachu');
      expect(json['natureId'], 'jolly');
      expect(json['abilityId'], 'static');
      expect(json['knownMoveIds'], ['thunderbolt']);
      expect(json['currentHp'], 1);
    });

    test('normalized rejects more than four moves', () {
      const pokemon = PlayerPokemon(
        speciesId: 'pikachu',
        natureId: 'jolly',
        abilityId: 'static',
        knownMoveIds: ['tackle', 'growl', 'quick-attack', 'slam', 'surf'],
      );

      expect(() => pokemon.normalized(), throwsStateError);
    });
  });

  group('PlayerParty', () {
    test('serialization round-trip', () {
      const party = PlayerParty(members: [
        PlayerPokemon(
          speciesId: 'lapras',
          natureId: 'modest',
          abilityId: 'water-absorb',
          knownMoveIds: ['surf'],
        ),
        PlayerPokemon(
          speciesId: 'pikachu',
          natureId: 'timid',
          abilityId: 'static',
        ),
      ]);
      final json = party.toJson();
      final restored = PlayerParty.fromJson(json);
      expect(restored.members.length, 2);
      expect(restored.members[0].speciesId, 'lapras');
    });

    test('default is empty party', () {
      const party = PlayerParty();
      expect(party.members, isEmpty);
    });
  });

  group('PlayerProgression', () {
    test('serialization round-trip', () {
      const progression = PlayerProgression(
        unlockedFieldAbilities: [FieldAbility.surf],
        storyFlags: ['badge_cascade', 'rescued_bill'],
        completedStepIds: ['step_intro', 'step_2_1'],
      );
      final json = progression.toJson();
      final restored = PlayerProgression.fromJson(json);
      expect(restored.unlockedFieldAbilities, [FieldAbility.surf]);
      expect(restored.storyFlags, ['badge_cascade', 'rescued_bill']);
      expect(restored.completedStepIds, ['step_intro', 'step_2_1']);
    });

    test('defaults are empty', () {
      const progression = PlayerProgression();
      expect(progression.unlockedFieldAbilities, isEmpty);
      expect(progression.storyFlags, isEmpty);
      expect(progression.completedStepIds, isEmpty);
    });
  });

  group('TrainerProfile', () {
    test('serialization round-trip', () {
      const profile = TrainerProfile(
        name: 'Red',
        badgeIds: ['boulder', 'cascade'],
        money: 4200,
        playtimeSeconds: 3600,
      );

      final json = profile.toJson();
      final restored = TrainerProfile.fromJson(json);

      expect(restored, profile);
    });

    test('normalized badges are stable', () {
      const profile = TrainerProfile(
        name: ' Red ',
        badgeIds: ['cascade', 'boulder', 'cascade'],
      );

      final normalized = profile.normalized();

      expect(normalized.name, 'Red');
      expect(normalized.badgeIds, ['boulder', 'cascade']);
    });

    test('normalized rejects empty names', () {
      const profile = TrainerProfile(name: '   ');

      expect(() => profile.normalized(), throwsStateError);
    });
  });

  group('Bag', () {
    test('serialization round-trip', () {
      const bag = Bag(
        entries: [
          BagEntry(itemId: 'poke-ball', categoryId: 'items', quantity: 10),
          BagEntry(itemId: 'potion', categoryId: 'medicine', quantity: 3),
        ],
      );

      final json = bag.toJson();
      final restored = Bag.fromJson(json);

      expect(restored, bag);
    });

    test('normalized entries merge duplicates deterministically', () {
      const bag = Bag(
        entries: [
          BagEntry(itemId: 'potion', categoryId: 'medicine', quantity: 2),
          BagEntry(itemId: 'poke-ball', categoryId: 'items', quantity: 5),
          BagEntry(itemId: 'potion', categoryId: 'medicine', quantity: 3),
        ],
      );

      final normalized = bag.normalized();

      expect(normalized.entries, [
        const BagEntry(itemId: 'poke-ball', categoryId: 'items', quantity: 5),
        const BagEntry(itemId: 'potion', categoryId: 'medicine', quantity: 5),
      ]);
    });

    test('normalized rejects non-positive quantities', () {
      const bag = Bag(
        entries: [
          BagEntry(itemId: 'potion', categoryId: 'medicine', quantity: 0),
        ],
      );

      expect(() => bag.normalized(), throwsStateError);
    });
  });

  group('SaveData', () {
    test('serialization round-trip', () {
      const save = SaveData(
        saveId: 'save_001',
        currentMapId: 'pallet_town',
        playerPosition: GridPos(x: 5, y: 3),
        playerFacing: EntityFacing.north,
        party: PlayerParty(members: [
          PlayerPokemon(
            speciesId: 'squirtle',
            natureId: 'bold',
            abilityId: 'torrent',
            level: 12,
            knownMoveIds: ['surf', 'water_gun'],
          ),
        ]),
        trainerProfile: TrainerProfile(
          name: 'Leaf',
          badgeIds: ['cascade'],
          money: 1200,
          playtimeSeconds: 180,
        ),
        bag: Bag(
          entries: [
            BagEntry(itemId: 'poke-ball', categoryId: 'items', quantity: 5),
          ],
        ),
        progression: PlayerProgression(
          unlockedFieldAbilities: [FieldAbility.surf],
          storyFlags: ['intro_done'],
        ),
        properties: {'lastHealLocation': 'pokemon_center_1'},
      );

      final json = save.toJson();
      final jsonString = jsonEncode(json);
      final decoded = jsonDecode(jsonString) as Map<String, dynamic>;
      final restored = SaveData.fromJson(decoded);

      expect(restored.saveId, 'save_001');
      expect(restored.currentMapId, 'pallet_town');
      expect(restored.playerPosition, const GridPos(x: 5, y: 3));
      expect(restored.playerFacing, EntityFacing.north);
      expect(restored.party.members.length, 1);
      expect(restored.party.members.first.speciesId, 'squirtle');
      expect(restored.trainerProfile.name, 'Leaf');
      expect(restored.bag.entries.single.itemId, 'poke-ball');
      expect(restored.progression.unlockedFieldAbilities, [FieldAbility.surf]);
      expect(restored.properties['lastHealLocation'], 'pokemon_center_1');
    });

    test('defaults are coherent', () {
      const save = SaveData(saveId: 'test');
      expect(save.currentMapId, '');
      expect(save.playerPosition, const GridPos(x: 0, y: 0));
      expect(save.playerFacing, EntityFacing.south);
      expect(save.party.members, isEmpty);
      expect(save.trainerProfile.name, 'Player');
      expect(save.bag.entries, isEmpty);
      expect(save.progression.unlockedFieldAbilities, isEmpty);
      expect(save.progression.storyFlags, isEmpty);
      expect(save.progression.completedStepIds, isEmpty);
      expect(save.properties, isEmpty);
    });

    test('copyWith preserves unmodified fields', () {
      const save = SaveData(
        saveId: 'test',
        currentMapId: 'route_1',
        party: PlayerParty(members: [
          PlayerPokemon(
            speciesId: 'bulbasaur',
            natureId: 'hardy',
            abilityId: 'overgrow',
          ),
        ]),
      );
      final updated = save.copyWith(currentMapId: 'route_2');
      expect(updated.saveId, 'test');
      expect(updated.currentMapId, 'route_2');
      expect(updated.party.members.length, 1);
    });
  });

  group('FieldAbility', () {
    test('JSON values match expected strings', () {
      const save = SaveData(
        saveId: 'test',
        progression: PlayerProgression(
          unlockedFieldAbilities: [
            FieldAbility.surf,
            FieldAbility.cut,
            FieldAbility.strength,
          ],
        ),
      );
      final json = save.toJson();
      final abilities = (json['progression']
          as Map<String, dynamic>)['unlockedFieldAbilities'] as List;
      expect(abilities, ['surf', 'cut', 'strength']);
    });
  });
}

```

### `packages/map_gameplay/test/script_system_integration_test.dart`

```dart
import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:test/test.dart';

void main() {
  final evaluator = const ScriptConditionEvaluator();
  final pageResolver = const EventPageResolver();
  final mutations = const GameStateMutations();

  group('GameState Mutations', () {
    test('setFlag adds flag to activeFlags', () {
      final initialState = GameState(
        saveId: 'test-save',
        storyFlags: const StoryFlags(activeFlags: {}),
      );

      final newState = mutations.setFlag(initialState, 'professor_met');

      expect(newState.storyFlags.activeFlags, contains('professor_met'));
    });

    test('setFlag is idempotent', () {
      final initialState = GameState(
        saveId: 'test-save',
        storyFlags: const StoryFlags(activeFlags: {'professor_met'}),
      );

      final newState = mutations.setFlag(initialState, 'professor_met');

      expect(newState.storyFlags.activeFlags.length, equals(1));
      expect(newState.storyFlags.activeFlags, contains('professor_met'));
    });

    test('clearFlag removes flag from activeFlags', () {
      final initialState = GameState(
        saveId: 'test-save',
        storyFlags: const StoryFlags(
            activeFlags: {'professor_met', 'starter_received'}),
      );

      final newState = mutations.clearFlag(initialState, 'professor_met');

      expect(newState.storyFlags.activeFlags, isNot(contains('professor_met')));
      expect(newState.storyFlags.activeFlags, contains('starter_received'));
    });
  });

  group('ScriptConditionEvaluator', () {
    test('flagIsSet returns true when flag is active', () {
      final state = GameState(
        saveId: 'test-save',
        storyFlags: const StoryFlags(activeFlags: {'professor_met'}),
      );

      final condition = ScriptCondition(
        type: ScriptConditionType.flagIsSet,
        params: {ScriptConditionParams.flagName: 'professor_met'},
      );
      final result = evaluator.evaluate(condition, state);

      expect(result, isTrue);
    });

    test('flagIsSet returns false when flag is not active', () {
      final state = GameState(
        saveId: 'test-save',
        storyFlags: const StoryFlags(activeFlags: {}),
      );

      final condition = ScriptCondition(
        type: ScriptConditionType.flagIsSet,
        params: {ScriptConditionParams.flagName: 'professor_met'},
      );
      final result = evaluator.evaluate(condition, state);

      expect(result, isFalse);
    });

    test('flagIsUnset returns true when flag is not active', () {
      final state = GameState(
        saveId: 'test-save',
        storyFlags: const StoryFlags(activeFlags: {}),
      );

      final condition = ScriptCondition(
        type: ScriptConditionType.flagIsUnset,
        params: {ScriptConditionParams.flagName: 'professor_met'},
      );
      final result = evaluator.evaluate(condition, state);

      expect(result, isTrue);
    });

    test('flagIsUnset returns false when flag is active', () {
      final state = GameState(
        saveId: 'test-save',
        storyFlags: const StoryFlags(activeFlags: {'professor_met'}),
      );

      final condition = ScriptCondition(
        type: ScriptConditionType.flagIsUnset,
        params: {ScriptConditionParams.flagName: 'professor_met'},
      );
      final result = evaluator.evaluate(condition, state);

      expect(result, isFalse);
    });

    test('allOf returns true when all children are true', () {
      final state = GameState(
        saveId: 'test-save',
        storyFlags: const StoryFlags(activeFlags: {'flag_a', 'flag_b'}),
      );

      final condition = ScriptCondition(
        type: ScriptConditionType.allOf,
        children: [
          ScriptCondition(
            type: ScriptConditionType.flagIsSet,
            params: {ScriptConditionParams.flagName: 'flag_a'},
          ),
          ScriptCondition(
            type: ScriptConditionType.flagIsSet,
            params: {ScriptConditionParams.flagName: 'flag_b'},
          ),
        ],
      );
      final result = evaluator.evaluate(condition, state);

      expect(result, isTrue);
    });

    test('allOf returns false when any child is false', () {
      final state = GameState(
        saveId: 'test-save',
        storyFlags: const StoryFlags(activeFlags: {'flag_a'}),
      );

      final condition = ScriptCondition(
        type: ScriptConditionType.allOf,
        children: [
          ScriptCondition(
            type: ScriptConditionType.flagIsSet,
            params: {ScriptConditionParams.flagName: 'flag_a'},
          ),
          ScriptCondition(
            type: ScriptConditionType.flagIsSet,
            params: {ScriptConditionParams.flagName: 'flag_b'},
          ),
        ],
      );
      final result = evaluator.evaluate(condition, state);

      expect(result, isFalse);
    });

    test('anyOf returns true when any child is true', () {
      final state = GameState(
        saveId: 'test-save',
        storyFlags: const StoryFlags(activeFlags: {'flag_a'}),
      );

      final condition = ScriptCondition(
        type: ScriptConditionType.anyOf,
        children: [
          ScriptCondition(
            type: ScriptConditionType.flagIsSet,
            params: {ScriptConditionParams.flagName: 'flag_a'},
          ),
          ScriptCondition(
            type: ScriptConditionType.flagIsSet,
            params: {ScriptConditionParams.flagName: 'flag_b'},
          ),
        ],
      );
      final result = evaluator.evaluate(condition, state);

      expect(result, isTrue);
    });

    test('anyOf returns false when all children are false', () {
      final state = GameState(
        saveId: 'test-save',
        storyFlags: const StoryFlags(activeFlags: {}),
      );

      final condition = ScriptCondition(
        type: ScriptConditionType.anyOf,
        children: [
          ScriptCondition(
            type: ScriptConditionType.flagIsSet,
            params: {ScriptConditionParams.flagName: 'flag_a'},
          ),
          ScriptCondition(
            type: ScriptConditionType.flagIsSet,
            params: {ScriptConditionParams.flagName: 'flag_b'},
          ),
        ],
      );
      final result = evaluator.evaluate(condition, state);

      expect(result, isFalse);
    });

    test('not inverts condition', () {
      final state = GameState(
        saveId: 'test-save',
        storyFlags: const StoryFlags(activeFlags: {'professor_met'}),
      );

      final condition = ScriptCondition(
        type: ScriptConditionType.not,
        children: [
          ScriptCondition(
            type: ScriptConditionType.flagIsSet,
            params: {ScriptConditionParams.flagName: 'professor_met'},
          ),
        ],
      );
      final result = evaluator.evaluate(condition, state);

      expect(result, isFalse);
    });
  });

  group('EventPageResolver - MVP Scenario', () {
    test('Page 1 active when flag is NOT set', () {
      final state = GameState(
        saveId: 'test-save',
        storyFlags: const StoryFlags(activeFlags: {}),
      );

      final event = MapEventDefinition(
        id: 'professor_event',
        title: 'Professor Oak',
        position: const EventPosition(layerId: 'objects', x: 5, y: 5),
        pages: [
          MapEventPage(
            pageNumber: 0,
            condition: ScriptCondition(
              type: ScriptConditionType.flagIsUnset,
              params: {ScriptConditionParams.flagName: 'professor_met'},
            ),
            message: 'Hello! I am Professor Oak!',
          ),
          MapEventPage(
            pageNumber: 1,
            condition: ScriptCondition(
              type: ScriptConditionType.flagIsSet,
              params: {ScriptConditionParams.flagName: 'professor_met'},
            ),
            message: 'Good luck on your journey!',
          ),
        ],
      );

      final activePage = pageResolver.resolve(event, state);

      expect(activePage, isNotNull);
      expect(activePage!.pageIndex, equals(0));
      expect(activePage.page.message, equals('Hello! I am Professor Oak!'));
    });

    test('Page 2 active AFTER flag is set', () {
      final initialState = GameState(
        saveId: 'test-save',
        storyFlags: const StoryFlags(activeFlags: {}),
      );

      final stateWithFlag = mutations.setFlag(initialState, 'professor_met');

      final event = MapEventDefinition(
        id: 'professor_event',
        title: 'Professor Oak',
        position: const EventPosition(layerId: 'objects', x: 5, y: 5),
        pages: [
          MapEventPage(
            pageNumber: 0,
            condition: ScriptCondition(
              type: ScriptConditionType.flagIsUnset,
              params: {ScriptConditionParams.flagName: 'professor_met'},
            ),
            message: 'Hello! I am Professor Oak!',
          ),
          MapEventPage(
            pageNumber: 1,
            condition: ScriptCondition(
              type: ScriptConditionType.flagIsSet,
              params: {ScriptConditionParams.flagName: 'professor_met'},
            ),
            message: 'Good luck on your journey!',
          ),
        ],
      );

      final activePage = pageResolver.resolve(event, stateWithFlag);

      expect(activePage, isNotNull);
      expect(activePage!.pageIndex, equals(1));
      expect(activePage.page.message, equals('Good luck on your journey!'));
    });

    test('Full MVP scenario: Page1 -> Script -> Flag -> Page2', () {
      final initialState = GameState(
        saveId: 'test-save',
        storyFlags: const StoryFlags(activeFlags: {}),
      );

      final event = MapEventDefinition(
        id: 'professor_event',
        title: 'Professor Oak',
        position: const EventPosition(layerId: 'objects', x: 5, y: 5),
        pages: [
          MapEventPage(
            pageNumber: 0,
            condition: ScriptCondition(
              type: ScriptConditionType.flagIsUnset,
              params: {ScriptConditionParams.flagName: 'professor_met'},
            ),
            script: const ScriptRef(
                scriptId: 'professor_intro', startNode: 'start'),
            message: 'Hello! I am Professor Oak!',
          ),
          MapEventPage(
            pageNumber: 1,
            condition: ScriptCondition(
              type: ScriptConditionType.flagIsSet,
              params: {ScriptConditionParams.flagName: 'professor_met'},
            ),
            message: 'Good luck on your journey!',
          ),
        ],
      );

      final script = ScriptAsset(
        id: 'professor_intro',
        defaultStartNode: 'start',
        nodes: [
          ScriptNode(
            id: 'start',
            commands: [
              ScriptCommand(
                type: ScriptCommandType.setFlag,
                params: {'flagName': 'professor_met'},
              ),
              const ScriptCommand(type: ScriptCommandType.end),
            ],
          ),
        ],
      );

      final activePageBefore = pageResolver.resolve(event, initialState);
      expect(activePageBefore, isNotNull);
      expect(activePageBefore!.pageIndex, equals(0));

      var currentState = initialState;
      for (final command in script.nodes.first.commands) {
        if (command.type == ScriptCommandType.setFlag) {
          currentState =
              mutations.setFlag(currentState, command.params['flagName']!);
        }
      }

      final activePageAfter = pageResolver.resolve(event, currentState);
      expect(activePageAfter, isNotNull);
      expect(activePageAfter!.pageIndex, equals(1));
      expect(
          activePageAfter.page.message, equals('Good luck on your journey!'));
    });
  });

  group('ScriptConditionEvaluator with FieldAbility', () {
    test('fieldAbilityUnlocked returns true when ability is unlocked', () {
      final state = GameState(
        saveId: 'test-save',
        progression: const PlayerProgression(
            unlockedFieldAbilities: [FieldAbility.surf]),
      );

      final condition = ScriptCondition(
        type: ScriptConditionType.fieldAbilityUnlocked,
        params: {ScriptConditionParams.ability: 'surf'},
      );
      final result = evaluator.evaluate(condition, state);

      expect(result, isTrue);
    });

    test('fieldAbilityUnlocked returns false when ability is not unlocked', () {
      final state = GameState(
        saveId: 'test-save',
        progression: const PlayerProgression(unlockedFieldAbilities: []),
      );

      final condition = ScriptCondition(
        type: ScriptConditionType.fieldAbilityUnlocked,
        params: {ScriptConditionParams.ability: 'surf'},
      );
      final result = evaluator.evaluate(condition, state);

      expect(result, isFalse);
    });
  });

  group('ScriptConditionEvaluator with Party Moves', () {
    test('partyHasUsableMove returns true when party has move', () {
      final state = GameState(
        saveId: 'test-save',
        party: PlayerParty(members: [
          const PlayerPokemon(
            speciesId: 'pikachu',
            natureId: 'timid',
            abilityId: 'static',
            knownMoveIds: ['surf', 'thunderbolt'],
          ),
        ]),
      );

      final condition = ScriptCondition(
        type: ScriptConditionType.partyHasUsableMove,
        params: {ScriptConditionParams.moveId: 'surf'},
      );
      final result = evaluator.evaluate(condition, state);

      expect(result, isTrue);
    });

    test('partyHasUsableMove returns false when only fainted pokemon has move',
        () {
      final state = GameState(
        saveId: 'test-save',
        party: PlayerParty(members: [
          const PlayerPokemon(
            speciesId: 'pikachu',
            natureId: 'timid',
            abilityId: 'static',
            knownMoveIds: ['surf', 'thunderbolt'],
            currentHp: 0,
          ),
        ]),
      );

      final condition = ScriptCondition(
        type: ScriptConditionType.partyHasUsableMove,
        params: {ScriptConditionParams.moveId: 'surf'},
      );
      final result = evaluator.evaluate(condition, state);

      expect(result, isFalse);
    });
  });
}

```

### `packages/map_gameplay/test/surf_evaluation_test.dart`

```dart
import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:test/test.dart';

void main() {
  group('evaluateSurfAttempt', () {
    test('returns NotWater when target cell is not water', () {
      final result = evaluateSurfAttempt(
        gameState: _fullSurfGameState(),
        isTargetWater: false,
      );
      expect(result, isA<NotWater>());
    });

    test('returns AlreadySurfing when player is already in surf mode', () {
      final result = evaluateSurfAttempt(
        gameState: _fullSurfGameState().copyWith(
          playerMovementMode: MovementMode.surf,
        ),
        isTargetWater: true,
      );
      expect(result, isA<AlreadySurfing>());
    });

    test('returns MissingSurfCapablePokemon when no party member knows surf',
        () {
      const gameState = GameState(
        saveId: 'test',
        party: PlayerParty(members: [
          PlayerPokemon(
            speciesId: 'pikachu',
            natureId: 'timid',
            abilityId: 'static',
            knownMoveIds: ['thunderbolt'],
          ),
        ]),
        progression: PlayerProgression(
          unlockedFieldAbilities: [FieldAbility.surf],
        ),
      );
      final result = evaluateSurfAttempt(
        gameState: gameState,
        isTargetWater: true,
      );
      expect(result, isA<MissingSurfCapablePokemon>());
    });

    test('returns MissingSurfCapablePokemon when surf pokemon is fainted', () {
      const gameState = GameState(
        saveId: 'test',
        party: PlayerParty(members: [
          PlayerPokemon(
            speciesId: 'lapras',
            natureId: 'modest',
            abilityId: 'water-absorb',
            knownMoveIds: ['surf'],
            currentHp: 0,
          ),
        ]),
        progression: PlayerProgression(
          unlockedFieldAbilities: [FieldAbility.surf],
        ),
      );
      final result = evaluateSurfAttempt(
        gameState: gameState,
        isTargetWater: true,
      );
      expect(result, isA<MissingSurfCapablePokemon>());
    });

    test('returns MissingSurfCapablePokemon when party is empty', () {
      const gameState = GameState(
        saveId: 'test',
        progression: PlayerProgression(
          unlockedFieldAbilities: [FieldAbility.surf],
        ),
      );
      final result = evaluateSurfAttempt(
        gameState: gameState,
        isTargetWater: true,
      );
      expect(result, isA<MissingSurfCapablePokemon>());
    });

    test(
        'returns SurfNotUnlocked when pokemon knows surf but ability is locked',
        () {
      const gameState = GameState(
        saveId: 'test',
        party: PlayerParty(members: [
          PlayerPokemon(
            speciesId: 'lapras',
            natureId: 'modest',
            abilityId: 'water-absorb',
            knownMoveIds: ['surf'],
          ),
        ]),
        progression: PlayerProgression(
          unlockedFieldAbilities: [], // surf not unlocked
        ),
      );
      final result = evaluateSurfAttempt(
        gameState: gameState,
        isTargetWater: true,
      );
      expect(result, isA<SurfNotUnlocked>());
    });

    test('returns CanPromptSurf when all conditions are met', () {
      final result = evaluateSurfAttempt(
        gameState: _fullSurfGameState(),
        isTargetWater: true,
      );
      expect(result, isA<CanPromptSurf>());
    });

    test(
        'returns CanPromptSurf with multiple party members (one capable, one not)',
        () {
      const gameState = GameState(
        saveId: 'test',
        party: PlayerParty(members: [
          PlayerPokemon(
            speciesId: 'pikachu',
            natureId: 'timid',
            abilityId: 'static',
            knownMoveIds: ['thunderbolt'],
          ),
          PlayerPokemon(
            speciesId: 'lapras',
            natureId: 'modest',
            abilityId: 'water-absorb',
            knownMoveIds: ['surf', 'ice_beam'],
          ),
        ]),
        progression: PlayerProgression(
          unlockedFieldAbilities: [FieldAbility.surf],
        ),
      );
      final result = evaluateSurfAttempt(
        gameState: gameState,
        isTargetWater: true,
      );
      expect(result, isA<CanPromptSurf>());
    });
  });

  group('partyHasUsableFieldMove', () {
    test('returns true when a non-fainted member knows the move', () {
      const party = PlayerParty(members: [
        PlayerPokemon(
          speciesId: 'lapras',
          natureId: 'modest',
          abilityId: 'water-absorb',
          knownMoveIds: ['surf'],
        ),
      ]);
      expect(partyHasUsableFieldMove(party, FieldAbility.surf), isTrue);
    });

    test('returns false when the member knowing the move is fainted', () {
      const party = PlayerParty(members: [
        PlayerPokemon(
          speciesId: 'lapras',
          natureId: 'modest',
          abilityId: 'water-absorb',
          knownMoveIds: ['surf'],
          currentHp: 0,
        ),
      ]);
      expect(partyHasUsableFieldMove(party, FieldAbility.surf), isFalse);
    });

    test('returns false when no member knows the move', () {
      const party = PlayerParty(members: [
        PlayerPokemon(
          speciesId: 'pikachu',
          natureId: 'timid',
          abilityId: 'static',
          knownMoveIds: ['thunderbolt'],
        ),
      ]);
      expect(partyHasUsableFieldMove(party, FieldAbility.surf), isFalse);
    });

    test('returns false for empty party', () {
      const party = PlayerParty();
      expect(partyHasUsableFieldMove(party, FieldAbility.surf), isFalse);
    });
  });
}

GameState _fullSurfGameState() {
  return const GameState(
    saveId: 'test',
    party: PlayerParty(members: [
      PlayerPokemon(
        speciesId: 'lapras',
        natureId: 'modest',
        abilityId: 'water-absorb',
        level: 30,
        knownMoveIds: ['surf', 'ice_beam'],
      ),
    ]),
    progression: PlayerProgression(
      unlockedFieldAbilities: [FieldAbility.surf],
    ),
  );
}

```

### `packages/map_runtime/lib/src/infrastructure/file_game_save_repository.dart`

```dart
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:map_core/map_core.dart';
import 'package:path_provider/path_provider.dart';

import '../../../domain/repositories/game_save_repository.dart';

/// Implémentation fichier de [GameSaveRepository].
///
/// Stocke les sauvegardes dans le répertoire de support de l'application.
/// Chemin : `<ApplicationSupportDirectory>/pokemonProject/game_save.json`
class FileGameSaveRepository implements GameSaveRepository {
  static const String _saveFileName = 'game_save.json';
  static const String _subDirectory = 'pokemonProject';

  /// Retourne le chemin complet du fichier de sauvegarde.
  @protected
  Future<String> getSaveFilePath() async {
    final directory = await getApplicationSupportDirectory();
    final saveDir = Directory('${directory.path}/$_subDirectory');
    if (!await saveDir.exists()) {
      await saveDir.create(recursive: true);
    }
    return '${saveDir.path}/$_saveFileName';
  }

  @override
  Future<void> save(GameState state) async {
    try {
      final filePath = await getSaveFilePath();
      final normalizedSaveData = saveDataFromGameState(state);
      final normalizedState = state.copyWith(
        saveId: normalizedSaveData.saveId,
        currentMapId: normalizedSaveData.currentMapId,
        playerPosition: normalizedSaveData.playerPosition,
        playerFacing: normalizedSaveData.playerFacing,
        party: normalizedSaveData.party,
        trainerProfile: normalizedSaveData.trainerProfile,
        bag: normalizedSaveData.bag,
        progression: normalizedSaveData.progression,
        metadata: normalizedSaveData.properties,
      );
      final json = normalizedState.toJson();
      final file = File(filePath);
      debugPrint(
        '[step_studio_trace] save_repo_write_start path=$filePath completedStepIds=${normalizedState.progression.completedStepIds}',
      );
      await file
          .writeAsString(const JsonEncoder.withIndent('  ').convert(json));
      debugPrint('[save] game saved to $filePath');
      debugPrint(
        '[step_studio_trace] save_repo_write_done path=$filePath completedStepIds=${normalizedState.progression.completedStepIds}',
      );
    } catch (e, st) {
      debugPrint('[save] failed: $e\n$st');
      throw GameSaveException('Failed to save game: $e');
    }
  }

  @override
  Future<GameState?> load() async {
    try {
      final filePath = await getSaveFilePath();
      final file = File(filePath);
      if (!await file.exists()) {
        debugPrint('[load] no save file found at $filePath');
        return null;
      }
      final content = await file.readAsString();
      final json = jsonDecode(content) as Map<String, dynamic>;
      final state = normalizeLoadedGameState(GameState.fromJson(json));
      debugPrint('[load] game loaded from $filePath');
      return state;
    } catch (e, st) {
      debugPrint('[load] failed: $e\n$st');
      throw GameSaveException('Failed to load game: $e');
    }
  }

  @override
  Future<bool> exists() async {
    try {
      final filePath = await getSaveFilePath();
      final file = File(filePath);
      return await file.exists();
    } catch (e, st) {
      debugPrint('[exists] failed: $e\n$st');
      throw GameSaveException('Failed to check save existence: $e');
    }
  }

  @override
  Future<void> delete() async {
    try {
      final filePath = await getSaveFilePath();
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
        debugPrint('[delete] save deleted at $filePath');
      }
    } catch (e, st) {
      debugPrint('[delete] failed: $e\n$st');
      throw GameSaveException('Failed to delete save: $e');
    }
  }
}

```

### `packages/map_runtime/test/file_game_save_repository_test.dart`

```dart
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/map_runtime.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('FileGameSaveRepository E2E', () {
    late _TestFileGameSaveRepository repository;
    late Directory testDirectory;

    setUp(() async {
      // Override the application support directory for testing
      testDirectory = await Directory.systemTemp.createTemp('game_save_test_');
      repository = _TestFileGameSaveRepository(testDirectory);
    });

    tearDown(() async {
      if (await testDirectory.exists()) {
        await testDirectory.delete(recursive: true);
      }
    });

    test('save → load → GameState identical', () async {
      const originalState = GameState(
        saveId: 'test_save_001',
        currentMapId: 'pallet_town',
        playerPosition: GridPos(x: 5, y: 3),
        playerFacing: EntityFacing.north,
        playerMovementMode: MovementMode.walk,
        party: PlayerParty(members: [
          PlayerPokemon(
            speciesId: 'squirtle',
            natureId: 'bold',
            abilityId: 'torrent',
            level: 12,
            ivs: PokemonStatSpread(
              hp: 31,
              attack: 30,
              defense: 29,
              specialAttack: 28,
              specialDefense: 27,
              speed: 26,
            ),
            knownMoveIds: ['surf', 'water_gun'],
            currentHp: 30,
            heldItemId: 'mystic-water',
          ),
        ]),
        trainerProfile: TrainerProfile(
          name: 'Leaf',
          badgeIds: ['boulder', 'cascade'],
          money: 2500,
          playtimeSeconds: 1800,
        ),
        bag: Bag(
          entries: [
            BagEntry(itemId: 'poke-ball', categoryId: 'items', quantity: 10),
            BagEntry(itemId: 'potion', categoryId: 'medicine', quantity: 3),
          ],
        ),
        progression: PlayerProgression(
          unlockedFieldAbilities: [FieldAbility.surf],
          storyFlags: ['intro_done'],
        ),
        scriptVariables: ScriptVariables(values: {
          'rival_battles_won': ScriptVariableValue.int(3),
        }),
        storyFlags: StoryFlags(activeFlags: {
          'trainer_defeated:gym_leader_1',
          'badge_cascade',
        }),
        consumedEventIds: {'item_potion_route1', 'npc_trainer_route22'},
        metadata: {'testKey': 'testValue'},
      );

      // Save
      await repository.save(originalState);

      // Load
      final loadedState = await repository.load();

      expect(loadedState, isNotNull);
      expect(loadedState!.saveId, equals(originalState.saveId));
      expect(loadedState.currentMapId, equals(originalState.currentMapId));
      expect(loadedState.playerPosition, equals(originalState.playerPosition));
      expect(loadedState.playerFacing, equals(originalState.playerFacing));
      expect(loadedState.playerMovementMode,
          equals(originalState.playerMovementMode));
      expect(loadedState.party.members.length,
          equals(originalState.party.members.length));
      expect(loadedState.trainerProfile, equals(originalState.trainerProfile));
      expect(loadedState.bag, equals(originalState.bag));
      expect(loadedState.progression.unlockedFieldAbilities,
          equals(originalState.progression.unlockedFieldAbilities));
      expect(loadedState.storyFlags.activeFlags,
          equals(originalState.storyFlags.activeFlags));
      expect(
          loadedState.consumedEventIds, equals(originalState.consumedEventIds));
    });

    test('save → load → storyFlags contains trainer_defeated:{id}', () async {
      const trainerId = 'gym_leader_1';
      const originalState = GameState(
        saveId: 'test_save_002',
        currentMapId: 'pallet_town',
        storyFlags: StoryFlags(activeFlags: {
          'trainer_defeated:$trainerId',
          'intro_done',
        }),
      );

      // Save
      await repository.save(originalState);

      // Load
      final loadedState = await repository.load();

      expect(loadedState, isNotNull);
      expect(loadedState!.storyFlags.activeFlags,
          contains('trainer_defeated:$trainerId'));
    });

    test(
        'load migrates legacy progression.storyFlags into storyFlags.activeFlags',
        () async {
      final filePath = await repository.exposedSaveFilePath();
      final file = File(filePath);
      final legacyJson = <String, dynamic>{
        'saveId': 'legacy_save',
        'currentMapId': 'vova_center',
        'progression': <String, dynamic>{
          'unlockedFieldAbilities': <String>[],
          'storyFlags': <String>[
            'met_professor',
            'trainer_defeated:jean_michel'
          ],
        },
        'storyFlags': <String, dynamic>{
          'activeFlags': <String>[],
        },
      };
      await file.writeAsString(
          const JsonEncoder.withIndent('  ').convert(legacyJson));

      final loadedState = await repository.load();

      expect(loadedState, isNotNull);
      expect(loadedState!.storyFlags.activeFlags, contains('met_professor'));
      expect(
        loadedState.storyFlags.activeFlags,
        contains('trainer_defeated:jean_michel'),
      );
    });

    test('load when no save exists → returns null', () async {
      final loadedState = await repository.load();
      expect(loadedState, isNull);
    });

    test('exists() returns true after save', () async {
      const state = GameState(
        saveId: 'test_save_003',
        currentMapId: 'pallet_town',
      );

      expect(await repository.exists(), isFalse);

      await repository.save(state);

      expect(await repository.exists(), isTrue);
    });

    test('delete → load → returns null', () async {
      const state = GameState(
        saveId: 'test_save_004',
        currentMapId: 'pallet_town',
      );

      await repository.save(state);
      expect(await repository.exists(), isTrue);

      await repository.delete();
      expect(await repository.exists(), isFalse);

      final loadedState = await repository.load();
      expect(loadedState, isNull);
    });

    test('JSON file structure is valid', () async {
      const trainerId = 'test_trainer';
      const state = GameState(
        saveId: 'test_save_005',
        currentMapId: 'test_map',
        playerPosition: GridPos(x: 10, y: 5),
        playerFacing: EntityFacing.east,
        trainerProfile: TrainerProfile(
          name: 'Red',
          badgeIds: ['boulder'],
          money: 500,
          playtimeSeconds: 90,
        ),
        bag: Bag(
          entries: [
            BagEntry(itemId: 'poke-ball', categoryId: 'items', quantity: 5),
          ],
        ),
        storyFlags: StoryFlags(activeFlags: {
          'trainer_defeated:$trainerId',
        }),
      );

      await repository.save(state);

      // Read raw JSON file
      final filePath = await repository.exposedSaveFilePath();
      final file = File(filePath);
      final content = await file.readAsString();
      final json = jsonDecode(content) as Map<String, dynamic>;

      // Verify structure
      expect(json['saveId'], equals('test_save_005'));
      expect(json['currentMapId'], equals('test_map'));
      expect(json['playerPosition'], isA<Map<String, dynamic>>());
      expect(json['playerFacing'], equals('east'));
      expect(json['playerMovementMode'], equals('walk'));
      expect(json['trainerProfile'], isA<Map<String, dynamic>>());
      expect(json['bag'], isA<Map<String, dynamic>>());
      expect(json['progression'], isA<Map<String, dynamic>>());
      expect(json['storyFlags'], isA<Map<String, dynamic>>());

      final storyFlags = json['storyFlags'] as Map<String, dynamic>;
      expect(storyFlags['activeFlags'], isA<List>());
      expect(
          (storyFlags['activeFlags'] as List)
              .contains('trainer_defeated:$trainerId'),
          isTrue);
    });

    test('save writes normalized phase 9 data', () async {
      const state = GameState(
        saveId: ' test_save_005b ',
        currentMapId: ' test_map ',
        trainerProfile: TrainerProfile(
          name: ' Red ',
          badgeIds: ['cascade', 'boulder', 'cascade'],
          money: 500,
          playtimeSeconds: 90,
        ),
        bag: Bag(
          entries: [
            BagEntry(itemId: ' potion ', categoryId: ' medicine ', quantity: 2),
            BagEntry(itemId: ' poke-ball ', categoryId: ' items ', quantity: 5),
            BagEntry(itemId: 'potion', categoryId: 'medicine', quantity: 3),
          ],
        ),
      );

      await repository.save(state);

      final filePath = await repository.exposedSaveFilePath();
      final file = File(filePath);
      final content = await file.readAsString();
      final json = jsonDecode(content) as Map<String, dynamic>;
      final trainerProfile = json['trainerProfile'] as Map<String, dynamic>;
      final bag = json['bag'] as Map<String, dynamic>;
      final entries = bag['entries'] as List<dynamic>;

      expect(json['saveId'], equals('test_save_005b'));
      expect(json['currentMapId'], equals('test_map'));
      expect(trainerProfile['name'], equals('Red'));
      expect(trainerProfile['badgeIds'], equals(['boulder', 'cascade']));
      expect(entries, [
        {
          'itemId': 'poke-ball',
          'categoryId': 'items',
          'quantity': 5,
        },
        {
          'itemId': 'potion',
          'categoryId': 'medicine',
          'quantity': 5,
        },
      ]);
    });

    test('save keeps project.json unchanged', () async {
      final projectFile = File('${testDirectory.path}/project.json');
      await projectFile.writeAsString('{"name":"test"}');

      const state = GameState(
        saveId: 'test_save_006',
        trainerProfile: TrainerProfile(name: 'Blue'),
      );

      await repository.save(state);

      expect(await projectFile.readAsString(), '{"name":"test"}');
    });

    test('invalid save does not write and keeps project.json unchanged',
        () async {
      final projectFile = File('${testDirectory.path}/project.json');
      await projectFile.writeAsString('{"name":"test"}');

      const invalidState = GameState(saveId: '');

      await expectLater(
        () => repository.save(invalidState),
        throwsA(isA<GameSaveException>()),
      );

      expect(await repository.exists(), isFalse);
      expect(await projectFile.readAsString(), '{"name":"test"}');
    });

    test(
        'invalid nested phase 9 data does not write and keeps project.json unchanged',
        () async {
      final projectFile = File('${testDirectory.path}/project.json');
      await projectFile.writeAsString('{"name":"test"}');

      const invalidState = GameState(
        saveId: 'test_save_007',
        trainerProfile: TrainerProfile(name: '   '),
      );

      await expectLater(
        () => repository.save(invalidState),
        throwsA(isA<GameSaveException>()),
      );

      expect(await repository.exists(), isFalse);
      expect(await projectFile.readAsString(), '{"name":"test"}');
    });
  });
}

/// Test repository that uses a custom test directory
class _TestFileGameSaveRepository extends FileGameSaveRepository {
  _TestFileGameSaveRepository(this._testDirectory);

  final Directory _testDirectory;

  Future<String> exposedSaveFilePath() => getSaveFilePath();

  @override
  Future<String> getSaveFilePath() async {
    final saveDir = Directory('${_testDirectory.path}/pokemonProject');
    if (!await saveDir.exists()) {
      await saveDir.create(recursive: true);
    }
    return '${saveDir.path}/game_save.json';
  }
}

```

## 15. Checklist finale

- [x] J’ai bien couvert uniquement les lots 44 à 47.
- [x] Je n’ai pas commencé les lots 48+.
- [x] J’ai utilisé des sub-agents pour audit, contradictoire et review couverture.
- [x] Je n’ai gardé qu’une seule implémentation finale.
- [x] Je n’ai pas touché `project.json`.
- [x] Je n’ai pas ouvert de chantier UI phase 10.
- [x] Je n’ai pas créé de framework générique spéculatif.
- [x] Les modèles de phase 9 vivent dans la couche la plus basse cohérente (`map_core`).
- [x] Le flux de save simple réutilise le repository/runtime existant au lieu de créer un second système.
- [x] Les saves invalides n’écrivent rien.
- [x] Les tests ciblés passent.
- [x] L’analyse ciblée passe.
- [x] Le code est formaté sur les fichiers Dart touchés.
- [x] Le rapport markdown a été créé.
- [x] Le rapport documente honnêtement les incidents réels.
- [x] Aucune commande Git d’écriture n’a été exécutée.
