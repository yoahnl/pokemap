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

    final coverage = _computeCellCoverage(
      bytesData: bytesData,
      imageWidth: image.width,
      srcLeft: srcLeft,
      srcTop: srcTop,
      cellCountX: source.width,
      cellCountY: source.height,
      cellPixelWidth: tileWidth,
      cellPixelHeight: tileHeight,
    );
    final cells = _computeCellsForPreset(
      coverageByCell: coverage,
      width: source.width,
      height: source.height,
      presetKind: presetKind,
    );
    return ElementCollisionProfile(
      source: ElementCollisionProfileSource.generated,
      cells: cells,
    );
  }

  List<double> _computeCellCoverage({
    required ByteData bytesData,
    required int imageWidth,
    required int srcLeft,
    required int srcTop,
    required int cellCountX,
    required int cellCountY,
    required int cellPixelWidth,
    required int cellPixelHeight,
  }) {
    const alphaThreshold = 110;
    final coverage =
        List<double>.filled(cellCountX * cellCountY, 0.0, growable: false);
    final cellPixelCount = cellPixelWidth * cellPixelHeight;
    if (cellPixelCount <= 0) {
      return coverage;
    }
    for (var cellY = 0; cellY < cellCountY; cellY++) {
      for (var cellX = 0; cellX < cellCountX; cellX++) {
        var solidCount = 0;
        final pixelStartX = srcLeft + cellX * cellPixelWidth;
        final pixelStartY = srcTop + cellY * cellPixelHeight;
        for (var py = 0; py < cellPixelHeight; py++) {
          final y = pixelStartY + py;
          for (var px = 0; px < cellPixelWidth; px++) {
            final x = pixelStartX + px;
            final pixelIndex = (y * imageWidth + x) * 4;
            final alpha = bytesData.getUint8(pixelIndex + 3);
            if (alpha >= alphaThreshold) {
              solidCount++;
            }
          }
        }
        coverage[cellY * cellCountX + cellX] = solidCount / cellPixelCount;
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
    final base = _cellsFromCoverage(
      coverageByCell: coverageByCell,
      width: width,
      height: height,
      minimumCoverage: presetKind == ElementPresetKind.building ? 0.2 : 0.1,
    );
    if (base.isEmpty) {
      return const [];
    }

    final cells = switch (presetKind) {
      ElementPresetKind.tree => _clipBottomAndCenter(
          cells: base,
          width: width,
          height: height,
          bottomRatio: 0.36,
          maxWidthRatio: 0.55,
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
    final maxColumns = _ratioToColumns(width, maxWidthRatio);
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
