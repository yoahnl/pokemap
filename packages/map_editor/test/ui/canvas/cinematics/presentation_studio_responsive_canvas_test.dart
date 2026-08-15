import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/theme/theme.dart';
import 'package:map_editor/src/ui/canvas/cinematics/presentation/presentation_studio_responsive_canvas.dart';
import 'package:map_editor/src/ui/canvas/cinematics/presentation/presentation_studio_viewport.dart';
import 'package:map_player_ui/presentation_renderer.dart';

import '../../../support/event_builder_v2_visual_harness.dart';

void main() {
  test(
    'controller preserves playhead, selection and orientation viewports',
    () {
      final controller = PresentationStudioResponsiveCanvasController(
        playheadUs: 2_000_000,
        selectedClipId: 'hero-clip',
      );
      addTearDown(controller.dispose);

      controller.landscapeViewport.zoomIn();
      controller.setMode(PresentationStudioCanvasMode.portrait);

      expect(controller.playheadUs, 2_000_000);
      expect(controller.selectedClipId, 'hero-clip');
      expect(controller.landscapeViewport.zoom, 1.25);
      expect(controller.portraitViewport.zoom, 1);

      controller.setMode(PresentationStudioCanvasMode.compare);
      controller.fitVisibleViewports();

      expect(controller.playheadUs, 2_000_000);
      expect(controller.selectedClipId, 'hero-clip');
      expect(controller.landscapeViewport.zoom, 1);
      expect(controller.portraitViewport.zoom, 1);
    },
  );

  testWidgets('toolbar switches landscape, portrait and Compare modes', (
    tester,
  ) async {
    final controller = PresentationStudioResponsiveCanvasController(
      playheadUs: 2_000_000,
    );
    addTearDown(controller.dispose);
    final frame = _frame(timeUs: 2_000_000);

    await _pumpResponsiveCanvas(
      tester,
      controller: controller,
      frameBuilder: (_) => frame,
    );

    expect(_rendererOrientations(tester), [
      PresentationFrameOrientation.landscape,
    ]);

    await tester.tap(find.byKey(presentationStudioPortraitModeKey));
    await tester.pump();

    expect(controller.playheadUs, 2_000_000);
    expect(_rendererOrientations(tester), [
      PresentationFrameOrientation.portrait,
    ]);

    await tester.tap(find.byKey(presentationStudioCompareModeKey));
    await tester.pump();

    final renderers = tester
        .widgetList<PresentationFrameRenderer>(
          find.byType(PresentationFrameRenderer),
        )
        .toList();
    expect(renderers.map((renderer) => renderer.orientation), [
      PresentationFrameOrientation.landscape,
      PresentationFrameOrientation.portrait,
    ]);
    expect(
      renderers.every((renderer) => identical(renderer.frame, frame)),
      isTrue,
    );
    expect(renderers.map((renderer) => renderer.frame.timeUs).toSet(), {
      2_000_000,
    });
    expect(find.textContaining('00:02.000'), findsOneWidget);
  });

  testWidgets('Compare applies distinct transforms to the same frame', (
    tester,
  ) async {
    final controller = PresentationStudioResponsiveCanvasController(
      mode: PresentationStudioCanvasMode.compare,
    );
    addTearDown(controller.dispose);
    final frame = _frame();
    final overrides = PresentationFrameOrientationOverrides(
      visualsByClipId: {
        'hero-clip': PresentationVisualOrientationOverride(
          landscape: PresentationVisualComposition(translateX: 0.2),
          portrait: PresentationVisualComposition(translateX: -0.3),
        ),
      },
    );

    await _pumpResponsiveCanvas(
      tester,
      controller: controller,
      frameBuilder: (_) => frame,
      orientationOverrides: overrides,
    );

    final translations = tester
        .widgetList<FractionalTranslation>(
          find.byKey(
            const ValueKey('presentation-visual-translation-hero-clip'),
          ),
        )
        .map((widget) => widget.translation)
        .toSet();
    expect(translations, {const Offset(0.2, 0), const Offset(-0.3, 0)});
  });

  testWidgets('one responsive source falls back in both orientations', (
    tester,
  ) async {
    final controller = PresentationStudioResponsiveCanvasController(
      mode: PresentationStudioCanvasMode.compare,
    );
    addTearDown(controller.dispose);
    final port = _RecordingContentPort();

    await _pumpResponsiveCanvas(
      tester,
      controller: controller,
      frameBuilder: (_) => _frame(),
      contentPort: port,
      mediaBindings: const [
        PresentationStudioResponsiveMediaBinding(
          clipId: 'hero-clip',
          kind: PresentationStudioResponsiveMediaKind.image,
          landscapeResourceId: 'hero-landscape',
        ),
      ],
    );

    expect(port.resolutions, [
      (
        orientation: PresentationFrameOrientation.landscape,
        resourceId: 'hero-landscape',
      ),
      (
        orientation: PresentationFrameOrientation.portrait,
        resourceId: 'hero-landscape',
      ),
    ]);
  });

  testWidgets('an incompatible responsive duration blocks the canvas', (
    tester,
  ) async {
    final controller = PresentationStudioResponsiveCanvasController(
      mode: PresentationStudioCanvasMode.compare,
    );
    addTearDown(controller.dispose);

    await _pumpResponsiveCanvas(
      tester,
      controller: controller,
      frameBuilder: (_) => _frame(),
      mediaBindings: const [
        PresentationStudioResponsiveMediaBinding(
          clipId: 'hero-clip',
          kind: PresentationStudioResponsiveMediaKind.video,
          landscapeResourceId: 'hero-landscape',
          landscapeDurationUs: 4_000_000,
          portraitResourceId: 'hero-portrait',
          portraitDurationUs: 500_000,
        ),
      ],
    );

    expect(
      find.byKey(presentationStudioResponsiveMediaBlockerKey),
      findsOneWidget,
    );
    expect(find.text('Composition responsive bloquée'), findsOneWidget);
    expect(find.textContaining('hero-portrait'), findsOneWidget);
    expect(find.byType(PresentationFrameRenderer), findsNothing);
  });

  testWidgets('Compare focus is deterministic and keeps both safe areas', (
    tester,
  ) async {
    final controller = PresentationStudioResponsiveCanvasController(
      mode: PresentationStudioCanvasMode.compare,
      playheadUs: 750_000,
      selectedClipId: 'hero-clip',
    );
    addTearDown(controller.dispose);

    await _pumpResponsiveCanvas(
      tester,
      controller: controller,
      frameBuilder: (_) => _frame(timeUs: 750_000),
    );

    expect(find.byKey(presentationStudioSafeAreaKey), findsNWidgets(2));
    final portraitGesture = find.descendant(
      of: find.byKey(const ValueKey('presentation-studio-portrait-viewport')),
      matching: find.byKey(presentationStudioViewportGestureKey),
    );
    await tester.tap(portraitGesture);
    await tester.pump();

    expect(controller.activeOrientation, PresentationFrameOrientation.portrait);
    expect(controller.playheadUs, 750_000);
    expect(controller.selectedClipId, 'hero-clip');
  });

  for (final size in <Size>[
    const Size(1280, 800),
    const Size(1672, 941),
    const Size(1920, 1080),
  ]) {
    testWidgets(
      'all responsive modes fit ${size.width.toInt()}x${size.height.toInt()}',
      (tester) async {
        final controller = PresentationStudioResponsiveCanvasController();
        addTearDown(controller.dispose);

        await _pumpResponsiveCanvas(
          tester,
          controller: controller,
          frameBuilder: (_) => _frame(),
          surfaceSize: size,
        );
        expect(tester.takeException(), isNull);

        controller.setMode(PresentationStudioCanvasMode.portrait);
        await tester.pump();
        expect(tester.takeException(), isNull);

        controller.setMode(PresentationStudioCanvasMode.compare);
        await tester.pump();
        expect(find.byType(PresentationFrameRenderer), findsNWidgets(2));
        expect(tester.takeException(), isNull);
      },
    );
  }

  for (final mode in PresentationStudioCanvasMode.values) {
    testWidgets('responsive ${mode.name} mode matches 1672x941', (
      tester,
    ) async {
      await loadEventBuilderV2PhaseKCaptureFonts();
      final controller = PresentationStudioResponsiveCanvasController(
        mode: mode,
        playheadUs: 2_000_000,
      );
      addTearDown(controller.dispose);

      await _pumpResponsiveCanvas(
        tester,
        controller: controller,
        frameBuilder: (_) => _frame(timeUs: 2_000_000),
        surfaceSize: const Size(1672, 941),
        fontFamily: eventBuilderV2PhaseKCaptureFontFamily,
      );

      await expectLater(
        find.byType(Scaffold),
        matchesGoldenFile(
          File(
            'test/goldens/narrative_studio/cinematics/'
            'presentation_studio_responsive_${mode.name}_1672x941.png',
          ).absolute.path,
        ),
      );
    });
  }
}

Future<void> _pumpResponsiveCanvas(
  WidgetTester tester, {
  required PresentationStudioResponsiveCanvasController controller,
  required PresentationFrame? Function(int playheadUs) frameBuilder,
  PresentationFrameContentPort? contentPort,
  PresentationFrameOrientationOverrides orientationOverrides =
      const PresentationFrameOrientationOverrides(),
  List<PresentationStudioResponsiveMediaBinding> mediaBindings = const [],
  Size surfaceSize = const Size(1280, 800),
  String? fontFamily,
}) async {
  tester.view.physicalSize = surfaceSize;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  final baseTheme = PokeMapTheme.dark();
  final theme = fontFamily == null
      ? baseTheme
      : baseTheme.copyWith(
          textTheme: baseTheme.textTheme.apply(fontFamily: fontFamily),
          primaryTextTheme: baseTheme.primaryTextTheme.apply(
            fontFamily: fontFamily,
          ),
        );
  await tester.pumpWidget(
    MaterialApp(
      theme: theme,
      home: Scaffold(
        appBar: AppBar(
          title: PresentationStudioResponsiveToolbar(controller: controller),
        ),
        body: PresentationStudioResponsiveCanvas(
          controller: controller,
          frameBuilder: frameBuilder,
          contentPort: contentPort ?? const _ContentPort(),
          playerTheme: PokeMapPlayerTheme.dark(),
          orientationOverrides: orientationOverrides,
          mediaBindings: mediaBindings,
        ),
      ),
    ),
  );
  await tester.pump();
}

List<PresentationFrameOrientation> _rendererOrientations(WidgetTester tester) =>
    tester
        .widgetList<PresentationFrameRenderer>(
          find.byType(PresentationFrameRenderer),
        )
        .map((renderer) => renderer.orientation)
        .toList();

PresentationFrame _frame({int timeUs = 0}) => PresentationFrame(
  cinematicId: 'opening',
  timeUs: timeUs,
  durationUs: 4_000_000,
  visuals: [
    PresentationVisualFrameClip(
      clipId: 'hero-clip',
      trackId: 'visuals',
      layerId: 'hero-layer',
      zIndex: 0,
      resourceId: 'hero-default',
      startUs: 0,
      durationUs: 1_000_000,
      elapsedUs: timeUs.clamp(0, 1_000_000),
      progress: 0,
      easedProgress: 0,
      easing: PresentationEasing.linear,
      composition: PresentationVisualComposition.identity,
      reducedMotionComposition: PresentationVisualComposition.identity,
    ),
  ],
);

final class _ContentPort implements PresentationFrameContentPort {
  const _ContentPort();

  @override
  PresentationVisualResolution resolveVisual({
    required PresentationVisualFrameClip clip,
    required PresentationFrameOrientation orientation,
  }) => PresentationVisualReady(
    child: ColoredBox(
      color: orientation == PresentationFrameOrientation.landscape
          ? const Color(0xff315da8)
          : const Color(0xff7349a8),
    ),
  );

  @override
  PresentationCaptionResolution resolveCaption({
    required PresentationCaptionFrameClip clip,
    required Locale locale,
  }) => const PresentationCaptionReady(text: 'Caption');
}

final class _RecordingContentPort implements PresentationFrameContentPort {
  final resolutions =
      <({PresentationFrameOrientation orientation, String resourceId})>[];

  @override
  PresentationVisualResolution resolveVisual({
    required PresentationVisualFrameClip clip,
    required PresentationFrameOrientation orientation,
  }) {
    resolutions.add((orientation: orientation, resourceId: clip.resourceId));
    return const PresentationVisualReady(child: SizedBox.expand());
  }

  @override
  PresentationCaptionResolution resolveCaption({
    required PresentationCaptionFrameClip clip,
    required Locale locale,
  }) => const PresentationCaptionReady(text: 'Caption');
}
