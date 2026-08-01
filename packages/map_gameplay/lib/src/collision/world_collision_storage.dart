import 'dart:typed_data';

import 'package:map_core/map_core.dart';

/// Immutable static collision storage for one gameplay map.
///
/// Authoring tile/cell collisions remain O(map cells). Pixel precision is
/// allocated only for chunks touched by an explicit element collision mask;
/// there is deliberately no `worldWidthPx * worldHeightPx` bitmap.
final class WorldCollisionStorage {
  WorldCollisionStorage._({
    required this.widthCells,
    required this.heightCells,
    required this.tileWidthPx,
    required this.tileHeightPx,
    required List<bool> tileCollisionCells,
    required List<bool> placedElementCollisionCells,
    required Map<(int, int), Uint32List> pixelMaskWordsByChunk,
  })  : _tileCollisionCells = tileCollisionCells,
        _placedElementCollisionCells = placedElementCollisionCells,
        _pixelMaskWordsByChunk = pixelMaskWordsByChunk;

  final int widthCells;
  final int heightCells;
  final int tileWidthPx;
  final int tileHeightPx;
  final List<bool> _tileCollisionCells;
  final List<bool> _placedElementCollisionCells;
  final Map<(int, int), Uint32List> _pixelMaskWordsByChunk;

  int get widthPx => widthCells * tileWidthPx;
  int get heightPx => heightCells * tileHeightPx;
  int get allocatedPixelMaskChunkCount => _pixelMaskWordsByChunk.length;
  int get allocatedPixelMaskWordCount =>
      _pixelMaskWordsByChunk.length * WorldCollisionStorageBuilder.chunkSize;

  bool collidesPixelRect(
    PixelRect rect, {
    required bool Function(int cellIndex) isDynamicCellBlocked,
  }) {
    for (var localY = 0; localY < rect.heightPx; localY += 1) {
      final y = rect.topPx + localY;
      for (var localX = 0; localX < rect.widthPx; localX += 1) {
        final x = rect.leftPx + localX;
        if (_isPixelBlocked(
          x,
          y,
          isDynamicCellBlocked: isDynamicCellBlocked,
        )) {
          return true;
        }
      }
    }
    return false;
  }

  bool isCellCenterBlocked(
    int cellX,
    int cellY, {
    required bool Function(int cellIndex) isDynamicCellBlocked,
  }) {
    if (cellX < 0 || cellY < 0 || cellX >= widthCells || cellY >= heightCells) {
      return true;
    }
    return _isPixelBlocked(
      cellX * tileWidthPx + tileWidthPx ~/ 2,
      cellY * tileHeightPx + tileHeightPx ~/ 2,
      isDynamicCellBlocked: isDynamicCellBlocked,
    );
  }

  bool _isPixelBlocked(
    int x,
    int y, {
    required bool Function(int cellIndex) isDynamicCellBlocked,
  }) {
    if (x < 0 || y < 0 || x >= widthPx || y >= heightPx) {
      return true;
    }
    final cellX = x ~/ tileWidthPx;
    final cellY = y ~/ tileHeightPx;
    final cellIndex = cellY * widthCells + cellX;
    if (_valueAt(_tileCollisionCells, cellIndex) ||
        _valueAt(_placedElementCollisionCells, cellIndex) ||
        isDynamicCellBlocked(cellIndex)) {
      return true;
    }

    final chunk = _pixelMaskWordsByChunk[(
      x ~/ WorldCollisionStorageBuilder.chunkSize,
      y ~/ WorldCollisionStorageBuilder.chunkSize
    )];
    if (chunk == null) {
      return false;
    }
    final localX = x % WorldCollisionStorageBuilder.chunkSize;
    final localY = y % WorldCollisionStorageBuilder.chunkSize;
    return (chunk[localY] & (1 << localX)) != 0;
  }
}

/// Mutable construction seam; discarded immediately after map loading.
final class WorldCollisionStorageBuilder {
  WorldCollisionStorageBuilder({
    required this.widthCells,
    required this.heightCells,
    required int tileWidthPx,
    required int tileHeightPx,
    required this.tileCollisionCells,
    required this.placedElementCollisionCells,
  })  : tileWidthPx = tileWidthPx <= 0 ? 16 : tileWidthPx,
        tileHeightPx = tileHeightPx <= 0 ? 16 : tileHeightPx;

  static const int chunkSize = 32;

  final int widthCells;
  final int heightCells;
  final int tileWidthPx;
  final int tileHeightPx;
  final List<bool> tileCollisionCells;
  final List<bool> placedElementCollisionCells;
  final Map<(int, int), Uint32List> _pixelMaskWordsByChunk =
      <(int, int), Uint32List>{};

  int get widthPx => widthCells * tileWidthPx;
  int get heightPx => heightCells * tileHeightPx;

  /// Stamps one transformed packed mask. Invalid masks remain a no-op, matching
  /// the historical runtime's fail-open behavior for malformed project data.
  bool stampPackedMask({
    required int leftPx,
    required int topPx,
    required ElementCollisionPixelMask mask,
    required QuarterTurnPixelTransform transform,
  }) {
    List<bool> decoded;
    try {
      decoded = ElementCollisionMaskCodec.decodePackedBits(
        widthPx: mask.widthPx,
        heightPx: mask.heightPx,
        dataBase64: mask.dataBase64,
      );
    } catch (_) {
      return false;
    }

    final destinationSize = transform.destinationPixelSize;
    final destinationLeft = BigInt.from(leftPx);
    final destinationTop = BigInt.from(topPx);
    final destinationRight =
        destinationLeft + BigInt.from(destinationSize.width);
    final destinationBottom =
        destinationTop + BigInt.from(destinationSize.height);
    final worldWidth = BigInt.from(widthPx);
    final worldHeight = BigInt.from(heightPx);
    if (destinationRight <= BigInt.zero ||
        destinationBottom <= BigInt.zero ||
        destinationLeft >= worldWidth ||
        destinationTop >= worldHeight) {
      return true;
    }

    final startX =
        (destinationLeft.isNegative ? -destinationLeft : BigInt.zero).toInt();
    final startY =
        (destinationTop.isNegative ? -destinationTop : BigInt.zero).toInt();
    final endX = (destinationRight > worldWidth
            ? worldWidth - destinationLeft
            : BigInt.from(destinationSize.width))
        .toInt();
    final endY = (destinationBottom > worldHeight
            ? worldHeight - destinationTop
            : BigInt.from(destinationSize.height))
        .toInt();

    for (var destinationY = startY; destinationY < endY; destinationY += 1) {
      for (var destinationX = startX; destinationX < endX; destinationX += 1) {
        final source = transform.destinationPixelToSourcePixel(
          GridPos(x: destinationX, y: destinationY),
        );
        final sourceIndex = source.y * mask.widthPx + source.x;
        if (sourceIndex < 0 ||
            sourceIndex >= decoded.length ||
            !decoded[sourceIndex]) {
          continue;
        }
        _setPixel(leftPx + destinationX, topPx + destinationY);
      }
    }
    return true;
  }

  WorldCollisionStorage build() {
    return WorldCollisionStorage._(
      widthCells: widthCells,
      heightCells: heightCells,
      tileWidthPx: tileWidthPx,
      tileHeightPx: tileHeightPx,
      tileCollisionCells: List<bool>.unmodifiable(tileCollisionCells),
      placedElementCollisionCells:
          List<bool>.unmodifiable(placedElementCollisionCells),
      // Copy the mutable construction chunks so a discarded builder can never
      // mutate storage already shared by later immutable world states.
      pixelMaskWordsByChunk: Map<(int, int), Uint32List>.unmodifiable(
        <(int, int), Uint32List>{
          for (final entry in _pixelMaskWordsByChunk.entries)
            entry.key: Uint32List.fromList(entry.value),
        },
      ),
    );
  }

  void _setPixel(int x, int y) {
    if (x < 0 || y < 0 || x >= widthPx || y >= heightPx) {
      return;
    }
    final key = (x ~/ chunkSize, y ~/ chunkSize);
    final words = _pixelMaskWordsByChunk.putIfAbsent(
      key,
      () => Uint32List(chunkSize),
    );
    words[y % chunkSize] |= 1 << (x % chunkSize);
  }
}

bool _valueAt(List<bool> values, int index) =>
    index >= 0 && index < values.length && values[index];
