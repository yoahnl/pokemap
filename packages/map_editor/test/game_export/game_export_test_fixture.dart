import 'dart:convert';
import 'dart:io';

import 'package:map_core/map_core.dart';
import 'package:map_editor/game_export.dart';
import 'package:map_editor/src/application/use_cases/seed_pokemon_demo_data_use_case.dart';
import 'package:map_editor/src/infrastructure/filesystem/project_filesystem.dart';
import 'package:map_editor/src/infrastructure/repositories/file_repositories.dart';
import 'package:path/path.dart' as p;

Future<Directory> createAuthorProject({
  bool withDialogue = true,
  bool withCanonicalPokemon = true,
  String name = 'Neutral Adventure',
}) async {
  final root = await Directory.systemTemp.createTemp('pokemap_author_export_');
  final project = ProjectManifest(
    name: name,
    version: ProjectVersion.v6,
    maps: const <ProjectMapEntry>[
      ProjectMapEntry(
        id: 'map.start',
        name: 'Start',
        relativePath: 'maps/start.json',
      ),
    ],
    tilesets: const <ProjectTilesetEntry>[],
    dialogues: withDialogue
        ? const <ProjectDialogueEntry>[
            ProjectDialogueEntry(
              id: 'dialogue.intro',
              name: 'Introduction',
              relativePath: 'dialogues/intro.yarn',
              defaultStartNode: 'Start',
            ),
          ]
        : const <ProjectDialogueEntry>[],
    scenes: <SceneAsset>[_playableCompletionScene()],
    eventRegistry: NarrativeEventRegistry(
      schemaVersion: 1,
      mode: EventSystemMode.v2Only,
      records: [
        NarrativeEventRecord.configuredStructurallyUnchecked(
          NarrativeEventDefinition(
            id: 'evt_019abcde-6000-7000-8000-000000000001',
            name: 'Runtime start',
            source: NarrativeEventSourceRef.mapEnter('map.start'),
            conditions: const [],
            sceneId: 'scene.main',
            reusePolicy: NarrativeEventReusePolicy.oneShot,
            priority: 0,
            order: 0,
          ),
          enabled: true,
        ),
      ],
      legacyClaims: const [],
    ),
    newGame: ProjectNewGameConfig(
      enabled: true,
      startMapId: 'map.start',
      startSpawnId: 'spawn.player',
      playerName: 'Player',
      initialParty: [
        PlayerPokemon(
          speciesId: withCanonicalPokemon ? 'bulbasaur' : 'fixture.partner',
          formId: 'partner',
          natureId: 'hardy',
          abilityId: withCanonicalPokemon ? 'overgrow' : 'steadfast',
          level: 5,
          currentHp: 20,
        ),
      ],
    ),
    pokemon: ProjectPokemonConfig(
      ruleset: PokemonRulesetProfile.pokeMapBetaV1,
      enabled: withCanonicalPokemon,
    ),
    settings: const ProjectSettings(
      tileWidth: 16,
      tileHeight: 16,
      mistralApiKey: 'fixture-secret-that-must-not-ship',
    ),
    globalProperties: const <String, dynamic>{
      'apiKey': 'another-author-secret',
      'weather': 'clear',
    },
  ).toJson();
  await File(
    p.join(root.path, 'project.json'),
  ).writeAsString(jsonEncode(project), flush: true);
  await Directory(p.join(root.path, 'maps')).create(recursive: true);
  final mapJson = const MapData(
    id: 'map.start',
    name: 'Start',
    version: ProjectVersion.v6,
    size: GridSize(width: 8, height: 8),
    layers: <MapLayer>[MapLayer.object(id: 'events', name: 'Events')],
    mapMetadata: MapMetadata(defaultSpawnId: 'spawn.player'),
    entities: <MapEntity>[
      MapEntity(
        id: 'spawn.player',
        name: 'Player start',
        kind: MapEntityKind.spawn,
        pos: GridPos(x: 1, y: 1),
        spawn: MapEntitySpawnData(role: EntitySpawnRole.playerStart),
      ),
    ],
  ).toJson();
  if (withDialogue) {
    mapJson['dialogue'] = <String, Object?>{
      'dialogueId': 'dialogue.intro',
      'scriptPathRelative': 'dialogues/intro.yarn',
    };
  }
  await File(
    p.join(root.path, 'maps', 'start.json'),
  ).writeAsString(jsonEncode(mapJson), flush: true);
  if (withDialogue) {
    await Directory(p.join(root.path, 'dialogues')).create(recursive: true);
    await File(p.join(root.path, 'dialogues', 'intro.yarn')).writeAsString('''
title: Start
---
Guide: Bienvenue.
-> Continuer
  <<outcome continue>>
  En route.
===
''', flush: true);
  }
  await Directory(p.join(root.path, 'assets')).create(recursive: true);
  await File(
    p.join(root.path, 'assets', 'icon.png'),
  ).writeAsBytes(onePixelPng, flush: true);
  await Directory(
    p.join(root.path, 'data', 'pokemon', 'media'),
  ).create(recursive: true);
  await File(
    p.join(root.path, 'data', 'pokemon', 'media', 'creature.png'),
  ).writeAsBytes(onePixelPng, flush: true);
  await File(
    p.join(root.path, 'LICENSE.txt'),
  ).writeAsString('Example license', flush: true);
  await File(
    p.join(root.path, 'CREDITS.txt'),
  ).writeAsString('Example credits', flush: true);
  await File(
    p.join(root.path, 'runtime_host_launch_save.json'),
  ).writeAsString('{}', flush: true);
  await Directory(p.join(root.path, 'saves')).create(recursive: true);
  await File(
    p.join(root.path, 'saves', 'slot.json'),
  ).writeAsString('{}', flush: true);
  await Directory(p.join(root.path, '.dart_tool')).create(recursive: true);
  await File(
    p.join(root.path, '.dart_tool', 'cache.json'),
  ).writeAsString('{}', flush: true);
  if (withCanonicalPokemon) {
    await SeedPokemonDemoDataUseCase(
      snapshotController: FilePokemonReadRepository(),
    ).execute(ProjectFileSystem(root.path));
    await _writeReferencedPokemonAssets(root);
  }
  return root;
}

Future<void> _writeReferencedPokemonAssets(Directory root) async {
  final mediaDirectory = Directory(
    p.join(root.path, 'data', 'pokemon', 'media'),
  );
  await for (final entity in mediaDirectory.list()) {
    if (entity is! File || !entity.path.endsWith('.json')) continue;
    final media =
        jsonDecode(await entity.readAsString()) as Map<String, dynamic>;
    final variants = (media['variants'] as Map<String, dynamic>).values;
    for (final rawVariant in variants) {
      final variant = rawVariant as Map<String, dynamic>;
      final paths = <String>[
        for (final key in const <String>[
          'frontStatic',
          'backStatic',
          'frontShinyStatic',
          'backShinyStatic',
          'icon',
          'party',
          'overworld',
          'portrait',
          'cry',
        ])
          if (variant[key] case final String path) path,
        for (final animation
            in (variant['animations'] as Map<String, dynamic>? ?? const {})
                .values)
          if ((animation as Map<String, dynamic>)['sheet']
              case final String path)
            path,
      ];
      for (final relativePath in paths) {
        final file = File(p.join(root.path, relativePath));
        await file.parent.create(recursive: true);
        await file.writeAsBytes(
          relativePath.endsWith('.ogg')
              ? utf8.encode('OggS pokemon-fixture')
              : onePixelPng,
          flush: true,
        );
      }
    }
  }
}

SceneAsset _playableCompletionScene() => SceneAsset(
  id: 'scene.main',
  name: 'Main journey',
  graph: SceneGraph(
    startNodeId: 'start',
    nodes: <SceneNode>[
      SceneNode(id: 'start', kind: SceneNodeKind.start),
      SceneNode(
        id: 'finish',
        kind: SceneNodeKind.action,
        payload: SceneActionPayload.consequence(
          SceneConsequence.finishGame(
            endingId: 'ending.fixture.complete',
            outcome: SceneGameCompletionOutcome.completed,
            result: SceneFinishGameResult(
              title: SceneLocalizedText(fallback: 'Adventure complete'),
              summary: SceneLocalizedText(
                fallback: 'The fixture reached its authored ending.',
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

GamePackageExportProfile neutralExportProfile({
  String gameId = 'games.example.neutral',
  String title = 'Neutral Adventure',
  String version = '1.2.0',
}) => GamePackageExportProfile(
  gameId: gameId,
  gameVersion: version,
  title: title,
  description: 'A neutral exported game.',
  authorName: 'Example Studio',
  defaultLocale: 'fr',
  supportedLocales: const <String>['fr', 'en'],
  iconPath: 'assets/icon.png',
  coverPath: 'assets/icon.png',
  licensePath: 'LICENSE.txt',
  creditsPath: 'CREDITS.txt',
);

final List<int> onePixelPng = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk'
  '+A8AAQUBAScY42YAAAAASUVORK5CYII=',
);
