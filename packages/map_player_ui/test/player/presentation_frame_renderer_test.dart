import 'dart:io';

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
    expect(publicContract, isNot(contains('package:map_runtime')));
    expect(runtimeImports, isEmpty);
  });
}

Widget _app(Widget child, {EdgeInsets padding = EdgeInsets.zero}) =>
    MaterialApp(
      theme: PokeMapPlayerTheme.dark(),
      home: MediaQuery(
        data: MediaQueryData(padding: padding),
        child: Scaffold(body: child),
      ),
    );

PresentationFrame _frame() => PresentationFrame(
      cinematicId: 'opening',
      timeUs: 500000,
      durationUs: 2000000,
      visuals: const [
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
