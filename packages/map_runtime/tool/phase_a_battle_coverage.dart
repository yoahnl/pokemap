import 'dart:convert';
import 'dart:io';

import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:map_runtime/src/application/battle_start_request.dart';
import 'package:map_runtime/src/application/load_runtime_map_bundle.dart';
import 'package:map_runtime/src/application/runtime_battle_combatant_seed_builder.dart';
import 'package:map_runtime/src/application/runtime_battle_move_bridge.dart';
import 'package:map_runtime/src/application/runtime_battle_setup_mapper.dart';
import 'package:map_runtime/src/application/runtime_move_catalog_loader.dart';
import 'package:map_runtime/src/application/runtime_pokemon_learnset_loader.dart';
import 'package:map_runtime/src/application/runtime_pokemon_species_loader.dart';
import 'package:path/path.dart' as p;

Future<void> main(List<String> args) async {
  final config = _CliConfig.fromArgs(args);
  final renderer = _PhaseACoverageRenderer(
    bridge: const RuntimeBattleMoveBridge(),
    mapper: RuntimeBattleSetupMapper(),
    moveCatalogLoader: RuntimeMoveCatalogLoader(),
    combatantSeedBuilder: RuntimeBattleCombatantSeedBuilder(),
    speciesLoader: RuntimePokemonSpeciesLoader(),
    learnsetLoader: RuntimePokemonLearnsetLoader(),
  );

  final report = await renderer.render(
    bootstrapJsonPath: config.bootstrapJsonPath,
    projectFilePath: config.projectFilePath,
    launchSavePath: config.launchSavePath,
  );

  final outputFile = File(config.outputPath);
  await outputFile.parent.create(recursive: true);
  await outputFile.writeAsString(report);
  stdout.writeln('Phase A battle coverage written to ${outputFile.path}');
}

class _CliConfig {
  const _CliConfig({
    required this.bootstrapJsonPath,
    required this.projectFilePath,
    required this.launchSavePath,
    required this.outputPath,
  });

  final String bootstrapJsonPath;
  final String projectFilePath;
  final String launchSavePath;
  final String outputPath;

  static _CliConfig fromArgs(List<String> args) {
    String readFlag(String name) {
      final index = args.indexOf(name);
      if (index == -1 || index + 1 >= args.length) {
        throw ArgumentError('Missing required flag $name');
      }
      return args[index + 1];
    }

    return _CliConfig(
      bootstrapJsonPath: readFlag('--bootstrap-json'),
      projectFilePath: readFlag('--project'),
      launchSavePath: readFlag('--save'),
      outputPath: readFlag('--output'),
    );
  }
}

class _PhaseACoverageRenderer {
  const _PhaseACoverageRenderer({
    required this.bridge,
    required this.mapper,
    required this.moveCatalogLoader,
    required this.combatantSeedBuilder,
    required this.speciesLoader,
    required this.learnsetLoader,
  });

  final RuntimeBattleMoveBridge bridge;
  final RuntimeBattleSetupMapper mapper;
  final RuntimeMoveCatalogLoader moveCatalogLoader;
  final RuntimeBattleCombatantSeedBuilder combatantSeedBuilder;
  final RuntimePokemonSpeciesLoader speciesLoader;
  final RuntimePokemonLearnsetLoader learnsetLoader;

  Future<String> render({
    required String bootstrapJsonPath,
    required String projectFilePath,
    required String launchSavePath,
  }) async {
    final projectFile = File(projectFilePath);
    final projectRootDirectory = projectFile.parent.path;
    final normalizedProjectRoot = p.normalize(projectRootDirectory);
    final normalizedLaunchSaveParent =
        p.normalize(File(launchSavePath).parent.path);
    if (normalizedLaunchSaveParent != normalizedProjectRoot) {
      throw StateError(
        'Phase A coverage requires the launch save to live next to project.json.',
      );
    }
    final manifest = ProjectManifest.fromJson(
      jsonDecode(await projectFile.readAsString()) as Map<String, dynamic>,
    );
    final launchSave = SaveData.fromJson(
      jsonDecode(await File(launchSavePath).readAsString())
          as Map<String, dynamic>,
    ).normalized();
    final gameState = gameStateFromSaveData(launchSave);
    final bootstrapCatalogJson =
        jsonDecode(await File(bootstrapJsonPath).readAsString())
            as Map<String, dynamic>;
    final bootstrapEntries =
        (bootstrapCatalogJson['entries'] as List<dynamic>? ?? const <dynamic>[])
            .whereType<Map>()
            .map((entry) => entry.cast<String, dynamic>())
            .toList(growable: false);
    final runtimeMovesCatalog = await moveCatalogLoader.load(
      projectRootDirectory: projectRootDirectory,
      pokemonConfig: manifest.pokemon,
    );

    final authoredMaps = await _loadProjectMaps(
      projectRootDirectory: projectRootDirectory,
      manifest: manifest,
    );
    final bootstrapMoves = bootstrapEntries
        .map(PokemonMove.fromJson)
        .toList(growable: false)
      ..sort((left, right) => left.id.compareTo(right.id));

    final bootstrapMoveRows = bootstrapMoves
        .map(
          (move) => _classifyMoveBridgeability(
            move: move,
            sourceLabel: 'bootstrap',
            occurrenceCount: 1,
            sources: const <String>['bootstrap'],
          ),
        )
        .toList(growable: false);

    final sliceMoveUsages = await _collectGoldenSliceMoveUsages(
      projectRootDirectory: projectRootDirectory,
      manifest: manifest,
      launchSave: launchSave,
      authoredMaps: authoredMaps,
    );
    final sliceMoveRows = sliceMoveUsages.values
        .map(
          (usage) => _classifyMoveBridgeability(
            move: usage.move,
            sourceLabel: 'golden_slice',
            occurrenceCount: usage.occurrenceCount,
            sources: usage.sources,
          ),
        )
        .toList(growable: false)
      ..sort((left, right) => left.moveId.compareTo(right.moveId));

    final playerSelection = mapper.selectPlayerBattleLineup(gameState.party);
    final playerSeedRows = await _buildPlayerSeedRows(
      projectRootDirectory: projectRootDirectory,
      manifest: manifest,
      runtimeMovesCatalog: runtimeMovesCatalog,
      gameState: gameState,
      playerSelection: playerSelection,
    );
    final trainerSeedRows = await _buildTrainerSeedRows(
      projectRootDirectory: projectRootDirectory,
      manifest: manifest,
      runtimeMovesCatalog: runtimeMovesCatalog,
    );
    final wildSeedRows = await _buildWildSeedRows(
      projectRootDirectory: projectRootDirectory,
      manifest: manifest,
      runtimeMovesCatalog: runtimeMovesCatalog,
      authoredMaps: authoredMaps,
    );

    final battleRows = await _buildBattleRows(
      projectRootDirectory: projectRootDirectory,
      manifest: manifest,
      gameState: gameState,
      authoredMaps: authoredMaps,
    );

    final bootstrapBridgeableCount =
        bootstrapMoveRows.where((row) => row.bridgeable).length;
    final sliceBridgeableCount =
        sliceMoveRows.where((row) => row.bridgeable).length;
    final playerBridgeableCount =
        playerSeedRows.where((row) => row.status == 'bridgeable').length;
    final trainerBridgeableCount =
        trainerSeedRows.where((row) => row.status == 'bridgeable').length;
    final wildBridgeableCount =
        wildSeedRows.where((row) => row.status == 'bridgeable').length;
    final wildBattleStartableCount =
        battleRows.where((row) => row.kind == 'wild' && row.startable).length;
    final trainerBattleStartableCount = battleRows
        .where((row) => row.kind == 'trainer' && row.startable)
        .length;

    return <String>[
      '# Phase A Battle Coverage',
      '',
      '## Executive Summary',
      '',
      '- Bootstrap moves bridgeables: '
          '$bootstrapBridgeableCount / ${bootstrapMoveRows.length}',
      '- Golden slice moves bridgeables: '
          '$sliceBridgeableCount / ${sliceMoveRows.length}',
      '- Player seeds bridgeables: '
          '$playerBridgeableCount / ${playerSeedRows.length}',
      '- Trainer seeds bridgeables: '
          '$trainerBridgeableCount / ${trainerSeedRows.length}',
      '- Wild seeds bridgeables: '
          '$wildBridgeableCount / ${wildSeedRows.length}',
      '- Wild battles startable: '
          '$wildBattleStartableCount / ${battleRows.where((row) => row.kind == 'wild').length}',
      '- Trainer battles startable: '
          '$trainerBattleStartableCount / ${battleRows.where((row) => row.kind == 'trainer').length}',
      '',
      '## Bootstrap Move Coverage',
      '',
      _markdownTable(
        const <String>[
          'moveId',
          'engineSupportLevel',
          'bridgeable',
          'bridgeLimit',
          'unsupportedReasons',
        ],
        bootstrapMoveRows
            .map(
              (row) => <String>[
                row.moveId,
                row.engineSupportLevel,
                row.bridgeable ? 'yes' : 'no',
                row.bridgeLimit,
                row.unsupportedReasons,
              ],
            )
            .toList(growable: false),
      ),
      '',
      '## Golden Slice Move Coverage',
      '',
      _markdownTable(
        const <String>[
          'moveId',
          'occurrences',
          'sources',
          'engineSupportLevel',
          'bridgeable',
          'bridgeLimit',
          'unsupportedReasons',
        ],
        sliceMoveRows
            .map(
              (row) => <String>[
                row.moveId,
                row.occurrenceCount.toString(),
                row.sources.join(', '),
                row.engineSupportLevel,
                row.bridgeable ? 'yes' : 'no',
                row.bridgeLimit,
                row.unsupportedReasons,
              ],
            )
            .toList(growable: false),
      ),
      '',
      '## Player Seed Coverage',
      '',
      _markdownTable(
        const <String>[
          'label',
          'candidateMoveIds',
          'builtMoveIds',
          'status',
          'failure',
        ],
        playerSeedRows
            .map(
              (row) => <String>[
                row.label,
                row.candidateMoveIds.join(', '),
                row.builtMoveIds.join(', '),
                row.status,
                row.failure,
              ],
            )
            .toList(growable: false),
      ),
      '',
      '## Trainer Seed Coverage',
      '',
      _markdownTable(
        const <String>[
          'label',
          'candidateMoveIds',
          'builtMoveIds',
          'status',
          'failure',
        ],
        trainerSeedRows
            .map(
              (row) => <String>[
                row.label,
                row.candidateMoveIds.join(', '),
                row.builtMoveIds.join(', '),
                row.status,
                row.failure,
              ],
            )
            .toList(growable: false),
      ),
      '',
      '## Wild Seed Coverage',
      '',
      _markdownTable(
        const <String>[
          'label',
          'candidateMoveIds',
          'builtMoveIds',
          'status',
          'failure',
        ],
        wildSeedRows
            .map(
              (row) => <String>[
                row.label,
                row.candidateMoveIds.join(', '),
                row.builtMoveIds.join(', '),
                row.status,
                row.failure,
              ],
            )
            .toList(growable: false),
      ),
      '',
      '## Authored Battle Startability',
      '',
      _markdownTable(
        const <String>[
          'kind',
          'label',
          'startable',
          'reason',
        ],
        battleRows
            .map(
              (row) => <String>[
                row.kind,
                row.label,
                row.startable ? 'yes' : 'no',
                row.reason,
              ],
            )
            .toList(growable: false),
      ),
      '',
      '## Notes',
      '',
      '- Wild battle opportunities are measured at the authored '
          '`zone -> table entry` level.',
      '- Trainer battles are measured at the authored NPC trainer hook level.',
      '- Player truth comes from the versioned launch save, not from test-only '
          'fixtures.',
      '- This report is generated locally from the real golden slice and the '
          'real embedded bootstrap seed.',
      '',
    ].join('\n');
  }

  Future<Map<String, MapData>> _loadProjectMaps({
    required String projectRootDirectory,
    required ProjectManifest manifest,
  }) async {
    final maps = <String, MapData>{};
    for (final entry in manifest.maps) {
      final file = File(p.join(projectRootDirectory, entry.relativePath));
      maps[entry.id] = MapData.fromJson(
        jsonDecode(await file.readAsString()) as Map<String, dynamic>,
      );
    }
    return maps;
  }

  _MoveCoverageRow _classifyMoveBridgeability({
    required PokemonMove move,
    required String sourceLabel,
    required int occurrenceCount,
    required List<String> sources,
  }) {
    try {
      bridge.toBattleMoveData(
        move: move,
        combatantLabel: 'Audit $sourceLabel',
      );
      return _MoveCoverageRow(
        moveId: move.id,
        occurrenceCount: occurrenceCount,
        sources: sources,
        engineSupportLevel: move.engineSupportLevel.name,
        bridgeable: true,
        bridgeLimit: '',
        unsupportedReasons: move.unsupportedReasons.join(', '),
      );
    } on RuntimeBattleSetupException catch (error) {
      return _MoveCoverageRow(
        moveId: move.id,
        occurrenceCount: occurrenceCount,
        sources: sources,
        engineSupportLevel: move.engineSupportLevel.name,
        bridgeable: false,
        bridgeLimit: _extractBridgeLimit(error.debugDetails),
        unsupportedReasons: move.unsupportedReasons.join(', '),
      );
    }
  }

  Future<Map<String, _SliceMoveUsage>> _collectGoldenSliceMoveUsages({
    required String projectRootDirectory,
    required ProjectManifest manifest,
    required SaveData launchSave,
    required Map<String, MapData> authoredMaps,
  }) async {
    final moveCatalog = await moveCatalogLoader.load(
      projectRootDirectory: projectRootDirectory,
      pokemonConfig: manifest.pokemon,
    );
    final usages = <String, _SliceMoveUsage>{};

    void addUsage({
      required String moveId,
      required String source,
    }) {
      final move = moveCatalog.lookup(moveId);
      if (move == null) {
        return;
      }
      final current = usages[moveId];
      usages[moveId] = current == null
          ? _SliceMoveUsage(
              move: move,
              occurrenceCount: 1,
              sources: <String>[source],
            )
          : current.addSource(source);
    }

    for (var i = 0; i < launchSave.party.members.length; i++) {
      final member = launchSave.party.members[i];
      final candidateMoveIds = await _derivePlayerCandidateMoveIds(
        projectRootDirectory: projectRootDirectory,
        manifest: manifest,
        playerPokemon: member,
      );
      for (final moveId in candidateMoveIds) {
        addUsage(
          moveId: moveId,
          source: 'player_party[$i]',
        );
      }
    }

    for (final trainer in manifest.trainers) {
      for (var i = 0; i < trainer.team.length; i++) {
        final teamMember = trainer.team[i];
        final candidateMoveIds = await _deriveTrainerCandidateMoveIds(
          projectRootDirectory: projectRootDirectory,
          manifest: manifest,
          teamMember: teamMember,
        );
        for (final moveId in candidateMoveIds) {
          addUsage(
            moveId: moveId,
            source: 'trainer:${trainer.id}[$i]',
          );
        }
      }
    }

    for (final mapEntry in authoredMaps.entries) {
      final map = mapEntry.value;
      for (final zone in _authoredEncounterZones(map)) {
        final tableId = (zone.encounter?.encounterTableId ?? '').trim();
        final table = manifest.encounterTables.firstWhere(
          (candidate) => candidate.id == tableId,
        );
        for (var i = 0; i < table.entries.length; i++) {
          final entry = table.entries[i];
          final candidateMoveIds = await _deriveWildCandidateMoveIds(
            projectRootDirectory: projectRootDirectory,
            manifest: manifest,
            speciesId: entry.speciesId,
            level: entry.minLevel,
          );
          for (final moveId in candidateMoveIds) {
            addUsage(
              moveId: moveId,
              source: 'wild:${map.id}:${zone.id}[$i]',
            );
          }
        }
      }
    }

    return usages;
  }

  Future<List<_SeedCoverageRow>> _buildPlayerSeedRows({
    required String projectRootDirectory,
    required ProjectManifest manifest,
    required RuntimeMoveCatalog runtimeMovesCatalog,
    required GameState gameState,
    required RuntimePlayerBattleLineupSelection playerSelection,
  }) async {
    final rows = <_SeedCoverageRow>[];
    for (var i = 0; i < gameState.party.members.length; i++) {
      final playerPokemon = gameState.party.members[i];
      final candidateMoveIds = await _derivePlayerCandidateMoveIds(
        projectRootDirectory: projectRootDirectory,
        manifest: manifest,
        playerPokemon: playerPokemon,
      );
      final label = i == playerSelection.activeIndex
          ? 'player_party[$i]:active:${playerPokemon.speciesId}'
          : playerSelection.reserveIndices.contains(i)
              ? 'player_party[$i]:reserve:${playerPokemon.speciesId}'
              : 'player_party[$i]:inactive:${playerPokemon.speciesId}';

      try {
        final seed = await combatantSeedBuilder.buildPlayerCombatantSeed(
          projectRootDirectory: projectRootDirectory,
          pokemonConfig: manifest.pokemon,
          movesCatalog: runtimeMovesCatalog,
          playerPokemon: playerPokemon,
          combatantLabel: label,
        );
        rows.add(
          _SeedCoverageRow(
            label: label,
            candidateMoveIds: candidateMoveIds,
            builtMoveIds:
                seed.moves.map((move) => move.id).toList(growable: false),
            status: 'bridgeable',
            failure: '',
          ),
        );
      } on RuntimeBattleSetupException catch (error) {
        rows.add(
          _SeedCoverageRow(
            label: label,
            candidateMoveIds: candidateMoveIds,
            builtMoveIds: const <String>[],
            status: 'blocked',
            failure: _formatFailure(error),
          ),
        );
      }
    }
    return rows;
  }

  Future<List<_SeedCoverageRow>> _buildTrainerSeedRows({
    required String projectRootDirectory,
    required ProjectManifest manifest,
    required RuntimeMoveCatalog runtimeMovesCatalog,
  }) async {
    final rows = <_SeedCoverageRow>[];
    for (final trainer in manifest.trainers) {
      for (var i = 0; i < trainer.team.length; i++) {
        final teamMember = trainer.team[i];
        final candidateMoveIds = await _deriveTrainerCandidateMoveIds(
          projectRootDirectory: projectRootDirectory,
          manifest: manifest,
          teamMember: teamMember,
        );
        final label = 'trainer:${trainer.id}[$i]:${teamMember.speciesId}';
        try {
          final seed = await combatantSeedBuilder.buildTrainerCombatantSeed(
            projectRootDirectory: projectRootDirectory,
            pokemonConfig: manifest.pokemon,
            movesCatalog: runtimeMovesCatalog,
            teamMember: teamMember,
            trainerName: trainer.name,
          );
          rows.add(
            _SeedCoverageRow(
              label: label,
              candidateMoveIds: candidateMoveIds,
              builtMoveIds:
                  seed.moves.map((move) => move.id).toList(growable: false),
              status: 'bridgeable',
              failure: '',
            ),
          );
        } on RuntimeBattleSetupException catch (error) {
          rows.add(
            _SeedCoverageRow(
              label: label,
              candidateMoveIds: candidateMoveIds,
              builtMoveIds: const <String>[],
              status: 'blocked',
              failure: _formatFailure(error),
            ),
          );
        }
      }
    }
    return rows;
  }

  Future<List<_SeedCoverageRow>> _buildWildSeedRows({
    required String projectRootDirectory,
    required ProjectManifest manifest,
    required RuntimeMoveCatalog runtimeMovesCatalog,
    required Map<String, MapData> authoredMaps,
  }) async {
    final rows = <_SeedCoverageRow>[];
    for (final mapEntry in authoredMaps.entries) {
      final map = mapEntry.value;
      for (final zone in _authoredEncounterZones(map)) {
        final table = manifest.encounterTables.firstWhere(
          (candidate) =>
              candidate.id == (zone.encounter?.encounterTableId ?? '').trim(),
        );
        for (var i = 0; i < table.entries.length; i++) {
          final entry = table.entries[i];
          final candidateMoveIds = await _deriveWildCandidateMoveIds(
            projectRootDirectory: projectRootDirectory,
            manifest: manifest,
            speciesId: entry.speciesId,
            level: entry.minLevel,
          );
          final label =
              'wild:${map.id}:${zone.id}[$i]:${entry.speciesId}@${entry.minLevel}-${entry.maxLevel}';
          try {
            final seed = await combatantSeedBuilder.buildWildCombatantSeed(
              projectRootDirectory: projectRootDirectory,
              pokemonConfig: manifest.pokemon,
              movesCatalog: runtimeMovesCatalog,
              request: WildBattleStartRequest(
                requestId: 'audit-wild-$i',
                createdAtEpochMs: 1,
                returnContext: OverworldReturnContext(
                  mapId: map.id,
                  playerPos: zone.area.pos,
                  playerFacing: Direction.south,
                ),
                mapId: map.id,
                zoneId: zone.id,
                tableId: table.id,
                encounterKind: zone.encounter!.encounterKind,
                speciesId: entry.speciesId,
                level: entry.minLevel,
                minLevel: entry.minLevel,
                maxLevel: entry.maxLevel,
                weight: entry.weight,
                playerPos: zone.area.pos,
              ),
            );
            rows.add(
              _SeedCoverageRow(
                label: label,
                candidateMoveIds: candidateMoveIds,
                builtMoveIds:
                    seed.moves.map((move) => move.id).toList(growable: false),
                status: 'bridgeable',
                failure: '',
              ),
            );
          } on RuntimeBattleSetupException catch (error) {
            rows.add(
              _SeedCoverageRow(
                label: label,
                candidateMoveIds: candidateMoveIds,
                builtMoveIds: const <String>[],
                status: 'blocked',
                failure: _formatFailure(error),
              ),
            );
          }
        }
      }
    }
    return rows;
  }

  Future<List<_BattleCoverageRow>> _buildBattleRows({
    required String projectRootDirectory,
    required ProjectManifest manifest,
    required GameState gameState,
    required Map<String, MapData> authoredMaps,
  }) async {
    final rows = <_BattleCoverageRow>[];
    for (final mapEntry in authoredMaps.entries) {
      final map = mapEntry.value;
      final bundle = await loadRuntimeMapBundle(
        projectFilePath: p.join(projectRootDirectory, 'project.json'),
        mapId: map.id,
      );

      for (final zone in _authoredEncounterZones(map)) {
        final table = manifest.encounterTables.firstWhere(
          (candidate) =>
              candidate.id == (zone.encounter?.encounterTableId ?? '').trim(),
        );
        for (var i = 0; i < table.entries.length; i++) {
          final entry = table.entries[i];
          final label =
              'wild:${map.id}:${zone.id}[$i]:${entry.speciesId}@${entry.minLevel}-${entry.maxLevel}';
          try {
            await mapper.map(
              bundle: bundle,
              gameState: gameState,
              request: WildBattleStartRequest(
                requestId: 'audit-wild-start-$i',
                createdAtEpochMs: 1,
                returnContext: OverworldReturnContext(
                  mapId: map.id,
                  playerPos: zone.area.pos,
                  playerFacing: Direction.south,
                ),
                mapId: map.id,
                zoneId: zone.id,
                tableId: table.id,
                encounterKind: zone.encounter!.encounterKind,
                speciesId: entry.speciesId,
                level: entry.minLevel,
                minLevel: entry.minLevel,
                maxLevel: entry.maxLevel,
                weight: entry.weight,
                playerPos: zone.area.pos,
              ),
            );
            rows.add(
              const _BattleCoverageRow(
                kind: 'wild',
                label: '',
                startable: true,
                reason: '',
              ).copyWith(label: label),
            );
          } on RuntimeBattleSetupException catch (error) {
            rows.add(
              _BattleCoverageRow(
                kind: 'wild',
                label: label,
                startable: false,
                reason: _formatFailure(error),
              ),
            );
          }
        }
      }

      final world = GameplayWorldState.fromMap(
        map,
        project: manifest,
      );
      for (final entity in map.entities.where(
        (entity) => entity.kind == MapEntityKind.npc,
      )) {
        final trainerId = entity.npc?.trainerId?.trim();
        if (trainerId == null || trainerId.isEmpty) {
          continue;
        }
        final label = 'trainer:${map.id}:${entity.id}:$trainerId';
        try {
          await mapper.map(
            bundle: bundle,
            gameState: gameState,
            request: TrainerBattleStartRequest(
              requestId: 'audit-trainer-$trainerId',
              createdAtEpochMs: 1,
              returnContext: OverworldReturnContext(
                mapId: map.id,
                playerPos: world.player.pos,
                playerFacing: world.player.facing,
              ),
              trainerId: trainerId,
              npcEntityId: entity.id,
              mapId: map.id,
              playerPos: world.player.pos,
            ),
          );
          rows.add(
            _BattleCoverageRow(
              kind: 'trainer',
              label: label,
              startable: true,
              reason: '',
            ),
          );
        } on RuntimeBattleSetupException catch (error) {
          rows.add(
            _BattleCoverageRow(
              kind: 'trainer',
              label: label,
              startable: false,
              reason: _formatFailure(error),
            ),
          );
        }
      }
    }
    return rows;
  }

  Future<List<String>> _derivePlayerCandidateMoveIds({
    required String projectRootDirectory,
    required ProjectManifest manifest,
    required PlayerPokemon playerPokemon,
  }) async {
    if (playerPokemon.knownMoveIds.isNotEmpty) {
      return _normalizeUniqueIdsPreserveOrder(playerPokemon.knownMoveIds)
          .take(4)
          .toList(growable: false);
    }
    return _deriveLearnsetMoveIds(
      projectRootDirectory: projectRootDirectory,
      manifest: manifest,
      speciesId: playerPokemon.speciesId,
      level: playerPokemon.level,
    );
  }

  Future<List<String>> _deriveTrainerCandidateMoveIds({
    required String projectRootDirectory,
    required ProjectManifest manifest,
    required ProjectTrainerPokemonEntry teamMember,
  }) async {
    if (teamMember.moves.isNotEmpty) {
      return _normalizeUniqueIdsPreserveOrder(teamMember.moves)
          .take(4)
          .toList(growable: false);
    }
    return _deriveLearnsetMoveIds(
      projectRootDirectory: projectRootDirectory,
      manifest: manifest,
      speciesId: teamMember.speciesId,
      level: teamMember.level,
    );
  }

  Future<List<String>> _deriveWildCandidateMoveIds({
    required String projectRootDirectory,
    required ProjectManifest manifest,
    required String speciesId,
    required int level,
  }) {
    return _deriveLearnsetMoveIds(
      projectRootDirectory: projectRootDirectory,
      manifest: manifest,
      speciesId: speciesId,
      level: level,
    );
  }

  Future<List<String>> _deriveLearnsetMoveIds({
    required String projectRootDirectory,
    required ProjectManifest manifest,
    required String speciesId,
    required int level,
  }) async {
    final species = await speciesLoader.loadById(
      projectRootDirectory: projectRootDirectory,
      pokemonConfig: manifest.pokemon,
      speciesId: speciesId,
    );
    final learnset = await learnsetLoader.loadByRef(
      projectRootDirectory: projectRootDirectory,
      pokemonConfig: manifest.pokemon,
      speciesRef: species.learnsetRef,
      fallbackSpeciesId: species.id,
    );
    final ordered = <String>[
      ...learnset.startingMoves,
      ...learnset.relearnMoves,
      ...learnset.levelUp
          .where((entry) => entry.level <= level)
          .map((entry) => entry.moveId),
    ];
    final unique = _normalizeUniqueIdsPreserveOrder(ordered);
    if (unique.length <= 4) {
      return unique;
    }
    return unique.sublist(unique.length - 4);
  }

  List<String> _normalizeUniqueIdsPreserveOrder(List<String> rawIds) {
    final out = <String>[];
    final seen = <String>{};
    for (final rawId in rawIds) {
      final normalizedId = rawId.trim();
      if (normalizedId.isEmpty || !seen.add(normalizedId)) {
        continue;
      }
      out.add(normalizedId);
    }
    return List<String>.unmodifiable(out);
  }

  String _extractBridgeLimit(String? debugDetails) {
    if (debugDetails == null || debugDetails.isEmpty) {
      return '';
    }
    final match = RegExp(r'bridgeLimit=([^,]+)').firstMatch(debugDetails);
    return match == null ? '' : match.group(1)!;
  }

  String _formatFailure(RuntimeBattleSetupException error) {
    if (error.debugDetails == null || error.debugDetails!.trim().isEmpty) {
      return error.message;
    }
    return '${error.message} (${error.debugDetails})';
  }

  String _markdownTable(List<String> headers, List<List<String>> rows) {
    String escape(String value) {
      return value.replaceAll('|', '\\|').replaceAll('\n', '<br>');
    }

    final buffer = StringBuffer()
      ..writeln('| ${headers.map(escape).join(' | ')} |')
      ..writeln('| ${headers.map((_) => '---').join(' | ')} |');
    for (final row in rows) {
      buffer.writeln('| ${row.map(escape).join(' | ')} |');
    }
    return buffer.toString().trimRight();
  }

  Iterable<MapGameplayZone> _authoredEncounterZones(MapData map) sync* {
    for (final zone in map.gameplayZones) {
      final tableId = (zone.encounter?.encounterTableId ?? '').trim();
      if (zone.kind != GameplayZoneKind.encounter || tableId.isEmpty) {
        continue;
      }
      yield zone;
    }
  }
}

class _SliceMoveUsage {
  const _SliceMoveUsage({
    required this.move,
    required this.occurrenceCount,
    required this.sources,
  });

  final PokemonMove move;
  final int occurrenceCount;
  final List<String> sources;

  _SliceMoveUsage addSource(String source) {
    final nextSources = List<String>.from(sources);
    if (!nextSources.contains(source)) {
      nextSources.add(source);
    }
    return _SliceMoveUsage(
      move: move,
      occurrenceCount: occurrenceCount + 1,
      sources: List<String>.unmodifiable(nextSources),
    );
  }
}

class _MoveCoverageRow {
  const _MoveCoverageRow({
    required this.moveId,
    required this.occurrenceCount,
    required this.sources,
    required this.engineSupportLevel,
    required this.bridgeable,
    required this.bridgeLimit,
    required this.unsupportedReasons,
  });

  final String moveId;
  final int occurrenceCount;
  final List<String> sources;
  final String engineSupportLevel;
  final bool bridgeable;
  final String bridgeLimit;
  final String unsupportedReasons;
}

class _SeedCoverageRow {
  const _SeedCoverageRow({
    required this.label,
    required this.candidateMoveIds,
    required this.builtMoveIds,
    required this.status,
    required this.failure,
  });

  final String label;
  final List<String> candidateMoveIds;
  final List<String> builtMoveIds;
  final String status;
  final String failure;
}

class _BattleCoverageRow {
  const _BattleCoverageRow({
    required this.kind,
    required this.label,
    required this.startable,
    required this.reason,
  });

  final String kind;
  final String label;
  final bool startable;
  final String reason;

  _BattleCoverageRow copyWith({
    String? kind,
    String? label,
    bool? startable,
    String? reason,
  }) {
    return _BattleCoverageRow(
      kind: kind ?? this.kind,
      label: label ?? this.label,
      startable: startable ?? this.startable,
      reason: reason ?? this.reason,
    );
  }
}
