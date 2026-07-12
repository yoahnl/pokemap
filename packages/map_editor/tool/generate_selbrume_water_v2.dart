import 'dart:io';
import 'dart:typed_data';

import 'package:image/image.dart' as img;

const selbrumeOpenSeaV2FileName = 'selbrume_open_sea_v2.png';
const selbrumeCoastV2FileName = 'selbrume_coast_v2.png';
const selbrumeMarshWaterV2FileName = 'selbrume_marsh_water_v2.png';

const selbrumeOpenSeaFrameCount = 32;
const selbrumeOpenSeaFrameSize = 128;
const selbrumeBoundaryFrameCount = 4;
const selbrumeBoundaryFrameSize = 32;

/// Stable column order for the 15 cardinal-mask variants below `cross`.
///
/// In the coast atlas, `x = column * 32` and `y = frame * 32`. In the
/// marsh atlas, the same layout starts at `y = 128`. The marsh center uses
/// four 128x128 frames at `(frame * 128, 0)`.
const selbrumeWaterBoundaryVariants = <SelbrumeWaterBoundaryVariant>[
  SelbrumeWaterBoundaryVariant(mask: 0, name: 'isolated'),
  SelbrumeWaterBoundaryVariant(mask: 1, name: 'endNorth'),
  SelbrumeWaterBoundaryVariant(mask: 2, name: 'endEast'),
  SelbrumeWaterBoundaryVariant(mask: 3, name: 'cornerNE'),
  SelbrumeWaterBoundaryVariant(mask: 4, name: 'endSouth'),
  SelbrumeWaterBoundaryVariant(mask: 5, name: 'vertical'),
  SelbrumeWaterBoundaryVariant(mask: 6, name: 'cornerSE'),
  SelbrumeWaterBoundaryVariant(mask: 7, name: 'teeEast'),
  SelbrumeWaterBoundaryVariant(mask: 8, name: 'endWest'),
  SelbrumeWaterBoundaryVariant(mask: 9, name: 'cornerNW'),
  SelbrumeWaterBoundaryVariant(mask: 10, name: 'horizontal'),
  SelbrumeWaterBoundaryVariant(mask: 11, name: 'teeNorth'),
  SelbrumeWaterBoundaryVariant(mask: 12, name: 'cornerSW'),
  SelbrumeWaterBoundaryVariant(mask: 13, name: 'teeWest'),
  SelbrumeWaterBoundaryVariant(mask: 14, name: 'teeSouth'),
];

const _usage = 'Usage: dart run tool/generate_selbrume_water_v2.dart '
    '--output-dir <directory>';

Future<void> main(List<String> args) async {
  exitCode = await runGenerateSelbrumeWaterV2(args);
}

Future<int> runGenerateSelbrumeWaterV2(
  List<String> args, {
  StringSink? out,
  StringSink? error,
}) async {
  final output = out ?? stdout;
  final errors = error ?? stderr;
  final outputPath = _parseOutputDirectory(args);
  if (outputPath == null) {
    errors.writeln(_usage);
    return 64;
  }

  final artifacts = generateSelbrumeWaterV2();
  final directory = Directory(outputPath);
  try {
    await directory.create(recursive: true);
    for (final entry in artifacts.files.entries) {
      final file = File('${directory.path}/${entry.key}');
      final changed = await _writeIfChanged(file, entry.value);
      output.writeln('${changed ? 'Wrote' : 'Unchanged'} ${file.path}');
    }
  } on FileSystemException catch (exception) {
    errors.writeln('error: ${exception.message}');
    return 73;
  }
  return 0;
}

SelbrumeWaterV2Artifacts generateSelbrumeWaterV2() {
  final openSea = _buildOpenSeaStrip();
  final coast = _buildBoundaryAtlas(_WaterStyle.openSea);
  final marsh = _buildMarshAtlas();
  return SelbrumeWaterV2Artifacts(
    openSea: Uint8List.fromList(img.encodePng(openSea)),
    coast: Uint8List.fromList(img.encodePng(coast)),
    marsh: Uint8List.fromList(img.encodePng(marsh)),
  );
}

img.Image _buildOpenSeaStrip() {
  final strip = img.Image(
    width: selbrumeOpenSeaFrameCount * selbrumeOpenSeaFrameSize,
    height: selbrumeOpenSeaFrameSize,
    numChannels: 4,
  );
  for (var frame = 0; frame < selbrumeOpenSeaFrameCount; frame += 1) {
    _paintWaterFrame(
      strip,
      originX: frame * selbrumeOpenSeaFrameSize,
      originY: 0,
      frame: frame,
      frameCount: selbrumeOpenSeaFrameCount,
      style: _WaterStyle.openSea,
    );
  }
  return strip;
}

img.Image _buildMarshAtlas() {
  final atlas = img.Image(width: 512, height: 256, numChannels: 4);
  for (var frame = 0; frame < selbrumeBoundaryFrameCount; frame += 1) {
    _paintWaterFrame(
      atlas,
      originX: frame * selbrumeOpenSeaFrameSize,
      originY: 0,
      frame: frame,
      frameCount: selbrumeBoundaryFrameCount,
      style: _WaterStyle.marsh,
    );
  }
  _paintBoundaryAtlas(
    atlas,
    style: _WaterStyle.marsh,
    originY: 128,
  );
  return atlas;
}

img.Image _buildBoundaryAtlas(_WaterStyle style) {
  final atlas = img.Image(width: 480, height: 128, numChannels: 4);
  _paintBoundaryAtlas(atlas, style: style, originY: 0);
  return atlas;
}

void _paintBoundaryAtlas(
  img.Image atlas, {
  required _WaterStyle style,
  required int originY,
}) {
  for (var column = 0;
      column < selbrumeWaterBoundaryVariants.length;
      column += 1) {
    final variant = selbrumeWaterBoundaryVariants[column];
    final mask = _buildBoundaryMask(variant.mask);
    for (var frame = 0; frame < selbrumeBoundaryFrameCount; frame += 1) {
      _paintBoundaryCell(
        atlas,
        originX: column * selbrumeBoundaryFrameSize,
        originY: originY + frame * selbrumeBoundaryFrameSize,
        frame: frame,
        frameCount: selbrumeBoundaryFrameCount,
        mask: mask,
        cardinalMask: variant.mask,
        style: style,
      );
    }
  }
}

void _paintWaterFrame(
  img.Image destination, {
  required int originX,
  required int originY,
  required int frame,
  required int frameCount,
  required _WaterStyle style,
}) {
  const logicalSize = 64;
  const scale = 2;
  for (var y = 0; y < logicalSize; y += 1) {
    for (var x = 0; x < logicalSize; x += 1) {
      final color = _waterColor(
        x: x,
        y: y,
        period: logicalSize,
        frame: frame,
        frameCount: frameCount,
        style: style,
      );
      _setScaledPixel(
        destination,
        originX: originX,
        originY: originY,
        x: x,
        y: y,
        scale: scale,
        color: color,
        alpha: 255,
      );
    }
  }
  _paintToroidalGlints(
    destination,
    originX: originX,
    originY: originY,
    logicalSize: logicalSize,
    scale: scale,
    frame: frame,
    frameCount: frameCount,
    style: style,
  );
  _sealFrameEdges(
    destination,
    originX: originX,
    originY: originY,
    size: logicalSize * scale,
    pixelScale: scale,
  );
}

void _sealFrameEdges(
  img.Image image, {
  required int originX,
  required int originY,
  required int size,
  required int pixelScale,
}) {
  for (var y = 0; y < size; y += 1) {
    for (var offset = 0; offset < pixelScale; offset += 1) {
      final source = image.getPixel(originX + offset, originY + y);
      image.setPixelRgba(
        originX + size - pixelScale + offset,
        originY + y,
        source.r.toInt(),
        source.g.toInt(),
        source.b.toInt(),
        source.a.toInt(),
      );
    }
  }
  for (var x = 0; x < size; x += 1) {
    for (var offset = 0; offset < pixelScale; offset += 1) {
      final source = image.getPixel(originX + x, originY + offset);
      image.setPixelRgba(
        originX + x,
        originY + size - pixelScale + offset,
        source.r.toInt(),
        source.g.toInt(),
        source.b.toInt(),
        source.a.toInt(),
      );
    }
  }
}

void _paintToroidalGlints(
  img.Image destination, {
  required int originX,
  required int originY,
  required int logicalSize,
  required int scale,
  required int frame,
  required int frameCount,
  required _WaterStyle style,
}) {
  final count = style == _WaterStyle.openSea ? 12 : 5;
  final frameStep = logicalSize ~/ frameCount;
  for (var index = 0; index < count; index += 1) {
    final startX = (index * 23 + index * index * 7 + 5) % logicalSize;
    final startY = (index * 37 + index * index * 3 + 11) % logicalSize;
    final directionX = index.isEven ? 1 : -1;
    final directionY = index % 3 == 0 ? 1 : 0;
    final x = _mod(startX + directionX * frame * frameStep, logicalSize);
    final y = _mod(startY + directionY * frame * frameStep, logicalSize);
    final bright = style == _WaterStyle.openSea
        ? const _Rgba(218, 245, 255, 255)
        : const _Rgba(164, 205, 205, 255);
    final soft = style == _WaterStyle.openSea
        ? const _Rgba(111, 206, 255, 255)
        : const _Rgba(111, 168, 170, 255);
    _setToroidalScaledPixel(
      destination,
      originX: originX,
      originY: originY,
      logicalSize: logicalSize,
      scale: scale,
      x: x,
      y: y,
      color: bright,
    );
    _setToroidalScaledPixel(
      destination,
      originX: originX,
      originY: originY,
      logicalSize: logicalSize,
      scale: scale,
      x: x - 1,
      y: y,
      color: soft,
    );
    if (index % 4 == 0) {
      _setToroidalScaledPixel(
        destination,
        originX: originX,
        originY: originY,
        logicalSize: logicalSize,
        scale: scale,
        x: x + 1,
        y: y,
        color: soft,
      );
    }
  }
}

void _paintBoundaryCell(
  img.Image destination, {
  required int originX,
  required int originY,
  required int frame,
  required int frameCount,
  required List<bool> mask,
  required int cardinalMask,
  required _WaterStyle style,
}) {
  for (var y = 0; y < selbrumeBoundaryFrameSize; y += 1) {
    for (var x = 0; x < selbrumeBoundaryFrameSize; x += 1) {
      final inside = mask[y * selbrumeBoundaryFrameSize + x];
      final nearBoundary = _touchesOtherCoverage(
        mask,
        cardinalMask: cardinalMask,
        x: x,
        y: y,
        inside: inside,
      );
      if (inside) {
        final color = nearBoundary
            ? _insideBoundaryColor(
                x: x,
                y: y,
                frame: frame,
                frameCount: frameCount,
                style: style,
              )
            : _waterColor(
                x: x,
                y: y,
                period: selbrumeBoundaryFrameSize,
                frame: frame,
                frameCount: frameCount,
                style: style,
              );
        destination.setPixelRgba(
          originX + x,
          originY + y,
          color.red,
          color.green,
          color.blue,
          255,
        );
      } else if (nearBoundary) {
        final color = style == _WaterStyle.openSea
            ? const _Rgba(207, 241, 255, 150)
            : const _Rgba(111, 126, 105, 176);
        destination.setPixelRgba(
          originX + x,
          originY + y,
          color.red,
          color.green,
          color.blue,
          color.alpha,
        );
      } else {
        destination.setPixelRgba(originX + x, originY + y, 0, 0, 0, 0);
      }
    }
  }
}

List<bool> _buildBoundaryMask(int cardinalMask) {
  const size = selbrumeBoundaryFrameSize;
  const center = 15.5;
  const radius = 13.0;
  final values = List<bool>.filled(size * size, false);
  for (var y = 0; y < size; y += 1) {
    for (var x = 0; x < size; x += 1) {
      final dx = x - center;
      final dy = y - center;
      final inCenter = dx * dx + dy * dy <= radius * radius;
      final north = cardinalMask & 1 != 0 && y <= center && dx.abs() <= radius;
      final east = cardinalMask & 2 != 0 && x >= center && dy.abs() <= radius;
      final south = cardinalMask & 4 != 0 && y >= center && dx.abs() <= radius;
      final west = cardinalMask & 8 != 0 && x <= center && dy.abs() <= radius;
      values[y * size + x] = inCenter || north || east || south || west;
    }
  }
  return values;
}

bool _touchesOtherCoverage(
  List<bool> mask, {
  required int cardinalMask,
  required int x,
  required int y,
  required bool inside,
}) {
  for (var offsetY = -1; offsetY <= 1; offsetY += 1) {
    for (var offsetX = -1; offsetX <= 1; offsetX += 1) {
      if (offsetX == 0 && offsetY == 0) continue;
      final neighbor = _boundaryMaskAt(
        mask,
        cardinalMask: cardinalMask,
        x: x + offsetX,
        y: y + offsetY,
      );
      if (neighbor != inside) return true;
    }
  }
  return false;
}

bool _boundaryMaskAt(
  List<bool> mask, {
  required int cardinalMask,
  required int x,
  required int y,
}) {
  const size = selbrumeBoundaryFrameSize;
  const center = 15.5;
  const radius = 13.0;
  if (x < 0) {
    return cardinalMask & 8 != 0 && (y - center).abs() <= radius;
  }
  if (x >= size) {
    return cardinalMask & 2 != 0 && (y - center).abs() <= radius;
  }
  if (y < 0) {
    return cardinalMask & 1 != 0 && (x - center).abs() <= radius;
  }
  if (y >= size) {
    return cardinalMask & 4 != 0 && (x - center).abs() <= radius;
  }
  return mask[y * size + x];
}

_Rgba _insideBoundaryColor({
  required int x,
  required int y,
  required int frame,
  required int frameCount,
  required _WaterStyle style,
}) {
  final step = selbrumeBoundaryFrameSize ~/ frameCount;
  final pulse = _triangleWave(
    x * 3 - y * 5 + frame * step,
    selbrumeBoundaryFrameSize,
  );
  if (style == _WaterStyle.openSea) {
    return pulse > 145
        ? const _Rgba(239, 251, 255, 255)
        : const _Rgba(154, 224, 255, 255);
  }
  return pulse > 150
      ? const _Rgba(143, 148, 126, 255)
      : const _Rgba(92, 112, 101, 255);
}

_Rgba _waterColor({
  required int x,
  required int y,
  required int period,
  required int frame,
  required int frameCount,
  required _WaterStyle style,
}) {
  final frameStep = period ~/ frameCount;
  final broad = _periodicValueNoise(
    x + frame * frameStep,
    y,
    period: period,
    cellSize: period ~/ 4,
    salt: 17,
  );
  final swell = _periodicValueNoise(
    x - frame * frameStep,
    y + frame * frameStep,
    period: period,
    cellSize: period ~/ 2,
    salt: 53,
  );
  final value = (broad * 7 + swell * 3) ~/ 10;
  final palette = style == _WaterStyle.openSea ? _seaPalette : _marshPalette;
  final paletteIndex = (value * palette.length ~/ 256).clamp(
    0,
    palette.length - 1,
  );
  return palette[paletteIndex];
}

int _periodicValueNoise(
  int x,
  int y, {
  required int period,
  required int cellSize,
  required int salt,
}) {
  final wrappedX = _mod(x, period);
  final wrappedY = _mod(y, period);
  final gridSize = period ~/ cellSize;
  final gridX = wrappedX ~/ cellSize;
  final gridY = wrappedY ~/ cellSize;
  final nextX = (gridX + 1) % gridSize;
  final nextY = (gridY + 1) % gridSize;
  final weightX = _smoothWeight(wrappedX % cellSize, cellSize);
  final weightY = _smoothWeight(wrappedY % cellSize, cellSize);
  final top = _lerp1024(
    _controlValue(gridX, gridY, salt),
    _controlValue(nextX, gridY, salt),
    weightX,
  );
  final bottom = _lerp1024(
    _controlValue(gridX, nextY, salt),
    _controlValue(nextX, nextY, salt),
    weightX,
  );
  return _lerp1024(top, bottom, weightY);
}

int _controlValue(int x, int y, int salt) {
  var value = (x * 0x1f123bb5) ^ (y * 0x5f356495) ^ (salt * 0x9e3779b9);
  value = (value ^ (value >> 16)) * 0x45d9f3b;
  value = (value ^ (value >> 16)) * 0x45d9f3b;
  value ^= value >> 16;
  return value & 0xff;
}

int _smoothWeight(int offset, int cellSize) {
  final numerator = offset * offset * (3 * cellSize - 2 * offset) * 1024;
  final denominator = cellSize * cellSize * cellSize;
  return numerator ~/ denominator;
}

int _lerp1024(int a, int b, int weight) {
  return (a * (1024 - weight) + b * weight) ~/ 1024;
}

int _triangleWave(int value, int period) {
  final wrapped = _mod(value, period);
  final half = period ~/ 2;
  if (wrapped <= half) return wrapped * 255 ~/ half;
  return (period - wrapped) * 255 ~/ half;
}

int _mod(int value, int modulus) {
  final remainder = value % modulus;
  return remainder < 0 ? remainder + modulus : remainder;
}

void _setScaledPixel(
  img.Image image, {
  required int originX,
  required int originY,
  required int x,
  required int y,
  required int scale,
  required _Rgba color,
  required int alpha,
}) {
  for (var offsetY = 0; offsetY < scale; offsetY += 1) {
    for (var offsetX = 0; offsetX < scale; offsetX += 1) {
      image.setPixelRgba(
        originX + x * scale + offsetX,
        originY + y * scale + offsetY,
        color.red,
        color.green,
        color.blue,
        alpha,
      );
    }
  }
}

void _setToroidalScaledPixel(
  img.Image image, {
  required int originX,
  required int originY,
  required int logicalSize,
  required int scale,
  required int x,
  required int y,
  required _Rgba color,
}) {
  _setScaledPixel(
    image,
    originX: originX,
    originY: originY,
    x: _mod(x, logicalSize),
    y: _mod(y, logicalSize),
    scale: scale,
    color: color,
    alpha: color.alpha,
  );
}

String? _parseOutputDirectory(List<String> args) {
  if (args.length != 2 || args.first != '--output-dir') return null;
  final value = args[1].trim();
  return value.isEmpty ? null : value;
}

Future<bool> _writeIfChanged(File file, Uint8List bytes) async {
  if (await file.exists()) {
    final current = await file.readAsBytes();
    if (_sameBytes(current, bytes)) return false;
  }
  await file.writeAsBytes(bytes, flush: true);
  return true;
}

bool _sameBytes(List<int> a, List<int> b) {
  if (a.length != b.length) return false;
  for (var index = 0; index < a.length; index += 1) {
    if (a[index] != b[index]) return false;
  }
  return true;
}

const _seaPalette = <_Rgba>[
  _Rgba(5, 55, 143, 255),
  _Rgba(6, 70, 169, 255),
  _Rgba(8, 88, 196, 255),
  _Rgba(13, 108, 218, 255),
  _Rgba(22, 132, 235, 255),
  _Rgba(45, 161, 246, 255),
];

const _marshPalette = <_Rgba>[
  _Rgba(47, 91, 107, 255),
  _Rgba(54, 105, 119, 255),
  _Rgba(64, 119, 131, 255),
  _Rgba(75, 133, 142, 255),
  _Rgba(90, 147, 153, 255),
  _Rgba(109, 162, 163, 255),
];

enum _WaterStyle { openSea, marsh }

final class SelbrumeWaterBoundaryVariant {
  const SelbrumeWaterBoundaryVariant({
    required this.mask,
    required this.name,
  });

  final int mask;
  final String name;
}

final class SelbrumeWaterV2Artifacts {
  SelbrumeWaterV2Artifacts({
    required this.openSea,
    required this.coast,
    required this.marsh,
  }) : files = Map<String, Uint8List>.unmodifiable(
          <String, Uint8List>{
            selbrumeOpenSeaV2FileName: openSea,
            selbrumeCoastV2FileName: coast,
            selbrumeMarshWaterV2FileName: marsh,
          },
        );

  final Uint8List openSea;
  final Uint8List coast;
  final Uint8List marsh;
  final Map<String, Uint8List> files;
}

final class _Rgba {
  const _Rgba(this.red, this.green, this.blue, this.alpha);

  final int red;
  final int green;
  final int blue;
  final int alpha;
}
