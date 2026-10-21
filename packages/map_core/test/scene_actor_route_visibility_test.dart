import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  for (final visible in [false, true]) {
    test('route visibility round trips its boolean state: $visible', () {
      final json = {'kind': 'visibility', 'visible': visible};
      final step = SceneActorRouteStep.fromJson(json);
      expect(step.toJson(), json);
      expect(SceneActorRouteStep.fromJson(step.toJson()), step);
      final route = SceneActorRouteInteractiveCommand(
        target: SceneActorTarget.player(mapId: 'map'),
        steps: [step],
      );
      expect(SceneInteractiveCommand.fromJson(route.toJson()), route);
    });
  }
  for (final value in [null, 0, 1, .5, 'false']) {
    test('visibility refuses non boolean state $value', () {
      expect(
        () => SceneActorRouteStep.fromJson({
          'kind': 'visibility',
          'visible': value,
        }),
        throwsFormatException,
      );
    });
  }
  test('visibility refuses hidden extra fields', () {
    expect(
      () => SceneActorRouteStep.fromJson({
        'kind': 'visibility',
        'visible': true,
        'opacity': 255,
      }),
      throwsFormatException,
    );
  });
}
