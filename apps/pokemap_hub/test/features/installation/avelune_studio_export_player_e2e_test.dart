import 'dart:convert';
import 'dart:io';

import 'package:flame/game.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_distribution/map_distribution.dart';
import 'package:map_runtime/map_runtime.dart';
import 'package:path/path.dart' as p;
import 'package:pokemap_hub/pokemap_hub.dart';
import 'package:pokemap_hub/features/session/data/repositories/installed_game_launch_resolver.dart';

import '../../../../avelune_studio/test/support/game_export_fixture.dart';
import '../../../../avelune_studio/test/support/authoring_export_fixture.dart';

void main() {
  testWidgets('Studio export plays its cinematic in Player', (tester) async {
    final temporary = (await tester.runAsync(
      () => Directory.systemTemp.createTemp('as-exp-player-'),
    ))!;
    addTearDown(() => temporary.delete(recursive: true));
    final packageFile = File(p.join(temporary.path, 'demo.avelunegame'));
    late MapData expectedMap;
    late ProjectManifest expectedProject;
    late SceneAsset expectedArrivalScene;
    late CinematicAsset expectedCinematic;
    void expectTransformedBundle(RuntimeMapBundle bundle) {
      expect(bundle.manifest.version, ProjectVersion.v8);
      expect(bundle.map.placedElements, expectedMap.placedElements);
      expect(bundle.manifest.tilesets, expectedProject.tilesets);
      expect(bundle.manifest.elements, expectedProject.elements);
      final arrivalScene = bundle.manifest.scenes.singleWhere(
        (scene) => scene.id == expectedArrivalScene.id,
      );
      expect(arrivalScene.graph, expectedArrivalScene.graph);
      expect(
        bundle.manifest.cinematics
            .singleWhere((cinematic) => cinematic.id == expectedCinematic.id)
            .toJson(),
        expectedCinematic.toJson(),
      );
      expect(bundle.manifest.toJson(), isNot(contains('shadowCatalog')));
      expect(
        bundle.manifest.toJson(),
        isNot(contains('projectedBuildingShadowCatalog')),
      );
      final placed = bundle.map.placedElements.first;
      final geometry = resolveMapPlacedElementGeometry(
        instance: placed,
        element: bundle.manifest.elements.firstWhere(
          (e) => e.id == placed.elementId,
        ),
        tileSize: PixelSize(
          width: bundle.manifest.settings.tileWidth,
          height: bundle.manifest.settings.tileHeight,
        ),
      );
      expect(geometry.pixelSize, const PixelSize(width: 29, height: 17));
      expect(
        geometry.logicalRect.leftPx,
        placed.pos.x * bundle.manifest.settings.tileWidth + 3,
      );
      expect(
        geometry.logicalRect.topPx,
        placed.pos.y * bundle.manifest.settings.tileHeight + 5,
      );
      expect(placed.quarterTurns, 1);
    }

    final author = await AuthoringExportFixture.open(
      tester,
      prepareSource: (source) async {
        await prepareGameExportFixture(source);
        final projectFile = File(p.join(source.directory.path, 'project.json'));
        final project = ProjectManifest.fromJson(
          jsonDecode(await projectFile.readAsString()) as Map<String, dynamic>,
        );
        final mapFile = File(
          p.join(source.directory.path, project.maps.first.relativePath),
        );
        final map = MapData.fromJson(
          jsonDecode(await mapFile.readAsString()) as Map<String, dynamic>,
        );
        expectedCinematic = CinematicAsset(
          id: 'quay_welcome',
          title: 'Arrivée sur le quai',
          mapId: map.id,
          timeline: CinematicTimeline(
            steps: [
              CinematicTimelineStep(
                id: 'welcome',
                kind: CinematicTimelineStepKind.dialogueLine,
                dialogueText: _cinematicLine,
              ),
            ],
          ),
        );
        final withCinematic = project.copyWith(
          cinematics: [...project.cinematics, expectedCinematic],
        );
        final arrival = project.scenes.singleWhere(
          (scene) => scene.graph.nodes
              .map((node) => node.payload)
              .whereType<SceneYarnDialoguePayload>()
              .any((payload) => payload.dialogueId == 'zone'),
        );
        expectedArrivalScene = _insertArrivalCinematic(
          withCinematic,
          arrival,
          expectedCinematic.id,
        );
        expectedMap = map.copyWith(
          placedElements: [
            map.placedElements.first.copyWith(
              pixelOffset: const PixelOffset(x: 3, y: 5),
              pixelSize: const PixelSize(width: 29, height: 17),
              quarterTurns: 1,
              visualOrder: 4,
              properties: const {
                pokemapPlacementOriginProperty: pokemapPlacementOriginAuthored,
              },
            ),
            ...map.placedElements.skip(1),
          ],
        );
        expectedProject = withCinematic.copyWith(
          scenes: [
            for (final scene in project.scenes)
              scene.id == arrival.id ? expectedArrivalScene : scene,
          ],
          tilesets: [
            project.tilesets.first.copyWith(
              source: const ProjectTilesetSource.regularAtlas(
                assetId: 'atelier',
                pixelWidth: 160,
                pixelHeight: 64,
                tileWidth: 16,
                tileHeight: 16,
                pixelOffsetX: 2,
                pixelOffsetY: -1,
              ),
            ),
          ],
        );
        await mapFile.writeAsString(
          jsonEncode(expectedMap.toJson()),
          flush: true,
        );
        await projectFile.writeAsString(
          jsonEncode(expectedProject.toJson()),
          flush: true,
        );
      },
    );
    final before = await author.disk();
    await author.export(packageFile);
    expect(await tester.runAsync(packageFile.exists), isTrue);
    expect(await author.disk(), before);

    final source = author.source.directory;
    final hiddenSource = Directory('${source.path}.offline');
    await tester.runAsync(() => source.rename(hiddenSource.path));
    addTearDown(() async {
      if (await hiddenSource.exists()) {
        await hiddenSource.delete(recursive: true);
      }
    });
    expect(await tester.runAsync(source.exists), isFalse);

    await tester.runAsync(() async {
      final support = Directory(p.join(temporary.path, 'player'));
      final inspector = GamePackageInspector(
        hostCompatibility: _compatibility(),
      );
      final installed = await GamePackageInstaller(
        supportRoot: support,
        inspector: inspector,
        availableDiskBytes: (_) async => 2 * 1024 * 1024 * 1024,
        loadSmoke: (root, manifest) async {
          final bundle = await loadRuntimeMapBundle(
            projectFilePath: p.join(root.path, 'project', 'project.json'),
            mapId: 'jardin',
          );
          expect(bundle.map.id, 'jardin');
          expectTransformedBundle(bundle);
        },
        prepareSavesForUpdate: (_, _) async => const SaveUpdatePreparation(),
      ).install(packageFile, source: GamePackageInstallSource.localFile);
      final launch = await InstalledGameLaunchResolver(
        supportRoot: support,
        hostCompatibility: _compatibility(),
      ).resolve(installed.game);
      final installedProject = await launch.assets.resolveReference(
        launch.project,
      );
      expect(installedProject.path, isNot(source.path));
      final manifest = await loadProjectManifestFromFile(installedProject.path);
      expect(manifest.maps, hasLength(2));
      final bundle = await loadRuntimeMapBundle(
        projectFilePath: installedProject.path,
        mapId: manifest.newGame.startMapId,
      );
      expectTransformedBundle(bundle);
      final game = PlayableMapGame(
        bundle: bundle,
        projectFilePath: installedProject.path,
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
      await game.loaded;
      await tester.pump();
      await _until(
        game,
        () =>
            !game.debugIsMapActivationDispatchInFlight &&
            !game.inputAuthoritySnapshot.isGameplayLocked,
      );
      await _move(game, RuntimeInputControl.up);
      expect(game.gameStateSnapshot.playerPosition, const GridPos(x: 8, y: 8));
      await _until(
        game,
        () => game.debugCinematicDialogueLine == _cinematicLine,
      );
      expect(
        game.inputAuthoritySnapshot.context,
        RuntimeInputContext.cinematic,
      );
      game.handleRuntimeInputEvent(
        const RuntimeInputEvent.press(RuntimeInputControl.primary),
      );
      game.update(.016);
      game.handleRuntimeInputEvent(
        const RuntimeInputEvent.release(RuntimeInputControl.primary),
      );
      await _until(game, () => game.debugFlowPhaseName == 'dialogue');
      expect(game.gameStateSnapshot.currentMapId, 'jardin');
      for (var i = 0; i < 10 && game.debugFlowPhaseName == 'dialogue'; i++) {
        game.handleRuntimeInputEvent(
          const RuntimeInputEvent.press(RuntimeInputControl.primary),
        );
        game.update(.016);
        game.handleRuntimeInputEvent(
          const RuntimeInputEvent.release(RuntimeInputControl.primary),
        );
        await Future<void>.delayed(Duration.zero);
      }
      await _until(game, () => game.debugFlowPhaseName == 'overworld');
      await _move(game, RuntimeInputControl.down);
      await _move(game, RuntimeInputControl.right);
      await _until(
        game,
        () => game.gameStateSnapshot.currentMapId == 'clairiere',
      );
      expect(game.gameStateSnapshot.currentMapId, 'clairiere');
    });
  }, timeout: const Timeout(Duration(minutes: 5)));
}

const _cinematicLine = 'Le départ approche.';

SceneAsset _insertArrivalCinematic(
  ProjectManifest project,
  SceneAsset scene,
  String cinematicId,
) {
  final startId = scene.graph.startNodeId;
  final entry = scene.graph.edges.singleWhere(
    (edge) => edge.fromNodeId == startId,
  );
  final arrival = addSceneCinematicNodeDraft(
    scene,
    project: project,
    cinematicId: cinematicId,
    afterNodeId: startId,
  );
  final detached = removeSceneEdgeDraft(arrival.updatedScene, entry.id);
  final incoming = addSceneEdgeDraft(
    detached.updatedScene,
    fromNodeId: startId,
    fromPortId: entry.fromPortId,
    toNodeId: arrival.createdNode.id,
  );
  return addSceneEdgeDraft(
    incoming.updatedScene,
    fromNodeId: arrival.createdNode.id,
    fromPortId: 'completed',
    toNodeId: entry.toNodeId,
  ).updatedScene;
}

GamePackageHostCompatibility _compatibility() =>
    AveluneRuntimeCompatibility.host();

Future<void> _move(PlayableMapGame game, RuntimeInputControl direction) async {
  expect(
    game.handleRuntimeInputEvent(RuntimeInputEvent.press(direction)),
    isTrue,
  );
  game.update(.016);
  expect(
    game.handleRuntimeInputEvent(RuntimeInputEvent.release(direction)),
    isTrue,
  );
  await _until(
    game,
    () => !game.debugIsPlayerStepping && !game.debugHasPendingMapTransition,
  );
}

Future<void> _until(PlayableMapGame game, bool Function() done) async {
  for (var i = 0; i < 300; i++) {
    if (done()) return;
    game.update(.016);
    await Future<void>.delayed(Duration.zero);
  }
  throw StateError(
    'Phase ${game.debugFlowPhaseName}, verrou ${game.inputAuthoritySnapshot.context}, '
    'déclenchement ${game.debugIsNarrativeSpatialDispatchInFlight}, '
    'cinématique ${game.debugIsCinematicPlaying}, '
    'ligne ${game.debugCinematicDialogueLine}.',
  );
}
