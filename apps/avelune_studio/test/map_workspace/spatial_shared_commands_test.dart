import 'package:avelune_studio/features/map_workspace/coordination/map_editing_viewport_session.dart';
import 'package:avelune_studio/features/map_workspace/coordination/map_resource_placement.dart';
import 'package:avelune_studio/features/resources/application/resource_catalog.dart';

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show LogicalKeyboardKey;
import 'package:map_render_3d/map_render_3d.dart';
import 'package:avelune_studio/features/map_workspace/application/map_workspace_controller.dart';
import 'package:avelune_studio/platform/rendering/viewports/spatial_map_editing_viewport.dart';
import 'package:avelune_studio/platform/rendering/contracts/map_workspace_visuals.dart';

import '../support/map_workspace_fixture.dart';

import 'package:flutter_test/flutter_test.dart';
import 'package:avelune_studio/platform/rendering/studio_map_resources.dart';
import 'package:avelune_studio/features/project_session/domain/project_session.dart';
import 'package:avelune_studio/features/map_workspace/application/map_context_menu_model.dart';
import 'package:avelune_studio/features/map_workspace/application/map_context_menu_actions.dart';
import 'package:avelune_studio/features/map_workspace/application/map_context_command_runner.dart';
import 'package:map_core/map_core.dart';
import 'package:avelune_studio/features/map_workspace/application/editable_map_document.dart';
import 'package:avelune_studio/features/map_workspace/domain/map_workspace_port.dart';
import 'package:avelune_studio/features/map_workspace/application/spatial_model_editing_commands.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  for (final key in [LogicalKeyboardKey.delete, LogicalKeyboardKey.backspace]) {
    testWidgets('${key.keyLabel} removes the selected 3D decor and undoes', (
      tester,
    ) async {
      final project = ProjectManifest.fromJson(
        jsonDecode(
          File('test/fixtures/spatial_first_map/project.json')
              .readAsStringSync(),
        ) as Map<String, dynamic>,
      );
      final source = MapData.fromJson(
        jsonDecode(
          File('test/fixtures/spatial_first_map/maps/first-map.json')
              .readAsStringSync(),
        ) as Map<String, dynamic>,
      );
      final model = source.spatialScene!.instances.first.copyWith(
        position: Model3dVector3(x: 3.5, y: 0, z: 3.5),
      );
      final map = source.copyWith(
        spatialScene: source.spatialScene!.copyWith(
          instances: [model, ...source.spatialScene!.instances.skip(1)],
        ),
      );
      final document = EditableMapDocument(
        MapWorkspaceDocument(map: map, mapId: map.id, revision: 'delete-test'),
      );
      final view = MapEditingViewportSession()
        ..tool = StudioMapTool.select
        ..spatialFreeView = true;
      final controller =
          MapWorkspaceController(workspaceSession, WorkspaceMemoryPort())
            ..project = project
            ..active = document;
      controller.documents[map.id] = document;
      final visuals = _SpatialTestVisuals();
      addTearDown(view.dispose);
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) => Column(
                children: [
                  const TextField(key: ValueKey('delete-inspector-input')),
                  Expanded(
                    child: SpatialMapEditingViewport(
                      document: document,
                      controller: controller,
                      project: project,
                      visuals: visuals,
                      view: view,
                      onChanged: () => setState(() {}),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      SpatialSceneView scene() => tester.widget(find.byType(SpatialSceneView));
      void select() => scene().onContent!(
        SpatialSceneContentHit(
          kind: SpatialSceneContentKind.model,
          id: model.id,
          cell: (model.position.x.floor(), model.position.z.floor()),
        ),
      );
      select();
      await tester.pump();
      expect(document.current, same(map));
      expect(document.undoCount, 0);
      await tester.tap(find.byType(TextField).first);
      await tester.sendKeyEvent(key);
      await tester.pump();
      expect(document.current, same(map));
      expect(document.undoCount, 0);
      select();
      await tester.pump();
      document.saving = true;
      await tester.sendKeyEvent(key);
      await tester.pump();
      expect(document.current, same(map));
      document.saving = false;
      await tester.sendKeyDownEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump();
      expect(scene().contentPreview, isNotNull);
      await tester.sendKeyEvent(key);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump();
      expect(
        document.current.spatialScene!.instances,
        map.spatialScene!.instances.where((item) => item.id != model.id),
      );
      expect(document.current.entities, map.entities);
      expect(document.undoCount, 1);
      expect(document.selectedId, isNull);
      expect(view.target, isNull);
      expect(scene().selectedContent, isNull);
      expect(scene().contentPreview, isNull);
      await tester.sendKeyEvent(key);
      expect(document.undoCount, 1);
      document.restore(redo: false);
      await tester.pump();
      expect(document.current, map);
      expect(tester.takeException(), isNull);
    });
  }
  testWidgets('Shift-drag moves a 3D decor and Shift-click toggles it', (
    tester,
  ) async {
    final project = ProjectManifest.fromJson(
      jsonDecode(
        File('test/fixtures/spatial_first_map/project.json').readAsStringSync(),
      ) as Map<String, dynamic>,
    );
    final map = MapData.fromJson(
      jsonDecode(
        File('test/fixtures/spatial_first_map/maps/first-map.json')
            .readAsStringSync(),
      ) as Map<String, dynamic>,
    ).copyWith(entities: []);
    final document = EditableMapDocument(
      MapWorkspaceDocument(map: map, mapId: map.id, revision: 'shift-test'),
    );
    final view = MapEditingViewportSession()..tool = StudioMapTool.select;
    final controller =
        MapWorkspaceController(workspaceSession, WorkspaceMemoryPort())
          ..project = project
          ..active = document;
    controller.documents[map.id] = document;
    addTearDown(view.dispose);
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) => SpatialMapEditingViewport(
              document: document,
              controller: controller,
              project: project,
              visuals: _SpatialTestVisuals(),
              view: view,
              onChanged: () => setState(() {}),
            ),
          ),
        ),
      ),
    );
    SpatialSceneView scene() => tester.widget(find.byType(SpatialSceneView));
    final instance = map.spatialScene!.instances.firstWhere(
      (item) => item.blocksMovement,
    );
    final cell = (instance.position.x.floor(), instance.position.z.floor());
    final hit = SpatialSceneContentHit(
      kind: SpatialSceneContentKind.model,
      id: instance.id,
      cell: cell,
    );
    scene().onContent!(hit);
    await tester.pump();
    expect(document.selectedId, instance.id);
    await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
    expect(scene().onDragStart!(cell.$1, cell.$2, hit), isTrue);
    scene().onDragUpdate!((cell.$1 + 1, cell.$2));
    scene().onDragEnd!();
    await tester.pump();
    expect(
      document.current.spatialScene!.instances
          .firstWhere((item) => item.id == instance.id)
          .position
          .x,
      instance.position.x + 1,
    );
    expect(document.undoCount, 1);
    expect(document.selectedId, instance.id);
    scene().onContent!(hit);
    await tester.pump();
    expect(document.selectedId, isNull);
    expect(document.undoCount, 1);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
    await tester.pumpWidget(const SizedBox());
  });
  testWidgets('free camera moves selected content and returns to game view', (
    tester,
  ) async {
    final project = ProjectManifest.fromJson(
      jsonDecode(
        File('test/fixtures/spatial_first_map/project.json').readAsStringSync(),
      ) as Map<String, dynamic>,
    );
    final map = MapData.fromJson(
      jsonDecode(
        File('test/fixtures/spatial_first_map/maps/first-map.json')
            .readAsStringSync(),
      ) as Map<String, dynamic>,
    ).copyWith(entities: []);
    final document = EditableMapDocument(
      MapWorkspaceDocument(map: map, mapId: map.id, revision: 'camera-test'),
    );
    final view = MapEditingViewportSession()
      ..tool = StudioMapTool.place
      ..model3d = project.models3d.first;
    final controller =
        MapWorkspaceController(workspaceSession, WorkspaceMemoryPort())
          ..project = project
          ..active = document;
    controller.documents[map.id] = document;
    final visuals = _SpatialTestVisuals();
    addTearDown(view.dispose);
    addTearDown(controller.dispose);
    late VoidCallback refresh;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) {
              void changed() => setState(() {});
              refresh = changed;
              return Column(
                children: [
                  Expanded(
                    child: SpatialMapEditingViewport(
                      document: document,
                      controller: controller,
                      project: project,
                      visuals: visuals,
                      view: view,
                      onChanged: changed,
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
    SpatialSceneView scene() => tester.widget(find.byType(SpatialSceneView));
    expect(scene().controller.view, SpatialEditorView.game);
    view.spatialFreeView = !view.spatialFreeView;
    refresh();
    await tester.pump();
    expect(scene().controller.view, SpatialEditorView.orbit);
    expect(scene().onDragStart, isNotNull);
    expect(scene().onContent, isNotNull);
    expect(document.current, same(map));
    expect(document.canUndo, isFalse);
    final instance = map.spatialScene!.instances.firstWhere(
      (item) => item.blocksMovement,
    );
    final cell = (instance.position.x.floor(), instance.position.z.floor());
    final hit = SpatialSceneContentHit(
      kind: SpatialSceneContentKind.model,
      id: instance.id,
      cell: cell,
    );
    expect(scene().onDragStart!(cell.$1, cell.$2, hit), isFalse);
    view.tool = StudioMapTool.select;
    scene().onCell(0, 0);
    await tester.pump();
    expect(scene().selectContent, isTrue);
    expect(scene().onDragStart!(0, 0, null), isFalse);
    scene().onContent!(hit);
    await tester.pump();
    expect(document.selectedId, instance.id);
    expect(scene().selectedContent?.id, instance.id);
    expect(scene().selectionColor, isNotNull);
    expect(document.canUndo, isFalse);
    final yaw = scene().controller.yaw;
    final pitch = scene().controller.pitch;
    expect(scene().onDragStart!(cell.$1, cell.$2, hit), isTrue);
    scene().onDragUpdate!((cell.$1 + 1, cell.$2));
    await tester.pump();
    expect(document.current, same(map));
    expect(document.canUndo, isFalse);
    expect(scene().contentPreview?.id, instance.id);
    expect(scene().contentPreview?.position.x, instance.position.x + 1);
    expect(scene().contentPreview?.position.z, instance.position.z);
    expect(scene().scene, same(map.spatialScene));
    scene().onDragEnd!();
    await tester.pump();
    expect(scene().contentPreview, isNull);
    final moved = document.current.spatialScene!.instances.firstWhere(
      (item) => item.id == instance.id,
    );
    expect(moved.position.x, instance.position.x + 1);
    expect(moved.position.z, instance.position.z);
    expect(document.undoCount, 1);
    expect(document.current.spatialScene!.camera, map.spatialScene!.camera);
    expect(scene().controller.yaw, yaw);
    expect(scene().controller.pitch, pitch);
    document.restore(redo: false);
    expect(document.current, map);
    document.restore(redo: true);
    expect(
      document.current.spatialScene!.instances.firstWhere(
        (item) => item.id == instance.id,
      ),
      moved,
    );
    document.restore(redo: false);
    expect(scene().onDragStart!(cell.$1, cell.$2, hit), isTrue);
    scene().onDragUpdate!((cell.$1 + 2, cell.$2));
    view.spatialFreeView = false;
    scene().onDragEnd!();
    await tester.pump();
    expect(document.current, map);
    expect(document.canUndo, isFalse);
    expect(scene().contentPreview, isNull);
    view.spatialFreeView = true;
    scene().onCell(0, 0);
    await tester.pump();
    expect(scene().onDragStart!(cell.$1, cell.$2, hit), isTrue);
    scene().onDragUpdate!((cell.$1 + 2, cell.$2));
    document.saving = true;
    scene().onDragEnd!();
    document.saving = false;
    await tester.pump();
    expect(document.current, map);
    expect(document.canUndo, isFalse);
    expect(scene().onDragStart!(cell.$1, cell.$2, hit), isTrue);
    scene().onDragUpdate!((cell.$1 + 1, cell.$2));
    await tester.pump();
    expect(scene().contentPreview, isNotNull);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pump();
    expect(scene().contentPreview, isNull);
    expect(scene().selectedContent, isNull);
    expect(scene().controller.view, SpatialEditorView.orbit);
    scene().onDragEnd!();
    expect(document.current, map);
    expect(document.canUndo, isFalse);
    scene().controller.orbit(150, 50);
    expect(scene().controller.yaw, isNot(.5));
    view.viewport.zoomBy(1.25);
    await tester.pump();
    expect(view.scale, 1.25);
    view.spatialFreeView = !view.spatialFreeView;
    refresh();
    await tester.pump();
    expect(scene().controller.view, SpatialEditorView.game);
    expect(scene().onDragStart, isNotNull);
    view.spatialFreeView = !view.spatialFreeView;
    refresh();
    await tester.pump();
    view.recenter!();
    await tester.pump();
    expect(scene().controller.view, SpatialEditorView.game);
    expect(view.scale, 1);
    expect(document.current, map);
    expect(tester.takeException(), isNull);
  });
  testWidgets(
    'arrows preview selected models and NPCs with one held-key undo',
    (tester) async {
      final project = ProjectManifest.fromJson(
        jsonDecode(
          File('test/fixtures/spatial_first_map/project.json')
              .readAsStringSync(),
        ) as Map<String, dynamic>,
      );
      final source = MapData.fromJson(
        jsonDecode(
          File('test/fixtures/spatial_first_map/maps/first-map.json')
              .readAsStringSync(),
        ) as Map<String, dynamic>,
      );
      final model = source.spatialScene!.instances.first.copyWith(
        position: Model3dVector3(x: 3.5, y: 0, z: 3.5),
      );
      final npc = source.entities.first.copyWith(
        pos: const GridPos(x: 3, y: 3),
      );
      final map = source.copyWith(
        spatialScene: source.spatialScene!.copyWith(instances: [model]),
        entities: [npc],
      );
      final document = EditableMapDocument(
        MapWorkspaceDocument(
          map: map,
          mapId: map.id,
          revision: 'keyboard-test',
        ),
      );
      final view = MapEditingViewportSession()..tool = StudioMapTool.select;
      final controller =
          MapWorkspaceController(workspaceSession, WorkspaceMemoryPort())
            ..project = project
            ..active = document;
      final visuals = _SpatialTestVisuals();
      addTearDown(view.dispose);
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) => Column(
                children: [
                  const TextField(key: ValueKey('inspector-input')),
                  Expanded(
                    child: SpatialMapEditingViewport(
                      document: document,
                      controller: controller,
                      project: project,
                      visuals: visuals,
                      view: view,
                      onChanged: () => setState(() {}),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      SpatialSceneView scene() => tester.widget(find.byType(SpatialSceneView));
      scene().onContent!(
        SpatialSceneContentHit(
          kind: SpatialSceneContentKind.model,
          id: model.id,
          cell: (3, 3),
        ),
      );
      await tester.pump();
      await tester.sendKeyDownEvent(LogicalKeyboardKey.arrowRight);
      await tester.sendKeyRepeatEvent(LogicalKeyboardKey.arrowRight);
      await tester.sendKeyRepeatEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump();
      expect(document.current, same(map));
      expect(scene().contentPreview?.position.x, 6.5);
      expect(document.undoCount, 0);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump();
      expect(document.current.spatialScene!.instances.single.position.x, 6.5);
      expect(document.undoCount, 1);
      expect(scene().contentPreview, isNull);
      document.restore(redo: false);
      await tester.pump();
      await tester.sendKeyDownEvent(LogicalKeyboardKey.arrowLeft);
      await tester.pump();
      expect(scene().contentPreview?.position.x, 2.5);
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.arrowLeft);
      await tester.pump();
      expect(document.current, map);
      expect(scene().contentPreview, isNull);
      expect(document.undoCount, 0);
      expect(scene().selectedContent, isNull);
      expect(document.selectedId, isNull);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump();
      expect(document.current, map);
      await tester.tap(find.byKey(const ValueKey('inspector-input')));
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump();
      expect(document.current, map);
      expect(scene().contentPreview, isNull);
      scene().onContent!(
        SpatialSceneContentHit(
          kind: SpatialSceneContentKind.actor,
          id: 'npc:${npc.id}',
          cell: (3, 3),
        ),
      );
      await tester.pump();
      await tester.sendKeyDownEvent(LogicalKeyboardKey.arrowUp);
      await tester.pump();
      expect(scene().contentPreview?.id, 'npc:${npc.id}');
      expect(scene().contentPreview?.position.z, 2.5);
      expect(document.current.entities.single.pos, npc.pos);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.arrowUp);
      await tester.pump();
      expect(document.current.entities.single.pos, const GridPos(x: 3, y: 2));
      expect(document.undoCount, 1);
      expect(scene().contentPreview, isNull);
      await tester.sendKeyDownEvent(LogicalKeyboardKey.arrowLeft);
      for (var repeat = 0; repeat < 8; repeat++) {
        await tester.sendKeyRepeatEvent(LogicalKeyboardKey.arrowLeft);
      }
      await tester.pump();
      expect(scene().contentPreview?.position.x, .5);
      await tester.sendKeyDownEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump();
      expect(scene().contentPreview?.position.x, 1.5);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.arrowRight);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.arrowLeft);
      await tester.pump();
      expect(document.current.entities.single.pos, const GridPos(x: 1, y: 2));
      expect(document.undoCount, 2);
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pump();
      expect(scene().selectedContent, isNull);
      expect(view.target, isNull);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'canonical resource choice arms ground placement and selection uses content',
    (tester) async {
      final project = ProjectManifest.fromJson(
        jsonDecode(
          File('test/fixtures/spatial_first_map/project.json')
              .readAsStringSync(),
        ) as Map<String, dynamic>,
      );
      final map = MapData.fromJson(
        jsonDecode(
          File('test/fixtures/spatial_first_map/maps/first-map.json')
              .readAsStringSync(),
        ) as Map<String, dynamic>,
      );
      final document = EditableMapDocument(
        MapWorkspaceDocument(
          map: map.copyWith(entities: []),
          mapId: map.id,
          revision: 'test',
        ),
      );
      final view = MapEditingViewportSession();
      final controller = MapWorkspaceController(
        workspaceSession,
        WorkspaceMemoryPort(),
      );
      addTearDown(view.dispose);
      addTearDown(controller.dispose);
      controller.project = project;
      controller.active = document;
      controller.documents[document.current.id] = document;
      final model = project.models3d.first;
      expect(
        await useMapResource(
          workspace: controller,
          item: resourceCatalog(project)
              .singleWhere((item) => item.model3d?.id == model.id),
          view: () => view,
          isActive: () => true,
          chooseMap: (_) async => null,
          chooseTile: (_) async => null,
        ),
        isTrue,
      );
      expect(view.model3d, model);
      expect(view.tool, StudioMapTool.place);
      final visuals = _SpatialTestVisuals();
      Widget canvas() => MaterialApp(
        home: Scaffold(
          body: SpatialMapEditingViewport(
            document: document,
            controller: controller,
            project: project,
            visuals: visuals,
            view: view,
            onChanged: () {},
          ),
        ),
      );
      await tester.pumpWidget(canvas());
      final placement = tester.widget<SpatialSceneView>(
        find.byType(SpatialSceneView),
      );
      expect(placement.selectContent, isFalse);
      placement.onZoom!(-100);
      expect(view.scale, greaterThan(1));
      expect(placement.controller.zoom, closeTo(1 / view.scale, .00001));
      placement.onCell(3, 11);
      final added = document.current.spatialScene!.instances.last;
      expect(added.position.x, 3.5);
      expect(added.position.z, 11.5);
      view.tool = StudioMapTool.character;
      await tester.pumpWidget(canvas());
      expect(
        tester
            .widget<SpatialSceneView>(find.byType(SpatialSceneView))
            .selectContent,
        isFalse,
      );
      view.tool = StudioMapTool.select;
      await tester.pumpWidget(canvas());
      final selection = tester.widget<SpatialSceneView>(
        find.byType(SpatialSceneView),
      );
      expect(selection.selectContent, isTrue);
      expect(
        selection.onDragStart!(
          3,
          11,
          SpatialSceneContentHit(
            kind: SpatialSceneContentKind.model,
            id: added.id,
            cell: (3, 11),
          ),
        ),
        isTrue,
      );
      selection.onDragUpdate!((4, 11));
      selection.onDragEnd!();
      expect(document.current.spatialScene!.instances.last.position.x, 4.5);
      expect(document.current.spatialScene!.instances.last.position.z, 11.5);
      view.armMove(
        MapSelectionTarget(
          mapId: map.id,
          family: MapSelectionFamily.decor,
          id: added.id,
        ),
        'Déplacer',
      );
      expect(selection.onDragStart!(8, 11, null), isTrue);
      selection.onDragUpdate!((9, 11));
      selection.onDragEnd!();
      expect(document.current.spatialScene!.instances.last.position.x, 5.5);

      final commands = SpatialModelEditingCommands(document, project);
      commands.duplicate(added.id);
      final otherId = document.selectedId!;
      final firstHit = SpatialSceneContentHit(
        kind: SpatialSceneContentKind.model,
        id: added.id,
        cell: (5, 11),
      );
      selection.onContent!(firstHit);
      expect(document.selectedId, added.id);
      expect(selection.onDragStart!(5, 11, firstHit), isTrue);
      selection.onDragUpdate!((6, 11));
      selection.onDragEnd!();
      expect(commands.selected(added.id)!.position.x, 6.5);
      expect(commands.selected(otherId)!.position.x, 5.5);
      commands.update(added.id, x: 5.5);
      final npc = map.entities.first.copyWith(pos: const GridPos(x: 5, y: 11));
      document.commit(document.current.copyWith(entities: [npc]));
      selection.onContent!(
        SpatialSceneContentHit(
          kind: SpatialSceneContentKind.actor,
          id: 'npc:${npc.id}',
          cell: (5, 11),
        ),
      );
      expect(view.selectedFor(map.id, MapSelectionFamily.character), npc.id);
      expect(document.selectedId, isNull);
      final secondNpc = npc.copyWith(
        id: 'second-npc',
        pos: const GridPos(x: 6, y: 11),
      );
      document.commit(document.current.copyWith(entities: [npc, secondNpc]));
      view.armMove(
        MapSelectionTarget(
          mapId: map.id,
          family: MapSelectionFamily.character,
          id: npc.id,
        ),
        'Déplacer',
      );
      expect(
        selection.onDragStart!(
          6,
          11,
          SpatialSceneContentHit(
            kind: SpatialSceneContentKind.actor,
            id: 'npc:${secondNpc.id}',
            cell: (6, 11),
          ),
        ),
        isTrue,
      );
      selection.onDragUpdate!((7, 11));
      selection.onDragEnd!();
      expect(
        document.current.entities
            .firstWhere((entity) => entity.id == npc.id)
            .pos,
        const GridPos(x: 6, y: 11),
      );
      expect(
        document.current.entities
            .firstWhere((entity) => entity.id == secondNpc.id)
            .pos,
        const GridPos(x: 6, y: 11),
      );

      view.tool = StudioMapTool.eraseDecor;
      selection.onContent!(firstHit);
      expect(commands.selected(added.id), isNull);
      expect(commands.selected(otherId), isNotNull);
      view.tool = StudioMapTool.select;
      selection.onContent!(
        SpatialSceneContentHit(
          kind: SpatialSceneContentKind.model,
          id: otherId,
          cell: (5, 11),
        ),
      );
      view.transform.value = Matrix4.identity()..scaleByDouble(8, 8, 1, 1);
      expect(selection.controller.zoom, closeTo(.125, .00001));
      selection.onZoom!(-1000000);
      expect(view.scale, 8);
      expect(selection.controller.zoom, closeTo(.125, .00001));
      await tester.pumpWidget(const SizedBox());
    },
  );
  test(
    'empty spatial preview requires neither a hero nor a gameplay session',
    () async {
      final project = ProjectManifest.fromJson(
        jsonDecode(
          File('test/fixtures/spatial_first_map/project.json')
              .readAsStringSync(),
        ) as Map<String, dynamic>,
      );
      final map = MapData.fromJson(
        jsonDecode(
          File('test/fixtures/spatial_first_map/maps/first-map.json')
              .readAsStringSync(),
        ) as Map<String, dynamic>,
      );
      final resources = await StudioMapResources.load(
        ProjectSession(
          sessionId: 'preview',
          name: 'Preview',
          directoryPath: File('test/fixtures/spatial_first_map/project.json')
              .absolute
              .parent
              .path,
        ),
        project.copyWith(
          settings: project.settings.copyWith(defaultPlayerCharacterId: null),
          characters: [],
        ),
      );
      addTearDown(resources.dispose);
      final preview = await resources.spatialPreview(
        map.copyWith(entities: []),
      );
      expect(preview.frames, isEmpty);
      preview.dispose();
    },
  );
  test(
    'spatial models use decor catalog and canonical grounded editing history',
    () {
      final root = 'test/fixtures/spatial_first_map';
      final project = ProjectManifest.fromJson(
        jsonDecode(File('$root/project.json').readAsStringSync())
            as Map<String, dynamic>,
      );
      final map = MapData.fromJson(
        jsonDecode(File('$root/maps/first-map.json').readAsStringSync())
            as Map<String, dynamic>,
      );
      final document = EditableMapDocument(
        MapWorkspaceDocument(map: map, mapId: map.id, revision: 'test'),
      );
      final item = resourceCatalog(project)
          .where((item) => item.kind == ResourceKind.decors)
          .first;
      expect(item.model3d, isNotNull);
      expect(item.element, isNull);
      final commands = SpatialModelEditingCommands(document, project);
      final before = document.current;
      final instance = commands.place(item.model3d!, const GridPos(x: 3, y: 3));
      expect(document.selectedId, instance.id);
      expect(instance.position.y, map.spatialScene!.worldHeightAt(3.5, 3.5));
      commands.update(instance.id, x: 4.5, z: 4.5, rotation: 90, scale: 1.2);
      expect(
        commands.selected()!.position.y,
        map.spatialScene!.worldHeightAt(4.5, 4.5),
      );
      commands.duplicate(instance.id);
      expect(
        document.current.spatialScene!.instances.length,
        before.spatialScene!.instances.length + 2,
      );
      final duplicated = document.selectedId!;
      final target = locateMapContextTarget(
        document,
        project,
        MapContextFamily.decor,
        duplicated,
      )!;
      final context = MapContextActionContext(
        document: document,
        project: project,
        position: target.at,
      );
      expect(
        MapContextCommandRunner(context)
            .run(MapContextCommand.delete, target.target),
        isNull,
      );
      document.restore(redo: false);
      expect(
        document.current.spatialScene!.instances.length,
        before.spatialScene!.instances.length + 2,
      );
      expect(() => commands.update(instance.id, x: -1), throwsStateError);
      expect(
        document.current.spatialScene!.instances
            .firstWhere((v) => v.id == instance.id)
            .position
            .x,
        4.5,
      );
    },
  );
}

class _SpatialTestVisuals extends WorkspaceTestVisuals
    implements SpatialWorkspaceVisuals {
  @override
  Future<Uint8List> readGroundImage(String tilesetId) async => Uint8List(0);
  @override
  Future<Uint8List> readModel(String modelId) async => Uint8List(0);
  @override
  Future<SpatialNpcPreview> spatialPreview(MapData map) async =>
      SpatialNpcPreview({}, () {});
}
