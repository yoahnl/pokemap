import 'dart:convert';
import 'dart:io';

import 'package:map_core/map_core.dart';
import 'package:map_distribution/map_distribution.dart';
import 'package:map_editor/game_export.dart';
import 'package:map_editor/src/application/use_cases/seed_pokemon_demo_data_use_case.dart';
import 'package:map_editor/src/infrastructure/filesystem/project_filesystem.dart';
import 'package:map_editor/src/infrastructure/repositories/file_repositories.dart';
import 'package:path/path.dart' as p;
import 'package:pub_semver/pub_semver.dart';

/// A deliberately non-Selbrume author project used only for product gates.
///
/// It is written as an author workspace, exported through `map_editor`, then
/// deleted before installation so the installed runtime cannot depend on it.
final class NeutralCertificationGameFixture {
  static const String fixedGameId = 'games.pokemap.certification.neutral';
  static const String fixedGameVersion = '1.0.0';
  static const String fixedMapId = 'neutral_harbor';
  static const String fixedSpawnId = 'neutral_spawn';

  String get gameId => fixedGameId;
  String get gameVersion => fixedGameVersion;
  String get mapId => fixedMapId;
  String get spawnId => fixedSpawnId;
  String get authorSecret => 'phase8-author-secret-must-never-ship';

  GamePackageExportProfile get exportProfile => GamePackageExportProfile(
    gameId: gameId,
    gameVersion: gameVersion,
    title: 'The Clockwork Harbor',
    description: 'A neutral PokeMap certification mini-game.',
    authorName: 'PokeMap Certification Studio',
    defaultLocale: 'en',
    supportedLocales: const <String>['en', 'fr'],
  );

  GamePackageHostCompatibility get hostCompatibility =>
      GamePackageHostCompatibility(
        hubVersion: Version.parse('1.2.0'),
        runtimeApiVersion: Version.parse('1.4.0'),
        capabilities: const <String>{
          'dialogue.choices@1',
          'map@1',
          'overworld.menu@1',
          'world.shop@1',
        },
        supportedProjectFormats: const <String>{'v6'},
        currentProjectFormat: 'v6',
        supportedSaveFormats: const <int>{1},
      );

  Future<void> writeAuthorWorkspace(Directory root) async {
    await root.create(recursive: true);
    final manifest = ProjectManifest(
      name: 'The Clockwork Harbor',
      version: ProjectVersion.v6,
      maps: const <ProjectMapEntry>[
        ProjectMapEntry(
          id: fixedMapId,
          name: 'Clockwork Harbor',
          relativePath: 'maps/clockwork_harbor.json',
          role: MapRole.exterior,
        ),
      ],
      tilesets: const <ProjectTilesetEntry>[],
      newGame: const ProjectNewGameConfig(
        enabled: true,
        startMapId: fixedMapId,
        startSpawnId: fixedSpawnId,
        playerName: 'Ari',
        startingMoney: 300,
        initialParty: <PlayerPokemon>[
          PlayerPokemon(
            speciesId: 'bulbasaur',
            natureId: 'hardy',
            abilityId: 'overgrow',
            level: 5,
            currentHp: 20,
          ),
        ],
      ),
      scenes: <SceneAsset>[_completionScene],
      eventRegistry: _eventRegistry,
      globalProperties: <String, Object?>{
        'certificationFixture': true,
        'apiKey': authorSecret,
      },
    );
    final manifestJson = manifest.toJson();
    final settings = Map<String, Object?>.from(manifestJson['settings'] as Map);
    settings['mistralApiKey'] = authorSecret;
    manifestJson['settings'] = settings;
    await _writeJson(File(p.join(root.path, 'project.json')), manifestJson);

    const map = MapData(
      id: fixedMapId,
      name: 'Clockwork Harbor',
      version: ProjectVersion.v6,
      size: GridSize(width: 4, height: 4),
      entities: <MapEntity>[
        MapEntity(
          id: fixedSpawnId,
          name: 'Player arrival',
          kind: MapEntityKind.spawn,
          pos: GridPos(x: 1, y: 1),
          blocksMovement: false,
          spawn: MapEntitySpawnData(
            role: EntitySpawnRole.playerStart,
            facing: EntityFacing.south,
          ),
        ),
      ],
      mapMetadata: MapMetadata(defaultSpawnId: fixedSpawnId),
    );
    await _writeJson(
      File(p.join(root.path, 'maps', 'clockwork_harbor.json')),
      map.toJson(),
    );
    await SeedPokemonDemoDataUseCase(
      snapshotController: FilePokemonReadRepository(),
    ).execute(
      ProjectFileSystem(root.path),
    );
    await File(
      p.join(root.path, 'LICENSE.txt'),
    ).writeAsString('PokeMap neutral certification fixture.', flush: true);

    // These author-only artifacts must be dropped by the runtime projection.
    await File(
      p.join(root.path, 'runtime_host_launch_save.json'),
    ).writeAsString('{}', flush: true);
    await File(
      p.join(root.path, 'debug.log'),
    ).writeAsString(authorSecret, flush: true);
    final saves = Directory(p.join(root.path, 'saves'));
    await saves.create(recursive: true);
    await File(
      p.join(saves.path, 'slot.json'),
    ).writeAsString(authorSecret, flush: true);
  }

  Future<void> writeSpeciesCatalog(Directory root, {required int count}) async {
    if (count < 2 || count > 10000) {
      throw ArgumentError.value(count, 'count', 'must be between 2 and 10000');
    }
    final species = Directory(p.join(root.path, 'data', 'pokemon', 'species'));
    await species.create(recursive: true);
    await for (final entity in species.list()) {
      if (entity is File &&
          p.basename(entity.path).endsWith('-clockling.json')) {
        await entity.delete();
      }
    }
    final template =
        jsonDecode(
              await File(
                p.join(species.path, '0001-bulbasaur.json'),
              ).readAsString(),
            )
            as Map<String, dynamic>;
    for (var start = 2; start < count; start += 64) {
      final end = (start + 64).clamp(0, count);
      await Future.wait(<Future<void>>[
        for (var index = start; index < end; index++)
          _writeJson(
            File(
              p.join(
                species.path,
                '${index.toString().padLeft(4, '0')}-clockling.json',
              ),
            ),
            _speciesFromTemplate(template, index),
          ),
      ]);
    }
  }

  Future<GamePackageExportArtifact> export(
    Directory authorRoot,
    File outputFile,
  ) => const GamePackageExportService().exportToFile(
    projectRoot: authorRoot,
    profile: exportProfile,
    outputFile: outputFile,
  );
}

final NarrativeEventRegistry _eventRegistry = NarrativeEventRegistry(
  schemaVersion: 1,
  mode: EventSystemMode.v2Only,
  records: <NarrativeEventRecord>[
    NarrativeEventRecord.configuredStructurallyUnchecked(
      NarrativeEventDefinition(
        id: 'evt_019abcde-7000-7000-8000-000000000001',
        name: 'Runtime start',
        source: NarrativeEventSourceRef.mapEnter(
          NeutralCertificationGameFixture.fixedMapId,
        ),
        conditions: const [],
        sceneId: 'scene.certification.complete',
        reusePolicy: NarrativeEventReusePolicy.oneShot,
        priority: 0,
        order: 0,
      ),
      enabled: true,
    ),
  ],
  legacyClaims: const [],
);

final SceneAsset _completionScene = SceneAsset(
  id: 'scene.certification.complete',
  name: 'Certification journey',
  graph: SceneGraph(
    startNodeId: 'start',
    nodes: <SceneNode>[
      SceneNode(id: 'start', kind: SceneNodeKind.start),
      SceneNode(
        id: 'finish',
        kind: SceneNodeKind.action,
        payload: SceneActionPayload.consequence(
          SceneConsequence.finishGame(
            endingId: 'ending.certification.complete',
            outcome: SceneGameCompletionOutcome.completed,
            result: SceneFinishGameResult(
              title: SceneLocalizedText(fallback: 'Adventure complete'),
              summary: SceneLocalizedText(
                fallback: 'The certification journey reached its ending.',
              ),
            ),
            postGamePolicy: ScenePostGamePolicy.returnToTitle,
          ),
        ),
      ),
      SceneNode(
        id: 'end',
        kind: SceneNodeKind.end,
        payload: SceneEndPayload(outcomePolicy: SceneOutcomePolicy.progression),
      ),
    ],
    edges: <SceneEdge>[
      SceneEdge(
        id: 'start-finish',
        fromNodeId: 'start',
        fromPortId: 'completed',
        toNodeId: 'finish',
        kind: SceneEdgeKind.defaultFlow,
      ),
      SceneEdge(
        id: 'finish-end',
        fromNodeId: 'finish',
        fromPortId: 'completed',
        toNodeId: 'end',
        kind: SceneEdgeKind.defaultFlow,
      ),
    ],
  ),
);

Map<String, Object?> _speciesFromTemplate(
  Map<String, dynamic> template,
  int index,
) {
  final species = jsonDecode(jsonEncode(template)) as Map<String, dynamic>;
  species['id'] = 'clockling_$index';
  species['slug'] = 'clockling-$index';
  species['nationalDex'] = index + 1;
  species['names'] = <String, String>{
    'en': 'Clockling $index',
    'fr': 'Horlogre $index',
  };
  return species;
}

Future<void> _writeJson(File file, Map<String, Object?> value) async {
  await file.parent.create(recursive: true);
  await file.writeAsString(
    const JsonEncoder.withIndent('  ').convert(value),
    flush: true,
  );
}
