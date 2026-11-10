import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:map_distribution/map_distribution.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:map_runtime/map_runtime.dart';
import 'package:map_runtime/map_runtime_authoring.dart';
import 'package:path/path.dart' as p;
import 'package:pokemap_hub/pokemap_hub_player.dart';

import '../../../../avelune_studio/test/support/real_test_io.dart';
import '../../../../avelune_studio/test/support/synthetic_player_recipe.dart'
    show playSyntheticTemplateRoute;

Future<void> playCreatedPackage(
  WidgetTester tester,
  File package,
  Directory temporary,
  ProjectManifest authored,
  int grid, {
  required Map<String, MapData> expectedMaps,
  Future<void> Function(PlayableMapGame, bool Function(RuntimeInputEvent))?
  beforeTemplateRoute,
}) async {
  final playerRoot = Directory(p.join(temporary.path, 'player'));
  late PlayableMapGame game;
  late GridPos initialPosition;
  final adapter = (await tester.runAsync(() async {
    ProjectManifest? smokeProject;
    final installed = await GamePackageInstaller(
      supportRoot: playerRoot,
      inspector: GamePackageInspector(hostCompatibility: _compatibility()),
      availableDiskBytes: (_) async => 1024 * 1024 * 1024,
      loadSmoke: (root, manifest) async {
        final bundle = await loadRuntimeMapBundle(
          projectFilePath: p.join(root.path, 'project', 'project.json'),
          mapId: authored.newGame.startMapId,
        );
        smokeProject = bundle.manifest;
      },
      prepareSavesForUpdate: (_, _) async => const SaveUpdatePreparation(),
    ).install(package, source: GamePackageInstallSource.localFile);
    expect(
      smokeProject,
      authored.copyWith(
        presentation:
            authored.presentation ?? const ProjectPresentationProfile(),
        dialogues: [
          for (final dialogue in authored.dialogues)
            dialogue.copyWith(
              relativePath: p.setExtension(dialogue.relativePath, '.json'),
            ),
        ],
      ),
    );
    final launch = await InstalledGameLaunchResolver(
      supportRoot: playerRoot,
      hostCompatibility: _compatibility(),
    ).resolve(installed.game);
    final projectFile = await launch.assets.resolveReference(launch.project);
    final installedRoot = await playerRoot.resolveSymbolicLinks();
    expect(p.isWithin(installedRoot, projectFile.path), isTrue);
    final bundle = await loadRuntimeMapBundle(
      projectFilePath: projectFile.path,
      mapId: authored.newGame.startMapId,
    );
    expect(bundle.manifest.settings.tileWidth, grid);
    expect(bundle.manifest.settings.tileHeight, grid);
    expect(bundle.manifest.maps.map((map) => map.id), expectedMaps.keys);
    expect(bundle.manifest.tilesets, isNotEmpty);
    final catalog = AssetCatalog.fromJson(
      jsonDecode(
        await File(p.join(bundle.projectRootDirectory, assetCatalogStorageKey))
            .readAsString(),
      ) as Map<String, dynamic>,
    );
    final atlasPaths = resolveTilesetAbsolutePaths(
      manifest: bundle.manifest,
      projectRoot: bundle.projectRootDirectory,
      tilesetIds: bundle.manifest.tilesets.map((entry) => entry.id).toSet(),
      assetCatalog: catalog,
    );
    for (final entry in bundle.manifest.maps) {
      final mapBundle = await loadRuntimeMapBundle(
        projectFilePath: projectFile.path,
        mapId: entry.id,
      );
      expect(mapBundle.map.id, entry.id);
      expect(mapBundle.map, expectedMaps[entry.id]);
      expect(p.isWithin(installedRoot, mapBundle.projectRootDirectory), isTrue);
      for (final path in mapBundle.runtimeImageAbsolutePathsById.values) {
        expect(p.isWithin(installedRoot, path), isTrue);
        expect(await File(path).exists(), isTrue);
      }
    }
    for (final atlas in bundle.manifest.tilesets) {
      final source = atlas.source as ProjectRegularAtlasTilesetSource;
      expect(source.tileWidth, grid);
      expect(source.tileHeight, grid);
      expect(p.isWithin(installedRoot, atlasPaths[atlas.id]!), isTrue);
      final codec = await ui.instantiateImageCodec(
        await File(atlasPaths[atlas.id]!).readAsBytes(),
      );
      final image = (await codec.getNextFrame()).image;
      expect(image.width, source.pixelWidth);
      expect(image.height, source.pixelHeight);
      image.dispose();
      codec.dispose();
    }
    expect(
      bundle.manifest.characters.map((character) => character.id),
      authored.characters.map((character) => character.id),
    );
    await _checkCharacterFrames(bundle);
    final initial = createNewGameStateFromProject(
      project: bundle.manifest,
      startMap: bundle.map,
      saveId: 'created-$grid',
      tileWidthPx: grid,
      tileHeightPx: grid,
    );
    initialPosition = initial.playerPosition;
    final descriptor = GameSessionDescriptor(
      sessionId: 'session-$grid',
      sessionToken: 'token-$grid',
      identity: launch.identity,
      profileId: 'local',
      slotId: 'slot-1',
      launchMode: GameSessionLaunchMode.newGame,
      installedVersionHandle: launch.installedVersionHandle,
      runtimeApiVersion: launch.runtimeApiVersion,
      grantedCapabilities: launch.grantedCapabilities,
      locale: 'fr',
      accessibility: const GameSessionAccessibilityOptions(),
      initialGameState: initial,
    );
    final adapter = HubInProcessSessionFactory(
      launch: launch,
      saves: HubSaveStore(supportRoot: playerRoot, identity: launch.identity),
      mountGame: (mounted) async {
        game = mounted;
      },
      unmountGame: (_) async {},
    ).call(descriptor);
    await adapter.prepare(descriptor);
    await adapter.start();
    return adapter;
  }))!;
  addTearDown(() async => tester.runAsync(adapter.dispose));
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
  await RealTestIo.pump(tester, frames: 40);
  await tester.runAsync(() async {
    await game.toBeLoaded();
    await _until(
      game,
      () =>
          !game.debugIsMapActivationDispatchInFlight &&
          !game.inputAuthoritySnapshot.isGameplayLocked,
    );
    expect(game.gameStateSnapshot.currentMapId, authored.newGame.startMapId);
    expect(game.gameStateSnapshot.playerPosition, initialPosition);
    expect(
      game.gameStateSnapshot.trainerProfile.avatarCharacterId,
      authored.settings.defaultPlayerCharacterId,
    );
  });
  await beforeTemplateRoute?.call(game, adapter.handleInput);
  await playSyntheticTemplateRoute(tester, game, input: adapter.handleInput);
  await tester.runAsync(() async {
    final checkpoint = await adapter.captureCheckpoint();
    expect(checkpoint, isNotNull);
  });
  final evidence = Platform.environment['AVELUNE_CAPTURE_DIR'];
  if (evidence != null) {
    await tester.pump();
    await tester.runAsync(() async {
      final boundary =
          capture.currentContext!.findRenderObject() as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 1);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      await Directory(evidence).create(recursive: true);
      await File(p.join(evidence, 'player-created-$grid.png'))
          .writeAsBytes(bytes!.buffer.asUint8List());
      image.dispose();
    });
  }
  await tester.pumpWidget(const SizedBox());
  await tester.runAsync(adapter.dispose);
}

Future<void> _until(PlayableMapGame game, bool Function() done) async {
  for (var i = 0; i < 300; i++) {
    if (done()) return;
    game.update(.016);
    await Future<void>.delayed(Duration.zero);
  }
  throw StateError('Le Player installé n’a pas terminé l’opération attendue.');
}

GamePackageHostCompatibility _compatibility() =>
    AveluneRuntimeCompatibility.host();
Future<void> _checkCharacterFrames(RuntimeMapBundle bundle) async {
  final imageSizes = <String, ui.Size>{};
  for (final entry in bundle.runtimeImageAbsolutePathsById.entries) {
    final codec = await ui.instantiateImageCodec(
      await File(entry.value).readAsBytes(),
    );
    final image = (await codec.getNextFrame()).image;
    imageSizes[entry.key] = ui.Size(
      image.width.toDouble(),
      image.height.toDouble(),
    );
    image.dispose();
    codec.dispose();
  }
  final resolver = CharacterAnimationSourceResolver();
  for (final character in bundle.manifest.characters) {
    for (final animation in character.animations) {
      expect(animation.frames, isNotEmpty);
      for (final frame in animation.frames) {
        final source = resolver.resolveFrame(
          character: character,
          animation: animation,
          frame: frame,
          tileWidth: bundle.manifest.settings.tileWidth,
          tileHeight: bundle.manifest.settings.tileHeight,
          availableImageIds: imageSizes.keys.toSet(),
        );
        expect(
          source,
          isNotNull,
          reason:
              'Source réelle ${character.id}/${animation.state}/${animation.direction}',
        );
        final size = imageSizes[source!.imageId]!;
        expect(source.sourceRect.left, greaterThanOrEqualTo(0));
        expect(source.sourceRect.top, greaterThanOrEqualTo(0));
        expect(
          source.sourceRect.right,
          lessThanOrEqualTo(size.width),
          reason:
              'Frame ${character.id}/${animation.state}/${animation.direction} hors image',
        );
        expect(
          source.sourceRect.bottom,
          lessThanOrEqualTo(size.height),
          reason:
              'Frame ${character.id}/${animation.state}/${animation.direction} hors image',
        );
      }
    }
  }
}
