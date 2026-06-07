# NS-SCENES-V1-94 bis — Cinematic Path Studio Water Fidelity Fix

## 1. Résumé

Correction demandée par Karim après V1-94 : le prompt collé préparait V1-95, mais Karim a explicitement signalé que les éléments Path Studio, notamment l'eau, manquaient dans le backdrop cinematic. Cette demande directe a donc été traitée comme un correctif V1-94 bis avant de passer au contrat sprite V1-95.

Le bug venait du renderer backdrop cinematic : quand un `PathLayer` référence le preset de base Path Studio (`water_base`), le plan cinematic utilisait seulement ce preset de base. Le Map Editor, lui, résout d'abord l'unique `ProjectPathPatternPreset` lié par `basePathPresetId`, ce qui permet d'afficher le motif d'eau Path Studio.

V1-94 bis aligne le renderer cinematic sur ce comportement : si un pattern unique est lié au preset de base, il est utilisé ; si plusieurs patterns sont liés, le renderer conserve le fallback base pour éviter un choix arbitraire.

## 2. Demande

Demande utilisateur exacte de Karim :

```text
Let's go me faire le prochain prompt !

Le problème est qu'il manque les éléments du "path studio" et donc l'eau.
```

Arbitrage : le document attaché `NS-SCENES-V1-95 — Cinematic Actor Display Preview Sprite Resolver Prep Contract` n'a pas été exécuté dans ce tour, car il demandait un lot documentaire sans modification `packages/`, alors que Karim a demandé de réparer le rendu Path Studio/eau. V1-95 reste donc le prochain lot recommandé.

## 3. Cause racine

Le rendu Map Editor résout les motifs Path Studio depuis le preset de base :

```dart
for (final preset in project.pathPatternPresets)
  if (preset.basePathPresetId == normalizedPresetId) preset
```

Le rendu cinematic V1-94 cherchait seulement un pattern dont `pattern.id == layer.presetId`, puis retombait sur le preset de base. Pour une couche d'eau typique :

```text
PathLayer.presetId = water_base
ProjectPathPatternPreset.id = water_pattern
ProjectPathPatternPreset.basePathPresetId = water_base
```

le renderer cinematic ne trouvait pas `water_pattern` et affichait `water_base`, ce qui supprimait l'eau/motif Path Studio visible dans le Map Editor.

## 4. Code modifié

Fichier principal :

```text
packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_map_backdrop_layer_render_plan.dart
```

Code ajouté dans `_resolvePathPreset` :

```dart
final base = _pathPresetById(manifest, trimmed);
if (base == null) {
  return null;
}
ProjectPathPatternPreset? linkedPattern;
var hasAmbiguousPattern = false;
for (final pattern in manifest.pathPatternPresets) {
  if (pattern.basePathPresetId.trim() != trimmed) {
    continue;
  }
  if (linkedPattern != null) {
    hasAmbiguousPattern = true;
    break;
  }
  linkedPattern = pattern;
}
if (!hasAmbiguousPattern && linkedPattern != null) {
  return _ResolvedPathPreset(
    sourceId: linkedPattern.id,
    basePreset: base,
    patternPreset: linkedPattern,
  );
}
return _ResolvedPathPreset(sourceId: base.id, basePreset: base);
```

Comportement conservé :

- si `presetId` est déjà l'id exact d'un `ProjectPathPatternPreset`, l'ancien chemin reste prioritaire ;
- si aucun pattern lié n'existe, le preset de base reste utilisé ;
- si plusieurs patterns sont liés au même base preset, fallback base pour éviter de rendre un motif au hasard.

## 5. Test ajouté

Fichier :

```text
packages/map_editor/test/cinematic_builder_workspace_test.dart
```

Test de régression :

```dart
testWidgets(
    'uses Path Studio center pattern when a path layer references its base preset',
    (tester) async {
  final tilesetImage = await _makeExtendedBackdropTilesetImage();
  final manifest = _pathStudioWaterBackdropProject();

  final plan = buildCinematicMapBackdropLayerRenderPlan(
    mapData: _stageMapDataWithPathStudioWaterBackdrop(),
    manifest: manifest,
    tilesets: {
      'neutral_tiles': CinematicResolvedTilesetAsset.available(
        tilesetId: 'neutral_tiles',
        image: tilesetImage,
        tileWidth: 8,
        tileHeight: 8,
      ),
    },
  );

  final pathInstructions = plan.instructions
      .where((instruction) => instruction.sourceFamily == 'path')
      .toList();
  expect(pathInstructions, hasLength(4));
  expect(
    pathInstructions.map((instruction) => instruction.sourceId).toSet(),
    {'water_pattern'},
  );
  expect(
    pathInstructions.map((instruction) => instruction.sourceRect.left),
    [0.0, 8.0, 16.0, 24.0],
  );
});
```

RED fonctionnel obtenu avant correction :

```text
Expected: Set:['water_pattern']
  Actual: Set:['water_base']
   Which: does not contain 'water_pattern'
```

## 6. Validation

Package :

```text
packages/map_editor
```

Commandes vertes :

```text
flutter test --reporter=compact test/cinematic_builder_workspace_test.dart --plain-name 'uses Path Studio center pattern when a path layer references its base preset'
00:02 +1: All tests passed!
```

```text
flutter test --reporter=compact test/cinematic_builder_workspace_test.dart --plain-name 'builds extended backdrop bitmap instructions for neutral terrain path surface and placed elements'
00:01 +1: All tests passed!
```

```text
flutter analyze --no-fatal-infos lib/src/ui/canvas/cinematics/cinematic_map_backdrop_layer_render_plan.dart test/cinematic_builder_workspace_test.dart
No issues found! (ran in 1.7s)
```

```text
flutter test --reporter=compact test/cinematic_builder_workspace_test.dart
00:35 +175: All tests passed!
```

## 7. Anti-scope

Checks exécutés :

```text
git diff --check
<aucune sortie>
```

```text
git diff --name-only -- packages/map_runtime packages/map_gameplay packages/map_battle examples selbrume
<aucune sortie>
```

```text
rg -n "package:flame|GameWidget|FlameGame|PlayableMapGame|RuntimeMapGame|GameState|map_runtime|MapCanvas\(|MapGridPainter\(|playbackTimeMs|currentTimeMs|isPlaying|Timer\(|Ticker|AnimationController|gpt-image-2|image_generation" packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_map_backdrop_layer_render_plan.dart packages/map_editor/test/cinematic_builder_workspace_test.dart
<aucune sortie, exit 1 attendu pour aucun match>
```

V1-94 bis ne modifie pas :

- `map_runtime` ;
- `map_gameplay` ;
- `map_battle` ;
- `examples` ;
- Selbrume ;
- Flame/runtime/playback ;
- sprite actors ;
- image generation.

## 8. Fichiers modifiés

```text
packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_map_backdrop_layer_render_plan.dart
packages/map_editor/test/cinematic_builder_workspace_test.dart
reports/narrativeStudio/scenes/ns_scenes_v1_94_bis_cinematic_path_studio_water_fidelity_fix.md
reports/narrativeStudio/scenes/ns_scenes_v1_94_bis_evidence_pack.md
reports/narrativeStudio/scenes/road_map_scenes.md
reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
```

## 9. Limites

Ce correctif ne lance toujours pas la cinématique. Il ne remplace pas `MapCanvas`, ne branche pas Flame, ne fait pas de playback, ne rend pas encore les sprites acteurs finaux et ne change pas la timeline.

Le prochain lot recommandé reste :

```text
NS-SCENES-V1-95 — Cinematic Actor Display Preview Sprite Resolver Prep Contract
```

