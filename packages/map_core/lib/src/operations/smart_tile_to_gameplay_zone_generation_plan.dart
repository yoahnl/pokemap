import '../exceptions/map_exceptions.dart';
import '../models/enums.dart';
import '../models/geometry.dart';
import '../models/map_data.dart';
import '../models/map_gameplay_zone_payloads.dart';
import '../models/smart_tile_gameplay_zone_provenance.dart';

enum SmartTileGameplayZoneGenerationStrategy {
  boundingBox,
  greedyRectangles,
}

enum SmartTileGameplayZoneGenerationDiagnosticSeverity {
  error,
  warning,
  info,
}

enum SmartTileGameplayZoneGenerationDiagnosticKind {
  emptySource,
  missingSmartTilePresetId,
  missingMaterialId,
  noGeneratedZone,
  extraCellsIncluded,
  tooManyRectangles,
  overlapsExistingGameplayZone,
  unsupportedBehavior,
  zoneIdCollisionResolved,
}

final class SmartTileGameplayZoneGenerationSource {
  SmartTileGameplayZoneGenerationSource({
    required String smartTileLayerId,
    required String smartTileLayerName,
    required String smartTilePresetId,
    required String materialId,
    required Iterable<GridPos> cells,
    this.mapSize,
  })  : smartTileLayerId = smartTileLayerId.trim(),
        smartTileLayerName = smartTileLayerName.trim(),
        smartTilePresetId = smartTilePresetId.trim(),
        materialId = materialId.trim(),
        cells = _normalizeCells(cells, mapSize: mapSize) {
    if (this.smartTileLayerId.isEmpty) {
      throw const ValidationException('smartTileLayerId cannot be empty');
    }
    if (this.smartTilePresetId.isEmpty) {
      throw const ValidationException('smartTilePresetId cannot be empty');
    }
    if (this.materialId.isEmpty) {
      throw const ValidationException('materialId cannot be empty');
    }
    if (this.cells.isEmpty) {
      throw const ValidationException(
        'Smart Tile generation source cannot be empty',
      );
    }
  }

  final String smartTileLayerId;
  final String smartTileLayerName;
  final String smartTilePresetId;
  final String materialId;
  final List<GridPos> cells;
  final GridSize? mapSize;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is SmartTileGameplayZoneGenerationSource &&
            other.smartTileLayerId == smartTileLayerId &&
            other.smartTileLayerName == smartTileLayerName &&
            other.smartTilePresetId == smartTilePresetId &&
            other.materialId == materialId &&
            other.mapSize == mapSize &&
            _listEquals(other.cells, cells);
  }

  @override
  int get hashCode => Object.hash(
        smartTileLayerId,
        smartTileLayerName,
        smartTilePresetId,
        materialId,
        mapSize,
        Object.hashAll(cells),
      );
}

final class SmartTileGameplayZoneBehaviorDraft {
  const SmartTileGameplayZoneBehaviorDraft.encounter(
    EncounterZonePayload this.encounter,
  )   : kind = GameplayZoneKind.encounter,
        movement = null,
        hazard = null,
        special = null;

  const SmartTileGameplayZoneBehaviorDraft.movement(
    MovementZonePayload this.movement,
  )   : kind = GameplayZoneKind.movement,
        encounter = null,
        hazard = null,
        special = null;

  const SmartTileGameplayZoneBehaviorDraft.hazard(
    HazardZonePayload this.hazard,
  )   : kind = GameplayZoneKind.hazard,
        encounter = null,
        movement = null,
        special = null;

  const SmartTileGameplayZoneBehaviorDraft.special(
    SpecialZonePayload this.special,
  )   : kind = GameplayZoneKind.special,
        encounter = null,
        movement = null,
        hazard = null;

  final GameplayZoneKind kind;
  final EncounterZonePayload? encounter;
  final MovementZonePayload? movement;
  final HazardZonePayload? hazard;
  final SpecialZonePayload? special;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is SmartTileGameplayZoneBehaviorDraft &&
            other.kind == kind &&
            other.encounter == encounter &&
            other.movement == movement &&
            other.hazard == hazard &&
            other.special == special;
  }

  @override
  int get hashCode => Object.hash(
        kind,
        encounter,
        movement,
        hazard,
        special,
      );
}

final class SmartTileGameplayZoneCoverageReport {
  const SmartTileGameplayZoneCoverageReport({
    required this.sourceCellCount,
    required this.coveredSourceCellCount,
    required this.missingSourceCellCount,
    required this.extraCellCount,
    required this.zoneCount,
  });

  final int sourceCellCount;
  final int coveredSourceCellCount;
  final int missingSourceCellCount;
  final int extraCellCount;
  final int zoneCount;

  bool get isExact =>
      missingSourceCellCount == 0 &&
      extraCellCount == 0 &&
      coveredSourceCellCount == sourceCellCount;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is SmartTileGameplayZoneCoverageReport &&
            other.sourceCellCount == sourceCellCount &&
            other.coveredSourceCellCount == coveredSourceCellCount &&
            other.missingSourceCellCount == missingSourceCellCount &&
            other.extraCellCount == extraCellCount &&
            other.zoneCount == zoneCount;
  }

  @override
  int get hashCode => Object.hash(
        sourceCellCount,
        coveredSourceCellCount,
        missingSourceCellCount,
        extraCellCount,
        zoneCount,
      );
}

final class SmartTileGameplayZoneGenerationDiagnostic {
  const SmartTileGameplayZoneGenerationDiagnostic({
    required this.severity,
    required this.kind,
    required this.message,
  });

  final SmartTileGameplayZoneGenerationDiagnosticSeverity severity;
  final SmartTileGameplayZoneGenerationDiagnosticKind kind;
  final String message;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is SmartTileGameplayZoneGenerationDiagnostic &&
            other.severity == severity &&
            other.kind == kind &&
            other.message == message;
  }

  @override
  int get hashCode => Object.hash(severity, kind, message);
}

final class SmartTileGameplayZoneGenerationPlan {
  SmartTileGameplayZoneGenerationPlan({
    required this.source,
    required this.behavior,
    required this.strategy,
    required Iterable<MapGameplayZone> generatedZones,
    required Iterable<MapRect> rectangles,
    required this.coverage,
    required Iterable<SmartTileGameplayZoneGenerationDiagnostic> diagnostics,
  })  : generatedZones = List<MapGameplayZone>.unmodifiable(generatedZones),
        rectangles = List<MapRect>.unmodifiable(rectangles),
        diagnostics =
            List<SmartTileGameplayZoneGenerationDiagnostic>.unmodifiable(
          diagnostics,
        );

  final SmartTileGameplayZoneGenerationSource source;
  final SmartTileGameplayZoneBehaviorDraft behavior;
  final SmartTileGameplayZoneGenerationStrategy strategy;
  final List<MapGameplayZone> generatedZones;
  final List<MapRect> rectangles;
  final SmartTileGameplayZoneCoverageReport coverage;
  final List<SmartTileGameplayZoneGenerationDiagnostic> diagnostics;

  bool get hasBlockingDiagnostics => diagnostics.any(
        (diagnostic) =>
            diagnostic.severity ==
            SmartTileGameplayZoneGenerationDiagnosticSeverity.error,
      );

  bool get hasWarnings => diagnostics.any(
        (diagnostic) =>
            diagnostic.severity ==
            SmartTileGameplayZoneGenerationDiagnosticSeverity.warning,
      );

  bool get isExactCoverage => coverage.isExact;

  int get zoneCount => generatedZones.length;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is SmartTileGameplayZoneGenerationPlan &&
            other.source == source &&
            other.behavior == behavior &&
            other.strategy == strategy &&
            _listEquals(other.generatedZones, generatedZones) &&
            _listEquals(other.rectangles, rectangles) &&
            other.coverage == coverage &&
            _listEquals(other.diagnostics, diagnostics);
  }

  @override
  int get hashCode => Object.hash(
        source,
        behavior,
        strategy,
        Object.hashAll(generatedZones),
        Object.hashAll(rectangles),
        coverage,
        Object.hashAll(diagnostics),
      );
}

SmartTileGameplayZoneGenerationPlan createSmartTileGameplayZoneGenerationPlan({
  required SmartTileGameplayZoneGenerationSource source,
  required SmartTileGameplayZoneBehaviorDraft behavior,
  required SmartTileGameplayZoneGenerationStrategy strategy,
  required String zoneIdPrefix,
  required String zoneNamePrefix,
  int priority = 0,
  List<MapGameplayZone> existingZones = const [],
  int maxRectanglesWarningThreshold = 8,
}) {
  final provenance = SmartTileGameplayZoneProvenance(
    smartTileLayerId: source.smartTileLayerId,
    smartTilePresetId: source.smartTilePresetId,
    materialId: source.materialId,
    behaviorKey: _behaviorKey(behavior),
  );
  final unmanagedExistingZones = existingZones
      .where(
        (zone) =>
            !(zone.smartTileProvenance?.hasSameBinding(provenance) ?? false),
      )
      .toList(growable: false);
  final rectangles = switch (strategy) {
    SmartTileGameplayZoneGenerationStrategy.boundingBox => [
        _boundingBox(source.cells),
      ],
    SmartTileGameplayZoneGenerationStrategy.greedyRectangles =>
      _greedyRectangles(source.cells),
  };

  final diagnostics = <SmartTileGameplayZoneGenerationDiagnostic>[];
  final coverage = _buildCoverage(source.cells, rectangles);
  if (rectangles.isEmpty) {
    diagnostics.add(
      const SmartTileGameplayZoneGenerationDiagnostic(
        severity: SmartTileGameplayZoneGenerationDiagnosticSeverity.error,
        kind: SmartTileGameplayZoneGenerationDiagnosticKind.noGeneratedZone,
        message: 'No gameplay zone could be generated from this Smart Tile.',
      ),
    );
  }
  if (coverage.extraCellCount > 0) {
    diagnostics.add(
      SmartTileGameplayZoneGenerationDiagnostic(
        severity: SmartTileGameplayZoneGenerationDiagnosticSeverity.warning,
        kind: SmartTileGameplayZoneGenerationDiagnosticKind.extraCellsIncluded,
        message:
            '${coverage.extraCellCount} extra ${_pluralize('cell', coverage.extraCellCount)} '
            'will be included by generated rectangles.',
      ),
    );
  }
  if (rectangles.length > maxRectanglesWarningThreshold) {
    diagnostics.add(
      SmartTileGameplayZoneGenerationDiagnostic(
        severity: SmartTileGameplayZoneGenerationDiagnosticSeverity.warning,
        kind: SmartTileGameplayZoneGenerationDiagnosticKind.tooManyRectangles,
        message: '${rectangles.length} rectangles will be generated, above the '
            'recommended threshold of $maxRectanglesWarningThreshold.',
      ),
    );
  }
  for (final rectangle in rectangles) {
    for (final existingZone in unmanagedExistingZones) {
      if (_rectsOverlap(rectangle, existingZone.area)) {
        diagnostics.add(
          SmartTileGameplayZoneGenerationDiagnostic(
            severity: SmartTileGameplayZoneGenerationDiagnosticSeverity.warning,
            kind: SmartTileGameplayZoneGenerationDiagnosticKind
                .overlapsExistingGameplayZone,
            message:
                'Generated rectangle overlaps existing gameplay zone ${existingZone.id}.',
          ),
        );
        break;
      }
    }
  }

  final usedIds = <String>{for (final zone in unmanagedExistingZones) zone.id};
  final zones = <MapGameplayZone>[];
  for (var i = 0; i < rectangles.length; i++) {
    final baseId = _baseZoneId(
      zoneIdPrefix: zoneIdPrefix,
      fallback: source.smartTilePresetId,
      index: i,
      count: rectangles.length,
    );
    final id = _nextAvailableId(baseId, usedIds);
    if (id != baseId) {
      diagnostics.add(
        SmartTileGameplayZoneGenerationDiagnostic(
          severity: SmartTileGameplayZoneGenerationDiagnosticSeverity.info,
          kind: SmartTileGameplayZoneGenerationDiagnosticKind
              .zoneIdCollisionResolved,
          message: 'Generated zone id $baseId was already used; using $id.',
        ),
      );
    }
    usedIds.add(id);
    zones.add(
      _zoneFromDraft(
        id: id,
        name: _zoneName(
          zoneNamePrefix: zoneNamePrefix,
          fallback: source.smartTileLayerName.isEmpty
              ? source.smartTilePresetId
              : source.smartTileLayerName,
          index: i,
          count: rectangles.length,
        ),
        area: rectangles[i],
        priority: priority,
        behavior: behavior,
        provenance: provenance,
      ),
    );
  }

  return SmartTileGameplayZoneGenerationPlan(
    source: source,
    behavior: behavior,
    strategy: strategy,
    generatedZones: zones,
    rectangles: rectangles,
    coverage: coverage,
    diagnostics: diagnostics,
  );
}

List<GridPos> _normalizeCells(
  Iterable<GridPos> cells, {
  GridSize? mapSize,
}) {
  final unique = <GridPos>{};
  for (final cell in cells) {
    if (cell.x < 0 || cell.y < 0) {
      throw ValidationException(
        'Smart Tile generation cell is out of bounds: (${cell.x}, ${cell.y})',
      );
    }
    if (mapSize != null &&
        (cell.x >= mapSize.width || cell.y >= mapSize.height)) {
      throw ValidationException(
        'Smart Tile generation cell is out of bounds: (${cell.x}, ${cell.y})',
      );
    }
    unique.add(cell);
  }
  final sorted = unique.toList(growable: false)..sort(_compareGridPosByYThenX);
  return List<GridPos>.unmodifiable(sorted);
}

MapRect _boundingBox(List<GridPos> cells) {
  var minX = cells.first.x;
  var maxX = cells.first.x;
  var minY = cells.first.y;
  var maxY = cells.first.y;
  for (final cell in cells.skip(1)) {
    if (cell.x < minX) minX = cell.x;
    if (cell.x > maxX) maxX = cell.x;
    if (cell.y < minY) minY = cell.y;
    if (cell.y > maxY) maxY = cell.y;
  }
  return MapRect(
    pos: GridPos(x: minX, y: minY),
    size: GridSize(
      width: maxX - minX + 1,
      height: maxY - minY + 1,
    ),
  );
}

List<MapRect> _greedyRectangles(List<GridPos> cells) {
  final remaining = Set<GridPos>.from(cells);
  final rectangles = <MapRect>[];

  while (remaining.isNotEmpty) {
    final start = remaining.reduce(
      (best, cell) => _compareGridPosByYThenX(cell, best) < 0 ? cell : best,
    );
    var width = 1;
    while (remaining.contains(GridPos(x: start.x + width, y: start.y))) {
      width++;
    }

    var height = 1;
    var canExtend = true;
    while (canExtend) {
      final nextY = start.y + height;
      for (var dx = 0; dx < width; dx++) {
        if (!remaining.contains(GridPos(x: start.x + dx, y: nextY))) {
          canExtend = false;
          break;
        }
      }
      if (canExtend) height++;
    }

    for (var dy = 0; dy < height; dy++) {
      for (var dx = 0; dx < width; dx++) {
        remaining.remove(GridPos(x: start.x + dx, y: start.y + dy));
      }
    }
    rectangles.add(
      MapRect(
        pos: start,
        size: GridSize(width: width, height: height),
      ),
    );
  }

  return List<MapRect>.unmodifiable(rectangles);
}

SmartTileGameplayZoneCoverageReport _buildCoverage(
  List<GridPos> sourceCells,
  List<MapRect> rectangles,
) {
  final sourceSet = Set<GridPos>.from(sourceCells);
  final coveredCells = <GridPos>{};
  for (final rect in rectangles) {
    for (var y = rect.pos.y; y < rect.pos.y + rect.size.height; y++) {
      for (var x = rect.pos.x; x < rect.pos.x + rect.size.width; x++) {
        coveredCells.add(GridPos(x: x, y: y));
      }
    }
  }
  final coveredSourceCellCount = sourceSet.where(coveredCells.contains).length;
  final missingSourceCellCount =
      sourceSet.where((cell) => !coveredCells.contains(cell)).length;
  final extraCellCount =
      coveredCells.where((cell) => !sourceSet.contains(cell)).length;

  return SmartTileGameplayZoneCoverageReport(
    sourceCellCount: sourceSet.length,
    coveredSourceCellCount: coveredSourceCellCount,
    missingSourceCellCount: missingSourceCellCount,
    extraCellCount: extraCellCount,
    zoneCount: rectangles.length,
  );
}

MapGameplayZone _zoneFromDraft({
  required String id,
  required String name,
  required MapRect area,
  required int priority,
  required SmartTileGameplayZoneBehaviorDraft behavior,
  required SmartTileGameplayZoneProvenance provenance,
}) {
  return MapGameplayZone(
    id: id,
    name: name,
    kind: behavior.kind,
    area: area,
    priority: priority,
    encounter: behavior.encounter,
    movement: behavior.movement,
    hazard: behavior.hazard,
    special: behavior.special,
    smartTileProvenance: provenance,
  );
}

String _behaviorKey(SmartTileGameplayZoneBehaviorDraft behavior) {
  return switch (behavior.kind) {
    GameplayZoneKind.encounter =>
      'encounter.${behavior.encounter?.encounterKind.name ?? 'walk'}',
    GameplayZoneKind.movement =>
      'movement.${behavior.movement?.requiredMode.name ?? 'walk'}',
    GameplayZoneKind.hazard =>
      'hazard.${behavior.hazard?.hazardKind.name ?? 'other'}',
    GameplayZoneKind.special => 'special',
    GameplayZoneKind.movementEffect || GameplayZoneKind.custom =>
      throw const ValidationException(
        'Unsupported Smart Tile gameplay-zone behavior',
      ),
  };
}

String _baseZoneId({
  required String zoneIdPrefix,
  required String fallback,
  required int index,
  required int count,
}) {
  final prefix = _normalizeIdPrefix(
      zoneIdPrefix.trim().isEmpty ? fallback : zoneIdPrefix.trim());
  if (count == 1) return prefix;
  return '$prefix-${index + 1}';
}

String _normalizeIdPrefix(String value) {
  final normalized = value.trim().replaceAll(RegExp(r'\s+'), '-');
  if (normalized.isEmpty) return 'smart-tile-zone';
  return normalized;
}

String _nextAvailableId(String baseId, Set<String> usedIds) {
  if (!usedIds.contains(baseId)) return baseId;
  var suffix = 1;
  while (usedIds.contains('$baseId-$suffix')) {
    suffix++;
  }
  return '$baseId-$suffix';
}

String _zoneName({
  required String zoneNamePrefix,
  required String fallback,
  required int index,
  required int count,
}) {
  final prefix =
      zoneNamePrefix.trim().isEmpty ? fallback : zoneNamePrefix.trim();
  if (count == 1) return prefix;
  return '$prefix ${index + 1}';
}

bool _rectsOverlap(MapRect a, MapRect b) {
  return a.pos.x < b.pos.x + b.size.width &&
      a.pos.x + a.size.width > b.pos.x &&
      a.pos.y < b.pos.y + b.size.height &&
      a.pos.y + a.size.height > b.pos.y;
}

int _compareGridPosByYThenX(GridPos a, GridPos b) {
  final byY = a.y.compareTo(b.y);
  if (byY != 0) return byY;
  return a.x.compareTo(b.x);
}

String _pluralize(String singular, int count) {
  if (count == 1) return singular;
  return '${singular}s';
}

bool _listEquals<T>(List<T> a, List<T> b) {
  if (identical(a, b)) return true;
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}
