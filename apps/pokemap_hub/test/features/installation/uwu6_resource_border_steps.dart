import 'package:avelune_studio/features/map_workspace/application/map_border_drawing_draft.dart';
import 'package:avelune_studio/features/map_workspace/application/map_border_editing_commands.dart';
import 'package:avelune_studio/features/map_workspace/application/map_canvas_stroke.dart';
import 'package:avelune_studio/features/map_workspace/application/map_editing_commands.dart';
import 'package:avelune_studio/features/map_workspace/application/map_workspace_editing_state.dart';
import 'package:avelune_studio/features/resources/application/resource_border_lifecycle_controller.dart';
import 'package:avelune_studio/features/resources/coordination/resource_border_lifecycle.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

import 'uwu6_resource_host.dart';

Future<void> drawUwu6Border(Uwu6ResourceHost host) => host.io(() async {
  final controller = host.fixture.controller;
  final document = controller.active!;
  expect(document.current.layers.whereType<BorderLayer>(), isEmpty);
  final blueprint = MapBorderEditingCommands.publishedLines(
    controller.project!,
  ).singleWhere(
    (entry) => entry.latestPublished!.definition.name == 'Muret conservé',
  );
  final stroke = MapBorderDrawingDraft.start(
    mapId: document.current.id,
    mapSize: document.current.size,
    blueprintId: blueprint.id,
    alignment: borderTemplateStrokeAlignment(
      blueprint.latestPublished!.definition.template,
    ),
    origin: const GridPos(x: 10, y: 8),
  ).addAngle(const GridPos(x: 13, y: 8));
  expect(stroke.canFinish, true);
  MapBorderEditingCommands(document, controller.project!).finish(stroke);
  controller.notify();
  final map = document.current;
  final border = map.layers.whereType<BorderLayer>().single;
  expect(border.content.features, hasLength(1));
  expect(
    map.layers.indexOf(border),
    0,
    reason: 'First normal stroke must be above an opaque floor.',
  );
  final blockedCell = 8 * map.size.width + 11;
  expect(
    map.layers.whereType<CollisionLayer>().any(
      (layer) => layer.collisions[blockedCell],
    ),
    false,
  );
  final collisions = MapCanvasStroke.start(
    map: map,
    project: controller.project!,
    view: MapWorkspaceEditingState()..tool = StudioMapTool.collisionPaint,
    commands: MapEditingCommands(document, controller.project!),
    origin: const GridPos(x: 11, y: 8),
  )!;
  document.commit(collisions.commit());
  controller.notify();
  final painted = document.current;
  expect(
    painted.layers.whereType<CollisionLayer>().any(
      (layer) => layer.collisions[blockedCell],
    ),
    true,
  );
  expect(
    painted.layers.whereType<BorderLayer>().single.content,
    border.content,
  );
  expect(await controller.save(document), true, reason: document.error);
  expect(document.dirty, false, reason: document.error);
  print(
    'UWU6_RESOURCE_FIRST_BORDER_OWNER id=${border.id} features=${border.content.features.length} index=${map.layers.indexOf(border)}',
  );
  print('UWU6_RESOURCE_EXPLICIT_BORDER_COLLISION_OWNER=11,8 visualOnly=10,8');
});

Future<void> deprecateUwu6Border(Uwu6ResourceHost host) => host.io(() async {
  final navigation = host.navigation;
  final before = (await host.read()).borderCatalog.records.single;
  Future<void> manage(BorderResourceAction action) async {
    await runBorderResourceManagement(
      navigation: navigation,
      record: navigation.workspace.project!.borderCatalog.recordById(
        before.id,
      )!,
      action: action,
      isActive: () => true,
      present: (lifecycle) async {
        await lifecycle.prepare();
        expect(lifecycle.error, isNull);
        lifecycle.confirm(true);
        expect(await lifecycle.apply(), isNull);
      },
      presentUsages: (_, _, _) async {},
    );
    expect(navigation.error, isNull);
  }

  await manage(BorderResourceAction.deprecate);
  final deprecated = (await host.read()).borderCatalog.records.single;
  expect(deprecated.isDeprecated, true);
  expect(deprecated.draft, before.draft);
  expect(deprecated.latestPublished, before.latestPublished);
  await manage(BorderResourceAction.reactivate);
  expect((await host.read()).borderCatalog.records.single, before);
  await manage(BorderResourceAction.deprecate);
  expect((await host.read()).borderCatalog.records.single.isDeprecated, true);
  print(
    'UWU6_RESOURCE_BORDER_OWNER deprecated-reactivated-deprecated=${before.id}',
  );
});
