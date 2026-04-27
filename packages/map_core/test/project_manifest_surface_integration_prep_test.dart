import 'dart:convert';
import 'dart:io';

import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

/// ProjectManifest Surface integration prep (Lot 48) — comportement remplacé
/// en Lot 49 : [surfaceCatalog] est désormais un champ [ProjectManifest]
/// persisté (voir [surface_engine_lot_49] dans les rapports).
const _manifestSplitSurfaceKeyCandidates = <String>[
  'surfaceDefinitions',
  'surfaceAtlases',
  'surfaceAnimations',
  'surfacePresets',
  'surfaceCategories',
];

void main() {
  group(
    'ProjectManifest Surface Integration Prep: Lot 48 → Lot 49 transition',
    () {
    test(
      '1. Lot 48: no top-level surface keys; Lot 49: surfaceCatalog + no split',
      () {
        final manifest = _minimalManifest();
        final o = _asObjectMap(manifest.toJson());
        expect(o.containsKey('surfaceCatalog'), isTrue);
        expect(
          o['surfaceCatalog'],
          encodeProjectSurfaceCatalog(manifest.surfaceCatalog),
        );
        for (final k in _manifestSplitSurfaceKeyCandidates) {
          expect(o.containsKey(k), isFalse, reason: k);
        }
      },
    );

    test('2. manifest round-trips with default empty surface catalog', () {
      final manifest = _minimalManifest();
      final decoded = ProjectManifest.fromJson(manifest.toJson());
      expect(decoded, manifest);
    });

    test(
      '3. Lot 48 dropped unknown surfaceCatalog on write — Lot 49 persists it',
      () {
        final withCatalog = _withSurfaceCatalog(
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
        expect(out.containsKey('surfaceCatalog'), isTrue);
        expect(
          out['surfaceCatalog'],
          encodeProjectSurfaceCatalog(manifest.surfaceCatalog),
        );
        expect(manifest.surfaceCatalog.isEmpty, isTrue);
        expect(manifest.name, 'Lot 48 Prep');
      },
    );

    test(
      '4. Lot 47 minimal water: Lot 49 keeps catalog on manifest (was dropped in 48)',
      () {
        final surface = _readSurfaceCatalogFixtureJson(
          'minimal_water_surface_catalog_v0.json',
        );
        final withCatalog = _withSurfaceCatalog(_manifestJson(), surface);
        final manifest = ProjectManifest.fromJson(
          Map<String, dynamic>.from(withCatalog),
        );
        final out = _asObjectMap(manifest.toJson());
        expect(out.containsKey('surfaceCatalog'), isTrue);
        expect(
          out['surfaceCatalog'],
          encodeProjectSurfaceCatalog(manifest.surfaceCatalog),
        );
        expect(manifest.name, 'Lot 48 Prep');
        expect(manifest.maps, isEmpty);
        expect(manifest.tilesets, isEmpty);
        expect(manifest.surfaceCatalog.atlasCount, 1);
        expect(manifest.surfaceCatalog.animationCount, 1);
        expect(manifest.surfaceCatalog.presetCount, 1);
      },
    );

    test(
      '5. Lot 47 full water: Lot 49 keeps catalog on manifest (was dropped in 48)',
      () {
        final surface = _readSurfaceCatalogFixtureJson(
          'full_water_surface_catalog_v0.json',
        );
        final withCatalog = _withSurfaceCatalog(_manifestJson(), surface);
        final manifest = ProjectManifest.fromJson(
          Map<String, dynamic>.from(withCatalog),
        );
        final out = _asObjectMap(manifest.toJson());
        expect(out.containsKey('surfaceCatalog'), isTrue);
        expect(
          out['surfaceCatalog'],
          encodeProjectSurfaceCatalog(manifest.surfaceCatalog),
        );
        expect(manifest.name, 'Lot 48 Prep');
        expect(manifest.surfaceCatalog.atlasCount, 1);
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

    test('8. recommended manifest field name is surfaceCatalog', () {
      const recommendedFutureManifestField = 'surfaceCatalog';
      expect(recommendedFutureManifestField, 'surfaceCatalog');
    });

    test('9. discouraged split Surface key names are absent from toJson', () {
      final json = _minimalManifest().toJson();
      for (final k in _manifestSplitSurfaceKeyCandidates) {
        expect(json.containsKey(k), isFalse, reason: k);
      }
    });

    test('10. Lot 49: surfaceCatalog is always in toJson', () {
      expect(_minimalManifest().toJson().containsKey('surfaceCatalog'), isTrue);
    });

    test(
      '11. split + legacy root keys ignored; surfaceCatalog re-emitted; split not',
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
        expect(out.containsKey('surfaceCatalog'), isTrue);
        for (final k in _manifestSplitSurfaceKeyCandidates) {
          expect(out.containsKey(k), isFalse, reason: k);
        }
      },
    );

    test('12. Lot 47 fixtures are still valid JSON (unchanged by Lot 48/49 tests)', () {
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
      '15. Lot 49 adds surfaceCatalog to manifest wire (Lot 48 had none)',
      () {
        final keys = _minimalManifest().toJson().keys.toList();
        expect(keys.contains('surfaceCatalog'), isTrue);
      },
    );
  });
}

// --- helpers ---

Map<String, Object?> _asObjectMap(Map<String, dynamic> m) {
  return Map<String, Object?>.from(m);
}

ProjectManifest _minimalManifest() {
  return ProjectManifest(
    name: 'Lot 48 Prep',
    maps: [],
    tilesets: [],
    surfaceCatalog: ProjectSurfaceCatalog(),
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

Map<String, Object?> _withSurfaceCatalog(
  Map<String, Object?> manifestJson,
  Map<String, Object?> surfaceCatalogJson,
) {
  return <String, Object?>{
    ...manifestJson,
    'surfaceCatalog': surfaceCatalogJson,
  };
}
