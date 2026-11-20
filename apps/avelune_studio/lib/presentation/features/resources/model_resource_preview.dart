import 'dart:async';
import 'dart:collection';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:map_core/map_core_domain.dart';
import 'package:map_render_3d/map_render_3d.dart';

import 'package:avelune_studio/features/rendering/contracts/map_workspace_visuals.dart';

class ModelResourcePreview extends StatefulWidget {
  const ModelResourcePreview({
    super.key,
    required this.model,
    required this.visuals,
    this.compact = false,
  }) : preparedBytes = null;

  const ModelResourcePreview.prepared({
    super.key,
    required this.model,
    required Uint8List this.preparedBytes,
  }) : visuals = null,
       compact = false;

  final ProjectModel3dEntry model;
  final MapWorkspaceVisuals? visuals;
  final Uint8List? preparedBytes;
  final bool compact;

  @override
  State<ModelResourcePreview> createState() => _ModelResourcePreviewState();
}

typedef _ThumbnailKey = ({
  Model3dBounds bounds,
  String assetId,
  String path,
  String? revision,
  Color background,
});

final _thumbnails = Expando<_ModelThumbnails>();

class _ModelResourcePreviewState extends State<ModelResourcePreview> {
  final _controller = ModelPreviewController();
  Future<Uint8List>? _bytes;
  Uint8List? _thumbnail;
  _ThumbnailKey? _key;
  VoidCallback? _cancel;
  bool _failed = false;
  int _generation = 0;
  Color? _background;

  _ModelThumbnails get _cache =>
      _thumbnails[widget.visuals!] ??= _ModelThumbnails();

  SpatialModelSourceUpdates? _updates(MapWorkspaceVisuals? visuals) =>
      switch (visuals) {
        SpatialModelSourceWorkspaceVisuals value => value.modelSourceUpdates,
        _ => null,
      };

  @override
  void initState() {
    super.initState();
    _updates(widget.visuals)?.addListener(_sourceChanged);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final background = Theme.of(context).colorScheme.surfaceContainerLowest;
    if (_background == background) return;
    _background = background;
    _load();
  }

  @override
  void didUpdateWidget(ModelResourcePreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    final changedVisuals = !identical(oldWidget.visuals, widget.visuals);
    if (changedVisuals) {
      _updates(oldWidget.visuals)?.removeListener(_sourceChanged);
      _updates(widget.visuals)?.addListener(_sourceChanged);
    }
    if (changedVisuals ||
        oldWidget.model != widget.model ||
        oldWidget.compact != widget.compact ||
        !identical(oldWidget.preparedBytes, widget.preparedBytes)) {
      _load();
    }
  }

  void _sourceChanged() {
    final revision = _updates(widget.visuals)
        ?.revision(widget.model.sourceAssetId);
    if (_key?.revision != revision && mounted) setState(_load);
  }

  void _load() {
    final generation = ++_generation;
    _cancel?.call();
    _cancel = null;
    _bytes = null;
    _failed = false;
    _thumbnail = null;
    if (widget.preparedBytes case final bytes?) {
      _bytes = Future.value(bytes);
      return;
    }
    final model = widget.model;
    final visuals = widget.visuals;
    if (visuals is! SpatialWorkspaceVisuals) return;
    final key = (
      bounds: model.inspection.bounds,
      assetId: model.sourceAssetId,
      path: model.relativePath,
      revision: _updates(visuals)?.revision(model.sourceAssetId),
      background: _background!,
    );
    _key = key;
    Future<Uint8List> read() => Future.sync(
      () => switch (visuals) {
        final SpatialScopedWorkspaceVisuals scoped =>
          scoped.readModelDefinition(model),
        _ => (visuals as SpatialWorkspaceVisuals).readModel(model.id),
      },
    );
    if (!widget.compact) {
      _bytes = read();
      return;
    }
    _thumbnail = _cache.read(key);
    if (_thumbnail != null) return;
    _cancel = _cache.schedule(() {
      if (mounted && generation == _generation) {
        setState(() {
          _thumbnail = _cache.read(key);
          if (_thumbnail == null) _bytes = read();
        });
        if (_thumbnail != null) _finish();
      }
    });
  }

  void _finish() {
    _cancel?.call();
    _cancel = null;
  }

  Future<void> _capture(ui.Image frame, int generation) async {
    ui.Image? owned;
    try {
      owned = frame.clone();
      final data = await owned.toByteData(format: ui.ImageByteFormat.png);
      if (!mounted || _generation != generation || _failed) return;
      if (data == null) {
        _fail(generation);
        return;
      }
      final png = data.buffer.asUint8List(
        data.offsetInBytes,
        data.lengthInBytes,
      );
      _cache.put(_key!, png);
      setState(() {
        _thumbnail = png;
        _bytes = null;
      });
      _finish();
    } on Object {
      _fail(generation);
    } finally {
      owned?.dispose();
    }
  }

  void _fail(int generation) {
    if (!mounted || _generation != generation || _failed) return;
    setState(() {
      _failed = true;
      _bytes = null;
    });
    _finish();
  }

  @override
  void dispose() {
    _finish();
    _updates(widget.visuals)?.removeListener(_sourceChanged);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final thumbnail = _thumbnail;
    if (thumbnail != null) return Image.memory(thumbnail, fit: BoxFit.contain);
    final unavailable = Center(
      child: Icon(
        Icons.view_in_ar_outlined,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
        semanticLabel: 'Aperçu 3D indisponible',
      ),
    );
    if (_failed) return unavailable;
    final generation = _generation;
    final compact = widget.compact;
    void releaseFailedRequest() {
      if (compact) scheduleMicrotask(() => _fail(generation));
    }

    return FutureBuilder<Uint8List>(
      future: _bytes,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done &&
            snapshot.hasError) {
          releaseFailedRequest();
          return unavailable;
        }
        final bytes = snapshot.connectionState == ConnectionState.done
            ? snapshot.data
            : null;
        if (bytes == null) {
          if (compact) {
            return const Center(child: Icon(Icons.hourglass_empty, size: 18));
          }
          return const Center(
            child: SizedBox.square(
              dimension: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          );
        }
        final bounds = widget.model.inspection.bounds;
        return ModelPreview(
          key: ValueKey(generation),
          bytes: bytes,
          controller: _controller,
          minimum: [bounds.min.x, bounds.min.y, bounds.min.z],
          maximum: [bounds.max.x, bounds.max.y, bounds.max.z],
          background: _background!,
          interactive: !compact,
          onFirstFrame: compact
              ? (frame) => unawaited(_capture(frame, generation))
              : null,
          loadingBuilder: (_) => const SizedBox(),
          errorBuilder: (_, _) {
            releaseFailedRequest();
            return unavailable;
          },
        );
      },
    );
  }
}

final class _ModelThumbnails {
  final _cache = <_ThumbnailKey, Uint8List>{};
  final _queue = Queue<_ThumbnailRequest>();
  int _bytes = 0;
  int _active = 0;

  Uint8List? read(_ThumbnailKey key) {
    final png = _cache.remove(key);
    if (png != null) _cache[key] = png;
    return png;
  }

  void put(_ThumbnailKey key, Uint8List png) {
    _bytes -= _cache.remove(key)?.lengthInBytes ?? 0;
    _cache[key] = png;
    _bytes += png.lengthInBytes;
    while (_cache.length > 96 || _bytes > 4 * 1024 * 1024) {
      _bytes -= _cache.remove(_cache.keys.first)!.lengthInBytes;
    }
  }

  VoidCallback schedule(VoidCallback start) {
    final request = _ThumbnailRequest(start);
    _queue.add(request);
    _drain();
    return () {
      if (_queue.remove(request) || !request.active) return;
      request.active = false;
      _active--;
      _drain();
    };
  }

  void _drain() {
    while (_active < 2 && _queue.isNotEmpty) {
      final next = _queue.removeFirst();
      _active++;
      next.active = true;
      scheduleMicrotask(() {
        if (next.active) next.start();
      });
    }
  }
}

final class _ThumbnailRequest {
  _ThumbnailRequest(this.start);
  final VoidCallback start;
  bool active = false;
}
