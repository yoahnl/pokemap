import 'dart:math';

import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:test/test.dart';

void main() {
  test(
      'random pause choices apply initially and after obstruction without consuming paused time',
      () {
    final controller = NpcFixedRouteController(
      target: SceneActorTarget.entity(mapId: 'map', entityId: 'actor'),
      movement: MapEntityNpcMovementConfig.fromJson({
        'mode': 'fixedRoute',
        'routeSteps': [
          {'kind': 'face', 'direction': 'west'}
        ],
        'pauseDurationMs': 1,
        'pauseDurationsMs': [100, 200],
      }),
      random: _Random(),
    );
    expect(controller.nextStep(const Duration(milliseconds: 99)), isNull);
    expect(
        controller.nextStep(const Duration(seconds: 10), paused: true), isNull);
    final first = controller.nextStep(const Duration(milliseconds: 1))!;
    controller.resolveStep(first, NpcFixedRouteStepOutcome.blocked);
    expect(controller.nextStep(const Duration(milliseconds: 199)), isNull);
    expect(controller.nextStep(const Duration(milliseconds: 1)), isNotNull);
  });
}

final class _Random implements Random {
  int _index = 0;
  @override
  int nextInt(int max) => _index++ % max;
  @override
  bool nextBool() => false;
  @override
  double nextDouble() => 0;
}
