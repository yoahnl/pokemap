import 'package:avelune_studio/features/map_workspace/application/editable_map_document.dart';
import 'package:avelune_studio/features/map_workspace/domain/map_workspace_port.dart';
import 'package:avelune_studio/presentation/features/map_workspace/map_workspace_canvas.dart';
import 'package:avelune_studio/presentation/features/map_workspace/map_workspace_view_state.dart';
import 'package:avelune_studio/presentation/theme/studio_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

import 'support/map_workspace_fixture.dart';
import 'terrain_creation_test.dart'
    show terrainDraft, assignAll, publishFixture;

class _PreviewVisuals extends WorkspaceTestVisuals {
  MapData? painted;
  @override
  Widget canvas(MapData map) {
    painted = map;
    return const SizedBox.expand();
  }
}

void main() {
  testWidgets(
    'canvas previews interpolated terrain, commits one history, erases neighbors and cancels',
    (tester) async {
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final draft = terrainDraft();
      assignAll(draft);
      final manifest = publishFixture(draft);
      final preset = manifest.smartTileCatalog.presets.single;
      final source = workspaceMap('a');
      final document = EditableMapDocument(
        MapWorkspaceDocument(map: source, revision: 'saved', mapId: 'a'),
      );
      final view = MapWorkspaceViewState()
        ..terrain = preset
        ..tool = StudioMapTool.terrain;
      addTearDown(view.dispose);
      final visuals = _PreviewVisuals();
      late StateSetter redraw;
      await tester.pumpWidget(
        MaterialApp(
          theme: studioTheme(),
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                redraw = setState;
                return MapWorkspaceCanvas(
                  document: document,
                  project: manifest,
                  visuals: visuals,
                  view: view,
                  onChanged: () => setState(() {}),
                  gestureGeneration: 0,
                );
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      Offset cell(int x, int y) =>
          tester.getTopLeft(find.byKey(const ValueKey('map-canvas'))) +
          Offset(x * 32 + 12, y * 32 + 12);
      final gesture = await tester.startGesture(cell(2, 2));
      await gesture.moveTo(cell(6, 2));
      await tester.pump();
      expect(document.current, source);
      final preview = visuals.painted!.layers
          .whereType<SmartTileLayer>()
          .single;
      expect(
        smartTileSemanticCells(preview).where((value) => value != 0),
        hasLength(5),
      );
      await gesture.up();
      await tester.pumpAndSettle();
      expect(document.error, isNull);
      expect(document.undoCount, 1);
      final painted = document.current;
      document.restore(redo: false);
      expect(document.current, source);
      document.restore(redo: true);
      expect(document.current, painted);
      redraw(() => view.tool = StudioMapTool.erase);
      await tester.pump();
      final erase = await tester.startGesture(cell(3, 2));
      await erase.moveTo(cell(4, 2));
      await erase.up();
      await tester.pumpAndSettle();
      expect(document.undoCount, 2);
      final erased = document.current.layers.whereType<SmartTileLayer>().single;
      expect(
        smartTileSemanticCells(erased).where((value) => value != 0),
        hasLength(3),
      );
      final edge = resolveSmartTile(
        preset: preset,
        materials: manifest.smartTileCatalog.materials,
        context: smartTileCellContextForLayerCell(
          layer: erased,
          map: document.current,
          preset: preset,
          x: 2,
          y: 2,
        ),
        x: 2,
        y: 2,
      );
      expect(edge.ruleId, 'connection-0');
      final beforeCancel = document.current;
      redraw(() => view.tool = StudioMapTool.terrain);
      await tester.pump();
      final cancel = await tester.startGesture(cell(7, 7));
      await cancel.moveTo(cell(10, 7));
      await cancel.cancel();
      await tester.pumpAndSettle();
      expect(document.current, beforeCancel);
      expect(document.undoCount, 2);
      expect(tester.takeException(), isNull);
    },
  );
}
