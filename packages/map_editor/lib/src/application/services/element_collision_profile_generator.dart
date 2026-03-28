import 'dart:math' as math;
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:map_core/map_core.dart';

class ElementCollisionProfileGenerator {
  const ElementCollisionProfileGenerator();

  Future<ElementCollisionProfile> generate({
    required String tilesetImagePath,
    required TilesetSourceRect source,
    required int tileWidth,
    required int tileHeight,
    required ElementPresetKind presetKind,
    WarpTriggerPadding padding = const WarpTriggerPadding(),
  }) async {
    final normalizedPath = tilesetImagePath.trim();
    if (normalizedPath.isEmpty) {
      throw const FormatException('Tileset image path is empty');
    }
    if (tileWidth <= 0 || tileHeight <= 0) {
      throw const FormatException('Tile size must be strictly positive');
    }
    if (source.width <= 0 || source.height <= 0) {
      throw const FormatException(
          'Element source size must be strictly positive');
    }

    final file = File(normalizedPath);
    if (!await file.exists()) {
      throw FileSystemException('Tileset image not found', normalizedPath);
    }
    final bytes = await file.readAsBytes();
    if (bytes.isEmpty) {
      throw const FormatException('Tileset image is empty');
    }

    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    final image = frame.image;
    final srcLeft = source.x * tileWidth;
    final srcTop = source.y * tileHeight;
    final srcWidth = source.width * tileWidth;
    final srcHeight = source.height * tileHeight;
    if (srcLeft < 0 ||
        srcTop < 0 ||
        srcLeft + srcWidth > image.width ||
        srcTop + srcHeight > image.height) {
      throw const FormatException(
          'Element source rectangle is outside tileset bounds');
    }

    final bytesData =
        await image.toByteData(format: ui.ImageByteFormat.rawRgba);
    if (bytesData == null) {
      throw const FormatException('Unable to read tileset image pixels');
    }

    final resolvedPadding = _resolveAutoPadding(
      presetKind: presetKind,
      padding: padding,
      tileWidth: tileWidth,
      tileHeight: tileHeight,
    );

    final coverage = _computeCellCoverage(
      bytesData: bytesData,
      imageWidth: image.width,
      srcLeft: srcLeft,
      srcTop: srcTop,
      srcWidth: srcWidth,
      srcHeight: srcHeight,
      cellCountX: source.width,
      cellCountY: source.height,
      cellPixelWidth: tileWidth,
      cellPixelHeight: tileHeight,
      padding: resolvedPadding,
    );
    final cells = _computeCellsForPreset(
      coverageByCell: coverage,
      width: source.width,
      height: source.height,
      presetKind: presetKind,
    );
    return ElementCollisionProfile(
      source: ElementCollisionProfileSource.generated,
      padding: resolvedPadding,
      cells: cells,
    );
  }

  WarpTriggerPadding _resolveAutoPadding({
    required ElementPresetKind presetKind,
    required WarpTriggerPadding padding,
    required int tileWidth,
    required int tileHeight,
  }) {
    if (padding.top > 0 ||
        padding.right > 0 ||
        padding.bottom > 0 ||
        padding.left > 0) {
      return padding;
    }

    int px(double ratio, int tile) {
      return math.max(0, (tile * ratio).round());
    }

    return switch (presetKind) {
      ElementPresetKind.tree => WarpTriggerPadding(
          left: px(0.18, tileWidth),
          right: px(0.18, tileWidth),
          bottom: px(0.06, tileHeight),
        ),
      ElementPresetKind.building => WarpTriggerPadding(
          left: px(0.10, tileWidth),
          right: px(0.10, tileWidth),
        ),
      ElementPresetKind.rock => WarpTriggerPadding(
          left: px(0.12, tileWidth),
          right: px(0.12, tileWidth),
        ),
      ElementPresetKind.tallDecoration => WarpTriggerPadding(
          left: px(0.15, tileWidth),
          right: px(0.15, tileWidth),
        ),
      ElementPresetKind.cliff ||
      ElementPresetKind.generic =>
        const WarpTriggerPadding(),
    };
  }

  List<double> _computeCellCoverage({
    required ByteData bytesData,
    required int imageWidth,
    required int srcLeft,
    required int srcTop,
    required int srcWidth,
    required int srcHeight,
    required int cellCountX,
    required int cellCountY,
    required int cellPixelWidth,
    required int cellPixelHeight,
    required WarpTriggerPadding padding,
  }) {
    const alphaThreshold = 110;
    final coverage =
        List<double>.filled(cellCountX * cellCountY, 0.0, growable: false);
    if (cellPixelWidth <= 0 || cellPixelHeight <= 0) {
      return coverage;
    }
    final padLeft = padding.left.clamp(0, srcWidth);
    final padRight = padding.right.clamp(0, srcWidth);
    final padTop = padding.top.clamp(0, srcHeight);
    final padBottom = padding.bottom.clamp(0, srcHeight);
    final clipLeft = padLeft;
    final clipTop = padTop;
    final clipRight = math.max(clipLeft, srcWidth - padRight);
    final clipBottom = math.max(clipTop, srcHeight - padBottom);

    for (var cellY = 0; cellY < cellCountY; cellY++) {
      for (var cellX = 0; cellX < cellCountX; cellX++) {
        var solidCount = 0;
        var sampledPixelCount = 0;
        final pixelStartX = srcLeft + cellX * cellPixelWidth;
        final pixelStartY = srcTop + cellY * cellPixelHeight;
        for (var py = 0; py < cellPixelHeight; py++) {
          final localY = cellY * cellPixelHeight + py;
          if (localY < clipTop || localY >= clipBottom) {
            continue;
          }
          final y = pixelStartY + py;
          for (var px = 0; px < cellPixelWidth; px++) {
            final localX = cellX * cellPixelWidth + px;
            if (localX < clipLeft || localX >= clipRight) {
              continue;
            }
            sampledPixelCount++;
            final x = pixelStartX + px;
            final pixelIndex = (y * imageWidth + x) * 4;
            final alpha = bytesData.getUint8(pixelIndex + 3);
            if (alpha >= alphaThreshold) {
              solidCount++;
            }
          }
        }
        coverage[cellY * cellCountX + cellX] =
            sampledPixelCount <= 0 ? 0 : solidCount / sampledPixelCount;
      }
    }
    return coverage;
  }

  List<GridPos> _computeCellsForPreset({
    required List<double> coverageByCell,
    required int width,
    required int height,
    required ElementPresetKind presetKind,
  }) {
    final minimumCoverage = _minimumCoverageForPreset(presetKind);
    var base = _cellsFromCoverage(
      coverageByCell: coverageByCell,
      width: width,
      height: height,
      minimumCoverage: minimumCoverage,
    );
    if (base.isEmpty) {
      base = _cellsFromCoverage(
        coverageByCell: coverageByCell,
        width: width,
        height: height,
        minimumCoverage: (minimumCoverage * 0.6).clamp(0.06, 0.18),
      );
    }
    if (base.isEmpty) {
      return const [];
    }

    final cells = switch (presetKind) {
      ElementPresetKind.tree => _clipBottomAndCenter(
          cells: base,
          width: width,
          height: height,
          bottomRatio: 0.34,
          maxWidthRatio: 0.45,
          forceSingleColumnWhenNarrow: true,
        ),
      ElementPresetKind.building => _clipBottomBand(
          cells: base,
          height: height,
          bottomRatio: 0.62,
        ),
      ElementPresetKind.rock => _clipBottomAndCenter(
          cells: base,
          width: width,
          height: height,
          bottomRatio: 0.52,
          maxWidthRatio: 0.75,
        ),
      ElementPresetKind.cliff => _clipBottomBand(
          cells: base,
          height: height,
          bottomRatio: 0.72,
        ),
      ElementPresetKind.tallDecoration => _clipBottomAndCenter(
          cells: base,
          width: width,
          height: height,
          bottomRatio: 0.42,
          maxWidthRatio: 0.6,
        ),
      ElementPresetKind.generic => base,
    };
    return _normalizeCells(cells);
  }

  double _minimumCoverageForPreset(ElementPresetKind presetKind) {
    return switch (presetKind) {
      ElementPresetKind.tree => 0.24,
      ElementPresetKind.building => 0.18,
      ElementPresetKind.rock => 0.2,
      ElementPresetKind.cliff => 0.16,
      ElementPresetKind.tallDecoration => 0.2,
      ElementPresetKind.generic => 0.14,
    };
  }

  List<GridPos> _cellsFromCoverage({
    required List<double> coverageByCell,
    required int width,
    required int height,
    required double minimumCoverage,
  }) {
    final out = <GridPos>[];
    for (var y = 0; y < height; y++) {
      for (var x = 0; x < width; x++) {
        final value = coverageByCell[y * width + x];
        if (value >= minimumCoverage) {
          out.add(GridPos(x: x, y: y));
        }
      }
    }
    return out;
  }

  List<GridPos> _clipBottomBand({
    required List<GridPos> cells,
    required int height,
    required double bottomRatio,
  }) {
    final bottomRows = _ratioToRows(height, bottomRatio);
    final startRow = height - bottomRows;
    final filtered =
        cells.where((cell) => cell.y >= startRow).toList(growable: false);
    if (filtered.isNotEmpty) {
      return filtered;
    }
    final fallback =
        cells.where((cell) => cell.y == height - 1).toList(growable: false);
    if (fallback.isNotEmpty) {
      return fallback;
    }
    return cells;
  }

  List<GridPos> _clipBottomAndCenter({
    required List<GridPos> cells,
    required int width,
    required int height,
    required double bottomRatio,
    required double maxWidthRatio,
    bool forceSingleColumnWhenNarrow = false,
  }) {
    final bottom = _clipBottomBand(
      cells: cells,
      height: height,
      bottomRatio: bottomRatio,
    );
    if (bottom.isEmpty) {
      return bottom;
    }
    final uniqueColumns =
        bottom.map((cell) => cell.x).toSet().toList(growable: false)..sort();
    final maxColumns = forceSingleColumnWhenNarrow && width <= 2
        ? 1
        : _ratioToColumns(width, maxWidthRatio);
    final allowedColumns = uniqueColumns.length <= maxColumns
        ? uniqueColumns.toSet()
        : _pickColumnsNearCenter(
            columns: uniqueColumns,
            width: width,
            maxColumns: maxColumns,
          );
    final filtered = bottom
        .where((cell) => allowedColumns.contains(cell.x))
        .toList(growable: false);
    if (filtered.isNotEmpty) {
      return filtered;
    }
    final fallbackX = ((width - 1) / 2).round().clamp(0, width - 1);
    final fallbackY = height - 1;
    return [GridPos(x: fallbackX, y: fallbackY)];
  }

  int _ratioToRows(int height, double ratio) {
    final raw = (height * ratio).ceil();
    if (raw <= 0) {
      return 1;
    }
    if (raw > height) {
      return height;
    }
    return raw;
  }

  int _ratioToColumns(int width, double ratio) {
    final raw = (width * ratio).ceil();
    if (raw <= 0) {
      return 1;
    }
    if (raw > width) {
      return width;
    }
    return raw;
  }

  Set<int> _pickColumnsNearCenter({
    required List<int> columns,
    required int width,
    required int maxColumns,
  }) {
    final center = (width - 1) / 2.0;
    final sortedByDistance = List<int>.from(columns, growable: false)
      ..sort((a, b) => (a - center).abs().compareTo((b - center).abs()));
    final selected = sortedByDistance.take(maxColumns).toSet();
    if (selected.isNotEmpty) {
      return selected;
    }
    return {center.round().clamp(0, width - 1)};
  }

  List<GridPos> _normalizeCells(List<GridPos> cells) {
    final seen = <String>{};
    final unique = <GridPos>[];
    for (final cell in cells) {
      final key = '${cell.x}:${cell.y}';
      if (!seen.add(key)) {
        continue;
      }
      unique.add(cell);
    }
    unique.sort((a, b) {
      final yCompare = a.y.compareTo(b.y);
      if (yCompare != 0) {
        return yCompare;
      }
      return a.x.compareTo(b.x);
    });
    return unique;
  }
}
