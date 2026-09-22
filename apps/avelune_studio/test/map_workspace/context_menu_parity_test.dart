import 'dart:io';

import 'package:avelune_studio/features/map_workspace/application/map_context_command_runner.dart';
import 'package:avelune_studio/features/map_workspace/application/map_context_menu_actions.dart';
import 'package:avelune_studio/features/map_workspace/application/map_context_menu_model.dart';
import 'package:avelune_studio/features/map_workspace/application/map_entity_editing_commands.dart';
import 'package:avelune_studio/features/map_workspace/application/map_workspace_controller.dart';
import 'package:avelune_studio/features/map_workspace/application/warp_editing_commands.dart';
import 'package:avelune_studio/features/map_workspace/data/local_map_workspace_adapter.dart';
import 'package:avelune_studio/features/project_session/domain/project_session.dart';
import 'package:flutter/material.dart';
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
  testWidgets('menu and inspector delete the same way and refuse alike', (
    tester,
  ) async {
    final h = MapContextHarness.of(workspaceProject);
    addTearDown(h.dispose);
    final sign = MapEntityEditingCommands(
      h.document,
      h.project,
    ).place(MapEntityKind.sign, const GridPos(x: 4, y: 4));
    await h.pump(tester);

    // The inspector refuses it once the story references it.
    h.project = projectUsing('a', sign.id);
    h.redraw();
    await tester.pumpAndSettle();
    await h.rightClick(tester, 4, 4);
    await tester.tap(
      find.descendant(
        of: find.byKey(const ValueKey('map-context-menu')),
        matching: find.text('Supprimer'),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      MapEntityEditingCommands(h.document, h.project).selected(sign.id),
      isNotNull,
      reason: 'the menu honours the same guard as the inspector',
    );
    expect(
      find.byKey(const ValueKey('map-context-menu')),
      findsOneWidget,
      reason: 'a blocked action is inert, it does not silently close',
    );
    await h.escape(tester);

    // Freed again, both paths delete it.
    h.project = workspaceProject;
    h.redraw();
    await tester.pumpAndSettle();
    await h.rightClick(tester, 4, 4);
    await tester.tap(
      find.descendant(
        of: find.byKey(const ValueKey('map-context-menu')),
        matching: find.text('Supprimer'),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      MapEntityEditingCommands(h.document, h.project).selected(sign.id),
      isNull,
    );
  });

  testWidgets('a dependency added while the menu is open still blocks', (
    tester,
  ) async {
    final h = MapContextHarness.of(workspaceProject);
    addTearDown(h.dispose);
    final sign = MapEntityEditingCommands(
      h.document,
      h.project,
    ).place(MapEntityKind.sign, const GridPos(x: 5, y: 5));
    await h.pump(tester);

    await h.rightClick(tester, 5, 5);
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('map-context-menu')),
        matching: find.text('Supprimer'),
      ),
      findsOneWidget,
    );

    // The dependency appears after the menu was drawn.
    h.project = projectUsing('a', sign.id);
    await tester.tap(
      find.descendant(
        of: find.byKey(const ValueKey('map-context-menu')),
        matching: find.text('Supprimer'),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      MapEntityEditingCommands(h.document, h.project).selected(sign.id),
      isNotNull,
      reason: 'the command re-reads the guard when it acts, not at opening',
    );
    expect(h.document.error, contains('histoire'));
  });

  test('a menu edit survives saving and reopening from disk', () async {
    final temporary = await Directory.systemTemp.createTemp('avelune_ctx_');
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

    // The menu command, run through the shared runner.
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
