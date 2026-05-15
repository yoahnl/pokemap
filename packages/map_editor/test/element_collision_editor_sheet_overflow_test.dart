import 'dart:ui' as ui;

import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:macos_ui/macos_ui.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/ui/panels/element_collision_editor_sheet.dart';

void main() {
  testWidgets('collision editor sidebar does not overflow at desktop height',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(1600, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final image = await _testImage(width: 80, height: 96);
    await tester.pumpWidget(
      MacosApp(
        home: MacosTheme(
          data: MacosThemeData.dark(),
          child: CupertinoPageScaffold(
            child: Builder(
              builder: (context) => Center(
                child: CupertinoButton(
                  child: const Text('Open collision editor'),
                  onPressed: () {
                    showElementCollisionEditorSheet(
                      context: context,
                      elementName: 'selbrume maison 1',
                      image: image,
                      source: const TilesetSourceRect(
                        x: 0,
                        y: 0,
                        width: 5,
                        height: 6,
                      ),
                      tileWidth: 16,
                      tileHeight: 16,
                      initialProfile: const ElementCollisionProfile(
                        source: ElementCollisionProfileSource.generated,
                        cells: _buildingBlockingCells,
                        manualRemovedCells: _roofCells,
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open collision editor'));
    await tester.pumpAndSettle();

    expect(find.text('Aide'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

Future<ui.Image> _testImage({
  required int width,
  required int height,
}) async {
  final recorder = ui.PictureRecorder();
  final canvas = ui.Canvas(recorder);
  final paint = ui.Paint()..color = const Color(0xFF496D94);
  canvas.drawRect(
    ui.Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()),
    paint,
  );
  final picture = recorder.endRecording();
  return picture.toImage(width, height);
}

const List<GridPos> _roofCells = [
  GridPos(x: 0, y: 0),
  GridPos(x: 1, y: 0),
  GridPos(x: 2, y: 0),
  GridPos(x: 3, y: 0),
  GridPos(x: 4, y: 0),
  GridPos(x: 0, y: 1),
  GridPos(x: 1, y: 1),
  GridPos(x: 2, y: 1),
  GridPos(x: 3, y: 1),
  GridPos(x: 4, y: 1),
  GridPos(x: 0, y: 2),
  GridPos(x: 1, y: 2),
  GridPos(x: 2, y: 2),
  GridPos(x: 3, y: 2),
  GridPos(x: 4, y: 2),
];

const List<GridPos> _buildingBlockingCells = [
  GridPos(x: 0, y: 3),
  GridPos(x: 1, y: 3),
  GridPos(x: 2, y: 3),
  GridPos(x: 3, y: 3),
  GridPos(x: 4, y: 3),
  GridPos(x: 1, y: 4),
  GridPos(x: 2, y: 4),
  GridPos(x: 3, y: 4),
  GridPos(x: 4, y: 4),
  GridPos(x: 1, y: 5),
  GridPos(x: 2, y: 5),
  GridPos(x: 3, y: 5),
  GridPos(x: 4, y: 5),
];
