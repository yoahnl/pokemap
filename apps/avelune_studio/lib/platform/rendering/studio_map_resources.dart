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
        SpatialWorkspaceVisuals,
        ResourceWorkspaceVisuals,
        ResourceImageDimensionsVisuals,
        CharacterWorkspaceVisuals,
        CinematicWorkspaceVisuals,
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
  Future<Uint8List> readGroundImage(String tilesetId) async {
    final tileset = manifest.tilesets
        .where((tileset) => tileset.id == tilesetId)
        .firstOrNull;
    if (tileset == null) {
      throw StateError('Image de terrain absente : $tilesetId');
    }
    return Uint8List.fromList(
      await const LocalProjectFileReader().readBytes(
        projectRoot: projectRoot,
        relativePath: tileset.relativePath,
      ),
    );
  }

  @override
  Future<SpatialNpcPreview> spatialPreview(MapData map) async {
    final frames = <String, SpatialActorVisual>{};
    final images = <String, ui.Image>{};
    if (!map.entities.any((entity) => entity.npc != null)) {
      return SpatialNpcPreview(frames, () {});
    }
    await initializeSpatialRenderer();
    final bundle = await loadRuntimeMapBundle(
      projectFilePath: '$projectRoot/project.json',
      mapId: map.id,
      preloadedManifest: manifest,
    );
    final resolver = CharacterAnimationSourceResolver();
    final textures = <String, SpatialActorTexture>{};
    try {
      for (final entity in map.entities.where((entity) => entity.npc != null)) {
        final actor = manifest.characters
            .where((actor) => actor.id == entity.npc!.characterId)
            .firstOrNull;
        if (actor == null) {
          throw StateError('Personnage du PNJ absent : ${entity.name}');
        }
        final animation =
            actor.animations
                .where(
                  (clip) =>
                      clip.direction == entity.npc!.facing &&
                      clip.state == CharacterAnimationState.idle,
                )
                .firstOrNull ??
            actor.animations
                .where(
                  (clip) =>
                      clip.direction == entity.npc!.facing &&
                      clip.state == CharacterAnimationState.walk,
                )
                .firstOrNull;
        if (animation == null || animation.frames.isEmpty) {
          throw StateError('Animation du PNJ absente : ${entity.name}');
        }
        final asset = animation.sourceAssetId?.trim();
        final imageId = asset != null && asset.isNotEmpty
            ? characterAnimationRuntimeImageId(asset)
            : actor.tilesetId;
        if (!images.containsKey(imageId)) {
          final path = bundle.runtimeImageAbsolutePathsById[imageId];
          if (path == null) {
            throw StateError('Image du PNJ absente : ${entity.name}');
          }
          final codec = await ui.instantiateImageCodec(
            await File(path).readAsBytes(),
          );
          try {
            images[imageId] = (await codec.getNextFrame()).image;
          } finally {
            codec.dispose();
          }
          textures[imageId] = await SpatialActorTexture.fromImage(
            images[imageId]!,
          );
        }
        final source = resolver.resolveFrame(
          character: actor,
          animation: animation,
          frame: animation.frames.first,
          tileWidth: manifest.settings.tileWidth,
          tileHeight: manifest.settings.tileHeight,
          availableImageIds: images.keys.toSet(),
        );
        final image = images[imageId]!;
        if (source == null ||
            source.sourceRect.left < 0 ||
            source.sourceRect.top < 0 ||
            source.sourceRect.width <= 0 ||
            source.sourceRect.height <= 0 ||
            source.sourceRect.right > image.width ||
            source.sourceRect.bottom > image.height) {
          throw StateError('Frame du PNJ invalide : ${entity.name}');
        }
        final x = entity.pos.x + .5, z = entity.pos.y + .5;
        frames['npc:${entity.id}'] = SpatialActorVisual(
          x: x,
          y: map.spatialScene!.worldHeightAt(x, z),
          z: z,
          texture: textures[imageId]!,
          frame: source.sourceRect,
        );
      }
      return SpatialNpcPreview(frames, () {
        for (final image in images.values) {
          image.dispose();
        }
      });
    } on Object {
      for (final image in images.values) {
        image.dispose();
      }
      rethrow;
    }
  }

  @override
  Future<Uint8List> readModel(String modelId) async {
    final model = manifest.models3d
        .where((item) => item.id == modelId)
        .firstOrNull;
    if (model == null) throw StateError('Modèle introuvable : $modelId');
    final bytes = Uint8List.fromList(
      await const LocalProjectFileReader().readBytes(
        projectRoot: projectRoot,
        relativePath: model.relativePath,
      ),
    );
    await Isolate.run(() => const GlbModel3dInspector().inspect(bytes));
    return bytes;
  }

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
  @override
  Size? cachedImageDimensions(String id) => _cachedImageDimensions(id);
  int get decodedBytes => store.decodedBytes;
  Future<void> get settled => _resourcesSettled;

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
    final borderChanged =
        manifest.borderCatalog != updated.borderCatalog ||
        manifest.settings != updated.settings ||
        updated.borderCatalog.visualSnapshots.any(
          (snapshot) => snapshot.frames.any(
            (frame) => changedRelativePaths.contains(frame.relativeAssetPath),
          ),
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
      if (borderChanged) {
        borderPreview.invalidate(updated, _activeMap!);
      }
      setActiveMap(_activeMap!);
    }
    _refreshBrushAfterCatalog(updated);
    _notify();
  }

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
    store.release(_activeOwner);
    store.release(_brushOwner);
    store.close();
    await borderPreview.dispose();
    _changes.dispose();
  }
}
