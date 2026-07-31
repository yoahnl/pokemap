import 'package:map_core/map_core.dart';

/// JSON-safe projection of one explicit capability attestation.
final class AuthoringCapabilityTruthRecord {
  const AuthoringCapabilityTruthRecord({
    required this.capabilityId,
    required this.authoringControl,
    required this.contractField,
    required this.runtimeConsumer,
    required this.playerSurface,
    required this.positiveTest,
    required this.negativeTest,
    required this.status,
    required this.reason,
  });

  factory AuthoringCapabilityTruthRecord.fromCore(
    ProjectCapabilityTruthRecord record,
  ) {
    return AuthoringCapabilityTruthRecord(
      capabilityId: record.capabilityId,
      authoringControl: record.authoringControl,
      contractField: record.contractField,
      runtimeConsumer: record.runtimeConsumer,
      playerSurface: record.playerSurface,
      positiveTest: record.positiveTest,
      negativeTest: record.negativeTest,
      status: record.status.name,
      reason: record.reason,
    );
  }

  final String capabilityId;
  final String? authoringControl;
  final String? contractField;
  final String? runtimeConsumer;
  final String? playerSurface;
  final String? positiveTest;
  final String? negativeTest;
  final String status;
  final String? reason;

  Map<String, Object?> toJson() => {
        'capabilityId': capabilityId,
        'authoringControl': authoringControl,
        'contractField': contractField,
        'runtimeConsumer': runtimeConsumer,
        'playerSurface': playerSurface,
        'positiveTest': positiveTest,
        'negativeTest': negativeTest,
        'status': status,
        'reason': reason,
      };
}

/// JSON-safe projection of one coded capability-truth issue.
final class AuthoringCapabilityTruthIssue {
  const AuthoringCapabilityTruthIssue({
    required this.code,
    required this.capabilityId,
    required this.message,
  });

  factory AuthoringCapabilityTruthIssue.fromCore(
    ProjectCapabilityTruthIssue issue,
  ) {
    return AuthoringCapabilityTruthIssue(
      code: issue.code.name,
      capabilityId: issue.capabilityId,
      message: issue.message,
    );
  }

  final String code;
  final String capabilityId;
  final String message;

  Map<String, Object?> toJson() => {
        'code': code,
        'capabilityId': capabilityId,
        'message': message,
      };
}

/// Immutable authoring view of the fail-closed capability truth gate.
final class AuthoringCapabilityTruthReport {
  AuthoringCapabilityTruthReport._({
    required this.isPassing,
    required Iterable<AuthoringCapabilityTruthRecord> capabilities,
    required Iterable<AuthoringCapabilityTruthIssue> issues,
  })  : capabilities = List.unmodifiable(capabilities),
        issues = List.unmodifiable(issues);

  factory AuthoringCapabilityTruthReport.fromCore(
    ProjectCapabilityTruthReport report,
  ) {
    return AuthoringCapabilityTruthReport._(
      isPassing: report.isPassing,
      capabilities: report.capabilities.map(
        AuthoringCapabilityTruthRecord.fromCore,
      ),
      issues: report.issues.map(AuthoringCapabilityTruthIssue.fromCore),
    );
  }

  final bool isPassing;
  final List<AuthoringCapabilityTruthRecord> capabilities;
  final List<AuthoringCapabilityTruthIssue> issues;

  Map<String, Object?> toJson() => {
        'schemaVersion': 1,
        'status': isPassing ? 'pass' : 'fail',
        'capabilities': capabilities
            .map((capability) => capability.toJson())
            .toList(growable: false),
        'issues': issues.map((issue) => issue.toJson()).toList(growable: false),
      };
}

/// Adapts explicit truth records without inferring support from project data.
///
/// Deliberately no overload accepts a [ProjectManifest]: model presence is not
/// proof of an authoring control, runtime consumer, player surface, or tests.
abstract final class ProjectCapabilityTruthAdapter {
  static AuthoringCapabilityTruthReport evaluate({
    required Iterable<ProjectCapabilityTruthRecord> records,
    required Set<String> requiredCapabilityIds,
  }) {
    final report = ProjectCapabilityTruthReport.evaluate(
      records,
      requiredCapabilityIds: requiredCapabilityIds,
    );
    return AuthoringCapabilityTruthReport.fromCore(report);
  }
}
