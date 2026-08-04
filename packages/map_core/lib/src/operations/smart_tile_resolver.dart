import 'dart:convert';

import 'package:meta/meta.dart' show immutable;

import '../models/smart_tile.dart';
import 'smart_tile_cell_context.dart';
import 'smart_tile_sprite_geometry.dart';

enum SmartTileResolutionStatus {
  resolved,
  noIntent,
  noMatchingRule,
  ambiguousRule,
  noCandidate,
  invalidRule,
}

@immutable
final class SmartTileResolution {
  const SmartTileResolution({
    required this.status,
    this.ruleId,
    this.candidate,
    this.deterministicHash,
    this.matchingRuleIds = const <String>[],
    this.usedFallback = false,
    this.transform = const SmartTileSpriteTransform(),
    this.message = '',
  });

  final SmartTileResolutionStatus status;
  final String? ruleId;
  final SmartTileCandidate? candidate;
  final int? deterministicHash;
  final List<String> matchingRuleIds;
  final bool usedFallback;
  final SmartTileSpriteTransform transform;
  final String message;

  List<SmartTileVisualPart> get parts =>
      candidate?.parts ?? const <SmartTileVisualPart>[];
}

SmartTileResolution resolveSmartTile({
  required ProjectSmartTilePreset preset,
  required Iterable<ProjectSmartTileMaterial> materials,
  required SmartTileCellContext context,
  required int x,
  required int y,
  String mapId = '',
  String layerId = '',
  int projectSeed = 0,
  int layerSeed = 0,
}) {
  final materialMap = <String, ProjectSmartTileMaterial>{
    for (final material in materials) material.id: material,
  };
  final invalidRule = _firstInvalidRule(preset);
  if (invalidRule != null) {
    return SmartTileResolution(
      status: SmartTileResolutionStatus.invalidRule,
      ruleId: invalidRule.ruleId,
      matchingRuleIds: List<String>.unmodifiable(<String>[
        invalidRule.ruleId,
      ]),
      message: invalidRule.message,
    );
  }
  if (!_hasIntent(
    preset: preset,
    context: context,
    materials: materialMap,
  )) {
    return const SmartTileResolution(
      status: SmartTileResolutionStatus.noIntent,
      message: 'The Smart Tile cell has no semantic or Wang intent.',
    );
  }

  final matches = <_MatchedRule>[];
  final allowedTransforms = smartTileAllowedTransforms(preset.transformPolicy);
  for (final rule in preset.rules) {
    if (rule.id == preset.fallbackRuleId) continue;
    final transformedMatches = <SmartTileSpriteTransform>[];
    var specificity = 0;
    for (final transform in allowedTransforms) {
      final match = _ruleMatches(
        rule: rule,
        signature: transformSmartTileSignature(rule.signature, transform),
        preset: preset,
        materials: materialMap,
        context: context,
      );
      if (match.matches) {
        transformedMatches.add(transform);
        specificity = match.specificity;
      }
    }
    if (transformedMatches.isNotEmpty) {
      matches.add(
        _MatchedRule(
          rule,
          specificity,
          List<SmartTileSpriteTransform>.unmodifiable(transformedMatches),
        ),
      );
    }
  }

  if (matches.isEmpty) {
    final fallbackRuleId = preset.fallbackRuleId;
    if (fallbackRuleId == null) {
      return const SmartTileResolution(
        status: SmartTileResolutionStatus.noMatchingRule,
        message: 'No primary Smart Tile rule matches this context.',
      );
    }
    SmartTileRule? fallback;
    for (final rule in preset.rules) {
      if (rule.id == fallbackRuleId) {
        fallback = rule;
        break;
      }
    }
    if (fallback == null) {
      return SmartTileResolution(
        status: SmartTileResolutionStatus.noMatchingRule,
        message: 'Smart Tile fallback rule "$fallbackRuleId" is missing.',
      );
    }
    return _resolveCandidate(
      preset: preset,
      rule: fallback,
      transforms: const <SmartTileSpriteTransform>[
        SmartTileSpriteTransform(),
      ],
      usedFallback: true,
      x: x,
      y: y,
      mapId: mapId,
      layerId: layerId,
      projectSeed: projectSeed,
      layerSeed: layerSeed,
    );
  }

  var maximumSpecificity = matches.first.specificity;
  for (final match in matches.skip(1)) {
    if (match.specificity > maximumSpecificity) {
      maximumSpecificity = match.specificity;
    }
  }
  final best = matches
      .where((match) => match.specificity == maximumSpecificity)
      .toList(growable: false);
  if (best.length > 1) {
    final matchingRuleIds = <String>[
      for (final match in best) match.rule.id,
    ]..sort(_compareStringsByUtf8);
    return SmartTileResolution(
      status: SmartTileResolutionStatus.ambiguousRule,
      matchingRuleIds: List<String>.unmodifiable(matchingRuleIds),
      message: 'Several Smart Tile rules have the same maximum specificity.',
    );
  }

  return _resolveCandidate(
    preset: preset,
    rule: best.single.rule,
    transforms: best.single.transforms,
    usedFallback: false,
    x: x,
    y: y,
    mapId: mapId,
    layerId: layerId,
    projectSeed: projectSeed,
    layerSeed: layerSeed,
  );
}

int smartTileConnectivityMask({
  required SmartTileTopology topology,
  required SmartTileBoundaryPolicy boundaryPolicy,
  required Iterable<ProjectSmartTileMaterial> materials,
  required SmartTileCellContext context,
}) {
  if (topology == SmartTileTopology.uniform) return 0;
  final materialMap = <String, ProjectSmartTileMaterial>{
    for (final material in materials) material.id: material,
  };
  final center = context.centerMaterialId;
  if (_isEmptyMaterial(center, materialMap)) return 0;

  bool connected(SmartTileObservedSlot slot) {
    final neighbor = _effectiveMaterialId(
      slot: slot,
      policy: boundaryPolicy,
      centerMaterialId: center,
    );
    return _sameConnectionGroup(center!, neighbor, materialMap);
  }

  final north = connected(context.observed.northEdge);
  final east = connected(context.observed.eastEdge);
  final south = connected(context.observed.southEdge);
  final west = connected(context.observed.westEdge);
  final northWest = connected(context.observed.northWestCorner);
  final northEast = connected(context.observed.northEastCorner);
  final southEast = connected(context.observed.southEastCorner);
  final southWest = connected(context.observed.southWestCorner);

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

SmartTileResolution _resolveCandidate({
  required ProjectSmartTilePreset preset,
  required SmartTileRule rule,
  required List<SmartTileSpriteTransform> transforms,
  required bool usedFallback,
  required int x,
  required int y,
  required String mapId,
  required String layerId,
  required int projectSeed,
  required int layerSeed,
}) {
  final hash = _resolutionHash(
    projectSeed: projectSeed,
    layerSeed: layerSeed,
    mapId: mapId,
    layerId: layerId,
    presetId: preset.id,
    ruleId: rule.id,
    presetSeedSalt: preset.seedSalt,
    x: x,
    y: y,
  );
  final transform = _selectTransform(
    transforms,
    hash: hash,
    preferUntransformed: preset.transformPolicy.preferUntransformed,
  );
  final candidates = rule.candidates
      .where((candidate) => candidate.weight > 0)
      .toList(growable: false)
    ..sort(_compareCandidateIdsByUtf8);
  final matchingRuleIds = List<String>.unmodifiable(<String>[rule.id]);
  if (candidates.isEmpty) {
    return SmartTileResolution(
      status: SmartTileResolutionStatus.noCandidate,
      ruleId: rule.id,
      matchingRuleIds: matchingRuleIds,
      usedFallback: usedFallback,
      transform: transform,
      message: 'The selected Smart Tile rule has no positive candidate.',
    );
  }

  final totalWeight = candidates.fold<int>(
    0,
    (sum, candidate) => sum + candidate.weight,
  );
  var ticket = hash % totalWeight;
  var selectedCandidate = candidates.first;
  for (final candidate in candidates) {
    if (ticket < candidate.weight) {
      selectedCandidate = candidate;
      break;
    }
    ticket -= candidate.weight;
  }

  return SmartTileResolution(
    status: SmartTileResolutionStatus.resolved,
    ruleId: rule.id,
    candidate: selectedCandidate,
    deterministicHash: hash,
    matchingRuleIds: matchingRuleIds,
    usedFallback: usedFallback,
    transform: transform,
  );
}

SmartTileSpriteTransform _selectTransform(
  List<SmartTileSpriteTransform> transforms, {
  required int hash,
  required bool preferUntransformed,
}) {
  if (transforms.isEmpty) return const SmartTileSpriteTransform();
  if (preferUntransformed) {
    for (final transform in transforms) {
      if (isIdentitySmartTileTransform(transform)) return transform;
    }
  }
  return transforms[hash % transforms.length];
}

final class _InvalidRule {
  const _InvalidRule(this.ruleId, this.message);

  final String ruleId;
  final String message;
}

_InvalidRule? _firstInvalidRule(ProjectSmartTilePreset preset) {
  for (final rule in preset.rules) {
    if (rule.centerMatch.kind == SmartTileMatchKind.same ||
        rule.centerMatch.kind == SmartTileMatchKind.different) {
      return _InvalidRule(
        rule.id,
        'Rule "${rule.id}" has an invalid relative center match.',
      );
    }
    for (final slot in _allSignatureSlots(rule.signature)) {
      if (!_slotIsActive(preset.topology, slot.name) &&
          slot.match.kind != SmartTileMatchKind.any) {
        return _InvalidRule(
          rule.id,
          'Rule "${rule.id}" constrains inactive slot ${slot.name}.',
        );
      }
    }
    if (rule.candidates.any((candidate) => candidate.weight < 0)) {
      return _InvalidRule(
        rule.id,
        'Rule "${rule.id}" has a negative candidate weight.',
      );
    }
  }
  return null;
}

bool _hasIntent({
  required ProjectSmartTilePreset preset,
  required SmartTileCellContext context,
  required Map<String, ProjectSmartTileMaterial> materials,
}) {
  final centerMaterialId = context.centerMaterialId;
  if (!_isEmptyMaterial(centerMaterialId, materials)) return true;
  if (_hasExplicitCenterMaterialIntent(preset, centerMaterialId)) return true;
  if (preset.topology != SmartTileTopology.wangEdge4 &&
      preset.topology != SmartTileTopology.wangCorner4 &&
      preset.topology != SmartTileTopology.wang8) {
    return false;
  }
  return _allObservedSlots(context.observed).any(
    (slot) =>
        _slotIsActive(preset.topology, slot.name) &&
        (!_isEmptyMaterial(slot.value.materialId, materials) ||
            _hasExplicitSignatureMaterialIntent(
              preset,
              slot.name,
              slot.value.materialId,
            )),
  );
}

bool _hasExplicitCenterMaterialIntent(
  ProjectSmartTilePreset preset,
  String? materialId,
) {
  if (materialId == null || materialId.isEmpty) return false;
  return preset.rules.any(
    (rule) =>
        rule.id != preset.fallbackRuleId &&
        rule.centerMatch.kind == SmartTileMatchKind.material &&
        rule.centerMatch.materialId == materialId,
  );
}

bool _hasExplicitSignatureMaterialIntent(
  ProjectSmartTilePreset preset,
  String slotName,
  String? materialId,
) {
  if (materialId == null || materialId.isEmpty) return false;
  return preset.rules.any((rule) {
    if (rule.id == preset.fallbackRuleId) return false;
    for (final transform in smartTileAllowedTransforms(
      preset.transformPolicy,
    )) {
      final signature = transformSmartTileSignature(
        rule.signature,
        transform,
      );
      final match = switch (slotName) {
        'northWestCorner' => signature.northWestCorner,
        'northEdge' => signature.northEdge,
        'northEastCorner' => signature.northEastCorner,
        'eastEdge' => signature.eastEdge,
        'southEastCorner' => signature.southEastCorner,
        'southEdge' => signature.southEdge,
        'southWestCorner' => signature.southWestCorner,
        'westEdge' => signature.westEdge,
        _ => const SmartTileSlotMatch.any(),
      };
      if (match.kind == SmartTileMatchKind.material &&
          match.materialId == materialId) {
        return true;
      }
    }
    return false;
  });
}

final class _RuleMatch {
  const _RuleMatch(this.matches, this.specificity);

  final bool matches;
  final int specificity;
}

final class _MatchedRule {
  const _MatchedRule(this.rule, this.specificity, this.transforms);

  final SmartTileRule rule;
  final int specificity;
  final List<SmartTileSpriteTransform> transforms;
}

_RuleMatch _ruleMatches({
  required SmartTileRule rule,
  required SmartTileSignature signature,
  required ProjectSmartTilePreset preset,
  required Map<String, ProjectSmartTileMaterial> materials,
  required SmartTileCellContext context,
}) {
  final center = context.centerMaterialId;
  if (!_centerMatches(
    match: rule.centerMatch,
    centerMaterialId: center,
    materials: materials,
  )) {
    return const _RuleMatch(false, 0);
  }

  var specificity = rule.centerMatch.kind == SmartTileMatchKind.any ? 0 : 1;
  for (final slot in _resolvedActiveSlots(
    signature: signature,
    topology: preset.topology,
    observed: context.observed,
    boundaryPolicy: preset.boundaryPolicy,
    centerMaterialId: center,
    materials: materials,
  )) {
    if (slot.match.kind != SmartTileMatchKind.any) specificity += 1;
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

bool _centerMatches({
  required SmartTileSlotMatch match,
  required String? centerMaterialId,
  required Map<String, ProjectSmartTileMaterial> materials,
}) {
  return switch (match.kind) {
    SmartTileMatchKind.any => true,
    SmartTileMatchKind.empty => _isEmptyMaterial(centerMaterialId, materials),
    SmartTileMatchKind.material => centerMaterialId == match.materialId,
    SmartTileMatchKind.same || SmartTileMatchKind.different => false,
  };
}

final class _SignatureSlot {
  const _SignatureSlot(this.name, this.match);

  final String name;
  final SmartTileSlotMatch match;
}

final class _ObservedSlot {
  const _ObservedSlot(this.name, this.value);

  final String name;
  final SmartTileObservedSlot value;
}

List<_ObservedSlot> _allObservedSlots(SmartTileObservedSignature observed) =>
    <_ObservedSlot>[
      _ObservedSlot('northEdge', observed.northEdge),
      _ObservedSlot('northEastCorner', observed.northEastCorner),
      _ObservedSlot('eastEdge', observed.eastEdge),
      _ObservedSlot('southEastCorner', observed.southEastCorner),
      _ObservedSlot('southEdge', observed.southEdge),
      _ObservedSlot('southWestCorner', observed.southWestCorner),
      _ObservedSlot('westEdge', observed.westEdge),
      _ObservedSlot('northWestCorner', observed.northWestCorner),
    ];

List<_SignatureSlot> _allSignatureSlots(SmartTileSignature signature) =>
    <_SignatureSlot>[
      _SignatureSlot('northEdge', signature.northEdge),
      _SignatureSlot('northEastCorner', signature.northEastCorner),
      _SignatureSlot('eastEdge', signature.eastEdge),
      _SignatureSlot('southEastCorner', signature.southEastCorner),
      _SignatureSlot('southEdge', signature.southEdge),
      _SignatureSlot('southWestCorner', signature.southWestCorner),
      _SignatureSlot('westEdge', signature.westEdge),
      _SignatureSlot('northWestCorner', signature.northWestCorner),
    ];

final class _ResolvedSlot {
  const _ResolvedSlot(this.match, this.materialId);

  final SmartTileSlotMatch match;
  final String? materialId;
}

List<_ResolvedSlot> _resolvedActiveSlots({
  required SmartTileSignature signature,
  required SmartTileTopology topology,
  required SmartTileObservedSignature observed,
  required SmartTileBoundaryPolicy boundaryPolicy,
  required String? centerMaterialId,
  required Map<String, ProjectSmartTileMaterial> materials,
}) {
  String? effective(SmartTileObservedSlot slot) => _effectiveMaterialId(
        slot: slot,
        policy: boundaryPolicy,
        centerMaterialId: centerMaterialId,
      );

  final north = effective(observed.northEdge);
  final east = effective(observed.eastEdge);
  final south = effective(observed.southEdge);
  final west = effective(observed.westEdge);

  String? blobCorner(
    SmartTileObservedSlot slot,
    String? firstSide,
    String? secondSide,
  ) {
    if (topology == SmartTileTopology.blob8 &&
        (centerMaterialId == null ||
            !_sameConnectionGroup(
              centerMaterialId,
              firstSide,
              materials,
            ) ||
            !_sameConnectionGroup(
              centerMaterialId,
              secondSide,
              materials,
            ))) {
      return null;
    }
    return effective(slot);
  }

  return switch (topology) {
    SmartTileTopology.uniform => const <_ResolvedSlot>[],
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
          signature.northEastCorner,
          effective(observed.northEastCorner),
        ),
        _ResolvedSlot(
          signature.southEastCorner,
          effective(observed.southEastCorner),
        ),
        _ResolvedSlot(
          signature.southWestCorner,
          effective(observed.southWestCorner),
        ),
        _ResolvedSlot(
          signature.northWestCorner,
          effective(observed.northWestCorner),
        ),
      ],
    SmartTileTopology.blob8 || SmartTileTopology.wang8 => <_ResolvedSlot>[
        _ResolvedSlot(signature.northEdge, north),
        _ResolvedSlot(
          signature.northEastCorner,
          blobCorner(observed.northEastCorner, north, east),
        ),
        _ResolvedSlot(signature.eastEdge, east),
        _ResolvedSlot(
          signature.southEastCorner,
          blobCorner(observed.southEastCorner, south, east),
        ),
        _ResolvedSlot(signature.southEdge, south),
        _ResolvedSlot(
          signature.southWestCorner,
          blobCorner(observed.southWestCorner, south, west),
        ),
        _ResolvedSlot(signature.westEdge, west),
        _ResolvedSlot(
          signature.northWestCorner,
          blobCorner(observed.northWestCorner, north, west),
        ),
      ],
  };
}

bool _slotMatches({
  required SmartTileSlotMatch match,
  required String? neighborMaterialId,
  required String? centerMaterialId,
  required Map<String, ProjectSmartTileMaterial> materials,
}) {
  final centerHasMaterial = !_isEmptyMaterial(centerMaterialId, materials);
  return switch (match.kind) {
    SmartTileMatchKind.any => true,
    SmartTileMatchKind.same => centerHasMaterial
        ? _sameConnectionGroup(
            centerMaterialId!,
            neighborMaterialId,
            materials,
          )
        : _isEmptyMaterial(neighborMaterialId, materials),
    SmartTileMatchKind.different => centerHasMaterial
        ? !_sameConnectionGroup(
            centerMaterialId!,
            neighborMaterialId,
            materials,
          )
        : !_isEmptyMaterial(neighborMaterialId, materials),
    SmartTileMatchKind.empty => _isEmptyMaterial(neighborMaterialId, materials),
    SmartTileMatchKind.material => neighborMaterialId == match.materialId,
  };
}

String? _effectiveMaterialId({
  required SmartTileObservedSlot slot,
  required SmartTileBoundaryPolicy policy,
  required String? centerMaterialId,
}) {
  if (slot.isInsideMap) return slot.materialId;
  return switch (policy) {
    SmartTileBoundaryPolicy.empty => null,
    SmartTileBoundaryPolicy.connected => centerMaterialId,
  };
}

bool _isEmptyMaterial(
  String? materialId,
  Map<String, ProjectSmartTileMaterial> materials,
) {
  return materialId == null ||
      materialId.isEmpty ||
      (materials[materialId]?.isEmpty ?? false);
}

bool _sameConnectionGroup(
  String centerMaterialId,
  String? neighborMaterialId,
  Map<String, ProjectSmartTileMaterial> materials,
) {
  if (_isEmptyMaterial(centerMaterialId, materials) ||
      _isEmptyMaterial(neighborMaterialId, materials)) {
    return false;
  }
  final centerGroup = materials[centerMaterialId]?.connectionGroupId;
  final neighborGroup = materials[neighborMaterialId]?.connectionGroupId;
  if (centerGroup == null || neighborGroup == null) {
    return centerMaterialId == neighborMaterialId;
  }
  return centerGroup == neighborGroup;
}

bool _slotIsActive(SmartTileTopology topology, String slotName) {
  final isCorner = slotName.endsWith('Corner');
  return switch (topology) {
    SmartTileTopology.uniform => false,
    SmartTileTopology.cardinal4 || SmartTileTopology.wangEdge4 => !isCorner,
    SmartTileTopology.wangCorner4 => isCorner,
    SmartTileTopology.blob8 || SmartTileTopology.wang8 => true,
  };
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
) =>
    _compareStringsByUtf8(left.id, right.id);

int _compareStringsByUtf8(String left, String right) {
  final leftBytes = utf8.encode(left);
  final rightBytes = utf8.encode(right);
  final sharedLength = leftBytes.length < rightBytes.length
      ? leftBytes.length
      : rightBytes.length;
  for (var index = 0; index < sharedLength; index += 1) {
    final comparison = leftBytes[index].compareTo(rightBytes[index]);
    if (comparison != 0) return comparison;
  }
  return leftBytes.length.compareTo(rightBytes.length);
}
