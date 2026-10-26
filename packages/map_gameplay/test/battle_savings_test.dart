import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:test/test.dart';

void main() {
  final facts = [
    NarrativeFactDefinition(
        id: 'enabled', label: 'Enabled', defaultValue: true),
    NarrativeFactDefinition(
        id: 'balance',
        label: 'Savings',
        initialValue: NarrativeValue.integer(0)),
  ];
  const policy = ProjectBattleSavingsConfig(
      enabledFactId: 'enabled',
      balanceFactId: 'balance',
      percentage: 25,
      maximumBalance: 999999);
  GameState apply(GameState state, int money,
          {ProjectBattleSavingsConfig? config = policy}) =>
      const GameStateMutations().applyBattleRewards(
        state,
        reward: BattleReward(
            sourceKind: BattleRewardSourceKind.trainer,
            trainerId: 'trainer',
            money: money),
        battleSavings: config,
        facts: facts,
      );
  int balance(GameState state) =>
      state.narrativeFactRuntimeState.valueFor('balance')?.intValue ?? 0;
  test('reserves floor percentage and conserves positive battle money', () {
    final state = apply(
        const GameState(
            saveId: 'save',
            trainerProfile: TrainerProfile(name: 'Player', money: 3000)),
        403);
    expect(state.trainerProfile.money, 3303);
    expect(balance(state), 100);
    final restored =
        gameStateFromStrictSaveJson(strictGameStateSaveJson(state));
    expect(balance(restored), 100);
    final next = apply(restored, 400);
    expect(next.trainerProfile.money, 3603);
    expect(balance(next), 200);
  });
  test('savings cap deducts only actual deposit', () {
    final state = apply(
        GameState(
            saveId: 'save',
            narrativeFactRuntimeState: NarrativeFactRuntimeState.typed(
                valuesByFactId: {'balance': NarrativeValue.integer(999990)})),
        400);
    expect(balance(state), 999999);
    expect(state.trainerProfile.money, 391);
    final full = apply(state, 400);
    expect(balance(full), 999999);
    expect(full.trainerProfile.money, 791);
  });
  test('lowering the configured cap preserves existing saved savings', () {
    final state = GameState(
        saveId: 'save',
        narrativeFactRuntimeState: NarrativeFactRuntimeState.typed(
            valuesByFactId: {'balance': NarrativeValue.integer(1000000)}));
    final result = apply(state, 400);
    expect(balance(result), 1000000);
    expect(result.trainerProfile.money, 400);
  });
  test('missing policy, disabled savings and zero gains preserve old rewards',
      () {
    final state = const GameState(saveId: 'save');
    expect(apply(state, 400, config: null).trainerProfile.money, 400);
    final disabled = state.copyWith(
        narrativeFactRuntimeState:
            NarrativeFactRuntimeState(overridesByFactId: {'enabled': false}));
    final result = apply(disabled, 400);
    expect(result.trainerProfile.money, 400);
    expect(balance(result), 0);
    expect(balance(apply(state, 0)), 0);
  });
  test('invalid persisted balance cannot silently lose existing savings', () {
    final state = GameState(
        saveId: 'save',
        narrativeFactRuntimeState: NarrativeFactRuntimeState.typed(
            valuesByFactId: {'balance': NarrativeValue.integer(-1)}));
    expect(() => apply(state, 400), throwsStateError);
    expect(balance(state), -1);
  });
}
