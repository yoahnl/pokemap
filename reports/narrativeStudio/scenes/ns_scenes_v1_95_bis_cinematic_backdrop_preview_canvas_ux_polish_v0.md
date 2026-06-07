# NS-SCENES-V1-95 bis — Cinematic Backdrop Preview Canvas UX Polish V0

Date : 2026-06-07  
Demandeur : Karim  
Statut proposé : DONE

## Résumé

Karim a demandé de poursuivre le polish de la preview cinematic pour mieux respecter les proportions de l'image cible : moins de chrome autour de l'aperçu, un canvas plus dominant, une timeline toujours visible et lisible, et aucune régression sur l'eau Path Studio ni les acteurs placeholders.

Le lot reste strictement editor-only : aucun runtime, aucun Flame, aucun playback, aucun sprite acteur final, aucune persistance de pan/zoom/grille/details, et aucune mutation projet/map.

## Scope réalisé

- Vue scène plus canvas-first : header/diagnostics secondaires repliés en mode `Vue scène`.
- Détails secondaires accessibles par toggle local au lieu d'occuper l'espace de preview.
- Pan local par drag dans le viewport, exprimé en tuiles, borné par le resolver de framing.
- Reset/recentrage local du zoom et du pan.
- Grille masquée par défaut en `Vue scène`, avec toggle local.
- Backdrop, foreground et placeholders acteurs gardent le même transform.
- Timeline, inspector, transports disabled et rendu Path Studio/eau préservés.
- Seuil preview responsive final : `450 px` minimum pour garder le canvas fort sans rendre les interactions timeline inaccessibles.

## Fichiers modifiés

- `packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_backdrop_preview_framing.dart`
- `packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart`
- `packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_map_backdrop_preview_panel.dart`
- `packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_map_backdrop_layer_renderer.dart`
- `packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_map_backdrop_tile_renderer.dart`
- `packages/map_editor/test/cinematic_builder_workspace_test.dart`
- `reports/narrativeStudio/scenes/road_map_scenes.md`
- `reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md`
- `reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_95_bis_cinematic_backdrop_preview_canvas_ux_polish_v0.png`

## Code généré

### Etat local de framing

```dart
final class CinematicBackdropPreviewFramingState {
  const CinematicBackdropPreviewFramingState({
    this.mode = CinematicBackdropPreviewFramingMode.fitMap,
    this.zoom = 1,
    this.panTiles = Offset.zero,
    this.showDetails = false,
    this.showGrid = false,
  });

  static const minZoom = 1.0;
  static const maxZoom = 4.0;
  static const zoomStep = 0.25;

  final CinematicBackdropPreviewFramingMode mode;
  final double zoom;
  final Offset panTiles;
  final bool showDetails;
  final bool showGrid;
}
```

### Clamp du pan et transform partagé

```dart
final centerTile = Offset(
  _clampCenterTile(
    focusTile.dx + state.panTiles.dx,
    visibleTilesX / 2,
    mapWidth.toDouble(),
  ),
  _clampCenterTile(
    focusTile.dy + state.panTiles.dy,
    visibleTilesY / 2,
    mapHeight.toDouble(),
  ),
);
final clampedPanTiles = centerTile - focusTile;
```

### Drag local en tuiles

```dart
Offset _dragDeltaToPanTiles(
  Offset delta,
  Rect mapFrame,
  int mapWidth,
  int mapHeight,
) {
  if (mapFrame.width <= 0 || mapFrame.height <= 0) {
    return Offset.zero;
  }
  return Offset(
    -delta.dx * mapWidth / mapFrame.width,
    -delta.dy * mapHeight / mapFrame.height,
  );
}
```

### Split preview / timeline

```dart
const _builderBackdropPreviewMinHeight = 450.0;
const _builderBackdropPreviewMaxHeight = 560.0;
const _builderBackdropTimelineMinHeight = 320.0;
const _builderBackdropTimelineMaxHeight = 520.0;
const _builderBackdropTimelinePreferredShare = 0.40;
```

## Preuves de test

RED initial :

```text
flutter test --reporter=compact test/cinematic_builder_workspace_test.dart --plain-name 'renders a larger canvas-first scene preview with compact backdrop chrome'
Expected: a value greater than or equal to <300>
  Actual: <115.0>
```

GREEN principal :

```text
flutter test --reporter=compact test/cinematic_builder_workspace_test.dart --name 'renders a larger canvas-first scene preview|expands and collapses backdrop details|pans the scene view locally|clamps scene view pan|resets scene view pan and zoom|keeps actor placeholders aligned after scene framing pan|keeps grid hidden by default'
00:05 +7: All tests passed!
```

Suite Builder complète :

```text
flutter test --reporter=compact test/cinematic_builder_workspace_test.dart
00:27 +188: All tests passed!
```

Suite Library :

```text
flutter test --reporter=compact test/cinematics_library_workspace_test.dart
00:06 +21: All tests passed!
```

Tests core cinematic :

```text
dart test --reporter=compact test/cinematic_actor_display_preview_model_test.dart test/cinematic_map_backdrop_preview_model_test.dart test/cinematic_stage_map_source_catalog_test.dart test/cinematic_asset_test.dart test/project_manifest_cinematics_test.dart
00:00 +74: All tests passed!
```

Analyse ciblée editor :

```text
flutter analyze --no-fatal-infos ...
No issues found! (ran in 1.4s)
```

Analyse core :

```text
dart analyze
Analyzing map_core...
No issues found!
```

Analyse globale editor :

```text
flutter analyze
352 issues found.
```

Les erreurs globales `map_editor` restent hors lot et concernent notamment la dette préexistante Pokemon SDK (`pokemon_sdk_move_catalog_converter.dart`, `sync_pokemon_sdk_moves_catalog_use_case.dart`) plus des infos/warnings historiques.

## Visual Gate

Capture :

```text
reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_95_bis_cinematic_backdrop_preview_canvas_ux_polish_v0.png
PNG image data, 1663 x 926, 8-bit/color RGBA, non-interlaced
sha256 c9253cf557371ee0a1274f8de7d5571261e0119dddfe76371d02d09d70f70e5c
```

Validation visuelle : preview plus dominante, chrome secondaire replié, timeline conservée, inspector conservé, transports disabled visibles, grille masquée par défaut.

## Anti-scope

- Aucun fichier modifié dans `packages/map_runtime`, `packages/map_gameplay`, `packages/map_battle`, `examples` ou `selbrume`.
- Diff du lot sans ajout `Flame`, `playback`, `MapCanvas`, `readAsBytes`, génération image IA, sprite actor final ou référence Selbrume.
- Diff du lot sans ajout `Color(0x...)` ou `Colors.*`.
- `git diff --check` : aucun problème whitespace/hygiene.

## Git final

```text
 M packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_backdrop_preview_framing.dart
 M packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart
 M packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_map_backdrop_layer_renderer.dart
 M packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_map_backdrop_preview_panel.dart
 M packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_map_backdrop_tile_renderer.dart
 M packages/map_editor/test/cinematic_builder_workspace_test.dart
 M reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
 M reports/narrativeStudio/scenes/road_map_scenes.md
?? reports/narrativeStudio/scenes/ns_scenes_v1_95_bis_cinematic_backdrop_preview_canvas_ux_polish_v0.md
?? reports/narrativeStudio/scenes/ns_scenes_v1_95_bis_evidence_pack.md
?? reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_95_bis_cinematic_backdrop_preview_canvas_ux_polish_v0.png
```

## Limites

- La preview ne lance pas la cinématique.
- Les acteurs restent les placeholders V1-92.
- Le pan, la grille, les détails et le zoom ne sont pas persistés.
- La future reconnaissance visuelle des acteurs reste pour `NS-SCENES-V1-96 — Cinematic Actor Display Preview Sprite Resolver Prep Contract`.
