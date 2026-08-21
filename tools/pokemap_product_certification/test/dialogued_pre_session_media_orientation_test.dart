import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_player_ui/presentation_renderer.dart';

/// BETA-CIN-083 — a missing orientation variant falls back, and a music never
/// carries one.
///
/// The criterion reads like one rule but is enforced in three places, and all
/// three have to hold or the rule is decorative: the asset schema must refuse a
/// music with a variant, the runtime resolver must ignore orientation for music
/// even if data somehow carried one, and a visual whose variant is absent must
/// resolve to something rather than to null.
void main() {
  group('a music carries one shared source', () {
    test('the schema refuses a landscape variant', () {
      expect(
        () => PresentationAudioClip(
          id: 'music_lighthouse',
          startUs: 0,
          durationUs: 8000000,
          resourceId: 'media.lighthouse_loop',
          landscapeResourceId: 'media.lighthouse_loop_wide',
        ),
        throwsA(isA<PresentationCinematicValidationException>()),
      );
    });

    test('the schema refuses a portrait variant', () {
      expect(
        () => PresentationAudioClip(
          id: 'music_lighthouse',
          startUs: 0,
          durationUs: 8000000,
          resourceId: 'media.lighthouse_loop',
          portraitResourceId: 'media.lighthouse_loop_tall',
        ),
        throwsA(isA<PresentationCinematicValidationException>()),
      );
    });

    test('one shared source is accepted and resolves the same both ways', () {
      final music = PresentationAudioClip(
        id: 'music_lighthouse',
        startUs: 0,
        durationUs: 8000000,
        resourceId: 'media.lighthouse_loop',
      );
      expect(
        presentationAudioResourceForOrientation(
          music,
          PresentationAudioOrientation.landscape,
        ),
        'media.lighthouse_loop',
      );
      expect(
        presentationAudioResourceForOrientation(
          music,
          PresentationAudioOrientation.portrait,
        ),
        'media.lighthouse_loop',
      );
    });

    test('the renderer ignores orientation for music regardless of data', () {
      // Belt and braces: even a music entry that somehow arrived carrying
      // variants must resolve to the shared source, so a schema bypass cannot
      // produce two different musics per orientation.
      const entry = PresentationFrameMediaBinding(
        clipId: 'music_lighthouse',
        kind: PresentationFrameMediaKind.music,
        sharedResourceId: 'media.lighthouse_loop',
        landscapeResourceId: 'media.wrong_wide',
        portraitResourceId: 'media.wrong_tall',
      );
      expect(
        entry.resourceIdFor(PresentationFrameOrientation.landscape),
        'media.lighthouse_loop',
      );
      expect(
        entry.resourceIdFor(PresentationFrameOrientation.portrait),
        'media.lighthouse_loop',
      );
    });
  });

  group('a missing visual variant falls back to the available version', () {
    test('no variant at all: the shared source serves both orientations', () {
      const entry = PresentationFrameMediaBinding(
        clipId: 'backdrop',
        kind: PresentationFrameMediaKind.image,
        sharedResourceId: 'media.tower_night',
      );
      for (final orientation in PresentationFrameOrientation.values) {
        expect(
          entry.resourceIdFor(orientation),
          'media.tower_night',
          reason: 'an authored visual with no variants must still render in '
              '$orientation',
        );
      }
    });

    test('both variants: each orientation gets its own', () {
      const entry = PresentationFrameMediaBinding(
        clipId: 'backdrop',
        kind: PresentationFrameMediaKind.image,
        sharedResourceId: 'media.tower_night',
        landscapeResourceId: 'media.tower_night_wide',
        portraitResourceId: 'media.tower_night_tall',
      );
      expect(
        entry.resourceIdFor(PresentationFrameOrientation.landscape),
        'media.tower_night_wide',
      );
      expect(
        entry.resourceIdFor(PresentationFrameOrientation.portrait),
        'media.tower_night_tall',
      );
    });

    test('one variant only: the other orientation falls back, never to null',
        () {
      const landscapeOnly = PresentationFrameMediaBinding(
        clipId: 'backdrop',
        kind: PresentationFrameMediaKind.image,
        sharedResourceId: 'media.tower_night',
        landscapeResourceId: 'media.tower_night_wide',
      );
      expect(
        landscapeOnly.resourceIdFor(PresentationFrameOrientation.landscape),
        'media.tower_night_wide',
      );
      expect(
        landscapeOnly.resourceIdFor(PresentationFrameOrientation.portrait),
        'media.tower_night',
        reason: 'the missing portrait variant falls back to the shared source',
      );

      // And with no shared source either, it falls back across orientations
      // rather than rendering nothing: "the available version" is whichever
      // one exists.
      const portraitOnlyNoShared = PresentationFrameMediaBinding(
        clipId: 'backdrop',
        kind: PresentationFrameMediaKind.image,
        portraitResourceId: 'media.tower_night_tall',
      );
      expect(
        portraitOnlyNoShared.resourceIdFor(
          PresentationFrameOrientation.landscape,
        ),
        'media.tower_night_tall',
      );
    });

    test('a non-music audio may carry two variants and still fall back', () {
      final ambience = PresentationAudioClip(
        id: 'ambience_waves',
        startUs: 0,
        durationUs: 8000000,
        resourceId: 'media.waves',
        audioKind: PresentationAudioKind.soundEffect,
        bus: PresentationAudioBus.effects,
        landscapeResourceId: 'media.waves_wide',
      );
      expect(
        presentationAudioResourceForOrientation(
          ambience,
          PresentationAudioOrientation.landscape,
        ),
        'media.waves_wide',
      );
      expect(
        presentationAudioResourceForOrientation(
          ambience,
          PresentationAudioOrientation.portrait,
        ),
        'media.waves',
        reason: 'the absent portrait variant falls back to the single '
            'available version — the rule the music case forbids needing',
      );
    });
  });
}
