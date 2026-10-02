import 'dart:io';
import 'dart:ui' as ui;

import 'package:crypto/crypto.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_distribution/map_distribution.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:map_runtime/map_runtime.dart';
import 'package:path/path.dart' as p;
import 'package:pokemap_hub/pokemap_hub_player.dart';
import 'package:pub_semver/pub_semver.dart';

import '../../../../avelune_studio/test/support/m2_ui_fixture.dart' show pumpIo;
import 'uwu5_specialized_resources_player_movement.dart';

Future<void> playUwu5InstalledPackage(
  WidgetTester tester,
  File package,
  Directory temporary, {
  required ProjectManifest authored,
  required MapData authoredMap,
}) async {
  final support = Directory(p.join(temporary.path, 'player'));
  late PlayableMapGame game;
  late String installedRoot;
  final adapter =
      (await tester.runAsync(() async {
        final installed = await GamePackageInstaller(
          supportRoot: support,
          inspector: GamePackageInspector(hostCompatibility: _compatibility()),
          availableDiskBytes: (_) async => 1024 * 1024 * 1024,
          loadSmoke: (root, _) async {
            final loaded = await loadRuntimeMapBundle(
              projectFilePath: p.join(root.path, 'project', 'project.json'),
              mapId: authored.newGame.startMapId,
            );
            expect(loaded.map, authoredMap);
          },
          prepareSavesForUpdate: (_, _) async => const SaveUpdatePreparation(),
        ).install(package, source: GamePackageInstallSource.localFile);
        final launch = await InstalledGameLaunchResolver(
          supportRoot: support,
          hostCompatibility: _compatibility(),
        ).resolve(installed.game);
        final projectFile = await launch.assets.resolveReference(
          launch.project,
        );
        installedRoot = await support.resolveSymbolicLinks();
        expect(p.isWithin(installedRoot, projectFile.path), true);
        final bundle = await loadRuntimeMapBundle(
          projectFilePath: projectFile.path,
          mapId: authored.newGame.startMapId,
        );
        expect(bundle.manifest.smartTileCatalog, authored.smartTileCatalog);
        expect(bundle.manifest.borderCatalog, authored.borderCatalog);
        expect(bundle.manifest.characters, authored.characters);
        expect(
          bundle.manifest.characters.any((entry) => entry.id == 'guide'),
          false,
        );
        expect(
          bundle.manifest.settings.defaultPlayerCharacterId,
          'uwu5-replacement',
        );
        expect(
          bundle.map.layers.whereType<SmartTileLayer>().single.presetId,
          'uwu5-path',
        );
        expect(
          bundle.map.layers
              .whereType<BorderLayer>()
              .single
              .content
              .features
              .single,
          authoredMap.layers
              .whereType<BorderLayer>()
              .single
              .content
              .features
              .single,
        );
        final npcIds =
            bundle.map.entities
                .where((entity) => entity.npc != null)
                .map((entity) => entity.npc!.characterId)
                .toSet();
        expect(npcIds, {'uwu5-replacement'});
        final dialogue = bundle.manifest.dialogues.single;
        final dialogueBytes =
            await File(
              p.join(bundle.projectRootDirectory, dialogue.relativePath),
            ).readAsBytes();
        final compiled = const RuntimeDialogueDocumentCodec().decodeUtf8(
          dialogueBytes,
        );
        final line =
            compiled.nodes.single.steps.whereType<RuntimeDialogueLine>().single;
        expect(line.characterId, 'uwu5-replacement');
        expect(line.portraitStateId, 'neutral');
        expect(line.text, 'Bienvenue sur le quai.');
        final descriptor = GameSessionDescriptor(
          sessionId: 'uwu5-session',
          sessionToken: 'uwu5-token',
          identity: launch.identity,
          profileId: 'local',
          slotId: 'slot-1',
          launchMode: GameSessionLaunchMode.newGame,
          installedVersionHandle: launch.installedVersionHandle,
          runtimeApiVersion: launch.runtimeApiVersion,
          grantedCapabilities: launch.grantedCapabilities,
          locale: 'fr',
          accessibility: const GameSessionAccessibilityOptions(),
          initialGameState: createNewGameStateFromProject(
            project: bundle.manifest,
            startMap: bundle.map,
            saveId: 'uwu5-installed',
            tileWidthPx: bundle.manifest.settings.tileWidth,
            tileHeightPx: bundle.manifest.settings.tileHeight,
          ),
        );
        final adapter = HubInProcessSessionFactory(
          launch: launch,
          saves: HubSaveStore(supportRoot: support, identity: launch.identity),
          mountGame: (mounted) async {
            game = mounted;
          },
          unmountGame: (_) async {},
        ).call(descriptor);
        await adapter.prepare(descriptor);
        await adapter.start();
        print(
          'UWU5_PACKAGE_SHA256=${sha256.convert(await package.readAsBytes())}',
        );
        return adapter;
      }))!;
  addTearDown(() => tester.runAsync(adapter.dispose));
  final capture = GlobalKey();
  await tester.pumpWidget(
    RepaintBoundary(
      key: capture,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        home: GameWidget(game: game),
      ),
    ),
  );
  await pumpIo(tester, frames: 40);
  await tester.runAsync(() async {
    await game.toBeLoaded();
    await _until(
      game,
      () =>
          !game.debugIsMapActivationDispatchInFlight &&
          !game.inputAuthoritySnapshot.isGameplayLocked,
    );
  });
  await tester.pump();
  await _captureAndCheckPixels(tester, capture);
  await tester.runAsync(() async {
    expect(
      game.handleRuntimeInputEvent(
        const RuntimeInputEvent.press(RuntimeInputControl.up),
      ),
      true,
    );
    game.update(.016);
    game.handleRuntimeInputEvent(
      const RuntimeInputEvent.release(RuntimeInputControl.up),
    );
    await _until(game, () => game.debugFlowPhaseName == 'dialogue');
    expect(game.gameStateSnapshot.playerPosition, const GridPos(x: 8, y: 8));
  });
  for (
    var i = 0;
    i < 20 && game.dialoguePresentationListenable.value == null;
    i++
  ) {
    await pumpIo(tester, frames: 2);
  }
  final dialogue = game.dialoguePresentationListenable.value;
  expect(dialogue, isNotNull);
  expect(dialogue!.fullText, contains('Bienvenue sur le quai'));
  final portrait = dialogue.portrait;
  expect(portrait, isNotNull);
  expect(portrait!.characterId, 'uwu5-replacement');
  expect(p.isWithin(installedRoot, portrait.absoluteFilePath), true);
  expect(
    await tester.runAsync(() => File(portrait.absoluteFilePath).exists()),
    true,
  );
  print(
    'UWU5_INSTALLED_DIALOGUE_PORTRAIT=${portrait.characterId}:${portrait.portraitStateId}',
  );
  await tester.runAsync(() async {
    for (var i = 0; i < 8 && game.debugFlowPhaseName == 'dialogue'; i++) {
      game.update(2);
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
  });
  await pumpIo(tester, frames: 4);
  await tester.runAsync(() => verifyUwu5InstalledMovement(game));
  expect(game.gameStateSnapshot.currentMapId, authored.newGame.startMapId);
  await tester.pumpWidget(const SizedBox());
  await tester.runAsync(adapter.dispose);
}

Future<void> _captureAndCheckPixels(WidgetTester tester, GlobalKey key) async {
  await tester.runAsync(() async {
    final boundary =
        key.currentContext!.findRenderObject() as RenderRepaintBoundary;
    final frame = await boundary.toImage(pixelRatio: 1);
    try {
      final rgba =
          (await frame.toByteData(format: ui.ImageByteFormat.rawRgba))!;
      var terrain = 0, border = 0;
      for (var i = 0; i < rgba.lengthInBytes; i += 4) {
        if (rgba.getUint8(i + 3) != 255) continue;
        if (rgba.getUint8(i) == 25 &&
            rgba.getUint8(i + 1) == 211 &&
            rgba.getUint8(i + 2) == 181) {
          terrain++;
        }
        if (rgba.getUint8(i) == 241 &&
            rgba.getUint8(i + 1) == 117 &&
            rgba.getUint8(i + 2) == 23) {
          border++;
        }
      }
      expect(
        terrain,
        greaterThan(100),
        reason: 'Installed terrain must render.',
      );
      expect(
        border,
        greaterThan(100),
        reason: 'Placed deprecated border must render.',
      );
      print('UWU5_INSTALLED_TERRAIN_PIXELS=$terrain');
      print('UWU5_INSTALLED_DEPRECATED_BORDER_PIXELS=$border');
      final evidence = Platform.environment['UWU5_CAPTURE_DIR'];
      if (evidence != null) {
        final png = await frame.toByteData(format: ui.ImageByteFormat.png);
        await Directory(evidence).create(recursive: true);
        await File(
          p.join(evidence, 'uwu5-installed-specialized-resources.png'),
        ).writeAsBytes(png!.buffer.asUint8List());
      }
    } finally {
      frame.dispose();
    }
  });
}

Future<void> _until(PlayableMapGame game, bool Function() done) async {
  for (var i = 0; i < 300; i++) {
    if (done()) return;
    game.update(.016);
    await Future<void>.delayed(Duration.zero);
  }
  throw StateError('Installed Player did not reach the expected state.');
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
  supportedProjectFormats: const {'v8'},
  currentProjectFormat: 'v8',
  supportedSaveFormats: const {1},
);
