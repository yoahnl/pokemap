import 'dart:math';

import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('PresentationCinematicEvaluator', () {
    test('clamps seeks and evaluates half-open clips and exact markers', () {
      const evaluator = PresentationCinematicEvaluator();
      final asset = _boundaryAsset();

      final before = evaluator.evaluate(asset, timeUs: -1);
      final visualStart = evaluator.evaluate(asset, timeUs: 2);
      final visualEnd = evaluator.evaluate(asset, timeUs: 8);
      final end = evaluator.evaluate(asset, timeUs: 10);
      final after = evaluator.evaluate(asset, timeUs: 11);

      expect(before.timeUs, 0);
      expect(before.visuals, isEmpty);
      expect(before.audio.single.progress, 0);
      expect(before.markers.map((marker) => marker.clipId), ['marker_start']);
      expect(visualStart.visuals.single.progress, 0);
      expect(visualEnd.visuals, isEmpty);
      expect(end.timeUs, 10);
      expect(end.audio, isEmpty);
      expect(end.markers.map((marker) => marker.clipId), ['marker_end']);
      expect(after, end);
    });

    test(
      'resolves simultaneous tracks in canonical declaration-free order',
      () {
        const evaluator = PresentationCinematicEvaluator();
        final canonical = evaluator.evaluate(
          _simultaneousAsset(reverseDeclarations: false),
          timeUs: 5,
        );
        final reversed = evaluator.evaluate(
          _simultaneousAsset(reverseDeclarations: true),
          timeUs: 5,
        );

        expect(canonical, reversed);
        expect(canonical.visuals.map((clip) => clip.clipId), [
          'visual_background',
          'visual_foreground',
        ]);
        expect(canonical.audio.map((clip) => clip.clipId), [
          'audio_ambience',
          'audio_music',
        ]);
        expect(canonical.captions.map((clip) => clip.clipId), [
          'caption_a',
          'caption_b',
        ]);
        expect(
          () => canonical.visuals.add(canonical.visuals.first),
          throwsUnsupportedError,
        );
      },
    );

    test('evaluates every easing with canonical quadratic curves', () {
      const evaluator = PresentationCinematicEvaluator();
      final asset = _easingAsset();

      final quarter = evaluator.evaluate(asset, timeUs: 25);
      final threeQuarters = evaluator.evaluate(asset, timeUs: 75);
      final quarterById = {
        for (final visual in quarter.visuals) visual.clipId: visual,
      };
      final threeQuartersById = {
        for (final visual in threeQuarters.visuals) visual.clipId: visual,
      };

      expect(quarterById['linear']!.progress, 0.25);
      expect(quarterById['linear']!.easedProgress, 0.25);
      expect(quarterById['ease_in']!.easedProgress, 0.0625);
      expect(quarterById['ease_out']!.easedProgress, 0.4375);
      expect(quarterById['ease_in_out']!.easedProgress, 0.125);
      expect(threeQuartersById['ease_in_out']!.easedProgress, 0.875);
    });

    test('returns equal frames for repeated random seeks', () {
      const evaluator = PresentationCinematicEvaluator();
      final asset = _simultaneousAsset(reverseDeclarations: false);
      final random = Random(15015);
      final seeks = List.generate(500, (_) => random.nextInt(31) - 10);

      final firstPass = [
        for (final timeUs in seeks) evaluator.evaluate(asset, timeUs: timeUs),
      ];
      final secondPass = [
        for (final timeUs in seeks) evaluator.evaluate(asset, timeUs: timeUs),
      ];

      expect(secondPass, firstPass);
      expect(
        secondPass.map((frame) => frame.hashCode),
        firstPass.map((frame) => frame.hashCode),
      );
    });

    test('keeps clips from every active track without framerate input', () {
      const evaluator = PresentationCinematicEvaluator();
      final asset = _simultaneousAsset(reverseDeclarations: false);

      final frame = evaluator.evaluate(asset, timeUs: 5);

      expect(frame.cinematicId, 'simultaneous');
      expect(frame.durationUs, 10);
      expect(frame.visuals, hasLength(2));
      expect(frame.audio, hasLength(2));
      expect(frame.captions, hasLength(2));
      expect(frame.markers, hasLength(2));
    });
  });
}

PresentationCinematicAsset _boundaryAsset() {
  return PresentationCinematicAsset(
    id: 'boundaries',
    title: 'Boundaries',
    durationUs: 10,
    layers: [PresentationLayer(id: 'main', label: 'Main', zIndex: 0)],
    tracks: [
      PresentationTrack(
        id: 'visual',
        label: 'Visual',
        kind: PresentationTrackKind.visual,
        clips: [
          PresentationVisualClip(
            id: 'visual_clip',
            startUs: 2,
            durationUs: 6,
            layerId: 'main',
            resourceId: 'media.visual',
          ),
        ],
      ),
      PresentationTrack(
        id: 'audio',
        label: 'Audio',
        kind: PresentationTrackKind.audio,
        clips: [
          PresentationAudioClip(
            id: 'audio_clip',
            startUs: 0,
            durationUs: 10,
            resourceId: 'media.audio',
          ),
        ],
      ),
      PresentationTrack(
        id: 'markers',
        label: 'Markers',
        kind: PresentationTrackKind.marker,
        clips: [
          PresentationMarkerClip(
            id: 'marker_start',
            startUs: 0,
            label: 'Start',
          ),
          PresentationMarkerClip(id: 'marker_end', startUs: 10, label: 'End'),
        ],
      ),
    ],
  );
}

PresentationCinematicAsset _simultaneousAsset({
  required bool reverseDeclarations,
}) {
  final layers = [
    PresentationLayer(id: 'background', label: 'Background', zIndex: 0),
    PresentationLayer(id: 'foreground', label: 'Foreground', zIndex: 10),
  ];
  final tracks = [
    PresentationTrack(
      id: 'visual_z',
      label: 'Visual',
      kind: PresentationTrackKind.visual,
      clips: [
        PresentationVisualClip(
          id: 'visual_foreground',
          startUs: 0,
          durationUs: 10,
          layerId: 'foreground',
          resourceId: 'media.foreground',
        ),
        PresentationVisualClip(
          id: 'visual_background',
          startUs: 0,
          durationUs: 10,
          layerId: 'background',
          resourceId: 'media.background',
        ),
      ],
    ),
    PresentationTrack(
      id: 'audio_z',
      label: 'Audio Z',
      kind: PresentationTrackKind.audio,
      clips: [
        PresentationAudioClip(
          id: 'audio_music',
          startUs: 0,
          durationUs: 10,
          resourceId: 'media.music',
        ),
      ],
    ),
    PresentationTrack(
      id: 'audio_a',
      label: 'Audio A',
      kind: PresentationTrackKind.audio,
      clips: [
        PresentationAudioClip(
          id: 'audio_ambience',
          startUs: 0,
          durationUs: 10,
          resourceId: 'media.ambience',
        ),
      ],
    ),
    PresentationTrack(
      id: 'caption_z',
      label: 'Caption Z',
      kind: PresentationTrackKind.caption,
      clips: [
        PresentationCaptionClip(
          id: 'caption_b',
          startUs: 0,
          durationUs: 10,
          captionId: 'caption.b',
        ),
      ],
    ),
    PresentationTrack(
      id: 'caption_a',
      label: 'Caption A',
      kind: PresentationTrackKind.caption,
      clips: [
        PresentationCaptionClip(
          id: 'caption_a',
          startUs: 0,
          durationUs: 10,
          captionId: 'caption.a',
        ),
      ],
    ),
    PresentationTrack(
      id: 'markers_z',
      label: 'Markers Z',
      kind: PresentationTrackKind.marker,
      clips: [PresentationMarkerClip(id: 'marker_b', startUs: 5, label: 'B')],
    ),
    PresentationTrack(
      id: 'markers_a',
      label: 'Markers A',
      kind: PresentationTrackKind.marker,
      clips: [PresentationMarkerClip(id: 'marker_a', startUs: 5, label: 'A')],
    ),
  ];
  return PresentationCinematicAsset(
    id: 'simultaneous',
    title: 'Simultaneous',
    durationUs: 10,
    layers: reverseDeclarations ? layers.reversed.toList() : layers,
    tracks: reverseDeclarations ? tracks.reversed.toList() : tracks,
  );
}

PresentationCinematicAsset _easingAsset() {
  final easings = {
    'linear': PresentationEasing.linear,
    'ease_in': PresentationEasing.easeIn,
    'ease_out': PresentationEasing.easeOut,
    'ease_in_out': PresentationEasing.easeInOut,
  };
  return PresentationCinematicAsset(
    id: 'easings',
    title: 'Easings',
    durationUs: 100,
    layers: [
      for (final id in easings.keys)
        PresentationLayer(id: id, label: id, zIndex: 0),
    ],
    tracks: [
      PresentationTrack(
        id: 'visual',
        label: 'Visual',
        kind: PresentationTrackKind.visual,
        clips: [
          for (final entry in easings.entries)
            PresentationVisualClip(
              id: entry.key,
              startUs: 0,
              durationUs: 100,
              layerId: entry.key,
              resourceId: 'media.${entry.key}',
              easing: entry.value,
            ),
        ],
      ),
    ],
  );
}
