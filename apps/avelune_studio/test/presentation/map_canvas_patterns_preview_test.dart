import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:avelune_studio/features/map_workspace/application/editable_map_document.dart';
import 'package:avelune_studio/features/map_workspace/application/map_editing_commands.dart';
import 'package:avelune_studio/features/map_workspace/application/map_workspace_controller.dart';
import 'package:avelune_studio/features/map_workspace/data/local_map_workspace_adapter.dart';
import 'package:avelune_studio/features/map_workspace/domain/map_workspace_port.dart';
import 'package:avelune_studio/features/project_session/domain/project_session.dart';
import 'package:avelune_studio/features/map_workspace/application/map_canvas_stroke.dart';
import 'package:avelune_studio/features/map_workspace/coordination/map_editing_viewport_session.dart';
import 'package:avelune_studio/features/rendering/contracts/map_workspace_visuals.dart';
import 'package:avelune_studio/platform/rendering/viewports/spatial_map_editing_viewport.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_render_3d/map_render_3d.dart';

import '../support/map_workspace_fixture.dart';
import 'map_canvas_patterns_fixtures.dart';

void main() {
  for (final spatial in [false, true]) {
    for (final mode in SmartTilePatternSelectionKind.values) {
      test(
        '${spatial ? "3D" : "2D"} ${mode.name} previews one stable pattern and commits one exact undo',
        () {
          final fixture = patternFixture(spatial: spatial);
          final source = fixture.map;
          final view = MapEditingViewportSession()
            ..prepareTerrainPainting(fixture.preset)
            ..selectTerrainPattern(fixture.pattern)
            ..terrainPatternMode = mode;
          addTearDown(view.dispose);
          final material = view.terrainMaterialId;
          final document = EditableMapDocument(
            MapWorkspaceDocument(map: source, mapId: source.id, revision: 'r0'),
          );
          final stroke = MapCanvasStroke.start(
            map: source,
            project: fixture.project,
            view: view,
            commands: MapEditingCommands(document, fixture.project),
            origin: const GridPos(x: 0, y: 0),
          )!;
          stroke.paint(const GridPos(x: 3, y: 2));
          stroke.paint(const GridPos(x: 1, y: 1));
          final strokes = stroke.preview.layers
              .whereType<SmartTileLayer>()
              .single
              .patternStrokes;
          expect(strokes, hasLength(2));
          expect(
            strokes.first,
            source.layers
                .whereType<SmartTileLayer>()
                .single
                .patternStrokes
                .single,
          );
          expect(
            strokes.last.cells,
            hasLength(switch (mode) {
              SmartTilePatternSelectionKind.stamp => 2,
              SmartTilePatternSelectionKind.line => 2,
              SmartTilePatternSelectionKind.rectangle => 4,
            }),
          );
          expect(strokes.last.phaseX, 0);
          expect(strokes.last.phaseY, 0);
          expect(
            smartTileSemanticCells(
              stroke.preview.layers.whereType<SmartTileLayer>().single,
            ),
            everyElement(0),
          );
          expect(view.terrainMaterialId, material);
          expect(document.current, same(source));
          document.commit(stroke.commit());
          expect(document.current, stroke.preview);
          expect(document.undoCount, 1);
          expect(
            document.current.spatialScene?.instances,
            spatial ? isEmpty : isNull,
          );
          document.restore(redo: false);
          expect(document.current, source);
          document.restore(redo: true);
          expect(document.current, stroke.preview);
        },
      );
    }
  }

  testWidgets(
    'native pattern drag previews without writing and cancels when selection changes',
    (tester) async {
      final fixture = patternFixture();
      final document = EditableMapDocument(
        MapWorkspaceDocument(
          map: fixture.map,
          mapId: fixture.map.id,
          revision: 'r0',
        ),
      );
      final view = MapEditingViewportSession()
        ..prepareTerrainPainting(fixture.preset)
        ..selectTerrainPattern(fixture.pattern)
        ..terrainPatternMode = SmartTilePatternSelectionKind.rectangle;
      final controller = MapWorkspaceController(
        workspaceSession,
        WorkspaceMemoryPort(),
      );
      addTearDown(view.dispose);
      addTearDown(controller.dispose);
      Widget canvas() => MaterialApp(
        home: Scaffold(
          body: SpatialMapEditingViewport(
            document: document,
            controller: controller,
            project: fixture.project,
            visuals: _PatternVisuals(),
            view: view,
            onChanged: () {},
          ),
        ),
      );
      await tester.pumpWidget(canvas());
      var scene = tester.widget<SpatialSceneView>(
        find.byType(SpatialSceneView),
      );
      expect(scene.onDragStart!(0, 0, null), isTrue, reason: document.error);
      scene.onDragUpdate!((1, 1));
      expect(document.current, same(fixture.map));
      view.selectTerrainPattern(null);
      await tester.pumpWidget(canvas());
      scene.onDragEnd!();
      expect(document.current, same(fixture.map));
      expect(document.canUndo, isFalse);
      view.selectTerrainPattern(fixture.pattern);
      await tester.pumpWidget(canvas());
      scene = tester.widget<SpatialSceneView>(find.byType(SpatialSceneView));
      expect(scene.onDragStart!(0, 0, null), isTrue);
      scene.onDragUpdate!((1, 1));
      scene.onDragEnd!();
      expect(document.undoCount, 1);
      expect(
        document.current.layers
            .whereType<SmartTileLayer>()
            .single
            .patternStrokes,
        hasLength(2),
      );
      view.tool = StudioMapTool.erase;
      await tester.pumpWidget(canvas());
      scene = tester.widget<SpatialSceneView>(find.byType(SpatialSceneView));
      expect(scene.onDragStart!(0, 0, null), isTrue);
      scene.onDragEnd!();
      expect(
        document.current.layers
            .whereType<SmartTileLayer>()
            .single
            .patternStrokes
            .last
            .cells,
        hasLength(3),
      );
      document.restore(redo: false);
      expect(
        document.current.layers
            .whereType<SmartTileLayer>()
            .single
            .patternStrokes
            .last
            .cells,
        hasLength(4),
      );
      await tester.pumpWidget(const SizedBox());
      expect(tester.takeException(), isNull);
    },
  );

  test(
    'native pattern stamp and erase survive Studio save then reopen',
    () async {
      final fixture = patternFixture();
      final directory = await Directory.systemTemp.createTemp(
        'studio-pattern-save-',
      );
      addTearDown(() => directory.delete(recursive: true));
      final project = fixture.project.copyWith(
        maps: [
          const ProjectMapEntry(
            id: 'a',
            name: 'Eau native',
            relativePath: 'map.json',
          ),
        ],
      );
      await File('${directory.path}/project.json')
          .writeAsString(jsonEncode(project.toJson()));
      await File('${directory.path}/map.json')
          .writeAsString(jsonEncode(fixture.map.toJson()));
      final session = ProjectSession(
        sessionId: 'pattern',
        name: project.name,
        directoryPath: await directory.resolveSymbolicLinks(),
      );
      final port = LocalMapWorkspaceAdapter();
      await port.loadProject(session);
      final opened = await port.loadMap(session, project.maps.single);
      final document = EditableMapDocument(opened);
      final view = MapEditingViewportSession()
        ..prepareTerrainPainting(fixture.preset)
        ..selectTerrainPattern(fixture.pattern);
      addTearDown(view.dispose);
      final stroke = MapCanvasStroke.start(
        map: document.current,
        project: project,
        view: view,
        commands: MapEditingCommands(document, project),
        origin: const GridPos(x: 0, y: 0),
      )!;
      document.commit(stroke.commit());
      final stamped = document.current;
      final revision = await port.saveMap(session, document.base, stamped);
      document.acceptSave(stamped, revision);
      view.tool = StudioMapTool.erase;
      final erased = MapCanvasStroke.start(
        map: stamped,
        project: project,
        view: view,
        commands: MapEditingCommands(document, project),
        origin: const GridPos(x: 3, y: 2),
      )!.commit();
      document.commit(erased);
      await port.saveMap(session, document.base, erased);
      final fresh = LocalMapWorkspaceAdapter();
      await fresh.loadProject(session);
      final reopened = await fresh.loadMap(session, project.maps.single);
      expect(reopened.map, erased);
      expect(
        resolveSpatialSmartTileInstances(
          map: reopened.map,
          catalog: project.smartTileCatalog,
        ),
        resolveSpatialSmartTileInstances(
          map: erased,
          catalog: project.smartTileCatalog,
        ),
      );
      expect(reopened.map.spatialScene!.instances, isEmpty);
      document.restore(redo: false);
      expect(document.current, stamped);
    },
  );
}

class _PatternVisuals extends WorkspaceTestVisuals
    implements SpatialWorkspaceVisuals {
  final source = Completer<Uint8List>();
  @override
  Future<Uint8List> readModel(String modelId) => source.future;
  @override
  Future<Uint8List> readGroundImage(String tilesetId) async => Uint8List(0);
  @override
  Future<SpatialNpcPreview> spatialPreview(MapData map) async =>
      SpatialNpcPreview({}, () {});
}
