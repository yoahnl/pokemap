import 'package:map_battle/map_battle.dart';
import 'package:test/test.dart';

void main() {
  group('PSDK offensive signature Z-Moves', () {
    test('Catastropika requires its signature crystal and source move', () {
      final result = _runZMove(
        playerSpeciesId: 'pikachu',
        playerHeldItemId: 'pikanium_z',
        zMove: _zMove(
          id: 'catastropika',
          type: 'electric',
          category: PsdkBattleMoveCategory.physical,
          power: 210,
        ),
        sourceMove: _sourceMove(id: 'volt_tackle', type: 'electric'),
      );

      expect(_damageEvents(result, moveId: 'catastropika'), hasLength(1));
      expect(result.state.battlerAt(psdkOpponentSlot).currentHp, lessThan(100));
      expect(
          result.state.psdkState.hasZMoveUsedBank(psdkPlayerSlot.bank), isTrue);
    });

    test('Z-Move attempts fail before PP without the matching crystal', () {
      final result = _runZMove(
        playerSpeciesId: 'pikachu',
        playerHeldItemId: 'leftovers',
        zMove: _zMove(
          id: 'catastropika',
          type: 'electric',
          category: PsdkBattleMoveCategory.physical,
          power: 210,
        ),
        sourceMove: _sourceMove(id: 'volt_tackle', type: 'electric'),
      );

      final failures =
          result.timeline.events.whereType<BattleMoveFailedTimelineEvent>();
      expect(failures, hasLength(1));
      expect(failures.single.reason, 'unusable_by_user');
      expect(_damageEvents(result, moveId: 'catastropika'), isEmpty);
      expect(result.state.battlerAt(psdkPlayerSlot).moves.first.currentPp, 1);
      expect(
        result.state.psdkState.hasZMoveUsedBank(psdkPlayerSlot.bank),
        isFalse,
      );
    });

    test('Z-Move attempts fail before PP when the source move is absent', () {
      final result = _runZMove(
        playerSpeciesId: 'pikachu',
        playerHeldItemId: 'pikanium_z',
        zMove: _zMove(
          id: 'catastropika',
          type: 'electric',
          category: PsdkBattleMoveCategory.physical,
          power: 210,
        ),
      );

      final failures =
          result.timeline.events.whereType<BattleMoveFailedTimelineEvent>();
      expect(failures, hasLength(1));
      expect(failures.single.reason, 'unusable_by_user');
      expect(_damageEvents(result, moveId: 'catastropika'), isEmpty);
      expect(result.state.battlerAt(psdkPlayerSlot).moves.first.currentPp, 1);
      expect(
        result.state.psdkState.hasZMoveUsedBank(psdkPlayerSlot.bank),
        isFalse,
      );
    });

    test('a bank can use only one offensive signature Z-Move', () {
      final engine = BattleEngine(
        setup: _setup(
          playerSpeciesId: 'pikachu',
          playerHeldItemId: 'pikanium_z',
          playerMoves: <PsdkBattleMoveData>[
            _zMove(
              id: 'catastropika',
              type: 'electric',
              category: PsdkBattleMoveCategory.physical,
              power: 40,
              pp: 2,
            ),
            _sourceMove(id: 'volt_tackle', type: 'electric'),
          ],
        ),
      );

      final first = engine.submit(const BattleDecision.fight(moveSlot: 0));
      final second = engine.submit(const BattleDecision.fight(moveSlot: 0));

      expect(_damageEvents(first, moveId: 'catastropika'), hasLength(1));
      expect(
        second.timeline.events
            .whereType<BattleMoveFailedTimelineEvent>()
            .single
            .reason,
        'unusable_by_user',
      );
      expect(_damageEvents(second, moveId: 'catastropika'), isEmpty);
      expect(second.state.battlerAt(psdkPlayerSlot).moves.first.currentPp, 1);
      expect(
          second.state.psdkState.hasZMoveUsedBank(psdkPlayerSlot.bank), isTrue);
    });

    test('Searing Sunraze Smash corrects Studio user target to the foe', () {
      final result = _runZMove(
        playerSpeciesId: 'solgaleo',
        playerHeldItemId: 'solganium_z',
        zMove: _zMove(
          id: 'searing_sunraze_smash',
          type: 'steel',
          category: PsdkBattleMoveCategory.physical,
          power: 200,
          target: PsdkBattleMoveTarget.user,
        ),
        sourceMove: _sourceMove(id: 'sunsteel_strike', type: 'steel'),
      );

      expect(
          _damageEvents(result, moveId: 'searing_sunraze_smash'), hasLength(1));
      expect(result.state.battlerAt(psdkOpponentSlot).currentHp, lessThan(100));
      expect(result.state.battlerAt(psdkPlayerSlot).currentHp, 100);
    });

    test('Stoked Sparksurfer applies its guaranteed paralysis rider', () {
      final result = _runZMove(
        playerSpeciesId: 'raichu_alola',
        playerHeldItemId: 'aloraichium_z',
        zMove: _zMove(
          id: 'stoked_sparksurfer',
          type: 'electric',
          category: PsdkBattleMoveCategory.special,
          power: 175,
          effectChance: 100,
          statuses: <PsdkBattleMoveStatus>[
            PsdkBattleMoveStatus(
              status: PsdkBattleMajorStatus.paralysis,
              chance: 100,
            ),
          ],
        ),
        sourceMove: _sourceMove(id: 'thunderbolt', type: 'electric'),
      );

      expect(_damageEvents(result, moveId: 'stoked_sparksurfer'), hasLength(1));
      expect(
        result.state.battlerAt(psdkOpponentSlot).majorStatus,
        PsdkBattleMajorStatus.paralysis,
      );
    });
  });
}

BattleEngineTurnResult _runZMove({
  required String playerSpeciesId,
  required String playerHeldItemId,
  required PsdkBattleMoveData zMove,
  PsdkBattleMoveData? sourceMove,
}) {
  final engine = BattleEngine(
    setup: _setup(
      playerSpeciesId: playerSpeciesId,
      playerHeldItemId: playerHeldItemId,
      playerMoves: <PsdkBattleMoveData>[
        zMove,
        if (sourceMove != null) sourceMove,
      ],
    ),
  );
  return engine.submit(const BattleDecision.fight(moveSlot: 0));
}

BattleEngineSetup _setup({
  required String playerSpeciesId,
  required String playerHeldItemId,
  required List<PsdkBattleMoveData> playerMoves,
}) {
  return BattleEngineSetup.singles(
    player: _combatant(
      id: 'player',
      speciesId: playerSpeciesId,
      heldItemId: playerHeldItemId,
      speed: 100,
      types: const PsdkBattleTypes(primary: 'electric'),
      moves: playerMoves,
    ),
    opponent: _combatant(
      id: 'opponent',
      speciesId: 'opponent',
      speed: 1,
      types: const PsdkBattleTypes(primary: 'water'),
      moves: <PsdkBattleMoveData>[
        _sourceMove(id: 'opponent_wait', type: 'normal', power: 0),
      ],
    ),
    rngSeeds: const PsdkBattleRngSeeds(
      moveDamage: 1,
      moveCritical: 99999,
      moveAccuracy: 3,
      generic: 4,
    ),
  );
}

PsdkBattleCombatantSetup _combatant({
  required String id,
  required String speciesId,
  required int speed,
  required PsdkBattleTypes types,
  required List<PsdkBattleMoveData> moves,
  String? heldItemId,
}) {
  return PsdkBattleCombatantSetup(
    id: id,
    speciesId: speciesId,
    displayName: id,
    level: 50,
    maxHp: 100,
    currentHp: 100,
    types: types,
    stats: PsdkBattleStats(
      attack: 80,
      defense: 70,
      specialAttack: 80,
      specialDefense: 70,
      speed: speed,
    ),
    heldItemId: heldItemId,
    moves: moves,
  );
}

PsdkBattleMoveData _zMove({
  required String id,
  required String type,
  required PsdkBattleMoveCategory category,
  required int power,
  int pp = 1,
  int criticalRate = 1,
  int? effectChance,
  PsdkBattleMoveTarget target = PsdkBattleMoveTarget.adjacentFoe,
  List<PsdkBattleMoveStatus> statuses = const <PsdkBattleMoveStatus>[],
}) {
  return PsdkBattleMoveData(
    id: id,
    dbSymbol: id,
    name: id,
    type: type,
    category: category,
    power: power,
    accuracy: 0,
    pp: pp,
    priority: 0,
    criticalRate: criticalRate,
    effectChance: effectChance,
    battleEngineMethod: 's_z_move',
    target: target,
    protectable: false,
    kingRockUtility: true,
    statuses: statuses,
  );
}

PsdkBattleMoveData _sourceMove({
  required String id,
  required String type,
  int power = 90,
}) {
  return PsdkBattleMoveData(
    id: id,
    dbSymbol: id,
    name: id,
    type: type,
    category: power == 0
        ? PsdkBattleMoveCategory.status
        : PsdkBattleMoveCategory.physical,
    power: power,
    accuracy: power == 0 ? 0 : 100,
    pp: 15,
    priority: 0,
    battleEngineMethod: power == 0 ? 's_status' : 's_basic',
    target: power == 0
        ? PsdkBattleMoveTarget.self
        : PsdkBattleMoveTarget.adjacentFoe,
  );
}

List<BattleDamageTimelineEvent> _damageEvents(
  BattleEngineTurnResult result, {
  required String moveId,
}) {
  return result.timeline.events
      .whereType<BattleDamageTimelineEvent>()
      .where((event) => event.moveId == moveId)
      .toList(growable: false);
}
