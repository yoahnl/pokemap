import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';

enum RuntimeBattleKind {
  wild,
  trainer,
}

enum RuntimeBattleSourceKind {
  encounterZone,
  trainerInteraction,
  script,
}

class OverworldReturnContext {
  const OverworldReturnContext({
    required this.mapId,
    required this.playerPos,
    required this.playerFacing,
  });

  final String mapId;
  final GridPos playerPos;
  final Direction playerFacing;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'mapId': mapId,
      'playerPos': playerPos.toJson(),
      'playerFacing': playerFacing.name,
    };
  }
}

sealed class BattleStartRequest {
  const BattleStartRequest({
    required this.requestId,
    required this.createdAtEpochMs,
    required this.kind,
    required this.source,
    required this.returnContext,
  });

  final String requestId;
  final int createdAtEpochMs;
  final RuntimeBattleKind kind;
  final RuntimeBattleSourceKind source;
  final OverworldReturnContext returnContext;

  Map<String, dynamic> toJson();
}

class WildBattleStartRequest extends BattleStartRequest {
  const WildBattleStartRequest({
    required super.requestId,
    required super.createdAtEpochMs,
    required super.returnContext,
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
  }) : super(
          kind: RuntimeBattleKind.wild,
          source: RuntimeBattleSourceKind.encounterZone,
        );

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

  @override
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'requestId': requestId,
      'createdAtEpochMs': createdAtEpochMs,
      'kind': kind.name,
      'source': source.name,
      'returnContext': returnContext.toJson(),
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
}

class TrainerBattleStartRequest extends BattleStartRequest {
  const TrainerBattleStartRequest({
    required super.requestId,
    required super.createdAtEpochMs,
    required super.returnContext,
    required this.trainerId,
    required this.npcEntityId,
    required this.mapId,
    required this.playerPos,
  }) : super(
          kind: RuntimeBattleKind.trainer,
          source: RuntimeBattleSourceKind.trainerInteraction,
        );

  final String trainerId;
  final String npcEntityId;
  final String mapId;
  final GridPos playerPos;

  @override
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'requestId': requestId,
      'createdAtEpochMs': createdAtEpochMs,
      'kind': kind.name,
      'source': source.name,
      'returnContext': returnContext.toJson(),
      'trainerId': trainerId,
      'npcEntityId': npcEntityId,
      'mapId': mapId,
      'playerPos': playerPos.toJson(),
    };
  }
}
