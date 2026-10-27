import 'dart:typed_data';

import 'package:avelune_studio/features/map_workspace/application/editable_map_document.dart';
import 'package:avelune_studio/features/map_workspace/application/map_exterior_decoration_controller.dart';
import 'package:avelune_studio/features/map_workspace/application/map_workspace_controller.dart';
import 'package:avelune_studio/features/map_workspace/domain/map_exterior_decoration_port.dart';
import 'package:avelune_studio/features/map_workspace/domain/map_workspace_port.dart';
import 'package:avelune_studio/features/project_session/domain/project_session.dart';
import 'package:avelune_studio/presentation/features/map_workspace/map_workspace_editor_pane.dart';
import 'package:avelune_studio/presentation/features/map_workspace/map_workspace_view_state.dart';
import 'package:avelune_studio/presentation/features/map_workspace/map_workspace_visuals.dart';
import 'package:avelune_studio/presentation/features/map_workspace/spatial_map_editor.dart';
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
      final view = MapWorkspaceViewState();
      final visuals = _SpatialVisuals();
      final search = TextEditingController();
      addTearDown(search.dispose);
      addTearDown(exterior.dispose);
      addTearDown(view.dispose);
      addTearDown(controller.dispose);
      Widget pane() => MaterialApp(
        home: Scaffold(
          body: MapWorkspaceEditorPane(
            controller: controller,
            document: document,
            project: workspaceProject,
            visuals: visuals,
            view: view,
            search: search,
            generation: 0,
            showNavigator: false,
            showToolStrip: false,
            showPaletteDock: false,
            inspector: null,
            onActivate: (_) {},
            onOrganizeMaps: null,
            onToolChanged: () {},
            onChanged: () {},
            onMoreTools: () {},
            onResources: () {},
            onZoneDrawn: null,
            onContextMenu: null,
          ),
        ),
      );
      SpatialMapEditor canvas() =>
          tester.widget<SpatialMapEditor>(find.byType(SpatialMapEditor));
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
      final neighbors = canvas().neighbors;
      final decorations = canvas().neighborDecorations;
      final scene = tester.widget<SpatialSceneView>(
        find.byType(SpatialSceneView),
      );
      expect(scene.resolveAuthoringTarget!(4, 1), isNull);
      expect(scene.resolveAuthoringTarget!(-1, -1), isNotNull);
      await tester.pumpWidget(pane());
      expect(canvas().neighbors, same(neighbors));
      expect(canvas().neighborDecorations, same(decorations));
      expect(port.previewReads, ['b']);
      expect(port.decorations, ['a', 'b']);
      await tester.pumpWidget(const SizedBox());
    },
  );
}

final class _PreviewPort extends WorkspaceMemoryPort
    implements MapWorkspacePreviewSelectionPort, MapExteriorDecorationPort {
  _PreviewPort(this.map);
  final MapData map;
  final previewReads = <String>[], decorations = <String>[];
  @override
  Future<MapWorkspaceSelection> loadMapPreviewSelection(
    ProjectSession session,
    ProjectMapEntry entry,
  ) async {
    previewReads.add(entry.id);
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
