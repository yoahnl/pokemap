# NS-SCENES-V1-87 — Evidence Pack

## 1. Gate 0 complet

```text
pwd
/Users/karim/Project/pokemonProject
```

```text
git branch --show-current
main
```

```text
git status --short --untracked-files=all
(aucune sortie)
```

```text
git diff --stat
(aucune sortie)
```

```text
git diff --name-only
(aucune sortie)
```

```text
git log --oneline -n 15
fd10cce7 feat(narrative): auto-commit changes
c730bef3 feat(narrative): auto-commit changes
3b73a8fd feat(narrative): auto-commit changes
587b47f6 update selbrume
50a43df8 feat(narrative): add cinematic map backdrop preview model, tests, and roadmap updates (NS-SCENES-V1-83)
c76550a6 feat(narrative): update cinematic workspaces, tests, and roadmap reports (NS-SCENES-V1-82)
e32d5f2a update screenshot failures for ns_scenes_v1_29_storyline_step_scene_link_v0
1b311e81 feat(narrative): update cinematic builder workspace (NS-SCENES-V1-29-81)
122fe0c7 feat(narrative): update cinematic builder workspace (NS-SCENES-V1-81-BIS)
747aa6e6 feat(narrative): add cinematic builder workspace updates and test failure assets (NS-SCENES-V1-35)
2da49606 feat(narrative): add cinematic actor appearance readiness drift diagnostics polish v0 (NS-SCENES-V1-81)
eea6dbff feat(narrative): add cinematic character library picker v0 (NS-SCENES-V1-80)
eb7d47aa feat(narrative): add cinematic character library binding core model v0 (NS-SCENES-V1-79)
92a6c95e feat(narrative): add cinematic character library binding prep contract (NS-SCENES-V1-78)
d5113ec2 feat(narrative): add cinematic stage map entity event pickers v0 (NS-SCENES-V1-77)
```

## 2. Liste des fichiers lus

```text
AGENTS.md
agent_rules.md
skills/README.md
/Users/karim/.codex/attachments/b411b502-a685-45a2-ae10-a0ce3a044960/pasted-text.txt
reports/narrativeStudio/scenes/road_map_scenes.md
reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
reports/narrativeStudio/scenes/ns_scenes_v1_86_cinematic_map_backdrop_visual_composition_polish_v0.md
reports/narrativeStudio/scenes/ns_scenes_v1_86_evidence_pack.md
reports/narrativeStudio/scenes/ns_scenes_v1_85_cinematic_map_backdrop_visual_primitives_v0.md
reports/narrativeStudio/scenes/ns_scenes_v1_84_cinematic_map_backdrop_preview_renderer_v0.md
packages/map_core/lib/src/models/map_data.dart
packages/map_core/lib/src/models/map_layer.dart
packages/map_core/lib/src/models/project_manifest.dart
packages/map_core/lib/src/read_models/cinematic_map_backdrop_preview_model.dart
packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_map_backdrop_preview_panel.dart
packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_map_backdrop_visual_primitives_painter.dart
packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart
packages/map_editor/lib/src/ui/canvas/cinematics/cinematics_library_workspace.dart
packages/map_editor/lib/src/ui/canvas/map_canvas.dart
packages/map_editor/lib/src/ui/canvas/map_canvas/map_canvas_assets.dart
packages/map_editor/lib/src/ui/canvas/map_canvas/map_grid_painter.dart
packages/map_editor/lib/src/features/surface_painter/surface_layer_static_preview.dart
packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart
packages/map_runtime/lib/src/presentation/flame/runtime_map_game.dart
packages/map_runtime/lib/src/presentation/flame/map_layers_component.dart
packages/map_runtime/lib/src/application/scene_runtime/scene_cinematic_runtime_awaitable_adapter.dart
packages/map_runtime/lib/map_runtime.dart
```

## 3. Notes des sub-agents / passes specialisees

Sub-agent A — MapData / Layer Rendering Semantics :

```text
Faits : MapData porte layers + placedElements + entities/connections/warps/triggers/gameplayZones/events separes.
Layers a rendre : TileLayer, MapPlacedElement lies aux TileLayer, SurfaceLayer resoluble, TerrainLayer resoluble, PathLayer resoluble.
Layers a exclure : CollisionLayer, EnvironmentLayer direct, ObjectLayer direct V0, entities/events/triggers/warps/connections/gameplayZones.
Risque : ObjectLayer vs placedElements n'a pas un contrat bitmap clair.
Recommandation : renderer read-only par instructions bitmap, local au Cinematic Builder.
```

Sub-agent B — Tileset / Asset Resolution :

```text
Pipeline : ProjectTilesetEntry.relativePath persiste l'asset, ProjectSettings porte tileWidth/tileHeight, EditorNotifier.resolve path via ProjectWorkspace, MapCanvas charge via _TilesetImageCache.
Points reutilisables : ProjectWorkspace, getTilesetAbsolutePathById, collecte IDs tileset du canvas, transparentColor, bounds checks.
Risques : caches prives/dupliques, pas d'invalidation centrale, file/decode dans build si mal copie.
Recommandation : registry editor dedie hors build/paint, sortie immutable par tileset.
```

Sub-agent C — Map Editor Renderer / Extraction Audit :

```text
Composants : MapCanvas, MapGridPainter, surface atlas preview, entity visuals, foreground split.
Reutilisables : ordre MapGridPainter comme reference, helpers purs sous contrat, surface atlas preview.
Non reutilisables bruts : MapCanvas complet, _TilesetImageCache prive, painter cinematic primitives pour vraie map.
Option recommandee : renderer cinematic dedie read-only, alimente par helpers existants.
```

Sub-agent D — Runtime / Flame Anti-scope :

```text
Risques : RuntimeMapGame/PlayableMapGame importeraient Flame, GameState runtime, camera, input, PNJ, dialogue, battle, save/load.
Symboles interdits : PlayableMapGame, RuntimeMapGame, GameWidget, FlameGame, CameraComponent, MapLayersComponent, PlayerComponent, SceneCinematicRuntimeAwaitableAdapter, package:map_runtime/map_runtime.dart.
Frontiere : map_editor + map_core + CustomPainter, sans world/camera Flame.
Recommandation : projection visuelle editor-only, aucun runtime.
```

Sub-agent E — UX / Product Reviewer :

```text
Verdict : V1-88 est acceptable sans playback/acteurs si l'utilisateur reconnait sa map.
Wording : Carte du projet (statique), Decor seul, Sans acteurs, Sans lecture.
Seuil : vraies tiles/assets, ordre/opacite/proportions, fallback clair.
Risque UX : vraie map statique percue comme scene jouee si limites non visibles.
```

## 4. Resultats des recherches rg structurantes

```text
rg -n "class MapData|List<MapLayer>|placedElements|entities|connections|warps|triggers|gameplayZones|events|sealed class MapLayer|TileLayer|CollisionLayer|TerrainLayer|PathLayer|SurfaceLayer|ObjectLayer|EnvironmentLayer|opacity|isVisible" packages/map_core/lib/src/models/map_data.dart packages/map_core/lib/src/models/map_layer.dart
packages/map_core/lib/src/models/map_layer.dart:24:sealed class MapLayer with _$MapLayer {
packages/map_core/lib/src/models/map_layer.dart:32:    @Default(true) bool isVisible,
packages/map_core/lib/src/models/map_layer.dart:33:    @Default(1.0) double opacity,
packages/map_core/lib/src/models/map_layer.dart:35:  }) = TileLayer;
packages/map_core/lib/src/models/map_layer.dart:41:    @Default(true) bool isVisible,
packages/map_core/lib/src/models/map_layer.dart:42:    @Default(1.0) double opacity,
packages/map_core/lib/src/models/map_layer.dart:44:  }) = CollisionLayer;
packages/map_core/lib/src/models/map_layer.dart:50:    @Default(true) bool isVisible,
packages/map_core/lib/src/models/map_layer.dart:51:    @Default(1.0) double opacity,
packages/map_core/lib/src/models/map_layer.dart:53:  }) = TerrainLayer;
packages/map_core/lib/src/models/map_layer.dart:60:    @Default(true) bool isVisible,
packages/map_core/lib/src/models/map_layer.dart:61:    @Default(1.0) double opacity,
packages/map_core/lib/src/models/map_layer.dart:67:  }) = PathLayer;
packages/map_core/lib/src/models/map_layer.dart:74:    @Default(true) bool isVisible,
packages/map_core/lib/src/models/map_layer.dart:75:    @Default(1.0) double opacity,
packages/map_core/lib/src/models/map_layer.dart:78:  }) = SurfaceLayer;
packages/map_core/lib/src/models/map_layer.dart:84:    @Default(true) bool isVisible,
packages/map_core/lib/src/models/map_layer.dart:85:    @Default(1.0) double opacity,
packages/map_core/lib/src/models/map_layer.dart:86:  }) = ObjectLayer;
packages/map_core/lib/src/models/map_layer.dart:93:    @Default(true) bool isVisible,
packages/map_core/lib/src/models/map_layer.dart:94:    @Default(1.0) double opacity,
packages/map_core/lib/src/models/map_layer.dart:96:      fromJson: decodeEnvironmentLayerContent,
packages/map_core/lib/src/models/map_layer.dart:97:      toJson: encodeEnvironmentLayerContent,
packages/map_core/lib/src/models/map_layer.dart:99:    @Default(EnvironmentLayerContent.emptyContent)
packages/map_core/lib/src/models/map_layer.dart:100:    EnvironmentLayerContent content,
packages/map_core/lib/src/models/map_layer.dart:102:  }) = EnvironmentLayer;
packages/map_core/lib/src/models/map_data.dart:21:class MapData with _$MapData {
packages/map_core/lib/src/models/map_data.dart:29:    @Default([]) List<MapLayer> layers,
packages/map_core/lib/src/models/map_data.dart:30:    @Default([]) List<MapPlacedElement> placedElements,
packages/map_core/lib/src/models/map_data.dart:31:    @Default([]) List<MapEntity> entities,
packages/map_core/lib/src/models/map_data.dart:32:    @Default([]) List<MapConnection> connections,
packages/map_core/lib/src/models/map_data.dart:33:    @Default([]) List<MapWarp> warps,
packages/map_core/lib/src/models/map_data.dart:34:    @Default([]) List<MapTrigger> triggers,
packages/map_core/lib/src/models/map_data.dart:37:    /// Séparées des triggers (logiques scriptées) et des layers visuelles.
packages/map_core/lib/src/models/map_data.dart:38:    @Default([]) List<MapGameplayZone> gameplayZones,
packages/map_core/lib/src/models/map_data.dart:41:    @Default([]) List<MapEventDefinition> events,
packages/map_core/lib/src/models/map_data.dart:107:    @Default(1.0) double opacity,
```

```text
rg -n "class ProjectManifest|tilesets|ProjectSettings|tileWidth|tileHeight|ProjectMapEntry|ProjectTilesetEntry|relativePath|TilesetSourceRect|TilesetVisualFrame|ProjectElementEntry|ProjectTerrainPreset|ProjectPathPreset|surfaceCatalog" packages/map_core/lib/src/models/project_manifest.dart
35:/// JSON → [ProjectSurfaceCatalog] pour [ProjectManifest.surfaceCatalog] (Lot 49).
42:    throw const ValidationException('surfaceCatalog must be a JSON object');
311:class ProjectManifest with _$ProjectManifest {
316:    required List<ProjectMapEntry> maps,
319:    required List<ProjectTilesetEntry> tilesets,
321:    @Default([]) List<ProjectElementEntry> elements,
324:    @Default([]) List<ProjectTerrainPreset> terrainPresets,
325:    @Default([]) List<ProjectPathPreset> pathPresets,
382:    @Default(ProjectSettings()) ProjectSettings settings,
387:      name: 'surfaceCatalog',
391:    ProjectSurfaceCatalog surfaceCatalog,
427:class ProjectSettings with _$ProjectSettings {
429:  const factory ProjectSettings({
430:    @Default(16) int tileWidth,
431:    @Default(16) int tileHeight,
446:  }) = _ProjectSettings;
448:  factory ProjectSettings.fromJson(Map<String, dynamic> json) =>
449:      _$ProjectSettingsFromJson(json);
469:class ProjectMapEntry with _$ProjectMapEntry {
470:  const factory ProjectMapEntry({
473:    required String relativePath,
477:  }) = _ProjectMapEntry;
479:  factory ProjectMapEntry.fromJson(Map<String, dynamic> json) =>
480:      _$ProjectMapEntryFromJson(json);
504:    required String relativePath,
534:class ProjectTilesetEntry with _$ProjectTilesetEntry {
535:  const factory ProjectTilesetEntry({
538:    required String relativePath,
542:    /// Dossier de la bibliothèque tilesets (hiérarchie dédiée, distincte des groupes de carte).
554:  }) = _ProjectTilesetEntry;
556:  factory ProjectTilesetEntry.fromJson(Map<String, dynamic> json) =>
557:      _$ProjectTilesetEntryFromJson(json);
569:    required List<TilesetVisualFrame> frames,
578:class TilesetSourceRect with _$TilesetSourceRect {
579:  const factory TilesetSourceRect({
584:  }) = _TilesetSourceRect;
586:  factory TilesetSourceRect.fromJson(Map<String, dynamic> json) =>
587:      _$TilesetSourceRectFromJson(json);
594:class TilesetVisualFrame with _$TilesetVisualFrame {
596:  const factory TilesetVisualFrame({
598:    required TilesetSourceRect source,
602:  }) = _TilesetVisualFrame;
604:  factory TilesetVisualFrame.fromJson(Map<String, dynamic> json) =>
605:      _$TilesetVisualFrameFromJson(json);
635:class ProjectElementEntry with _$ProjectElementEntry {
637:  const factory ProjectElementEntry({
645:    required List<TilesetVisualFrame> frames,
661:  }) = _ProjectElementEntry;
663:  factory ProjectElementEntry.fromJson(Map<String, dynamic> json) =>
664:      _$ProjectElementEntryFromJson(jsonCoerceLegacySourceToFrames(json));
668:class ProjectTerrainPreset with _$ProjectTerrainPreset {
669:  const factory ProjectTerrainPreset({
677:  }) = _ProjectTerrainPreset;
679:  factory ProjectTerrainPreset.fromJson(Map<String, dynamic> json) =>
680:      _$ProjectTerrainPresetFromJson(json);
688:    required List<TilesetVisualFrame> frames,
702:class ProjectPathPreset with _$ProjectPathPreset {
703:  const factory ProjectPathPreset({
711:  }) = _ProjectPathPreset;
713:  factory ProjectPathPreset.fromJson(Map<String, dynamic> json) =>
714:      _$ProjectPathPresetFromJson(json);
724:    required List<TilesetVisualFrame> frames,
801:extension TilesetVisualFrameListX on List<TilesetVisualFrame> {
802:  TilesetVisualFrame get primaryFrame {
804:      throw StateError('At least one TilesetVisualFrame is required');
809:  TilesetSourceRect get primarySource => primaryFrame.source;
861:    required TilesetSourceRect source,
```

```text
rg -n "buildCinematicMapBackdropPreviewModel|_projectVisualPrimitives|_projectVisualLayers|TileLayer|TerrainLayer|PathLayer|SurfaceLayer|ObjectLayer|EnvironmentLayer|_missingTilesetIds|visualPrimitives|viewportRecommendation" packages/map_core/lib/src/read_models/cinematic_map_backdrop_preview_model.dart
192:    required this.viewportRecommendation,
194:    List<CinematicMapBackdropVisualPrimitive> visualPrimitives =
198:        visualPrimitives =
200:          visualPrimitives,
214:  final CinematicMapBackdropViewportRecommendation viewportRecommendation;
216:  final List<CinematicMapBackdropVisualPrimitive> visualPrimitives;
222:CinematicMapBackdropPreviewModel buildCinematicMapBackdropPreviewModel({
235:  final fallbackViewport = _viewportRecommendationFor(
251:      viewportRecommendation: fallbackViewport,
273:      viewportRecommendation: fallbackViewport,
296:      viewportRecommendation: fallbackViewport,
320:      viewportRecommendation: fallbackViewport,
346:      viewportRecommendation: fallbackViewport,
361:  final layers = _projectVisualLayers(mapData);
362:  final visualPrimitives = _projectVisualPrimitives(mapData);
364:  final missingTilesetIds = _missingTilesetIds(
392:    viewportRecommendation: _viewportRecommendationFor(
397:    visualPrimitives: visualPrimitives,
402:List<CinematicMapBackdropVisualPrimitive> _projectVisualPrimitives(
409:    if (layer is TileLayer) {
438:    } else if (layer is TerrainLayer) {
464:    } else if (layer is PathLayer) {
493:    } else if (layer is SurfaceLayer) {
516:    } else if (layer is ObjectLayer) {
547:    } else if (layer is EnvironmentLayer) {
651:  if (layer is TileLayer) {
654:  if (layer is TerrainLayer) {
657:  if (layer is PathLayer) {
660:  if (layer is SurfaceLayer) {
663:  if (layer is ObjectLayer) {
669:List<CinematicMapBackdropLayerPreview> _projectVisualLayers(MapData mapData) {
673:    if (layer is TileLayer) {
690:    } else if (layer is TerrainLayer) {
702:    } else if (layer is PathLayer) {
718:    } else if (layer is SurfaceLayer) {
730:    } else if (layer is ObjectLayer) {
741:    } else if (layer is EnvironmentLayer) {
759:List<String> _missingTilesetIds({
778:    if (layer is TileLayer) {
790:CinematicMapBackdropViewportRecommendation _viewportRecommendationFor({
```

```text
rg -n "class MapCanvas|_TilesetImageCache|_collectLayerTilesetPaths|_collectTilesetTransparentColors|getTilesetAbsolutePathById|MapGridPainter|paintSurfaceLayerAtlasTilePreview|drawImageRect|buildCinematicMapBackdropPreviewModel|stageMaps|backdropPreviewModel" packages/map_editor/lib/src/ui/canvas/map_canvas.dart packages/map_editor/lib/src/ui/canvas/map_canvas/map_canvas_assets.dart packages/map_editor/lib/src/ui/canvas/map_canvas/map_grid_painter.dart packages/map_editor/lib/src/features/editor/state/editor_notifier.dart packages/map_editor/lib/src/features/surface_painter/surface_layer_static_preview.dart packages/map_editor/lib/src/ui/canvas/cinematics/cinematics_library_workspace.dart packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart
packages/map_editor/lib/src/features/surface_painter/surface_layer_static_preview.dart:126:void paintSurfaceLayerAtlasTilePreview({
packages/map_editor/lib/src/features/surface_painter/surface_layer_static_preview.dart:178:      canvas.drawImageRect(
packages/map_editor/lib/src/ui/canvas/cinematics/cinematics_library_workspace.dart:279:      final backdropPreviewModel = _buildBackdropPreviewModel(builderAsset);
packages/map_editor/lib/src/ui/canvas/cinematics/cinematics_library_workspace.dart:283:        stageMaps: widget.project.maps,
packages/map_editor/lib/src/ui/canvas/cinematics/cinematics_library_workspace.dart:287:        backdropPreviewModel: backdropPreviewModel,
packages/map_editor/lib/src/ui/canvas/cinematics/cinematics_library_workspace.dart:432:    return buildCinematicMapBackdropPreviewModel(
packages/map_editor/lib/src/ui/canvas/map_canvas/map_canvas_assets.dart:19:class _TilesetImageCache {
packages/map_editor/lib/src/ui/canvas/map_canvas/map_grid_painter.dart:186:class MapGridPainter extends CustomPainter {
packages/map_editor/lib/src/ui/canvas/map_canvas/map_grid_painter.dart:222:  MapGridPainter({
packages/map_editor/lib/src/ui/canvas/map_canvas/map_grid_painter.dart:321:        paintSurfaceLayerAtlasTilePreview(
packages/map_editor/lib/src/ui/canvas/map_canvas/map_grid_painter.dart:896:    canvas.drawImageRect(
packages/map_editor/lib/src/ui/canvas/map_canvas/map_grid_painter.dart:1299:          canvas.drawImageRect(tilesetImage, srcRect, dstRect, tilePaint);
packages/map_editor/lib/src/ui/canvas/map_canvas/map_grid_painter.dart:1540:        canvas.drawImageRect(
packages/map_editor/lib/src/ui/canvas/map_canvas/map_grid_painter.dart:1722:        canvas.drawImageRect(tilesetImage, srcRect, dstRect, layerPaint);
packages/map_editor/lib/src/ui/canvas/map_canvas/map_grid_painter.dart:1915:      canvas.drawImageRect(image, srcRect, dstRect, Paint());
packages/map_editor/lib/src/ui/canvas/map_canvas/map_grid_painter.dart:1917:        canvas.drawImageRect(
packages/map_editor/lib/src/ui/canvas/map_canvas/map_grid_painter.dart:1934:    canvas.drawImageRect(image, srcRect, dstRect, Paint());
packages/map_editor/lib/src/ui/canvas/map_canvas/map_grid_painter.dart:1936:      canvas.drawImageRect(
packages/map_editor/lib/src/ui/canvas/map_canvas/map_grid_painter.dart:2251:    canvas.drawImageRect(
packages/map_editor/lib/src/ui/canvas/map_canvas/map_grid_painter.dart:2320:    canvas.drawImageRect(
packages/map_editor/lib/src/ui/canvas/map_canvas/map_grid_painter.dart:2578:  bool shouldRepaint(covariant MapGridPainter oldDelegate) {
packages/map_editor/lib/src/features/editor/state/editor_notifier.dart:1661:  String? getTilesetAbsolutePathById(String tilesetId) {
packages/map_editor/lib/src/features/editor/state/editor_notifier.dart:2155:    final tilesetPath = getTilesetAbsolutePathById(tilesetId);
packages/map_editor/lib/src/ui/canvas/map_canvas.dart:55:class MapCanvas extends ConsumerStatefulWidget {
packages/map_editor/lib/src/ui/canvas/map_canvas.dart:132:    _tilesetImagesFuture = _TilesetImageCache.loadMany(
packages/map_editor/lib/src/ui/canvas/map_canvas.dart:154:    final tilesetPathsById = _collectLayerTilesetPaths(
packages/map_editor/lib/src/ui/canvas/map_canvas.dart:162:    final transparentColorByTilesetId = _collectTilesetTransparentColors(
packages/map_editor/lib/src/ui/canvas/map_canvas.dart:507:                        painter: MapGridPainter(
packages/map_editor/lib/src/ui/canvas/map_canvas.dart:772:  Map<String, String> _collectLayerTilesetPaths(
packages/map_editor/lib/src/ui/canvas/map_canvas.dart:789:          final p = notifier.getTilesetAbsolutePathById(tilesetId);
packages/map_editor/lib/src/ui/canvas/map_canvas.dart:799:        final path = notifier.getTilesetAbsolutePathById(tilesetId);
packages/map_editor/lib/src/ui/canvas/map_canvas.dart:812:          final path = notifier.getTilesetAbsolutePathById(tilesetId);
packages/map_editor/lib/src/ui/canvas/map_canvas.dart:821:      final brushPath = notifier.getTilesetAbsolutePathById(brushTilesetId);
packages/map_editor/lib/src/ui/canvas/map_canvas.dart:831:          notifier.getTilesetAbsolutePathById(pathTilesetId);
packages/map_editor/lib/src/ui/canvas/map_canvas.dart:844:              notifier.getTilesetAbsolutePathById(frameTilesetId);
packages/map_editor/lib/src/ui/canvas/map_canvas.dart:856:            notifier.getTilesetAbsolutePathById(terrainTilesetId);
packages/map_editor/lib/src/ui/canvas/map_canvas.dart:868:              notifier.getTilesetAbsolutePathById(frameTilesetId);
packages/map_editor/lib/src/ui/canvas/map_canvas.dart:878:        final pathTilesetPath = notifier.getTilesetAbsolutePathById(tilesetId);
packages/map_editor/lib/src/ui/canvas/map_canvas.dart:890:              notifier.getTilesetAbsolutePathById(frameTilesetId);
packages/map_editor/lib/src/ui/canvas/map_canvas.dart:906:                notifier.getTilesetAbsolutePathById(frameTilesetId);
packages/map_editor/lib/src/ui/canvas/map_canvas.dart:917:  Map<String, TilesetTransparentColor> _collectTilesetTransparentColors(
packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart:238:    required this.stageMaps,
packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart:242:    this.backdropPreviewModel,
packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart:271:  final List<ProjectMapEntry> stageMaps;
packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart:275:  final CinematicMapBackdropPreviewModel? backdropPreviewModel;
packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart:370:                          hasBackdrop: widget.backdropPreviewModel != null,
packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart:386:                                backdropPreviewModel:
packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart:387:                                    widget.backdropPreviewModel,
packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart:437:                      stageMaps: widget.stageMaps,
packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart:1649:    this.backdropPreviewModel,
packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart:1657:  final CinematicMapBackdropPreviewModel? backdropPreviewModel;
packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart:1672:          final backdropPreviewModel = this.backdropPreviewModel;
packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart:1673:          if (backdropPreviewModel != null) {
packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart:1675:              model: backdropPreviewModel,
packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart:3783:    required this.stageMaps,
packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart:3808:  final List<ProjectMapEntry> stageMaps;
packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart:3850:              stageMaps: stageMaps,
packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart:3929:    required this.stageMaps,
packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart:3947:  final List<ProjectMapEntry> stageMaps;
packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart:3968:      maps: stageMaps,
packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart:3984:            stageMaps: stageMaps,
packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart:4032:    required this.stageMaps,
packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart:4038:  final List<ProjectMapEntry> stageMaps;
packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart:4050:    final selectedMap = _stageMapForId(widget.stageMaps, widget.asset.mapId);
packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart:4068:              onTap: widget.stageMaps.isEmpty
packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart:4072:                cursor: widget.stageMaps.isEmpty
packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart:4119:        if (widget.stageMaps.isEmpty) ...[
packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart:4134:    final roots = _buildMapTree(widget.groups, widget.stageMaps);
```

```text
rg -n "class PlayableMapGame|class RuntimeMapGame|class MapLayersComponent|SceneCinematicRuntimeAwaitableAdapter|CameraComponent|FlameGame|GameState|map_runtime" packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart packages/map_runtime/lib/src/presentation/flame/runtime_map_game.dart packages/map_runtime/lib/src/presentation/flame/map_layers_component.dart packages/map_runtime/lib/src/application/scene_runtime/scene_cinematic_runtime_awaitable_adapter.dart packages/map_runtime/lib/map_runtime.dart packages/map_editor/lib -g '!*.freezed.dart' -g '!*.g.dart'
packages/map_runtime/lib/map_runtime.dart:1:library map_runtime;
packages/map_runtime/lib/map_runtime.dart:87:        SceneCinematicRuntimeAwaitableAdapter,
packages/map_runtime/lib/src/application/scene_runtime/scene_cinematic_runtime_awaitable_adapter.dart:25:final class SceneCinematicRuntimeAwaitableAdapter {
packages/map_runtime/lib/src/application/scene_runtime/scene_cinematic_runtime_awaitable_adapter.dart:26:  const SceneCinematicRuntimeAwaitableAdapter({
packages/map_runtime/lib/src/presentation/flame/runtime_map_game.dart:9:class RuntimeMapGame extends FlameGame {
packages/map_runtime/lib/src/presentation/flame/map_layers_component.dart:36:class MapLayersComponent extends PositionComponent {
packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart:131:class PlayableMapGame extends FlameGame with KeyboardEvents {
packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart:146:        _gameState = normalizeLoadedGameState(
packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart:148:              ? const GameState(saveId: 'default')
packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart:180:  GameState _gameState;
packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart:518:      _syncGameStateFromWorld(mapIdOverride: _activeMapId);
packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart:529:  GameState get gameStateSnapshot {
packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart:531:      _syncGameStateFromWorld(mapIdOverride: _activeMapId);
packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart:820:    _syncGameStateFromWorld(mapIdOverride: _activeMapId);
packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart:843:  void _syncGameStateFromWorld({String? mapIdOverride}) {
packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart:1238:    _syncGameStateFromWorld();
packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart:1466:    _syncGameStateFromWorld();
packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart:2037:    _syncGameStateFromWorld();
packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart:2215:  /// - la synchronisation de GameState lorsque le flow mutera des flags.
packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart:2278:      onGameStateUpdated: (state) {
packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart:3396:    _syncGameStateFromWorld();
packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart:3597:    _syncGameStateFromWorld();
packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart:3628:      _syncGameStateFromWorld();
packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart:3699:    _syncGameStateFromWorld();
packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart:4304:      // - la sélection se fait sur le vrai GameState runtime, juste avant le
packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart:4358:        () => markSpeciesSeenInGameState(
packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart:4707:        _gameState = result.updatedGameState;
packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart:4771:      _gameState = result.updatedGameState;
packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart:4827:  /// 1. Applique le résultat au vrai GameState runtime
packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart:4843:      _gameState = applyRuntimeBattleOutcomeToGameState(
packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart:4973:    _gameState = applyRuntimeDefeatRecoveryToGameState(
packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart:4997:    _syncGameStateFromWorld(mapIdOverride: _activeMapId);
packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart:5213:      } else if (result.updatedGameState != null) {
packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart:5214:        _gameState = result.updatedGameState!;
packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart:5276:        final adapter = SceneCinematicRuntimeAwaitableAdapter(
packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart:5561:      onGameStateUpdated: (state) {
packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart:6459:      _syncGameStateFromWorld(mapIdOverride: _activeMapId);
packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart:6496:    final loadedState = normalizeLoadedGameState(rawLoadedState);
packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart:6521:      // 4. Restaurer GameState
packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart:6559:      // 11. Synchroniser GameState
packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart:6560:      _syncGameStateFromWorld(mapIdOverride: _activeMapId);
packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart:6797:      _syncGameStateFromWorld(mapIdOverride: _activeMapId);
packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart:6925:      _syncGameStateFromWorld(mapIdOverride: sourceMapId);
packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart:6961:      _syncGameStateFromWorld(mapIdOverride: _activeMapId);
packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart:7111:      _syncGameStateFromWorld(mapIdOverride: _activeMapId);
packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart:8443:      _syncGameStateFromWorld();
packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart:8603:  /// Utilise [CameraComponent.visibleWorldRect] qui tient compte du ratio
packages/map_editor/lib/src/features/narrative/application/cutscene_studio/cutscene_studio_compiler.dart:445:/// sans effet (voir `map_runtime`), au lieu d’un `waitMs` à 0 ms trompeur.
packages/map_editor/lib/src/features/narrative/application/cutscene_studio/cutscene_studio_models.dart:48:/// Doit rester aligné sur [kScenarioActionFlowMerge] (`map_runtime`).
packages/map_editor/lib/src/features/narrative/application/cutscene_studio/cutscene_studio_models.dart:56:/// Doit rester aligné sur [kScenarioActionAuthoringPlaceholder] (`map_runtime`).
packages/map_editor/lib/src/features/dialogue/application/dialogue_preview_runner.dart:2:// Prévisualisation « joueur » sans dépendre de `map_runtime`
packages/map_editor/lib/src/features/dialogue/application/dialogue_yarn_codec.dart:5:// Base algorithmique : alignée sur `packages/map_runtime/.../parse_yarn_dialogue.dart`
packages/map_editor/lib/src/features/narrative/application/step_studio_authoring.dart:465:/// dans ce dépôt : ni `map_gameplay`, ni `map_runtime`, ni les résumés de step
```

## 5. Arbitrage final

Option retenue : Option E hybride.

```text
Créer un petit contrat de rendu read-only pour la preview cinematic.
Résoudre les assets en amont côté editor.
Peindre via un renderer cinematic dédié.
Réutiliser seulement les helpers Map Editor purs et testables.
Ne pas embarquer MapCanvas complet.
Ne pas importer runtime/Flame.
Repousser Actor Display en V1-89.
```

## 6. Hunks complets des roadmaps modifiees

```diff
diff --git a/reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md b/reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
index de1e52e9..dda75ebf 100644
--- a/reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
+++ b/reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
@@ -9,7 +9,7 @@ Le runtime reste indispensable, mais le prochain blocage produit est plus basiqu
 ## Prochain lot exact recommande
 
 ```text
-NS-SCENES-V1-87 — Cinematic Actor Display Preview Prep Contract
+NS-SCENES-V1-88 — Cinematic Map Backdrop Real Tile Renderer V0
 ```
 
 ## Principes
@@ -120,9 +120,27 @@ NS-SCENES-V1-87 — Cinematic Actor Display Preview Prep Contract
 | NS-SCENES-V1-84 | Cinematic Map Backdrop Preview Renderer V0 | editor / preview-sandbox | Brancher le read model V1-83 dans le Cinematic Builder pour afficher un decor map sandbox read-only depuis une `MapData` deja chargee par l'editor. | Pas de runtime/Flame, pas de `PlayableMapGame`, pas de playback, pas d'acteurs rendus, pas de pathfinding/collision, pas de mutation map/projet. | Builder cinematics, snapshot map editor, renderer read-only, tests widget, rapport, screenshot. | DONE : `CinematicMapBackdropPreviewModel` passe au Builder, renderer sandbox read-only visible, fallbacks humains tous statuts, diagnostics, snapshot non destructive, Visual Gate, tests builder/library/core et analyse ciblee verts. | Refaire un runtime dans l'editor ; casser les proportions demandees par Karim ; rendre des acteurs ou collisions trop tot. | DONE : V1-84 affiche enfin un decor de map statique dans le Builder ; V1-84 ne lance toujours pas la cinematique. | V1-83. |
 | NS-SCENES-V1-85 | Cinematic Map Backdrop Visual Primitives V0 | core / editor preview-sandbox | Remplacer le rendu de bandes V1-84 par des primitives visuelles spatiales derivees de `MapData` reelle : cellules, chemins, surfaces, ancres objet/environnement et fallback summary honnete. | Pas de runtime/Flame, pas de `PlayableMapGame`, pas de playback, pas d'acteurs rendus, pas de fake tiles, pas de pathfinding/collision, pas de mutation map/projet. | Read model backdrop, panel/painter cinematic, tests widget/core, rapport, screenshot. | DONE : `visualPrimitives`, mini renderer CustomPainter tokenise, grille/cellules visibles, fallbacks V1-84 preserves, Visual Gate, tests builder/library/core et analyse ciblee verts. | Inventer une fake map ; brancher MapCanvas complet ; casser les proportions preview/timeline. | DONE : V1-85 rend le decor plus map-like sans rendre une cinematique jouable. | V1-84. |
 | NS-SCENES-V1-86 | Cinematic Map Backdrop Visual Composition Polish V0 | editor / ui-polish | A la demande de Karim, corriger la composition du backdrop avant Actor Display : viewport map plus grand/proportionnel, rail meta/legende secondaire, grille/primitives plus lisibles, preview/timeline equilibrees. | Pas de tiles/assets finaux, runtime/Flame, `PlayableMapGame`, playback, acteurs rendus, pathfinding/collision, mutation map/projet, donnees Selbrume ou image IA. | Builder cinematics, panel/painter backdrop, tests widget, rapport, screenshot. | DONE : test RED/GREEN viewport >= 220 px, ratio map preserve, legende secondaire, diagnostics sans overflow, Visual Gate 1663x926, tests builder/library/core cibles et analyse ciblee verts. | Trop reduire la timeline ; vendre une preview runtime ; agrandir les badges au lieu de la carte ; oublier le rapport avec code. | DONE : V1-86 rend le decor beaucoup plus lisible ; V1-86 ne rend toujours pas la cinematique jouable. | V1-85. |
-| NS-SCENES-V1-87 | Cinematic Actor Display Preview Prep Contract | doc-only / architecture-review | Cadrer l'affichage statique futur des acteurs dans la preview backdrop lisible, en decidant sources, apparences, positions et diagnostics avant tout renderer actor. | Pas de rendu acteur actif, pas de runtime/Flame, pas de playback/interpolation, pas de pathfinding/collision, pas de donnee Selbrume. | Rapport V1-87, roadmaps. | TODO : contrat acteurs preview, sources actor bindings/placements/Character Library, anti-scope runtime. | Poser des acteurs sur une projection encore trop abstraite ; confondre actor display et gameplay runtime. | TODO : contrat pret pour un renderer actor statique futur. | V1-86. |
+| NS-SCENES-V1-87 | Cinematic Map Backdrop Real Tile Rendering Prep Contract | doc-only / architecture-review | Cadrer le rendu reel des tiles/assets dans la preview cinematic avant tout code : audit MapData/layers, tilesets, asset resolution, rendu Map Editor et anti-scope runtime. | Pas de code produit, package, widget, test, screenshot, renderer, vraie map affichee, runtime/Flame, playback, acteurs rendus, fake tiles ou donnee Selbrume. | Rapport V1-87, Evidence Pack, roadmaps. | DONE : sub-agents A-E, Option E retenue, contrat futur renderer V1-88, asset registry editor-only recommande, layer ordering/fallbacks/tests futurs cadres. | Brancher MapCanvas complet ; charger les images dans build/paint ; utiliser le runtime ; poser des acteurs sur un decor abstrait. | DONE : contrat pret pour V1-88, sans modifier les packages. | V1-86. |
+| NS-SCENES-V1-88 | Cinematic Map Backdrop Real Tile Renderer V0 | editor / preview-sandbox | Afficher les vraies tiles/assets de la map dans le Cinematic Builder via un renderer read-only editor-only, avec images resolues en amont et diagnostics visibles. | Pas de runtime/Flame, `PlayableMapGame`, playback, acteurs rendus, pathfinding/collision, mutation map/projet, donnees Selbrume ou image IA. | Builder cinematics, renderer cinematic, asset registry/cache editor-only, tests widget, rapport, Visual Gate. | TODO : rendu `TileLayer` + placements visuels + surfaces resolubles, fallbacks diagnostics, proportions V1-86 preservees, tests/Visual Gate. | Divergence visuelle avec Map Editor ; cache image perime ; fallback silencieux ; timeline reduite. | TODO : vraie map statique reconnaissable sans lancer la cinematique. | V1-87. |
+| NS-SCENES-V1-89 | Cinematic Actor Display Preview Prep Contract | doc-only / architecture-review | Cadrer l'affichage statique futur des acteurs une fois le vrai decor map rendu : sources actor bindings/placements/Character Library, positions, apparences et diagnostics. | Pas de rendu acteur actif, runtime/Flame, playback/interpolation, pathfinding/collision, donnee Selbrume ou mutation runtime. | Rapport V1-89, roadmaps. | TODO : contrat acteurs preview et anti-scope runtime. | Confondre acteur statique et gameplay ; cacher les gaps Character Library ; casser le decor V1-88. | TODO : contrat pret pour renderer actor statique futur. | V1-88. |
 | NS-SCENES-V1-90 | Cinematic Timeline Scroll / Visibility Polish V0 | editor / ui-polish | Backlog futur : polir la visibilite des blocs/repere/selection quand les interactions clavier ou souris placent l'element cible hors de la vue utile. | Pas de playback, seek runtime, scrubber runtime, transport fonctionnel, drag/resize/reorder, mutation JSON, runtime, zoom temporel ou changement de modele. | Builder cinematics, tests widget, rapport, screenshot. | TODO : scroll automatique/visibilite controles, proportions timeline preservees, selection/probe non mutants. | Casser les proportions visees ; confondre scroll de vue et navigation temporelle ; ajouter un pouvoir de montage. | TODO : visibilite plus fiable, sans nouveau pouvoir temporel. | Backlog post Character Library. |
 
+## Mise a jour V1-87
+
+Statut : `NS-SCENES-V1-87 — Cinematic Map Backdrop Real Tile Rendering Prep Contract` est DONE.
+
+Demande : Karim a demande de cadrer le rendu reel des tiles/assets avant l'Actor Display. L'ancien prochain lot V1-87 Actor Display est donc repousse a V1-89, et V1-88 devient le renderer statique de vraie map.
+
+Decision : le futur rendu doit rester editor-only/read-only, sans runtime ni Flame. Option E retenue : petit contrat de rendu cinematic dedie, images tileset resolues en amont par un registry/cache editor, reutilisation prudente des helpers Map Editor, jamais `MapCanvas` complet.
+
+Scope realise : audit MapData/layers visuels, resolution tilesets/assets, Map Editor rendering, runtime anti-scope, options A-E comparees, contrat V1-88, layer ordering, fallbacks, tests futurs et Visual Gate future.
+
+Preuve : rapport V1-87, Evidence Pack V1-87, conclusions sub-agents A-E, checks anti-scope documentaires et `git diff --check`.
+
+Limites : doc-only ; pas de renderer, pas de vraie map affichee, pas de package modifie, pas de test, pas de screenshot, pas de runtime/Flame, pas de playback, pas d'acteurs rendus.
+
+Prochain lot exact recommande : `NS-SCENES-V1-88 — Cinematic Map Backdrop Real Tile Renderer V0`.
+
 ## Mise a jour V1-86
 
 Statut : `NS-SCENES-V1-86 — Cinematic Map Backdrop Visual Composition Polish V0` est DONE.
diff --git a/reports/narrativeStudio/scenes/road_map_scenes.md b/reports/narrativeStudio/scenes/road_map_scenes.md
index 8c4eff89..fd7761fa 100644
--- a/reports/narrativeStudio/scenes/road_map_scenes.md
+++ b/reports/narrativeStudio/scenes/road_map_scenes.md
@@ -141,15 +141,18 @@ Ces briques sont utiles, mais elles ne constituent pas encore une Scene V1 propr
 | NS-SCENES-V1-84 — Cinematic Map Backdrop Preview Renderer V0 | DONE | Read model V1-83 branche dans le Cinematic Builder avec snapshot `MapData` editor non destructive ; renderer sandbox read-only du decor map, fallbacks humains, diagnostics, Visual Gate, tests builder/library/core et analyse ciblee verts, sans acteurs/playback/runtime/Flame/pathfinding/collision, mutation map/projet, donnees Selbrume ni image IA. |
 | NS-SCENES-V1-85 — Cinematic Map Backdrop Visual Primitives V0 | DONE | Primitives visuelles pures derivees de `MapData` ajoutees au read model et rendues dans le Builder via mini painter editor-only : grille/cellules/ancres spatiales, fallback summary honnete, Visual Gate, tests core/editor/library et analyse ciblee verts, sans fake tile, runtime, Flame, playback, acteurs rendus, pathfinding/collision, donnees Selbrume ni image IA. |
 | NS-SCENES-V1-86 — Cinematic Map Backdrop Visual Composition Polish V0 | DONE | Polish de composition demande par Karim : preview backdrop plus lisible, viewport map agrandi et proportionnel, meta/legende compactes et secondaires, grille/primitives renforcees, timeline preservee, Visual Gate 1663x926, sans tiles/assets finaux, runtime, Flame, playback, acteurs rendus, collision/pathfinding, donnees Selbrume ni image IA. |
+| NS-SCENES-V1-87 — Cinematic Map Backdrop Real Tile Rendering Prep Contract | DONE | Lot documentaire demande par Karim : audit MapData/layers visuels, tilesets/assets, rendu Map Editor et anti-scope runtime/Flame ; Option E retenue, contrat futur renderer V1-88 defini, sans code produit, package, test, screenshot, renderer, map rendue, playback ni acteurs. |
+| NS-SCENES-V1-88 — Cinematic Map Backdrop Real Tile Renderer V0 | TODO | Afficher les vraies tiles/assets de la map dans la preview du Cinematic Builder via un renderer editor-only read-only, avec images resolues en amont, layer ordering defini, diagnostics/fallbacks visibles, sans runtime, Flame, playback ni acteurs rendus. |
+| NS-SCENES-V1-89 — Cinematic Actor Display Preview Prep Contract | TODO | Cadrer l'affichage statique futur des acteurs apres le vrai decor map : sources actor bindings/placements/Character Library, positions, apparences et diagnostics, sans rendu acteur actif, runtime, playback, pathfinding ou collision. |
 | NS-SCENES-V1-90 — Cinematic Timeline Scroll / Visibility Polish V0 | TODO | Backlog futur déplacé depuis V1-80 : polir le scroll automatique et la visibilite des blocs/selection/probe apres le cadrage Character Library, en preservant les proportions de timeline demandees par Karim. |
 
 ## Prochain lot recommande
 
-`NS-SCENES-V1-87 — Cinematic Actor Display Preview Prep Contract`
+`NS-SCENES-V1-88 — Cinematic Map Backdrop Real Tile Renderer V0`
 
-Raison : V1-86, demande explicitement par Karim avant de continuer vers les acteurs, rend le decor map plus lisible dans le Builder tout en restant sandbox/read-only. Le prochain verrou recommande est maintenant de cadrer l'affichage statique futur des acteurs dans cette preview, sans playback, interpolation, runtime, Flame, pathfinding/collision ou donnees Selbrume.
+Raison : V1-87 confirme que le decor reste structurel et que poser des acteurs dessus serait premature. Le prochain verrou recommande est donc de rendre les vraies tiles/assets de la map dans le Builder avec un renderer editor-only read-only, sans runtime, Flame, playback ni acteurs.
 
-Ordre apres V1-86 : `NS-SCENES-V1-87 — Cinematic Actor Display Preview Prep Contract`.
+Ordre apres V1-87 : `NS-SCENES-V1-88 — Cinematic Map Backdrop Real Tile Renderer V0`, puis `NS-SCENES-V1-89 — Cinematic Actor Display Preview Prep Contract`.
 
 Le lot `NS-SCENES-V1-78 — Cinematic Stage Source Drift Diagnostics Polish V0` précédemment recommandé est repoussé après la séquence Character Library Binding. Il reste pertinent, mais il ne doit plus occuper V1-78.
 
@@ -157,6 +160,22 @@ Le lot `NS-SCENES-V1-67 — Cinematic Timeline Scroll / Visibility Polish V0` pr
 
 Note : l'overview n'affiche plus `Facts — necessite un modele`; Facts et Regles du monde pointent maintenant vers des workspaces actifs.
 
+## Mise a jour V1-87
+
+Statut : `NS-SCENES-V1-87 — Cinematic Map Backdrop Real Tile Rendering Prep Contract` est DONE.
+
+Demande : Karim a fourni le prompt V1-87 et a volontairement interrompu la trajectoire Actor Display pour cadrer le rendu reel des tiles/assets de map avant de poser des acteurs dans la preview.
+
+Decision : l'Option E hybride est retenue. V1-88 doit creer un petit contrat/renderer cinematic read-only dedie, alimente par `MapData`, `ProjectManifest`, des instructions bitmap et des images tileset resolues en amont cote editor. Il peut reutiliser des helpers purs du Map Editor si leur dependance reste bornee, mais ne doit pas embarquer `MapCanvas` complet.
+
+Scope realise : audit documentaire MapData/layers visuels, resolution tilesets/assets, rendu Map Editor, frontieres runtime/Flame, options techniques comparees, contrat futur renderer V1-88, fallbacks/diagnostics, tests futurs et Visual Gate future.
+
+Preuve : rapports `ns_scenes_v1_87_cinematic_map_backdrop_real_tile_rendering_prep_contract.md` et `ns_scenes_v1_87_evidence_pack.md`, sub-agents A-E, recherches `rg`, checks anti-scope et `git diff --check`.
+
+Limites : doc-only. Aucun renderer n'est code, aucune vraie map n'est affichee, aucune tile n'est rendue, aucun package n'est modifie, aucun test ni screenshot n'est cree, aucun runtime/Flame/playback/acteur n'est ajoute.
+
+Prochain lot exact recommande : `NS-SCENES-V1-88 — Cinematic Map Backdrop Real Tile Renderer V0`.
+
 ## Mise a jour V1-86
 
 Statut : `NS-SCENES-V1-86 — Cinematic Map Backdrop Visual Composition Polish V0` est DONE.
```

## 7. Sortie git diff --check

```text
git diff --check
(aucune sortie)
```

## 8. Sortie git diff --stat

```text
git diff --stat
 .../scenes/road_map_scene_builder_authoring.md     | 22 +++++++++++++++++--
 reports/narrativeStudio/scenes/road_map_scenes.md  | 25 +++++++++++++++++++---
 2 files changed, 42 insertions(+), 5 deletions(-)
```

## 9. Sortie git diff --name-only

```text
git diff --name-only
reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
reports/narrativeStudio/scenes/road_map_scenes.md
```

## 10. Sortie git diff --name-only -- packages

```text
git diff --name-only -- packages
(aucune sortie)
```

## 11. Sortie git status final

```text
git status --short --untracked-files=all
 M reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
 M reports/narrativeStudio/scenes/road_map_scenes.md
?? reports/narrativeStudio/scenes/ns_scenes_v1_87_cinematic_map_backdrop_real_tile_rendering_prep_contract.md
?? reports/narrativeStudio/scenes/ns_scenes_v1_87_evidence_pack.md
```

## 12. Checks anti-scope

```text
git diff --name-only -- packages
(aucune sortie)
```

```text
git diff --check
(aucune sortie)
```

Les termes runtime/playback/IA presents dans les fichiers V1-87 le sont dans les sections d'anti-scope, non-objectifs, audit runtime ou sorties de recherche prouvant ce qu'il faut exclure.

## 13. Auto-review critique

1. V1-87 a-t-il modifie du code produit ? Non.
2. V1-87 a-t-il modifie `packages/` ? Non.
3. V1-87 a-t-il cree un test ? Non.
4. V1-87 a-t-il genere une image ou un screenshot ? Non.
5. V1-87 a-t-il affiche une vraie map ? Non.
6. V1-87 a-t-il importe runtime/Flame ? Non.
7. V1-87 a-t-il propose `PlayableMapGame` ? Non ; il est rejete.
8. V1-87 a-t-il compare `MapCanvas` complet ? Oui ; option rejetee.
9. V1-87 a-t-il identifie les painters reutilisables ? Oui.
10. V1-87 a-t-il identifie les painters dangereux ? Oui.
11. V1-87 a-t-il defini la resolution des tileset images ? Oui, registry editor en amont.
12. V1-87 a-t-il defini les layers a rendre ? Oui.
13. V1-87 a-t-il defini les layers a exclure ? Oui.
14. V1-87 a-t-il defini l'ordre de rendu futur ? Oui.
15. V1-87 a-t-il defini les fallbacks ? Oui.
16. V1-87 a-t-il defini les tests V1-88 ? Oui.
17. V1-87 a-t-il mis a jour les roadmaps ? Oui.
18. Evidence Pack complet ? Oui.
19. Prochain lot exact recommande ? `NS-SCENES-V1-88 — Cinematic Map Backdrop Real Tile Renderer V0`.

Limite critique : l'Evidence Pack prouve le cadrage documentaire, pas l'exactitude visuelle d'un renderer qui n'existe pas encore. La fidelite finale Map Editor vs Cinematic Builder reste a prouver en V1-88 par tests et Visual Gate.
