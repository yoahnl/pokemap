# P5-04 — Party / Bag / Heal Minimal Operations V0

## 1. Résumé exécutif

P5-04 est terminé.

Le lot ajoute des opérations pures dans `map_gameplay` pour couvrir le minimum
hors combat :

- `GameStateMutations.consumeItem(...)`
- `GameStateMutations.applyHpMedicineToPartyMember(...)`
- `GameStateMutations.recoverParty(...)`

Le choix principal est de ne pas créer de système d'items complet. L'effet de
medicine est fourni explicitement par l'appelant (`healAmount`, `maxHp`) parce
que `PlayerPokemon` persiste `currentHp` mais ne persiste pas `maxHp`.

La preuve est un test dédié avec roundtrip `SaveData`, plus les régressions
P5-02/P5-03 et persistence core.

## 2. Scope du lot

Inclus :

- opérations pures de bag consume ;
- opération medicine HP hors combat avec cap HP explicite ;
- opération recovery point / heal party avec caps HP explicites ;
- no-op sûrs pour entrées invalides ;
- conservation de map, position, facing, party, bag, progression, flags,
  consumed events et metadata selon l'opération ;
- preuve de persistence via `saveDataFromGameState(...)`,
  `gameStateFromSaveData(...)`, `normalizeLoadedGameState(...)` ;
- audit de l'UI bag existante dans `examples/playable_runtime_host`.

Exclus :

- UI party / bag / heal ;
- menu runtime complet ;
- Pokemon Center UI ;
- shop ;
- ItemRegistry / ItemEffectRegistry ;
- reward money apply ;
- XP / level-up ;
- capture party-or-box / PC / box ;
- Boot Flow ;
- Selbrume.

## 3. Sources lues

Sources principales :

- `AGENTS.md` fourni dans le prompt.
- `pokemap_roadmap_mecaniques_fangame.md`
- `MVP Selbrume/road_map_global.md`
- `MVP Selbrume/road_map_phase_5.md`
- `reports/roadmap/phase_5/p5_03_starter_initial_party_minimal_flow.md`
- `packages/map_gameplay/lib/src/game_state_mutations.dart`
- `packages/map_gameplay/lib/map_gameplay.dart`
- `packages/map_gameplay/test/game_state_mutations_test.dart`
- `packages/map_gameplay/test/give_pokemon_test.dart`
- `packages/map_gameplay/test/new_game_initial_party_test.dart`
- `packages/map_core/lib/src/models/save_data.dart`
- `packages/map_core/lib/src/models/game_state.dart`
- `packages/map_core/lib/src/operations/game_state_persistence.dart`
- `packages/map_runtime/lib/src/application/runtime_battle_bag_hp_heal_item_apply.dart`
- `examples/playable_runtime_host/lib/src/in_game_menu.dart`
- `examples/playable_runtime_host/test/in_game_menu_test.dart`

Sorties utiles observées :

- `PlayerPokemon` porte `currentHp` et `statusId`, mais pas `maxHp`.
- `BagEntry` porte `itemId`, `categoryId`, `quantity`.
- `GameStateMutations.giveItem(...)` existe déjà, no-op sur `itemId` vide ou
  `quantity <= 0`, et classe les medicines connues dans `categoryId =
  medicine`.
- `map_runtime` contient une logique battle-specific de potion, mais couplée à
  `BattleSession` et au write-back battle ; elle n'est pas la bonne couche pour
  les opérations overworld P5-04.
- `examples/playable_runtime_host/lib/src/in_game_menu.dart` contient déjà une
  section bag/party en lecture seule. Aucune extension n'a été ajoutée.

## 4. État initial party / bag / heal

État initial avant P5-04 :

- `GameStateMutations.giveItem(...)` permettait d'ajouter un item au bag.
- `GameStateMutations.givePokemon(...)` permettait d'ajouter une créature à la
  party.
- `SaveData` conservait déjà `party` et `bag`.
- Les opérations inverses ou de soin hors combat n'existaient pas dans
  `map_gameplay`.
- Le soin HP existait côté battle runtime, mais pas comme opération pure
  overworld.

## 5. Audit UI bag dans examples/playable_runtime_host

Résultat de l'audit :

- `examples/playable_runtime_host/lib/src/in_game_menu.dart` contient
  `_BagSection`, qui regroupe les `BagEntry` par catégorie et affiche `itemId`
  / quantité.
- Le même fichier contient `_PartySection` et `_PartyPokemonCard`, qui affichent
  la party persistée, les PV actuels, le statut, l'objet tenu et les moves.
- `examples/playable_runtime_host/test/in_game_menu_test.dart` teste déjà cet
  affichage.
- Cette UI vit dans le host d'exemple, pas dans `map_runtime`.

Dette documentée :

```text
UI bag actuellement dans examples/playable_runtime_host.
À extraire plus tard vers packages/map_runtime si/quand on travaille sur l'UI
runtime du sac.
```

Décision P5-04 :

- aucune nouvelle UI bag ajoutée ;
- aucune logique durable bag/heal ajoutée dans `examples/playable_runtime_host`;
- aucune migration UI effectuée dans ce lot.

## 6. Opérations ajoutées ou réutilisées

Réutilisé :

- `GameStateMutations.giveItem(...)`
- `GameStateMutations.givePokemon(...)`
- `saveDataFromGameState(...)`
- `gameStateFromSaveData(...)`
- `normalizeLoadedGameState(...)`

Ajouté dans `packages/map_gameplay/lib/src/game_state_mutations.dart` :

- `consumeItem(...)`
- `applyHpMedicineToPartyMember(...)`
- `recoverParty(...)`

Le barrel `packages/map_gameplay/lib/map_gameplay.dart` exportait déjà
`game_state_mutations.dart`, donc aucun export supplémentaire n'était requis.

## 7. Bag consume minimal

`consumeItem(...)` :

- trim `itemId` ;
- no-op si `itemId` est vide ;
- no-op si `quantity <= 0` ;
- no-op si l'item est absent ;
- no-op si la quantité disponible est insuffisante ;
- décrémente la quantité si possible ;
- retire l'entrée si la quantité tombe à zéro ;
- renvoie un nouveau `GameState` seulement quand une mutation réelle existe.

## 8. Medicine outside battle

`applyHpMedicineToPartyMember(...)` :

- sélectionne un membre par `partyIndex` ;
- trim `itemId` ;
- no-op si index invalide, item absent, `healAmount <= 0`, `maxHp <= 0`, ou HP
  déjà au cap ;
- consomme exactement un item via `consumeItem(...)` ;
- ajoute `healAmount` à `currentHp` ;
- cap à `maxHp` fourni explicitement ;
- ne crée aucune table `potion -> 20 HP` ;
- ne crée aucun `ItemRegistry` ou `ItemEffectRegistry`.

Limite volontaire :

L'opération ne déduit pas si un item est une medicine depuis un registry. Le
contrat V0 est : l'appelant fournit l'item et son effet numérique.

## 9. Heal party / recovery point

`recoverParty(...)` :

- prend `maxHpByPartyIndex` ;
- restaure chaque membre dont l'index a un cap HP strictement positif ;
- clear `statusId` par défaut ;
- garde les membres sans cap valide inchangés ;
- ne consomme aucun item ;
- représente le minimum opérationnel d'un recovery point, sans Pokemon Center UI
  et sans contenu.

## 10. Persistence roundtrip

Le test dédié prouve :

```text
GameState avec party + bag
-> applyHpMedicineToPartyMember(...)
-> recoverParty(...)
-> saveDataFromGameState(...)
-> gameStateFromSaveData(...)
-> normalizeLoadedGameState(...)
-> party healed + bag décrémenté conservés
```

## 11. Dette UI bag examples et report vers map_runtime

La dette existe déjà :

- `examples/playable_runtime_host` porte une UI bag/party de host et des tests
  associés.
- Ce host reste utile comme banc de test runtime, mais ne doit pas devenir la
  source durable de l'UI produit.

Report :

- extraction éventuelle vers `packages/map_runtime` lors d'un futur lot UI
  runtime ;
- pas dans P5-04 ;
- pas dans P5-05.

## 12. Ce qui est prouvé

P5-04 prouve :

- lecture de party persistée via `GameState.party.members` dans un test de flux ;
- consommation d'item par quantité partielle ;
- retrait d'entrée bag à quantité zéro ;
- no-op sûrs pour item absent, id blank, quantité invalide, quantité
  insuffisante ;
- soin HP hors combat avec cap explicite ;
- consommation de l'item de medicine ;
- no-op sûr sur index invalide / item absent / aucun soin utile ;
- recovery party multi-membres ;
- clear status par recovery ;
- persistence de party/bag après heal ;
- aucun id Selbrume hardcodé.

## 13. Ce qui n’est pas prouvé

Non prouvé volontairement :

- UI bag interactive ;
- UI party interactive ;
- Pokemon Center UI ;
- calcul de `maxHp` depuis species/stats ;
- registry d'items ou d'effets ;
- shop ;
- reward money apply ;
- XP / level-up ;
- capture destination party-or-box ;
- PC / box.

## 14. Limites et reports vers P5-05 / P5-06 / P5-07 / P5-09

Reports :

- P5-05 : rewards / money / XP, sans réutiliser P5-04 comme reward apply.
- P5-06 : capture destination party-or-box et party full.
- P5-07 : roundtrip save/load gameplay bêta plus large.
- P5-09 : validation bêta de projet lançable, y compris diagnostics d'items /
  party / heal si nécessaire.

## 15. Tests exécutés

Test rouge initial :

```text
cd packages/map_gameplay && dart test test/party_bag_heal_operations_test.dart

00:00 +0: loading test/party_bag_heal_operations_test.dart
00:00 +0 -1: loading test/party_bag_heal_operations_test.dart [E]
Failed to load "test/party_bag_heal_operations_test.dart":
Error: The method 'consumeItem' isn't defined for the type 'GameStateMutations'.
Error: The method 'applyHpMedicineToPartyMember' isn't defined for the type 'GameStateMutations'.
Error: The method 'recoverParty' isn't defined for the type 'GameStateMutations'.
00:00 +0 -1: Some tests failed.
```

Test ciblé final :

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

Régressions ciblées :

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
cd packages/map_gameplay && dart test test/game_state_mutations_test.dart

00:00 +0: loading test/game_state_mutations_test.dart
00:00 +0: GameStateMutations - giveItem giveItem adds a new item to an empty Bag
00:00 +1: GameStateMutations - giveItem giveItem adds a new item of default category items
00:00 +2: GameStateMutations - giveItem giveItem accumulates quantity if the item already exists
00:00 +3: GameStateMutations - giveItem giveItem preserves other items in the Bag
00:00 +4: GameStateMutations - giveItem giveItem does nothing (no-op) when quantity <= 0
00:00 +5: GameStateMutations - giveItem giveItem does nothing (no-op) when itemId is empty or whitespace-only
00:00 +6: All tests passed!
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
cd packages/map_gameplay && dart format --set-exit-if-changed lib/src/game_state_mutations.dart test/party_bag_heal_operations_test.dart

Formatted test/party_bag_heal_operations_test.dart
Formatted 2 files (1 changed) in 0.01 seconds.
```

```text
cd packages/map_gameplay && dart format --set-exit-if-changed lib/src/game_state_mutations.dart test/party_bag_heal_operations_test.dart

Formatted 2 files (0 changed) in 0.01 seconds.
```

## 16. Modifications effectuées

Fichiers créés :

- `packages/map_gameplay/test/party_bag_heal_operations_test.dart`
- `reports/roadmap/phase_5/p5_04_party_bag_heal_minimal_operations.md`

Fichiers modifiés :

- `packages/map_gameplay/lib/src/game_state_mutations.dart`
- `MVP Selbrume/road_map_phase_5.md`

Aucun fichier modifié dans :

- `examples/playable_runtime_host`
- `packages/map_runtime`
- `packages/map_core/lib/src/models/game_state.dart`
- `packages/map_core/lib/src/models/save_data.dart`

## 17. Evidence Pack

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
sed -n '1,980p' "MVP Selbrume/road_map_phase_5.md"
sed -n '1,320p' reports/roadmap/phase_5/p5_03_starter_initial_party_minimal_flow.md
sed -n '1,360p' packages/map_gameplay/lib/src/game_state_mutations.dart
sed -n '1,260p' packages/map_gameplay/lib/map_gameplay.dart
sed -n '1,360p' packages/map_gameplay/test/game_state_mutations_test.dart
sed -n '1,260p' packages/map_gameplay/test/new_game_initial_party_test.dart
sed -n '1,420p' packages/map_core/lib/src/models/save_data.dart
sed -n '1,260p' packages/map_core/lib/src/models/game_state.dart
sed -n '1,260p' packages/map_core/lib/src/operations/game_state_persistence.dart
test -f packages/map_runtime/lib/src/application/runtime_battle_bag_hp_heal_item_apply.dart && sed -n '1,260p' packages/map_runtime/lib/src/application/runtime_battle_bag_hp_heal_item_apply.dart || echo ABSENT
rg -n "Bag|BagEntry|giveItem|consume|removeItem|itemId|quantity|medicine|heal|currentHp|maxHp|statusId|PlayerPokemon|PlayerParty|party|recover|revive|hp" packages/map_core packages/map_gameplay packages/map_runtime examples/playable_runtime_host --glob '!build/**' --glob '!**/.dart_tool/**'
rg -n "Bag|bag|inventory|item|medicine|heal|party|menu|overlay|potion|use item|useItem" examples/playable_runtime_host --glob '!build/**' --glob '!**/.dart_tool/**'
find packages/map_gameplay/test -maxdepth 2 -type f | sort | rg "bag|heal|party|pokemon|game_state|new_game"
find packages/map_runtime/test -maxdepth 3 -type f | sort | rg "bag|heal|party|battle|medicine"
find packages/map_core/test -maxdepth 2 -type f | sort | rg "game_state|save|bag|pokemon|party"
find examples/playable_runtime_host -maxdepth 4 -type f | sort | rg "bag|item|party|menu|overlay|inventory|heal"
sed -n '208,290p' packages/map_runtime/lib/src/application/runtime_battle_bag_hp_heal_item_apply.dart
sed -n '420,620p' examples/playable_runtime_host/lib/src/in_game_menu.dart
sed -n '1,220p' packages/map_gameplay/test/give_pokemon_test.dart
sed -n '1,260p' packages/map_gameplay/test/game_state_mutations_test.dart
rg -n "class StoryFlags|class GameProgression|class PlayerMovement|class GridPos|enum Direction|enum Facing|PlayerFacing|copyWith" packages/map_core/lib/src/models packages/map_core/lib/src --glob '!build/**' --glob '!**/.dart_tool/**'
sed -n '1,180p' packages/map_core/lib/src/models/enums.dart
sed -n '1,140p' packages/map_core/lib/src/models/game_state.dart
cd packages/map_gameplay && dart test test/party_bag_heal_operations_test.dart
cd packages/map_gameplay && dart format --set-exit-if-changed lib/src/game_state_mutations.dart test/party_bag_heal_operations_test.dart
cd packages/map_gameplay && dart test test/party_bag_heal_operations_test.dart
cd packages/map_gameplay && dart test test/new_game_initial_party_test.dart
cd packages/map_gameplay && dart test test/give_pokemon_test.dart
cd packages/map_gameplay && dart test test/game_state_mutations_test.dart
cd packages/map_core && dart test test/game_state_persistence_test.dart
cd packages/map_gameplay && dart analyze
git diff -- packages/map_gameplay/lib/src/game_state_mutations.dart packages/map_gameplay/test/party_bag_heal_operations_test.dart "MVP Selbrume/road_map_phase_5.md"
rg -n "P5-04|P5-05|Prochain lot exact|Phase 5" "MVP Selbrume/road_map_phase_5.md"
sed -n '1,240p' "MVP Selbrume/road_map_phase_5.md"
```

### Sorties utiles des recherches

Recherche UI bag host :

```text
examples/playable_runtime_host/lib/src/in_game_menu.dart:151: InGameMenuSection.bag => _BagSection(gameState: gameState),
examples/playable_runtime_host/lib/src/in_game_menu.dart:430: class _BagSection extends StatelessWidget {
examples/playable_runtime_host/lib/src/in_game_menu.dart:444: final entriesByCategory = <String, List<BagEntry>>{};
examples/playable_runtime_host/lib/src/in_game_menu.dart:471: key: Key('bag-entry-${entry.itemId}'),
examples/playable_runtime_host/lib/src/in_game_menu.dart:499: final members = gameState.party.members;
examples/playable_runtime_host/test/in_game_menu_test.dart:72: expect(find.byKey(const Key('in-game-bag-section')), findsOneWidget);
examples/playable_runtime_host/test/in_game_menu_test.dart:73: expect(find.byKey(const Key('bag-entry-potion')), findsOneWidget);
```

Fichiers tests trouvés :

```text
packages/map_gameplay/test/game_state_mutations_test.dart
packages/map_gameplay/test/give_pokemon_test.dart
packages/map_gameplay/test/new_game_initial_party_test.dart
packages/map_gameplay/test/new_game_state_builder_test.dart
packages/map_runtime/test/battle_potion_apply_runtime_test.dart
packages/map_runtime/test/wild_battle_end_to_end_flow_test.dart
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
    String speciesId = 'p5_starter_species',
    int level = 7,
    int currentHp = 12,
    String statusId = '',
    List<String> knownMoveIds = const ['p5_tackle'],
  }) {
    return PlayerPokemon(
      speciesId: speciesId,
      level: level,
      natureId: 'hardy',
      abilityId: 'overgrow',
      knownMoveIds: knownMoveIds,
      currentHp: currentHp,
      statusId: statusId,
    );
  }

  GameState partyBagState({
    List<PlayerPokemon> members = const [],
    List<BagEntry> bagEntries = const [],
  }) {
    var state = GameState(
      saveId: 'p5_party_bag_heal_save',
      currentMapId: 'p5_party_bag_heal_map',
      playerPosition: const GridPos(x: 4, y: 9),
      playerFacing: EntityFacing.west,
      party: PlayerParty(members: members),
      bag: Bag(entries: bagEntries),
      metadata: const {'lot': 'p5_04'},
    );
    state = mutations.setFlag(state, 'p5.flag.ready');
    state = mutations.markEventConsumed(state, 'p5.event.consumed');
    return state;
  }

  group('GameStateMutations.consumeItem', () {
    test('decrements an item quantity', () {
      final state = partyBagState(
        members: [pokemon()],
        bagEntries: const [
          BagEntry(itemId: 'potion', categoryId: 'medicine', quantity: 5),
          BagEntry(itemId: 'poke-ball', categoryId: 'items', quantity: 2),
        ],
      );

      final updated = mutations.consumeItem(state, ' potion ', 2);
      final potion =
          updated.bag.entries.singleWhere((entry) => entry.itemId == 'potion');
      final pokeBall = updated.bag.entries
          .singleWhere((entry) => entry.itemId == 'poke-ball');

      expect(potion.quantity, 3);
      expect(pokeBall.quantity, 2);
    });

    test('removes an entry when quantity reaches zero', () {
      final state = partyBagState(
        bagEntries: const [
          BagEntry(itemId: 'potion', categoryId: 'medicine', quantity: 2),
        ],
      );

      final updated = mutations.consumeItem(state, 'potion', 2);

      expect(updated.bag.entries, isEmpty);
    });

    test('preserves party, map, progression and metadata', () {
      final firstPokemon = pokemon(currentHp: 8, statusId: 'poison');
      final state = partyBagState(
        members: [firstPokemon],
        bagEntries: const [
          BagEntry(itemId: 'potion', categoryId: 'medicine', quantity: 3),
        ],
      );

      final updated = mutations.consumeItem(state, 'potion', 1);

      expect(updated.currentMapId, state.currentMapId);
      expect(updated.playerPosition, state.playerPosition);
      expect(updated.playerFacing, state.playerFacing);
      expect(updated.party.members, state.party.members);
      expect(updated.storyFlags, state.storyFlags);
      expect(updated.consumedEventIds, state.consumedEventIds);
      expect(updated.metadata, state.metadata);
    });

    test('handles missing item, blank id and invalid quantity safely', () {
      final state = partyBagState(
        bagEntries: const [
          BagEntry(itemId: 'potion', categoryId: 'medicine', quantity: 1),
        ],
      );

      expect(mutations.consumeItem(state, 'ether', 1), same(state));
      expect(mutations.consumeItem(state, '   ', 1), same(state));
      expect(mutations.consumeItem(state, 'potion', 0), same(state));
      expect(mutations.consumeItem(state, 'potion', -1), same(state));
      expect(mutations.consumeItem(state, 'potion', 2), same(state));
    });
  });

  group('GameStateMutations.applyHpMedicineToPartyMember', () {
    test('heals a party member and consumes the medicine item', () {
      final state = partyBagState(
        members: [pokemon(currentHp: 6)],
        bagEntries: const [
          BagEntry(itemId: 'potion', categoryId: 'medicine', quantity: 2),
        ],
      );

      final updated = mutations.applyHpMedicineToPartyMember(
        state,
        partyIndex: 0,
        itemId: 'potion',
        healAmount: 8,
        maxHp: 20,
      );

      expect(updated.party.members.single.currentHp, 14);
      expect(updated.bag.entries.single.quantity, 1);
      expect(updated.party.members.single.statusId, isEmpty);
    });

    test('caps healing at explicit maxHp', () {
      final state = partyBagState(
        members: [pokemon(currentHp: 17)],
        bagEntries: const [
          BagEntry(itemId: 'potion', categoryId: 'medicine', quantity: 1),
        ],
      );

      final updated = mutations.applyHpMedicineToPartyMember(
        state,
        partyIndex: 0,
        itemId: 'potion',
        healAmount: 20,
        maxHp: 22,
      );

      expect(updated.party.members.single.currentHp, 22);
      expect(updated.bag.entries, isEmpty);
    });

    test('does not consume item on invalid index, missing item or no healing',
        () {
      final state = partyBagState(
        members: [pokemon(currentHp: 20)],
        bagEntries: const [
          BagEntry(itemId: 'potion', categoryId: 'medicine', quantity: 1),
        ],
      );

      expect(
        mutations.applyHpMedicineToPartyMember(
          state,
          partyIndex: 3,
          itemId: 'potion',
          healAmount: 5,
          maxHp: 25,
        ),
        same(state),
      );
      expect(
        mutations.applyHpMedicineToPartyMember(
          state,
          partyIndex: 0,
          itemId: 'ether',
          healAmount: 5,
          maxHp: 25,
        ),
        same(state),
      );
      expect(
        mutations.applyHpMedicineToPartyMember(
          state,
          partyIndex: 0,
          itemId: 'potion',
          healAmount: 5,
          maxHp: 20,
        ),
        same(state),
      );
    });
  });

  group('GameStateMutations.recoverParty', () {
    test('restores multiple party members with explicit max HP caps', () {
      final state = partyBagState(
        members: [
          pokemon(speciesId: 'p5_species_a', currentHp: 3),
          pokemon(speciesId: 'p5_species_b', currentHp: 0, statusId: 'sleep'),
        ],
        bagEntries: const [
          BagEntry(itemId: 'potion', categoryId: 'medicine', quantity: 1),
        ],
      );

      final updated = mutations.recoverParty(
        state,
        maxHpByPartyIndex: const {0: 18, 1: 21},
      );

      expect(updated.party.members[0].currentHp, 18);
      expect(updated.party.members[1].currentHp, 21);
      expect(updated.party.members[0].statusId, isEmpty);
      expect(updated.party.members[1].statusId, isEmpty);
      expect(updated.bag, state.bag);
      expect(updated.currentMapId, state.currentMapId);
      expect(updated.storyFlags, state.storyFlags);
      expect(updated.consumedEventIds, state.consumedEventIds);
    });

    test('skips party members without a valid explicit cap', () {
      final state = partyBagState(
        members: [
          pokemon(speciesId: 'p5_species_a', currentHp: 5),
          pokemon(speciesId: 'p5_species_b', currentHp: 6, statusId: 'burn'),
        ],
      );

      final updated = mutations.recoverParty(
        state,
        maxHpByPartyIndex: const {0: 12, 1: 0},
      );

      expect(updated.party.members[0].currentHp, 12);
      expect(updated.party.members[0].statusId, isEmpty);
      expect(updated.party.members[1].currentHp, 6);
      expect(updated.party.members[1].statusId, 'burn');
    });

    test('round-trips healed party and updated bag through SaveData', () {
      final state = partyBagState(
        members: [pokemon(currentHp: 4, statusId: 'poison')],
        bagEntries: const [
          BagEntry(itemId: 'potion', categoryId: 'medicine', quantity: 2),
        ],
      );

      final healed = mutations.applyHpMedicineToPartyMember(
        state,
        partyIndex: 0,
        itemId: 'potion',
        healAmount: 10,
        maxHp: 16,
      );
      final recovered = mutations.recoverParty(
        healed,
        maxHpByPartyIndex: const {0: 20},
      );
      final saveData = saveDataFromGameState(recovered);
      final reloaded =
          normalizeLoadedGameState(gameStateFromSaveData(saveData));

      expect(reloaded.party.members.single.currentHp, 20);
      expect(reloaded.party.members.single.statusId, isEmpty);
      expect(reloaded.bag.entries.single.itemId, 'potion');
      expect(reloaded.bag.entries.single.quantity, 1);
      expect(reloaded.currentMapId, state.currentMapId);
      expect(reloaded.metadata, state.metadata);
    });

    test('does not hardcode any Selbrume ids', () {
      final state = partyBagState(
        members: [pokemon(speciesId: 'p5_generic_species', currentHp: 1)],
        bagEntries: const [
          BagEntry(
            itemId: 'p5_generic_medicine',
            categoryId: 'medicine',
            quantity: 1,
          ),
        ],
      );

      final updated = mutations.applyHpMedicineToPartyMember(
        state,
        partyIndex: 0,
        itemId: 'p5_generic_medicine',
        healAmount: 2,
        maxHp: 5,
      );

      expect(updated.party.members.single.speciesId, 'p5_generic_species');
      expect(updated.bag.entries, isEmpty);
    });
  });
}
```

### Diff complet des fichiers modifiés

```diff
diff --git a/MVP Selbrume/road_map_phase_5.md b/MVP Selbrume/road_map_phase_5.md
index d4f18965..a9b2ec05 100644
--- a/MVP Selbrume/road_map_phase_5.md	
+++ b/MVP Selbrume/road_map_phase_5.md	
@@ -8,6 +8,7 @@ P5-00 : terminé.
 P5-01 : terminé.
 P5-02 : terminé.
 P5-03 : terminé.
+P5-04 : terminé.
 
 Phase 5 reste orientée vers une boucle RPG minimale prouvable, pas vers une
 parité Pokémon complète, pas vers Selbrume final, pas vers une UI premium.
@@ -15,7 +16,7 @@ parité Pokémon complète, pas vers Selbrume final, pas vers une UI premium.
 Prochain lot exact :
 
 ```text
-P5-04 — Party / Bag / Heal Minimal Operations V0
+P5-05 — Battle Rewards / Money / XP Minimal Apply V0
 ```
 
 ## Objectif Phase 5
@@ -177,7 +178,7 @@ roundtrip save/load ciblé
 
 ### P5-04 — Party / Bag / Heal Minimal Operations V0
 
-Statut : prochain lot exact.
+Statut : terminé.
 
 But :
 
@@ -197,6 +198,8 @@ tests purs
 
 ### P5-05 — Battle Rewards / Money / XP Minimal Apply V0
 
+Statut : prochain lot exact.
+
 But :
 
 ```text
diff --git a/packages/map_gameplay/lib/src/game_state_mutations.dart b/packages/map_gameplay/lib/src/game_state_mutations.dart
index bf7e8d70..d15601fb 100644
--- a/packages/map_gameplay/lib/src/game_state_mutations.dart
+++ b/packages/map_gameplay/lib/src/game_state_mutations.dart
@@ -177,6 +177,139 @@ class GameStateMutations {
     return state.copyWith(bag: updatedBag);
   }
 
+  /// Consomme une quantité d'item depuis le sac.
+  ///
+  /// No-op sûr si l'id est vide, la quantité invalide, l'item absent ou la
+  /// quantité disponible insuffisante.
+  GameState consumeItem(
+    GameState state,
+    String itemId,
+    int quantity,
+  ) {
+    final normalizedItemId = itemId.trim();
+    if (normalizedItemId.isEmpty || quantity <= 0) {
+      return state;
+    }
+
+    final nextEntries = <BagEntry>[];
+    var consumed = false;
+
+    for (final entry in state.bag.normalized().entries) {
+      final isRequestedItem =
+          !consumed && entry.itemId.trim() == normalizedItemId;
+      if (!isRequestedItem) {
+        nextEntries.add(entry);
+        continue;
+      }
+
+      if (entry.quantity < quantity) {
+        return state;
+      }
+
+      consumed = true;
+      final nextQuantity = entry.quantity - quantity;
+      if (nextQuantity > 0) {
+        nextEntries.add(entry.copyWith(quantity: nextQuantity));
+      }
+    }
+
+    if (!consumed) {
+      return state;
+    }
+
+    return state.copyWith(
+      bag: Bag(entries: nextEntries).normalized(),
+    );
+  }
+
+  /// Applique un soin HP hors combat à un membre de party.
+  ///
+  /// Le cap HP est fourni par l'appelant car [PlayerPokemon] ne persiste pas de
+  /// maxHp. Cette mutation ne contient donc aucune table d'items ou de stats.
+  GameState applyHpMedicineToPartyMember(
+    GameState state, {
+    required int partyIndex,
+    required String itemId,
+    required int healAmount,
+    required int maxHp,
+  }) {
+    final normalizedItemId = itemId.trim();
+    if (partyIndex < 0 ||
+        partyIndex >= state.party.members.length ||
+        normalizedItemId.isEmpty ||
+        healAmount <= 0 ||
+        maxHp <= 0) {
+      return state;
+    }
+
+    final target = state.party.members[partyIndex];
+    final currentHp = target.currentHp < 0 ? 0 : target.currentHp;
+    if (currentHp >= maxHp) {
+      return state;
+    }
+
+    final hasItem = state.bag.normalized().entries.any(
+          (entry) =>
+              entry.itemId.trim() == normalizedItemId && entry.quantity > 0,
+        );
+    if (!hasItem) {
+      return state;
+    }
+
+    final consumedState = consumeItem(state, normalizedItemId, 1);
+    final healedHp = currentHp + healAmount;
+    final cappedHp = healedHp > maxHp ? maxHp : healedHp;
+    final nextMembers = [...consumedState.party.members];
+    nextMembers[partyIndex] = nextMembers[partyIndex].copyWith(
+      currentHp: cappedHp,
+    );
+
+    return consumedState.copyWith(
+      party: consumedState.party.copyWith(members: nextMembers),
+    );
+  }
+
+  /// Restaure la party à partir de caps HP explicites par index.
+  ///
+  /// Représente un recovery point minimal sans UI ni Pokemon Center persistant.
+  GameState recoverParty(
+    GameState state, {
+    required Map<int, int> maxHpByPartyIndex,
+    bool clearStatus = true,
+  }) {
+    if (state.party.members.isEmpty || maxHpByPartyIndex.isEmpty) {
+      return state;
+    }
+
+    final nextMembers = <PlayerPokemon>[];
+    var changed = false;
+
+    for (var index = 0; index < state.party.members.length; index++) {
+      final member = state.party.members[index];
+      final maxHp = maxHpByPartyIndex[index];
+      if (maxHp == null || maxHp <= 0) {
+        nextMembers.add(member);
+        continue;
+      }
+
+      final nextStatusId = clearStatus ? '' : member.statusId;
+      final nextMember = member.copyWith(
+        currentHp: maxHp,
+        statusId: nextStatusId,
+      );
+      changed = changed || nextMember != member;
+      nextMembers.add(nextMember);
+    }
+
+    if (!changed) {
+      return state;
+    }
+
+    return state.copyWith(
+      party: state.party.copyWith(members: nextMembers),
+    );
+  }
+
   /// Donne un Pokémon au joueur.
   ///
   /// Le [PlayerPokemon] doit être construit par l'appelant (authoring, script,
```

### Contrôles finaux

```text
git diff --check

<sortie vide>
```

```text
git diff --stat

 MVP Selbrume/road_map_phase_5.md                   |   7 +-
 .../map_gameplay/lib/src/game_state_mutations.dart | 133 +++++++++++++++++++++
 2 files changed, 138 insertions(+), 2 deletions(-)
```

```text
git diff --name-only

MVP Selbrume/road_map_phase_5.md
packages/map_gameplay/lib/src/game_state_mutations.dart
```

```text
git status --short --untracked-files=all

 M "MVP Selbrume/road_map_phase_5.md"
 M packages/map_gameplay/lib/src/game_state_mutations.dart
?? packages/map_gameplay/test/party_bag_heal_operations_test.dart
?? reports/roadmap/phase_5/p5_04_party_bag_heal_minimal_operations.md
```

### Contrôles explicites de non-scope

- `road_map_global.md` n'a pas été modifié.
- P5-05 n'a pas été exécuté.
- Boot Flow complet non créé.
- Selbrume final non créé.
- Aucun reward / money / XP ajouté.
- Aucune capture party-or-box / PC / box ajoutée.
- Aucune UI bag ajoutée dans `examples/playable_runtime_host`.
- Aucune logique bag/heal durable ajoutée dans `examples/playable_runtime_host`.
- Aucun `ItemRegistry` ou `ItemEffectRegistry` créé.

## 18. Auto-review critique

Points forts :

- Le lot n'est pas audit-only : une API pure et testée est ajoutée.
- Les tests couvrent no-op, mutation utile, cap HP, recovery, status clear et
  persistence.
- Aucun modèle persistant n'a été modifié.
- Aucun code `examples/playable_runtime_host` n'a été touché.

Réserves :

- `applyHpMedicineToPartyMember(...)` ne calcule pas `maxHp`; c'est voulu car
  le modèle ne le persiste pas.
- L'opération ne porte pas un diagnostic typé ; le style existant de
  `GameStateMutations` est le no-op sûr.
- La vraie UI runtime bag reste une dette séparée.

## 19. Regard critique sur le prompt

Le prompt force utilement la frontière entre opérations gameplay pures et UI
host d'exemple. C'est important ici : le repo possède déjà une UI bag/party dans
`examples/playable_runtime_host`, mais la bonne réponse P5-04 était de poser les
briques réutilisables dans `map_gameplay`, pas de prolonger cette UI.

Prochain lot exact recommandé :

```text
P5-05 — Battle Rewards / Money / XP Minimal Apply V0
```
