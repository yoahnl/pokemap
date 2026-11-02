import 'package:map_battle/map_battle.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('C7 required abilities', () {
    test('Adaptability replaces matching STAB with 2 before rounding', () {
      expect(_damage().stabMultiplier, 1.5);
      final adapted = _damage(ability: 'adaptability');
      expect(adapted.stabMultiplier, 2);
      expect(adapted.damage, 16);
      expect(_hit(_engine(ability: 'adaptability')), 16);
    });
    test('Adaptability accepts secondary and third types only once', () {
      expect(
          _damage(
                  ability: 'adaptability',
                  userTypes: const PsdkBattleTypes(
                      primary: 'water', secondary: 'normal'))
              .stabMultiplier,
          2);
      expect(
          _damage(
                  ability: 'adaptability',
                  userTypes: const PsdkBattleTypes(primary: 'water'),
                  thirdType: 'normal')
              .stabMultiplier,
          2);
    });
    test('Adaptability leaves other types and status moves unchanged', () {
      expect(_damage(ability: 'adaptability', type: 'water').stabMultiplier, 1);
      expect(_damage(ability: 'adaptability', statusMove: true).damage, 0);
      expect(
          _damage(ability: 'adaptability', statusMove: true).stabMultiplier, 1);
      expect(_damage(ability: 'adaptability', suppressed: true).stabMultiplier,
          1.5);
    });
    for (final type in ['normal', 'fighting']) {
      test('Scrappy lets $type hit Ghost through the complete turn pipeline',
          () {
        expect(
            _hit(_engine(
                type: type, foeTypes: const PsdkBattleTypes(primary: 'ghost'))),
            0);
        expect(
            _hit(_engine(
                ability: 'scrappy',
                type: type,
                foeTypes: const PsdkBattleTypes(primary: 'ghost'))),
            type == 'normal' ? 12 : 8);
        expect(
            _hit(_engine(
                ability: 'scrappy',
                type: type,
                suppressed: true,
                foeTypes: const PsdkBattleTypes(primary: 'ghost'))),
            0);
      });
    }
    for (final entry in {'rock': 0.5, 'dark': 1.0, 'steel': 0.5}.entries) {
      test('Scrappy Normal preserves Ghost/${entry.key} multiplier', () {
        final types = PsdkBattleTypes(primary: 'ghost', secondary: entry.key);
        expect(
            _hit(_engine(ability: 'scrappy', foeTypes: types)),
            _hit(_engine(
                ability: 'scrappy',
                foeTypes: PsdkBattleTypes(primary: entry.key))));
        expect(
            _damage(ability: 'scrappy', foeTypes: types)
                .typeEffectivenessMultiplier,
            entry.value);
      });
    }
    test('Scrappy Fighting preserves secondary weaknesses and resistances', () {
      expect(
          _hit(_engine(
              ability: 'scrappy',
              type: 'fighting',
              foeTypes:
                  const PsdkBattleTypes(primary: 'ghost', secondary: 'dark'))),
          16);
      expect(
          _hit(_engine(
              ability: 'scrappy',
              type: 'fighting',
              foeTypes: const PsdkBattleTypes(
                  primary: 'ghost', secondary: 'poison'))),
          4);
    });
    test('Scrappy preserves other type and ability immunities', () {
      expect(
          _hit(_engine(
              ability: 'scrappy',
              type: 'electric',
              foeTypes: const PsdkBattleTypes(primary: 'ground'))),
          0);
      expect(
          _hit(_engine(
              ability: 'scrappy',
              type: 'psychic',
              foeTypes: const PsdkBattleTypes(primary: 'dark'))),
          0);
      expect(
          _hit(_engine(
              ability: 'scrappy', type: 'electric', foeAbility: 'volt_absorb')),
          0);
    });
    for (final ability in ['adaptability', 'scrappy']) {
      test('$ability is disabled by Neutralizing Gas and Gastro Acid', () {
        final gas = _gasState(ability);
        expect(
            gas
                .battlerAt(psdkPlayerSlot)
                .effects
                .contains('ability_suppressed'),
            isTrue);
        expect(
            _damage(ability: ability, stateOverride: gas).stabMultiplier, 1.5);
        final acid = _engine(
            ability: ability,
            foeMove: _move('gastro_acid',
                method: 's_gastro_acid',
                power: 0,
                category: PsdkBattleMoveCategory.status));
        acid.submit(const BattleDecision.fight(moveSlot: 1));
        expect(
            acid
                .snapshot()
                .psdkState
                .battlerAt(psdkPlayerSlot)
                .effects
                .contains('ability_suppressed'),
            isTrue);
        expect(_hit(acid), 12);
      });
    }
    test('Mold Breaker on the foe leaves attacker-owned abilities active', () {
      expect(_hit(_engine(ability: 'adaptability', foeAbility: 'mold_breaker')),
          16);
      expect(
          _hit(_engine(
              ability: 'scrappy',
              foeAbility: 'mold_breaker',
              foeTypes: const PsdkBattleTypes(primary: 'ghost'))),
          12);
    });
    test('AI estimates attacker ability STAB and Scrappy immunity correctly',
        () {
      final adapted = _engine(ability: 'adaptability').snapshot().psdkState;
      final scrappy = _engine(
              ability: 'scrappy',
              foeTypes: const PsdkBattleTypes(primary: 'ghost'))
          .snapshot()
          .psdkState;
      final plain = _engine(foeTypes: const PsdkBattleTypes(primary: 'ghost'))
          .snapshot()
          .psdkState;
      int estimate(PsdkBattleState state) => const PsdkBattleAi()
          .scoreMoves(
              state: state, user: psdkPlayerSlot, target: psdkOpponentSlot)
          .first
          .estimatedDamage;
      expect(estimate(adapted), 20);
      expect(estimate(scrappy), 15);
      expect(estimate(plain), 0);
    });
    test('Scrappy preserves super-effective damage through Wonder Guard', () {
      expect(
          _hit(_engine(
              ability: 'scrappy',
              type: 'fighting',
              foeAbility: 'wonder_guard',
              foeTypes:
                  const PsdkBattleTypes(primary: 'ghost', secondary: 'dark'))),
          16);
      expect(
          _hit(_engine(
              ability: 'scrappy',
              type: 'normal',
              foeAbility: 'wonder_guard',
              foeTypes: const PsdkBattleTypes(primary: 'ghost'))),
          0);
    });
    test('Early Bird loses one action and attacks on the second', () {
      final engine = _engine(ability: 'early_bird', asleep: true);
      expect(_hit(engine), 0);
      expect(
          engine.snapshot().psdkState.battlerAt(psdkPlayerSlot).sleepTurns, 2);
      expect(_hit(engine), 12);
      final user = engine.snapshot().psdkState.battlerAt(psdkPlayerSlot);
      expect(user.majorStatus, isNull);
      expect(user.sleepTurns, 0);
      expect(user.effects.contains('sleep'), isFalse);
    });
    for (final elapsed in [1, 2, 3]) {
      test('Early Bird wakes before prevention at elapsed $elapsed', () {
        final engine =
            _engine(ability: 'early_bird', asleep: true, sleepTurns: elapsed);
        expect(_hit(engine), 12);
        expect(
            engine.snapshot().psdkState.battlerAt(psdkPlayerSlot).majorStatus,
            isNull);
        expect(engine.snapshot().psdkState.battlerAt(psdkPlayerSlot).sleepTurns,
            0);
      });
    }
    for (final ability in <String?>[null, 'early_bird']) {
      test(
          'ordinary and suppressed sleep retain two missed actions for $ability',
          () {
        final engine =
            _engine(ability: ability, asleep: true, suppressed: true);
        expect(_hit(engine), 0);
        expect(_hit(engine), 0);
        expect(_hit(engine), 12);
      });
    }
    test('Neutralizing Gas disables Early Bird acceleration', () {
      var state = _gasState('early_bird', asleep: true);
      for (var turn = 1; turn <= 3; turn++) {
        final result = const BattleStatusChangeHandler().resolveUserPrevention(
          context: BattleHandlerContext(
              state: state, rng: _rng(), turn: turn, user: psdkPlayerSlot),
          user: psdkPlayerSlot,
          move: BattleMoveDefinition.fromPsdk(_move('hit')),
        )!;
        expect(result.prevented, turn < 3);
        state = result.state;
      }
    });
    test('Early Bird Rest heals before shortened sleep and recovery', () {
      final engine = _engine(
          ability: 'early_bird',
          hp: 40,
          extraMove: _move('rest',
              method: 's_rest',
              power: 0,
              category: PsdkBattleMoveCategory.status,
              target: PsdkBattleMoveTarget.user));
      final rest = engine.submit(const BattleDecision.fight(moveSlot: 2));
      final user = rest.state.battlerAt(psdkPlayerSlot);
      expect(user.currentHp, 100);
      expect(user.majorStatus, PsdkBattleMajorStatus.sleep);
      expect(user.sleepTurns, 0);
      expect(user.moves[2].currentPp, 34);
      expect(_hit(engine), 0);
      expect(_hit(engine), 12);
    });
    test('Early Bird still permits Snore before waking', () {
      final engine =
          _engine(ability: 'early_bird', asleep: true, moveId: 'snore');
      expect(_hit(engine), 12);
      expect(engine.snapshot().psdkState.battlerAt(psdkPlayerSlot).majorStatus,
          PsdkBattleMajorStatus.sleep);
      expect(_hit(engine), 12);
      expect(engine.snapshot().psdkState.battlerAt(psdkPlayerSlot).majorStatus,
          isNull);
    });
  });
  group('C7 King Rock canonical transport', () {
    const canonical = PokemonMove(
      id: 'tackle',
      name: 'Charge',
      type: 'normal',
      category: PokemonMoveCategory.physical,
      basePower: 40,
      accuracy: PokemonMoveAccuracy.percent(value: 100),
      pp: 35,
    );
    const projector = CanonicalPsdkMoveProjector();
    test('projects explicit source eligibility and preserves unknown defaults',
        () {
      for (final id in [
        'tackle',
        'surf',
        'mirror_coat',
        'Mirror Coat',
        'mirrorcoat'
      ]) {
        expect(
            projector.project(move: canonical.copyWith(id: id)).kingRockUtility,
            isTrue,
            reason: id);
      }
      expect(
          projector
              .project(move: canonical.copyWith(id: 'thunder_fang'))
              .kingRockUtility,
          isFalse);
      expect(
          projector
              .project(move: canonical.copyWith(id: 'custom_move'))
              .kingRockUtility,
          isFalse);
      final sourceIdentity = canonical.copyWith(
          id: 'custom_move',
          sourceRefs: const PokemonMoveSourceRefs(showdownMoveId: 'TACKLE'));
      expect(projector.project(move: sourceIdentity).kingRockUtility, isTrue);
      final falseSource = canonical.copyWith(
          id: 'thunder_fang',
          sourceRefs: const PokemonMoveSourceRefs(showdownMoveId: 'tackle'));
      expect(projector.project(move: falseSource).kingRockUtility, isFalse);
    });
    test(
        'eligible projected moves activate the held item and prevent the foe action',
        () {
      final projected = projector.project(move: canonical);
      final engine = _engine(
          playerMove: projected,
          heldItem: 'king_s_rock',
          genericSeed: 0,
          foeMove: _move('foe_hit'));
      final result = engine.submit(const BattleDecision.fight(moveSlot: 0));
      expect(
          result.timeline.events
              .any((event) => event.toJson()['reason'] == 'item:king_s_rock'),
          isTrue);
      expect(
          result.timeline.events
              .whereType<BattleDamageTimelineEvent>()
              .where((event) => event.moveId == 'foe_hit'),
          isEmpty);
      expect(result.state.battlerAt(psdkPlayerSlot).heldItemId, 'king_s_rock');
    });
    test(
        'ineligible, unknown, nonholder and missed rolls retain the foe action',
        () {
      for (final row in [
        (id: 'thunder_fang', item: 'king_s_rock', seed: 0),
        (id: 'custom_move', item: 'king_s_rock', seed: 0),
        (id: 'tackle', item: null, seed: 0),
        (id: 'tackle', item: 'king_s_rock', seed: 9),
      ]) {
        final engine = _engine(
            playerMove: projector.project(move: canonical.copyWith(id: row.id)),
            heldItem: row.item,
            genericSeed: row.seed,
            foeMove: _move('foe_hit'));
        final result = engine.submit(const BattleDecision.fight(moveSlot: 0));
        expect(
            result.timeline.events
                .any((event) => event.toJson()['reason'] == 'item:king_s_rock'),
            isFalse,
            reason: row.toString());
        expect(
            result.timeline.events
                .whereType<BattleDamageTimelineEvent>()
                .where((event) => event.moveId == 'foe_hit'),
            hasLength(1),
            reason: row.toString());
      }
    });
  });
  group('C7 required move projections', () {
    test(
        'Mirror Coat canonical projection retaliates only against special hits',
        () {
      final projected = const CanonicalPsdkMoveProjector().project(
          move: const PokemonMove(
        id: 'mirror_coat',
        name: 'Voile Miroir',
        type: 'psychic',
        category: PokemonMoveCategory.special,
        basePower: 0,
        accuracy: PokemonMoveAccuracy.percent(value: 100),
        pp: 20,
        priority: -5,
      ));
      expect(projected.battleEngineMethod, 's_mirror_coat');
      for (final category in [
        PsdkBattleMoveCategory.special,
        PsdkBattleMoveCategory.physical
      ]) {
        final result = _engine(
                playerMove: projected,
                foeMove: _move('foe_hit', category: category))
            .submit(const BattleDecision.fight(moveSlot: 0));
        final incoming = result.timeline.events
            .whereType<BattleDamageTimelineEvent>()
            .where((event) => event.moveId == 'foe_hit')
            .single
            .damage;
        final reflected = result.timeline.events
            .whereType<BattleDamageTimelineEvent>()
            .where((event) => event.moveId == 'mirror_coat');
        if (category == PsdkBattleMoveCategory.special) {
          expect(reflected.single.damage, incoming * 2);
        } else {
          expect(reflected, isEmpty);
        }
      }
    });
    test(
        'zero-power retaliation respects type immunities without scaling fixed damage',
        () {
      for (final row in [
        (
          id: 'mirror_coat',
          type: 'psychic',
          category: PokemonMoveCategory.special,
          foeType: 'dark',
          ability: null,
          immune: true
        ),
        (
          id: 'mirror_coat',
          type: 'psychic',
          category: PokemonMoveCategory.special,
          foeType: 'dark',
          ability: 'mold_breaker',
          immune: true
        ),
        (
          id: 'mirror_coat',
          type: 'psychic',
          category: PokemonMoveCategory.special,
          foeType: 'steel',
          ability: null,
          immune: false
        ),
        (
          id: 'counter',
          type: 'fighting',
          category: PokemonMoveCategory.physical,
          foeType: 'ghost',
          ability: null,
          immune: true
        ),
        (
          id: 'counter',
          type: 'fighting',
          category: PokemonMoveCategory.physical,
          foeType: 'ghost',
          ability: 'mold_breaker',
          immune: true
        ),
        (
          id: 'counter',
          type: 'fighting',
          category: PokemonMoveCategory.physical,
          foeType: 'ghost',
          ability: 'scrappy',
          immune: false
        ),
        (
          id: 'counter',
          type: 'fighting',
          category: PokemonMoveCategory.physical,
          foeType: 'flying',
          ability: null,
          immune: false
        ),
      ]) {
        final projected = const CanonicalPsdkMoveProjector().project(
            move: PokemonMove(
          id: row.id,
          name: row.id,
          type: row.type,
          category: row.category,
          basePower: 0,
          accuracy: const PokemonMoveAccuracy.percent(value: 100),
          pp: 20,
          priority: -5,
        ));
        final result = _engine(
                playerMove: projected,
                ability: row.ability,
                foeTypes: PsdkBattleTypes(primary: row.foeType),
                foeMove: _move('foe_hit',
                    category: row.category == PokemonMoveCategory.special
                        ? PsdkBattleMoveCategory.special
                        : PsdkBattleMoveCategory.physical))
            .submit(const BattleDecision.fight(moveSlot: 0));
        final damage =
            result.timeline.events.whereType<BattleDamageTimelineEvent>();
        final incoming =
            damage.where((event) => event.moveId == 'foe_hit').single.damage;
        final reflected = damage.where((event) => event.moveId == row.id);
        if (row.immune) {
          expect(reflected, isEmpty, reason: row.toString());
          expect(
              result.timeline.events.any((event) =>
                  event.kind == 'move_immune' &&
                  event.toJson()['moveId'] == row.id),
              isTrue,
              reason: row.toString());
        } else {
          expect(reflected.single.damage, incoming * 2, reason: row.toString());
        }
      }
    });
    test('OHKO refuses a higher-level target even with No Guard', () {
      for (final ability in <String?>[null, 'no_guard']) {
        final engine = _engine(
            ability: ability,
            level: 20,
            foeLevel: 21,
            playerMove: _move('sheer_cold',
                type: 'ice', method: 's_ohko', power: 0, accuracy: 100));
        expect(_hit(engine), 0);
      }
    });
    test(
        'OHKO uses base accuracy plus level difference without accuracy stages',
        () {
      var witnessedExtraHit = false;
      for (var seed = 1; seed <= 100; seed++) {
        final roll = BattleRngStream(seed: seed).nextPercent().value;
        final move = _move('sheer_cold',
            type: 'ice', method: 's_ohko', power: 0, accuracy: 30);
        final engine = _engine(
            level: 30,
            foeLevel: 20,
            playerMove: move,
            accuracySeed: seed,
            stages: PsdkBattleStatStages(values: const {'accuracy': -6}),
            foeStages: PsdkBattleStatStages(values: const {'evasion': 6}));
        expect(_hit(engine), roll <= 40 ? 100 : 0, reason: 'roll=$roll');
        witnessedExtraHit |= roll > 30 && roll <= 40;
      }
      expect(witnessedExtraHit, isTrue);
    });
    test('OHKO retains Sturdy immunity, suppression and Mold Breaker', () {
      final move = _move('sheer_cold',
          type: 'ice', method: 's_ohko', power: 0, accuracy: 100);
      expect(_hit(_engine(playerMove: move, foeAbility: 'sturdy')), 0);
      expect(
          _hit(_engine(
              playerMove: move, ability: 'mold_breaker', foeAbility: 'sturdy')),
          100);
    });
    test('OHKO No Guard succeeds at equal level but not when suppressed', () {
      final move = _move('sheer_cold',
          type: 'ice', method: 's_ohko', power: 0, accuracy: 30);
      var seed = 1;
      while (BattleRngStream(seed: seed).nextPercent().value <= 30) {
        seed++;
      }
      expect(
          _hit(_engine(
              playerMove: move, ability: 'no_guard', accuracySeed: seed)),
          100);
      expect(
          _hit(_engine(
              playerMove: move,
              ability: 'no_guard',
              suppressed: true,
              accuracySeed: seed)),
          0);
      expect(
          _hit(_engine(
              playerMove: move, foeAbility: 'no_guard', accuracySeed: seed)),
          100);
    });
    test(
        'OHKO Lock On guarantees the right target while preserving the level gate',
        () {
      final move = _move('sheer_cold',
          type: 'ice', method: 's_ohko', power: 0, accuracy: 1);
      final lock = _move('lock_on',
          method: 's_lock_on',
          power: 0,
          category: PsdkBattleMoveCategory.status);
      for (final foeLevel in [20, 21]) {
        final engine =
            _engine(playerMove: move, extraMove: lock, foeLevel: foeLevel);
        engine.submit(const BattleDecision.fight(moveSlot: 2));
        expect(_hit(engine), foeLevel == 20 ? 100 : 0);
      }
    });
    test('OHKO type immunity is checked even with catalog power zero', () {
      expect(
          _hit(_engine(
              playerMove: _move('fissure',
                  type: 'ground', method: 's_ohko', power: 0, accuracy: 100),
              foeTypes: const PsdkBattleTypes(primary: 'flying'))),
          0);
      expect(
          _hit(_engine(
              playerMove: _move('guillotine',
                  type: 'normal', method: 's_ohko', power: 0, accuracy: 100),
              foeTypes: const PsdkBattleTypes(primary: 'ghost'))),
          0);
    });
    test('Hidden Power derives historical sentinel power from second IV bits',
        () {
      for (final entry in {0: 30, 2: 70, 31: 70}.entries) {
        final hidden = _engine(
            ivs: List.filled(6, entry.key),
            playerMove:
                _move('hidden_power', method: 's_hidden_power', power: 1));
        final expectedType = entry.key.isEven ? 'fighting' : 'dark';
        final ordinary = _engine(
            ivs: List.filled(6, entry.key),
            playerMove:
                _move('ordinary', type: expectedType, power: entry.value));
        expect(_hit(hidden), _hit(ordinary), reason: 'IV=${entry.key}');
      }
    });
    test('Hidden Power uses its IV type in Ghost and Ground immunity prechecks',
        () {
      final hidden = _move('hidden_power', method: 's_hidden_power', power: 1);
      expect(
          _hit(_engine(
              ivs: List.filled(6, 31),
              playerMove: hidden,
              foeTypes: const PsdkBattleTypes(primary: 'ghost'))),
          greaterThan(0));
      expect(
          _hit(_engine(
              ivs: [1, 1, 1, 1, 0, 1],
              playerMove: hidden,
              foeTypes: const PsdkBattleTypes(primary: 'ground'))),
          0);
    });
    test('Hidden Power preserves an explicit modern power of 60', () {
      final hidden = _engine(
          ivs: List.filled(6, 31),
          playerMove:
              _move('hidden_power', method: 's_hidden_power', power: 60));
      final ordinary =
          _engine(playerMove: _move('ordinary', type: 'dark', power: 60));
      expect(_hit(hidden), _hit(ordinary));
    });
  });
}

BattleEngine _engine({
  String? ability,
  String? foeAbility,
  String? heldItem,
  int genericSeed = 4,
  String type = 'normal',
  String moveId = 'hit',
  PsdkBattleTypes userTypes = const PsdkBattleTypes(primary: 'normal'),
  PsdkBattleTypes foeTypes = const PsdkBattleTypes(primary: 'water'),
  String? thirdType,
  bool suppressed = false,
  bool asleep = false,
  int sleepTurns = 0,
  int hp = 100,
  PsdkBattleMoveData? extraMove,
  PsdkBattleMoveData? foeMove,
  PsdkBattleMoveData? playerMove,
  int level = 20,
  int foeLevel = 20,
  int accuracySeed = 3,
  List<int>? ivs,
  PsdkBattleStatStages? stages,
  PsdkBattleStatStages? foeStages,
}) =>
    BattleEngine(
        setup: BattleEngineSetup.singlesPokeMapBetaV1ForTest(
      player: _combatant('player',
          ability: ability,
          heldItem: heldItem,
          types: userTypes,
          thirdType: thirdType,
          suppressed: suppressed,
          asleep: asleep,
          sleepTurns: sleepTurns,
          hp: hp,
          level: level,
          ivs: ivs,
          stages: stages,
          moves: [
            playerMove ?? _move(moveId, type: type),
            _move('wait', power: 0),
            if (extraMove != null) extraMove
          ]),
      opponent: _combatant('opponent',
          ability: foeAbility,
          types: foeTypes,
          moves: [foeMove ?? _move('foe_wait', power: 0)],
          speed: 1,
          level: foeLevel,
          stages: foeStages),
      rngSeeds: PsdkBattleRngSeeds(
          moveDamage: 1,
          moveCritical: 99999,
          moveAccuracy: accuracySeed,
          generic: genericSeed),
    ));

BattleMoveDamageResult _damage({
  String? ability,
  String type = 'normal',
  PsdkBattleTypes userTypes = const PsdkBattleTypes(primary: 'normal'),
  PsdkBattleTypes foeTypes = const PsdkBattleTypes(primary: 'water'),
  String? thirdType,
  bool suppressed = false,
  bool statusMove = false,
  PsdkBattleState? stateOverride,
}) {
  final state = stateOverride ??
      _engine(
              ability: ability,
              type: type,
              userTypes: userTypes,
              foeTypes: foeTypes,
              thirdType: thirdType,
              suppressed: suppressed)
          .snapshot()
          .psdkState;
  return const BattleMoveDamageCalculator().calculate(BattleMoveDamageContext(
    field: state.field,
    state: state,
    user: state.battlerAt(psdkPlayerSlot),
    target: state.battlerAt(psdkOpponentSlot),
    userSlot: psdkPlayerSlot,
    targetSlot: psdkOpponentSlot,
    move: BattleMoveDefinition.fromPsdk(_move('hit',
        type: type,
        category: statusMove
            ? PsdkBattleMoveCategory.status
            : PsdkBattleMoveCategory.physical)),
    rng: BattleRngStreams.fromSeedSnapshot(const BattleRngSeeds(
        moveDamage: 1, moveCritical: 99999, moveAccuracy: 3, generic: 4)),
  ));
}

PsdkBattleCombatantSetup _combatant(
  String id, {
  required PsdkBattleTypes types,
  required List<PsdkBattleMoveData> moves,
  String? ability,
  String? heldItem,
  String? thirdType,
  bool suppressed = false,
  bool asleep = false,
  int sleepTurns = 0,
  int hp = 100,
  int speed = 100,
  int level = 20,
  List<int>? ivs,
  PsdkBattleStatStages? stages,
}) =>
    PsdkBattleCombatantSetup(
      id: id,
      speciesId: id,
      displayName: id,
      level: level,
      maxHp: 100,
      currentHp: hp,
      types: types,
      type3: thirdType,
      stats: PsdkBattleStats(
          attack: 50,
          defense: 50,
          specialAttack: 50,
          specialDefense: 50,
          speed: speed),
      moves: moves,
      abilityId: ability,
      heldItemId: heldItem,
      majorStatus: asleep ? PsdkBattleMajorStatus.sleep : null,
      sleepTurns: sleepTurns,
      statStages: stages,
      ivHp: ivs?[0] ?? 31,
      ivAttack: ivs?[1] ?? 31,
      ivDefense: ivs?[2] ?? 31,
      ivSpeed: ivs?[3] ?? 31,
      ivSpecialAttack: ivs?[4] ?? 31,
      ivSpecialDefense: ivs?[5] ?? 31,
      effects:
          PsdkBattleEffectStack(values: [if (suppressed) 'ability_suppressed']),
    );

PsdkBattleMoveData _move(
  String id, {
  String type = 'normal',
  String method = 's_basic',
  int power = 40,
  int accuracy = 100,
  PsdkBattleMoveCategory category = PsdkBattleMoveCategory.physical,
  PsdkBattleMoveTarget target = PsdkBattleMoveTarget.adjacentFoe,
}) =>
    PsdkBattleMoveData(
        id: id,
        dbSymbol: id,
        name: id,
        type: type,
        category: category,
        power: power,
        accuracy: accuracy,
        pp: 35,
        priority: 0,
        battleEngineMethod: method,
        target: target);

int _hit(BattleEngine engine) {
  final result = engine.submit(const BattleDecision.fight(moveSlot: 0));
  return result.timeline.events
      .whereType<BattleDamageTimelineEvent>()
      .where((event) =>
          event.user == const BattlePositionRef(bank: 0, position: 0))
      .fold(0, (sum, event) => sum + event.damage);
}

BattleRngStreams _rng() =>
    BattleRngStreams.fromSeedSnapshot(const BattleRngSeeds(
        moveDamage: 1, moveCritical: 99999, moveAccuracy: 3, generic: 4));

PsdkBattleState _gasState(String ability, {bool asleep = false}) {
  final state =
      _engine(ability: ability, asleep: asleep, foeAbility: 'neutralizing_gas')
          .snapshot()
          .psdkState;
  return const BattleSwitchHandler()
      .dispatchSwitchEvents(
        context: BattleHandlerContext(
            state: state, rng: _rng(), turn: 1, user: psdkOpponentSlot),
        who: psdkOpponentSlot,
        replacement: psdkOpponentSlot,
      )
      .state;
}
