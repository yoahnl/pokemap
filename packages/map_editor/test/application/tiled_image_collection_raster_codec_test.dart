import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:map_authoring/map_authoring.dart';
import 'package:map_editor/src/application/services/tiled_image_collection_raster_codec.dart';

void main() {
  test('packs byte-identical owned PNG pages without resampling source pixels',
      () {
    const codec = ImagePackageTiledImageCollectionRasterCodec();
    const packer = TiledImageCollectionPacker(codec: codec);
    final source = img.Image(width: 2, height: 1, numChannels: 4)
      ..setPixelRgba(0, 0, 1, 2, 3, 4)
      ..setPixelRgba(1, 0, 250, 240, 230, 220);
    final input = TiledImageCollectionPackingInput(
      source: 'props/pixels.png',
      bytes: img.encodePng(source),
      declaredPixelWidth: 2,
      declaredPixelHeight: 1,
    );

    final first = packer.pack(
      <TiledImageCollectionPackingInput>[input],
      maximumPageWidth: 8,
      maximumPageHeight: 8,
      padding: 1,
    );
    final second = packer.pack(
      <TiledImageCollectionPackingInput>[input],
      maximumPageWidth: 8,
      maximumPageHeight: 8,
      padding: 1,
    );

    expect(second.pages.single.bytes, orderedEquals(first.pages.single.bytes));
    expect(second.pages.single.artifact, first.pages.single.artifact);
    final page = img.decodePng(
      Uint8List.fromList(first.pages.single.bytes),
    )!;
    final placement = first.placementForSource(input.source).sourceRect;
    expect(_rgba(page.getPixel(placement.x, placement.y)), (1, 2, 3, 4));
    expect(
      _rgba(page.getPixel(placement.x + 1, placement.y)),
      (250, 240, 230, 220),
    );
    expect(_rgba(page.getPixel(0, 0)), (0, 0, 0, 0));
  });
}

(int, int, int, int) _rgba(img.Pixel pixel) => (
      pixel.r.toInt(),
      pixel.g.toInt(),
      pixel.b.toInt(),
      pixel.a.toInt(),
    );
