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
  Map<String, int> candidateWeights = const <String, int>{},
}) =>
    PreparedSmartTileResolver(
      preset: preset,
      materials: materials,
      mapId: mapId,
      layerId: layerId,
      projectSeed: projectSeed,
      layerSeed: layerSeed,
      candidateWeights: candidateWeights,
    ).resolve(context: context, x: x, y: y);

/// Reusable, immutable resolver that prepares all preset-stable work once.
///
/// Create one instance per rendered layer (or other batch) and call [resolve]
/// for every cell. [resolveSmartTile] remains the compatibility entry point
/// for isolated resolutions.
@immutable
final class PreparedSmartTileResolver {
  factory PreparedSmartTileResolver({
    required ProjectSmartTilePreset preset,
    required Iterable<ProjectSmartTileMaterial> materials,
    String mapId = '',
    String layerId = '',
    int projectSeed = 0,
    int layerSeed = 0,
    Map<String, int> candidateWeights = const <String, int>{},
  }) {
    final materialMap = Map<String, ProjectSmartTileMaterial>.unmodifiable(
      <String, ProjectSmartTileMaterial>{
        for (final material in materials) material.id: material,
      },
    );
    final allowedTransforms = smartTileAllowedTransforms(
      preset.transformPolicy,
    );
    final hashPrefix = _resolutionHashPrefix(
      projectSeed: projectSeed,
      layerSeed: layerSeed,
    );

    _PreparedSmartTileRule prepare(SmartTileRule rule) {
      // La surcharge par calque s'applique ici, avant le filtre des poids
      // positifs et la somme : la boucle de résolution ne la voit jamais.
      // Une clé qui ne correspond à aucun candidat est ignorée — les
      // surcharges orphelines d'un preset réimporté ne cassent pas la carte.
      final effective = candidateWeights.isEmpty
          ? rule
          : rule.copyWith(
              candidates: <SmartTileCandidate>[
                for (final candidate in rule.candidates)
                  candidateWeights.containsKey(candidate.id)
                      ? candidate.copyWith(
                          weight: candidateWeights[candidate.id]!,
                        )
                      : candidate,
              ],
            );
      return _PreparedSmartTileRule(
        rule: effective,
        signatures: List<_PreparedSmartTileSignature>.unmodifiable(
          <_PreparedSmartTileSignature>[
            for (final transform in allowedTransforms)
              _PreparedSmartTileSignature(
                transform: transform,
                centerMatch: effective.centerMatch,
                constraints: _prepareSlotConstraints(
                  transformSmartTileSignature(
                    effective.signature,
                    transform,
                  ),
                  preset.topology,
                ),
              ),
          ],
        ),
        hashSuffix: List<int>.unmodifiable(
          _resolutionHashSuffix(
            presetSeedSalt: preset.seedSalt,
            mapId: mapId,
            layerId: layerId,
            presetId: preset.id,
            ruleId: effective.id,
          ),
        ),
      );
    }

    final primaryRules = <_PreparedSmartTileRule>[];
    _PreparedSmartTileRule? fallbackRule;
    for (final rule in preset.rules) {
      if (rule.id == preset.fallbackRuleId) {
        fallbackRule ??= prepare(rule);
      } else {
        primaryRules.add(prepare(rule));
      }
    }
    final explicitCenterMaterialIds = <String>{};
    final explicitSignatureMaterialIds = <Set<String>>[
      for (var index = 0; index < 8; index += 1) <String>{},
    ];
    for (final rule in primaryRules) {
      final centerMatch = rule.rule.centerMatch;
      if (centerMatch.kind == SmartTileMatchKind.material &&
          centerMatch.materialId != null) {
        explicitCenterMaterialIds.add(centerMatch.materialId!);
      }
      for (final signature in rule.signatures) {
        for (final constraint in signature.constraints) {
          if (constraint.match.kind == SmartTileMatchKind.material &&
              constraint.match.materialId != null) {
            explicitSignatureMaterialIds[constraint.slotIndex]
                .add(constraint.match.materialId!);
          }
        }
      }
    }
    return PreparedSmartTileResolver._(
      preset: preset,
      materials: materialMap,
      invalidRule: _firstInvalidRule(preset),
      primaryRules: List<_PreparedSmartTileRule>.unmodifiable(primaryRules),
      fallbackRule: fallbackRule,
      hashPrefix: hashPrefix,
      explicitCenterMaterialIds:
          Set<String>.unmodifiable(explicitCenterMaterialIds),
      explicitSignatureMaterialIds: List<Set<String>>.unmodifiable(
        <Set<String>>[
          for (final ids in explicitSignatureMaterialIds)
            Set<String>.unmodifiable(ids),
        ],
      ),
    );
  }

  const PreparedSmartTileResolver._({
    required this.preset,
    required Map<String, ProjectSmartTileMaterial> materials,
    required _InvalidRule? invalidRule,
    required List<_PreparedSmartTileRule> primaryRules,
    required _PreparedSmartTileRule? fallbackRule,
    required int hashPrefix,
    required Set<String> explicitCenterMaterialIds,
    required List<Set<String>> explicitSignatureMaterialIds,
  })  : _materials = materials,
        _invalidRule = invalidRule,
        _primaryRules = primaryRules,
        _fallbackRule = fallbackRule,
        _hashPrefix = hashPrefix,
        _explicitCenterMaterialIds = explicitCenterMaterialIds,
        _explicitSignatureMaterialIds = explicitSignatureMaterialIds;

  final ProjectSmartTilePreset preset;
  final Map<String, ProjectSmartTileMaterial> _materials;
  final _InvalidRule? _invalidRule;
  final List<_PreparedSmartTileRule> _primaryRules;
  final _PreparedSmartTileRule? _fallbackRule;
  final int _hashPrefix;
  final Set<String> _explicitCenterMaterialIds;
  final List<Set<String>> _explicitSignatureMaterialIds;

  SmartTileResolution resolve({
    required SmartTileCellContext context,
    required int x,
    required int y,
  }) {
    final invalidRule = _invalidRule;
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
    if (!_hasPreparedIntent(context)) {
      return const SmartTileResolution(
        status: SmartTileResolutionStatus.noIntent,
        message: 'The Smart Tile cell has no semantic or Wang intent.',
      );
    }
    final preparedContext = _PreparedSmartTileCellContext(
      preset: preset,
      materials: _materials,
      context: context,
    );

    final matches = <_PreparedMatchedRule>[];
    for (final preparedRule in _primaryRules) {
      List<SmartTileSpriteTransform>? transformedMatches;
      var specificity = 0;
      for (final preparedSignature in preparedRule.signatures) {
        if (preparedSignature.matches(
          context: preparedContext,
          materials: _materials,
        )) {
          (transformedMatches ??= <SmartTileSpriteTransform>[])
              .add(preparedSignature.transform);
          specificity = preparedSignature.specificity;
        }
      }
      if (transformedMatches != null) {
        matches.add(
          _PreparedMatchedRule(
            preparedRule,
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
      final fallbackRule = _fallbackRule;
      if (fallbackRule == null) {
        return SmartTileResolution(
          status: SmartTileResolutionStatus.noMatchingRule,
          message: 'Smart Tile fallback rule "$fallbackRuleId" is missing.',
        );
      }
      return _resolvePreparedCandidate(
        preset: preset,
        rule: fallbackRule,
        transforms: const <SmartTileSpriteTransform>[
          SmartTileSpriteTransform(),
        ],
        usedFallback: true,
        hashPrefix: _hashPrefix,
        x: x,
        y: y,
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
        for (final match in best) match.rule.rule.id,
      ]..sort(_compareStringsByUtf8);
      return SmartTileResolution(
        status: SmartTileResolutionStatus.ambiguousRule,
        matchingRuleIds: List<String>.unmodifiable(matchingRuleIds),
        message: 'Several Smart Tile rules have the same maximum specificity.',
      );
    }

    return _resolvePreparedCandidate(
      preset: preset,
      rule: best.single.rule,
      transforms: best.single.transforms,
      usedFallback: false,
      hashPrefix: _hashPrefix,
      x: x,
      y: y,
    );
  }

  bool _hasPreparedIntent(SmartTileCellContext context) {
    final centerMaterialId = context.centerMaterialId;
    if (!_isEmptyMaterial(centerMaterialId, _materials)) return true;
    if (centerMaterialId != null &&
        centerMaterialId.isNotEmpty &&
        _explicitCenterMaterialIds.contains(centerMaterialId)) {
      return true;
    }

    bool slotHasIntent(int index, SmartTileObservedSlot slot) {
      final materialId = slot.materialId;
      return !_isEmptyMaterial(materialId, _materials) ||
          (materialId != null &&
              materialId.isNotEmpty &&
              _explicitSignatureMaterialIds[index].contains(materialId));
    }

    final observed = context.observed;
    return switch (preset.topology) {
      SmartTileTopology.uniform || SmartTileTopology.cardinal4 => false,
      SmartTileTopology.wangEdge4 => slotHasIntent(0, observed.northEdge) ||
          slotHasIntent(2, observed.eastEdge) ||
          slotHasIntent(4, observed.southEdge) ||
          slotHasIntent(6, observed.westEdge),
      SmartTileTopology.wangCorner4 =>
        slotHasIntent(1, observed.northEastCorner) ||
            slotHasIntent(3, observed.southEastCorner) ||
            slotHasIntent(5, observed.southWestCorner) ||
            slotHasIntent(7, observed.northWestCorner),
      SmartTileTopology.blob8 => false,
      SmartTileTopology.wang8 => slotHasIntent(0, observed.northEdge) ||
          slotHasIntent(1, observed.northEastCorner) ||
          slotHasIntent(2, observed.eastEdge) ||
          slotHasIntent(3, observed.southEastCorner) ||
          slotHasIntent(4, observed.southEdge) ||
          slotHasIntent(5, observed.southWestCorner) ||
          slotHasIntent(6, observed.westEdge) ||
          slotHasIntent(7, observed.northWestCorner),
    };
  }
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

final class _PreparedSmartTileSignature {
  _PreparedSmartTileSignature({
    required this.transform,
    required this.centerMatch,
    required this.constraints,
  }) : specificity = (centerMatch.kind == SmartTileMatchKind.any ? 0 : 1) +
            constraints.length;

  final SmartTileSpriteTransform transform;
  final SmartTileSlotMatch centerMatch;
  final List<_PreparedSlotConstraint> constraints;
  final int specificity;

  bool matches({
    required _PreparedSmartTileCellContext context,
    required Map<String, ProjectSmartTileMaterial> materials,
  }) {
    if (!_centerMatches(
      match: centerMatch,
      centerMaterialId: context.centerMaterialId,
      materials: materials,
    )) {
      return false;
    }
    for (final constraint in constraints) {
      if (!_slotMatches(
        match: constraint.match,
        neighborMaterialId: context.materialAt(constraint.slotIndex),
        centerMaterialId: context.centerMaterialId,
        materials: materials,
      )) {
        return false;
      }
    }
    return true;
  }
}

final class _PreparedSlotConstraint {
  const _PreparedSlotConstraint(this.slotIndex, this.match);

  final int slotIndex;
  final SmartTileSlotMatch match;
}

List<_PreparedSlotConstraint> _prepareSlotConstraints(
  SmartTileSignature signature,
  SmartTileTopology topology,
) {
  final constraints = <_PreparedSlotConstraint>[];

  void add(int index, SmartTileSlotMatch match) {
    if (match.kind != SmartTileMatchKind.any) {
      constraints.add(_PreparedSlotConstraint(index, match));
    }
  }

  switch (topology) {
    case SmartTileTopology.uniform:
      break;
    case SmartTileTopology.cardinal4:
    case SmartTileTopology.wangEdge4:
      add(0, signature.northEdge);
      add(2, signature.eastEdge);
      add(4, signature.southEdge);
      add(6, signature.westEdge);
      break;
    case SmartTileTopology.wangCorner4:
      add(1, signature.northEastCorner);
      add(3, signature.southEastCorner);
      add(5, signature.southWestCorner);
      add(7, signature.northWestCorner);
      break;
    case SmartTileTopology.blob8:
    case SmartTileTopology.wang8:
      add(0, signature.northEdge);
      add(1, signature.northEastCorner);
      add(2, signature.eastEdge);
      add(3, signature.southEastCorner);
      add(4, signature.southEdge);
      add(5, signature.southWestCorner);
      add(6, signature.westEdge);
      add(7, signature.northWestCorner);
      break;
  }
  return List<_PreparedSlotConstraint>.unmodifiable(constraints);
}

final class _PreparedSmartTileCellContext {
  factory _PreparedSmartTileCellContext({
    required ProjectSmartTilePreset preset,
    required Map<String, ProjectSmartTileMaterial> materials,
    required SmartTileCellContext context,
  }) {
    final center = context.centerMaterialId;
    final observed = context.observed;

    String? effective(SmartTileObservedSlot slot) => _effectiveMaterialId(
          slot: slot,
          policy: preset.boundaryPolicy,
          centerMaterialId: center,
        );

    final north = effective(observed.northEdge);
    final east = effective(observed.eastEdge);
    final south = effective(observed.southEdge);
    final west = effective(observed.westEdge);

    String? corner(
      SmartTileObservedSlot slot,
      String? firstSide,
      String? secondSide,
    ) {
      if (preset.topology == SmartTileTopology.blob8 &&
          (center == null ||
              !_sameConnectionGroup(center, firstSide, materials) ||
              !_sameConnectionGroup(center, secondSide, materials))) {
        return null;
      }
      return effective(slot);
    }

    return _PreparedSmartTileCellContext._(
      centerMaterialId: center,
      north: north,
      northEast: corner(observed.northEastCorner, north, east),
      east: east,
      southEast: corner(observed.southEastCorner, south, east),
      south: south,
      southWest: corner(observed.southWestCorner, south, west),
      west: west,
      northWest: corner(observed.northWestCorner, north, west),
    );
  }

  const _PreparedSmartTileCellContext._({
    required this.centerMaterialId,
    required this.north,
    required this.northEast,
    required this.east,
    required this.southEast,
    required this.south,
    required this.southWest,
    required this.west,
    required this.northWest,
  });

  final String? centerMaterialId;
  final String? north;
  final String? northEast;
  final String? east;
  final String? southEast;
  final String? south;
  final String? southWest;
  final String? west;
  final String? northWest;

  String? materialAt(int index) => switch (index) {
        0 => north,
        1 => northEast,
        2 => east,
        3 => southEast,
        4 => south,
        5 => southWest,
        6 => west,
        7 => northWest,
        _ => null,
      };
}

final class _PreparedSmartTileRule {
  factory _PreparedSmartTileRule({
    required SmartTileRule rule,
    required List<_PreparedSmartTileSignature> signatures,
    required List<int> hashSuffix,
  }) {
    final candidates = rule.candidates
        .where((candidate) => candidate.weight > 0)
        .toList(growable: false)
      ..sort(_compareCandidateIdsByUtf8);
    return _PreparedSmartTileRule._(
      rule: rule,
      signatures: signatures,
      hashSuffix: hashSuffix,
      candidates: List<SmartTileCandidate>.unmodifiable(candidates),
      totalWeight: candidates.fold<int>(
        0,
        (sum, candidate) => sum + candidate.weight,
      ),
      matchingRuleIds: List<String>.unmodifiable(<String>[rule.id]),
    );
  }

  const _PreparedSmartTileRule._({
    required this.rule,
    required this.signatures,
    required this.hashSuffix,
    required this.candidates,
    required this.totalWeight,
    required this.matchingRuleIds,
  });

  final SmartTileRule rule;
  final List<_PreparedSmartTileSignature> signatures;
  final List<int> hashSuffix;
  final List<SmartTileCandidate> candidates;
  final int totalWeight;
  final List<String> matchingRuleIds;
}

final class _PreparedMatchedRule {
  const _PreparedMatchedRule(this.rule, this.specificity, this.transforms);

  final _PreparedSmartTileRule rule;
  final int specificity;
  final List<SmartTileSpriteTransform> transforms;
}

SmartTileResolution _resolvePreparedCandidate({
  required ProjectSmartTilePreset preset,
  required _PreparedSmartTileRule rule,
  required List<SmartTileSpriteTransform> transforms,
  required bool usedFallback,
  required int hashPrefix,
  required int x,
  required int y,
}) {
  final hash = _preparedResolutionHash(
    hashPrefix: hashPrefix,
    hashSuffix: rule.hashSuffix,
    x: x,
    y: y,
  );
  final transform = _selectTransform(
    transforms,
    hash: hash,
    preferUntransformed: preset.transformPolicy.preferUntransformed,
  );
  final candidates = rule.candidates;
  if (candidates.isEmpty) {
    return SmartTileResolution(
      status: SmartTileResolutionStatus.noCandidate,
      ruleId: rule.rule.id,
      matchingRuleIds: rule.matchingRuleIds,
      usedFallback: usedFallback,
      transform: transform,
      message: 'The selected Smart Tile rule has no positive candidate.',
    );
  }

  var ticket = hash % rule.totalWeight;
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
    ruleId: rule.rule.id,
    candidate: selectedCandidate,
    deterministicHash: hash,
    matchingRuleIds: rule.matchingRuleIds,
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

const int _smartTileFnvOffsetBasis = 0xcbf29ce484222325;
const int _smartTileFnvPrime = 0x100000001b3;
const int _smartTileUint64Mask = 0xffffffffffffffff;

int _resolutionHashPrefix({
  required int projectSeed,
  required int layerSeed,
}) {
  var hash = _smartTileFnvOffsetBasis;
  hash = _hashInt64(hash, projectSeed);
  return _hashInt64(hash, layerSeed);
}

List<int> _resolutionHashSuffix({
  required int presetSeedSalt,
  required String mapId,
  required String layerId,
  required String presetId,
  required String ruleId,
}) {
  final bytes = <int>[];

  void addInt64(int value) {
    final encoded = value & _smartTileUint64Mask;
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

  addInt64(presetSeedSalt);
  addString(mapId);
  addString(layerId);
  addString(presetId);
  addString(ruleId);
  return bytes;
}

int _preparedResolutionHash({
  required int hashPrefix,
  required List<int> hashSuffix,
  required int x,
  required int y,
}) {
  var hash = _hashInt32(hashPrefix, x);
  hash = _hashInt32(hash, y);
  for (final byte in hashSuffix) {
    hash = _hashByte(hash, byte);
  }
  return hash;
}

int _hashInt32(int hash, int value) {
  final encoded = value & 0xffffffff;
  for (var shift = 0; shift < 32; shift += 8) {
    hash = _hashByte(hash, (encoded >> shift) & 0xff);
  }
  return hash;
}

int _hashInt64(int hash, int value) {
  final encoded = value & _smartTileUint64Mask;
  for (var shift = 0; shift < 64; shift += 8) {
    hash = _hashByte(hash, (encoded >> shift) & 0xff);
  }
  return hash;
}

int _hashByte(int hash, int byte) {
  return ((hash ^ (byte & 0xff)) * _smartTileFnvPrime) & _smartTileUint64Mask;
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
