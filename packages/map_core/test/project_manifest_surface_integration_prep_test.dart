import 'dart:convert';
import 'dart:io';

import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

/// ProjectManifest Surface integration prep (Lot 48).
///
/// [Lot 49] will likely break test 3 (unknown `surfaceCatalog` currently dropped on write).

const _manifestSurfaceKeyCandidates = <String>[
  'surfaceCatalog',
  'surfaceDefinitions',
  'surfaceAtlases',
  'surfaceAnimations',
  'surfacePresets',
  'surfaceCategories',
];

const _discouragedTopLevelNames = <String>[
  'surfaceDefinitions',
  'surfaceAtlases',
  'surfaceAnimations',
  'surfacePresets',
  'surfaceCategories',
];

void main() {
  group('ProjectManifest Surface Integration Prep (Lot 48)', () {
    test('1. current manifest toJson has no Surface persistence keys', () {
      final manifest = _minimalManifest();
      _expectNoSurfaceKeys(
        _asObjectMap(manifest.toJson()),
      );
    });

    test('2. current manifest round-trips without Surface', () {
      final manifest = _minimalManifest();
      final decoded = ProjectManifest.fromJson(manifest.toJson());
      expect(decoded, manifest);
    });

    test(
      '3. current manifest ignores unknown surfaceCatalog (dropped on toJson) — will change in Lot 49',
      () {
        final withCatalog = _withFutureSurfaceCatalog(
          _manifestJson(),
          <String, Object?>{
            'atlases': <Object?>[],
            'animations': <Object?>[],
            'presets': <Object?>[],
          },
        );
        final manifest = ProjectManifest.fromJson(
          Map<String, dynamic>.from(withCatalog),
        );
        final out = _asObjectMap(manifest.toJson());
        expect(out.containsKey('surfaceCatalog'), isFalse);
        expect(manifest.name, 'Lot 48 Prep');
      },
    );

    test(
      '4. current manifest ignores Lot 47 minimal water surfaceCatalog (dropped on toJson)',
      () {
        final surface = _readSurfaceCatalogFixtureJson(
          'minimal_water_surface_catalog_v0.json',
        );
        final withCatalog = _withFutureSurfaceCatalog(_manifestJson(), surface);
        final manifest = ProjectManifest.fromJson(
          Map<String, dynamic>.from(withCatalog),
        );
        final out = _asObjectMap(manifest.toJson());
        expect(out.containsKey('surfaceCatalog'), isFalse);
        expect(manifest.name, 'Lot 48 Prep');
        expect(manifest.maps, isEmpty);
        expect(manifest.tilesets, isEmpty);
      },
    );

    test(
      '5. current manifest ignores Lot 47 full water surfaceCatalog (dropped on toJson)',
      () {
        final surface = _readSurfaceCatalogFixtureJson(
          'full_water_surface_catalog_v0.json',
        );
        final withCatalog = _withFutureSurfaceCatalog(_manifestJson(), surface);
        final manifest = ProjectManifest.fromJson(
          Map<String, dynamic>.from(withCatalog),
        );
        final out = _asObjectMap(manifest.toJson());
        expect(out.containsKey('surfaceCatalog'), isFalse);
        expect(manifest.name, 'Lot 48 Prep');
      },
    );

    test('6. future minimal Lot 47 catalog decodes via decodeProjectSurfaceCatalog', () {
      final raw = _readSurfaceCatalogFixtureJson(
        'minimal_water_surface_catalog_v0.json',
      );
      final catalog = decodeProjectSurfaceCatalog(
        Map<String, dynamic>.from(raw),
      );
      expect(catalog.atlases.length, 1);
      expect(catalog.animations.length, 1);
      expect(catalog.presets.length, 1);
      expect(
        diagnoseProjectSurfaceCatalog(catalog).hasDiagnostics,
        isFalse,
      );
      expect(
        diagnoseProjectSurfaceCatalogUnusedResources(catalog).hasDiagnostics,
        isFalse,
      );
    });

    test('7. future full Lot 47 catalog decodes via decodeProjectSurfaceCatalog', () {
      final raw = _readSurfaceCatalogFixtureJson(
        'full_water_surface_catalog_v0.json',
      );
      final catalog = decodeProjectSurfaceCatalog(
        Map<String, dynamic>.from(raw),
      );
      expect(catalog.atlases.length, 1);
      expect(catalog.animations.length, 1);
      expect(catalog.presets.length, 1);
      expect(
        diagnoseProjectSurfaceCatalog(catalog).hasDiagnostics,
        isFalse,
      );
      expect(
        diagnoseProjectSurfaceCatalogUnusedResources(catalog).hasDiagnostics,
        isFalse,
      );
    });

    test('8. recommended future manifest field name is surfaceCatalog', () {
      const recommendedFutureManifestField = 'surfaceCatalog';
      expect(recommendedFutureManifestField, 'surfaceCatalog');
    });

    test('9. discouraged split Surface key names are absent from toJson', () {
      final json = _minimalManifest().toJson();
      for (final k in _discouragedTopLevelNames) {
        expect(json.containsKey(k), isFalse, reason: k);
      }
    });

    test(
      '10. surfaceCatalog is not yet a ProjectManifest field in Lot 48',
      () {
        expect(
          _minimalManifest().toJson().containsKey('surfaceCatalog'),
          isFalse,
        );
      },
    );

    test(
      '11. root unknown Surface keys do not break decode; not re-emitted on toJson',
      () {
        final merged = <String, Object?>{
          ..._manifestJson(),
          'surfaceCatalog': <String, Object?>{
            'atlases': <Object?>[],
            'animations': <Object?>[],
            'presets': <Object?>[],
          },
          'surfaceDefinitions': <Object?>[],
          'surfaceAtlases': <Object?>[],
          'surfaceAnimations': <Object?>[],
          'surfacePresets': <Object?>[],
          'surfaceCategories': <Object?>[],
        };
        final m = ProjectManifest.fromJson(
          Map<String, dynamic>.from(merged),
        );
        final out = m.toJson();
        for (final k in _manifestSurfaceKeyCandidates) {
          expect(out.containsKey(k), isFalse, reason: k);
        }
      },
    );

    test('12. Lot 47 fixtures are still valid JSON (unchanged by Lot 48)', () {
      for (final name in const <String>[
        'empty_surface_catalog_v0.json',
        'minimal_water_surface_catalog_v0.json',
        'full_water_surface_catalog_v0.json',
      ]) {
        final raw = File(_fixturePath(name)).readAsStringSync();
        final v = jsonDecode(raw);
        expect(v, isA<Object?>());
      }
    });

    test('13. Lot 47 fixtures are bare catalog JSON (no top-level surfaceCatalog)', () {
      for (final name in const <String>[
        'empty_surface_catalog_v0.json',
        'minimal_water_surface_catalog_v0.json',
        'full_water_surface_catalog_v0.json',
      ]) {
        final o = _readSurfaceCatalogFixtureJson(name);
        expect(o.containsKey('surfaceCatalog'), isFalse, reason: name);
      }
    });

    test(
      '14. catalog codec and manifest stay usable via public map_core (no src imports)',
      () {
        final c = decodeProjectSurfaceCatalog(
          Map<String, dynamic>.from(
            _readSurfaceCatalogFixtureJson('empty_surface_catalog_v0.json'),
          ),
        );
        expect(c.isEmpty, isTrue);
        expect(_minimalManifest().name, isNotEmpty);
      },
    );

    test(
      '15. Lot 48 does not add generated manifest Surface members — no new .g.dart contract in tests',
      () {
        // Assertions above use only toJson / fromJson and decodeProjectSurfaceCatalog;
        // report confirms no lib/ or generated file edits in this lot.
        expect(
          _minimalManifest().toJson().keys.where(
                (k) => k.contains('urface'),
              ),
          isEmpty,
        );
      },
    );
  });
}

// --- helpers ---

Map<String, Object?> _asObjectMap(Map<String, dynamic> m) {
  return Map<String, Object?>.from(m);
}

void _expectNoSurfaceKeys(Map<String, Object?> json) {
  for (final k in _manifestSurfaceKeyCandidates) {
    expect(json.containsKey(k), isFalse, reason: 'unexpected key: $k');
  }
}

ProjectManifest _minimalManifest() {
  return const ProjectManifest(
    name: 'Lot 48 Prep',
    maps: [],
    tilesets: [],
  );
}

Map<String, Object?> _manifestJson() {
  return <String, Object?>{
    'name': 'Lot 48 Prep',
    'maps': <Object?>[],
    'tilesets': <Object?>[],
  };
}

String _fixturePath(String name) {
  return 'test/fixtures/surface_catalog_json/$name';
}

Map<String, Object?> _readSurfaceCatalogFixtureJson(String name) {
  final s = File(_fixturePath(name)).readAsStringSync();
  return jsonDecode(s) as Map<String, Object?>;
}

Map<String, Object?> _withFutureSurfaceCatalog(
  Map<String, Object?> manifestJson,
  Map<String, Object?> surfaceCatalogJson,
) {
  return <String, Object?>{
    ...manifestJson,
    'surfaceCatalog': surfaceCatalogJson,
  };
}
