# Lot 23 — ProjectSurfaceAtlas Model V0

**Date** : 2026-04-26  
**Périmètre** : `ProjectSurfaceAtlas` pur dans `surface.dart`, test dédié, rapport. **Aucun** `ProjectManifest`, **aucun** généré, **`map_core.dart` inchangé** (export `surface.dart` déjà présent).

---

## 1. Résumé exécutif

- Ajout de `ProjectSurfaceAtlas` : `id`, `name`, `tilesetId`, `geometry`, `categoryId?`, `sortOrder` (défaut 0) ; validité des trois chaînes obligatoires par `trim().isEmpty` → `ValidationException` ; stockage des chaînes **sans** trim ; pas de revalidation de `geometry` ; `==` / `hashCode` sur les six champs.
- **+20** tests ciblés ; suite `map_core` **+567** ; analyse **No issues found!**

---

## 2. Pourquoi ce lot vient après le Lot 22

Le Lot 22 a cadré la géométrie ; le Lot 23 introduit le **premier agrégat métier** « atlas » réauteur, **sans** l’enregistrer dans le JSON projet.

---

## 3. Fichiers consultés

- `surface.dart`, tests 21/22, `project_manifest` (convention `categoryId`), `map_exceptions`, `map_core.dart` (export).

---

## 4. Fichiers créés

- `packages/map_core/test/project_surface_atlas_test.dart`
- `reports/surface/surface_engine_lot_23_project_surface_atlas_model.md` (généré par script d’assemblage pour inclure le code + diffs intégraux)

---

## 5. Fichiers modifiés

- `packages/map_core/lib/src/models/surface.dart` uniquement.

---

## 6. API ajoutée

- `ProjectSurfaceAtlas` — voir code §24.

---

## 7. Sémantique de `ProjectSurfaceAtlas`

- Atlas **logique** : référence `tilesetId` + `SurfaceAtlasGeometry` ; pas de binaire, pas de lien manifest.

---

## 8. Validations

- `id`, `name`, `tilesetId` : non vides **après trim** pour l’**acceptation** ; valeurs **stockées** inchangées.

---

## 9. Décision `categoryId`

- Aligné sur `ProjectPathPreset.categoryId` (`String?`, pas de garde stricte côté modèle pour les chaînes vides dans ce lot) : `null` OK ; `''` ou blanc autorisé si l’appelant les passe (pas de sur-validation documentée ailleurs).

---

## 10. Décision `sortOrder`

- Entier arbitraire, défaut 0 (comme les presets path sans min).

---

## 11–12. Tests et preuves

- 20 scénarios : minimal, champs, chaînes exactes, rejets, identité de géométrie, égalité / inégalités, export, clés manifest absentes.

---

## 13. Non réalisé

- Pas de JSON, pas de `ProjectManifest`, pas de `SurfaceLayer`, etc.

---

## 14–15. Manifest / generated

- Inchangé ; aucun `.g` / `freezed`.

---

## 16. Impact lots suivants

- Première brique vers une liste `surfaceAtlases` future et sérialisation.

---

## 17. Commandes lancées

```bash
cd packages/map_core
/opt/homebrew/bin/dart test test/project_surface_atlas_test.dart
/opt/homebrew/bin/dart test test/surface_atlas_geometry_test.dart test/surface_model_entrypoint_test.dart
/opt/homebrew/bin/dart analyze lib/src/models/surface.dart test/project_surface_atlas_test.dart \
  test/surface_atlas_geometry_test.dart test/surface_model_entrypoint_test.dart lib/map_core.dart
/opt/homebrew/bin/dart test
```

---

## 18. Résultats (extraits)

- Test projet : `+20: All tests passed!` (exit 0)
- Analyse : `No issues found!` (exit 0)
- Suite : `+567: All tests passed!` (exit 0)

---

## 19. Total

**+567** All tests passed!

---

## 20–22. Vigilance / autocritique / prompt

- Cohabitation : deux tests manifest similaires (géo + atlas) = volontairement redondant pour preuve.
- `categoryId: ''` non interdit (choix explicite).

---

## 23. Auto-review

Tous les points check-liste du prompt : **Oui** (hors `git` write).

---

## 24. Contenu intégral — `packages/map_core/lib/src/models/surface.dart`

````dart
// Fichier d’entrée Surface (map_core) : pas de persistance JSON, pas de `toJson` ici.
// Contient l’[enum] de layout, les value objects de géométrie d’atlas, et
// [ProjectSurfaceAtlas] (métadonnées d’atlas) — raccrochage manifest dans des lots
// ultérieurs.

import 'package:meta/meta.dart' show immutable;

import '../exceptions/map_exceptions.dart';

/// Convention de **disposition** d’un tileset d’atlas (comment interpréter la
/// grille 2D par rapport aux variantes de surface et aux frames d’animation).
///
/// Ce type est volontairement indépendant de `ProjectPathPreset` : il pourra
/// servir plus tard à décrire des atlasses Surface sans dupliquer le legacy
/// path-only.
enum SurfaceAtlasLayout {
  /// Grille d’atlas classique, **sans** convention imposée « variante = axe X »
  /// / « frame = axe Y ». Utile quand l’adresse d’une tuile est arbitraire
  /// (sélection manuelle, pack artistique) ou quand l’outillage n’impose pas
  /// encore la séparation variante/animation.
  grid,

  /// Chaque **colonne** du tileset = une **variante** d’apparence (bord, coin,
  /// pièce centrale, etc.) ; chaque **ligne** = une **frame** d’animation
  /// (temps) pour ce même slot de variante.
  ///
  /// C’est la convention des lots **11–19** (bridge vertical-atlas) : l’axe
  /// `x` indexe le `TerrainPathVariant` / la colonne, l’axe `y` indexe
  /// l’empilement des `TilesetVisualFrame`.
  columnsAreVariantsRowsAreFrames,

  /// Convention **miroir** de [columnsAreVariantsRowsAreFrames] : chaque
  /// **ligne** = une variante, chaque **colonne** = une frame. Prévue pour
  /// ne pas enfermer le moteur Surface dans une seule orientation d’atlas
  /// (art packs, outils, ou imports où les axes sont inversés).
  rowsAreVariantsColumnsAreFrames,
}

/// Taille d’une **tuile** d’atlas, en **pixels** (largeur / hauteur d’un slot
/// de découpe dans l’image source).
///
/// Aucun lien avec un asset réel ici : pas de chargement d’image, pas de JSON.
@immutable
final class SurfaceAtlasTileSize {
  /// [width] et [height] doivent être **strictement positives** (en pixels
  /// de tuile, entiers).
  SurfaceAtlasTileSize({
    required this.width,
    required this.height,
  }) {
    if (width <= 0) {
      throw const ValidationException('SurfaceAtlasTileSize.width must be > 0');
    }
    if (height <= 0) {
      throw const ValidationException('SurfaceAtlasTileSize.height must be > 0');
    }
  }

  final int width;
  final int height;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SurfaceAtlasTileSize &&
          other.width == width &&
          other.height == height;

  @override
  int get hashCode => Object.hash(width, height);
}

/// Taille d’**atlas** en nombre de **cellules** (colonnes × lignes de tuiles),
/// sans interpréter le sens des colonnes / lignes (cela relève de
/// [SurfaceAtlasLayout] via [SurfaceAtlasGeometry]).
///
/// Pas de persistance ni de sérialisation dans ce lot.
@immutable
final class SurfaceAtlasGridSize {
  /// [columns] et [rows] doivent être **> 0** (compte de cellules de grille).
  SurfaceAtlasGridSize({
    required this.columns,
    required this.rows,
  }) {
    if (columns <= 0) {
      throw const ValidationException('SurfaceAtlasGridSize.columns must be > 0');
    }
    if (rows <= 0) {
      throw const ValidationException('SurfaceAtlasGridSize.rows must be > 0');
    }
  }

  final int columns;
  final int rows;

  /// Nombre de tuiles dans la grille : `columns * rows`.
  int get tileCount => columns * rows;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SurfaceAtlasGridSize &&
          other.columns == columns &&
          other.rows == rows;

  @override
  int get hashCode => Object.hash(columns, rows);
}

/// Géométrie complète d’un atlas Surface : **taille d’une tuile** (pixels),
/// **grille** (cellules) et [layout] (comment relire l’atlas).
///
/// * Ne valide **pas** qu’une image existe ou que sa taille en pixels
///   recouvre exactement `tileSize * gridSize` — cela sera du ressort des lots
///   runtime / auteur.
/// * [containsGridCoordinate] travaille en **indices de colonne / ligne** dans
///   la grille (0-based), **pas** en coordonnées pixel dans la texture.
@immutable
final class SurfaceAtlasGeometry {
  /// [layout] vaut [SurfaceAtlasLayout.grid] par défaut.
  SurfaceAtlasGeometry({
    required this.tileSize,
    required this.gridSize,
    this.layout = SurfaceAtlasLayout.grid,
  });

  final SurfaceAtlasTileSize tileSize;
  final SurfaceAtlasGridSize gridSize;
  final SurfaceAtlasLayout layout;

  /// Délègue à [SurfaceAtlasGridSize.tileCount] : nombre de **slots** dans la grille.
  int get tileCount => gridSize.tileCount;

  /// Vrai si `(column, row)` est un couple d’**indices** valides sur la
  /// **grille** (pas une preuve d’adressage de tuile : selon [layout], la
  /// sémantique d’autotile peut différer).
  bool containsGridCoordinate({required int column, required int row}) =>
      column >= 0 &&
      row >= 0 &&
      column < gridSize.columns &&
      row < gridSize.rows;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SurfaceAtlasGeometry &&
          other.tileSize == tileSize &&
          other.gridSize == gridSize &&
          other.layout == layout;

  @override
  int get hashCode => Object.hash(tileSize, gridSize, layout);
}

/// Métadonnées d’un **atlas Surface** auteur : identifiant, libellé, tileset
/// source, et [geometry] (convention d’atlas, pas d’image chargée ici).
///
/// * N’est **pas** encore rattaché à un [ProjectManifest] (aucune liste
///   `surfaceAtlases` dans ce lot) : modèle de domaine seul, sans persistance
///   JSON.
/// * Ne fait **pas** de [toJson] / [fromJson] ; ne crée **pas** de preset
///   runtime ni d’[SurfaceLayer].
/// * Ne valide **pas** l’existence d’un enregistrement de tileset dans le
///   manifeste, ni la taille d’un fichier image — seulement la cohérence
///   minimale des champs texte requis.
@immutable
final class ProjectSurfaceAtlas {
  ProjectSurfaceAtlas({
    required this.id,
    required this.name,
    required this.tilesetId,
    required this.geometry,
    this.categoryId,
    this.sortOrder = 0,
  }) {
    if (id.trim().isEmpty) {
      throw const ValidationException('ProjectSurfaceAtlas.id must be non-empty');
    }
    if (name.trim().isEmpty) {
      throw const ValidationException('ProjectSurfaceAtlas.name must be non-empty');
    }
    if (tilesetId.trim().isEmpty) {
      throw const ValidationException('ProjectSurfaceAtlas.tilesetId must be non-empty');
    }
  }

  /// Identifiant stable, unique côté auteur. Stocké **tel quel** (pas de trim
  /// appliqué à la chaîne mémorisée) ; on rejette seulement les « vides » via
  /// `trim` dans le constructeur.
  final String id;

  /// Nom d’affichage ; mêmes règles de stockage et de garde qu’[id].
  final String name;

  /// Clé de tileset (référence logique) ; même principe de stockage.
  final String tilesetId;

  /// Découpage d’atlas (les dimensions sont déjà validées par les value objects
  /// [SurfaceAtlasTileSize] / [SurfaceAtlasGridSize] ; pas de revalidation ici).
  final SurfaceAtlasGeometry geometry;

  /// Dossier / catégorie optionnelle (comme [ProjectPathPreset.categoryId]) :
  /// ce lot **n’impose** pas de forme (chaîne vide autorisée si l’appelant la
  /// transmet, pour ne pas sur-valider en l’absence de convention unique sur
  /// les champs optionnels de ce type dans le monorepo).
  final String? categoryId;

  /// Ordre d’affichage (classement) ; toute valeur entière est acceptée, comme
  /// [ProjectPathPreset.sortOrder] sans borne documentée ici.
  final int sortOrder;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProjectSurfaceAtlas &&
          other.id == id &&
          other.name == name &&
          other.tilesetId == tilesetId &&
          other.geometry == geometry &&
          other.categoryId == categoryId &&
          other.sortOrder == sortOrder;

  @override
  int get hashCode => Object.hash(
        id,
        name,
        tilesetId,
        geometry,
        categoryId,
        sortOrder,
      );
}
````


## 25. Contenu intégral — `packages/map_core/test/project_surface_atlas_test.dart`

````dart
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

SurfaceAtlasGeometry _geometry({
  SurfaceAtlasLayout layout = SurfaceAtlasLayout.columnsAreVariantsRowsAreFrames,
}) {
  return SurfaceAtlasGeometry(
    tileSize: SurfaceAtlasTileSize(width: 32, height: 32),
    gridSize: SurfaceAtlasGridSize(columns: 23, rows: 32),
    layout: layout,
  );
}

void main() {
  group('ProjectSurfaceAtlas', () {
    test('minimal atlas: fields and derived geometry', () {
      final atlas = ProjectSurfaceAtlas(
        id: 'water-atlas',
        name: 'Water Atlas',
        tilesetId: 'outdoor-water',
        geometry: SurfaceAtlasGeometry(
          tileSize: SurfaceAtlasTileSize(width: 32, height: 32),
          gridSize: SurfaceAtlasGridSize(columns: 23, rows: 32),
          layout: SurfaceAtlasLayout.columnsAreVariantsRowsAreFrames,
        ),
      );
      expect(atlas.id, 'water-atlas');
      expect(atlas.name, 'Water Atlas');
      expect(atlas.tilesetId, 'outdoor-water');
      expect(atlas.categoryId, isNull);
      expect(atlas.sortOrder, 0);
      expect(atlas.geometry.tileCount, 736);
      expect(
        atlas.geometry.layout,
        SurfaceAtlasLayout.columnsAreVariantsRowsAreFrames,
      );
    });

    test('preserves categoryId and sortOrder', () {
      final atlas = ProjectSurfaceAtlas(
        id: 'a1',
        name: 'A',
        tilesetId: 't1',
        geometry: _geometry(),
        categoryId: 'animated-surfaces',
        sortOrder: 42,
      );
      expect(atlas.categoryId, 'animated-surfaces');
      expect(atlas.sortOrder, 42);
    });

    test('stores id, name, tilesetId exactly (no auto-trim on fields)', () {
      const rawId = '  water-atlas  ';
      const rawName = '  Water Atlas  ';
      const rawTileset = '  outdoor-water  ';
      final atlas = ProjectSurfaceAtlas(
        id: rawId,
        name: rawName,
        tilesetId: rawTileset,
        geometry: _geometry(),
      );
      expect(atlas.id, rawId);
      expect(atlas.name, rawName);
      expect(atlas.tilesetId, rawTileset);
    });

    test('rejects empty id: empty string', () {
      expect(
        () => ProjectSurfaceAtlas(
          id: '',
          name: 'N',
          tilesetId: 't',
          geometry: _geometry(),
        ),
        throwsA(isA<ValidationException>()),
      );
    });

    test('rejects empty id: whitespace only', () {
      expect(
        () => ProjectSurfaceAtlas(
          id: '   ',
          name: 'N',
          tilesetId: 't',
          geometry: _geometry(),
        ),
        throwsA(isA<ValidationException>()),
      );
    });

    test('rejects empty name: empty string', () {
      expect(
        () => ProjectSurfaceAtlas(
          id: 'i',
          name: '',
          tilesetId: 't',
          geometry: _geometry(),
        ),
        throwsA(isA<ValidationException>()),
      );
    });

    test('rejects empty name: whitespace only', () {
      expect(
        () => ProjectSurfaceAtlas(
          id: 'i',
          name: '   ',
          tilesetId: 't',
          geometry: _geometry(),
        ),
        throwsA(isA<ValidationException>()),
      );
    });

    test('rejects empty tilesetId: empty string', () {
      expect(
        () => ProjectSurfaceAtlas(
          id: 'i',
          name: 'n',
          tilesetId: '',
          geometry: _geometry(),
        ),
        throwsA(isA<ValidationException>()),
      );
    });

    test('rejects empty tilesetId: whitespace only', () {
      expect(
        () => ProjectSurfaceAtlas(
          id: 'i',
          name: 'n',
          tilesetId: '   ',
          geometry: _geometry(),
        ),
        throwsA(isA<ValidationException>()),
      );
    });

    test('keeps the same geometry instance (no re-wrap)', () {
      final geom = _geometry();
      final atlas = ProjectSurfaceAtlas(
        id: 'x',
        name: 'X',
        tilesetId: 'y',
        geometry: geom,
      );
      expect(atlas.geometry, same(geom));
    });

    test('value equality: same values', () {
      final g = _geometry();
      final a = ProjectSurfaceAtlas(
        id: 'i',
        name: 'n',
        tilesetId: 't',
        geometry: g,
        categoryId: 'c',
        sortOrder: 1,
      );
      final b = ProjectSurfaceAtlas(
        id: 'i',
        name: 'n',
        tilesetId: 't',
        geometry: g,
        categoryId: 'c',
        sortOrder: 1,
      );
      expect(a, b);
      expect(a.hashCode, b.hashCode);
    });

    test('value equality: id differs', () {
      final g = _geometry();
      final a = ProjectSurfaceAtlas(
        id: 'a',
        name: 'n',
        tilesetId: 't',
        geometry: g,
      );
      final b = ProjectSurfaceAtlas(
        id: 'b',
        name: 'n',
        tilesetId: 't',
        geometry: g,
      );
      expect(a, isNot(b));
    });

    test('value equality: name differs', () {
      final g = _geometry();
      final a = ProjectSurfaceAtlas(
        id: 'i',
        name: 'n1',
        tilesetId: 't',
        geometry: g,
      );
      final b = ProjectSurfaceAtlas(
        id: 'i',
        name: 'n2',
        tilesetId: 't',
        geometry: g,
      );
      expect(a, isNot(b));
    });

    test('value equality: tilesetId differs', () {
      final g = _geometry();
      final a = ProjectSurfaceAtlas(
        id: 'i',
        name: 'n',
        tilesetId: 't1',
        geometry: g,
      );
      final b = ProjectSurfaceAtlas(
        id: 'i',
        name: 'n',
        tilesetId: 't2',
        geometry: g,
      );
      expect(a, isNot(b));
    });

    test('value equality: geometry differs (layout)', () {
      final g1 = _geometry(
        layout: SurfaceAtlasLayout.grid,
      );
      final g2 = _geometry(
        layout: SurfaceAtlasLayout.columnsAreVariantsRowsAreFrames,
      );
      final a = ProjectSurfaceAtlas(
        id: 'i',
        name: 'n',
        tilesetId: 't',
        geometry: g1,
      );
      final b = ProjectSurfaceAtlas(
        id: 'i',
        name: 'n',
        tilesetId: 't',
        geometry: g2,
      );
      expect(a, isNot(b));
    });

    test('value equality: geometry differs (grid size)', () {
      final g1 = SurfaceAtlasGeometry(
        tileSize: SurfaceAtlasTileSize(width: 16, height: 16),
        gridSize: SurfaceAtlasGridSize(columns: 2, rows: 2),
      );
      final g2 = SurfaceAtlasGeometry(
        tileSize: SurfaceAtlasTileSize(width: 16, height: 16),
        gridSize: SurfaceAtlasGridSize(columns: 3, rows: 2),
      );
      final a = ProjectSurfaceAtlas(
        id: 'i',
        name: 'n',
        tilesetId: 't',
        geometry: g1,
      );
      final b = ProjectSurfaceAtlas(
        id: 'i',
        name: 'n',
        tilesetId: 't',
        geometry: g2,
      );
      expect(a, isNot(b));
    });

    test('value equality: categoryId differs (including null vs non-null)', () {
      final g = _geometry();
      final a = ProjectSurfaceAtlas(
        id: 'i',
        name: 'n',
        tilesetId: 't',
        geometry: g,
        categoryId: 'c',
      );
      final b = ProjectSurfaceAtlas(
        id: 'i',
        name: 'n',
        tilesetId: 't',
        geometry: g,
        categoryId: null,
      );
      expect(a, isNot(b));
    });

    test('value equality: sortOrder differs', () {
      final g = _geometry();
      final a = ProjectSurfaceAtlas(
        id: 'i',
        name: 'n',
        tilesetId: 't',
        geometry: g,
        sortOrder: 0,
      );
      final b = ProjectSurfaceAtlas(
        id: 'i',
        name: 'n',
        tilesetId: 't',
        geometry: g,
        sortOrder: 1,
      );
      expect(a, isNot(b));
    });

    test('export: type available via map_core', () {
      final atlas = ProjectSurfaceAtlas(
        id: 'i',
        name: 'n',
        tilesetId: 't',
        geometry: _geometry(),
      );
      expect(atlas, isA<ProjectSurfaceAtlas>());
    });

    test('ProjectManifest toJson: no top-level surface* keys', () {
      const manifest = ProjectManifest(
        name: 'L23',
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
      for (final key in <String>[
        'surfaceDefinitions',
        'surfaceAtlases',
        'surfaceAnimations',
        'surfacePresets',
        'surfaceCategories',
      ]) {
        expect(map.containsKey(key), isFalse, reason: key);
      }
    });
  });
}
````


## 26. Diff réel — `git diff` sur `surface.dart` (working tree / base index)

*Diff régénéré après mise à jour des 4 premières lignes d’en-tête du fichier.*

````diff
diff --git a/packages/map_core/lib/src/models/surface.dart b/packages/map_core/lib/src/models/surface.dart
index deed3b7e..119b2b3d 100644
--- a/packages/map_core/lib/src/models/surface.dart
+++ b/packages/map_core/lib/src/models/surface.dart
@@ -1,7 +1,7 @@
-// Fichier d’entrée Surface (map_core) : pas de persistance, pas de JSON ici.
-// Les types ci-dessous décrivent seulement une **géométrie d’atlas** (tailles, grille,
-// convention de layout) pour une future intégration (ex. `ProjectSurfaceAtlas`, hors
-// scope des lots actuels).
+// Fichier d’entrée Surface (map_core) : pas de persistance JSON, pas de `toJson` ici.
+// Contient l’[enum] de layout, les value objects de géométrie d’atlas, et
+// [ProjectSurfaceAtlas] (métadonnées d’atlas) — raccrochage manifest dans des lots
+// ultérieurs.
 
 import 'package:meta/meta.dart' show immutable;
 
@@ -151,3 +151,82 @@ final class SurfaceAtlasGeometry {
   @override
   int get hashCode => Object.hash(tileSize, gridSize, layout);
 }
+
+/// Métadonnées d’un **atlas Surface** auteur : identifiant, libellé, tileset
+/// source, et [geometry] (convention d’atlas, pas d’image chargée ici).
+///
+/// * N’est **pas** encore rattaché à un [ProjectManifest] (aucune liste
+///   `surfaceAtlases` dans ce lot) : modèle de domaine seul, sans persistance
+///   JSON.
+/// * Ne fait **pas** de [toJson] / [fromJson] ; ne crée **pas** de preset
+///   runtime ni d’[SurfaceLayer].
+/// * Ne valide **pas** l’existence d’un enregistrement de tileset dans le
+///   manifeste, ni la taille d’un fichier image — seulement la cohérence
+///   minimale des champs texte requis.
+@immutable
+final class ProjectSurfaceAtlas {
+  ProjectSurfaceAtlas({
+    required this.id,
+    required this.name,
+    required this.tilesetId,
+    required this.geometry,
+    this.categoryId,
+    this.sortOrder = 0,
+  }) {
+    if (id.trim().isEmpty) {
+      throw const ValidationException('ProjectSurfaceAtlas.id must be non-empty');
+    }
+    if (name.trim().isEmpty) {
+      throw const ValidationException('ProjectSurfaceAtlas.name must be non-empty');
+    }
+    if (tilesetId.trim().isEmpty) {
+      throw const ValidationException('ProjectSurfaceAtlas.tilesetId must be non-empty');
+    }
+  }
+
+  /// Identifiant stable, unique côté auteur. Stocké **tel quel** (pas de trim
+  /// appliqué à la chaîne mémorisée) ; on rejette seulement les « vides » via
+  /// `trim` dans le constructeur.
+  final String id;
+
+  /// Nom d’affichage ; mêmes règles de stockage et de garde qu’[id].
+  final String name;
+
+  /// Clé de tileset (référence logique) ; même principe de stockage.
+  final String tilesetId;
+
+  /// Découpage d’atlas (les dimensions sont déjà validées par les value objects
+  /// [SurfaceAtlasTileSize] / [SurfaceAtlasGridSize] ; pas de revalidation ici).
+  final SurfaceAtlasGeometry geometry;
+
+  /// Dossier / catégorie optionnelle (comme [ProjectPathPreset.categoryId]) :
+  /// ce lot **n’impose** pas de forme (chaîne vide autorisée si l’appelant la
+  /// transmet, pour ne pas sur-valider en l’absence de convention unique sur
+  /// les champs optionnels de ce type dans le monorepo).
+  final String? categoryId;
+
+  /// Ordre d’affichage (classement) ; toute valeur entière est acceptée, comme
+  /// [ProjectPathPreset.sortOrder] sans borne documentée ici.
+  final int sortOrder;
+
+  @override
+  bool operator ==(Object other) =>
+      identical(this, other) ||
+      other is ProjectSurfaceAtlas &&
+          other.id == id &&
+          other.name == name &&
+          other.tilesetId == tilesetId &&
+          other.geometry == geometry &&
+          other.categoryId == categoryId &&
+          other.sortOrder == sortOrder;
+
+  @override
+  int get hashCode => Object.hash(
+        id,
+        name,
+        tilesetId,
+        geometry,
+        categoryId,
+        sortOrder,
+      );
+}
````


## 27. Diff réel — `diff -u /dev/null` sur `test/project_surface_atlas_test.dart` (fichier nouveau)

````diff
--- /dev/null	2026-04-26 23:18:41
+++ packages/map_core/test/project_surface_atlas_test.dart	2026-04-26 23:18:06
@@ -0,0 +1,341 @@
+import 'package:map_core/map_core.dart';
+import 'package:test/test.dart';
+
+SurfaceAtlasGeometry _geometry({
+  SurfaceAtlasLayout layout = SurfaceAtlasLayout.columnsAreVariantsRowsAreFrames,
+}) {
+  return SurfaceAtlasGeometry(
+    tileSize: SurfaceAtlasTileSize(width: 32, height: 32),
+    gridSize: SurfaceAtlasGridSize(columns: 23, rows: 32),
+    layout: layout,
+  );
+}
+
+void main() {
+  group('ProjectSurfaceAtlas', () {
+    test('minimal atlas: fields and derived geometry', () {
+      final atlas = ProjectSurfaceAtlas(
+        id: 'water-atlas',
+        name: 'Water Atlas',
+        tilesetId: 'outdoor-water',
+        geometry: SurfaceAtlasGeometry(
+          tileSize: SurfaceAtlasTileSize(width: 32, height: 32),
+          gridSize: SurfaceAtlasGridSize(columns: 23, rows: 32),
+          layout: SurfaceAtlasLayout.columnsAreVariantsRowsAreFrames,
+        ),
+      );
+      expect(atlas.id, 'water-atlas');
+      expect(atlas.name, 'Water Atlas');
+      expect(atlas.tilesetId, 'outdoor-water');
+      expect(atlas.categoryId, isNull);
+      expect(atlas.sortOrder, 0);
+      expect(atlas.geometry.tileCount, 736);
+      expect(
+        atlas.geometry.layout,
+        SurfaceAtlasLayout.columnsAreVariantsRowsAreFrames,
+      );
+    });
+
+    test('preserves categoryId and sortOrder', () {
+      final atlas = ProjectSurfaceAtlas(
+        id: 'a1',
+        name: 'A',
+        tilesetId: 't1',
+        geometry: _geometry(),
+        categoryId: 'animated-surfaces',
+        sortOrder: 42,
+      );
+      expect(atlas.categoryId, 'animated-surfaces');
+      expect(atlas.sortOrder, 42);
+    });
+
+    test('stores id, name, tilesetId exactly (no auto-trim on fields)', () {
+      const rawId = '  water-atlas  ';
+      const rawName = '  Water Atlas  ';
+      const rawTileset = '  outdoor-water  ';
+      final atlas = ProjectSurfaceAtlas(
+        id: rawId,
+        name: rawName,
+        tilesetId: rawTileset,
+        geometry: _geometry(),
+      );
+      expect(atlas.id, rawId);
+      expect(atlas.name, rawName);
+      expect(atlas.tilesetId, rawTileset);
+    });
+
+    test('rejects empty id: empty string', () {
+      expect(
+        () => ProjectSurfaceAtlas(
+          id: '',
+          name: 'N',
+          tilesetId: 't',
+          geometry: _geometry(),
+        ),
+        throwsA(isA<ValidationException>()),
+      );
+    });
+
+    test('rejects empty id: whitespace only', () {
+      expect(
+        () => ProjectSurfaceAtlas(
+          id: '   ',
+          name: 'N',
+          tilesetId: 't',
+          geometry: _geometry(),
+        ),
+        throwsA(isA<ValidationException>()),
+      );
+    });
+
+    test('rejects empty name: empty string', () {
+      expect(
+        () => ProjectSurfaceAtlas(
+          id: 'i',
+          name: '',
+          tilesetId: 't',
+          geometry: _geometry(),
+        ),
+        throwsA(isA<ValidationException>()),
+      );
+    });
+
+    test('rejects empty name: whitespace only', () {
+      expect(
+        () => ProjectSurfaceAtlas(
+          id: 'i',
+          name: '   ',
+          tilesetId: 't',
+          geometry: _geometry(),
+        ),
+        throwsA(isA<ValidationException>()),
+      );
+    });
+
+    test('rejects empty tilesetId: empty string', () {
+      expect(
+        () => ProjectSurfaceAtlas(
+          id: 'i',
+          name: 'n',
+          tilesetId: '',
+          geometry: _geometry(),
+        ),
+        throwsA(isA<ValidationException>()),
+      );
+    });
+
+    test('rejects empty tilesetId: whitespace only', () {
+      expect(
+        () => ProjectSurfaceAtlas(
+          id: 'i',
+          name: 'n',
+          tilesetId: '   ',
+          geometry: _geometry(),
+        ),
+        throwsA(isA<ValidationException>()),
+      );
+    });
+
+    test('keeps the same geometry instance (no re-wrap)', () {
+      final geom = _geometry();
+      final atlas = ProjectSurfaceAtlas(
+        id: 'x',
+        name: 'X',
+        tilesetId: 'y',
+        geometry: geom,
+      );
+      expect(atlas.geometry, same(geom));
+    });
+
+    test('value equality: same values', () {
+      final g = _geometry();
+      final a = ProjectSurfaceAtlas(
+        id: 'i',
+        name: 'n',
+        tilesetId: 't',
+        geometry: g,
+        categoryId: 'c',
+        sortOrder: 1,
+      );
+      final b = ProjectSurfaceAtlas(
+        id: 'i',
+        name: 'n',
+        tilesetId: 't',
+        geometry: g,
+        categoryId: 'c',
+        sortOrder: 1,
+      );
+      expect(a, b);
+      expect(a.hashCode, b.hashCode);
+    });
+
+    test('value equality: id differs', () {
+      final g = _geometry();
+      final a = ProjectSurfaceAtlas(
+        id: 'a',
+        name: 'n',
+        tilesetId: 't',
+        geometry: g,
+      );
+      final b = ProjectSurfaceAtlas(
+        id: 'b',
+        name: 'n',
+        tilesetId: 't',
+        geometry: g,
+      );
+      expect(a, isNot(b));
+    });
+
+    test('value equality: name differs', () {
+      final g = _geometry();
+      final a = ProjectSurfaceAtlas(
+        id: 'i',
+        name: 'n1',
+        tilesetId: 't',
+        geometry: g,
+      );
+      final b = ProjectSurfaceAtlas(
+        id: 'i',
+        name: 'n2',
+        tilesetId: 't',
+        geometry: g,
+      );
+      expect(a, isNot(b));
+    });
+
+    test('value equality: tilesetId differs', () {
+      final g = _geometry();
+      final a = ProjectSurfaceAtlas(
+        id: 'i',
+        name: 'n',
+        tilesetId: 't1',
+        geometry: g,
+      );
+      final b = ProjectSurfaceAtlas(
+        id: 'i',
+        name: 'n',
+        tilesetId: 't2',
+        geometry: g,
+      );
+      expect(a, isNot(b));
+    });
+
+    test('value equality: geometry differs (layout)', () {
+      final g1 = _geometry(
+        layout: SurfaceAtlasLayout.grid,
+      );
+      final g2 = _geometry(
+        layout: SurfaceAtlasLayout.columnsAreVariantsRowsAreFrames,
+      );
+      final a = ProjectSurfaceAtlas(
+        id: 'i',
+        name: 'n',
+        tilesetId: 't',
+        geometry: g1,
+      );
+      final b = ProjectSurfaceAtlas(
+        id: 'i',
+        name: 'n',
+        tilesetId: 't',
+        geometry: g2,
+      );
+      expect(a, isNot(b));
+    });
+
+    test('value equality: geometry differs (grid size)', () {
+      final g1 = SurfaceAtlasGeometry(
+        tileSize: SurfaceAtlasTileSize(width: 16, height: 16),
+        gridSize: SurfaceAtlasGridSize(columns: 2, rows: 2),
+      );
+      final g2 = SurfaceAtlasGeometry(
+        tileSize: SurfaceAtlasTileSize(width: 16, height: 16),
+        gridSize: SurfaceAtlasGridSize(columns: 3, rows: 2),
+      );
+      final a = ProjectSurfaceAtlas(
+        id: 'i',
+        name: 'n',
+        tilesetId: 't',
+        geometry: g1,
+      );
+      final b = ProjectSurfaceAtlas(
+        id: 'i',
+        name: 'n',
+        tilesetId: 't',
+        geometry: g2,
+      );
+      expect(a, isNot(b));
+    });
+
+    test('value equality: categoryId differs (including null vs non-null)', () {
+      final g = _geometry();
+      final a = ProjectSurfaceAtlas(
+        id: 'i',
+        name: 'n',
+        tilesetId: 't',
+        geometry: g,
+        categoryId: 'c',
+      );
+      final b = ProjectSurfaceAtlas(
+        id: 'i',
+        name: 'n',
+        tilesetId: 't',
+        geometry: g,
+        categoryId: null,
+      );
+      expect(a, isNot(b));
+    });
+
+    test('value equality: sortOrder differs', () {
+      final g = _geometry();
+      final a = ProjectSurfaceAtlas(
+        id: 'i',
+        name: 'n',
+        tilesetId: 't',
+        geometry: g,
+        sortOrder: 0,
+      );
+      final b = ProjectSurfaceAtlas(
+        id: 'i',
+        name: 'n',
+        tilesetId: 't',
+        geometry: g,
+        sortOrder: 1,
+      );
+      expect(a, isNot(b));
+    });
+
+    test('export: type available via map_core', () {
+      final atlas = ProjectSurfaceAtlas(
+        id: 'i',
+        name: 'n',
+        tilesetId: 't',
+        geometry: _geometry(),
+      );
+      expect(atlas, isA<ProjectSurfaceAtlas>());
+    });
+
+    test('ProjectManifest toJson: no top-level surface* keys', () {
+      const manifest = ProjectManifest(
+        name: 'L23',
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
+      for (final key in <String>[
+        'surfaceDefinitions',
+        'surfaceAtlases',
+        'surfaceAnimations',
+        'surfacePresets',
+        'surfaceCategories',
+      ]) {
+        expect(map.containsKey(key), isFalse, reason: key);
+      }
+    });
+  });
+}
````


---

*Fin — Lot 23*
