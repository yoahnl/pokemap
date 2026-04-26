# Lot 25 — Surface Animation Frame Value Object V0

## 1. Résumé exécutif

Introduction du value object **`SurfaceAnimationFrame`** dans `packages/map_core/lib/src/models/surface.dart` : une frame = [`SurfaceAtlasTileRef`] + `durationMs` (> 0), `isInside` en délégation vers `tileRef`, égalité sur `tileRef` + `durationMs`. Aucun JSON, pas de `ProjectManifest` modifié, pas de timeline ni moteur. Tests ciblés (14) + suite `map_core` : **597** tests verts. `dart analyze` ciblé : **Aucun problème**.

## 2. Pourquoi ce lot vient après le Lot 24

Le **Lot 24** a posé l’adresse de tuile (`SurfaceAtlasTileRef`). Le **Lot 25** additionne le **rythme d’affichage** d’**une** frame (`durationMs`) pour préparer, plus tard, des timelines ou des animations Surface, sans les implémenter.

## 3. Fichiers consultés (audit)

- `packages/map_core/lib/src/models/surface.dart` (types Surface existants, dont `SurfaceAtlasTileRef`)
- Tests : `surface_atlas_tile_ref_test.dart`, `project_surface_atlas_test.dart`, `surface_atlas_geometry_test.dart`, `surface_model_entrypoint_test.dart`
- `map_core.dart` : export `surface.dart` déjà présent
- `map_exceptions.dart` : `ValidationException`
- Conventions (aperçu) : `project_manifest.dart`, `visual_frame_json.dart` (hors lot)
- Rapports lots 21–24

**Constat :** `SurfaceAtlasTileRef` valide déjà les coordonnées / `atlasId` — pas de revalidation au niveau de `SurfaceAnimationFrame`.

## 4. Fichiers créés

- `packages/map_core/test/surface_animation_frame_test.dart`
- `reports/surface/surface_engine_lot_25_surface_animation_frame.md` (ce document)

## 5. Fichiers modifiés

- `packages/map_core/lib/src/models/surface.dart` uniquement (ajout de `SurfaceAnimationFrame` en fin de fichier)

**Inchangés :** `map_core/lib/map_core.dart`, `project_manifest.dart`, autres packages, aucun fichier généré.

## 6. API ajoutée

```dart
@immutable
final class SurfaceAnimationFrame {
  SurfaceAnimationFrame({
    required SurfaceAtlasTileRef tileRef,
    required int durationMs,
  });

  final SurfaceAtlasTileRef tileRef;
  final int durationMs;

  bool isInside(SurfaceAtlasGeometry geometry);

  @override
  bool operator ==(Object other) => /* tileRef, durationMs */;

  @override
  int get hashCode => Object.hash(tileRef, durationMs);
}
```

## 7. Sémantique de `SurfaceAnimationFrame`

- **Rôle** : modèle de domaine pour **une** frame (tuile + durée) ; **pas** une animation complète, **pas** de JSON, **pas** de lecture du temps d’exécution.
- **`tileRef`** : instance **conservée telle quelle** ; pas de revalidation de `atlasId` / `column` / `row`.
- **`durationMs`** : entier > 0 ; **donnée** seule, pas un moteur.

## 8. Validation de `durationMs`

`durationMs <= 0` (y compris 0) lève `ValidationException('SurfaceAnimationFrame.durationMs must be > 0')`.

## 9. Sémantique de `isInside`

`isInside(geometry)` retourne `tileRef.isInside(geometry)` — donc ne résout pas `atlasId`, ne touche pas au manifest, ne charge rien, indépendant d’un moteur runtime (même sémantique que le Lot 24, une couche de plus par délégation).

## 10. Ce qui a été testé

14 cas : champs, identité de `tileRef`, rejets `durationMs` 0 / -1, acceptation 1, `isInside` vrai / faux, indépendance du layout, égalité (même / différents `tileRef` / `durationMs`), export public, `ProjectManifest.toJson` sans clés `surface*`.

## 11. Ce que les tests prouvent

- Comportement VO + règles `durationMs`.
- Délégation `isInside` (via le même `tileRef` que le Lot 24).
- Aucun ajout de clés surface au JSON manifest minimal.
- API exposée par `package:map_core/map_core.dart`.

## 12. Ce qui n’a volontairement pas été fait

- Timeline, liste de frames, `ProjectSurfaceAnimation`, persistance, resolver `atlasId` → atlas.

## 13. Pourquoi `ProjectManifest` n’a toujours pas été modifié

L’apparition des listes `surfaceAtlases` / `surfaceAnimations` etc. est **reportée** : les types restent en domaine pur pour stabiliser sémantique et tests.

## 14. Pourquoi aucun fichier généré n’a été créé

Value object manuel, cohérent avec `SurfaceAtlasTileRef` / géométrie, sans `build_runner` ni Freezed.

## 15. Impact pour les prochains lots Surface

- Les timelines pourront s’appuyer sur des **`SurfaceAnimationFrame`** existants (liste hors scope ici).
- `durationMs` est prêt à être enchaîné par un moteur ultérieur.

## 16. Commandes lancées

Toutes dans `packages/map_core` avec `/opt/homebrew/bin/dart`.

- `dart test test/surface_animation_frame_test.dart` → dernière ligne : `+14: All tests passed!` (exit 0)
- `dart test` sur `surface_atlas_tile_ref_test.dart`, `project_surface_atlas_test.dart`, `surface_atlas_geometry_test.dart`, `surface_model_entrypoint_test.dart` (groupe) → `+59: All tests passed!` (exit 0)
- `dart analyze` (chemins : `surface.dart`, 5 tests, `map_core.dart`) → `No issues found!` (exit 0)
- `dart test` (tout le package) → dernière ligne : `+597: All tests passed!` (exit 0)

## 17. Résultats exacts des tests ciblés

| Commande / lot | Dernière ligne |
|----------------|----------------|
| `surface_animation_frame_test.dart` | `+14: All tests passed!` |
| 4 tests Surface (regroupés) | `+59: All tests passed!` |

## 18. Total exact du `dart test` complet (map_core)

**597** tests, tous passés (`+597: All tests passed!`).

## 19. Points de vigilance

- L’égalité repose sur celle de `SurfaceAtlasTileRef` (valeur, pas seulement identité d’objet) + `durationMs` — `tileRef` est pourtant **stocké** sans copie, ce qui n’affecte pas `==` entre deux instances distinctes de frame aux refs égales.
- Aucun plafond sur `durationMs` (entier > 0 seulement) — un moteur futur pourra borner.

## 20. Autocritique finale

- Un test `row` différent en plus de `atlasId` / `column` n’est pas exigé distinctement (couvert par l’inégalité `SurfaceAtlasTileRef` + cas colonne).

## 21. Ce que le prompt semble discutable ou incomplet

- Rien de bloquant. La contrainte « ne pas revalider atlas/column/row » est **respectée** en ne testant que `durationMs` côté `SurfaceAnimationFrame` et en documentant la délégation.

## 22. Auto-review indépendante

| Question | Oui / Non |
|----------|-----------|
| Lot limité à `SurfaceAnimationFrame` + test + rapport ? | **Oui** |
| Aucun `ProjectManifest` modifié (source) ? | **Oui** |
| Aucun champ surface persistant ajouté ? | **Oui** |
| Aucun Freezed/JSON généré, pas de `.g.dart`/`.freezed.dart` ? | **Oui** |
| Aucun autre package modifié ? | **Oui** |
| Types Surface antérieurs compatibles (pas de break) ? | **Oui** |
| `durationMs` validé (> 0) ? | **Oui** |
| Pas de résolution `atlasId` ? | **Oui** |
| `isInside` → `SurfaceAtlasTileRef.isInside` ? | **Oui** |
| Égalité testée ? | **Oui** |
| Export public ? | **Oui** |
| Manifest `toJson` sans clés `surface*` testé ? | **Oui** |
| `map_core` 597 / 597 ? | **Oui** |
| Commandes `git` d’**écriture** utilisées ? | **Non** (respect de la consigne) |

**Verdicts (passes simulées) :** Audit OK · Impl. OK · Tests OK · Analyse/CI locale OK · Critique OK.

## 23. Contenu complet des fichiers (verbatim)

Le fichier modifié `surface.dart` et le fichier de test **complets** sont injectés en **section 25** ci-dessous (générés à partir des fichiers disque).

## 24. Diff complet réel

### 24.A `git diff` — `packages/map_core/lib/src/models/surface.dart`

Voir sortie `git` ci-dessous (hachage d’index tel que sur le poste de validation).

```diff
diff --git a/packages/map_core/lib/src/models/surface.dart b/packages/map_core/lib/src/models/surface.dart
index b776c8f8..188fe0e5 100644
--- a/packages/map_core/lib/src/models/surface.dart
+++ b/packages/map_core/lib/src/models/surface.dart
@@ -286,3 +286,50 @@ final class SurfaceAtlasTileRef {
   @override
   int get hashCode => Object.hash(atlasId, column, row);
 }
+
+/// **Une** frame d’animation Surface côté domaine : [tileRef] (tuile d’atlas) +
+/// [durationMs] (durée d’affichage en millisecondes).
+///
+/// * Modèle pur : **aucun** [toJson] / [fromJson] ; ne constitue **pas** une
+///   timeline, une liste de frames ni un moteur d’animation.
+/// * [durationMs] n’est qu’une **donnée** (pas d’horloge, pas de « temps
+///   courant », pas d’exécution runtime).
+/// * [tileRef] reste une [SurfaceAtlasTileRef] logique, **non résolue** vers un
+///   [ProjectSurfaceAtlas] ou un manifest — pas de chargement de texture, pas
+///   de vérification de fichier image ici.
+/// * [isInside] se contente de déléguer à [SurfaceAtlasTileRef.isInside] (la
+///   [SurfaceAtlasTileRef] a déjà validé `atlasId` / `column` / `row`) ; ce
+///   constructeur ne re-valide pas ces champs.
+@immutable
+final class SurfaceAnimationFrame {
+  SurfaceAnimationFrame({
+    required this.tileRef,
+    required this.durationMs,
+  }) {
+    if (durationMs <= 0) {
+      throw const ValidationException(
+        'SurfaceAnimationFrame.durationMs must be > 0',
+      );
+    }
+  }
+
+  /// Référence de la tuile à afficher (instance conservée telle quelle).
+  final SurfaceAtlasTileRef tileRef;
+
+  /// Durée d’affichage de la frame, en millisecondes (strictement positive).
+  final int durationMs;
+
+  /// Vérifie que la [tileRef] tient dans [geometry] (délègue, sans autre
+  /// sémantique d’animation).
+  bool isInside(SurfaceAtlasGeometry geometry) => tileRef.isInside(geometry);
+
+  @override
+  bool operator ==(Object other) =>
+      identical(this, other) ||
+      other is SurfaceAnimationFrame &&
+          other.tileRef == tileRef &&
+          other.durationMs == durationMs;
+
+  @override
+  int get hashCode => Object.hash(tileRef, durationMs);
+}
```

### 24.B Fichier nouveau `test/surface_animation_frame_test.dart`

Diff obtenu par `diff -u /dev/null` : voir intégralité en **section 25.B** (chaque ligne de code précédée de `+`).

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

/// **Une** frame d’animation Surface côté domaine : [tileRef] (tuile d’atlas) +
/// [durationMs] (durée d’affichage en millisecondes).
///
/// * Modèle pur : **aucun** [toJson] / [fromJson] ; ne constitue **pas** une
///   timeline, une liste de frames ni un moteur d’animation.
/// * [durationMs] n’est qu’une **donnée** (pas d’horloge, pas de « temps
///   courant », pas d’exécution runtime).
/// * [tileRef] reste une [SurfaceAtlasTileRef] logique, **non résolue** vers un
///   [ProjectSurfaceAtlas] ou un manifest — pas de chargement de texture, pas
///   de vérification de fichier image ici.
/// * [isInside] se contente de déléguer à [SurfaceAtlasTileRef.isInside] (la
///   [SurfaceAtlasTileRef] a déjà validé `atlasId` / `column` / `row`) ; ce
///   constructeur ne re-valide pas ces champs.
@immutable
final class SurfaceAnimationFrame {
  SurfaceAnimationFrame({
    required this.tileRef,
    required this.durationMs,
  }) {
    if (durationMs <= 0) {
      throw const ValidationException(
        'SurfaceAnimationFrame.durationMs must be > 0',
      );
    }
  }

  /// Référence de la tuile à afficher (instance conservée telle quelle).
  final SurfaceAtlasTileRef tileRef;

  /// Durée d’affichage de la frame, en millisecondes (strictement positive).
  final int durationMs;

  /// Vérifie que la [tileRef] tient dans [geometry] (délègue, sans autre
  /// sémantique d’animation).
  bool isInside(SurfaceAtlasGeometry geometry) => tileRef.isInside(geometry);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SurfaceAnimationFrame &&
          other.tileRef == tileRef &&
          other.durationMs == durationMs;

  @override
  int get hashCode => Object.hash(tileRef, durationMs);
}
```


### 25.B `packages/map_core/test/surface_animation_frame_test.dart`

```dart
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('SurfaceAnimationFrame', () {
    test('minimal frame holds tileRef and durationMs', () {
      final tileRef = SurfaceAtlasTileRef(
        atlasId: 'water-atlas',
        column: 3,
        row: 4,
      );

      final frame = SurfaceAnimationFrame(
        tileRef: tileRef,
        durationMs: 120,
      );

      expect(frame.tileRef, tileRef);
      expect(frame.durationMs, 120);
    });

    test('preserves the exact same tileRef instance (identity)', () {
      final tileRef = SurfaceAtlasTileRef(
        atlasId: 'a',
        column: 0,
        row: 0,
      );
      final frame = SurfaceAnimationFrame(
        tileRef: tileRef,
        durationMs: 50,
      );
      expect(identical(frame.tileRef, tileRef), isTrue);
    });

    test('rejects durationMs == 0', () {
      final ref = SurfaceAtlasTileRef(atlasId: 'x', column: 0, row: 0);
      expect(
        () => SurfaceAnimationFrame(tileRef: ref, durationMs: 0),
        throwsA(isA<ValidationException>()),
      );
    });

    test('rejects durationMs < 0', () {
      final ref = SurfaceAtlasTileRef(atlasId: 'x', column: 0, row: 0);
      expect(
        () => SurfaceAnimationFrame(tileRef: ref, durationMs: -1),
        throwsA(isA<ValidationException>()),
      );
    });

    test('accepts durationMs == 1', () {
      final ref = SurfaceAtlasTileRef(atlasId: 'x', column: 0, row: 0);
      final frame = SurfaceAnimationFrame(
        tileRef: ref,
        durationMs: 1,
      );
      expect(frame.durationMs, 1);
    });

    test('isInside: true for interior cell', () {
      final geometry = SurfaceAtlasGeometry(
        tileSize: SurfaceAtlasTileSize(width: 32, height: 32),
        gridSize: SurfaceAtlasGridSize(columns: 4, rows: 3),
      );
      final frame = SurfaceAnimationFrame(
        tileRef: SurfaceAtlasTileRef(
          atlasId: 'a',
          column: 3,
          row: 2,
        ),
        durationMs: 10,
      );
      expect(frame.isInside(geometry), isTrue);
    });

    test('isInside: false when cell out of grid', () {
      final geometry = SurfaceAtlasGeometry(
        tileSize: SurfaceAtlasTileSize(width: 32, height: 32),
        gridSize: SurfaceAtlasGridSize(columns: 4, rows: 3),
      );
      final frame = SurfaceAnimationFrame(
        tileRef: SurfaceAtlasTileRef(
          atlasId: 'a',
          column: 4,
          row: 0,
        ),
        durationMs: 10,
      );
      expect(frame.isInside(geometry), isFalse);
    });

    test('isInside: same frame independent of layout enum', () {
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
      final frame = SurfaceAnimationFrame(
        tileRef: SurfaceAtlasTileRef(
          atlasId: 'a',
          column: 1,
          row: 1,
        ),
        durationMs: 5,
      );
      expect(frame.isInside(gGrid), isTrue);
      expect(frame.isInside(gVertical), isTrue);
    });

    test('value equality: same tile values and duration => equal and same hash', () {
      final a = SurfaceAnimationFrame(
        tileRef: SurfaceAtlasTileRef(
          atlasId: 'a',
          column: 1,
          row: 2,
        ),
        durationMs: 100,
      );
      final b = SurfaceAnimationFrame(
        tileRef: SurfaceAtlasTileRef(
          atlasId: 'a',
          column: 1,
          row: 2,
        ),
        durationMs: 100,
      );
      expect(a, b);
      expect(a.hashCode, b.hashCode);
    });

    test('value equality: different tileRef (atlasId)', () {
      final a = SurfaceAnimationFrame(
        tileRef: SurfaceAtlasTileRef(
          atlasId: 'a',
          column: 0,
          row: 0,
        ),
        durationMs: 10,
      );
      final b = SurfaceAnimationFrame(
        tileRef: SurfaceAtlasTileRef(
          atlasId: 'b',
          column: 0,
          row: 0,
        ),
        durationMs: 10,
      );
      expect(a, isNot(b));
    });

    test('value equality: different tileRef (column)', () {
      final a = SurfaceAnimationFrame(
        tileRef: SurfaceAtlasTileRef(
          atlasId: 'a',
          column: 0,
          row: 0,
        ),
        durationMs: 10,
      );
      final b = SurfaceAnimationFrame(
        tileRef: SurfaceAtlasTileRef(
          atlasId: 'a',
          column: 1,
          row: 0,
        ),
        durationMs: 10,
      );
      expect(a, isNot(b));
    });

    test('value equality: different durationMs', () {
      final ref = SurfaceAtlasTileRef(
        atlasId: 'a',
        column: 0,
        row: 0,
      );
      final a = SurfaceAnimationFrame(tileRef: ref, durationMs: 10);
      final b = SurfaceAnimationFrame(tileRef: ref, durationMs: 20);
      expect(a, isNot(b));
    });

    test('export: type is visible through map_core', () {
      final frame = SurfaceAnimationFrame(
        tileRef: SurfaceAtlasTileRef(
          atlasId: 'a',
          column: 0,
          row: 0,
        ),
        durationMs: 1,
      );
      expect(frame, isA<SurfaceAnimationFrame>());
    });

    test('ProjectManifest toJson: no surface* top-level keys', () {
      const manifest = ProjectManifest(
        name: 'L25',
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

### 25.C Diff `diff -u /dev/null` (test)

```diff
--- /dev/null	2026-04-26 23:27:32
+++ /Users/karim/Project/pokemonProject/packages/map_core/test/surface_animation_frame_test.dart	2026-04-26 23:26:57
@@ -0,0 +1,225 @@
+import 'package:map_core/map_core.dart';
+import 'package:test/test.dart';
+
+void main() {
+  group('SurfaceAnimationFrame', () {
+    test('minimal frame holds tileRef and durationMs', () {
+      final tileRef = SurfaceAtlasTileRef(
+        atlasId: 'water-atlas',
+        column: 3,
+        row: 4,
+      );
+
+      final frame = SurfaceAnimationFrame(
+        tileRef: tileRef,
+        durationMs: 120,
+      );
+
+      expect(frame.tileRef, tileRef);
+      expect(frame.durationMs, 120);
+    });
+
+    test('preserves the exact same tileRef instance (identity)', () {
+      final tileRef = SurfaceAtlasTileRef(
+        atlasId: 'a',
+        column: 0,
+        row: 0,
+      );
+      final frame = SurfaceAnimationFrame(
+        tileRef: tileRef,
+        durationMs: 50,
+      );
+      expect(identical(frame.tileRef, tileRef), isTrue);
+    });
+
+    test('rejects durationMs == 0', () {
+      final ref = SurfaceAtlasTileRef(atlasId: 'x', column: 0, row: 0);
+      expect(
+        () => SurfaceAnimationFrame(tileRef: ref, durationMs: 0),
+        throwsA(isA<ValidationException>()),
+      );
+    });
+
+    test('rejects durationMs < 0', () {
+      final ref = SurfaceAtlasTileRef(atlasId: 'x', column: 0, row: 0);
+      expect(
+        () => SurfaceAnimationFrame(tileRef: ref, durationMs: -1),
+        throwsA(isA<ValidationException>()),
+      );
+    });
+
+    test('accepts durationMs == 1', () {
+      final ref = SurfaceAtlasTileRef(atlasId: 'x', column: 0, row: 0);
+      final frame = SurfaceAnimationFrame(
+        tileRef: ref,
+        durationMs: 1,
+      );
+      expect(frame.durationMs, 1);
+    });
+
+    test('isInside: true for interior cell', () {
+      final geometry = SurfaceAtlasGeometry(
+        tileSize: SurfaceAtlasTileSize(width: 32, height: 32),
+        gridSize: SurfaceAtlasGridSize(columns: 4, rows: 3),
+      );
+      final frame = SurfaceAnimationFrame(
+        tileRef: SurfaceAtlasTileRef(
+          atlasId: 'a',
+          column: 3,
+          row: 2,
+        ),
+        durationMs: 10,
+      );
+      expect(frame.isInside(geometry), isTrue);
+    });
+
+    test('isInside: false when cell out of grid', () {
+      final geometry = SurfaceAtlasGeometry(
+        tileSize: SurfaceAtlasTileSize(width: 32, height: 32),
+        gridSize: SurfaceAtlasGridSize(columns: 4, rows: 3),
+      );
+      final frame = SurfaceAnimationFrame(
+        tileRef: SurfaceAtlasTileRef(
+          atlasId: 'a',
+          column: 4,
+          row: 0,
+        ),
+        durationMs: 10,
+      );
+      expect(frame.isInside(geometry), isFalse);
+    });
+
+    test('isInside: same frame independent of layout enum', () {
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
+      final frame = SurfaceAnimationFrame(
+        tileRef: SurfaceAtlasTileRef(
+          atlasId: 'a',
+          column: 1,
+          row: 1,
+        ),
+        durationMs: 5,
+      );
+      expect(frame.isInside(gGrid), isTrue);
+      expect(frame.isInside(gVertical), isTrue);
+    });
+
+    test('value equality: same tile values and duration => equal and same hash', () {
+      final a = SurfaceAnimationFrame(
+        tileRef: SurfaceAtlasTileRef(
+          atlasId: 'a',
+          column: 1,
+          row: 2,
+        ),
+        durationMs: 100,
+      );
+      final b = SurfaceAnimationFrame(
+        tileRef: SurfaceAtlasTileRef(
+          atlasId: 'a',
+          column: 1,
+          row: 2,
+        ),
+        durationMs: 100,
+      );
+      expect(a, b);
+      expect(a.hashCode, b.hashCode);
+    });
+
+    test('value equality: different tileRef (atlasId)', () {
+      final a = SurfaceAnimationFrame(
+        tileRef: SurfaceAtlasTileRef(
+          atlasId: 'a',
+          column: 0,
+          row: 0,
+        ),
+        durationMs: 10,
+      );
+      final b = SurfaceAnimationFrame(
+        tileRef: SurfaceAtlasTileRef(
+          atlasId: 'b',
+          column: 0,
+          row: 0,
+        ),
+        durationMs: 10,
+      );
+      expect(a, isNot(b));
+    });
+
+    test('value equality: different tileRef (column)', () {
+      final a = SurfaceAnimationFrame(
+        tileRef: SurfaceAtlasTileRef(
+          atlasId: 'a',
+          column: 0,
+          row: 0,
+        ),
+        durationMs: 10,
+      );
+      final b = SurfaceAnimationFrame(
+        tileRef: SurfaceAtlasTileRef(
+          atlasId: 'a',
+          column: 1,
+          row: 0,
+        ),
+        durationMs: 10,
+      );
+      expect(a, isNot(b));
+    });
+
+    test('value equality: different durationMs', () {
+      final ref = SurfaceAtlasTileRef(
+        atlasId: 'a',
+        column: 0,
+        row: 0,
+      );
+      final a = SurfaceAnimationFrame(tileRef: ref, durationMs: 10);
+      final b = SurfaceAnimationFrame(tileRef: ref, durationMs: 20);
+      expect(a, isNot(b));
+    });
+
+    test('export: type is visible through map_core', () {
+      final frame = SurfaceAnimationFrame(
+        tileRef: SurfaceAtlasTileRef(
+          atlasId: 'a',
+          column: 0,
+          row: 0,
+        ),
+        durationMs: 1,
+      );
+      expect(frame, isA<SurfaceAnimationFrame>());
+    });
+
+    test('ProjectManifest toJson: no surface* top-level keys', () {
+      const manifest = ProjectManifest(
+        name: 'L25',
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


---

*Fin du rapport — Lot 25 — SurfaceAnimationFrame (map_core seulement).*
