import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart' as crypto;
import 'package:image/image.dart' as image;

Uint8List originalIndexedAutotilePng({required bool hasTransparency}) =>
    base64Decode(hasTransparency
        ? 'iVBORw0KGgoAAAANSUhEUgAAAKAAAAAgBAMAAABnUW7GAAAAMFBMVEUR7x8e5CYr2S04zjRFwztSuEJfrUlsolB5l1eGjF6TgWWgdmyta3O6YHrHVYHUSoj6cFotAAAAEHRSTlMASf8ASf8ASf8ASf8ASf8AcP/B/AAAAJtJREFUeJztlDENgFAQQ4sFLGABC1jAwreABSxgAQtYwAIWQAIJCctbmsutN3V43V5adcPU1v28/+zHedmO6/kTuAPugQe5AvAIPAHPcgXgBrwAr3IF4A14Bz7kCsAn8EUHcoWoJEUtOkmKWnSSFLXoJClq0UlS1KKTpOzU6EDZqdGBslOjA2WnRgfKTo0OVH9Yf1h/WH9Yf/jlC9S7+z0G6vscAAAAAElFTkSuQmCC'
        : 'iVBORw0KGgoAAAANSUhEUgAAAKAAAAAgBAMAAABnUW7GAAAAMFBMVEUR7x8e5CYr2S04zjRFwztSuEJfrUlsolB5l1eGjF6TgWWgdmyta3O6YHrHVYHUSoj6cFotAAAAm0lEQVR4nO2UMQ2AUBBDiwUsYAELWMDCt4AFLGABC1jAAhZAAgkJy1uay603dXjdXlp1w9TW/bz/7Md52Y7r+RO4A+6BB7kC8Ag8Ac9yBeAGvACvcgXgDXgHPuQKwCfwRQdyhagkRS06SYpadJIUtegkKWrRSVLUopOk7NToQNmp0YGyU6MDZadGB8pOjQ5Uf1h/WH9Yf1h/+OUL1Lv7PQbq+xwAAAAASUVORK5CYII=');

enum OriginalAutotileFormat { standard, extended, simple }

final class OriginalAutotileSourceRect {
  const OriginalAutotileSourceRect(this.x, this.y, this.width, this.height);

  final int x;
  final int y;
  final int width;
  final int height;
}

final class OriginalAutotileOracle {
  OriginalAutotileOracle._(
    this.sourceQuarters,
    this.sourceRects,
    this.expectedHashes,
    this.frameCount,
    this.archiveSha256,
    this.patternScriptSha256,
    this.geometryScriptSha256,
  );

  factory OriginalAutotileOracle.load({
    String path = 'test/support/autotile_quadrant_oracle.json',
  }) {
    final data =
        jsonDecode(File(path).readAsStringSync()) as Map<String, dynamic>;
    if (data['schemaVersion'] != 1 ||
        data['variantCount'] != 48 ||
        data['frameCount'] != 3 ||
        data['tileSize'] != 32 ||
        data['quarterSize'] != 16) {
      throw StateError('Unsupported original autotile oracle');
    }
    final variants = data['variants'] as List<dynamic>;
    if (variants.length != 48) {
      throw StateError('Oracle must cover all 48 variants');
    }
    final quarters = <List<int>>[];
    final rectangles =
        <OriginalAutotileFormat, List<List<OriginalAutotileSourceRect>>>{
      for (final format in OriginalAutotileFormat.values) format: [],
    };
    for (var index = 0; index < variants.length; index++) {
      final variant = variants[index] as Map<String, dynamic>;
      if (variant['variant'] != index) {
        throw StateError(
            'Oracle variant positions must be explicit and ordered');
      }
      final values =
          (variant['standardSourceQuarters'] as List<dynamic>).cast<int>();
      if (values.length != 4 ||
          values.any((value) => value < 1 || value > 48)) {
        throw StateError('Oracle source quarter facts are invalid');
      }
      quarters.add(List<int>.unmodifiable(values));
      final byFormat = variant['sourceRectsByFormat'] as Map<String, dynamic>;
      for (final format in OriginalAutotileFormat.values) {
        final rects = byFormat[format.name] as List<dynamic>;
        if (rects.length != 4) {
          throw StateError('Oracle must provide four source rectangles');
        }
        rectangles[format]!.add(List<OriginalAutotileSourceRect>.unmodifiable(
          rects.map((value) {
            final rect = (value as List<dynamic>).cast<int>();
            if (rect.length != 4 ||
                rect[0] < 0 ||
                rect[1] < 0 ||
                rect[2] != 16 ||
                rect[3] != 16) {
              throw StateError('Oracle source rectangle is invalid');
            }
            return OriginalAutotileSourceRect(
                rect[0], rect[1], rect[2], rect[3]);
          }),
        ));
      }
    }
    final hashData = data['expectedRgbaSha256ByFormat'] as Map<String, dynamic>;
    final hashes = <OriginalAutotileFormat, List<List<String>>>{};
    for (final format in OriginalAutotileFormat.values) {
      final frames = hashData[format.name] as List<dynamic>;
      if (frames.length != 3) {
        throw StateError('Oracle must cover three independent frames');
      }
      hashes[format] = List<List<String>>.unmodifiable(frames.map((frame) {
        final values = (frame as List<dynamic>).cast<String>();
        if (values.length != 48 ||
            values.any((value) => !RegExp(r'^[a-f0-9]{64}$').hasMatch(value))) {
          throw StateError('Oracle expected hashes are invalid');
        }
        return List<String>.unmodifiable(values);
      }));
    }
    final provenance = data['provenance'] as Map<String, dynamic>;
    return OriginalAutotileOracle._(
      List<List<int>>.unmodifiable(quarters),
      Map<OriginalAutotileFormat,
          List<List<OriginalAutotileSourceRect>>>.unmodifiable(
        rectangles.map((key, value) => MapEntry(
            key, List<List<OriginalAutotileSourceRect>>.unmodifiable(value))),
      ),
      Map<OriginalAutotileFormat, List<List<String>>>.unmodifiable(hashes),
      data['frameCount'] as int,
      provenance['archiveSha256'] as String,
      (provenance['patternReference'] as Map<String, dynamic>)['scriptSha256']
          as String,
      (provenance['geometryReference'] as Map<String, dynamic>)['scriptSha256']
          as String,
    );
  }

  final List<List<int>> sourceQuarters;
  final Map<OriginalAutotileFormat, List<List<OriginalAutotileSourceRect>>>
      sourceRects;
  final Map<OriginalAutotileFormat, List<List<String>>> expectedHashes;
  final int frameCount;
  final String archiveSha256;
  final String patternScriptSha256;
  final String geometryScriptSha256;
}

final class OriginalAutotileFixture {
  factory OriginalAutotileFixture.standard({
    int frameCount = 3,
    OriginalAutotileOracle? oracle,
  }) =>
      OriginalAutotileFixture._build(
          OriginalAutotileFormat.standard, frameCount, oracle);

  factory OriginalAutotileFixture.extended({
    int frameCount = 3,
    OriginalAutotileOracle? oracle,
  }) =>
      OriginalAutotileFixture._build(
          OriginalAutotileFormat.extended, frameCount, oracle);

  factory OriginalAutotileFixture.simple({
    int frameCount = 3,
    OriginalAutotileOracle? oracle,
  }) =>
      OriginalAutotileFixture._build(
          OriginalAutotileFormat.simple, frameCount, oracle);

  factory OriginalAutotileFixture._build(
    OriginalAutotileFormat format,
    int frameCount,
    OriginalAutotileOracle? inputOracle,
  ) {
    final oracle = inputOracle ?? OriginalAutotileOracle.load();
    if (frameCount < 1 || frameCount > oracle.frameCount) {
      throw ArgumentError.value(frameCount, 'frameCount', 'Expected 1 to 3');
    }
    final frameWidth = format == OriginalAutotileFormat.simple ? 32 : 96;
    final height = switch (format) {
      OriginalAutotileFormat.standard => 128,
      OriginalAutotileFormat.extended => 192,
      OriginalAutotileFormat.simple => 32,
    };
    final width = frameWidth * frameCount;
    final raster = image.Image(width: width, height: height, numChannels: 4);
    final rgba = Uint8List(width * height * 4);
    for (var y = 0; y < height; y++) {
      for (var x = 0; x < width; x++) {
        final frame = x ~/ frameWidth;
        final sourceX = x % frameWidth;
        final quarter = (y ~/ 16) * (frameWidth ~/ 16) + sourceX ~/ 16 + 1;
        final pixel = _originalPixel(frame, quarter, sourceX % 16, y % 16);
        raster.setPixelRgba(x, y, pixel[0], pixel[1], pixel[2], pixel[3]);
        rgba.setRange((y * width + x) * 4, (y * width + x + 1) * 4, pixel);
      }
    }
    return OriginalAutotileFixture._(
      format,
      oracle,
      frameCount,
      width,
      height,
      Uint8List.fromList(image.encodePng(raster)).asUnmodifiableView(),
      rgba.asUnmodifiableView(),
    );
  }

  const OriginalAutotileFixture._(
    this.format,
    this.oracle,
    this.frameCount,
    this.width,
    this.height,
    this.pngBytes,
    this.sourceRgba,
  );

  final OriginalAutotileFormat format;
  final OriginalAutotileOracle oracle;
  final int frameCount;
  final int width;
  final int height;
  final Uint8List pngBytes;
  final Uint8List sourceRgba;

  int get frameWidth => width ~/ frameCount;
  String get pngSha256 => crypto.sha256.convert(pngBytes).toString();

  Uint8List expectedRgba({required int frame, required int variant}) {
    RangeError.checkValueInInterval(frame, 0, frameCount - 1, 'frame');
    RangeError.checkValidIndex(variant, oracle.sourceQuarters, 'variant');
    final rects = oracle.sourceRects[format]![variant];
    final result = Uint8List(32 * 32 * 4);
    for (var y = 0; y < 32; y++) {
      for (var x = 0; x < 32; x++) {
        final rect = rects[(y ~/ 16) * 2 + x ~/ 16];
        final sourceX = rect.x + x % 16;
        final sourceY = rect.y + y % 16;
        final quarter =
            (sourceY ~/ 16) * (frameWidth ~/ 16) + sourceX ~/ 16 + 1;
        result.setRange(
          (y * 32 + x) * 4,
          (y * 32 + x + 1) * 4,
          _originalPixel(frame, quarter, sourceX % 16, sourceY % 16),
        );
      }
    }
    return result.asUnmodifiableView();
  }

  String expectedRgbaHash({required int frame, required int variant}) {
    RangeError.checkValueInInterval(frame, 0, frameCount - 1, 'frame');
    RangeError.checkValidIndex(variant, oracle.sourceQuarters, 'variant');
    return oracle.expectedHashes[format]![frame][variant];
  }

  static List<int> _originalPixel(int frame, int quarter, int x, int y) {
    if (y == 0 && x == 3) {
      return const [255, 0, 255, 255];
    }
    return [
      (17 + frame * 61 + quarter * 3 + x * 7 + y * 11) % 256,
      (31 + frame * 43 + quarter * 5 + x * 13 + y * 3) % 256,
      (47 + frame * 29 + quarter * 7 + x * 5 + y * 17) % 256,
      y == 0 && x == 0
          ? 0
          : y == 0 && x == 1
              ? 127
              : 255,
    ];
  }
}
