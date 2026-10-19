import 'dart:convert';
import 'dart:io';

import 'package:flame/game.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_distribution/map_distribution.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:map_runtime/map_runtime.dart';
import 'package:map_runtime/src/application/narrative_runtime_activity_gate.dart';
import 'package:path/path.dart' as p;
import 'package:pokemap_hub/pokemap_hub_player.dart';
import 'package:pub_semver/pub_semver.dart';

void main() {
  testWidgets(
    'installed WhiteOut recovers the mounted Player and checkpoints before a fresh reload',
    (tester) async {
      final fixture = await tester.runAsync(() async {
        final root = await Directory.systemTemp.createTemp('l24-installed-');
        addTearDown(() => root.delete(recursive: true));
        final command = SceneInteractiveCommand.fromJson({'kind': 'whiteOut'});
        final project = ProjectManifest(
          name: 'Generic recovery fixture',
          maps: const [
            ProjectMapEntry(
              id: 'field',
              name: 'Field',
              relativePath: 'field.json',
            ),
          ],
          tilesets: const [],
          scenes: [
            SceneAsset(
              id: 'recovery',
              name: 'Recovery',
              graph: SceneGraph(
                startNodeId: 'start',
                nodes: [
                  SceneNode(id: 'start', kind: SceneNodeKind.start),
                  SceneNode(
                    id: 'whiteout',
                    kind: SceneNodeKind.action,
                    payload: SceneActionPayload.interactive(command),
                  ),
                  SceneNode(id: 'end', kind: SceneNodeKind.end),
                ],
                edges: [
                  SceneEdge(
                    id: 'entry',
                    fromNodeId: 'start',
                    fromPortId: 'completed',
                    toNodeId: 'whiteout',
                    kind: SceneEdgeKind.defaultFlow,
                  ),
                  SceneEdge(
                    id: 'finish',
                    fromNodeId: 'whiteout',
                    fromPortId: 'completed',
                    toNodeId: 'end',
                    kind: SceneEdgeKind.actionCompleted,
                  ),
                ],
              ),
            ),
          ],
        );
        const map = MapData(
          id: 'field',
          name: 'Field',
          size: GridSize(width: 4, height: 4),
          entities: [
            MapEntity(
              id: 'start',
              name: 'Start',
              kind: MapEntityKind.spawn,
              pos: GridPos(x: 0, y: 0),
              blocksMovement: false,
              spawn: MapEntitySpawnData(
                role: EntitySpawnRole.playerStart,
                facing: EntityFacing.south,
              ),
            ),
          ],
          mapMetadata: MapMetadata(defaultSpawnId: 'start'),
        );
        final built = const GamePackageBuilder().build(
          manifest: _packageManifest(project.version.name),
          payloadFiles: {
            'project/project.json': utf8.encode(jsonEncode(project.toJson())),
            'project/field.json': utf8.encode(jsonEncode(map.toJson())),
          },
        );
        final archive = File(p.join(root.path, 'recovery.avelunegame'));
        await archive.writeAsBytes(built.packageBytes, flush: true);
        final support = Directory(p.join(root.path, 'support'));
        final compatibility = _compatibility(project.version.name);
        final installed = await GamePackageInstaller(
          supportRoot: support,
          inspector: GamePackageInspector(hostCompatibility: compatibility),
          availableDiskBytes: (_) async => 1024 * 1024 * 1024,
          loadSmoke: (staged, _) async {
            final bundle = await loadRuntimeMapBundle(
              projectFilePath: p.join(staged.path, 'project', 'project.json'),
              mapId: 'field',
            );
            bundle.projectCatalog?.dispose();
          },
          prepareSavesForUpdate: (_, _) async => const SaveUpdatePreparation(),
        ).install(archive, source: GamePackageInstallSource.localExport);
        final launch = await InstalledGameLaunchResolver(
          supportRoot: support,
          hostCompatibility: compatibility,
        ).resolve(installed.game);
        final projectFile = await launch.assets.resolveReference(
          launch.project,
        );
        final bundle = await loadRuntimeMapBundle(
          projectFilePath: projectFile.path,
          mapId: 'field',
        );
        addTearDown(() => bundle.projectCatalog?.dispose());
        return (
          bundle: bundle,
          projectFile: projectFile.path,
          save: File(p.join(root.path, 'player-save.json')),
          archive: archive,
          archiveBefore: built.packageBytes,
          installedBefore: await File(projectFile.path).readAsBytes(),
        );
      });
      expect(fixture, isNotNull);
      final installed = fixture!;
      final payload =
          installed.bundle.manifest.scenes.single.graph.nodes[1].payload
              as SceneActionPayload;
      expect(payload.interactiveCommand!.toJson(), {'kind': 'whiteOut'});
      final gate = NarrativeRuntimeActivityGate();
      final repository = _LocalSaveRepository(installed.save, gate);
      const initial = GameState(
        saveId: 'installed-recovery',
        currentMapId: 'field',
        playerPosition: GridPos(x: 0, y: 0),
        trainerProfile: TrainerProfile(name: 'Player', money: 1000),
        party: PlayerParty(
          members: [
            PlayerPokemon(
              speciesId: 'creature',
              level: 10,
              natureId: 'hardy',
              abilityId: 'ability',
              knownMoveIds: ['pulse'],
              currentPpByMoveId: {'pulse': 0},
              currentHp: 0,
              statusId: 'poison',
            ),
          ],
        ),
        metadata: {
          playerRecoveryMapIdMetadataKey: 'field',
          playerRecoveryPositionXMetadataKey: '2',
          playerRecoveryPositionYMetadataKey: '2',
          playerRecoveryFacingMetadataKey: 'east',
        },
      );
      var checkpointRequests = 0;
      var checkpointSaved = false;
      late PlayableMapGame game;
      game = PlayableMapGame(
        bundle: installed.bundle,
        projectFilePath: installed.projectFile,
        saveData: saveDataFromGameState(initial),
        saveRepository: repository,
        narrativeRuntimeActivityGate: gate,
        runtimePlayerPokemonProgressionCatalogLoader: _catalogs,
        defeatRecoveryCapsLoader: (_) async =>
            const RuntimePlayerServiceRecoveryCaps(
              maxHpByPartyIndex: {0: 20},
              maxPpByPartyIndex: {
                0: {'pulse': 15},
              },
            ),
        defeatRecoveryCheckpointEmitter: () async {
          expect(gate.activity, NarrativeRuntimeActivity.idle);
          expect(game.canCapturePlayerCheckpoint, isTrue);
          checkpointRequests++;
          expect(await game.saveGame(), isTrue);
          checkpointSaved = true;
        },
      );
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: SizedBox(
            width: 640,
            height: 480,
            child: GameWidget(game: game),
          ),
        ),
      );
      await _pumpUntil(tester, () => game.isLoaded);
      await _pumpUntil(
        tester,
        () => !game.debugIsMapActivationDispatchInFlight,
      );
      expect(game.isLoaded, isTrue);
      expect(game.isMounted, isTrue);
      expect(checkpointRequests, 0);
      final result = await tester.runAsync(
        () => game.debugExecuteNarrativeSceneForTest(
          NarrativeSceneExecutionRequest(
            eventId: 'installed-recovery-event',
            sceneId: 'recovery',
            executionId: 'installed-recovery-execution',
            gameState: game.gameStateSnapshot,
          ),
        ),
      );
      expect(result, isA<NarrativeSceneExecutionCompleted>());
      await _pumpUntil(tester, () => checkpointSaved);
      await tester.runAsync(() async {
        expect(await installed.save.exists(), isTrue);
      });
      final recovered = game.gameStateSnapshot;
      expect(recovered.currentMapId, 'field');
      expect(recovered.playerPosition, const GridPos(x: 2, y: 2));
      expect(recovered.playerFacing, EntityFacing.east);
      expect(recovered.party.members.single.currentHp, 20);
      expect(recovered.party.members.single.currentPpByMoveId, {'pulse': 15});
      expect(recovered.party.members.single.statusId, isEmpty);
      expect(recovered.trainerProfile.money, 900);
      expect(recovered.metadata[playerDefeatCountMetadataKey], '1');
      final freshGate = NarrativeRuntimeActivityGate();
      final freshRepository = _LocalSaveRepository(installed.save, freshGate);
      final saved = await tester.runAsync(freshRepository.load);
      expect(saved, isNotNull);
      final fresh = PlayableMapGame(
        bundle: installed.bundle,
        projectFilePath: installed.projectFile,
        initialMapActivationReason: MapActivationReason.saveRestore,
        saveData: saveDataFromGameState(saved!),
        saveRepository: freshRepository,
        narrativeRuntimeActivityGate: freshGate,
        runtimePlayerPokemonProgressionCatalogLoader: _catalogs,
      );
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: SizedBox(
            width: 640,
            height: 480,
            child: GameWidget(key: const ValueKey('reloaded'), game: fresh),
          ),
        ),
      );
      await _pumpUntil(tester, () => fresh.isLoaded);
      await _pumpUntil(
        tester,
        () => !fresh.debugIsMapActivationDispatchInFlight,
      );
      final restored = fresh.gameStateSnapshot;
      expect(fresh.isMounted, isTrue);
      expect(restored.party, recovered.party);
      expect(restored.trainerProfile, recovered.trainerProfile);
      expect(restored.playerPosition, recovered.playerPosition);
      expect(restored.playerFacing, recovered.playerFacing);
      expect(restored.metadata[playerDefeatCountMetadataKey], '1');
      expect(checkpointRequests, 1);
      await tester.runAsync(() async {
        expect(await installed.archive.readAsBytes(), installed.archiveBefore);
        expect(
          await File(installed.projectFile).readAsBytes(),
          installed.installedBefore,
        );
      });
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
}

Future<void> _pumpUntil(WidgetTester tester, bool Function() done) async {
  for (var attempt = 0; attempt < 240; attempt++) {
    if (done()) return;
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 1)),
    );
    await tester.pump(const Duration(milliseconds: 16));
  }
  fail('The mounted Player did not finish its recovery checkpoint.');
}

Future<RuntimePlayerPokemonProgressionCatalogs> _catalogs({
  required GameState gameState,
  required String projectRootDirectory,
  required ProjectPokemonConfig pokemonConfig,
}) async => const RuntimePlayerPokemonProgressionCatalogs(
  speciesById: {
    'creature': PlayerPokemonHydrationSpecies(
      id: 'creature',
      baseStats: PokemonBaseStats(
        hp: 40,
        attack: 40,
        defense: 40,
        specialAttack: 40,
        specialDefense: 40,
        speed: 40,
      ),
      primaryAbilityId: 'ability',
      abilityIds: ['ability'],
      growthRateId: 'medium_fast',
    ),
  },
  maxPpByMoveId: {'pulse': 15},
);

final class _LocalSaveRepository extends FileGameSaveRepository {
  _LocalSaveRepository(this.file, NarrativeRuntimeActivityGate gate)
    : super(activityGate: gate);

  final File file;

  @override
  Future<String> getSaveFilePath() async => file.path;
}

GamePackageHostCompatibility _compatibility(String format) =>
    GamePackageHostCompatibility(
      hubVersion: Version.parse('1.2.0'),
      runtimeApiVersion: Version.parse('1.4.0'),
      capabilities: const {'map@1', 'catalog.partitioned@2'},
      supportedProjectFormats: {format},
      currentProjectFormat: format,
      supportedSaveFormats: const {1},
    );

GamePackageManifest _packageManifest(String format) => GamePackageManifest(
  packageFormat: 1,
  gameId: 'games.example.recovery',
  gameVersion: Version.parse('1.0.0'),
  title: 'Recovery fixture',
  author: const GamePackageParty(name: 'Test'),
  compatibility: GamePackageCompatibility(
    minHubVersion: Version.parse('0.1.0'),
    runtimeApiExpression: '>=1.0.0 <2.0.0',
    projectFormat: format,
    saveFormat: 1,
    compatibilityId: 'main',
    requiredCapabilities: const ['map@1'],
  ),
  locales: GamePackageLocales(defaultLocale: 'en', supported: const ['en']),
  presentation: const GamePackagePresentation(),
  content: GamePackageContent(
    fileCount: 0,
    totalBytes: 0,
    treeSha256: '0' * 64,
    files: const [],
  ),
);
