import 'dart:convert';

import 'package:map_core/map_core.dart';

import '../contracts/json_contract_support.dart';

/// Computes the same framed SHA-256 form used by project snapshots.
///
/// [logicalName] is part of the fingerprint domain. Callers must therefore use
/// the same stable logical name when comparing two revisions of one resource.
String computeAuthoringBytesFingerprint(
  List<int> bytes, {
  required String logicalName,
}) {
  return computeNarrativeProjectFingerprint([
    NarrativeProjectFingerprintEntry(
      relativePath: logicalName,
      bytes: bytes,
    ),
  ]);
}

/// Encodes contract-safe JSON with recursively sorted object keys.
///
/// Dart map insertion order is not a protocol identity. Sorting here ensures
/// idempotency payloads and generated planning IDs remain stable across
/// transports that deserialize the same JSON with a different key order.
String canonicalAuthoringJson(Object? value) {
  final frozen = freezeContractJsonValue(value, field: 'value');
  return jsonEncode(_canonicalize(frozen));
}

String computeAuthoringJsonFingerprint(
  Object? value, {
  required String logicalName,
}) {
  return computeAuthoringBytesFingerprint(
    utf8.encode(canonicalAuthoringJson(value)),
    logicalName: logicalName,
  );
}

Object? _canonicalize(Object? value) {
  if (value is List<Object?>) {
    return [for (final item in value) _canonicalize(item)];
  }
  if (value is Map<String, Object?>) {
    final keys = value.keys.toList()..sort();
    return <String, Object?>{
      for (final key in keys) key: _canonicalize(value[key]),
    };
  }
  return value;
}
