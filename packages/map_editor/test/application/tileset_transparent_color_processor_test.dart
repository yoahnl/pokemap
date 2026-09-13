import 'dart:async';
import 'dart:typed_data';

import 'package:image/image.dart' as img;
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/application/services/tileset_transparent_color_processor.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final key = TilesetTransparentColor(red: 255, green: 0, blue: 255);

  test('worker preserves every RGB value and non-key alpha', () async {
    final source = img.Image(width: 3, height: 1, numChannels: 4)
      ..setPixelRgba(0, 0, 255, 0, 255, 255)
      ..setPixelRgba(1, 0, 80, 120, 40, 137)
      ..setPixelRgba(2, 0, 255, 0, 254, 0);
    final bytes = img.encodePng(source);
    final before = Uint8List.fromList(bytes);
    final result = await applyTilesetTransparentColorToPngBytesAsync(
      imageBytes: bytes,
      transparentColor: key,
    );
    final decoded = img.decodePng(result)!;
    expect(decoded.width, 3);
    expect(decoded.height, 1);
    expect(decoded.getBytes(order: img.ChannelOrder.rgba), [
      255,
      0,
      255,
      0,
      80,
      120,
      40,
      137,
      255,
      0,
      254,
      0,
    ]);
    expect(bytes, before);
    final synchronous = img.decodePng(
      applyTilesetTransparentColorToPngBytes(
        imageBytes: bytes,
        transparentColor: key,
      ),
    )!;
    expect(
      decoded.getBytes(order: img.ChannelOrder.rgba),
      synchronous.getBytes(order: img.ChannelOrder.rgba),
    );
  });

  test('RGB source gains alpha only for matching pixels', () async {
    final source = img.Image(width: 2, height: 1, numChannels: 3)
      ..setPixelRgb(0, 0, 255, 0, 255)
      ..setPixelRgb(1, 0, 10, 20, 30);
    final result = await applyTilesetTransparentColorToPngBytesAsync(
      imageBytes: img.encodePng(source),
      transparentColor: key,
    );
    expect(img.decodePng(result)!.getBytes(order: img.ChannelOrder.rgba), [
      255,
      0,
      255,
      0,
      10,
      20,
      30,
      255,
    ]);
  });

  test(
    'missing transparent color returns original bytes without decoding',
    () async {
      final bytes = Uint8List.fromList([1, 2, 3]);
      final result = await applyTilesetTransparentColorToPngBytesAsync(
        imageBytes: bytes,
        transparentColor: null,
      );
      expect(identical(result, bytes), isTrue);
    },
  );

  test(
    'invalid image propagates its error and releases the worker queue',
    () async {
      final failed = applyTilesetTransparentColorToPngBytesAsync(
        imageBytes: Uint8List.fromList([1, 2, 3]),
        transparentColor: key,
      );
      final failureExpectation = expectLater(failed, throwsArgumentError);
      final next = applyTilesetTransparentColorToPngBytesAsync(
        imageBytes: img.encodePng(img.Image(width: 1, height: 1)),
        transparentColor: key,
      );
      await failureExpectation;
      expect(img.decodePng(await next), isNotNull);
    },
  );

  test('image processing lets the caller event loop run', () async {
    final bytes = img.encodePng(img.Image(width: 256, height: 256));
    var delivered = false;
    final timer = Timer(Duration.zero, () => delivered = true);
    try {
      await applyTilesetTransparentColorToPngBytesAsync(
        imageBytes: bytes,
        transparentColor: key,
      );
      expect(delivered, isTrue);
    } finally {
      timer.cancel();
    }
  });
}
