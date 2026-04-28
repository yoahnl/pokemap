import 'package:map_battle/map_battle.dart';
import 'package:test/test.dart';

void main() {
  group('PSDK grounding move families', () {
    test('s_smack_down damages and grounds an airborne target', () {
      final result = _runMove(
        playerMove: _move(
          id: 'smack_down',
          type: 'rock',
          power: 50,
          battleEngineMethod: 's_smack_down',
        ),
        opponentTypes: const PsdkBattleTypes(primary: 'flying'),
      );

      final target = result.state.battlerAt(psdkOpponentSlot);
      expect(_damageEvents(result, moveId: 'smack_down'), hasLength(1));
      expect(target.effects.contains('smack_down'), isTrue);
      expect(const BattleGroundingResolver().isGrounded(target), isTrue);
    });

    test('smack_down effect removes local Ground immunity from Flying type',
        () {
      final result = _runMove(
        playerMove: _move(
          id: 'earthquake',
          type: 'ground',
          power: 100,
          battleEngineMethod: 's_basic',
        ),
        opponentTypes: const PsdkBattleTypes(primary: 'flying'),
        opponentEffects: const PsdkBattleEffectStack.empty().add('smack_down'),
      );

      expect(_damageEvents(result, moveId: 'earthquake'), hasLength(1));
      expect(result.state.battlerAt(psdkOpponentSlot).currentHp, lessThan(100));
    });
  });
}

PsdkBattleTurnResult _runMove({
  required PsdkBattleMoveData playerMove,
  PsdkBattleTypes opponentTypes = const PsdkBattleTypes(primary: 'normal'),
  PsdkBattleEffectStack opponentEffects = const PsdkBattleEffectStack.empty(),
}) {
  final engine = PsdkBattleEngine(
    setup: PsdkBattleSetup.singles(
      player: _combatant(
        id: 'player',
        speed: 100,
        types: const PsdkBattleTypes(primary: 'normal'),
        move: playerMove,
      ),
      opponent: _combatant(
        id: 'opponent',
        speed: 1,
        types: opponentTypes,
        effects: opponentEffects,
        move: _move(
          id: 'opponent_wait',
          category: PsdkBattleMoveCategory.status,
          power: 0,
          accuracy: 0,
          battleEngineMethod: 's_splash',
        ),
      ),
      rngSeeds: const PsdkBattleRngSeeds(
        moveDamage: 1,
        moveCritical: 99999,
        moveAccuracy: 3,
        generic: 4,
      ),
    ),
  );
  return engine.submit(const PsdkBattleDecision.fight(moveSlot: 0));
}

PsdkBattleCombatantSetup _combatant({
  required String id,
  required int speed,
  required PsdkBattleTypes types,
  required PsdkBattleMoveData move,
  PsdkBattleEffectStack effects = const PsdkBattleEffectStack.empty(),
}) {
  return PsdkBattleCombatantSetup(
    id: id,
    speciesId: id,
    displayName: id,
    level: 20,
    maxHp: 100,
    currentHp: 100,
    types: types,
    stats: PsdkBattleStats(
      attack: 50,
      defense: 50,
      specialAttack: 50,
      specialDefense: 50,
      speed: speed,
    ),
    moves: <PsdkBattleMoveData>[move],
    effects: effects,
  );
}

PsdkBattleMoveData _move({
  required String id,
  String type = 'normal',
  PsdkBattleMoveCategory category = PsdkBattleMoveCategory.physical,
  required int power,
  int accuracy = 100,
  String battleEngineMethod = 's_basic',
}) {
  return PsdkBattleMoveData(
    id: id,
    dbSymbol: id,
    name: id,
    type: type,
    category: category,
    power: power,
    accuracy: accuracy,
    pp: 20,
    priority: 0,
    criticalRate: 1,
    battleEngineMethod: battleEngineMethod,
    target: PsdkBattleMoveTarget.adjacentFoe,
  );
}

List<PsdkBattleDamageEvent> _damageEvents(
  PsdkBattleTurnResult result, {
  required String moveId,
}) {
  return result.timeline.events
      .whereType<PsdkBattleDamageEvent>()
      .where((event) => event.moveId == moveId)
      .toList(growable: false);
}
