# P5-06 — Capture Destination Party-or-Box V0

## 1. Résumé exécutif

P5-06 est implémenté.

Le lot ferme le cas critique :

```text
capture réussie
-> party si place disponible
-> storage minimal persistant si party pleine
-> caught/seen synchronisés
-> SaveData roundtrip
```

Le changement reste borné :

- ajout d'un `PokemonStorage` minimal dans `map_core` ;
- ajout du champ `pokemonStorage` à `SaveData` et `GameState` ;
- ajout de `GameStateMutations.applyCapturedPokemon(...)` dans `map_gameplay` ;
- branchement runtime minimal du write-back capture vers cette opération ;
- pas de PC UI, pas de box UI, pas de menu storage, pas de capture formula
  complète.

## 2. Scope du lot

Inclus :

- destination party quand `party.length < maxPartySize` ;
- destination storage quand la party est pleine ;
- `CaptureDestinationResult` testable ;
- progression `seenSpeciesIds` / `caughtSpeciesIds` synchronisée depuis party
  et storage ;
- roundtrip `SaveData` ;
- runtime capture : capture encore autorisée si party pleine et Poké Ball
  disponible ;
- tests purs et tests runtime ciblés.

Exclus :

- UI PC / box / storage ;
- menu PC complet ;
- nickname / summary screen ;
- animation ou formule de capture complète ;
- types de Balls complets ;
- rewards / money / XP supplémentaires ;
- moves learned / évolution ;
- Boot Flow ;
- Selbrume.

## 3. Sources lues

Sources principales :

- `pokemap_roadmap_mecaniques_fangame.md`
- `skills/README.md`
- `MVP Selbrume/road_map_global.md`
- `MVP Selbrume/road_map_phase_5.md`
- `reports/roadmap/phase_5/p5_05_battle_rewards_money_xp_minimal_apply.md`
- `packages/map_core/lib/src/models/save_data.dart`
- `packages/map_core/lib/src/models/game_state.dart`
- `packages/map_core/lib/src/operations/game_state_persistence.dart`
- `packages/map_core/test/save_data_test.dart`
- `packages/map_core/test/game_state_persistence_test.dart`
- `packages/map_gameplay/lib/src/game_state_mutations.dart`
- `packages/map_gameplay/lib/map_gameplay.dart`
- `packages/map_gameplay/test/battle_reward_operations_test.dart`
- `packages/map_runtime/lib/src/application/runtime_battle_outcome_apply.dart`
- `packages/map_runtime/lib/src/application/runtime_battle_setup_mapper.dart`
- `packages/map_runtime/test/runtime_battle_outcome_apply_test.dart`
- `packages/map_runtime/test/runtime_battle_setup_mapper_test.dart`
- `packages/map_runtime/test/wild_battle_end_to_end_flow_test.dart`

## 4. État initial capture / party / storage

Avant P5-06 :

- `PlayerParty` existait.
- `PlayerPokemon` existait et roundtrippait.
- `PlayerProgression` portait déjà `seenSpeciesIds` et `caughtSpeciesIds`.
- `normalizeLoadedGameState(...)` synchronisait déjà la party vers caught/seen.
- Aucun stockage Pokémon persistant n'existait.
- Le runtime capture ajoutait le Pokémon à la party si possible.
- Le runtime rejetait explicitement une capture si la party était pleine.
- `RuntimeBattleSetupMapper` désactivait la capture si la party était pleine.

Conclusion d'audit :

```text
Le cas party pleine ne pouvait pas être fermé sans ajouter un stockage minimal
persistant. Une liste locale ou metadata string aurait menti sur la preuve.
```

## 5. Modèle ou opération ajoutée

Modèle minimal ajouté dans `map_core` :

```dart
@freezed
class PokemonStorage with _$PokemonStorage {
  const PokemonStorage._();

  @JsonSerializable(explicitToJson: true)
  const factory PokemonStorage({
    @Default([]) List<PlayerPokemon> storedPokemon,
  }) = _PokemonStorage;

  factory PokemonStorage.fromJson(Map<String, dynamic> json) =>
      _$PokemonStorageFromJson(json);

  PokemonStorage normalized() => copyWith(
        storedPokemon: storedPokemon
            .map((member) => member.normalized())
            .toList(growable: false),
      );
}
```

Champs ajoutés :

```dart
@Default(PokemonStorage()) PokemonStorage pokemonStorage
```

dans :

- `GameState`
- `SaveData`

API ajoutée dans `map_gameplay` :

```dart
enum CaptureDestinationKind {
  none,
  party,
  storage,
}

class CaptureDestinationResult {
  const CaptureDestinationResult({
    required this.state,
    required this.destination,
    this.partyIndex,
    this.storageIndex,
  });

  const CaptureDestinationResult.none(GameState state)
      : this(
          state: state,
          destination: CaptureDestinationKind.none,
        );

  const CaptureDestinationResult.party({
    required GameState state,
    required int partyIndex,
  }) : this(
          state: state,
          destination: CaptureDestinationKind.party,
          partyIndex: partyIndex,
        );

  const CaptureDestinationResult.storage({
    required GameState state,
    required int storageIndex,
  }) : this(
          state: state,
          destination: CaptureDestinationKind.storage,
          storageIndex: storageIndex,
        );

  final GameState state;
  final CaptureDestinationKind destination;
  final int? partyIndex;
  final int? storageIndex;
}
```

Opération ajoutée :

```dart
CaptureDestinationResult applyCapturedPokemon(
  GameState state, {
  required PlayerPokemon pokemon,
  int maxPartySize = 6,
})
```

## 6. Destination party

Comportement prouvé :

- `speciesId` trimé ;
- si party non pleine, ajout en fin de party ;
- `partyIndex` retourné ;
- storage inchangé ;
- caught/seen synchronisés.

Test :

```text
adds the captured pokemon to party when there is room
```

## 7. Destination storage

Comportement prouvé :

- si party pleine, party reste à `maxPartySize` ;
- Pokémon ajouté dans `pokemonStorage.storedPokemon` ;
- `storageIndex` retourné ;
- storage existant conservé et appendé ;
- aucun système de box nommé, PC UI, capacité ou tri premium ajouté.

Tests :

```text
sends the captured pokemon to storage when party is full
appends to existing storage and reports the storage index
```

## 8. Progression seen/caught

`game_state_persistence.dart` synchronise maintenant les espèces possédées via :

- party ;
- storage minimal.

Cela conserve l'invariant existant :

```text
caught implique seen
```

Tests :

```text
updates caught and seen for party and storage destinations
syncs stored species into caught and seen for persistence
```

## 9. Runtime capture existante

Réponses audit :

1. Le runtime ajoutait déjà le Pokémon capturé à la party.
2. Le runtime consommait déjà une Poké Ball au write-back.
3. Le runtime marquait seen/caught via normalisation party -> caught/seen.
4. Si party pleine, le runtime rejetait la capture.
5. P5-06 branche maintenant le runtime sur `applyCapturedPokemon(...)`.

Changement runtime borné :

- `RuntimeBattleSetupMapper` autorise la capture sauvage si une Poké Ball est
  disponible, même si la party est pleine ;
- `applyRuntimeBattleOutcomeToGameState(...)` consomme la Poké Ball puis délègue
  la destination à `GameStateMutations.applyCapturedPokemon(...)`.

Pas de modification `map_battle`.

## 10. Persistence roundtrip

Roundtrip prouvé :

```text
GameState avec party + storage
-> applyCapturedPokemon(...)
-> saveDataFromGameState(...)
-> gameStateFromSaveData(...)
-> normalizeLoadedGameState(...)
-> party / storage / caught / seen conservés
```

## 11. Ce qui est prouvé

P5-06 prouve :

- capture vers party quand il reste une place ;
- capture vers storage quand la party est pleine ;
- party max size respectée par paramètre `maxPartySize`, défaut `6` ;
- résultat de destination testable ;
- storage persistant via `SaveData` ;
- caught/seen mis à jour pour party et storage ;
- runtime capture ne rejette plus brutalement party pleine ;
- tests ciblés et régressions passent ;
- aucun id Selbrume hardcodé.

## 12. Ce qui n’est pas prouvé

Non prouvé volontairement :

- PC UI ;
- box UI ;
- choix de box ;
- noms de boîtes ;
- déplacement / retrait depuis storage ;
- nickname screen ;
- summary screen ;
- capture formula complète ;
- Poké Ball types complets ;
- storage capacity ;
- migration de vieux fichiers disque réels hors compatibilité des defaults
  JSON générés.

## 13. Limites et reports vers P5-07 / P5-08 / P5-09

Reports :

- P5-07 : roundtrip gameplay bêta complet incluant storage, party, bag, money,
  capture et rewards.
- P5-08 : smoke runtime New Game -> Battle -> Reward -> Save/Load.
- P5-09 : validator bêta pour party pleine, storage présent, capture possible,
  Poké Ball disponible et projet lançable.

## 14. Tests exécutés

Test rouge initial :

```text
cd packages/map_gameplay && dart test test/capture_destination_operations_test.dart

00:00 +0: loading test/capture_destination_operations_test.dart
00:00 +0 -1: loading test/capture_destination_operations_test.dart [E]
Failed to load "test/capture_destination_operations_test.dart":
Error: Method not found: 'PokemonStorage'.
Error: No named parameter with the name 'pokemonStorage'.
Error: Undefined name 'CaptureDestinationKind'.
Error: The method 'applyCapturedPokemon' isn't defined for the type 'GameStateMutations'.
00:00 +0 -1: Some tests failed.
```

Test ciblé final :

```text
cd packages/map_gameplay && dart test test/capture_destination_operations_test.dart

00:00 +0: loading test/capture_destination_operations_test.dart
00:00 +0: GameStateMutations.applyCapturedPokemon adds the captured pokemon to party when there is room
00:00 +1: GameStateMutations.applyCapturedPokemon sends the captured pokemon to storage when party is full
00:00 +2: GameStateMutations.applyCapturedPokemon appends to existing storage and reports the storage index
00:00 +3: GameStateMutations.applyCapturedPokemon blank speciesId is a safe no-op
00:00 +4: GameStateMutations.applyCapturedPokemon preserves map, position, bag, money, flags and metadata
00:00 +5: GameStateMutations.applyCapturedPokemon updates caught and seen for party and storage destinations
00:00 +6: GameStateMutations.applyCapturedPokemon round-trips party and storage captures through SaveData
00:00 +7: GameStateMutations.applyCapturedPokemon does not hardcode any Selbrume ids
00:00 +8: All tests passed!
```

Régressions principales :

```text
cd packages/map_gameplay && dart test test/battle_reward_operations_test.dart
00:00 +10: All tests passed!

cd packages/map_gameplay && dart test test/party_bag_heal_operations_test.dart
00:00 +11: All tests passed!

cd packages/map_gameplay && dart test test/new_game_initial_party_test.dart
00:00 +9: All tests passed!

cd packages/map_core && dart test test/game_state_persistence_test.dart
00:00 +8: All tests passed!

cd packages/map_core && dart test test/save_data_test.dart
00:00 +25: All tests passed!

cd packages/map_runtime && flutter test test/runtime_battle_outcome_apply_test.dart
00:00 +14: All tests passed!

cd packages/map_runtime && flutter test test/runtime_battle_setup_mapper_test.dart
00:00 +26: All tests passed!

cd packages/map_runtime && flutter test test/wild_battle_end_to_end_flow_test.dart
00:00 +12: All tests passed!
```

Analyze :

```text
cd packages/map_gameplay && dart analyze
Analyzing map_gameplay...
No issues found!

cd packages/map_core && dart analyze
Analyzing map_core...
No issues found!
```

Runtime analyze :

```text
cd packages/map_runtime && flutter analyze
Analyzing map_runtime...
352 issues found. (ran in 3.2s)
```

Ces 352 issues sont des infos préexistantes `prefer_const`, imports relatifs de
tests Step Studio et noms locaux commençant par `_`. Elles ne sont pas ouvertes
par P5-06. Une passe non fatale confirme l'absence d'erreur bloquante :

```text
cd packages/map_runtime && flutter analyze --no-fatal-infos
Analyzing map_runtime...
352 issues found. (ran in 1.9s)
exit code 0
```

Format :

```text
cd packages/map_gameplay && dart format --set-exit-if-changed lib/src/game_state_mutations.dart lib/map_gameplay.dart test/capture_destination_operations_test.dart
Formatted 3 files (0 changed) in 0.01 seconds.

cd packages/map_core && dart format --set-exit-if-changed lib/src/models/save_data.dart lib/src/models/game_state.dart lib/src/operations/game_state_persistence.dart test/game_state_persistence_test.dart test/save_data_test.dart
Formatted 5 files (0 changed) in 0.02 seconds.

cd packages/map_runtime && dart format --set-exit-if-changed lib/src/application/runtime_battle_outcome_apply.dart lib/src/application/runtime_battle_setup_mapper.dart test/runtime_battle_outcome_apply_test.dart test/runtime_battle_setup_mapper_test.dart test/wild_battle_end_to_end_flow_test.dart
Formatted 5 files (0 changed) in 0.03 seconds.
```

Build runner :

```text
cd packages/map_core && dart run build_runner build --delete-conflicting-outputs
Built with build_runner in 9s; wrote 6 outputs.
```

Warnings observés pendant build runner :

```text
W SDK language version 3.11.0 is newer than `analyzer` language version 3.9.0. Run `dart pub upgrade`.
W json_serializable on lib/src/models/game_state.dart:
  The version constraint "^4.8.1" on json_annotation allows versions before 4.9.0 which is not allowed.
```

## 15. Modifications effectuées

Fichiers créés :

- `packages/map_gameplay/test/capture_destination_operations_test.dart`
- `reports/roadmap/phase_5/p5_06_capture_destination_party_or_box.md`

Fichiers modifiés :

- `MVP Selbrume/road_map_phase_5.md`
- `packages/map_core/lib/src/models/save_data.dart`
- `packages/map_core/lib/src/models/save_data.freezed.dart`
- `packages/map_core/lib/src/models/save_data.g.dart`
- `packages/map_core/lib/src/models/game_state.dart`
- `packages/map_core/lib/src/models/game_state.freezed.dart`
- `packages/map_core/lib/src/models/game_state.g.dart`
- `packages/map_core/lib/src/operations/game_state_persistence.dart`
- `packages/map_core/test/save_data_test.dart`
- `packages/map_core/test/game_state_persistence_test.dart`
- `packages/map_gameplay/lib/map_gameplay.dart`
- `packages/map_gameplay/lib/src/game_state_mutations.dart`
- `packages/map_runtime/lib/src/application/runtime_battle_outcome_apply.dart`
- `packages/map_runtime/lib/src/application/runtime_battle_setup_mapper.dart`
- `packages/map_runtime/test/runtime_battle_outcome_apply_test.dart`
- `packages/map_runtime/test/runtime_battle_setup_mapper_test.dart`
- `packages/map_runtime/test/wild_battle_end_to_end_flow_test.dart`

## 16. Evidence Pack

### git status initial exact

Commande :

```bash
git status --short --untracked-files=all
```

Sortie exacte :

```text
```

### Commandes exécutées

Commandes obligatoires et utiles exécutées :

```bash
git status --short --untracked-files=all
sed -n '1,360p' "MVP Selbrume/road_map_global.md"
sed -n '1,1080p' "MVP Selbrume/road_map_phase_5.md"
sed -n '1,320p' reports/roadmap/phase_5/p5_05_battle_rewards_money_xp_minimal_apply.md
sed -n '1,520p' packages/map_gameplay/lib/src/game_state_mutations.dart
sed -n '1,260p' packages/map_gameplay/lib/map_gameplay.dart
sed -n '1,320p' packages/map_gameplay/test/battle_reward_operations_test.dart
sed -n '1,520p' packages/map_core/lib/src/models/save_data.dart
sed -n '1,320p' packages/map_core/lib/src/models/game_state.dart
sed -n '1,320p' packages/map_core/lib/src/operations/game_state_persistence.dart
sed -n '1,460p' packages/map_runtime/lib/src/application/runtime_battle_outcome_apply.dart
rg -n "capture|captured|caught|seen|party full|partyFull|box|storage|PC|PokemonStorage|PlayerPokemon|PlayerParty|caughtSpeciesIds|seenSpeciesIds|markSpecies|normalizeLoadedGameState|runtime_battle_outcome_apply|poke-ball|pokeball" packages/map_core packages/map_gameplay packages/map_runtime packages/map_battle --glob '!build/**' --glob '!**/.dart_tool/**'
find packages/map_gameplay/test -maxdepth 2 -type f | sort | rg "capture|box|storage|party|pokemon|battle|reward"
find packages/map_runtime/test -maxdepth 3 -type f | sort | rg "capture|box|storage|party|battle|wild"
find packages/map_core/test -maxdepth 2 -type f | sort | rg "game_state|save|pokemon|party|caught|seen|storage"
cd packages/map_core && dart run build_runner build --delete-conflicting-outputs
cd packages/map_gameplay && dart test test/capture_destination_operations_test.dart
cd packages/map_gameplay && dart test test/battle_reward_operations_test.dart
cd packages/map_gameplay && dart test test/party_bag_heal_operations_test.dart
cd packages/map_gameplay && dart test test/new_game_initial_party_test.dart
cd packages/map_core && dart test test/game_state_persistence_test.dart
cd packages/map_core && dart test test/save_data_test.dart
cd packages/map_gameplay && dart analyze
cd packages/map_core && dart analyze
cd packages/map_runtime && flutter test test/runtime_battle_outcome_apply_test.dart
cd packages/map_runtime && flutter test test/runtime_battle_setup_mapper_test.dart
cd packages/map_runtime && flutter test test/wild_battle_end_to_end_flow_test.dart
cd packages/map_runtime && flutter analyze
cd packages/map_runtime && flutter analyze --no-fatal-infos
```

### Contenu complet du nouveau test

```dart
import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:test/test.dart';

void main() {
  const mutations = GameStateMutations();

  PlayerPokemon pokemon(String speciesId, {int level = 5}) {
    return PlayerPokemon(
      speciesId: speciesId,
      natureId: 'hardy',
      abilityId: 'p5_capture_ability',
      level: level,
      knownMoveIds: const ['p5_capture_move'],
      currentHp: 12,
    );
  }

  GameState captureState({
    required List<PlayerPokemon> party,
    List<PlayerPokemon> storage = const [],
    Set<String> storyFlags = const {'p5.capture.flag'},
  }) {
    var state = GameState(
      saveId: 'p5_capture_save',
      currentMapId: 'p5_capture_map',
      playerPosition: const GridPos(x: 4, y: 7),
      playerFacing: EntityFacing.west,
      trainerProfile: const TrainerProfile(name: 'P5 Player', money: 325),
      party: PlayerParty(members: party),
      pokemonStorage: PokemonStorage(storedPokemon: storage),
      bag: const Bag(
        entries: [
          BagEntry(itemId: 'poke-ball', categoryId: 'items', quantity: 2),
        ],
      ),
      progression: const PlayerProgression(
        seenSpeciesIds: ['p5_seen_before'],
        caughtSpeciesIds: ['p5_caught_before'],
      ),
      storyFlags: StoryFlags(activeFlags: storyFlags),
      metadata: const {'lot': 'p5_06'},
    );
    state = mutations.markEventConsumed(state, 'p5.capture.before');
    return state;
  }

  group('GameStateMutations.applyCapturedPokemon', () {
    test('adds the captured pokemon to party when there is room', () {
      final state = captureState(
        party: [
          pokemon('p5_party_0'),
          pokemon('p5_party_1'),
          pokemon('p5_party_2'),
          pokemon('p5_party_3'),
          pokemon('p5_party_4'),
        ],
      );

      final result = mutations.applyCapturedPokemon(
        state,
        pokemon: pokemon(' p5_captured_party ', level: 9),
      );

      expect(result.destination, CaptureDestinationKind.party);
      expect(result.partyIndex, 5);
      expect(result.storageIndex, isNull);
      expect(result.state.party.members, hasLength(6));
      expect(result.state.party.members.last.speciesId, 'p5_captured_party');
      expect(result.state.pokemonStorage.storedPokemon, isEmpty);
    });

    test('sends the captured pokemon to storage when party is full', () {
      final state = captureState(
        party: List<PlayerPokemon>.generate(
          6,
          (index) => pokemon('p5_party_$index'),
        ),
      );

      final result = mutations.applyCapturedPokemon(
        state,
        pokemon: pokemon('p5_captured_storage', level: 11),
      );

      expect(result.destination, CaptureDestinationKind.storage);
      expect(result.partyIndex, isNull);
      expect(result.storageIndex, 0);
      expect(result.state.party.members, hasLength(6));
      expect(result.state.party.members.map((member) => member.speciesId), [
        'p5_party_0',
        'p5_party_1',
        'p5_party_2',
        'p5_party_3',
        'p5_party_4',
        'p5_party_5',
      ]);
      expect(result.state.pokemonStorage.storedPokemon, hasLength(1));
      expect(
        result.state.pokemonStorage.storedPokemon.single.speciesId,
        'p5_captured_storage',
      );
    });

    test('appends to existing storage and reports the storage index', () {
      final state = captureState(
        party: List<PlayerPokemon>.generate(
          6,
          (index) => pokemon('p5_party_$index'),
        ),
        storage: [
          pokemon('p5_stored_existing_a'),
          pokemon('p5_stored_existing_b'),
        ],
      );

      final result = mutations.applyCapturedPokemon(
        state,
        pokemon: pokemon('p5_captured_storage_c'),
      );

      expect(result.destination, CaptureDestinationKind.storage);
      expect(result.storageIndex, 2);
      expect(result.state.party.members, hasLength(6));
      expect(result.state.pokemonStorage.storedPokemon, hasLength(3));
      expect(
        result.state.pokemonStorage.storedPokemon
            .map((member) => member.speciesId),
        [
          'p5_stored_existing_a',
          'p5_stored_existing_b',
          'p5_captured_storage_c'
        ],
      );
    });

    test('blank speciesId is a safe no-op', () {
      final state = captureState(
        party: [pokemon('p5_party_0')],
      );

      final result = mutations.applyCapturedPokemon(
        state,
        pokemon: pokemon('   '),
      );

      expect(result.destination, CaptureDestinationKind.none);
      expect(result.state, same(state));
      expect(result.partyIndex, isNull);
      expect(result.storageIndex, isNull);
    });

    test('preserves map, position, bag, money, flags and metadata', () {
      final state = captureState(
        party: List<PlayerPokemon>.generate(
          6,
          (index) => pokemon('p5_party_$index'),
        ),
      );

      final result = mutations.applyCapturedPokemon(
        state,
        pokemon: pokemon('p5_captured_preserve'),
      );

      expect(result.state.currentMapId, state.currentMapId);
      expect(result.state.playerPosition, state.playerPosition);
      expect(result.state.playerFacing, state.playerFacing);
      expect(result.state.bag, state.bag);
      expect(result.state.trainerProfile, state.trainerProfile);
      expect(result.state.storyFlags, state.storyFlags);
      expect(result.state.consumedEventIds, state.consumedEventIds);
      expect(result.state.metadata, state.metadata);
    });

    test('updates caught and seen for party and storage destinations', () {
      final partyResult = mutations.applyCapturedPokemon(
        captureState(party: [pokemon('p5_party_0')]),
        pokemon: pokemon('p5_captured_seen_party'),
      );
      final storageResult = mutations.applyCapturedPokemon(
        captureState(
          party: List<PlayerPokemon>.generate(
            6,
            (index) => pokemon('p5_party_$index'),
          ),
        ),
        pokemon: pokemon('p5_captured_seen_storage'),
      );

      expect(
        partyResult.state.progression.caughtSpeciesIds,
        contains('p5_captured_seen_party'),
      );
      expect(
        partyResult.state.progression.seenSpeciesIds,
        contains('p5_captured_seen_party'),
      );
      expect(
        storageResult.state.progression.caughtSpeciesIds,
        contains('p5_captured_seen_storage'),
      );
      expect(
        storageResult.state.progression.seenSpeciesIds,
        contains('p5_captured_seen_storage'),
      );
    });

    test('round-trips party and storage captures through SaveData', () {
      final partyResult = mutations.applyCapturedPokemon(
        captureState(
          party: [
            pokemon('p5_party_0'),
            pokemon('p5_party_1'),
            pokemon('p5_party_2'),
            pokemon('p5_party_3'),
            pokemon('p5_party_4'),
          ],
        ),
        pokemon: pokemon('p5_roundtrip_party'),
      );
      final storageResult = mutations.applyCapturedPokemon(
        partyResult.state,
        pokemon: pokemon('p5_roundtrip_storage'),
      );

      final saveData = saveDataFromGameState(storageResult.state);
      final reloaded =
          normalizeLoadedGameState(gameStateFromSaveData(saveData));

      expect(reloaded.party.members, hasLength(6));
      expect(reloaded.party.members.last.speciesId, 'p5_roundtrip_party');
      expect(reloaded.pokemonStorage.storedPokemon, hasLength(1));
      expect(
        reloaded.pokemonStorage.storedPokemon.single.speciesId,
        'p5_roundtrip_storage',
      );
      expect(
        reloaded.progression.caughtSpeciesIds,
        containsAll(['p5_roundtrip_party', 'p5_roundtrip_storage']),
      );
      expect(reloaded.metadata, storageResult.state.metadata);
    });

    test('does not hardcode any Selbrume ids', () {
      final result = mutations.applyCapturedPokemon(
        captureState(party: [pokemon('p5_party_generic')]),
        pokemon: pokemon('p5_capture_generic'),
      );

      final joined = [
        result.state.currentMapId,
        ...result.state.party.members.map((member) => member.speciesId),
        ...result.state.pokemonStorage.storedPokemon
            .map((member) => member.speciesId),
      ].join('|').toLowerCase();

      expect(joined, isNot(contains('selbrume')));
      expect(joined, isNot(contains('lysa')));
      expect(joined, isNot(contains('mael')));
      expect(joined, isNot(contains('brume')));
    });
  });
}
```

### Diff des sections modifiées

Le diff intégral des fichiers générés `*.freezed.dart` / `*.g.dart` est long et
mécanique. Il est produit par :

```text
cd packages/map_core && dart run build_runner build --delete-conflicting-outputs
```

Les sections manuelles exhaustives sont :

```diff
@freezed
class PokemonStorage with _$PokemonStorage {
  const PokemonStorage._();

  @JsonSerializable(explicitToJson: true)
  const factory PokemonStorage({
    @Default([]) List<PlayerPokemon> storedPokemon,
  }) = _PokemonStorage;

  factory PokemonStorage.fromJson(Map<String, dynamic> json) =>
      _$PokemonStorageFromJson(json);

  PokemonStorage normalized() => copyWith(
        storedPokemon: storedPokemon
            .map((member) => member.normalized())
            .toList(growable: false),
      );
}
```

```diff
+    @Default(PokemonStorage()) PokemonStorage pokemonStorage,
```

```diff
+  /// Applique une capture réussie vers la party ou le storage minimal.
+  CaptureDestinationResult applyCapturedPokemon(
+    GameState state, {
+    required PlayerPokemon pokemon,
+    int maxPartySize = 6,
+  }) { ... }
```

```diff
-    if (stateWithPlayerHp.party.members.length >= 6) {
-      throw StateError(
-        'Impossible d’ajouter un Pokémon capturé : la party du joueur est pleine.',
-      );
-    }
-
     final bagAfterConsumption =
         _consumeOnePokeBallOrThrow(stateWithPlayerHp.bag);
     final capturedPokemon = _buildCapturedWildPlayerPokemon(
       enemy: outcome.finalState.enemy,
     );
-    final nextMembers = List<PlayerPokemon>.of(
-      stateWithPlayerHp.party.members,
-      growable: true,
-    )..add(capturedPokemon);
-
-    return normalizeLoadedGameState(
+    final captureResult = const GameStateMutations().applyCapturedPokemon(
       stateWithPlayerHp.copyWith(
-        party: stateWithPlayerHp.party.copyWith(members: nextMembers),
         bag: bagAfterConsumption,
       ),
+      pokemon: capturedPokemon,
     );
+
+    return captureResult.state;
```

### Contrôles finaux

Commande :

```bash
git diff --check
```

Sortie exacte :

```text
```

Commande :

```bash
git diff --stat
```

Sortie exacte :

```text
 MVP Selbrume/road_map_phase_5.md                   |   7 +-
 packages/map_core/lib/src/models/game_state.dart   |   1 +
 .../lib/src/models/game_state.freezed.dart         |  38 +++-
 packages/map_core/lib/src/models/game_state.g.dart |   5 +
 packages/map_core/lib/src/models/save_data.dart    |  21 +++
 .../map_core/lib/src/models/save_data.freezed.dart | 202 ++++++++++++++++++++-
 packages/map_core/lib/src/models/save_data.g.dart  |  19 ++
 .../lib/src/operations/game_state_persistence.dart |  14 +-
 .../map_core/test/game_state_persistence_test.dart |  40 ++++
 packages/map_core/test/save_data_test.dart         |  32 ++++
 packages/map_gameplay/lib/map_gameplay.dart        |   3 +-
 .../map_gameplay/lib/src/game_state_mutations.dart |  97 ++++++++++
 .../application/runtime_battle_outcome_apply.dart  |  29 +--
 .../application/runtime_battle_setup_mapper.dart   |   6 +-
 .../test/runtime_battle_outcome_apply_test.dart    |  50 +++--
 .../test/runtime_battle_setup_mapper_test.dart     |   5 +-
 .../test/wild_battle_end_to_end_flow_test.dart     |  11 +-
 17 files changed, 527 insertions(+), 53 deletions(-)
```

Commande :

```bash
git diff --name-only
```

Sortie exacte :

```text
MVP Selbrume/road_map_phase_5.md
packages/map_core/lib/src/models/game_state.dart
packages/map_core/lib/src/models/game_state.freezed.dart
packages/map_core/lib/src/models/game_state.g.dart
packages/map_core/lib/src/models/save_data.dart
packages/map_core/lib/src/models/save_data.freezed.dart
packages/map_core/lib/src/models/save_data.g.dart
packages/map_core/lib/src/operations/game_state_persistence.dart
packages/map_core/test/game_state_persistence_test.dart
packages/map_core/test/save_data_test.dart
packages/map_gameplay/lib/map_gameplay.dart
packages/map_gameplay/lib/src/game_state_mutations.dart
packages/map_runtime/lib/src/application/runtime_battle_outcome_apply.dart
packages/map_runtime/lib/src/application/runtime_battle_setup_mapper.dart
packages/map_runtime/test/runtime_battle_outcome_apply_test.dart
packages/map_runtime/test/runtime_battle_setup_mapper_test.dart
packages/map_runtime/test/wild_battle_end_to_end_flow_test.dart
```

Commande :

```bash
git status --short --untracked-files=all
```

Sortie exacte :

```text
 M "MVP Selbrume/road_map_phase_5.md"
 M packages/map_core/lib/src/models/game_state.dart
 M packages/map_core/lib/src/models/game_state.freezed.dart
 M packages/map_core/lib/src/models/game_state.g.dart
 M packages/map_core/lib/src/models/save_data.dart
 M packages/map_core/lib/src/models/save_data.freezed.dart
 M packages/map_core/lib/src/models/save_data.g.dart
 M packages/map_core/lib/src/operations/game_state_persistence.dart
 M packages/map_core/test/game_state_persistence_test.dart
 M packages/map_core/test/save_data_test.dart
 M packages/map_gameplay/lib/map_gameplay.dart
 M packages/map_gameplay/lib/src/game_state_mutations.dart
 M packages/map_runtime/lib/src/application/runtime_battle_outcome_apply.dart
 M packages/map_runtime/lib/src/application/runtime_battle_setup_mapper.dart
 M packages/map_runtime/test/runtime_battle_outcome_apply_test.dart
 M packages/map_runtime/test/runtime_battle_setup_mapper_test.dart
 M packages/map_runtime/test/wild_battle_end_to_end_flow_test.dart
?? packages/map_gameplay/test/capture_destination_operations_test.dart
?? reports/roadmap/phase_5/p5_06_capture_destination_party_or_box.md
```

### Contrôles explicites de non-scope

- `road_map_global.md` n'a pas été modifié.
- P5-07 n'a pas été exécuté.
- Boot Flow complet non créé.
- Selbrume final non créé.
- Aucune UI PC/box/storage créée.
- Aucun reward/money/XP supplémentaire ajouté.
- Aucun moves learned / evolution system ajouté.
- Aucun système storage complet créé.
- Aucun changement `map_battle`.

## 17. Auto-review critique

Points forts :

- Le cas party pleine est réellement fermé au niveau persistence.
- Le runtime n'échoue plus sur party pleine.
- Le stockage reste minimal : une liste persistante, pas une UI PC.
- Les invariants caught/seen restent centralisés dans la persistence.

Réserves :

- `PokemonStorage` est un V0 plat, sans box nommée, capacité ou déplacement.
- Le runtime capture dépend toujours de l'item `poke-ball` minimal existant.
- `flutter analyze` runtime complet reste bruyant à cause d'infos historiques
  hors scope.

## 18. Regard critique sur le prompt

Le prompt force correctement la fermeture du vrai trou : une capture party full
ne devait plus être seulement documentée. Le seul point délicat est qu'un
storage persistant imposait de modifier les modèles `SaveData/GameState` et de
régénérer Freezed. C'est plus lourd qu'une opération pure seule, mais c'est le
plus petit changement honnête : sans stockage persistant, P5-06 aurait été une
fausse preuve.

Prochain lot exact :

```text
P5-07 — Gameplay Save/Load Beta Roundtrip V0
```
