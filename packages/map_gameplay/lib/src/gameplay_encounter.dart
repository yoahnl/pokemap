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
  noSource,
  ambiguousSource,
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
    required this.sourceId,
    required this.sourceKind,
    required this.tableId,
    required this.encounterKind,
    required this.speciesId,
    required this.level,
    required this.minLevel,
    required this.maxLevel,
    required this.weight,
    required this.playerPos,
    this.generationSeed = 0,
    this.pokemonOverrides,
  });

  final String mapId;
  final String sourceId;
  final EncounterSourceKind sourceKind;
  final String tableId;
  final EncounterKind encounterKind;
  final String speciesId;
  final int level;
  final int minLevel;
  final int maxLevel;
  final int weight;
  final GridPos playerPos;
  final int generationSeed;
  final ProjectEncounterPokemonOverrides? pokemonOverrides;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'mapId': mapId,
      'sourceId': sourceId,
      'sourceKind': sourceKind.name,
      'tableId': tableId,
      'encounterKind': encounterKind.name,
      'speciesId': speciesId,
      'level': level,
      'minLevel': minLevel,
      'maxLevel': maxLevel,
      'weight': weight,
      'playerPos': playerPos.toJson(),
      'generationSeed': generationSeed,
      'pokemonOverrides': pokemonOverrides?.toJson(),
    };
  }

  factory GameplayEncounter.fromJson(Map<String, dynamic> json) {
    final rawKind =
        (json['encounterKind'] as String?) ?? EncounterKind.walk.name;
    final parsedKind = EncounterKind.values.where((k) => k.name == rawKind);
    final rawSourceKind = json['sourceKind'] as String?;
    final parsedSourceKind = EncounterSourceKind.values.where(
      (kind) => kind.name == rawSourceKind,
    );
    if (parsedSourceKind.isEmpty) {
      throw FormatException(
        'GameplayEncounter requires a valid sourceKind',
        rawSourceKind,
      );
    }
    return GameplayEncounter(
      mapId: (json['mapId'] as String?) ?? '',
      sourceId: (json['sourceId'] as String?) ?? '',
      sourceKind: parsedSourceKind.first,
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
      generationSeed: (json['generationSeed'] as num?)?.toInt() ?? 0,
      pokemonOverrides: json['pokemonOverrides'] is Map
          ? ProjectEncounterPokemonOverrides.fromJson(
              (json['pokemonOverrides'] as Map).cast<String, dynamic>(),
            )
          : null,
    );
  }
}

class GameplayEncounterCheckResult {
  const GameplayEncounterCheckResult({
    required this.status,
    this.sourceId,
    this.sourceKind,
    this.tableId,
    this.encounterKind,
    this.roll,
    this.encounter,
    this.ambiguousSourceIds = const <String>[],
  });

  final GameplayEncounterCheckStatus status;
  final String? sourceId;
  final EncounterSourceKind? sourceKind;
  final String? tableId;
  final EncounterKind? encounterKind;
  final double? roll;
  final GameplayEncounter? encounter;
  final List<String> ambiguousSourceIds;

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
  final sourceResolution = resolveEncounterSourceAtPosition(
    world.map,
    position: position,
    encounterKind: encounterKind,
  );
  if (sourceResolution.status == EncounterSourceResolutionStatus.noSource) {
    return const GameplayEncounterCheckResult(
      status: GameplayEncounterCheckStatus.noSource,
    );
  }
  if (sourceResolution.status == EncounterSourceResolutionStatus.ambiguous) {
    return GameplayEncounterCheckResult(
      status: GameplayEncounterCheckStatus.ambiguousSource,
      encounterKind: encounterKind,
      ambiguousSourceIds: sourceResolution.ambiguousSourceIds,
    );
  }
  final source = sourceResolution.source!;

  final sourceEncounter = source.encounter;
  final tableId = sourceEncounter.encounterTableId?.trim();
  if (tableId == null || tableId.isEmpty) {
    return GameplayEncounterCheckResult(
      status: GameplayEncounterCheckStatus.noEncounterTableId,
      sourceId: source.id,
      sourceKind: source.kind,
      encounterKind: encounterKind,
    );
  }

  final table = _findEncounterTable(project.encounterTables, tableId);
  if (table == null) {
    return GameplayEncounterCheckResult(
      status: GameplayEncounterCheckStatus.encounterTableNotFound,
      sourceId: source.id,
      sourceKind: source.kind,
      tableId: tableId,
      encounterKind: encounterKind,
    );
  }

  if (table.encounterKind != encounterKind) {
    return GameplayEncounterCheckResult(
      status: GameplayEncounterCheckStatus.encounterKindMismatch,
      sourceId: source.id,
      sourceKind: source.kind,
      tableId: table.id,
      encounterKind: encounterKind,
    );
  }

  if (table.conditions.isNotEmpty && gameState == null) {
    return GameplayEncounterCheckResult(
      status: GameplayEncounterCheckStatus.conditionContextUnavailable,
      sourceId: source.id,
      sourceKind: source.kind,
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
          sourceId: source.id,
          sourceKind: source.kind,
          tableId: table.id,
          encounterKind: encounterKind,
        );
      }
    }
  }

  final entries = canonicalEncounterEntries(
    _validEncounterEntries(table.entries),
  );
  if (entries.isEmpty) {
    return GameplayEncounterCheckResult(
      status: GameplayEncounterCheckStatus.emptyEncounterTable,
      sourceId: source.id,
      sourceKind: source.kind,
      tableId: table.id,
      encounterKind: encounterKind,
    );
  }

  final rng = random ?? Random();
  final chancePerStep = policy.chancePerStep ?? table.chancePerStep;
  if (!chancePerStep.isFinite || chancePerStep < 0 || chancePerStep > 1) {
    return GameplayEncounterCheckResult(
      status: GameplayEncounterCheckStatus.invalidEncounterRate,
      sourceId: source.id,
      sourceKind: source.kind,
      tableId: table.id,
      encounterKind: encounterKind,
    );
  }
  final roll = rng.nextDouble();
  if (roll >= chancePerStep) {
    return GameplayEncounterCheckResult(
      status: GameplayEncounterCheckStatus.rollFailed,
      sourceId: source.id,
      sourceKind: source.kind,
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
    sourceId: source.id,
    sourceKind: source.kind,
    tableId: table.id,
    encounterKind: encounterKind,
    speciesId: selected.speciesId,
    level: level,
    minLevel: selected.minLevel,
    maxLevel: selected.maxLevel,
    weight: selected.weight,
    playerPos: GridPos(x: position.x, y: position.y),
    generationSeed: _stableWildGenerationSeed(
      mapId: world.map.id,
      sourceId: source.id,
      tableId: table.id,
      encounterKind: encounterKind,
      speciesId: selected.speciesId,
      level: level,
      playerPos: position,
      encounterRoll: roll,
    ),
    pokemonOverrides: selected.pokemonOverrides,
  );
  return GameplayEncounterCheckResult(
    status: GameplayEncounterCheckStatus.triggered,
    sourceId: source.id,
    sourceKind: source.kind,
    tableId: table.id,
    encounterKind: encounterKind,
    roll: roll,
    encounter: encounter,
  );
}

int _stableWildGenerationSeed({
  required String mapId,
  required String sourceId,
  required String tableId,
  required EncounterKind encounterKind,
  required String speciesId,
  required int level,
  required GridPos playerPos,
  required double encounterRoll,
}) {
  final value = <Object>[
    mapId,
    sourceId,
    tableId,
    encounterKind.name,
    speciesId,
    level,
    playerPos.x,
    playerPos.y,
    encounterRoll,
  ].join('|');
  var hash = 0x811c9dc5;
  for (final codeUnit in value.codeUnits) {
    hash ^= codeUnit;
    hash = (hash * 0x01000193) & 0xffffffff;
  }
  return hash;
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
