import 'package:map_core/map_core.dart';
import 'package:map_editor/src/application/services/narrative_diagnostic_suppression_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const warning = NarrativeProjectDiagnostic(
    code: 'readableLabelMatchesId',
    severity: NarrativeProjectDiagnosticSeverity.warning,
    domain: NarrativeProjectDiagnosticDomain.event,
    message: 'Le label lisible reprend l’identifiant technique.',
    path: 'eventRegistry.records.evt_port.label',
    destination: NarrativeProjectDiagnosticDestination.event,
    eventId: 'evt_port',
  );
  const service = NarrativeDiagnosticSuppressionService();

  test('persists then reloads an active suppression from ProjectManifest JSON',
      () async {
    final project = _project();
    ProjectManifest? persisted;

    final updated = await service.suppress(
      project: project,
      diagnostic: warning,
      reason: 'Dette cosmétique acceptée pour la démo.',
      author: 'Karim',
      createdAt: DateTime.utc(2026, 7, 20),
      persist: (next) async => persisted = next,
    );
    final reloaded = ProjectManifest.fromJson(persisted!.toJson());
    final snapshot = service.buildSnapshot(
      project: reloaded,
      diagnostics: const [warning],
      now: DateTime.utc(2026, 7, 20, 12),
    );

    expect(updated.narrativeDiagnosticSuppressions, hasLength(1));
    expect(snapshot.diagnostics.single.status,
        NarrativeDiagnosticStatus.suppressed);
    expect(snapshot.resolvedSuppressions, isEmpty);
  });

  test('expired and stale suppressions never hide the current diagnostic', () {
    final fingerprint = service.fingerprint(warning);
    final expired = NarrativeDiagnosticSuppression(
      diagnosticId: warning.stableKey,
      diagnosticFingerprint: fingerprint,
      reason: 'Expiration volontaire.',
      author: 'Karim',
      createdAt: DateTime.utc(2026, 7, 1),
      expiresAt: DateTime.utc(2026, 7, 10),
    );
    final changedWarning = NarrativeProjectDiagnostic(
      code: warning.code,
      severity: warning.severity,
      domain: warning.domain,
      message: '${warning.message} Nouveau contexte.',
      path: warning.path,
      destination: warning.destination,
      eventId: warning.eventId,
    );
    final stale = NarrativeDiagnosticSuppression(
      diagnosticId: changedWarning.stableKey,
      diagnosticFingerprint: 'sha256:${'0' * 64}',
      reason: 'Ancien contenu.',
      author: 'Karim',
      createdAt: DateTime.utc(2026, 7, 1),
    );

    final expiredSnapshot = service.buildSnapshot(
      project: _project(suppressions: [expired]),
      diagnostics: const [warning],
      now: DateTime.utc(2026, 7, 20),
    );
    final staleSnapshot = service.buildSnapshot(
      project: _project(suppressions: [stale]),
      diagnostics: [changedWarning],
      now: DateTime.utc(2026, 7, 20),
    );

    expect(expiredSnapshot.diagnostics.single.status,
        NarrativeDiagnosticStatus.expiredSuppression);
    expect(staleSnapshot.diagnostics.single.status,
        NarrativeDiagnosticStatus.staleSuppression);
  });

  test('a suppression whose diagnostic disappeared is reported as resolved',
      () {
    final suppression = NarrativeDiagnosticSuppression(
      diagnosticId: warning.stableKey,
      diagnosticFingerprint: service.fingerprint(warning),
      reason: 'Dette désormais corrigée.',
      author: 'Karim',
      createdAt: DateTime.utc(2026, 7, 1),
    );

    final snapshot = service.buildSnapshot(
      project: _project(suppressions: [suppression]),
      diagnostics: const [],
      now: DateTime.utc(2026, 7, 20),
    );

    expect(snapshot.resolvedSuppressions, [suppression]);
  });

  test('release-blocking errors cannot be suppressed', () async {
    final error = NarrativeProjectDiagnostic(
      code: warning.code,
      severity: NarrativeProjectDiagnosticSeverity.error,
      domain: warning.domain,
      message: warning.message,
      path: warning.path,
      destination: warning.destination,
      eventId: warning.eventId,
    );

    expect(
      () => service.suppress(
        project: _project(),
        diagnostic: error,
        reason: 'Tentative invalide.',
        author: 'Karim',
        persist: (_) async {},
      ),
      throwsA(isA<NarrativeDiagnosticSuppressionRejected>()),
    );
  });

  test('persistence failure leaves the immutable source project unchanged',
      () async {
    final project = _project();

    expect(
      () => service.suppress(
        project: project,
        diagnostic: warning,
        reason: 'Ne doit pas survivre.',
        author: 'Karim',
        persist: (_) async => throw StateError('disk full'),
      ),
      throwsStateError,
    );
    expect(project.narrativeDiagnosticSuppressions, isEmpty);
  });

  test('merges publication-only physical diagnostics without duplicating core',
      () {
    final authoring = NarrativeProjectValidationReport(
      diagnostics: const [warning],
      mapEventViews: const [],
    );
    final publication = NarrativeMultidimensionalValidationReport(
      validatorVersion: 'v1',
      profileId: 'profile',
      profileVersion: 1,
      projectFingerprint: 'sha256:${'9' * 64}',
      generatedAt: DateTime.utc(2026),
      structurallyValid: NarrativeValidationDimensionResult(
        status: NarrativeValidationStatus.pass,
        diagnostics: [
          NarrativeMultidimensionalDiagnostic(
            id: warning.stableKey,
            code: warning.code,
            severity: 'warning',
            message: warning.message,
            path: warning.path,
          ),
        ],
      ),
      narrativelySolvable: NarrativeValidationDimensionResult(
        status: NarrativeValidationStatus.pass,
      ),
      physicallyReachable: NarrativeValidationDimensionResult(
        status: NarrativeValidationStatus.indeterminate,
        diagnostics: [
          NarrativeMultidimensionalDiagnostic(
            id: 'physical:blocked:evt_port',
            code: 'explorationBudgetExceeded',
            severity: 'warning',
            message: 'Budget physique dépassé.',
            path: 'maps.map_port',
            provenance: const ['spawn:start', 'event:evt_port'],
          ),
        ],
      ),
      runtimeSmokeVerified: NarrativeValidationDimensionResult(
        status: NarrativeValidationStatus.pass,
      ),
    );

    final merged = mergeNarrativePublicationDiagnostics(
      authoringReport: authoring,
      publicationReport: publication,
    );

    expect(merged.diagnostics, hasLength(2));
    expect(merged.diagnostics.last.mapId, 'map_port');
    expect(merged.diagnostics.last.destination,
        NarrativeProjectDiagnosticDestination.map);
    expect(merged.diagnostics.last.message, contains('spawn:start'));
  });
}

ProjectManifest _project({
  List<NarrativeDiagnosticSuppression> suppressions = const [],
}) =>
    ProjectManifest(
      name: 'Suppression test',
      maps: const [],
      tilesets: const [],
      narrativeDiagnosticSuppressions: suppressions,
    );
