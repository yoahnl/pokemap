import 'package:map_battle/map_battle.dart';
import 'package:test/test.dart';

void main() {
  group('PSDK berry item effects', () {
    test('Oran Berry heals after damage at the PSDK half HP threshold', () {
      final result = _damagePlayer(
        playerHeldItemId: 'oran_berry',
        rawDamage: 60,
      );
      final player = result.state.battlerAt(psdkPlayerSlot);

      expect(player.currentHp, 50);
      expect(player.heldItemId, isNull);
      expect(player.consumedItemId, 'oran_berry');
      expect(player.itemConsumed, isTrue);
      expect(_healEvents(result, moveId: 'item:oran_berry').single.amount, 10);
      expect(_itemEvents(result).single.itemId, 'oran_berry');
    });

    test('Sitrus Berry heals at end turn and is consumed only once', () {
      final first = _tickEndTurn(
        playerHeldItemId: 'sitrus_berry',
        playerCurrentHp: 40,
      );
      final second = const BattleEndTurnHandler().resolveEndTurn(
        BattleHandlerContext(
          state: first.state,
          rng: first.rng,
          turn: 3,
          user: psdkPlayerSlot,
        ),
      );

      expect(first.state.battlerAt(psdkPlayerSlot).currentHp, 65);
      expect(first.state.battlerAt(psdkPlayerSlot).heldItemId, isNull);
      expect(
          first.state.battlerAt(psdkPlayerSlot).consumedItemId, 'sitrus_berry');
      expect(_healEvents(first, moveId: 'item:sitrus_berry').single.amount, 25);
      expect(_healEvents(second, moveId: 'item:sitrus_berry'), isEmpty);
      expect(_itemEvents(second), isEmpty);
    });

    test('Ripen doubles HP-healing berries', () {
      final result = _tickEndTurn(
        playerHeldItemId: 'sitrus_berry',
        playerCurrentHp: 40,
        playerAbilityId: 'ripen',
      );
      final player = result.state.battlerAt(psdkPlayerSlot);

      expect(player.currentHp, 90);
      expect(player.consumedItemId, 'sitrus_berry');
      expect(
          _healEvents(result, moveId: 'item:sitrus_berry').single.amount, 50);
    });

    test('Cheek Pouch heals after consuming a berry', () {
      final result = _damagePlayer(
        playerHeldItemId: 'oran_berry',
        playerAbilityId: 'cheek_pouch',
        rawDamage: 60,
      );
      final player = result.state.battlerAt(psdkPlayerSlot);

      expect(player.currentHp, 83);
      expect(player.consumedItemId, 'oran_berry');
      expect(_healEvents(result, moveId: 'item:oran_berry').single.amount, 10);
      expect(
        _healEvents(result, moveId: 'ability:cheek_pouch').single.amount,
        33,
      );
    });

    test('Unburden doubles speed after the held item is consumed', () {
      final before = _state(
        playerHeldItemId: 'oran_berry',
        playerAbilityId: 'unburden',
      );
      final consumed = _damagePlayer(
        playerHeldItemId: 'oran_berry',
        playerAbilityId: 'unburden',
        rawDamage: 60,
      );
      final restored = const BattleItemChangeHandler().changeHeldItem(
        context: BattleHandlerContext(
          state: consumed.state,
          rng: consumed.rng,
          turn: 2,
          user: psdkPlayerSlot,
        ),
        target: psdkPlayerSlot,
        heldItemId: 'sitrus_berry',
      );

      expect(_fightSpeed(before), 50);
      expect(_fightSpeed(consumed.state), 100);
      expect(_fightSpeed(restored.state), 50);
    });

    test(
        'Harvest restores and immediately re-executes a threshold berry in sun',
        () {
      final result = _tickEndTurn(
        playerHeldItemId: null,
        playerCurrentHp: 40,
        playerAbilityId: 'harvest',
        playerConsumedItemId: 'sitrus_berry',
        playerItemConsumed: true,
        weather: PsdkBattleWeatherId.sunny,
      );
      final player = result.state.battlerAt(psdkPlayerSlot);

      expect(player.currentHp, 65);
      expect(player.heldItemId, isNull);
      expect(player.consumedItemId, 'sitrus_berry');
      expect(
          _healEvents(result, moveId: 'item:sitrus_berry').single.amount, 25);
      expect(_itemEvents(result).single.itemId, 'sitrus_berry');
    });

    test('Rawst Berry cures burn immediately after the status is applied', () {
      final result = _applyStatus(
        playerHeldItemId: 'rawst_berry',
        status: PsdkBattleMajorStatus.burn,
      );
      final player = result.state.battlerAt(psdkPlayerSlot);

      expect(player.majorStatus, isNull);
      expect(player.heldItemId, isNull);
      expect(player.consumedItemId, 'rawst_berry');
      expect(_statusCureEvents(result, moveId: 'status_move').single.status,
          PsdkBattleMajorStatus.burn);
      expect(_itemEvents(result).single.itemId, 'rawst_berry');
    });

    test('Lum Berry cures any major status and Pecha Berry cures toxic', () {
      final lum = _applyStatus(
        playerHeldItemId: 'lum_berry',
        status: PsdkBattleMajorStatus.sleep,
      );
      final pecha = _applyStatus(
        playerHeldItemId: 'pecha_berry',
        status: PsdkBattleMajorStatus.toxic,
      );

      expect(lum.state.battlerAt(psdkPlayerSlot).majorStatus, isNull);
      expect(lum.state.battlerAt(psdkPlayerSlot).consumedItemId, 'lum_berry');
      expect(pecha.state.battlerAt(psdkPlayerSlot).majorStatus, isNull);
      expect(
          pecha.state.battlerAt(psdkPlayerSlot).consumedItemId, 'pecha_berry');
    });

    test('PSDK status berries cure their exact major status', () {
      final cases = <(String, PsdkBattleMajorStatus)>[
        ('aspear_berry', PsdkBattleMajorStatus.freeze),
        ('cheri_berry', PsdkBattleMajorStatus.paralysis),
        ('chesto_berry', PsdkBattleMajorStatus.sleep),
        ('pecha_berry', PsdkBattleMajorStatus.poison),
        ('rawst_berry', PsdkBattleMajorStatus.burn),
      ];

      for (final (itemId, status) in cases) {
        final result = _applyStatus(playerHeldItemId: itemId, status: status);
        final player = result.state.battlerAt(psdkPlayerSlot);

        expect(player.majorStatus, isNull, reason: itemId);
        expect(player.consumedItemId, itemId, reason: itemId);
        expect(_itemEvents(result).single.itemId, itemId, reason: itemId);
      }
    });

    test('Berry Juice heals a fixed amount at the half HP threshold', () {
      final result = _damagePlayer(
        playerHeldItemId: 'berry_juice',
        rawDamage: 60,
      );
      final player = result.state.battlerAt(psdkPlayerSlot);

      expect(player.currentHp, 60);
      expect(player.consumedItemId, 'berry_juice');
      expect(_healEvents(result, moveId: 'item:berry_juice').single.amount, 20);
    });

    test('Liechi Berry raises attack at pinch threshold', () {
      final result = _tickEndTurn(
        playerHeldItemId: 'liechi_berry',
        playerCurrentHp: 25,
      );
      final player = result.state.battlerAt(psdkPlayerSlot);

      expect(player.heldItemId, isNull);
      expect(player.consumedItemId, 'liechi_berry');
      expect(player.statStages.valueOf('attack'), 1);
      expect(_statEvents(result).single.stat, 'attack');
      expect(_itemEvents(result).single.itemId, 'liechi_berry');
    });

    test('PSDK pinch stat berries raise their mapped stat', () {
      final cases = <(String, String)>[
        ('liechi_berry', 'attack'),
        ('ganlon_berry', 'defense'),
        ('salac_berry', 'speed'),
        ('petaya_berry', 'specialAttack'),
        ('apicot_berry', 'specialDefense'),
      ];

      for (final (itemId, stat) in cases) {
        final result = _tickEndTurn(
          playerHeldItemId: itemId,
          playerCurrentHp: 25,
        );
        final player = result.state.battlerAt(psdkPlayerSlot);

        expect(player.heldItemId, isNull, reason: itemId);
        expect(player.consumedItemId, itemId, reason: itemId);
        expect(player.statStages.valueOf(stat), 1, reason: itemId);
      }
    });

    test('Starf Berry consumes and raises one random stat', () {
      final result = _tickEndTurn(
        playerHeldItemId: 'starf_berry',
        playerCurrentHp: 25,
      );
      final player = result.state.battlerAt(psdkPlayerSlot);

      expect(player.heldItemId, isNull);
      expect(player.consumedItemId, 'starf_berry');
      expect(_statEvents(result), hasLength(1));
      expect(
        player.statStages.values.values.where((stage) => stage == 1),
        hasLength(1),
      );
    });

    test('type-resisting berries reduce matching damage and consume once', () {
      final baseline = _runPlayerMove(
        opponentTypes: const PsdkBattleTypes(primary: 'grass'),
        playerMove: _move(id: 'ember', type: 'fire', power: 80),
      );
      final occa = _runPlayerMove(
        opponentHeldItemId: 'occa_berry',
        opponentTypes: const PsdkBattleTypes(primary: 'grass'),
        playerMove: _move(id: 'ember', type: 'fire', power: 80),
      );
      final neutral = _runPlayerMove(
        opponentHeldItemId: 'occa_berry',
        opponentTypes: const PsdkBattleTypes(primary: 'normal'),
        playerMove: _move(id: 'ember', type: 'fire', power: 80),
      );
      final neutralBaseline = _runPlayerMove(
        opponentTypes: const PsdkBattleTypes(primary: 'normal'),
        playerMove: _move(id: 'ember', type: 'fire', power: 80),
      );
      final chilan = _runPlayerMove(
        opponentHeldItemId: 'chilan_berry',
        opponentTypes: const PsdkBattleTypes(primary: 'normal'),
        playerMove: _move(id: 'tackle', type: 'normal', power: 80),
      );
      final chilanBaseline = _runPlayerMove(
        opponentTypes: const PsdkBattleTypes(primary: 'normal'),
        playerMove: _move(id: 'tackle', type: 'normal', power: 80),
      );

      expect(_damage(occa, moveId: 'ember'),
          lessThan(_damage(baseline, moveId: 'ember')));
      expect(occa.state.battlerAt(psdkOpponentSlot).heldItemId, isNull);
      expect(
          occa.state.battlerAt(psdkOpponentSlot).consumedItemId, 'occa_berry');
      expect(_itemEventsFromTurn(occa).single.itemId, 'occa_berry');
      expect(_damage(neutral, moveId: 'ember'),
          _damage(neutralBaseline, moveId: 'ember'));
      expect(
          neutral.state.battlerAt(psdkOpponentSlot).heldItemId, 'occa_berry');
      expect(_damage(chilan, moveId: 'tackle'),
          lessThan(_damage(chilanBaseline, moveId: 'tackle')));
      expect(chilan.state.battlerAt(psdkOpponentSlot).consumedItemId,
          'chilan_berry');
    });

    test('Enigma Berry heals after a super-effective hit and consumes', () {
      final result = _runPlayerMove(
        opponentHeldItemId: 'enigma_berry',
        opponentTypes: const PsdkBattleTypes(primary: 'grass'),
        playerMove: _move(id: 'flamethrower', type: 'fire', power: 120),
        opponentCurrentHp: 160,
        opponentMaxHp: 200,
      );

      final opponent = result.state.battlerAt(psdkOpponentSlot);
      expect(opponent.heldItemId, isNull);
      expect(opponent.consumedItemId, 'enigma_berry');
      expect(
          _healEventsFromTurn(result, moveId: 'item:enigma_berry')
              .single
              .amount,
          50);
      expect(_itemEventsFromTurn(result).single.itemId, 'enigma_berry');
    });

    test('Jaboca and Rowap punish matching incoming categories', () {
      final jaboca = _runPlayerMove(
        opponentHeldItemId: 'jaboca_berry',
        playerMove: _move(id: 'slash', type: 'normal', power: 80),
      );
      final rowap = _runPlayerMove(
        opponentHeldItemId: 'rowap_berry',
        playerMove: _move(
          id: 'swift',
          type: 'normal',
          power: 80,
          category: PsdkBattleMoveCategory.special,
        ),
      );
      final wrongCategory = _runPlayerMove(
        opponentHeldItemId: 'jaboca_berry',
        playerMove: _move(
          id: 'swift',
          type: 'normal',
          power: 80,
          category: PsdkBattleMoveCategory.special,
        ),
      );

      expect(jaboca.state.battlerAt(psdkPlayerSlot).currentHp, 88);
      expect(jaboca.state.battlerAt(psdkOpponentSlot).consumedItemId,
          'jaboca_berry');
      expect(rowap.state.battlerAt(psdkPlayerSlot).currentHp, 88);
      expect(rowap.state.battlerAt(psdkOpponentSlot).consumedItemId,
          'rowap_berry');
      expect(wrongCategory.state.battlerAt(psdkPlayerSlot).currentHp, 100);
      expect(
          wrongCategory.state.battlerAt(psdkOpponentSlot).heldItemId, isNull);
      expect(wrongCategory.state.battlerAt(psdkOpponentSlot).consumedItemId,
          'jaboca_berry');
    });

    test('Kee and Maranga raise defense stats after matching hits', () {
      final kee = _runPlayerMove(
        opponentHeldItemId: 'kee_berry',
        playerMove: _move(id: 'slash', type: 'normal', power: 80),
      );
      final maranga = _runPlayerMove(
        opponentHeldItemId: 'maranga_berry',
        playerMove: _move(
          id: 'swift',
          type: 'normal',
          power: 80,
          category: PsdkBattleMoveCategory.special,
        ),
      );

      expect(kee.state.battlerAt(psdkOpponentSlot).consumedItemId, 'kee_berry');
      expect(
          kee.state.battlerAt(psdkOpponentSlot).statStages.valueOf('defense'),
          1);
      expect(maranga.state.battlerAt(psdkOpponentSlot).consumedItemId,
          'maranga_berry');
      expect(
        maranga.state
            .battlerAt(psdkOpponentSlot)
            .statStages
            .valueOf('specialDefense'),
        1,
      );
    });
  });
}

const _seeds = BattleRngSeeds(
  moveDamage: 1,
  moveCritical: 99999,
  moveAccuracy: 3,
  generic: 4,
);

BattleHandlerResult _damagePlayer({
  required String? playerHeldItemId,
  String? playerAbilityId,
  required int rawDamage,
}) {
  final state = _state(
    playerHeldItemId: playerHeldItemId,
    playerAbilityId: playerAbilityId,
  );
  return const BattleDamageHandler().applyDamage(
    context: BattleHandlerContext(
      state: state,
      rng: BattleRngStreams.fromSeedSnapshot(_seeds),
      turn: 1,
      user: psdkOpponentSlot,
    ),
    target: psdkPlayerSlot,
    moveId: 'tackle',
    rawDamage: rawDamage,
    move: BattleMoveDefinition.fromPsdk(_move(id: 'tackle', power: 40)),
  );
}

PsdkBattleTurnResult _runPlayerMove({
  required PsdkBattleMoveData playerMove,
  String? opponentHeldItemId,
  PsdkBattleTypes opponentTypes = const PsdkBattleTypes(primary: 'normal'),
  int opponentCurrentHp = 100,
  int opponentMaxHp = 100,
}) {
  final engine = PsdkBattleEngine(
    setup: BattleEngineSetup.singles(
      player: _combatant(
        id: 'player',
        move: playerMove,
      ),
      opponent: _combatant(
        id: 'opponent',
        heldItemId: opponentHeldItemId,
        types: opponentTypes,
        currentHp: opponentCurrentHp,
        maxHp: opponentMaxHp,
        move: _move(id: 'opponent_wait', type: 'normal', power: 0),
      ),
      rngSeeds: _seeds.psdkSeeds,
    ).psdkSetup,
  );
  return engine.submit(const PsdkBattleDecision.fight(moveSlot: 0));
}

BattleHandlerResult _tickEndTurn({
  required String? playerHeldItemId,
  required int playerCurrentHp,
  String? playerAbilityId,
  String? playerConsumedItemId,
  bool playerItemConsumed = false,
  PsdkBattleWeatherId? weather,
}) {
  final state = _state(
    playerHeldItemId: playerHeldItemId,
    playerCurrentHp: playerCurrentHp,
    playerAbilityId: playerAbilityId,
    playerConsumedItemId: playerConsumedItemId,
    playerItemConsumed: playerItemConsumed,
    weather: weather,
  );
  return const BattleEndTurnHandler().resolveEndTurn(
    BattleHandlerContext(
      state: state,
      rng: BattleRngStreams.fromSeedSnapshot(_seeds),
      turn: 2,
      user: psdkPlayerSlot,
    ),
  );
}

BattleHandlerResult _applyStatus({
  required String playerHeldItemId,
  required PsdkBattleMajorStatus status,
}) {
  final state = _state(playerHeldItemId: playerHeldItemId);
  return const BattleStatusChangeHandler().applyMajorStatus(
    context: BattleHandlerContext(
      state: state,
      rng: BattleRngStreams.fromSeedSnapshot(_seeds),
      turn: 1,
      user: psdkOpponentSlot,
    ),
    target: psdkPlayerSlot,
    moveId: 'status_move',
    status: status,
  );
}

PsdkBattleState _state({
  required String? playerHeldItemId,
  int playerCurrentHp = 100,
  String? playerAbilityId,
  String? playerConsumedItemId,
  bool playerItemConsumed = false,
  PsdkBattleWeatherId? weather,
}) {
  final state = PsdkBattleState.fromSetup(
    BattleEngineSetup.singles(
      player: _combatant(
        id: 'player',
        heldItemId: playerHeldItemId,
        abilityId: playerAbilityId,
        consumedItemId: playerConsumedItemId,
        itemConsumed: playerItemConsumed,
        currentHp: playerCurrentHp,
        move: _move(id: 'tackle', power: 40),
      ),
      opponent: _combatant(
        id: 'opponent',
        move: _move(id: 'status_move', power: 0),
      ),
      rngSeeds: _seeds.psdkSeeds,
    ).psdkSetup,
  );
  return weather == null
      ? state
      : state.copyWith(field: state.field.withWeather(weather));
}

PsdkBattleCombatantSetup _combatant({
  required String id,
  required PsdkBattleMoveData move,
  String? heldItemId,
  String? consumedItemId,
  bool itemConsumed = false,
  String? abilityId,
  PsdkBattleTypes types = const PsdkBattleTypes(primary: 'normal'),
  int maxHp = 100,
  int currentHp = 100,
}) {
  return PsdkBattleCombatantSetup(
    id: id,
    speciesId: id,
    displayName: id,
    level: 20,
    maxHp: maxHp,
    currentHp: currentHp,
    types: types,
    stats: const PsdkBattleStats(
      attack: 50,
      defense: 50,
      specialAttack: 50,
      specialDefense: 50,
      speed: 50,
    ),
    heldItemId: heldItemId,
    consumedItemId: consumedItemId,
    itemConsumed: itemConsumed,
    abilityId: abilityId,
    moves: <PsdkBattleMoveData>[move],
  );
}

int _fightSpeed(PsdkBattleState state) {
  final action = const PsdkBattleActionDecisionMapper().map(
    state: state,
    user: psdkPlayerSlot,
    decision: const BattleFightDecision(moveSlot: 0),
  );
  return (action as PsdkBattleFightAction).speed;
}

PsdkBattleMoveData _move({
  required String id,
  String type = 'normal',
  required int power,
  PsdkBattleMoveCategory? category,
}) {
  return PsdkBattleMoveData(
    id: id,
    dbSymbol: id,
    name: id,
    type: type,
    category: category ??
        (power > 0
            ? PsdkBattleMoveCategory.physical
            : PsdkBattleMoveCategory.status),
    power: power,
    accuracy: 100,
    pp: 35,
    priority: 0,
    criticalRate: 1,
    battleEngineMethod: power > 0 ? 's_basic' : 's_status',
    target: PsdkBattleMoveTarget.adjacentFoe,
  );
}

List<PsdkBattleHealEvent> _healEvents(
  BattleHandlerResult result, {
  required String moveId,
}) {
  return result.events
      .whereType<PsdkBattleHealEvent>()
      .where((event) => event.moveId == moveId)
      .toList(growable: false);
}

List<PsdkBattleItemEvent> _itemEvents(BattleHandlerResult result) {
  return result.events.whereType<PsdkBattleItemEvent>().toList(growable: false);
}

List<PsdkBattleStatusCureEvent> _statusCureEvents(
  BattleHandlerResult result, {
  required String moveId,
}) {
  return result.events
      .whereType<PsdkBattleStatusCureEvent>()
      .where((event) => event.moveId == moveId)
      .toList(growable: false);
}

List<PsdkBattleStatStageEvent> _statEvents(BattleHandlerResult result) {
  return result.events
      .whereType<PsdkBattleStatStageEvent>()
      .toList(growable: false);
}

int _damage(PsdkBattleTurnResult result, {required String moveId}) {
  return result.timeline.events
      .whereType<PsdkBattleDamageEvent>()
      .where((event) => event.moveId == moveId)
      .fold<int>(0, (total, event) => total + event.damage);
}

List<PsdkBattleHealEvent> _healEventsFromTurn(
  PsdkBattleTurnResult result, {
  required String moveId,
}) {
  return result.timeline.events
      .whereType<PsdkBattleHealEvent>()
      .where((event) => event.moveId == moveId)
      .toList(growable: false);
}

List<PsdkBattleItemEvent> _itemEventsFromTurn(PsdkBattleTurnResult result) {
  return result.timeline.events
      .whereType<PsdkBattleItemEvent>()
      .toList(growable: false);
}
