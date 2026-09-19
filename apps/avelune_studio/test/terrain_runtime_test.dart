import 'dart:io';
import 'dart:ui' as ui;

import 'package:avelune_studio/features/map_workspace/data/local_map_workspace_adapter.dart';
import 'package:avelune_studio/features/project_session/domain/project_session.dart';
import 'package:avelune_studio/features/resources/data/local_resource_adapter.dart';
import 'package:avelune_studio/features/resources/domain/resource_port.dart';
import 'package:avelune_studio/features/terrains/application/terrain_brush.dart';
import 'package:avelune_studio/features/terrains/application/terrain_draft_controller.dart';
import 'package:avelune_studio/features/terrains/domain/terrain_connections.dart';
import 'package:avelune_studio/platform/playtest/studio_playtest_view.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as image;
import 'package:map_core/map_core.dart';
import 'package:map_runtime/map_runtime.dart';

import '../tool/create_example_project.dart';

void main() {
  testWidgets(
    'new imported and published terrain renders its pixels in real runtime and walks',
    (tester) async {
      tester.view.physicalSize = const Size(1024, 768);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      late Directory root;
      late ProjectSession session;
      late ProjectManifest manifest;
      late String revision;
      late LocalResourceAdapter resources;
      late LocalMapWorkspaceAdapter maps;
      await tester.runAsync(() async {
        maps = LocalMapWorkspaceAdapter();
        root = await Directory.systemTemp.createTemp('studio_terrain_runtime_');
        await writeExampleProject(root);
        session = ProjectSession(
          sessionId: root.path,
          name: 'Terrain runtime',
          directoryPath: await root.resolveSymbolicLinks(),
        );
        manifest = await maps.loadProject(session);
        resources = LocalResourceAdapter(session: session, mapAdapter: maps);
        final source = File('${root.path}/new-terrain.png');
        final pixels = image.Image(width: 64, height: 64);
        image.fill(pixels, color: image.ColorRgb8(217, 19, 173));
        await source.writeAsBytes(image.encodePng(pixels));
        final receipt = await resources.importImage(
          ResourceImageImport(
            sourcePath: source.path,
            name: 'Nouveau terrain visible',
            tileWidth: 16,
            tileHeight: 16,
          ),
        );
        manifest = receipt.manifest;
        final tileset = manifest.tilesets.firstWhere(
          (t) => t.id == receipt.createdTilesetId,
        );
        final draft = TerrainDraftController(
          manifest: manifest,
          atlas: terrainAtlas(tileset, 'runtime-atlas'),
          id: 'runtime-terrain',
        );
        for (var index = 0; index < 16; index++) {
          draft.selectedRule = index;
          draft.assign(index % 4, index ~/ 4);
        }
        final saved = await draft.save((action, values) async {
          final receipt = await resources.mutate(action, values);
          return receipt.manifest;
        }, publish: true);
        expect(saved, isTrue, reason: draft.error);
        manifest = draft.manifest;
        final document = await maps.loadMap(session, manifest.maps.first);
        final map = applyTerrainStroke(
          map: document.map,
          manifest: manifest,
          preset: manifest.smartTileCatalog.presets.single,
          cells: const [GridPos(x: 8, y: 8), GridPos(x: 9, y: 8)],
        );
        revision = await maps.saveMap(session, document, map);
      });
      addTearDown(() async {
        await resources.dispose();
        await root.delete(recursive: true);
      });
      final boundaryKey = GlobalKey();
      var returned = false;
      await tester.pumpWidget(
        MaterialApp(
          home: RepaintBoundary(
            key: boundaryKey,
            child: Scaffold(
              body: StudioPlaytestView(
                session: session,
                entry: manifest.maps.first,
                expectedRevision: revision,
                port: maps,
                onClose: () => returned = true,
              ),
            ),
          ),
        ),
      );
      PlayableMapGame? game;
      for (var attempt = 0; attempt < 300; attempt++) {
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 10)),
        );
        await tester.pump(const Duration(milliseconds: 16));
        final finder = find.byType(GameWidget<PlayableMapGame>);
        if (finder.evaluate().isNotEmpty) {
          game = tester.widget<GameWidget<PlayableMapGame>>(finder).game;
          if (game!.isLoaded && !game.debugIsMapActivationDispatchInFlight) {
            break;
          }
        }
      }
      expect(game, isNotNull);
      expect(game!.isLoaded, isTrue);
      await tester.pump(const Duration(milliseconds: 50));
      final bundle = await tester.runAsync(
        () => game!.debugLoadRuntimeMapBundleCachedForTest(
          manifest.maps.first.id,
        ),
      );
      expect(
        bundle!.map.layers.whereType<SmartTileLayer>().single.presetId,
        'runtime-terrain',
      );
      final boundary =
          boundaryKey.currentContext!.findRenderObject()!
              as RenderRepaintBoundary;
      final matchingPixels = await tester.runAsync(() async {
        final frame = await boundary.toImage(pixelRatio: 1);
        final data = await frame.toByteData(format: ui.ImageByteFormat.rawRgba);
        var count = 0;
        for (var offset = 0; offset < data!.lengthInBytes; offset += 4) {
          if (data.getUint8(offset) == 217 &&
              data.getUint8(offset + 1) == 19 &&
              data.getUint8(offset + 2) == 173 &&
              data.getUint8(offset + 3) == 255) {
            count++;
          }
        }
        frame.dispose();
        return count;
      });
      expect(matchingPixels, greaterThan(100));
      expect(game.debugPlayerGridPosition, const GridPos(x: 8, y: 9));
      game.handleRuntimeInputEvent(
        const RuntimeInputEvent.press(RuntimeInputControl.right),
      );
      game.update(.016);
      game.handleRuntimeInputEvent(
        const RuntimeInputEvent.release(RuntimeInputControl.right),
      );
      game.update(.3);
      expect(game.debugPlayerGridPosition, const GridPos(x: 9, y: 9));
      await tester.tap(find.text('Retour à la carte'));
      expect(returned, isTrue);
      await tester.pumpWidget(const SizedBox());
      expect(game.paused, isTrue);
      expect(tester.takeException(), isNull);
    },
  );
}
