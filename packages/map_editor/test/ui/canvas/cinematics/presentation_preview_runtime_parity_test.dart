import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/ui/canvas/cinematics/presentation/presentation_frame_preview.dart';
import 'package:map_player_ui/presentation_renderer.dart';

void main() {
  test('one canonical asset produces a stable evaluation trace', () {
    final asset = _asset();
    const evaluator = PresentationCinematicEvaluator();
    const timestamps = <int>[0, 1_000_000, 2_500_000, 3_000_000, 6_000_000];

    final studioTrace = <PresentationFrame>[
      for (final timeUs in timestamps)
        evaluator.evaluate(asset, timeUs: timeUs),
    ];
    final playerTrace = <PresentationFrame>[
      for (final timeUs in timestamps)
        evaluator.evaluate(asset, timeUs: timeUs),
    ];

    expect(playerTrace, studioTrace);
    expect(studioTrace[3].markers.map((marker) => marker.clipId), <String>[
      'ask-name',
    ]);
    expect(studioTrace.last.timeUs, asset.durationUs);
  });

  testWidgets(
    'Studio and Player expose identical render signatures for one revision',
    (tester) async {
      final asset = _asset();
      const timeUs = 2_500_000;
      final frame = const PresentationCinematicEvaluator().evaluate(
        asset,
        timeUs: timeUs,
      );
      final assetRevision = sha256
          .convert(
            utf8.encode(jsonEncode(encodePresentationCinematicAsset(asset))),
          )
          .toString();
      const binding = PresentationFrameMediaBinding(
        clipId: 'hero',
        kind: PresentationFrameMediaKind.image,
        landscapeResourceId: 'hero-landscape',
        portraitResourceId: 'hero-portrait',
      );

      expect(frame.cinematicId, asset.id);
      expect(frame.timeUs, timeUs);

      for (final orientation in PresentationFrameOrientation.values) {
        final editorPort = _ContentPort();
        final playerPort = _ContentPort();
        final editorSignature = await _renderSignature(
          tester,
          orientation: orientation,
          child: PresentationFramePreview(
            frame: frame,
            orientation: orientation,
            contentPort: PresentationResponsiveFrameContentPort(
              delegate: editorPort,
              bindings: const <PresentationFrameMediaBinding>[binding],
            ),
            playerTheme: PokeMapPlayerTheme.dark(),
          ),
        );
        final snapshot = RuntimePresentationFrameSnapshot(
          assetRevision: assetRevision,
          frame: frame,
          orientation: orientation,
          mediaBindings: const <PresentationFrameMediaBinding>[binding],
        );
        final playerSignature = await _renderSignature(
          tester,
          orientation: orientation,
          child: RuntimePresentationFrameSurface(
            snapshot: snapshot,
            contentPort: playerPort,
          ),
        );

        expect(snapshot.assetRevision, assetRevision);
        expect(identical(snapshot.frame, frame), isTrue);
        expect(playerSignature, editorSignature, reason: orientation.name);
        final expectedResource = switch (orientation) {
          PresentationFrameOrientation.landscape => 'hero-landscape',
          PresentationFrameOrientation.portrait => 'hero-portrait',
        };
        expect(editorPort.visualRequests, <String>[expectedResource]);
        expect(playerPort.visualRequests, <String>[expectedResource]);
      }
    },
  );

  testWidgets('Studio and Player share the one-source responsive fallback', (
    tester,
  ) async {
    final frame = const PresentationCinematicEvaluator().evaluate(
      _asset(),
      timeUs: 2_500_000,
    );
    const binding = PresentationFrameMediaBinding(
      clipId: 'hero',
      kind: PresentationFrameMediaKind.video,
      portraitResourceId: 'hero-portrait-only',
    );
    final editorPort = _ContentPort();
    final playerPort = _ContentPort();

    await _renderSignature(
      tester,
      orientation: PresentationFrameOrientation.landscape,
      child: PresentationFramePreview(
        frame: frame,
        orientation: PresentationFrameOrientation.landscape,
        contentPort: PresentationResponsiveFrameContentPort(
          delegate: editorPort,
          bindings: const <PresentationFrameMediaBinding>[binding],
        ),
        playerTheme: PokeMapPlayerTheme.dark(),
      ),
    );
    await _renderSignature(
      tester,
      orientation: PresentationFrameOrientation.landscape,
      child: RuntimePresentationFrameSurface(
        snapshot: RuntimePresentationFrameSnapshot(
          assetRevision: 'revision-fallback',
          frame: frame,
          orientation: PresentationFrameOrientation.landscape,
          mediaBindings: const <PresentationFrameMediaBinding>[binding],
        ),
        contentPort: playerPort,
      ),
    );

    expect(editorPort.visualRequests, <String>['hero-portrait-only']);
    expect(playerPort.visualRequests, editorPort.visualRequests);
    expect(tester.takeException(), isNull);
  });
}

Future<Map<String, Object?>> _renderSignature(
  WidgetTester tester, {
  required PresentationFrameOrientation orientation,
  required Widget child,
}) async {
  final size = switch (orientation) {
    PresentationFrameOrientation.landscape => const Size(400, 225),
    PresentationFrameOrientation.portrait => const Size(225, 400),
  };
  await tester.binding.setSurfaceSize(const Size(500, 500));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    MaterialApp(
      locale: const Locale('fr'),
      theme: PokeMapPlayerTheme.dark(),
      home: Center(
        child: SizedBox(
          width: size.width,
          height: size.height,
          child: RepaintBoundary(
            key: const ValueKey<String>('parity-boundary'),
            child: child,
          ),
        ),
      ),
    ),
  );
  await tester.pump();
  final boundary = find.byKey(const ValueKey<String>('parity-boundary'));
  final canvas = find.descendant(
    of: boundary,
    matching: find.byKey(
      ValueKey<String>('presentation-frame-canvas-${orientation.name}'),
    ),
  );
  final keyedWidgets = tester
      .widgetList<Widget>(
        find.descendant(
          of: boundary,
          matching: find.byWidgetPredicate(
            (widget) => widget.key is ValueKey<String>,
          ),
        ),
      )
      .map((widget) => widget.key)
      .whereType<ValueKey<String>>()
      .map((key) => key.value)
      .where((value) => value.startsWith('presentation-'))
      .toList(growable: false);
  final opacities = tester
      .widgetList<Opacity>(
        find.descendant(of: boundary, matching: find.byType(Opacity)),
      )
      .map((widget) => widget.opacity)
      .toList(growable: false);
  final texts = tester
      .widgetList<Text>(
        find.descendant(of: boundary, matching: find.byType(Text)),
      )
      .map((widget) => widget.data)
      .whereType<String>()
      .toList(growable: false);
  return <String, Object?>{
    'size': tester.getSize(canvas),
    'keys': keyedWidgets,
    'opacities': opacities,
    'texts': texts,
  };
}

PresentationCinematicAsset _asset() => PresentationCinematicAsset(
  id: 'opening',
  title: 'Ouverture',
  durationUs: 6_000_000,
  layers: <PresentationLayer>[
    PresentationLayer(id: 'background', label: 'Fond', zIndex: 0),
    PresentationLayer(id: 'title', label: 'Titre', zIndex: 1),
  ],
  tracks: <PresentationTrack>[
    PresentationTrack(
      id: 'visuals',
      label: 'Visuels',
      kind: PresentationTrackKind.visual,
      clips: <PresentationClip>[
        PresentationVisualClip(
          id: 'hero',
          startUs: 0,
          durationUs: 6_000_000,
          layerId: 'background',
          resourceId: 'hero-shared',
          landscapeResourceId: 'hero-landscape',
          portraitResourceId: 'hero-portrait',
          from: PresentationVisualComposition(opacity: .2),
          to: PresentationVisualComposition(opacity: 1),
        ),
        PresentationTextClip(
          id: 'title',
          startUs: 1_000_000,
          durationUs: 4_000_000,
          layerId: 'title',
          text: 'Une aventure vous attend',
        ),
      ],
    ),
    PresentationTrack(
      id: 'music',
      label: 'Musique',
      kind: PresentationTrackKind.audio,
      clips: <PresentationClip>[
        PresentationAudioClip(
          id: 'music',
          startUs: 0,
          durationUs: 6_000_000,
          resourceId: 'music-shared',
          audioKind: PresentationAudioKind.music,
          loop: true,
        ),
      ],
    ),
    PresentationTrack(
      id: 'captions',
      label: 'Sous-titres',
      kind: PresentationTrackKind.caption,
      clips: <PresentationClip>[
        PresentationCaptionClip(
          id: 'caption',
          startUs: 1_000_000,
          durationUs: 4_000_000,
          captionId: 'opening.caption',
        ),
      ],
    ),
    PresentationTrack(
      id: 'markers',
      label: 'Repères',
      kind: PresentationTrackKind.marker,
      clips: <PresentationClip>[
        PresentationMarkerClip(
          id: 'ask-name',
          startUs: 3_000_000,
          label: 'Demander le nom',
          markerKind: PresentationMarkerKind.interactionCue,
        ),
      ],
    ),
  ],
);

final class _ContentPort implements PresentationFrameContentPort {
  final visualRequests = <String>[];

  @override
  PresentationVisualResolution resolveVisual({
    required PresentationVisualFrameClip clip,
    required PresentationFrameOrientation orientation,
  }) {
    visualRequests.add(clip.resourceId);
    return PresentationVisualReady(
      child: ColoredBox(
        color: clip.resourceId.contains('portrait')
            ? const Color(0xFF9C5FFF)
            : const Color(0xFF2A78FF),
      ),
    );
  }

  @override
  PresentationCaptionResolution resolveCaption({
    required PresentationCaptionFrameClip clip,
    required Locale locale,
  }) => const PresentationCaptionReady(text: 'Une aventure vous attend');
}
