import 'dart:typed_data';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:map_editor/src/features/surface_studio/atlas/surface_studio_atlas_panel.dart';
import 'package:map_editor/src/features/surface_studio/surface_studio_column_selection.dart';

void main() {
  testWidgets(
      'atlas viewport hit testing uses fitted image rect, not viewport width',
      (tester) async {
    var selection = const SurfaceStudioColumnSelection.empty();

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Center(
          child: SizedBox(
            width: 600,
            height: 460,
            child: SurfaceStudioAtlasViewport(
              columnCount: 23,
              frameCount: 32,
              tileWidth: 32,
              tileHeight: 32,
              atlasImageBytes: _atlasBytes(),
              selection: selection,
              centerAssigned: false,
              centerColumns: const <int>[],
              zoomPercent: 100,
              onColumnSelectionChanged: (next) => selection = next,
              onUseSelectionAsCenter: () {},
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final canvas = find.byKey(const ValueKey('surfaceStudio.atlas.canvas'));
    expect(canvas, findsOneWidget);
    expect(find.byKey(const ValueKey('surfaceStudio.atlas.realImage')),
        findsNothing);

    final canvasTopLeft = tester.getTopLeft(canvas);
    await tester.tapAt(canvasTopLeft + const Offset(120, 210));
    await tester.pump();
    expect(selection.columns, isEmpty);

    await tester.tapAt(canvasTopLeft + const Offset(200, 210));
    await tester.pump();
    expect(selection.columns, <int>[4]);
  });
}

Uint8List _atlasBytes() {
  const tile = 32;
  const columns = 23;
  const frames = 32;
  final image = img.Image(width: columns * tile, height: frames * tile);
  for (var frame = 0; frame < frames; frame++) {
    for (var column = 0; column < columns; column++) {
      img.fillRect(
        image,
        x1: column * tile,
        y1: frame * tile,
        x2: column * tile + tile - 1,
        y2: frame * tile + tile - 1,
        color: img.ColorRgb8(20 + column * 5, 50 + frame, 160),
      );
    }
  }
  return Uint8List.fromList(img.encodePng(image));
}
