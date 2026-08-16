import 'dart:convert';
import 'dart:io';

import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:map_distribution/map_distribution.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  test('exports a certified package inside the configured output root',
      () async {
    final projectRoot = await _createPlayableProject();
    final exportRoot = await Directory.systemTemp.createTemp('avelune_export_');
    addTearDown(() => projectRoot.delete(recursive: true));
    addTearDown(() => exportRoot.delete(recursive: true));
    final profile = _profile();
    await GamePackageExportProfileStore(projectRoot: projectRoot).save(profile);
    final output = File(p.join(exportRoot.path, 'fixture-1.0.0.avelunegame'));
    final api = await LocalGamePackageExportApi.create(
      allowedProjectRoots: <String>[projectRoot.path],
      allowedExportRoots: <String>[exportRoot.path],
      exportService: CanonicalGamePackageExportService(
        pokemonValidator: _acceptPokemonProjection,
      ),
    );

    final receipt = await api.export(
      projectRoot: projectRoot.path,
      outputPath: output.path,
    );
    final inspection = const GamePackageInspector().inspect(
      await output.readAsBytes(),
    );

    expect(receipt.outputPath, await output.resolveSymbolicLinks());
    expect(receipt.sizeBytes, await output.length());
    expect(receipt.sha256, isNotEmpty);
    expect(receipt.gameId, profile.gameId);
    expect(receipt.gameVersion, profile.gameVersion);
    expect(inspection.manifest.gameId, profile.gameId);
  });

  test('rejects a destination outside the configured output root', () async {
    final projectRoot = await _createPlayableProject();
    final exportRoot = await Directory.systemTemp.createTemp('avelune_export_');
    final outsideRoot = await Directory.systemTemp.createTemp('avelune_outside_');
    addTearDown(() => projectRoot.delete(recursive: true));
    addTearDown(() => exportRoot.delete(recursive: true));
    addTearDown(() => outsideRoot.delete(recursive: true));
    await GamePackageExportProfileStore(projectRoot: projectRoot).save(_profile());
    final api = await LocalGamePackageExportApi.create(
      allowedProjectRoots: <String>[projectRoot.path],
      allowedExportRoots: <String>[exportRoot.path],
      exportService: CanonicalGamePackageExportService(
        pokemonValidator: _acceptPokemonProjection,
      ),
    );

    await expectLater(
      api.export(
        projectRoot: projectRoot.path,
        outputPath: p.join(outsideRoot.path, 'escape.avelunegame'),
      ),
      throwsA(
        isA<GamePackageExportException>().having(
          (error) => error.code,
          'code',
          'exportPathOutsideAllowedRoots',
        ),
      ),
    );
  });
}

Future<Directory> _createPlayableProject() async {
  final root = await Directory.systemTemp.createTemp('authoring_export_');
  final project = ProjectManifest(
    name: 'Export Fixture',
    maps: const <ProjectMapEntry>[
      ProjectMapEntry(
        id: 'map.start',
        name: 'Start',
        relativePath: 'maps/start.json',
      ),
    ],
    tilesets: const <ProjectTilesetEntry>[],
    scenes: <SceneAsset>[_completionScene()],
    eventRegistry: NarrativeEventRegistry(
      schemaVersion: 1,
      mode: EventSystemMode.v2Only,
      records: <NarrativeEventRecord>[
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
    newGame: const ProjectNewGameConfig(
      enabled: true,
      startMapId: 'map.start',
      startSpawnId: 'spawn.player',
      playerName: 'Player',
      initialParty: <PlayerPokemon>[
        PlayerPokemon(
          speciesId: 'fixture.partner',
          formId: 'partner',
          natureId: 'hardy',
          abilityId: 'steadfast',
          level: 5,
          currentHp: 20,
        ),
      ],
    ),
    pokemon: const ProjectPokemonConfig(
      enabled: true,
      ruleset: PokemonRulesetProfile.pokeMapBetaV1,
    ),
  );
  await File(p.join(root.path, 'project.json')).writeAsString(
    jsonEncode(project.toJson()),
    flush: true,
  );
  await Directory(p.join(root.path, 'maps')).create(recursive: true);
  await File(p.join(root.path, 'maps', 'start.json')).writeAsString(
    jsonEncode(
      const MapData(
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
      ).toJson(),
    ),
    flush: true,
  );
  await Directory(
    p.join(root.path, 'data', 'pokemon', 'species'),
  ).create(recursive: true);
  await File(
    p.join(root.path, 'data', 'pokemon', 'species', 'fixture.json'),
  ).writeAsString('{"id":"fixture.partner"}', flush: true);
  await Directory(
    p.join(root.path, 'data', 'pokemon', 'catalogs'),
  ).create(recursive: true);
  await File(
    p.join(root.path, 'data', 'pokemon', 'catalogs', 'moves.json'),
  ).writeAsString('{"entries":[]}', flush: true);
  return root;
}

Future<PokemonCatalogCoherenceReport> _acceptPokemonProjection({
  required ProjectFileReader reader,
  required String projectRoot,
  required ProjectManifest manifest,
}) async =>
    PokemonCatalogCoherenceReport(const <PokemonCatalogDiagnostic>[]);

SceneAsset _completionScene() => SceneAsset(
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
                  title: SceneLocalizedText(fallback: 'Complete'),
                  summary: SceneLocalizedText(fallback: 'Done'),
                ),
                postGamePolicy: ScenePostGamePolicy.returnToTitle,
              ),
            ),
          ),
          SceneNode(
            id: 'end',
            kind: SceneNodeKind.end,
            payload: SceneEndPayload(
              outcomePolicy: SceneOutcomePolicy.progression,
            ),
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

GamePackageExportProfile _profile() => GamePackageExportProfile(
      gameId: 'games.example.authoring-export',
      gameVersion: '1.0.0',
      title: 'Authoring Export',
      authorName: 'PokeMap',
      defaultLocale: 'fr',
      supportedLocales: const <String>['fr'],
    );
