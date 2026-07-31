import 'package:map_core/map_core.dart';

import '../../contracts/json_contract_support.dart';

enum AuthoringReadinessSeverity { error, warning, info }

final class ReadinessPlannedFix {
  ReadinessPlannedFix({
    required String actionId,
    required String reason,
    Map<String, Object?> parameters = const <String, Object?>{},
  })  : actionId = _nonBlank(actionId, 'actionId'),
        reason = _nonBlank(reason, 'reason'),
        parameters = freezeContractJsonObject(
          parameters,
          field: 'parameters',
        );

  final String actionId;
  final String reason;
  final Map<String, Object?> parameters;

  Map<String, Object?> toJson() => <String, Object?>{
        'actionId': actionId,
        'reason': reason,
        'parameters': parameters,
        'applyAutomatically': false,
      };
}

final class AuthoringReadinessDiagnostic {
  AuthoringReadinessDiagnostic({
    required String id,
    required this.severity,
    required String summary,
    required String evidenceRef,
    this.plannedFix,
  })  : id = _safeId(id, 'id'),
        summary = _nonBlank(summary, 'summary'),
        evidenceRef = _evidenceRef(evidenceRef);

  final String id;
  final AuthoringReadinessSeverity severity;
  final String summary;
  final String evidenceRef;
  final ReadinessPlannedFix? plannedFix;

  bool get isBlocking => severity != AuthoringReadinessSeverity.info;

  AuthoringReadinessDiagnostic withPlannedFix(ReadinessPlannedFix fix) =>
      AuthoringReadinessDiagnostic(
        id: id,
        severity: severity,
        summary: summary,
        evidenceRef: evidenceRef,
        plannedFix: fix,
      );

  Map<String, Object?> toJson() => <String, Object?>{
        'id': id,
        'severity': severity.name,
        'summary': summary,
        'evidenceRef': evidenceRef,
        if (plannedFix != null) 'plannedFix': plannedFix!.toJson(),
      };
}

abstract interface class ProjectReadinessValidatorPort {
  Future<List<AuthoringReadinessDiagnostic>> validate();
}

final class AuthoringProjectReadinessResult {
  AuthoringProjectReadinessResult(
    Iterable<AuthoringReadinessDiagnostic> diagnostics,
  ) : diagnostics = _sortedDiagnostics(diagnostics);

  final List<AuthoringReadinessDiagnostic> diagnostics;

  bool get isReady => diagnostics.every((diagnostic) => !diagnostic.isBlocking);

  List<ReadinessPlannedFix> get plannedFixes => List.unmodifiable(
        diagnostics
            .map((diagnostic) => diagnostic.plannedFix)
            .whereType<ReadinessPlannedFix>(),
      );

  Map<String, Object?> toJson() => <String, Object?>{
        'ready': isReady,
        'diagnostics': diagnostics.map((item) => item.toJson()).toList(),
        'fixesApplied': false,
      };
}

/// Aggregates independent validators and associates optional fix plans.
///
/// No method on this type can execute a mutation. Applying a planned action
/// still requires the normal Authoring API plan/confirm/apply workflow.
final class ProjectReadinessActions {
  ProjectReadinessActions({
    required Iterable<ProjectReadinessValidatorPort> validators,
  }) : _validators = List.unmodifiable(validators);

  final List<ProjectReadinessValidatorPort> _validators;

  Future<AuthoringProjectReadinessResult> evaluate({
    Map<String, ReadinessPlannedFix> plannedFixesByDiagnosticId =
        const <String, ReadinessPlannedFix>{},
  }) async {
    final diagnostics = <AuthoringReadinessDiagnostic>[];
    for (final validator in _validators) {
      diagnostics.addAll(await validator.validate());
    }
    final ids = <String>{};
    for (final diagnostic in diagnostics) {
      if (!ids.add(diagnostic.id)) {
        throw StateError('Duplicate readiness diagnostic: ${diagnostic.id}');
      }
    }
    final unknownFixes = plannedFixesByDiagnosticId.keys
        .where((id) => !ids.contains(id))
        .toList(growable: false);
    if (unknownFixes.isNotEmpty) {
      throw ArgumentError.value(
        unknownFixes,
        'plannedFixesByDiagnosticId',
        'fixes must target emitted diagnostics',
      );
    }
    return AuthoringProjectReadinessResult(
      diagnostics.map((diagnostic) {
        final fix = plannedFixesByDiagnosticId[diagnostic.id];
        if (fix == null || !diagnostic.isBlocking) return diagnostic;
        return diagnostic.withPlannedFix(fix);
      }),
    );
  }
}

typedef MapCoreReadinessReportLoader = Future<ProjectGameplayReadinessReport>
    Function();

/// Converts the canonical `map_core` FG-180 validator into Authoring API
/// diagnostics with stable, path-free evidence references.
final class MapCoreProjectReadinessAdapter
    implements ProjectReadinessValidatorPort {
  const MapCoreProjectReadinessAdapter(this._load);

  final MapCoreReadinessReportLoader _load;

  @override
  Future<List<AuthoringReadinessDiagnostic>> validate() async {
    final report = await _load();
    return List.unmodifiable(
      report.diagnostics.map(
        (diagnostic) => AuthoringReadinessDiagnostic(
          id: 'gameplay.${diagnostic.check.name}',
          severity: switch (diagnostic.severity) {
            ProjectGameplayReadinessSeverity.error =>
              AuthoringReadinessSeverity.error,
            ProjectGameplayReadinessSeverity.warning =>
              AuthoringReadinessSeverity.warning,
            ProjectGameplayReadinessSeverity.info =>
              AuthoringReadinessSeverity.info,
          },
          summary: diagnostic.summary,
          evidenceRef: 'validator://map_core/project_gameplay_readiness/'
              '${diagnostic.check.name}',
        ),
      ),
    );
  }
}

typedef MapCoreReleaseGateReportLoader = Future<MvpReleaseGateReport>
    Function();

/// Preserves the executed-vs-declared truth of the canonical FG-185 gate.
final class MapCoreMvpReleaseGateAdapter
    implements ProjectReadinessValidatorPort {
  const MapCoreMvpReleaseGateAdapter(this._load);

  final MapCoreReleaseGateReportLoader _load;

  @override
  Future<List<AuthoringReadinessDiagnostic>> validate() async {
    final report = await _load();
    return List.unmodifiable(
      MvpReleaseGateCriterion.values.map((criterion) {
        final evidence = report.evidenceByCriterion[criterion]!;
        final receipt = evidence.executionReceipt;
        final passed = evidence.evidenceKind ==
                MvpReleaseGateEvidenceKind.executedEvidence &&
            evidence.status == MvpReleaseGateEvidenceStatus.passed &&
            receipt != null &&
            receipt.exitCode == 0;
        return AuthoringReadinessDiagnostic(
          id: 'release.${criterion.name}',
          severity: passed
              ? AuthoringReadinessSeverity.info
              : AuthoringReadinessSeverity.error,
          summary: evidence.summary,
          evidenceRef: 'release-gate://map_core/${criterion.name}/'
              '${receipt?.outputDigestSha256 ?? 'unverified'}',
        );
      }),
    );
  }
}

List<AuthoringReadinessDiagnostic> _sortedDiagnostics(
  Iterable<AuthoringReadinessDiagnostic> diagnostics,
) {
  final result = diagnostics.toList()
    ..sort((left, right) => left.id.compareTo(right.id));
  return List.unmodifiable(result);
}

String _safeId(String value, String field) {
  final normalized = _nonBlank(value, field);
  if (!RegExp(r'^[a-z][A-Za-z0-9_.-]{2,127}$').hasMatch(normalized)) {
    throw ArgumentError.value(value, field, 'must be a stable identifier');
  }
  return normalized;
}

String _evidenceRef(String value) {
  final normalized = _nonBlank(value, 'evidenceRef');
  final uri = Uri.tryParse(normalized);
  if (uri == null || !uri.hasScheme || uri.scheme == 'file') {
    throw ArgumentError.value(
      value,
      'evidenceRef',
      'must be a stable non-file URI',
    );
  }
  return normalized;
}

String _nonBlank(String value, String field) {
  if (value.trim().isEmpty) {
    throw ArgumentError.value(value, field, 'must not be blank');
  }
  return value.trim();
}
