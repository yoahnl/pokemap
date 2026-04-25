import 'package:map_battle/map_battle.dart';
import 'package:test/test.dart';

void main() {
  group('PSDK persistent effect move families', () {
    test('s_aqua_ring adds a healing end-turn effect to the user', () {
      final engine = PsdkBattleEngine(
        setup: _setup(
          playerCurrentHp: 60,
          playerMoves: <PsdkBattleMoveData>[
            _move(
              id: 'aqua_ring',
              battleEngineMethod: 's_aqua_ring',
              target: PsdkBattleMoveTarget.user,
            ),
          ],
        ),
      );

      final result = engine.submit(const PsdkBattleDecision.fight(moveSlot: 0));
      final player = result.state.battlerAt(psdkPlayerSlot);

      expect(player.effects.contains('aqua_ring'), isTrue);
      expect(
          player.effects.effects
              .singleWhere((effect) => effect.id == 'aqua_ring'),
          isA<AquaRingEffect>());
      expect(player.currentHp, 66);
      expect(_heal(result, moveId: 'effect:aqua_ring').amount, 6);
    });

    test('s_aqua_ring fails when every target already has Aqua Ring', () {
      final engine = PsdkBattleEngine(
        setup: _setup(
          playerCurrentHp: 60,
          playerEffects: const PsdkBattleEffectStack.empty().addEffect(
            const AquaRingEffect(
              scope: BattlerBattleEffectScope(psdkPlayerSlot),
            ),
          ),
          playerMoves: <PsdkBattleMoveData>[
            _move(
              id: 'aqua_ring',
              battleEngineMethod: 's_aqua_ring',
              target: PsdkBattleMoveTarget.user,
            ),
          ],
        ),
      );

      final result = engine.submit(const PsdkBattleDecision.fight(moveSlot: 0));
      final failed =
          result.timeline.events.whereType<PsdkBattleMoveFailedEvent>();

      expect(failed.single.reason, 'unusable_by_user');
      expect(result.state.battlerAt(psdkPlayerSlot).currentHp, 66);
    });

    test('ghost s_curse creates a CurseEffect that damages the target later',
        () {
      final engine = PsdkBattleEngine(
        setup: _setup(
          playerTypes: const PsdkBattleTypes(primary: 'ghost'),
          playerMoves: <PsdkBattleMoveData>[
            _move(
              id: 'curse',
              battleEngineMethod: 's_curse',
              target: PsdkBattleMoveTarget.adjacentFoe,
            ),
          ],
        ),
      );

      final result = engine.submit(const PsdkBattleDecision.fight(moveSlot: 0));
      final opponent = result.state.battlerAt(psdkOpponentSlot);

      expect(opponent.effects.contains('curse'), isTrue);
      expect(
          opponent.effects.effects
              .singleWhere((effect) => effect.id == 'curse'),
          isA<CurseEffect>());
      expect(_damage(result, moveId: 'curse').damage, 50);
      expect(_damage(result, moveId: 'effect:curse').damage, 25);
    });
  });
}

PsdkBattleSetup _setup({
  List<PsdkBattleMoveData>? playerMoves,
  PsdkBattleTypes playerTypes = const PsdkBattleTypes(primary: 'normal'),
  int playerCurrentHp = 100,
  PsdkBattleEffectStack playerEffects = const PsdkBattleEffectStack.empty(),
}) {
  return PsdkBattleSetup.singles(
    player: _combatant(
      id: 'player',
      speed: 100,
      currentHp: playerCurrentHp,
      types: playerTypes,
      moves: playerMoves ?? <PsdkBattleMoveData>[_move(id: 'tackle')],
      effects: playerEffects,
    ),
    opponent: _combatant(
      id: 'opponent',
      speed: 1,
      moves: <PsdkBattleMoveData>[
        _move(
          id: 'splash',
          battleEngineMethod: 's_splash',
          target: PsdkBattleMoveTarget.none,
        ),
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
  int speed = 50,
  int currentHp = 100,
  PsdkBattleTypes types = const PsdkBattleTypes(primary: 'normal'),
  List<PsdkBattleMoveData>? moves,
  PsdkBattleEffectStack effects = const PsdkBattleEffectStack.empty(),
}) {
  return PsdkBattleCombatantSetup(
    id: id,
    speciesId: id,
    displayName: id,
    level: 20,
    maxHp: 100,
    currentHp: currentHp,
    types: types,
    stats: PsdkBattleStats(
      attack: 50,
      defense: 50,
      specialAttack: 50,
      specialDefense: 50,
      speed: speed,
    ),
    moves: moves ?? <PsdkBattleMoveData>[_move(id: 'tackle')],
    effects: effects,
  );
}

PsdkBattleMoveData _move({
  required String id,
  String? battleEngineMethod,
  PsdkBattleMoveTarget target = PsdkBattleMoveTarget.adjacentFoe,
}) {
  return PsdkBattleMoveData(
    id: id,
    dbSymbol: id,
    name: id,
    type: 'normal',
    category: PsdkBattleMoveCategory.status,
    power: 0,
    accuracy: 0,
    pp: 35,
    priority: 0,
    criticalRate: 1,
    battleEngineMethod: battleEngineMethod ?? 's_basic',
    target: target,
  );
}

PsdkBattleHealEvent _heal(
  PsdkBattleTurnResult result, {
  required String moveId,
}) {
  return result.timeline.events
      .whereType<PsdkBattleHealEvent>()
      .singleWhere((event) => event.moveId == moveId);
}

PsdkBattleDamageEvent _damage(
  PsdkBattleTurnResult result, {
  required String moveId,
}) {
  return result.timeline.events
      .whereType<PsdkBattleDamageEvent>()
      .singleWhere((event) => event.moveId == moveId);
}
