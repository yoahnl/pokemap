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
    'dispatches BW2 sound commands when the source program reaches them',
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
          _instruction('playSound', {'se': 'first'}),
          _instruction('waitFrames', {'frames': 2}),
          _instruction('playSound', {'se': 'second'}),
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
      expect(calls.map((value) => value.$1), ['first', 'second']);
      expect(calls[1].$2, greaterThan(calls[0].$2));
    },
  );
}
