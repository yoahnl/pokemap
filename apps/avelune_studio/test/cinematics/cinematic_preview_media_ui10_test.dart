import 'dart:async';

import 'package:avelune_studio/features/cinematics/application/cinematic_preview_transport.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core_domain.dart';

void main() {
  for (final audio in [false, true]) {
    test(
      'camera preview advances with media configured and audio=$audio',
      () async {
        final port = _MediaPort();
        final plan = _cameraPlan(audio: audio);
        expect(plan.frameAt(0).cameraPose.geometry.isAvailable, isFalse);
        final transport = CinematicPreviewTransport()
          ..configureMedia(port)
          ..install(plan);
        addTearDown(transport.dispose);
        transport.play();
        await transport.mediaSettled;
        expect(transport.mediaError, isNull);
        expect(transport.playing, isTrue);
        transport.advance(400);
        await transport.mediaSettled;
        expect(transport.timeMs, greaterThanOrEqualTo(400));
        expect(transport.playing, isTrue);
        expect(port.commands.length, audio ? 1 : 0);
        if (audio) expect(port.commands.single.assetId, 'ambience');
        transport.pause();
        await transport.mediaSettled;
        expect(port.active, isEmpty);
      },
    );
  }

  test(
    'camera coexistence does not suppress missing media diagnostics',
    () async {
      final port = _MediaPort();
      final transport = CinematicPreviewTransport()
        ..configureMedia(port)
        ..install(_cameraPlan(audio: true, missingMedia: true));
      addTearDown(transport.dispose);
      transport.play();
      await transport.mediaSettled;
      expect(transport.playing, isFalse);
      expect(transport.mediaError, contains('unavailable media asset'));
      expect(port.commands, isEmpty);
    },
  );

  test(
    'explicit playback executes canonical audio once; seek is silent and pause restores',
    () async {
      final port = _MediaPort();
      final transport = CinematicPreviewTransport()
        ..configureMedia(port)
        ..install(_plan());
      addTearDown(transport.dispose);
      transport.play();
      await transport.mediaSettled;
      expect(port.commands.length, 1);
      expect(port.commands.single.kind, CinematicMediaPlaybackCommandKind.play);
      expect(port.commands.single.assetId, 'ambience');
      transport.advance(100);
      await transport.mediaSettled;
      expect(port.commands.length, 1);
      transport.seek(250);
      await transport.mediaSettled;
      expect(transport.playing, isFalse);
      expect(port.commands.length, 1);
      expect(port.active, isEmpty);
      transport.play();
      await transport.mediaSettled;
      expect(port.commands.length, 2);
      transport.pause();
      await transport.mediaSettled;
      expect(port.active, isEmpty);
    },
  );

  test(
    'stop during a pending media start restores the late owned channel',
    () async {
      final port = _MediaPort()..gate = Completer<void>();
      final transport = CinematicPreviewTransport()
        ..configureMedia(port)
        ..install(_plan());
      addTearDown(transport.dispose);
      transport.play();
      await port.started.future;
      transport.stop();
      port.gate!.complete();
      await transport.mediaSettled;
      expect(port.active, isEmpty);
      expect(transport.timeMs, 0);
      expect(transport.playing, isFalse);
    },
  );

  test(
    'replacement and disposal clean previous asynchronous media without late notifications',
    () async {
      final first = _MediaPort()..gate = Completer<void>();
      final second = _MediaPort();
      final transport = CinematicPreviewTransport()
        ..configureMedia(first)
        ..install(_plan());
      transport.play();
      await first.started.future;
      transport.configureMedia(second);
      transport.dispose();
      transport.play();
      expect(transport.playing, isFalse);
      first.gate!.complete();
      await transport.mediaSettled;
      expect(first.active, isEmpty);
      expect(second.active, isEmpty);
    },
  );

  test(
    'media failure pauses visual playback and exposes an honest diagnostic',
    () async {
      final port = _MediaPort()..failure = StateError('Missing sound');
      final transport = CinematicPreviewTransport()
        ..configureMedia(port)
        ..install(_plan());
      addTearDown(transport.dispose);
      transport.play();
      await transport.mediaSettled;
      expect(transport.mediaError, contains('Missing sound'));
      expect(transport.playing, isFalse);
      expect(port.active, isEmpty);
    },
  );
}

CinematicPreviewPlaybackPlan _cameraPlan({
  required bool audio,
  bool missingMedia = false,
}) {
  final media = CinematicMediaAsset(
    id: 'ambience',
    label: 'Ambiance fixture',
    kind: CinematicMediaAssetKind.music,
    relativePath: 'ambience.wav',
    durationMs: 1000,
  );
  var asset = CinematicAsset(
    id: 'camera-fixture',
    title: 'Caméra et média',
    timeline: CinematicTimeline(
      steps: [
        CinematicTimelineStep(
          id: 'camera',
          kind: CinematicTimelineStepKind.camera,
          durationMs: 300,
          metadata: {
            cinematicTimelineCameraModeMetadataKey: 'focus',
            cinematicTimelineCameraTargetKindMetadataKey: 'sceneCenter',
            cinematicTimelineCameraZoomPresetMetadataKey: 'close',
          },
        ),
        CinematicTimelineStep(
          id: 'wait',
          kind: CinematicTimelineStepKind.wait,
          durationMs: 1000,
        ),
      ],
    ),
  );
  if (audio) {
    asset = addCinematicTimelineCommandStep(
      asset,
      kind: CinematicTimelineStepKind.music,
      mediaAsset: media,
      durationMs: 1000,
      afterStepId: 'camera',
    ).cinematic;
  }
  return buildCinematicPreviewPlaybackPlan(
    cinematic: asset,
    mediaAssets: missingMedia ? [] : [media],
  );
}

CinematicPreviewPlaybackPlan _plan() {
  final media = CinematicMediaAsset(
    id: 'ambience',
    label: 'Ambiance fixture',
    kind: CinematicMediaAssetKind.music,
    relativePath: 'ambience.wav',
    durationMs: 1000,
  );
  final asset = addCinematicTimelineCommandStep(
    CinematicAsset(
      id: 'fixture',
      title: 'Fixture',
      timeline: CinematicTimeline(),
    ),
    kind: CinematicTimelineStepKind.music,
    mediaAsset: media,
    durationMs: 1000,
    loop: true,
  ).cinematic;
  return buildCinematicPreviewPlaybackPlan(
    cinematic: asset,
    mediaAssets: [media],
  );
}

class _MediaPort implements CinematicMediaPlaybackPort {
  final commands = <CinematicMediaPlaybackCommand>[];
  final active = <String>{};
  final started = Completer<void>();
  Completer<void>? gate;
  Object? failure;
  @override
  Future<CinematicMediaPlaybackCheckpoint> captureCheckpoint() async =>
      CinematicMediaPlaybackCheckpoint();
  @override
  Future<void> execute(CinematicMediaPlaybackCommand command) async {
    commands.add(command);
    if (!started.isCompleted) started.complete();
    await gate?.future;
    if (failure != null) throw failure!;
    active.add(command.assetId!);
  }

  @override
  Future<void> restore(CinematicMediaPlaybackCheckpoint checkpoint) async {
    active.clear();
  }
}
