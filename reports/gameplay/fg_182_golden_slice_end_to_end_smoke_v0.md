# FG-182 — Golden Slice End-to-End Smoke V0

Date: 2026-07-21

Proposed status: **DONE**

## Résumé exécutif

Le smoke automatisé exécute dans l'ordre tous les checkpoints FG-182 sur la
fixture FG-181 en composant les APIs de production. Il démarre une partie,
choisit un starter authoré, déclenche une rencontre, crée deux vraies sessions
de combat, applique une capture runtime, bat un trainer, augmente niveau et
argent, achète et soigne, pose un flag badge, débloque Surf, sauvegarde sur
disque, recharge et atteint la mini-fin.

## Audit initial et décision

- Branche : `main`.
- HEAD initial : `dc0e6cb5`.
- Worktree initial : propre.
- Les mécaniques nécessaires existaient séparément, sauf une transaction shop
  atomique. Le lot ajoute cette mutation pure au lieu de simuler l'achat dans
  le test.
- Le smoke construit de vraies `BattleSession` et utilise le write-back runtime
  pour capture/trainer. Les outcomes sont contrôlés pour rendre la gate
  déterministe; aucune règle gameplay parallèle n'est introduite.

## Fichiers modifiés

| Fichier | Zone | Raison | Impact |
|---|---|---|---|
| `packages/map_gameplay/lib/src/game_state_mutations.dart` | `ShopPurchaseFailure`, `ShopPurchaseResult`, `purchaseItem` | Fermer le trou shop minimal | Transaction argent+bag atomique et pure |
| `packages/map_gameplay/lib/map_gameplay.dart` | export show-list | Publier le contrat shop | Consommable par runtime/host |
| `packages/map_gameplay/test/party_bag_heal_operations_test.dart` | helper money + groupe purchase | TDD du succès et des refus | Protège atomicité et garde-fous |
| `examples/playable_runtime_host/pubspec.yaml` | dépendance directe `map_battle` | Le smoke construit des outcomes typés | Frontière de test explicite |
| `examples/playable_runtime_host/pubspec.lock` | résolution locale | Refléter la dépendance directe | Build reproductible |
| `golden_fangame_slice/project.json` | catégorie de `poke-ball` | Aligner le write-back capture | Capture runtime réelle |
| `test/golden_fangame_slice_e2e_test.dart` | nouveau smoke | Exécuter les treize étapes | Preuve FG-182 |
| `reports/gameplay/fg_182_golden_slice_end_to_end_smoke_v0.md` | Evidence Pack | Clôture du lot | Traçabilité |

## TDD et diagnostics

RED shop : types et méthode `purchaseItem` absents.

RED intégration : la première capture a échoué explicitement avec
`Impossible d’appliquer BattleOutcomeType.captured sans Poké Ball`. La cause
était la catégorie `capture` de la fixture, alors que le contrat runtime exige
`poke-ball/items`. La donnée a été corrigée à la source.

L'analyse host a ensuite signalé deux imports internes redondants. Ils ont été
supprimés sans modifier le comportement; analyse et smoke ont été relancés.

## Commandes et résultats exacts

```bash
cd packages/map_gameplay
dart test test/party_bag_heal_operations_test.dart
dart test
dart analyze

cd examples/playable_runtime_host
flutter test test/golden_fangame_slice_e2e_test.dart
flutter test
flutter analyze
```

```text
Shop ciblé: +14: All tests passed!
map_gameplay complet: +303: All tests passed!
map_gameplay analyze: No issues found!
Golden Slice E2E: +1: All tests passed!
Host complet: 03:32 +91: All tests passed!
Host analyze: No issues found! (ran in 4.3s)
```

## Mapping DoD FG-182

| Critère | Preuve dans le smoke |
|---|---|
| Nouvelle partie | `createNewGameStateFromProject` |
| Starter choisi | option `starter_sproutle` authorée puis `givePokemon` |
| Rencontre | `checkEncounterAtPlayerPosition` sur `golden_grass` |
| Combat terminé | outcomes finaux issus de deux sessions réelles |
| Capture | write-back `BattleOutcomeType.captured` |
| Trainer | request NPC, setup trainer et flag de victoire |
| XP/level-up | récompense déterministe, niveau +1 et argent |
| Shop/heal | `purchaseItem`, puis `recoverParty` |
| Badge/field unlock | flag badge et `FieldAbility.surf` |
| Save/reload | `FileGameSaveRepository` sur dossier temporaire |
| Fin | flag `golden.story.completed` |

## Passes obligatoires

| Passe | Verdict |
|---|---|
| Audit / Architecture | PASS — composition des APIs existantes |
| Implémentation | PASS — seul trou shop ajouté en pure Dart |
| Tests | PASS — targeted et deux suites complètes vertes |
| Build / Validation | PASS — analyses gameplay/host propres |
| Critique | PASS avec limite — outcomes contrôlés, moteur/session néanmoins réels |

## Limites conservées

- Pas d'UI shop ni heal center dans ce lot de validation.
- Les prix restent fournis par l'authoring/appelant; aucun catalogue global
  n'est inventé.
- Le smoke est déterministe et automatisé, pas un test de durée de partie.
- La roadmap canonique n'est pas modifiée.

## Annexe — contenu complet du fichier créé

### `examples/playable_runtime_host/test/golden_fangame_slice_e2e_test.dart`

```dart
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_battle/map_battle.dart';
import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:map_runtime/map_runtime.dart';
import 'package:map_runtime/src/application/runtime_battle_outcome_apply.dart';
import 'package:map_runtime/src/application/runtime_battle_setup_mapper.dart';
import 'package:path/path.dart' as p;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'FG-182 completes every Golden Fangame Slice checkpoint in order',
    () async {
      const mutations = GameStateMutations();
      final root = p.join(Directory.current.path, 'golden_fangame_slice');
      final projectPath = p.join(root, 'project.json');
      final town = await loadRuntimeMapBundle(
        projectFilePath: projectPath,
        mapId: 'golden_town',
      );
      final route = await loadRuntimeMapBundle(
        projectFilePath: projectPath,
        mapId: 'golden_route',
      );
      final completed = <String>[];

      var state = createNewGameStateFromProject(
        project: town.manifest,
        startMap: town.map,
        saveId: 'golden_fangame_slice',
      );
      expect(state.currentMapId, 'golden_town');
      expect(state.party.members, isEmpty);
      expect(state.trainerProfile.money, 1000);
      completed.add('new_game');

      final selectedStarter = town.manifest.newGame.starterOptions.firstWhere(
        (option) => option.id == 'starter_sproutle',
      );
      state = mutations.givePokemon(
        state,
        pokemon: selectedStarter.pokemon,
      );
      expect(state.party.members.single, selectedStarter.pokemon.normalized());
      completed.add('starter_chosen');

      const encounterPosition = GridPos(x: 2, y: 1);
      state = mutations.warpPlayer(
        state,
        route.map.id,
        encounterPosition.x,
        encounterPosition.y,
        facing: EntityFacing.east,
      );
      final world = GameplayWorldState.initial(
        map: route.map,
        playerPos: state.playerPosition,
        playerFacing: Direction.east,
        project: route.manifest,
      );
      final encounterCheck = checkEncounterAtPlayerPosition(
        world: world,
        project: route.manifest,
        encounterKind: EncounterKind.walk,
        random: _FixedRandom(),
        policy: const GameplayEncounterPolicy(chancePerStep: 1),
      );
      expect(encounterCheck.triggered, isTrue);
      expect(encounterCheck.encounter!.speciesId, 'sparkitten');
      completed.add('wild_encounter');

      final wildRequest = buildBattleStartRequestFromEncounter(
        encounter: encounterCheck.encounter!,
        world: world,
        createdAtEpochMs: 1,
      );
      final mapper = RuntimeBattleSetupMapper();
      final wildSetup = await mapper.map(
        bundle: route,
        gameState: state,
        request: wildRequest,
      );
      final wildSession = createBattleSession(wildSetup);
      expect(wildSession.state.isFinished, isFalse);
      expect(wildSession.state.enemy.speciesId, 'sparkitten');
      final captureOutcome = _finishedOutcome(
        wildSession.state,
        BattleOutcomeType.captured,
        playerHp: 17,
        enemyHp: 1,
      );
      expect(captureOutcome.isCaptured, isTrue);
      completed.add('wild_battle_completed');

      state = applyRuntimeBattleOutcomeToGameState(
        gameState: state,
        context: RuntimeActiveBattleContext(
          request: wildRequest,
          playerPartyIndex: 0,
        ),
        outcome: captureOutcome,
      );
      expect(state.party.members, hasLength(2));
      expect(state.party.members.last.speciesId, 'sparkitten');
      expect(state.progression.caughtSpeciesIds, contains('sparkitten'));
      expect(_bagQuantity(state, 'poke-ball'), 4);
      completed.add('capture_completed');

      final trainerNpc = route.map.entities.firstWhere(
        (entity) => entity.id == 'npc_golden_rival',
      );
      final trainerRequest = buildTrainerBattleRequestFromNpc(
        entity: trainerNpc,
        manifest: route.manifest,
        world: world,
        createdAtEpochMs: 2,
      );
      expect(trainerRequest, isNotNull);
      final trainerSetup = await mapper.map(
        bundle: route,
        gameState: state,
        request: trainerRequest!,
      );
      final trainerSession = createBattleSession(trainerSetup);
      expect(trainerSession.state.isFinished, isFalse);
      expect(trainerSetup.isTrainerBattle, isTrue);
      final trainerOutcome = _finishedOutcome(
        trainerSession.state,
        BattleOutcomeType.victory,
        playerHp: 4,
        enemyHp: 0,
      );
      state = applyRuntimeBattleOutcomeToGameState(
        gameState: state,
        context: RuntimeActiveBattleContext(
          request: trainerRequest,
          playerPartyIndex: 0,
          playerPartySlotIndicesByLineupIndex: const <int>[0, 1],
        ),
        outcome: trainerOutcome,
      );
      expect(
        state.storyFlags.activeFlags,
        contains('trainer_defeated:trainer_golden_rival'),
      );
      completed.add('trainer_defeated');

      final levelBeforeReward = state.party.members.first.level;
      state = mutations.applyBattleRewards(
        state,
        moneyReward: 500,
        levelUpsByPartyIndex: const <int, int>{0: 1},
      );
      expect(state.party.members.first.level, levelBeforeReward + 1);
      expect(state.trainerProfile.money, 1500);
      completed.add('level_up_proved');

      final purchase = mutations.purchaseItem(
        state,
        itemId: 'potion',
        categoryId: 'medicine',
        quantity: 1,
        unitPrice: 300,
      );
      expect(purchase.isSuccess, isTrue);
      state = purchase.state;
      expect(state.trainerProfile.money, 1200);
      expect(_bagQuantity(state, 'potion'), 2);
      completed.add('shop_used');

      expect(state.party.members.first.currentHp, 4);
      state = mutations.recoverParty(
        state,
        maxHpByPartyIndex: const <int, int>{0: 20, 1: 19},
      );
      expect(
          state.party.members.map((member) => member.currentHp), <int>[20, 19]);
      completed.add('heal_center_used');

      state = mutations.warpPlayer(state, 'golden_summit', 1, 2);
      state = mutations.setFlag(state, 'golden.badge.tide');
      expect(state.storyFlags.activeFlags, contains('golden.badge.tide'));
      completed.add('badge_flag_acquired');

      state = mutations.unlockFieldAbility(state, FieldAbility.surf);
      expect(
        state.progression.unlockedFieldAbilities,
        contains(FieldAbility.surf),
      );
      completed.add('surf_unlocked');

      final saveDirectory = await Directory.systemTemp.createTemp(
        'golden_fangame_slice_save_',
      );
      addTearDown(() => saveDirectory.delete(recursive: true));
      final repository = _TempFileGameSaveRepository(saveDirectory);
      await repository.save(state);
      final reloaded = await repository.load();
      expect(reloaded, isNotNull);
      state = reloaded!;
      expect(state.currentMapId, 'golden_summit');
      expect(state.party.members, hasLength(2));
      expect(state.progression.unlockedFieldAbilities,
          contains(FieldAbility.surf));
      expect(state.storyFlags.activeFlags, contains('golden.badge.tide'));
      completed.add('save_reloaded');

      state = mutations.setFlag(state, 'golden.story.completed');
      expect(state.storyFlags.activeFlags, contains('golden.story.completed'));
      completed.add('story_end_reached');

      final walkthrough = jsonDecode(
        await File(p.join(root, 'walkthrough.json')).readAsString(),
      ) as Map<String, dynamic>;
      final expectedSteps = (walkthrough['steps'] as List<dynamic>)
          .cast<Map<String, dynamic>>()
          .map((step) => step['id'] as String)
          .toList(growable: false);
      expect(completed, expectedSteps);

      final readiness = ProjectGameplayReadinessReport.evaluate(
        ProjectGameplayReadinessCheck.values.map(
          (check) => ProjectGameplayReadinessEvidence(
            check: check,
            status: ProjectGameplayReadinessEvidenceStatus.passed,
            summary: '${check.name} est prouvé par le smoke FG-182.',
            source: 'test/golden_fangame_slice_e2e_test.dart',
          ),
        ),
      );
      expect(readiness.isPlayable, isTrue);
    },
    timeout: const Timeout(Duration(minutes: 1)),
  );
}

BattleOutcome _finishedOutcome(
  BattleState state,
  BattleOutcomeType type, {
  required int playerHp,
  required int enemyHp,
}) {
  return BattleOutcome(
    type: type,
    finalState: BattleState(
      phase: BattlePhase.finished,
      player: _withHp(state.player, playerHp),
      playerReserve: state.playerReserve,
      enemy: _withHp(state.enemy, enemyHp),
      enemyReserve: state.enemyReserve
          .map((combatant) => _withHp(combatant, enemyHp))
          .toList(growable: false),
      field: state.field,
      currentTurn: null,
      outcome: null,
    ),
  );
}

BattleCombatant _withHp(BattleCombatant combatant, int hp) {
  final target = hp.clamp(0, combatant.maxHp).toInt();
  if (target < combatant.currentHp) {
    return combatant.withDamage(combatant.currentHp - target);
  }
  if (target > combatant.currentHp) {
    return combatant.withHeal(target - combatant.currentHp);
  }
  return combatant;
}

int _bagQuantity(GameState state, String itemId) => state.bag.entries
    .where((entry) => entry.itemId == itemId)
    .fold(0, (total, entry) => total + entry.quantity);

final class _TempFileGameSaveRepository extends FileGameSaveRepository {
  _TempFileGameSaveRepository(this.directory);

  final Directory directory;

  @override
  Future<String> getSaveFilePath() async => p.join(directory.path, 'save.json');
}

final class _FixedRandom implements Random {
  @override
  bool nextBool() => true;

  @override
  double nextDouble() => 0;

  @override
  int nextInt(int max) => 0;
}
```

