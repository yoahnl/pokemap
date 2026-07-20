import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  test('commands and checkpoints round-trip without Flutter or Flame', () {
    final command = CinematicMediaPlaybackCommand.play(
      commandId: 'play_wave',
      assetId: 'sfx_wave',
      channel: 'ambience',
      volume: 0.6,
      loop: true,
    );
    final checkpoint = CinematicMediaPlaybackCheckpoint(
      activeChannels: const {'music': 'music_port'},
      activeFxIds: const {'fx_fog'},
      channelVolumes: const {'music': 0.6},
      loopingChannels: const {'music'},
    );

    expect(
      CinematicMediaPlaybackCommand.fromJson(command.toJson()),
      command,
    );
    expect(
      CinematicMediaPlaybackCheckpoint.fromJson(checkpoint.toJson()),
      checkpoint,
    );
    expect(command.kind, CinematicMediaPlaybackCommandKind.play);
  });

  test('FX and channel lifecycle commands keep their typed payload', () {
    final commands = [
      CinematicMediaPlaybackCommand.spawnFx(
        commandId: 'fx',
        assetId: 'fx_fog',
        channel: 'atmosphere',
        durationMs: 800,
        intensity: 0.7,
      ),
      CinematicMediaPlaybackCommand.fadeChannel(
        commandId: 'fade',
        channel: 'music',
        volume: 0,
        durationMs: 500,
      ),
      CinematicMediaPlaybackCommand.stopChannel(
        commandId: 'stop',
        channel: 'music',
      ),
      CinematicMediaPlaybackCommand.cancelFx(
        commandId: 'cancel',
        assetId: 'fx_fog',
      ),
      CinematicMediaPlaybackCommand.restore(commandId: 'restore'),
    ];

    expect(
      commands
          .map((command) =>
              CinematicMediaPlaybackCommand.fromJson(command.toJson()))
          .toList(),
      commands,
    );
    expect(commands.first.intensity, 0.7);
  });

  test('marker is editorial and never a playback command kind', () {
    expect(
      CinematicMediaPlaybackCommandKind.values.map((kind) => kind.name),
      isNot(contains('marker')),
    );
  });
}
