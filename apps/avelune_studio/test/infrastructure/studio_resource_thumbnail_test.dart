import 'dart:io';

import 'package:avelune_studio/platform/rendering/studio_map_resources.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

import '../support/resource_stress_fixture.dart';

void main() {
  testWidgets(
    'visible decor and literal tile show their exact crop after lazy load',
    (tester) async {
      final fixture = (await tester.runAsync(
        () => ResourceStressFixture.create(errorCount: 0),
      ))!;
      final resources = (await tester.runAsync(
        () => StudioMapResources.load(fixture.session, fixture.manifest),
      ))!;
      final tileKey = GlobalKey();
      final decorKey = GlobalKey();
      final decor = fixture.manifest.elements.firstWhere(
        (entry) => entry.id == 'rocher-131',
      );
      await tester.pumpWidget(
        MaterialApp(
          home: Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                RepaintBoundary(
                  key: tileKey,
                  child: resources.tileThumbnail(
                    TileLayerPaletteEntry(
                      tilesetId: fixture.lateAtlasId,
                      localTileId: 1,
                    ),
                    size: 32,
                  ),
                ),
                RepaintBoundary(
                  key: decorKey,
                  child: resources.thumbnail(decor, size: 32),
                ),
              ],
            ),
          ),
        ),
      );
      await _settle(tester, resources);
      await tester.pump();
      expect(await tester.runAsync(() => _pixel(tileKey)), [
        191,
        166,
        112,
        255,
      ]);
      expect(await tester.runAsync(() => _pixel(decorKey)), [
        135,
        149,
        165,
        255,
      ]);
      expect(resources.store.decoder.decodes, 1);
      expect(resources.images.keys, [fixture.lateAtlasId]);
      await tester.pumpWidget(const SizedBox());
      await resources.dispose();
      await tester.runAsync(fixture.dispose);
    },
  );

  testWidgets('sparse collection thumbnail loads only its actual page', (
    tester,
  ) async {
    final fixture = (await tester.runAsync(
      () => ResourceStressFixture.create(errorCount: 0),
    ))!;
    await tester.runAsync(() async {
      await Directory('${fixture.directory.path}/assets/pages').create();
      await File(
        '${fixture.directory.path}/assets/atelier.png',
      ).copy('${fixture.directory.path}/assets/pages/rock.png');
    });
    final manifest = fixture.manifest.copyWith(
      tilesets: [
        ProjectTilesetEntry(
          id: 'collection',
          name: 'Collection',
          relativePath: 'assets/pages',
          source: ProjectImageCollectionTilesetSource(
            pages: const [
              ProjectImageCollectionPage(
                id: 'unused',
                assetId: 'unused-page',
                pixelWidth: 160,
                pixelHeight: 64,
              ),
              ProjectImageCollectionPage(
                id: 'rock',
                assetId: 'rock-page',
                pixelWidth: 160,
                pixelHeight: 64,
              ),
            ],
            tileDefinitions: const [
              ProjectImageCollectionTileDefinition(
                tileId: 42,
                pageId: 'rock',
                sourceRect: ProjectTilesetPixelRect(
                  x: 64,
                  y: 0,
                  width: 32,
                  height: 32,
                ),
              ),
            ],
          ),
        ),
      ],
    );
    final resources = (await tester.runAsync(
      () => StudioMapResources.load(fixture.session, manifest),
    ))!;
    final key = GlobalKey();
    await tester.pumpWidget(
      MaterialApp(
        home: Center(
          child: RepaintBoundary(
            key: key,
            child: resources.tileThumbnail(
              const TileLayerPaletteEntry(
                tilesetId: 'collection',
                localTileId: 42,
              ),
              size: 32,
            ),
          ),
        ),
      ),
    );
    await _settle(tester, resources);
    await tester.pump();
    expect(await tester.runAsync(() => _pixel(key)), [135, 149, 165, 255]);
    expect(resources.images.keys, ['rock-page']);
    expect(resources.diagnostics, isEmpty);
    expect(resources.store.decoder.decodes, 1);
    await tester.pumpWidget(const SizedBox());
    await resources.dispose();
    await tester.runAsync(fixture.dispose);
  });
}

Future<List<int>> _pixel(GlobalKey key) async {
  final boundary =
      key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
  final image = await boundary.toImage();
  final rgba = (await image.toByteData())!;
  final offset = (16 * image.width + 16) * 4;
  final pixel = rgba.buffer.asUint8List().sublist(offset, offset + 4);
  image.dispose();
  return pixel;
}

Future<void> _settle(WidgetTester tester, StudioMapResources resources) async {
  var complete = false;
  resources.settled.then((_) => complete = true);
  final watch = Stopwatch()..start();
  while (!complete && watch.elapsed < const Duration(seconds: 20)) {
    await tester.pump();
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 20)),
    );
  }
  expect(
    complete,
    isTrue,
    reason: 'Décodage des miniatures en moins de 20 secondes',
  );
  await tester.pump();
}
