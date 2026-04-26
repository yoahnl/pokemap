# Lot 28 — Surface Variant Role Enum V0

## 1. Résumé exécutif

Ajout de l’enum **`SurfaceVariantRole`** (rôles blob / autotile surface) et de la constante **`standardSurfaceVariantRoleOrder`** (liste explicite de 21 cas, **pas** `SurfaceVariantRole.values`). Aucun mapping vers `TerrainPathVariant`, pas de modification de `TerrainPathVariant` ni du manifest. Tests : **7** ; suite `map_core` : **647** ; analyse : **Aucun problème**.

## 2. Pourquoi ce lot vient après le Lot 27

Après les modèles nommés (`ProjectSurfaceAnimation`, etc.), le **vocabulaire** de rôle de variante autotile Surface est posé **nativement**, pour ne pas lier le futur Surface Engine au seul `TerrainPathVariant` legacy.

## 3. Fichiers consultés (audit)

- `surface.dart`, tests surface 21–27, `enums.dart` (`TerrainPathVariant` — ordre et noms alignés de fait), `map_core.dart` (export)

## 4. Fichiers créés

- `packages/map_core/test/surface_variant_role_test.dart`
- `reports/surface/surface_engine_lot_28_surface_variant_role.md`

## 5. Fichiers modifiés

- `packages/map_core/lib/src/models/surface.dart` uniquement

## 6. API ajoutée

- `enum SurfaceVariantRole { … }` (21 variantes, ordre d’intention v0 water/lava/ice / bridge vertical-atlas)
- `const List<SurfaceVariantRole> standardSurfaceVariantRoleOrder` (même sémantique, énumération manuelle)

## 7. Sémantique de `SurfaceVariantRole`

Rôle **visuel logique** d’une cellule autotilée, pas d’id de tuile, pas d’animation, pas de collision, pas de preset.

## 8. Sémantique de `standardSurfaceVariantRoleOrder`

**Ordre contractuel** d’atlas (évite de dériver silencieusement d’un réordonnancement d’`enum`).

## 9. Relation avec `TerrainPathVariant`

- **`TerrainPathVariant** : vocabulaire **legacy** path (inchangé, toujours dans `enums.dart`).  
- **`SurfaceVariantRole` : vocabulaire **Surface** (ce lot).  
- **Aucune** conversion ici. Les noms de cas **`.name`** coïncident aujourd’hui pour `cross` (test de cohabitation) — c’est accidentel de synchronisation, pas un contrat de mapping.

## 10. Ce qui a été testé

Ordre de `values`, identité de `standardSurfaceVariantRoleOrder` avec la liste attendue, couverture 1:1, `add` interdit, export, manifest, coexistence `TerrainPathVariant` + égalité de nom `cross`.

## 11. Ce que les tests prouvent

Stabilité d’intention, pas de fuite manifest, indépendance des deux enums au niveau **API** (pas de pont).

## 12. Volontairement non fait

Mapping `TerrainPathVariant` → `SurfaceVariantRole`, `ProjectSurfacePreset`, JSON, moteur.

## 13. `ProjectManifest` non modifié

Même logique que lots 21–27.

## 14. Pas de code généré

Enum manuel, pas de `build_runner`.

## 15. Prochains lots

Mappers, presets, intégration autotile pourront s’appuyer sur `SurfaceVariantRole` + `standardSurfaceVariantRoleOrder`.

## 16. Commandes lancées

`packages/map_core`, `/opt/homebrew/bin/dart` :

- `dart test test/surface_variant_role_test.dart` → `+7: All tests passed!`
- Groupe 8 fichiers surface → `+123: All tests passed!`
- `dart analyze` (10 chemins) → `No issues found!`
- `dart test` (tout) → `+647: All tests passed!`

## 17–18. Résultats & total

- Total **`dart test` map_core** : **647** tests, tous passés.

## 19. Points de vigilance

- Coïncidence des noms `TerrainPathVariant` / `SurfaceVariantRole` : **ne pas** lire un contrat de mapping permanent sans lot dédié.

## 20. Autocritique

- Aucun helper de validation en plus des tests (non jugé nécessaire pour v0).

## 21. Prompt discutable

- Aucun point bloquant. « blob 47+ » dans le doc = intention RM/classique, non normatif moteur.

## 22. Auto-review (Oui/Non)

| Item |  |
|------|--|
| Périmètre enum + ordre + tests + rapport | Oui |
| `ProjectManifest` / champs persistant| Inchangé |
| Pas Freezed/JSON/`.g`/`.freezed` | Oui |
| `TerrainPathVariant` non modifié, pas de conversion | Oui |
| Ordre explicite + couverture testée | Oui |
| Export `map_core` | Oui |
| 647/647 | Oui |
| Git écriture | **Non** |
| Diffs/sources sections 23–24 | Oui (injection) |

## 23. Contenu complet des fichiers

### 23.A `surface.dart` (fichier complet)

```dart
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
```
### 23.B `surface_variant_role_test.dart` (fichier complet)

```dart
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

/// Même ordre explicite que le Lot 28 / `surface.dart` (ne pas utiliser
/// `values` pour construire l’attendu — teste vraiment l’intention).
const List<SurfaceVariantRole> kExpectedSurfaceVariantRoleOrder = [
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

void main() {
  group('SurfaceVariantRole', () {
    test('SurfaceVariantRole.values is exactly the expected order', () {
      expect(
        List<SurfaceVariantRole>.from(SurfaceVariantRole.values),
        kExpectedSurfaceVariantRoleOrder,
      );
    });

    test('standardSurfaceVariantRoleOrder matches expected explicit list', () {
      expect(standardSurfaceVariantRoleOrder, kExpectedSurfaceVariantRoleOrder);
    });

    test('standard list covers all enum values once (set + length)', () {
      final fromEnum = SurfaceVariantRole.values.toSet();
      final fromStandard = standardSurfaceVariantRoleOrder.toSet();
      expect(standardSurfaceVariantRoleOrder.length, SurfaceVariantRole.values.length);
      expect(standardSurfaceVariantRoleOrder.length, fromStandard.length);
      expect(fromEnum, fromStandard);
      for (final v in SurfaceVariantRole.values) {
        expect(standardSurfaceVariantRoleOrder.where((e) => e == v).length, 1);
      }
    });

    test('standardSurfaceVariantRoleOrder is not growable (const list)', () {
      // Liste `const` : tentative de mutation → UnsupportedError (runtime).
      expect(
        () => standardSurfaceVariantRoleOrder.add(SurfaceVariantRole.cross),
        throwsA(isA<UnsupportedError>()),
      );
    });

    test('export: types from map_core only', () {
      expect(SurfaceVariantRole.cross, isA<SurfaceVariantRole>());
      expect(standardSurfaceVariantRoleOrder, isA<List<SurfaceVariantRole>>());
    });

    test('ProjectManifest toJson: no surface* top-level keys', () {
      const manifest = ProjectManifest(
        name: 'L28',
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

    test('TerrainPathVariant still available; cross names align (no conversion)', () {
      expect(TerrainPathVariant.cross, isA<TerrainPathVariant>());
      expect(SurfaceVariantRole.cross, isA<SurfaceVariantRole>());
      expect(SurfaceVariantRole.cross.name, TerrainPathVariant.cross.name);
    });
  });
}
```


## 24. Diffs complets

### 24.A `git diff` — surface.dart

```diff
diff --git a/packages/map_core/lib/src/models/surface.dart b/packages/map_core/lib/src/models/surface.dart
index 0fa8cc16..eb4c141f 100644
--- a/packages/map_core/lib/src/models/surface.dart
+++ b/packages/map_core/lib/src/models/surface.dart
@@ -1,7 +1,7 @@
 // Fichier d’entrée Surface (map_core) : pas de persistance JSON, pas de `toJson` ici.
-// Contient l’[enum] de layout, les value objects de géométrie d’atlas, et
-// [ProjectSurfaceAtlas] (métadonnées d’atlas) — raccrochage manifest dans des lots
-// ultérieurs.
+// Contient les enums (layout, rôles de variante d’autotile), les value objects
+// de géométrie d’atlas, [ProjectSurfaceAtlas] / [ProjectSurfaceAnimation] —
+// raccrochage manifest dans des lots ultérieurs.
 
 import 'package:meta/meta.dart' show immutable;
 
@@ -36,6 +36,62 @@ enum SurfaceAtlasLayout {
   rowsAreVariantsColumnsAreFrames,
 }
 
+/// Rôle visuel logique d’une cellule dans une surface autotilée (blob 47+).
+///
+/// C’est le **vocabulaire Surface natif** — indépendant de [TerrainPathVariant]
+/// (monde legacy path) : aucun mapping n’est imposé ici, conversion éventuelle
+/// dans un lot dédié. Ne désigne **pas** un identifiant de tuile, une animation
+/// ni le gameplay.
+enum SurfaceVariantRole {
+  isolated,
+  endNorth,
+  endEast,
+  endSouth,
+  endWest,
+  horizontal,
+  vertical,
+  cornerNE,
+  cornerSE,
+  cornerSW,
+  cornerNW,
+  innerCornerNE,
+  innerCornerSE,
+  innerCornerSW,
+  innerCornerNW,
+  teeNorth,
+  teeEast,
+  teeSouth,
+  teeWest,
+  cross,
+}
+
+/// Ordre d’indexation **stable** des variantes d’atlas (vertical-atlas, lots
+/// 11–19) : **n’est pas** `SurfaceVariantRole.values` — chaque cas est listé
+/// explicitement pour qu’un réordonnancement accidentel d’enum n’invalide pas
+/// silencieusement le mapping atlas.
+const List<SurfaceVariantRole> standardSurfaceVariantRoleOrder = [
+  SurfaceVariantRole.isolated,
+  SurfaceVariantRole.endNorth,
+  SurfaceVariantRole.endEast,
+  SurfaceVariantRole.endSouth,
+  SurfaceVariantRole.endWest,
+  SurfaceVariantRole.horizontal,
+  SurfaceVariantRole.vertical,
+  SurfaceVariantRole.cornerNE,
+  SurfaceVariantRole.cornerSE,
+  SurfaceVariantRole.cornerSW,
+  SurfaceVariantRole.cornerNW,
+  SurfaceVariantRole.innerCornerNE,
+  SurfaceVariantRole.innerCornerSE,
+  SurfaceVariantRole.innerCornerSW,
+  SurfaceVariantRole.innerCornerNW,
+  SurfaceVariantRole.teeNorth,
+  SurfaceVariantRole.teeEast,
+  SurfaceVariantRole.teeSouth,
+  SurfaceVariantRole.teeWest,
+  SurfaceVariantRole.cross,
+];
+
 /// Taille d’une **tuile** d’atlas, en **pixels** (largeur / hauteur d’un slot
 /// de découpe dans l’image source).
 ///
```
### 24.B `diff -u /dev/null` — test

```diff
--- /dev/null	2026-04-26 23:43:56
+++ /Users/karim/Project/pokemonProject/packages/map_core/test/surface_variant_role_test.dart	2026-04-26 23:43:30
@@ -0,0 +1,96 @@
+import 'package:map_core/map_core.dart';
+import 'package:test/test.dart';
+
+/// Même ordre explicite que le Lot 28 / `surface.dart` (ne pas utiliser
+/// `values` pour construire l’attendu — teste vraiment l’intention).
+const List<SurfaceVariantRole> kExpectedSurfaceVariantRoleOrder = [
+  SurfaceVariantRole.isolated,
+  SurfaceVariantRole.endNorth,
+  SurfaceVariantRole.endEast,
+  SurfaceVariantRole.endSouth,
+  SurfaceVariantRole.endWest,
+  SurfaceVariantRole.horizontal,
+  SurfaceVariantRole.vertical,
+  SurfaceVariantRole.cornerNE,
+  SurfaceVariantRole.cornerSE,
+  SurfaceVariantRole.cornerSW,
+  SurfaceVariantRole.cornerNW,
+  SurfaceVariantRole.innerCornerNE,
+  SurfaceVariantRole.innerCornerSE,
+  SurfaceVariantRole.innerCornerSW,
+  SurfaceVariantRole.innerCornerNW,
+  SurfaceVariantRole.teeNorth,
+  SurfaceVariantRole.teeEast,
+  SurfaceVariantRole.teeSouth,
+  SurfaceVariantRole.teeWest,
+  SurfaceVariantRole.cross,
+];
+
+void main() {
+  group('SurfaceVariantRole', () {
+    test('SurfaceVariantRole.values is exactly the expected order', () {
+      expect(
+        List<SurfaceVariantRole>.from(SurfaceVariantRole.values),
+        kExpectedSurfaceVariantRoleOrder,
+      );
+    });
+
+    test('standardSurfaceVariantRoleOrder matches expected explicit list', () {
+      expect(standardSurfaceVariantRoleOrder, kExpectedSurfaceVariantRoleOrder);
+    });
+
+    test('standard list covers all enum values once (set + length)', () {
+      final fromEnum = SurfaceVariantRole.values.toSet();
+      final fromStandard = standardSurfaceVariantRoleOrder.toSet();
+      expect(standardSurfaceVariantRoleOrder.length, SurfaceVariantRole.values.length);
+      expect(standardSurfaceVariantRoleOrder.length, fromStandard.length);
+      expect(fromEnum, fromStandard);
+      for (final v in SurfaceVariantRole.values) {
+        expect(standardSurfaceVariantRoleOrder.where((e) => e == v).length, 1);
+      }
+    });
+
+    test('standardSurfaceVariantRoleOrder is not growable (const list)', () {
+      // Liste `const` : tentative de mutation → UnsupportedError (runtime).
+      expect(
+        () => standardSurfaceVariantRoleOrder.add(SurfaceVariantRole.cross),
+        throwsA(isA<UnsupportedError>()),
+      );
+    });
+
+    test('export: types from map_core only', () {
+      expect(SurfaceVariantRole.cross, isA<SurfaceVariantRole>());
+      expect(standardSurfaceVariantRoleOrder, isA<List<SurfaceVariantRole>>());
+    });
+
+    test('ProjectManifest toJson: no surface* top-level keys', () {
+      const manifest = ProjectManifest(
+        name: 'L28',
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
+
+    test('TerrainPathVariant still available; cross names align (no conversion)', () {
+      expect(TerrainPathVariant.cross, isA<TerrainPathVariant>());
+      expect(SurfaceVariantRole.cross, isA<SurfaceVariantRole>());
+      expect(SurfaceVariantRole.cross.name, TerrainPathVariant.cross.name);
+    });
+  });
+}
```


---

*Fin — Lot 28 — SurfaceVariantRole (map_core).*
