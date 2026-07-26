import 'narrative_command_catalog.dart';

enum ProjectCapabilityTruthStatus { promoted, deferred }

enum ProjectCapabilityTruthIssueCode {
  duplicateCapabilityId,
  missingCapabilityId,
  missingExpectedCapability,
  unexpectedCapability,
  noPromotedCapabilities,
  missingAuthoringControl,
  missingContractField,
  missingRuntimeConsumer,
  missingPlayerSurface,
  missingPositiveTest,
  missingNegativeTest,
  missingDeferredReason,
}

final class ProjectCapabilityTruthAttestation {
  ProjectCapabilityTruthAttestation({
    required Map<String, String> referencesByCapabilityId,
  }) : referencesByCapabilityId = Map.unmodifiable(referencesByCapabilityId);

  final Map<String, String> referencesByCapabilityId;

  String referenceFor(String capabilityId) =>
      referencesByCapabilityId[capabilityId] ?? '';
}

final class ProjectCapabilityTruthRecord {
  const ProjectCapabilityTruthRecord.promoted({
    required this.capabilityId,
    required this.authoringControl,
    required this.contractField,
    required this.runtimeConsumer,
    required this.playerSurface,
    required this.positiveTest,
    required this.negativeTest,
  })  : status = ProjectCapabilityTruthStatus.promoted,
        reason = null;

  const ProjectCapabilityTruthRecord.deferred({
    required this.capabilityId,
    required this.reason,
  })  : status = ProjectCapabilityTruthStatus.deferred,
        authoringControl = null,
        contractField = null,
        runtimeConsumer = null,
        playerSurface = null,
        positiveTest = null,
        negativeTest = null;

  final String capabilityId;
  final String? authoringControl;
  final String? contractField;
  final String? runtimeConsumer;
  final String? playerSurface;
  final String? positiveTest;
  final String? negativeTest;
  final ProjectCapabilityTruthStatus status;
  final String? reason;

  Map<String, Object?> toJson() => {
        'capabilityId': capabilityId,
        'authoringControl': authoringControl,
        'contractField': contractField,
        'runtimeConsumer': runtimeConsumer,
        'playerSurface': playerSurface,
        'positiveTest': positiveTest,
        'negativeTest': negativeTest,
        'status': status.name,
        'reason': reason,
      };
}

final class ProjectCapabilityTruthIssue {
  const ProjectCapabilityTruthIssue({
    required this.code,
    required this.capabilityId,
    required this.message,
  });

  final ProjectCapabilityTruthIssueCode code;
  final String capabilityId;
  final String message;

  Map<String, Object?> toJson() => {
        'code': code.name,
        'capabilityId': capabilityId,
        'message': message,
      };
}

final class ProjectCapabilityTruthReport {
  ProjectCapabilityTruthReport._({
    required List<ProjectCapabilityTruthRecord> capabilities,
    required List<ProjectCapabilityTruthIssue> issues,
  })  : capabilities = List.unmodifiable(capabilities),
        issues = List.unmodifiable(issues);

  factory ProjectCapabilityTruthReport.evaluate(
    Iterable<ProjectCapabilityTruthRecord> records, {
    required Set<String> requiredCapabilityIds,
  }) {
    final capabilities = records.toList()
      ..sort(
        (left, right) => left.capabilityId.compareTo(right.capabilityId),
      );
    final issues = <ProjectCapabilityTruthIssue>[];
    final countsById = <String, int>{};
    final normalizedRequiredIds = {
      for (final capabilityId in requiredCapabilityIds)
        if (capabilityId.trim().isNotEmpty) capabilityId.trim(),
    };
    for (final record in capabilities) {
      countsById.update(
        record.capabilityId,
        (count) => count + 1,
        ifAbsent: () => 1,
      );
      if (record.capabilityId.trim().isEmpty) {
        issues.add(
          const ProjectCapabilityTruthIssue(
            code: ProjectCapabilityTruthIssueCode.missingCapabilityId,
            capabilityId: '',
            message: 'Capability ID is required.',
          ),
        );
      }
      if (record.status == ProjectCapabilityTruthStatus.deferred) {
        if (_isBlank(record.reason)) {
          issues.add(
            ProjectCapabilityTruthIssue(
              code: ProjectCapabilityTruthIssueCode.missingDeferredReason,
              capabilityId: record.capabilityId,
              message: 'A deferred capability requires a reason.',
            ),
          );
        }
        continue;
      }
      _requireReference(
        issues,
        record,
        value: record.authoringControl,
        code: ProjectCapabilityTruthIssueCode.missingAuthoringControl,
        label: 'authoring control',
      );
      _requireReference(
        issues,
        record,
        value: record.contractField,
        code: ProjectCapabilityTruthIssueCode.missingContractField,
        label: 'contract field',
      );
      _requireReference(
        issues,
        record,
        value: record.runtimeConsumer,
        code: ProjectCapabilityTruthIssueCode.missingRuntimeConsumer,
        label: 'runtime consumer',
      );
      _requireReference(
        issues,
        record,
        value: record.playerSurface,
        code: ProjectCapabilityTruthIssueCode.missingPlayerSurface,
        label: 'player surface',
      );
      _requireReference(
        issues,
        record,
        value: record.positiveTest,
        code: ProjectCapabilityTruthIssueCode.missingPositiveTest,
        label: 'positive test',
      );
      _requireReference(
        issues,
        record,
        value: record.negativeTest,
        code: ProjectCapabilityTruthIssueCode.missingNegativeTest,
        label: 'negative test',
      );
    }
    for (final entry in countsById.entries) {
      if (entry.value < 2) continue;
      issues.add(
        ProjectCapabilityTruthIssue(
          code: ProjectCapabilityTruthIssueCode.duplicateCapabilityId,
          capabilityId: entry.key,
          message: 'Capability ${entry.key} is declared ${entry.value} times.',
        ),
      );
    }
    for (final capabilityId in normalizedRequiredIds) {
      if (countsById.containsKey(capabilityId)) continue;
      issues.add(
        ProjectCapabilityTruthIssue(
          code: ProjectCapabilityTruthIssueCode.missingExpectedCapability,
          capabilityId: capabilityId,
          message: 'Required capability $capabilityId is not declared.',
        ),
      );
    }
    for (final capabilityId in countsById.keys) {
      if (normalizedRequiredIds.contains(capabilityId)) continue;
      issues.add(
        ProjectCapabilityTruthIssue(
          code: ProjectCapabilityTruthIssueCode.unexpectedCapability,
          capabilityId: capabilityId,
          message: 'Capability $capabilityId is outside the required set.',
        ),
      );
    }
    if (normalizedRequiredIds.isEmpty ||
        !capabilities.any(
          (record) => record.status == ProjectCapabilityTruthStatus.promoted,
        )) {
      issues.add(
        const ProjectCapabilityTruthIssue(
          code: ProjectCapabilityTruthIssueCode.noPromotedCapabilities,
          capabilityId: '*',
          message:
              'A capability truth gate requires at least one promoted capability.',
        ),
      );
    }
    issues.sort((left, right) {
      final capability = left.capabilityId.compareTo(right.capabilityId);
      return capability != 0
          ? capability
          : left.code.name.compareTo(right.code.name);
    });
    return ProjectCapabilityTruthReport._(
      capabilities: capabilities,
      issues: issues,
    );
  }

  final List<ProjectCapabilityTruthRecord> capabilities;
  final List<ProjectCapabilityTruthIssue> issues;

  bool get isPassing => issues.isEmpty;

  Map<String, Object?> toJson() => {
        'schemaVersion': 1,
        'status': isPassing ? 'pass' : 'fail',
        'capabilities': [
          for (final capability in capabilities) capability.toJson(),
        ],
        'issues': [for (final issue in issues) issue.toJson()],
      };

  String get agentMarkdown {
    final buffer = StringBuffer()
      ..writeln('# Project Capability Truth')
      ..writeln()
      ..writeln('| Capability | Status | Runtime | Positive | Negative |')
      ..writeln('|---|---|---|---|---|');
    for (final capability in capabilities) {
      buffer.writeln(
        '| `${capability.capabilityId}` | `${capability.status.name}` | '
        '${_cell(capability.runtimeConsumer)} | '
        '${_cell(capability.positiveTest)} | '
        '${_cell(capability.negativeTest)} |',
      );
    }
    if (issues.isNotEmpty) {
      buffer
        ..writeln()
        ..writeln('## Blocking issues');
      for (final issue in issues) {
        buffer.writeln(
          '- `${issue.code.name}` · `${issue.capabilityId}` · ${issue.message}',
        );
      }
    }
    return buffer.toString().trimRight();
  }
}

List<ProjectCapabilityTruthRecord> buildNarrativeCommandCapabilityTruthMatrix({
  NarrativeCommandCatalog? catalog,
  required ProjectCapabilityTruthAttestation authoring,
  required ProjectCapabilityTruthAttestation runtime,
  required ProjectCapabilityTruthAttestation playerSurface,
  required ProjectCapabilityTruthAttestation positiveTests,
  required ProjectCapabilityTruthAttestation negativeTests,
}) {
  final resolvedCatalog = catalog ?? NarrativeCommandCatalog.canonical();
  return List.unmodifiable([
    for (final command in resolvedCatalog.commands)
      if (command.isPublishable)
        ProjectCapabilityTruthRecord.promoted(
          capabilityId: narrativeCommandCapabilityId(command.id),
          authoringControl: authoring.referenceFor(command.id),
          contractField: command.wireId,
          runtimeConsumer: runtime.referenceFor(command.id),
          playerSurface: playerSurface.referenceFor(command.id),
          positiveTest: positiveTests.referenceFor(command.id),
          negativeTest: negativeTests.referenceFor(command.id),
        )
      else
        ProjectCapabilityTruthRecord.deferred(
          capabilityId: narrativeCommandCapabilityId(command.id),
          reason: command.capabilities.reason ??
              'The command is not supported across every required layer.',
        ),
  ]);
}

String narrativeCommandCapabilityId(String commandId) =>
    'narrative.command.$commandId';

Set<String> requiredNarrativeCommandCapabilityIds({
  NarrativeCommandCatalog? catalog,
}) =>
    Set.unmodifiable(
      (catalog ?? NarrativeCommandCatalog.canonical())
          .commands
          .map((command) => narrativeCommandCapabilityId(command.id)),
    );

void _requireReference(
  List<ProjectCapabilityTruthIssue> target,
  ProjectCapabilityTruthRecord record, {
  required String? value,
  required ProjectCapabilityTruthIssueCode code,
  required String label,
}) {
  if (!_isBlank(value)) return;
  target.add(
    ProjectCapabilityTruthIssue(
      code: code,
      capabilityId: record.capabilityId,
      message: 'Promoted capability requires a $label reference.',
    ),
  );
}

bool _isBlank(String? value) => value == null || value.trim().isEmpty;

String _cell(String? value) =>
    (value == null || value.trim().isEmpty ? '—' : value)
        .replaceAll('|', r'\|')
        .replaceAll('\n', ' ');
