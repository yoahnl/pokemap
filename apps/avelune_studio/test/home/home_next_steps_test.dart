import 'package:avelune_studio/features/home/application/home_next_steps.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core_domain.dart';

void main() {
  test('an empty project asks for a map and a start, verifies nothing', () {
    final steps = homeNextSteps(
      maps: const [],
      newGame: const ProjectNewGameConfig(),
      canTest: false,
    );
    expect([for (final step in steps) step.kind], HomeNextStepKind.values);
    expect(steps[0].status, HomeNextStepStatus.todo);
    expect(steps[0].destination, 'createMap');
    expect(steps[1].status, HomeNextStepStatus.todo);
    for (final step in steps.skip(2)) {
      expect(
        step.status,
        HomeNextStepStatus.unverified,
        reason: '${step.kind}',
      );
    }
  });

  test('map and start are done only when the manifest proves them', () {
    final steps = homeNextSteps(
      maps: const [(id: 'bourg', name: 'Bourg Geon')],
      newGame: const ProjectNewGameConfig(startMapId: 'bourg'),
      canTest: true,
    );
    expect(steps[0].status, HomeNextStepStatus.done);
    expect(steps[0].destination, 'map');
    expect(steps[1].status, HomeNextStepStatus.done);
    expect(steps[1].mapId, 'bourg');
    expect(steps[1].detail, contains('Bourg Geon'));
    expect(
      steps.where((step) => step.status == HomeNextStepStatus.done).length,
      2,
    );
    expect(steps.last.destination, 'testGame');
    expect(steps.last.unavailableReason, isNull);
  });

  test('a start pointing to a missing map is not reported as done', () {
    final steps = homeNextSteps(
      maps: const [(id: 'bourg', name: 'Bourg Geon')],
      newGame: const ProjectNewGameConfig(startMapId: 'route-perdue'),
      canTest: false,
    );
    expect(steps[1].status, HomeNextStepStatus.todo);
    expect(steps[1].detail, contains('introuvable'));
    expect(steps.last.unavailableReason, isNotNull);
  });

  test('without the project manifest the start stays unverified', () {
    final steps = homeNextSteps(
      maps: const [(id: 'bourg', name: 'Bourg Geon')],
      newGame: null,
      canTest: true,
    );
    expect(steps[0].status, HomeNextStepStatus.done);
    expect(steps[1].status, HomeNextStepStatus.unverified);
  });
}
