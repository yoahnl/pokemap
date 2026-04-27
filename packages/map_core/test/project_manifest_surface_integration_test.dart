import 'dart:convert';
import 'dart:io';

import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('ProjectManifest Surface Integration (Lot 49)', () {
    test('1. ProjectManifest exposes surfaceCatalog', () {
      final m = _minimal();
      expect(m.surfaceCatalog.isEmpty, isTrue);
    });

    test('2. toJson encodes surfaceCatalog even when empty', () {
      final m = _minimal();
      final json = m.toJson();
      expect(json.containsKey('surfaceCatalog'), isTrue);
      expect(
        json['surfaceCatalog'],
        encodeProjectSurfaceCatalog(ProjectSurfaceCatalog()),
      );
    });

    test('3. fromJson accepts missing surfaceCatalog key', () {
      final raw = <String, dynamic>{
        'name': 'Legacy',
        'maps': <dynamic>[],
        'tilesets': <dynamic>[],
      };
      final m = ProjectManifest.fromJson(raw);
      expect(m.surfaceCatalog.isEmpty, isTrue);
      final out = m.toJson();
      expect(out.containsKey('surfaceCatalog'), isTrue);
      expect(
        out['surfaceCatalog'],
        encodeProjectSurfaceCatalog(m.surfaceCatalog),
      );
    });

    test('4. fromJson accepts surfaceCatalog: null as empty', () {
      final raw = <String, dynamic>{
        'name': 'NullCat',
        'maps': <dynamic>[],
        'tilesets': <dynamic>[],
        'surfaceCatalog': null,
      };
      final m = ProjectManifest.fromJson(raw);
      expect(m.surfaceCatalog.isEmpty, isTrue);
    });

    test('5. fromJson rejects surfaceCatalog when not a JSON object', () {
      final raw = <String, dynamic>{
        'name': 'Bad',
        'maps': <dynamic>[],
        'tilesets': <dynamic>[],
        'surfaceCatalog': 'nope',
      };
      expect(
        () => ProjectManifest.fromJson(raw),
        throwsA(isA<ValidationException>()),
      );
    });

    test('6. fromJson rejects incomplete surfaceCatalog (missing presets)', () {
      final raw = <String, dynamic>{
        'name': 'Inc',
        'maps': <dynamic>[],
        'tilesets': <dynamic>[],
        'surfaceCatalog': <String, dynamic>{
          'atlases': <dynamic>[],
          'animations': <dynamic>[],
        },
      };
      expect(
        () => ProjectManifest.fromJson(raw),
        throwsA(isA<ValidationException>()),
      );
    });

    test('7. fromJson decodes empty_surface_catalog_v0.json under surfaceCatalog', () {
      final inner = _readFixtureJson('empty_surface_catalog_v0.json');
      final m = ProjectManifest.fromJson(
        _wireWithSurface(inner),
      );
      expect(m.surfaceCatalog.isEmpty, isTrue);
      final json = m.toJson();
      final expected = Map<String, Object?>.from(inner);
      expect(
        Map<String, Object?>.from(
          json['surfaceCatalog']! as Map<dynamic, dynamic>,
        ),
        expected,
      );
    });

    test('8. fromJson decodes minimal_water_surface_catalog_v0.json', () {
      final inner = _readFixtureJson('minimal_water_surface_catalog_v0.json');
      final m = ProjectManifest.fromJson(_wireWithSurface(inner));
      expect(m.surfaceCatalog.atlasCount, 1);
      expect(m.surfaceCatalog.animationCount, 1);
      expect(m.surfaceCatalog.presetCount, 1);
      expect(
        diagnoseProjectSurfaceCatalog(m.surfaceCatalog).hasDiagnostics,
        isFalse,
      );
      expect(
        diagnoseProjectSurfaceCatalogUnusedResources(m.surfaceCatalog)
            .hasDiagnostics,
        isFalse,
      );
      expect(
        m.toJson()['surfaceCatalog'],
        encodeProjectSurfaceCatalog(m.surfaceCatalog),
      );
    });

    test('9. fromJson decodes full_water_surface_catalog_v0.json', () {
      final inner = _readFixtureJson('full_water_surface_catalog_v0.json');
      final m = ProjectManifest.fromJson(_wireWithSurface(inner));
      expect(m.surfaceCatalog.atlasCount, 1);
      expect(m.surfaceCatalog.animationCount, 1);
      expect(m.surfaceCatalog.presetCount, 1);
      expect(
        m.toJson()['surfaceCatalog'],
        encodeProjectSurfaceCatalog(m.surfaceCatalog),
      );
    });

    test('10. round-trip manifest with minimal water catalog', () {
      final inner = _readFixtureJson('minimal_water_surface_catalog_v0.json');
      final a = ProjectManifest.fromJson(_wireWithSurface(inner));
      final b = ProjectManifest.fromJson(
        jsonDecode(jsonEncode(a.toJson())) as Map<String, dynamic>,
      );
      expect(b, a);
    });

    test('11. round-trip manifest with full water catalog', () {
      final inner = _readFixtureJson('full_water_surface_catalog_v0.json');
      final a = ProjectManifest.fromJson(_wireWithSurface(inner));
      final b = ProjectManifest.fromJson(
        jsonDecode(jsonEncode(a.toJson())) as Map<String, dynamic>,
      );
      expect(b, a);
    });

    test('12. copyWith preserves surfaceCatalog when renaming', () {
      final inner = _readFixtureJson('minimal_water_surface_catalog_v0.json');
      final m = ProjectManifest.fromJson(_wireWithSurface(inner));
      final copy = m.copyWith(name: 'Renamed');
      expect(copy.name, 'Renamed');
      expect(copy.surfaceCatalog, m.surfaceCatalog);
    });

    test('13. copyWith can replace surfaceCatalog', () {
      final empty = _minimal();
      final inner = _readFixtureJson('minimal_water_surface_catalog_v0.json');
      final cat = decodeProjectSurfaceCatalog(
        Map<String, dynamic>.from(inner),
      );
      final copy = empty.copyWith(surfaceCatalog: cat);
      expect(copy.surfaceCatalog, cat);
    });

    test('14. equality distinguishes surfaceCatalog', () {
      final a = _minimal();
      final inner = _readFixtureJson('minimal_water_surface_catalog_v0.json');
      final cat = decodeProjectSurfaceCatalog(
        Map<String, dynamic>.from(inner),
      );
      final b = a.copyWith(surfaceCatalog: cat);
      expect(a == b, isFalse);
    });

    test('15. toJson surfaceCatalog matches encodeProjectSurfaceCatalog', () {
      final inner = _readFixtureJson('full_water_surface_catalog_v0.json');
      final m = ProjectManifest.fromJson(_wireWithSurface(inner));
      final json = m.toJson();
      expect(
        json['surfaceCatalog'],
        encodeProjectSurfaceCatalog(m.surfaceCatalog),
      );
    });

    test('16. split legacy Surface keys remain absent from toJson', () {
      final json = _minimal().toJson();
      for (final k in const [
        'surfaceDefinitions',
        'surfaceAtlases',
        'surfaceAnimations',
        'surfacePresets',
        'surfaceCategories',
      ]) {
        expect(json.containsKey(k), isFalse, reason: k);
      }
    });

    test('17. Lot 47 fixtures remain bare catalog JSON (no manifest wrapper)', () {
      for (final name in const [
        'empty_surface_catalog_v0.json',
        'minimal_water_surface_catalog_v0.json',
        'full_water_surface_catalog_v0.json',
      ]) {
        final o = _readFixtureJson(name);
        expect(o.containsKey('surfaceCatalog'), isFalse, reason: name);
      }
    });

    test('18. unknown root key futureUnknownKey is not re-emitted', () {
      final raw = <String, dynamic>{
        'name': 'U',
        'maps': <dynamic>[],
        'tilesets': <dynamic>[],
        'futureUnknownKey': 123,
      };
      final m = ProjectManifest.fromJson(raw);
      final out = m.toJson();
      expect(out.containsKey('futureUnknownKey'), isFalse);
    });

    test('19. invalid atlas id in surfaceCatalog surfaces ValidationException', () {
      final raw = <String, dynamic>{
        'name': 'BadAtlas',
        'maps': <dynamic>[],
        'tilesets': <dynamic>[],
        'surfaceCatalog': <String, dynamic>{
          'atlases': <dynamic>[
            <String, dynamic>{
              'id': '   ',
              'name': 'X',
              'tilesetId': 't',
              'geometry': _minimalGeometry(),
              'sortOrder': 0,
            },
          ],
          'animations': <dynamic>[],
          'presets': <dynamic>[],
        },
      };
      expect(
        () => ProjectManifest.fromJson(raw),
        throwsA(
          predicate<dynamic>(
            (e) =>
                e is ValidationException &&
                e.toString().contains('ProjectSurfaceAtlas.id'),
          ),
        ),
      );
    });

    test('20. public map_core API only: imports limited to map_core (see file header)', () {
      // Ce fichier n’importe que `map_core` et l’API standard Dart.
      final m = _minimal();
      expect(m.surfaceCatalog, isA<ProjectSurfaceCatalog>());
    });
  });
}

Map<String, dynamic> _minimalGeometry() {
  return <String, dynamic>{
    'tileSize': <String, dynamic>{'width': 16, 'height': 16},
    'gridSize': <String, dynamic>{'columns': 1, 'rows': 1},
    'layout': 'columnsAreVariantsRowsAreFrames',
  };
}

ProjectManifest _minimal() {
  return ProjectManifest(
    name: 'Lot 49',
    maps: const [],
    tilesets: const [],
    surfaceCatalog: ProjectSurfaceCatalog(),
  );
}

String _fixturePath(String name) => 'test/fixtures/surface_catalog_json/$name';

Map<String, Object?> _readFixtureJson(String name) {
  return jsonDecode(File(_fixturePath(name)).readAsStringSync())
      as Map<String, Object?>;
}

Map<String, dynamic> _wireWithSurface(Map<String, Object?> inner) {
  return <String, dynamic>{
    'name': 'Wired',
    'maps': <dynamic>[],
    'tilesets': <dynamic>[],
    'surfaceCatalog': inner,
  };
}
