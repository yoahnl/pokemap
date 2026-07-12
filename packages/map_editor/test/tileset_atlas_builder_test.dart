import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:map_editor/src/application/services/tileset_atlas_builder.dart';

import '../tool/build_tileset_atlas.dart' as atlas_cli;

const _supportedLayoutSchema = '''
{"atlases":{"ts_id":{"widthCells":16,"heightCells":16,"tileWidth":32,"tileHeight":32,"items":[{"id":"el","file":"el.png","x":0,"y":0,"width":1,"height":1}]}}}
''';

void main() {
  group('buildTilesetAtlas', () {
    test('builds an exact RGBA canvas and copies item pixels without blending',
        () {
      final result = buildTilesetAtlas(
        widthCells: 3,
        heightCells: 2,
        tileWidth: 2,
        tileHeight: 2,
        items: <TilesetAtlasItem>[
          TilesetAtlasItem(
            id: 'red',
            bytes: _solidPng(2, 2, const _Pixel(255, 0, 0, 255)),
            xCells: 0,
            yCells: 0,
            widthCells: 1,
            heightCells: 1,
          ),
          TilesetAtlasItem(
            id: 'translucent',
            bytes: _solidPng(4, 2, const _Pixel(10, 20, 30, 127)),
            xCells: 1,
            yCells: 1,
            widthCells: 2,
            heightCells: 1,
          ),
        ],
      );
      final atlas = _decodePng(result);

      expect((atlas.width, atlas.height), (6, 4));
      expect(_pixelAt(atlas, 0, 0), const _Pixel(255, 0, 0, 255));
      expect(_pixelAt(atlas, 2, 0), const _Pixel(0, 0, 0, 0));
      expect(_pixelAt(atlas, 2, 2), const _Pixel(10, 20, 30, 127));
      expect(_pixelAt(atlas, 5, 3), const _Pixel(10, 20, 30, 127));
      expect(_pixelAt(atlas, 0, 3), const _Pixel(0, 0, 0, 0));
    });

    test('converts uint16 RGBA channels to uint8 before copying pixels', () {
      final source = img.Image(
        width: 1,
        height: 1,
        format: img.Format.uint16,
        numChannels: 4,
      )..setPixelRgba(0, 0, 65535, 32768, 257, 32896);

      final result = buildTilesetAtlas(
        widthCells: 1,
        heightCells: 1,
        tileWidth: 1,
        tileHeight: 1,
        items: <TilesetAtlasItem>[
          TilesetAtlasItem(
            id: 'uint16',
            bytes: img.encodePng(source),
            xCells: 0,
            yCells: 0,
            widthCells: 1,
            heightCells: 1,
          ),
        ],
      );
      final atlas = _decodePng(result);

      expect(atlas.format, img.Format.uint8);
      expect(_pixelAt(atlas, 0, 0), const _Pixel(255, 128, 1, 128));
    });

    test('is byte-deterministic for repeated and reversed input order', () {
      final items = <TilesetAtlasItem>[
        TilesetAtlasItem(
          id: 'z-last-id',
          bytes: _solidPng(1, 1, const _Pixel(1, 2, 3, 255)),
          xCells: 1,
          yCells: 0,
          widthCells: 1,
          heightCells: 1,
        ),
        TilesetAtlasItem(
          id: 'a-first-id',
          bytes: _solidPng(1, 1, const _Pixel(4, 5, 6, 255)),
          xCells: 0,
          yCells: 1,
          widthCells: 1,
          heightCells: 1,
        ),
      ];

      Uint8List build(List<TilesetAtlasItem> orderedItems) => buildTilesetAtlas(
            widthCells: 2,
            heightCells: 2,
            tileWidth: 1,
            tileHeight: 1,
            items: orderedItems,
          );

      final first = build(items);
      expect(build(items), orderedEquals(first));
      expect(build(items.reversed.toList()), orderedEquals(first));
    });

    test('rejects duplicate item IDs', () {
      final bytes = _solidPng(1, 1, const _Pixel(1, 2, 3, 255));

      expect(
        () => buildTilesetAtlas(
          widthCells: 2,
          heightCells: 1,
          tileWidth: 1,
          tileHeight: 1,
          items: <TilesetAtlasItem>[
            TilesetAtlasItem(
              id: 'duplicate',
              bytes: bytes,
              xCells: 0,
              yCells: 0,
              widthCells: 1,
              heightCells: 1,
            ),
            TilesetAtlasItem(
              id: 'duplicate',
              bytes: bytes,
              xCells: 1,
              yCells: 0,
              widthCells: 1,
              heightCells: 1,
            ),
          ],
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('rejects geometrically overlapping footprints', () {
      expect(
        () => buildTilesetAtlas(
          widthCells: 3,
          heightCells: 3,
          tileWidth: 1,
          tileHeight: 1,
          items: <TilesetAtlasItem>[
            TilesetAtlasItem(
              id: 'large',
              bytes: _solidPng(2, 2, const _Pixel(1, 2, 3, 255)),
              xCells: 0,
              yCells: 0,
              widthCells: 2,
              heightCells: 2,
            ),
            TilesetAtlasItem(
              id: 'overlap',
              bytes: _solidPng(2, 1, const _Pixel(4, 5, 6, 255)),
              xCells: 1,
              yCells: 1,
              widthCells: 2,
              heightCells: 1,
            ),
          ],
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('rejects negative coordinates and out-of-bounds footprints', () {
      final bytes = _solidPng(1, 1, const _Pixel(1, 2, 3, 255));
      final invalidItems = <TilesetAtlasItem>[
        TilesetAtlasItem(
          id: 'negative-x',
          bytes: bytes,
          xCells: -1,
          yCells: 0,
          widthCells: 1,
          heightCells: 1,
        ),
        TilesetAtlasItem(
          id: 'negative-y',
          bytes: bytes,
          xCells: 0,
          yCells: -1,
          widthCells: 1,
          heightCells: 1,
        ),
        TilesetAtlasItem(
          id: 'past-right',
          bytes: bytes,
          xCells: 2,
          yCells: 0,
          widthCells: 1,
          heightCells: 1,
        ),
        TilesetAtlasItem(
          id: 'past-bottom',
          bytes: bytes,
          xCells: 0,
          yCells: 2,
          widthCells: 1,
          heightCells: 1,
        ),
      ];

      for (final item in invalidItems) {
        expect(
          () => buildTilesetAtlas(
            widthCells: 2,
            heightCells: 2,
            tileWidth: 1,
            tileHeight: 1,
            items: <TilesetAtlasItem>[item],
          ),
          throwsA(isA<ArgumentError>()),
          reason: item.id,
        );
      }
    });

    test('rejects non-positive atlas, tile, and footprint dimensions', () {
      final bytes = _solidPng(1, 1, const _Pixel(1, 2, 3, 255));

      for (final dimensions in <(int, int, int, int)>[
        (0, 1, 1, 1),
        (1, 0, 1, 1),
        (-1, 1, 1, 1),
        (1, -1, 1, 1),
        (1, 1, 0, 1),
        (1, 1, 1, 0),
        (1, 1, -1, 1),
        (1, 1, 1, -1),
      ]) {
        expect(
          () => buildTilesetAtlas(
            widthCells: dimensions.$1,
            heightCells: dimensions.$2,
            tileWidth: dimensions.$3,
            tileHeight: dimensions.$4,
            items: const <TilesetAtlasItem>[],
          ),
          throwsA(isA<ArgumentError>()),
          reason: 'dimensions=$dimensions',
        );
      }

      for (final footprint in <(int, int)>[(0, 1), (1, 0), (-1, 1), (1, -1)]) {
        expect(
          () => buildTilesetAtlas(
            widthCells: 1,
            heightCells: 1,
            tileWidth: 1,
            tileHeight: 1,
            items: <TilesetAtlasItem>[
              TilesetAtlasItem(
                id: 'invalid-footprint',
                bytes: bytes,
                xCells: 0,
                yCells: 0,
                widthCells: footprint.$1,
                heightCells: footprint.$2,
              ),
            ],
          ),
          throwsA(isA<ArgumentError>()),
          reason: 'footprint=$footprint',
        );
      }
    });

    test('rejects an excessive atlas before allocating its canvas', () {
      expect(
        () => buildTilesetAtlas(
          widthCells: tilesetAtlasPixelBudget + 1,
          heightCells: 1,
          tileWidth: 1,
          tileHeight: 1,
          items: const <TilesetAtlasItem>[],
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('rejects oversized item metadata before decoding pixel storage', () {
      expect(
        () => buildTilesetAtlas(
          widthCells: 1,
          heightCells: 1,
          tileWidth: 1,
          tileHeight: 1,
          items: <TilesetAtlasItem>[
            TilesetAtlasItem(
              id: 'oversized-metadata',
              bytes: _pngDimensionsOnly(tilesetAtlasPixelBudget + 1, 1),
              xCells: 0,
              yCells: 0,
              widthCells: 1,
              heightCells: 1,
            ),
          ],
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('rejects invalid item bytes and pixel dimensions unlike footprint',
        () {
      expect(
        () => buildTilesetAtlas(
          widthCells: 1,
          heightCells: 1,
          tileWidth: 1,
          tileHeight: 1,
          items: <TilesetAtlasItem>[
            TilesetAtlasItem(
              id: 'invalid-bytes',
              bytes: Uint8List.fromList(<int>[1, 2, 3]),
              xCells: 0,
              yCells: 0,
              widthCells: 1,
              heightCells: 1,
            ),
          ],
        ),
        throwsA(isA<FormatException>()),
      );

      expect(
        () => buildTilesetAtlas(
          widthCells: 1,
          heightCells: 1,
          tileWidth: 2,
          tileHeight: 2,
          items: <TilesetAtlasItem>[
            TilesetAtlasItem(
              id: 'wrong-size',
              bytes: _solidPng(1, 2, const _Pixel(1, 2, 3, 255)),
              xCells: 0,
              yCells: 0,
              widthCells: 1,
              heightCells: 1,
            ),
          ],
        ),
        throwsA(isA<ArgumentError>()),
      );
    });
  });

  group('tileset atlas layout and CLI', () {
    test('builds the documented ATLAS_LAYOUTS.json schema end to end',
        () async {
      final temp = await Directory.systemTemp.createTemp('atlas_layout_');
      addTearDown(() => temp.delete(recursive: true));
      final inputDirectory = Directory('${temp.path}/items');
      await inputDirectory.create();
      final itemBytes = _solidPng(
        32,
        32,
        const _Pixel(21, 22, 23, 200),
      );
      await File('${inputDirectory.path}/el.png').writeAsBytes(itemBytes);

      final result = await atlas_cli.buildTilesetAtlasFromLayoutJson(
        layoutJson: _supportedLayoutSchema,
        atlasId: 'ts_id',
        inputDirectory: inputDirectory,
      );
      final direct = buildTilesetAtlas(
        widthCells: 16,
        heightCells: 16,
        tileWidth: 32,
        tileHeight: 32,
        items: <TilesetAtlasItem>[
          TilesetAtlasItem(
            id: 'el',
            bytes: itemBytes,
            xCells: 0,
            yCells: 0,
            widthCells: 1,
            heightCells: 1,
          ),
        ],
      );
      final atlas = _decodePng(result);

      expect(result, orderedEquals(direct));
      expect((atlas.width, atlas.height), (512, 512));
      expect(_pixelAt(atlas, 31, 31), const _Pixel(21, 22, 23, 200));
      expect(_pixelAt(atlas, 32, 0), const _Pixel(0, 0, 0, 0));
    });

    test('rejects absolute and parent-traversing item paths', () async {
      final temp = await Directory.systemTemp.createTemp('atlas_layout_');
      addTearDown(() => temp.delete(recursive: true));

      for (final unsafePath in <String>['../el.png', '/tmp/el.png']) {
        final layout = jsonEncode(<String, Object>{
          'atlases': <String, Object>{
            'ts_id': <String, Object>{
              'widthCells': 1,
              'heightCells': 1,
              'tileWidth': 1,
              'tileHeight': 1,
              'items': <Object>[
                <String, Object>{
                  'id': 'el',
                  'file': unsafePath,
                  'x': 0,
                  'y': 0,
                  'width': 1,
                  'height': 1,
                },
              ],
            },
          },
        });

        await expectLater(
          atlas_cli.buildTilesetAtlasFromLayoutJson(
            layoutJson: layout,
            atlasId: 'ts_id',
            inputDirectory: temp,
          ),
          throwsA(isA<ArgumentError>()),
          reason: unsafePath,
        );
      }
    });

    test('reads item bytes from the canonical path after symlink validation',
        () async {
      final temp = await Directory.systemTemp.createTemp('atlas_layout_');
      addTearDown(() => temp.delete(recursive: true));
      final inputDirectory = Directory('${temp.path}/items');
      await inputDirectory.create();
      await File('${inputDirectory.path}/original.png').writeAsBytes(
        _solidPng(1, 1, const _Pixel(200, 10, 20, 255)),
      );
      await File('${inputDirectory.path}/replacement.png').writeAsBytes(
        _solidPng(1, 1, const _Pixel(20, 10, 200, 255)),
      );
      final link = Link('${inputDirectory.path}/item.png');
      await link.create('original.png');
      final layout = jsonEncode(<String, Object>{
        'atlases': <String, Object>{
          'canonical': <String, Object>{
            'widthCells': 1,
            'heightCells': 1,
            'tileWidth': 1,
            'tileHeight': 1,
            'items': <Object>[
              <String, Object>{
                'id': 'item',
                'file': 'item.png',
                'x': 0,
                'y': 0,
                'width': 1,
                'height': 1,
              },
            ],
          },
        },
      });

      final result = await atlas_cli.buildTilesetAtlasFromLayoutJson(
        layoutJson: layout,
        atlasId: 'canonical',
        inputDirectory: inputDirectory,
        afterItemPathResolvedForTesting: () async {
          await link.delete();
          await link.create('replacement.png');
        },
      );

      expect(
        _pixelAt(_decodePng(result), 0, 0),
        const _Pixel(200, 10, 20, 255),
      );
    });

    test('creates one output then refuses to overwrite it', () async {
      final temp = await Directory.systemTemp.createTemp('atlas_cli_');
      addTearDown(() => temp.delete(recursive: true));
      final inputDirectory = Directory('${temp.path}/items');
      await inputDirectory.create();
      await File('${inputDirectory.path}/el.png').writeAsBytes(
        _solidPng(32, 32, const _Pixel(1, 2, 3, 255)),
      );
      final layout = File('${temp.path}/ATLAS_LAYOUTS.json');
      await layout.writeAsString(_supportedLayoutSchema);
      final output = File('${temp.path}/nested/atlas.png');
      final args = <String>[
        '--layout',
        layout.path,
        '--atlas-id',
        'ts_id',
        '--input-dir',
        inputDirectory.path,
        '--output',
        output.path,
      ];
      final firstErrors = StringBuffer();

      final firstCode = await atlas_cli.runBuildTilesetAtlas(
        args,
        out: StringBuffer(),
        error: firstErrors,
      );

      expect(firstCode, 0, reason: firstErrors.toString());
      final original = await output.readAsBytes();
      final secondErrors = StringBuffer();

      final secondCode = await atlas_cli.runBuildTilesetAtlas(
        args,
        out: StringBuffer(),
        error: secondErrors,
      );

      expect(secondCode, atlas_cli.buildTilesetAtlasOutputExitCode);
      expect(secondErrors.toString(), contains('already exists'));
      expect(await output.readAsBytes(), orderedEquals(original));
    });

    test('preserves output created immediately before exclusive creation',
        () async {
      final temp = await Directory.systemTemp.createTemp('atlas_cli_');
      addTearDown(() => temp.delete(recursive: true));
      final inputDirectory = Directory('${temp.path}/items');
      await inputDirectory.create();
      await File('${inputDirectory.path}/el.png').writeAsBytes(
        _solidPng(32, 32, const _Pixel(1, 2, 3, 255)),
      );
      final layout = File('${temp.path}/ATLAS_LAYOUTS.json');
      await layout.writeAsString(_supportedLayoutSchema);
      final output = File('${temp.path}/atlas.png');
      final sentinel = Uint8List.fromList(<int>[7, 8, 9]);
      final errors = StringBuffer();

      final code = await atlas_cli.runBuildTilesetAtlas(
        <String>[
          '--layout',
          layout.path,
          '--atlas-id',
          'ts_id',
          '--input-dir',
          inputDirectory.path,
          '--output',
          output.path,
        ],
        out: StringBuffer(),
        error: errors,
        beforeOutputCreateForTesting: () => output.writeAsBytes(sentinel),
      );

      expect(code, atlas_cli.buildTilesetAtlasOutputExitCode);
      expect(await output.readAsBytes(), orderedEquals(sentinel));
    });

    test('maps an atlas pixel-budget rejection to the data exit code',
        () async {
      final temp = await Directory.systemTemp.createTemp('atlas_cli_');
      addTearDown(() => temp.delete(recursive: true));
      final inputDirectory = Directory('${temp.path}/items');
      await inputDirectory.create();
      final layout = File('${temp.path}/ATLAS_LAYOUTS.json');
      await layout.writeAsString(
        jsonEncode(<String, Object>{
          'atlases': <String, Object>{
            'too-large': <String, Object>{
              'widthCells': tilesetAtlasPixelBudget + 1,
              'heightCells': 1,
              'tileWidth': 1,
              'tileHeight': 1,
              'items': const <Object>[],
            },
          },
        }),
      );
      final output = File('${temp.path}/atlas.png');
      final errors = StringBuffer();

      final code = await atlas_cli.runBuildTilesetAtlas(
        <String>[
          '--layout',
          layout.path,
          '--atlas-id',
          'too-large',
          '--input-dir',
          inputDirectory.path,
          '--output',
          output.path,
        ],
        out: StringBuffer(),
        error: errors,
      );

      expect(code, atlas_cli.buildTilesetAtlasDataExitCode);
      expect(errors.toString(), contains('pixel budget'));
      expect(output.existsSync(), isFalse);
    });
  });
}

Uint8List _solidPng(int width, int height, _Pixel pixel) {
  final image = img.Image(width: width, height: height, numChannels: 4);
  for (var y = 0; y < height; y += 1) {
    for (var x = 0; x < width; x += 1) {
      image.setPixelRgba(
        x,
        y,
        pixel.red,
        pixel.green,
        pixel.blue,
        pixel.alpha,
      );
    }
  }
  return img.encodePng(image);
}

Uint8List _pngDimensionsOnly(int width, int height) {
  final header = Uint8List(13);
  final view = ByteData.sublistView(header);
  view
    ..setUint32(0, width, Endian.big)
    ..setUint32(4, height, Endian.big);
  header.setAll(8, <int>[8, 6, 0, 0, 0]);
  return (BytesBuilder(copy: false)
        ..add(<int>[137, 80, 78, 71, 13, 10, 26, 10])
        ..add(_pngChunk('IHDR', header))
        ..add(_pngChunk('IEND', const <int>[])))
      .takeBytes();
}

Uint8List _pngChunk(String type, List<int> data) {
  final typeBytes = ascii.encode(type);
  final crcInput = <int>[...typeBytes, ...data];
  final bytes = Uint8List(12 + data.length);
  final view = ByteData.sublistView(bytes);
  view.setUint32(0, data.length, Endian.big);
  bytes.setRange(4, 8, typeBytes);
  bytes.setRange(8, 8 + data.length, data);
  view.setUint32(8 + data.length, _crc32(crcInput), Endian.big);
  return bytes;
}

int _crc32(List<int> bytes) {
  var crc = 0xffffffff;
  for (final byte in bytes) {
    crc ^= byte;
    for (var bit = 0; bit < 8; bit += 1) {
      crc = (crc & 1) == 1 ? (crc >> 1) ^ 0xedb88320 : crc >> 1;
    }
  }
  return (crc ^ 0xffffffff) & 0xffffffff;
}

img.Image _decodePng(Uint8List bytes) {
  final image = img.decodePng(bytes);
  expect(image, isNotNull);
  return image!;
}

_Pixel _pixelAt(img.Image image, int x, int y) {
  final pixel = image.getPixel(x, y);
  return _Pixel(
    pixel.r.toInt(),
    pixel.g.toInt(),
    pixel.b.toInt(),
    pixel.a.toInt(),
  );
}

final class _Pixel {
  const _Pixel(this.red, this.green, this.blue, this.alpha);

  final int red;
  final int green;
  final int blue;
  final int alpha;

  @override
  bool operator ==(Object other) =>
      other is _Pixel &&
      red == other.red &&
      green == other.green &&
      blue == other.blue &&
      alpha == other.alpha;

  @override
  int get hashCode => Object.hash(red, green, blue, alpha);

  @override
  String toString() => '_Pixel($red, $green, $blue, $alpha)';
}
