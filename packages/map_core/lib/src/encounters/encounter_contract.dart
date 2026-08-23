import 'dart:convert';

import '../models/enums.dart';
import '../models/geometry.dart';
import '../models/map_data.dart';
import '../models/map_layer.dart';
import '../models/map_gameplay_zone_payloads.dart';
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

enum EncounterSourceKind { gameplayZone, smartTileLayer }

class EncounterSource {
  const EncounterSource({
    required this.kind,
    required this.id,
    required this.priority,
    required this.encounter,
  });

  final EncounterSourceKind kind;
  final String id;
  final int priority;
  final EncounterZonePayload encounter;
}

enum EncounterSourceResolutionStatus { noSource, resolved, ambiguous }

class EncounterSourceResolution {
  const EncounterSourceResolution._({
    required this.status,
    this.source,
    this.ambiguousSourceIds = const <String>[],
  });

  const EncounterSourceResolution.noSource()
    : this._(status: EncounterSourceResolutionStatus.noSource);

  EncounterSourceResolution.resolved(EncounterSource source)
    : this._(status: EncounterSourceResolutionStatus.resolved, source: source);

  EncounterSourceResolution.ambiguous(Iterable<String> sourceIds)
    : this._(
        status: EncounterSourceResolutionStatus.ambiguous,
        ambiguousSourceIds: List<String>.unmodifiable(
          sourceIds.toList(growable: false)..sort(),
        ),
      );

  final EncounterSourceResolutionStatus status;
  final EncounterSource? source;
  final List<String> ambiguousSourceIds;
}

class EncounterSourceAmbiguity {
  EncounterSourceAmbiguity({
    required this.encounterKind,
    required this.priority,
    required this.position,
    required Iterable<String> sourceIds,
  }) : sourceIds = List<String>.unmodifiable(
         sourceIds.toList(growable: false)..sort(),
       );

  final EncounterKind encounterKind;
  final int priority;
  final GridPos position;
  final List<String> sourceIds;
}

EncounterSource? findEncounterSource(
  MapData map, {
  required EncounterSourceKind kind,
  required String id,
}) {
  switch (kind) {
    case EncounterSourceKind.gameplayZone:
      for (final zone in map.gameplayZones) {
        final encounter = zone.encounter;
        if (zone.id == id &&
            zone.kind == GameplayZoneKind.encounter &&
            encounter != null) {
          return EncounterSource(
            kind: kind,
            id: zone.id,
            priority: zone.priority,
            encounter: encounter,
          );
        }
      }
      return null;
    case EncounterSourceKind.smartTileLayer:
      const prefix = 'smart_tile_layer:';
      if (!id.startsWith(prefix)) {
        return null;
      }
      final layerId = id.substring(prefix.length);
      for (final layer in map.layers.whereType<SmartTileLayer>()) {
        final behavior = layer.encounterBehavior;
        if (layer.id == layerId && behavior != null) {
          return EncounterSource(
            kind: kind,
            id: '$prefix${layer.id}',
            priority: behavior.priority,
            encounter: behavior.encounter,
          );
        }
      }
      return null;
  }
}

EncounterSourceResolution resolveEncounterSourceAtPosition(
  MapData map, {
  required GridPos position,
  required EncounterKind encounterKind,
}) {
  final eligible = <EncounterSource>[
    for (final zone in map.gameplayZones)
      if (zone.kind == GameplayZoneKind.encounter &&
          zone.encounter?.encounterKind == encounterKind &&
          _containsPosition(zone.area, position))
        EncounterSource(
          kind: EncounterSourceKind.gameplayZone,
          id: zone.id,
          priority: zone.priority,
          encounter: zone.encounter!,
        ),
    for (final layer in map.layers.whereType<SmartTileLayer>())
      if (_smartTileLayerContainsEncounter(
        map: map,
        layer: layer,
        position: position,
        encounterKind: encounterKind,
      ))
        EncounterSource(
          kind: EncounterSourceKind.smartTileLayer,
          id: 'smart_tile_layer:${layer.id}',
          priority: layer.encounterBehavior!.priority,
          encounter: layer.encounterBehavior!.encounter,
        ),
  ];
  if (eligible.isEmpty) {
    return const EncounterSourceResolution.noSource();
  }
  final highestPriority = eligible
      .map((source) => source.priority)
      .reduce((left, right) => left > right ? left : right);
  final highest = eligible
      .where((source) => source.priority == highestPriority)
      .toList(growable: false);
  if (highest.length == 1) {
    return EncounterSourceResolution.resolved(highest.single);
  }
  final encounter = highest.first.encounter;
  if (highest.every((source) => source.encounter == encounter)) {
    final canonical = highest.toList(growable: false)
      ..sort((left, right) => left.id.compareTo(right.id));
    return EncounterSourceResolution.resolved(canonical.first);
  }
  return EncounterSourceResolution.ambiguous(
    highest.map((source) => source.id),
  );
}

List<EncounterSourceAmbiguity> findEncounterSourceAmbiguities(MapData map) {
  final nativeLayers = map.layers
      .whereType<SmartTileLayer>()
      .where((layer) => layer.isVisible && layer.encounterBehavior != null)
      .toList(growable: false);
  final ambiguities = <EncounterSourceAmbiguity>[];
  for (final zone in map.gameplayZones) {
    final zoneEncounter = zone.encounter;
    if (zone.kind != GameplayZoneKind.encounter || zoneEncounter == null) {
      continue;
    }
    for (final layer in nativeLayers) {
      final behavior = layer.encounterBehavior!;
      if (zone.priority != behavior.priority ||
          zoneEncounter.encounterKind != behavior.encounter.encounterKind ||
          zoneEncounter == behavior.encounter) {
        continue;
      }
      final position = _firstSmartTileMaterialPositionInRect(
        map: map,
        layer: layer,
        materialId: behavior.materialId,
        rect: zone.area,
      );
      if (position != null) {
        ambiguities.add(
          EncounterSourceAmbiguity(
            encounterKind: zoneEncounter.encounterKind,
            priority: zone.priority,
            position: position,
            sourceIds: <String>[zone.id, 'smart_tile_layer:${layer.id}'],
          ),
        );
      }
    }
  }
  for (var leftIndex = 0; leftIndex < nativeLayers.length; leftIndex++) {
    final left = nativeLayers[leftIndex];
    final leftBehavior = left.encounterBehavior!;
    for (
      var rightIndex = leftIndex + 1;
      rightIndex < nativeLayers.length;
      rightIndex++
    ) {
      final right = nativeLayers[rightIndex];
      final rightBehavior = right.encounterBehavior!;
      if (leftBehavior.priority != rightBehavior.priority ||
          leftBehavior.encounter.encounterKind !=
              rightBehavior.encounter.encounterKind ||
          leftBehavior.encounter == rightBehavior.encounter) {
        continue;
      }
      final position = _firstSharedSmartTileMaterialPosition(
        map: map,
        left: left,
        leftMaterialId: leftBehavior.materialId,
        right: right,
        rightMaterialId: rightBehavior.materialId,
      );
      if (position != null) {
        ambiguities.add(
          EncounterSourceAmbiguity(
            encounterKind: leftBehavior.encounter.encounterKind,
            priority: leftBehavior.priority,
            position: position,
            sourceIds: <String>[
              'smart_tile_layer:${left.id}',
              'smart_tile_layer:${right.id}',
            ],
          ),
        );
      }
    }
  }
  return List<EncounterSourceAmbiguity>.unmodifiable(ambiguities);
}

GridPos? _firstSmartTileMaterialPositionInRect({
  required MapData map,
  required SmartTileLayer layer,
  required String materialId,
  required MapRect rect,
}) {
  final materialValue = layer.materialPalette.indexOf(materialId);
  if (materialValue <= 0) return null;
  final left = rect.pos.x < 0 ? 0 : rect.pos.x;
  final top = rect.pos.y < 0 ? 0 : rect.pos.y;
  final right = rect.pos.x + rect.size.width > map.size.width
      ? map.size.width
      : rect.pos.x + rect.size.width;
  final bottom = rect.pos.y + rect.size.height > map.size.height
      ? map.size.height
      : rect.pos.y + rect.size.height;
  final semanticCells = layer.field.semanticCells;
  for (var y = top; y < bottom; y++) {
    for (var x = left; x < right; x++) {
      final index = y * map.size.width + x;
      if (index < semanticCells.length &&
          semanticCells[index] == materialValue) {
        return GridPos(x: x, y: y);
      }
    }
  }
  return null;
}

GridPos? _firstSharedSmartTileMaterialPosition({
  required MapData map,
  required SmartTileLayer left,
  required String leftMaterialId,
  required SmartTileLayer right,
  required String rightMaterialId,
}) {
  final leftValue = left.materialPalette.indexOf(leftMaterialId);
  final rightValue = right.materialPalette.indexOf(rightMaterialId);
  if (leftValue <= 0 || rightValue <= 0) return null;
  final leftCells = left.field.semanticCells;
  final rightCells = right.field.semanticCells;
  final cellCount = map.size.width * map.size.height;
  final upperBound = cellCount < leftCells.length
      ? cellCount
      : leftCells.length;
  final sharedBound = upperBound < rightCells.length
      ? upperBound
      : rightCells.length;
  for (var index = 0; index < sharedBound; index++) {
    if (leftCells[index] == leftValue && rightCells[index] == rightValue) {
      return GridPos(x: index % map.size.width, y: index ~/ map.size.width);
    }
  }
  return null;
}

bool _smartTileLayerContainsEncounter({
  required MapData map,
  required SmartTileLayer layer,
  required GridPos position,
  required EncounterKind encounterKind,
}) {
  final behavior = layer.encounterBehavior;
  if (!layer.isVisible ||
      behavior == null ||
      behavior.encounter.encounterKind != encounterKind ||
      position.x < 0 ||
      position.y < 0 ||
      position.x >= map.size.width ||
      position.y >= map.size.height) {
    return false;
  }
  final materialValue = layer.materialPalette.indexOf(behavior.materialId);
  if (materialValue <= 0) {
    return false;
  }
  final cellIndex = position.y * map.size.width + position.x;
  final semanticCells = layer.field.semanticCells;
  return cellIndex < semanticCells.length &&
      semanticCells[cellIndex] == materialValue;
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
