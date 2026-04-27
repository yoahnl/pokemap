# Phase R1 — Lot 12 — Seen/Caught persistants minimaux

## 1. Résumé exécutif honnête

Le lot 12 a été implémenté de manière minimale, réelle et bornée.

Le repo possède maintenant un état persistant `seen/caught` porté par `PlayerProgression`, sérialisé dans le save, relu proprement depuis les saves existantes, et normalisé de façon idempotente.

Le contrat livré est le suivant :
- les espèces déjà possédées par le joueur via sa party sont synchronisées dans `caughtSpeciesIds` et donc aussi dans `seenSpeciesIds` ;
- une rencontre sauvage réelle marque l’espèce ennemie comme `seen` au moment où le battle handoff réel a effectivement résolu cette espèce et s’apprête à ouvrir l’overlay de combat ;
- aucune logique de capture n’est ajoutée ;
- une simple rencontre sauvage, quel que soit son outcome, ne crée jamais `caught`.

Le scope est resté strictement sur `map_core` et `map_runtime`. Aucun chantier lot 13+ n’a été ouvert.

## 2. État initial audité réel

Audit du code réel avant modification :
- `GameState` portait déjà un `PlayerProgression` dans `packages/map_core/lib/src/models/game_state.dart`.
- `SaveData` persistait déjà `progression` dans `packages/map_core/lib/src/models/save_data.dart`.
- `PlayerProgression` ne portait encore aucun état Pokédex runtime ; seuls `unlockedFieldAbilities`, `storyFlags`, `completedStepIds` et `completedCutsceneIds` existaient.
- Les bridges canoniques `GameState <-> SaveData` étaient centralisés dans `packages/map_core/lib/src/operations/game_state_persistence.dart` via :
  - `gameStateFromSaveData(...)`
  - `saveDataFromGameState(...)`
  - `normalizeLoadedGameState(...)`
- `FileGameSaveRepository` charge directement `GameState.fromJson(...)` puis appelle `normalizeLoadedGameState(...)`, ce qui impose de gérer la compatibilité legacy à la fois au niveau JSON et au niveau normalisation.
- `PlayableMapGame` possédait déjà la boucle sauvage réelle issue des lots 9/10/11. Le point d’écriture runtime le plus honnête pour `seen` était `_openBattleOverlay(...)`, c’est-à-dire après résolution réelle du `BattleSetup` et juste avant l’entrée effective en phase de combat.

Constat important : le vrai plus petit lot 12 n’était pas de créer un nouveau service Pokédex, mais d’étendre `PlayerProgression` puis de normaliser cet état à travers les bridges save/runtime déjà existants.

## 3. Problèmes confirmés / non confirmés

### Problèmes confirmés

- Il n’existait aucun état persistant `seen/caught` dans les modèles runtime/save.
- Les saves legacy n’avaient donc aucun champ Pokédex runtime à relire ni à normaliser.
- Une espèce déjà présente dans la party du joueur n’était pas reflétée dans un état `caught/seen` persistant.
- La boucle sauvage réelle n’écrivait encore aucun `seen` côté runtime, même quand l’espèce ennemie était réellement résolue et engagée dans le battle handoff.

### Problèmes non confirmés

- Aucun besoin de toucher `map_battle` n’a été confirmé.
- Aucun besoin de toucher le host d’exemple n’a été confirmé.
- Aucun besoin de créer un nouveau service ou store runtime global n’a été confirmé.
- Aucun besoin de rouvrir l’editor ni les readers Pokémon n’a été confirmé.

## 4. Cause racine réelle

La cause racine était simple : les modèles core/save avaient déjà un point d’ancrage naturel (`PlayerProgression`) mais aucun champ ni invariant explicites pour `seen/caught`.

Du coup :
- rien n’était sérialisé ;
- rien n’était migré pour les saves legacy ;
- rien n’assurait la cohérence `party -> caught -> seen` ;
- rien n’écrivait `seen` dans la boucle sauvage réelle.

Le manque n’était pas architectural. Il était local et contractuel.

## 5. Décisions retenues / rejetées

### Décisions retenues

- Porter `seenSpeciesIds` et `caughtSpeciesIds` directement dans `PlayerProgression`.
- Garder la logique de normalisation dans les bridges existants `GameState <-> SaveData`, pas dans une nouvelle couche.
- Imposer l’invariant métier `caught => seen` dans `PlayerProgression.normalized()`.
- Synchroniser les espèces possédées via la `party` du joueur dans `caught`, puis donc dans `seen`, au moment des conversions et de la normalisation.
- Ajouter un helper runtime minimal `markSpeciesSeenInGameState(...)` dans `game_state_persistence.dart` pour écrire `seen` sans inventer `caught`.
- Marquer `seen` dans `PlayableMapGame._openBattleOverlay(...)` uniquement après résolution réelle du `BattleSetup` ennemi.

### Décisions rejetées

- Nouveau service Pokédex runtime : rejeté, disproportionné.
- Nouveau store global runtime : rejeté, stack parallèle.
- Marquer `caught` lors d’une rencontre sauvage : rejeté, relève du lot 13 capture.
- Déplacer la logique dans `map_battle` : rejeté, hors besoin réel.
- Ajouter une UI Pokédex riche : rejeté, hors scope.

## 6. Périmètre inclus / exclu

### Inclus

- persistance de `seen/caught` dans `PlayerProgression`
- compatibilité des saves legacy
- normalisation idempotente des saves chargées
- synchronisation minimale `party -> caught -> seen`
- marquage runtime minimal de `seen` lors d’une vraie rencontre sauvage engagée
- tests ciblés core/runtime

### Exclu

- capture
- seen/caught UI riche
- rewards / XP / level up
- bag / objets
- whiteout-lite
- heal center
- refonte runtime
- refonte combat
- lot 13+

## 7. Liste exacte des fichiers modifiés / créés / supprimés

### Modifiés

- `packages/map_core/lib/src/models/save_data.dart`
- `packages/map_core/lib/src/models/save_data.freezed.dart`
- `packages/map_core/lib/src/models/save_data.g.dart`
- `packages/map_core/lib/src/operations/game_state_persistence.dart`
- `packages/map_core/test/game_state_persistence_test.dart`
- `packages/map_core/test/save_data_test.dart`
- `packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart`
- `packages/map_runtime/test/file_game_save_repository_test.dart`
- `packages/map_runtime/test/wild_battle_end_to_end_flow_test.dart`

### Créés

- aucun

### Supprimés

- aucun

## 8. Justification fichier par fichier

### `packages/map_core/lib/src/models/save_data.dart`

Ajout des champs persistants `seenSpeciesIds` et `caughtSpeciesIds` à `PlayerProgression`, avec normalisation dédiée. C’est le point d’atterrissage le plus honnête car `progression` existait déjà et portait déjà l’état persistant runtime du joueur.

### `packages/map_core/lib/src/models/save_data.freezed.dart`

Mise à jour générée nécessaire suite à l’évolution de `PlayerProgression`.

### `packages/map_core/lib/src/models/save_data.g.dart`

Mise à jour générée nécessaire pour sérialiser/désérialiser `seenSpeciesIds` et `caughtSpeciesIds`.

### `packages/map_core/lib/src/operations/game_state_persistence.dart`

Consolidation du vrai contrat lot 12 :
- normalisation legacy
- synchronisation `party -> caught -> seen`
- helper minimal pour marquer `seen` côté runtime sans inventer `caught`

### `packages/map_core/test/game_state_persistence_test.dart`

Preuves ciblées sur :
- migration legacy
- sync party -> caught/seen
- normalisation des saves chargées
- marquage runtime `seen` sans `caught`

### `packages/map_core/test/save_data_test.dart`

Preuves ciblées sur la sérialisation `PlayerProgression` et l’invariant `caught => seen`.

### `packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart`

Écriture runtime minimale de `seen` dans la boucle sauvage réelle, au moment produit correct : lorsque le battle handoff réel a effectivement résolu l’espèce ennemie et que l’overlay va s’ouvrir.

### `packages/map_runtime/test/file_game_save_repository_test.dart`

Preuves E2E save/load réelles sur le repository de save runtime, y compris compatibilité legacy.

### `packages/map_runtime/test/wild_battle_end_to_end_flow_test.dart`

Preuve verticale runtime stable : une vraie rencontre sauvage ajoute `seen`, ne crée pas `caught`, puis conserve cet état après application du résultat de combat.

## 9. Commandes réellement exécutées

### Audit

```bash
git status --short
git diff --stat
find . -name AGENTS.md -print
rg -n "seen|caught|pokedex|PlayerParty|PlayerPokemon|SaveData|GameState|toSaveData|fromSaveData|normalize|load save|storyFlags|party" packages/map_core packages/map_runtime -g'*.dart'
sed -n '1,260p' packages/map_core/lib/src/models/game_state.dart
sed -n '1,260p' packages/map_core/lib/src/models/save_data.dart
rg -n "saveDataFromGameState|gameStateFromSaveData|normalizeLoadedGameState|SaveData\(|fromSaveData|toSaveData" packages/map_core packages/map_runtime -g'*.dart'
sed -n '1,260p' packages/map_core/test/game_state_persistence_test.dart
sed -n '1,220p' packages/map_core/lib/src/operations/game_state_persistence.dart
sed -n '300,420p' packages/map_core/lib/src/models/save_data.dart
sed -n '1,220p' packages/map_runtime/lib/src/infrastructure/file_game_save_repository.dart
sed -n '1,180p' packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart
rg -n "class GameStateMutations|setFlag\(|copyWith\(progression|progression\.copyWith" packages/map_runtime packages/map_core -g'*.dart'
sed -n '1,220p' packages/map_runtime/test/file_game_save_repository_test.dart
sed -n '220,360p' packages/map_runtime/test/file_game_save_repository_test.dart
sed -n '1,260p' packages/map_runtime/test/wild_battle_end_to_end_flow_test.dart
sed -n '1,220p' packages/map_runtime/test/runtime_battle_outcome_apply_test.dart
sed -n '1,220p' packages/map_runtime/test/runtime_battle_setup_mapper_test.dart
sed -n '1,220p' packages/map_core/pubspec.yaml
sed -n '1,220p' packages/map_runtime/pubspec.yaml
```

### Génération / format / analyse / tests

```bash
cd packages/map_core && /opt/homebrew/bin/dart run build_runner build --delete-conflicting-outputs
/opt/homebrew/bin/dart format \
  packages/map_core/lib/src/models/save_data.dart \
  packages/map_core/lib/src/models/save_data.freezed.dart \
  packages/map_core/lib/src/models/save_data.g.dart \
  packages/map_core/lib/src/operations/game_state_persistence.dart \
  packages/map_core/test/game_state_persistence_test.dart \
  packages/map_core/test/save_data_test.dart \
  packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart \
  packages/map_runtime/test/file_game_save_repository_test.dart \
  packages/map_runtime/test/wild_battle_end_to_end_flow_test.dart
cd packages/map_core && /opt/homebrew/bin/dart analyze lib/src/models/save_data.dart lib/src/operations/game_state_persistence.dart test/save_data_test.dart test/game_state_persistence_test.dart
cd packages/map_runtime && /opt/homebrew/bin/flutter analyze --no-pub lib/src/presentation/flame/playable_map_game.dart test/file_game_save_repository_test.dart test/wild_battle_end_to_end_flow_test.dart
cd packages/map_core && /opt/homebrew/bin/dart test test/save_data_test.dart test/game_state_persistence_test.dart
cd packages/map_runtime && /opt/homebrew/bin/flutter test test/file_game_save_repository_test.dart test/wild_battle_end_to_end_flow_test.dart test/runtime_battle_setup_mapper_test.dart test/runtime_battle_outcome_apply_test.dart
```

### État git final

```bash
git status --short
git diff --stat
git ls-files --others --exclude-standard
```

## 10. Résultats réels de format / analyze / tests

### Build runner (`packages/map_core`)

Résultat : succès.

Note honnête : la commande a émis des warnings d’environnement déjà présents :
- version language SDK plus récente que celle du package `analyzer`
- contrainte `json_annotation` légèrement en retard

Ces warnings n’ont pas bloqué la génération.

### Format

Résultat : succès.

Sortie notable :
- `Formatted packages/map_core/lib/src/models/save_data.dart`
- `Formatted packages/map_core/lib/src/operations/game_state_persistence.dart`
- `Formatted packages/map_runtime/test/wild_battle_end_to_end_flow_test.dart`
- `Formatted 9 files (3 changed) in 0.09 seconds.`

### Analyze `packages/map_core`

Résultat : succès.

Sortie : `No issues found!`

### Analyze `packages/map_runtime`

Résultat : succès.

Sortie : `Analyzing 3 items... No issues found!`

### Tests `packages/map_core`

Résultat : succès.

Sortie finale : `All tests passed!`

### Tests `packages/map_runtime`

Résultat : succès.

Sortie finale : `All tests passed!`

## 11. Incidents rencontrés

- `build_runner` a émis des warnings d’environnement non bloquants sur `analyzer` et `json_annotation`.
- Lors du lancement parallèle des validations Flutter, une commande a brièvement attendu le `startup lock` Flutter (`Waiting for another flutter command to release the startup lock...`). Le verrou s’est résolu automatiquement et les commandes ont fini proprement.
- Un reviewer réutilisé a répondu avec un avis stale hors scope (restes d’un contexte trainer antérieur). Sa conclusion a été explicitement rejetée et n’a pas influencé l’implémentation lot 12.

## 12. État git utile

État final utile observé :

```text
 M packages/map_core/lib/src/models/save_data.dart
 M packages/map_core/lib/src/models/save_data.freezed.dart
 M packages/map_core/lib/src/models/save_data.g.dart
 M packages/map_core/lib/src/operations/game_state_persistence.dart
 M packages/map_core/test/game_state_persistence_test.dart
 M packages/map_core/test/save_data_test.dart
 M packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart
 M packages/map_runtime/test/file_game_save_repository_test.dart
 M packages/map_runtime/test/wild_battle_end_to_end_flow_test.dart
```

Aucun fichier non suivi hors report au moment de cette rédaction.

## 13. Checklist finale

- [x] je me suis basé sur le code réel
- [x] je n’ai créé aucune stack parallèle
- [x] je n’ai pas ouvert le lot 13+
- [x] un état seen/caught persistant existe réellement
- [x] les saves legacy restent lisibles
- [x] la party du joueur alimente correctement caught et seen
- [x] une vraie rencontre sauvage ajoute au moins seen
- [x] rien n’ajoute caught par erreur hors possession réelle
- [x] les lots 9/10/11 utiles restent verts
- [x] j’ai exécuté format
- [x] j’ai exécuté analyze
- [x] j’ai exécuté les tests utiles
- [x] je n’ai fait aucune écriture git interdite
- [x] j’ai créé un report ultra complet
- [x] le report contient le contenu complet des fichiers touchés

## 14. Conclusion honnête

Le lot 12 est livré dans son plus petit périmètre honnête.

Ce qui est réellement en place :
- persistance `seen/caught`
- compatibilité legacy
- invariant `caught => seen`
- sync `party -> caught -> seen`
- write runtime minimal de `seen` sur vraie rencontre sauvage
- preuves automatiques stables sur core/runtime

Ce qui n’a volontairement pas été fait parce que ce serait le lot 13+ :
- capture
- UI Pokédex
- seen/caught trainer riche
- rewards / XP / level up
- inventaire / bag

## 15. Annexe — contenu complet des fichiers touchés

Le report s’exclut lui-même de cette annexe pour éviter la récursion infinie.


### /Users/karim/Project/pokemonProject/packages/map_core/lib/src/models/save_data.dart

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

const _legacyPlayerPokemonNatureId = 'hardy';
const _legacyPlayerPokemonAbilityId = 'unknown';

Map<String, dynamic> _migrateLegacyPlayerPokemonJson(
  Map<String, dynamic> json,
) {
  final hasLegacyMarkers = json['id'] is String ||
      json.containsKey('nickname') ||
      json.containsKey('isFainted');
  if (!hasLegacyMarkers) {
    return json;
  }
  final migrated = Map<String, dynamic>.from(json);
  final natureId = migrated['natureId'];
  if (natureId == null) {
    migrated['natureId'] = _legacyPlayerPokemonNatureId;
  }
  final abilityId = migrated['abilityId'];
  if (abilityId == null) {
    migrated['abilityId'] = _legacyPlayerPokemonAbilityId;
  }
  final currentHp = migrated['currentHp'];
  if (currentHp == null && migrated['isFainted'] is bool) {
    migrated['currentHp'] = (migrated['isFainted'] as bool) ? 0 : 1;
  }
  return migrated;
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
      _$PlayerPokemonFromJson(_migrateLegacyPlayerPokemonJson(json));

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

@freezed
class PlayerProgression with _$PlayerProgression {
  const PlayerProgression._();

  @JsonSerializable(explicitToJson: true)
  const factory PlayerProgression({
    @Default([]) List<FieldAbility> unlockedFieldAbilities,
    @Default([]) List<String> storyFlags,
    @Default([]) List<String> completedStepIds,
    @Default([]) List<String> completedCutsceneIds,
    @Default([]) List<String> seenSpeciesIds,
    @Default([]) List<String> caughtSpeciesIds,
  }) = _PlayerProgression;

  factory PlayerProgression.fromJson(Map<String, dynamic> json) =>
      _$PlayerProgressionFromJson(json);

  PlayerProgression normalized() {
    final normalizedCaughtSpeciesIds =
        _normalizeUniqueStringsSorted(caughtSpeciesIds);
    final normalizedSeenSpeciesIds = _normalizeUniqueStringsSorted(
      <String>[
        ...seenSpeciesIds,
        ...normalizedCaughtSpeciesIds,
      ],
    );

    return copyWith(
      storyFlags: _normalizeUniqueStringsSorted(storyFlags),
      completedStepIds: _normalizeUniqueStringsPreserveOrder(completedStepIds),
      completedCutsceneIds:
          _normalizeUniqueStringsPreserveOrder(completedCutsceneIds),
      seenSpeciesIds: normalizedSeenSpeciesIds,
      caughtSpeciesIds: normalizedCaughtSpeciesIds,
    );
  }
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

### /Users/karim/Project/pokemonProject/packages/map_core/lib/src/models/save_data.freezed.dart

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
  List<String> get completedStepIds => throw _privateConstructorUsedError;
  List<String> get completedCutsceneIds => throw _privateConstructorUsedError;
  List<String> get seenSpeciesIds => throw _privateConstructorUsedError;
  List<String> get caughtSpeciesIds => throw _privateConstructorUsedError;

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
      List<String> completedCutsceneIds,
      List<String> seenSpeciesIds,
      List<String> caughtSpeciesIds});
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
    Object? seenSpeciesIds = null,
    Object? caughtSpeciesIds = null,
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
      seenSpeciesIds: null == seenSpeciesIds
          ? _value.seenSpeciesIds
          : seenSpeciesIds // ignore: cast_nullable_to_non_nullable
              as List<String>,
      caughtSpeciesIds: null == caughtSpeciesIds
          ? _value.caughtSpeciesIds
          : caughtSpeciesIds // ignore: cast_nullable_to_non_nullable
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
      List<String> completedCutsceneIds,
      List<String> seenSpeciesIds,
      List<String> caughtSpeciesIds});
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
    Object? seenSpeciesIds = null,
    Object? caughtSpeciesIds = null,
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
      seenSpeciesIds: null == seenSpeciesIds
          ? _value._seenSpeciesIds
          : seenSpeciesIds // ignore: cast_nullable_to_non_nullable
              as List<String>,
      caughtSpeciesIds: null == caughtSpeciesIds
          ? _value._caughtSpeciesIds
          : caughtSpeciesIds // ignore: cast_nullable_to_non_nullable
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
      final List<String> completedCutsceneIds = const [],
      final List<String> seenSpeciesIds = const [],
      final List<String> caughtSpeciesIds = const []})
      : _unlockedFieldAbilities = unlockedFieldAbilities,
        _storyFlags = storyFlags,
        _completedStepIds = completedStepIds,
        _completedCutsceneIds = completedCutsceneIds,
        _seenSpeciesIds = seenSpeciesIds,
        _caughtSpeciesIds = caughtSpeciesIds,
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

  final List<String> _completedStepIds;
  @override
  @JsonKey()
  List<String> get completedStepIds {
    if (_completedStepIds is EqualUnmodifiableListView)
      return _completedStepIds;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_completedStepIds);
  }

  final List<String> _completedCutsceneIds;
  @override
  @JsonKey()
  List<String> get completedCutsceneIds {
    if (_completedCutsceneIds is EqualUnmodifiableListView)
      return _completedCutsceneIds;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_completedCutsceneIds);
  }

  final List<String> _seenSpeciesIds;
  @override
  @JsonKey()
  List<String> get seenSpeciesIds {
    if (_seenSpeciesIds is EqualUnmodifiableListView) return _seenSpeciesIds;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_seenSpeciesIds);
  }

  final List<String> _caughtSpeciesIds;
  @override
  @JsonKey()
  List<String> get caughtSpeciesIds {
    if (_caughtSpeciesIds is EqualUnmodifiableListView)
      return _caughtSpeciesIds;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_caughtSpeciesIds);
  }

  @override
  String toString() {
    return 'PlayerProgression(unlockedFieldAbilities: $unlockedFieldAbilities, storyFlags: $storyFlags, completedStepIds: $completedStepIds, completedCutsceneIds: $completedCutsceneIds, seenSpeciesIds: $seenSpeciesIds, caughtSpeciesIds: $caughtSpeciesIds)';
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
                .equals(other._completedCutsceneIds, _completedCutsceneIds) &&
            const DeepCollectionEquality()
                .equals(other._seenSpeciesIds, _seenSpeciesIds) &&
            const DeepCollectionEquality()
                .equals(other._caughtSpeciesIds, _caughtSpeciesIds));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      const DeepCollectionEquality().hash(_unlockedFieldAbilities),
      const DeepCollectionEquality().hash(_storyFlags),
      const DeepCollectionEquality().hash(_completedStepIds),
      const DeepCollectionEquality().hash(_completedCutsceneIds),
      const DeepCollectionEquality().hash(_seenSpeciesIds),
      const DeepCollectionEquality().hash(_caughtSpeciesIds));

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
      final List<String> completedCutsceneIds,
      final List<String> seenSpeciesIds,
      final List<String> caughtSpeciesIds}) = _$PlayerProgressionImpl;
  const _PlayerProgression._() : super._();

  factory _PlayerProgression.fromJson(Map<String, dynamic> json) =
      _$PlayerProgressionImpl.fromJson;

  @override
  List<FieldAbility> get unlockedFieldAbilities;
  @override
  List<String> get storyFlags;
  @override
  List<String> get completedStepIds;
  @override
  List<String> get completedCutsceneIds;
  @override
  List<String> get seenSpeciesIds;
  @override
  List<String> get caughtSpeciesIds;

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

### /Users/karim/Project/pokemonProject/packages/map_core/lib/src/models/save_data.g.dart

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
      seenSpeciesIds: (json['seenSpeciesIds'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      caughtSpeciesIds: (json['caughtSpeciesIds'] as List<dynamic>?)
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
      'seenSpeciesIds': instance.seenSpeciesIds,
      'caughtSpeciesIds': instance.caughtSpeciesIds,
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

### /Users/karim/Project/pokemonProject/packages/map_core/lib/src/operations/game_state_persistence.dart

```dart
import '../models/enums.dart';
import '../models/game_state.dart';
import '../models/save_data.dart';

GameState gameStateFromSaveData(SaveData saveData) {
  final normalizedSaveData = saveData.normalized();
  final normalizedProgression = _normalizePokedexProgression(
    progression: normalizedSaveData.progression,
    party: normalizedSaveData.party,
  );
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
    progression: normalizedProgression,
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
  final normalizedProgression = _normalizePokedexProgression(
    progression: gameState.progression.copyWith(
      storyFlags: mergedProgressionFlags.toList(growable: false),
    ),
    party: gameState.party,
  );

  return SaveData(
    saveId: gameState.saveId,
    currentMapId: gameState.currentMapId,
    playerPosition: gameState.playerPosition,
    playerFacing: gameState.playerFacing,
    party: gameState.party,
    trainerProfile: gameState.trainerProfile,
    bag: gameState.bag,
    progression: normalizedProgression,
    properties: gameState.metadata,
  ).normalized();
}

GameState normalizeLoadedGameState(GameState state) {
  final normalizedProgression = _normalizePokedexProgression(
    progression: state.progression,
    party: state.party,
  );
  if (state.storyFlags.activeFlags.isNotEmpty ||
      normalizedProgression.storyFlags.isEmpty) {
    return state.copyWith(
      progression: normalizedProgression,
    );
  }
  final migratedFlags = normalizedProgression.storyFlags
      .map((flag) => flag.trim())
      .where((flag) => flag.isNotEmpty)
      .toSet();
  return state.copyWith(
    progression: normalizedProgression,
    storyFlags: state.storyFlags.copyWith(activeFlags: migratedFlags),
  );
}

/// Marque une espèce comme vue dans l'état runtime.
///
/// Le lot 12 reste volontairement minimal :
/// - "seen" doit pouvoir être écrit dès qu'un ennemi est réellement engagé ;
/// - "caught" ne doit jamais être inventé ici ;
/// - la possession réelle continue d'être déduite de la party du joueur.
///
/// Cet helper reste donc borné à une mutation honnête de `seen`, tout en
/// laissant la normalisation partagée garantir les invariants :
/// - `caught` implique `seen` ;
/// - les espèces déjà présentes dans la party finissent toujours dans
///   `caught`, donc aussi dans `seen`.
GameState markSpeciesSeenInGameState(
  GameState state,
  String speciesId,
) {
  final normalizedSpeciesId = speciesId.trim();
  if (normalizedSpeciesId.isEmpty) {
    return normalizeLoadedGameState(state);
  }

  final nextProgression = _normalizePokedexProgression(
    progression: state.progression.copyWith(
      seenSpeciesIds: <String>[
        ...state.progression.seenSpeciesIds,
        normalizedSpeciesId,
      ],
    ),
    party: state.party,
  );

  return state.copyWith(
    progression: nextProgression,
  );
}

PlayerProgression _normalizePokedexProgression({
  required PlayerProgression progression,
  required PlayerParty party,
}) {
  // Invariant métier lot 12 :
  // - une espèce possédée via la vraie party du joueur est "caught" ;
  // - tout "caught" doit aussi être "seen" ;
  // - les saves legacy peuvent ne rien stocker, donc on reconstruit ce socle
  //   minimal à partir de la party quand nécessaire.
  final ownedSpeciesIds = party.members
      .map((member) => member.speciesId.trim())
      .where((speciesId) => speciesId.isNotEmpty)
      .toList(growable: false);

  return progression.copyWith(
    caughtSpeciesIds: <String>[
      ...progression.caughtSpeciesIds,
      ...ownedSpeciesIds,
    ],
    seenSpeciesIds: <String>[
      ...progression.seenSpeciesIds,
      ...progression.caughtSpeciesIds,
      ...ownedSpeciesIds,
    ],
  ).normalized();
}

```

### /Users/karim/Project/pokemonProject/packages/map_core/test/game_state_persistence_test.dart

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
      expect(state.progression.caughtSpeciesIds, ['lapras']);
      expect(state.progression.seenSpeciesIds, ['lapras']);
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

    test('syncs party species into caught and seen for persistence', () {
      const state = GameState(
        saveId: 'save_seen_caught',
        party: PlayerParty(
          members: <PlayerPokemon>[
            PlayerPokemon(
              speciesId: 'bulbasaur',
              natureId: 'bold',
              abilityId: 'overgrow',
            ),
            PlayerPokemon(
              speciesId: 'charmander',
              natureId: 'timid',
              abilityId: 'blaze',
            ),
          ],
        ),
        progression: PlayerProgression(
          seenSpeciesIds: ['pikachu'],
          caughtSpeciesIds: ['pikachu'],
        ),
      );

      final save = saveDataFromGameState(state);

      expect(
        save.progression.caughtSpeciesIds,
        containsAll(<String>['bulbasaur', 'charmander', 'pikachu']),
      );
      expect(
        save.progression.seenSpeciesIds,
        containsAll(<String>['bulbasaur', 'charmander', 'pikachu']),
      );
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

    test('hydrates caught and seen from party for legacy states', () {
      const state = GameState(
        saveId: 'save_legacy_seen',
        party: PlayerParty(
          members: <PlayerPokemon>[
            PlayerPokemon(
              speciesId: 'mew',
              natureId: 'calm',
              abilityId: 'synchronize',
            ),
          ],
        ),
      );

      final normalized = normalizeLoadedGameState(state);

      expect(normalized.progression.caughtSpeciesIds, equals(['mew']));
      expect(normalized.progression.seenSpeciesIds, equals(['mew']));
    });

    test('markSpeciesSeenInGameState adds seen without inventing caught', () {
      const state = GameState(
        saveId: 'save_seen_only',
        party: PlayerParty(
          members: <PlayerPokemon>[
            PlayerPokemon(
              speciesId: 'bulbasaur',
              natureId: 'bold',
              abilityId: 'overgrow',
            ),
          ],
        ),
      );

      final updated = markSpeciesSeenInGameState(state, 'zubat');

      expect(updated.progression.caughtSpeciesIds, equals(['bulbasaur']));
      expect(
        updated.progression.seenSpeciesIds,
        equals(['bulbasaur', 'zubat']),
      );
    });
  });
}

```

### /Users/karim/Project/pokemonProject/packages/map_core/test/save_data_test.dart

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
        knownMoveIds: ['tackle', 'growl', 'quick_attack', 'slam', 'surf'],
      );

      expect(() => pokemon.normalized(), throwsStateError);
    });

    test('legacy JSON migrates missing phase 9 fields', () {
      final restored = PlayerPokemon.fromJson({
        'id': 'party_1',
        'speciesId': 'lapras',
        'nickname': 'Ferry',
        'level': 30,
        'knownMoveIds': ['surf', 'ice_beam'],
        'isFainted': true,
      });

      expect(restored.speciesId, 'lapras');
      expect(restored.natureId, 'hardy');
      expect(restored.abilityId, 'unknown');
      expect(restored.currentHp, 0);
      expect(restored.knownMoveIds, ['surf', 'ice_beam']);
    });

    test('non legacy JSON missing phase 9 fields still fails', () {
      expect(
        () => PlayerPokemon.fromJson({
          'speciesId': 'lapras',
          'knownMoveIds': ['surf'],
        }),
        throwsA(isA<TypeError>()),
      );
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
        seenSpeciesIds: ['lapras', 'pikachu'],
        caughtSpeciesIds: ['lapras'],
      );
      final json = progression.toJson();
      final restored = PlayerProgression.fromJson(json);
      expect(restored.unlockedFieldAbilities, [FieldAbility.surf]);
      expect(restored.storyFlags, ['badge_cascade', 'rescued_bill']);
      expect(restored.completedStepIds, ['step_intro', 'step_2_1']);
      expect(restored.seenSpeciesIds, ['lapras', 'pikachu']);
      expect(restored.caughtSpeciesIds, ['lapras']);
    });

    test('defaults are empty', () {
      const progression = PlayerProgression();
      expect(progression.unlockedFieldAbilities, isEmpty);
      expect(progression.storyFlags, isEmpty);
      expect(progression.completedStepIds, isEmpty);
      expect(progression.seenSpeciesIds, isEmpty);
      expect(progression.caughtSpeciesIds, isEmpty);
    });

    test('normalized keeps caught as subset of seen', () {
      const progression = PlayerProgression(
        seenSpeciesIds: ['pikachu'],
        caughtSpeciesIds: ['bulbasaur'],
      );

      final normalized = progression.normalized();

      expect(normalized.caughtSpeciesIds, ['bulbasaur']);
      expect(
        normalized.seenSpeciesIds,
        ['bulbasaur', 'pikachu'],
      );
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

### /Users/karim/Project/pokemonProject/packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart

```dart
import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flame/input.dart';
import 'package:flame/text.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:map_battle/map_battle.dart';
import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';

import '../../../domain/repositories/game_save_repository.dart';
import '../../../src/application/load_game_use_case.dart';
import '../../../src/application/save_game_use_case.dart';
import '../../../src/infrastructure/file_game_save_repository.dart';
import '../../application/battle_start_request.dart';
import '../../application/cutscene_runtime_models.dart';
import '../../application/cutscene_runtime_runner.dart';
import '../../application/dialogue_runtime_models.dart';
import '../../application/encounter_to_battle_request.dart';
import '../../application/field_move_dialogue.dart';
import '../../application/global_story_chapter_runtime.dart';
import '../../application/load_dialogue_content.dart';
import '../../application/load_runtime_map_bundle.dart';
import '../../application/map_entity_runtime_predicate_evaluator.dart';
import '../../application/movement_feedback.dart';
import '../../application/npc_overworld_movement_defaults.dart';
import '../../application/npc_runtime_presence.dart';
import '../../application/placed_behavior_runtime_cooldown.dart';
import '../../application/resolve_dialogue.dart';
import '../../application/runtime_battle_setup_mapper.dart';
import '../../application/runtime_battle_outcome_apply.dart';
import '../../application/runtime_character_refs.dart';
import '../../application/runtime_map_bundle.dart';
import '../../application/runtime_story_branching.dart';
import '../../application/scenario_runtime/scenario_runtime_executor.dart';
import '../../application/scenario_runtime/scenario_runtime_models.dart';
import '../../application/scenario_runtime_completion_gate.dart';
import '../../application/script_runtime_controller.dart';
import '../../application/script_runtime_state.dart';
import '../../application/scripted_entity_movement_controller.dart';
import '../../application/scripted_entity_movement_models.dart';
import '../../application/scripted_npc_anchor_passability.dart';
import '../../application/step_studio_completion_runtime.dart';
import '../../application/step_studio_world_presence_runtime.dart';
import '../../application/story_flags_manager.dart';
import '../../application/trainer_battle_request.dart';
import '../../infrastructure/tile_image_loader.dart';
import 'battle_overlay_component.dart';
import 'battle_transition_overlay_component.dart';
import 'dialogue_overlay_component.dart';
import 'map_layers_component.dart';
import 'overworld_actor_component.dart';
import 'player_component.dart';
import 'warp_transition_overlay_component.dart';

const double _kViewportTilesX = 15.0;
const double _kViewportTilesY = 11.0;
const double _kWaterRequiresSurfMessageCooldownMs = 900;
const GameplayEncounterPolicy _kEncounterPolicy = GameplayEncounterPolicy(
  chancePerStep: 0.12,
);

enum _RuntimeFlowPhase {
  overworld,
  dialogue,
  mapTransition,
  battleTransition,
  battle,
}

class PlayableMapGame extends FlameGame with KeyboardEvents {
  PlayableMapGame({
    required RuntimeMapBundle bundle,
    required this.projectFilePath,
    SaveData? saveData,
    GameSaveRepository? saveRepository,
    this.bundleTransformer,
    this.runtimeCutscenes = const <RuntimeCutsceneAsset>[],
  })  : _bundle = bundle,
        _gameState = normalizeLoadedGameState(
          saveData == null
              ? const GameState(saveId: 'default')
              : gameStateFromSaveData(saveData),
        ),
        _saveRepo = saveRepository ?? FileGameSaveRepository() {
    if (bundleTransformer != null) {
      _bundle = bundleTransformer!(_bundle);
    }
    _saveGameUseCase = SaveGameUseCase(_saveRepo);
    _loadGameUseCase = LoadGameUseCase(_saveRepo);
  }

  final String projectFilePath;
  final RuntimeMapBundle Function(RuntimeMapBundle bundle)? bundleTransformer;
  final List<RuntimeCutsceneAsset> runtimeCutscenes;
  RuntimeMapBundle _bundle;
  GameState _gameState;
  late GameplayWorldState _world;
  late PlayerComponent _player;
  String _activeMapId = '';
  String? _previousMapId;
  _RuntimeFlowPhase _flowPhase = _RuntimeFlowPhase.overworld;
  final Set<LogicalKeyboardKey> _pressedKeys = <LogicalKeyboardKey>{};
  LogicalKeyboardKey? _lastMoveKey;
  TriggeredWarp? _pendingWarp;
  TriggeredConnection? _pendingConnection;
  BattleStartRequest? _pendingBattleRequest;
  PlacedElementInteracted? _pendingPlacedElementBehavior;
  DialogueOverlayComponent? _dialogueOverlay;
  BattleTransitionOverlayComponent? _battleTransitionOverlay;
  BattleOverlayComponent? _battleOverlay;
  WarpTransitionOverlayComponent? _warpTransitionOverlay;
  TextComponent? _notification;
  final List<OverworldActorComponent> _npcActors = [];
  final Map<String, _LoadedPlayableMap> _loadedMapsById = {};
  final Map<String, Future<_LoadedPlayableMap?>> _loadMapFutureById = {};
  final math.Random _encounterRandom = math.Random();
  final GridPathfinder _followPathfinder = const GridPathfinder();
  final RuntimeBattleSetupMapper _battleSetupMapper =
      const RuntimeBattleSetupMapper();
  final PlacedBehaviorCooldownGate _placedBehaviorCooldownGate =
      PlacedBehaviorCooldownGate();
  final StoryFlagsManager _storyFlags = const StoryFlagsManager();
  final RuntimeStoryBranching _storyBranching = const RuntimeStoryBranching();
  final ScenarioRuntimeExecutor _scenarioRuntime =
      const ScenarioRuntimeExecutor();

  /// Cache de l’index Step Studio ↔ cutscenes locales (invalidé quand [_bundle] change).
  StepCompletionCutsceneIndex? _cachedStepCompletionIndex;
  RuntimeMapBundle? _cachedStepCompletionBundleForIndex;

  /// Cache des `worldChanges` parsés (une entrée par ligne JSON) pour le manifeste courant.
  List<StepStudioWorldPresenceRule> _cachedStepStudioWorldRules =
      const <StepStudioWorldPresenceRule>[];
  ProjectManifest? _cachedStepStudioWorldRulesManifest;

  void _ensureStepStudioWorldRulesForManifest(ProjectManifest manifest) {
    if (identical(_cachedStepStudioWorldRulesManifest, manifest)) {
      return;
    }
    _cachedStepStudioWorldRulesManifest = manifest;
    _cachedStepStudioWorldRules =
        buildStepStudioWorldPresenceRuleList(manifest.scenarios);
  }

  late final CutsceneRuntimeRunner _cutsceneRunner =
      _buildCutsceneRuntimeRunner();
  CutsceneChoiceRequest? _pendingCutsceneChoiceRequest;
  ScriptedEntityMovementController? _scriptedEntityMovementController;
  final Map<String, GridPos> _runtimeNpcPositions = <String, GridPos>{};
  // Réservations temporaires d'occupation pour PNJ scriptés en cours de pas.
  //
  // Frontière intentionnelle:
  // - `GameplayWorldState` reste la source canonique des positions *commitées*.
  // - pendant une interpolation visuelle d'un pas PNJ, on réserve aussi les
  //   cellules de destination pour éviter les traversées joueur<->PNJ / PNJ<->PNJ.
  final Map<String, Set<GridPos>> _scriptedNpcReservedOccupiedCellsByEntity =
      <String, Set<GridPos>>{};
  double _runtimeClockMs = 0;
  double _lastWaterRequiresSurfMessageAtMs = -1000000000;
  void Function()? _pendingPostDialogueAction;
  bool _awaitingSurfConfirmation = false;
  bool _showCollisionOverlay = false;
  bool _showNpcCollisionDebugOverlay = false;
  bool _showBehaviorDebugOverlay = false;
  bool _showFpsOverlay = false;
  TextComponent? _behaviorDebugOverlay;
  TextComponent? _fpsOverlay;
  double _fpsAccumulatorSeconds = 0.0;
  int _fpsFrameCount = 0;
  double _currentFps = 0.0;
  String _lastBehaviorDebugLine = 'Aucun behavior déclenché';
  GridPos? _debugTileMarkerPos;
  String? _debugTileMarkerLabel;
  RectangleComponent? _debugTileMarkerFill;
  RectangleComponent? _debugTileMarkerBorder;
  TextComponent? _debugTileMarkerText;
  final Map<String, _NpcCollisionDebugVisual> _npcCollisionDebugByEntityId =
      <String, _NpcCollisionDebugVisual>{};

  ScriptRuntimeController? _activeScriptController;
  bool _isAwaitingScriptResume = false;
  Set<String> _activeScenarioTriggerIds = <String>{};
  _PendingScenarioFollowRequest? _pendingScenarioFollowRequest;
  _PendingScenarioTransitionMapRequest? _pendingScenarioTransitionMapRequest;
  final Map<String, _PendingScenarioNpcWarpEntry>
      _pendingScenarioNpcWarpEntries = <String, _PendingScenarioNpcWarpEntry>{};
  final Map<String, _PendingScenarioMoveContinuation>
      _pendingScenarioMoveContinuationsByEntity =
      <String, _PendingScenarioMoveContinuation>{};
  // File d'attente des scénarios ayant atteint `end` mais dont la complétion
  // doit attendre la fin réelle des effets runtime visibles.
  final List<_PendingScenarioReachedEnd> _pendingScenarioReachedEndQueue =
      <_PendingScenarioReachedEnd>[];
  String? _lastScenarioCompletionBlockReason;

  // Save/Load system
  final GameSaveRepository _saveRepo;
  late SaveGameUseCase _saveGameUseCase;
  late LoadGameUseCase _loadGameUseCase;

  // Battle system (map_battle integration)
  BattleSession? _battleSession;
  RuntimeActiveBattleContext? _activeBattleContext;

  // Battle flow hardening
  bool _isBattleResolving =
      false; // Lock pour empêcher spam clavier pendant résolution

  // Line of Sight (LoS) trainer detection
  final Set<String> _triggeredTrainerBattles = {}; // Anti-retrigger lock

  bool get showCollisionOverlay => _showCollisionOverlay;

  void setCollisionOverlayVisible(bool visible) {
    _showCollisionOverlay = visible;
    for (final loaded in _loadedMapsById.values) {
      loaded.backgroundLayers.showCollisionOverlay = visible;
    }
  }

  bool get showNpcCollisionDebugOverlay => _showNpcCollisionDebugOverlay;

  void setNpcCollisionDebugOverlayVisible(bool visible) {
    _showNpcCollisionDebugOverlay = visible;
    if (!isLoaded) {
      return;
    }
    _syncNpcCollisionDebugOverlay();
  }

  bool get showBehaviorDebugOverlay => _showBehaviorDebugOverlay;
  bool get showFpsOverlay => _showFpsOverlay;
  double get currentFps => _currentFps;

  /// Active/désactive l'affichage du compteur FPS dans le viewport runtime.
  ///
  /// Ce toggle est utilisé par l'example host pour un contrôle manuel.
  /// Le compteur est volontairement optionnel pour éviter toute pollution
  /// visuelle par défaut.
  void setFpsOverlayVisible(bool visible) {
    _showFpsOverlay = visible;
    if (!_showFpsOverlay) {
      _fpsOverlay?.removeFromParent();
      _fpsOverlay = null;
      return;
    }
    if (!isLoaded) {
      return;
    }
    _ensureFpsOverlay();
  }

  MovementMode get playerMovementMode {
    if (isLoaded) {
      return _world.player.movementMode;
    }
    return _gameState.playerMovementMode;
  }

  bool get isSurfing => playerMovementMode == MovementMode.surf;

  ({String mapId, int playerX, int playerY, String facing, String movementMode})
      get saveLoadInfo {
    if (isLoaded) {
      _syncGameStateFromWorld(mapIdOverride: _activeMapId);
    }
    return (
      mapId: _gameState.currentMapId,
      playerX: _gameState.playerPosition.x,
      playerY: _gameState.playerPosition.y,
      facing: _gameState.playerFacing.name,
      movementMode: _gameState.playerMovementMode.name,
    );
  }

  GameState get gameStateSnapshot {
    if (isLoaded) {
      _syncGameStateFromWorld(mapIdOverride: _activeMapId);
    }
    return _gameState;
  }

  void _syncGameStateFromWorld({String? mapIdOverride}) {
    final mapId = mapIdOverride ?? _activeMapId;
    _gameState = _gameState.copyWith(
      currentMapId: mapId,
      playerPosition: _world.player.pos,
      playerFacing: _world.player.facing.asFacing,
      playerMovementMode: _world.player.movementMode,
    );
  }

  /// Filtre spatial PNJ : d’abord [MapEntityNpcData.visibilityRule], puis
  /// les `worldChanges` Step Studio (même [mapId] / [entity.id] que l’authoring).
  ///
  /// Les règles Step Studio sont relues via [_ensureStepStudioWorldRulesForManifest]
  /// **à chaque évaluation** pour éviter une liste [worldRules] capturée une fois
  /// et obsolète si le cache manifeste est invalidé.
  NpcMapPresencePredicate _npcPresencePredicateFor(ProjectManifest manifest) {
    return (String mapId, MapEntity npcEntity) {
      _ensureStepStudioWorldRulesForManifest(manifest);
      return isNpcRuntimePresentOnMap(
        gameState: _gameState,
        manifest: manifest,
        stepStudioWorldRules: _cachedStepStudioWorldRules,
        mapId: mapId,
        entity: npcEntity,
      );
    };
  }

  /// Dialogue effectif : variantes ordonnées puis dialogue par défaut du PNJ.
  DialogueRef? _resolveNpcDialogueRef(MapEntity entity) {
    final npc = entity.npc;
    if (npc == null) {
      return null;
    }
    return MapEntityRuntimePredicateEvaluator(
      gameState: _gameState,
      chapterIndex:
          buildGlobalStoryChapterStepIndex(_bundle.manifest.scenarios),
    ).resolveNpcDialogue(npc);
  }

  void _refreshWorldNpcPresence() {
    if (!isLoaded) {
      return;
    }
    _world = _world.withNpcMapPresencePredicate(
      _npcPresencePredicateFor(_bundle.manifest),
    );
    // Retirer les acteurs Flame des PNJ désormais absents (évite toute dérive
    // visuelle / hit test si un composant repasse « visible » par défaut).
    _detachAbsentNpcActorsFromAllLoadedMaps();
    _syncNpcRenderVisibility();
    _syncNpcCollisionDebugOverlay();
    // Patrouilles / réservations / LoS trainer : mêmes règles que le gameplay
    // (un PNJ « absent » ne doit plus consommer ces systèmes parallèles).
    _stopGameplaySideEffectsForAbsentNpcs();
  }

  /// Retire les [OverworldActorComponent] pour tout PNJ avec personnage dont le
  /// prédicat de présence est faux (cartes chargées / voisines incluses).
  void _detachAbsentNpcActorsFromAllLoadedMaps() {
    for (final loaded in _loadedMapsById.values) {
      final npcPred = _npcPresencePredicateFor(loaded.bundle.manifest);
      final mapId = loaded.bundle.map.id;
      final toRemove = <String>[];
      for (final entity in loaded.bundle.map.entities) {
        if (entity.kind != MapEntityKind.npc) {
          continue;
        }
        final charId = resolveNpcCharacterId(entity, loaded.bundle.manifest);
        if (charId == null || charId.isEmpty) {
          continue;
        }
        if (npcPred(mapId, entity)) {
          continue;
        }
        if (loaded.npcActorByEntityId.containsKey(entity.id)) {
          toRemove.add(entity.id);
        }
      }
      for (final rawId in toRemove) {
        final id = rawId.trim();
        if (id.isEmpty) {
          continue;
        }
        _scriptedEntityMovementController?.stopPatrol(id);
        _scriptedEntityMovementController?.untrackEntity(id);
        _scriptedNpcReservedOccupiedCellsByEntity.remove(id);
        _runtimeNpcPositions.remove(id);
        _triggeredTrainerBattles.remove(id);
        if (_pendingScenarioFollowRequest?.leaderEntityId == id) {
          _pendingScenarioFollowRequest = null;
        }
        _pendingScenarioNpcWarpEntries.remove(id);
        _pendingScenarioMoveContinuationsByEntity.remove(id);
        _purgeMountedNpcActorForEntity(entityId: id, loaded: loaded);
      }
    }
  }

  void _purgeMountedNpcActorForEntity({
    required String entityId,
    required _LoadedPlayableMap loaded,
  }) {
    final actor = loaded.npcActorByEntityId.remove(entityId);
    if (actor != null) {
      loaded.npcActors.remove(actor);
      _npcActors.remove(actor);
      actor.removeFromParent();
    }
    final visual = _npcCollisionDebugByEntityId.remove(entityId);
    visual?.spriteRect.removeFromParent();
    visual?.collisionRect.removeFromParent();
    visual?.anchorMarker.removeFromParent();
  }

  /// Arrête tout effet runtime **hors** [GameplayWorldState] qui pourrait encore
  /// cibler un PNJ filtré par [NpcMapPresencePredicate] (patrouille, réservation
  /// de cases, lock trainer).
  void _stopGameplaySideEffectsForAbsentNpcs() {
    final controller = _scriptedEntityMovementController;
    final pred = _npcPresencePredicateFor(_bundle.manifest);
    final mapId = _world.map.id;
    for (final entity in _world.map.entities) {
      if (entity.kind != MapEntityKind.npc) {
        continue;
      }
      if (pred(mapId, entity)) {
        continue;
      }
      controller?.stopPatrol(entity.id);
      _scriptedNpcReservedOccupiedCellsByEntity.remove(entity.id);
      _runtimeNpcPositions.remove(entity.id);
      _triggeredTrainerBattles.remove(entity.id);
    }
    _applyNpcOverworldDefaultMovement();
  }

  void _syncNpcRenderVisibility() {
    for (final loaded in _loadedMapsById.values) {
      _applyNpcVisibilityToLoadedMap(loaded);
    }
  }

  void _applyNpcVisibilityToLoadedMap(_LoadedPlayableMap loaded) {
    final npcPred = _npcPresencePredicateFor(loaded.bundle.manifest);
    loaded.backgroundLayers.npcMapPresencePredicate = npcPred;
    loaded.foregroundLayers.npcMapPresencePredicate = npcPred;
    for (final entity in loaded.bundle.map.entities) {
      if (entity.kind != MapEntityKind.npc) {
        continue;
      }
      final present = npcPred(loaded.bundle.map.id, entity);
      // Trace "source de vérité -> rendu" :
      // on journalise la décision finale de présence pour chaque PNJ afin de
      // diagnostiquer rapidement un cas "la règle existe mais l'acteur reste visible".
      debugPrint(
        '[step_studio_trace] npc_presence_applied map=${loaded.bundle.map.id} entity=${entity.id} present=$present',
      );
      loaded.npcActorByEntityId[entity.id]?.setGameplayVisible(present);
    }
  }

  RuntimeMapBundle _resolveRuntimeBundle(RuntimeMapBundle bundle) {
    final transform = bundleTransformer;
    if (transform == null) {
      return bundle;
    }
    return transform(bundle);
  }

  void setPlayerMovementMode(MovementMode movementMode) {
    if (!isLoaded) {
      return;
    }
    if (_world.player.movementMode == movementMode) {
      return;
    }
    _world = _world.withPlayer(
      _world.player.copyWith(movementMode: movementMode),
    );
    _syncGameStateFromWorld();
    _player.syncState(_world.player);
  }

  void setSurfingEnabled(bool enabled) {
    setPlayerMovementMode(enabled ? MovementMode.surf : MovementMode.walk);
  }

  /// Lance un déplacement scripté ponctuel pour un PNJ.
  ///
  /// API runtime publique pensée pour une future orchestration cutscene:
  /// - start movement
  /// - poll status
  /// - wait until completed/failed
  ScriptedEntityMovementStatus startScriptedNpcMove({
    required String entityId,
    required GridPos destination,
  }) {
    final controller = _scriptedEntityMovementController;
    if (controller == null) {
      return ScriptedEntityMovementStatus(
        entityId: entityId,
        state: ScriptedEntityMovementState.failed,
        currentPos: const GridPos(x: 0, y: 0),
        targetPos: destination,
        failureReason: 'Scripted movement controller is not initialized.',
      );
    }
    return controller.moveEntityTo(
      entityId: entityId,
      destination: destination,
    );
  }

  /// Active une patrouille simple (waypoints) pour un PNJ.
  ScriptedEntityMovementStatus startScriptedNpcPatrol({
    required String entityId,
    required List<GridPos> waypoints,
    bool loop = true,
    int pauseDurationMs = 0,
    int stepDurationMs = 200,
  }) {
    final controller = _scriptedEntityMovementController;
    if (controller == null) {
      return ScriptedEntityMovementStatus(
        entityId: entityId,
        state: ScriptedEntityMovementState.failed,
        currentPos: const GridPos(x: 0, y: 0),
        failureReason: 'Scripted movement controller is not initialized.',
      );
    }
    return controller.startPatrol(
      ScriptedEntityPatrolRoute(
        entityId: entityId,
        waypoints: waypoints,
        loop: loop,
        pauseDurationMs: pauseDurationMs,
        stepDurationMs: stepDurationMs,
      ),
    );
  }

  void stopScriptedNpcPatrol(String entityId) {
    _scriptedEntityMovementController?.stopPatrol(entityId);
  }

  ScriptedEntityMovementStatus scriptedNpcMovementStatus(String entityId) {
    final controller = _scriptedEntityMovementController;
    if (controller == null) {
      return ScriptedEntityMovementStatus(
        entityId: entityId,
        state: ScriptedEntityMovementState.failed,
        currentPos: const GridPos(x: 0, y: 0),
        failureReason: 'Scripted movement controller is not initialized.',
      );
    }
    return controller.statusOf(entityId);
  }

  /// true si une cutscene runtime est en cours d'exécution.
  bool get isCutsceneRunning => _cutsceneRunner.isRunning;

  /// Identifiant de la cutscene active, `null` si aucune.
  String? get activeCutsceneId => _cutsceneRunner.activeCutsceneId;

  /// Snapshot détaillé du runner cutscene.
  CutsceneRuntimeStatus get cutsceneStatus => _cutsceneRunner.status;

  /// Requête de choix en attente (si la cutscene attend une décision joueur).
  CutsceneChoiceRequest? get pendingCutsceneChoiceRequest =>
      _pendingCutsceneChoiceRequest;

  bool get hasPendingCutsceneChoice => _pendingCutsceneChoiceRequest != null;

  /// Dernier choix résolu pendant la cutscene active.
  CutsceneChoiceResult? get lastCutsceneChoiceResult =>
      _cutsceneRunner.lastChoiceResult;

  /// Démarre une cutscene fournie explicitement.
  ///
  /// Cette API est utile pour des déclenchements runtime directs (tests,
  /// scripts d'initialisation, futur bridge Step -> Cutscene).
  bool startCutscene(RuntimeCutsceneAsset cutscene) {
    if (!isLoaded) {
      return false;
    }
    if (_flowPhase != _RuntimeFlowPhase.overworld) {
      return false;
    }
    _pendingCutsceneChoiceRequest = null;
    return _cutsceneRunner.start(cutscene);
  }

  /// Démarre une cutscene depuis le registre runtime injecté au game host.
  ///
  /// Retourne `false` si l'ID est introuvable ou si une cutscene est déjà active.
  bool startCutsceneById(String cutsceneId) {
    if (!isLoaded) {
      return false;
    }
    final normalized = cutsceneId.trim();
    if (normalized.isEmpty) {
      return false;
    }
    final cutscene = _findRuntimeCutsceneById(normalized);
    if (cutscene == null) {
      return false;
    }
    _pendingCutsceneChoiceRequest = null;
    return _cutsceneRunner.start(cutscene);
  }

  bool resolvePendingCutsceneChoiceByIndex(int selectedIndex) {
    final resolved = _cutsceneRunner.resolveActiveChoiceByIndex(selectedIndex);
    if (resolved) {
      _pendingCutsceneChoiceRequest = _cutsceneRunner.activeChoiceRequest;
    }
    return resolved;
  }

  bool resolvePendingCutsceneChoiceByValue(String selectedValue) {
    final resolved = _cutsceneRunner.resolveActiveChoiceByValue(selectedValue);
    if (resolved) {
      _pendingCutsceneChoiceRequest = _cutsceneRunner.activeChoiceRequest;
    }
    return resolved;
  }

  void setBehaviorDebugOverlayVisible(bool visible) {
    _showBehaviorDebugOverlay = visible;
    if (!visible) {
      _behaviorDebugOverlay?.removeFromParent();
      _behaviorDebugOverlay = null;
      return;
    }
    if (!isLoaded) {
      return;
    }
    _ensureBehaviorDebugOverlay();
  }

  void setDebugTileMarker({
    required GridPos? position,
    String? label,
  }) {
    _debugTileMarkerPos = position;
    _debugTileMarkerLabel = label;
    if (!isLoaded) {
      return;
    }
    _applyDebugTileMarker();
  }

  @override
  Future<void> onLoad() async {
    try {
      _world = GameplayWorldState.fromMap(
        _bundle.map,
        project: _bundle.manifest,
        tileWidth: _bundle.manifest.settings.tileWidth,
        tileHeight: _bundle.manifest.settings.tileHeight,
        npcMapPresencePredicate: _npcPresencePredicateFor(_bundle.manifest),
      );
      debugPrint(
        '[runtime] Map loaded: ${_bundle.map.id}, spawn at (${_world.player.pos.x}, ${_world.player.pos.y})',
      );
    } on GameplaySpawnResolutionException catch (e) {
      debugPrint(
          '[runtime] Spawn resolution failed ($e), falling back to (0,0)');
      _world = GameplayWorldState.initial(
        map: _bundle.map,
        playerPos: const GridPos(x: 0, y: 0),
        project: _bundle.manifest,
        tileWidth: _bundle.manifest.settings.tileWidth,
        tileHeight: _bundle.manifest.settings.tileHeight,
        npcMapPresencePredicate: _npcPresencePredicateFor(_bundle.manifest),
      );
    }
    final images =
        await loadTilesetImagesById(_bundle.tilesetAbsolutePathsById);
    _activeMapId = _bundle.map.id;
    final rootMap = await _mountLoadedMap(
      bundle: _bundle,
      tileImagesById: images,
      originCellX: 0,
      originCellY: 0,
    );
    final playerChar = _resolvePlayerCharacter(_bundle);
    _player = PlayerComponent(
      bundle: _bundle,
      state: _world.player,
      characterEntry: playerChar,
      tileImages: images,
      mapOrigin: _originPixelsOf(rootMap),
    );
    await world.add(_player);
    _syncGameStateFromWorld();
    _configureCameraViewport();
    _syncCameraToPlayer();
    _preloadActiveMapConnections();
    _ensureBehaviorDebugOverlay();
    _ensureFpsOverlay();
    _applyDebugTileMarker();
    _resetScriptedNpcMovementController();
    _activeScenarioTriggerIds = _scenarioRuntime.triggerIdsAtPosition(
      map: _bundle.map,
      pos: _world.player.pos,
    );
    _dispatchScenarioRuntimeSource(
      ScenarioRuntimeSourceEvent.mapEnter(mapId: _activeMapId),
    );
    return super.onLoad();
  }

  @override
  KeyEventResult onKeyEvent(
    KeyEvent event,
    Set<LogicalKeyboardKey> keysPressed,
  ) {
    final isDown = event is KeyDownEvent || event is KeyRepeatEvent;
    final isUp = event is KeyUpEvent;
    final key = event.logicalKey;

    // IMPORTANT: Handle battle phase FIRST before movement keys
    // Otherwise arrow keys will be captured by movement handler
    if (_flowPhase == _RuntimeFlowPhase.battle) {
      // Navigation dans les choix du combat
      // ↑/↓ pour naviguer, E/Space/Enter pour valider, Escape pour fuir
      final overlay = _battleOverlay;
      if (overlay != null) {
        // ↑ : sélection précédente (KeyDownEvent ONLY, pas KeyRepeatEvent)
        if (key == LogicalKeyboardKey.arrowUp && event is KeyDownEvent) {
          final changed = overlay.moveSelectionUp();
          debugPrint('[battle] ArrowUp pressed, selection changed=$changed');
          return KeyEventResult.handled;
        }
        // ↓ : sélection suivante (KeyDownEvent ONLY, pas KeyRepeatEvent)
        if (key == LogicalKeyboardKey.arrowDown && event is KeyDownEvent) {
          final changed = overlay.moveSelectionDown();
          debugPrint('[battle] ArrowDown pressed, selection changed=$changed');
          return KeyEventResult.handled;
        }
        // E / Space / Enter : validation du choix sélectionné
        // CRITICAL: Only process KeyDownEvent, NOT KeyRepeatEvent!
        // KeyRepeatEvent is sent when key is held down, which causes multiple validations
        if (event is KeyDownEvent &&
            (key == LogicalKeyboardKey.keyE ||
                key == LogicalKeyboardKey.space ||
                key == LogicalKeyboardKey.enter)) {
          // CRITICAL: Re-check phase AFTER getting into this block
          // Because the phase might have changed during this same key event processing
          // (e.g., last attack of the battle finished it)
          if (_flowPhase != _RuntimeFlowPhase.battle) {
            debugPrint(
                '[battle] Validate key pressed but phase changed to $_flowPhase, IGNORING');
            return KeyEventResult.ignored;
          }
          // Also check if overlay is still valid (might have been removed)
          if (_battleOverlay == null) {
            debugPrint(
                '[battle] Validate key pressed but overlay is null, IGNORING');
            return KeyEventResult.ignored;
          }
          final selectedChoice = overlay.getSelectedChoice();
          debugPrint(
              '[battle] Validate key pressed (E/Space/Enter), selectedChoice=$selectedChoice');
          final validated = overlay.validateSelectedChoice();
          debugPrint('[battle] validateSelectedChoice returned=$validated');
          return KeyEventResult.handled;
        }
        // Escape : tentative de fuite (seulement si l'action est disponible)
        if (event is KeyDownEvent && key == LogicalKeyboardKey.escape) {
          // Vérifier si l'action "Fuir" est disponible dans les choix
          final selectedChoice = overlay.getSelectedChoice();
          debugPrint('[battle] Escape pressed, selectedChoice=$selectedChoice');
          if (selectedChoice is PlayerBattleChoiceRun) {
            overlay.validateSelectedChoice();
            debugPrint('[battle] Escape validated (run selected)');
            return KeyEventResult.handled;
          }
          // Si "Fuir" n'est pas sélectionné, ne rien faire
          debugPrint('[battle] Escape ignored (run not selected)');
          return KeyEventResult.ignored;
        }
      } else {
        debugPrint('[battle] Keyboard event but overlay is null!');
      }
      return KeyEventResult.ignored;
    }

    // Pendant une cutscene active en overworld, on bloque les entrées joueur
    // directes (déplacement/interact) pour garder la scène déterministe.
    if (isCutsceneRunning && _flowPhase == _RuntimeFlowPhase.overworld) {
      if (_isMovementKey(key)) {
        _pressedKeys.remove(key);
        if (_lastMoveKey == key) {
          _lastMoveKey = null;
        }
        return KeyEventResult.handled;
      }
      if (event is KeyDownEvent &&
          (key == LogicalKeyboardKey.keyE ||
              key == LogicalKeyboardKey.space ||
              key == LogicalKeyboardKey.enter)) {
        return KeyEventResult.handled;
      }
    }

    // Déplacement scripté joueur (scénario / cutscene): pas d’entrées clavier.
    if (_suppressOverworldInputForScriptedPlayerMovement() &&
        _flowPhase == _RuntimeFlowPhase.overworld) {
      if (_isMovementKey(key)) {
        _pressedKeys.remove(key);
        if (_lastMoveKey == key) {
          _lastMoveKey = null;
        }
        return KeyEventResult.handled;
      }
      if (event is KeyDownEvent &&
          (key == LogicalKeyboardKey.keyE ||
              key == LogicalKeyboardKey.space ||
              key == LogicalKeyboardKey.enter)) {
        return KeyEventResult.handled;
      }
    }

    // Handle movement keys (but NOT during battle)
    if (_isMovementKey(key)) {
      if (_flowPhase == _RuntimeFlowPhase.dialogue) {
        _pressedKeys.remove(key);
        if (_lastMoveKey == key) {
          _lastMoveKey = null;
        }
        if ((_dialogueOverlay?.isShowingChoices ?? false) && isDown) {
          if (key == LogicalKeyboardKey.arrowUp) {
            _moveChoiceCursor(-1);
          } else if (key == LogicalKeyboardKey.arrowDown) {
            _moveChoiceCursor(1);
          }
        }
        return KeyEventResult.handled;
      }
      if (_flowPhase != _RuntimeFlowPhase.overworld) {
        _pressedKeys.remove(key);
        if (_lastMoveKey == key) {
          _lastMoveKey = null;
        }
        return KeyEventResult.handled;
      }
      if (isDown) {
        _pressedKeys.add(key);
        _lastMoveKey = key;
      } else if (isUp) {
        _pressedKeys.remove(key);
        if (_lastMoveKey == key) {
          _lastMoveKey = null;
        }
      }
      return KeyEventResult.handled;
    }

    if (_flowPhase == _RuntimeFlowPhase.mapTransition ||
        _flowPhase == _RuntimeFlowPhase.battleTransition) {
      return KeyEventResult.ignored;
    }
    if (!isDown) return KeyEventResult.ignored;

    if (_flowPhase == _RuntimeFlowPhase.dialogue) {
      final overlay = _dialogueOverlay!;
      if (overlay.isShowingChoices) {
        if (key == LogicalKeyboardKey.arrowUp) {
          _moveChoiceCursor(-1);
          return KeyEventResult.handled;
        }
        if (key == LogicalKeyboardKey.arrowDown) {
          _moveChoiceCursor(1);
          return KeyEventResult.handled;
        }
        if (event is KeyDownEvent &&
            (key == LogicalKeyboardKey.keyE ||
                key == LogicalKeyboardKey.space)) {
          _confirmDialogueChoice();
          return KeyEventResult.handled;
        }
      } else {
        if (event is KeyDownEvent &&
            (key == LogicalKeyboardKey.keyE ||
                key == LogicalKeyboardKey.space)) {
          _advanceDialogue();
          return KeyEventResult.handled;
        }
      }
      return KeyEventResult.ignored;
    }

    if (_flowPhase != _RuntimeFlowPhase.overworld) {
      return KeyEventResult.ignored;
    }

    if (event is KeyDownEvent &&
        (key == LogicalKeyboardKey.keyE || key == LogicalKeyboardKey.space)) {
      _handleInteract();
      return KeyEventResult.handled;
    }

    return KeyEventResult.handled;
  }

  @override
  void update(double dt) {
    super.update(dt);
    _updateFps(dt);
    _runtimeClockMs += dt * 1000;
    _placedBehaviorCooldownGate.prune(nowMs: _runtimeClockMs);
    _updateActorDepthOrdering();
    _syncCameraToPlayer();
    _syncNpcCollisionDebugOverlay();

    if (_flowPhase != _RuntimeFlowPhase.overworld) {
      return;
    }

    final pendingWarp = _pendingWarp;
    if (pendingWarp != null && !_player.isStepping) {
      _pendingWarp = null;
      _handleWarp(pendingWarp);
      return;
    }

    final pendingConnection = _pendingConnection;
    if (pendingConnection != null && !_player.isStepping) {
      _pendingConnection = null;
      _handleConnection(pendingConnection);
      return;
    }

    final pendingBattleRequest = _pendingBattleRequest;
    if (pendingBattleRequest != null && !_player.isStepping) {
      _pendingBattleRequest = null;
      _startBattleHandoff(pendingBattleRequest);
      return;
    }

    final pendingPlacedElementBehavior = _pendingPlacedElementBehavior;
    if (pendingPlacedElementBehavior != null && !_player.isStepping) {
      _pendingPlacedElementBehavior = null;
      _executePlacedElementBehavior(
        element: pendingPlacedElementBehavior.element,
        behavior: pendingPlacedElementBehavior.behavior,
        trigger: pendingPlacedElementBehavior.trigger,
      );
      return;
    }

    // Tick du système de déplacement scripté PNJ.
    //
    // Ce tick reste dans le flux overworld pour ce MVP:
    // - pas d'exécution pendant dialogue/battle transition;
    // - base propre pour un futur "wait movement" en cutscene.
    _scriptedEntityMovementController?.update(dt);
    _processPendingScenarioNpcWarpEntries();
    _processPendingScenarioMoveContinuations();
    _processPendingScenarioFollowRequest();
    _processPendingScenarioTransitionMapRequest();
    _processPendingScenarioReachedEndCompletions();

    // Tick runner cutscene MVP (séquentiel).
    _cutsceneRunner.update(dt);
    _pendingCutsceneChoiceRequest = _cutsceneRunner.activeChoiceRequest;
    if (isCutsceneRunning) {
      // Tant que la cutscene n'est pas terminée, on ne laisse pas la boucle
      // input joueur déplacer le player.
      return;
    }

    _driveMovement();
  }

  void _updateActorDepthOrdering() {
    _player.priority = 1000 + _player.footPoint.y.round();
    for (final actor in _npcActors) {
      actor.priority = 1000 + actor.depthSortY.round();
    }
  }

  bool _isMovementKey(LogicalKeyboardKey key) {
    return key == LogicalKeyboardKey.arrowUp ||
        key == LogicalKeyboardKey.arrowDown ||
        key == LogicalKeyboardKey.arrowLeft ||
        key == LogicalKeyboardKey.arrowRight ||
        key == LogicalKeyboardKey.keyW ||
        key == LogicalKeyboardKey.keyA ||
        key == LogicalKeyboardKey.keyS ||
        key == LogicalKeyboardKey.keyD;
  }

  GameplayIntent? _intentFromPressedKeys() {
    Direction? dirFor(LogicalKeyboardKey key) {
      if (key == LogicalKeyboardKey.arrowUp || key == LogicalKeyboardKey.keyW) {
        return Direction.north;
      }
      if (key == LogicalKeyboardKey.arrowDown ||
          key == LogicalKeyboardKey.keyS) {
        return Direction.south;
      }
      if (key == LogicalKeyboardKey.arrowLeft ||
          key == LogicalKeyboardKey.keyA) {
        return Direction.west;
      }
      if (key == LogicalKeyboardKey.arrowRight ||
          key == LogicalKeyboardKey.keyD) {
        return Direction.east;
      }
      return null;
    }

    final preferred = _lastMoveKey;
    if (preferred != null && _pressedKeys.contains(preferred)) {
      final d = dirFor(preferred);
      if (d != null) {
        return MoveIntent(d);
      }
    }

    for (final key in _pressedKeys) {
      final d = dirFor(key);
      if (d != null) {
        return MoveIntent(d);
      }
    }
    return null;
  }

  void _driveMovement() {
    if (_suppressOverworldInputForScriptedPlayerMovement()) {
      _clearPressedMovementKeys();
      return;
    }
    if (_player.isStepping) {
      return;
    }

    final intent = _intentFromPressedKeys();
    if (intent == null) {
      _player.syncState(_world.player);
      return;
    }
    final attemptedDirection = intent is MoveIntent ? intent.direction : null;
    final attemptedX = attemptedDirection == null
        ? null
        : _world.player.pos.x + attemptedDirection.dx;
    final attemptedY = attemptedDirection == null
        ? null
        : _world.player.pos.y + attemptedDirection.dy;
    final attemptedOutOfBounds = attemptedX != null &&
        attemptedY != null &&
        (attemptedX < 0 ||
            attemptedY < 0 ||
            attemptedX >= _world.map.size.width ||
            attemptedY >= _world.map.size.height);

    // Collision runtime stricte contre les destinations PNJ réservées.
    //
    // Sans ce garde-fou, un joueur peut entrer dans la case cible d'un PNJ en
    // interpolation (avant commit canonique), créant un effet de traversée.
    if (attemptedDirection != null &&
        attemptedX != null &&
        attemptedY != null &&
        _isCellReservedByScriptedNpc(
          GridPos(x: attemptedX, y: attemptedY),
        )) {
      _world =
          _world.withPlayer(_world.player.copyWith(facing: attemptedDirection));
      _player.syncState(_world.player);
      return;
    }

    final previousPlayerPos = _world.player.pos;
    final result = stepGameplayWorld(_world, intent);
    _world = result.world;
    _syncGameStateFromWorld();
    _consumePathAnimationSignals(result.pathAnimationSignals);

    if (result is Blocked) {
      if (result.reason == GameplayMovementBlockReason.waterRequiresSurf) {
        _handleWaterBlocked();
      }
      if (attemptedOutOfBounds && attemptedDirection != null) {
        final direction = switch (attemptedDirection) {
          Direction.north => MapConnectionDirection.north,
          Direction.south => MapConnectionDirection.south,
          Direction.east => MapConnectionDirection.east,
          Direction.west => MapConnectionDirection.west,
        };
        debugPrint(
          '[connection] no connection for direction=${direction.name} map=${_bundle.map.id}',
        );
      }
      _player.syncState(_world.player);
      return;
    }

    if (result is Moved) {
      _player.startStep(
        _world.player,
        durationSeconds: PlayerComponent.kDefaultStepSeconds,
      );
      _checkStepEncounter();
      _checkTrainerLineOfSight(); // Check LoS only when player position changes
      _dispatchScenarioTriggerEnterFromMovement(
        previousPos: previousPlayerPos,
        currentPos: _world.player.pos,
      );
      return;
    }

    if (result is WarpTriggered) {
      if (result.warp.triggerMode == MapWarpTriggerMode.onEnter) {
        _player.startStep(
          _world.player,
          durationSeconds: PlayerComponent.kDefaultStepSeconds,
        );
      } else {
        _player.syncState(_world.player, snapToGrid: true);
      }
      _pendingWarp = result.warp;
      debugPrint(
        '[warp] Triggered warp ${result.warp.warpId} mode=${result.warp.triggerMode.name} -> map=${result.warp.targetMapId} pos=(${result.warp.targetPos.x}, ${result.warp.targetPos.y})',
      );
      return;
    }

    if (result is ConnectionTriggered) {
      _player.syncState(_world.player);
      _pendingConnection = result.connection;
      debugPrint(
        '[connection] exit detected map=${_bundle.map.id} direction=${result.connection.direction.name} target=${result.connection.targetMapId} offset=${result.connection.offset} source=(${result.connection.sourcePos.x}, ${result.connection.sourcePos.y})',
      );
      return;
    }

    if (result is PlacedElementInteracted) {
      final isMovementTrigger =
          result.trigger == MapPlacedElementTriggerType.onEnter ||
              result.trigger == MapPlacedElementTriggerType.onExit ||
              result.trigger == MapPlacedElementTriggerType.onNear;
      if (isMovementTrigger) {
        _player.startStep(
          _world.player,
          durationSeconds: PlayerComponent.kDefaultStepSeconds,
        );
      } else {
        _player.syncState(_world.player);
      }
      _pendingPlacedElementBehavior = result;
      final behaviorId = result.behavior.id.trim().isEmpty
          ? 'legacy'
          : result.behavior.id.trim();
      debugPrint(
        '[placed_behavior] queued trigger=${result.trigger.name} scope=${result.behavior.triggerScope.name} instance=${result.element.id} behavior=$behaviorId effect=${result.behavior.effect.type.name}',
      );
      _updateBehaviorDebugLine(
        'Queued ${result.trigger.name}/${result.behavior.triggerScope.name} · ${result.behavior.effect.type.name} · ${result.element.id}#$behaviorId',
      );
      return;
    }
  }

  void _checkStepEncounter() {
    final encounterKind = _world.player.movementMode == MovementMode.surf
        ? EncounterKind.surf
        : EncounterKind.walk;
    final pos = _world.player.pos;
    debugPrint(
      '[encounter] checking at x=${pos.x} y=${pos.y} kind=${encounterKind.name}',
    );
    final check = checkEncounterAtPlayerPosition(
      world: _world,
      project: _bundle.manifest,
      encounterKind: encounterKind,
      random: _encounterRandom,
      policy: _kEncounterPolicy,
    );
    _logEncounterCheck(check);
    if (!check.triggered) {
      return;
    }
    final encounter = check.encounter;
    if (encounter == null) {
      return;
    }
    final request = buildBattleStartRequestFromEncounter(
      encounter: encounter,
      world: _world,
    );
    _pendingBattleRequest = request;
    debugPrint(
      '[battle] battle request created kind=${request.kind.name} source=${request.source.name} requestId=${request.requestId}',
    );
    debugPrint(
      '[battle] wild payload species=${encounter.speciesId} level=${encounter.level} map=${encounter.mapId} zone=${encounter.zoneId}',
    );
  }

  /// Détecte les entrées dans des triggers de map pour alimenter les sources
  /// scénario `sourceTriggerEnter`.
  ///
  /// Le calcul est local et déterministe:
  /// - on lit les triggers couvrant l'ancienne position,
  /// - on lit les triggers couvrant la nouvelle position,
  /// - on déclenche uniquement les IDs présents dans "nouvelle - ancienne".
  void _dispatchScenarioTriggerEnterFromMovement({
    required GridPos previousPos,
    required GridPos currentPos,
  }) {
    // On privilégie l'état mémorisé pour éviter de recalculer l'ancienne
    // couverture à chaque tick. Un fallback de sécurité reste possible.
    final previousIds = _activeScenarioTriggerIds.isEmpty
        ? _scenarioRuntime.triggerIdsAtPosition(
            map: _bundle.map,
            pos: previousPos,
          )
        : _activeScenarioTriggerIds;
    final currentIds = _scenarioRuntime.triggerIdsAtPosition(
      map: _bundle.map,
      pos: currentPos,
    );
    _activeScenarioTriggerIds = currentIds;
    final enteredIds =
        currentIds.difference(previousIds).toList(growable: false)..sort();
    for (final triggerId in enteredIds) {
      _dispatchScenarioRuntimeSource(
        ScenarioRuntimeSourceEvent.triggerEnter(
          mapId: _activeMapId,
          triggerId: triggerId,
        ),
      );
    }
  }

  /// Point d'entrée unique pour les déclenchements runtime du Scenario Graph.
  ///
  /// Cette méthode centralise:
  /// - le guard de phase (overworld/script actif),
  /// - l'appel à l'exécuteur scénario,
  /// - le branchement vers les effets runtime (dialogue/script/message),
  /// - la synchronisation de GameState lorsque le flow mutera des flags.
  ScenarioRuntimeExecutionResult _dispatchScenarioRuntimeSource(
    ScenarioRuntimeSourceEvent sourceEvent,
  ) {
    if (_flowPhase != _RuntimeFlowPhase.overworld) {
      return const ScenarioRuntimeExecutionResult(
        status: ScenarioRuntimeExecutionStatus.noMatchingSource,
        effect: ScenarioRuntimeEffect.none(),
        message: 'Ignored: flow is not in overworld phase.',
      );
    }
    final activeScript = _activeScriptController;
    if (activeScript != null && !activeScript.isTerminated) {
      return const ScenarioRuntimeExecutionResult(
        status: ScenarioRuntimeExecutionStatus.noMatchingSource,
        effect: ScenarioRuntimeEffect.none(),
        message: 'Ignored: a script is already running.',
      );
    }
    final scenarios = _bundle.manifest.scenarios;
    if (scenarios.isEmpty) {
      return const ScenarioRuntimeExecutionResult(
        status: ScenarioRuntimeExecutionStatus.noMatchingSource,
        effect: ScenarioRuntimeEffect.none(),
        message: 'No scenario available in current manifest.',
      );
    }

    final result = _scenarioRuntime.dispatch(
      scenarios: scenarios,
      sourceEvent: sourceEvent,
      context: _buildScenarioRuntimeExecutionContext(),
    );

    // Step Studio : on ne complète pas sur "flow reached end" uniquement.
    // La completion est validée quand les effets runtime visibles sont terminés.
    _handleScenarioRuntimeCompletionResult(
      result,
      origin: 'dispatch:${sourceEvent.type.name}',
    );

    // On maintient une trace explicite en logs pour faciliter le debug.
    if (result.status == ScenarioRuntimeExecutionStatus.noMatchingSource) {
      return result;
    }
    debugPrint(
      '[scenario_runtime] source=${sourceEvent.type.name} map=${sourceEvent.mapId} trigger=${sourceEvent.triggerId ?? '-'} entity=${sourceEvent.entityId ?? '-'} status=${result.status.name} scenario=${result.scenarioId ?? '-'} sourceNode=${result.sourceNodeId ?? '-'} stopNode=${result.stopNodeId ?? '-'} message=${result.message}',
    );
    return result;
  }

  /// Contexte partagé dispatch / continuation : inclut le filtre Step Studio
  /// pour ne pas relancer une cutscene locale dont la step est déjà complétée.
  ScenarioRuntimeExecutionContext _buildScenarioRuntimeExecutionContext() {
    return ScenarioRuntimeExecutionContext(
      gameState: _gameState,
      onGameStateUpdated: (state) {
        _gameState = state;
        _refreshWorldNpcPresence();
      },
      shouldSkipScenario: _shouldSkipLocalScenarioForCompletedStep,
      openDialogue: _openScenarioDialogueById,
      runScript: _runScenarioScriptById,
      showMessage: (message) => _showNotification(message),
      moveCharacter: ({
        required entityId,
        required targetKind,
        required targetId,
        required waitForCompletion,
        runtimeSourceId,
      }) {
        return _runScenarioMoveCharacter(
          entityId: entityId,
          targetKind: targetKind,
          targetId: targetId,
          waitForCompletion: waitForCompletion,
          runtimeSourceId: runtimeSourceId,
        );
      },
      followCharacter: ({
        required leaderEntityId,
      }) {
        return _runScenarioFollowCharacter(leaderEntityId: leaderEntityId);
      },
      faceCharacter: ({
        required entityId,
        required direction,
      }) {
        return _runScenarioFaceCharacter(
          entityId: entityId,
          direction: direction,
        );
      },
      transitionMap: ({
        required mapId,
        required warpId,
      }) {
        return _runScenarioTransitionMap(
          mapId: mapId,
          warpId: warpId,
        );
      },
    );
  }

  /// Index Step Studio mis en cache tant que le bundle courant est inchangé
  /// (évite de re-parser le JSON à chaque déclencheur).
  StepCompletionCutsceneIndex _stepCompletionIndexForCurrentBundle() {
    if (!identical(_cachedStepCompletionBundleForIndex, _bundle)) {
      _cachedStepCompletionBundleForIndex = _bundle;
      _cachedStepCompletionIndex =
          buildStepCompletionCutsceneIndex(_bundle.manifest.scenarios);
    }
    return _cachedStepCompletionIndex!;
  }

  /// Si la cutscene [scenarioId] est la condition de fin d’une step déjà
  /// enregistrée dans [PlayerProgression.completedStepIds], on ignore ce
  /// scénario pour permettre à un autre candidat de matcher (ou aucun).
  bool _shouldSkipLocalScenarioForCompletedStep(String scenarioId) {
    final index = _stepCompletionIndexForCurrentBundle();
    final stepId = index.stepIdToCompleteWhenCutsceneEnds(scenarioId);
    if (stepId == null) {
      return false;
    }
    return _gameState.progression.completedStepIds.contains(stepId);
  }

  /// Capture un résultat scénario et décide si la completion doit être :
  /// - appliquée immédiatement;
  /// - ou différée jusqu'à la fin réelle des effets runtime visibles.
  void _handleScenarioRuntimeCompletionResult(
    ScenarioRuntimeExecutionResult result, {
    required String origin,
  }) {
    if (result.status != ScenarioRuntimeExecutionStatus.reachedEnd) {
      return;
    }
    final scenarioId = result.scenarioId?.trim();
    if (scenarioId == null || scenarioId.isEmpty) {
      return;
    }
    final blockingReason = _scenarioCompletionBlockingReason();
    if (blockingReason == null) {
      _applyScenarioReachedEndCompletion(
          scenarioId: scenarioId, origin: origin);
      return;
    }
    for (final pending in _pendingScenarioReachedEndQueue) {
      if (pending.scenarioId == scenarioId) {
        debugPrint(
          '[step_studio_trace] completion_deferred_duplicate scenario=$scenarioId origin=$origin reason="$blockingReason"',
        );
        return;
      }
    }
    _pendingScenarioReachedEndQueue.add(
      _PendingScenarioReachedEnd(
        scenarioId: scenarioId,
        origin: origin,
        queuedAtMs: _runtimeClockMs,
      ),
    );
    debugPrint(
      '[step_studio_trace] completion_deferred scenario=$scenarioId origin=$origin reason="$blockingReason"',
    );
  }

  /// Applique réellement la completion progression pour un scénario qui a
  /// atteint `end` ET dont la mise en scène runtime est terminée.
  void _applyScenarioReachedEndCompletion({
    required String scenarioId,
    required String origin,
  }) {
    var progression = _gameState.progression;
    var changed = false;

    final index = _stepCompletionIndexForCurrentBundle();
    final stepId = index.stepIdToCompleteWhenCutsceneEnds(scenarioId);
    if (stepId != null) {
      debugPrint(
        '[step_studio_trace] runtime_mark_step_completed_candidate scenario=$scenarioId step=$stepId before=${progression.completedStepIds}',
      );
      final nextSteps = appendCompletedStepIdIfAbsent(
        progression.completedStepIds,
        stepId,
      );
      if (!identical(nextSteps, progression.completedStepIds)) {
        progression = progression.copyWith(completedStepIds: nextSteps);
        changed = true;
        debugPrint(
          '[step_studio] step "$stepId" completed (cutscene "$scenarioId" reached end).',
        );
        debugPrint(
          '[step_studio_trace] runtime_completed_steps_updated scenario=$scenarioId step=$stepId after=${progression.completedStepIds}',
        );
      }
    }

    ScenarioAsset? scenarioAsset;
    for (final s in _bundle.manifest.scenarios) {
      if (s.id == scenarioId) {
        scenarioAsset = s;
        break;
      }
    }
    if (scenarioAsset != null &&
        scenarioAsset.scope == ScenarioScope.localEventFlow) {
      final nextCut = appendCompletedCutsceneIdIfAbsent(
        progression.completedCutsceneIds,
        scenarioId,
      );
      if (!identical(nextCut, progression.completedCutsceneIds)) {
        progression = progression.copyWith(completedCutsceneIds: nextCut);
        changed = true;
        debugPrint(
          '[runtime] local scenario "$scenarioId" marked completed (predicate cutsceneCompleted).',
        );
      }
    }

    if (changed) {
      _gameState = _gameState.copyWith(progression: progression);
      _refreshWorldNpcPresence();
    }
    debugPrint(
      '[step_studio_trace] completion_applied scenario=$scenarioId origin=$origin completedSteps=${_gameState.progression.completedStepIds} completedCutscenes=${_gameState.progression.completedCutsceneIds}',
    );
  }

  /// Retourne la raison bloquante empêchant de finaliser la cutscene.
  ///
  /// Tant qu'une raison existe, on ne matérialise pas les effects de progression
  /// (`completedStepIds`, `completedCutsceneIds`).
  String? _scenarioCompletionBlockingReason() {
    return scenarioRuntimeCompletionBlockingReason(
      isOverworldFlow: _flowPhase == _RuntimeFlowPhase.overworld,
      flowPhaseName: _flowPhase.name,
      isDialogueOpen: _dialogueOverlay != null,
      isCutsceneRunnerActive: isCutsceneRunning,
      hasPendingFollowCharacter: _pendingScenarioFollowRequest != null,
      hasPendingMoveContinuations:
          _pendingScenarioMoveContinuationsByEntity.isNotEmpty,
      hasPendingNpcWarpEntries: _pendingScenarioNpcWarpEntries.isNotEmpty,
      hasPendingTransitionMapRequest:
          _pendingScenarioTransitionMapRequest != null,
      hasPendingRuntimeWarp: _pendingWarp != null,
      hasPendingRuntimeConnection: _pendingConnection != null,
      isPlayerStepInProgress: _player.isStepping,
    );
  }

  /// Dès que les effets visibles sont terminés, on applique les complétions
  /// différées dans l'ordre d'arrivée.
  void _processPendingScenarioReachedEndCompletions() {
    if (_pendingScenarioReachedEndQueue.isEmpty) {
      _lastScenarioCompletionBlockReason = null;
      return;
    }
    final blockingReason = _scenarioCompletionBlockingReason();
    if (blockingReason != null) {
      if (_lastScenarioCompletionBlockReason != blockingReason) {
        debugPrint(
          '[step_studio_trace] completion_gate_blocked reason="$blockingReason" queue=${_pendingScenarioReachedEndQueue.length}',
        );
        _lastScenarioCompletionBlockReason = blockingReason;
      }
      return;
    }
    if (_lastScenarioCompletionBlockReason != null) {
      debugPrint(
        '[step_studio_trace] completion_gate_unblocked queue=${_pendingScenarioReachedEndQueue.length}',
      );
      _lastScenarioCompletionBlockReason = null;
    }
    final pendingItems =
        List<_PendingScenarioReachedEnd>.from(_pendingScenarioReachedEndQueue);
    _pendingScenarioReachedEndQueue.clear();
    for (final pending in pendingItems) {
      final waitMs = (_runtimeClockMs - pending.queuedAtMs).round();
      debugPrint(
        '[step_studio_trace] completion_deferred_flush scenario=${pending.scenarioId} waitedMs=$waitMs origin=${pending.origin}',
      );
      _applyScenarioReachedEndCompletion(
        scenarioId: pending.scenarioId,
        origin: 'deferred:${pending.origin}',
      );
    }
  }

  /// Ouvre un dialogue projet à partir d'un `dialogueId`.
  ///
  /// Callback utilisé par le bridge scénario.
  bool _openScenarioDialogueById(
    String dialogueId, {
    String? startNode,
    String? runtimeSourceId,
  }) {
    final normalizedDialogueId = dialogueId.trim();
    if (normalizedDialogueId.isEmpty) {
      return false;
    }
    final opened = _tryOpenDialogue(
      runtimeSourceId ?? 'scenario',
      DialogueRef(
        dialogueId: normalizedDialogueId,
        startNode: startNode,
      ),
      'Dialogue introuvable: $normalizedDialogueId',
    );
    if (opened && runtimeSourceId != null && runtimeSourceId.isNotEmpty) {
      _scheduleScenarioContinuationAfterDialogue(runtimeSourceId);
    }
    return opened;
  }

  void _scheduleScenarioContinuationAfterDialogue(String runtimeSourceId) {
    if (!runtimeSourceId.startsWith('scenario:')) {
      return;
    }
    final previous = _pendingPostDialogueAction;
    _pendingPostDialogueAction = () {
      previous?.call();
      _resumeScenarioAfterRuntimeSource(runtimeSourceId);
    };
  }

  void _resumeScenarioAfterRuntimeSource(String runtimeSourceId) {
    final parts = runtimeSourceId.split(':');
    if (parts.length != 4) {
      return;
    }
    final scenarioId = parts[1].trim();
    final sourceNodeId = parts[2].trim();
    final resumeAfterNodeId = parts[3].trim();
    if (scenarioId.isEmpty ||
        sourceNodeId.isEmpty ||
        resumeAfterNodeId.isEmpty) {
      return;
    }
    final result = _scenarioRuntime.dispatchContinuation(
      scenarios: _bundle.manifest.scenarios,
      scenarioId: scenarioId,
      sourceNodeId: sourceNodeId,
      resumeAfterNodeId: resumeAfterNodeId,
      context: _buildScenarioRuntimeExecutionContext(),
    );
    _handleScenarioRuntimeCompletionResult(
      result,
      origin: 'continuation:$runtimeSourceId',
    );
    debugPrint(
      '[scenario_runtime] continuation source=$runtimeSourceId status=${result.status.name} scenario=${result.scenarioId ?? '-'} stopNode=${result.stopNodeId ?? '-'} message=${result.message}',
    );
  }

  bool _runScenarioMoveCharacter({
    required String entityId,
    required String targetKind,
    required String targetId,
    required bool waitForCompletion,
    String? runtimeSourceId,
  }) {
    final trimmedEntity = entityId.trim();
    if (trimmedEntity == 'player') {
      _scriptedEntityMovementController?.syncTrackedEntityPosition(
        trimmedEntity,
        _world.player.pos,
      );
    }
    final destination = _resolveScenarioMoveTarget(
      targetKind: targetKind,
      targetId: targetId,
    );
    if (destination == null) {
      debugPrint(
        '[scenario_runtime] moveCharacter target unresolved kind=$targetKind targetId=$targetId',
      );
      return false;
    }
    var resolvedDestination = destination;
    var entityApproachCandidates = const <GridPos>[];
    if (targetKind == 'entity') {
      entityApproachCandidates = _resolveScenarioEntityApproachCandidates(
        moverEntityId: entityId,
        targetEntityId: targetId,
        primaryDestination: destination,
      );
      if (entityApproachCandidates.isEmpty) {
        debugPrint(
          '[scenario_runtime] moveCharacter entity target has no reachable adjacent cell entity=$entityId target=$targetId',
        );
        return false;
      }
      resolvedDestination = entityApproachCandidates.first;
    }
    var started = startScriptedNpcMove(
      entityId: entityId,
      destination: resolvedDestination,
    );
    if (started.state == ScriptedEntityMovementState.failed &&
        targetKind == 'warp') {
      final warp = _findMapWarpById(targetId);
      if (warp != null) {
        final fallbackCandidates = _resolveScenarioWarpApproachCandidates(
          entityId: entityId,
          warp: warp,
          primaryDestination: destination,
        );
        for (final candidate in fallbackCandidates) {
          final fallbackStarted = startScriptedNpcMove(
            entityId: entityId,
            destination: candidate,
          );
          if (fallbackStarted.state != ScriptedEntityMovementState.failed) {
            resolvedDestination = candidate;
            started = fallbackStarted;
            debugPrint(
              '[scenario_runtime] moveCharacter warp fallback entity=$entityId warp=${warp.id} destination=(${candidate.x},${candidate.y})',
            );
            break;
          }
        }
      }
    }
    if (started.state == ScriptedEntityMovementState.failed &&
        targetKind == 'entity') {
      final fallbackCandidates = entityApproachCandidates.isNotEmpty
          ? entityApproachCandidates.skip(1)
          : _resolveScenarioEntityApproachCandidates(
              moverEntityId: entityId,
              targetEntityId: targetId,
              primaryDestination: destination,
            );
      for (final candidate in fallbackCandidates) {
        final fallbackStarted = startScriptedNpcMove(
          entityId: entityId,
          destination: candidate,
        );
        if (fallbackStarted.state != ScriptedEntityMovementState.failed) {
          resolvedDestination = candidate;
          started = fallbackStarted;
          debugPrint(
            '[scenario_runtime] moveCharacter entity fallback entity=$entityId target=$targetId destination=(${candidate.x},${candidate.y})',
          );
          break;
        }
      }
    }
    if (started.state == ScriptedEntityMovementState.failed) {
      debugPrint(
        '[scenario_runtime] moveCharacter failed entity=$entityId destination=(${resolvedDestination.x},${resolvedDestination.y})',
      );
      return false;
    }
    if (targetKind == 'warp') {
      final warp = _findMapWarpById(targetId);
      if (warp != null) {
        _pendingScenarioNpcWarpEntries[entityId] = _PendingScenarioNpcWarpEntry(
          entityId: entityId,
          warpId: warp.id,
          warpPos: warp.pos,
          approachPos: resolvedDestination,
        );
      }
    } else {
      _pendingScenarioNpcWarpEntries.remove(entityId);
    }
    if (waitForCompletion) {
      final runtimeSource = runtimeSourceId?.trim() ?? '';
      if (runtimeSource.startsWith('scenario:') && trimmedEntity.isNotEmpty) {
        _pendingScenarioMoveContinuationsByEntity[trimmedEntity] =
            _PendingScenarioMoveContinuation(
          entityId: trimmedEntity,
          runtimeSourceId: runtimeSource,
          targetKind: targetKind,
        );
      }
      debugPrint(
        '[scenario_runtime] moveCharacter started entity=$entityId destination=(${resolvedDestination.x},${resolvedDestination.y}) waitForCompletion=true',
      );
    } else {
      _pendingScenarioMoveContinuationsByEntity.remove(trimmedEntity);
    }
    return true;
  }

  bool _runScenarioTransitionMap({
    required String mapId,
    required String warpId,
  }) {
    final normalizedMapId = mapId.trim();
    final normalizedWarpId = warpId.trim();
    if (normalizedMapId.isEmpty || normalizedWarpId.isEmpty) {
      debugPrint(
        '[scenario_runtime] transitionMap invalid mapId="$mapId" warpId="$warpId"',
      );
      return false;
    }
    _pendingScenarioTransitionMapRequest = _PendingScenarioTransitionMapRequest(
      mapId: normalizedMapId,
      warpId: normalizedWarpId,
    );
    debugPrint(
      '[scenario_runtime] transitionMap scheduled map=$normalizedMapId warp=$normalizedWarpId',
    );
    return true;
  }

  void _processPendingScenarioTransitionMapRequest() {
    final pending = _pendingScenarioTransitionMapRequest;
    if (pending == null) {
      return;
    }

    // On attend la fin du suivi (followCharacter) pour ne pas couper la scène.
    if (_pendingScenarioFollowRequest != null) {
      return;
    }
    if (_player.isStepping) {
      return;
    }

    _pendingScenarioTransitionMapRequest = null;
    unawaited(_executeScenarioTransitionMapRequest(pending));
  }

  Future<void> _executeScenarioTransitionMapRequest(
    _PendingScenarioTransitionMapRequest request,
  ) async {
    if (_flowPhase != _RuntimeFlowPhase.overworld) {
      debugPrint(
        '[scenario_runtime] transitionMap ignored: flow=${_flowPhase.name}',
      );
      return;
    }
    try {
      final loadedBundle = await loadRuntimeMapBundle(
        projectFilePath: projectFilePath,
        mapId: request.mapId,
      );
      final targetBundle = _resolveRuntimeBundle(loadedBundle);
      MapWarp? targetWarp;
      for (final candidate in targetBundle.map.warps) {
        if (candidate.id == request.warpId) {
          targetWarp = candidate;
          break;
        }
      }
      if (targetWarp == null) {
        debugPrint(
          '[scenario_runtime] transitionMap failed: warp "${request.warpId}" not found on map "${request.mapId}"',
        );
        _showNotification('Transition impossible (warp introuvable)');
        return;
      }

      final transition = TriggeredWarp(
        warpId: 'scenario:${request.warpId}',
        targetMapId: targetBundle.map.id,
        targetPos: targetWarp.pos,
        triggerMode: MapWarpTriggerMode.onEnter,
      );
      debugPrint(
        '[scenario_runtime] transitionMap start map=${transition.targetMapId} warp=${request.warpId} pos=(${transition.targetPos.x},${transition.targetPos.y})',
      );
      await _handleWarp(transition);
    } catch (e, st) {
      debugPrint(
        '[scenario_runtime] transitionMap failed map=${request.mapId} warp=${request.warpId}: $e\n$st',
      );
      _showNotification('Transition impossible');
    }
  }

  MapWarp? _findMapWarpById(String warpId) {
    final normalized = warpId.trim();
    if (normalized.isEmpty) {
      return null;
    }
    for (final warp in _world.map.warps) {
      if (warp.id == normalized) {
        return warp;
      }
    }
    return null;
  }

  List<GridPos> _resolveScenarioWarpApproachCandidates({
    required String entityId,
    required MapWarp warp,
    required GridPos primaryDestination,
  }) {
    final currentPos = _resolveScenarioEntityPosition(entityId) ?? warp.pos;
    final candidates = <GridPos>[];
    final seen = <GridPos>{primaryDestination};

    // Anneaux autour du warp: on essaie de rester proche de la porte tout en
    // respectant le footprint collision réel du PNJ (souvent 2x2).
    const maxRadius = 4;
    for (var radius = 1; radius <= maxRadius; radius++) {
      for (var dx = -radius; dx <= radius; dx++) {
        final top = GridPos(x: warp.pos.x + dx, y: warp.pos.y - radius);
        if (_addWarpApproachCandidate(
          seen: seen,
          out: candidates,
          candidate: top,
          entityId: entityId,
        )) {
          // no-op
        }
        final bottom = GridPos(x: warp.pos.x + dx, y: warp.pos.y + radius);
        _addWarpApproachCandidate(
          seen: seen,
          out: candidates,
          candidate: bottom,
          entityId: entityId,
        );
      }
      for (var dy = -radius + 1; dy <= radius - 1; dy++) {
        final left = GridPos(x: warp.pos.x - radius, y: warp.pos.y + dy);
        _addWarpApproachCandidate(
          seen: seen,
          out: candidates,
          candidate: left,
          entityId: entityId,
        );
        final right = GridPos(x: warp.pos.x + radius, y: warp.pos.y + dy);
        _addWarpApproachCandidate(
          seen: seen,
          out: candidates,
          candidate: right,
          entityId: entityId,
        );
      }
    }

    candidates.sort((a, b) {
      final aDoor = (a.x - warp.pos.x).abs() + (a.y - warp.pos.y).abs();
      final bDoor = (b.x - warp.pos.x).abs() + (b.y - warp.pos.y).abs();
      if (aDoor != bDoor) {
        return aDoor.compareTo(bDoor);
      }
      final aCurrent = (a.x - currentPos.x).abs() + (a.y - currentPos.y).abs();
      final bCurrent = (b.x - currentPos.x).abs() + (b.y - currentPos.y).abs();
      return aCurrent.compareTo(bCurrent);
    });
    return candidates;
  }

  List<GridPos> _resolveScenarioEntityApproachCandidates({
    required String moverEntityId,
    required String targetEntityId,
    required GridPos primaryDestination,
  }) {
    final currentPos =
        _resolveScenarioEntityPosition(moverEntityId) ?? primaryDestination;

    MapRect targetRect;
    if (targetEntityId == 'player') {
      targetRect = MapRect(
        pos: _world.player.pos,
        size: const GridSize(width: 1, height: 1),
      );
    } else {
      MapEntity? targetEntity;
      for (final entry in _world.map.entities) {
        if (entry.id == targetEntityId) {
          targetEntity = entry;
          break;
        }
      }
      if (targetEntity == null) {
        return const <GridPos>[];
      }
      targetRect = resolveEntityCollisionFootprint(targetEntity);
    }

    final candidates = <GridPos>[];
    final seen = <GridPos>{primaryDestination};
    for (final cell in _adjacentCellsAroundRect(targetRect)) {
      if (!seen.add(cell)) {
        continue;
      }
      if (!_isWithinMapBounds(_world.map, cell)) {
        continue;
      }
      if (!_isScenarioNpcAnchorPassable(
          entityId: moverEntityId, anchor: cell)) {
        continue;
      }
      candidates.add(cell);
    }

    candidates.sort((a, b) {
      final aCurrent = (a.x - currentPos.x).abs() + (a.y - currentPos.y).abs();
      final bCurrent = (b.x - currentPos.x).abs() + (b.y - currentPos.y).abs();
      if (aCurrent != bCurrent) {
        return aCurrent.compareTo(bCurrent);
      }
      final aTarget =
          (a.x - targetRect.pos.x).abs() + (a.y - targetRect.pos.y).abs();
      final bTarget =
          (b.x - targetRect.pos.x).abs() + (b.y - targetRect.pos.y).abs();
      return aTarget.compareTo(bTarget);
    });
    return candidates;
  }

  bool _addWarpApproachCandidate({
    required Set<GridPos> seen,
    required List<GridPos> out,
    required GridPos candidate,
    required String entityId,
  }) {
    if (!seen.add(candidate)) {
      return false;
    }
    if (!_isWithinMapBounds(_world.map, candidate)) {
      return false;
    }
    if (!_isScenarioNpcAnchorPassable(entityId: entityId, anchor: candidate)) {
      return false;
    }
    out.add(candidate);
    return true;
  }

  bool _isScenarioNpcAnchorPassable({
    required String entityId,
    required GridPos anchor,
  }) {
    if (entityId.trim() == 'player') {
      return _isPlayerScriptedMoveAnchorPassable(anchor);
    }
    final probe = evaluateScriptedNpcAnchorPassability(
      world: _world,
      entityId: entityId,
      anchorPos: anchor,
      movementMode: MovementMode.walk,
      dynamicBlockedCells: _scriptedNpcDynamicBlockedCells(
        ignoreEntityId: entityId,
      ),
    );
    return probe.passable;
  }

  bool _isPlayerScriptedMoveAnchorPassable(GridPos anchor) {
    final mode = _world.player.movementMode;
    if (_world.movementBlockReasonAt(
          x: anchor.x,
          y: anchor.y,
          movementMode: mode,
        ) !=
        null) {
      return false;
    }
    for (final cell
        in _scriptedNpcDynamicBlockedCells(ignoreEntityId: 'player')) {
      if (cell.x == anchor.x && cell.y == anchor.y) {
        return false;
      }
    }
    return true;
  }

  GridPos? _resolveScenarioEntityPosition(String entityId) {
    if (entityId == 'player') {
      return _world.player.pos;
    }
    final runtimePos = _runtimeNpcPositions[entityId];
    if (runtimePos != null) {
      return runtimePos;
    }
    for (final entity in _world.map.entities) {
      if (entity.id == entityId) {
        return entity.pos;
      }
    }
    return null;
  }

  GridPos? _resolveScenarioMoveTarget({
    required String targetKind,
    required String targetId,
  }) {
    final map = _world.map;
    switch (targetKind) {
      case 'warp':
        for (final warp in map.warps) {
          if (warp.id == targetId) {
            return warp.pos;
          }
        }
        return null;
      case 'spawn':
        for (final entity in map.entities) {
          if (entity.kind == MapEntityKind.spawn && entity.id == targetId) {
            return entity.pos;
          }
        }
        return null;
      case 'entity':
        if (targetId == 'player') {
          return _world.player.pos;
        }
        for (final entity in map.entities) {
          if (entity.id == targetId) {
            return entity.pos;
          }
        }
        return null;
      default:
        return null;
    }
  }

  bool _suppressOverworldInputForScriptedPlayerMovement() {
    final status = scriptedNpcMovementStatus('player');
    return status.state == ScriptedEntityMovementState.moving;
  }

  void _clearPressedMovementKeys() {
    _pressedKeys.removeWhere(_isMovementKey);
    if (_lastMoveKey != null && !_pressedKeys.contains(_lastMoveKey!)) {
      _lastMoveKey = null;
    }
  }

  void _processPendingScenarioNpcWarpEntries() {
    if (_pendingScenarioNpcWarpEntries.isEmpty) {
      return;
    }
    final entityIds =
        _pendingScenarioNpcWarpEntries.keys.toList(growable: false)..sort();
    for (final entityId in entityIds) {
      final pending = _pendingScenarioNpcWarpEntries[entityId];
      if (pending == null) {
        continue;
      }
      final status = scriptedNpcMovementStatus(entityId);
      if (status.state == ScriptedEntityMovementState.moving) {
        continue;
      }
      if (status.state == ScriptedEntityMovementState.failed) {
        debugPrint(
          '[scenario_runtime] npc warp canceled entity=$entityId warp=${pending.warpId} reason="${status.failureReason ?? 'move failed'}"',
        );
        _pendingScenarioNpcWarpEntries.remove(entityId);
        continue;
      }
      if (status.state != ScriptedEntityMovementState.completed) {
        final stillPresent = _resolveScenarioEntityPosition(entityId) != null;
        if (!stillPresent) {
          _pendingScenarioNpcWarpEntries.remove(entityId);
        }
        continue;
      }
      _pendingScenarioNpcWarpEntries.remove(entityId);
      _completeScenarioNpcWarpEntry(pending);
    }
  }

  void _processPendingScenarioMoveContinuations() {
    if (_pendingScenarioMoveContinuationsByEntity.isEmpty) {
      return;
    }
    final entityIds = _pendingScenarioMoveContinuationsByEntity.keys
        .toList(growable: false)
      ..sort();
    for (final entityId in entityIds) {
      final pending = _pendingScenarioMoveContinuationsByEntity[entityId];
      if (pending == null) {
        continue;
      }

      if (pending.targetKind == 'warp' && _pendingWarp != null) {
        // Le déplacement est "fini" uniquement après consommation effective du
        // warp joueur et retour en overworld.
        continue;
      }

      final status = scriptedNpcMovementStatus(entityId);
      if (status.state == ScriptedEntityMovementState.moving) {
        continue;
      }
      if (status.state == ScriptedEntityMovementState.failed) {
        _pendingScenarioMoveContinuationsByEntity.remove(entityId);
        continue;
      }
      if (status.state == ScriptedEntityMovementState.completed ||
          status.state == ScriptedEntityMovementState.idle) {
        _pendingScenarioMoveContinuationsByEntity.remove(entityId);
        _resumeScenarioAfterRuntimeSource(pending.runtimeSourceId);
      }
    }
  }

  void _completeScenarioNpcWarpEntry(_PendingScenarioNpcWarpEntry pending) {
    if (pending.entityId.trim() == 'player') {
      _completeScenarioPlayerWarpEntry(pending);
      return;
    }
    final removed = _despawnNpcFromActiveMap(pending.entityId);
    if (!removed) {
      debugPrint(
        '[scenario_runtime] npc warp failed to remove entity=${pending.entityId} warp=${pending.warpId}',
      );
      return;
    }
    debugPrint(
      '[scenario_runtime] npc entered warp entity=${pending.entityId} warp=${pending.warpId} approach=(${pending.approachPos.x},${pending.approachPos.y})',
    );
  }

  void _completeScenarioPlayerWarpEntry(_PendingScenarioNpcWarpEntry pending) {
    final warp = _findMapWarpById(pending.warpId);
    if (warp == null) {
      debugPrint(
        '[scenario_runtime] player warp failed: warp "${pending.warpId}" not found on map "${_bundle.map.id}"',
      );
      return;
    }
    _pendingWarp = TriggeredWarp(
      warpId: warp.id,
      targetMapId: warp.targetMapId,
      targetPos: warp.targetPos,
      triggerMode: warp.triggerMode,
    );
    debugPrint(
      '[scenario_runtime] player reached warp=${warp.id} -> map=${warp.targetMapId} target=(${warp.targetPos.x},${warp.targetPos.y})',
    );
  }

  bool _despawnNpcFromActiveMap(String entityId) {
    final normalized = entityId.trim();
    if (normalized.isEmpty) {
      return false;
    }
    final entities = _world.map.entities;
    final index = entities.indexWhere((entity) => entity.id == normalized);
    if (index < 0) {
      return false;
    }

    final updatedEntities = List<MapEntity>.from(entities)..removeAt(index);
    final updatedMap = _world.map.copyWith(entities: updatedEntities);
    final playerState = _world.player;
    _world = GameplayWorldState.initial(
      map: updatedMap,
      playerPos: playerState.pos,
      playerFacing: playerState.facing,
      playerMovementMode: playerState.movementMode,
      project: _bundle.manifest,
      tileWidth: _bundle.manifest.settings.tileWidth,
      tileHeight: _bundle.manifest.settings.tileHeight,
      npcMapPresencePredicate: _npcPresencePredicateFor(_bundle.manifest),
    );
    _bundle = RuntimeMapBundle(
      manifest: _bundle.manifest,
      map: updatedMap,
      projectRootDirectory: _bundle.projectRootDirectory,
      tilesetAbsolutePathsById: _bundle.tilesetAbsolutePathsById,
    );

    final loaded = _loadedMapsById[_activeMapId];
    if (loaded != null) {
      _purgeMountedNpcActorForEntity(entityId: normalized, loaded: loaded);
    }

    _scriptedNpcReservedOccupiedCellsByEntity.remove(normalized);
    _runtimeNpcPositions.remove(normalized);
    _triggeredTrainerBattles.remove(normalized);
    if (_pendingScenarioFollowRequest?.leaderEntityId == normalized) {
      _pendingScenarioFollowRequest = null;
    }
    _pendingScenarioNpcWarpEntries.remove(normalized);
    _pendingScenarioMoveContinuationsByEntity.remove(normalized);
    _scriptedEntityMovementController?.untrackEntity(normalized);
    _syncGameStateFromWorld();
    return true;
  }

  bool _runScenarioFollowCharacter({
    required String leaderEntityId,
  }) {
    _pendingScenarioFollowRequest = _PendingScenarioFollowRequest(
      leaderEntityId: leaderEntityId,
      requestedAtMs: _runtimeClockMs,
    );
    debugPrint(
      '[scenario_runtime] followCharacter activated leader=$leaderEntityId',
    );
    // On traite la première itération immédiatement pour éviter un frame de latence.
    _processPendingScenarioFollowRequest();
    return true;
  }

  void _processPendingScenarioFollowRequest() {
    final pending = _pendingScenarioFollowRequest;
    if (pending == null) {
      return;
    }
    final leaderPos = _resolveScenarioLeaderPosition(pending.leaderEntityId);
    if (leaderPos == null) {
      debugPrint(
        '[scenario_runtime] followCharacter canceled leader unresolved=${pending.leaderEntityId}',
      );
      _pendingScenarioFollowRequest = null;
      return;
    }
    final leaderRect = _resolveScenarioLeaderCollisionFootprint(
      leaderEntityId: pending.leaderEntityId,
      fallbackAnchor: leaderPos,
    );
    final leaderMovement = scriptedNpcMovementStatus(pending.leaderEntityId);
    final leaderTravelDirection = _resolveLeaderTravelDirection(
      pending: pending,
      leaderPos: leaderPos,
      movementStatus: leaderMovement,
    );
    final preferredTrailingSide = leaderTravelDirection == null
        ? null
        : _oppositeDirection(leaderTravelDirection);
    final playerPos = _world.player.pos;
    final playerAdjacentToLeader = _isPosAdjacentToRect(playerPos, leaderRect);

    // Condition de fin:
    // - leader immobile
    // - joueur déjà adjacent au footprint réel du leader.
    if (leaderMovement.state != ScriptedEntityMovementState.moving &&
        playerAdjacentToLeader) {
      debugPrint(
        '[scenario_runtime] followCharacter completed leader=${pending.leaderEntityId} player=(${playerPos.x},${playerPos.y})',
      );
      _pendingScenarioFollowRequest = null;
      return;
    }

    // Si le joueur est déjà en interpolation, on attend le prochain tick.
    if (_player.isStepping) {
      return;
    }

    final canReuseCachedPath = pending.cachedPath != null &&
        pending.cachedPathDestination != null &&
        pending.cachedPathLeaderPos != null &&
        pending.cachedPathLeaderPos!.x == leaderPos.x &&
        pending.cachedPathLeaderPos!.y == leaderPos.y;
    if (canReuseCachedPath) {
      final nextPos = _nextFollowPathStep(
        path: pending.cachedPath!,
        currentPos: playerPos,
      );
      if (nextPos != null) {
        final stepped = _stepPlayerAlongFollowPath(
          leaderEntityId: pending.leaderEntityId,
          leaderPos: leaderPos,
          destination: pending.cachedPathDestination!,
          nextPos: nextPos,
          preferredTrailingSide: preferredTrailingSide,
        );
        if (stepped) {
          pending.consecutiveBlockedSteps = 0;
          return;
        }
        pending.consecutiveBlockedSteps += 1;
        _clearPendingFollowPathCache(pending);
        if (leaderMovement.state != ScriptedEntityMovementState.moving &&
            pending.consecutiveBlockedSteps >= 10) {
          debugPrint(
            '[scenario_runtime] followCharacter canceled repeated blocked steps leader=${pending.leaderEntityId}',
          );
          _pendingScenarioFollowRequest = null;
        }
        return;
      }
      _clearPendingFollowPathCache(pending);
    }

    final followPlan = _resolveFollowPathPlanNearLeader(
      leaderEntityId: pending.leaderEntityId,
      leaderPos: leaderPos,
      preferredSide: preferredTrailingSide,
      strictPreferredSide:
          leaderMovement.state == ScriptedEntityMovementState.moving,
    );
    if (followPlan == null) {
      if (leaderMovement.state != ScriptedEntityMovementState.moving) {
        pending.consecutiveBlockedSteps += 1;
        if (pending.consecutiveBlockedSteps >= 10) {
          debugPrint(
            '[scenario_runtime] followCharacter canceled no reachable trailing path leader=${pending.leaderEntityId}',
          );
          _pendingScenarioFollowRequest = null;
        }
      }
      return;
    }
    pending.consecutiveBlockedSteps = 0;

    // Si on est déjà au meilleur point, on attend la prochaine évolution leader.
    if (followPlan.path.length <= 1 ||
        (followPlan.destination.x == playerPos.x &&
            followPlan.destination.y == playerPos.y)) {
      _clearPendingFollowPathCache(pending);
      return;
    }

    pending.cachedPath = followPlan.path;
    pending.cachedPathDestination = followPlan.destination;
    pending.cachedPathLeaderPos = leaderPos;
    final nextPos = _nextFollowPathStep(
      path: followPlan.path,
      currentPos: playerPos,
    );
    if (nextPos == null) {
      _clearPendingFollowPathCache(pending);
      return;
    }

    final stepped = _stepPlayerAlongFollowPath(
      leaderEntityId: pending.leaderEntityId,
      leaderPos: leaderPos,
      destination: followPlan.destination,
      nextPos: nextPos,
      preferredTrailingSide: preferredTrailingSide,
    );
    if (!stepped) {
      pending.consecutiveBlockedSteps += 1;
      _clearPendingFollowPathCache(pending);
      if (leaderMovement.state != ScriptedEntityMovementState.moving &&
          pending.consecutiveBlockedSteps >= 10) {
        debugPrint(
          '[scenario_runtime] followCharacter canceled repeated blocked steps leader=${pending.leaderEntityId}',
        );
        _pendingScenarioFollowRequest = null;
      }
    }
  }

  bool _stepPlayerAlongFollowPath({
    required String leaderEntityId,
    required GridPos leaderPos,
    required GridPos destination,
    required GridPos nextPos,
    required Direction? preferredTrailingSide,
  }) {
    final currentPos = _world.player.pos;
    final direction = _directionBetweenAdjacent(
      from: currentPos,
      to: nextPos,
    );
    if (direction == null) {
      debugPrint(
        '[scenario_runtime] followCharacter invalid non-adjacent path step leader=$leaderEntityId from=(${currentPos.x},${currentPos.y}) to=(${nextPos.x},${nextPos.y})',
      );
      return false;
    }

    final result = stepGameplayWorld(_world, MoveIntent(direction));
    if (result is! Moved) {
      debugPrint(
        '[scenario_runtime] followCharacter path step blocked leader=$leaderEntityId from=(${currentPos.x},${currentPos.y}) to=(${nextPos.x},${nextPos.y})',
      );
      return false;
    }
    _world = result.world;
    _syncGameStateFromWorld();
    _consumePathAnimationSignals(result.pathAnimationSignals);
    _player.startStep(
      _world.player,
      durationSeconds: PlayerComponent.kDefaultStepSeconds,
    );
    _dispatchScenarioTriggerEnterFromMovement(
      previousPos: currentPos,
      currentPos: _world.player.pos,
    );
    debugPrint(
      '[scenario_runtime] followCharacter stepping leader=$leaderEntityId leaderPos=(${leaderPos.x},${leaderPos.y}) trailingSide=${preferredTrailingSide?.name ?? '-'} destination=(${destination.x},${destination.y}) next=(${nextPos.x},${nextPos.y}) playerPos=(${_world.player.pos.x},${_world.player.pos.y})',
    );
    return true;
  }

  bool _runScenarioFaceCharacter({
    required String entityId,
    required String direction,
  }) {
    final facing = _parseEntityFacing(direction);
    if (facing == null) {
      debugPrint(
        '[scenario_runtime] faceCharacter invalid direction="$direction"',
      );
      return false;
    }
    if (entityId == 'player') {
      final next =
          _world.player.copyWith(facing: _directionFromEntityFacing(facing));
      _world = _world.withPlayer(next);
      _syncGameStateFromWorld();
      _player.syncState(_world.player, snapToGrid: true);
      return true;
    }
    final normalizedEntityId = entityId.trim();
    final active = _loadedMapsById[_activeMapId];
    final actor = active?.npcActorByEntityId[normalizedEntityId];
    if (actor != null) {
      final movement = scriptedNpcMovementStatus(normalizedEntityId);
      if (movement.state == ScriptedEntityMovementState.moving ||
          actor.isStepping) {
        debugPrint(
          '[scenario_runtime] faceCharacter deferred entity=$normalizedEntityId while moving',
        );
        return true;
      }
      actor.setMotion(facing, CharacterAnimationState.idle);
      return true;
    }

    // Tolérance runtime: si l’entité n’a pas d’acteur visuel actuellement
    // monté (ex: map context différente), on tente au moins de persister
    // l’orientation dans l’état map; sinon on ignore sans bloquer le flow.
    if (_setEntityFacingStateOnly(normalizedEntityId, facing)) {
      debugPrint(
        '[scenario_runtime] faceCharacter applied state-only entity="$normalizedEntityId"',
      );
      return true;
    }
    debugPrint(
      '[scenario_runtime] faceCharacter entity unresolved="$normalizedEntityId" (ignored)',
    );
    return true;
  }

  bool _setEntityFacingStateOnly(String entityId, EntityFacing facing) {
    if (entityId.isEmpty) {
      return false;
    }
    final entities = _world.map.entities;
    final index = entities.indexWhere((entity) => entity.id == entityId);
    if (index < 0) {
      return false;
    }
    final entity = entities[index];
    final npc = entity.npc;
    if (npc == null) {
      return false;
    }
    final updatedEntities = List<MapEntity>.from(entities);
    updatedEntities[index] = entity.copyWith(
      npc: npc.copyWith(facing: facing),
    );
    final updatedMap = _world.map.copyWith(entities: updatedEntities);
    final playerState = _world.player;
    _world = GameplayWorldState.initial(
      map: updatedMap,
      playerPos: playerState.pos,
      playerFacing: playerState.facing,
      playerMovementMode: playerState.movementMode,
      project: _bundle.manifest,
      tileWidth: _bundle.manifest.settings.tileWidth,
      tileHeight: _bundle.manifest.settings.tileHeight,
      npcMapPresencePredicate: _npcPresencePredicateFor(_bundle.manifest),
    );
    _bundle = RuntimeMapBundle(
      manifest: _bundle.manifest,
      map: updatedMap,
      projectRootDirectory: _bundle.projectRootDirectory,
      tilesetAbsolutePathsById: _bundle.tilesetAbsolutePathsById,
    );
    _syncGameStateFromWorld();
    return true;
  }

  EntityFacing? _parseEntityFacing(String raw) {
    switch (raw.trim().toLowerCase()) {
      case 'north':
        return EntityFacing.north;
      case 'south':
        return EntityFacing.south;
      case 'east':
        return EntityFacing.east;
      case 'west':
        return EntityFacing.west;
      default:
        return null;
    }
  }

  Direction _directionFromEntityFacing(EntityFacing facing) {
    switch (facing) {
      case EntityFacing.north:
        return Direction.north;
      case EntityFacing.south:
        return Direction.south;
      case EntityFacing.east:
        return Direction.east;
      case EntityFacing.west:
        return Direction.west;
    }
  }

  GridPos? _resolveScenarioLeaderPosition(String leaderEntityId) {
    final movementStatus = scriptedNpcMovementStatus(leaderEntityId);
    if (movementStatus.entityId == leaderEntityId) {
      return movementStatus.currentPos;
    }
    final active = _loadedMapsById[_activeMapId];
    final actor = active?.npcActorByEntityId[leaderEntityId];
    final actorGridPos = actor?.gridPos;
    if (actorGridPos != null) {
      return actorGridPos;
    }
    for (final entity in _world.map.entities) {
      if (entity.id == leaderEntityId) {
        return entity.pos;
      }
    }
    return null;
  }

  _FollowPathPlan? _resolveFollowPathPlanNearLeader({
    required String leaderEntityId,
    required GridPos leaderPos,
    required Direction? preferredSide,
    required bool strictPreferredSide,
  }) {
    final currentPlayerPos = _world.player.pos;
    final leaderRect = _resolveScenarioLeaderCollisionFootprint(
      leaderEntityId: leaderEntityId,
      fallbackAnchor: leaderPos,
    );
    final candidates = <GridPos>[];
    final preferredCandidates = <GridPos>{};
    if (preferredSide != null) {
      final trailing = _cellsAlongRectSide(leaderRect, preferredSide).toList();
      candidates.addAll(trailing);
      preferredCandidates.addAll(trailing);
    }
    if (!strictPreferredSide) {
      candidates.addAll(_adjacentCellsAroundRect(leaderRect));
    }
    final deduplicated = candidates.toSet().toList(growable: false);
    deduplicated.sort((a, b) {
      final aPreferred = preferredCandidates.contains(a) ? 0 : 1;
      final bPreferred = preferredCandidates.contains(b) ? 0 : 1;
      if (aPreferred != bPreferred) {
        return aPreferred.compareTo(bPreferred);
      }
      final da =
          (a.x - currentPlayerPos.x).abs() + (a.y - currentPlayerPos.y).abs();
      final db =
          (b.x - currentPlayerPos.x).abs() + (b.y - currentPlayerPos.y).abs();
      return da.compareTo(db);
    });
    for (final candidate in deduplicated) {
      if (!_canPlacePlayerAt(candidate)) {
        continue;
      }
      final path = _computeFollowPlayerPath(
        start: currentPlayerPos,
        goal: candidate,
      );
      if (path == null) {
        continue;
      }
      return _FollowPathPlan(
        destination: candidate,
        path: path,
      );
    }

    // Si la cible "derrière" est impossible en déplacement, on autorise un
    // fallback adjacent pour éviter les blocages durs dans les couloirs.
    if (strictPreferredSide) {
      final relaxedCandidates =
          _adjacentCellsAroundRect(leaderRect).toSet().toList(growable: false);
      relaxedCandidates.sort((a, b) {
        final da =
            (a.x - currentPlayerPos.x).abs() + (a.y - currentPlayerPos.y).abs();
        final db =
            (b.x - currentPlayerPos.x).abs() + (b.y - currentPlayerPos.y).abs();
        return da.compareTo(db);
      });
      for (final candidate in relaxedCandidates) {
        if (!_canPlacePlayerAt(candidate)) {
          continue;
        }
        final path = _computeFollowPlayerPath(
          start: currentPlayerPos,
          goal: candidate,
        );
        if (path == null) {
          continue;
        }
        return _FollowPathPlan(
          destination: candidate,
          path: path,
        );
      }
    }

    if (_isPosAdjacentToRect(currentPlayerPos, leaderRect) &&
        _canPlacePlayerAt(currentPlayerPos)) {
      return _FollowPathPlan(
        destination: currentPlayerPos,
        path: <GridPos>[currentPlayerPos],
      );
    }
    return null;
  }

  List<GridPos>? _computeFollowPlayerPath({
    required GridPos start,
    required GridPos goal,
  }) {
    final result = _followPathfinder.findPath(
      bounds: _world.map.size,
      start: start,
      goal: goal,
      isPassable: (x, y) {
        if (x == start.x && y == start.y) {
          return true;
        }
        final cell = GridPos(x: x, y: y);
        if (!_isWithinMapBounds(_world.map, cell)) {
          return false;
        }
        if (_isCellReservedByScriptedNpc(cell)) {
          return false;
        }
        final trial = _world.withPlayer(_world.player.copyWith(pos: cell));
        return !trial.isBlocked(x, y);
      },
    );
    if (!result.foundPath) {
      return null;
    }
    return result.path;
  }

  Direction? _directionBetweenAdjacent({
    required GridPos from,
    required GridPos to,
  }) {
    final dx = to.x - from.x;
    final dy = to.y - from.y;
    if (dx == 0 && dy == -1) return Direction.north;
    if (dx == 0 && dy == 1) return Direction.south;
    if (dx == 1 && dy == 0) return Direction.east;
    if (dx == -1 && dy == 0) return Direction.west;
    return null;
  }

  GridPos? _nextFollowPathStep({
    required List<GridPos> path,
    required GridPos currentPos,
  }) {
    if (path.length < 2) {
      return null;
    }
    final currentIndex = path.indexWhere(
      (cell) => cell.x == currentPos.x && cell.y == currentPos.y,
    );
    if (currentIndex < 0 || currentIndex + 1 >= path.length) {
      return null;
    }
    return path[currentIndex + 1];
  }

  void _clearPendingFollowPathCache(_PendingScenarioFollowRequest pending) {
    pending.cachedPath = null;
    pending.cachedPathDestination = null;
    pending.cachedPathLeaderPos = null;
  }

  MapRect _resolveScenarioLeaderCollisionFootprint({
    required String leaderEntityId,
    required GridPos fallbackAnchor,
  }) {
    for (final entity in _world.map.entities) {
      if (entity.id == leaderEntityId) {
        final footprint = resolveEntityCollisionFootprint(entity);
        final offsetX = footprint.pos.x - entity.pos.x;
        final offsetY = footprint.pos.y - entity.pos.y;
        return MapRect(
          pos: GridPos(
            x: fallbackAnchor.x + offsetX,
            y: fallbackAnchor.y + offsetY,
          ),
          size: footprint.size,
        );
      }
    }
    return MapRect(
      pos: fallbackAnchor,
      size: const GridSize(width: 1, height: 1),
    );
  }

  Iterable<GridPos> _adjacentCellsAroundRect(MapRect rect) sync* {
    final left = rect.pos.x;
    final top = rect.pos.y;
    final right = left + rect.size.width - 1;
    final bottom = top + rect.size.height - 1;
    final yielded = <GridPos>{};

    for (var x = left; x <= right; x++) {
      final north = GridPos(x: x, y: top - 1);
      if (yielded.add(north)) {
        yield north;
      }
      final south = GridPos(x: x, y: bottom + 1);
      if (yielded.add(south)) {
        yield south;
      }
    }
    for (var y = top; y <= bottom; y++) {
      final west = GridPos(x: left - 1, y: y);
      if (yielded.add(west)) {
        yield west;
      }
      final east = GridPos(x: right + 1, y: y);
      if (yielded.add(east)) {
        yield east;
      }
    }
  }

  Iterable<GridPos> _cellsAlongRectSide(MapRect rect, Direction side) sync* {
    final left = rect.pos.x;
    final top = rect.pos.y;
    final right = left + rect.size.width - 1;
    final bottom = top + rect.size.height - 1;
    switch (side) {
      case Direction.north:
        for (var x = left; x <= right; x++) {
          yield GridPos(x: x, y: top - 1);
        }
      case Direction.south:
        for (var x = left; x <= right; x++) {
          yield GridPos(x: x, y: bottom + 1);
        }
      case Direction.east:
        for (var y = top; y <= bottom; y++) {
          yield GridPos(x: right + 1, y: y);
        }
      case Direction.west:
        for (var y = top; y <= bottom; y++) {
          yield GridPos(x: left - 1, y: y);
        }
    }
  }

  Direction? _resolveLeaderTravelDirection({
    required _PendingScenarioFollowRequest pending,
    required GridPos leaderPos,
    required ScriptedEntityMovementStatus movementStatus,
  }) {
    final previous = pending.lastLeaderPos;
    pending.lastLeaderPos = leaderPos;
    if (previous != null) {
      final dx = leaderPos.x - previous.x;
      final dy = leaderPos.y - previous.y;
      final fromDelta = _directionFromDelta(dx, dy);
      if (fromDelta != null) {
        pending.lastLeaderTravelDirection = fromDelta;
        return fromDelta;
      }
    }
    if (movementStatus.state == ScriptedEntityMovementState.moving &&
        movementStatus.targetPos != null) {
      final target = movementStatus.targetPos!;
      final dx = target.x - leaderPos.x;
      final dy = target.y - leaderPos.y;
      final fromTargetVector = _directionFromDelta(dx, dy);
      if (fromTargetVector != null) {
        pending.lastLeaderTravelDirection = fromTargetVector;
        return fromTargetVector;
      }
    }
    return pending.lastLeaderTravelDirection;
  }

  Direction? _directionFromDelta(int dx, int dy) {
    if (dx == 0 && dy == 0) {
      return null;
    }
    if (dx.abs() >= dy.abs()) {
      return dx >= 0 ? Direction.east : Direction.west;
    }
    return dy >= 0 ? Direction.south : Direction.north;
  }

  Direction _oppositeDirection(Direction direction) {
    switch (direction) {
      case Direction.north:
        return Direction.south;
      case Direction.south:
        return Direction.north;
      case Direction.east:
        return Direction.west;
      case Direction.west:
        return Direction.east;
    }
  }

  bool _isPosAdjacentToRect(GridPos pos, MapRect rect) {
    final left = rect.pos.x;
    final top = rect.pos.y;
    final right = left + rect.size.width - 1;
    final bottom = top + rect.size.height - 1;
    final isInside =
        pos.x >= left && pos.x <= right && pos.y >= top && pos.y <= bottom;
    if (isInside) {
      return false;
    }
    final dx =
        pos.x < left ? left - pos.x : (pos.x > right ? pos.x - right : 0);
    final dy =
        pos.y < top ? top - pos.y : (pos.y > bottom ? pos.y - bottom : 0);
    return math.max(dx, dy) == 1;
  }

  bool _canPlacePlayerAt(GridPos pos) {
    if (!_isWithinMapBounds(_world.map, pos)) {
      return false;
    }
    final trial = _world.withPlayer(_world.player.copyWith(pos: pos));
    return !trial.isBlocked(pos.x, pos.y);
  }

  /// Lance un script projet à partir d'un `scriptId`.
  ///
  /// Callback utilisé par le bridge scénario.
  bool _runScenarioScriptById(
    String scriptId, {
    String? startNode,
    String? runtimeSourceId,
  }) {
    final normalizedScriptId = scriptId.trim();
    if (normalizedScriptId.isEmpty) {
      return false;
    }
    if (_activeScriptController != null &&
        !_activeScriptController!.isTerminated) {
      return false;
    }
    ScriptAsset? scriptAsset;
    for (final entry in _bundle.manifest.scripts) {
      if (entry.id == normalizedScriptId) {
        scriptAsset = entry.asset;
        break;
      }
    }
    if (scriptAsset == null) {
      debugPrint('[scenario_runtime] script not found: $normalizedScriptId');
      return false;
    }
    _startScriptExecution(
      script: scriptAsset,
      startNodeId: startNode,
      runtimeSourceId: runtimeSourceId ?? 'scenario',
    );
    return true;
  }

  void _logEncounterCheck(GameplayEncounterCheckResult check) {
    final kind = check.encounterKind?.name ?? EncounterKind.walk.name;
    switch (check.status) {
      case GameplayEncounterCheckStatus.noZone:
        debugPrint('[encounter] no compatible zone');
        return;
      case GameplayEncounterCheckStatus.noEncounterTableId:
        debugPrint(
          '[encounter] zone=${check.zoneId ?? 'unknown'} has no encounter table id (kind=$kind)',
        );
        return;
      case GameplayEncounterCheckStatus.encounterTableNotFound:
        debugPrint(
          '[encounter] zone=${check.zoneId ?? 'unknown'} table=${check.tableId ?? 'unknown'} not found',
        );
        return;
      case GameplayEncounterCheckStatus.encounterKindMismatch:
        debugPrint(
          '[encounter] zone=${check.zoneId ?? 'unknown'} table=${check.tableId ?? 'unknown'} kind mismatch (expected=$kind)',
        );
        return;
      case GameplayEncounterCheckStatus.emptyEncounterTable:
        debugPrint(
          '[encounter] zone=${check.zoneId ?? 'unknown'} table=${check.tableId ?? 'unknown'} has no valid entries',
        );
        return;
      case GameplayEncounterCheckStatus.rollFailed:
        debugPrint(
          '[encounter] matched zone=${check.zoneId ?? 'unknown'} table=${check.tableId ?? 'unknown'}',
        );
        debugPrint(
          '[encounter] rolled no encounter roll=${check.roll?.toStringAsFixed(3) ?? 'n/a'}',
        );
        return;
      case GameplayEncounterCheckStatus.triggered:
        final encounter = check.encounter;
        if (encounter == null) {
          debugPrint('[encounter] triggered status without payload');
          return;
        }
        debugPrint(
          '[encounter] matched zone=${encounter.zoneId} table=${encounter.tableId}',
        );
        debugPrint(
          '[encounter] triggered species=${encounter.speciesId} level=${encounter.level} kind=${encounter.encounterKind.name}',
        );
        return;
    }
  }

  /// Démarre le handoff de combat.
  ///
  /// [request] - La requête de combat (wild ou trainer).
  ///
  /// Cette méthode :
  /// 1. Stocke la requête pour le mapping vers BattleSetup
  /// 2. Passe en phase battleTransition
  /// 3. Affiche l'overlay de transition
  void _startBattleHandoff(BattleStartRequest request) {
    if (_flowPhase != _RuntimeFlowPhase.overworld) {
      return;
    }
    _flowPhase = _RuntimeFlowPhase.battleTransition;
    _notification?.removeFromParent();
    _notification = null;
    _battleTransitionOverlay?.removeFromParent();
    _battleTransitionOverlay = null;
    _battleOverlay?.removeFromParent();
    _battleOverlay = null;
    debugPrint(
      '[battle] transition started requestId=${request.requestId} kind=${request.kind.name}',
    );
    final overlay = BattleTransitionOverlayComponent(
      request: request,
      viewportSize: camera.viewport.size,
      onFinished: () {
        // Le mapping vers BattleSetup peut maintenant lire le vrai projet et
        // échouer explicitement. On déclenche donc l'ouverture de manière async
        // au lieu de supposer qu'un setup placeholder sera toujours disponible.
        unawaited(_openBattleOverlay(request));
      },
    );
    camera.viewport.add(overlay);
    _battleTransitionOverlay = overlay;
  }

  /// Ouvre l'overlay de combat après la transition.
  ///
  /// [request] - La requête de combat.
  ///
  /// Cette méthode :
  /// 1. Mappe BattleStartRequest → BattleSetup
  /// 2. Crée la BattleSession
  /// 3. Affiche BattleOverlayComponent avec la session
  Future<void> _openBattleOverlay(BattleStartRequest request) async {
    if (_flowPhase != _RuntimeFlowPhase.battleTransition) {
      return;
    }
    _battleTransitionOverlay?.removeFromParent();
    _battleTransitionOverlay = null;
    try {
      // Le lot 10 introduit un invariant critique : on mémorise le slot exact
      // de party utilisé pour le handoff avant d'ouvrir le combat.
      //
      // Pourquoi ici :
      // - la sélection se fait sur le vrai GameState runtime, juste avant le
      //   mapping vers BattleSetup ;
      // - on réutilise ensuite ce même index au moment du write-back ;
      // - on évite ainsi le bug classique "recalculer le premier Pokémon
      //   jouable après le combat", qui casserait la cohérence si le
      //   combattant actif finit K.O.
      final playerPartyIndex =
          _battleSetupMapper.selectUsablePartyMemberIndex(_gameState.party);

      // Le lot 9 remplace enfin le setup placeholder par un mapping réel
      // depuis la save runtime et les données projet.
      final setup = await _toBattleSetup(
        request,
        playerPartyIndex: playerPartyIndex,
      );

      // Lot 12 pose le premier write runtime honnête du "seen" :
      // l'espèce ennemie n'est marquée vue qu'une fois le handoff réellement
      // résolu et le combat effectivement prêt à s'ouvrir.
      //
      // On évite volontairement de marquer plus tôt :
      // - une simple case d'herbe ne suffit pas ;
      // - un setup qui échoue ne doit rien écrire ;
      // - aucune capture n'est ouverte ici.
      _gameState = markSpeciesSeenInGameState(
        _gameState,
        setup.enemyPokemon.speciesId,
      );
      _flowPhase = _RuntimeFlowPhase.battle;

      // Créer la session de combat
      _battleSession = createBattleSession(setup);
      _activeBattleContext = RuntimeActiveBattleContext(
        request: request,
        playerPartyIndex: playerPartyIndex,
      );

      // Afficher l'overlay de combat avec la session
      final overlay = BattleOverlayComponent(
        session: _battleSession!,
        viewportSize: camera.viewport.size,
        onPlayerChoice: _onPlayerBattleChoice,
      );
      camera.viewport.add(overlay);
      _battleOverlay = overlay;
      debugPrint(
        '[battle] overlay opened requestId=${request.requestId} kind=${request.kind.name}',
      );
    } on RuntimeBattleSetupException catch (error) {
      _cancelBattleHandoff(
        userMessage: error.message,
        debugDetails: error.debugDetails,
      );
    } catch (error, stackTrace) {
      _cancelBattleHandoff(
        userMessage:
            'Impossible de démarrer le combat avec les données locales du projet.',
        debugDetails: '$error\n$stackTrace',
      );
    }
  }

  /// Mappe BattleStartRequest → BattleSetup.
  ///
  /// [request] - La requête de combat depuis le runtime.
  ///
  /// Retourne un BattleSetup pur pour le moteur de combat.
  Future<BattleSetup> _toBattleSetup(
    BattleStartRequest request, {
    int? playerPartyIndex,
  }) {
    return _battleSetupMapper.map(
      bundle: _bundle,
      gameState: _gameState,
      request: request,
      playerPartyIndex: playerPartyIndex,
    );
  }

  void _cancelBattleHandoff({
    required String userMessage,
    String? debugDetails,
  }) {
    // On nettoie explicitement tout état battle partiellement initialisé.
    // Ce helper évite qu'un mapping KO laisse le runtime coincé en transition.
    _battleOverlay?.removeFromParent();
    _battleOverlay = null;
    _battleTransitionOverlay?.removeFromParent();
    _battleTransitionOverlay = null;
    _battleSession = null;
    _activeBattleContext = null;
    _isBattleResolving = false;
    _flowPhase = _RuntimeFlowPhase.overworld;
    _pressedKeys.clear();
    _lastMoveKey = null;
    debugPrint(
      '[battle] handoff cancelled message="$userMessage" details=${debugDetails ?? 'n/a'}',
    );
    _showNotification(userMessage);
  }

  /// Gère le choix du joueur pendant le combat.
  ///
  /// [choice] - Le choix fait par le joueur.
  ///
  /// Cette méthode :
  /// 1. Applique le choix via BattleSession.applyChoice()
  /// 2. Met à jour l'UI
  /// 3. Vérifie si le combat est fini
  /// 4. Si fini, appelle _onBattleFinished()
  ///
  /// **Lock anti-spam** : `_isBattleResolving` empêche le spam clavier
  /// pendant la résolution d'un tour.
  void _onPlayerBattleChoice(PlayerBattleChoice choice) {
    if (_battleSession == null) {
      return;
    }

    // Lock anti-spam : empêcher traitement multiple pendant résolution
    if (_isBattleResolving) {
      debugPrint('[battle] choice ignored: already resolving');
      return;
    }
    _isBattleResolving = true;

    try {
      // Appliquer le choix (retourne une nouvelle session immutable)
      _battleSession = _battleSession!.applyChoice(choice);

      // Mettre à jour l'UI avec le nouvel état
      final overlay = _battleOverlay;
      overlay?.updateState(_battleSession!);

      // Vérifier si le combat est fini
      if (_battleSession!.state.isFinished) {
        _onBattleFinished(_battleSession!.state.outcome!);
      }
    } finally {
      // Unlock après résolution (ou après fin de combat)
      // Si combat fini, _onBattleFinished() va reset l'état de toute façon
      if (_flowPhase == _RuntimeFlowPhase.battle) {
        _isBattleResolving = false;
      }
    }
  }

  /// Gère la fin du combat.
  ///
  /// [outcome] - Le résultat du combat.
  ///
  /// Cette méthode :
  /// 1. Applique le résultat au vrai GameState runtime
  /// 2. Nettoie l'overlay (SUPPRIME du parent)
  /// 3. Retourne à l'overworld
  void _onBattleFinished(BattleOutcome outcome) {
    debugPrint('[battle] battle finished outcome=${outcome.type.name}');

    // Le lot 10 normalise ici tout le write-back post-combat :
    // - PV du Pokémon joueur écrits sur le slot exact mémorisé ;
    // - flag trainer_defeated uniquement sur une vraie victoire trainer ;
    // - aucune tentative de recalcul du Pokémon actif après la fin du combat.
    final activeBattleContext = _activeBattleContext;
    if (activeBattleContext != null) {
      final previousState = _gameState;
      _gameState = applyRuntimeBattleOutcomeToGameState(
        gameState: _gameState,
        context: activeBattleContext,
        outcome: outcome,
        storyFlagsManager: _storyFlags,
      );

      if (outcome.isVictory &&
          activeBattleContext.request is TrainerBattleStartRequest) {
        final trainerRequest =
            activeBattleContext.request as TrainerBattleStartRequest;
        debugPrint(
          '[battle] trainer marked as defeated: ${trainerRequest.trainerId}',
        );
      }

      // On ne refresh la présence PNJ que si les story flags ont réellement
      // changé ; cela garde le retour overworld minimal pour wild/defeat/run.
      if (!identical(previousState.storyFlags, _gameState.storyFlags) &&
          previousState.storyFlags != _gameState.storyFlags) {
        _refreshWorldNpcPresence();
      }
    }

    // Nettoyer et retourner à l'overworld
    // IMPORTANT: Il faut SUPPRIMER l'overlay du parent, pas juste mettre à null
    _battleOverlay?.removeFromParent();
    _battleOverlay = null;
    _battleTransitionOverlay?.removeFromParent();
    _battleTransitionOverlay = null;
    _battleSession = null;
    _activeBattleContext = null;
    _isBattleResolving = false; // Reset lock anti-spam

    // NOTE: NE PAS clear _triggeredTrainerBattles ici!
    // Le lock doit rester actif tant que le joueur est dans la LoS du trainer.
    // Si on clear le lock ici, le trainer sera re-déclenché immédiatement
    // car le joueur est probablement encore dans sa zone de LoS.
    //
    // Le lock sera clear automatiquement quand le joueur quittera la LoS,
    // via le mécanisme de réarmement dans _checkTrainerLineOfSight():
    //   if (_triggeredTrainerBattles.contains(entity.id)) {
    //     if (!inLoS) _triggeredTrainerBattles.remove(entity.id);
    //   }
    //
    // Et même si le lock est encore actif, le trainer ne sera pas re-déclenché
    // car il est marqué defeated dans storyFlags (guard dans _checkTrainerLineOfSight).

    _flowPhase = _RuntimeFlowPhase.overworld;
    _pressedKeys.clear();
    _lastMoveKey = null;
    debugPrint('[battle] overworld resumed');
  }

  void _handleInteract() {
    final result = stepGameplayWorld(_world, const InteractIntent());
    _world = result.world;
    _consumePathAnimationSignals(result.pathAnimationSignals);
    var scenarioHandledEntityInteraction = false;

    switch (result) {
      case NothingToInteract():
        if (result.pathAnimationSignals.isNotEmpty) {
          debugPrint('[interact] Path animation trigger');
          return;
        }
        debugPrint('[interact] Nothing to interact with');
        _showNotification('...');
      case NpcInteracted(:final entity):
        debugPrint('[interact] NPC: ${entity.id}');
        _faceNpcTowardPlayer(entity.id);
        scenarioHandledEntityInteraction =
            _tryDispatchScenarioEntityInteraction(
          entity.id,
        );
        if (!scenarioHandledEntityInteraction) {
          _handleNpcInteraction(entity);
        }
      case SignInteracted(:final entity):
        debugPrint('[interact] Sign: ${entity.id}');
        scenarioHandledEntityInteraction =
            _tryDispatchScenarioEntityInteraction(
          entity.id,
        );
        if (!scenarioHandledEntityInteraction) {
          _tryOpenDialogue(
              entity.id, entity.sign?.dialogue, entity.inspectorHeadline);
        }
      case ItemInteracted(:final entity):
        debugPrint('[interact] Item: ${entity.id}');
        _showNotification(entity.inspectorHeadline);
      case EntityInteracted(:final entity):
        debugPrint('[interact] Entity: ${entity.id}');
        scenarioHandledEntityInteraction =
            _tryDispatchScenarioEntityInteraction(
          entity.id,
        );
        if (!scenarioHandledEntityInteraction) {
          _showNotification(entity.inspectorHeadline);
        }
      case PlacedElementInteracted(
          :final element,
          :final behavior,
          :final trigger,
        ):
        debugPrint('[interact] PlacedElement: ${element.id}');
        _executePlacedElementBehavior(
          element: element,
          behavior: behavior,
          trigger: trigger,
        );
      default:
        break;
    }

    if (result is NothingToInteract ||
        (result is EntityInteracted && !scenarioHandledEntityInteraction)) {
      _tryInteractWithMapEvent();
    }
  }

  bool _tryDispatchScenarioEntityInteraction(String entityId) {
    final result = _dispatchScenarioRuntimeSource(
      ScenarioRuntimeSourceEvent.entityInteract(
        mapId: _activeMapId,
        entityId: entityId,
      ),
    );
    return result.handled;
  }

  void _tryInteractWithMapEvent() {
    if (_activeScriptController != null &&
        !_activeScriptController!.isTerminated) {
      debugPrint('[interact] blocked: script is active');
      return;
    }

    if (_flowPhase != _RuntimeFlowPhase.overworld) {
      debugPrint('[interact] blocked: flow phase is $_flowPhase');
      return;
    }

    final facing = _world.player.facing;
    final tx = _world.player.pos.x + facing.dx;
    final ty = _world.player.pos.y + facing.dy;

    final map = _bundle.map;
    MapEventDefinition? event;
    for (final e in map.events) {
      if (e.position.x == tx && e.position.y == ty) {
        event = e;
        break;
      }
    }

    if (event == null) return;

    final activePage = _storyBranching.resolveEventPage(event, _gameState);

    if (activePage == null) return;

    if (activePage.page.isDisabled) return;

    debugPrint('[interact] MapEvent: ${event.id} page=${activePage.pageIndex}');
    _handleMapEventInteraction(event, activePage);
  }

  void _handleMapEventInteraction(
    MapEventDefinition event,
    ActiveEventPage page,
  ) {
    if (page.page.script != null) {
      final message = page.page.message?.trim();
      if (message != null && message.isNotEmpty) {
        _showNotification(message);
      }
      _executeEventScript(event, page, page.page.script!);
    } else if (page.page.message != null && page.page.message!.isNotEmpty) {
      _showNotification(page.page.message!);
    } else {
      _showNotification('...');
    }
  }

  void _executeEventScript(
    MapEventDefinition event,
    ActiveEventPage page,
    ScriptRef scriptRef,
  ) {
    final scriptAsset = _bundle.manifest.scripts
        .firstWhere(
          (s) => s.id == scriptRef.scriptId,
          orElse: () =>
              throw StateError('Script not found: ${scriptRef.scriptId}'),
        )
        .asset;
    _startScriptExecution(
      script: scriptAsset,
      startNodeId: scriptRef.startNode,
      runtimeSourceId: event.id,
    );
  }

  /// Démarrage générique d'exécution script.
  ///
  /// Cette méthode factorise le chemin script:
  /// - scripts de pages d'event map,
  /// - scripts déclenchés par le Scenario Runtime Bridge.
  void _startScriptExecution({
    required ScriptAsset script,
    String? startNodeId,
    required String runtimeSourceId,
  }) {
    final context = ScriptExecutionContext(
      gameState: _gameState,
      onGameStateUpdated: (state) {
        _gameState = state;
        _refreshWorldNpcPresence();
      },
      onDialogueOpened: (dialogue) {
        _openDialogueForScriptSource(runtimeSourceId, dialogue);
      },
      onWarpRequested: (mapId, x, y) {
        _pendingWarp = TriggeredWarp(
          warpId: 'script_warp',
          targetMapId: mapId,
          targetPos: GridPos(x: x, y: y),
          triggerMode: MapWarpTriggerMode.onEnter,
        );
      },
    );

    _activeScriptController = ScriptRuntimeController(
      script: script,
      context: context,
      startNodeId: startNodeId,
    );
    _isAwaitingScriptResume = false;
    _runScriptStep();
  }

  void _runScriptStep() {
    final controller = _activeScriptController;
    if (controller == null) {
      return;
    }

    if (controller.isTerminated) {
      _activeScriptController = null;
      _isAwaitingScriptResume = false;
      return;
    }

    if (controller.isSuspended) {
      _isAwaitingScriptResume = true;
      return;
    }

    final result = controller.step();

    if (result is ScriptCommandResultSuspended) {
      _isAwaitingScriptResume = true;
      if (result.reason == ScriptSuspendReason.waitingForDialogue) {
        _flowPhase = _RuntimeFlowPhase.dialogue;
      }
      return;
    }

    _runScriptStep();
  }

  void _openDialogueForScriptSource(
      String runtimeSourceId, YarnDialogueRef dialogueRef) {
    final resolved = resolveDialogue(
      entityId: runtimeSourceId,
      ref: DialogueRef(
        dialogueId: '',
        scriptPathRelative: dialogueRef.filePath,
        startNode: dialogueRef.startNode,
      ),
      projectRootDirectory: _bundle.projectRootDirectory,
      dialogues: _bundle.manifest.dialogues,
    );

    if (resolved == null) {
      debugPrint(
          '[script] failed to resolve dialogue: ${dialogueRef.filePath}');
      _runScriptStep();
      return;
    }

    loadDialogueContent(resolved).then((session) {
      if (session == null) {
        debugPrint('[script] failed to load dialogue');
        _runScriptStep();
        return;
      }

      _pendingPostDialogueAction = () {
        _flowPhase = _RuntimeFlowPhase.overworld;
        if (_isAwaitingScriptResume) {
          _isAwaitingScriptResume = false;
          _runScriptStep();
        }
      };

      _openDialogue(session);
    });
  }

  void _consumePathAnimationSignals(List<PathAnimationSignal> signals) {
    if (signals.isEmpty) {
      return;
    }
    final active = _loadedMapsById[_activeMapId];
    if (active == null) {
      return;
    }
    for (final signal in signals) {
      switch (signal.kind) {
        case PathAnimationSignalKind.trigger:
          final backgroundApplied =
              active.backgroundLayers.triggerPathAnimationRule(
            layerId: signal.layerId,
            ruleId: signal.ruleId,
            mode: signal.mode,
            scope: signal.scope,
            cellX: signal.sourcePos.x,
            cellY: signal.sourcePos.y,
          );
          final foregroundApplied =
              active.foregroundLayers.triggerPathAnimationRule(
            layerId: signal.layerId,
            ruleId: signal.ruleId,
            mode: signal.mode,
            scope: signal.scope,
            cellX: signal.sourcePos.x,
            cellY: signal.sourcePos.y,
          );
          if (!backgroundApplied && !foregroundApplied) {
            debugPrint(
              '[path_anim] trigger ignored layer=${signal.layerId} preset=${signal.presetId} rule=${signal.ruleId} trigger=${signal.trigger.name} mode=${signal.mode.name} source=(${signal.sourcePos.x}, ${signal.sourcePos.y})',
            );
            continue;
          }
          debugPrint(
            '[path_anim] trigger layer=${signal.layerId} preset=${signal.presetId} rule=${signal.ruleId} trigger=${signal.trigger.name} mode=${signal.mode.name} source=(${signal.sourcePos.x}, ${signal.sourcePos.y})',
          );
        case PathAnimationSignalKind.setActive:
          final activeValue = signal.active ?? false;
          final backgroundApplied =
              active.backgroundLayers.setPathAnimationRuleActive(
            layerId: signal.layerId,
            ruleId: signal.ruleId,
            active: activeValue,
            scope: signal.scope,
            cellX: signal.sourcePos.x,
            cellY: signal.sourcePos.y,
          );
          final foregroundApplied =
              active.foregroundLayers.setPathAnimationRuleActive(
            layerId: signal.layerId,
            ruleId: signal.ruleId,
            active: activeValue,
            scope: signal.scope,
            cellX: signal.sourcePos.x,
            cellY: signal.sourcePos.y,
          );
          if (!backgroundApplied && !foregroundApplied) {
            debugPrint(
              '[path_anim] active ignored layer=${signal.layerId} preset=${signal.presetId} rule=${signal.ruleId} trigger=${signal.trigger.name} active=$activeValue source=(${signal.sourcePos.x}, ${signal.sourcePos.y})',
            );
            continue;
          }
          debugPrint(
            '[path_anim] active layer=${signal.layerId} preset=${signal.presetId} rule=${signal.ruleId} trigger=${signal.trigger.name} active=$activeValue source=(${signal.sourcePos.x}, ${signal.sourcePos.y})',
          );
      }
    }
  }

  void _executePlacedElementBehavior({
    required MapPlacedElement element,
    required MapPlacedElementBehavior behavior,
    required MapPlacedElementTriggerType trigger,
  }) {
    if (!behavior.enabled) {
      return;
    }
    final effect = behavior.effect;
    final cooldownKey = _buildPlacedBehaviorCooldownKey(
      element: element,
      behavior: behavior,
      trigger: trigger,
    );
    final cooldownOverride = _resolvePlacedBehaviorCooldownOverride(behavior);
    if (!_placedBehaviorCooldownGate.canTrigger(
      key: cooldownKey,
      nowMs: _runtimeClockMs,
    )) {
      final remainingMs = _placedBehaviorCooldownGate.remainingMs(
        key: cooldownKey,
        nowMs: _runtimeClockMs,
      );
      debugPrint(
        '[placed_behavior] cooldown blocked trigger=${trigger.name} scope=${behavior.triggerScope.name} instance=${element.id} behavior=${cooldownKey.behaviorId} effect=${effect.type.name} remainingMs=${remainingMs.toStringAsFixed(0)}',
      );
      _updateBehaviorDebugLine(
        'Cooldown ${effect.type.name} (${remainingMs.toStringAsFixed(0)} ms) · ${element.id}#${cooldownKey.behaviorId} (${behavior.triggerScope.name})',
      );
      return;
    }
    debugPrint(
      '[placed_behavior] trigger=${trigger.name} scope=${behavior.triggerScope.name} instance=${element.id} behavior=${cooldownKey.behaviorId} effect=${effect.type.name}',
    );
    var effectApplied = false;
    switch (effect.type) {
      case MapPlacedElementEffectType.showMessage:
        final text = effect.message?.trim() ?? '';
        if (text.isEmpty) {
          debugPrint(
            '[placed_behavior] showMessage ignored instance=${element.id} behavior=${cooldownKey.behaviorId} reason=empty_message',
          );
          return;
        }
        _showNotification(text);
        effectApplied = true;
        break;
      case MapPlacedElementEffectType.openDialogue:
        effectApplied =
            _tryOpenDialogue(element.id, effect.dialogue, element.elementId);
        break;
      case MapPlacedElementEffectType.setAnimationEnabled:
        final enabled = effect.animationEnabled;
        if (enabled == null) {
          debugPrint(
            '[placed_behavior] setAnimationEnabled ignored instance=${element.id} behavior=${cooldownKey.behaviorId} reason=missing_value',
          );
          return;
        }
        final currentEnabled = _resolvePlacedElementAnimationEnabled(
          element.id,
        );
        if (currentEnabled == enabled) {
          debugPrint(
            '[placed_behavior] setAnimationEnabled ignored instance=${element.id} behavior=${cooldownKey.behaviorId} reason=no_change value=$enabled',
          );
          _updateBehaviorDebugLine(
            'Animation déjà ${enabled ? 'active' : 'inactive'} · ${element.id}#${cooldownKey.behaviorId}',
          );
          return;
        }
        _applyPlacedElementAnimationEnabled(
          instanceId: element.id,
          enabled: enabled,
        );
        effectApplied = true;
        break;
      case MapPlacedElementEffectType.playAnimationOnce:
        final triggered =
            _playPlacedElementAnimationOnce(instanceId: element.id);
        if (!triggered) {
          debugPrint(
            '[placed_behavior] playAnimationOnce ignored instance=${element.id} behavior=${cooldownKey.behaviorId} reason=no_animatable_frames',
          );
          _updateBehaviorDebugLine(
            'Animation 1x indisponible · ${element.id}#${cooldownKey.behaviorId}',
          );
          return;
        } else {
          debugPrint(
            '[placed_behavior] playAnimationOnce started instance=${element.id} behavior=${cooldownKey.behaviorId} strategy=restart',
          );
        }
        effectApplied = true;
        break;
    }
    if (!effectApplied) {
      return;
    }
    _placedBehaviorCooldownGate.markTriggered(
      key: cooldownKey,
      nowMs: _runtimeClockMs,
      overrideDuration: cooldownOverride,
    );
    _updateBehaviorDebugLine(
      'Triggered ${trigger.name}/${behavior.triggerScope.name} -> ${effect.type.name} · ${element.id}#${cooldownKey.behaviorId}',
    );
  }

  bool _playPlacedElementAnimationOnce({
    required String instanceId,
  }) {
    final loaded = _loadedMapsById[_activeMapId];
    if (loaded == null) {
      return false;
    }
    final fromBackground =
        loaded.backgroundLayers.playPlacedElementAnimationOnce(
      instanceId: instanceId,
    );
    final fromForeground =
        loaded.foregroundLayers.playPlacedElementAnimationOnce(
      instanceId: instanceId,
    );
    return fromBackground || fromForeground;
  }

  void _applyPlacedElementAnimationEnabled({
    required String instanceId,
    required bool enabled,
  }) {
    try {
      final updatedMap = setMapPlacedElementAnimationEnabled(
        _world.map,
        instanceId: instanceId,
        enabled: enabled,
      );
      _world = GameplayWorldState.initial(
        map: updatedMap,
        playerPos: _world.player.pos,
        playerFacing: _world.player.facing,
        playerMovementMode: _world.player.movementMode,
        project: _bundle.manifest,
        tileWidth: _bundle.manifest.settings.tileWidth,
        tileHeight: _bundle.manifest.settings.tileHeight,
        npcMapPresencePredicate: _npcPresencePredicateFor(_bundle.manifest),
      );
      _bundle = RuntimeMapBundle(
        manifest: _bundle.manifest,
        map: updatedMap,
        projectRootDirectory: _bundle.projectRootDirectory,
        tilesetAbsolutePathsById: _bundle.tilesetAbsolutePathsById,
      );
      final activeLoaded = _loadedMapsById[_activeMapId];
      if (activeLoaded != null) {
        activeLoaded.backgroundLayers.setPlacedElementAnimationEnabledOverride(
          instanceId: instanceId,
          enabled: enabled,
        );
        activeLoaded.foregroundLayers.setPlacedElementAnimationEnabledOverride(
          instanceId: instanceId,
          enabled: enabled,
        );
        _loadedMapsById[_activeMapId] = _LoadedPlayableMap(
          bundle: _bundle,
          originCellX: activeLoaded.originCellX,
          originCellY: activeLoaded.originCellY,
          backgroundLayers: activeLoaded.backgroundLayers,
          foregroundLayers: activeLoaded.foregroundLayers,
          npcActors: activeLoaded.npcActors,
          npcActorByEntityId: activeLoaded.npcActorByEntityId,
        );
      }
      debugPrint(
        '[placed_behavior] setAnimationEnabled applied instance=$instanceId enabled=$enabled',
      );
    } catch (e, st) {
      debugPrint(
        '[placed_behavior] setAnimationEnabled failed instance=$instanceId enabled=$enabled error=$e\n$st',
      );
      _showNotification('Animation update failed');
    }
  }

  bool _tryOpenDialogue(
      String entityId, DialogueRef? ref, String fallbackLabel) {
    if (_flowPhase != _RuntimeFlowPhase.overworld) return false;
    if (_dialogueOverlay != null) return false;
    if (!_npcEntityAllowedOnActiveMapForDialogue(entityId)) {
      debugPrint('[dialogue] blocked: npc absent entityId=$entityId');
      return false;
    }

    final resolved = resolveDialogue(
      entityId: entityId,
      ref: ref,
      projectRootDirectory: _bundle.projectRootDirectory,
      dialogues: _bundle.manifest.dialogues,
    );

    if (resolved == null) {
      _showNotification(fallbackLabel);
      return false;
    }

    loadDialogueContent(resolved).then((session) {
      if (_dialogueOverlay != null) return;
      if (session == null) {
        debugPrint('[dialogue] failed to load session for entity=$entityId');
        _showNotification(fallbackLabel);
        return;
      }
      debugPrint('[dialogue] opening dialogue for entity=$entityId');
      _openDialogue(session);
    });
    return true;
  }

  void _openDialogue(DialogueSession session) {
    _notification?.removeFromParent();
    _notification = null;
    _pressedKeys.clear();
    _lastMoveKey = null;
    _flowPhase = _RuntimeFlowPhase.dialogue;

    final overlay = DialogueOverlayComponent(
      session: session,
      viewportSize: camera.viewport.size,
      onFinished: () {
        debugPrint('[dialogue] dialogue closed');
        _dialogueOverlay = null;
        _flowPhase = _RuntimeFlowPhase.overworld;
        _awaitingSurfConfirmation = false;
        final action = _pendingPostDialogueAction;
        _pendingPostDialogueAction = null;
        action?.call();
      },
    );
    camera.viewport.add(overlay);
    _dialogueOverlay = overlay;
    final openedState = session.state;
    if (openedState is DialogueShowingLine) {
      debugPrint(
          '[dialogue] opened node=${session.currentNodeTitle} text="${openedState.text}"');
    } else if (openedState is DialogueWaitingForChoice) {
      debugPrint(
          '[dialogue] opened node=${session.currentNodeTitle} choice count=${openedState.choices.length}');
    }
  }

  void _advanceDialogue() {
    final overlay = _dialogueOverlay;
    if (overlay == null) return;
    final prevNode = overlay.currentSession.currentNodeTitle;
    final stillOpen = overlay.advance();
    if (!stillOpen) {
      debugPrint('[dialogue] finished');
      return;
    }
    final newNode = overlay.currentSession.currentNodeTitle;
    if (newNode != null && newNode != prevNode) {
      debugPrint('[dialogue] jump to=$newNode');
    }
    final newState = overlay.currentSession.state;
    if (newState is DialogueShowingLine) {
      debugPrint('[dialogue] line text="${newState.text}"');
    } else if (newState is DialogueWaitingForChoice) {
      debugPrint(
          '[dialogue] choice opened count=${newState.choices.length} selected=0');
    }
  }

  void _moveChoiceCursor(int delta) {
    final overlay = _dialogueOverlay;
    if (overlay == null) return;
    overlay.moveCursor(delta);
    final state = overlay.currentSession.state;
    if (state is DialogueWaitingForChoice) {
      debugPrint('[dialogue] choice moved selected=${state.selectedIndex}');
    }
  }

  void _confirmDialogueChoice() {
    final overlay = _dialogueOverlay;
    if (overlay == null) return;
    final state = overlay.currentSession.state;
    if (state is DialogueWaitingForChoice) {
      final idx = state.selectedIndex;
      debugPrint(
          '[dialogue] choice confirmed index=$idx text="${state.choices[idx].text}"');
      if (_awaitingSurfConfirmation) {
        if (idx == 0) {
          _pendingPostDialogueAction = () {
            setSurfingEnabled(true);
            debugPrint('[surf] mode activated via dialogue choice');
          };
        }
        _awaitingSurfConfirmation = false;
      }
    }
    final prevNode = overlay.currentSession.currentNodeTitle;
    final stillOpen = overlay.confirmChoice();
    if (!stillOpen) {
      debugPrint('[dialogue] finished');
      return;
    }
    final newNode = overlay.currentSession.currentNodeTitle;
    if (newNode != null && newNode != prevNode) {
      debugPrint('[dialogue] jump to=$newNode');
    }
    final newState = overlay.currentSession.state;
    if (newState is DialogueShowingLine) {
      debugPrint('[dialogue] line text="${newState.text}"');
    } else if (newState is DialogueWaitingForChoice) {
      debugPrint(
          '[dialogue] choice opened count=${newState.choices.length} selected=0');
    }
  }

  /// Garde-fou : tout dialogue / combat PNJ passe par ici ou [_tryOpenDialogue].
  bool _npcEntityAllowedOnActiveMapForDialogue(String entityId) {
    final normalized = entityId.trim();
    if (normalized.isEmpty) {
      return true;
    }
    MapEntity? found;
    for (final e in _world.map.entities) {
      if (e.id == normalized) {
        found = e;
        break;
      }
    }
    if (found == null) {
      return true;
    }
    if (found.kind != MapEntityKind.npc) {
      return true;
    }
    return _npcPresencePredicateFor(_bundle.manifest)(
      _world.map.id,
      found,
    );
  }

  void _handleNpcInteraction(MapEntity entity) {
    if (!_npcPresencePredicateFor(_bundle.manifest)(_world.map.id, entity)) {
      debugPrint('[interact] ignored absent npc=${entity.id}');
      return;
    }
    final trainerId = entity.npc?.trainerId?.trim();

    // Cas 1: pas de trainerId → dialogue normal
    if (trainerId == null || trainerId.isEmpty) {
      _tryOpenDialogue(
        entity.id,
        _resolveNpcDialogueRef(entity),
        entity.inspectorHeadline,
      );
      return;
    }

    // Cas 2: trainer déjà battu → defeat dialogue ou fallback
    if (_storyBranching.isTrainerDefeated(_gameState, trainerId)) {
      debugPrint(
        '[interact] trainer already defeated trainer=$trainerId npc=${entity.id}',
      );
      _openDefeatDialogue(entity);
      return;
    }

    // Cas 3: trainerId invalide → log + fallback dialogue
    final trainer =
        _bundle.manifest.trainers.cast<ProjectTrainerEntry?>().firstWhere(
              (t) => t?.id == trainerId,
              orElse: () => null,
            );
    if (trainer == null) {
      debugPrint(
        '[battle] trainer not found: $trainerId for npc=${entity.id}, fallback to dialogue',
      );
      _showNotification('Dresseur introuvable.');
      _tryOpenDialogue(
        entity.id,
        _resolveNpcDialogueRef(entity),
        entity.inspectorHeadline,
      );
      return;
    }

    // Cas 4: trainer non battu → battle normal
    // Vérifier aussi _triggeredTrainerBattles pour éviter double déclenchement
    if (_triggeredTrainerBattles.contains(entity.id)) {
      debugPrint(
        '[interact] trainer battle already triggered (LoS lock) trainer=$trainerId npc=${entity.id}',
      );
      // Ne pas déclencher un autre battle, mais ne pas bloquer l'interaction non plus
      // Juste ignorer silencieusement
      return;
    }

    final request = buildTrainerBattleRequestFromNpc(
      entity: entity,
      manifest: _bundle.manifest,
      world: _world,
    );
    if (request != null) {
      debugPrint(
        '[battle] trainer battle triggered npc=${entity.id} trainer=$trainerId',
      );
      // Lock ANTI-RETRIGGER avant de déclencher
      _triggeredTrainerBattles.add(entity.id);
      // UNIFIED PATTERN: Store in _pendingBattleRequest, let update() consume it
      // This is consistent with wild encounters and allows proper timing
      _pendingBattleRequest = request;
    }
  }

  void _openDefeatDialogue(MapEntity entity) {
    final defeatRef = entity.npc?.defeatDialogueRef;
    if (defeatRef != null) {
      debugPrint('[interact] opening defeat dialogue npc=${entity.id}');
      _tryOpenDialogue(entity.id, defeatRef, entity.inspectorHeadline);
    } else if (_resolveNpcDialogueRef(entity) != null) {
      debugPrint(
          '[interact] no defeat dialogue, fallback to normal dialogue npc=${entity.id}');
      _tryOpenDialogue(
        entity.id,
        _resolveNpcDialogueRef(entity),
        entity.inspectorHeadline,
      );
    } else {
      debugPrint(
          '[interact] no dialogue for defeated trainer npc=${entity.id}');
      _showNotification('Le dresseur est déjà vaincu.');
    }
  }

  /// DEBUG-ONLY: Marque un trainer comme battu.
  ///
  /// **À n'utiliser qu'en debug/dev pour tester le flux de défaite.**
  /// Tant que le gameplay de combat n'est pas implémenté, ce mécanisme
  /// permet de simuler une victoire pour vérifier le defeat dialogue.
  ///
  /// En production, ce flag devrait être positionné automatiquement
  /// après une vraie victoire en combat.
  void debugMarkTrainerAsDefeated(String trainerId) {
    final trimmedId = trainerId.trim();
    if (trimmedId.isEmpty) {
      debugPrint('[debug] invalid trainerId, ignored');
      return;
    }
    _gameState = _storyFlags.markTrainerDefeated(_gameState, trimmedId);
    debugPrint('[debug] trainer $trimmedId marked as defeated');
    _refreshWorldNpcPresence();
  }

  /// Vérifie la Line of Sight (LoS) des trainers et déclenche automatiquement
  /// le battle si le joueur est détecté.
  ///
  /// **Conditions de déclenchement :**
  /// 1. Runtime stable : overworld, pas de dialogue, pas de battle pending
  /// 2. Trainer avec trainerId valide et lineOfSightRange > 0
  /// 3. Trainer non déjà battu (flag trainer_defeated:{id})
  /// 4. Joueur dans la LoS du trainer (checkLineOfSight)
  /// 5. Trainer pas déjà dans _triggeredTrainerBattles (anti-retrigger)
  ///
  /// **Réarmement :**
  /// - Quand le joueur sort de la LoS → lock retirée
  /// - Sur changement de map → toutes les locks retirées
  ///
  /// **Origine du calcul :**
  /// - Depuis entity.pos du NPC
  /// - Axe cardinal uniquement (nord/sud/est/ouest)
  /// - Aucune diagonale
  /// - Obstacles via world.isBlocked() sur les cases STRICTEMENT entre
  ///   le NPC et le joueur (exclut case du NPC et case du joueur)
  void _checkTrainerLineOfSight() {
    // Condition de stabilité runtime stricte
    if (_flowPhase != _RuntimeFlowPhase.overworld) return;
    if (_dialogueOverlay != null) return;
    if (_pendingBattleRequest != null) return;

    for (final entity in _world.map.entities) {
      if (entity.kind != MapEntityKind.npc) continue;
      if (!_npcPresencePredicateFor(_bundle.manifest)(
        _world.map.id,
        entity,
      )) {
        continue;
      }

      final trainerId = entity.npc?.trainerId;
      if (trainerId == null || trainerId.isEmpty) continue;

      final losRange = entity.npc?.lineOfSightRange ?? 0;
      if (losRange <= 0) continue;

      // Vérifier si déjà battu
      if (_storyBranching.isTrainerDefeated(_gameState, trainerId)) continue;

      // Anti-retrigger : ignorer si déjà déclenché dans cette session
      if (_triggeredTrainerBattles.contains(entity.id)) {
        // Réarmement : si joueur sort de LoS, retirer le lock
        final inLoS = checkLineOfSight(
          npcPos: entity.pos,
          npcFacing: entity.npc!.facing,
          lineOfSightRange: losRange,
          playerPos: _world.player.pos,
          world: _world,
        );
        if (!inLoS) {
          _triggeredTrainerBattles.remove(entity.id);
        }
        continue;
      }

      // Check LoS
      final inLoS = checkLineOfSight(
        npcPos: entity.pos,
        npcFacing: entity.npc!.facing,
        lineOfSightRange: losRange,
        playerPos: _world.player.pos,
        world: _world,
      );

      if (inLoS) {
        // Lock anti-retrigger AVANT de déclencher
        _triggeredTrainerBattles.add(entity.id);
        _triggerTrainerBattle(entity);
      }
    }
  }

  /// Déclenche un battle trainer (appelé par interaction manuelle OU LoS auto).
  ///
  /// **Factorisation :** Cette méthode factorise UNIQUEMENT le démarrage du battle.
  /// Elle ne gère PAS :
  /// - La vérification trainer déjà battu (déjà fait par l'appelant)
  /// - Le defeat dialogue (géré par _handleNpcInteraction pour interaction manuelle)
  ///
  /// **Gestion d'erreur :**
  /// - trainerId invalide → log + notification + pas de crash
  /// - Battle request null → log + pas de battle
  void _triggerTrainerBattle(MapEntity entity) {
    final trainerId = entity.npc?.trainerId;
    if (trainerId == null || trainerId.isEmpty) {
      debugPrint('[trainer] no trainerId for entity=${entity.id}');
      return;
    }

    // Vérifier si déjà battu (pour LoS — interaction manuelle a déjà son check)
    if (_storyBranching.isTrainerDefeated(_gameState, trainerId)) {
      debugPrint('[trainer] already defeated trainer=$trainerId');
      return;
    }

    // Vérifier trainer valide
    final trainer =
        _bundle.manifest.trainers.cast<ProjectTrainerEntry?>().firstWhere(
              (t) => t?.id == trainerId,
              orElse: () => null,
            );
    if (trainer == null) {
      debugPrint('[trainer] not found trainer=$trainerId entity=${entity.id}');
      _showNotification('Dresseur introuvable.');
      return;
    }

    // Créer battle request
    final request = buildTrainerBattleRequestFromNpc(
      entity: entity,
      manifest: _bundle.manifest,
      world: _world,
    );
    if (request != null) {
      debugPrint(
          '[trainer] battle triggered trainer=$trainerId entity=${entity.id}');
      // UNIFIED PATTERN: Store in _pendingBattleRequest, let update() consume it
      // This is consistent with wild encounters and allows proper timing
      _pendingBattleRequest = request;
    } else {
      debugPrint(
          '[trainer] battle request failed trainer=$trainerId entity=${entity.id}');
    }
  }

  void _showNotification(String text) {
    _notification?.removeFromParent();
    final paint = TextPaint(
      style: const TextStyle(
        fontSize: 16,
        color: Colors.white,
        backgroundColor: Color(0xAA000000),
      ),
    );
    final component = TextComponent(
      text: text,
      textRenderer: paint,
      anchor: Anchor.topCenter,
    );
    component.position = Vector2(
      camera.viewport.size.x / 2,
      camera.viewport.size.y - 48,
    );
    camera.viewport.add(component);
    _notification = component;
    Future.delayed(const Duration(seconds: 2), () {
      if (_notification == component) {
        component.removeFromParent();
        _notification = null;
      }
    });
  }

  void _handleWaterBlocked() {
    final delta = _runtimeClockMs - _lastWaterRequiresSurfMessageAtMs;
    if (delta < _kWaterRequiresSurfMessageCooldownMs) {
      return;
    }
    _lastWaterRequiresSurfMessageAtMs = _runtimeClockMs;

    final evaluation = evaluateSurfAttempt(
      gameState: _gameState,
      isTargetWater: true,
    );
    final yarnNode = surfEvaluationToYarnNode(evaluation);
    if (yarnNode == null) {
      return;
    }

    final session = loadSurfDialogueSession(yarnNode);
    if (session == null) {
      debugPrint('[surf] failed to load dialogue node=$yarnNode');
      _showNotification(waterRequiresSurfFeedbackMessage);
      return;
    }

    debugPrint(
        '[surf] evaluation=${evaluation.runtimeType} -> dialogue=$yarnNode');

    if (evaluation is CanPromptSurf) {
      _awaitingSurfConfirmation = true;
    }
    _openDialogue(session);
  }

  /// Sauvegarde l'état actuel de la partie.
  ///
  /// Retourne `true` si la sauvegarde a réussi.
  Future<bool> saveGame() async {
    if (isLoaded) {
      _syncGameStateFromWorld(mapIdOverride: _activeMapId);
    }
    debugPrint(
      '[step_studio_trace] runtime_save_requested map=$_activeMapId completedStepIds=${_gameState.progression.completedStepIds} completedCutsceneIds=${_gameState.progression.completedCutsceneIds}',
    );
    return _saveGameUseCase.execute(_gameState);
  }

  /// Charge l'état de la partie et resync complètement le runtime.
  ///
  /// Retourne `true` si le chargement a réussi.
  /// Retourne `false` si aucune sauvegarde n'existe ou en cas d'échec.
  ///
  /// Effets de bord :
  /// - Modifie `_gameState`
  /// - Modifie `_activeMapId`
  /// - Recharge la map courante
  /// - Reconstruit `_world` avec la position/facing du joueur
  /// - Resync `_player` avec le nouveau `_world`
  /// - Resync caméra / streaming / bounds
  ///
  /// **Note** : Cette méthode ne restaure pas les overlays actifs (dialogue,
  /// battle transition) ni les états transitoires. Elle restaure uniquement
  /// l'état principal du runtime.
  ///
  /// **Limitation** : La phase destructive (à partir de `_gameState = loadedState`)
  /// n'est pas transactionnelle. En cas d'échec pendant le chargement de la map
  /// ou le remontage des layers, le runtime peut rester dans un état partiellement
  /// modifié. Aucun rollback n'est implémenté dans ce lot. Cette limitation sera
  /// adressée dans un futur lot si nécessaire.
  Future<bool> loadGame() async {
    // 1. Charger loadedState
    final rawLoadedState = await _loadGameUseCase.execute();
    if (rawLoadedState == null) {
      debugPrint('[load] no save found');
      return false;
    }
    final loadedState = normalizeLoadedGameState(rawLoadedState);

    // 2. Charger newBundle (avec error handling)
    RuntimeMapBundle newBundle;
    try {
      final loadedBundle = await loadRuntimeMapBundle(
        projectFilePath: projectFilePath,
        mapId: loadedState.currentMapId,
      );
      newBundle = _resolveRuntimeBundle(loadedBundle);
    } catch (e, st) {
      debugPrint('[load] failed to load map: $e\n$st');
      return false;
    }

    // 3. Charger newImages (avec error handling)
    Map<String, ui.Image> newImages;
    try {
      newImages =
          await loadTilesetImagesById(newBundle.tilesetAbsolutePathsById);
    } catch (e, st) {
      debugPrint('[load] failed to load tileset images: $e\n$st');
      return false;
    }

    // 4-16. Phase destructive (protégée par try/catch)
    try {
      // 4. Restaurer GameState
      _gameState = loadedState;

      // 5. Nettoyer l'état transitoire
      _clearTransientUiState();

      // 6. Unmount anciennes maps
      _unmountAllLoadedMaps();

      // 7. Assigner _bundle = newBundle
      _bundle = newBundle;

      // 8. Monter nouvelle map
      await _mountLoadedMap(
        bundle: newBundle,
        tileImagesById: newImages,
        originCellX: 0,
        originCellY: 0,
      );

      // 9. Reconstruire _world
      _world = GameplayWorldState.initial(
        map: newBundle.map,
        project: newBundle.manifest,
        playerPos: loadedState.playerPosition,
        playerFacing: loadedState.playerFacing.asDirection,
        playerMovementMode: loadedState.playerMovementMode,
        npcMapPresencePredicate: _npcPresencePredicateFor(newBundle.manifest),
      );

      // 10. Mettre _activeMapId + reset contrôleur PNJ scripté
      _activeMapId = loadedState.currentMapId;
      _resetScriptedNpcMovementController();

      // 10. Resync _player
      _player.setMapOrigin(Vector2(0, 0), snapToGrid: false);
      _player.syncState(_world.player, snapToGrid: true);

      // 11. Synchroniser GameState
      _syncGameStateFromWorld(mapIdOverride: _activeMapId);

      // 12-15. Resync caméra / streaming / bounds
      _configureCameraViewport();
      _syncCameraToPlayer();
      _preloadActiveMapConnections();
      _pruneLoadedMapsToActiveNeighborhood();
      _applyDebugTileMarker();
      _activeScenarioTriggerIds = _scenarioRuntime.triggerIdsAtPosition(
        map: _bundle.map,
        pos: _world.player.pos,
      );

      _refreshWorldNpcPresence();

      debugPrint('[load] game loaded from saveId=${loadedState.saveId}');
      return true;
    } catch (e, st) {
      debugPrint('[load] failed during destructive phase: $e\n$st');
      return false;
    }
  }

  PlacedBehaviorRuntimeKey _buildPlacedBehaviorCooldownKey({
    required MapPlacedElement element,
    required MapPlacedElementBehavior behavior,
    required MapPlacedElementTriggerType trigger,
  }) {
    final trimmedBehaviorId = behavior.id.trim();
    final behaviorId = trimmedBehaviorId.isEmpty ? 'legacy' : trimmedBehaviorId;
    return PlacedBehaviorRuntimeKey(
      instanceId: element.id,
      behaviorId: behaviorId,
      trigger: trigger,
      effectType: behavior.effect.type,
    );
  }

  Duration? _resolvePlacedBehaviorCooldownOverride(
    MapPlacedElementBehavior behavior,
  ) {
    final cooldownMs = behavior.cooldownMs;
    if (cooldownMs == null) {
      return null;
    }
    if (cooldownMs <= 0) {
      return Duration.zero;
    }
    return Duration(milliseconds: cooldownMs);
  }

  bool _resolvePlacedElementAnimationEnabled(String instanceId) {
    for (final instance in _world.map.placedElements) {
      if (instance.id != instanceId) {
        continue;
      }
      return instance.animation?.enabled ?? false;
    }
    return false;
  }

  void _ensureBehaviorDebugOverlay() {
    if (!_showBehaviorDebugOverlay) {
      return;
    }
    final existing = _behaviorDebugOverlay;
    if (existing != null) {
      existing.text = _lastBehaviorDebugLine;
      return;
    }
    final overlay = TextComponent(
      text: _lastBehaviorDebugLine,
      textRenderer: TextPaint(
        style: const TextStyle(
          fontSize: 12,
          color: Colors.white,
          backgroundColor: Color(0xAA111111),
        ),
      ),
      anchor: Anchor.topLeft,
      position: Vector2(10, 10),
      priority: 30000,
    );
    camera.viewport.add(overlay);
    _behaviorDebugOverlay = overlay;
  }

  void _ensureFpsOverlay() {
    if (!_showFpsOverlay) {
      return;
    }
    final existing = _fpsOverlay;
    if (existing != null) {
      existing.text = 'FPS ${_currentFps.toStringAsFixed(1)}';
      return;
    }
    final overlay = TextComponent(
      text: 'FPS ${_currentFps.toStringAsFixed(1)}',
      textRenderer: TextPaint(
        style: const TextStyle(
          fontSize: 12,
          color: Colors.lightGreenAccent,
          backgroundColor: Color(0xAA111111),
          fontWeight: FontWeight.w600,
        ),
      ),
      anchor: Anchor.topLeft,
      position: Vector2(10, 28),
      priority: 30000,
    );
    camera.viewport.add(overlay);
    _fpsOverlay = overlay;
  }

  void _updateFps(double dt) {
    _fpsAccumulatorSeconds += dt;
    _fpsFrameCount += 1;

    // Fenêtre courte de 250ms: stable sans être trop lente.
    if (_fpsAccumulatorSeconds < 0.25) {
      return;
    }
    _currentFps = _fpsFrameCount / _fpsAccumulatorSeconds;
    _fpsAccumulatorSeconds = 0.0;
    _fpsFrameCount = 0;

    if (_showFpsOverlay) {
      _ensureFpsOverlay();
      _fpsOverlay?.text = 'FPS ${_currentFps.toStringAsFixed(1)}';
    }
  }

  void _updateBehaviorDebugLine(String line) {
    _lastBehaviorDebugLine = line;
    if (!_showBehaviorDebugOverlay) {
      return;
    }
    _ensureBehaviorDebugOverlay();
    final overlay = _behaviorDebugOverlay;
    if (overlay == null) {
      return;
    }
    overlay.text = line;
  }

  Future<void> _handleWarp(TriggeredWarp warp) async {
    if (_flowPhase != _RuntimeFlowPhase.overworld) {
      debugPrint('[warp] ignored: flow=${_flowPhase.name}');
      return;
    }
    _flowPhase = _RuntimeFlowPhase.mapTransition;
    final sourceBundle = _bundle;
    final sourceWorld = _world;
    final sourceMapId = _activeMapId;
    final sourcePos = _world.player.pos;
    final sourceFacing = _world.player.facing;
    WarpTransitionOverlayComponent? overlay;
    var swapCompleted = false;
    try {
      _clearTransientUiState();
      overlay = WarpTransitionOverlayComponent(
        viewportSize: camera.viewport.size,
      );
      camera.viewport.add(overlay);
      _warpTransitionOverlay = overlay;
      debugPrint(
        '[warp] start transition warp=${warp.warpId} map=$sourceMapId -> ${warp.targetMapId} target=(${warp.targetPos.x}, ${warp.targetPos.y})',
      );
      final loadedBundle = await loadRuntimeMapBundle(
        projectFilePath: projectFilePath,
        mapId: warp.targetMapId,
      );
      final newBundle = _resolveRuntimeBundle(loadedBundle);
      debugPrint('[warp] target map loaded id=${newBundle.map.id}');
      final transitionSpec = _resolveWarpTransitionSpec(
        sourceMap: sourceBundle.map,
        targetMap: newBundle.map,
      );
      if (transitionSpec.style == _WarpTransitionStyle.fade) {
        debugPrint(
          '[warp] fade out durationMs=${transitionSpec.fadeOut.inMilliseconds}',
        );
        await overlay.fadeOut(duration: transitionSpec.fadeOut);
      }
      if (!_isWithinMapBounds(newBundle.map, warp.targetPos)) {
        throw StateError(
          'warp target out of bounds map=${newBundle.map.id} pos=(${warp.targetPos.x}, ${warp.targetPos.y}) size=${newBundle.map.size.width}x${newBundle.map.size.height}',
        );
      }
      final newWorld = GameplayWorldState.initial(
        map: newBundle.map,
        playerPos: warp.targetPos,
        playerFacing: sourceFacing,
        project: newBundle.manifest,
        tileWidth: newBundle.manifest.settings.tileWidth,
        tileHeight: newBundle.manifest.settings.tileHeight,
        npcMapPresencePredicate: _npcPresencePredicateFor(newBundle.manifest),
      );
      if (newWorld.isBlocked(warp.targetPos.x, warp.targetPos.y)) {
        throw StateError(
          'warp target blocked map=${newBundle.map.id} pos=(${warp.targetPos.x}, ${warp.targetPos.y})',
        );
      }
      debugPrint('[warp] loading target map visuals id=${newBundle.map.id}');
      final newImages =
          await loadTilesetImagesById(newBundle.tilesetAbsolutePathsById);
      _unmountAllLoadedMaps();
      final root = await _mountLoadedMap(
        bundle: newBundle,
        tileImagesById: newImages,
        originCellX: 0,
        originCellY: 0,
      );
      _bundle = newBundle;
      _world = newWorld;
      _activeMapId = newBundle.map.id;
      _previousMapId = null;
      _triggeredTrainerBattles.clear(); // Reset LoS locks on map change
      _resetScriptedNpcMovementController();
      _player.setMapOrigin(_originPixelsOf(root), snapToGrid: false);
      _player.syncState(_world.player, snapToGrid: true);
      _syncGameStateFromWorld(mapIdOverride: _activeMapId);
      swapCompleted = true;
      debugPrint(
        '[warp] player placed at map=${newBundle.map.id} pos=(${_world.player.pos.x}, ${_world.player.pos.y})',
      );
      _configureCameraViewport();
      _syncCameraToPlayer();
      _preloadActiveMapConnections();
      _pruneLoadedMapsToActiveNeighborhood();
      _refreshWorldNpcPresence();
      if (transitionSpec.style == _WarpTransitionStyle.fade) {
        debugPrint(
          '[warp] fade in durationMs=${transitionSpec.fadeIn.inMilliseconds}',
        );
        await overlay.fadeIn(duration: transitionSpec.fadeIn);
      }
      debugPrint('[warp] transition completed');
    } catch (e, st) {
      debugPrint('[warp] transition failed: $e\n$st');
      _showNotification('Warp failed');
      if (!swapCompleted) {
        await _recoverFromWarpFailure(
          sourceBundle: sourceBundle,
          sourceWorld: sourceWorld,
          sourceMapId: sourceMapId,
        );
      }
      if (overlay != null) {
        await overlay.fadeIn(duration: const Duration(milliseconds: 140));
      }
    } finally {
      _warpTransitionOverlay?.close();
      _warpTransitionOverlay = null;
      _flowPhase = _RuntimeFlowPhase.overworld;
      debugPrint(
        '[warp] gameplay unlocked map=$_activeMapId pos=(${_world.player.pos.x}, ${_world.player.pos.y})',
      );
      if (swapCompleted) {
        _activeScenarioTriggerIds = _scenarioRuntime.triggerIdsAtPosition(
          map: _bundle.map,
          pos: _world.player.pos,
        );
        _dispatchScenarioRuntimeSource(
          ScenarioRuntimeSourceEvent.mapEnter(mapId: _activeMapId),
        );
      }
      if (_activeMapId == sourceMapId &&
          _world.player.pos.x == sourcePos.x &&
          _world.player.pos.y == sourcePos.y) {
        _player.syncState(_world.player, snapToGrid: true);
      }
    }
  }

  _WarpTransitionSpec _resolveWarpTransitionSpec({
    required MapData sourceMap,
    required MapData targetMap,
  }) {
    final sourceIndoor = sourceMap.mapMetadata.isIndoor ||
        sourceMap.mapMetadata.mapType == MapType.building ||
        sourceMap.mapMetadata.mapType == MapType.interior ||
        sourceMap.mapMetadata.mapType == MapType.cave ||
        sourceMap.mapMetadata.mapType == MapType.facility;
    final targetIndoor = targetMap.mapMetadata.isIndoor ||
        targetMap.mapMetadata.mapType == MapType.building ||
        targetMap.mapMetadata.mapType == MapType.interior ||
        targetMap.mapMetadata.mapType == MapType.cave ||
        targetMap.mapMetadata.mapType == MapType.facility;
    final duration = sourceIndoor == targetIndoor
        ? const Duration(milliseconds: 170)
        : const Duration(milliseconds: 230);
    return _WarpTransitionSpec(
      style: _WarpTransitionStyle.fade,
      fadeOut: duration,
      fadeIn: duration,
    );
  }

  Future<void> _recoverFromWarpFailure({
    required RuntimeMapBundle sourceBundle,
    required GameplayWorldState sourceWorld,
    required String sourceMapId,
  }) async {
    if (_loadedMapsById.isNotEmpty && _activeMapId == sourceMapId) {
      _bundle = sourceBundle;
      _world = sourceWorld;
      _syncGameStateFromWorld(mapIdOverride: sourceMapId);
      _player.syncState(_world.player, snapToGrid: true);
      _configureCameraViewport();
      _syncCameraToPlayer();
      debugPrint('[warp] rollback no-op (source map still mounted)');
      return;
    }

    try {
      _unmountAllLoadedMaps();
      final loadedFallbackBundle = await loadRuntimeMapBundle(
        projectFilePath: projectFilePath,
        mapId: sourceMapId,
      );
      final fallbackBundle = _resolveRuntimeBundle(loadedFallbackBundle);
      final fallbackWorld = _buildSafeWorldState(
        map: fallbackBundle.map,
        project: fallbackBundle.manifest,
        preferredPos: sourceWorld.player.pos,
        fallbackFacing: sourceWorld.player.facing,
        tileWidth: fallbackBundle.manifest.settings.tileWidth,
        tileHeight: fallbackBundle.manifest.settings.tileHeight,
      );
      final fallbackImages =
          await loadTilesetImagesById(fallbackBundle.tilesetAbsolutePathsById);
      final root = await _mountLoadedMap(
        bundle: fallbackBundle,
        tileImagesById: fallbackImages,
        originCellX: 0,
        originCellY: 0,
      );
      _bundle = fallbackBundle;
      _world = fallbackWorld;
      _activeMapId = fallbackBundle.map.id;
      _previousMapId = null;
      _resetScriptedNpcMovementController();
      _player.setMapOrigin(_originPixelsOf(root), snapToGrid: false);
      _player.syncState(_world.player, snapToGrid: true);
      _syncGameStateFromWorld(mapIdOverride: _activeMapId);
      _configureCameraViewport();
      _syncCameraToPlayer();
      _preloadActiveMapConnections();
      _pruneLoadedMapsToActiveNeighborhood();
      debugPrint(
        '[warp] rollback restored map=${fallbackBundle.map.id} pos=(${_world.player.pos.x}, ${_world.player.pos.y})',
      );
    } catch (e, st) {
      debugPrint('[warp] rollback failed: $e\n$st');
    }
  }

  GameplayWorldState _buildSafeWorldState({
    required MapData map,
    required ProjectManifest project,
    required GridPos preferredPos,
    required Direction fallbackFacing,
    required int tileWidth,
    required int tileHeight,
  }) {
    final safePos = _isWithinMapBounds(map, preferredPos)
        ? preferredPos
        : const GridPos(x: 0, y: 0);
    final world = GameplayWorldState.initial(
      map: map,
      playerPos: safePos,
      playerFacing: fallbackFacing,
      project: project,
      tileWidth: tileWidth,
      tileHeight: tileHeight,
      npcMapPresencePredicate: _npcPresencePredicateFor(project),
    );
    if (!world.isBlocked(safePos.x, safePos.y)) {
      return world;
    }

    try {
      final spawn = resolveInitialPlayerSpawn(map);
      final spawnWorld = GameplayWorldState.initial(
        map: map,
        playerPos: spawn.pos,
        playerFacing: fallbackFacing,
        project: project,
        tileWidth: tileWidth,
        tileHeight: tileHeight,
        npcMapPresencePredicate: _npcPresencePredicateFor(project),
      );
      if (!spawnWorld.isBlocked(spawn.pos.x, spawn.pos.y)) {
        return spawnWorld;
      }
    } catch (_) {}

    for (var y = 0; y < map.size.height; y++) {
      for (var x = 0; x < map.size.width; x++) {
        if (!world.isBlocked(x, y)) {
          return GameplayWorldState.initial(
            map: map,
            playerPos: GridPos(x: x, y: y),
            playerFacing: fallbackFacing,
            project: project,
            tileWidth: tileWidth,
            tileHeight: tileHeight,
            npcMapPresencePredicate: _npcPresencePredicateFor(project),
          );
        }
      }
    }

    return world;
  }

  bool _isWithinMapBounds(MapData map, GridPos pos) {
    return pos.x >= 0 &&
        pos.y >= 0 &&
        pos.x < map.size.width &&
        pos.y < map.size.height;
  }

  Future<void> _handleConnection(TriggeredConnection connection) async {
    _flowPhase = _RuntimeFlowPhase.mapTransition;
    var transitionCompleted = false;
    try {
      _clearTransientUiState();
      debugPrint(
        '[connection] attempting map=${_bundle.map.id} direction=${connection.direction.name} target=${connection.targetMapId} offset=${connection.offset} source=(${connection.sourcePos.x}, ${connection.sourcePos.y})',
      );
      final source = _loadedMapsById[_activeMapId];
      if (source == null) {
        debugPrint(
            '[connection] source map visuals missing for id=$_activeMapId');
        _player.syncState(_world.player, snapToGrid: true);
        _showNotification('Connection failed');
        return;
      }
      final target = await _ensureConnectionTargetLoaded(
        source: source,
        connection: connection,
      );
      if (target == null) {
        _player.syncState(_world.player, snapToGrid: true);
        _showNotification('Connection failed');
        return;
      }
      debugPrint('[connection] resolved target map=${target.bundle.map.id}');
      final targetPos = resolveConnectedMapTargetPos(
        sourcePos: connection.sourcePos,
        sourceSize: source.bundle.map.size,
        targetSize: target.bundle.map.size,
        direction: connection.direction,
        offset: connection.offset,
      );
      if (targetPos == null) {
        debugPrint(
          '[connection] invalid entry coordinates direction=${connection.direction.name} offset=${connection.offset} source=(${connection.sourcePos.x}, ${connection.sourcePos.y}) sourceSize=${source.bundle.map.size.width}x${source.bundle.map.size.height} targetSize=${target.bundle.map.size.width}x${target.bundle.map.size.height}',
        );
        _player.syncState(_world.player, snapToGrid: true);
        _showNotification('Connection invalid');
        return;
      }
      debugPrint(
        '[connection] computed entry pos=(${targetPos.x}, ${targetPos.y})',
      );
      final newWorld = GameplayWorldState.initial(
        map: target.bundle.map,
        playerPos: targetPos,
        playerFacing: _world.player.facing,
        project: target.bundle.manifest,
        tileWidth: target.bundle.manifest.settings.tileWidth,
        tileHeight: target.bundle.manifest.settings.tileHeight,
        npcMapPresencePredicate:
            _npcPresencePredicateFor(target.bundle.manifest),
      );
      if (newWorld.isBlocked(targetPos.x, targetPos.y)) {
        debugPrint(
          '[connection] blocked entry map=${target.bundle.map.id} pos=(${targetPos.x}, ${targetPos.y})',
        );
        _player.syncState(_world.player, snapToGrid: true);
        _showNotification('Connection blocked');
        return;
      }
      _bundle = target.bundle;
      _world = newWorld;
      _previousMapId = _activeMapId;
      _activeMapId = target.bundle.map.id;
      _resetScriptedNpcMovementController();
      _syncGameStateFromWorld(mapIdOverride: _activeMapId);
      final fromPx = _player.position.clone();
      final targetOriginPx = _originPixelsOf(target);
      final toPx = Vector2(
        targetOriginPx.x + targetPos.x * _cellWidth,
        targetOriginPx.y + targetPos.y * _cellHeight,
      );
      debugPrint(
        '[connection] player step pixels from=(${fromPx.x.toStringAsFixed(1)}, ${fromPx.y.toStringAsFixed(1)}) to=(${toPx.x.toStringAsFixed(1)}, ${toPx.y.toStringAsFixed(1)})',
      );
      _player.setMapOrigin(targetOriginPx, snapToGrid: false);
      _player.startStep(
        _world.player,
        durationSeconds: PlayerComponent.kDefaultStepSeconds,
      );
      _configureCameraViewport();
      final visibleSize = camera.viewfinder.visibleGameSize;
      debugPrint(
        '[connection] camera after transition focus=(${_player.focusPoint.x.toStringAsFixed(1)}, ${_player.focusPoint.y.toStringAsFixed(1)}) viewport=(${(visibleSize?.x ?? 0).toStringAsFixed(1)}, ${(visibleSize?.y ?? 0).toStringAsFixed(1)})',
      );
      debugPrint(
        '[connection] transition complete -> map=${target.bundle.map.id} pos=(${targetPos.x}, ${targetPos.y})',
      );
      _preloadActiveMapConnections();
      _pruneLoadedMapsToActiveNeighborhood();
      _refreshWorldNpcPresence();
      transitionCompleted = true;
    } catch (e, st) {
      debugPrint('[connection] transition failed: $e\n$st');
      _player.syncState(_world.player, snapToGrid: true);
      _showNotification('Connection failed');
    } finally {
      _flowPhase = _RuntimeFlowPhase.overworld;
      if (transitionCompleted) {
        _activeScenarioTriggerIds = _scenarioRuntime.triggerIdsAtPosition(
          map: _bundle.map,
          pos: _world.player.pos,
        );
        _dispatchScenarioRuntimeSource(
          ScenarioRuntimeSourceEvent.mapEnter(mapId: _activeMapId),
        );
      }
    }
  }

  void _clearTransientUiState() {
    _pendingWarp = null;
    _pendingConnection = null;
    // CRITICAL: Do NOT clear _pendingBattleRequest if a battle is active!
    // This would cancel a pending wild encounter battle.
    // Only clear if we're in overworld phase (no battle in progress).
    if (_flowPhase == _RuntimeFlowPhase.overworld) {
      _pendingBattleRequest = null;
    }
    _pendingPlacedElementBehavior = null;
    _notification?.removeFromParent();
    _notification = null;
    _dialogueOverlay?.removeFromParent();
    _dialogueOverlay = null;
    _battleTransitionOverlay?.removeFromParent();
    _battleTransitionOverlay = null;
    _battleOverlay?.removeFromParent();
    _battleOverlay = null;
    // Blindage défensif lot 10 :
    // ce reset central est utilisé par plusieurs chemins runtime (load, warp,
    // connection). Si un contexte battle survivait ici, on garderait en
    // mémoire un slot party et une requête de combat qui ne correspondent plus
    // à l'état overworld courant. On l'efface donc explicitement avec le reste
    // de l'UI transitoire.
    _activeBattleContext = null;
    _warpTransitionOverlay?.removeFromParent();
    _warpTransitionOverlay = null;
    _pressedKeys.clear();
    _lastMoveKey = null;
  }

  void _unmountAllLoadedMaps() {
    final ids = _loadedMapsById.keys.toList(growable: false);
    for (final id in ids) {
      _unmountLoadedMap(id);
    }
    _loadedMapsById.clear();
    _loadMapFutureById.clear();
  }

  void _applyDebugTileMarker() {
    _debugTileMarkerFill?.removeFromParent();
    _debugTileMarkerFill = null;
    _debugTileMarkerBorder?.removeFromParent();
    _debugTileMarkerBorder = null;
    _debugTileMarkerText?.removeFromParent();
    _debugTileMarkerText = null;

    final pos = _debugTileMarkerPos;
    if (pos == null) {
      return;
    }
    final loaded = _loadedMapsById[_activeMapId];
    if (loaded == null) {
      return;
    }
    final origin = _originPixelsOf(loaded);
    final x = origin.x + pos.x * _cellWidth;
    final y = origin.y + pos.y * _cellHeight;
    final size = Vector2(_cellWidth, _cellHeight);

    final fill = RectangleComponent(
      position: Vector2(x, y),
      size: size,
      paint: ui.Paint()..color = const ui.Color(0x66FF9800),
      priority: 150000,
    );
    final border = RectangleComponent(
      position: Vector2(x, y),
      size: size,
      paint: ui.Paint()
        ..color = const ui.Color(0xFFFF6D00)
        ..style = ui.PaintingStyle.stroke
        ..strokeWidth = 2,
      priority: 150001,
    );
    world.add(fill);
    world.add(border);
    _debugTileMarkerFill = fill;
    _debugTileMarkerBorder = border;

    final label = _debugTileMarkerLabel?.trim();
    if (label == null || label.isEmpty) {
      return;
    }
    final text = TextComponent(
      text: label,
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
      position: Vector2(x + 2, y + 2),
      priority: 150002,
    );
    world.add(text);
    _debugTileMarkerText = text;
  }

  void _clearNpcCollisionDebugOverlay() {
    final ids = _npcCollisionDebugByEntityId.keys.toList(growable: false);
    for (final id in ids) {
      final visual = _npcCollisionDebugByEntityId.remove(id);
      visual?.spriteRect.removeFromParent();
      visual?.collisionRect.removeFromParent();
      visual?.anchorMarker.removeFromParent();
    }
  }

  void _syncNpcCollisionDebugOverlay() {
    if (!_showNpcCollisionDebugOverlay) {
      _clearNpcCollisionDebugOverlay();
      return;
    }
    final loaded = _loadedMapsById[_activeMapId];
    if (loaded == null) {
      _clearNpcCollisionDebugOverlay();
      return;
    }
    final origin = _originPixelsOf(loaded);
    final seen = <String>{};
    for (final entity in _world.map.entities) {
      if (entity.kind != MapEntityKind.npc) {
        continue;
      }
      final actor = loaded.npcActorByEntityId[entity.id];
      if (actor == null) {
        continue;
      }
      seen.add(entity.id);
      final visual = _npcCollisionDebugByEntityId.putIfAbsent(entity.id, () {
        final spriteRect = RectangleComponent(
          priority: 200000,
          paint: ui.Paint()
            ..color = const ui.Color(0xAA00E5FF)
            ..style = ui.PaintingStyle.stroke
            ..strokeWidth = 2,
        );
        final collisionRect = RectangleComponent(
          priority: 200001,
          paint: ui.Paint()
            ..color = const ui.Color(0xAAFF1744)
            ..style = ui.PaintingStyle.stroke
            ..strokeWidth = 2,
        );
        final anchorMarker = CircleComponent(
          radius: 3.0,
          priority: 200002,
          paint: ui.Paint()..color = const ui.Color(0xFFFFEA00),
        );
        world.add(spriteRect);
        world.add(collisionRect);
        world.add(anchorMarker);
        return _NpcCollisionDebugVisual(
          spriteRect: spriteRect,
          collisionRect: collisionRect,
          anchorMarker: anchorMarker,
        );
      });

      // 1) Bounding box visuelle réelle du sprite.
      visual.spriteRect
        ..position = actor.position.clone()
        ..size = actor.size.clone();

      // 2) Footprint collision gameplay (grille -> pixels).
      final footprint = resolveEntityCollisionFootprint(entity);
      visual.collisionRect
        ..position = Vector2(
          origin.x + footprint.pos.x * _cellWidth,
          origin.y + footprint.pos.y * _cellHeight,
        )
        ..size = Vector2(
          footprint.size.width * _cellWidth,
          footprint.size.height * _cellHeight,
        );

      // 3) Point d'ancrage logique MapEntity.pos (top-left cellule logique).
      visual.anchorMarker.position = Vector2(
        origin.x + entity.pos.x * _cellWidth + (_cellWidth / 2) - 3,
        origin.y + entity.pos.y * _cellHeight + (_cellHeight / 2) - 3,
      );
    }

    final stale = _npcCollisionDebugByEntityId.keys
        .where((id) => !seen.contains(id))
        .toList(growable: false);
    for (final id in stale) {
      final visual = _npcCollisionDebugByEntityId.remove(id);
      visual?.spriteRect.removeFromParent();
      visual?.collisionRect.removeFromParent();
      visual?.anchorMarker.removeFromParent();
    }
  }

  void _unmountLoadedMap(String mapId) {
    _clearNpcCollisionDebugOverlay();
    final loaded = _loadedMapsById.remove(mapId);
    if (loaded == null) {
      return;
    }
    loaded.backgroundLayers.removeFromParent();
    loaded.foregroundLayers.removeFromParent();
    for (final actor in loaded.npcActors) {
      actor.removeFromParent();
      _npcActors.remove(actor);
    }
  }

  Future<_LoadedPlayableMap> _mountLoadedMap({
    required RuntimeMapBundle bundle,
    required Map<String, ui.Image> tileImagesById,
    required int originCellX,
    required int originCellY,
  }) async {
    final npcPred = _npcPresencePredicateFor(bundle.manifest);
    final backgroundLayers = MapLayersComponent(
      bundle: bundle,
      tileImagesByTilesetId: tileImagesById,
      showCollisionOverlay: _showCollisionOverlay,
      npcMapPresencePredicate: npcPred,
    );
    backgroundLayers.position = _originPixels(
      originCellX: originCellX,
      originCellY: originCellY,
    );
    backgroundLayers.priority = 0;
    await world.add(backgroundLayers);

    final foregroundLayers = MapLayersComponent(
      bundle: bundle,
      tileImagesByTilesetId: tileImagesById,
      renderPass: MapLayerRenderPass.foreground,
      showCollisionOverlay: false,
      npcMapPresencePredicate: npcPred,
    );
    foregroundLayers.position = _originPixels(
      originCellX: originCellX,
      originCellY: originCellY,
    );
    foregroundLayers.priority = 100000;
    await world.add(foregroundLayers);

    final npcActors = <OverworldActorComponent>[];
    final npcActorByEntityId = <String, OverworldActorComponent>{};
    final charById = {for (final c in bundle.manifest.characters) c.id: c};
    final cw = bundle.cellWidth;
    final ch = bundle.cellHeight;
    final originPx =
        _originPixels(originCellX: originCellX, originCellY: originCellY);
    for (final entity in bundle.map.entities) {
      if (entity.kind != MapEntityKind.npc) continue;
      if (!npcPred(bundle.map.id, entity)) {
        // Pas de création d'acteur si la règle runtime dit "absent".
        debugPrint(
          '[step_studio_trace] npc_mount_skipped map=${bundle.map.id} entity=${entity.id} reason=presence_predicate_false',
        );
        continue;
      }
      final charId = resolveNpcCharacterId(entity, bundle.manifest);
      if (charId == null || charId.isEmpty) continue;
      final char = charById[charId];
      if (char == null) continue;
      final actor = OverworldActorComponent(
        character: char,
        tileImages: tileImagesById,
        tileWidth: bundle.manifest.settings.tileWidth,
        tileHeight: bundle.manifest.settings.tileHeight,
        cellWidth: cw,
        cellHeight: ch,
        facing: entity.npc?.facing ?? EntityFacing.south,
      );
      actor.configureGridPlacement(
        pos: entity.pos,
        footprint: entity.size,
        mapOrigin: originPx,
        snapToGrid: true,
      );
      npcActors.add(actor);
      npcActorByEntityId[entity.id] = actor;
      _npcActors.add(actor);
      await world.add(actor);
      debugPrint(
        '[step_studio_trace] npc_mount_added map=${bundle.map.id} entity=${entity.id}',
      );
    }

    final loaded = _LoadedPlayableMap(
      bundle: bundle,
      originCellX: originCellX,
      originCellY: originCellY,
      backgroundLayers: backgroundLayers,
      foregroundLayers: foregroundLayers,
      npcActors: npcActors,
      npcActorByEntityId: npcActorByEntityId,
    );
    _loadedMapsById[bundle.map.id] = loaded;
    _applyNpcVisibilityToLoadedMap(loaded);
    return loaded;
  }

  Future<_LoadedPlayableMap?> _ensureConnectionTargetLoaded({
    required _LoadedPlayableMap source,
    required TriggeredConnection connection,
  }) async {
    final targetMapId = connection.targetMapId;
    final existing = _loadedMapsById[targetMapId];
    if (existing != null) {
      final expected = _computeConnectedOriginCells(
        source: source,
        connection: connection,
        targetSize: existing.bundle.map.size,
      );
      if (expected.x != existing.originCellX ||
          expected.y != existing.originCellY) {
        debugPrint(
          '[connection] origin mismatch target=$targetMapId existing=(${existing.originCellX}, ${existing.originCellY}) expected=(${expected.x}, ${expected.y})',
        );
      }
      return existing;
    }
    final inFlight = _loadMapFutureById[targetMapId];
    if (inFlight != null) {
      return await inFlight;
    }

    Future<_LoadedPlayableMap?> load() async {
      try {
        final loadedBundle = await loadRuntimeMapBundle(
          projectFilePath: projectFilePath,
          mapId: targetMapId,
        );
        final bundle = _resolveRuntimeBundle(loadedBundle);
        final origin = _computeConnectedOriginCells(
          source: source,
          connection: connection,
          targetSize: bundle.map.size,
        );
        final images =
            await loadTilesetImagesById(bundle.tilesetAbsolutePathsById);
        final loaded = await _mountLoadedMap(
          bundle: bundle,
          tileImagesById: images,
          originCellX: origin.x,
          originCellY: origin.y,
        );
        debugPrint(
          '[connection] loaded map=${bundle.map.id} origin=(${origin.x}, ${origin.y})',
        );
        return loaded;
      } catch (e, st) {
        debugPrint(
            '[connection] load failed target=$targetMapId error=$e\n$st');
        return null;
      }
    }

    final future = load();
    _loadMapFutureById[targetMapId] = future;
    try {
      return await future;
    } finally {
      final current = _loadMapFutureById[targetMapId];
      if (identical(current, future)) {
        _loadMapFutureById.remove(targetMapId);
      }
    }
  }

  _GridCellPos _computeConnectedOriginCells({
    required _LoadedPlayableMap source,
    required TriggeredConnection connection,
    required GridSize targetSize,
  }) {
    return switch (connection.direction) {
      MapConnectionDirection.east => _GridCellPos(
          x: source.originCellX + source.bundle.map.size.width,
          y: source.originCellY + connection.offset,
        ),
      MapConnectionDirection.west => _GridCellPos(
          x: source.originCellX - targetSize.width,
          y: source.originCellY + connection.offset,
        ),
      MapConnectionDirection.north => _GridCellPos(
          x: source.originCellX + connection.offset,
          y: source.originCellY - targetSize.height,
        ),
      MapConnectionDirection.south => _GridCellPos(
          x: source.originCellX + connection.offset,
          y: source.originCellY + source.bundle.map.size.height,
        ),
    };
  }

  void _preloadActiveMapConnections() {
    final active = _loadedMapsById[_activeMapId];
    if (active == null) {
      return;
    }
    for (final connection in active.bundle.map.connections) {
      _ensureConnectionTargetLoaded(
        source: active,
        connection: TriggeredConnection(
          direction: connection.direction,
          targetMapId: connection.targetMapId,
          offset: connection.offset,
          sourcePos: _world.player.pos,
        ),
      );
    }
  }

  void _pruneLoadedMapsToActiveNeighborhood() {
    final active = _loadedMapsById[_activeMapId];
    if (active == null) {
      return;
    }
    final keep = <String>{
      active.bundle.map.id,
      ...active.bundle.map.connections.map((c) => c.targetMapId),
    };
    final previousMapId = _previousMapId;
    if (previousMapId != null && previousMapId.isNotEmpty) {
      keep.add(previousMapId);
    }
    final toRemove = _loadedMapsById.keys
        .where((id) => !keep.contains(id))
        .toList(growable: false);
    for (final id in toRemove) {
      _unmountLoadedMap(id);
    }
  }

  Vector2 _originPixels({
    required int originCellX,
    required int originCellY,
  }) {
    return Vector2(originCellX * _cellWidth, originCellY * _cellHeight);
  }

  Vector2 _originPixelsOf(_LoadedPlayableMap map) {
    return _originPixels(
      originCellX: map.originCellX,
      originCellY: map.originCellY,
    );
  }

  ProjectCharacterEntry? _resolvePlayerCharacter(RuntimeMapBundle bundle) {
    return resolveDefaultPlayerCharacter(bundle.manifest);
  }

  void _faceNpcTowardPlayer(String entityId) {
    final loaded = _loadedMapsById[_activeMapId];
    final actor = loaded?.npcActorByEntityId[entityId];
    if (actor == null) {
      return;
    }
    final playerFacing = _world.player.facing;
    final npcFacing = switch (playerFacing) {
      Direction.north => EntityFacing.south,
      Direction.south => EntityFacing.north,
      Direction.east => EntityFacing.west,
      Direction.west => EntityFacing.east,
    };
    actor.setMotion(npcFacing, CharacterAnimationState.idle);
  }

  /// Construit le runner cutscene MVP avec callbacks runtime concrets.
  ///
  /// Le runner reste découplé de Flame; `PlayableMapGame` lui injecte juste
  /// les opérations nécessaires.
  CutsceneRuntimeRunner _buildCutsceneRuntimeRunner() {
    return CutsceneRuntimeRunner(
      context: CutsceneRuntimeContext(
        openDialogue: (dialogueId, {startNode}) {
          return _openScenarioDialogueById(
            dialogueId,
            startNode: startNode,
            runtimeSourceId: 'cutscene',
          );
        },
        isDialogueOpen: () => _dialogueOverlay != null,
        requestChoice: (request) {
          _pendingCutsceneChoiceRequest = request;
          return true;
        },
        resolveCutsceneById: _findRuntimeCutsceneById,
        moveNpcTo: ({required entityId, required destination}) {
          return startScriptedNpcMove(
            entityId: entityId,
            destination: destination,
          );
        },
        readNpcMovementStatus: (entityId) {
          return scriptedNpcMovementStatus(entityId);
        },
        faceNpc: ({required entityId, required facing}) {
          return _setNpcFacing(entityId, facing);
        },
        emitOutcome: (outcomeId) {
          _emitCutsceneOutcome(outcomeId);
        },
        setFlag: (flagName) {
          _gameState = _storyFlags.set(_gameState, flagName);
          _refreshWorldNpcPresence();
        },
        clearFlag: (flagName) {
          _gameState = _storyFlags.clear(_gameState, flagName);
          _refreshWorldNpcPresence();
        },
        isFlagSet: (flagName) => _storyFlags.isSet(_gameState, flagName),
        isOutcomeSet: (outcomeId) =>
            _storyFlags.isSet(_gameState, scenarioOutcomeFlagName(outcomeId)),
      ),
    );
  }

  RuntimeCutsceneAsset? _findRuntimeCutsceneById(String cutsceneId) {
    final normalized = cutsceneId.trim();
    if (normalized.isEmpty) {
      return null;
    }
    for (final candidate in runtimeCutscenes) {
      if (candidate.id == normalized) {
        return candidate;
      }
    }
    return null;
  }

  /// Oriente explicitement un PNJ (étape `faceNpc` de cutscene).
  ///
  /// On met à jour:
  /// - l'acteur visuel (immédiat),
  /// - la map runtime en mémoire (facing npc), pour rester cohérent avec les
  ///   futures logiques gameplay lisant l'orientation d'entité.
  bool _setNpcFacing(String entityId, EntityFacing facing) {
    final loaded = _loadedMapsById[_activeMapId];
    final actor = loaded?.npcActorByEntityId[entityId];
    if (actor == null) {
      return false;
    }
    actor.setMotion(facing, CharacterAnimationState.idle);

    final entities = _world.map.entities;
    final index = entities.indexWhere((entity) => entity.id == entityId);
    if (index < 0) {
      return true;
    }
    final entity = entities[index];
    final npc = entity.npc;
    if (npc == null) {
      return true;
    }
    final updatedEntities = List<MapEntity>.from(entities);
    updatedEntities[index] = entity.copyWith(
      npc: npc.copyWith(facing: facing),
    );
    final updatedMap = _world.map.copyWith(entities: updatedEntities);
    _world = GameplayWorldState.initial(
      map: updatedMap,
      playerPos: _world.player.pos,
      playerFacing: _world.player.facing,
      playerMovementMode: _world.player.movementMode,
      project: _bundle.manifest,
      tileWidth: _bundle.manifest.settings.tileWidth,
      tileHeight: _bundle.manifest.settings.tileHeight,
      npcMapPresencePredicate: _npcPresencePredicateFor(_bundle.manifest),
    );
    _bundle = RuntimeMapBundle(
      manifest: _bundle.manifest,
      map: updatedMap,
      projectRootDirectory: _bundle.projectRootDirectory,
      tilesetAbsolutePathsById: _bundle.tilesetAbsolutePathsById,
    );
    return true;
  }

  /// Émet un outcome depuis une cutscene.
  ///
  /// MVP:
  /// 1) on persiste l'outcome comme flag `scenario.outcome.*`,
  /// 2) on tente une transition vers un scénario global via `sourceOutcome`.
  void _emitCutsceneOutcome(String outcomeId) {
    final normalized = outcomeId.trim();
    if (normalized.isEmpty) {
      return;
    }
    _gameState =
        _storyFlags.set(_gameState, scenarioOutcomeFlagName(normalized));
    _refreshWorldNpcPresence();
    _dispatchScenarioRuntimeSource(
      ScenarioRuntimeSourceEvent.outcomeReceived(
        outcomeId: normalized,
      ),
    );
  }

  /// (Re)crée le contrôleur de déplacement scripté pour la map active.
  ///
  /// Cette méthode est appelée:
  /// - au chargement initial,
  /// - après warp/connection/load game (changement de map).
  ///
  /// On repart à chaque fois d'un snapshot propre des PNJ actifs pour éviter
  /// toute dérive d'état entre maps.
  void _resetScriptedNpcMovementController() {
    _runtimeNpcPositions
      ..clear()
      ..addAll(_collectCurrentNpcPositions());
    _runtimeNpcPositions['player'] = _world.player.pos;
    _scriptedNpcReservedOccupiedCellsByEntity.clear();

    final controller = ScriptedEntityMovementController(
      mapSize: _world.map.size,
      isCellBlocked: _isNpcCellBlockedForRoutePlanning,
      startEntityStep: _startScriptedNpcStep,
      isEntityStepping: _isScriptedNpcStepping,
      onEntityPositionCommitted: _commitScriptedNpcPosition,
      validateEntityStep: _validateScriptedNpcStepRuntimeCollision,
    );
    controller.replaceTrackedEntities(_runtimeNpcPositions);
    _scriptedEntityMovementController = controller;
    _applyNpcOverworldDefaultMovement();
  }

  void _applyNpcOverworldDefaultMovement() {
    final controller = _scriptedEntityMovementController;
    if (controller == null) {
      return;
    }
    final pred = _npcPresencePredicateFor(_bundle.manifest);
    final mapId = _world.map.id;
    for (final entity in _world.map.entities) {
      if (entity.kind != MapEntityKind.npc) {
        continue;
      }
      if (!pred(mapId, entity)) {
        controller.stopPatrol(entity.id);
        continue;
      }
      final route = resolveNpcDefaultPatrolRoute(entity);
      if (route == null) {
        controller.stopPatrol(entity.id);
        continue;
      }
      controller.startPatrol(route);
    }
  }

  Map<String, GridPos> _collectCurrentNpcPositions() {
    final loaded = _loadedMapsById[_activeMapId];
    if (loaded == null) {
      return const <String, GridPos>{};
    }
    final pred = _npcPresencePredicateFor(_bundle.manifest);
    final mapId = _world.map.id;
    final byId = <String, GridPos>{};
    for (final entity in _world.map.entities) {
      if (entity.kind != MapEntityKind.npc) {
        continue;
      }
      if (!pred(mapId, entity)) {
        continue;
      }
      // On ne suit que les PNJ présents **et** encore montés en acteur.
      if (!loaded.npcActorByEntityId.containsKey(entity.id)) {
        continue;
      }
      byId[entity.id] = entity.pos;
    }
    return byId;
  }

  bool _isNpcCellBlockedForRoutePlanning(
    int x,
    int y, {
    String? ignoreEntityId,
  }) {
    final normalizedIgnore = ignoreEntityId?.trim();
    if (normalizedIgnore == null || normalizedIgnore.isEmpty) {
      return _world.isBlocked(x, y);
    }
    if (normalizedIgnore == 'player') {
      final mode = _world.player.movementMode;
      if (_world.movementBlockReasonAt(
            x: x,
            y: y,
            movementMode: mode,
          ) !=
          null) {
        return true;
      }
      for (final cell
          in _scriptedNpcDynamicBlockedCells(ignoreEntityId: 'player')) {
        if (cell.x == x && cell.y == y) {
          return true;
        }
      }
      return false;
    }

    // Pathfinding anchor validation:
    // - `x,y` est la position logique MapEntity.pos (top-left),
    // - on valide le footprint collision réel (important pour NPC 2x2),
    // - on ignore l'auto-collision de l'entité courante.
    final probe = evaluateScriptedNpcAnchorPassability(
      world: _world,
      entityId: normalizedIgnore,
      anchorPos: GridPos(x: x, y: y),
      movementMode: MovementMode.walk,
      dynamicBlockedCells: _scriptedNpcDynamicBlockedCells(
        ignoreEntityId: normalizedIgnore,
      ),
    );
    if (!probe.passable) {
      debugPrint(
        '[npc_patrol] blocked anchor entity=$normalizedIgnore anchor=($x,$y) reason="${probe.reason}" footprint=${probe.evaluatedCollisionCells.map((c) => '(${c.x},${c.y})').join(',')}',
      );
    }
    return !probe.passable;
  }

  String? _validateScriptedNpcStepRuntimeCollision({
    required String entityId,
    required GridPos from,
    required GridPos to,
  }) {
    if (entityId.trim() == 'player') {
      final mode = _world.player.movementMode;
      final block = _world.movementBlockReasonAt(
        x: to.x,
        y: to.y,
        movementMode: mode,
      );
      if (block != null) {
        debugPrint(
          '[npc_patrol] runtime step rejected entity=player from=(${from.x},${from.y}) to=(${to.x},${to.y}) reason=${block.name}',
        );
        return block.name;
      }
      for (final cell
          in _scriptedNpcDynamicBlockedCells(ignoreEntityId: 'player')) {
        if (cell.x == to.x && cell.y == to.y) {
          debugPrint(
            '[npc_patrol] runtime step rejected entity=player to=(${to.x},${to.y}) reason=dynamic_blocker',
          );
          return 'Dynamic blocker at destination.';
        }
      }
      return null;
    }
    final probe = evaluateScriptedNpcAnchorPassability(
      world: _world,
      entityId: entityId,
      anchorPos: to,
      movementMode: MovementMode.walk,
      dynamicBlockedCells: _scriptedNpcDynamicBlockedCells(
        ignoreEntityId: entityId,
      ),
    );
    if (!probe.passable) {
      debugPrint(
        '[npc_patrol] runtime step rejected entity=$entityId from=(${from.x},${from.y}) to=(${to.x},${to.y}) reason="${probe.reason}"',
      );
      return probe.reason;
    }
    return null;
  }

  /// Cellules dynamiques à bloquer pour un pas NPC scripté.
  ///
  /// Frontière conceptuelle:
  /// - collision "statique" (layers + entités map) => via GameplayWorldState;
  /// - collision "dynamique" hors map entities (joueur) => injectée ici.
  ///
  /// On inclut volontairement:
  /// 1) la cellule logique canonique du joueur (`_world.player.pos`);
  /// 2) la cellule visuelle actuelle au niveau des pieds du player pendant
  ///    l'interpolation de pas.
  ///
  /// Le point (2) évite les traversées visuelles quand la simulation logique a
  /// déjà commité un déplacement joueur mais que le sprite est encore en train
  /// d'animer son pas.
  Iterable<GridPos> _scriptedNpcDynamicBlockedCells({
    String? ignoreEntityId,
  }) sync* {
    final activeFollowLeader = _pendingScenarioFollowRequest?.leaderEntityId;
    final ignorePlayerForLeader = activeFollowLeader != null &&
        ignoreEntityId != null &&
        ignoreEntityId == activeFollowLeader;

    if (!ignorePlayerForLeader) {
      final canonical = _world.player.pos;
      yield canonical;

      final rendered = _renderedPlayerFootGridCell();
      if (rendered != null &&
          (rendered.x != canonical.x || rendered.y != canonical.y)) {
        yield rendered;
      }
    }

    // Réservations de destination des autres PNJ en cours de pas.
    for (final entry in _scriptedNpcReservedOccupiedCellsByEntity.entries) {
      if (ignoreEntityId != null && entry.key == ignoreEntityId) {
        continue;
      }
      yield* entry.value;
    }
  }

  GridPos? _renderedPlayerFootGridCell() {
    final origin = _player.mapOrigin;
    if (_cellWidth <= 0 || _cellHeight <= 0) {
      return null;
    }
    final foot = _player.footPoint;
    final cellX = ((foot.x - origin.x) / _cellWidth).floor();
    final cellY = ((foot.y - 1 - origin.y) / _cellHeight).floor();
    if (cellX < 0 ||
        cellY < 0 ||
        cellX >= _world.map.size.width ||
        cellY >= _world.map.size.height) {
      return null;
    }
    return GridPos(x: cellX, y: cellY);
  }

  bool _startScriptedNpcStep({
    required String entityId,
    required GridPos from,
    required GridPos to,
    required EntityFacing facing,
    double? durationSeconds,
  }) {
    if (entityId.trim() == 'player') {
      final walkFacing = _directionFromEntityFacing(facing);
      final nextState = _world.player.copyWith(pos: to, facing: walkFacing);
      _player.startStep(
        nextState,
        durationSeconds: durationSeconds ?? PlayerComponent.kDefaultStepSeconds,
      );
      _reserveScriptedNpcStepOccupiedCells(
        entityId: entityId,
        fromAnchorPos: from,
        toAnchorPos: to,
      );
      return true;
    }
    final loaded = _loadedMapsById[_activeMapId];
    final actor = loaded?.npcActorByEntityId[entityId];
    if (actor == null) {
      return false;
    }
    final started = actor.startGridStep(
      to: to,
      facing: facing,
      durationSeconds: durationSeconds ?? PlayerComponent.kDefaultStepSeconds,
    );
    if (!started) {
      _scriptedNpcReservedOccupiedCellsByEntity.remove(entityId);
      return false;
    }
    _reserveScriptedNpcStepOccupiedCells(
      entityId: entityId,
      fromAnchorPos: from,
      toAnchorPos: to,
    );
    return true;
  }

  bool _isScriptedNpcStepping(String entityId) {
    if (entityId.trim() == 'player') {
      return _player.isStepping;
    }
    final loaded = _loadedMapsById[_activeMapId];
    final actor = loaded?.npcActorByEntityId[entityId];
    return actor?.isStepping ?? false;
  }

  void _commitScriptedNpcPosition(String entityId, GridPos position) {
    if (entityId.trim() == 'player') {
      final from = _world.player.pos;
      final facing = _directionBetweenAdjacent(from: from, to: position) ??
          _world.player.facing;
      _world = _world.withPlayer(
        _world.player.copyWith(pos: position, facing: facing),
      );
      _runtimeNpcPositions['player'] = position;
      _scriptedNpcReservedOccupiedCellsByEntity.remove(entityId);
      _player.syncState(_world.player, snapToGrid: true);
      _syncGameStateFromWorld();
      return;
    }
    _runtimeNpcPositions[entityId] = position;
    _scriptedNpcReservedOccupiedCellsByEntity.remove(entityId);
    _world = _world.withEntityPosition(entityId, position);
  }

  bool _isCellReservedByScriptedNpc(GridPos cell) {
    for (final cells in _scriptedNpcReservedOccupiedCellsByEntity.values) {
      if (cells.contains(cell)) {
        return true;
      }
    }
    return false;
  }

  void _reserveScriptedNpcStepOccupiedCells({
    required String entityId,
    required GridPos fromAnchorPos,
    required GridPos toAnchorPos,
  }) {
    if (entityId.trim() == 'player') {
      _scriptedNpcReservedOccupiedCellsByEntity[entityId] = <GridPos>{
        GridPos(x: fromAnchorPos.x, y: fromAnchorPos.y),
        GridPos(x: toAnchorPos.x, y: toAnchorPos.y),
      };
      return;
    }
    final entity = _world.map.entities
        .where((candidate) => candidate.id == entityId)
        .cast<MapEntity?>()
        .firstWhere((candidate) => candidate != null, orElse: () => null);
    if (entity == null) {
      _scriptedNpcReservedOccupiedCellsByEntity.remove(entityId);
      return;
    }

    // Réservation "anti-traversée visuelle":
    // - footprint collision de la destination (cohérence gameplay stricte),
    // - footprint visuel grille du NPC sur source + destination (cohérence
    //   perceptuelle pendant l'interpolation visuelle du sprite).
    final reserved = <GridPos>{}
      ..addAll(_resolveEntityCollisionCellsAtAnchor(entity, toAnchorPos))
      ..addAll(_resolveEntityVisualCellsAtAnchor(entity, fromAnchorPos))
      ..addAll(_resolveEntityVisualCellsAtAnchor(entity, toAnchorPos));
    if (reserved.isEmpty) {
      _scriptedNpcReservedOccupiedCellsByEntity.remove(entityId);
      return;
    }
    _scriptedNpcReservedOccupiedCellsByEntity[entityId] = reserved;
  }

  Set<GridPos> _resolveEntityCollisionCellsAtAnchor(
    MapEntity entity,
    GridPos anchorPos,
  ) {
    final moved = entity.copyWith(pos: anchorPos);
    return resolveEntityCollisionCells(moved).where(_isInMapBounds).toSet();
  }

  Set<GridPos> _resolveEntityVisualCellsAtAnchor(
    MapEntity entity,
    GridPos anchorPos,
  ) {
    final cells = <GridPos>{};
    for (var dy = 0; dy < entity.size.height; dy++) {
      for (var dx = 0; dx < entity.size.width; dx++) {
        final cell = GridPos(
          x: anchorPos.x + dx,
          y: anchorPos.y + dy,
        );
        if (_isInMapBounds(cell)) {
          cells.add(cell);
        }
      }
    }
    return cells;
  }

  bool _isInMapBounds(GridPos cell) {
    return cell.x >= 0 &&
        cell.y >= 0 &&
        cell.x < _world.map.size.width &&
        cell.y < _world.map.size.height;
  }

  double get _cellWidth =>
      _bundle.manifest.settings.tileWidth *
      _bundle.manifest.settings.displayScale;

  double get _cellHeight =>
      _bundle.manifest.settings.tileHeight *
      _bundle.manifest.settings.displayScale;

  void _configureCameraViewport() {
    final cw = _bundle.cellWidth;
    final ch = _bundle.cellHeight;
    final mw = _bundle.map.size.width * cw;
    final mh = _bundle.map.size.height * ch;
    final vw = math.min(_kViewportTilesX * cw, mw);
    final vh = math.min(_kViewportTilesY * ch, mh);
    camera.viewfinder.visibleGameSize = Vector2(vw, vh);
  }

  void _syncCameraToPlayer() {
    if (!isLoaded) {
      return;
    }
    final focus = _player.focusPoint;
    camera.viewfinder.position = Vector2(
      focus.x.roundToDouble(),
      focus.y.roundToDouble(),
    );
  }
}

class _LoadedPlayableMap {
  _LoadedPlayableMap({
    required this.bundle,
    required this.originCellX,
    required this.originCellY,
    required this.backgroundLayers,
    required this.foregroundLayers,
    required this.npcActors,
    required this.npcActorByEntityId,
  });

  final RuntimeMapBundle bundle;
  final int originCellX;
  final int originCellY;
  final MapLayersComponent backgroundLayers;
  final MapLayersComponent foregroundLayers;
  final List<OverworldActorComponent> npcActors;
  final Map<String, OverworldActorComponent> npcActorByEntityId;
}

class _NpcCollisionDebugVisual {
  _NpcCollisionDebugVisual({
    required this.spriteRect,
    required this.collisionRect,
    required this.anchorMarker,
  });

  final RectangleComponent spriteRect;
  final RectangleComponent collisionRect;
  final CircleComponent anchorMarker;
}

class _GridCellPos {
  const _GridCellPos({
    required this.x,
    required this.y,
  });

  final int x;
  final int y;
}

class _PendingScenarioFollowRequest {
  _PendingScenarioFollowRequest({
    required this.leaderEntityId,
    required this.requestedAtMs,
  });

  final String leaderEntityId;
  final double requestedAtMs;
  GridPos? lastLeaderPos;
  Direction? lastLeaderTravelDirection;
  List<GridPos>? cachedPath;
  GridPos? cachedPathDestination;
  GridPos? cachedPathLeaderPos;
  int consecutiveBlockedSteps = 0;
}

class _PendingScenarioTransitionMapRequest {
  const _PendingScenarioTransitionMapRequest({
    required this.mapId,
    required this.warpId,
  });

  final String mapId;
  final String warpId;
}

class _PendingScenarioNpcWarpEntry {
  const _PendingScenarioNpcWarpEntry({
    required this.entityId,
    required this.warpId,
    required this.warpPos,
    required this.approachPos,
  });

  final String entityId;
  final String warpId;
  final GridPos warpPos;
  final GridPos approachPos;
}

class _PendingScenarioMoveContinuation {
  const _PendingScenarioMoveContinuation({
    required this.entityId,
    required this.runtimeSourceId,
    required this.targetKind,
  });

  final String entityId;
  final String runtimeSourceId;
  final String targetKind;
}

class _PendingScenarioReachedEnd {
  const _PendingScenarioReachedEnd({
    required this.scenarioId,
    required this.origin,
    required this.queuedAtMs,
  });

  final String scenarioId;
  final String origin;
  final double queuedAtMs;
}

class _FollowPathPlan {
  const _FollowPathPlan({
    required this.destination,
    required this.path,
  });

  final GridPos destination;
  final List<GridPos> path;
}

enum _WarpTransitionStyle {
  fade,
}

class _WarpTransitionSpec {
  const _WarpTransitionSpec({
    required this.style,
    required this.fadeOut,
    required this.fadeIn,
  });

  final _WarpTransitionStyle style;
  final Duration fadeOut;
  final Duration fadeIn;
}

```

### /Users/karim/Project/pokemonProject/packages/map_runtime/test/file_game_save_repository_test.dart

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
          seenSpeciesIds: ['pidgey'],
          caughtSpeciesIds: ['pidgey'],
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

      await repository.save(originalState);
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
      expect(
        loadedState.progression.seenSpeciesIds,
        containsAll(<String>['pidgey', 'squirtle']),
      );
      expect(
        loadedState.progression.caughtSpeciesIds,
        containsAll(<String>['pidgey', 'squirtle']),
      );
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

      await repository.save(originalState);
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

      final filePath = await repository.exposedSaveFilePath();
      final file = File(filePath);
      final content = await file.readAsString();
      final json = jsonDecode(content) as Map<String, dynamic>;

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

    test(
        'load migrates legacy party members and save rewrites normalized phase 9 data',
        () async {
      const originalState = GameState(
        saveId: 'legacy_phase_9',
        currentMapId: 'vova_center',
        playerPosition: GridPos(x: 4, y: 7),
        playerFacing: EntityFacing.west,
        party: PlayerParty(members: [
          PlayerPokemon(
            speciesId: 'lapras',
            natureId: 'modest',
            abilityId: 'water-absorb',
            level: 30,
            knownMoveIds: ['surf', 'ice_beam'],
            currentHp: 22,
          ),
        ]),
        trainerProfile: TrainerProfile(
          name: 'Leaf',
          badgeIds: ['cascade'],
          money: 1200,
          playtimeSeconds: 600,
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
      final legacyJson = originalState.toJson();
      final party = legacyJson['party'] as Map<String, dynamic>;
      final members = party['members'] as List<dynamic>;
      final member = members.single as Map<String, dynamic>;
      member
        ..remove('natureId')
        ..remove('abilityId')
        ..remove('ivs')
        ..remove('evs')
        ..remove('currentHp')
        ..remove('statusId')
        ..remove('isShiny')
        ..remove('heldItemId')
        ..['id'] = 'party_1'
        ..['nickname'] = 'Ferry'
        ..['isFainted'] = false;

      final projectFile = File('${testDirectory.path}/project.json');
      await projectFile.writeAsString('{"name":"test"}');

      final filePath = await repository.exposedSaveFilePath();
      final file = File(filePath);
      await file.writeAsString(
        const JsonEncoder.withIndent('  ').convert(legacyJson),
      );

      final loadedState = await repository.load();

      expect(loadedState, isNotNull);
      expect(loadedState!.party.members.single.speciesId, 'lapras');
      expect(loadedState.party.members.single.natureId, 'hardy');
      expect(loadedState.party.members.single.abilityId, 'unknown');
      expect(loadedState.party.members.single.currentHp, 1);
      expect(loadedState.progression.caughtSpeciesIds, contains('lapras'));
      expect(loadedState.progression.seenSpeciesIds, contains('lapras'));
      expect(
        loadedState.scriptVariables.values['rival_battles_won'],
        const ScriptVariableValue.int(3),
      );
      expect(
        loadedState.storyFlags.activeFlags,
        equals(originalState.storyFlags.activeFlags),
      );
      expect(
        loadedState.consumedEventIds,
        equals(originalState.consumedEventIds),
      );
      expect(loadedState.metadata, equals(originalState.metadata));

      await repository.save(loadedState);

      final normalizedJson =
          jsonDecode(await file.readAsString()) as Map<String, dynamic>;
      final normalizedParty = normalizedJson['party'] as Map<String, dynamic>;
      final normalizedMembers = normalizedParty['members'] as List<dynamic>;
      final normalizedMember = normalizedMembers.single as Map<String, dynamic>;

      expect(normalizedMember['speciesId'], 'lapras');
      expect(normalizedMember['natureId'], 'hardy');
      expect(normalizedMember['abilityId'], 'unknown');
      expect(normalizedMember['currentHp'], 1);
      expect(normalizedMember.containsKey('id'), isFalse);
      expect(normalizedMember.containsKey('nickname'), isFalse);
      expect(normalizedMember.containsKey('isFainted'), isFalse);
      expect(await projectFile.readAsString(), '{"name":"test"}');
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

    test('corrupt load fails and does not rewrite save or project.json',
        () async {
      final projectFile = File('${testDirectory.path}/project.json');
      await projectFile.writeAsString('{"name":"test"}');

      final filePath = await repository.exposedSaveFilePath();
      final file = File(filePath);
      const corruptContent = '''
{
  "saveId": "broken_save",
  "currentMapId": "vova_center",
  "party": {
    "members": [
      {
        "speciesId": "lapras",
        "knownMoveIds": ["surf"]
      }
    ]
  }
}
''';
      await file.writeAsString(corruptContent);

      await expectLater(
        () => repository.load(),
        throwsA(isA<GameSaveException>()),
      );

      expect(await file.readAsString(), corruptContent);
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

### /Users/karim/Project/pokemonProject/packages/map_runtime/test/wild_battle_end_to_end_flow_test.dart

```dart
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_battle/map_battle.dart';
import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:map_runtime/src/application/battle_start_request.dart';
import 'package:map_runtime/src/application/encounter_to_battle_request.dart';
import 'package:map_runtime/src/application/runtime_battle_outcome_apply.dart';
import 'package:map_runtime/src/application/runtime_battle_setup_mapper.dart';
import 'package:map_runtime/src/application/runtime_map_bundle.dart';
import 'package:path/path.dart' as p;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('wild battle runtime flow lot 11', () {
    late Directory tempProjectRoot;
    const mapper = RuntimeBattleSetupMapper();

    setUp(() async {
      tempProjectRoot =
          await Directory.systemTemp.createTemp('wild_battle_flow_');
    });

    tearDown(() async {
      if (await tempProjectRoot.exists()) {
        await tempProjectRoot.delete(recursive: true);
      }
    });

    test('real wild encounter chain resolves to victory and writes back hp',
        () async {
      final manifest = await _writeProjectManifest(tempProjectRoot);
      final map = _buildMap();

      // On part bien du vrai chemin overworld minimal :
      // 1. world gameplay avec spawn réel
      // 2. déplacement d'une case vers une zone de rencontre
      // 3. check de rencontre sur la case atteinte
      final initialWorld = GameplayWorldState.fromMap(
        map,
        project: manifest,
        tileWidth: 16,
        tileHeight: 16,
      );
      final stepResult = stepGameplayWorld(
        initialWorld,
        const MoveIntent(Direction.east),
      );
      expect(stepResult, isA<Moved>());
      final movedWorld = stepResult.world;
      expect(movedWorld.player.pos, const GridPos(x: 1, y: 0));

      final encounterCheck = checkEncounterAtPlayerPosition(
        world: movedWorld,
        project: manifest,
        encounterKind: EncounterKind.walk,
        random: _FixedEncounterRandom(
          nextDoubleValues: const <double>[0.0],
          nextIntValues: const <int>[0, 0],
        ),
        policy: const GameplayEncounterPolicy(chancePerStep: 1),
      );

      expect(encounterCheck.triggered, isTrue);
      final encounter = encounterCheck.encounter!;
      expect(encounter.speciesId, equals('sparkitten'));
      expect(encounter.level, equals(6));

      final request = buildBattleStartRequestFromEncounter(
        encounter: encounter,
        world: movedWorld,
        createdAtEpochMs: 1,
      );
      expect(request.kind, equals(RuntimeBattleKind.wild));
      expect(request.source, equals(RuntimeBattleSourceKind.encounterZone));

      final setup = await mapper.map(
        bundle: _buildBundle(tempProjectRoot.path, manifest, map),
        gameState: _playerState(),
        request: request,
      );
      final stateWithSeen = markSpeciesSeenInGameState(
          _playerState(), setup.enemyPokemon.speciesId);
      expect(stateWithSeen.progression.seenSpeciesIds, contains('sparkitten'));
      expect(
        stateWithSeen.progression.caughtSpeciesIds,
        isNot(contains('sparkitten')),
      );

      final session = createBattleSession(setup);
      final afterTurn1 = session.applyChoice(const PlayerBattleChoiceFight(0));
      expect(afterTurn1.state.isFinished, isFalse);
      final afterTurn2 =
          afterTurn1.applyChoice(const PlayerBattleChoiceFight(0));
      expect(afterTurn2.state.outcome, isNotNull);
      expect(afterTurn2.state.outcome!.isVictory, isTrue);

      final updatedState = applyRuntimeBattleOutcomeToGameState(
        gameState: stateWithSeen,
        context: const RuntimeActiveBattleContext(
          request: WildBattleStartRequest(
            requestId: 'wild-request',
            createdAtEpochMs: 1,
            returnContext: OverworldReturnContext(
              mapId: 'field_map',
              playerPos: GridPos(x: 1, y: 0),
              playerFacing: Direction.east,
            ),
            mapId: 'field_map',
            zoneId: 'encounter_grass',
            tableId: 'field_grass',
            encounterKind: EncounterKind.walk,
            speciesId: 'sparkitten',
            level: 6,
            minLevel: 6,
            maxLevel: 6,
            weight: 1,
            playerPos: GridPos(x: 1, y: 0),
          ),
          playerPartyIndex: 0,
        ),
        outcome: afterTurn2.state.outcome!,
      );

      expect(updatedState.party.members.first.currentHp, equals(15));
      expect(updatedState.progression.seenSpeciesIds, contains('sparkitten'));
      expect(
        updatedState.progression.caughtSpeciesIds,
        isNot(contains('sparkitten')),
      );
      expect(updatedState.storyFlags.activeFlags, isEmpty);
    });

    test('run choice produces a real runaway outcome without trainer flags',
        () async {
      final manifest = await _writeProjectManifest(tempProjectRoot);
      final map = _buildMap();
      final world = GameplayWorldState.fromMap(
        map,
        project: manifest,
        tileWidth: 16,
        tileHeight: 16,
      );
      final movedWorld = stepGameplayWorld(
        world,
        const MoveIntent(Direction.east),
      ).world;
      final encounter = checkEncounterAtPlayerPosition(
        world: movedWorld,
        project: manifest,
        encounterKind: EncounterKind.walk,
        random: _FixedEncounterRandom(
          nextDoubleValues: const <double>[0.0],
          nextIntValues: const <int>[0, 0],
        ),
        policy: const GameplayEncounterPolicy(chancePerStep: 1),
      ).encounter!;
      final request = buildBattleStartRequestFromEncounter(
        encounter: encounter,
        world: movedWorld,
        createdAtEpochMs: 1,
      );

      final setup = await mapper.map(
        bundle: _buildBundle(tempProjectRoot.path, manifest, map),
        gameState: _playerState(),
        request: request,
      );
      final stateWithSeen = markSpeciesSeenInGameState(
          _playerState(), setup.enemyPokemon.speciesId);

      final outcome = createBattleSession(setup)
          .applyChoice(const PlayerBattleChoiceRun())
          .state
          .outcome!;
      expect(outcome.isRunaway, isTrue);

      final updatedState = applyRuntimeBattleOutcomeToGameState(
        gameState: stateWithSeen,
        context: RuntimeActiveBattleContext(
          request: request,
          playerPartyIndex: 0,
        ),
        outcome: outcome,
      );

      expect(updatedState.party.members.first.currentHp, equals(20));
      expect(updatedState.progression.seenSpeciesIds, contains('sparkitten'));
      expect(
        updatedState.progression.caughtSpeciesIds,
        isNot(contains('sparkitten')),
      );
      expect(updatedState.storyFlags.activeFlags, isEmpty);
    });
  });
}

GameState _playerState() {
  return const GameState(
    saveId: 'wild-flow-save',
    party: PlayerParty(
      members: <PlayerPokemon>[
        PlayerPokemon(
          speciesId: 'sproutle',
          natureId: 'bold',
          abilityId: 'overgrow',
          level: 10,
          knownMoveIds: <String>['vine_whip'],
          currentHp: 20,
        ),
      ],
    ),
  );
}

MapData _buildMap() {
  return const MapData(
    id: 'field_map',
    name: 'Field Map',
    size: GridSize(width: 4, height: 3),
    layers: <MapLayer>[
      MapLayer.object(id: 'objects', name: 'Objects'),
    ],
    entities: <MapEntity>[
      MapEntity(
        id: 'spawn_start',
        name: 'Spawn Start',
        kind: MapEntityKind.spawn,
        pos: GridPos(x: 0, y: 0),
        blocksMovement: false,
        spawn: MapEntitySpawnData(
          role: EntitySpawnRole.playerStart,
          facing: EntityFacing.east,
        ),
      ),
    ],
    gameplayZones: <MapGameplayZone>[
      MapGameplayZone(
        id: 'encounter_grass',
        name: 'Encounter Grass',
        kind: GameplayZoneKind.encounter,
        area: MapRect(
          pos: GridPos(x: 1, y: 0),
          size: GridSize(width: 1, height: 1),
        ),
        encounter: EncounterZonePayload(
          encounterTableId: 'field_grass',
          encounterKind: EncounterKind.walk,
        ),
      ),
    ],
    mapMetadata: MapMetadata(
      defaultSpawnId: 'spawn_start',
    ),
  );
}

RuntimeMapBundle _buildBundle(
  String projectRootDirectory,
  ProjectManifest manifest,
  MapData map,
) {
  return RuntimeMapBundle(
    manifest: manifest,
    map: map,
    projectRootDirectory: projectRootDirectory,
    tilesetAbsolutePathsById: const <String, String>{},
  );
}

Future<ProjectManifest> _writeProjectManifest(Directory projectRoot) async {
  const manifest = ProjectManifest(
    name: 'Wild Battle Flow Test',
    maps: <ProjectMapEntry>[
      ProjectMapEntry(
        id: 'field_map',
        name: 'Field Map',
        relativePath: 'maps/field_map.json',
      ),
    ],
    tilesets: <ProjectTilesetEntry>[],
    encounterTables: <ProjectEncounterTable>[
      ProjectEncounterTable(
        id: 'field_grass',
        name: 'Field Grass',
        encounterKind: EncounterKind.walk,
        entries: <ProjectEncounterEntry>[
          ProjectEncounterEntry(
            speciesId: 'sparkitten',
            minLevel: 6,
            maxLevel: 6,
            weight: 1,
          ),
        ],
      ),
    ],
    pokemon: ProjectPokemonConfig(
      dataRoot: 'data/pokemon',
      speciesDir: 'data/pokemon/species',
      learnsetsDir: 'data/pokemon/learnsets',
      evolutionsDir: 'data/pokemon/evolutions',
      mediaDir: 'data/pokemon/media',
      catalogFiles: <String, String>{
        'moves': 'data/pokemon/catalogs/moves.json',
      },
    ),
  );

  await File(
    p.join(projectRoot.path, 'project.json'),
  ).writeAsString(
      const JsonEncoder.withIndent('  ').convert(manifest.toJson()));
  await _writePokemonFixtures(projectRoot);
  return manifest;
}

Future<void> _writePokemonFixtures(Directory projectRoot) async {
  await _writeProjectRelativeJson(
    projectRoot,
    'data/pokemon/species/001-sproutle.json',
    <String, dynamic>{
      'id': 'sproutle',
      'slug': 'sproutle',
      'nationalDex': 1,
      'names': <String, String>{'en': 'Sproutle'},
      'speciesName': <String, String>{'en': 'Seedling'},
      'genIntroduced': 1,
      'typing': <String, Object>{
        'types': <String>['grass'],
      },
      'baseStats': <String, int>{
        'hp': 45,
        'atk': 49,
        'def': 49,
        'spa': 65,
        'spd': 65,
        'spe': 45,
        'bst': 318,
      },
      'abilities': <String, String>{'primary': 'overgrow'},
      'breeding': <String, Object>{
        'genderRatio': <String, double>{'male': 0.875, 'female': 0.125},
        'eggGroups': <String>['monster', 'grass'],
        'hatchCycles': 20,
      },
      'progression': <String, Object>{
        'growthRateId': 'medium_slow',
        'baseExp': 64,
        'catchRate': 45,
        'baseFriendship': 50,
      },
      'refs': <String, String>{
        'learnset': 'sproutle',
        'evolution': 'sproutle',
        'media': 'sproutle',
      },
      'dexContent': <String, Object>{
        'heightM': 0.7,
        'weightKg': 6.9,
      },
      'gameplayFlags': <String, bool>{'starterEligible': true},
      'sourceMeta': <String, Object>{'seededBy': 'test', 'seedVersion': 1},
    },
  );

  await _writeProjectRelativeJson(
    projectRoot,
    'data/pokemon/species/004-sparkitten.json',
    <String, dynamic>{
      'id': 'sparkitten',
      'slug': 'sparkitten',
      'nationalDex': 4,
      'names': <String, String>{'en': 'Sparkitten'},
      'speciesName': <String, String>{'en': 'Ember Cat'},
      'genIntroduced': 1,
      'typing': <String, Object>{
        'types': <String>['fire'],
      },
      'baseStats': <String, int>{
        'hp': 35,
        'atk': 52,
        'def': 43,
        'spa': 60,
        'spd': 50,
        'spe': 65,
        'bst': 305,
      },
      'abilities': <String, String>{'primary': 'blaze'},
      'breeding': <String, Object>{
        'genderRatio': <String, double>{'male': 0.875, 'female': 0.125},
        'eggGroups': <String>['field'],
        'hatchCycles': 20,
      },
      'progression': <String, Object>{
        'growthRateId': 'medium_slow',
        'baseExp': 62,
        'catchRate': 45,
        'baseFriendship': 50,
      },
      'refs': <String, String>{
        'learnset': 'sparkitten',
        'evolution': 'sparkitten',
        'media': 'sparkitten',
      },
      'dexContent': <String, Object>{
        'heightM': 0.6,
        'weightKg': 8.5,
      },
      'sourceMeta': <String, Object>{'seededBy': 'test', 'seedVersion': 1},
    },
  );

  await _writeProjectRelativeJson(
    projectRoot,
    'data/pokemon/learnsets/sproutle.json',
    <String, dynamic>{
      'startingMoves': <String>['vine_whip'],
      'relearnMoves': <String>[],
      'levelUp': <Map<String, Object>>[],
    },
  );

  await _writeProjectRelativeJson(
    projectRoot,
    'data/pokemon/learnsets/sparkitten.json',
    <String, dynamic>{
      'startingMoves': <String>['scratch'],
      'relearnMoves': <String>[],
      'levelUp': <Map<String, Object>>[],
    },
  );

  await _writeProjectRelativeJson(
    projectRoot,
    'data/pokemon/catalogs/moves.json',
    <String, dynamic>{
      'schemaVersion': 1,
      'kind': 'pokemon_catalog',
      'catalog': 'moves',
      'meta': <String, Object>{
        'description': 'Wild battle flow test move catalog',
      },
      'entries': <Map<String, Object?>>[
        _moveEntry('vine_whip', 'Vine Whip', 12),
        _moveEntry('scratch', 'Scratch', 5),
      ],
    },
  );
}

Map<String, Object?> _moveEntry(String id, String name, int power) {
  return <String, Object?>{
    'id': id,
    'name': name,
    'type': 'normal',
    'category': power == 0 ? 'status' : 'physical',
    'power': power == 0 ? null : power,
    'pp': 35,
  };
}

Future<void> _writeProjectRelativeJson(
  Directory projectRoot,
  String relativePath,
  Map<String, dynamic> json,
) async {
  final file = File(p.join(projectRoot.path, relativePath));
  await file.parent.create(recursive: true);
  await file.writeAsString(const JsonEncoder.withIndent('  ').convert(json));
}

class _FixedEncounterRandom implements Random {
  _FixedEncounterRandom({
    required this.nextDoubleValues,
    required this.nextIntValues,
  });

  final List<double> nextDoubleValues;
  final List<int> nextIntValues;
  int _doubleIndex = 0;
  int _intIndex = 0;

  @override
  bool nextBool() => false;

  @override
  double nextDouble() {
    if (nextDoubleValues.isEmpty) {
      return 0.0;
    }
    final index = _doubleIndex < nextDoubleValues.length
        ? _doubleIndex++
        : nextDoubleValues.length - 1;
    return nextDoubleValues[index];
  }

  @override
  int nextInt(int max) {
    if (max <= 0) {
      throw ArgumentError.value(max, 'max', 'must be > 0');
    }
    if (nextIntValues.isEmpty) {
      return 0;
    }
    final index = _intIndex < nextIntValues.length
        ? _intIndex++
        : nextIntValues.length - 1;
    return nextIntValues[index] % max;
  }
}

```
