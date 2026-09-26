import 'package:flutter/widgets.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/map_runtime_authoring.dart';
import 'package:avelune_studio/features/project_session/domain/project_session.dart';
import 'package:avelune_studio/presentation/features/map_workspace/map_workspace_visuals.dart';
import 'package:avelune_studio/presentation/features/map_workspace/workspace_resource_diagnostic.dart';
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
import '../../presentation/features/characters/character_workspace_visuals.dart';
import '../../presentation/features/cinematics/cinematic_workspace_visuals.dart';

import '../../presentation/features/presentations/presentation_workspace_visuals.dart';
import '../../features/presentations/domain/presentation_port.dart';
import 'presentation_workspace_visuals.dart';
part 'studio_map_resource_recovery.dart';
part 'studio_map_resources_helpers.dart';

final class StudioMapResources
    implements
        MapWorkspaceVisuals,
        ResourceWorkspaceVisuals,
        CharacterWorkspaceVisuals,
        CinematicWorkspaceVisuals,
        CinematicMediaWorkspaceVisuals,
        PresentationMediaWorkspaceVisuals,
        MapBorderPreviewVisuals {
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
  int get decodedBytes => store.decodedBytes;
  Future<void> get settled async {
    await Future.wait([store.settled, borderPreview.settled]);
  }

  static Future<StudioMapResources> load(
    ProjectSession session,
    ProjectManifest manifest, {
    int maximumBytes = 256 * 1024 * 1024,
    StudioImageDecoder decode = decodeRuntimeTilesetImage,
  }) async {
    final result = StudioMapResources._(session.directoryPath, manifest);
    try {
      result.paths.addAll(
        await resolveStudioResourcePaths(
          session.directoryPath,
          manifest,
          result._index.supported,
        ),
      );
    } on Object catch (error) {
      result._failed(
        'catalogue',
        StudioResourceFailure(
          WorkspaceResourceCause.readFailure,
          error.toString(),
        ),
      );
    }
    result.store = StudioImageStore(
      projectRoot: result.projectRoot,
      maximumBytes: maximumBytes,
      paths: result.paths,
      colors: result._index.colors,
      decode: decode,
      changed: result._notify,
      failed: result._failed,
    );
    return result;
  }

  @override
  Future<void> updateCatalog(
    ProjectManifest updated, {
    Set<String> changedRelativePaths = const {},
  }) async {
    if (_disposed) return;
    final next = StudioResourceIndex(updated);
    final resolved = await resolveStudioResourcePaths(
      projectRoot,
      updated,
      next.supported,
    );
    await store.settled;
    if (_disposed) return;
    final invalid = changedStudioResourceIds(
      root: projectRoot,
      before: paths,
      after: resolved,
      previousColors: _index.colors,
      nextColors: next.colors,
      changedRelativePaths: changedRelativePaths,
    );
    manifest = updated;
    _index = next;
    paths
      ..clear()
      ..addAll(resolved);
    store.colors
      ..clear()
      ..addAll(next.colors);
    store.invalidate(invalid);
    catalogVersion++;
    if (_activeMap != null) {
      borderPreview.invalidate(updated, _activeMap!);
      setActiveMap(_activeMap!);
    }
    final terrain = _terrainPreset;
    final character = _characterBrush;
    if (character != null) {
      setCharacterBrush(
        updated.characters
            .where((entry) => entry.id == character.id)
            .firstOrNull,
      );
    } else if (terrain != null) {
      setTerrainBrush(
        updated.smartTileCatalog.presets
            .where((item) => item.id == terrain.id)
            .firstOrNull,
      );
    } else {
      setBrush(elements[_brushElement?.id], _brushTile);
    }
    _notify();
  }

  @override
  Widget atlasPreview(String tilesetId) =>
      StudioAtlasPreview(resources: this, tilesetId: tilesetId);

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
  void setCharacterBrush(ProjectCharacterEntry? character) {
    if (_disposed) return;
    _characterBrush = character;
    _terrainPreset = null;
    _brushElement = null;
    _brushTile = null;
    _brushIds = character == null ? {} : characterResourceIds(character);
    store.priority = {...activeResourceIds, ..._brushIds};
    store.retain(_brushOwner, _brushIds);
  }

  @override
  Widget characterThumbnail(
    ProjectCharacterEntry character, {
    double size = 48,
    EntityFacing facing = EntityFacing.south,
  }) => StudioCharacterThumbnail(
    resources: this,
    character: character,
    size: size,
    facing: facing,
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
  }) => StudioCharacterThumbnail(
    resources: this,
    character: character,
    size: size,
    facing: facing,
    animationState: animationState,
    elapsedMs: elapsedMs,
    customAnimation: customAnimation,
  );

  @override
  Future<void> retryResources(Iterable<String> resourceIds) =>
      _retryResources(resourceIds);

  @override
  List<WorkspaceResourceDiagnostic> get diagnostics => List.unmodifiable([
    ..._diagnostics.values,
    if (borderPreview.issue case final issue?)
      WorkspaceResourceDiagnostic(
        resourceId: 'border:${_activeMap?.id}',
        name: 'Bordures de la carte',
        cause: WorkspaceResourceCause.readFailure,
        detail: issue,
      ),
  ]);
  @override
  List<String> get warnings =>
      diagnostics.map((item) => '${item.name} : ${item.message}').toList();
  @override
  void addListener(VoidCallback listener) => _changes.addListener(listener);
  @override
  void removeListener(VoidCallback listener) =>
      _changes.removeListener(listener);
  @override
  Widget canvas(MapData map) => StudioMapVisual(map: map, resources: this);
  @override
  Widget thumbnail(ProjectElementEntry element, {double size = 48}) =>
      StudioResourceThumbnail(element: element, resources: this, size: size);
  @override
  Widget tileThumbnail(TileLayerPaletteEntry tile, {double size = 48}) =>
      StudioResourceThumbnail(tile: tile, resources: this, size: size);
  @override
  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    store.release(_activeOwner);
    store.release(_brushOwner);
    store.close();
    await borderPreview.dispose();
    _changes.dispose();
  }
}
