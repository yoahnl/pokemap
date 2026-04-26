// Fichier d’entrée Surface (map_core) : pas de persistance JSON, pas de `toJson` ici.
// Contient les enums (layout, rôles de variante d’autotile), les value objects
// de géométrie d’atlas, [ProjectSurfaceAtlas] / [ProjectSurfaceAnimation] —
// raccrochage manifest dans des lots ultérieurs.

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

/// Rôle visuel logique d’une cellule dans une surface autotilée (blob 47+).
///
/// C’est le **vocabulaire Surface natif** — indépendant de [TerrainPathVariant]
/// (monde legacy path) : aucun mapping n’est imposé ici, conversion éventuelle
/// dans un lot dédié. Ne désigne **pas** un identifiant de tuile, une animation
/// ni le gameplay.
enum SurfaceVariantRole {
  isolated,
  endNorth,
  endEast,
  endSouth,
  endWest,
  horizontal,
  vertical,
  cornerNE,
  cornerSE,
  cornerSW,
  cornerNW,
  innerCornerNE,
  innerCornerSE,
  innerCornerSW,
  innerCornerNW,
  teeNorth,
  teeEast,
  teeSouth,
  teeWest,
  cross,
}

/// Ordre d’indexation **stable** des variantes d’atlas (vertical-atlas, lots
/// 11–19) : **n’est pas** `SurfaceVariantRole.values` — chaque cas est listé
/// explicitement pour qu’un réordonnancement accidentel d’enum n’invalide pas
/// silencieusement le mapping atlas.
const List<SurfaceVariantRole> standardSurfaceVariantRoleOrder = [
  SurfaceVariantRole.isolated,
  SurfaceVariantRole.endNorth,
  SurfaceVariantRole.endEast,
  SurfaceVariantRole.endSouth,
  SurfaceVariantRole.endWest,
  SurfaceVariantRole.horizontal,
  SurfaceVariantRole.vertical,
  SurfaceVariantRole.cornerNE,
  SurfaceVariantRole.cornerSE,
  SurfaceVariantRole.cornerSW,
  SurfaceVariantRole.cornerNW,
  SurfaceVariantRole.innerCornerNE,
  SurfaceVariantRole.innerCornerSE,
  SurfaceVariantRole.innerCornerSW,
  SurfaceVariantRole.innerCornerNW,
  SurfaceVariantRole.teeNorth,
  SurfaceVariantRole.teeEast,
  SurfaceVariantRole.teeSouth,
  SurfaceVariantRole.teeWest,
  SurfaceVariantRole.cross,
];

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

/// Comparaison **ordonnée** de deux listes de frames (même longueur et égalité
/// élément par élément) — utile à [SurfaceAnimationTimeline] pour [operator ==]
/// sans dépendre d’un utilitaire de collection externe.
bool _surfaceAnimationFramesEqualInOrder(
  List<SurfaceAnimationFrame> a,
  List<SurfaceAnimationFrame> b,
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

/// Timeline d’animation Surface côté **domaine** : une liste **ordonnée** et
/// **immuable** de [SurfaceAnimationFrame].
///
/// * Pas de [toJson] / [fromJson] ; ne constitue **pas** [ProjectSurfaceAnimation]
///   ni d’enregistrement de projet.
/// * Aucun **temps courant**, **frame courante** ou moteur de lecture : c’est
///   seulement la séquence et les durées **déclarées** ; [totalDurationMs] est
///   la somme de ces durées, pas une exécution.
/// * [isInside] n’agit qu’en validation **géométrique** (toutes les frames
///   [SurfaceAnimationFrame.isInside]) : pas d’[atlasId] résolu, pas de manifest,
///   pas de texture, pas de runtime.
/// * La liste passée au constructeur est **copiée** puis enrobée en non modifiable
///   (une mutation de la source après construction ne change **pas** la timeline).
@immutable
final class SurfaceAnimationTimeline {
  SurfaceAnimationTimeline({
    required List<SurfaceAnimationFrame> frames,
  }) {
    if (frames.isEmpty) {
      throw const ValidationException(
        'SurfaceAnimationTimeline.frames must be non-empty',
      );
    }
    _frames = List<SurfaceAnimationFrame>.unmodifiable(
      List<SurfaceAnimationFrame>.from(frames),
    );
  }

  late final List<SurfaceAnimationFrame> _frames;

  /// Frames dans l’**ordre** d’enchaînement (liste **non modifiable**).
  List<SurfaceAnimationFrame> get frames => _frames;

  /// Nombre de frames.
  int get frameCount => _frames.length;

  /// Somme des [SurfaceAnimationFrame.durationMs] (millisecondes déclarées).
  int get totalDurationMs {
    var sum = 0;
    for (final frame in _frames) {
      sum += frame.durationMs;
    }
    return sum;
  }

  /// Vrai si **chaque** frame tient dans [geometry] (même règles qu’en Lot 25).
  bool isInside(SurfaceAtlasGeometry geometry) =>
      _frames.every((frame) => frame.isInside(geometry));

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SurfaceAnimationTimeline &&
          _surfaceAnimationFramesEqualInOrder(frames, other.frames);

  @override
  int get hashCode => Object.hashAll(_frames);
}

/// **Animation Surface** côté domaine : identifiant, libellé, et
/// [SurfaceAnimationTimeline] (source de vérité pour **frames** et **durées**).
///
/// * Modèle pur : **aucun** [toJson] / [fromJson] ; **n’est pas** rattaché à un
///   [ProjectManifest] (aucun champ `surfaceAnimations` à ce stade) — miroir
///   d’intention de [ProjectSurfaceAtlas] (Lot 23) pour l’**animation** nommée.
/// * Aucun **horloge** ni **frame courante** : ne lit **pas** le temps ; ne
///   implémente **pas** de moteur, playback ou horloge Surface.
/// * [isInside] se délègue à [timeline] seule (pas de résolution d’[atlasId],
///   pas de vérification de tileset, pas de texture, pas de runtime).
/// * [syncGroupId] prépare une **synchronisation future** entre instances (eau,
///   lave, etc.) côté runtime : **inerte** dans ce lot (aucun effet, aucune
///   clé lue ici ailleurs).
/// * [categoryId] suit la même marge de manœuvre qu’[ProjectSurfaceAtlas] :
///   chaînes vides / espaces autorisées si l’appelant les transmet, pour ne pas
///   sur-valider l’**optionnel** en l’absence d’unicité de convention dans le
///   monorepo.
@immutable
final class ProjectSurfaceAnimation {
  ProjectSurfaceAnimation({
    required this.id,
    required this.name,
    required this.timeline,
    this.syncGroupId,
    this.categoryId,
    this.sortOrder = 0,
  }) {
    if (id.trim().isEmpty) {
      throw const ValidationException('ProjectSurfaceAnimation.id must be non-empty');
    }
    if (name.trim().isEmpty) {
      throw const ValidationException('ProjectSurfaceAnimation.name must be non-empty');
    }
    // Promotion sur champ public : copie locale (cf. règles d’analyse Dart).
    final sync = syncGroupId;
    if (sync != null && sync.trim().isEmpty) {
      throw const ValidationException(
        'ProjectSurfaceAnimation.syncGroupId must be null or have non-empty content',
      );
    }
  }

  /// Identifiant auteur, stocké **tel quel** (invalidité seulement si, après
  /// [trim], il ne reste rien). Pas de raccrochage manifest dans ce lot.
  final String id;

  /// Nom d’affichage ; mêmes règles de stockage / garde qu’[id].
  final String name;

  /// La timeline est conservée **identique** (référence d’objet) ; on ne
  /// re-valide ni les frames, ni les durées, ni la copie (déjà
  /// [SurfaceAnimationTimeline]).
  final SurfaceAnimationTimeline timeline;

  /// Synchronisation future (ex. eau / lave partagés) : **préparé ici, inerte**
  /// tant qu’il n’y a pas de moteur.
  final String? syncGroupId;

  /// Dossier / catégorie optionnelle (comme [ProjectSurfaceAtlas.categoryId]) :
  /// pas de forme imposée sur les chaînes vides ici.
  final String? categoryId;

  /// Classement (affichage), comme [ProjectSurfaceAtlas.sortOrder] ; toute
  /// valeur entière est acceptée, y compris négative.
  final int sortOrder;

  /// Délègue à [SurfaceAnimationTimeline.frameCount].
  int get frameCount => timeline.frameCount;

  /// Délègue à [SurfaceAnimationTimeline.totalDurationMs].
  int get totalDurationMs => timeline.totalDurationMs;

  /// Délègue à [SurfaceAnimationTimeline.isInside].
  bool isInside(SurfaceAtlasGeometry geometry) => timeline.isInside(geometry);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProjectSurfaceAnimation &&
          other.id == id &&
          other.name == name &&
          other.timeline == timeline &&
          other.syncGroupId == syncGroupId &&
          other.categoryId == categoryId &&
          other.sortOrder == sortOrder;

  @override
  int get hashCode => Object.hash(
        id,
        name,
        timeline,
        syncGroupId,
        categoryId,
        sortOrder,
      );
}

/// Lien logique `SurfaceVariantRole` → identifiant d’**animation** (`animationId`)
/// pour le futur branchement preset — **ne** constitue **pas** un
/// [ProjectSurfaceAnimation] résolu, **ni** [ProjectSurfacePreset], **ni** une
/// table de mapping complète d’autotile.
///
/// * Modèle de domaine pur, **aucun** [toJson] / persistance ici.
/// * [role] appartient au **vocabulaire Surface** ([SurfaceVariantRole]) et n’est
///   **pas** un [TerrainPathVariant] (legacy path).
/// * [animationId] est une clé auteur telle quelle (invalidité seulement si, après
///   [trim], il ne reste rien) ; on ne cherche **pas** un
///   [ProjectSurfaceAnimation] de ce nom dans le manifest, ni compatibilité
///   atlas, ni frames / durées / temps courant.
@immutable
final class SurfaceVariantAnimationRef {
  SurfaceVariantAnimationRef({
    required this.role,
    required this.animationId,
  }) {
    if (animationId.trim().isEmpty) {
      throw const ValidationException(
        'SurfaceVariantAnimationRef.animationId must be non-empty',
      );
    }
  }

  /// Rôle de variante autotile (vocabulaire Surface, Lot 28).
  final SurfaceVariantRole role;

  /// Cible le futur [ProjectSurfaceAnimation.id] côté auteur, **sans résolution**
  /// ni vérification d’existence dans ce lot.
  final String animationId;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SurfaceVariantAnimationRef &&
          other.role == role &&
          other.animationId == animationId;

  @override
  int get hashCode => Object.hash(role, animationId);
}

/// Comparaison **ordonnée** de deux listes de [SurfaceVariantAnimationRef] pour
/// [SurfaceVariantAnimationRefSet] (même principe que
/// [_surfaceAnimationFramesEqualInOrder] côté timeline).
bool _surfaceVariantAnimationRefListsEqualInOrder(
  List<SurfaceVariantAnimationRef> a,
  List<SurfaceVariantAnimationRef> b,
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

/// Ensemble **ordonné** et **immuable** de [SurfaceVariantAnimationRef] (au plus
/// une ref par [SurfaceVariantRole]).
///
/// * Modèle de domaine pur : **aucun** [toJson], **ni** [ProjectSurfacePreset] ni
///   enregistrement manifest ; n’**en résout** pas les [animationId] vers
///   [ProjectSurfaceAnimation].
/// * L’**unicité** porte sur le **rôle** : le même `animationId` sur plusieurs
///   rôles est autorisé (ex. un clip partagé) ; deux entrées **même rôle** sont
///   rejetées.
/// * L’**ordre d’entrée** est conservé (pas de tri sur
///   [standardSurfaceVariantRoleOrder]).
/// * [coversAllRoles] vérifie seulement que les rôles **demandés** sont présents
///   (n’impose **pas** la liste complète des 20 rôles).
@immutable
final class SurfaceVariantAnimationRefSet {
  SurfaceVariantAnimationRefSet({
    required List<SurfaceVariantAnimationRef> refs,
  }) {
    if (refs.isEmpty) {
      throw const ValidationException(
        'SurfaceVariantAnimationRefSet.refs must be non-empty',
      );
    }
    final seen = <SurfaceVariantRole>{};
    for (final r in refs) {
      if (!seen.add(r.role)) {
        throw const ValidationException(
          'SurfaceVariantAnimationRefSet.refs must not contain duplicate SurfaceVariantRole',
        );
      }
    }
    _refs = List<SurfaceVariantAnimationRef>.unmodifiable(
      List<SurfaceVariantAnimationRef>.from(refs),
    );
  }

  late final List<SurfaceVariantAnimationRef> _refs;

  /// Refs dans l’**ordre** fourni (liste **non modifiable**).
  List<SurfaceVariantAnimationRef> get refs => _refs;

  int get length => _refs.length;

  /// Après construction valide, toujours `false` (le set n’est jamais vide).
  bool get isEmpty => _refs.isEmpty;

  /// Après construction valide, toujours `true`.
  bool get isNotEmpty => _refs.isNotEmpty;

  /// Vrai s’il existe une ref de ce [role].
  bool containsRole(SurfaceVariantRole role) {
    for (final r in _refs) {
      if (r.role == role) {
        return true;
      }
    }
    return false;
  }

  /// La ref pour [role] si présente, sinon `null`.
  SurfaceVariantAnimationRef? refForRole(SurfaceVariantRole role) {
    for (final r in _refs) {
      if (r.role == role) {
        return r;
      }
    }
    return null;
  }

  /// L’[SurfaceVariantAnimationRef.animationId] pour [role] si présent.
  String? animationIdForRole(SurfaceVariantRole role) =>
      refForRole(role)?.animationId;

  /// Vrai si **chaque** rôle de [roles] est couvert (pour un [Iterable] vide :
  /// vrai, comme `every` sur collection vide en Dart).
  bool coversAllRoles(Iterable<SurfaceVariantRole> roles) =>
      roles.every(containsRole);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SurfaceVariantAnimationRefSet &&
          _surfaceVariantAnimationRefListsEqualInOrder(refs, other.refs);

  @override
  int get hashCode => Object.hashAll(_refs);
}
