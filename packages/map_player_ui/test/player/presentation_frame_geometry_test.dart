import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_player_ui/presentation_renderer.dart';

void main() {
  for (final orientation in PresentationFrameOrientation.values) {
    testWidgets('real transformed text geometry ${orientation.name}',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(960, 640));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final geometry = PresentationFrameGeometryController();
      final composition = PresentationVisualComposition(
        translateX: .05,
        translateY: .08,
        scaleX: .8,
        scaleY: .9,
        rotationTurns: .04,
        opacity: 1,
      );
      await tester.pumpWidget(MaterialApp(
        theme: PokeMapPlayerTheme.dark(),
        home: PresentationFrameRenderer(
          frame: _frame(composition),
          orientation: orientation,
          contentPort: _Content(),
          geometry: geometry,
        ),
      ));
      final canvas = tester.renderObject<RenderBox>(find.byKey(
        ValueKey('presentation-frame-canvas-${orientation.name}'),
      ));
      final text = tester.renderObject<RenderBox>(find.byKey(
        const ValueKey('presentation-text-title'),
      ));
      final actual = geometry.snapshot().single;
      final transform = text.getTransformTo(canvas);
      final corners = [
        Offset.zero,
        Offset(text.size.width, 0),
        text.size.bottomRight(Offset.zero),
        Offset(0, text.size.height)
      ];
      for (var i = 0; i < corners.length; i++) {
        expect(
            (actual.corners[i] -
                    MatrixUtils.transformPoint(transform, corners[i]))
                .distance,
            lessThan(.001));
      }
      final center =
          MatrixUtils.transformPoint(transform, text.size.center(Offset.zero));
      expect(geometry.hitTest(center)?.clipId, 'title');
      expect(geometry.hitTest(actual.bounds.topLeft + const Offset(.1, .1)),
          isNull);
      expect(actual.bounds.width, lessThan(canvas.size.width));
      await tester.pumpWidget(const SizedBox());
      expect(geometry.snapshot(), isEmpty);
    });
  }
  testWidgets('visible text geometry intersects the actual crop',
      (tester) async {
    final geometry = PresentationFrameGeometryController();
    await tester.pumpWidget(MaterialApp(
      theme: PokeMapPlayerTheme.dark(),
      home: PresentationFrameRenderer(
        frame: _frame(PresentationVisualComposition(cropLeft: .5)),
        orientation: PresentationFrameOrientation.landscape,
        contentPort: _Content(),
        geometry: geometry,
      ),
    ));
    final size = geometry.canvasSize!;
    final selected = geometry.snapshot().single;
    expect(selected.bounds.left, closeTo(size.width / 2, .001));
    expect(
        geometry.hitTest(Offset(size.width / 2 - 1, size.height / 2)), isNull);
    expect(
        geometry.hitTest(Offset(size.width / 2 + 1, size.height / 2))?.clipId,
        'title');
  });
}

PresentationFrame _frame(PresentationVisualComposition composition) =>
    PresentationFrame(
      cinematicId: 'opening',
      timeUs: 0,
      durationUs: 1000000,
      texts: [
        PresentationTextFrameClip(
          clipId: 'title',
          trackId: 'text',
          layerId: 'title',
          zIndex: 2,
          text: 'Le train\n17h42',
          localizationKey: null,
          style: PresentationTextStyle(fontSize: 24),
          startUs: 0,
          durationUs: 1000000,
          elapsedUs: 0,
          progress: 0,
          easedProgress: 0,
          easing: PresentationEasing.linear,
          composition: composition,
          reducedMotionComposition: composition,
        )
      ],
    );

class _Content implements PresentationFrameContentPort {
  @override
  PresentationVisualResolution resolveVisual(
          {required PresentationVisualFrameClip clip,
          required PresentationFrameOrientation orientation}) =>
      const PresentationVisualReady(child: SizedBox());
  @override
  PresentationCaptionResolution resolveCaption(
          {required PresentationCaptionFrameClip clip,
          required Locale locale}) =>
      const PresentationCaptionReady(text: '');
}
