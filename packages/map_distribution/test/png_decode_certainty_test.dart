import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:image/image.dart' as img;
import 'package:map_core/map_core.dart';
import 'package:map_distribution/map_distribution.dart';
import 'package:map_distribution/src/png_decode_certainty.dart';
import 'package:map_distribution/src/static_png_validation.dart';
import 'package:test/test.dart';

import 'support/spatial_package_fixture.dart';

void main() {
  group('PNG decode certainty agrees with the full decoder', () {
    const supported = [
      (0, 1),
      (0, 2),
      (0, 4),
      (0, 8),
      (0, 16),
      (2, 8),
      (2, 16),
      (3, 1),
      (3, 2),
      (3, 4),
      (3, 8),
      (4, 8),
      (4, 16),
      (6, 8),
      (6, 16),
    ];
    for (final (color, bits) in supported) {
      for (final interlace in [0, 1]) {
        test('color $color / $bits bits / interlace $interlace', () {
          final bytes = _png(
              width: 13,
              height: 9,
              color: color,
              bits: bits,
              interlace: interlace);
          expect(_fullDecodeSucceeds(bytes), isTrue);
          expect(_certain(bytes), interlace == 0);
        });
      }
    }

    test('encoder outputs are accepted exactly when they decode', () {
      final random = Random(7);
      img.Image filled(img.Image image) {
        for (final pixel in image) {
          for (var channel = 0; channel < image.numChannels; channel++) {
            pixel[channel] = random.nextInt(pixel.maxChannelValue.toInt() + 1);
          }
        }
        return image;
      }

      final samples = [
        filled(img.Image(width: 31, height: 17, numChannels: 1)),
        filled(img.Image(width: 31, height: 17, numChannels: 2)),
        filled(img.Image(width: 31, height: 17)),
        filled(img.Image(width: 31, height: 17, numChannels: 4)),
        filled(img.Image(
            width: 31, height: 17, numChannels: 4, format: img.Format.uint16)),
        img.quantize(filled(img.Image(width: 31, height: 17)),
            numberOfColors: 16),
      ];
      for (final sample in samples) {
        for (final filter in img.PngFilter.values) {
          final bytes = img.encodePng(sample, filter: filter);
          expect(_fullDecodeSucceeds(bytes), isTrue);
          expect(_certain(bytes), isTrue,
              reason:
                  '${sample.numChannels} channels ${sample.format} $filter');
        }
      }
      final misframed = img.encodePng(img.Image(
          width: 31, height: 17, numChannels: 1, format: img.Format.uint4));
      expect(_fullDecodeSucceeds(misframed), isTrue);
      expect(_certain(misframed), isFalse);
    });

    test('ancillary chunks the decoder reads safely stay on the fast path', () {
      final extras = [
        _chunk('tEXt', [...ascii.encode('Title'), 0, ...ascii.encode('x')]),
        _chunk('pHYs', [0, 0, 11, 19, 0, 0, 11, 19, 1]),
        _chunk('gAMA', [0, 0, 177, 143]),
        _chunk('bKGD', [0, 1, 0, 2, 0, 3]),
        _chunk('iCCP', [...ascii.encode('sRGB'), 0, 0, 1, 2, 3]),
        _chunk('tRNS', [0, 1, 0, 2, 0, 3]),
        _chunk('cICP', [1, 13, 0, 1]),
        _chunk('zzZz', [9, 9, 9]),
      ];
      final bytes = _png(width: 5, height: 3, color: 2, extras: extras);
      expect(_fullDecodeSucceeds(bytes), isTrue);
      expect(_certain(bytes), isTrue);
      final indexed = _png(width: 5, height: 3, color: 3, bits: 4, extras: [
        _chunk('tRNS', [0, 128]),
        _chunk('bKGD', [1]),
      ]);
      expect(_fullDecodeSucceeds(indexed), isTrue);
      expect(_certain(indexed), isTrue);
    });

    final corrupted = <String, Uint8List>{
      'truncated IDAT': _png(width: 6, height: 4, truncateInflated: 1),
      'surplus scanlines': _png(width: 6, height: 4, surplusInflated: 3),
      'bad zlib header': _png(width: 6, height: 4, corruptZlibHeader: true),
      'wrong IHDR size': _png(width: 6, height: 4, headerLength: 14),
      'filter byte 7': _png(width: 6, height: 4, filterOverride: 7),
      'missing IEND': _png(width: 6, height: 4, withEnd: false),
      'IDAT checksum': _png(width: 6, height: 4, corruptIdatCrc: true),
      'animation control': _png(width: 6, height: 4, extras: [
        _chunk('acTL', [0, 0, 0, 1, 0, 0, 0, 0])
      ]),
      'short gamma': _png(width: 6, height: 4, extras: [
        _chunk('gAMA', [0, 1, 2])
      ]),
      'odd gray transparency': _png(width: 6, height: 4, color: 0, extras: [
        _chunk('tRNS', [0])
      ]),
      'background outside palette':
          _png(width: 6, height: 4, color: 3, extras: [
        _chunk('bKGD', [20])
      ]),
      'palette without PLTE':
          _png(width: 6, height: 4, color: 3, palette: false),
      'unterminated ICC name': _png(width: 6, height: 4, extras: [
        _chunk('iCCP', [65, 66])
      ]),
      'unsupported bit depth': _png(width: 6, height: 4, color: 2, bits: 4),
    };
    for (final MapEntry(key: name, value: bytes) in corrupted.entries) {
      test('$name falls back to the full decoder', () {
        expect(_certain(bytes), isFalse);
      });
    }

    test('acceptance always implies a successful full decode', () {
      final random = Random(11);
      var accepted = 0;
      for (var round = 0; round < 400; round++) {
        final base = _png(width: 4, height: 3, color: 2);
        final mutated = Uint8List.fromList(base);
        final flips = 1 + random.nextInt(3);
        for (var flip = 0; flip < flips; flip++) {
          final index = 8 + random.nextInt(mutated.length - 8);
          mutated[index] ^= 1 << random.nextInt(8);
        }
        final dimensions =
            decodeRasterImageDimensions(mutated, mediaType: 'image/png');
        if (dimensions == null) continue;
        if (isCertainlyDecodablePng(mutated, dimensions)) {
          accepted++;
          expect(_fullDecodeSucceeds(mutated, dimensions), isTrue);
        }
      }
      expect(accepted, greaterThan(0));
    });
  });

  group('spatial validator image outcome is unchanged', () {
    final samples = <String, List<int>>{
      'encoded RGB': img.encodePng(img.Image(width: 32, height: 32)),
      'encoded RGBA 16 bit': img.encodePng(img.Image(
          width: 32, height: 32, numChannels: 4, format: img.Format.uint16)),
      'interlaced': _png(width: 32, height: 32, interlace: 1),
      'truncated IDAT': _png(width: 32, height: 32, truncateInflated: 1),
      'bad zlib header': _png(width: 32, height: 32, corruptZlibHeader: true),
      'wrong IHDR size': _png(width: 32, height: 32, headerLength: 14),
      'filter byte 7': _png(width: 32, height: 32, filterOverride: 7),
      'missing IEND': _png(width: 32, height: 32, withEnd: false),
      'IDAT checksum': _png(width: 32, height: 32, corruptIdatCrc: true),
      'surplus scanlines': _png(width: 32, height: 32, surplusInflated: 40),
    };
    for (final MapEntry(key: name, value: bytes) in samples.entries) {
      test(name, () {
        final files = _withHeroImage(bytes);
        final project = ProjectManifest.fromJson(
            jsonDecode(utf8.decode(files['project/project.json']!)));
        String? actual;
        try {
          const GamePackageSpatialProjectValidator()
              .validate(project, (path) => files[path]);
        } on GamePackageFormatException catch (error) {
          actual = error.code;
        }
        expect(actual, _previousImageOutcome(bytes));
      });
    }
  });
}

bool _certain(List<int> bytes) {
  final dimensions = decodeRasterImageDimensions(bytes, mediaType: 'image/png');
  return dimensions != null && isCertainlyDecodablePng(bytes, dimensions);
}

bool _fullDecodeSucceeds(List<int> bytes, [RasterImageDimensions? dimensions]) {
  final expected =
      dimensions ?? decodeRasterImageDimensions(bytes, mediaType: 'image/png');
  try {
    final decoded = img.decodeImage(Uint8List.fromList(bytes));
    return decoded != null &&
        expected != null &&
        decoded.width == expected.width &&
        decoded.height == expected.height;
  } on Object {
    return false;
  }
}

String? _previousImageOutcome(List<int> bytes) {
  final dimensions = decodeRasterImageDimensions(bytes, mediaType: 'image/png');
  if (dimensions == null) return 'decodedAssetQuotaExceeded';
  try {
    final decoded = img.decodeImage(Uint8List.fromList(bytes));
    if (decoded == null ||
        decoded.width != dimensions.width ||
        decoded.height != dimensions.height) {
      return 'runtime3d.image_invalid';
    }
  } on Object {
    return 'runtime3d.invalid_project';
  }
  return null;
}

Map<String, List<int>> _withHeroImage(List<int> bytes) {
  final files = spatialPayload();
  final catalogue =
      jsonDecode(utf8.decode(files['project/assets/.pokemap-assets.json']!))
          as Map<String, dynamic>;
  final record = (catalogue['records'] as List)
      .cast<Map<String, dynamic>>()
      .singleWhere((record) => record['id'] == 'hero-source');
  final previous = record['artifact']['digest'] as String;
  files.remove('project/assets/.pokemap-store/${previous.substring(7)}.blob');
  final digest = computeNarrativeProjectFingerprint([
    NarrativeProjectFingerprintEntry(
        relativePath: 'artifact-content', bytes: bytes),
  ]);
  files['project/assets/.pokemap-store/${digest.substring(7)}.blob'] = bytes;
  files['project/assets/hero.png'] = bytes;
  record['artifact'] = {
    'digest': digest,
    'handle': 'artifact://sha256/${digest.substring(7)}',
    'mediaType': 'image/png',
    'byteLength': bytes.length,
  };
  files['project/assets/.pokemap-assets.json'] =
      utf8.encode(jsonEncode(catalogue));
  return files;
}

Uint8List _png({
  required int width,
  required int height,
  int color = 6,
  int bits = 8,
  int interlace = 0,
  int headerLength = 13,
  bool palette = true,
  List<Uint8List> extras = const [],
  int truncateInflated = 0,
  int surplusInflated = 0,
  int? filterOverride,
  bool corruptZlibHeader = false,
  bool corruptIdatCrc = false,
  bool withEnd = true,
}) {
  final header = ByteData(headerLength)
    ..setUint32(0, width)
    ..setUint32(4, height)
    ..setUint8(8, bits)
    ..setUint8(9, color)
    ..setUint8(12, interlace);
  final info = img.PngInfo()
    ..width = width
    ..height = height
    ..bits = bits
    ..colorType = color
    ..interlaceMethod = interlace;
  final channels = switch (color) { 2 => 3, 4 => 2, 6 => 4, _ => 1 };
  final stride = 1 + ((width * channels * bits + 7) >> 3);
  final random = Random(width * 31 + height);
  final raw = Uint8List(
      staticPngScanlineBytes(info) - truncateInflated + surplusInflated);
  for (var index = 0; index < raw.length; index++) {
    raw[index] = random.nextInt(256);
  }
  if (interlace == 0) {
    for (var row = 0; row * stride < raw.length; row++) {
      raw[row * stride] = filterOverride ?? row % 5;
    }
  } else {
    raw.fillRange(0, raw.length, 0);
  }
  final compressed = Uint8List.fromList(ZLibEncoder().encode(raw));
  if (corruptZlibHeader) compressed[0] = 0;
  final idat = _chunk('IDAT', compressed);
  if (corruptIdatCrc) idat[idat.length - 1] ^= 1;
  final output = BytesBuilder()
    ..add([137, 80, 78, 71, 13, 10, 26, 10])
    ..add(_chunk('IHDR', header.buffer.asUint8List()));
  if (color == 3 && palette) {
    output.add(_chunk('PLTE', [for (var i = 0; i < 48; i++) i * 5]));
  }
  for (final extra in extras) {
    output.add(extra);
  }
  output.add(idat);
  if (withEnd) output.add(_chunk('IEND', const []));
  return output.takeBytes();
}

Uint8List _chunk(String type, List<int> data) {
  final typeBytes = ascii.encode(type);
  final crc = getCrc32(data, getCrc32(typeBytes));
  return (BytesBuilder()
        ..add((ByteData(4)..setUint32(0, data.length)).buffer.asUint8List())
        ..add(typeBytes)
        ..add(data)
        ..add((ByteData(4)..setUint32(0, crc)).buffer.asUint8List()))
      .takeBytes();
}
