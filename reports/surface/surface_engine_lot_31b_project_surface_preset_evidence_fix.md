# Lot 31-bis — Preuve (evidence fix) : `ProjectSurfacePreset` V0

## 1. Résumé exécutif

Ce rapport ne modifie **aucun code** : il **archive** les contenus complets, les diffs issus de l'historique Git (`3a3186c1` — commit Lot 31) et les **sorties brutes** des commandes `dart` relancées afin de corriger le déficit de preuve documentaire du rapport Lot 31.

## 2. Pourquoi le Lot 31-bis existe

Le Lot 31 était techniquement correct, mais le rapport `surface_engine_lot_31_project_surface_preset_model.md` renvoyait encore partiellement vers le worktree pour les contenus intégraux au lieu d'y copier les fichiers, diffs `git show` et journaux d'exécution de façon reproductible.

## 3. Fichiers inspectés (lecture, audit)

- `packages/map_core/lib/src/models/surface.dart` — `ProjectSurfacePreset` présent, `id`/`name` validés, délégations, pas de résolution d'`animationId`, pas de `SurfacePresetKind`
- `packages/map_core/test/project_surface_preset_test.dart` — 23 tests, manifest minimal sans clés `surface*`
- `reports/surface/surface_engine_lot_31_project_surface_preset_model.md` — lot 31 (archivage)
- `packages/map_core/lib/map_core.dart` — export de `src/models/surface.dart` (inchangé)
- `packages/map_core/lib/src/models/project_manifest.dart` — inchangé (pas de listes Surface persistantes)

## 4. Fichier créé / modifié par **ce** lot (31-bis)

- **Créé :** `reports/surface/surface_engine_lot_31b_project_surface_preset_evidence_fix.md` (ce document)
- **Code Lot 31 :** aucun fichier de code ni rapport Lot 31 modifié (voir §5)

## 5. Code du Lot 31 : **non modifié**

- `packages/map_core/lib/src/models/surface.dart` — **inchangé**
- `packages/map_core/test/project_surface_preset_test.dart` — **inchangé**
- `reports/surface/surface_engine_lot_31_project_surface_preset_model.md` — **inchangé**

## 6. `ProjectManifest` : **non modifié** (par ce lot)

Aucun éditeur n'a touché `project_manifest.dart` pour le 31-bis.

## 7. Fichiers générés (`build_runner`, `.g.dart`, `.freezed.dart`)

**Aucun.**

## 8. `SurfacePresetKind` / `surfaceKind`

**Non créé** (inchangé par rapport au Lot 31).

---

## 9. Contenu complet : `packages/map_core/test/project_surface_preset_test.dart`

> **Lignes :** 397 (worktree) — identique à `git show HEAD:packages/map_core/test/project_surface_preset_test.dart`.

```dart
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

SurfaceVariantAnimationRef _ref(SurfaceVariantRole role, String animationId) {
  return SurfaceVariantAnimationRef(
    role: role,
    animationId: animationId,
  );
}

SurfaceVariantAnimationRefSet _refSet(List<SurfaceVariantAnimationRef> refs) {
  return SurfaceVariantAnimationRefSet(refs: refs);
}

ProjectSurfacePreset _preset({
  String id = 'p1',
  String name = 'N',
  required SurfaceVariantAnimationRefSet variantAnimations,
  String? categoryId,
  int sortOrder = 0,
}) {
  return ProjectSurfacePreset(
    id: id,
    name: name,
    variantAnimations: variantAnimations,
    categoryId: categoryId,
    sortOrder: sortOrder,
  );
}

SurfaceAnimationTimeline _singleTileTimeline() {
  return SurfaceAnimationTimeline(
    frames: [
      SurfaceAnimationFrame(
        tileRef: SurfaceAtlasTileRef(
          atlasId: 'atlas-1',
          column: 0,
          row: 0,
        ),
        durationMs: 100,
      ),
    ],
  );
}

void main() {
  group('ProjectSurfacePreset', () {
    test('1. minimal preset: fields and variantCount', () {
      final refs = SurfaceVariantAnimationRefSet(
        refs: [
          SurfaceVariantAnimationRef(
            role: SurfaceVariantRole.isolated,
            animationId: 'water-isolated-loop',
          ),
        ],
      );
      final preset = ProjectSurfacePreset(
        id: 'water-surface',
        name: 'Water Surface',
        variantAnimations: refs,
      );
      expect(preset.id, 'water-surface');
      expect(preset.name, 'Water Surface');
      expect(preset.variantAnimations, refs);
      expect(preset.categoryId, isNull);
      expect(preset.sortOrder, 0);
      expect(preset.variantCount, 1);
    });

    test('2. preserves exact same variantAnimations instance', () {
      final refs = _refSet([_ref(SurfaceVariantRole.isolated, 'a')]);
      final preset = _preset(variantAnimations: refs);
      expect(identical(preset.variantAnimations, refs), isTrue);
    });

    test('3. preserves categoryId and sortOrder', () {
      final refs = _refSet([_ref(SurfaceVariantRole.isolated, 'a')]);
      final preset = _preset(
        variantAnimations: refs,
        categoryId: 'animated-surfaces',
        sortOrder: 42,
      );
      expect(preset.categoryId, 'animated-surfaces');
      expect(preset.sortOrder, 42);
    });

    test('4. stores id and name exactly without auto-trim', () {
      const id = '  water-surface  ';
      const name = '  Water Surface  ';
      final refs = _refSet([_ref(SurfaceVariantRole.isolated, 'a')]);
      final preset = ProjectSurfacePreset(
        id: id,
        name: name,
        variantAnimations: refs,
      );
      expect(preset.id, id);
      expect(preset.name, name);
    });

    test('5. rejects empty id: empty and whitespace', () {
      final refs = _refSet([_ref(SurfaceVariantRole.isolated, 'a')]);
      expect(
        () => ProjectSurfacePreset(
          id: '',
          name: 'N',
          variantAnimations: refs,
        ),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => ProjectSurfacePreset(
          id: '   ',
          name: 'N',
          variantAnimations: refs,
        ),
        throwsA(isA<ValidationException>()),
      );
    });

    test('6. rejects empty name: empty and whitespace', () {
      final refs = _refSet([_ref(SurfaceVariantRole.isolated, 'a')]);
      expect(
        () => ProjectSurfacePreset(
          id: 'i',
          name: '',
          variantAnimations: refs,
        ),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => ProjectSurfacePreset(
          id: 'i',
          name: '   ',
          variantAnimations: refs,
        ),
        throwsA(isA<ValidationException>()),
      );
    });

    test('7. does not over-validate categoryId: empty and whitespace allowed', () {
      final refs = _refSet([_ref(SurfaceVariantRole.isolated, 'a')]);
      final a = _preset(
        variantAnimations: refs,
        categoryId: '',
      );
      final b = _preset(
        variantAnimations: _refSet([_ref(SurfaceVariantRole.cross, 'x')]),
        categoryId: '   ',
      );
      expect(a.categoryId, '');
      expect(b.categoryId, '   ');
    });

    test('8. allows negative sortOrder', () {
      final refs = _refSet([_ref(SurfaceVariantRole.isolated, 'a')]);
      final preset = _preset(
        variantAnimations: refs,
        sortOrder: -10,
      );
      expect(preset.sortOrder, -10);
    });

    test('9. delegating containsRole', () {
      final set = _refSet([
        _ref(SurfaceVariantRole.isolated, 'a'),
        _ref(SurfaceVariantRole.horizontal, 'b'),
      ]);
      final preset = _preset(variantAnimations: set);
      expect(preset.containsRole(SurfaceVariantRole.isolated), isTrue);
      expect(preset.containsRole(SurfaceVariantRole.horizontal), isTrue);
      expect(preset.containsRole(SurfaceVariantRole.cross), isFalse);
    });

    test('10. delegating refForRole: present and absent', () {
      final r = _ref(SurfaceVariantRole.isolated, 'loop');
      final set = _refSet([r]);
      final preset = _preset(variantAnimations: set);
      expect(preset.refForRole(SurfaceVariantRole.isolated), r);
      expect(preset.refForRole(SurfaceVariantRole.cross), isNull);
    });

    test('11. delegating animationIdForRole: present and absent', () {
      final set = _refSet([_ref(SurfaceVariantRole.vertical, 'v-id')]);
      final preset = _preset(variantAnimations: set);
      expect(
        preset.animationIdForRole(SurfaceVariantRole.vertical),
        'v-id',
      );
      expect(
        preset.animationIdForRole(SurfaceVariantRole.isolated),
        isNull,
      );
    });

    test('12. delegating coversAllRoles', () {
      final set = _refSet([
        _ref(SurfaceVariantRole.isolated, 'a'),
        _ref(SurfaceVariantRole.horizontal, 'b'),
        _ref(SurfaceVariantRole.vertical, 'c'),
      ]);
      final preset = _preset(variantAnimations: set);
      expect(
        preset.coversAllRoles(
          [SurfaceVariantRole.isolated, SurfaceVariantRole.horizontal],
        ),
        isTrue,
      );
      expect(
        preset.coversAllRoles(
          [SurfaceVariantRole.isolated, SurfaceVariantRole.cross],
        ),
        isFalse,
      );
      expect(preset.coversAllRoles([]), isTrue);
    });

    test('13. can cover exactly standardSurfaceVariantRoleOrder', () {
      final refs = [
        for (var i = 0; i < standardSurfaceVariantRoleOrder.length; i++)
          _ref(
            standardSurfaceVariantRoleOrder[i],
            'anim-$i',
          ),
      ];
      final set = _refSet(refs);
      final preset = _preset(
        id: 'full',
        name: 'Full',
        variantAnimations: set,
      );
      expect(
        preset.variantCount,
        standardSurfaceVariantRoleOrder.length,
      );
      expect(
        preset.coversAllRoles(standardSurfaceVariantRoleOrder),
        isTrue,
      );
    });

    test('14. value equality: identical presets are equal and same hashCode', () {
      final s = _refSet([_ref(SurfaceVariantRole.isolated, 'a')]);
      final a = _preset(
        id: 'i',
        name: 'N',
        variantAnimations: s,
        categoryId: 'cat',
        sortOrder: 1,
      );
      final b = _preset(
        id: 'i',
        name: 'N',
        variantAnimations: s,
        categoryId: 'cat',
        sortOrder: 1,
      );
      expect(a, b);
      expect(a.hashCode, b.hashCode);
    });

    test('15. value equality: different id', () {
      final s = _refSet([_ref(SurfaceVariantRole.isolated, 'a')]);
      final a = _preset(id: 'a1', name: 'N', variantAnimations: s);
      final b = _preset(id: 'a2', name: 'N', variantAnimations: s);
      expect(a, isNot(equals(b)));
    });

    test('16. value equality: different name', () {
      final s = _refSet([_ref(SurfaceVariantRole.isolated, 'a')]);
      final a = _preset(name: 'A', variantAnimations: s);
      final b = _preset(name: 'B', variantAnimations: s);
      expect(a, isNot(equals(b)));
    });

    test('17. value equality: different variantAnimations', () {
      final base = _refSet([_ref(SurfaceVariantRole.isolated, 'same')]);
      // Different animationId
      final a = _preset(variantAnimations: base);
      final b1 = _preset(
        variantAnimations: _refSet([_ref(SurfaceVariantRole.isolated, 'other')]),
      );
      expect(a, isNot(equals(b1)));
      // Different order (RefSet is order-sensitive)
      final c = _refSet([
        _ref(SurfaceVariantRole.cross, 'x'),
        _ref(SurfaceVariantRole.isolated, 'i'),
      ]);
      final d = _refSet([
        _ref(SurfaceVariantRole.isolated, 'i'),
        _ref(SurfaceVariantRole.cross, 'x'),
      ]);
      expect(c, isNot(equals(d)));
      final pC = _preset(id: 'p', name: 'n', variantAnimations: c);
      final pD = _preset(id: 'p', name: 'n', variantAnimations: d);
      expect(pC, isNot(equals(pD)));
      // Different role
      final e = _preset(
        variantAnimations: _refSet([_ref(SurfaceVariantRole.cross, 'x')]),
      );
      final f = _preset(
        variantAnimations: _refSet([_ref(SurfaceVariantRole.teeWest, 'x')]),
      );
      expect(e, isNot(equals(f)));
    });

    test('18. value equality: different categoryId', () {
      final s = _refSet([_ref(SurfaceVariantRole.isolated, 'a')]);
      final a = _preset(
        variantAnimations: s,
        categoryId: 'c1',
      );
      final b = _preset(
        variantAnimations: s,
        categoryId: 'c2',
      );
      expect(a, isNot(equals(b)));
    });

    test('19. value equality: different sortOrder', () {
      final s = _refSet([_ref(SurfaceVariantRole.isolated, 'a')]);
      final a = _preset(
        variantAnimations: s,
        sortOrder: 0,
      );
      final b = _preset(
        variantAnimations: s,
        sortOrder: 1,
      );
      expect(a, isNot(equals(b)));
    });

    test('20. public export: ProjectSurfacePreset via map_core', () {
      final preset = _preset(
        variantAnimations: _refSet([_ref(SurfaceVariantRole.isolated, 'a')]),
      );
      expect(preset, isA<ProjectSurfacePreset>());
    });

    test(
        '21. V0 visual-only: preset has no kind / surfaceKind / behavior field',
        () {
      final preset = _preset(
        id: 'vis',
        name: 'Visual',
        variantAnimations: _refSet([_ref(SurfaceVariantRole.isolated, 'a')]),
      );
      expect(preset.id, 'vis');
    });

    test('22. coexists with ProjectSurfaceAnimation without resolution', () {
      final animation = ProjectSurfaceAnimation(
        id: 'water-loop',
        name: 'Water Loop',
        timeline: _singleTileTimeline(),
      );
      final r = SurfaceVariantAnimationRef(
        role: SurfaceVariantRole.cross,
        animationId: animation.id,
      );
      final set = SurfaceVariantAnimationRefSet(refs: [r]);
      final preset = ProjectSurfacePreset(
        id: 'p',
        name: 'P',
        variantAnimations: set,
      );
      expect(
        preset.animationIdForRole(SurfaceVariantRole.cross),
        animation.id,
      );
    });

    test('23. ProjectManifest still has no Surface persistence keys (Lot 21–31)', () {
      const manifest = ProjectManifest(
        name: 'L31 smoke',
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
      for (final key in forbidden) {
        expect(map.containsKey(key), isFalse, reason: 'unexpected key: $key');
      }
    });
  });
}

```

---

## 10. Contenu complet : bloc `ProjectSurfacePreset` (fin de `surface.dart`)

Extrait contigu, plage de lignes **716**–**803** (1-based) du fichier `surface.dart` :

```dart
/// **Preset Surface** côté auteur : définition visuelle **réutilisable** qui
/// associe des [SurfaceVariantRole] à des identifiants d’animation (`animationId`)
/// via un [SurfaceVariantAnimationRefSet].
///
/// * Modèle de **domaine pur** : **aucun** [toJson] / [fromJson] ; **n’est pas**
///   rattaché à un [ProjectManifest] (aucune liste `surfacePresets` à ce
///   stade).
/// * Ne **résout** pas les [animationId] vers des [ProjectSurfaceAnimation],
///   ne connaît **pas** de [ProjectSurfaceAtlas], pas de frames, pas de runtime.
/// * Les recherches par rôle ([containsRole], [refForRole], [animationIdForRole],
///   [coversAllRoles]) **délèguent** à [variantAnimations], source de vérité pour
///   les rôles couverts et l’**ordre** des refs.
/// * Pas de [SurfacePresetKind], pas de gameplay / eau / herbe / lave ici : V0
///   strictement **visuel** (assemblage de refs de variantes).
@immutable
final class ProjectSurfacePreset {
  ProjectSurfacePreset({
    required this.id,
    required this.name,
    required this.variantAnimations,
    this.categoryId,
    this.sortOrder = 0,
  }) {
    if (id.trim().isEmpty) {
      throw const ValidationException('ProjectSurfacePreset.id must be non-empty');
    }
    if (name.trim().isEmpty) {
      throw const ValidationException('ProjectSurfacePreset.name must be non-empty');
    }
  }

  /// Identifiant stable du preset, stocké **tel quel** (invalidité seulement si,
  /// après [trim], il ne reste rien). Pas de résolution d’animations.
  final String id;

  /// Libellé auteur ; mêmes règles de stockage / garde qu’[id].
  final String name;

  /// Set de refs (non vide, rôles uniques) : **même instance** que celle passée
  /// au constructeur (pas de copie, pas de revalidation ici).
  final SurfaceVariantAnimationRefSet variantAnimations;

  /// Catégorie d’UI optionnelle ; pas de forme imposée (comme
  /// [ProjectSurfaceAtlas.categoryId] / [ProjectSurfaceAnimation.categoryId]).
  final String? categoryId;

  /// Classement d’affichage futur ; toute valeur entière acceptée (y compris
  /// négative), comme [ProjectSurfaceAtlas.sortOrder] / [ProjectSurfaceAnimation.sortOrder].
  final int sortOrder;

  /// Délègue à [SurfaceVariantAnimationRefSet.length] : nombre de rôles couverts.
  int get variantCount => variantAnimations.length;

  /// Délègue à [SurfaceVariantAnimationRefSet.containsRole].
  bool containsRole(SurfaceVariantRole role) =>
      variantAnimations.containsRole(role);

  /// Délègue à [SurfaceVariantAnimationRefSet.refForRole].
  SurfaceVariantAnimationRef? refForRole(SurfaceVariantRole role) =>
      variantAnimations.refForRole(role);

  /// Délègue à [SurfaceVariantAnimationRefSet.animationIdForRole].
  String? animationIdForRole(SurfaceVariantRole role) =>
      variantAnimations.animationIdForRole(role);

  /// Délègue à [SurfaceVariantAnimationRefSet.coversAllRoles].
  bool coversAllRoles(Iterable<SurfaceVariantRole> roles) =>
      variantAnimations.coversAllRoles(roles);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProjectSurfacePreset &&
          other.id == id &&
          other.name == name &&
          other.variantAnimations == variantAnimations &&
          other.categoryId == categoryId &&
          other.sortOrder == sortOrder;

  @override
  int get hashCode => Object.hash(
        id,
        name,
        variantAnimations,
        categoryId,
        sortOrder,
      );
}

```

---

## 11. Diff complet réel : `packages/map_core/lib/src/models/surface.dart`

Source : `git show 3a3186c1 -p -- packages/map_core/lib/src/models/surface.dart`

```text
commit 3a3186c1702a02aa21d967fbbd3185c0dfd02867
Author: yoahn <yoahn.linard@papernest.com>
Date:   Sun Apr 26 23:59:52 2026 +0200

    feat(map_core): ProjectSurfacePreset (Lot 31)
    
    Preset auteur visuel, refs via SurfaceVariantAnimationRefSet, sans manifest.
    Tests + rapport. Pas de SurfacePresetKind ni persistance.
    
    Made-with: Cursor

diff --git a/packages/map_core/lib/src/models/surface.dart b/packages/map_core/lib/src/models/surface.dart
index d525ca3f..51070465 100644
--- a/packages/map_core/lib/src/models/surface.dart
+++ b/packages/map_core/lib/src/models/surface.dart
@@ -1,7 +1,7 @@
 // Fichier d’entrée Surface (map_core) : pas de persistance JSON, pas de `toJson` ici.
 // Contient les enums (layout, rôles de variante d’autotile), les value objects
-// de géométrie d’atlas, [ProjectSurfaceAtlas] / [ProjectSurfaceAnimation] —
-// raccrochage manifest dans des lots ultérieurs.
+// de géométrie d’atlas, [ProjectSurfaceAtlas] / [ProjectSurfaceAnimation] /
+// [ProjectSurfacePreset] — raccrochage manifest dans des lots ultérieurs.
 
 import 'package:meta/meta.dart' show immutable;
 
@@ -712,3 +712,92 @@ final class SurfaceVariantAnimationRefSet {
   @override
   int get hashCode => Object.hashAll(_refs);
 }
+
+/// **Preset Surface** côté auteur : définition visuelle **réutilisable** qui
+/// associe des [SurfaceVariantRole] à des identifiants d’animation (`animationId`)
+/// via un [SurfaceVariantAnimationRefSet].
+///
+/// * Modèle de **domaine pur** : **aucun** [toJson] / [fromJson] ; **n’est pas**
+///   rattaché à un [ProjectManifest] (aucune liste `surfacePresets` à ce
+///   stade).
+/// * Ne **résout** pas les [animationId] vers des [ProjectSurfaceAnimation],
+///   ne connaît **pas** de [ProjectSurfaceAtlas], pas de frames, pas de runtime.
+/// * Les recherches par rôle ([containsRole], [refForRole], [animationIdForRole],
+///   [coversAllRoles]) **délèguent** à [variantAnimations], source de vérité pour
+///   les rôles couverts et l’**ordre** des refs.
+/// * Pas de [SurfacePresetKind], pas de gameplay / eau / herbe / lave ici : V0
+///   strictement **visuel** (assemblage de refs de variantes).
+@immutable
+final class ProjectSurfacePreset {
+  ProjectSurfacePreset({
+    required this.id,
+    required this.name,
+    required this.variantAnimations,
+    this.categoryId,
+    this.sortOrder = 0,
+  }) {
+    if (id.trim().isEmpty) {
+      throw const ValidationException('ProjectSurfacePreset.id must be non-empty');
+    }
+    if (name.trim().isEmpty) {
+      throw const ValidationException('ProjectSurfacePreset.name must be non-empty');
+    }
+  }
+
+  /// Identifiant stable du preset, stocké **tel quel** (invalidité seulement si,
+  /// après [trim], il ne reste rien). Pas de résolution d’animations.
+  final String id;
+
+  /// Libellé auteur ; mêmes règles de stockage / garde qu’[id].
+  final String name;
+
+  /// Set de refs (non vide, rôles uniques) : **même instance** que celle passée
+  /// au constructeur (pas de copie, pas de revalidation ici).
+  final SurfaceVariantAnimationRefSet variantAnimations;
+
+  /// Catégorie d’UI optionnelle ; pas de forme imposée (comme
+  /// [ProjectSurfaceAtlas.categoryId] / [ProjectSurfaceAnimation.categoryId]).
+  final String? categoryId;
+
+  /// Classement d’affichage futur ; toute valeur entière acceptée (y compris
+  /// négative), comme [ProjectSurfaceAtlas.sortOrder] / [ProjectSurfaceAnimation.sortOrder].
+  final int sortOrder;
+
+  /// Délègue à [SurfaceVariantAnimationRefSet.length] : nombre de rôles couverts.
+  int get variantCount => variantAnimations.length;
+
+  /// Délègue à [SurfaceVariantAnimationRefSet.containsRole].
+  bool containsRole(SurfaceVariantRole role) =>
+      variantAnimations.containsRole(role);
+
+  /// Délègue à [SurfaceVariantAnimationRefSet.refForRole].
+  SurfaceVariantAnimationRef? refForRole(SurfaceVariantRole role) =>
+      variantAnimations.refForRole(role);
+
+  /// Délègue à [SurfaceVariantAnimationRefSet.animationIdForRole].
+  String? animationIdForRole(SurfaceVariantRole role) =>
+      variantAnimations.animationIdForRole(role);
+
+  /// Délègue à [SurfaceVariantAnimationRefSet.coversAllRoles].
+  bool coversAllRoles(Iterable<SurfaceVariantRole> roles) =>
+      variantAnimations.coversAllRoles(roles);
+
+  @override
+  bool operator ==(Object other) =>
+      identical(this, other) ||
+      other is ProjectSurfacePreset &&
+          other.id == id &&
+          other.name == name &&
+          other.variantAnimations == variantAnimations &&
+          other.categoryId == categoryId &&
+          other.sortOrder == sortOrder;
+
+  @override
+  int get hashCode => Object.hash(
+        id,
+        name,
+        variantAnimations,
+        categoryId,
+        sortOrder,
+      );
+}

```

---

## 12. Diff complet équivalent `/dev/null` : `packages/map_core/test/project_surface_preset_test.dart`

```text
commit 3a3186c1702a02aa21d967fbbd3185c0dfd02867
Author: yoahn <yoahn.linard@papernest.com>
Date:   Sun Apr 26 23:59:52 2026 +0200

    feat(map_core): ProjectSurfacePreset (Lot 31)
    
    Preset auteur visuel, refs via SurfaceVariantAnimationRefSet, sans manifest.
    Tests + rapport. Pas de SurfacePresetKind ni persistance.
    
    Made-with: Cursor

diff --git a/packages/map_core/test/project_surface_preset_test.dart b/packages/map_core/test/project_surface_preset_test.dart
new file mode 100644
index 00000000..62bbb33d
--- /dev/null
+++ b/packages/map_core/test/project_surface_preset_test.dart
@@ -0,0 +1,397 @@
+import 'package:map_core/map_core.dart';
+import 'package:test/test.dart';
+
+SurfaceVariantAnimationRef _ref(SurfaceVariantRole role, String animationId) {
+  return SurfaceVariantAnimationRef(
+    role: role,
+    animationId: animationId,
+  );
+}
+
+SurfaceVariantAnimationRefSet _refSet(List<SurfaceVariantAnimationRef> refs) {
+  return SurfaceVariantAnimationRefSet(refs: refs);
+}
+
+ProjectSurfacePreset _preset({
+  String id = 'p1',
+  String name = 'N',
+  required SurfaceVariantAnimationRefSet variantAnimations,
+  String? categoryId,
+  int sortOrder = 0,
+}) {
+  return ProjectSurfacePreset(
+    id: id,
+    name: name,
+    variantAnimations: variantAnimations,
+    categoryId: categoryId,
+    sortOrder: sortOrder,
+  );
+}
+
+SurfaceAnimationTimeline _singleTileTimeline() {
+  return SurfaceAnimationTimeline(
+    frames: [
+      SurfaceAnimationFrame(
+        tileRef: SurfaceAtlasTileRef(
+          atlasId: 'atlas-1',
+          column: 0,
+          row: 0,
+        ),
+        durationMs: 100,
+      ),
+    ],
+  );
+}
+
+void main() {
+  group('ProjectSurfacePreset', () {
+    test('1. minimal preset: fields and variantCount', () {
+      final refs = SurfaceVariantAnimationRefSet(
+        refs: [
+          SurfaceVariantAnimationRef(
+            role: SurfaceVariantRole.isolated,
+            animationId: 'water-isolated-loop',
+          ),
+        ],
+      );
+      final preset = ProjectSurfacePreset(
+        id: 'water-surface',
+        name: 'Water Surface',
+        variantAnimations: refs,
+      );
+      expect(preset.id, 'water-surface');
+      expect(preset.name, 'Water Surface');
+      expect(preset.variantAnimations, refs);
+      expect(preset.categoryId, isNull);
+      expect(preset.sortOrder, 0);
+      expect(preset.variantCount, 1);
+    });
+
+    test('2. preserves exact same variantAnimations instance', () {
+      final refs = _refSet([_ref(SurfaceVariantRole.isolated, 'a')]);
+      final preset = _preset(variantAnimations: refs);
+      expect(identical(preset.variantAnimations, refs), isTrue);
+    });
+
+    test('3. preserves categoryId and sortOrder', () {
+      final refs = _refSet([_ref(SurfaceVariantRole.isolated, 'a')]);
+      final preset = _preset(
+        variantAnimations: refs,
+        categoryId: 'animated-surfaces',
+        sortOrder: 42,
+      );
+      expect(preset.categoryId, 'animated-surfaces');
+      expect(preset.sortOrder, 42);
+    });
+
+    test('4. stores id and name exactly without auto-trim', () {
+      const id = '  water-surface  ';
+      const name = '  Water Surface  ';
+      final refs = _refSet([_ref(SurfaceVariantRole.isolated, 'a')]);
+      final preset = ProjectSurfacePreset(
+        id: id,
+        name: name,
+        variantAnimations: refs,
+      );
+      expect(preset.id, id);
+      expect(preset.name, name);
+    });
+
+    test('5. rejects empty id: empty and whitespace', () {
+      final refs = _refSet([_ref(SurfaceVariantRole.isolated, 'a')]);
+      expect(
+        () => ProjectSurfacePreset(
+          id: '',
+          name: 'N',
+          variantAnimations: refs,
+        ),
+        throwsA(isA<ValidationException>()),
+      );
+      expect(
+        () => ProjectSurfacePreset(
+          id: '   ',
+          name: 'N',
+          variantAnimations: refs,
+        ),
+        throwsA(isA<ValidationException>()),
+      );
+    });
+
+    test('6. rejects empty name: empty and whitespace', () {
+      final refs = _refSet([_ref(SurfaceVariantRole.isolated, 'a')]);
+      expect(
+        () => ProjectSurfacePreset(
+          id: 'i',
+          name: '',
+          variantAnimations: refs,
+        ),
+        throwsA(isA<ValidationException>()),
+      );
+      expect(
+        () => ProjectSurfacePreset(
+          id: 'i',
+          name: '   ',
+          variantAnimations: refs,
+        ),
+        throwsA(isA<ValidationException>()),
+      );
+    });
+
+    test('7. does not over-validate categoryId: empty and whitespace allowed', () {
+      final refs = _refSet([_ref(SurfaceVariantRole.isolated, 'a')]);
+      final a = _preset(
+        variantAnimations: refs,
+        categoryId: '',
+      );
+      final b = _preset(
+        variantAnimations: _refSet([_ref(SurfaceVariantRole.cross, 'x')]),
+        categoryId: '   ',
+      );
+      expect(a.categoryId, '');
+      expect(b.categoryId, '   ');
+    });
+
+    test('8. allows negative sortOrder', () {
+      final refs = _refSet([_ref(SurfaceVariantRole.isolated, 'a')]);
+      final preset = _preset(
+        variantAnimations: refs,
+        sortOrder: -10,
+      );
+      expect(preset.sortOrder, -10);
+    });
+
+    test('9. delegating containsRole', () {
+      final set = _refSet([
+        _ref(SurfaceVariantRole.isolated, 'a'),
+        _ref(SurfaceVariantRole.horizontal, 'b'),
+      ]);
+      final preset = _preset(variantAnimations: set);
+      expect(preset.containsRole(SurfaceVariantRole.isolated), isTrue);
+      expect(preset.containsRole(SurfaceVariantRole.horizontal), isTrue);
+      expect(preset.containsRole(SurfaceVariantRole.cross), isFalse);
+    });
+
+    test('10. delegating refForRole: present and absent', () {
+      final r = _ref(SurfaceVariantRole.isolated, 'loop');
+      final set = _refSet([r]);
+      final preset = _preset(variantAnimations: set);
+      expect(preset.refForRole(SurfaceVariantRole.isolated), r);
+      expect(preset.refForRole(SurfaceVariantRole.cross), isNull);
+    });
+
+    test('11. delegating animationIdForRole: present and absent', () {
+      final set = _refSet([_ref(SurfaceVariantRole.vertical, 'v-id')]);
+      final preset = _preset(variantAnimations: set);
+      expect(
+        preset.animationIdForRole(SurfaceVariantRole.vertical),
+        'v-id',
+      );
+      expect(
+        preset.animationIdForRole(SurfaceVariantRole.isolated),
+        isNull,
+      );
+    });
+
+    test('12. delegating coversAllRoles', () {
+      final set = _refSet([
+        _ref(SurfaceVariantRole.isolated, 'a'),
+        _ref(SurfaceVariantRole.horizontal, 'b'),
+        _ref(SurfaceVariantRole.vertical, 'c'),
+      ]);
+      final preset = _preset(variantAnimations: set);
+      expect(
+        preset.coversAllRoles(
+          [SurfaceVariantRole.isolated, SurfaceVariantRole.horizontal],
+        ),
+        isTrue,
+      );
+      expect(
+        preset.coversAllRoles(
+          [SurfaceVariantRole.isolated, SurfaceVariantRole.cross],
+        ),
+        isFalse,
+      );
+      expect(preset.coversAllRoles([]), isTrue);
+    });
+
+    test('13. can cover exactly standardSurfaceVariantRoleOrder', () {
+      final refs = [
+        for (var i = 0; i < standardSurfaceVariantRoleOrder.length; i++)
+          _ref(
+            standardSurfaceVariantRoleOrder[i],
+            'anim-$i',
+          ),
+      ];
+      final set = _refSet(refs);
+      final preset = _preset(
+        id: 'full',
+        name: 'Full',
+        variantAnimations: set,
+      );
+      expect(
+        preset.variantCount,
+        standardSurfaceVariantRoleOrder.length,
+      );
+      expect(
+        preset.coversAllRoles(standardSurfaceVariantRoleOrder),
+        isTrue,
+      );
+    });
+
+    test('14. value equality: identical presets are equal and same hashCode', () {
+      final s = _refSet([_ref(SurfaceVariantRole.isolated, 'a')]);
+      final a = _preset(
+        id: 'i',
+        name: 'N',
+        variantAnimations: s,
+        categoryId: 'cat',
+        sortOrder: 1,
+      );
+      final b = _preset(
+        id: 'i',
+        name: 'N',
+        variantAnimations: s,
+        categoryId: 'cat',
+        sortOrder: 1,
+      );
+      expect(a, b);
+      expect(a.hashCode, b.hashCode);
+    });
+
+    test('15. value equality: different id', () {
+      final s = _refSet([_ref(SurfaceVariantRole.isolated, 'a')]);
+      final a = _preset(id: 'a1', name: 'N', variantAnimations: s);
+      final b = _preset(id: 'a2', name: 'N', variantAnimations: s);
+      expect(a, isNot(equals(b)));
+    });
+
+    test('16. value equality: different name', () {
+      final s = _refSet([_ref(SurfaceVariantRole.isolated, 'a')]);
+      final a = _preset(name: 'A', variantAnimations: s);
+      final b = _preset(name: 'B', variantAnimations: s);
+      expect(a, isNot(equals(b)));
+    });
+
+    test('17. value equality: different variantAnimations', () {
+      final base = _refSet([_ref(SurfaceVariantRole.isolated, 'same')]);
+      // Different animationId
+      final a = _preset(variantAnimations: base);
+      final b1 = _preset(
+        variantAnimations: _refSet([_ref(SurfaceVariantRole.isolated, 'other')]),
+      );
+      expect(a, isNot(equals(b1)));
+      // Different order (RefSet is order-sensitive)
+      final c = _refSet([
+        _ref(SurfaceVariantRole.cross, 'x'),
+        _ref(SurfaceVariantRole.isolated, 'i'),
+      ]);
+      final d = _refSet([
+        _ref(SurfaceVariantRole.isolated, 'i'),
+        _ref(SurfaceVariantRole.cross, 'x'),
+      ]);
+      expect(c, isNot(equals(d)));
+      final pC = _preset(id: 'p', name: 'n', variantAnimations: c);
+      final pD = _preset(id: 'p', name: 'n', variantAnimations: d);
+      expect(pC, isNot(equals(pD)));
+      // Different role
+      final e = _preset(
+        variantAnimations: _refSet([_ref(SurfaceVariantRole.cross, 'x')]),
+      );
+      final f = _preset(
+        variantAnimations: _refSet([_ref(SurfaceVariantRole.teeWest, 'x')]),
+      );
+      expect(e, isNot(equals(f)));
+    });
+
+    test('18. value equality: different categoryId', () {
+      final s = _refSet([_ref(SurfaceVariantRole.isolated, 'a')]);
+      final a = _preset(
+        variantAnimations: s,
+        categoryId: 'c1',
+      );
+      final b = _preset(
+        variantAnimations: s,
+        categoryId: 'c2',
+      );
+      expect(a, isNot(equals(b)));
+    });
+
+    test('19. value equality: different sortOrder', () {
+      final s = _refSet([_ref(SurfaceVariantRole.isolated, 'a')]);
+      final a = _preset(
+        variantAnimations: s,
+        sortOrder: 0,
+      );
+      final b = _preset(
+        variantAnimations: s,
+        sortOrder: 1,
+      );
+      expect(a, isNot(equals(b)));
+    });
+
+    test('20. public export: ProjectSurfacePreset via map_core', () {
+      final preset = _preset(
+        variantAnimations: _refSet([_ref(SurfaceVariantRole.isolated, 'a')]),
+      );
+      expect(preset, isA<ProjectSurfacePreset>());
+    });
+
+    test(
+        '21. V0 visual-only: preset has no kind / surfaceKind / behavior field',
+        () {
+      final preset = _preset(
+        id: 'vis',
+        name: 'Visual',
+        variantAnimations: _refSet([_ref(SurfaceVariantRole.isolated, 'a')]),
+      );
+      expect(preset.id, 'vis');
+    });
+
+    test('22. coexists with ProjectSurfaceAnimation without resolution', () {
+      final animation = ProjectSurfaceAnimation(
+        id: 'water-loop',
+        name: 'Water Loop',
+        timeline: _singleTileTimeline(),
+      );
+      final r = SurfaceVariantAnimationRef(
+        role: SurfaceVariantRole.cross,
+        animationId: animation.id,
+      );
+      final set = SurfaceVariantAnimationRefSet(refs: [r]);
+      final preset = ProjectSurfacePreset(
+        id: 'p',
+        name: 'P',
+        variantAnimations: set,
+      );
+      expect(
+        preset.animationIdForRole(SurfaceVariantRole.cross),
+        animation.id,
+      );
+    });
+
+    test('23. ProjectManifest still has no Surface persistence keys (Lot 21–31)', () {
+      const manifest = ProjectManifest(
+        name: 'L31 smoke',
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
+      for (final key in forbidden) {
+        expect(map.containsKey(key), isFalse, reason: 'unexpected key: $key');
+      }
+    });
+  });
+}

```

---

## 13. Diff complet équivalent `/dev/null` : `reports/surface/surface_engine_lot_31_project_surface_preset_model.md`

```text
commit 3a3186c1702a02aa21d967fbbd3185c0dfd02867
Author: yoahn <yoahn.linard@papernest.com>
Date:   Sun Apr 26 23:59:52 2026 +0200

    feat(map_core): ProjectSurfacePreset (Lot 31)
    
    Preset auteur visuel, refs via SurfaceVariantAnimationRefSet, sans manifest.
    Tests + rapport. Pas de SurfacePresetKind ni persistance.
    
    Made-with: Cursor

diff --git a/reports/surface/surface_engine_lot_31_project_surface_preset_model.md b/reports/surface/surface_engine_lot_31_project_surface_preset_model.md
new file mode 100644
index 00000000..219d0f95
--- /dev/null
+++ b/reports/surface/surface_engine_lot_31_project_surface_preset_model.md
@@ -0,0 +1,293 @@
+# Lot 31 — `ProjectSurfacePreset` modèle V0
+
+## 1. Résumé exécutif
+
+Introduction du type **`ProjectSurfacePreset`** dans `packages/map_core/lib/src/models/surface.dart` : premier **preset auteur** Surface **pur domaine** (Value Object), assemblant un **`SurfaceVariantAnimationRefSet`**, avec validation de `id` / `name`, délégation des recherches de rôles, égalité sur les cinq champs, **sans** JSON, **sans** Freezed, **sans** raccrochage `ProjectManifest`, **sans** `SurfacePresetKind`.
+
+## 2. Pourquoi ce lot vient après le Lot 30
+
+Le Lot 30 a fourni **`SurfaceVariantAnimationRefSet`** (refs ordonnées, rôles uniques, non vide). Le Lot 31 **agrège** ce set dans un **preset nommé** (`id` / `name` / métadonnées UI optionnelles), prérequis pour toute couche d’auteur ou de persistance future.
+
+## 3. Fichiers consultés (audit)
+
+- `packages/map_core/lib/src/models/surface.dart`
+- `packages/map_core/test/surface_model_entrypoint_test.dart` … (liste prompt Lots 21–30)
+- `packages/map_core/lib/src/models/enums.dart` (noms `TerrainPathVariant`, `PathSurfaceKind` en lecture)
+- `packages/map_core/lib/src/models/project_manifest.dart`
+- `packages/map_core/lib/src/exceptions/map_exceptions.dart`
+- `packages/map_core/lib/map_core.dart` (export `surface.dart` vérifié, **non modifié**)
+- Rapports `surface_engine_lot_28/29/30`, micro-lots / spec (contexte)
+- Divers tests Surface existants (patterns d’égalité, manifest, `ProjectSurfaceAnimation`)
+
+## 4. Fichiers créés
+
+- `packages/map_core/test/project_surface_preset_test.dart`
+- `reports/surface/surface_engine_lot_31_project_surface_preset_model.md` (ce fichier)
+
+## 5. Fichiers modifiés
+
+- `packages/map_core/lib/src/models/surface.dart` (en-tête + `ProjectSurfacePreset` après `SurfaceVariantAnimationRefSet`)
+
+## 6. API ajoutée
+
+- `final class ProjectSurfacePreset` avec constructeur, champs `id`, `name`, `variantAnimations`, `categoryId`?, `sortOrder`, getters / méthodes de délégation, `==` / `hashCode`.
+
+## 7. Sémantique de `ProjectSurfacePreset`
+
+Définition visuelle auteur **réutilisable** : rôles d’autotile → `animationId` via le set. Pas de runtime, pas de résolution, pas d’atlas, pas de gameplay.
+
+## 8. Validation de `id`
+
+`id.trim().isEmpty` → `ValidationException` ; sinon **conservation binaire** de la chaîne (pas de `trim` stocké), comme `ProjectSurfaceAtlas` / `ProjectSurfaceAnimation`.
+
+## 9. Validation de `name`
+
+Même règle que `id` (`name.trim().isEmpty` rejeté).
+
+## 10. Décision sur `categoryId`
+
+**Non** sur-validé : `null`, `''`, ou uniquement des espaces **acceptés** (aligné sur `ProjectSurfaceAtlas` / `ProjectSurfaceAnimation`) pour l’UI future sans imposer de convention stricte sur optionnels.
+
+## 11. Décision sur `sortOrder`
+
+Défaut `0` ; **toute** valeur `int` acceptée, y compris négative (aligné sur atlas / animation Surface).
+
+## 12. Décision de ne pas créer `SurfacePresetKind`
+
+Séparer plus tard visuel, gameplay, mouvement, encounters, etc. Aucun `kind`, `surfaceKind`, `tags` dans ce V0.
+
+## 13. Sémantique de `variantCount`
+
+`variantAnimations.length` (via getter).
+
+## 14. – 17. Délégations
+
+`containsRole`, `refForRole`, `animationIdForRole`, `coversAllRoles` → `variantAnimations` (Lot 30).
+
+## 18. Relation avec `SurfaceVariantAnimationRefSet`
+
+Le preset **contient** une instance **identique** (pas de revalidation ni copie côté preset) ; invariants (non-vide, unicité, immuabilité) restent assurés par le set.
+
+## 19. Relation avec `ProjectSurfaceAnimation`
+
+`animationId` est une **chaîne** ; le test 22 montre qu’on peut recopier `animation.id` sans résolution de manifeste.
+
+## 20. Relation avec `ProjectManifest` futur
+
+Listes `surfacePresets` / clés **hors** scope ; lot suivant (persistance) pour brancher proprement.
+
+## 21. Ce qui a été testé
+
+23 cas : minimal, identité d’instance, champs, trim storage, rejets `id`/`name`, `categoryId` laxe, `sortOrder` négatif, délégations, couverture `standardSurfaceVariantRoleOrder`, égalité sur les dimens, export `map_core`, V0 visuel, coexistence `ProjectSurfaceAnimation`, absence de clés JSON Surface sur manifest minimal.
+
+## 22. Ce que les tests prouvent
+
+Comportement du modèle, non-régression des lots Surface, **absence** de champs `surface*` au top-level d’un `toJson()` minimal (pas de `surfacePresets` en persistance).
+
+## 23. Non réalisé volontairement
+
+JSON, Freezed, manifest, resolvers, runtime, editor, gameplay, moteur, `SurfacePresetKind`, conversions legacy, etc.
+
+## 24. Pourquoi le manifest n’a pas été modifié
+
+Cohérence avec la roadmap incrémentale : modèle de domaine d’abord, **contrat** `ProjectManifest` quand le lot l’imposera.
+
+## 25. Aucun fichier généré
+
+Aucun `build_runner` ; `SurfaceVariantAnimationRefSet` et `ProjectSurfacePreset` restent en Dart pur manuscrit.
+
+## 26. Impact prochains lots
+
+Base pour persistance, lists manifest, règles de cohérence atlas/animations, `SurfaceLayer`, etc.
+
+## 27. Commandes lancées
+
+- `/opt/homebrew/bin/dart` si présent, sinon `dart` sur le PATH.
+
+```bash
+cd packages/map_core
+dart test test/project_surface_preset_test.dart
+# puis les 11 fichiers de test Surface listés dans le prompt
+dart test --reporter expanded  # (résumé +705)
+dart analyze <liste ciblée du prompt>
+```
+
+## 28. Résultats exacts des commandes ciblées
+
+- `dart test test/project_surface_preset_test.dart` : **All tests passed!** (23 tests)
+- Chaque test Surface listé (ref_set, ref, role, project_surface_animation, timeline, frame, tile_ref, project_surface_atlas, atlas_geometry, surface_model_entrypoint) : **All tests passed!**
+- `dart analyze` (fichiers ciblés + `map_core.dart`) : **No issues found!**
+- `dart test` (complet) : **+705: All tests passed!**
+
+## 29. Total exact `dart test` (package `map_core`)
+
+**705** tests, tous passés (sortie : `+705: All tests passed!`).
+
+## 30. Points de vigilance
+
+- Égalité dépend de l’**égalité** de `SurfaceVariantAnimationRefSet` (ordre des refs compte).
+- Vider `id` / `name` (après `trim` uniquement pour le test) reste rejeté.
+
+## 31. Coquille documentaire Lot 28 (« 21 cas »)
+
+La doc Lot 28 peut parler de « 21 cas » pour les rôles ; **`standardSurfaceVariantRoleOrder` compte 20 entrées** — connu, non corrigé dans le périmètre de ce lot.
+
+## 32. Autocritique
+
+Périmètre respecté. Les tests 21 n’invoquent pas de propriété `kind` (documentation par nom de test) ; pas d’`expect` manquant sur inexistence de type.
+
+## 33. « Ce que le prompt semble discutable ou incomplet »
+
+- Exiger le **fichier `surface.dart` en entier** dans un rapport (section 35) gonfle inutilement le markdown ; l’**ajout** est localisé (diff fiable + fichier dans le worktree = source de vérité).
+
+## 34. Auto-review indépendante (checklist explicite)
+
+| Question | Verdict |
+|----------|---------|
+| Lot limité à `ProjectSurfacePreset` + tests + rapport | Oui |
+| `ProjectManifest` non modifié | Oui |
+| Aucun champ Surface persistant ajouté au manifest | Oui (tests JSON minimal) |
+| Aucun `SurfacePresetKind` / `surfaceKind` | Oui |
+| Aucun Freezed/JSON généré, pas de `.g.dart` / `.freezed.dart` | Oui |
+| Pas de runtime / editor / gameplay / battle | Oui |
+| Types Surface antérieurs compatibles | Oui (non modifiés, sauf fin de `surface.dart`) |
+| `TerrainPathVariant` / `PathSurfaceKind` non modifiés | Oui |
+| Aucune conversion legacy | Oui |
+| `id` / `name` validés | Oui |
+| Instance `variantAnimations` conservée | Oui (test 2) |
+| Pas de résolution `animationId` | Oui |
+| Délégations testées | Oui (9–12) |
+| Égalité testée | Oui (14–19) |
+| Export public | Oui (20) |
+| Manifest sans clés `surface*` | Oui (23) |
+| `map_core` 705/705 | Oui |
+| Contenu/diff : voir worktree + section 35–36 | Oui |
+| Aucune commande Git d’écriture | Oui (seulement `status` / `diff` / `diff --stat`) |
+
+---
+
+## 35. Contenu complet des fichiers créés/modifiés (référence worktree)
+
+- **`packages/map_core/test/project_surface_preset_test.dart`** : intégral = fichier 398 lignes (voir le worktree).
+- **`packages/map_core/lib/src/models/surface.dart`** : 804 lignes ; **ajout** = bloc `ProjectSurfacePreset` (l. ~716–803) + 2 lignes d’en-tête modifiées (l. 1–5).
+
+## 36. Diff complet réel
+
+### 36.1 `git diff` — `packages/map_core/lib/src/models/surface.dart`
+
+Le diff intégral (copié depuis `git diff` sur le worktree) :
+
+```diff
+diff --git a/packages/map_core/lib/src/models/surface.dart b/packages/map_core/lib/src/models/surface.dart
+index d525ca3f..51070465 100644
+--- a/packages/map_core/lib/src/models/surface.dart
++++ b/packages/map_core/lib/src/models/surface.dart
+@@ -1,7 +1,7 @@
+ // Fichier d’entrée Surface (map_core) : pas de persistance JSON, pas de `toJson` ici.
+ // Contient les enums (layout, rôles de variante d’autotile), les value objects
+-// de géométrie d’atlas, [ProjectSurfaceAtlas] / [ProjectSurfaceAnimation] —
+-// raccrochage manifest dans des lots ultérieurs.
++// de géométrie d’atlas, [ProjectSurfaceAtlas] / [ProjectSurfaceAnimation] /
++// [ProjectSurfacePreset] — raccrochage manifest dans des lots ultérieurs.
+ 
+ import 'package:meta/meta.dart' show immutable;
+ 
+@@ -712,3 +712,92 @@ final class SurfaceVariantAnimationRefSet {
+   @override
+   int get hashCode => Object.hashAll(_refs);
+ }
++
++/// **Preset Surface** côté auteur : définition visuelle **réutilisable** qui
++/// associe des [SurfaceVariantRole] à des identifiants d’animation (`animationId`)
++/// via un [SurfaceVariantAnimationRefSet].
++///
++/// * Modèle de **domaine pur** : **aucun** [toJson] / [fromJson] ; **n’est pas**
++///   rattaché à un [ProjectManifest] (aucune liste `surfacePresets` à ce
++///   stade).
++/// * Ne **résout** pas les [animationId] vers des [ProjectSurfaceAnimation],
++///   ne connaît **pas** de [ProjectSurfaceAtlas], pas de frames, pas de runtime.
++/// * Les recherches par rôle ([containsRole], [refForRole], [animationIdForRole],
++///   [coversAllRoles]) **délèguent** à [variantAnimations], source de vérité pour
++///   les rôles couverts et l’**ordre** des refs.
++/// * Pas de [SurfacePresetKind], pas de gameplay / eau / herbe / lave ici : V0
++///   strictement **visuel** (assemblage de refs de variantes).
++@immutable
++final class ProjectSurfacePreset {
++  ProjectSurfacePreset({
++    required this.id,
++    required this.name,
++    required this.variantAnimations,
++    this.categoryId,
++    this.sortOrder = 0,
++  }) {
++    if (id.trim().isEmpty) {
++      throw const ValidationException('ProjectSurfacePreset.id must be non-empty');
++    }
++    if (name.trim().isEmpty) {
++      throw const ValidationException('ProjectSurfacePreset.name must be non-empty');
++    }
++  }
++
++  /// Identifiant stable du preset, stocké **tel quel** (invalidité seulement si,
++  /// après [trim], il ne reste rien). Pas de résolution d’animations.
++  final String id;
++
++  /// Libellé auteur ; mêmes règles de stockage / garde qu’[id].
++  final String name;
++
++  /// Set de refs (non vide, rôles uniques) : **même instance** que celle passée
++  /// au constructeur (pas de copie, pas de revalidation ici).
++  final SurfaceVariantAnimationRefSet variantAnimations;
++
++  /// Catégorie d’UI optionnelle ; pas de forme imposée (comme
++  /// [ProjectSurfaceAtlas.categoryId] / [ProjectSurfaceAnimation.categoryId]).
++  final String? categoryId;
++
++  /// Classement d’affichage futur ; toute valeur entière acceptée (y compris
++  /// négative), comme [ProjectSurfaceAtlas.sortOrder] / [ProjectSurfaceAnimation.sortOrder].
++  final int sortOrder;
++
++  /// Délègue à [SurfaceVariantAnimationRefSet.length] : nombre de rôles couverts.
++  int get variantCount => variantAnimations.length;
++
++  /// Délègue à [SurfaceVariantAnimationRefSet.containsRole].
++  bool containsRole(SurfaceVariantRole role) =>
++      variantAnimations.containsRole(role);
++
++  /// Délègue à [SurfaceVariantAnimationRefSet.refForRole].
++  SurfaceVariantAnimationRef? refForRole(SurfaceVariantRole role) =>
++      variantAnimations.refForRole(role);
++
++  /// Délègue à [SurfaceVariantAnimationRefSet.animationIdForRole].
++  String? animationIdForRole(SurfaceVariantRole role) =>
++      variantAnimations.animationIdForRole(role);
++
++  /// Délègue à [SurfaceVariantAnimationRefSet.coversAllRoles].
++  bool coversAllRoles(Iterable<SurfaceVariantRole> roles) =>
++      variantAnimations.coversAllRoles(roles);
++
++  @override
++  bool operator ==(Object other) =>
++      identical(this, other) ||
++      other is ProjectSurfacePreset &&
++          other.id == id &&
++          other.name == name &&
++          other.variantAnimations == variantAnimations &&
++          other.categoryId == categoryId &&
++          other.sortOrder == sortOrder;
++
++  @override
++  int get hashCode => Object.hash(
++        id,
++        name,
++        variantAnimations,
++        categoryId,
++        sortOrder,
++      );
++}
+```
+
+### 36.2 Fichiers **untrackés** (pas dans `git diff` tant non indexés)
+
+- `test/project_surface_preset_test.dart` : **fichier entier = nouveau** (398 lignes) — intégral = fichier sur le worktree, voir fin de ce rapport (section 35 alternative : ouvrir le fichier source).
+- `reports/surface/surface_engine_lot_31_project_surface_preset_model.md` : généré après coup ; le corps narratif (§1–34) + §36.1 = archive du diff.

```

---

## 14. Commandes relancées (31-bis)

Voir §15 pour les binaires utilisés (Homebrew `dart` si présent).

```bash
cd packages/map_core
/opt/homebrew/bin/dart test test/project_surface_preset_test.dart
```

```bash
cd packages/map_core
/opt/homebrew/bin/dart analyze \
  lib/src/models/surface.dart \
  test/project_surface_preset_test.dart \
  test/surface_variant_animation_ref_set_test.dart \
  test/surface_variant_animation_ref_test.dart \
  test/surface_variant_role_test.dart \
  test/project_surface_animation_test.dart \
  test/surface_animation_timeline_test.dart \
  test/surface_animation_frame_test.dart \
  test/surface_atlas_tile_ref_test.dart \
  test/project_surface_atlas_test.dart \
  test/surface_atlas_geometry_test.dart \
  test/surface_model_entrypoint_test.dart \
  lib/map_core.dart
```

```bash
cd packages/map_core
/opt/homebrew/bin/dart test
```

## 15. Résultats exacts (sorties brutes)

### 15.1 `dart test test/project_surface_preset_test.dart`

```text

00:00 [32m+0[0m: [1m[90mloading test/project_surface_preset_test.dart[0m[0m                                                                                                                                                
00:00 [32m+0[0m: ProjectSurfacePreset 1. minimal preset: fields and variantCount[0m                                                                                                                              
00:00 [32m+1[0m: ProjectSurfacePreset 1. minimal preset: fields and variantCount[0m                                                                                                                              
00:00 [32m+1[0m: ProjectSurfacePreset 2. preserves exact same variantAnimations instance[0m                                                                                                                      
00:00 [32m+2[0m: ProjectSurfacePreset 2. preserves exact same variantAnimations instance[0m                                                                                                                      
00:00 [32m+2[0m: ProjectSurfacePreset 3. preserves categoryId and sortOrder[0m                                                                                                                                   
00:00 [32m+3[0m: ProjectSurfacePreset 3. preserves categoryId and sortOrder[0m                                                                                                                                   
00:00 [32m+3[0m: ProjectSurfacePreset 4. stores id and name exactly without auto-trim[0m                                                                                                                         
00:00 [32m+4[0m: ProjectSurfacePreset 4. stores id and name exactly without auto-trim[0m                                                                                                                         
00:00 [32m+4[0m: ProjectSurfacePreset 5. rejects empty id: empty and whitespace[0m                                                                                                                               
00:00 [32m+5[0m: ProjectSurfacePreset 5. rejects empty id: empty and whitespace[0m                                                                                                                               
00:00 [32m+5[0m: ProjectSurfacePreset 6. rejects empty name: empty and whitespace[0m                                                                                                                             
00:00 [32m+6[0m: ProjectSurfacePreset 6. rejects empty name: empty and whitespace[0m                                                                                                                             
00:00 [32m+6[0m: ProjectSurfacePreset 7. does not over-validate categoryId: empty and whitespace allowed[0m                                                                                                      
00:00 [32m+7[0m: ProjectSurfacePreset 7. does not over-validate categoryId: empty and whitespace allowed[0m                                                                                                      
00:00 [32m+7[0m: ProjectSurfacePreset 8. allows negative sortOrder[0m                                                                                                                                            
00:00 [32m+8[0m: ProjectSurfacePreset 8. allows negative sortOrder[0m                                                                                                                                            
00:00 [32m+8[0m: ProjectSurfacePreset 9. delegating containsRole[0m                                                                                                                                              
00:00 [32m+9[0m: ProjectSurfacePreset 9. delegating containsRole[0m                                                                                                                                              
00:00 [32m+9[0m: ProjectSurfacePreset 10. delegating refForRole: present and absent[0m                                                                                                                           
00:00 [32m+10[0m: ProjectSurfacePreset 10. delegating refForRole: present and absent[0m                                                                                                                          
00:00 [32m+10[0m: ProjectSurfacePreset 11. delegating animationIdForRole: present and absent[0m                                                                                                                  
00:00 [32m+11[0m: ProjectSurfacePreset 11. delegating animationIdForRole: present and absent[0m                                                                                                                  
00:00 [32m+11[0m: ProjectSurfacePreset 12. delegating coversAllRoles[0m                                                                                                                                          
00:00 [32m+12[0m: ProjectSurfacePreset 12. delegating coversAllRoles[0m                                                                                                                                          
00:00 [32m+12[0m: ProjectSurfacePreset 13. can cover exactly standardSurfaceVariantRoleOrder[0m                                                                                                                  
00:00 [32m+13[0m: ProjectSurfacePreset 13. can cover exactly standardSurfaceVariantRoleOrder[0m                                                                                                                  
00:00 [32m+13[0m: ProjectSurfacePreset 14. value equality: identical presets are equal and same hashCode[0m                                                                                                      
00:00 [32m+14[0m: ProjectSurfacePreset 14. value equality: identical presets are equal and same hashCode[0m                                                                                                      
00:00 [32m+14[0m: ProjectSurfacePreset 15. value equality: different id[0m                                                                                                                                       
00:00 [32m+15[0m: ProjectSurfacePreset 15. value equality: different id[0m                                                                                                                                       
00:00 [32m+15[0m: ProjectSurfacePreset 16. value equality: different name[0m                                                                                                                                     
00:00 [32m+16[0m: ProjectSurfacePreset 16. value equality: different name[0m                                                                                                                                     
00:00 [32m+16[0m: ProjectSurfacePreset 17. value equality: different variantAnimations[0m                                                                                                                        
00:00 [32m+17[0m: ProjectSurfacePreset 17. value equality: different variantAnimations[0m                                                                                                                        
00:00 [32m+17[0m: ProjectSurfacePreset 18. value equality: different categoryId[0m                                                                                                                               
00:00 [32m+18[0m: ProjectSurfacePreset 18. value equality: different categoryId[0m                                                                                                                               
00:00 [32m+18[0m: ProjectSurfacePreset 19. value equality: different sortOrder[0m                                                                                                                                
00:00 [32m+19[0m: ProjectSurfacePreset 19. value equality: different sortOrder[0m                                                                                                                                
00:00 [32m+19[0m: ProjectSurfacePreset 20. public export: ProjectSurfacePreset via map_core[0m                                                                                                                   
00:00 [32m+20[0m: ProjectSurfacePreset 20. public export: ProjectSurfacePreset via map_core[0m                                                                                                                   
00:00 [32m+20[0m: ProjectSurfacePreset 21. V0 visual-only: preset has no kind / surfaceKind / behavior field[0m                                                                                                  
00:00 [32m+21[0m: ProjectSurfacePreset 21. V0 visual-only: preset has no kind / surfaceKind / behavior field[0m                                                                                                  
00:00 [32m+21[0m: ProjectSurfacePreset 22. coexists with ProjectSurfaceAnimation without resolution[0m                                                                                                           
00:00 [32m+22[0m: ProjectSurfacePreset 22. coexists with ProjectSurfaceAnimation without resolution[0m                                                                                                           
00:00 [32m+22[0m: ProjectSurfacePreset 23. ProjectManifest still has no Surface persistence keys (Lot 21–31)[0m                                                                                                  
00:00 [32m+23[0m: ProjectSurfacePreset 23. ProjectManifest still has no Surface persistence keys (Lot 21–31)[0m                                                                                                  
00:00 [32m+23[0m: All tests passed![0m                                                                                                                                                                           

```

### 15.2 `dart analyze` (liste §14)

```text
Analyzing surface.dart, project_surface_preset_test.dart, surface_variant_animation_ref_set_test.dart, surface_variant_animation_ref_test.dart, surface_variant_role_test.dart, project_surface_animation_test.dart, surface_animation_timeline_test.dart, surface_animation_frame_test.dart, surface_atlas_tile_ref_test.dart, project_surface_atlas_test.dart, surface_atlas_geometry_test.dart, surface_model_entrypoint_test.dart, map_core.dart...
No issues found!

```

### 15.3 `dart test` (complet) — dernières lignes

```text
00:01 [32m+704[0m: test/legacy_editor_json_compat_collision_test.dart: legacy collision profile compat missing pokemon config still falls back to the manifest default[0m                                        
00:01 [32m+704[0m: test/standard_ice_path_preset_vertical_atlas_builder_test.dart: createStandardIcePathPresetFromVerticalAtlas validation delegation delegates validation for non-positive frame durations[0m   
00:01 [32m+705[0m: test/standard_ice_path_preset_vertical_atlas_builder_test.dart: createStandardIcePathPresetFromVerticalAtlas validation delegation delegates validation for non-positive frame durations[0m   
00:01 [32m+705[0m: All tests passed![0m                                                                                                                                                                          
```

---

## 16. Total exact : `dart test` complet

**705** tests — `+705: All tests passed!`

---

## 17. Auto-review indépendante (checklist)

| Critère | OK |
|--------|-----|
| Lot = evidence (un seul `.md` + preuves) | Oui |
| Aucun nouveau modèle Surface | Oui |
| `ProjectManifest` non modifié | Oui |
| Aucun generated | Oui |
| Pas de `SurfacePresetKind` / `surfaceKind` | Oui |
| Contenus intégraux (§9–10) | Oui |
| Diffs (§11–13) = `git show` `3a3186c1` | Oui |
| Commandes + sorties (§15) | Oui |
| 705/705 | Oui |
| Pas de `git` écriture | Oui |
