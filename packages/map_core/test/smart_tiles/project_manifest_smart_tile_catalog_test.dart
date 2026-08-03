import 'dart:convert';

import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('ProjectManifest Smart Tile catalog', () {
    test('missing catalog defaults to empty without v6 JSON churn', () {
      final manifest = ProjectManifest.fromJson(_minimalManifestJson());

      expect(manifest.smartTileCatalog, const ProjectSmartTileCatalog.empty());
      expect(manifest.toJson(), isNot(contains('smartTileCatalog')));
    });

    test('empty catalog round-trips in v6', () {
      final decoded = ProjectManifest.fromJson(_minimalManifestJson());
      final roundTripped = ProjectManifest.fromJson(
        jsonDecode(jsonEncode(decoded.toJson())) as Map<String, dynamic>,
      );

      expect(roundTripped.version, ProjectVersion.v6);
      expect(roundTripped.smartTileCatalog.isEmpty, isTrue);
    });

    test('v6 persists a native catalog', () {
      final json = _minimalManifestJson()
        ..['smartTileCatalog'] = _nonEmptyCatalog.toJson();

      final manifest = ProjectManifest.fromJson(json);
      final encoded = manifest.toJson();

      expect(manifest.smartTileCatalog, _nonEmptyCatalog);
      expect(encoded['smartTileCatalog'], _nonEmptyCatalog.toJson());
    });

    test('Corner 12 template hint survives JSON round-trip', () {
      const preset = ProjectSmartTilePreset(
        id: 'erw-corner-12',
        name: 'ERW Corner 12',
        usage: SmartTileUsage.path,
        topology: SmartTileTopology.wangCorner4,
        templateHint: SmartTileTemplateHint.corner12,
        coveragePolicy: SmartTileCoveragePolicy.complete,
        coverageProfile: SmartTileCoverageProfile(
          mode: SmartTileCoverageMode.template,
        ),
        transformPolicy: SmartTileTransformPolicy(),
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

Map<String, dynamic> _minimalManifestJson() {
  return <String, dynamic>{
    'name': 'Smart Tiles test project',
    'version': 'v6',
    'maps': <Object?>[],
    'tilesets': <Object?>[],
  };
}
