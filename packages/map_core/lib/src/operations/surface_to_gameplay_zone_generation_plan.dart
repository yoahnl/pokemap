import '../exceptions/map_exceptions.dart';
import '../models/enums.dart';
import '../models/geometry.dart';
import '../models/map_data.dart';
import '../models/map_gameplay_zone_payloads.dart';

enum SurfaceGameplayZoneGenerationStrategy {
  boundingBox,
  greedyRectangles,
}

enum SurfaceGameplayZoneGenerationDiagnosticSeverity {
  error,
  warning,
  info,
}

enum SurfaceGameplayZoneGenerationDiagnosticKind {
  emptySource,
  missingSurfacePresetId,
  noGeneratedZone,
  extraCellsIncluded,
  tooManyRectangles,
  overlapsExistingGameplayZone,
  unsupportedBehavior,
  zoneIdCollisionResolved,
}

final class SurfaceGameplayZoneGenerationSource {
  SurfaceGameplayZoneGenerationSource({
    required String surfaceLayerId,
    required String surfaceLayerName,
    required String surfacePresetId,
    required Iterable<GridPos> cells,
    this.mapSize,
  })  : surfaceLayerId = surfaceLayerId.trim(),
        surfaceLayerName = surfaceLayerName.trim(),
        surfacePresetId = surfacePresetId.trim(),
        cells = _normalizeCells(cells, mapSize: mapSize) {
    if (this.surfacePresetId.isEmpty) {
      throw const ValidationException('surfacePresetId cannot be empty');
    }
    if (this.cells.isEmpty) {
      throw const ValidationException(
          'surface generation source cannot be empty');
    }
  }

  final String surfaceLayerId;
  final String surfaceLayerName;
  final String surfacePresetId;
  final List<GridPos> cells;
  final GridSize? mapSize;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is SurfaceGameplayZoneGenerationSource &&
            other.surfaceLayerId == surfaceLayerId &&
            other.surfaceLayerName == surfaceLayerName &&
            other.surfacePresetId == surfacePresetId &&
            other.mapSize == mapSize &&
            _listEquals(other.cells, cells);
  }

  @override
  int get hashCode => Object.hash(
        surfaceLayerId,
        surfaceLayerName,
        surfacePresetId,
        mapSize,
        Object.hashAll(cells),
      );
}

final class SurfaceGameplayZoneBehaviorDraft {
  const SurfaceGameplayZoneBehaviorDraft.encounter(
    EncounterZonePayload this.encounter,
  )   : kind = GameplayZoneKind.encounter,
        movement = null,
        hazard = null,
        special = null;

  const SurfaceGameplayZoneBehaviorDraft.movement(
    MovementZonePayload this.movement,
  )   : kind = GameplayZoneKind.movement,
        encounter = null,
        hazard = null,
        special = null;

  const SurfaceGameplayZoneBehaviorDraft.hazard(
    HazardZonePayload this.hazard,
  )   : kind = GameplayZoneKind.hazard,
        encounter = null,
        movement = null,
        special = null;

  const SurfaceGameplayZoneBehaviorDraft.special(
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
        other is SurfaceGameplayZoneBehaviorDraft &&
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

final class SurfaceGameplayZoneCoverageReport {
  const SurfaceGameplayZoneCoverageReport({
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
        other is SurfaceGameplayZoneCoverageReport &&
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

final class SurfaceGameplayZoneGenerationDiagnostic {
  const SurfaceGameplayZoneGenerationDiagnostic({
    required this.severity,
    required this.kind,
    required this.message,
  });

  final SurfaceGameplayZoneGenerationDiagnosticSeverity severity;
  final SurfaceGameplayZoneGenerationDiagnosticKind kind;
  final String message;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is SurfaceGameplayZoneGenerationDiagnostic &&
            other.severity == severity &&
            other.kind == kind &&
            other.message == message;
  }

  @override
  int get hashCode => Object.hash(severity, kind, message);
}

final class SurfaceGameplayZoneGenerationPlan {
  SurfaceGameplayZoneGenerationPlan({
    required this.source,
    required this.behavior,
    required this.strategy,
    required Iterable<MapGameplayZone> generatedZones,
    required Iterable<MapRect> rectangles,
    required this.coverage,
    required Iterable<SurfaceGameplayZoneGenerationDiagnostic> diagnostics,
  })  : generatedZones = List<MapGameplayZone>.unmodifiable(generatedZones),
        rectangles = List<MapRect>.unmodifiable(rectangles),
        diagnostics =
            List<SurfaceGameplayZoneGenerationDiagnostic>.unmodifiable(
          diagnostics,
        );

  final SurfaceGameplayZoneGenerationSource source;
  final SurfaceGameplayZoneBehaviorDraft behavior;
  final SurfaceGameplayZoneGenerationStrategy strategy;
  final List<MapGameplayZone> generatedZones;
  final List<MapRect> rectangles;
  final SurfaceGameplayZoneCoverageReport coverage;
  final List<SurfaceGameplayZoneGenerationDiagnostic> diagnostics;

  bool get hasBlockingDiagnostics => diagnostics.any(
        (diagnostic) =>
            diagnostic.severity ==
            SurfaceGameplayZoneGenerationDiagnosticSeverity.error,
      );

  bool get hasWarnings => diagnostics.any(
        (diagnostic) =>
            diagnostic.severity ==
            SurfaceGameplayZoneGenerationDiagnosticSeverity.warning,
      );

  bool get isExactCoverage => coverage.isExact;

  int get zoneCount => generatedZones.length;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is SurfaceGameplayZoneGenerationPlan &&
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

SurfaceGameplayZoneGenerationPlan createSurfaceGameplayZoneGenerationPlan({
  required SurfaceGameplayZoneGenerationSource source,
  required SurfaceGameplayZoneBehaviorDraft behavior,
  required SurfaceGameplayZoneGenerationStrategy strategy,
  required String zoneIdPrefix,
  required String zoneNamePrefix,
  int priority = 0,
  List<MapGameplayZone> existingZones = const [],
  int maxRectanglesWarningThreshold = 8,
}) {
  final rectangles = switch (strategy) {
    SurfaceGameplayZoneGenerationStrategy.boundingBox => [
        _boundingBox(source.cells),
      ],
    SurfaceGameplayZoneGenerationStrategy.greedyRectangles =>
      _greedyRectangles(source.cells),
  };

  final diagnostics = <SurfaceGameplayZoneGenerationDiagnostic>[];
  final coverage = _buildCoverage(source.cells, rectangles);
  if (rectangles.isEmpty) {
    diagnostics.add(
      const SurfaceGameplayZoneGenerationDiagnostic(
        severity: SurfaceGameplayZoneGenerationDiagnosticSeverity.error,
        kind: SurfaceGameplayZoneGenerationDiagnosticKind.noGeneratedZone,
        message: 'No gameplay zone could be generated from this surface.',
      ),
    );
  }
  if (coverage.extraCellCount > 0) {
    diagnostics.add(
      SurfaceGameplayZoneGenerationDiagnostic(
        severity: SurfaceGameplayZoneGenerationDiagnosticSeverity.warning,
        kind: SurfaceGameplayZoneGenerationDiagnosticKind.extraCellsIncluded,
        message:
            '${coverage.extraCellCount} extra ${_pluralize('cell', coverage.extraCellCount)} '
            'will be included by generated rectangles.',
      ),
    );
  }
  if (rectangles.length > maxRectanglesWarningThreshold) {
    diagnostics.add(
      SurfaceGameplayZoneGenerationDiagnostic(
        severity: SurfaceGameplayZoneGenerationDiagnosticSeverity.warning,
        kind: SurfaceGameplayZoneGenerationDiagnosticKind.tooManyRectangles,
        message: '${rectangles.length} rectangles will be generated, above the '
            'recommended threshold of $maxRectanglesWarningThreshold.',
      ),
    );
  }
  for (final rectangle in rectangles) {
    for (final existingZone in existingZones) {
      if (_rectsOverlap(rectangle, existingZone.area)) {
        diagnostics.add(
          SurfaceGameplayZoneGenerationDiagnostic(
            severity: SurfaceGameplayZoneGenerationDiagnosticSeverity.warning,
            kind: SurfaceGameplayZoneGenerationDiagnosticKind
                .overlapsExistingGameplayZone,
            message:
                'Generated rectangle overlaps existing gameplay zone ${existingZone.id}.',
          ),
        );
        break;
      }
    }
  }

  final usedIds = <String>{for (final zone in existingZones) zone.id};
  final zones = <MapGameplayZone>[];
  for (var i = 0; i < rectangles.length; i++) {
    final baseId = _baseZoneId(
      zoneIdPrefix: zoneIdPrefix,
      fallback: source.surfacePresetId,
      index: i,
      count: rectangles.length,
    );
    final id = _nextAvailableId(baseId, usedIds);
    if (id != baseId) {
      diagnostics.add(
        SurfaceGameplayZoneGenerationDiagnostic(
          severity: SurfaceGameplayZoneGenerationDiagnosticSeverity.info,
          kind: SurfaceGameplayZoneGenerationDiagnosticKind
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
          fallback: source.surfaceLayerName.isEmpty
              ? source.surfacePresetId
              : source.surfaceLayerName,
          index: i,
          count: rectangles.length,
        ),
        area: rectangles[i],
        priority: priority,
        behavior: behavior,
      ),
    );
  }

  return SurfaceGameplayZoneGenerationPlan(
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
        'surface generation cell is out of bounds: (${cell.x}, ${cell.y})',
      );
    }
    if (mapSize != null &&
        (cell.x >= mapSize.width || cell.y >= mapSize.height)) {
      throw ValidationException(
        'surface generation cell is out of bounds: (${cell.x}, ${cell.y})',
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

SurfaceGameplayZoneCoverageReport _buildCoverage(
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

  return SurfaceGameplayZoneCoverageReport(
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
  required SurfaceGameplayZoneBehaviorDraft behavior,
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
  );
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
  if (normalized.isEmpty) return 'surface-zone';
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
