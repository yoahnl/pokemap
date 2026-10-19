import 'package:map_battle/map_battle.dart';
import 'package:test/test.dart';

void main() {
  test('an authored opponent option is consumed once across engine turns', () {
    final engine = _engine();

    final first = engine.submit(const BattleDecision.fight(moveSlot: 0));
    final second = engine.submit(const BattleDecision.fight(moveSlot: 0));

    expect(_opponentItems(first), hasLength(1));
    expect(_opponentItems(second), isEmpty);
  });

  test('a rejected turn restores the heal and leaves the stock available', () {
    final engine = _engine();
    final before = engine.snapshot();

    expect(
      () => engine.submit(
        const BattleDecision.item(
          itemId: 'player_tonic',
          target: psdkPlayerSlot,
          effect: PsdkBattleHpHealItemEffect.flat(1),
          highPriority: false,
        ),
      ),
      throwsA(isA<BattleDecisionRejectedError>()),
    );
    expect(engine.snapshot().turnNumber, before.turnNumber);
    expect(
      engine.snapshot().battlerAt(psdkOpponentSlot).currentHp,
      before.battlerAt(psdkOpponentSlot).currentHp,
    );

    final committed = engine.submit(const BattleDecision.fight(moveSlot: 0));
    expect(_opponentItems(committed), hasLength(1));
    final exhausted = engine.submit(const BattleDecision.fight(moveSlot: 0));
    expect(_opponentItems(exhausted), isEmpty);
  });

  test('a fresh engine receives a fresh authored stock', () {
    final first = _engine();
    first.submit(const BattleDecision.fight(moveSlot: 0));
    final second = _engine();

    expect(
      _opponentItems(second.submit(const BattleDecision.fight(moveSlot: 0))),
      hasLength(1),
    );
  });

  test('quantity two allows exactly two committed consumptions', () {
    final engine = _engine(quantity: 2);
    final turns = List.generate(
      3,
      (_) => engine.submit(const BattleDecision.fight(moveSlot: 0)),
    );

    expect(turns.map((turn) => _opponentItems(turn).length), [1, 1, 0]);
  });

  test('player use of the same item never changes opponent availability', () {
    final engine = _engine(playerHp: 70);
    const decision = BattleDecision.item(
      itemId: 'trainer_tonic',
      target: psdkPlayerSlot,
      effect: PsdkBattleHpHealItemEffect.flat(1),
      highPriority: true,
    );
    final first = engine.submit(decision);
    final second = engine.submit(decision);

    expect(_opponentItems(first), hasLength(1));
    expect(_opponentItems(second), isEmpty);
    expect(
      [...first.timeline.events, ...second.timeline.events]
          .whereType<BattleItemTimelineEvent>()
          .where((event) => event.user.bank == 0),
      hasLength(2),
    );
  });

  test('an opponent replacement never replenishes the shared trainer stock', () {
    final engine = _engine(playerPower: 1000, opponentReserve: true);
    final first = engine.submit(const BattleDecision.fight(moveSlot: 0));

    expect(_opponentItems(first), hasLength(1));
    expect(engine.snapshot().battlerAt(psdkOpponentSlot).id, 'reserve');
    final second = engine.submit(const BattleDecision.fight(moveSlot: 0));
    expect(_opponentItems(second), isEmpty);
  });

  test('a voluntary opponent switch keeps the trainer stock exhausted', () {
    final engine = _engine(
      opponentReserve: true,
      opponentReservePower: 1000,
      canSwitch: true,
    );
    final first = engine.submit(const BattleDecision.fight(moveSlot: 0));
    expect(_opponentItems(first), hasLength(1));
    expect(engine.snapshot().battlerAt(psdkOpponentSlot).id, 'opponent');

    final second = engine.submit(const BattleDecision.fight(moveSlot: 0));
    expect(_opponentItems(second), isEmpty);
    expect(engine.snapshot().battlerAt(psdkOpponentSlot).id, 'reserve');
    expect(engine.snapshot().battlerAt(psdkOpponentSlot).currentHp, greaterThan(0));

    final third = engine.submit(const BattleDecision.fight(moveSlot: 0));
    expect(_opponentItems(third), isEmpty);
  });

  test('scoring an unusable full HP heal does not spend the stock', () {
    final engine = _engine(opponentHp: 100);
    final first = engine.submit(const BattleDecision.fight(moveSlot: 0));
    expect(_opponentItems(first), isEmpty);

    final second = engine.submit(const BattleDecision.fight(moveSlot: 0));
    expect(_opponentItems(second), hasLength(1));
    final third = engine.submit(const BattleDecision.fight(moveSlot: 0));
    expect(_opponentItems(third), isEmpty);
  });
}

List<BattleItemTimelineEvent> _opponentItems(BattleEngineTurnResult result) =>
    result.timeline.events
        .whereType<BattleItemTimelineEvent>()
        .where((event) => event.user.bank == 1 && event.kind == 'item_consumed')
        .toList();

BattleEngine _engine({
  int quantity = 1,
  int playerHp = 100,
  int playerPower = 1,
  int opponentHp = 20,
  int opponentReservePower = 1,
  bool opponentReserve = false,
  bool canSwitch = false,
}) => BattleEngine(
  setup: BattleEngineSetup.singlesPokeMapBetaV1ForTest(
    player: _battler('player', playerHp, power: playerPower),
    opponent: _battler('opponent', opponentHp),
    opponentReserves: [
      if (opponentReserve) _battler('reserve', 20, power: opponentReservePower),
    ],
    rngSeeds: const PsdkBattleRngSeeds(
      moveDamage: 1,
      moveCritical: 99999,
      moveAccuracy: 3,
      generic: 4,
    ),
  ),
  opponentAi: PsdkBattleAi(
    canSwitch: canSwitch,
    canUseItem: true,
    itemOptions: [
      PsdkBattleAiItemOption.hpHeal(
        itemId: 'trainer_tonic',
        amount: 1,
        quantity: quantity,
      ),
    ],
  ),
);

PsdkBattleCombatantSetup _battler(String id, int currentHp, {int power = 1}) =>
    PsdkBattleCombatantSetup(
      id: id,
      speciesId: 'test_species',
      displayName: id,
      level: 5,
      maxHp: 100,
      currentHp: currentHp,
      types: const PsdkBattleTypes(primary: 'normal'),
      stats: const PsdkBattleStats(
        attack: 10,
        defense: 10,
        specialAttack: 10,
        specialDefense: 10,
        speed: 10,
      ),
      moves: [
        PsdkBattleMoveData(
          id: 'test_move',
          dbSymbol: 'test_move',
          name: 'Test move',
          type: 'normal',
          category: PsdkBattleMoveCategory.physical,
          power: power,
          accuracy: 100,
          pp: 40,
          priority: 0,
          battleEngineMethod: 's_basic',
          target: PsdkBattleMoveTarget.adjacentFoe,
        ),
      ],
    );
