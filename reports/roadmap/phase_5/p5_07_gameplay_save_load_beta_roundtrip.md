# P5-07 — Gameplay Save/Load Beta Roundtrip V0

## 1. Résumé exécutif

P5-07 est implémenté.

Le lot ajoute une preuve exécutable de roundtrip gameplay bêta via le chemin
runtime le plus réel disponible :

```text
GameState P5-02 -> P5-06
-> SaveGameUseCase
-> FileGameSaveRepository
-> vrai fichier game_save.json temporaire
-> LoadGameUseCase
-> normalizeLoadedGameState(...)
-> assertions gameplay bêta
```

Résultat : party, storage, bag, money, level-up direct, heal/status,
caught/seen, flags, consumed events et metadata survivent à une vraie
sauvegarde/recharge disque.

Aucun code de production n'a été modifié pour P5-07.

## 2. Scope du lot

Inclus :

- création d'un test runtime ciblé ;
- écriture disque temporaire via `FileGameSaveRepository` ;
- sauvegarde via `SaveGameUseCase` ;
- chargement via `LoadGameUseCase` ;
- vérification du fichier JSON produit ;
- vérification complète des états gameplay bêta ;
- mise à jour de la roadmap Phase 5 ;
- rapport et Evidence Pack.

Exclus :

- UI save/load ;
- menu runtime de sauvegarde ;
- New Game UI ;
- Boot Flow complet ;
- écran titre ;
- starter UI ;
- party UI ;
- bag UI ;
- heal center UI ;
- PC / box UI ;
- reward UI ;
- capture animation ;
- XP persistée complète ;
- moves learned ;
- évolution ;
- Selbrume final ;
- P5-08.

## 3. Sources lues

Sources principales :

- `AGENTS.md`
- `skills/README.md`
- `pokemap_roadmap_mecaniques_fangame.md`
- `MVP Selbrume/road_map_global.md`
- `MVP Selbrume/road_map_phase_5.md`
- `reports/roadmap/phase_5/p5_06_capture_destination_party_or_box.md`
- `packages/map_core/lib/src/models/save_data.dart`
- `packages/map_core/lib/src/models/game_state.dart`
- `packages/map_core/lib/src/operations/game_state_persistence.dart`
- `packages/map_gameplay/lib/src/game_state_mutations.dart`
- `packages/map_gameplay/lib/src/new_game_state_builder.dart`
- `packages/map_runtime/lib/src/infrastructure/file_game_save_repository.dart`
- `packages/map_runtime/lib/src/application/save_game_use_case.dart`
- `packages/map_runtime/lib/src/application/load_game_use_case.dart`
- `packages/map_runtime/lib/map_runtime.dart`
- `packages/map_runtime/lib/domain/repositories/game_save_repository.dart`
- `packages/map_runtime/test/file_game_save_repository_test.dart`
- `packages/map_gameplay/test/capture_destination_operations_test.dart`
- `packages/map_gameplay/test/battle_reward_operations_test.dart`
- `packages/map_gameplay/test/party_bag_heal_operations_test.dart`
- `packages/map_core/test/game_state_persistence_test.dart`
- `packages/map_core/test/save_data_test.dart`

## 4. Chemin save/load choisi

Chemin choisi :

```text
packages/map_runtime/test/p5_gameplay_save_load_beta_roundtrip_test.dart
-> _TempFileGameSaveRepository extends FileGameSaveRepository
-> SaveGameUseCase.execute(...)
-> FileGameSaveRepository.save(...)
-> game_save.json réel dans Directory.systemTemp
-> LoadGameUseCase.execute(...)
-> FileGameSaveRepository.load(...)
-> normalizeLoadedGameState(...)
```

Justification :

- `map_runtime` dépend déjà proprement de `map_core` et `map_gameplay`.
- `FileGameSaveRepository` existe et écrit un vrai fichier.
- Les use cases runtime existent et sont exportés par `map_runtime.dart`.
- Une sous-classe de test peut remplacer `getSaveFilePath()` sans toucher au
  repository de production.

Ce choix donne une preuve Level 4 partiel : vraie écriture disque, vraie lecture
disque, vrai repository runtime, vrai JSON `GameState`.

## 5. État gameplay bêta construit

Le test construit un état générique non-Selbrume :

```text
map : p5_roundtrip_map
spawn : p5_roundtrip_spawn
save : p5_roundtrip_save
starter : p5_roundtrip_starter
party species : p5_roundtrip_party_0 .. p5_roundtrip_party_3
captured party species : p5_roundtrip_captured_party
captured storage species : p5_roundtrip_captured_storage
item : p5_roundtrip_medicine
flag : p5.roundtrip.flag.ready
event : p5.roundtrip.event.consumed
trainer defeated flag : trainer_defeated:p5_roundtrip_trainer
```

Workflow :

```text
MapData avec spawn
-> createNewGameStateFromMap(...)
-> givePokemon(...)
-> giveItem(...)
-> applyHpMedicineToPartyMember(...)
-> recoverParty(...)
-> applyBattleRewards(...)
-> setFlag(...)
-> markEventConsumed(...)
-> applyCapturedPokemon(...) vers party
-> applyCapturedPokemon(...) vers storage
-> SaveGameUseCase
-> LoadGameUseCase
-> normalizeLoadedGameState
```

## 6. Party / starter / level-up

Prouvé après reload :

- `party.members` conserve 6 membres ;
- l'ordre de party est conservé ;
- le starter `p5_roundtrip_starter` reste en slot 0 ;
- le level-up direct P5-05 est conservé (`level = 7`) ;
- la capture party est conservée en slot 5.

## 7. Bag / medicine / heal

Prouvé après reload :

- le sac conserve `p5_roundtrip_medicine` ;
- la quantité attendue reste `1` après consommation d'une medicine ;
- le starter est restauré à `currentHp = 20` ;
- `statusId` est vidé par `recoverParty(...)`.

## 8. Capture party / storage

Prouvé après reload :

- capture avec party non pleine -> destination `party` ;
- capture avec party pleine -> destination `storage` ;
- `pokemonStorage.storedPokemon` conserve `p5_roundtrip_captured_storage` ;
- l'ordre du storage est conservé.

## 9. Progression seen/caught

Prouvé après reload :

- `caughtSpeciesIds` contient le starter, la capture party et la capture
  storage ;
- `seenSpeciesIds` contient le starter, la capture party et la capture storage ;
- `normalizeLoadedGameState(...)` maintient l'invariant caught -> seen.

## 10. Flags / consumed events / metadata

Prouvé après reload :

- `storyFlags.activeFlags` contient `p5.roundtrip.flag.ready` ;
- `storyFlags.activeFlags` contient
  `trainer_defeated:p5_roundtrip_trainer` ;
- `consumedEventIds` contient `p5.roundtrip.event.consumed` ;
- `metadata` conserve `lot=p5_07` et
  `persistence=file_game_save_repository`.

## 11. Persistence roundtrip

Le test vérifie aussi le fichier sur disque avant reload :

```text
save file exists
json['saveId'] == p5_roundtrip_save
json['currentMapId'] == p5_roundtrip_map
json['pokemonStorage'] is Map<String, dynamic>
```

La preuve n'est donc pas un roundtrip in-memory.

## 12. Ce qui est prouvé

P5-07 prouve :

- un état gameplay bêta minimal peut être construit sans UI ;
- `FileGameSaveRepository` écrit un vrai `game_save.json` ;
- `SaveGameUseCase` et `LoadGameUseCase` fonctionnent sur ce scénario ;
- party, storage, bag, money, level-up direct, heal/status, caught/seen, flags,
  consumed events et metadata survivent au roundtrip ;
- aucun id Selbrume n'est hardcodé dans la preuve ;
- aucune nouvelle mécanique gameplay n'a été ajoutée.

## 13. Ce qui n’est pas prouvé

Non prouvé volontairement :

- UI save/load ;
- runtime save menu ;
- New Game UI ;
- Boot Flow complet ;
- combat runtime complet dans ce test ;
- capture animation ;
- XP persistée complète ;
- move learning ;
- évolution ;
- PC / box UI ;
- gameplay save/load depuis une vraie session Flame longue.

Ces sujets restent reportés vers P5-08 / P5-09 / Phase 7 selon leur nature.

## 14. Limites et reports vers P5-08 / P5-09

Limites :

- P5-07 prouve le roundtrip disque runtime, pas une boucle runtime complète.
- Le combat n'est pas exécuté dans Flame dans ce test ; les effets sont
  appliqués via opérations P5-02 à P5-06.
- XP courante persistée reste absente ; P5-05 utilise un level-up direct
  minimal.
- L'analyse complète `map_runtime` contient encore des infos historiques
  `prefer_const_*` et `avoid_relative_lib_imports`, mais le nouveau test est
  clean en analyse ciblée.

Reports :

- P5-08 : smoke runtime New Game -> Battle -> Reward -> Save/Load.
- P5-09 : validator bêta de jouabilité.
- Phase 7 ou chantier dédié : UI save/load et Boot Flow complet.

## 15. Tests exécutés

Test ciblé P5-07 :

```text
cd packages/map_runtime && flutter test test/p5_gameplay_save_load_beta_roundtrip_test.dart

00:00 +0: loading /Users/karim/Project/pokemonProject/packages/map_runtime/test/p5_gameplay_save_load_beta_roundtrip_test.dart
00:00 +0: P5-07 roundtrips beta gameplay state through FileGameSaveRepository
[step_studio_trace] save_repo_write_start path=/var/folders/b5/7gsfwzyd449_54n8l40h40gc0000gn/T/p5_roundtrip_save_kInJFL/pokemonProject/game_save.json completedStepIds=[]
[save] game saved to /var/folders/b5/7gsfwzyd449_54n8l40h40gc0000gn/T/p5_roundtrip_save_kInJFL/pokemonProject/game_save.json
[step_studio_trace] save_repo_write_done path=/var/folders/b5/7gsfwzyd449_54n8l40h40gc0000gn/T/p5_roundtrip_save_kInJFL/pokemonProject/game_save.json completedStepIds=[]
[load] game loaded from /var/folders/b5/7gsfwzyd449_54n8l40h40gc0000gn/T/p5_roundtrip_save_kInJFL/pokemonProject/game_save.json
00:00 +1: All tests passed!
```

Régressions ciblées :

```text
cd packages/map_gameplay && dart test test/capture_destination_operations_test.dart

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

```text
cd packages/map_gameplay && dart test test/battle_reward_operations_test.dart

00:00 +0: GameStateMutations.addMoney increases trainerProfile money
00:00 +1: GameStateMutations.addMoney is a no-op for non-positive amounts
00:00 +2: GameStateMutations.applyBattleRewards applies money reward and preserves world state
00:00 +3: GameStateMutations.applyBattleRewards applies direct minimal level-up when XP is not persisted
00:00 +4: GameStateMutations.applyBattleRewards caps direct level-up at PlayerPokemon max level
00:00 +5: GameStateMutations.applyBattleRewards ignores invalid party indexes and non-positive level increments
00:00 +6: GameStateMutations.applyBattleRewards applies money even when party is empty
00:00 +7: GameStateMutations.applyBattleRewards does not create or duplicate trainer defeated policy
00:00 +8: GameStateMutations.applyBattleRewards round-trips money and direct level-up through SaveData
00:00 +9: GameStateMutations.applyBattleRewards does not hardcode any Selbrume ids
00:00 +10: All tests passed!
```

```text
cd packages/map_gameplay && dart test test/party_bag_heal_operations_test.dart

00:00 +0: GameStateMutations.consumeItem decrements an item quantity
00:00 +1: GameStateMutations.consumeItem removes an entry when quantity reaches zero
00:00 +2: GameStateMutations.consumeItem preserves party, map, progression and metadata
00:00 +3: GameStateMutations.consumeItem handles missing item, blank id and invalid quantity safely
00:00 +4: GameStateMutations.applyHpMedicineToPartyMember heals a party member and consumes the medicine item
00:00 +5: GameStateMutations.applyHpMedicineToPartyMember caps healing at explicit maxHp
00:00 +6: GameStateMutations.applyHpMedicineToPartyMember does not consume item on invalid index, missing item or no healing
00:00 +7: GameStateMutations.recoverParty restores multiple party members with explicit max HP caps
00:00 +8: GameStateMutations.recoverParty skips party members without a valid explicit cap
00:00 +9: GameStateMutations.recoverParty round-trips healed party and updated bag through SaveData
00:00 +10: GameStateMutations.recoverParty does not hardcode any Selbrume ids
00:00 +11: All tests passed!
```

```text
cd packages/map_core && dart test test/game_state_persistence_test.dart

00:00 +0: loading test/game_state_persistence_test.dart
00:00 +0: gameStateFromSaveData migrates legacy save fields to GameState
00:00 +1: saveDataFromGameState keeps core fields and merges story flags in legacy slot
00:00 +2: saveDataFromGameState syncs party species into caught and seen for persistence
00:00 +3: saveDataFromGameState syncs stored species into caught and seen for persistence
00:00 +4: normalizeLoadedGameState hydrates storyFlags from progression when storyFlags are empty
00:00 +5: normalizeLoadedGameState keeps explicit storyFlags as source of truth when already set
00:00 +6: normalizeLoadedGameState hydrates caught and seen from party for legacy states
00:00 +7: normalizeLoadedGameState markSpeciesSeenInGameState adds seen without inventing caught
00:00 +8: All tests passed!
```

```text
cd packages/map_core && dart test test/save_data_test.dart

00:00 +0: loading test/save_data_test.dart
00:00 +0: PokemonStatSpread serialization round-trip
00:00 +1: PlayerPokemon serialization round-trip
00:00 +2: PlayerPokemon defaults are coherent
00:00 +3: PlayerPokemon JSON keys match expected structure
00:00 +4: PlayerPokemon normalizes an optional authored gender without inventing one
00:00 +5: PlayerPokemon normalized rejects more than four moves
00:00 +6: PlayerPokemon legacy JSON migrates missing phase 9 fields
00:00 +7: PlayerPokemon non legacy JSON missing phase 9 fields still fails
00:00 +8: PlayerParty serialization round-trip
00:00 +9: PlayerParty default is empty party
00:00 +10: PokemonStorage serialization round-trip
00:00 +11: PokemonStorage default is empty storage
00:00 +12: PlayerProgression serialization round-trip
00:00 +13: PlayerProgression defaults are empty
00:00 +14: PlayerProgression normalized keeps caught as subset of seen
00:00 +15: TrainerProfile serialization round-trip
00:00 +16: TrainerProfile normalized badges are stable
00:00 +17: TrainerProfile normalized rejects empty names
00:00 +18: Bag serialization round-trip
00:00 +19: Bag normalized entries merge duplicates deterministically
00:00 +20: Bag normalized rejects non-positive quantities
00:00 +21: SaveData serialization round-trip
00:00 +22: SaveData defaults are coherent
00:00 +23: SaveData copyWith preserves unmodified fields
00:00 +24: FieldAbility JSON values match expected strings
00:00 +25: All tests passed!
```

Analyse :

```text
cd packages/map_runtime && flutter analyze --no-fatal-infos test/p5_gameplay_save_load_beta_roundtrip_test.dart

Analyzing p5_gameplay_save_load_beta_roundtrip_test.dart...
No issues found! (ran in 1.3s)
```

```text
cd packages/map_runtime && flutter analyze --no-fatal-infos

Analyzing map_runtime...
352 issues found. (ran in 2.6s)

Signal utile :
- exit code 0 grâce à --no-fatal-infos ;
- infos historiques uniquement dans lib/test existants ;
- exemples observés : prefer_const_constructors, prefer_const_declarations,
  avoid_relative_lib_imports, no_leading_underscores_for_local_identifiers ;
- aucun issue ciblé sur
  test/p5_gameplay_save_load_beta_roundtrip_test.dart.
```

## 16. Modifications effectuées

Fichiers créés :

- `packages/map_runtime/test/p5_gameplay_save_load_beta_roundtrip_test.dart`
- `reports/roadmap/phase_5/p5_07_gameplay_save_load_beta_roundtrip.md`

Fichiers modifiés :

- `MVP Selbrume/road_map_phase_5.md`

Code de production modifié :

- aucun.

Tests P4 modifiés :

- aucun.

## 17. Evidence Pack

### git status initial exact

```text
<aucune sortie>
```

### Commandes exécutées

```bash
git status --short --untracked-files=all
sed -n '1,360p' "MVP Selbrume/road_map_global.md"
sed -n '1,1120p' "MVP Selbrume/road_map_phase_5.md"
sed -n '1,340p' reports/roadmap/phase_5/p5_06_capture_destination_party_or_box.md
sed -n '1,520p' packages/map_core/lib/src/models/save_data.dart
sed -n '1,340p' packages/map_core/lib/src/models/game_state.dart
sed -n '1,340p' packages/map_core/lib/src/operations/game_state_persistence.dart
sed -n '1,420p' packages/map_gameplay/lib/src/game_state_mutations.dart
sed -n '421,760p' packages/map_gameplay/lib/src/game_state_mutations.dart
sed -n '1,260p' packages/map_gameplay/lib/src/new_game_state_builder.dart
sed -n '1,260p' packages/map_runtime/lib/src/infrastructure/file_game_save_repository.dart
sed -n '1,220p' packages/map_runtime/lib/src/application/save_game_use_case.dart
sed -n '1,220p' packages/map_runtime/lib/src/application/load_game_use_case.dart
rg -n "FileGameSaveRepository|SaveGameUseCase|LoadGameUseCase|saveGame|loadGame|SaveData|GameState|pokemonStorage|applyCapturedPokemon|applyBattleRewards|recoverParty|consumeItem|saveDataFromGameState|gameStateFromSaveData|normalizeLoadedGameState" packages/map_core packages/map_gameplay packages/map_runtime --glob '!build/**' --glob '!**/.dart_tool/**'
find packages/map_runtime/test -maxdepth 3 -type f | sort | rg "save|load|gameplay|p5|roundtrip|storage|capture"
find packages/map_gameplay/test -maxdepth 2 -type f | sort | rg "save|load|gameplay|roundtrip|capture|reward|heal"
find packages/map_core/test -maxdepth 2 -type f | sort | rg "save|game_state|storage|pokemon"
sed -n '1,180p' packages/map_runtime/lib/map_runtime.dart
sed -n '1,120p' packages/map_runtime/lib/domain/repositories/game_save_repository.dart
sed -n '1,700p' packages/map_runtime/test/file_game_save_repository_test.dart
sed -n '1,260p' packages/map_gameplay/test/capture_destination_operations_test.dart
sed -n '1,240p' packages/map_gameplay/test/battle_reward_operations_test.dart
sed -n '1,280p' packages/map_gameplay/test/party_bag_heal_operations_test.dart
sed -n '1,280p' packages/map_core/test/game_state_persistence_test.dart
sed -n '1,260p' packages/map_core/test/save_data_test.dart
dart format --set-exit-if-changed packages/map_runtime/test/p5_gameplay_save_load_beta_roundtrip_test.dart
cd packages/map_runtime && flutter test test/p5_gameplay_save_load_beta_roundtrip_test.dart
cd packages/map_gameplay && dart test test/capture_destination_operations_test.dart
cd packages/map_gameplay && dart test test/battle_reward_operations_test.dart
cd packages/map_gameplay && dart test test/party_bag_heal_operations_test.dart
cd packages/map_core && dart test test/game_state_persistence_test.dart
cd packages/map_core && dart test test/save_data_test.dart
cd packages/map_runtime && flutter analyze --no-fatal-infos
cd packages/map_runtime && flutter analyze --no-fatal-infos test/p5_gameplay_save_load_beta_roundtrip_test.dart
```

### Sortie format

```text
dart format --set-exit-if-changed packages/map_runtime/test/p5_gameplay_save_load_beta_roundtrip_test.dart

Formatted 1 file (0 changed) in 0.01 seconds.
```

### Contenu complet du nouveau test

```dart
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:map_runtime/map_runtime.dart';

const _saveId = 'p5_roundtrip_save';
const _mapId = 'p5_roundtrip_map';
const _spawnId = 'p5_roundtrip_spawn';
const _starterSpeciesId = 'p5_roundtrip_starter';
const _capturedPartySpeciesId = 'p5_roundtrip_captured_party';
const _capturedStorageSpeciesId = 'p5_roundtrip_captured_storage';
const _medicineItemId = 'p5_roundtrip_medicine';
const _flagId = 'p5.roundtrip.flag.ready';
const _eventId = 'p5.roundtrip.event.consumed';
const _trainerDefeatedFlag = 'trainer_defeated:p5_roundtrip_trainer';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'P5-07 roundtrips beta gameplay state through FileGameSaveRepository',
    () async {
      final testDirectory =
          await Directory.systemTemp.createTemp('p5_roundtrip_save_');
      final repository = _TempFileGameSaveRepository(testDirectory);
      final saveGame = SaveGameUseCase(repository);
      final loadGame = LoadGameUseCase(repository);

      try {
        final state = _buildBetaGameplayState();

        expect(await saveGame.execute(state), isTrue);
        expect(await repository.exists(), isTrue);

        final saveFilePath = await repository.exposedSaveFilePath();
        final saveFile = File(saveFilePath);
        expect(await saveFile.exists(), isTrue);

        final savedJson =
            jsonDecode(await saveFile.readAsString()) as Map<String, dynamic>;
        expect(savedJson['saveId'], _saveId);
        expect(savedJson['currentMapId'], _mapId);
        expect(savedJson['pokemonStorage'], isA<Map<String, dynamic>>());

        final loaded = await loadGame.execute();
        expect(loaded, isNotNull);

        final reloaded = normalizeLoadedGameState(loaded!);

        expect(reloaded.saveId, _saveId);
        expect(reloaded.currentMapId, _mapId);
        expect(reloaded.playerPosition, const GridPos(x: 4, y: 6));
        expect(reloaded.playerFacing, EntityFacing.east);

        expect(reloaded.party.members, hasLength(6));
        expect(
          reloaded.party.members.map((pokemon) => pokemon.speciesId),
          equals(<String>[
            _starterSpeciesId,
            'p5_roundtrip_party_0',
            'p5_roundtrip_party_1',
            'p5_roundtrip_party_2',
            'p5_roundtrip_party_3',
            _capturedPartySpeciesId,
          ]),
        );
        expect(reloaded.party.members.first.level, 7);
        expect(reloaded.party.members.first.currentHp, 20);
        expect(reloaded.party.members.first.statusId, isEmpty);

        expect(reloaded.pokemonStorage.storedPokemon, hasLength(1));
        expect(
          reloaded.pokemonStorage.storedPokemon.single.speciesId,
          _capturedStorageSpeciesId,
        );

        expect(
          reloaded.bag.entries,
          equals(<BagEntry>[
            const BagEntry(
              itemId: _medicineItemId,
              categoryId: 'items',
              quantity: 1,
            ),
          ]),
        );
        expect(reloaded.trainerProfile.money, 275);

        expect(reloaded.storyFlags.activeFlags, contains(_flagId));
        expect(reloaded.storyFlags.activeFlags, contains(_trainerDefeatedFlag));
        expect(reloaded.consumedEventIds, contains(_eventId));
        expect(
          reloaded.metadata,
          equals(<String, String>{
            'lot': 'p5_07',
            'persistence': 'file_game_save_repository',
          }),
        );

        expect(
          reloaded.progression.caughtSpeciesIds,
          containsAll(<String>[
            _starterSpeciesId,
            _capturedPartySpeciesId,
            _capturedStorageSpeciesId,
          ]),
        );
        expect(
          reloaded.progression.seenSpeciesIds,
          containsAll(<String>[
            _starterSpeciesId,
            _capturedPartySpeciesId,
            _capturedStorageSpeciesId,
          ]),
        );

        expect(_containsSelbrumeId(reloaded), isFalse);
      } finally {
        if (await testDirectory.exists()) {
          await testDirectory.delete(recursive: true);
        }
      }
    },
  );
}

GameState _buildBetaGameplayState() {
  const mutations = GameStateMutations();
  var state = createNewGameStateFromMap(
    startMap: _roundtripMap(),
    saveId: _saveId,
    playerName: 'P5 Tester',
  ).copyWith(
    metadata: const <String, String>{
      'lot': 'p5_07',
      'persistence': 'file_game_save_repository',
    },
  );

  state = mutations.givePokemon(
    state,
    pokemon: _pokemon(
      _starterSpeciesId,
      level: 5,
      currentHp: 4,
      statusId: 'poison',
      knownMoveIds: const <String>['p5_roundtrip_tackle'],
    ),
  );
  state = mutations.giveItem(state, _medicineItemId, 2);
  state = mutations.applyHpMedicineToPartyMember(
    state,
    partyIndex: 0,
    itemId: _medicineItemId,
    healAmount: 8,
    maxHp: 20,
  );
  state = mutations.recoverParty(
    state,
    maxHpByPartyIndex: const <int, int>{0: 20},
  );
  state = mutations.applyBattleRewards(
    state,
    moneyReward: 275,
    levelUpsByPartyIndex: const <int, int>{0: 2},
  );
  state = mutations.setFlag(state, _flagId);
  state = mutations.setFlag(state, _trainerDefeatedFlag);
  state = mutations.markEventConsumed(state, _eventId);

  for (var index = 0; index < 4; index++) {
    state = mutations.givePokemon(
      state,
      pokemon: _pokemon(
        'p5_roundtrip_party_$index',
        level: 3 + index,
        currentHp: 10 + index,
      ),
    );
  }

  final partyCapture = mutations.applyCapturedPokemon(
    state,
    pokemon: _pokemon(_capturedPartySpeciesId, level: 4, currentHp: 14),
  );
  expect(partyCapture.destination, CaptureDestinationKind.party);
  expect(partyCapture.partyIndex, 5);

  final storageCapture = mutations.applyCapturedPokemon(
    partyCapture.state,
    pokemon: _pokemon(_capturedStorageSpeciesId, level: 6, currentHp: 18),
  );
  expect(storageCapture.destination, CaptureDestinationKind.storage);
  expect(storageCapture.storageIndex, 0);

  return storageCapture.state;
}

MapData _roundtripMap() {
  return const MapData(
    id: _mapId,
    name: 'P5 Roundtrip Field',
    size: GridSize(width: 12, height: 10),
    mapMetadata: MapMetadata(defaultSpawnId: _spawnId),
    entities: <MapEntity>[
      MapEntity(
        id: _spawnId,
        name: 'P5 Roundtrip Spawn',
        kind: MapEntityKind.spawn,
        pos: GridPos(x: 4, y: 6),
        spawn: MapEntitySpawnData(
          spawnKey: _spawnId,
          role: EntitySpawnRole.playerStart,
          facing: EntityFacing.east,
        ),
      ),
    ],
  );
}

PlayerPokemon _pokemon(
  String speciesId, {
  int level = 5,
  int currentHp = 20,
  String statusId = '',
  List<String> knownMoveIds = const <String>['p5_roundtrip_move'],
}) {
  return PlayerPokemon(
    speciesId: speciesId,
    natureId: 'hardy',
    abilityId: 'p5_roundtrip_ability',
    level: level,
    currentHp: currentHp,
    statusId: statusId,
    knownMoveIds: knownMoveIds,
  );
}

bool _containsSelbrumeId(GameState state) {
  final values = <String>[
    state.saveId,
    state.currentMapId,
    state.trainerProfile.name,
    ...state.party.members.map((pokemon) => pokemon.speciesId),
    ...state.pokemonStorage.storedPokemon.map((pokemon) => pokemon.speciesId),
    ...state.bag.entries.map((entry) => entry.itemId),
    ...state.storyFlags.activeFlags,
    ...state.consumedEventIds,
    ...state.metadata.keys,
    ...state.metadata.values,
  ];
  return values.any((value) => value.toLowerCase().contains('selbrume'));
}

class _TempFileGameSaveRepository extends FileGameSaveRepository {
  _TempFileGameSaveRepository(this._testDirectory);

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

### Diff complet du fichier modifié `road_map_phase_5.md`

```diff
diff --git a/MVP Selbrume/road_map_phase_5.md b/MVP Selbrume/road_map_phase_5.md
index b08adf2f..f8972602 100644
--- a/MVP Selbrume/road_map_phase_5.md
+++ b/MVP Selbrume/road_map_phase_5.md
@@ -11,6 +11,7 @@ P5-03 : terminé.
 P5-04 : terminé.
 P5-05 : terminé.
 P5-06 : terminé.
+P5-07 : terminé.
 
 Phase 5 reste orientée vers une boucle RPG minimale prouvable, pas vers une
 parité Pokémon complète, pas vers Selbrume final, pas vers une UI premium.
@@ -18,7 +19,7 @@ parité Pokémon complète, pas vers Selbrume final, pas vers une UI premium.
 Prochain lot exact :
 
 ```text
-P5-07 — Gameplay Save/Load Beta Roundtrip V0
+P5-08 — Beta Runtime Smoke : New Game -> Battle -> Reward -> Save/Load
 ```
 
 ## Objectif Phase 5
@@ -239,7 +240,7 @@ tests party full / party not full
 
 ### P5-07 — Gameplay Save/Load Beta Roundtrip V0
 
-Statut : prochain lot exact.
+Statut : terminé.
 
 But :
 
@@ -262,6 +263,8 @@ runtime save/load ciblé
 
 ### P5-08 — Beta Runtime Smoke : New Game -> Battle -> Reward -> Save/Load
 
+Statut : prochain lot exact.
+
 But :
 
 ```text
```

### Contrôles explicites

- `road_map_global.md` n'a pas été modifié.
- P5-08 n'a pas été exécuté.
- Aucun Boot Flow complet n'a été créé.
- Selbrume final n'a pas été créé.
- Aucune UI save/load n'a été créée.
- Aucune XP persistée complète n'a été ajoutée.
- Aucun moves learned / evolution system n'a été ajouté.
- Aucun code de production n'a été modifié pour P5-07.
- Aucun fichier `map_editor` ou `map_battle` n'a été modifié.

### Résultats git finaux

`git diff --check` :

```text
<aucune sortie>
```

`git diff --stat` :

```text
 MVP Selbrume/road_map_phase_5.md | 7 +++++--
 1 file changed, 5 insertions(+), 2 deletions(-)
```

`git diff --name-only` :

```text
MVP Selbrume/road_map_phase_5.md
```

`git status --short --untracked-files=all` :

```text
 M "MVP Selbrume/road_map_phase_5.md"
?? packages/map_runtime/test/p5_gameplay_save_load_beta_roundtrip_test.dart
?? reports/roadmap/phase_5/p5_07_gameplay_save_load_beta_roundtrip.md
```

## 18. Auto-review critique

Points solides :

- Le test utilise un vrai repository fichier runtime.
- Le fichier JSON est vérifié avant reload.
- Le test ne crée aucune mécanique P5 nouvelle.
- Le roundtrip couvre les états gameplay ajoutés ou consolidés en P5-02 à
  P5-06.

Réserves :

- `FileGameSaveRepository.save(...)` normalise via `SaveData`, puis écrit un
  `GameState` JSON. C'est le comportement runtime existant ; P5-07 le prouve,
  mais ne le simplifie pas.
- Le combat n'est pas exécuté dans Flame ; P5-08 doit le faire.
- L'analyse complète `map_runtime` reste bruyante à cause d'infos historiques.

Verdict :

```text
P5-07 est validable.
Prochain lot exact : P5-08 — Beta Runtime Smoke : New Game -> Battle -> Reward -> Save/Load.
```

## 19. Regard critique sur le prompt

Le prompt est exigeant mais utile : il force à distinguer un roundtrip réel
disque/runtime d'un simple test in-memory. La contrainte d'éviter toute UI et
toute nouvelle mécanique est importante ici, car le risque naturel aurait été
de glisser vers P5-08. Le seul point lourd est l'Evidence Pack autour des sorties
d'analyse `map_runtime`, car le package contient déjà beaucoup d'infos
historiques ; le test ciblé P5-07 donne un signal plus précis.
