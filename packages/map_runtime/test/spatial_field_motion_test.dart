import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/src/spatial/spatial_field_motion.dart';

void main() {
  test('one field motion keeps player and boulder at the same progress and holds its endpoint', () async {
    final motion = SpatialFieldMotion();
    final completed = motion.play(ability: FieldAbility.strength,
        from: PlayerSpatialPosition(x: 1.4, z: 2.6), to: PlayerSpatialPosition(x: 2.4, z: 2.6),
        durationMs: 250, modelInstanceId: 'rock', modelDeltaX: 1);
    motion.update(.1, paused: true);
    expect(motion.progress, 0);
    motion.update(.1);
    expect(motion.position!.x, closeTo(1.8, .000001));
    expect(motion.modelTranslation('rock')!.x, closeTo(.4, .000001));
    expect(motion.modelTranslation('other'), isNull);
    motion.update(.15);
    expect(await completed, isTrue);
    expect(motion.isActive, isTrue);
    expect(motion.position!.x, 2.4);
    expect(motion.state, CharacterAnimationState.push);
    expect(await motion.play(ability: FieldAbility.strength, from: PlayerSpatialPosition(x: 2.4, z: 2.6),
        to: PlayerSpatialPosition(x: 3.4, z: 2.6), durationMs: 250), isFalse);
    motion.release();
    expect(motion.isActive, isFalse);
    expect(motion.position, isNull);
  });

  test('cancellation, pause and invalid clock ticks never finish a partial traversal', () async {
    final motion = SpatialFieldMotion();
    for (final ability in [FieldAbility.waterfall, FieldAbility.whirlpool]) {
      final completed = motion.play(ability: ability,
          from: PlayerSpatialPosition(x: 1.5, z: 2.5), to: PlayerSpatialPosition(x: 1.5, z: 1.5), durationMs: 250);
      motion.update(double.nan);
      motion.update(-1);
      motion.update(.1);
      motion.update(5, paused: true);
      expect(motion.progress, closeTo(.4, .000001));
      motion.cancel();
      expect(await completed, isFalse);
      expect(motion.isActive, isFalse);
    }
    expect(() => motion.play(ability: FieldAbility.fly, from: PlayerSpatialPosition(x: 1, z: 1),
        to: PlayerSpatialPosition(x: 1, z: 2), durationMs: 250), throwsArgumentError);
  });
}
