import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/map_runtime.dart';

/// L'application runtime des outcomes de cue — BETA-CIN-070.
///
/// Le premier cas caractérise l'ancien `continue` (la timeline reprend et se
/// termine), puis chaque nouvel outcome est prouvé sur le contrôleur réel :
/// stop termine proprement, cancelled skippe, failed préserve son code, une
/// destination absente échoue avec un code stable SANS déplacer le playhead,
/// une destination valide échoue fermé tant que le routage (BETA-CIN-072)
/// n'existe pas, et une réponse périmée après un skip ne produit jamais une
/// seconde reprise.
void main() {
  PresentationCinematicAsset asset() => PresentationCinematicAsset(
        id: 'opening',
        title: 'Opening',
        durationUs: 1000000,
        tracks: [
          PresentationTrack(
            id: 'markers',
            label: 'Repères',
            kind: PresentationTrackKind.marker,
            clips: [
              PresentationMarkerClip(
                id: 'chapter_two',
                startUs: 200000,
                label: 'Chapitre deux',
              ),
              PresentationMarkerClip(
                id: 'ask_name',
                startUs: 500000,
                label: 'Demander le nom',
                markerKind: PresentationMarkerKind.interactionCue,
              ),
            ],
          ),
        ],
      );

  ({
    Future<RuntimePresentationExecutionTerminal> terminal,
    List<int> frameTimesUs,
    RuntimePresentationScenePlaybackController player,
  }) launch({
    required ScenePresentationInteractionCueHandler onInteractionCue,
    List<int> deltasUs = const <int>[600000, 400000],
  }) {
    final frameTimesUs = <int>[];
    final execution = RuntimePresentationExecutionController(
      mediaController: RuntimePresentationMediaPlaybackController(
        catalog: ProjectMediaCatalog(),
        targetPlatform: PresentationMediaTargetPlatform.macos,
        resolveUri: (_) => Uri(),
        videoDriver: _UnusedVideoDriver(),
      ),
    );
    final player = RuntimePresentationScenePlaybackController(
      executionController: execution,
      onFrame: (_, frame) {
        if (frame != null) frameTimesUs.add(frame.timeUs);
      },
      frameDeltas: (_) => Stream<int>.fromIterable(deltasUs),
    );
    final terminal = player.playPresentationCinematic(
      ScenePresentationCinematicRuntimeRequest(
        requestId: 'runtime:opening:cue',
        createdAtEpochMs: 1,
        projectRevision:
            'sha256:aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa',
        contentHash:
            'sha256:bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb',
        presentationCinematicId: 'opening',
        interactionCueMarkerIds: const <String>{'ask_name'},
        onInteractionCue: onInteractionCue,
        asset: asset(),
      ),
    );
    return (
      terminal: terminal,
      frameTimesUs: frameTimesUs,
      player: player,
    );
  }

  test('characterizes the legacy continue: the timeline resumes and ends',
      () async {
    final cues = <String>[];
    final run = launch(
      onInteractionCue: (cue) async {
        cues.add(cue.markerId);
        return const PresentationInteractionOutcome.continueTimeline();
      },
    );
    addTearDown(run.player.dispose);

    expect(
      (await run.terminal).result,
      RuntimePresentationExecutionResult.completed,
    );
    expect(cues, ['ask_name']);
    expect(run.frameTimesUs, [0, 600000, 1000000]);
  });

  test('stop ends the run as a successful early completion', () async {
    final run = launch(
      onInteractionCue: (_) async =>
          const PresentationInteractionOutcome.stop(),
    );
    addTearDown(run.player.dispose);

    expect(
      (await run.terminal).result,
      RuntimePresentationExecutionResult.completed,
    );
    expect(
      run.frameTimesUs,
      [0, 600000],
      reason: 'nothing may play after a stop — the world takes over',
    );
  });

  test('cancelled ends the run as skipped', () async {
    final run = launch(
      onInteractionCue: (_) async =>
          const PresentationInteractionOutcome.cancelled(),
    );
    addTearDown(run.player.dispose);

    expect(
      (await run.terminal).result,
      RuntimePresentationExecutionResult.skipped,
    );
    expect(run.frameTimesUs, [0, 600000]);
  });

  test('failed ends the run and preserves the authored diagnostic code',
      () async {
    final run = launch(
      onInteractionCue: (_) async =>
          const PresentationInteractionOutcome.failed(
        diagnosticCode: 'scene.custom_failure',
      ),
    );
    addTearDown(run.player.dispose);

    final terminal = await run.terminal;
    expect(terminal.result, RuntimePresentationExecutionResult.failed);
    expect(terminal.diagnosticCode, 'scene.custom_failure');
  });

  test('an absent seek destination fails with the stable code and never '
      'moves the playhead', () async {
    final run = launch(
      onInteractionCue: (_) async =>
          PresentationInteractionOutcome.seekMarker(markerId: 'ghost'),
    );
    addTearDown(run.player.dispose);

    final terminal = await run.terminal;
    expect(terminal.result, RuntimePresentationExecutionResult.failed);
    expect(
      terminal.diagnosticCode,
      PresentationCueOutcomeCodes.unknownSeekDestination,
    );
    expect(
      run.frameTimesUs,
      [0, 600000],
      reason: 'the playhead must stay exactly where the cue suspended it',
    );
  });

  test('a resolved destination fails closed until BETA-CIN-072 routes it',
      () async {
    for (final outcome in [
      PresentationInteractionOutcome.seekMarker(markerId: 'chapter_two'),
      PresentationInteractionOutcome.repeatFromMarker(markerId: 'chapter_two'),
    ]) {
      final run = launch(onInteractionCue: (_) async => outcome);
      final terminal = await run.terminal;
      expect(terminal.result, RuntimePresentationExecutionResult.failed);
      expect(
        terminal.diagnosticCode,
        PresentationCueOutcomeCodes.seekRoutingUnavailable,
      );
      expect(
        run.frameTimesUs,
        [0, 600000],
        reason: 'half a seek would be worse than none: the playhead never '
            'jumps to 200000 before the real routing exists',
      );
      await run.player.dispose();
    }
  });

  test('a stale response after a skip never produces a second resumption',
      () async {
    final cueReached = Completer<void>();
    final releaseCue = Completer<void>();
    final run = launch(
      onInteractionCue: (_) async {
        cueReached.complete();
        await releaseCue.future;
        return const PresentationInteractionOutcome.stop();
      },
    );
    addTearDown(run.player.dispose);

    await cueReached.future;
    final skipped = await run.player.skipActive();
    expect(skipped?.result, RuntimePresentationExecutionResult.skipped);

    releaseCue.complete();
    final terminal = await run.terminal;
    expect(
      terminal.result,
      RuntimePresentationExecutionResult.skipped,
      reason: 'the late stop belongs to a dead execution: applying it would '
          'rewrite a skip into a completion — it must be ignored',
    );
    await Future<void>.delayed(Duration.zero);
    expect(
      run.frameTimesUs,
      [0, 600000],
      reason: 'no frame may be published by the stale response',
    );
  });

  test('the looping music survives the hold and dies with the run', () async {
    final audioDriver = _RecordingCueAudioDriver();
    final audioController = RuntimePresentationAudioController(
      catalog: ProjectMediaCatalog(
        entries: [
          ProjectMediaAsset(
            id: 'media_theme',
            label: 'Theme',
            kind: ProjectMediaKind.audio,
            sourceAssetId: 'asset_theme',
          ),
        ],
      ),
      resolveUri: (media) => Uri.file('/media/theme.ogg'),
      driver: audioDriver,
      mixer: RuntimeAudioMixer(),
    );
    final execution = RuntimePresentationExecutionController(
      mediaController: RuntimePresentationMediaPlaybackController(
        catalog: ProjectMediaCatalog(),
        targetPlatform: PresentationMediaTargetPlatform.macos,
        resolveUri: (_) => Uri(),
        videoDriver: _UnusedVideoDriver(),
      ),
    );
    final cueReached = Completer<void>();
    final releaseCue = Completer<void>();
    final player = RuntimePresentationScenePlaybackController(
      executionController: execution,
      audioController: audioController,
      onFrame: (_, __) {},
      frameDeltas: (_) => Stream<int>.fromIterable(const [600000, 400000]),
    );
    addTearDown(player.dispose);

    final musicalAsset = PresentationCinematicAsset(
      id: 'opening',
      title: 'Opening',
      durationUs: 1000000,
      tracks: [
        PresentationTrack(
          id: 'audio',
          label: 'Audio',
          kind: PresentationTrackKind.audio,
          clips: [
            PresentationAudioClip(
              id: 'theme',
              startUs: 0,
              durationUs: 1000000,
              resourceId: 'media_theme',
              audioKind: PresentationAudioKind.music,
              loop: true,
            ),
          ],
        ),
        PresentationTrack(
          id: 'markers',
          label: 'Repères',
          kind: PresentationTrackKind.marker,
          clips: [
            PresentationMarkerClip(
              id: 'ask_name',
              startUs: 500000,
              label: 'Demander le nom',
              markerKind: PresentationMarkerKind.interactionCue,
            ),
          ],
        ),
      ],
    );
    final terminal = player.playPresentationCinematic(
      ScenePresentationCinematicRuntimeRequest(
        requestId: 'runtime:opening:audio',
        createdAtEpochMs: 1,
        projectRevision:
            'sha256:aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa',
        contentHash:
            'sha256:bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb',
        presentationCinematicId: 'opening',
        interactionCueMarkerIds: const <String>{'ask_name'},
        onInteractionCue: (_) async {
          cueReached.complete();
          await releaseCue.future;
          return const PresentationInteractionOutcome.continueTimeline();
        },
        asset: musicalAsset,
      ),
    );

    await cueReached.future;
    final handle = audioDriver.handles.single;
    expect(handle.loop, isTrue);
    expect(
      handle.paused,
      isTrue,
      reason: 'the interaction hold suspends the music position-preserving',
    );
    expect(audioDriver.playCalls, 1);

    releaseCue.complete();
    expect(
      (await terminal).result,
      RuntimePresentationExecutionResult.completed,
    );
    expect(
      audioDriver.playCalls,
      1,
      reason: 'resuming after the hold must never restart the loop audibly',
    );
    expect(
      handle.stopped,
      isTrue,
      reason: 'after the run ends, zero audio handle stays active',
    );
    expect(audioController.activeChannelCount, 0);
  });

  test('an early exit releases the audio the last frame never stopped',
      () async {
    final audioDriver = _RecordingCueAudioDriver();
    final audioController = RuntimePresentationAudioController(
      catalog: ProjectMediaCatalog(
        entries: [
          ProjectMediaAsset(
            id: 'media_theme',
            label: 'Theme',
            kind: ProjectMediaKind.audio,
            sourceAssetId: 'asset_theme',
          ),
        ],
      ),
      resolveUri: (media) => Uri.file('/media/theme.ogg'),
      driver: audioDriver,
      mixer: RuntimeAudioMixer(),
    );
    final execution = RuntimePresentationExecutionController(
      mediaController: RuntimePresentationMediaPlaybackController(
        catalog: ProjectMediaCatalog(),
        targetPlatform: PresentationMediaTargetPlatform.macos,
        resolveUri: (_) => Uri(),
        videoDriver: _UnusedVideoDriver(),
      ),
    );
    final player = RuntimePresentationScenePlaybackController(
      executionController: execution,
      audioController: audioController,
      onFrame: (_, __) {},
      frameDeltas: (_) => Stream<int>.fromIterable(const [600000, 400000]),
    );
    addTearDown(player.dispose);

    final terminal = player.playPresentationCinematic(
      ScenePresentationCinematicRuntimeRequest(
        requestId: 'runtime:opening:early-exit',
        createdAtEpochMs: 1,
        projectRevision:
            'sha256:aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa',
        contentHash:
            'sha256:bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb',
        presentationCinematicId: 'opening',
        interactionCueMarkerIds: const <String>{'ask_name'},
        onInteractionCue: (_) async =>
            const PresentationInteractionOutcome.stop(),
        asset: PresentationCinematicAsset(
          id: 'opening',
          title: 'Opening',
          durationUs: 1000000,
          tracks: [
            PresentationTrack(
              id: 'audio',
              label: 'Audio',
              kind: PresentationTrackKind.audio,
              clips: [
                PresentationAudioClip(
                  id: 'theme',
                  startUs: 0,
                  durationUs: 1000000,
                  resourceId: 'media_theme',
                  audioKind: PresentationAudioKind.music,
                  loop: true,
                ),
              ],
            ),
            PresentationTrack(
              id: 'markers',
              label: 'Repères',
              kind: PresentationTrackKind.marker,
              clips: [
                PresentationMarkerClip(
                  id: 'ask_name',
                  startUs: 500000,
                  label: 'Demander le nom',
                  markerKind: PresentationMarkerKind.interactionCue,
                ),
              ],
            ),
          ],
        ),
      ),
    );

    expect(
      (await terminal).result,
      RuntimePresentationExecutionResult.completed,
    );
    expect(
      audioDriver.handles.single.stopped,
      isTrue,
      reason: 'the last frame never ran: only the terminal release can stop '
          'this loop — leaving it playing would be the exact handle leak',
    );
    expect(audioController.activeChannelCount, 0);
  });
}

final class _UnusedVideoDriver
    implements RuntimePresentationVideoPlaybackDriver {
  @override
  Future<Object> prepare(Uri source, {required double initialVolume}) =>
      Future<Object>.error(StateError('unused'));

  @override
  Future<void> play(Object handle) async {}

  @override
  Future<void> pause(Object handle) async {}

  @override
  Future<void> setVolume(Object handle, double volume) async {}

  @override
  Future<void> dispose(Object handle) async {}
}

final class _CueFakeAudioHandle {
  _CueFakeAudioHandle({required this.loop});

  final bool loop;
  bool paused = false;
  bool stopped = false;
}

final class _RecordingCueAudioDriver
    implements RuntimePresentationAudioDriver {
  final handles = <_CueFakeAudioHandle>[];
  var playCalls = 0;

  @override
  Future<Object> play(
    Uri source, {
    required double volume,
    required bool loop,
    required Duration position,
  }) async {
    playCalls += 1;
    final handle = _CueFakeAudioHandle(loop: loop);
    handles.add(handle);
    return handle;
  }

  @override
  Future<void> pause(Object handle) async {
    (handle as _CueFakeAudioHandle).paused = true;
  }

  @override
  Future<void> resume(Object handle) async {
    (handle as _CueFakeAudioHandle).paused = false;
  }

  @override
  Future<void> setVolume(Object handle, double volume) async {}

  @override
  Future<void> stop(Object handle) async {
    (handle as _CueFakeAudioHandle).stopped = true;
  }
}
