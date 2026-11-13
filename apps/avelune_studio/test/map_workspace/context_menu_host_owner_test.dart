import 'dart:io';

import 'package:avelune_studio/features/map_workspace/application/map_context_command_runner.dart';
import 'package:avelune_studio/features/map_workspace/application/map_context_menu_model.dart';
import 'package:avelune_studio/features/map_workspace/application/map_entity_editing_commands.dart';
import 'package:avelune_studio/features/map_workspace/application/map_workspace_controller.dart';
import 'package:avelune_studio/features/map_workspace/application/map_workspace_editing_state.dart';
import 'package:avelune_studio/features/map_workspace/data/local_map_workspace_adapter.dart';
import 'package:avelune_studio/features/project_session/domain/project_session.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

import '../../tool/create_example_project.dart' show writeExampleProject;
import '../support/map_context_owner_fixture.dart';

const departure = 'jardin';

void main() {
  late Directory directory;
  late ProjectSession session;
  late MapWorkspaceController controller;
  MapContextOwnerHarness? harness;

  setUp(() async {
    final temporary = await Directory.systemTemp.createTemp('avelune_ctxh_');
    directory = Directory(await temporary.resolveSymbolicLinks());
    await writeExampleProject(directory);
    session = ProjectSession(
      sessionId: directory.path,
      name: 'Context owner and native viewport',
      directoryPath: directory.path,
    );
    controller = MapWorkspaceController(session, LocalMapWorkspaceAdapter());
    harness = null;
  });

  tearDown(() async {
    harness?.dispose();
    controller.dispose();
    if (directory.existsSync()) await directory.delete(recursive: true);
  });

  Future<MapEntity> open(WidgetTester tester) async {
    final sign = (await tester.runAsync(() async {
      await controller.initialize();
      await controller.activate(
        controller.project!.maps.firstWhere((entry) => entry.id == departure),
      );
      return MapEntityEditingCommands(
        controller.active!,
        controller.project!,
      ).place(MapEntityKind.sign, const GridPos(x: 5, y: 5));
    }))!;
    harness = MapContextOwnerHarness(
      controller.active!,
      controller.project!,
      controller: controller,
    );
    await harness!.pump(tester);
    return sign;
  }

  testWidgets(
    'native right click and context session delete with save and cold reopen',
    (tester) async {
      final sign = await open(tester);
      await harness!.rightClick(tester, 5, 5);
      expect(harness!.request!.target!.id, sign.id);
      harness!.run(MapContextCommand.delete);
      expect(harness!.request, isNull);
      expect(
        controller.active!.current.entities.where(
          (entity) => entity.id == sign.id,
        ),
        isEmpty,
      );
      await tester.runAsync(() async {
        expect(await controller.save(controller.active!), isTrue);
        final reopened = MapWorkspaceController(
          session,
          LocalMapWorkspaceAdapter(),
        );
        try {
          await reopened.initialize();
          await reopened.activate(
            reopened.project!.maps.firstWhere((entry) => entry.id == departure),
          );
          expect(
            reopened.active!.current.entities.where(
              (entity) => entity.id == sign.id,
            ),
            isEmpty,
          );
        } finally {
          reopened.dispose();
        }
      });
    },
  );

  testWidgets('opening and closing a context request adds no map mutation', (
    tester,
  ) async {
    await open(tester);
    final before = controller.active!.current;
    final steps = controller.active!.undoCount;
    await harness!.rightClick(tester, 5, 5);
    expect(harness!.request, isNotNull);
    harness!.close();
    expect(harness!.request, isNull);
    expect(controller.active!.current, same(before));
    expect(controller.active!.undoCount, steps);
  });

  testWidgets('properties requests navigation for the selected identity', (
    tester,
  ) async {
    final sign = await open(tester);
    var calls = 0;
    harness!.navigation = MapContextNavigation(showProperties: () => calls++);
    await harness!.rightClick(tester, 5, 5);
    harness!.run(MapContextCommand.properties);
    expect(calls, 1);
    expect(harness!.selected(MapSelectionFamily.marker), sign.id);
    expect(harness!.request, isNull);
  });

}
