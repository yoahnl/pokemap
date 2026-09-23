import 'dart:convert';
import 'dart:io';

import 'package:avelune_studio/presentation/features/game_export/studio_game_export_page.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_distribution/map_distribution.dart';
import 'package:map_runtime/map_runtime.dart';
import 'package:path/path.dart' as p;
import 'package:pokemap_hub/pokemap_hub.dart';
import 'package:pokemap_hub/features/session/data/repositories/installed_game_launch_resolver.dart';
import 'package:pub_semver/pub_semver.dart';

import '../../../../avelune_studio/test/support/game_export_fixture.dart';
import '../../../../avelune_studio/test/support/map_host_fixture.dart';
import '../../../../avelune_studio/test/support/m2_ui_fixture.dart' show pumpIo;

void main() {
  testWidgets(
    'Studio package installs and plays from Avelune Player storage',
    (tester) async {
      final temporary =
          (await tester.runAsync(
            () => Directory.systemTemp.createTemp('as-exp-player-'),
          ))!;
      addTearDown(() => temporary.delete(recursive: true));
      final packageFile = File(p.join(temporary.path, 'demo.avelunegame'));
      final author = await MapHostFixture.open(
        tester,
        prepareSource: prepareGameExportFixture,
        gameExportPicker: (_) async => packageFile,
        assetBundle: _StudioAssetBundle(),
      );
      final before = await author.disk();
      await author.openExport();
      await tester.enterText(
        find.widgetWithText(TextField, 'Auteur'),
        'Avelune',
      );
      await tester.tap(find.byKey(const ValueKey('start-game-export')));
      await pumpIo(tester, frames: 120);
      expect(
        find.text('Dernier paquet produit'),
        findsOneWidget,
        reason:
            tester
                .widget<StudioGameExportPage>(find.byType(StudioGameExportPage))
                .controller
                .error,
      );
      expect(await tester.runAsync(packageFile.exists), isTrue);
      expect(await author.disk(), before);
      await tester.pumpWidget(const SizedBox());

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
        final manifest = ProjectManifest.fromJson(
          jsonDecode(await installedProject.readAsString())
              as Map<String, dynamic>,
        );
        expect(manifest.maps, hasLength(2));
        final bundle = await loadRuntimeMapBundle(
          projectFilePath: installedProject.path,
          mapId: manifest.newGame.startMapId,
        );
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
        expect(
          game.gameStateSnapshot.playerPosition,
          const GridPos(x: 8, y: 8),
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
        await packageFile.copy('/tmp/avelune_as_exp_001_demo.avelunegame');
      });
    },
    timeout: const Timeout(Duration(minutes: 5)),
  );
}

GamePackageHostCompatibility _compatibility() => GamePackageHostCompatibility(
  hubVersion: Version.parse('1.2.0'),
  runtimeApiVersion: Version.parse('1.4.0'),
  capabilities: const {
    'dialogue.choices@1',
    'map@1',
    'overworld.menu@1',
    'world.shop@1',
  },
  supportedProjectFormats: const {'v6', 'v7'},
  currentProjectFormat: 'v6',
  supportedSaveFormats: const {1},
);

class _InstalledDemoGame extends PlayableMapGame {
  _InstalledDemoGame({required super.bundle, required super.projectFilePath});
  @override
  bool get isLoaded => true;
}

class _StudioAssetBundle extends CachingAssetBundle {
  @override
  Future<ByteData> load(String key) async {
    if (key.startsWith('assets/home/')) {
      final bytes =
          await File(
            p.join(Directory.current.path, '../avelune_studio', key),
          ).readAsBytes();
      return ByteData.sublistView(Uint8List.fromList(bytes));
    }
    return rootBundle.load(key);
  }
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
