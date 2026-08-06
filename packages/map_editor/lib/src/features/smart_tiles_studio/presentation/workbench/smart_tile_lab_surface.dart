import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:map_core/map_core.dart';

import '../../../../app/providers/editor/editor_asset_cache_providers.dart';
import '../../../../ui/assets/editor_image_cache.dart';
import '../../application/smart_tile_test_layer_controller.dart';
import 'smart_tile_compact_lab.dart';

/// Owns tileset decoding for the laboratory canvas.
///
/// Keeping the loading here means the lab draws real sprites without the panel
/// having to know about image caches, and the decoded images stay shared with
/// the rest of the editor session.
class SmartTileLabSurface extends ConsumerStatefulWidget {
  const SmartTileLabSurface({
    super.key,
    required this.layer,
    required this.mapSize,
    required this.topology,
    required this.visuals,
    required this.tilesetPathsById,
    required this.onTargetPressed,
    this.showStructure = true,
    this.selectedX,
    this.selectedY,
    this.projectRootPath,
    this.imageCache,
    this.cellExtent = 44,
  });

  final SmartTileLayer layer;
  final GridSize mapSize;
  final SmartTileTopology topology;
  final List<SmartTileLayerVisual> visuals;

  /// Absolute path of every tileset the resolved visuals sample, by tileset id.
  final Map<String, String> tilesetPathsById;
  final ValueChanged<SmartTileLabTarget> onTargetPressed;
  final bool showStructure;
  final int? selectedX;
  final int? selectedY;
  final String? projectRootPath;
  final EditorImageCache? imageCache;
  final double cellExtent;

  @override
  ConsumerState<SmartTileLabSurface> createState() =>
      _SmartTileLabSurfaceState();
}

class _SmartTileLabSurfaceState extends ConsumerState<SmartTileLabSurface> {
  Map<String, EditorImageLoadResult> _results =
      const <String, EditorImageLoadResult>{};
  String? _requestedKey;
  EditorImageCache? _requestedCache;
  EditorImageCache? _localCache;
  String? _localCacheScope;
  var _requestEpoch = 0;

  @override
  void dispose() {
    _disposeResults();
    _localCache?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scope = widget.projectRootPath?.trim();
    final cache = _cacheFor(scope == null || scope.isEmpty ? 'lab' : scope);
    _ensureLoad(cache);
    return SmartTileCompactLab(
      layer: widget.layer,
      mapSize: widget.mapSize,
      topology: widget.topology,
      visuals: widget.visuals,
      tilesetImages: <String, ui.Image?>{
        for (final entry in _results.entries) entry.key: entry.value.image,
      },
      showStructure: widget.showStructure,
      selectedX: widget.selectedX,
      selectedY: widget.selectedY,
      cellExtent: widget.cellExtent,
      onTargetPressed: widget.onTargetPressed,
    );
  }

  void _ensureLoad(EditorImageCache cache) {
    final paths = widget.tilesetPathsById;
    final key =
        (paths.entries.map((entry) => '${entry.key}=${entry.value}').toList()
              ..sort())
            .join('|');
    if (_requestedKey == key && identical(_requestedCache, cache)) return;
    _requestedKey = key;
    _requestedCache = cache;
    final epoch = ++_requestEpoch;
    _disposeResults();
    if (paths.isEmpty) return;
    unawaited(() async {
      final results = await cache.loadMany(
        paths,
        variantKeyForId: (_) => 'smart-tile-lab',
      );
      if (!mounted || epoch != _requestEpoch) {
        for (final result in results.values) {
          result.dispose();
        }
        return;
      }
      setState(() => _results = results);
    }());
  }

  void _disposeResults() {
    for (final result in _results.values) {
      result.dispose();
    }
    _results = const <String, EditorImageLoadResult>{};
  }

  EditorImageCache _cacheFor(String scope) {
    final provided = widget.imageCache;
    if (provided != null) return provided;
    try {
      ProviderScope.containerOf(context, listen: false);
      return ref.watch(editorImageCacheProvider(scope));
    } on StateError {
      if (_localCache == null || _localCacheScope != scope) {
        _localCache?.dispose();
        _localCacheScope = scope;
        _localCache = EditorImageCache(sessionKey: scope);
      }
      return _localCache!;
    }
  }
}
