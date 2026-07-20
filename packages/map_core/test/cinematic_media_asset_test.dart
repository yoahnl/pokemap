import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  test('round-trips typed sound music and FX assets', () {
    final assets = [
      CinematicMediaAsset(
        id: 'sfx_wave',
        label: 'Vague',
        kind: CinematicMediaAssetKind.sound,
        relativePath: 'audio/sfx/wave.ogg',
        durationMs: 900,
        channel: 'ambience',
      ),
      CinematicMediaAsset(
        id: 'music_port',
        label: 'Port',
        kind: CinematicMediaAssetKind.music,
        relativePath: 'audio/music/port.ogg',
        loopByDefault: true,
        channel: 'music',
      ),
      CinematicMediaAsset(
        id: 'fx_fog',
        label: 'Brume',
        kind: CinematicMediaAssetKind.cinematicFx,
        relativePath: 'fx/fog.json',
        metadata: const {'density': '0.7'},
      ),
    ];

    expect(
      assets.map((asset) => CinematicMediaAsset.fromJson(asset.toJson())),
      assets,
    );
  });
}
