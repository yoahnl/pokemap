import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:image/image.dart' as img;
import 'package:map_core/map_core.dart';

import 'border_asset_alpha_analyzer.dart';

const String _snapshotHashDomain = 'pokemap-border-snapshot-v1';
const String _sourceHashDomain = 'pokemap-border-source-v1';

enum BorderAssetSnapshotErrorCode {
  unsafeSourcePath,
  fullyTransparent,
  anchorOutsideAsset,
}

final class BorderAssetSnapshotException implements Exception {
  const BorderAssetSnapshotException({
    required this.code,
    required this.userMessage,
    this.frameIndex,
  });

  final BorderAssetSnapshotErrorCode code;
  final String userMessage;
  final int? frameIndex;

  @override
  String toString() =>
      'BorderAssetSnapshotException.${code.name}: $userMessage';
}

/// One source frame selected through the normal project asset library.
final class BorderAssetSnapshotSourceFrame {
  BorderAssetSnapshotSourceFrame({
    required this.sourceProjectRelativePath,
    required Uint8List encodedImageBytes,
    this.sourceRectPx,
    this.durationMs,
    this.transparentColorArgb,
    this.decodedFrameIndex = 0,
  }) : _encodedImageBytes = Uint8List.fromList(encodedImageBytes) {
    if (!_isSafeProjectRelativePath(sourceProjectRelativePath)) {
      throw const BorderAssetSnapshotException(
        code: BorderAssetSnapshotErrorCode.unsafeSourcePath,
        userMessage:
            'L’image source doit rester dans le projet et utiliser un chemin relatif sûr.',
      );
    }
  }

  final String sourceProjectRelativePath;
  final Uint8List _encodedImageBytes;
  final BorderPixelRect? sourceRectPx;
  final int? durationMs;
  final int? transparentColorArgb;
  final int decodedFrameIndex;

  Uint8List get encodedImageBytes => Uint8List.fromList(_encodedImageBytes);
}

final class BorderAssetSnapshotRequest {
  BorderAssetSnapshotRequest({
    required List<BorderAssetSnapshotSourceFrame> frames,
    this.anchorPx,
  }) : _frames = List<BorderAssetSnapshotSourceFrame>.unmodifiable(frames);

  final List<BorderAssetSnapshotSourceFrame> _frames;
  final BorderPixelPos? anchorPx;

  List<BorderAssetSnapshotSourceFrame> get frames => _frames;
}

/// One immutable content-addressed file to stage below the project root.
final class BorderSnapshotFilePayload {
  BorderSnapshotFilePayload({
    required this.relativePath,
    required Uint8List bytes,
  })  : _bytes = Uint8List.fromList(bytes),
        contentSha256 = sha256.convert(bytes).toString() {
    if (!_isSafeSnapshotRelativePath(relativePath)) {
      throw ArgumentError.value(
        relativePath,
        'relativePath',
        'must remain below assets/borders/snapshots/',
      );
    }
  }

  final String relativePath;
  final Uint8List _bytes;
  final String contentSha256;

  Uint8List get bytes => Uint8List.fromList(_bytes);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BorderSnapshotFilePayload &&
          relativePath == other.relativePath &&
          contentSha256 == other.contentSha256 &&
          _bytesEqual(_bytes, other._bytes);

  @override
  int get hashCode => Object.hash(relativePath, contentSha256);
}

final class BorderAssetSnapshotPreparation {
  BorderAssetSnapshotPreparation({
    required this.snapshot,
    required this.metrics,
    required List<BorderSnapshotFilePayload> files,
  }) : _files = List<BorderSnapshotFilePayload>.unmodifiable(files);

  final BorderVisualSnapshot snapshot;
  final BorderPrimitiveAssetMetrics metrics;
  final List<BorderSnapshotFilePayload> _files;

  List<BorderSnapshotFilePayload> get files => _files;
}

enum BorderSnapshotPayloadIssueCode {
  duplicateFile,
  missingFile,
  unexpectedFile,
  metadataMismatch,
  invalidImage,
  contentFingerprintMismatch,
}

final class BorderSnapshotPayloadIssue {
  const BorderSnapshotPayloadIssue({
    required this.code,
    this.snapshotId,
    this.relativePath,
  });

  final BorderSnapshotPayloadIssueCode code;
  final String? snapshotId;
  final String? relativePath;
}

final class BorderSnapshotPayloadValidation {
  BorderSnapshotPayloadValidation({
    required List<BorderSnapshotPayloadIssue> issues,
  }) : issues = List<BorderSnapshotPayloadIssue>.unmodifiable(issues);

  final List<BorderSnapshotPayloadIssue> issues;

  bool get isValid => issues.isEmpty;
}

/// Converts current source frames into immutable snapshot metadata and files.
///
/// The snapshot digest deliberately excludes source and destination paths.
/// [BorderPrimitiveAssetMetrics.assetFingerprint] deliberately includes the
/// source path and encoded bytes so the Studio can later detect divergence.
final class BorderAssetSnapshotService {
  const BorderAssetSnapshotService({
    this.alphaAnalyzer = const BorderAssetAlphaAnalyzer(),
  });

  final BorderAssetAlphaAnalyzer alphaAnalyzer;

  /// Proves that staged file payloads are exactly the canonical pixel content
  /// referenced by [snapshots]. This is deliberately independent from
  /// caller-supplied filesystem integrity flags: publication must never commit
  /// a manifest merely because its caller asserted that files existed.
  BorderSnapshotPayloadValidation validatePreparedPayloads({
    required List<BorderVisualSnapshot> snapshots,
    required List<BorderSnapshotFilePayload> files,
  }) {
    final issues = <BorderSnapshotPayloadIssue>[];
    final byPath = <String, BorderSnapshotFilePayload>{};
    for (final file in files) {
      if (byPath.containsKey(file.relativePath)) {
        issues.add(
          BorderSnapshotPayloadIssue(
            code: BorderSnapshotPayloadIssueCode.duplicateFile,
            relativePath: file.relativePath,
          ),
        );
      } else {
        byPath[file.relativePath] = file;
      }
    }

    final expectedPaths = <String>{};
    for (final snapshot in snapshots) {
      var canVerifyFingerprint = true;
      final frameInputs = <BorderAssetAlphaFrameInput>[];
      for (var index = 0; index < snapshot.frames.length; index += 1) {
        final frame = snapshot.frames[index];
        final expectedPath = 'assets/borders/snapshots/'
            '${snapshot.contentFingerprint}/'
            'frame_${index.toString().padLeft(4, '0')}.png';
        expectedPaths.add(expectedPath);
        if (frame.relativeAssetPath != expectedPath ||
            frame.sourceRectPx.x != 0 ||
            frame.sourceRectPx.y != 0) {
          issues.add(
            BorderSnapshotPayloadIssue(
              code: BorderSnapshotPayloadIssueCode.metadataMismatch,
              snapshotId: snapshot.id,
              relativePath: frame.relativeAssetPath,
            ),
          );
          canVerifyFingerprint = false;
        }
        final payload = byPath[frame.relativeAssetPath];
        if (payload == null) {
          issues.add(
            BorderSnapshotPayloadIssue(
              code: BorderSnapshotPayloadIssueCode.missingFile,
              snapshotId: snapshot.id,
              relativePath: frame.relativeAssetPath,
            ),
          );
          canVerifyFingerprint = false;
          continue;
        }
        frameInputs.add(
          BorderAssetAlphaFrameInput(
            encodedImageBytes: payload._bytes,
            durationMs: frame.durationMs,
            transparentColorArgb: frame.transparentColorArgb,
          ),
        );
      }
      if (!canVerifyFingerprint ||
          frameInputs.length != snapshot.frames.length) {
        continue;
      }
      try {
        final analysis = alphaAnalyzer.analyze(
          BorderAssetAlphaAnalysisInput(frames: frameInputs),
        );
        final firstRect = snapshot.frames.first.sourceRectPx;
        if (analysis.pixelSize.width != firstRect.width ||
            analysis.pixelSize.height != firstRect.height) {
          issues.add(
            BorderSnapshotPayloadIssue(
              code: BorderSnapshotPayloadIssueCode.metadataMismatch,
              snapshotId: snapshot.id,
              relativePath: snapshot.frames.first.relativeAssetPath,
            ),
          );
          continue;
        }
        if (_snapshotFingerprint(analysis) != snapshot.contentFingerprint) {
          issues.add(
            BorderSnapshotPayloadIssue(
              code: BorderSnapshotPayloadIssueCode.contentFingerprintMismatch,
              snapshotId: snapshot.id,
            ),
          );
        }
      } on BorderAssetAlphaAnalysisException {
        issues.add(
          BorderSnapshotPayloadIssue(
            code: BorderSnapshotPayloadIssueCode.invalidImage,
            snapshotId: snapshot.id,
          ),
        );
      }
    }

    for (final path in byPath.keys) {
      if (!expectedPaths.contains(path)) {
        issues.add(
          BorderSnapshotPayloadIssue(
            code: BorderSnapshotPayloadIssueCode.unexpectedFile,
            relativePath: path,
          ),
        );
      }
    }
    return BorderSnapshotPayloadValidation(issues: issues);
  }

  BorderAssetSnapshotPreparation prepare(BorderAssetSnapshotRequest request) {
    final analysis = alphaAnalyzer.analyze(
      BorderAssetAlphaAnalysisInput(
        frames: <BorderAssetAlphaFrameInput>[
          for (final frame in request.frames)
            BorderAssetAlphaFrameInput(
              encodedImageBytes: frame._encodedImageBytes,
              sourceRectPx: frame.sourceRectPx,
              durationMs: frame.durationMs,
              transparentColorArgb: frame.transparentColorArgb,
              decodedFrameIndex: frame.decodedFrameIndex,
            ),
        ],
      ),
    );
    final opaqueBounds = analysis.opaqueUnionBounds;
    if (opaqueBounds == null) {
      throw const BorderAssetSnapshotException(
        code: BorderAssetSnapshotErrorCode.fullyTransparent,
        userMessage:
            'Cet asset est entièrement transparent et ne peut pas former une primitive.',
      );
    }

    final anchor = request.anchorPx ??
        BorderPixelPos(
          x: opaqueBounds.x + opaqueBounds.width ~/ 2,
          y: opaqueBounds.bottom - 1,
        );
    if (anchor.x < 0 ||
        anchor.y < 0 ||
        anchor.x >= analysis.pixelSize.width ||
        anchor.y >= analysis.pixelSize.height) {
      throw const BorderAssetSnapshotException(
        code: BorderAssetSnapshotErrorCode.anchorOutsideAsset,
        userMessage: 'L’ancre doit se trouver à l’intérieur de l’asset.',
      );
    }

    final snapshotFingerprint = _snapshotFingerprint(analysis);
    final snapshotFrames = <BorderVisualFrameSnapshot>[];
    final files = <BorderSnapshotFilePayload>[];
    for (var index = 0; index < analysis.frames.length; index += 1) {
      final analyzed = analysis.frames[index];
      final relativePath = 'assets/borders/snapshots/'
          '$snapshotFingerprint/frame_${index.toString().padLeft(4, '0')}.png';
      final pngBytes = _encodeNormalizedPng(
        rgba: analyzed.rgbaBytes,
        width: analysis.pixelSize.width,
        height: analysis.pixelSize.height,
      );
      files.add(
        BorderSnapshotFilePayload(
          relativePath: relativePath,
          bytes: pngBytes,
        ),
      );
      snapshotFrames.add(
        BorderVisualFrameSnapshot(
          relativeAssetPath: relativePath,
          sourceRectPx: BorderPixelRect(
            x: 0,
            y: 0,
            width: analysis.pixelSize.width,
            height: analysis.pixelSize.height,
          ),
          durationMs: analyzed.durationMs,
          transparentColorArgb: analyzed.transparentColorArgb,
        ),
      );
    }

    return BorderAssetSnapshotPreparation(
      snapshot: BorderVisualSnapshot(
        id: 'border-snapshot-sha256:$snapshotFingerprint',
        contentFingerprint: snapshotFingerprint,
        frames: snapshotFrames,
      ),
      metrics: BorderPrimitiveAssetMetrics(
        assetFingerprint: _sourceFingerprint(request, analysis),
        pixelSize: analysis.pixelSize,
        opaqueBounds: opaqueBounds,
        defaultAnchorPx: anchor,
        occupancyMaskRle: analysis.structuralOccupancyMaskRle,
      ),
      files: files,
    );
  }
}

String _snapshotFingerprint(BorderAssetAlphaAnalysis analysis) {
  final digest = _Sha256Builder()..addText(_snapshotHashDomain);
  digest
    ..addUint32(analysis.frames.length)
    ..addUint32(analysis.pixelSize.width)
    ..addUint32(analysis.pixelSize.height);
  for (final frame in analysis.frames) {
    digest
      ..addUint32(0)
      ..addUint32(0)
      ..addUint32(analysis.pixelSize.width)
      ..addUint32(analysis.pixelSize.height)
      ..addUint64(frame.durationMs)
      ..addOptionalUint32(frame.transparentColorArgb)
      ..addBytes(frame.rgbaBytes);
  }
  return digest.close();
}

String _sourceFingerprint(
  BorderAssetSnapshotRequest request,
  BorderAssetAlphaAnalysis analysis,
) {
  final digest = _Sha256Builder()
    ..addText(_sourceHashDomain)
    ..addUint32(request.frames.length);
  for (var index = 0; index < request.frames.length; index += 1) {
    final source = request.frames[index];
    final effective = analysis.frames[index];
    digest
      ..addText(source.sourceProjectRelativePath)
      ..addBytes(source._encodedImageBytes)
      ..addOptionalRect(source.sourceRectPx)
      ..addUint64(effective.durationMs)
      ..addOptionalUint32(source.transparentColorArgb)
      ..addSignedInt64(source.decodedFrameIndex);
  }
  return 'sha256:${digest.close()}';
}

Uint8List _encodeNormalizedPng({
  required Uint8List rgba,
  required int width,
  required int height,
}) {
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

final class _Sha256Builder {
  _Sha256Builder() {
    _input = sha256.startChunkedConversion(_output);
  }

  final _DigestSink _output = _DigestSink();
  late final ByteConversionSink _input;
  bool _closed = false;

  void addText(String value) {
    final bytes = utf8.encode(value);
    addBytes(bytes);
  }

  void addBytes(List<int> bytes) {
    _requireOpen();
    addUint64(bytes.length);
    _input.add(bytes);
  }

  void addUint32(int value) {
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
    if (value < 0) {
      throw RangeError.value(value, 'value', 'must be non-negative');
    }
    var remaining = BigInt.from(value);
    final bytes = List<int>.filled(8, 0);
    for (var index = 7; index >= 0; index -= 1) {
      bytes[index] = (remaining & BigInt.from(0xff)).toInt();
      remaining >>= 8;
    }
    if (remaining != BigInt.zero) {
      throw RangeError.value(value, 'value', 'must fit uint64');
    }
    _input.add(bytes);
  }

  void addSignedInt64(int value) {
    var normalized = BigInt.from(value);
    final modulus = BigInt.one << 64;
    if (normalized < -(BigInt.one << 63) ||
        normalized > (BigInt.one << 63) - BigInt.one) {
      throw RangeError.value(value, 'value', 'must fit int64');
    }
    if (normalized.isNegative) normalized += modulus;
    final bytes = List<int>.filled(8, 0);
    for (var index = 7; index >= 0; index -= 1) {
      bytes[index] = (normalized & BigInt.from(0xff)).toInt();
      normalized >>= 8;
    }
    _input.add(bytes);
  }

  void addOptionalUint32(int? value) {
    _input.add(<int>[value == null ? 0 : 1]);
    if (value != null) addUint32(value);
  }

  void addOptionalRect(BorderPixelRect? rect) {
    _input.add(<int>[rect == null ? 0 : 1]);
    if (rect == null) return;
    addSignedInt64(rect.x);
    addSignedInt64(rect.y);
    addUint64(rect.width);
    addUint64(rect.height);
  }

  String close() {
    _requireOpen();
    _closed = true;
    _input.close();
    return _output.value.toString();
  }

  void _requireOpen() {
    if (_closed) throw StateError('SHA-256 builder is already closed');
  }
}

final class _DigestSink implements Sink<Digest> {
  Digest? _value;

  Digest get value => _value ?? (throw StateError('Digest is not complete'));

  @override
  void add(Digest data) {
    if (_value != null) throw StateError('Digest already received');
    _value = data;
  }

  @override
  void close() {}
}

bool _isSafeProjectRelativePath(String path) {
  if (path.isEmpty ||
      path.startsWith('/') ||
      path.contains(r'\') ||
      path.contains(':') ||
      path.trim() != path) {
    return false;
  }
  return path.split('/').every(
        (segment) => segment.isNotEmpty && segment != '.' && segment != '..',
      );
}

bool _isSafeSnapshotRelativePath(String path) =>
    path.startsWith('assets/borders/snapshots/') &&
    _isSafeProjectRelativePath(path);

bool _bytesEqual(Uint8List left, Uint8List right) {
  if (left.length != right.length) return false;
  for (var index = 0; index < left.length; index += 1) {
    if (left[index] != right[index]) return false;
  }
  return true;
}
