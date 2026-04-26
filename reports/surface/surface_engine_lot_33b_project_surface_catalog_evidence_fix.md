# Surface Engine — Lot 33-bis : preuve (evidence fix) `ProjectSurfaceCatalog` V0

## 1. Résumé exécutif

Ce lot **ne modifie aucun code** : il ajoute uniquement ce rapport pour corriger l'exigence de preuve du Lot 33, en intégrant **intégralement** (sources, diffs, sorties de commandes) ce que le rapport Lot 33 renvoyait vers le dépôt.

**Ancre Git pour les diffs (Lot 33) :** commit `9a3ebd9f`.

## 2. Pourquoi le Lot 33-bis existe

Le rapport `surface_engine_lot_33_project_surface_catalog_model.md` (§33–34) renvoyait vers les fichiers et les diffs au lieu de les inscrire, et résumait les sorties de commandes. Le Lot 33-bis supplémente ces preuves **sans** toucher à l'implémentation.

## 3. Fichiers inspectés

- `packages/map_core/lib/src/models/surface_catalog.dart`
- `packages/map_core/test/project_surface_catalog_test.dart`
- `packages/map_core/lib/map_core.dart`
- `reports/surface/surface_engine_lot_33_project_surface_catalog_model.md`
- `packages/map_core/lib/src/models/surface.dart`
- `packages/map_core/lib/src/models/project_manifest.dart`
- (ce fichier) `reports/surface/surface_engine_lot_33b_project_surface_catalog_evidence_fix.md`

## 4. Fichiers modifiés par ce lot

- Aucun fichier Dart ni manifeste : **seule** création de ce rapport Markdown.

## 5. Confirmation : code du Lot 33 non modifié

`sha256` identique entre l'objet Git `9a3ebd9f` et le fichier de l'arbre de travail (`surface_catalog.dart`) :

```text
337240a9f24a1e0f35681be6e5583d9ece1a9b0779ed0c431759042c472c7012  -
337240a9f24a1e0f35681be6e5583d9ece1a9b0779ed0c431759042c472c7012  packages/map_core/lib/src/models/surface_catalog.dart
```

## 6. Confirmation : `ProjectManifest` non modifié (33/33-bis)

Le 33-bis n'édite pas le manifest. Les clés de persistance listées en test 33 (`surfaceDefinitions`, `surfaceAtlases`, `surfaceAnimations`, `surfacePresets`, `surfaceCategories`) ne sont **pas** des champs du modèle `ProjectManifest` à ce stade (audit : absence de ces symboles dans le fichier source `project_manifest.dart`).

## 7. Confirmation : aucun fichier généré (33-bis)

Aucun `build_runner` ; pas de `*.g.dart` / `*.freezed.dart` lié à ce lot.

## 8. Confirmation : aucun `SurfacePresetKind` / `surfaceKind` créé

Non.

## 9. Confirmation : aucun runtime / editor / gameplay / battle modifié

Non — uniquement ce rapport sous `reports/surface/`.

---

## 10. Contenu intégral de `packages/map_core/lib/src/models/surface_catalog.dart`

```dart
import 'package:meta/meta.dart' show immutable;

import '../exceptions/map_exceptions.dart';
import 'surface.dart';

/// Comparaison **ordonnée** de deux listes d’[ProjectSurfaceAtlas] pour
/// [ProjectSurfaceCatalog.operator ==].
bool _projectSurfaceAtlasesEqualInOrder(
  List<ProjectSurfaceAtlas> a,
  List<ProjectSurfaceAtlas> b,
) {
  if (a.length != b.length) {
    return false;
  }
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) {
      return false;
    }
  }
  return true;
}

/// Idem pour [ProjectSurfaceAnimation].
bool _projectSurfaceAnimationsEqualInOrder(
  List<ProjectSurfaceAnimation> a,
  List<ProjectSurfaceAnimation> b,
) {
  if (a.length != b.length) {
    return false;
  }
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) {
      return false;
    }
  }
  return true;
}

/// Idem pour [ProjectSurfacePreset].
bool _projectSurfacePresetsEqualInOrder(
  List<ProjectSurfacePreset> a,
  List<ProjectSurfacePreset> b,
) {
  if (a.length != b.length) {
    return false;
  }
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) {
      return false;
    }
  }
  return true;
}

void _rejectDuplicateIds<T>(
  List<T> items,
  String Function(T) idOf,
  String message,
) {
  final seen = <String>{};
  for (final item in items) {
    if (!seen.add(idOf(item))) {
      throw ValidationException(message);
    }
  }
}

/// Catalogue auteur **Surface** en **mémoire uniquement** : regroupe des
/// [ProjectSurfaceAtlas], [ProjectSurfaceAnimation] et [ProjectSurfacePreset]
/// pour des lookups et de futurs diagnostics — **sans** persistance JSON,
/// **sans** [ProjectManifest], **sans** résolution de références.
///
/// * Les listes sont **copiées** puis exposées en **non modifiables** : une
///   mutation de la source après construction ne change **pas** le catalogue.
/// * Unicité des `id` **au sein de chaque liste** ; les **namespaces** atlas /
///   animation / preset sont **indépendants** en V0 (même chaîne `water` dans
///   les trois collections autorisée — pas de contrainte globale prématurée).
/// * Ne **revalide** pas les modèles embarqués ; ne **résout** pas les
///   `animationId` des presets vers des animations du catalogue.
@immutable
final class ProjectSurfaceCatalog {
  ProjectSurfaceCatalog({
    List<ProjectSurfaceAtlas> atlases = const [],
    List<ProjectSurfaceAnimation> animations = const [],
    List<ProjectSurfacePreset> presets = const [],
  }) {
    final atl = List<ProjectSurfaceAtlas>.from(atlases);
    final anim = List<ProjectSurfaceAnimation>.from(animations);
    final pre = List<ProjectSurfacePreset>.from(presets);

    _rejectDuplicateIds<ProjectSurfaceAtlas>(
      atl,
      (a) => a.id,
      'ProjectSurfaceCatalog.atlases must not contain duplicate ProjectSurfaceAtlas.id',
    );
    _rejectDuplicateIds<ProjectSurfaceAnimation>(
      anim,
      (a) => a.id,
      'ProjectSurfaceCatalog.animations must not contain duplicate ProjectSurfaceAnimation.id',
    );
    _rejectDuplicateIds<ProjectSurfacePreset>(
      pre,
      (a) => a.id,
      'ProjectSurfaceCatalog.presets must not contain duplicate ProjectSurfacePreset.id',
    );

    _atlases = List<ProjectSurfaceAtlas>.unmodifiable(atl);
    _animations = List<ProjectSurfaceAnimation>.unmodifiable(anim);
    _presets = List<ProjectSurfacePreset>.unmodifiable(pre);
  }

  late final List<ProjectSurfaceAtlas> _atlases;
  late final List<ProjectSurfaceAnimation> _animations;
  late final List<ProjectSurfacePreset> _presets;

  /// Atlasses (ordre d’insertion, liste **non modifiable**).
  List<ProjectSurfaceAtlas> get atlases => _atlases;

  /// Animations (ordre d’insertion, liste **non modifiable**).
  List<ProjectSurfaceAnimation> get animations => _animations;

  /// Presets (ordre d’insertion, liste **non modifiable**).
  List<ProjectSurfacePreset> get presets => _presets;

  int get atlasCount => _atlases.length;

  int get animationCount => _animations.length;

  int get presetCount => _presets.length;

  /// Vrai si **les trois** listes sont vides (modèle valide hors manifest).
  bool get isEmpty =>
      _atlases.isEmpty && _animations.isEmpty && _presets.isEmpty;

  /// Inverse de [isEmpty].
  bool get isNotEmpty => !isEmpty;

  /// [ProjectSurfaceAtlas] dont [ProjectSurfaceAtlas.id] est **égale** à [id]
  /// (comparaison de chaînes, **pas** de [trim]).
  ProjectSurfaceAtlas? atlasById(String id) {
    for (final a in _atlases) {
      if (a.id == id) {
        return a;
      }
    }
    return null;
  }

  /// Idem [atlasById] pour [ProjectSurfaceAnimation.id].
  ProjectSurfaceAnimation? animationById(String id) {
    for (final a in _animations) {
      if (a.id == id) {
        return a;
      }
    }
    return null;
  }

  /// Idem [atlasById] pour [ProjectSurfacePreset.id].
  ProjectSurfacePreset? presetById(String id) {
    for (final p in _presets) {
      if (p.id == id) {
        return p;
      }
    }
    return null;
  }

  /// Délègue : [atlasById] `!= null`.
  bool containsAtlas(String id) => atlasById(id) != null;

  /// Délègue : [animationById] `!= null`.
  bool containsAnimation(String id) => animationById(id) != null;

  /// Délègue : [presetById] `!= null`.
  bool containsPreset(String id) => presetById(id) != null;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProjectSurfaceCatalog &&
          _projectSurfaceAtlasesEqualInOrder(_atlases, other._atlases) &&
          _projectSurfaceAnimationsEqualInOrder(_animations, other._animations) &&
          _projectSurfacePresetsEqualInOrder(_presets, other._presets);

  @override
  int get hashCode => Object.hash(
        Object.hashAll(_atlases),
        Object.hashAll(_animations),
        Object.hashAll(_presets),
      );
}
```

## 11. Contenu intégral de `packages/map_core/test/project_surface_catalog_test.dart`

```dart
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

SurfaceAtlasGeometry _geometry() {
  return SurfaceAtlasGeometry(
    tileSize: SurfaceAtlasTileSize(width: 32, height: 32),
    gridSize: SurfaceAtlasGridSize(columns: 2, rows: 2),
    layout: SurfaceAtlasLayout.columnsAreVariantsRowsAreFrames,
  );
}

ProjectSurfaceAtlas _atlas(String id) {
  return ProjectSurfaceAtlas(
    id: id,
    name: 'name-$id',
    tilesetId: 'ts',
    geometry: _geometry(),
  );
}

SurfaceAnimationTimeline _timeline() {
  return SurfaceAnimationTimeline(
    frames: [
      SurfaceAnimationFrame(
        tileRef: SurfaceAtlasTileRef(
          atlasId: 'a',
          column: 0,
          row: 0,
        ),
        durationMs: 1,
      ),
    ],
  );
}

ProjectSurfaceAnimation _animation(String id) {
  return ProjectSurfaceAnimation(
    id: id,
    name: 'anim-$id',
    timeline: _timeline(),
  );
}

SurfaceVariantAnimationRefSet _variantSet() {
  return SurfaceVariantAnimationRefSet(
    refs: [
      SurfaceVariantAnimationRef(
        role: SurfaceVariantRole.isolated,
        animationId: 'anim-1',
      ),
    ],
  );
}

ProjectSurfacePreset _preset(String id) {
  return ProjectSurfacePreset(
    id: id,
    name: 'preset-$id',
    variantAnimations: _variantSet(),
  );
}

void main() {
  group('ProjectSurfaceCatalog (Lot 33)', () {
    test('1. empty catalog: counts, isEmpty, unmodifiable empty lists', () {
      final catalog = ProjectSurfaceCatalog();
      expect(catalog.atlasCount, 0);
      expect(catalog.animationCount, 0);
      expect(catalog.presetCount, 0);
      expect(catalog.isEmpty, isTrue);
      expect(catalog.isNotEmpty, isFalse);
      expect(catalog.atlases, isEmpty);
      expect(catalog.animations, isEmpty);
      expect(catalog.presets, isEmpty);
    });

    test('2. catalog with 2 of each kind: counts, isNotEmpty', () {
      final catalog = ProjectSurfaceCatalog(
        atlases: [_atlas('a1'), _atlas('a2')],
        animations: [_animation('m1'), _animation('m2')],
        presets: [_preset('p1'), _preset('p2')],
      );
      expect(catalog.atlasCount, 2);
      expect(catalog.animationCount, 2);
      expect(catalog.presetCount, 2);
      expect(catalog.isEmpty, isFalse);
      expect(catalog.isNotEmpty, isTrue);
    });

    test('3. order of atlases preserved', () {
      final catalog = ProjectSurfaceCatalog(
        atlases: [
          _atlas('o1'),
          _atlas('o2'),
          _atlas('o3'),
        ],
      );
      expect(
        catalog.atlases.map((e) => e.id).toList(),
        ['o1', 'o2', 'o3'],
      );
    });

    test('4. order of animations preserved', () {
      final catalog = ProjectSurfaceCatalog(
        animations: [
          _animation('o1'),
          _animation('o2'),
          _animation('o3'),
        ],
      );
      expect(
        catalog.animations.map((e) => e.id).toList(),
        ['o1', 'o2', 'o3'],
      );
    });

    test('5. order of presets preserved', () {
      final catalog = ProjectSurfaceCatalog(
        presets: [
          _preset('o1'),
          _preset('o2'),
          _preset('o3'),
        ],
      );
      expect(
        catalog.presets.map((e) => e.id).toList(),
        ['o1', 'o2', 'o3'],
      );
    });

    test('6. exposed lists are unmodifiable: add throws', () {
      final catalog = ProjectSurfaceCatalog();
      expect(
        () => catalog.atlases.add(_atlas('x')),
        throwsA(isA<UnsupportedError>()),
      );
      expect(
        () => catalog.animations.add(_animation('x')),
        throwsA(isA<UnsupportedError>()),
      );
      expect(
        () => catalog.presets.add(_preset('x')),
        throwsA(isA<UnsupportedError>()),
      );
    });

    test('7. defensive copy: atlases source mutated after build', () {
      final source = <ProjectSurfaceAtlas>[_atlas('only')];
      final catalog = ProjectSurfaceCatalog(atlases: source);
      source.add(_atlas('extra'));
      expect(catalog.atlasCount, 1);
      expect(catalog.atlases.map((e) => e.id), ['only']);
    });

    test('8. defensive copy: animations source mutated after build', () {
      final source = <ProjectSurfaceAnimation>[_animation('only')];
      final catalog = ProjectSurfaceCatalog(animations: source);
      source.add(_animation('extra'));
      expect(catalog.animationCount, 1);
      expect(catalog.animations.map((e) => e.id), ['only']);
    });

    test('9. defensive copy: presets source mutated after build', () {
      final source = <ProjectSurfacePreset>[_preset('only')];
      final catalog = ProjectSurfaceCatalog(presets: source);
      source.add(_preset('extra'));
      expect(catalog.presetCount, 1);
      expect(catalog.presets.map((e) => e.id), ['only']);
    });

    test('10. duplicate atlas id throws ValidationException', () {
      expect(
        () => ProjectSurfaceCatalog(
          atlases: [
            _atlas('dup'),
            _atlas('dup'),
          ],
        ),
        throwsA(isA<ValidationException>()),
      );
    });

    test('11. duplicate animation id throws ValidationException', () {
      expect(
        () => ProjectSurfaceCatalog(
          animations: [
            _animation('dup'),
            _animation('dup'),
          ],
        ),
        throwsA(isA<ValidationException>()),
      );
    });

    test('12. duplicate preset id throws ValidationException', () {
      expect(
        () => ProjectSurfaceCatalog(
          presets: [
            _preset('dup'),
            _preset('dup'),
          ],
        ),
        throwsA(isA<ValidationException>()),
      );
    });

    test('13. same id string across collections is allowed; lookups', () {
      const shared = 'water';
      final a = _atlas(shared);
      final m = _animation(shared);
      final p = _preset(shared);
      final catalog = ProjectSurfaceCatalog(
        atlases: [a],
        animations: [m],
        presets: [p],
      );
      expect(catalog.atlasById(shared), same(a));
      expect(catalog.animationById(shared), same(m));
      expect(catalog.presetById(shared), same(p));
    });

    test('14. atlasById returns instance when present', () {
      final a = _atlas('known');
      final c = ProjectSurfaceCatalog(atlases: [a]);
      expect(c.atlasById('known'), same(a));
    });

    test('15. atlasById null when absent', () {
      final c = ProjectSurfaceCatalog(atlases: [_atlas('a')]);
      expect(c.atlasById('missing'), isNull);
    });

    test('16. animationById returns instance when present', () {
      final m = _animation('known');
      final c = ProjectSurfaceCatalog(animations: [m]);
      expect(c.animationById('known'), same(m));
    });

    test('17. animationById null when absent', () {
      final c = ProjectSurfaceCatalog(animations: [_animation('a')]);
      expect(c.animationById('missing'), isNull);
    });

    test('18. presetById returns instance when present', () {
      final p = _preset('known');
      final c = ProjectSurfaceCatalog(presets: [p]);
      expect(c.presetById('known'), same(p));
    });

    test('19. presetById null when absent', () {
      final c = ProjectSurfaceCatalog(presets: [_preset('a')]);
      expect(c.presetById('missing'), isNull);
    });

    test('20. containsAtlas delegates to lookup', () {
      final c = ProjectSurfaceCatalog(atlases: [_atlas('x')]);
      expect(c.containsAtlas('x'), isTrue);
      expect(c.containsAtlas('y'), isFalse);
    });

    test('21. containsAnimation delegates to lookup', () {
      final c = ProjectSurfaceCatalog(animations: [_animation('x')]);
      expect(c.containsAnimation('x'), isTrue);
      expect(c.containsAnimation('y'), isFalse);
    });

    test('22. containsPreset delegates to lookup', () {
      final c = ProjectSurfaceCatalog(presets: [_preset('x')]);
      expect(c.containsPreset('x'), isTrue);
      expect(c.containsPreset('y'), isFalse);
    });

    test('23. lookups use exact id string (no trim) — atlas', () {
      const spaced = '  water  ';
      final atlas = ProjectSurfaceAtlas(
        id: spaced,
        name: 'N',
        tilesetId: 't',
        geometry: _geometry(),
      );
      final c = ProjectSurfaceCatalog(atlases: [atlas]);
      expect(c.atlasById(spaced), same(atlas));
      expect(c.atlasById('water'), isNull);
    });

    test('24. does not resolve missing animationId on preset; no error', () {
      final preset = ProjectSurfacePreset(
        id: 'orphan-preset',
        name: 'O',
        variantAnimations: SurfaceVariantAnimationRefSet(
          refs: [
            SurfaceVariantAnimationRef(
              role: SurfaceVariantRole.isolated,
              animationId: 'missing-animation',
            ),
          ],
        ),
      );
      final catalog = ProjectSurfaceCatalog(presets: [preset]);
      expect(
        () => catalog.presetById('orphan-preset'),
        returnsNormally,
      );
      expect(catalog.presetById('orphan-preset'), same(preset));
      expect(
        catalog.animationById('missing-animation'),
        isNull,
      );
    });

    test('25. value equality: same content same order: == and hashCode', () {
      final a1 = _atlas('a1');
      final a2 = _atlas('a2');
      final m1 = _animation('m1');
      final p1 = _preset('p1');
      final c1 = ProjectSurfaceCatalog(
        atlases: [a1, a2],
        animations: [m1],
        presets: [p1],
      );
      final c2 = ProjectSurfaceCatalog(
        atlases: [a1, a2],
        animations: [m1],
        presets: [p1],
      );
      expect(c1, c2);
      expect(c1.hashCode, c2.hashCode);
    });

    test('26. value inequality: different atlas order', () {
      final x = _atlas('x');
      final y = _atlas('y');
      final c1 = ProjectSurfaceCatalog(atlases: [x, y]);
      final c2 = ProjectSurfaceCatalog(atlases: [y, x]);
      expect(c1, isNot(c2));
    });

    test('27. value inequality: different animation order', () {
      final x = _animation('x');
      final y = _animation('y');
      final c1 = ProjectSurfaceCatalog(animations: [x, y]);
      final c2 = ProjectSurfaceCatalog(animations: [y, x]);
      expect(c1, isNot(c2));
    });

    test('28. value inequality: different preset order', () {
      final x = _preset('x');
      final y = _preset('y');
      final c1 = ProjectSurfaceCatalog(presets: [x, y]);
      final c2 = ProjectSurfaceCatalog(presets: [y, x]);
      expect(c1, isNot(c2));
    });

    test('29. value inequality: different content', () {
      final c1 = ProjectSurfaceCatalog(atlases: [_atlas('a')]);
      final c2 = ProjectSurfaceCatalog(atlases: [_atlas('b')]);
      expect(c1, isNot(c2));
    });

    test('30. public surface export: ProjectSurfaceCatalog from map_core', () {
      final catalog = ProjectSurfaceCatalog();
      expect(catalog, isA<ProjectSurfaceCatalog>());
    });

    test('31. ProjectManifest still has no Surface persistence keys (Lot 33)', () {
      const manifest = ProjectManifest(
        name: 'L33',
        maps: [
          ProjectMapEntry(
            id: 'm1',
            name: 'Map',
            relativePath: 'maps/m1.json',
          ),
        ],
        tilesets: [],
      );
      final map = manifest.toJson();
      const forbidden = <String>[
        'surfaceDefinitions',
        'surfaceAtlases',
        'surfaceAnimations',
        'surfacePresets',
        'surfaceCategories',
      ];
      for (final k in forbidden) {
        expect(map.containsKey(k), isFalse, reason: 'forbidden: $k');
      }
    });
  });
}
```

## 12. Extrait pertinent de `packages/map_core/lib/map_core.dart` (exports `surface` / `surface_catalog`)

```dart
export 'src/models/script_asset.dart';
export 'src/models/script_conditions.dart';
export 'src/models/map_event_definition.dart';
export 'src/models/project_trainer.dart';
export 'src/models/scenario_asset.dart';
export 'src/models/visual_frame_json.dart';
export 'src/models/surface.dart';
export 'src/models/surface_catalog.dart';
export 'src/operations/map_resize.dart';
export 'src/operations/map_paint.dart';
export 'src/operations/map_collision.dart';
export 'src/operations/map_path.dart';
export 'src/operations/map_terrain.dart';
export 'src/operations/map_terrain_autotile.dart';
```

## 13. Diff complet réel — `map_core.dart` (commit `9a3ebd9f`)

```diff
commit 9a3ebd9fd8c295679a229d3faf2c236a1e135dea
Author: yoahn <yoahn.linard@papernest.com>
Date:   Mon Apr 27 00:19:12 2026 +0200

    feat(map_core): ProjectSurfaceCatalog (Surface Engine lot 33)
    
    In-memory author catalog for ProjectSurfaceAtlas, ProjectSurfaceAnimation,
    ProjectSurfacePreset: defensive list copies, per-collection id uniqueness,
    lookups, value equality. No ProjectManifest, no JSON/Freezed.
    
    Includes tests and surface_engine_lot_33 report.
    
    Made-with: Cursor

diff --git a/packages/map_core/lib/map_core.dart b/packages/map_core/lib/map_core.dart
index 1c39cf24..355d2918 100644
--- a/packages/map_core/lib/map_core.dart
+++ b/packages/map_core/lib/map_core.dart
@@ -23,6 +23,7 @@ export 'src/models/project_trainer.dart';
 export 'src/models/scenario_asset.dart';
 export 'src/models/visual_frame_json.dart';
 export 'src/models/surface.dart';
+export 'src/models/surface_catalog.dart';
 export 'src/operations/map_resize.dart';
 export 'src/operations/map_paint.dart';
 export 'src/operations/map_collision.dart';
```

## 14. Diff `/dev/null` — `surface_catalog.dart` (commit `9a3ebd9f`)

```diff
commit 9a3ebd9fd8c295679a229d3faf2c236a1e135dea
Author: yoahn <yoahn.linard@papernest.com>
Date:   Mon Apr 27 00:19:12 2026 +0200

    feat(map_core): ProjectSurfaceCatalog (Surface Engine lot 33)
    
    In-memory author catalog for ProjectSurfaceAtlas, ProjectSurfaceAnimation,
    ProjectSurfacePreset: defensive list copies, per-collection id uniqueness,
    lookups, value equality. No ProjectManifest, no JSON/Freezed.
    
    Includes tests and surface_engine_lot_33 report.
    
    Made-with: Cursor

diff --git a/packages/map_core/lib/src/models/surface_catalog.dart b/packages/map_core/lib/src/models/surface_catalog.dart
new file mode 100644
index 00000000..2fe2db11
--- /dev/null
+++ b/packages/map_core/lib/src/models/surface_catalog.dart
@@ -0,0 +1,192 @@
+import 'package:meta/meta.dart' show immutable;
+
+import '../exceptions/map_exceptions.dart';
+import 'surface.dart';
+
+/// Comparaison **ordonnée** de deux listes d’[ProjectSurfaceAtlas] pour
+/// [ProjectSurfaceCatalog.operator ==].
+bool _projectSurfaceAtlasesEqualInOrder(
+  List<ProjectSurfaceAtlas> a,
+  List<ProjectSurfaceAtlas> b,
+) {
+  if (a.length != b.length) {
+    return false;
+  }
+  for (var i = 0; i < a.length; i++) {
+    if (a[i] != b[i]) {
+      return false;
+    }
+  }
+  return true;
+}
+
+/// Idem pour [ProjectSurfaceAnimation].
+bool _projectSurfaceAnimationsEqualInOrder(
+  List<ProjectSurfaceAnimation> a,
+  List<ProjectSurfaceAnimation> b,
+) {
+  if (a.length != b.length) {
+    return false;
+  }
+  for (var i = 0; i < a.length; i++) {
+    if (a[i] != b[i]) {
+      return false;
+    }
+  }
+  return true;
+}
+
+/// Idem pour [ProjectSurfacePreset].
+bool _projectSurfacePresetsEqualInOrder(
+  List<ProjectSurfacePreset> a,
+  List<ProjectSurfacePreset> b,
+) {
+  if (a.length != b.length) {
+    return false;
+  }
+  for (var i = 0; i < a.length; i++) {
+    if (a[i] != b[i]) {
+      return false;
+    }
+  }
+  return true;
+}
+
+void _rejectDuplicateIds<T>(
+  List<T> items,
+  String Function(T) idOf,
+  String message,
+) {
+  final seen = <String>{};
+  for (final item in items) {
+    if (!seen.add(idOf(item))) {
+      throw ValidationException(message);
+    }
+  }
+}
+
+/// Catalogue auteur **Surface** en **mémoire uniquement** : regroupe des
+/// [ProjectSurfaceAtlas], [ProjectSurfaceAnimation] et [ProjectSurfacePreset]
+/// pour des lookups et de futurs diagnostics — **sans** persistance JSON,
+/// **sans** [ProjectManifest], **sans** résolution de références.
+///
+/// * Les listes sont **copiées** puis exposées en **non modifiables** : une
+///   mutation de la source après construction ne change **pas** le catalogue.
+/// * Unicité des `id` **au sein de chaque liste** ; les **namespaces** atlas /
+///   animation / preset sont **indépendants** en V0 (même chaîne `water` dans
+///   les trois collections autorisée — pas de contrainte globale prématurée).
+/// * Ne **revalide** pas les modèles embarqués ; ne **résout** pas les
+///   `animationId` des presets vers des animations du catalogue.
+@immutable
+final class ProjectSurfaceCatalog {
+  ProjectSurfaceCatalog({
+    List<ProjectSurfaceAtlas> atlases = const [],
+    List<ProjectSurfaceAnimation> animations = const [],
+    List<ProjectSurfacePreset> presets = const [],
+  }) {
+    final atl = List<ProjectSurfaceAtlas>.from(atlases);
+    final anim = List<ProjectSurfaceAnimation>.from(animations);
+    final pre = List<ProjectSurfacePreset>.from(presets);
+
+    _rejectDuplicateIds<ProjectSurfaceAtlas>(
+      atl,
+      (a) => a.id,
+      'ProjectSurfaceCatalog.atlases must not contain duplicate ProjectSurfaceAtlas.id',
+    );
+    _rejectDuplicateIds<ProjectSurfaceAnimation>(
+      anim,
+      (a) => a.id,
+      'ProjectSurfaceCatalog.animations must not contain duplicate ProjectSurfaceAnimation.id',
+    );
+    _rejectDuplicateIds<ProjectSurfacePreset>(
+      pre,
+      (a) => a.id,
+      'ProjectSurfaceCatalog.presets must not contain duplicate ProjectSurfacePreset.id',
+    );
+
+    _atlases = List<ProjectSurfaceAtlas>.unmodifiable(atl);
+    _animations = List<ProjectSurfaceAnimation>.unmodifiable(anim);
+    _presets = List<ProjectSurfacePreset>.unmodifiable(pre);
+  }
+
+  late final List<ProjectSurfaceAtlas> _atlases;
+  late final List<ProjectSurfaceAnimation> _animations;
+  late final List<ProjectSurfacePreset> _presets;
+
+  /// Atlasses (ordre d’insertion, liste **non modifiable**).
+  List<ProjectSurfaceAtlas> get atlases => _atlases;
+
+  /// Animations (ordre d’insertion, liste **non modifiable**).
+  List<ProjectSurfaceAnimation> get animations => _animations;
+
+  /// Presets (ordre d’insertion, liste **non modifiable**).
+  List<ProjectSurfacePreset> get presets => _presets;
+
+  int get atlasCount => _atlases.length;
+
+  int get animationCount => _animations.length;
+
+  int get presetCount => _presets.length;
+
+  /// Vrai si **les trois** listes sont vides (modèle valide hors manifest).
+  bool get isEmpty =>
+      _atlases.isEmpty && _animations.isEmpty && _presets.isEmpty;
+
+  /// Inverse de [isEmpty].
+  bool get isNotEmpty => !isEmpty;
+
+  /// [ProjectSurfaceAtlas] dont [ProjectSurfaceAtlas.id] est **égale** à [id]
+  /// (comparaison de chaînes, **pas** de [trim]).
+  ProjectSurfaceAtlas? atlasById(String id) {
+    for (final a in _atlases) {
+      if (a.id == id) {
+        return a;
+      }
+    }
+    return null;
+  }
+
+  /// Idem [atlasById] pour [ProjectSurfaceAnimation.id].
+  ProjectSurfaceAnimation? animationById(String id) {
+    for (final a in _animations) {
+      if (a.id == id) {
+        return a;
+      }
+    }
+    return null;
+  }
+
+  /// Idem [atlasById] pour [ProjectSurfacePreset.id].
+  ProjectSurfacePreset? presetById(String id) {
+    for (final p in _presets) {
+      if (p.id == id) {
+        return p;
+      }
+    }
+    return null;
+  }
+
+  /// Délègue : [atlasById] `!= null`.
+  bool containsAtlas(String id) => atlasById(id) != null;
+
+  /// Délègue : [animationById] `!= null`.
+  bool containsAnimation(String id) => animationById(id) != null;
+
+  /// Délègue : [presetById] `!= null`.
+  bool containsPreset(String id) => presetById(id) != null;
+
+  @override
+  bool operator ==(Object other) =>
+      identical(this, other) ||
+      other is ProjectSurfaceCatalog &&
+          _projectSurfaceAtlasesEqualInOrder(_atlases, other._atlases) &&
+          _projectSurfaceAnimationsEqualInOrder(_animations, other._animations) &&
+          _projectSurfacePresetsEqualInOrder(_presets, other._presets);
+
+  @override
+  int get hashCode => Object.hash(
+        Object.hashAll(_atlases),
+        Object.hashAll(_animations),
+        Object.hashAll(_presets),
+      );
+}
```

## 15. Diff `/dev/null` — `project_surface_catalog_test.dart` (commit `9a3ebd9f`)

```diff
commit 9a3ebd9fd8c295679a229d3faf2c236a1e135dea
Author: yoahn <yoahn.linard@papernest.com>
Date:   Mon Apr 27 00:19:12 2026 +0200

    feat(map_core): ProjectSurfaceCatalog (Surface Engine lot 33)
    
    In-memory author catalog for ProjectSurfaceAtlas, ProjectSurfaceAnimation,
    ProjectSurfacePreset: defensive list copies, per-collection id uniqueness,
    lookups, value equality. No ProjectManifest, no JSON/Freezed.
    
    Includes tests and surface_engine_lot_33 report.
    
    Made-with: Cursor

diff --git a/packages/map_core/test/project_surface_catalog_test.dart b/packages/map_core/test/project_surface_catalog_test.dart
new file mode 100644
index 00000000..c7b35d53
--- /dev/null
+++ b/packages/map_core/test/project_surface_catalog_test.dart
@@ -0,0 +1,391 @@
+import 'package:map_core/map_core.dart';
+import 'package:test/test.dart';
+
+SurfaceAtlasGeometry _geometry() {
+  return SurfaceAtlasGeometry(
+    tileSize: SurfaceAtlasTileSize(width: 32, height: 32),
+    gridSize: SurfaceAtlasGridSize(columns: 2, rows: 2),
+    layout: SurfaceAtlasLayout.columnsAreVariantsRowsAreFrames,
+  );
+}
+
+ProjectSurfaceAtlas _atlas(String id) {
+  return ProjectSurfaceAtlas(
+    id: id,
+    name: 'name-$id',
+    tilesetId: 'ts',
+    geometry: _geometry(),
+  );
+}
+
+SurfaceAnimationTimeline _timeline() {
+  return SurfaceAnimationTimeline(
+    frames: [
+      SurfaceAnimationFrame(
+        tileRef: SurfaceAtlasTileRef(
+          atlasId: 'a',
+          column: 0,
+          row: 0,
+        ),
+        durationMs: 1,
+      ),
+    ],
+  );
+}
+
+ProjectSurfaceAnimation _animation(String id) {
+  return ProjectSurfaceAnimation(
+    id: id,
+    name: 'anim-$id',
+    timeline: _timeline(),
+  );
+}
+
+SurfaceVariantAnimationRefSet _variantSet() {
+  return SurfaceVariantAnimationRefSet(
+    refs: [
+      SurfaceVariantAnimationRef(
+        role: SurfaceVariantRole.isolated,
+        animationId: 'anim-1',
+      ),
+    ],
+  );
+}
+
+ProjectSurfacePreset _preset(String id) {
+  return ProjectSurfacePreset(
+    id: id,
+    name: 'preset-$id',
+    variantAnimations: _variantSet(),
+  );
+}
+
+void main() {
+  group('ProjectSurfaceCatalog (Lot 33)', () {
+    test('1. empty catalog: counts, isEmpty, unmodifiable empty lists', () {
+      final catalog = ProjectSurfaceCatalog();
+      expect(catalog.atlasCount, 0);
+      expect(catalog.animationCount, 0);
+      expect(catalog.presetCount, 0);
+      expect(catalog.isEmpty, isTrue);
+      expect(catalog.isNotEmpty, isFalse);
+      expect(catalog.atlases, isEmpty);
+      expect(catalog.animations, isEmpty);
+      expect(catalog.presets, isEmpty);
+    });
+
+    test('2. catalog with 2 of each kind: counts, isNotEmpty', () {
+      final catalog = ProjectSurfaceCatalog(
+        atlases: [_atlas('a1'), _atlas('a2')],
+        animations: [_animation('m1'), _animation('m2')],
+        presets: [_preset('p1'), _preset('p2')],
+      );
+      expect(catalog.atlasCount, 2);
+      expect(catalog.animationCount, 2);
+      expect(catalog.presetCount, 2);
+      expect(catalog.isEmpty, isFalse);
+      expect(catalog.isNotEmpty, isTrue);
+    });
+
+    test('3. order of atlases preserved', () {
+      final catalog = ProjectSurfaceCatalog(
+        atlases: [
+          _atlas('o1'),
+          _atlas('o2'),
+          _atlas('o3'),
+        ],
+      );
+      expect(
+        catalog.atlases.map((e) => e.id).toList(),
+        ['o1', 'o2', 'o3'],
+      );
+    });
+
+    test('4. order of animations preserved', () {
+      final catalog = ProjectSurfaceCatalog(
+        animations: [
+          _animation('o1'),
+          _animation('o2'),
+          _animation('o3'),
+        ],
+      );
+      expect(
+        catalog.animations.map((e) => e.id).toList(),
+        ['o1', 'o2', 'o3'],
+      );
+    });
+
+    test('5. order of presets preserved', () {
+      final catalog = ProjectSurfaceCatalog(
+        presets: [
+          _preset('o1'),
+          _preset('o2'),
+          _preset('o3'),
+        ],
+      );
+      expect(
+        catalog.presets.map((e) => e.id).toList(),
+        ['o1', 'o2', 'o3'],
+      );
+    });
+
+    test('6. exposed lists are unmodifiable: add throws', () {
+      final catalog = ProjectSurfaceCatalog();
+      expect(
+        () => catalog.atlases.add(_atlas('x')),
+        throwsA(isA<UnsupportedError>()),
+      );
+      expect(
+        () => catalog.animations.add(_animation('x')),
+        throwsA(isA<UnsupportedError>()),
+      );
+      expect(
+        () => catalog.presets.add(_preset('x')),
+        throwsA(isA<UnsupportedError>()),
+      );
+    });
+
+    test('7. defensive copy: atlases source mutated after build', () {
+      final source = <ProjectSurfaceAtlas>[_atlas('only')];
+      final catalog = ProjectSurfaceCatalog(atlases: source);
+      source.add(_atlas('extra'));
+      expect(catalog.atlasCount, 1);
+      expect(catalog.atlases.map((e) => e.id), ['only']);
+    });
+
+    test('8. defensive copy: animations source mutated after build', () {
+      final source = <ProjectSurfaceAnimation>[_animation('only')];
+      final catalog = ProjectSurfaceCatalog(animations: source);
+      source.add(_animation('extra'));
+      expect(catalog.animationCount, 1);
+      expect(catalog.animations.map((e) => e.id), ['only']);
+    });
+
+    test('9. defensive copy: presets source mutated after build', () {
+      final source = <ProjectSurfacePreset>[_preset('only')];
+      final catalog = ProjectSurfaceCatalog(presets: source);
+      source.add(_preset('extra'));
+      expect(catalog.presetCount, 1);
+      expect(catalog.presets.map((e) => e.id), ['only']);
+    });
+
+    test('10. duplicate atlas id throws ValidationException', () {
+      expect(
+        () => ProjectSurfaceCatalog(
+          atlases: [
+            _atlas('dup'),
+            _atlas('dup'),
+          ],
+        ),
+        throwsA(isA<ValidationException>()),
+      );
+    });
+
+    test('11. duplicate animation id throws ValidationException', () {
+      expect(
+        () => ProjectSurfaceCatalog(
+          animations: [
+            _animation('dup'),
+            _animation('dup'),
+          ],
+        ),
+        throwsA(isA<ValidationException>()),
+      );
+    });
+
+    test('12. duplicate preset id throws ValidationException', () {
+      expect(
+        () => ProjectSurfaceCatalog(
+          presets: [
+            _preset('dup'),
+            _preset('dup'),
+          ],
+        ),
+        throwsA(isA<ValidationException>()),
+      );
+    });
+
+    test('13. same id string across collections is allowed; lookups', () {
+      const shared = 'water';
+      final a = _atlas(shared);
+      final m = _animation(shared);
+      final p = _preset(shared);
+      final catalog = ProjectSurfaceCatalog(
+        atlases: [a],
+        animations: [m],
+        presets: [p],
+      );
+      expect(catalog.atlasById(shared), same(a));
+      expect(catalog.animationById(shared), same(m));
+      expect(catalog.presetById(shared), same(p));
+    });
+
+    test('14. atlasById returns instance when present', () {
+      final a = _atlas('known');
+      final c = ProjectSurfaceCatalog(atlases: [a]);
+      expect(c.atlasById('known'), same(a));
+    });
+
+    test('15. atlasById null when absent', () {
+      final c = ProjectSurfaceCatalog(atlases: [_atlas('a')]);
+      expect(c.atlasById('missing'), isNull);
+    });
+
+    test('16. animationById returns instance when present', () {
+      final m = _animation('known');
+      final c = ProjectSurfaceCatalog(animations: [m]);
+      expect(c.animationById('known'), same(m));
+    });
+
+    test('17. animationById null when absent', () {
+      final c = ProjectSurfaceCatalog(animations: [_animation('a')]);
+      expect(c.animationById('missing'), isNull);
+    });
+
+    test('18. presetById returns instance when present', () {
+      final p = _preset('known');
+      final c = ProjectSurfaceCatalog(presets: [p]);
+      expect(c.presetById('known'), same(p));
+    });
+
+    test('19. presetById null when absent', () {
+      final c = ProjectSurfaceCatalog(presets: [_preset('a')]);
+      expect(c.presetById('missing'), isNull);
+    });
+
+    test('20. containsAtlas delegates to lookup', () {
+      final c = ProjectSurfaceCatalog(atlases: [_atlas('x')]);
+      expect(c.containsAtlas('x'), isTrue);
+      expect(c.containsAtlas('y'), isFalse);
+    });
+
+    test('21. containsAnimation delegates to lookup', () {
+      final c = ProjectSurfaceCatalog(animations: [_animation('x')]);
+      expect(c.containsAnimation('x'), isTrue);
+      expect(c.containsAnimation('y'), isFalse);
+    });
+
+    test('22. containsPreset delegates to lookup', () {
+      final c = ProjectSurfaceCatalog(presets: [_preset('x')]);
+      expect(c.containsPreset('x'), isTrue);
+      expect(c.containsPreset('y'), isFalse);
+    });
+
+    test('23. lookups use exact id string (no trim) — atlas', () {
+      const spaced = '  water  ';
+      final atlas = ProjectSurfaceAtlas(
+        id: spaced,
+        name: 'N',
+        tilesetId: 't',
+        geometry: _geometry(),
+      );
+      final c = ProjectSurfaceCatalog(atlases: [atlas]);
+      expect(c.atlasById(spaced), same(atlas));
+      expect(c.atlasById('water'), isNull);
+    });
+
+    test('24. does not resolve missing animationId on preset; no error', () {
+      final preset = ProjectSurfacePreset(
+        id: 'orphan-preset',
+        name: 'O',
+        variantAnimations: SurfaceVariantAnimationRefSet(
+          refs: [
+            SurfaceVariantAnimationRef(
+              role: SurfaceVariantRole.isolated,
+              animationId: 'missing-animation',
+            ),
+          ],
+        ),
+      );
+      final catalog = ProjectSurfaceCatalog(presets: [preset]);
+      expect(
+        () => catalog.presetById('orphan-preset'),
+        returnsNormally,
+      );
+      expect(catalog.presetById('orphan-preset'), same(preset));
+      expect(
+        catalog.animationById('missing-animation'),
+        isNull,
+      );
+    });
+
+    test('25. value equality: same content same order: == and hashCode', () {
+      final a1 = _atlas('a1');
+      final a2 = _atlas('a2');
+      final m1 = _animation('m1');
+      final p1 = _preset('p1');
+      final c1 = ProjectSurfaceCatalog(
+        atlases: [a1, a2],
+        animations: [m1],
+        presets: [p1],
+      );
+      final c2 = ProjectSurfaceCatalog(
+        atlases: [a1, a2],
+        animations: [m1],
+        presets: [p1],
+      );
+      expect(c1, c2);
+      expect(c1.hashCode, c2.hashCode);
+    });
+
+    test('26. value inequality: different atlas order', () {
+      final x = _atlas('x');
+      final y = _atlas('y');
+      final c1 = ProjectSurfaceCatalog(atlases: [x, y]);
+      final c2 = ProjectSurfaceCatalog(atlases: [y, x]);
+      expect(c1, isNot(c2));
+    });
+
+    test('27. value inequality: different animation order', () {
+      final x = _animation('x');
+      final y = _animation('y');
+      final c1 = ProjectSurfaceCatalog(animations: [x, y]);
+      final c2 = ProjectSurfaceCatalog(animations: [y, x]);
+      expect(c1, isNot(c2));
+    });
+
+    test('28. value inequality: different preset order', () {
+      final x = _preset('x');
+      final y = _preset('y');
+      final c1 = ProjectSurfaceCatalog(presets: [x, y]);
+      final c2 = ProjectSurfaceCatalog(presets: [y, x]);
+      expect(c1, isNot(c2));
+    });
+
+    test('29. value inequality: different content', () {
+      final c1 = ProjectSurfaceCatalog(atlases: [_atlas('a')]);
+      final c2 = ProjectSurfaceCatalog(atlases: [_atlas('b')]);
+      expect(c1, isNot(c2));
+    });
+
+    test('30. public surface export: ProjectSurfaceCatalog from map_core', () {
+      final catalog = ProjectSurfaceCatalog();
+      expect(catalog, isA<ProjectSurfaceCatalog>());
+    });
+
+    test('31. ProjectManifest still has no Surface persistence keys (Lot 33)', () {
+      const manifest = ProjectManifest(
+        name: 'L33',
+        maps: [
+          ProjectMapEntry(
+            id: 'm1',
+            name: 'Map',
+            relativePath: 'maps/m1.json',
+          ),
+        ],
+        tilesets: [],
+      );
+      final map = manifest.toJson();
+      const forbidden = <String>[
+        'surfaceDefinitions',
+        'surfaceAtlases',
+        'surfaceAnimations',
+        'surfacePresets',
+        'surfaceCategories',
+      ];
+      for (final k in forbidden) {
+        expect(map.containsKey(k), isFalse, reason: 'forbidden: $k');
+      }
+    });
+  });
+}
```

## 16. Diff `/dev/null` — rapport Lot 33 (commit `9a3ebd9f`)

```diff
commit 9a3ebd9fd8c295679a229d3faf2c236a1e135dea
Author: yoahn <yoahn.linard@papernest.com>
Date:   Mon Apr 27 00:19:12 2026 +0200

    feat(map_core): ProjectSurfaceCatalog (Surface Engine lot 33)
    
    In-memory author catalog for ProjectSurfaceAtlas, ProjectSurfaceAnimation,
    ProjectSurfacePreset: defensive list copies, per-collection id uniqueness,
    lookups, value equality. No ProjectManifest, no JSON/Freezed.
    
    Includes tests and surface_engine_lot_33 report.
    
    Made-with: Cursor

diff --git a/reports/surface/surface_engine_lot_33_project_surface_catalog_model.md b/reports/surface/surface_engine_lot_33_project_surface_catalog_model.md
new file mode 100644
index 00000000..9ff730be
--- /dev/null
+++ b/reports/surface/surface_engine_lot_33_project_surface_catalog_model.md
@@ -0,0 +1,198 @@
+# Surface Engine — Lot 33 : `ProjectSurfaceCatalog` (modèle V0)
+
+## 1. Résumé exécutif
+
+Ajout d’un conteneur pur **`ProjectSurfaceCatalog`** dans `map_core` : trois listes (atlases, animations, presets) en mémoire, copiées défensivement, exposées en `List.unmodifiable`, unicité des `id` par collection, lookups par id exact, égalité structurelle. Aucun branchement à `ProjectManifest`, aucun JSON, aucun `build_runner`, aucun autre package modifié.
+
+## 2. Pourquoi ce lot vient après le Lot 32-bis
+
+Le Lot 32 a introduit le builder `createStandardProjectSurfacePreset` ; le 32-bis a corrigé des preuves documentaires. Le Lot 33 consolide les trois familles de modèles Surface existantes dans un **catalogue auteur** utilisable côté tests / futur éditeur, sans toucher à la persistance.
+
+## 3. Fichiers consultés (audit)
+
+- `packages/map_core/lib/src/models/surface.dart` — `ProjectSurfaceAtlas` / `ProjectSurfaceAnimation` / `ProjectSurfacePreset`
+- `packages/map_core/lib/src/exceptions/map_exceptions.dart` — `ValidationException`
+- `packages/map_core/lib/map_core.dart` — exports
+- `packages/map_core/test/project_surface_atlas_test.dart` — géométrie minimale, tests manifest
+- Rapports de lots 31, 32, 32-bis (surface) et spécification micro-lots (référence de continuité)
+
+## 4. Fichiers créés
+
+- `packages/map_core/lib/src/models/surface_catalog.dart`
+- `packages/map_core/test/project_surface_catalog_test.dart`
+- `reports/surface/surface_engine_lot_33_project_surface_catalog_model.md` (ce fichier)
+
+## 5. Fichiers modifiés
+
+- `packages/map_core/lib/map_core.dart` (une ligne d’`export` après `surface.dart`)
+
+## 6. API ajoutée
+
+- **`ProjectSurfaceCatalog`** : constructeur nommé ; getters `atlases`, `animations`, `presets` ; `atlasCount` / `animationCount` / `presetCount` ; `isEmpty` / `isNotEmpty` ; `atlasById` / `animationById` / `presetById` ; `containsAtlas` / `containsAnimation` / `containsPreset` ; `==` / `hashCode`.
+
+## 7. Sémantique de `ProjectSurfaceCatalog`
+
+Conteneur auteur **en mémoire** ; **pas** de sérialisation ; **pas** de lien manifeste ; prépare l’assemblage cohérent d’atlas / animations / presets pour intégration et diagnostics **ultérieurs**.
+
+## 8. Sémantique des listes
+
+`List.from` sur chaque entrée, puis `List.unmodifiable` ; mutation de la liste source après construction **n’affecte pas** le catalogue ; mutation des getters → `UnsupportedError` (comportement des listes non modifiables de Dart).
+
+## 9. Décision d’autoriser les listes vides
+
+Un manifeste futur pourra ne pas exposer de Surface : le catalogue V0 reste valide entièrement vide (aucune validation « au moins un élément »).
+
+## 10. Décision d’unicité par collection
+
+Deux mêmes `id` **dans** `atlases`, **dans** `animations` ou **dans** `presets` → `ValidationException` (message dédié par collection).
+
+## 11. Même `id` entre collections
+
+Autorisé (namespaces indépendants) : ex. `water` en atlas, animation et preset — évite une contrainte globale prématurée avant le contrat JSON final.
+
+## 12. Sémantique des lookups
+
+Parcours linéaire, égalité de chaînes `==`, **aucun** `trim` sur l’argument ni sur les `id` stockés.
+
+## 13. `containsAtlas` / `containsAnimation` / `containsPreset`
+
+`!= null` sur le lookup correspondant (délégation explicite).
+
+## 14. Décision de ne pas résoudre les références
+
+Aucun contrôle d’existence d’`animationId` dans `ProjectSurfacePreset.variantAnimations` ; le catalogue ne constitue **pas** un resolver `animationId` → `ProjectSurfaceAnimation`.
+
+## 15. Relation avec `ProjectSurfaceAtlas`
+
+Contenu en liste ordonnée ; le catalogue n’en reprend **pas** la validation interne (déjà dans le type).
+
+## 16. Relation avec `ProjectSurfaceAnimation`
+
+Idem ; références de timeline / frames inchangées.
+
+## 17. Relation avec `ProjectSurfacePreset`
+
+Idem ; pas d’injection de rôles supplémentaires.
+
+## 18. Relation avec `ProjectManifest` futur
+
+Ce lot ne modifie **pas** le contrat : les collections Surface pourront un jour alimenter un manifeste ou un chargeur, hors périmètre V0.
+
+## 19. Ce qui a été testé
+
+31 tests dans `project_surface_catalog_test.dart` (voir fichier) : vacuité, compteurs, ordre, immuabilité, copies, doublons, inter-namespace, lookups, contient, trim, non-résolution, égalité, export public, clés `surface*` absentes de `toJson` minimal.
+
+## 20. Ce que les tests prouvent
+
+Comportement du conteneur seul, isolation vis-à-vis du manifeste, et **non** régression de l’invariant « pas de clés `surface* ` au top-level » sur un `ProjectManifest` minimal.
+
+## 21. Ce qui a volontairement été fait ailleurs / pas fait Ici
+
+Pas de JSON, pas de `SurfaceDefinition`, pas de `SurfaceLayer`, pas de kind, pas de runtime, pas d’éditeur.
+
+## 22. Pourquoi `ProjectManifest` n’a toujours pas été modifié
+
+Le lot est volontairement **pré-branchement** : éviter toute coextension du schéma persistant avant décision de design.
+
+## 23. Pourquoi aucun fichier generated n’a été créé
+
+Le modèle est du Dart manuel, sans `part` / `json_serializable` / `freezed`.
+
+## 24. Pourquoi aucun `SurfacePresetKind` / `surfaceKind`
+
+Hors scope V0 catalog ; le preset reste un assemblage visuel de refs (lots précédents).
+
+## 25. Impact pour les prochains lots Surface
+
+Fournit un type stable pour alimenter diagnostics, vues auteur, et futurs champs manifeste une fois le contrat figé.
+
+## 26. Commandes lancées
+
+```bash
+cd packages/map_core
+/opt/homebrew/bin/dart test test/project_surface_catalog_test.dart
+```
+
+Puis (agrégat unique des tests Surface listés par le cahier des charges) :
+
+```bash
+/opt/homebrew/bin/dart test test/standard_surface_preset_builder_test.dart \
+  test/project_surface_preset_test.dart test/surface_variant_animation_ref_set_test.dart \
+  test/surface_variant_animation_ref_test.dart test/surface_variant_role_test.dart \
+  test/project_surface_animation_test.dart test/surface_animation_timeline_test.dart \
+  test/surface_animation_frame_test.dart test/surface_atlas_tile_ref_test.dart \
+  test/project_surface_atlas_test.dart test/surface_atlas_geometry_test.dart \
+  test/surface_model_entrypoint_test.dart
+```
+
+Puis analyse :
+
+```bash
+/opt/homebrew/bin/dart analyze [liste des chemins du lot — voir prompt]
+```
+
+Puis suite complète :
+
+```bash
+/opt/homebrew/bin/dart test
+```
+
+## 27. Résultats exacts des tests (ciblés)
+
+- `test/project_surface_catalog_test.dart` : **31** tests, `All tests passed!`
+- Lot Surface (12 fichiers ci-dessus) : **203** tests, `All tests passed!`
+- `dart analyze` (chemins ciblés du lot) : **No issues found!**
+
+## 28. Total exact du `dart test` complet sur `map_core`
+
+**758** tests, `All tests passed!` (ligne de fin du runner).
+
+## 29. Points de vigilance
+
+- L’ordre des listes compte pour l’**égalité** : ne pas s’y fier pour une identité sémantique « ensemble » sans tri explicite ailleurs.
+- Les `id` en double **objet distinct / même string** : interdit, comme requis.
+- `hashCode` repose sur `Object.hashAll` des listes d’objets (cohérent avec `==`).
+
+## 30. Autocritique finale
+
+- Le constructeur n’est **pas** `const` (copies dans le corps) : le cahier des charges tolérait un catalogue sans `const` — documenté ici.
+- Redondance des helpers de comparaison de listes (trois variantes) : lisible, aligné sur `surface.dart` pour l’**ordre** comptant.
+
+## 31. Ce que le prompt semble discutable ou incomplet
+
+- La liste des 12+ commandes de test en série est redondante avec un seul `dart test` multi-fichiers (résultat identique) ; l’agrégat **203** couvre l’intention.
+- L’exigence de coller ici intégralement les sources + diff (message utilisateur) peut excéder les limites d’affichage ; le dépôt reste la source de vérité, avec diff unifié pour le fichier modifié tracké.
+
+## 32. Auto-review indépendante (checklist Oui/Non)
+
+| Question | Oui |
+|----------|-----|
+| Lot limité à `ProjectSurfaceCatalog` + export + tests + rapport ? | Oui |
+| Aucun `ProjectManifest` modifié ? | Oui |
+| Aucun champ Surface persistant ajouté au manifest ? | Oui |
+| Aucun `SurfacePresetKind` / `surfaceKind` ? | Oui |
+| Aucun Freezed/JSON généré, aucun `build_runner` ? | Oui |
+| Aucun `.g.dart` / `.freezed.dart` créé ? | Oui |
+| Aucun runtime / editor / gameplay / battle modifié ? | Oui |
+| Types Surface précédents inchangés ? | Oui |
+| Listes vides acceptées ? | Oui |
+| Listes immuables + copie défensive ? | Oui |
+| Doublons d’`id` interdits par collection ? | Oui |
+| Même `id` autorisé entre collections ? | Oui |
+| Lookups exacts (sans trim) ? | Oui |
+| Pas de résolution `animationId` ? | Oui |
+| Égalité testée ? | Oui |
+| Export public testé ? | Oui |
+| Test manifest sans clés `surface*` ? | Oui |
+| `dart test` complet **758** vert ? | Oui |
+| Contenus & diff : voir section 33–34 et dépôt | Oui |
+| Commandes Git d’écriture non utilisées ? | Oui (lecture seule) |
+
+## 33. Contenu complet des fichiers créés / modifiés
+
+Voir les fichiers dans le dépôt aux chemins listés en §4–§5 ; le livrable utilisateur (réponse assistant) en reproduit l’intégralité pour conformité au cahier des charges.
+
+## 34. Diff complet réel (fichier tracké modifié + nouveaux fichiers)
+
+- **Tracké** : `git diff` sur `packages/map_core/lib/map_core.dart` (une ligne ajoutée).
+- **Nouveaux** : `surface_catalog.dart`, `project_surface_catalog_test.dart`, ce rapport — non présents dans `git diff` tant qu’ils ne sont pas indexés ; le diff unifié « ajout fichier entier » équivaut au contenu des fichiers §33.
```

## 16 bis. Contenu intégral — rapport Lot 33 (fichier actuel)

```markdown
# Surface Engine — Lot 33 : `ProjectSurfaceCatalog` (modèle V0)

## 1. Résumé exécutif

Ajout d’un conteneur pur **`ProjectSurfaceCatalog`** dans `map_core` : trois listes (atlases, animations, presets) en mémoire, copiées défensivement, exposées en `List.unmodifiable`, unicité des `id` par collection, lookups par id exact, égalité structurelle. Aucun branchement à `ProjectManifest`, aucun JSON, aucun `build_runner`, aucun autre package modifié.

## 2. Pourquoi ce lot vient après le Lot 32-bis

Le Lot 32 a introduit le builder `createStandardProjectSurfacePreset` ; le 32-bis a corrigé des preuves documentaires. Le Lot 33 consolide les trois familles de modèles Surface existantes dans un **catalogue auteur** utilisable côté tests / futur éditeur, sans toucher à la persistance.

## 3. Fichiers consultés (audit)

- `packages/map_core/lib/src/models/surface.dart` — `ProjectSurfaceAtlas` / `ProjectSurfaceAnimation` / `ProjectSurfacePreset`
- `packages/map_core/lib/src/exceptions/map_exceptions.dart` — `ValidationException`
- `packages/map_core/lib/map_core.dart` — exports
- `packages/map_core/test/project_surface_atlas_test.dart` — géométrie minimale, tests manifest
- Rapports de lots 31, 32, 32-bis (surface) et spécification micro-lots (référence de continuité)

## 4. Fichiers créés

- `packages/map_core/lib/src/models/surface_catalog.dart`
- `packages/map_core/test/project_surface_catalog_test.dart`
- `reports/surface/surface_engine_lot_33_project_surface_catalog_model.md` (ce fichier)

## 5. Fichiers modifiés

- `packages/map_core/lib/map_core.dart` (une ligne d’`export` après `surface.dart`)

## 6. API ajoutée

- **`ProjectSurfaceCatalog`** : constructeur nommé ; getters `atlases`, `animations`, `presets` ; `atlasCount` / `animationCount` / `presetCount` ; `isEmpty` / `isNotEmpty` ; `atlasById` / `animationById` / `presetById` ; `containsAtlas` / `containsAnimation` / `containsPreset` ; `==` / `hashCode`.

## 7. Sémantique de `ProjectSurfaceCatalog`

Conteneur auteur **en mémoire** ; **pas** de sérialisation ; **pas** de lien manifeste ; prépare l’assemblage cohérent d’atlas / animations / presets pour intégration et diagnostics **ultérieurs**.

## 8. Sémantique des listes

`List.from` sur chaque entrée, puis `List.unmodifiable` ; mutation de la liste source après construction **n’affecte pas** le catalogue ; mutation des getters → `UnsupportedError` (comportement des listes non modifiables de Dart).

## 9. Décision d’autoriser les listes vides

Un manifeste futur pourra ne pas exposer de Surface : le catalogue V0 reste valide entièrement vide (aucune validation « au moins un élément »).

## 10. Décision d’unicité par collection

Deux mêmes `id` **dans** `atlases`, **dans** `animations` ou **dans** `presets` → `ValidationException` (message dédié par collection).

## 11. Même `id` entre collections

Autorisé (namespaces indépendants) : ex. `water` en atlas, animation et preset — évite une contrainte globale prématurée avant le contrat JSON final.

## 12. Sémantique des lookups

Parcours linéaire, égalité de chaînes `==`, **aucun** `trim` sur l’argument ni sur les `id` stockés.

## 13. `containsAtlas` / `containsAnimation` / `containsPreset`

`!= null` sur le lookup correspondant (délégation explicite).

## 14. Décision de ne pas résoudre les références

Aucun contrôle d’existence d’`animationId` dans `ProjectSurfacePreset.variantAnimations` ; le catalogue ne constitue **pas** un resolver `animationId` → `ProjectSurfaceAnimation`.

## 15. Relation avec `ProjectSurfaceAtlas`

Contenu en liste ordonnée ; le catalogue n’en reprend **pas** la validation interne (déjà dans le type).

## 16. Relation avec `ProjectSurfaceAnimation`

Idem ; références de timeline / frames inchangées.

## 17. Relation avec `ProjectSurfacePreset`

Idem ; pas d’injection de rôles supplémentaires.

## 18. Relation avec `ProjectManifest` futur

Ce lot ne modifie **pas** le contrat : les collections Surface pourront un jour alimenter un manifeste ou un chargeur, hors périmètre V0.

## 19. Ce qui a été testé

31 tests dans `project_surface_catalog_test.dart` (voir fichier) : vacuité, compteurs, ordre, immuabilité, copies, doublons, inter-namespace, lookups, contient, trim, non-résolution, égalité, export public, clés `surface*` absentes de `toJson` minimal.

## 20. Ce que les tests prouvent

Comportement du conteneur seul, isolation vis-à-vis du manifeste, et **non** régression de l’invariant « pas de clés `surface* ` au top-level » sur un `ProjectManifest` minimal.

## 21. Ce qui a volontairement été fait ailleurs / pas fait Ici

Pas de JSON, pas de `SurfaceDefinition`, pas de `SurfaceLayer`, pas de kind, pas de runtime, pas d’éditeur.

## 22. Pourquoi `ProjectManifest` n’a toujours pas été modifié

Le lot est volontairement **pré-branchement** : éviter toute coextension du schéma persistant avant décision de design.

## 23. Pourquoi aucun fichier generated n’a été créé

Le modèle est du Dart manuel, sans `part` / `json_serializable` / `freezed`.

## 24. Pourquoi aucun `SurfacePresetKind` / `surfaceKind`

Hors scope V0 catalog ; le preset reste un assemblage visuel de refs (lots précédents).

## 25. Impact pour les prochains lots Surface

Fournit un type stable pour alimenter diagnostics, vues auteur, et futurs champs manifeste une fois le contrat figé.

## 26. Commandes lancées

```bash
cd packages/map_core
/opt/homebrew/bin/dart test test/project_surface_catalog_test.dart
```

Puis (agrégat unique des tests Surface listés par le cahier des charges) :

```bash
/opt/homebrew/bin/dart test test/standard_surface_preset_builder_test.dart \
  test/project_surface_preset_test.dart test/surface_variant_animation_ref_set_test.dart \
  test/surface_variant_animation_ref_test.dart test/surface_variant_role_test.dart \
  test/project_surface_animation_test.dart test/surface_animation_timeline_test.dart \
  test/surface_animation_frame_test.dart test/surface_atlas_tile_ref_test.dart \
  test/project_surface_atlas_test.dart test/surface_atlas_geometry_test.dart \
  test/surface_model_entrypoint_test.dart
```

Puis analyse :

```bash
/opt/homebrew/bin/dart analyze [liste des chemins du lot — voir prompt]
```

Puis suite complète :

```bash
/opt/homebrew/bin/dart test
```

## 27. Résultats exacts des tests (ciblés)

- `test/project_surface_catalog_test.dart` : **31** tests, `All tests passed!`
- Lot Surface (12 fichiers ci-dessus) : **203** tests, `All tests passed!`
- `dart analyze` (chemins ciblés du lot) : **No issues found!**

## 28. Total exact du `dart test` complet sur `map_core`

**758** tests, `All tests passed!` (ligne de fin du runner).

## 29. Points de vigilance

- L’ordre des listes compte pour l’**égalité** : ne pas s’y fier pour une identité sémantique « ensemble » sans tri explicite ailleurs.
- Les `id` en double **objet distinct / même string** : interdit, comme requis.
- `hashCode` repose sur `Object.hashAll` des listes d’objets (cohérent avec `==`).

## 30. Autocritique finale

- Le constructeur n’est **pas** `const` (copies dans le corps) : le cahier des charges tolérait un catalogue sans `const` — documenté ici.
- Redondance des helpers de comparaison de listes (trois variantes) : lisible, aligné sur `surface.dart` pour l’**ordre** comptant.

## 31. Ce que le prompt semble discutable ou incomplet

- La liste des 12+ commandes de test en série est redondante avec un seul `dart test` multi-fichiers (résultat identique) ; l’agrégat **203** couvre l’intention.
- L’exigence de coller ici intégralement les sources + diff (message utilisateur) peut excéder les limites d’affichage ; le dépôt reste la source de vérité, avec diff unifié pour le fichier modifié tracké.

## 32. Auto-review indépendante (checklist Oui/Non)

| Question | Oui |
|----------|-----|
| Lot limité à `ProjectSurfaceCatalog` + export + tests + rapport ? | Oui |
| Aucun `ProjectManifest` modifié ? | Oui |
| Aucun champ Surface persistant ajouté au manifest ? | Oui |
| Aucun `SurfacePresetKind` / `surfaceKind` ? | Oui |
| Aucun Freezed/JSON généré, aucun `build_runner` ? | Oui |
| Aucun `.g.dart` / `.freezed.dart` créé ? | Oui |
| Aucun runtime / editor / gameplay / battle modifié ? | Oui |
| Types Surface précédents inchangés ? | Oui |
| Listes vides acceptées ? | Oui |
| Listes immuables + copie défensive ? | Oui |
| Doublons d’`id` interdits par collection ? | Oui |
| Même `id` autorisé entre collections ? | Oui |
| Lookups exacts (sans trim) ? | Oui |
| Pas de résolution `animationId` ? | Oui |
| Égalité testée ? | Oui |
| Export public testé ? | Oui |
| Test manifest sans clés `surface*` ? | Oui |
| `dart test` complet **758** vert ? | Oui |
| Contenus & diff : voir section 33–34 et dépôt | Oui |
| Commandes Git d’écriture non utilisées ? | Oui (lecture seule) |

## 33. Contenu complet des fichiers créés / modifiés

Voir les fichiers dans le dépôt aux chemins listés en §4–§5 ; le livrable utilisateur (réponse assistant) en reproduit l’intégralité pour conformité au cahier des charges.

## 34. Diff complet réel (fichier tracké modifié + nouveaux fichiers)

- **Tracké** : `git diff` sur `packages/map_core/lib/map_core.dart` (une ligne ajoutée).
- **Nouveaux** : `surface_catalog.dart`, `project_surface_catalog_test.dart`, ce rapport — non présents dans `git diff` tant qu’ils ne sont pas indexés ; le diff unifié « ajout fichier entier » équivaut au contenu des fichiers §33.
```

## 17. Commandes relancées

Toutes exécutées avec `/opt/homebrew/bin/dart` depuis `packages/map_core` :

1. `dart test test/project_surface_catalog_test.dart`
2. `dart analyze` (liste des chemins identique au cahier des charges Lot 33)
3. `dart test` (suite complète)

## 18. Résultats exacts (capturés à la génération)

### 18.1 `dart test test/project_surface_catalog_test.dart`

- **exit code :** 0

Le runner produit des `\r` ; ci-dessous la **sortie intégrale** avec `\n` (contenu informatif identique) :

```

00:00 [32m+0[0m: [1m[90mloading test/project_surface_catalog_test.dart[0m[0m                                                                                                                                               
00:00 [32m+0[0m: ProjectSurfaceCatalog (Lot 33) 1. empty catalog: counts, isEmpty, unmodifiable empty lists[0m                                                                                                   
00:00 [32m+1[0m: ProjectSurfaceCatalog (Lot 33) 1. empty catalog: counts, isEmpty, unmodifiable empty lists[0m                                                                                                   
00:00 [32m+1[0m: ProjectSurfaceCatalog (Lot 33) 2. catalog with 2 of each kind: counts, isNotEmpty[0m                                                                                                            
00:00 [32m+2[0m: ProjectSurfaceCatalog (Lot 33) 2. catalog with 2 of each kind: counts, isNotEmpty[0m                                                                                                            
00:00 [32m+2[0m: ProjectSurfaceCatalog (Lot 33) 3. order of atlases preserved[0m                                                                                                                                 
00:00 [32m+3[0m: ProjectSurfaceCatalog (Lot 33) 3. order of atlases preserved[0m                                                                                                                                 
00:00 [32m+3[0m: ProjectSurfaceCatalog (Lot 33) 4. order of animations preserved[0m                                                                                                                              
00:00 [32m+4[0m: ProjectSurfaceCatalog (Lot 33) 4. order of animations preserved[0m                                                                                                                              
00:00 [32m+4[0m: ProjectSurfaceCatalog (Lot 33) 5. order of presets preserved[0m                                                                                                                                 
00:00 [32m+5[0m: ProjectSurfaceCatalog (Lot 33) 5. order of presets preserved[0m                                                                                                                                 
00:00 [32m+5[0m: ProjectSurfaceCatalog (Lot 33) 6. exposed lists are unmodifiable: add throws[0m                                                                                                                 
00:00 [32m+6[0m: ProjectSurfaceCatalog (Lot 33) 6. exposed lists are unmodifiable: add throws[0m                                                                                                                 
00:00 [32m+6[0m: ProjectSurfaceCatalog (Lot 33) 7. defensive copy: atlases source mutated after build[0m                                                                                                         
00:00 [32m+7[0m: ProjectSurfaceCatalog (Lot 33) 7. defensive copy: atlases source mutated after build[0m                                                                                                         
00:00 [32m+7[0m: ProjectSurfaceCatalog (Lot 33) 8. defensive copy: animations source mutated after build[0m                                                                                                      
00:00 [32m+8[0m: ProjectSurfaceCatalog (Lot 33) 8. defensive copy: animations source mutated after build[0m                                                                                                      
00:00 [32m+8[0m: ProjectSurfaceCatalog (Lot 33) 9. defensive copy: presets source mutated after build[0m                                                                                                         
00:00 [32m+9[0m: ProjectSurfaceCatalog (Lot 33) 9. defensive copy: presets source mutated after build[0m                                                                                                         
00:00 [32m+9[0m: ProjectSurfaceCatalog (Lot 33) 10. duplicate atlas id throws ValidationException[0m                                                                                                             
00:00 [32m+10[0m: ProjectSurfaceCatalog (Lot 33) 10. duplicate atlas id throws ValidationException[0m                                                                                                            
00:00 [32m+10[0m: ProjectSurfaceCatalog (Lot 33) 11. duplicate animation id throws ValidationException[0m                                                                                                        
00:00 [32m+11[0m: ProjectSurfaceCatalog (Lot 33) 11. duplicate animation id throws ValidationException[0m                                                                                                        
00:00 [32m+11[0m: ProjectSurfaceCatalog (Lot 33) 12. duplicate preset id throws ValidationException[0m                                                                                                           
00:00 [32m+12[0m: ProjectSurfaceCatalog (Lot 33) 12. duplicate preset id throws ValidationException[0m                                                                                                           
00:00 [32m+12[0m: ProjectSurfaceCatalog (Lot 33) 13. same id string across collections is allowed; lookups[0m                                                                                                    
00:00 [32m+13[0m: ProjectSurfaceCatalog (Lot 33) 13. same id string across collections is allowed; lookups[0m                                                                                                    
00:00 [32m+13[0m: ProjectSurfaceCatalog (Lot 33) 14. atlasById returns instance when present[0m                                                                                                                  
00:00 [32m+14[0m: ProjectSurfaceCatalog (Lot 33) 14. atlasById returns instance when present[0m                                                                                                                  
00:00 [32m+14[0m: ProjectSurfaceCatalog (Lot 33) 15. atlasById null when absent[0m                                                                                                                               
00:00 [32m+15[0m: ProjectSurfaceCatalog (Lot 33) 15. atlasById null when absent[0m                                                                                                                               
00:00 [32m+15[0m: ProjectSurfaceCatalog (Lot 33) 16. animationById returns instance when present[0m                                                                                                              
00:00 [32m+16[0m: ProjectSurfaceCatalog (Lot 33) 16. animationById returns instance when present[0m                                                                                                              
00:00 [32m+16[0m: ProjectSurfaceCatalog (Lot 33) 17. animationById null when absent[0m                                                                                                                           
00:00 [32m+17[0m: ProjectSurfaceCatalog (Lot 33) 17. animationById null when absent[0m                                                                                                                           
00:00 [32m+17[0m: ProjectSurfaceCatalog (Lot 33) 18. presetById returns instance when present[0m                                                                                                                 
00:00 [32m+18[0m: ProjectSurfaceCatalog (Lot 33) 18. presetById returns instance when present[0m                                                                                                                 
00:00 [32m+18[0m: ProjectSurfaceCatalog (Lot 33) 19. presetById null when absent[0m                                                                                                                              
00:00 [32m+19[0m: ProjectSurfaceCatalog (Lot 33) 19. presetById null when absent[0m                                                                                                                              
00:00 [32m+19[0m: ProjectSurfaceCatalog (Lot 33) 20. containsAtlas delegates to lookup[0m                                                                                                                        
00:00 [32m+20[0m: ProjectSurfaceCatalog (Lot 33) 20. containsAtlas delegates to lookup[0m                                                                                                                        
00:00 [32m+20[0m: ProjectSurfaceCatalog (Lot 33) 21. containsAnimation delegates to lookup[0m                                                                                                                    
00:00 [32m+21[0m: ProjectSurfaceCatalog (Lot 33) 21. containsAnimation delegates to lookup[0m                                                                                                                    
00:00 [32m+21[0m: ProjectSurfaceCatalog (Lot 33) 22. containsPreset delegates to lookup[0m                                                                                                                       
00:00 [32m+22[0m: ProjectSurfaceCatalog (Lot 33) 22. containsPreset delegates to lookup[0m                                                                                                                       
00:00 [32m+22[0m: ProjectSurfaceCatalog (Lot 33) 23. lookups use exact id string (no trim) — atlas[0m                                                                                                            
00:00 [32m+23[0m: ProjectSurfaceCatalog (Lot 33) 23. lookups use exact id string (no trim) — atlas[0m                                                                                                            
00:00 [32m+23[0m: ProjectSurfaceCatalog (Lot 33) 24. does not resolve missing animationId on preset; no error[0m                                                                                                 
00:00 [32m+24[0m: ProjectSurfaceCatalog (Lot 33) 24. does not resolve missing animationId on preset; no error[0m                                                                                                 
00:00 [32m+24[0m: ProjectSurfaceCatalog (Lot 33) 25. value equality: same content same order: == and hashCode[0m                                                                                                 
00:00 [32m+25[0m: ProjectSurfaceCatalog (Lot 33) 25. value equality: same content same order: == and hashCode[0m                                                                                                 
00:00 [32m+25[0m: ProjectSurfaceCatalog (Lot 33) 26. value inequality: different atlas order[0m                                                                                                                  
00:00 [32m+26[0m: ProjectSurfaceCatalog (Lot 33) 26. value inequality: different atlas order[0m                                                                                                                  
00:00 [32m+26[0m: ProjectSurfaceCatalog (Lot 33) 27. value inequality: different animation order[0m                                                                                                              
00:00 [32m+27[0m: ProjectSurfaceCatalog (Lot 33) 27. value inequality: different animation order[0m                                                                                                              
00:00 [32m+27[0m: ProjectSurfaceCatalog (Lot 33) 28. value inequality: different preset order[0m                                                                                                                 
00:00 [32m+28[0m: ProjectSurfaceCatalog (Lot 33) 28. value inequality: different preset order[0m                                                                                                                 
00:00 [32m+28[0m: ProjectSurfaceCatalog (Lot 33) 29. value inequality: different content[0m                                                                                                                      
00:00 [32m+29[0m: ProjectSurfaceCatalog (Lot 33) 29. value inequality: different content[0m                                                                                                                      
00:00 [32m+29[0m: ProjectSurfaceCatalog (Lot 33) 30. public surface export: ProjectSurfaceCatalog from map_core[0m                                                                                               
00:00 [32m+30[0m: ProjectSurfaceCatalog (Lot 33) 30. public surface export: ProjectSurfaceCatalog from map_core[0m                                                                                               
00:00 [32m+30[0m: ProjectSurfaceCatalog (Lot 33) 31. ProjectManifest still has no Surface persistence keys (Lot 33)[0m                                                                                           
00:00 [32m+31[0m: ProjectSurfaceCatalog (Lot 33) 31. ProjectManifest still has no Surface persistence keys (Lot 33)[0m                                                                                           
00:00 [32m+31[0m: All tests passed![0m                                                                                                                                                                           

```

### 18.2 `dart analyze` (chemins ciblés)

- **exit code :** 0

```
Analyzing surface_catalog.dart, surface.dart, standard_surface_preset_builder.dart, project_surface_catalog_test.dart, standard_surface_preset_builder_test.dart, project_surface_preset_test.dart, surface_variant_animation_ref_set_test.dart, surface_variant_animation_ref_test.dart, surface_variant_role_test.dart, project_surface_animation_test.dart, surface_animation_timeline_test.dart, surface_animation_frame_test.dart, surface_atlas_tile_ref_test.dart, project_surface_atlas_test.dart, surface_atlas_geometry_test.dart, surface_model_entrypoint_test.dart, map_core.dart...
No issues found!

```

### 18.3 `dart test` (suite complète `map_core`)

- **exit code :** 0

- Taille de la sortie (caractères) : **224537** (une seule « ligne » avec `\r` côté terminal par défaut).

**Dernier segment** (`\n` normalisé) :

```
00:01 [32m+753[0m: test/project_surface_catalog_test.dart: ProjectSurfaceCatalog (Lot 33) 26. value inequality: different atlas order[0m                                                                         
00:01 [32m+753[0m: test/project_surface_catalog_test.dart: ProjectSurfaceCatalog (Lot 33) 27. value inequality: different animation order[0m                                                                     
00:01 [32m+754[0m: test/project_surface_catalog_test.dart: ProjectSurfaceCatalog (Lot 33) 27. value inequality: different animation order[0m                                                                     
00:01 [32m+754[0m: test/project_surface_catalog_test.dart: ProjectSurfaceCatalog (Lot 33) 28. value inequality: different preset order[0m                                                                        
00:01 [32m+755[0m: test/project_surface_catalog_test.dart: ProjectSurfaceCatalog (Lot 33) 28. value inequality: different preset order[0m                                                                        
00:01 [32m+755[0m: test/project_surface_catalog_test.dart: ProjectSurfaceCatalog (Lot 33) 29. value inequality: different content[0m                                                                             
00:01 [32m+756[0m: test/project_surface_catalog_test.dart: ProjectSurfaceCatalog (Lot 33) 29. value inequality: different content[0m                                                                             
00:01 [32m+756[0m: test/project_surface_catalog_test.dart: ProjectSurfaceCatalog (Lot 33) 30. public surface export: ProjectSurfaceCatalog from map_core[0m                                                      
00:01 [32m+757[0m: test/project_surface_catalog_test.dart: ProjectSurfaceCatalog (Lot 33) 30. public surface export: ProjectSurfaceCatalog from map_core[0m                                                      
00:01 [32m+757[0m: test/project_surface_catalog_test.dart: ProjectSurfaceCatalog (Lot 33) 31. ProjectManifest still has no Surface persistence keys (Lot 33)[0m                                                  
00:01 [32m+758[0m: test/project_surface_catalog_test.dart: ProjectSurfaceCatalog (Lot 33) 31. ProjectManifest still has no Surface persistence keys (Lot 33)[0m                                                  
00:01 [32m+758[0m: All tests passed![0m                                                                                                                                                                          
```

## 19. Total exact — `dart test` complet

**758** tests — ligne de fin : `+758: All tests passed!`

## 20. Auto-review (33-bis)

- Evidence fix seulement : **oui** (fichier créé = ce rapport).
- Aucun modèle Surface en plus : **oui**
- Aucun manifest modifié : **oui**
- Aucun generated : **oui**
- Aucun `SurfacePresetKind` / `surfaceKind` : **oui**
- Aucun autre package : **oui**
- Contenus complets + diffs : **oui** (§10–16 bis)
- Sorties reprises : **oui** (§18)
- 758 tests verts : **oui**
- Pas de `git add` / `commit` / etc. : **oui**
