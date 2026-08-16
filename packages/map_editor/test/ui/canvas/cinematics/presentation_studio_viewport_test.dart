import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/l10n/app_localizations.dart';
import 'package:map_editor/src/theme/theme.dart';
import 'package:map_editor/src/ui/canvas/cinematics/presentation/presentation_studio_viewport.dart';
import 'package:map_player_ui/presentation_renderer.dart';

void main() {
  testWidgets('English viewport stays operable at 200 percent text scale', (
    tester,
  ) async {
    await _pumpViewport(
      tester,
      locale: const Locale('en'),
      textScaler: const TextScaler.linear(2),
    );

    expect(
      tester.getSemantics(find.byKey(presentationStudioViewportKey)).label,
      startsWith('Presentation cinematic canvas'),
    );
    expect(find.text('No content to display'), findsOneWidget);
    expect(find.byTooltip('Zoom out'), findsOneWidget);
    expect(find.byTooltip('Zoom in'), findsOneWidget);
    expect(find.byTooltip('Fit frame'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  test(
    'viewport controller keeps zoom, pan, fit and recenter deterministic',
    () {
      final controller = PresentationStudioViewportController();

      controller.zoomIn();
      controller.panBy(const Offset(24, -12));

      expect(controller.zoom, 1.25);
      expect(controller.pan, const Offset(24, -12));

      controller.recenter();
      expect(controller.zoom, 1.25);
      expect(controller.pan, Offset.zero);

      controller.fit();
      expect(controller.zoom, 1);
      expect(controller.pan, Offset.zero);
    },
  );

  test('viewport controller clamps pan to the visible frame bounds', () {
    final controller = PresentationStudioViewportController();
    controller.configureBounds(
      viewportSize: const Size(800, 600),
      frameSize: const Size(640, 360),
    );

    controller.panBy(const Offset(10000, -10000));
    expect(controller.pan, const Offset(48, -48));

    controller.zoomIn();
    controller.zoomIn();
    controller.panBy(const Offset(10000, -10000));
    expect(controller.pan, const Offset(100, -48));

    controller.zoomOut();
    expect(controller.pan, const Offset(48, -48));
  });

  testWidgets('viewport clips the transformed frame to its workspace', (
    tester,
  ) async {
    final controller = PresentationStudioViewportController();
    await _pumpViewport(
      tester,
      controller: controller,
      frame: PresentationFrame(
        cinematicId: 'opening',
        timeUs: 0,
        durationUs: 1000000,
      ),
    );

    expect(
      find.ancestor(
        of: find.byKey(presentationStudioViewportTransformKey),
        matching: find.byType(ClipRect),
      ),
      findsOneWidget,
    );
    controller.panBy(const Offset(10000, 10000));
    await tester.pump();

    final viewportRect = tester.getRect(
      find.byKey(presentationStudioViewportGestureKey),
    );
    final frameRect = tester.getRect(
      find.byKey(presentationStudioViewportFrameKey),
    );
    expect(viewportRect.contains(frameRect.center), isTrue);
  });

  testWidgets(
    'viewport forwards the exact frame to the shared Player renderer',
    (tester) async {
      final frame = PresentationFrame(
        cinematicId: 'opening',
        timeUs: 0,
        durationUs: 1000000,
      );
      const port = _ContentPort();

      await _pumpViewport(tester, frame: frame, contentPort: port);

      final renderer = tester.widget<PresentationFrameRenderer>(
        find.byType(PresentationFrameRenderer),
      );
      expect(identical(renderer.frame, frame), isTrue);
      expect(identical(renderer.contentPort, port), isTrue);
      expect(renderer.orientation, PresentationFrameOrientation.landscape);
      expect(find.textContaining('monde'), findsNothing);
      expect(find.textContaining('acteur'), findsNothing);
      expect(find.textContaining('Flame'), findsNothing);
    },
  );

  testWidgets(
    'keyboard zoom, pan and fit only change ephemeral viewport state',
    (tester) async {
      final controller = PresentationStudioViewportController();
      await _pumpViewport(
        tester,
        controller: controller,
        frame: PresentationFrame(
          cinematicId: 'opening',
          timeUs: 0,
          durationUs: 1000000,
        ),
      );

      await tester.tap(find.byKey(presentationStudioViewportKey));
      await tester.sendKeyEvent(LogicalKeyboardKey.equal);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump();

      expect(controller.zoom, 1.25);
      expect(controller.pan.dx, 24);
      expect(find.text('125 %'), findsOneWidget);

      await tester.sendKeyEvent(LogicalKeyboardKey.keyF);
      await tester.pump();

      expect(controller.zoom, 1);
      expect(controller.pan, Offset.zero);
      expect(find.text('100 %'), findsOneWidget);
    },
  );

  testWidgets('pointer drag pans and wheel zooms around the canvas', (
    tester,
  ) async {
    final controller = PresentationStudioViewportController();
    await _pumpViewport(
      tester,
      controller: controller,
      frame: PresentationFrame(
        cinematicId: 'opening',
        timeUs: 0,
        durationUs: 1000000,
      ),
    );

    await tester.drag(
      find.byKey(presentationStudioViewportGestureKey),
      const Offset(30, 18),
    );
    await tester.pump();
    expect(controller.pan.dx, greaterThan(0));
    expect(controller.pan.dy, greaterThan(0));

    final center = tester.getCenter(
      find.byKey(presentationStudioViewportGestureKey),
    );
    final pointer = TestPointer(1, PointerDeviceKind.mouse);
    await tester.sendEventToBinding(pointer.hover(center));
    await tester.sendEventToBinding(
      pointer.scroll(const Offset(0, -40), timeStamp: Duration.zero),
    );
    await tester.pump();

    expect(controller.zoom, 1.25);
  });

  testWidgets('selected content drag emits normalized frame deltas', (
    tester,
  ) async {
    final deltas = <Offset>[];
    await _pumpViewport(
      tester,
      frame: PresentationFrame(
        cinematicId: 'opening',
        timeUs: 0,
        durationUs: 1000000,
      ),
      onCompositionDrag: deltas.add,
    );
    final frameRect = tester.getRect(
      find.byKey(presentationStudioViewportFrameKey),
    );

    await tester.drag(
      find.byKey(presentationStudioViewportFrameKey),
      Offset(frameRect.width * .2, frameRect.height * -.1),
    );
    await tester.pump();

    final total = deltas.fold<Offset>(Offset.zero, (sum, item) => sum + item);
    expect(deltas, hasLength(1));
    expect(total.dx, closeTo(.2, .01));
    expect(total.dy, closeTo(-.1, .01));
  });

  testWidgets(
    'empty, missing media and renderer error keep the canvas explicit',
    (tester) async {
      await _pumpViewport(tester);
      expect(find.text('Aucun contenu à afficher'), findsOneWidget);
      expect(find.byKey(presentationStudioSafeAreaKey), findsOneWidget);

      await _pumpViewport(
        tester,
        frame: _missingMediaFrame(),
        contentPort: const _MissingContentPort(),
      );
      expect(find.text('Média hero introuvable'), findsOneWidget);
      final frameSize = tester.getSize(
        find.byKey(presentationStudioViewportFrameKey),
      );
      expect(frameSize.width / frameSize.height, closeTo(16 / 9, 0.001));

      await _pumpViewport(
        tester,
        state: PresentationStudioViewportState.error,
        errorMessage: 'Le renderer ne peut pas produire cette frame.',
      );
      expect(
        find.text('Le renderer ne peut pas produire cette frame.'),
        findsOneWidget,
      );
      expect(find.bySemanticsLabel('Réessayer le rendu'), findsOneWidget);
    },
  );

  for (final size in <Size>[
    const Size(1280, 800),
    const Size(1672, 941),
    const Size(1920, 1080),
  ]) {
    final sizeName = '${size.width.toInt()}x${size.height.toInt()}';
    for (final fixture
        in <
          ({
            String name,
            PresentationFrame? frame,
            PresentationFrameContentPort port,
            PresentationStudioViewportState state,
            String? errorMessage,
          })
        >[
          (
            name: 'empty',
            frame: null,
            port: const _ContentPort(),
            state: PresentationStudioViewportState.ready,
            errorMessage: null,
          ),
          (
            name: 'static',
            frame: _missingMediaFrame(),
            port: const _ContentPort(),
            state: PresentationStudioViewportState.ready,
            errorMessage: null,
          ),
          (
            name: 'missing',
            frame: _missingMediaFrame(),
            port: const _MissingContentPort(),
            state: PresentationStudioViewportState.ready,
            errorMessage: null,
          ),
          (
            name: 'error',
            frame: null,
            port: const _ContentPort(),
            state: PresentationStudioViewportState.error,
            errorMessage: 'Le renderer ne peut pas produire cette frame.',
          ),
        ]) {
      testWidgets('viewport ${fixture.name} matches $sizeName', (tester) async {
        await _pumpViewport(
          tester,
          surfaceSize: size,
          frame: fixture.frame,
          contentPort: fixture.port,
          state: fixture.state,
          errorMessage: fixture.errorMessage,
        );

        await expectLater(
          find.byKey(presentationStudioViewportKey),
          matchesGoldenFile(
            File(
              'test/goldens/narrative_studio/cinematics/'
              'presentation_studio_viewport_${fixture.name}_$sizeName.png',
            ).absolute.path,
          ),
        );
      });
    }
  }
}

Future<void> _pumpViewport(
  WidgetTester tester, {
  PresentationStudioViewportController? controller,
  PresentationFrame? frame,
  PresentationFrameContentPort contentPort = const _ContentPort(),
  PresentationStudioViewportState state = PresentationStudioViewportState.ready,
  String? errorMessage,
  Size surfaceSize = const Size(900, 620),
  Locale locale = const Locale('fr'),
  TextScaler textScaler = TextScaler.noScaling,
  ValueChanged<Offset>? onCompositionDrag,
}) async {
  tester.view.physicalSize = surfaceSize;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  if (controller != null) addTearDown(controller.dispose);

  await tester.pumpWidget(
    MaterialApp(
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      theme: PokeMapTheme.dark(),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(textScaler: textScaler),
        child: child!,
      ),
      home: Scaffold(
        body: PresentationStudioViewport(
          controller: controller,
          frame: frame,
          orientation: PresentationFrameOrientation.landscape,
          contentPort: contentPort,
          playerTheme: PokeMapPlayerTheme.dark(),
          state: state,
          errorMessage: errorMessage,
          onRetry: () {},
          onCompositionDrag: onCompositionDrag,
        ),
      ),
    ),
  );
  await tester.pump();
}

PresentationFrame _missingMediaFrame() => PresentationFrame(
  cinematicId: 'opening',
  timeUs: 0,
  durationUs: 1000000,
  visuals: <PresentationVisualFrameClip>[
    PresentationVisualFrameClip(
      clipId: 'hero-clip',
      trackId: 'visuals',
      layerId: 'hero-layer',
      zIndex: 0,
      resourceId: 'hero',
      startUs: 0,
      durationUs: 1000000,
      elapsedUs: 0,
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
  }) => const PresentationVisualReady(
    child: ColoredBox(color: Color(0xff315da8)),
  );

  @override
  PresentationCaptionResolution resolveCaption({
    required PresentationCaptionFrameClip clip,
    required Locale locale,
  }) => const PresentationCaptionReady(text: 'Une aventure vous attend');
}

final class _MissingContentPort implements PresentationFrameContentPort {
  const _MissingContentPort();

  @override
  PresentationVisualResolution resolveVisual({
    required PresentationVisualFrameClip clip,
    required PresentationFrameOrientation orientation,
  }) => PresentationVisualUnavailable(
    reason: PresentationContentUnavailableReason.missing,
    message: 'Média ${clip.resourceId} introuvable',
  );

  @override
  PresentationCaptionResolution resolveCaption({
    required PresentationCaptionFrameClip clip,
    required Locale locale,
  }) => const PresentationCaptionUnavailable(
    reason: PresentationContentUnavailableReason.missing,
    message: 'Sous-titre introuvable',
  );
}
