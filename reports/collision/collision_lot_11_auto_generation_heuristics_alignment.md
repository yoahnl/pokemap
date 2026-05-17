# Collision Lot 11 — Auto-generation Documentation / Heuristics Alignment V0

## 1. Résumé exécutif

Collision-11 aligne la génération automatique `map_editor` avec le contrat collision stabilisé :

- `visualMask` reste l’occupation visuelle issue de l’alpha.
- `collisionMask` est dérivé par heuristiques, pas par copie brute de l’alpha.
- `occlusionMask` est dérivé séparément et reste non bloquant.
- `cells` est maintenant la projection legacy/debug de `collisionMask`.

Le lot ajoute des tests ciblés sur PNG synthétique et sur `PlacedElementMaskHeuristicsV1`, corrige les commentaires obsolètes, et ne modifie aucun package hors `map_editor`.

## 2. Git status initial

Commande :

```bash
git status --short --untracked-files=all
```

Sortie exacte initiale dans le worktree Collision :

```text

```

Le checkout principal `/Users/karim/Project/pokemonProject` ne contenait pas les lots Collision 3 à 10-bis. Le lot a donc été exécuté dans le worktree actif des lots précédents :

```text
/Users/karim/.config/superpowers/worktrees/pokemonProject/collision-source-of-truth-worktree
```

## 3. Rapports précédents relus

Rapports présents et relus dans le worktree Collision :

```text
reports/collision/collision_lot_4_element_collision_profile_normalizer.md
reports/collision/collision_lot_5_collision_mask_cells_projection_contract.md
reports/collision/collision_lot_10_building_golden_slice.md
reports/collision/collision_lot_10bis_fine_collision_mask_authoring_ui.md
```

Décisions reprises :

- `collisionMask` est la vérité fine gameplay.
- `visualMask` est une aide d’analyse / aperçu.
- `occlusionMask` est réservé au rendu devant/derrière et ne bloque pas.
- `cells` est une projection legacy / fallback / debug.
- L’UI fine mask permet maintenant d’éditer `collisionMask`, donc la génération auto doit documenter honnêtement ses masques initiaux.

## 4. Audit ciblé de la génération automatique

Fichiers audités :

```text
packages/map_editor/lib/src/application/collision_generation/element_visual_occupancy_analyzer.dart
packages/map_editor/lib/src/application/collision_generation/element_visual_occupancy_raster.dart
packages/map_editor/lib/src/application/collision_generation/placed_element_auto_collision_generator.dart
packages/map_editor/lib/src/application/collision_generation/placed_element_collision_params.dart
packages/map_editor/lib/src/application/collision_generation/placed_element_mask_heuristics_v1.dart
packages/map_editor/test/collision_generation/placed_element_auto_collision_copy_test.dart
packages/map_editor/test/collision_generation/element_ground_blocking_analyzer_test.dart
packages/map_core/lib/src/operations/element_collision_mask_codec.dart
packages/map_core/lib/src/operations/element_collision_profile_normalizer.dart
```

Constats :

- `ElementVisualOccupancyAnalyzer` produit uniquement un masque booléen d’occupation visuelle avec padding et seuil alpha.
- `PlacedElementMaskHeuristicsV1` dérive `collision` et `occlusion` depuis l’occupation visuelle.
- `PlacedElementAutoCollisionGenerator` produisait déjà `visualMask`, `collisionMask`, `occlusionMask`.
- `PlacedElementAutoCollisionGenerator` laissait `cells: const []`, ce qui divergeait du contrat Collision-5/10-bis.
- `placed_element_collision_params.dart` et `element_visual_occupancy_raster.dart` contenaient encore des formulations de type copie alpha vers collision.
- Le test historique `placed_element_auto_collision_copy_test.dart` ne testait pas réellement le générateur et conservait un nom de test trompeur.

## 5. Chaîne réelle de génération

Chaîne finale documentée :

```text
image source / alpha
→ ElementVisualOccupancyAnalyzer.analyze(...)
→ visualMask = occupation visuelle alpha après padding et seuil
→ PlacedElementMaskHeuristicsV1.deriveFromVisualOccupancy(...)
→ collisionMask = sous-ensemble gameplay dérivé par heuristiques
→ occlusionMask = sous-ensemble rendu dérivé par heuristiques
→ cells = ElementCollisionMaskCodec.cellsFromPixelMask(collisionMask, tileWidth/tileHeight/source size)
→ ElementCollisionProfile(source: generated, ...)
```

## 6. Heuristiques identifiées

Heuristiques V1 observées :

- BBox des pixels visibles.
- Bande d’occlusion haute : `occlusionBandTopFraction = 0.38`.
- Bande d’ombre basse maximale : `shadowBandMaxFraction = 0.22`.
- Ligne d’ombre candidate si sa densité est inférieure au ratio `shadowDensityRatioVsMaxRow = 0.48` par rapport à la ligne la plus dense.
- L’ombre basse est retirée de `collisionMask` mais reste présente dans `visualMask`.
- L’occlusion est produite dans une bande haute du bbox et n’est pas injectée dans la collision.

## 7. Contrat visualMask / collisionMask / occlusionMask / cells

Contrat final :

```text
visualMask
  Occupation visuelle / aide d’analyse. Ne bloque jamais le joueur.

collisionMask
  Masque gameplay initial généré. Retouchable ensuite dans le mode Masque fin.

occlusionMask
  Masque de rendu futur devant/derrière. Ne bloque jamais le joueur.

cells
  Projection legacy/debug du collisionMask généré. Pas une source de vérité séparée.
```

## 8. Décision sur cells générées

Décision : Option A.

Le générateur remplit désormais `cells` avec la projection de `collisionMask` via :

```dart
ElementCollisionMaskCodec.cellsFromPixelMask(
  mask: collisionMask,
  tileWidth: tileWidth,
  tileHeight: tileHeight,
  sourceWidthInTiles: source.width,
  sourceHeightInTiles: source.height,
)
```

Raison :

- Cohérent avec Collision-5.
- Cohérent avec `ElementCollisionTripleMaskEditor`.
- Améliore les vues legacy/debug sans changer la vérité fine.
- Ne change pas le JSON schema.

## 9. Fichiers créés

```text
packages/map_editor/test/collision_generation/placed_element_mask_heuristics_v1_test.dart
reports/collision/collision_lot_11_auto_generation_heuristics_alignment.md
```

## 10. Fichiers modifiés

```text
packages/map_editor/lib/src/application/collision_generation/element_visual_occupancy_raster.dart
packages/map_editor/lib/src/application/collision_generation/placed_element_auto_collision_generator.dart
packages/map_editor/lib/src/application/collision_generation/placed_element_collision_params.dart
packages/map_editor/lib/src/application/collision_generation/placed_element_mask_heuristics_v1.dart
packages/map_editor/test/collision_generation/placed_element_auto_collision_copy_test.dart
```

## 11. Fichiers explicitement non modifiés

```text
packages/map_core/**
packages/map_gameplay/**
packages/map_runtime/**
packages/map_battle/**
examples/**
packages/map_editor/lib/src/infrastructure/repositories/file_repositories.dart
packages/map_editor/lib/src/ui/panels/element_collision_editor_sheet.dart
packages/map_editor/lib/src/ui/widgets/element_collision_triple_mask_editor.dart
packages/map_editor/test/element_collision_editor_sheet_fine_mask_test.dart
```

## 12. Tests ajoutés / modifiés

Tests modifiés dans `placed_element_auto_collision_copy_test.dart` :

- `creates visual collision and occlusion masks from alpha heuristics`
- `projects generated collisionMask into legacy cells`
- `respects padding before deriving masks from alpha`
- `documents alpha threshold as visual occupancy input`

Tests créés dans `placed_element_mask_heuristics_v1_test.dart` :

- `removes sparse bottom shadow rows from collision only`
- `empty visual occupancy creates no collision or occlusion`

Test RED observé avant correction :

```text
Expected: [GridPos(x: 0, y: 0)]
Actual: []
Which: at location [0] is [] which shorter than expected
```

## 13. Commandes lancées

```bash
git status --short --untracked-files=all
find reports/collision -maxdepth 1 -type f | sort
rg -n "PlacedElementAutoCollisionGenerator|PlacedElementCollisionGenerationParams|PlacedElementMaskHeuristicsV1|ElementVisualOccupancyAnalyzer|ElementVisualOccupancyRaster|visualMask|collisionMask|occlusionMask|cellsFromPixelMask|alpha|shadow|density|band|occlusion|copy alpha|copie alpha|heuristic|heuristique" packages/map_editor/lib packages/map_editor/test packages/map_core/lib
flutter test --no-pub --reporter compact test/collision_generation/placed_element_auto_collision_copy_test.dart
flutter test --no-pub --reporter expanded test/collision_generation/placed_element_auto_collision_copy_test.dart test/collision_generation/placed_element_mask_heuristics_v1_test.dart
dart format packages/map_editor/lib/src/application/collision_generation/element_visual_occupancy_raster.dart packages/map_editor/lib/src/application/collision_generation/placed_element_auto_collision_generator.dart packages/map_editor/lib/src/application/collision_generation/placed_element_collision_params.dart packages/map_editor/lib/src/application/collision_generation/placed_element_mask_heuristics_v1.dart packages/map_editor/test/collision_generation/placed_element_auto_collision_copy_test.dart packages/map_editor/test/collision_generation/placed_element_mask_heuristics_v1_test.dart
flutter test --no-pub --reporter compact test/collision_generation/placed_element_auto_collision_copy_test.dart test/collision_generation/placed_element_mask_heuristics_v1_test.dart test/collision_generation/element_ground_blocking_analyzer_test.dart
flutter test --no-pub --reporter compact test/element_collision_editor_sheet_fine_mask_test.dart test/collision_building_golden_slice_test.dart test/element_collision_truth_summary_test.dart
flutter analyze lib/src/application/collision_generation/placed_element_auto_collision_generator.dart lib/src/application/collision_generation/placed_element_collision_params.dart lib/src/application/collision_generation/placed_element_mask_heuristics_v1.dart lib/src/application/collision_generation/element_visual_occupancy_raster.dart test/collision_generation/placed_element_auto_collision_copy_test.dart test/collision_generation/placed_element_mask_heuristics_v1_test.dart
git diff --name-only
git diff --stat
git status --short --untracked-files=all
```

## 14. Résultats des tests ciblés

Baseline avant modification :

```text
00:01 +1: All tests passed!
```

RED attendu avant correction de production :

```text
00:00 +1 -1: PlacedElementAutoCollisionGenerator projects generated collisionMask into legacy cells [E]
Expected: [GridPos(x: 0, y: 0)]
Actual: []
```

Après modification :

```text
00:01 +8: All tests passed!
```

Commande :

```bash
flutter test --no-pub --reporter compact test/collision_generation/placed_element_auto_collision_copy_test.dart test/collision_generation/placed_element_mask_heuristics_v1_test.dart test/collision_generation/element_ground_blocking_analyzer_test.dart
```

Tests de non-régression editor collision :

```text
00:06 +23: All tests passed!
```

Commande :

```bash
flutter test --no-pub --reporter compact test/element_collision_editor_sheet_fine_mask_test.dart test/collision_building_golden_slice_test.dart test/element_collision_truth_summary_test.dart
```

## 15. Analyse statique / format

Format :

```text
Formatted packages/map_editor/lib/src/application/collision_generation/placed_element_mask_heuristics_v1.dart
Formatted packages/map_editor/test/collision_generation/placed_element_auto_collision_copy_test.dart
Formatted 6 files (2 changed) in 0.02 seconds.
Formatted 1 file (0 changed) in 0.01 seconds.
```

Analyse ciblée :

```text
Analyzing 6 items...
No issues found! (ran in 2.2s)
```

## 16. Vérification du périmètre

`git diff --name-only` avant création du rapport :

```text
packages/map_editor/lib/src/application/collision_generation/element_visual_occupancy_raster.dart
packages/map_editor/lib/src/application/collision_generation/placed_element_auto_collision_generator.dart
packages/map_editor/lib/src/application/collision_generation/placed_element_collision_params.dart
packages/map_editor/lib/src/application/collision_generation/placed_element_mask_heuristics_v1.dart
packages/map_editor/test/collision_generation/placed_element_auto_collision_copy_test.dart
```

Fichier untracked en plus :

```text
packages/map_editor/test/collision_generation/placed_element_mask_heuristics_v1_test.dart
```

Aucun fichier `map_core`, `map_gameplay`, `map_runtime`, `map_battle`, `examples`, generated ou `build_runner` n’a été modifié.

## 17. Git status final

Commande :

```bash
git status --short --untracked-files=all
```

Sortie exacte finale :

```text
 M packages/map_editor/lib/src/application/collision_generation/element_visual_occupancy_raster.dart
 M packages/map_editor/lib/src/application/collision_generation/placed_element_auto_collision_generator.dart
 M packages/map_editor/lib/src/application/collision_generation/placed_element_collision_params.dart
 M packages/map_editor/lib/src/application/collision_generation/placed_element_mask_heuristics_v1.dart
 M packages/map_editor/test/collision_generation/placed_element_auto_collision_copy_test.dart
?? packages/map_editor/test/collision_generation/placed_element_mask_heuristics_v1_test.dart
?? reports/collision/collision_lot_11_auto_generation_heuristics_alignment.md
```

## 18. git diff --stat

Commande :

```bash
git diff --stat
```

Sortie exacte finale pour les fichiers suivis modifiés :

```text
 .../element_visual_occupancy_raster.dart           |   3 +-
 .../placed_element_auto_collision_generator.dart   |  13 +-
 .../placed_element_collision_params.dart           |  11 +-
 .../placed_element_mask_heuristics_v1.dart         |   8 +-
 .../placed_element_auto_collision_copy_test.dart   | 196 ++++++++++++++++++---
 5 files changed, 195 insertions(+), 36 deletions(-)
```

## 19. Risques / réserves

- Le fichier de test historique garde le nom `placed_element_auto_collision_copy_test.dart` pour éviter un renommage de fichier non nécessaire. Le contenu ne décrit plus une copie alpha.
- Les heuristiques restent géométriques et simples. Les sprites atypiques devront toujours être retouchés dans l’éditeur fin.
- L’occlusion runtime n’est pas branchée dans ce lot.

Non vérifié.

**Sujet :**
Suite complète `packages/map_editor`.

**Raison :**
Le lot est limité à `collision_generation`; les tests ciblés et de non-régression collision editor ont été lancés.

**Impact :**
Une régression hors collision_generation dans une zone non ciblée de l’éditeur ne serait pas détectée par ce lot.

**Comment vérifier dans Collision-12 :**
Lancer `cd packages/map_editor && flutter test --no-pub --reporter compact` et documenter les échecs hors lot s’il y en a.

## 20. Ce que ce lot prouve

- Le générateur produit bien `visualMask`, `collisionMask` et `occlusionMask`.
- Une ligne basse clairsemée peut rester visuelle sans devenir collision.
- `occlusionMask` est dérivé séparément de `collisionMask`.
- `padding` rogne l’occupation alpha avant dérivation des masques.
- `cells` est la projection de `collisionMask`.
- Les commentaires trompeurs sur la copie alpha ont été corrigés.

## 21. Ce que ce lot ne prouve pas encore

- Le rendu runtime de `occlusionMask`.
- Une golden screenshot Flutter.
- La qualité des heuristiques sur tous les assets réels.
- Une génération automatique parfaite pour bâtiments complexes.

## 22. Recommandation après Collision-11

Collision-12 peut traiter l’occlusion runtime si c’est la prochaine priorité produit. Sinon, faire un test manuel avec plusieurs bâtiments réels et ajuster les heuristiques uniquement sur cas observés.

## 23. Auto-review finale

- Ai-je limité le lot à map_editor collision_generation ? Oui.
- Ai-je évité map_core ? Oui.
- Ai-je évité map_gameplay ? Oui.
- Ai-je évité map_runtime ? Oui.
- Ai-je évité FileProjectRepository ? Oui.
- Ai-je évité la sheet collision ? Oui.
- Ai-je évité build_runner/generated ? Oui.
- Ai-je documenté la chaîne réelle de génération ? Oui.
- Ai-je corrigé les commentaires trompeurs ? Oui.
- Ai-je ajouté des tests heuristiques ciblés ? Oui.
- Ai-je tranché la question des cells générées ? Oui, Option A.
- Ai-je conservé visualMask comme aperçu/analyse ? Oui.
- Ai-je conservé occlusionMask comme non bloquant ? Oui.
- Ai-je évité de changer les heuristiques sans preuve ? Oui.
- Ai-je relancé les tests ciblés ? Oui.

## 24. Contenu complet des fichiers créés/modifiés

### packages/map_editor/lib/src/application/collision_generation/element_visual_occupancy_raster.dart

```dart
import 'dart:typed_data';

/// Lecture bas niveau du buffer RGBA tileset : **occupation visuelle** pixel à
/// pixel (sans décision gameplay).
///
/// Sert à centraliser le test `opaque ?` et à documenter l’accès mémoire.
/// Le masque gameplay est produit ailleurs par heuristiques, pas par copie brute
/// de cette occupation visuelle.
class ElementVisualOccupancyRaster {
  const ElementVisualOccupancyRaster();

  /// `true` si le pixel est considéré comme matière visible (alpha strictement
  /// au-dessus du seuil).
  bool isOpaquePixel({
    required ByteData bytesData,
    required int imageWidth,
    required int x,
    required int y,
    required int alphaThreshold,
  }) {
    final pixelIndex = (y * imageWidth + x) * 4;
    final alpha = bytesData.getUint8(pixelIndex + 3);
    return alpha > alphaThreshold;
  }
}
```

### packages/map_editor/lib/src/application/collision_generation/placed_element_auto_collision_generator.dart

```dart
import 'dart:io';
import 'dart:ui' as ui;

import 'package:map_core/map_core.dart';

import 'element_visual_occupancy_analyzer.dart';
import 'placed_element_collision_params.dart';
import 'placed_element_mask_heuristics_v1.dart';

/// Orchestre le décodage image → [ElementCollisionProfile] avec **trois** rôles :
/// [ElementCollisionProfile.visualMask], [ElementCollisionProfile.collisionMask],
/// [ElementCollisionProfile.occlusionMask].
///
/// Pipeline (V2 produit) :
/// 1. occupation visuelle binaire (`ElementVisualOccupancyAnalyzer`) ;
/// 2. encodage du **visuel** tel quel ;
/// 3. **collision** et **occlusion** dérivés par [PlacedElementMaskHeuristicsV1]
///    (pas de copie « opaque = bloquant ») ;
/// 4. encodage `packed_bits_v1` pour chaque masque.
/// 5. projection legacy/debug de [ElementCollisionProfile.collisionMask] vers
///    [ElementCollisionProfile.cells].
class PlacedElementAutoCollisionGenerator {
  const PlacedElementAutoCollisionGenerator({
    ElementVisualOccupancyAnalyzer? visualOccupancyAnalyzer,
  }) : _visualOccupancyAnalyzer =
            visualOccupancyAnalyzer ?? const ElementVisualOccupancyAnalyzer();

  final ElementVisualOccupancyAnalyzer _visualOccupancyAnalyzer;

  Future<ElementCollisionProfile> generate({
    required String tilesetImagePath,
    required TilesetSourceRect source,
    required int tileWidth,
    required int tileHeight,
    WarpTriggerPadding padding = const WarpTriggerPadding(),
    PlacedElementCollisionGenerationParams params =
        PlacedElementCollisionGenerationParams.defaults,
  }) async {
    final normalizedPath = tilesetImagePath.trim();
    if (normalizedPath.isEmpty) {
      throw const FormatException('Tileset image path is empty');
    }
    if (tileWidth <= 0 || tileHeight <= 0) {
      throw const FormatException('Tile size must be strictly positive');
    }
    if (source.width <= 0 || source.height <= 0) {
      throw const FormatException(
        'Element source size must be strictly positive',
      );
    }

    final file = File(normalizedPath);
    if (!await file.exists()) {
      throw FileSystemException('Tileset image not found', normalizedPath);
    }
    final bytes = await file.readAsBytes();
    if (bytes.isEmpty) {
      throw const FormatException('Tileset image is empty');
    }

    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    final image = frame.image;
    final srcLeft = source.x * tileWidth;
    final srcTop = source.y * tileHeight;
    final srcWidth = source.width * tileWidth;
    final srcHeight = source.height * tileHeight;
    if (srcLeft < 0 ||
        srcTop < 0 ||
        srcLeft + srcWidth > image.width ||
        srcTop + srcHeight > image.height) {
      throw const FormatException(
        'Element source rectangle is outside tileset bounds',
      );
    }

    final bytesData =
        await image.toByteData(format: ui.ImageByteFormat.rawRgba);
    if (bytesData == null) {
      throw const FormatException('Unable to read tileset image pixels');
    }

    final maskWidthPx = source.width * tileWidth;
    final maskHeightPx = source.height * tileHeight;
    final visual = _visualOccupancyAnalyzer.analyze(
      bytesData: bytesData,
      imageWidth: image.width,
      srcLeft: srcLeft,
      srcTop: srcTop,
      srcWidth: srcWidth,
      srcHeight: srcHeight,
      padding: padding,
      alphaThreshold: params.alphaThreshold,
    );
    final visualPixels = List<bool>.from(visual.visiblePixels);
    final derived = PlacedElementMaskHeuristicsV1.deriveFromVisualOccupancy(
      visualOpaque: visualPixels,
      widthPx: maskWidthPx,
      heightPx: maskHeightPx,
    );

    final visualMask = ElementCollisionPixelMask(
      widthPx: maskWidthPx,
      heightPx: maskHeightPx,
      dataBase64: ElementCollisionMaskCodec.encodePackedBits(
        widthPx: maskWidthPx,
        heightPx: maskHeightPx,
        solidPixels: visualPixels,
      ),
    );
    final collisionMask = ElementCollisionPixelMask(
      widthPx: maskWidthPx,
      heightPx: maskHeightPx,
      dataBase64: ElementCollisionMaskCodec.encodePackedBits(
        widthPx: maskWidthPx,
        heightPx: maskHeightPx,
        solidPixels: derived.collision,
      ),
    );
    final occlusionMask = ElementCollisionPixelMask(
      widthPx: maskWidthPx,
      heightPx: maskHeightPx,
      dataBase64: ElementCollisionMaskCodec.encodePackedBits(
        widthPx: maskWidthPx,
        heightPx: maskHeightPx,
        solidPixels: derived.occlusion,
      ),
    );
    final cells = ElementCollisionMaskCodec.cellsFromPixelMask(
      mask: collisionMask,
      tileWidth: tileWidth,
      tileHeight: tileHeight,
      sourceWidthInTiles: source.width,
      sourceHeightInTiles: source.height,
    );

    return ElementCollisionProfile(
      source: ElementCollisionProfileSource.generated,
      visualMask: visualMask,
      collisionMask: collisionMask,
      occlusionMask: occlusionMask,
      padding: padding,
      cells: cells,
    );
  }
}
```

### packages/map_editor/lib/src/application/collision_generation/placed_element_collision_params.dart

```dart
/// Paramètres d’auto-génération des masques collision.
///
/// Le générateur part de l’occupation visuelle alpha, puis applique les
/// heuristiques V1 pour dériver `collisionMask` et `occlusionMask`.
/// `cells` reste une projection de compatibilité du `collisionMask`, pas une
/// source de vérité séparée.
class PlacedElementCollisionGenerationParams {
  const PlacedElementCollisionGenerationParams({
    this.alphaThreshold = kCollisionAlphaOpaqueThreshold,
  });

  /// Pixels avec `alpha <= alphaThreshold` sont transparents pour le masque.
  final int alphaThreshold;

  static const PlacedElementCollisionGenerationParams defaults =
      PlacedElementCollisionGenerationParams();
}

/// Seuil alpha : au-dessus = pixel visible pour l’analyse automatique.
const int kCollisionAlphaOpaqueThreshold = 24;
```

### packages/map_editor/lib/src/application/collision_generation/placed_element_mask_heuristics_v1.dart

```dart
import 'dart:math' as math;

/// Heuristiques **V1** pour dériver collision et occlusion à partir du masque
/// visuel (pixels opaques).
///
/// ## Problème résolu
/// L’ancien pipeline copiait `visual = opaque` → `collision`, donc **ombres** et
/// **décors hauts** devenaient des murs. Ici on **sépare** explicitement :
/// - **visuel** : matière affichée (référence, éditeur) ;
/// - **collision** : sous-ensemble du visuel, **sans** bande d’ombre basse ;
/// - **occlusion** : sous-ensemble du visuel (bande haute du « volume ») pour
///   le rendu « passer derrière », **sans** influencer la collision.
///
/// ## Limites (honnêtes)
/// - Sans ML : on ne « comprend » pas une scène ; on applique des règles
///   géométriques sur le bbox des pixels opaques.
/// - Les assets très atypiques devront être **corrigés à la main** dans l’éditeur.
/// - L’occlusion auto est une **approximation** (bande haute du bbox) : le
///   runtime peut l’affiner plus tard (split dynamique).
class PlacedElementMaskHeuristicsV1 {
  PlacedElementMaskHeuristicsV1._();

  /// Fraction de la hauteur du bbox (depuis le haut) considérée comme zone
  /// d’occlusion « toit / couronne » (à recouvrir quand le joueur est derrière).
  static const double occlusionBandTopFraction = 0.38;

  /// Hauteur minimale de bande d’ombre basse : fraction du bbox (depuis le bas).
  static const double shadowBandMaxFraction = 0.22;

  /// Une ligne est candidate « ombre » si sa densité d’opacité est inférieure à
  /// ce ratio par rapport à la ligne la plus dense du bbox.
  static const double shadowDensityRatioVsMaxRow = 0.48;

  // ---------------------------------------------------------------------------
  // Entrée / sortie
  // ---------------------------------------------------------------------------

  /// [visualOpaque] : `true` = pixel opaque (alpha > seuil), repère local
  /// `(widthPx, heightPx)`, index `y * widthPx + x`.
  ///
  /// Retourne trois listes booléennes **même taille** : collision et occlusion
  /// sont des sous-ensembles du visuel (pas des pixels hors sprite).
  static MaskTriple deriveFromVisualOccupancy({
    required List<bool> visualOpaque,
    required int widthPx,
    required int heightPx,
  }) {
    if (widthPx <= 0 ||
        heightPx <= 0 ||
        visualOpaque.length != widthPx * heightPx) {
      return MaskTriple(
        collision: List<bool>.from(visualOpaque),
        occlusion: List<bool>.filled(widthPx * heightPx, false),
      );
    }

    final bbox = _boundingBoxOfOpaque(visualOpaque, widthPx, heightPx);
    if (bbox == null) {
      return MaskTriple(
        collision: List<bool>.filled(visualOpaque.length, false),
        occlusion: List<bool>.filled(visualOpaque.length, false),
      );
    }

    final shadowRows = _inferShadowRowsFromVisualDensity(
      visualOpaque,
      widthPx,
      heightPx,
      bbox,
    );

    final collision = List<bool>.filled(visualOpaque.length, false);
    final occlusion = List<bool>.filled(visualOpaque.length, false);

    final occTopY =
        bbox.minY + (bbox.height * occlusionBandTopFraction).floor();
    for (var y = bbox.minY; y <= bbox.maxY; y++) {
      for (var x = bbox.minX; x <= bbox.maxX; x++) {
        final i = y * widthPx + x;
        if (i < 0 || i >= visualOpaque.length) {
          continue;
        }
        if (!visualOpaque[i]) {
          continue;
        }
        final inShadow = shadowRows[y];
        if (!inShadow) {
          collision[i] = true;
        }
        if (y < occTopY) {
          occlusion[i] = true;
        }
      }
    }

    return MaskTriple(collision: collision, occlusion: occlusion);
  }

  static _BBox? _boundingBoxOfOpaque(
    List<bool> visual,
    int widthPx,
    int heightPx,
  ) {
    var minX = widthPx;
    var minY = heightPx;
    var maxX = -1;
    var maxY = -1;
    for (var y = 0; y < heightPx; y++) {
      for (var x = 0; x < widthPx; x++) {
        if (!visual[y * widthPx + x]) {
          continue;
        }
        minX = math.min(minX, x);
        minY = math.min(minY, y);
        maxX = math.max(maxX, x);
        maxY = math.max(maxY, y);
      }
    }
    if (maxX < minX || maxY < minY) {
      return null;
    }
    return _BBox(minX: minX, minY: minY, maxX: maxX, maxY: maxY);
  }

  /// Infère les lignes d’ombre comme une **bande basse** du bbox : on part du
  /// bas et on remonte tant que la ligne est « moins pleine » que le maximum
  /// (typique ombre projetée semi-transparente agrégée en bool).
  static List<bool> _inferShadowRowsFromVisualDensity(
    List<bool> visual,
    int widthPx,
    int heightPx,
    _BBox bbox,
  ) {
    final shadowRows = List<bool>.filled(heightPx, false);
    final rowCounts = List<int>.filled(heightPx, 0);
    var maxCount = 0;
    for (var y = bbox.minY; y <= bbox.maxY; y++) {
      var c = 0;
      for (var x = bbox.minX; x <= bbox.maxX; x++) {
        if (visual[y * widthPx + x]) {
          c++;
        }
      }
      rowCounts[y] = c;
      maxCount = math.max(maxCount, c);
    }
    if (maxCount <= 0) {
      return shadowRows;
    }

    final threshold =
        math.max(1, (maxCount * shadowDensityRatioVsMaxRow).ceil());
    final maxShadowRows = math.max(
        1, ((bbox.maxY - bbox.minY + 1) * shadowBandMaxFraction).ceil());

    var consecutive = 0;
    for (var y = bbox.maxY;
        y >= bbox.minY && consecutive < maxShadowRows;
        y--) {
      if (rowCounts[y] <= threshold && rowCounts[y] < maxCount) {
        shadowRows[y] = true;
        consecutive++;
      } else {
        // On arrête la remontée si on touche la « structure » dense (façade).
        break;
      }
    }
    return shadowRows;
  }
}

class MaskTriple {
  const MaskTriple({
    required this.collision,
    required this.occlusion,
  });

  /// Pixels bloquants gameplay (sans ombre basse heuristique).
  final List<bool> collision;

  /// Pixels qui participent à la couverture visuelle « devant / derrière ».
  final List<bool> occlusion;
}

class _BBox {
  const _BBox({
    required this.minX,
    required this.minY,
    required this.maxX,
    required this.maxY,
  });

  final int minX;
  final int minY;
  final int maxX;
  final int maxY;

  int get width => maxX - minX + 1;
  int get height => maxY - minY + 1;
}
```

### packages/map_editor/test/collision_generation/placed_element_auto_collision_copy_test.dart

```dart
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/application/collision_generation/placed_element_auto_collision_generator.dart';
import 'package:map_editor/src/application/collision_generation/placed_element_collision_params.dart';

void main() {
  group('PlacedElementAutoCollisionGenerator', () {
    test('creates visual collision and occlusion masks from alpha heuristics',
        () async {
      final dir = Directory.systemTemp.createTempSync('collision_generation_');
      addTearDown(() => dir.deleteSync(recursive: true));
      final imagePath = await _writePng(
        dir,
        width: 4,
        height: 4,
        opaquePixels: const [
          _P(0, 0),
          _P(1, 0),
          _P(2, 0),
          _P(3, 0),
          _P(0, 1),
          _P(1, 1),
          _P(2, 1),
          _P(3, 1),
          _P(0, 2),
          _P(1, 2),
          _P(2, 2),
          _P(3, 2),
          // Sparse bottom row: visual shadow only, not blocking collision.
          _P(0, 3),
        ],
      );

      final profile =
          await const PlacedElementAutoCollisionGenerator().generate(
        tilesetImagePath: imagePath,
        source: const TilesetSourceRect(x: 0, y: 0, width: 1, height: 1),
        tileWidth: 4,
        tileHeight: 4,
      );

      expect(profile.source, ElementCollisionProfileSource.generated);
      expect(profile.padding, const WarpTriggerPadding());
      expect(profile.visualMask, isNotNull);
      expect(profile.collisionMask, isNotNull);
      expect(profile.occlusionMask, isNotNull);

      final visual = _decode(profile.visualMask!);
      final collision = _decode(profile.collisionMask!);
      final occlusion = _decode(profile.occlusionMask!);

      expect(visual[_idx(0, 3, width: 4)], isTrue);
      expect(collision[_idx(0, 3, width: 4)], isFalse);
      expect(collision.where((solid) => solid), hasLength(12));
      expect(occlusion.where((solid) => solid), hasLength(4));
      expect(occlusion[_idx(0, 0, width: 4)], isTrue);
      expect(occlusion[_idx(0, 1, width: 4)], isFalse);
    });

    test('projects generated collisionMask into legacy cells', () async {
      final dir = Directory.systemTemp.createTempSync('collision_generation_');
      addTearDown(() => dir.deleteSync(recursive: true));
      final imagePath = await _writePng(
        dir,
        width: 4,
        height: 4,
        opaquePixels: {
          for (var y = 0; y < 4; y++)
            for (var x = 0; x < 4; x++) _P(x, y),
        },
      );

      final profile =
          await const PlacedElementAutoCollisionGenerator().generate(
        tilesetImagePath: imagePath,
        source: const TilesetSourceRect(x: 0, y: 0, width: 1, height: 1),
        tileWidth: 4,
        tileHeight: 4,
      );

      expect(profile.collisionMask, isNotNull);
      expect(
        profile.cells,
        ElementCollisionMaskCodec.cellsFromPixelMask(
          mask: profile.collisionMask!,
          tileWidth: 4,
          tileHeight: 4,
          sourceWidthInTiles: 1,
          sourceHeightInTiles: 1,
        ),
      );
      expect(profile.cells, const [GridPos(x: 0, y: 0)]);
    });

    test('respects padding before deriving masks from alpha', () async {
      final dir = Directory.systemTemp.createTempSync('collision_generation_');
      addTearDown(() => dir.deleteSync(recursive: true));
      final imagePath = await _writePng(
        dir,
        width: 4,
        height: 4,
        opaquePixels: {
          for (var y = 0; y < 4; y++)
            for (var x = 0; x < 4; x++) _P(x, y),
        },
      );

      final profile =
          await const PlacedElementAutoCollisionGenerator().generate(
        tilesetImagePath: imagePath,
        source: const TilesetSourceRect(x: 0, y: 0, width: 1, height: 1),
        tileWidth: 4,
        tileHeight: 4,
        padding: const WarpTriggerPadding(left: 1, right: 1, top: 1, bottom: 1),
      );

      final visual = _decode(profile.visualMask!);
      final collision = _decode(profile.collisionMask!);

      expect(visual[_idx(0, 0, width: 4)], isFalse);
      expect(visual[_idx(1, 1, width: 4)], isTrue);
      expect(collision[_idx(1, 1, width: 4)], isTrue);
      expect(collision[_idx(0, 0, width: 4)], isFalse);
    });

    test('documents alpha threshold as visual occupancy input', () {
      expect(
          PlacedElementCollisionGenerationParams.defaults.alphaThreshold, 24);
    });
  });
}

Future<String> _writePng(
  Directory dir, {
  required int width,
  required int height,
  required Iterable<_P> opaquePixels,
}) async {
  final recorder = ui.PictureRecorder();
  final canvas = ui.Canvas(recorder);
  final paint = ui.Paint()..color = const ui.Color(0xFFFFFFFF);
  for (final p in opaquePixels) {
    canvas.drawRect(
      ui.Rect.fromLTWH(p.x.toDouble(), p.y.toDouble(), 1, 1),
      paint,
    );
  }
  final image = await recorder.endRecording().toImage(width, height);
  final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
  if (bytes == null) {
    throw StateError('Unable to encode PNG test image');
  }
  final file = File('${dir.path}/tileset.png');
  await file.writeAsBytes(bytes.buffer.asUint8List(), flush: true);
  return file.path;
}

List<bool> _decode(ElementCollisionPixelMask mask) {
  return ElementCollisionMaskCodec.decodePackedBits(
    widthPx: mask.widthPx,
    heightPx: mask.heightPx,
    dataBase64: mask.dataBase64,
  );
}

int _idx(int x, int y, {required int width}) => y * width + x;

class _P {
  const _P(this.x, this.y);

  final int x;
  final int y;

  @override
  bool operator ==(Object other) => other is _P && other.x == x && other.y == y;

  @override
  int get hashCode => Object.hash(x, y);
}
```

### packages/map_editor/test/collision_generation/placed_element_mask_heuristics_v1_test.dart

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:map_editor/src/application/collision_generation/placed_element_mask_heuristics_v1.dart';

void main() {
  group('PlacedElementMaskHeuristicsV1', () {
    test('removes sparse bottom shadow rows from collision only', () {
      final visual = List<bool>.filled(4 * 4, false);
      for (var y = 0; y < 3; y++) {
        for (var x = 0; x < 4; x++) {
          visual[_idx(x, y)] = true;
        }
      }
      visual[_idx(0, 3)] = true;

      final derived = PlacedElementMaskHeuristicsV1.deriveFromVisualOccupancy(
        visualOpaque: visual,
        widthPx: 4,
        heightPx: 4,
      );

      expect(derived.collision[_idx(0, 3)], isFalse);
      expect(derived.collision.where((solid) => solid), hasLength(12));
      expect(derived.occlusion[_idx(0, 0)], isTrue);
      expect(derived.occlusion[_idx(0, 1)], isFalse);
    });

    test('empty visual occupancy creates no collision or occlusion', () {
      final derived = PlacedElementMaskHeuristicsV1.deriveFromVisualOccupancy(
        visualOpaque: List<bool>.filled(9, false),
        widthPx: 3,
        heightPx: 3,
      );

      expect(derived.collision.any((solid) => solid), isFalse);
      expect(derived.occlusion.any((solid) => solid), isFalse);
    });
  });
}

int _idx(int x, int y) => y * 4 + x;
```
