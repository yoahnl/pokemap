import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';

enum RuntimeBattleKind {
  wild,
  trainer,
  staticEncounter,
}

enum RuntimeBattleSourceKind {
  wildEncounter,
  trainerInteraction,
  staticEncounter,
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

  /// Politique runtime explicite pour l'action de fuite.
  ///
  /// Seule une rencontre sauvage ordinaire est fuyable. Un boss statique
  /// reste volontairement non-trainer pour son write-back, mais ne doit pas
  /// hériter pour autant des actions sauvages Capture/Run.
  bool get allowsPlayerFlee => kind == RuntimeBattleKind.wild;

  Map<String, dynamic> toJson();
}

class WildBattleStartRequest extends BattleStartRequest {
  const WildBattleStartRequest({
    required super.requestId,
    required super.createdAtEpochMs,
    required super.returnContext,
    required this.mapId,
    required this.encounterSourceId,
    required this.encounterSourceKind,
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
    this.generatedPokemon,
    this.generationProfileId = '',
    this.generationSchemaVersion = 0,
  }) : super(
          kind: RuntimeBattleKind.wild,
          source: RuntimeBattleSourceKind.wildEncounter,
        );

  final String mapId;
  final String encounterSourceId;
  final EncounterSourceKind encounterSourceKind;
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
  final PlayerPokemon? generatedPokemon;
  final String generationProfileId;
  final int generationSchemaVersion;

  WildBattleStartRequest withGeneratedPokemon({
    required PlayerPokemon pokemon,
    required String profileId,
    required int schemaVersion,
  }) {
    return WildBattleStartRequest(
      requestId: requestId,
      createdAtEpochMs: createdAtEpochMs,
      returnContext: returnContext,
      mapId: mapId,
      encounterSourceId: encounterSourceId,
      encounterSourceKind: encounterSourceKind,
      tableId: tableId,
      encounterKind: encounterKind,
      speciesId: speciesId,
      level: level,
      minLevel: minLevel,
      maxLevel: maxLevel,
      weight: weight,
      playerPos: playerPos,
      generationSeed: generationSeed,
      pokemonOverrides: pokemonOverrides,
      generatedPokemon: pokemon,
      generationProfileId: profileId,
      generationSchemaVersion: schemaVersion,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'requestId': requestId,
      'createdAtEpochMs': createdAtEpochMs,
      'kind': kind.name,
      'source': source.name,
      'returnContext': returnContext.toJson(),
      'mapId': mapId,
      'encounterSourceId': encounterSourceId,
      'encounterSourceKind': encounterSourceKind.name,
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
      'generatedPokemon': generatedPokemon?.toJson(),
      'generationProfileId': generationProfileId,
      'generationSchemaVersion': generationSchemaVersion,
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

/// Combat unique contre un Pokémon ou un boss placé dans le monde.
///
/// Le profil d'adversaire réutilise volontairement la donnée d'équipe du
/// projet afin de ne pas dupliquer le catalogue Pokémon. Contrairement à un
/// combat de dresseur, ce type ne marque aucun trainer comme vaincu et ne
/// permet ni fuite ni capture dans le contrat V0.
class StaticBattleStartRequest extends BattleStartRequest {
  const StaticBattleStartRequest({
    required super.requestId,
    required super.createdAtEpochMs,
    required super.returnContext,
    required this.battleId,
    required this.opponentProfileId,
    required this.entityId,
    required this.mapId,
    required this.playerPos,
  }) : super(
          kind: RuntimeBattleKind.staticEncounter,
          source: RuntimeBattleSourceKind.staticEncounter,
        );

  final String battleId;
  final String opponentProfileId;
  final String entityId;
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
      'battleId': battleId,
      'opponentProfileId': opponentProfileId,
      'entityId': entityId,
      'mapId': mapId,
      'playerPos': playerPos.toJson(),
    };
  }
}
