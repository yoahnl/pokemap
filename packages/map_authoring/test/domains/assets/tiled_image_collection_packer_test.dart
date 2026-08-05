import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  const codec = _DeterministicTestRasterCodec();
  const packer = TiledImageCollectionPacker(codec: codec);

  group('TiledImageCollectionPacker', () {
    test('is byte deterministic regardless of dependency input order', () {
      final inputs = <TiledImageCollectionPackingInput>[
        _input('props/tree.png', 2, 3, const _Rgba(10, 20, 30, 255)),
        _input('props/flower.png', 1, 1, const _Rgba(40, 50, 60, 127)),
        _input('props/rock.png', 3, 2, const _Rgba(70, 80, 90, 255)),
      ];

      final first = packer.pack(
        inputs,
        maximumPageWidth: 5,
        maximumPageHeight: 5,
        padding: 0,
      );
      final reversed = packer.pack(
        inputs.reversed,
        maximumPageWidth: 5,
        maximumPageHeight: 5,
        padding: 0,
      );

      expect(reversed.pages, hasLength(first.pages.length));
      for (var index = 0; index < first.pages.length; index += 1) {
        expect(
          reversed.pages[index].bytes,
          orderedEquals(first.pages[index].bytes),
        );
      }
      expect(
        reversed.pages.map((page) => page.artifact.digest),
        orderedEquals(first.pages.map((page) => page.artifact.digest)),
      );
      expect(
        reversed.placements.map(_placementJson).toList(),
        equals(first.placements.map(_placementJson).toList()),
      );
      for (final page in first.pages) {
        expect(
          page.artifact,
          ContentArtifactRef.fromBytes(page.bytes, mediaType: 'image/png'),
        );
      }
    });

    test('creates stable numbered pages when one page cannot fit every image',
        () {
      final result = packer.pack(
        <TiledImageCollectionPackingInput>[
          _input('a.png', 3, 3, const _Rgba(255, 0, 0, 255)),
          _input('b.png', 3, 3, const _Rgba(0, 255, 0, 255)),
        ],
        maximumPageWidth: 4,
        maximumPageHeight: 4,
        padding: 0,
      );

      expect(
        result.pages.map((page) => page.id),
        <String>['page-0000', 'page-0001'],
      );
      expect(
        result.pages.map((page) => (page.pixelWidth, page.pixelHeight)),
        <(int, int)>[(3, 3), (3, 3)],
      );
      expect(result.placementForSource('a.png').pageId, 'page-0000');
      expect(result.placementForSource('b.png').pageId, 'page-0001');
    });

    test('copies exact RGBA pixels and keeps transparent padding', () {
      final result = packer.pack(
        <TiledImageCollectionPackingInput>[
          TiledImageCollectionPackingInput(
            source: 'pixels.png',
            bytes: codec.encodePng(
              TiledImageCollectionRgbaImage(
                pixelWidth: 2,
                pixelHeight: 1,
                rgbaBytes: const <int>[
                  12,
                  34,
                  56,
                  78,
                  90,
                  87,
                  65,
                  43,
                ],
              ),
            ),
            declaredPixelWidth: 2,
            declaredPixelHeight: 1,
          ),
        ],
        maximumPageWidth: 8,
        maximumPageHeight: 8,
        padding: 1,
      );

      final placement = result.placementForSource('pixels.png');
      expect((placement.sourceRect.x, placement.sourceRect.y), (1, 1));
      final page = codec.decode(result.pages.single.bytes);
      expect(_pixelAt(page, 0, 0), const _Rgba(0, 0, 0, 0));
      expect(_pixelAt(page, 1, 1), const _Rgba(12, 34, 56, 78));
      expect(_pixelAt(page, 2, 1), const _Rgba(90, 87, 65, 43));
      expect(_pixelAt(page, 3, 2), const _Rgba(0, 0, 0, 0));
    });

    test('turns each TSX transparent color into alpha before packing', () {
      final result = packer.pack(
        <TiledImageCollectionPackingInput>[
          TiledImageCollectionPackingInput(
            source: 'pixels.png',
            bytes: codec.encodePng(
              TiledImageCollectionRgbaImage(
                pixelWidth: 2,
                pixelHeight: 1,
                rgbaBytes: const <int>[
                  12,
                  34,
                  56,
                  255,
                  90,
                  87,
                  65,
                  255,
                ],
              ),
            ),
            declaredPixelWidth: 2,
            declaredPixelHeight: 1,
            transparentColor: TilesetTransparentColor.fromHexRgb('0c2238'),
          ),
        ],
        maximumPageWidth: 2,
        maximumPageHeight: 1,
        padding: 0,
      );

      final page = codec.decode(result.pages.single.bytes);
      expect(_pixelAt(page, 0, 0), const _Rgba(12, 34, 56, 0));
      expect(_pixelAt(page, 1, 0), const _Rgba(90, 87, 65, 255));
    });

    test('rejects duplicate sources and mismatched declared dimensions', () {
      final valid = _input('same.png', 1, 1, const _Rgba(1, 2, 3, 255));

      expect(
        () => packer.pack(<TiledImageCollectionPackingInput>[valid, valid]),
        throwsA(_packingError('tileset.tiled.image_dependency_duplicate')),
      );
      expect(
        () => packer.pack(
          <TiledImageCollectionPackingInput>[
            TiledImageCollectionPackingInput(
              source: 'wrong.png',
              bytes: valid.bytes,
              declaredPixelWidth: 2,
              declaredPixelHeight: 1,
            ),
          ],
        ),
        throwsA(_packingError('tileset.tiled.image_dimensions_mismatch')),
      );
    });

    test('fails closed for invalid bytes, oversized items and pixel budgets',
        () {
      expect(
        () => packer.pack(
          const <TiledImageCollectionPackingInput>[
            TiledImageCollectionPackingInput(
              source: 'broken.png',
              bytes: <int>[1, 2, 3],
              declaredPixelWidth: 1,
              declaredPixelHeight: 1,
            ),
          ],
        ),
        throwsA(_packingError('tileset.tiled.image_decode_invalid')),
      );

      final large = _input('large.png', 4, 4, const _Rgba(1, 2, 3, 255));
      expect(
        () => packer.pack(
          <TiledImageCollectionPackingInput>[large],
          maximumPageWidth: 3,
          maximumPageHeight: 4,
          padding: 0,
        ),
        throwsA(_packingError('tileset.tiled.image_page_too_small')),
      );
      expect(
        () => packer.pack(
          <TiledImageCollectionPackingInput>[large],
          maximumDecodedPixels: 15,
          padding: 0,
        ),
        throwsA(_packingError('tileset.tiled.image_pixel_budget_exceeded')),
      );
      expect(
        () => packer.pack(
          <TiledImageCollectionPackingInput>[
            _input('padded.png', 1, 1, const _Rgba(1, 2, 3, 255)),
          ],
          maximumPageWidth: 21,
          maximumPageHeight: 21,
          padding: 10,
          maximumGeneratedPixels: 440,
        ),
        throwsA(
          _packingError('tileset.tiled.image_page_pixel_budget_exceeded'),
        ),
      );
    });

    test('rejects an empty collection instead of emitting an empty page', () {
      expect(
        () => packer.pack(const <TiledImageCollectionPackingInput>[]),
        throwsA(_packingError('tileset.tiled.image_dependencies_required')),
      );
    });
  });
}

TiledImageCollectionPackingInput _input(
  String source,
  int width,
  int height,
  _Rgba color,
) {
  return TiledImageCollectionPackingInput(
    source: source,
    bytes: const _DeterministicTestRasterCodec().encodePng(
      TiledImageCollectionRgbaImage(
        pixelWidth: width,
        pixelHeight: height,
        rgbaBytes: <int>[
          for (var index = 0; index < width * height; index += 1) ...<int>[
            color.r,
            color.g,
            color.b,
            color.a
          ],
        ],
      ),
    ),
    declaredPixelWidth: width,
    declaredPixelHeight: height,
  );
}

Map<String, Object?> _placementJson(
  TiledImageCollectionPackedPlacement placement,
) =>
    <String, Object?>{
      'source': placement.source,
      'pageId': placement.pageId,
      'rect': placement.sourceRect.toJson(),
    };

Matcher _packingError(String code) =>
    isA<TiledImageCollectionPackingException>()
        .having((error) => error.code, 'code', code);

_Rgba _pixelAt(TiledImageCollectionRgbaImage image, int x, int y) {
  final index = (y * image.pixelWidth + x) * 4;
  return _Rgba(
    image.rgbaBytes[index],
    image.rgbaBytes[index + 1],
    image.rgbaBytes[index + 2],
    image.rgbaBytes[index + 3],
  );
}

final class _DeterministicTestRasterCodec
    implements TiledImageCollectionRasterCodec {
  const _DeterministicTestRasterCodec();

  @override
  TiledImageCollectionRgbaImage decode(List<int> encodedBytes) {
    if (encodedBytes.length < 2) throw const FormatException('truncated');
    return TiledImageCollectionRgbaImage(
      pixelWidth: encodedBytes[0],
      pixelHeight: encodedBytes[1],
      rgbaBytes: encodedBytes.skip(2),
    );
  }

  @override
  TiledImageCollectionRasterMetadata inspect(List<int> encodedBytes) {
    if (encodedBytes.length < 2) throw const FormatException('truncated');
    final expectedLength = 2 + encodedBytes[0] * encodedBytes[1] * 4;
    if (encodedBytes.length != expectedLength) {
      throw const FormatException('invalid rgba payload');
    }
    return TiledImageCollectionRasterMetadata(
      pixelWidth: encodedBytes[0],
      pixelHeight: encodedBytes[1],
    );
  }

  @override
  List<int> encodePng(TiledImageCollectionRgbaImage image) => <int>[
        image.pixelWidth,
        image.pixelHeight,
        ...image.rgbaBytes,
      ];
}

final class _Rgba {
  const _Rgba(this.r, this.g, this.b, this.a);

  final int r;
  final int g;
  final int b;
  final int a;

  @override
  bool operator ==(Object other) =>
      other is _Rgba &&
      other.r == r &&
      other.g == g &&
      other.b == b &&
      other.a == a;

  @override
  int get hashCode => Object.hash(r, g, b, a);

  @override
  String toString() => 'rgba($r, $g, $b, $a)';
}
