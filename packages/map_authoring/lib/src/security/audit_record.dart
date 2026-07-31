import '../contracts/action_descriptor.dart';
import 'authoring_permission.dart';
import 'output_redaction.dart';

enum AuthoringAuditDecision {
  denied('denied'),
  failed('failed'),
  succeeded('succeeded');

  const AuthoringAuditDecision(this.wireName);

  final String wireName;

  static AuthoringAuditDecision fromWireName(String value) {
    return AuthoringAuditDecision.values.firstWhere(
      (decision) => decision.wireName == value,
      orElse: () => throw const FormatException('Unknown audit decision.'),
    );
  }
}

final class AuthoringAuditRecord {
  AuthoringAuditRecord({
    required String auditId,
    required String actorId,
    required String projectId,
    required this.operation,
    required this.decision,
    required String requestId,
    required String actionId,
    required int actionVersion,
    required this.riskLevel,
    String? planId,
    String? receiptId,
    required String code,
    required DateTime timestamp,
    Map<String, Object?> details = const {},
    AuthoringOutputRedactor redactor = const AuthoringOutputRedactor(),
  })  : auditId = safeAuthoringSecurityIdentifier(auditId, 'auditId'),
        actorId = safeAuthoringSecurityIdentifier(actorId, 'actorId'),
        projectId = safeAuthoringSecurityIdentifier(projectId, 'projectId'),
        requestId = safeAuthoringSecurityIdentifier(requestId, 'requestId'),
        actionId = safeAuthoringSecurityIdentifier(actionId, 'actionId'),
        actionVersion = _positiveVersion(actionVersion),
        planId = planId == null
            ? null
            : safeAuthoringSecurityIdentifier(planId, 'planId'),
        receiptId = receiptId == null
            ? null
            : safeAuthoringSecurityIdentifier(receiptId, 'receiptId'),
        code = _safeCode(code),
        timestamp = timestamp.toUtc(),
        details = _redactedDetails(details, redactor);

  factory AuthoringAuditRecord.fromJson(Map<String, dynamic> json) {
    const keys = {
      'schemaVersion',
      'auditId',
      'actorId',
      'projectId',
      'operation',
      'decision',
      'requestId',
      'actionId',
      'actionVersion',
      'riskLevel',
      'planId',
      'receiptId',
      'code',
      'timestampUtc',
      'details',
    };
    if (json['schemaVersion'] != 1 ||
        json.keys.any((key) => !keys.contains(key)) ||
        json['details'] is! Map) {
      throw const FormatException('Invalid audit record schema.');
    }
    try {
      return AuthoringAuditRecord(
        auditId: _requiredString(json['auditId']),
        actorId: _requiredString(json['actorId']),
        projectId: _requiredString(json['projectId']),
        operation: AuthoringSecurityOperation.fromWireName(
          _requiredString(json['operation']),
        ),
        decision: AuthoringAuditDecision.fromWireName(
          _requiredString(json['decision']),
        ),
        requestId: _requiredString(json['requestId']),
        actionId: _requiredString(json['actionId']),
        actionVersion: _requiredInt(json['actionVersion']),
        riskLevel: AuthoringRiskLevel.fromWireName(
          _requiredString(json['riskLevel']),
        ),
        planId: _optionalString(json['planId']),
        receiptId: _optionalString(json['receiptId']),
        code: _requiredString(json['code']),
        timestamp: _requiredDate(json['timestampUtc']),
        details: Map<String, Object?>.from(json['details'] as Map),
      );
    } on ArgumentError catch (error) {
      throw FormatException(error.message.toString());
    }
  }

  final String auditId;
  final String actorId;
  final String projectId;
  final AuthoringSecurityOperation operation;
  final AuthoringAuditDecision decision;
  final String requestId;
  final String actionId;
  final int actionVersion;
  final AuthoringRiskLevel riskLevel;
  final String? planId;
  final String? receiptId;
  final String code;
  final DateTime timestamp;
  final Map<String, Object?> details;

  Map<String, Object?> toJson() => {
        'schemaVersion': 1,
        'auditId': auditId,
        'actorId': actorId,
        'projectId': projectId,
        'operation': operation.wireName,
        'decision': decision.wireName,
        'requestId': requestId,
        'actionId': actionId,
        'actionVersion': actionVersion,
        'riskLevel': riskLevel.wireName,
        if (planId != null) 'planId': planId,
        if (receiptId != null) 'receiptId': receiptId,
        'code': code,
        'timestampUtc': timestamp.toIso8601String(),
        'details': details,
      };
}

Map<String, Object?> _redactedDetails(
  Map<String, Object?> details,
  AuthoringOutputRedactor redactor,
) {
  final redacted = redactor.redact(details);
  if (redacted is! Map<String, Object?>) {
    throw ArgumentError.value(details, 'details', 'must be a JSON object');
  }
  return redacted;
}

String _safeCode(String value) {
  if (!RegExp(r'^[a-z][a-z0-9_.-]*$').hasMatch(value)) {
    throw ArgumentError.value(value, 'code', 'must be a stable safe code');
  }
  return value;
}

String _requiredString(Object? value) {
  if (value is! String || value.isEmpty) throw const FormatException();
  return value;
}

String? _optionalString(Object? value) {
  if (value == null) return null;
  return _requiredString(value);
}

int _requiredInt(Object? value) {
  if (value is! int) throw const FormatException();
  return value;
}

DateTime _requiredDate(Object? value) {
  if (value is! String) throw const FormatException();
  final parsed = DateTime.tryParse(value);
  if (parsed == null || !parsed.isUtc) throw const FormatException();
  return parsed;
}

int _positiveVersion(int value) {
  if (value <= 0) {
    throw ArgumentError.value(value, 'actionVersion', 'must be positive');
  }
  return value;
}
