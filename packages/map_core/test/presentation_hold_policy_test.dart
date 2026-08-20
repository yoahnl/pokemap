import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

/// La politique de hold authorée par piste — BETA-CIN-077.
///
/// Frozen par défaut partout ; ambientContinues uniquement quand l'auteur le
/// dit. Le codec n'écrit la politique que hors défaut et relit frozen quand
/// elle est absente ; le plan audio dérive la politique de la piste
/// porteuse de chaque clip.
void main() {
  PresentationCinematicAsset asset({
    PresentationHoldTrackPolicy musicPolicy =
        PresentationHoldTrackPolicy.ambientContinues,
  }) =>
      PresentationCinematicAsset(
        id: 'opening',
        title: 'Opening',
        durationUs: 2000000,
        tracks: [
          PresentationTrack(
            id: 'music',
            label: 'Musique',
            kind: PresentationTrackKind.audio,
            holdPolicy: musicPolicy,
            clips: [
              PresentationAudioClip(
                id: 'theme',
                startUs: 0,
                durationUs: 2000000,
                resourceId: 'media_theme',
                audioKind: PresentationAudioKind.music,
                loop: true,
              ),
            ],
          ),
          PresentationTrack(
            id: 'sfx',
            label: 'Effets',
            kind: PresentationTrackKind.audio,
            clips: [
              PresentationAudioClip(
                id: 'whoosh',
                startUs: 0,
                durationUs: 500000,
                resourceId: 'media_whoosh',
                audioKind: PresentationAudioKind.soundEffect,
                bus: PresentationAudioBus.effects,
              ),
            ],
          ),
        ],
      );

  test('the policy defaults to frozen and round-trips when authored', () {
    expect(
      PresentationTrack(
        id: 't',
        label: 'T',
        kind: PresentationTrackKind.audio,
      ).holdPolicy,
      PresentationHoldTrackPolicy.frozen,
    );

    final encoded = encodePresentationCinematicAsset(asset());
    final reloaded = decodePresentationCinematicAsset(encoded);
    expect(
      reloaded.tracks.singleWhere((track) => track.id == 'music').holdPolicy,
      PresentationHoldTrackPolicy.ambientContinues,
    );
    expect(
      reloaded.tracks.singleWhere((track) => track.id == 'sfx').holdPolicy,
      PresentationHoldTrackPolicy.frozen,
    );
  });

  test('frozen is never written — the default stays implicit on the wire',
      () {
    final encoded = encodePresentationCinematicAsset(
      asset(musicPolicy: PresentationHoldTrackPolicy.frozen),
    );
    expect(
      encoded.toString(),
      isNot(contains('holdPolicy')),
      reason: 'only authored ambience appears in the document',
    );
  });

  test('the audio plan derives each start command from its owning track',
      () {
    const evaluator = PresentationCinematicEvaluator();
    final plan = planPresentationAudioCommands(
      asset: asset(),
      frame: evaluator.evaluate(asset(), timeUs: 100000),
      activeChannels: const [],
    );
    final starts =
        plan.commands.whereType<PresentationAudioStartCommand>().toList();
    expect(
      starts.singleWhere((command) => command.clipId == 'theme').holdPolicy,
      PresentationHoldTrackPolicy.ambientContinues,
    );
    expect(
      starts.singleWhere((command) => command.clipId == 'whoosh').holdPolicy,
      PresentationHoldTrackPolicy.frozen,
    );
  });
}
