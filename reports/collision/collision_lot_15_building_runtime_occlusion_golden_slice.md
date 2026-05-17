# Collision Lot 15 — Building Runtime Occlusion Golden Slice V0

## 1. Résumé exécutif

Collision-15 ajoute une golden slice runtime comportementale centrée sur un bâtiment 6 x 7 tiles.

Le lot prouve :

- un bâtiment `RuntimeMapBundle` avec `occlusionMask` crée un `PlacedElementOcclusionPatchComponent` via `PlayableMapGame` ;
- le patch de toit peut être rendu au-dessus d'un joueur quand sa priorité Flame est supérieure ;
- le joueur peut être rendu au-dessus du patch quand sa priorité Flame est supérieure ;
- les priorités suivent le contrat `1000 + depthSortY` pour le patch et `1000 + footPoint.y` pour le joueur ;
- le garde-fou gameplay bâtiment de Collision-10 reste vert.

Aucun fichier de production n'a été modifié.

## 2. Git status initial

Commande :

```bash
git status --short --untracked-files=all
```

Sortie exacte :

```text
```

Le worktree Collision était propre au démarrage du lot.

## 3. Rapports précédents relus

Rapports relus :

- `reports/collision/collision_lot_10_building_golden_slice.md`
- `reports/collision/collision_lot_12_occlusion_runtime_decision.md`
- `reports/collision/collision_lot_13_occlusion_runtime_patch_resolution.md`
- `reports/collision/collision_lot_14_static_occlusion_patch_renderer.md`
- `reports/collision/collision_lot_14bis_occlusion_patch_reposition_lifecycle.md`

Points repris :

- Collision-10 : bâtiment réaliste, toit passable, base bloquante côté gameplay.
- Collision-12 : `occlusionMask` est une donnée de rendu uniquement.
- Collision-13 : `resolveStaticPlacedElementOcclusionPatchInstructions(...)` produit des instructions pures.
- Collision-14 : `PlacedElementOcclusionPatchComponent` rend uniquement les pixels/runs de `occlusionMask`.
- Collision-14-bis : `translateByMapOriginDelta(...)` cumule correctement plusieurs repositionnements.

## 4. Audit ciblé runtime golden slice

Fichiers inspectés :

- `packages/map_runtime/lib/src/presentation/flame/placed_element_occlusion_patch_component.dart`
  - `PlacedElementOcclusionPatchComponent`
  - `debugDrawRunCount`
  - `translateByMapOriginDelta(Vector2 delta)`
  - conclusion : composant exploitable directement pour un test pixel robuste.
- `packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart`
  - `_mountLoadedMap(...)`
  - `_updateActorDepthOrdering()`
  - `debugUnmountLoadedMapForTest(...)`
  - `debugRepositionLoadedMapForTest(...)`
  - conclusion : `PlayableMapGame` monte les patches depuis le resolver et donne accès au joueur/runtime en test.
- `packages/map_runtime/lib/src/presentation/flame/static_placed_element_occlusion_patch_resolution.dart`
  - `StaticPlacedElementOcclusionPatchInstruction`
  - `resolveStaticPlacedElementOcclusionPatchInstructions(...)`
  - conclusion : la priorité patch est `1000 + depthSortY`.
- `packages/map_runtime/lib/src/presentation/flame/player_component.dart`
  - `footPoint`
  - conclusion : `PlayableMapGame._updateActorDepthOrdering()` définit la priorité joueur avec `1000 + footPoint.y.round()`.
- `packages/map_runtime/lib/src/infrastructure/runtime_tileset_image.dart`
  - `RuntimeTilesetImage.drawImageRect(...)`
  - conclusion : compatible avec le renderer de patch.
- `packages/map_runtime/test/placed_element_occlusion_patch_component_test.dart`
  - tests pixel/runs existants.
- `packages/map_runtime/test/playable_map_game_placed_element_occlusion_test.dart`
  - tests mount/unmount/reposition existants.
- `packages/map_gameplay/test/collision_building_golden_slice_test.dart`
  - garde-fou gameplay Collision-10.

Flame MCP :

- recherche `Flame component priority render order PositionComponent render` : aucun résultat ;
- recherche `Component priority Flame render tree priority` : aucun résultat ;
- recherche `priority` : résultat `flame > components > components`, section `Priority`, mais l'outil ne fournit pas le détail complet de la page.

Conclusion Flame utilisée :

- les détails documentaires récupérables étaient incomplets ;
- le test s'appuie donc sur le pattern local vérifié dans `PlayableMapGame` : priorité patch `1000 + depthSortY`, priorité joueur `1000 + footPoint.y`.

## 5. Stratégie de test retenue

Stratégie retenue : C — test priorité + test composant pixel + test `PlayableMapGame`.

Pourquoi :

- un rendu pixel complet de `PlayableMapGame` dépendrait de la caméra, du viewport, du sprite joueur et des transforms globales ;
- le composant réel `PlacedElementOcclusionPatchComponent` suffit à prouver le rendu pixel de `occlusionMask` ;
- `PlayableMapGame` est quand même utilisé pour prouver que la fixture bâtiment runtime monte réellement un patch d'occlusion.

Le test créé combine :

- deux tests pixel avec `PlacedElementOcclusionPatchComponent` et un composant joueur bleu minimal ;
- un test `PlayableMapGame` qui charge un bâtiment 6 x 7, monte le patch, vérifie les dimensions du mask, les runs, la priorité patch et la priorité joueur.

## 6. Fixture bâtiment runtime

Fixture :

- tile source : `16 px` ;
- bâtiment : `6 x 7 tiles` ;
- source pixels bâtiment : `96 x 112 px` ;
- `occlusionMask` : les `3` rangées hautes, soit `48 px` de hauteur ;
- `collisionMask` : les `2` rangées basses, soit une base gameplay séparée ;
- couleur patch/toit : `#FFD830` ;
- couleur joueur probe : `#2060FF`.

Dans le test `PlayableMapGame` :

- map : `building-runtime-map` ;
- élément : `blue-roof-house` ;
- instance : `blue-roof-house-1` ;
- layer : `buildings` ;
- player start : `(3, 5)`.

## 7. Cas joueur derrière

Test :

```text
building runtime occlusion draws roof patch above player when player is behind
```

Preuve :

- patch priority : `1112` ;
- player probe priority : `1088` ;
- assertion : `patch.priority > player.priority` ;
- pixel d'overlap `(44, 32)` : `rgba(255, 216, 48, 255)`.

Conclusion :

Quand le patch a une priorité supérieure, le toit est rendu au-dessus du joueur.

## 8. Cas joueur devant

Test :

```text
building runtime occlusion lets player render above roof patch when player is in front
```

Preuve :

- patch priority : `1112` ;
- player probe priority : `1128` ;
- assertion : `player.priority > patch.priority` ;
- pixel d'overlap `(44, 32)` : `rgba(32, 96, 255, 255)`.

Conclusion :

Quand le joueur a une priorité supérieure, le joueur est rendu au-dessus du toit.

## 9. Garde-fou gameplay

Commande :

```bash
cd packages/map_gameplay && flutter test --no-pub --reporter compact test/collision_building_golden_slice_test.dart
```

Sortie utile :

```text
00:00 +5: All tests passed!
```

Conclusion :

Le comportement Collision-10 reste vert :

- toit passable ;
- base bloquante ;
- legacy non normalisé sur-bloquant ;
- `collisionMask` prioritaire ;
- hitbox pieds cohérente.

## 10. Fichiers créés

- `packages/map_runtime/test/building_runtime_occlusion_golden_slice_test.dart`
- `reports/collision/collision_lot_15_building_runtime_occlusion_golden_slice.md`

## 11. Fichiers modifiés

Aucun.

## 12. Fichiers explicitement non modifiés

- `packages/map_runtime/lib/src/presentation/flame/map_layers_component.dart`
- `packages/map_runtime/lib/src/presentation/flame/placed_element_occlusion_patch_component.dart`
- `packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart`
- `packages/map_runtime/lib/src/presentation/flame/player_component.dart`
- `packages/map_runtime/lib/src/presentation/flame/overworld_actor_component.dart`
- `packages/map_runtime/lib/src/presentation/flame/runtime_map_game.dart`
- `packages/map_core/**`
- `packages/map_editor/**`
- `packages/map_gameplay/**`
- `packages/map_battle/**`
- `examples/**`
- fichiers generated

## 13. Tests ajoutés / modifiés

Ajout :

- `packages/map_runtime/test/building_runtime_occlusion_golden_slice_test.dart`

Tests ajoutés :

- `building runtime occlusion draws roof patch above player when player is behind`
- `building runtime occlusion lets player render above roof patch when player is in front`
- `PlayableMapGame mounts a building roof occlusion patch with actor depth priority`

Tests modifiés :

- Aucun.

## 14. Commandes lancées

Commandes lancées :

```bash
git status --short --untracked-files=all
```

```bash
cd packages/map_runtime && flutter test --no-pub --reporter compact test/playable_map_game_placed_element_occlusion_test.dart test/placed_element_occlusion_patch_component_test.dart test/static_placed_element_occlusion_patch_resolution_test.dart
```

```bash
cd packages/map_runtime && flutter test --no-pub --reporter expanded test/building_runtime_occlusion_golden_slice_test.dart
```

```bash
dart format packages/map_runtime/test/building_runtime_occlusion_golden_slice_test.dart
```

```bash
cd packages/map_runtime && flutter analyze test/building_runtime_occlusion_golden_slice_test.dart
```

```bash
cd packages/map_runtime && flutter test --no-pub --reporter compact test/building_runtime_occlusion_golden_slice_test.dart test/playable_map_game_placed_element_occlusion_test.dart test/placed_element_occlusion_patch_component_test.dart test/static_placed_element_occlusion_patch_resolution_test.dart
```

```bash
cd packages/map_runtime && flutter test --no-pub --reporter compact test/map_layers_component_placed_element_render_test.dart test/map_layers_component_render_pass_test.dart test/load_runtime_map_bundle_collision_normalization_test.dart
```

```bash
cd packages/map_gameplay && flutter test --no-pub --reporter compact test/collision_building_golden_slice_test.dart
```

```bash
cd packages/map_runtime && flutter test --no-pub --reporter compact
```

```bash
git diff --name-only
```

```bash
git diff --stat
```

## 15. Résultats des tests runtime

Baseline Collision-14/14-bis :

```bash
cd packages/map_runtime && flutter test --no-pub --reporter compact test/playable_map_game_placed_element_occlusion_test.dart test/placed_element_occlusion_patch_component_test.dart test/static_placed_element_occlusion_patch_resolution_test.dart
```

Sortie utile :

```text
00:02 +24: All tests passed!
```

Test Collision-15 seul :

```bash
cd packages/map_runtime && flutter test --no-pub --reporter expanded test/building_runtime_occlusion_golden_slice_test.dart
```

Sortie utile :

```text
00:00 +0: Building runtime occlusion golden slice building runtime occlusion draws roof patch above player when player is behind
00:00 +1: Building runtime occlusion golden slice building runtime occlusion lets player render above roof patch when player is in front
00:00 +2: Building runtime occlusion golden slice PlayableMapGame mounts a building roof occlusion patch with actor depth priority
[runtime] Map loaded: building-runtime-map, spawn at (3, 5)
00:00 +3: All tests passed!
```

Runtime occlusion groupé :

```bash
cd packages/map_runtime && flutter test --no-pub --reporter compact test/building_runtime_occlusion_golden_slice_test.dart test/playable_map_game_placed_element_occlusion_test.dart test/placed_element_occlusion_patch_component_test.dart test/static_placed_element_occlusion_patch_resolution_test.dart
```

Sortie utile :

```text
00:02 +27: All tests passed!
```

Runtime régression ciblée :

```bash
cd packages/map_runtime && flutter test --no-pub --reporter compact test/map_layers_component_placed_element_render_test.dart test/map_layers_component_render_pass_test.dart test/load_runtime_map_bundle_collision_normalization_test.dart
```

Sortie utile :

```text
00:01 +4: All tests passed!
```

Suite complète runtime :

```bash
cd packages/map_runtime && flutter test --no-pub --reporter compact
```

Sortie utile :

```text
00:25 +1133: All tests passed!
```

## 16. Résultats des tests gameplay

Garde-fou gameplay :

```bash
cd packages/map_gameplay && flutter test --no-pub --reporter compact test/collision_building_golden_slice_test.dart
```

Sortie utile :

```text
00:00 +5: All tests passed!
```

## 17. Analyse statique / format

Format :

```bash
dart format packages/map_runtime/test/building_runtime_occlusion_golden_slice_test.dart
```

Sortie utile finale :

```text
Formatted 1 file (0 changed) in 0.01 seconds.
```

Analyse initiale après création :

```text
2 issues found. (ran in 4.2s)
```

Issues :

- `prefer_const_constructors` sur `MapData`
- `prefer_const_constructors` sur `MapMetadata`

Correction :

- `MapData` rendu `const` ;
- les `const` internes redondants retirés après le diagnostic `unnecessary_const`.

Analyse finale :

```bash
cd packages/map_runtime && flutter analyze test/building_runtime_occlusion_golden_slice_test.dart
```

Sortie exacte utile :

```text
Analyzing building_runtime_occlusion_golden_slice_test.dart...
No issues found! (ran in 3.5s)
```

## 18. Vérification du périmètre

Commande :

```bash
git diff --name-only
```

Sortie exacte :

```text
```

Explication :

Les fichiers créés sont encore non suivis, donc `git diff --name-only` ne liste aucune ligne.

Commande :

```bash
git diff --stat
```

Sortie exacte :

```text
```

Explication :

Les fichiers créés sont encore non suivis, donc `git diff --stat` ne liste aucune ligne.

Inventaire complet :

- Créé : `packages/map_runtime/test/building_runtime_occlusion_golden_slice_test.dart`
- Créé : `reports/collision/collision_lot_15_building_runtime_occlusion_golden_slice.md`
- Modifié : Aucun
- Supprimé : Aucun
- Generated : Aucun
- Hors lot touché : Aucun

## 19. Git status final

Commande :

```bash
git status --short --untracked-files=all
```

Sortie attendue après création du rapport :

```text
?? packages/map_runtime/test/building_runtime_occlusion_golden_slice_test.dart
?? reports/collision/collision_lot_15_building_runtime_occlusion_golden_slice.md
```

## 20. git diff --stat

Commande :

```bash
git diff --stat
```

Sortie exacte :

```text
```

Explication :

Les deux fichiers Collision-15 sont non suivis à ce stade.

## 21. Risques / réserves

Réserves :

- le test pixel n'utilise pas un rendu caméra complet de `PlayableMapGame` ;
- le test pixel utilise un composant joueur minimal bleu pour isoler l'ordre de rendu par priorité ;
- les éléments animés restent hors périmètre ;
- les maps connectées sont couvertes par Collision-14-bis pour le repositionnement, pas par cette golden slice visuelle ;
- le test ne vérifie pas un screenshot Flutter complet.

Impact :

- faible risque produit pour V0, car le rendu pixel du patch réel et le montage `PlayableMapGame` sont testés séparément ;
- un futur lot visuel manuel ou golden screenshot pourrait vérifier caméra + player sprite complet si nécessaire.

## 22. Ce que cette golden slice prouve

Cette golden slice prouve :

- un bâtiment 6 x 7 avec `occlusionMask` monte un patch runtime ;
- le patch utilise les dimensions `96 x 112 px` du bâtiment ;
- le patch rend la zone de toit depuis `occlusionMask` ;
- le patch est dans l'ordre de priorité Flame via `instruction.flamePriority` ;
- le joueur participe au même modèle de profondeur via `1000 + footPoint.y.round()` ;
- le toit gagne visuellement quand sa priorité est supérieure ;
- le joueur gagne visuellement quand sa priorité est supérieure ;
- le garde-fou gameplay de Collision-10 reste vert.

## 23. Ce que cette golden slice ne prouve pas encore

Cette golden slice ne prouve pas :

- une golden screenshot complète avec caméra `PlayableMapGame` ;
- l'occlusion d'éléments animés ;
- l'occlusion sur plusieurs maps connectées avec pixel render complet ;
- la qualité visuelle avec vrais assets de production ;
- une optimisation de performance au-delà des runs horizontaux de Collision-14.

## 24. Recommandation après Collision-15

Recommandation :

- considérer l'occlusion runtime statique V0 comme validée côté tests ;
- faire ensuite un test manuel éditeur/runtime avec une vraie maison du projet ;
- si le rendu visuel réel est satisfaisant, fermer le chantier occlusion V0 ;
- si un problème caméra/sprite apparaît, ouvrir un lot ciblé :
  `Collision-16 — Runtime Occlusion Visual QA / Real Asset Smoke V0`.

## 25. Auto-review finale

Checklist :

- Ai-je prouvé le cas joueur derrière ? Oui.
- Ai-je prouvé le cas joueur devant ? Oui.
- Ai-je vérifié les priorités ? Oui.
- Ai-je évité de modifier le gameplay ? Oui.
- Ai-je évité map_core ? Oui.
- Ai-je évité map_editor ? Oui.
- Ai-je évité MapLayersComponent ? Oui.
- Ai-je évité RuntimeMapGame ? Oui.
- Ai-je relancé le garde-fou gameplay ? Oui.
- Ai-je documenté les limites ? Oui.

Auto-critique :

- le choix de ne pas faire un rendu pixel complet `PlayableMapGame` est volontaire et documenté ;
- la preuve est plus robuste techniquement, mais moins proche d'une capture finale complète ;
- le prochain risque produit est uniquement visuel/caméra avec vrais assets, pas data/gameplay.

## 26. Contenu complet des fichiers créés/modifiés

### `packages/map_runtime/test/building_runtime_occlusion_golden_slice_test.dart`

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
import 'package:map_runtime/src/presentation/flame/player_component.dart';
import 'package:map_runtime/src/presentation/flame/static_placed_element_occlusion_patch_resolution.dart';

import 'surface/surface_runtime_test_support.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Building runtime occlusion golden slice', () {
    test(
      'building runtime occlusion draws roof patch above player when player is behind',
      () async {
        final patch = PlacedElementOcclusionPatchComponent(
          instruction: _buildingRoofInstruction(flamePriority: 1112),
          tilesetImage: await _solidRuntimeTilesetImage(
            width: _buildingSourceWidthPx,
            height: _buildingSourceHeightPx,
            color: _roofColor,
          ),
        );
        final player = _PlayerProbeComponent(
          priority: 1088,
          position: Vector2(40, 24),
        );

        expect(patch.priority, greaterThan(player.priority));

        final image = await _renderByPriority(
          [player, patch],
          width: _buildingSourceWidthPx,
          height: _buildingSourceHeightPx,
        );

        expect(await pixelAt(image, 44, 32), rgba(255, 216, 48, 255));
      },
    );

    test(
      'building runtime occlusion lets player render above roof patch when player is in front',
      () async {
        final patch = PlacedElementOcclusionPatchComponent(
          instruction: _buildingRoofInstruction(flamePriority: 1112),
          tilesetImage: await _solidRuntimeTilesetImage(
            width: _buildingSourceWidthPx,
            height: _buildingSourceHeightPx,
            color: _roofColor,
          ),
        );
        final player = _PlayerProbeComponent(
          priority: 1128,
          position: Vector2(40, 24),
        );

        expect(player.priority, greaterThan(patch.priority));

        final image = await _renderByPriority(
          [patch, player],
          width: _buildingSourceWidthPx,
          height: _buildingSourceHeightPx,
        );

        expect(await pixelAt(image, 44, 32), rgba(32, 96, 255, 255));
      },
    );

    test(
      'PlayableMapGame mounts a building roof occlusion patch with actor depth priority',
      () async {
        final game = _game(bundle: _buildingBundle());

        await _load(game);

        final patches = _occlusionPatches(game);
        expect(patches, hasLength(1));

        final patch = patches.single;
        expect(patch.instruction.placedElementId, 'blue-roof-house-1');
        expect(patch.instruction.elementId, 'blue-roof-house');
        expect(patch.instruction.occlusionMask.widthPx, _buildingSourceWidthPx);
        expect(
          patch.instruction.occlusionMask.heightPx,
          _buildingSourceHeightPx,
        );
        expect(patch.debugDrawRunCount, _roofMaskHeightPx);
        expect(patch.priority, patch.instruction.flamePriority);
        expect(patch.priority, (1000 + patch.instruction.depthSortY).round());
        expect(
          patch.instruction.depthSortY,
          patch.position.y + patch.size.y,
        );

        final player = _players(game).single;
        expect(player.priority, 1000 + player.footPoint.y.round());
      },
    );
  });
}

const _tileSize = 16;
const _buildingSourceWidthTiles = 6;
const _buildingSourceHeightTiles = 7;
const _buildingSourceWidthPx = _buildingSourceWidthTiles * _tileSize;
const _buildingSourceHeightPx = _buildingSourceHeightTiles * _tileSize;
const _roofMaskHeightPx = 3 * _tileSize;
const _roofColor = Color(0xFFFFD830);
const _playerColor = Color(0xFF2060FF);

StaticPlacedElementOcclusionPatchInstruction _buildingRoofInstruction({
  required int flamePriority,
}) {
  return StaticPlacedElementOcclusionPatchInstruction(
    mapId: 'building-runtime-map',
    placedElementId: 'blue-roof-house-1',
    elementId: 'blue-roof-house',
    layerId: 'buildings',
    tilesetId: 'building',
    sourceLeftPx: 0,
    sourceTopPx: 0,
    sourceWidthPx: _buildingSourceWidthPx,
    sourceHeightPx: _buildingSourceHeightPx,
    worldLeft: 0,
    worldTop: 0,
    visualWidth: _buildingSourceWidthPx.toDouble(),
    visualHeight: _buildingSourceHeightPx.toDouble(),
    depthSortY: _buildingSourceHeightPx.toDouble(),
    flamePriority: flamePriority,
    opacity: 1,
    occlusionMask: _roofOcclusionMask(),
  );
}

Future<ui.Image> _renderByPriority(
  List<PositionComponent> components, {
  required int width,
  required int height,
}) {
  final ordered = [...components]
    ..sort((a, b) => a.priority.compareTo(b.priority));
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  for (final component in ordered) {
    canvas.save();
    canvas.translate(component.position.x, component.position.y);
    component.render(canvas);
    canvas.restore();
  }
  return recorder.endRecording().toImage(width, height);
}

class _PlayerProbeComponent extends PositionComponent {
  _PlayerProbeComponent({
    required int priority,
    required Vector2 position,
  }) : super(
          position: position,
          size: Vector2(12, 24),
        ) {
    this.priority = priority;
  }

  @override
  void render(Canvas canvas) {
    canvas.drawRect(
      size.toRect(),
      Paint()
        ..isAntiAlias = false
        ..color = _playerColor,
    );
  }
}

PlayableMapGame _game({
  required RuntimeMapBundle bundle,
}) {
  return PlayableMapGame(
    bundle: bundle,
    projectFilePath: '/tmp/building-runtime-occlusion-project.json',
    runtimeTilesetImageLoader: (
      absolutePathByTilesetId, {
      transparentColorByTilesetId = const <String, TilesetTransparentColor>{},
    }) async {
      final out = <String, RuntimeTilesetImage>{};
      if (absolutePathByTilesetId.containsKey('player')) {
        out['player'] = await _solidRuntimeTilesetImage(
          width: 16,
          height: 32,
          color: _playerColor,
        );
      }
      if (absolutePathByTilesetId.containsKey('building')) {
        out['building'] = await _solidRuntimeTilesetImage(
          width: _buildingSourceWidthPx,
          height: _buildingSourceHeightPx,
          color: _roofColor,
        );
      }
      return out;
    },
  );
}

Future<void> _load(PlayableMapGame game) async {
  game.onGameResize(Vector2(256, 256));
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

List<PlayerComponent> _players(PlayableMapGame game) {
  return game.world.children.whereType<PlayerComponent>().toList(
        growable: false,
      );
}

RuntimeMapBundle _buildingBundle() {
  final occlusionMask = _roofOcclusionMask();
  final collisionMask = _baseCollisionMask();
  return RuntimeMapBundle(
    manifest: ProjectManifest(
      name: 'Building Runtime Occlusion Golden Slice',
      maps: const <ProjectMapEntry>[],
      tilesets: const [
        ProjectTilesetEntry(
          id: 'player',
          name: 'Player',
          relativePath: 'tilesets/player.png',
        ),
        ProjectTilesetEntry(
          id: 'building',
          name: 'Building',
          relativePath: 'tilesets/building.png',
        ),
      ],
      settings: const ProjectSettings(
        tileWidth: _tileSize,
        tileHeight: _tileSize,
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
      elementCategories: const [
        ProjectElementCategory(id: 'buildings', name: 'Buildings'),
      ],
      elements: [
        ProjectElementEntry(
          id: 'blue-roof-house',
          name: 'Blue Roof House',
          tilesetId: 'building',
          categoryId: 'buildings',
          frames: const [
            TilesetVisualFrame(
              source: TilesetSourceRect(
                x: 0,
                y: 0,
                width: _buildingSourceWidthTiles,
                height: _buildingSourceHeightTiles,
              ),
            ),
          ],
          collisionProfile: ElementCollisionProfile(
            source: ElementCollisionProfileSource.manual,
            collisionMask: collisionMask,
            occlusionMask: occlusionMask,
          ),
        ),
      ],
      surfaceCatalog: ProjectSurfaceCatalog(),
    ),
    map: const MapData(
      id: 'building-runtime-map',
      name: 'Building Runtime Map',
      size: GridSize(width: 10, height: 10),
      layers: [
        MapLayer.object(id: 'buildings', name: 'Buildings'),
      ],
      entities: [
        MapEntity(
          id: 'player-start',
          name: 'Player Start',
          kind: MapEntityKind.spawn,
          pos: GridPos(x: 3, y: 5),
          blocksMovement: false,
          spawn: MapEntitySpawnData(
            role: EntitySpawnRole.playerStart,
            facing: EntityFacing.south,
          ),
        ),
      ],
      placedElements: [
        MapPlacedElement(
          id: 'blue-roof-house-1',
          layerId: 'buildings',
          elementId: 'blue-roof-house',
          pos: GridPos(x: 1, y: 1),
          applyCollision: true,
        ),
      ],
      mapMetadata: MapMetadata(defaultSpawnId: 'player-start'),
    ),
    projectRootDirectory: '/tmp/building-runtime-occlusion-test',
    tilesetAbsolutePathsById: const {
      'player': '/tmp/player.png',
      'building': '/tmp/building.png',
    },
  );
}

ElementCollisionPixelMask _roofOcclusionMask() {
  return _mask(
    widthPx: _buildingSourceWidthPx,
    heightPx: _buildingSourceHeightPx,
    isSolid: (_, y) => y < _roofMaskHeightPx,
  );
}

ElementCollisionPixelMask _baseCollisionMask() {
  return _mask(
    widthPx: _buildingSourceWidthPx,
    heightPx: _buildingSourceHeightPx,
    isSolid: (_, y) => y >= 5 * _tileSize,
  );
}

ElementCollisionPixelMask _mask({
  required int widthPx,
  required int heightPx,
  required bool Function(int x, int y) isSolid,
}) {
  final bits = List<bool>.filled(widthPx * heightPx, false);
  for (var y = 0; y < heightPx; y++) {
    for (var x = 0; x < widthPx; x++) {
      bits[y * widthPx + x] = isSolid(x, y);
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

Future<RuntimeTilesetImage> _solidRuntimeTilesetImage({
  required int width,
  required int height,
  required Color color,
}) async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  canvas.drawRect(
    Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()),
    Paint()
      ..isAntiAlias = false
      ..color = color,
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

### `reports/collision/collision_lot_15_building_runtime_occlusion_golden_slice.md`

Le rapport est ce fichier. Il n'est pas recopié récursivement dans lui-même.
