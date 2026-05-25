# P5-03 — Starter / Initial Party Minimal Flow V0

## 1. Résumé exécutif

P5-03 est validable.

Le lot prouve le flux minimal demandé sans créer de nouvelle API :

```text
createNewGameStateFromMap(...)
-> GameStateMutations.givePokemon(...)
-> party initiale non vide
-> saveDataFromGameState(...)
-> gameStateFromSaveData(...)
-> normalizeLoadedGameState(...)
-> starter conservé
```

Décision importante : `GameStateMutations.givePokemon(...)` suffit pour P5-03. Ajouter un wrapper `giveStarterPokemon...` aurait dupliqué une opération pure existante sans gain réel. Le lot ajoute donc un test ciblé, pas de code de production.

## 2. Scope du lot

Inclus :

- audit de `GameStateMutations.givePokemon(...)` ;
- audit de `PlayerPokemon`, `PlayerParty`, `SaveData` et `GameState` ;
- preuve d'un starter minimal depuis un `GameState` P5-02 ;
- preuve speciesId trimé / blank speciesId no-op ;
- preuve level et moves conservés ;
- preuve validation persistence pour level invalide et move id blank ;
- preuve anti-doublon via `preventDuplicateSpecies` ;
- preuve roundtrip `SaveData` ;
- mise à jour roadmap Phase 5 ;
- rapport P5-03.

Exclus :

- écran de choix starter ;
- UI starter ;
- catalogue starter persistant ;
- species registry ;
- Boot Flow complet ;
- écran titre, slots, intro, cinématique ;
- Selbrume final ;
- rewards / money reward apply / XP / level-up ;
- heal center ;
- capture party-or-box / PC / box.

## 3. Sources lues

Fichiers principaux lus :

- `skills/README.md`
- `pokemap_roadmap_mecaniques_fangame.md`
- `MVP Selbrume/road_map_global.md`
- `MVP Selbrume/road_map_phase_5.md`
- `reports/roadmap/phase_5/p5_02_new_game_initial_game_state_builder.md`
- `packages/map_gameplay/lib/src/game_state_mutations.dart`
- `packages/map_gameplay/lib/src/new_game_state_builder.dart`
- `packages/map_gameplay/test/give_pokemon_test.dart`
- `packages/map_gameplay/test/new_game_state_builder_test.dart`
- `packages/map_core/lib/src/models/save_data.dart`
- `packages/map_core/lib/src/models/game_state.dart`

Fichiers / recherches complémentaires :

- `packages/map_gameplay/test/new_game_initial_party_test.dart` créé ;
- `find packages/map_gameplay/test ...` ;
- `find packages/map_core/test ...` ;
- `rg ... givePokemon|PlayerPokemon|starter|initial party ...`.

Lien roadmap mécanique :

- P5-03 touche les gaps FG-010 / FG-012 / FG-013 de la roadmap mécanique.
- Ce lot prouve uniquement l'ajout d'une créature initiale à la party depuis un état New Game. Il ne clôture pas FG-012 / FG-013 au sens complet, car il n'y a pas encore de modèle de sélection starter, UI/runtime flow, flag anti-reprise, ni projet bêta complet.

## 4. État de givePokemon / PlayerPokemon

`GameStateMutations.givePokemon(...)` :

- prend un `GameState` et un `PlayerPokemon` ;
- trim `pokemon.speciesId` ;
- retourne le state inchangé si `speciesId` est vide ou blank ;
- ajoute le Pokémon à `state.party.members` ;
- préserve le reste du `GameState` ;
- peut éviter un doublon species via `preventDuplicateSpecies: true` ;
- ne limite pas la taille de party ;
- ne choisit pas de species par défaut.

`PlayerPokemon` supporte déjà :

- `speciesId` ;
- `natureId` ;
- `abilityId` ;
- `level` ;
- `knownMoveIds` ;
- `currentHp` ;
- `statusId` ;
- `heldItemId`.

`PlayerPokemon.normalized()` valide notamment :

- `speciesId`, `natureId`, `abilityId` non vides ;
- `level` entre 1 et 100 ;
- `currentHp >= 0` ;
- aucun `knownMoveIds` vide ;
- au plus 4 moves.

## 5. API ajoutée ou décision de réutiliser l’existant

Aucune API de production ajoutée.

Décision :

```text
Réutiliser GameStateMutations.givePokemon(...)
```

Justification :

- l'opération pure existe déjà ;
- elle est générique et non liée à un contenu final ;
- elle couvre le besoin minimal : ajouter une créature initiale à la party ;
- un wrapper starter serait prématuré sans starter catalog ni sélection runtime ;
- P5-09 pourra ajouter des diagnostics bêta si un projet a une party/starter incohérent.

## 6. Starter / party initiale

Le test `new_game_initial_party_test.dart` prouve :

- `createNewGameStateFromMap(...)` produit un état initial P5-02 avec party vide ;
- `GameStateMutations.givePokemon(...)` ajoute un starter générique ;
- la party contient exactement la créature attendue ;
- `level`, `knownMoveIds`, `currentHp`, `statusId` et `heldItemId` sont vérifiés ;
- l'état d'origine n'est pas muté.

IDs utilisés :

```text
map: p5_initial_party_map
spawn: p5_initial_party_spawn
save: p5_initial_party_save
species: p5_starter_species
moves: p5_starter_tackle, p5_starter_guard
```

## 7. Validation minimale

P5-03 prouve le comportement réel, sans durcir arbitrairement l'API :

- `speciesId` blank : no-op sûr dans `givePokemon(...)` ;
- `speciesId` avec espaces : trim ;
- doublon species : évité si `preventDuplicateSpecies` est activé ;
- `level` invalide : rejeté par la validation persistence `PlayerPokemon.normalized()` via `saveDataFromGameState(...)` ;
- move id blank : rejeté par la validation persistence.

Limite volontaire :

- `givePokemon(...)` ne devient pas un validator starter complet. La validation projet lançable et les diagnostics auteur appartiennent à P5-09.

## 8. Persistence roundtrip

Preuve retenue :

```text
GameState avec starter
-> saveDataFromGameState(...)
-> gameStateFromSaveData(...)
-> normalizeLoadedGameState(...)
```

Le roundtrip conserve :

- `saveId` ;
- `currentMapId` ;
- `playerPosition` ;
- `playerFacing` ;
- party initiale ;
- `speciesId` ;
- `level` ;
- `knownMoveIds` ;
- bag vide ;
- money à 0.

## 9. Ce qui est prouvé

- Le GameState initial P5-02 peut recevoir une créature initiale.
- La créature initiale est conservée en party.
- `speciesId`, `level`, moves et HP minimal sont testés.
- Les champs New Game de base restent inchangés.
- Le roundtrip persistence conserve la party initiale.
- Les doublons peuvent être évités à la demande.
- Aucun contenu Selbrume n'est injecté.
- Aucune UI ni Boot Flow n'est créé.

## 10. Ce qui n’est pas prouvé

- Pas de sélection starter.
- Pas de catalogue starter.
- Pas de UI starter.
- Pas de dialogue starter.
- Pas de flag anti-reprise de starter.
- Pas de limite party-size dans `map_gameplay`.
- Pas de PC/box.
- Pas de capture destination.
- Pas de starter runtime flow.
- Pas de reward / money reward apply / XP / level-up.

## 11. Limites et reports vers P5-04 / P5-06 / P5-07 / P5-09

- P5-04 doit traiter party/bag/heal minimal hors combat.
- P5-06 doit traiter la destination capture party-or-box et la vraie question party full.
- P5-07 doit élargir le roundtrip gameplay bêta.
- P5-09 doit diagnostiquer les projets avec starter/party manquants ou incohérents.
- FG-012 / FG-013 restent non clôturés au sens roadmap mécanique complète.

## 12. Tests exécutés

Test ciblé P5-03 :

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

Régressions ciblées :

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
cd packages/map_gameplay && dart test test/new_game_state_builder_test.dart

00:00 +0: loading test/new_game_state_builder_test.dart
00:00 +0: createNewGameState creates a GameState with the correct start map id
00:00 +1: createNewGameState trims whitespace from startMapId
00:00 +2: createNewGameState sets the default start position to (0, 0)
00:00 +3: createNewGameState sets a custom start position
00:00 +4: createNewGameState sets the default facing to south
00:00 +5: createNewGameState sets a custom facing
00:00 +6: createNewGameState initializes party as empty
00:00 +7: createNewGameState initializes bag as empty
00:00 +8: createNewGameState initializes storyFlags as empty
00:00 +9: createNewGameState initializes scriptVariables as empty
00:00 +10: createNewGameState initializes completedStepIds as empty
00:00 +11: createNewGameState initializes completedCutsceneIds as empty
00:00 +12: createNewGameState initializes consumedEventIds as empty
00:00 +13: createNewGameState initializes progression seenSpeciesIds as empty
00:00 +14: createNewGameState initializes progression caughtSpeciesIds as empty
00:00 +15: createNewGameState initializes progression storyFlags as empty
00:00 +16: createNewGameState initializes unlockedFieldAbilities as empty
00:00 +17: createNewGameState initializes metadata as empty
00:00 +18: createNewGameState sets playerMovementMode to walk
00:00 +19: createNewGameState does not preload any Pokemon
00:00 +20: createNewGameState sets the default saveId to new_game
00:00 +21: createNewGameState accepts a custom saveId
00:00 +22: createNewGameState falls back to new_game when saveId is blank
00:00 +23: createNewGameState sets the default player name to Player
00:00 +24: createNewGameState accepts a custom player name
00:00 +25: createNewGameState falls back to Player when playerName is blank
00:00 +26: createNewGameState trainerProfile starts with zero money
00:00 +27: createNewGameState trainerProfile starts with zero playtime
00:00 +28: createNewGameState trainerProfile starts with no badges
00:00 +29: createNewGameState throws ArgumentError when startMapId is empty
00:00 +30: createNewGameState throws ArgumentError when startMapId is blank
00:00 +31: createNewGameState round-trips through SaveData correctly
00:00 +32: createNewGameState does not reference any Selbrume-specific ids
00:00 +33: createNewGameStateFromMap resolves defaultSpawnId into start position and facing
00:00 +34: createNewGameStateFromMap falls back to the first playerStart spawn when defaultSpawnId is absent
00:00 +35: createNewGameStateFromMap throws when the map id is blank
00:00 +36: createNewGameStateFromMap throws when no player spawn can be resolved
00:00 +37: createNewGameStateFromMap round-trips the spawn-derived state through SaveData
00:00 +38: createNewGameStateFromMap does not hardcode Selbrume ids when resolving a map spawn
00:00 +39: All tests passed!
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
cd packages/map_gameplay && dart format --set-exit-if-changed test/new_game_initial_party_test.dart

Formatted 1 file (0 changed) in 0.01 seconds.
```

## 13. Modifications effectuées

Fichiers créés :

- `packages/map_gameplay/test/new_game_initial_party_test.dart`
- `reports/roadmap/phase_5/p5_03_starter_initial_party_minimal_flow.md`

Fichiers modifiés :

- `MVP Selbrume/road_map_phase_5.md`

Aucun fichier de production n'a été modifié.

## 14. Evidence Pack

### git status initial exact

```text
git status --short --untracked-files=all

<aucune sortie>
```

### Commandes exécutées

```text
sed -n '1,220p' skills/README.md
sed -n '1,220p' /Users/karim/.codex/plugins/cache/openai-curated/superpowers/6188456f/skills/test-driven-development/SKILL.md
sed -n '1,220p' /Users/karim/.codex/skills/dart-add-unit-test/SKILL.md
git status --short --untracked-files=all
sed -n '1,260p' pokemap_roadmap_mecaniques_fangame.md
sed -n '1,360p' "MVP Selbrume/road_map_global.md"
sed -n '1,940p' "MVP Selbrume/road_map_phase_5.md"
sed -n '1,320p' reports/roadmap/phase_5/p5_02_new_game_initial_game_state_builder.md
sed -n '1,280p' packages/map_gameplay/lib/src/game_state_mutations.dart
sed -n '1,220p' packages/map_gameplay/lib/src/new_game_state_builder.dart
sed -n '1,320p' packages/map_gameplay/test/give_pokemon_test.dart
sed -n '1,420p' packages/map_gameplay/test/new_game_state_builder_test.dart
sed -n '1,360p' packages/map_core/lib/src/models/save_data.dart
sed -n '1,260p' packages/map_core/lib/src/models/game_state.dart
rg -n "givePokemon|PlayerPokemon|PlayerParty|party|speciesId|level|move|moves|currentHp|maxHp|status|heldItem|preventDuplicateSpecies|party full|partyFull|starter|initial party" packages/map_core packages/map_gameplay packages/map_runtime --glob '!build/**' --glob '!**/.dart_tool/**'
find packages/map_gameplay/test -maxdepth 2 -type f | sort | rg "pokemon|party|new_game|game_state|starter"
find packages/map_core/test -maxdepth 2 -type f | sort | rg "game_state|save|pokemon|party"
dart test test/new_game_initial_party_test.dart
dart format --set-exit-if-changed test/new_game_initial_party_test.dart
dart test test/give_pokemon_test.dart
dart test test/new_game_state_builder_test.dart
dart test test/game_state_mutations_test.dart
dart test test/game_state_persistence_test.dart
dart analyze
git diff -- "MVP Selbrume/road_map_phase_5.md"
```

### Sorties utiles

`find packages/map_gameplay/test ...` :

```text
packages/map_gameplay/test/game_state_mutations_test.dart
packages/map_gameplay/test/give_pokemon_test.dart
packages/map_gameplay/test/new_game_state_builder_test.dart
```

`find packages/map_core/test ...` :

```text
packages/map_core/test/game_state_persistence_test.dart
packages/map_core/test/pokemon_move_test.dart
packages/map_core/test/project_manifest_path_pattern_save_reload_test.dart
packages/map_core/test/save_data_test.dart
```

`rg ... starter|initial party ...` a produit une sortie très longue. Signaux utiles :

- `packages/map_gameplay/lib/src/game_state_mutations.dart` contient `givePokemon(...)` ;
- `packages/map_core/lib/src/models/save_data.dart` contient `PlayerPokemon`, `PlayerParty`, `knownMoveIds`, `level`, `currentHp`, `statusId`, `heldItemId` ;
- `packages/map_runtime/lib/src/application/runtime_battle_setup_mapper.dart` et des tests runtime connaissent déjà des cas party full/capture, mais cette logique est hors scope P5-03 ;
- la roadmap mécanique garde FG-012 / FG-013 à traiter pour la sélection/runtime starter complète.

### Contenu complet du nouveau fichier de test

```dart
import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:test/test.dart';

void main() {
  const mutations = GameStateMutations();

  MapData startMap() {
    return const MapData(
      id: 'p5_initial_party_map',
      name: 'P5 Initial Party Field',
      size: GridSize(width: 10, height: 8),
      mapMetadata: MapMetadata(defaultSpawnId: 'p5_initial_party_spawn'),
      entities: [
        MapEntity(
          id: 'p5_initial_party_spawn',
          kind: MapEntityKind.spawn,
          pos: GridPos(x: 4, y: 5),
          spawn: MapEntitySpawnData(
            spawnKey: 'p5_initial_party_spawn',
            role: EntitySpawnRole.playerStart,
            facing: EntityFacing.north,
          ),
        ),
      ],
    );
  }

  GameState initialState() {
    return createNewGameStateFromMap(
      startMap: startMap(),
      saveId: 'p5_initial_party_save',
      playerName: 'P5 Player',
    );
  }

  PlayerPokemon starterPokemon({
    String speciesId = 'p5_starter_species',
    int level = 5,
    List<String> knownMoveIds = const [
      'p5_starter_tackle',
      'p5_starter_guard',
    ],
  }) {
    return PlayerPokemon(
      speciesId: speciesId,
      natureId: 'hardy',
      abilityId: 'p5_starter_ability',
      level: level,
      knownMoveIds: knownMoveIds,
      currentHp: 18,
    );
  }

  group('P5-03 initial party flow', () {
    test('creates a starter party from a P5-02 New Game state', () {
      final state = initialState();
      final result = mutations.givePokemon(
        state,
        pokemon: starterPokemon(),
      );

      expect(state.party.members, isEmpty);
      expect(result.party.members, hasLength(1));

      final starter = result.party.members.single;
      expect(starter.speciesId, 'p5_starter_species');
      expect(starter.level, 5);
      expect(
        starter.knownMoveIds,
        ['p5_starter_tackle', 'p5_starter_guard'],
      );
      expect(starter.currentHp, 18);
      expect(starter.statusId, isEmpty);
      expect(starter.heldItemId, isEmpty);
    });

    test('trims starter speciesId through givePokemon', () {
      final result = mutations.givePokemon(
        initialState(),
        pokemon: starterPokemon(speciesId: '  p5_starter_species  '),
      );

      expect(result.party.members.single.speciesId, 'p5_starter_species');
    });

    test('keeps blank starter speciesId as a safe no-op', () {
      final state = initialState();
      final result = mutations.givePokemon(
        state,
        pokemon: starterPokemon(speciesId: '   '),
      );

      expect(identical(result, state), isTrue);
      expect(result.party.members, isEmpty);
    });

    test('preserves New Game map, spawn, bag, money, and progression', () {
      final state = initialState();
      final result = mutations.givePokemon(
        state,
        pokemon: starterPokemon(),
      );

      expect(result.currentMapId, 'p5_initial_party_map');
      expect(result.playerPosition, const GridPos(x: 4, y: 5));
      expect(result.playerFacing, EntityFacing.north);
      expect(result.bag.entries, isEmpty);
      expect(result.trainerProfile.money, 0);
      expect(result.progression.completedStepIds, isEmpty);
      expect(result.progression.completedCutsceneIds, isEmpty);
      expect(result.progression.unlockedFieldAbilities, isEmpty);
      expect(result.storyFlags.activeFlags, isEmpty);
      expect(result.consumedEventIds, isEmpty);
      expect(result.metadata, isEmpty);
    });

    test('round-trips the initial party through SaveData', () {
      final stateWithStarter = mutations.givePokemon(
        initialState(),
        pokemon: starterPokemon(level: 7),
      );

      final saveData = saveDataFromGameState(stateWithStarter);
      final reloaded =
          normalizeLoadedGameState(gameStateFromSaveData(saveData));

      expect(reloaded.saveId, 'p5_initial_party_save');
      expect(reloaded.currentMapId, 'p5_initial_party_map');
      expect(reloaded.playerPosition, const GridPos(x: 4, y: 5));
      expect(reloaded.playerFacing, EntityFacing.north);
      expect(reloaded.party.members, hasLength(1));

      final starter = reloaded.party.members.single;
      expect(starter.speciesId, 'p5_starter_species');
      expect(starter.level, 7);
      expect(
        starter.knownMoveIds,
        ['p5_starter_tackle', 'p5_starter_guard'],
      );
      expect(reloaded.bag.entries, isEmpty);
      expect(reloaded.trainerProfile.money, 0);
    });

    test('prevents duplicate starter species when requested', () {
      var state = initialState();
      state = mutations.givePokemon(
        state,
        pokemon: starterPokemon(level: 5),
      );
      final result = mutations.givePokemon(
        state,
        pokemon: starterPokemon(level: 10),
        preventDuplicateSpecies: true,
      );

      expect(result.party.members, hasLength(1));
      expect(result.party.members.single.level, 5);
    });

    test('persistence validation rejects invalid starter level', () {
      final stateWithInvalidStarter = mutations.givePokemon(
        initialState(),
        pokemon: starterPokemon(level: 0),
      );

      expect(
        () => saveDataFromGameState(stateWithInvalidStarter),
        throwsStateError,
      );
    });

    test('persistence validation rejects blank starter move ids', () {
      final stateWithInvalidStarter = mutations.givePokemon(
        initialState(),
        pokemon: starterPokemon(knownMoveIds: const ['p5_valid_move', '  ']),
      );

      expect(
        () => saveDataFromGameState(stateWithInvalidStarter),
        throwsStateError,
      );
    });

    test('does not hardcode Selbrume-specific ids', () {
      final result = mutations.givePokemon(
        initialState(),
        pokemon: starterPokemon(),
      );

      final joined = [
        result.currentMapId,
        result.party.members.single.speciesId,
        ...result.party.members.single.knownMoveIds,
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
index 878727d8..d4f18965 100644
--- a/MVP Selbrume/road_map_phase_5.md	
+++ b/MVP Selbrume/road_map_phase_5.md	
@@ -7,6 +7,7 @@ Phase 5 active.
 P5-00 : terminé.
 P5-01 : terminé.
 P5-02 : terminé.
+P5-03 : terminé.
 
 Phase 5 reste orientée vers une boucle RPG minimale prouvable, pas vers une
 parité Pokémon complète, pas vers Selbrume final, pas vers une UI premium.
@@ -14,7 +15,7 @@ parité Pokémon complète, pas vers Selbrume final, pas vers une UI premium.
 Prochain lot exact :
 
 ```text
-P5-03 — Starter / Initial Party Minimal Flow V0
+P5-04 — Party / Bag / Heal Minimal Operations V0
 ```
 
 ## Objectif Phase 5
@@ -158,7 +159,7 @@ aucun Boot Flow complet
 
 ### P5-03 — Starter / Initial Party Minimal Flow V0
 
-Statut : prochain lot exact.
+Statut : terminé.
 
 But :
 
@@ -176,6 +177,8 @@ roundtrip save/load ciblé
 
 ### P5-04 — Party / Bag / Heal Minimal Operations V0
 
+Statut : prochain lot exact.
+
 But :
 
 ```text
```

### Contrôles hors scope

- `road_map_global.md` n'a pas été modifié.
- P5-04 n'a pas été exécuté.
- Aucun Boot Flow complet n'a été créé.
- Aucune UI starter n'a été créée.
- Aucun écran titre / slot / intro / cinématique n'a été créé.
- Aucun starter catalog persistant n'a été créé.
- Aucun Selbrume final n'a été créé.
- Aucun reward / money reward apply / XP / level-up n'a été ajouté.
- Aucun heal center n'a été ajouté.
- Aucune capture party-or-box / PC / box n'a été ajoutée.
- Aucun fichier de production n'a été modifié.

### Sorties finales

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
?? packages/map_gameplay/test/new_game_initial_party_test.dart
?? reports/roadmap/phase_5/p5_03_starter_initial_party_minimal_flow.md
```

## 15. Auto-review critique

Le lot est volontairement minimal : il prouve une party initiale via une opération existante au lieu de créer un starter system prématuré.

Le point à surveiller : `givePokemon(...)` ne limite pas la taille de party et ne normalise pas immédiatement tout `PlayerPokemon`. C'est acceptable ici parce que P5-03 reste le flux initial minimal ; les contraintes de taille, PC/box et validation projet appartiennent à P5-06 / P5-09.

## 16. Regard critique sur le prompt

Le prompt pousse dans la bonne direction : il exige une preuve concrète tout en empêchant le glissement vers l'UI starter ou le Boot Flow. Le meilleur résultat ici était de résister à l'envie de créer une API dédiée et de prouver que l'opération existante suffit.

Verdict :

```text
P5-03 : validable.
Prochain lot exact : P5-04 — Party / Bag / Heal Minimal Operations V0.
```
