import 'package:map_core/map_core.dart';

// ---------------------------------------------------------------------------
// Lot Environment-26 — suppression des placements générés d’une EnvironmentArea.
// Pur Dart, pas de Flutter / I/O ; pas de mutation si erreur bloquante.
// ---------------------------------------------------------------------------

/// Enregistrement d’un [MapPlacedElement] retiré par Clear.
final class EnvironmentClearedGeneratedPlacement {
  const EnvironmentClearedGeneratedPlacement({
    required this.placedElementId,
    required this.elementId,
    required this.layerId,
    required this.pos,
  });

  final String placedElementId;
  final String elementId;
  final String layerId;
  final GridPos pos;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is EnvironmentClearedGeneratedPlacement &&
            placedElementId == other.placedElementId &&
            elementId == other.elementId &&
            layerId == other.layerId &&
            pos == other.pos;
  }

  @override
  int get hashCode => Object.hash(placedElementId, elementId, layerId, pos);
}

enum EnvironmentClearIssueSeverity {
  error,
  warning,
}

enum EnvironmentClearIssueKind {
  environmentLayerNotFound,
  layerIsNotEnvironmentLayer,
  areaNotFound,
  noGeneratedPlacements,
  missingGeneratedPlacement,
  mapValidationFailed,
}

final class EnvironmentClearIssue {
  const EnvironmentClearIssue({
    required this.severity,
    required this.kind,
    required this.message,
    this.environmentLayerId,
    this.areaId,
    this.placedElementId,
  });

  final EnvironmentClearIssueSeverity severity;
  final EnvironmentClearIssueKind kind;
  final String message;
  final String? environmentLayerId;
  final String? areaId;
  final String? placedElementId;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is EnvironmentClearIssue &&
            severity == other.severity &&
            kind == other.kind &&
            message == other.message &&
            environmentLayerId == other.environmentLayerId &&
            areaId == other.areaId &&
            placedElementId == other.placedElementId;
  }

  @override
  int get hashCode => Object.hash(
        severity,
        kind,
        message,
        environmentLayerId,
        areaId,
        placedElementId,
      );
}

final class EnvironmentClearResult {
  factory EnvironmentClearResult({
    required MapData map,
    required List<EnvironmentClearedGeneratedPlacement> clearedPlacements,
    required List<EnvironmentClearIssue> issues,
  }) {
    return EnvironmentClearResult._(
      map: map,
      clearedPlacements:
          List<EnvironmentClearedGeneratedPlacement>.unmodifiable(
        List<EnvironmentClearedGeneratedPlacement>.from(clearedPlacements),
      ),
      issues: List<EnvironmentClearIssue>.unmodifiable(
        List<EnvironmentClearIssue>.from(issues),
      ),
    );
  }

  const EnvironmentClearResult._({
    required this.map,
    required this.clearedPlacements,
    required this.issues,
  });

  final MapData map;
  final List<EnvironmentClearedGeneratedPlacement> clearedPlacements;
  final List<EnvironmentClearIssue> issues;

  bool get hasErrors =>
      issues.any((i) => i.severity == EnvironmentClearIssueSeverity.error);

  bool get hasWarnings =>
      issues.any((i) => i.severity == EnvironmentClearIssueSeverity.warning);

  int get errorCount => issues
      .where((i) => i.severity == EnvironmentClearIssueSeverity.error)
      .length;

  int get warningCount => issues
      .where((i) => i.severity == EnvironmentClearIssueSeverity.warning)
      .length;

  int get clearedPlacementCount => clearedPlacements.length;

  List<EnvironmentClearIssue> issuesForKind(EnvironmentClearIssueKind kind) {
    return List<EnvironmentClearIssue>.unmodifiable(
      issues.where((i) => i.kind == kind).toList(growable: false),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is EnvironmentClearResult &&
        map == other.map &&
        clearedPlacementCount == other.clearedPlacementCount &&
        _listEqualsCleared(clearedPlacements, other.clearedPlacements) &&
        _listEqualsClearIssues(issues, other.issues);
  }

  @override
  int get hashCode => Object.hash(
        map,
        clearedPlacementCount,
        Object.hashAll(clearedPlacements),
        Object.hashAll(issues),
      );
}

bool _listEqualsCleared(
  List<EnvironmentClearedGeneratedPlacement> a,
  List<EnvironmentClearedGeneratedPlacement> b,
) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}

bool _listEqualsClearIssues(
  List<EnvironmentClearIssue> a,
  List<EnvironmentClearIssue> b,
) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}

EnvironmentClearResult _failure(
  MapData original, {
  required List<EnvironmentClearIssue> issues,
}) {
  return EnvironmentClearResult(
    map: original,
    clearedPlacements: const [],
    issues: issues,
  );
}

/// Retire les [MapPlacedElement] dont l’id est listé dans
/// [EnvironmentArea.generatedPlacementIds], puis vide cette liste.
///
/// Tolérant aux ids manquants (warning, nettoyage quand même).
/// Aucune suppression hors de la liste de l’area.
class ClearEnvironmentGeneratedPlacementsUseCase {
  EnvironmentClearResult execute(
    MapData map, {
    required String environmentLayerId,
    required String areaId,
  }) {
    final issues = <EnvironmentClearIssue>[];
    final envId = environmentLayerId.trim();
    final aid = areaId.trim();

    EnvironmentLayer? envLayer;
    for (final layer in map.layers) {
      if (layer.id == envId) {
        if (layer is EnvironmentLayer) {
          envLayer = layer;
        } else {
          issues.add(
            EnvironmentClearIssue(
              severity: EnvironmentClearIssueSeverity.error,
              kind: EnvironmentClearIssueKind.layerIsNotEnvironmentLayer,
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
        EnvironmentClearIssue(
          severity: EnvironmentClearIssueSeverity.error,
          kind: EnvironmentClearIssueKind.environmentLayerNotFound,
          message: 'Environment layer not found: $envId',
          environmentLayerId: envId,
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
        EnvironmentClearIssue(
          severity: EnvironmentClearIssueSeverity.error,
          kind: EnvironmentClearIssueKind.areaNotFound,
          message: 'Environment area not found: $aid',
          environmentLayerId: envId,
          areaId: aid,
        ),
      );
      return _failure(map, issues: issues);
    }

    final ids = area.generatedPlacementIds;
    if (ids.isEmpty) {
      issues.add(
        const EnvironmentClearIssue(
          severity: EnvironmentClearIssueSeverity.warning,
          kind: EnvironmentClearIssueKind.noGeneratedPlacements,
          message: 'Cette zone n’a aucun placement généré référencé.',
        ),
      );
      return EnvironmentClearResult(
        map: map,
        clearedPlacements: const [],
        issues: issues,
      );
    }

    final idSet = ids.toSet();
    final placedById = <String, MapPlacedElement>{
      for (final p in map.placedElements) p.id: p,
    };

    final cleared = <EnvironmentClearedGeneratedPlacement>[];
    for (final pid in ids) {
      final placed = placedById[pid];
      if (placed == null) {
        issues.add(
          EnvironmentClearIssue(
            severity: EnvironmentClearIssueSeverity.warning,
            kind: EnvironmentClearIssueKind.missingGeneratedPlacement,
            message: 'Placement généré absent de la carte : $pid',
            environmentLayerId: envId,
            areaId: aid,
            placedElementId: pid,
          ),
        );
      } else {
        cleared.add(
          EnvironmentClearedGeneratedPlacement(
            placedElementId: placed.id,
            elementId: placed.elementId,
            layerId: placed.layerId,
            pos: placed.pos,
          ),
        );
      }
    }

    final newPlaced = <MapPlacedElement>[
      for (final p in map.placedElements)
        if (!idSet.contains(p.id)) p,
    ];

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
            generatedPlacementIds: const [],
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
      MapValidator.validate(updated);
    } catch (e) {
      issues.add(
        EnvironmentClearIssue(
          severity: EnvironmentClearIssueSeverity.error,
          kind: EnvironmentClearIssueKind.mapValidationFailed,
          message: 'MapValidator.validate failed: $e',
          environmentLayerId: envId,
          areaId: aid,
        ),
      );
      return _failure(map, issues: issues);
    }

    return EnvironmentClearResult(
      map: updated,
      clearedPlacements: cleared,
      issues: issues,
    );
  }
}
