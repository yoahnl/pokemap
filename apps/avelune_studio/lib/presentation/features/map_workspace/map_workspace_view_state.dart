import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:map_core/map_core.dart';
import 'package:map_render_3d/map_render_3d.dart';

import '../resources/resource_catalog.dart';
import 'map_terrain_patterns.dart';

import 'package:avelune_studio/features/map_workspace/application/editable_map_document.dart';
import 'package:avelune_studio/features/map_workspace/application/map_border_drawing_draft.dart';
import 'package:avelune_studio/features/map_workspace/application/map_border_editing_commands.dart';
import 'package:avelune_studio/features/map_workspace/application/environment_editing_commands.dart';
import 'package:avelune_studio/features/map_workspace/application/spatial_terrain_stroke.dart';
import 'package:avelune_studio/features/map_workspace/application/spatial_ramp_editing_commands.dart';
import 'package:avelune_studio/features/map_workspace/application/spatial_terrain_surface_editing_commands.dart';

enum MapSelectionFamily { decor, character, marker, warp, zone, trigger }

class MapSelectionTarget {
  const MapSelectionTarget({
    required this.mapId,
    required this.family,
    required this.id,
  });
  final String mapId;
  final MapSelectionFamily family;
  final String id;
}

enum StudioMapTool {
  select,
  place,
  paint,
  terrain,
  character,
  warp,
  connection,
  spawn,
  sign,
  fieldObstacle,
  zone,
  gameplayZone,
  encounterPaint,
  encounterErase,
  collisionPaint,
  collisionErase,
  border,
  environment,
  erase,
  eraseDecor,
  pan,
}

class MapWorkspaceViewState {
  final spatialAnimations = SpatialAnimationPreviewController();
  final transform = TransformationController();
  double get scale => transform.value.entry(0, 0).abs();
  StudioMapTool tool = StudioMapTool.select;
  bool spatialFreeView = false;
  SpatialTerrainMode spatialTerrainMode = SpatialTerrainMode.ground;
  int spatialTerrainLevel = 1;
  SpatialRampEditingPreview? rampPreview;
  bool spatialContinuousTerrain = false;
  bool spatialSurfaceSelect = false;
  bool spatialSurfaceReanchorInstances = true;
  String spatialSurfaceLowLevel = '0';
  String spatialSurfaceHighLevel = '1';
  SpatialRampDirection spatialSurfaceDirection = SpatialRampDirection.north;
  String? spatialSurfaceId;
  SpatialTerrainSurfaceEditingPreview? terrainSurfacePreview;
  (bool, String, String, SpatialRampDirection, bool)
  get terrainSurfaceOptions => (
    spatialContinuousTerrain,
    spatialSurfaceLowLevel,
    spatialSurfaceHighLevel,
    spatialSurfaceDirection,
    spatialSurfaceReanchorInstances,
  );
  ProjectElementEntry? brush;
  FieldObstacleKind fieldObstacleKind = FieldObstacleKind.cutTree;
  ProjectModel3dEntry? model3d;
  TileLayerPaletteEntry? tile;
  ProjectSmartTilePreset? terrain;
  String? terrainMaterialId;
  String? terrainPatternId;
  SmartTilePatternSelectionKind terrainPatternMode =
      SmartTilePatternSelectionKind.stamp;
  ProjectCharacterEntry? character;
  ProjectMapEntry? warpDestination;
  MapWarpTriggerMode warpPlacementMode = MapWarpTriggerMode.onEnter;

  void prepareFieldObstaclePlacement(FieldObstacleKind kind) {
    fieldObstacleKind = kind;
    paletteTab = 'Décors';
    tool = StudioMapTool.fieldObstacle;
  }

  String? borderBlueprintId;
  MapBorderDrawingDraft? borderDraft;
  ({MapBorderDrawingDraft draft, String message})? borderDraftFailure;
  String? borderDraftErrorFor(MapData map, ProjectManifest project) {
    final failure = borderDraftFailure;
    final draft = borderDraft;
    return tool == StudioMapTool.border &&
            map.spatialScene != null &&
            failure != null &&
            draft != null &&
            draft.featureId == failure.draft.featureId &&
            identical(failure.draft.sourceMap, map) &&
            identical(failure.draft.sourceProject, project)
        ? failure.message
        : null;
  }

  void failBorderDraft(
    MapBorderDrawingDraft draft,
    EditableMapDocument document,
    Object error,
  ) {
    final message = error.toString();
    document.error = message;
    borderDraftFailure = (draft: draft, message: message);
  }

  void clearBorderDraftFailure(EditableMapDocument document) {
    final failure = borderDraftFailure;
    if (failure != null &&
        identical(failure.draft.sourceMap, document.current) &&
        document.error == failure.message) {
      document.error = null;
    }
    borderDraftFailure = null;
  }

  BorderStrokeEditingMode borderEditingMode = BorderStrokeEditingMode.draw;
  ({String layerId, String featureId})? borderFeature;
  MapBorderRegenerationPreview? borderPreview;
  void repairBorderSelection(MapData map) {
    final selected = borderFeature;
    if (selected == null) return;
    final layer = map.layers
        .whereType<BorderLayer>()
        .where((layer) => layer.id == selected.layerId && layer.isVisible)
        .firstOrNull;
    if (layer?.content.featureById(selected.featureId) != null) return;
    borderFeature = null;
    borderPreview = null;
    borderEditingMode = BorderStrokeEditingMode.draw;
  }

  MapEnvironmentSession? environment;
  MapSelectionTarget? _target;
  MapSelectionTarget? get target => _target;

  MapSelectionTarget? _pendingMove;
  String? _moveHint;

  /// Armed by the context menu: the element the next drag must move, whatever
  /// else sits under the pointer.
  MapSelectionTarget? get pendingMove => _pendingMove;
  set pendingMove(MapSelectionTarget? target) {
    _pendingMove = target;
    _moveHint = null;
  }

  String? get moveHint => _pendingMove == null ? null : _moveHint;

  void armMove(MapSelectionTarget target, String hint) {
    _pendingMove = target;
    _moveHint = hint;
  }

  MapPlacedElement? armedDecorIn(MapData map) {
    final armed = _pendingMove;
    if (armed == null ||
        armed.family != MapSelectionFamily.decor ||
        armed.mapId != map.id ||
        tool != StudioMapTool.select) {
      return null;
    }
    return map.placedElements.where((item) => item.id == armed.id).firstOrNull;
  }

  GameplayZoneKind zoneKind = GameplayZoneKind.encounter;
  String characterQuery = '';
  double characterScrollOffset = 0;
  bool grid = false;
  bool navigatorCollapsed = false;
  bool highlightTerrain = true;
  bool dimOtherTerrains = false;
  bool lockDecorProportions = false;
  bool showDecorCollision = false;
  bool paletteTiles = false;
  bool revealPalette = false;
  bool revealInspector = false;
  String paletteTab = 'Décors';
  final resourceFilters = ResourceCatalogFilterState();
  String? _resourceMapId;
  final paletteScrollOffsets = <String, double>{};
  String? paletteAtlasId;
  final paletteAtlasTransforms = <String, TransformationController>{};
  final fittedPaletteAtlases = <String>{};
  bool positioned = false;
  Size? _viewport;
  Size? _content;
  Matrix4? _fittedTransform;
  int _fitGeneration = 0;
  VoidCallback? recenter;
  void Function(GridPos)? centerOn;
  Offset? Function(GridPos)? globalOfCell;

  void fitViewport(Size viewport, Size content) {
    final widthScale = viewport.width / content.width;
    final heightScale = viewport.height / content.height;
    final scale = math.min(1.0, math.min(widthScale, heightScale));
    transform.value = Matrix4.identity()
      ..translateByDouble(
        (viewport.width - content.width * scale) / 2,
        (viewport.height - content.height * scale) / 2,
        0,
        1,
      )
      ..scaleByDouble(scale, scale, 1, 1);
    _fittedTransform = transform.value.clone();
  }

  void attachViewport(
    Size viewport,
    Size content,
    Size tile, {
    required bool Function() mounted,
    GlobalKey? surface,
  }) {
    void fit() => fitViewport(viewport, content);
    centerOn = (cell) => centerCell(cell, viewport, tile);
    recenter = fit;
    globalOfCell = (cell) {
      final box = surface?.currentContext?.findRenderObject();
      return box is RenderBox && box.attached
          ? box.localToGlobal(
              Offset((cell.x + 1) * tile.width, (cell.y + 1) * tile.height),
            )
          : null;
    };
    final changed = _viewport != viewport || _content != content;
    _viewport = viewport;
    _content = content;
    if (!changed) return;
    final fitted = _fittedTransform;
    if (positioned && fitted != null && transform.value != fitted) return;
    positioned = true;
    final generation = ++_fitGeneration;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted() &&
          generation == _fitGeneration &&
          (fitted == null || transform.value == fitted)) {
        fit();
      }
    });
  }

  void centerCell(GridPos cell, Size viewport, Size tile) {
    final scale = this.scale;
    transform.value = Matrix4.identity()
      ..translateByDouble(
        viewport.width / 2 - (cell.x + .5) * tile.width * scale,
        viewport.height / 2 - (cell.y + .5) * tile.height * scale,
        0,
        1,
      )
      ..scaleByDouble(scale, scale, 1, 1);
  }

  void prepareCharacterPlacement() {
    paletteTab = 'Personnages';
    brush = null;
    model3d = null;
    tile = null;
    terrain = null;
    tool = character == null ? StudioMapTool.select : StudioMapTool.character;
  }

  void prepareTerrainPainting(ProjectSmartTilePreset preset) {
    paletteTab = 'Terrains';
    if (terrain?.id != preset.id) terrainPatternId = null;
    if (terrain?.id != preset.id ||
        !preset.allowedMaterialIds.contains(terrainMaterialId)) {
      terrainMaterialId = preset.defaultMaterialId;
    }
    terrain = preset;
    brush = null;
    model3d = null;
    tile = null;
    character = null;
    spatialTerrainMode = SpatialTerrainMode.ground;
    tool = StudioMapTool.terrain;
  }

  void selectTerrainPattern(ProjectSmartTilePattern? pattern) {
    terrainPatternId = pattern?.id;
    if (pattern?.repeatMode == SmartTilePatternRepeatMode.stamp) {
      terrainPatternMode = SmartTilePatternSelectionKind.stamp;
    }
    spatialTerrainMode = SpatialTerrainMode.ground;
    tool = StudioMapTool.terrain;
  }

  ProjectSmartTilePattern? terrainPatternFor(
    ProjectManifest project,
    MapData map,
  ) {
    final preset = terrain;
    if (preset == null || terrainPatternId == null) return null;
    return availableTerrainPatterns(
      project: project,
      map: map,
      preset: preset,
    ).where((pattern) => pattern.id == terrainPatternId).firstOrNull;
  }

  List<ResourceItem> paletteResources(
    ProjectManifest project,
    String mapId, {
    bool applyFilters = true,
  }) {
    final kinds = switch (paletteTab) {
      'Décors' => const {'element', 'model3d'},
      'Terrains' => const {'smartTilePreset'},
      'Tuiles' => const {'tileset'},
      'Personnages' => const {'character'},
      'Bordures' => const {'borderBlueprint'},
      'Environnements' => const {'environmentPreset'},
      _ => const <String>{},
    };
    final filters = applyFilters
        ? resourceFilters.copy()
        : ResourceCatalogFilterState(showComponents: true);
    filters.usage = ResourceCatalogUsage.all;
    return filterResourceCatalog(
      project,
      resourceCatalog(project)
          .where((item) => kinds.contains(item.canonicalKind))
          .toList(),
      filters,
      activeMapId: mapId,
      forMapPicker: true,
    );
  }

  void reconcileResources(
    ProjectManifest project, {
    String? mapId,
    MapData? map,
  }) {
    resourceFilters.usage = ResourceCatalogUsage.all;
    final activeMapId = mapId ?? _resourceMapId;
    final available = filterResourceCatalog(
      project,
      resourceCatalog(project),
      ResourceCatalogFilterState(showComponents: true),
      activeMapId: activeMapId,
      forMapPicker: true,
    ).map((item) => item.identity).toSet();
    bool has(String kind, String id) => available.contains('$kind:$id');
    if (mapId != null && _resourceMapId != null && _resourceMapId != mapId) {
      environment = null;
      borderDraft = null;
      borderDraftFailure = null;
      borderPreview = null;
      borderFeature = null;
      spatialSurfaceId = null;
      terrainSurfacePreview = null;
      spatialSurfaceSelect = false;
    }
    _resourceMapId = activeMapId;
    if (model3d != null) {
      model3d = project.models3d
          .where((item) => item.id == model3d!.id && has('model3d', item.id))
          .firstOrNull;
      if (model3d == null && tool == StudioMapTool.place) {
        tool = StudioMapTool.select;
      }
    }
    if (brush != null) {
      brush = project.elements
          .where((item) => item.id == brush!.id && has('element', item.id))
          .firstOrNull;
      if (brush == null &&
          (tool == StudioMapTool.place || tool == StudioMapTool.paint)) {
        tool = StudioMapTool.select;
      }
    }
    if (terrain != null) {
      terrain = project.smartTileCatalog.presets
          .where(
            (item) => item.id == terrain!.id && has('smartTilePreset', item.id),
          )
          .firstOrNull;
      if (terrain == null && tool == StudioMapTool.terrain) {
        tool = StudioMapTool.select;
      }
      if (terrain == null) {
        terrainMaterialId = null;
        terrainPatternId = null;
      } else if (!terrain!.allowedMaterialIds.contains(terrainMaterialId)) {
        terrainMaterialId = terrain!.defaultMaterialId;
      }
      if (terrainPatternId != null) {
        final pattern = map == null
            ? project.smartTileCatalog.patterns
                  .where((pattern) => pattern.id == terrainPatternId)
                  .firstOrNull
            : terrainPatternFor(project, map);
        if (pattern == null) {
          terrainPatternId = null;
        } else if (pattern.repeatMode == SmartTilePatternRepeatMode.stamp) {
          terrainPatternMode = SmartTilePatternSelectionKind.stamp;
        }
      }
    }
    if (character != null) {
      character = project.characters
          .where(
            (item) => item.id == character!.id && has('character', item.id),
          )
          .firstOrNull;
      if (character == null && tool == StudioMapTool.character) {
        tool = StudioMapTool.select;
      }
    }
    if (tile != null && !has('tileset', tile!.tilesetId)) {
      tile = null;
      if (tool == StudioMapTool.paint) tool = StudioMapTool.select;
    }
    if (paletteAtlasId != null && !has('tileset', paletteAtlasId!)) {
      paletteAtlasId = null;
    }
    if (borderBlueprintId != null &&
        !has('borderBlueprint', borderBlueprintId!)) {
      borderBlueprintId = null;
      borderDraft = null;
      borderDraftFailure = null;
      if (tool == StudioMapTool.border) tool = StudioMapTool.select;
    }
    if (environment != null && map != null) {
      final session = environment!;
      final area = map.layers
          .whereType<EnvironmentLayer>()
          .where((layer) => layer.id == session.layerId)
          .expand((layer) => layer.content.areas)
          .where((area) => area.id == session.areaId)
          .firstOrNull;
      if (area == null || !has('environmentPreset', area.presetId)) {
        environment = null;
      }
    }
    if (environment == null && tool == StudioMapTool.environment) {
      tool = StudioMapTool.select;
    }
  }

  void prepareWarpPlacement() {
    paletteTab = 'Passages';
    brush = null;
    model3d = null;
    tile = null;
    terrain = null;
    character = null;
    tool =
        warpDestination == null &&
            warpPlacementMode != MapWarpTriggerMode.sceneOnly
        ? StudioMapTool.select
        : StudioMapTool.warp;
  }

  void prepareConnections() {
    paletteTab = 'Passages';
    pendingMove = null;
    revealInspector = true;
    tool = StudioMapTool.connection;
  }

  String? selectedFor(String mapId, MapSelectionFamily family) {
    final target = _target;
    return target != null && target.mapId == mapId && target.family == family
        ? target.id
        : null;
  }

  bool hasSelectionIn(String mapId) => _target?.mapId == mapId;

  void select(
    EditableMapDocument document,
    MapSelectionFamily family,
    String id,
  ) {
    _target = MapSelectionTarget(
      mapId: document.current.id,
      family: family,
      id: id,
    );
    document.selectedId = family == MapSelectionFamily.decor ? id : null;
  }

  void clearSelection(EditableMapDocument document) {
    _target = null;
    pendingMove = null;
    document.selectedId = null;
  }

  void dispose() {
    spatialAnimations.dispose();
    _fitGeneration++;
    transform.dispose();
    for (final controller in paletteAtlasTransforms.values) {
      controller.dispose();
    }
  }
}
