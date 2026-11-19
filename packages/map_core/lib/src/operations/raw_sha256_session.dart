import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:meta/meta.dart';

import 'narrative_fingerprint_sha256.dart';

String narrativeEventBytesFingerprint(List<int> bytes) {
  final session = RawSha256Session();
  try {
    session.add(bytes);
    return 'sha256:${session.finish()}';
  } finally {
    session.dispose();
  }
}

final class RawSha256Session {
  RawSha256Session()
    : this.withSinkFactory(createNarrativeFingerprintSha256Sink);

  @visibleForTesting
  RawSha256Session.withSinkFactory(
    ByteConversionSink Function(Sink<Digest>) factory,
  ) {
    try {
      _input = factory(_output);
    } on Object {
      _output.discard();
      rethrow;
    }
  }

  final _RawDigestOutput _output = _RawDigestOutput();
  ByteConversionSink? _input;
  String? _result;
  bool _disposed = false;

  void add(List<int> bytes) {
    final input = _input;
    if (input == null || _disposed) {
      throw StateError('The raw SHA256 session is closed.');
    }
    try {
      input.add(bytes);
    } on Object {
      dispose();
      rethrow;
    }
  }

  String finish() {
    if (_disposed) throw StateError('The raw SHA256 session is disposed.');
    final existing = _result;
    if (existing != null) return existing;
    try {
      _input!.close();
      final digest = _output.digest;
      if (digest == null) {
        throw StateError('The raw SHA256 digest was not produced.');
      }
      final result = digest.toString();
      _input = null;
      return _result = result;
    } on Object {
      dispose();
      rethrow;
    }
  }

  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _output.discard();
    final input = _input;
    _input = null;
    try {
      input?.close();
    } on Object {
      return;
    }
  }
}

final class _RawDigestOutput implements Sink<Digest> {
  Digest? digest;
  bool _accepting = true;

  @override
  void add(Digest value) {
    if (!_accepting) return;
    if (digest != null) throw StateError('More than one raw SHA256 digest.');
    digest = value;
  }

  void discard() {
    _accepting = false;
    digest = null;
  }

  @override
  void close() {}
}
