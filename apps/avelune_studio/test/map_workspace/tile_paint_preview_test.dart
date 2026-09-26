import 'package:avelune_studio/features/map_workspace/application/editable_map_document.dart';
import 'package:avelune_studio/features/map_workspace/domain/map_workspace_port.dart';
import 'package:avelune_studio/features/map_workspace/application/map_editing_commands.dart';
import 'package:avelune_studio/presentation/features/map_workspace/map_canvas_stroke.dart';
import 'package:avelune_studio/presentation/features/map_workspace/map_workspace_canvas.dart';
import 'package:avelune_studio/presentation/features/map_workspace/map_workspace_view_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

import '../support/map_workspace_fixture.dart';

void main() {
  test('repeated pointer events in one cell do not rematerialize the map', () {
    final document = EditableMapDocument(
      MapWorkspaceDocument(
        map: workspaceMap('a'),
        revision: 'base',
        mapId: 'a',
      ),
    );
    final view = MapWorkspaceViewState()
      ..tool = StudioMapTool.paint
      ..tile = const TileLayerPaletteEntry(tilesetId: 'atlas', localTileId: 0);
    addTearDown(view.dispose);
    final stroke = MapCanvasStroke.start(
      map: document.current,
      project: workspaceProject,
      view: view,
      commands: MapEditingCommands(document, workspaceProject),
      origin: const GridPos(x: 2, y: 2),
    )!;
    expect(stroke.buffer.mapMaterializationCount, 1);
    stroke.paint(const GridPos(x: 2, y: 2));
    expect(stroke.buffer.mapMaterializationCount, 1);
    stroke.paint(const GridPos(x: 3, y: 2));
    expect(stroke.buffer.mapMaterializationCount, 2);
  });

  testWidgets(
    'tile stroke is visible while dragging and commits once on release',
    (tester) async {
      final document = EditableMapDocument(
        MapWorkspaceDocument(
          map: workspaceMap('a'),
          revision: 'base',
          mapId: 'a',
        ),
      );
      final view = MapWorkspaceViewState()
        ..tool = StudioMapTool.paint
        ..tile = const TileLayerPaletteEntry(
          tilesetId: 'atlas',
          localTileId: 0,
        );
      final visuals = _RecordingVisuals();
      addTearDown(view.dispose);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MapWorkspaceCanvas(
              document: document,
              project: workspaceProject,
              visuals: visuals,
              view: view,
              onChanged: () {},
              gestureGeneration: 0,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final canvas = tester.renderObject<RenderBox>(
        find.byKey(const ValueKey('map-canvas')),
      );
      Offset cell(int x, int y) =>
          canvas.localToGlobal(Offset(x * 32 + 16, y * 32 + 16));
      final gesture = await tester.startGesture(cell(2, 2));
      await tester.pump();
      await gesture.moveTo(cell(4, 2));
      await tester.pump();
      expect(document.current.layers.whereType<TileLayer>().first.cells[44], 0);
      expect(visuals.lastMap!.layers.whereType<TileLayer>().first.cells[44], 1);
      await gesture.up();
      await tester.pump();
      expect(document.current.layers.whereType<TileLayer>().first.cells[44], 1);
      expect(document.undoCount, 1);
      document.restore(redo: false);
      expect(document.current.layers.whereType<TileLayer>().first.cells[44], 0);
    },
  );
}

class _RecordingVisuals extends WorkspaceTestVisuals {
  MapData? lastMap;

  @override
  Widget canvas(MapData map) {
    lastMap = map;
    return const SizedBox.expand();
  }
}
