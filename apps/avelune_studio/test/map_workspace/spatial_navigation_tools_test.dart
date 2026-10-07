import 'package:avelune_studio/features/map_workspace/application/editable_map_document.dart';
import 'package:avelune_studio/features/map_workspace/application/map_workspace_controller.dart';
import 'package:avelune_studio/features/map_workspace/domain/map_workspace_port.dart';
import 'package:avelune_studio/presentation/features/map_workspace/map_workspace_view_state.dart';
import 'package:avelune_studio/presentation/features/map_workspace/map_workspace_visuals.dart';
import 'package:avelune_studio/presentation/features/map_workspace/spatial_map_editor.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_render_3d/map_render_3d.dart';
import '../support/map_workspace_fixture.dart';

void main() {
  final project = workspaceProject.copyWith(
    version: ProjectVersion.v9,
    settings: const ProjectSettings(dimension: ProjectDimension.threeD),
    maps: const [
      ProjectMapEntry(id: 'a', name: 'A', relativePath: 'maps/a.json'),
      ProjectMapEntry(id: 'b', name: 'B', relativePath: 'maps/b.json'),
    ],
  );
  testWidgets('shared spawn, collision and passage gestures edit a 3D map', (
    tester,
  ) async {
    final map = MapData(
      id: 'a',
      name: 'A',
      version: ProjectVersion.v9,
      size: const GridSize(width: 6, height: 5),
      spatialScene: MapSpatialScene(width: 6, depth: 5),
    );
    final document = EditableMapDocument(
      MapWorkspaceDocument(map: map, mapId: map.id, revision: 'navigation'),
    );
    final controller = MapWorkspaceController(
      workspaceSession,
      WorkspaceMemoryPort(),
    );
    final view = MapWorkspaceViewState()..tool = StudioMapTool.spawn;
    addTearDown(view.dispose);
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) => SpatialMapEditor(
              document: document,
              controller: controller,
              project: project,
              visuals: _Visuals(),
              view: view,
              onChanged: () => setState(() {}),
            ),
          ),
        ),
      ),
    );
    SpatialSceneView scene() => tester.widget(find.byType(SpatialSceneView));
    scene().onCell(1, 3);
    await tester.pump();
    final spawn = document.current.entities.single;
    expect(spawn.kind, MapEntityKind.spawn);
    expect(spawn.pos, const GridPos(x: 1, y: 3));
    expect(view.selectedFor('a', MapSelectionFamily.marker), spawn.id);
    expect(
      scene().cellOverlays.singleWhere((cell) => cell.id == spawn.id).kind.name,
      'spawn',
    );
    view.tool = StudioMapTool.collisionPaint;
    await tester.pump();
    expect(scene().onDragStart!(2, 2, null), isTrue);
    scene().onDragUpdate!((4, 2));
    expect(document.current.layers, isEmpty);
    scene().onDragEnd!();
    await tester.pump();
    final layer = document.current.layers.whereType<CollisionLayer>().single;
    expect(layer.collisions.where((cell) => cell).length, 3);
    expect(
      scene().cellOverlays
          .where((cell) => cell.kind.name == 'collision')
          .length,
      3,
    );
    expect(document.undoCount, 2);
    document.restore(redo: false);
    expect(document.current.layers, isEmpty);
    document.restore(redo: true);
    view.tool = StudioMapTool.collisionErase;
    await tester.pump();
    scene().onCell(3, 2);
    await tester.pump();
    expect(
      (document.current.layers.single as CollisionLayer).collisions[15],
      isFalse,
    );
    view
      ..tool = StudioMapTool.warp
      ..warpDestination = project.maps.last;
    await tester.pump();
    scene().onCell(5, 3);
    await tester.pump();
    final warp = document.current.warps.single;
    expect(warp.targetMapId, 'b');
    expect(warp.pos, const GridPos(x: 5, y: 3));
    expect(view.selectedFor('a', MapSelectionFamily.warp), warp.id);
    expect(
      scene().cellOverlays.singleWhere((cell) => cell.id == warp.id).kind.name,
      'warp',
    );
    view.tool = StudioMapTool.select;
    await tester.pump();
    scene().onCell(1, 3);
    await tester.pump();
    expect(view.selectedFor('a', MapSelectionFamily.marker), spawn.id);
    scene().onCell(5, 3);
    await tester.pump();
    expect(view.selectedFor('a', MapSelectionFamily.warp), warp.id);
    final undo = document.undoCount;
    expect(
      scene().onDragStart!(
        5,
        3,
        SpatialSceneContentHit(
          kind: SpatialSceneContentKind.warp,
          id: warp.id,
          cell: (5, 3),
        ),
      ),
      isTrue,
    );
    scene().onDragUpdate!((4, 4));
    await tester.pump();
    expect(document.current.warps.single.pos, const GridPos(x: 5, y: 3));
    expect(
      scene().cellOverlays.singleWhere((cell) => cell.id == warp.id).cell,
      (4, 4),
    );
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pump();
    expect(document.undoCount, undo);
    expect(
      scene().cellOverlays.singleWhere((cell) => cell.id == warp.id).cell,
      (5, 3),
    );
    scene().onContent!(
      SpatialSceneContentHit(
        kind: SpatialSceneContentKind.marker,
        id: spawn.id,
        cell: (1, 3),
      ),
    );
    await tester.pump();
    await tester.sendKeyDownEvent(LogicalKeyboardKey.arrowRight);
    await tester.pump();
    expect(document.current.entities.single.pos, const GridPos(x: 1, y: 3));
    expect(
      scene().cellOverlays.singleWhere((cell) => cell.id == spawn.id).cell,
      (2, 3),
    );
    await tester.sendKeyUpEvent(LogicalKeyboardKey.arrowRight);
    await tester.pump();
    expect(document.current.entities.single.pos, const GridPos(x: 2, y: 3));
    expect(document.undoCount, undo + 1);
    view.pendingMove = MapSelectionTarget(
      mapId: 'a',
      family: MapSelectionFamily.marker,
      id: spawn.id,
    );
    expect(
      scene().onDragStart!(
        5,
        3,
        SpatialSceneContentHit(
          kind: SpatialSceneContentKind.warp,
          id: warp.id,
          cell: (5, 3),
        ),
      ),
      isTrue,
    );
    scene().onDragUpdate!((4, 3));
    scene().onDragEnd!();
    await tester.pump();
    expect(document.current.entities.single.pos, const GridPos(x: 1, y: 3));
    expect(document.current.warps.single.pos, const GridPos(x: 5, y: 3));
    expect(MapData.fromJson(document.current.toJson()), document.current);
  });
}

class _Visuals extends WorkspaceTestVisuals implements SpatialWorkspaceVisuals {
  @override
  Future<Uint8List> readGroundImage(String id) async => Uint8List(0);
  @override
  Future<Uint8List> readModel(String id) async => Uint8List(0);
  @override
  Future<SpatialNpcPreview> spatialPreview(MapData map) async =>
      SpatialNpcPreview({}, () {});
}
