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
