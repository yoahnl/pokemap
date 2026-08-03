import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/editor/presentation/world_map/world_map_layer_hover_preview.dart';
import 'package:map_editor/src/features/editor/state/editor_notifier.dart';
import 'package:map_editor/src/features/editor/state/editor_state.dart';
import 'package:map_editor/src/ui/canvas/map_canvas.dart';

import '../../shell_chrome_test_harness.dart';

void main() {
  test('highlight painter colors occupied cells only', () async {
    const tileSize = 16.0;
    const painter = TileLayerHoverHighlightPainter(
      layer: TileLayer(
        id: 'tiles',
        name: 'Tiles',
        tiles: <int>[1, 0],
      ),
      mapSize: GridSize(width: 2, height: 1),
      zoom: 1,
      offset: Offset.zero,
      tileWidth: tileSize,
      tileHeight: tileSize,
      color: Color(0xFF4C8DFF),
    );
    final recorder = ui.PictureRecorder();
    painter.paint(
      ui.Canvas(recorder),
      const ui.Size(tileSize * 2, tileSize),
    );
    final picture = recorder.endRecording();
    final image = await picture.toImage(32, 16);
    final pixels = await image.toByteData(format: ui.ImageByteFormat.rawRgba);

    expect(pixels!.getUint8((8 * 32 + 8) * 4 + 3), greaterThan(0));
    expect(pixels.getUint8((8 * 32 + 24) * 4 + 3), 0);

    image.dispose();
    picture.dispose();
  });

  testWidgets('canvas previews only the hovered tile layer', (tester) async {
    final map = buildShellChromeMap(
      width: 2,
      height: 2,
      layers: const <MapLayer>[
        TileLayer(
          id: 'tiles',
          name: 'Tiles',
          tiles: <int>[1, 0, 0, 1],
        ),
        CollisionLayer(
          id: 'collision',
          name: 'Collision',
          collisions: <bool>[true, false, false, true],
        ),
      ],
    );
    final container = await pumpEditorCanvasHostHarness(
      tester,
      initialState: EditorState(
        project: buildShellChromeProject(),
        workspaceMode: EditorWorkspaceMode.map,
        activeMap: map,
        activeLayerId: 'tiles',
        savedMapSnapshot: map,
      ),
    );
    const overlayKey = ValueKey<String>(
      'map-canvas-tile-layer-hover-highlight',
    );

    expect(find.byKey(overlayKey), findsNothing);

    container.read(worldMapHoveredTileLayerIdProvider.notifier).show('tiles');
    await tester.pump();

    expect(find.byKey(overlayKey), findsOneWidget);

    container
        .read(worldMapHoveredTileLayerIdProvider.notifier)
        .show('collision');
    await tester.pump();

    expect(find.byKey(overlayKey), findsNothing);
    expect(container.read(worldMapHoveredTileLayerIdProvider), 'collision');
    expect(container.read(editorNotifierProvider).activeMap, same(map));
    expect(container.read(editorNotifierProvider).mapUndoStack, isEmpty);
  });
}
