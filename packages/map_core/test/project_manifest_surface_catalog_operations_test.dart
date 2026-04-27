import 'dart:convert';
import 'dart:io';

import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('ProjectManifest surface catalog operations (Lot 50)', () {
    test('1. getProjectManifestSurfaceCatalog returns the manifest catalog', () {
      final cat = _minimalWaterCatalog();
      final m = _manifest(surfaceCatalog: cat);
      expect(
        identical(getProjectManifestSurfaceCatalog(m), m.surfaceCatalog),
        isTrue,
      );
    });

    test('2. projectManifestSurfaceCatalogIsEmpty true for empty catalog', () {
      expect(
        projectManifestSurfaceCatalogIsEmpty(_manifest()),
        isTrue,
      );
    });

    test('3. projectManifestSurfaceCatalogIsEmpty false for non-empty catalog', () {
      final m = _manifest(surfaceCatalog: _minimalWaterCatalog());
      expect(projectManifestSurfaceCatalogIsEmpty(m), isFalse);
    });

    test('4. replaceProjectManifestSurfaceCatalog replaces only catalog', () {
      final base = _manifest(
        surfaceCatalog: ProjectSurfaceCatalog(),
        settings: const ProjectSettings(tileWidth: 99, tileHeight: 11),
        pokemon: const ProjectPokemonConfig(enabled: false),
      );
      final minimal = _minimalWaterCatalog();
      final updated = replaceProjectManifestSurfaceCatalog(base, minimal);
      expect(updated.surfaceCatalog, minimal);
      expect(updated.name, base.name);
      expect(updated.maps, base.maps);
      expect(updated.tilesets, base.tilesets);
      expect(updated.settings.tileWidth, 99);
      expect(updated.settings.tileHeight, 11);
      expect(updated.pokemon.enabled, isFalse);
    });

    test('5. replaceProjectManifestSurfaceCatalog does not mutate source manifest', () {
      final empty = ProjectSurfaceCatalog();
      final m = _manifest(surfaceCatalog: empty);
      final originalRef = m.surfaceCatalog;
      final minimal = _minimalWaterCatalog();
      final u = replaceProjectManifestSurfaceCatalog(m, minimal);
      expect(identical(m.surfaceCatalog, originalRef), isTrue);
      expect(m.surfaceCatalog.isEmpty, isTrue);
      expect(u.surfaceCatalog, minimal);
      expect(identical(u, m), isFalse);
    });

    test('6. replaceProjectManifestSurfaceCatalog preserves JSON encoding contract', () {
      final updated = replaceProjectManifestSurfaceCatalog(
        _manifest(),
        _minimalWaterCatalog(),
      );
      final json = updated.toJson();
      expect(
        json['surfaceCatalog'],
        encodeProjectSurfaceCatalog(updated.surfaceCatalog),
      );
    });

    test('7. updateProjectManifestSurfaceCatalog passes current catalog to update', () {
      ProjectSurfaceCatalog? received;
      final m = _manifest(surfaceCatalog: _minimalWaterCatalog());
      updateProjectManifestSurfaceCatalog(m, (current) {
        received = current;
        return current;
      });
      expect(received, m.surfaceCatalog);
    });

    test('8. updateProjectManifestSurfaceCatalog calls update exactly once', () {
      var count = 0;
      final m = _manifest();
      updateProjectManifestSurfaceCatalog(m, (c) {
        count++;
        return c;
      });
      expect(count, 1);
    });

    test('9. updateProjectManifestSurfaceCatalog uses returned catalog as new value', () {
      final full = _fullWaterCatalog();
      final m = _manifest(surfaceCatalog: _minimalWaterCatalog());
      final u = updateProjectManifestSurfaceCatalog(m, (_) => full);
      expect(u.surfaceCatalog, full);
    });

    test('10. updateProjectManifestSurfaceCatalog preserves other fields', () {
      final base = _manifest(
        settings: const ProjectSettings(tileWidth: 42, displayScale: 3),
      );
      final u = updateProjectManifestSurfaceCatalog(
        base,
        (_) => _minimalWaterCatalog(),
      );
      expect(u.name, base.name);
      expect(u.settings.tileWidth, 42);
      expect(u.settings.displayScale, 3);
    });

    test('11. updateProjectManifestSurfaceCatalog propagates exceptions', () {
      final m = _manifest();
      expect(
        () => updateProjectManifestSurfaceCatalog(
          m,
          (_) => throw StateError('boom'),
        ),
        throwsA(isA<StateError>()),
      );
    });

    test('12. clearProjectManifestSurfaceCatalog yields empty catalog', () {
      final m = _manifest(surfaceCatalog: _fullWaterCatalog());
      final cleared = clearProjectManifestSurfaceCatalog(m);
      expect(cleared.surfaceCatalog.isEmpty, isTrue);
    });

    test('13. clearProjectManifestSurfaceCatalog does not mutate source', () {
      final full = _fullWaterCatalog();
      final m = _manifest(surfaceCatalog: full);
      clearProjectManifestSurfaceCatalog(m);
      expect(m.surfaceCatalog, full);
      expect(m.surfaceCatalog.isEmpty, isFalse);
    });

    test('14. clearProjectManifestSurfaceCatalog preserves other fields', () {
      final base = _manifest(
        name: 'KeepName',
        surfaceCatalog: _minimalWaterCatalog(),
      );
      final c = clearProjectManifestSurfaceCatalog(base);
      expect(c.name, 'KeepName');
      expect(c.maps, base.maps);
    });

    test('15. round-trip JSON after replace with minimal water', () {
      final updated = replaceProjectManifestSurfaceCatalog(
        _manifest(),
        _minimalWaterCatalog(),
      );
      final decoded = ProjectManifest.fromJson(
        jsonDecode(jsonEncode(updated.toJson())) as Map<String, dynamic>,
      );
      expect(decoded, updated);
    });

    test('16. round-trip JSON after clear', () {
      final cleared = clearProjectManifestSurfaceCatalog(
        _manifest(surfaceCatalog: _fullWaterCatalog()),
      );
      final decoded = ProjectManifest.fromJson(
        jsonDecode(jsonEncode(cleared.toJson())) as Map<String, dynamic>,
      );
      expect(decoded, cleared);
    });

    test('17. helpers do not run diagnostics; invalid refs still allowed', () {
      final orphan = _orphanRefCatalog();
      final m = _manifest();
      final replaced = replaceProjectManifestSurfaceCatalog(m, orphan);
      expect(replaced.surfaceCatalog, orphan);
      final diag = diagnoseProjectSurfaceCatalog(orphan);
      expect(diag.hasDiagnostics, isTrue);
    });

    test('18. helpers keep single surfaceCatalog key in toJson; no split keys', () {
      final u = replaceProjectManifestSurfaceCatalog(
        _manifest(),
        _minimalWaterCatalog(),
      );
      final j = u.toJson();
      expect(j.containsKey('surfaceCatalog'), isTrue);
      for (final k in const [
        'surfaceDefinitions',
        'surfaceAtlases',
        'surfaceAnimations',
        'surfacePresets',
        'surfaceCategories',
      ]) {
        expect(j.containsKey(k), isFalse, reason: k);
      }
    });

    test('19. public export via map_core', () {
      expect(
        getProjectManifestSurfaceCatalog(_manifest()),
        isA<ProjectSurfaceCatalog>(),
      );
    });

    test('20. Lot 47 fixtures stay bare JSON without top-level surfaceCatalog', () {
      for (final n in const [
        'empty_surface_catalog_v0.json',
        'minimal_water_surface_catalog_v0.json',
        'full_water_surface_catalog_v0.json',
      ]) {
        final o = _readFixtureJson(n);
        expect(o, isA<Map<String, Object?>>());
        expect(o.containsKey('surfaceCatalog'), isFalse, reason: n);
      }
    });
  });
}

// --- test helpers (Lot 50) ---

ProjectManifest _manifest({
  String name = 'Surface Ops',
  ProjectSurfaceCatalog? surfaceCatalog,
  ProjectSettings? settings,
  ProjectPokemonConfig? pokemon,
}) {
  return ProjectManifest(
    name: name,
    maps: const [],
    tilesets: const [],
    surfaceCatalog: surfaceCatalog ?? ProjectSurfaceCatalog(),
    settings: settings ?? const ProjectSettings(),
    pokemon: pokemon ?? const ProjectPokemonConfig(),
  );
}

ProjectSurfaceCatalog _minimalWaterCatalog() {
  return decodeProjectSurfaceCatalog(
    Map<String, Object?>.from(
      _readFixtureJson('minimal_water_surface_catalog_v0.json'),
    ),
  );
}

ProjectSurfaceCatalog _fullWaterCatalog() {
  return decodeProjectSurfaceCatalog(
    Map<String, Object?>.from(
      _readFixtureJson('full_water_surface_catalog_v0.json'),
    ),
  );
}

/// Catalogue valide à la construction (pas de doublon d’id) mais incohérent
/// pour les diagnostics (animation qui référence un atlas absent de la liste).
ProjectSurfaceCatalog _orphanRefCatalog() {
  final frame = SurfaceAnimationFrame(
    tileRef: SurfaceAtlasTileRef(
      atlasId: 'missing-atlas',
      column: 0,
      row: 0,
    ),
    durationMs: 32,
  );
  final timeline = SurfaceAnimationTimeline(frames: [frame]);
  final anim = ProjectSurfaceAnimation(
    id: 'orphan-anim',
    name: 'Orphan',
    timeline: timeline,
  );
  final refs = SurfaceVariantAnimationRefSet(
    refs: [
      SurfaceVariantAnimationRef(
        role: SurfaceVariantRole.isolated,
        animationId: 'orphan-anim',
      ),
    ],
  );
  return ProjectSurfaceCatalog(
    atlases: const [],
    animations: [anim],
    presets: [
      ProjectSurfacePreset(
        id: 'preset-orphan',
        name: 'P',
        variantAnimations: refs,
      ),
    ],
  );
}

Map<String, Object?> _readFixtureJson(String name) {
  return jsonDecode(
    File('test/fixtures/surface_catalog_json/$name').readAsStringSync(),
  ) as Map<String, Object?>;
}
