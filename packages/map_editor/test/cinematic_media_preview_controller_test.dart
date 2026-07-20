import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/ui/canvas/cinematics/preview/cinematic_media_preview_controller.dart';

void main() {
  test('preview executes media cues, never marker, and restores on cancel',
      () async {
    final fixture = await _loadFixture();
    final port = _RecordingMediaPort();
    final clock = MutableCinematicPreviewClock();
    final controller = CinematicMediaPreviewController(
      port: port,
      clock: clock,
    );

    await controller.prepare(fixture.plan);
    final state = await controller.advanceTo(2899);

    expect(clock.nowMs, 2899);
    expect(state.fx?.referenceId, 'fx.fog');
    expect(
      port.commands.map((command) => command.kind),
      [
        CinematicMediaPlaybackCommandKind.play,
        CinematicMediaPlaybackCommandKind.play,
        CinematicMediaPlaybackCommandKind.spawnFx,
      ],
    );
    expect(
      port.commands.map((command) => command.commandId),
      isNot(contains(contains('marker'))),
    );

    await controller.cancel();
    expect(port.restored, [port.initialCheckpoint]);
    expect(controller.isPrepared, isFalse);
  });

  test('seek deterministically rebuilds looping music and active FX', () async {
    final fixture = await _loadFixture();
    final port = _RecordingMediaPort();
    final controller = CinematicMediaPreviewController(port: port);

    await controller.prepare(fixture.plan);
    await controller.advanceTo(2899);
    port.commands.clear();

    final state = await controller.seek(2200);

    expect(port.restored.last, port.initialCheckpoint);
    expect(
      port.commands.map((command) => command.assetId),
      ['music.mist', 'fx.fog'],
    );
    expect(state.fx?.referenceId, 'fx.fog');
  });

  test('failure rolls back and invalidates the prepared session', () async {
    final fixture = await _loadFixture();
    final port = _RecordingMediaPort()..failingAssetId = 'music.mist';
    final controller = CinematicMediaPreviewController(port: port);

    await controller.prepare(fixture.plan);

    await expectLater(
      controller.advanceTo(2200),
      throwsA(isA<CinematicMediaPreviewException>()),
    );
    expect(port.restored.last, port.initialCheckpoint);
    expect(controller.isPrepared, isFalse);
    expect(controller.state.timeMs, 0);
  });
}

Future<({CinematicPreviewPlaybackPlan plan})> _loadFixture() async {
  final json = jsonDecode(
    await File(
      '../map_core/test/fixtures/cinematic_media_contract/project.json',
    ).readAsString(),
  ) as Map<String, dynamic>;
  final manifest = ProjectManifest.fromJson(json);
  return (
    plan: buildCinematicPreviewPlaybackPlan(
      cinematic: manifest.cinematics.single,
      dialogues: manifest.dialogues,
      mediaAssets: manifest.cinematicMediaAssets,
    ),
  );
}

final class _RecordingMediaPort implements CinematicMediaPlaybackPort {
  final initialCheckpoint = CinematicMediaPlaybackCheckpoint(
    activeChannels: const {'music': 'music.before'},
    channelVolumes: const {'music': 0.25},
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
