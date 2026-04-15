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
        'rejects a move whose non-neutral crit ratio would still be lost by the current battle engine',
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
              contains('moveId=razor_leaf'),
              contains('bridgeLimit=unsupported_crit_ratio:2'),
            ),
          ),
        ),
      );
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

    test('rejects a status move that needs a real battle status system', () {
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
              contains('moveId=thunder_wave'),
              contains('engineSupportLevel=structuredSupported'),
              contains('bridgeLimit=unsupported_effect_kind:apply_status'),
            ),
          ),
        ),
      );
    });

    test('rejects a probabilistic secondary effect that would lie without RNG',
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
              contains('moveId=thunderbolt'),
              contains('bridgeLimit=unsupported_effect_kind:apply_status'),
            ),
          ),
        ),
      );
    });

    test(
        'still rejects unsupported effect families even when accuracy is now bridgeable',
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
            contains('bridgeLimit=unsupported_effect_kind:apply_status'),
          ),
        ),
      );
    });
  });
}
