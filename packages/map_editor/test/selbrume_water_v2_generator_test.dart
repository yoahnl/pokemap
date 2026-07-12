import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;

const _toolPath = 'tool/generate_selbrume_water_v2.dart';
const _openSeaName = 'selbrume_open_sea_v2.png';
const _coastName = 'selbrume_coast_v2.png';
const _marshName = 'selbrume_marsh_water_v2.png';
const _expectedNames = <String>[
  _coastName,
  _marshName,
  _openSeaName,
];

void main() {
  late Directory outputDirectory;
  late Map<String, Uint8List> firstBytes;
  late Map<String, String> firstHashes;

  setUpAll(() async {
    outputDirectory = await Directory.systemTemp.createTemp(
      'selbrume_water_v2_test_',
    );
    final result = await _runGenerator(outputDirectory);
    expect(
      result.exitCode,
      0,
      reason: 'stdout:\n${result.stdout}\nstderr:\n${result.stderr}',
    );
    firstBytes = <String, Uint8List>{
      for (final name in _expectedNames)
        name: await File('${outputDirectory.path}/$name').readAsBytes(),
    };
    firstHashes = <String, String>{
      for (final name in _expectedNames)
        name: await _sha256(File('${outputDirectory.path}/$name')),
    };
  });

  tearDownAll(() async {
    if (await outputDirectory.exists()) {
      await outputDirectory.delete(recursive: true);
    }
  });

  test('writes only the three canonical water-v2 PNG files', () async {
    final names = await outputDirectory
        .list()
        .where((entity) => entity is File)
        .map((entity) => entity.uri.pathSegments.last)
        .toList();
    names.sort();

    expect(names, _expectedNames);
  });

  test('uses the exact runtime-compatible dimensions and alpha contracts', () {
    final openSea = _decode(firstBytes[_openSeaName]!);
    final coast = _decode(firstBytes[_coastName]!);
    final marsh = _decode(firstBytes[_marshName]!);

    expect((openSea.width, openSea.height), (4096, 128));
    expect((coast.width, coast.height), (480, 128));
    expect((marsh.width, marsh.height), (512, 256));
    expect(openSea.numChannels, 4);
    expect(coast.numChannels, 4);
    expect(marsh.numChannels, 4);

    expect(_alphaExtrema(openSea), (255, 255));
    expect(_alphaExtrema(coast), (0, 255));
    expect(_partialAlphaCount(coast), greaterThan(0));
    expect(_alphaExtrema(marsh), (0, 255));
    expect(_partialAlphaCount(marsh), greaterThan(0));

    for (var y = 0; y < 128; y += 1) {
      for (var x = 0; x < 512; x += 1) {
        expect(marsh.getPixel(x, y).a.toInt(), 255);
      }
    }
  });

  test('is byte-idempotent and keeps stable SHA-256 hashes', () async {
    final result = await _runGenerator(outputDirectory);
    expect(
      result.exitCode,
      0,
      reason: 'stdout:\n${result.stdout}\nstderr:\n${result.stderr}',
    );

    for (final name in _expectedNames) {
      final file = File('${outputDirectory.path}/$name');
      expect(await file.readAsBytes(), orderedEquals(firstBytes[name]!));
      expect(await _sha256(file), firstHashes[name]);
      expect(firstHashes[name], hasLength(64));
    }
  });

  test('open sea is vivid blue and spatially and temporally seamless', () {
    final image = _decode(firstBytes[_openSeaName]!);
    final average = _averageColor(image, 0, 0, image.width, image.height);

    expect(average.blue, greaterThan(average.green + 25));
    expect(average.green, greaterThan(average.red + 35));
    expect(
      _logicalTransitionRatio(image, frameX: 0, frameY: 0),
      lessThan(.20),
      reason: 'broad water masses must dominate over checkerboard noise',
    );
    _expectSpatialSeams(
      image,
      frameCount: 32,
      frameWidth: 128,
      frameHeight: 128,
      frameX: (frame) => frame * 128,
      frameY: (_) => 0,
    );
    _expectTemporalLoop(
      image,
      frameCount: 32,
      frameWidth: 128,
      frameHeight: 128,
      frameX: (frame) => frame * 128,
      frameY: (_) => 0,
    );
  });

  test('coast atlas covers all fifteen non-cross masks for four frames', () {
    final image = _decode(firstBytes[_coastName]!);

    _expectBoundaryAtlasCoverage(image, yOffset: 0);
    _expectBoundaryAtlasTemporalLoops(image, yOffset: 0);
  });

  test('marsh output contains a subdued seamless center and all shores', () {
    final marsh = _decode(firstBytes[_marshName]!);
    final openSea = _decode(firstBytes[_openSeaName]!);
    final marshAverage = _averageColor(marsh, 0, 0, 512, 128);
    final seaAverage = _averageColor(openSea, 0, 0, 4096, 128);

    expect(marshAverage.blue, greaterThan(marshAverage.green));
    expect(marshAverage.green, greaterThan(marshAverage.red));
    expect(
      marshAverage.saturation,
      lessThan(seaAverage.saturation - 25),
    );
    _expectSpatialSeams(
      marsh,
      frameCount: 4,
      frameWidth: 128,
      frameHeight: 128,
      frameX: (frame) => frame * 128,
      frameY: (_) => 0,
    );
    _expectTemporalLoop(
      marsh,
      frameCount: 4,
      frameWidth: 128,
      frameHeight: 128,
      frameX: (frame) => frame * 128,
      frameY: (_) => 0,
    );
    _expectBoundaryAtlasCoverage(marsh, yOffset: 128);
    _expectBoundaryAtlasTemporalLoops(marsh, yOffset: 128);
  });
}

Future<ProcessResult> _runGenerator(Directory outputDirectory) {
  return Process.run(
    'dart',
    <String>[
      'run',
      _toolPath,
      '--output-dir',
      outputDirectory.path,
    ],
    workingDirectory: Directory.current.path,
  );
}

Future<String> _sha256(File file) async {
  final result = await Process.run(
    'shasum',
    <String>['-a', '256', file.path],
  );
  if (result.exitCode != 0) {
    throw StateError('shasum failed: ${result.stderr}');
  }
  return (result.stdout as String).split(RegExp(r'\s+')).first;
}

img.Image _decode(Uint8List bytes) {
  final decoded = img.decodePng(bytes);
  if (decoded == null) {
    throw StateError('Generated bytes are not a PNG.');
  }
  return decoded;
}

(int, int) _alphaExtrema(img.Image image) {
  var minimum = 255;
  var maximum = 0;
  for (final pixel in image) {
    final alpha = pixel.a.toInt();
    minimum = math.min(minimum, alpha);
    maximum = math.max(maximum, alpha);
  }
  return (minimum, maximum);
}

int _partialAlphaCount(img.Image image) {
  var count = 0;
  for (final pixel in image) {
    final alpha = pixel.a.toInt();
    if (alpha > 0 && alpha < 255) count += 1;
  }
  return count;
}

void _expectBoundaryAtlasCoverage(img.Image image, {required int yOffset}) {
  const frameCount = 4;
  const cellSize = 32;
  for (var mask = 0; mask < 15; mask += 1) {
    for (var frame = 0; frame < frameCount; frame += 1) {
      final originX = mask * cellSize;
      final originY = yOffset + frame * cellSize;
      var opaque = 0;
      var transparent = 0;
      for (var y = 0; y < cellSize; y += 1) {
        for (var x = 0; x < cellSize; x += 1) {
          final alpha = image.getPixel(originX + x, originY + y).a.toInt();
          if (alpha == 0) transparent += 1;
          if (alpha == 255) opaque += 1;
        }
      }
      expect(opaque, greaterThan(0), reason: 'mask=$mask frame=$frame');
      expect(
        transparent,
        greaterThan(0),
        reason: 'mask=$mask frame=$frame must remain an alpha boundary',
      );

      _expectEdgeConnection(
        image,
        originX: originX,
        originY: originY,
        x: 16,
        y: 0,
        connected: mask & 1 != 0,
        label: 'north mask=$mask frame=$frame',
      );
      _expectEdgeConnection(
        image,
        originX: originX,
        originY: originY,
        x: 31,
        y: 16,
        connected: mask & 2 != 0,
        label: 'east mask=$mask frame=$frame',
      );
      _expectEdgeConnection(
        image,
        originX: originX,
        originY: originY,
        x: 16,
        y: 31,
        connected: mask & 4 != 0,
        label: 'south mask=$mask frame=$frame',
      );
      _expectEdgeConnection(
        image,
        originX: originX,
        originY: originY,
        x: 0,
        y: 16,
        connected: mask & 8 != 0,
        label: 'west mask=$mask frame=$frame',
      );
    }
  }
}

void _expectEdgeConnection(
  img.Image image, {
  required int originX,
  required int originY,
  required int x,
  required int y,
  required bool connected,
  required String label,
}) {
  final alpha = image.getPixel(originX + x, originY + y).a.toInt();
  if (connected) {
    expect(alpha, 255, reason: label);
  } else {
    expect(alpha, 0, reason: label);
  }
}

void _expectBoundaryAtlasTemporalLoops(
  img.Image image, {
  required int yOffset,
}) {
  for (var mask = 0; mask < 15; mask += 1) {
    _expectTemporalLoop(
      image,
      frameCount: 4,
      frameWidth: 32,
      frameHeight: 32,
      frameX: (_) => mask * 32,
      frameY: (frame) => yOffset + frame * 32,
    );
  }
}

void _expectSpatialSeams(
  img.Image image, {
  required int frameCount,
  required int frameWidth,
  required int frameHeight,
  required int Function(int frame) frameX,
  required int Function(int frame) frameY,
}) {
  for (var frame = 0; frame < frameCount; frame += 1) {
    final originX = frameX(frame);
    final originY = frameY(frame);
    final horizontalInternal = <double>[];
    for (var x = 0; x < frameWidth - 1; x += 1) {
      horizontalInternal.add(
        _meanColumnDelta(
          image,
          originX + x,
          originX + x + 1,
          originY,
          frameHeight,
        ),
      );
    }
    final verticalInternal = <double>[];
    for (var y = 0; y < frameHeight - 1; y += 1) {
      verticalInternal.add(
        _meanRowDelta(
          image,
          originY + y,
          originY + y + 1,
          originX,
          frameWidth,
        ),
      );
    }
    final leftRight = _meanColumnDelta(
      image,
      originX + frameWidth - 1,
      originX,
      originY,
      frameHeight,
    );
    final topBottom = _meanRowDelta(
      image,
      originY + frameHeight - 1,
      originY,
      originX,
      frameWidth,
    );

    expect(
      leftRight,
      lessThanOrEqualTo(_percentile(horizontalInternal, .95) * 1.5 + .01),
      reason: 'left/right seam frame=$frame',
    );
    expect(
      topBottom,
      lessThanOrEqualTo(_percentile(verticalInternal, .95) * 1.5 + .01),
      reason: 'top/bottom seam frame=$frame',
    );
  }
}

void _expectTemporalLoop(
  img.Image image, {
  required int frameCount,
  required int frameWidth,
  required int frameHeight,
  required int Function(int frame) frameX,
  required int Function(int frame) frameY,
}) {
  final adjacent = <double>[];
  for (var frame = 0; frame < frameCount - 1; frame += 1) {
    adjacent.add(
      _meanFrameDelta(
        image,
        frameX(frame),
        frameY(frame),
        frameX(frame + 1),
        frameY(frame + 1),
        frameWidth,
        frameHeight,
      ),
    );
  }
  final lastToFirst = _meanFrameDelta(
    image,
    frameX(frameCount - 1),
    frameY(frameCount - 1),
    frameX(0),
    frameY(0),
    frameWidth,
    frameHeight,
  );
  final sorted = [...adjacent]..sort();
  final median = _percentile(sorted, .5);
  final p95 = _percentile(sorted, .95);

  expect(
    lastToFirst,
    lessThanOrEqualTo(math.max(1.5 * median, p95) + .01),
  );
}

double _meanFrameDelta(
  img.Image image,
  int ax,
  int ay,
  int bx,
  int by,
  int width,
  int height,
) {
  var total = 0;
  for (var y = 0; y < height; y += 1) {
    for (var x = 0; x < width; x += 1) {
      total += _pixelDelta(
        image.getPixel(ax + x, ay + y),
        image.getPixel(bx + x, by + y),
      );
    }
  }
  return total / (width * height * 4);
}

double _meanColumnDelta(
  img.Image image,
  int ax,
  int bx,
  int y,
  int height,
) {
  var total = 0;
  for (var offset = 0; offset < height; offset += 1) {
    total += _pixelDelta(
      image.getPixel(ax, y + offset),
      image.getPixel(bx, y + offset),
    );
  }
  return total / (height * 4);
}

double _meanRowDelta(
  img.Image image,
  int ay,
  int by,
  int x,
  int width,
) {
  var total = 0;
  for (var offset = 0; offset < width; offset += 1) {
    total += _pixelDelta(
      image.getPixel(x + offset, ay),
      image.getPixel(x + offset, by),
    );
  }
  return total / (width * 4);
}

int _pixelDelta(img.Pixel a, img.Pixel b) {
  return (a.r.toInt() - b.r.toInt()).abs() +
      (a.g.toInt() - b.g.toInt()).abs() +
      (a.b.toInt() - b.b.toInt()).abs() +
      (a.a.toInt() - b.a.toInt()).abs();
}

double _logicalTransitionRatio(
  img.Image image, {
  required int frameX,
  required int frameY,
}) {
  var transitions = 0;
  var comparisons = 0;
  for (var y = 0; y < 64; y += 1) {
    for (var x = 0; x < 64; x += 1) {
      final pixel = image.getPixel(frameX + x * 2, frameY + y * 2);
      if (x + 1 < 64) {
        comparisons += 1;
        if (_pixelDelta(
              pixel,
              image.getPixel(frameX + (x + 1) * 2, frameY + y * 2),
            ) >
            0) {
          transitions += 1;
        }
      }
      if (y + 1 < 64) {
        comparisons += 1;
        if (_pixelDelta(
              pixel,
              image.getPixel(frameX + x * 2, frameY + (y + 1) * 2),
            ) >
            0) {
          transitions += 1;
        }
      }
    }
  }
  return transitions / comparisons;
}

double _percentile(List<double> values, double percentile) {
  final sorted = [...values]..sort();
  final index = ((sorted.length - 1) * percentile).round();
  return sorted[index];
}

_AverageColor _averageColor(
  img.Image image,
  int originX,
  int originY,
  int width,
  int height,
) {
  var red = 0;
  var green = 0;
  var blue = 0;
  var count = 0;
  for (var y = 0; y < height; y += 1) {
    for (var x = 0; x < width; x += 1) {
      final pixel = image.getPixel(originX + x, originY + y);
      if (pixel.a.toInt() == 0) continue;
      red += pixel.r.toInt();
      green += pixel.g.toInt();
      blue += pixel.b.toInt();
      count += 1;
    }
  }
  return _AverageColor(red / count, green / count, blue / count);
}

final class _AverageColor {
  const _AverageColor(this.red, this.green, this.blue);

  final double red;
  final double green;
  final double blue;

  double get saturation =>
      math.max(red, math.max(green, blue)) -
      math.min(red, math.min(green, blue));
}
