import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:map_editor/src/application/services/raster_asset_grid_normalizer.dart';

import '../tool/normalize_tileset_asset.dart' as normalize_cli;

void main() {
  group('normalizeRasterAssetToGrid', () {
    test(
      'pads the real 154x194 boat to 160x224 and preserves opaque pixels',
      () {
        final sourceBytes = File(
          '../../selbrume/assets/tilesets/bateau_selbrume.png',
        ).readAsBytesSync();
        final source = _decodePng(sourceBytes);

        expect((source.width, source.height), (154, 194));

        final result = normalizeRasterAssetToGrid(
          RasterAssetGridNormalizationRequest(
            bytes: sourceBytes,
            gridWidth: 32,
            gridHeight: 32,
          ),
        );
        final normalized = _decodePng(result);

        expect((normalized.width, normalized.height), (160, 224));

        const offsetX = 3;
        const offsetY = 30;
        for (var y = 0; y < source.height; y += 1) {
          for (var x = 0; x < source.width; x += 1) {
            final sourcePixel = _pixelAt(source, x, y);
            if (sourcePixel.alpha > 0) {
              expect(
                _pixelAt(normalized, x + offsetX, y + offsetY),
                sourcePixel,
                reason: 'Opaque source pixel ($x, $y) changed.',
              );
            }
          }
        }

        for (var y = 0; y < normalized.height; y += 1) {
          for (var x = 0; x < normalized.width; x += 1) {
            final isPadding = x < offsetX ||
                x >= offsetX + source.width ||
                y < offsetY ||
                y >= offsetY + source.height;
            if (isPadding) {
              expect(
                _pixelAt(normalized, x, y).alpha,
                0,
                reason: 'Padding pixel ($x, $y) is not transparent.',
              );
            }
          }
        }
      },
    );

    test('pads to the next grid multiple when no target is supplied', () {
      final result = normalizeRasterAssetToGrid(
        RasterAssetGridNormalizationRequest(
          bytes: _solidPng(3, 5, const _Pixel(10, 20, 30, 255)),
          gridWidth: 4,
          gridHeight: 4,
        ),
      );
      final normalized = _decodePng(result);

      expect((normalized.width, normalized.height), (4, 8));
      expect(_pixelAt(normalized, 0, 2).alpha, 0);
      expect(_pixelAt(normalized, 0, 3), const _Pixel(10, 20, 30, 255));
      expect(_pixelAt(normalized, 3, 7).alpha, 0);
    });

    test('places content at the top-left anchor', () {
      final result = normalizeRasterAssetToGrid(
        RasterAssetGridNormalizationRequest(
          bytes: _solidPng(2, 2, const _Pixel(80, 90, 100, 255)),
          gridWidth: 2,
          gridHeight: 2,
          targetWidth: 4,
          targetHeight: 6,
          anchor: RasterAssetAnchor.topLeft,
        ),
      );
      final normalized = _decodePng(result);

      expect(_pixelAt(normalized, 0, 0), const _Pixel(80, 90, 100, 255));
      expect(_pixelAt(normalized, 2, 0).alpha, 0);
      expect(_pixelAt(normalized, 0, 2).alpha, 0);
    });

    test('places content at the bottom-center anchor', () {
      final result = normalizeRasterAssetToGrid(
        RasterAssetGridNormalizationRequest(
          bytes: _solidPng(2, 2, const _Pixel(80, 90, 100, 255)),
          gridWidth: 2,
          gridHeight: 2,
          targetWidth: 4,
          targetHeight: 6,
        ),
      );
      final normalized = _decodePng(result);

      expect(_pixelAt(normalized, 1, 4), const _Pixel(80, 90, 100, 255));
      expect(_pixelAt(normalized, 0, 4).alpha, 0);
      expect(_pixelAt(normalized, 1, 3).alpha, 0);
    });

    test('centers content with symmetric deterministic padding', () {
      final request = RasterAssetGridNormalizationRequest(
        bytes: _solidPng(2, 4, const _Pixel(41, 42, 43, 255)),
        gridWidth: 2,
        gridHeight: 2,
        targetWidth: 6,
        targetHeight: 8,
        anchor: RasterAssetAnchor.center,
      );

      final first = normalizeRasterAssetToGrid(request);
      final second = normalizeRasterAssetToGrid(request);
      final normalized = _decodePng(first);

      expect(first, orderedEquals(second));
      expect((normalized.width, normalized.height), (6, 8));
      expect(_pixelAt(normalized, 1, 2).alpha, 0);
      expect(_pixelAt(normalized, 2, 2), const _Pixel(41, 42, 43, 255));
      expect(_pixelAt(normalized, 3, 5), const _Pixel(41, 42, 43, 255));
      expect(_pixelAt(normalized, 4, 5).alpha, 0);
      expect(_pixelAt(normalized, 2, 1).alpha, 0);
      expect(_pixelAt(normalized, 2, 6).alpha, 0);
    });

    test('trims the transparent border before padding and anchoring', () {
      final source = img.Image(width: 5, height: 5, numChannels: 4);
      for (var y = 2; y <= 3; y += 1) {
        for (var x = 1; x <= 3; x += 1) {
          source.setPixelRgba(x, y, x * 20, y * 30, 7, 255);
        }
      }

      final result = normalizeRasterAssetToGrid(
        RasterAssetGridNormalizationRequest(
          bytes: img.encodePng(source),
          gridWidth: 4,
          gridHeight: 4,
          trimTransparentBorder: true,
        ),
      );
      final normalized = _decodePng(result);

      expect((normalized.width, normalized.height), (4, 4));
      expect(_pixelAt(normalized, 0, 1).alpha, 0);
      expect(_pixelAt(normalized, 0, 2), const _Pixel(20, 60, 7, 255));
      expect(_pixelAt(normalized, 2, 3), const _Pixel(60, 90, 7, 255));
      expect(_pixelAt(normalized, 3, 3).alpha, 0);
    });

    test('converts uint16 RGBA channels to uint8 before copying pixels', () {
      final source = img.Image(
        width: 1,
        height: 1,
        format: img.Format.uint16,
        numChannels: 4,
      )..setPixelRgba(0, 0, 65535, 32768, 257, 32896);

      final result = normalizeRasterAssetToGrid(
        RasterAssetGridNormalizationRequest(
          bytes: img.encodePng(source),
          gridWidth: 1,
          gridHeight: 1,
        ),
      );
      final normalized = _decodePng(result);

      expect(normalized.format, img.Format.uint8);
      expect(_pixelAt(normalized, 0, 0), const _Pixel(255, 128, 1, 128));
    });

    test('contains a 64x64 source as 32x32 at the target bottom-center', () {
      final result = normalizeRasterAssetToGrid(
        RasterAssetGridNormalizationRequest(
          bytes: _solidPng(64, 64, const _Pixel(12, 34, 56, 255)),
          gridWidth: 32,
          gridHeight: 32,
          targetWidth: 32,
          targetHeight: 64,
          resizeMode: RasterAssetResizeMode.containNearest,
        ),
      );
      final normalized = _decodePng(result);

      expect((normalized.width, normalized.height), (32, 64));
      expect(_pixelAt(normalized, 0, 31).alpha, 0);
      expect(_pixelAt(normalized, 0, 32), const _Pixel(12, 34, 56, 255));
      expect(_pixelAt(normalized, 31, 63), const _Pixel(12, 34, 56, 255));
    });

    test('uses deterministic proportional nearest-neighbor downscaling', () {
      final source = img.Image(width: 4, height: 4, numChannels: 4);
      const colors = <_Pixel>[
        _Pixel(255, 0, 0, 255),
        _Pixel(0, 255, 0, 255),
        _Pixel(0, 0, 255, 255),
        _Pixel(255, 255, 0, 255),
      ];
      for (var y = 0; y < 4; y += 1) {
        for (var x = 0; x < 4; x += 1) {
          final color = colors[(y ~/ 2) * 2 + (x ~/ 2)];
          source.setPixelRgba(
            x,
            y,
            color.red,
            color.green,
            color.blue,
            color.alpha,
          );
        }
      }

      final request = RasterAssetGridNormalizationRequest(
        bytes: img.encodePng(source),
        gridWidth: 2,
        gridHeight: 2,
        targetWidth: 2,
        targetHeight: 4,
        resizeMode: RasterAssetResizeMode.containNearest,
      );
      final first = normalizeRasterAssetToGrid(request);
      final second = normalizeRasterAssetToGrid(request);
      final normalized = _decodePng(first);

      expect(first, orderedEquals(second));
      expect(_pixelAt(normalized, 0, 2), colors[0]);
      expect(_pixelAt(normalized, 1, 2), colors[1]);
      expect(_pixelAt(normalized, 0, 3), colors[2]);
      expect(_pixelAt(normalized, 1, 3), colors[3]);
    });

    test('rounds one contain scale and preserves the final source border', () {
      final source = img.Image(width: 2, height: 3, numChannels: 4);
      for (var y = 0; y < source.height; y += 1) {
        for (var x = 0; x < source.width; x += 1) {
          source.setPixelRgba(x, y, 10 + x, 20 + y, 30, 255);
        }
      }
      source.setPixelRgba(1, 2, 201, 202, 203, 255);

      final result = normalizeRasterAssetToGrid(
        RasterAssetGridNormalizationRequest(
          bytes: img.encodePng(source),
          gridWidth: 1,
          gridHeight: 1,
          targetWidth: 4,
          targetHeight: 4,
          anchor: RasterAssetAnchor.topLeft,
          resizeMode: RasterAssetResizeMode.containNearest,
        ),
      );
      final normalized = _decodePng(result);

      expect((normalized.width, normalized.height), (4, 4));
      expect(_pixelAt(normalized, 2, 3), const _Pixel(201, 202, 203, 255));
      expect(_pixelAt(normalized, 3, 3), const _Pixel(0, 0, 0, 0));
    });

    test('rejects invalid image bytes and detectable APNG bytes', () {
      expect(
        () => normalizeRasterAssetToGrid(
          RasterAssetGridNormalizationRequest(
            bytes: Uint8List.fromList(<int>[1, 2, 3]),
            gridWidth: 1,
            gridHeight: 1,
          ),
        ),
        throwsA(isA<FormatException>()),
      );
      expect(
        () => normalizeRasterAssetToGrid(
          RasterAssetGridNormalizationRequest(
            bytes: _detectableApngBytes(),
            gridWidth: 1,
            gridHeight: 1,
          ),
        ),
        throwsA(isA<FormatException>()),
      );
    });

    test('rejects oversized source metadata before decoding pixel storage', () {
      expect(
        () => normalizeRasterAssetToGrid(
          RasterAssetGridNormalizationRequest(
            bytes: _pngDimensionsOnly(rasterAssetPixelBudget + 1, 1),
            gridWidth: 1,
            gridHeight: 1,
          ),
        ),
        throwsA(isA<FormatException>()),
      );
    });

    test('rejects a fully transparent image when alpha trim is requested', () {
      expect(
        () => normalizeRasterAssetToGrid(
          RasterAssetGridNormalizationRequest(
            bytes: _solidPng(2, 2, const _Pixel(0, 0, 0, 0)),
            gridWidth: 1,
            gridHeight: 1,
            trimTransparentBorder: true,
          ),
        ),
        throwsA(isA<StateError>()),
      );
    });

    test('rejects zero or negative grid dimensions', () {
      final bytes = _solidPng(1, 1, const _Pixel(1, 2, 3, 255));

      for (final grid in <(int, int)>[(0, 1), (1, 0), (-1, 1), (1, -1)]) {
        expect(
          () => normalizeRasterAssetToGrid(
            RasterAssetGridNormalizationRequest(
              bytes: bytes,
              gridWidth: grid.$1,
              gridHeight: grid.$2,
            ),
          ),
          throwsA(isA<ArgumentError>()),
          reason: 'grid=$grid',
        );
      }
    });

    test('rejects invalid and partial target dimensions', () {
      final bytes = _solidPng(1, 1, const _Pixel(1, 2, 3, 255));
      final invalidTargets = <(int?, int?)>[
        (0, 2),
        (2, 0),
        (-2, 2),
        (2, -2),
        (3, 2),
        (2, 3),
        (2, null),
        (null, 2),
      ];

      for (final target in invalidTargets) {
        expect(
          () => normalizeRasterAssetToGrid(
            RasterAssetGridNormalizationRequest(
              bytes: bytes,
              gridWidth: 2,
              gridHeight: 2,
              targetWidth: target.$1,
              targetHeight: target.$2,
            ),
          ),
          throwsA(isA<ArgumentError>()),
          reason: 'target=$target',
        );
      }
    });

    test('rejects an oversized source when resize mode is none', () {
      expect(
        () => normalizeRasterAssetToGrid(
          RasterAssetGridNormalizationRequest(
            bytes: _solidPng(3, 2, const _Pixel(1, 2, 3, 255)),
            gridWidth: 2,
            gridHeight: 2,
            targetWidth: 2,
            targetHeight: 2,
          ),
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('rejects an excessive target before allocating its canvas', () {
      expect(
        () => normalizeRasterAssetToGrid(
          RasterAssetGridNormalizationRequest(
            bytes: _solidPng(1, 1, const _Pixel(1, 2, 3, 255)),
            gridWidth: 1,
            gridHeight: 1,
            targetWidth: rasterAssetPixelBudget + 1,
            targetHeight: 1,
          ),
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('rejects contain-nearest when no target is supplied', () {
      expect(
        () => normalizeRasterAssetToGrid(
          RasterAssetGridNormalizationRequest(
            bytes: _solidPng(2, 2, const _Pixel(1, 2, 3, 255)),
            gridWidth: 2,
            gridHeight: 2,
            resizeMode: RasterAssetResizeMode.containNearest,
          ),
        ),
        throwsA(isA<ArgumentError>()),
      );
    });
  });

  group('normalize tileset asset CLI', () {
    test('creates the output parent without modifying the input', () async {
      final temp = await Directory.systemTemp.createTemp('normalize_asset_');
      addTearDown(() => temp.delete(recursive: true));
      final input = File('${temp.path}/source.png');
      final original = _solidPng(3, 3, const _Pixel(4, 5, 6, 255));
      await input.writeAsBytes(original);
      final output = File('${temp.path}/nested/output.png');
      final errors = StringBuffer();

      final code = await normalize_cli.runNormalizeTilesetAsset(
        <String>[
          '--input',
          input.path,
          '--output',
          output.path,
          '--grid-width',
          '2',
          '--grid-height',
          '2',
          '--anchor',
          'bottom-center',
          '--resize',
          'none',
        ],
        out: StringBuffer(),
        error: errors,
      );

      expect(code, 0, reason: errors.toString());
      expect(await input.readAsBytes(), orderedEquals(original));
      expect(output.existsSync(), isTrue);
      expect(
        (
          _decodePng(await output.readAsBytes()).width,
          _decodePng(await output.readAsBytes()).height,
        ),
        (4, 4),
      );
    });

    test('parses center and writes symmetrically centered content', () async {
      final temp = await Directory.systemTemp.createTemp('normalize_asset_');
      addTearDown(() => temp.delete(recursive: true));
      final input = File('${temp.path}/source.png');
      await input.writeAsBytes(
        _solidPng(2, 2, const _Pixel(14, 15, 16, 255)),
      );
      final output = File('${temp.path}/output.png');
      final errors = StringBuffer();

      final code = await normalize_cli.runNormalizeTilesetAsset(
        <String>[
          '--input',
          input.path,
          '--output',
          output.path,
          '--grid-width',
          '2',
          '--grid-height',
          '2',
          '--target-width',
          '6',
          '--target-height',
          '6',
          '--anchor',
          'center',
          '--resize',
          'none',
        ],
        out: StringBuffer(),
        error: errors,
      );

      expect(code, 0, reason: errors.toString());
      final normalized = _decodePng(await output.readAsBytes());
      expect(_pixelAt(normalized, 1, 2).alpha, 0);
      expect(_pixelAt(normalized, 2, 2), const _Pixel(14, 15, 16, 255));
      expect(_pixelAt(normalized, 3, 3), const _Pixel(14, 15, 16, 255));
      expect(_pixelAt(normalized, 4, 3).alpha, 0);
      expect(_pixelAt(normalized, 2, 1).alpha, 0);
      expect(_pixelAt(normalized, 2, 4).alpha, 0);
    });

    test('refuses an existing output and preserves its bytes', () async {
      final temp = await Directory.systemTemp.createTemp('normalize_asset_');
      addTearDown(() => temp.delete(recursive: true));
      final input = File('${temp.path}/source.png');
      await input.writeAsBytes(_solidPng(1, 1, const _Pixel(4, 5, 6, 255)));
      final output = File('${temp.path}/output.png');
      final sentinel = Uint8List.fromList(<int>[9, 8, 7]);
      await output.writeAsBytes(sentinel);
      final errors = StringBuffer();

      final code = await normalize_cli.runNormalizeTilesetAsset(
        _normalizerArgs(input.path, output.path),
        out: StringBuffer(),
        error: errors,
      );

      expect(code, normalize_cli.normalizeTilesetOutputExitCode);
      expect(errors.toString(), contains('already exists'));
      expect(await output.readAsBytes(), orderedEquals(sentinel));
    });

    test('preserves output created immediately before exclusive creation',
        () async {
      final temp = await Directory.systemTemp.createTemp('normalize_asset_');
      addTearDown(() => temp.delete(recursive: true));
      final input = File('${temp.path}/source.png');
      await input.writeAsBytes(
        _solidPng(1, 1, const _Pixel(4, 5, 6, 255)),
      );
      final output = File('${temp.path}/output.png');
      final sentinel = Uint8List.fromList(<int>[7, 8, 9]);
      final errors = StringBuffer();

      final code = await normalize_cli.runNormalizeTilesetAsset(
        _normalizerArgs(input.path, output.path),
        out: StringBuffer(),
        error: errors,
        beforeOutputCreateForTesting: () => output.writeAsBytes(sentinel),
      );

      expect(code, normalize_cli.normalizeTilesetOutputExitCode);
      expect(await output.readAsBytes(), orderedEquals(sentinel));
    });

    test('refuses identical input and output paths', () async {
      final temp = await Directory.systemTemp.createTemp('normalize_asset_');
      addTearDown(() => temp.delete(recursive: true));
      final input = File('${temp.path}/source.png');
      final original = _solidPng(1, 1, const _Pixel(4, 5, 6, 255));
      await input.writeAsBytes(original);
      final errors = StringBuffer();

      final code = await normalize_cli.runNormalizeTilesetAsset(
        _normalizerArgs(input.path, input.path),
        out: StringBuffer(),
        error: errors,
      );

      expect(code, normalize_cli.normalizeTilesetOutputExitCode);
      expect(errors.toString(), contains('same file'));
      expect(await input.readAsBytes(), orderedEquals(original));
    });

    test(
      'returns a usage code and explicit error for an invalid enum value',
      () async {
        final errors = StringBuffer();

        final code = await normalize_cli.runNormalizeTilesetAsset(
          <String>[
            '--input',
            'source.png',
            '--output',
            'output.png',
            '--grid-width',
            '32',
            '--grid-height',
            '32',
            '--anchor',
            'middle',
            '--resize',
            'none',
          ],
          out: StringBuffer(),
          error: errors,
        );

        expect(code, normalize_cli.normalizeTilesetUsageExitCode);
        expect(errors.toString(), contains('top-left|center|bottom-center'));
      },
    );

    test('maps a target pixel-budget rejection to the data exit code',
        () async {
      final temp = await Directory.systemTemp.createTemp('normalize_asset_');
      addTearDown(() => temp.delete(recursive: true));
      final input = File('${temp.path}/source.png');
      await input.writeAsBytes(
        _solidPng(1, 1, const _Pixel(4, 5, 6, 255)),
      );
      final output = File('${temp.path}/output.png');
      final errors = StringBuffer();

      final code = await normalize_cli.runNormalizeTilesetAsset(
        <String>[
          '--input',
          input.path,
          '--output',
          output.path,
          '--grid-width',
          '1',
          '--grid-height',
          '1',
          '--target-width',
          '${rasterAssetPixelBudget + 1}',
          '--target-height',
          '1',
          '--anchor',
          'bottom-center',
          '--resize',
          'none',
        ],
        out: StringBuffer(),
        error: errors,
      );

      expect(code, normalize_cli.normalizeTilesetDataExitCode);
      expect(errors.toString(), contains('pixel budget'));
      expect(output.existsSync(), isFalse);
    });
  });
}

List<String> _normalizerArgs(String input, String output) => <String>[
      '--input',
      input,
      '--output',
      output,
      '--grid-width',
      '1',
      '--grid-height',
      '1',
      '--anchor',
      'bottom-center',
      '--resize',
      'none',
    ];

Uint8List _solidPng(int width, int height, _Pixel pixel) {
  final image = img.Image(width: width, height: height, numChannels: 4);
  for (var y = 0; y < height; y += 1) {
    for (var x = 0; x < width; x += 1) {
      image.setPixelRgba(x, y, pixel.red, pixel.green, pixel.blue, pixel.alpha);
    }
  }
  return img.encodePng(image);
}

Uint8List _detectableApngBytes() {
  final png = _solidPng(1, 1, const _Pixel(1, 2, 3, 255));
  final output = BytesBuilder(copy: false)
    ..add(png.sublist(0, 33))
    ..add(_pngChunk('acTL', <int>[0, 0, 0, 1, 0, 0, 0, 0]))
    ..add(png.sublist(33));
  return output.takeBytes();
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
