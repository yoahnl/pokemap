import 'package:flutter_test/flutter_test.dart';
import 'package:map_battle/map_battle.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/src/application/runtime_battle_move_bridge.dart';
import 'package:map_runtime/src/application/runtime_battle_setup_exception.dart';

void main() {
  group('RuntimeBattleMoveBridge', () {
    const bridge = RuntimeBattleMoveBridge();

    test('projects a standard damage move without destroying canonical data',
        () {
      const move = PokemonMove(
        id: 'vine_whip',
        name: 'Vine Whip',
        names: <String, String>{'en': 'Vine Whip'},
        generation: 1,
        source: 'test',
        type: 'grass',
        category: PokemonMoveCategory.physical,
        target: PokemonMoveTarget.normal,
        basePower: 45,
        accuracy: PokemonMoveAccuracy.percent(value: 100),
        pp: 25,
        engineSupportLevel: PokemonMoveEngineSupportLevel.structuredSupported,
      );

      final battleMove = bridge.toBattleMoveData(
        move: move,
        combatantLabel: 'Le Pokémon actif du joueur',
      );

      expect(battleMove.id, equals('vine_whip'));
      expect(battleMove.power, equals(45));
      expect(battleMove.type, equals('grass'));
      expect(battleMove.category, equals(BattleMoveCategory.physical));
      expect(battleMove.target, equals(BattleMoveTarget.opponent));
      expect(
        battleMove.accuracy.kind,
        equals(BattleMoveAccuracyKind.percent),
      );
      expect(battleMove.accuracy.value, equals(100));
      expect(battleMove.pp, equals(25));
      expect(battleMove.selfStatStageChanges, isEmpty);
      expect(battleMove.targetStatStageChanges, isEmpty);
    });

    test('inspectMove reports a standard damage move as bridgeable', () {
      const move = PokemonMove(
        id: 'vine_whip',
        name: 'Vine Whip',
        names: <String, String>{'en': 'Vine Whip'},
        generation: 1,
        source: 'test',
        type: 'grass',
        category: PokemonMoveCategory.physical,
        target: PokemonMoveTarget.normal,
        basePower: 45,
        accuracy: PokemonMoveAccuracy.percent(value: 100),
        pp: 25,
        engineSupportLevel: PokemonMoveEngineSupportLevel.structuredSupported,
      );

      final diagnostic = bridge.inspectMove(
        move: move,
        combatantLabel: 'Le Pokémon actif du joueur',
      );

      expect(diagnostic.bridgeable, isTrue);
      expect(diagnostic.reason, equals('bridgeable'));
      expect(diagnostic.runtimeBridgeable, isTrue);
      expect(diagnostic.psdkRegistered, isTrue);
      expect(diagnostic.psdkPartial, isTrue);
      expect(
        diagnostic.engineSupportLevel,
        equals(PokemonMoveEngineSupportLevel.structuredSupported),
      );
      expect(diagnostic.battleEngineMethod, equals('s_basic'));
      expect(diagnostic.psdkRegistryStatus, equals('partial'));
    });

    test('inspectMove reports Transform as bridgeable with PSDK metadata', () {
      const move = PokemonMove(
        id: 'transform',
        name: 'Transform',
        names: <String, String>{'en': 'Transform'},
        generation: 1,
        source: 'test',
        type: 'normal',
        category: PokemonMoveCategory.status,
        target: PokemonMoveTarget.normal,
        basePower: 0,
        accuracy: PokemonMoveAccuracy.alwaysHits(),
        pp: 10,
        engineSupportLevel: PokemonMoveEngineSupportLevel.catalogOnly,
        unsupportedReasons: <String>['psdk_method:s_transform'],
      );

      final diagnostic = bridge.inspectMove(
        move: move,
        combatantLabel: 'Le Pokémon actif du joueur',
      );

      expect(diagnostic.bridgeable, isTrue);
      expect(diagnostic.reason, equals('bridgeable'));
      expect(diagnostic.psdkRegistered, isTrue);
      expect(diagnostic.psdkPartial, isTrue);
      expect(
        diagnostic.engineSupportLevel,
        equals(PokemonMoveEngineSupportLevel.catalogOnly),
      );
      expect(diagnostic.battleEngineMethod, equals('s_transform'));
      expect(diagnostic.psdkRegistryStatus, equals('partial'));
    });

    test('inspectMove reports Baton Pass as not bridgeable without throwing',
        () {
      const move = PokemonMove(
        id: 'baton_pass',
        name: 'Baton Pass',
        names: <String, String>{'en': 'Baton Pass'},
        generation: 2,
        source: 'test',
        type: 'normal',
        category: PokemonMoveCategory.status,
        target: PokemonMoveTarget.self,
        basePower: 0,
        accuracy: PokemonMoveAccuracy.alwaysHits(),
        pp: 40,
        effects: <PokemonMoveEffect>[
          PokemonMoveEffect.selfSwitch(),
        ],
        engineSupportLevel: PokemonMoveEngineSupportLevel.structuredSupported,
      );

      final diagnostic = bridge.inspectMove(
        move: move,
        combatantLabel: 'Le Pokémon actif du joueur',
      );

      expect(diagnostic.bridgeable, isFalse);
      expect(diagnostic.runtimeBridgeable, isFalse);
      expect(diagnostic.psdkRegistered, isTrue);
      expect(diagnostic.psdkPartial, isTrue);
      expect(diagnostic.reason, equals('unsupported_effect_kind:self_switch'));
      expect(
        diagnostic.engineSupportLevel,
        equals(PokemonMoveEngineSupportLevel.structuredSupported),
      );
      expect(diagnostic.battleEngineMethod, equals('s_baton_pass'));
      expect(diagnostic.psdkRegistryStatus, equals('partial'));
      expect(
        diagnostic.debugDetails,
        contains('bridgeLimit=unsupported_effect_kind:self_switch'),
      );
    });

    test('projects target any as the active foe in the local singles slice',
        () {
      const move = PokemonMove(
        id: 'aura_sphere',
        name: 'Aura Sphere',
        names: <String, String>{'en': 'Aura Sphere'},
        generation: 4,
        source: 'test',
        type: 'fighting',
        category: PokemonMoveCategory.special,
        target: PokemonMoveTarget.any,
        basePower: 80,
        accuracy: PokemonMoveAccuracy.alwaysHits(),
        pp: 20,
        engineSupportLevel: PokemonMoveEngineSupportLevel.structuredSupported,
      );

      final battleMove = bridge.toBattleMoveData(
        move: move,
        combatantLabel: 'Le Pokémon actif du joueur',
      );

      expect(battleMove.id, equals('aura_sphere'));
      expect(battleMove.target, equals(BattleMoveTarget.opponent));
    });

    test(
        'keeps Water Pulse bridgeable while dropping unsupported confusion rider',
        () {
      const move = PokemonMove(
        id: 'water_pulse',
        name: 'Water Pulse',
        names: <String, String>{'en': 'Water Pulse'},
        generation: 3,
        source: 'test',
        type: 'water',
        category: PokemonMoveCategory.special,
        target: PokemonMoveTarget.any,
        basePower: 60,
        accuracy: PokemonMoveAccuracy.percent(value: 100),
        pp: 20,
        effects: <PokemonMoveEffect>[
          PokemonMoveEffect.applyVolatileStatus(
            targetScope: PokemonMoveEffectTargetScope.target,
            chance: 20,
            volatileStatusId: 'confusion',
          ),
        ],
        engineSupportLevel: PokemonMoveEngineSupportLevel.structuredSupported,
      );

      final battleMove = bridge.toBattleMoveData(
        move: move,
        combatantLabel: 'Le Pokémon actif du joueur',
      );

      expect(battleMove.id, equals('water_pulse'));
      expect(battleMove.power, equals(60));
      expect(battleMove.target, equals(BattleMoveTarget.opponent));
    });

    test('projects a deterministic target stat drop move honestly', () {
      const move = PokemonMove(
        id: 'growl',
        name: 'Growl',
        names: <String, String>{'en': 'Growl'},
        generation: 1,
        source: 'test',
        type: 'normal',
        category: PokemonMoveCategory.status,
        target: PokemonMoveTarget.allAdjacentFoes,
        basePower: 0,
        accuracy: PokemonMoveAccuracy.percent(value: 100),
        pp: 40,
        effects: <PokemonMoveEffect>[
          PokemonMoveEffect.modifyStats(
            targetScope: PokemonMoveEffectTargetScope.target,
            stageChanges: <PokemonMoveStatStageChange>[
              PokemonMoveStatStageChange(
                stat: PokemonMoveStatId.attack,
                stages: -1,
              ),
            ],
          ),
        ],
        engineSupportLevel: PokemonMoveEngineSupportLevel.structuredSupported,
      );

      final battleMove = bridge.toBattleMoveData(
        move: move,
        combatantLabel: 'Le Pokémon actif du joueur',
      );

      expect(battleMove.power, equals(0));
      expect(battleMove.type, equals('normal'));
      expect(battleMove.category, equals(BattleMoveCategory.status));
      expect(battleMove.target, equals(BattleMoveTarget.opponent));
      expect(battleMove.pp, equals(40));
      expect(battleMove.selfStatStageChanges, isEmpty);
      expect(battleMove.targetStatStageChanges, hasLength(1));
      expect(
        battleMove.targetStatStageChanges.single.stat,
        equals(BattleStatId.attack),
      );
      expect(
        battleMove.targetStatStageChanges.single.stages,
        equals(-1),
      );
    });

    test('projects a deterministic self stat boost move honestly', () {
      const move = PokemonMove(
        id: 'swords_dance',
        name: 'Swords Dance',
        names: <String, String>{'en': 'Swords Dance'},
        generation: 1,
        source: 'test',
        type: 'normal',
        category: PokemonMoveCategory.status,
        target: PokemonMoveTarget.self,
        basePower: 0,
        accuracy: PokemonMoveAccuracy.alwaysHits(),
        pp: 20,
        effects: <PokemonMoveEffect>[
          PokemonMoveEffect.modifyStats(
            targetScope: PokemonMoveEffectTargetScope.self,
            stageChanges: <PokemonMoveStatStageChange>[
              PokemonMoveStatStageChange(
                stat: PokemonMoveStatId.attack,
                stages: 2,
              ),
            ],
          ),
        ],
        engineSupportLevel: PokemonMoveEngineSupportLevel.structuredSupported,
      );

      final battleMove = bridge.toBattleMoveData(
        move: move,
        combatantLabel: 'Le Pokémon actif du joueur',
      );

      expect(battleMove.power, equals(0));
      expect(battleMove.selfStatStageChanges, hasLength(1));
      expect(
        battleMove.selfStatStageChanges.single.stat,
        equals(BattleStatId.attack),
      );
      expect(
        battleMove.selfStatStageChanges.single.stages,
        equals(2),
      );
      expect(battleMove.target, equals(BattleMoveTarget.self));
      expect(battleMove.pp, equals(20));
      expect(battleMove.targetStatStageChanges, isEmpty);
    });

    test(
        'accepts a zMove-only partial label when the underlying move is just a deterministic self stat boost already supported by battle',
        () {
      const move = PokemonMove(
        id: 'withdraw',
        name: 'Withdraw',
        names: <String, String>{'en': 'Withdraw'},
        generation: 1,
        source: 'test',
        type: 'water',
        category: PokemonMoveCategory.status,
        target: PokemonMoveTarget.self,
        basePower: 0,
        accuracy: PokemonMoveAccuracy.alwaysHits(),
        pp: 40,
        effects: <PokemonMoveEffect>[
          PokemonMoveEffect.modifyStats(
            targetScope: PokemonMoveEffectTargetScope.self,
            stageChanges: <PokemonMoveStatStageChange>[
              PokemonMoveStatStageChange(
                stat: PokemonMoveStatId.defense,
                stages: 1,
              ),
            ],
          ),
        ],
        // Mini-lot starter coverage :
        // - certains catalogues déjà convertis portent encore ce partial à
        //   cause de la seule métadonnée Showdown `zMove` ;
        // - on veut prouver ici que le bridge ne rouvre pas "les partials"
        //   en général, mais seulement ce cas legacy déjà exécutable.
        engineSupportLevel: PokemonMoveEngineSupportLevel.structuredPartial,
        unsupportedReasons: <String>['unsupported_mechanic:zMove'],
      );

      final battleMove = bridge.toBattleMoveData(
        move: move,
        combatantLabel: 'Le Pokémon actif du joueur',
      );

      expect(battleMove.id, equals('withdraw'));
      expect(battleMove.target, equals(BattleMoveTarget.self));
      expect(battleMove.selfStatStageChanges, hasLength(1));
      expect(
        battleMove.selfStatStageChanges.single.stat,
        equals(BattleStatId.defense),
      );
      expect(
        battleMove.selfStatStageChanges.single.stages,
        equals(1),
      );
    });

    test(
        'projects Bubble honestly once the only remaining partial reason is a supported probabilistic speed-drop rider',
        () {
      const move = PokemonMove(
        id: 'bubble',
        name: 'Bubble',
        names: <String, String>{'en': 'Bubble'},
        generation: 1,
        source: 'test',
        type: 'water',
        category: PokemonMoveCategory.special,
        target: PokemonMoveTarget.allAdjacentFoes,
        basePower: 40,
        accuracy: PokemonMoveAccuracy.percent(value: 100),
        pp: 30,
        effects: <PokemonMoveEffect>[
          PokemonMoveEffect.modifyStats(
            targetScope: PokemonMoveEffectTargetScope.target,
            chance: 10,
            stageChanges: <PokemonMoveStatStageChange>[
              PokemonMoveStatStageChange(
                stat: PokemonMoveStatId.speed,
                stages: -1,
              ),
            ],
          ),
        ],
        engineSupportLevel: PokemonMoveEngineSupportLevel.structuredPartial,
        unsupportedReasons: <String>[
          'unsupported_mechanic:probabilistic_modify_stats',
        ],
      );

      final battleMove = bridge.toBattleMoveData(
        move: move,
        combatantLabel: 'Le Pokémon actif du joueur',
      );

      expect(battleMove.id, equals('bubble'));
      expect(battleMove.name, equals('Bubble'));
      expect(battleMove.type, equals('water'));
      expect(battleMove.category, equals(BattleMoveCategory.special));
      expect(battleMove.power, equals(40));
      expect(battleMove.target, equals(BattleMoveTarget.opponent));
      expect(
        battleMove.accuracy.kind,
        equals(BattleMoveAccuracyKind.percent),
      );
      expect(battleMove.accuracy.value, equals(100));
      expect(battleMove.pp, equals(30));
      expect(battleMove.selfStatStageChanges, isEmpty);
      expect(battleMove.targetStatStageChanges, isEmpty);
      expect(battleMove.targetStatStageRider, isNotNull);
      expect(
        battleMove.targetStatStageRider!.chancePercent,
        equals(10),
      );
      expect(
        battleMove.targetStatStageRider!.changes.single.stat,
        equals(BattleStatId.speed),
      );
      expect(
        battleMove.targetStatStageRider!.changes.single.stages,
        equals(-1),
      );
    });

    test('projects Transform as an executable target-copy move', () {
      const move = PokemonMove(
        id: 'transform',
        name: 'Transform',
        names: <String, String>{'en': 'Transform'},
        generation: 1,
        source: 'test',
        type: 'normal',
        category: PokemonMoveCategory.status,
        target: PokemonMoveTarget.normal,
        basePower: 0,
        accuracy: PokemonMoveAccuracy.alwaysHits(),
        pp: 10,
        engineSupportLevel: PokemonMoveEngineSupportLevel.catalogOnly,
        unsupportedReasons: <String>['psdk_method:s_transform'],
      );

      final battleMove = bridge.toBattleMoveData(
        move: move,
        combatantLabel: 'Le Pokémon actif du joueur',
      );

      expect(battleMove.id, equals('transform'));
      expect(battleMove.power, equals(0));
      expect(battleMove.type, equals('normal'));
      expect(battleMove.category, equals(BattleMoveCategory.status));
      expect(battleMove.target, equals(BattleMoveTarget.opponent));
      expect(
        battleMove.accuracy.kind,
        equals(BattleMoveAccuracyKind.alwaysHits),
      );
      expect(battleMove.pp, equals(10));
      expect(battleMove.copiesTargetOnHit, isTrue);
    });

    test(
        'still rejects a probabilistic stat rider move when another real unsupported reason remains',
        () {
      const move = PokemonMove(
        id: 'bubble_plus_terrain',
        name: 'Bubble Plus Terrain',
        names: <String, String>{'en': 'Bubble Plus Terrain'},
        generation: 1,
        source: 'test',
        type: 'water',
        category: PokemonMoveCategory.special,
        target: PokemonMoveTarget.allAdjacentFoes,
        basePower: 40,
        accuracy: PokemonMoveAccuracy.percent(value: 100),
        pp: 30,
        effects: <PokemonMoveEffect>[
          PokemonMoveEffect.modifyStats(
            targetScope: PokemonMoveEffectTargetScope.target,
            chance: 10,
            stageChanges: <PokemonMoveStatStageChange>[
              PokemonMoveStatStageChange(
                stat: PokemonMoveStatId.speed,
                stages: -1,
              ),
            ],
          ),
        ],
        engineSupportLevel: PokemonMoveEngineSupportLevel.structuredPartial,
        unsupportedReasons: <String>[
          'unsupported_mechanic:probabilistic_modify_stats',
          'unsupported_effect_kind:set_terrain',
        ],
      );

      expect(
        () => bridge.toBattleMoveData(
          move: move,
          combatantLabel: 'Le Pokémon actif du joueur',
        ),
        throwsA(
          isA<RuntimeBattleSetupException>().having(
            (error) => error.debugDetails,
            'debugDetails',
            allOf(
              contains('moveId=bubble_plus_terrain'),
              contains('engineSupportLevel=structuredPartial'),
              contains('bridgeLimit=engine_support_level_not_bridgeable'),
            ),
          ),
        ),
      );
    });

    test(
        'rejects a self-target damage move that map_battle would still resolve against the opponent',
        () {
      const move = PokemonMove(
        id: 'mind_blown_self',
        name: 'Mind Blown Self',
        names: <String, String>{'en': 'Mind Blown Self'},
        generation: 9,
        source: 'test',
        type: 'fire',
        category: PokemonMoveCategory.special,
        target: PokemonMoveTarget.self,
        basePower: 50,
        accuracy: PokemonMoveAccuracy.percent(value: 100),
        pp: 5,
        engineSupportLevel: PokemonMoveEngineSupportLevel.structuredSupported,
      );

      expect(
        () => bridge.toBattleMoveData(
          move: move,
          combatantLabel: 'Le Pokémon actif du joueur',
        ),
        throwsA(
          isA<RuntimeBattleSetupException>().having(
            (error) => error.debugDetails,
            'debugDetails',
            allOf(
              contains('moveId=mind_blown_self'),
              contains('bridgeLimit=unsupported_standard_damage_target:self'),
            ),
          ),
        ),
      );
    });

    test(
        'projects a move with non-zero priority once battle order consumes it honestly',
        () {
      const move = PokemonMove(
        id: 'quick_attack',
        name: 'Quick Attack',
        names: <String, String>{'en': 'Quick Attack'},
        generation: 1,
        source: 'test',
        type: 'normal',
        category: PokemonMoveCategory.physical,
        target: PokemonMoveTarget.normal,
        basePower: 40,
        accuracy: PokemonMoveAccuracy.percent(value: 100),
        pp: 30,
        priority: 1,
        engineSupportLevel: PokemonMoveEngineSupportLevel.structuredSupported,
      );

      final battleMove = bridge.toBattleMoveData(
        move: move,
        combatantLabel: 'Le Pokémon actif du joueur',
      );

      expect(battleMove.id, equals('quick_attack'));
      expect(battleMove.priority, equals(1));
      expect(battleMove.power, equals(40));
      expect(battleMove.target, equals(BattleMoveTarget.opponent));
    });

    test('projects a deterministic speed boost move honestly', () {
      const move = PokemonMove(
        id: 'agility',
        name: 'Agility',
        names: <String, String>{'en': 'Agility'},
        generation: 1,
        source: 'test',
        type: 'psychic',
        category: PokemonMoveCategory.status,
        target: PokemonMoveTarget.self,
        basePower: 0,
        accuracy: PokemonMoveAccuracy.alwaysHits(),
        pp: 30,
        effects: <PokemonMoveEffect>[
          PokemonMoveEffect.modifyStats(
            targetScope: PokemonMoveEffectTargetScope.self,
            stageChanges: <PokemonMoveStatStageChange>[
              PokemonMoveStatStageChange(
                stat: PokemonMoveStatId.speed,
                stages: 2,
              ),
            ],
          ),
        ],
        engineSupportLevel: PokemonMoveEngineSupportLevel.structuredSupported,
      );

      final battleMove = bridge.toBattleMoveData(
        move: move,
        combatantLabel: 'Le Pokémon actif du joueur',
      );

      expect(battleMove.power, equals(0));
      expect(battleMove.target, equals(BattleMoveTarget.self));
      expect(battleMove.selfStatStageChanges, hasLength(1));
      expect(
        battleMove.selfStatStageChanges.single.stat,
        equals(BattleStatId.speed),
      );
      expect(
        battleMove.selfStatStageChanges.single.stages,
        equals(2),
      );
    });

    test(
        'projects a move with non-trivial percent accuracy once battle owns the hit check',
        () {
      const move = PokemonMove(
        id: 'fire_blast',
        name: 'Fire Blast',
        names: <String, String>{'en': 'Fire Blast'},
        generation: 1,
        source: 'test',
        type: 'fire',
        category: PokemonMoveCategory.special,
        target: PokemonMoveTarget.normal,
        basePower: 110,
        accuracy: PokemonMoveAccuracy.percent(value: 85),
        pp: 5,
        engineSupportLevel: PokemonMoveEngineSupportLevel.structuredSupported,
      );

      final battleMove = bridge.toBattleMoveData(
        move: move,
        combatantLabel: 'Le Pokémon actif du joueur',
      );

      expect(battleMove.id, equals('fire_blast'));
      expect(
        battleMove.accuracy.kind,
        equals(BattleMoveAccuracyKind.percent),
      );
      expect(battleMove.accuracy.value, equals(85));
      expect(battleMove.pp, equals(5));
    });

    test(
        'rejects a move whose type is not actually supported by the current battle type chart',
        () {
      const move = PokemonMove(
        id: 'typo_bolt',
        name: 'Typo Bolt',
        names: <String, String>{'en': 'Typo Bolt'},
        generation: 1,
        source: 'test',
        type: 'electrik',
        category: PokemonMoveCategory.special,
        target: PokemonMoveTarget.normal,
        basePower: 80,
        accuracy: PokemonMoveAccuracy.percent(value: 100),
        pp: 15,
        engineSupportLevel: PokemonMoveEngineSupportLevel.structuredSupported,
      );

      expect(
        () => bridge.toBattleMoveData(
          move: move,
          combatantLabel: 'Le Pokémon actif du joueur',
        ),
        throwsA(
          isA<RuntimeBattleSetupException>().having(
            (error) => error.debugDetails,
            'debugDetails',
            allOf(
              contains('moveId=typo_bolt'),
              contains('moveName=Typo Bolt'),
              contains('bridgeLimit=unsupported_type:electrik'),
            ),
          ),
        ),
      );
    });

    test(
        'accepts a move whose non-neutral crit ratio is now transported honestly to battle',
        () {
      const move = PokemonMove(
        id: 'razor_leaf',
        name: 'Razor Leaf',
        names: <String, String>{'en': 'Razor Leaf'},
        generation: 1,
        source: 'test',
        type: 'grass',
        category: PokemonMoveCategory.physical,
        target: PokemonMoveTarget.allAdjacentFoes,
        basePower: 55,
        accuracy: PokemonMoveAccuracy.percent(value: 100),
        pp: 25,
        critRatio: 2,
        engineSupportLevel: PokemonMoveEngineSupportLevel.structuredSupported,
      );

      final battleMove = bridge.toBattleMoveData(
        move: move,
        combatantLabel: 'Le Pokémon actif du joueur',
      );

      expect(battleMove.id, equals('razor_leaf'));
      expect(battleMove.critRatio, equals(2));
    });

    test(
        'rejects a target shape that is still outside the honest 1v1 bridge subset',
        () {
      const move = PokemonMove(
        id: 'stealth_rock',
        name: 'Stealth Rock',
        names: <String, String>{'en': 'Stealth Rock'},
        generation: 4,
        source: 'test',
        type: 'rock',
        category: PokemonMoveCategory.status,
        target: PokemonMoveTarget.foeSide,
        basePower: 0,
        accuracy: PokemonMoveAccuracy.alwaysHits(),
        pp: 20,
        engineSupportLevel: PokemonMoveEngineSupportLevel.structuredSupported,
      );

      expect(
        () => bridge.toBattleMoveData(
          move: move,
          combatantLabel: 'Le Pokémon actif du joueur',
        ),
        throwsA(
          isA<RuntimeBattleSetupException>().having(
            (error) => error.debugDetails,
            'debugDetails',
            allOf(
              contains('moveId=stealth_rock'),
              contains('bridgeLimit=unsupported_target:foeSide'),
            ),
          ),
        ),
      );
    });

    test('supports a deterministic major status move in the BE7 subset', () {
      const move = PokemonMove(
        id: 'thunder_wave',
        name: 'Thunder Wave',
        names: <String, String>{'en': 'Thunder Wave'},
        generation: 1,
        source: 'test',
        type: 'electric',
        category: PokemonMoveCategory.status,
        target: PokemonMoveTarget.normal,
        basePower: 0,
        accuracy: PokemonMoveAccuracy.percent(value: 100),
        pp: 20,
        effects: <PokemonMoveEffect>[
          PokemonMoveEffect.applyStatus(
            targetScope: PokemonMoveEffectTargetScope.target,
            statusId: 'par',
          ),
        ],
        engineSupportLevel: PokemonMoveEngineSupportLevel.structuredSupported,
      );

      final battleMove = bridge.toBattleMoveData(
        move: move,
        combatantLabel: 'Le Pokémon actif du joueur',
      );

      expect(battleMove.power, equals(0));
      expect(
        battleMove.majorStatusEffect?.status,
        equals(BattleMajorStatusId.par),
      );
      expect(battleMove.majorStatusEffect?.chancePercent, isNull);
    });

    test(
        'supports a probabilistic major status effect once battle owns the RNG',
        () {
      const move = PokemonMove(
        id: 'thunderbolt',
        name: 'Thunderbolt',
        names: <String, String>{'en': 'Thunderbolt'},
        generation: 1,
        source: 'test',
        type: 'electric',
        category: PokemonMoveCategory.special,
        target: PokemonMoveTarget.normal,
        basePower: 90,
        accuracy: PokemonMoveAccuracy.percent(value: 100),
        pp: 15,
        effects: <PokemonMoveEffect>[
          PokemonMoveEffect.applyStatus(
            targetScope: PokemonMoveEffectTargetScope.target,
            chance: 10,
            statusId: 'par',
          ),
        ],
        engineSupportLevel: PokemonMoveEngineSupportLevel.structuredSupported,
      );

      final battleMove = bridge.toBattleMoveData(
        move: move,
        combatantLabel: 'Le Pokémon actif du joueur',
      );

      expect(battleMove.power, equals(90));
      expect(
        battleMove.majorStatusEffect?.status,
        equals(BattleMajorStatusId.par),
      );
      expect(battleMove.majorStatusEffect?.chancePercent, equals(10));
    });

    test(
        'supports the exact protect volatile subset instead of reopening all applyVolatileStatus',
        () {
      const move = PokemonMove(
        id: 'protect',
        name: 'Protect',
        names: <String, String>{'en': 'Protect'},
        generation: 1,
        source: 'test',
        type: 'normal',
        category: PokemonMoveCategory.status,
        target: PokemonMoveTarget.self,
        basePower: 0,
        accuracy: PokemonMoveAccuracy.alwaysHits(),
        pp: 10,
        effects: <PokemonMoveEffect>[
          PokemonMoveEffect.applyVolatileStatus(
            targetScope: PokemonMoveEffectTargetScope.self,
            volatileStatusId: 'protect',
          ),
        ],
        engineSupportLevel: PokemonMoveEngineSupportLevel.structuredSupported,
      );

      final battleMove = bridge.toBattleMoveData(
        move: move,
        combatantLabel: 'Le Pokémon actif du joueur',
      );

      expect(battleMove.target, equals(BattleMoveTarget.self));
      expect(
        battleMove.selfVolatileStatus,
        equals(BattleVolatileStatusId.protect),
      );
    });

    test(
        'accepts old catalog-only Protect when its volatile effect is supported',
        () {
      const move = PokemonMove(
        id: 'protect',
        name: 'Protect',
        names: <String, String>{'en': 'Protect'},
        generation: 1,
        source: 'test',
        type: 'normal',
        category: PokemonMoveCategory.status,
        target: PokemonMoveTarget.self,
        basePower: 0,
        accuracy: PokemonMoveAccuracy.alwaysHits(),
        pp: 10,
        effects: <PokemonMoveEffect>[
          PokemonMoveEffect.applyVolatileStatus(
            targetScope: PokemonMoveEffectTargetScope.self,
            volatileStatusId: 'protect',
          ),
        ],
        engineSupportLevel: PokemonMoveEngineSupportLevel.catalogOnly,
        unsupportedReasons: <String>[
          'unsupported_mechanic:condition',
          'unsupported_mechanic:stallingMove',
        ],
      );

      final battleMove = bridge.toBattleMoveData(
        move: move,
        combatantLabel: 'Le Pokémon actif du joueur',
      );

      expect(battleMove.target, equals(BattleMoveTarget.self));
      expect(
        battleMove.selfVolatileStatus,
        equals(BattleVolatileStatusId.protect),
      );
    });

    test('supports a breakProtect damage move in the BE8 subset', () {
      const move = PokemonMove(
        id: 'feint',
        name: 'Feint',
        names: <String, String>{'en': 'Feint'},
        generation: 4,
        source: 'test',
        type: 'normal',
        category: PokemonMoveCategory.physical,
        target: PokemonMoveTarget.normal,
        basePower: 30,
        accuracy: PokemonMoveAccuracy.percent(value: 100),
        pp: 10,
        effects: <PokemonMoveEffect>[
          PokemonMoveEffect.breakProtect(),
        ],
        engineSupportLevel: PokemonMoveEngineSupportLevel.structuredSupported,
      );

      final battleMove = bridge.toBattleMoveData(
        move: move,
        combatantLabel: 'Le Pokémon actif du joueur',
      );

      expect(battleMove.breaksProtect, isTrue);
      expect(battleMove.target, equals(BattleMoveTarget.opponent));
    });

    test('supports a requireRecharge damage move in the BE8 subset', () {
      const move = PokemonMove(
        id: 'hyper_beam',
        name: 'Hyper Beam',
        names: <String, String>{'en': 'Hyper Beam'},
        generation: 1,
        source: 'test',
        type: 'normal',
        category: PokemonMoveCategory.special,
        target: PokemonMoveTarget.normal,
        basePower: 150,
        accuracy: PokemonMoveAccuracy.percent(value: 90),
        pp: 5,
        effects: <PokemonMoveEffect>[
          PokemonMoveEffect.requireRecharge(),
        ],
        engineSupportLevel: PokemonMoveEngineSupportLevel.structuredSupported,
      );

      final battleMove = bridge.toBattleMoveData(
        move: move,
        combatantLabel: 'Le Pokémon actif du joueur',
      );

      expect(battleMove.requiresRecharge, isTrue);
      expect(battleMove.power, equals(150));
    });

    test('supports a chargeThenStrike damage move in the BE8 subset', () {
      const move = PokemonMove(
        id: 'solar_beam',
        name: 'Solar Beam',
        names: <String, String>{'en': 'Solar Beam'},
        generation: 1,
        source: 'test',
        type: 'grass',
        category: PokemonMoveCategory.special,
        target: PokemonMoveTarget.normal,
        basePower: 120,
        accuracy: PokemonMoveAccuracy.percent(value: 100),
        pp: 10,
        effects: <PokemonMoveEffect>[
          PokemonMoveEffect.chargeThenStrike(chargeStateId: 'solar_charge'),
        ],
        engineSupportLevel: PokemonMoveEngineSupportLevel.structuredSupported,
      );

      final battleMove = bridge.toBattleMoveData(
        move: move,
        combatantLabel: 'Le Pokémon actif du joueur',
      );

      expect(
        battleMove.chargeThenStrikeEffect?.chargeStateId,
        equals('solar_charge'),
      );
      expect(battleMove.target, equals(BattleMoveTarget.opponent));
    });

    test(
        'still rejects a noncanonical move that combines chargeThenStrike and requireRecharge',
        () {
      const move = PokemonMove(
        id: 'bad_combo_beam',
        name: 'Bad Combo Beam',
        names: <String, String>{'en': 'Bad Combo Beam'},
        generation: 9,
        source: 'test',
        type: 'normal',
        category: PokemonMoveCategory.special,
        target: PokemonMoveTarget.normal,
        basePower: 120,
        accuracy: PokemonMoveAccuracy.percent(value: 100),
        pp: 5,
        effects: <PokemonMoveEffect>[
          PokemonMoveEffect.requireRecharge(),
          PokemonMoveEffect.chargeThenStrike(),
        ],
        engineSupportLevel: PokemonMoveEngineSupportLevel.structuredSupported,
      );

      expect(
        () => bridge.toBattleMoveData(
          move: move,
          combatantLabel: 'Le Pokémon actif du joueur',
        ),
        throwsA(
          isA<RuntimeBattleSetupException>().having(
            (error) => error.debugDetails,
            'debugDetails',
            contains(
              'bridgeLimit=unsupported_combined_charge_then_recharge',
            ),
          ),
        ),
      );
    });

    test(
        'still rejects unsupported major statuses even when applyStatus is now partially bridgeable',
        () {
      const move = PokemonMove(
        id: 'sleep_powder',
        name: 'Sleep Powder',
        names: <String, String>{'en': 'Sleep Powder'},
        generation: 1,
        source: 'test',
        type: 'grass',
        category: PokemonMoveCategory.status,
        target: PokemonMoveTarget.normal,
        basePower: 0,
        accuracy: PokemonMoveAccuracy.percent(value: 75),
        pp: 15,
        effects: <PokemonMoveEffect>[
          PokemonMoveEffect.applyStatus(
            targetScope: PokemonMoveEffectTargetScope.target,
            statusId: 'slp',
          ),
        ],
        engineSupportLevel: PokemonMoveEngineSupportLevel.structuredSupported,
      );

      expect(
        () => bridge.toBattleMoveData(
          move: move,
          combatantLabel: 'Le Pokémon actif du joueur',
        ),
        throwsA(
          isA<RuntimeBattleSetupException>().having(
            (error) => error.debugDetails,
            'debugDetails',
            contains('bridgeLimit=unsupported_major_status:slp'),
          ),
        ),
      );
    });

    test(
        'still rejects unsupported applyVolatileStatus outside the protect subset',
        () {
      const move = PokemonMove(
        id: 'confuse_ray',
        name: 'Confuse Ray',
        names: <String, String>{'en': 'Confuse Ray'},
        generation: 1,
        source: 'test',
        type: 'ghost',
        category: PokemonMoveCategory.status,
        target: PokemonMoveTarget.normal,
        basePower: 0,
        accuracy: PokemonMoveAccuracy.percent(value: 100),
        pp: 10,
        effects: <PokemonMoveEffect>[
          PokemonMoveEffect.applyVolatileStatus(
            targetScope: PokemonMoveEffectTargetScope.target,
            volatileStatusId: 'confusion',
          ),
        ],
        engineSupportLevel: PokemonMoveEngineSupportLevel.structuredSupported,
      );

      expect(
        () => bridge.toBattleMoveData(
          move: move,
          combatantLabel: 'Le Pokémon actif du joueur',
        ),
        throwsA(
          isA<RuntimeBattleSetupException>().having(
            (error) => error.debugDetails,
            'debugDetails',
            contains(
              'bridgeLimit=unsupported_apply_volatile_status_scope:target',
            ),
          ),
        ),
      );
    });

    test('supports the exact Rain Dance weather subset in BE9', () {
      const move = PokemonMove(
        id: 'rain_dance',
        name: 'Rain Dance',
        names: <String, String>{'en': 'Rain Dance'},
        generation: 2,
        source: 'test',
        type: 'water',
        category: PokemonMoveCategory.status,
        target: PokemonMoveTarget.all,
        basePower: 0,
        accuracy: PokemonMoveAccuracy.alwaysHits(),
        pp: 5,
        effects: <PokemonMoveEffect>[
          PokemonMoveEffect.setWeather(
            targetScope: PokemonMoveEffectTargetScope.field,
            weatherId: 'raindance',
          ),
        ],
        engineSupportLevel: PokemonMoveEngineSupportLevel.structuredSupported,
      );

      final battleMove = bridge.toBattleMoveData(
        move: move,
        combatantLabel: 'Le Pokémon actif du joueur',
      );

      expect(battleMove.target, equals(BattleMoveTarget.field));
      expect(battleMove.weatherEffect, equals(BattleWeatherId.rain));
      expect(battleMove.pseudoWeatherEffect, isNull);
    });

    test(
        'rejects a malformed self-target field move instead of widening the BE9 field contract',
        () {
      const move = PokemonMove(
        id: 'bad_self_rain',
        name: 'Bad Self Rain',
        names: <String, String>{'en': 'Bad Self Rain'},
        generation: 9,
        source: 'test',
        type: 'water',
        category: PokemonMoveCategory.status,
        target: PokemonMoveTarget.self,
        basePower: 0,
        accuracy: PokemonMoveAccuracy.alwaysHits(),
        pp: 5,
        effects: <PokemonMoveEffect>[
          PokemonMoveEffect.setWeather(
            targetScope: PokemonMoveEffectTargetScope.field,
            weatherId: 'raindance',
          ),
        ],
        engineSupportLevel: PokemonMoveEngineSupportLevel.structuredSupported,
      );

      expect(
        () => bridge.toBattleMoveData(
          move: move,
          combatantLabel: 'Le Pokémon actif du joueur',
        ),
        throwsA(
          isA<RuntimeBattleSetupException>().having(
            (error) => error.debugDetails,
            'debugDetails',
            contains('bridgeLimit=unsupported_field_target:self'),
          ),
        ),
      );
    });

    test('supports the exact Sandstorm weather subset in BE9', () {
      const move = PokemonMove(
        id: 'sandstorm',
        name: 'Sandstorm',
        names: <String, String>{'en': 'Sandstorm'},
        generation: 2,
        source: 'test',
        type: 'rock',
        category: PokemonMoveCategory.status,
        target: PokemonMoveTarget.all,
        basePower: 0,
        accuracy: PokemonMoveAccuracy.alwaysHits(),
        pp: 10,
        effects: <PokemonMoveEffect>[
          PokemonMoveEffect.setWeather(
            targetScope: PokemonMoveEffectTargetScope.field,
            weatherId: 'sandstorm',
          ),
        ],
        engineSupportLevel: PokemonMoveEngineSupportLevel.structuredSupported,
      );

      final battleMove = bridge.toBattleMoveData(
        move: move,
        combatantLabel: 'Le Pokémon actif du joueur',
      );

      expect(battleMove.target, equals(BattleMoveTarget.field));
      expect(battleMove.weatherEffect, equals(BattleWeatherId.sandstorm));
    });

    test(
        'supports the exact Trick Room pseudoWeather subset without reopening all structuredPartial moves',
        () {
      const move = PokemonMove(
        id: 'trick_room',
        name: 'Trick Room',
        names: <String, String>{'en': 'Trick Room'},
        generation: 4,
        source: 'test',
        type: 'psychic',
        category: PokemonMoveCategory.status,
        target: PokemonMoveTarget.all,
        basePower: 0,
        accuracy: PokemonMoveAccuracy.alwaysHits(),
        pp: 5,
        priority: -7,
        effects: <PokemonMoveEffect>[
          PokemonMoveEffect.setPseudoWeather(
            targetScope: PokemonMoveEffectTargetScope.field,
            pseudoWeatherId: 'trickroom',
          ),
        ],
        engineSupportLevel: PokemonMoveEngineSupportLevel.structuredPartial,
        unsupportedReasons: <String>[
          'unsupported_mechanic:turn_order_inversion',
          'showdown_callback:condition.durationCallback',
          'showdown_callback:condition.onFieldEnd',
        ],
      );

      final battleMove = bridge.toBattleMoveData(
        move: move,
        combatantLabel: 'Le Pokémon actif du joueur',
      );

      expect(battleMove.target, equals(BattleMoveTarget.field));
      expect(
        battleMove.pseudoWeatherEffect,
        equals(BattlePseudoWeatherId.trickRoom),
      );
      expect(battleMove.priority, equals(-7));
    });

    test('still rejects unsupported weather ids outside the BE9 subset', () {
      const move = PokemonMove(
        id: 'sunny_day',
        name: 'Sunny Day',
        names: <String, String>{'en': 'Sunny Day'},
        generation: 2,
        source: 'test',
        type: 'fire',
        category: PokemonMoveCategory.status,
        target: PokemonMoveTarget.all,
        basePower: 0,
        accuracy: PokemonMoveAccuracy.alwaysHits(),
        pp: 5,
        effects: <PokemonMoveEffect>[
          PokemonMoveEffect.setWeather(
            targetScope: PokemonMoveEffectTargetScope.field,
            weatherId: 'sunnyday',
          ),
        ],
        engineSupportLevel: PokemonMoveEngineSupportLevel.structuredSupported,
      );

      expect(
        () => bridge.toBattleMoveData(
          move: move,
          combatantLabel: 'Le Pokémon actif du joueur',
        ),
        throwsA(
          isA<RuntimeBattleSetupException>().having(
            (error) => error.debugDetails,
            'debugDetails',
            contains('bridgeLimit=unsupported_weather:sunnyday'),
          ),
        ),
      );
    });

    test('still rejects unsupported pseudoWeather ids outside the BE9 subset',
        () {
      const move = PokemonMove(
        id: 'magic_room',
        name: 'Magic Room',
        names: <String, String>{'en': 'Magic Room'},
        generation: 5,
        source: 'test',
        type: 'psychic',
        category: PokemonMoveCategory.status,
        target: PokemonMoveTarget.all,
        basePower: 0,
        accuracy: PokemonMoveAccuracy.alwaysHits(),
        pp: 10,
        effects: <PokemonMoveEffect>[
          PokemonMoveEffect.setPseudoWeather(
            targetScope: PokemonMoveEffectTargetScope.field,
            pseudoWeatherId: 'magicroom',
          ),
        ],
        engineSupportLevel: PokemonMoveEngineSupportLevel.structuredSupported,
      );

      expect(
        () => bridge.toBattleMoveData(
          move: move,
          combatantLabel: 'Le Pokémon actif du joueur',
        ),
        throwsA(
          isA<RuntimeBattleSetupException>().having(
            (error) => error.debugDetails,
            'debugDetails',
            contains('bridgeLimit=unsupported_pseudo_weather:magicroom'),
          ),
        ),
      );
    });

    test('still rejects setTerrain because BE9 does not open terrains', () {
      const move = PokemonMove(
        id: 'electric_terrain',
        name: 'Electric Terrain',
        names: <String, String>{'en': 'Electric Terrain'},
        generation: 6,
        source: 'test',
        type: 'electric',
        category: PokemonMoveCategory.status,
        target: PokemonMoveTarget.all,
        basePower: 0,
        accuracy: PokemonMoveAccuracy.alwaysHits(),
        pp: 10,
        effects: <PokemonMoveEffect>[
          PokemonMoveEffect.setTerrain(
            targetScope: PokemonMoveEffectTargetScope.field,
            terrainId: 'electricterrain',
          ),
        ],
        engineSupportLevel: PokemonMoveEngineSupportLevel.structuredSupported,
      );

      expect(
        () => bridge.toBattleMoveData(
          move: move,
          combatantLabel: 'Le Pokémon actif du joueur',
        ),
        throwsA(
          isA<RuntimeBattleSetupException>().having(
            (error) => error.debugDetails,
            'debugDetails',
            anyOf(
              contains('bridgeLimit=unsupported_target:all'),
              contains('bridgeLimit=unsupported_effect_kind:set_terrain'),
            ),
          ),
        ),
      );
    });

    test('supports Stealth Rock as the first honest side-level hazard slice',
        () {
      const move = PokemonMove(
        id: 'stealth_rock',
        name: 'Stealth Rock',
        names: <String, String>{'en': 'Stealth Rock'},
        generation: 4,
        source: 'test',
        type: 'rock',
        category: PokemonMoveCategory.status,
        target: PokemonMoveTarget.foeSide,
        basePower: 0,
        accuracy: PokemonMoveAccuracy.alwaysHits(),
        pp: 20,
        effects: <PokemonMoveEffect>[
          PokemonMoveEffect.setSideCondition(
            targetScope: PokemonMoveEffectTargetScope.foeSide,
            conditionId: 'stealthrock',
          ),
        ],
        engineSupportLevel: PokemonMoveEngineSupportLevel.structuredSupported,
      );

      final battleMove = bridge.toBattleMoveData(
        move: move,
        combatantLabel: 'Le Pokémon actif du joueur',
      );

      expect(battleMove.target, equals(BattleMoveTarget.opponentSide));
      expect(battleMove.setsStealthRock, isTrue);
    });

    test('supports Spikes as the second honest side-level hazard slice', () {
      const move = PokemonMove(
        id: 'spikes',
        name: 'Spikes',
        names: <String, String>{'en': 'Spikes'},
        generation: 2,
        source: 'test',
        type: 'ground',
        category: PokemonMoveCategory.status,
        target: PokemonMoveTarget.foeSide,
        basePower: 0,
        accuracy: PokemonMoveAccuracy.alwaysHits(),
        pp: 20,
        effects: <PokemonMoveEffect>[
          PokemonMoveEffect.setSideCondition(
            targetScope: PokemonMoveEffectTargetScope.foeSide,
            conditionId: 'spikes',
          ),
        ],
        engineSupportLevel: PokemonMoveEngineSupportLevel.structuredSupported,
      );

      final battleMove = bridge.toBattleMoveData(
        move: move,
        combatantLabel: 'Le Pokémon actif du joueur',
      );

      expect(battleMove.target, equals(BattleMoveTarget.opponentSide));
      expect(battleMove.setsSpikes, isTrue);
    });

    test(
        'still rejects unsupported side conditions beyond Stealth Rock and Spikes',
        () {
      const move = PokemonMove(
        id: 'toxic_spikes',
        name: 'Toxic Spikes',
        names: <String, String>{'en': 'Toxic Spikes'},
        generation: 4,
        source: 'test',
        type: 'poison',
        category: PokemonMoveCategory.status,
        target: PokemonMoveTarget.foeSide,
        basePower: 0,
        accuracy: PokemonMoveAccuracy.alwaysHits(),
        pp: 20,
        effects: <PokemonMoveEffect>[
          PokemonMoveEffect.setSideCondition(
            targetScope: PokemonMoveEffectTargetScope.foeSide,
            conditionId: 'toxicspikes',
          ),
        ],
        engineSupportLevel: PokemonMoveEngineSupportLevel.structuredSupported,
      );

      expect(
        () => bridge.toBattleMoveData(
          move: move,
          combatantLabel: 'Le Pokémon actif du joueur',
        ),
        throwsA(
          isA<RuntimeBattleSetupException>().having(
            (error) => error.debugDetails,
            'debugDetails',
            contains('bridgeLimit=unsupported_side_condition:toxicspikes'),
          ),
        ),
      );
    });

    test('still rejects setSlotCondition because BE9 does not open slot state',
        () {
      const move = PokemonMove(
        id: 'healing_wish',
        name: 'Healing Wish',
        names: <String, String>{'en': 'Healing Wish'},
        generation: 4,
        source: 'test',
        type: 'psychic',
        category: PokemonMoveCategory.status,
        target: PokemonMoveTarget.self,
        basePower: 0,
        accuracy: PokemonMoveAccuracy.alwaysHits(),
        pp: 10,
        effects: <PokemonMoveEffect>[
          PokemonMoveEffect.setSlotCondition(
            targetScope: PokemonMoveEffectTargetScope.slot,
            conditionId: 'healingwish',
          ),
        ],
        engineSupportLevel: PokemonMoveEngineSupportLevel.structuredSupported,
      );

      expect(
        () => bridge.toBattleMoveData(
          move: move,
          combatantLabel: 'Le Pokémon actif du joueur',
        ),
        throwsA(
          isA<RuntimeBattleSetupException>().having(
            (error) => error.debugDetails,
            'debugDetails',
            anyOf(
              contains('bridgeLimit=unsupported_target:self'),
              contains(
                  'bridgeLimit=unsupported_effect_kind:set_slot_condition'),
              contains('bridgeLimit=unsupported_target:slot'),
            ),
          ),
        ),
      );
    });
  });
}
