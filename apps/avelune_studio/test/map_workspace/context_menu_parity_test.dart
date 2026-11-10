import 'dart:io';

import 'package:avelune_studio/features/map_workspace/application/map_context_command_runner.dart';
import 'package:avelune_studio/features/map_workspace/application/map_context_menu_actions.dart';
import 'package:avelune_studio/features/map_workspace/application/map_context_menu_model.dart';
import 'package:avelune_studio/features/map_workspace/application/map_entity_editing_commands.dart';
import 'package:avelune_studio/features/map_workspace/application/map_workspace_controller.dart';
import 'package:avelune_studio/features/map_workspace/application/warp_editing_commands.dart';
import 'package:avelune_studio/features/map_workspace/data/local_map_workspace_adapter.dart';
import 'package:avelune_studio/features/project_session/domain/project_session.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

import '../../tool/create_example_project.dart' show writeExampleProject;
import '../support/map_context_harness.dart';
import '../support/map_workspace_fixture.dart';

const eventId = 'evt_0192bc3d-4e5f-7a1b-8c2d-3e4f5a6b7c8d';

ProjectManifest projectUsing(String mapId, String entityId) =>
    workspaceProject.copyWith(
      eventRegistry: NarrativeEventRegistry(
        schemaVersion: 1,
        mode: EventSystemMode.legacyOnly,
        records: [
          NarrativeEventRecord.draft(
            NarrativeEventDraft(
              id: eventId,
              name: 'Lecture',
              source: NarrativeEventSourceRef.entityInteract(mapId, entityId),
              conditions: const [],
              priority: 0,
              order: 0,
            ),
          ),
        ],
        legacyClaims: const [],
      ),
    );

void main() {
  testWidgets(
    'context actions and direct commands honour the same deletion guard',
    (tester) async {
      final h = MapContextHarness.of(workspaceProject);
      addTearDown(h.dispose);
      final sign = MapEntityEditingCommands(
        h.document,
        h.project,
      ).place(MapEntityKind.sign, const GridPos(x: 4, y: 4));
      await h.pump(tester);
      h.project = projectUsing('a', sign.id);
      await h.rightClick(tester, 4, 4);
      final action = h.request!.actions.singleWhere(
        (action) => action.command == MapContextCommand.delete,
      );
      expect(action.enabled, isFalse);
      expect(action.unavailable, contains('histoire'));
      expect(
        MapEntityEditingCommands(
          h.document,
          h.project,
        ).deletionProblem(sign.id),
        isNotNull,
      );
      h.close();
      h.project = workspaceProject;
      await h.rightClick(tester, 4, 4);
      h.run(MapContextCommand.delete);
      expect(
        MapEntityEditingCommands(h.document, h.project).selected(sign.id),
        isNull,
      );
    },
  );

  testWidgets(
    'a dependency added after opening the request is still enforced at execution',
    (tester) async {
      final h = MapContextHarness.of(workspaceProject);
      addTearDown(h.dispose);
      final sign = MapEntityEditingCommands(
        h.document,
        h.project,
      ).place(MapEntityKind.sign, const GridPos(x: 5, y: 5));
      await h.pump(tester);
      await h.rightClick(tester, 5, 5);
      expect(
        h.request!.actions
            .singleWhere((action) => action.command == MapContextCommand.delete)
            .enabled,
        isTrue,
      );
      h.project = projectUsing('a', sign.id);
      h.run(MapContextCommand.delete);
      expect(
        MapEntityEditingCommands(h.document, h.project).selected(sign.id),
        isNotNull,
      );
      expect(h.document.error, contains('histoire'));
    },
  );

  test('a menu edit survives saving and reopening from disk', () async {
    final parent = Directory(
      '/Users/karim/Library/Caches/AveluneQA/studio-t01-retirement-20261109/t01-map-retirement',
    );
    await parent.create(recursive: true);
    final temporary = await parent.createTemp('avelune_ctx_');
    final directory = Directory(await temporary.resolveSymbolicLinks());
    addTearDown(() async {
      if (directory.existsSync()) await directory.delete(recursive: true);
    });
    await writeExampleProject(directory);
    final session = ProjectSession(
      sessionId: directory.path,
      name: 'Menu contextuel',
      directoryPath: directory.path,
    );

    final workspace = MapWorkspaceController(
      session,
      LocalMapWorkspaceAdapter(),
    );
    await workspace.initialize();
    await workspace.activate(
      workspace.project!.maps.firstWhere((entry) => entry.id == 'jardin'),
    );
    final warpId = WarpEditingCommands(workspace.active!, workspace.project!)
        .place(
          workspace.project!.maps.firstWhere(
            (entry) => entry.id == 'clairiere',
          ),
          const GridPos(x: 6, y: 6),
        )
        .id;

    final context = MapContextActionContext(
      document: workspace.active!,
      project: workspace.project!,
      position: const GridPos(x: 6, y: 6),
    );
    final target = mapContextTargetsAt(
      context.document,
      context.project,
      context.position,
    ).firstWhere((item) => item.family == MapContextFamily.warp);
    expect(
      MapContextCommandRunner(context).run(MapContextCommand.delete, target),
      isNull,
    );

    expect(await workspace.save(workspace.active!), isTrue);
    workspace.dispose();
    final reopened = MapWorkspaceController(
      session,
      LocalMapWorkspaceAdapter(),
    );
    await reopened.initialize();
    await reopened.activate(
      reopened.project!.maps.firstWhere((entry) => entry.id == 'jardin'),
    );
    expect(
      reopened.active!.current.warps.where((item) => item.id == warpId),
      isEmpty,
      reason: 'what the menu removed is really gone from the file',
    );
    reopened.dispose();
  });
}
