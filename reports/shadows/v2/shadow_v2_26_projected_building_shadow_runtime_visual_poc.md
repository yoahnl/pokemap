# ShadowV2-26 — Projected Building Shadow Runtime Visual POC V0

## 1. Résumé exécutif

ShadowV2-26 ajoute un POC visuel automatisé minimal, en mémoire, sans screenshot disque et sans baseline.

Le test créé prouve le chaînon demandé :

```text
PlayableMapGame minimal
-> background MapLayersComponent.shadowCollectionProvider
-> ShadowRuntimeInstructionCollection contenant V2 projectedPolygon groundStatic
-> ShadowRuntimeRenderer.renderCollectionPass(...)
-> ui.PictureRecorder / ui.Canvas
-> ui.Image
-> pixels alpha vérifiés
```

Résultat :
- pixel intérieur V2 `(80,150)` : `alpha > 0` ;
- pixel extérieur `(10,10)` : `alpha == 0` ;
- points V2 attendus vérifiés : `(64,128)`, `(64,192)`, `(112,176)`, `(112,144)` ;
- coexistence V1 + V2 vérifiée par ordre de collection : V2 avant V1 ;
- aucun fichier de production modifié ;
- aucun screenshot, aucune baseline, aucun fichier Selbrume.

## 2. Objectif du lot

Objectif exact :

```text
Prouver par test automatisé qu'une ombre projetée V2 produite par PlayableMapGame
est réellement dessinée en pixels par ShadowRuntimeRenderer existant.
```

Le lot devait créer uniquement :

```text
packages/map_runtime/test/shadow/runtime_projected_building_shadow_visual_poc_test.dart
reports/shadows/v2/shadow_v2_26_projected_building_shadow_runtime_visual_poc.md
```

## 3. Rappel ShadowV2-24 / ShadowV2-25

ShadowV2-24 a raccordé ShadowV2 au runtime via `PlayableMapGame` :

```text
ProjectManifest + MapData
-> buildRuntimeProjectedBuildingShadowCollection(...)
-> stockage privé par map dans PlayableMapGame
-> merge V2 + V1 + actorContact
-> provider interne du background MapLayersComponent
-> ShadowRuntimeRenderer existant
```

ShadowV2-25 a choisi l'option C :

```text
test renderer + provider combiné sans GameWidget
```

ShadowV2-26 applique cette décision avec un test qui récupère la collection depuis le provider host et la rend en mémoire avec le renderer existant.

## 4. État initial du worktree

Commande :

```bash
git status --short --untracked-files=all
```

Sortie :

```text
```

Interprétation : aucun fichier préexistant non lié au lot n'était présent dans le worktree au lancement de ShadowV2-26.

## 5. Décision AGENTS / design gate déjà satisfait

Commandes :

```bash
find .. -name AGENTS.md -print
```

Sortie :

```text
../pokemonProject/AGENTS.md
../free-claude-code/AGENTS.md
```

Commande :

```bash
rg -n "Do not invoke implementation skills|design has been presented|creative|structural|architectural|product-facing" AGENTS.md
```

Sortie :

```text
765:Before structural changes, read the nearest:
848:1. Brainstorming (`superpowers:brainstorming`) before creative work.
1094:Do not invoke implementation skills, write code, scaffold a project, or take implementation action until a design has been presented and approved when the task is creative, structural, architectural, or product-facing.
1096:For creative work such as features, components, behavior changes, or UI:
```

Décision : le design gate visuel a déjà été satisfait par ShadowV2-25. ShadowV2-26 est uniquement l'exécution test-only de ce design.

Note Flame MCP : `flame_docs` a été interrogé pour les tests de rendu en mémoire (`Flame testing render component PictureRecorder Canvas toImage`, `GameWidget widget test FlameGame`). Aucun résultat n'a été trouvé. Le POC suit donc les patterns locaux déjà présents dans les tests `map_runtime`.

## 6. Fichiers créés / modifiés / supprimés

Créés par ShadowV2-26 :

```text
packages/map_runtime/test/shadow/runtime_projected_building_shadow_visual_poc_test.dart
reports/shadows/v2/shadow_v2_26_projected_building_shadow_runtime_visual_poc.md
```

Modifiés par ShadowV2-26 :

```text
Aucun
```

Supprimés par ShadowV2-26 :

```text
Aucun
```

Generated touchés :

```text
Aucun
```

Screenshots / baselines créés :

```text
Aucun
```

Fichiers Selbrume touchés :

```text
Aucun
```

Fichiers préexistants non liés au lot :

```text
Aucun
```

## 7. Audit initial des tests host / renderer

Commande :

```bash
rg -n "runtime projected building shadow host integration|PlayableMapGame provides projected building shadows|_expectProjectedBuildingInstruction|_backgroundLayer|ShadowRuntimeRenderer|renderCollectionPass|pixelAt|rawRgba|PictureRecorder|toImage" packages/map_runtime/test/shadow packages/map_runtime/lib/src/shadow packages/map_runtime/lib/src/presentation/flame
```

Sortie pertinente :

```text
packages/map_runtime/test/shadow/shadow_runtime_renderer_test.dart:57:  group('ShadowRuntimeRenderer.renderInstruction', () {
packages/map_runtime/test/shadow/shadow_runtime_renderer_test.dart:243:  group('ShadowRuntimeRenderer.renderCollectionPass', () {
packages/map_runtime/test/shadow/shadow_runtime_renderer_test.dart:385:  final recorder = ui.PictureRecorder();
packages/map_runtime/test/shadow/shadow_runtime_renderer_test.dart:397:  const ShadowRuntimeRenderer().renderCollectionPass(canvas, collection, pass);
packages/map_runtime/test/shadow/shadow_runtime_renderer_test.dart:406:  final data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
packages/map_runtime/test/shadow/runtime_projected_building_shadow_host_integration_test.dart:17:  group('runtime projected building shadow host integration', () {
packages/map_runtime/test/shadow/runtime_projected_building_shadow_host_integration_test.dart:19:        'PlayableMapGame provides projected building shadows to the background layer',
packages/map_runtime/test/shadow/runtime_projected_building_shadow_host_integration_test.dart:31:      final background = _backgroundLayer(game);
packages/map_runtime/test/shadow/runtime_projected_building_shadow_host_integration_test.dart:41:      _expectProjectedBuildingInstruction(instruction);
packages/map_runtime/test/shadow/runtime_projected_building_shadow_host_integration_test.dart:348:MapLayersComponent _backgroundLayer(PlayableMapGame game) {
packages/map_runtime/test/shadow/runtime_projected_building_shadow_host_integration_test.dart:384:void _expectProjectedBuildingInstruction(
packages/map_runtime/test/shadow/shadow_runtime_renderer_integration_test.dart:21:      expect(await pixelAt(image, 16, 16), rgba(0, 0, 255, 255));
packages/map_runtime/test/shadow/runtime_static_placed_element_shadow_host_integration_test.dart:63:      expect((await pixelAt(image, centerX, centerY))[3], greaterThan(0));
packages/map_runtime/test/shadow/runtime_static_placed_element_shadow_host_integration_test.dart:456:  final recorder = ui.PictureRecorder();
packages/map_runtime/test/shadow/runtime_static_placed_element_shadow_host_integration_test.dart:459:  return recorder.endRecording().toImage(width, height);
packages/map_runtime/lib/src/shadow/shadow_runtime_renderer.dart:8:final class ShadowRuntimeRenderer {
packages/map_runtime/lib/src/shadow/shadow_runtime_renderer.dart:69:  void renderCollectionPass(
packages/map_runtime/lib/src/presentation/flame/map_layers_component.dart:43:    this.shadowRenderer = const ShadowRuntimeRenderer(),
packages/map_runtime/lib/src/presentation/flame/map_layers_component.dart:335:    shadowRenderer.renderCollectionPass(
packages/map_runtime/lib/src/presentation/flame/map_layers_component.dart:340:    shadowRenderer.renderCollectionPass(
```

Confirmations :
- le test host du Lot 24 fournit une micro-bundle exploitable ;
- le renderer sait déjà rendre `projectedPolygon` ;
- les tests existants utilisent déjà `PictureRecorder`, `toImage`, `rawRgba` et `pixelAt` ;
- aucun fichier production n'était nécessaire pour le POC.

## 8. Stratégie de preuve visuelle choisie

Stratégie appliquée :
- construire un `PlayableMapGame` minimal avec les données V2 authorées ;
- récupérer la collection finale depuis le provider du background `MapLayersComponent` ;
- vérifier que la collection contient l'instruction V2 attendue ;
- rendre le pass `groundStatic` en mémoire avec `ShadowRuntimeRenderer.renderCollectionPass(...)` ;
- vérifier l'alpha de deux pixels.

Le test ne monte pas `GameWidget`, ne crée pas de fichier image et n'utilise pas le harness Selbrume.

## 9. Test principal : provider V2 -> renderer -> pixels

Test créé :

```text
runtime projected building visual POC renders host-provided V2 polygon pixels
```

Ce test :
- charge une map synthétique 4x4 ;
- utilise `tileWidth = 16`, `tileHeight = 16`, `displayScale = 2` ;
- place le building en `(1,2)` ;
- utilise `ProjectedShadowDirection(x: 1, y: 0)` ;
- utilise `lengthRatio = 0.5`, `nearWidthRatio = 1`, `farWidthRatio = 0.5` ;
- utilise `opacity = 0.18`, `colorHexRgb = '123ABC'` ;
- vérifie les points `(64,128)`, `(64,192)`, `(112,176)`, `(112,144)` ;
- rend la collection `groundStatic` en image mémoire ;
- vérifie `alpha(80,150) > 0` ;
- vérifie `alpha(10,10) == 0`.

Le pixel `(80,150)` est choisi parce qu'il est nettement à l'intérieur du polygone attendu et loin du pixel extérieur `(10,10)`.

## 10. Test coexistence V1 + V2

Test créé :

```text
runtime projected building visual POC keeps V2 before V1 in merged collection
```

Ce test ajoute une ombre V1 au même élément via :

```text
ProjectShadowProfile(
  id: 'legacy-shadow',
  name: 'Legacy Shadow',
  mode: ShadowCasterMode.ellipse,
  renderPass: ShadowRenderPass.groundStatic,
  opacity: 0.35,
  colorHexRgb: '010203',
)
```

Assertions :
- `collection.groundStatic` contient 2 instructions ;
- `groundStatic[0]` est V2 (`projectedPolygon`, `123ABC`, `0.18`) ;
- `groundStatic[1]` est V1 (`010203`, `0.35`) ;
- aucune preuve par pixel blendé n'est utilisée pour l'ordre.

## 11. Test anti-dérive screenshot/baseline/genericProjection

Test créé :

```text
runtime projected building visual POC does not use screenshots baselines or auto projection
```

Dans le code source, les chaînes interdites sont découpées en littéraux adjacents afin que le test vérifie les chaînes complètes au runtime sans que l'audit `rg` se détecte lui-même.

Exemples :

```dart
'matches' 'GoldenFile'
'generic' 'Projection'
'base' 'line_manifest' '.json'
```

## 12. TDD RED initial

Commande :

```bash
cd packages/map_runtime && flutter test test/shadow/runtime_projected_building_shadow_visual_poc_test.dart
```

Sortie RED :

```text
00:00 +0: loading /Users/karim/Project/pokemonProject/packages/map_runtime/test/shadow/runtime_projected_building_shadow_visual_poc_test.dart
test/shadow/runtime_projected_building_shadow_visual_poc_test.dart:29:27: Error: Method not found: '_renderGroundStaticShadows'.
      final image = await _renderGroundStaticShadows(
                          ^^^^^^^^^^^^^^^^^^^^^^^^^^
00:00 +0 -1: loading /Users/karim/Project/pokemonProject/packages/map_runtime/test/shadow/runtime_projected_building_shadow_visual_poc_test.dart [E]
  Failed to load "/Users/karim/Project/pokemonProject/packages/map_runtime/test/shadow/runtime_projected_building_shadow_visual_poc_test.dart":
  Compilation failed for testPath=/Users/karim/Project/pokemonProject/packages/map_runtime/test/shadow/runtime_projected_building_shadow_visual_poc_test.dart: test/shadow/runtime_projected_building_shadow_visual_poc_test.dart:29:27: Error: Method not found: '_renderGroundStaticShadows'.
        final image = await _renderGroundStaticShadows(
                            ^^^^^^^^^^^^^^^^^^^^^^^^^^
  .
00:00 +0 -1: Some tests failed.
```

Interprétation : RED contrôlé par helper de rendu manquant. Le correctif a été limité au fichier de test : ajout de l'import `ShadowRuntimeRenderer` et du helper `_renderGroundStaticShadows(...)`.

## 13. Résultats des tests

### Test ciblé final

Commande :

```bash
cd packages/map_runtime && flutter test test/shadow/runtime_projected_building_shadow_visual_poc_test.dart
```

Sortie complète :

```text
00:00 +0: loading /Users/karim/Project/pokemonProject/packages/map_runtime/test/shadow/runtime_projected_building_shadow_visual_poc_test.dart
00:00 +0: runtime projected building shadow visual POC runtime projected building visual POC renders host-provided V2 polygon pixels
[runtime] Map loaded: projected-building-shadow-visual-poc, spawn at (0, 0)
00:00 +1: runtime projected building shadow visual POC runtime projected building visual POC keeps V2 before V1 in merged collection
[runtime] Map loaded: projected-building-shadow-visual-poc, spawn at (0, 0)
00:00 +2: runtime projected building shadow visual POC runtime projected building visual POC does not use screenshots baselines or auto projection
00:00 +3: All tests passed!
```

### Régressions ciblées

Commande :

```bash
cd packages/map_runtime && flutter test test/shadow/shadow_runtime_renderer_test.dart test/shadow/shadow_runtime_renderer_integration_test.dart test/shadow/runtime_projected_building_shadow_host_integration_test.dart
```

Ligne finale exacte :

```text
00:00 +35: All tests passed!
```

### Régression shadow complète

Commande :

```bash
cd packages/map_runtime && flutter test test/shadow
```

Ligne finale exacte :

```text
00:02 +260: All tests passed!
```

## 14. Résultat analyze

Commande :

```bash
cd packages/map_runtime && flutter analyze test/shadow/runtime_projected_building_shadow_visual_poc_test.dart
```

Sortie complète :

```text
Analyzing runtime_projected_building_shadow_visual_poc_test.dart...

No issues found! (ran in 2.2s)
```

## 15. Audit anti-dérive

Commande :

```bash
rg -n "genericProjection|applyElementAutoShadowPolicyToProject|diagnoseProjectedBuildingShadows|ProjectValidator|MapValidator|resolveProjectedStaticShadowGeometry|resolveStaticShadowFamilyProjectionSpec|static_shadow_family_projection|element_auto_shadow_policy|SHADOW_SCREENSHOT|baseline|matchesGoldenFile|selbrume|reports/shadows/baselines" packages/map_runtime/test/shadow/runtime_projected_building_shadow_visual_poc_test.dart
```

Sortie :

```text
```

Interprétation : aucune dérive détectée dans le fichier de test V2-26.

## 16. Ce qui n’a volontairement pas été modifié

Fichiers de production non modifiés :

```text
packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart
packages/map_runtime/lib/src/presentation/flame/map_layers_component.dart
packages/map_runtime/lib/src/shadow/shadow_runtime_renderer.dart
packages/map_runtime/lib/src/shadow/shadow_runtime_render_instruction.dart
packages/map_runtime/lib/src/shadow/shadow_runtime_instruction_collection.dart
packages/map_runtime/lib/src/shadow/runtime_projected_building_shadow_collection.dart
packages/map_runtime/lib/src/shadow/projected_building_shadow_runtime_adapter.dart
packages/map_runtime/lib/src/shadow/runtime_shadow_collection_merge.dart
packages/map_runtime/lib/src/shadow/runtime_static_placed_element_shadow_collection.dart
packages/map_runtime/lib/src/shadow/runtime_static_placed_element_shadow_sources.dart
packages/map_core/**
packages/map_editor/**
packages/map_gameplay/**
packages/map_battle/**
examples/**
packages/map_runtime/tool/**
```

Tests existants non modifiés :

```text
packages/map_runtime/test/shadow/runtime_projected_building_shadow_host_integration_test.dart
packages/map_runtime/test/shadow/shadow_runtime_renderer_test.dart
packages/map_runtime/test/shadow/shadow_runtime_renderer_integration_test.dart
packages/map_runtime/test/shadow/runtime_static_placed_element_shadow_host_integration_test.dart
```

## 17. Ce qui n’a volontairement pas été créé

Non créés :

```text
*.png
*.jpg
*.jpeg
*.webp
*.golden
baseline_manifest.json
fixture Selbrume
nouveau renderer
nouveau provider public
nouveau modèle
nouveau codec
nouveau diagnostic
generated file
GameWidget test
screenshot disque
baseline
```

## 18. git diff --stat

Sortie avant création du rapport, après création du test :

```text
```

Interprétation : le test est non suivi, donc `git diff --stat` ne le liste pas.

Sortie finale après création du rapport :

```text
```

Interprétation : les deux fichiers du lot sont non suivis, donc `git diff --stat` reste vide.

## 19. git diff --name-status

Sortie avant création du rapport, après création du test :

```text
```

Interprétation : aucun fichier suivi n'a été modifié.

Sortie finale après création du rapport :

```text
```

Interprétation : aucun fichier suivi n'a été modifié.

## 20. git diff --check

Sortie avant création du rapport, après création du test :

```text
```

Interprétation : aucune erreur whitespace détectée.

Sortie finale après création du rapport :

```text
```

Interprétation : `git diff --check` est propre.

## 21. git status final

Commande :

```bash
git status --short --untracked-files=all
```

Sortie :

```text
?? packages/map_runtime/test/shadow/runtime_projected_building_shadow_visual_poc_test.dart
?? reports/shadows/v2/shadow_v2_26_projected_building_shadow_runtime_visual_poc.md
```

Interprétation : le status final montre uniquement les deux fichiers attendus pour ShadowV2-26.

## 22. Risques / réserves

Risque : le test rend directement la collection via `ShadowRuntimeRenderer`, et non un `GameWidget`.

Réponse : c'est la décision explicite de ShadowV2-25. Les tests existants prouvent déjà que `MapLayersComponent` appelle `renderCollectionPass`; ce lot prouve que la collection V2 produite par le host devient bien des pixels via le renderer existant.

Risque : un pixel intérieur pourrait devenir fragile si la géométrie change.

Réponse : le test vérifie d'abord les quatre points attendus. Le pixel `(80,150)` est choisi loin des bords du polygone et le renderer utilise un paint hard-edge sans antialiasing.

Risque : la coexistence V1/V2 par pixel serait ambiguë.

Réponse : l'ordre V2 avant V1 est volontairement vérifié par collection order, pas par couleur blendée.

## 23. Auto-critique

- Le lot est bien test-only : aucun fichier de production n'a été modifié.
- Le test prouve réellement un pixel issu de V2 : la collection est récupérée depuis `PlayableMapGame`, l'instruction V2 est identifiée par shape/pass/couleur/opacité/points, puis la collection est rendue par `ShadowRuntimeRenderer`.
- Le test ne confond pas V1 et V2 : V2 est identifiée par `projectedPolygon`, `123ABC`, `0.18`; V1 par `010203`, `0.35`.
- Le pixel intérieur `(80,150)` est assez loin des bords du polygone attendu.
- Le pixel extérieur `(10,10)` est hors polygone.
- Le test ne dépend pas d'une couleur exacte fragile ; il vérifie l'alpha.
- Le test n'écrit aucun fichier image.
- Le test ne modifie ni Selbrume ni baseline.
- Le rapport contient les preuves demandées et le code complet du test créé.

## 24. Regard critique sur le prompt

Le prompt verrouille correctement le risque principal : "visual POC" aurait pu déclencher un screenshot, un golden ou une modification du renderer. Le cadrage force une preuve plus fine : collection V2 host -> renderer existant -> pixels en mémoire.

Le test anti-dérive avec `rg` sur des termes interdits impose une petite gymnastique de chaînes concaténées dans le test, mais elle est utile : le fichier source reste propre pour l'audit tout en vérifiant les snippets complets au runtime.

## 25. Prochain lot recommandé

Prochain lot recommandé :

```text
ShadowV2-27 — Projected Building Shadow Editor Preview Design Gate
```

Alternative si le rendu V2 nécessite une décision artistique avant l'éditeur :

```text
ShadowV2-27 — Projected Building Shadow Visual Calibration Design Gate
```

## 26. Code complet des fichiers créés/modifiés

### packages/map_runtime/test/shadow/runtime_projected_building_shadow_visual_poc_test.dart

```dart
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/src/application/runtime_map_bundle.dart';
import 'package:map_runtime/src/infrastructure/runtime_tileset_image.dart';
import 'package:map_runtime/src/presentation/flame/map_layers_component.dart';
import 'package:map_runtime/src/presentation/flame/playable_map_game.dart';
import 'package:map_runtime/src/shadow/shadow_runtime_instruction_collection.dart';
import 'package:map_runtime/src/shadow/shadow_runtime_render_instruction.dart';
import 'package:map_runtime/src/shadow/shadow_runtime_renderer.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('runtime projected building shadow visual POC', () {
    test(
        'runtime projected building visual POC renders host-provided V2 polygon pixels',
        () async {
      final collection = await _hostShadowCollection();

      expect(collection, isNotNull);
      final v2Instructions = _projectedBuildingInstructions(collection!);
      expect(v2Instructions, hasLength(1));
      final instruction = v2Instructions.single;
      _expectProjectedBuildingInstruction(instruction);

      final image = await _renderGroundStaticShadows(
        collection,
        width: 160,
        height: 224,
      );

      expect(await _alphaAt(image, 80, 150), greaterThan(0));
      expect(await _alphaAt(image, 10, 10), 0);
    });

    test(
        'runtime projected building visual POC keeps V2 before V1 in merged collection',
        () async {
      final collection = await _hostShadowCollection(withV1Shadow: true);
      final groundStatic = collection!.groundStatic;

      expect(groundStatic, hasLength(2));
      _expectProjectedBuildingInstruction(groundStatic[0]);
      _expectLegacyStaticInstruction(groundStatic[1]);
    });

    test(
        'runtime projected building visual POC does not use screenshots '
        'base'
        'lines or auto projection',
        () {
      final source = File(
        'test/shadow/runtime_projected_building_shadow_visual_poc_test.dart',
      ).readAsStringSync();
      final forbiddenSnippets = [
        'matches' 'GoldenFile',
        'SHADOW_' 'SCREENSHOT',
        'sel' 'brume',
        'base' 'line_manifest' '.json',
        'reports/shadows/base' 'lines',
        'diagnoseProjectedBuilding' 'Shadows',
        'applyElementAutoShadow' 'PolicyToProject',
        'generic' 'Projection',
        'resolveProjected' 'StaticShadowGeometry',
        'resolveStaticShadowFamily' 'ProjectionSpec',
        'static_shadow_family' '_projection',
        'element_auto_shadow' '_policy',
      ];

      for (final snippet in forbiddenSnippets) {
        expect(source, isNot(contains(snippet)));
      }
    });
  });
}

Future<ShadowRuntimeInstructionCollection?> _hostShadowCollection({
  bool withV1Shadow = false,
}) async {
  final game = PlayableMapGame(
    bundle: _bundle(withV1Shadow: withV1Shadow),
    projectFilePath: '/tmp/project.json',
    runtimeTilesetImageLoader: _emptyImageLoader,
    enableActorContactShadows: false,
  );

  game.onGameResize(Vector2(160, 224));
  await game.onLoad();
  game.update(0);
  final background = _backgroundLayer(game);

  expect(background.shadowCollectionProvider, isNotNull);
  return background.shadowCollectionProvider!();
}

RuntimeMapBundle _bundle({
  bool withV1Shadow = false,
}) {
  return RuntimeMapBundle(
    manifest: ProjectManifest(
      name: 'Runtime Projected Building Shadow Visual POC',
      maps: const <ProjectMapEntry>[],
      tilesets: const <ProjectTilesetEntry>[],
      settings: const ProjectSettings(
        tileWidth: 16,
        tileHeight: 16,
        displayScale: 2,
        defaultPlayerCharacterId: 'player',
      ),
      elements: [
        ProjectElementEntry(
          id: 'building',
          name: 'Building',
          tilesetId: 'props',
          categoryId: 'building',
          frames: const [
            TilesetVisualFrame(
              source: TilesetSourceRect(x: 0, y: 0, width: 2, height: 3),
            ),
          ],
          shadow: withV1Shadow
              ? ProjectElementShadowConfig(
                  castsShadow: true,
                  shadowProfileId: 'legacy-shadow',
                )
              : null,
          projectedBuildingShadow: _projectedConfig(),
        ),
      ],
      characters: const [
        ProjectCharacterEntry(
          id: 'player',
          name: 'Player',
          tilesetId: 'player',
          frameWidth: 2,
          frameHeight: 2,
        ),
      ],
      surfaceCatalog: ProjectSurfaceCatalog(),
      shadowCatalog: withV1Shadow
          ? _legacyShadowCatalog()
          : const ProjectShadowCatalog.empty(),
      projectedBuildingShadowCatalog: ProjectBuildingShadowPresetCatalog(
        presets: [_preset()],
      ),
    ),
    map: const MapData(
      id: 'projected-building-shadow-visual-poc',
      name: 'Projected Building Shadow Visual POC',
      size: GridSize(width: 4, height: 4),
      layers: [
        MapLayer.tile(
          id: 'objects',
          name: 'Objects',
          tilesetId: 'props',
          tiles: <int>[],
        ),
      ],
      placedElements: [
        MapPlacedElement(
          id: 'building-1',
          layerId: 'objects',
          elementId: 'building',
          pos: GridPos(x: 1, y: 2),
        ),
      ],
      entities: [
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
      mapMetadata: MapMetadata(defaultSpawnId: 'spawn'),
    ),
    projectRootDirectory: '/tmp/runtime-projected-building-shadow-visual-poc',
    tilesetAbsolutePathsById: const <String, String>{},
  );
}

ProjectElementProjectedBuildingShadowConfig _projectedConfig() {
  return ProjectElementProjectedBuildingShadowConfig(
    enabled: true,
    presetId: 'shadow-a',
    anchor: ProjectedShadowAnchor(xRatio: 0.5, yRatio: 1),
    localOffset: ProjectedShadowOffset(x: 0, y: 0),
  );
}

ProjectBuildingShadowPreset _preset() {
  return ProjectBuildingShadowPreset(
    id: 'shadow-a',
    name: 'Shadow A',
    direction: ProjectedShadowDirection(x: 1, y: 0),
    shape: ProjectedShadowShapeTuning(
      lengthRatio: 0.5,
      nearWidthRatio: 1,
      farWidthRatio: 0.5,
    ),
    appearance: ProjectedShadowAppearance(
      opacity: 0.18,
      colorHexRgb: '123ABC',
    ),
    timeOfDayMode: ProjectedShadowTimeOfDayMode.fixed,
  );
}

ProjectShadowCatalog _legacyShadowCatalog() {
  return ProjectShadowCatalog(
    profiles: [
      ProjectShadowProfile(
        id: 'legacy-shadow',
        name: 'Legacy Shadow',
        mode: ShadowCasterMode.ellipse,
        renderPass: ShadowRenderPass.groundStatic,
        opacity: 0.35,
        colorHexRgb: '010203',
      ),
    ],
  );
}

Future<Map<String, RuntimeTilesetImage>> _emptyImageLoader(
  Map<String, String> absolutePathByTilesetId, {
  Map<String, TilesetTransparentColor> transparentColorByTilesetId =
      const <String, TilesetTransparentColor>{},
}) async {
  return const <String, RuntimeTilesetImage>{};
}

MapLayersComponent _backgroundLayer(PlayableMapGame game) {
  return game.world.children.whereType<MapLayersComponent>().singleWhere(
        (layer) => layer.renderPass == MapLayerRenderPass.background,
      );
}

List<ShadowRuntimeRenderInstruction> _projectedBuildingInstructions(
  ShadowRuntimeInstructionCollection collection,
) {
  return collection.groundStatic
      .where(
        (instruction) =>
            instruction.shape == ShadowRuntimeShapeKind.projectedPolygon &&
            instruction.renderPass == ShadowRenderPass.groundStatic &&
            instruction.colorHexRgb == '123ABC' &&
            instruction.opacity == 0.18,
      )
      .toList(growable: false);
}

void _expectProjectedBuildingInstruction(
  ShadowRuntimeRenderInstruction instruction,
) {
  expect(instruction.shape, ShadowRuntimeShapeKind.projectedPolygon);
  expect(instruction.renderPass, ShadowRenderPass.groundStatic);
  expect(instruction.opacity, 0.18);
  expect(instruction.colorHexRgb, '123ABC');
  expect(instruction.polygonPoints, hasLength(4));
  _expectPointClose(instruction.polygonPoints[0], x: 64, y: 128);
  _expectPointClose(instruction.polygonPoints[1], x: 64, y: 192);
  _expectPointClose(instruction.polygonPoints[2], x: 112, y: 176);
  _expectPointClose(instruction.polygonPoints[3], x: 112, y: 144);
}

void _expectLegacyStaticInstruction(
  ShadowRuntimeRenderInstruction instruction,
) {
  expect(instruction.renderPass, ShadowRenderPass.groundStatic);
  expect(instruction.opacity, 0.35);
  expect(instruction.colorHexRgb, '010203');
}

void _expectPointClose(
  ShadowRuntimePoint point, {
  required double x,
  required double y,
}) {
  expect(point.worldX, closeTo(x, 0.000001));
  expect(point.worldY, closeTo(y, 0.000001));
}

Future<int> _alphaAt(ui.Image image, int x, int y) async {
  final data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
  final offset = (y * image.width + x) * 4;
  return data!.getUint8(offset + 3);
}

Future<ui.Image> _renderGroundStaticShadows(
  ShadowRuntimeInstructionCollection collection, {
  required int width,
  required int height,
}) {
  final recorder = ui.PictureRecorder();
  final canvas = ui.Canvas(recorder);
  const ShadowRuntimeRenderer().renderCollectionPass(
    canvas,
    collection,
    ShadowRenderPass.groundStatic,
  );
  return recorder.endRecording().toImage(width, height);
}
```

Le présent rapport est le contenu complet du fichier :

```text
reports/shadows/v2/shadow_v2_26_projected_building_shadow_runtime_visual_poc.md
```

Checklist finale :
- [x] Aucun fichier de production modifié
- [x] Aucun test existant modifié
- [x] Nouveau test visual POC créé
- [x] Rapport Lot 26 créé
- [x] Aucun screenshot créé
- [x] Aucune baseline créée
- [x] Selbrume non modifié
- [x] PlayableMapGame non modifié
- [x] MapLayersComponent non modifié
- [x] ShadowRuntimeRenderer non modifié
- [x] map_core non modifié
- [x] Provider V2 récupéré depuis PlayableMapGame
- [x] V2 projectedPolygon groundStatic vérifié
- [x] Points V2 attendus vérifiés
- [x] Pixel intérieur alpha > 0 vérifié
- [x] Pixel extérieur alpha == 0 vérifié
- [x] Ordre V2 avant V1 vérifié
- [x] Aucun genericProjection / diagnostics runtime
- [x] Test ciblé passé
- [x] Régressions ciblées passées
- [x] test/shadow complet passé
- [x] Analyze ciblé OK
- [x] Evidence Pack complet
- [x] git status final conforme
