import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/src/application/runtime_manifest_tilesets.dart';

import '../../map_gameplay/test/support/moving_platform_fixture.dart';

void main() {
  test(
    'all platform orientations preload their atlases including frame overrides',
    () {
      final fixture = MovingPlatformFixture();
      final project = fixture.project.copyWith(
        elements: [
          for (var index = 0; index < 4; index++)
            fixture.project.elements[index].copyWith(
              tilesetId: 'orientation-$index',
              frames: [
                TilesetVisualFrame(
                  tilesetId: index == 3 ? 'override' : '',
                  source: const TilesetSourceRect(
                    x: 0,
                    y: 0,
                    width: 1,
                    height: 2,
                  ),
                ),
              ],
            ),
        ],
      );
      for (var turns = 0; turns < 4; turns++) {
        final state = fixture.state.withPlatform(
          mapId: 'gym',
          platformId: 'bridge',
          pose: MovingPlatformPose(leftPx: 64, topPx: 64, quarterTurns: turns),
        );
        final map = applyMovingPlatformWorldStateToMap(
          map: fixture.map,
          worldState: state,
          tileSize: const PixelSize(width: 32, height: 32),
        );
        expect(
          collectAllRuntimeTilesetIds(map, project),
          containsAll([
            'orientation-0',
            'orientation-1',
            'orientation-2',
            'override',
          ]),
        );
      }
    },
  );
}
