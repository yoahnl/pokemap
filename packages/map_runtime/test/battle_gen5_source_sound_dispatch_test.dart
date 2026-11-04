import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_battle/map_battle.dart';
import 'package:map_runtime/src/presentation/flame/battle_animation_plan.dart';
import 'package:map_runtime/src/presentation/flame/battle_gen5_source_program_playback.dart';
import 'package:map_runtime/src/presentation/flame/battle_overlay_component.dart';

import 'support/load_flame_component.dart';

Map<String, dynamic> _instruction(
  String op, [
  Map<String, dynamic> args = const {},
]) => {
  'op': op,
  'args': args,
  'source': {'index': 0, 'line': 1, 'name': op, 'operands': <String>[]},
};

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'dispatches BW2 sound commands after their scheduled frame delay',
    () async {
      const pokemon = BattleCombatantData(
        speciesId: 'totodile',
        level: 7,
        maxHp: 25,
        currentHp: 25,
        stats: BattleStatsSnapshot(
          attack: 20,
          defense: 20,
          specialAttack: 20,
          specialDefense: 20,
          speed: 20,
        ),
        moves: [BattleMoveData(id: 'tackle', name: 'Charge', power: 40)],
      );
      final overlay = BattleOverlayComponent(
        session: createBattleSession(
          BattleSetup.pokeMapBetaV1ForTest(
            playerPokemon: pokemon,
            enemyPokemon: pokemon,
            isTrainerBattle: false,
            trainerId: null,
          ),
        ),
        viewportSize: Vector2(390, 844),
        onPlayerChoice: (_) {},
        introEnabled: false,
      );
      await loadFlameComponent(overlay);
      await overlay.waitForPendingVisualSync();
      overlay.presentPostBattlePlan(const BattleAnimationPlan(steps: []));
      addTearDown(overlay.onRemove);
      final program = <String, dynamic>{
        'kind': 'gen5SourceProgram',
        'timebaseHz': 60,
        'source': {'path': 'test.s'},
        'variants': ['Attack'],
        'labels': [
          {'name': 'Attack', 'instructionIndex': 0, 'line': 1},
        ],
        'variant': 'Attack',
        'entryIndex': 0,
        'conversion': 'supported',
        'instructions': [
          _instruction('waitFrames', {'frames': 3}),
          _instruction('setYield', {'value': false}),
          _instruction('playSound', {'se': 'slow', 'wait': 4}),
          _instruction('playSound', {'se': 'fast', 'wait': 2}),
          _instruction('playSound', {'se': 'immediate', 'wait': 0}),
          _instruction('setYield', {'value': true}),
          _instruction('waitFrames', {'frames': 8}),
          _instruction('end'),
        ],
      };
      final calls = <(String, int)>[];
      var tick = 0;
      final finished = overlay.presentExperimentalGen5Attack(
        program: program,
        variant: 'Attack',
        hasEmitter: (_, _) => false,
        startEmitter: (_, _, _) {},
        particlesBusy: () => false,
        detachParticles: () {},
        allowSilentAudio: true,
        onSourceSound: (args) => calls.add((args['se'] as String, tick)),
      );
      for (tick = 0; tick < 80 && overlay.isTurnPresentationActive; tick++) {
        overlay.updateTree(1 / 60);
        await Future<void>.delayed(Duration.zero);
      }
      expect(await finished, BattleGen5SourcePlaybackStatus.finished);
      expect(calls.map((value) => value.$1), ['immediate', 'fast', 'slow']);
      expect(calls[1].$2 - calls[0].$2, 2);
      expect(calls[2].$2 - calls[0].$2, 4);

      calls.clear();
      final cancelled = overlay.presentExperimentalGen5Attack(
        program: {
          ...program,
          'instructions': [
            _instruction('playSound', {'se': 'cancelled', 'wait': 5}),
            _instruction('waitFrames', {'frames': 20}),
            _instruction('end'),
          ],
        },
        variant: 'Attack',
        hasEmitter: (_, _) => false,
        startEmitter: (_, _, _) {},
        particlesBusy: () => false,
        detachParticles: () {},
        allowSilentAudio: true,
        onSourceSound: (args) => calls.add((args['se'] as String, tick)),
      );
      overlay.updateTree(1 / 60);
      overlay.cancelExperimentalGen5Attack();
      for (var frame = 0; frame < 10; frame++) {
        overlay.updateTree(1 / 60);
      }
      expect(await cancelled, BattleGen5SourcePlaybackStatus.cancelled);
      expect(calls, isEmpty);

      final cries = <(String, int)>[];
      final criesFinished = overlay.presentExperimentalGen5Attack(
        program: {
          ...program,
          'instructions': [
            _instruction('setYield', {'value': false}),
            _instruction('playCry', {'targets': 'EFFVM_DEFENDER', 'delay': 3}),
            _instruction('playCry', {'targets': 'EFFVM_ATTACKER', 'delay': 0}),
            _instruction('setYield', {'value': true}),
            _instruction('waitFrames', {'frames': 8}),
            _instruction('end'),
          ],
        },
        variant: 'Attack',
        hasEmitter: (_, _) => false,
        startEmitter: (_, _, _) {},
        particlesBusy: () => false,
        detachParticles: () {},
        allowSilentAudio: true,
        onSourceCry: (args) => cries.add((args['targets'] as String, tick)),
      );
      for (tick = 0; tick < 80 && overlay.isTurnPresentationActive; tick++) {
        overlay.updateTree(1 / 60);
        await Future<void>.delayed(Duration.zero);
      }
      expect(await criesFinished, BattleGen5SourcePlaybackStatus.finished);
      expect(cries.map((value) => value.$1), [
        'EFFVM_ATTACKER',
        'EFFVM_DEFENDER',
      ]);
      expect(cries[1].$2 - cries[0].$2, 3);

      cries.clear();
      final criesWaited = overlay.presentExperimentalGen5Attack(
        program: {
          ...program,
          'instructions': [
            _instruction('playCry', {'targets': 'EFFVM_ATTACKER', 'delay': 5}),
            _instruction('waitTasks', {'what': 'CRY'}),
            _instruction('end'),
          ],
        },
        variant: 'Attack',
        hasEmitter: (_, _) => false,
        startEmitter: (_, _, _) {},
        particlesBusy: () => false,
        detachParticles: () {},
        allowSilentAudio: true,
        onSourceCry: (args) => cries.add((args['targets'] as String, tick)),
      );
      for (tick = 0; tick < 80 && overlay.isTurnPresentationActive; tick++) {
        overlay.updateTree(1 / 60);
        await Future<void>.delayed(Duration.zero);
      }
      expect(await criesWaited, BattleGen5SourcePlaybackStatus.finished);
      expect(cries.map((value) => value.$1), ['EFFVM_ATTACKER']);

      cries.clear();
      final criesCancelled = overlay.presentExperimentalGen5Attack(
        program: {
          ...program,
          'instructions': [
            _instruction('playCry', {'targets': 'EFFVM_ATTACKER', 'delay': 5}),
            _instruction('waitFrames', {'frames': 20}),
            _instruction('end'),
          ],
        },
        variant: 'Attack',
        hasEmitter: (_, _) => false,
        startEmitter: (_, _, _) {},
        particlesBusy: () => false,
        detachParticles: () {},
        allowSilentAudio: true,
        onSourceCry: (args) => cries.add((args['targets'] as String, tick)),
      );
      overlay.updateTree(1 / 60);
      overlay.cancelExperimentalGen5Attack();
      for (var frame = 0; frame < 10; frame++) {
        overlay.updateTree(1 / 60);
      }
      expect(await criesCancelled, BattleGen5SourcePlaybackStatus.cancelled);
      expect(cries, isEmpty);
    },
  );
}
