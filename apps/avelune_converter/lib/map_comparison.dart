import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:avelune_converter_adapters/avelune_converter_adapters.dart';
import 'package:avelune_converter_core/avelune_converter_core.dart';
import 'package:avelune_studio/avelune_design_system.dart';
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
  ui.Image? _image;
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
    _image?.dispose();
    _image = null;
    _error = null;
    _emptyImage = false;
    if (_target == null) return;
    try {
      final image = await _decodeAtlas(
        widget.prepared,
        _source.sourceTilesetId,
      );
      if (!mounted || generation != _generation) {
        image?.dispose();
        return;
      }
      setState(() {
        _image = image;
        _emptyImage = image == null;
      });
    } catch (error) {
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
    _image?.dispose();
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
    if (_image == null && !_emptyImage) {
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
              'La vue source reconstruit les tuiles lues ; elle n’est pas une capture du jeu Essentials. Les priorités d’acteurs, événements et comportements ne sont pas certifiés par cette comparaison.',
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
                    ? SourceTilesPainter(source, _image)
                    : NativeTilesPainter(_target!, _image),
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
  });

  final PreparedStudy prepared;
  final int sourceTilesetId;

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
        oldWidget.sourceTilesetId != widget.sourceTilesetId) {
      unawaited(_load());
    }
  }

  Future<void> _load() async {
    final generation = ++_generation;
    _image?.dispose();
    _image = null;
    _error = null;
    try {
      final image = await _decodeAtlas(widget.prepared, widget.sourceTilesetId);
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
              Text('${_image!.width} × ${_image!.height} pixels source'),
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

Future<ui.Image?> _decodeAtlas(
  PreparedStudy prepared,
  int sourceTilesetId,
) async {
  Sha256Hash? hash;
  for (final crop in prepared.composition.crops) {
    if (crop.sourceTilesetId == sourceTilesetId) {
      hash = crop.imageSha256;
      break;
    }
  }
  if (hash == null) return null;
  final artifact = prepared.composition.draft?.artifacts
      .where((value) => value.rawSha256 == hash)
      .firstOrNull;
  if (artifact == null) {
    throw StateError('Les pixels préparés ne correspondent pas à cet atlas.');
  }
  const NativePngValidator().headerDimensions(
    artifact.bytes,
    limits: prepared.settings.writeLimits,
  );
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
  SourceTilesPainter(this.source, this.image)
    : layers =
          (source.layers.toList()
                ..sort((a, b) => a.sourceZ.compareTo(b.sourceZ)))
              .map((layer) => layer.cells)
              .toList(growable: false);

  final SourceMapData source;
  final ui.Image? image;
  final List<List<int>> layers;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..filterQuality = FilterQuality.none;
    for (final cells in layers) {
      for (var index = 0; index < cells.length; index++) {
        final tile = cells[index];
        if (tile == 0) continue;
        if (tile < 384) throw StateError('Tuile source non prise en charge.');
        _paintTile(canvas, image!, paint, tile - 384, index, source.width);
      }
    }
  }

  @override
  bool shouldRepaint(SourceTilesPainter oldDelegate) =>
      oldDelegate.source != source || oldDelegate.image != image;
}

class NativeTilesPainter extends CustomPainter {
  const NativeTilesPainter(this.target, this.image);

  final MapData target;
  final ui.Image? image;

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
          image!,
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
      oldDelegate.target != target || oldDelegate.image != image;
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
    Rect.fromLTWH((localId % 8) * 32, (localId ~/ 8) * 32, 32, 32),
    Rect.fromLTWH(
      (cellIndex % mapWidth) * 32,
      (cellIndex ~/ mapWidth) * 32,
      32,
      32,
    ),
    paint,
  );
}
