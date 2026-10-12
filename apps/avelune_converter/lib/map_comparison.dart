import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:avelune_converter_adapters/avelune_converter_adapters.dart';
import 'package:avelune_converter_core/avelune_converter_core.dart';
import 'package:avelune_design_system/avelune_design_system.dart';
import 'package:flutter/material.dart';
import 'package:map_core/map_core.dart' show MapData, TileLayer;

class ConverterMapComparison extends StatefulWidget {
  const ConverterMapComparison({
    super.key,
    required this.prepared,
    required this.sourceMapId,
  });

  final PreparedStudy prepared;
  final int sourceMapId;

  @override
  State<ConverterMapComparison> createState() => _ConverterMapComparisonState();
}

class _ConverterMapComparisonState extends State<ConverterMapComparison> {
  final _transform = TransformationController();
  Map<String, ui.Image> _images = const {};
  Map<String, ui.Image> _sourceAutotileImages = const {};
  String? _error;
  int _generation = 0;
  bool _fitPending = true;
  bool _emptyImage = false;
  Size _viewport = Size.zero;

  SourceMapData get _source => widget.prepared.normalizedSource.maps
      .firstWhere((value) => value.map.sourceMapId == widget.sourceMapId)
      .map;
  MapData? get _target =>
      widget.prepared.composition.nativeMaps[widget.sourceMapId];

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  @override
  void didUpdateWidget(ConverterMapComparison oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.prepared.composition.compositionHash !=
            widget.prepared.composition.compositionHash ||
        oldWidget.sourceMapId != widget.sourceMapId) {
      _fitPending = true;
      unawaited(_load());
    }
  }

  Future<void> _load() async {
    final generation = ++_generation;
    for (final image in _images.values) {
      image.dispose();
    }
    for (final image in _sourceAutotileImages.values) {
      image.dispose();
    }
    _images = const {};
    _sourceAutotileImages = const {};
    _error = null;
    _emptyImage = false;
    if (_target == null) return;
    Map<String, ui.Image> images = const {};
    Map<String, ui.Image> sourceImages = const {};
    try {
      images = await _decodeAtlases(widget.prepared, _source.sourceTilesetId);
      sourceImages = await _decodeSourceAutotiles(
        widget.prepared,
        _source.sourceTilesetId,
      );
      if (!mounted || generation != _generation) {
        for (final image in [...images.values, ...sourceImages.values]) {
          image.dispose();
        }
        return;
      }
      setState(() {
        _images = images;
        _sourceAutotileImages = sourceImages;
        _emptyImage = images.isEmpty;
      });
    } catch (error) {
      for (final image in [...images.values, ...sourceImages.values]) {
        image.dispose();
      }
      if (mounted && generation == _generation) {
        setState(
          () => _error =
              'L’aperçu de cet atlas ne peut pas être affiché : $error',
        );
      }
    }
  }

  @override
  void dispose() {
    _generation++;
    for (final image in _images.values) {
      image.dispose();
    }
    for (final image in _sourceAutotileImages.values) {
      image.dispose();
    }
    _transform.dispose();
    super.dispose();
  }

  void _fit() {
    final scale = math.min(
      _viewport.width / (_source.width * 32),
      _viewport.height / (_source.height * 32),
    );
    _transform.value = Matrix4.diagonal3Values(scale, scale, 1)
      ..setTranslationRaw(
        (_viewport.width - _source.width * 32 * scale) / 2,
        (_viewport.height - _source.height * 32 * scale) / 2,
        0,
      );
  }

  void _zoom(double factor) {
    final current = _transform.value;
    final previousScale = current.getMaxScaleOnAxis();
    final next = (previousScale * factor).clamp(.01, 8.0);
    final ratio = next / previousScale;
    final center = _viewport.center(Offset.zero);
    _transform.value = Matrix4.diagonal3Values(next, next, 1)
      ..setTranslationRaw(
        center.dx - (center.dx - current.storage[12]) * ratio,
        center.dy - (center.dy - current.storage[13]) * ratio,
        0,
      );
  }

  @override
  Widget build(BuildContext context) {
    if (_target == null) {
      return const StudioNotice(
        'La comparaison native n’est pas disponible tant que cette sélection est bloquée. Les données et diagnostics source restent consultables.',
      );
    }
    if (_error != null) return StudioNotice(_error!, isError: true);
    if (_images.isEmpty && !_emptyImage) {
      return const StudioPanel(
        children: [
          Text('Chargement des pixels de l’atlas vérifié…'),
          SizedBox(height: 12),
          LinearProgressIndicator(),
        ],
      );
    }
    final source = _source;
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = (constraints.maxWidth - 24) / 2 - 40;
        _viewport = Size(width, 284);
        if (_fitPending) {
          _fitPending = false;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) _fit();
          });
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  '${source.width} × ${source.height} cases · zoom et déplacement synchronisés',
                ),
                StudioButton(
                  label: 'Réduire',
                  secondary: true,
                  onPressed: () => _zoom(.8),
                ),
                StudioButton(
                  label: 'Agrandir',
                  secondary: true,
                  onPressed: () => _zoom(1.25),
                ),
                StudioButton(
                  label: 'Ajuster',
                  secondary: true,
                  onPressed: _fit,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _pane(
                    'Données source reconstruites',
                    sourceMode: true,
                  ),
                ),
                const SizedBox(width: 24),
                Expanded(
                  child: _pane('Cellules natives Avelune', sourceMode: false),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const StudioNotice(
              'Cette comparaison statique reconstruit les tuiles lues à la première frame ; elle n’est pas une capture du jeu Essentials. Les animations se vérifient dans Studio. Les priorités d’acteurs, événements et comportements ne sont pas certifiés ici.',
            ),
          ],
        );
      },
    );
  }

  Widget _pane(String title, {required bool sourceMode}) {
    final source = _source;
    return StudioPanel(
      title: title,
      compact: true,
      children: [
        StudioAssetPreview(
          height: 300,
          child: InteractiveViewer(
            key: ValueKey(
              sourceMode ? 'source-map-canvas' : 'target-map-canvas',
            ),
            transformationController: _transform,
            constrained: false,
            minScale: .01,
            maxScale: 8,
            boundaryMargin: const EdgeInsets.all(4096),
            child: RepaintBoundary(
              child: CustomPaint(
                size: Size(source.width * 32, source.height * 32),
                painter: sourceMode
                    ? SourceTilesPainter(
                        source,
                        _images,
                        widget.prepared.composition.crops,
                        autotileImages: _sourceAutotileImages,
                        autotiles: widget.prepared.composition.autotiles,
                      )
                    : NativeTilesPainter(_target!, _images),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class ConverterAtlasPreview extends StatefulWidget {
  const ConverterAtlasPreview({
    super.key,
    required this.prepared,
    required this.sourceTilesetId,
    this.autotileSlot,
  });

  final PreparedStudy prepared;
  final int sourceTilesetId;
  final int? autotileSlot;

  @override
  State<ConverterAtlasPreview> createState() => _ConverterAtlasPreviewState();
}

class _ConverterAtlasPreviewState extends State<ConverterAtlasPreview> {
  ui.Image? _image;
  String? _error;
  int _generation = 0;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  @override
  void didUpdateWidget(ConverterAtlasPreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.prepared.composition.compositionHash !=
            widget.prepared.composition.compositionHash ||
        oldWidget.sourceTilesetId != widget.sourceTilesetId ||
        oldWidget.autotileSlot != widget.autotileSlot) {
      unawaited(_load());
    }
  }

  Future<void> _load() async {
    final generation = ++_generation;
    _image?.dispose();
    _image = null;
    _error = null;
    try {
      final auto = widget.autotileSlot == null
          ? null
          : widget.prepared.composition.autotiles
                .where(
                  (value) =>
                      value.sourceTilesetId == widget.sourceTilesetId &&
                      value.autotileSlot == widget.autotileSlot,
                )
                .firstOrNull;
      final id =
          auto?.nativeTilesetId ??
          widget.prepared.composition.tilesetIds[widget.sourceTilesetId];
      final image = id == null
          ? null
          : await _decodeNativeAtlas(widget.prepared, id);
      if (!mounted || generation != _generation) {
        image?.dispose();
        return;
      }
      setState(() => _image = image);
    } catch (error) {
      if (mounted && generation == _generation) {
        setState(() => _error = 'L’atlas ne peut pas être affiché : $error');
      }
    }
  }

  @override
  void dispose() {
    _generation++;
    _image?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 12),
    child: _error != null
        ? StudioNotice(_error!, isError: true)
        : _image == null
        ? const StudioNotice('Aucun atlas préparé pour cette ressource.')
        : Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                '${_image!.width} × ${_image!.height} pixels ${widget.autotileSlot == null ? 'source' : 'assemblés · atlas de frames, aperçu statique'}',
              ),
              const SizedBox(height: 8),
              StudioAssetPreview(
                height: 240,
                child: RawImage(
                  image: _image,
                  fit: BoxFit.contain,
                  filterQuality: FilterQuality.none,
                ),
              ),
            ],
          ),
  );
}

Future<Map<String, ui.Image>> _decodeAtlases(
  PreparedStudy prepared,
  int sourceTilesetId,
) async {
  final ids = prepared.composition.crops
      .where((crop) => crop.sourceTilesetId == sourceTilesetId)
      .map((crop) => crop.nativeTilesetId)
      .toSet();
  final images = <String, ui.Image>{};
  try {
    for (final id in ids) {
      final image = await _decodeNativeAtlas(prepared, id);
      if (image != null) images[id] = image;
    }
    return Map.unmodifiable(images);
  } catch (_) {
    for (final image in images.values) {
      image.dispose();
    }
    rethrow;
  }
}

Future<ui.Image?> _decodeNativeAtlas(PreparedStudy prepared, String id) async {
  final import = prepared.composition.draft?.mutations
      .where(
        (value) =>
            value.actionId == 'tileset.import_image' &&
            value.parameters['tilesetId'] == id,
      )
      .firstOrNull;
  if (import == null) return null;
  final artifact = prepared.composition.draft?.artifacts
      .where((value) => value.handle == import.parameters['artifactHandle'])
      .firstOrNull;
  if (artifact == null) {
    throw StateError('Les pixels préparés ne correspondent pas à cet atlas.');
  }
  return _decodeArtifact(artifact, prepared.settings.writeLimits);
}

Future<Map<String, ui.Image>> _decodeSourceAutotiles(
  PreparedStudy prepared,
  int sourceTilesetId,
) async {
  final images = <String, ui.Image>{};
  try {
    for (final autotile in prepared.composition.autotiles.where(
      (value) => value.sourceTilesetId == sourceTilesetId,
    )) {
      images[autotile.nativeTilesetId] = await _decodeArtifact(
        autotile.sourceArtifact,
        prepared.settings.writeLimits,
      );
    }
    return Map.unmodifiable(images);
  } catch (_) {
    for (final image in images.values) {
      image.dispose();
    }
    rethrow;
  }
}

Future<ui.Image> _decodeArtifact(
  NativeArtifact artifact,
  NativeWriteLimits limits,
) async {
  const NativePngValidator().headerDimensions(artifact.bytes, limits: limits);
  final bytes = artifact.bytes is Uint8List
      ? artifact.bytes as Uint8List
      : Uint8List.fromList(artifact.bytes);
  final codec = await ui.instantiateImageCodec(bytes);
  try {
    final frame = await codec.getNextFrame();
    return frame.image;
  } finally {
    codec.dispose();
  }
}

class SourceTilesPainter extends CustomPainter {
  SourceTilesPainter(
    this.source,
    this.images,
    List<LiteralTileCrop> inputCrops, {
    this.autotileImages = const {},
    List<LiteralAutotileComposition> autotiles = const [],
  }) : layers =
           (source.layers.toList()
                 ..sort((a, b) => a.sourceZ.compareTo(b.sourceZ)))
               .map((layer) => layer.cells)
               .toList(growable: false),
       autotiles = Map.unmodifiable({
         for (final autotile in autotiles)
           if (autotile.sourceTilesetId == source.sourceTilesetId)
             autotile.autotileSlot: autotile,
       }),
       crops = Map.unmodifiable({
         for (final crop in inputCrops)
           if (crop.sourceTilesetId == source.sourceTilesetId)
             crop.sourceTileId: crop,
       });

  final SourceMapData source;
  final Map<String, ui.Image> images;
  final Map<String, ui.Image> autotileImages;
  final Map<int, LiteralAutotileComposition> autotiles;
  final Map<int, LiteralTileCrop> crops;
  final List<List<int>> layers;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..filterQuality = FilterQuality.none;
    for (final cells in layers) {
      for (var index = 0; index < cells.length; index++) {
        final tile = cells[index];
        if (tile == 0) continue;
        if (tile >= 48 && tile < 384) {
          final autotile = autotiles[tile ~/ 48 - 1];
          final image = autotileImages[autotile?.nativeTilesetId];
          if (autotile == null || image == null) {
            throw StateError(
              'Les pixels source originaux de cet autotile ne sont pas disponibles.',
            );
          }
          for (final part in autotile.sourceParts(
            frame: 0,
            variant: tile % 48,
          )) {
            canvas.drawImageRect(
              image,
              Rect.fromLTWH(
                part.x.toDouble(),
                part.y.toDouble(),
                part.width.toDouble(),
                part.height.toDouble(),
              ),
              Rect.fromLTWH(
                (index % source.width) * 32 + part.destinationX.toDouble(),
                (index ~/ source.width) * 32 + part.destinationY.toDouble(),
                part.width.toDouble(),
                part.height.toDouble(),
              ),
              paint,
            );
          }
          continue;
        }
        final crop = crops[tile];
        if (crop == null) throw StateError('Tuile source non préparée.');
        _paintTile(
          canvas,
          images[crop.nativeTilesetId]!,
          paint,
          crop.nativeLocalTileId,
          index,
          source.width,
        );
      }
    }
  }

  @override
  bool shouldRepaint(SourceTilesPainter oldDelegate) =>
      oldDelegate.source != source ||
      oldDelegate.images != images ||
      oldDelegate.autotileImages != autotileImages ||
      oldDelegate.autotiles != autotiles ||
      oldDelegate.crops != crops;
}

class NativeTilesPainter extends CustomPainter {
  const NativeTilesPainter(this.target, this.images);

  final MapData target;
  final Map<String, ui.Image> images;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..filterQuality = FilterQuality.none;
    for (final layer in target.layers.reversed) {
      if (layer is! TileLayer || !layer.isVisible) continue;
      for (var index = 0; index < layer.cells.length; index++) {
        final cell = layer.cells[index];
        if (cell == 0) continue;
        final entry = layer.palette[cell - 1];
        _paintTile(
          canvas,
          images[entry.tilesetId]!,
          paint,
          entry.localTileId,
          index,
          target.size.width,
        );
      }
    }
  }

  @override
  bool shouldRepaint(NativeTilesPainter oldDelegate) =>
      oldDelegate.target != target || oldDelegate.images != images;
}

void _paintTile(
  Canvas canvas,
  ui.Image image,
  Paint paint,
  int localId,
  int cellIndex,
  int mapWidth,
) {
  canvas.drawImageRect(
    image,
    Rect.fromLTWH(
      (localId % (image.width ~/ 32)) * 32,
      (localId ~/ (image.width ~/ 32)) * 32,
      32,
      32,
    ),
    Rect.fromLTWH(
      (cellIndex % mapWidth) * 32,
      (cellIndex ~/ mapWidth) * 32,
      32,
      32,
    ),
    paint,
  );
}
