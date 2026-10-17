import 'dart:typed_data';

import 'package:map_core/map_core.dart';

import 'border_collision_geometry.dart';

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
    required Map<(int, int), Map<BorderCollisionOwner, Uint32List>>
        borderMaskWordsByChunk,
    required Map<(int, int), Uint32List> borderAggregateWordsByChunk,
    required this.supportableTerrainCellsByLayer,
    required this.supportRectsByLayer,
    required Map<String, Map<int, List<PixelRect>>> supportableTerrainRectsByCell,
  })  : _tileCollisionCells = tileCollisionCells,
        _placedElementCollisionCells = placedElementCollisionCells,
        _pixelMaskWordsByChunk = pixelMaskWordsByChunk,
        _borderMaskWordsByChunk = borderMaskWordsByChunk,
        _borderAggregateWordsByChunk = borderAggregateWordsByChunk,
        _supportableTerrainRectsByCell = supportableTerrainRectsByCell,
        _supportableTerrainLayerIds = List.unmodifiable({
          ...supportableTerrainCellsByLayer.keys,
          ...supportableTerrainRectsByCell.keys,
        });

  final int widthCells;
  final int heightCells;
  final int tileWidthPx;
  final int tileHeightPx;
  final List<bool> _tileCollisionCells;
  final List<bool> _placedElementCollisionCells;
  final Map<(int, int), Uint32List> _pixelMaskWordsByChunk;
  final Map<(int, int), Map<BorderCollisionOwner, Uint32List>>
      _borderMaskWordsByChunk;
  final Map<(int, int), Uint32List> _borderAggregateWordsByChunk;
  final Map<String, List<bool>> supportableTerrainCellsByLayer;
  final Map<String, List<PixelRect>> supportRectsByLayer;
  final Map<String, Map<int, List<PixelRect>>> _supportableTerrainRectsByCell;
  final List<String> _supportableTerrainLayerIds;

  int get widthPx => widthCells * tileWidthPx;
  int get heightPx => heightCells * tileHeightPx;
  int get allocatedPixelMaskChunkCount =>
      _pixelMaskWordsByChunk.length +
      _borderAggregateWordsByChunk.length +
      _borderMaskWordsByChunk.values
          .fold<int>(0, (count, owners) => count + owners.length);
  int get allocatedPixelMaskWordCount =>
      allocatedPixelMaskChunkCount * WorldCollisionStorageBuilder.chunkSize;

  WorldCollisionStorage withSupportRectsByLayer(
    Map<String, List<PixelRect>> rectangles,
  ) => WorldCollisionStorage._(
    widthCells: widthCells,
    heightCells: heightCells,
    tileWidthPx: tileWidthPx,
    tileHeightPx: tileHeightPx,
    tileCollisionCells: _tileCollisionCells,
    placedElementCollisionCells: _placedElementCollisionCells,
    pixelMaskWordsByChunk: _pixelMaskWordsByChunk,
    borderMaskWordsByChunk: _borderMaskWordsByChunk,
    borderAggregateWordsByChunk: _borderAggregateWordsByChunk,
    supportableTerrainCellsByLayer: supportableTerrainCellsByLayer,
    supportableTerrainRectsByCell: _supportableTerrainRectsByCell,
    supportRectsByLayer: Map.unmodifiable({
      for (final entry in rectangles.entries)
        entry.key: List<PixelRect>.unmodifiable(entry.value),
    }),
  );

  bool collidesPixelRect(
    PixelRect rect, {
    required bool Function(int cellIndex) isDynamicCellBlocked,
    BorderCollisionExclusion? borderExclusion,
    Set<String> ignoredSupportableTerrainLayerIds = const {},
  }) {
    if (borderExclusion != null) {
      _validateBorderExclusionArea(borderExclusion.area);
    }
    for (var localY = 0; localY < rect.heightPx; localY += 1) {
      final y = rect.topPx + localY;
      for (var localX = 0; localX < rect.widthPx; localX += 1) {
        final x = rect.leftPx + localX;
        if (_isPixelBlocked(
          x,
          y,
          isDynamicCellBlocked: isDynamicCellBlocked,
          borderExclusion: borderExclusion,
          ignoredSupportableTerrainLayerIds: ignoredSupportableTerrainLayerIds,
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
    BorderCollisionExclusion? borderExclusion,
    Set<String> ignoredSupportableTerrainLayerIds = const {},
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

    for (final layerId in _supportableTerrainLayerIds) {
      if (!ignoredSupportableTerrainLayerIds.contains(layerId) &&
          (_valueAt(supportableTerrainCellsByLayer[layerId] ?? const [], cellIndex) ||
              (_supportableTerrainRectsByCell[layerId]?[cellIndex]?.any(
                    (rect) => x >= rect.leftPx && x < rect.leftPx + rect.widthPx &&
                        y >= rect.topPx && y < rect.topPx + rect.heightPx,
                  ) ?? false)) &&
          !(supportRectsByLayer[layerId]?.any((rect) =>
              x >= rect.leftPx && x < rect.leftPx + rect.widthPx &&
              y >= rect.topPx && y < rect.topPx + rect.heightPx) ?? false)) {
        return true;
      }
    }

    final key = (
      x ~/ WorldCollisionStorageBuilder.chunkSize,
      y ~/ WorldCollisionStorageBuilder.chunkSize
    );
    final chunk = _pixelMaskWordsByChunk[key];
    final localX = x % WorldCollisionStorageBuilder.chunkSize;
    final localY = y % WorldCollisionStorageBuilder.chunkSize;
    final bit = 1 << localX;
    if (chunk != null && (chunk[localY] & bit) != 0) return true;
    final aggregate = _borderAggregateWordsByChunk[key];
    if (aggregate == null || (aggregate[localY] & bit) == 0) return false;
    final area = borderExclusion?.area;
    if (area == null ||
        x < area.leftPx ||
        y < area.topPx ||
        x >= area.leftPx + area.widthPx ||
        y >= area.topPx + area.heightPx) {
      return true;
    }
    for (final entry in _borderMaskWordsByChunk[key]!.entries) {
      if (borderExclusion!.owners.contains(entry.key)) continue;
      if ((entry.value[localY] & bit) != 0) return true;
    }
    return false;
  }

  void _validateBorderExclusionArea(PixelRect area) {
    final right = BigInt.from(area.leftPx) + BigInt.from(area.widthPx);
    final bottom = BigInt.from(area.topPx) + BigInt.from(area.heightPx);
    if (area.leftPx < 0 ||
        area.topPx < 0 ||
        area.widthPx <= 0 ||
        area.heightPx <= 0 ||
        right > BigInt.from(widthPx) ||
        bottom > BigInt.from(heightPx) ||
        area.leftPx ~/ tileWidthPx != (right.toInt() - 1) ~/ tileWidthPx ||
        area.topPx ~/ tileHeightPx != (bottom.toInt() - 1) ~/ tileHeightPx) {
      throw ArgumentError.value(
          area, 'borderExclusion.area', 'Must be contained in one map cell');
    }
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
    this.supportableTerrainCellsByLayer = const {},
    this.supportRectsByLayer = const {},
    this.supportableTerrainRectsByLayer = const {},
  })  : tileWidthPx = tileWidthPx <= 0 ? 16 : tileWidthPx,
        tileHeightPx = tileHeightPx <= 0 ? 16 : tileHeightPx;

  static const int chunkSize = 32;

  final int widthCells;
  final int heightCells;
  final int tileWidthPx;
  final int tileHeightPx;
  final List<bool> tileCollisionCells;
  final List<bool> placedElementCollisionCells;
  final Map<String, List<bool>> supportableTerrainCellsByLayer;
  final Map<String, List<PixelRect>> supportRectsByLayer;
  final Map<String, List<PixelRect>> supportableTerrainRectsByLayer;
  final Map<(int, int), Uint32List> _pixelMaskWordsByChunk =
      <(int, int), Uint32List>{};
  final Map<(int, int), Map<BorderCollisionOwner, Uint32List>>
      _borderMaskWordsByChunk = {};

  int get widthPx => widthCells * tileWidthPx;
  int get heightPx => heightCells * tileHeightPx;

  void stampRect(PixelRect rect) => _stampRect(rect);

  void stampBorderRect(MaterializedBorderCollisionRect contact) =>
      _stampRect(contact.rect, owner: contact.owner);

  void _stampRect(PixelRect rect, {BorderCollisionOwner? owner}) {
    if (rect.widthPx <= 0 || rect.heightPx <= 0) return;
    final left = rect.leftPx.clamp(0, widthPx);
    final top = rect.topPx.clamp(0, heightPx);
    final rightBig = BigInt.from(rect.leftPx) + BigInt.from(rect.widthPx);
    final bottomBig = BigInt.from(rect.topPx) + BigInt.from(rect.heightPx);
    final right = rightBig < BigInt.zero
        ? 0
        : rightBig > BigInt.from(widthPx)
            ? widthPx
            : rightBig.toInt();
    final bottom = bottomBig < BigInt.zero
        ? 0
        : bottomBig > BigInt.from(heightPx)
            ? heightPx
            : bottomBig.toInt();
    if (left >= right || top >= bottom) return;
    for (var x = left; x < right;) {
      final localX = x % chunkSize;
      final span = (right - x).clamp(0, chunkSize - localX);
      final bits = (0xffffffff >> (chunkSize - span)) << localX;
      for (var y = top; y < bottom; y++) {
        final key = (x ~/ chunkSize, y ~/ chunkSize);
        final words = owner == null
            ? _pixelMaskWordsByChunk.putIfAbsent(
                key, () => Uint32List(chunkSize))
            : _borderMaskWordsByChunk
                .putIfAbsent(key, () => {})
                .putIfAbsent(owner, () => Uint32List(chunkSize));
        words[y % chunkSize] |= bits;
      }
      x += span;
    }
  }

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
    final terrainRectCells = <String, Map<int, List<PixelRect>>>{};
    for (final entry in supportableTerrainRectsByLayer.entries) {
      final cells = <int, List<PixelRect>>{};
      for (final rect in entry.value) {
        if (rect.widthPx <= 0 || rect.heightPx <= 0) continue;
        final left = (rect.leftPx ~/ tileWidthPx).clamp(0, widthCells - 1);
        final right = ((rect.leftPx + rect.widthPx - 1) ~/ tileWidthPx)
            .clamp(0, widthCells - 1);
        final top = (rect.topPx ~/ tileHeightPx).clamp(0, heightCells - 1);
        final bottom = ((rect.topPx + rect.heightPx - 1) ~/ tileHeightPx)
            .clamp(0, heightCells - 1);
        for (var y = top; y <= bottom; y++) {
          for (var x = left; x <= right; x++) {
            cells.putIfAbsent(y * widthCells + x, () => []).add(rect);
          }
        }
      }
      terrainRectCells[entry.key] = Map.unmodifiable({
        for (final cell in cells.entries)
          cell.key: List<PixelRect>.unmodifiable(cell.value),
      });
    }
    final borderAggregate = <(int, int), Uint32List>{};
    for (final chunk in _borderMaskWordsByChunk.entries) {
      final union = Uint32List(chunkSize);
      for (final words in chunk.value.values) {
        for (var row = 0; row < chunkSize; row++) {
          union[row] |= words[row];
        }
      }
      borderAggregate[chunk.key] = union;
    }
    return WorldCollisionStorage._(
      widthCells: widthCells,
      heightCells: heightCells,
      tileWidthPx: tileWidthPx,
      tileHeightPx: tileHeightPx,
      tileCollisionCells: List<bool>.unmodifiable(tileCollisionCells),
      supportableTerrainCellsByLayer: Map.unmodifiable({
        for (final entry in supportableTerrainCellsByLayer.entries)
          entry.key: List<bool>.unmodifiable(entry.value),
      }),
      supportRectsByLayer: Map.unmodifiable({
        for (final entry in supportRectsByLayer.entries)
          entry.key: List<PixelRect>.unmodifiable(entry.value),
      }),
      supportableTerrainRectsByCell: Map.unmodifiable(terrainRectCells),
      placedElementCollisionCells:
          List<bool>.unmodifiable(placedElementCollisionCells),
      // Copy the mutable construction chunks so a discarded builder can never
      // mutate storage already shared by later immutable world states.
      borderAggregateWordsByChunk: Map.unmodifiable(borderAggregate),
      borderMaskWordsByChunk: Map.unmodifiable({
        for (final chunk in _borderMaskWordsByChunk.entries)
          chunk.key: Map<BorderCollisionOwner, Uint32List>.unmodifiable({
            for (final entry in chunk.value.entries)
              entry.key: Uint32List.fromList(entry.value)
          }),
      }),
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
