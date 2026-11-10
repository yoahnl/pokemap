import 'dart:convert';
import 'dart:io';

import 'package:flame/components.dart';
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
  testWidgets('Studio package installs and plays from Avelune Player storage', (
    tester,
  ) async {
    final temporary = (await tester.runAsync(
      () => Directory.systemTemp.createTemp('as-exp-player-'),
    ))!;
    addTearDown(() => temporary.delete(recursive: true));
    final packageFile = File(p.join(temporary.path, 'demo.avelunegame'));
    late MapData expectedMap;
    late ProjectManifest expectedProject;
    void expectTransformedBundle(RuntimeMapBundle bundle) {
      expect(bundle.manifest.version, ProjectVersion.v8);
      expect(bundle.map.placedElements, expectedMap.placedElements);
      expect(bundle.manifest.tilesets, expectedProject.tilesets);
      expect(bundle.manifest.elements, expectedProject.elements);
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
        expectedProject = project.copyWith(
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
      final game = _InstalledDemoGame(
        bundle: bundle,
        projectFilePath: installedProject.path,
      );
      game.onGameResize(Vector2(640, 480));
      await game.onLoad();
      addTearDown(game.onRemove);
      await _until(
        game,
        () =>
            !game.debugIsMapActivationDispatchInFlight &&
            !game.inputAuthoritySnapshot.isGameplayLocked,
      );
      await _move(game, RuntimeInputControl.up);
      expect(game.gameStateSnapshot.playerPosition, const GridPos(x: 8, y: 8));
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

GamePackageHostCompatibility _compatibility() =>
    AveluneRuntimeCompatibility.host();

class _InstalledDemoGame extends PlayableMapGame {
  _InstalledDemoGame({required super.bundle, required super.projectFilePath});
  @override
  bool get isLoaded => true;
}

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
  throw StateError('Le parcours Player n’a pas atteint l’état attendu.');
}
