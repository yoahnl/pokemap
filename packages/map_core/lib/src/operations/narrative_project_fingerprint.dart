import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:meta/meta.dart' show immutable;

@immutable
final class NarrativeProjectFingerprintEntry {
  NarrativeProjectFingerprintEntry({
    required String relativePath,
    required List<int> bytes,
  })  : relativePath = _normalizePath(relativePath),
        bytes = Uint8List.fromList(bytes);

  final String relativePath;
  final Uint8List bytes;
}

String computeNarrativeProjectFingerprint(
  Iterable<NarrativeProjectFingerprintEntry> entries,
) {
  final ordered = entries.toList()
    ..sort((left, right) => left.relativePath.compareTo(right.relativePath));
  final builder = NarrativeProjectFingerprintBuilder();
  for (final entry in ordered) {
    builder
      ..startEntry(
        relativePath: entry.relativePath,
        byteLength: entry.bytes.length,
      )
      ..addBytes(entry.bytes)
      ..endEntry();
  }
  return builder.close();
}

/// Incrementally computes the canonical project fingerprint without retaining
/// file payloads or the complete framed byte stream in memory.
///
/// Entries must be supplied in ascending normalized path order. Each entry's
/// declared byte length is checked against the chunks received before the next
/// entry can start.
final class NarrativeProjectFingerprintBuilder {
  NarrativeProjectFingerprintBuilder() {
    _input = sha256.startChunkedConversion(_output);
  }

  final _NarrativeProjectDigestSink _output = _NarrativeProjectDigestSink();
  late final ByteConversionSink _input;
  String? _lastPath;
  int? _remainingEntryBytes;
  String? _fingerprint;

  void startEntry({
    required String relativePath,
    required int byteLength,
  }) {
    _checkOpen();
    if (_remainingEntryBytes != null) {
      throw StateError('The previous fingerprint entry is still open.');
    }
    if (byteLength < 0) {
      throw ArgumentError.value(byteLength, 'byteLength');
    }
    final path = _normalizePath(relativePath);
    final previousPath = _lastPath;
    if (previousPath != null) {
      final order = path.compareTo(previousPath);
      if (order == 0) {
        throw ArgumentError('Duplicate fingerprint path "$path".');
      }
      if (order < 0) {
        throw ArgumentError(
          'Fingerprint paths must be supplied in ascending order: '
          '"$path" follows "$previousPath".',
        );
      }
    }
    final pathBytes = utf8.encode(path);
    _input
      ..add(_uint64(pathBytes.length))
      ..add(pathBytes)
      ..add(_uint64(byteLength));
    _lastPath = path;
    _remainingEntryBytes = byteLength;
  }

  void addBytes(List<int> bytes) {
    _checkOpen();
    final remaining = _remainingEntryBytes;
    if (remaining == null) {
      throw StateError('No fingerprint entry is open.');
    }
    if (bytes.length > remaining) {
      throw StateError(
        'Fingerprint entry received ${bytes.length} bytes with only '
        '$remaining remaining.',
      );
    }
    _input.add(bytes);
    _remainingEntryBytes = remaining - bytes.length;
  }

  void endEntry() {
    _checkOpen();
    final remaining = _remainingEntryBytes;
    if (remaining == null) {
      throw StateError('No fingerprint entry is open.');
    }
    if (remaining != 0) {
      throw StateError(
        'Fingerprint entry ended with $remaining bytes missing.',
      );
    }
    _remainingEntryBytes = null;
  }

  String close() {
    final existing = _fingerprint;
    if (existing != null) return existing;
    if (_remainingEntryBytes != null) {
      throw StateError('Cannot close with a fingerprint entry still open.');
    }
    _input.close();
    final digest = _output.digest;
    if (digest == null) {
      throw StateError('The project fingerprint digest was not produced.');
    }
    return _fingerprint = 'sha256:$digest';
  }

  void _checkOpen() {
    if (_fingerprint != null) {
      throw StateError('The project fingerprint builder is closed.');
    }
  }
}

final class _NarrativeProjectDigestSink implements Sink<Digest> {
  Digest? digest;

  @override
  void add(Digest data) {
    if (digest != null) {
      throw StateError('The digest sink received more than one value.');
    }
    digest = data;
  }

  @override
  void close() {}
}

String _normalizePath(String value) {
  var path = value.trim().replaceAll('\\', '/');
  while (path.startsWith('./')) {
    path = path.substring(2);
  }
  while (path.contains('//')) {
    path = path.replaceAll('//', '/');
  }
  if (path.isEmpty || path.startsWith('/') || path.split('/').contains('..')) {
    throw ArgumentError.value(
        value, 'relativePath', 'must stay project-relative');
  }
  return path;
}

Uint8List _uint64(int value) {
  if (value < 0) throw ArgumentError.value(value, 'value');
  final data = ByteData(8)..setUint64(0, value, Endian.big);
  return data.buffer.asUint8List();
}
