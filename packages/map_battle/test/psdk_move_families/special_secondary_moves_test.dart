import 'package:map_battle/map_battle.dart';
import 'package:test/test.dart';

void main() {
  group('PSDK special secondary move families', () {
    test('s_tri_attack can apply one of its three major statuses', () {
      final result = _runMove(
        playerMove: _move(
          id: 'tri_attack',
          category: PsdkBattleMoveCategory.special,
          power: 80,
          battleEngineMethod: 's_tri_attack',
        ),
      );

      expect(_damage(result, moveId: 'tri_attack'), greaterThan(0));
      expect(
        result.state.battlerAt(psdkOpponentSlot).majorStatus,
        isIn(<PsdkBattleMajorStatus>[
          PsdkBattleMajorStatus.paralysis,
          PsdkBattleMajorStatus.burn,
          PsdkBattleMajorStatus.freeze,
        ]),
      );
    });

    test('s_psychic_noise applies Heal Block unless Aroma Veil blocks it', () {
      final applied = _runMove(
        playerMove: _move(
          id: 'psychic_noise',
          type: 'psychic',
          category: PsdkBattleMoveCategory.special,
          power: 75,
          battleEngineMethod: 's_psychic_noise',
        ),
      );
      final blocked = _runMove(
        opponentAbilityId: 'aroma_veil',
        playerMove: _move(
          id: 'psychic_noise',
          type: 'psychic',
          category: PsdkBattleMoveCategory.special,
          power: 75,
          battleEngineMethod: 's_psychic_noise',
        ),
      );

      expect(_damage(applied, moveId: 'psychic_noise'), greaterThan(0));
      expect(
        applied.state
            .battlerAt(psdkOpponentSlot)
            .effects
            .contains('heal_block'),
        isTrue,
      );
      expect(
        blocked.state
            .battlerAt(psdkOpponentSlot)
            .effects
            .contains('heal_block'),
        isFalse,
      );
    });

    test('s_throat_chop applies a timed Throat Chop marker', () {
      final result = _runMove(
        playerMove: _move(
          id: 'throat_chop',
          type: 'dark',
          power: 80,
          battleEngineMethod: 's_throat_chop',
        ),
      );

      final target = result.state.battlerAt(psdkOpponentSlot);
      expect(_damage(result, moveId: 'throat_chop'), greaterThan(0));
      expect(target.effects.contains('throat_chop'), isTrue);
    });

    test('s_relic_song can apply its imported sleep rider', () {
      final result = _runMove(
        playerMove: _move(
          id: 'relic_song',
          type: 'normal',
          category: PsdkBattleMoveCategory.special,
          power: 75,
          battleEngineMethod: 's_relic_song',
          effectChance: 100,
          statuses: <PsdkBattleMoveStatus>[
            PsdkBattleMoveStatus(
              status: PsdkBattleMajorStatus.sleep,
              chance: 100,
            ),
          ],
        ),
      );

      expect(_damage(result, moveId: 'relic_song'), greaterThan(0));
      expect(
        result.state.battlerAt(psdkOpponentSlot).majorStatus,
        PsdkBattleMajorStatus.sleep,
      );
      expect(
        result.timeline.events.whereType<PsdkBattleStatusEvent>(),
        hasLength(1),
      );
    });

    test('Throat Chop prevents sound moves while its marker is active', () {
      final result = _runMove(
        playerEffects: const PsdkBattleEffectStack.empty().addEffect(
          ThroatChopEffect(scope: BattlerBattleEffectScope(psdkPlayerSlot)),
        ),
        playerMove: _move(
          id: 'hyper_voice',
          type: 'normal',
          category: PsdkBattleMoveCategory.special,
          power: 90,
          battleEngineMethod: 's_basic',
          sound: true,
        ),
      );

      expect(_failed(result, moveId: 'hyper_voice'), isTrue);
      expect(_damageEvents(result, moveId: 'hyper_voice'), isEmpty);
    });

    test('s_burn_up requires and then removes the user move type locally', () {
      final blocked = _runMove(
        playerTypes: const PsdkBattleTypes(primary: 'normal'),
        playerMove: _move(
          id: 'burn_up',
          type: 'fire',
          category: PsdkBattleMoveCategory.special,
          power: 130,
          battleEngineMethod: 's_burn_up',
        ),
      );
      final applied = _runMove(
        playerTypes: const PsdkBattleTypes(primary: 'fire'),
        playerMove: _move(
          id: 'burn_up',
          type: 'fire',
          category: PsdkBattleMoveCategory.special,
          power: 130,
          battleEngineMethod: 's_burn_up',
        ),
      );

      final user = applied.state.battlerAt(psdkPlayerSlot);
      expect(_failed(blocked, moveId: 'burn_up'), isTrue);
      expect(_damageEvents(blocked, moveId: 'burn_up'), isEmpty);
      expect(_damage(applied, moveId: 'burn_up'), greaterThan(0));
      expect(user.hasType('fire'), isFalse);
      expect(user.effects.contains('burn_up'), isTrue);
    });

    test('s_incinerate removes a target berry after a successful hit', () {
      final result = _runMove(
        opponentHeldItemId: 'oran_berry',
        playerMove: _move(
          id: 'incinerate',
          type: 'fire',
          category: PsdkBattleMoveCategory.special,
          power: 60,
          battleEngineMethod: 's_incinerate',
        ),
      );

      expect(_damage(result, moveId: 'incinerate'), greaterThan(0));
      expect(result.state.battlerAt(psdkOpponentSlot).heldItemId, isNull);
    });

    test('s_alluring_voice confuses targets boosted this turn', () {
      final result = _runMove(
        opponentStatHistory: PsdkBattleStatHistory(
          entries: const <PsdkBattleStatHistoryEntry>[
            PsdkBattleStatHistoryEntry(
              turn: 1,
              stat: 'attack',
              delta: 1,
              currentStage: 1,
            ),
          ],
        ),
        playerMove: _move(
          id: 'alluring_voice',
          type: 'fairy',
          category: PsdkBattleMoveCategory.special,
          power: 80,
          battleEngineMethod: 's_alluring_voice',
        ),
      );

      final target = result.state.battlerAt(psdkOpponentSlot);
      expect(_damage(result, moveId: 'alluring_voice'), greaterThan(0));
      expect(target.effects.contains('confusion'), isTrue);
    });

    test('s_burning_jealousy burns targets boosted this turn', () {
      final result = _runMove(
        opponentStatHistory: PsdkBattleStatHistory(
          entries: const <PsdkBattleStatHistoryEntry>[
            PsdkBattleStatHistoryEntry(
              turn: 1,
              stat: 'attack',
              delta: 1,
              currentStage: 1,
            ),
          ],
        ),
        playerMove: _move(
          id: 'burning_jealousy',
          type: 'fire',
          category: PsdkBattleMoveCategory.special,
          power: 70,
          battleEngineMethod: 's_burning_jealousy',
        ),
      );

      expect(_damage(result, moveId: 'burning_jealousy'), greaterThan(0));
      expect(
        result.state.battlerAt(psdkOpponentSlot).majorStatus,
        PsdkBattleMajorStatus.burn,
      );
    });

    test('s_salt_cure installs residual damage with water/steel scaling', () {
      final result = _runMove(
        opponentTypes: const PsdkBattleTypes(primary: 'water'),
        playerMove: _move(
          id: 'salt_cure',
          type: 'rock',
          category: PsdkBattleMoveCategory.physical,
          power: 40,
          battleEngineMethod: 's_salt_cure',
        ),
      );

      final target = result.state.battlerAt(psdkOpponentSlot);
      expect(_damage(result, moveId: 'salt_cure'), greaterThan(0));
      expect(target.effects.contains('salt_cure'), isTrue);
      expect(_damage(result, moveId: 'effect:salt_cure'), 25);
    });

    test('s_syrup_bomb installs a timed speed-drop effect', () {
      final result = _runMove(
        playerMove: _move(
          id: 'syrup_bomb',
          type: 'grass',
          category: PsdkBattleMoveCategory.special,
          power: 60,
          battleEngineMethod: 's_syrup_bomb',
        ),
      );

      final target = result.state.battlerAt(psdkOpponentSlot);
      expect(_damage(result, moveId: 'syrup_bomb'), greaterThan(0));
      expect(target.effects.contains('syrup_bomb'), isTrue);
      expect(target.statStages.valueOf('speed'), -1);
    });

    test('s_tar_shot installs a fire-weakness marker', () {
      final result = _runMove(
        playerMove: _move(
          id: 'tar_shot',
          type: 'rock',
          category: PsdkBattleMoveCategory.status,
          power: 0,
          battleEngineMethod: 's_tar_shot',
        ),
      );

      expect(
          result.state.battlerAt(psdkOpponentSlot).effects.contains('tar_shot'),
          isTrue);
      expect(_damageEvents(result, moveId: 'tar_shot'), isEmpty);
    });
  });
}

PsdkBattleTurnResult _runMove({
  required PsdkBattleMoveData playerMove,
  PsdkBattleTypes playerTypes = const PsdkBattleTypes(primary: 'normal'),
  PsdkBattleEffectStack playerEffects = const PsdkBattleEffectStack.empty(),
  PsdkBattleTypes opponentTypes = const PsdkBattleTypes(primary: 'normal'),
  String? opponentAbilityId,
  String? opponentHeldItemId,
  PsdkBattleStatHistory opponentStatHistory =
      const PsdkBattleStatHistory.empty(),
}) {
  final engine = PsdkBattleEngine(
    setup: PsdkBattleSetup.singles(
      player: _combatant(
        id: 'player',
        speed: 100,
        types: playerTypes,
        effects: playerEffects,
        move: playerMove,
      ),
      opponent: _combatant(
        id: 'opponent',
        speed: 1,
        types: opponentTypes,
        abilityId: opponentAbilityId,
        heldItemId: opponentHeldItemId,
        statHistory: opponentStatHistory,
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
  String? abilityId,
  String? heldItemId,
  PsdkBattleStatHistory statHistory = const PsdkBattleStatHistory.empty(),
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
    abilityId: abilityId,
    heldItemId: heldItemId,
    statHistory: statHistory,
    effects: effects,
    stats: PsdkBattleStats(
      attack: 50,
      defense: 50,
      specialAttack: 50,
      specialDefense: 50,
      speed: speed,
    ),
    moves: <PsdkBattleMoveData>[move],
  );
}

PsdkBattleMoveData _move({
  required String id,
  String type = 'normal',
  PsdkBattleMoveCategory category = PsdkBattleMoveCategory.physical,
  required int power,
  int accuracy = 100,
  String battleEngineMethod = 's_basic',
  bool sound = false,
  int? effectChance,
  List<PsdkBattleMoveStatus> statuses = const <PsdkBattleMoveStatus>[],
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
    effectChance: effectChance,
    battleEngineMethod: battleEngineMethod,
    target: PsdkBattleMoveTarget.adjacentFoe,
    sound: sound,
    statuses: statuses,
  );
}

int _damage(PsdkBattleTurnResult result, {required String moveId}) {
  return _damageEvents(result, moveId: moveId).single.damage;
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

bool _failed(PsdkBattleTurnResult result, {required String moveId}) {
  return result.timeline.events
      .whereType<PsdkBattleMoveFailedEvent>()
      .any((event) => event.moveId == moveId);
}
