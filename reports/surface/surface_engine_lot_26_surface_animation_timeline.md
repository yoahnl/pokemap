# Lot 26 — Surface Animation Timeline Value Object V0

## 1. Résumé exécutif

Ajout de **`SurfaceAnimationTimeline`** dans `packages/map_core/lib/src/models/surface.dart` : liste **ordonnée** et **immuable** de [`SurfaceAnimationFrame`], rejet de liste vide, copie défensive + `List.unmodifiable`, `frameCount`, `totalDurationMs` (somme), `isInside` = toutes les frames, égalité **sensible à l’ordre** via `_surfaceAnimationFramesEqualInOrder` et `Object.hashAll`. Aucun JSON, pas de `ProjectManifest` modifié, pas de `ProjectSurfaceAnimation`. Test dédié : **15** cas. Suite `map_core` : **612** tests verts. `dart analyze` ciblé : **Aucun problème**.

## 2. Pourquoi ce lot vient après le Lot 25

Le **Lot 25** posait l’atome **frame** (tuile + durée). Le **Lot 26** enchaîne plusieurs frames en **séquence** (donnée de domaine) sans moteur de lecture, sans identifiant projet.

## 3. Fichiers consultés (audit)

- `packages/map_core/lib/src/models/surface.dart` (types jusqu’à `SurfaceAnimationFrame`)
- Tests surface 21–25 (réf. conventions)
- `map_exceptions.dart`, `map_core.dart` (export `surface.dart` déjà là)

## 4. Fichiers créés

- `packages/map_core/test/surface_animation_timeline_test.dart`
- `reports/surface/surface_engine_lot_26_surface_animation_timeline.md` (ce document)

## 5. Fichiers modifiés

- `packages/map_core/lib/src/models/surface.dart` uniquement

**Inchangés :** `map_core/lib/map_core.dart`, `project_manifest.dart`, autres packages, aucun fichier généré.

## 6. API ajoutée

- `SurfaceAnimationTimeline({ required List<SurfaceAnimationFrame> frames })`
- `List<SurfaceAnimationFrame> get frames` (unmodifiable)
- `int get frameCount`
- `int get totalDurationMs`
- `bool isInside(SurfaceAtlasGeometry geometry)`
- `==` / `hashCode` (ordre des frames compte)
- Aide : `_surfaceAnimationFramesEqualInOrder` (bibliothèque standard uniquement)

## 7. Sémantique de `SurfaceAnimationTimeline`

Modèle de domaine pur : pas de persistance, pas d’`id` projet, pas de résolution temporelle ; `totalDurationMs` = somme des durées **déclarées** ; `isInside` = vérification géométrique cumulée.

## 8. Validation de `frames`

`frames.isEmpty` → `ValidationException('SurfaceAnimationTimeline.frames must be non-empty')`. Stockage : `List<SurfaceAnimationFrame>.from(frames)` puis `List<SurfaceAnimationFrame>.unmodifiable(...)`.

## 9. Sémantique de `frameCount`

Alias de `frames.length` (via `_frames.length`).

## 10. Sémantique de `totalDurationMs`

Somme de chaque `SurfaceAnimationFrame.durationMs`.

## 11. Sémantique de `isInside`

`frames.every((f) => f.isInside(geometry))` — pas d’`atlasId` résolu, pas de texture, indépendant d’un moteur ; délègue la sémantique de frame au Lot 25 / 24.

## 12. Ce qui a été testé

15 cas (minimal, vide, ordre, somme, unmodifiable, copie défensive, `isInside` vrai/faux/layout, égalités ordre/durée/tuile, export, `ProjectManifest`).

## 13. Ce que les tests prouvent

Comportement VO, immuabilité, défense contre mutation source, sémantique `isInside` / ordre, contrat manifest inchangé.

## 14. Ce qui n’a volontairement pas été fait

`ProjectSurfaceAnimation`, JSON, playback, frame courante, moteur, migration manifest.

## 15. Pourquoi `ProjectManifest` n’a toujours pas été modifié

Les champs / listes Surface persistantes restent sur la roadmap de lots ultérieurs ; ici on fige seulement le type domaine.

## 16. Pourquoi aucun fichier généré n’a été créé

Cohérence avec les lots 21–26 : VOs manuels dans `surface.dart`.

## 17. Impact pour les prochains lots Surface

Un futur `ProjectSurfaceAnimation` (ou autre) pourra s’appuyer sur `SurfaceAnimationTimeline` comme **donnée** de séquence une fois le manifest prêt.

## 18. Commandes lancées

Répertoire : `packages/map_core`, binaire : `/opt/homebrew/bin/dart`.

- `dart test test/surface_animation_timeline_test.dart` → `+15: All tests passed!` (0)
- `dart test` (groupe 6 fichiers surface listés) → `+88: All tests passed!` (0)
- `dart analyze` (chemins du prompt) → `No issues found!` (0)
- `dart test` (complet) → `+612: All tests passed!` (0)

## 19. Résultats exacts (résumé)

| Commande | Dernière ligne / sortie |
|----------|-------------------------|
| `test/surface_animation_timeline_test.dart` | `+15: All tests passed!` |
| Groupe tests surface (6 fichiers) | `+88: All tests passed!` |
| `dart analyze` | `No issues found!` |
| `dart test` (tout) | `+612: All tests passed!` |

## 20. Total exact du `dart test` complet (map_core)

**612** tests, tous passés.

## 21. Points de vigilance

- `Object.hashAll` : ordre des frames influence `hashCode` (souhaité).
- Aucune déduplication de frames : une même instance répétée dans la liste compte autant de fois en somme / égalité.

## 22. Autocritique finale

- Égalité pourrait s’appuyer sur `==` de `List<SurfaceAnimationFrame>` ; la fonction privée garde l’intention explicite sans dépendre du comportement exact de comparaison de listes pour des listes vues (ici équivalente).

## 23. Ce que le prompt semble discutable ou incomplet

- Rien de bloquant. `List.unmodifiable` après `List.from` : conforme copie + immuabilité.

## 24. Auto-review indépendante

| Item | Oui / Non |
|------|-----------|
| Périmètre `SurfaceAnimationTimeline` + test + rapport seulement | **Oui** |
| `ProjectManifest` non modifié (source) | **Oui** |
| Aucun champ surface persistant | **Oui** |
| Pas de Freezed / JSON généré / `.g` / `.freezed` | **Oui** |
| Aucun autre package | **Oui** |
| Liste non vide validée, copie défensive, unmodifiable | **Oui** |
| `totalDurationMs` = somme | **Oui** |
| `isInside` = toutes les frames | **Oui** |
| Ordre d’`==` / `hashCode` | **Oui** |
| Export + garde-fou `toJson` | **Oui** |
| `map_core` 612/612 | **Oui** |
| Diffs / sources intégrés (sections 25–26 ci-dessous) | **Oui** |
| **Commandes git d’écriture** | **Non** (conforme consigne) |

## 25. Contenu complet des fichiers (verbatim + patch)

Le script d’injection a rempli la section 25 (fichier `surface.dart` complet, test, `diff -u` du test) au moment de la génération sur disque. Si le fichier a été re-tronqué manuellement, se référer au chemin de vérité dans le dépôt.

### 25.A `packages/map_core/lib/src/models/surface.dart` (fichier complet)

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
```
### 25.B `packages/map_core/test/surface_animation_timeline_test.dart` (fichier complet)

```dart
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

SurfaceAnimationFrame _frame({
  required String atlasId,
  required int column,
  required int row,
  required int durationMs,
}) {
  return SurfaceAnimationFrame(
    tileRef: SurfaceAtlasTileRef(
      atlasId: atlasId,
      column: column,
      row: row,
    ),
    durationMs: durationMs,
  );
}

void main() {
  group('SurfaceAnimationTimeline', () {
    test('minimal timeline with one frame', () {
      final frame = SurfaceAnimationFrame(
        tileRef: SurfaceAtlasTileRef(
          atlasId: 'water-atlas',
          column: 0,
          row: 0,
        ),
        durationMs: 120,
      );

      final timeline = SurfaceAnimationTimeline(frames: [frame]);

      expect(timeline.frames.length, 1);
      expect(timeline.frameCount, 1);
      expect(timeline.totalDurationMs, 120);
      expect(timeline.frames.first, frame);
    });

    test('rejects empty frames list', () {
      expect(
        () => SurfaceAnimationTimeline(frames: []),
        throwsA(isA<ValidationException>()),
      );
    });

    test('preserves frame order', () {
      final a = _frame(atlasId: 'a', column: 0, row: 0, durationMs: 1);
      final b = _frame(atlasId: 'b', column: 0, row: 0, durationMs: 1);
      final c = _frame(atlasId: 'c', column: 0, row: 0, durationMs: 1);
      final timeline = SurfaceAnimationTimeline(frames: [a, b, c]);
      expect(timeline.frames[0], a);
      expect(timeline.frames[1], b);
      expect(timeline.frames[2], c);
    });

    test('totalDurationMs sums frame durations', () {
      final timeline = SurfaceAnimationTimeline(
        frames: [
          _frame(atlasId: 'x', column: 0, row: 0, durationMs: 50),
          _frame(atlasId: 'x', column: 1, row: 0, durationMs: 100),
          _frame(atlasId: 'x', column: 2, row: 0, durationMs: 150),
        ],
      );
      expect(timeline.totalDurationMs, 300);
    });

    test('exposed frames list is unmodifiable', () {
      final f = _frame(atlasId: 'a', column: 0, row: 0, durationMs: 10);
      final timeline = SurfaceAnimationTimeline(frames: [f]);
      expect(
        () => timeline.frames.add(f),
        throwsA(isA<UnsupportedError>()),
      );
    });

    test('defensive copy: mutating source after construction does not affect timeline', () {
      final f1 = _frame(atlasId: 'a', column: 0, row: 0, durationMs: 10);
      final source = <SurfaceAnimationFrame>[f1];
      final timeline = SurfaceAnimationTimeline(frames: source);
      final f2 = _frame(atlasId: 'b', column: 0, row: 0, durationMs: 20);
      source.add(f2);
      expect(timeline.frameCount, 1);
      expect(timeline.frames.length, 1);
      expect(timeline.frames.first, f1);
    });

    test('isInside: true when all frames are inside grid', () {
      final geometry = SurfaceAtlasGeometry(
        tileSize: SurfaceAtlasTileSize(width: 32, height: 32),
        gridSize: SurfaceAtlasGridSize(columns: 4, rows: 3),
      );
      final timeline = SurfaceAnimationTimeline(
        frames: [
          _frame(atlasId: 'a', column: 0, row: 0, durationMs: 10),
          _frame(atlasId: 'a', column: 3, row: 2, durationMs: 10),
        ],
      );
      expect(timeline.isInside(geometry), isTrue);
    });

    test('isInside: false when any frame is out of grid', () {
      final geometry = SurfaceAtlasGeometry(
        tileSize: SurfaceAtlasTileSize(width: 32, height: 32),
        gridSize: SurfaceAtlasGridSize(columns: 4, rows: 3),
      );
      final timeline = SurfaceAnimationTimeline(
        frames: [
          _frame(atlasId: 'a', column: 0, row: 0, durationMs: 10),
          _frame(atlasId: 'a', column: 4, row: 0, durationMs: 10),
        ],
      );
      expect(timeline.isInside(geometry), isFalse);
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
          _frame(atlasId: 'a', column: 1, row: 1, durationMs: 5),
        ],
      );
      expect(timeline.isInside(gGrid), isTrue);
      expect(timeline.isInside(gVertical), isTrue);
    });

    test('value equality: same frames in same order => equal and same hashCode', () {
      final t1 = SurfaceAnimationTimeline(
        frames: [
          _frame(atlasId: 'a', column: 0, row: 0, durationMs: 10),
          _frame(atlasId: 'a', column: 1, row: 0, durationMs: 20),
        ],
      );
      final t2 = SurfaceAnimationTimeline(
        frames: [
          _frame(atlasId: 'a', column: 0, row: 0, durationMs: 10),
          _frame(atlasId: 'a', column: 1, row: 0, durationMs: 20),
        ],
      );
      expect(t1, t2);
      expect(t1.hashCode, t2.hashCode);
    });

    test('value equality: different order => not equal', () {
      final f0 = _frame(atlasId: 'a', column: 0, row: 0, durationMs: 10);
      final f1 = _frame(atlasId: 'a', column: 1, row: 0, durationMs: 10);
      final t1 = SurfaceAnimationTimeline(frames: [f0, f1]);
      final t2 = SurfaceAnimationTimeline(frames: [f1, f0]);
      expect(t1, isNot(t2));
    });

    test('value equality: different frame content => not equal', () {
      final t1 = SurfaceAnimationTimeline(
        frames: [
          _frame(atlasId: 'a', column: 0, row: 0, durationMs: 10),
        ],
      );
      final t2 = SurfaceAnimationTimeline(
        frames: [
          _frame(atlasId: 'b', column: 0, row: 0, durationMs: 10),
        ],
      );
      expect(t1, isNot(t2));
    });

    test('value equality: different duration on a frame => not equal', () {
      final t1 = SurfaceAnimationTimeline(
        frames: [
          _frame(atlasId: 'a', column: 0, row: 0, durationMs: 10),
        ],
      );
      final t2 = SurfaceAnimationTimeline(
        frames: [
          _frame(atlasId: 'a', column: 0, row: 0, durationMs: 99),
        ],
      );
      expect(t1, isNot(t2));
    });

    test('export: type is visible through map_core', () {
      final t = SurfaceAnimationTimeline(
        frames: [
          _frame(atlasId: 'a', column: 0, row: 0, durationMs: 1),
        ],
      );
      expect(t, isA<SurfaceAnimationTimeline>());
    });

    test('ProjectManifest toJson: no surface* top-level keys', () {
      const manifest = ProjectManifest(
        name: 'L26',
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
### 25.C `diff -u /dev/null` — test

```diff
--- /dev/null	2026-04-26 23:31:38
+++ /Users/karim/Project/pokemonProject/packages/map_core/test/surface_animation_timeline_test.dart	2026-04-26 23:31:10
@@ -0,0 +1,224 @@
+import 'package:map_core/map_core.dart';
+import 'package:test/test.dart';
+
+SurfaceAnimationFrame _frame({
+  required String atlasId,
+  required int column,
+  required int row,
+  required int durationMs,
+}) {
+  return SurfaceAnimationFrame(
+    tileRef: SurfaceAtlasTileRef(
+      atlasId: atlasId,
+      column: column,
+      row: row,
+    ),
+    durationMs: durationMs,
+  );
+}
+
+void main() {
+  group('SurfaceAnimationTimeline', () {
+    test('minimal timeline with one frame', () {
+      final frame = SurfaceAnimationFrame(
+        tileRef: SurfaceAtlasTileRef(
+          atlasId: 'water-atlas',
+          column: 0,
+          row: 0,
+        ),
+        durationMs: 120,
+      );
+
+      final timeline = SurfaceAnimationTimeline(frames: [frame]);
+
+      expect(timeline.frames.length, 1);
+      expect(timeline.frameCount, 1);
+      expect(timeline.totalDurationMs, 120);
+      expect(timeline.frames.first, frame);
+    });
+
+    test('rejects empty frames list', () {
+      expect(
+        () => SurfaceAnimationTimeline(frames: []),
+        throwsA(isA<ValidationException>()),
+      );
+    });
+
+    test('preserves frame order', () {
+      final a = _frame(atlasId: 'a', column: 0, row: 0, durationMs: 1);
+      final b = _frame(atlasId: 'b', column: 0, row: 0, durationMs: 1);
+      final c = _frame(atlasId: 'c', column: 0, row: 0, durationMs: 1);
+      final timeline = SurfaceAnimationTimeline(frames: [a, b, c]);
+      expect(timeline.frames[0], a);
+      expect(timeline.frames[1], b);
+      expect(timeline.frames[2], c);
+    });
+
+    test('totalDurationMs sums frame durations', () {
+      final timeline = SurfaceAnimationTimeline(
+        frames: [
+          _frame(atlasId: 'x', column: 0, row: 0, durationMs: 50),
+          _frame(atlasId: 'x', column: 1, row: 0, durationMs: 100),
+          _frame(atlasId: 'x', column: 2, row: 0, durationMs: 150),
+        ],
+      );
+      expect(timeline.totalDurationMs, 300);
+    });
+
+    test('exposed frames list is unmodifiable', () {
+      final f = _frame(atlasId: 'a', column: 0, row: 0, durationMs: 10);
+      final timeline = SurfaceAnimationTimeline(frames: [f]);
+      expect(
+        () => timeline.frames.add(f),
+        throwsA(isA<UnsupportedError>()),
+      );
+    });
+
+    test('defensive copy: mutating source after construction does not affect timeline', () {
+      final f1 = _frame(atlasId: 'a', column: 0, row: 0, durationMs: 10);
+      final source = <SurfaceAnimationFrame>[f1];
+      final timeline = SurfaceAnimationTimeline(frames: source);
+      final f2 = _frame(atlasId: 'b', column: 0, row: 0, durationMs: 20);
+      source.add(f2);
+      expect(timeline.frameCount, 1);
+      expect(timeline.frames.length, 1);
+      expect(timeline.frames.first, f1);
+    });
+
+    test('isInside: true when all frames are inside grid', () {
+      final geometry = SurfaceAtlasGeometry(
+        tileSize: SurfaceAtlasTileSize(width: 32, height: 32),
+        gridSize: SurfaceAtlasGridSize(columns: 4, rows: 3),
+      );
+      final timeline = SurfaceAnimationTimeline(
+        frames: [
+          _frame(atlasId: 'a', column: 0, row: 0, durationMs: 10),
+          _frame(atlasId: 'a', column: 3, row: 2, durationMs: 10),
+        ],
+      );
+      expect(timeline.isInside(geometry), isTrue);
+    });
+
+    test('isInside: false when any frame is out of grid', () {
+      final geometry = SurfaceAtlasGeometry(
+        tileSize: SurfaceAtlasTileSize(width: 32, height: 32),
+        gridSize: SurfaceAtlasGridSize(columns: 4, rows: 3),
+      );
+      final timeline = SurfaceAnimationTimeline(
+        frames: [
+          _frame(atlasId: 'a', column: 0, row: 0, durationMs: 10),
+          _frame(atlasId: 'a', column: 4, row: 0, durationMs: 10),
+        ],
+      );
+      expect(timeline.isInside(geometry), isFalse);
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
+          _frame(atlasId: 'a', column: 1, row: 1, durationMs: 5),
+        ],
+      );
+      expect(timeline.isInside(gGrid), isTrue);
+      expect(timeline.isInside(gVertical), isTrue);
+    });
+
+    test('value equality: same frames in same order => equal and same hashCode', () {
+      final t1 = SurfaceAnimationTimeline(
+        frames: [
+          _frame(atlasId: 'a', column: 0, row: 0, durationMs: 10),
+          _frame(atlasId: 'a', column: 1, row: 0, durationMs: 20),
+        ],
+      );
+      final t2 = SurfaceAnimationTimeline(
+        frames: [
+          _frame(atlasId: 'a', column: 0, row: 0, durationMs: 10),
+          _frame(atlasId: 'a', column: 1, row: 0, durationMs: 20),
+        ],
+      );
+      expect(t1, t2);
+      expect(t1.hashCode, t2.hashCode);
+    });
+
+    test('value equality: different order => not equal', () {
+      final f0 = _frame(atlasId: 'a', column: 0, row: 0, durationMs: 10);
+      final f1 = _frame(atlasId: 'a', column: 1, row: 0, durationMs: 10);
+      final t1 = SurfaceAnimationTimeline(frames: [f0, f1]);
+      final t2 = SurfaceAnimationTimeline(frames: [f1, f0]);
+      expect(t1, isNot(t2));
+    });
+
+    test('value equality: different frame content => not equal', () {
+      final t1 = SurfaceAnimationTimeline(
+        frames: [
+          _frame(atlasId: 'a', column: 0, row: 0, durationMs: 10),
+        ],
+      );
+      final t2 = SurfaceAnimationTimeline(
+        frames: [
+          _frame(atlasId: 'b', column: 0, row: 0, durationMs: 10),
+        ],
+      );
+      expect(t1, isNot(t2));
+    });
+
+    test('value equality: different duration on a frame => not equal', () {
+      final t1 = SurfaceAnimationTimeline(
+        frames: [
+          _frame(atlasId: 'a', column: 0, row: 0, durationMs: 10),
+        ],
+      );
+      final t2 = SurfaceAnimationTimeline(
+        frames: [
+          _frame(atlasId: 'a', column: 0, row: 0, durationMs: 99),
+        ],
+      );
+      expect(t1, isNot(t2));
+    });
+
+    test('export: type is visible through map_core', () {
+      final t = SurfaceAnimationTimeline(
+        frames: [
+          _frame(atlasId: 'a', column: 0, row: 0, durationMs: 1),
+        ],
+      );
+      expect(t, isA<SurfaceAnimationTimeline>());
+    });
+
+    test('ProjectManifest toJson: no surface* top-level keys', () {
+      const manifest = ProjectManifest(
+        name: 'L26',
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


## 26. Diff complet réel — `packages/map_core/lib/src/models/surface.dart`

```diff
diff --git a/packages/map_core/lib/src/models/surface.dart b/packages/map_core/lib/src/models/surface.dart
index 188fe0e5..5992bf97 100644
--- a/packages/map_core/lib/src/models/surface.dart
+++ b/packages/map_core/lib/src/models/surface.dart
@@ -333,3 +333,80 @@ final class SurfaceAnimationFrame {
   @override
   int get hashCode => Object.hash(tileRef, durationMs);
 }
+
+/// Comparaison **ordonnée** de deux listes de frames (même longueur et égalité
+/// élément par élément) — utile à [SurfaceAnimationTimeline] pour [operator ==]
+/// sans dépendre d’un utilitaire de collection externe.
+bool _surfaceAnimationFramesEqualInOrder(
+  List<SurfaceAnimationFrame> a,
+  List<SurfaceAnimationFrame> b,
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
+/// Timeline d’animation Surface côté **domaine** : une liste **ordonnée** et
+/// **immuable** de [SurfaceAnimationFrame].
+///
+/// * Pas de [toJson] / [fromJson] ; ne constitue **pas** [ProjectSurfaceAnimation]
+///   ni d’enregistrement de projet.
+/// * Aucun **temps courant**, **frame courante** ou moteur de lecture : c’est
+///   seulement la séquence et les durées **déclarées** ; [totalDurationMs] est
+///   la somme de ces durées, pas une exécution.
+/// * [isInside] n’agit qu’en validation **géométrique** (toutes les frames
+///   [SurfaceAnimationFrame.isInside]) : pas d’[atlasId] résolu, pas de manifest,
+///   pas de texture, pas de runtime.
+/// * La liste passée au constructeur est **copiée** puis enrobée en non modifiable
+///   (une mutation de la source après construction ne change **pas** la timeline).
+@immutable
+final class SurfaceAnimationTimeline {
+  SurfaceAnimationTimeline({
+    required List<SurfaceAnimationFrame> frames,
+  }) {
+    if (frames.isEmpty) {
+      throw const ValidationException(
+        'SurfaceAnimationTimeline.frames must be non-empty',
+      );
+    }
+    _frames = List<SurfaceAnimationFrame>.unmodifiable(
+      List<SurfaceAnimationFrame>.from(frames),
+    );
+  }
+
+  late final List<SurfaceAnimationFrame> _frames;
+
+  /// Frames dans l’**ordre** d’enchaînement (liste **non modifiable**).
+  List<SurfaceAnimationFrame> get frames => _frames;
+
+  /// Nombre de frames.
+  int get frameCount => _frames.length;
+
+  /// Somme des [SurfaceAnimationFrame.durationMs] (millisecondes déclarées).
+  int get totalDurationMs {
+    var sum = 0;
+    for (final frame in _frames) {
+      sum += frame.durationMs;
+    }
+    return sum;
+  }
+
+  /// Vrai si **chaque** frame tient dans [geometry] (même règles qu’en Lot 25).
+  bool isInside(SurfaceAtlasGeometry geometry) =>
+      _frames.every((frame) => frame.isInside(geometry));
+
+  @override
+  bool operator ==(Object other) =>
+      identical(this, other) ||
+      other is SurfaceAnimationTimeline &&
+          _surfaceAnimationFramesEqualInOrder(frames, other.frames);
+
+  @override
+  int get hashCode => Object.hashAll(_frames);
+}
```


---

*Fin — Lot 26 — SurfaceAnimationTimeline (map_core seulement).*
