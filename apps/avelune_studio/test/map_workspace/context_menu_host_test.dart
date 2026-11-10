import 'dart:async';
import 'dart:io';

import 'package:avelune_studio/features/map_workspace/application/map_context_command_runner.dart';
import 'package:avelune_studio/features/map_workspace/application/map_context_menu_model.dart';
import 'package:avelune_studio/features/map_workspace/application/map_entity_editing_commands.dart';
import 'package:avelune_studio/features/map_workspace/application/map_workspace_controller.dart';
import 'package:avelune_studio/features/map_workspace/application/map_workspace_editing_state.dart';
import 'package:avelune_studio/features/map_workspace/coordination/workspace_navigation_session.dart';
import 'package:avelune_studio/features/map_workspace/data/local_map_workspace_adapter.dart';
import 'package:avelune_studio/features/project_session/domain/project_session.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

import '../../tool/create_example_project.dart' show writeExampleProject;
import '../support/map_context_harness.dart';

const departure = 'jardin';

void main() {
  late Directory directory;
  late ProjectSession session;
  late MapWorkspaceController controller;
  MapContextHarness? harness;

  setUp(() async {
    final parent = Directory(
      '/Users/karim/Library/Caches/AveluneQA/studio-t01-retirement-20261109/t01-map-retirement',
    );
    await parent.create(recursive: true);
    final temporary = await parent.createTemp('avelune_ctxh_');
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
    harness = MapContextHarness(controller.active!, controller.project!);
    await harness!.pump(tester);
    return sign;
  }

  testWidgets(
    'native right click and context session delete with save and cold reopen',
    (tester) async {
      final sign = await open(tester);
      await harness!.rightClick(tester, 5, 5);
      expect(harness!.request!.selected!.id, sign.id);
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

  testWidgets(
    'opening an unbound story zone explains the missing interaction and preserves it',
    (tester) async {
      await open(tester);
      final document = controller.active!;
      const trigger = MapTrigger(
        id: 'quai',
        name: 'Quai',
        type: TriggerType.event,
        area: MapRect(
          pos: GridPos(x: 8, y: 3),
          size: GridSize(width: 3, height: 3),
        ),
      );
      document.commit(
        document.current.copyWith(
          triggers: [...document.current.triggers, trigger],
        ),
      );
      final navigation = WorkspaceNavigationSession(
        controller: controller,
        isActive: () => true,
        changed: () {},
      );
      harness!.navigation = MapContextNavigation(
        openStoryZone: (target) {
          unawaited(
            navigation.openExistingStoryZone(
              document,
              target,
              choose: (_) async => null,
            ),
          );
        },
      );
      await harness!.rightClick(tester, 9, 4);
      final target = harness!.request!.targets.singleWhere(
        (target) => target.family == MapContextFamily.trigger,
      );
      harness!.select(target);
      harness!.run(MapContextCommand.openNarrativeDocument);
      expect(document.error, contains('Tracez-la depuis'));
      expect(
        document.current.triggers.where((value) => value.id == trigger.id),
        isNotEmpty,
      );
    },
  );
}
