import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('Smart Tiles-only project format v6', () {
    test('new in-memory manifests and maps default to v6', () {
      expect(
        ProjectManifest(
          name: 'New project',
          maps: const <ProjectMapEntry>[],
          tilesets: const <ProjectTilesetEntry>[],
        ).version,
        ProjectVersion.v6,
      );
      expect(
        const MapData(
          id: 'new-map',
          name: 'New map',
          size: GridSize(width: 1, height: 1),
        ).version,
        ProjectVersion.v6,
      );
    });

    test('decodes canonical v6 manifests and maps', () {
      expect(
        ProjectManifest.fromJsonPokeMapBetaV1ForTest(
          _minimalManifestJson(version: 'v6'),
        ).version,
        ProjectVersion.v6,
      );
      expect(
        MapData.fromJson(_minimalMapJson(version: 'v6')).version,
        ProjectVersion.v6,
      );
    });

    for (final version in <String>['v1', 'v2', 'v3', 'v4', 'v5']) {
      test('rejects legacy project format $version explicitly', () {
        expect(
          () => ProjectManifest.fromJsonPokeMapBetaV1ForTest(
            _minimalManifestJson(version: version),
          ),
          throwsA(
            isA<FormatException>().having(
              (error) => error.message,
              'message',
              allOf(
                contains('smart_tile_v6_project_required'),
                contains(version),
              ),
            ),
          ),
        );
      });

      test('rejects legacy map format $version explicitly', () {
        expect(
          () => MapData.fromJson(_minimalMapJson(version: version)),
          throwsA(
            isA<FormatException>().having(
              (error) => error.message,
              'message',
              allOf(contains('smart_tile_v6_map_required'), contains(version)),
            ),
          ),
        );
      });
    }

    for (final legacyKey in <String>[
      'terrainCategories',
      'pathCategories',
      'terrainPresets',
      'pathPresets',
      'pathPatternPresets',
      'surfaceCatalog',
    ]) {
      test('v6 rejects the legacy manifest key $legacyKey even when empty', () {
        final raw = _minimalManifestJson(version: 'v6')
          ..[legacyKey] = legacyKey == 'surfaceCatalog'
              ? <String, Object?>{}
              : <Object?>[];

        expect(
          () => ProjectManifest.fromJsonPokeMapBetaV1ForTest(raw),
          throwsA(
            isA<FormatException>().having(
              (error) => error.message,
              'message',
              allOf(
                contains('smart_tile_v6_legacy_manifest_field_unsupported'),
                contains(legacyKey),
              ),
            ),
          ),
        );
      });
    }

    for (final runtimeType in <String>['terrain', 'path', 'surface']) {
      test('v6 rejects the legacy $runtimeType layer before decoding', () {
        final raw = _minimalMapJson(version: 'v6')
          ..['layers'] = <Object?>[
            <String, Object?>{
              'runtimeType': runtimeType,
              'id': 'legacy',
              'name': 'Legacy',
            },
          ];

        expect(
          () => MapData.fromJson(raw),
          throwsA(
            isA<FormatException>().having(
              (error) => error.message,
              'message',
              allOf(
                contains('smart_tile_v6_legacy_layer_unsupported'),
                contains(runtimeType),
              ),
            ),
          ),
        );
      });
    }

    test('v6 rejects legacy Smart Tile lists beside a native field', () {
      final raw = _minimalMapJson(version: 'v6')
        ..['layers'] = <Object?>[
          <String, Object?>{
            'runtimeType': 'smart_tile',
            'id': 'native',
            'name': 'Native',
            'presetId': 'preset',
            'usage': 'terrain',
            'materialPalette': <String>['', 'grass'],
            'field': <String, Object?>{
              'kind': 'cell',
              'semanticCells': <int>[1],
            },
            'corners': <int>[0, 0, 0, 0],
          },
        ];

      expect(
        () => MapData.fromJson(raw),
        throwsA(
          isA<FormatException>().having(
            (error) => error.message,
            'message',
            contains('smart_tile_v6_legacy_payload_unsupported'),
          ),
        ),
      );
    });

    test('v6 requires the native Smart Tile field payload', () {
      final raw = _minimalMapJson(version: 'v6')
        ..['layers'] = <Object?>[
          <String, Object?>{
            'runtimeType': 'smart_tile',
            'id': 'native',
            'name': 'Native',
            'presetId': 'preset',
            'usage': 'terrain',
            'materialPalette': <String>['', 'grass'],
          },
        ];

      expect(
        () => MapData.fromJson(raw),
        throwsA(
          isA<FormatException>().having(
            (error) => error.message,
            'message',
            contains('smart_tile_v6_field_required'),
          ),
        ),
      );
    });

    test('the public layer kind no longer exposes legacy visual families', () {
      expect(
        MapLayerKind.values.map((kind) => kind.name),
        isNot(containsAll(<String>['terrain', 'path', 'surface'])),
      );
    });
  });
}

Map<String, dynamic> _minimalManifestJson({required String version}) {
  return <String, dynamic>{
    'name': 'Smart Tiles test project',
    'version': version,
    'maps': <Object?>[],
    'tilesets': <Object?>[],
  };
}

Map<String, dynamic> _minimalMapJson({required String version}) {
  return <String, dynamic>{
    'id': 'smart-tiles-test-map',
    'name': 'Smart Tiles test map',
    'size': <String, dynamic>{'width': 1, 'height': 1},
    'version': version,
  };
}
