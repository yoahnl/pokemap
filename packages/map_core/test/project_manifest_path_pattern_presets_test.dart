import 'dart:convert';
import 'dart:io';

import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('ProjectManifest pathPatternPresets', () {
    test('decodes old manifests without pathPatternPresets as empty', () {
      final manifest = ProjectManifest.fromJson(_baseManifestJson());

      expect(manifest.pathPatternPresets, isEmpty);
      expect(manifest.toJson(), containsPair('pathPatternPresets', []));
    });

    test('decodes pathPatternPresets null as empty', () {
      final manifest = ProjectManifest.fromJson(
        _baseManifestJson(pathPatternPresets: null),
      );

      expect(manifest.pathPatternPresets, isEmpty);
    });

    test('decodes and encodes empty pathPatternPresets stably', () {
      final manifest = ProjectManifest.fromJson(
        _baseManifestJson(pathPatternPresets: <Object?>[]),
      );
      final json = manifest.toJson();

      expect(manifest.pathPatternPresets, isEmpty);
      expect(json.containsKey('pathPatternPresets'), isTrue);
      expect(json['pathPatternPresets'], <Object?>[]);
    });

    test('decodes the Lot 9 minimal golden through ProjectManifest', () {
      final fixture = _readPathPatternFixture(
        'project_path_pattern_preset_minimal_1x1.json',
      );
      final expected = decodeProjectPathPatternPreset(fixture);

      final manifest = ProjectManifest.fromJson(
        _baseManifestJson(pathPatternPresets: [fixture]),
      );

      expect(manifest.pathPatternPresets, [expected]);
    });

    test('decodes the Lot 9 complete golden through ProjectManifest', () {
      final fixture = _readPathPatternFixture(
        'project_path_pattern_preset_complete_2x2.json',
      );
      final expected = decodeProjectPathPatternPreset(fixture);

      final manifest = ProjectManifest.fromJson(
        _baseManifestJson(pathPatternPresets: [fixture]),
      );

      expect(manifest.pathPatternPresets, [expected]);
      expect(manifest.pathPatternPresets.single.transparentColor,
          TilesetTransparentColor.fromHexRgb('f05ba1'));
      expect(
        manifest.pathPatternPresets.single.centerPattern.size,
        PathCenterPatternSize(width: 2, height: 2),
      );
    });

    test('roundtrips manifest pathPatternPresets without changing order', () {
      final minimal = decodeProjectPathPatternPreset(
        _readPathPatternFixture(
          'project_path_pattern_preset_minimal_1x1.json',
        ),
      );
      final complete = decodeProjectPathPatternPreset(
        _readPathPatternFixture(
          'project_path_pattern_preset_complete_2x2.json',
        ),
      );
      final manifest = ProjectManifest(
        name: 'PathPattern manifest',
        maps: const [],
        tilesets: const [],
        pathPatternPresets: [minimal, complete],
        surfaceCatalog: ProjectSurfaceCatalog(),
      );

      final decoded = ProjectManifest.fromJson(
        jsonDecode(jsonEncode(manifest.toJson())) as Map<String, dynamic>,
      );

      expect(decoded.pathPatternPresets, [minimal, complete]);
    });

    test('does not migrate legacy pathPresets into pathPatternPresets', () {
      final manifest = ProjectManifest.fromJson(
        _baseManifestJson(pathPresets: [_legacyPathPresetJson()]),
      );

      expect(manifest.pathPresets, hasLength(1));
      expect(manifest.pathPatternPresets, isEmpty);
    });

    test('rejects invalid pathPatternPresets payloads', () {
      for (final payload in <Object?>[
        'not-list',
        [123],
        [
          <String, Object?>{
            'id': 'broken',
            'name': 'Broken',
            'basePathPresetId': 'legacy-water',
            'sortOrder': 0,
          },
        ],
      ]) {
        expect(
          () => ProjectManifest.fromJson(
            _baseManifestJson(pathPatternPresets: payload),
          ),
          throwsA(isA<ValidationException>()),
          reason: payload.toString(),
        );
      }
    });
  });
}

const _absent = Object();

Map<String, dynamic> _baseManifestJson({
  Object? pathPatternPresets = _absent,
  List<Object?> pathPresets = const [],
}) {
  final json = <String, dynamic>{
    'name': 'PathPattern manifest',
    'maps': <Object?>[],
    'tilesets': <Object?>[],
    'pathPresets': pathPresets,
  };
  if (!identical(pathPatternPresets, _absent)) {
    json['pathPatternPresets'] = pathPatternPresets;
  }
  return json;
}

Map<String, dynamic> _readPathPatternFixture(String name) {
  return jsonDecode(
    File('test/fixtures/path_pattern/$name').readAsStringSync(),
  ) as Map<String, dynamic>;
}

Map<String, dynamic> _legacyPathPresetJson() {
  return <String, dynamic>{
    'id': 'legacy-water',
    'name': 'Legacy Water',
    'surfaceKind': 'water',
    'tilesetId': 'outdoor',
    'variants': [
      <String, dynamic>{
        'variant': 'cross',
        'frames': [
          <String, dynamic>{
            'tilesetId': '',
            'source': <String, dynamic>{
              'x': 0,
              'y': 0,
              'width': 1,
              'height': 1,
            },
            'durationMs': null,
          },
        ],
      },
    ],
    'sortOrder': 0,
  };
}
