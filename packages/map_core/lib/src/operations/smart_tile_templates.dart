import '../models/smart_tile.dart';
import 'smart_tile_cell_context.dart';

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
    SmartTileTemplateHint.simple => const <int>[0],
    SmartTileTemplateHint.edge16 =>
      List<int>.unmodifiable(<int>[for (var mask = 0; mask < 16; mask++) mask]),
    SmartTileTemplateHint.corner16 => List<int>.unmodifiable(
        <int>[for (var mask = 0; mask < 16; mask++) mask << 4],
      ),
    SmartTileTemplateHint.corner12 => const <int>[
        0x10,
        0x20,
        0x30,
        0x40,
        0x60,
        0x70,
        0x80,
        0x90,
        0xB0,
        0xC0,
        0xD0,
        0xE0,
      ],
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
    SmartTileTemplateHint.simple => SmartTileTopology.uniform,
    SmartTileTemplateHint.edge16 => SmartTileTopology.wangEdge4,
    SmartTileTemplateHint.corner16 ||
    SmartTileTemplateHint.corner12 =>
      SmartTileTopology.wangCorner4,
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
    SmartTileTopology.uniform => const SmartTileSignature(),
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

final class SmartTileTemplateCase {
  const SmartTileTemplateCase({
    required this.mask,
    required this.topology,
    required this.signature,
    required this.context,
  });

  final int mask;
  final SmartTileTopology topology;
  final SmartTileSignature signature;
  final SmartTileCellContext context;
}

/// Decodes one canonical template mask into its rule and observed context.
///
/// This is the sole mask-to-slot projection used by the test bench and future
/// coverage analysis. It derives observed slots from the canonical signature,
/// so bit positions are defined only by [smartTileSignatureForMask].
SmartTileTemplateCase smartTileTemplateCaseForMask({
  required int mask,
  required SmartTileTopology topology,
  required String materialId,
}) {
  final signature = smartTileSignatureForMask(mask, topology: topology);

  SmartTileObservedSlot observed(SmartTileSlotMatch match) {
    return switch (match.kind) {
      SmartTileMatchKind.same => SmartTileObservedSlot.inside(
          materialId: materialId,
        ),
      SmartTileMatchKind.different ||
      SmartTileMatchKind.any ||
      SmartTileMatchKind.empty =>
        const SmartTileObservedSlot.inside(),
      SmartTileMatchKind.material => SmartTileObservedSlot.inside(
          materialId: match.materialId,
        ),
    };
  }

  return SmartTileTemplateCase(
    mask: topology == SmartTileTopology.blob8
        ? normalizeSmartTileBlobMask(mask)
        : mask & smartTileEightNeighborMask,
    topology: topology,
    signature: signature,
    context: SmartTileCellContext(
      centerMaterialId: materialId,
      observed: SmartTileObservedSignature(
        northWestCorner: observed(signature.northWestCorner),
        northEdge: observed(signature.northEdge),
        northEastCorner: observed(signature.northEastCorner),
        eastEdge: observed(signature.eastEdge),
        southEastCorner: observed(signature.southEastCorner),
        southEdge: observed(signature.southEdge),
        southWestCorner: observed(signature.southWestCorner),
        westEdge: observed(signature.westEdge),
      ),
    ),
  );
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
    SmartTileTopology.uniform => _signatureUsesOnlyAny(signature) ? 0 : null,
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
  final canonicalMask = topology == SmartTileTopology.blob8
      ? normalizeSmartTileBlobMask(mask)
      : mask;
  return smartTileSignatureForMask(canonicalMask, topology: topology) ==
          signature
      ? canonicalMask
      : null;
}

bool _signatureUsesOnlyAny(SmartTileSignature signature) =>
    <SmartTileSlotMatch>[
      signature.northWestCorner,
      signature.northEdge,
      signature.northEastCorner,
      signature.eastEdge,
      signature.southEastCorner,
      signature.southEdge,
      signature.southWestCorner,
      signature.westEdge,
    ].every((match) => match.kind == SmartTileMatchKind.any);

/// Generates the canonical rule skeleton for a native template.
///
/// Simple presets deliberately get one center-material rule per allowed
/// material. Explicit empty materials are excluded unless the caller names
/// them in [explicitEmptyMaterialIds].
List<SmartTileRule> generateSmartTileTemplateRules({
  required ProjectSmartTilePreset preset,
  required Map<String, List<SmartTileCandidate>> candidatesByMaterialId,
  required Iterable<ProjectSmartTileMaterial> materials,
  Set<String> explicitEmptyMaterialIds = const <String>{},
}) {
  if (preset.templateHint == SmartTileTemplateHint.simple) {
    final materialById = <String, ProjectSmartTileMaterial>{
      for (final material in materials) material.id: material,
    };
    final ids = preset.allowedMaterialIds
        .map((id) => id.trim())
        .where((id) => id.isNotEmpty)
        .toSet()
        .where(
          (id) =>
              !(materialById[id]?.isEmpty ?? false) ||
              explicitEmptyMaterialIds.contains(id),
        )
        .toList(growable: false)
      ..sort();
    return List<SmartTileRule>.unmodifiable(<SmartTileRule>[
      for (final materialId in ids)
        SmartTileRule(
          id: 'material_$materialId',
          centerMatch: SmartTileSlotMatch.material(materialId),
          candidates: List<SmartTileCandidate>.unmodifiable(
            candidatesByMaterialId[materialId] ?? const <SmartTileCandidate>[],
          ),
        ),
    ]);
  }

  return List<SmartTileRule>.unmodifiable(<SmartTileRule>[
    for (final mask in smartTileCanonicalMasks(preset.templateHint))
      SmartTileRule(
        id: smartTileCanonicalRuleId(mask),
        centerMatch: const SmartTileSlotMatch.any(),
        signature: smartTileTemplateCaseForMask(
          mask: mask,
          topology: preset.topology,
          materialId: preset.defaultMaterialId,
        ).signature,
      ),
  ]);
}

String smartTileCanonicalRuleId(int mask) =>
    'mask_${(mask & smartTileEightNeighborMask).toRadixString(16).padLeft(2, '0')}';
