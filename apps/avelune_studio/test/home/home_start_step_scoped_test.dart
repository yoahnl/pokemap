import 'package:avelune_studio/features/home/application/home_next_steps.dart';
import 'package:avelune_studio/features/map_workspace/application/map_workspace_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

import '../support/scoped_map_workspace_port.dart';

void main() {
  test('a scoped catalog proves the start without reading the project', () async {
    final port = ScopedTestMapPort(
      metadata: scopedMapMetadata.copyWith(
        newGame: const ProjectNewGameConfig(
          enabled: true,
          startMapId: 'second',
          startSpawnId: 'start',
        ),
      ),
    );
    final controller = MapWorkspaceController(scopedMapSession, port);
    addTearDown(controller.dispose);
    await controller.initialize();
    expect(controller.hasCompleteProject, isFalse);
    expect(controller.homeNewGame?.startMapId, 'second');
    await controller.activate(firstScopedMap);
    expect(controller.homeNewGame?.startMapId, 'second');
    expect(port.fullReads, 0);

    final start = homeNextSteps(
      maps: [
        for (final entry in controller.project!.maps)
          (id: entry.id, name: entry.name),
      ],
      newGame: controller.homeNewGame,
      canTest: true,
    ).singleWhere((step) => step.kind == HomeNextStepKind.start);
    expect(start.status, HomeNextStepStatus.done);
    expect(start.detail, 'La partie commence sur Seconde.');
  });

  test('a scoped catalog without a start reads as to do, not unverified', () async {
    final controller = MapWorkspaceController(
      scopedMapSession,
      ScopedTestMapPort(),
    );
    addTearDown(controller.dispose);
    await controller.initialize();
    final start = homeNextSteps(
      maps: const [(id: 'first', name: 'Première')],
      newGame: controller.homeNewGame,
      canTest: true,
    ).singleWhere((step) => step.kind == HomeNextStepKind.start);
    expect(start.status, HomeNextStepStatus.todo);
  });
}
