# Lot 22 — Surface Atlas Geometry Value Objects V0

**Date (rédaction)** : 2026-04-26  
**Périmètre** : `surface.dart` + `test/surface_atlas_geometry_test.dart` + ce rapport. **Aucun** `ProjectManifest`, **aucun** généré, **aucun** autre package.

---

## 1. Résumé exécutif

Ajout de trois value objects `final` immuables : [`SurfaceAtlasTileSize`], [`SurfaceAtlasGridSize`], [`SurfaceAtlasGeometry`], en prolongeant l’`enum` existant `SurfaceAtlasLayout` (inchangé en intention). Validations `> 0` via `ValidationException`, `==` / `hashCode` pour l’égalité de valeur, `SurfaceAtlasGeometry.tileCount` en délégation vers `gridSize.tileCount`, `containsGridCoordinate` en indices de grille. Suite `map_core` : **+547** (dont **+20** pour le nouveau fichier de test), **analyse ciblée** : **No issues found!** `map_core.dart` : **non modifié** (export `surface.dart` déjà en place, Lot 21).

---

## 2. Pourquoi ce lot vient après le Lot 21 / 21-bis

Le Lot 21 a posé le vocabulaire de **layout** ; le 21-bis a figé les preuves. Le Lot 22 ajoute le **découpage** minimal (taille de tuile, taille de grille, géométrie) pour préparer de futurs modèles `ProjectSurfaceAtlas` **sans** introduire de persistance JSON.

---

## 3. Fichiers consultés

- `packages/map_core/lib/src/models/surface.dart` (avant : enum seul)  
- `packages/map_core/lib/map_core.dart` (exports)  
- `packages/map_core/lib/src/exceptions/map_exceptions.dart`  
- `packages/map_core/test/surface_model_entrypoint_test.dart`  
- `reports/surface/surface_engine_lot_21_surface_model_entrypoint.md`  
- `reports/surface/surface_engine_lot_21b_surface_model_entrypoint_evidence_fix.md`  
- `surface project/pokemap_surface_engine_micro_lots.md` (lecture légère)  
- `surface project/pokemap_surface_engine_spec.md` (lecture légère)

---

## 4. Fichiers créés

| Fichier | Rôle |
|---------|------|
| `packages/map_core/test/surface_atlas_geometry_test.dart` | Couverture functional + garde-fous manifest |
| `reports/surface/surface_engine_lot_22_surface_atlas_geometry_value_objects.md` | Rapport (ce document) |

---

## 5. Fichiers modifiés

| Fichier | Rôle |
|---------|------|
| `packages/map_core/lib/src/models/surface.dart` | + value objects, `import meta` pour `@immutable` |

**Non modifié** : `map_core.dart` (barrel) — inutile de retoucher l’export.

---

## 6. API ajoutée

- `SurfaceAtlasTileSize` : `width`, `height` (pixels de tuile, entiers `> 0`)  
- `SurfaceAtlasGridSize` : `columns`, `rows` (`> 0`), getter `tileCount`  
- `SurfaceAtlasGeometry` : `tileSize`, `gridSize`, `layout` (défaut `SurfaceAtlasLayout.grid`), `tileCount` (délégation), `containsGridCoordinate`  
- `SurfaceAtlasLayout` : **inchangé** (mêmes trois constantes, même ordre de déclaration)

---

## 7. Sémantique de `SurfaceAtlasTileSize`

Dimensions **strictement positives** ; sinon `ValidationException` avec messages explicites. Aucun lien avec un asset chargé, pas de JSON. Égalité sur `(width, height)`.

---

## 8. Sémantique de `SurfaceAtlasGridSize`

`columns` et `rows` **> 0** ; `tileCount` = `columns * rows`. Pas de sémantique “variante/frame” ici (réservé au couple layout + outillage futur). Égalité sur `(columns, rows)`.

---

## 9. Sémantique de `SurfaceAtlasGeometry`

Compose les trois blocs. **Ne vérifie pas** que `tileSize.width * gridSize.columns` égale la largeur d’une texture — volontairement hors scope. `containsGridCoordinate` : indices **0-based** de **colonne** / **ligne** de **grille** (pas pixels). `layout` hérité des lots 11–19 quand = `columnsAreVariantsRowsAreFrames`. Égalité sur `(tileSize, gridSize, layout)`.

---

## 10. Ce qui a été testé

- Validations négatives (8 cas sur tile + grid)  
- Égalité / `hashCode` (tile, grid, geometry avec variations de layout, tile, grid)  
- `tileCount` (736 pour 23×32) et délégation sur geometry  
- Layout par défaut `grid`  
- `containsGridCoordinate` (positifs + négatifs listés par le prompt)  
- Export : résolution de symboles via `map_core`  
- `ProjectManifest.toJson()` : toujours pas de clés `surface*`

---

## 11. Ce que les tests prouvent

- Comportement identique à la spec de lot ; **+20** tests pour ce fichier.  
- Le contrat manifest n’a **pas** gagné de champs surface au seul effet d’inclure des types Dart dans `surface.dart`.  
- Non-régression d’`import` public.

---

## 12. Ce qui n’a volontairement pas été fait

- Pas de `copyWith`, pas de `toString` personnalisé (hors lot).  
- Pas de `ProjectSurfaceAtlas`, `SurfaceLayer`, champs JSON.  
- Pas de `build_runner` / `part` / générés.  
- Pas d’autres paquets (runtime, editor, …).

---

## 13. Pourquoi `ProjectManifest` n’a toujours pas été modifié

Aucun besoin d’enregistrement côté projet tant que le schéma `surface*` n’est pas spécifié en lot ultérieur ; évite migration prématurée.

---

## 14. Pourquoi aucun fichier generated

Les types sont des classes Dart pures, sans annotation `json_serializable` / `freezed`.

---

## 15. Impact prochains lots

- Base pour un futur DTO/Freezed `ProjectSurfaceAtlas` référençant `SurfaceAtlasGeometry` et des IDs de ressource.  
- `containsGridCoordinate` pourra alimenter des validateurs d’index (tile sheet) côté auteur ou outils.

---

## 16. Commandes lancées

```bash
cd packages/map_core
/opt/homebrew/bin/dart test test/surface_atlas_geometry_test.dart
/opt/homebrew/bin/dart test test/surface_model_entrypoint_test.dart
/opt/homebrew/bin/dart analyze \
  lib/src/models/surface.dart \
  test/surface_atlas_geometry_test.dart \
  test/surface_model_entrypoint_test.dart \
  lib/map_core.dart
/opt/homebrew/bin/dart test
```

---

## 17. Résultats exacts (extraits retenus)

**Tests `surface_atlas_geometry_test.dart`** : progression jusqu’à `+20: All tests passed!`, **exit 0**.  
**Tests `surface_model_entrypoint_test.dart`** : `+3: All tests passed!`, **exit 0**.  
**`dart analyze` (4 chemins)** :

```text
Analyzing surface.dart, surface_atlas_geometry_test.dart, surface_model_entrypoint_test.dart, map_core.dart...
No issues found!
```

**Suite complète (fin de log)** :

```text
00:01 +547: All tests passed!
```

---

## 18. Total exact — `dart test` complet (`map_core`)

**+547** — **All tests passed!**  
*(+20 par rapport au +527 documenté après le Lot 21 / 21-bis : uniquement le nouveau fichier de test.)*

---

## 19. Points de vigilance

- `hashCode` / `==` : collision théorique possible (comportement standard `Object.hash`).  
- `containsGridCoordinate` n’impose **pas** que `layout` corresponde à l’ordre d’itération d’un moteur de rendu.  
- Constructeurs **non** `const` (validations au corps) : les appels de test ne peuvent pas utiliser `const` sur ces instances.

---

## 20. Autocritique finale

- L’import `package:meta/meta.dart` est un **ajout de dépendance d’implémentation** (déjà en `pubspec` de `map_core`) pour `@immutable` — alternative possible : retirer `@immutable` et s’en tenir à `final` + commentaires, si l’on veut le fichier **sans** `meta` au prochain refacto micro-lot.  
- Pas de `toString` : debug moins pratique jusqu’au prochain lot.

---

## 21. Ce que le prompt semble discutable ou incomplet

- “Importer uniquement `map_core`” pour les **tests** : le harness `test` reste nécessaire (comme Lot 21).  
- Exigence d’`equality` : pas de règle pour les collisions de `hashCode` (acceptable).

---

## 22. Auto-review indépendante (réponses explicites)

| Question | Réponse |
|----------|---------|
| Périmètre value objects atlas uniquement ? | **Oui** |
| `ProjectManifest` non modifié ? | **Oui** |
| Pas de gros modèle manifest / Freezed / `.g` ? | **Oui** |
| Runtime / editor / gameplay / battle ? | **Non touché** |
| `SurfaceAtlasLayout` préservé ? | **Oui** (enum intact) |
| Validations `TileSize` / `GridSize` ? | **Oui** |
| `tileCount` sur geometry délègue ? | **Oui** |
| `containsGridCoordinate` = grille, pas pixels ? | **Oui** (doc + tests) |
| Égalité testée ? | **Oui** |
| Export `map_core` ? | **Oui** |
| Clés surface absentes du `toJson()` manifest (test) ? | **Oui** |
| Suite +547 ? | **Oui** |
| Contenus & diff (réponse + dépôt) ? | **Oui** (fichiers dans l’arbre) |
| Pas de `git` write ? | **Oui** (session agent) |

---

## 23. Contenu intégral des fichiers créés / modifiés (copie dans ce rapport)

Les blocs ci-dessous sont une **copie intégrale** des sources telles qu’enregistrées pour le Lot 22 (fences en 4 backticks pour éviter les conflits si le texte contient des triples backticks ailleurs).

### 23.1 `packages/map_core/lib/src/models/surface.dart` (fichier modifié, contenu intégral)

````dart
// Fichier d’entrée Surface (map_core) : pas de persistance, pas de JSON ici.
// Les types ci-dessous décrivent seulement une **géométrie d’atlas** (tailles, grille,
// convention de layout) pour une future intégration (ex. `ProjectSurfaceAtlas`, hors
// scope des lots actuels).

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
````

### 23.2 `packages/map_core/test/surface_atlas_geometry_test.dart` (fichier créé, contenu intégral)

````dart
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('SurfaceAtlasTileSize', () {
    test('keeps width and height', () {
      final size = SurfaceAtlasTileSize(width: 32, height: 16);
      expect(size.width, 32);
      expect(size.height, 16);
    });

    test('rejects non-positive width: 0', () {
      expect(
        () => SurfaceAtlasTileSize(width: 0, height: 1),
        throwsA(isA<ValidationException>()),
      );
    });

    test('rejects non-positive width: -1', () {
      expect(
        () => SurfaceAtlasTileSize(width: -1, height: 1),
        throwsA(isA<ValidationException>()),
      );
    });

    test('rejects non-positive height: 0', () {
      expect(
        () => SurfaceAtlasTileSize(width: 1, height: 0),
        throwsA(isA<ValidationException>()),
      );
    });

    test('rejects non-positive height: -1', () {
      expect(
        () => SurfaceAtlasTileSize(width: 1, height: -1),
        throwsA(isA<ValidationException>()),
      );
    });

    test('value equality: same values => equal and same hashCode', () {
      final a = SurfaceAtlasTileSize(width: 12, height: 8);
      final b = SurfaceAtlasTileSize(width: 12, height: 8);
      expect(a, b);
      expect(a.hashCode, b.hashCode);
    });

    test('value equality: different => not equal', () {
      final a = SurfaceAtlasTileSize(width: 12, height: 8);
      final b = SurfaceAtlasTileSize(width: 10, height: 8);
      expect(a, isNot(b));
    });
  });

  group('SurfaceAtlasGridSize', () {
    test('keeps columns, rows, tileCount', () {
      final g = SurfaceAtlasGridSize(columns: 23, rows: 32);
      expect(g.columns, 23);
      expect(g.rows, 32);
      expect(g.tileCount, 736);
    });

    test('rejects non-positive columns: 0', () {
      expect(
        () => SurfaceAtlasGridSize(columns: 0, rows: 1),
        throwsA(isA<ValidationException>()),
      );
    });

    test('rejects non-positive columns: -1', () {
      expect(
        () => SurfaceAtlasGridSize(columns: -1, rows: 1),
        throwsA(isA<ValidationException>()),
      );
    });

    test('rejects non-positive rows: 0', () {
      expect(
        () => SurfaceAtlasGridSize(columns: 1, rows: 0),
        throwsA(isA<ValidationException>()),
      );
    });

    test('rejects non-positive rows: -1', () {
      expect(
        () => SurfaceAtlasGridSize(columns: 1, rows: -1),
        throwsA(isA<ValidationException>()),
      );
    });

    test('value equality: same => equal; different => not', () {
      final a = SurfaceAtlasGridSize(columns: 2, rows: 3);
      final b = SurfaceAtlasGridSize(columns: 2, rows: 3);
      final c = SurfaceAtlasGridSize(columns: 2, rows: 4);
      expect(a, b);
      expect(a.hashCode, b.hashCode);
      expect(a, isNot(c));
    });
  });

  group('SurfaceAtlasGeometry', () {
    test('keeps fields and delegates tileCount', () {
      final tileSize = SurfaceAtlasTileSize(width: 32, height: 32);
      final gridSize = SurfaceAtlasGridSize(columns: 23, rows: 32);
      final geometry = SurfaceAtlasGeometry(
        tileSize: tileSize,
        gridSize: gridSize,
        layout: SurfaceAtlasLayout.columnsAreVariantsRowsAreFrames,
      );
      expect(geometry.tileSize, same(tileSize));
      expect(geometry.gridSize, same(gridSize));
      expect(
        geometry.layout,
        SurfaceAtlasLayout.columnsAreVariantsRowsAreFrames,
      );
      expect(geometry.tileCount, 736);
    });

    test('default layout is grid', () {
      final tileSize = SurfaceAtlasTileSize(width: 8, height: 8);
      final gridSize = SurfaceAtlasGridSize(columns: 1, rows: 1);
      final geometry = SurfaceAtlasGeometry(
        tileSize: tileSize,
        gridSize: gridSize,
      );
      expect(geometry.layout, SurfaceAtlasLayout.grid);
    });

    test('containsGridCoordinate: interior points in range', () {
      final tile = SurfaceAtlasTileSize(width: 1, height: 1);
      final grid = SurfaceAtlasGridSize(columns: 3, rows: 2);
      final g = SurfaceAtlasGeometry(
        tileSize: tile,
        gridSize: grid,
        layout: SurfaceAtlasLayout.grid,
      );
      expect(g.containsGridCoordinate(column: 0, row: 0), isTrue);
      expect(g.containsGridCoordinate(column: 2, row: 1), isTrue);
      expect(g.containsGridCoordinate(column: 1, row: 1), isTrue);
    });

    test('containsGridCoordinate: out of range or negative', () {
      final tile = SurfaceAtlasTileSize(width: 1, height: 1);
      final grid = SurfaceAtlasGridSize(columns: 3, rows: 2);
      final g = SurfaceAtlasGeometry(
        tileSize: tile,
        gridSize: grid,
        layout: SurfaceAtlasLayout.grid,
      );
      expect(g.containsGridCoordinate(column: -1, row: 0), isFalse);
      expect(g.containsGridCoordinate(column: 0, row: -1), isFalse);
      expect(g.containsGridCoordinate(column: 3, row: 0), isFalse);
      expect(g.containsGridCoordinate(column: 0, row: 2), isFalse);
      expect(g.containsGridCoordinate(column: 99, row: 99), isFalse);
    });

    test('value equality: layout / tile / grid disambiguation', () {
      final t = SurfaceAtlasTileSize(width: 16, height: 16);
      final g32 = SurfaceAtlasGridSize(columns: 2, rows: 2);
      final a = SurfaceAtlasGeometry(
        tileSize: t,
        gridSize: g32,
        layout: SurfaceAtlasLayout.grid,
      );
      final b = SurfaceAtlasGeometry(
        tileSize: t,
        gridSize: g32,
        layout: SurfaceAtlasLayout.grid,
      );
      expect(a, b);
      expect(a.hashCode, b.hashCode);

      final c = SurfaceAtlasGeometry(
        tileSize: t,
        gridSize: g32,
        layout: SurfaceAtlasLayout.columnsAreVariantsRowsAreFrames,
      );
      expect(a, isNot(c));

      final t2 = SurfaceAtlasTileSize(width: 8, height: 8);
      final aTile = SurfaceAtlasGeometry(
        tileSize: t2,
        gridSize: g32,
        layout: SurfaceAtlasLayout.grid,
      );
      expect(a, isNot(aTile));

      final gOther = SurfaceAtlasGridSize(columns: 3, rows: 2);
      final aGrid = SurfaceAtlasGeometry(
        tileSize: t,
        gridSize: gOther,
        layout: SurfaceAtlasLayout.grid,
      );
      expect(a, isNot(aGrid));
    });
  });

  group('public export & manifest unchanged', () {
    test('map_core exposes all new types', () {
      // Types referenced above; if export breaks, this file will not resolve.
      expect(SurfaceAtlasLayout.values, isNotEmpty);
    });

    test('ProjectManifest toJson() still has no surface* top-level keys', () {
      const manifest = ProjectManifest(
        name: 'L22',
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

**Note** : `packages/map_core/lib/map_core.dart` n’a **pas** été modifié pour le Lot 22 (l’`export` de `surface.dart` date du Lot 21). Aucun contenu à recopier ici.

---

## 24. Diff / stat (intégral côté suivi, équivalent /dev/null pour le test)

### 24.1 `git diff --stat` (exemple local)

```text
 packages/map_core/lib/src/models/surface.dart | 126 +++++++++++++++++++++-
 1 file changed, 124 insertions(+), 2 deletions(-)
```

### 24.2 Rejouer le diff sur `surface.dart` depuis la branche

```bash
git diff -- packages/map_core/lib/src/models/surface.dart
```

*(La sortie complète est la différence entre la base git et le working tree / dernier commit selon l’état local.)*

### 24.3 Fichier de test (nouveau) — équivalent `diff -u /dev/null`

Tout le contenu du test est : **identique** au bloc **§23.2** (chaque ligne serait préfixée `+` dans un vrai `diff -u`).

### 24.4 Ce rapport Markdown

- **Nouveau fichier** : son contenu complet est **ce document** (y compris les sections 23–24 mises à jour). Pour un diff binaire, utiliser `diff -u /dev/null reports/surface/surface_engine_lot_22_surface_atlas_geometry_value_objects.md` après l’enregistrement.

---

*Fin — Lot 22*
