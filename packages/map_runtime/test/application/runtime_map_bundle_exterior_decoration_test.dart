import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/map_runtime.dart';

void main() {
  RuntimeMapBundle bundle(String id) => RuntimeMapBundle(
    manifest: ProjectManifest(
      name: 'Decoration',
      maps: const [],
      tilesets: const [],
      settings: const ProjectSettings(),
    ),
    map: MapData(
      id: id,
      name: id,
      version: ProjectVersion.v9,
      size: const GridSize(width: 8, height: 8),
      spatialScene: MapSpatialScene(width: 8, depth: 8),
    ),
    projectRootDirectory: '/project',
    tilesetAbsolutePathsById: const {},
  );

  test(
    'exterior visuals survive same-map copies and never follow another map',
    () {
      final decoration = MapExteriorDecoration(
        mapId: 'route',
        playableWidth: 8,
        playableDepth: 8,
        west: 4,
      );
      final dynamic original = bundle('route');
      final dynamic decorated = original.copyWith(
        exteriorDecoration: decoration,
      );
      expect(decorated.exteriorDecoration, same(decoration));
      expect(decorated.copyWith().exteriorDecoration, same(decoration));
      expect(
        decorated.copyWith(map: bundle('other').map).exteriorDecoration,
        isNull,
      );
      expect(decorated.map, original.map);
    },
  );

  test(
    'maps without decoration retain their original gameplay and identity',
    () {
      final dynamic original = bundle('route');
      expect(original.exteriorDecoration, isNull);
      expect(original.copyWith().map, same(original.map));
    },
  );
}
