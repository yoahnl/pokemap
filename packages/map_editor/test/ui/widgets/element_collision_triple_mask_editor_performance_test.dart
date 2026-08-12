import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/application/services/editor_performance_telemetry.dart';
import 'package:map_editor/src/ui/widgets/element_collision_triple_mask_editor.dart';

void main() {
  test('stores collision and occlusion drafts in one byte per pixel', () {
    final draft = FineMaskDraft.empty(width: 1024, height: 1024);

    expect(draft.storageByteLength, 2 * 1024 * 1024);

    final mutation = draft.paintCollision(
      centerX: 512,
      centerY: 512,
      brushSize: 8,
      erase: false,
    );

    expect(mutation.changedPixelCount, 64);
    expect(mutation.dirtyBounds, const Rect.fromLTWH(508, 508, 8, 8));
    expect(draft.collisionAt(512, 512), isTrue);
  });

  test('rolls back a fine-mask stroke atomically', () {
    final draft = FineMaskDraft.empty(width: 1024, height: 1024);
    final stroke = draft.beginStroke(FineMaskLayer.collision);

    stroke.paint(centerX: 512, centerY: 512, brushSize: 32, erase: false);
    expect(draft.collisionAt(512, 512), isTrue);

    stroke.rollback();

    expect(draft.collisionAt(512, 512), isFalse);
  });

  test('keeps a thousand-point stroke bounded to dirty chunks', () {
    final draft = FineMaskDraft.empty(width: 1024, height: 1024);
    final cache = FineMaskPaintRunCache(
      draft.collisionBytes,
      width: 1024,
      height: 1024,
    );
    final stroke = draft.beginStroke(FineMaskLayer.collision);
    var rebuiltPixels = 0;

    for (var index = 0; index < 1000; index += 1) {
      final mutation = stroke.paint(
        centerX: index % 1024,
        centerY: index ~/ 1024,
        brushSize: 1,
        erase: false,
      );
      cache.rebuild(mutation.dirtyBounds);
      rebuiltPixels += cache.lastRebuiltPixelCount;
    }
    stroke.commit();

    expect(rebuiltPixels, 32 * 1000);
    expect(draft.collisionAt(0, 0), isTrue);
    expect(draft.collisionAt(999, 0), isTrue);
  });

  test('rebuilds paint runs only inside dirty chunks', () {
    final bits = Uint8List(1024 * 1024);
    final cache = FineMaskPaintRunCache(bits, width: 1024, height: 1024);
    final untouchedBefore = cache.chunkRunsForRow(20, 0);
    final dirtyBefore = cache.chunkRunsForRow(20, 12);
    bits[20 * 1024 + 400] = 1;

    cache.rebuild(const Rect.fromLTWH(400, 20, 1, 1));

    expect(cache.chunkRunsForRow(20, 0), same(untouchedBefore));
    expect(cache.chunkRunsForRow(20, 12), isNot(same(dirtyBefore)));
    expect(cache.lastRebuiltPixelCount, 32);
    expect(cache.chunkRunsForRow(20, 12), const <CollisionMaskPaintRun>[
      CollisionMaskPaintRun(x: 400, y: 20, length: 1),
    ]);
  });

  testWidgets('reads only the selected visual source region', (tester) async {
    final image = await _image(1024);
    addTearDown(image.dispose);

    final region = await tester.runAsync(
      () => readFineMaskVisualAlphaRegion(
        image: image,
        sourceRect: const Rect.fromLTWH(400, 500, 16, 32),
      ),
    );

    expect(region?.width, 16);
    expect(region?.height, 32);
    expect(region?.readbackPixelCount, 16 * 32);
    expect(region?.alphaBytes, hasLength(16 * 32));
  });

  test('coalesces a dense 1024 mask into one paint run per row', () {
    final runs = buildCollisionMaskPaintRuns(
      List<bool>.filled(1024 * 1024, true),
      width: 1024,
      height: 1024,
    );

    expect(runs, hasLength(1024));
    expect(runs.first, const CollisionMaskPaintRun(x: 0, y: 0, length: 1024));
    expect(runs.last, const CollisionMaskPaintRun(x: 0, y: 1023, length: 1024));
  });

  testWidgets('keeps fine-mask pointer moves local until pointer up', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(900, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final image = await _image(1024);
    addTearDown(image.dispose);
    var callbackCount = 0;
    ElementCollisionProfile? committed;
    final recorder = EditorPerformanceRecorder();
    final recording = EditorPerformanceTelemetry.startRecording(recorder);
    addTearDown(recording.close);

    await tester.pumpWidget(
      CupertinoApp(
        home: SizedBox(
          width: 700,
          height: 900,
          child: ElementCollisionTripleMaskEditor(
            image: image,
            source: const TilesetSourceRect(x: 0, y: 0, width: 1, height: 1),
            tileWidth: 1024,
            tileHeight: 1024,
            profile: null,
            draftPadding: const WarpTriggerPadding(),
            onProfileChanged: (next) {
              callbackCount += 1;
              committed = next;
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final before = recorder.snapshot();
    final surface = find.byType(CustomPaint).last;
    final rect = tester.getRect(surface);
    final gesture = await tester.startGesture(
      rect.topLeft + const Offset(8, 8),
    );

    for (var index = 1; index <= 20; index += 1) {
      await gesture.moveTo(rect.topLeft + Offset(8 + index * 4, 8 + index * 4));
      await tester.pump();
    }

    final during = recorder.deltaSince(before);
    expect(callbackCount, 0);
    expect(during.counter(EditorPerformanceCounterName.base64Encode), 0);
    expect(during.counter(EditorPerformanceCounterName.base64Decode), 0);

    await gesture.up();
    await tester.pump();

    expect(callbackCount, 1);
    expect(committed?.collisionMask, isNotNull);
  });

  testWidgets('commits an active stroke before changing mask mode', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(900, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final image = await _image(64);
    addTearDown(image.dispose);
    var callbackCount = 0;

    await tester.pumpWidget(
      CupertinoApp(
        home: SizedBox(
          width: 700,
          height: 900,
          child: ElementCollisionTripleMaskEditor(
            image: image,
            source: const TilesetSourceRect(x: 0, y: 0, width: 1, height: 1),
            tileWidth: 64,
            tileHeight: 64,
            profile: null,
            draftPadding: const WarpTriggerPadding(),
            onProfileChanged: (_) => callbackCount += 1,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final surface = find.byType(CustomPaint).last;
    final gesture = await tester.startGesture(tester.getCenter(surface));
    await gesture.moveBy(const Offset(8, 8));
    await tester.pump();

    expect(callbackCount, 0);

    await tester.tap(find.text('Peindre occlusion'));
    await tester.pump();

    expect(callbackCount, 1);
    await gesture.up();
  });

  testWidgets('controller commits an active stroke synchronously', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(900, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final image = await _image(64);
    addTearDown(image.dispose);
    final controller = ElementCollisionFineMaskController();
    ElementCollisionProfile? committed;
    await tester.pumpWidget(
      CupertinoApp(
        home: SizedBox(
          width: 700,
          height: 900,
          child: ElementCollisionTripleMaskEditor(
            image: image,
            source: const TilesetSourceRect(x: 0, y: 0, width: 1, height: 1),
            tileWidth: 64,
            tileHeight: 64,
            profile: null,
            draftPadding: const WarpTriggerPadding(),
            controller: controller,
            onProfileChanged: (next) => committed = next,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final surface = find.byType(CustomPaint).last;
    final gesture = await tester.startGesture(
      tester.getCenter(surface),
      pointer: 42,
    );
    await gesture.moveBy(const Offset(8, 8));
    await tester.pump();

    controller.commitActiveStroke();

    expect(committed?.collisionMask, isNotNull);
    await gesture.up();
  });
}

Future<ui.Image> _image(int extent) async {
  final recorder = ui.PictureRecorder();
  final canvas = ui.Canvas(recorder);
  canvas.drawRect(
    ui.Rect.fromLTWH(0, 0, extent.toDouble(), extent.toDouble()),
    ui.Paint()..color = const ui.Color(0xFFFFFFFF),
  );
  final picture = recorder.endRecording();
  final image = await picture.toImage(extent, extent);
  picture.dispose();
  return image;
}
