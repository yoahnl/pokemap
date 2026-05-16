# Collision Lot 14 — Static Placed Element Occlusion Patch Renderer V0

## 1. Résumé exécutif

Collision-14 ajoute le rendu runtime V0 des patches d'occlusion statiques dans `map_runtime`.

Le lot consomme les instructions pures créées par Collision-13 :

```text
StaticPlacedElementOcclusionPatchInstruction
+ RuntimeTilesetImage
→ PlacedElementOcclusionPatchComponent
→ montage dans PlayableMapGame
```

Le rendu reste strictement visuel :

```text
occlusionMask = rendu uniquement
collisionMask = gameplay
cells = projection / fallback / debug
```

Aucun fichier `map_core`, `map_editor`, `map_gameplay`, `map_battle`, `examples` ou generated n'a été modifié.

## 2. Git status initial

Commande :

```bash
git status --short --untracked-files=all
```

Sortie exacte :

```text
```

Le worktree était propre au début du lot.

Commit de départ :

```bash
git log -1 --oneline
```

Sortie utile :

```text
bbbe5a56 feat: add runtime occlusion patch resolver
```

## 3. Rapports précédents relus

Rapports relus :

```text
reports/collision/collision_lot_12_occlusion_runtime_decision.md
reports/collision/collision_lot_13_occlusion_runtime_patch_resolution.md
```

Décisions reprises :

```text
occlusionMask ne bloque jamais.
collisionMask reste la source gameplay fine.
cells reste une projection / fallback / debug.
Collision-13 produit les instructions runtime pures.
Les éléments animés sont ignorés en V0 par le resolver.
applyCollision=false ne doit pas empêcher l'occlusion.
RuntimeTilesetImage est la contrainte d'image côté runtime.
PlacedElementOcclusionPatchComponent existait mais utilisait ui.Image directement.
PlayableMapGame trie joueur / PNJ autour de 1000 + footY / depthSortY.
```

## 4. Audit ciblé du renderer runtime

Fichiers inspectés :

```text
packages/map_runtime/lib/src/presentation/flame/static_placed_element_occlusion_patch_resolution.dart
packages/map_runtime/lib/src/presentation/flame/placed_element_occlusion_patch_component.dart
packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart
packages/map_runtime/lib/src/presentation/flame/map_layers_component.dart
packages/map_runtime/lib/src/presentation/flame/runtime_map_game.dart
packages/map_runtime/lib/src/infrastructure/runtime_tileset_image.dart
packages/map_runtime/lib/src/application/runtime_map_bundle.dart
packages/map_runtime/test/static_placed_element_occlusion_patch_resolution_test.dart
packages/map_runtime/test/map_layers_component_placed_element_render_test.dart
packages/map_runtime/test/map_layers_component_render_pass_test.dart
packages/map_runtime/test/shadow/runtime_actor_contact_shadow_host_integration_test.dart
```

Commande de recherche :

```bash
rg -n "StaticPlacedElementOcclusionPatchInstruction|resolveStaticPlacedElementOcclusionPatchInstructions|PlacedElementOcclusionPatchComponent|RuntimeTilesetImage|drawImageRect|_mountLoadedMap|_repositionLoadedMap|_unmountLoadedMap|_LoadedPlayableMap|foregroundLayers|backgroundLayers|npcActors|priority|footPoint|depthSortY|tileImagesById|tilesetImagesById|MapLayersComponent" packages/map_runtime/lib packages/map_runtime/test
```

Constats principaux :

```text
RuntimeTilesetImage expose drawImageRect(Canvas, Rect sourceRect, Rect destinationRect, Paint).
MapLayersComponent utilise déjà RuntimeTilesetImage.drawImageRect.
PlayableMapGame monte les backgroundLayers à priorité 0.
PlayableMapGame monte les foregroundLayers à priorité 100000.
PlayableMapGame trie le joueur via 1000 + footPoint.y.
PlayableMapGame trie les PNJ via 1000 + actor.depthSortY.
_mountLoadedMap dispose déjà de bundle, originCellX/Y et tileImagesById.
_unmountLoadedMap retire déjà les layers et les PNJ.
_repositionLoadedMap repositionne déjà les layers et les PNJ.
_LoadedPlayableMap stockait bundle, origin, layers et PNJ, mais pas les patches d'occlusion.
```

Conclusion d'audit :

```text
Le chemin de moindre risque est d'adapter PlacedElementOcclusionPatchComponent pour consommer l'instruction Collision-13 et RuntimeTilesetImage, puis de monter ces composants dans PlayableMapGame sans toucher MapLayersComponent.
```

## 5. Design retenu

Design renderer :

```text
PlacedElementOcclusionPatchComponent reçoit :
- StaticPlacedElementOcclusionPatchInstruction ;
- RuntimeTilesetImage.

Le constructeur configure :
- position depuis instruction.worldLeft/worldTop ;
- size depuis instruction.visualWidth/visualHeight ;
- priority depuis instruction.flamePriority.

Le composant pré-calcule des runs horizontaux de pixels true du occlusionMask.
render(...) dessine uniquement ces runs avec RuntimeTilesetImage.drawImageRect(...).
```

Design montage :

```text
PlayableMapGame._mountLoadedMap(...)
→ resolveStaticPlacedElementOcclusionPatchInstructions(...)
→ lookup RuntimeTilesetImage par instruction.tilesetId
→ création de PlacedElementOcclusionPatchComponent
→ world.add(patch)
→ stockage dans _LoadedPlayableMap.occlusionPatches
```

Lifecycle :

```text
_unmountLoadedMap(...) retire les patches.
_repositionLoadedMap(...) applique le delta d'origine aux patches.
```

## 6. Adaptation du composant d’occlusion

`PlacedElementOcclusionPatchComponent` ne dépend plus de `RuntimeMapBundle`, `MapPlacedElement`, `ProjectElementEntry` ou `ui.Image`.

Il consomme directement :

```dart
StaticPlacedElementOcclusionPatchInstruction instruction
RuntimeTilesetImage tilesetImage
```

Rendu :

```text
1. Decode occlusionMask.
2. Valide que les dimensions du mask correspondent au source rect.
3. Compresse les pixels actifs en runs horizontaux.
4. Dessine chaque run depuis le tileset vers la destination locale.
5. Ignore le rendu si opacity <= 0 ou si aucun run n'existe.
```

Choix V0 :

```text
Pas de saveLayer.
Pas de shader.
Pas de clipPath.
Pas de rendu de toute la bbox.
Pas de lecture collisionMask.
Pas de lecture cells.
Pas d'accès GameplayWorldState.
```

## 7. Montage dans PlayableMapGame

`PlayableMapGame._mountLoadedMap(...)` monte maintenant les patches d'occlusion après les couches background/foreground et avant les PNJ.

Règles :

```text
Si RuntimeTilesetImage est absent pour instruction.tilesetId, le patch est ignoré.
applyCollision=false n'empêche pas le montage, car cette règle est portée par le resolver Collision-13.
Les patches utilisent instruction.flamePriority.
Les patches sont stockés dans _LoadedPlayableMap.
```

Un hook de test a été ajouté :

```dart
@visibleForTesting
void debugUnmountLoadedMapForTest(String mapId)
```

Ce hook appelle `_unmountLoadedMap(mapId)` et permet de tester que les patches sont retirés.

## 8. Lifecycle mount / reposition / unmount

Mount :

```text
Les instructions sont résolues par map chargée avec son originCellX/Y.
Un patch est créé par instruction si l'image runtime du tileset existe.
```

Reposition :

```text
_repositionLoadedMap(...) calcule oldOriginPx puis originPx.
originDelta = originPx - oldOriginPx.
Chaque patch applique applyMapOriginDelta(originDelta).
La priorité est recalculée avec 1000 + instruction.depthSortY + delta.y.
```

Unmount :

```text
Chaque patch stocké dans _LoadedPlayableMap.occlusionPatches appelle removeFromParent().
```

## 9. Règles de priorité / depth sorting

Le resolver Collision-13 fournit :

```text
depthSortY = worldTop + visualHeight
flamePriority = 1000 + depthSortY.round()
```

Le composant applique :

```text
priority = instruction.flamePriority
```

Après reposition de map :

```text
priority = 1000 + instruction.depthSortY + originDelta.y
```

Ce choix maintient les patches dans la même zone de priorité que :

```text
joueur : 1000 + footPoint.y
PNJ : 1000 + actor.depthSortY
```

Les patches ne sont pas placés à `100000`, ce qui éviterait un foreground global permanent.

## 10. Fichiers créés

```text
packages/map_runtime/test/placed_element_occlusion_patch_component_test.dart
packages/map_runtime/test/playable_map_game_placed_element_occlusion_test.dart
reports/collision/collision_lot_14_static_occlusion_patch_renderer.md
```

## 11. Fichiers modifiés

```text
packages/map_runtime/lib/src/presentation/flame/placed_element_occlusion_patch_component.dart
packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart
```

## 12. Fichiers explicitement non modifiés

```text
packages/map_core/**
packages/map_editor/**
packages/map_gameplay/**
packages/map_battle/**
examples/**
packages/map_runtime/lib/src/presentation/flame/map_layers_component.dart
packages/map_runtime/lib/src/presentation/flame/runtime_map_game.dart
packages/map_runtime/lib/src/presentation/flame/player_component.dart
packages/map_runtime/lib/src/presentation/flame/overworld_actor_component.dart
packages/map_runtime/lib/src/application/load_runtime_map_bundle.dart
packages/map_runtime/lib/src/application/runtime_map_bundle.dart
packages/map_runtime/lib/src/presentation/flame/static_placed_element_occlusion_patch_resolution.dart
```

## 13. Tests ajoutés / modifiés

Tests créés :

```text
packages/map_runtime/test/placed_element_occlusion_patch_component_test.dart
packages/map_runtime/test/playable_map_game_placed_element_occlusion_test.dart
```

Tests couverts :

```text
PlacedElementOcclusionPatchComponent configure position, size et priority.
PlacedElementOcclusionPatchComponent dessine uniquement les pixels masqués.
PlacedElementOcclusionPatchComponent ne dessine rien avec opacity zero.
PlacedElementOcclusionPatchComponent produit zéro run avec un mask vide.
PlayableMapGame monte un patch statique avec occlusionMask.
PlayableMapGame ne monte pas de patch sans occlusionMask.
PlayableMapGame monte le patch même si applyCollision=false.
PlayableMapGame ignore le patch si RuntimeTilesetImage manque.
PlayableMapGame retire les patches à l'unmount.
```

## 14. Commandes lancées

Commandes d'audit et de validation :

```bash
git status --short --untracked-files=all
git log -1 --oneline
rg -n "StaticPlacedElementOcclusionPatchInstruction|resolveStaticPlacedElementOcclusionPatchInstructions|PlacedElementOcclusionPatchComponent|RuntimeTilesetImage|drawImageRect|_mountLoadedMap|_repositionLoadedMap|_unmountLoadedMap|_LoadedPlayableMap|foregroundLayers|backgroundLayers|npcActors|priority|footPoint|depthSortY|tileImagesById|tilesetImagesById|MapLayersComponent" packages/map_runtime/lib packages/map_runtime/test
cd packages/map_runtime && flutter test --no-pub --reporter compact test/static_placed_element_occlusion_patch_resolution_test.dart
cd packages/map_runtime && flutter test --no-pub --reporter expanded test/placed_element_occlusion_patch_component_test.dart
cd packages/map_runtime && flutter test --no-pub --reporter expanded test/playable_map_game_placed_element_occlusion_test.dart
dart format packages/map_runtime/lib/src/presentation/flame/placed_element_occlusion_patch_component.dart packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart packages/map_runtime/test/placed_element_occlusion_patch_component_test.dart packages/map_runtime/test/playable_map_game_placed_element_occlusion_test.dart
cd packages/map_runtime && flutter analyze lib/src/presentation/flame/placed_element_occlusion_patch_component.dart lib/src/presentation/flame/playable_map_game.dart test/placed_element_occlusion_patch_component_test.dart test/playable_map_game_placed_element_occlusion_test.dart
cd packages/map_runtime && flutter test --no-pub --reporter compact test/placed_element_occlusion_patch_component_test.dart test/playable_map_game_placed_element_occlusion_test.dart test/static_placed_element_occlusion_patch_resolution_test.dart test/map_layers_component_placed_element_render_test.dart test/map_layers_component_render_pass_test.dart test/load_runtime_map_bundle_collision_normalization_test.dart
cd packages/map_gameplay && flutter test --no-pub --reporter compact test/collision_building_golden_slice_test.dart
cd packages/map_runtime && flutter test --no-pub --reporter compact
git diff --name-only
git diff --stat
git status --short --untracked-files=all
```

## 15. Résultats des tests composant

Commande :

```bash
cd packages/map_runtime
flutter test --no-pub --reporter expanded test/placed_element_occlusion_patch_component_test.dart
```

Sortie utile exacte :

```text
00:00 +4: All tests passed!
```

## 16. Résultats des tests PlayableMapGame

Commande :

```bash
cd packages/map_runtime
flutter test --no-pub --reporter expanded test/playable_map_game_placed_element_occlusion_test.dart
```

Sortie utile exacte :

```text
00:00 +5: All tests passed!
```

## 17. Résultats des tests de non-régression

Baseline avant modification :

```bash
cd packages/map_runtime
flutter test --no-pub --reporter compact test/static_placed_element_occlusion_patch_resolution_test.dart
```

Sortie utile exacte :

```text
00:01 +12: All tests passed!
```

Tests groupés runtime :

```bash
cd packages/map_runtime
flutter test --no-pub --reporter compact test/placed_element_occlusion_patch_component_test.dart test/playable_map_game_placed_element_occlusion_test.dart test/static_placed_element_occlusion_patch_resolution_test.dart test/map_layers_component_placed_element_render_test.dart test/map_layers_component_render_pass_test.dart test/load_runtime_map_bundle_collision_normalization_test.dart
```

Sortie utile exacte :

```text
00:04 +25: All tests passed!
```

Garde-fou gameplay :

```bash
cd packages/map_gameplay
flutter test --no-pub --reporter compact test/collision_building_golden_slice_test.dart
```

Sortie utile exacte :

```text
00:00 +5: All tests passed!
```

Suite complète runtime :

```bash
cd packages/map_runtime
flutter test --no-pub --reporter compact
```

Sortie utile exacte :

```text
00:22 +1127: All tests passed!
```

## 18. Analyse statique / format

Commande format initiale :

```bash
dart format packages/map_runtime/lib/src/presentation/flame/placed_element_occlusion_patch_component.dart packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart packages/map_runtime/test/placed_element_occlusion_patch_component_test.dart packages/map_runtime/test/playable_map_game_placed_element_occlusion_test.dart
```

Sortie exacte :

```text
Formatted packages/map_runtime/test/playable_map_game_placed_element_occlusion_test.dart
Formatted 4 files (1 changed) in 0.06 seconds.
```

Commande format finale :

```bash
dart format packages/map_runtime/lib/src/presentation/flame/placed_element_occlusion_patch_component.dart packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart packages/map_runtime/test/placed_element_occlusion_patch_component_test.dart packages/map_runtime/test/playable_map_game_placed_element_occlusion_test.dart
```

Sortie exacte :

```text
Formatted 4 files (0 changed) in 0.06 seconds.
```

Analyse ciblée :

```bash
cd packages/map_runtime
flutter analyze lib/src/presentation/flame/placed_element_occlusion_patch_component.dart lib/src/presentation/flame/playable_map_game.dart test/placed_element_occlusion_patch_component_test.dart test/playable_map_game_placed_element_occlusion_test.dart
```

Sortie utile exacte :

```text
No issues found! (ran in 8.3s)
```

Note d'analyse :

```text
Une première analyse a signalé un import unnecessary dans placed_element_occlusion_patch_component.dart.
L'import a été retiré, puis l'analyse ciblée finale ci-dessus est passée sans issue.
```

## 19. Vérification du périmètre

Commande :

```bash
git diff --name-only
```

Sortie finale :

```text
packages/map_runtime/lib/src/presentation/flame/placed_element_occlusion_patch_component.dart
packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart
```

Fichiers créés non listés par `git diff --name-only` car non suivis :

```text
packages/map_runtime/test/placed_element_occlusion_patch_component_test.dart
packages/map_runtime/test/playable_map_game_placed_element_occlusion_test.dart
reports/collision/collision_lot_14_static_occlusion_patch_renderer.md
```

Inventaire complet du lot :

```text
Créés :
- packages/map_runtime/test/placed_element_occlusion_patch_component_test.dart
- packages/map_runtime/test/playable_map_game_placed_element_occlusion_test.dart
- reports/collision/collision_lot_14_static_occlusion_patch_renderer.md

Modifiés :
- packages/map_runtime/lib/src/presentation/flame/placed_element_occlusion_patch_component.dart
- packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart

Supprimés :
- Aucun

Generated :
- Aucun

Hors périmètre touché :
- Aucun
```

## 20. Git status final

Commande :

```bash
git status --short --untracked-files=all
```

Sortie exacte après création du rapport et vérifications finales :

```text
 M packages/map_runtime/lib/src/presentation/flame/placed_element_occlusion_patch_component.dart
 M packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart
?? packages/map_runtime/test/placed_element_occlusion_patch_component_test.dart
?? packages/map_runtime/test/playable_map_game_placed_element_occlusion_test.dart
?? reports/collision/collision_lot_14_static_occlusion_patch_renderer.md
```

## 21. git diff --stat

Commande :

```bash
git diff --stat
```

Sortie finale :

```text
 .../placed_element_occlusion_patch_component.dart  | 226 ++++++++++-----------
 .../src/presentation/flame/playable_map_game.dart  |  43 ++++
 2 files changed, 145 insertions(+), 124 deletions(-)
```

Note :

```text
Les fichiers créés non suivis ne sont pas inclus dans git diff --stat tant qu'ils ne sont pas indexés.
Ils sont listés dans l'inventaire complet du lot.
```

## 22. Risques / réserves

Risques bornés :

```text
Le rendu V0 est statique : les éléments animés restent ignorés par le resolver Collision-13.
Le rendu compresse en runs horizontaux, mais un mask complexe peut encore produire plusieurs draw calls.
Le lot ne contient pas encore de golden slice runtime bâtiment avec joueur devant/derrière.
Le lot ne teste pas de capture visuelle Flame complète.
Le lot ne conditionne pas l'occlusion par acteur : il s'appuie sur la priority Flame.
```

Impact :

```text
Ces limites correspondent au périmètre Collision-14.
Collision-15 doit prouver le cas bâtiment réel avec joueur, toit et collision gameplay inchangée.
```

## 23. Ce que ce lot prouve

```text
Le runtime peut créer un composant d'occlusion depuis une instruction Collision-13.
Le composant utilise RuntimeTilesetImage.
Le composant dessine uniquement les pixels/runs du occlusionMask.
Le composant respecte position, size, priority et opacity.
PlayableMapGame monte les patches d'occlusion statiques.
PlayableMapGame ignore les patches si le tileset runtime manque.
applyCollision=false n'empêche pas le montage du patch.
PlayableMapGame retire les patches à l'unmount.
La suite complète map_runtime reste verte.
Le garde-fou map_gameplay bâtiment reste vert.
```

## 24. Ce que ce lot ne prouve pas encore

```text
Il ne prouve pas encore une scène bâtiment complète avec joueur passant derrière un toit.
Il ne prouve pas encore le comportement visuel sur maps connectées via screenshot.
Il ne prouve pas encore les éléments animés.
Il ne prouve pas encore une optimisation renderer avancée.
Il ne modifie pas l'occlusion runtime pour devenir interactive ou conditionnelle par acteur.
```

## 25. Préparation de Collision-15

Lot recommandé :

```text
Collision-15 — Building Runtime Occlusion Golden Slice V0
```

Objectifs à couvrir :

```text
Bâtiment réel avec occlusionMask.
Joueur devant / derrière selon priority.
Toit redessiné au-dessus du joueur quand le joueur passe derrière.
collisionMask / cells gameplay inchangés.
GameplayWorldState toujours non modifié.
Test runtime ciblé ou screenshot robuste si l'infrastructure le permet.
```

## 26. Auto-review finale

Checklist :

```text
Ai-je limité le lot à map_runtime rendu/montage ? Oui.
Ai-je évité map_core ? Oui.
Ai-je évité map_editor ? Oui.
Ai-je évité map_gameplay production ? Oui.
Ai-je évité MapLayersComponent ? Oui.
Ai-je évité RuntimeMapGame ? Oui.
Ai-je utilisé RuntimeTilesetImage ? Oui.
Ai-je consommé les instructions Collision-13 ? Oui.
Ai-je respecté priority = instruction.flamePriority ? Oui.
Ai-je évité saveLayer/shader ? Oui.
Ai-je évité d'utiliser occlusionMask comme collision ? Oui.
Ai-je relancé les tests de non-régression ? Oui.
Ai-je documenté ce que Collision-15 devra prouver ? Oui.
```

## 27. Contenu complet des fichiers créés/modifiés

### Fichier créé — `packages/map_runtime/test/placed_element_occlusion_patch_component_test.dart`

```dart
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/src/infrastructure/runtime_tileset_image.dart';
import 'package:map_runtime/src/presentation/flame/placed_element_occlusion_patch_component.dart';
import 'package:map_runtime/src/presentation/flame/static_placed_element_occlusion_patch_resolution.dart';

import 'surface/surface_runtime_test_support.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PlacedElementOcclusionPatchComponent', () {
    test('configures position size and priority from instruction', () async {
      final component = PlacedElementOcclusionPatchComponent(
        instruction: _instruction(
          worldLeft: 12,
          worldTop: 24,
          visualWidth: 32,
          visualHeight: 16,
          flamePriority: 1040,
        ),
        tilesetImage: await _runtimeTilesetImage2x2(),
      );

      expect(component.position.x, 12);
      expect(component.position.y, 24);
      expect(component.size.x, 32);
      expect(component.size.y, 16);
      expect(component.priority, 1040);
    });

    test('renders only masked occlusion pixels', () async {
      final component = PlacedElementOcclusionPatchComponent(
        instruction: _instruction(
          mask: _mask(widthPx: 2, heightPx: 2, solidPixels: const {3}),
        ),
        tilesetImage: await _runtimeTilesetImage2x2(),
      );

      final image = await _render(component, width: 2, height: 2);

      expect(await pixelAt(image, 0, 0), rgba(0, 0, 0, 0));
      expect(await pixelAt(image, 1, 0), rgba(0, 0, 0, 0));
      expect(await pixelAt(image, 0, 1), rgba(0, 0, 0, 0));
      expect(await pixelAt(image, 1, 1), rgba(255, 255, 0, 255));
    });

    test('does not render when opacity is zero', () async {
      final component = PlacedElementOcclusionPatchComponent(
        instruction: _instruction(
          opacity: 0,
          mask: _mask(widthPx: 2, heightPx: 2, solidPixels: const {0, 3}),
        ),
        tilesetImage: await _runtimeTilesetImage2x2(),
      );

      final image = await _render(component, width: 2, height: 2);

      expect(await pixelAt(image, 0, 0), rgba(0, 0, 0, 0));
      expect(await pixelAt(image, 1, 1), rgba(0, 0, 0, 0));
    });

    test('empty decoded mask produces no draw runs', () async {
      final component = PlacedElementOcclusionPatchComponent(
        instruction: _instruction(
          mask: _mask(widthPx: 2, heightPx: 2, solidPixels: const {}),
        ),
        tilesetImage: await _runtimeTilesetImage2x2(),
      );

      expect(component.debugDrawRunCount, 0);
    });
  });
}

StaticPlacedElementOcclusionPatchInstruction _instruction({
  double worldLeft = 0,
  double worldTop = 0,
  double visualWidth = 2,
  double visualHeight = 2,
  double depthSortY = 2,
  int flamePriority = 1002,
  double opacity = 1,
  ElementCollisionPixelMask? mask,
}) {
  return StaticPlacedElementOcclusionPatchInstruction(
    mapId: 'map',
    placedElementId: 'placed',
    elementId: 'element',
    layerId: 'objects',
    tilesetId: 'entity',
    sourceLeftPx: 0,
    sourceTopPx: 0,
    sourceWidthPx: 2,
    sourceHeightPx: 2,
    worldLeft: worldLeft,
    worldTop: worldTop,
    visualWidth: visualWidth,
    visualHeight: visualHeight,
    depthSortY: depthSortY,
    flamePriority: flamePriority,
    opacity: opacity,
    occlusionMask: mask ?? _mask(widthPx: 2, heightPx: 2),
  );
}

ElementCollisionPixelMask _mask({
  required int widthPx,
  required int heightPx,
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

Future<RuntimeTilesetImage> _runtimeTilesetImage2x2() async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  canvas.drawRect(
    const Rect.fromLTWH(0, 0, 1, 1),
    Paint()..color = const Color(0xFFFF0000),
  );
  canvas.drawRect(
    const Rect.fromLTWH(1, 0, 1, 1),
    Paint()..color = const Color(0xFF00FF00),
  );
  canvas.drawRect(
    const Rect.fromLTWH(0, 1, 1, 1),
    Paint()..color = const Color(0xFF0000FF),
  );
  canvas.drawRect(
    const Rect.fromLTWH(1, 1, 1, 1),
    Paint()..color = const Color(0xFFFFFF00),
  );
  final image = await recorder.endRecording().toImage(2, 2);
  return RuntimeTilesetImage(
    images: [image],
    chunks: const [
      RuntimeTilesetChunk(top: 0, height: 2, width: 2),
    ],
    width: 2,
    height: 2,
  );
}

Future<ui.Image> _render(
  PlacedElementOcclusionPatchComponent component, {
  required int width,
  required int height,
}) {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  component.render(canvas);
  return recorder.endRecording().toImage(width, height);
}
```

### Fichier créé — `packages/map_runtime/test/playable_map_game_placed_element_occlusion_test.dart`

```dart
import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/src/application/runtime_map_bundle.dart';
import 'package:map_runtime/src/infrastructure/runtime_tileset_image.dart';
import 'package:map_runtime/src/presentation/flame/placed_element_occlusion_patch_component.dart';
import 'package:map_runtime/src/presentation/flame/playable_map_game.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PlayableMapGame placed element occlusion patches', () {
    test(
        'mounts static occlusion patches for placed elements with occlusionMask',
        () async {
      final game = _game(bundle: _bundle());

      await _load(game);

      final patches = _occlusionPatches(game);
      expect(patches, hasLength(1));
      expect(patches.single.priority, 1064);
      expect(patches.single.position.x, 32);
      expect(patches.single.position.y, 32);
    });

    test('does not mount occlusion patch when occlusionMask is absent',
        () async {
      final game = _game(
        bundle: _bundle(includeOcclusionMask: false),
      );

      await _load(game);

      expect(_occlusionPatches(game), isEmpty);
    });

    test('mounts occlusion patch even when applyCollision is false', () async {
      final game = _game(
        bundle: _bundle(applyCollision: false),
      );

      await _load(game);

      expect(_occlusionPatches(game), hasLength(1));
    });

    test('skips occlusion patch when RuntimeTilesetImage is missing', () async {
      final game = _game(
        bundle: _bundle(),
        includeElementTilesetImage: false,
      );

      await _load(game);

      expect(_occlusionPatches(game), isEmpty);
    });

    test('removes occlusion patches when loaded map is unmounted', () async {
      final game = _game(bundle: _bundle());
      await _load(game);

      expect(_occlusionPatches(game), hasLength(1));

      game.debugUnmountLoadedMapForTest('occlusion-map');
      game.update(0);

      expect(_occlusionPatches(game), isEmpty);
    });
  });
}

PlayableMapGame _game({
  required RuntimeMapBundle bundle,
  bool includeElementTilesetImage = true,
}) {
  return PlayableMapGame(
    bundle: bundle,
    projectFilePath: '/tmp/occlusion-project.json',
    runtimeTilesetImageLoader: (
      absolutePathByTilesetId, {
      transparentColorByTilesetId = const <String, TilesetTransparentColor>{},
    }) async {
      final out = <String, RuntimeTilesetImage>{};
      if (absolutePathByTilesetId.containsKey('player')) {
        out['player'] = await _runtimeTilesetImage(
          width: 16,
          height: 32,
          color: const Color(0xFF4070FF),
        );
      }
      if (includeElementTilesetImage &&
          absolutePathByTilesetId.containsKey('entity')) {
        out['entity'] = await _runtimeTilesetImage(
          width: 16,
          height: 16,
          color: const Color(0xFFFF0000),
        );
      }
      return out;
    },
  );
}

Future<void> _load(PlayableMapGame game) async {
  game.onGameResize(Vector2(128, 128));
  await game.onLoad();
  game.update(0);
}

List<PlacedElementOcclusionPatchComponent> _occlusionPatches(
  PlayableMapGame game,
) {
  return game.world.children
      .whereType<PlacedElementOcclusionPatchComponent>()
      .toList(growable: false);
}

RuntimeMapBundle _bundle({
  bool includeOcclusionMask = true,
  bool applyCollision = true,
}) {
  final occlusionMask = includeOcclusionMask ? _mask() : null;
  return RuntimeMapBundle(
    manifest: ProjectManifest(
      name: 'Playable Occlusion Test',
      maps: const <ProjectMapEntry>[],
      tilesets: const [
        ProjectTilesetEntry(
          id: 'player',
          name: 'Player',
          relativePath: 'tilesets/player.png',
        ),
        ProjectTilesetEntry(
          id: 'entity',
          name: 'Entity',
          relativePath: 'tilesets/entity.png',
        ),
      ],
      settings: const ProjectSettings(
        tileWidth: 16,
        tileHeight: 16,
        displayScale: 2,
        defaultPlayerCharacterId: 'player',
      ),
      characters: const [
        ProjectCharacterEntry(
          id: 'player',
          name: 'Player',
          tilesetId: 'player',
          frameWidth: 1,
          frameHeight: 2,
        ),
      ],
      elements: [
        ProjectElementEntry(
          id: 'house',
          name: 'House',
          tilesetId: 'entity',
          categoryId: 'buildings',
          frames: const [
            TilesetVisualFrame(source: TilesetSourceRect(x: 0, y: 0)),
          ],
          collisionProfile: occlusionMask == null
              ? null
              : ElementCollisionProfile(
                  source: ElementCollisionProfileSource.manual,
                  occlusionMask: occlusionMask,
                ),
        ),
      ],
      surfaceCatalog: ProjectSurfaceCatalog(),
    ),
    map: MapData(
      id: 'occlusion-map',
      name: 'Occlusion Map',
      size: const GridSize(width: 4, height: 4),
      layers: const [
        MapLayer.object(id: 'objects', name: 'Objects'),
      ],
      entities: const [
        MapEntity(
          id: 'spawn',
          name: 'Spawn',
          kind: MapEntityKind.spawn,
          pos: GridPos(x: 0, y: 0),
          blocksMovement: false,
          spawn: MapEntitySpawnData(
            role: EntitySpawnRole.playerStart,
            facing: EntityFacing.south,
          ),
        ),
      ],
      placedElements: [
        MapPlacedElement(
          id: 'house-1',
          layerId: 'objects',
          elementId: 'house',
          pos: const GridPos(x: 1, y: 1),
          applyCollision: applyCollision,
        ),
      ],
      mapMetadata: const MapMetadata(defaultSpawnId: 'spawn'),
    ),
    projectRootDirectory: '/tmp/occlusion-runtime-test',
    tilesetAbsolutePathsById: const {
      'player': '/tmp/player.png',
      'entity': '/tmp/entity.png',
    },
  );
}

ElementCollisionPixelMask _mask() {
  final bits = List<bool>.filled(16 * 16, false);
  bits[0] = true;
  return ElementCollisionPixelMask(
    widthPx: 16,
    heightPx: 16,
    dataBase64: ElementCollisionMaskCodec.encodePackedBits(
      widthPx: 16,
      heightPx: 16,
      solidPixels: bits,
    ),
  );
}

Future<RuntimeTilesetImage> _runtimeTilesetImage({
  required int width,
  required int height,
  required Color color,
}) async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  canvas.drawRect(
    Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()),
    Paint()..color = color,
  );
  final image = await recorder.endRecording().toImage(width, height);
  return RuntimeTilesetImage(
    images: [image],
    chunks: [
      RuntimeTilesetChunk(top: 0, height: height, width: width),
    ],
    width: width,
    height: height,
  );
}
```

### Diff complet — fichiers modifiés

```diff
diff --git a/packages/map_runtime/lib/src/presentation/flame/placed_element_occlusion_patch_component.dart b/packages/map_runtime/lib/src/presentation/flame/placed_element_occlusion_patch_component.dart
index 0edffd3f..7da9c572 100644
--- a/packages/map_runtime/lib/src/presentation/flame/placed_element_occlusion_patch_component.dart
+++ b/packages/map_runtime/lib/src/presentation/flame/placed_element_occlusion_patch_component.dart
@@ -1,151 +1,129 @@
-import 'dart:ui' as ui;
-
 import 'package:flame/components.dart';
 import 'package:flutter/material.dart';
 import 'package:map_core/map_core.dart';
 
-import '../../application/runtime_map_bundle.dart';
+import '../../infrastructure/runtime_tileset_image.dart';
+import 'static_placed_element_occlusion_patch_resolution.dart';
 
-/// Une **zone d’occlusion** (toit / couronne) pour **un** [MapPlacedElement] :
-/// redessine uniquement les pixels marqués dans [ElementCollisionProfile.occlusionMask]
-/// **par-dessus** le joueur lorsque la priorité Flame le permet.
-///
-/// ## Rôle produit
-/// - **Ne** gère **pas** la collision (voir masque collision / gameplay).
-/// - Sert uniquement à l’effet « passer derrière » la partie haute d’un bâtiment.
-///
-/// ## Priorité de dessin
-/// `priority ≈ 1000 + bas_du_sprite_en_pixels_monde` pour rester aligné avec
-/// [OverworldActorComponent.depthSortY] / le joueur (`1000 + footY`).
-///
-/// ## Limites (honnêtes)
-/// - La **base** du bâtiment reste peinte dans [MapLayersComponent] (priorité 0) :
-///   tant qu’on ne duplique pas le rendu « base » en couche Y-sortée, le joueur
-///   peut recouvrir la base quand il est au sud — comportement classique acceptable
-///   pour une première itération ; la suite est documentée dans le rapport produit.
 class PlacedElementOcclusionPatchComponent extends PositionComponent {
   PlacedElementOcclusionPatchComponent({
-    required this.bundle,
-    required this.instance,
-    required this.element,
-    required this.tileImage,
-    required Vector2 mapOriginPx,
-  }) : super(
+    required this.instruction,
+    required this.tilesetImage,
+  })  : _drawRuns = _buildDrawRuns(instruction),
+        super(
           anchor: Anchor.topLeft,
-          position: _computeTopLeft(
-            bundle: bundle,
-            instance: instance,
-            element: element,
-            mapOriginPx: mapOriginPx,
-          ),
-          size: _computeSize(
-            bundle: bundle,
-            element: element,
-          ),
+          position: Vector2(instruction.worldLeft, instruction.worldTop),
+          size: Vector2(instruction.visualWidth, instruction.visualHeight),
         ) {
-    final mask = element.collisionProfile?.occlusionMask;
-    final tw = bundle.manifest.settings.tileWidth;
-    final th = bundle.manifest.settings.tileHeight;
-    final ch = bundle.cellHeight;
-    if (mask != null && tw > 0 && th > 0) {
-      final sy = ch / th;
-      final bottomWorld =
-          mapOriginPx.y + instance.pos.y * ch + mask.heightPx * sy;
-      priority = (1000 + bottomWorld).round().clamp(0, 2000000);
-    } else {
-      priority = -1;
-    }
+    priority = instruction.flamePriority;
   }
 
-  final RuntimeMapBundle bundle;
-  final MapPlacedElement instance;
-  final ProjectElementEntry element;
-  final ui.Image tileImage;
+  final StaticPlacedElementOcclusionPatchInstruction instruction;
+  final RuntimeTilesetImage tilesetImage;
+  final List<_OcclusionPixelRun> _drawRuns;
 
-  static Vector2 _computeTopLeft({
-    required RuntimeMapBundle bundle,
-    required MapPlacedElement instance,
-    required ProjectElementEntry element,
-    required Vector2 mapOriginPx,
-  }) {
-    final cw = bundle.cellWidth;
-    final ch = bundle.cellHeight;
-    return Vector2(
-      mapOriginPx.x + instance.pos.x * cw,
-      mapOriginPx.y + instance.pos.y * ch,
-    );
-  }
+  @visibleForTesting
+  int get debugDrawRunCount => _drawRuns.length;
 
-  static Vector2 _computeSize({
-    required RuntimeMapBundle bundle,
-    required ProjectElementEntry element,
-  }) {
-    final mask = element.collisionProfile?.occlusionMask;
-    final tw = bundle.manifest.settings.tileWidth;
-    final th = bundle.manifest.settings.tileHeight;
-    final cw = bundle.cellWidth;
-    final ch = bundle.cellHeight;
-    if (mask == null || tw <= 0 || th <= 0) {
-      return Vector2.zero();
-    }
-    final sx = cw / tw;
-    final sy = ch / th;
-    return Vector2(mask.widthPx * sx, mask.heightPx * sy);
+  void applyMapOriginDelta(Vector2 delta) {
+    position = Vector2(
+      instruction.worldLeft + delta.x,
+      instruction.worldTop + delta.y,
+    );
+    priority = (1000 + instruction.depthSortY + delta.y).round();
   }
 
   @override
   void render(Canvas canvas) {
-    final profile = element.collisionProfile;
-    final mask = profile?.occlusionMask;
-    if (mask == null) {
+    if (instruction.opacity <= 0 || _drawRuns.isEmpty) {
       return;
     }
-    List<bool> pixels;
-    try {
-      pixels = ElementCollisionMaskCodec.decodePackedBits(
-        widthPx: mask.widthPx,
-        heightPx: mask.heightPx,
-        dataBase64: mask.dataBase64,
+    final paint = Paint()
+      ..isAntiAlias = false
+      ..filterQuality = FilterQuality.none;
+    if (instruction.opacity < 1) {
+      paint.color = Color.fromRGBO(255, 255, 255, instruction.opacity);
+    }
+
+    final scaleX = instruction.visualWidth / instruction.sourceWidthPx;
+    final scaleY = instruction.visualHeight / instruction.sourceHeightPx;
+    for (final run in _drawRuns) {
+      final src = Rect.fromLTWH(
+        (instruction.sourceLeftPx + run.x).toDouble(),
+        (instruction.sourceTopPx + run.y).toDouble(),
+        run.width.toDouble(),
+        1,
       );
-    } catch (_) {
-      return;
+      final dst = Rect.fromLTWH(
+        run.x * scaleX,
+        run.y * scaleY,
+        run.width * scaleX,
+        scaleY,
+      );
+      tilesetImage.drawImageRect(canvas, src, dst, paint);
     }
-    final frame = element.frames.primaryFrame;
-    final tw = bundle.manifest.settings.tileWidth;
-    final th = bundle.manifest.settings.tileHeight;
-    final cw = bundle.cellWidth;
-    final ch = bundle.cellHeight;
-    if (tw <= 0 || th <= 0) {
-      return;
+  }
+
+  static List<_OcclusionPixelRun> _buildDrawRuns(
+    StaticPlacedElementOcclusionPatchInstruction instruction,
+  ) {
+    final mask = instruction.occlusionMask;
+    if (mask.widthPx <= 0 ||
+        mask.heightPx <= 0 ||
+        instruction.sourceWidthPx <= 0 ||
+        instruction.sourceHeightPx <= 0 ||
+        instruction.visualWidth <= 0 ||
+        instruction.visualHeight <= 0 ||
+        mask.widthPx != instruction.sourceWidthPx ||
+        mask.heightPx != instruction.sourceHeightPx) {
+      return const [];
     }
-    final scaleX = cw / tw;
-    final scaleY = ch / th;
-    final srcLeft = frame.source.x * tw;
-    final srcTop = frame.source.y * th;
-    final paint = Paint()..filterQuality = FilterQuality.none;
-    for (var py = 0; py < mask.heightPx; py++) {
-      for (var px = 0; px < mask.widthPx; px++) {
-        final idx = py * mask.widthPx + px;
-        if (idx < 0 || idx >= pixels.length || !pixels[idx]) {
-          continue;
-        }
-        final ix = srcLeft + px;
-        final iy = srcTop + py;
-        if (ix < 0 ||
-            iy < 0 ||
-            ix >= tileImage.width ||
-            iy >= tileImage.height) {
-          continue;
+
+    final pixels = _decodeMask(mask);
+    if (pixels.isEmpty) {
+      return const [];
+    }
+
+    final runs = <_OcclusionPixelRun>[];
+    for (var y = 0; y < mask.heightPx; y++) {
+      int? runStart;
+      for (var x = 0; x <= mask.widthPx; x++) {
+        final isSolid = x < mask.widthPx && pixels[y * mask.widthPx + x];
+        if (isSolid && runStart == null) {
+          runStart = x;
+        } else if (!isSolid && runStart != null) {
+          runs.add(_OcclusionPixelRun(x: runStart, y: y, width: x - runStart));
+          runStart = null;
         }
-        final src = Rect.fromLTWH(ix.toDouble(), iy.toDouble(), 1, 1);
-        final dst = Rect.fromLTWH(
-          px * scaleX,
-          py * scaleY,
-          scaleX,
-          scaleY,
-        );
-        canvas.drawImageRect(tileImage, src, dst, paint);
       }
     }
+    return List<_OcclusionPixelRun>.unmodifiable(runs);
+  }
+
+  static List<bool> _decodeMask(ElementCollisionPixelMask mask) {
+    try {
+      return ElementCollisionMaskCodec.decodePackedBits(
+        widthPx: mask.widthPx,
+        heightPx: mask.heightPx,
+        dataBase64: mask.dataBase64,
+      );
+    } on FormatException {
+      return const [];
+    } on ArgumentError {
+      return const [];
+    }
   }
 }
+
+@immutable
+final class _OcclusionPixelRun {
+  const _OcclusionPixelRun({
+    required this.x,
+    required this.y,
+    required this.width,
+  });
+
+  final int x;
+  final int y;
+  final int width;
+}
diff --git a/packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart b/packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart
index 86e65ec0..776988e3 100644
--- a/packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart
+++ b/packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart
@@ -77,8 +77,10 @@ import 'dialogue_overlay_component.dart';
 import 'map_layers_component.dart';
 import 'overworld_actor_component.dart';
 import 'player_component.dart';
+import 'placed_element_occlusion_patch_component.dart';
 import 'runtime_battle_gender_overrides.dart';
 import 'runtime_trainer_battle_overrides.dart';
+import 'static_placed_element_occlusion_patch_resolution.dart';
 import 'warp_transition_overlay_component.dart';
 
 const double _kViewportTilesX = 15.0;
@@ -600,6 +602,11 @@ class PlayableMapGame extends FlameGame with KeyboardEvents {
   @visibleForTesting
   bool debugIsMapLoaded(String mapId) => _loadedMapsById.containsKey(mapId);
 
+  @visibleForTesting
+  void debugUnmountLoadedMapForTest(String mapId) {
+    _unmountLoadedMap(mapId);
+  }
+
   @visibleForTesting
   Vector2 debugWorldTopLeftForSpawnCell(GridPos cell) {
     return _worldTopLeftForPlayerSpawnCell(
@@ -5022,6 +5029,7 @@ class PlayableMapGame extends FlameGame with KeyboardEvents {
           originCellY: activeLoaded.originCellY,
           backgroundLayers: activeLoaded.backgroundLayers,
           foregroundLayers: activeLoaded.foregroundLayers,
+          occlusionPatches: activeLoaded.occlusionPatches,
           npcActors: activeLoaded.npcActors,
           npcActorByEntityId: activeLoaded.npcActorByEntityId,
         );
@@ -6460,6 +6468,9 @@ class PlayableMapGame extends FlameGame with KeyboardEvents {
     }
     loaded.backgroundLayers.removeFromParent();
     loaded.foregroundLayers.removeFromParent();
+    for (final patch in loaded.occlusionPatches) {
+      patch.removeFromParent();
+    }
     for (final actor in loaded.npcActors) {
       actor.removeFromParent();
       _npcActors.remove(actor);
@@ -6501,6 +6512,26 @@ class PlayableMapGame extends FlameGame with KeyboardEvents {
     foregroundLayers.priority = 100000;
     await world.add(foregroundLayers);
 
+    final occlusionPatches = <PlacedElementOcclusionPatchComponent>[];
+    final occlusionInstructions =
+        resolveStaticPlacedElementOcclusionPatchInstructions(
+      bundle: bundle,
+      originCellX: originCellX,
+      originCellY: originCellY,
+    );
+    for (final instruction in occlusionInstructions) {
+      final tilesetImage = tileImagesById[instruction.tilesetId];
+      if (tilesetImage == null) {
+        continue;
+      }
+      final patch = PlacedElementOcclusionPatchComponent(
+        instruction: instruction,
+        tilesetImage: tilesetImage,
+      );
+      occlusionPatches.add(patch);
+      await world.add(patch);
+    }
+
     final npcActors = <OverworldActorComponent>[];
     final npcActorByEntityId = <String, OverworldActorComponent>{};
     final charById = {for (final c in bundle.manifest.characters) c.id: c};
@@ -6551,6 +6582,7 @@ class PlayableMapGame extends FlameGame with KeyboardEvents {
       originCellY: originCellY,
       backgroundLayers: backgroundLayers,
       foregroundLayers: foregroundLayers,
+      occlusionPatches: occlusionPatches,
       npcActors: npcActors,
       npcActorByEntityId: npcActorByEntityId,
     );
@@ -6660,12 +6692,20 @@ class PlayableMapGame extends FlameGame with KeyboardEvents {
     required int originCellX,
     required int originCellY,
   }) {
+    final oldOriginPx = _originPixels(
+      originCellX: loaded.originCellX,
+      originCellY: loaded.originCellY,
+    );
     final originPx = _originPixels(
       originCellX: originCellX,
       originCellY: originCellY,
     );
+    final originDelta = originPx - oldOriginPx;
     loaded.backgroundLayers.position = originPx.clone();
     loaded.foregroundLayers.position = originPx.clone();
+    for (final patch in loaded.occlusionPatches) {
+      patch.applyMapOriginDelta(originDelta);
+    }
     for (final entity in loaded.bundle.map.entities) {
       if (entity.kind != MapEntityKind.npc) {
         continue;
@@ -6687,6 +6727,7 @@ class PlayableMapGame extends FlameGame with KeyboardEvents {
       originCellY: originCellY,
       backgroundLayers: loaded.backgroundLayers,
       foregroundLayers: loaded.foregroundLayers,
+      occlusionPatches: loaded.occlusionPatches,
       npcActors: loaded.npcActors,
       npcActorByEntityId: loaded.npcActorByEntityId,
     );
@@ -7639,6 +7680,7 @@ class _LoadedPlayableMap {
     required this.originCellY,
     required this.backgroundLayers,
     required this.foregroundLayers,
+    required this.occlusionPatches,
     required this.npcActors,
     required this.npcActorByEntityId,
   });
@@ -7648,6 +7690,7 @@ class _LoadedPlayableMap {
   final int originCellY;
   final MapLayersComponent backgroundLayers;
   final MapLayersComponent foregroundLayers;
+  final List<PlacedElementOcclusionPatchComponent> occlusionPatches;
   final List<OverworldActorComponent> npcActors;
   final Map<String, OverworldActorComponent> npcActorByEntityId;
 }
```

### Note sur le rapport lui-même

Le rapport courant n'embarque pas une copie récursive de son propre contenu dans cette section.
