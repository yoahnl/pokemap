import 'dart:convert';
import 'dart:io';

import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('PresentationCinematicAsset', () {
    test('round-trips a canonical responsive timeline in stable JSON', () {
      final asset = PresentationCinematicAsset(
        id: 'presentation_opening',
        title: 'Ouverture',
        description: 'Introduction avant la nouvelle partie.',
        durationUs: 12_000_000,
        layers: [
          PresentationLayer(id: 'background', label: 'Fond', zIndex: 0),
          PresentationLayer(id: 'title', label: 'Titre', zIndex: 10),
        ],
        tracks: [
          PresentationTrack(
            id: 'visuals',
            label: 'Visuels',
            kind: PresentationTrackKind.visual,
            clips: [
              PresentationVisualClip(
                id: 'background_clip',
                startUs: 0,
                durationUs: 12_000_000,
                layerId: 'background',
                resourceId: 'media_opening_background',
              ),
              PresentationVisualClip(
                id: 'title_clip',
                startUs: 2_000_000,
                durationUs: 6_000_000,
                layerId: 'title',
                resourceId: 'text_opening_title',
                easing: PresentationEasing.easeInOut,
              ),
            ],
          ),
          PresentationTrack(
            id: 'music',
            label: 'Musique',
            kind: PresentationTrackKind.audio,
            clips: [
              PresentationAudioClip(
                id: 'music_clip',
                startUs: 0,
                durationUs: 12_000_000,
                resourceId: 'media_opening_music',
              ),
            ],
          ),
          PresentationTrack(
            id: 'captions',
            label: 'Sous-titres',
            kind: PresentationTrackKind.caption,
            clips: [
              PresentationCaptionClip(
                id: 'caption_clip',
                startUs: 2_000_000,
                durationUs: 3_000_000,
                captionId: 'caption_opening_welcome',
              ),
            ],
          ),
          PresentationTrack(
            id: 'markers',
            label: 'Repères',
            kind: PresentationTrackKind.marker,
            clips: [
              PresentationMarkerClip(
                id: 'cue_player_name',
                startUs: 8_000_000,
                label: 'Demander le nom',
                markerKind: PresentationMarkerKind.interactionCue,
              ),
            ],
          ),
        ],
      );

      final encoded = encodePresentationCinematicAsset(asset);
      final decoded = decodePresentationCinematicAsset(
        jsonDecode(jsonEncode(encoded)),
      );
      final encodedAgain = encodePresentationCinematicAsset(decoded);

      expect(decoded, asset);
      expect(jsonEncode(encodedAgain), jsonEncode(encoded));
      expect(encoded['schemaVersion'], 1);
      expect(encoded['capabilities'], ['cinematic.presentation']);
      expect(encoded['timebase'], {
        'unit': 'microsecond',
        'ticksPerSecond': 1000000,
      });
    });

    test('uses deterministic defaults for a minimal asset', () {
      final asset = PresentationCinematicAsset(
        id: 'presentation_minimal',
        title: 'Minimal',
        durationUs: 1,
      );

      expect(encodePresentationCinematicAsset(asset), {
        'schemaVersion': 1,
        'capabilities': ['cinematic.presentation'],
        'timebase': {'unit': 'microsecond', 'ticksPerSecond': 1000000},
        'id': 'presentation_minimal',
        'title': 'Minimal',
        'durationUs': 1,
        'layers': <Object?>[],
        'tracks': <Object?>[],
      });
      expect(asset.layers, isEmpty);
      expect(asset.tracks, isEmpty);
    });

    test(
      'represents simultaneous and overlapping clips without reordering',
      () {
        final clips = [
          PresentationVisualClip(
            id: 'clip_a',
            startUs: 0,
            durationUs: 7_000_000,
            layerId: 'layer_a',
            resourceId: 'media_a',
          ),
          PresentationVisualClip(
            id: 'clip_b',
            startUs: 2_000_000,
            durationUs: 6_000_000,
            layerId: 'layer_b',
            resourceId: 'media_b',
          ),
        ];
        final asset = PresentationCinematicAsset(
          id: 'presentation_overlap',
          title: 'Overlap',
          durationUs: 8_000_000,
          layers: [
            PresentationLayer(id: 'layer_a', label: 'A', zIndex: 0),
            PresentationLayer(id: 'layer_b', label: 'B', zIndex: 1),
          ],
          tracks: [
            PresentationTrack(
              id: 'visuals',
              label: 'Visuels',
              kind: PresentationTrackKind.visual,
              clips: clips,
            ),
          ],
        );

        final decoded = decodePresentationCinematicAsset(
          encodePresentationCinematicAsset(asset),
        );

        expect(decoded.tracks.single.clips, clips);
        expect(decoded.tracks.single.clips[0].endUs, 7_000_000);
        expect(decoded.tracks.single.clips[1].startUs, 2_000_000);
      },
    );

    test('round-trips canonical visual composition and transitions', () {
      final asset = PresentationCinematicAsset(
        id: 'presentation_composition',
        title: 'Composition',
        durationUs: 1_000_000,
        layers: [PresentationLayer(id: 'hero', label: 'Hero', zIndex: 7)],
        tracks: [
          PresentationTrack(
            id: 'visuals',
            label: 'Visuels',
            kind: PresentationTrackKind.visual,
            clips: [
              PresentationVisualClip(
                id: 'hero_clip',
                startUs: 0,
                durationUs: 1_000_000,
                layerId: 'hero',
                resourceId: 'media.hero',
                easing: PresentationEasing.easeInOut,
                from: PresentationVisualComposition(
                  translateX: -0.25,
                  translateY: 0.1,
                  scaleX: 0.8,
                  scaleY: 0.9,
                  rotationTurns: -0.05,
                  opacity: 0.2,
                  cropLeft: 0.1,
                  cropTop: 0.05,
                ),
                to: PresentationVisualComposition(
                  translateX: 0.25,
                  translateY: -0.1,
                  scaleX: 1.2,
                  scaleY: 1.1,
                  rotationTurns: 0.05,
                  opacity: 0.9,
                  cropRight: 0.1,
                  cropBottom: 0.05,
                ),
                transitionIn: PresentationVisualTransition(
                  kind: PresentationVisualTransitionKind.slideLeft,
                  durationUs: 200_000,
                ),
                transitionOut: PresentationVisualTransition(
                  kind: PresentationVisualTransitionKind.fade,
                  durationUs: 300_000,
                ),
              ),
            ],
          ),
        ],
      );

      final encoded = encodePresentationCinematicAsset(asset);
      final decoded = decodePresentationCinematicAsset(
        jsonDecode(jsonEncode(encoded)),
      );
      final clip =
          (encoded['tracks']! as List<Object?>).single as Map<String, Object?>;
      final visual =
          (clip['clips']! as List<Object?>).single as Map<String, Object?>;

      expect(decoded, asset);
      expect(visual['from'], {
        'translateX': -0.25,
        'translateY': 0.1,
        'scaleX': 0.8,
        'scaleY': 0.9,
        'rotationTurns': -0.05,
        'opacity': 0.2,
        'cropLeft': 0.1,
        'cropTop': 0.05,
        'cropRight': 0.0,
        'cropBottom': 0.0,
      });
      expect(visual['transitionIn'], {
        'kind': 'slideLeft',
        'durationUs': 200000,
      });
      expect(visual['transitionOut'], {'kind': 'fade', 'durationUs': 300000});
    });

    test('rejects invalid crop, opacity and transition durations', () {
      expect(
        () => PresentationVisualComposition(opacity: 1.1),
        throwsA(isA<PresentationCinematicValidationException>()),
      );
      expect(
        () => PresentationVisualComposition(cropLeft: 0.6, cropRight: 0.4),
        throwsA(isA<PresentationCinematicValidationException>()),
      );
      expect(
        () => PresentationVisualClip(
          id: 'visual',
          startUs: 0,
          durationUs: 10,
          layerId: 'layer',
          resourceId: 'media',
          transitionIn: PresentationVisualTransition(
            kind: PresentationVisualTransitionKind.fade,
            durationUs: 11,
          ),
        ),
        throwsA(isA<PresentationCinematicValidationException>()),
      );
    });

    test('rejects incompatible tracks, duplicate ids and dangling layers', () {
      expect(
        () => PresentationTrack(
          id: 'visuals',
          label: 'Visuels',
          kind: PresentationTrackKind.visual,
          clips: [
            PresentationAudioClip(
              id: 'audio',
              startUs: 0,
              durationUs: 1,
              resourceId: 'music',
            ),
          ],
        ),
        throwsA(
          isA<PresentationCinematicValidationException>().having(
            (error) => error.code,
            'code',
            PresentationCinematicValidationErrorCode.incompatibleTrack,
          ),
        ),
      );

      expect(
        () => PresentationCinematicAsset(
          id: 'duplicates',
          title: 'Duplicates',
          durationUs: 10,
          tracks: [
            PresentationTrack(
              id: 'markers_a',
              label: 'A',
              kind: PresentationTrackKind.marker,
              clips: [
                PresentationMarkerClip(id: 'same', startUs: 1, label: 'A'),
              ],
            ),
            PresentationTrack(
              id: 'markers_b',
              label: 'B',
              kind: PresentationTrackKind.marker,
              clips: [
                PresentationMarkerClip(id: 'same', startUs: 2, label: 'B'),
              ],
            ),
          ],
        ),
        throwsA(
          isA<PresentationCinematicValidationException>().having(
            (error) => error.code,
            'code',
            PresentationCinematicValidationErrorCode.duplicateId,
          ),
        ),
      );

      expect(
        () => PresentationCinematicAsset(
          id: 'dangling',
          title: 'Dangling',
          durationUs: 10,
          tracks: [
            PresentationTrack(
              id: 'visuals',
              label: 'Visuels',
              kind: PresentationTrackKind.visual,
              clips: [
                PresentationVisualClip(
                  id: 'visual',
                  startUs: 0,
                  durationUs: 10,
                  layerId: 'missing',
                  resourceId: 'media',
                ),
              ],
            ),
          ],
        ),
        throwsA(
          isA<PresentationCinematicValidationException>().having(
            (error) => error.code,
            'code',
            PresentationCinematicValidationErrorCode.danglingLayer,
          ),
        ),
      );
    });

    test('rejects invalid bounds and non-zero marker durations', () {
      expect(
        () => PresentationCinematicAsset(
          id: 'overflow',
          title: 'Overflow',
          durationUs: 10,
          tracks: [
            PresentationTrack(
              id: 'audio',
              label: 'Audio',
              kind: PresentationTrackKind.audio,
              clips: [
                PresentationAudioClip(
                  id: 'clip',
                  startUs: 8,
                  durationUs: 3,
                  resourceId: 'music',
                ),
              ],
            ),
          ],
        ),
        throwsA(
          isA<PresentationCinematicValidationException>().having(
            (error) => error.code,
            'code',
            PresentationCinematicValidationErrorCode.outOfBounds,
          ),
        ),
      );

      final json = _minimalJson();
      json['tracks'] = [
        {
          'id': 'markers',
          'label': 'Repères',
          'kind': 'marker',
          'clips': [
            {
              'id': 'cue',
              'kind': 'marker',
              'startUs': 0,
              'durationUs': 1,
              'label': 'Cue',
              'markerKind': 'ordinary',
            },
          ],
        },
      ];

      expect(
        () => decodePresentationCinematicAsset(json),
        throwsA(
          isA<PresentationCinematicCodecException>()
              .having(
                (error) => error.code,
                'code',
                PresentationCinematicCodecErrorCode.invalidValue,
              )
              .having(
                (error) => error.path,
                'path',
                r'$.tracks[0].clips[0].durationUs',
              ),
        ),
      );
    });

    test('fails closed on unsupported schemas and capabilities', () {
      expect(
        () => decodePresentationCinematicAsset({
          ..._minimalJson(),
          'schemaVersion': 2,
        }),
        throwsA(
          isA<UnsupportedPresentationCinematicSchema>().having(
            (error) => error.schemaVersion,
            'schemaVersion',
            2,
          ),
        ),
      );

      expect(
        () => decodePresentationCinematicAsset({
          ..._minimalJson(),
          'capabilities': ['cinematic.presentation', 'presentation.branch'],
        }),
        throwsA(
          isA<PresentationCinematicCodecException>()
              .having(
                (error) => error.code,
                'code',
                PresentationCinematicCodecErrorCode.unsupportedCapability,
              )
              .having((error) => error.path, 'path', r'$.capabilities[1]'),
        ),
      );
    });

    test('preserves structural validation codes through the codec', () {
      final danglingLayer = _minimalJson()
        ..['tracks'] = [
          {
            'id': 'visuals',
            'label': 'Visuels',
            'kind': 'visual',
            'clips': [
              {
                'id': 'visual',
                'kind': 'visual',
                'startUs': 0,
                'durationUs': 1,
                'layerId': 'missing',
                'resourceId': 'media',
                'easing': 'linear',
              },
            ],
          },
        ];
      final incompatibleTrack = _minimalJson()
        ..['tracks'] = [
          {
            'id': 'visuals',
            'label': 'Visuels',
            'kind': 'visual',
            'clips': [
              {
                'id': 'audio',
                'kind': 'audio',
                'startUs': 0,
                'durationUs': 1,
                'resourceId': 'music',
              },
            ],
          },
        ];

      expect(
        () => decodePresentationCinematicAsset(danglingLayer),
        throwsA(
          isA<PresentationCinematicCodecException>()
              .having(
                (error) => error.code,
                'code',
                PresentationCinematicCodecErrorCode.danglingReference,
              )
              .having(
                (error) => error.path,
                'path',
                r'$.tracks[0].clips[0].layerId',
              ),
        ),
      );
      expect(
        () => decodePresentationCinematicAsset(incompatibleTrack),
        throwsA(
          isA<PresentationCinematicCodecException>()
              .having(
                (error) => error.code,
                'code',
                PresentationCinematicCodecErrorCode.incompatibleTrack,
              )
              .having(
                (error) => error.path,
                'path',
                r'$.tracks[0].clips[0].kind',
              ),
        ),
      );
    });

    test('keeps the world model and package boundary unchanged', () {
      final world = CinematicAsset(
        id: 'world_intro',
        title: 'World intro',
        timeline: CinematicTimeline(),
      );
      final pubspec = File('pubspec.yaml').readAsStringSync();
      final modelSource = File(
        'lib/src/models/presentation_cinematic_asset.dart',
      ).readAsStringSync();

      expect(CinematicAsset.fromJson(world.toJson()), world);
      expect(world.toJson(), isNot(contains('schemaVersion')));
      expect(pubspec, isNot(contains('flutter:')));
      expect(pubspec, isNot(contains('flame:')));
      expect(modelSource, isNot(contains("import 'dart:io'")));
      expect(modelSource, isNot(contains('package:flutter/')));
      expect(modelSource, isNot(contains('package:flame/')));
    });
  });
}

Map<String, Object?> _minimalJson() => {
  'schemaVersion': 1,
  'capabilities': ['cinematic.presentation'],
  'timebase': {'unit': 'microsecond', 'ticksPerSecond': 1000000},
  'id': 'presentation_minimal',
  'title': 'Minimal',
  'durationUs': 1,
  'layers': <Object?>[],
  'tracks': <Object?>[],
};
