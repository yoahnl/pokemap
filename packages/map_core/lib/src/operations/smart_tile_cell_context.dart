import 'package:meta/meta.dart' show immutable;

import '../models/smart_tile.dart';

@immutable
final class SmartTileObservedSlot {
  const SmartTileObservedSlot.inside({this.materialId}) : isInsideMap = true;

  const SmartTileObservedSlot.outside()
      : isInsideMap = false,
        materialId = null;

  final bool isInsideMap;
  final String? materialId;
}

@immutable
final class SmartTileObservedSignature {
  const SmartTileObservedSignature({
    this.northEdge = const SmartTileObservedSlot.outside(),
    this.northEastCorner = const SmartTileObservedSlot.outside(),
    this.eastEdge = const SmartTileObservedSlot.outside(),
    this.southEastCorner = const SmartTileObservedSlot.outside(),
    this.southEdge = const SmartTileObservedSlot.outside(),
    this.southWestCorner = const SmartTileObservedSlot.outside(),
    this.westEdge = const SmartTileObservedSlot.outside(),
    this.northWestCorner = const SmartTileObservedSlot.outside(),
  });

  final SmartTileObservedSlot northEdge;
  final SmartTileObservedSlot northEastCorner;
  final SmartTileObservedSlot eastEdge;
  final SmartTileObservedSlot southEastCorner;
  final SmartTileObservedSlot southEdge;
  final SmartTileObservedSlot southWestCorner;
  final SmartTileObservedSlot westEdge;
  final SmartTileObservedSlot northWestCorner;

  List<SmartTileObservedSlot> activeSlots(SmartTileTopology topology) {
    return switch (topology) {
      SmartTileTopology.uniform => const <SmartTileObservedSlot>[],
      SmartTileTopology.cardinal4 ||
      SmartTileTopology.wangEdge4 =>
        <SmartTileObservedSlot>[
          northEdge,
          eastEdge,
          southEdge,
          westEdge,
        ],
      SmartTileTopology.blob8 ||
      SmartTileTopology.wang8 =>
        <SmartTileObservedSlot>[
          northEdge,
          northEastCorner,
          eastEdge,
          southEastCorner,
          southEdge,
          southWestCorner,
          westEdge,
          northWestCorner,
        ],
      SmartTileTopology.wangCorner4 => <SmartTileObservedSlot>[
          northEastCorner,
          southEastCorner,
          southWestCorner,
          northWestCorner,
        ],
    };
  }
}

@immutable
final class SmartTileCellContext {
  const SmartTileCellContext({
    this.centerMaterialId,
    this.observed = const SmartTileObservedSignature(),
  });

  factory SmartTileCellContext.fromCellGrid({
    required int width,
    required int height,
    required int x,
    required int y,
    required String? Function(int x, int y) materialAt,
  }) {
    if (x < 0 || y < 0 || x >= width || y >= height) {
      throw RangeError('Smart Tile cell ($x, $y) is outside $width x $height');
    }

    SmartTileObservedSlot sample(int sampleX, int sampleY) {
      if (sampleX < 0 || sampleY < 0 || sampleX >= width || sampleY >= height) {
        return const SmartTileObservedSlot.outside();
      }
      return SmartTileObservedSlot.inside(
        materialId: materialAt(sampleX, sampleY),
      );
    }

    return SmartTileCellContext(
      centerMaterialId: materialAt(x, y),
      observed: SmartTileObservedSignature(
        northEdge: sample(x, y - 1),
        northEastCorner: sample(x + 1, y - 1),
        eastEdge: sample(x + 1, y),
        southEastCorner: sample(x + 1, y + 1),
        southEdge: sample(x, y + 1),
        southWestCorner: sample(x - 1, y + 1),
        westEdge: sample(x - 1, y),
        northWestCorner: sample(x - 1, y - 1),
      ),
    );
  }

  final String? centerMaterialId;
  final SmartTileObservedSignature observed;
}
