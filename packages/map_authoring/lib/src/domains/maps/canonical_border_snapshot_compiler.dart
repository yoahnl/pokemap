import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:image/image.dart' as img;
import 'package:map_core/map_core.dart';

final class CanonicalBorderSourceFrame {
  CanonicalBorderSourceFrame({
    required this.sourceProjectRelativePath,
    required List<int> encodedImageBytes,
    this.sourceRectPx,
    this.durationMs,
    this.transparentColorArgb,
    this.decodedFrameIndex = 0,
  }) : encodedImageBytes = Uint8List.fromList(encodedImageBytes) {
    if (!_isSafeProjectRelativePath(sourceProjectRelativePath)) {
      throw const CanonicalBorderSnapshotException(
        code: 'border.snapshot.source_path_invalid',
        message: 'The Border source path must stay inside the project.',
      );
    }
  }

  final String sourceProjectRelativePath;
  final Uint8List encodedImageBytes;
  final BorderPixelRect? sourceRectPx;
  final int? durationMs;
  final int? transparentColorArgb;
  final int decodedFrameIndex;
}

final class CanonicalBorderSnapshotFile {
  CanonicalBorderSnapshotFile({
    required this.relativePath,
    required List<int> bytes,
  }) : bytes = Uint8List.fromList(bytes);

  final String relativePath;
  final Uint8List bytes;
}

final class CanonicalBorderSnapshotPreparation {
  CanonicalBorderSnapshotPreparation({
    required this.sourceElementId,
    required this.snapshot,
    required this.metrics,
    required List<CanonicalBorderSnapshotFile> files,
  }) : files = List<CanonicalBorderSnapshotFile>.unmodifiable(files);

  final String sourceElementId;
  final BorderVisualSnapshot snapshot;
  final BorderPrimitiveAssetMetrics metrics;
  final List<CanonicalBorderSnapshotFile> files;
}

final class CanonicalBorderSnapshotException implements Exception {
  const CanonicalBorderSnapshotException({
    required this.code,
    required this.message,
    this.frameIndex,
  });

  final String code;
  final String message;
  final int? frameIndex;

  @override
  String toString() => '$code: $message';
}

final class CanonicalBorderSnapshotCompiler {
  const CanonicalBorderSnapshotCompiler();

  CanonicalBorderSnapshotPreparation prepare({
    required String sourceElementId,
    required List<CanonicalBorderSourceFrame> frames,
    BorderPixelPos? anchorPx,
  }) {
    if (sourceElementId.trim().isEmpty ||
        sourceElementId != sourceElementId.trim()) {
      throw const CanonicalBorderSnapshotException(
        code: 'border.snapshot.source_element_invalid',
        message: 'The Border source element id is invalid.',
      );
    }
    if (frames.isEmpty) {
      throw const CanonicalBorderSnapshotException(
        code: 'border.snapshot.frames_required',
        message: 'At least one Border source frame is required.',
      );
    }

    final analyzed = <_AnalyzedFrame>[];
    int? width;
    int? height;
    for (var index = 0; index < frames.length; index += 1) {
      final current = _analyzeFrame(frames[index], index);
      width ??= current.width;
      height ??= current.height;
      if (current.width != width || current.height != height) {
        throw CanonicalBorderSnapshotException(
          code: 'border.snapshot.frame_dimensions_mismatch',
          message: 'Every Border source frame must share the same size.',
          frameIndex: index,
        );
      }
      analyzed.add(current);
    }

    final pixelCount = checkedBorderRleCellCount(
      width: width!,
      height: height!,
      path: r'$.borderSnapshot',
    );
    final structuralMask = List<bool>.filled(pixelCount, true);
    int? minX;
    int? minY;
    int? maxX;
    int? maxY;
    for (final frame in analyzed) {
      for (var pixelIndex = 0; pixelIndex < pixelCount; pixelIndex += 1) {
        final opaque = frame.rgba[pixelIndex * 4 + 3] > 0;
        structuralMask[pixelIndex] = structuralMask[pixelIndex] && opaque;
        if (!opaque) continue;
        final x = pixelIndex % width;
        final y = pixelIndex ~/ width;
        minX = minX == null || x < minX ? x : minX;
        minY = minY == null || y < minY ? y : minY;
        maxX = maxX == null || x > maxX ? x : maxX;
        maxY = maxY == null || y > maxY ? y : maxY;
      }
    }
    if (minX == null || minY == null || maxX == null || maxY == null) {
      throw const CanonicalBorderSnapshotException(
        code: 'border.snapshot.fully_transparent',
        message: 'A fully transparent image cannot become a Border primitive.',
      );
    }

    final opaqueBounds = BorderPixelRect(
      x: minX,
      y: minY,
      width: maxX - minX + 1,
      height: maxY - minY + 1,
    );
    final anchor = anchorPx ??
        BorderPixelPos(
          x: opaqueBounds.x + opaqueBounds.width ~/ 2,
          y: opaqueBounds.bottom - 1,
        );
    if (anchor.x < 0 ||
        anchor.y < 0 ||
        anchor.x >= width ||
        anchor.y >= height) {
      throw const CanonicalBorderSnapshotException(
        code: 'border.snapshot.anchor_outside_asset',
        message: 'The Border anchor must stay inside the source frame.',
      );
    }

    final contentFrames = <BorderSnapshotContentFrame>[
      for (final frame in analyzed)
        BorderSnapshotContentFrame(
          sourceRectPx: BorderPixelRect(
            x: 0,
            y: 0,
            width: width,
            height: height,
          ),
          durationMs: frame.durationMs,
          transparentColorArgb: frame.transparentColorArgb,
          rgbaBytes: frame.rgba,
        ),
    ];
    final contentFingerprint = computeBorderSnapshotContentFingerprint(
      frames: contentFrames,
    );
    final snapshotFrames = <BorderVisualFrameSnapshot>[];
    final files = <CanonicalBorderSnapshotFile>[];
    for (var index = 0; index < analyzed.length; index += 1) {
      final frame = analyzed[index];
      final relativePath = 'assets/borders/snapshots/$contentFingerprint/'
          'frame_${index.toString().padLeft(4, '0')}.png';
      snapshotFrames.add(
        BorderVisualFrameSnapshot(
          relativeAssetPath: relativePath,
          sourceRectPx: BorderPixelRect(
            x: 0,
            y: 0,
            width: width,
            height: height,
          ),
          durationMs: frame.durationMs,
          transparentColorArgb: frame.transparentColorArgb,
        ),
      );
      files.add(
        CanonicalBorderSnapshotFile(
          relativePath: relativePath,
          bytes: _encodePng(frame.rgba, width, height),
        ),
      );
    }

    return CanonicalBorderSnapshotPreparation(
      sourceElementId: sourceElementId,
      snapshot: BorderVisualSnapshot(
        id: 'border-snapshot-sha256:$contentFingerprint',
        contentFingerprint: contentFingerprint,
        frames: snapshotFrames,
      ),
      metrics: BorderPrimitiveAssetMetrics(
        assetFingerprint: _sourceFingerprint(
          sourceElementId: sourceElementId,
          frames: frames,
          analyzed: analyzed,
        ),
        pixelSize: GridSize(width: width, height: height),
        opaqueBounds: opaqueBounds,
        defaultAnchorPx: anchor,
        occupancyMaskRle: encodeBorderRleMask(structuralMask),
      ),
      files: files,
    );
  }
}

_AnalyzedFrame _analyzeFrame(CanonicalBorderSourceFrame frame, int index) {
  final durationMs = frame.durationMs ?? defaultBorderVisualFrameDurationMs;
  if (durationMs <= 0) {
    throw CanonicalBorderSnapshotException(
      code: 'border.snapshot.frame_duration_invalid',
      message: 'A Border frame duration must be positive.',
      frameIndex: index,
    );
  }
  final transparent = frame.transparentColorArgb;
  if (transparent != null && (transparent < 0 || transparent > 0xffffffff)) {
    throw CanonicalBorderSnapshotException(
      code: 'border.snapshot.transparent_color_invalid',
      message: 'The transparent color must be a 32-bit ARGB value.',
      frameIndex: index,
    );
  }
  try {
    final decoder = img.findDecoderForData(frame.encodedImageBytes);
    final info = decoder?.startDecode(frame.encodedImageBytes);
    if (decoder == null || info == null) {
      throw const FormatException('unsupported image');
    }
    if (frame.decodedFrameIndex < 0 ||
        frame.decodedFrameIndex >= info.numFrames) {
      throw RangeError('frame index');
    }
    final decoded = decoder.decodeFrame(frame.decodedFrameIndex);
    if (decoded == null || decoded.data == null) {
      throw const FormatException('unreadable frame');
    }
    final sourceRect = frame.sourceRectPx ??
        BorderPixelRect(
          x: 0,
          y: 0,
          width: decoded.width,
          height: decoded.height,
        );
    if (sourceRect.x < 0 ||
        sourceRect.y < 0 ||
        sourceRect.right > decoded.width ||
        sourceRect.bottom > decoded.height) {
      throw RangeError('source rect');
    }
    checkedBorderRleCellCount(
      width: sourceRect.width,
      height: sourceRect.height,
      path: r'$.borderSnapshot.frames',
    );
    final rgba = Uint8List(sourceRect.width * sourceRect.height * 4);
    final transparentRgb = transparent == null ? null : transparent & 0xffffff;
    for (var y = 0; y < sourceRect.height; y += 1) {
      for (var x = 0; x < sourceRect.width; x += 1) {
        final pixel = decoded.getPixel(sourceRect.x + x, sourceRect.y + y);
        final offset = (y * sourceRect.width + x) * 4;
        final red = pixel.r.toInt();
        final green = pixel.g.toInt();
        final blue = pixel.b.toInt();
        final rgb = (red << 16) | (green << 8) | blue;
        rgba[offset] = red;
        rgba[offset + 1] = green;
        rgba[offset + 2] = blue;
        rgba[offset + 3] = transparentRgb == rgb ? 0 : pixel.a.toInt();
      }
    }
    return _AnalyzedFrame(
      width: sourceRect.width,
      height: sourceRect.height,
      rgba: rgba,
      durationMs: durationMs,
      transparentColorArgb: transparent,
    );
  } on CanonicalBorderSnapshotException {
    rethrow;
  } on Object {
    throw CanonicalBorderSnapshotException(
      code: 'border.snapshot.image_invalid',
      message: 'The Border source image or source rectangle is invalid.',
      frameIndex: index,
    );
  }
}

String _sourceFingerprint({
  required String sourceElementId,
  required List<CanonicalBorderSourceFrame> frames,
  required List<_AnalyzedFrame> analyzed,
}) {
  final digest = _Sha256Builder()
    ..addText('pokemap-border-source-v1')
    ..addText(sourceElementId)
    ..addUint32(frames.length);
  for (var index = 0; index < frames.length; index += 1) {
    final frame = frames[index];
    digest
      ..addText(frame.sourceProjectRelativePath)
      ..addBytes(frame.encodedImageBytes)
      ..addOptionalRect(frame.sourceRectPx)
      ..addUint64(analyzed[index].durationMs)
      ..addOptionalUint32(frame.transparentColorArgb)
      ..addSignedInt64(frame.decodedFrameIndex);
  }
  return 'sha256:${digest.close()}';
}

Uint8List _encodePng(Uint8List rgba, int width, int height) {
  final image = img.Image(width: width, height: height, numChannels: 4);
  for (var y = 0; y < height; y += 1) {
    for (var x = 0; x < width; x += 1) {
      final offset = (y * width + x) * 4;
      image.setPixelRgba(
        x,
        y,
        rgba[offset],
        rgba[offset + 1],
        rgba[offset + 2],
        rgba[offset + 3],
      );
    }
  }
  return Uint8List.fromList(img.encodePng(image));
}

bool _isSafeProjectRelativePath(String value) {
  if (value.isEmpty ||
      value != value.trim() ||
      value.startsWith('/') ||
      value.contains(r'\') ||
      value.contains(':')) {
    return false;
  }
  return value.split('/').every(
        (segment) => segment.isNotEmpty && segment != '.' && segment != '..',
      );
}

final class _AnalyzedFrame {
  const _AnalyzedFrame({
    required this.width,
    required this.height,
    required this.rgba,
    required this.durationMs,
    required this.transparentColorArgb,
  });

  final int width;
  final int height;
  final Uint8List rgba;
  final int durationMs;
  final int? transparentColorArgb;
}

final class _Sha256Builder {
  _Sha256Builder() {
    _input = sha256.startChunkedConversion(_output);
  }

  final _DigestSink _output = _DigestSink();
  late final ByteConversionSink _input;
  bool _closed = false;

  void addText(String value) => addBytes(utf8.encode(value));

  void addBytes(List<int> value) {
    _requireOpen();
    addUint64(value.length);
    _input.add(value);
  }

  void addUint32(int value) {
    _requireOpen();
    if (value < 0 || value > 0xffffffff) {
      throw RangeError.range(value, 0, 0xffffffff, 'value');
    }
    _input.add(<int>[
      (value >> 24) & 0xff,
      (value >> 16) & 0xff,
      (value >> 8) & 0xff,
      value & 0xff,
    ]);
  }

  void addUint64(int value) {
    _requireOpen();
    if (value < 0) throw RangeError.value(value, 'value');
    var remaining = BigInt.from(value);
    final bytes = List<int>.filled(8, 0);
    for (var index = 7; index >= 0; index -= 1) {
      bytes[index] = (remaining & BigInt.from(0xff)).toInt();
      remaining >>= 8;
    }
    if (remaining != BigInt.zero) throw RangeError.value(value, 'value');
    _input.add(bytes);
  }

  void addSignedInt64(int value) {
    _requireOpen();
    var normalized = BigInt.from(value);
    if (normalized < -(BigInt.one << 63) ||
        normalized > (BigInt.one << 63) - BigInt.one) {
      throw RangeError.value(value, 'value');
    }
    if (normalized.isNegative) normalized += BigInt.one << 64;
    final bytes = List<int>.filled(8, 0);
    for (var index = 7; index >= 0; index -= 1) {
      bytes[index] = (normalized & BigInt.from(0xff)).toInt();
      normalized >>= 8;
    }
    _input.add(bytes);
  }

  void addOptionalUint32(int? value) {
    _requireOpen();
    _input.add(<int>[value == null ? 0 : 1]);
    if (value != null) addUint32(value);
  }

  void addOptionalRect(BorderPixelRect? value) {
    _requireOpen();
    _input.add(<int>[value == null ? 0 : 1]);
    if (value == null) return;
    addSignedInt64(value.x);
    addSignedInt64(value.y);
    addUint64(value.width);
    addUint64(value.height);
  }

  String close() {
    _requireOpen();
    _closed = true;
    _input.close();
    return _output.value.toString();
  }

  void _requireOpen() {
    if (_closed) throw StateError('Digest builder is closed');
  }
}

final class _DigestSink implements Sink<Digest> {
  Digest? _value;

  Digest get value => _value ?? (throw StateError('Digest is incomplete'));

  @override
  void add(Digest data) {
    if (_value != null) throw StateError('Digest already received');
    _value = data;
  }

  @override
  void close() {}
}
