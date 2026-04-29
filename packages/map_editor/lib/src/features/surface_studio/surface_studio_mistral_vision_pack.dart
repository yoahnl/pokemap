import 'dart:convert';
import 'dart:typed_data';

import 'package:image/image.dart' as img;

final class SurfaceStudioMistralVisionPack {
  const SurfaceStudioMistralVisionPack({
    required this.originalAtlasDataUrl,
    required this.annotatedAtlasDataUrl,
    required this.columnContactSheetDataUrl,
    required this.columnDescriptors,
  });

  final String originalAtlasDataUrl;
  final String annotatedAtlasDataUrl;
  final String columnContactSheetDataUrl;
  final List<SurfaceStudioColumnVisualDescriptor> columnDescriptors;
}

final class SurfaceStudioColumnVisualDescriptor {
  const SurfaceStudioColumnVisualDescriptor({
    required this.column,
    required this.averageColorHex,
    required this.edgeOccupancy,
    required this.hasTransparentPixels,
    required this.likelyEmpty,
    required this.localCandidateRoles,
  });

  final int column;
  final String averageColorHex;
  final SurfaceStudioColumnEdgeOccupancy edgeOccupancy;
  final bool hasTransparentPixels;
  final bool likelyEmpty;
  final List<String> localCandidateRoles;

  Map<String, Object?> toJson() => {
        'column': column,
        'averageColorHex': averageColorHex,
        'edgeOccupancy': edgeOccupancy.toJson(),
        'hasTransparentPixels': hasTransparentPixels,
        'likelyEmpty': likelyEmpty,
        'localCandidateRoles': localCandidateRoles,
      };
}

final class SurfaceStudioColumnEdgeOccupancy {
  const SurfaceStudioColumnEdgeOccupancy({
    required this.top,
    required this.right,
    required this.bottom,
    required this.left,
  });

  final double top;
  final double right;
  final double bottom;
  final double left;

  Map<String, Object?> toJson() => {
        'top': _round(top),
        'right': _round(right),
        'bottom': _round(bottom),
        'left': _round(left),
      };
}

SurfaceStudioMistralVisionPack buildSurfaceStudioMistralVisionPack({
  required Uint8List imageBytes,
  required int tileWidth,
  required int tileHeight,
  required int columnCount,
  required int frameCount,
  int originalMaxLongSide = 1400,
  int annotatedMaxLongSide = 1600,
}) {
  final decoded = _tryDecodeImage(imageBytes);
  if (decoded == null) {
    final fallback = _dataUrl(imageBytes);
    return SurfaceStudioMistralVisionPack(
      originalAtlasDataUrl: fallback,
      annotatedAtlasDataUrl: fallback,
      columnContactSheetDataUrl: fallback,
      columnDescriptors: const <SurfaceStudioColumnVisualDescriptor>[],
    );
  }

  final original = _resizeForAnalysis(decoded, originalMaxLongSide);
  final annotated = _buildAnnotatedAtlas(
    decoded,
    tileWidth: tileWidth,
    tileHeight: tileHeight,
    columnCount: columnCount,
    frameCount: frameCount,
    maxLongSide: annotatedMaxLongSide,
  );
  final contactSheet = _buildColumnContactSheet(
    decoded,
    tileWidth: tileWidth,
    tileHeight: tileHeight,
    columnCount: columnCount,
    frameCount: frameCount,
  );
  final descriptors = <SurfaceStudioColumnVisualDescriptor>[
    for (var column = 1; column <= columnCount; column++)
      _describeColumn(
        decoded,
        uiColumn: column,
        tileWidth: tileWidth,
        tileHeight: tileHeight,
        frameCount: frameCount,
      ),
  ];

  return SurfaceStudioMistralVisionPack(
    originalAtlasDataUrl: _pngDataUrl(original),
    annotatedAtlasDataUrl: _pngDataUrl(annotated),
    columnContactSheetDataUrl: _pngDataUrl(contactSheet),
    columnDescriptors: List<SurfaceStudioColumnVisualDescriptor>.unmodifiable(
      descriptors,
    ),
  );
}

String surfaceStudioColumnDescriptorsJson(
  List<SurfaceStudioColumnVisualDescriptor> descriptors,
) =>
    const JsonEncoder.withIndent('  ').convert(
      descriptors.map((descriptor) => descriptor.toJson()).toList(),
    );

img.Image _resizeForAnalysis(img.Image source, int maxLongSide) {
  final longest = source.width > source.height ? source.width : source.height;
  if (longest <= maxLongSide) {
    return img.Image.from(source);
  }
  return img.copyResize(
    source,
    width: source.width >= source.height ? maxLongSide : null,
    height: source.height > source.width ? maxLongSide : null,
    interpolation: img.Interpolation.average,
  );
}

img.Image _buildAnnotatedAtlas(
  img.Image source, {
  required int tileWidth,
  required int tileHeight,
  required int columnCount,
  required int frameCount,
  required int maxLongSide,
}) {
  final annotated = _resizeForAnalysis(source, maxLongSide);
  final safeColumns = columnCount < 1 ? 1 : columnCount;
  final safeFrames = frameCount < 1 ? 1 : frameCount;
  final columnWidth = annotated.width / safeColumns;
  final rowHeight = annotated.height / safeFrames;
  final gridColor = img.ColorRgba8(242, 200, 75, 220);
  final labelFill = img.ColorRgba8(11, 16, 32, 230);
  final labelText = img.ColorRgb8(242, 200, 75);

  for (var column = 0; column <= safeColumns; column++) {
    final x = (column * columnWidth).round().clamp(0, annotated.width - 1);
    img.drawLine(
      annotated,
      x1: x,
      y1: 0,
      x2: x,
      y2: annotated.height - 1,
      color: gridColor,
    );
  }
  for (var frame = 0; frame <= safeFrames; frame++) {
    final y = (frame * rowHeight).round().clamp(0, annotated.height - 1);
    img.drawLine(
      annotated,
      x1: 0,
      y1: y,
      x2: annotated.width - 1,
      y2: y,
      color: frame % 4 == 0 ? gridColor : img.ColorRgba8(255, 255, 255, 120),
    );
  }

  for (var column = 1; column <= safeColumns; column++) {
    final label = '$column';
    final left = ((column - 1) * columnWidth).round();
    final centerX = (left + columnWidth / 2).round();
    final desiredLabelWidth = label.length * 10 + 12;
    final maxLabelWidth = columnWidth.round();
    final labelWidth = maxLabelWidth < 24
        ? maxLabelWidth
        : desiredLabelWidth.clamp(24, maxLabelWidth).toInt();
    final labelLeft = (centerX - labelWidth ~/ 2).clamp(0, annotated.width - 1);
    img.fillRect(
      annotated,
      x1: labelLeft,
      y1: 4,
      x2: (labelLeft + labelWidth).clamp(0, annotated.width - 1),
      y2: 24,
      color: labelFill,
    );
    img.drawString(
      annotated,
      label,
      font: img.arial14,
      x: labelLeft + 5,
      y: 7,
      color: labelText,
    );
  }
  return annotated;
}

img.Image _buildColumnContactSheet(
  img.Image source, {
  required int tileWidth,
  required int tileHeight,
  required int columnCount,
  required int frameCount,
}) {
  final safeColumns = columnCount < 1 ? 1 : columnCount;
  final safeFrames = frameCount < 1 ? 1 : frameCount;
  final thumbWidth = tileWidth.clamp(32, 80).toInt();
  final thumbHeight = tileHeight.clamp(32, 80).toInt();
  const labelHeight = 24;
  const gap = 8;
  final samples = <int>{0, safeFrames ~/ 2, safeFrames - 1}.toList()..sort();
  final cellWidth = thumbWidth + 12;
  final cellHeight = labelHeight + samples.length * thumbHeight + 12;
  final sheet = img.Image(
    width: gap + safeColumns * (cellWidth + gap),
    height: cellHeight + gap * 2,
  );
  img.fill(sheet, color: img.ColorRgb8(11, 16, 32));

  for (var column = 1; column <= safeColumns; column++) {
    final cellLeft = gap + (column - 1) * (cellWidth + gap);
    img.fillRect(
      sheet,
      x1: cellLeft,
      y1: gap,
      x2: cellLeft + cellWidth,
      y2: gap + cellHeight,
      color: img.ColorRgb8(28, 36, 51),
    );
    img.drawString(
      sheet,
      '$column',
      font: img.arial14,
      x: cellLeft + 6,
      y: gap + 5,
      color: img.ColorRgb8(242, 200, 75),
    );
    for (var sampleIndex = 0; sampleIndex < samples.length; sampleIndex++) {
      final frame = samples[sampleIndex].clamp(0, safeFrames - 1);
      final tile = img.copyCrop(
        source,
        x: (column - 1) * tileWidth,
        y: frame * tileHeight,
        width: tileWidth,
        height: tileHeight,
      );
      final thumb = img.copyResize(
        tile,
        width: thumbWidth,
        height: thumbHeight,
        interpolation: img.Interpolation.nearest,
      );
      img.compositeImage(
        sheet,
        thumb,
        dstX: cellLeft + 6,
        dstY: gap + labelHeight + sampleIndex * thumbHeight,
      );
    }
  }
  return sheet;
}

SurfaceStudioColumnVisualDescriptor _describeColumn(
  img.Image source, {
  required int uiColumn,
  required int tileWidth,
  required int tileHeight,
  required int frameCount,
}) {
  final safeFrameCount = frameCount < 1 ? 1 : frameCount;
  var totalR = 0;
  var totalG = 0;
  var totalB = 0;
  var visibleCount = 0;
  var transparentCount = 0;
  var darkVisibleCount = 0;

  final xStart = (uiColumn - 1) * tileWidth;
  final frameSamples = <int>{0, safeFrameCount ~/ 2, safeFrameCount - 1};
  for (final frame in frameSamples) {
    final yStart = frame * tileHeight;
    for (var y = yStart; y < yStart + tileHeight; y++) {
      if (y < 0 || y >= source.height) {
        continue;
      }
      for (var x = xStart; x < xStart + tileWidth; x++) {
        if (x < 0 || x >= source.width) {
          continue;
        }
        final pixel = source.getPixel(x, y);
        final alpha = pixel.a.toInt();
        if (alpha < 20) {
          transparentCount++;
          continue;
        }
        final red = pixel.r.toInt();
        final green = pixel.g.toInt();
        final blue = pixel.b.toInt();
        totalR += red;
        totalG += green;
        totalB += blue;
        visibleCount++;
        if ((red + green + blue) / 3 < 10) {
          darkVisibleCount++;
        }
      }
    }
  }

  final averageColorHex = visibleCount == 0
      ? '#000000'
      : _hexColor(
          totalR ~/ visibleCount,
          totalG ~/ visibleCount,
          totalB ~/ visibleCount,
        );
  final sampledPixels = visibleCount + transparentCount;
  final transparentRatio =
      sampledPixels == 0 ? 1.0 : transparentCount / sampledPixels;
  final darkRatio = visibleCount == 0 ? 1.0 : darkVisibleCount / visibleCount;
  final likelyEmpty = transparentRatio > 0.9 || darkRatio > 0.95;
  final edgeOccupancy = _edgeOccupancy(
    source,
    xStart: xStart,
    yStart: 0,
    tileWidth: tileWidth,
    tileHeight: tileHeight,
  );

  return SurfaceStudioColumnVisualDescriptor(
    column: uiColumn,
    averageColorHex: averageColorHex,
    edgeOccupancy: edgeOccupancy,
    hasTransparentPixels: transparentCount > 0,
    likelyEmpty: likelyEmpty,
    localCandidateRoles: likelyEmpty
        ? const <String>[]
        : _candidateRolesFromEdges(edgeOccupancy),
  );
}

SurfaceStudioColumnEdgeOccupancy _edgeOccupancy(
  img.Image source, {
  required int xStart,
  required int yStart,
  required int tileWidth,
  required int tileHeight,
}) {
  double occupied(int x, int y) {
    if (x < 0 || x >= source.width || y < 0 || y >= source.height) {
      return 0;
    }
    final pixel = source.getPixel(x, y);
    final alpha = pixel.a.toInt();
    final brightness = (pixel.r + pixel.g + pixel.b) / 3;
    return alpha > 20 && brightness > 10 ? 1 : 0;
  }

  var top = 0.0;
  var bottom = 0.0;
  for (var x = xStart; x < xStart + tileWidth; x++) {
    top += occupied(x, yStart);
    bottom += occupied(x, yStart + tileHeight - 1);
  }
  var left = 0.0;
  var right = 0.0;
  for (var y = yStart; y < yStart + tileHeight; y++) {
    left += occupied(xStart, y);
    right += occupied(xStart + tileWidth - 1, y);
  }
  return SurfaceStudioColumnEdgeOccupancy(
    top: top / tileWidth,
    right: right / tileHeight,
    bottom: bottom / tileWidth,
    left: left / tileHeight,
  );
}

List<String> _candidateRolesFromEdges(
  SurfaceStudioColumnEdgeOccupancy occupancy,
) {
  final candidates = <String>['isolated'];
  if (occupancy.top > 0.55) {
    candidates.add('endNorth');
  }
  if (occupancy.right > 0.55) {
    candidates.add('endEast');
  }
  if (occupancy.bottom > 0.55) {
    candidates.add('endSouth');
  }
  if (occupancy.left > 0.55) {
    candidates.add('endWest');
  }
  return List<String>.unmodifiable(candidates);
}

String _pngDataUrl(img.Image image) =>
    'data:image/png;base64,${base64Encode(img.encodePng(image))}';

String _dataUrl(Uint8List bytes) =>
    'data:image/png;base64,${base64Encode(bytes)}';

String _hexColor(int red, int green, int blue) =>
    '#${_hex(red)}${_hex(green)}${_hex(blue)}';

String _hex(int value) => value.clamp(0, 255).toRadixString(16).padLeft(2, '0');

double _round(double value) => double.parse(value.toStringAsFixed(3));

img.Image? _tryDecodeImage(Uint8List imageBytes) {
  try {
    return img.decodeImage(imageBytes);
  } catch (_) {
    return null;
  }
}
