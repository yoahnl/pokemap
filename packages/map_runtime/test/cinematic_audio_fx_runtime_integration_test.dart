import 'dart:convert';
import 'dart:io';

import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/src/application/scene_runtime/cinematic_runtime_playback_controller.dart';
import 'package:map_runtime/src/application/scene_runtime/scene_cinematic_runtime_awaitable_result.dart';
import 'package:map_runtime/src/presentation/flame/flame_cinematic_runtime_playback_sink.dart';

void main() {
  test(
      'shared Selbrume fixture has preview/runtime command parity and rollback',
      () async {
    final manifest = await _loadFixture();
    final cinematic = manifest.cinematics.single;
    final previewPlan = buildCinematicPreviewPlaybackPlan(
      cinematic: cinematic,
      dialogues: manifest.dialogues,
      mediaAssets: manifest.cinematicMediaAssets,
    );
    final host = _FixtureHost();
    final media = _RecordingMediaPort();
    final sink = FlameCinematicRuntimePlaybackSink(
      host: host,
      mediaPlaybackPort: media,
      dialogues: manifest.dialogues,
      mediaAssets: manifest.cinematicMediaAssets,
    );
    final controller = CinematicRuntimePlaybackController(sink: sink);

    final completion = controller.play(cinematic);
    await _flush();
    controller.update(const Duration(milliseconds: 1000));
    expect(host.dialogues, ['dialogue.port']);
    controller.update(const Duration(milliseconds: 500));
    await _flush();
    controller.update(const Duration(milliseconds: 300));
    await _flush();
    controller.update(const Duration(milliseconds: 300));
    await _flush();
    controller.update(const Duration(milliseconds: 800));
    final result = await completion;

    expect(result.success, isTrue);
    expect(previewPlan.executableDurationMs, 2900);
    expect(
      media.commands
          .where((command) =>
              command.kind != CinematicMediaPlaybackCommandKind.cancelFx)
          .map((command) => (command.kind, command.assetId)),
      [
        (CinematicMediaPlaybackCommandKind.play, 'sound.bell'),
        (CinematicMediaPlaybackCommandKind.play, 'music.mist'),
        (CinematicMediaPlaybackCommandKind.spawnFx, 'fx.fog'),
      ],
    );
    expect(
      previewPlan.playbackCues
          .where((cue) =>
              cue.kind == CinematicPlaybackCueKind.sound ||
              cue.kind == CinematicPlaybackCueKind.music ||
              cue.kind == CinematicPlaybackCueKind.fx)
          .map((cue) => cue.referenceId),
      ['sound.bell', 'music.mist', 'fx.fog'],
    );
    expect(
      media.commands.map((command) => command.commandId),
      isNot(contains(contains('marker'))),
    );
    expect(media.restored, [media.initialCheckpoint]);
    expect(host.inputLocked, isFalse);
  });

  test('mid-playback media failure restores input, camera and media', () async {
    final manifest = await _loadFixture();
    final host = _FixtureHost();
    final media = _RecordingMediaPort()..failingAssetId = 'music.mist';
    final sink = FlameCinematicRuntimePlaybackSink(
      host: host,
      mediaPlaybackPort: media,
      dialogues: manifest.dialogues,
      mediaAssets: manifest.cinematicMediaAssets,
    );
    final controller = CinematicRuntimePlaybackController(sink: sink);

    final completion = controller.play(manifest.cinematics.single);
    await _flush();
    controller.update(const Duration(milliseconds: 1000));
    controller.update(const Duration(milliseconds: 500));
    await _flush();
    controller.update(const Duration(milliseconds: 300));
    await _flush();
    controller.update(Duration.zero);
    final result = await completion;

    expect(result.success, isFalse);
    expect(
        result.errorCode, SceneCinematicRuntimeAwaitableErrorCode.sinkFailure);
    expect(media.restored, [media.initialCheckpoint]);
    expect(host.inputLocked, isFalse);
    expect(host.cameraPosition, Vector2(10, 10));
  });

  test('cancelling the shared fixture restores its captured media checkpoint',
      () async {
    final manifest = await _loadFixture();
    final host = _FixtureHost();
    final media = _RecordingMediaPort();
    final controller = CinematicRuntimePlaybackController(
      sink: FlameCinematicRuntimePlaybackSink(
        host: host,
        mediaPlaybackPort: media,
        dialogues: manifest.dialogues,
        mediaAssets: manifest.cinematicMediaAssets,
      ),
    );

    final completion = controller.play(manifest.cinematics.single);
    await _flush();
    expect(controller.cancel(), isTrue);
    final result = await completion;

    expect(result.errorCode, SceneCinematicRuntimeAwaitableErrorCode.cancelled);
    expect(media.restored, [media.initialCheckpoint]);
    expect(host.inputLocked, isFalse);
  });
}

Future<ProjectManifest> _loadFixture() async {
  final json = jsonDecode(
    await File(
      '../map_core/test/fixtures/cinematic_media_contract/project.json',
    ).readAsString(),
  ) as Map<String, dynamic>;
  return ProjectManifest.fromJson(json);
}

Future<void> _flush() => Future<void>.delayed(Duration.zero);

final class _RecordingMediaPort implements CinematicMediaPlaybackPort {
  final initialCheckpoint = CinematicMediaPlaybackCheckpoint(
    activeChannels: const {'music': 'music.before'},
    channelVolumes: const {'music': 0.2},
    loopingChannels: const {'music'},
  );
  final commands = <CinematicMediaPlaybackCommand>[];
  final restored = <CinematicMediaPlaybackCheckpoint>[];
  String? failingAssetId;

  @override
  Future<CinematicMediaPlaybackCheckpoint> captureCheckpoint() async =>
      initialCheckpoint;

  @override
  Future<void> execute(CinematicMediaPlaybackCommand command) async {
    commands.add(command);
    if (command.assetId == failingAssetId) {
      throw StateError('Injected media failure.');
    }
  }

  @override
  Future<void> restore(CinematicMediaPlaybackCheckpoint checkpoint) async {
    restored.add(checkpoint);
  }
}

final class _FixtureHost implements FlameCinematicRuntimeHost {
  bool inputLocked = false;
  final dialogues = <String>[];

  @override
  bool get isReady => true;

  @override
  String get activeMapId => 'map.port';

  @override
  Vector2 cameraPosition = Vector2(10, 10);

  @override
  Vector2? cameraVisibleGameSize = Vector2(100, 80);

  @override
  Vector2 get sceneCenter => Vector2(50, 40);

  @override
  FlameCinematicRuntimeActorHandle? get playerActor => null;

  @override
  FlameCinematicRuntimeActorHandle? mapEntityActor(String entityId) => null;

  @override
  Vector2? mapEntityFocusPoint(String entityId) => null;

  @override
  Vector2 stagePointFocusPoint(CinematicStagePoint point) =>
      Vector2(point.x, point.y);

  @override
  void setCinematicInputLocked(bool locked) => inputLocked = locked;

  @override
  void showCinematicDialogueLine(String? text) {}

  @override
  Future<void> playCinematicDialogueAsset(String dialogueId) async {
    dialogues.add(dialogueId);
  }

  @override
  void cancelCinematicDialogueAsset() {}

  @override
  void setCinematicFadeOpacity(double? opacity) {}

  @override
  void showCinematicActorEmote(
    FlameCinematicRuntimeActorHandle? actor,
    String? emoteId,
  ) {}
}
