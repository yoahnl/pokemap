# Evidence Pack — NS-SCENES-V1-95 bis

Lot : `NS-SCENES-V1-95 bis — Cinematic Backdrop Preview Canvas UX Polish V0`  
Date : 2026-06-07  
Demandeur : Karim  
Objectif : preview backdrop plus canvas-first, proportions proches de l'image cible, timeline conservée, sans runtime.

## Gate 0

Etat initial lu avant édition :

```text
pwd
/Users/karim/Project/pokemonProject

git status --short --untracked-files=all
<clean>

git branch --show-current
main

git diff --stat
<empty>

git diff --name-only
<empty>
```

Derniers commits lus au départ :

```text
5b6822e7 feat(map_editor): refactor UI, add cinematic backdrop preview, and update tests
adc0b197 update selbrume
35415a41 feat(map_editor): smooth left sidebar transitions & refactored narrative studio quick actions
0f1cce5c Merge branch 'feature/stabilize-sidebar'
cf774aef ui: stabilize World Explorer sidebar width and card ordering in Narrative Studio
```

Note de sécurité Git : un commit externe `e093213f update selbrume` est apparu pendant les validations. Aucun fichier `selbrume/` ne reste modifié dans le diff final du lot.

## Subagents

Deux subagents ont été utilisés pour auditer les zones indépendantes.

### Pauli — layout/chrome/timeline

Constats utilisés :

- Le split Builder preview/timeline était le levier principal.
- Le chrome `_BackdropHeader`, `_BackdropDiagnostics`, `_BackdropMetaBar` devait être réduit en `Vue scène`.
- La timeline devait rester visible et actionnable.
- Les clés existantes à préserver : `cinematic-builder-timeline-placeholder`, transports, inspector.

Application :

- Chrome replié seulement en `Vue scène`.
- Timeline min conservé à `320 px`, preview min final à `450 px` après tuning responsive.
- Tests historiques duration/resize/mouse probe préservés par la suite Builder complète.

### Averroes — pan/grid/actor overlay

Constats utilisés :

- Pan local en `Offset panTiles`, relatif au focus, sans mutation projet/map.
- Pan appliqué uniquement via `framing.transform.frame`, afin que backdrop, foreground et acteurs restent alignés.
- Clamp du centre visible selon la taille de viewport et le zoom.
- Grille à séparer du border : scene view sans grille par défaut, border conservé.

Application :

- `CinematicBackdropPreviewFramingState.panTiles`.
- `_clampCenterTile`.
- `_dragDeltaToPanTiles`.
- `paintGrid` / `paintBorder` séparés dans les renderers tile/layer.

## Design Gate Q1-Q32

Q1. Canvas plus dominant en `Vue scène` ? OK.  
Q2. Timeline toujours visible ? OK.  
Q3. Timeline toujours actionnable ? OK, suite Builder complète verte.  
Q4. Inspector conservé ? OK.  
Q5. Transports reset/play/stop conservés disabled ? OK.  
Q6. Mode `Carte entière` conservé ? OK.  
Q7. Mode `Vue scène` conservé ? OK.  
Q8. Zoom local conservé ? OK.  
Q9. Reset zoom conservé ? OK.  
Q10. Nouveau reset/recentrage local ? OK.  
Q11. Pan par drag local ? OK.  
Q12. Pan borné ? OK, test pur `clamps scene view pan in tile units`.  
Q13. Pan non persistant ? OK, tests non-mutation.  
Q14. Grille masquée par défaut en `Vue scène` ? OK.  
Q15. Toggle grille local ? OK.  
Q16. Border map conservé sans grille ? OK via `paintBorder`.  
Q17. Détails secondaires repliés ? OK.  
Q18. Détails accessibles ? OK via `cinematic-builder-map-backdrop-details-toggle`.  
Q19. Backdrop tile renderer préservé ? OK.  
Q20. Backdrop layer renderer préservé ? OK.  
Q21. Path Studio/eau non régressé ? OK, test V1-94 bis vert.  
Q22. Actor Display V1-92 préservé ? OK.  
Q23. Acteurs alignés après zoom ? OK.  
Q24. Acteurs alignés après pan ? OK.  
Q25. Pas de runtime ? OK sur diff.  
Q26. Pas de Flame ? OK sur diff.  
Q27. Pas de playback ? OK sur diff.  
Q28. Pas de sprite acteur final ? OK.  
Q29. Pas de `MapCanvas` complet ? OK sur diff.  
Q30. Pas de mutation projet/map ? OK, tests `toJson`.  
Q31. Pas de donnée Selbrume ? OK, diff final hors `selbrume`.  
Q32. Visual Gate 1663x926 générée ? OK.

## Code généré — snippets exacts

### Framing state local

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

### Clamp du centre visible

```dart
final visibleTilesX = viewportSize.width / (tilePixelWidth * scale);
final visibleTilesY = viewportSize.height / (tilePixelHeight * scale);
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

### Drag pan local

```dart
GestureDetector(
  behavior: HitTestBehavior.opaque,
  onPanUpdate: isSceneMode && onFramingPanChanged != null
      ? (details) {
          onFramingPanChanged!(
            framing.panTiles +
                _dragDeltaToPanTiles(
                  details.delta,
                  framing.transform.frame,
                  plan.mapWidth,
                  plan.mapHeight,
                ),
          );
        }
      : null,
  child: RepaintBoundary(
    key: const ValueKey(
      'cinematic-builder-map-backdrop-bitmap-viewport',
    ),
```

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

### Controls scene view

```dart
PokeMapIconButton(
  key: const ValueKey('cinematic-builder-map-backdrop-reset-view'),
  tooltip: 'Recentrer la vue',
  size: buttonSize,
  variant: PokeMapIconButtonVariant.soft,
  onPressed: canAdjustSceneOptions ? onResetView : null,
  icon: const Icon(CupertinoIcons.scope),
),
PokeMapIconButton(
  key: const ValueKey('cinematic-builder-map-backdrop-grid-toggle'),
  tooltip: state.showGrid ? 'Masquer la grille' : 'Afficher la grille',
  size: buttonSize,
  variant: PokeMapIconButtonVariant.soft,
  onPressed: canAdjustSceneOptions && onGridChanged != null
      ? () => onGridChanged!(!state.showGrid)
      : null,
  icon: Icon(
    state.showGrid ? CupertinoIcons.grid : CupertinoIcons.square,
  ),
),
```

### Renderers : grille et border séparés

```dart
const CinematicMapBackdropLayerRenderPainter({
  required this.plan,
  required this.palette,
  this.paintGrid = true,
  this.paintBorder = true,
});
```

```dart
const CinematicMapBackdropTileRenderPainter({
  required this.plan,
  required this.palette,
  this.paintGrid = true,
  this.paintBorder = true,
});
```

### Split final preview/timeline

```dart
const _builderBackdropPreviewMinHeight = 450.0;
const _builderBackdropPreviewMaxHeight = 560.0;
const _builderBackdropTimelineMinHeight = 320.0;
const _builderBackdropTimelineMaxHeight = 520.0;
const _builderBackdropTimelinePreferredShare = 0.40;
```

## Tests ajoutés

Nouveaux tests dans `packages/map_editor/test/cinematic_builder_workspace_test.dart` :

- `renders a larger canvas-first scene preview with compact backdrop chrome`
- `expands and collapses backdrop details without mutating the project`
- `pans the scene view locally by dragging the backdrop viewport`
- `clamps scene view pan in tile units`
- `resets scene view pan and zoom without mutating cinematic data`
- `keeps actor placeholders aligned after scene framing pan`
- `keeps grid hidden by default in scene view and toggles it locally`
- `captures V1-95-bis cinematic backdrop canvas ux polish visual gate when requested`

## RED / GREEN

RED utile :

```text
flutter test --reporter=compact test/cinematic_builder_workspace_test.dart --plain-name 'renders a larger canvas-first scene preview with compact backdrop chrome'
Expected: a value greater than or equal to <300>
  Actual: <115.0>
```

Régression détectée pendant tuning responsive :

```text
flutter test --reporter=compact test/cinematic_builder_workspace_test.dart
Expected: a value greater than or equal to <300>
  Actual: <254.0>
```

Résolution : seuil preview final `450.0`, qui garde le test de proportions vert et remet les interactions duration/resize vertes.

GREEN final ciblé :

```text
flutter test --reporter=compact test/cinematic_builder_workspace_test.dart --name 'renders a larger canvas-first scene preview|expands and collapses backdrop details|pans the scene view locally|clamps scene view pan|resets scene view pan and zoom|keeps actor placeholders aligned after scene framing pan|keeps grid hidden by default'
00:05 +7: All tests passed!
```

## Commandes de validation

```text
flutter analyze --no-fatal-infos lib/src/ui/canvas/cinematics/cinematic_backdrop_preview_framing.dart lib/src/ui/canvas/cinematics/cinematic_map_backdrop_preview_panel.dart lib/src/ui/canvas/cinematics/cinematic_map_backdrop_viewport_transform.dart lib/src/ui/canvas/cinematics/cinematic_map_backdrop_layer_renderer.dart lib/src/ui/canvas/cinematics/cinematic_actor_display_preview_overlay.dart lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart lib/src/ui/canvas/cinematics/cinematics_library_workspace.dart lib/src/ui/design_system/pokemap_dashboard_primitives.dart test/cinematic_builder_workspace_test.dart test/cinematics_library_workspace_test.dart
No issues found! (ran in 1.4s)
```

```text
flutter test --reporter=compact test/cinematic_builder_workspace_test.dart
00:27 +188: All tests passed!
```

```text
flutter test --reporter=compact test/cinematics_library_workspace_test.dart
00:06 +21: All tests passed!
```

```text
dart test --reporter=compact test/cinematic_actor_display_preview_model_test.dart test/cinematic_map_backdrop_preview_model_test.dart test/cinematic_stage_map_source_catalog_test.dart test/cinematic_asset_test.dart test/project_manifest_cinematics_test.dart
00:00 +74: All tests passed!
```

```text
dart analyze
Analyzing map_core...
No issues found!
```

```text
flutter test --update-goldens --dart-define=NS_SCENES_V1_95_BIS_CAPTURE_CINEMATIC_BACKDROP_CANVAS_UX=true --reporter=compact test/cinematic_builder_workspace_test.dart --plain-name 'captures V1-95-bis cinematic backdrop canvas ux polish visual gate when requested'
00:02 +1: All tests passed!
```

```text
flutter test --dart-define=NS_SCENES_V1_95_BIS_CAPTURE_CINEMATIC_BACKDROP_CANVAS_UX=true --reporter=compact test/cinematic_builder_workspace_test.dart --plain-name 'captures V1-95-bis cinematic backdrop canvas ux polish visual gate when requested'
00:02 +1: All tests passed!
```

Global `map_editor` :

```text
flutter analyze
352 issues found.
```

Signal utile : l'échec global est hors lot, concentré sur dette Pokemon SDK et infos/warnings historiques. L'analyse ciblée des fichiers touchés est verte.

## Visual evidence

```text
ls -l reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_95_bis_cinematic_backdrop_preview_canvas_ux_polish_v0.png
-rw-r--r--  1 karim  staff  225821 Jun  7 19:44 reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_95_bis_cinematic_backdrop_preview_canvas_ux_polish_v0.png

file reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_95_bis_cinematic_backdrop_preview_canvas_ux_polish_v0.png
PNG image data, 1663 x 926, 8-bit/color RGBA, non-interlaced

shasum -a 256 reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_95_bis_cinematic_backdrop_preview_canvas_ux_polish_v0.png
c9253cf557371ee0a1274f8de7d5571261e0119dddfe76371d02d09d70f70e5c
```

## Anti-scope exact

```text
git diff --name-only -- packages/map_runtime packages/map_gameplay packages/map_battle examples selbrume
<empty>
```

```text
git diff -U0 -- packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_backdrop_preview_framing.dart packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_map_backdrop_preview_panel.dart packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_map_backdrop_layer_renderer.dart packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_map_backdrop_tile_renderer.dart | rg -n "Color\\(0x|Colors\\."
<no match>
```

```text
git diff -U0 -- packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_backdrop_preview_framing.dart packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_map_backdrop_preview_panel.dart packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_map_backdrop_layer_renderer.dart packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_map_backdrop_tile_renderer.dart | rg -n "Flame|flame|playback|MapCanvas|Selbrume|readAsBytes|gpt-image|image generation|Sprite|sprite"
<no match>
```

## Roadmaps

Mis à jour :

- `reports/narrativeStudio/scenes/road_map_scenes.md`
- `reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md`

Résultat :

- `NS-SCENES-V1-95 bis — Cinematic Backdrop Preview Canvas UX Polish V0` proposé DONE.
- Prochain lot exact maintenu : `NS-SCENES-V1-96 — Cinematic Actor Display Preview Sprite Resolver Prep Contract`.

## Diff hygiene et status final

```text
git diff --check
<no output, exit 0>
```

```text
git status --short --untracked-files=all
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
