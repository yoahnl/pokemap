import 'dart:ui' as ui;

import 'package:avelune_converter/asset_review_canvas.dart';
import 'package:avelune_converter_core/avelune_converter_core.dart';
import 'package:avelune_design_system/avelune_design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../packages/avelune_converter_adapters/test/support/original_asset_fixture.dart';

void main() {
  late OriginalAssetFixture fixture;
  late ui.Image image;
  late List<AssetCanvasCell> cells;
  late List<AssetPart> parts;
  late StateSetter rebuildCanvas;

  setUp(() async {
    fixture = await OriginalAssetFixture.create();
    cells = [];
    parts = fixture.treeCandidate().parts;
  });

  Future<void> pump(WidgetTester tester) async {
    await tester.runAsync(() async {
      final codec = await ui.instantiateImageCodec(
        Uint8List.fromList(fixture.pngBytes),
      );
      image = (await codec.getNextFrame()).image;
      codec.dispose();
    });
    addTearDown(image.dispose);
    await tester.pumpWidget(
      MaterialApp(
        theme: studioTheme(),
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 700,
              height: 500,
              child: StatefulBuilder(
                builder: (context, setState) {
                  rebuildCanvas = setState;
                  return ConverterAssetSourceCanvas(
                    source: fixture.treeCandidate().sources.single,
                    image: image,
                    parts: parts,
                    selectedCells: cells,
                    onSelectionChanged: (next) => setState(() => cells = next),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  Offset sourcePoint(WidgetTester tester, Offset source) {
    final finder = find.byKey(const ValueKey('asset-source-view'));
    final viewer = tester.widget<InteractiveViewer>(finder);
    final translated = MatrixUtils.transformPoint(
      viewer.transformationController!.value,
      source,
    );
    return tester.getTopLeft(finder) + translated;
  }

  testWidgets(
    'AC-10 canvas centers the selected source parts without moving on metadata rebuild',
    (tester) async {
      await pump(tester);
      final view = find.byKey(const ValueKey('asset-source-view'));
      Offset center() => tester
          .widget<InteractiveViewer>(view)
          .transformationController!
          .toScene(tester.getSize(view).center(Offset.zero));
      expect(center().dx, closeTo(32, .001));
      expect(center().dy, closeTo(48, .001));
      final controller = tester
          .widget<InteractiveViewer>(view)
          .transformationController!;
      controller.value = Matrix4.translationValues(25, 12, 0)
        ..setEntry(0, 0, 2)
        ..setEntry(1, 1, 2);
      final before = controller.value.clone();
      rebuildCanvas(() => parts = fixture.treeCandidate().parts);
      await tester.pump();
      expect(controller.value, before);
      rebuildCanvas(() => parts = fixture.houseCandidate().parts);
      await tester.pump();
      expect(center().dx, closeTo(160, .001));
      expect(center().dy, closeTo(128, .001));
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('AC-10 source cell selection remains exact after zoom and pan', (
    tester,
  ) async {
    await pump(tester);
    await tester.tap(find.byKey(const ValueKey('asset-tool-cell')));
    await tester.tap(find.byKey(const ValueKey('asset-zoom-100')));
    await tester.pump();
    await tester.tapAt(sourcePoint(tester, const Offset(48, 16)));
    await tester.pump();
    expect(cells, [(x: 1, y: 0)]);
    await tester.tap(find.byKey(const ValueKey('asset-zoom-200')));
    await tester.pump();
    final viewer = tester.widget<InteractiveViewer>(
      find.byKey(const ValueKey('asset-source-view')),
    );
    viewer.transformationController!.value =
        Matrix4.translationValues(25, 12, 0)
          ..setEntry(0, 0, 2)
          ..setEntry(1, 1, 2);
    await tester.pump();
    await tester.tapAt(sourcePoint(tester, const Offset(48, 16)));
    await tester.pump();
    expect(cells, isEmpty);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'AC-10 rectangle selects only covered source cells and clears with Escape',
    (tester) async {
      await pump(tester);
      await tester.tap(find.byKey(const ValueKey('asset-tool-rectangle')));
      await tester.tap(find.byKey(const ValueKey('asset-zoom-100')));
      await tester.pump();
      final gesture = await tester.startGesture(
        sourcePoint(tester, const Offset(1, 1)),
      );
      await gesture.moveTo(sourcePoint(tester, const Offset(63, 31)));
      await gesture.up();
      await tester.pump();
      expect(cells, [(x: 0, y: 0), (x: 1, y: 0)]);
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pump();
      expect(cells, isEmpty);
      expect(tester.takeException(), isNull);
    },
  );
}
