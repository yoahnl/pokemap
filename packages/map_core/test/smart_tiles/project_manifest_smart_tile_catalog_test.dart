import 'dart:convert';

import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('ProjectManifest Smart Tile catalog', () {
    for (final version in <String>['v1', 'v2', 'v3']) {
      test('missing catalog defaults to empty without $version JSON churn', () {
        final manifest = ProjectManifest.fromJson(
          _minimalManifestJson(version: version),
        );

        expect(
            manifest.smartTileCatalog, const ProjectSmartTileCatalog.empty());
        expect(manifest.toJson(), isNot(contains('smartTileCatalog')));
      });
    }

    test('empty catalog round-trips in v4', () {
      final decoded = ProjectManifest.fromJson(
        _minimalManifestJson(version: 'v4'),
      );
      final roundTripped = ProjectManifest.fromJson(
        jsonDecode(jsonEncode(decoded.toJson())) as Map<String, dynamic>,
      );

      expect(roundTripped.version, ProjectVersion.v4);
      expect(roundTripped.smartTileCatalog.isEmpty, isTrue);
    });

    test('non-empty catalog requires v4', () {
      for (final version in <String>['v1', 'v2', 'v3']) {
        final json = _minimalManifestJson(version: version)
          ..['smartTileCatalog'] = _nonEmptyCatalog.toJson();

        expect(
          () => ProjectManifest.fromJson(json),
          throwsA(
            isA<FormatException>().having(
              (error) => error.message,
              'message',
              contains(r'$.smartTileCatalog'),
            ),
          ),
          reason: version,
        );
      }
    });

    test('v4 persists a native catalog beside legacy authoring fields', () {
      final json = _minimalManifestJson(version: 'v4')
        ..addAll(<String, Object?>{
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
          'smartTileCatalog': _nonEmptyCatalog.toJson(),
        });

      final manifest = ProjectManifest.fromJson(json);
      final encoded = manifest.toJson();

      expect(manifest.smartTileCatalog, _nonEmptyCatalog);
      expect(encoded['terrainPresets'], isEmpty);
      expect(encoded['pathPresets'], isEmpty);
      expect(encoded['pathPatternPresets'], isEmpty);
      expect(encoded['surfaceCatalog'], isA<Map<String, Object?>>());
      expect(encoded['smartTileCatalog'], _nonEmptyCatalog.toJson());
    });

    test('Corner 12 template hint survives JSON round-trip', () {
      const preset = ProjectSmartTilePreset(
        id: 'erw-corner-12',
        name: 'ERW Corner 12',
        usage: SmartTileUsage.path,
        topology: SmartTileTopology.wangCorner4,
        templateHint: SmartTileTemplateHint.corner12,
        defaultMaterialId: 'grass',
        allowedMaterialIds: <String>['grass'],
      );

      final encoded = preset.toJson();
      final decoded = ProjectSmartTilePreset.fromJson(
        jsonDecode(jsonEncode(encoded)) as Map<String, dynamic>,
      );

      expect(encoded['templateHint'], 'corner_12');
      expect(decoded, preset);
    });
  });
}

final ProjectSmartTileCatalog _nonEmptyCatalog = ProjectSmartTileCatalog(
  categories: const <ProjectSmartTileCategory>[
    ProjectSmartTileCategory(id: 'hanazuki', name: 'Hanazuki'),
  ],
);

Map<String, dynamic> _minimalManifestJson({required String version}) {
  return <String, dynamic>{
    'name': 'Smart Tiles test project',
    'version': version,
    'maps': <Object?>[],
    'tilesets': <Object?>[],
  };
}
