import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/border_studio/application/border_asset_alpha_analyzer.dart';

void main() {
  group('BorderAssetAlphaAnalyzer', () {
    const analyzer = BorderAssetAlphaAnalyzer();

    test('keeps normalized RGBA and treats alpha greater than zero as opaque',
        () {
      final bytes = _png(
        width: 2,
        height: 1,
        pixels: const <_Rgba>[
          _Rgba(10, 20, 30, 1),
          _Rgba(40, 50, 60, 0),
        ],
      );

      final result = analyzer.analyze(
        BorderAssetAlphaAnalysisInput(
          frames: <BorderAssetAlphaFrameInput>[
            BorderAssetAlphaFrameInput(encodedImageBytes: bytes),
          ],
        ),
      );

      expect(result.pixelSize, const GridSize(width: 2, height: 1));
      expect(
        result.opaqueUnionBounds,
        BorderPixelRect(x: 0, y: 0, width: 1, height: 1),
      );
      expect(result.structuralOccupancyMaskRle, 'border-rle-v1:2:1:1,1');
      expect(result.isFullyOpaque, isFalse);
      expect(result.isFullyTransparent, isFalse);
      expect(result.frames.single.durationMs, 100);
      expect(
        result.frames.single.rgbaBytes,
        <int>[10, 20, 30, 1, 40, 50, 60, 0],
      );
    });

    test('reports a fully opaque image', () {
      final result = analyzer.analyze(
        BorderAssetAlphaAnalysisInput(
          frames: <BorderAssetAlphaFrameInput>[
            BorderAssetAlphaFrameInput(
              encodedImageBytes: _solidPng(
                width: 2,
                height: 2,
                alpha: 255,
              ),
              durationMs: 75,
            ),
          ],
        ),
      );

      expect(result.isFullyOpaque, isTrue);
      expect(result.isFullyTransparent, isFalse);
      expect(
        result.opaqueUnionBounds,
        BorderPixelRect(x: 0, y: 0, width: 2, height: 2),
      );
      expect(result.structuralOccupancyMaskRle, 'border-rle-v1:4:1:4');
      expect(result.frames.single.durationMs, 75);
    });

    test('accepts a fully transparent image with no opaque bounds', () {
      final result = analyzer.analyze(
        BorderAssetAlphaAnalysisInput(
          frames: <BorderAssetAlphaFrameInput>[
            BorderAssetAlphaFrameInput(
              encodedImageBytes: _solidPng(
                width: 2,
                height: 2,
                alpha: 0,
              ),
            ),
          ],
        ),
      );

      expect(result.isFullyOpaque, isFalse);
      expect(result.isFullyTransparent, isTrue);
      expect(result.opaqueUnionBounds, isNull);
      expect(result.frames.single.opaqueBounds, isNull);
      expect(result.structuralOccupancyMaskRle, 'border-rle-v1:4:0:4');
    });

    test('uses opaque union bounds and frame intersection for animation', () {
      final first = _png(
        width: 3,
        height: 1,
        pixels: const <_Rgba>[
          _Rgba(1, 2, 3, 255),
          _Rgba(4, 5, 6, 255),
          _Rgba(7, 8, 9, 0),
        ],
      );
      final second = _png(
        width: 3,
        height: 1,
        pixels: const <_Rgba>[
          _Rgba(1, 2, 3, 0),
          _Rgba(4, 5, 6, 255),
          _Rgba(7, 8, 9, 255),
        ],
      );

      final result = analyzer.analyze(
        BorderAssetAlphaAnalysisInput(
          frames: <BorderAssetAlphaFrameInput>[
            BorderAssetAlphaFrameInput(encodedImageBytes: first),
            BorderAssetAlphaFrameInput(
              encodedImageBytes: second,
              durationMs: 60,
            ),
          ],
        ),
      );

      expect(result.frames.map((frame) => frame.durationMs), <int>[100, 60]);
      expect(
        result.frames.map((frame) => frame.opaqueBounds),
        <BorderPixelRect>[
          BorderPixelRect(x: 0, y: 0, width: 2, height: 1),
          BorderPixelRect(x: 1, y: 0, width: 2, height: 1),
        ],
      );
      expect(
        result.opaqueUnionBounds,
        BorderPixelRect(x: 0, y: 0, width: 3, height: 1),
      );
      expect(result.structuralOccupancyMaskRle, 'border-rle-v1:3:0:1,1,1');
    });

    test('applies an RGB transparency key before alpha analysis', () {
      final result = analyzer.analyze(
        BorderAssetAlphaAnalysisInput(
          frames: <BorderAssetAlphaFrameInput>[
            BorderAssetAlphaFrameInput(
              encodedImageBytes: _png(
                width: 2,
                height: 1,
                pixels: const <_Rgba>[
                  _Rgba(255, 0, 255, 255),
                  _Rgba(1, 2, 3, 255),
                ],
              ),
              transparentColorArgb: 0xffff00ff,
            ),
          ],
        ),
      );

      expect(result.structuralOccupancyMaskRle, 'border-rle-v1:2:0:1,1');
      expect(
        result.frames.single.rgbaBytes,
        <int>[255, 0, 255, 0, 1, 2, 3, 255],
      );
    });

    test('crops a typed source rectangle before analysis', () {
      final result = analyzer.analyze(
        BorderAssetAlphaAnalysisInput(
          frames: <BorderAssetAlphaFrameInput>[
            BorderAssetAlphaFrameInput(
              encodedImageBytes: _png(
                width: 3,
                height: 2,
                pixels: const <_Rgba>[
                  _Rgba(0, 0, 0, 0),
                  _Rgba(1, 2, 3, 255),
                  _Rgba(0, 0, 0, 0),
                  _Rgba(0, 0, 0, 0),
                  _Rgba(4, 5, 6, 255),
                  _Rgba(0, 0, 0, 0),
                ],
              ),
              sourceRectPx: BorderPixelRect(
                x: 1,
                y: 0,
                width: 1,
                height: 2,
              ),
            ),
          ],
        ),
      );

      expect(result.pixelSize, const GridSize(width: 1, height: 2));
      expect(result.structuralOccupancyMaskRle, 'border-rle-v1:2:1:2');
      expect(
        result.frames.single.rgbaBytes,
        <int>[1, 2, 3, 255, 4, 5, 6, 255],
      );
    });

    test('rejects empty or undecodable input with typed user-facing errors',
        () {
      expect(
        () => analyzer.analyze(
          BorderAssetAlphaAnalysisInput(frames: const []),
        ),
        _throwsAlphaError(BorderAssetAlphaAnalysisErrorCode.noFrames),
      );
      expect(
        () => analyzer.analyze(
          BorderAssetAlphaAnalysisInput(
            frames: <BorderAssetAlphaFrameInput>[
              BorderAssetAlphaFrameInput(
                encodedImageBytes: Uint8List.fromList(<int>[1, 2, 3]),
              ),
            ],
          ),
        ),
        _throwsAlphaError(
          BorderAssetAlphaAnalysisErrorCode.invalidEncodedImage,
          frameIndex: 0,
        ),
      );
    });

    test('rejects a source above the 64M pixel ceiling before decoding', () {
      final tinyValidPng = _solidPng(width: 1, height: 1, alpha: 255);

      expect(
        () => analyzer.analyze(
          BorderAssetAlphaAnalysisInput(
            frames: <BorderAssetAlphaFrameInput>[
              BorderAssetAlphaFrameInput(
                encodedImageBytes: tinyValidPng,
                sourceRectPx: BorderPixelRect(
                  x: 0,
                  y: 0,
                  width: 8193,
                  height: 8193,
                ),
              ),
            ],
          ),
        ),
        _throwsAlphaError(
          BorderAssetAlphaAnalysisErrorCode.pixelLimitExceeded,
          frameIndex: 0,
        ),
      );
    });

    test('rejects oversized dimensions from encoded image metadata', () {
      expect(
        () => analyzer.analyze(
          BorderAssetAlphaAnalysisInput(
            frames: <BorderAssetAlphaFrameInput>[
              BorderAssetAlphaFrameInput(
                encodedImageBytes: _pngMetadataOnly(
                  width: 8193,
                  height: 8193,
                ),
              ),
            ],
          ),
        ),
        _throwsAlphaError(
          BorderAssetAlphaAnalysisErrorCode.pixelLimitExceeded,
          frameIndex: 0,
        ),
      );
    });

    test('rejects heterogeneous animation frame dimensions', () {
      expect(
        () => analyzer.analyze(
          BorderAssetAlphaAnalysisInput(
            frames: <BorderAssetAlphaFrameInput>[
              BorderAssetAlphaFrameInput(
                encodedImageBytes: _solidPng(
                  width: 2,
                  height: 1,
                  alpha: 255,
                ),
              ),
              BorderAssetAlphaFrameInput(
                encodedImageBytes: _solidPng(
                  width: 1,
                  height: 2,
                  alpha: 255,
                ),
              ),
            ],
          ),
        ),
        _throwsAlphaError(
          BorderAssetAlphaAnalysisErrorCode.heterogeneousFrameDimensions,
          frameIndex: 1,
        ),
      );
    });

    for (final invalidDuration in <int>[0, -1]) {
      test('rejects explicit frame duration $invalidDuration ms', () {
        expect(
          () => analyzer.analyze(
            BorderAssetAlphaAnalysisInput(
              frames: <BorderAssetAlphaFrameInput>[
                BorderAssetAlphaFrameInput(
                  encodedImageBytes: _solidPng(
                    width: 1,
                    height: 1,
                    alpha: 255,
                  ),
                  durationMs: invalidDuration,
                ),
              ],
            ),
          ),
          _throwsAlphaError(
            BorderAssetAlphaAnalysisErrorCode.invalidFrameDuration,
            frameIndex: 0,
          ),
        );
      });
    }

    test('rejects a source rectangle outside the decoded image', () {
      expect(
        () => analyzer.analyze(
          BorderAssetAlphaAnalysisInput(
            frames: <BorderAssetAlphaFrameInput>[
              BorderAssetAlphaFrameInput(
                encodedImageBytes: _solidPng(
                  width: 2,
                  height: 2,
                  alpha: 255,
                ),
                sourceRectPx: BorderPixelRect(
                  x: 1,
                  y: 1,
                  width: 2,
                  height: 2,
                ),
              ),
            ],
          ),
        ),
        _throwsAlphaError(
          BorderAssetAlphaAnalysisErrorCode.sourceRectOutOfBounds,
          frameIndex: 0,
        ),
      );
    });
  });
}

Matcher _throwsAlphaError(
  BorderAssetAlphaAnalysisErrorCode code, {
  int? frameIndex,
}) =>
    throwsA(
      isA<BorderAssetAlphaAnalysisException>()
          .having((error) => error.code, 'code', code)
          .having((error) => error.frameIndex, 'frameIndex', frameIndex)
          .having(
            (error) => error.userMessage.trim(),
            'non-empty userMessage',
            isNotEmpty,
          ),
    );

Uint8List _solidPng({
  required int width,
  required int height,
  required int alpha,
}) =>
    _png(
      width: width,
      height: height,
      pixels: List<_Rgba>.filled(
        width * height,
        _Rgba(12, 34, 56, alpha),
      ),
    );

Uint8List _png({
  required int width,
  required int height,
  required List<_Rgba> pixels,
}) {
  assert(pixels.length == width * height);
  final image = img.Image(width: width, height: height, numChannels: 4);
  for (var index = 0; index < pixels.length; index += 1) {
    final pixel = pixels[index];
    image.setPixelRgba(
      index % width,
      index ~/ width,
      pixel.r,
      pixel.g,
      pixel.b,
      pixel.a,
    );
  }
  return Uint8List.fromList(img.encodePng(image));
}

Uint8List _pngMetadataOnly({required int width, required int height}) {
  final bytes = BytesBuilder(copy: false)
    ..add(const <int>[137, 80, 78, 71, 13, 10, 26, 10]);
  final header = ByteData(13)
    ..setUint32(0, width)
    ..setUint32(4, height)
    ..setUint8(8, 8)
    ..setUint8(9, 6)
    ..setUint8(10, 0)
    ..setUint8(11, 0)
    ..setUint8(12, 0);
  _addPngChunk(bytes, 'IHDR', header.buffer.asUint8List());
  _addPngChunk(bytes, 'IEND', Uint8List(0));
  return bytes.takeBytes();
}

void _addPngChunk(BytesBuilder output, String type, Uint8List data) {
  final typeBytes = Uint8List.fromList(type.codeUnits);
  final length = ByteData(4)..setUint32(0, data.length);
  final crcInput = Uint8List(typeBytes.length + data.length)
    ..setRange(0, typeBytes.length, typeBytes)
    ..setRange(typeBytes.length, typeBytes.length + data.length, data);
  final crc = ByteData(4)..setUint32(0, _crc32(crcInput));
  output
    ..add(length.buffer.asUint8List())
    ..add(typeBytes)
    ..add(data)
    ..add(crc.buffer.asUint8List());
}

int _crc32(Uint8List bytes) {
  var crc = 0xffffffff;
  for (final byte in bytes) {
    crc ^= byte;
    for (var bit = 0; bit < 8; bit += 1) {
      crc = (crc & 1) == 1 ? (crc >> 1) ^ 0xedb88320 : crc >> 1;
    }
  }
  return (crc ^ 0xffffffff) & 0xffffffff;
}

final class _Rgba {
  const _Rgba(this.r, this.g, this.b, this.a);

  final int r;
  final int g;
  final int b;
  final int a;
}
