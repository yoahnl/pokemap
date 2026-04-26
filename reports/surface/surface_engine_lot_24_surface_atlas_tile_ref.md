# Lot 24 — Surface Atlas Tile Ref V0

## 1. Résumé exécutif

Ce lot introduit le value object **`SurfaceAtlasTileRef`** dans `packages/map_core/lib/src/models/surface.dart` : adresse logique d’une tuile d’atlas (identifiant d’atlas + colonne + ligne de grille), validations alignées sur les lots 21–23, `isInside` par délégation à `SurfaceAtlasGeometry.containsGridCoordinate`, égalité de valeur. Aucun JSON, Freezed, ni modification de `ProjectManifest` ou du barrel (l’export `surface.dart` existait déjà). Tests ciblés + suite `map_core` complète : **583** tests, succès. Analyse ciblée : **Aucun problème**.

## 2. Pourquoi ce lot vient après le Lot 23

Le **Lot 23** a posé `ProjectSurfaceAtlas` (métadonnées d’atlas). Le **Lot 24** ajoute un **type de référence fine** vers une **cellule** d’atlas (sans charger d’image ni lier le manifest) : c’est l’imbrication logique usuelle (atlas + coordonnée de grille) pour les lots qui brancheront auteur/runtime sur des adresses stables d’atlas.

## 3. Fichiers consultés (audit)

- `packages/map_core/lib/src/models/surface.dart` (enum + géométrie + `ProjectSurfaceAtlas`)
- `packages/map_core/test/surface_model_entrypoint_test.dart`, `surface_atlas_geometry_test.dart`, `project_surface_atlas_test.dart`
- `packages/map_core/lib/src/models/project_manifest.dart` (hors changement, contrat persistant)
- `packages/map_core/lib/src/exceptions/map_exceptions.dart` (`ValidationException`)
- `packages/map_core/lib/map_core.dart` (ligne 25 : `export 'src/models/surface.dart'`)
- Rapports lots 21–23 et spéc/prompt surface (réf. roadmap)

**Constats d’audit :** `SurfaceAtlasGeometry.containsGridCoordinate` existe et ignore le **layout** pour la seule vérification d’indice (cohérent avec le test cas 9). `map_core` exporte déjà `surface.dart` — **pas d’edit du barrel** en Lot 24.

## 4. Fichiers créés

- `packages/map_core/test/surface_atlas_tile_ref_test.dart`
- `reports/surface/surface_engine_lot_24_surface_atlas_tile_ref.md` (ce fichier)

## 5. Fichiers modifiés

- `packages/map_core/lib/src/models/surface.dart` (ajout `SurfaceAtlasTileRef` uniquement en fin de fichier, après `ProjectSurfaceAtlas`)

**Non modifié :** `map_core/lib/map_core.dart`, `project_manifest.dart`, packages runtime/editor/gameplay/battle, aucun `.g.dart` / `.freezed.dart`.

## 6. API ajoutée

```dart
@immutable
final class SurfaceAtlasTileRef {
  SurfaceAtlasTileRef({
    required this.atlasId,
    required this.column,
    required this.row,
  });

  final String atlasId;
  final int column;
  final int row;

  bool isInside(SurfaceAtlasGeometry geometry);

  @override
  bool operator ==(Object other) => /* atlasId, column, row */;

  @override
  int get hashCode => Object.hash(atlasId, column, row);
}
```

## 7. Sémantique de `SurfaceAtlasTileRef`

- **Rôle** : adresse abstraite d’une case dans un atlas identifié par `atlasId` ; ne résout **pas** un enregistrement de projet, ne charge **aucune** texture.
- **`atlasId`** : clé auteur telle quelle (voir validation).
- **`column` / `row`** : indices 0-based sur la **grille** d’atlas, pas des pixels.
- **Pas de persistance** : pas de `toJson` / sérialisation dans ce lot.

## 8. Validation des champs

| Champ   | Règle |
|---------|--------|
| `atlasId` | `atlasId.trim().isEmpty` → `ValidationException` ; la valeur **stockée** est la chaîne passée telle quelle. |
| `column`  | `column < 0` → `ValidationException` |
| `row`     | `row < 0` → `ValidationException` |

## 9. Sémantique de `isInside`

`isInside(geometry)` retourne exactement `geometry.containsGridCoordinate(column: column, row: row)` : vérification géométrique sur la taille de grille, **pas** d’existence d’atlas dans le manifest, **pas** de résolution de `atlasId` vers un `ProjectSurfaceAtlas`.

## 10. Ce qui a été testé

16 cas dans `surface_atlas_tile_ref_test.dart` : champs, stockage `atlasId` brut, rejets, zéro, `isInside` vrai/faux, indépendance vis-à-vis de `SurfaceAtlasLayout`, égalité, export public, garde-fou `ProjectManifest.toJson` sans clés `surface*`.

## 11. Ce que les tests prouvent

- Comportement value object et validations.
- Délégation `isInside` → `containsGridCoordinate`.
- Aucun ajout de clés surface au JSON manifest minimal (non-régression lot 24 sur le contrat Freezed actuel).
- L’export `package:map_core/map_core.dart` suffit à utiliser `SurfaceAtlasTileRef`.

## 12. Ce qui n’a volontairement pas été fait

- Aucun JSON surface, `SurfaceDefinition`, `SurfaceLayer`, `ProjectSurface` preset, animation.
- Aucun lien `atlasId` → `ProjectSurfaceAtlas` ou lookup manifest.
- Aucun changement d’atlas / géométrie / helpers vertical legacy.

## 13. Pourquoi `ProjectManifest` n’a toujours pas été modifié

La Roadmap exige d’**étager** l’apparition des listes / champs persistantes Surface. Les lots 21–24 restent en **domaine pur** côté `map_core` pour figer sémantique et tests avant toute extension du schéma manifest.

## 14. Pourquoi aucun fichier généré n’a été créé

Le lot est volontairement **sans** `json_serializable` / `freezed` / `build_runner` : value object manuel, comme les autres types de `surface.dart` hors génération.

## 15. Impact pour les prochains lots Surface

- Les futurs blocs (presets, cartes, runtime) pourront transporter un **`SurfaceAtlasTileRef`** comme adresse stable d’apparence de tuile, une fois le manifest étendu.
- Tant que le manifest ne liste pas les atlasses, l’`atlasId` reste un **identifiant logique** non vérifié ici.

## 16. Commandes lancées

Toutes depuis `packages/map_core`, binaire : `/opt/homebrew/bin/dart`.

```bash
dart test test/surface_atlas_tile_ref_test.dart
```

Sortie (extrait) : `+16: All tests passed!`

```bash
dart test test/project_surface_atlas_test.dart
```

```bash
dart test test/surface_atlas_geometry_test.dart
```

```bash
dart test test/surface_model_entrypoint_test.dart
```

(Enchaînement groupé exécuté une fois : 43 cas, `All tests passed!` — mélange de fichiers.)

```bash
dart analyze \
  lib/src/models/surface.dart \
  test/surface_atlas_tile_ref_test.dart \
  test/project_surface_atlas_test.dart \
  test/surface_atlas_geometry_test.dart \
  test/surface_model_entrypoint_test.dart \
  lib/map_core.dart
```

Sortie : `No issues found!` (code 0).

```bash
dart test
```

## 17. Résultats exacts des tests ciblés

- **`surface_atlas_tile_ref_test.dart` :** 16 passed, 0 failed — dernière ligne : `+16: All tests passed!`
- Regroupement surface (4 fichiers) : 43 cas — `All tests passed!`

## 18. Total exact du `dart test` complet (map_core)

**583 tests, tous passés** — dernière ligne de sortie : `+583: All tests passed!` (exit code 0).  
*(Avant ce lot, la base était 567 tests : +16 = 583.)*

## 19. Points de vigilance

- `atlasId` n’est **pas** validé contre un catalogue : deux références avec le même triplet d’intuition mais un `atlasId` fautif ne sont pas détectées ici.
- L’égalité est **sensible** à la casse / espaces de `atlasId` (stockage exact).

## 20. Autocritique finale

- Redondance avec les tests d’autres lots sur l’absence de clés `surface*` dans `toJson` : utile pour **prouver** le Lot 24 n’a pas touché au manifest, au prix d’une légère duplication.
- Aucun test de **collision** `hashCode` (non requis par le prompt).

## 21. Ce que le prompt semble discutable ou incomplet

- Le texte de mission demande « toute l’intention » API sans forcer l’**annotation** `@immutable` : le dépôt l’utilise déjà sur les value objects de `surface.dart` — alignement appliqué.
- Répéter le garde-fou manifest à chaque lot Surface peut sembler lourd ; c’est en revanche une **preuve d’invariant** exigée.

## 22. Auto-review indépendante (checklist explicite)

| Question | Verdict |
|----------|---------|
| Lot limité à `SurfaceAtlasTileRef` (+ test + rapport) ? | Oui. |
| `ProjectManifest` modifié ? | **Non** (fichier non touché, test lecture seule `toJson`). |
| Aucun champ surface persistant ajouté au manifest ? | **Oui** (prouvé par test + aucun changement de source). |
| Aucun modèle Freezed/JSON généré ? | **Oui**. |
| Aucun `.g.dart` / `.freezed.dart` créé ? | **Oui**. |
| Aucun runtime/editor/gameplay/battle modifié ? | **Oui**. |
| `SurfaceAtlasLayout`, VO Lot 22, `ProjectSurfaceAtlas` compatible ? | Oui, pas d’évolution de ces types. |
| `atlasId` / `column` / `row` validés ? | Oui. |
| `atlasId` non résolu ? | Oui (aucun lookup). |
| `isInside` → `containsGridCoordinate` ? | Oui. |
| Égalité testée ? | Oui. |
| Export public OK ? | Oui. |
| Tests manifest sans clés `surface*` ? | Oui. |
| `map_core` complet vert (583) ? | Oui. |
| Contenus / diffs complets dans ce rapport ? | Oui, sections 23–24. |
| Commandes git d’écriture utilisées ? | **Non** (seulement `status` / `diff` selon règles). |

**Verdicts « sub-agents » (passes simulées, conformément `codex_rule.md`) :**

| Passe | Verdict |
|-------|---------|
| Audit / Architecture | **OK** — `surface.dart` cohérent, pas de fuite manifest. |
| Implémentation | **OK** — VO seul, validations, `isInside`, `==`/`hashCode`. |
| Tests | **OK** — 16 cas + garde-fou manifest. |
| Build / Validation | **OK** — `dart analyze` + `dart test` 583. |
| Critique finale | **OK** — revue item 22 sans blocage. |

## 23. Contenu complet des fichiers créés / modifiés

Les blocs ci-dessous reprennent **verbatim** le contenu des fichiers sur disque à la validation du lot (LF, UTF-8).

### 23.A `packages/map_core/lib/src/models/surface.dart` (fichier complet, 289 lignes)

Fichier **modifié** (unique fichier Dart source du lot) : voir **section 25.A** (bloc `dart` intégral).

## 24. Diff complet réel

### 24.A `git diff` — `packages/map_core/lib/src/models/surface.dart`

```diff
diff --git a/packages/map_core/lib/src/models/surface.dart b/packages/map_core/lib/src/models/surface.dart
index 119b2b3d..b776c8f8 100644
--- a/packages/map_core/lib/src/models/surface.dart
+++ b/packages/map_core/lib/src/models/surface.dart
@@ -230,3 +230,59 @@ final class ProjectSurfaceAtlas {
         sortOrder,
       );
 }
+
+/// Adresse logique d’une **cellule** dans un atlas identifié par [atlasId]
+/// (pas de chargement d’image, pas de jointure [ProjectSurfaceAtlas] ou
+/// manifest dans ce lot — [atlasId] est un libellé auteur, non résolu ici).
+///
+/// * [column] et [row] sont des **indices de grille** 0-based (même
+///   convention que [SurfaceAtlasGeometry.containsGridCoordinate]), **pas** des
+///   pixels dans la texture.
+/// * [isInside] s’appuie uniquement sur la [SurfaceAtlasGeometry] passée (elle
+///   n’impose pas que l’on connaisse un `ProjectSurfaceAtlas` concret) ; elle ne
+///   vérifie **pas** qu’un enregistrement d’atlas portant cet [atlasId] existe.
+@immutable
+final class SurfaceAtlasTileRef {
+  SurfaceAtlasTileRef({
+    required this.atlasId,
+    required this.column,
+    required this.row,
+  }) {
+    if (atlasId.trim().isEmpty) {
+      throw const ValidationException('SurfaceAtlasTileRef.atlasId must be non-empty');
+    }
+    if (column < 0) {
+      throw const ValidationException('SurfaceAtlasTileRef.column must be >= 0');
+    }
+    if (row < 0) {
+      throw const ValidationException('SurfaceAtlasTileRef.row must be >= 0');
+    }
+  }
+
+  /// Clé d’atlas côté domaine. Stockage **brut** (comme [ProjectSurfaceAtlas.id]) ;
+  /// l’irrecevabilité seulement quand, après [trim], il ne reste rien.
+  final String atlasId;
+
+  /// Colonne (axe X de la **grille d’atlas**), indice 0-based.
+  final int column;
+
+  /// Ligne (axe Y de la **grille d’atlas**), indice 0-based.
+  final int row;
+
+  /// Vérifie si ce couple (column,row) tient dans [geometry] (indépendant du
+  /// [SurfaceAtlasLayout] pour la seule **taille** de grille, cf.
+  /// [SurfaceAtlasGeometry.containsGridCoordinate]).
+  bool isInside(SurfaceAtlasGeometry geometry) =>
+      geometry.containsGridCoordinate(column: column, row: row);
+
+  @override
+  bool operator ==(Object other) =>
+      identical(this, other) ||
+      other is SurfaceAtlasTileRef &&
+          other.atlasId == atlasId &&
+          other.column == column &&
+          other.row == row;
+
+  @override
+  int get hashCode => Object.hash(atlasId, column, row);
+}
```

### 24.B `diff -u /dev/null` — `packages/map_core/test/surface_atlas_tile_ref_test.dart`

Diff généré par `diff -u /dev/null …/surface_atlas_tile_ref_test.dart` (chemins d’en-têtes = machine de validation) :

```diff
--- /dev/null	2026-04-26 23:23:58
+++ packages/map_core/test/surface_atlas_tile_ref_test.dart	2026-04-26 23:22:27
@@ -0,0 +1,181 @@
+import 'package:map_core/map_core.dart';
+import 'package:test/test.dart';
+
+void main() {
+  group('SurfaceAtlasTileRef', () {
+    test('minimal ref holds fields', () {
+      final ref = SurfaceAtlasTileRef(
+        atlasId: 'water-atlas',
+        column: 3,
+        row: 4,
+      );
+      expect(ref.atlasId, 'water-atlas');
+      expect(ref.column, 3);
+      expect(ref.row, 4);
+    });
+
+    test('stores atlasId exactly without trimming the stored value', () {
+      const raw = '  water-atlas  ';
+      final ref = SurfaceAtlasTileRef(
+        atlasId: raw,
+        column: 0,
+        row: 0,
+      );
+      expect(ref.atlasId, raw);
+    });
+
+    test('rejects empty atlasId: empty string', () {
+      expect(
+        () => SurfaceAtlasTileRef(atlasId: '', column: 0, row: 0),
+        throwsA(isA<ValidationException>()),
+      );
+    });
+
+    test('rejects empty atlasId: whitespace only', () {
+      expect(
+        () => SurfaceAtlasTileRef(atlasId: '   ', column: 0, row: 0),
+        throwsA(isA<ValidationException>()),
+      );
+    });
+
+    test('rejects negative column', () {
+      expect(
+        () => SurfaceAtlasTileRef(atlasId: 'a', column: -1, row: 0),
+        throwsA(isA<ValidationException>()),
+      );
+    });
+
+    test('rejects negative row', () {
+      expect(
+        () => SurfaceAtlasTileRef(atlasId: 'a', column: 0, row: -1),
+        throwsA(isA<ValidationException>()),
+      );
+    });
+
+    test('accepts column and row zero', () {
+      final ref = SurfaceAtlasTileRef(
+        atlasId: 'atlas',
+        column: 0,
+        row: 0,
+      );
+      expect(ref.column, 0);
+      expect(ref.row, 0);
+    });
+
+    test('isInside: true for interior cells', () {
+      final geometry = SurfaceAtlasGeometry(
+        tileSize: SurfaceAtlasTileSize(width: 32, height: 32),
+        gridSize: SurfaceAtlasGridSize(columns: 4, rows: 3),
+      );
+      final a = SurfaceAtlasTileRef(
+        atlasId: 'a',
+        column: 0,
+        row: 0,
+      );
+      final b = SurfaceAtlasTileRef(
+        atlasId: 'a',
+        column: 3,
+        row: 2,
+      );
+      expect(a.isInside(geometry), isTrue);
+      expect(b.isInside(geometry), isTrue);
+    });
+
+    test('isInside: false when out of grid', () {
+      final geometry = SurfaceAtlasGeometry(
+        tileSize: SurfaceAtlasTileSize(width: 32, height: 32),
+        gridSize: SurfaceAtlasGridSize(columns: 4, rows: 3),
+      );
+      void expectOut(int c, int r) {
+        expect(
+          SurfaceAtlasTileRef(
+            atlasId: 'a',
+            column: c,
+            row: r,
+          ).isInside(geometry),
+          isFalse,
+        );
+      }
+
+      expectOut(4, 0);
+      expectOut(0, 3);
+      expectOut(99, 99);
+    });
+
+    test('isInside: same column/row independent of layout enum', () {
+      final tile = SurfaceAtlasTileSize(width: 8, height: 8);
+      final grid = SurfaceAtlasGridSize(columns: 4, rows: 3);
+      final gGrid = SurfaceAtlasGeometry(
+        tileSize: tile,
+        gridSize: grid,
+        layout: SurfaceAtlasLayout.grid,
+      );
+      final gVertical = SurfaceAtlasGeometry(
+        tileSize: tile,
+        gridSize: grid,
+        layout: SurfaceAtlasLayout.columnsAreVariantsRowsAreFrames,
+      );
+      final ref = SurfaceAtlasTileRef(
+        atlasId: 'a',
+        column: 1,
+        row: 1,
+      );
+      expect(ref.isInside(gGrid), isTrue);
+      expect(ref.isInside(gVertical), isTrue);
+    });
+
+    test('value equality: same values and hashCode', () {
+      final a = SurfaceAtlasTileRef(atlasId: 'x', column: 2, row: 3);
+      final b = SurfaceAtlasTileRef(atlasId: 'x', column: 2, row: 3);
+      expect(a, b);
+      expect(a.hashCode, b.hashCode);
+    });
+
+    test('value equality: atlasId differs', () {
+      final a = SurfaceAtlasTileRef(atlasId: 'a', column: 0, row: 0);
+      final b = SurfaceAtlasTileRef(atlasId: 'b', column: 0, row: 0);
+      expect(a, isNot(b));
+    });
+
+    test('value equality: column differs', () {
+      final a = SurfaceAtlasTileRef(atlasId: 'a', column: 0, row: 0);
+      final b = SurfaceAtlasTileRef(atlasId: 'a', column: 1, row: 0);
+      expect(a, isNot(b));
+    });
+
+    test('value equality: row differs', () {
+      final a = SurfaceAtlasTileRef(atlasId: 'a', column: 0, row: 0);
+      final b = SurfaceAtlasTileRef(atlasId: 'a', column: 0, row: 1);
+      expect(a, isNot(b));
+    });
+
+    test('export: type is visible through map_core', () {
+      final ref = SurfaceAtlasTileRef(atlasId: 'a', column: 0, row: 0);
+      expect(ref, isA<SurfaceAtlasTileRef>());
+    });
+
+    test('ProjectManifest toJson: no surface* top-level keys', () {
+      const manifest = ProjectManifest(
+        name: 'L24',
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
```

## 25. Annexe : fichiers complets (verbatim)

### 25.A `packages/map_core/lib/src/models/surface.dart`

```dart
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

/// Adresse logique d’une **cellule** dans un atlas identifié par [atlasId]
/// (pas de chargement d’image, pas de jointure [ProjectSurfaceAtlas] ou
/// manifest dans ce lot — [atlasId] est un libellé auteur, non résolu ici).
///
/// * [column] et [row] sont des **indices de grille** 0-based (même
///   convention que [SurfaceAtlasGeometry.containsGridCoordinate]), **pas** des
///   pixels dans la texture.
/// * [isInside] s’appuie uniquement sur la [SurfaceAtlasGeometry] passée (elle
///   n’impose pas que l’on connaisse un `ProjectSurfaceAtlas` concret) ; elle ne
///   vérifie **pas** qu’un enregistrement d’atlas portant cet [atlasId] existe.
@immutable
final class SurfaceAtlasTileRef {
  SurfaceAtlasTileRef({
    required this.atlasId,
    required this.column,
    required this.row,
  }) {
    if (atlasId.trim().isEmpty) {
      throw const ValidationException('SurfaceAtlasTileRef.atlasId must be non-empty');
    }
    if (column < 0) {
      throw const ValidationException('SurfaceAtlasTileRef.column must be >= 0');
    }
    if (row < 0) {
      throw const ValidationException('SurfaceAtlasTileRef.row must be >= 0');
    }
  }

  /// Clé d’atlas côté domaine. Stockage **brut** (comme [ProjectSurfaceAtlas.id]) ;
  /// l’irrecevabilité seulement quand, après [trim], il ne reste rien.
  final String atlasId;

  /// Colonne (axe X de la **grille d’atlas**), indice 0-based.
  final int column;

  /// Ligne (axe Y de la **grille d’atlas**), indice 0-based.
  final int row;

  /// Vérifie si ce couple (column,row) tient dans [geometry] (indépendant du
  /// [SurfaceAtlasLayout] pour la seule **taille** de grille, cf.
  /// [SurfaceAtlasGeometry.containsGridCoordinate]).
  bool isInside(SurfaceAtlasGeometry geometry) =>
      geometry.containsGridCoordinate(column: column, row: row);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SurfaceAtlasTileRef &&
          other.atlasId == atlasId &&
          other.column == column &&
          other.row == row;

  @override
  int get hashCode => Object.hash(atlasId, column, row);
}
```


### 25.B `packages/map_core/test/surface_atlas_tile_ref_test.dart`

```dart
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('SurfaceAtlasTileRef', () {
    test('minimal ref holds fields', () {
      final ref = SurfaceAtlasTileRef(
        atlasId: 'water-atlas',
        column: 3,
        row: 4,
      );
      expect(ref.atlasId, 'water-atlas');
      expect(ref.column, 3);
      expect(ref.row, 4);
    });

    test('stores atlasId exactly without trimming the stored value', () {
      const raw = '  water-atlas  ';
      final ref = SurfaceAtlasTileRef(
        atlasId: raw,
        column: 0,
        row: 0,
      );
      expect(ref.atlasId, raw);
    });

    test('rejects empty atlasId: empty string', () {
      expect(
        () => SurfaceAtlasTileRef(atlasId: '', column: 0, row: 0),
        throwsA(isA<ValidationException>()),
      );
    });

    test('rejects empty atlasId: whitespace only', () {
      expect(
        () => SurfaceAtlasTileRef(atlasId: '   ', column: 0, row: 0),
        throwsA(isA<ValidationException>()),
      );
    });

    test('rejects negative column', () {
      expect(
        () => SurfaceAtlasTileRef(atlasId: 'a', column: -1, row: 0),
        throwsA(isA<ValidationException>()),
      );
    });

    test('rejects negative row', () {
      expect(
        () => SurfaceAtlasTileRef(atlasId: 'a', column: 0, row: -1),
        throwsA(isA<ValidationException>()),
      );
    });

    test('accepts column and row zero', () {
      final ref = SurfaceAtlasTileRef(
        atlasId: 'atlas',
        column: 0,
        row: 0,
      );
      expect(ref.column, 0);
      expect(ref.row, 0);
    });

    test('isInside: true for interior cells', () {
      final geometry = SurfaceAtlasGeometry(
        tileSize: SurfaceAtlasTileSize(width: 32, height: 32),
        gridSize: SurfaceAtlasGridSize(columns: 4, rows: 3),
      );
      final a = SurfaceAtlasTileRef(
        atlasId: 'a',
        column: 0,
        row: 0,
      );
      final b = SurfaceAtlasTileRef(
        atlasId: 'a',
        column: 3,
        row: 2,
      );
      expect(a.isInside(geometry), isTrue);
      expect(b.isInside(geometry), isTrue);
    });

    test('isInside: false when out of grid', () {
      final geometry = SurfaceAtlasGeometry(
        tileSize: SurfaceAtlasTileSize(width: 32, height: 32),
        gridSize: SurfaceAtlasGridSize(columns: 4, rows: 3),
      );
      void expectOut(int c, int r) {
        expect(
          SurfaceAtlasTileRef(
            atlasId: 'a',
            column: c,
            row: r,
          ).isInside(geometry),
          isFalse,
        );
      }

      expectOut(4, 0);
      expectOut(0, 3);
      expectOut(99, 99);
    });

    test('isInside: same column/row independent of layout enum', () {
      final tile = SurfaceAtlasTileSize(width: 8, height: 8);
      final grid = SurfaceAtlasGridSize(columns: 4, rows: 3);
      final gGrid = SurfaceAtlasGeometry(
        tileSize: tile,
        gridSize: grid,
        layout: SurfaceAtlasLayout.grid,
      );
      final gVertical = SurfaceAtlasGeometry(
        tileSize: tile,
        gridSize: grid,
        layout: SurfaceAtlasLayout.columnsAreVariantsRowsAreFrames,
      );
      final ref = SurfaceAtlasTileRef(
        atlasId: 'a',
        column: 1,
        row: 1,
      );
      expect(ref.isInside(gGrid), isTrue);
      expect(ref.isInside(gVertical), isTrue);
    });

    test('value equality: same values and hashCode', () {
      final a = SurfaceAtlasTileRef(atlasId: 'x', column: 2, row: 3);
      final b = SurfaceAtlasTileRef(atlasId: 'x', column: 2, row: 3);
      expect(a, b);
      expect(a.hashCode, b.hashCode);
    });

    test('value equality: atlasId differs', () {
      final a = SurfaceAtlasTileRef(atlasId: 'a', column: 0, row: 0);
      final b = SurfaceAtlasTileRef(atlasId: 'b', column: 0, row: 0);
      expect(a, isNot(b));
    });

    test('value equality: column differs', () {
      final a = SurfaceAtlasTileRef(atlasId: 'a', column: 0, row: 0);
      final b = SurfaceAtlasTileRef(atlasId: 'a', column: 1, row: 0);
      expect(a, isNot(b));
    });

    test('value equality: row differs', () {
      final a = SurfaceAtlasTileRef(atlasId: 'a', column: 0, row: 0);
      final b = SurfaceAtlasTileRef(atlasId: 'a', column: 0, row: 1);
      expect(a, isNot(b));
    });

    test('export: type is visible through map_core', () {
      final ref = SurfaceAtlasTileRef(atlasId: 'a', column: 0, row: 0);
      expect(ref, isA<SurfaceAtlasTileRef>());
    });

    test('ProjectManifest toJson: no surface* top-level keys', () {
      const manifest = ProjectManifest(
        name: 'L24',
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
```


## État `git` (lecture seule, fin de lot)

Exemple de sortie attendue : `M packages/map_core/lib/src/models/surface.dart`, `?? packages/map_core/test/surface_atlas_tile_ref_test.dart`, `?? reports/surface/surface_engine_lot_24_surface_atlas_tile_ref.md`.

---

*Rapport Lot 24 — Surface Atlas Tile Ref V0 — map_core only.*
