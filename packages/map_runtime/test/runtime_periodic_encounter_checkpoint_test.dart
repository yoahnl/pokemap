import 'package:flutter_test/flutter_test.dart';
import 'package:map_battle/map_battle.dart';
import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:map_story/map_story.dart';
import 'package:map_runtime/src/application/runtime_periodic_encounter_checkpoint.dart';

void main() {
  final definition = PeriodicEncounterDefinition(
    rewardId: 'weekly',
    label: 'Weekly',
    consumeOnOutcomes: {PeriodicEncounterOutcome.victory},
  );
  const initial = GameState(saveId: 'save', metadata: {'before': 'kept'});
  final outcome = BattleOutcome(
    type: BattleOutcomeType.victory,
    finalState: createBattleSession(
      const BattleSetup.pokeMapBetaV1ForTest(
        playerPokemon: BattleCombatantData(
          speciesId: 'hero',
          level: 5,
          maxHp: 20,
          stats: BattleStatsSnapshot(
            attack: 10,
            defense: 10,
            specialAttack: 10,
            specialDefense: 10,
            speed: 10,
          ),
          moves: [BattleMoveData(id: 'tackle', name: 'Tackle', power: 40)],
        ),
        enemyPokemon: BattleCombatantData(
          speciesId: 'foe',
          level: 2,
          maxHp: 10,
          stats: BattleStatsSnapshot(
            attack: 10,
            defense: 10,
            specialAttack: 10,
            specialDefense: 10,
            speed: 10,
          ),
          moves: [BattleMoveData(id: 'tackle', name: 'Tackle', power: 40)],
        ),
        isTrainerBattle: false,
        trainerId: null,
      ),
    ).state,
  );

  for (final stale in [false, true]) {
    test(
      'full battle checkpoint ${stale ? 'rejects a stale final result' : 'preserves a later Scene change'}',
      () async {
        final transactions = NarrativeEventStateTransactions(initial);
        var working = initial;
        GameState? persisted;
        final result = transactions.transact<void>((_) async {
          final owner = transactions.captureCheckpointOwner()!;
          final occurrence = beginPeriodicEncounter(
            initial,
            definition: definition,
            localDay: '2026-11-06',
          );
          working = await checkpointRuntimePeriodicEncounter(
            owner: owner,
            occurrence: occurrence,
            finalState: initial.copyWith(
              completedBattleRequestIds: {'battle'},
              party: const PlayerParty(
                members: [
                  PlayerPokemon(
                    individualId: 'captured',
                    speciesId: 'foe',
                    natureId: 'hardy',
                    abilityId: 'run-away',
                  ),
                ],
              ),
              bag: const Bag(entries: [BagEntry(itemId: 'ball', quantity: 2)]),
            ),
            outcome: outcome,
            readFinalSceneState: () => working,
            persist: (state) async => persisted = state,
          );
          working = working.copyWith(
            trainerProfile: working.trainerProfile.copyWith(money: 5),
          );
          return NarrativeEventStateTransaction.commit(
            stale ? initial.copyWith(metadata: {'later': 'stale'}) : working,
            null,
          );
        });
        if (stale) {
          await expectLater(result, throwsStateError);
          expect(await transactions.read(), persisted);
          expect(
            (await transactions.read()).party.members.single.individualId,
            'captured',
          );
        } else {
          await result;
          expect((await transactions.read()).trainerProfile.money, 5);
          expect((await transactions.read()).party, persisted!.party);
        }
        expect(persisted!.metadata, initial.metadata);
        expect(persisted!.periodicRewardState.claimFor('weekly')!.revision, 1);
        expect(persisted!.completedBattleRequestIds, {'battle'});
        expect(persisted!.bag.entries.single.quantity, 2);
      },
    );
  }
}
