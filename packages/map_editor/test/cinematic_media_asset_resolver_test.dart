import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/application/services/cinematic_media_asset_resolver.dart';

void main() {
  test('resolves only project-relative media paths inside the project root',
      () async {
    final resolver = CinematicMediaAssetResolver(
      projectRoot: '/project',
      fileExists: (path) async => path == '/project/audio/wave.ogg',
    );

    final result = await resolver.resolve([
      CinematicMediaAsset(
        id: 'wave',
        label: 'Wave',
        kind: CinematicMediaAssetKind.sound,
        relativePath: 'audio/wave.ogg',
      ),
      CinematicMediaAsset(
        id: 'escape',
        label: 'Escape',
        kind: CinematicMediaAssetKind.sound,
        relativePath: '../escape.ogg',
      ),
    ]);

    expect(result['wave']?.resolution, CinematicMediaPathResolution.present);
    expect(result['wave']?.absolutePath, '/project/audio/wave.ogg');
    expect(
        result['escape']?.resolution, CinematicMediaPathResolution.forbidden);
  });
}
