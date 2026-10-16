import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:image/image.dart' as img;
import 'package:map_distribution/src/static_png_validation.dart';
import 'package:test/test.dart';

void main() {
  group('bounded static PNG validation', () {
    const cases = [
      (0, 1, 21, 31),
      (0, 2, 28, 36),
      (0, 4, 42, 49),
      (0, 8, 70, 77),
      (0, 16, 133, 140),
      (2, 8, 196, 203),
      (2, 16, 385, 392),
      (3, 1, 21, 31),
      (3, 2, 28, 36),
      (3, 4, 42, 49),
      (3, 8, 70, 77),
      (4, 8, 133, 140),
      (4, 16, 259, 266),
      (6, 8, 259, 266),
      (6, 16, 511, 518),
    ];
    for (final (color, bits, plain, adam7) in cases) {
      for (final interlace in [0, 1]) {
        test('decodes color $color / $bits bits / interlace $interlace', () {
          final count = interlace == 0 ? plain : adam7;
          final bytes = _png(
              width: 9,
              height: 7,
              color: color,
              bits: bits,
              interlace: interlace,
              raw: Uint8List(count));
          final decoder =
              validatedStaticPngDecoder(bytes, maxDimension: 9, maxPixels: 63);
          expect(staticPngScanlineBytes(decoder.info), count);
          final image = decoder.decodeFrame(0)!;
          expect((image.width, image.height), (9, 7));
        });
      }
    }
    test(
        'preflights tiny Adam7 passes and decodes split IDAT header and trailer',
        () {
      final compressed = ZLibEncoder().encode([0, 10, 20, 30, 255]);
      final tiny = validatedStaticPngDecoder(_png(interlace: 1),
          maxDimension: 1, maxPixels: 1);
      expect(staticPngScanlineBytes(tiny.info), 5);
      final bytes = _png(idat: [
        for (final value in compressed) [value]
      ]);
      final image =
          validatedStaticPngDecoder(bytes, maxDimension: 1, maxPixels: 1)
              .decodeFrame(0)!;
      expect(image.getPixel(0, 0).r, 10);
      expect(image.getPixel(0, 0).g, 20);
      expect(image.getPixel(0, 0).b, 30);
    });
    test('validates LZ77 back references after the 32 KiB window wraps', () {
      final image = img.Image(width: 256, height: 256);
      for (var y = 0; y < image.height; y++) {
        for (var x = 0; x < image.width; x++) {
          image.setPixelRgba(x, y, x, y % 4, x ^ (y % 4), 255);
        }
      }
      final bytes = img.encodePng(image, level: 9);
      expect(bytes.length, lessThan(32 * 1024));
      final decoder =
          validatedStaticPngDecoder(bytes, maxDimension: 256, maxPixels: 65536);
      expect(staticPngScanlineBytes(decoder.info), greaterThan(32 * 1024));
      expect(decoder.decodeFrame(0)!.getBytes(), image.getBytes());
    });
    test(
        'refuses surplus inflation before writing beyond the expected scanlines',
        () {
      final bomb = _png(raw: Uint8List(8 * 1024 * 1024));
      expect(
          () => validatedStaticPngDecoder(bomb, maxDimension: 1, maxPixels: 1),
          throwsA(isA<FormatException>().having((error) => error.message,
              'message', contains('exceeds its declared dimensions'))));
      expect(
          () => validatedStaticPngDecoder(_png(raw: Uint8List(6)),
              maxDimension: 1, maxPixels: 1),
          throwsFormatException);
      expect(
          () => validatedStaticPngDecoder(_png(raw: Uint8List(4)),
              maxDimension: 1, maxPixels: 1),
          throwsFormatException);
    });
    test('bounds uncompressed deflate blocks before their stream writes', () {
      final exact = _png(idat: [
        ZLibEncoder().encode([0, 1, 2, 3, 255], level: 0)
      ]);
      expect(
          validatedStaticPngDecoder(exact, maxDimension: 1, maxPixels: 1)
              .decodeFrame(0)!
              .width,
          1);
      final surplus =
          _png(idat: [ZLibEncoder().encode(Uint8List(65535), level: 0)]);
      expect(
          () =>
              validatedStaticPngDecoder(surplus, maxDimension: 1, maxPixels: 1),
          throwsA(isA<FormatException>().having((error) => error.message,
              'message', contains('exceeds its declared dimensions'))));
    });
    test('refuses truncated and extra deflate data and incorrect Adler32', () {
      final compressed = ZLibEncoder().encode([0, 1, 2, 3, 255]);
      final corruptAdler = Uint8List.fromList(compressed);
      corruptAdler[corruptAdler.length - 1] ^= 1;
      for (final invalid in [
        compressed.sublist(0, compressed.length - 1),
        [...compressed.sublist(0, 3), ...compressed.sublist(4)],
        [
          ...compressed.sublist(0, compressed.length - 4),
          0,
          ...compressed.sublist(compressed.length - 4)
        ],
        corruptAdler,
        [0, ...compressed.skip(1)],
        [compressed[0], compressed[1] | 32, ...compressed.skip(2)],
      ]) {
        expect(
            () => validatedStaticPngDecoder(_png(idat: [invalid]),
                maxDimension: 1, maxPixels: 1),
            throwsFormatException);
      }
    });
    test(
        'refuses duplicate IHDR, animation, nonconsecutive IDAT and invalid CRC',
        () {
      final original = _png();
      final headerChunk = original.sublist(8, 33);
      for (final invalid in [
        Uint8List.fromList([
          ...original.sublist(0, 33),
          ...headerChunk,
          ...original.sublist(33)
        ]),
        _png(extraBeforeIdat: [
          _chunk('acTL', [0, 0, 0, 1, 0, 0, 0, 0])
        ]),
        _png(idat: [
          [1],
          [2]
        ], splitGap: true),
        Uint8List.fromList(original)..[29] ^= 1,
        Uint8List.fromList([...original, 0]),
        Uint8List.sublistView(original, 0, original.length - 1),
      ]) {
        expect(
            () => validatedStaticPngDecoder(invalid,
                maxDimension: 1, maxPixels: 1),
            throwsFormatException);
      }
    });
    test('refuses dimensions before creating a decoder or inflating', () {
      expect(
          () => validatedStaticPngDecoder(_png(width: 2, raw: Uint8List(9)),
              maxDimension: 1, maxPixels: 2),
          throwsFormatException);
      expect(
          () => validatedStaticPngDecoder(_png(width: 2, raw: Uint8List(9)),
              maxDimension: 2, maxPixels: 1),
          throwsFormatException);
    });
  });
}

Uint8List _png(
    {int width = 1,
    int height = 1,
    int color = 6,
    int bits = 8,
    int interlace = 0,
    Uint8List? raw,
    List<List<int>>? idat,
    List<Uint8List> extraBeforeIdat = const [],
    bool splitGap = false}) {
  final header = ByteData(13)
    ..setUint32(0, width)
    ..setUint32(4, height)
    ..setUint8(8, bits)
    ..setUint8(9, color)
    ..setUint8(12, interlace);
  final chunks = idat ?? [ZLibEncoder().encode(raw ?? Uint8List(5))];
  final output = BytesBuilder()
    ..add([137, 80, 78, 71, 13, 10, 26, 10])
    ..add(_chunk('IHDR', header.buffer.asUint8List()));
  if (color == 3) output.add(_chunk('PLTE', [0, 0, 0]));
  for (final extra in extraBeforeIdat) {
    output.add(extra);
  }
  for (var index = 0; index < chunks.length; index++) {
    if (splitGap && index != 0) output.add(_chunk('tEXt', [65, 0, 66]));
    output.add(_chunk('IDAT', chunks[index]));
  }
  return (output..add(_chunk('IEND', []))).takeBytes();
}

Uint8List _chunk(String type, List<int> bytes) {
  final tagged = [...ascii.encode(type), ...bytes];
  return (BytesBuilder()
        ..add((ByteData(4)..setUint32(0, bytes.length)).buffer.asUint8List())
        ..add(tagged)
        ..add(
            (ByteData(4)..setUint32(0, getCrc32(tagged))).buffer.asUint8List()))
      .takeBytes();
}
