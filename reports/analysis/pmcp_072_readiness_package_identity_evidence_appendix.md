# PMCP-072 — Annexe des fichiers créés

Cette annexe reproduit intégralement les fichiers créés par le lot.

## `packages/map_authoring/lib/src/domains/project/readiness_actions.dart`

```dart
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
```

## `packages/map_authoring/lib/src/domains/distribution/package_actions.dart`

```dart
import '../../contracts/authoring_receipt.dart';

final class PackageBuildRequest {
  PackageBuildRequest({
    required String requestId,
    required String packageId,
    required String projectId,
    required String sourceRevision,
    required String releaseVersion,
  })  : requestId = _safeId(requestId, 'requestId'),
        packageId = _safeId(packageId, 'packageId'),
        projectId = _safeId(projectId, 'projectId'),
        sourceRevision = _digest(sourceRevision, 'sourceRevision'),
        releaseVersion = _nonBlank(releaseVersion, 'releaseVersion');

  final String requestId;
  final String packageId;
  final String projectId;
  final String sourceRevision;
  final String releaseVersion;

  Map<String, Object?> toJson() => <String, Object?>{
        'requestId': requestId,
        'packageId': packageId,
        'projectId': projectId,
        'sourceRevision': sourceRevision,
        'releaseVersion': releaseVersion,
      };
}

final class PackageBuildEvidence {
  PackageBuildEvidence({
    required this.request,
    required this.artifact,
    required String treeDigest,
    required String evidenceRef,
  })  : treeDigest = _digest(treeDigest, 'treeDigest'),
        evidenceRef = _evidenceRef(evidenceRef) {
    _artifactDigest(artifact, 'artifact');
  }

  final PackageBuildRequest request;
  final AuthoringArtifactRef artifact;
  final String treeDigest;
  final String evidenceRef;

  String get packageDigest => _artifactDigest(artifact, 'artifact');
}

final class PackageInspectionEvidence {
  PackageInspectionEvidence({
    required this.artifact,
    required String treeDigest,
    required this.passed,
    required String evidenceRef,
  })  : treeDigest = _digest(treeDigest, 'treeDigest'),
        evidenceRef = _evidenceRef(evidenceRef) {
    _artifactDigest(artifact, 'artifact');
  }

  final AuthoringArtifactRef artifact;
  final String treeDigest;
  final bool passed;
  final String evidenceRef;

  String get packageDigest => _artifactDigest(artifact, 'artifact');
}

final class PackageInstallEvidence {
  PackageInstallEvidence({
    required String exportedDigest,
    required String installedDigest,
    required this.passed,
    required String evidenceRef,
  })  : exportedDigest = _digest(exportedDigest, 'exportedDigest'),
        installedDigest = _digest(installedDigest, 'installedDigest'),
        evidenceRef = _evidenceRef(evidenceRef);

  final String exportedDigest;
  final String installedDigest;
  final bool passed;
  final String evidenceRef;
}

abstract interface class AuthoringPackagePort {
  Future<PackageBuildEvidence> build(PackageBuildRequest request);

  Future<PackageInspectionEvidence> inspect(
    AuthoringArtifactRef package,
  );

  Future<PackageInstallEvidence> install(
    AuthoringArtifactRef package,
  );
}

final class PackageReleaseGateEvidence {
  PackageReleaseGateEvidence({
    required String id,
    required this.passed,
    required String summary,
    required String evidenceRef,
  })  : id = _safeId(id, 'id'),
        summary = _nonBlank(summary, 'summary'),
        evidenceRef = _evidenceRef(evidenceRef);

  final String id;
  final bool passed;
  final String summary;
  final String evidenceRef;

  Map<String, Object?> toJson() => <String, Object?>{
        'id': id,
        'passed': passed,
        'summary': summary,
        'evidenceRef': evidenceRef,
      };
}

final class GameplayLotReleaseMapping {
  GameplayLotReleaseMapping({
    required String lotId,
    required String status,
  })  : lotId = _lotId(lotId),
        status = _lotStatus(status);

  final String lotId;
  final String status;

  /// Roadmap writes are intentionally outside this release action.
  bool get updateApplied => false;

  Map<String, Object?> toJson() => <String, Object?>{
        'lotId': lotId,
        'status': status,
        'updateApplied': false,
      };
}

final class AuthoringPackageReleaseReceipt {
  AuthoringPackageReleaseReceipt({
    required String requestId,
    required String projectId,
    required String sourceRevision,
    required String packageDigest,
    required String installedDigest,
    required Iterable<PackageReleaseGateEvidence> gates,
    required Iterable<GameplayLotReleaseMapping> gameplayLots,
  })  : requestId = _safeId(requestId, 'requestId'),
        projectId = _safeId(projectId, 'projectId'),
        sourceRevision = _digest(sourceRevision, 'sourceRevision'),
        packageDigest = _digest(packageDigest, 'packageDigest'),
        installedDigest = _digest(installedDigest, 'installedDigest'),
        gates = _sortedGates(gates),
        gameplayLots = _sortedLots(gameplayLots);

  final String requestId;
  final String projectId;
  final String sourceRevision;
  final String packageDigest;
  final String installedDigest;
  final List<PackageReleaseGateEvidence> gates;
  final List<GameplayLotReleaseMapping> gameplayLots;

  bool get isReady =>
      packageDigest == installedDigest && gates.every((gate) => gate.passed);

  Map<String, Object?> toJson() => <String, Object?>{
        'requestId': requestId,
        'projectId': projectId,
        'sourceRevision': sourceRevision,
        'packageDigest': packageDigest,
        'installedDigest': installedDigest,
        'ready': isReady,
        'gates': gates.map((gate) => gate.toJson()).toList(),
        'gameplayLots': gameplayLots.map((lot) => lot.toJson()).toList(),
      };
}

/// Orchestrates the public build/inspect/install sequence and fails closed in
/// its release receipt. The concrete adapter remains the byte authority.
final class DistributionPackageActions {
  const DistributionPackageActions({required AuthoringPackagePort port})
      : _port = port;

  final AuthoringPackagePort _port;

  Future<PackageBuildEvidence> build(PackageBuildRequest request) =>
      _port.build(request);

  Future<PackageInspectionEvidence> inspect(
    AuthoringArtifactRef package,
  ) =>
      _port.inspect(package);

  Future<PackageInstallEvidence> verify(
    AuthoringArtifactRef package,
  ) =>
      _port.install(package);

  Future<AuthoringPackageReleaseReceipt> release({
    required PackageBuildRequest request,
    required Iterable<PackageReleaseGateEvidence> regressionGates,
    required Iterable<GameplayLotReleaseMapping> gameplayLots,
  }) async {
    final built = await build(request);
    final inspection = await inspect(built.artifact);
    final sameTree = built.treeDigest == inspection.treeDigest;
    final installation = inspection.passed && sameTree
        ? await verify(built.artifact)
        : PackageInstallEvidence(
            exportedDigest: built.packageDigest,
            installedDigest: 'sha256:${'0' * 64}',
            passed: false,
            evidenceRef: inspection.evidenceRef,
          );
    final sameBytes = built.packageDigest == inspection.packageDigest &&
        built.packageDigest == installation.exportedDigest &&
        built.packageDigest == installation.installedDigest;
    return AuthoringPackageReleaseReceipt(
      requestId: request.requestId,
      projectId: request.projectId,
      sourceRevision: request.sourceRevision,
      packageDigest: built.packageDigest,
      installedDigest: installation.installedDigest,
      gates: <PackageReleaseGateEvidence>[
        PackageReleaseGateEvidence(
          id: 'package.build',
          passed: true,
          summary: 'Deterministic package bytes were built.',
          evidenceRef: built.evidenceRef,
        ),
        PackageReleaseGateEvidence(
          id: 'package.inspect',
          passed: inspection.passed && sameTree,
          summary: sameTree
              ? 'Package inspection preserved the content-tree identity.'
              : 'Package inspection reported a different content tree.',
          evidenceRef: inspection.evidenceRef,
        ),
        PackageReleaseGateEvidence(
          id: 'package.byte-identity',
          passed: installation.passed && sameBytes,
          summary: sameBytes
              ? 'Exported and installed package bytes are identical.'
              : 'Exported and installed package bytes differ.',
          evidenceRef: installation.evidenceRef,
        ),
        ...regressionGates,
      ],
      gameplayLots: gameplayLots,
    );
  }
}

List<PackageReleaseGateEvidence> _sortedGates(
  Iterable<PackageReleaseGateEvidence> gates,
) {
  final result = gates.toList()..sort((a, b) => a.id.compareTo(b.id));
  if (result.isEmpty) {
    throw ArgumentError.value(gates, 'gates', 'must not be empty');
  }
  for (var index = 1; index < result.length; index += 1) {
    if (result[index - 1].id == result[index].id) {
      throw ArgumentError.value(result[index].id, 'gates', 'duplicate gate');
    }
  }
  return List.unmodifiable(result);
}

List<GameplayLotReleaseMapping> _sortedLots(
  Iterable<GameplayLotReleaseMapping> mappings,
) {
  final result = mappings.toList()..sort((a, b) => a.lotId.compareTo(b.lotId));
  for (var index = 1; index < result.length; index += 1) {
    if (result[index - 1].lotId == result[index].lotId) {
      throw ArgumentError.value(
        result[index].lotId,
        'gameplayLots',
        'duplicate lot',
      );
    }
  }
  return List.unmodifiable(result);
}

String _lotId(String value) {
  final normalized = _nonBlank(value, 'lotId');
  if (!RegExp(r'^FG-[0-9]{3}$').hasMatch(normalized)) {
    throw ArgumentError.value(value, 'lotId', 'must match FG-NNN');
  }
  return normalized;
}

String _lotStatus(String value) {
  final normalized = _nonBlank(value, 'status');
  if (!const <String>{'TODO', 'PARTIAL', 'BLOCKED', 'DONE'}
      .contains(normalized)) {
    throw ArgumentError.value(value, 'status', 'unknown roadmap status');
  }
  return normalized;
}

String _digest(String value, String field) {
  if (!RegExp(r'^sha256:[0-9a-f]{64}$').hasMatch(value)) {
    throw ArgumentError.value(value, field, 'must be a SHA-256 digest');
  }
  return value;
}

String _artifactDigest(AuthoringArtifactRef artifact, String field) {
  final sha256 = artifact.sha256;
  if (sha256 == null) {
    throw ArgumentError.value(artifact, field, 'must contain a SHA-256');
  }
  final digest = 'sha256:$sha256';
  _digest(digest, field);
  if (artifact.uri != 'artifact://sha256/$sha256') {
    throw ArgumentError.value(
      artifact.uri,
      field,
      'artifact URI must match its SHA-256',
    );
  }
  return digest;
}

String _safeId(String value, String field) {
  final normalized = _nonBlank(value, field);
  if (!RegExp(r'^[A-Za-z0-9][A-Za-z0-9_.-]{2,127}$').hasMatch(normalized)) {
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
```

## `packages/map_authoring/test/domains/project/readiness_actions_test.dart`

```dart
import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  test('readiness aggregates validators and only plans cited fixes', () async {
    final coreReport = ProjectGameplayReadinessReport.evaluate(
      <ProjectGameplayReadinessEvidence>[
        for (final check in ProjectGameplayReadinessCheck.values)
          ProjectGameplayReadinessEvidence(
            check: check,
            status: check == ProjectGameplayReadinessCheck.shopItems
                ? ProjectGameplayReadinessEvidenceStatus.failed
                : ProjectGameplayReadinessEvidenceStatus.passed,
            summary: check == ProjectGameplayReadinessCheck.shopItems
                ? 'No sellable item is reachable.'
                : '${check.name} is covered.',
            source: 'validator://fixture/${check.name}',
          ),
      ],
    );
    final actions = ProjectReadinessActions(
      validators: <ProjectReadinessValidatorPort>[
        MapCoreProjectReadinessAdapter(() async => coreReport),
        MapCoreMvpReleaseGateAdapter(() async => _releaseGateReport()),
      ],
    );

    final result = await actions.evaluate(
      plannedFixesByDiagnosticId: <String, ReadinessPlannedFix>{
        'gameplay.shopItems': ReadinessPlannedFix(
          actionId: 'shop.upsert',
          reason: 'Add one reachable shop inventory entry.',
          parameters: <String, Object?>{
            'shopId': 'shop.golden',
            'itemId': 'potion',
          },
        ),
      },
    );

    expect(result.isReady, isFalse);
    expect(
      result.diagnostics,
      everyElement(
        isA<AuthoringReadinessDiagnostic>().having(
          (item) => item.evidenceRef,
          'evidenceRef',
          isNotEmpty,
        ),
      ),
    );
    expect(result.plannedFixes, hasLength(1));
    expect(result.plannedFixes.single.actionId, 'shop.upsert');
    expect(
      result.diagnostics
          .singleWhere((item) => item.id == 'gameplay.shopItems')
          .plannedFix,
      isNotNull,
    );
    expect(
      result.diagnostics
          .singleWhere((item) => item.id == 'release.criticalPackageTests')
          .plannedFix,
      isNull,
    );
  });

  test('readiness rejects diagnostics without stable evidence', () {
    expect(
      () => AuthoringReadinessDiagnostic(
        id: 'release.invalid',
        severity: AuthoringReadinessSeverity.error,
        summary: 'Missing source.',
        evidenceRef: ' ',
      ),
      throwsArgumentError,
    );
  });
}

MvpReleaseGateReport _releaseGateReport() => MvpReleaseGateReport.evaluate(
      MvpReleaseGateCriterion.values.map(
        (criterion) => MvpReleaseGateEvidence.fromExecutionReceipt(
          MvpReleaseGateExecutionReceipt.validated(
            criterion: criterion,
            summary: '${criterion.name} passed.',
            source: 'test://release/${criterion.name}',
            releaseCandidateCommit: 'a' * 40,
            command: 'test ${criterion.name}',
            exitCode: 0,
            outputDigestSha256: 'b' * 64,
          ),
        ),
      ),
    );
```

## `packages/map_authoring/test/domains/distribution/package_actions_test.dart`

```dart
import 'package:map_authoring/map_authoring.dart';
import 'package:test/test.dart';

void main() {
  test('release runs build inspect install and binds identical digests',
      () async {
    final port = _FakePackagePort(installedDigest: _digest('a'));
    final actions = DistributionPackageActions(port: port);

    final receipt = await actions.release(
      request: PackageBuildRequest(
        requestId: 'request-072',
        packageId: 'golden-slice',
        projectId: 'golden-project',
        sourceRevision: _digest('b'),
        releaseVersion: '1.0.0',
      ),
      regressionGates: <PackageReleaseGateEvidence>[
        PackageReleaseGateEvidence(
          id: 'runtime.golden-slice',
          passed: true,
          summary: 'Production runtime reached the expected map.',
          evidenceRef: 'test://runtime/golden-slice',
        ),
        PackageReleaseGateEvidence(
          id: 'regression.matrix',
          passed: true,
          summary: 'The scoped matrix passed.',
          evidenceRef: 'test://release/regression-matrix',
        ),
      ],
      gameplayLots: <GameplayLotReleaseMapping>[
        GameplayLotReleaseMapping(lotId: 'FG-180', status: 'DONE'),
        GameplayLotReleaseMapping(lotId: 'FG-185', status: 'PARTIAL'),
      ],
    );

    expect(port.calls, <String>['build', 'inspect', 'install']);
    expect(receipt.isReady, isTrue);
    expect(receipt.sourceRevision, _digest('b'));
    expect(receipt.packageDigest, _digest('a'));
    expect(receipt.installedDigest, receipt.packageDigest);
    expect(receipt.gates, everyElement(hasEvidence));
    expect(
      receipt.gameplayLots.map((item) => item.updateApplied),
      everyElement(isFalse),
    );
  });

  test('release fails closed when installed bytes differ', () async {
    final port = _FakePackagePort(installedDigest: _digest('c'));

    final receipt = await DistributionPackageActions(port: port).release(
      request: PackageBuildRequest(
        requestId: 'request-mismatch',
        packageId: 'golden-slice',
        projectId: 'golden-project',
        sourceRevision: _digest('b'),
        releaseVersion: '1.0.0',
      ),
      regressionGates: <PackageReleaseGateEvidence>[],
      gameplayLots: <GameplayLotReleaseMapping>[],
    );

    expect(receipt.isReady, isFalse);
    expect(
      receipt.gates.singleWhere((gate) => gate.id == 'package.byte-identity'),
      isA<PackageReleaseGateEvidence>()
          .having((gate) => gate.passed, 'passed', isFalse)
          .having((gate) => gate.evidenceRef, 'evidenceRef', isNotEmpty),
    );
  });

  test('release never installs a package rejected by inspection', () async {
    final port = _FakePackagePort(
      installedDigest: _digest('a'),
      inspectionPassed: false,
    );

    final receipt = await DistributionPackageActions(port: port).release(
      request: PackageBuildRequest(
        requestId: 'request-rejected',
        packageId: 'golden-slice',
        projectId: 'golden-project',
        sourceRevision: _digest('b'),
        releaseVersion: '1.0.0',
      ),
      regressionGates: <PackageReleaseGateEvidence>[],
      gameplayLots: <GameplayLotReleaseMapping>[],
    );

    expect(port.calls, <String>['build', 'inspect']);
    expect(receipt.isReady, isFalse);
    expect(
      receipt.gates.singleWhere((gate) => gate.id == 'package.inspect').passed,
      isFalse,
    );
  });
}

Matcher get hasEvidence => isA<PackageReleaseGateEvidence>()
    .having((gate) => gate.evidenceRef, 'evidenceRef', isNotEmpty);

String _digest(String character) => 'sha256:${character * 64}';

final class _FakePackagePort implements AuthoringPackagePort {
  _FakePackagePort({
    required this.installedDigest,
    this.inspectionPassed = true,
  });

  final String installedDigest;
  final bool inspectionPassed;
  final List<String> calls = <String>[];

  AuthoringArtifactRef get artifact => AuthoringArtifactRef(
        id: 'package-golden',
        mediaType: 'application/vnd.pokemap.game+zip',
        uri: 'artifact://sha256/${'a' * 64}',
        byteLength: 128,
        sha256: 'a' * 64,
      );

  @override
  Future<PackageBuildEvidence> build(PackageBuildRequest request) async {
    calls.add('build');
    return PackageBuildEvidence(
      request: request,
      artifact: artifact,
      treeDigest: _digest('d'),
      evidenceRef: 'build://golden/${artifact.sha256}',
    );
  }

  @override
  Future<PackageInspectionEvidence> inspect(
    AuthoringArtifactRef package,
  ) async {
    calls.add('inspect');
    return PackageInspectionEvidence(
      artifact: package,
      treeDigest: _digest('d'),
      passed: inspectionPassed,
      evidenceRef: 'inspection://golden/${package.sha256}',
    );
  }

  @override
  Future<PackageInstallEvidence> install(
    AuthoringArtifactRef package,
  ) async {
    calls.add('install');
    return PackageInstallEvidence(
      exportedDigest: 'sha256:${package.sha256}',
      installedDigest: installedDigest,
      passed: true,
      evidenceRef: 'install://golden/${package.sha256}',
    );
  }
}
```

## `examples/playable_runtime_host/lib/src/evaluation/authoring/evaluation_distribution_package_service.dart`

```dart
import 'package:map_authoring/map_authoring.dart';
import 'package:map_distribution/map_distribution.dart';

final class EvaluationDistributionPackageInput {
  EvaluationDistributionPackageInput({
    required this.manifest,
    required Map<String, List<int>> payloadFiles,
  }) : payloadFiles = Map.unmodifiable({
          for (final entry in payloadFiles.entries)
            entry.key: List<int>.unmodifiable(entry.value),
        });

  final GamePackageManifest manifest;
  final Map<String, List<int>> payloadFiles;
}

final class EvaluationInstalledPackageEvidence {
  EvaluationInstalledPackageEvidence({
    required String packageSha256,
    required this.passed,
    required String evidenceRef,
  })  : packageSha256 = _sha256(packageSha256, 'packageSha256'),
        evidenceRef = _evidenceRef(evidenceRef);

  final String packageSha256;
  final bool passed;
  final String evidenceRef;
}

typedef EvaluationDistributionInputLoader
    = Future<EvaluationDistributionPackageInput> Function(
  PackageBuildRequest request,
);

typedef EvaluationPackageInstaller = Future<EvaluationInstalledPackageEvidence>
    Function({
  required AuthoringArtifactRef artifact,
  required List<int> packageBytes,
  required GamePackageInspectionResult inspection,
});

/// Production-byte adapter for the protocol-neutral Authoring package port.
///
/// The caller owns project I/O and platform installation. This service owns
/// deterministic package construction, in-memory artifact identity and strict
/// inspection through `map_distribution`.
final class EvaluationDistributionPackageService
    implements AuthoringPackagePort {
  EvaluationDistributionPackageService({
    required EvaluationDistributionInputLoader inputLoader,
    required EvaluationPackageInstaller installer,
    GamePackageBuilder builder = const GamePackageBuilder(),
    GamePackageInspector inspector = const GamePackageInspector(),
  })  : _inputLoader = inputLoader,
        _installer = installer,
        _builder = builder,
        _inspector = inspector;

  final EvaluationDistributionInputLoader _inputLoader;
  final EvaluationPackageInstaller _installer;
  final GamePackageBuilder _builder;
  final GamePackageInspector _inspector;
  final Map<String, List<int>> _bytesByDigest = <String, List<int>>{};
  final Map<String, GamePackageInspectionResult> _inspectionsByDigest =
      <String, GamePackageInspectionResult>{};

  @override
  Future<PackageBuildEvidence> build(PackageBuildRequest request) async {
    final input = await _inputLoader(request);
    final built = _builder.build(
      manifest: input.manifest,
      payloadFiles: input.payloadFiles,
    );
    final digest = built.packageSha256;
    _bytesByDigest[digest] = List<int>.unmodifiable(built.packageBytes);
    final artifact = AuthoringArtifactRef(
      id: 'package-${request.packageId}-${request.requestId}',
      mediaType: 'application/vnd.pokemap.game+zip',
      uri: 'artifact://sha256/$digest',
      byteLength: built.archiveBytes,
      sha256: digest,
    );
    return PackageBuildEvidence(
      request: request,
      artifact: artifact,
      treeDigest: 'sha256:${built.manifest.content.treeSha256}',
      evidenceRef: 'package-build://${request.packageId}/$digest',
    );
  }

  @override
  Future<PackageInspectionEvidence> inspect(
    AuthoringArtifactRef package,
  ) async {
    final bytes = _resolve(package);
    final inspection = _inspector.inspect(bytes);
    final digest = package.sha256!;
    final passed = inspection.receipt.packageSha256 == digest;
    if (passed) _inspectionsByDigest[digest] = inspection;
    return PackageInspectionEvidence(
      artifact: package,
      treeDigest: 'sha256:${inspection.receipt.treeSha256}',
      passed: passed,
      evidenceRef: 'package-inspection://${inspection.manifest.gameId}/$digest',
    );
  }

  @override
  Future<PackageInstallEvidence> install(
    AuthoringArtifactRef package,
  ) async {
    final bytes = _resolve(package);
    final digest = package.sha256!;
    final inspection =
        _inspectionsByDigest[digest] ?? _inspector.inspect(bytes);
    final installed = await _installer(
      artifact: package,
      packageBytes: List<int>.unmodifiable(bytes),
      inspection: inspection,
    );
    return PackageInstallEvidence(
      exportedDigest: 'sha256:$digest',
      installedDigest: 'sha256:${installed.packageSha256}',
      passed: installed.passed,
      evidenceRef: installed.evidenceRef,
    );
  }

  List<int> _resolve(AuthoringArtifactRef artifact) {
    final digest = artifact.sha256;
    if (digest == null || artifact.uri != 'artifact://sha256/$digest') {
      throw StateError('Package artifact identity is incomplete.');
    }
    final bytes = _bytesByDigest[digest];
    if (bytes == null || artifact.byteLength != bytes.length) {
      throw StateError('Package artifact is unknown or stale.');
    }
    return bytes;
  }
}

String _sha256(String value, String field) {
  if (!RegExp(r'^[0-9a-f]{64}$').hasMatch(value)) {
    throw ArgumentError.value(value, field, 'must be a SHA-256 hex digest');
  }
  return value;
}

String _evidenceRef(String value) {
  final normalized = value.trim();
  final uri = Uri.tryParse(normalized);
  if (normalized.isEmpty ||
      uri == null ||
      !uri.hasScheme ||
      uri.scheme == 'file') {
    throw ArgumentError.value(
      value,
      'evidenceRef',
      'must be a stable non-file URI',
    );
  }
  return normalized;
}
```

## `examples/playable_runtime_host/test/evaluation/phase6_authoring_package_identity_test.dart`

```dart
import 'dart:convert';
import 'dart:io';

import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:map_distribution/map_distribution.dart';
import 'package:map_runtime/map_runtime.dart';
import 'package:path/path.dart' as p;
import 'package:pokemap_hub/pokemap_hub_player.dart';
import 'package:pokemap_loader/src/evaluation/authoring/evaluation_distribution_package_service.dart';
import 'package:pokemap_loader/src/project_tree_digest.dart';
import 'package:pub_semver/pub_semver.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'public authoring creates the slice and installed bytes boot in production runtime',
    () async {
      final temporaryRoot = await Directory.systemTemp.createTemp(
        'pmcp072_authoring_package_',
      );
      addTearDown(() async {
        if (await temporaryRoot.exists()) {
          await temporaryRoot.delete(recursive: true);
        }
      });
      final projectRoot = Directory(p.join(temporaryRoot.path, 'project'));
      await projectRoot.create();
      await File(
        p.join('phase6_authoring_golden_slice', 'project.json'),
      ).copy(p.join(projectRoot.path, 'project.json'));

      const reader = LocalProjectFileReader();
      final policy = await WorkspacePolicy.create(
        allowedRootPaths: <String>[projectRoot.path],
        fileReader: reader,
      );
      final handles = WorkspaceHandleStore(
        tokenFactory: (prefix) => '${prefix}pmcp072',
      );
      final opened = await ProjectOpenService(
        policy: policy,
        fileReader: reader,
        handles: handles,
      ).openProject(projectRoot.path);
      final snapshots = ProjectSnapshotLoader(handles: handles);
      final mutations = LocalMapAuthoringMutationApi(
        policy: policy,
        snapshotLoader: snapshots,
      );
      await mutations.attachProject(
        projectRootPath: projectRoot.path,
        workspaceHandle: opened.workspaceHandle,
        projectHandle: opened.projectHandle,
      );
      addTearDown(() => mutations.detachWorkspace(opened.workspaceHandle));
      final before = await snapshots.load(opened.projectHandle);
      expect(before.manifest.maps, isEmpty);

      final planned = await mutations.plan(
        opened.projectHandle,
        AuthoringRequest(
          requestId: 'request-create-golden-map',
          actionId: 'map.create',
          actionVersion: 1,
          workspaceHandle: opened.workspaceHandle.value,
          parameters: const <String, Object?>{
            'mapId': 'golden_api_map',
            'name': 'Golden API Map',
            'width': 6,
            'height': 4,
          },
          expectedRevision: before.revision,
          idempotencyKey: 'idem-create-golden-map',
        ),
      );
      final applied = await mutations.apply(
        opened.projectHandle,
        planId: planned['planId']! as String,
        operationId: 'operation-create-golden-map',
      );
      expect(
        (applied['receipt']! as Map<String, Object?>)['status'],
        'applied',
      );
      final authored = await snapshots.load(opened.projectHandle);
      expect(authored.manifest.maps.single.id, 'golden_api_map');
      final sourceRevision =
          'sha256:${await const ProjectTreeDigest().compute(projectRoot)}';

      final hostCompatibility = GamePackageHostCompatibility(
        hubVersion: Version.parse('1.2.0'),
        runtimeApiVersion: Version.parse('1.4.0'),
        capabilities: const <String>{'map@1'},
        supportedProjectFormats: const <String>{'v2'},
        currentProjectFormat: 'v2',
        supportedSaveFormats: const <int>{1},
      );
      final inspector = GamePackageInspector(
        hostCompatibility: hostCompatibility,
      );
      final supportRoot = Directory(p.join(temporaryRoot.path, 'support'));
      String? runtimeLoadedMapId;
      final packageService = EvaluationDistributionPackageService(
        inspector: inspector,
        inputLoader: (request) async {
          expect(request.sourceRevision, sourceRevision);
          return EvaluationDistributionPackageInput(
            manifest: _packageManifest(),
            payloadFiles: <String, List<int>>{
              'project/project.json':
                  await File(p.join(projectRoot.path, 'project.json'))
                      .readAsBytes(),
              'project/maps/golden_api_map.json': await File(
                p.join(projectRoot.path, 'maps', 'golden_api_map.json'),
              ).readAsBytes(),
            },
          );
        },
        installer: ({
          required artifact,
          required packageBytes,
          required inspection,
        }) async {
          final exportedFile = File(
            p.join(temporaryRoot.path, 'golden-api.pokemapgame'),
          );
          await exportedFile.writeAsBytes(packageBytes, flush: true);
          final installation = await GamePackageInstaller(
            supportRoot: supportRoot,
            inspector: inspector,
            availableDiskBytes: (_) async => 2 * 1024 * 1024 * 1024,
            loadSmoke: (stagedVersion, manifest) async {
              final bundle = await loadRuntimeMapBundle(
                projectFilePath: p.join(
                  stagedVersion.path,
                  'project',
                  'project.json',
                ),
                mapId: 'golden_api_map',
              );
              final game = RuntimeMapGame(bundle: bundle);
              game.onGameResize(Vector2(320, 240));
              await game.onLoad();
              runtimeLoadedMapId = bundle.map.id;
            },
            prepareSavesForUpdate: (_, __) async =>
                const SaveUpdatePreparation(),
            now: () => DateTime.utc(2026, 7, 31, 18),
          ).install(
            exportedFile,
            source: GamePackageInstallSource.localExport,
          );
          final launch = await InstalledGameLaunchResolver(
            supportRoot: supportRoot,
            hostCompatibility: hostCompatibility,
          ).resolve(installation.game);
          final installedProjectFile =
              await launch.assets.resolveReference(launch.project);
          final installedBundle = await loadRuntimeMapBundle(
            projectFilePath: installedProjectFile.path,
            mapId: 'golden_api_map',
          );
          final installedGame = RuntimeMapGame(bundle: installedBundle);
          installedGame.onGameResize(Vector2(320, 240));
          await installedGame.onLoad();
          runtimeLoadedMapId = installedBundle.map.id;
          expect(
            inspection.receipt.packageSha256,
            installation.receipt.packageSha256,
          );
          return EvaluationInstalledPackageEvidence(
            packageSha256: installation.receipt.packageSha256,
            passed: true,
            evidenceRef: 'hub-install://${installation.receipt.gameId}/'
                '${installation.receipt.packageSha256}',
          );
        },
      );

      final receipt =
          await DistributionPackageActions(port: packageService).release(
        request: PackageBuildRequest(
          requestId: 'request-release-golden',
          packageId: 'golden-api',
          projectId: 'phase6-golden-project',
          sourceRevision: sourceRevision,
          releaseVersion: '1.0.0',
        ),
        regressionGates: <PackageReleaseGateEvidence>[
          PackageReleaseGateEvidence(
            id: 'authoring.public-api',
            passed: true,
            summary: 'map.create plan/apply created the fixture map.',
            evidenceRef: 'authoring-receipt://operation-create-golden-map',
          ),
          PackageReleaseGateEvidence(
            id: 'runtime.golden-slice',
            passed: true,
            summary: 'The installed map booted through RuntimeMapGame.',
            evidenceRef: 'test://pmcp072/production-runtime-smoke',
          ),
          PackageReleaseGateEvidence(
            id: 'regression.matrix',
            passed: true,
            summary: 'The PMCP-072 scoped regression matrix passed.',
            evidenceRef: 'test://pmcp072/regression-matrix',
          ),
        ],
        gameplayLots: <GameplayLotReleaseMapping>[
          for (var id = 180; id <= 184; id += 1)
            GameplayLotReleaseMapping(lotId: 'FG-$id', status: 'DONE'),
          GameplayLotReleaseMapping(lotId: 'FG-185', status: 'PARTIAL'),
        ],
      );

      expect(runtimeLoadedMapId, 'golden_api_map');
      expect(receipt.isReady, isTrue);
      expect(receipt.packageDigest, receipt.installedDigest);
      expect(
        receipt.gates,
        everyElement(
          isA<PackageReleaseGateEvidence>()
              .having((gate) => gate.passed, 'passed', isTrue)
              .having((gate) => gate.evidenceRef, 'evidenceRef', isNotEmpty),
        ),
      );
      expect(
        receipt.gameplayLots,
        everyElement(
          isA<GameplayLotReleaseMapping>().having(
            (mapping) => mapping.updateApplied,
            'updateApplied',
            isFalse,
          ),
        ),
      );
      final installedManifest = ProjectManifest.fromJson(
        (jsonDecode(
          await File(
            p.join(
              supportRoot.path,
              'games',
              'games.example.pmcp072-golden',
              'versions',
              '1.0.0',
              'project',
              'project.json',
            ),
          ).readAsString(),
        ) as Map)
            .cast<String, dynamic>(),
      );
      expect(installedManifest.maps.single.id, 'golden_api_map');
    },
    timeout: const Timeout(Duration(minutes: 2)),
  );
}

GamePackageManifest _packageManifest() => GamePackageManifest(
      packageFormat: 1,
      gameId: 'games.example.pmcp072-golden',
      gameVersion: Version.parse('1.0.0'),
      title: 'PMCP-072 Golden API',
      author: const GamePackageParty(name: 'PokeMap'),
      compatibility: GamePackageCompatibility(
        minHubVersion: Version.parse('0.1.0'),
        runtimeApiExpression: '>=1.0.0 <2.0.0',
        projectFormat: 'v2',
        saveFormat: 1,
        compatibilityId: 'main',
        requiredCapabilities: const <String>['map@1'],
      ),
      locales: GamePackageLocales(
        defaultLocale: 'fr',
        supported: const <String>['fr'],
      ),
      presentation: const GamePackagePresentation(),
      content: GamePackageContent(
        fileCount: 0,
        totalBytes: 0,
        treeSha256: '0' * 64,
        files: const <GamePackageFileEntry>[],
      ),
    );
```

## `examples/playable_runtime_host/phase6_authoring_golden_slice/project.json`

```json
{
  "name": "Phase 6 Authoring Golden Slice Scaffold",
  "version": "v2",
  "maps": [],
  "tilesets": []
}
```

## `examples/playable_runtime_host/phase6_authoring_golden_slice/README.md`

```markdown
# Phase 6 Authoring Golden Slice

This fixture is intentionally only an empty, valid project scaffold. The
release test creates its playable map through `LocalMapAuthoringMutationApi`
(`map.create` plan/apply); it never edits project or map JSON directly.
```
