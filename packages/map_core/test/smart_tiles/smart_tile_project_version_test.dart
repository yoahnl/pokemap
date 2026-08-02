import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('Smart Tiles project format v5', () {
    test('decodes v5 manifests and maps', () {
      expect(
        ProjectManifest.fromJson(_minimalManifestJson(version: 'v5')).version,
        ProjectVersion.v5,
      );
      expect(
        MapData.fromJson(_minimalMapJson(version: 'v5')).version,
        ProjectVersion.v5,
      );
    });

    test('v5 preserves the canonical visual stack contract', () {
      final json = _minimalMapJson(version: 'v5')
        ..['visualStack'] = MapVisualStackConfig.canonicalV1.toJson();

      expect(MapData.fromJson(json).visualStack, isNotNull);
    });

    test('v2 still rejects visualStack', () {
      final json = _minimalMapJson(version: 'v2')
        ..['visualStack'] = MapVisualStackConfig.canonicalV1.toJson();

      expect(() => MapData.fromJson(json), throwsFormatException);
    });

    test('migration guards accept v5 and reject unknown future versions', () {
      final manifest = _minimalManifestJson(version: 'v5');
      expect(
        identical(migrateProjectManifestJson(manifest), manifest),
        isTrue,
      );
      expect(
        () => migrateProjectManifestJson(
          _minimalManifestJson(version: 'v6'),
        ),
        throwsFormatException,
      );
    });

    test('non-empty native catalog requires v5 but canonical empty v2 does not',
        () {
      final emptyV4 = _minimalManifestJson(version: 'v4')
        ..['smartTileCatalog'] = <String, Object?>{
          'formatVersion': 2,
          'categories': <Object?>[],
          'atlases': <Object?>[],
          'materials': <Object?>[],
          'animations': <Object?>[],
          'presets': <Object?>[],
        };
      expect(ProjectManifest.fromJson(emptyV4).version, ProjectVersion.v4);

      final nonEmptyV4 = _minimalManifestJson(version: 'v4')
        ..['smartTileCatalog'] = <String, Object?>{
          'formatVersion': 2,
          'materials': <Object?>[
            <String, Object?>{
              'id': 'grass',
              'name': 'Grass',
              'connectionGroupId': 'ground',
            },
          ],
        };
      expect(
        () => ProjectManifest.fromJson(nonEmptyV4),
        throwsA(
          isA<FormatException>().having(
            (error) => error.message,
            'message',
            contains('ProjectVersion.v5'),
          ),
        ),
      );
    });

    for (final legacyKey in <String>[
      'terrainCategories',
      'pathCategories',
      'terrainPresets',
      'pathPresets',
      'pathPatternPresets',
    ]) {
      test('v5 rejects non-empty legacy manifest field $legacyKey', () {
        final raw = _minimalManifestJson(version: 'v5')
          ..[legacyKey] = <Object?>[<String, Object?>{}];

        expect(
          () => ProjectManifest.fromJson(raw),
          throwsA(
            isA<FormatException>().having(
              (error) => error.message,
              'message',
              allOf(
                contains('smart_tile_v5_legacy_manifest_unsupported'),
                contains(legacyKey),
              ),
            ),
          ),
        );
      });
    }

    for (final runtimeType in <String>['terrain', 'path']) {
      test('v5 rejects legacy $runtimeType layers before decoding', () {
        final raw = _minimalMapJson(version: 'v5')
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
                contains('smart_tile_v5_legacy_layer_unsupported'),
                contains(runtimeType),
              ),
            ),
          ),
        );
      });
    }

    test('v5 rejects legacy Smart Tile lists beside a native field', () {
      final raw = _minimalMapJson(version: 'v5')
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
            contains('smart_tile_v5_legacy_payload_unsupported'),
          ),
        ),
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
