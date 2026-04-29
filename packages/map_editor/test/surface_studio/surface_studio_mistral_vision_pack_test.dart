import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:map_editor/src/features/surface_studio/surface_studio_mistral_vision_pack.dart';

void main() {
  test('vision pack builds original, annotated and contact sheet data urls',
      () {
    final pack = buildSurfaceStudioMistralVisionPack(
      imageBytes: _atlasBytesWithEmptyColumn(),
      tileWidth: 8,
      tileHeight: 8,
      columnCount: 4,
      frameCount: 2,
    );

    expect(pack.originalAtlasDataUrl, startsWith('data:image/png;base64,'));
    expect(pack.annotatedAtlasDataUrl, startsWith('data:image/png;base64,'));
    expect(
      pack.columnContactSheetDataUrl,
      startsWith('data:image/png;base64,'),
    );
    expect(pack.columnDescriptors, hasLength(4));
    expect(pack.columnDescriptors[2].column, 3);
    expect(pack.columnDescriptors[2].likelyEmpty, isTrue);
    expect(pack.columnDescriptors[0].averageColorHex, startsWith('#'));

    final contactSheet = img.decodePng(_decodeDataUrl(
      pack.columnContactSheetDataUrl,
    ));
    expect(contactSheet, isNotNull);
    expect(contactSheet!.width, greaterThan(contactSheet.height));

    final descriptorJson = surfaceStudioColumnDescriptorsJson(
      pack.columnDescriptors,
    );
    expect(descriptorJson, contains('"likelyEmpty": true'));
    expect(descriptorJson, isNot(contains('/Users/')));
    expect(descriptorJson, isNot(contains('configured-secret')));
  });
}

Uint8List _atlasBytesWithEmptyColumn() {
  const tile = 8;
  const columns = 4;
  const frames = 2;
  final image = img.Image(width: columns * tile, height: frames * tile);
  img.fill(image, color: img.ColorRgba8(0, 0, 0, 0));
  for (var frame = 0; frame < frames; frame++) {
    for (var column = 0; column < columns; column++) {
      if (column == 2) {
        continue;
      }
      img.fillRect(
        image,
        x1: column * tile,
        y1: frame * tile,
        x2: column * tile + tile - 1,
        y2: frame * tile + tile - 1,
        color: img.ColorRgba8(30 + column * 40, 120, 210, 255),
      );
    }
  }
  return Uint8List.fromList(img.encodePng(image));
}

Uint8List _decodeDataUrl(String dataUrl) {
  final encoded = dataUrl.substring(dataUrl.indexOf(',') + 1);
  return Uint8List.fromList(base64Decode(encoded));
}
