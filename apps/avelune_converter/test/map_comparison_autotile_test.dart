import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:avelune_converter/map_comparison.dart';
import 'package:avelune_converter_adapters/avelune_converter_adapters.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as image;

import '../../../packages/avelune_converter_adapters/test/support/literal_tile_fixture.dart';
import '../../../packages/avelune_converter_adapters/test/support/original_autotile_fixture.dart';

Future<ui.Image> _decode(List<int> bytes) async {
  final codec = await ui.instantiateImageCodec(Uint8List.fromList(bytes));
  try {
    return (await codec.getNextFrame()).image;
  } finally {
    codec.dispose();
  }
}

Future<List<int>> _paint(CustomPainter painter) async {
  final recorder = ui.PictureRecorder();
  painter.paint(ui.Canvas(recorder), const ui.Size(96, 32));
  final picture = recorder.endRecording();
  final rendered = await picture.toImage(96, 32);
  try {
    return (await rendered.toByteData(format: ui.ImageByteFormat.rawRgba))!
        .buffer
        .asUint8List()
        .toList();
  } finally {
    rendered.dispose();
    picture.dispose();
  }
}

void main() {
  testWidgets(
    'original source pixels remain independent when native autotile pixels change',
    (tester) async {
      await tester.runAsync(() async {
        final root = await Directory.systemTemp.createTemp(
          'ac07-source-comparison-',
        );
        final decoded = <ui.Image>[];
        try {
          final raster = OriginalAutotileFixture.standard(
            frameCount: 1,
            oracle: OriginalAutotileOracle.load(
              path: '../../packages/avelune_converter_adapters/test/support/autotile_quadrant_oracle.json',
            ),
          );
          final fixture = await LiteralTileFixture.create(
            sourceRootPath: '${root.path}/source',
            maps: [
              LiteralFixtureMap(
                id: 1,
                layers: const [
                  [384, 79, 0],
                  [0, 0, 79],
                  [0, 0, 0],
                ],
              ),
            ],
            tilesets: [
              LiteralFixtureTileset(
                id: 1,
                autotileNames: const ['OriginalWater'],
              ),
            ],
            autotilePngs: {'OriginalWater': raster.pngBytes},
          );
          final composition = await const LiteralTileComposer().compose(
            source: fixture.source,
            files: fixture.files,
            selectedSourceMapIds: const [1],
            projectName: 'Original source comparison',
            parentPath: root.path,
            folderName: 'unused',
            sourceRootPath: fixture.sourceRootPath,
          );
          expect(composition.canWrite, isTrue);
          final nativeImages = <String, ui.Image>{};
          for (final import in composition.draft!.mutations.where(
            (value) => value.actionId == 'tileset.import_image',
          )) {
            final artifact = composition.draft!.artifacts.singleWhere(
              (value) => value.handle == import.parameters['artifactHandle'],
            );
            final pixels = await _decode(artifact.bytes);
            decoded.add(pixels);
            nativeImages[import.parameters['tilesetId'] as String] = pixels;
          }
          final auto = composition.autotiles.single;
          final original = await _decode(auto.sourceArtifact.bytes);
          decoded.add(original);
          final sourceImages = {auto.nativeTilesetId: original};
          final map = fixture.source.maps.single.map;
          SourceTilesPainter sourcePainter(Map<String, ui.Image> native) =>
              SourceTilesPainter(
                map,
                native,
                composition.crops,
                autotileImages: sourceImages,
                autotiles: composition.autotiles,
              );
          final sourceBefore = await _paint(sourcePainter(nativeImages));
          final nativeBefore = await _paint(
            NativeTilesPainter(composition.nativeMaps[1]!, nativeImages),
          );
          expect(sourceBefore, nativeBefore);
          final corrupted = image.Image(
            width: auto.pixelWidth,
            height: auto.pixelHeight,
            numChannels: 4,
          );
          image.fill(corrupted, color: image.ColorRgba8(4, 230, 25, 255));
          final wrongPixels = await _decode(image.encodePng(corrupted));
          decoded.add(wrongPixels);
          final wrongNativeImages = {
            ...nativeImages,
            auto.nativeTilesetId: wrongPixels,
          };
          expect(await _paint(sourcePainter(wrongNativeImages)), sourceBefore);
          expect(
            await _paint(
              NativeTilesPainter(composition.nativeMaps[1]!, wrongNativeImages),
            ),
            isNot(nativeBefore),
          );
        } finally {
          for (final pixels in decoded) {
            pixels.dispose();
          }
          await root.delete(recursive: true);
        }
      });
    },
  );
}
