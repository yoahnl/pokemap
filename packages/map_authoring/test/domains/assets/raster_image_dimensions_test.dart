import 'package:map_authoring/src/domains/assets/raster_image_dimensions.dart';
import 'package:test/test.dart';

void main() {
  test('decodes dimensions from PNG, JPEG, GIF, and WebP bytes', () {
    expect(
      decodeRasterImageDimensions(_png(width: 3, height: 2),
          mediaType: 'image/png'),
      _hasDimensions(3, 2),
    );
    expect(
      decodeRasterImageDimensions(_jpeg(width: 5, height: 4),
          mediaType: 'image/jpeg'),
      _hasDimensions(5, 4),
    );
    expect(
      decodeRasterImageDimensions(_gif(width: 7, height: 6),
          mediaType: 'image/gif'),
      _hasDimensions(7, 6),
    );
    expect(
      decodeRasterImageDimensions(_webpVp8x(width: 9, height: 8),
          mediaType: 'image/webp'),
      _hasDimensions(9, 8),
    );
  });

  test('rejects mismatched, truncated, and zero-sized image headers', () {
    expect(
      decodeRasterImageDimensions(_png(width: 1, height: 1),
          mediaType: 'image/jpeg'),
      isNull,
    );
    expect(
      decodeRasterImageDimensions(const <int>[0x89, 0x50],
          mediaType: 'image/png'),
      isNull,
    );
    expect(
      decodeRasterImageDimensions(_gif(width: 0, height: 1),
          mediaType: 'image/gif'),
      isNull,
    );
  });
}

Matcher _hasDimensions(int width, int height) => isA<RasterImageDimensions>()
    .having((value) => value.width, 'width', width)
    .having((value) => value.height, 'height', height);

List<int> _png({required int width, required int height}) => <int>[
      0x89,
      0x50,
      0x4e,
      0x47,
      0x0d,
      0x0a,
      0x1a,
      0x0a,
      0,
      0,
      0,
      13,
      ...'IHDR'.codeUnits,
      ..._u32be(width),
      ..._u32be(height),
      8,
      6,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
    ];

List<int> _jpeg({required int width, required int height}) => <int>[
      0xff,
      0xd8,
      0xff,
      0xc0,
      0,
      7,
      8,
      ..._u16be(height),
      ..._u16be(width),
    ];

List<int> _gif({required int width, required int height}) => <int>[
      ...'GIF89a'.codeUnits,
      ..._u16le(width),
      ..._u16le(height),
    ];

List<int> _webpVp8x({required int width, required int height}) => <int>[
      ...'RIFF'.codeUnits,
      ..._u32le(22),
      ...'WEBP'.codeUnits,
      ...'VP8X'.codeUnits,
      ..._u32le(10),
      0,
      0,
      0,
      0,
      ..._u24le(width - 1),
      ..._u24le(height - 1),
    ];

List<int> _u16be(int value) => <int>[(value >> 8) & 0xff, value & 0xff];

List<int> _u16le(int value) => <int>[value & 0xff, (value >> 8) & 0xff];

List<int> _u24le(int value) => <int>[
      value & 0xff,
      (value >> 8) & 0xff,
      (value >> 16) & 0xff,
    ];

List<int> _u32be(int value) => <int>[
      (value >> 24) & 0xff,
      (value >> 16) & 0xff,
      (value >> 8) & 0xff,
      value & 0xff,
    ];

List<int> _u32le(int value) => <int>[
      value & 0xff,
      (value >> 8) & 0xff,
      (value >> 16) & 0xff,
      (value >> 24) & 0xff,
    ];
