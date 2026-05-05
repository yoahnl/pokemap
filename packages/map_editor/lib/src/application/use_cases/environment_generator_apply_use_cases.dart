import 'package:map_core/map_core.dart';

import 'environment_generator_use_cases.dart';

// ---------------------------------------------------------------------------
// Lot Environment-24 — application des candidats Lot 23 → MapPlacedElement.
// Aucune UI, aucun I/O, pas de mutation si erreur.
// ---------------------------------------------------------------------------

/// Lien entre un candidat Lot 23 et l’instance [MapPlacedElement] créée.
final class EnvironmentAppliedGeneratedPlacement {
  const EnvironmentAppliedGeneratedPlacement({
    required this.candidateId,
    required this.placedElementId,
    required this.elementId,
    required this.layerId,
    required this.pos,
  });

  final String candidateId;
  final String placedElementId;
  final String elementId;
  final String layerId;
  final GridPos pos;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is EnvironmentAppliedGeneratedPlacement &&
            candidateId == other.candidateId &&
            placedElementId == other.placedElementId &&
            elementId == other.elementId &&
            layerId == other.layerId &&
            pos == other.pos;
  }

  @override
  int get hashCode =>
      Object.hash(candidateId, placedElementId, elementId, layerId, pos);
}

enum EnvironmentApplyIssueSeverity {
  error,
}

enum EnvironmentApplyIssueKind {
  environmentLayerNotFound,
  layerIsNotEnvironmentLayer,
  targetTileLayerMissing,
  targetTileLayerInvalid,
  areaNotFound,
  areaAlreadyHasGeneratedPlacements,
  emptyCandidates,
  candidateWrongEnvironmentLayer,
  candidateWrongArea,
  candidateWrongPreset,
  candidateWrongTargetLayer,
  candidateElementMissing,
  candidateOutOfBounds,
  candidateTargetLayerTilesetMismatch,
  candidateDuplicateId,
  placedElementIdConflict,
  candidatePositionDuplicate,
  mapValidationFailed,
}

final class EnvironmentApplyIssue {
  const EnvironmentApplyIssue({
    required this.severity,
    required this.kind,
    required this.message,
    this.environmentLayerId,
    this.areaId,
    this.candidateId,
    this.targetLayerId,
    this.elementId,
    this.placedElementId,
  });

  final EnvironmentApplyIssueSeverity severity;
  final EnvironmentApplyIssueKind kind;
  final String message;
  final String? environmentLayerId;
  final String? areaId;
  final String? candidateId;
  final String? targetLayerId;
  final String? elementId;
  final String? placedElementId;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is EnvironmentApplyIssue &&
            severity == other.severity &&
            kind == other.kind &&
            message == other.message &&
            environmentLayerId == other.environmentLayerId &&
            areaId == other.areaId &&
            candidateId == other.candidateId &&
            targetLayerId == other.targetLayerId &&
            elementId == other.elementId &&
            placedElementId == other.placedElementId;
  }

  @override
  int get hashCode => Object.hash(
        severity,
        kind,
        message,
        environmentLayerId,
        areaId,
        candidateId,
        targetLayerId,
        elementId,
        placedElementId,
      );
}

final class EnvironmentApplyResult {
  factory EnvironmentApplyResult({
    required MapData map,
    required List<EnvironmentAppliedGeneratedPlacement> appliedPlacements,
    required List<EnvironmentApplyIssue> issues,
  }) {
    return EnvironmentApplyResult._(
      map: map,
      appliedPlacements:
          List<EnvironmentAppliedGeneratedPlacement>.unmodifiable(
        List<EnvironmentAppliedGeneratedPlacement>.from(appliedPlacements),
      ),
      issues: List<EnvironmentApplyIssue>.unmodifiable(
        List<EnvironmentApplyIssue>.from(issues),
      ),
    );
  }

  const EnvironmentApplyResult._({
    required this.map,
    required this.appliedPlacements,
    required this.issues,
  });

  final MapData map;
  final List<EnvironmentAppliedGeneratedPlacement> appliedPlacements;
  final List<EnvironmentApplyIssue> issues;

  bool get hasErrors =>
      issues.any((i) => i.severity == EnvironmentApplyIssueSeverity.error);

  int get errorCount => issues
      .where((i) => i.severity == EnvironmentApplyIssueSeverity.error)
      .length;

  int get appliedPlacementCount => appliedPlacements.length;

  List<EnvironmentApplyIssue> issuesForKind(EnvironmentApplyIssueKind kind) {
    return List<EnvironmentApplyIssue>.unmodifiable(
      issues.where((i) => i.kind == kind).toList(growable: false),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is EnvironmentApplyResult &&
        map == other.map &&
        appliedPlacementCount == other.appliedPlacementCount &&
        _listEqualsApplied(appliedPlacements, other.appliedPlacements) &&
        _listEqualsApplyIssues(issues, other.issues);
  }

  @override
  int get hashCode => Object.hash(
        map,
        appliedPlacementCount,
        Object.hashAll(appliedPlacements),
        Object.hashAll(issues),
      );
}

bool _listEqualsApplied(
  List<EnvironmentAppliedGeneratedPlacement> a,
  List<EnvironmentAppliedGeneratedPlacement> b,
) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}

bool _listEqualsApplyIssues(
  List<EnvironmentApplyIssue> a,
  List<EnvironmentApplyIssue> b,
) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}

bool _originInBounds(GridPos pos, GridSize size) {
  return pos.x >= 0 && pos.y >= 0 && pos.x < size.width && pos.y < size.height;
}

/// Footprint [MapValidator] quand [projectDialogueContext] est fourni (élément connu).
bool _footprintInBounds({
  required GridPos pos,
  required GridSize mapSize,
  required ProjectElementEntry element,
}) {
  final source = element.frames.primarySource;
  final width = source.width <= 0 ? 1 : source.width;
  final height = source.height <= 0 ? 1 : source.height;
  final right = pos.x + width;
  final bottom = pos.y + height;
  return right <= mapSize.width && bottom <= mapSize.height;
}

String _effectiveTileLayerTilesetId(TileLayer layer, MapData map) {
  return (layer.tilesetId ?? map.tilesetId).trim();
}

String _elementPrimaryTilesetId(ProjectElementEntry element) {
  final frameTilesetId = element.frames.primaryFrame.tilesetId.trim();
  if (frameTilesetId.isNotEmpty) return frameTilesetId;
  return element.tilesetId.trim();
}

bool _applyCollisionFromCandidate(EnvironmentCollisionMode mode) {
  switch (mode) {
    case EnvironmentCollisionMode.forceEnabled:
      return true;
    case EnvironmentCollisionMode.forceDisabled:
      return false;
    case EnvironmentCollisionMode.useElementDefault:
      // [MapPlacedElement] défaut = true ; aligné sur l’indexeur d’instances tuiles.
      // Le profil [ElementCollisionProfile] pilote la géométrie, pas ce booléen.
      return true;
  }
}

EnvironmentApplyResult _failure(
  MapData original, {
  required List<EnvironmentApplyIssue> issues,
}) {
  return EnvironmentApplyResult(
    map: original,
    appliedPlacements: const [],
    issues: issues,
  );
}

/// Applique des [EnvironmentGeneratedPlacementCandidate] sur une [MapData] en mémoire.
///
/// Transactionnel : la moindre erreur → [map] d’entrée inchangée, aucun placement créé.
class ApplyEnvironmentGeneratedPlacementsUseCase {
  EnvironmentApplyResult execute(
    MapData map, {
    required ProjectManifest manifest,
    required String environmentLayerId,
    required String areaId,
    required List<EnvironmentGeneratedPlacementCandidate> candidates,
  }) {
    final issues = <EnvironmentApplyIssue>[];
    final envId = environmentLayerId.trim();
    final aid = areaId.trim();

    EnvironmentLayer? envLayer;
    for (final layer in map.layers) {
      if (layer.id == envId) {
        if (layer is EnvironmentLayer) {
          envLayer = layer;
        } else {
          issues.add(
            EnvironmentApplyIssue(
              severity: EnvironmentApplyIssueSeverity.error,
              kind: EnvironmentApplyIssueKind.layerIsNotEnvironmentLayer,
              message: 'Layer is not an environment layer: $envId',
              environmentLayerId: envId,
            ),
          );
          return _failure(map, issues: issues);
        }
        break;
      }
    }
    if (envLayer == null) {
      issues.add(
        EnvironmentApplyIssue(
          severity: EnvironmentApplyIssueSeverity.error,
          kind: EnvironmentApplyIssueKind.environmentLayerNotFound,
          message: 'Environment layer not found: $envId',
          environmentLayerId: envId,
        ),
      );
      return _failure(map, issues: issues);
    }

    final targetId = envLayer.content.targetTileLayerId?.trim();
    if (targetId == null || targetId.isEmpty) {
      issues.add(
        EnvironmentApplyIssue(
          severity: EnvironmentApplyIssueSeverity.error,
          kind: EnvironmentApplyIssueKind.targetTileLayerMissing,
          message: 'Environment layer has no target tile layer id',
          environmentLayerId: envId,
        ),
      );
      return _failure(map, issues: issues);
    }

    TileLayer? targetTileLayer;
    for (final layer in map.layers) {
      if (layer.id == targetId) {
        if (layer is! TileLayer) {
          issues.add(
            EnvironmentApplyIssue(
              severity: EnvironmentApplyIssueSeverity.error,
              kind: EnvironmentApplyIssueKind.targetTileLayerInvalid,
              message:
                  'Target tile layer id does not reference a TileLayer: $targetId',
              environmentLayerId: envId,
              targetLayerId: targetId,
            ),
          );
          return _failure(map, issues: issues);
        }
        targetTileLayer = layer;
        break;
      }
    }
    if (targetTileLayer == null) {
      issues.add(
        EnvironmentApplyIssue(
          severity: EnvironmentApplyIssueSeverity.error,
          kind: EnvironmentApplyIssueKind.targetTileLayerInvalid,
          message: 'Target tile layer not found: $targetId',
          environmentLayerId: envId,
          targetLayerId: targetId,
        ),
      );
      return _failure(map, issues: issues);
    }

    EnvironmentArea? area;
    for (final a in envLayer.content.areas) {
      if (a.id == aid) {
        area = a;
        break;
      }
    }
    if (area == null) {
      issues.add(
        EnvironmentApplyIssue(
          severity: EnvironmentApplyIssueSeverity.error,
          kind: EnvironmentApplyIssueKind.areaNotFound,
          message: 'Environment area not found: $aid',
          environmentLayerId: envId,
          areaId: aid,
        ),
      );
      return _failure(map, issues: issues);
    }

    if (area.generatedPlacementIds.isNotEmpty) {
      issues.add(
        EnvironmentApplyIssue(
          severity: EnvironmentApplyIssueSeverity.error,
          kind: EnvironmentApplyIssueKind.areaAlreadyHasGeneratedPlacements,
          message:
              'Environment area already has generated placements (${area.generatedPlacementIds.length})',
          environmentLayerId: envId,
          areaId: aid,
        ),
      );
      return _failure(map, issues: issues);
    }

    if (candidates.isEmpty) {
      issues.add(
        const EnvironmentApplyIssue(
          severity: EnvironmentApplyIssueSeverity.error,
          kind: EnvironmentApplyIssueKind.emptyCandidates,
          message: 'No placement candidates to apply',
        ),
      );
      return _failure(map, issues: issues);
    }

    final elementById = <String, ProjectElementEntry>{
      for (final e in manifest.elements) e.id: e,
    };

    final seenCandidateIds = <String>{};
    final seenPositions = <String>{};
    final existingPlacedIds = <String>{
      for (final p in map.placedElements) p.id,
    };
    final stagedPlacedIds = <String>{};

    for (final c in candidates) {
      if (!seenCandidateIds.add(c.id)) {
        issues.add(
          EnvironmentApplyIssue(
            severity: EnvironmentApplyIssueSeverity.error,
            kind: EnvironmentApplyIssueKind.candidateDuplicateId,
            message: 'Duplicate candidate id: ${c.id}',
            environmentLayerId: envId,
            areaId: aid,
            candidateId: c.id,
          ),
        );
        return _failure(map, issues: issues);
      }

      if (c.environmentLayerId.trim() != envId) {
        issues.add(
          EnvironmentApplyIssue(
            severity: EnvironmentApplyIssueSeverity.error,
            kind: EnvironmentApplyIssueKind.candidateWrongEnvironmentLayer,
            message: 'Candidate environmentLayerId mismatch: ${c.id}',
            environmentLayerId: envId,
            areaId: aid,
            candidateId: c.id,
          ),
        );
        return _failure(map, issues: issues);
      }
      if (c.areaId.trim() != aid) {
        issues.add(
          EnvironmentApplyIssue(
            severity: EnvironmentApplyIssueSeverity.error,
            kind: EnvironmentApplyIssueKind.candidateWrongArea,
            message: 'Candidate areaId mismatch: ${c.id}',
            environmentLayerId: envId,
            areaId: aid,
            candidateId: c.id,
          ),
        );
        return _failure(map, issues: issues);
      }
      if (c.presetId.trim() != area.presetId.trim()) {
        issues.add(
          EnvironmentApplyIssue(
            severity: EnvironmentApplyIssueSeverity.error,
            kind: EnvironmentApplyIssueKind.candidateWrongPreset,
            message: 'Candidate presetId mismatch: ${c.id}',
            environmentLayerId: envId,
            areaId: aid,
            candidateId: c.id,
          ),
        );
        return _failure(map, issues: issues);
      }
      if (c.targetLayerId.trim() != targetId) {
        issues.add(
          EnvironmentApplyIssue(
            severity: EnvironmentApplyIssueSeverity.error,
            kind: EnvironmentApplyIssueKind.candidateWrongTargetLayer,
            message: 'Candidate targetLayerId mismatch: ${c.id}',
            environmentLayerId: envId,
            areaId: aid,
            candidateId: c.id,
            targetLayerId: c.targetLayerId,
          ),
        );
        return _failure(map, issues: issues);
      }

      final entry = elementById[c.elementId.trim()];
      if (entry == null) {
        issues.add(
          EnvironmentApplyIssue(
            severity: EnvironmentApplyIssueSeverity.error,
            kind: EnvironmentApplyIssueKind.candidateElementMissing,
            message: 'Candidate references unknown element: ${c.elementId}',
            environmentLayerId: envId,
            areaId: aid,
            candidateId: c.id,
            elementId: c.elementId,
          ),
        );
        return _failure(map, issues: issues);
      }

      if (!_originInBounds(c.pos, map.size) ||
          !_footprintInBounds(pos: c.pos, mapSize: map.size, element: entry)) {
        issues.add(
          EnvironmentApplyIssue(
            severity: EnvironmentApplyIssueSeverity.error,
            kind: EnvironmentApplyIssueKind.candidateOutOfBounds,
            message:
                'Candidate position or footprint out of map bounds: ${c.id}',
            environmentLayerId: envId,
            areaId: aid,
            candidateId: c.id,
            elementId: c.elementId,
          ),
        );
        return _failure(map, issues: issues);
      }

      final targetTilesetId =
          _effectiveTileLayerTilesetId(targetTileLayer, map);
      final elementTilesetId = _elementPrimaryTilesetId(entry);
      if (targetTilesetId.isNotEmpty &&
          elementTilesetId.isNotEmpty &&
          targetTilesetId != elementTilesetId) {
        issues.add(
          EnvironmentApplyIssue(
            severity: EnvironmentApplyIssueSeverity.error,
            kind: EnvironmentApplyIssueKind.candidateTargetLayerTilesetMismatch,
            message: 'Candidate ${c.id} uses element ${c.elementId} from '
                'tileset $elementTilesetId, but target layer $targetId '
                'uses tileset $targetTilesetId.',
            environmentLayerId: envId,
            areaId: aid,
            candidateId: c.id,
            targetLayerId: targetId,
            elementId: c.elementId,
          ),
        );
        return _failure(map, issues: issues);
      }

      final placedId = c.id;
      if (existingPlacedIds.contains(placedId) ||
          stagedPlacedIds.contains(placedId)) {
        issues.add(
          EnvironmentApplyIssue(
            severity: EnvironmentApplyIssueSeverity.error,
            kind: EnvironmentApplyIssueKind.placedElementIdConflict,
            message: 'Placed element id already exists: $placedId',
            environmentLayerId: envId,
            areaId: aid,
            candidateId: c.id,
            placedElementId: placedId,
          ),
        );
        return _failure(map, issues: issues);
      }

      final posKey = '${c.targetLayerId.trim()}|${c.pos.x}|${c.pos.y}';
      if (!seenPositions.add(posKey)) {
        issues.add(
          EnvironmentApplyIssue(
            severity: EnvironmentApplyIssueSeverity.error,
            kind: EnvironmentApplyIssueKind.candidatePositionDuplicate,
            message: 'Duplicate candidate position on layer: $posKey',
            environmentLayerId: envId,
            areaId: aid,
            candidateId: c.id,
            targetLayerId: c.targetLayerId,
          ),
        );
        return _failure(map, issues: issues);
      }

      stagedPlacedIds.add(placedId);
    }

    final newPlaced = <MapPlacedElement>[
      ...map.placedElements,
    ];
    final applied = <EnvironmentAppliedGeneratedPlacement>[];
    final newPlacementIds = <String>[];

    for (final c in candidates) {
      final applyCollision = _applyCollisionFromCandidate(c.collisionMode);
      final placed = MapPlacedElement(
        id: c.id,
        layerId: c.targetLayerId.trim(),
        elementId: c.elementId.trim(),
        pos: c.pos,
        applyCollision: applyCollision,
      );
      newPlaced.add(placed);
      newPlacementIds.add(c.id);
      applied.add(
        EnvironmentAppliedGeneratedPlacement(
          candidateId: c.id,
          placedElementId: c.id,
          elementId: c.elementId.trim(),
          layerId: c.targetLayerId.trim(),
          pos: c.pos,
        ),
      );
    }

    final newAreas = <EnvironmentArea>[
      for (final a in envLayer.content.areas)
        if (a.id == aid)
          EnvironmentArea(
            id: a.id,
            name: a.name,
            presetId: a.presetId,
            mask: a.mask,
            seed: a.seed,
            paramsOverride: a.paramsOverride,
            generatedPlacementIds: newPlacementIds,
          )
        else
          a,
    ];

    final newContent = EnvironmentLayerContent(
      targetTileLayerId: envLayer.content.targetTileLayerId,
      areas: newAreas,
    );

    MapData updated;
    try {
      updated = setEnvironmentLayerContent(
        map,
        layerId: envId,
        content: newContent,
      ).copyWith(placedElements: newPlaced);
      MapValidator.validate(updated, projectDialogueContext: manifest);
    } catch (e) {
      issues.add(
        EnvironmentApplyIssue(
          severity: EnvironmentApplyIssueSeverity.error,
          kind: EnvironmentApplyIssueKind.mapValidationFailed,
          message: 'MapValidator.validate failed: $e',
          environmentLayerId: envId,
          areaId: aid,
        ),
      );
      return _failure(map, issues: issues);
    }

    return EnvironmentApplyResult(
      map: updated,
      appliedPlacements: applied,
      issues: const [],
    );
  }
}
