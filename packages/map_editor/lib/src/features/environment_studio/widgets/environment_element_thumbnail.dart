import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:map_core/map_core.dart';
import 'package:path/path.dart' as p;

import '../../../app/providers/editor/editor_asset_cache_providers.dart';
import '../../../theme/theme.dart';
import '../../../ui/assets/editor_image_cache.dart';
import '../../../ui/shared/cupertino_editor_widgets.dart';

typedef EnvironmentTilesetPathResolver = String? Function(String tilesetId);

class EnvironmentElementThumbnail extends ConsumerStatefulWidget {
  const EnvironmentElementThumbnail({
    super.key,
    required this.manifest,
    required this.element,
    required this.elementId,
    this.resolveTilesetPathById,
    this.size = 34,
    this.previewKey,
    this.fallbackKey,
    this.fallbackAccent,
    this.projectRootPath,
    this.imageCache,
  });

  final ProjectManifest manifest;
  final ProjectElementEntry? element;
  final String elementId;
  final EnvironmentTilesetPathResolver? resolveTilesetPathById;
  final double size;
  final Key? previewKey;
  final Key? fallbackKey;
  final Color? fallbackAccent;
  final String? projectRootPath;
  final EditorImageCache? imageCache;

  @override
  ConsumerState<EnvironmentElementThumbnail> createState() =>
      _EnvironmentElementThumbnailState();
}

class _EnvironmentElementThumbnailState
    extends ConsumerState<EnvironmentElementThumbnail> {
  EditorImageLoadResult? _result;
  String? _requestedKey;
  EditorImageCache? _requestedCache;
  EditorImageCache? _localCache;
  String? _localCacheScope;
  var _requestEpoch = 0;

  @override
  void didUpdateWidget(covariant EnvironmentElementThumbnail oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.manifest, widget.manifest) ||
        !identical(oldWidget.element, widget.element) ||
        oldWidget.resolveTilesetPathById != widget.resolveTilesetPathById ||
        oldWidget.projectRootPath != widget.projectRootPath ||
        !identical(oldWidget.imageCache, widget.imageCache)) {
      _releaseCurrent();
    }
  }

  @override
  Widget build(BuildContext context) {
    final resolved = _ResolvedEnvironmentElementThumbnail.resolve(
      manifest: widget.manifest,
      element: widget.element,
      resolveTilesetPathById: widget.resolveTilesetPathById,
    );
    if (resolved == null) {
      _releaseCurrent();
      return _fallback(context);
    }

    final projectRoot = widget.projectRootPath?.trim();
    final scope = projectRoot == null || projectRoot.isEmpty
        ? p.dirname(resolved.path)
        : projectRoot;
    final cache = _cacheFor(scope);
    _ensureLoad(cache, resolved);
    final result = _result;
    if (result == null) {
      return _loading(context);
    }
    final image = result.image;
    if (image == null) {
      return _fallback(context);
    }
    return Container(
      key: widget.previewKey,
      width: widget.size,
      height: widget.size,
      decoration: BoxDecoration(
        color: EditorChrome.badgeFill(context),
        borderRadius: BorderRadius.circular(9),
        border: Border.all(
          color: context.pokeMapColors.divider,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: RawImage(
        image: image,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.none,
      ),
    );
  }

  void _ensureLoad(
    EditorImageCache cache,
    _ResolvedEnvironmentElementThumbnail resolved,
  ) {
    if (_requestedKey == resolved.cacheKey &&
        identical(_requestedCache, cache)) {
      return;
    }
    _requestedKey = resolved.cacheKey;
    _requestedCache = cache;
    final epoch = ++_requestEpoch;
    _result?.dispose();
    _result = null;
    unawaited(() async {
      final result = await cache.loadCrop(
        resolved.path,
        sourceRect: Rect.fromLTWH(
          (resolved.source.x * resolved.tileWidth).toDouble(),
          (resolved.source.y * resolved.tileHeight).toDouble(),
          (resolved.source.width * resolved.tileWidth).toDouble(),
          (resolved.source.height * resolved.tileHeight).toDouble(),
        ),
        variantKey: 'environment-thumbnail',
        sourceVariantKey: 'environment-tileset',
      );
      if (!mounted || epoch != _requestEpoch) {
        result.dispose();
        return;
      }
      setState(() => _result = result);
    }());
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

  Widget _loading(BuildContext context) {
    return Semantics(
      label: 'Chargement de la vignette d’environnement',
      child: Container(
        key: const Key('environment-element-thumbnail-loading'),
        width: widget.size,
        height: widget.size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: EditorChrome.badgeFill(context),
          borderRadius: BorderRadius.circular(9),
          border: Border.all(
            color: context.pokeMapColors.divider,
          ),
        ),
        child: Icon(
          CupertinoIcons.hourglass,
          size: 14,
          color: EditorChrome.subtleLabel(context),
        ),
      ),
    );
  }

  Widget _fallback(BuildContext context) {
    final accent = widget.fallbackAccent ?? EditorChrome.accentJade;
    final id = widget.elementId.trim();
    return Container(
      key: widget.fallbackKey,
      width: widget.size,
      height: widget.size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: accent.withValues(alpha: 0.38)),
      ),
      child: Text(
        id.isEmpty ? '?' : id.characters.first.toUpperCase(),
        style: TextStyle(
          color: accent,
          fontSize: widget.size <= 30 ? 13 : 16,
          fontWeight: FontWeight.w900,
          letterSpacing: 0,
        ),
      ),
    );
  }

  void _releaseCurrent() {
    _requestEpoch++;
    _requestedKey = null;
    _requestedCache = null;
    _result?.dispose();
    _result = null;
  }

  @override
  void dispose() {
    _releaseCurrent();
    _localCache?.dispose();
    super.dispose();
  }
}

class _ResolvedEnvironmentElementThumbnail {
  const _ResolvedEnvironmentElementThumbnail({
    required this.path,
    required this.source,
    required this.tileWidth,
    required this.tileHeight,
  });

  final String path;
  final TilesetSourceRect source;
  final int tileWidth;
  final int tileHeight;

  static _ResolvedEnvironmentElementThumbnail? resolve({
    required ProjectManifest manifest,
    required ProjectElementEntry? element,
    required EnvironmentTilesetPathResolver? resolveTilesetPathById,
  }) {
    if (element == null || element.frames.isEmpty) {
      return null;
    }
    final frame = element.frames.primaryFrame;
    final tilesetId = frame.tilesetId.trim().isNotEmpty
        ? frame.tilesetId.trim()
        : element.tilesetId.trim();
    if (tilesetId.isEmpty) {
      return null;
    }
    final tileWidth = manifest.settings.tileWidth;
    final tileHeight = manifest.settings.tileHeight;
    if (tileWidth <= 0 || tileHeight <= 0) {
      return null;
    }
    final source = frame.source;
    if (source.width <= 0 || source.height <= 0) {
      return null;
    }
    final path = _resolvePath(
      manifest: manifest,
      tilesetId: tilesetId,
      resolveTilesetPathById: resolveTilesetPathById,
    );
    if (path == null) {
      return null;
    }
    return _ResolvedEnvironmentElementThumbnail(
      path: path,
      source: source,
      tileWidth: tileWidth,
      tileHeight: tileHeight,
    );
  }

  static String? _resolvePath({
    required ProjectManifest manifest,
    required String tilesetId,
    required EnvironmentTilesetPathResolver? resolveTilesetPathById,
  }) {
    final resolved = resolveTilesetPathById?.call(tilesetId)?.trim();
    if (resolved != null && resolved.isNotEmpty) {
      return resolved;
    }
    for (final tileset in manifest.tilesets) {
      if (tileset.id != tilesetId) {
        continue;
      }
      final relativePath = tileset.relativePath.trim();
      if (relativePath.isNotEmpty && p.isAbsolute(relativePath)) {
        return relativePath;
      }
      return null;
    }
    return null;
  }

  String get cacheKey {
    return [
      path,
      source.x,
      source.y,
      source.width,
      source.height,
      tileWidth,
      tileHeight,
    ].join('|');
  }
}
