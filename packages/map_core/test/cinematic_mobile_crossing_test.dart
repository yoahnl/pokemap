import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  test('mobile actor crossing is explicit, strict and survives copy', () {
    final base = CinematicAsset(
      id: 'crossing',
      title: 'Crossing',
      timeline: CinematicTimeline(),
    );
    final enabled = CinematicAsset.fromJson({
      ...base.toJson(),
      'allowMobileActorCrossing': true,
    });
    expect(enabled.toJson()['allowMobileActorCrossing'], isTrue);
    expect(
      enabled.copyWith(title: 'Updated').toJson()['allowMobileActorCrossing'],
      isTrue,
    );
    expect(base.toJson()['allowMobileActorCrossing'], isFalse);
    for (final invalid in ['true', 1, null]) {
      expect(
        () => CinematicAsset.fromJson({
          ...base.toJson(),
          'allowMobileActorCrossing': invalid,
        }),
        throwsFormatException,
      );
    }
  });
}
