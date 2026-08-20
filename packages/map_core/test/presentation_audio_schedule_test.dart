import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

/// Le plan audio déterministe d'un frame Presentation — BETA-CIN-076.
///
/// Les frames viennent du VRAI évaluateur : chaque entrée audio produit une
/// commande déterministe (start à la position exacte, volume piloté par les
/// fades authorés, stop de ce qui quitte le frame, stop total au terminal)
/// ou une issue fail-closed. Musique unique inter-orientations, variantes
/// pour les autres kinds, et les effets ponctuels ne bouclent jamais par
/// défaut.
void main() {
  const evaluator = PresentationCinematicEvaluator();

  PresentationCinematicAsset asset() => PresentationCinematicAsset(
        id: 'opening',
        title: 'Opening',
        durationUs: 3000000,
        tracks: [
          PresentationTrack(
            id: 'audio',
            label: 'Audio',
            kind: PresentationTrackKind.audio,
            clips: [
              PresentationAudioClip(
                id: 'theme',
                startUs: 0,
                durationUs: 3000000,
                resourceId: 'media_theme',
                audioKind: PresentationAudioKind.music,
                volume: 0.8,
                loop: true,
                fadeInUs: 200000,
                fadeOutUs: 200000,
                bus: PresentationAudioBus.music,
              ),
              PresentationAudioClip(
                id: 'whoosh',
                startUs: 1000000,
                durationUs: 500000,
                resourceId: 'media_whoosh',
                audioKind: PresentationAudioKind.soundEffect,
                landscapeResourceId: 'media_whoosh_wide',
                portraitResourceId: 'media_whoosh_tall',
                bus: PresentationAudioBus.effects,
              ),
            ],
          ),
        ],
      );

  PresentationFrame frameAt(int timeUs) =>
      evaluator.evaluate(asset(), timeUs: timeUs);

  PresentationAudioChannelSnapshot playingTheme({double volume = 0.8}) =>
      PresentationAudioChannelSnapshot(
        clipId: 'theme',
        resourceId: 'media_theme',
        loop: true,
        volume: volume,
      );

  group('BETA-CIN-076 starts are exact and deterministic', () {
    test('a fresh frame starts the music at position zero, looping, faded in',
        () {
      final plan = planPresentationAudioCommands(
        asset: asset(),
        frame: frameAt(0),
        activeChannels: const [],
      );
      expect(plan.issues, isEmpty);
      expect(plan.commands, [
        const PresentationAudioStartCommand(
          clipId: 'theme',
          resourceId: 'media_theme',
          positionUs: 0,
          loop: true,
          volume: 0,
          audioKind: PresentationAudioKind.music,
          bus: PresentationAudioBus.music,
        ),
      ]);
    });

    test('entering mid-clip starts at the evaluated position', () {
      final plan = planPresentationAudioCommands(
        asset: asset(),
        frame: frameAt(1200000),
        activeChannels: const [],
      );
      final starts =
          plan.commands.whereType<PresentationAudioStartCommand>().toList();
      expect(starts, hasLength(2));
      expect(
        starts.singleWhere((command) => command.clipId == 'theme').positionUs,
        1200000,
      );
      final whoosh =
          starts.singleWhere((command) => command.clipId == 'whoosh');
      expect(whoosh.positionUs, 200000);
      expect(
        whoosh.loop,
        isFalse,
        reason: 'sound effects never loop unless explicitly authored to',
      );
    });

    test('the same inputs always produce the same command list', () {
      final first = planPresentationAudioCommands(
        asset: asset(),
        frame: frameAt(1200000),
        activeChannels: [playingTheme()],
      );
      final second = planPresentationAudioCommands(
        asset: asset(),
        frame: frameAt(1200000),
        activeChannels: [playingTheme()],
      );
      expect(first.commands, second.commands);
    });
  });

  group('BETA-CIN-076 fades drive deterministic volume updates', () {
    test('mid-fade-in the volume is the exact linear ramp', () {
      final plan = planPresentationAudioCommands(
        asset: asset(),
        frame: frameAt(100000),
        activeChannels: [playingTheme(volume: 0)],
      );
      expect(plan.commands, [
        const PresentationAudioSetVolumeCommand(clipId: 'theme', volume: 0.4),
      ]);
    });

    test('after the fade the authored volume holds and the plan is quiet',
        () {
      final plan = planPresentationAudioCommands(
        asset: asset(),
        frame: frameAt(500000),
        activeChannels: [playingTheme()],
      );
      expect(
        plan.commands,
        isEmpty,
        reason: 'an unchanged steady state must not command anything — a '
            'restart or volume churn per page would be audible',
      );
    });

    test('inside the fade-out window the volume ramps back down', () {
      final plan = planPresentationAudioCommands(
        asset: asset(),
        frame: frameAt(2900000),
        activeChannels: [playingTheme()],
      );
      expect(plan.commands, [
        PresentationAudioSetVolumeCommand(
          clipId: 'theme',
          volume: 0.8 * (100000 / 200000),
        ),
      ]);
    });
  });

  group('BETA-CIN-076 stops and terminal', () {
    test('a clip that left the frame stops, the rest keeps playing', () {
      final plan = planPresentationAudioCommands(
        asset: asset(),
        frame: frameAt(2000000),
        activeChannels: [
          playingTheme(),
          const PresentationAudioChannelSnapshot(
            clipId: 'whoosh',
            resourceId: 'media_whoosh_wide',
            loop: false,
            volume: 1,
          ),
        ],
      );
      expect(plan.commands, [
        const PresentationAudioStopCommand(clipId: 'whoosh'),
      ]);
    });

    test('a terminal frame stops every channel', () {
      final plan = planPresentationAudioCommands(
        asset: asset(),
        frame: null,
        activeChannels: [
          playingTheme(),
          const PresentationAudioChannelSnapshot(
            clipId: 'whoosh',
            resourceId: 'media_whoosh_wide',
            loop: false,
            volume: 1,
          ),
        ],
      );
      expect(plan.commands, const [
        PresentationAudioStopCommand(clipId: 'theme'),
        PresentationAudioStopCommand(clipId: 'whoosh'),
      ]);
    });
  });

  group('BETA-CIN-076 orientations and fail-closed issues', () {
    test('music shares one source while effects pick their variant', () {
      final portrait = planPresentationAudioCommands(
        asset: asset(),
        frame: frameAt(1200000),
        activeChannels: const [],
        orientation: PresentationAudioOrientation.portrait,
      );
      final starts = portrait.commands
          .whereType<PresentationAudioStartCommand>()
          .toList();
      expect(
        starts.singleWhere((command) => command.clipId == 'theme').resourceId,
        'media_theme',
        reason: 'music must use one shared source across 16:9 and 9:16',
      );
      expect(
        starts.singleWhere((command) => command.clipId == 'whoosh').resourceId,
        'media_whoosh_tall',
      );
    });

    test('an orientation flip restarts the variant at the same position', () {
      final plan = planPresentationAudioCommands(
        asset: asset(),
        frame: frameAt(1200000),
        activeChannels: [
          playingTheme(),
          const PresentationAudioChannelSnapshot(
            clipId: 'whoosh',
            resourceId: 'media_whoosh_wide',
            loop: false,
            volume: 1,
          ),
        ],
        orientation: PresentationAudioOrientation.portrait,
      );
      expect(plan.commands, const [
        PresentationAudioStopCommand(clipId: 'whoosh'),
        PresentationAudioStartCommand(
          clipId: 'whoosh',
          resourceId: 'media_whoosh_tall',
          positionUs: 200000,
          loop: false,
          volume: 1,
          audioKind: PresentationAudioKind.soundEffect,
          bus: PresentationAudioBus.effects,
        ),
      ]);
    });

    test('a one-shot consumed before the destination never replays', () {
      // Seek back to 2s: the whoosh (1.0s-1.5s) sits OUTSIDE the replayed
      // window and must stay silent — only clips alive in the evaluated
      // frame may start.
      final plan = planPresentationAudioCommands(
        asset: asset(),
        frame: frameAt(2000000),
        activeChannels: [playingTheme()],
      );
      expect(
        plan.commands.whereType<PresentationAudioStartCommand>(),
        isEmpty,
        reason: 'seek/repeat replays only what the destination frame '
            'contains: already-consumed one-shots stay consumed',
      );
    });

    test('a frame entry unknown to the asset is a fail-closed issue', () {
      final plan = planPresentationAudioCommands(
        asset: asset(),
        frame: PresentationFrame(
          cinematicId: 'opening',
          timeUs: 0,
          durationUs: 3000000,
          audio: const [
            PresentationAudioFrameClip(
              clipId: 'ghost',
              trackId: 'audio',
              resourceId: 'media_ghost',
              startUs: 0,
              durationUs: 1000,
              elapsedUs: 0,
              progress: 0,
            ),
          ],
        ),
        activeChannels: const [],
      );
      expect(plan.issues, const [
        PresentationAudioPlanIssue(
          clipId: 'ghost',
          code: PresentationAudioPlanIssueCode.unknownAudioClip,
        ),
      ]);
      expect(
        plan.commands.whereType<PresentationAudioStartCommand>(),
        isEmpty,
        reason: 'nothing undefined may start playing',
      );
    });
  });
}
