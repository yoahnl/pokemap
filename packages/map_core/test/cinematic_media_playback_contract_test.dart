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

  test('marker is editorial and never a playback command kind', () {
    expect(
      CinematicMediaPlaybackCommandKind.values.map((kind) => kind.name),
      isNot(contains('marker')),
    );
  });
}
