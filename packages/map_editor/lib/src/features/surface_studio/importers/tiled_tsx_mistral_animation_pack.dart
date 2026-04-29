import 'dart:convert';
import 'dart:typed_data';

import 'package:image/image.dart' as img;

import 'tiled_tsx_mistral_grouping_models.dart';

final class TiledTsxMistralAnimationPack {
  const TiledTsxMistralAnimationPack({
    required this.contactSheetDataUrl,
    required this.metadataJson,
  });

  final String contactSheetDataUrl;
  final String metadataJson;
}

TiledTsxMistralAnimationPack buildTiledTsxMistralAnimationPack({
  required TiledTsxMistralGroupingRequest request,
  required Uint8List? atlasImageBytes,
}) {
  final decoded = _tryDecodeImage(atlasImageBytes);
  final metadata = _metadataForRequest(request);
  final sheet = _buildAnimationContactSheet(
    request: request,
    decodedAtlas: decoded,
  );
  return TiledTsxMistralAnimationPack(
    contactSheetDataUrl: _pngDataUrl(sheet),
    metadataJson: const JsonEncoder.withIndent('  ').convert(metadata),
  );
}

Map<String, Object?> _metadataForRequest(
  TiledTsxMistralGroupingRequest request,
) {
  return {
    'tileWidth': request.tileWidth,
    'tileHeight': request.tileHeight,
    'atlasColumns': request.atlasColumns,
    'atlasRows': request.atlasRows,
    'animations': [
      for (final animation in request.animations)
        {
          'animationId': animation.id,
          'frameCount': animation.frameCount,
          'totalDurationMs': animation.totalDurationMs,
          'firstFrame': _frameMetadata(animation.timeline.frames.first, 0),
          'sampledFrames': [
            for (final index in _sampleFrameIndexes(animation.frameCount))
              _frameMetadata(animation.timeline.frames[index], index),
          ],
        },
    ],
  };
}

Map<String, Object?> _frameMetadata(dynamic frame, int index) {
  return {
    'index': index,
    'column': frame.tileRef.column,
    'row': frame.tileRef.row,
    'durationMs': frame.durationMs,
  };
}

img.Image _buildAnimationContactSheet({
  required TiledTsxMistralGroupingRequest request,
  required img.Image? decodedAtlas,
}) {
  final animations = request.animations;
  const gap = 10;
  const labelHeight = 34;
  const footerHeight = 22;
  final thumbWidth = request.tileWidth.clamp(32, 72).toInt();
  final thumbHeight = request.tileHeight.clamp(32, 72).toInt();
  const sampleCount = 3;
  final cardWidth = 18 + sampleCount * thumbWidth + (sampleCount - 1) * 6;
  final cardHeight = labelHeight + thumbHeight + footerHeight + 18;
  final columns = animations.length <= 2 ? animations.length.clamp(1, 2) : 3;
  final rows =
      ((animations.length + columns - 1) / columns).ceil().clamp(1, 999);
  final sheet = img.Image(
    width: gap + columns * (cardWidth + gap),
    height: gap + rows * (cardHeight + gap),
  );
  img.fill(sheet, color: img.ColorRgb8(11, 16, 32));

  for (var i = 0; i < animations.length; i++) {
    final animation = animations[i];
    final column = i % columns;
    final row = i ~/ columns;
    final left = gap + column * (cardWidth + gap);
    final top = gap + row * (cardHeight + gap);
    _drawAnimationCard(
      sheet,
      animation: animation,
      decodedAtlas: decodedAtlas,
      request: request,
      left: left,
      top: top,
      width: cardWidth,
      height: cardHeight,
      thumbWidth: thumbWidth,
      thumbHeight: thumbHeight,
      index: i + 1,
    );
  }
  return sheet;
}

void _drawAnimationCard(
  img.Image sheet, {
  required dynamic animation,
  required img.Image? decodedAtlas,
  required TiledTsxMistralGroupingRequest request,
  required int left,
  required int top,
  required int width,
  required int height,
  required int thumbWidth,
  required int thumbHeight,
  required int index,
}) {
  img.fillRect(
    sheet,
    x1: left,
    y1: top,
    x2: left + width,
    y2: top + height,
    color: img.ColorRgb8(28, 36, 51),
  );
  img.drawString(
    sheet,
    '$index ${animation.id}',
    font: img.arial14,
    x: left + 7,
    y: top + 7,
    color: img.ColorRgb8(242, 200, 75),
  );
  final samples = _sampleFrameIndexes(animation.frameCount);
  for (var sampleIndex = 0; sampleIndex < samples.length; sampleIndex++) {
    final frameIndex = samples[sampleIndex];
    final frame = animation.timeline.frames[frameIndex];
    final dstX = left + 7 + sampleIndex * (thumbWidth + 6);
    final dstY = top + 34;
    final tile = _tileImageForFrame(
      decodedAtlas: decodedAtlas,
      request: request,
      column: frame.tileRef.column,
      row: frame.tileRef.row,
    );
    final thumb = img.copyResize(
      tile,
      width: thumbWidth,
      height: thumbHeight,
      interpolation: img.Interpolation.nearest,
    );
    img.compositeImage(sheet, thumb, dstX: dstX, dstY: dstY);
    img.drawString(
      sheet,
      'f${frameIndex + 1}',
      font: img.arial14,
      x: dstX,
      y: dstY + thumbHeight + 3,
      color: img.ColorRgb8(184, 196, 210),
    );
  }
}

img.Image _tileImageForFrame({
  required img.Image? decodedAtlas,
  required TiledTsxMistralGroupingRequest request,
  required int column,
  required int row,
}) {
  if (decodedAtlas == null) {
    final fallback =
        img.Image(width: request.tileWidth, height: request.tileHeight);
    img.fill(fallback, color: img.ColorRgb8(51, 65, 85));
    return fallback;
  }
  final x = column * request.tileWidth;
  final y = row * request.tileHeight;
  if (x < 0 ||
      y < 0 ||
      x + request.tileWidth > decodedAtlas.width ||
      y + request.tileHeight > decodedAtlas.height) {
    final fallback =
        img.Image(width: request.tileWidth, height: request.tileHeight);
    img.fill(fallback, color: img.ColorRgb8(127, 29, 29));
    return fallback;
  }
  return img.copyCrop(
    decodedAtlas,
    x: x,
    y: y,
    width: request.tileWidth,
    height: request.tileHeight,
  );
}

List<int> _sampleFrameIndexes(int frameCount) {
  if (frameCount <= 0) {
    return const <int>[0];
  }
  final indexes = <int>{0, frameCount ~/ 2, frameCount - 1}.toList()..sort();
  return List<int>.unmodifiable(indexes);
}

img.Image? _tryDecodeImage(Uint8List? bytes) {
  if (bytes == null || bytes.isEmpty) {
    return null;
  }
  try {
    return img.decodeImage(bytes);
  } catch (_) {
    return null;
  }
}

String _pngDataUrl(img.Image image) =>
    'data:image/png;base64,${base64Encode(img.encodePng(image))}';
