import 'dart:convert';

import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('Smart Tiles v4 compatibility', () {
    for (final version in <String>['v1', 'v2', 'v3']) {
      test('$version manifest keeps legacy authoring collections intact', () {
        final raw = <String, dynamic>{
          'name': 'Legacy $version',
          'version': version,
          'maps': <Object?>[],
          'tilesets': <Object?>[],
          'terrainCategories': <Object?>[],
          'pathCategories': <Object?>[],
          'terrainPresets': <Object?>[],
          'pathPresets': <Object?>[],
          'pathPatternPresets': <Object?>[],
          'surfaceCatalog': <String, Object?>{
            'atlases': <Object?>[],
            'animations': <Object?>[],
            'presets': <Object?>[],
          },
        };

        final manifest = ProjectManifest.fromJson(raw);
        final encoded = manifest.toJson();

        expect(manifest.smartTileCatalog.isEmpty, isTrue);
        expect(encoded, isNot(contains('smartTileCatalog')));
        for (final key in <String>[
          'terrainCategories',
          'pathCategories',
          'terrainPresets',
          'pathPresets',
          'pathPatternPresets',
        ]) {
          expect(encoded[key], raw[key], reason: '$version $key');
        }
        expect(encoded['surfaceCatalog'], raw['surfaceCatalog']);
      });
    }

    test('v1-v3 maps keep layers and v3 visual stack semantics', () {
      for (final version in <String>['v1', 'v2', 'v3']) {
        final raw = <String, dynamic>{
          'id': 'map-$version',
          'name': 'Map $version',
          'size': <String, dynamic>{'width': 1, 'height': 1},
          'version': version,
          'layers': <Object?>[],
          if (version == 'v3')
            'visualStack': <String, dynamic>{'semanticsVersion': 1},
        };

        final decoded = MapData.fromJson(raw);
        final encoded = decoded.toJson();

        expect(encoded['layers'], raw['layers']);
        expect(encoded['visualStack'], raw['visualStack']);
      }
    });

    test('v4 map round-trips visualStack and exposes the native layer kind',
        () {
      const map = MapData(
        id: 'v4-map',
        name: 'V4 map',
        size: GridSize(width: 1, height: 1),
        version: ProjectVersion.v4,
        visualStack: MapVisualStackConfig.canonicalV1,
      );

      final decoded = MapData.fromJson(
        jsonDecode(jsonEncode(map.toJson())) as Map<String, dynamic>,
      );

      expect(decoded, map);
      expect(
        MapLayerKind.values.map((kind) => kind.name),
        contains('smartTile'),
      );
    });
  });
}
