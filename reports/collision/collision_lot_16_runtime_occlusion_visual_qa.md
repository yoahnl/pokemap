# Collision Lot 16 — Runtime Occlusion Visual QA / Real Asset Smoke V0

## 1. Résumé exécutif

Collision-16 valide l'occlusion runtime statique V0 au niveau smoke visuel.

Le lot ajoute un test `PlayableMapGame` complet et léger :

- charge un bâtiment 6 x 7 avec `collisionMask` et `occlusionMask` ;
- charge un vrai `PlayerComponent` runtime ;
- monte un `PlacedElementOcclusionPatchComponent` ;
- vérifie les priorités patch/joueur ;
- appelle `PlayableMapGame.render(...)` dans un `PictureRecorder` ;
- vérifie que le rendu complet produit une image `256 x 192` sans exception.

Le lot ne modifie aucun fichier de production.

Décision QA :

- aucun vrai asset/projet maison avec `occlusionMask` prêt n'a été trouvé dans les fixtures inspectées ;
- le smoke automatisé retenu est donc une fixture synthétique réaliste, complétée par un protocole manuel précis pour vrais assets.

## 2. Git status initial

Commande :

```bash
git status --short --untracked-files=all
```

Sortie exacte au démarrage de Collision-16 :

```text
?? packages/map_runtime/test/building_runtime_occlusion_golden_slice_test.dart
?? reports/collision/collision_lot_15_building_runtime_occlusion_golden_slice.md
```

Ces fichiers proviennent de Collision-15 et sont hors lot Collision-16.

## 3. Rapports précédents relus

Rapports relus :

- `reports/collision/collision_lot_14_static_occlusion_patch_renderer.md`
- `reports/collision/collision_lot_14bis_occlusion_patch_reposition_lifecycle.md`
- `reports/collision/collision_lot_15_building_runtime_occlusion_golden_slice.md`
- `reports/collision/collision_lot_10_building_golden_slice.md`
- `reports/collision/collision_lot_12_occlusion_runtime_decision.md`
- `reports/collision/collision_lot_13_occlusion_runtime_patch_resolution.md`

Points repris :

- Collision-14 : le patch d'occlusion utilise `RuntimeTilesetImage` et rend les runs de `occlusionMask`.
- Collision-14-bis : le repositionnement successif est sécurisé.
- Collision-15 : le patch peut passer devant le joueur, et le joueur peut passer devant le patch selon priorité.
- Collision-15 ne prouve pas un rendu complet `PlayableMapGame` caméra/viewport.
- Collision-16 doit rapprocher la preuve du vrai runtime visuel.

## 4. Audit des assets / fixtures disponibles

Commande d'audit recommandée corrigée via script Node, pour éviter les problèmes d'échappement shell :

```text
find-like scan sur extensions png/json/tmx/tsx dans packages/examples/assets/test
```

Sortie utile :

```text
assetFileCount: 286
houseLikeCount: 4
runtimeTestCandidateCount: 22
```

Fichiers `house/maison/building/roof/toit` trouvés :

```text
./packages/map_core/test/element_collision_building_golden_slice_test.dart
./packages/map_editor/test/collision_building_golden_slice_test.dart
./packages/map_gameplay/test/collision_building_golden_slice_test.dart
./packages/map_runtime/test/building_runtime_occlusion_golden_slice_test.dart
```

Conclusion :

- aucun asset PNG maison explicite prêt pour un smoke réel n'a été trouvé ;
- aucune map fixture runtime prête avec maison + `occlusionMask` n'a été trouvée ;
- les occurrences maison exploitables sont des fixtures de tests Collision, pas un vrai projet runtime visuel.

Tests/runtime helpers disponibles :

```text
./packages/map_runtime/test/building_runtime_occlusion_golden_slice_test.dart
./packages/map_runtime/test/playable_map_game_placed_element_occlusion_test.dart
./packages/map_runtime/test/placed_element_occlusion_patch_component_test.dart
./packages/map_runtime/test/static_placed_element_occlusion_patch_resolution_test.dart
./packages/map_runtime/test/surface/surface_runtime_playable_host_smoke_test.dart
./packages/map_runtime/test/surface/surface_runtime_test_support.dart
```

## 5. Audit caméra / viewport / rendu PlayableMapGame

Fichiers inspectés :

- `packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart`
  - `PlayableMapGame extends FlameGame`
  - `onGameResize(Vector2 size)`
  - `debugCameraWorldTopLeft`
  - `debugPlayerScreenTopLeft`
  - `_updateActorDepthOrdering()`
- `packages/map_runtime/test/surface/surface_runtime_playable_host_smoke_test.dart`
  - smoke `PlayableMapGame starts and ticks`
  - smoke `RuntimeMapGame` avec `PictureRecorder`
- `packages/map_runtime/test/building_runtime_occlusion_golden_slice_test.dart`
  - preuve pixel composant + preuve montage `PlayableMapGame`.

Constats :

- `PlayableMapGame` peut être initialisé en test avec `onGameResize(...)`, `onLoad()`, `update(0)`.
- `PlayableMapGame.render(canvas)` peut être appelé dans un `PictureRecorder`.
- Le repo utilise déjà des renders déterministes de composants via `PictureRecorder`.
- Aucun test existant ne faisait encore un `PlayableMapGame.render(...)` pour l'occlusion bâtiment.

Flame MCP :

- recherche `FlameGame render camera viewport world render priority components` : aucun résultat ;
- recherche `camera viewport` : aucun résultat ;
- recherche `camera` : résultats génériques, pas de détail directement exploitable pour ce lot.

Décision :

- utiliser les patterns locaux testés ;
- éviter une assertion pixel caméra complète ;
- ajouter un smoke `PlayableMapGame.render(...)` sans exception.

## 6. Stratégie de validation retenue

Stratégie retenue : D — hybrid.

Contenu :

- conserver la preuve pixel/priorité de Collision-15 ;
- ajouter un smoke complet `PlayableMapGame.render(...)` avec bâtiment + joueur + patch ;
- fournir un protocole manuel QA pour vrais assets.

Pourquoi pas une assertion pixel `PlayableMapGame` complète :

- la caméra, le viewport, les transforms Flame et le sprite réel ajoutent une fragilité qui ne sert pas le contrat V0 ;
- Collision-15 couvre déjà le pixel overlap du patch réel ;
- Collision-16 ajoute le chaînon manquant : rendu complet du jeu sans exception avec patch + player + viewport.

## 7. Tests ajoutés / modifiés

Fichier créé :

- `packages/map_runtime/test/runtime_occlusion_visual_smoke_test.dart`

Test ajouté :

```text
playable runtime building occlusion smoke renders without exception
```

Ce test vérifie :

- `PlayableMapGame` charge la map ;
- un patch d'occlusion bâtiment est monté ;
- un joueur réel est monté ;
- les priorités patch/joueur suivent leurs contrats ;
- `PlayableMapGame.render(...)` produit une image sans exception.

Tests modifiés :

- Aucun.

## 8. Protocole manuel QA

### Préparation

1. Ouvrir l'éditeur.
2. Sélectionner une vraie maison ou un prop haut.
3. Ouvrir l'éditeur collision.
4. Passer en mode `Masque fin`.
5. Vérifier ou peindre :
   - `collisionMask` sur la base / murs bas ;
   - `occlusionMask` sur le toit / partie haute ;
   - ne pas utiliser `visualMask` comme collision.
6. Sauvegarder.
7. Rouvrir la maison.
8. Vérifier :
   - `Collision fine active` quand `collisionMask` existe ;
   - `occlusionMask` conservé ;
   - `Masque occlusion` décrit comme non bloquant.

### Runtime

1. Placer la maison sur une map de test.
2. Placer le spawn joueur devant ou proche de la maison.
3. Lancer le runtime.
4. Marcher derrière le toit.
5. Vérifier que le toit recouvre le joueur.
6. Marcher devant la maison.
7. Vérifier que le joueur passe devant le toit.
8. Essayer de traverser le toit visuel.
9. Vérifier que le toit ne bloque pas le déplacement.
10. Essayer de traverser la base / mur bas.
11. Vérifier que la base bloque selon `collisionMask` ou fallback `cells`.
12. Sauvegarder, fermer, recharger et relancer le runtime.
13. Vérifier que l'occlusion reste identique.

### Résultats attendus

- Le toit est visuellement au-dessus du joueur quand le joueur est derrière.
- Le joueur est visuellement au-dessus du toit quand le joueur est devant.
- Le toit ne bloque pas la marche.
- La base bloque la marche.
- Aucun patch d'occlusion ne reste affiché après changement/unload de map.
- Pas de flickering quand le joueur passe autour du seuil de profondeur.

## 9. Résultats attendus en manuel

Résultats attendus :

- `collisionMask` pilote uniquement la collision gameplay.
- `occlusionMask` pilote uniquement le rendu visuel devant/derrière.
- `visualMask` reste une aide d'analyse.
- Le joueur reste contrôlable normalement.
- La maison ne devient pas une bbox bloquante.
- Le patch d'occlusion reste aligné avec le sprite de maison.

## 10. Symptômes de bug à surveiller

Symptômes :

- toit toujours derrière le joueur ;
- toit toujours devant le joueur ;
- toit décalé horizontalement ou verticalement ;
- toit visible sur une autre map après unload ;
- flickering de priorité ;
- `occlusionMask` qui bloque le joueur ;
- `collisionMask` ignoré après ajout d'occlusion ;
- patch transparent ou opaque incorrect ;
- joueur invisible derrière toute la bbox au lieu du toit seulement ;
- rendu correct avant sauvegarde mais perdu après reload.

## 11. Fichiers créés

- `packages/map_runtime/test/runtime_occlusion_visual_smoke_test.dart`
- `reports/collision/collision_lot_16_runtime_occlusion_visual_qa.md`

## 12. Fichiers modifiés

Aucun.

## 13. Fichiers explicitement non modifiés

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

## 14. Commandes lancées

Commandes lancées :

```bash
git status --short --untracked-files=all
```

```bash
cd packages/map_runtime && flutter test --no-pub --reporter compact test/building_runtime_occlusion_golden_slice_test.dart test/playable_map_game_placed_element_occlusion_test.dart test/placed_element_occlusion_patch_component_test.dart test/static_placed_element_occlusion_patch_resolution_test.dart
```

```bash
cd packages/map_runtime && flutter test --no-pub --reporter expanded test/runtime_occlusion_visual_smoke_test.dart
```

```bash
dart format packages/map_runtime/test/runtime_occlusion_visual_smoke_test.dart
```

```bash
cd packages/map_runtime && flutter analyze test/runtime_occlusion_visual_smoke_test.dart
```

```bash
cd packages/map_runtime && flutter test --no-pub --reporter compact test/runtime_occlusion_visual_smoke_test.dart test/building_runtime_occlusion_golden_slice_test.dart test/playable_map_game_placed_element_occlusion_test.dart test/placed_element_occlusion_patch_component_test.dart test/static_placed_element_occlusion_patch_resolution_test.dart
```

```bash
cd packages/map_runtime && flutter test --no-pub --reporter compact test/map_layers_component_placed_element_render_test.dart test/map_layers_component_render_pass_test.dart test/load_runtime_map_bundle_collision_normalization_test.dart
```

```bash
cd packages/map_runtime && flutter test --no-pub --reporter compact
```

```bash
cd packages/map_gameplay && flutter test --no-pub --reporter compact test/collision_building_golden_slice_test.dart
```

```bash
git diff --name-only
```

```bash
git diff --stat
```

Commandes d'audit lancées avec Context Mode :

```text
audit assets/fixtures png/json/tmx/tsx
audit rg occlusionMask/collisionMask/PlayableMapGame/PictureRecorder/camera/viewport
```

Deux tentatives d'audit shell ont échoué à cause de parenthèses non échappées dans `find`. La cause était le parsing `/bin/sh`; l'audit a ensuite été relancé via parcours Node `fs.readdirSync`.

## 15. Résultats des tests runtime

Baseline Collision-15 / occlusion :

```bash
cd packages/map_runtime && flutter test --no-pub --reporter compact test/building_runtime_occlusion_golden_slice_test.dart test/playable_map_game_placed_element_occlusion_test.dart test/placed_element_occlusion_patch_component_test.dart test/static_placed_element_occlusion_patch_resolution_test.dart
```

Sortie utile :

```text
00:02 +27: All tests passed!
```

Smoke Collision-16 seul :

```bash
cd packages/map_runtime && flutter test --no-pub --reporter expanded test/runtime_occlusion_visual_smoke_test.dart
```

Sortie utile :

```text
00:00 +0: Runtime occlusion visual smoke playable runtime building occlusion smoke renders without exception
[runtime] Map loaded: runtime-occlusion-visual-smoke-map, spawn at (3, 5)
00:00 +1: All tests passed!
```

Runtime groupé Collision-16 :

```bash
cd packages/map_runtime && flutter test --no-pub --reporter compact test/runtime_occlusion_visual_smoke_test.dart test/building_runtime_occlusion_golden_slice_test.dart test/playable_map_game_placed_element_occlusion_test.dart test/placed_element_occlusion_patch_component_test.dart test/static_placed_element_occlusion_patch_resolution_test.dart
```

Sortie utile :

```text
00:02 +28: All tests passed!
```

Régressions runtime ciblées :

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
00:25 +1134: All tests passed!
```

## 16. Résultats du garde-fou gameplay

Commande :

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
dart format packages/map_runtime/test/runtime_occlusion_visual_smoke_test.dart
```

Sortie utile :

```text
Formatted packages/map_runtime/test/runtime_occlusion_visual_smoke_test.dart
Formatted 1 file (1 changed) in 0.01 seconds.
```

Analyse :

```bash
cd packages/map_runtime && flutter analyze test/runtime_occlusion_visual_smoke_test.dart
```

Sortie utile :

```text
Analyzing runtime_occlusion_visual_smoke_test.dart...
No issues found! (ran in 3.8s)
```

## 18. Vérification du périmètre

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

Explication :

Les fichiers Collision-15 et Collision-16 sont non suivis, donc `git diff --name-only` et `git diff --stat` ne listent aucune ligne.

Inventaire complet :

- Créé par Collision-16 : `packages/map_runtime/test/runtime_occlusion_visual_smoke_test.dart`
- Créé par Collision-16 : `reports/collision/collision_lot_16_runtime_occlusion_visual_qa.md`
- Préexistant hors Collision-16 : `packages/map_runtime/test/building_runtime_occlusion_golden_slice_test.dart`
- Préexistant hors Collision-16 : `reports/collision/collision_lot_15_building_runtime_occlusion_golden_slice.md`
- Modifié : Aucun
- Supprimé : Aucun
- Generated : Aucun

## 19. Git status final

Commande :

```bash
git status --short --untracked-files=all
```

Sortie exacte :

```text
?? packages/map_runtime/test/building_runtime_occlusion_golden_slice_test.dart
?? packages/map_runtime/test/runtime_occlusion_visual_smoke_test.dart
?? reports/collision/collision_lot_15_building_runtime_occlusion_golden_slice.md
?? reports/collision/collision_lot_16_runtime_occlusion_visual_qa.md
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

Les fichiers concernés sont non suivis.

## 21. Risques / réserves

Risques et réserves :

- aucun vrai asset maison avec `occlusionMask` prêt n'a été trouvé ;
- le smoke `PlayableMapGame` vérifie un rendu complet sans exception, mais pas un pixel caméra précis ;
- la validation finale sur vrais assets doit encore être faite manuellement ;
- les éléments animés restent hors V0 ;
- le comportement avec plusieurs maps connectées est couvert par lifecycle/reposition, mais pas par un rendu visuel manuel dans ce lot.

## 22. Ce que ce lot prouve

Ce lot prouve :

- `PlayableMapGame` peut charger une scène bâtiment + joueur + `occlusionMask` ;
- un patch d'occlusion statique est monté dans le monde runtime ;
- un vrai `PlayerComponent` est présent ;
- patch et joueur utilisent les priorités attendues ;
- `PlayableMapGame.render(...)` fonctionne dans un viewport de test avec le patch monté ;
- la suite runtime complète reste verte ;
- le garde-fou gameplay bâtiment reste vert.

## 23. Ce que ce lot ne prouve pas encore

Non vérifié.

**Sujet :**
Pixel exact de recouvrement toit/joueur dans un rendu complet `PlayableMapGame` avec caméra.

**Raison :**
Le test pixel complet serait plus fragile que la preuve composant de Collision-15, car il dépend du cadrage caméra, du viewport, du sprite joueur et des transforms Flame.

**Impact :**
Faible pour V0 automatisée, car Collision-15 teste déjà le pixel overlap du patch réel et Collision-16 teste maintenant le rendu complet sans exception.

**Comment vérifier ensuite :**
Faire le protocole manuel QA sur une vraie maison, puis ajouter un test pixel caméra seulement si un helper stable de capture runtime est extrait.

Non vérifié.

**Sujet :**
Vrai asset maison du projet avec masque occlusion persistant.

**Raison :**
L'audit n'a pas trouvé de fixture maison runtime prête avec asset réel et `occlusionMask`.

**Impact :**
La confiance technique est bonne, mais la validation produit finale dépend d'un essai manuel dans l'éditeur/runtime.

**Comment vérifier ensuite :**
Créer ou sélectionner une maison réelle dans l'éditeur, peindre `collisionMask` et `occlusionMask`, sauvegarder, lancer le runtime et suivre le protocole QA.

## 24. Recommandation finale

Recommandation :

- considérer l'occlusion runtime statique V0 comme techniquement validée ;
- effectuer maintenant le protocole manuel sur une vraie maison du projet ;
- si le protocole manuel est vert, clôturer le chantier Collision/Occlusion V0 ;
- si un écart visuel apparaît, ouvrir un micro-lot ciblé sur le symptôme observé.

## 25. Auto-review finale

Checklist :

- Ai-je audité les vrais assets / fixtures ? Oui.
- Ai-je évité map_core ? Oui.
- Ai-je évité map_editor ? Oui.
- Ai-je évité map_gameplay production ? Oui.
- Ai-je évité MapLayersComponent ? Oui.
- Ai-je évité RuntimeMapGame ? Oui.
- Ai-je évité les modèles / JSON ? Oui.
- Ai-je évité build_runner/generated ? Oui.
- Ai-je relancé les tests runtime ciblés ? Oui.
- Ai-je relancé le garde-fou gameplay ? Oui.
- Ai-je fourni un protocole manuel QA réellement utilisable ? Oui.
- Ai-je documenté les limites ? Oui.

Auto-critique :

- le test ajouté est un smoke robuste, pas une golden screenshot ;
- il augmente la confiance caméra/viewport en appelant `PlayableMapGame.render(...)`, mais il ne remplace pas une passe visuelle humaine sur vrais assets ;
- le bon prochain geste est manuel, pas une nouvelle couche de code.

## 26. Contenu complet des fichiers créés/modifiés

### `packages/map_runtime/test/runtime_occlusion_visual_smoke_test.dart`

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

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Runtime occlusion visual smoke', () {
    test('playable runtime building occlusion smoke renders without exception',
        () async {
      final game = PlayableMapGame(
        bundle: _bundle(),
        projectFilePath: '/tmp/runtime-occlusion-visual-smoke/project.json',
        runtimeTilesetImageLoader: _loadRuntimeImages,
      );

      game.onGameResize(Vector2(256, 192));
      await game.onLoad();
      game.update(0);

      final patches = game.world.children
          .whereType<PlacedElementOcclusionPatchComponent>()
          .toList(growable: false);
      final players = game.world.children
          .whereType<PlayerComponent>()
          .toList(growable: false);

      expect(patches, hasLength(1));
      expect(players, hasLength(1));
      expect(patches.single.priority, patches.single.instruction.flamePriority);
      expect(
        patches.single.priority,
        (1000 + patches.single.instruction.depthSortY).round(),
      );
      expect(
        players.single.priority,
        1000 + players.single.footPoint.y.round(),
      );

      final image = await _renderGame(game, width: 256, height: 192);

      expect(image.width, 256);
      expect(image.height, 192);
    });
  });
}

const _tileSize = 16;
const _buildingWidthTiles = 6;
const _buildingHeightTiles = 7;
const _buildingWidthPx = _buildingWidthTiles * _tileSize;
const _buildingHeightPx = _buildingHeightTiles * _tileSize;
const _roofHeightPx = 3 * _tileSize;

RuntimeMapBundle _bundle() {
  return RuntimeMapBundle(
    manifest: ProjectManifest(
      name: 'Runtime Occlusion Visual Smoke',
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
          id: 'visual-smoke-house',
          name: 'Visual Smoke House',
          tilesetId: 'building',
          categoryId: 'buildings',
          frames: const [
            TilesetVisualFrame(
              source: TilesetSourceRect(
                x: 0,
                y: 0,
                width: _buildingWidthTiles,
                height: _buildingHeightTiles,
              ),
            ),
          ],
          collisionProfile: ElementCollisionProfile(
            source: ElementCollisionProfileSource.manual,
            collisionMask: _baseCollisionMask(),
            occlusionMask: _roofOcclusionMask(),
          ),
        ),
      ],
      surfaceCatalog: ProjectSurfaceCatalog(),
    ),
    map: const MapData(
      id: 'runtime-occlusion-visual-smoke-map',
      name: 'Runtime Occlusion Visual Smoke Map',
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
          id: 'visual-smoke-house-1',
          layerId: 'buildings',
          elementId: 'visual-smoke-house',
          pos: GridPos(x: 1, y: 1),
          applyCollision: true,
        ),
      ],
      mapMetadata: MapMetadata(defaultSpawnId: 'player-start'),
    ),
    projectRootDirectory: '/tmp/runtime-occlusion-visual-smoke',
    tilesetAbsolutePathsById: const {
      'player': '/tmp/player.png',
      'building': '/tmp/building.png',
    },
  );
}

Future<Map<String, RuntimeTilesetImage>> _loadRuntimeImages(
  Map<String, String> absolutePathByTilesetId, {
  Map<String, TilesetTransparentColor> transparentColorByTilesetId =
      const <String, TilesetTransparentColor>{},
}) async {
  final images = <String, RuntimeTilesetImage>{};
  if (absolutePathByTilesetId.containsKey('player')) {
    images['player'] = await _solidRuntimeTilesetImage(
      width: 16,
      height: 32,
      color: const Color(0xFF2060FF),
    );
  }
  if (absolutePathByTilesetId.containsKey('building')) {
    images['building'] = await _solidRuntimeTilesetImage(
      width: _buildingWidthPx,
      height: _buildingHeightPx,
      color: const Color(0xFFFFD830),
    );
  }
  return images;
}

Future<ui.Image> _renderGame(
  PlayableMapGame game, {
  required int width,
  required int height,
}) {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  game.render(canvas);
  return recorder.endRecording().toImage(width, height);
}

ElementCollisionPixelMask _roofOcclusionMask() {
  return _mask(
    widthPx: _buildingWidthPx,
    heightPx: _buildingHeightPx,
    isSolid: (_, y) => y < _roofHeightPx,
  );
}

ElementCollisionPixelMask _baseCollisionMask() {
  return _mask(
    widthPx: _buildingWidthPx,
    heightPx: _buildingHeightPx,
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

### `reports/collision/collision_lot_16_runtime_occlusion_visual_qa.md`

Le rapport est ce fichier. Il n'est pas recopié récursivement dans lui-même.
