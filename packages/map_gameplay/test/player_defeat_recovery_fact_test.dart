import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:test/test.dart';

void main() {
  final fact = NarrativeFactDefinition(
      id: 'recovered',
      label: 'Retour après défaite',
      legacyFlagName: 'source:switch:1');
  const config = ProjectDefeatRecoveryConfig(recoveredFactId: 'recovered');
  const state = GameState(
      saveId: 'defeat-signal',
      currentMapId: 'gym',
      playerPosition: GridPos(x: 2, y: 3),
      trainerProfile: TrainerProfile(name: 'Leaf', money: 1000),
      party: PlayerParty(members: [
        PlayerPokemon(
            individualId: 'original-member',
            speciesId: 'bulbasaur',
            natureId: 'hardy',
            abilityId: 'overgrow',
            currentHp: 0,
            level: 5)
      ]));
  const point = PlayerRecoveryPoint(
      mapId: 'home', position: GridPos(x: 9, y: 7), facing: EntityFacing.north);
  NarrativeFactRuntimeResolved resolve(GameState value) =>
      NarrativeFactRuntimeResolver.fromFacts([fact]).resolve(
          factId: fact.id,
          runtimeState: value.narrativeFactRuntimeState,
          storyFlags: value.storyFlags) as NarrativeFactRuntimeResolved;
  test(
      'full native recovery atomically marks the boolean Fact and preserves native loss rules',
      () {
    final result = applyPlayerDefeatRecovery(
        state: state,
        fallbackPoint: point,
        maxHpByPartyIndex: const {0: 25},
        recoveryConfig: config,
        facts: [fact]);
    expect(resolve(result.state).value, isTrue);
    expect(resolve(state).value, isFalse);
    expect(result.state.currentMapId, 'home');
    expect(result.state.playerPosition, point.position);
    expect(result.state.trainerProfile.money, 900);
    expect(result.moneyLost, 100);
    expect(result.state.party.members.single.individualId, 'original-member');
    expect(result.state.party.members.single.currentHp, 25);
    expect(result.state.metadata[playerDefeatCountMetadataKey], '1');
    final restored = gameStateFromSaveData(
        SaveData.fromJson(saveDataFromGameState(result.state).toJson()));
    expect(resolve(restored).value, isTrue);
    expect(restored.party, result.state.party);
    expect(PlayerRecoveryPoint.tryRead(restored),
        PlayerRecoveryPoint.tryRead(result.state));
  });
  test(
      'absent hook leaves Facts unchanged and healing does not count as a defeat',
      () {
    final result = applyPlayerDefeatRecovery(
        state: state, fallbackPoint: point, maxHpByPartyIndex: const {0: 25});
    expect(resolve(result.state).value, isFalse);
    expect(
        resolve(const GameStateMutations()
            .recoverParty(state, maxHpByPartyIndex: const {0: 25})).value,
        isFalse);
  });
  test(
      'missing, ambiguous or incorrectly typed hook rejects without partial healing or flag mutation',
      () {
    for (final facts in <List<NarrativeFactDefinition>>[
      [],
      [fact, fact],
      [
        NarrativeFactDefinition(
            id: 'recovered',
            label: 'Text',
            initialValue: NarrativeValue.string(''))
      ]
    ]) {
      expect(
          () => applyPlayerDefeatRecovery(
              state: state,
              fallbackPoint: point,
              maxHpByPartyIndex: const {0: 25},
              recoveryConfig: config,
              facts: facts),
          throwsA(isA<ValidationException>()));
      expect(state.party.members.single.currentHp, 0);
      expect(state.trainerProfile.money, 1000);
      expect(resolve(state).value, isFalse);
    }
  });
  test(
      'failed recovery and later caller rollback cannot publish the recovery Fact',
      () {
    expect(
        () => applyPlayerDefeatRecovery(
            state: state,
            fallbackPoint: point,
            maxHpByPartyIndex: const {},
            recoveryConfig: config,
            facts: [fact]),
        throwsStateError);
    final candidate = applyPlayerDefeatRecovery(
        state: state,
        fallbackPoint: point,
        maxHpByPartyIndex: const {0: 25},
        recoveryConfig: config,
        facts: [fact]);
    expect(resolve(candidate.state).value, isTrue);
    final rollback = gameStateFromSaveData(saveDataFromGameState(state));
    expect(resolve(rollback).value, isFalse);
    expect(rollback.metadata[playerDefeatCountMetadataKey], isNull);
  });
}
