import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/smart_tiles_studio/application/smart_tile_studio_launch_context.dart';

void main() {
  test('library and captured map contexts have stable value equality', () {
    expect(
      const SmartTilesStudioLaunchContext.library(),
      const SmartTilesStudioLaunchContext.library(),
    );
    expect(
      const SmartTilesStudioLaunchContext.map(mapId: 'map-a'),
      const SmartTilesStudioLaunchContext.map(mapId: 'map-a'),
    );
    expect(
      const SmartTilesStudioLaunchContext.map(mapId: 'map-a'),
      isNot(const SmartTilesStudioLaunchContext.map(mapId: 'map-b')),
    );
  });

  test('availability requires the same map to remain active', () {
    const context = SmartTilesStudioLaunchContext.map(mapId: 'map-a');
    expect(context.isCapturedMapAvailable(_map('map-a')), isTrue);
    expect(context.isCapturedMapAvailable(_map('map-b')), isFalse);
    expect(context.isCapturedMapAvailable(null), isFalse);
  });
}

MapData _map(String id) => MapData(
      id: id,
      name: id,
      size: const GridSize(width: 1, height: 1),
    );
