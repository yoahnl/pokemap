import '../models/smart_tile.dart';

const int smartTileNorthBit = 0x01;
const int smartTileEastBit = 0x02;
const int smartTileSouthBit = 0x04;
const int smartTileWestBit = 0x08;
const int smartTileNorthWestBit = 0x10;
const int smartTileNorthEastBit = 0x20;
const int smartTileSouthEastBit = 0x40;
const int smartTileSouthWestBit = 0x80;

const int smartTileCardinalMask = 0x0f;
const int smartTileCornerMask = 0xf0;
const int smartTileEightNeighborMask = 0xff;

/// Returns the native canonical connectivity masks for a known template.
///
/// Legacy 20 is deliberately excluded: it remains on its historical resolver
/// until an explicit conversion proves how each source cell maps to a native
/// signature. Free mappings are authored directly and have no generated set.
List<int> smartTileCanonicalMasks(SmartTileTemplateHint template) {
  return switch (template) {
    SmartTileTemplateHint.edge16 =>
      List<int>.unmodifiable(<int>[for (var mask = 0; mask < 16; mask++) mask]),
    SmartTileTemplateHint.corner16 => List<int>.unmodifiable(
        <int>[for (var mask = 0; mask < 16; mask++) mask << 4],
      ),
    SmartTileTemplateHint.blob47 => List<int>.unmodifiable(
        (<int>{
          for (var mask = 0; mask < 256; mask++)
            normalizeSmartTileBlobMask(mask),
        }.toList()
          ..sort()),
      ),
    SmartTileTemplateHint.mixed256 => List<int>.unmodifiable(
        <int>[for (var mask = 0; mask < 256; mask++) mask],
      ),
    SmartTileTemplateHint.legacy20 ||
    SmartTileTemplateHint.free =>
      const <int>[],
  };
}

/// Applies the conventional Blob 47 diagonal gate.
///
/// A diagonal is meaningful only when both adjacent cardinal neighbors are
/// connected. Applying this function to all 256 eight-neighbor masks yields
/// exactly the 47 canonical Blob signatures.
int normalizeSmartTileBlobMask(int mask) {
  final value = mask & smartTileEightNeighborMask;
  final north = value & smartTileNorthBit != 0;
  final east = value & smartTileEastBit != 0;
  final south = value & smartTileSouthBit != 0;
  final west = value & smartTileWestBit != 0;
  var normalized = value & smartTileCardinalMask;
  if (north && west && value & smartTileNorthWestBit != 0) {
    normalized |= smartTileNorthWestBit;
  }
  if (north && east && value & smartTileNorthEastBit != 0) {
    normalized |= smartTileNorthEastBit;
  }
  if (south && east && value & smartTileSouthEastBit != 0) {
    normalized |= smartTileSouthEastBit;
  }
  if (south && west && value & smartTileSouthWestBit != 0) {
    normalized |= smartTileSouthWestBit;
  }
  return normalized;
}

SmartTileTopology smartTileTopologyForTemplate(
  SmartTileTemplateHint template,
) {
  return switch (template) {
    SmartTileTemplateHint.edge16 => SmartTileTopology.wangEdge4,
    SmartTileTemplateHint.corner16 => SmartTileTopology.wangCorner4,
    SmartTileTemplateHint.blob47 => SmartTileTopology.blob8,
    SmartTileTemplateHint.mixed256 => SmartTileTopology.wang8,
    SmartTileTemplateHint.legacy20 => SmartTileTopology.cardinal4,
    SmartTileTemplateHint.free => SmartTileTopology.wang8,
  };
}

/// Builds the exact same/different rule signature represented by [mask].
SmartTileSignature smartTileSignatureForMask(
  int mask, {
  required SmartTileTopology topology,
}) {
  final normalized = switch (topology) {
    SmartTileTopology.blob8 => normalizeSmartTileBlobMask(mask),
    _ => mask & smartTileEightNeighborMask,
  };
  SmartTileSlotMatch edge(int bit) => normalized & bit != 0
      ? const SmartTileSlotMatch.same()
      : const SmartTileSlotMatch.different();

  return switch (topology) {
    SmartTileTopology.cardinal4 ||
    SmartTileTopology.wangEdge4 =>
      SmartTileSignature(
        northEdge: edge(smartTileNorthBit),
        eastEdge: edge(smartTileEastBit),
        southEdge: edge(smartTileSouthBit),
        westEdge: edge(smartTileWestBit),
      ),
    SmartTileTopology.wangCorner4 => SmartTileSignature(
        northWestCorner: edge(smartTileNorthWestBit),
        northEastCorner: edge(smartTileNorthEastBit),
        southEastCorner: edge(smartTileSouthEastBit),
        southWestCorner: edge(smartTileSouthWestBit),
      ),
    SmartTileTopology.blob8 || SmartTileTopology.wang8 => SmartTileSignature(
        northWestCorner: edge(smartTileNorthWestBit),
        northEdge: edge(smartTileNorthBit),
        northEastCorner: edge(smartTileNorthEastBit),
        eastEdge: edge(smartTileEastBit),
        southEastCorner: edge(smartTileSouthEastBit),
        southEdge: edge(smartTileSouthBit),
        southWestCorner: edge(smartTileSouthWestBit),
        westEdge: edge(smartTileWestBit),
      ),
  };
}

/// Returns the canonical connectivity mask encoded by [signature].
///
/// `null` means that the signature uses `any`, `empty`, or explicit material
/// constraints and therefore cannot be represented by a binary template mask.
int? smartTileMaskForSignature(
  SmartTileSignature signature, {
  required SmartTileTopology topology,
}) {
  int? bit(SmartTileSlotMatch match, int value) {
    return switch (match.kind) {
      SmartTileMatchKind.same => value,
      SmartTileMatchKind.different => 0,
      SmartTileMatchKind.any ||
      SmartTileMatchKind.empty ||
      SmartTileMatchKind.material =>
        null,
    };
  }

  int? combine(List<(SmartTileSlotMatch, int)> slots) {
    var result = 0;
    for (final slot in slots) {
      final value = bit(slot.$1, slot.$2);
      if (value == null) {
        return null;
      }
      result |= value;
    }
    return result;
  }

  final mask = switch (topology) {
    SmartTileTopology.cardinal4 || SmartTileTopology.wangEdge4 => combine(
        <(SmartTileSlotMatch, int)>[
          (signature.northEdge, smartTileNorthBit),
          (signature.eastEdge, smartTileEastBit),
          (signature.southEdge, smartTileSouthBit),
          (signature.westEdge, smartTileWestBit),
        ],
      ),
    SmartTileTopology.wangCorner4 => combine(
        <(SmartTileSlotMatch, int)>[
          (signature.northWestCorner, smartTileNorthWestBit),
          (signature.northEastCorner, smartTileNorthEastBit),
          (signature.southEastCorner, smartTileSouthEastBit),
          (signature.southWestCorner, smartTileSouthWestBit),
        ],
      ),
    SmartTileTopology.blob8 || SmartTileTopology.wang8 => combine(
        <(SmartTileSlotMatch, int)>[
          (signature.northWestCorner, smartTileNorthWestBit),
          (signature.northEdge, smartTileNorthBit),
          (signature.northEastCorner, smartTileNorthEastBit),
          (signature.eastEdge, smartTileEastBit),
          (signature.southEastCorner, smartTileSouthEastBit),
          (signature.southEdge, smartTileSouthBit),
          (signature.southWestCorner, smartTileSouthWestBit),
          (signature.westEdge, smartTileWestBit),
        ],
      ),
  };
  if (mask == null) {
    return null;
  }
  return topology == SmartTileTopology.blob8
      ? normalizeSmartTileBlobMask(mask)
      : mask;
}

String smartTileCanonicalRuleId(int mask) =>
    'mask_${(mask & smartTileEightNeighborMask).toRadixString(16).padLeft(2, '0')}';
