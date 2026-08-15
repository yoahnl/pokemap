import 'dart:convert';

import '../models/enums.dart';
import '../models/geometry.dart';
import '../models/map_data.dart';
import '../models/project_manifest.dart';

enum EncounterProbabilityIssue {
  invalidChancePerStep,
  nonPositiveWeight,
  zeroTotalWeight,
}

class EncounterEntryProbability {
  const EncounterEntryProbability({
    required this.weight,
    required this.relativeShare,
    required this.resolvedChancePerStep,
  });

  final int weight;
  final double? relativeShare;
  final double? resolvedChancePerStep;
}

class EncounterProbabilityProjection {
  const EncounterProbabilityProjection({
    required this.chancePerStep,
    required this.totalWeight,
    required this.entries,
    required this.issues,
  });

  final double chancePerStep;
  final int totalWeight;
  final List<EncounterEntryProbability> entries;
  final Set<EncounterProbabilityIssue> issues;

  bool get isValid => issues.isEmpty;
}

EncounterProbabilityProjection projectEncounterProbabilities({
  required double chancePerStep,
  required Iterable<int> weights,
}) {
  final orderedWeights = weights.toList(growable: false);
  final totalWeight = orderedWeights.fold<int>(
    0,
    (sum, weight) => sum + weight,
  );
  final issues = <EncounterProbabilityIssue>{};
  if (!chancePerStep.isFinite || chancePerStep < 0 || chancePerStep > 1) {
    issues.add(EncounterProbabilityIssue.invalidChancePerStep);
  }
  if (orderedWeights.any((weight) => weight <= 0)) {
    issues.add(EncounterProbabilityIssue.nonPositiveWeight);
  }
  if (totalWeight <= 0) {
    issues.add(EncounterProbabilityIssue.zeroTotalWeight);
  }
  final canProject = issues.isEmpty;
  final entries = orderedWeights
      .map((weight) {
        final relativeShare = canProject ? weight / totalWeight : null;
        return EncounterEntryProbability(
          weight: weight,
          relativeShare: relativeShare,
          resolvedChancePerStep: relativeShare == null
              ? null
              : chancePerStep * relativeShare,
        );
      })
      .toList(growable: false);
  return EncounterProbabilityProjection(
    chancePerStep: chancePerStep,
    totalWeight: totalWeight,
    entries: List<EncounterEntryProbability>.unmodifiable(entries),
    issues: Set<EncounterProbabilityIssue>.unmodifiable(issues),
  );
}

List<ProjectEncounterEntry> canonicalEncounterEntries(
  Iterable<ProjectEncounterEntry> entries,
) {
  final ordered = entries.toList(growable: false)
    ..sort((left, right) {
      var comparison = left.speciesId.compareTo(right.speciesId);
      if (comparison != 0) return comparison;
      comparison = left.minLevel.compareTo(right.minLevel);
      if (comparison != 0) return comparison;
      comparison = left.maxLevel.compareTo(right.maxLevel);
      if (comparison != 0) return comparison;
      comparison = left.weight.compareTo(right.weight);
      if (comparison != 0) return comparison;
      return jsonEncode(
        left.pokemonOverrides?.toJson(),
      ).compareTo(jsonEncode(right.pokemonOverrides?.toJson()));
    });
  return List<ProjectEncounterEntry>.unmodifiable(ordered);
}

enum EncounterZoneResolutionStatus { noZone, resolved, ambiguous }

class EncounterZoneResolution {
  const EncounterZoneResolution._({
    required this.status,
    this.zone,
    this.ambiguousZoneIds = const <String>[],
  });

  const EncounterZoneResolution.noZone()
    : this._(status: EncounterZoneResolutionStatus.noZone);

  EncounterZoneResolution.resolved(MapGameplayZone zone)
    : this._(status: EncounterZoneResolutionStatus.resolved, zone: zone);

  EncounterZoneResolution.ambiguous(Iterable<String> zoneIds)
    : this._(
        status: EncounterZoneResolutionStatus.ambiguous,
        ambiguousZoneIds: List<String>.unmodifiable(
          zoneIds.toList(growable: false)..sort(),
        ),
      );

  final EncounterZoneResolutionStatus status;
  final MapGameplayZone? zone;
  final List<String> ambiguousZoneIds;
}

class EncounterZoneAmbiguity {
  EncounterZoneAmbiguity({
    required this.encounterKind,
    required this.priority,
    required Iterable<String> zoneIds,
  }) : zoneIds = List<String>.unmodifiable(
         zoneIds.toList(growable: false)..sort(),
       );

  final EncounterKind encounterKind;
  final int priority;
  final List<String> zoneIds;
}

EncounterZoneResolution resolveEncounterZoneAtPosition(
  Iterable<MapGameplayZone> zones, {
  required GridPos position,
  required EncounterKind encounterKind,
}) {
  final eligible = zones
      .where((zone) => zone.kind == GameplayZoneKind.encounter)
      .where((zone) => zone.encounter?.encounterKind == encounterKind)
      .where((zone) => _containsPosition(zone.area, position))
      .toList(growable: false);
  if (eligible.isEmpty) {
    return const EncounterZoneResolution.noZone();
  }
  final highestPriority = eligible
      .map((zone) => zone.priority)
      .reduce((left, right) => left > right ? left : right);
  final highest = eligible
      .where((zone) => zone.priority == highestPriority)
      .toList(growable: false);
  if (highest.length > 1) {
    final payload = highest.first.encounter;
    if (highest.every((zone) => zone.encounter == payload)) {
      final canonical = highest.toList(growable: false)
        ..sort((left, right) => left.id.compareTo(right.id));
      return EncounterZoneResolution.resolved(canonical.first);
    }
    return EncounterZoneResolution.ambiguous(highest.map((zone) => zone.id));
  }
  return EncounterZoneResolution.resolved(highest.single);
}

List<EncounterZoneAmbiguity> findEncounterZoneAmbiguities(
  Iterable<MapGameplayZone> zones,
) {
  final encounters =
      zones
          .where((zone) => zone.kind == GameplayZoneKind.encounter)
          .where((zone) => zone.encounter != null)
          .toList(growable: false)
        ..sort((left, right) => left.id.compareTo(right.id));
  final ambiguities = <EncounterZoneAmbiguity>[];
  for (var leftIndex = 0; leftIndex < encounters.length; leftIndex++) {
    final left = encounters[leftIndex];
    for (
      var rightIndex = leftIndex + 1;
      rightIndex < encounters.length;
      rightIndex++
    ) {
      final right = encounters[rightIndex];
      if (left.priority != right.priority ||
          left.encounter!.encounterKind != right.encounter!.encounterKind ||
          left.encounter == right.encounter ||
          !_rectanglesOverlap(left.area, right.area)) {
        continue;
      }
      ambiguities.add(
        EncounterZoneAmbiguity(
          encounterKind: left.encounter!.encounterKind,
          priority: left.priority,
          zoneIds: <String>[left.id, right.id],
        ),
      );
    }
  }
  return List<EncounterZoneAmbiguity>.unmodifiable(ambiguities);
}

bool _containsPosition(MapRect area, GridPos pos) {
  final right = area.pos.x + area.size.width;
  final bottom = area.pos.y + area.size.height;
  return pos.x >= area.pos.x &&
      pos.x < right &&
      pos.y >= area.pos.y &&
      pos.y < bottom;
}

bool _rectanglesOverlap(MapRect left, MapRect right) {
  final leftRight = left.pos.x + left.size.width;
  final leftBottom = left.pos.y + left.size.height;
  final rightRight = right.pos.x + right.size.width;
  final rightBottom = right.pos.y + right.size.height;
  return left.pos.x < rightRight &&
      leftRight > right.pos.x &&
      left.pos.y < rightBottom &&
      leftBottom > right.pos.y;
}
