import 'dart:convert';
import 'dart:io';

import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('Surface catalog JSON golden samples (Lot 47)', () {
    const manifestKeys = <String>[
      'surfaceCatalog',
      'surfaceDefinitions',
      'surfaceAtlases',
      'surfaceAnimations',
      'surfacePresets',
      'surfaceCategories',
    ];

    const categoryListKeys = <String>['categories', 'surfaceCategories'];

    const forbiddenKindKeys = <String>['surfaceKind', 'presetKind', 'kind', 'type'];

    test('1. empty fixture is valid JSON', () {
      final raw = _readFixture('empty_surface_catalog_v0.json');
      final o = jsonDecode(raw);
      expect(o, isA<Map<String, Object?>>());
      final m = o as Map<String, Object?>;
      expect(m.keys.toSet(), <String>{'atlases', 'animations', 'presets'});
      expect(m['atlases'], isA<List>());
      expect(m['animations'], isA<List>());
      expect(m['presets'], isA<List>());
      expect(m['atlases'], isEmpty);
      expect(m['animations'], isEmpty);
      expect(m['presets'], isEmpty);
    });

    test('2. empty fixture matches codec', () {
      final catalog = ProjectSurfaceCatalog();
      final pretty = _prettyJson(encodeProjectSurfaceCatalog(catalog));
      final fixture = _readFixture('empty_surface_catalog_v0.json');
      expect(pretty, fixture);
    });

    test('3. empty fixture round-trip', () {
      final fixture = _readFixture('empty_surface_catalog_v0.json');
      final c = decodeProjectSurfaceCatalog(
        _readFixtureJson('empty_surface_catalog_v0.json'),
      );
      final pretty = _prettyJson(encodeProjectSurfaceCatalog(c));
      expect(pretty, fixture);
    });

    test('4. minimal water fixture is valid JSON with expected structure', () {
      final raw = _readFixture('minimal_water_surface_catalog_v0.json');
      final m = jsonDecode(raw) as Map<String, Object?>;
      expect((m['atlases'] as List).length, 1);
      expect((m['animations'] as List).length, 1);
      expect((m['presets'] as List).length, 1);
      final a0 = (m['atlases']! as List)[0] as Map<String, Object?>;
      final n0 = (m['animations']! as List)[0] as Map<String, Object?>;
      final p0 = (m['presets']! as List)[0] as Map<String, Object?>;
      expect(a0.containsKey('categoryId'), isFalse);
      expect(n0.containsKey('categoryId'), isFalse);
      expect(n0.containsKey('syncGroupId'), isFalse);
      expect(p0.containsKey('categoryId'), isFalse);
      expect(a0['sortOrder'], 0);
      expect(n0['sortOrder'], 0);
      expect(p0['sortOrder'], 0);
    });

    test('5. minimal water fixture matches codec', () {
      final catalog = _minimalWaterCatalog();
      final pretty = _prettyJson(encodeProjectSurfaceCatalog(catalog));
      final fixture = _readFixture('minimal_water_surface_catalog_v0.json');
      expect(pretty, fixture);
    });

    test('6. minimal water fixture round-trip', () {
      final fixture = _readFixture('minimal_water_surface_catalog_v0.json');
      final c = decodeProjectSurfaceCatalog(
        _readFixtureJson('minimal_water_surface_catalog_v0.json'),
      );
      final pretty = _prettyJson(encodeProjectSurfaceCatalog(c));
      expect(pretty, fixture);
    });

    test('7. minimal water: no error diagnostics', () {
      final c = decodeProjectSurfaceCatalog(
        _readFixtureJson('minimal_water_surface_catalog_v0.json'),
      );
      final r = diagnoseProjectSurfaceCatalog(c);
      expect(r.hasDiagnostics, isFalse);
    });

    test('8. minimal water: no unused resource diagnostics', () {
      final c = decodeProjectSurfaceCatalog(
        _readFixtureJson('minimal_water_surface_catalog_v0.json'),
      );
      final r = diagnoseProjectSurfaceCatalogUnusedResources(c);
      expect(r.hasDiagnostics, isFalse);
    });

    test('9. full water fixture is valid JSON with expected structure', () {
      final raw = _readFixture('full_water_surface_catalog_v0.json');
      final m = jsonDecode(raw) as Map<String, Object?>;
      expect((m['atlases'] as List).length, 1);
      expect((m['animations'] as List).length, 1);
      expect((m['presets'] as List).length, 1);
      final a0 = (m['atlases']! as List)[0] as Map<String, Object?>;
      final n0 = (m['animations']! as List)[0] as Map<String, Object?>;
      final p0 = (m['presets']! as List)[0] as Map<String, Object?>;
      expect(a0['categoryId'], 'animated-surfaces');
      expect(n0['syncGroupId'], 'water');
      expect(n0['categoryId'], 'animated-surfaces');
      expect(p0['categoryId'], 'animated-surfaces');
      final frames = (n0['timeline']! as Map)['frames']! as List;
      expect(frames.length, 2);
      final refs = (p0['variantAnimations']! as Map)['refs']! as List;
      expect(refs.length, 3);
    });

    test('10. full water fixture matches codec', () {
      final catalog = _fullWaterCatalog();
      final pretty = _prettyJson(encodeProjectSurfaceCatalog(catalog));
      final fixture = _readFixture('full_water_surface_catalog_v0.json');
      expect(pretty, fixture);
    });

    test('11. full water fixture round-trip', () {
      final fixture = _readFixture('full_water_surface_catalog_v0.json');
      final c = decodeProjectSurfaceCatalog(
        _readFixtureJson('full_water_surface_catalog_v0.json'),
      );
      final pretty = _prettyJson(encodeProjectSurfaceCatalog(c));
      expect(pretty, fixture);
    });

    test('12. full water: preset ref order is cross, isolated, horizontal', () {
      final c = decodeProjectSurfaceCatalog(
        _readFixtureJson('full_water_surface_catalog_v0.json'),
      );
      final roles = c.presets.first.variantAnimations.refs
          .map((r) => r.role)
          .toList();
      expect(roles, [
        SurfaceVariantRole.cross,
        SurfaceVariantRole.isolated,
        SurfaceVariantRole.horizontal,
      ]);
    });

    test('13. full water: no error diagnostics', () {
      final c = decodeProjectSurfaceCatalog(
        _readFixtureJson('full_water_surface_catalog_v0.json'),
      );
      expect(diagnoseProjectSurfaceCatalog(c).hasDiagnostics, isFalse);
    });

    test('14. full water: no unused resource diagnostics', () {
      final c = decodeProjectSurfaceCatalog(
        _readFixtureJson('full_water_surface_catalog_v0.json'),
      );
      expect(
        diagnoseProjectSurfaceCatalogUnusedResources(c).hasDiagnostics,
        isFalse,
      );
    });

    test('15. fixtures contain no manifest wrapper keys (raw string)', () {
      for (final f in const [
        'empty_surface_catalog_v0.json',
        'minimal_water_surface_catalog_v0.json',
        'full_water_surface_catalog_v0.json',
      ]) {
        final s = _readFixture(f);
        for (final k in manifestKeys) {
          expect(s.contains('"$k"'), isFalse, reason: '$f must not key $k');
        }
      }
    });

    test('16. fixtures contain no category list keys', () {
      for (final f in const [
        'empty_surface_catalog_v0.json',
        'minimal_water_surface_catalog_v0.json',
        'full_water_surface_catalog_v0.json',
      ]) {
        final s = _readFixture(f);
        for (final k in categoryListKeys) {
          expect(s.contains('"$k"'), isFalse, reason: '$f $k');
        }
      }
    });

    test('17. fixtures contain no kind/surfaceKind/type as map keys (deep)', () {
      for (final f in const [
        'empty_surface_catalog_v0.json',
        'minimal_water_surface_catalog_v0.json',
        'full_water_surface_catalog_v0.json',
      ]) {
        final o = jsonDecode(_readFixture(f)) as Object?;
        expect(_mapContainsAnyKeyFrom(o, forbiddenKindKeys.toSet()), isFalse);
      }
    });

    test('18. fixtures end with newline', () {
      for (final f in const [
        'empty_surface_catalog_v0.json',
        'minimal_water_surface_catalog_v0.json',
        'full_water_surface_catalog_v0.json',
      ]) {
        final s = _readFixture(f);
        expect(s.endsWith('\n'), isTrue, reason: f);
      }
    });

    test('19. fixtures match two-space pretty jsonEncode roundtrip', () {
      for (final name in const [
        'empty_surface_catalog_v0.json',
        'minimal_water_surface_catalog_v0.json',
        'full_water_surface_catalog_v0.json',
      ]) {
        final raw = _readFixture(name);
        final decoded = jsonDecode(raw) as Object?;
        const encoder = JsonEncoder.withIndent('  ');
        final repretty = _withTrailingNewline(encoder.convert(decoded));
        expect(repretty, raw, reason: name);
      }
    });

    test('20. each fixture is stable: decode->encode->pretty equals fixture', () {
      for (final name in const [
        'empty_surface_catalog_v0.json',
        'minimal_water_surface_catalog_v0.json',
        'full_water_surface_catalog_v0.json',
      ]) {
        final raw = _readFixture(name);
        final m = _readFixtureJson(name);
        final c = decodeProjectSurfaceCatalog(m);
        final out = _prettyJson(encodeProjectSurfaceCatalog(c));
        expect(out, raw, reason: name);
      }
    });

    test('21. water fixtures use layout columnsAreVariantsRowsAreFrames', () {
      for (final name in const [
        'minimal_water_surface_catalog_v0.json',
        'full_water_surface_catalog_v0.json',
      ]) {
        final s = _readFixture(name);
        expect(
          s.contains('columnsAreVariantsRowsAreFrames'),
          isTrue,
          reason: name,
        );
        expect(s.contains('"grid"'), isFalse, reason: name);
      }
    });

    test('22. water fixtures: sortOrder on every atlas, animation, preset', () {
      for (final name in const [
        'minimal_water_surface_catalog_v0.json',
        'full_water_surface_catalog_v0.json',
      ]) {
        final m = jsonDecode(_readFixture(name)) as Map<String, Object?>;
        for (final listKey in const ['atlases', 'animations', 'presets']) {
          for (final item in m[listKey]! as List) {
            final o = item as Map<String, Object?>;
            expect(o.containsKey('sortOrder'), isTrue, reason: '$name $listKey');
          }
        }
      }
    });

    test('23. minimal fixture omits null optional fields (categoryId, syncGroupId)', () {
      final m = _readFixtureJson('minimal_water_surface_catalog_v0.json');
      final a0 = (m['atlases']! as List)[0]! as Map<String, Object?>;
      final n0 = (m['animations']! as List)[0]! as Map<String, Object?>;
      final p0 = (m['presets']! as List)[0]! as Map<String, Object?>;
      expect(a0.containsKey('categoryId'), isFalse);
      expect(n0.containsKey('categoryId'), isFalse);
      expect(n0.containsKey('syncGroupId'), isFalse);
      expect(p0.containsKey('categoryId'), isFalse);
    });

    test('24. only public map_core import for package (no src/)', () {
      // Ce fichier n'importe que `package:map_core/map_core.dart` (aucun `package:map_core/src/`).
      expect(encodeProjectSurfaceCatalog(_minimalWaterCatalog()), isA<Map<String, Object?>>());
    });

    test('25. ProjectManifest: surfaceCatalog key; no split surface keys (Lot 49)', () {
      final manifest = ProjectManifest(
        name: 'L47',
        maps: [
          ProjectMapEntry(
            id: 'm1',
            name: 'M',
            relativePath: 'maps/m1.json',
          ),
        ],
        tilesets: [],
        surfaceCatalog: ProjectSurfaceCatalog(),
      );
      final ju = manifest.toJson();
      expect(ju.containsKey('surfaceCatalog'), isTrue);
      expect(
        ju['surfaceCatalog'],
        encodeProjectSurfaceCatalog(manifest.surfaceCatalog),
      );
      for (final k in const [
        'surfaceDefinitions',
        'surfaceAtlases',
        'surfaceAnimations',
        'surfacePresets',
        'surfaceCategories',
      ]) {
        expect(ju.containsKey(k), isFalse, reason: k);
      }
    });
  });
}

String _fixturePath(String name) => 'test/fixtures/surface_catalog_json/$name';

String _readFixture(String name) => File(_fixturePath(name)).readAsStringSync();

Map<String, Object?> _readFixtureJson(String name) {
  return jsonDecode(_readFixture(name)) as Map<String, Object?>;
}

String _prettyJson(Map<String, Object?> json) {
  const encoder = JsonEncoder.withIndent('  ');
  return _withTrailingNewline(encoder.convert(json));
}

String _withTrailingNewline(String value) {
  if (value.endsWith('\n')) {
    return value;
  }
  return '$value\n';
}

/// Parcourt maps JSON ; ne considère que les clés de map (pas le contenu des strings).
bool _mapContainsAnyKeyFrom(Object? o, Set<String> forbidden) {
  if (o is Map) {
    for (final e in o.entries) {
      if (e.key is String && forbidden.contains(e.key! as String)) {
        return true;
      }
      if (_mapContainsAnyKeyFrom(e.value, forbidden)) {
        return true;
      }
    }
  } else if (o is List) {
    for (final e in o) {
      if (_mapContainsAnyKeyFrom(e, forbidden)) {
        return true;
      }
    }
  }
  return false;
}

SurfaceAtlasGeometry _sharedWaterGeometry() {
  return SurfaceAtlasGeometry(
    tileSize: SurfaceAtlasTileSize(width: 32, height: 32),
    gridSize: SurfaceAtlasGridSize(columns: 23, rows: 32),
    layout: SurfaceAtlasLayout.columnsAreVariantsRowsAreFrames,
  );
}

ProjectSurfaceAtlas _waterAtlas({
  String id = 'water-atlas',
  String name = 'Water Atlas',
  String tilesetId = 'nature-tileset',
  String? categoryId = 'animated-surfaces',
  int sortOrder = 10,
}) {
  return ProjectSurfaceAtlas(
    id: id,
    name: name,
    tilesetId: tilesetId,
    geometry: _sharedWaterGeometry(),
    categoryId: categoryId,
    sortOrder: sortOrder,
  );
}

ProjectSurfaceAnimation _waterAnimation({
  String id = 'water-loop',
  String name = 'Water Loop',
  int sortOrder = 20,
  String? syncGroupId = 'water',
  String? categoryId = 'animated-surfaces',
  bool twoFrames = true,
  String atlasId = 'water-atlas',
}) {
  return ProjectSurfaceAnimation(
    id: id,
    name: name,
    timeline: SurfaceAnimationTimeline(
      frames: twoFrames
          ? [
              SurfaceAnimationFrame(
                tileRef: SurfaceAtlasTileRef(
                  atlasId: atlasId,
                  column: 0,
                  row: 0,
                ),
                durationMs: 120,
              ),
              SurfaceAnimationFrame(
                tileRef: SurfaceAtlasTileRef(
                  atlasId: atlasId,
                  column: 0,
                  row: 1,
                ),
                durationMs: 120,
              ),
            ]
          : [
              SurfaceAnimationFrame(
                tileRef: SurfaceAtlasTileRef(
                  atlasId: atlasId,
                  column: 0,
                  row: 0,
                ),
                durationMs: 120,
              ),
            ],
    ),
    syncGroupId: syncGroupId,
    categoryId: categoryId,
    sortOrder: sortOrder,
  );
}

ProjectSurfacePreset _waterPreset({
  String id = 'water-surface',
  String name = 'Water Surface',
  String? categoryId = 'animated-surfaces',
  int sortOrder = 30,
  String animationId = 'water-loop',
  bool multiRef = true,
}) {
  final refs = multiRef
      ? <SurfaceVariantAnimationRef>[
          SurfaceVariantAnimationRef(
            role: SurfaceVariantRole.cross,
            animationId: animationId,
          ),
          SurfaceVariantAnimationRef(
            role: SurfaceVariantRole.isolated,
            animationId: animationId,
          ),
          SurfaceVariantAnimationRef(
            role: SurfaceVariantRole.horizontal,
            animationId: animationId,
          ),
        ]
      : <SurfaceVariantAnimationRef>[
          SurfaceVariantAnimationRef(
            role: SurfaceVariantRole.isolated,
            animationId: animationId,
          ),
        ];
  return ProjectSurfacePreset(
    id: id,
    name: name,
    variantAnimations: SurfaceVariantAnimationRefSet(refs: refs),
    categoryId: categoryId,
    sortOrder: sortOrder,
  );
}

ProjectSurfaceCatalog _minimalWaterCatalog() {
  return ProjectSurfaceCatalog(
    atlases: [
      _waterAtlas(
        categoryId: null,
        sortOrder: 0,
      ),
    ],
    animations: [
      _waterAnimation(
        id: 'water-isolated-loop',
        name: 'Water Isolated Loop',
        sortOrder: 0,
        syncGroupId: null,
        categoryId: null,
        twoFrames: false,
        atlasId: 'water-atlas',
      ),
    ],
    presets: [
      _waterPreset(
        categoryId: null,
        sortOrder: 0,
        animationId: 'water-isolated-loop',
        multiRef: false,
      ),
    ],
  );
}

ProjectSurfaceCatalog _fullWaterCatalog() {
  return ProjectSurfaceCatalog(
    atlases: [
      _waterAtlas(
        sortOrder: 10,
        categoryId: 'animated-surfaces',
      ),
    ],
    animations: [
      _waterAnimation(
        id: 'water-loop',
        name: 'Water Loop',
        sortOrder: 20,
        twoFrames: true,
      ),
    ],
    presets: [
      _waterPreset(
        sortOrder: 30,
        multiRef: true,
        animationId: 'water-loop',
      ),
    ],
  );
}
