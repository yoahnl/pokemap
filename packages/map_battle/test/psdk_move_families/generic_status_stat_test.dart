import 'package:map_battle/map_battle.dart';
import 'package:test/test.dart';

void main() {
  group('PSDK generic status/stat move families', () {
    test('s_stat applies target status and stat stages without damage', () {
      final result = _runMove(
        playerMove: _move(
          id: 'scary_wave',
          battleEngineMethod: 's_stat',
          power: 0,
          category: PsdkBattleMoveCategory.status,
          statuses: <PsdkBattleMoveStatus>[
            PsdkBattleMoveStatus(
              status: PsdkBattleMajorStatus.paralysis,
              chance: 100,
            ),
          ],
          stageMods: const <PsdkBattleMoveStageMod>[
            PsdkBattleMoveStageMod(
              stat: 'attack',
              stages: -1,
              chance: 100,
            ),
          ],
        ),
      );
      final opponent = result.state.battlerAt(psdkOpponentSlot);

      expect(opponent.currentHp, 100);
      expect(opponent.majorStatus, PsdkBattleMajorStatus.paralysis);
      expect(opponent.statStages.valueOf('attack'), -1);
      expect(
        _eventKinds(result),
        containsAllInOrder(<String>['status', 'stat_stage_change']),
      );
      expect(_eventKinds(result), isNot(contains('damage')));
    });

    test('s_status applies target stat stages even without a major status', () {
      final result = _runMove(
        playerMove: _move(
          id: 'tail_whip',
          battleEngineMethod: 's_status',
          power: 0,
          category: PsdkBattleMoveCategory.status,
          stageMods: const <PsdkBattleMoveStageMod>[
            PsdkBattleMoveStageMod(
              stat: 'defense',
              stages: -1,
              chance: 100,
            ),
          ],
        ),
      );
      final opponent = result.state.battlerAt(psdkOpponentSlot);

      expect(opponent.currentHp, 100);
      expect(opponent.statStages.valueOf('defense'), -1);
      expect(_eventKinds(result), contains('stat_stage_change'));
      expect(_eventKinds(result), isNot(contains('damage')));
    });

    test('s_stat fails when every target stat change is already capped', () {
      final result = _runMove(
        opponentStatStages: PsdkBattleStatStages(
          values: const <String, int>{
            'attack': -6,
            'specialAttack': -6,
          },
        ),
        playerMove: _move(
          id: 'noble_roar',
          battleEngineMethod: 's_stat',
          power: 0,
          category: PsdkBattleMoveCategory.status,
          stageMods: const <PsdkBattleMoveStageMod>[
            PsdkBattleMoveStageMod(
              stat: 'attack',
              stages: -1,
              chance: 100,
            ),
            PsdkBattleMoveStageMod(
              stat: 'specialAttack',
              stages: -1,
              chance: 100,
            ),
          ],
        ),
      );
      final opponent = result.state.battlerAt(psdkOpponentSlot);

      expect(opponent.statStages.valueOf('attack'), -6);
      expect(opponent.statStages.valueOf('specialAttack'), -6);
      expect(_eventKinds(result), contains('move_failed'));
      expect(_eventKinds(result), isNot(contains('stat_stage_change')));
      expect(
        result.state.battlerAt(psdkPlayerSlot).moveHistory.successfulMoveIds,
        isNot(contains('noble_roar')),
      );
    });

    test('s_toxic_thread fails only when poison and Speed drop both fail', () {
      final result = _runMove(
        opponentMajorStatus: PsdkBattleMajorStatus.poison,
        opponentStatStages: PsdkBattleStatStages(
          values: const <String, int>{'speed': -6},
        ),
        playerMove: _move(
          id: 'toxic_thread',
          battleEngineMethod: 's_toxic_thread',
          power: 0,
          category: PsdkBattleMoveCategory.status,
          statuses: <PsdkBattleMoveStatus>[
            PsdkBattleMoveStatus(
              status: PsdkBattleMajorStatus.poison,
              chance: 100,
            ),
          ],
          stageMods: const <PsdkBattleMoveStageMod>[
            PsdkBattleMoveStageMod(
              stat: 'speed',
              stages: -1,
              chance: 100,
            ),
          ],
        ),
      );
      final opponent = result.state.battlerAt(psdkOpponentSlot);

      expect(opponent.majorStatus, PsdkBattleMajorStatus.poison);
      expect(opponent.statStages.valueOf('speed'), -6);
      expect(_eventKinds(result), contains('move_failed'));
      expect(_eventKinds(result), isNot(contains('status')));
      expect(_eventKinds(result), isNot(contains('stat_stage_change')));
    });

    test('s_toxic_thread continues when either poison or Speed drop works', () {
      final speedDropOnly = _runMove(
        opponentMajorStatus: PsdkBattleMajorStatus.poison,
        playerMove: _move(
          id: 'toxic_thread',
          battleEngineMethod: 's_toxic_thread',
          power: 0,
          category: PsdkBattleMoveCategory.status,
          statuses: <PsdkBattleMoveStatus>[
            PsdkBattleMoveStatus(
              status: PsdkBattleMajorStatus.poison,
              chance: 100,
            ),
          ],
          stageMods: const <PsdkBattleMoveStageMod>[
            PsdkBattleMoveStageMod(
              stat: 'speed',
              stages: -1,
              chance: 100,
            ),
          ],
        ),
      );
      final poisonOnly = _runMove(
        opponentStatStages: PsdkBattleStatStages(
          values: const <String, int>{'speed': -6},
        ),
        playerMove: _move(
          id: 'toxic_thread',
          battleEngineMethod: 's_toxic_thread',
          power: 0,
          category: PsdkBattleMoveCategory.status,
          statuses: <PsdkBattleMoveStatus>[
            PsdkBattleMoveStatus(
              status: PsdkBattleMajorStatus.poison,
              chance: 100,
            ),
          ],
          stageMods: const <PsdkBattleMoveStageMod>[
            PsdkBattleMoveStageMod(
              stat: 'speed',
              stages: -1,
              chance: 100,
            ),
          ],
        ),
      );
      final speedDropTarget = speedDropOnly.state.battlerAt(psdkOpponentSlot);
      final poisonTarget = poisonOnly.state.battlerAt(psdkOpponentSlot);

      expect(speedDropTarget.majorStatus, PsdkBattleMajorStatus.poison);
      expect(speedDropTarget.statStages.valueOf('speed'), -1);
      expect(_eventKinds(speedDropOnly), contains('stat_stage_change'));
      expect(_eventKinds(speedDropOnly), isNot(contains('move_failed')));
      expect(poisonTarget.majorStatus, PsdkBattleMajorStatus.poison);
      expect(poisonTarget.statStages.valueOf('speed'), -6);
      expect(_eventKinds(poisonOnly), contains('status'));
      expect(_eventKinds(poisonOnly), isNot(contains('move_failed')));
    });

    test('Mist prevents opposing stat drops', () {
      final result = _runMove(
        opponentEffects: const PsdkBattleEffectStack.empty().addEffect(
          GenericBattleEffect(id: 'mist', scope: BankBattleEffectScope(1)),
        ),
        playerMove: _move(
          id: 'tail_whip',
          battleEngineMethod: 's_status',
          power: 0,
          category: PsdkBattleMoveCategory.status,
          stageMods: const <PsdkBattleMoveStageMod>[
            PsdkBattleMoveStageMod(
              stat: 'defense',
              stages: -1,
              chance: 100,
            ),
          ],
        ),
      );
      final opponent = result.state.battlerAt(psdkOpponentSlot);

      expect(opponent.statStages.valueOf('defense'), 0);
      expect(_eventKinds(result), isNot(contains('stat_stage_change')));
    });

    test('s_mist installs protection before slower opposing stat drops', () {
      final result = _runMove(
        playerMove: _move(
          id: 'mist',
          battleEngineMethod: 's_mist',
          power: 0,
          accuracy: 0,
          category: PsdkBattleMoveCategory.status,
          target: PsdkBattleMoveTarget.self,
        ),
        opponentMove: _move(
          id: 'tail_whip',
          battleEngineMethod: 's_status',
          power: 0,
          category: PsdkBattleMoveCategory.status,
          stageMods: const <PsdkBattleMoveStageMod>[
            PsdkBattleMoveStageMod(
              stat: 'defense',
              stages: -1,
              chance: 100,
            ),
          ],
        ),
      );
      final player = result.state.battlerAt(psdkPlayerSlot);

      expect(player.effects.contains('mist'), isTrue);
      expect(player.statStages.valueOf('defense'), 0);
      expect(_eventKinds(result), isNot(contains('stat_stage_change')));
    });

    test('s_status applies target Confusion as a volatile effect', () {
      final result = _runMove(
        genericSeed: 1,
        playerMove: _move(
          id: 'confuse_ray',
          battleEngineMethod: 's_status',
          power: 0,
          category: PsdkBattleMoveCategory.status,
          statuses: <PsdkBattleMoveStatus>[
            PsdkBattleMoveStatus.volatile(
              status: PsdkBattleVolatileStatus.confusion,
              chance: 100,
            ),
          ],
        ),
        opponentMove: _move(
          id: 'opponent_splash',
          battleEngineMethod: 's_splash',
          power: 0,
          accuracy: 0,
          category: PsdkBattleMoveCategory.status,
          target: PsdkBattleMoveTarget.none,
        ),
      );
      final opponent = result.state.battlerAt(psdkOpponentSlot);
      final confusion = opponent.effects.effects.whereType<ConfusionEffect>();

      expect(opponent.currentHp, 92);
      expect(opponent.moves.single.currentPp, 35);
      expect(opponent.effects.contains(PsdkBattleEffectIds.confusion), isTrue);
      expect(confusion.single.remainingConfusionTurns, 2);
      expect(
        result.timeline.events.whereType<PsdkBattleDamageEvent>().single.moveId,
        'effect:confusion',
      );
      expect(
        result.timeline.events
            .whereType<PsdkBattleMoveFailedEvent>()
            .single
            .moveId,
        'opponent_splash',
      );
    });

    test('s_status fails when the target already has a major status', () {
      final result = _runMove(
        opponentMajorStatus: PsdkBattleMajorStatus.burn,
        playerMove: _move(
          id: 'thunder_wave',
          battleEngineMethod: 's_status',
          power: 0,
          accuracy: 90,
          category: PsdkBattleMoveCategory.status,
          statuses: <PsdkBattleMoveStatus>[
            PsdkBattleMoveStatus(
              status: PsdkBattleMajorStatus.paralysis,
              chance: 100,
            ),
          ],
        ),
      );
      final opponent = result.state.battlerAt(psdkOpponentSlot);

      expect(opponent.majorStatus, PsdkBattleMajorStatus.burn);
      expect(_eventKinds(result), contains('move_failed'));
      expect(_eventKinds(result), isNot(contains('status')));
      expect(
        result.state.battlerAt(psdkPlayerSlot).moveHistory.successfulMoveIds,
        isNot(contains('thunder_wave')),
      );
    });

    test('s_status fails when type immunity blocks the major status', () {
      final result = _runMove(
        opponentTypes: const PsdkBattleTypes(primary: 'electric'),
        playerMove: _move(
          id: 'thunder_wave',
          battleEngineMethod: 's_status',
          power: 0,
          accuracy: 90,
          category: PsdkBattleMoveCategory.status,
          statuses: <PsdkBattleMoveStatus>[
            PsdkBattleMoveStatus(
              status: PsdkBattleMajorStatus.paralysis,
              chance: 100,
            ),
          ],
        ),
      );
      final opponent = result.state.battlerAt(psdkOpponentSlot);

      expect(opponent.majorStatus, isNull);
      expect(_eventKinds(result), contains('move_failed'));
      expect(_eventKinds(result), isNot(contains('status')));
    });

    test('s_self_stat damages the target and applies stages to the user', () {
      final result = _runMove(
        playerMove: _move(
          id: 'flame_charge',
          battleEngineMethod: 's_self_stat',
          power: 40,
          stageMods: const <PsdkBattleMoveStageMod>[
            PsdkBattleMoveStageMod(
              stat: 'speed',
              stages: 1,
              chance: 100,
            ),
          ],
        ),
      );
      final player = result.state.battlerAt(psdkPlayerSlot);
      final opponent = result.state.battlerAt(psdkOpponentSlot);

      expect(opponent.currentHp, lessThan(100));
      expect(player.statStages.valueOf('speed'), 1);
      expect(opponent.statStages.valueOf('speed'), 0);
      expect(
        _eventKinds(result),
        containsAllInOrder(<String>['damage', 'stat_stage_change']),
      );
      expect(
        result.timeline.events
            .whereType<PsdkBattleStatStageEvent>()
            .single
            .target,
        psdkPlayerSlot,
      );
    });

    test('s_self_stat status moves fail when every self boost is maxed', () {
      final result = _runMove(
        playerStatStages: PsdkBattleStatStages(
          values: const <String, int>{
            'specialAttack': 6,
            'specialDefense': 6,
          },
        ),
        playerMove: _move(
          id: 'calm_mind',
          battleEngineMethod: 's_self_stat',
          power: 0,
          accuracy: 0,
          category: PsdkBattleMoveCategory.status,
          target: PsdkBattleMoveTarget.user,
          stageMods: const <PsdkBattleMoveStageMod>[
            PsdkBattleMoveStageMod(
              stat: 'specialAttack',
              stages: 1,
              chance: 100,
            ),
            PsdkBattleMoveStageMod(
              stat: 'specialDefense',
              stages: 1,
              chance: 100,
            ),
          ],
        ),
      );
      final player = result.state.battlerAt(psdkPlayerSlot);

      expect(player.statStages.valueOf('specialAttack'), 6);
      expect(player.statStages.valueOf('specialDefense'), 6);
      expect(_eventKinds(result), contains('move_failed'));
      expect(_eventKinds(result), isNot(contains('stat_stage_change')));
      expect(
          player.moveHistory.successfulMoveIds, isNot(contains('calm_mind')));
    });

    test('s_self_status damages the target and applies status to the user', () {
      final result = _runMove(
        playerMove: _move(
          id: 'self_poison_hit',
          battleEngineMethod: 's_self_status',
          power: 40,
          statuses: <PsdkBattleMoveStatus>[
            PsdkBattleMoveStatus(
              status: PsdkBattleMajorStatus.poison,
              chance: 100,
            ),
          ],
        ),
      );
      final player = result.state.battlerAt(psdkPlayerSlot);
      final opponent = result.state.battlerAt(psdkOpponentSlot);

      expect(opponent.currentHp, lessThan(100));
      expect(player.majorStatus, PsdkBattleMajorStatus.poison);
      expect(opponent.majorStatus, isNull);
      expect(
        _eventKinds(result),
        containsAllInOrder(<String>['damage', 'status']),
      );
      expect(
        result.timeline.events.whereType<PsdkBattleStatusEvent>().single.target,
        psdkPlayerSlot,
      );
    });

    test('s_self_status fails when the user already has a major status', () {
      final result = _runMove(
        playerMajorStatus: PsdkBattleMajorStatus.burn,
        playerMove: _move(
          id: 'self_poison',
          battleEngineMethod: 's_self_status',
          power: 0,
          category: PsdkBattleMoveCategory.status,
          statuses: <PsdkBattleMoveStatus>[
            PsdkBattleMoveStatus(
              status: PsdkBattleMajorStatus.poison,
              chance: 100,
            ),
          ],
        ),
      );
      final player = result.state.battlerAt(psdkPlayerSlot);

      expect(player.majorStatus, PsdkBattleMajorStatus.burn);
      expect(_eventKinds(result), contains('move_failed'));
      expect(_eventKinds(result), isNot(contains('status')));
      expect(
        player.moveHistory.successfulMoveIds,
        isNot(contains('self_poison')),
      );
    });

    test('s_self_status applies self Confusion as a volatile effect', () {
      final result = _runMove(
        genericSeed: 1,
        playerMove: _move(
          id: 'self_confuse',
          battleEngineMethod: 's_self_status',
          power: 0,
          category: PsdkBattleMoveCategory.status,
          statuses: <PsdkBattleMoveStatus>[
            PsdkBattleMoveStatus.volatile(
              status: PsdkBattleVolatileStatus.confusion,
              chance: 100,
            ),
          ],
        ),
      );
      final player = result.state.battlerAt(psdkPlayerSlot);
      final confusion = player.effects.effects.whereType<ConfusionEffect>();

      expect(player.effects.contains(PsdkBattleEffectIds.confusion), isTrue);
      expect(confusion.single.remainingConfusionTurns, 3);
      expect(_eventKinds(result), isNot(contains('move_failed')));
    });
  });
}

PsdkBattleTurnResult _runMove({
  required PsdkBattleMoveData playerMove,
  PsdkBattleMoveData? opponentMove,
  PsdkBattleEffectStack opponentEffects = const PsdkBattleEffectStack.empty(),
  PsdkBattleMajorStatus? playerMajorStatus,
  PsdkBattleStatStages? playerStatStages,
  PsdkBattleMajorStatus? opponentMajorStatus,
  PsdkBattleStatStages? opponentStatStages,
  PsdkBattleTypes opponentTypes = const PsdkBattleTypes(primary: 'normal'),
  int genericSeed = 4,
}) {
  final engine = PsdkBattleEngine(
    setup: PsdkBattleSetup.singles(
      player: _combatant(
        id: 'player',
        speed: 100,
        move: playerMove,
        majorStatus: playerMajorStatus,
        statStages: playerStatStages,
      ),
      opponent: _combatant(
        id: 'opponent',
        speed: 1,
        move: opponentMove ??
            _move(
              id: 'opponent_wait',
              power: 0,
              accuracy: 1,
            ),
        majorStatus: opponentMajorStatus,
        statStages: opponentStatStages,
        effects: opponentEffects,
        types: opponentTypes,
      ),
      rngSeeds: PsdkBattleRngSeeds(
        moveDamage: 1,
        moveCritical: 99999,
        moveAccuracy: 3,
        generic: genericSeed,
      ),
    ),
  );
  return engine.submit(const PsdkBattleDecision.fight(moveSlot: 0));
}

PsdkBattleCombatantSetup _combatant({
  required String id,
  required int speed,
  required PsdkBattleMoveData move,
  PsdkBattleMajorStatus? majorStatus,
  PsdkBattleStatStages? statStages,
  PsdkBattleEffectStack effects = const PsdkBattleEffectStack.empty(),
  PsdkBattleTypes types = const PsdkBattleTypes(primary: 'normal'),
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
    statStages: statStages ?? PsdkBattleStatStages.neutral(),
    majorStatus: majorStatus,
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
  PsdkBattleMoveTarget target = PsdkBattleMoveTarget.adjacentFoe,
  List<PsdkBattleMoveStatus> statuses = const <PsdkBattleMoveStatus>[],
  List<PsdkBattleMoveStageMod> stageMods = const <PsdkBattleMoveStageMod>[],
}) {
  return PsdkBattleMoveData(
    id: id,
    dbSymbol: id,
    name: id,
    type: type,
    category: category,
    power: power,
    accuracy: accuracy,
    pp: 35,
    priority: 0,
    criticalRate: 1,
    battleEngineMethod: battleEngineMethod,
    target: target,
    statuses: statuses,
    stageMods: stageMods,
  );
}

List<String> _eventKinds(PsdkBattleTurnResult result) {
  return result.timeline.events.map((event) => event.kind).toList();
}
