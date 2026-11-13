import 'dart:async';
import 'dart:typed_data';

import 'package:avelune_studio/features/map_workspace/application/editable_map_document.dart';
import 'package:avelune_studio/features/map_workspace/application/map_exterior_decoration_controller.dart';
import 'package:avelune_studio/features/map_workspace/application/map_workspace_controller.dart';
import 'package:avelune_studio/features/map_workspace/domain/map_exterior_decoration_port.dart';
import 'package:avelune_studio/features/map_workspace/domain/map_workspace_port.dart';
import 'package:avelune_studio/features/project_session/domain/project_session.dart';
import 'package:avelune_studio/features/map_workspace/coordination/spatial_map_neighbor_session.dart';
import 'package:avelune_studio/features/map_workspace/coordination/map_editing_viewport_session.dart';
import 'package:avelune_studio/features/rendering/contracts/map_workspace_visuals.dart';
import 'package:avelune_studio/platform/rendering/viewports/spatial_map_editing_viewport.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_render_3d/map_render_3d.dart';

import '../support/map_workspace_fixture.dart';

void main() {
  testWidgets(
    'real neighbor previews retain their scope and cached inputs during exterior edits',
    (tester) async {
      final a = MapData(
        id: 'a',
        name: 'A',
        version: ProjectVersion.v9,
        size: const GridSize(width: 4, height: 4),
        spatialScene: MapSpatialScene(width: 4, depth: 4),
        connections: const [
          MapConnection(
            direction: MapConnectionDirection.east,
            targetMapId: 'b',
            offset: 1,
          ),
        ],
      );
      final b = MapData(
        id: 'b',
        name: 'B',
        version: ProjectVersion.v9,
        size: const GridSize(width: 2, height: 2),
        spatialScene: MapSpatialScene(width: 2, depth: 2),
      );
      final port = _PreviewPort(b);
      final exterior =
          await MapExteriorDecorationController.open(workspaceSession, a, port)
            ..setEditingExterior(true);
      final document = EditableMapDocument(
        MapWorkspaceDocument(map: a, mapId: 'a', revision: 'r0'),
      )..exteriorDecoration = exterior;
      final controller = MapWorkspaceController(workspaceSession, port)
        ..project = workspaceProject
        ..active = document;
      final view = MapEditingViewportSession();
      final neighbors = SpatialMapNeighborSession();
      addTearDown(neighbors.dispose);
      final visuals = _SpatialVisuals();
      addTearDown(exterior.dispose);
      addTearDown(view.dispose);
      addTearDown(controller.dispose);
      Widget pane() {
        neighbors.refresh(
          controller: controller,
          map: document.current,
          project: workspaceProject,
          visuals: visuals,
        );
        return MaterialApp(
          home: Scaffold(
            body: ListenableBuilder(
              listenable: neighbors,
              builder: (_, _) => SpatialMapEditingViewport(
                controller: controller,
                document: document,
                project: workspaceProject,
                visuals: visuals,
                view: view,
                neighbors: neighbors.neighbors,
                neighborDecorations: neighbors.decorations,
                exteriorContextReady: neighbors.ready,
                onChanged: () {},
              ),
            ),
          ),
        );
      }

      SpatialMapEditingViewport canvas() =>
          tester.widget<SpatialMapEditingViewport>(
            find.byType(SpatialMapEditingViewport),
          );
      await tester.pumpWidget(pane());
      for (var i = 0; i < 5 && canvas().neighbors.isEmpty; i++) {
        await tester.pump();
      }
      expect(port.previewReads, ['b']);
      expect(port.decorations, ['a', 'b']);
      expect(controller.project, same(workspaceProject));
      expect(controller.active, same(document));
      expect(
        controller.previewDefinitionsFor('b')?.tilesets.single.id,
        'neighbor-only',
      );
      expect(canvas().neighbors.single.offset, const Offset(4, 1));
      expect(
        canvas().neighbors.single.project?.tilesets.single.id,
        'neighbor-only',
      );
      final initialNeighbors = canvas().neighbors;
      final decorations = canvas().neighborDecorations;
      final scene = tester.widget<SpatialSceneView>(
        find.byType(SpatialSceneView),
      );
      expect(scene.resolveAuthoringTarget!(4, 1), isNull);
      expect(scene.resolveAuthoringTarget!(-1, -1), isNotNull);
      await tester.pumpWidget(pane());
      expect(canvas().neighbors, same(initialNeighbors));
      expect(canvas().neighborDecorations, same(decorations));
      expect(port.previewReads, ['b']);
      expect(port.decorations, ['a', 'b']);
      await tester.pumpWidget(const SizedBox());
    },
  );

  for (final disposed in [false, true]) {
    test(
      'late neighbor result is ignored after ${disposed ? 'disposal' : 'map switch'}',
      () async {
        final a = _connectedMap();
        final b = _neighborMap();
        final port = _PreviewPort(b)..gate = Completer<void>();
        final controller = MapWorkspaceController(workspaceSession, port)
          ..project = workspaceProject;
        final session = SpatialMapNeighborSession();
        final visuals = _SpatialVisuals();
        addTearDown(controller.dispose);
        addTearDown(session.dispose);
        var publications = 0;
        session.addListener(() => publications++);
        session.refresh(
          map: a,
          controller: controller,
          project: workspaceProject,
          visuals: visuals,
        );
        expect(session.loading, isTrue);
        if (disposed) {
          session.dispose();
        } else {
          session.refresh(
            map: b,
            controller: controller,
            project: workspaceProject,
            visuals: visuals,
          );
          expect(session.ready, isTrue);
        }
        port.gate!.complete();
        await Future<void>.delayed(Duration.zero);
        expect(session.neighbors, isEmpty);
        expect(session.decorations, isEmpty);
        expect(publications, 0);
      },
    );
  }

  test('neighbor failure is published and a changed request retries', () async {
    final port = _PreviewPort(_neighborMap())..fail = true;
    final controller = MapWorkspaceController(workspaceSession, port)
      ..project = workspaceProject;
    final session = SpatialMapNeighborSession();
    final visuals = _SpatialVisuals();
    addTearDown(controller.dispose);
    addTearDown(session.dispose);
    session.refresh(
      map: _connectedMap(),
      controller: controller,
      project: workspaceProject,
      visuals: visuals,
    );
    await Future<void>.delayed(Duration.zero);
    expect(session.failure, isA<StateError>());
    expect(session.loading, isFalse);
    expect(session.ready, isFalse);
    port.fail = false;
    session.refresh(
      map: _connectedMap(),
      controller: controller,
      project: workspaceProject.copyWith(name: 'Retry'),
      visuals: visuals,
    );
    await Future<void>.delayed(Duration.zero);
    expect(session.failure, isNull);
    expect(session.ready, isTrue);
    expect(session.neighbors.single.map.id, 'b');
    expect(port.previewReads, ['b', 'b']);
  });
}

MapData _connectedMap() => MapData(
  id: 'a',
  name: 'A',
  version: ProjectVersion.v9,
  size: const GridSize(width: 4, height: 4),
  spatialScene: MapSpatialScene(width: 4, depth: 4),
  connections: const [
    MapConnection(
      direction: MapConnectionDirection.east,
      targetMapId: 'b',
      offset: 1,
    ),
  ],
);

MapData _neighborMap() => MapData(
  id: 'b',
  name: 'B',
  version: ProjectVersion.v9,
  size: const GridSize(width: 2, height: 2),
  spatialScene: MapSpatialScene(width: 2, depth: 2),
);

final class _PreviewPort extends WorkspaceMemoryPort
    implements MapWorkspacePreviewSelectionPort, MapExteriorDecorationPort {
  _PreviewPort(this.map);
  final MapData map;
  Completer<void>? gate;
  bool fail = false;
  final previewReads = <String>[], decorations = <String>[];
  @override
  Future<MapWorkspaceSelection> loadMapPreviewSelection(
    ProjectSession session,
    ProjectMapEntry entry,
  ) async {
    previewReads.add(entry.id);
    await gate?.future;
    if (fail) throw StateError('Preview failed');
    return MapWorkspaceSelection(
      document: MapWorkspaceDocument(map: map, revision: 'r0', mapId: map.id),
      definitions: workspaceProject.copyWith(
        tilesets: const [
          ProjectTilesetEntry(
            id: 'neighbor-only',
            name: 'Neighbor',
            relativePath: 'neighbor.png',
          ),
        ],
      ),
      catalogRevision: 'r0',
      snapshotRevision: 'r0',
    );
  }

  @override
  Future<MapWorkspaceDocument> loadMap(
    ProjectSession session,
    ProjectMapEntry entry,
  ) async => throw StateError('A preview must use the neutral selection path.');
  @override
  Future<MapExteriorDecorationState> loadExteriorDecoration(
    ProjectSession session,
    String mapId,
  ) async {
    decorations.add(mapId);
    return const MapExteriorDecorationState(decoration: null, revision: 'r0');
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnsupportedError(invocation.memberName.toString());
}

final class _SpatialVisuals extends WorkspaceTestVisuals
    implements SpatialWorkspaceVisuals {
  @override
  Future<Uint8List> readModel(String id) async => Uint8List(0);
  @override
  Future<Uint8List> readGroundImage(String id) async => Uint8List(0);
  @override
  Future<SpatialNpcPreview> spatialPreview(MapData map) async =>
      SpatialNpcPreview({}, () {});
}
