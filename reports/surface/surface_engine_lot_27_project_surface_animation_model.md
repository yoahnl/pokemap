# Lot 27 — ProjectSurfaceAnimation Model V0

## 1. Résumé exécutif

Ajout de **`ProjectSurfaceAnimation`** dans `packages/map_core/lib/src/models/surface.dart` : `id` / `name` validés (non vides après trim, stockage brut), `timeline` (instance conservée, délégation `frameCount` / `totalDurationMs` / `isInside`), `syncGroupId` optionnel (si non `null`, rejet des chaînes vides / whitespace seuls — copie locale pour la promotion nulle), `categoryId` souple (aligné **ProjectSurfaceAtlas** : `''` et espaces autorisés), `sortOrder` sans borne (négatifs autorisés). Aucun JSON, pas de `ProjectManifest` modifié. Tests : **28** ; suite `map_core` : **640** ; analyse : **Aucun problème**.

## 2. Pourquoi ce lot vient après le Lot 26

Le **Lot 26** a fourni `SurfaceAnimationTimeline` (séquence de frames). Le **Lot 27** attache un **identifiant et des métadonnées** d’**animation** réutilisables, sans persistance.

## 3. Fichiers consultés (audit)

- `surface.dart` (types 21–26), `ProjectSurfaceAtlas` (conventions `id`/`name`/`categoryId`/`sortOrder`)
- Tests surface existants, `map_exceptions`, `map_core.dart` (export)

## 4. Fichiers créés

- `packages/map_core/test/project_surface_animation_test.dart`
- `reports/surface/surface_engine_lot_27_project_surface_animation_model.md`

## 5. Fichiers modifiés

- `packages/map_core/lib/src/models/surface.dart` uniquement

## 6. API ajoutée

`ProjectSurfaceAnimation` avec champs, getters délégués, `==` / `hashCode` sur l’ensemble des champs (incl. `timeline`).

## 7. Sémantique

Modèle de domaine pur, pas de manifest, pas d’horloge ni moteur ; `syncGroupId` **prépare** seulement une synchro future.

## 8. Validation de `id`

`id.trim().isEmpty` → `ValidationException`. Valeur **stockée** inchangée.

## 9. Validation de `name`

Comme `id`.

## 10. Décision `syncGroupId`

- `null` : OK.  
- Non `null` : si `trim` vide → `ValidationException`.  
- Sinon : stockage **brut** (comme le prompt : pas de trim en mémoire).  
- **Impl. :** variable locale `sync` pour `trim` (promotion, analyse Dart sur champ public).

## 11. Décision `categoryId`

Comme **Lot 23 `ProjectSurfaceAtlas.categoryId`** : `''` et `'   '` **acceptés** (tests 9 du prompt / fichier).

## 12. Décision `sortOrder`

Aucune validation de signe (convention alignée `ProjectSurfaceAtlas`).

## 13–15. `frameCount` / `totalDurationMs` / `isInside`

Délégation stricte à `timeline` (même sémantique que Lot 26).

## 16. Ce qui a été testé

28 cas (minimal, identité `timeline`, champs optionnels, chaînes exactes, rejets `id`/`name`/`syncGroupId`, `categoryId` vides, `sortOrder` négatif, délégations, `isInside` + layout, égalité multi-axes, ordre de timeline, export, `toJson` manifest).

## 17. Ce que les tests prouvent

Validations, délégation, cohérence avec atlas, **pas** de clés `surface*` au manifest.

## 18. Ce qui n’a pas été fait

JSON, `ProjectSurfacePreset`, runtime, moteur, playback.

## 19. Pourquoi `ProjectManifest` non modifié

Les listes `surfaceAnimations` / etc. arrivent dans des lots dédiés au schéma persistant.

## 20. Pas de génération

Cohérence des lots 21–27 (VO manuel dans `surface.dart`).

## 21. Prochains lots

`ProjectSurfaceAnimation` pourra être listé côté manifest quand le contrat l’acceptera.

## 22. Commandes lancées

`packages/map_core`, `/opt/homebrew/bin/dart` :

- `dart test test/project_surface_animation_test.dart` → `+28: All tests passed!`
- Groupe 7 tests surface (fichiers du prompt) → `+116: All tests passed!`
- `dart analyze` (9 chemins) → `No issues found!`
- `dart test` (tout) → `+640: All tests passed!`

## 23–24. Résultats & total

| Jeu de tests | Dernière ligne |
|----------------|-----------------|
| `project_surface_animation_test.dart` | `+28: All tests passed!` |
| 7 fichiers surface | `+116: All tests passed!` |
| Tout `map_core` | `+640: All tests passed!` |

## 25. Points de vigilance

- Même clé sémantique `syncGroupId` côté futur moteur : hors scope ici.
- L’**égalité** inclut toute la `timeline` (deux instances distinctes et égales en valeur = animations égales).

## 26. Autocritique

- Exception `syncGroupId` : texte légèrement différent de la spec du prompt, sens identique (null ou contenu non vide visuellement).

## 27. Prompt discutable

- Aucun blocage. Alignement explicite `ProjectSurfaceAtlas` sur `categoryId` demandé.

## 28. Auto-review (Oui/Non)

| Item |  |
|------|--|
| Périmètre respecté (modèle + test + rapport) | Oui |
| `ProjectManifest` source non modifié | Oui |
| Pas de Freezed/JSON/`.g`/`.freezed` | Oui |
| Autres packages non touchés | Oui |
| `id`/`name`/`syncGroupId` (si présent) validés | Oui |
| Pas de résolution `atlasId` / pas de temps courant | Oui |
| Délégation timeline | Oui |
| `map_core` 640/640 | Oui |
| Fichiers complets + diffs (sections 29–30) | Oui (injection) |
| Git écriture | **Non** (conforme) |

## 29. Contenu complet des fichiers

### 29.A `surface.dart` (fichier complet)

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
### 29.B `project_surface_animation_test.dart` (fichier complet)

```dart
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

SurfaceAtlasTileRef _ref(int column, int row, {String atlasId = 'water-atlas'}) {
  return SurfaceAtlasTileRef(
    atlasId: atlasId,
    column: column,
    row: row,
  );
}

SurfaceAnimationFrame _frame(
  int column,
  int row,
  int durationMs, {
  String atlasId = 'water-atlas',
}) {
  return SurfaceAnimationFrame(
    tileRef: _ref(column, row, atlasId: atlasId),
    durationMs: durationMs,
  );
}

SurfaceAnimationTimeline _singleFrameTimeline({int durationMs = 120}) {
  return SurfaceAnimationTimeline(
    frames: [
      _frame(0, 0, durationMs),
    ],
  );
}

SurfaceAtlasGeometry _geometry([SurfaceAtlasLayout? layout]) {
  return SurfaceAtlasGeometry(
    tileSize: SurfaceAtlasTileSize(width: 32, height: 32),
    gridSize: SurfaceAtlasGridSize(columns: 4, rows: 3),
    layout: layout ?? SurfaceAtlasLayout.grid,
  );
}

void main() {
  group('ProjectSurfaceAnimation', () {
    test('minimal animation: fields and delegation', () {
      final timeline = SurfaceAnimationTimeline(
        frames: [
          SurfaceAnimationFrame(
            tileRef: SurfaceAtlasTileRef(
              atlasId: 'water-atlas',
              column: 0,
              row: 0,
            ),
            durationMs: 120,
          ),
        ],
      );

      final animation = ProjectSurfaceAnimation(
        id: 'water-loop',
        name: 'Water Loop',
        timeline: timeline,
      );

      expect(animation.id, 'water-loop');
      expect(animation.name, 'Water Loop');
      expect(animation.timeline, timeline);
      expect(animation.syncGroupId, isNull);
      expect(animation.categoryId, isNull);
      expect(animation.sortOrder, 0);
      expect(animation.frameCount, 1);
      expect(animation.totalDurationMs, 120);
    });

    test('preserves the exact same timeline instance', () {
      final timeline = _singleFrameTimeline();
      final animation = ProjectSurfaceAnimation(
        id: 'a',
        name: 'A',
        timeline: timeline,
      );
      expect(identical(animation.timeline, timeline), isTrue);
    });

    test('preserves syncGroupId, categoryId, sortOrder', () {
      final timeline = _singleFrameTimeline();
      final animation = ProjectSurfaceAnimation(
        id: 'a',
        name: 'A',
        timeline: timeline,
        syncGroupId: 'water-global',
        categoryId: 'animated-surfaces',
        sortOrder: 42,
      );
      expect(animation.syncGroupId, 'water-global');
      expect(animation.categoryId, 'animated-surfaces');
      expect(animation.sortOrder, 42);
    });

    test('stores id, name, syncGroupId strings exactly without auto-trim', () {
      const id = '  water-loop  ';
      const name = '  Water Loop  ';
      const sync = '  water-sync  ';
      final animation = ProjectSurfaceAnimation(
        id: id,
        name: name,
        timeline: _singleFrameTimeline(),
        syncGroupId: sync,
      );
      expect(animation.id, id);
      expect(animation.name, name);
      expect(animation.syncGroupId, sync);
    });

    test('rejects empty id: empty string', () {
      expect(
        () => ProjectSurfaceAnimation(
          id: '',
          name: 'N',
          timeline: _singleFrameTimeline(),
        ),
        throwsA(isA<ValidationException>()),
      );
    });

    test('rejects empty id: whitespace only', () {
      expect(
        () => ProjectSurfaceAnimation(
          id: '   ',
          name: 'N',
          timeline: _singleFrameTimeline(),
        ),
        throwsA(isA<ValidationException>()),
      );
    });

    test('rejects empty name: empty string', () {
      expect(
        () => ProjectSurfaceAnimation(
          id: 'a',
          name: '',
          timeline: _singleFrameTimeline(),
        ),
        throwsA(isA<ValidationException>()),
      );
    });

    test('rejects empty name: whitespace only', () {
      expect(
        () => ProjectSurfaceAnimation(
          id: 'a',
          name: '   ',
          timeline: _singleFrameTimeline(),
        ),
        throwsA(isA<ValidationException>()),
      );
    });

    test('rejects non-null syncGroupId that is only whitespace: empty', () {
      expect(
        () => ProjectSurfaceAnimation(
          id: 'a',
          name: 'A',
          timeline: _singleFrameTimeline(),
          syncGroupId: '',
        ),
        throwsA(isA<ValidationException>()),
      );
    });

    test('rejects non-null syncGroupId that is only whitespace: spaces', () {
      expect(
        () => ProjectSurfaceAnimation(
          id: 'a',
          name: 'A',
          timeline: _singleFrameTimeline(),
          syncGroupId: '   ',
        ),
        throwsA(isA<ValidationException>()),
      );
    });

    test('allows syncGroupId == null', () {
      final animation = ProjectSurfaceAnimation(
        id: 'a',
        name: 'A',
        timeline: _singleFrameTimeline(),
      );
      expect(animation.syncGroupId, isNull);
    });

    test('categoryId: accepts empty and whitespace (ProjectSurfaceAtlas policy)', () {
      final a1 = ProjectSurfaceAnimation(
        id: 'a',
        name: 'A',
        timeline: _singleFrameTimeline(),
        categoryId: '',
      );
      expect(a1.categoryId, '');

      const rawWhitespace = '   ';
      final a2 = ProjectSurfaceAnimation(
        id: 'b',
        name: 'B',
        timeline: _singleFrameTimeline(),
        categoryId: rawWhitespace,
      );
      expect(a2.categoryId, rawWhitespace);
    });

    test('sortOrder: preserves negative value', () {
      final animation = ProjectSurfaceAnimation(
        id: 'a',
        name: 'A',
        timeline: _singleFrameTimeline(),
        sortOrder: -10,
      );
      expect(animation.sortOrder, -10);
    });

    test('frameCount delegates to timeline (3 frames)', () {
      final timeline = SurfaceAnimationTimeline(
        frames: [
          _frame(0, 0, 1),
          _frame(0, 0, 1),
          _frame(0, 0, 1),
        ],
      );
      final animation = ProjectSurfaceAnimation(
        id: 'a',
        name: 'A',
        timeline: timeline,
      );
      expect(animation.frameCount, 3);
    });

    test('totalDurationMs delegates: 50 + 100 + 150 = 300', () {
      final timeline = SurfaceAnimationTimeline(
        frames: [
          _frame(0, 0, 50),
          _frame(1, 0, 100),
          _frame(2, 0, 150),
        ],
      );
      final animation = ProjectSurfaceAnimation(
        id: 'a',
        name: 'A',
        timeline: timeline,
      );
      expect(animation.totalDurationMs, 300);
    });

    test('isInside: true when all tiles inside grid', () {
      final g = _geometry();
      final timeline = SurfaceAnimationTimeline(
        frames: [
          _frame(0, 0, 10),
          _frame(3, 2, 10),
        ],
      );
      final animation = ProjectSurfaceAnimation(
        id: 'a',
        name: 'A',
        timeline: timeline,
      );
      expect(animation.isInside(g), isTrue);
    });

    test('isInside: false when one frame out of grid', () {
      final g = _geometry();
      final timeline = SurfaceAnimationTimeline(
        frames: [
          _frame(0, 0, 10),
          _frame(4, 0, 10),
        ],
      );
      final animation = ProjectSurfaceAnimation(
        id: 'a',
        name: 'A',
        timeline: timeline,
      );
      expect(animation.isInside(g), isFalse);
    });

    test('isInside: independent of SurfaceAtlasLayout', () {
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
      final timeline = SurfaceAnimationTimeline(
        frames: [
          _frame(1, 1, 5),
        ],
      );
      final animation = ProjectSurfaceAnimation(
        id: 'a',
        name: 'A',
        timeline: timeline,
      );
      expect(animation.isInside(gGrid), isTrue);
      expect(animation.isInside(gVertical), isTrue);
    });

    test('value equality: same values => equal and same hash', () {
      final t1 = _singleFrameTimeline();
      final a = ProjectSurfaceAnimation(
        id: 'a',
        name: 'A',
        timeline: t1,
        syncGroupId: 'g',
        categoryId: 'c',
        sortOrder: 1,
      );
      final t2 = SurfaceAnimationTimeline(
        frames: [
          SurfaceAnimationFrame(
            tileRef: SurfaceAtlasTileRef(
              atlasId: 'water-atlas',
              column: 0,
              row: 0,
            ),
            durationMs: 120,
          ),
        ],
      );
      final b = ProjectSurfaceAnimation(
        id: 'a',
        name: 'A',
        timeline: t2,
        syncGroupId: 'g',
        categoryId: 'c',
        sortOrder: 1,
      );
      expect(a, b);
      expect(a.hashCode, b.hashCode);
    });

    test('value equality: id differs', () {
      final t = _singleFrameTimeline();
      final a = ProjectSurfaceAnimation(id: 'a', name: 'N', timeline: t);
      final b = ProjectSurfaceAnimation(id: 'b', name: 'N', timeline: t);
      expect(a, isNot(b));
    });

    test('value equality: name differs', () {
      final t = _singleFrameTimeline();
      final a = ProjectSurfaceAnimation(id: 'a', name: 'A', timeline: t);
      final b = ProjectSurfaceAnimation(id: 'a', name: 'B', timeline: t);
      expect(a, isNot(b));
    });

    test('value equality: timeline differs (duration)', () {
      final t1 = _singleFrameTimeline(durationMs: 10);
      final t2 = _singleFrameTimeline(durationMs: 20);
      final a = ProjectSurfaceAnimation(id: 'a', name: 'A', timeline: t1);
      final b = ProjectSurfaceAnimation(id: 'a', name: 'A', timeline: t2);
      expect(a, isNot(b));
    });

    test('value equality: syncGroupId differs', () {
      final t = _singleFrameTimeline();
      final a = ProjectSurfaceAnimation(
        id: 'a',
        name: 'A',
        timeline: t,
        syncGroupId: 'g1',
      );
      final b = ProjectSurfaceAnimation(
        id: 'a',
        name: 'A',
        timeline: t,
        syncGroupId: 'g2',
      );
      expect(a, isNot(b));
    });

    test('value equality: categoryId differs', () {
      final t = _singleFrameTimeline();
      final a = ProjectSurfaceAnimation(
        id: 'a',
        name: 'A',
        timeline: t,
        categoryId: 'c1',
      );
      final b = ProjectSurfaceAnimation(
        id: 'a',
        name: 'A',
        timeline: t,
        categoryId: 'c2',
      );
      expect(a, isNot(b));
    });

    test('value equality: sortOrder differs', () {
      final t = _singleFrameTimeline();
      final a = ProjectSurfaceAnimation(
        id: 'a',
        name: 'A',
        timeline: t,
        sortOrder: 0,
      );
      final b = ProjectSurfaceAnimation(
        id: 'a',
        name: 'A',
        timeline: t,
        sortOrder: 1,
      );
      expect(a, isNot(b));
    });

    test('value equality: timeline order differs (same frames, different order)', () {
      final f1 = _frame(0, 0, 10);
      final f2 = _frame(1, 0, 10);
      final t1 = SurfaceAnimationTimeline(frames: [f1, f2]);
      final t2 = SurfaceAnimationTimeline(frames: [f2, f1]);
      final a = ProjectSurfaceAnimation(id: 'a', name: 'A', timeline: t1);
      final b = ProjectSurfaceAnimation(id: 'a', name: 'A', timeline: t2);
      expect(a, isNot(b));
    });

    test('export: type is visible through map_core', () {
      final animation = ProjectSurfaceAnimation(
        id: 'a',
        name: 'A',
        timeline: _singleFrameTimeline(),
      );
      expect(animation, isA<ProjectSurfaceAnimation>());
    });

    test('ProjectManifest toJson: no surface* top-level keys', () {
      const manifest = ProjectManifest(
        name: 'L27',
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


## 30. Diffs complets

### 30.A `git diff` — surface.dart

```diff
diff --git a/packages/map_core/lib/src/models/surface.dart b/packages/map_core/lib/src/models/surface.dart
index 5992bf97..0fa8cc16 100644
--- a/packages/map_core/lib/src/models/surface.dart
+++ b/packages/map_core/lib/src/models/surface.dart
@@ -410,3 +410,100 @@ final class SurfaceAnimationTimeline {
   @override
   int get hashCode => Object.hashAll(_frames);
 }
+
+/// **Animation Surface** côté domaine : identifiant, libellé, et
+/// [SurfaceAnimationTimeline] (source de vérité pour **frames** et **durées**).
+///
+/// * Modèle pur : **aucun** [toJson] / [fromJson] ; **n’est pas** rattaché à un
+///   [ProjectManifest] (aucun champ `surfaceAnimations` à ce stade) — miroir
+///   d’intention de [ProjectSurfaceAtlas] (Lot 23) pour l’**animation** nommée.
+/// * Aucun **horloge** ni **frame courante** : ne lit **pas** le temps ; ne
+///   implémente **pas** de moteur, playback ou horloge Surface.
+/// * [isInside] se délègue à [timeline] seule (pas de résolution d’[atlasId],
+///   pas de vérification de tileset, pas de texture, pas de runtime).
+/// * [syncGroupId] prépare une **synchronisation future** entre instances (eau,
+///   lave, etc.) côté runtime : **inerte** dans ce lot (aucun effet, aucune
+///   clé lue ici ailleurs).
+/// * [categoryId] suit la même marge de manœuvre qu’[ProjectSurfaceAtlas] :
+///   chaînes vides / espaces autorisées si l’appelant les transmet, pour ne pas
+///   sur-valider l’**optionnel** en l’absence d’unicité de convention dans le
+///   monorepo.
+@immutable
+final class ProjectSurfaceAnimation {
+  ProjectSurfaceAnimation({
+    required this.id,
+    required this.name,
+    required this.timeline,
+    this.syncGroupId,
+    this.categoryId,
+    this.sortOrder = 0,
+  }) {
+    if (id.trim().isEmpty) {
+      throw const ValidationException('ProjectSurfaceAnimation.id must be non-empty');
+    }
+    if (name.trim().isEmpty) {
+      throw const ValidationException('ProjectSurfaceAnimation.name must be non-empty');
+    }
+    // Promotion sur champ public : copie locale (cf. règles d’analyse Dart).
+    final sync = syncGroupId;
+    if (sync != null && sync.trim().isEmpty) {
+      throw const ValidationException(
+        'ProjectSurfaceAnimation.syncGroupId must be null or have non-empty content',
+      );
+    }
+  }
+
+  /// Identifiant auteur, stocké **tel quel** (invalidité seulement si, après
+  /// [trim], il ne reste rien). Pas de raccrochage manifest dans ce lot.
+  final String id;
+
+  /// Nom d’affichage ; mêmes règles de stockage / garde qu’[id].
+  final String name;
+
+  /// La timeline est conservée **identique** (référence d’objet) ; on ne
+  /// re-valide ni les frames, ni les durées, ni la copie (déjà
+  /// [SurfaceAnimationTimeline]).
+  final SurfaceAnimationTimeline timeline;
+
+  /// Synchronisation future (ex. eau / lave partagés) : **préparé ici, inerte**
+  /// tant qu’il n’y a pas de moteur.
+  final String? syncGroupId;
+
+  /// Dossier / catégorie optionnelle (comme [ProjectSurfaceAtlas.categoryId]) :
+  /// pas de forme imposée sur les chaînes vides ici.
+  final String? categoryId;
+
+  /// Classement (affichage), comme [ProjectSurfaceAtlas.sortOrder] ; toute
+  /// valeur entière est acceptée, y compris négative.
+  final int sortOrder;
+
+  /// Délègue à [SurfaceAnimationTimeline.frameCount].
+  int get frameCount => timeline.frameCount;
+
+  /// Délègue à [SurfaceAnimationTimeline.totalDurationMs].
+  int get totalDurationMs => timeline.totalDurationMs;
+
+  /// Délègue à [SurfaceAnimationTimeline.isInside].
+  bool isInside(SurfaceAtlasGeometry geometry) => timeline.isInside(geometry);
+
+  @override
+  bool operator ==(Object other) =>
+      identical(this, other) ||
+      other is ProjectSurfaceAnimation &&
+          other.id == id &&
+          other.name == name &&
+          other.timeline == timeline &&
+          other.syncGroupId == syncGroupId &&
+          other.categoryId == categoryId &&
+          other.sortOrder == sortOrder;
+
+  @override
+  int get hashCode => Object.hash(
+        id,
+        name,
+        timeline,
+        syncGroupId,
+        categoryId,
+        sortOrder,
+      );
+}
```
### 30.B `diff -u /dev/null` — test

```diff
--- /dev/null	2026-04-26 23:40:50
+++ /Users/karim/Project/pokemonProject/packages/map_core/test/project_surface_animation_test.dart	2026-04-26 23:40:13
@@ -0,0 +1,459 @@
+import 'package:map_core/map_core.dart';
+import 'package:test/test.dart';
+
+SurfaceAtlasTileRef _ref(int column, int row, {String atlasId = 'water-atlas'}) {
+  return SurfaceAtlasTileRef(
+    atlasId: atlasId,
+    column: column,
+    row: row,
+  );
+}
+
+SurfaceAnimationFrame _frame(
+  int column,
+  int row,
+  int durationMs, {
+  String atlasId = 'water-atlas',
+}) {
+  return SurfaceAnimationFrame(
+    tileRef: _ref(column, row, atlasId: atlasId),
+    durationMs: durationMs,
+  );
+}
+
+SurfaceAnimationTimeline _singleFrameTimeline({int durationMs = 120}) {
+  return SurfaceAnimationTimeline(
+    frames: [
+      _frame(0, 0, durationMs),
+    ],
+  );
+}
+
+SurfaceAtlasGeometry _geometry([SurfaceAtlasLayout? layout]) {
+  return SurfaceAtlasGeometry(
+    tileSize: SurfaceAtlasTileSize(width: 32, height: 32),
+    gridSize: SurfaceAtlasGridSize(columns: 4, rows: 3),
+    layout: layout ?? SurfaceAtlasLayout.grid,
+  );
+}
+
+void main() {
+  group('ProjectSurfaceAnimation', () {
+    test('minimal animation: fields and delegation', () {
+      final timeline = SurfaceAnimationTimeline(
+        frames: [
+          SurfaceAnimationFrame(
+            tileRef: SurfaceAtlasTileRef(
+              atlasId: 'water-atlas',
+              column: 0,
+              row: 0,
+            ),
+            durationMs: 120,
+          ),
+        ],
+      );
+
+      final animation = ProjectSurfaceAnimation(
+        id: 'water-loop',
+        name: 'Water Loop',
+        timeline: timeline,
+      );
+
+      expect(animation.id, 'water-loop');
+      expect(animation.name, 'Water Loop');
+      expect(animation.timeline, timeline);
+      expect(animation.syncGroupId, isNull);
+      expect(animation.categoryId, isNull);
+      expect(animation.sortOrder, 0);
+      expect(animation.frameCount, 1);
+      expect(animation.totalDurationMs, 120);
+    });
+
+    test('preserves the exact same timeline instance', () {
+      final timeline = _singleFrameTimeline();
+      final animation = ProjectSurfaceAnimation(
+        id: 'a',
+        name: 'A',
+        timeline: timeline,
+      );
+      expect(identical(animation.timeline, timeline), isTrue);
+    });
+
+    test('preserves syncGroupId, categoryId, sortOrder', () {
+      final timeline = _singleFrameTimeline();
+      final animation = ProjectSurfaceAnimation(
+        id: 'a',
+        name: 'A',
+        timeline: timeline,
+        syncGroupId: 'water-global',
+        categoryId: 'animated-surfaces',
+        sortOrder: 42,
+      );
+      expect(animation.syncGroupId, 'water-global');
+      expect(animation.categoryId, 'animated-surfaces');
+      expect(animation.sortOrder, 42);
+    });
+
+    test('stores id, name, syncGroupId strings exactly without auto-trim', () {
+      const id = '  water-loop  ';
+      const name = '  Water Loop  ';
+      const sync = '  water-sync  ';
+      final animation = ProjectSurfaceAnimation(
+        id: id,
+        name: name,
+        timeline: _singleFrameTimeline(),
+        syncGroupId: sync,
+      );
+      expect(animation.id, id);
+      expect(animation.name, name);
+      expect(animation.syncGroupId, sync);
+    });
+
+    test('rejects empty id: empty string', () {
+      expect(
+        () => ProjectSurfaceAnimation(
+          id: '',
+          name: 'N',
+          timeline: _singleFrameTimeline(),
+        ),
+        throwsA(isA<ValidationException>()),
+      );
+    });
+
+    test('rejects empty id: whitespace only', () {
+      expect(
+        () => ProjectSurfaceAnimation(
+          id: '   ',
+          name: 'N',
+          timeline: _singleFrameTimeline(),
+        ),
+        throwsA(isA<ValidationException>()),
+      );
+    });
+
+    test('rejects empty name: empty string', () {
+      expect(
+        () => ProjectSurfaceAnimation(
+          id: 'a',
+          name: '',
+          timeline: _singleFrameTimeline(),
+        ),
+        throwsA(isA<ValidationException>()),
+      );
+    });
+
+    test('rejects empty name: whitespace only', () {
+      expect(
+        () => ProjectSurfaceAnimation(
+          id: 'a',
+          name: '   ',
+          timeline: _singleFrameTimeline(),
+        ),
+        throwsA(isA<ValidationException>()),
+      );
+    });
+
+    test('rejects non-null syncGroupId that is only whitespace: empty', () {
+      expect(
+        () => ProjectSurfaceAnimation(
+          id: 'a',
+          name: 'A',
+          timeline: _singleFrameTimeline(),
+          syncGroupId: '',
+        ),
+        throwsA(isA<ValidationException>()),
+      );
+    });
+
+    test('rejects non-null syncGroupId that is only whitespace: spaces', () {
+      expect(
+        () => ProjectSurfaceAnimation(
+          id: 'a',
+          name: 'A',
+          timeline: _singleFrameTimeline(),
+          syncGroupId: '   ',
+        ),
+        throwsA(isA<ValidationException>()),
+      );
+    });
+
+    test('allows syncGroupId == null', () {
+      final animation = ProjectSurfaceAnimation(
+        id: 'a',
+        name: 'A',
+        timeline: _singleFrameTimeline(),
+      );
+      expect(animation.syncGroupId, isNull);
+    });
+
+    test('categoryId: accepts empty and whitespace (ProjectSurfaceAtlas policy)', () {
+      final a1 = ProjectSurfaceAnimation(
+        id: 'a',
+        name: 'A',
+        timeline: _singleFrameTimeline(),
+        categoryId: '',
+      );
+      expect(a1.categoryId, '');
+
+      const rawWhitespace = '   ';
+      final a2 = ProjectSurfaceAnimation(
+        id: 'b',
+        name: 'B',
+        timeline: _singleFrameTimeline(),
+        categoryId: rawWhitespace,
+      );
+      expect(a2.categoryId, rawWhitespace);
+    });
+
+    test('sortOrder: preserves negative value', () {
+      final animation = ProjectSurfaceAnimation(
+        id: 'a',
+        name: 'A',
+        timeline: _singleFrameTimeline(),
+        sortOrder: -10,
+      );
+      expect(animation.sortOrder, -10);
+    });
+
+    test('frameCount delegates to timeline (3 frames)', () {
+      final timeline = SurfaceAnimationTimeline(
+        frames: [
+          _frame(0, 0, 1),
+          _frame(0, 0, 1),
+          _frame(0, 0, 1),
+        ],
+      );
+      final animation = ProjectSurfaceAnimation(
+        id: 'a',
+        name: 'A',
+        timeline: timeline,
+      );
+      expect(animation.frameCount, 3);
+    });
+
+    test('totalDurationMs delegates: 50 + 100 + 150 = 300', () {
+      final timeline = SurfaceAnimationTimeline(
+        frames: [
+          _frame(0, 0, 50),
+          _frame(1, 0, 100),
+          _frame(2, 0, 150),
+        ],
+      );
+      final animation = ProjectSurfaceAnimation(
+        id: 'a',
+        name: 'A',
+        timeline: timeline,
+      );
+      expect(animation.totalDurationMs, 300);
+    });
+
+    test('isInside: true when all tiles inside grid', () {
+      final g = _geometry();
+      final timeline = SurfaceAnimationTimeline(
+        frames: [
+          _frame(0, 0, 10),
+          _frame(3, 2, 10),
+        ],
+      );
+      final animation = ProjectSurfaceAnimation(
+        id: 'a',
+        name: 'A',
+        timeline: timeline,
+      );
+      expect(animation.isInside(g), isTrue);
+    });
+
+    test('isInside: false when one frame out of grid', () {
+      final g = _geometry();
+      final timeline = SurfaceAnimationTimeline(
+        frames: [
+          _frame(0, 0, 10),
+          _frame(4, 0, 10),
+        ],
+      );
+      final animation = ProjectSurfaceAnimation(
+        id: 'a',
+        name: 'A',
+        timeline: timeline,
+      );
+      expect(animation.isInside(g), isFalse);
+    });
+
+    test('isInside: independent of SurfaceAtlasLayout', () {
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
+      final timeline = SurfaceAnimationTimeline(
+        frames: [
+          _frame(1, 1, 5),
+        ],
+      );
+      final animation = ProjectSurfaceAnimation(
+        id: 'a',
+        name: 'A',
+        timeline: timeline,
+      );
+      expect(animation.isInside(gGrid), isTrue);
+      expect(animation.isInside(gVertical), isTrue);
+    });
+
+    test('value equality: same values => equal and same hash', () {
+      final t1 = _singleFrameTimeline();
+      final a = ProjectSurfaceAnimation(
+        id: 'a',
+        name: 'A',
+        timeline: t1,
+        syncGroupId: 'g',
+        categoryId: 'c',
+        sortOrder: 1,
+      );
+      final t2 = SurfaceAnimationTimeline(
+        frames: [
+          SurfaceAnimationFrame(
+            tileRef: SurfaceAtlasTileRef(
+              atlasId: 'water-atlas',
+              column: 0,
+              row: 0,
+            ),
+            durationMs: 120,
+          ),
+        ],
+      );
+      final b = ProjectSurfaceAnimation(
+        id: 'a',
+        name: 'A',
+        timeline: t2,
+        syncGroupId: 'g',
+        categoryId: 'c',
+        sortOrder: 1,
+      );
+      expect(a, b);
+      expect(a.hashCode, b.hashCode);
+    });
+
+    test('value equality: id differs', () {
+      final t = _singleFrameTimeline();
+      final a = ProjectSurfaceAnimation(id: 'a', name: 'N', timeline: t);
+      final b = ProjectSurfaceAnimation(id: 'b', name: 'N', timeline: t);
+      expect(a, isNot(b));
+    });
+
+    test('value equality: name differs', () {
+      final t = _singleFrameTimeline();
+      final a = ProjectSurfaceAnimation(id: 'a', name: 'A', timeline: t);
+      final b = ProjectSurfaceAnimation(id: 'a', name: 'B', timeline: t);
+      expect(a, isNot(b));
+    });
+
+    test('value equality: timeline differs (duration)', () {
+      final t1 = _singleFrameTimeline(durationMs: 10);
+      final t2 = _singleFrameTimeline(durationMs: 20);
+      final a = ProjectSurfaceAnimation(id: 'a', name: 'A', timeline: t1);
+      final b = ProjectSurfaceAnimation(id: 'a', name: 'A', timeline: t2);
+      expect(a, isNot(b));
+    });
+
+    test('value equality: syncGroupId differs', () {
+      final t = _singleFrameTimeline();
+      final a = ProjectSurfaceAnimation(
+        id: 'a',
+        name: 'A',
+        timeline: t,
+        syncGroupId: 'g1',
+      );
+      final b = ProjectSurfaceAnimation(
+        id: 'a',
+        name: 'A',
+        timeline: t,
+        syncGroupId: 'g2',
+      );
+      expect(a, isNot(b));
+    });
+
+    test('value equality: categoryId differs', () {
+      final t = _singleFrameTimeline();
+      final a = ProjectSurfaceAnimation(
+        id: 'a',
+        name: 'A',
+        timeline: t,
+        categoryId: 'c1',
+      );
+      final b = ProjectSurfaceAnimation(
+        id: 'a',
+        name: 'A',
+        timeline: t,
+        categoryId: 'c2',
+      );
+      expect(a, isNot(b));
+    });
+
+    test('value equality: sortOrder differs', () {
+      final t = _singleFrameTimeline();
+      final a = ProjectSurfaceAnimation(
+        id: 'a',
+        name: 'A',
+        timeline: t,
+        sortOrder: 0,
+      );
+      final b = ProjectSurfaceAnimation(
+        id: 'a',
+        name: 'A',
+        timeline: t,
+        sortOrder: 1,
+      );
+      expect(a, isNot(b));
+    });
+
+    test('value equality: timeline order differs (same frames, different order)', () {
+      final f1 = _frame(0, 0, 10);
+      final f2 = _frame(1, 0, 10);
+      final t1 = SurfaceAnimationTimeline(frames: [f1, f2]);
+      final t2 = SurfaceAnimationTimeline(frames: [f2, f1]);
+      final a = ProjectSurfaceAnimation(id: 'a', name: 'A', timeline: t1);
+      final b = ProjectSurfaceAnimation(id: 'a', name: 'A', timeline: t2);
+      expect(a, isNot(b));
+    });
+
+    test('export: type is visible through map_core', () {
+      final animation = ProjectSurfaceAnimation(
+        id: 'a',
+        name: 'A',
+        timeline: _singleFrameTimeline(),
+      );
+      expect(animation, isA<ProjectSurfaceAnimation>());
+    });
+
+    test('ProjectManifest toJson: no surface* top-level keys', () {
+      const manifest = ProjectManifest(
+        name: 'L27',
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

*Fin — Lot 27 — ProjectSurfaceAnimation (map_core).*
