import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_player_ui/map_player_ui.dart';
import 'package:map_player_ui/presentation_renderer.dart';

void main() {
  testWidgets('renders canonical visual layers and captions in landscape', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(800, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final port = _ContentPort();

    await tester.pumpWidget(
      _app(
        PresentationFrameRenderer(
          frame: _frame(),
          orientation: PresentationFrameOrientation.landscape,
          contentPort: port,
        ),
      ),
    );

    final canvas = find.byKey(
      const ValueKey<String>('presentation-frame-canvas-landscape'),
    );
    expect(canvas, findsOneWidget);
    expect(tester.getSize(canvas), const Size(800, 450));
    expect(port.visualRequests, [
      'visual_background:landscape',
      'visual_foreground:landscape',
    ]);
    expect(
      tester
          .widgetList<Opacity>(
            find.descendant(of: canvas, matching: find.byType(Opacity)),
          )
          .map((widget) => (widget.key! as ValueKey<String>).value),
      [
        'presentation-visual-opacity-visual_background',
        'presentation-visual-opacity-visual_foreground',
      ],
    );
    expect(
      find.byKey(const ValueKey<String>('resolved-background')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('resolved-foreground')),
      findsOneWidget,
    );
    expect(find.text('Une aventure vous attend'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('renders portrait media and keeps captions inside safe areas', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final port = _ContentPort();

    await tester.pumpWidget(
      _app(
        PresentationFrameRenderer(
          frame: _frame(),
          orientation: PresentationFrameOrientation.portrait,
          contentPort: port,
        ),
        padding: const EdgeInsets.only(top: 44, bottom: 34),
      ),
    );

    final canvas = find.byKey(
      const ValueKey<String>('presentation-frame-canvas-portrait'),
    );
    final canvasRect = tester.getRect(canvas);
    final captionRect = tester.getRect(
      find.byKey(
        const ValueKey<String>('presentation-caption-caption_primary'),
      ),
    );
    expect(canvasRect.width / canvasRect.height, closeTo(9 / 16, 0.001));
    expect(captionRect.top, greaterThanOrEqualTo(canvasRect.top + 44));
    expect(captionRect.bottom, lessThanOrEqualTo(canvasRect.bottom - 34));
    expect(port.visualRequests, [
      'visual_background:portrait',
      'visual_foreground:portrait',
    ]);
    expect(tester.takeException(), isNull);
  });

  testWidgets('renders explicit states for unavailable media and captions', (
    tester,
  ) async {
    final port = _ContentPort(
      missingVisuals: const {'media.background'},
      unsupportedVisuals: const {'media.foreground'},
      unsupportedCaptions: const {'caption.primary'},
    );

    await tester.pumpWidget(
      _app(
        PresentationFrameRenderer(
          frame: _frame(),
          orientation: PresentationFrameOrientation.landscape,
          contentPort: port,
        ),
      ),
    );

    expect(
      find.byKey(
        const ValueKey<String>(
          'presentation-visual-unavailable-visual_background',
        ),
      ),
      findsOneWidget,
    );
    expect(
      find.byKey(
        const ValueKey<String>(
          'presentation-visual-unavailable-visual_foreground',
        ),
      ),
      findsOneWidget,
    );
    expect(
      find.byKey(
        const ValueKey<String>(
          'presentation-caption-unavailable-caption_primary',
        ),
      ),
      findsOneWidget,
    );
    expect(find.text('Média media.background introuvable'), findsOneWidget);
    expect(find.text('Média media.foreground indisponible'), findsOneWidget);
    expect(find.text('Texte caption.primary indisponible'), findsOneWidget);
    expect(
      tester
          .getSemantics(
            find.byKey(
              const ValueKey<String>(
                'presentation-caption-unavailable-caption_primary',
              ),
            ),
          )
          .value,
      'unsupported',
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('applies only the composition projected by the frame', (
    tester,
  ) async {
    final frame = _frameWithComposition(
      PresentationVisualComposition(
        translateX: 0.25,
        translateY: -0.1,
        scaleX: 0.5,
        scaleY: 0.75,
        rotationTurns: 0.125,
        opacity: 0.4,
        cropLeft: 0.1,
        cropTop: 0.2,
        cropRight: 0.3,
        cropBottom: 0.1,
      ),
    );

    await tester.pumpWidget(
      _app(
        PresentationFrameRenderer(
          frame: frame,
          orientation: PresentationFrameOrientation.landscape,
          contentPort: _ContentPort(),
        ),
      ),
    );

    final opacity = tester.widget<Opacity>(
      find.byKey(
        const ValueKey<String>('presentation-visual-opacity-composed'),
      ),
    );
    final translation = tester.widget<FractionalTranslation>(
      find.byKey(
        const ValueKey<String>('presentation-visual-translation-composed'),
      ),
    );
    final crop = tester.widget<ClipRect>(
      find.byKey(
        const ValueKey<String>('presentation-visual-crop-composed'),
      ),
    );
    final rotation = tester.widget<Transform>(
      find.byKey(
        const ValueKey<String>('presentation-visual-rotation-composed'),
      ),
    );
    final scale = tester.widget<Transform>(
      find.byKey(
        const ValueKey<String>('presentation-visual-scale-composed'),
      ),
    );

    expect(opacity.opacity, 0.4);
    expect(translation.translation, const Offset(0.25, -0.1));
    expect(crop.clipper!.getClip(const Size(100, 100)),
        const Rect.fromLTRB(10, 20, 70, 90));
    expect(rotation.transform.entry(0, 0), closeTo(math.sqrt1_2, 0.000001));
    expect(scale.transform.entry(0, 0), 0.5);
    expect(scale.transform.entry(1, 1), 0.75);
    expect(find.byType(AnimatedOpacity), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('uses the evaluator-projected reduced motion composition', (
    tester,
  ) async {
    final frame = _frameWithComposition(
      PresentationVisualComposition(translateX: 0.75, opacity: 0.4),
      reducedMotionComposition: PresentationVisualComposition(
        translateX: 0,
        opacity: 0.8,
      ),
    );

    await tester.pumpWidget(
      _app(
        PresentationFrameRenderer(
          frame: frame,
          orientation: PresentationFrameOrientation.landscape,
          contentPort: _ContentPort(),
        ),
        disableAnimations: true,
      ),
    );

    final opacity = tester.widget<Opacity>(
      find.byKey(
        const ValueKey<String>('presentation-visual-opacity-composed'),
      ),
    );
    final translation = tester.widget<FractionalTranslation>(
      find.byKey(
        const ValueKey<String>('presentation-visual-translation-composed'),
      ),
    );

    expect(opacity.opacity, 0.8);
    expect(translation.translation, Offset.zero);
  });

  testWidgets('reduced flashes overrides authored opacity transitions', (
    tester,
  ) async {
    final frame = _frameWithComposition(
      PresentationVisualComposition(opacity: 0.1),
      reducedFlashOpacity: 0.9,
    );

    await tester.pumpWidget(
      _app(
        PresentationFrameRenderer(
          frame: frame,
          orientation: PresentationFrameOrientation.landscape,
          contentPort: _ContentPort(),
          reduceFlashes: true,
        ),
      ),
    );

    final opacity = tester.widget<Opacity>(
      find.byKey(
        const ValueKey<String>('presentation-visual-opacity-composed'),
      ),
    );
    expect(opacity.opacity, 0.9);
  });

  testWidgets('caption preference can hide authored captions', (tester) async {
    await tester.pumpWidget(
      _app(
        PresentationFrameRenderer(
          frame: _frame(),
          orientation: PresentationFrameOrientation.landscape,
          contentPort: _ContentPort(),
          showCaptions: false,
        ),
      ),
    );

    expect(find.text('Une aventure vous attend'), findsNothing);
  });

  testWidgets('disposes interrupted visual resources exactly once', (
    tester,
  ) async {
    var disposeCount = 0;
    final port = _DisposableContentPort(() => disposeCount += 1);

    await tester.pumpWidget(
      _app(
        PresentationFrameRenderer(
          frame: _frameWithComposition(
            PresentationVisualComposition(),
          ),
          orientation: PresentationFrameOrientation.landscape,
          contentPort: port,
        ),
      ),
    );
    expect(disposeCount, 0);

    await tester.pumpWidget(
      _app(
        PresentationFrameRenderer(
          frame: PresentationFrame(
            cinematicId: 'opening',
            timeUs: 900000,
            durationUs: 1000000,
          ),
          orientation: PresentationFrameOrientation.landscape,
          contentPort: port,
        ),
      ),
    );
    await tester.pump();

    expect(disposeCount, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('matches deterministic compositions at exact timestamps', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(400, 300));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final port = _ContentPort();
    const evaluator = PresentationCinematicEvaluator();
    final asset = _animatedAsset();

    for (final timeUs in <int>[250000, 750000]) {
      await tester.pumpWidget(
        _app(
          RepaintBoundary(
            key: const ValueKey<String>('golden-boundary'),
            child: PresentationFrameRenderer(
              frame: evaluator.evaluate(asset, timeUs: timeUs),
              orientation: PresentationFrameOrientation.landscape,
              contentPort: port,
            ),
          ),
        ),
      );

      await expectLater(
        find.byKey(const ValueKey<String>('golden-boundary')),
        matchesGoldenFile(
          'goldens/presentation_frame_renderer/composition_$timeUs.png',
        ),
      );
    }
  });

  test('keeps the shared renderer outside runtime and editor internals', () {
    final renderer = File(
      'lib/src/player/presentation_frame_renderer.dart',
    ).readAsStringSync();
    final publicContract = File(
      'lib/presentation_renderer.dart',
    ).readAsStringSync();
    final runtimeImports = Directory('../map_runtime/lib')
        .listSync(recursive: true)
        .whereType<File>()
        .where((file) => file.path.endsWith('.dart'))
        .expand(
          (file) => RegExp(
            "import 'package:map_player_ui/[^']+';",
          ).allMatches(file.readAsStringSync()),
        )
        .toList();

    expect(renderer, isNot(contains('package:map_runtime')));
    expect(renderer, isNot(contains('AnimationController')));
    expect(renderer, isNot(contains('AnimatedOpacity')));
    expect(renderer, isNot(contains('Tween')));
    expect(renderer, isNot(contains('frame.timeUs')));
    expect(publicContract, isNot(contains('package:map_runtime')));
    expect(runtimeImports, isEmpty);
  });
}

Widget _app(
  Widget child, {
  EdgeInsets padding = EdgeInsets.zero,
  bool disableAnimations = false,
}) =>
    MaterialApp(
      theme: PokeMapPlayerTheme.dark(),
      home: MediaQuery(
        data: MediaQueryData(
          padding: padding,
          disableAnimations: disableAnimations,
        ),
        child: Scaffold(body: child),
      ),
    );

PresentationFrame _frame() => PresentationFrame(
      cinematicId: 'opening',
      timeUs: 500000,
      durationUs: 2000000,
      visuals: [
        PresentationVisualFrameClip(
          clipId: 'visual_background',
          trackId: 'visuals',
          layerId: 'background',
          zIndex: 0,
          resourceId: 'media.background',
          startUs: 0,
          durationUs: 2000000,
          elapsedUs: 500000,
          progress: .25,
          easedProgress: .25,
          easing: PresentationEasing.linear,
          composition: PresentationVisualComposition.identity,
          reducedMotionComposition: PresentationVisualComposition.identity,
        ),
        PresentationVisualFrameClip(
          clipId: 'visual_foreground',
          trackId: 'visuals',
          layerId: 'foreground',
          zIndex: 10,
          resourceId: 'media.foreground',
          startUs: 0,
          durationUs: 2000000,
          elapsedUs: 500000,
          progress: .25,
          easedProgress: .25,
          easing: PresentationEasing.linear,
          composition: PresentationVisualComposition.identity,
          reducedMotionComposition: PresentationVisualComposition.identity,
        ),
      ],
      captions: const [
        PresentationCaptionFrameClip(
          clipId: 'caption_primary',
          trackId: 'captions',
          captionId: 'caption.primary',
          startUs: 0,
          durationUs: 2000000,
          elapsedUs: 500000,
          progress: .25,
        ),
      ],
    );

PresentationCinematicAsset _animatedAsset() => PresentationCinematicAsset(
      id: 'animated',
      title: 'Animated',
      durationUs: 1000000,
      layers: [PresentationLayer(id: 'main', label: 'Main', zIndex: 0)],
      tracks: [
        PresentationTrack(
          id: 'visuals',
          label: 'Visuals',
          kind: PresentationTrackKind.visual,
          clips: [
            PresentationVisualClip(
              id: 'composed',
              startUs: 0,
              durationUs: 1000000,
              layerId: 'main',
              resourceId: 'media.foreground',
              easing: PresentationEasing.easeInOut,
              from: PresentationVisualComposition(
                translateX: -0.4,
                scaleX: 0.7,
                scaleY: 0.7,
                opacity: 0.4,
                cropRight: 0.2,
              ),
              to: PresentationVisualComposition(
                translateX: 0.4,
                scaleX: 1.1,
                scaleY: 1.1,
                opacity: 0.9,
                cropLeft: 0.2,
              ),
              transitionIn: PresentationVisualTransition(
                kind: PresentationVisualTransitionKind.slideLeft,
                durationUs: 200000,
              ),
              transitionOut: PresentationVisualTransition(
                kind: PresentationVisualTransitionKind.fade,
                durationUs: 200000,
              ),
            ),
          ],
        ),
      ],
    );

PresentationFrame _frameWithComposition(
  PresentationVisualComposition composition, {
  PresentationVisualComposition? reducedMotionComposition,
  double? reducedFlashOpacity,
  int timeUs = 500000,
}) =>
    PresentationFrame(
      cinematicId: 'opening',
      timeUs: timeUs,
      durationUs: 1000000,
      visuals: [
        PresentationVisualFrameClip(
          clipId: 'composed',
          trackId: 'visuals',
          layerId: 'main',
          zIndex: 0,
          resourceId: 'media.foreground',
          startUs: 0,
          durationUs: 1000000,
          elapsedUs: timeUs,
          progress: timeUs / 1000000,
          easedProgress: timeUs / 1000000,
          easing: PresentationEasing.linear,
          composition: composition,
          reducedMotionComposition: reducedMotionComposition ?? composition,
          reducedFlashOpacity: reducedFlashOpacity ?? composition.opacity,
        ),
      ],
    );

final class _ContentPort implements PresentationFrameContentPort {
  _ContentPort({
    this.missingVisuals = const {},
    this.unsupportedVisuals = const {},
    this.unsupportedCaptions = const {},
  });

  final Set<String> missingVisuals;
  final Set<String> unsupportedVisuals;
  final Set<String> unsupportedCaptions;
  final List<String> visualRequests = [];

  @override
  PresentationVisualResolution resolveVisual({
    required PresentationVisualFrameClip clip,
    required PresentationFrameOrientation orientation,
  }) {
    visualRequests.add('${clip.clipId}:${orientation.name}');
    if (missingVisuals.contains(clip.resourceId)) {
      return PresentationVisualUnavailable(
        reason: PresentationContentUnavailableReason.missing,
        message: 'Média ${clip.resourceId} introuvable',
      );
    }
    if (unsupportedVisuals.contains(clip.resourceId)) {
      return PresentationVisualUnavailable(
        reason: PresentationContentUnavailableReason.unsupported,
        message: 'Média ${clip.resourceId} indisponible',
      );
    }
    return PresentationVisualReady(
      child: ColoredBox(
        key: ValueKey<String>(
          clip.resourceId == 'media.background'
              ? 'resolved-background'
              : 'resolved-foreground',
        ),
        color:
            clip.resourceId == 'media.background' ? Colors.blue : Colors.green,
      ),
    );
  }

  @override
  PresentationCaptionResolution resolveCaption({
    required PresentationCaptionFrameClip clip,
    required Locale locale,
  }) {
    if (unsupportedCaptions.contains(clip.captionId)) {
      return PresentationCaptionUnavailable(
        reason: PresentationContentUnavailableReason.unsupported,
        message: 'Texte ${clip.captionId} indisponible',
      );
    }
    return const PresentationCaptionReady(text: 'Une aventure vous attend');
  }
}

final class _DisposableContentPort implements PresentationFrameContentPort {
  const _DisposableContentPort(this.onDispose);

  final VoidCallback onDispose;

  @override
  PresentationVisualResolution resolveVisual({
    required PresentationVisualFrameClip clip,
    required PresentationFrameOrientation orientation,
  }) =>
      PresentationVisualReady(child: _DisposableVisual(onDispose));

  @override
  PresentationCaptionResolution resolveCaption({
    required PresentationCaptionFrameClip clip,
    required Locale locale,
  }) =>
      const PresentationCaptionUnavailable(
        reason: PresentationContentUnavailableReason.missing,
        message: 'Indisponible',
      );
}

final class _DisposableVisual extends StatefulWidget {
  const _DisposableVisual(this.onDispose);

  final VoidCallback onDispose;

  @override
  State<_DisposableVisual> createState() => _DisposableVisualState();
}

final class _DisposableVisualState extends State<_DisposableVisual> {
  @override
  void dispose() {
    widget.onDispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => const ColoredBox(color: Colors.purple);
}
