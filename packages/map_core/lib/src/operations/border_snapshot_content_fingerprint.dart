import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart' show Digest, sha256;
import 'package:meta/meta.dart' show immutable;

import '../exceptions/map_exceptions.dart';
import '../models/border_value_objects.dart';

const String _borderSnapshotHashDomain = 'pokemap-border-snapshot-v1';

/// One decoded frame used by the immutable Border snapshot identity contract.
///
/// The bytes are row-major RGBA pixels for [sourceRectPx]. Encoded PNG bytes
/// and source/destination paths are deliberately absent from this value.
@immutable
final class BorderSnapshotContentFrame {
  BorderSnapshotContentFrame({
    required this.sourceRectPx,
    required this.durationMs,
    this.transparentColorArgb,
    required Uint8List rgbaBytes,
  }) : _rgbaBytes = Uint8List.fromList(rgbaBytes) {
    if (sourceRectPx.x < 0 || sourceRectPx.y < 0) {
      throw const ValidationException(
        'BorderSnapshotContentFrame.sourceRectPx coordinates must be >= 0',
      );
    }
    if (durationMs <= 0) {
      throw const ValidationException(
        'BorderSnapshotContentFrame.durationMs must be > 0',
      );
    }
    final color = transparentColorArgb;
    if (color != null && (color < 0 || color > 0xffffffff)) {
      throw const ValidationException(
        'BorderSnapshotContentFrame.transparentColorArgb must be a 32-bit '
        'ARGB value',
      );
    }
    final expectedLength = sourceRectPx.width * sourceRectPx.height * 4;
    if (_rgbaBytes.length != expectedLength) {
      throw ValidationException(
        'BorderSnapshotContentFrame.rgbaBytes must contain exactly '
        '$expectedLength bytes',
      );
    }
  }

  final BorderPixelRect sourceRectPx;
  final int durationMs;
  final int? transparentColorArgb;
  final Uint8List _rgbaBytes;

  Uint8List get rgbaBytes => Uint8List.fromList(_rgbaBytes);
}

/// Computes the V1 immutable snapshot SHA-256 from decoded pixels + metadata.
///
/// This is the same cross-package contract used at publication and runtime
/// readiness. It intentionally excludes encoded-file bytes and all paths.
String computeBorderSnapshotContentFingerprint({
  required List<BorderSnapshotContentFrame> frames,
}) {
  if (frames.isEmpty) {
    throw const ValidationException(
      'Border snapshot content fingerprint requires at least one frame',
    );
  }
  final width = frames.first.sourceRectPx.width;
  final height = frames.first.sourceRectPx.height;
  for (final frame in frames.skip(1)) {
    if (frame.sourceRectPx.width != width ||
        frame.sourceRectPx.height != height) {
      throw const ValidationException(
        'Border snapshot content frames must share dimensions',
      );
    }
  }

  final digest = _Sha256Builder()..addText(_borderSnapshotHashDomain);
  digest
    ..addUint32(frames.length)
    ..addUint32(width)
    ..addUint32(height);
  for (final frame in frames) {
    digest
      ..addUint32(frame.sourceRectPx.x)
      ..addUint32(frame.sourceRectPx.y)
      ..addUint32(frame.sourceRectPx.width)
      ..addUint32(frame.sourceRectPx.height)
      ..addUint64(frame.durationMs)
      ..addOptionalUint32(frame.transparentColorArgb)
      ..addBytes(frame._rgbaBytes);
  }
  return digest.close();
}

final class _Sha256Builder {
  _Sha256Builder() {
    _input = sha256.startChunkedConversion(_output);
  }

  final _DigestSink _output = _DigestSink();
  late final ByteConversionSink _input;
  bool _closed = false;

  void addText(String value) => addBytes(utf8.encode(value));

  void addBytes(List<int> bytes) {
    _requireOpen();
    addUint64(bytes.length);
    _input.add(bytes);
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

  void addOptionalUint32(int? value) {
    _requireOpen();
    _input.add(<int>[value == null ? 0 : 1]);
    if (value != null) addUint32(value);
  }

  String close() {
    _requireOpen();
    _closed = true;
    _input.close();
    return _output.value.toString();
  }

  void _requireOpen() {
    if (_closed) {
      throw StateError('SHA-256 builder is already closed');
    }
  }
}

final class _DigestSink implements Sink<Digest> {
  Digest? _value;

  Digest get value => _value ?? (throw StateError('Missing SHA-256 digest'));

  @override
  void add(Digest data) {
    if (_value != null) {
      throw StateError('SHA-256 digest was emitted more than once');
    }
    _value = data;
  }

  @override
  void close() {}
}
