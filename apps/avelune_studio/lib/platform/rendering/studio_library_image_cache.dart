import 'package:flutter/foundation.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/map_runtime.dart'
    show characterAnimationRuntimeImageId;
import 'package:map_runtime/map_runtime_authoring.dart';
import 'package:path/path.dart' as p;

import '../../features/rendering/contracts/workspace_resource_diagnostic.dart';
import '../../features/resources/application/resource_preview_source.dart';
import 'studio_image_store.dart';
import 'studio_resource_catalog.dart';
import 'studio_resource_decoder.dart';
import 'studio_resource_index.dart';
import 'studio_resource_notifications.dart';
import 'studio_thumbnail_resources.dart';

final class StudioLibraryImageCache {
  StudioLibraryImageCache(this._catalog);

  final StudioAssetCatalogCache _catalog;
  String get projectRoot => _catalog.projectRoot;
  final _changes = StudioResourceNotifications();
  final _paths = <String, String>{};
  final _colors = <String, TilesetTransparentColor>{};
  final _failures = <String, StudioResourceFailure>{};
  bool _catalogObserved = false;
  bool _disposed = false;
  int _generation = 0;

  late final _store = StudioImageStore(
    projectRoot: projectRoot,
    maximumBytes: 64 * 1024 * 1024,
    paths: _paths,
    colors: _colors,
    changed: _changes.emitLater,
    failed: (id, failure) {
      if (failure == null) {
        _failures.remove(id);
      } else {
        _failures[id] = failure;
      }
      _changes.emitLater();
    },
  );

  Future<StudioThumbnailResources?> scope(
    ResourcePreviewSource source,
    ProjectManifest project,
  ) async {
    if (_disposed) return null;
    final generation = _generation;
    final character = switch (source) {
      CharacterPreviewSource(:final character) => character,
      _ => null,
    };
    final tilesetIds = switch (source) {
      AtlasPreviewSource(:final tilesetId) => {tilesetId},
      TileFramePreviewSource(:final entry) => {entry.tilesetId},
      ElementPreviewSource(:final element) => {
        element.frames.firstOrNull?.tilesetId.isNotEmpty == true
            ? element.frames.first.tilesetId
            : element.tilesetId,
      },
      CharacterPreviewSource(:final character) => {character.tilesetId},
      _ => <String>{},
    };
    final scope = project.copyWith(
      tilesets: [
        for (final item in project.tilesets)
          if (tilesetIds.contains(item.id)) item,
      ],
      characters: [?character],
      elements: const [],
    );
    final index = StudioResourceIndex(scope);
    final requiredIds = switch (source) {
      TileFramePreviewSource(:final entry) => index.forTile(entry),
      AtlasPreviewSource(:final tilesetId, :final pageId) => {
        ?studioLibraryAtlasImageId(project, tilesetId, pageId: pageId),
      },
      ElementPreviewSource() => index.expand(tilesetIds),
      CharacterPreviewSource(:final character) => index.forCharacter(character),
      _ => <String>{},
    };
    final catalog = _catalog.read(refresh: !_catalogObserved);
    _catalogObserved = true;
    final paths = await resolveStudioResourcePaths(
      projectRoot,
      scope,
      index.supported,
      catalogRead: catalog,
    );
    if (_disposed) return null;
    if (generation != _generation) return this.scope(source, project);
    final aliases = <String, String>{};
    for (final id in requiredIds) {
      final path = paths[id];
      if (path == null) continue;
      final color = index.colors[id];
      final key = '$path\u0000${color?.toHexRgb() ?? ''}';
      _paths[key] = path;
      if (color != null) _colors[key] = color;
      aliases[id] = key;
    }
    return _StudioLibraryThumbnailResources(this, index, aliases);
  }

  void refreshCatalog() {
    _catalogObserved = false;
    _generation++;
  }

  void invalidate(Set<String> changedRelativePaths) {
    if (changedRelativePaths.isEmpty || _disposed) return;
    _generation++;
    final changed = {
      for (final path in changedRelativePaths)
        p.normalize(p.join(projectRoot, path)),
    };
    _store.invalidate({
      for (final entry in _paths.entries)
        if (changed.contains(entry.value)) entry.key,
    });
    _changes.emitLater();
  }

  void dispose() {
    _disposed = true;
    _store.close();
    _changes.dispose();
  }
}

String? studioLibraryAtlasImageId(
  ProjectManifest project,
  String tilesetId, {
  String? pageId,
}) {
  final source = project.tilesets
      .where((item) => item.id == tilesetId)
      .firstOrNull
      ?.source;
  return switch (source) {
    ProjectImageCollectionTilesetSource(:final pages) when pageId == null =>
      pages.firstOrNull?.assetId,
    ProjectImageCollectionTilesetSource(:final pages) =>
      pages.where((page) => page.id == pageId).firstOrNull?.assetId,
    _ => tilesetId,
  };
}

final class _StudioLibraryThumbnailResources
    implements StudioThumbnailResources {
  _StudioLibraryThumbnailResources(this.cache, this.index, this.aliases);

  final StudioLibraryImageCache cache;
  final StudioResourceIndex index;
  final Map<String, String> aliases;

  @override
  ProjectManifest get manifest => index.manifest;
  @override
  Map<String, ProjectTilesetEntry> get tilesets => index.tilesets;
  @override
  Map<String, RuntimeTilesetImage> get images => {
    for (final entry in aliases.entries)
      entry.key: ?cache._store.images[entry.value],
  };
  @override
  List<WorkspaceResourceDiagnostic> get diagnostics => [
    for (final entry in aliases.entries)
      if (cache._failures[entry.value] case final failure?)
        WorkspaceResourceDiagnostic(
          resourceId: entry.key,
          name: entry.key,
          cause: failure.cause,
        ),
  ];
  @override
  int get catalogVersion => cache._generation;
  @override
  void retain(Object owner, Set<String> ids) =>
      cache._store.retain(owner, {for (final id in ids) ?aliases[id]});
  @override
  void release(Object owner) => cache._store.release(owner);
  @override
  bool hasFailure(Iterable<String> ids) => ids.any(
    (id) => aliases[id] == null || cache._failures.containsKey(aliases[id]),
  );
  @override
  Set<String> elementResourceIds(ProjectElementEntry element) =>
      index.forElement(element);
  @override
  Set<String> tileResourceIds(TileLayerPaletteEntry tile) =>
      index.forTile(tile);
  @override
  Set<String> characterResourceIds(ProjectCharacterEntry character) => {
    character.tilesetId,
    for (final animation in character.animations)
      if (animation.sourceAssetId case final id?)
        characterAnimationRuntimeImageId(id),
  };
  @override
  void addListener(VoidCallback listener) =>
      cache._changes.addListener(listener);
  @override
  void removeListener(VoidCallback listener) =>
      cache._changes.removeListener(listener);
}
