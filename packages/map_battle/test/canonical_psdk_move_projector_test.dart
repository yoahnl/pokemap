import 'package:map_battle/map_battle.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  const projector = CanonicalPsdkMoveProjector();
  const move = PokemonMove(
    id: 'custom_move',
    name: 'Custom Move',
    type: 'normal',
    category: PokemonMoveCategory.physical,
    basePower: 40,
    accuracy: PokemonMoveAccuracy.percent(value: 95),
    pp: 15,
  );

  test('projects scalar fields and existing DTO defaults', () {
    final result = projector.project(
      move: move.copyWith(type: ' FIRE ', priority: -2, critRatio: 3),
      currentPp: 7,
    );
    expect(result.id, 'custom_move');
    expect(result.dbSymbol, 'custom_move');
    expect(result.name, 'Custom Move');
    expect(result.type, 'fire');
    expect(result.power, 40);
    expect(result.accuracy, 95);
    expect(result.pp, 15);
    expect(result.currentPp, 7);
    expect(result.priority, -2);
    expect(result.criticalRate, 3);
    expect(result.battleEngineMethod, 's_basic');
    expect(result.effectChance, isNull);
    expect(result.protectable, isTrue);
    expect(result.mirrorMoveAffected, isTrue);
    expect(result.kingRockUtility, isFalse);
    expect(result.statuses, isEmpty);
    expect(result.stageMods, isEmpty);
    expect(projector.project(move: move).currentPp, 15);
  });

  final targets = <PokemonMoveTarget, PsdkBattleMoveTarget>{
    PokemonMoveTarget.adjacentAlly: PsdkBattleMoveTarget.adjacentAlly,
    PokemonMoveTarget.adjacentAllyOrSelf:
        PsdkBattleMoveTarget.adjacentAllyOrSelf,
    PokemonMoveTarget.adjacentFoe: PsdkBattleMoveTarget.adjacentFoe,
    PokemonMoveTarget.all: PsdkBattleMoveTarget.allBattlers,
    PokemonMoveTarget.allAdjacent: PsdkBattleMoveTarget.allAdjacent,
    PokemonMoveTarget.allAdjacentFoes: PsdkBattleMoveTarget.allAdjacentFoes,
    PokemonMoveTarget.allies: PsdkBattleMoveTarget.allAllies,
    PokemonMoveTarget.allySide: PsdkBattleMoveTarget.userSide,
    PokemonMoveTarget.allyTeam: PsdkBattleMoveTarget.allAllies,
    PokemonMoveTarget.any: PsdkBattleMoveTarget.anyFoe,
    PokemonMoveTarget.foeSide: PsdkBattleMoveTarget.foeSide,
    PokemonMoveTarget.normal: PsdkBattleMoveTarget.adjacentFoe,
    PokemonMoveTarget.randomNormal: PsdkBattleMoveTarget.randomFoe,
    PokemonMoveTarget.scripted: PsdkBattleMoveTarget.none,
    PokemonMoveTarget.self: PsdkBattleMoveTarget.user,
  };
  for (final entry in targets.entries) {
    test('projects target ${entry.key.name}', () {
      expect(projector.project(move: move.copyWith(target: entry.key)).target,
          entry.value);
    });
  }
  for (final category in PokemonMoveCategory.values) {
    test('projects category ${category.name} and clamps negative power', () {
      final result = projector.project(
        move: move.copyWith(
          category: category,
          basePower: -3,
          accuracy: const PokemonMoveAccuracy.alwaysHits(),
          unsupportedReasons: ['psdk_method:s_basic'],
        ),
      );
      expect(result.category.name, category.name);
      expect(result.power, 0);
      expect(result.accuracy, 0);
    });
  }

  final flagReaders = <PokemonMoveFlag, bool Function(PsdkBattleMoveData)>{
    PokemonMoveFlag.contact: (m) => m.contact,
    PokemonMoveFlag.sound: (m) => m.sound,
    PokemonMoveFlag.bite: (m) => m.bite,
    PokemonMoveFlag.pulse: (m) => m.pulse,
    PokemonMoveFlag.wind: (m) => m.wind,
    PokemonMoveFlag.bullet: (m) => m.ballistics,
    PokemonMoveFlag.dance: (m) => m.dance,
    PokemonMoveFlag.heal: (m) => m.heal,
    PokemonMoveFlag.charge: (m) => m.charge,
    PokemonMoveFlag.recharge: (m) => m.recharge,
    PokemonMoveFlag.snatch: (m) => m.snatchable,
    PokemonMoveFlag.reflectable: (m) => m.magicCoatAffected,
  };
  for (final flag in PokemonMoveFlag.values) {
    test('preserves existing mapping for flag ${flag.name}', () {
      final result = projector.project(move: move.copyWith(flags: [flag]));
      for (final entry in flagReaders.entries) {
        expect(entry.value(result), entry.key == flag, reason: entry.key.name);
      }
      expect(result.protectable, isTrue);
      expect(result.mirrorMoveAffected, isTrue);
      expect(result.kingRockUtility, isFalse);
    });
  }

  test('does not mutate support metadata or canonical source data', () {
    final canonical = move.copyWith(
      engineSupportLevel: PokemonMoveEngineSupportLevel.structuredPartial,
      unsupportedReasons: ['custom-reason', 'psdk_method:s_basic'],
      sourceRefs: const PokemonMoveSourceRefs(
        showdownMoveId: 'Different',
        showdownHooksPresent: ['onHit'],
      ),
    );
    final snapshot = canonical.toJson();
    projector.project(move: canonical);
    expect(canonical.toJson(), snapshot);
    for (final support in PokemonMoveEngineSupportLevel.values) {
      expect(
          projector
              .project(move: canonical.copyWith(engineSupportLevel: support))
              .battleEngineMethod,
          's_basic');
    }
  });

  test('uses first nonempty exact explicit method marker before all IDs', () {
    final canonical = move.copyWith(
      id: 'protect',
      unsupportedReasons: [
        'psdk_method: ',
        'other:ignored',
        'psdk_method: s_transform ',
        'psdk_method:s_counter',
      ],
      sourceRefs: const PokemonMoveSourceRefs(showdownMoveId: 'copycat'),
    );
    expect(projector.resolveBattleEngineMethod(canonical), 's_transform');
    expect(
        projector.project(move: canonical).battleEngineMethod, 's_transform');
    expect(projector.registryStatusFor('s_transform'), 'ported');
  });

  final aliases = <String, String>{
    'baton_pass': 's_baton_pass',
    'copycat': 's_mirror_move',
    'counter': 's_counter',
    'endure': 's_protect',
    'helping_hand': 's_helping_hand',
    'helpinghand': 's_helping_hand',
    'protect': 's_protect',
    'quick_guard': 's_protect',
    'quickguard': 's_protect',
    'transform': 's_transform',
  };
  for (final entry in aliases.entries) {
    test('resolves native and Showdown alias ${entry.key}', () {
      expect(
          projector.resolveBattleEngineMethod(
              move.copyWith(id: ' ${entry.key.toUpperCase()} ')),
          entry.value);
      expect(
          projector.resolveBattleEngineMethod(move.copyWith(
              sourceRefs: PokemonMoveSourceRefs(
                  showdownMoveId: ' ${entry.key.toUpperCase()} '))),
          entry.value);
    });
  }

  test(
      'resolves indexed native ID before Showdown alias then indexed Showdown ID',
      () {
    expect(
        projector.resolveBattleEngineMethod(move.copyWith(
            id: ' THUNDER WAVE ',
            sourceRefs:
                const PokemonMoveSourceRefs(showdownMoveId: 'protect'))),
        psdkBattleEngineMethodForMoveId('thunder_wave'));
    expect(
        projector.resolveBattleEngineMethod(move.copyWith(
            sourceRefs:
                const PokemonMoveSourceRefs(showdownMoveId: ' THUNDER WAVE '))),
        psdkBattleEngineMethodForMoveId('thunder_wave'));
    expect(psdkBattleEngineMethodForMoveId('thunder_wave'), isNotNull);
    expect(
        projector.resolveBattleEngineMethod(move.copyWith(
            sourceRefs: const PokemonMoveSourceRefs(showdownMoveId: ' '))),
        's_basic');
  });

  test('rejects missing method and unknown explicit method with typed reasons',
      () {
    final noMethod = move.copyWith(category: PokemonMoveCategory.status);
    expect(projector.resolveBattleEngineMethod(noMethod), isNull);
    expect(projector.registryStatusFor(null), isNull);
    expect(projector.registryStatusFor('s_unknown'), isNull);
    expect(
        () => projector.project(move: noMethod),
        throwsA(isA<CanonicalPsdkMoveProjectionException>().having(
            (e) => e.reason, 'reason', 'psdk_battle_engine_method_not_found')));
    expect(
        () => projector.project(
            move: move.copyWith(unsupportedReasons: ['psdk_method:s_unknown'])),
        throwsA(isA<CanonicalPsdkMoveProjectionException>().having(
            (e) => e.reason,
            'reason',
            'psdk_battle_engine_method_not_ported:s_unknown')));
  });

  for (final entry in {
    ' ': 'invalid_type:empty',
    ' COSMIC ': 'unsupported_type:cosmic'
  }.entries) {
    test('rejects invalid type ${entry.key} with typed reason', () {
      expect(
          () => projector.project(move: move.copyWith(type: entry.key)),
          throwsA(isA<CanonicalPsdkMoveProjectionException>()
              .having((e) => e.reason, 'reason', entry.value)));
    });
  }

  test('leaves existing DTO validation exceptions unwrapped', () {
    for (final invalid in [
      move.copyWith(pp: -1),
      move.copyWith(critRatio: -1),
      move.copyWith(accuracy: const PokemonMoveAccuracy.percent(value: 101))
    ]) {
      expect(() => projector.project(move: invalid), throwsRangeError);
    }
    for (final pp in [-1, 16]) {
      expect(
          () => projector.project(move: move, currentPp: pp), throwsRangeError);
    }
    expect(() => projector.project(move: move.copyWith(name: ' ')),
        throwsArgumentError);
    expect(projector.project(move: move.copyWith(pp: 0)).currentPp, 0);
  });

  final majorAliases = <String, PsdkBattleMajorStatus>{
    'par': PsdkBattleMajorStatus.paralysis,
    'paralysis': PsdkBattleMajorStatus.paralysis,
    'brn': PsdkBattleMajorStatus.burn,
    'burn': PsdkBattleMajorStatus.burn,
    'psn': PsdkBattleMajorStatus.poison,
    'poison': PsdkBattleMajorStatus.poison,
    'tox': PsdkBattleMajorStatus.toxic,
    'toxic': PsdkBattleMajorStatus.toxic,
    'slp': PsdkBattleMajorStatus.sleep,
    'sleep': PsdkBattleMajorStatus.sleep,
    'frz': PsdkBattleMajorStatus.freeze,
    'freeze': PsdkBattleMajorStatus.freeze,
  };
  test('preserves ordered status aliases and default or explicit chances', () {
    final result = projector.project(
        move: move.copyWith(effects: [
      for (final alias in majorAliases.keys)
        PokemonMoveEffect.applyStatus(
            statusId: ' ${alias.toUpperCase()} ', chance: 25),
      const PokemonMoveEffect.applyStatus(statusId: 'unknown'),
      const PokemonMoveEffect.applyStatus(statusId: 'brn'),
      const PokemonMoveEffect.applyVolatileStatus(
          volatileStatusId: ' CONFUSED ', chance: 30),
      const PokemonMoveEffect.applyVolatileStatus(
          volatileStatusId: 'confusion'),
      const PokemonMoveEffect.applyVolatileStatus(volatileStatusId: 'flinch'),
      const PokemonMoveEffect.applyVolatileStatus(volatileStatusId: 'protect'),
    ]));
    expect(result.statuses.take(majorAliases.length).map((s) => s.majorStatus),
        majorAliases.values);
    expect(result.statuses.take(majorAliases.length).map((s) => s.chance),
        everyElement(25));
    expect(result.statuses[majorAliases.length].chance, 100);
    expect(
        result.statuses
            .skip(majorAliases.length + 1)
            .map((s) => s.volatileStatus),
        [
          PsdkBattleVolatileStatus.confusion,
          PsdkBattleVolatileStatus.confusion,
          PsdkBattleVolatileStatus.flinch
        ]);
    expect(result.statuses.skip(majorAliases.length + 1).map((s) => s.chance),
        [30, 100, 100]);
    expect(() => result.statuses.clear(), throwsUnsupportedError);
  });

  test('leaves invalid recognized status chance to DTO validation', () {
    for (final chance in [0, 101]) {
      expect(
          () => projector.project(
                  move: move.copyWith(effects: [
                PokemonMoveEffect.applyStatus(statusId: 'brn', chance: chance),
              ])),
          throwsRangeError);
      expect(
          () => projector.project(
                  move: move.copyWith(effects: [
                PokemonMoveEffect.applyVolatileStatus(
                    volatileStatusId: 'flinch', chance: chance),
              ])),
          throwsRangeError);
    }
    expect(
        projector
            .project(
                move: move.copyWith(effects: [
              const PokemonMoveEffect.applyStatus(
                  statusId: 'unknown', chance: 0),
            ]))
            .statuses,
        isEmpty);
  });

  test('preserves stage order, scopes, names, values and nullable chances', () {
    final result = projector.project(
        move: move.copyWith(effects: [
      PokemonMoveEffect.modifyStats(
          targetScope: PokemonMoveEffectTargetScope.self,
          stageChanges: [
            for (final stat in PokemonMoveStatId.values)
              PokemonMoveStatStageChange(stat: stat, stages: stat.index - 3)
          ]),
      const PokemonMoveEffect.heal(numerator: 1, denominator: 2),
      const PokemonMoveEffect.modifyStats(
          targetScope: PokemonMoveEffectTargetScope.field,
          chance: 17,
          stageChanges: [
            PokemonMoveStatStageChange(
                stat: PokemonMoveStatId.attack, stages: 2)
          ]),
    ]));
    expect(result.stageMods.map((m) => m.stat), [
      'attack',
      'defense',
      'specialAttack',
      'specialDefense',
      'speed',
      'accuracy',
      'evasion',
      'attack'
    ]);
    expect(result.stageMods.map((m) => m.stages), [-3, -2, -1, 0, 1, 2, 3, 2]);
    expect(result.stageMods.map((m) => m.chance),
        [null, null, null, null, null, null, null, 17]);
    expect(() => result.stageMods.clear(), throwsUnsupportedError);
  });
}
