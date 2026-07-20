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
  final seen = <String>{};
  final framed = BytesBuilder(copy: false);
  for (final entry in ordered) {
    if (!seen.add(entry.relativePath)) {
      throw ArgumentError(
          'Duplicate fingerprint path "${entry.relativePath}".');
    }
    final pathBytes = utf8.encode(entry.relativePath);
    framed
      ..add(_uint64(pathBytes.length))
      ..add(pathBytes)
      ..add(_uint64(entry.bytes.length))
      ..add(entry.bytes);
  }
  return 'sha256:${sha256.convert(framed.takeBytes())}';
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
