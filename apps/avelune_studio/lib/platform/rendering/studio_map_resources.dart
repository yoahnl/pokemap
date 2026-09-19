import 'dart:async';
import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:map_authoring/map_authoring.dart'
    show AssetCatalog, assetCatalogStorageKey;
import 'package:map_authoring/map_authoring_local.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/map_runtime.dart';
import 'package:map_runtime/map_runtime_authoring.dart';

import 'package:avelune_studio/features/project_session/domain/project_session.dart';
import 'package:avelune_studio/presentation/features/map_workspace/map_workspace_visuals.dart';
import 'package:avelune_studio/presentation/features/map_workspace/workspace_resource_diagnostic.dart';
import 'studio_image_store.dart';
import 'studio_map_visual_widgets.dart';
import 'studio_resource_decoder.dart';
import 'studio_resource_index.dart';
import 'studio_resource_thumbnail.dart';

final class StudioMapResources implements MapWorkspaceVisuals {
  StudioMapResources._(this.projectRoot, this.manifest)
    : _index = StudioResourceIndex(manifest);

  final String projectRoot;
  final ProjectManifest manifest;
  final StudioResourceIndex _index;
  final Map<String, String> paths = {};
  Map<String, ProjectTilesetEntry> get tilesets => _index.tilesets;
  Map<String, ProjectElementEntry> get elements => _index.elements;
  final Map<String, WorkspaceResourceDiagnostic> _diagnostics = {};
  final _ResourceChanges _changes = _ResourceChanges();
  final Object _activeOwner = Object();
  final Object _brushOwner = Object();
  Set<String> _brushIds = {};
  late final StudioImageStore store;
  bool _disposed = false;
  bool _notificationPending = false;
  @override
  Set<String> activeResourceIds = {};
  Map<String, RuntimeTilesetImage> get images => store.images;
  int get decodedBytes => store.decodedBytes;
  Future<void> get settled => store.settled;

  static Future<StudioMapResources> load(
    ProjectSession session,
    ProjectManifest manifest, {
    int maximumBytes = 256 * 1024 * 1024,
    StudioImageDecoder decode = decodeRuntimeTilesetImage,
  }) async {
    final result = StudioMapResources._(session.directoryPath, manifest);
    const reader = LocalProjectFileReader();
    AssetCatalog? catalog;
    try {
      final probe = await reader.probeResource(
        projectRoot: session.directoryPath,
        relativePath: assetCatalogStorageKey,
      );
      if (probe.status == ProjectResourceProbeStatus.exists) {
        catalog = AssetCatalog.fromJson(
          jsonDecode(
                utf8.decode(
                  await reader.readBytes(
                    projectRoot: session.directoryPath,
                    relativePath: assetCatalogStorageKey,
                  ),
                ),
              )
              as Map<String, dynamic>,
        );
      } else if (probe.status != ProjectResourceProbeStatus.missing) {
        throw StateError('Catalogue: ${probe.status.name}');
      }
    } on Object catch (error) {
      result._failed(
        'catalogue',
        StudioResourceFailure(
          WorkspaceResourceCause.readFailure,
          error.toString(),
        ),
      );
    }
    result.paths.addAll(
      resolveTilesetAbsolutePaths(
        manifest: manifest,
        projectRoot: session.directoryPath,
        tilesetIds: result._index.supported,
        assetCatalog: catalog,
      ),
    );
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

  Set<String> elementResourceIds(ProjectElementEntry element) =>
      _index.forElement(element);
  Set<String> tileResourceIds(TileLayerPaletteEntry tile) =>
      _index.forTile(tile);
  Set<String> mapResourceIds(MapData map) => _index.forMap(map);
  bool hasFailure(Iterable<String> ids) => ids.any(_diagnostics.containsKey);

  @override
  void setActiveMap(MapData map) {
    if (_disposed) return;
    activeResourceIds = mapResourceIds(map);
    store.priority = {...activeResourceIds, ..._brushIds};
    store.retain(_activeOwner, activeResourceIds);
    _notify();
  }

  @override
  void setBrush(ProjectElementEntry? element, TileLayerPaletteEntry? tile) {
    if (_disposed) return;
    _brushIds = element != null
        ? elementResourceIds(element)
        : tile != null
        ? tileResourceIds(tile)
        : {};
    store.priority = {...activeResourceIds, ..._brushIds};
    store.retain(_brushOwner, _brushIds);
  }

  void retain(Object owner, Set<String> ids) => store.retain(owner, ids);
  void release(Object owner) => store.release(owner);

  @override
  Future<void> retryResources(Iterable<String> resourceIds) async {
    if (_disposed) return;
    final ids = resourceIds.toSet();
    for (final id in ids) {
      final old = _diagnostics[id];
      if (old == null) continue;
      _diagnostics[id] = WorkspaceResourceDiagnostic(
        resourceId: id,
        name: old.name,
        cause: old.cause,
        detail: old.detail,
        status: WorkspaceResourceStatus.retrying,
      );
    }
    _notify();
    await Future.wait(
      ids.map(
        (id) => store.request(id, retry: true, retainUntilComplete: true),
      ),
    );
  }

  void _failed(String id, StudioResourceFailure? failure) {
    if (_disposed) return;
    if (failure == null) {
      _diagnostics.remove(id);
    } else {
      _diagnostics[id] = WorkspaceResourceDiagnostic(
        resourceId: id,
        name: _index.names[id] ?? id,
        cause: failure.cause,
        detail: failure.detail,
      );
    }
  }

  void _notify() {
    if (_disposed || _notificationPending) return;
    _notificationPending = true;
    scheduleMicrotask(() {
      _notificationPending = false;
      if (!_disposed) _changes.emit();
    });
  }

  RuntimeAuthoringMapRenderer renderer(MapData map) {
    if (_disposed) throw StateError('Ressources fermées');
    return RuntimeAuthoringMapRenderer(
      bundle: RuntimeMapBundle(
        manifest: manifest,
        map: map,
        projectRootDirectory: projectRoot,
        tilesetAbsolutePathsById: paths,
      ),
      images: images,
    );
  }

  @override
  List<WorkspaceResourceDiagnostic> get diagnostics =>
      List.unmodifiable(_diagnostics.values);
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
    _changes.dispose();
  }
}

final class _ResourceChanges extends ChangeNotifier {
  void emit() => notifyListeners();
}
