import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/l10n/app_localizations.dart';
import 'package:map_editor/src/theme/theme.dart';
import 'package:map_editor/src/ui/canvas/cinematics/presentation/presentation_studio_responsive_canvas.dart';
import 'package:map_editor/src/ui/canvas/cinematics/presentation/presentation_studio_layer_tree.dart';
import 'package:map_editor/src/ui/canvas/cinematics/presentation/presentation_studio_viewport.dart';
import 'package:map_player_ui/presentation_renderer.dart';

import '../../../support/event_builder_v2_visual_harness.dart';

void main() {
  test(
    'controller preserves playhead, selection and orientation viewports',
    () {
      final controller = PresentationStudioResponsiveCanvasController(
        durationUs: 4_000_000,
        playheadUs: 2_000_000,
        initialSelection: const PresentationStudioSelection(
          layerId: 'hero-layer',
          trackId: 'visuals',
          clipId: 'hero-clip',
        ),
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
      durationUs: 4_000_000,
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

  testWidgets('English responsive controls remain usable at 200 percent', (
    tester,
  ) async {
    final controller = PresentationStudioResponsiveCanvasController(
      durationUs: 4_000_000,
    );
    addTearDown(controller.dispose);

    await _pumpResponsiveCanvas(
      tester,
      controller: controller,
      frameBuilder: (_) => _frame(),
      locale: const Locale('en'),
      textScaler: const TextScaler.linear(2),
    );

    expect(find.bySemanticsLabel('Previous frame'), findsOneWidget);
    expect(find.bySemanticsLabel('Play'), findsOneWidget);
    expect(find.text('Compare'), findsOneWidget);
    expect(find.text('Fit'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.tap(find.byKey(presentationStudioLoopKey));
    await tester.pump();
    expect(find.bySemanticsLabel('Disable loop'), findsOneWidget);
  });

  testWidgets('English responsive blocker is explicit', (tester) async {
    final controller = PresentationStudioResponsiveCanvasController(
      durationUs: 4_000_000,
      mode: PresentationStudioCanvasMode.compare,
    );
    addTearDown(controller.dispose);

    await _pumpResponsiveCanvas(
      tester,
      controller: controller,
      frameBuilder: (_) => _frame(),
      locale: const Locale('en'),
      mediaBindings: const [
        PresentationStudioResponsiveMediaBinding(
          clipId: 'hero-clip',
          kind: PresentationStudioResponsiveMediaKind.image,
          sharedResourceId: 'hero-shared',
        ),
        PresentationStudioResponsiveMediaBinding(
          clipId: 'hero-clip',
          kind: PresentationStudioResponsiveMediaKind.image,
          portraitResourceId: 'hero-portrait',
        ),
      ],
    );

    expect(find.text('Responsive composition blocked'), findsOneWidget);
    expect(
      find.text('Clip hero-clip has multiple media bindings.'),
      findsOneWidget,
    );
  });

  testWidgets('temporal preview evaluates one shared frame at the playhead', (
    tester,
  ) async {
    final controller = PresentationStudioResponsiveCanvasController(
      durationUs: 4_000_000,
      mode: PresentationStudioCanvasMode.compare,
    );
    addTearDown(controller.dispose);

    await _pumpResponsiveCanvas(
      tester,
      controller: controller,
      frameBuilder: (playheadUs) => _frame(timeUs: playheadUs),
    );

    await tester.tap(find.byKey(presentationStudioPlayPauseKey));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));

    final renderers = tester
        .widgetList<PresentationFrameRenderer>(
          find.byType(PresentationFrameRenderer),
        )
        .toList();
    expect(controller.playheadUs, 250_000);
    expect(renderers.map((renderer) => renderer.frame.timeUs).toSet(), {
      250_000,
    });
    expect(identical(renderers.first.frame, renderers.last.frame), isTrue);
  });

  testWidgets('preview forwards renderer accessibility preferences', (
    tester,
  ) async {
    final controller = PresentationStudioResponsiveCanvasController(
      durationUs: 4_000_000,
    );
    addTearDown(controller.dispose);

    await _pumpResponsiveCanvas(
      tester,
      controller: controller,
      frameBuilder: (_) => _frame(),
      reduceMotion: true,
      reduceFlashes: true,
      showCaptions: false,
    );

    final renderer = tester.widget<PresentationFrameRenderer>(
      find.byType(PresentationFrameRenderer),
    );
    expect(renderer.reduceMotion, isTrue);
    expect(renderer.reduceFlashes, isTrue);
    expect(renderer.showCaptions, isFalse);
  });

  testWidgets('preview exposes loading and renderer error states', (
    tester,
  ) async {
    var retries = 0;
    final controller = PresentationStudioResponsiveCanvasController(
      durationUs: 4_000_000,
    );
    addTearDown(controller.dispose);
    controller.setLoading();

    await _pumpResponsiveCanvas(
      tester,
      controller: controller,
      frameBuilder: (_) => _frame(),
      onRetry: () {
        retries += 1;
        controller.setReady();
      },
    );

    expect(
      tester
          .widget<PresentationStudioViewport>(
            find.byType(PresentationStudioViewport),
          )
          .state,
      PresentationStudioViewportState.loading,
    );

    controller.setError('Décodage vidéo impossible.');
    await tester.pump();

    final viewport = tester.widget<PresentationStudioViewport>(
      find.byType(PresentationStudioViewport),
    );
    expect(viewport.state, PresentationStudioViewportState.error);
    expect(viewport.errorMessage, 'Décodage vidéo impossible.');
    expect(find.byType(PresentationFrameRenderer), findsNothing);

    await tester.tap(find.text('Réessayer le rendu'));
    await tester.pump();

    expect(retries, 1);
    expect(controller.status, PresentationPlaybackStatus.ready);
    expect(find.byType(PresentationFrameRenderer), findsOneWidget);
  });

  testWidgets('canvas tap updates the shared Presentation selection', (
    tester,
  ) async {
    final controller = PresentationStudioResponsiveCanvasController(
      durationUs: 4_000_000,
    );
    addTearDown(controller.dispose);
    final asset = PresentationCinematicAsset(
      id: 'opening',
      title: 'Opening',
      durationUs: 4_000_000,
      layers: <PresentationLayer>[
        PresentationLayer(id: 'hero-layer', label: 'Hero', zIndex: 0),
      ],
      tracks: <PresentationTrack>[
        PresentationTrack(
          id: 'visuals',
          label: 'Visuals',
          kind: PresentationTrackKind.visual,
          clips: <PresentationClip>[
            PresentationVisualClip(
              id: 'hero-clip',
              startUs: 0,
              durationUs: 1_000_000,
              layerId: 'hero-layer',
              resourceId: 'hero-default',
            ),
          ],
        ),
      ],
    );

    await _pumpResponsiveCanvas(
      tester,
      controller: controller,
      frameBuilder: (_) => _frame(),
      asset: asset,
    );

    await tester.tap(find.byKey(presentationStudioViewportFrameKey));
    await tester.pump();

    expect(controller.selection.value?.layerId, 'hero-layer');
    expect(controller.selection.value?.clipId, 'hero-clip');
  });

  testWidgets('selected text drag crosses the responsive canvas boundary', (
    tester,
  ) async {
    final controller = PresentationStudioResponsiveCanvasController(
      durationUs: 4_000_000,
      initialSelection: const PresentationStudioSelection(
        layerId: 'title-layer',
        trackId: 'visuals',
        clipId: 'title-clip',
      ),
    );
    addTearDown(controller.dispose);
    final asset = PresentationCinematicAsset(
      id: 'opening',
      title: 'Opening',
      durationUs: 4_000_000,
      layers: <PresentationLayer>[
        PresentationLayer(id: 'title-layer', label: 'Title', zIndex: 0),
      ],
      tracks: <PresentationTrack>[
        PresentationTrack(
          id: 'visuals',
          label: 'Visuals',
          kind: PresentationTrackKind.visual,
          clips: <PresentationClip>[
            PresentationTextClip(
              id: 'title-clip',
              startUs: 0,
              durationUs: 4_000_000,
              layerId: 'title-layer',
              text: 'Opening',
            ),
          ],
        ),
      ],
    );
    final frame = const PresentationCinematicEvaluator().evaluate(
      asset,
      timeUs: 0,
    );
    final deltas = <Offset>[];

    await _pumpResponsiveCanvas(
      tester,
      controller: controller,
      frameBuilder: (_) => frame,
      asset: asset,
      onSelectedTextDrag: deltas.add,
    );

    final frameFinder = find.byKey(presentationStudioViewportFrameKey);
    final frameRect = tester.getRect(frameFinder);
    await tester.drag(
      frameFinder,
      Offset(frameRect.width * .1, frameRect.height * -.1),
    );
    await tester.pump();

    final total = deltas.fold<Offset>(Offset.zero, (sum, item) => sum + item);
    expect(total.dx, closeTo(.1, .01));
    expect(total.dy, closeTo(-.1, .01));

    controller.selection.clear();
    await tester.pump();
    expect(
      tester
          .widget<PresentationStudioViewport>(
            find.byKey(
              const ValueKey('presentation-studio-landscape-viewport'),
            ),
          )
          .onCompositionDrag,
      isNull,
    );
  });

  testWidgets('Compare applies distinct transforms to the same frame', (
    tester,
  ) async {
    final controller = PresentationStudioResponsiveCanvasController(
      durationUs: 4_000_000,
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
      durationUs: 4_000_000,
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

  testWidgets('an orientation source overrides the shared fallback', (
    tester,
  ) async {
    final controller = PresentationStudioResponsiveCanvasController(
      durationUs: 4_000_000,
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
          sharedResourceId: 'hero-shared',
          portraitResourceId: 'hero-portrait',
        ),
      ],
    );

    expect(port.resolutions, [
      (
        orientation: PresentationFrameOrientation.landscape,
        resourceId: 'hero-shared',
      ),
      (
        orientation: PresentationFrameOrientation.portrait,
        resourceId: 'hero-portrait',
      ),
    ]);
    expect(
      find.byKey(presentationStudioResponsiveMediaBlockerKey),
      findsNothing,
    );
  });

  testWidgets('an incompatible responsive duration blocks the canvas', (
    tester,
  ) async {
    final controller = PresentationStudioResponsiveCanvasController(
      durationUs: 4_000_000,
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

  testWidgets('catalog-pending video keeps the authoring canvas available', (
    tester,
  ) async {
    final controller = PresentationStudioResponsiveCanvasController(
      durationUs: 4_000_000,
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
          sharedResourceId: 'hero-video',
          requireDurationMetadata: false,
        ),
      ],
    );

    expect(
      find.byKey(presentationStudioResponsiveMediaBlockerKey),
      findsNothing,
    );
    expect(find.byType(PresentationFrameRenderer), findsNWidgets(2));
  });

  testWidgets('Compare focus is deterministic and keeps both safe areas', (
    tester,
  ) async {
    final controller = PresentationStudioResponsiveCanvasController(
      durationUs: 4_000_000,
      mode: PresentationStudioCanvasMode.compare,
      playheadUs: 750_000,
      initialSelection: const PresentationStudioSelection(
        layerId: 'hero-layer',
        trackId: 'visuals',
        clipId: 'hero-clip',
      ),
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
        final controller = PresentationStudioResponsiveCanvasController(
          durationUs: 4_000_000,
        );
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
        durationUs: 4_000_000,
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
  bool? reduceMotion,
  bool reduceFlashes = false,
  bool showCaptions = true,
  PresentationCinematicAsset? asset,
  Size surfaceSize = const Size(1280, 800),
  String? fontFamily,
  VoidCallback? onRetry,
  ValueChanged<Offset>? onSelectedTextDrag,
  Locale locale = const Locale('fr'),
  TextScaler textScaler = TextScaler.noScaling,
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
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      theme: theme,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(textScaler: textScaler),
        child: child!,
      ),
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
          reduceMotion: reduceMotion,
          reduceFlashes: reduceFlashes,
          showCaptions: showCaptions,
          asset: asset,
          onRetry: onRetry,
          onSelectedTextDrag: onSelectedTextDrag,
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
