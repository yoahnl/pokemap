import 'dart:typed_data';
import 'dart:isolate';
import 'dart:ui' as ui;
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:map_authoring/map_authoring_local.dart';
import 'package:map_authoring/map_authoring_resources.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/map_runtime_authoring.dart';
import 'package:map_runtime/map_runtime.dart';
import 'package:map_render_3d/map_render_3d.dart';
import 'package:avelune_studio/features/project_session/domain/project_session.dart';
import '../../features/rendering/contracts/map_workspace_visuals.dart';
import '../../features/rendering/contracts/workspace_resource_diagnostic.dart';

import 'studio_image_store.dart';
import 'studio_map_visual_widgets.dart';
import 'studio_resource_decoder.dart';
import 'studio_resource_index.dart';
import 'studio_resource_thumbnail.dart';
import 'studio_resource_catalog.dart';
import 'studio_atlas_preview.dart';
import 'studio_character_thumbnail.dart';
import 'studio_cinematic_media.dart';
import 'studio_resource_notifications.dart';
import 'studio_border_preview.dart';
import '../../features/rendering/contracts/character_workspace_visuals.dart';
import '../../features/rendering/contracts/cinematic_workspace_visuals.dart';
import '../../features/rendering/contracts/presentation_workspace_visuals.dart';
import '../../features/presentations/domain/presentation_port.dart';
import 'presentation_workspace_visuals.dart';
part 'studio_map_resource_recovery.dart';
part 'studio_map_resources_helpers.dart';
part 'studio_cinematic_spatial_preview.dart';
part 'studio_map_resources_catalog.dart';
part 'studio_map_resources_spatial.dart';

Future<RuntimeMapBundle> loadStudioPreviewBundle({
  required String projectRoot,
  required ProjectManifest manifest,
  required MapData map,
}) => loadRuntimeMapBundle(
  projectFilePath: '$projectRoot/project.json',
  mapId: map.id,
  preloadedManifest: manifest,
  additionalCharacterIds: {
    for (final entity in map.entities) ?entity.npc?.characterId,
  },
);

final class StudioMapResources
    implements
        MapWorkspaceVisuals,
        SpatialWorkspaceVisuals,
        SpatialScopedWorkspaceVisuals,
        SpatialModelSourceWorkspaceVisuals,
        ResourceWorkspaceVisuals,
        ResourceImageDimensionsVisuals,
        CharacterWorkspaceVisuals,
        CinematicWorkspaceVisuals,
        CinematicSpatialWorkspaceVisuals,
        CinematicMediaWorkspaceVisuals,
        PresentationMediaWorkspaceVisuals,
        MapBorderPreviewVisuals,
        MapWorkspacePreviewVisuals {
  StudioMapResources._(this.projectRoot, this.manifest)
    : _index = StudioResourceIndex(manifest);

  @override
  PresentationWorkspaceVisuals createPresentationVisuals({
    required String revision,
    required ProjectMediaCatalog catalog,
    List<PresentationStagedMedia> imports = const [],
  }) => StudioPresentationVisuals(
    projectRoot: projectRoot,
    revision: revision,
    catalog: catalog,
    imports: imports,
  );
  final String projectRoot;
  @override
  Future<CinematicSpatialPreview> cinematicSpatialPreview(
    MapData map,
    CinematicActorDisplayPreviewModel actors,
  ) => _cinematicSpatialPreview(map, actors);
  @override
  Future<Uint8List> readGroundImage(String tilesetId) =>
      _readGroundImage(tilesetId);

  @override
  Future<Uint8List> readGroundDefinition(ProjectTilesetEntry tileset) =>
      _readGroundDefinition(tileset);

  @override
  Future<SpatialNpcPreview> spatialPreview(MapData map) =>
      _spatialPreview(map);

  @override
  Future<Uint8List> readModel(String modelId) => _readModel(modelId);

  @override
  Future<Uint8List> readModelDefinition(ProjectModel3dEntry model) =>
      _readModelDefinition(model);

  @override
  CinematicMediaPlaybackPort createCinematicMedia(ProjectManifest project) =>
      StudioCinematicMedia(
        projectRoot: projectRoot,
        assets: project.cinematicMediaAssets,
      );
  ProjectManifest manifest;
  StudioResourceIndex _index;
  final Map<String, String> paths = {};
  Map<String, ProjectTilesetEntry> get tilesets => _index.tilesets;
  Map<String, ProjectElementEntry> get elements => _index.elements;
  final Map<String, WorkspaceResourceDiagnostic> _diagnostics = {};
  final StudioResourceNotifications _changes = StudioResourceNotifications();
  final Object _activeOwner = Object();
  final Object _brushOwner = Object();
  Set<String> _brushIds = {};
  MapData? _activeMap;
  ProjectElementEntry? _brushElement;
  TileLayerPaletteEntry? _brushTile;
  ProjectSmartTilePreset? _terrainPreset;
  ProjectCharacterEntry? _characterBrush;
  int catalogVersion = 0;
  @override
  final SpatialModelSourceUpdates modelSourceUpdates =
      SpatialModelSourceUpdates();
  late final StudioImageStore store;
  late final StudioBorderPreview borderPreview = StudioBorderPreview(
    projectRoot: projectRoot,
    changed: _notify,
  );
  @override
  bool get borderPreviewLoading => borderPreview.loading;
  @override
  bool get borderPreviewReady => borderPreview.assets != null;
  @override
  String? get borderPreviewIssue => borderPreview.issue;
  bool _disposed = false;
  @override
  Set<String> activeResourceIds = {};
  Map<String, RuntimeTilesetImage> get images => store.images;
  @override
  Size? cachedImageDimensions(String id) => _cachedImageDimensions(id);
  int get decodedBytes => store.decodedBytes;
  Future<void> get settled => _resourcesSettled;

  static Future<StudioMapResources> load(
    ProjectSession session,
    ProjectManifest manifest, {
    int maximumBytes = 256 * 1024 * 1024,
    StudioImageDecoder decode = decodeRuntimeTilesetImage,
  }) => _loadStudioMapResources(
    session,
    manifest,
    maximumBytes: maximumBytes,
    decode: decode,
  );

  @override
  Future<void> updateModelSources(
    ProjectManifest updated,
    Map<String, ProjectModel3dEntry> definitions,
    Map<String, String> revisions,
  ) => _updateModelSources(updated, definitions, revisions);

  @override
  Future<void> updateCatalog(
    ProjectManifest updated, {
    Set<String> changedRelativePaths = const {},
  }) => _updateCatalog(updated, changedRelativePaths: changedRelativePaths);

  @override
  Widget atlasPreview(String tilesetId) =>
      StudioAtlasPreview(resources: this, tilesetId: tilesetId);
  @override
  ProjectRegularAtlasTilesetSource? characterAtlas(
    ProjectCharacterEntry character,
  ) => _characterAtlas(character);

  @override
  void setActiveMap(MapData map) => _setActiveMap(map);
  @override
  void setBrush(ProjectElementEntry? element, TileLayerPaletteEntry? tile) =>
      _setBrush(element, tile);

  @override
  void setTerrainBrush(ProjectSmartTilePreset? preset) {
    if (_disposed) return;
    _terrainPreset = preset;
    _characterBrush = null;
    _brushElement = null;
    _brushTile = null;
    _brushIds = preset == null ? {} : _index.forTerrain(preset);
    store.priority = {...activeResourceIds, ..._brushIds};
    store.retain(_brushOwner, _brushIds);
  }

  void retain(Object owner, Set<String> ids) => store.retain(owner, ids);
  @override
  void setCharacterBrush(ProjectCharacterEntry? character) =>
      _setCharacterBrush(character);

  @override
  Widget characterThumbnail(
    ProjectCharacterEntry character, {
    double size = 48,
    EntityFacing facing = EntityFacing.south,
  }) => _characterThumbnail(character, size: size, facing: facing);
  @override
  Widget characterAnimationThumbnail(
    ProjectCharacterEntry character, {
    required double size,
    required EntityFacing facing,
    required CharacterAnimationState state,
    required int elapsedMs,
  }) => _characterThumbnail(
    character,
    size: size,
    facing: facing,
    state: state,
    elapsedMs: elapsedMs,
  );
  void release(Object owner) => store.release(owner);

  @override
  Widget cinematicActor(
    ProjectCharacterEntry character, {
    double size = 48,
    EntityFacing facing = EntityFacing.south,
    CharacterAnimationState animationState = CharacterAnimationState.idle,
    int elapsedMs = 0,
    CharacterCustomAnimationClip? customAnimation,
  }) => _characterThumbnail(
    character,
    size: size,
    facing: facing,
    state: animationState,
    elapsedMs: elapsedMs,
    customAnimation: customAnimation,
  );

  @override
  Future<void> retryResources(Iterable<String> resourceIds) =>
      _retryResources(resourceIds);
  @override
  List<WorkspaceResourceDiagnostic> get diagnostics => _resourceDiagnostics;
  @override
  List<String> get warnings =>
      diagnostics.map((item) => '${item.name} : ${item.message}').toList();
  @override
  void addListener(VoidCallback listener) => _changes.addListener(listener);
  @override
  void removeListener(VoidCallback listener) =>
      _changes.removeListener(listener);
  @override
  Widget canvas(
    MapData map, {
    MapPlacedElement? placedElementPreview,
    Color? collisionColor,
  }) => StudioMapVisual(
    map: map,
    resources: this,
    placedElementPreview: placedElementPreview,
    collisionColor: collisionColor,
  );
  @override
  Widget previewCanvas(MapData map) =>
      StudioMapVisual(map: map, resources: this, preview: true);
  @override
  Widget thumbnail(ProjectElementEntry element, {double size = 48}) =>
      StudioResourceThumbnail(element: element, resources: this, size: size);
  @override
  Widget placementPreview(ProjectElementEntry element, Size size) =>
      StudioResourceThumbnail(
        element: element,
        resources: this,
        canvasSize: size,
      );
  @override
  Widget tileThumbnail(TileLayerPaletteEntry tile, {double size = 48}) =>
      StudioResourceThumbnail(tile: tile, resources: this, size: size);
  @override
  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    modelSourceUpdates.dispose();
    store.release(_activeOwner);
    store.release(_brushOwner);
    store.close();
    await borderPreview.dispose();
    _changes.dispose();
  }
}
