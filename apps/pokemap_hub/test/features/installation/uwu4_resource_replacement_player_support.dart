import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:crypto/crypto.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as image;
import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:map_distribution/map_distribution.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:map_runtime/map_runtime.dart';
import 'package:map_runtime/map_runtime_authoring.dart';
import 'package:path/path.dart' as p;
import 'package:pokemap_hub/pokemap_hub_player.dart';
import 'package:pub_semver/pub_semver.dart';

import '../../../../avelune_studio/test/support/m2_ui_fixture.dart' show pumpIo;
import '../../../../avelune_studio/test/support/game_export_fixture.dart';
import '../../../../avelune_studio/test/support/m3_story_fixture.dart';

Future<void> prepareUwu4ExportFixture(M3StoryFixture source) async {
  await prepareGameExportFixture(source);
  final file = File(p.join(source.directory.path, 'project.json'));
  final manifest = ProjectManifest.fromJson(
    jsonDecode(await file.readAsString()),
  );
  final tilesets = <ProjectTilesetEntry>[];
  final records = <AssetRecord>[];
  for (final tileset in manifest.tilesets) {
    final bytes =
        await File(
          p.join(source.directory.path, tileset.relativePath),
        ).readAsBytes();
    final decoded = image.decodePng(bytes)!;
    final artifact = ContentArtifactRef.fromBytes(
      bytes,
      mediaType: 'image/png',
    );
    final id = 'fixture_${tileset.id}';
    records.add(
      AssetRecord(
        id: id,
        logicalPath: tileset.relativePath,
        artifact: artifact,
      ),
    );
    final blob = File(
      p.join(source.directory.path, assetBlobStorageKey(artifact)),
    );
    await blob.create(recursive: true);
    await blob.writeAsBytes(bytes);
    tilesets.add(
      tileset.copyWith(
        source: ProjectRegularAtlasTilesetSource(
          assetId: id,
          pixelWidth: decoded.width,
          pixelHeight: decoded.height,
          tileWidth: manifest.settings.tileWidth,
          tileHeight: manifest.settings.tileHeight,
        ),
      ),
    );
  }
  await File(
    p.join(source.directory.path, assetCatalogStorageKey),
  ).writeAsString(jsonEncode(AssetCatalog(records: records).toJson()));
  await file.writeAsString(
    jsonEncode(manifest.copyWith(tilesets: tilesets).toJson()),
  );
}

Future<void> playReplacedPackage(
  WidgetTester tester,
  File package,
  Directory temporary, {
  required ProjectManifest authored,
  required String tilesetId,
  required String elementId,
  required String placedId,
  required List<int> expectedPixels,
}) async {
  final support = Directory(p.join(temporary.path, 'player'));
  late PlayableMapGame game;
  final adapter =
      (await tester.runAsync(() async {
        final installed = await GamePackageInstaller(
          supportRoot: support,
          inspector: GamePackageInspector(hostCompatibility: _compatibility()),
          availableDiskBytes: (_) async => 1024 * 1024 * 1024,
          loadSmoke: (root, _) async {
            final bundle = await loadRuntimeMapBundle(
              projectFilePath: p.join(root.path, 'project', 'project.json'),
              mapId: authored.newGame.startMapId,
            );
            expect(
              bundle.map.placedElements.any((entry) => entry.id == placedId),
              isTrue,
            );
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
        final installedRoot = await support.resolveSymbolicLinks();
        expect(p.isWithin(installedRoot, projectFile.path), isTrue);
        final bundle = await loadRuntimeMapBundle(
          projectFilePath: projectFile.path,
          mapId: authored.newGame.startMapId,
        );
        expect(bundle.manifest.tilesets, authored.tilesets);
        expect(bundle.manifest.elements, authored.elements);
        expect(
          bundle.map.placedElements
              .singleWhere((entry) => entry.id == placedId)
              .elementId,
          elementId,
        );
        final catalog = AssetCatalog.fromJson(
          jsonDecode(
            await File(
              p.join(bundle.projectRootDirectory, assetCatalogStorageKey),
            ).readAsString(),
          ),
        );
        final atlas =
            resolveTilesetAbsolutePaths(
              manifest: bundle.manifest,
              projectRoot: bundle.projectRootDirectory,
              tilesetIds: {tilesetId},
              assetCatalog: catalog,
            )[tilesetId]!;
        expect(p.isWithin(installedRoot, atlas), isTrue);
        expect(await File(atlas).readAsBytes(), expectedPixels);
        final state = createNewGameStateFromProject(
          project: bundle.manifest,
          startMap: bundle.map,
          saveId: 'uwu4-replaced',
          tileWidthPx: bundle.manifest.settings.tileWidth,
          tileHeightPx: bundle.manifest.settings.tileHeight,
        );
        final descriptor = GameSessionDescriptor(
          sessionId: 'uwu4-session',
          sessionToken: 'uwu4-token',
          identity: launch.identity,
          profileId: 'local',
          slotId: 'slot-1',
          launchMode: GameSessionLaunchMode.newGame,
          installedVersionHandle: launch.installedVersionHandle,
          runtimeApiVersion: launch.runtimeApiVersion,
          grantedCapabilities: launch.grantedCapabilities,
          locale: 'fr',
          accessibility: const GameSessionAccessibilityOptions(),
          initialGameState: state,
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
          'UWU4_PACKAGE_SHA256=${sha256.convert(await package.readAsBytes())}',
        );
        print('UWU4_INSTALLED_PIXELS_SHA256=${sha256.convert(expectedPixels)}');
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
    for (var i = 0; i < 300 && game.debugIsMapActivationDispatchInFlight; i++) {
      game.update(.016);
      await Future<void>.delayed(Duration.zero);
    }
    expect(game.debugIsMapActivationDispatchInFlight, isFalse);
    expect(game.gameStateSnapshot.currentMapId, authored.newGame.startMapId);
  });
  await tester.pump();
  await tester.runAsync(() async {
    final boundary =
        capture.currentContext!.findRenderObject() as RenderRepaintBoundary;
    final frame = await boundary.toImage(pixelRatio: 1);
    final rgba = await frame.toByteData(format: ui.ImageByteFormat.rawRgba);
    var changedPixels = 0;
    for (var i = 0; i < rgba!.lengthInBytes; i += 4) {
      if (rgba.getUint8(i) == 249 &&
          rgba.getUint8(i + 1) == 9 &&
          rgba.getUint8(i + 2) == 222 &&
          rgba.getUint8(i + 3) == 255) {
        changedPixels++;
      }
    }
    expect(
      changedPixels,
      greaterThan(100),
      reason: 'The installed runtime must render the replaced placed décor.',
    );
    print('UWU4_RENDER_REPLACED_PIXELS=$changedPixels');
    final evidence = Platform.environment['UWU4_CAPTURE_DIR'];
    if (evidence != null) {
      final png = await frame.toByteData(format: ui.ImageByteFormat.png);
      await Directory(evidence).create(recursive: true);
      await File(
        p.join(evidence, 'uwu4-installed-replaced-resource.png'),
      ).writeAsBytes(png!.buffer.asUint8List());
    }
    frame.dispose();
  });
  await tester.pumpWidget(const SizedBox());
  await tester.runAsync(adapter.dispose);
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
