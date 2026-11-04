import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/src/presentation/flame/battle_gen5_source_emitter.dart';
import 'package:map_runtime/src/presentation/flame/battle_spl_configured_emitter.dart';
import 'package:map_runtime/src/presentation/flame/battle_spl_particle_pool.dart';
import 'package:map_runtime/src/presentation/flame/battle_spl_random.dart';

void main() {
  for (final scenario in [
    (id: 'fissure', group: 261, emitter: 0),
    (id: 'substitute', group: 334, emitter: 0),
    (id: 'fusion-bolt', group: 737, emitter: 1),
    (id: 'trick', group: 441, emitter: 0),
    (id: 'switcheroo', group: 594, emitter: 0),
  ]) {
    test('${scenario.id} source bounce changes its particle trajectories', () async {
      final bundle = jsonDecode(
        await File('assets/bw2/batch/${scenario.id}.json').readAsString(),
      ) as Map<String, dynamic>;
      final groups = bundle['particleGroups'] as Map<String, dynamic>?;
      final group = groups == null
          ? bundle
          : groups['${scenario.group}'] as Map<String, dynamic>;
      final indices = (group['sourceEmitterIndices'] as List).cast<int>();
      final index = indices.indexOf(scenario.emitter);
      expect(index, greaterThanOrEqualTo(0));
      final program = bundle['program'] as Map;
      final instructions = (program['instructions'] as List).skip(program['entryIndex'] as int);
      final instruction = instructions.cast<Map>().firstWhere((entry) {
        final args = entry['args'];
        return args is Map && args['particle'] == scenario.group &&
            args['emitter'] == scenario.emitter &&
            {'startEmitter', 'startFieldEmitter'}.contains(entry['op']);
      });
      final args = (instruction['args'] as Map).cast<String, dynamic>();
      final position = args.containsKey('fromX')
          ? gen5SourceFieldEmitterOffset(args)
          : (x: 0, y: args['offsetY'] as int, z: 0);

      BattleSplConfiguredEmitter make({required bool bounce}) {
        final raw = jsonDecode(jsonEncode(group['definition'])) as Map<String, dynamic>;
        final source = (raw['emitters'] as List)[index] as Map;
        applyGen5SourceEmitterParameters(source, args, orthographic: false);
        if (!bounce) (source['motion'] as Map).remove('collisionPlane');
        final definition = BattleSplParticleDefinition.fromExperimentalJson(raw);
        final textures = definition.textureIds.toList()..sort();
        return BattleSplConfiguredEmitter(
          definition: definition.emitters[index],
          textureIndices: {for (var i = 0; i < textures.length; i++) textures[i]: i},
          random: BattleSplRandom(seed: 0),
          pool: BattleSplParticlePool(capacity: 256),
        );
      }

      final original = make(bounce: true);
      final withoutBounce = make(bounce: false);
      var difference = false;
      for (var tick = 0; tick < 300; tick++) {
        original.step(managerFrame: tick & 1, position: position);
        withoutBounce.step(managerFrame: tick & 1, position: position);
        final unaffected = {for (final p in withoutBounce.playback.particles) p.id: p};
        for (final particle in original.playback.particles) {
          final other = unaffected[particle.id];
          if (other != null && (particle.motion.position != other.motion.position ||
              particle.motion.velocity != other.motion.velocity)) {
            difference = true;
            break;
          }
        }
        if (difference || original.playback.isComplete) break;
      }
      original.cancel();
      withoutBounce.cancel();
      expect(difference, isTrue);
    });
  }
}
