# Collision Lot 13 — Occlusion Runtime Patch Resolution Model V0

## 1. Résumé exécutif

Collision-13 ajoute une brique pure côté `map_runtime` pour résoudre les futurs patches d’occlusion statiques sans encore les rendre.

Le lot crée :

- un modèle `StaticPlacedElementOcclusionPatchInstruction` ;
- un resolver `resolveStaticPlacedElementOcclusionPatchInstructions(...)` ;
- une suite de tests ciblés couvrant l’éligibilité, les coordonnées monde, le `tilesetId`, les masks invalides/vides, les éléments animés V0 et le fait que `applyCollision=false` ne bloque pas l’occlusion.

Aucun composant Flame n’est monté. Aucun rendu Canvas n’est ajouté. `PlayableMapGame`, `MapLayersComponent`, `RuntimeMapGame`, `PlacedElementOcclusionPatchComponent`, `map_core`, `map_editor` et `map_gameplay` ne sont pas modifiés.

## 2. Git status initial

Commande lancée au début du lot dans le worktree actif :

```bash
git status --short --untracked-files=all
```

Sortie exacte :

```text
```

Le worktree Collision actif était propre au début du lot.

## 3. Rapports précédents relus

Rapports relus :

- `reports/collision/collision_lot_10_building_golden_slice.md`
- `reports/collision/collision_lot_10bis_fine_collision_mask_authoring_ui.md`
- `reports/collision/collision_lot_11_auto_generation_heuristics_alignment.md`
- `reports/collision/collision_lot_12_occlusion_runtime_decision.md`

Points repris explicitement :

- `occlusionMask` est une donnée de rendu uniquement et ne bloque jamais le joueur.
- `collisionMask` reste la vérité gameplay fine.
- `cells` reste projection/fallback/debug.
- `visualMask` reste aperçu/analyse.
- `ElementCollisionTripleMaskEditor` permet déjà d’éditer `occlusionMask`.
- La génération automatique produit déjà `occlusionMask` séparément.
- `PlacedElementOcclusionPatchComponent` existe mais n’est pas monté dans le runtime.
- `PlacedElementOcclusionPatchComponent` travaille avec `ui.Image`, alors que le rendu runtime actuel passe par `RuntimeTilesetImage`.
- Collision-12 recommande une résolution pure des instructions avant de brancher un renderer Flame.

## 4. Audit ciblé runtime

Fichiers inspectés :

- `packages/map_runtime/lib/src/application/runtime_map_bundle.dart`
- `packages/map_runtime/lib/src/application/load_runtime_map_bundle.dart`
- `packages/map_runtime/lib/src/infrastructure/runtime_tileset_image.dart`
- `packages/map_runtime/lib/src/presentation/flame/map_layers_component.dart`
- `packages/map_runtime/lib/src/presentation/flame/placed_element_occlusion_patch_component.dart`
- `packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart`
- `packages/map_runtime/lib/src/presentation/flame/runtime_map_game.dart`
- `packages/map_core/lib/src/models/project_manifest.dart`
- `packages/map_core/lib/src/models/map_data.dart`
- `packages/map_core/lib/src/models/element_collision_profile.dart`
- `packages/map_core/lib/src/operations/element_collision_mask_codec.dart`
- `packages/map_runtime/test/map_layers_component_placed_element_render_test.dart`
- `packages/map_runtime/test/map_layers_component_render_pass_test.dart`
- `packages/map_runtime/test/load_runtime_map_bundle_collision_normalization_test.dart`

Constats principaux :

- `RuntimeMapBundle` expose `manifest`, `map`, `projectRootDirectory`, `tilesetAbsolutePathsById`, `cellWidth` et `cellHeight`.
- `RuntimeMapBundle.cellWidth` et `RuntimeMapBundle.cellHeight` utilisent `tileWidth/tileHeight * displayScale`.
- `loadRuntimeMapBundle` normalise les profils collision au chargement, mais ne traite pas le rendu d’occlusion.
- `MapPlacedElement` expose `id`, `layerId`, `elementId`, `pos`, `applyCollision`, `opacity` et `animation`.
- `ProjectElementEntry` expose `tilesetId`, `frames` et `collisionProfile`.
- `TilesetVisualFrameListX.primaryFrame` retourne la première frame et lève si la liste est vide.
- `MapLayersComponent` résout le `tilesetId` avec priorité à `frame.tilesetId.trim()` puis fallback sur `entry.tilesetId.trim()`.
- `MapLayersComponent` dessine les éléments placés avec `instance.pos.x * bundle.cellWidth` et `instance.pos.y * bundle.cellHeight`.
- `PlayableMapGame` depth-sort les acteurs avec une priorité autour de `1000 + footPoint.y` / `1000 + actor.depthSortY`.
- `PlacedElementOcclusionPatchComponent` est un composant existant, non monté, qui rendrait des pixels masqués à partir d’une `ui.Image`.

Commande de recherche lancée :

```bash
rg -n "RuntimeMapBundle|MapPlacedElement|ProjectElementEntry|ProjectSettings|ProjectManifest|MapData|tilesetId|frames|primaryFrame|TilesetVisualFrame|TilesetSourceRect|MapPlacedElementAnimation|animation|opacity|occlusionMask|ElementCollisionPixelMask|RuntimeTilesetImage|MapLayerRenderPass|originCellX|originCellY|_originPixels|priority|depthSortY" packages/map_runtime packages/map_core
```

Classes/fonctions importantes trouvées :

- `RuntimeMapBundle`
- `loadRuntimeMapBundle`
- `RuntimeTilesetImage.drawImageRect`
- `MapLayersComponent._paintPlacedElementsForLayer`
- `PlacedElementOcclusionPatchComponent`
- `PlayableMapGame._updateActorDepthOrdering`
- `MapPlacedElement`
- `MapPlacedElementAnimation`
- `ProjectElementEntry`
- `TilesetVisualFrame`
- `TilesetVisualFrameListX.primaryFrame`
- `ElementCollisionMaskCodec.decodePackedBits`

## 5. Design retenu

Le resolver est placé dans :

```text
packages/map_runtime/lib/src/presentation/flame/static_placed_element_occlusion_patch_resolution.dart
```

Ce placement est volontairement proche de la future intégration Flame, mais le fichier ne crée aucun `Component`, n’importe pas Flame et ne rend rien.

Le resolver prend un `RuntimeMapBundle` et une origine de map en cellules :

```dart
resolveStaticPlacedElementOcclusionPatchInstructions({
  required RuntimeMapBundle bundle,
  required int originCellX,
  required int originCellY,
})
```

La sortie est une liste d’instructions pures. Collision-14 pourra consommer ces instructions pour créer un renderer ou des composants sans réauditer les règles d’éligibilité.

## 6. API ajoutée

API ajoutée :

```dart
final class StaticPlacedElementOcclusionPatchInstruction
```

```dart
List<StaticPlacedElementOcclusionPatchInstruction>
    resolveStaticPlacedElementOcclusionPatchInstructions({
  required RuntimeMapBundle bundle,
  required int originCellX,
  required int originCellY,
})
```

L’API reste interne au package, importable par les tests via `package:map_runtime/src/...`. Aucun export public dans `map_runtime.dart` n’a été ajouté.

## 7. Modèle d’instruction d’occlusion

Chaque instruction contient :

- `mapId`
- `placedElementId`
- `elementId`
- `layerId`
- `tilesetId`
- `sourceLeftPx`
- `sourceTopPx`
- `sourceWidthPx`
- `sourceHeightPx`
- `worldLeft`
- `worldTop`
- `visualWidth`
- `visualHeight`
- `depthSortY`
- `flamePriority`
- `opacity`
- `occlusionMask`

Ces champs suffisent pour préparer un futur rendu de patch :

- quelle map ;
- quelle instance ;
- quel élément projet ;
- quelle couche ;
- quel tileset ;
- quel rectangle source en pixels ;
- où placer le patch dans le monde ;
- quelle taille visuelle runtime ;
- quelle priorité de rendu proposer ;
- quelle opacité appliquer ;
- quel masque d’occlusion utiliser.

## 8. Règles d’éligibilité

Un `MapPlacedElement` produit une instruction si :

- `elementId` correspond à un `ProjectElementEntry` ;
- l’élément a exactement une frame en V0 ;
- l’instance n’a pas d’animation active ;
- `collisionProfile.occlusionMask` existe ;
- le mask est décodable ;
- le mask contient au moins un pixel actif ;
- les dimensions du mask correspondent au rectangle source visuel en pixels ;
- le `tilesetId` est résolu depuis la frame ou l’élément.

Le resolver ignore proprement :

- `elementId` inconnu ;
- profil sans `occlusionMask` ;
- `occlusionMask` vide ;
- payload base64 invalide ;
- frame source non positive ;
- dimensions mask/source incompatibles ;
- élément multi-frame ;
- instance animée en V0 ;
- `tilesetId` vide.

Point important validé par test :

```text
applyCollision=false n’empêche pas l’occlusion.
```

Un objet peut ne pas bloquer le joueur tout en devant passer visuellement devant lui.

## 9. Règles de coordonnées / priorité

Coordonnées monde :

```text
worldLeft = (originCellX + instance.pos.x) * bundle.cellWidth
worldTop = (originCellY + instance.pos.y) * bundle.cellHeight
```

Dimensions visuelles runtime :

```text
visualWidth = frame.source.width * bundle.cellWidth
visualHeight = frame.source.height * bundle.cellHeight
```

Rectangle source pixels :

```text
sourceLeftPx = frame.source.x * tileWidth
sourceTopPx = frame.source.y * tileHeight
sourceWidthPx = frame.source.width * tileWidth
sourceHeightPx = frame.source.height * tileHeight
```

Depth / priorité V0 :

```text
depthSortY = worldTop + visualHeight
flamePriority = 1000 + depthSortY.round()
```

Ce choix s’aligne avec le principe déjà présent dans `PlayableMapGame` autour de `1000 + footY/depthSortY`. Collision-14 pourra affiner l’ancre si le rendu réel demande une priorité plus subtile.

## 10. Fichiers créés

- `packages/map_runtime/lib/src/presentation/flame/static_placed_element_occlusion_patch_resolution.dart`
- `packages/map_runtime/test/static_placed_element_occlusion_patch_resolution_test.dart`
- `reports/collision/collision_lot_13_occlusion_runtime_patch_resolution.md`

## 11. Fichiers modifiés

Aucun fichier suivi existant n’a été modifié.

## 12. Fichiers explicitement non modifiés

Fichiers et zones explicitement non modifiés :

- `packages/map_core/**`
- `packages/map_editor/**`
- `packages/map_gameplay/**`
- `packages/map_battle/**`
- `examples/**`
- `packages/map_runtime/lib/map_runtime.dart`
- `packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart`
- `packages/map_runtime/lib/src/presentation/flame/runtime_map_game.dart`
- `packages/map_runtime/lib/src/presentation/flame/map_layers_component.dart`
- `packages/map_runtime/lib/src/presentation/flame/placed_element_occlusion_patch_component.dart`
- `packages/map_runtime/lib/src/presentation/flame/player_component.dart`
- `packages/map_runtime/lib/src/presentation/flame/overworld_actor_component.dart`
- `packages/map_runtime/lib/src/application/load_runtime_map_bundle.dart`
- fichiers generated
- assets

## 13. Tests ajoutés

Fichier ajouté :

```text
packages/map_runtime/test/static_placed_element_occlusion_patch_resolution_test.dart
```

Tests ajoutés :

- `resolves static placed element occlusion patch instruction`
- `applies connected map origin to world coordinates`
- `skips elements without occlusionMask`
- `skips empty occlusionMask`
- `skips placed elements with unknown elementId`
- `skips animated placed elements in V0`
- `skips multi-frame elements in V0`
- `resolves occlusion even when applyCollision is false`
- `uses frame tilesetId override before element tilesetId`
- `falls back to element tilesetId when frame tilesetId is empty`
- `skips occlusionMask with dimensions not matching visual source size`
- `skips invalid occlusionMask payloads`

## 14. Commandes lancées

Commandes d’audit et de validation lancées :

```bash
git status --short --untracked-files=all
```

```bash
cd packages/map_runtime
flutter test --no-pub --reporter compact test/map_layers_component_placed_element_render_test.dart test/map_layers_component_render_pass_test.dart test/load_runtime_map_bundle_collision_normalization_test.dart
```

```bash
rg -n "RuntimeMapBundle|MapPlacedElement|ProjectElementEntry|ProjectSettings|ProjectManifest|MapData|tilesetId|frames|primaryFrame|TilesetVisualFrame|TilesetSourceRect|MapPlacedElementAnimation|animation|opacity|occlusionMask|ElementCollisionPixelMask|RuntimeTilesetImage|MapLayerRenderPass|originCellX|originCellY|_originPixels|priority|depthSortY" packages/map_runtime packages/map_core
```

```bash
cd packages/map_runtime
flutter test --no-pub --reporter expanded test/static_placed_element_occlusion_patch_resolution_test.dart
```

```bash
dart format packages/map_runtime/lib/src/presentation/flame/static_placed_element_occlusion_patch_resolution.dart packages/map_runtime/test/static_placed_element_occlusion_patch_resolution_test.dart
```

```bash
cd packages/map_runtime
flutter analyze lib/src/presentation/flame/static_placed_element_occlusion_patch_resolution.dart test/static_placed_element_occlusion_patch_resolution_test.dart
```

```bash
cd packages/map_runtime
flutter test --no-pub --reporter compact test/static_placed_element_occlusion_patch_resolution_test.dart test/map_layers_component_placed_element_render_test.dart test/map_layers_component_render_pass_test.dart test/load_runtime_map_bundle_collision_normalization_test.dart
```

```bash
cd packages/map_runtime
flutter test --no-pub --reporter compact
```

```bash
git diff --name-only
```

```bash
git diff --stat
```

```bash
git status --short --untracked-files=all
```

## 15. Résultats des tests ciblés

Baseline avant modification :

```bash
cd packages/map_runtime
flutter test --no-pub --reporter compact test/map_layers_component_placed_element_render_test.dart test/map_layers_component_render_pass_test.dart test/load_runtime_map_bundle_collision_normalization_test.dart
```

Sortie utile :

```text
00:02 +4: All tests passed!
```

RED avant implémentation :

```bash
cd packages/map_runtime
flutter test --no-pub --reporter expanded test/static_placed_element_occlusion_patch_resolution_test.dart
```

Sortie utile :

```text
test/static_placed_element_occlusion_patch_resolution_test.dart:4:8: Error: Error when reading 'lib/src/presentation/flame/static_placed_element_occlusion_patch_resolution.dart': No such file or directory
import 'package:map_runtime/src/presentation/flame/static_placed_element_occlusion_patch_resolution.dart';
       ^
test/static_placed_element_occlusion_patch_resolution_test.dart:31:11: Error: Method not found: 'resolveStaticPlacedElementOcclusionPatchInstructions'.
          resolveStaticPlacedElementOcclusionPatchInstructions(
          ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
00:00 +0 -1: Some tests failed.
```

GREEN ciblé après implémentation :

```bash
cd packages/map_runtime
flutter test --no-pub --reporter expanded test/static_placed_element_occlusion_patch_resolution_test.dart
```

Sortie utile :

```text
00:00 +0: static placed element occlusion patch resolution resolves static placed element occlusion patch instruction
00:00 +1: static placed element occlusion patch resolution applies connected map origin to world coordinates
00:00 +2: static placed element occlusion patch resolution skips elements without occlusionMask
00:00 +3: static placed element occlusion patch resolution skips empty occlusionMask
00:00 +4: static placed element occlusion patch resolution skips placed elements with unknown elementId
00:00 +5: static placed element occlusion patch resolution skips animated placed elements in V0
00:00 +6: static placed element occlusion patch resolution skips multi-frame elements in V0
00:00 +7: static placed element occlusion patch resolution resolves occlusion even when applyCollision is false
00:00 +8: static placed element occlusion patch resolution uses frame tilesetId override before element tilesetId
00:00 +9: static placed element occlusion patch resolution falls back to element tilesetId when frame tilesetId is empty
00:00 +10: static placed element occlusion patch resolution skips occlusionMask with dimensions not matching visual source size
00:00 +11: static placed element occlusion patch resolution skips invalid occlusionMask payloads
00:00 +12: All tests passed!
```

Régression ciblée runtime :

```bash
cd packages/map_runtime
flutter test --no-pub --reporter compact test/static_placed_element_occlusion_patch_resolution_test.dart test/map_layers_component_placed_element_render_test.dart test/map_layers_component_render_pass_test.dart test/load_runtime_map_bundle_collision_normalization_test.dart
```

Sortie utile :

```text
00:02 +16: All tests passed!
```

Suite complète `map_runtime` :

```bash
cd packages/map_runtime
flutter test --no-pub --reporter compact
```

Sortie utile :

```text
00:28 +1118: All tests passed!
```

## 16. Analyse statique / format

Format :

```bash
dart format packages/map_runtime/lib/src/presentation/flame/static_placed_element_occlusion_patch_resolution.dart packages/map_runtime/test/static_placed_element_occlusion_patch_resolution_test.dart
```

Sortie exacte finale :

```text
Formatted 2 files (0 changed) in 0.01 seconds.
```

Une première passe de format après création avait formaté les deux fichiers :

```text
Formatted packages/map_runtime/lib/src/presentation/flame/static_placed_element_occlusion_patch_resolution.dart
Formatted packages/map_runtime/test/static_placed_element_occlusion_patch_resolution_test.dart
Formatted 2 files (2 changed) in 0.01 seconds.
```

Analyse ciblée :

```bash
cd packages/map_runtime
flutter analyze lib/src/presentation/flame/static_placed_element_occlusion_patch_resolution.dart test/static_placed_element_occlusion_patch_resolution_test.dart
```

Sortie finale :

```text
Analyzing 2 items...

No issues found! (ran in 1.4s)
```

Note d’auto-correction :

Une première analyse a signalé :

```text
warning • The operand can't be 'null', so the condition is always 'false' • lib/src/presentation/flame/static_placed_element_occlusion_patch_resolution.dart:108:13 • unnecessary_null_comparison

1 issue found. (ran in 2.1s)
```

Cause : `TilesetVisualFrameListX.primaryFrame` n’est pas nullable et lève si la liste est vide. Le resolver filtre déjà `element.frames.length != 1`, donc le guard `frame == null` était inutile. Correction appliquée : retrait du guard redondant.

## 17. Vérification du périmètre

Commande :

```bash
git diff --name-only
```

Sortie exacte :

```text
```

Commande :

```bash
git diff --stat
```

Sortie exacte :

```text
```

Explication : les fichiers du lot sont nouveaux et non suivis. `git diff` ne liste pas les fichiers non suivis. Le périmètre est donc vérifié par `git status --short --untracked-files=all`.

Fichiers présents dans le périmètre Collision-13 :

- `packages/map_runtime/lib/src/presentation/flame/static_placed_element_occlusion_patch_resolution.dart`
- `packages/map_runtime/test/static_placed_element_occlusion_patch_resolution_test.dart`
- `reports/collision/collision_lot_13_occlusion_runtime_patch_resolution.md`

Aucun fichier `map_core`, `map_editor`, `map_gameplay`, `map_battle`, `examples`, generated ou runtime Flame existant n’est modifié.

## 18. Git status final

Commande :

```bash
git status --short --untracked-files=all
```

Sortie exacte finale :

```text
?? packages/map_runtime/lib/src/presentation/flame/static_placed_element_occlusion_patch_resolution.dart
?? packages/map_runtime/test/static_placed_element_occlusion_patch_resolution_test.dart
?? reports/collision/collision_lot_13_occlusion_runtime_patch_resolution.md
```

## 19. git diff --stat

Commande :

```bash
git diff --stat
```

Sortie exacte :

```text
```

Les trois fichiers du lot sont non suivis, donc `git diff --stat` est vide tant qu’aucun `git add` n’est exécuté.

## 20. Risques / réserves

- Le resolver ne rend pas encore les patches. C’est volontaire : Collision-13 prépare les instructions uniquement.
- Les éléments animés et les éléments multi-frame sont ignorés en V0. Collision-14 ou Collision-15 devra décider comment gérer un `occlusionMask` par frame.
- Le guard dimensions exige que `occlusionMask.widthPx/heightPx` corresponde exactement au rectangle source primaire en pixels. Cela protège le futur renderer, mais peut ignorer des données incohérentes déjà présentes.
- `flamePriority = 1000 + depthSortY.round()` est une règle V0 alignée avec le tri acteur actuel. Elle pourra être affinée quand le renderer sera branché.
- Le resolver ne vérifie pas que `tilesetId` existe dans `bundle.manifest.tilesets` ou `tilesetAbsolutePathsById`; il se limite à produire une instruction pure avec l’identifiant résolu comme `MapLayersComponent`.

## 21. Préparation de Collision-14

Collision-14 pourra consommer :

```dart
resolveStaticPlacedElementOcclusionPatchInstructions(
  bundle: bundle,
  originCellX: originCellX,
  originCellY: originCellY,
)
```

Étapes recommandées pour Collision-14 :

- créer un renderer/composant qui consomme `StaticPlacedElementOcclusionPatchInstruction` ;
- décider si `PlacedElementOcclusionPatchComponent` est adapté ou doit être remplacé pour utiliser `RuntimeTilesetImage` ;
- monter les patches au-dessus des acteurs sans modifier `GameplayWorldState` ;
- tester qu’un patch d’occlusion apparaît au-dessus du joueur ;
- tester que `occlusionMask` ne bloque toujours pas le gameplay ;
- garder les éléments animés hors V0 ou ajouter une résolution par frame avec tests dédiés.

## 22. Auto-review finale

- Ai-je limité le lot à map_runtime résolution/tests ? Oui.
- Ai-je évité map_core ? Oui.
- Ai-je évité map_editor ? Oui.
- Ai-je évité map_gameplay ? Oui.
- Ai-je évité PlayableMapGame ? Oui.
- Ai-je évité MapLayersComponent ? Oui.
- Ai-je évité PlacedElementOcclusionPatchComponent ? Oui.
- Ai-je évité tout rendu Canvas ? Oui.
- Ai-je bien ignoré les éléments animés en V0 ? Oui, test `skips animated placed elements in V0`.
- Ai-je prouvé applyCollision=false compatible avec occlusion ? Oui, test `resolves occlusion even when applyCollision is false`.
- Ai-je pris en compte l’origine de map ? Oui, test `applies connected map origin to world coordinates`.
- Ai-je calculé une priorité cohérente avec le depth sorting existant ? Oui, `depthSortY = worldTop + visualHeight` et `flamePriority = 1000 + depthSortY.round()`.
- Ai-je documenté ce qui reste pour Collision-14 ? Oui.
- Ai-je lancé les tests ciblés ? Oui.
- Ai-je lancé la suite complète `map_runtime` ? Oui, `00:28 +1118: All tests passed!`.

## 23. Contenu complet des fichiers créés/modifiés

Le rapport lui-même n’est pas recopié récursivement dans cette section. Les deux fichiers Dart créés par le lot sont reproduits intégralement ci-dessous.

### `packages/map_runtime/lib/src/presentation/flame/static_placed_element_occlusion_patch_resolution.dart`

```dart
import 'package:map_core/map_core.dart';

import '../../application/runtime_map_bundle.dart';

final class StaticPlacedElementOcclusionPatchInstruction {
  const StaticPlacedElementOcclusionPatchInstruction({
    required this.mapId,
    required this.placedElementId,
    required this.elementId,
    required this.layerId,
    required this.tilesetId,
    required this.sourceLeftPx,
    required this.sourceTopPx,
    required this.sourceWidthPx,
    required this.sourceHeightPx,
    required this.worldLeft,
    required this.worldTop,
    required this.visualWidth,
    required this.visualHeight,
    required this.depthSortY,
    required this.flamePriority,
    required this.opacity,
    required this.occlusionMask,
  });

  final String mapId;
  final String placedElementId;
  final String elementId;
  final String layerId;
  final String tilesetId;
  final int sourceLeftPx;
  final int sourceTopPx;
  final int sourceWidthPx;
  final int sourceHeightPx;
  final double worldLeft;
  final double worldTop;
  final double visualWidth;
  final double visualHeight;
  final double depthSortY;
  final int flamePriority;
  final double opacity;
  final ElementCollisionPixelMask occlusionMask;
}

List<StaticPlacedElementOcclusionPatchInstruction>
    resolveStaticPlacedElementOcclusionPatchInstructions({
  required RuntimeMapBundle bundle,
  required int originCellX,
  required int originCellY,
}) {
  final settings = bundle.manifest.settings;
  final tileWidth = settings.tileWidth;
  final tileHeight = settings.tileHeight;
  if (tileWidth <= 0 ||
      tileHeight <= 0 ||
      bundle.cellWidth <= 0 ||
      bundle.cellHeight <= 0) {
    return const [];
  }

  final elementById = {
    for (final element in bundle.manifest.elements) element.id: element,
  };
  final instructions = <StaticPlacedElementOcclusionPatchInstruction>[];

  for (final instance in bundle.map.placedElements) {
    final element = elementById[instance.elementId];
    if (element == null) {
      continue;
    }

    final instruction = _resolveInstruction(
      bundle: bundle,
      instance: instance,
      element: element,
      originCellX: originCellX,
      originCellY: originCellY,
      tileWidth: tileWidth,
      tileHeight: tileHeight,
    );
    if (instruction != null) {
      instructions.add(instruction);
    }
  }

  return instructions;
}

StaticPlacedElementOcclusionPatchInstruction? _resolveInstruction({
  required RuntimeMapBundle bundle,
  required MapPlacedElement instance,
  required ProjectElementEntry element,
  required int originCellX,
  required int originCellY,
  required int tileWidth,
  required int tileHeight,
}) {
  if (_isAnimatedInV0(instance, element)) {
    return null;
  }

  final mask = element.collisionProfile?.occlusionMask;
  if (mask == null) {
    return null;
  }

  final frame = element.frames.primaryFrame;
  final source = frame.source;
  if (source.width <= 0 || source.height <= 0) {
    return null;
  }

  final sourceWidthPx = source.width * tileWidth;
  final sourceHeightPx = source.height * tileHeight;
  if (mask.widthPx != sourceWidthPx || mask.heightPx != sourceHeightPx) {
    return null;
  }

  if (!_maskHasAnySolidPixel(mask)) {
    return null;
  }

  final tilesetId = _resolveTilesetId(frame, element);
  if (tilesetId.isEmpty) {
    return null;
  }

  final worldLeft = (originCellX + instance.pos.x) * bundle.cellWidth;
  final worldTop = (originCellY + instance.pos.y) * bundle.cellHeight;
  final visualWidth = source.width * bundle.cellWidth;
  final visualHeight = source.height * bundle.cellHeight;
  final depthSortY = worldTop + visualHeight;

  return StaticPlacedElementOcclusionPatchInstruction(
    mapId: bundle.map.id,
    placedElementId: instance.id,
    elementId: instance.elementId,
    layerId: instance.layerId,
    tilesetId: tilesetId,
    sourceLeftPx: source.x * tileWidth,
    sourceTopPx: source.y * tileHeight,
    sourceWidthPx: sourceWidthPx,
    sourceHeightPx: sourceHeightPx,
    worldLeft: worldLeft,
    worldTop: worldTop,
    visualWidth: visualWidth,
    visualHeight: visualHeight,
    depthSortY: depthSortY,
    flamePriority: (1000 + depthSortY).round(),
    opacity: instance.opacity.clamp(0.0, 1.0).toDouble(),
    occlusionMask: mask,
  );
}

bool _isAnimatedInV0(
  MapPlacedElement instance,
  ProjectElementEntry element,
) {
  if (element.frames.length != 1) {
    return true;
  }
  final animation = instance.animation;
  if (animation == null || !animation.enabled) {
    return false;
  }
  return animation.mode != MapPlacedElementAnimationMode.none;
}

String _resolveTilesetId(
  TilesetVisualFrame frame,
  ProjectElementEntry element,
) {
  final frameTilesetId = frame.tilesetId.trim();
  if (frameTilesetId.isNotEmpty) {
    return frameTilesetId;
  }
  return element.tilesetId.trim();
}

bool _maskHasAnySolidPixel(ElementCollisionPixelMask mask) {
  try {
    final pixels = ElementCollisionMaskCodec.decodePackedBits(
      widthPx: mask.widthPx,
      heightPx: mask.heightPx,
      dataBase64: mask.dataBase64,
    );
    return pixels.any((pixel) => pixel);
  } on FormatException {
    return false;
  } on ArgumentError {
    return false;
  }
}
```

### `packages/map_runtime/test/static_placed_element_occlusion_patch_resolution_test.dart`

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/src/application/runtime_map_bundle.dart';
import 'package:map_runtime/src/presentation/flame/static_placed_element_occlusion_patch_resolution.dart';

void main() {
  group('static placed element occlusion patch resolution', () {
    test('resolves static placed element occlusion patch instruction', () {
      final mask = _mask(widthPx: 32, heightPx: 16, solidPixels: {0, 17});
      final bundle = _bundle(
        placedElements: [
          _placedElement(
            pos: const GridPos(x: 5, y: 7),
            opacity: 0.75,
          ),
        ],
        elements: [
          _projectElement(
            frames: const [
              TilesetVisualFrame(
                tilesetId: 'frame_tileset',
                source: TilesetSourceRect(x: 3, y: 4, width: 2, height: 1),
              ),
            ],
            occlusionMask: mask,
          ),
        ],
      );

      final instructions = resolveStaticPlacedElementOcclusionPatchInstructions(
        bundle: bundle,
        originCellX: 0,
        originCellY: 0,
      );

      expect(instructions, hasLength(1));
      final instruction = instructions.single;
      expect(instruction.mapId, 'map_1');
      expect(instruction.placedElementId, 'placed_1');
      expect(instruction.elementId, 'house');
      expect(instruction.layerId, 'decor');
      expect(instruction.tilesetId, 'frame_tileset');
      expect(instruction.sourceLeftPx, 48);
      expect(instruction.sourceTopPx, 64);
      expect(instruction.sourceWidthPx, 32);
      expect(instruction.sourceHeightPx, 16);
      expect(instruction.worldLeft, 80);
      expect(instruction.worldTop, 112);
      expect(instruction.visualWidth, 32);
      expect(instruction.visualHeight, 16);
      expect(instruction.depthSortY, 128);
      expect(instruction.flamePriority, 1128);
      expect(instruction.opacity, 0.75);
      expect(instruction.occlusionMask, same(mask));
    });

    test('applies connected map origin to world coordinates', () {
      final bundle = _bundle(
        placedElements: [
          _placedElement(pos: const GridPos(x: 2, y: 4)),
        ],
        elements: [
          _projectElement(
            frames: const [
              TilesetVisualFrame(
                source: TilesetSourceRect(x: 0, y: 0),
              ),
            ],
            occlusionMask: _mask(),
          ),
        ],
      );

      final instruction = resolveStaticPlacedElementOcclusionPatchInstructions(
        bundle: bundle,
        originCellX: 10,
        originCellY: -3,
      ).single;

      expect(instruction.worldLeft, 192);
      expect(instruction.worldTop, 16);
      expect(instruction.depthSortY, 32);
      expect(instruction.flamePriority, 1032);
    });

    test('skips elements without occlusionMask', () {
      final bundle = _bundle(
        placedElements: [_placedElement()],
        elements: [_projectElement()],
      );

      final instructions = resolveStaticPlacedElementOcclusionPatchInstructions(
        bundle: bundle,
        originCellX: 0,
        originCellY: 0,
      );

      expect(instructions, isEmpty);
    });

    test('skips empty occlusionMask', () {
      final bundle = _bundle(
        placedElements: [_placedElement()],
        elements: [
          _projectElement(
            occlusionMask: _mask(solidPixels: const {}),
          ),
        ],
      );

      final instructions = resolveStaticPlacedElementOcclusionPatchInstructions(
        bundle: bundle,
        originCellX: 0,
        originCellY: 0,
      );

      expect(instructions, isEmpty);
    });

    test('skips placed elements with unknown elementId', () {
      final bundle = _bundle(
        placedElements: [
          _placedElement(elementId: 'missing_element'),
        ],
        elements: [
          _projectElement(occlusionMask: _mask()),
        ],
      );

      final instructions = resolveStaticPlacedElementOcclusionPatchInstructions(
        bundle: bundle,
        originCellX: 0,
        originCellY: 0,
      );

      expect(instructions, isEmpty);
    });

    test('skips animated placed elements in V0', () {
      final bundle = _bundle(
        placedElements: [
          _placedElement(
            animation: const MapPlacedElementAnimation(
              enabled: true,
              mode: MapPlacedElementAnimationMode.loop,
            ),
          ),
        ],
        elements: [
          _projectElement(occlusionMask: _mask()),
        ],
      );

      final instructions = resolveStaticPlacedElementOcclusionPatchInstructions(
        bundle: bundle,
        originCellX: 0,
        originCellY: 0,
      );

      expect(instructions, isEmpty);
    });

    test('skips multi-frame elements in V0', () {
      final bundle = _bundle(
        placedElements: [_placedElement()],
        elements: [
          _projectElement(
            frames: const [
              TilesetVisualFrame(source: TilesetSourceRect(x: 0, y: 0)),
              TilesetVisualFrame(source: TilesetSourceRect(x: 1, y: 0)),
            ],
            occlusionMask: _mask(),
          ),
        ],
      );

      final instructions = resolveStaticPlacedElementOcclusionPatchInstructions(
        bundle: bundle,
        originCellX: 0,
        originCellY: 0,
      );

      expect(instructions, isEmpty);
    });

    test('resolves occlusion even when applyCollision is false', () {
      final bundle = _bundle(
        placedElements: [
          _placedElement(applyCollision: false),
        ],
        elements: [
          _projectElement(occlusionMask: _mask()),
        ],
      );

      final instructions = resolveStaticPlacedElementOcclusionPatchInstructions(
        bundle: bundle,
        originCellX: 0,
        originCellY: 0,
      );

      expect(instructions, hasLength(1));
    });

    test('uses frame tilesetId override before element tilesetId', () {
      final bundle = _bundle(
        placedElements: [_placedElement()],
        elements: [
          _projectElement(
            tilesetId: 'element_tileset',
            frames: const [
              TilesetVisualFrame(
                tilesetId: 'override_tileset',
                source: TilesetSourceRect(x: 0, y: 0),
              ),
            ],
            occlusionMask: _mask(),
          ),
        ],
      );

      final instruction = resolveStaticPlacedElementOcclusionPatchInstructions(
        bundle: bundle,
        originCellX: 0,
        originCellY: 0,
      ).single;

      expect(instruction.tilesetId, 'override_tileset');
    });

    test('falls back to element tilesetId when frame tilesetId is empty', () {
      final bundle = _bundle(
        placedElements: [_placedElement()],
        elements: [
          _projectElement(
            tilesetId: 'element_tileset',
            frames: const [
              TilesetVisualFrame(
                source: TilesetSourceRect(x: 0, y: 0),
              ),
            ],
            occlusionMask: _mask(),
          ),
        ],
      );

      final instruction = resolveStaticPlacedElementOcclusionPatchInstructions(
        bundle: bundle,
        originCellX: 0,
        originCellY: 0,
      ).single;

      expect(instruction.tilesetId, 'element_tileset');
    });

    test('skips occlusionMask with dimensions not matching visual source size',
        () {
      final bundle = _bundle(
        placedElements: [_placedElement()],
        elements: [
          _projectElement(
            frames: const [
              TilesetVisualFrame(
                source: TilesetSourceRect(x: 0, y: 0, width: 2, height: 1),
              ),
            ],
            occlusionMask: _mask(widthPx: 16, heightPx: 16),
          ),
        ],
      );

      final instructions = resolveStaticPlacedElementOcclusionPatchInstructions(
        bundle: bundle,
        originCellX: 0,
        originCellY: 0,
      );

      expect(instructions, isEmpty);
    });

    test('skips invalid occlusionMask payloads', () {
      final bundle = _bundle(
        placedElements: [_placedElement()],
        elements: [
          _projectElement(
            occlusionMask: const ElementCollisionPixelMask(
              widthPx: 16,
              heightPx: 16,
              dataBase64: 'not-valid-base64',
            ),
          ),
        ],
      );

      final instructions = resolveStaticPlacedElementOcclusionPatchInstructions(
        bundle: bundle,
        originCellX: 0,
        originCellY: 0,
      );

      expect(instructions, isEmpty);
    });
  });
}

RuntimeMapBundle _bundle({
  required List<MapPlacedElement> placedElements,
  required List<ProjectElementEntry> elements,
  ProjectSettings settings = const ProjectSettings(
    tileWidth: 16,
    tileHeight: 16,
    displayScale: 1,
  ),
}) {
  return RuntimeMapBundle(
    manifest: ProjectManifest(
      name: 'Occlusion Patch Test Project',
      surfaceCatalog: ProjectSurfaceCatalog(),
      maps: const [],
      tilesets: const [
        ProjectTilesetEntry(
          id: 'element_tileset',
          name: 'Element Tileset',
          relativePath: 'tilesets/elements.png',
        ),
        ProjectTilesetEntry(
          id: 'frame_tileset',
          name: 'Frame Tileset',
          relativePath: 'tilesets/frame.png',
        ),
        ProjectTilesetEntry(
          id: 'override_tileset',
          name: 'Override Tileset',
          relativePath: 'tilesets/override.png',
        ),
      ],
      settings: settings,
      elements: elements,
    ),
    map: MapData(
      id: 'map_1',
      name: 'Map 1',
      size: const GridSize(width: 20, height: 20),
      layers: const [],
      placedElements: placedElements,
    ),
    projectRootDirectory: '/tmp/occlusion_patch_test',
    tilesetAbsolutePathsById: const {},
  );
}

MapPlacedElement _placedElement({
  String id = 'placed_1',
  String layerId = 'decor',
  String elementId = 'house',
  GridPos pos = const GridPos(x: 0, y: 0),
  bool applyCollision = true,
  double opacity = 1,
  MapPlacedElementAnimation? animation,
}) {
  return MapPlacedElement(
    id: id,
    layerId: layerId,
    elementId: elementId,
    pos: pos,
    applyCollision: applyCollision,
    opacity: opacity,
    animation: animation,
  );
}

ProjectElementEntry _projectElement({
  String id = 'house',
  String tilesetId = 'element_tileset',
  List<TilesetVisualFrame> frames = const [
    TilesetVisualFrame(source: TilesetSourceRect(x: 0, y: 0)),
  ],
  ElementCollisionPixelMask? occlusionMask,
}) {
  return ProjectElementEntry(
    id: id,
    name: id,
    tilesetId: tilesetId,
    categoryId: 'buildings',
    frames: frames,
    collisionProfile: occlusionMask == null
        ? null
        : ElementCollisionProfile(
            source: ElementCollisionProfileSource.manual,
            occlusionMask: occlusionMask,
          ),
  );
}

ElementCollisionPixelMask _mask({
  int widthPx = 16,
  int heightPx = 16,
  Set<int> solidPixels = const {0},
}) {
  final bits = List<bool>.filled(widthPx * heightPx, false);
  for (final index in solidPixels) {
    if (index >= 0 && index < bits.length) {
      bits[index] = true;
    }
  }
  return ElementCollisionPixelMask(
    widthPx: widthPx,
    heightPx: heightPx,
    dataBase64: ElementCollisionMaskCodec.encodePackedBits(
      widthPx: widthPx,
      heightPx: heightPx,
      solidPixels: bits,
    ),
  );
}
```
