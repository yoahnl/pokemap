import 'dart:typed_data';

import 'package:image/image.dart' as img;
import 'package:map_core/map_core.dart';

/// Effective duration used when an authored frame has no explicit duration.
const int borderAssetDefaultFrameDurationMs = 100;

/// Maximum number of logical RGBA pixels retained by one analysis.
const int borderAssetMaxDecodedPixels = borderRleMaxDecodedCells;

/// Stable error vocabulary suitable for localized Border Studio feedback.
enum BorderAssetAlphaAnalysisErrorCode {
  noFrames,
  invalidEncodedImage,
  decodedFrameOutOfRange,
  pixelLimitExceeded,
  sourceRectOutOfBounds,
  heterogeneousFrameDimensions,
  invalidFrameDuration,
  invalidTransparentColor,
}

/// A typed, user-displayable alpha-analysis failure.
final class BorderAssetAlphaAnalysisException implements Exception {
  const BorderAssetAlphaAnalysisException({
    required this.code,
    required this.userMessage,
    this.frameIndex,
  });

  final BorderAssetAlphaAnalysisErrorCode code;
  final String userMessage;
  final int? frameIndex;

  @override
  String toString() {
    final location = frameIndex == null ? '' : ' (frame $frameIndex)';
    return 'BorderAssetAlphaAnalysisException.${code.name}$location: '
        '$userMessage';
  }
}

/// One logical visual frame to decode from an encoded image or atlas.
///
/// [durationMs] deliberately remains nullable here: `null` means an absent
/// authoring value and is normalized to [borderAssetDefaultFrameDurationMs].
/// An explicitly supplied value must be strictly positive.
final class BorderAssetAlphaFrameInput {
  BorderAssetAlphaFrameInput({
    required Uint8List encodedImageBytes,
    this.sourceRectPx,
    this.durationMs,
    this.transparentColorArgb,
    this.decodedFrameIndex = 0,
  }) : _encodedImageBytes = Uint8List.fromList(encodedImageBytes);

  final Uint8List _encodedImageBytes;
  final BorderPixelRect? sourceRectPx;
  final int? durationMs;
  final int? transparentColorArgb;

  /// Frame inside an encoded multi-frame image. Atlas sources normally use 0.
  final int decodedFrameIndex;

  Uint8List get encodedImageBytes => Uint8List.fromList(_encodedImageBytes);
}

/// Ordered logical frames forming one primitive asset.
final class BorderAssetAlphaAnalysisInput {
  BorderAssetAlphaAnalysisInput({
    required List<BorderAssetAlphaFrameInput> frames,
  }) : _frames = List<BorderAssetAlphaFrameInput>.unmodifiable(frames);

  final List<BorderAssetAlphaFrameInput> _frames;

  List<BorderAssetAlphaFrameInput> get frames => _frames;
}

/// Decoded and alpha-normalized pixels for one logical frame.
final class BorderAnalyzedAlphaFrame {
  BorderAnalyzedAlphaFrame._({
    required Uint8List rgbaBytes,
    required this.durationMs,
    required this.opaqueBounds,
    required this.transparentColorArgb,
  }) : _rgbaBytes = rgbaBytes;

  final Uint8List _rgbaBytes;
  final int durationMs;
  final BorderPixelRect? opaqueBounds;
  final int? transparentColorArgb;

  /// Defensive copy of row-major RGBA bytes.
  Uint8List get rgbaBytes => Uint8List.fromList(_rgbaBytes);
}

/// Aggregate alpha facts needed by snapshot import and primitive metrics.
final class BorderAssetAlphaAnalysis {
  BorderAssetAlphaAnalysis._({
    required this.pixelSize,
    required this.opaqueUnionBounds,
    required this.structuralOccupancyMaskRle,
    required List<BorderAnalyzedAlphaFrame> frames,
    required this.isFullyOpaque,
  }) : _frames = List<BorderAnalyzedAlphaFrame>.unmodifiable(frames);

  final GridSize pixelSize;

  /// Union of opaque pixels across all frames, or `null` when all are empty.
  final BorderPixelRect? opaqueUnionBounds;

  /// Canonical mask of pixels opaque in every frame (`alpha > 0`).
  final String structuralOccupancyMaskRle;

  final List<BorderAnalyzedAlphaFrame> _frames;
  final bool isFullyOpaque;

  List<BorderAnalyzedAlphaFrame> get frames => _frames;

  bool get isFullyTransparent => opaqueUnionBounds == null;
}

/// Pure, filesystem-free alpha analyzer for Border Studio source frames.
final class BorderAssetAlphaAnalyzer {
  const BorderAssetAlphaAnalyzer();

  BorderAssetAlphaAnalysis analyze(BorderAssetAlphaAnalysisInput input) {
    if (input.frames.isEmpty) {
      throw const BorderAssetAlphaAnalysisException(
        code: BorderAssetAlphaAnalysisErrorCode.noFrames,
        userMessage: 'Ajoutez au moins une image à analyser.',
      );
    }

    final prepared = <_PreparedFrame>[];
    var retainedPixelCount = 0;
    int? expectedWidth;
    int? expectedHeight;

    for (var frameIndex = 0;
        frameIndex < input.frames.length;
        frameIndex += 1) {
      final frame = input.frames[frameIndex];
      final durationMs = _effectiveDuration(frame, frameIndex);
      _validateTransparentColor(frame, frameIndex);

      final requestedRect = frame.sourceRectPx;
      if (requestedRect != null) {
        _requireSupportedDimensions(
          requestedRect.width,
          requestedRect.height,
          frameIndex,
        );
      }

      final decoder = _startDecoder(frame, frameIndex);
      final info = decoder.info;
      _requireSupportedDimensions(info.width, info.height, frameIndex);

      final decodedFrameIndex = frame.decodedFrameIndex;
      if (decodedFrameIndex < 0 || decodedFrameIndex >= info.numFrames) {
        throw BorderAssetAlphaAnalysisException(
          code: BorderAssetAlphaAnalysisErrorCode.decodedFrameOutOfRange,
          frameIndex: frameIndex,
          userMessage: 'La frame demandée n’existe pas dans cette image.',
        );
      }

      final sourceRect = requestedRect ??
          BorderPixelRect(
            x: 0,
            y: 0,
            width: info.width,
            height: info.height,
          );
      if (!_fits(sourceRect, info.width, info.height)) {
        throw BorderAssetAlphaAnalysisException(
          code: BorderAssetAlphaAnalysisErrorCode.sourceRectOutOfBounds,
          frameIndex: frameIndex,
          userMessage: 'La zone choisie dépasse les limites de l’image.',
        );
      }

      final width = sourceRect.width;
      final height = sourceRect.height;
      if (expectedWidth == null) {
        expectedWidth = width;
        expectedHeight = height;
      } else if (width != expectedWidth || height != expectedHeight) {
        throw BorderAssetAlphaAnalysisException(
          code: BorderAssetAlphaAnalysisErrorCode.heterogeneousFrameDimensions,
          frameIndex: frameIndex,
          userMessage:
              'Toutes les frames d’une animation doivent avoir la même taille.',
        );
      }

      final logicalPixels = width * height;
      if (retainedPixelCount > borderAssetMaxDecodedPixels - logicalPixels) {
        throw BorderAssetAlphaAnalysisException(
          code: BorderAssetAlphaAnalysisErrorCode.pixelLimitExceeded,
          frameIndex: frameIndex,
          userMessage:
              'L’animation dépasse la limite de 64 millions de pixels.',
        );
      }
      retainedPixelCount += logicalPixels;
      prepared.add(
        _PreparedFrame(
          input: frame,
          decoder: decoder.decoder,
          sourceRect: sourceRect,
          durationMs: durationMs,
          frameIndex: frameIndex,
        ),
      );
    }

    final width = expectedWidth!;
    final height = expectedHeight!;
    final cellCount = width * height;
    final structuralMask = Uint8List(cellCount);
    final analyzedFrames = <BorderAnalyzedAlphaFrame>[];
    _OpaqueBoundsAccumulator? unionBounds;

    for (final preparedFrame in prepared) {
      final decoded = _decodePreparedFrame(preparedFrame);
      if (!_fits(
        preparedFrame.sourceRect,
        decoded.width,
        decoded.height,
      )) {
        throw BorderAssetAlphaAnalysisException(
          code: BorderAssetAlphaAnalysisErrorCode.sourceRectOutOfBounds,
          frameIndex: preparedFrame.frameIndex,
          userMessage: 'La zone choisie dépasse les limites de l’image.',
        );
      }

      final rgba = Uint8List(cellCount * 4);
      final frameBounds = _OpaqueBoundsAccumulator();
      final transparentRgb = preparedFrame.input.transparentColorArgb == null
          ? null
          : preparedFrame.input.transparentColorArgb! & 0x00ffffff;

      for (var y = 0; y < height; y += 1) {
        for (var x = 0; x < width; x += 1) {
          final cellIndex = y * width + x;
          final byteIndex = cellIndex * 4;
          final pixel = decoded.getPixel(
            preparedFrame.sourceRect.x + x,
            preparedFrame.sourceRect.y + y,
          );
          final red = pixel.r.toInt();
          final green = pixel.g.toInt();
          final blue = pixel.b.toInt();
          var alpha = pixel.a.toInt();
          if (transparentRgb != null &&
              ((red << 16) | (green << 8) | blue) == transparentRgb) {
            alpha = 0;
          }
          rgba[byteIndex] = red;
          rgba[byteIndex + 1] = green;
          rgba[byteIndex + 2] = blue;
          rgba[byteIndex + 3] = alpha;

          final opaque = alpha > 0;
          if (preparedFrame.frameIndex == 0) {
            structuralMask[cellIndex] = opaque ? 1 : 0;
          } else if (!opaque) {
            structuralMask[cellIndex] = 0;
          }
          if (opaque) {
            frameBounds.include(x, y);
          }
        }
      }

      final opaqueBounds = frameBounds.toRect();
      if (opaqueBounds != null) {
        unionBounds ??= _OpaqueBoundsAccumulator();
        unionBounds.includeRect(opaqueBounds);
      }
      analyzedFrames.add(
        BorderAnalyzedAlphaFrame._(
          rgbaBytes: rgba,
          durationMs: preparedFrame.durationMs,
          opaqueBounds: opaqueBounds,
          transparentColorArgb: preparedFrame.input.transparentColorArgb,
        ),
      );
    }

    var structuralOpaqueCount = 0;
    for (final value in structuralMask) {
      if (value != 0) {
        structuralOpaqueCount += 1;
      }
    }

    return BorderAssetAlphaAnalysis._(
      pixelSize: GridSize(width: width, height: height),
      opaqueUnionBounds: unionBounds?.toRect(),
      structuralOccupancyMaskRle: _encodeByteMask(structuralMask),
      frames: analyzedFrames,
      isFullyOpaque: structuralOpaqueCount == cellCount,
    );
  }
}

int _effectiveDuration(BorderAssetAlphaFrameInput frame, int frameIndex) {
  final duration = frame.durationMs;
  if (duration == null) {
    return borderAssetDefaultFrameDurationMs;
  }
  if (duration <= 0) {
    throw BorderAssetAlphaAnalysisException(
      code: BorderAssetAlphaAnalysisErrorCode.invalidFrameDuration,
      frameIndex: frameIndex,
      userMessage: 'La durée d’une frame doit être supérieure à 0 ms.',
    );
  }
  return duration;
}

void _validateTransparentColor(
  BorderAssetAlphaFrameInput frame,
  int frameIndex,
) {
  final color = frame.transparentColorArgb;
  if (color != null && (color < 0 || color > 0xffffffff)) {
    throw BorderAssetAlphaAnalysisException(
      code: BorderAssetAlphaAnalysisErrorCode.invalidTransparentColor,
      frameIndex: frameIndex,
      userMessage: 'La couleur transparente fournie est invalide.',
    );
  }
}

_StartedDecoder _startDecoder(
  BorderAssetAlphaFrameInput frame,
  int frameIndex,
) {
  try {
    if (frame._encodedImageBytes.isEmpty) {
      throw const FormatException('empty image');
    }
    final decoder = img.findDecoderForData(frame._encodedImageBytes);
    if (decoder == null) {
      throw const FormatException('unknown image format');
    }
    final info = decoder.startDecode(frame._encodedImageBytes);
    if (info == null || info.width <= 0 || info.height <= 0) {
      throw const FormatException('invalid image metadata');
    }
    return _StartedDecoder(decoder: decoder, info: info);
  } catch (_) {
    throw BorderAssetAlphaAnalysisException(
      code: BorderAssetAlphaAnalysisErrorCode.invalidEncodedImage,
      frameIndex: frameIndex,
      userMessage: 'Cette image est illisible ou son format est invalide.',
    );
  }
}

img.Image _decodePreparedFrame(_PreparedFrame prepared) {
  try {
    final decoded = prepared.decoder.decodeFrame(
      prepared.input.decodedFrameIndex,
    );
    if (decoded == null || decoded.data == null) {
      throw const FormatException('frame decode failed');
    }
    return decoded;
  } catch (_) {
    throw BorderAssetAlphaAnalysisException(
      code: BorderAssetAlphaAnalysisErrorCode.invalidEncodedImage,
      frameIndex: prepared.frameIndex,
      userMessage: 'Cette image est illisible ou son format est invalide.',
    );
  }
}

void _requireSupportedDimensions(int width, int height, int frameIndex) {
  if (width <= 0 ||
      height <= 0 ||
      width > borderRleMaxDimension ||
      height > borderRleMaxDimension ||
      width > borderAssetMaxDecodedPixels ~/ height) {
    throw BorderAssetAlphaAnalysisException(
      code: BorderAssetAlphaAnalysisErrorCode.pixelLimitExceeded,
      frameIndex: frameIndex,
      userMessage:
          'Cette image dépasse la taille maximale prise en charge par Border Studio.',
    );
  }
}

bool _fits(BorderPixelRect rect, int imageWidth, int imageHeight) =>
    rect.x >= 0 &&
    rect.y >= 0 &&
    rect.width <= imageWidth &&
    rect.height <= imageHeight &&
    rect.x <= imageWidth - rect.width &&
    rect.y <= imageHeight - rect.height;

String _encodeByteMask(Uint8List mask) {
  if (mask.isEmpty) {
    return '${borderRleV1Prefix}0:0:';
  }
  var current = mask[0] != 0;
  var runLength = 1;
  final output = StringBuffer()
    ..write(borderRleV1Prefix)
    ..write(mask.length)
    ..write(':')
    ..write(current ? '1' : '0')
    ..write(':');
  for (var index = 1; index < mask.length; index += 1) {
    final value = mask[index] != 0;
    if (value == current) {
      runLength += 1;
      continue;
    }
    output
      ..write(runLength)
      ..write(',');
    current = value;
    runLength = 1;
  }
  output.write(runLength);
  return output.toString();
}

final class _StartedDecoder {
  const _StartedDecoder({required this.decoder, required this.info});

  final img.Decoder decoder;
  final img.DecodeInfo info;
}

final class _PreparedFrame {
  const _PreparedFrame({
    required this.input,
    required this.decoder,
    required this.sourceRect,
    required this.durationMs,
    required this.frameIndex,
  });

  final BorderAssetAlphaFrameInput input;
  final img.Decoder decoder;
  final BorderPixelRect sourceRect;
  final int durationMs;
  final int frameIndex;
}

final class _OpaqueBoundsAccumulator {
  int? _minX;
  int? _minY;
  int? _maxX;
  int? _maxY;

  void include(int x, int y) {
    _minX = _minX == null || x < _minX! ? x : _minX;
    _minY = _minY == null || y < _minY! ? y : _minY;
    _maxX = _maxX == null || x > _maxX! ? x : _maxX;
    _maxY = _maxY == null || y > _maxY! ? y : _maxY;
  }

  void includeRect(BorderPixelRect rect) {
    include(rect.x, rect.y);
    include(rect.right - 1, rect.bottom - 1);
  }

  BorderPixelRect? toRect() {
    final minX = _minX;
    final minY = _minY;
    final maxX = _maxX;
    final maxY = _maxY;
    if (minX == null || minY == null || maxX == null || maxY == null) {
      return null;
    }
    return BorderPixelRect(
      x: minX,
      y: minY,
      width: maxX - minX + 1,
      height: maxY - minY + 1,
    );
  }
}
