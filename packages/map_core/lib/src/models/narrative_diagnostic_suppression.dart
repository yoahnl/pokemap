import 'package:meta/meta.dart' show immutable;

const _sha256FingerprintPattern = r'^sha256:[0-9a-f]{64}$';

/// Auditable project-owned decision to hide one non-blocking diagnostic.
///
/// The fingerprint deliberately binds the decision to the diagnostic content.
/// A changed diagnostic therefore becomes stale instead of inheriting an old
/// suppression silently.
@immutable
final class NarrativeDiagnosticSuppression {
  NarrativeDiagnosticSuppression({
    this.schemaVersion = 1,
    required String diagnosticId,
    required String diagnosticFingerprint,
    required String reason,
    required String author,
    required DateTime createdAt,
    DateTime? expiresAt,
  })  : diagnosticId = _requiredText(diagnosticId, 'diagnosticId'),
        diagnosticFingerprint = _fingerprint(diagnosticFingerprint),
        reason = _requiredText(reason, 'reason'),
        author = _requiredText(author, 'author'),
        createdAt = createdAt.toUtc(),
        expiresAt = expiresAt?.toUtc() {
    if (schemaVersion != 1) {
      throw ArgumentError.value(schemaVersion, 'schemaVersion');
    }
    if (this.expiresAt case final expiration?
        when expiration.isBefore(this.createdAt)) {
      throw ArgumentError.value(
        expiresAt,
        'expiresAt',
        'must not precede createdAt',
      );
    }
  }

  factory NarrativeDiagnosticSuppression.fromJson(Map<String, dynamic> json) {
    final schemaVersion = json['schemaVersion'];
    final createdAt = json['createdAt'];
    final expiresAt = json['expiresAt'];
    if (schemaVersion is! int) {
      throw const FormatException('schemaVersion must be an integer.');
    }
    if (createdAt is! String) {
      throw const FormatException('createdAt must be an ISO-8601 string.');
    }
    if (expiresAt != null && expiresAt is! String) {
      throw const FormatException('expiresAt must be an ISO-8601 string.');
    }
    return NarrativeDiagnosticSuppression(
      schemaVersion: schemaVersion,
      diagnosticId: _jsonText(json, 'diagnosticId'),
      diagnosticFingerprint: _jsonText(json, 'diagnosticFingerprint'),
      reason: _jsonText(json, 'reason'),
      author: _jsonText(json, 'author'),
      createdAt: DateTime.parse(createdAt),
      expiresAt: expiresAt == null ? null : DateTime.parse(expiresAt),
    );
  }

  final int schemaVersion;
  final String diagnosticId;
  final String diagnosticFingerprint;
  final String reason;
  final String author;
  final DateTime createdAt;
  final DateTime? expiresAt;

  bool isExpiredAt(DateTime instant) {
    final expiration = expiresAt;
    return expiration != null && !instant.toUtc().isBefore(expiration);
  }

  Map<String, dynamic> toJson() => {
        'schemaVersion': schemaVersion,
        'diagnosticId': diagnosticId,
        'diagnosticFingerprint': diagnosticFingerprint,
        'reason': reason,
        'author': author,
        'createdAt': createdAt.toIso8601String(),
        if (expiresAt != null) 'expiresAt': expiresAt!.toIso8601String(),
      };
}

String _jsonText(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is! String) throw FormatException('$key must be a string.');
  return value;
}

String _requiredText(String value, String name) {
  final normalized = value.trim();
  if (normalized.isEmpty) throw ArgumentError.value(value, name);
  return normalized;
}

String _fingerprint(String value) {
  final normalized = value.trim();
  if (!RegExp(_sha256FingerprintPattern).hasMatch(normalized)) {
    throw ArgumentError.value(
      value,
      'diagnosticFingerprint',
      'must be a lowercase sha256 fingerprint',
    );
  }
  return normalized;
}
