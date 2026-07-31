import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('Smart Tiles project format v4', () {
    test('decodes v4 manifests and maps', () {
      expect(
        ProjectManifest.fromJson(_minimalManifestJson(version: 'v4')).version,
        ProjectVersion.v4,
      );
      expect(
        MapData.fromJson(_minimalMapJson(version: 'v4')).version,
        ProjectVersion.v4,
      );
    });

    test('v4 preserves the canonical v3 visual stack contract', () {
      final json = _minimalMapJson(version: 'v4')
        ..['visualStack'] = MapVisualStackConfig.canonicalV1.toJson();

      expect(MapData.fromJson(json).visualStack, isNotNull);
    });

    test('v2 still rejects visualStack', () {
      final json = _minimalMapJson(version: 'v2')
        ..['visualStack'] = MapVisualStackConfig.canonicalV1.toJson();

      expect(() => MapData.fromJson(json), throwsFormatException);
    });

    test('migration guards accept v4 and reject unknown future versions', () {
      final manifest = _minimalManifestJson(version: 'v4');
      expect(
        identical(migrateProjectManifestJson(manifest), manifest),
        isTrue,
      );
      expect(
        () => migrateProjectManifestJson(
          _minimalManifestJson(version: 'v5'),
        ),
        throwsFormatException,
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
