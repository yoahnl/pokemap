import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/src/spatial/spatial_field_action_presentation.dart';

void main() {
  test('field animation pauses and completes one native cycle once', () async {
    final action = SpatialFieldActionPresentation();
    final playing = action.play(FieldAbility.cut, durationMs: 160);
    expect(action.state, CharacterAnimationState.cut);
    action.update(.1, paused: true);
    expect(action.elapsedSeconds, 0);
    action.update(.1);
    expect(action.isActive, isTrue);
    expect(await action.play(FieldAbility.rockSmash, durationMs: 100), isFalse);
    action.update(.06);
    expect(await playing, isTrue);
    expect(action.state, isNull);
    expect(action.isActive, isFalse);
  });

  test(
    'cancelled actions complete without an impact and can be restarted',
    () async {
      final action = SpatialFieldActionPresentation();
      final cancelled = action.play(FieldAbility.rockSmash, durationMs: 200);
      action.update(double.nan);
      action.cancel();
      expect(await cancelled, isFalse);
      final next = action.play(FieldAbility.rockSmash, durationMs: 200);
      expect(action.state, CharacterAnimationState.rockSmash);
      action.update(.2);
      expect(await next, isTrue);
      expect(
        () => action.play(FieldAbility.fly, durationMs: 200),
        throwsArgumentError,
      );
    },
  );
}
