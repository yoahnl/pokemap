import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:map_core/map_core.dart';
import 'package:path/path.dart' as p;

import '../../../app/providers/editor/editor_asset_cache_providers.dart';
import '../../../theme/theme.dart';
import '../../../ui/assets/editor_image_cache.dart';
import '../application/smart_tile_sprite_source.dart';

/// Renders the actual pixels of one Smart Tile frame.
///
/// The Studio used to describe frames only in prose, so authors could not tell
/// what a terrain looked like. This widget closes that gap by cropping the
/// referenced atlas cell out of its tileset through [EditorImageCache], the
/// same decode-and-cache path the map canvas uses.
class SmartTileSpritePreview extends ConsumerStatefulWidget {
  const SmartTileSpritePreview({
    super.key,
    required this.frame,
    required this.atlases,
    required this.tilesets,
    this.projectRootPath,
    this.imageCache,
    this.size = 34,
    this.previewKey,
    this.fallbackKey,
    this.semanticLabel,
  });

  final SmartTileFrameRef frame;
  final Iterable<ProjectSmartTileAtlas> atlases;
  final Iterable<ProjectTilesetEntry> tilesets;
  final String? projectRootPath;
  final EditorImageCache? imageCache;
  final double size;
  final Key? previewKey;
  final Key? fallbackKey;
  final String? semanticLabel;

  @override
  ConsumerState<SmartTileSpritePreview> createState() =>
      _SmartTileSpritePreviewState();
}

class _SmartTileSpritePreviewState
    extends ConsumerState<SmartTileSpritePreview> {
  EditorImageLoadResult? _result;
  String? _requestedKey;
  EditorImageCache? _requestedCache;
  EditorImageCache? _localCache;
  String? _localCacheScope;
  var _requestEpoch = 0;

  @override
  void dispose() {
    _result?.dispose();
    _localCache?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final source = resolveSmartTileSpriteSource(
      frame: widget.frame,
      atlases: widget.atlases,
      tilesets: widget.tilesets,
      projectRootPath: widget.projectRootPath,
    );
    if (source == null) {
      _releaseCurrent();
      return _fallback(context);
    }

    final projectRoot = widget.projectRootPath?.trim();
    final scope = projectRoot == null || projectRoot.isEmpty
        ? p.dirname(source.absolutePath)
        : projectRoot;
    final cache = _cacheFor(scope);
    _ensureLoad(cache, source);

    final result = _result;
    if (result == null) return _loading(context);
    final image = result.image;
    if (image == null) return _fallback(context);

    return Semantics(
      label: widget.semanticLabel,
      image: widget.semanticLabel != null,
      child: Container(
        key: widget.previewKey,
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(
          color: context.pokeMapColors.surfaceSubtle,
          borderRadius: BorderRadius.circular(7),
          border: Border.all(color: context.pokeMapColors.borderSubtle),
        ),
        clipBehavior: Clip.antiAlias,
        child: RawImage(
          image: image,
          fit: BoxFit.contain,
          filterQuality: FilterQuality.none,
        ),
      ),
    );
  }

  void _ensureLoad(EditorImageCache cache, SmartTileSpriteSource source) {
    final key = '${source.absolutePath}#${source.sourceRect.x},'
        '${source.sourceRect.y},${source.sourceRect.width},'
        '${source.sourceRect.height}';
    if (_requestedKey == key && identical(_requestedCache, cache)) return;
    _requestedKey = key;
    _requestedCache = cache;
    final epoch = ++_requestEpoch;
    _result?.dispose();
    _result = null;
    unawaited(() async {
      final result = await cache.loadCrop(
        source.absolutePath,
        sourceRect: Rect.fromLTWH(
          source.sourceRect.x.toDouble(),
          source.sourceRect.y.toDouble(),
          source.sourceRect.width.toDouble(),
          source.sourceRect.height.toDouble(),
        ),
        variantKey: 'smart-tile-sprite',
        sourceVariantKey: 'smart-tile-atlas',
      );
      if (!mounted || epoch != _requestEpoch) {
        result.dispose();
        return;
      }
      setState(() => _result = result);
    }());
  }

  void _releaseCurrent() {
    if (_requestedKey == null && _result == null) return;
    _requestEpoch += 1;
    _requestedKey = null;
    _requestedCache = null;
    _result?.dispose();
    _result = null;
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

  Widget _loading(BuildContext context) => Container(
        key: const Key('smart-tile-sprite-preview-loading'),
        width: widget.size,
        height: widget.size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: context.pokeMapColors.surfaceSubtle,
          borderRadius: BorderRadius.circular(7),
          border: Border.all(color: context.pokeMapColors.borderSubtle),
        ),
        child: Icon(
          CupertinoIcons.hourglass,
          size: widget.size <= 30 ? 11 : 13,
          color: context.pokeMapColors.textSecondary,
        ),
      );

  Widget _fallback(BuildContext context) => Container(
        key: widget.fallbackKey,
        width: widget.size,
        height: widget.size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: context.pokeMapColors.controlSurface,
          borderRadius: BorderRadius.circular(7),
          border: Border.all(color: context.pokeMapColors.borderSubtle),
        ),
        child: Icon(
          CupertinoIcons.photo,
          size: widget.size <= 30 ? 11 : 14,
          color: context.pokeMapColors.textSecondary,
        ),
      );
}
