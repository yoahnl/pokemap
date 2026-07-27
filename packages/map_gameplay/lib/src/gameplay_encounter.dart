import 'dart:math';

import 'package:map_core/map_core.dart' hide defaultEncounterChancePerStep;
import 'package:map_core/map_core.dart' as core
    show defaultEncounterChancePerStep;

import 'gameplay_world_state.dart';
import 'script_condition_evaluator.dart';

/// Backward-compatible gameplay export for the authored model default.
const double defaultEncounterChancePerStep = core.defaultEncounterChancePerStep;

class GameplayEncounterPolicy {
  const GameplayEncounterPolicy({
    this.chancePerStep,
  }) : assert(
          chancePerStep == null || (chancePerStep >= 0 && chancePerStep <= 1),
        );

  /// Explicit override reserved for deterministic tests and host tooling.
  ///
  /// Production callers leave this null so the authored table rate is used.
  final double? chancePerStep;
}

enum GameplayEncounterCheckStatus {
  noZone,
  noEncounterTableId,
  encounterTableNotFound,
  encounterKindMismatch,
  conditionContextUnavailable,
  conditionsNotMet,
  invalidEncounterRate,
  emptyEncounterTable,
  rollFailed,
  triggered,
}

class GameplayEncounter {
  const GameplayEncounter({
    required this.mapId,
    required this.zoneId,
    required this.tableId,
    required this.encounterKind,
    required this.speciesId,
    required this.level,
    required this.minLevel,
    required this.maxLevel,
    required this.weight,
    required this.playerPos,
  });

  final String mapId;
  final String zoneId;
  final String tableId;
  final EncounterKind encounterKind;
  final String speciesId;
  final int level;
  final int minLevel;
  final int maxLevel;
  final int weight;
  final GridPos playerPos;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'mapId': mapId,
      'zoneId': zoneId,
      'tableId': tableId,
      'encounterKind': encounterKind.name,
      'speciesId': speciesId,
      'level': level,
      'minLevel': minLevel,
      'maxLevel': maxLevel,
      'weight': weight,
      'playerPos': playerPos.toJson(),
    };
  }

  factory GameplayEncounter.fromJson(Map<String, dynamic> json) {
    final rawKind =
        (json['encounterKind'] as String?) ?? EncounterKind.walk.name;
    final parsedKind = EncounterKind.values.where((k) => k.name == rawKind);
    return GameplayEncounter(
      mapId: (json['mapId'] as String?) ?? '',
      zoneId: (json['zoneId'] as String?) ?? '',
      tableId: (json['tableId'] as String?) ?? '',
      encounterKind: parsedKind.isEmpty ? EncounterKind.walk : parsedKind.first,
      speciesId: (json['speciesId'] as String?) ?? '',
      level: (json['level'] as num?)?.toInt() ?? 1,
      minLevel: (json['minLevel'] as num?)?.toInt() ?? 1,
      maxLevel: (json['maxLevel'] as num?)?.toInt() ?? 1,
      weight: (json['weight'] as num?)?.toInt() ?? 1,
      playerPos: json['playerPos'] is Map<String, dynamic>
          ? GridPos.fromJson(json['playerPos'] as Map<String, dynamic>)
          : const GridPos(x: 0, y: 0),
    );
  }
}

class GameplayEncounterCheckResult {
  const GameplayEncounterCheckResult({
    required this.status,
    this.zoneId,
    this.tableId,
    this.encounterKind,
    this.roll,
    this.encounter,
  });

  final GameplayEncounterCheckStatus status;
  final String? zoneId;
  final String? tableId;
  final EncounterKind? encounterKind;
  final double? roll;
  final GameplayEncounter? encounter;

  bool get triggered =>
      status == GameplayEncounterCheckStatus.triggered && encounter != null;
}

GameplayEncounterCheckResult checkEncounterAtPlayerPosition({
  required GameplayWorldState world,
  required ProjectManifest project,
  required EncounterKind encounterKind,
  GameState? gameState,
  ScriptEvaluationContext? conditionContext,
  Random? random,
  GameplayEncounterPolicy policy = const GameplayEncounterPolicy(),
}) {
  final position = world.player.pos;
  final zone = _resolveEncounterZone(
    world.map.gameplayZones,
    position: position,
    encounterKind: encounterKind,
  );
  if (zone == null) {
    return const GameplayEncounterCheckResult(
      status: GameplayEncounterCheckStatus.noZone,
    );
  }

  final zoneEncounter = zone.encounter;
  if (zoneEncounter == null) {
    return GameplayEncounterCheckResult(
      status: GameplayEncounterCheckStatus.noEncounterTableId,
      zoneId: zone.id,
      encounterKind: encounterKind,
    );
  }

  final tableId = zoneEncounter.encounterTableId?.trim();
  if (tableId == null || tableId.isEmpty) {
    return GameplayEncounterCheckResult(
      status: GameplayEncounterCheckStatus.noEncounterTableId,
      zoneId: zone.id,
      encounterKind: encounterKind,
    );
  }

  final table = _findEncounterTable(project.encounterTables, tableId);
  if (table == null) {
    return GameplayEncounterCheckResult(
      status: GameplayEncounterCheckStatus.encounterTableNotFound,
      zoneId: zone.id,
      tableId: tableId,
      encounterKind: encounterKind,
    );
  }

  if (table.encounterKind != encounterKind) {
    return GameplayEncounterCheckResult(
      status: GameplayEncounterCheckStatus.encounterKindMismatch,
      zoneId: zone.id,
      tableId: table.id,
      encounterKind: encounterKind,
    );
  }

  if (table.conditions.isNotEmpty && gameState == null) {
    return GameplayEncounterCheckResult(
      status: GameplayEncounterCheckStatus.conditionContextUnavailable,
      zoneId: zone.id,
      tableId: table.id,
      encounterKind: encounterKind,
    );
  }
  if (gameState != null) {
    const evaluator = ScriptConditionEvaluator();
    for (final condition in table.conditions) {
      if (!evaluator.evaluate(
        condition,
        gameState,
        context: conditionContext,
      )) {
        return GameplayEncounterCheckResult(
          status: GameplayEncounterCheckStatus.conditionsNotMet,
          zoneId: zone.id,
          tableId: table.id,
          encounterKind: encounterKind,
        );
      }
    }
  }

  final entries = _validEncounterEntries(table.entries);
  if (entries.isEmpty) {
    return GameplayEncounterCheckResult(
      status: GameplayEncounterCheckStatus.emptyEncounterTable,
      zoneId: zone.id,
      tableId: table.id,
      encounterKind: encounterKind,
    );
  }

  final rng = random ?? Random();
  final chancePerStep = policy.chancePerStep ?? table.chancePerStep;
  if (chancePerStep < 0 || chancePerStep > 1) {
    return GameplayEncounterCheckResult(
      status: GameplayEncounterCheckStatus.invalidEncounterRate,
      zoneId: zone.id,
      tableId: table.id,
      encounterKind: encounterKind,
    );
  }
  final roll = rng.nextDouble();
  if (roll >= chancePerStep) {
    return GameplayEncounterCheckResult(
      status: GameplayEncounterCheckStatus.rollFailed,
      zoneId: zone.id,
      tableId: table.id,
      encounterKind: encounterKind,
      roll: roll,
    );
  }

  final selected = _pickWeightedEncounterEntry(entries, rng);
  final levelRange = selected.maxLevel - selected.minLevel + 1;
  final level = selected.minLevel + rng.nextInt(levelRange);
  final encounter = GameplayEncounter(
    mapId: world.map.id,
    zoneId: zone.id,
    tableId: table.id,
    encounterKind: encounterKind,
    speciesId: selected.speciesId,
    level: level,
    minLevel: selected.minLevel,
    maxLevel: selected.maxLevel,
    weight: selected.weight,
    playerPos: GridPos(x: position.x, y: position.y),
  );
  return GameplayEncounterCheckResult(
    status: GameplayEncounterCheckStatus.triggered,
    zoneId: zone.id,
    tableId: table.id,
    encounterKind: encounterKind,
    roll: roll,
    encounter: encounter,
  );
}

MapGameplayZone? _resolveEncounterZone(
  List<MapGameplayZone> zones, {
  required GridPos position,
  required EncounterKind encounterKind,
}) {
  MapGameplayZone? best;
  for (final zone in zones) {
    if (zone.kind != GameplayZoneKind.encounter) continue;
    final payload = zone.encounter;
    if (payload == null) continue;
    if (payload.encounterKind != encounterKind) continue;
    if (!_containsPosition(zone.area, position)) continue;
    if (best == null || zone.priority > best.priority) {
      best = zone;
    }
  }
  return best;
}

bool _containsPosition(MapRect area, GridPos pos) {
  final x0 = area.pos.x;
  final y0 = area.pos.y;
  final x1 = x0 + area.size.width;
  final y1 = y0 + area.size.height;
  return pos.x >= x0 && pos.x < x1 && pos.y >= y0 && pos.y < y1;
}

ProjectEncounterTable? _findEncounterTable(
  List<ProjectEncounterTable> tables,
  String id,
) {
  for (final table in tables) {
    if (table.id == id) {
      return table;
    }
  }
  return null;
}

List<ProjectEncounterEntry> _validEncounterEntries(
  List<ProjectEncounterEntry> entries,
) {
  return entries
      .where((entry) => entry.speciesId.trim().isNotEmpty)
      .where((entry) => entry.weight > 0)
      .where((entry) => entry.minLevel > 0 && entry.maxLevel > 0)
      .where((entry) => entry.minLevel <= entry.maxLevel)
      .toList(growable: false);
}

ProjectEncounterEntry _pickWeightedEncounterEntry(
  List<ProjectEncounterEntry> entries,
  Random random,
) {
  var totalWeight = 0;
  for (final entry in entries) {
    totalWeight += entry.weight;
  }
  if (totalWeight <= 0) {
    return entries.first;
  }
  var pick = random.nextInt(totalWeight);
  for (final entry in entries) {
    if (pick < entry.weight) {
      return entry;
    }
    pick -= entry.weight;
  }
  return entries.last;
}
