import 'dart:convert';

import 'package:crypto/crypto.dart';

import '../models/presentation_cinematic_asset.dart';
import '../operations/presentation_media_publication.dart';
import '../serialization/presentation_cinematic_codec.dart';

enum PresentationExecutionEventKind {
  prepare,
  start,
  fallback,
  skip,
  failure,
  dispose,
}

enum PresentationExecutionSource { player, editor, directApi, jsonl, mcp }

enum PresentationExecutionOutcome { completed, skipped, cancelled, failed }

final class PresentationExecutionCorrelation {
  PresentationExecutionCorrelation({
    required String runId,
    required String projectRevision,
    required String assetId,
    required String contentHash,
  }) : runId = _safeIdentifier(runId, 'runId'),
       projectRevision = _sha256(projectRevision, 'projectRevision'),
       assetId = _safeIdentifier(assetId, 'assetId'),
       contentHash = _sha256(contentHash, 'contentHash');

  final String runId;
  final String projectRevision;
  final String assetId;
  final String contentHash;
}

final class PresentationExecutionEvent {
  const PresentationExecutionEvent._({
    required this.sequence,
    required this.kind,
    required this.source,
    this.stableErrorCode,
  });

  final int sequence;
  final PresentationExecutionEventKind kind;
  final PresentationExecutionSource source;
  final String? stableErrorCode;

  Map<String, Object?> toJson() => {
    'sequence': sequence,
    'kind': kind.name,
    'source': source.name,
    if (stableErrorCode != null) 'stableErrorCode': stableErrorCode,
  };
}

final class PresentationExecutionTerminal {
  const PresentationExecutionTerminal._({
    required this.sequence,
    required this.outcome,
    required this.source,
    this.stableErrorCode,
  });

  final int sequence;
  final PresentationExecutionOutcome outcome;
  final PresentationExecutionSource source;
  final String? stableErrorCode;

  Map<String, Object?> toJson() => {
    'sequence': sequence,
    'outcome': outcome.name,
    'source': source.name,
    if (stableErrorCode != null) 'stableErrorCode': stableErrorCode,
  };
}

final class PresentationExecutionReceipt {
  PresentationExecutionReceipt._({
    required this.correlation,
    required this.platform,
    required List<PresentationExecutionEvent> events,
    required this.terminal,
  }) : events = List<PresentationExecutionEvent>.unmodifiable(events);

  static const schemaVersion = 1;

  final PresentationExecutionCorrelation correlation;
  final PresentationMediaTargetPlatform platform;
  final List<PresentationExecutionEvent> events;
  final PresentationExecutionTerminal terminal;

  Map<String, Object?> toJson() => {
    'schemaVersion': schemaVersion,
    'runId': correlation.runId,
    'projectRevision': correlation.projectRevision,
    'assetId': correlation.assetId,
    'contentHash': correlation.contentHash,
    'platform': platform.name,
    'events': events.map((event) => event.toJson()).toList(growable: false),
    'terminal': terminal.toJson(),
  };

  String encodeCanonical() => jsonEncode(_canonicalize(toJson()));
}

final class PresentationExecutionRecorder {
  PresentationExecutionRecorder({
    required this.correlation,
    required this.platform,
  });

  final PresentationExecutionCorrelation correlation;
  final PresentationMediaTargetPlatform platform;
  final List<PresentationExecutionEvent> _events = [];
  PresentationExecutionTerminal? _terminal;
  PresentationExecutionReceipt? _receipt;

  PresentationExecutionReceipt? get receipt => _receipt;

  List<PresentationExecutionEvent> get events =>
      List<PresentationExecutionEvent>.unmodifiable(_events);

  PresentationExecutionEvent? get lastEvent =>
      _events.isEmpty ? null : _events.last;

  PresentationExecutionEvent? record(
    PresentationExecutionEventKind kind, {
    required PresentationExecutionSource source,
    String? stableErrorCode,
  }) {
    if (_terminal != null) return null;
    final normalizedErrorCode = _eventErrorCode(kind, stableErrorCode);
    final event = PresentationExecutionEvent._(
      sequence: _events.length,
      kind: kind,
      source: source,
      stableErrorCode: normalizedErrorCode,
    );
    _events.add(event);
    return event;
  }

  PresentationExecutionTerminal finish(
    PresentationExecutionOutcome outcome, {
    required PresentationExecutionSource source,
    String? stableErrorCode,
  }) {
    final existing = _terminal;
    if (existing != null) return existing;
    final normalizedErrorCode = _terminalErrorCode(outcome, stableErrorCode);
    if (outcome == PresentationExecutionOutcome.failed &&
        (lastEvent?.kind != PresentationExecutionEventKind.failure ||
            lastEvent?.stableErrorCode != normalizedErrorCode)) {
      record(
        PresentationExecutionEventKind.failure,
        source: source,
        stableErrorCode: normalizedErrorCode,
      );
    }
    final terminal = PresentationExecutionTerminal._(
      sequence: _events.length,
      outcome: outcome,
      source: source,
      stableErrorCode: normalizedErrorCode,
    );
    _terminal = terminal;
    _receipt = PresentationExecutionReceipt._(
      correlation: correlation,
      platform: platform,
      events: _events,
      terminal: terminal,
    );
    return terminal;
  }
}

String buildPresentationExecutionRunId({
  required String runtimeSourceId,
  required String assetId,
  required int nonce,
  int sequence = 0,
}) {
  final digest = sha256.convert(
    utf8.encode(
      jsonEncode(<Object?>[runtimeSourceId, assetId, nonce, sequence]),
    ),
  );
  return 'cinematic-run:sha256:$digest';
}

String buildPresentationExecutionAssetCorrelationId(String assetId) {
  final normalized = _nonBlank(assetId, 'assetId');
  if (RegExp(r'^[A-Za-z0-9][A-Za-z0-9._:-]{0,255}$').hasMatch(normalized)) {
    return normalized;
  }
  return 'asset:sha256:${sha256.convert(utf8.encode(normalized))}';
}

String computePresentationCinematicContentHash(
  PresentationCinematicAsset asset,
) {
  final canonical = jsonEncode(
    _canonicalize(encodePresentationCinematicAsset(asset)),
  );
  return 'sha256:${sha256.convert(utf8.encode(canonical))}';
}

String? _eventErrorCode(
  PresentationExecutionEventKind kind,
  String? stableErrorCode,
) {
  if (kind == PresentationExecutionEventKind.failure) {
    return _stableErrorCode(stableErrorCode, 'stableErrorCode');
  }
  if (stableErrorCode != null) {
    throw ArgumentError.value(
      stableErrorCode,
      'stableErrorCode',
      'is only valid for a failure event',
    );
  }
  return null;
}

String? _terminalErrorCode(
  PresentationExecutionOutcome outcome,
  String? stableErrorCode,
) {
  if (outcome == PresentationExecutionOutcome.failed) {
    return _stableErrorCode(stableErrorCode, 'stableErrorCode');
  }
  if (stableErrorCode != null) {
    throw ArgumentError.value(
      stableErrorCode,
      'stableErrorCode',
      'is only valid for a failed outcome',
    );
  }
  return null;
}

String _safeIdentifier(String value, String name) {
  final normalized = _nonBlank(value, name);
  if (!RegExp(r'^[A-Za-z0-9][A-Za-z0-9._:-]{0,255}$').hasMatch(normalized)) {
    throw ArgumentError.value(value, name, 'must be an opaque identifier');
  }
  return normalized;
}

String _sha256(String value, String name) {
  final normalized = value.trim().toLowerCase();
  if (!RegExp(r'^sha256:[0-9a-f]{64}$').hasMatch(normalized)) {
    throw ArgumentError.value(value, name, 'must be a sha256 digest');
  }
  return normalized;
}

String _stableErrorCode(String? value, String name) {
  final normalized = _nonBlank(value, name);
  if (!RegExp(r'^[a-z][a-z0-9]*(?:[._-][a-z0-9]+)+$').hasMatch(normalized)) {
    throw ArgumentError.value(value, name, 'must be a stable error code');
  }
  return normalized;
}

String _nonBlank(String? value, String name) {
  final normalized = value?.trim();
  if (normalized == null || normalized.isEmpty) {
    throw ArgumentError.value(value, name, 'must not be blank');
  }
  return normalized;
}

Object? _canonicalize(Object? value) {
  if (value == null || value is bool || value is num || value is String) {
    return value;
  }
  if (value is List) {
    return value.map(_canonicalize).toList(growable: false);
  }
  if (value is Map) {
    final keys = value.keys.map((key) {
      if (key is! String) {
        throw ArgumentError.value(key, 'key', 'must be a string');
      }
      return key;
    }).toList()..sort();
    return <String, Object?>{
      for (final key in keys) key: _canonicalize(value[key]),
    };
  }
  throw ArgumentError.value(value, 'value', 'is not JSON-compatible');
}
