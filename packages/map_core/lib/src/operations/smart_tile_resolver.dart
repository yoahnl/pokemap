import 'dart:convert';

import 'package:meta/meta.dart' show immutable;

import '../models/smart_tile.dart';

@immutable
final class SmartTileCellSample {
  const SmartTileCellSample.inside({this.materialId}) : isInsideMap = true;

  const SmartTileCellSample.outside()
      : isInsideMap = false,
        materialId = null;

  final bool isInsideMap;
  final String? materialId;
}

@immutable
final class SmartTileNeighborhood {
  const SmartTileNeighborhood({
    required this.centerMaterialId,
    this.northWest = const SmartTileCellSample.outside(),
    this.north = const SmartTileCellSample.outside(),
    this.northEast = const SmartTileCellSample.outside(),
    this.east = const SmartTileCellSample.outside(),
    this.southEast = const SmartTileCellSample.outside(),
    this.south = const SmartTileCellSample.outside(),
    this.southWest = const SmartTileCellSample.outside(),
    this.west = const SmartTileCellSample.outside(),
  });

  factory SmartTileNeighborhood.fromGrid({
    required int width,
    required int height,
    required int x,
    required int y,
    required String? Function(int x, int y) materialAt,
  }) {
    if (width <= 0 || height <= 0) {
      throw ArgumentError('Smart Tile grid dimensions must be positive.');
    }
    if (x < 0 || y < 0 || x >= width || y >= height) {
      throw RangeError('Smart Tile center is outside the grid.');
    }

    SmartTileCellSample read(int sampleX, int sampleY) {
      if (sampleX < 0 || sampleY < 0 || sampleX >= width || sampleY >= height) {
        return const SmartTileCellSample.outside();
      }
      return SmartTileCellSample.inside(
        materialId: materialAt(sampleX, sampleY),
      );
    }

    return SmartTileNeighborhood(
      centerMaterialId: materialAt(x, y),
      northWest: read(x - 1, y - 1),
      north: read(x, y - 1),
      northEast: read(x + 1, y - 1),
      east: read(x + 1, y),
      southEast: read(x + 1, y + 1),
      south: read(x, y + 1),
      southWest: read(x - 1, y + 1),
      west: read(x - 1, y),
    );
  }

  final String? centerMaterialId;
  final SmartTileCellSample northWest;
  final SmartTileCellSample north;
  final SmartTileCellSample northEast;
  final SmartTileCellSample east;
  final SmartTileCellSample southEast;
  final SmartTileCellSample south;
  final SmartTileCellSample southWest;
  final SmartTileCellSample west;
}

enum SmartTileResolutionStatus {
  resolved,
  noCenterMaterial,
  noMatchingRule,
  noCandidate,
}

@immutable
final class SmartTileResolution {
  const SmartTileResolution({
    required this.status,
    this.ruleId,
    this.candidate,
    this.deterministicHash,
    this.message = '',
  });

  final SmartTileResolutionStatus status;
  final String? ruleId;
  final SmartTileCandidate? candidate;
  final int? deterministicHash;
  final String message;

  List<SmartTileVisualPart> get parts =>
      candidate?.parts ?? const <SmartTileVisualPart>[];
}

SmartTileResolution resolveSmartTile({
  required ProjectSmartTilePreset preset,
  required Iterable<ProjectSmartTileMaterial> materials,
  required SmartTileNeighborhood neighborhood,
  required int x,
  required int y,
  String mapId = '',
  String layerId = '',
  int projectSeed = 0,
  int layerSeed = 0,
}) {
  final centerMaterialId = neighborhood.centerMaterialId;
  if (centerMaterialId == null || centerMaterialId.isEmpty) {
    return const SmartTileResolution(
      status: SmartTileResolutionStatus.noCenterMaterial,
      message: 'The center cell has no Smart Tile material.',
    );
  }

  final materialMap = <String, ProjectSmartTileMaterial>{
    for (final material in materials) material.id: material,
  };
  SmartTileRule? selectedRule;
  var selectedSpecificity = -1;
  for (final rule in preset.rules) {
    final match = _ruleMatches(
      rule: rule,
      preset: preset,
      materials: materialMap,
      neighborhood: neighborhood,
    );
    if (match.matches && match.specificity > selectedSpecificity) {
      selectedRule = rule;
      selectedSpecificity = match.specificity;
    }
  }

  if (selectedRule == null) {
    return const SmartTileResolution(
      status: SmartTileResolutionStatus.noMatchingRule,
      message: 'No Smart Tile rule matches this neighborhood.',
    );
  }

  final candidates = selectedRule.candidates
      .where((candidate) => candidate.weight > 0)
      .toList(growable: false);
  candidates.sort(_compareCandidateIdsByUtf8);
  if (candidates.isEmpty) {
    return SmartTileResolution(
      status: SmartTileResolutionStatus.noCandidate,
      ruleId: selectedRule.id,
      message: 'The matching Smart Tile rule has no valid candidate.',
    );
  }

  final hash = _resolutionHash(
    projectSeed: projectSeed,
    layerSeed: layerSeed,
    mapId: mapId,
    layerId: layerId,
    presetId: preset.id,
    ruleId: selectedRule.id,
    presetSeedSalt: preset.seedSalt,
    x: x,
    y: y,
  );
  final totalWeight = candidates.fold<int>(
    0,
    (sum, candidate) => sum + candidate.weight,
  );
  var ticket = hash % totalWeight;
  SmartTileCandidate selectedCandidate = candidates.first;
  for (final candidate in candidates) {
    if (ticket < candidate.weight) {
      selectedCandidate = candidate;
      break;
    }
    ticket -= candidate.weight;
  }

  return SmartTileResolution(
    status: SmartTileResolutionStatus.resolved,
    ruleId: selectedRule.id,
    candidate: selectedCandidate,
    deterministicHash: hash,
  );
}

int smartTileConnectivityMask({
  required SmartTileTopology topology,
  required SmartTileBoundaryPolicy boundaryPolicy,
  required Iterable<ProjectSmartTileMaterial> materials,
  required SmartTileNeighborhood neighborhood,
}) {
  final center = neighborhood.centerMaterialId;
  if (center == null || center.isEmpty) {
    return 0;
  }
  final materialMap = <String, ProjectSmartTileMaterial>{
    for (final material in materials) material.id: material,
  };
  bool connected(SmartTileCellSample sample) {
    final neighbor = _effectiveMaterialId(
      sample: sample,
      policy: boundaryPolicy,
      centerMaterialId: center,
    );
    return _sameConnectionGroup(center, neighbor, materialMap);
  }

  final north = connected(neighborhood.north);
  final east = connected(neighborhood.east);
  final south = connected(neighborhood.south);
  final west = connected(neighborhood.west);
  final northWest = connected(neighborhood.northWest);
  final northEast = connected(neighborhood.northEast);
  final southEast = connected(neighborhood.southEast);
  final southWest = connected(neighborhood.southWest);

  var mask = 0;
  if (topology != SmartTileTopology.wangCorner4) {
    if (north) mask |= 0x01;
    if (east) mask |= 0x02;
    if (south) mask |= 0x04;
    if (west) mask |= 0x08;
  }
  if (topology == SmartTileTopology.blob8 ||
      topology == SmartTileTopology.wangCorner4 ||
      topology == SmartTileTopology.wang8) {
    final gateBlobCorners = topology == SmartTileTopology.blob8;
    if (northWest && (!gateBlobCorners || north && west)) mask |= 0x10;
    if (northEast && (!gateBlobCorners || north && east)) mask |= 0x20;
    if (southEast && (!gateBlobCorners || south && east)) mask |= 0x40;
    if (southWest && (!gateBlobCorners || south && west)) mask |= 0x80;
  }
  return mask;
}

int smartTileFnv1a64(Iterable<int> bytes) {
  const offsetBasis = 0xcbf29ce484222325;
  const prime = 0x100000001b3;
  const mask64 = 0xffffffffffffffff;
  var hash = offsetBasis;
  for (final byte in bytes) {
    hash ^= byte & 0xff;
    hash = (hash * prime) & mask64;
  }
  return hash;
}

final class _RuleMatch {
  const _RuleMatch(this.matches, this.specificity);

  final bool matches;
  final int specificity;
}

_RuleMatch _ruleMatches({
  required SmartTileRule rule,
  required ProjectSmartTilePreset preset,
  required Map<String, ProjectSmartTileMaterial> materials,
  required SmartTileNeighborhood neighborhood,
}) {
  final center = neighborhood.centerMaterialId!;
  final slots = _activeSlots(
    signature: rule.signature,
    topology: preset.topology,
    neighborhood: neighborhood,
    boundaryPolicy: preset.boundaryPolicy,
    centerMaterialId: center,
    materials: materials,
  );
  var specificity = 0;
  for (final slot in slots) {
    if (slot.match.kind != SmartTileMatchKind.any) {
      specificity += 1;
    }
    if (!_slotMatches(
      match: slot.match,
      neighborMaterialId: slot.materialId,
      centerMaterialId: center,
      materials: materials,
    )) {
      return _RuleMatch(false, specificity);
    }
  }
  return _RuleMatch(true, specificity);
}

final class _ResolvedSlot {
  const _ResolvedSlot(this.match, this.materialId);

  final SmartTileSlotMatch match;
  final String? materialId;
}

List<_ResolvedSlot> _activeSlots({
  required SmartTileSignature signature,
  required SmartTileTopology topology,
  required SmartTileNeighborhood neighborhood,
  required SmartTileBoundaryPolicy boundaryPolicy,
  required String centerMaterialId,
  required Map<String, ProjectSmartTileMaterial> materials,
}) {
  String? effective(SmartTileCellSample sample) => _effectiveMaterialId(
        sample: sample,
        policy: boundaryPolicy,
        centerMaterialId: centerMaterialId,
      );

  final north = effective(neighborhood.north);
  final east = effective(neighborhood.east);
  final south = effective(neighborhood.south);
  final west = effective(neighborhood.west);

  String? blobCorner(
    SmartTileCellSample sample,
    String? firstSide,
    String? secondSide,
  ) {
    if (topology == SmartTileTopology.blob8 &&
        (!_sameConnectionGroup(centerMaterialId, firstSide, materials) ||
            !_sameConnectionGroup(centerMaterialId, secondSide, materials))) {
      return null;
    }
    return effective(sample);
  }

  return switch (topology) {
    SmartTileTopology.cardinal4 ||
    SmartTileTopology.wangEdge4 =>
      <_ResolvedSlot>[
        _ResolvedSlot(signature.northEdge, north),
        _ResolvedSlot(signature.eastEdge, east),
        _ResolvedSlot(signature.southEdge, south),
        _ResolvedSlot(signature.westEdge, west),
      ],
    SmartTileTopology.wangCorner4 => <_ResolvedSlot>[
        _ResolvedSlot(
            signature.northWestCorner, effective(neighborhood.northWest)),
        _ResolvedSlot(
            signature.northEastCorner, effective(neighborhood.northEast)),
        _ResolvedSlot(
            signature.southEastCorner, effective(neighborhood.southEast)),
        _ResolvedSlot(
            signature.southWestCorner, effective(neighborhood.southWest)),
      ],
    SmartTileTopology.blob8 || SmartTileTopology.wang8 => <_ResolvedSlot>[
        _ResolvedSlot(
          signature.northWestCorner,
          blobCorner(neighborhood.northWest, north, west),
        ),
        _ResolvedSlot(signature.northEdge, north),
        _ResolvedSlot(
          signature.northEastCorner,
          blobCorner(neighborhood.northEast, north, east),
        ),
        _ResolvedSlot(signature.eastEdge, east),
        _ResolvedSlot(
          signature.southEastCorner,
          blobCorner(neighborhood.southEast, south, east),
        ),
        _ResolvedSlot(signature.southEdge, south),
        _ResolvedSlot(
          signature.southWestCorner,
          blobCorner(neighborhood.southWest, south, west),
        ),
        _ResolvedSlot(signature.westEdge, west),
      ],
  };
}

bool _slotMatches({
  required SmartTileSlotMatch match,
  required String? neighborMaterialId,
  required String centerMaterialId,
  required Map<String, ProjectSmartTileMaterial> materials,
}) {
  return switch (match.kind) {
    SmartTileMatchKind.any => true,
    SmartTileMatchKind.same => _sameConnectionGroup(
        centerMaterialId,
        neighborMaterialId,
        materials,
      ),
    SmartTileMatchKind.different => !_sameConnectionGroup(
        centerMaterialId,
        neighborMaterialId,
        materials,
      ),
    SmartTileMatchKind.empty => neighborMaterialId == null,
    SmartTileMatchKind.material => neighborMaterialId == match.materialId,
  };
}

String? _effectiveMaterialId({
  required SmartTileCellSample sample,
  required SmartTileBoundaryPolicy policy,
  required String centerMaterialId,
}) {
  if (sample.isInsideMap) {
    return sample.materialId;
  }
  return switch (policy) {
    SmartTileBoundaryPolicy.empty => null,
    SmartTileBoundaryPolicy.connected => centerMaterialId,
  };
}

bool _sameConnectionGroup(
  String centerMaterialId,
  String? neighborMaterialId,
  Map<String, ProjectSmartTileMaterial> materials,
) {
  if (neighborMaterialId == null || neighborMaterialId.isEmpty) {
    return false;
  }
  final centerGroup = materials[centerMaterialId]?.connectionGroupId;
  final neighborGroup = materials[neighborMaterialId]?.connectionGroupId;
  if (centerGroup == null || neighborGroup == null) {
    return centerMaterialId == neighborMaterialId;
  }
  return centerGroup == neighborGroup;
}

int _resolutionHash({
  required int projectSeed,
  required int layerSeed,
  required int x,
  required int y,
  required int presetSeedSalt,
  required String mapId,
  required String layerId,
  required String presetId,
  required String ruleId,
}) {
  final bytes = <int>[];

  void addInt64(int value) {
    const mask64 = 0xffffffffffffffff;
    final encoded = value & mask64;
    for (var shift = 0; shift < 64; shift += 8) {
      bytes.add((encoded >> shift) & 0xff);
    }
  }

  void addString(String value) {
    final encoded = utf8.encode(value);
    final length = encoded.length;
    for (var shift = 0; shift < 32; shift += 8) {
      bytes.add((length >> shift) & 0xff);
    }
    bytes.addAll(encoded);
  }

  void addInt32(int value) {
    final encoded = value & 0xffffffff;
    for (var shift = 0; shift < 32; shift += 8) {
      bytes.add((encoded >> shift) & 0xff);
    }
  }

  addInt64(projectSeed);
  addInt64(layerSeed);
  addInt32(x);
  addInt32(y);
  addInt64(presetSeedSalt);
  addString(mapId);
  addString(layerId);
  addString(presetId);
  addString(ruleId);
  return smartTileFnv1a64(bytes);
}

int _compareCandidateIdsByUtf8(
  SmartTileCandidate left,
  SmartTileCandidate right,
) {
  final leftBytes = utf8.encode(left.id);
  final rightBytes = utf8.encode(right.id);
  final sharedLength = leftBytes.length < rightBytes.length
      ? leftBytes.length
      : rightBytes.length;
  for (var index = 0; index < sharedLength; index += 1) {
    final comparison = leftBytes[index].compareTo(rightBytes[index]);
    if (comparison != 0) {
      return comparison;
    }
  }
  return leftBytes.length.compareTo(rightBytes.length);
}
