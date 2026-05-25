# P5-05 — Battle Rewards / Money / XP Minimal Apply V0

## 1. Résumé exécutif

P5-05 est terminé.

Le lot ajoute la brique pure minimale de récompense de combat côté
`map_gameplay` :

- `GameStateMutations.addMoney(...)`
- `GameStateMutations.applyBattleRewards(...)`

L'audit a confirmé que `TrainerProfile.money` existe déjà et roundtrip via
`SaveData`. En revanche, `PlayerPokemon` ne persiste pas d'XP courante :
P5-05 n'ajoute donc pas de champ XP et n'invente pas d'XP invisible. Le niveau
minimal prouvé est un level-up direct, borné à 100, fourni explicitement par
l'appelant.

La policy `trainer_defeated:{trainerId}` reste portée par le runtime existant
(`runtime_battle_outcome_apply.dart` + `StoryFlagsManager`) et n'est pas
dupliquée dans `map_gameplay`.

## 2. Scope du lot

Inclus :

- money reward minimal ;
- battle reward apply minimal ;
- level-up direct minimal quand XP persistée absente ;
- no-op sûrs sur montants invalides et indexes invalides ;
- conservation de map / position / facing / bag / flags / consumed events /
  metadata ;
- roundtrip `SaveData` ;
- tests purs dans `map_gameplay`.

Exclus :

- UI reward / écran de fin de combat ;
- shop / economy engine ;
- XP persistée complète ;
- courbe XP officielle ;
- moves learned ;
- évolution ;
- badges complets ;
- capture party-or-box / PC / box ;
- heal center ;
- Boot Flow ;
- Selbrume.

## 3. Sources lues

Sources principales :

- `pokemap_roadmap_mecaniques_fangame.md`
- `MVP Selbrume/road_map_global.md`
- `MVP Selbrume/road_map_phase_5.md`
- `reports/roadmap/phase_5/p5_04_party_bag_heal_minimal_operations.md`
- `packages/map_gameplay/lib/src/game_state_mutations.dart`
- `packages/map_gameplay/lib/map_gameplay.dart`
- `packages/map_gameplay/test/party_bag_heal_operations_test.dart`
- `packages/map_gameplay/test/new_game_initial_party_test.dart`
- `packages/map_core/lib/src/models/save_data.dart`
- `packages/map_core/lib/src/models/game_state.dart`
- `packages/map_core/lib/src/operations/game_state_persistence.dart`
- `packages/map_runtime/lib/src/application/runtime_battle_outcome_apply.dart`
- `packages/map_runtime/lib/src/application/story_flags_manager.dart`
- `packages/map_runtime/test/reward_bridge_readiness_test.dart`
- `packages/map_runtime/test/runtime_battle_outcome_apply_test.dart`
- `packages/map_runtime/test/trainer_defeated_test.dart`

Sorties utiles observées :

- `TrainerProfile` porte `money`.
- `PlayerPokemon` porte `level`, mais pas `experience`, `xp`, ni XP courante.
- `PlayerPokemon.normalized()` impose `level` entre `1` et `100`.
- `runtime_battle_outcome_apply.dart` marque déjà un trainer vaincu après
  victoire trainer via `StoryFlagsManager.markTrainerDefeated(...)`.
- `reward_bridge_readiness_test.dart` prouve un reward post-battle narratif /
  item, et vérifie explicitement qu'il n'implique ni argent, ni XP, ni level-up.

## 4. État initial battle rewards / money / XP

État initial avant P5-05 :

- `money` existait dans `TrainerProfile`.
- `SaveData` persistait `TrainerProfile`.
- Le runtime écrivait déjà les PV post-battle et la policy trainer defeated.
- Les scenarios pouvaient donner un item ou poser flags/steps après victoire.
- Aucun helper `map_gameplay` ne portait money reward.
- Aucun modèle XP persisté n'existait dans `PlayerPokemon`.

## 5. Opérations ajoutées ou réutilisées

Réutilisé :

- `saveDataFromGameState(...)`
- `gameStateFromSaveData(...)`
- `normalizeLoadedGameState(...)`
- policy runtime `trainer_defeated:{trainerId}` existante.

Ajouté dans `packages/map_gameplay/lib/src/game_state_mutations.dart` :

- `addMoney(GameState state, int amount)`
- `applyBattleRewards(GameState state, {int moneyReward, Map<int, int> levelUpsByPartyIndex})`

Le barrel `packages/map_gameplay/lib/map_gameplay.dart` exportait déjà
`GameStateMutations`.

## 6. Money reward

`addMoney(...)` :

- no-op si `amount <= 0` ;
- ajoute `amount` à `trainerProfile.money` ;
- ne touche pas au bag, party, map, flags, consumed events ou metadata ;
- ne crée pas de shop ;
- ne crée pas d'economy engine.

`applyBattleRewards(...)` réutilise `addMoney(...)` pour `moneyReward`.

## 7. XP / level-up minimal

Décision P5-05 :

```text
Pas de XP persistée ajoutée.
Level-up direct minimal prouvé.
```

Justification :

- `PlayerPokemon` n'a pas de champ XP ;
- ajouter une XP persistée aurait impliqué une modification de modèle /
  generated files / migration implicite trop large pour V0 ;
- créer une XP invisible serait refusé : elle ne survivrait pas au roundtrip et
  mentirait sur la preuve.

Comportement V0 :

- `levelUpsByPartyIndex` applique des incréments directs ;
- index invalide : ignoré ;
- incrément <= 0 : ignoré ;
- niveau final capé à 100 ;
- pas de stats recalculées ;
- pas de moves learned ;
- pas d'évolution.

## 8. Trainer defeated policy

La policy existante est conservée :

- `runtime_battle_outcome_apply.dart` appelle `StoryFlagsManager` en cas de
  `outcome.isVictory` et `TrainerBattleStartRequest`.
- Le flag conventionnel reste `trainer_defeated:<trainerId>`.
- `applyBattleRewards(...)` ne crée aucun flag trainer defeated.

Test P5-05 :

- vérifie qu'un flag `trainer_defeated:p5_existing_trainer` existant est
  préservé ;
- vérifie qu'aucun autre flag `trainer_defeated:*` n'est ajouté.

## 9. Persistence roundtrip

Le test dédié prouve :

```text
GameState avec party + money
-> applyBattleRewards(moneyReward, levelUpsByPartyIndex)
-> saveDataFromGameState(...)
-> gameStateFromSaveData(...)
-> normalizeLoadedGameState(...)
-> money + level-up direct conservés
```

## 10. Ce qui est prouvé

P5-05 prouve :

- `addMoney(...)` augmente `trainerProfile.money` ;
- `addMoney(...)` no-op sur montant non positif ;
- `applyBattleRewards(...)` applique money reward ;
- `applyBattleRewards(...)` préserve map / position / facing / bag / flags /
  consumed events / metadata ;
- `applyBattleRewards(...)` applique un level-up direct minimal ;
- le level-up direct est capé à 100 ;
- les indexes invalides et increments non positifs sont ignorés ;
- une party vide ne casse pas le money reward ;
- la policy trainer defeated n'est pas dupliquée ;
- le résultat survit au roundtrip `SaveData` ;
- aucun id Selbrume n'est hardcodé.

## 11. Ce qui n’est pas prouvé

Non prouvé volontairement :

- XP persistée ;
- courbe XP ;
- formule XP Pokémon ;
- distribution automatique selon participants / ennemis ;
- level-up avec recalcul stats ;
- moves learned ;
- évolution ;
- reward items depuis battle reward model ;
- badges complets ;
- UI reward.

## 12. Limites et reports vers P5-06 / P5-07 / P5-09

Reports :

- P5-06 : capture destination party-or-box.
- P5-07 : roundtrip gameplay bêta plus large incluant combat / reward /
  capture si présent.
- P5-09 : diagnostics de jouabilité pour rewards incohérents, trainer refs,
  starter/party et prérequis de lancement.

XP persistée complète reste un gap assumé. Si la bêta exige une barre XP
persistante avant le checkpoint, il faudra un micro-lot dédié plutôt qu'un champ
ajouté furtivement.

## 13. Tests exécutés

Test rouge initial :

```text
cd packages/map_gameplay && dart test test/battle_reward_operations_test.dart

00:00 +0: loading test/battle_reward_operations_test.dart
00:00 +0 -1: loading test/battle_reward_operations_test.dart [E]
Failed to load "test/battle_reward_operations_test.dart":
Error: The method 'addMoney' isn't defined for the type 'GameStateMutations'.
Error: The method 'applyBattleRewards' isn't defined for the type 'GameStateMutations'.
00:00 +0 -1: Some tests failed.
```

Test ciblé final :

```text
cd packages/map_gameplay && dart test test/battle_reward_operations_test.dart

00:00 +0: loading test/battle_reward_operations_test.dart
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

Régressions :

```text
cd packages/map_gameplay && dart test test/party_bag_heal_operations_test.dart

00:00 +0: loading test/party_bag_heal_operations_test.dart
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
cd packages/map_gameplay && dart test test/new_game_initial_party_test.dart

00:00 +0: loading test/new_game_initial_party_test.dart
00:00 +0: P5-03 initial party flow creates a starter party from a P5-02 New Game state
00:00 +1: P5-03 initial party flow trims starter speciesId through givePokemon
00:00 +2: P5-03 initial party flow keeps blank starter speciesId as a safe no-op
00:00 +3: P5-03 initial party flow preserves New Game map, spawn, bag, money, and progression
00:00 +4: P5-03 initial party flow round-trips the initial party through SaveData
00:00 +5: P5-03 initial party flow prevents duplicate starter species when requested
00:00 +6: P5-03 initial party flow persistence validation rejects invalid starter level
00:00 +7: P5-03 initial party flow persistence validation rejects blank starter move ids
00:00 +8: P5-03 initial party flow does not hardcode Selbrume-specific ids
00:00 +9: All tests passed!
```

```text
cd packages/map_gameplay && dart test test/give_pokemon_test.dart

00:00 +0: loading test/give_pokemon_test.dart
00:00 +0: GameStateMutations.givePokemon adds a Pokemon to an empty party
00:00 +1: GameStateMutations.givePokemon appends to an existing party
00:00 +2: GameStateMutations.givePokemon preserves existing party members
00:00 +3: GameStateMutations.givePokemon preserves bag
00:00 +4: GameStateMutations.givePokemon preserves storyFlags
00:00 +5: GameStateMutations.givePokemon preserves currentMapId and playerPosition
00:00 +6: GameStateMutations.givePokemon preserves progression
00:00 +7: GameStateMutations.givePokemon is a no-op when speciesId is empty
00:00 +8: GameStateMutations.givePokemon is a no-op when speciesId is blank
00:00 +9: GameStateMutations.givePokemon trims speciesId whitespace
00:00 +10: GameStateMutations.givePokemon prevents duplicate species when requested
00:00 +11: GameStateMutations.givePokemon allows duplicate species when preventDuplicateSpecies is false
00:00 +12: GameStateMutations.givePokemon allows duplicate species by default
00:00 +13: GameStateMutations.givePokemon does not hardcode any Selbrume ids
00:00 +14: GameStateMutations.givePokemon round-trips through save/load
00:00 +15: GameStateMutations.givePokemon full flow: createNewGameState then givePokemon then save/load
00:00 +16: All tests passed!
```

```text
cd packages/map_core && dart test test/game_state_persistence_test.dart

00:00 +0: loading test/game_state_persistence_test.dart
00:00 +0: gameStateFromSaveData migrates legacy save fields to GameState
00:00 +1: saveDataFromGameState keeps core fields and merges story flags in legacy slot
00:00 +2: saveDataFromGameState syncs party species into caught and seen for persistence
00:00 +3: normalizeLoadedGameState hydrates storyFlags from progression when storyFlags are empty
00:00 +4: normalizeLoadedGameState keeps explicit storyFlags as source of truth when already set
00:00 +5: normalizeLoadedGameState hydrates caught and seen from party for legacy states
00:00 +6: normalizeLoadedGameState markSpeciesSeenInGameState adds seen without inventing caught
00:00 +7: All tests passed!
```

Analyse :

```text
cd packages/map_gameplay && dart analyze

Analyzing map_gameplay...
No issues found!
```

Format :

```text
cd packages/map_gameplay && dart format --set-exit-if-changed lib/src/game_state_mutations.dart test/battle_reward_operations_test.dart

Formatted 2 files (0 changed) in 0.01 seconds.
```

## 14. Modifications effectuées

Fichiers créés :

- `packages/map_gameplay/test/battle_reward_operations_test.dart`
- `reports/roadmap/phase_5/p5_05_battle_rewards_money_xp_minimal_apply.md`

Fichiers modifiés :

- `packages/map_gameplay/lib/src/game_state_mutations.dart`
- `MVP Selbrume/road_map_phase_5.md`

Non modifiés :

- `MVP Selbrume/road_map_global.md`
- `packages/map_core/lib/src/models/save_data.dart`
- `packages/map_core/lib/src/models/game_state.dart`
- `packages/map_runtime`
- `packages/map_battle`

## 15. Evidence Pack

### Git status initial exact

```text
git status --short --untracked-files=all

<sortie vide>
```

### Commandes exécutées

```text
sed -n '1,220p' /Users/karim/.codex/plugins/cache/openai-curated/superpowers/6188456f/skills/test-driven-development/SKILL.md
sed -n '1,180p' /Users/karim/.codex/skills/dart-add-unit-test/SKILL.md
git status --short --untracked-files=all
sed -n '1,260p' pokemap_roadmap_mecaniques_fangame.md
sed -n '1,360p' "MVP Selbrume/road_map_global.md"
sed -n '1,1040p' "MVP Selbrume/road_map_phase_5.md"
sed -n '1,320p' reports/roadmap/phase_5/p5_04_party_bag_heal_minimal_operations.md
sed -n '1,420p' packages/map_gameplay/lib/src/game_state_mutations.dart
sed -n '1,260p' packages/map_gameplay/lib/map_gameplay.dart
sed -n '1,360p' packages/map_gameplay/test/party_bag_heal_operations_test.dart
sed -n '1,360p' packages/map_gameplay/test/new_game_initial_party_test.dart
sed -n '1,460p' packages/map_core/lib/src/models/save_data.dart
sed -n '1,260p' packages/map_core/lib/src/models/game_state.dart
sed -n '1,260p' packages/map_core/lib/src/operations/game_state_persistence.dart
sed -n '1,320p' packages/map_runtime/lib/src/application/runtime_battle_outcome_apply.dart
sed -n '1,300p' packages/map_runtime/test/reward_bridge_readiness_test.dart
rg -n "money|TrainerProfile|reward|battle reward|BattleReward|XP|xp|experience|level|level-up|levelUp|trainer defeated|trainerDefeated|defeatedTrainer|battle:|victory|BattleOutcome|runtime_battle_outcome_apply|markTrainer|giveItem|completeStep" packages/map_core packages/map_gameplay packages/map_runtime packages/map_battle --glob '!build/**' --glob '!**/.dart_tool/**'
find packages/map_gameplay/test -maxdepth 2 -type f | sort | rg "reward|money|xp|level|battle|party|bag|heal|pokemon"
find packages/map_runtime/test -maxdepth 3 -type f | sort | rg "reward|money|xp|level|battle|trainer"
find packages/map_core/test -maxdepth 2 -type f | sort | rg "game_state|save|pokemon|party|money|level"
sed -n '1,220p' packages/map_runtime/lib/src/application/story_flags_manager.dart
find packages/map_battle/lib -type f | sort | head -200
rg -n "money|TrainerProfile|addMoney|applyMoney|giveMoney|PlayerPokemon\\(|levelUp|level-up|experience|XP|xp" packages/map_core/lib/src packages/map_gameplay/lib/src packages/map_gameplay/test packages/map_core/test --glob '!build/**' --glob '!**/.dart_tool/**'
rg -n "trainer_defeated|trainerDefeated|markTrainerDefeated|isTrainerDefeated|BattleOutcome|isVictory|runtime_battle_outcome_apply" packages/map_runtime/lib/src/application packages/map_runtime/test packages/map_battle/lib/src --glob '!build/**' --glob '!**/.dart_tool/**'
sed -n '320,520p' packages/map_runtime/lib/src/application/runtime_battle_outcome_apply.dart
sed -n '1,220p' packages/map_runtime/test/trainer_defeated_test.dart
sed -n '1,220p' packages/map_runtime/test/runtime_battle_outcome_apply_test.dart
cd packages/map_gameplay && dart test test/battle_reward_operations_test.dart
cd packages/map_gameplay && dart format --set-exit-if-changed lib/src/game_state_mutations.dart test/battle_reward_operations_test.dart
cd packages/map_gameplay && dart test test/battle_reward_operations_test.dart
cd packages/map_gameplay && dart test test/party_bag_heal_operations_test.dart
cd packages/map_gameplay && dart test test/new_game_initial_party_test.dart
cd packages/map_gameplay && dart test test/give_pokemon_test.dart
cd packages/map_core && dart test test/game_state_persistence_test.dart
cd packages/map_gameplay && dart analyze
sed -n '1,260p' packages/map_gameplay/test/battle_reward_operations_test.dart
git diff -- packages/map_gameplay/lib/src/game_state_mutations.dart "MVP Selbrume/road_map_phase_5.md"
git status --short --untracked-files=all
```

### Sorties utiles

`save_data.dart` :

```text
TrainerProfile: name, badgeIds, money, playtimeSeconds.
PlayerPokemon: speciesId, natureId, abilityId, level, ivs, evs, knownMoveIds,
currentHp, statusId, isShiny, heldItemId.
PlayerPokemon.normalized(): level must be between 1 and 100.
```

`runtime_battle_outcome_apply.dart` :

```text
if (outcome.isVictory && request is TrainerBattleStartRequest) {
  return storyFlagsManager.markTrainerDefeated(
    stateWithPlayerHp,
    request.trainerId,
  );
}
```

`reward_bridge_readiness_test.dart` :

```text
post battle item reward does not imply money xp or level up
expect(state.trainerProfile.money, 500);
expect(member.level, 7);
```

Fichiers tests trouvés :

```text
packages/map_gameplay/test/give_pokemon_test.dart
packages/map_gameplay/test/new_game_initial_party_test.dart
packages/map_gameplay/test/party_bag_heal_operations_test.dart
packages/map_runtime/test/reward_bridge_readiness_test.dart
packages/map_runtime/test/runtime_battle_outcome_apply_test.dart
packages/map_runtime/test/trainer_defeated_test.dart
packages/map_core/test/game_state_persistence_test.dart
```

### Contenu complet du nouveau test

```dart
import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:test/test.dart';

void main() {
  const mutations = GameStateMutations();

  PlayerPokemon pokemon({
    String speciesId = 'p5_reward_species',
    int level = 8,
    int currentHp = 16,
  }) {
    return PlayerPokemon(
      speciesId: speciesId,
      natureId: 'hardy',
      abilityId: 'p5_reward_ability',
      level: level,
      knownMoveIds: const ['p5_reward_tackle'],
      currentHp: currentHp,
    );
  }

  GameState rewardState({
    int money = 100,
    List<PlayerPokemon> members = const [],
    Set<String> storyFlags = const {},
  }) {
    var state = GameState(
      saveId: 'p5_battle_reward_save',
      currentMapId: 'p5_battle_reward_map',
      playerPosition: const GridPos(x: 6, y: 3),
      playerFacing: EntityFacing.east,
      trainerProfile: TrainerProfile(name: 'P5 Player', money: money),
      party: PlayerParty(members: members),
      bag: const Bag(
        entries: [
          BagEntry(itemId: 'potion', categoryId: 'medicine', quantity: 2),
        ],
      ),
      storyFlags: StoryFlags(activeFlags: storyFlags),
      metadata: const {'lot': 'p5_05'},
    );
    state = mutations.markEventConsumed(state, 'p5.event.before_reward');
    return state;
  }

  group('GameStateMutations.addMoney', () {
    test('increases trainerProfile money', () {
      final state = rewardState(money: 120);

      final updated = mutations.addMoney(state, 35);

      expect(updated.trainerProfile.money, 155);
      expect(updated.currentMapId, state.currentMapId);
      expect(updated.playerPosition, state.playerPosition);
      expect(updated.bag, state.bag);
    });

    test('is a no-op for non-positive amounts', () {
      final state = rewardState(money: 120);

      expect(mutations.addMoney(state, 0), same(state));
      expect(mutations.addMoney(state, -10), same(state));
    });
  });

  group('GameStateMutations.applyBattleRewards', () {
    test('applies money reward and preserves world state', () {
      final state = rewardState(
        money: 50,
        members: [pokemon()],
        storyFlags: const {'trainer_defeated:p5_existing_trainer'},
      );

      final updated = mutations.applyBattleRewards(
        state,
        moneyReward: 200,
      );

      expect(updated.trainerProfile.money, 250);
      expect(updated.currentMapId, state.currentMapId);
      expect(updated.playerPosition, state.playerPosition);
      expect(updated.playerFacing, state.playerFacing);
      expect(updated.bag, state.bag);
      expect(updated.party, state.party);
      expect(updated.storyFlags, state.storyFlags);
      expect(updated.consumedEventIds, state.consumedEventIds);
      expect(updated.metadata, state.metadata);
    });

    test('applies direct minimal level-up when XP is not persisted', () {
      final state = rewardState(
        members: [
          pokemon(speciesId: 'p5_reward_a', level: 8),
          pokemon(speciesId: 'p5_reward_b', level: 12),
        ],
      );

      final updated = mutations.applyBattleRewards(
        state,
        levelUpsByPartyIndex: const {0: 2, 1: 1},
      );

      expect(updated.party.members[0].level, 10);
      expect(updated.party.members[1].level, 13);
      expect(updated.party.members[0].knownMoveIds, ['p5_reward_tackle']);
      expect(updated.party.members[1].currentHp, 16);
    });

    test('caps direct level-up at PlayerPokemon max level', () {
      final state = rewardState(
        members: [pokemon(level: 99)],
      );

      final updated = mutations.applyBattleRewards(
        state,
        levelUpsByPartyIndex: const {0: 5},
      );

      expect(updated.party.members.single.level, 100);
    });

    test('ignores invalid party indexes and non-positive level increments', () {
      final state = rewardState(
        members: [pokemon(level: 9)],
      );

      final updated = mutations.applyBattleRewards(
        state,
        levelUpsByPartyIndex: const {
          -1: 5,
          0: 0,
          1: 3,
        },
      );

      expect(updated, same(state));
    });

    test('applies money even when party is empty', () {
      final state = rewardState(money: 5);

      final updated = mutations.applyBattleRewards(
        state,
        moneyReward: 15,
        levelUpsByPartyIndex: const {0: 1},
      );

      expect(updated.trainerProfile.money, 20);
      expect(updated.party.members, isEmpty);
    });

    test('does not create or duplicate trainer defeated policy', () {
      final state = rewardState(
        members: [pokemon()],
        storyFlags: const {'trainer_defeated:p5_existing_trainer'},
      );

      final updated = mutations.applyBattleRewards(
        state,
        moneyReward: 10,
        levelUpsByPartyIndex: const {0: 1},
      );

      expect(
        updated.storyFlags.activeFlags
            .where((flag) => flag.startsWith('trainer_defeated:')),
        ['trainer_defeated:p5_existing_trainer'],
      );
    });

    test('round-trips money and direct level-up through SaveData', () {
      final state = rewardState(
        money: 25,
        members: [pokemon(speciesId: 'p5_roundtrip_species', level: 14)],
      );

      final rewarded = mutations.applyBattleRewards(
        state,
        moneyReward: 75,
        levelUpsByPartyIndex: const {0: 3},
      );
      final saveData = saveDataFromGameState(rewarded);
      final reloaded =
          normalizeLoadedGameState(gameStateFromSaveData(saveData));

      expect(reloaded.trainerProfile.money, 100);
      expect(reloaded.party.members.single.speciesId, 'p5_roundtrip_species');
      expect(reloaded.party.members.single.level, 17);
      expect(reloaded.bag.entries.single.itemId, 'potion');
      expect(reloaded.metadata, state.metadata);
    });

    test('does not hardcode any Selbrume ids', () {
      final state = rewardState(
        members: [pokemon(speciesId: 'p5_generic_reward_species')],
      );

      final updated = mutations.applyBattleRewards(
        state,
        moneyReward: 1,
        levelUpsByPartyIndex: const {0: 1},
      );

      final joined = [
        updated.currentMapId,
        updated.party.members.single.speciesId,
        ...updated.party.members.single.knownMoveIds,
      ].join('|').toLowerCase();

      expect(joined, isNot(contains('selbrume')));
      expect(joined, isNot(contains('lysa')));
      expect(joined, isNot(contains('mael')));
      expect(joined, isNot(contains('brume')));
    });
  });
}
```

### Diff complet des fichiers modifiés

```diff
diff --git a/MVP Selbrume/road_map_phase_5.md b/MVP Selbrume/road_map_phase_5.md
index a9b2ec05..e239a35f 100644
--- a/MVP Selbrume/road_map_phase_5.md	
+++ b/MVP Selbrume/road_map_phase_5.md	
@@ -9,6 +9,7 @@ P5-01 : terminé.
 P5-02 : terminé.
 P5-03 : terminé.
 P5-04 : terminé.
+P5-05 : terminé.
 
 Phase 5 reste orientée vers une boucle RPG minimale prouvable, pas vers une
 parité Pokémon complète, pas vers Selbrume final, pas vers une UI premium.
@@ -16,7 +17,7 @@ parité Pokémon complète, pas vers Selbrume final, pas vers une UI premium.
 Prochain lot exact :
 
 ```text
-P5-05 — Battle Rewards / Money / XP Minimal Apply V0
+P5-06 — Capture Destination Party-or-Box V0
 ```
 
 ## Objectif Phase 5
@@ -198,7 +199,7 @@ tests purs
 
 ### P5-05 — Battle Rewards / Money / XP Minimal Apply V0
 
-Statut : prochain lot exact.
+Statut : terminé.
 
 But :
 
@@ -219,6 +220,8 @@ pas de système complet de moves learned / evolution
 
 ### P5-06 — Capture Destination Party-or-Box V0
 
+Statut : prochain lot exact.
+
 But :
 
 ```text
diff --git a/packages/map_gameplay/lib/src/game_state_mutations.dart b/packages/map_gameplay/lib/src/game_state_mutations.dart
index d15601fb..ad1a62bd 100644
--- a/packages/map_gameplay/lib/src/game_state_mutations.dart
+++ b/packages/map_gameplay/lib/src/game_state_mutations.dart
@@ -310,6 +310,73 @@ class GameStateMutations {
     );
   }
 
+  /// Ajoute de l'argent au profil joueur.
+  ///
+  /// No-op sûr si [amount] est nul ou négatif. Cette mutation reste un reward
+  /// minimal : elle ne crée ni shop, ni moteur économique.
+  GameState addMoney(GameState state, int amount) {
+    if (amount <= 0) {
+      return state;
+    }
+
+    return state.copyWith(
+      trainerProfile: state.trainerProfile.copyWith(
+        money: state.trainerProfile.money + amount,
+      ),
+    );
+  }
+
+  /// Applique les récompenses minimales d'une victoire de combat.
+  ///
+  /// `PlayerPokemon` ne persiste pas encore d'XP courante. Le chemin V0 expose
+  /// donc uniquement un level-up direct et déterministe fourni par l'appelant.
+  /// La policy `trainer_defeated:{trainerId}` reste portée par le runtime.
+  GameState applyBattleRewards(
+    GameState state, {
+    int moneyReward = 0,
+    Map<int, int> levelUpsByPartyIndex = const {},
+  }) {
+    var nextState = addMoney(state, moneyReward);
+
+    if (levelUpsByPartyIndex.isEmpty || nextState.party.members.isEmpty) {
+      return nextState;
+    }
+
+    final nextMembers = List<PlayerPokemon>.of(
+      nextState.party.members,
+      growable: false,
+    );
+    var changed = false;
+
+    for (final entry in levelUpsByPartyIndex.entries) {
+      final partyIndex = entry.key;
+      final levelIncrement = entry.value;
+      if (partyIndex < 0 ||
+          partyIndex >= nextMembers.length ||
+          levelIncrement <= 0) {
+        continue;
+      }
+
+      final member = nextMembers[partyIndex];
+      final nextLevel = member.level + levelIncrement;
+      final cappedLevel = nextLevel > 100 ? 100 : nextLevel;
+      if (cappedLevel == member.level) {
+        continue;
+      }
+
+      nextMembers[partyIndex] = member.copyWith(level: cappedLevel);
+      changed = true;
+    }
+
+    if (!changed) {
+      return nextState;
+    }
+
+    return nextState.copyWith(
+      party: nextState.party.copyWith(members: nextMembers),
+    );
+  }
+
   /// Donne un Pokémon au joueur.
   ///
   /// Le [PlayerPokemon] doit être construit par l'appelant (authoring, script,
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
 MVP Selbrume/road_map_phase_5.md                   |  7 ++-
 .../map_gameplay/lib/src/game_state_mutations.dart | 67 ++++++++++++++++++++++
 2 files changed, 72 insertions(+), 2 deletions(-)
```

Commande :

```bash
git diff --name-only
```

Sortie exacte :

```text
MVP Selbrume/road_map_phase_5.md
packages/map_gameplay/lib/src/game_state_mutations.dart
```

Commande :

```bash
git status --short --untracked-files=all
```

Sortie exacte :

```text
 M "MVP Selbrume/road_map_phase_5.md"
 M packages/map_gameplay/lib/src/game_state_mutations.dart
?? packages/map_gameplay/test/battle_reward_operations_test.dart
?? reports/roadmap/phase_5/p5_05_battle_rewards_money_xp_minimal_apply.md
```

### Contrôles explicites de non-scope

- `road_map_global.md` n'a pas été modifié.
- P5-06 n'a pas été exécuté.
- Boot Flow complet non créé.
- Selbrume final non créé.
- Aucune UI reward créée.
- Aucune capture party-or-box / PC / box ajoutée.
- Aucun moves learned / evolution system ajouté.
- Aucun shop / economy engine ajouté.
- Aucun changement `map_runtime` ou `map_battle`.

## 16. Auto-review critique

Points forts :

- Le lot est concret et test-first.
- Il évite l'XP invisible.
- Il respecte la séparation : reward gameplay pur dans `map_gameplay`,
  trainer defeated runtime dans `map_runtime`.
- Aucun modèle persistant n'a été modifié.

Réserves :

- Le level-up est direct et ne calcule pas l'XP.
- Aucun recalcul de stats ou HP max n'est appliqué au level-up.
- Le mapping battle outcome réel -> reward apply n'est pas branché dans runtime ;
  P5-05 pose seulement l'opération pure minimale.

## 17. Regard critique sur le prompt

Le prompt force la bonne décision : il demande XP, mais autorise de démontrer le
gap si le modèle ne le supporte pas. Ici, ajouter une XP persistée aurait
probablement ouvert une migration et de la génération Freezed hors scope. La
bonne preuve V0 est donc money + level-up direct minimal, avec le gap XP nommé
au lieu d'être masqué.

Prochain lot exact :

```text
P5-06 — Capture Destination Party-or-Box V0
```
